-- AsteroidAssetIds: GENERADO por scripts/upload-asteroides.sh (no editar a mano).
-- Los ids de las mallas de asteroide hechas en Blender (assets/asteroides, scripts/espacio/asteroides_blender.py):
--   Mallas    "Asteroide<n>" -> Model de cada FBX (una MeshPart dentro); n = variante (shared/Cosmos/Asteroids)
--   Texturas  "asteroide_<mapa>" -> imagen (color, normal)
-- Vacío hasta que se suban: mientras tanto los asteroides se hacen con bloques y cuñas (el respaldo).
return {
	Mallas = {},
	Texturas = {},
} :: { Mallas: { [string]: string }, Texturas: { [string]: string } }
