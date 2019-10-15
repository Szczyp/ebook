{-# LANGUAGE DeriveGeneric #-}

module Article where

import Data.Aeson
import GHC.Generics
import Data.Text

data Article = Article {
    url  :: Text
  , from :: Text
  , html :: Text
  , title :: Text
  , content :: Text
  , length :: Int
  , excerpt :: Text
  , byline :: Maybe Text
  , dir :: Maybe Text
  } deriving (Generic, Show)

instance FromJSON Article
