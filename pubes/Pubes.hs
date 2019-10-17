{-# LANGUAGE DeriveGeneric #-}

module Pubes where

import Data.Aeson
import GHC.Generics
import Data.Text
import Data.ByteString

data Pubes = Pubes {
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
  , epub :: Text
  } deriving (Generic, Show)

instance ToJSON Pubes
