module Update.Notifications exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for WebSocket notification messages.

Handles real-time updates from the server via WebSocket.

-}

import Api.Encode as Encode
import Dict
import Model exposing (..)
import Ports
import Process
import Set
import Task
import Update.Helpers exposing (removeSessionTurn, setConnectionState)


{-| Notifications-specific messages.
-}
type Msg
    = ConnectionChanged String Bool -- serverUrl, isConnected
    | OrderConflictReceived String String Int -- serverUrl, sessionId, year
    | NotificationSessionTurn String String String (Maybe Int) -- serverUrl, sessionId, action, year
    | NotificationSession String String String -- serverUrl, id, action
    | NotificationInvitation String String String -- serverUrl, id, action
    | NotificationRace String String String -- serverUrl, id, action
    | NotificationRuleset String String String -- serverUrl, sessionId, action
    | NotificationPlayerRace String String String -- serverUrl, id, action
    | NotificationOrderStatus String String String -- serverUrl, sessionId, action
    | NotificationPendingRegistration String String String (Maybe String) (Maybe String) -- serverUrl, id, action, userProfileId, nickname
    | HideToast


{-| Handle all Notifications messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ConnectionChanged serverUrl isConnected_ ->
            let
                currentState =
                    getConnectionState serverUrl model.serverData

                newState =
                    if isConnected_ then
                        -- We don't have user info here, keep existing if connected
                        case currentState of
                            Connected info ->
                                Connected info

                            _ ->
                                Connecting

                    else
                        Disconnected
            in
            ( setConnectionState serverUrl newState model
            , Cmd.none
            )

        OrderConflictReceived serverUrl sessionId year ->
            let
                updateConflicts : ServerData -> ServerData
                updateConflicts data =
                    let
                        sessionConflicts =
                            Dict.get sessionId data.orderConflicts
                                |> Maybe.withDefault Set.empty
                                |> Set.insert year
                    in
                    { data | orderConflicts = Dict.insert sessionId sessionConflicts data.orderConflicts }
            in
            ( { model
                | serverData =
                    updateServerData serverUrl
                        updateConflicts
                        model.serverData
              }
            , Cmd.none
            )

        NotificationSession serverUrl sessionId action ->
            let
                isSelectedServer =
                    model.selectedServerUrl == Just serverUrl
            in
            case action of
                "deleted" ->
                    -- Remove the session from the list locally and close detail if viewing it
                    let
                        closeDetail =
                            isSelectedServer
                                && (case model.sessionDetail of
                                        Just detail ->
                                            detail.sessionId == sessionId

                                        Nothing ->
                                            False
                                   )

                        -- Remove session from list and clear lastViewedSession if it was the deleted session
                        updatedServerData =
                            updateServerData serverUrl
                                (\sd ->
                                    { sd
                                        | sessions = List.filter (\s -> s.id /= sessionId) sd.sessions
                                        , lastViewedSession =
                                            if sd.lastViewedSession == Just sessionId then
                                                Nothing

                                            else
                                                sd.lastViewedSession
                                    }
                                )
                                model.serverData
                    in
                    ( if closeDetail then
                        { model | sessionDetail = Nothing, serverData = updatedServerData }

                      else
                        { model | serverData = updatedServerData }
                    , Cmd.none
                    )

                _ ->
                    -- For created/updated, fetch only the specific session
                    -- GotSession will upsert it into the sessions list
                    ( model
                    , Ports.getSession (Encode.getSession serverUrl sessionId)
                    )

        NotificationInvitation serverUrl invitationId action ->
            case action of
                "deleted" ->
                    -- Remove the invitation from both received and sent lists
                    -- Also refresh sessions since pendingInvitation flag may have changed
                    ( { model
                        | serverData =
                            updateServerData serverUrl
                                (\sd ->
                                    { sd
                                        | invitations =
                                            List.filter (\inv -> inv.id /= invitationId) sd.invitations
                                        , sentInvitations =
                                            List.filter (\inv -> inv.id /= invitationId) sd.sentInvitations
                                    }
                                )
                                model.serverData
                      }
                    , Ports.getSessions serverUrl
                    )

                _ ->
                    -- For created/updated, refresh invitations from server
                    ( model
                    , Cmd.batch
                        [ Ports.getInvitations serverUrl
                        , Ports.getSentInvitations serverUrl
                        ]
                    )

        NotificationRace serverUrl _ _ ->
            -- Refresh races when notified (for any server, not just selected)
            ( model
            , Ports.getRaces serverUrl
            )

        NotificationPlayerRace serverUrl _ _ ->
            -- Refresh session data (player races are part of session) for any server
            let
                isSelectedServer =
                    model.selectedServerUrl == Just serverUrl
            in
            ( model
            , Cmd.batch
                [ -- Always refresh sessions list to update player counts
                  Ports.getSessions serverUrl
                , -- Also refresh the specific session if viewing it on selected server
                  if isSelectedServer then
                    case model.sessionDetail of
                        Just detail ->
                            Ports.getSession (Encode.getSession serverUrl detail.sessionId)

                        Nothing ->
                            Cmd.none

                  else
                    Cmd.none
                ]
            )

        NotificationRuleset serverUrl sessionId _ ->
            let
                isSelectedServer =
                    model.selectedServerUrl == Just serverUrl
            in
            ( { model
                | serverData =
                    -- Remove cached rules so they get refetched
                    updateServerData serverUrl
                        (\sd ->
                            { sd
                                | sessionRules =
                                    Dict.remove sessionId sd.sessionRules
                            }
                        )
                        model.serverData
              }
            , -- Refetch if dialog is open for this session on selected server
              if isSelectedServer then
                case model.dialog of
                    Just (RulesDialog form) ->
                        if form.sessionId == sessionId then
                            Ports.getRules (Encode.getRules serverUrl sessionId)

                        else
                            Cmd.none

                    _ ->
                        Cmd.none

              else
                Cmd.none
            )

        NotificationSessionTurn serverUrl sessionId action maybeYear ->
            -- Handle turn notifications for any server, not just selected
            -- Always save to game dir since each server has its own game directory
            case ( action, maybeYear ) of
                ( "deleted", Just year ) ->
                    -- Remove the turn from cache
                    ( removeSessionTurn serverUrl sessionId year model
                    , Cmd.none
                    )

                ( _, Just year ) ->
                    -- For created/updated/ready, fetch the turn files and refresh orders status
                    -- Old years' orders status remain valid in the cache
                    ( model
                    , Cmd.batch
                        [ Ports.getTurn (Encode.getTurn serverUrl sessionId year True)
                        , Ports.getSession (Encode.getSession serverUrl sessionId)
                        , Ports.getOrdersStatus (Encode.getOrdersStatus serverUrl sessionId)
                        ]
                    )

                ( "ready", Nothing ) ->
                    -- Turn ready without year - fetch latest turn and refresh orders status
                    ( model
                    , Cmd.batch
                        [ Ports.getLatestTurn (Encode.getLatestTurn serverUrl sessionId)
                        , Ports.getSession (Encode.getSession serverUrl sessionId)
                        , Ports.getOrdersStatus (Encode.getOrdersStatus serverUrl sessionId)
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        NotificationOrderStatus serverUrl sessionId action ->
            if action == "updated" then
                ( model
                , Ports.getOrdersStatus (Encode.getOrdersStatus serverUrl sessionId)
                )

            else
                ( model, Cmd.none )

        NotificationPendingRegistration serverUrl _ action maybeUserProfileId _ ->
            let
                serverData =
                    getServerData serverUrl model.serverData

                -- Get current user ID from connection state
                currentUserId =
                    case serverData.connectionState of
                        Connected info ->
                            Just info.userId

                        _ ->
                            Nothing

                -- Check if this approval/rejection is for the current user
                isCurrentUserApproved =
                    action == "approved" && maybeUserProfileId == currentUserId && currentUserId /= Nothing

                isCurrentUserRejected =
                    action == "rejected" && maybeUserProfileId == currentUserId && currentUserId /= Nothing

                -- If current user was approved, reconnect to refresh their permissions
                reconnectCmd =
                    if isCurrentUserApproved then
                        Cmd.batch
                            [ Ports.disconnect serverUrl
                            , Ports.autoConnect serverUrl
                            ]

                    else
                        Cmd.none

                -- Show toast and update model for current user approval/rejection
                ( updatedModel, toastCmd ) =
                    if isCurrentUserApproved then
                        ( { model | toast = Just "Your registration has been approved! Reconnecting..." }
                        , Process.sleep 3000 |> Task.perform (\_ -> HideToast)
                        )

                    else if isCurrentUserRejected then
                        ( { model | toast = Just "Your registration has been rejected." }
                        , Process.sleep 3000 |> Task.perform (\_ -> HideToast)
                        )

                    else
                        ( model, Cmd.none )
            in
            -- Refetch pending registrations when notified (created/approved/rejected)
            -- This keeps the count and dialog in sync with the server
            ( updatedModel
            , Cmd.batch
                [ Ports.getPendingRegistrations serverUrl
                , reconnectCmd
                , toastCmd
                ]
            )

        HideToast ->
            ( { model | toast = Nothing }
            , Cmd.none
            )
