-- Final step. Run as the PostgreSQL superuser after all checks pass.
ALTER ROLE postgres NOLOGIN;
