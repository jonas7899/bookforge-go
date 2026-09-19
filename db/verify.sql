-- Run against the application database with a role that can inspect pg_roles.
-- The query discovers service schemas by the *_owner / *_app naming convention.

\pset null '(null)'

SELECT 'install_admin' AS check_name,
       EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'install_admin') AS ok,
       COALESCE((SELECT NOT rolsuper AND rolcreaterole AND rolcreatedb
                 FROM pg_roles WHERE rolname = :'install_admin'), false) AS properties_ok;

SELECT 'postgres_nologin' AS check_name,
       COALESCE((SELECT NOT rolcanlogin FROM pg_roles WHERE rolname = 'postgres'), false) AS ok;

WITH service_roles AS (
    SELECT n.nspname AS service,
           owner_role.rolname AS owner_role,
           app_role.rolname AS app_role,
           owner_role.rolcanlogin AS owner_can_login,
           app_role.rolcanlogin AS app_can_login,
           app_role.rolsuper AS app_is_superuser,
           app_role.rolcreatedb AS app_can_create_database,
           app_role.rolcreaterole AS app_can_create_role,
           app_role.rolreplication AS app_can_replicate,
           app_role.rolbypassrls AS app_can_bypass_rls
    FROM pg_namespace n
    JOIN pg_roles owner_role ON owner_role.rolname = n.nspname || '_owner'
    JOIN pg_roles app_role ON app_role.rolname = n.nspname || '_app'
    WHERE n.nspname NOT LIKE 'pg_%'
      AND n.nspname <> 'information_schema'
      AND n.nspname <> 'public'
)
SELECT service,
       owner_role,
       app_role,
       owner_can_login = false AS owner_nologin,
       app_can_login,
       NOT app_is_superuser AND NOT app_can_create_database
           AND NOT app_can_create_role AND NOT app_can_replicate
           AND NOT app_can_bypass_rls AS app_restricted,
       has_schema_privilege(app_role, service, 'USAGE') AS app_has_schema_usage,
         NOT has_schema_privilege(app_role, service, 'CREATE') AS no_schema_create,
       NOT EXISTS (
           SELECT 1
           FROM pg_class c
           WHERE c.relnamespace = service::regnamespace
             AND c.relkind IN ('r', 'p')
             AND (
                 has_table_privilege(app_role, c.oid, 'SELECT') OR
                 has_table_privilege(app_role, c.oid, 'INSERT') OR
                 has_table_privilege(app_role, c.oid, 'UPDATE') OR
                 has_table_privilege(app_role, c.oid, 'DELETE') OR
                 has_table_privilege(app_role, c.oid, 'TRUNCATE') OR
                 has_table_privilege(app_role, c.oid, 'REFERENCES') OR
                 has_table_privilege(app_role, c.oid, 'TRIGGER')
             )
       ) AS no_direct_table_privileges
FROM service_roles
ORDER BY service;

-- Baseline isolation check. Add documented exceptions before granting
-- cross-service interface access.
WITH service_roles AS (
    SELECT n.nspname AS service, app_role.rolname AS app_role
    FROM pg_namespace n
    JOIN pg_roles app_role ON app_role.rolname = n.nspname || '_app'
    WHERE n.nspname NOT LIKE 'pg_%'
      AND n.nspname NOT IN ('information_schema', 'public')
)
SELECT source.service AS source_service,
       target.service AS target_service,
       NOT has_schema_privilege(source.app_role, target.service, 'USAGE') AS isolated
FROM service_roles source
JOIN service_roles target ON target.service <> source.service
ORDER BY source.service, target.service;
