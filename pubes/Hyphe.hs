{-# LANGUAGE DeriveGeneric #-}

module Hyphe where

import Data.Aeson
import GHC.Generics
import Data.Text

data Hyphe = Hyphe {
    url        :: Text
  , from       :: Text
  , html       :: Text
  , title      :: Text
  , content    :: Text
  , hyphenated :: Text
  , length     :: Int
  , excerpt    :: Text
  , byline     :: Maybe Text
  , dir        :: Maybe Text
  , lang       :: Text
  } deriving (Generic, Show)

instance FromJSON Hyphe
