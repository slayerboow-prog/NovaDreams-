#!/usr/bin/env bash
# Publica RealLifeSimulator.rbxl en tu juego de Roblox (Open Cloud, sin abrir Studio).
#
# Hay varias ventanas trabajando a la vez y en Roblox siempre gana la última versión subida,
# así que este script tiene un candado: solo publica si el código está al día con GitHub,
# sin cambios sin guardar, y construye él mismo el juego con ese código justo antes de subirlo.
# Así nadie puede publicar una versión vieja que borre lo que han hecho las demás ventanas.
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

# 1. Estar en la rama del juego, sin cambios sin guardar (el .rbxl construido no cuenta)
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

# 2b. Nunca hacia atrás: cada publicación deja en GitHub una marca (etiqueta pub/<hora>-<commit>).
#     Solo se publica si este código contiene la última versión publicada. Así, aunque dos ventanas
#     publiquen casi a la vez, una versión vieja (la «56» después de la «57») no puede pisar a la nueva.
lastPublished() {
	git fetch -q origin "refs/tags/pub/*:refs/tags/pub/*" 2>/dev/null || true
	git tag -l "pub/*" | sort -t/ -k2 -n | tail -1
}
notOlder() {
	local last
	last="$(lastPublished)"
	if [ -n "$last" ] && ! git merge-base --is-ancestor "$last" HEAD; then
		fail "ya está publicada una versión más nueva ($last). Haz: git pull origin $BRANCH"
	fi
}
notOlder

# 3. Construir el juego con este código (nunca se sube un .rbxl viejo)
echo "Comprobando y construyendo el juego del commit $COMMIT…"
lune run scripts/test-compile.luau
rojo build default.project.json -o "$FILE"
lune run scripts/build-place.luau "$FILE"

# 4. Última comprobación justo antes de subir, por si otra ventana ha subido código mientras tanto
upToDate
notOlder
[ "$(git rev-parse --short HEAD)" = "$COMMIT" ] || fail "el código ha cambiado durante la construcción."

URL="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=Published"
echo "Publicando $FILE ($(du -h "$FILE" | cut -f1)) del commit $COMMIT…"
curl -sS --fail-with-body -X POST "$URL" \
	-H "x-api-key: ${ROBLOX_API_KEY}" \
	-H "Content-Type: application/octet-stream" \
	--data-binary @"$FILE"
echo
# Marca de lo publicado (para el candado 2b de las demás ventanas)
TAG="pub/$(date -u +%s)-$COMMIT"
git tag "$TAG" HEAD && git push -q origin "refs/tags/$TAG" || echo "⚠️ No se pudo guardar la marca $TAG en GitHub (la publicación sí se ha hecho)."
echo "✅ Publicado (commit $COMMIT). Ábrelo en la app de Roblox del móvil."
