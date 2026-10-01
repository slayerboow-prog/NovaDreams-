#!/usr/bin/env bash
# Sube las plantillas de ropa de los 30 conjuntos del pase (assets/outfits/oNN_shirt.png y
# oNN_pants.png, 585×559, hechas con scripts/outfits/gen.py) a Roblox con Open Cloud y, al acabar,
# escribe src/shared/OutfitIds.luau (nombre -> "rbxassetid://<imagen>"). shared/OutfitBuilder las usa
# como ShirtTemplate / PantsTemplate; mientras falte alguna, ese conjunto se viste con colores y piezas.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox, el dueño de las imágenes.
#                            Si no está, se mira de quién es el juego (ROBLOX_UNIVERSE_ID, el mismo de
#                            scripts/publish.sh); para eso la clave necesita también "universe: read".
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo, el id del grupo
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-outfits.sh               genera las que falten y sube las que aún no tienen id
#   bash scripts/upload-outfits.sh --force       vuelve a subirlas todas
#   bash scripts/upload-outfits.sh o05 o13       solo esos conjuntos (camisa y pantalón)
#   bash scripts/upload-outfits.sh --gen         vuelve a dibujarlas antes (python3 scripts/outfits/gen.py)
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

SRC="assets/outfits"
IDS="src/shared/OutfitIds.luau"
FORCE=0
GEN=0
ONLY=()
for arg in "$@"; do
	case "$arg" in
		--force) FORCE=1 ;;
		--gen) GEN=1 ;;
		-h | --help) sed -n '2,19p' "$0"; exit 0 ;;
		-*) echo "Opción desconocida: $arg"; exit 1 ;;
		*) ONLY+=("$(printf '%s' "$arg" | tr 'A-Z' 'a-z')") ;;
	esac
done

if [ "$GEN" = 1 ] || ! ls "$SRC"/o*_shirt.png >/dev/null 2>&1; then
	python3 scripts/outfits/gen.py
fi

NAMES=()
for png in "$SRC"/o*_shirt.png "$SRC"/o*_pants.png; do
	[ -f "$png" ] || continue
	name="$(basename "$png" .png)"
	if [ "${#ONLY[@]}" -gt 0 ] && [[ ! " ${ONLY[*]} " == *" ${name%_*} "* ]]; then
		continue
	fi
	NAMES+=("$name")
done
if [ "${#NAMES[@]}" -eq 0 ]; then
	echo "❌ No hay plantillas en $SRC. Créalas con: python3 scripts/outfits/gen.py"
	exit 1
fi

# ---------------------------------------------------------------------------
# Clave y dueño
# ---------------------------------------------------------------------------
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir imágenes)."
	echo "   Créala en create.roblox.com → Open Cloud → API Keys y ponla así:  export ROBLOX_API_KEY=…"
	exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "❌ Hace falta curl"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Hace falta python3"; exit 1; }

json() { # json <campo.subcampo> < texto
	python3 -c "import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    data = None
for key in sys.argv[1].split('.'):
    data = data.get(key) if isinstance(data, dict) else None
print('' if data is None else data)" "$1"
}

# La clave va en un archivo de cabeceras (así no sale en la lista de procesos ni en ningún mensaje)
HEADERS="$(mktemp)"
trap 'rm -f "$HEADERS"' EXIT
chmod 600 "$HEADERS"
printf 'x-api-key: %s\n' "$ROBLOX_API_KEY" > "$HEADERS"

UNIVERSE="${ROBLOX_UNIVERSE_ID:-10767975237}" # Real Life Simulator (el mismo que scripts/publish.sh)
CREATOR=""
if [ -n "${ROBLOX_CREATOR_USER_ID:-}" ]; then
	CREATOR="$(printf '{"userId":"%s"}' "$ROBLOX_CREATOR_USER_ID")"
elif [ -n "${ROBLOX_CREATOR_GROUP_ID:-}" ]; then
	CREATOR="$(printf '{"groupId":"%s"}' "$ROBLOX_CREATOR_GROUP_ID")"
else
	universe="$(curl -sS "https://apis.roblox.com/cloud/v2/universes/${UNIVERSE}" -H "@${HEADERS}" 2>/dev/null || true)"
	owner_user="$(printf '%s' "$universe" | json user | sed -n 's|^users/\([0-9][0-9]*\)$|\1|p')"
	owner_group="$(printf '%s' "$universe" | json group | sed -n 's|^groups/\([0-9][0-9]*\)$|\1|p')"
	if [ -n "$owner_user" ]; then
		CREATOR="$(printf '{"userId":"%s"}' "$owner_user")"
	elif [ -n "$owner_group" ]; then
		CREATOR="$(printf '{"groupId":"%s"}' "$owner_group")"
	else
		echo "❌ No sé a nombre de quién subir las imágenes: pon ROBLOX_CREATOR_USER_ID (o ROBLOX_CREATOR_GROUP_ID)."
		exit 1
	fi
fi

# ---------------------------------------------------------------------------
# Subir
# ---------------------------------------------------------------------------
declare -A KNOWN=()
if [ -f "$IDS" ]; then
	while IFS='=' read -r key value; do
		KNOWN["$key"]="$value"
	done < <(grep -oE '^\s*o[0-9]+_(shirt|pants) = "rbxassetid://[0-9]+"' "$IDS" | sed -E 's/^\s*([a-z_0-9]+) = "(rbxassetid:\/\/[0-9]+)"/\1=\2/')
fi

# Del id del Decal al de su imagen (lo que usan ShirtTemplate / PantsTemplate)
image_of_decal() {
	local decal="$1" xml image
	xml="$(curl -sS -L "https://assetdelivery.roblox.com/v1/asset/?id=${decal}" -H "@${HEADERS}" 2>/dev/null || true)"
	image="$(printf '%s' "$xml" | grep -oE 'id=[0-9]+' | head -1 | cut -d= -f2 || true)"
	if [ -n "$image" ]; then
		echo "$image"
	else
		echo "$decal"
	fi
}

upload() { # upload <nombre> -> escribe el id de la imagen
	local name="$1" png="$SRC/$1.png" request response operation done_ assetId
	request="$(printf '{"assetType":"Decal","displayName":"Ropa %s","description":"Plantilla de ropa del pase de Real Life Simulator (hecha por código)","creationContext":{"creator":%s}}' "$name" "$CREATOR")"
	response="$(curl -sS -X POST "https://apis.roblox.com/assets/v1/assets" \
		-H "@${HEADERS}" \
		-F "request=${request};type=application/json" \
		-F "fileContent=@${png};type=image/png" || true)"
	operation="$(printf '%s' "$response" | json operationId)"
	if [ -z "$operation" ]; then
		operation="$(printf '%s' "$response" | json path | sed 's|^operations/||')"
	fi
	if [ -z "$operation" ]; then
		echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
		return 1
	fi
	for _ in $(seq 1 45); do
		sleep 2
		response="$(curl -sS "https://apis.roblox.com/assets/v1/operations/${operation}" -H "@${HEADERS}" || true)"
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
UPLOADED=0
for name in "${NAMES[@]}"; do
	if [ "$FORCE" = 0 ] && [ -n "${KNOWN[$name]:-}" ]; then
		echo "  = $name ya subido (${KNOWN[$name]})"
		continue
	fi
	if id="$(upload "$name")"; then
		KNOWN["$name"]="rbxassetid://${id}"
		UPLOADED=$((UPLOADED + 1))
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

{
	echo "-- OutfitIds: GENERADO por scripts/upload-outfits.sh (no editar a mano)."
	echo "-- Plantilla de ropa clásica subida a Roblox (\"rbxassetid://…\") por conjunto: o01_shirt, o01_pants…"
	echo "-- Un conjunto usa sus plantillas solo si tiene las dos; si no, OutfitBuilder lo viste con colores y piezas."
	if [ "${#KNOWN[@]}" -eq 0 ]; then
		echo "return {} :: { [string]: string }"
	else
		echo "return {"
		for key in $(printf '%s\n' "${!KNOWN[@]}" | sort); do
			echo "	${key} = \"${KNOWN[$key]}\","
		done
		echo "} :: { [string]: string }"
	fi
} > "$IDS"
echo "📄 $IDS con ${#KNOWN[@]} plantillas (${UPLOADED} nuevas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED no se pudieron subir (vuelve a lanzar el script: solo sube las que faltan)"
	exit 1
fi
echo "✅ Listo. Reconstruye el juego para que los conjuntos usen sus plantillas."
