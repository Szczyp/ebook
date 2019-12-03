package weir

import zio._
import zio.duration._
import zio.clock.Clock
import zio.blocking.Blocking
import weir.MailRegistry._
import argonaut._, Argonaut._

import zio.kafka.client._
import zio.kafka.client.serde._
import org.apache.kafka.clients.producer.ProducerRecord

object Pipe {
  case class Urex(url: String, from: String)
  implicit def UrexCodecJson =
    casecodec2(Urex.apply, Urex.unapply)("url", "from")

  case class Weir(url: String, from: String, to: String)
  implicit def WeirCodecJson =
    casecodec3(Weir.apply, Weir.unapply)("url", "from", "to")

  val run =
    for {
      cfg <- config.get

      consumerSettings = ConsumerSettings(
        bootstrapServers = List(cfg.bootstrapServers),
        groupId = "weir",
        clientId = "weir",
        closeTimeout = 30.seconds,
        extraDriverSettings = Map(),
        pollInterval = 250.millis,
        pollTimeout = 50.millis,
        perPartitionChunkPrefetch = 2
      )

      producerSettings = ProducerSettings(
        bootstrapServers = List(cfg.bootstrapServers),
        closeTimeout = 30.seconds,
        extraDriverSettings = Map()
      )

      consumer = Consumer.make(consumerSettings)
      producer = Producer.make(producerSettings, Serde.string, Serde.string)

      _ <- (consumer zip producer).use {
        case (consumer, producer) =>
          consumer
            .subscribeAnd(Subscription.topics("urex"))
            .plainStream(Serde.string, Serde.string)
            .mapConcat(r => r.record.value().decodeOption[Urex].map(v => (r.record.key(), r.offset, v)))
            .mapM {
              case (key, offset, Urex(url, from)) =>
                mailRegistry
                  .lookup(from)
                  .map(
                    _.map(
                      to => (new ProducerRecord("weir", key, new Weir(url, from, to).asJson.nospaces), offset)
                    )
                  )
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
    } yield ()

}
