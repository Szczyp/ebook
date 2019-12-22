using System;
using Confluent.Kafka;
using MimeKit;
using MailKit.Net.Smtp;
using System.Reactive.Linq;
using System.Reactive.Concurrency;
using System.IO;
using MailKit.Security;
using System.Collections.Generic;
using System.Linq;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace Heave
{
    class SmtpConfig
    {
        public string Host { get; }
        public string User { get; }
        public string Password { get; }

        public SmtpConfig(string host, string user, string password)
        {
            if (new[] { host, user, password }.Any(String.IsNullOrEmpty))
                throw new ArgumentNullException("Host, User and Password cannot be null");

            Host = host;
            User = user;
            Password = password;
        }

        public static SmtpConfig Read()
        {
            var deserializer = new DeserializerBuilder().Build();
            var dict = deserializer.Deserialize<Dictionary<string,string>>(
                File.ReadAllText("/etc/heave/smtp.yaml"));
            return new SmtpConfig(dict["host"], dict["user"], dict["password"]);
        }
    }

    static class Heave
    {
        public static IObservable<byte[]> Mails(string servers)
        {
            servers = servers ?? "localhost:9092";
            var config = new ConsumerConfig
            {
                GroupId = "heave",
                BootstrapServers = servers,
                AutoOffsetReset = AutoOffsetReset.Earliest
            };

            return Observable.Create<byte[]>(subscribe =>
            {
                return NewThreadScheduler.Default.ScheduleLongRunning(_ =>
                {
                    var consumer = new ConsumerBuilder<string, byte[]>(config).Build();

                    consumer.Subscribe("scribe");

                    while (true)
                    {
                        var cr = consumer.Consume();
                        subscribe.OnNext(cr.Value);
                    }
                });
            });
        }

        public static Action<byte[]> Send(SmtpConfig config)
        {
            var client = new SmtpClient();
            #warning CheckCertificateRevocation is false, please investigate.
            client.CheckCertificateRevocation = false;

            return payload =>
            {
                client.Connect(config.Host, 587, SecureSocketOptions.StartTls);
                client.Authenticate(config.User, config.Password);

                var message = MimeMessage.Load(new MemoryStream(payload));

                client.Send(message);

                client.Disconnect(true);
            };
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            var servers = Environment.GetEnvironmentVariable("KAFKA_BOOTSTRAP_SERVERS");
            var config = SmtpConfig.Read();

            Heave.Mails(servers)
            .ForEachAsync(Heave.Send(config))
            .Wait();
        }
    }
}
