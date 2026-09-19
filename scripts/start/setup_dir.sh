#!/bin/bash

# Bookforge - Project Setup Script
# This script initializes the project with git submodules and dependencies

set -e  # Exit on error

# Create directory structure
DIRECTORIES=(
"01_docs/01_specs/"
"01_docs/02_design/"
"01_docs/03_manuals/"
"01_docs/04_project_log/"
"02_backend/cmd/api/"
"02_backend/internal/api/"
"02_backend/internal/models/"
"02_backend/internal/repositories/"
"02_backend/internal/services/"
"02_backend/internal/middleware/"
"02_backend/internal/database/"
"02_backend/migrations/"
"03_frontend_htmx/handlers/"
"03_frontend_htmx/templates/"
"03_frontend_htmx/static/css/"
"03_frontend_htmx/static/js/"
"03_frontend_htmx/middleware/"
"04_common/config-go/"
"04_common/logger-go/"
"04_common/shared/"
"05_config"
)
for dir in "${DIRECTORIES[@]}"; do
    # Create directory
    mkdir -p "$dir"
    # add a placeholder file
    touch "${dir}.gitkeep"
done

touch "02_backend/cmd/api/main.go"
touch "02_backend/go.mod"
touch "02_backend/go.sum"
touch "03_frontend_htmx/go.mod"
touch "03_frontend_htmx/go.sum"
touch "05_config/config.dev.yaml"
touch "05_config/config.prod.yaml"
touch "05_config/env.example"

touch "01_docs/01_specs/01_kovetelmeny_specifikacio.md"
touch "01_docs/04_project_log/01_projektnaplo.md"
touch "docker-compose.yml"
touch "Makefile"
touch ".gitignore"
touch ".gitmodules"
touch "README.md"
touch "INSTALL_INSTRUCTIONS.md"
touch "STEP_0_SUMMARY.md"
