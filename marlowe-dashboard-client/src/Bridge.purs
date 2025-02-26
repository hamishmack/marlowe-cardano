module Bridge
  ( _bridge
  , class Bridge
  , toFront
  , toBack
  ) where

import Prologue

import Data.Bifunctor (bimap)
import Data.BigInt.Argonaut (BigInt)
import Data.Lens (Iso', iso)
import Data.Map (Map, fromFoldable, toUnfoldable) as Front
import Data.Newtype (unwrap)
import Data.Tuple.Nested ((/\))
import Marlowe.Semantics (Assets(..)) as Front
import Network.RemoteData (RemoteData)
import Plutus.V1.Ledger.Crypto (PubKey(..)) as Back
import Plutus.V1.Ledger.Value (CurrencySymbol(..), TokenName(..), Value(..)) as Back
import PlutusTx.AssocMap (Map(..)) as Back

{-
Note [JSON communication]: To ensure the client and the PAB server understand each other, they have
to be able to serialize/deserialize data in the same way. This is achieved in two ways:

1. Using PureScript types that are automatically generated from the Haskell code by Servant.PureScript.
2. Creating our own custom JSON encode/decode instances and making sure that they match.

In general, method 1 is preferable (no risk of human error), but method 2 is used for the
Marlowe.Contract. This is because we want custom encode/decode instances for Marlowe contracts anyway
(making the JSON more readable makes the JavaScript implementation of Marlowe nicer, since this works
by writing the contract as JSON directly.

There are two issues with method 1. First, the Haskell code uses a custom `PlutusTx.AssocMap` instead
of the standard `Data.Map`, a complication that is unnecessary on the PureScript side. Second, the
Haskell code uses the newtype record shorthand a lot (e.g. newtype Slot = { getSlot: Integer }), which
PureScript takes literally. Using these types directly in the PureScript code thus leads to a lot of
tedious boilerplate.

This module takes care of these issues by providing an isomorphism between relevant backend types and
their PureScript-friendly counterparts. Note, however, that the mappings should *not* be used for
Marlowe contracts, since for these we have the custom JSON encode/decode instances.
-}
_bridge :: forall a b. Bridge a b => Iso' a b
_bridge = iso toFront toBack

class Bridge a b where
  toFront :: a -> b
  toBack :: b -> a

instance webDataBridge ::
  ( Bridge a b
  ) =>
  Bridge (RemoteData e a) (RemoteData e b) where
  toFront = map toFront
  toBack = map toBack

instance tupleBridge ::
  ( Bridge a c
  , Bridge b d
  ) =>
  Bridge (Tuple a b) (Tuple c d) where
  toFront (a /\ b) = toFront a /\ toFront b
  toBack (c /\ d) = toBack c /\ toBack d

instance arrayBridge :: Bridge a b => Bridge (Array a) (Array b) where
  toFront = map toFront
  toBack = map toBack

instance eitherBridge ::
  ( Bridge a c
  , Bridge b d
  ) =>
  Bridge (Either a b) (Either c d) where
  toFront = bimap toFront toFront
  toBack = bimap toBack toBack

instance maybeBridge :: (Bridge a b) => Bridge (Maybe a) (Maybe b) where
  toFront = map toFront
  toBack = map toBack

instance mapBridge ::
  ( Ord a
  , Ord c
  , Bridge a c
  , Bridge b d
  ) =>
  Bridge (Back.Map a b) (Front.Map c d) where
  toFront map = Front.fromFoldable $ toFront <$> unwrap map
  toBack map = Back.Map $ toBack <$> Front.toUnfoldable map

instance bigIntegerBridge :: Bridge BigInt BigInt where
  toFront = identity
  toBack = identity

-- TODO: Marlowe.Semantics.PubKey is currently just an alias for String
instance pubKeyBridge :: Bridge Back.PubKey String where
  toFront (Back.PubKey { getPubKey }) = getPubKey
  toBack getPubKey = Back.PubKey { getPubKey }

-- TODO: the Haskell type is called 'Value' but the PureScript type is called 'Assets'
instance valueBridge :: Bridge Back.Value Front.Assets where
  toFront (Back.Value { getValue }) = Front.Assets $ toFront getValue
  toBack (Front.Assets getValue) = Back.Value { getValue: toBack getValue }

-- TODO: Marlowe.Semantics.TokenName is currently just an alias for String
instance tokenNameBridge :: Bridge Back.TokenName String where
  toFront (Back.TokenName { unTokenName }) = unTokenName
  toBack unTokenName = Back.TokenName { unTokenName }

-- TODO: Marlowe.Semantics.CurrencySymbol is currently just an alias for String
instance currencySymbolBridge :: Bridge Back.CurrencySymbol String where
  toFront (Back.CurrencySymbol { unCurrencySymbol }) = unCurrencySymbol
  toBack unCurrencySymbol = Back.CurrencySymbol { unCurrencySymbol }
