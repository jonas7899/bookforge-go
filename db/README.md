# PostgreSQL bootstrap

This directory contains a reusable, Go-independent PostgreSQL bootstrap for
the application database `my_first_ag_proj`. Change `DB_NAME` and `SERVICES`
for another application. The SQL never contains a password.

## Installation order

Run the scripts in this order:

1. As the initial PostgreSQL superuser, run `bootstrap/01_create_install_admin.sql`.
2. As the same superuser, run `bootstrap/02_create_database.sql`.
3. Connect to the new database as `install_admin`.
4. Run `bootstrap/03_create_service.sql` and `bootstrap/04_configure_default_privileges.sql` once per service.
5. Set passwords outside Git using DBeaver's password dialog or `\password role_name` in `psql`.
6. Run the service migrations through `install_admin` with the corresponding `*_owner` role set for the session.
7. Grant only the created interfaces with `05_grant_view.sql` or `06_grant_function.sql` in that owner-role session.
8. Run `verify.sql` while connected to the application database.
9. As the PostgreSQL superuser, run `bootstrap/99_disable_postgres.sql` last.

The optional `bootstrap/run.sh` automates steps 1-4. Export values from
`bootstrap/bootstrap.env.example` first. It prompts for passwords through
`psql`; it does not accept or persist passwords itself.

## Roles

- `postgres` remains a superuser for emergency administration, but is changed to `NOLOGIN` at the end.
- `install_admin` is the normal installation role: `LOGIN`, `CREATEDB`, and `CREATEROLE`, but not superuser.
- `<service>_owner` is `NOLOGIN` and owns one service schema and its migration objects. `install_admin` is a member of it so migration tools can use `SET ROLE` without making the owner login-capable.
- `<service>_app` is the runtime `LOGIN` role. It has schema `USAGE`, but no direct table privileges and no DDL role attributes.

Do not use an `_app` role for Goose migrations. Do not grant `ALL` to a
runtime role. Views and functions are database interfaces; grant them one at
a time after they exist.

## DBeaver and secrets

Create separate DBeaver connections for the initial `postgres` session,
`install_admin`, and each runtime role. For migrations, connect as
`install_admin` with the PostgreSQL connection option
`-c role=<service>_owner`; the owner role itself remains `NOLOGIN`. Enter passwords in the
connection password field or use DBeaver variables that are excluded from
exported project files. Never put a real password in SQL, YAML, `.env` files
that are committed, or migration source.

When switching databases in DBeaver, edit the connection's Database field to
the value of `DB_NAME`; PostgreSQL does not support a SQL `USE database`
statement.

## Default privileges

`ALTER DEFAULT PRIVILEGES FOR ROLE <service>_owner IN SCHEMA <service>` applies
only to future objects created by that owner in that schema. It does not fix
existing objects and it does not apply to objects created by `install_admin`
or another role. This bootstrap deliberately revokes runtime defaults;
interface grants remain explicit.

## Adding services and databases

Add a service name to `SERVICES`, then run scripts 03 and 04 for it. This
creates `<service>`, `<service>_owner`, and `<service>_app`. For a new
application database, set `DB_NAME`, run scripts 01-02, connect to the new
database, and repeat the service steps. Do not reuse service roles between
databases unless that sharing is an explicit operational decision.

## Cross-service access

The default is no schema `USAGE` across services. Expose a narrow view or
function from the owning service and grant only that object. If the consumer
needs schema `USAGE`, grant it explicitly to the consumer app role and record
the exception beside the migration. Never grant the consumer `ALL` on the
producer schema or its tables.

## Goose migrations

Run Goose with an `install_admin` migration connection using
`options='-c role=<service>_owner'`, the target application database, and the
target service schema. Configure
Goose's version table inside that service schema, for example
`auth.goose_db_version`. Migrations create tables, views, and functions as the
owner. Their final statements should grant only the required interface
permissions to `<service>_app`. Runtime connections use only `<service>_app`.

The legacy root `migrations/` directory is left unchanged because it contains
the existing `book` schema SQL. Migrate it only after deciding whether `book`
is a service or a separate application concern.

## Verification

Run `psql -v install_admin=install_admin -f db/verify.sql` against the target
database, or execute the statements in DBeaver. The result checks actual
`pg_roles`, schema privileges, object privileges, and cross-service isolation,
not merely whether a GRANT script was run. A failed check must be resolved
before disabling `postgres` login.
