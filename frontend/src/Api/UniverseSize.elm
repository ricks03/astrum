module Api.UniverseSize exposing
    ( UniverseSize(..)
    , all
    , fromInt
    , toInt
    , toString
    )

{-| Universe size for Stars! game rules.

Determines the size of the galaxy in light years.

-}


{-| Universe size options.
-}
type UniverseSize
    = Tiny
    | Small
    | Medium
    | Large
    | Huge


{-| All universe sizes in order.
-}
all : List UniverseSize
all =
    [ Tiny
    , Small
    , Medium
    , Large
    , Huge
    ]


{-| Convert to integer for API/encoding.
-}
toInt : UniverseSize -> Int
toInt size =
    case size of
        Tiny ->
            0

        Small ->
            1

        Medium ->
            2

        Large ->
            3

        Huge ->
            4


{-| Convert from integer (from API/decoding).
-}
fromInt : Int -> Maybe UniverseSize
fromInt n =
    case n of
        0 ->
            Just Tiny

        1 ->
            Just Small

        2 ->
            Just Medium

        3 ->
            Just Large

        4 ->
            Just Huge

        _ ->
            Nothing


{-| Human-readable string for display with dimensions.
-}
toString : UniverseSize -> String
toString size =
    case size of
        Tiny ->
            "Tiny (400 ly)"

        Small ->
            "Small (800 ly)"

        Medium ->
            "Medium (1200 ly)"

        Large ->
            "Large (1600 ly)"

        Huge ->
            "Huge (2000 ly)"
