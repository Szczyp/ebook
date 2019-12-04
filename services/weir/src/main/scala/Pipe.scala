package weir

import zio._
import zio.duration._
import weir.MailRegistry._
import argonaut._, Argonaut._
import ArgonautScalaz._

import zio.kafka.client._
import zio.kafka.client.serde._
import org.apache.kafka.clients.producer.ProducerRecord

object Pipe {
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
                .mapConcat(r => r.record.value().parseOption.map(data => (r.record.key(), r.offset, data)))
                .mapM {
                  case (key, offset, data) =>
                    val fromL = jObjectPL >=> jsonObjectPL("from") >=> jStringPL

                    fromL.get(data) match {
                      case None => UIO(None)
                      case Some(from) =>
                        mailRegistry
                          .lookup(from)
                          .map(
                            _.map(
                              to => {
                                val json = ("to" := to) ->: data
                                (new ProducerRecord("weir", key, json.nospaces), offset)
                              }
                            )
                          )
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
    } yield ()
}
