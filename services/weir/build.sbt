val ZioVersion    = "1.0.0-RC17"
val Specs2Version = "4.7.0"

resolvers += Resolver.sonatypeRepo("releases")
resolvers += Resolver.sonatypeRepo("snapshots")

lazy val root = (project in file("."))
  .settings(
    organization := "weir",
    name := "weir",
    version := "1.0.0",
    scalaVersion := "2.12.10",
    maxErrors := 3,
    libraryDependencies ++= Seq(
      "dev.zio"               %% "zio"         % ZioVersion,
      "dev.zio"               %% "zio-streams" % ZioVersion,
      "dev.zio"               %% "zio-kafka"   % "0.4.1",
      "io.argonaut"           %% "argonaut"    % "6.2.2",
      "org.specs2"            %% "specs2-core" % Specs2Version % "test"
    )
  )

// Refine scalac params from tpolecat
scalacOptions --= Seq(
  "-Xfatal-warnings"
)

addCommandAlias("fmt", "all scalafmtSbt scalafmt test:scalafmt")
addCommandAlias("chk", "all scalafmtSbtCheck scalafmtCheck test:scalafmtCheck")

enablePlugins(JavaAppPackaging)
