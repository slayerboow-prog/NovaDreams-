#!/usr/bin/env bash
# Publica RealLifeSimulator.rbxl en tu juego de Roblox (Open Cloud, sin abrir Studio).
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY      clave de Open Cloud con permiso "universe-places: write" para tu juego
#   ROBLOX_UNIVERSE_ID  el número de la experiencia (Universe ID)
#   ROBLOX_PLACE_ID     el número del lugar (Place ID)
# Uso: scripts/publish.sh [archivo.rbxl]   (por defecto, RealLifeSimulator.rbxl)
set -euo pipefail
FILE="${1:-RealLifeSimulator.rbxl}"
: "${ROBLOX_API_KEY:?Falta ROBLOX_API_KEY}"
: "${ROBLOX_UNIVERSE_ID:?Falta ROBLOX_UNIVERSE_ID}"
ROBLOX_PLACE_ID="${ROBLOX_PLACE_ID:-113359543879512}" # Real Life Simulator (lugar de inicio)
[ -f "$FILE" ] || { echo "No existe $FILE (constrúyelo antes)"; exit 1; }
URL="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=Published"
echo "Publicando $FILE ($(du -h "$FILE" | cut -f1))…"
curl -sS --fail-with-body -X POST "$URL" \
	-H "x-api-key: ${ROBLOX_API_KEY}" \
	-H "Content-Type: application/octet-stream" \
	--data-binary @"$FILE"
echo
echo "✅ Publicado. Ábrelo en la app de Roblox del móvil."
