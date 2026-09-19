# Stage 1: build goose from source
FROM golang:1.24-alpine AS builder
RUN go install github.com/pressly/goose/v3/cmd/goose@v3.24.1

# Stage 2: tiny runtime
FROM alpine:3.20
COPY --from=builder /go/bin/goose /usr/local/bin/goose
ENTRYPOINT ["goose"]