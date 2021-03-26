#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.." || { echo "not able to switch to the oxideshop directory"; exit 1; }

for d in project-modules/*; do
    module_name=$(basename "$d")
    metadata="$d/metadata.php"
    if grep -q "'extend'" "$metadata"; then
        vendor/bin/oxid-dump-autoload -s "$metadata" -p ".autoload.module.$module_name.php"
    fi
done
