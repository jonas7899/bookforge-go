#!/usr/bin/env sh
set -eu

: "${DB_HOST:=127.0.0.1}"
: "${DB_PORT:=5432}"
: "${DB_NAME:=my_first_ag_proj}"
: "${INSTALL_ADMIN:=install_admin}"
: "${SERVICES:=auth customer billing}"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

run_as_initial_admin() {
    psql --host="$DB_HOST" --port="$DB_PORT" --dbname=postgres \
        --set=ON_ERROR_STOP=1 "$@"
}

run_as_install_admin() {
    psql --host="$DB_HOST" --port="$DB_PORT" --dbname="$DB_NAME" \
        --username="$INSTALL_ADMIN" --set=ON_ERROR_STOP=1 "$@"
}

run_as_initial_admin --set=install_admin="$INSTALL_ADMIN" \
    -f "$script_dir/01_create_install_admin.sql"
run_as_initial_admin --set=install_admin="$INSTALL_ADMIN" \
    --set=database_name="$DB_NAME" -f "$script_dir/02_create_database.sql"

for service in $SERVICES; do
    run_as_install_admin \
        --set=install_admin="$INSTALL_ADMIN" --set=service="$service" \
        -f "$script_dir/03_create_service.sql"
    run_as_install_admin --set=install_admin="$INSTALL_ADMIN" \
        --set=service="$service" -f "$script_dir/04_configure_default_privileges.sql"
done

printf '%s\n' "Bootstrap roles and schemas created. Set role passwords, run migrations, grant interfaces, verify, then run 99_disable_postgres.sql as postgres."
