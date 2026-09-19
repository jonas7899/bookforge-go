-- Explicit interface grant. Run as the service owner after the view exists.

SELECT format(
    'GRANT SELECT ON TABLE %I.%I TO %I',
    :'interface_schema', :'interface_name', :'interface_schema' || '_app'
)
\gexec
