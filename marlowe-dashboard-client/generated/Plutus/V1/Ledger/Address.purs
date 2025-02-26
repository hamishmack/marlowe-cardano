-- File auto generated by purescript-bridge! --
module Plutus.V1.Ledger.Address where

import Prelude

import Control.Lazy (defer)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Argonaut.Encode.Aeson as E
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Plutus.V1.Ledger.Credential (Credential, StakingCredential)
import Type.Proxy (Proxy(Proxy))

newtype Address = Address
  { addressCredential :: Credential
  , addressStakingCredential :: Maybe StakingCredential
  }

derive instance Eq Address

derive instance Ord Address

instance Show Address where
  show a = genericShow a

instance EncodeJson Address where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { addressCredential: E.value :: _ Credential
        , addressStakingCredential:
            (E.maybe E.value) :: _ (Maybe StakingCredential)
        }
    )

instance DecodeJson Address where
  decodeJson = defer \_ -> D.decode $
    ( Address <$> D.record "Address"
        { addressCredential: D.value :: _ Credential
        , addressStakingCredential:
            (D.maybe D.value) :: _ (Maybe StakingCredential)
        }
    )

derive instance Generic Address _

derive instance Newtype Address _

--------------------------------------------------------------------------------

_Address
  :: Iso' Address
       { addressCredential :: Credential
       , addressStakingCredential :: Maybe StakingCredential
       }
_Address = _Newtype
