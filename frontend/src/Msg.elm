module Msg exposing (Msg(..))

{-| All application messages.

This module defines every possible message that can occur in the application.
Messages are grouped by domain for clarity.

-}

import Update.Admin
import Update.Auth
import Update.DragDrop
import Update.MapViewer
import Update.Notifications
import Update.Races
import Update.Rules
import Update.Server
import Update.SessionDetail
import Update.Sessions
import Update.Settings
import Update.TurnFiles
import Update.RaceBuilder
import Update.UI


type Msg
    = NoOp
      -- =========================================================================
      -- Sub-message Types
      -- =========================================================================
    | UIMsg Update.UI.Msg
    | MapViewerMsg Update.MapViewer.Msg
    | SettingsMsg Update.Settings.Msg
    | DragDropMsg Update.DragDrop.Msg
    | AuthMsg Update.Auth.Msg
    | ServerMsg Update.Server.Msg
    | NotificationsMsg Update.Notifications.Msg
    | TurnFilesMsg Update.TurnFiles.Msg
    | RacesMsg Update.Races.Msg
    | RulesMsg Update.Rules.Msg
    | RaceBuilderMsg Update.RaceBuilder.Msg
    | SessionsMsg Update.Sessions.Msg
    | SessionDetailMsg Update.SessionDetail.Msg
    | AdminMsg Update.Admin.Msg
