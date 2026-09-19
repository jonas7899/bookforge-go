package handlers

import (
	"bookforge-go-backend/_src-legacy/api/model"
	"bookforge-go-backend/_src-legacy/common/errors"
	"bookforge-go-backend/_src-legacy/config"
	"bookforge-go-backend/_src-legacy/messages"
	"encoding/json"
	"fmt"
	"io/ioutil"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type HealthHandler interface {
	GetHealth(c *gin.Context)
}

type healthHandler struct {
	config *config.Configuration
}

type BuildInfoStruct struct {
	BuildId       string `json:"buildId"`
	BuildNr       string `json:"buildNr"`
	SourceVersion string `json:"sourceVersion"`
}

func (h *healthHandler) GetHealth(c *gin.Context) {
	defaultInfo := model.HealthCheck{
		Service:    "bookforge",
		Status:     "running",
		ApiVersion: []string{"v1"},
	}

	data, err := ioutil.ReadFile(h.config.BuildinfoPath)
	err = errors.Wrap(err)
	if errors.Cause(err) != nil {
		msg := fmt.Sprintf(messages.HandlerFailedToReadInfoFileMsg, h.config.BuildinfoPath)
		log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", msg, errors.StackTrace(err)))
		c.JSON(200, defaultInfo)
	} else {
		var buildInfo BuildInfoStruct
		err = errors.Wrap(json.Unmarshal(data, &buildInfo))
		if errors.Cause(err) != nil {
			msg := fmt.Sprintf(messages.HandlerFailedToReadInfoFileMsg, h.config.BuildinfoPath)
			log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", msg, errors.StackTrace(err)))
			c.JSON(200, defaultInfo)
		}

		c.JSON(200, buildInfo)
	}
}

func CreateHealthHandler(conf *config.Configuration) HealthHandler {
	return &healthHandler{
		config: conf,
	}
}
