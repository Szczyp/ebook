{-# LANGUAGE DeriveGeneric #-}

module Parrot where

import Data.Aeson
import GHC.Generics
import Data.Text

data Parrot = Parrot {
    url     :: Text
  , from    :: Text
  , html    :: Text
  , title   :: Text
  , content :: Text
  , length  :: Int
  , excerpt :: Text
  , byline  :: Maybe Text
  , dir     :: Maybe Text
  , lang    :: Text
  } deriving (Generic, Show)

instance FromJSON Parrot
