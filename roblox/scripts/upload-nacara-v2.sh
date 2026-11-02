#!/usr/bin/env bash
# Sube las texturas y los ornamentos de Nácara v2 (assets/nacara-v2: scripts/map/nacara_v2_texturas.py y
# nacara_v2_ornamentos.py) a Roblox con Open Cloud y escribe src/shared/Sea/NacaraV2AssetIds.luau. Como
# scripts/upload-mar.sh. SOLO en la sesión que publica (no en las pruebas). Diseño: docs/mar/nacara-v2/diseno.md.
#
#   1. Texturas (assets/nacara-v2/tex/*.png: color, normal, rugosidad y metal de 8 texturas, 512 px, y el atlas
#      «ornamentos_*» de 1024) como Decal -> id de la IMAGEN (si la clave no puede leer el Decal se guarda el
#      del Decal y el juego lo pasa a imagen con shared/Images; build-place.luau usa shared/TextureImageIds)
#   2. Cada ornamento (assets/nacara-v2/<Ornamento>.fbx) como Model -> "Mallas". ANTES pasan la revisión de
#      moderación (scripts/audit/moderacion-mallas.py --check): si alguna sale marcada no se sube ninguna.
# El juego: los MaterialVariant «NV2_…» los mete scripts/build-place.luau en el archivo (un Script no puede
# escribir sus mapas) y World/NacaraV2Look carga los ornamentos. Sin ids, Nácara v2 (apagado) usa colores lisos.
#
# Hace falta (variables de entorno): ROBLOX_API_KEY (no se enseña nunca) y, si hace falta,
# ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID (los assets, del MISMO dueño que el juego).
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-nacara-v2.sh            sube lo que aún no tiene id
#   bash scripts/upload-nacara-v2.sh --force    vuelve a subirlo todo
#
# Después: commit + push de src/shared/Sea/NacaraV2AssetIds.luau, bash scripts/textures/image-ids.sh (si hace
# falta) y publicar (scripts/publish.sh).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/Sea/NacaraV2AssetIds.luau"
DIR="assets/nacara-v2"
FORCE=0
for arg in "$@"; do
	case "$arg" in
		--force) FORCE=1 ;;
		-h | --help) sed -n '2,25p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $arg"; exit 1 ;;
	esac
done

if [ ! -f "$DIR/manifest.json" ]; then
	echo "❌ No están las texturas de Nácara v2 en $DIR. Créalo con: python3 scripts/map/nacara_v2_texturas.py y nacara_v2_ornamentos.py (pip install bpy==4.2.0)"
	exit 1
fi

# ---------------------------------------------------------------------------
# Clave y dueño
# ---------------------------------------------------------------------------
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir assets)."
	echo "   Créala en create.roblox.com → Open Cloud → API Keys y ponla así:  export ROBLOX_API_KEY=…"
	exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "❌ Hace falta curl"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Hace falta python3 (para leer las respuestas de Roblox)"; exit 1; }

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
WORK="$(mktemp -d)"
trap 'rm -rf "$HEADERS" "$WORK"' EXIT
chmod 600 "$HEADERS"
printf 'x-api-key: %s\n' "$ROBLOX_API_KEY" > "$HEADERS"

UNIVERSE="${ROBLOX_UNIVERSE_ID:-10767975237}" # Heroes of History (el mismo que scripts/publish.sh)
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
		echo "❌ No sé a nombre de quién subir Nácara v2 (falta ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID,"
		echo "   o el permiso «universe: read» de la clave para saber el dueño del juego ${UNIVERSE})."
		exit 1
	fi
fi
echo "👤 Dueño de Nácara v2: ${CREATOR}"

# ---------------------------------------------------------------------------
# Ids que ya había (sección.nombre -> id)
# ---------------------------------------------------------------------------
declare -A MALLAS=()
declare -A TEXTURAS=()
if [ -f "$IDS" ] && [ "$FORCE" = 0 ]; then
	section=""
	while IFS= read -r line; do
		case "$line" in
			*"Mallas = {"*) section="M" ;;
			*"Texturas = {"*) section="T" ;;
		esac
		if [[ "$line" =~ ^[[:space:]]+([A-Za-z0-9_]+)\ =\ \"(rbxassetid://[0-9]+)\" ]]; then
			if [ "$section" = "M" ]; then MALLAS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; fi
			if [ "$section" = "T" ]; then TEXTURAS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; fi
		fi
	done < "$IDS"
fi

# ---------------------------------------------------------------------------
# Subir (Open Cloud Assets API) con reintentos
# ---------------------------------------------------------------------------
image_of_decal() {
	local decal="$1" xml image
	for _ in 1 2 3; do
		xml="$(curl -sS -L "https://assetdelivery.roblox.com/v1/asset/?id=${decal}" -H "@${HEADERS}" 2>/dev/null || true)"
		image="$(printf '%s' "$xml" | grep -oE 'id=[0-9]+' | head -1 | cut -d= -f2 || true)"
		if [ -n "$image" ]; then
			echo "$image"
			return 0
		fi
		sleep 3
	done
	echo "  ⚠️  no se encontró la imagen del decal ${decal}; se guarda el id del decal" >&2
	echo "$decal"
}

upload_once() { # upload_once <archivo> <tipo Decal|Model> <mime> <nombre> -> escribe el id
	local file="$1" type="$2" mime="$3" name="$4" request response operation done_ assetId
	request="$(printf '{"assetType":"%s","displayName":"Nacara %s","description":"Nacara v2 de Heroes of History (%s)","creationContext":{"creator":%s}}' "$type" "$name" "$name" "$CREATOR")"
	response="$(curl -sS -X POST "https://apis.roblox.com/assets/v1/assets" \
		-H "@${HEADERS}" \
		-F "request=${request};type=application/json" \
		-F "fileContent=@${file};type=${mime}" || true)"
	operation="$(printf '%s' "$response" | json operationId)"
	if [ -z "$operation" ]; then
		operation="$(printf '%s' "$response" | json path | sed 's|^operations/||')"
	fi
	if [ -z "$operation" ]; then
		echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
		return 1
	fi
	for _ in $(seq 1 90); do
		sleep 2
		response="$(curl -sS "https://apis.roblox.com/assets/v1/operations/${operation}" -H "@${HEADERS}" || true)"
		done_="$(printf '%s' "$response" | json done)"
		if [ "$done_" = "True" ] || [ "$done_" = "true" ]; then
			assetId="$(printf '%s' "$response" | json response.assetId)"
			if [ -n "$assetId" ]; then
				if [ "$type" = "Decal" ]; then image_of_decal "$assetId"; else echo "$assetId"; fi
				return 0
			fi
			echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
			return 1
		fi
	done
	echo "  ❌ $name: Roblox tarda demasiado (operación ${operation})" >&2
	return 1
}

upload() {
	local attempt
	for attempt in 1 2 3; do
		if upload_once "$@"; then
			return 0
		fi
		[ "$attempt" -lt 3 ] && { echo "  … reintento $((attempt + 1)) de $4 en $((attempt * 10)) s" >&2; sleep $((attempt * 10)); }
	done
	return 1
}

# Revisión de moderación (scripts/lib/revisar-mallas.sh, docs/bugs/moderacion/): las mallas que se van a
# subir, antes de subir NADA; si alguna está marcada, para aquí.
source scripts/lib/revisar-mallas.sh
PENDIENTES=()
for file in "$DIR"/*.fbx; do
	name="$(basename "$file" .fbx)"
	[ -n "${MALLAS[$name]:-}" ] || PENDIENTES+=("$file")
done
revisar_mallas "${PENDIENTES[@]}"

FAILED=0
echo "🖼️  Texturas"
for file in "$DIR"/tex/*.png; do
	name="$(basename "$file" .png)"
	if [ -n "${TEXTURAS[$name]:-}" ]; then
		echo "  = $name ya subida (${TEXTURAS[$name]})"
		continue
	fi
	if id="$(upload "$file" Decal image/png "$name")"; then
		TEXTURAS["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

echo "🪸 Mallas (FBX)"
for file in "$DIR"/*.fbx; do
	name="$(basename "$file" .fbx)"
	if [ -n "${MALLAS[$name]:-}" ]; then
		echo "  = $name ya subida (${MALLAS[$name]})"
		continue
	fi
	if id="$(upload "$file" Model model/fbx "$name")"; then
		MALLAS["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# ---------------------------------------------------------------------------
# NacaraV2AssetIds.luau (generado)
# ---------------------------------------------------------------------------
{
	echo "-- NacaraV2AssetIds: GENERADO por scripts/upload-nacara-v2.sh (no editar a mano)."
	echo "-- Los ids de las texturas y los ornamentos de Nácara v2 (assets/nacara-v2):"
	echo "--   Mallas    \"<Ornamento>\" -> Model de cada FBX (una MeshPart dentro); Ornamento = shared/Sea/NacaraV2.Ornaments"
	echo "--   Texturas  \"<textura>_<mapa>\" -> imagen (color, normal, roughness, metalness) y \"ornamentos_<mapa>\" (el atlas)"
	echo "-- Vacío hasta que se suban: mientras tanto Nácara v2 usa los colores lisos y las piezas de respaldo."
	echo "return {"
	echo "	Mallas = {"
	for key in $(printf '%s\n' "${!MALLAS[@]}" | sort); do
		echo "		${key} = \"${MALLAS[$key]}\","
	done
	echo "	},"
	echo "	Texturas = {"
	for key in $(printf '%s\n' "${!TEXTURAS[@]}" | sort); do
		echo "		${key} = \"${TEXTURAS[$key]}\","
	done
	echo "	},"
	echo "} :: { Mallas: { [string]: string }, Texturas: { [string]: string } }"
} > "$IDS"
echo "📄 $IDS escrito (${#MALLAS[@]} mallas, ${#TEXTURAS[@]} texturas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED cosas no se pudieron subir (vuelve a lanzar el script: solo sube lo que falta)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para ver Nácara v2 con texturas."
