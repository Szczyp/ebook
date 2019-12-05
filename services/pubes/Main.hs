{-# LANGUAGE NamedFieldPuns, OverloadedStrings, StrictData #-}

module Main where

import           Control.Applicative
import           Control.Error.Util
import           Control.Lens
import           Control.Monad              (void)
import           Control.Monad.IO.Class     (liftIO)
import           Control.Monad.Logger       (runNoLoggingT, runStdoutLoggingT)
import           Control.Monad.Trans.Reader
import qualified Data.Aeson                 as Aeson
import           Data.Aeson.Lens
import qualified Data.ByteString            as BS
import qualified Data.ByteString.Base64     as Base64
import qualified Data.ByteString.Char8      as C8
import           Data.ByteString.Lazy       (ByteString, fromStrict, toStrict)
import qualified Data.ByteString.UTF8       as BSUTF8
import           Data.Maybe                 (fromMaybe)
import           Data.Monoid                ((<>))
import           Data.Text
import qualified Data.Text.Encoding         as TextEncoding
import           Data.Text.IO               as TIO
import           Data.Time.Calendar
import           Data.Time.Clock
import           GHC.Generics
import           Kafka.Consumer
    ( BrokerAddress (..)
    , ConsumerGroupId (..)
    , ConsumerRecord (..)
    , OffsetReset (..)
    , Timeout (..)
    , TopicName (..)
    , brokersList
    , groupId
    , logLevel
    , noAutoCommit
    , offsetReset
    , topics
    )
import qualified Kafka.Producer             as Producer
import           Kafka.Types                (KafkaLogLevel (..))
import           Pipes                      (lift, runEffect, (>->))
import qualified Pipes                      as P
import           Pipes.Kafka
import qualified Pipes.Prelude              as P
import qualified Pipes.Safe                 as PS
import           System.Environment         (getExecutablePath, lookupEnv)
import           System.FilePath
import           Text.Pandoc                hiding
    (getCurrentTime, getDataFileName, lookupEnv)
import qualified Text.Pandoc.Builder        as PB
import           Text.Pandoc.Definition     (Inline (..), Meta (..))


data Config = Config {
    css      :: !C8.ByteString
  , template :: !String
  , time     :: !UTCTime
  , servers  :: ![BrokerAddress]
  } deriving (Show)


processHyphe
  :: ConsumerRecord (Maybe C8.ByteString) (Maybe C8.ByteString)
  -> ReaderT Config Maybe C8.ByteString
processHyphe ConsumerRecord{crValue} = do
  json                <- TextEncoding.decodeUtf8 <$> crValue & lift
  (title, hyphenated) <- each (pluck json) ("title", "hyphenated") & lift
  byline              <- pluck json "byline" <|> pure "unknown" & lift
  epub                <- html2epub title byline hyphenated
  pure $ TextEncoding.encodeUtf8 $ json & _Object . at "epub" ?~ Aeson.String (epub64 epub)

  where
    epub64 = TextEncoding.decodeUtf8 . Base64.encode . toStrict
    html2epub title author html = do
      Config{css, template, time} <- ask
      lift $ hush $ runPure $ do
        modifyPureState $ \ s ->
          s{stFiles = insertInFileTree "epub.css" (FileInfo time css) mempty}
        readHtml def html
          >>= setMetadata title author
          >>= writeEPUB3 def { writerTemplate = Just template }
    setMetadata title author doc =
      pure $ PB.setTitle (conv title)
      $ PB.setAuthors [conv author]
      $ PB.setMeta "css" ("epub.css" :: FilePath) doc
      where
        conv = PB.text . unpack
    pluck json k = json ^? key k . _String


main :: IO ()
main = do
  path <- takeDirectory <$> getExecutablePath
  config@Config{servers} <- Config
    <$> BS.readFile (path </> "data/ebook.css")
    <*> (BSUTF8.toString <$> BS.readFile (path </> "data/template.t"))
    <*> getCurrentTime
    <*> (fmap BrokerAddress
         . splitOn ","
         . pack
         .  fromMaybe "localhost:9092"
         <$> lookupEnv "KAFKA_BOOTSTRAP_SERVERS")

  let pipe = P.for source (P.each . process) >-> sink
      process = flip runReaderT config . processHyphe
      sink = kafkaSink producerProps (TopicName "pubes")
      producerProps =
          Producer.brokersList servers
          <> Producer.logLevel KafkaLogErr
      source = kafkaSource consumerProps consumerSub (Timeout 1000)
      consumerProps =
        brokersList servers
        <> groupId (ConsumerGroupId "pubes")
        <> logLevel KafkaLogErr
      consumerSub = topics [TopicName "hyphe"]
                    <> offsetReset Earliest

  runNoLoggingT $ PS.runSafeT $ runEffect pipe
