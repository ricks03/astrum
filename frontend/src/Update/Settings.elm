module Update.Settings exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for app settings messages.

Handles settings dialog, directories, Wine/NTVDM configuration.

-}

import Model exposing (..)
import Ports


{-| Settings-specific messages.
-}
type Msg
    = OpenSettingsDialog
    | SelectServersDir
    | GotAppSettings (Result String AppSettings)
    | ServersDirSelected (Result String AppSettings)
    | SetAutoDownloadStars Bool
    | AutoDownloadStarsSet (Result String AppSettings)
    | SetUseWine Bool
    | UseWineSet (Result String AppSettings)
    | SelectWinePrefixesDir
    | WinePrefixesDirSelected (Result String AppSettings)
    | CheckWineInstall
    | WineInstallChecked (Result String { valid : Bool, message : String })
    | CheckNtvdmSupport
    | NtvdmChecked (Result String NtvdmCheckResult)


{-| Handle all Settings messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenSettingsDialog ->
            ( { model | dialog = Just SettingsDialog }
            , Ports.getAppSettings ()
            )

        SelectServersDir ->
            ( model, Ports.selectServersDir () )

        GotAppSettings result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ServersDirSelected result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        SetAutoDownloadStars enabled ->
            ( model, Ports.setAutoDownloadStars enabled )

        AutoDownloadStarsSet result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        SetUseWine enabled ->
            ( model, Ports.setUseWine enabled )

        UseWineSet result ->
            case result of
                Ok settings ->
                    ( { model
                        | appSettings = Just settings
                        , wineCheckMessage = Nothing
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        SelectWinePrefixesDir ->
            ( model, Ports.selectWinePrefixesDir () )

        WinePrefixesDirSelected result ->
            case result of
                Ok settings ->
                    ( { model | appSettings = Just settings }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        CheckWineInstall ->
            ( { model | wineCheckInProgress = True, wineCheckMessage = Nothing }
            , Ports.checkWineInstall ()
            )

        WineInstallChecked result ->
            case result of
                Ok checkResult ->
                    let
                        updatedSettings =
                            model.appSettings
                                |> Maybe.map (\s -> { s | validWineInstall = checkResult.valid })
                    in
                    ( { model
                        | appSettings = updatedSettings
                        , wineCheckInProgress = False
                        , wineCheckMessage = Just checkResult.message
                      }
                    , Cmd.none
                    )

                Err errMsg ->
                    ( { model
                        | wineCheckInProgress = False
                        , wineCheckMessage = Just ("Check failed: " ++ errMsg)
                      }
                    , Cmd.none
                    )

        CheckNtvdmSupport ->
            ( { model | ntvdmCheckInProgress = True }, Ports.checkNtvdmSupport () )

        NtvdmChecked result ->
            case result of
                Ok checkResult ->
                    ( { model
                        | ntvdmCheckInProgress = False
                        , ntvdmCheckResult = Just checkResult
                      }
                    , Cmd.none
                    )

                Err errMsg ->
                    ( { model
                        | ntvdmCheckInProgress = False
                        , ntvdmCheckResult = Just { available = False, is64Bit = False, message = "Check failed: " ++ errMsg, helpUrl = Nothing }
                      }
                    , Cmd.none
                    )
