module Api.UserProfile exposing (UserProfile)

{-| UserProfile type definition.

Represents a user profile on a Neper server.

-}


{-| A user profile.
-}
type alias UserProfile =
    { id : String
    , nickname : String
    , email : String
    , isActive : Bool
    , isManager : Bool
    , message : Maybe String -- Registration message (for pending users)
    }
