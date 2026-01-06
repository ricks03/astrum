module Update.UI exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for UI-related messages.

Handles zoom controls, escape key, error clearing, and browser Stars! feature toggle.

-}

import Model exposing (..)
import Ports


{-| UI-specific messages.
-}
type Msg
    = ClearError
    | EscapePressed
    | ZoomIn
    | ZoomOut
    | ZoomReset
    | ZoomLevelSet (Result String AppSettings)
    | RequestEnableBrowserStars Bool
    | ConfirmEnableBrowserStars
    | CancelEnableBrowserStars
    | EnableBrowserStarsSet (Result String AppSettings)


{-| Handle all UI messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClearError ->
            ( { model | error = Nothing }, Cmd.none )

        EscapePressed ->
            ( { model
                | dialog = Nothing
                , contextMenu = Nothing
                , showUserMenu = False
              }
            , Cmd.none
            )

        ZoomIn ->
            let
                currentLevel =
                    model.appSettings
                        |> Maybe.map .zoomLevel
                        |> Maybe.withDefault 100

                newLevel =
                    min 200 (currentLevel + 10)
            in
            ( model, Ports.setZoomLevel newLevel )

        ZoomOut ->
            let
                currentLevel =
                    model.appSettings
                        |> Maybe.map .zoomLevel
                        |> Maybe.withDefault 100

                newLevel =
                    max 50 (currentLevel - 10)
            in
            ( model, Ports.setZoomLevel newLevel )

        ZoomReset ->
            ( model, Ports.setZoomLevel 100 )

        ZoomLevelSet result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        RequestEnableBrowserStars enabled ->
            if enabled then
                ( { model | confirmingBrowserStars = True }, Cmd.none )

            else
                ( model, Ports.setEnableBrowserStars False )

        ConfirmEnableBrowserStars ->
            ( { model | confirmingBrowserStars = False }
            , Ports.setEnableBrowserStars True
            )

        CancelEnableBrowserStars ->
            ( { model | confirmingBrowserStars = False }, Cmd.none )

        EnableBrowserStarsSet result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )
