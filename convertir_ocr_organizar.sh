#!/bin/bash

# Ruta base
ENTRADA="./entrada"
SALIDA="./salida"
LOG_CAMBIOS="./salida/registro_cambios.log"

mkdir -p "$SALIDA"
echo "Registro de cambios - $(date)" > "$LOG_CAMBIOS"

# Función: Extraer texto OCR y limpiar imágenes temporales
procesar_pdf() {
  local archivo="$1"
  local nombre=$(basename "$archivo" .pdf)
  local salida_txt="$SALIDA/${nombre}_ocr.txt"
  local carpeta_temp="$SALIDA/temp_${nombre}"

  mkdir -p "$carpeta_temp"

  echo "[+] Procesando OCR para $archivo" >> "$LOG_CAMBIOS"
  pdftoppm "$archivo" "$carpeta_temp/page" -png

  for img in "$carpeta_temp"/page-*.png; do
    tesseract "$img" "$img" -l spa --psm 3 txt >> /dev/null 2>&1
  done

  cat "$carpeta_temp"/*.txt > "$salida_txt"
  echo "[✓] Texto extraído a $salida_txt" >> "$LOG_CAMBIOS"

  rm -rf "$carpeta_temp"
  echo "[-] Imágenes temporales eliminadas para $nombre" >> "$LOG_CAMBIOS"
}

# Función: Generar PDF OCR sin extraer texto plano
generar_pdf_ocr() {
  local archivo="$1"
  local nombre=$(basename "$archivo" .pdf)
  local carpeta_temp="$SALIDA/temp_pdf_${nombre}"
  mkdir -p "$carpeta_temp"
  pdftoppm "$archivo" "$carpeta_temp/page" -png

  for img in "$carpeta_temp"/page-*.png; do
    tesseract "$img" "$img" -l spa pdf >> /dev/null 2>&1
  done

  pdfunite "$carpeta_temp"/*.pdf "$SALIDA/${nombre}_ocr.pdf"
  echo "[✓] PDF OCR generado en $SALIDA/${nombre}_ocr.pdf" >> "$LOG_CAMBIOS"
  rm -rf "$carpeta_temp"
}

# Buscar PDFs duplicados (por nombre exacto y tamaño)
buscar_duplicados() {
  echo "[!] Buscando duplicados..." >> "$LOG_CAMBIOS"
  find "$ENTRADA" -type f -name "*.pdf" -exec md5sum {} + | sort | uniq -d --check-chars=32 | cut -d ' ' -f 3- >> "$LOG_CAMBIOS"
}

# Organizar por año si es posible
organizar_por_anio() {
  echo "[!] Reorganizando archivos..." >> "$LOG_CAMBIOS"
  for pdf in "$ENTRADA"/*.pdf; do
    year=$(pdfinfo "$pdf" | grep "CreationDate" | grep -oE '[0-9]{4}')
    if [ ! -z "$year" ]; then
      mkdir -p "$ENTRADA/$year"
      mv "$pdf" "$ENTRADA/$year/"
      echo "[→] Movido $pdf a carpeta $year" >> "$LOG_CAMBIOS"
    fi
  done
}

# LOOP PRINCIPAL
for archivo in "$ENTRADA"/*.pdf; do
  if pdftotext "$archivo" - > /dev/null 2>&1; then
    texto=$(pdftotext "$archivo" -)
    if [ -n "$texto" ]; then
      nombre=$(basename "$archivo" .pdf)
      echo "$texto" > "$SALIDA/${nombre}.txt"
      echo "[✓] Texto extraído sin OCR para $archivo" >> "$LOG_CAMBIOS"
    else
      procesar_pdf "$archivo"
    fi
  else
    procesar_pdf "$archivo"
  fi
  generar_pdf_ocr "$archivo"
  echo "---" >> "$LOG_CAMBIOS"
done

buscar_duplicados
organizar_por_anio

echo "[✔] Proceso completo. Revisa $LOG_CAMBIOS para ver los cambios aplicados."
