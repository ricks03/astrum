module Update.MapViewer exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for map viewer messages.

Handles map generation, options, and export.

-}

import Api.Encode as Encode
import Dict
import Model exposing (..)
import Ports
import Update.Helpers exposing (clearMapContent, updateMapOptions, updateMapViewerForm)


{-| MapViewer-specific messages.
-}
type Msg
    = OpenMapViewer String Int String Int -- sessionId, year, raceName, playerNumber
    | UpdateMapWidth String
    | UpdateMapHeight String
    | SelectMapPreset String -- "800x600", "1024x768", etc.
    | ToggleShowNames
    | ToggleShowFleets
    | UpdateShowFleetPaths String
    | ToggleShowMines
    | ToggleShowWormholes
    | ToggleShowLegend
    | ToggleShowScannerCoverage
    | GenerateMap
    | MapGenerated (Result String String) -- SVG string result
    | SaveMap
    | MapSaved (Result String ())
    | ToggleMapFullscreen
    | SelectMapFormat String -- "svg" or "gif"
    | UpdateGifDelay String -- delay in ms
    | GenerateAnimatedMap
    | AnimatedMapGenerated (Result String String) -- base64 GIF result
    | SaveGif
    | GifSaved (Result String ())


{-| Handle all MapViewer messages.

Returns (Model, Cmd Msg) using this module's own Msg type.
The parent Update.elm uses Cmd.map to wrap commands.

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenMapViewer sessionId year raceName playerNumber ->
            ( { model | dialog = Just (MapViewerDialog (emptyMapViewerForm sessionId year raceName playerNumber)) }
            , Cmd.none
            )

        UpdateMapWidth widthStr ->
            case String.toInt widthStr of
                Just width ->
                    ( updateMapOptions model (\opts -> { opts | width = clamp 400 4096 width })
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        UpdateMapHeight heightStr ->
            case String.toInt heightStr of
                Just height ->
                    ( updateMapOptions model (\opts -> { opts | height = clamp 300 4096 height })
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        SelectMapPreset preset ->
            let
                ( width, height ) =
                    case preset of
                        "800x600" ->
                            ( 800, 600 )

                        "1024x768" ->
                            ( 1024, 768 )

                        "1920x1080" ->
                            ( 1920, 1080 )

                        "2560x1440" ->
                            ( 2560, 1440 )

                        _ ->
                            ( 1024, 768 )
            in
            ( updateMapOptions model (\opts -> { opts | width = width, height = height })
            , Cmd.none
            )

        ToggleShowNames ->
            ( updateMapOptions model (\opts -> { opts | showNames = not opts.showNames })
            , Cmd.none
            )

        ToggleShowFleets ->
            ( updateMapOptions model (\opts -> { opts | showFleets = not opts.showFleets })
            , Cmd.none
            )

        UpdateShowFleetPaths yearsStr ->
            case String.toInt yearsStr of
                Just years ->
                    ( updateMapOptions model (\opts -> { opts | showFleetPaths = clamp 0 10 years })
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        ToggleShowMines ->
            ( updateMapOptions model (\opts -> { opts | showMines = not opts.showMines })
            , Cmd.none
            )

        ToggleShowWormholes ->
            ( updateMapOptions model (\opts -> { opts | showWormholes = not opts.showWormholes })
            , Cmd.none
            )

        ToggleShowLegend ->
            ( updateMapOptions model (\opts -> { opts | showLegend = not opts.showLegend })
            , Cmd.none
            )

        ToggleShowScannerCoverage ->
            ( updateMapOptions model (\opts -> { opts | showScannerCoverage = not opts.showScannerCoverage })
            , Cmd.none
            )

        ToggleMapFullscreen ->
            ( model, Ports.requestFullscreen "map-viewer-frame" )

        SelectMapFormat formatStr ->
            let
                format =
                    if formatStr == "gif" then
                        GIFFormat

                    else
                        SVGFormat
            in
            ( updateMapOptions model (\opts -> { opts | outputFormat = format })
                |> clearMapContent
            , Cmd.none
            )

        UpdateGifDelay delayStr ->
            case String.toInt delayStr of
                Just delay ->
                    ( updateMapOptions model (\opts -> { opts | gifDelay = clamp 100 2000 delay })
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        GenerateMap ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case model.selectedServerUrl of
                        Just serverUrl ->
                            let
                                serverData =
                                    getServerData serverUrl model.serverData

                                maybeTurnFiles =
                                    Dict.get form.sessionId serverData.sessionTurns
                                        |> Maybe.andThen (Dict.get form.year)
                            in
                            case maybeTurnFiles of
                                Just turnFiles ->
                                    ( { model | dialog = Just (MapViewerDialog { form | generating = True, error = Nothing }) }
                                    , Ports.generateMap (Encode.generateMap serverUrl form.sessionId form.year form.options turnFiles)
                                    )

                                Nothing ->
                                    ( { model | dialog = Just (MapViewerDialog { form | error = Just "Turn files not available. Please open the Turn Files dialog first." }) }
                                    , Cmd.none
                                    )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        MapGenerated result ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case result of
                        Ok svg ->
                            ( { model | dialog = Just (MapViewerDialog { form | generatedSvg = Just svg, generating = False }) }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model | dialog = Just (MapViewerDialog { form | error = Just err, generating = False }) }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none )

        SaveMap ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case ( model.selectedServerUrl, form.generatedSvg ) of
                        ( Just serverUrl, Just svg ) ->
                            ( { model | dialog = Just (MapViewerDialog { form | saving = True }) }
                            , Ports.saveMap (Encode.saveMap serverUrl form.sessionId form.year form.raceName form.playerNumber svg)
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        MapSaved result ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case result of
                        Ok () ->
                            ( { model | dialog = Just (MapViewerDialog { form | saving = False }) }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model | dialog = Just (MapViewerDialog { form | error = Just err, saving = False }) }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none )

        GenerateAnimatedMap ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case model.selectedServerUrl of
                        Just serverUrl ->
                            ( { model | dialog = Just (MapViewerDialog { form | generatingGif = True, error = Nothing, generatedGif = Nothing }) }
                            , Ports.generateAnimatedMap (Encode.generateAnimatedMap serverUrl form.sessionId form.options)
                            )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AnimatedMapGenerated result ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case result of
                        Ok gifB64 ->
                            ( { model | dialog = Just (MapViewerDialog { form | generatedGif = Just gifB64, generatingGif = False, generatedSvg = Nothing }) }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model | dialog = Just (MapViewerDialog { form | error = Just err, generatingGif = False }) }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none )

        SaveGif ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case ( model.selectedServerUrl, form.generatedGif ) of
                        ( Just serverUrl, Just gifB64 ) ->
                            ( { model | dialog = Just (MapViewerDialog { form | saving = True }) }
                            , Ports.saveGif (Encode.saveGif serverUrl form.sessionId form.raceName form.playerNumber gifB64)
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GifSaved result ->
            case model.dialog of
                Just (MapViewerDialog form) ->
                    case result of
                        Ok () ->
                            ( { model | dialog = Just (MapViewerDialog { form | saving = False }) }
                            , Cmd.none
                            )

                        Err err ->
                            ( { model | dialog = Just (MapViewerDialog { form | error = Just err, saving = False }) }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none )
