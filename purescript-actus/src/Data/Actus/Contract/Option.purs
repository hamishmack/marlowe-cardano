module Data.Actus.Contract.Option where

import Prelude

import Data.Actus.Types as Types
import Data.DateTime (DateTime)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)

newtype Contract = Contract
  ( Types.Contract
      ( calendar :: Types.Calendar
      , contractPerformance :: Types.ContractPerformance
      , contractStructure :: Types.ContractStructure
      , notionalPrincipal :: NotionalPrincipal
      , optionality :: Optionality
      , settlement :: Maybe Types.Settlement
      )
  )

derive instance eqContract :: Eq Contract
derive instance newtypeContract :: Newtype Contract _
derive instance genericContract :: Generic Contract _

mkContract
  :: DateTime
  -> Types.ContractRole
  -> String
  -> Types.Calendar
  -> Types.ContractPerformance
  -> Types.ContractStructure
  -> NotionalPrincipal
  -> Optionality
  -> Maybe Types.Settlement
  -> Contract
mkContract
  statusDate
  contractRole
  contractId
  calendar
  contractPerformance
  contractStructure
  notionalPrincipal
  optionality
  settlement =
  Contract
    { statusDate
    , contractRole
    , contractId
    , calendar
    , contractPerformance
    , contractStructure
    , notionalPrincipal
    , optionality
    , settlement
    }

type NotionalPrincipal =
  { maturityDate :: DateTime
  , purchase :: Maybe Types.ContractEndEvent
  , termination :: Maybe Types.ContractEndEvent
  }

mkNotionalPrincipal
  :: DateTime
  -> Maybe Types.ContractEndEvent
  -> Maybe Types.ContractEndEvent
  -> NotionalPrincipal
mkNotionalPrincipal maturityDate purchase termination =
  { maturityDate, purchase, termination }

type Optionality =
  { optionExerciseType :: Types.OptionExerciseType
  , optionExerciseEndDate :: DateTime
  , optionStrike1 :: Number
  , optionType :: Types.OptionType
  , cycle :: Maybe Types.AnchoredCycle
  }

mkOptionality
  :: Types.OptionExerciseType
  -> DateTime
  -> Number
  -> Types.OptionType
  -> Maybe Types.AnchoredCycle
  -> Optionality
mkOptionality
  optionExerciseType
  optionExerciseEndDate
  optionStrike1
  optionType
  cycle =
  { optionExerciseType
  , optionExerciseEndDate
  , optionStrike1
  , optionType
  , cycle
  }

