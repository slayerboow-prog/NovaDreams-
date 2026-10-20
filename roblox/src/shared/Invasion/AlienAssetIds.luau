-- AlienAssetIds: GENERADO por scripts/upload-invasion.sh (no editar a mano).
-- Los ids de los alienígenas v2 subidos a Roblox (assets/invasion, hechos con
-- scripts/invasion/alien_blender.py):
--   Completos  "<Raza>_<Tipo>" -> Model con todas sus MeshPart y su SurfaceAppearance (fase 3, con Lune)
--   Modelos    "<Raza>_<Tipo>" -> Model de cada FBX (sus MeshPart dentro, con el nombre de cada pieza)
--   Texturas   "<Raza>_<juego>_<mapa>" -> imagen (tropas/naves: color, normal, rugosidad, metal)
-- Vacío hasta que se suban: mientras tanto el juego usa los modelos hechos con piezas (World/Kit/AlienModels).
return {
	Completos = {
	},
	Modelos = {
	},
	Texturas = {
	},
} :: { Completos: { [string]: string }, Modelos: { [string]: string }, Texturas: { [string]: string } }
