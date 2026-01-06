module Update.Server exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for server management messages.

Handles server CRUD, selection, and context menus.

-}

import Api.Encode as Encode
import Api.Server exposing (Server)
import Api.Session
import Model exposing (..)
import Ports
import Update.Helpers exposing (updateDialogError, updateServerForm)


{-| Server-specific messages.
-}
type Msg
    = GotServers (Result String (List Server))
    | SelectServer String
    | ServerAdded (Result String Server)
    | ServerUpdated (Result String ())
    | ServerRemoved (Result String ())
    | GotHasDefaultServer (Result String Bool)
    | AddDefaultServer
    | DefaultServerAdded (Result String Server)
    | OpenAddServerDialog
    | OpenEditServerDialog String -- serverUrl
    | OpenRemoveServerDialog String String -- serverUrl, serverName
    | CloseDialog
    | UpdateServerFormName String
    | UpdateServerFormUrl String
    | SubmitAddServer
    | SubmitEditServer String -- old serverUrl
    | ConfirmRemoveServer String -- serverUrl
    | ShowContextMenu String Float Float -- serverUrl, x, y
    | HideContextMenu


{-| Handle all Server messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotServers result ->
            case result of
                Ok servers ->
                    ( { model
                        | servers = servers
                        , loading = False
                        , error = Nothing
                      }
                    , Ports.getAppSettings ()
                    )

                Err err ->
                    ( { model
                        | loading = False
                        , error = Just err
                      }
                    , Cmd.none
                    )

        SelectServer serverUrl ->
            let
                -- Save current session detail to previous server's lastViewedSession
                serverDataWithSavedView =
                    case ( model.selectedServerUrl, model.sessionDetail ) of
                        ( Just prevServerUrl, Just detail ) ->
                            updateServerData prevServerUrl
                                (\sd -> { sd | lastViewedSession = Just detail.sessionId })
                                model.serverData

                        ( Just prevServerUrl, Nothing ) ->
                            -- Clear lastViewedSession if we're on session list
                            updateServerData prevServerUrl
                                (\sd -> { sd | lastViewedSession = Nothing })
                                model.serverData

                        _ ->
                            model.serverData

                -- Get the new server's data to check for lastViewedSession
                newServerData =
                    getServerData serverUrl serverDataWithSavedView

                -- Try to restore session detail if lastViewedSession exists and session is still valid
                ( restoredSessionDetail, restoredSelectedSessionId ) =
                    case newServerData.lastViewedSession of
                        Just sessionId ->
                            -- Check if session still exists
                            case List.filter (\s -> s.id == sessionId) newServerData.sessions |> List.head of
                                Just session ->
                                    ( Just
                                        { sessionId = sessionId
                                        , showInviteDialog = False
                                        , dragState = Nothing
                                        , playersExpanded = not (Api.Session.isStarted session)
                                        }
                                    , Just sessionId
                                    )

                                Nothing ->
                                    -- Session was deleted, clear the lastViewedSession
                                    ( Nothing, Nothing )

                        Nothing ->
                            ( Nothing, Nothing )

                -- If session was deleted, update serverData to clear lastViewedSession
                finalServerData =
                    case ( newServerData.lastViewedSession, restoredSessionDetail ) of
                        ( Just _, Nothing ) ->
                            -- Session was deleted, clear it
                            updateServerData serverUrl
                                (\sd -> { sd | lastViewedSession = Nothing })
                                serverDataWithSavedView

                        _ ->
                            serverDataWithSavedView

                newModel =
                    { model
                        | selectedServerUrl = Just serverUrl
                        , contextMenu = Nothing
                        , selectedSessionId = restoredSelectedSessionId
                        , sessionDetail = restoredSessionDetail
                        , serverData = finalServerData
                    }

                maybeServer =
                    getServerByUrl serverUrl model.servers
            in
            if isConnected serverUrl model.serverData then
                -- Already connected, just switch view (data is kept up-to-date via notifications)
                ( newModel
                , Cmd.none
                )

            else
                -- Not connected, check if we have saved credentials
                case maybeServer of
                    Just server ->
                        if server.hasCredentials then
                            -- Try auto-connect with saved credentials
                            ( { newModel
                                | serverData =
                                    updateServerData serverUrl
                                        (\sd -> { sd | connectionState = Connecting })
                                        newModel.serverData
                              }
                            , Ports.autoConnect serverUrl
                            )

                        else
                            -- No credentials, show connect dialog
                            ( { newModel
                                | dialog = Just (ConnectDialog serverUrl emptyConnectForm)
                              }
                            , Cmd.none
                            )

                    Nothing ->
                        -- Server not found, show connect dialog anyway
                        ( { newModel
                            | dialog = Just (ConnectDialog serverUrl emptyConnectForm)
                          }
                        , Cmd.none
                        )

        ServerAdded result ->
            case result of
                Ok _ ->
                    ( { model | dialog = Nothing }
                    , Ports.getServers ()
                    )

                Err err ->
                    ( updateDialogError model err
                    , Cmd.none
                    )

        ServerUpdated result ->
            case result of
                Ok _ ->
                    ( { model | dialog = Nothing }
                    , Ports.getServers ()
                    )

                Err err ->
                    ( updateDialogError model err
                    , Cmd.none
                    )

        ServerRemoved result ->
            case result of
                Ok _ ->
                    ( { model
                        | dialog = Nothing
                        , selectedServerUrl = Nothing
                      }
                    , Cmd.batch [ Ports.getServers (), Ports.hasDefaultServer () ]
                    )

                Err err ->
                    ( { model | error = Just err }
                    , Cmd.none
                    )

        GotHasDefaultServer result ->
            case result of
                Ok hasDefault ->
                    ( { model | hasDefaultServer = hasDefault }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        AddDefaultServer ->
            ( model, Ports.addDefaultServer () )

        DefaultServerAdded result ->
            case result of
                Ok server ->
                    ( { model
                        | servers = model.servers ++ [ server ]
                        , hasDefaultServer = True
                        , dialog = Nothing
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( updateDialogError model err
                    , Cmd.none
                    )

        OpenAddServerDialog ->
            ( { model | dialog = Just (AddServerDialog emptyServerForm) }
            , Ports.hasDefaultServer ()
            )

        OpenEditServerDialog serverUrl ->
            case getServerByUrl serverUrl model.servers of
                Just server ->
                    ( { model
                        | dialog =
                            Just
                                (EditServerDialog serverUrl
                                    { name = server.name
                                    , url = server.url
                                    , originalName = Just server.name
                                    , error = Nothing
                                    , submitting = False
                                    }
                                )
                        , contextMenu = Nothing
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        OpenRemoveServerDialog serverUrl serverName ->
            ( { model
                | dialog = Just (RemoveServerDialog serverUrl serverName)
                , contextMenu = Nothing
              }
            , Cmd.none
            )

        CloseDialog ->
            -- Check if we're closing a successful registration dialog
            -- If so, trigger auto-connect
            case model.dialog of
                Just (RegisterDialog serverUrl form) ->
                    if form.success then
                        ( { model | dialog = Nothing }
                        , Ports.autoConnect serverUrl
                        )

                    else
                        ( { model | dialog = Nothing }
                        , Cmd.none
                        )

                _ ->
                    ( { model | dialog = Nothing }
                    , Cmd.none
                    )

        UpdateServerFormName name ->
            ( updateServerForm model (\form -> { form | name = name })
            , Cmd.none
            )

        UpdateServerFormUrl url ->
            ( updateServerForm model (\form -> { form | url = url })
            , Cmd.none
            )

        SubmitAddServer ->
            case model.dialog of
                Just (AddServerDialog form) ->
                    if String.isEmpty form.name || String.isEmpty form.url then
                        ( updateDialogError model "Name and URL are required"
                        , Cmd.none
                        )

                    else
                        ( updateServerForm model (\f -> { f | submitting = True, error = Nothing })
                        , Ports.addServer (Encode.addServer form.name form.url)
                        )

                _ ->
                    ( model, Cmd.none )

        SubmitEditServer oldUrl ->
            case model.dialog of
                Just (EditServerDialog _ form) ->
                    if String.isEmpty form.name || String.isEmpty form.url then
                        ( updateDialogError model "Name and URL are required"
                        , Cmd.none
                        )

                    else
                        ( updateServerForm model (\f -> { f | submitting = True, error = Nothing })
                        , Ports.updateServer (Encode.updateServer oldUrl form.name form.url)
                        )

                _ ->
                    ( model, Cmd.none )

        ConfirmRemoveServer serverUrl ->
            ( { model | dialog = Nothing }
            , Ports.removeServer serverUrl
            )

        ShowContextMenu serverUrl x y ->
            ( { model
                | contextMenu = Just { serverUrl = serverUrl, x = x, y = y }
              }
            , Cmd.none
            )

        HideContextMenu ->
            ( { model | contextMenu = Nothing }
            , Cmd.none
            )
