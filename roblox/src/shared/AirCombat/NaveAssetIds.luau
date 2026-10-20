-- NaveAssetIds: GENERADO por scripts/upload-nave.sh (no editar a mano).
-- Los ids de la nave realista «HX-7 Halcón» subida a Roblox (assets/nave, hecha con
-- scripts/nave/nave_blender.py):
--   Completa  un Model con todas las MeshPart y su SurfaceAppearance (la fase 3 del script, con Lune)
--   Piezas    "<Pieza>" -> Model de cada FBX (una MeshPart dentro)
--   Texturas  "<juego>_<mapa>" -> imagen (casco/alas/motores: color, normal, rugosidad, metal; lod: color)
-- Vacío hasta que se suban: mientras tanto el juego usa la nave hecha con piezas (shared/AirCombat/ShipModel).
return {
	Completa = "",
	Piezas = {
		BrilloAzul = "rbxassetid://120123031347899",
		BrilloRojo = "rbxassetid://103178125051491",
		Motores = "rbxassetid://98663230817587",
		NaveLOD = "rbxassetid://77983537350040",
		TrenPata = "rbxassetid://129716338084865",
	},
	Texturas = {
		lod_color = "rbxassetid://83172293305098",
		motores_color = "rbxassetid://73816113092219",
		motores_metal = "rbxassetid://78130060580321",
		motores_normal = "rbxassetid://126350088904347",
		motores_rugosidad = "rbxassetid://102862644707154",
	},
} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }
