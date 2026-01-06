module Api.ResearchLevel exposing
    ( ResearchLevel(..)
    , fromInt
    , toInt
    )

{-| Research cost level for a technology field.

Stars! research can be set to one of three cost levels:

  - Expensive (75% extra cost)
  - Standard (normal cost)
  - Cheap (50% less cost)

-}


{-| Research cost level.
-}
type ResearchLevel
    = Expensive
    | Standard
    | Cheap


{-| Convert to integer for API/encoding.
-}
toInt : ResearchLevel -> Int
toInt level =
    case level of
        Expensive ->
            0

        Standard ->
            1

        Cheap ->
            2


{-| Convert from integer (from API/decoding).
-}
fromInt : Int -> Maybe ResearchLevel
fromInt n =
    case n of
        0 ->
            Just Expensive

        1 ->
            Just Standard

        2 ->
            Just Cheap

        _ ->
            Nothing
