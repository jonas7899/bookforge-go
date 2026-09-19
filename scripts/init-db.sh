#!/bin/bash
# Bookforge - PostgreSQL Initialization Script
# Location: scripts/init-db.sh (mounted in docker-compose via docker-entrypoint-initdb.d)
#
# FONTOS: Ez a script csak az ELSŐ inicializáláskor fut le (üres volume).
# POSTGRES_USER lesz a superuser — nincs külön "postgres" role.
# A jelszót psql :'variable' interpolációval kezeljük (speciális karakterek ellen).

set -e

# ============================================
# CONFIGURATION FROM ENVIRONMENT
# ============================================

DB_NAME="${POSTGRES_DB:-bookforge_dev}"
DB_USER="${POSTGRES_USER:-dev}"
DB_PASSWORD="${POSTGRES_PASSWORD:-}"
APP_SCHEMA="${POSTGRES_SCHEMA:-bookforge}"

# ============================================
# LOGGING
# ============================================

log_info()    { echo "[INFO] $1"; }
log_success() { echo "[SUCCESS] ✅ $1"; }
log_error()   { echo "[ERROR] ❌ $1"; }

# ============================================
# STEP 1: Extensions
# ============================================

log_info "Starting database initialization..."
log_info "Database: $DB_NAME | User: $DB_USER | Schema: $APP_SCHEMA"

psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
EOSQL
log_info "Extensions created"

# ============================================
# STEP 2: Security - lock down postgres DB
# ============================================

psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
    REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;
EOSQL
log_info "postgres database locked down"

# ============================================
# STEP 3: Connection limit + jelszó scram-sha-256 hash-sel
#
# Az ALTER USER ... PASSWORD garantálja, hogy a jelszó scram-sha-256
# formátumban legyen eltárolva, ami megfelel a pg_hba.conf beállításnak.
# A :'password' psql interpoláció biztonságosan kezeli a speciális karaktereket
# (@, #, &, stb.) — nem kell kézzel escape-elni.
# ============================================

psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" \
    -v password="$DB_PASSWORD" <<-EOSQL
    ALTER ROLE "$DB_USER" CONNECTION LIMIT 10;
    ALTER ROLE "$DB_USER" WITH PASSWORD :'password';
EOSQL
log_info "Connection limit set and password hash updated (scram-sha-256) for $DB_USER"

# ============================================
# STEP 4: Schema, search path, permissions
# ============================================

psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" <<-EOSQL
    -- Create dedicated schema
    CREATE SCHEMA IF NOT EXISTS "$APP_SCHEMA" AUTHORIZATION "$DB_USER";

    -- Set default search path for application user
    ALTER ROLE "$DB_USER" IN DATABASE "$DB_NAME" SET search_path = '$APP_SCHEMA', public;

    -- Lock down public schema
    REVOKE ALL ON SCHEMA public FROM PUBLIC;

    -- Grant privileges on application schema
    GRANT ALL PRIVILEGES ON SCHEMA "$APP_SCHEMA" TO "$DB_USER";
    GRANT USAGE ON SCHEMA public TO "$DB_USER";

    -- Default privileges for future objects
    ALTER DEFAULT PRIVILEGES IN SCHEMA "$APP_SCHEMA" GRANT ALL ON TABLES TO "$DB_USER";
    ALTER DEFAULT PRIVILEGES IN SCHEMA "$APP_SCHEMA" GRANT ALL ON SEQUENCES TO "$DB_USER";
    ALTER DEFAULT PRIVILEGES IN SCHEMA "$APP_SCHEMA" GRANT ALL ON FUNCTIONS TO "$DB_USER";

    -- Timezone
    ALTER DATABASE "$DB_NAME" SET timezone TO 'UTC';
EOSQL
log_info "Schema, permissions, and settings configured"

# ============================================
# VERIFICATION
# ============================================

log_info "Verifying setup..."

SCHEMA_COUNT=$(psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" -t -c \
    "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$APP_SCHEMA'" | tr -d ' ')

if [ "$SCHEMA_COUNT" -eq 1 ]; then
    log_success "Schema '$APP_SCHEMA' verified"
else
    log_error "Schema '$APP_SCHEMA' not found!"
    exit 1
fi

SEARCH_PATH=$(psql -v ON_ERROR_STOP=1 --username "$DB_USER" --dbname "$DB_NAME" -t -c "SHOW search_path")
log_info "Search path: $SEARCH_PATH"

# ============================================
# SUMMARY
# ============================================

log_success "Database initialized successfully!"
echo ""
echo "  Database:     $DB_NAME"
echo "  User:         $DB_USER (connection limit: 10)"
echo "  Schema:       $APP_SCHEMA"
echo "  Search path:  $APP_SCHEMA, public"
echo "  Timezone:     UTC"
echo "  Password:     scram-sha-256 hash beállítva"
echo ""
echo "Next: run migrations, then start backend"