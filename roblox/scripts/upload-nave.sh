#!/usr/bin/env bash
# Sube la nave realista «HX-7 Halcón» (assets/nave, hecha con scripts/nave/nave_blender.py) a Roblox con
# Open Cloud y escribe src/shared/AirCombat/NaveAssetIds.luau. SOLO en la sesión que publica (no en las
# pruebas). Documentación: docs/espacio-aaa/nave-realista.md
#
#   1. Texturas (assets/nave/tex/*.png) como Decal -> id de la imagen ("casco_color" -> "rbxassetid://…")
#   2. Cada pieza (assets/nave/<Pieza>.fbx) como Model -> "Piezas" (una MeshPart dentro de cada uno)
#   3. (si hay Lune) Descarga esos Model, monta uno solo con todas las MeshPart en su sitio y su
#      SurfaceAppearance (color, normal, rugosidad y metal: scripts/nave/compose.luau) y lo sube como
#      Model -> "Completa". Si esta fase falla, el juego usa las piezas sueltas con su textura de color.
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
#   bash scripts/upload-nave.sh              sube lo que aún no tiene id
#   bash scripts/upload-nave.sh --force      vuelve a subirlo todo
#   bash scripts/upload-nave.sh --sin-fase3  solo texturas y piezas (sin el Model completo)
#
# Después: commit + push de src/shared/AirCombat/NaveAssetIds.luau y publicar (scripts/publish.sh).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/AirCombat/NaveAssetIds.luau"
DIR="assets/nave"
FORCE=0
PHASE3=1
for arg in "$@"; do
	case "$arg" in
		--force) FORCE=1 ;;
		--sin-fase3) PHASE3=0 ;;
		-h | --help) sed -n '2,27p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $arg"; exit 1 ;;
	esac
done

if [ ! -f "$DIR/manifest.json" ]; then
	echo "❌ No está la nave en $DIR. Créala con: python3 scripts/nave/nave_blender.py (pip install bpy==4.2.0)"
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
		echo "❌ No sé a nombre de quién subir la nave (falta ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID,"
		echo "   o el permiso «universe: read» de la clave para saber el dueño del juego ${UNIVERSE})."
		exit 1
	fi
fi
echo "👤 Dueño de la nave: ${CREATOR}"

# ---------------------------------------------------------------------------
# Ids que ya había (sección.nombre -> id)
# ---------------------------------------------------------------------------
declare -A PIEZAS=()
declare -A TEXTURAS=()
COMPLETA=""
if [ -f "$IDS" ] && [ "$FORCE" = 0 ]; then
	section=""
	while IFS= read -r line; do
		case "$line" in
			*"Piezas = {"*) section="P" ;;
			*"Texturas = {"*) section="T" ;;
			*"Completa = \"rbxassetid://"*) COMPLETA="$(printf '%s' "$line" | grep -oE 'rbxassetid://[0-9]+' || true)" ;;
		esac
		if [[ "$line" =~ ^[[:space:]]+([A-Za-z0-9_]+)\ =\ \"(rbxassetid://[0-9]+)\" ]]; then
			if [ "$section" = "P" ]; then PIEZAS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"; fi
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
	request="$(printf '{"assetType":"%s","displayName":"HX-7 %s","description":"Nave HX-7 Halcón de Heroes of History (%s)","creationContext":{"creator":%s}}' "$type" "$name" "$name" "$CREATOR")"
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
	[ -n "${PIEZAS[$name]:-}" ] || PENDIENTES+=("$file")
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

echo "🚀 Piezas (FBX)"
CHANGED=0
for file in "$DIR"/*.fbx; do
	name="$(basename "$file" .fbx)"
	if [ -n "${PIEZAS[$name]:-}" ]; then
		echo "  = $name ya subida (${PIEZAS[$name]})"
		continue
	fi
	if id="$(upload "$file" Model model/fbx "$name")"; then
		PIEZAS["$name"]="rbxassetid://${id}"
		CHANGED=1
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# Fase 3: el Model completo con SurfaceAppearance (necesita Lune: https://lune-org.github.io/docs)
if [ "$PHASE3" = 1 ] && { [ -z "$COMPLETA" ] || [ "$CHANGED" = 1 ]; } && [ "$FAILED" = 0 ]; then
	if command -v lune >/dev/null 2>&1; then
		echo "🧩 Model completo (MeshPart + SurfaceAppearance)"
		ok=1
		for name in "${!PIEZAS[@]}"; do
			id="${PIEZAS[$name]#rbxassetid://}"
			if ! curl -sS -L --fail "https://assetdelivery.roblox.com/v1/asset/?id=${id}" -H "@${HEADERS}" -o "$WORK/${name}.rbxm" 2>/dev/null; then
				echo "  ⚠️  no se pudo descargar ${name} (${id})"
				ok=0
			fi
		done
		if [ "$ok" = 1 ]; then
			: > "$WORK/texturas.txt"
			for key in "${!TEXTURAS[@]}"; do
				printf '%s=%s\n' "$key" "${TEXTURAS[$key]}" >> "$WORK/texturas.txt"
			done
			if lune run scripts/nave/compose.luau "$WORK" "$DIR/manifest.json" "$WORK/texturas.txt" "$WORK/NaveHX7.rbxm"; then
				if id="$(upload "$WORK/NaveHX7.rbxm" Model model/x-rbxm "Completa")"; then
					COMPLETA="rbxassetid://${id}"
					echo "  ✅ Completa -> ${COMPLETA}"
				else
					echo "  ⚠️  no se pudo subir el Model completo (el juego usará las piezas sueltas)"
				fi
			fi
		fi
	else
		echo "ℹ️  Sin Lune no se monta el Model completo: el juego usará las piezas sueltas con su textura de color."
	fi
fi

# ---------------------------------------------------------------------------
# NaveAssetIds.luau (generado)
# ---------------------------------------------------------------------------
{
	echo "-- NaveAssetIds: GENERADO por scripts/upload-nave.sh (no editar a mano)."
	echo "-- Los ids de la nave realista «HX-7 Halcón» subida a Roblox (assets/nave, hecha con"
	echo "-- scripts/nave/nave_blender.py):"
	echo "--   Completa  un Model con todas las MeshPart y su SurfaceAppearance (la fase 3 del script, con Lune)"
	echo "--   Piezas    \"<Pieza>\" -> Model de cada FBX (una MeshPart dentro)"
	echo "--   Texturas  \"<juego>_<mapa>\" -> imagen (casco/alas/motores: color, normal, rugosidad, metal; lod: color)"
	echo "-- Vacío hasta que se suban: mientras tanto el juego usa la nave hecha con piezas (shared/AirCombat/ShipModel)."
	echo "return {"
	echo "	Completa = \"${COMPLETA}\","
	echo "	Piezas = {"
	for key in $(printf '%s\n' "${!PIEZAS[@]}" | sort); do
		echo "		${key} = \"${PIEZAS[$key]}\","
	done
	echo "	},"
	echo "	Texturas = {"
	for key in $(printf '%s\n' "${!TEXTURAS[@]}" | sort); do
		echo "		${key} = \"${TEXTURAS[$key]}\","
	done
	echo "	},"
	echo "} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }"
} > "$IDS"
echo "📄 $IDS escrito (${#PIEZAS[@]} piezas, ${#TEXTURAS[@]} texturas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED cosas no se pudieron subir (vuelve a lanzar el script: solo sube lo que falta)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para volar con la nave realista."
