-- Run while connected to the application database as install_admin.
-- Invoke once for every service, for example: -v service=auth

SELECT format(
    'CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
    :'service' || '_owner'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'service' || '_owner'
)
\gexec

SELECT format(
    'CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
    :'service' || '_app'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'service' || '_app'
)
\gexec

-- install_admin uses SET ROLE / connection option role=<service>_owner for
-- migrations because the owner role itself intentionally cannot log in.
SELECT format(
    'GRANT %I TO %I', :'service' || '_owner', :'install_admin'
)
\gexec

SELECT format(
    'CREATE SCHEMA %I AUTHORIZATION %I', :'service', :'service' || '_owner'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_namespace WHERE nspname = :'service'
)
\gexec

SELECT format(
    'ALTER SCHEMA %I OWNER TO %I', :'service', :'service' || '_owner'
)
\gexec

SELECT format(
    'REVOKE ALL ON SCHEMA %I FROM PUBLIC', :'service'
)
\gexec

SELECT format(
    'GRANT USAGE ON SCHEMA %I TO %I', :'service', :'service' || '_app'
)
\gexec

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
