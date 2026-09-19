package main

import (
	"docstore/src/api"
	"docstore/src/api/handlers"
	"docstore/src/common/errors"
	"docstore/src/config"
	"docstore/src/db"
	"docstore/src/logger"
	"docstore/src/messages"
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
