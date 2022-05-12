module Component.AddContact (component, _addContact) where

import Prologue

import Capability.Toast (class Toast, addToast)
import Component.AddContact.Types
  ( AddContactFields
  , Component
  , Contact
  , Input
  , Msg(..)
  , _address
  , _nickname
  )
import Component.Button.Types as Button
import Component.Button.View (button)
import Component.Form (renderTextInput)
import Component.Toast.Types (successToast)
import Css as Css
import Data.Address (Address)
import Data.Address as A
import Data.AddressBook (AddressBook)
import Data.AddressBook as AB
import Data.AddressBook as AddressBook
import Data.Bifunctor (lmap)
import Data.Either (either)
import Data.Lens (Setter', set)
import Data.Lens.Record (prop)
import Data.These (These(..))
import Data.WalletNickname (WalletNickname)
import Data.WalletNickname as WN
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect)
import Halogen as H
import Halogen.Css (classNames)
import Halogen.Form.FieldState as FS
import Halogen.Form.Injective (blank, project)
import Halogen.Form.Input (FieldState)
import Halogen.Form.Input as Input
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Events.Extra (onClick_)
import Halogen.Store.Connect (Connected, connect)
import Halogen.Store.Monad (class MonadStore, updateStore)
import Halogen.Store.Select (selectEq)
import Store as Store
import Type.Proxy (Proxy(..))
import Web.Event.Event (Event, preventDefault)

data Action
  = OnInit
  | OnReceive (Connected AddressBook Input)
  | OnUpdate (AddContactFields -> AddContactFields)
  | OnFormSubmit Event
  | OnBack
  | OnSave Contact

type State =
  { addressBook :: AddressBook
  , fields :: AddContactFields
  , result :: Maybe Contact
  }

type ChildSlots =
  ( nickname :: Input.Slot Action WalletNickname Unit
  , address :: Input.Slot Action Address Unit
  )

type ComponentHTML m =
  H.ComponentHTML Action ChildSlots m

type DSL m a =
  H.HalogenM State Action ChildSlots Msg m a

_addContact = Proxy :: Proxy "addContact"

component
  :: forall m
   . MonadAff m
  => MonadStore Store.Action Store.Store m
  => Toast m
  => Component m
component = connect (selectEq _.addressBook) $ H.mkComponent
  { initialState
  , eval: H.mkEval $ H.defaultEval
      { handleAction = handleAction
      , receive = Just <<< OnReceive
      , initialize = Just OnInit
      }
  , render
  }

initialState :: Connected AddressBook Input -> State
initialState { context, input: { initializeNickname } } =
  { addressBook: context
  , fields: (blank :: AddContactFields)
      { nickname = FS.Incomplete initializeNickname }
  , result: Nothing
  }

adaptInput
  :: forall a
   . Setter' AddContactFields (FieldState a)
  -> Input.Msg Action a
  -> Action
adaptInput optic = case _ of
  Input.Updated field -> OnUpdate $ set optic field
  Input.Blurred -> OnUpdate identity
  Input.Focused -> OnUpdate identity
  Input.Emit a -> a

handleAction
  :: forall m
   . MonadEffect m
  => MonadStore Store.Action Store.Store m
  => Toast m
  => Action
  -> DSL m Unit
handleAction = case _ of
  OnInit -> H.tell _nickname unit $ Input.Focus
  OnReceive input -> H.modify_ _ { addressBook = input.context }
  OnUpdate update -> do
    { fields: newFields } <- H.modify \s -> s { fields = update s.fields }
    H.modify_ _ { result = project newFields }
  OnFormSubmit event -> H.liftEffect $ preventDefault event
  OnBack -> H.raise BackClicked
  OnSave contact -> do
    updateStore $ Store.ModifyAddressBook
      (AddressBook.insert contact.nickname contact.address)
    addToast $ successToast "Contact added"
    H.raise $ SaveClicked contact

render
  :: forall m
   . MonadAff m
  => MonadStore Store.Action Store.Store m
  => State
  -> ComponentHTML m
render { addressBook, result, fields } =
  HH.div
    [ classNames
        [ "h-full"
        , "grid"
        , "grid-rows-1fr-auto"
        , "divide-y"
        , "divide-gray"
        ]
    ]
    [ HH.form [ classNames [ "space-y-4", "p-4" ], HE.onSubmit OnFormSubmit ]
        [ nicknameInput addressBook fields.nickname
        , addressInput addressBook fields.address
        ]
    , HH.div
        [ classNames [ "flex", "gap-4", "p-4" ] ]
        [ HH.a
            [ classNames $ Css.button <> [ "flex-1", "text-center" ]
            , onClick_ OnBack
            ]
            [ HH.text "Back" ]
        , button
            Button.Primary
            (OnSave <$> result)
            [ "flex-1" ]
            [ HH.text "Save" ]
        ]
    ]

nicknameInput
  :: forall m
   . MonadAff m
  => AddressBook
  -> FieldState WalletNickname
  -> ComponentHTML m
nicknameInput addressBook fieldState =
  HH.slot _nickname unit Input.component input $ adaptInput (prop _nickname)
  where
  id = "add-contact-nickname"
  label = "Wallet nickname"
  input =
    { fieldState
    , format: WN.toString
    , validate: either This That <<<
        (notInAddressBook <=< lmap Left <<< WN.fromString)
    , render: \{ error, value, result } ->
        renderTextInput
          id
          label
          Nothing
          result
          error
          (Input.setInputProps value [])
          case _ of
            Left WN.Empty -> "Required."
            Left WN.ContainsNonAlphaNumeric ->
              "Can only contain letters and digits."
            Right _ -> "Already exists."
    }
  notInAddressBook nickname
    | AB.containsNickname nickname addressBook = Left $ Right unit
    | otherwise = Right nickname

addressInput
  :: forall m
   . MonadAff m
  => AddressBook
  -> FieldState Address
  -> ComponentHTML m
addressInput addressBook fieldState =
  HH.slot _address unit Input.component input $ adaptInput (prop _address)
  where
  id = "add-contact-address"
  label = "Address"
  input =
    { fieldState
    , format: A.toString
    , validate:
        either This That <<< (notInAddressBook <=< lmap Left <<< A.fromString)
    , render: \{ error, value, result } ->
        renderTextInput
          id
          label
          Nothing
          result
          error
          (Input.setInputProps value [])
          case _ of
            Left A.Empty -> "Required."
            Left A.Invalid -> "Invalid."
            Right nickname -> "Already exists (" <> WN.toString nickname <> ")."
    }
  notInAddressBook address = case AB.lookupNickname address addressBook of
    Nothing -> Right address
    Just nickname -> Left $ Right nickname
