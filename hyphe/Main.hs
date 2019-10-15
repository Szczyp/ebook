{-# LANGUAGE DuplicateRecordFields, NamedFieldPuns, OverloadedStrings,
             RecordWildCards #-}

module Main where

import Article
import Hyphenated

import qualified Control.Monad.Logger   as Logger
import qualified Data.Aeson             as Aeson
import qualified Data.ByteString.Char8  as Char8
import qualified Data.ByteString.Lazy   as ByteString
import qualified Data.Maybe             as Maybe
import           Data.Text              (Text)
import qualified Data.Text              as Text
import qualified Data.Text.IO           as TextIO
import qualified Data.Text.Lazy         as TextLazy
import qualified Kafka.Consumer         as KafkaConsumer
import qualified Kafka.Producer         as KafkaProducer
import           Kafka.Types            (KafkaLogLevel (..))
import           Pipes                  ((>->))
import qualified Pipes
import qualified Pipes.Kafka            as PipesKafka
import qualified Pipes.Prelude          as PipesPrelude
import qualified Pipes.Safe             as PipesSafe
import qualified System.Environment     as Environment
import           Text.HTML.TagSoup      (Tag (..))
import qualified Text.HTML.TagSoup      as TagSoup
import           Text.HTML.TagSoup.Tree (TagTree (..))
import qualified Text.HTML.TagSoup.Tree as TagSoupTree
import qualified Text.Hyphenation       as Hyphenation


hyphenate :: Text -> Text
hyphenate = Text.unwords
            . map (Text.intercalate "\173"
                   . map Text.pack
                   . Hyphenation.hyphenate Hyphenation.english_US{ Hyphenation.hyphenatorLeftMin = 3
                                                                 , Hyphenation.hyphenatorRightMin = 3 }
                   . Text.unpack)
            . Text.words


hyphenateContent = TagSoupTree.renderTree . TagSoupTree.transformTree f . TagSoupTree.parseTree
  where
    f (TagLeaf (TagText txt)) = [TagLeaf (TagText $ hyphenate txt)]
    f x                       = [x]


processArticle
  :: KafkaConsumer.ConsumerRecord (Maybe Char8.ByteString) (Maybe Char8.ByteString)
  -> Maybe Char8.ByteString
processArticle KafkaConsumer.ConsumerRecord{KafkaConsumer.crValue} = do
  v <- crValue
  article@Article{content} <- Aeson.decode (ByteString.fromStrict v)
  pure $ ByteString.toStrict . Aeson.encode . article2hyphenated (hyphenateContent content) $ article
  where
    article2hyphenated hyphenated Article{..} = Hyphenated{..}


main :: IO ()
main = do
  servers <- fmap KafkaConsumer.BrokerAddress
             . Text.splitOn ","
             . Text.pack
             .  Maybe.fromMaybe "localhost:9092"
             <$> Environment.lookupEnv "KAFKA_BOOTSTRAP_SERVERS"

  let pipe = Pipes.for source (Pipes.each . processArticle) >-> sink
      sink = PipesKafka.kafkaSink producerProps (KafkaProducer.TopicName "hyphen")
      producerProps =
        KafkaProducer.brokersList servers
        <> KafkaProducer.logLevel KafkaLogErr
      source = PipesKafka.kafkaSource consumerProps consumerSub (KafkaConsumer.Timeout 1000)
      consumerProps =
        KafkaConsumer.brokersList servers
        <> KafkaConsumer.groupId (KafkaConsumer.ConsumerGroupId "hyphe")
        <> KafkaConsumer.logLevel KafkaLogErr
      consumerSub = KafkaConsumer.topics [KafkaConsumer.TopicName "articles"]
                    <> KafkaConsumer.offsetReset KafkaConsumer.Earliest

  Logger.runNoLoggingT $ PipesSafe.runSafeT $ Pipes.runEffect pipe
