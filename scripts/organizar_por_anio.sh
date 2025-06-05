#!/bin/bash
ENTRADA="/app/entrada"
for archivo in $(find "$ENTRADA" -type f -name "*.pdf"); do
  year=$(pdfinfo "$archivo" 2>/dev/null | grep -oP 'CreationDate.*\K\d{4}')
  if [ -n "$year" ]; then
    mkdir -p "$ENTRADA/$year"
    mv "$archivo" "$ENTRADA/$year/"
  fi
done
