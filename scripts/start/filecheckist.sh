#!/bin/bash

echo "🔍 Checking critical files..."
echo ""

MISSING=0

# Current project files
FILES=(
    "02_backend/cmd/api/main.go"
    "02_backend/go.mod"
    "02_backend/migrations/book-createschema.sql"
    "02_backend/migrations/book-initialdata.sql"
    "03_frontend_htmx/go.mod"
    "04_common/config/config.go"
    "04_common/go.mod"
    "05_config/config.yaml"
    "05_config/.env.example"
    "go.work"
    "Makefile"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ MISSING: $file"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
if [ $MISSING -eq 0 ]; then
    echo "🎉 All critical files present!"
else
    echo "⚠️  Missing $MISSING critical files!"
fi