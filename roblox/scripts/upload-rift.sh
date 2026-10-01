#!/usr/bin/env bash
# Sube las texturas de la Grieta del cielo (textures/rift/*.png, hechas con scripts/rift/gen.py) a
# Roblox con Open Cloud (como Decal) y, al acabar, escribe src/shared/RiftTextureIds.luau con el id de
# cada imagen ("rift_interior" -> "rbxassetid://…"). El cliente (Controllers/SkyRift) las usa en cuanto
# están; si solo se sabe el id del Decal, el servidor lo pasa a imagen al arrancar (shared/Images).
# Las vistas previas (preview*.png) no se suben.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox, el dueño de las imágenes.
#                            Si no está, se mira de quién es el juego (ROBLOX_UNIVERSE_ID, el mismo de
#                            scripts/publish.sh); para eso la clave necesita también "universe: read".
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo, el id del grupo
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-rift.sh                          sube las que aún no tienen id
#   bash scripts/upload-rift.sh --force                  vuelve a subirlas todas
#   bash scripts/upload-rift.sh rift_interior bolt_1     solo esas
#
# Después: commit + push de src/shared/RiftTextureIds.luau y publicar (scripts/publish.sh).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/RiftTextureIds.luau"
FORCE=0
ONLY=()
for arg in "$@"; do
	case "$arg" in
		--force) FORCE=1 ;;
		-h | --help) sed -n '2,20p' "$0"; exit 0 ;;
		-*) echo "Opción desconocida: $arg"; exit 1 ;;
		*) ONLY+=("$arg") ;;
	esac
done

# ---------------------------------------------------------------------------
# Qué archivos se suben
# ---------------------------------------------------------------------------
FILES=()
for file in textures/rift/*.png; do
	case "$(basename "$file")" in preview*) continue ;; esac
	[ -f "$file" ] && FILES+=("$file")
done
if [ "${#FILES[@]}" -eq 0 ]; then
	echo "❌ No hay texturas en textures/rift/. Créalas con: python3 scripts/rift/gen.py"
	exit 1
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

UNIVERSE="${ROBLOX_UNIVERSE_ID:-10767975237}" # Real Life Simulator (el mismo que scripts/publish.sh)
CREATOR=""
if [ -n "${ROBLOX_CREATOR_USER_ID:-}" ]; then
	CREATOR="$(printf '{"userId":"%s"}' "$ROBLOX_CREATOR_USER_ID")"
	echo "👤 Dueño de las texturas: usuario ${ROBLOX_CREATOR_USER_ID}"
elif [ -n "${ROBLOX_CREATOR_GROUP_ID:-}" ]; then
	CREATOR="$(printf '{"groupId":"%s"}' "$ROBLOX_CREATOR_GROUP_ID")"
	echo "👥 Dueño de las texturas: grupo ${ROBLOX_CREATOR_GROUP_ID}"
else
	# El dueño del juego: GET /cloud/v2/universes/{id} responde "user": "users/<id>" (o "group": "groups/<id>")
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
		echo "   No está ROBLOX_CREATOR_USER_ID y no se ha podido saber el dueño del juego ${UNIVERSE}"
		echo "   (la clave necesita el permiso «universe: read» para eso)."
		echo "   Solución: export ROBLOX_CREATOR_USER_ID=<tu id> (o ROBLOX_CREATOR_GROUP_ID=<id del grupo>)"
		exit 1
	fi
fi

# ---------------------------------------------------------------------------
# Subir
# ---------------------------------------------------------------------------
# Ids que ya había (nombre -> id)
declare -A KNOWN=()
if [ -f "$IDS" ]; then
	while IFS='=' read -r key value; do
		KNOWN["$key"]="$value"
	done < <(grep -oE '^\s*[a-z0-9_]+ = "rbxassetid://[0-9]+"' "$IDS" | sed -E 's/^\s*([a-z0-9_]+) = "(rbxassetid:\/\/[0-9]+)"/\1=\2/')
fi

# Del id del Decal al de su imagen (lo que usan ColorMap, NormalMap…). Roblox puede tardar un poco
# en tenerla lista: se reintenta.
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
	request="$(printf '{"assetType":"Decal","displayName":"Grieta %s","description":"Textura de la Grieta del cielo de Real Life Simulator","creationContext":{"creator":%s}}' "$name" "$CREATOR")"
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
		[ "$attempt" -lt 3 ] && { echo "  … reintento $((attempt + 1)) de $2 en $((attempt * 10)) s" >&2; sleep $((attempt * 10)); }
	done
	return 1
}

FAILED=0
UPLOADED=0
for file in "${FILES[@]}"; do
	name="$(basename "$file" .png)"
	if [ "${#ONLY[@]}" -gt 0 ] && [[ ! " ${ONLY[*]} " == *" $name "* ]]; then
		continue
	fi
	if [ "$FORCE" = 0 ] && [ -n "${KNOWN[$name]:-}" ]; then
		echo "  = $name ya subida (${KNOWN[$name]})"
		continue
	fi
	if id="$(upload "$file" "$name")"; then
		KNOWN["$name"]="rbxassetid://${id}"
		UPLOADED=$((UPLOADED + 1))
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# ---------------------------------------------------------------------------
# RiftTextureIds.luau (generado)
# ---------------------------------------------------------------------------
{
	echo "-- RiftTextureIds: GENERADO por scripts/upload-rift.sh (no editar a mano)."
	echo "-- \"<nombre>\" (textures/rift/<nombre>.png, hechas con scripts/rift/gen.py) -> imagen subida a Roblox"
	echo "-- (\"rbxassetid://…\"). Vacío hasta que se suban: mientras tanto la Grieta del cielo se dibuja por código"
	echo "-- con la misma silueta (Controllers/SkyRift, shared/SkyRiftArt)."
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
echo "📄 $IDS con ${#KNOWN[@]} texturas (${UPLOADED} nuevas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED texturas no se pudieron subir (vuelve a lanzar el script: solo sube las que faltan)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para ver la grieta con sus texturas."
