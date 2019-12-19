open System


module Kafka =
    open Confluent.Kafka

    module Config =
        type Config = {
            BootstrapServers: string
        }

        let create =
            let bootstrapServers =
                let bs = Environment.GetEnvironmentVariable("KAFKA_BOOTSTRAP_SERVERS")
                if String.IsNullOrEmpty(bs)
                then "localhost:9092"
                else bs
            {BootstrapServers = bootstrapServers}


    module Consumer =
        open Config

        let create config =
            let consumerConfig = ConsumerConfig (
                                     GroupId = "scribe",
                                     BootstrapServers = config.BootstrapServers,
                                     AutoOffsetReset = Nullable AutoOffsetReset.Earliest
                                   )
            let consumer = ConsumerBuilder<Ignore, string>(consumerConfig).Build()
            consumer.Subscribe "mob"
            consumer

        let consume (c: IConsumer<Ignore, string>) =
            c.Consume().Value


    module Producer =
        open Config

        let create config =
            let producerConfig = ProducerConfig (
                                        BootstrapServers = config.BootstrapServers
                                    )
            ProducerBuilder<Null, byte[]>(producerConfig).Build()

        let produce (p: IProducer<Null, byte[]>) bs =
            p.Produce("scribe", Message<Null, byte[]>(Value = bs))


module Mail =
    module Config =
        open Legivel.Serialization
        open System.IO

        type Config = {
            User: string;
        }

        let create =
            let defaultConfig = {User = "test@test.com"}
            try
                let yaml = File.ReadAllText("/etc/scribe/mail.yaml")
                match Deserialize<Config> yaml with
                | [Succes {Data = config}] -> config
                | _ -> defaultConfig
            with
                | _ -> defaultConfig

    module Mail =
        open Chiron
        open Config
        open MimeKit
        open System.IO
        open System.Text.RegularExpressions

        type Record = {
            From: string;
            Url: string;
            To: string;
            Title: string;
            Mobi: byte[];
        } with

            static member FromJson (_ :Record) = json {
                let! from = Json.read "from"
                let! url = Json.read "url"
                let! t = Json.read "to"
                let! title = Json.read "title"
                let! mobi = Json.read "mobi"

                return {
                    From = from;
                    Url = url;
                    To = t;
                    Title = title;
                    Mobi = Convert.FromBase64String(mobi)
                }
            }

        let parse: string -> Record = Json.parse >> Json.deserialize

        let create config record =
            let fileName s =
                sprintf "%s.mobi" <| Regex.Replace(s, @"[^-\w.]", " ")

            let msg = MimeMessage()
            let from = MailboxAddress(config.User)
            msg.From.Add(from)
            msg.To.Add(MailboxAddress(record.To))
            msg.Subject <- record.Title
            let txt = TextPart(
                        Text = sprintf "%s generated from %s" record.Title record.Url
                    )
            let mobi = MimePart(
                        Content = MimeContent(new MemoryStream(record.Mobi)),
                        ContentDisposition = ContentDisposition(ContentDisposition.Attachment),
                        ContentTransferEncoding = ContentEncoding.Base64,
                        FileName = fileName record.Title
                    )
            let multipart = Multipart()
            multipart.Add(txt)
            multipart.Add(mobi)
            msg.Body <- multipart
            msg

        let toBytes (msg: MimeMessage) =
            use stream = new MemoryStream()
            msg.WriteTo(stream)
            stream.ToArray()


open Kafka
open Mail


[<EntryPoint>]
let main argv =
    let mailConfig = Mail.Config.create
    let kafkaConfig = Kafka.Config.create

    use consumer = Consumer.create kafkaConfig
    use producer = Producer.create kafkaConfig

    while true do
        Consumer.consume consumer
        |> Mail.parse
        |> Mail.create mailConfig
        |> Mail.toBytes
        |> Producer.produce producer

    0
