package logger

import (
	"bookforge-go-backend/_src-legacy/config"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

//panic (zerolog.PanicLevel, 5)
//fatal (zerolog.FatalLevel, 4)
//error (zerolog.ErrorLevel, 3)
//warn (zerolog.WarnLevel, 2)
//info (zerolog.InfoLevel, 1)
//debug (zerolog.DebugLevel, 0)
//trace (zerolog.TraceLevel, -1)

func ConfigureLogger(config config.Configuration) {
	zerolog.SetGlobalLevel(zerolog.Level(config.LogLevel))
	consoleWriter := zerolog.NewConsoleWriter()
	consoleWriter.TimeFormat = "2006-01-02T15:04:05Z07:00"
	if config.LogCallerInfo {
		log.Logger = zerolog.New(consoleWriter).With().Stack().Timestamp().Caller().Logger()
	} else {
		log.Logger = zerolog.New(consoleWriter).With().Stack().Timestamp().Logger()
	}
}
