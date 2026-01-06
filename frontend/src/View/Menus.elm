module View.Menus exposing
    ( viewContextMenu
    , viewUserMenu
    )

{-| Context menu and user menu views.
-}

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)
import Msg exposing (Msg(..))
import Update.Admin
import Update.Auth
import Update.Races
import Update.Server
import Update.SessionDetail


{-| Render the context menu for server buttons.
-}
viewContextMenu : Maybe ContextMenu -> Dict.Dict String ServerData -> Html Msg
viewContextMenu maybeMenu serverData =
    case maybeMenu of
        Nothing ->
            text ""

        Just menu ->
            let
                isServerConnected =
                    isConnected menu.serverUrl serverData
            in
            div []
                [ div
                    [ class "context-menu-backdrop"
                    , onClick (ServerMsg Update.Server.HideContextMenu)
                    ]
                    []
                , div
                    [ class "context-menu"
                    , style "left" (String.fromFloat menu.x ++ "px")
                    , style "top" (String.fromFloat menu.y ++ "px")
                    ]
                    ([ if isServerConnected then
                        div
                            [ class "context-menu__item is-disabled"
                            , attribute "title" "Disconnect before editing"
                            ]
                            [ text "Edit Server" ]

                       else
                        div
                            [ class "context-menu__item"
                            , onClick (ServerMsg (Update.Server.OpenEditServerDialog menu.serverUrl))
                            ]
                            [ text "Edit Server" ]
                     ]
                        ++ (if isServerConnected then
                                [ div [ class "context-menu__separator" ] []
                                , div
                                    [ class "context-menu__item"
                                    , onClick (AuthMsg (Update.Auth.Disconnect menu.serverUrl))
                                    ]
                                    [ text "Disconnect" ]
                                ]

                            else
                                []
                           )
                        ++ (if isServerConnected then
                                []

                            else
                                [ div [ class "context-menu__separator" ] []
                                , div
                                    [ class "context-menu__item is-danger"
                                    , onClick (ServerMsg (Update.Server.OpenRemoveServerDialog menu.serverUrl ""))
                                    ]
                                    [ text "Remove Server" ]
                                ]
                           )
                    )
                ]


{-| Render the user menu dropdown.
-}
viewUserMenu : Model -> Html Msg
viewUserMenu model =
    if not model.showUserMenu then
        text ""

    else
        case model.selectedServerUrl of
            Nothing ->
                text ""

            Just serverUrl ->
                let
                    serverData =
                        getCurrentServerData model

                    maybeSerialKey =
                        case serverData.connectionState of
                            Connected info ->
                                if String.isEmpty info.serialKey then
                                    Nothing

                                else
                                    Just info.serialKey

                            _ ->
                                Nothing
                in
                div []
                    [ div
                        [ class "user-menu-backdrop"
                        , onClick (AdminMsg Update.Admin.HideUserMenu)
                        ]
                        []
                    , div [ class "user-menu" ]
                        ([ case maybeSerialKey of
                            Just serialKey ->
                                div [ class "user-menu__serial" ]
                                    [ span [ class "user-menu__serial-label" ] [ text "Serial Key:" ]
                                    , div [ class "user-menu__value-row" ]
                                        [ span [ class "user-menu__serial-value" ] [ text serialKey ]
                                        , button
                                            [ class "user-menu__copy-btn"
                                            , onClick (AdminMsg (Update.Admin.CopyToClipboard serialKey))
                                            , attribute "title" "Copy to clipboard"
                                            ]
                                            [ text "\u{1F4CB}" ]
                                        ]
                                    ]

                            Nothing ->
                                text ""
                         , div [ class "user-menu__separator" ] []
                         , div
                            [ class "user-menu__item"
                            , onClick (RacesMsg Update.Races.OpenRacesDialog)
                            ]
                            [ text "My Races" ]
                         , div
                            [ class "user-menu__item"
                            , onClick (SessionDetailMsg Update.SessionDetail.OpenInvitationsDialog)
                            ]
                            [ text "Invitations" ]
                         , div [ class "user-menu__separator" ] []
                         , div
                            [ class "user-menu__item"
                            , onClick (AdminMsg (Update.Admin.CopyApiKey serverUrl))
                            ]
                            [ text "Copy API Key" ]
                         , div
                            [ class "user-menu__item"
                            , onClick (AdminMsg Update.Admin.OpenChangeApikeyDialog)
                            ]
                            [ text "Change API Key" ]
                         , div [ class "user-menu__separator" ] []
                         , div
                            [ class "user-menu__item"
                            , onClick (AuthMsg (Update.Auth.Disconnect serverUrl))
                            ]
                            [ text "Disconnect" ]
                         ]
                        )
                    ]
