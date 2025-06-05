#!/bin/bash
ENTRADA="/app/entrada"
SALIDA="/app/salida"
mkdir -p "$SALIDA"

for docx in $(find "$ENTRADA" -type f -name "*.docx"); do
  name=$(basename "$docx" .docx)
  pandoc "$docx" -t plain -o "$SALIDA/${name}.txt"
done

for xlsx in $(find "$ENTRADA" -type f -name "*.xlsx"); do
  name=$(basename "$xlsx" .xlsx)
  ssconvert "$xlsx" "$SALIDA/${name}.csv"
done
