{-# LANGUAGE DeriveGeneric #-}

module Hyphenated where

import Data.Aeson
import GHC.Generics
import Data.Text

data Hyphenated = Hyphenated {
    url  :: Text
  , from :: Text
  , html :: Text
  , title :: Text
  , content :: Text
  , hyphenated :: Text
  , length :: Int
  , excerpt :: Text
  , byline :: Maybe Text
  , dir :: Maybe Text
  } deriving (Generic, Show)

instance FromJSON Hyphenated
