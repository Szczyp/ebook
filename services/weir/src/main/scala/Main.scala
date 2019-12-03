package weir

import zio.App
import zio.clock.Clock
import zio.blocking.Blocking

object Main extends App {

  val env = MailRegistry.Live.create
    .map(
      mr =>
        new MailRegistry with Clock.Live with Blocking.Live with Config.Live {
          val mailRegistry = mr.mailRegistry
        }
    )
    .provide(new Clock.Live with Blocking.Live with Config.Live)

  def run(args: List[String]) =
    Pipe
      .run
      .provideM(env)
      .fold(_ => 1, _ => 0)
}
