{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main (main) where

import Lens.Micro.Platform
import Data.Aeson
import qualified Data.Char as DC
import qualified Data.Text as DT
import GHC.IO.Encoding (setLocaleEncoding, utf8)
import qualified Relude.Unsafe as Unsafe
import qualified System.Environment as SE
import System.Nixpkgs.FirefoxAddons

data Addon = Addon { slug :: Text
                   , pname :: Maybe Text
                   , license :: Maybe AddonLicense
                   }
  deriving (Show, Generic)

instance FromJSON Addon

instance FromJSON AddonLicense where
  parseJSON =
    let toLowerInit (h, t) = DT.toLower h <> t
        opts = defaultOptions
          { constructorTagModifier = toString
                                     . DT.toLower
                                     . Unsafe.fromJust
                                     . DT.stripPrefix "AddonLicense"
                                     . toText
          , fieldLabelModifier     = toString
                                     . toLowerInit
                                     . DT.span DC.isUpper
                                     . Unsafe.fromJust
                                     . DT.stripPrefix "addonLicense"
                                     . toText
          }
    in  genericParseJSON opts

data CmdArgs = CmdArgs { inputFile :: FilePath
                       , outputFile :: FilePath
                       }
               deriving (Eq, Show)

parseArgs :: IO CmdArgs
parseArgs = SE.getArgs >>= parse
  where
    usage =
      do
        progName <- SE.getProgName
        putTextLn $ toText progName <> " IN_FILE OUT_FILE"
        putTextLn ""
        putTextLn "where IN_FILE is a JSON file containing a list of addons"
        putTextLn "and OUT_FILE is the Nix expression destination."
        exitSuccess

    parse ["--help"] = usage
    parse [jsonFile, nixFile] = pure $ CmdArgs jsonFile nixFile
    parse _          = usage

fetchAddons :: FilePath -> [Addon] -> IO ()
fetchAddons outputFile addons = addonsExpr >>= writeFileText outputFile
  where
    addonsExpr = generateFirefoxAddonPackages . map mkAddonReq $ addons
    mkAddonReq Addon {..} = AddonReq slug (
      maybe id (set addonLicense . Just) license
      . maybe id (addonNixName .~) pname)

printAndPanic :: String -> IO ()
printAndPanic t = putStrLn t >> exitFailure

main :: IO ()
main =
  do
    setLocaleEncoding utf8
    CmdArgs {..} <- parseArgs

    decoded <- eitherDecodeFileStrict' inputFile
    either printAndPanic (fetchAddons outputFile) decoded
