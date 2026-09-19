package main

import (
	appconfig "bookforge-go-common/config"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
)

type healthResponse struct {
	Service string   `json:"service"`
	Status  string   `json:"status"`
	API     []string `json:"apiVersion"`
}

func main() {
	cfg := appconfig.AppConfig{Name: "bookforge", Environment: "development"}
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}
	router := chi.NewRouter()
	router.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(healthResponse{
			Service: cfg.Name,
			Status:  "running",
			API:     []string{"v1"},
		})
	})

	address := ":" + port
	log.Println("Bookforge backend listening on " + address)
	log.Fatal(http.ListenAndServe(address, router))
}
