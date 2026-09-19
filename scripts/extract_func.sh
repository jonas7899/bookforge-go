#!/usr/bin/env bash

dir="$1"
fname="$2"

if [[ -z "$dir" || -z "$fname" ]]; then
    echo "Használat: $0 <directory> <FunctionName>"
    exit 1
fi

find "$dir" -type f -name "*.go" | while read -r file; do
    awk -v fname="$fname" -v file="$file" '
    # Ha megtaláljuk a func deklarációt
    $0 ~ "func[[:space:]]+" fname {
        printing = 1
        brace = 0
        print "=== " file " ==="
    }

    printing {
        print
        brace += gsub(/\{/, "{")
        brace -= gsub(/\}/, "}")
        if (brace == 0) {
            printing = 0
            print ""
        }
    }
    ' "$file"
done
