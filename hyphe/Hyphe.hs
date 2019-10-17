{-# LANGUAGE DeriveGeneric #-}

module Hyphe where

import Data.Aeson
import GHC.Generics
import Data.Text
import Data.ByteString

data Hyphe = Hyphe {
    url  :: Text
  , from :: Text
  , html :: Text
  , title :: Text
  , content :: Text
  , length :: Int
  , excerpt :: Text
  , byline :: Maybe Text
  , dir :: Maybe Text
  , hyphenated :: Text
  } deriving (Generic, Show)

instance ToJSON Hyphe
