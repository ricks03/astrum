module View.Dialog.StarsBrowser exposing (viewStarsBrowserDialog)

{-| Stars! browser dialog for playing Stars! in an embedded DOSBox emulator.

This embeds the stars-browser (Emularity + DOSBox) in an iframe with WailsFS
backend for native filesystem access to the session's game directory.

-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model exposing (StarsBrowserForm)
import Msg exposing (Msg(..))
import Url


{-| View the Stars! browser dialog.
-}
viewStarsBrowserDialog : StarsBrowserForm -> Html Msg
viewStarsBrowserDialog form =
    div [ class "stars-browser-dialog" ]
        [ viewHeader form
        , viewBody form
        ]


{-| Dialog header with title and close button.
-}
viewHeader : StarsBrowserForm -> Html Msg
viewHeader form =
    div [ class "dialog__header stars-browser-dialog__header" ]
        [ h2 [ class "dialog__title" ]
            [ text ("Stars! - " ++ form.sessionName) ]
        , div [ class "stars-browser-dialog__header-actions" ]
            [ button
                [ class "btn btn--secondary btn--sm"
                , id "stars-browser-fullscreen-btn"
                , attribute "onclick" "document.querySelector('.stars-browser-dialog').requestFullscreen();"
                , title "Fullscreen (F11)"
                ]
                [ text "Fullscreen" ]
            , button
                [ class "btn btn--danger btn--sm"
                , onClick CloseDialog
                , title "Close game (Ctrl+Q)"
                ]
                [ text "Close Game" ]
            ]
        ]


{-| Dialog body with embedded Stars! browser.
-}
viewBody : StarsBrowserForm -> Html Msg
viewBody form =
    let
        -- Build the session key for WailsFS: "serverURL|sessionID"
        sessionKey =
            form.serverUrl ++ "|" ++ form.sessionId

        -- Build iframe src with query parameters
        iframeSrc =
            "stars-browser/stars.html"
                ++ "?session="
                ++ Url.percentEncode sessionKey
                ++ "&width="
                ++ String.fromInt form.width
                ++ "&height="
                ++ String.fromInt form.height
                ++ "&embedded=true"
    in
    div [ class "dialog__body stars-browser-dialog__body" ]
        [ case form.error of
            Just err ->
                div [ class "stars-browser-dialog__error" ]
                    [ p [] [ text err ] ]

            Nothing ->
                text ""
        , iframe
            [ src iframeSrc
            , class "stars-browser-dialog__iframe"
            , id "stars-browser-iframe"
            , attribute "allowfullscreen" "true"
            , attribute "frameborder" "0"
            ]
            []
        ]
