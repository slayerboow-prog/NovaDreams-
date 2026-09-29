#!/usr/bin/env bash
# Publica RealLifeSimulator.rbxl en tu juego de Roblox (Open Cloud, sin abrir Studio).
#
# Hay varias ventanas trabajando a la vez y en Roblox siempre gana la última versión subida,
# así que este script tiene un candado: solo publica si el código está al día con GitHub,
# sin cambios sin guardar, y construye él mismo el juego con ese código justo antes de subirlo.
# Así nadie puede publicar una versión vieja que borre lo que han hecho las demás ventanas: la
# comprobación se repite justo antes de subir, así que si otra ventana ha subido algo mientras se
# construía, esta se para.
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY      clave de Open Cloud con permiso "universe-places: write" para tu juego
#   ROBLOX_UNIVERSE_ID  el número de la experiencia (Universe ID)
#   ROBLOX_PLACE_ID     el número del lugar (Place ID)
#   PUBLISH_BRANCH      rama del juego (por defecto, claude/roblox-game-d98vy8)
# Uso (desde roblox/): scripts/publish.sh [archivo.rbxl]   (por defecto, RealLifeSimulator.rbxl)
set -euo pipefail
cd "$(dirname "$0")/.."
FILE="${1:-RealLifeSimulator.rbxl}"
: "${ROBLOX_API_KEY:?Falta ROBLOX_API_KEY}"
ROBLOX_UNIVERSE_ID="${ROBLOX_UNIVERSE_ID:-10767975237}" # Real Life Simulator (experiencia)
ROBLOX_PLACE_ID="${ROBLOX_PLACE_ID:-113359543879512}" # Real Life Simulator (lugar de inicio)
BRANCH="${PUBLISH_BRANCH:-claude/roblox-game-d98vy8}"

fail() { echo "⛔ No se publica: $1" >&2; exit 1; }

# 1. Estar en la rama del juego, sin cambios sin guardar (el .rbxl construido no cuenta).
#    Si la copia está en un commit suelto (HEAD desacoplado, pasa en las ventanas nuevas), se pone en
#    la rama con lo último de GitHub (sin cambios sin guardar no se pierde nada).
if [ "$(git rev-parse --abbrev-ref HEAD)" = "HEAD" ] && [ -z "$(git status --porcelain -- . ":(exclude)$FILE")" ]; then
	git fetch -q origin "$BRANCH" || fail "no se pudo consultar GitHub."
	git checkout -q -B "$BRANCH" "origin/$BRANCH" || fail "no se pudo poner la copia en la rama '$BRANCH'."
	echo "(La copia estaba en un commit suelto: ahora está en '$BRANCH', al día con GitHub.)"
fi
[ "$(git rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] ||
	fail "estás en la rama '$(git rev-parse --abbrev-ref HEAD)', no en '$BRANCH'."
DIRTY="$(git status --porcelain -- . ":(exclude)$FILE")"
[ -z "$DIRTY" ] || fail "hay cambios sin guardar (haz commit y push primero):
$DIRTY"

# 2. Estar exactamente al día con GitHub: ni faltan cambios de otras ventanas ni hay commits sin subir
upToDate() {
	git fetch -q origin "$BRANCH" || fail "no se pudo consultar GitHub."
	local here there
	here="$(git rev-parse HEAD)"
	there="$(git rev-parse "origin/$BRANCH")"
	[ "$here" = "$there" ] && return 0
	if git merge-base --is-ancestor HEAD "origin/$BRANCH"; then
		fail "faltan cambios de otras ventanas. Haz: git pull origin $BRANCH"
	elif git merge-base --is-ancestor "origin/$BRANCH" HEAD; then
		fail "tienes commits sin subir. Haz: git push origin $BRANCH"
	else
		fail "tu rama y la de GitHub se han separado. Haz: git pull origin $BRANCH (y resuelve), luego push."
	fi
}
upToDate
COMMIT="$(git rev-parse --short HEAD)"

# 2b. Herramientas para construir (lune y rojo). Las ventanas nuevas no las traen: se descargan solas.
if ! command -v lune >/dev/null 2>&1 || ! command -v rojo >/dev/null 2>&1; then
	echo "Instalando lune y rojo…"
	mkdir -p "$HOME/bin"
	curl -sSfL -o /tmp/lune.zip https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-linux-x86_64.zip &&
		curl -sSfL -o /tmp/rojo.zip https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-linux-x86_64.zip &&
		unzip -oq /tmp/lune.zip -d "$HOME/bin" && unzip -oq /tmp/rojo.zip -d "$HOME/bin" &&
		chmod +x "$HOME/bin/lune" "$HOME/bin/rojo" || fail "no se pudieron instalar lune y rojo."
	export PATH="$HOME/bin:$PATH"
fi

# 3. Construir el juego con este código (nunca se sube un .rbxl viejo)
echo "Comprobando y construyendo el juego del commit $COMMIT…"
lune run scripts/test-compile.luau
rojo build default.project.json -o "$FILE"
lune run scripts/build-place.luau "$FILE"

# 4. Última comprobación justo antes de subir, por si otra ventana ha subido código mientras tanto
upToDate
[ "$(git rev-parse --short HEAD)" = "$COMMIT" ] || fail "el código ha cambiado durante la construcción."

URL="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=Published"
echo "Publicando $FILE ($(du -h "$FILE" | cut -f1)) del commit $COMMIT…"
curl -sS --fail-with-body -X POST "$URL" \
	-H "x-api-key: ${ROBLOX_API_KEY}" \
	-H "Content-Type: application/octet-stream" \
	--data-binary @"$FILE"
echo
echo "✅ Publicado (commit $COMMIT). Ábrelo en la app de Roblox del móvil."
