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
import           Text.Pandoc
import qualified Text.Pandoc.Builder    as PB
import           Text.Pandoc.Definition (Inline (..), Meta (..))


processArticle
  :: C8.ByteString
  -> String
  -> ConsumerRecord (Maybe C8.ByteString) (Maybe C8.ByteString)
  -> Maybe C8.ByteString
processArticle css template ConsumerRecord{crValue} = do
  v <- crValue
  article@Article{content,title,byline} <- decode $ fromStrict v
  epub <- hush $ html2epub title byline content css template
  pure $ toStrict . encode $ article2epub article (epub64 epub)

  where
    article2epub Article{..} epub = Epub{..}
    dummyTime = (UTCTime (ModifiedJulianDay 0) (secondsToDiffTime 0))
    epub64 = decodeUtf8 . Base64.encode . toStrict
    html2epub title author html css template = runPure $ do
      modifyPureState $ \ s ->
        s{stFiles = insertInFileTree "epub.css" (FileInfo dummyTime css) mempty}
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
  runNoLoggingT $ PS.runSafeT $ runEffect $ pipe css template
  where
    pipe css template = P.for source (P.each . processArticle css template) >-> sink
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
