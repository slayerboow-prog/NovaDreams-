#!/usr/bin/env bash
# Sube los personajes 3D propios del reparto (assets/personajes3d, hechos con
# scripts/personajes/personajes3d_blender.py) a Roblox con Open Cloud y escribe
# src/shared/Personajes3DAssetIds.luau. SOLO en la sesión que publica (no en las pruebas).
# Documentación: docs/personajes/3d/README.md.
#
#   0. ANTES DE NADA: la revisión de moderación (scripts/lib/revisar-mallas.sh ->
#      scripts/audit/moderacion-mallas.py --check) de cada FBX que se va a subir. Si alguna malla sale
#      marcada, no se sube NINGUNA (docs/bugs/moderacion/: cada aviso es una falta en la cuenta).
#      Mira también la «vista gris» de cada malla en docs/personajes/3d/revision-gris/.
#   1. Texturas (assets/personajes3d/tex/*.png) como Decal -> id de la imagen
#   2. Cada personaje (assets/personajes3d/Personaje3D_<Key>.fbx: Cuerpo + CuerpoLOD con su esqueleto)
#      como Model -> "Modelos"
#
# Hace falta (variables de entorno, como scripts/upload-invasion.sh):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox; si no, el dueño del juego
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-personajes3d.sh                  sube lo que aún no tiene id
#   bash scripts/upload-personajes3d.sh --solo Cosme     solo ese personaje (Personaje3D_Cosme*)
#   bash scripts/upload-personajes3d.sh --force          vuelve a subirlo todo
#
# Después: commit + push de src/shared/Personajes3DAssetIds.luau y publicar (scripts/publish.sh).
# Si algo no se sube (o la moderación lo retira: World/MallasRetiradas), ese personaje sigue con
# CastLook (bloques con textura): nunca se queda sin cuerpo.
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/Personajes3DAssetIds.luau"
DIR="assets/personajes3d"
FORCE=0
SOLO=""
while [ "$#" -gt 0 ]; do
	case "$1" in
		--force) FORCE=1 ;;
		--solo=*) SOLO="${1#--solo=}" ;;
		--solo) shift; SOLO="${1:-}" ;;
		-h | --help) sed -n '2,27p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $1"; exit 1 ;;
	esac
	shift
done
wanted() { # wanted <nombre>: ¿entra en --solo? (claves separadas por comas: Cosme,Nico)
	[ -z "$SOLO" ] && return 0
	local key
	local -a keys
	IFS=',' read -r -a keys <<< "$SOLO"
	for key in "${keys[@]}"; do
		[ -n "$key" ] && [[ "$1" == "Personaje3D_${key}"* ]] && return 0
	done
	return 1
}

if [ ! -f "$DIR/manifest.json" ]; then
	echo "❌ No están los personajes en $DIR. Créalos con: python3 scripts/personajes/personajes3d_blender.py (pip install bpy==4.2.0)"
	exit 1
fi
command -v python3 >/dev/null 2>&1 || { echo "❌ Hace falta python3"; exit 1; }

# ---------------------------------------------------------------------------
# Ids que ya había (sección.nombre -> id)
# ---------------------------------------------------------------------------
declare -A MODELOS=()
declare -A TEXTURAS=()
if [ -f "$IDS" ] && [ "$FORCE" = 0 ]; then
	section=""
	while IFS= read -r line; do
		case "$line" in
			*"Modelos = {"*) section="M" ;;
			*"Texturas = {"*) section="T" ;;
		esac
		if [[ "$line" =~ ^[[:space:]]+([A-Za-z0-9_]+)\ =\ \"(rbxassetid://[0-9]+)\" ]]; then
			case "$section" in
				M) MODELOS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}" ;;
				T) TEXTURAS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}" ;;
			esac
		fi
	done < "$IDS"
fi

# Revisión de moderación ANTES de pedir la clave o subir nada (scripts/lib/revisar-mallas.sh)
source scripts/lib/revisar-mallas.sh
PENDIENTES=()
for file in "$DIR"/*.fbx; do
	[ -f "$file" ] || continue
	name="$(basename "$file" .fbx)"
	wanted "$name" || continue
	[ -n "${MODELOS[$name]:-}" ] || PENDIENTES+=("$file")
done
revisar_mallas "${PENDIENTES[@]}"

if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir assets)."
	echo "   Créala en create.roblox.com → Open Cloud → API Keys y ponla así:  export ROBLOX_API_KEY=…"
	exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "❌ Hace falta curl"; exit 1; }

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
		echo "❌ No sé a nombre de quién subirlo (falta ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID,"
		echo "   o el permiso «universe: read» de la clave para saber el dueño del juego ${UNIVERSE})."
		exit 1
	fi
fi
echo "👤 Dueño: ${CREATOR}"

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
	request="$(printf '{"assetType":"%s","displayName":"Reparto %s","description":"Personaje de Heroes of History (%s)","creationContext":{"creator":%s}}' "$type" "$name" "$name" "$CREATOR")"
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
	for attempt in 1 2 3 4; do
		if upload_once "$@"; then
			return 0
		fi
		[ "$attempt" -lt 4 ] && { echo "  … reintento $((attempt + 1)) de $4 en $((attempt * 15)) s" >&2; sleep $((attempt * 15)); }
	done
	return 1
}

write_ids() {
	{
		echo "-- Personajes3DAssetIds: GENERADO por scripts/upload-personajes3d.sh (no editar a mano)."
		echo "-- Los ids de los personajes 3D propios subidos a Roblox (assets/personajes3d, hechos con"
		echo "-- scripts/personajes/personajes3d_blender.py):"
		echo "--   Modelos    \"Personaje3D_<Key>\" -> Model del FBX (la MeshPart Cuerpo y CuerpoLOD con sus Bone)"
		echo "--   Texturas   \"Personaje3D_<Key>_<mapa>\" -> imagen (color, normal, rugosidad)"
		echo "-- Vacío hasta que se suban: mientras tanto el reparto sale con CastLook (bloques con textura) de siempre."
		echo "return {"
		echo "	Modelos = {"
		for key in $(printf '%s\n' "${!MODELOS[@]}" | sort); do
			echo "		${key} = \"${MODELOS[$key]}\","
		done
		echo "	},"
		echo "	Texturas = {"
		for key in $(printf '%s\n' "${!TEXTURAS[@]}" | sort); do
			echo "		${key} = \"${TEXTURAS[$key]}\","
		done
		echo "	},"
		echo "} :: { Modelos: { [string]: string }, Texturas: { [string]: string } }"
	} > "$IDS"
}

FAILED=0
echo "🖼️  Texturas"
for file in "$DIR"/tex/*.png; do
	[ -f "$file" ] || continue
	name="$(basename "$file" .png)"
	wanted "$name" || continue
	if [ -n "${TEXTURAS[$name]:-}" ]; then
		echo "  = $name ya subida (${TEXTURAS[$name]})"
		continue
	fi
	if id="$(upload "$file" Decal image/png "$name")"; then
		TEXTURAS["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
		write_ids
	else
		FAILED=$((FAILED + 1))
	fi
done

echo "🧍 Personajes (FBX)"
for file in "${PENDIENTES[@]}"; do
	name="$(basename "$file" .fbx)"
	if id="$(upload "$file" Model model/fbx "$name")"; then
		MODELOS["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
		write_ids
	else
		FAILED=$((FAILED + 1))
	fi
done

write_ids
echo "📄 $IDS escrito (${#MODELOS[@]} personajes, ${#TEXTURAS[@]} texturas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED cosas no se pudieron subir (vuelve a lanzar el script: solo sube lo que falta)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para ver a los personajes 3D."
