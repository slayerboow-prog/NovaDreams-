#!/usr/bin/env bash
# Sube los alienígenas v2 de la Invasión de la Grieta (assets/invasion, hechos con
# scripts/invasion/alien_blender.py) a Roblox con Open Cloud y escribe src/shared/Invasion/AlienAssetIds.luau.
# SOLO en la sesión que publica (no en las pruebas). Documentación: docs/invasion.md («Alienígenas v2»).
#
#   1. Texturas (assets/invasion/tex/*.png) como Decal -> id de la imagen ("Vortidos_tropas_color" -> …)
#   2. Cada modelo (assets/invasion/<Raza>_<Tipo>.fbx) como Model -> "Modelos" (sus MeshPart dentro)
#   3. (si hay Lune) Descarga esos Model, monta cada uno con sus MeshPart nombradas y su SurfaceAppearance
#      (scripts/invasion/compose.luau) y lo sube como Model -> "Completos". Si esta fase falla, el juego
#      usa las piezas del FBX con su textura de color.
#
# Hace falta (variables de entorno, como scripts/upload-nave.sh):
#   ROBLOX_API_KEY           clave de Open Cloud con permiso "asset: read, write" (no se enseña nunca)
#   ROBLOX_CREATOR_USER_ID   (opcional) tu id de usuario de Roblox (el dueño de los assets); si no está, se
#                            mira de quién es el juego (ROBLOX_UNIVERSE_ID; la clave necesita "universe: read")
#   ROBLOX_CREATOR_GROUP_ID  (opcional) si el juego es de un grupo
#   Los assets tienen que ser del MISMO dueño que el juego: si no, el servidor no puede cargarlos.
#
# Uso (desde la carpeta roblox/):
#   bash scripts/upload-invasion.sh              sube lo que aún no tiene id
#   bash scripts/upload-invasion.sh --force      vuelve a subirlo todo
#   bash scripts/upload-invasion.sh --sin-fase3  solo texturas y modelos (sin los Model completos)
#   bash scripts/upload-invasion.sh --solo VortidosCristal2
#                                                solo lo que empieza por ese nombre (los Vórtidos de cristal de
#                                                scripts/invasion/vortidos_blender.py: 8 FBX + 8 texturas; una
#                                                malla con esqueleto por modelo, nunca segmentos sueltos)
# Antes de subir ninguna malla pasa la revisión de moderación (scripts/lib/revisar-mallas.sh).
#
# Después: commit + push de src/shared/Invasion/AlienAssetIds.luau y publicar (scripts/publish.sh).
# Si algo no se sube, el juego sigue con los alienígenas de piezas de siempre (nunca se queda sin nada).
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

IDS="src/shared/Invasion/AlienAssetIds.luau"
DIR="assets/invasion"
FORCE=0
PHASE3=1
SOLO=""
while [ "$#" -gt 0 ]; do
	case "$1" in
		--force) FORCE=1 ;;
		--sin-fase3) PHASE3=0 ;;
		--solo=*) SOLO="${1#--solo=}" ;;
		--solo) shift; SOLO="${1:-}" ;;
		-h | --help) sed -n '2,30p' "$0"; exit 0 ;;
		*) echo "Opción desconocida: $1"; exit 1 ;;
	esac
	shift
done
wanted() { # wanted <nombre>: ¿entra en --solo?
	[ -z "$SOLO" ] || [[ "$1" == "$SOLO"* ]]
}

if [ ! -f "$DIR/manifest.json" ]; then
	echo "❌ No están los alienígenas en $DIR. Créalos con: python3 scripts/invasion/alien_blender.py (pip install bpy==4.2.0)"
	exit 1
fi
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud con permiso para subir assets)."
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
		echo "❌ No sé a nombre de quién subirlo (falta ROBLOX_CREATOR_USER_ID o ROBLOX_CREATOR_GROUP_ID,"
		echo "   o el permiso «universe: read» de la clave para saber el dueño del juego ${UNIVERSE})."
		exit 1
	fi
fi
echo "👤 Dueño: ${CREATOR}"

# ---------------------------------------------------------------------------
# Ids que ya había (sección.nombre -> id)
# ---------------------------------------------------------------------------
declare -A MODELOS=()
declare -A COMPLETOS=()
declare -A TEXTURAS=()
if [ -f "$IDS" ] && [ "$FORCE" = 0 ]; then
	section=""
	while IFS= read -r line; do
		case "$line" in
			*"Completos = {"*) section="C" ;;
			*"Modelos = {"*) section="M" ;;
			*"Texturas = {"*) section="T" ;;
		esac
		if [[ "$line" =~ ^[[:space:]]+([A-Za-z0-9_]+)\ =\ \"(rbxassetid://[0-9]+)\" ]]; then
			case "$section" in
				C) COMPLETOS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}" ;;
				M) MODELOS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}" ;;
				T) TEXTURAS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}" ;;
			esac
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
	request="$(printf '{"assetType":"%s","displayName":"Invasión %s","description":"Alienígenas de la Invasión de la Grieta de Heroes of History (%s)","creationContext":{"creator":%s}}' "$type" "$name" "$name" "$CREATOR")"
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
		echo "-- AlienAssetIds: GENERADO por scripts/upload-invasion.sh (no editar a mano)."
		echo "-- Los ids de los alienígenas v2 subidos a Roblox (assets/invasion, hechos con"
		echo "-- scripts/invasion/alien_blender.py):"
		echo "--   Completos  \"<Raza>_<Tipo>\" -> Model con todas sus MeshPart y su SurfaceAppearance (fase 3, con Lune)"
		echo "--   Modelos    \"<Raza>_<Tipo>\" -> Model de cada FBX (sus MeshPart dentro, con el nombre de cada pieza)"
		echo "--   Texturas   \"<Raza>_<juego>_<mapa>\" -> imagen (tropas/naves: color, normal, rugosidad, metal)"
		echo "-- Vacío hasta que se suban: mientras tanto el juego usa los modelos hechos con piezas (World/Kit/AlienModels)."
		echo "return {"
		echo "	Completos = {"
		for key in $(printf '%s\n' "${!COMPLETOS[@]}" | sort); do
			echo "		${key} = \"${COMPLETOS[$key]}\","
		done
		echo "	},"
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
		echo "} :: { Completos: { [string]: string }, Modelos: { [string]: string }, Texturas: { [string]: string } }"
	} > "$IDS"
}

# Revisión de moderación (scripts/lib/revisar-mallas.sh, docs/bugs/moderacion/): las mallas que se van a
# subir, antes de subir NADA; si alguna está marcada, para aquí.
source scripts/lib/revisar-mallas.sh
PENDIENTES=()
for file in "$DIR"/*.fbx; do
	name="$(basename "$file" .fbx)"
	wanted "$name" || continue
	[ -n "${MODELOS[$name]:-}" ] || PENDIENTES+=("$file")
done
revisar_mallas "${PENDIENTES[@]}"

FAILED=0
echo "🖼️  Texturas"
for file in "$DIR"/tex/*.png; do
	name="$(basename "$file" .png)"
	wanted "$name" || continue
	if [ -n "${TEXTURAS[$name]:-}" ]; then
		echo "  = $name ya subida (${TEXTURAS[$name]})"
		continue
	fi
	if id="$(upload "$file" Decal image/png "$name")"; then
		TEXTURAS["$name"]="rbxassetid://${id}"
		echo "  ✅ $name -> rbxassetid://${id}"
		write_ids # (lo que ya está subido no se pierde si algo falla después)
	else
		FAILED=$((FAILED + 1))
	fi
done

echo "👽 Modelos (FBX)"
declare -A CHANGED=()
for file in "$DIR"/*.fbx; do
	name="$(basename "$file" .fbx)"
	wanted "$name" || continue
	if [ -n "${MODELOS[$name]:-}" ]; then
		echo "  = $name ya subido (${MODELOS[$name]})"
		continue
	fi
	if id="$(upload "$file" Model model/fbx "$name")"; then
		MODELOS["$name"]="rbxassetid://${id}"
		CHANGED["$name"]=1
		echo "  ✅ $name -> rbxassetid://${id}"
		write_ids
	else
		FAILED=$((FAILED + 1))
	fi
done

# Fase 3: los Model completos con SurfaceAppearance (necesita Lune: https://lune-org.github.io/docs)
if [ "$PHASE3" = 1 ] && [ "$FAILED" = 0 ]; then
	if command -v lune >/dev/null 2>&1; then
		echo "🧩 Modelos completos (MeshPart + SurfaceAppearance)"
		mkdir -p "$WORK/fbx" "$WORK/out"
		todo=0
		for name in "${!MODELOS[@]}"; do
			wanted "$name" || continue
			if [ -z "${COMPLETOS[$name]:-}" ] || [ -n "${CHANGED[$name]:-}" ]; then
				id="${MODELOS[$name]#rbxassetid://}"
				if curl -sS -L --fail "https://assetdelivery.roblox.com/v1/asset/?id=${id}" -H "@${HEADERS}" -o "$WORK/fbx/${name}.rbxm" 2>/dev/null; then
					todo=$((todo + 1))
				else
					echo "  ⚠️  no se pudo descargar ${name} (${id}): usará las piezas sueltas"
				fi
			fi
		done
		if [ "$todo" -gt 0 ]; then
			: > "$WORK/texturas.txt"
			for key in "${!TEXTURAS[@]}"; do
				printf '%s=%s\n' "$key" "${TEXTURAS[$key]}" >> "$WORK/texturas.txt"
			done
			if lune run scripts/invasion/compose.luau "$WORK/fbx" "$DIR/manifest.json" "$WORK/texturas.txt" "$WORK/out"; then
				for file in "$WORK"/out/*.rbxm; do
					[ -f "$file" ] || continue
					name="$(basename "$file" .rbxm)"
					if id="$(upload "$file" Model model/x-rbxm "$name completo")"; then
						COMPLETOS["$name"]="rbxassetid://${id}"
						echo "  ✅ $name completo -> rbxassetid://${id}"
						write_ids
					else
						echo "  ⚠️  $name: no se pudo subir el completo (usará las piezas del FBX)"
					fi
				done
			fi
		fi
	else
		echo "ℹ️  Sin Lune no se montan los completos: el juego usará las piezas del FBX con su textura de color."
	fi
fi

write_ids
echo "📄 $IDS escrito (${#MODELOS[@]} modelos, ${#COMPLETOS[@]} completos, ${#TEXTURAS[@]} texturas)"
if [ "$FAILED" -gt 0 ]; then
	echo "⚠️  $FAILED cosas no se pudieron subir (vuelve a lanzar el script: solo sube lo que falta)"
	exit 1
fi
echo "✅ Listo. Haz commit + push de $IDS y publica (scripts/publish.sh) para ver a los alienígenas nuevos."
