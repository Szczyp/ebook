package weir

import zio.console.{ getStrLn, putStrLn, Console }
import zio.clock.Clock
import zio.blocking.Blocking
import zio.duration._
import zio._
import weir.MailRegistry._
import argonaut._, Argonaut._

import zio.kafka.client._
import zio.kafka.client.serde._
import org.apache.kafka.clients.producer.ProducerRecord

object Main extends App {
  case class Urex(url: String, from: String)
  implicit def UrexCodecJson =
    casecodec2(Urex.apply, Urex.unapply)("url", "from")

  case class Weir(url: String, from: String, to: String)
  implicit def WeirCodecJson =
    casecodec3(Weir.apply, Weir.unapply)("url", "from", "to")

  val consumerSettings: ConsumerSettings =
    ConsumerSettings(
      bootstrapServers = List("localhost:9092"),
      groupId = "weir",
      clientId = "weir",
      closeTimeout = 30.seconds,
      extraDriverSettings = Map(),
      pollInterval = 250.millis,
      pollTimeout = 50.millis,
      perPartitionChunkPrefetch = 2
    )

  val producerSettings: ProducerSettings =
    ProducerSettings(
      bootstrapServers = List("localhost:9092"),
      closeTimeout = 30.seconds,
      extraDriverSettings = Map()
    )

  val consumer = Consumer.make(consumerSettings)
  val producer = Producer.make(producerSettings, Serde.string, Serde.string)

  def pipe = (consumer zip producer).use {
    case (consumer, producer) =>
      consumer
        .subscribeAnd(Subscription.topics("urex"))
        .plainStream(Serde.string, Serde.string)
        .mapM { record =>
          val key: String   = record.record.key()
          val value: String = record.record.value()
          value.decodeOption[Urex] match {
            case Some(Urex(url, from)) =>
              for {
                to <- mailRegistry.lookup(from)
              } yield (to.map(to => {
                val producerRecord: ProducerRecord[String, String] =
                  new ProducerRecord("weir", key, new Weir(url, from, to).asJson.nospaces)
                (producerRecord, record.offset)
              }))
            case None => ZIO.succeed(None)
          }
        }
        .collect { case Some(x) => x }
        .chunks
        .mapM { chunk =>
          val records = chunk.map(_._1)

          val offsetBatch = OffsetBatch(chunk.map(_._2).toSeq)

          producer.produceChunk(records) *> offsetBatch.commit
        }
        .runDrain
  }

  def run(args: List[String]) = {
    val env = MailRegistry.Live.create
      .map(
        mr =>
          new MailRegistry with Clock.Live with Blocking.Live {
            val mailRegistry = mr.mailRegistry
          }
      )
      .provide(new Clock.Live with Blocking.Live)

    pipe.provideM(env).fold(_ => 1, _ => 0)
  }
}
