module View.Dialog.Auth exposing
    ( viewConnectDialog
    , viewRegisterDialog
    )

{-| Authentication dialogs: connect (login) and register.
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (ConnectForm, RegisterForm)
import Msg exposing (Msg(..))
import Update.Auth
import Update.Server
import View.Helpers exposing (viewFormError)


{-| Dialog for connecting (logging in) to a server.
-}
viewConnectDialog : String -> ConnectForm -> Html Msg
viewConnectDialog serverUrl form =
    div []
        [ div [ class "dialog__header" ]
            [ h2 [ class "dialog__title" ] [ text "Connect to Server" ]
            , button
                [ class "dialog__close"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text "x" ]
            ]
        , div [ class "dialog__body" ]
            [ div [ class "connect-dialog__tabs" ]
                [ button
                    [ class "connect-dialog__tab is-active" ]
                    [ text "Login" ]
                , button
                    [ class "connect-dialog__tab"
                    , onClick (AuthMsg Update.Auth.SwitchToRegister)
                    ]
                    [ text "Register" ]
                ]
            , viewFormError form.error
            , div [ class "form-group" ]
                [ label [ class "form-label" ] [ text "Username" ]
                , input
                    [ class "form-input"
                    , type_ "text"
                    , placeholder "Your nickname"
                    , value form.username
                    , onInput (AuthMsg << Update.Auth.UpdateConnectUsername)
                    ]
                    []
                ]
            , div [ class "form-group" ]
                [ label [ class "form-label" ] [ text "API Key" ]
                , input
                    [ class "form-input"
                    , type_ "password"
                    , placeholder "Your API key"
                    , value form.password
                    , onInput (AuthMsg << Update.Auth.UpdateConnectPassword)
                    ]
                    []
                ]
            ]
        , div [ class "dialog__footer dialog__footer--right" ]
            [ button
                [ class "btn btn-secondary"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text "Cancel" ]
            , button
                [ class "btn btn-primary"
                , classList [ ( "btn-loading", form.submitting ) ]
                , onClick (AuthMsg (Update.Auth.SubmitConnect serverUrl))
                , disabled form.submitting
                ]
                [ text "Connect" ]
            ]
        ]


{-| Dialog for registering a new account.
-}
viewRegisterDialog : String -> RegisterForm -> Html Msg
viewRegisterDialog serverUrl form =
    div []
        [ div [ class "dialog__header" ]
            [ h2 [ class "dialog__title" ] [ text "Register Account" ]
            , button
                [ class "dialog__close"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text "x" ]
            ]
        , div [ class "dialog__body" ]
            (if form.success then
                [ div [ class "register-success" ]
                    [ div [ class "register-success__icon" ] [ text "\u{2713}" ]
                    , h3 [ class "register-success__title" ]
                        [ text
                            (if form.pending then
                                "Registration Pending Approval"

                             else
                                "Registration Complete"
                            )
                        ]
                    , p [ class "register-success__message" ]
                        (if form.pending then
                            [ text "You are now connected to the server."
                            , br [] []
                            , text "While waiting for approval, you can create and manage your races."
                            , br [] []
                            , text "Once approved, you'll be able to join and create sessions."
                            ]

                         else
                            [ text "You are now connected to the server with full access." ]
                        )
                    ]
                ]

             else
                [ div [ class "connect-dialog__tabs" ]
                    [ button
                        [ class "connect-dialog__tab"
                        , onClick (AuthMsg Update.Auth.SwitchToConnect)
                        ]
                        [ text "Login" ]
                    , button
                        [ class "connect-dialog__tab is-active" ]
                        [ text "Register" ]
                    ]
                , viewFormError form.error
                , div [ class "form-group" ]
                    [ label [ class "form-label" ] [ text "Nickname" ]
                    , input
                        [ class "form-input"
                        , type_ "text"
                        , placeholder "Choose a nickname"
                        , value form.nickname
                        , onInput (AuthMsg << Update.Auth.UpdateRegisterNickname)
                        ]
                        []
                    ]
                , div [ class "form-group" ]
                    [ label [ class "form-label" ] [ text "Email" ]
                    , input
                        [ class "form-input"
                        , type_ "email"
                        , placeholder "your@email.com"
                        , value form.email
                        , onInput (AuthMsg << Update.Auth.UpdateRegisterEmail)
                        ]
                        []
                    ]
                , div [ class "form-group" ]
                    [ label [ class "form-label" ] [ text "Message (optional)" ]
                    , textarea
                        [ class "form-input"
                        , placeholder "Why do you want to join?"
                        , value form.message
                        , onInput (AuthMsg << Update.Auth.UpdateRegisterMessage)
                        ]
                        []
                    ]
                ]
            )
        , div [ class "dialog__footer dialog__footer--right" ]
            [ button
                [ class "btn btn-secondary"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text
                    (if form.success then
                        "Close"

                     else
                        "Cancel"
                    )
                ]
            , if form.success then
                text ""

              else
                button
                    [ class "btn btn-primary"
                    , classList [ ( "btn-loading", form.submitting ) ]
                    , onClick (AuthMsg (Update.Auth.SubmitRegister serverUrl))
                    , disabled form.submitting
                    ]
                    [ text "Register" ]
            ]
        ]
