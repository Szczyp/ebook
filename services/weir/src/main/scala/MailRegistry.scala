package weir

import zio._
import scala.collection.immutable.Map
import zio.kafka.client._
import zio.kafka.client.serde._
import org.apache.kafka.clients.consumer.ConsumerConfig
import org.apache.kafka.common.TopicPartition
import argonaut._, Argonaut._
import zio.duration._

trait MailRegistry {
  val mailRegistry: MailRegistry.Service
}

object MailRegistry {
  trait Service {
    def lookup(mailAddress: String): UIO[Option[String]]
  }

  trait Live extends MailRegistry {
    val ref: Ref[Map[String, String]]

    val mailRegistry = new Service {
      def lookup(mailAddress: String): UIO[Option[String]] =
        ref.get.map(_.get(mailAddress))
    }
  }

  object Live {
    val create = {

      case class Draft(user: String, kindle: String)
      implicit def DraftCodecJson =
        casecodec2(Draft.apply, Draft.unapply)("user", "kindle")

      val subscription = Subscription.topics("draft")

      for {
        cfg <- config.get
        settings = ConsumerSettings(
          bootstrapServers = List(cfg.bootstrapServers),
          groupId = "weir",
          clientId = "weir",
          closeTimeout = 30.seconds,
          extraDriverSettings = Map(),
          pollInterval = 250.millis,
          pollTimeout = 50.millis,
          perPartitionChunkPrefetch = 2
        )

        consumer = Consumer.make(settings)

        r <- Ref.make(Map.empty[String, String])
        run = consumer.use { c =>
          for {
            _     <- c.subscribe(subscription)
            parts <- c.assignment.repeat(Schedule.doUntil(_.nonEmpty))
            _     <- c.seekToBeginning(parts)
            stream <- c.plainStream(Serde.string, Serde.string)
                       .flattenChunks
                       .tap(
                         _.record.value.decodeOption[Draft] match {
                           case Some(Draft(user, kindle)) =>
                             r.modify(m => ((), m + (user -> kindle)))
                           case None => UIO(())
                         }
                       )
                       .map(_.offset)
                       .aggregateAsync(Consumer.offsetBatches)
                       .mapM(_.commit)
                       .runDrain
          } yield ()
        }
        _ <- run.fork
      } yield (new Live { override val ref = r })
    }
  }
}

object mailRegistry {
  def lookup(mailAddress: String): URIO[MailRegistry, Option[String]] =
    ZIO.accessM(_.mailRegistry.lookup(mailAddress))
}
