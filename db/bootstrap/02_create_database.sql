-- Run as the initial PostgreSQL superuser.

SELECT format(
    'CREATE DATABASE %I OWNER %I',
    :'database_name', :'install_admin'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = :'database_name'
)
\gexec
