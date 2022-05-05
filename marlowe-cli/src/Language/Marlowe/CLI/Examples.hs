-----------------------------------------------------------------------------
--
-- Module      :  $Headers
-- License     :  Apache 2.0
--
-- Stability   :  Experimental
-- Portability :  Portable
--
-- | Example contracts.
--
-----------------------------------------------------------------------------


{-# LANGUAGE RecordWildCards #-}


module Language.Marlowe.CLI.Examples (
-- * Contracts
  makeExample
) where


import Control.Monad.Except (MonadIO, liftIO)
import Data.Aeson.Encode.Pretty (encodePretty)
import Language.Marlowe.Semantics (MarloweData (..))
import Language.Marlowe.Util (merkleize)

import qualified Data.ByteString.Lazy as LBS (writeFile)


-- | Serialise an example contract to JSON.
makeExample :: MonadIO m
            => Bool            -- ^ Flag for merkleized output
            -> FilePath        -- ^ The output JSON file for the Marlowe contract.
            -> FilePath        -- ^ The output JSON file for the Marlowe contract's state.
            -> MarloweData     -- ^ The contract and state data.
            -> m ()            -- ^ Action to serialise the Marlowe data.
makeExample merkleized contractFile stateFile MarloweData {..} =
  liftIO $
    do
      if merkleized
        then LBS.writeFile contractFile . encodePretty $ merkleize marloweContract
        else LBS.writeFile contractFile . encodePretty $ marloweContract
      LBS.writeFile stateFile . encodePretty $ marloweState
