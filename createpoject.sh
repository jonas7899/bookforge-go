go mod init bookforge-go-backend
go get github.com/rs/zerolog/log
go get github.com/gin-gonic/gin
go get github.com/jmoiron/sqlx
go get github.com/kelseyhightower/envconfig
go get github.com/lib/pq
go get github.com/google/uuid
go mod tidy

sudo apt install sql-migrate