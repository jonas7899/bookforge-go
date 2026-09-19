#!/bin/bash

# A) Legenerálja a .templ file-okból az SSR (Server-side rendering) Go kódot: templ generate
# B) Statikus elemzést végez: go vet
# C) Előállítja a binárisokat: go build

# Ha bármelyik parancs hibára fut, a script azonnal álljon le
set -e

echo "Name of the script \$0: $0"
echo "Total number of arguments \$#: $#"
echo "Values of all the arguments \$@: $@"
echo "The bash script 1. argument \$1: $1"
echo "The process id of the current shell \$$: $$"
echo "The exit status of the last executed command \$?: $?"
echo "The process id of the last executed command \$!: $!"


echo "templ generate..."
$HOME/go/bin/templ generate
#templ generate

echo "Finished"

echo "checking code..."
go vet ./...
echo "Finished"

if [ $# -eq 0 ]; then
    echo "Building..."
    [ -f ./tmp/main ] && rm ./tmp/main
    go build -o ./tmp/main ./cmd/api
    ls -la ./tmp/main
fi

if [ "$1" == "dryrun" ]; then
    echo "Testing the build..."
    go build -o /dev/null ./...
fi
echo "Finished"
 