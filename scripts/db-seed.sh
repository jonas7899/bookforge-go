#!/bin/bash
# db-seed.sh — Service Admin létrehozása
# Futtatás: ./db-seed.sh
# Vagy egyedi adatokkal: EMAIL="te@email.hu" PASSWORD="Jelszo123!" NAME="Teljes Neved" ./db-seed.sh

set -e

CONTAINER="bookforge-postgres"
DB_USER="${DB_USER:-dev}"
DB_NAME="${DB_NAME:-bookforge_dev}"
SCHEMA="${DB_SCHEMA}"
if [ -z "$SCHEMA" ]; then
  echo "❌ DB_SCHEMA környezeti változó nincs beállítva"
  exit 1
fi

## EMAIL="${EMAIL:-admin@bookforge.hu}"
EMAIL="${EMAIL:-test2@example.com}"
PASSWORD="${PASSWORD:-Admin1234!}"
FULL_NAME="${NAME:-Service Admin}"

echo "╔══════════════════════════════════════════╗"
echo "║           DB SEED — Service Admin        ║"
echo "╚══════════════════════════════════════════╝"
echo "  Container : $CONTAINER"
echo "  DB        : $DB_NAME"
echo "  Email     : $EMAIL"
echo ""

# bcrypt hash generálása Python-nal (a legtöbb rendszeren elérhető)
# Ha nincs Python, fallback: htpasswd vagy manuális hash
if command -v python3 &>/dev/null; then
  PASSWORD_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw('$PASSWORD'.encode(), bcrypt.gensalt(12)).decode())" 2>/dev/null)
fi

if [ -z "$PASSWORD_HASH" ]; then
  # Fallback: előre generált bcrypt hash a "Admin1234!" jelszóhoz
  # Ha más jelszót adsz meg, ezt a hash-t le kell cserélni!
  echo "⚠️  Python bcrypt nem elérhető — hardcoded hash-t használok."
  echo "   Ez csak az alapértelmezett 'Admin1234!' jelszóval működik!"
  PASSWORD_HASH='$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj0y9e3dNaQu'
fi

# Snowflake-szerű ID generálása bash-ben (epoch: 2024-01-01)
EPOCH_MS=1704067200000
NOW_MS=$(date +%s%3N)
TS=$((NOW_MS - EPOCH_MS))
USER_ID=$(( (TS << 22) | (1 << 12) | (RANDOM % 4096) ))
SA_ID=$(( (TS << 22) | (2 << 12) | (RANDOM % 4096) ))
NOW=$(date -u +"%Y-%m-%d %H:%M:%S")

docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" << PSQL
SET search_path TO $SCHEMA, public;

-- 1. User létrehozása (ha még nem létezik)
INSERT INTO users (id, email, password_hash, full_name, is_active, is_verified, verified_at, created_at, updated_at)
VALUES (
  $USER_ID,
  '$EMAIL',
  '$PASSWORD_HASH',
  '$FULL_NAME',
  true, true,
  '$NOW', '$NOW', '$NOW'
)
ON CONFLICT (email) DO NOTHING;

-- 2. Service Admin bejegyzés
INSERT INTO service_admins (id, user_id, notes, created_at)
SELECT $SA_ID, id, 'db-seed.sh által létrehozva', NOW()
FROM users WHERE email = '$EMAIL'
ON CONFLICT DO NOTHING;

-- Visszajelzés
SELECT
  u.id,
  u.email,
  u.full_name,
  CASE WHEN sa.id IS NOT NULL THEN '✅ service_admin' ELSE '❌ NEM service_admin' END AS role
FROM users u
LEFT JOIN service_admins sa ON sa.user_id = u.id
WHERE u.email = '$EMAIL';
PSQL

echo ""
echo "═══════════════════════════════════════════"
echo "✅ KÉSZ!"
echo "   Email:  $EMAIL"
echo "   Jelszó: $PASSWORD"
echo "   URL:    /admin/login"
echo "═══════════════════════════════════════════"