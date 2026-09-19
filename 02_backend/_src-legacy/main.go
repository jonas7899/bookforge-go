package main

import (
	"bookforge-go-backend/_src-legacy/api"
	"bookforge-go-backend/_src-legacy/api/handlers"
	"bookforge-go-backend/_src-legacy/common/errors"
	"bookforge-go-backend/_src-legacy/config"
	"bookforge-go-backend/_src-legacy/db"
	"bookforge-go-backend/_src-legacy/logger"
	"bookforge-go-backend/_src-legacy/messages"
	"fmt"

	"github.com/rs/zerolog/log"
)

func main() {
	config, err := config.ReadConfiguration()
	err = errors.Wrap(err)
	if errors.Cause(err) != nil {
		log.Panic().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.FailedToReadConfigurationMsg, errors.StackTrace(err)))
	}

	logger.ConfigureLogger(config)

	db, err := db.CreatePostgresConnection(config)
	err = errors.Wrap(err)
	if errors.Cause(err) != nil {
		log.Panic().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.FailedToConnectToPostgresDbMsg, errors.StackTrace(err)))
	}
	healthHandler := handlers.CreateHealthHandler(&config)

	api := api.CreateApi(&config, &healthHandler)
	api.RunAPI()
	db.Close()
}
