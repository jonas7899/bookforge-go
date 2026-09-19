package api

import (
	"bookforge-go-backend/_src-legacy/api/handlers"
	"bookforge-go-backend/_src-legacy/common/errors"
	"bookforge-go-backend/_src-legacy/config"
	"bookforge-go-backend/_src-legacy/messages"
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type Api interface {
	RunAPI()
}

type api struct {
	config        *config.Configuration
	healthHandler *handlers.HealthHandler
}

func (api *api) RunAPI() {
	if api.config.Development {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	engine := gin.New()
	engine.Use(gin.Recovery())

	var (
		err error
	)

	root := engine.Group("")
	root.GET("/health", (*api.healthHandler).GetHealth)

	v1Group := root.Group("v1")
	v1Group.GET("/")

	log.Info().Msg(messages.ApiStartMsg)
	if api.config.EnableTLS {
		err = engine.RunTLS(fmt.Sprintf("bookforge:%d", api.config.APIPort), api.config.CertPath, api.config.KeyPath)
	} else {
		err = engine.Run(fmt.Sprintf(":%d", api.config.APIPort))
	}
	if err != nil {
		err = errors.New(err.Error())
		log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.ApiFailedToStartMsg, errors.StackTrace(err)))
		return
	}
	log.Info().Msg(messages.ApiEndedGracefullyMsg)

}

func CreateApi(config *config.Configuration, healthHandler *handlers.HealthHandler) Api {
	return &api{
		config:        config,
		healthHandler: healthHandler,
	}
}
