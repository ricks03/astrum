module View.Dialog.ApiKey exposing (viewChangeApikeyDialog)

{-| Dialog for changing the user's own API key.
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (ChangeApikeyState(..))
import Msg exposing (Msg(..))
import Update.Admin


{-| Dialog for changing your own API key.
-}
viewChangeApikeyDialog : ChangeApikeyState -> Html Msg
viewChangeApikeyDialog state =
    div [ class "dialog change-apikey-dialog" ]
        [ div [ class "dialog__header" ]
            [ h2 [ class "dialog__title" ] [ text "Change API Key" ]
            , button
                [ class "dialog__close"
                , onClick (AdminMsg Update.Admin.CancelChangeApikey)
                ]
                [ text "\u{00D7}" ]
            ]
        , div [ class "dialog__body" ]
            [ case state of
                ConfirmingChange ->
                    viewConfirmChangeApikey

                ChangingApikey ->
                    viewChangingApikey

                ChangeComplete newApikey ->
                    viewChangeApikeyComplete newApikey
            ]
        ]


{-| Confirmation view for changing own API key.
-}
viewConfirmChangeApikey : Html Msg
viewConfirmChangeApikey =
    div [ class "confirm-dialog" ]
        [ div [ class "confirm-dialog__icon is-warning" ] [ text "!" ]
        , h3 [ class "confirm-dialog__title" ] [ text "Change Your API Key?" ]
        , p [ class "confirm-dialog__message" ]
            [ text "This will generate a new API key and invalidate your current one."
            , br [] []
            , text "You will need to update any other applications using your API key."
            ]
        , div [ class "confirm-dialog__actions" ]
            [ button
                [ class "btn btn--secondary"
                , onClick (AdminMsg Update.Admin.CancelChangeApikey)
                ]
                [ text "Cancel" ]
            , button
                [ class "btn btn--warning"
                , onClick (AdminMsg Update.Admin.SubmitChangeApikey)
                ]
                [ text "Change API Key" ]
            ]
        ]


{-| Loading view while changing API key.
-}
viewChangingApikey : Html Msg
viewChangingApikey =
    div [ class "change-apikey-dialog__loading" ]
        [ div [ class "spinner" ] []
        , text "Changing your API key..."
        ]


{-| View showing the new API key after change.
-}
viewChangeApikeyComplete : String -> Html Msg
viewChangeApikeyComplete newApikey =
    div [ class "change-apikey-dialog__result" ]
        [ div [ class "change-apikey-dialog__result-icon" ] [ text "\u{2713}" ]
        , h3 [ class "change-apikey-dialog__result-title" ]
            [ text "API Key Changed Successfully" ]
        , div [ class "change-apikey-dialog__result-warning" ]
            [ text "Please save this key. The server will not show it again:" ]
        , div [ class "change-apikey-dialog__result-key" ]
            [ text newApikey ]
        , p [ class "change-apikey-dialog__result-note" ]
            [ text "Your stored credentials have been updated automatically." ]
        , button
            [ class "btn btn--primary"
            , onClick (AdminMsg Update.Admin.CancelChangeApikey)
            ]
            [ text "Done" ]
        ]
