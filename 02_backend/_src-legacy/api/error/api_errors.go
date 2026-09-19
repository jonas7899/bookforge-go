package api_errors

import (
	"docstore/src/messages"
	"errors"
)

type HttpError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

var (
	ErrInvalidToken = HttpError{
		Code:    40100,
		Message: messages.InvalidTokenMsg,
	}
	ErrExpiredToken = HttpError{
		Code:    40101,
		Message: messages.InvalidTokenMsg,
	}
	ErrNoPrivileges = HttpError{
		Code:    40102,
		Message: messages.NoPrivilegeMsg,
	}
)

var (
	ErrFailedToLoadJwks = errors.New(messages.FailedToLoadJwksMsg)
)
