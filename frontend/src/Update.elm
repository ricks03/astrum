module Update exposing (update)

{-| Application update logic.

This module routes all messages to their appropriate handler modules.

-}

import Model exposing (Model)
import Msg exposing (Msg(..))
import Update.Admin as Admin
import Update.Auth as Auth
import Update.DragDrop as DragDrop
import Update.MapViewer as MapViewer
import Update.Notifications as Notifications
import Update.RaceBuilder as RaceBuilder
import Update.Races as Races
import Update.Rules as Rules
import Update.Server as Server
import Update.SessionDetail as SessionDetail
import Update.Sessions as Sessions
import Update.Settings as Settings
import Update.TurnFiles as TurnFiles
import Update.UI as UI



-- =============================================================================
-- UPDATE
-- =============================================================================


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        -- =====================================================================
        -- Sub-message delegation
        -- =====================================================================
        UIMsg subMsg ->
            let
                ( newModel, cmd ) =
                    UI.update subMsg model
            in
            ( newModel, Cmd.map UIMsg cmd )

        MapViewerMsg subMsg ->
            let
                ( newModel, cmd ) =
                    MapViewer.update subMsg model
            in
            ( newModel, Cmd.map MapViewerMsg cmd )

        SettingsMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Settings.update subMsg model
            in
            ( newModel, Cmd.map SettingsMsg cmd )

        DragDropMsg subMsg ->
            let
                ( newModel, cmd ) =
                    DragDrop.update subMsg model
            in
            ( newModel, Cmd.map DragDropMsg cmd )

        AuthMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Auth.update subMsg model
            in
            ( newModel, Cmd.map AuthMsg cmd )

        ServerMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Server.update subMsg model
            in
            ( newModel, Cmd.map ServerMsg cmd )

        NotificationsMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Notifications.update subMsg model
            in
            ( newModel, Cmd.map NotificationsMsg cmd )

        TurnFilesMsg subMsg ->
            let
                ( newModel, cmd ) =
                    TurnFiles.update subMsg model
            in
            ( newModel, Cmd.map TurnFilesMsg cmd )

        RacesMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Races.update subMsg model
            in
            ( newModel, Cmd.map RacesMsg cmd )

        RulesMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Rules.update subMsg model
            in
            ( newModel, Cmd.map RulesMsg cmd )

        SessionsMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Sessions.update subMsg model
            in
            ( newModel, Cmd.map SessionsMsg cmd )

        SessionDetailMsg subMsg ->
            let
                ( newModel, cmd ) =
                    SessionDetail.update subMsg model
            in
            ( newModel, Cmd.map SessionDetailMsg cmd )

        RaceBuilderMsg subMsg ->
            let
                ( newModel, cmd ) =
                    RaceBuilder.update subMsg model
            in
            ( newModel, Cmd.map RaceBuilderMsg cmd )

        AdminMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Admin.update subMsg model
            in
            ( newModel, Cmd.map AdminMsg cmd )

