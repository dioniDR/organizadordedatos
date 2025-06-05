#!/bin/bash
ENTRADA="/app/entrada"
LOG="/app/salida/duplicados.log"
echo "Duplicados encontrados:" > "$LOG"
find "$ENTRADA" -type f \( -name "*.pdf" -o -name "*.docx" -o -name "*.txt" \) -exec md5sum {} + | sort | uniq -d --check-chars=32 | cut -d ' ' -f 3- >> "$LOG"
