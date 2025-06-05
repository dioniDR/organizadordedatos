#!/bin/bash
ENTRADA="/app/entrada"
SALIDA="/app/salida"
mkdir -p "$SALIDA"

for xml in $(find "$ENTRADA" -type f -name "*.xml"); do
  name=$(basename "$xml" .xml)
  xmllint --format "$xml" | sed 's/<[^>]*>//g' > "$SALIDA/${name}.txt"
done
