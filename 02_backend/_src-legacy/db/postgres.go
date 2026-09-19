package db

import (
	"bookforge-go-backend/_src-legacy/common/errors"
	"bookforge-go-backend/_src-legacy/config"
	"bookforge-go-backend/_src-legacy/messages"
	"fmt"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog/log"
)

func CreatePostgresConnection(config config.Configuration) (*sqlx.DB, error) {
	url := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.PostgresDB.Host, config.PostgresDB.Port, config.PostgresDB.User,
		config.PostgresDB.Pass, config.PostgresDB.Database, config.PostgresDB.SslMode)

	db, err := sqlx.Connect("postgres", url)
	err = errors.Wrap(err)
	if errors.Cause(err) != nil {
		log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.FailedToConnectToPostgresDbMsg, errors.StackTrace(err)))
		return nil, err
	} else {
		err = errors.Wrap(db.Ping())
		if errors.Cause(err) != nil {
			log.Error().Err(err).Msg(fmt.Sprintf("%s\n%s", messages.UnavailablePostgresDbMsg, errors.StackTrace(err)))
			return nil, err
		} else {
			log.Debug().Msg(fmt.Sprintf(messages.PostgresAvailableConnectedMsg, config.PostgresDB.Host, config.PostgresDB.Database))
		}
	}
	return db, nil
}
