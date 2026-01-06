module Api.PRT exposing
    ( PRT(..)
    , fromInt
    , toInt
    )

{-| Primary Racial Traits (PRT) for Stars! races.

Each race has exactly one PRT that defines its core characteristics.

-}


{-| Primary Racial Trait.
-}
type PRT
    = HyperExpansion
    | SuperStealth
    | WarMonger
    | ClaimAdjuster
    | InnerStrength
    | SpaceDemolition
    | PacketPhysics
    | InterstellarTraveler
    | AlternateReality
    | JackOfAllTrades


{-| Convert a PRT to its API integer index.
-}
toInt : PRT -> Int
toInt prt =
    case prt of
        HyperExpansion ->
            0

        SuperStealth ->
            1

        WarMonger ->
            2

        ClaimAdjuster ->
            3

        InnerStrength ->
            4

        SpaceDemolition ->
            5

        PacketPhysics ->
            6

        InterstellarTraveler ->
            7

        AlternateReality ->
            8

        JackOfAllTrades ->
            9


{-| Parse an integer to a PRT. Returns Nothing for invalid values.
-}
fromInt : Int -> Maybe PRT
fromInt n =
    case n of
        0 ->
            Just HyperExpansion

        1 ->
            Just SuperStealth

        2 ->
            Just WarMonger

        3 ->
            Just ClaimAdjuster

        4 ->
            Just InnerStrength

        5 ->
            Just SpaceDemolition

        6 ->
            Just PacketPhysics

        7 ->
            Just InterstellarTraveler

        8 ->
            Just AlternateReality

        9 ->
            Just JackOfAllTrades

        _ ->
            Nothing
