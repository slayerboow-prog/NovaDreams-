-- PuertoAssetIds: GENERADO por scripts/upload-puerto.sh (no editar a mano).
-- Los ids de las mallas del Puerto de Valmar hechas con Blender (scripts/puerto/puerto_blender.py,
-- assets/puerto):
--   Mallas    "<Kind>" -> Model con una MeshPart (GruaSTS, Contenedor40, Contenedor20, Tetrapodo, Bolardo)
--   Texturas  "<nombre>" -> imagen (los Decal se pasan a imagen con shared/Images)
-- Vacío hasta que se suban: mientras tanto el puerto usa las piezas (World/Kit/PuertoKit).
return {
	Mallas = {
		GruaSTS = "rbxassetid://114124567545639",
		Contenedor40 = "rbxassetid://106419125720696",
		Contenedor20 = "rbxassetid://81286893163307",
		Tetrapodo = "rbxassetid://88741221313884",
		Bolardo = "rbxassetid://97372936549193",
	},
	Texturas = {
	},
}
