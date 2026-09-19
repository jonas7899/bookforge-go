# syntax=docker/dockerfile:1.4
# docker/frontend/Dockerfile
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# GitHub Access Token beállítások
ARG GITHUB_TOKEN
RUN git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"

# GOPRIVATE beállítások
ENV GOPRIVATE=github.com/jonas7899/*
ENV GONOSUMDB=github.com/jonas7899/*
ENV GONOPROXY=github.com/jonas7899/*

COPY 03_frontend_htmx/go.mod 03_frontend_htmx/go.sum ./
# Token miatt már nem kell SSH mount
COPY 04_common ../04_common/
RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  go mod download && rm -rf /go/pkg/mod/cache/vcs

COPY 03_frontend_htmx .

RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app ./cmd/server

# Final stage
FROM alpine:latest
RUN apk add --no-cache ca-certificates wget
WORKDIR /app
COPY --from=builder /app/app .
COPY --from=builder /app/templates ./templates/
COPY --from=builder /app/static ./static/
USER nobody:nobody
CMD ["./app"]