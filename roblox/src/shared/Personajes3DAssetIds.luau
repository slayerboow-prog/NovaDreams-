-- Personajes3DAssetIds: GENERADO por scripts/upload-personajes3d.sh (no editar a mano).
-- Los ids de los personajes 3D propios subidos a Roblox (assets/personajes3d, hechos con
-- scripts/personajes/personajes3d_blender.py):
--   Modelos    "Personaje3D_<Key>" -> Model del FBX (la MeshPart Cuerpo y CuerpoLOD con sus Bone)
--   Texturas   "Personaje3D_<Key>_<mapa>" -> imagen (color, normal, rugosidad)
-- Vacío hasta que se suban: mientras tanto el reparto sale con CastLook (bloques con textura) de siempre.
return {
	Modelos = {},
	Texturas = {},
} :: { Modelos: { [string]: string }, Texturas: { [string]: string } }
