{-# LANGUAGE DeriveGeneric #-}

module Epub where

import Data.Aeson
import GHC.Generics
import Data.Text
import Data.ByteString

data Epub = Epub {
    url  :: Text
  , from :: Text
  , html :: Text
  , title :: Text
  , content :: Text
  , length :: Int
  , excerpt :: Text
  , byline :: Maybe Text
  , dir :: Maybe Text
  , epub :: Text
  } deriving (Generic, Show)

instance ToJSON Epub
