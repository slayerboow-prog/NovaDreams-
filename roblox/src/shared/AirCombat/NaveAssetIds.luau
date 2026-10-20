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
		Alas2 = "rbxassetid://102152128554629",
		Armas2 = "rbxassetid://113399974382934",
		BrilloAzul = "rbxassetid://120123031347899",
		BrilloRojo = "rbxassetid://103178125051491",
		Cabina2 = "rbxassetid://97049100730427",
		CabinaFrente2 = "rbxassetid://87432305024904",
		Fuselaje2 = "rbxassetid://113740286004554",
		Motores = "rbxassetid://98663230817587",
		NaveLOD = "rbxassetid://77983537350040",
		TrenPata = "rbxassetid://129716338084865",
	},
	Texturas = {
		alas2_color = "rbxassetid://111889800705459",
		alas2_metal = "rbxassetid://91941436163424",
		alas2_normal = "rbxassetid://109170130101370",
		alas2_rugosidad = "rbxassetid://114714818534399",
		casco2_color = "rbxassetid://81453911540473",
		casco2_metal = "rbxassetid://78767336317489",
		casco2_normal = "rbxassetid://124356433063255",
		casco2_rugosidad = "rbxassetid://115347234290966",
		lod_color = "rbxassetid://83172293305098",
		motores_color = "rbxassetid://73816113092219",
		motores_metal = "rbxassetid://78130060580321",
		motores_normal = "rbxassetid://126350088904347",
		motores_rugosidad = "rbxassetid://102862644707154",
	},
} :: { Completa: string, Piezas: { [string]: string }, Texturas: { [string]: string } }
