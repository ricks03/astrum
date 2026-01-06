module Api.StartingDistance exposing
    ( StartingDistance(..)
    , all
    , fromInt
    , toInt
    , toString
    )

{-| Starting distance between players for Stars! game rules.

Determines how far apart player homeworlds are placed.

-}


{-| Starting distance options.
-}
type StartingDistance
    = Close
    | Moderate
    | Farther
    | Distant


{-| All starting distance options in order.
-}
all : List StartingDistance
all =
    [ Close
    , Moderate
    , Farther
    , Distant
    ]


{-| Convert to integer for API/encoding.
-}
toInt : StartingDistance -> Int
toInt distance =
    case distance of
        Close ->
            0

        Moderate ->
            1

        Farther ->
            2

        Distant ->
            3


{-| Convert from integer (from API/decoding).
-}
fromInt : Int -> Maybe StartingDistance
fromInt n =
    case n of
        0 ->
            Just Close

        1 ->
            Just Moderate

        2 ->
            Just Farther

        3 ->
            Just Distant

        _ ->
            Nothing


{-| Human-readable string for display.
-}
toString : StartingDistance -> String
toString distance =
    case distance of
        Close ->
            "Close"

        Moderate ->
            "Moderate"

        Farther ->
            "Farther"

        Distant ->
            "Distant"
