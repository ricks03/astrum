module View.Dialog.Settings exposing (viewSettingsDialog)

{-| Settings dialog for application configuration.
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (AppSettings, NtvdmCheckResult)
import Msg exposing (Msg(..))
import Update.Server
import Update.Settings
import Update.UI


{-| Dialog for configuring application settings.
-}
viewSettingsDialog : Maybe AppSettings -> Bool -> Maybe String -> Bool -> Maybe NtvdmCheckResult -> Bool -> Html Msg
viewSettingsDialog maybeSettings wineCheckInProgress wineCheckMessage ntvdmCheckInProgress ntvdmCheckResult confirmingBrowserStars =
    let
        serversDir =
            maybeSettings
                |> Maybe.map .serversDir
                |> Maybe.withDefault "Loading..."

        autoDownloadStars =
            maybeSettings
                |> Maybe.map .autoDownloadStars
                |> Maybe.withDefault True

        zoomLevel =
            maybeSettings
                |> Maybe.map .zoomLevel
                |> Maybe.withDefault 100

        useWine =
            maybeSettings
                |> Maybe.map .useWine
                |> Maybe.withDefault False

        winePrefixesDir =
            maybeSettings
                |> Maybe.map .winePrefixesDir
                |> Maybe.withDefault "~/.config/astrum/wine_prefixes"

        validWineInstall =
            maybeSettings
                |> Maybe.map .validWineInstall
                |> Maybe.withDefault False

        enableBrowserStars =
            maybeSettings
                |> Maybe.map .enableBrowserStars
                |> Maybe.withDefault False
    in
    div [ class "settings-dialog" ]
        [ div [ class "dialog__header" ]
            [ h2 [ class "dialog__title" ] [ text "Settings" ]
            , button
                [ class "dialog__close"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text "\u{00D7}" ]
            ]
        , div [ class "dialog__body" ]
            [ div [ class "settings-dialog__section" ]
                [ h3 [ class "settings-dialog__section-title" ] [ text "Display" ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__label" ]
                        [ text ("Zoom Level: " ++ String.fromInt zoomLevel ++ "%") ]
                    , div [ class "settings-dialog__zoom-row" ]
                        [ button
                            [ class "btn btn--secondary btn--small"
                            , onClick (UIMsg Update.UI.ZoomOut)
                            , disabled (zoomLevel <= 50)
                            ]
                            [ text "-" ]
                        , div [ class "settings-dialog__zoom-bar" ]
                            [ div
                                [ class "settings-dialog__zoom-fill"
                                , style "width" (String.fromFloat ((toFloat (zoomLevel - 50) / 150) * 100) ++ "%")
                                ]
                                []
                            ]
                        , button
                            [ class "btn btn--secondary btn--small"
                            , onClick (UIMsg Update.UI.ZoomIn)
                            , disabled (zoomLevel >= 200)
                            ]
                            [ text "+" ]
                        , button
                            [ class "btn btn--secondary btn--small"
                            , onClick (UIMsg Update.UI.ZoomReset)
                            ]
                            [ text "Reset" ]
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Shortcuts: Ctrl+Plus/Minus, Ctrl+Scroll, or Ctrl+0 to reset." ]
                    ]
                ]
            , div [ class "settings-dialog__section" ]
                [ h3 [ class "settings-dialog__section-title" ] [ text "Game Files" ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__label" ] [ text "Servers Directory" ]
                    , div [ class "settings-dialog__path-row" ]
                        [ span [ class "settings-dialog__path" ] [ text serversDir ]
                        , button
                            [ class "btn btn--secondary btn--small"
                            , onClick (SettingsMsg Update.Settings.SelectServersDir)
                            ]
                            [ text "Change..." ]
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Game files for each session are stored in subdirectories under this folder." ]
                    ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__checkbox-label" ]
                        [ input
                            [ type_ "checkbox"
                            , checked autoDownloadStars
                            , onCheck (SettingsMsg << Update.Settings.SetAutoDownloadStars)
                            ]
                            []
                        , text "Auto download Stars.exe"
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Automatically download Stars.exe from the server to each session directory." ]
                    ]
                ]
            , div [ class "settings-dialog__section" ]
                [ h3 [ class "settings-dialog__section-title" ] [ text "Wine (Linux)" ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__checkbox-label" ]
                        [ input
                            [ type_ "checkbox"
                            , checked useWine
                            , onCheck (SettingsMsg << Update.Settings.SetUseWine)
                            ]
                            []
                        , text "Use Wine to launch Stars!"
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Enable this on Linux to run Stars! through Wine." ]
                    ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__label" ] [ text "Wine Prefixes Directory" ]
                    , div [ class "settings-dialog__path-row" ]
                        [ span [ class "settings-dialog__path" ] [ text winePrefixesDir ]
                        , button
                            [ class "btn btn--secondary btn--small"
                            , onClick (SettingsMsg Update.Settings.SelectWinePrefixesDir)
                            , disabled (not useWine)
                            ]
                            [ text "Change..." ]
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Directory containing per-server Wine prefixes. Each server gets its own prefix for separate serial keys." ]
                    ]
                , div [ class "settings-dialog__field" ]
                    [ div [ class "settings-dialog__wine-check-row" ]
                        [ button
                            [ class "btn btn--secondary"
                            , onClick (SettingsMsg Update.Settings.CheckWineInstall)
                            , disabled (not useWine || wineCheckInProgress)
                            ]
                            [ text
                                (if wineCheckInProgress then
                                    "Checking..."

                                 else
                                    "Check Wine Installation"
                                )
                            ]
                        , viewWineStatus validWineInstall wineCheckMessage
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Verifies that 32-bit Wine is properly installed and working." ]
                    ]
                ]
            , div [ class "settings-dialog__section" ]
                [ h3 [ class "settings-dialog__section-title" ] [ text "16-bit Support (Windows)" ]
                , div [ class "settings-dialog__field" ]
                    [ p [ class "settings-dialog__hint" ]
                        [ text "Stars! is a 16-bit application. 64-bit Windows requires OTVDM (winevdm) to run 16-bit programs. 32-bit Windows uses native NTVDM." ]
                    ]
                , div [ class "settings-dialog__field" ]
                    [ div [ class "settings-dialog__wine-check-row" ]
                        [ button
                            [ class "btn btn--secondary"
                            , onClick (SettingsMsg Update.Settings.CheckNtvdmSupport)
                            , disabled ntvdmCheckInProgress
                            ]
                            [ text
                                (if ntvdmCheckInProgress then
                                    "Checking..."

                                 else
                                    "Check 16-bit Support"
                                )
                            ]
                        , viewNtvdmStatus ntvdmCheckResult
                        ]
                    , p [ class "settings-dialog__hint" ]
                        [ text "Checks for OTVDM (64-bit) or NTVDM (32-bit) to run Stars!." ]
                    ]
                ]
            , div [ class "settings-dialog__section" ]
                [ h3 [ class "settings-dialog__section-title" ] [ text "Experimental" ]
                , div [ class "settings-dialog__field" ]
                    [ label [ class "settings-dialog__checkbox-label" ]
                        [ input
                            [ type_ "checkbox"
                            , checked enableBrowserStars
                            , onCheck (UIMsg << Update.UI.RequestEnableBrowserStars)
                            ]
                            []
                        , text "Enable Stars! in Browser"
                        ]
                    , p [ class "settings-dialog__hint settings-dialog__hint--warning" ]
                        [ text "Run Stars! directly in your browser using DOSBox emulation. This is experimental and should not be mixed with the native Stars! executable." ]
                    ]
                ]
            ]
        , div [ class "dialog__footer" ]
            [ button
                [ class "btn btn--secondary"
                , onClick (ServerMsg Update.Server.CloseDialog)
                ]
                [ text "Close" ]
            ]
        , viewBrowserStarsConfirmation confirmingBrowserStars
        ]


{-| Confirmation dialog for enabling browser Stars!.
-}
viewBrowserStarsConfirmation : Bool -> Html Msg
viewBrowserStarsConfirmation show =
    if show then
        div [ class "confirmation-overlay" ]
            [ div [ class "confirmation-dialog" ]
                [ div [ class "confirmation-dialog__header" ]
                    [ h3 [] [ text "Enable Browser Stars!?" ] ]
                , div [ class "confirmation-dialog__body" ]
                    [ p [ class "confirmation-dialog__warning" ]
                        [ text "Do NOT mix Stars! in the browser with another Stars! executable to manipulate your files or you risk file corruptions." ]
                    , p []
                        [ text "When this feature is enabled:" ]
                    , ul []
                        [ li [] [ text "The \"Run Stars!\" button will be disabled" ]
                        , li [] [ text "A \"Launch in Browser\" button will appear instead" ]
                        ]
                    ]
                , div [ class "confirmation-dialog__footer" ]
                    [ button
                        [ class "btn btn--secondary"
                        , onClick (UIMsg Update.UI.CancelEnableBrowserStars)
                        ]
                        [ text "Cancel" ]
                    , button
                        [ class "btn btn--primary"
                        , onClick (UIMsg Update.UI.ConfirmEnableBrowserStars)
                        ]
                        [ text "Enable" ]
                    ]
                ]
            ]

    else
        text ""


{-| Display the wine installation status.
-}
viewWineStatus : Bool -> Maybe String -> Html Msg
viewWineStatus isValid maybeMessage =
    case maybeMessage of
        Just message ->
            if isValid then
                span [ class "settings-dialog__wine-status settings-dialog__wine-status--valid" ]
                    [ text message ]

            else
                span [ class "settings-dialog__wine-status settings-dialog__wine-status--invalid" ]
                    [ text message ]

        Nothing ->
            if isValid then
                span [ class "settings-dialog__wine-status settings-dialog__wine-status--valid" ]
                    [ text "Validated" ]

            else
                span [ class "settings-dialog__wine-status settings-dialog__wine-status--not-checked" ]
                    [ text "Not checked" ]


{-| Display the NTVDM check status.
-}
viewNtvdmStatus : Maybe NtvdmCheckResult -> Html Msg
viewNtvdmStatus maybeResult =
    case maybeResult of
        Just result ->
            if result.available then
                div [ class "settings-dialog__wine-status settings-dialog__wine-status--valid" ]
                    [ text result.message ]

            else
                div [ class "settings-dialog__wine-status settings-dialog__wine-status--invalid" ]
                    [ text result.message
                    , case result.helpUrl of
                        Just url ->
                            div [ class "settings-dialog__help-link" ]
                                [ a [ href url, target "_blank" ] [ text "Download OTVDM nightly build" ]
                                ]

                        Nothing ->
                            text ""
                    ]

        Nothing ->
            div [ class "settings-dialog__wine-status settings-dialog__wine-status--not-checked" ]
                [ text "Not checked" ]
