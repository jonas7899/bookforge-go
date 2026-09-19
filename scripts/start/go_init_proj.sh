#!/bin/bash

# letelepíti a Go-t és a szükséges csomagokat: go mod
# 

// install go permanently in idx vm
nix-env -iA nixpkgs.go

go mod init bookforge-go-backend
go get github.com/go-chi/chi/v5
go get github.com/jackc/pgx/v5
go get github.com/joho/godotenv
go get github.com/bwmarrin/snowflake
go get github.com/a-h/templ
go get golang.org/x/crypto/bcrypt
go get github.com/alexedwards/scs/v2
go get github.com/alexedwards/scs/postgresstore
go install github.com/pressly/goose/v3/cmd/goose@latest
go get github.com/go-chi/chi/v5
go get github.com/jackc/pgx/v5
go get github.com/joho/godotenv
go get github.com/bwmarrin/snowflake
go get github.com/a-h/templ
go get golang.org/x/crypto/bcrypt
go get github.com/alexedwards/scs/v2
go get github.com/alexedwards/scs/postgresstore
psql "postgres://dev:dev123@localhost:5432/postgres?sslmode=disable" -c "CREATE DATABASE bookforge_dev OWNER user;"
psql "postgres://dev:dev123@localhost:5432/postgres?sslmode=disable" -c 'CREATE DATABASE bookforge_dev OWNER "user";'
go get github.com/jackc/pgx/v5/pgxpool@v5.8.0
go install github.com/a-h/templ/cmd/templ@latest
export PATH=$PATH:$(go env GOPATH)/bin
go mod tidy
go install github.com/air-verse/air@latest
nohup postgres -D .data/postgres > postgres.log 2>&1 &
pg_isready
echo $PGDATA
