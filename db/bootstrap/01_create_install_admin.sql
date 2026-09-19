-- Run as the initial PostgreSQL superuser.
-- No password is stored here. Set it interactively after this script succeeds.

SELECT format(
    'CREATE ROLE %I LOGIN NOSUPERUSER CREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS',
    :'install_admin'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'install_admin'
)
\gexec

SELECT format(
    'ALTER ROLE %I LOGIN NOSUPERUSER CREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS',
    :'install_admin'
)
\gexec
