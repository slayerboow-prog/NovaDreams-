#!/usr/bin/env bash
# Sube los edificios y objetos de calle de las ciudades de los planetas (assets/ciudades, hechas con
# scripts/planetas/edificios_blender.py) a Roblox con Open Cloud y escribe src/shared/Cosmos/CiudadAssetIds.luau.
# Cada FBX lleva varias mallas (una por material): Roblox lo convierte en un Model con varias MeshPart.
#
#   1. Texturas (assets/planetas/tex/*.png, si las hay) como Decal -> id de la IMAGEN (si la clave no puede
#      leer el decal, se guarda el del decal y el juego lo pasa a imagen con shared/Images)
#   2. Cada monumento (assets/planetas/<Kind>.fbx: Palacio, Puerta, ArbolMadre, TorreAnillos, Reactor, Ciudadela, ReactorVerde) como
#      Model -> "Mallas" (una MeshPart por material). El juego lo pone en lugar de las piezas (World/PlanetMetroMeshes).
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox (el dueño de los assets). Si no está, se
#                            mira de quién es el juego (ROBLOX_UNIVERSE_ID, como scripts/publish.sh); para
#                            eso la clave necesita también "universe: read".
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo, el id del grupo
#   Los assets tienen que ser del MISMO dueño que el juego: si no, el servidor no puede cargarlos.
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-ciudades.sh            sube lo que aún no tiene id
#   bash scripts/upload-ciudades.sh --force    vuelve a subirlo todo
#
# Después: commit + push de src/shared/Cosmos/CiudadAssetIds.luau y publicar (scripts/publish.sh).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/Cosmos/CiudadAssetIds.luau"
DIR="assets/ciudades"
FORCE=0
for arg in "$@"; do
	case "$arg" in
		--force) FORCE=1 ;;
		-h | --help) sed -n '2,23p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $arg"; exit 1 ;;
	esac
done

if [ ! -f "$DIR/manifest.json" ]; then
	echo "❌ No están las mallas en $DIR. Créalas con: blender -b --python scripts/planetas/edificios_blender.py"
	exit 1
fi
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir assets)."
	echo "   Créala en create.roblox.com → Open Cloud → API Keys y ponla así:  export ROBLOX_API_KEY=…"
	exit 1
fi
KINDS="$(python3 -c "import json;print(' '.join(json.load(open('assets/ciudades/manifest.json',encoding='utf-8')).keys()))" | tr -d '')"
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
trap 'rm -f "$HEADERS"' EXIT
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
		echo "❌ No sé a nombre de quién subir las mallas (falta ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID,"
		echo "   o el permiso «universe: read» de la clave para saber el dueño del juego ${UNIVERSE})."
		exit 1
	fi
fi
echo "👤 Dueño de las mallas: ${CREATOR}"

# Ids que ya había (sección.nombre -> id)
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
	echo "  ⚠️  no se encontró la imagen del decal ${decal}; se guarda el del decal (shared/Images lo resuelve en el juego)" >&2
	echo "$decal"
}

upload_once() { # upload_once <archivo> <tipo Decal|Model> <mime> <nombre> -> escribe el id
	local file="$1" type="$2" mime="$3" name="$4" request response operation done_ assetId
	request="$(printf '{"assetType":"%s","displayName":"Ciudad %s","description":"Edificio de las ciudades de los planetas de Heroes of History (%s)","creationContext":{"creator":%s}}' "$type" "$name" "$name" "$CREATOR")"
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
for kind in $KINDS; do
	if [ -f "$DIR/$kind.fbx" ] && [ -z "${MALLAS[$kind]:-}" ]; then
		PENDIENTES+=("$DIR/$kind.fbx")
	fi
done
revisar_mallas "${PENDIENTES[@]}"

FAILED=0
if compgen -G "$DIR/tex/*.png" >/dev/null; then
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
fi

echo "🏙 Edificios y objetos de calle (FBX)"
for kind in $KINDS; do
	file="$DIR/$kind.fbx"
	[ -f "$file" ] || { echo "  ⚠️  falta $file"; FAILED=$((FAILED + 1)); continue; }
	if [ -n "${MALLAS[$kind]:-}" ]; then
		echo "  = $kind ya subida (${MALLAS[$kind]})"
		continue
	fi
	if id="$(upload "$file" Model model/fbx "$kind")"; then
		MALLAS["$kind"]="rbxassetid://${id}"
		echo "  ✅ $kind -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# Escribir shared/Cosmos/CiudadAssetIds.luau (lo que haya, aunque algo fallara)
{
	echo "-- CiudadAssetIds: GENERADO por scripts/upload-ciudades.sh (no editar a mano)."
	echo "-- Los ids de los edificios de las ciudades hechos con Blender (scripts/planetas/edificios_blender.py):"
	echo "--   Mallas    \"<Kind>\" -> Model con una MeshPart por material (edificios por secciones y objetos de calle; World/PlanetCityMeshes)"
	echo "--   Texturas  \"<nombre>\" -> imagen (los Decal se pasan a imagen con shared/Images)"
	echo "-- Vacío hasta que se suban: mientras tanto se ven los de piezas (World/PlanetMetroBuilder)."
	echo "return {"
	echo "	Mallas = {"
	for kind in $KINDS; do
		echo "		${kind} = \"${MALLAS[$kind]:-}\","
	done
	echo "	},"
	echo "	Texturas = {"
	for name in $(printf '%s\n' "${!TEXTURAS[@]}" | sort); do
		echo "		${name} = \"${TEXTURAS[$name]}\","
	done
	echo "	},"
	echo "}"
} > "$IDS"
echo "📝 $IDS escrito"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED cosas no se pudieron subir (vuelve a lanzar el script: solo sube lo que falta)"
	exit 1
fi
echo "✅ Listo. Ahora: commit + push de $IDS y publicar (bash scripts/publish.sh)."
