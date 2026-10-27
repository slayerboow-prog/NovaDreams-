-- EstiloBloqueAssetIds: GENERADO por scripts/upload-estilo-bloque.sh (no editar a mano).
-- Los ids del estilo bloque del reparto subidos a Roblox (assets/bloque, hechos con
-- scripts/personajes/bloque_blender.py):
--   Modelos    "Bloque_<Key>" -> Model del FBX (una MeshPart por accesorio, con su nombre)
--   Texturas   atlas "Bloque_<Key>_<mapa>", ropa "bloque_<key>_camisa/_pantalon", caras "bloque_<key>_cara_<e>"
-- Vacío hasta que se suban: mientras tanto el reparto sale con CastLook de siempre.
return {
	Modelos = {},
	Texturas = {},
} :: { Modelos: { [string]: string }, Texturas: { [string]: string } }
