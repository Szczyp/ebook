{-# LANGUAGE DeriveGeneric, DuplicateRecordFields, NamedFieldPuns,
             OverloadedStrings, RecordWildCards, StrictData #-}

module Main where

import Article
import Epub

import           Control.Error.Util
import           Control.Monad          (void)
import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Logger   (runNoLoggingT, runStdoutLoggingT)
import           Data.Aeson
import qualified Data.ByteString        as BS
import qualified Data.ByteString.Base64 as Base64
import qualified Data.ByteString.Char8  as C8
import           Data.ByteString.Lazy   (ByteString, fromStrict, toStrict)
import           Data.Monoid            ((<>))
import           Data.Text
import           Data.Text.Encoding
import           Data.Text.IO           as TIO
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
import qualified Kafka.Producer         as Producer
import           Kafka.Types            (KafkaLogLevel (..))
import           Pipes                  (runEffect, (>->))
import qualified Pipes                  as P
import           Pipes.Kafka
import qualified Pipes.Prelude          as P
import qualified Pipes.Safe             as PS
import           System.FilePath
import           Text.Pandoc hiding (Reader, getCurrentTime)
import qualified Text.Pandoc.Builder    as PB
import           Text.Pandoc.Definition (Inline (..), Meta (..))
import Control.Monad.Trans.Reader
import Control.Monad.Trans


data Config = Config {
    css :: C8.ByteString
  , template :: String
  , time :: UTCTime
                     } deriving (Show)

processArticle
  :: ConsumerRecord (Maybe C8.ByteString) (Maybe C8.ByteString)
  -> ReaderT Config Maybe C8.ByteString
processArticle ConsumerRecord{crValue} = do
  v <- lift crValue
  article@Article{content,title,byline} <- lift $ decode (fromStrict v)
  epub <- html2epub title byline content css template
  pure $ toStrict . encode $ article2epub article (epub64 epub)

  where
    article2epub Article{..} epub = Epub{..}
    epub64 = decodeUtf8 . Base64.encode . toStrict
    html2epub title author html css template = do
      Config css template time <- ask
      lift $ hush $ runPure $ do
      modifyPureState $ \ s ->
        s{stFiles = insertInFileTree "epub.css" (FileInfo time css) mempty}
      readHtml def html
        >>= setMetadata title author
        >>= writeEPUB3 def { writerTemplate = (Just template) }
    setMetadata title author doc =
      pure $ PB.setTitle (conv title)
      $ PB.setAuthors [maybe (PB.text "unknown") conv author]
      $ PB.setMeta "css" ("epub.css" :: FilePath) $ doc
      where conv = PB.text . unpack


main :: IO ()
main = do
  css <- BS.readFile "ebook.css"
  template <- Prelude.readFile "template.t"
  time <- getCurrentTime
  let config = Config css template time
  runNoLoggingT $ PS.runSafeT $ runEffect $ pipe config
  where
    pipe config = P.for source (P.each . flip runReaderT config . processArticle) >-> sink
    sink = kafkaSink producerProps (TopicName "epub")
    producerProps =
         Producer.brokersList [BrokerAddress "localhost:9092"]
      <> Producer.logLevel KafkaLogErr
    source = kafkaSource consumerProps consumerSub (Timeout 1000)
    consumerProps =
      brokersList [BrokerAddress "localhost:9092"] <>
      groupId (ConsumerGroupId "pubes") <>
      logLevel KafkaLogErr
    consumerSub = topics [TopicName "articles"] <> offsetReset Earliest
