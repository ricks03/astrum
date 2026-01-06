module Api.LeftoverPointsOption exposing
    ( LeftoverPointsOption(..)
    , all
    , fromInt
    , toInt
    , toString
    )

{-| Leftover advantage points allocation for Stars! race builder.

Determines what to spend up to 50 leftover advantage points on.

-}


{-| Leftover points allocation options.
-}
type LeftoverPointsOption
    = SurfaceMinerals
    | MineralConcentrations
    | Mines
    | Factories
    | Defenses


{-| All leftover points options in order.
-}
all : List LeftoverPointsOption
all =
    [ SurfaceMinerals
    , MineralConcentrations
    , Mines
    , Factories
    , Defenses
    ]


{-| Convert to integer for API/encoding.
-}
toInt : LeftoverPointsOption -> Int
toInt option =
    case option of
        SurfaceMinerals ->
            0

        MineralConcentrations ->
            1

        Mines ->
            2

        Factories ->
            3

        Defenses ->
            4


{-| Convert from integer (from API/decoding).
-}
fromInt : Int -> Maybe LeftoverPointsOption
fromInt n =
    case n of
        0 ->
            Just SurfaceMinerals

        1 ->
            Just MineralConcentrations

        2 ->
            Just Mines

        3 ->
            Just Factories

        4 ->
            Just Defenses

        _ ->
            Nothing


{-| Human-readable string for display.
-}
toString : LeftoverPointsOption -> String
toString option =
    case option of
        SurfaceMinerals ->
            "Surface minerals"

        MineralConcentrations ->
            "Mineral concentrations"

        Mines ->
            "Mines"

        Factories ->
            "Factories"

        Defenses ->
            "Defenses"
