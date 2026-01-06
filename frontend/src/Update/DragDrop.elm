module Update.DragDrop exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for drag and drop reordering.

Handles player reordering within sessions and server reordering in the sidebar.

-}

import Api.Encode as Encode
import Json.Encode as E
import Model exposing (..)
import Ports
import Update.Helpers exposing (moveItem)


{-| DragDrop-specific messages.
-}
type Msg
    = MouseDownOnPlayer String String Float Float -- playerId, playerName, mouseX, mouseY
    | MouseMoveWhileDragging Float Float -- mouseX, mouseY
    | MouseEnterPlayer String -- target playerId
    | MouseLeavePlayer
    | MouseUpEndDrag
    | PlayersReordered String (Result String ()) -- serverUrl, result
    | ServerDragStart String Float -- serverUrl, mouseY
    | ServerDragMove Float -- mouseY
    | ServerDragEnter String -- target serverUrl
    | ServerDragLeave
    | ServerDragEnd
    | ServersReordered (Result String ())


{-| Handle all DragDrop messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseDownOnPlayer playerId playerName mouseX mouseY ->
            case model.sessionDetail of
                Just detail ->
                    ( { model
                        | sessionDetail =
                            Just
                                { detail
                                    | dragState =
                                        Just
                                            { draggedPlayerId = playerId
                                            , draggedPlayerName = playerName
                                            , dragOverPlayerId = Nothing
                                            , mouseX = mouseX
                                            , mouseY = mouseY
                                            }
                                }
                      }
                    , Ports.clearSelection ()
                    )

                Nothing ->
                    ( model, Cmd.none )

        MouseMoveWhileDragging mouseX mouseY ->
            case model.sessionDetail of
                Just detail ->
                    case detail.dragState of
                        Just dragState ->
                            ( { model
                                | sessionDetail =
                                    Just
                                        { detail
                                            | dragState =
                                                Just { dragState | mouseX = mouseX, mouseY = mouseY }
                                        }
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MouseEnterPlayer playerId ->
            case model.sessionDetail of
                Just detail ->
                    case detail.dragState of
                        Just dragState ->
                            if dragState.draggedPlayerId /= playerId then
                                ( { model
                                    | sessionDetail =
                                        Just
                                            { detail
                                                | dragState =
                                                    Just { dragState | dragOverPlayerId = Just playerId }
                                            }
                                  }
                                , Cmd.none
                                )

                            else
                                ( model, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MouseLeavePlayer ->
            case model.sessionDetail of
                Just detail ->
                    case detail.dragState of
                        Just dragState ->
                            ( { model
                                | sessionDetail =
                                    Just
                                        { detail
                                            | dragState =
                                                Just { dragState | dragOverPlayerId = Nothing }
                                        }
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MouseUpEndDrag ->
            case ( model.selectedServerUrl, model.sessionDetail ) of
                ( Just serverUrl, Just detail ) ->
                    case detail.dragState of
                        Just dragState ->
                            case dragState.dragOverPlayerId of
                                Just targetPlayerId ->
                                    let
                                        currentData =
                                            getServerData serverUrl model.serverData

                                        maybeSession =
                                            getSessionById detail.sessionId currentData.sessions
                                    in
                                    case maybeSession of
                                        Just session ->
                                            let
                                                draggedIndex =
                                                    session.players
                                                        |> List.indexedMap Tuple.pair
                                                        |> List.filter (\( _, p ) -> p.userProfileId == dragState.draggedPlayerId)
                                                        |> List.head
                                                        |> Maybe.map Tuple.first

                                                targetIndex =
                                                    session.players
                                                        |> List.indexedMap Tuple.pair
                                                        |> List.filter (\( _, p ) -> p.userProfileId == targetPlayerId)
                                                        |> List.head
                                                        |> Maybe.map Tuple.first
                                            in
                                            case ( draggedIndex, targetIndex ) of
                                                ( Just fromIdx, Just toIdx ) ->
                                                    if fromIdx /= toIdx then
                                                        let
                                                            reorderedPlayers =
                                                                moveItem fromIdx toIdx session.players

                                                            playerOrders =
                                                                reorderedPlayers
                                                                    |> List.indexedMap
                                                                        (\idx p ->
                                                                            E.object
                                                                                [ ( "userProfileId", E.string p.userProfileId )
                                                                                , ( "playerOrder", E.int idx )
                                                                                ]
                                                                        )
                                                        in
                                                        ( { model
                                                            | sessionDetail =
                                                                Just { detail | dragState = Nothing }
                                                          }
                                                        , Ports.reorderPlayers
                                                            (E.object
                                                                [ ( "serverUrl", E.string serverUrl )
                                                                , ( "sessionId", E.string detail.sessionId )
                                                                , ( "playerOrders", E.list identity playerOrders )
                                                                ]
                                                            )
                                                        )

                                                    else
                                                        ( { model | sessionDetail = Just { detail | dragState = Nothing } }
                                                        , Cmd.none
                                                        )

                                                _ ->
                                                    ( { model | sessionDetail = Just { detail | dragState = Nothing } }
                                                    , Cmd.none
                                                    )

                                        Nothing ->
                                            ( { model | sessionDetail = Just { detail | dragState = Nothing } }
                                            , Cmd.none
                                            )

                                Nothing ->
                                    ( { model | sessionDetail = Just { detail | dragState = Nothing } }
                                    , Cmd.none
                                    )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PlayersReordered serverUrl result ->
            case result of
                Ok _ ->
                    -- Refresh the session to get updated player order
                    case model.sessionDetail of
                        Just detail ->
                            ( model
                            , Ports.getSession (Encode.getSession serverUrl detail.sessionId)
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Err err ->
                    ( { model | error = Just err }
                    , Cmd.none
                    )

        ServerDragStart serverUrl mouseY ->
            ( { model
                | serverDragState =
                    Just
                        { draggedServerUrl = serverUrl
                        , dragOverServerUrl = Nothing
                        , mouseY = mouseY
                        }
              }
            , Ports.clearSelection ()
            )

        ServerDragMove mouseY ->
            case model.serverDragState of
                Just dragState ->
                    ( { model
                        | serverDragState =
                            Just { dragState | mouseY = mouseY }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        ServerDragEnter serverUrl ->
            case model.serverDragState of
                Just dragState ->
                    if dragState.draggedServerUrl /= serverUrl then
                        ( { model
                            | serverDragState =
                                Just { dragState | dragOverServerUrl = Just serverUrl }
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ServerDragLeave ->
            case model.serverDragState of
                Just dragState ->
                    ( { model
                        | serverDragState =
                            Just { dragState | dragOverServerUrl = Nothing }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        ServerDragEnd ->
            case model.serverDragState of
                Just dragState ->
                    case dragState.dragOverServerUrl of
                        Just targetUrl ->
                            let
                                draggedIndex =
                                    model.servers
                                        |> List.indexedMap Tuple.pair
                                        |> List.filter (\( _, s ) -> s.url == dragState.draggedServerUrl)
                                        |> List.head
                                        |> Maybe.map Tuple.first

                                targetIndex =
                                    model.servers
                                        |> List.indexedMap Tuple.pair
                                        |> List.filter (\( _, s ) -> s.url == targetUrl)
                                        |> List.head
                                        |> Maybe.map Tuple.first
                            in
                            case ( draggedIndex, targetIndex ) of
                                ( Just fromIdx, Just toIdx ) ->
                                    if fromIdx /= toIdx then
                                        let
                                            reorderedServers =
                                                moveItem fromIdx toIdx model.servers

                                            serverOrders =
                                                reorderedServers
                                                    |> List.indexedMap
                                                        (\idx s ->
                                                            E.object
                                                                [ ( "url", E.string s.url )
                                                                , ( "order", E.int idx )
                                                                ]
                                                        )
                                        in
                                        ( { model
                                            | serverDragState = Nothing
                                            , servers = reorderedServers
                                          }
                                        , Ports.reorderServers
                                            (E.object
                                                [ ( "serverOrders", E.list identity serverOrders )
                                                ]
                                            )
                                        )

                                    else
                                        ( { model | serverDragState = Nothing }, Cmd.none )

                                _ ->
                                    ( { model | serverDragState = Nothing }, Cmd.none )

                        Nothing ->
                            ( { model | serverDragState = Nothing }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ServersReordered result ->
            case result of
                Ok _ ->
                    -- Order already updated optimistically in ServerDragEnd
                    ( model, Cmd.none )

                Err err ->
                    -- On error, refresh servers to get correct order
                    ( { model | error = Just err }
                    , Ports.getServers ()
                    )
