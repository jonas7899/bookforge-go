package messages

const (
	ApiStartMsg           = "API server bookforge has been started"
	ApiEndedGracefullyMsg = "API server bookforge ended gracefully"
	ApiFailedToStartMsg   = "Failed to start API server bookforge"

	InvalidTokenMsg = "invalid jwt token"
	ExpiredTokenMsg = "expired jwt token"
	NoPrivilegeMsg  = "user has no privileges to use this route"

	MissingIdParameterMsg = "missing id parameter"
	InvalidIdParameterMsg = "invalid id parameter"

	FailedToLoadJwksMsg = "failed to load jwks from userservice"

	CanNotGetSavedUserFromTokenMsg           = "Can not get saved user from token"
	CanNotParseUserObjectInUserTokenModelMsg = "Can not parse user object in userToken model"
	UserMissingOneOfThisPrivilegesMsg        = "User missing one of this privileges: %v"
	UserMissingPrivilegesMsg                 = "User missing privileges: %v all of these must assign to the user!"

	FailedToReadConfigurationMsg = "Failed to read configuration"

	FailedToConnectToPostgresDbMsg = "Failed to connect to postgres db"
	UnavailablePostgresDbMsg       = "The postgres db is unavailable"
	PostgresAvailableConnectedMsg  = "Postgres available, connected to %s / %s"
	HandlerFailedToReadInfoFileMsg = "Failed to read info file: %s"
)
