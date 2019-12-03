package weir

import zio._

trait Config {
  val config: Config.Service
}

object Config {
  case class Data(bootstrapServers: String)
  trait Service {
    def get: UIO[Data]
  }

  trait Live extends Config {
    val config = new Service {
      def get = {
        for {
          bs <- ZIO.effectTotal(sys.env.get("KAFKA_BOOTSTRAP_SERVERS"))
        }
        yield (new Data(bs.getOrElse("localhost:9092")))
      }
    }
  }

  object Live extends Live
}

object config {
  val get: URIO[Config, Config.Data] = ZIO.accessM(_.config.get)
}

