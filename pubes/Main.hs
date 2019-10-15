{-# LANGUAGE DuplicateRecordFields, NamedFieldPuns, OverloadedStrings,
             RecordWildCards, StrictData #-}

module Main where

import Hyphenated
import Epub

import           Control.Error.Util
import           Control.Monad              (void)
import           Control.Monad.IO.Class     (liftIO)
import           Control.Monad.Logger       (runNoLoggingT, runStdoutLoggingT)
import           Control.Monad.Trans.Reader
import           Data.Aeson
import qualified Data.ByteString            as BS
import qualified Data.ByteString.Base64     as Base64
import qualified Data.ByteString.Char8      as C8
import           Data.ByteString.Lazy       (ByteString, fromStrict, toStrict)
import           Data.Maybe                 (fromMaybe)
import           Data.Monoid                ((<>))
import           Data.Text
import           Data.Text.Encoding
import           Data.Text.IO               as TIO
import           Data.Time.Calendar
import           Data.Time.Clock
import           Debug.Trace
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
import           System.Environment         (lookupEnv)
import           System.FilePath
import           Text.Pandoc                hiding (getCurrentTime, lookupEnv)
import qualified Text.Pandoc.Builder        as PB
import           Text.Pandoc.Definition     (Inline (..), Meta (..))


data Config = Config {
    css      :: !C8.ByteString
  , template :: !String
  , time     :: !UTCTime
  , servers  :: ![BrokerAddress]
  } deriving (Show)


processHyphenated
  :: ConsumerRecord (Maybe C8.ByteString) (Maybe C8.ByteString)
  -> ReaderT Config Maybe C8.ByteString
processHyphenated ConsumerRecord{crValue} = do
  v <- lift crValue
  article@Hyphenated{hyphenated,title,byline} <- lift $ decode (fromStrict v)
  epub <- html2epub title byline hyphenated css template
  pure $ toStrict . encode $ article2epub article (epub64 epub)

  where
    article2epub Hyphenated{..} epub = Epub{..}
    epub64 = decodeUtf8 . Base64.encode . toStrict
    html2epub title author html css template = do
      Config{css, template, time} <- ask
      lift $ hush $ runPure $ do
        modifyPureState $ \ s ->
          s{stFiles = insertInFileTree "epub.css" (FileInfo time css) mempty}
        readHtml def html
          >>= setMetadata title author
          >>= writeEPUB3 def { writerTemplate = Just template }
    setMetadata title author doc =
      pure $ PB.setTitle (conv title)
      $ PB.setAuthors [maybe (PB.text "unknown") conv author]
      $ PB.setMeta "css" ("epub.css" :: FilePath) doc
      where
        conv = PB.text . unpack


main :: IO ()
main = do
  config@Config{servers} <- Config
    <$> BS.readFile "data/ebook.css"
    <*> Prelude.readFile "data/template.t"
    <*> getCurrentTime
    <*> (fmap BrokerAddress
         . splitOn ","
         . pack
         .  fromMaybe "localhost:9092"
         <$> lookupEnv "KAFKA_BOOTSTRAP_SERVERS")

  let pipe = P.for source (P.each . process) >-> sink
      process = flip runReaderT config . processHyphenated
      sink = kafkaSink producerProps (TopicName "epub")
      producerProps =
          Producer.brokersList servers
          <> Producer.logLevel KafkaLogErr
      source = kafkaSource consumerProps consumerSub (Timeout 1000)
      consumerProps =
        brokersList servers
        <> groupId (ConsumerGroupId "pubes")
        <> logLevel KafkaLogErr
      consumerSub = topics [TopicName "hyphen"]
                    <> offsetReset Earliest

  runNoLoggingT $ PS.runSafeT $ runEffect pipe
