module Api.Density exposing
    ( Density(..)
    , all
    , fromInt
    , toInt
    , toString
    )

{-| Star density for Stars! game rules.

Determines how many stars are placed in the galaxy.

-}


{-| Density options.
-}
type Density
    = Sparse
    | Normal
    | Dense
    | Packed


{-| All density options in order.
-}
all : List Density
all =
    [ Sparse
    , Normal
    , Dense
    , Packed
    ]


{-| Convert to integer for API/encoding.
-}
toInt : Density -> Int
toInt density =
    case density of
        Sparse ->
            0

        Normal ->
            1

        Dense ->
            2

        Packed ->
            3


{-| Convert from integer (from API/decoding).
-}
fromInt : Int -> Maybe Density
fromInt n =
    case n of
        0 ->
            Just Sparse

        1 ->
            Just Normal

        2 ->
            Just Dense

        3 ->
            Just Packed

        _ ->
            Nothing


{-| Human-readable string for display.
-}
toString : Density -> String
toString density =
    case density of
        Sparse ->
            "Sparse"

        Normal ->
            "Normal"

        Dense ->
            "Dense"

        Packed ->
            "Packed"
