module Marlowe.Execution.Types
  ( State
  , PastState
  , PendingTimeouts
  , ContractAndState
  , PastAction(..)
  , TimeoutInfo
  , NamedAction(..)
  ) where

import Prologue

import Data.BigInt.Argonaut (BigInt)
import Data.DateTime.Instant (Instant)
import Data.Generic.Rep (class Generic)
import Data.List (List)
import Data.Map (Map)
import Data.Show.Generic (genericShow)
import Marlowe.Extended.Metadata (MetaData)
import Marlowe.PAB (PlutusAppId)
import Marlowe.Semantics
  ( AccountId
  , Accounts
  , Bound
  , ChoiceId
  , Contract
  , MarloweParams
  , Observation
  , Party
  , Payment
  , Token
  , TransactionInput
  , ValueId
  )
import Marlowe.Semantics (State) as Semantic

-- The execution state represents the status of a Marlowe contract synced with the PAB.
-- It is currently optmized for speed and ease of computation at expense of storage and clear
-- boundaries. For example in the history array we store the balance prior and after the
-- transaction input, and for timeouts we store the missed actions. This information is needed
-- only by the contract carousel (only 1 open at a time), but it's pre-calculated for all
-- contracts (even the closed ones).
-- TODO: Consider using Lazy computations
type State =
  { -- Current contract and state
    semanticState :: Semantic.State
  , contract :: Contract
  -- The initial contract is needed to calculate the participants
  , initialContract :: Contract
  , metadata :: MetaData
  , marloweParams :: MarloweParams
  , history :: Array PastState
  -- When the user submits a transaction, we save it here until we get confirmation from the PAB and
  -- can advance the contract. This enables us to show immediate feedback to the user while we wait.
  , mPendingTransaction :: Maybe TransactionInput

  , mPendingTimeouts :: Maybe PendingTimeouts
  , mNextTimeout :: Maybe Instant
  , followerAppId :: PlutusAppId
  }

type TimeoutInfo =
  { time :: Instant
  , missedActions :: Array NamedAction
  }

data PastAction
  = InputAction
  | TimeoutAction TimeoutInfo

derive instance Eq PastAction

type PastState =
  { balancesAtStart :: Accounts
  , action :: PastAction
  , txInput :: TransactionInput
  , balancesAtEnd :: Accounts
  , resultingPayments :: List Payment
  }

-- The contract and state usually goes together and allows you to speficy the "overall state"
-- of a contract.
-- TODO: see if we can come up with a better name and maybe move it to Marlowe.Semantic
type ContractAndState =
  { contract :: Contract
  , state :: Semantic.State
  }

-- This represents the timeouts that haven't been applied to the contract. When a step of a
-- contract has timed out, nothing happens until the next TransactionInput. This could be an
-- IDeposit or IChoose for the continuation contract, or an empty transaction to advance or even
-- close the contract. We store a separate ContractAndState from the "current" ContractAndState because
-- this is the predicted state that we would be in if we applied an empty transaction, and this
-- allows us to extract the NamedActions that need to be applied next. Also, we store the timeouts
-- as an Array because it is possible that multiple continuations have timedout before we advance
-- the contract.
type PendingTimeouts =
  { continuation :: ContractAndState
  , timeouts :: Array TimeoutInfo
  }

-- Represents the possible buttons that can be displayed on a contract step card
data NamedAction
  -- Equivalent to Semantics.Action(Deposit)
  -- Creates IDeposit
  = MakeDeposit AccountId Party Token BigInt
  -- Equivalent to Semantics.Action(Choice) but has ChosenNum since it is a stateful element that
  -- stores the users choice
  -- Creates IChoice
  | MakeChoice ChoiceId (Array Bound)
  -- Equivalent to Semantics.Action(Notify) (can be applied by any user)
  -- Creates INotify
  | MakeNotify Observation
  -- An empty transaction needs to be submitted in order to trigger a change in the contract and
  -- we work out the details of what will happen when this occurs, currently we are interested in
  -- any payments that will be made and new bindings that will be evaluated
  -- Creates empty tx
  | Evaluate { payments :: Array Payment, bindings :: Map ValueId BigInt }
  -- A special case of Evaluate where the only way the Contract can progress is to apply an empty
  -- transaction which results in the contract being closed
  -- Creates empty tx
  | CloseContract

derive instance Eq NamedAction
derive instance Generic NamedAction _
instance Show NamedAction where
  show = genericShow
