#!/bin/bash
# Bookforge - PostgreSQL Initialization Script
# Reads configuration from environment variables
# Location: scripts/init-db.sh (mounted in docker-compose.yml)
set - e # ============================================
  # CONFIGURATION FROM ENVIRONMENT
  # ============================================
  # Database connection info (provided by PostgreSQL Docker image)
  DB_NAME = "${POSTGRES_DB:-bookforge_dev}" DB_USER = "${POSTGRES_USER:-dev}" DB_PASSWORD = "${POSTGRES_PASSWORD:-dev123}" # Application schema name (custom)
  APP_SCHEMA = "${POSTGRES_SCHEMA:-ai_copywriting}" # ============================================
  # LOGGING
  # ============================================
  log_info() { echo "[INFO] $1" } log_success() { echo "[SUCCESS] ✅ $1" } log_error() { echo "[ERROR] ❌ $1" } # ============================================
  # DATABASE INITIALIZATION
  # ============================================
  log_info "Starting database initialization..." log_info "Database: $DB_NAME" log_info "User: $DB_USER" log_info "Schema: $APP_SCHEMA" # Execute SQL as postgres superuser
  psql - v ON_ERROR_STOP = 1 --username postgres <<-EOSQL
  -- ============================================
  -- EXTENSIONS
  -- ============================================
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
$(log_info "Extensions created") EOSQL # Connect to the application database
psql - v ON_ERROR_STOP = 1 --username postgres --dbname "$DB_NAME" <<-EOSQL
-- ============================================
-- SCHEMA SETUP
-- ============================================
-- Create dedicated schema for the application
CREATE SCHEMA IF NOT EXISTS "$APP_SCHEMA" AUTHORIZATION "$DB_USER";
-- Set default search path for application user
ALTER ROLE "$DB_USER" IN DATABASE "$DB_NAME"
SET search_path = '$APP_SCHEMA',
  public;
-- Set search path for current session
SET search_path = '$APP_SCHEMA',
  public;
$(log_info "Schema '$APP_SCHEMA' created") -- ============================================
-- SECURITY & PERMISSIONS
-- ============================================
-- Revoke all privileges on 'public' schema from PUBLIC
REVOKE ALL ON SCHEMA public
FROM PUBLIC;
-- Grant all privileges on application schema to user
GRANT ALL PRIVILEGES ON SCHEMA $APP_SCHEMA TO "$DB_USER";
-- Grant usage on public schema (for extensions)
GRANT USAGE ON SCHEMA public TO "$DB_USER";
-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA $APP_SCHEMA
GRANT ALL ON TABLES TO "$DB_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA $APP_SCHEMA
GRANT ALL ON SEQUENCES TO "$DB_USER";
ALTER DEFAULT PRIVILEGES IN SCHEMA $APP_SCHEMA
GRANT ALL ON FUNCTIONS TO "$DB_USER";
$(log_info "Permissions granted") -- ============================================
-- DATABASE SETTINGS
-- ============================================
ALTER DATABASE "$DB_NAME"
SET timezone TO 'UTC';
$(log_info "Database settings configured") EOSQL # ============================================
# VERIFICATION
# ============================================
log_info "Verifying setup..." # Check schema exists
SCHEMA_COUNT = $(
  psql - v ON_ERROR_STOP = 1 --username "$DB_USER" --dbname "$DB_NAME" -t -c \
  "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$APP_SCHEMA'"
) if [ "$SCHEMA_COUNT" -eq 1 ];
then log_success "Schema '$APP_SCHEMA' verified"
else log_error "Schema '$APP_SCHEMA' not found!" exit 1 fi # Check search path
SEARCH_PATH = $(
  psql - v ON_ERROR_STOP = 1 --username "$DB_USER" --dbname "$DB_NAME" -t -c "SHOW search_path")
  log_info "Search path: $SEARCH_PATH" # ============================================
  # SUMMARY
  # ============================================
  log_success "Database initialized successfully!" echo "" echo "Configuration:" echo "  Database: $DB_NAME" echo "  User: $DB_USER" echo "  Schema: $APP_SCHEMA" echo "  Search path: $APP_SCHEMA, public" echo "" echo "Next steps:" echo "  1. Run migrations: make migrate-up" echo "  2. Start backend: make run-backend"