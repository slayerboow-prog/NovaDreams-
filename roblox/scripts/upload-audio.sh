#!/usr/bin/env bash
# Sube los audios del juego a Roblox con Open Cloud y, al acabar, escribe src/shared/SoundIds.luau con
# el id de cada uno (nombre del archivo sin .ogg -> "rbxassetid://…"). SoundFx, Weather y StoryAudio
# usan esos ids cuando el Id de Config es 0: no hay que copiar nada a mano.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox, el dueño de los audios.
#                            Si no está, se mira de quién es el juego (ROBLOX_UNIVERSE_ID, el mismo de
#                            scripts/publish.sh); para eso la clave necesita también "universe: read".
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo, el id del grupo
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-audio.sh                 sube los efectos (audio/sfx/*.ogg) que aún no tienen id
#   bash scripts/upload-audio.sh --music         y también la música (audio/*.ogg, los 7 de la historia)
#   bash scripts/upload-audio.sh --force         vuelve a subirlos todos
#   bash scripts/upload-audio.sh motor lluvia    solo esos
#
# Roblox puede pedir que la cuenta esté verificada para subir audio y limita cuántos se suben al mes.
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/SoundIds.luau"
MUSIC=0
FORCE=0
ONLY=()
for arg in "$@"; do
	case "$arg" in
		--music) MUSIC=1 ;;
		--force) FORCE=1 ;;
		-h | --help) sed -n '2,20p' "$0"; exit 0 ;;
		-*) echo "Opción desconocida: $arg"; exit 1 ;;
		*) ONLY+=("${arg%.ogg}") ;;
	esac
done

# ---------------------------------------------------------------------------
# Qué archivos se suben
# ---------------------------------------------------------------------------
FILES=()
for file in audio/sfx/*.ogg; do
	[ -f "$file" ] && FILES+=("$file")
done
if [ "$MUSIC" = 1 ]; then
	for file in audio/*.ogg; do
		[ -f "$file" ] && FILES+=("$file")
	done
fi
if [ "${#FILES[@]}" -eq 0 ]; then
	echo "❌ No hay audios en audio/sfx. Créalos con: python3 scripts/audio/sfx.py"
	exit 1
fi

# ---------------------------------------------------------------------------
# Clave y dueño de los audios
# ---------------------------------------------------------------------------
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir audios)."
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
	echo "👤 Dueño de los audios: usuario ${ROBLOX_CREATOR_USER_ID}"
elif [ -n "${ROBLOX_CREATOR_GROUP_ID:-}" ]; then
	CREATOR="$(printf '{"groupId":"%s"}' "$ROBLOX_CREATOR_GROUP_ID")"
	echo "👥 Dueño de los audios: grupo ${ROBLOX_CREATOR_GROUP_ID}"
else
	# El dueño del juego: GET /cloud/v2/universes/{id} responde "user": "users/<id>" (o "group": "groups/<id>")
	universe="$(curl -sS "https://apis.roblox.com/cloud/v2/universes/${UNIVERSE}" -H "@${HEADERS}" 2>/dev/null || true)"
	owner_user="$(printf '%s' "$universe" | json user | sed -n 's|^users/\([0-9][0-9]*\)$|\1|p')"
	owner_group="$(printf '%s' "$universe" | json group | sed -n 's|^groups/\([0-9][0-9]*\)$|\1|p')"
	if [ -n "$owner_user" ]; then
		CREATOR="$(printf '{"userId":"%s"}' "$owner_user")"
		echo "👤 Dueño de los audios: usuario ${owner_user} (el dueño del juego ${UNIVERSE})"
	elif [ -n "$owner_group" ]; then
		CREATOR="$(printf '{"groupId":"%s"}' "$owner_group")"
		echo "👥 Dueño de los audios: grupo ${owner_group} (el dueño del juego ${UNIVERSE})"
	else
		echo "❌ No sé a nombre de quién subir los audios."
		echo "   No está ROBLOX_CREATOR_USER_ID y no se ha podido saber el dueño del juego ${UNIVERSE}"
		echo "   (la clave necesita el permiso «universe: read» para eso)."
		echo "   Solución: pon tu id de usuario de Roblox (sale en la dirección de tu perfil, roblox.com/users/<id>/profile):"
		echo "     export ROBLOX_CREATOR_USER_ID=<tu id>"
		echo "   Si el juego es de un grupo: export ROBLOX_CREATOR_GROUP_ID=<id del grupo>"
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
	done < <(grep -oE '^\s*[a-z_0-9]+ = "rbxassetid://[0-9]+"' "$IDS" | sed -E 's/^\s*([a-z_0-9]+) = "(rbxassetid:\/\/[0-9]+)"/\1=\2/')
fi

upload() { # upload <archivo> -> escribe el id del audio
	local file="$1" name request response operation done_ assetId
	name="$(basename "$file" .ogg)"
	request="$(printf '{"assetType":"Audio","displayName":"%s","description":"Audio original de Real Life Simulator (hecho por código)","creationContext":{"creator":%s}}' "$name" "$CREATOR")"
	response="$(curl -sS -X POST "https://apis.roblox.com/assets/v1/assets" \
		-H "@${HEADERS}" \
		-F "request=${request};type=application/json" \
		-F "fileContent=@${file};type=audio/ogg" || true)"
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
				echo "$assetId"
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
for file in "${FILES[@]}"; do
	name="$(basename "$file" .ogg)"
	if [ "${#ONLY[@]}" -gt 0 ] && [[ ! " ${ONLY[*]} " == *" $name "* ]]; then
		continue
	fi
	if [ "$FORCE" = 0 ] && [ -n "${KNOWN[$name]:-}" ]; then
		echo "  = $name ya subido (${KNOWN[$name]})"
		continue
	fi
	if id="$(upload "$file")"; then
		KNOWN["$name"]="rbxassetid://${id}"
		UPLOADED=$((UPLOADED + 1))
		echo "  ✅ $name -> rbxassetid://${id}"
	else
		FAILED=$((FAILED + 1))
	fi
done

# ---------------------------------------------------------------------------
# SoundIds.luau (generado)
# ---------------------------------------------------------------------------
{
	echo "-- SoundIds: GENERADO por scripts/upload-audio.sh (no editar a mano)."
	echo "-- Nombre del archivo de audio (sin .ogg) -> audio subido a Roblox (\"rbxassetid://…\")."
	echo "-- Efectos (audio/sfx: motor, lluvia…) y, si se subió con --music, la música (tema_valmar…)."
	echo "-- SoundFx, Weather y StoryAudio lo miran cuando el Id de Config es 0. Si falta un nombre, se busca"
	echo "-- un Sound con ese nombre en ReplicatedStorage > Sonidos (o > Musica para la música)."
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
echo "📄 $IDS con ${#KNOWN[@]} audios (${UPLOADED} nuevos)"
if [ "$MUSIC" = 1 ]; then
	echo "ℹ️  Música: Config.Audio ya tiene Id para cada pieza y ese manda. Los ids nuevos se usan si ese"
	echo "   no carga o si pones su Id a 0 en src/shared/Config.luau."
fi
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED audios no se pudieron subir (vuelve a lanzar el script: solo sube los que faltan)"
	exit 1
fi
echo "✅ Listo. Reconstruye y publica el juego para que suenen (los audios nuevos pueden tardar un rato en"
echo "   pasar la revisión de Roblox)."
