#!/usr/bin/env bash
# Genera src/shared/TextureImageIds.luau (id de Decal de shared/TextureIds -> id de su imagen).
# Lanza en Roblox la prueba scripts/cloud/imagenes-texturas.luau (necesita ROBLOX_API_KEY, como
# scripts/cloud-test.sh) y escribe el módulo con las líneas "[img] <decal>=<imagen>" del registro.
# Uso (desde la carpeta roblox/): bash scripts/textures/image-ids.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
bash scripts/cloud-test.sh imagenes-texturas
LOG="${TMPDIR:-/tmp}/cloud-test/imagenes-texturas.log"
OUT="src/shared/TextureImageIds.luau"
{
	echo "-- TextureImageIds: GENERADO por scripts/textures/image-ids.sh (no editar a mano)."
	echo "-- Id de cada Decal de shared/TextureIds -> id de su imagen (lo saca en un servidor de Roblox la prueba"
	echo "-- scripts/cloud/imagenes-texturas.luau con InsertService:LoadAsset, como shared/Images.resolve)."
	echo "-- Lo usa scripts/build-place.luau para dejar los mapas de los MaterialVariant ya puestos en el archivo."
	echo "-- Para regenerarlo (tras subir texturas nuevas): bash scripts/textures/image-ids.sh"
	echo "return {"
	sed -n 's/^\[OUTPUT\] \[img\] \([0-9]\+\)=\([0-9]\+\)$/\t["\1"] = "rbxassetid:\/\/\2",/p' "$LOG" | sort -u
	echo "} :: { [string]: string }"
} > "$OUT"
echo "Escrito $OUT ($(grep -c rbxassetid "$OUT") imágenes)"
