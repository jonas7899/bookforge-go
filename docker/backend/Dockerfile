# syntax=docker/dockerfile:1.4
# docker/backend/Dockerfile

FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# GitHub Access Token beállítások
ARG GITHUB_TOKEN
RUN git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"

# GOPRIVATE is kell
ENV GOPRIVATE=github.com/jonas7899/*
ENV GONOSUMDB=github.com/jonas7899/*
ENV GONOPROXY=github.com/jonas7899/*

COPY go.mod go.sum ./
COPY 04_common ../04_common/

# Private module letöltés Tokennel
RUN go mod download && rm -rf /go/pkg/mod/cache/vcs

# Most jöhet a teljes source
COPY 02_backend .

RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  rm -rf /go/pkg/mod/cache/vcs && \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app ./cmd/api

RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o seed ./cmd/seed

# Final stage
FROM alpine:latest
RUN apk add --no-cache ca-certificates wget
WORKDIR /app
COPY --from=builder /app/app .
COPY --from=builder /app/seed .
USER nobody:nobody
CMD ["./app"]