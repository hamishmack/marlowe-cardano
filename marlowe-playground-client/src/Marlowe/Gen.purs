module Marlowe.Gen where

import Prologue

import Control.Lazy (class Lazy, defer)
import Control.Monad.Gen
  ( class MonadGen
  , chooseFloat
  , chooseInt
  , resize
  , suchThat
  , unfoldable
  )
import Control.Monad.Gen as Gen
import Control.Monad.Reader (class MonadReader, ask, local)
import Control.Monad.Rec.Class (class MonadRec)
import Data.BigInt.Argonaut (BigInt)
import Data.BigInt.Argonaut as BigInt
import Data.Char (fromCharCode)
import Data.Char.Gen (genAlpha, genDigitChar)
import Data.DateTime.Instant (Instant, instant, unInstant)
import Data.Foldable (class Foldable)
import Data.Int (rem)
import Data.Maybe (fromJust, fromMaybe)
import Data.Newtype (unwrap)
import Data.NonEmpty (NonEmpty, (:|))
import Data.Semigroup.Foldable (foldl1)
import Data.String.CodeUnits (fromCharArray)
import Data.Time.Duration (Milliseconds(..))
import Marlowe.Extended as EM
import Marlowe.Holes
  ( Action(..)
  , Bound(..)
  , Case(..)
  , ChoiceId(..)
  , Contract(..)
  , Location(..)
  , MarloweType(..)
  , Observation(..)
  , Party(..)
  , Payee(..)
  , Term(..)
  , TermWrapper(..)
  , Token(..)
  , Value(..)
  , ValueId(..)
  , mkArgName
  )
import Marlowe.Holes as H
import Marlowe.Semantics
  ( CurrencySymbol
  , Input(..)
  , PubKey
  , Rational(..)
  , TimeInterval(..)
  , TokenName
  , TransactionInput(..)
  , TransactionWarning(..)
  )
import Marlowe.Semantics as S
import Partial.Unsafe (unsafePartial)
import Plutus.V1.Ledger.Time (POSIXTime(..))

newtype GenerationOptions = GenerationOptions
  { withHoles :: Boolean, withExtendedConstructs :: Boolean }

oneOf
  :: forall m a f
   . Foldable f
  => MonadGen m
  => NonEmpty f (m a)
  -> m a
oneOf = foldl1 Gen.choose

genBigInt :: forall m. MonadGen m => MonadRec m => m BigInt
genBigInt = BigInt.fromInt <$> chooseInt bottom top

genRational :: forall m. MonadGen m => MonadRec m => m Rational
genRational = do
  n <- genBigInt
  d <- genBigInt
  pure
    -- we need to do this because in tests where we wrap a Rational in a Term or TermWrapper

    -- when we have two negative values then the column position of the term will different

    -- to if we have two positive values, even though the rationals themselves are equal

    $
      if d > zero then
        Rational n d
      else
        Rational (-n) (-d)

genInstant :: forall m. MonadGen m => MonadRec m => m Instant
genInstant = do
  n <- chooseFloat (unwrap (unInstant bottom)) (unwrap (unInstant top))
  pure $ unsafePartial $ fromJust $ instant $ Milliseconds n

genPOSIXTime :: forall m. MonadGen m => MonadRec m => m POSIXTime
genPOSIXTime = POSIXTime <$> genInstant

genTimeout
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m H.Timeout
genTimeout = do
  GenerationOptions { withExtendedConstructs } <- ask
  if withExtendedConstructs then
    oneOf $ slot :| [ timeParam ]
  else
    slot
  where
  slot = H.TimeValue <$> genPOSIXTime

  timeParam = H.TimeParam <$> genTokenName

genValueId
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m ValueId
genValueId = ValueId <$> genString

genHexit :: forall m. MonadGen m => m Char
genHexit = oneOf $ lowerAlphaHexDigit :| upperAlphaHexDigit :| [ genDigitChar ]
  where
  lowerAlphaHexDigit = fromMaybe 'a' <$> (fromCharCode <$> chooseInt 97 102)

  upperAlphaHexDigit = fromMaybe 'A' <$> (fromCharCode <$> chooseInt 65 70)

genBase16 :: forall m. MonadGen m => MonadRec m => m String
genBase16 = fromCharArray <$> resize (\s -> s - (s `rem` 2))
  (unfoldable genHexit)

genAlphaNum :: forall m. MonadGen m => MonadRec m => m Char
genAlphaNum = oneOf $ genAlpha :| [ genDigitChar ]

genString :: forall m. MonadGen m => MonadRec m => m String
genString = fromCharArray <$> resize (_ - 1) (unfoldable genAlphaNum)

genPubKey :: forall m. MonadGen m => MonadRec m => m PubKey
genPubKey = genBase16

genTokenName :: forall m. MonadGen m => MonadRec m => m TokenName
genTokenName = genString

genParty
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m Party
genParty = oneOf $ pk :| [ role ]
  where
  pk = PK <$> genPubKey

  role = Role <$> genTokenName

genCurrencySymbol :: forall m. MonadGen m => MonadRec m => m CurrencySymbol
genCurrencySymbol = genBase16

genTimeInterval
  :: forall m. MonadGen m => MonadRec m => m POSIXTime -> m TimeInterval
genTimeInterval gen = do
  from <- gen
  to <- suchThat gen (\v -> v > from)
  pure $ TimeInterval from to

genBound :: forall m. MonadGen m => MonadRec m => m Bound
genBound = do
  from <- genBigInt
  to <- suchThat genBigInt (\v -> v > from)
  pure $ Bound from to

genPosition :: forall m. MonadGen m => MonadRec m => m Int
genPosition = chooseInt 0 1000

genRange :: forall m. MonadGen m => MonadRec m => m Location
genRange = do
  startLineNumber <- genPosition
  startColumn <- genPosition
  endLineNumber <- genPosition
  endColumn <- genPosition
  pure $ Range { startLineNumber, startColumn, endLineNumber, endColumn }

genHole :: forall m a. MonadGen m => MonadRec m => String -> m (Term a)
genHole name = do
  -- name <- suchThat genString (\s -> s /= "")
  range <- genRange
  pure $ Hole name range

genTerm
  :: forall m a
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => String
  -> m a
  -> m (Term a)
genTerm name g = do
  GenerationOptions { withHoles } <- ask
  oneOf $ (Term <$> g <*> pure NoLocation) :|
    (if withHoles then [ genHole name ] else [])

genTermWrapper
  :: forall m a
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m a
  -> m (TermWrapper a)
genTermWrapper g = do
  TermWrapper <$> g <*> pure NoLocation

genToken
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m Token
genToken = oneOf $ (pure $ Token "" "") :|
  [ Token <$> genCurrencySymbol <*> genTokenName ]

genChoiceId
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m ChoiceId
genChoiceId = do
  choiceName <- genString
  choiceOwner <- genTerm (mkArgName PartyType) genParty
  pure $ ChoiceId choiceName choiceOwner

genPayee
  :: forall m
   . MonadGen m
  => MonadRec m
  => MonadReader GenerationOptions m
  => m Payee
genPayee = oneOf $ (Account <$> genTerm (mkArgName PartyType) genParty) :|
  [ Party <$> genTerm (mkArgName PartyType) genParty ]

genAction
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Observation)
  => Lazy (m Value)
  => MonadReader GenerationOptions m
  => Int
  -> m Action
genAction size =
  oneOf
    $
      ( Deposit <$> genTerm "into" genParty <*> genTerm "from_party" genParty
          <*> genTerm (mkArgName TokenType) genToken
          <*> genTerm (mkArgName ValueType) (genValue' size)
      )
        :|
          [ Choice <$> genChoiceId <*> resize (_ - 1)
              (unfoldable (genTerm (mkArgName BoundType) genBound))
          , Notify <$> genTerm (mkArgName ObservationType)
              (genObservation' size)
          ]

genCase
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Value)
  => Lazy (m Observation)
  => Lazy (m Contract)
  => MonadReader GenerationOptions m
  => Int
  -> m Case
genCase size = do
  let
    newSize = size - 1
  action <- genTerm (mkArgName ActionType) $ genAction newSize
  contract <- genTerm (mkArgName ContractType) $ genContract' newSize
  pure (Case action contract)

genCases
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Value)
  => Lazy (m Observation)
  => Lazy (m Contract)
  => MonadReader GenerationOptions m
  => Int
  -> m (Array (Term Case))
genCases size = resize (_ - 1)
  (unfoldable (local withoutHoles (genTerm "case" (genCase size))))
  where
  withoutHoles (GenerationOptions { withExtendedConstructs }) =
    GenerationOptions { withHoles: false, withExtendedConstructs }

genValue
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Value)
  => Lazy (m Observation)
  => MonadReader GenerationOptions m
  => m Value
genValue = genValue' 5

genValue'
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Value)
  => Lazy (m Observation)
  => MonadReader GenerationOptions m
  => Int
  -> m Value
genValue' size
  | size > 1 =
      defer \_ -> do
        let
          newSize = (size - 1)

          genNewValue = genTerm (mkArgName ValueType) $ genValue' newSize

          genNewValueIndexed i = genTerm ((mkArgName ValueType) <> show i) $
            genValue' newSize
        GenerationOptions { withExtendedConstructs } <- ask
        let
          extendedConstructcs =
            if withExtendedConstructs then [ ConstantParam <$> genTokenName ]
            else []
        oneOf $ pure TimeIntervalStart
          :|
            ( [ pure TimeIntervalEnd
              , AvailableMoney <$> genTerm (mkArgName PartyType) genParty <*>
                  genTerm (mkArgName TokenType) genToken
              , Constant <$> genBigInt
              , NegValue <$> genNewValue
              , AddValue <$> genNewValueIndexed 1 <*> genNewValueIndexed 2
              , SubValue <$> genNewValueIndexed 1 <*> genNewValueIndexed 2
              , MulValue <$> genNewValueIndexed 1 <*> genNewValueIndexed 2
              , DivValue <$> genNewValueIndexed 1 <*> genNewValueIndexed 2
              , ChoiceValue <$> genChoiceId
              , UseValue <$> genTermWrapper genValueId
              , Cond <$> genTerm "condition" (genObservation' newSize)
                  <*> genTerm "then" (genValue' newSize)
                  <*> genTerm "else" (genValue' newSize)
              ]
                <> extendedConstructcs
            )
  | otherwise =
      oneOf $ pure TimeIntervalStart
        :|
          [ pure TimeIntervalEnd
          , AvailableMoney <$> genTerm (mkArgName PartyType) genParty <*>
              genTerm (mkArgName TokenType) genToken
          , Constant <$> genBigInt
          , UseValue <$> genTermWrapper genValueId
          ]

genObservation
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Observation)
  => Lazy (m Value)
  => MonadReader GenerationOptions m
  => m Observation
genObservation = genObservation' 5

genObservation'
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Observation)
  => Lazy (m Value)
  => MonadReader GenerationOptions m
  => Int
  -> m Observation
genObservation' size
  | size > 1 =
      defer \_ ->
        let
          newSize = (size - 1)

          genNewValue i = genTerm ((mkArgName ValueType) <> show i) $ genValue'
            newSize

          genNewObservationIndexed i =
            genTerm ((mkArgName ObservationType) <> show i) $ genObservation'
              newSize

          genNewObservation = genTerm (mkArgName ObservationType) $
            genObservation' newSize
        in
          oneOf
            $
              ( AndObs <$> genNewObservationIndexed 1 <*>
                  genNewObservationIndexed 2
              )
                :|
                  [ OrObs <$> genNewObservationIndexed 1 <*>
                      genNewObservationIndexed 2
                  , NotObs <$> genNewObservation
                  , ChoseSomething <$> genChoiceId
                  , ValueGE <$> genNewValue 1 <*> genNewValue 2
                  , ValueGT <$> genNewValue 1 <*> genNewValue 2
                  , ValueLT <$> genNewValue 1 <*> genNewValue 2
                  , ValueLE <$> genNewValue 1 <*> genNewValue 2
                  , ValueEQ <$> genNewValue 1 <*> genNewValue 2
                  ]
  | otherwise = genLeaf
      where
      genLeaf
        :: m Observation
      genLeaf = ChoseSomething <$> genChoiceId

genContract
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Contract)
  => Lazy (m Observation)
  => Lazy (m Value)
  => MonadReader GenerationOptions m
  => m Contract
genContract = genContract' 3

genContract'
  :: forall m
   . MonadGen m
  => MonadRec m
  => Lazy (m Contract)
  => Lazy (m Observation)
  => Lazy (m Value)
  => MonadReader GenerationOptions m
  => Int
  -> m Contract
genContract' size
  | size > 1 =
      defer \_ ->
        let
          newSize = (size - 1)

          genNewValue = genTerm (mkArgName ValueType) $ genValue' newSize

          genNewObservation = genTerm (mkArgName ObservationType) $
            genObservation' newSize

          genNewContractIndexed i = genTerm ((mkArgName ContractType) <> show i)
            $ genContract' newSize

          genNewContract = genTerm (mkArgName ContractType) $ genContract'
            newSize

          genNewTimeout = Term <$> genTimeout <*> pure NoLocation
        in
          oneOf $ pure Close
            :|
              [ Pay <$> genTerm (mkArgName PartyType) genParty
                  <*> genTerm (mkArgName PayeeType) genPayee
                  <*> genTerm (mkArgName TokenType) genToken
                  <*> genNewValue
                  <*> genNewContract
              , If <$> genNewObservation <*> genNewContractIndexed 1 <*>
                  genNewContractIndexed 2
              , When <$> genCases newSize <*> genNewTimeout <*> genNewContract
              , Let <$> genTermWrapper genValueId <*> genNewValue <*>
                  genNewContract
              , Assert <$> genNewObservation <*> genNewContract
              ]
  | otherwise = genLeaf
      where
      genLeaf
        :: m Contract
      genLeaf = pure Close

----------------------------------------------------------------- Semantics Generators ---------------------------------
genTokenNameValue :: forall m. MonadGen m => MonadRec m => m S.TokenName
genTokenNameValue = genString

genCurrencySymbolValue
  :: forall m. MonadGen m => MonadRec m => m S.CurrencySymbol
genCurrencySymbolValue = genBase16

genTokenValue :: forall m. MonadGen m => MonadRec m => m S.Token
genTokenValue = do
  currencySymbol <- genCurrencySymbolValue
  tokenName <- genTokenName
  pure $ S.Token currencySymbol tokenName

genPartyValue :: forall m. MonadGen m => MonadRec m => m S.Party
genPartyValue = oneOf $ pk :| [ role ]
  where
  pk = S.PK <$> genPubKey

  role = S.Role <$> genTokenNameValue

genPayeeValueCore :: forall m. MonadGen m => MonadRec m => m S.Payee
genPayeeValueCore = oneOf $ (S.Account <$> genPartyValue) :|
  [ S.Party <$> genPartyValue ]

genPayeeValueExtended :: forall m. MonadGen m => MonadRec m => m EM.Payee
genPayeeValueExtended = oneOf $ (EM.Account <$> genPartyValue) :|
  [ EM.Party <$> genPartyValue ]

genValueIdValue :: forall m. MonadGen m => MonadRec m => m S.ValueId
genValueIdValue = S.ValueId <$> genString

genChoiceIdValue :: forall m. MonadGen m => MonadRec m => m S.ChoiceId
genChoiceIdValue = do
  choiceName <- genString
  choiceOwner <- genPartyValue
  pure $ S.ChoiceId choiceName choiceOwner

genInput
  :: forall m
   . MonadGen m
  => MonadRec m
  => m S.Input
genInput =
  oneOf
    $
      ( IDeposit <$> genPartyValue <*> genPartyValue <*> genTokenValue <*>
          genBigInt
      )
        :|
          [ IChoice <$> genChoiceIdValue <*> genBigInt
          , pure INotify
          ]

genTransactionInput
  :: forall m
   . MonadGen m
  => MonadRec m
  => m S.TransactionInput
genTransactionInput = do
  interval <- genTimeInterval genPOSIXTime
  inputs <- unfoldable genInput
  pure $ TransactionInput { interval, inputs }

genTransactionWarning
  :: forall m
   . MonadGen m
  => MonadRec m
  => m TransactionWarning
genTransactionWarning =
  oneOf
    $
      ( TransactionNonPositiveDeposit <$> genPartyValue <*> genPartyValue
          <*> genTokenValue
          <*> genBigInt
      )
        :|
          [ TransactionNonPositivePay <$> genPartyValue <*> genPayeeValueCore
              <*> genTokenValue
              <*> genBigInt
          , TransactionPartialPay <$> genPartyValue <*> genPayeeValueCore
              <*> genTokenValue
              <*> genBigInt
              <*> genBigInt
          , TransactionShadowing <$> genValueIdValue <*> genBigInt <*> genBigInt
          ]
