-- File auto generated by purescript-bridge! --
module Plutus.V1.Ledger.Credential where

import Prelude

import Control.Lazy (defer)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Argonaut.Encode.Aeson as E
import Data.BigInt.Argonaut (BigInt)
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Plutus.V1.Ledger.Crypto (PubKeyHash)
import Type.Proxy (Proxy(Proxy))

data Credential
  = PubKeyCredential PubKeyHash
  | ScriptCredential String

derive instance Eq Credential

derive instance Ord Credential

instance Show Credential where
  show a = genericShow a

instance EncodeJson Credential where
  encodeJson = defer \_ -> case _ of
    PubKeyCredential a -> E.encodeTagged "PubKeyCredential" a E.value
    ScriptCredential a -> E.encodeTagged "ScriptCredential" a E.value

instance DecodeJson Credential where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "Credential"
    $ Map.fromFoldable
        [ "PubKeyCredential" /\ D.content (PubKeyCredential <$> D.value)
        , "ScriptCredential" /\ D.content (ScriptCredential <$> D.value)
        ]

derive instance Generic Credential _

--------------------------------------------------------------------------------

_PubKeyCredential :: Prism' Credential PubKeyHash
_PubKeyCredential = prism' PubKeyCredential case _ of
  (PubKeyCredential a) -> Just a
  _ -> Nothing

_ScriptCredential :: Prism' Credential String
_ScriptCredential = prism' ScriptCredential case _ of
  (ScriptCredential a) -> Just a
  _ -> Nothing

--------------------------------------------------------------------------------

data StakingCredential
  = StakingHash Credential
  | StakingPtr BigInt BigInt BigInt

derive instance Eq StakingCredential

derive instance Ord StakingCredential

instance Show StakingCredential where
  show a = genericShow a

instance EncodeJson StakingCredential where
  encodeJson = defer \_ -> case _ of
    StakingHash a -> E.encodeTagged "StakingHash" a E.value
    StakingPtr a b c -> E.encodeTagged "StakingPtr" (a /\ b /\ c)
      (E.tuple (E.value >/\< E.value >/\< E.value))

instance DecodeJson StakingCredential where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "StakingCredential"
    $ Map.fromFoldable
        [ "StakingHash" /\ D.content (StakingHash <$> D.value)
        , "StakingPtr" /\ D.content
            (D.tuple $ StakingPtr </$\> D.value </*\> D.value </*\> D.value)
        ]

derive instance Generic StakingCredential _

--------------------------------------------------------------------------------

_StakingHash :: Prism' StakingCredential Credential
_StakingHash = prism' StakingHash case _ of
  (StakingHash a) -> Just a
  _ -> Nothing

_StakingPtr
  :: Prism' StakingCredential { a :: BigInt, b :: BigInt, c :: BigInt }
_StakingPtr = prism' (\{ a, b, c } -> (StakingPtr a b c)) case _ of
  (StakingPtr a b c) -> Just { a, b, c }
  _ -> Nothing
