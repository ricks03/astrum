module View.Dialog.MapViewer exposing (viewMapViewerDialog)

{-| Map viewer dialog for displaying SVG and animated GIF maps of Stars! games.
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Model exposing (MapOptions, MapOutputFormat(..), MapViewerForm)
import Msg exposing (Msg(..))
import Update.MapViewer
import Update.Server


{-| View the map viewer dialog.
-}
viewMapViewerDialog : MapViewerForm -> Html Msg
viewMapViewerDialog form =
    div [ class "map-viewer-dialog" ]
        [ viewHeader form
        , viewBody form
        , viewFooter form
        ]


{-| Dialog header with title and close button.
-}
viewHeader : MapViewerForm -> Html Msg
viewHeader form =
    div [ class "dialog__header" ]
        [ h2 [ class "dialog__title" ]
            [ text ("Map Viewer - Year " ++ String.fromInt form.year) ]
        , button
            [ class "dialog__close"
            , onClick (ServerMsg Update.Server.CloseDialog)
            ]
            [ text "×" ]
        ]


{-| Dialog body with options panel and map display.
-}
viewBody : MapViewerForm -> Html Msg
viewBody form =
    div [ class "dialog__body map-viewer-dialog__body" ]
        [ viewOptionsPanel form.options
        , viewMapDisplay form
        ]


{-| Options panel (left side).
-}
viewOptionsPanel : MapOptions -> Html Msg
viewOptionsPanel options =
    div [ class "map-viewer-dialog__options" ]
        [ h3 [ class "map-viewer-dialog__section-title" ] [ text "Output Format" ]
        , viewFormatOptions options
        , h3 [ class "map-viewer-dialog__section-title" ] [ text "Resolution" ]
        , viewResolutionOptions options
        , h3 [ class "map-viewer-dialog__section-title" ] [ text "Display Options" ]
        , viewDisplayOptions options
        ]


{-| Output format selection (SVG or GIF).
-}
viewFormatOptions : MapOptions -> Html Msg
viewFormatOptions options =
    div [ class "map-viewer-dialog__format-options" ]
        [ label [ class "map-viewer-dialog__radio" ]
            [ input
                [ type_ "radio"
                , name "mapFormat"
                , checked (options.outputFormat == SVGFormat)
                , onClick (MapViewerMsg (Update.MapViewer.SelectMapFormat "svg"))
                ]
                []
            , text "Static Map (SVG) - current year"
            ]
        , label [ class "map-viewer-dialog__radio" ]
            [ input
                [ type_ "radio"
                , name "mapFormat"
                , checked (options.outputFormat == GIFFormat)
                , onClick (MapViewerMsg (Update.MapViewer.SelectMapFormat "gif"))
                ]
                []
            , text "Animated Map (GIF) - full history"
            ]
        , case options.outputFormat of
            GIFFormat ->
                viewGifDelayInput options.gifDelay

            SVGFormat ->
                text ""
        ]


{-| GIF delay input (milliseconds between frames).
-}
viewGifDelayInput : Int -> Html Msg
viewGifDelayInput delay =
    div [ class "map-viewer-dialog__gif-delay" ]
        [ label [] [ text "Frame delay (ms):" ]
        , input
            [ type_ "number"
            , value (String.fromInt delay)
            , onInput (MapViewerMsg << Update.MapViewer.UpdateGifDelay)
            , Html.Attributes.min "100"
            , Html.Attributes.max "2000"
            , Html.Attributes.step "100"
            ]
            []
        ]


{-| Resolution options (presets and custom).
-}
viewResolutionOptions : MapOptions -> Html Msg
viewResolutionOptions options =
    div [ class "map-viewer-dialog__resolution" ]
        [ div [ class "map-viewer-dialog__presets" ]
            [ label [] [ text "Preset:" ]
            , select [ onInput (MapViewerMsg << Update.MapViewer.SelectMapPreset) ]
                [ option [ value "800x600", selected (options.width == 800 && options.height == 600) ] [ text "800 x 600" ]
                , option [ value "1024x768", selected (options.width == 1024 && options.height == 768) ] [ text "1024 x 768" ]
                , option [ value "1920x1080", selected (options.width == 1920 && options.height == 1080) ] [ text "1920 x 1080 (Full HD)" ]
                , option [ value "2560x1440", selected (options.width == 2560 && options.height == 1440) ] [ text "2560 x 1440 (2K)" ]
                , option [ value "custom" ] [ text "Custom" ]
                ]
            ]
        , div [ class "map-viewer-dialog__custom-size" ]
            [ label [] [ text "Width:" ]
            , input
                [ type_ "number"
                , value (String.fromInt options.width)
                , onInput (MapViewerMsg << Update.MapViewer.UpdateMapWidth)
                , Html.Attributes.min "400"
                , Html.Attributes.max "4096"
                ]
                []
            , label [] [ text "Height:" ]
            , input
                [ type_ "number"
                , value (String.fromInt options.height)
                , onInput (MapViewerMsg << Update.MapViewer.UpdateMapHeight)
                , Html.Attributes.min "300"
                , Html.Attributes.max "4096"
                ]
                []
            ]
        ]


{-| Display options (checkboxes).
-}
viewDisplayOptions : MapOptions -> Html Msg
viewDisplayOptions options =
    div [ class "map-viewer-dialog__display-options" ]
        [ viewCheckbox "Show planet names" options.showNames (MapViewerMsg Update.MapViewer.ToggleShowNames)
        , viewCheckbox "Show fleets" options.showFleets (MapViewerMsg Update.MapViewer.ToggleShowFleets)
        , viewFleetPathsInput options.showFleetPaths
        , viewCheckbox "Show minefields" options.showMines (MapViewerMsg Update.MapViewer.ToggleShowMines)
        , viewCheckbox "Show wormholes" options.showWormholes (MapViewerMsg Update.MapViewer.ToggleShowWormholes)
        , viewCheckbox "Show legend" options.showLegend (MapViewerMsg Update.MapViewer.ToggleShowLegend)
        , viewCheckbox "Show scanner coverage" options.showScannerCoverage (MapViewerMsg Update.MapViewer.ToggleShowScannerCoverage)
        ]


{-| Single checkbox with label.
-}
viewCheckbox : String -> Bool -> Msg -> Html Msg
viewCheckbox labelText isChecked msg =
    label [ class "map-viewer-dialog__checkbox" ]
        [ input
            [ type_ "checkbox"
            , checked isChecked
            , onClick msg
            ]
            []
        , text labelText
        ]


{-| Fleet paths input (number of years).
-}
viewFleetPathsInput : Int -> Html Msg
viewFleetPathsInput years =
    div [ class "map-viewer-dialog__fleet-paths" ]
        [ label [] [ text "Fleet paths (years):" ]
        , input
            [ type_ "number"
            , value (String.fromInt years)
            , onInput (MapViewerMsg << Update.MapViewer.UpdateShowFleetPaths)
            , Html.Attributes.min "0"
            , Html.Attributes.max "10"
            , placeholder "0 = off"
            ]
            []
        ]


{-| Map display area (right side).
-}
viewMapDisplay : MapViewerForm -> Html Msg
viewMapDisplay form =
    div [ class "map-viewer-dialog__display" ]
        [ case form.error of
            Just err ->
                div [ class "dialog__error" ] [ text err ]

            Nothing ->
                text ""
        , viewMapContent form
        ]


{-| Display the generated map content (SVG or GIF).
-}
viewMapContent : MapViewerForm -> Html Msg
viewMapContent form =
    case ( form.generatedSvg, form.generatedGif ) of
        ( Just svg, _ ) ->
            div [ class "map-viewer-dialog__svg-container" ]
                [ Html.node "iframe"
                    [ id "map-viewer-frame"
                    , attribute "srcdoc" (wrapSvgInHtml svg)
                    , class "map-viewer-dialog__svg-frame"
                    ]
                    []
                , button
                    [ class "map-viewer-dialog__fullscreen-btn"
                    , onClick (MapViewerMsg Update.MapViewer.ToggleMapFullscreen)
                    , title "View fullscreen"
                    ]
                    [ text "⛶" ]
                ]

        ( Nothing, Just gifB64 ) ->
            div [ class "map-viewer-dialog__gif-container" ]
                [ img
                    [ src ("data:image/gif;base64," ++ gifB64)
                    , class "map-viewer-dialog__gif-image"
                    , alt "Animated game map"
                    ]
                    []
                ]

        ( Nothing, Nothing ) ->
            viewPlaceholder form


{-| Placeholder when no map is generated yet.
-}
viewPlaceholder : MapViewerForm -> Html Msg
viewPlaceholder form =
    div [ class "map-viewer-dialog__placeholder" ]
        [ if form.generating then
            text "Generating SVG map..."

          else if form.generatingGif then
            text "Generating animated GIF (this may take a moment)..."

          else
            case form.options.outputFormat of
                SVGFormat ->
                    text "Click \"Generate Map\" to create the map"

                GIFFormat ->
                    text "Click \"Generate Animated Map\" to create the animation"
        ]


{-| Wrap SVG content in an HTML document with centering styles.
-}
wrapSvgInHtml : String -> String
wrapSvgInHtml svg =
    """<!DOCTYPE html>
<html>
<head>
<style>
html, body {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    background: #1a1a2e;
}
body {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100%;
}
svg {
    max-width: 100%;
    max-height: 100%;
}
</style>
</head>
<body>
""" ++ svg ++ """
</body>
</html>"""


{-| Dialog footer with action buttons.
-}
viewFooter : MapViewerForm -> Html Msg
viewFooter form =
    div [ class "dialog__footer" ]
        [ div [ class "dialog__actions" ]
            (viewGenerateButton form
                ++ viewSaveButton form
                ++ [ button
                        [ class "btn"
                        , onClick (ServerMsg Update.Server.CloseDialog)
                        ]
                        [ text "Close" ]
                   ]
            )
        ]


{-| Generate button based on output format.
-}
viewGenerateButton : MapViewerForm -> List (Html Msg)
viewGenerateButton form =
    case form.options.outputFormat of
        SVGFormat ->
            [ button
                [ class "btn btn--primary"
                , onClick (MapViewerMsg Update.MapViewer.GenerateMap)
                , disabled (form.generating || form.generatingGif)
                ]
                [ text
                    (if form.generating then
                        "Generating..."

                     else
                        "Generate Map"
                    )
                ]
            ]

        GIFFormat ->
            [ button
                [ class "btn btn--primary"
                , onClick (MapViewerMsg Update.MapViewer.GenerateAnimatedMap)
                , disabled (form.generating || form.generatingGif)
                ]
                [ text
                    (if form.generatingGif then
                        "Generating..."

                     else
                        "Generate Animated Map"
                    )
                ]
            ]


{-| Save button based on generated content.
-}
viewSaveButton : MapViewerForm -> List (Html Msg)
viewSaveButton form =
    case ( form.generatedSvg, form.generatedGif ) of
        ( Just _, _ ) ->
            [ button
                [ class "btn btn--secondary"
                , onClick (MapViewerMsg Update.MapViewer.SaveMap)
                , disabled form.saving
                ]
                [ text
                    (if form.saving then
                        "Saving..."

                     else
                        "Save SVG"
                    )
                ]
            ]

        ( Nothing, Just _ ) ->
            [ button
                [ class "btn btn--secondary"
                , onClick (MapViewerMsg Update.MapViewer.SaveGif)
                , disabled form.saving
                ]
                [ text
                    (if form.saving then
                        "Saving..."

                     else
                        "Save GIF"
                    )
                ]
            ]

        ( Nothing, Nothing ) ->
            []
