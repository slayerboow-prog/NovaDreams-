-- NaveAssetIds: GENERADO por scripts/upload-nave.sh (no editar a mano).
-- Los ids de la nave realista «HX-7 Halcón» subida a Roblox (assets/nave, hecha con
-- scripts/nave/nave_blender.py):
--   Completa  un Model con todas las MeshPart y su SurfaceAppearance (la fase 2 del script, con Lune)
--   Piezas    "<Pieza>" -> Model de cada FBX (una MeshPart dentro)
--   Texturas  "<juego>_<mapa>" -> imagen (casco/alas/motores: color, normal, rugosidad, metal; lod: color)
-- Vacío hasta que se suban: mientras tanto el juego usa la nave hecha con piezas (shared/AirCombat/ShipModel).
return {
	Completa = "",
	Piezas = {},
	Texturas = {},
} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }
