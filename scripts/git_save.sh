#!/bin/bash

# Ha csak el kell menteni félkész állapotot
# mielőtt az AI átrendezné az egész kódbázist 
COMMENT=""
if [[ $# -ne 0 ]] ; then
    COMMENT="$1 - "
fi
git status && git add . && git commit -m "${COMMENT}Auto-save: $(date +%H:%M:%S)" && git push