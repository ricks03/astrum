module Api.LRT exposing
    ( LRT(..)
    , fromInt
    , toInt
    )

{-| Lesser Racial Traits (LRT) for Stars! races.

Each race can have multiple LRTs that modify its capabilities.
Some LRTs are beneficial (cost advantage points), others are detrimental (give advantage points).

-}


{-| Lesser Racial Trait.
-}
type LRT
    = ImprovedFuelEfficiency
    | TotalTerraforming
    | AdvancedRemoteMining
    | ImprovedStarbases
    | GeneralizedResearch
    | UltimateRecycling
    | MineralAlchemy
    | NoRamScoopEngines
    | CheapEngines
    | OnlyBasicRemoteMining
    | NoAdvancedScanners
    | LowStartingPopulation
    | BleedingEdgeTechnology
    | RegeneratingShields


{-| Convert an LRT to its API integer index.
-}
toInt : LRT -> Int
toInt lrt =
    case lrt of
        ImprovedFuelEfficiency ->
            0

        TotalTerraforming ->
            1

        AdvancedRemoteMining ->
            2

        ImprovedStarbases ->
            3

        GeneralizedResearch ->
            4

        UltimateRecycling ->
            5

        MineralAlchemy ->
            6

        NoRamScoopEngines ->
            7

        CheapEngines ->
            8

        OnlyBasicRemoteMining ->
            9

        NoAdvancedScanners ->
            10

        LowStartingPopulation ->
            11

        BleedingEdgeTechnology ->
            12

        RegeneratingShields ->
            13


{-| Parse an integer to an LRT. Returns Nothing for invalid values.
-}
fromInt : Int -> Maybe LRT
fromInt n =
    case n of
        0 ->
            Just ImprovedFuelEfficiency

        1 ->
            Just TotalTerraforming

        2 ->
            Just AdvancedRemoteMining

        3 ->
            Just ImprovedStarbases

        4 ->
            Just GeneralizedResearch

        5 ->
            Just UltimateRecycling

        6 ->
            Just MineralAlchemy

        7 ->
            Just NoRamScoopEngines

        8 ->
            Just CheapEngines

        9 ->
            Just OnlyBasicRemoteMining

        10 ->
            Just NoAdvancedScanners

        11 ->
            Just LowStartingPopulation

        12 ->
            Just BleedingEdgeTechnology

        13 ->
            Just RegeneratingShields

        _ ->
            Nothing
