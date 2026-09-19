package model

type HealthCheck struct {
	Service    string   `json:"service"`
	Status     string   `json:"status"`
	ApiVersion []string `json:"apiVersion"`
}
