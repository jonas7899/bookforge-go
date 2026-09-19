-- Explicit interface grant. Run as the service owner after the function exists.

SELECT format(
    'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO %I',
    :'interface_schema', :'function_name', :'function_signature',
    :'interface_schema' || '_app'
)
\gexec
