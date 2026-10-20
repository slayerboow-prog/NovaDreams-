-- MarAssetIds: GENERADO por scripts/upload-mar.sh (no editar a mano).
-- Los ids del kit del mar hecho en Blender (assets/mar, scripts/map/mar_kit_blender.py):
--   Mallas    "<Pieza>" -> Model de cada FBX (una MeshPart dentro); Pieza = shared/Sea/MarKit.Pieces
--   Texturas  "<pieza>_<mapa>" -> imagen (color, normal) y "causticas" (la luz del fondo, Controllers/ReefZoneFx)
-- Vacío hasta que se suban: mientras tanto el mar usa las piezas de respaldo (MarKit.fallback).
return {
	Mallas = {},
	Texturas = {},
} :: { Mallas: { [string]: string }, Texturas: { [string]: string } }
