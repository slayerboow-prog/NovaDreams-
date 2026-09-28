#!/usr/bin/env bash
# Convierte los iconos de la interfaz (assets/icons/*.svg, blancos sobre transparente) a PNG y los
# sube a Roblox con Open Cloud; al acabar escribe src/client/UI/IconIds.luau con el id de cada imagen.
# UI/Icons usa esas imágenes en lugar de los emojis de reserva.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   tu id de usuario de Roblox (el dueño de las imágenes)
# Y un conversor de SVG a PNG: rsvg-convert, ImageMagick (magick o convert), inkscape o
# python3 con cairosvg (pip install cairosvg).
#
# Uso (desde la carpeta roblox/):
#   scripts/upload-icons.sh              convierte y sube los que aún no tienen id
#   scripts/upload-icons.sh --png-only   solo convierte (assets/icons/png)
#   scripts/upload-icons.sh --force      vuelve a subirlos todos
#   scripts/upload-icons.sh casa tienda  solo esos
#   ICON_SIZE=256 (por defecto)          tamaño de los PNG
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="assets/icons"
OUT="assets/icons/png"
IDS="src/client/UI/IconIds.luau"
SIZE="${ICON_SIZE:-256}"
PNG_ONLY=0
FORCE=0
ONLY=()
for arg in "$@"; do
	case "$arg" in
		--png-only) PNG_ONLY=1 ;;
		--force) FORCE=1 ;;
		-*) echo "Opción desconocida: $arg"; exit 1 ;;
		*) ONLY+=("$arg") ;;
	esac
done

# ---------------------------------------------------------------------------
# SVG -> PNG
# ---------------------------------------------------------------------------
CONVERTER=""
if command -v rsvg-convert >/dev/null 2>&1; then
	CONVERTER="rsvg"
elif command -v magick >/dev/null 2>&1; then
	CONVERTER="magick"
elif command -v convert >/dev/null 2>&1; then
	CONVERTER="convert"
elif command -v inkscape >/dev/null 2>&1; then
	CONVERTER="inkscape"
elif python3 -c "import cairosvg" >/dev/null 2>&1; then
	CONVERTER="cairosvg"
else
	echo "❌ No hay conversor de SVG a PNG. Instala uno: librsvg (rsvg-convert), ImageMagick, inkscape o 'pip install cairosvg'."
	exit 1
fi

to_png() {
	local svg="$1" png="$2"
	case "$CONVERTER" in
		rsvg) rsvg-convert -w "$SIZE" -h "$SIZE" -b none "$svg" -o "$png" ;;
		magick) magick -background none -density 384 "$svg" -resize "${SIZE}x${SIZE}" "$png" ;;
		convert) convert -background none -density 384 "$svg" -resize "${SIZE}x${SIZE}" "$png" ;;
		inkscape) inkscape "$svg" --export-type=png --export-filename="$png" -w "$SIZE" -h "$SIZE" >/dev/null 2>&1 ;;
		cairosvg) python3 -c "import sys, cairosvg; cairosvg.svg2png(url=sys.argv[1], write_to=sys.argv[2], output_width=int(sys.argv[3]), output_height=int(sys.argv[3]))" "$svg" "$png" "$SIZE" ;;
	esac
}

mkdir -p "$OUT"
NAMES=()
for svg in "$SRC"/*.svg; do
	name="$(basename "$svg" .svg)"
	if [ "${#ONLY[@]}" -gt 0 ] && [[ ! " ${ONLY[*]} " == *" $name "* ]]; then
		continue
	fi
	to_png "$svg" "$OUT/$name.png"
	NAMES+=("$name")
done
echo "🖼  ${#NAMES[@]} iconos convertidos a PNG (${SIZE}x${SIZE}, con $CONVERTER) en $OUT"
if [ "$PNG_ONLY" = 1 ]; then
	exit 0
fi

# ---------------------------------------------------------------------------
# Subir a Roblox (Open Cloud Assets API) y apuntar los ids
# ---------------------------------------------------------------------------
: "${ROBLOX_API_KEY:?Falta ROBLOX_API_KEY}"
: "${ROBLOX_CREATOR_USER_ID:?Falta ROBLOX_CREATOR_USER_ID}"
command -v curl >/dev/null 2>&1 || { echo "❌ Hace falta curl"; exit 1; }
set +x # (la clave no se enseña nunca)

json() { # json <campo.subcampo> < texto
	python3 -c "import sys, json
data = json.load(sys.stdin)
for key in sys.argv[1].split('.'):
    data = data.get(key) if isinstance(data, dict) else None
print('' if data is None else data)" "$1"
}

# Ids que ya había (nombre -> id)
declare -A KNOWN=()
if [ -f "$IDS" ]; then
	while IFS='=' read -r key value; do
		KNOWN["$key"]="$value"
	done < <(grep -oE '^\s*[a-z]+ = "rbxassetid://[0-9]+"' "$IDS" | sed -E 's/^\s*([a-z]+) = "(rbxassetid:\/\/[0-9]+)"/\1=\2/')
fi

# Del id del Decal al de su imagen (lo que usa ImageLabel.Image)
image_of_decal() {
	local decal="$1" xml image
	xml="$(curl -sS -L "https://assetdelivery.roblox.com/v1/asset/?id=${decal}" -H "x-api-key: ${ROBLOX_API_KEY}" 2>/dev/null || true)"
	image="$(printf '%s' "$xml" | grep -oE 'id=[0-9]+' | head -1 | cut -d= -f2 || true)"
	if [ -n "$image" ]; then
		echo "$image"
	else
		echo "$decal"
	fi
}

upload() {
	local name="$1" png="$OUT/$1.png" request response operation done_ assetId
	request="$(printf '{"assetType":"Decal","displayName":"Icono %s","description":"Icono de la interfaz de Real Life Simulator","creationContext":{"creator":{"userId":"%s"}}}' "$name" "$ROBLOX_CREATOR_USER_ID")"
	response="$(curl -sS -X POST "https://apis.roblox.com/assets/v1/assets" \
		-H "x-api-key: ${ROBLOX_API_KEY}" \
		-F "request=${request};type=application/json" \
		-F "fileContent=@${png};type=image/png")"
	operation="$(printf '%s' "$response" | json operationId)"
	if [ -z "$operation" ]; then
		operation="$(printf '%s' "$response" | json path | sed 's|^operations/||')"
	fi
	if [ -z "$operation" ]; then
		echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
		return 1
	fi
	for _ in $(seq 1 30); do
		sleep 2
		response="$(curl -sS "https://apis.roblox.com/assets/v1/operations/${operation}" -H "x-api-key: ${ROBLOX_API_KEY}")"
		done_="$(printf '%s' "$response" | json done)"
		if [ "$done_" = "True" ] || [ "$done_" = "true" ]; then
			assetId="$(printf '%s' "$response" | json response.assetId)"
			if [ -n "$assetId" ]; then
				image_of_decal "$assetId"
				return 0
			fi
			echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
			return 1
		fi
	done
	echo "  ❌ $name: Roblox tarda demasiado (operación ${operation})" >&2
	return 1
}

FAILED=0
for name in "${NAMES[@]}"; do
	if [ "$FORCE" = 0 ] && [ -n "${KNOWN[$name]:-}" ]; then
		echo "  = $name ya subido (${KNOWN[$name]})"
		continue
	fi
	if id="$(upload "$name")"; then
		KNOWN["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# IconIds.luau (generado)
{
	echo "-- IconIds: GENERADO por scripts/upload-icons.sh (no editar a mano)."
	echo "-- Nombre del icono -> imagen subida a Roblox (\"rbxassetid://…\"). Los que falten usan el emoji de"
	echo "-- reserva de UI/Icons (se ven en todos los dispositivos)."
	echo "return {"
	for key in $(printf '%s\n' "${!KNOWN[@]}" | sort); do
		echo "	${key} = \"${KNOWN[$key]}\","
	done
	echo "} :: { [string]: string }"
} > "$IDS"
echo "📄 $IDS con ${#KNOWN[@]} iconos"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED iconos no se pudieron subir (vuelve a lanzar el script: solo sube los que faltan)"
	exit 1
fi
echo "✅ Listo. Reconstruye el juego para que la interfaz use las imágenes."
