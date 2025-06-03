#!/bin/bash
mkdir -p /app/salida

for archivo in /app/entrada/*.pdf; do
  nombre=$(basename "$archivo" .pdf)
  
  # Intento 1: PDF con texto embebido
  pdftotext "$archivo" "/app/salida/${nombre}.txt"
  
  # Verifica si quedó vacío (es probable escaneado)
  if [ ! -s "/app/salida/${nombre}.txt" ]; then
    pdftoppm "$archivo" "/app/salida/temp_${nombre}" -png
    for img in /app/salida/temp_${nombre}-*.png; do
      tesseract "$img" "$img" -l spa
    done
    cat /app/salida/temp_${nombre}-*.txt > "/app/salida/${nombre}_ocr.txt"
    rm /app/salida/temp_${nombre}-*
  fi
done

# Consolida todos los textos en uno solo
cat /app/salida/*.txt > /app/salida/resultado_final.txt
