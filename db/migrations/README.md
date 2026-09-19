# Service migrations

Keep Goose migrations grouped by service, for example:

```text
db/migrations/auth/
db/migrations/customer/
db/migrations/billing/
```

Run each directory with that service's `*_owner` role. The owner may create
and alter internal tables, views, and functions. The runtime `*_app` role must
receive only explicit grants for interfaces created by the migration.

Do not add broad table grants or migration logic to the Go application. Keep
the Goose version table in the service schema, such as
`auth.goose_db_version`.
