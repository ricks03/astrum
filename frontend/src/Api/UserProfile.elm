module Api.UserProfile exposing (UserProfile, UserProfileState(..))

{-| UserProfile type definition.

Represents a user profile on a Neper server.

-}


{-| User profile state.
-}
type UserProfileState
    = Pending
    | Active
    | Inactive


{-| A user profile.
-}
type alias UserProfile =
    { id : String
    , nickname : String
    , email : String
    , state : UserProfileState
    , isManager : Bool
    , message : Maybe String -- Registration message (for pending users)
    }
