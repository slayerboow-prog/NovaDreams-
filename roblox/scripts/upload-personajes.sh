#!/usr/bin/env bash
# Sube las texturas del reparto de la historia (assets/personajes/**/*.png, hechas con
# scripts/personajes/gen.py: caras de cada personaje con sus expresiones, plantillas de ropa compartidas y
# los mechones del pelo) a Roblox con Open Cloud (como Decal) y, al acabar, escribe
# src/shared/PersonajesTextureIds.luau con el id de cada imagen ("pj_cara_nico_happy" -> "rbxassetid://…").
# shared/LifeStory/CastLook las usa en cuanto están; mientras falten, cada personaje se ve como antes.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox, el dueño de las imágenes.
#                            Si no está, se mira de quién es el juego (ROBLOX_UNIVERSE_ID, el mismo de
#                            scripts/publish.sh); para eso la clave necesita también "universe: read".
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo, el id del grupo
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-personajes.sh                       sube todas las que aún no tienen id
#   bash scripts/upload-personajes.sh --grupo Ropa,Saga1    solo esos grupos (orden recomendado: Ropa,
#                                                           Saga1, Saga2, Nacara, Otros; ver
#                                                           assets/personajes/grupos.txt)
#   bash scripts/upload-personajes.sh --force               vuelve a subirlas todas
#   bash scripts/upload-personajes.sh pj_cara_nico_happy    solo esa
#   bash scripts/upload-personajes.sh --lista               dice qué subiría (sin subir nada ni pedir clave)
#
# Son ~500 imágenes pequeñas (caras de 256/512 px en PNG de paleta; ropa 585x559): se pueden subir por
# grupos en varios días; el script siempre continúa donde lo dejó.
# Moderación (docs/bugs/moderacion/): SOLO imágenes de caras y de ropa (nada de cuerpos sin ropa). Si algún
# día hay mallas en assets/personajes, pasan antes por scripts/audit/moderacion-mallas.py y las marcadas no
# se suben.
#
# Después: commit + push de src/shared/PersonajesTextureIds.luau y publicar (scripts/publish.sh).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/PersonajesTextureIds.luau"
GROUPS_FILE="assets/personajes/grupos.txt"
FORCE=0
LIST=0
ONLY=()
WANT_GROUPS=""
while [ $# -gt 0 ]; do
	case "$1" in
		--force) FORCE=1 ;;
		--lista) LIST=1 ;;
		--grupo) shift; WANT_GROUPS="${1:-}" ;;
		--grupo=*) WANT_GROUPS="${1#--grupo=}" ;;
		-h | --help) sed -n '2,30p' "$0"; exit 0 ;;
		-*) echo "Opción desconocida: $1"; exit 1 ;;
		*) ONLY+=("$1") ;;
	esac
	shift
done

# ---------------------------------------------------------------------------
# Qué archivos se suben
# ---------------------------------------------------------------------------
if ! ls assets/personajes/caras/pj_*.png >/dev/null 2>&1; then
	echo "❌ No hay texturas en assets/personajes/. Créalas con:"
	echo "   lune run scripts/personajes/export.luau && python3 scripts/personajes/gen.py"
	exit 1
fi

# Mallas (no hay ninguna hoy): revisión de moderación antes de nada
MESHES=()
while IFS= read -r -d '' mesh; do
	MESHES+=("$mesh")
done < <(find assets/personajes -type f \( -iname '*.fbx' -o -iname '*.obj' \) -print0 2>/dev/null)
if [ "${#MESHES[@]}" -gt 0 ]; then
	# shellcheck source=lib/revisar-mallas.sh
	source scripts/lib/revisar-mallas.sh
	revisar_mallas "${MESHES[@]}" || { echo "❌ Mallas marcadas por la revisión de moderación: no se sube nada."; exit 2; }
fi

declare -A GROUP_OF=()
if [ -f "$GROUPS_FILE" ]; then
	while read -r name group; do
		case "$name" in "#"* | "") continue ;; esac
		GROUP_OF["$name"]="$group"
	done < "$GROUPS_FILE"
fi

FILES=()
while IFS= read -r file; do
	name="$(basename "$file" .png)"
	if [ -n "$WANT_GROUPS" ]; then
		group="${GROUP_OF[$name]:-Otros}"
		[[ ",${WANT_GROUPS}," == *",${group},"* ]] || continue
	fi
	if [ "${#ONLY[@]}" -gt 0 ] && [[ ! " ${ONLY[*]} " == *" $name "* ]]; then
		continue
	fi
	FILES+=("$file")
done < <(find assets/personajes -type f -name 'pj_*.png' | sort)

# Ids que ya había (nombre -> id)
declare -A KNOWN=()
if [ -f "$IDS" ]; then
	while IFS='=' read -r key value; do
		KNOWN["$key"]="$value"
	done < <(grep -oE '^\s*[a-z0-9_]+ = "rbxassetid://[0-9]+"' "$IDS" | sed -E 's/^\s*([a-z0-9_]+) = "(rbxassetid:\/\/[0-9]+)"/\1=\2/')
fi

PENDING=()
for file in "${FILES[@]}"; do
	name="$(basename "$file" .png)"
	if [ "$FORCE" = 0 ] && [ -n "${KNOWN[$name]:-}" ]; then
		continue
	fi
	PENDING+=("$file")
done
echo "🖼️  ${#FILES[@]} texturas elegidas, ${#PENDING[@]} por subir (${#KNOWN[@]} ya con id)"
if [ "$LIST" = 1 ]; then
	for file in "${PENDING[@]}"; do
		name="$(basename "$file" .png)"
		echo "  · $name (${GROUP_OF[$name]:-Otros})"
	done
	exit 0
fi
if [ "${#PENDING[@]}" -eq 0 ]; then
	echo "✅ Nada que subir."
	exit 0
fi

# ---------------------------------------------------------------------------
# Clave y dueño de las imágenes
# ---------------------------------------------------------------------------
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir imágenes)."
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
trap 'rm -f "$HEADERS"' EXIT
chmod 600 "$HEADERS"
printf 'x-api-key: %s\n' "$ROBLOX_API_KEY" > "$HEADERS"

UNIVERSE="${ROBLOX_UNIVERSE_ID:-10767975237}" # Heroes of History (el mismo que scripts/publish.sh)
CREATOR=""
if [ -n "${ROBLOX_CREATOR_USER_ID:-}" ]; then
	CREATOR="$(printf '{"userId":"%s"}' "$ROBLOX_CREATOR_USER_ID")"
	echo "👤 Dueño de las texturas: usuario ${ROBLOX_CREATOR_USER_ID}"
elif [ -n "${ROBLOX_CREATOR_GROUP_ID:-}" ]; then
	CREATOR="$(printf '{"groupId":"%s"}' "$ROBLOX_CREATOR_GROUP_ID")"
	echo "👥 Dueño de las texturas: grupo ${ROBLOX_CREATOR_GROUP_ID}"
else
	universe="$(curl -sS "https://apis.roblox.com/cloud/v2/universes/${UNIVERSE}" -H "@${HEADERS}" 2>/dev/null || true)"
	owner_user="$(printf '%s' "$universe" | json user | sed -n 's|^users/\([0-9][0-9]*\)$|\1|p')"
	owner_group="$(printf '%s' "$universe" | json group | sed -n 's|^groups/\([0-9][0-9]*\)$|\1|p')"
	if [ -n "$owner_user" ]; then
		CREATOR="$(printf '{"userId":"%s"}' "$owner_user")"
		echo "👤 Dueño de las texturas: usuario ${owner_user} (el dueño del juego ${UNIVERSE})"
	elif [ -n "$owner_group" ]; then
		CREATOR="$(printf '{"groupId":"%s"}' "$owner_group")"
		echo "👥 Dueño de las texturas: grupo ${owner_group} (el dueño del juego ${UNIVERSE})"
	else
		echo "❌ No sé a nombre de quién subir las texturas."
		echo "   Solución: export ROBLOX_CREATOR_USER_ID=<tu id> (o ROBLOX_CREATOR_GROUP_ID=<id del grupo>)"
		exit 1
	fi
fi

# ---------------------------------------------------------------------------
# Subir
# ---------------------------------------------------------------------------
image_of_decal() {
	local decal="$1" xml image
	for _ in 1 2; do
		xml="$(curl -sS -L "https://assetdelivery.roblox.com/v1/asset/?id=${decal}" -H "@${HEADERS}" 2>/dev/null || true)"
		image="$(printf '%s' "$xml" | grep -oE 'id=[0-9]+' | head -1 | cut -d= -f2 || true)"
		if [ -n "$image" ]; then
			echo "$image"
			return 0
		fi
		sleep 3
	done
	echo "  ⚠️  no se encontró la imagen del decal ${decal}; se guarda el id del decal (el juego lo pasa a imagen al arrancar: shared/Images)" >&2
	echo "$decal"
}

upload_once() { # upload_once <archivo> <nombre> -> escribe el id de la imagen
	local file="$1" name="$2" request response operation done_ assetId
	request="$(printf '{"assetType":"Decal","displayName":"HoH %s","description":"Textura de un personaje de Heroes of History (cara o ropa)","creationContext":{"creator":%s}}' "$name" "$CREATOR")"
	response="$(curl -sS -X POST "https://apis.roblox.com/assets/v1/assets" \
		-H "@${HEADERS}" \
		-F "request=${request};type=application/json" \
		-F "fileContent=@${file};type=image/png" || true)"
	operation="$(printf '%s' "$response" | json operationId)"
	if [ -z "$operation" ]; then
		operation="$(printf '%s' "$response" | json path | sed 's|^operations/||')"
	fi
	if [ -z "$operation" ]; then
		echo "  ❌ $name: $(printf '%s' "$response" | head -c 300)" >&2
		return 1
	fi
	for _ in $(seq 1 60); do
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

upload() { # con reintentos (límite de peticiones, cortes de red)
	local attempt
	for attempt in 1 2 3; do
		if upload_once "$1" "$2"; then
			return 0
		fi
		[ "$attempt" -lt 3 ] && { echo "  … reintento $((attempt + 1)) de $2 en $((attempt * 15)) s" >&2; sleep $((attempt * 15)); }
	done
	return 1
}

write_ids() {
	{
		echo "-- PersonajesTextureIds: GENERADO por scripts/upload-personajes.sh (no editar a mano)."
		echo "-- \"<nombre>\" (assets/personajes/**/<nombre>.png, hechas con scripts/personajes/gen.py) -> imagen subida"
		echo "-- a Roblox (\"rbxassetid://…\"): caras del reparto (pj_cara_<clave>_<expresión>), plantillas de ropa"
		echo "-- compartidas (pj_ropa_<estilo>, pj_pantalon_<estilo>) y los mechones del pelo (pj_pelo)."
		echo "-- Vacío hasta que se suban: mientras tanto el reparto se ve como siempre (shared/LifeStory/CastLook)."
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
}

FAILED=0
UPLOADED=0
for file in "${PENDING[@]}"; do
	name="$(basename "$file" .png)"
	if id="$(upload "$file" "$name")"; then
		KNOWN["$name"]="rbxassetid://${id}"
		UPLOADED=$((UPLOADED + 1))
		echo "  ✅ $name -> rbxassetid://${id}"
		# (se va guardando: si se corta, lo subido no se pierde)
		[ $((UPLOADED % 10)) -eq 0 ] && write_ids
	else
		FAILED=$((FAILED + 1))
	fi
done
write_ids
echo "📄 $IDS con ${#KNOWN[@]} texturas (${UPLOADED} nuevas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED texturas no se pudieron subir (vuelve a lanzar el script: solo sube las que faltan)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para ver al reparto con texturas."
