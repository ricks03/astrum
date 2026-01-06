module Update.Rules exposing
    ( Msg(..)
    , update
    )

{-| Update handlers for rules dialog messages.

Handles rules dialog and all rule field updates.

-}

import Api.Encode as Encode
import Api.Rules exposing (Rules)
import Dict
import Model exposing (..)
import Ports
import Update.Helpers exposing (updateRules, updateRulesForm)


{-| Rules-specific messages.
-}
type Msg
    = OpenRulesDialog String Bool -- sessionId, rulesIsSet
    | GotRules String String (Result String Rules) -- serverUrl, sessionId, result
    | UpdateRulesUniverseSize Int
    | UpdateRulesDensity Int
    | UpdateRulesStartingDistance Int
    | UpdateRulesMaximumMinerals Bool
    | UpdateRulesSlowerTechAdvances Bool
    | UpdateRulesAcceleratedBbsPlay Bool
    | UpdateRulesNoRandomEvents Bool
    | UpdateRulesComputerPlayersFormAlliances Bool
    | UpdateRulesPublicPlayerScores Bool
    | UpdateRulesGalaxyClumping Bool
    | UpdateRulesVcOwnsPercentOfPlanets Bool
    | UpdateRulesVcOwnsPercentOfPlanetsValue String
    | UpdateRulesVcAttainTechInFields Bool
    | UpdateRulesVcAttainTechInFieldsTechValue String
    | UpdateRulesVcAttainTechInFieldsFieldsValue String
    | UpdateRulesVcExceedScoreOf Bool
    | UpdateRulesVcExceedScoreOfValue String
    | UpdateRulesVcExceedNextPlayerScoreBy Bool
    | UpdateRulesVcExceedNextPlayerScoreByValue String
    | UpdateRulesVcHasProductionCapacityOf Bool
    | UpdateRulesVcHasProductionCapacityOfValue String
    | UpdateRulesVcOwnsCapitalShips Bool
    | UpdateRulesVcOwnsCapitalShipsValue String
    | UpdateRulesVcHaveHighestScoreAfterYears Bool
    | UpdateRulesVcHaveHighestScoreAfterYearsValue String
    | UpdateRulesVcWinnerMustMeet String
    | UpdateRulesVcMinYearsBeforeWinner String
    | SubmitRules
    | RulesSet String (Result String Rules) -- serverUrl, result


{-| Handle all Rules messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenRulesDialog sessionId rulesIsSet ->
            handleOpenRulesDialog model sessionId rulesIsSet

        GotRules serverUrl sessionId result ->
            handleGotRules model serverUrl sessionId result

        UpdateRulesUniverseSize val ->
            handleUpdateRulesUniverseSize model val

        UpdateRulesDensity val ->
            handleUpdateRulesDensity model val

        UpdateRulesStartingDistance val ->
            handleUpdateRulesStartingDistance model val

        UpdateRulesMaximumMinerals val ->
            handleUpdateRulesMaximumMinerals model val

        UpdateRulesSlowerTechAdvances val ->
            handleUpdateRulesSlowerTechAdvances model val

        UpdateRulesAcceleratedBbsPlay val ->
            handleUpdateRulesAcceleratedBbsPlay model val

        UpdateRulesNoRandomEvents val ->
            handleUpdateRulesNoRandomEvents model val

        UpdateRulesComputerPlayersFormAlliances val ->
            handleUpdateRulesComputerPlayersFormAlliances model val

        UpdateRulesPublicPlayerScores val ->
            handleUpdateRulesPublicPlayerScores model val

        UpdateRulesGalaxyClumping val ->
            handleUpdateRulesGalaxyClumping model val

        UpdateRulesVcOwnsPercentOfPlanets val ->
            handleUpdateRulesVcOwnsPercentOfPlanets model val

        UpdateRulesVcOwnsPercentOfPlanetsValue val ->
            handleUpdateRulesVcOwnsPercentOfPlanetsValue model val

        UpdateRulesVcAttainTechInFields val ->
            handleUpdateRulesVcAttainTechInFields model val

        UpdateRulesVcAttainTechInFieldsTechValue val ->
            handleUpdateRulesVcAttainTechInFieldsTechValue model val

        UpdateRulesVcAttainTechInFieldsFieldsValue val ->
            handleUpdateRulesVcAttainTechInFieldsFieldsValue model val

        UpdateRulesVcExceedScoreOf val ->
            handleUpdateRulesVcExceedScoreOf model val

        UpdateRulesVcExceedScoreOfValue val ->
            handleUpdateRulesVcExceedScoreOfValue model val

        UpdateRulesVcExceedNextPlayerScoreBy val ->
            handleUpdateRulesVcExceedNextPlayerScoreBy model val

        UpdateRulesVcExceedNextPlayerScoreByValue val ->
            handleUpdateRulesVcExceedNextPlayerScoreByValue model val

        UpdateRulesVcHasProductionCapacityOf val ->
            handleUpdateRulesVcHasProductionCapacityOf model val

        UpdateRulesVcHasProductionCapacityOfValue val ->
            handleUpdateRulesVcHasProductionCapacityOfValue model val

        UpdateRulesVcOwnsCapitalShips val ->
            handleUpdateRulesVcOwnsCapitalShips model val

        UpdateRulesVcOwnsCapitalShipsValue val ->
            handleUpdateRulesVcOwnsCapitalShipsValue model val

        UpdateRulesVcHaveHighestScoreAfterYears val ->
            handleUpdateRulesVcHaveHighestScoreAfterYears model val

        UpdateRulesVcHaveHighestScoreAfterYearsValue val ->
            handleUpdateRulesVcHaveHighestScoreAfterYearsValue model val

        UpdateRulesVcWinnerMustMeet val ->
            handleUpdateRulesVcWinnerMustMeet model val

        UpdateRulesVcMinYearsBeforeWinner val ->
            handleUpdateRulesVcMinYearsBeforeWinner model val

        SubmitRules ->
            handleSubmitRules model

        RulesSet serverUrl result ->
            handleRulesSet model serverUrl result



-- =============================================================================
-- RULES DIALOG
-- =============================================================================


{-| Open rules dialog.
-}
handleOpenRulesDialog : Model -> String -> Bool -> ( Model, Cmd Msg )
handleOpenRulesDialog model sessionId rulesIsSet =
    case model.selectedServerUrl of
        Just serverUrl ->
            let
                currentData =
                    getServerData serverUrl model.serverData

                currentUserId =
                    case currentData.connectionState of
                        Connected info ->
                            Just info.userId

                        _ ->
                            Nothing

                isManager =
                    case ( currentUserId, getSessionById sessionId currentData.sessions ) of
                        ( Just userId, Just session ) ->
                            List.member userId session.managers

                        _ ->
                            False

                cachedRules =
                    Dict.get sessionId currentData.sessionRules

                ( initialForm, cmd ) =
                    case ( rulesIsSet, cachedRules ) of
                        ( True, Just rules ) ->
                            ( { sessionId = sessionId
                              , rules = rules
                              , isManager = isManager
                              , error = Nothing
                              , submitting = False
                              , loading = False
                              }
                            , Cmd.none
                            )

                        ( True, Nothing ) ->
                            ( { sessionId = sessionId
                              , rules = Api.Rules.defaultRules
                              , isManager = isManager
                              , error = Nothing
                              , submitting = False
                              , loading = True
                              }
                            , Ports.getRules (Encode.getRules serverUrl sessionId)
                            )

                        ( False, _ ) ->
                            ( { sessionId = sessionId
                              , rules = Api.Rules.defaultRules
                              , isManager = isManager
                              , error = Nothing
                              , submitting = False
                              , loading = False
                              }
                            , Cmd.none
                            )
            in
            ( { model | dialog = Just (RulesDialog initialForm) }
            , cmd
            )

        Nothing ->
            ( model, Cmd.none )


{-| Handle rules result.
-}
handleGotRules : Model -> String -> String -> Result String Rules -> ( Model, Cmd Msg )
handleGotRules model serverUrl sessionId result =
    case result of
        Ok rules ->
            ( { model
                | dialog =
                    case model.dialog of
                        Just (RulesDialog form) ->
                            Just (RulesDialog { form | rules = rules, loading = False })

                        other ->
                            other
                , serverData =
                    updateServerData serverUrl
                        (\sd ->
                            { sd
                                | sessionRules =
                                    Dict.insert sessionId rules sd.sessionRules
                            }
                        )
                        model.serverData
              }
            , Cmd.none
            )

        Err err ->
            ( updateRulesForm model (\f -> { f | error = Just err, loading = False })
            , Cmd.none
            )


{-| Submit rules.
-}
handleSubmitRules : Model -> ( Model, Cmd Msg )
handleSubmitRules model =
    case model.dialog of
        Just (RulesDialog form) ->
            case model.selectedServerUrl of
                Just serverUrl ->
                    ( updateRulesForm model (\f -> { f | submitting = True, error = Nothing })
                    , Ports.setRules (Encode.setRules serverUrl form.sessionId form.rules)
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Handle rules set result.
-}
handleRulesSet : Model -> String -> Result String Rules -> ( Model, Cmd Msg )
handleRulesSet model serverUrl result =
    case ( result, model.dialog ) of
        ( Ok rules, Just (RulesDialog form) ) ->
            ( { model
                | dialog = Nothing
                , serverData =
                    updateServerData serverUrl
                        (\sd ->
                            { sd
                                | sessionRules =
                                    Dict.insert form.sessionId rules sd.sessionRules
                            }
                        )
                        model.serverData
              }
            , Ports.getSession (Encode.getSession serverUrl form.sessionId)
            )

        ( Ok _, _ ) ->
            ( { model | dialog = Nothing }
            , Cmd.none
            )

        ( Err err, _ ) ->
            ( updateRulesForm model (\f -> { f | submitting = False, error = Just err })
            , Cmd.none
            )



-- =============================================================================
-- UNIVERSE CONFIGURATION
-- =============================================================================


handleUpdateRulesUniverseSize : Model -> Int -> ( Model, Cmd Msg )
handleUpdateRulesUniverseSize model val =
    ( updateRules model (\r -> { r | universeSize = val }), Cmd.none )


handleUpdateRulesDensity : Model -> Int -> ( Model, Cmd Msg )
handleUpdateRulesDensity model val =
    ( updateRules model (\r -> { r | density = val }), Cmd.none )


handleUpdateRulesStartingDistance : Model -> Int -> ( Model, Cmd Msg )
handleUpdateRulesStartingDistance model val =
    ( updateRules model (\r -> { r | startingDistance = val }), Cmd.none )



-- =============================================================================
-- GAME OPTIONS
-- =============================================================================


handleUpdateRulesMaximumMinerals : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesMaximumMinerals model val =
    ( updateRules model (\r -> { r | maximumMinerals = val }), Cmd.none )


handleUpdateRulesSlowerTechAdvances : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesSlowerTechAdvances model val =
    ( updateRules model (\r -> { r | slowerTechAdvances = val }), Cmd.none )


handleUpdateRulesAcceleratedBbsPlay : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesAcceleratedBbsPlay model val =
    ( updateRules model (\r -> { r | acceleratedBbsPlay = val }), Cmd.none )


handleUpdateRulesNoRandomEvents : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesNoRandomEvents model val =
    ( updateRules model (\r -> { r | noRandomEvents = val }), Cmd.none )


handleUpdateRulesComputerPlayersFormAlliances : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesComputerPlayersFormAlliances model val =
    ( updateRules model (\r -> { r | computerPlayersFormAlliances = val }), Cmd.none )


handleUpdateRulesPublicPlayerScores : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesPublicPlayerScores model val =
    ( updateRules model (\r -> { r | publicPlayerScores = val }), Cmd.none )


handleUpdateRulesGalaxyClumping : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesGalaxyClumping model val =
    ( updateRules model (\r -> { r | galaxyClumping = val }), Cmd.none )



-- =============================================================================
-- VICTORY CONDITIONS
-- =============================================================================


handleUpdateRulesVcOwnsPercentOfPlanets : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcOwnsPercentOfPlanets model val =
    ( updateRules model (\r -> { r | vcOwnsPercentOfPlanets = val }), Cmd.none )


handleUpdateRulesVcOwnsPercentOfPlanetsValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcOwnsPercentOfPlanetsValue model val =
    ( updateRules model (\r -> { r | vcOwnsPercentOfPlanetsValue = Maybe.withDefault r.vcOwnsPercentOfPlanetsValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcAttainTechInFields : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcAttainTechInFields model val =
    ( updateRules model (\r -> { r | vcAttainTechInFields = val }), Cmd.none )


handleUpdateRulesVcAttainTechInFieldsTechValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcAttainTechInFieldsTechValue model val =
    ( updateRules model (\r -> { r | vcAttainTechInFieldsTechValue = Maybe.withDefault r.vcAttainTechInFieldsTechValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcAttainTechInFieldsFieldsValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcAttainTechInFieldsFieldsValue model val =
    ( updateRules model (\r -> { r | vcAttainTechInFieldsFieldsValue = Maybe.withDefault r.vcAttainTechInFieldsFieldsValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcExceedScoreOf : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcExceedScoreOf model val =
    ( updateRules model (\r -> { r | vcExceedScoreOf = val }), Cmd.none )


handleUpdateRulesVcExceedScoreOfValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcExceedScoreOfValue model val =
    ( updateRules model (\r -> { r | vcExceedScoreOfValue = Maybe.withDefault r.vcExceedScoreOfValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcExceedNextPlayerScoreBy : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcExceedNextPlayerScoreBy model val =
    ( updateRules model (\r -> { r | vcExceedNextPlayerScoreBy = val }), Cmd.none )


handleUpdateRulesVcExceedNextPlayerScoreByValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcExceedNextPlayerScoreByValue model val =
    ( updateRules model (\r -> { r | vcExceedNextPlayerScoreByValue = Maybe.withDefault r.vcExceedNextPlayerScoreByValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcHasProductionCapacityOf : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcHasProductionCapacityOf model val =
    ( updateRules model (\r -> { r | vcHasProductionCapacityOf = val }), Cmd.none )


handleUpdateRulesVcHasProductionCapacityOfValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcHasProductionCapacityOfValue model val =
    ( updateRules model (\r -> { r | vcHasProductionCapacityOfValue = Maybe.withDefault r.vcHasProductionCapacityOfValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcOwnsCapitalShips : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcOwnsCapitalShips model val =
    ( updateRules model (\r -> { r | vcOwnsCapitalShips = val }), Cmd.none )


handleUpdateRulesVcOwnsCapitalShipsValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcOwnsCapitalShipsValue model val =
    ( updateRules model (\r -> { r | vcOwnsCapitalShipsValue = Maybe.withDefault r.vcOwnsCapitalShipsValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcHaveHighestScoreAfterYears : Model -> Bool -> ( Model, Cmd Msg )
handleUpdateRulesVcHaveHighestScoreAfterYears model val =
    ( updateRules model (\r -> { r | vcHaveHighestScoreAfterYears = val }), Cmd.none )


handleUpdateRulesVcHaveHighestScoreAfterYearsValue : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcHaveHighestScoreAfterYearsValue model val =
    ( updateRules model (\r -> { r | vcHaveHighestScoreAfterYearsValue = Maybe.withDefault r.vcHaveHighestScoreAfterYearsValue (String.toInt val) }), Cmd.none )


handleUpdateRulesVcWinnerMustMeet : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcWinnerMustMeet model val =
    ( updateRules model (\r -> { r | vcWinnerMustMeet = Maybe.withDefault r.vcWinnerMustMeet (String.toInt val) }), Cmd.none )


handleUpdateRulesVcMinYearsBeforeWinner : Model -> String -> ( Model, Cmd Msg )
handleUpdateRulesVcMinYearsBeforeWinner model val =
    ( updateRules model (\r -> { r | vcMinYearsBeforeWinner = Maybe.withDefault r.vcMinYearsBeforeWinner (String.toInt val) }), Cmd.none )
