#!/bin/bash
SALIDA="/app/salida"
cat "$SALIDA"/*.txt > "$SALIDA/resultado_final.txt"
