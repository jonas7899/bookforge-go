-- Run while connected to the application database as install_admin.
-- Invoke once for every service, for example: -v service=auth
--
-- Runtime users receive no default table, sequence, or function privileges.
-- Interface permissions are granted explicitly by 05_grant_*.sql.

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON TABLES FROM %I',
    :'service' || '_owner', :'service', :'service' || '_app'
)
\gexec

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON SEQUENCES FROM %I',
    :'service' || '_owner', :'service', :'service' || '_app'
)
\gexec

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON FUNCTIONS FROM %I',
    :'service' || '_owner', :'service', :'service' || '_app'
)
\gexec

SELECT format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC',
    :'service' || '_owner', :'service'
)
\gexec

