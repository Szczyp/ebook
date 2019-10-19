{-# LANGUAGE DuplicateRecordFields, NamedFieldPuns, OverloadedStrings,
             RecordWildCards #-}

module Main where

import Hyphe
import Parrot

import qualified Control.Monad.Logger      as Logger
import qualified Data.Aeson                as Aeson
import qualified Data.ByteString.Char8     as Char8
import qualified Data.ByteString.Lazy      as ByteString
import qualified Data.Maybe                as Maybe
import           Data.Text                 (Text)
import qualified Data.Text                 as Text
import qualified Data.Text.IO              as TextIO
import qualified Data.Text.Lazy            as TextLazy
import qualified Kafka.Consumer            as KafkaConsumer
import qualified Kafka.Producer            as KafkaProducer
import           Kafka.Types               (KafkaLogLevel (..))
import           Pipes                     ((>->))
import qualified Pipes
import qualified Pipes.Kafka               as PipesKafka
import qualified Pipes.Prelude             as PipesPrelude
import qualified Pipes.Safe                as PipesSafe
import qualified System.Environment        as Environment
import           Text.HTML.TagSoup         (Tag (..))
import qualified Text.HTML.TagSoup         as TagSoup
import           Text.HTML.TagSoup.Tree    (TagTree (..))
import qualified Text.HTML.TagSoup.Tree    as TagSoupTree
import qualified Text.Hyphenation          as Hyphenation
import           Text.Hyphenation.Language (Language (..))
import qualified Text.Hyphenation.Language as HyphenationLanguage


hyphenate :: Text -> Text -> Text
hyphenate lang text = case parrot2Language lang of
  Nothing -> text
  Just l  -> parse l text

  where
    hyphe l = Text.unwords
            . map (Text.intercalate "\173"
                   . map Text.pack
                   . Hyphenation.hyphenate
                    (HyphenationLanguage.languageHyphenator l)
                    { Hyphenation.hyphenatorLeftMin = 3
                    , Hyphenation.hyphenatorRightMin = 3 }
                   . Text.unpack)
            . Text.words

    parse l = TagSoupTree.renderTree . TagSoupTree.transformTree (f l) . TagSoupTree.parseTree

    f l (TagLeaf (TagText txt)) = [TagLeaf (TagText $ hyphe l txt)]
    f l x                       = [x]


parrot2Language :: Text -> Maybe Language
parrot2Language lang = case lang of
  "afr" -> Just Afrikaans
  "hye" -> Just Armenian
  "ben" -> Just Bengali
  "bul" -> Just Bulgarian
  "cat" -> Just Catalan
  "cmn" -> Just Chinese
  "hrv" -> Just Croatian
  "ces" -> Just Czech
  "dan" -> Just Danish
  "nld" -> Just Dutch
  "eng" -> Just English_US
  "epo" -> Just Esperanto
  "est" -> Just Estonian
  "fin" -> Just Finnish
  "fra" -> Just French
  "glg" -> Just Galician
  "kat" -> Just Georgian
  "deu" -> Just German_1996
  "ell" -> Just Greek_Poly
  "guj" -> Just Gujarati
  "hin" -> Just Hindi
  "hun" -> Just Hungarian
  "ind" -> Just Indonesian
  "ita" -> Just Italian
  "kan" -> Just Kannada
  "lav" -> Just Latvian
  "lit" -> Just Lithuanian
  "mal" -> Just Malayalam
  "mar" -> Just Marathi
  "khk" -> Just Mongolian
  "nob" -> Just Norwegian_Bokmal
  "nno" -> Just Norwegian_Nynorsk
  "ori" -> Just Oriya
  "pan" -> Just Panjabi
  "pol" -> Just Polish
  "por" -> Just Portuguese
  "ron" -> Just Romanian
  "rus" -> Just Russian
  "srp" -> Just Serbian_Cyrillic
  "slk" -> Just Slovak
  "slv" -> Just Slovenian
  "spa" -> Just Spanish
  "swe" -> Just Swedish
  "tam" -> Just Tamil
  "tel" -> Just Telugu
  "tha" -> Just Thai
  "tur" -> Just Turkish
  "tuk" -> Just Turkmen
  "ukr" -> Just Ukrainian
  _     -> Nothing


processParrot
  :: KafkaConsumer.ConsumerRecord (Maybe Char8.ByteString) (Maybe Char8.ByteString)
  -> Maybe Char8.ByteString
processParrot KafkaConsumer.ConsumerRecord{KafkaConsumer.crValue} = do
  v <- crValue
  parrot@Parrot{content,lang} <- Aeson.decode (ByteString.fromStrict v)
  pure $ ByteString.toStrict . Aeson.encode . parrot2hyphe (hyphenate lang content) $ parrot

  where
    parrot2hyphe hyphenated Parrot{..} = Hyphe{..}


main :: IO ()
main = do
  servers <- fmap KafkaConsumer.BrokerAddress
             . Text.splitOn ","
             . Text.pack
             .  Maybe.fromMaybe "localhost:9092"
             <$> Environment.lookupEnv "KAFKA_BOOTSTRAP_SERVERS"

  let pipe = Pipes.for source (Pipes.each . processParrot) >-> sink
      sink = PipesKafka.kafkaSink producerProps (KafkaProducer.TopicName "hyphe")
      producerProps =
        KafkaProducer.brokersList servers
        <> KafkaProducer.logLevel KafkaLogErr
      source = PipesKafka.kafkaSource consumerProps consumerSub (KafkaConsumer.Timeout 1000)
      consumerProps =
        KafkaConsumer.brokersList servers
        <> KafkaConsumer.groupId (KafkaConsumer.ConsumerGroupId "hyphe")
        <> KafkaConsumer.logLevel KafkaLogErr
      consumerSub = KafkaConsumer.topics [KafkaConsumer.TopicName "parrot"]
                    <> KafkaConsumer.offsetReset KafkaConsumer.Earliest

  Logger.runNoLoggingT $ PipesSafe.runSafeT $ Pipes.runEffect pipe
