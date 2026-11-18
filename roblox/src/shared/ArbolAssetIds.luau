-- ArbolAssetIds: GENERADO por scripts/upload-arbol.sh (no editar a mano).
-- Los ids del Árbol Ancestral subido a Roblox (assets/arbol, hecho con scripts/arbol/arbol_blender.py
-- y scripts/arbol/texturas.py):
--   Completa  un Model con todas las MeshPart y su SurfaceAppearance (la fase 3 del script, con Lune)
--   Piezas    "<Pieza>" -> Model de cada FBX (una MeshPart dentro)
--   Texturas  "<juego>_<mapa>" -> imagen (casco/alas/motores: color, normal, rugosidad, metal; lod: color)
-- Vacío hasta que se suban: mientras tanto el juego usa el árbol hecho con piezas (World/Kit/AncientTree).
return {
	Completa = "",
	Piezas = {
		Copa1 = "rbxassetid://82633161481351",
		Copa2 = "rbxassetid://110242734701968",
		Copa3 = "rbxassetid://119796241440458",
		Copa4 = "rbxassetid://96051404715990",
		Copa5 = "rbxassetid://77578873749599",
		Raices = "rbxassetid://86682572207198",
		Ramas = "rbxassetid://131874575745607",
		Tronco = "rbxassetid://77095639193748",
		Venas = "rbxassetid://81211435317545",
	},
	Texturas = {
		corteza_color = "rbxassetid://110070404971817",
		corteza_normal = "rbxassetid://110794018035542",
		hojas_color = "rbxassetid://132859027519661",
		hojas_normal = "rbxassetid://140408438036861",
	},
} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }
