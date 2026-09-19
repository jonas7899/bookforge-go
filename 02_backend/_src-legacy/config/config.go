package config

import (
	"docstore/src/common/errors"
	"docstore/src/messages"
	"fmt"

	"github.com/kelseyhightower/envconfig"
	"github.com/rs/zerolog/log"
)

type Configuration struct {
	PostgresDB struct {
		Host     string `envconfig:"DB_SERVER" required:"true" default:"127.0.0.1"`
		Port     uint32 `envconfig:"DB_PORT" required:"true" default:"5432"`
		User     string `envconfig:"DB_USER" required:"true"`
		Pass     string `envconfig:"DB_PASS" required:"true"`
		Database string `envconfig:"DB_DATABASE" required:"true"`
		SslMode  string `envconfig:"DB_SSL_MODE" required:"true" default:"disable"`
	}
	InstrumentSettings struct {
	}
	APIPort                 int    `envconfig:"API_PORT" default:"80"`
	Authorization           bool   `envconfig:"AUTHORIZATION" default:"true"`
	EnableTLS               bool   `envconfig:"ENABLE_TLS" default:"false"`
	CertPath                string `envconfig:"CERT_PATH" default:"../cert.pem"`
	KeyPath                 string `envconfig:"KEY_PATH" default:"../key.pem"`
	CerberusURL             string `envconfig:"CERBERUS_URL" required:"true" default:"localhost"`
	TransferServiceInterval int    `envconfig:"SERVICE_INTERVAL" required:"true" default:"60"`
	TcpListenerPort         uint32 `envconfig:"TCPLISTENERPORT" required:"true" default:"5000"`
	Development             bool   `envconfig:"DEVELOPMENT" default:"false"`
	PermittedOrigin         string `envconfig:"PERMITTED_ORIGIN_URL" default:""`
	UserServiceUrl          string `envconfig:"USER_SERVICE_URL" default:"http://userservice"`
	Verbose                 bool   `envconfig:"VERBOSE" default:"false"`
	TestRunner              bool   `envconfig:"TEST_RUNNER" default:"false"`
	LogLevel                int8   `envconfig:"LOG_LEVEL" default:"-1"`
	LogCallerInfo           bool   `envconfig:"LOG_LEVEL" default:"true"`
	BuildinfoPath           string `envconfig:"BUILDINFO_CERT_PATH" default:"/dist/.buildinfo.json"`
}

var Settings Configuration

func ReadConfiguration() (Configuration, error) {
	var config Configuration
	err := envconfig.Process("", &config)
	err = errors.Wrap(err)
	if errors.Cause(err) != nil {
		log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.FailedToReadConfigurationMsg, errors.StackTrace(err)))
		return config, err
	}
	return config, nil
}
