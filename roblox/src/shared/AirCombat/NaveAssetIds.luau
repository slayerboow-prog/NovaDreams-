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
		Alas = "rbxassetid://70523914018548",
		Armas = "rbxassetid://128875574211630",
		BrilloAzul = "rbxassetid://120123031347899",
		BrilloRojo = "rbxassetid://103178125051491",
		Cabina = "rbxassetid://93560000555486",
		CabinaFrente = "rbxassetid://125673720524758",
		Fuselaje = "rbxassetid://87215694459571",
		Motores = "rbxassetid://98663230817587",
		NaveLOD = "rbxassetid://77983537350040",
		TrenPata = "rbxassetid://129716338084865",
	},
	Texturas = {
		alas_color = "rbxassetid://139039099390840",
		alas_metal = "rbxassetid://90106714112058",
		alas_normal = "rbxassetid://75864849716312",
		alas_rugosidad = "rbxassetid://77623779537407",
		casco_color = "rbxassetid://80047853278857",
		casco_metal = "rbxassetid://85032992775623",
		casco_normal = "rbxassetid://106765130010584",
		casco_rugosidad = "rbxassetid://113864757516069",
		lod_color = "rbxassetid://83172293305098",
		motores_color = "rbxassetid://73816113092219",
		motores_metal = "rbxassetid://78130060580321",
		motores_normal = "rbxassetid://126350088904347",
		motores_rugosidad = "rbxassetid://102862644707154",
	},
} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }
