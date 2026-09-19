#!/bin/bash

# Ha bármelyik parancs hibára fut, a script azonnal álljon le
set -e

echo "🛑 Takarítás..."
# Leállítjuk az air-t és a beragadt main folyamatot is
pkill -f air || true
pkill -f "tmp/main" || true
# Felszabadítjuk a 8082-es portot (ha valami mégis fogná)
lsof -t -i :8082 | xargs -r kill || true

echo "🐘 Adatbázis újraindítása..."
# Megpróbáljuk leállítani, de nem baj, ha nem futott
pg_ctl -D .idx/.data/postgres -o "-k /tmp" -l postgres.log stop || true

# Indítás a szokásos paraméterekkel
pg_ctl -D .idx/.data/postgres -o "-k /tmp -h 127.0.0.1" -l postgres.log start

echo "⏳ Várakozás az adatbázisra..."
# Addig várunk (max 10mp), amíg a Postgres tényleg válaszol a 127.0.0.1-en
timeout 10s bash -c 'until pg_isready -h 127.0.0.1; do sleep 0.5; done'

echo "🦆 Migrációk futtatása..."
# Biztosítjuk, hogy a $DATABASE_URL helyes legyen
goose -dir internal/db/migrations postgres "$DATABASE_URL" up

echo "⚙️ Template generálás..."
$HOME/go/bin/templ generate

echo "Kód ellenőrzés..."
go vet ./...

# A buildelést az AIR végzi, ez a sor felesleges és hibát okoz.
# echo "🛠️ Szerver buildelése..."
# go build -o ./tmp/main ./cmd/server

echo "✈️ Szerver indítása (Air)..."
$HOME/go/bin/air