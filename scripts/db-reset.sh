#!/bin/bash
# db-reset.sh — Összes tábla tartalmának törlése (goose_db_version kivételével)
# Futtatás: ./db-reset.sh
# Megerősítés nélkül: ./db-reset.sh --force

set -e

CONTAINER="bookforge-postgres"
DB_USER="${DB_USER:-dev}"
DB_NAME="${DB_NAME:-bookforge_dev}"
DB_SCHEMA="${DB_SCHEMA:-bookforge}"

FORCE=false
if [ "$1" = "--force" ]; then
  FORCE=true
fi

echo "╔══════════════════════════════════════════════╗"
echo "║  ⚠️  FIGYELEM: ADATBÁZIS RESET                ║"
echo "║  Ez a művelet TÖRLI az összes tábla          ║"
echo "║  tartalmát (kivéve: goose_db_version)!       ║"
echo "╚══════════════════════════════════════════════╝"
echo "  Container : $CONTAINER"
echo "  DB        : $DB_NAME"
echo "  Schema    : $DB_SCHEMA"
echo ""

if [ "$FORCE" = false ]; then
  read -p "Biztosan folytatod? Írd be: RESET > " ANSWER
  if [ "$ANSWER" != "RESET" ]; then
    echo "❌ Megszakítva."
    exit 0
  fi
fi

echo ""
echo "🗑️  Törlés folyamatban..."

# Dinamikusan lekérdezi a sémában lévő összes táblát,
# kihagyja a goose_db_version-t, majd TRUNCATE-eli őket CASCADE-del.
docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" << PSQL
SET search_path TO $DB_SCHEMA, public;

DO \$\$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = '$DB_SCHEMA'
      AND tablename != 'goose_db_version'
    ORDER BY tablename
  LOOP
    EXECUTE 'TRUNCATE TABLE $DB_SCHEMA.' || quote_ident(tbl) || ' RESTART IDENTITY CASCADE';
    RAISE NOTICE 'Törölve: %', tbl;
  END LOOP;
END;
\$\$;

SELECT '✅ goose_db_version verzió: ' || MAX(version_id)::text AS status
FROM goose_db_version;
PSQL

echo ""
echo "═══════════════════════════════════════════════"
echo "✅ RESET KÉSZ! Az adatbázis üres."
echo "   Következő lépés: ./db-seed.sh"
echo "═══════════════════════════════════════════════"