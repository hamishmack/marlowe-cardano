-- File auto generated by purescript-bridge! --
module Ledger.TimeSlot where

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
import Data.Newtype (class Newtype, unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple (Tuple)
import Data.Tuple.Nested ((/\))
import Plutus.V1.Ledger.Slot (Slot)
import Plutus.V1.Ledger.Time (POSIXTime)
import Type.Proxy (Proxy(Proxy))

newtype SlotConfig = SlotConfig
  { scSlotLength :: BigInt
  , scSlotZeroTime :: POSIXTime
  }

derive instance Eq SlotConfig

instance Show SlotConfig where
  show a = genericShow a

instance EncodeJson SlotConfig where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { scSlotLength: E.value :: _ BigInt
        , scSlotZeroTime: E.value :: _ POSIXTime
        }
    )

instance DecodeJson SlotConfig where
  decodeJson = defer \_ -> D.decode $
    ( SlotConfig <$> D.record "SlotConfig"
        { scSlotLength: D.value :: _ BigInt
        , scSlotZeroTime: D.value :: _ POSIXTime
        }
    )

derive instance Generic SlotConfig _

derive instance Newtype SlotConfig _

--------------------------------------------------------------------------------

_SlotConfig
  :: Iso' SlotConfig { scSlotLength :: BigInt, scSlotZeroTime :: POSIXTime }
_SlotConfig = _Newtype

--------------------------------------------------------------------------------

newtype SlotConversionError = SlotOutOfRange
  { requestedSlot :: Slot
  , horizon :: Tuple Slot POSIXTime
  }

derive instance Eq SlotConversionError

instance Show SlotConversionError where
  show a = genericShow a

instance EncodeJson SlotConversionError where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { requestedSlot: E.value :: _ Slot
        , horizon: (E.tuple (E.value >/\< E.value)) :: _ (Tuple Slot POSIXTime)
        }
    )

instance DecodeJson SlotConversionError where
  decodeJson = defer \_ -> D.decode $
    ( SlotOutOfRange <$> D.record "SlotOutOfRange"
        { requestedSlot: D.value :: _ Slot
        , horizon: (D.tuple (D.value </\> D.value)) :: _ (Tuple Slot POSIXTime)
        }
    )

derive instance Generic SlotConversionError _

derive instance Newtype SlotConversionError _

--------------------------------------------------------------------------------

_SlotOutOfRange
  :: Iso' SlotConversionError
       { requestedSlot :: Slot, horizon :: Tuple Slot POSIXTime }
_SlotOutOfRange = _Newtype
