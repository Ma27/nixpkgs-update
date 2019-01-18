{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}

module Main where

import OurPrelude

import Control.Applicative ((<**>))
import qualified Data.Text as T
import qualified Data.Text.IO as T
import DeleteMerged (deleteDone)
import qualified Options.Applicative as Opt
import System.Directory (getHomeDirectory)
import System.Posix.Env (getEnv)
import Update (updateAll)
import Utils (Options(..), setupNixpkgs)

default (T.Text)

data Mode
  = Update
  | DeleteDone
  | UpdateMergeBase

modeParser :: Opt.Parser Mode
modeParser =
  Opt.flag'
    Update
    (Opt.long "update" <> Opt.help "Update packages (default mode)") <|>
  Opt.flag'
    DeleteDone
    (Opt.long "delete-done" <>
     Opt.help "Delete branches from PRs that were merged or closed") <|>
  Opt.flag'
    UpdateMergeBase
    (Opt.long "update-merge-base" <>
     Opt.help "Updates the branch to use for updates")

programInfo :: Opt.ParserInfo Mode
programInfo =
  Opt.info
    (modeParser <**> Opt.helper)
    (Opt.fullDesc <> Opt.progDesc "Update packages in nixpkgs repository" <>
     Opt.header "nixpkgs-update")

makeOptions :: IO Options
makeOptions = do
  dry <- isJust <$> getEnv "DRY_RUN"
  homeDir <- T.pack <$> getHomeDirectory
  token <- T.strip <$> T.readFile "github_token.txt"
  return $ Options dry (homeDir <> "/.nixpkgs-update") token

main :: IO ()
main = do
  mode <- Opt.execParser programInfo
  options <- makeOptions
  updates <- T.readFile "packages-to-update.txt"
  setupNixpkgs
  case mode of
    DeleteDone -> deleteDone options
    Update -> updateAll options updates
    UpdateMergeBase -> return ()
