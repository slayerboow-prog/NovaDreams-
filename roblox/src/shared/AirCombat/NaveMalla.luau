-- NaveMalla: GENERADO por scripts/nave/nave_blender.py (no editar a mano).
-- La nave realista «HX-7 Halcón» hecha en Blender: sus piezas (MeshPart al subirlas con
-- scripts/upload-nave.sh), con el centro y el tamaño en studs respecto al Root de la nave (ejes de
-- shared/AirCombat/ShipModel: el morro a -Z), los triángulos, el material de Roblox y el juego de
-- texturas (assets/nave/tex/<juego>_<mapa>.png). Lo usa shared/AirCombat/ShipModel (modo malla).

return {
	Name = "HX-7 Halcón",
	Designation = "HX-7",
	NozzleZ = 10.45,
	MuzzleZ = -11.0,
	Engines = { Vector3.new(-2.450, -0.250, 10.450), Vector3.new(2.450, -0.250, 10.450) }, -- centro del brillo de cada tobera
	EngineRadius = 1.6,
	WingTip = Vector3.new(13.500, -0.720, 9.350), -- punta del ala derecha (la izquierda: X negativa)
	TailLight = Vector3.new(0, 1.600, 10.000),
	Seat = Vector3.new(0.0, -1.25, -0.3),
	TotalTris = 42974,
	Pieces = {
		{ Name = "Fuselaje", Center = Vector3.new(0.000, 0.869, -3.500), Size = Vector3.new(6.600, 5.142, 27.800), Tris = 18228, Material = "Metal", Set = "casco", Color = nil, Lod = false },
		{ Name = "CabinaFrente", Center = Vector3.new(0.010, 2.098, -1.818), Size = Vector3.new(2.789, 1.986, 6.887), Tris = 2408, Material = "Metal", Set = "casco", Color = nil, Lod = false },
		{ Name = "Alas", Center = Vector3.new(0.000, -0.500, 2.063), Size = Vector3.new(27.200, 0.658, 15.271), Tris = 5652, Material = "Metal", Set = "alas", Color = nil, Lod = false },
		{ Name = "Armas", Center = Vector3.new(0.000, -1.885, -4.400), Size = Vector3.new(6.020, 1.070, 13.200), Tris = 2368, Material = "Metal", Set = "alas", Color = nil, Lod = false },
		{ Name = "Motores", Center = Vector3.new(0.000, -0.250, 5.372), Size = Vector3.new(8.380, 3.480, 11.144), Tris = 12340, Material = "Metal", Set = "motores", Color = nil, Lod = false },
		{ Name = "TrenPata", Center = Vector3.new(0.000, -2.925, -1.150), Size = Vector3.new(6.818, 3.250, 12.200), Tris = 528, Material = "Metal", Set = "motores", Color = nil, Lod = false },
		{ Name = "Cabina", Center = Vector3.new(0.000, 2.078, -1.800), Size = Vector3.new(2.561, 1.835, 6.800), Tris = 778, Material = "Glass", Set = nil, Color = Color3.fromRGB(24, 32, 44), Lod = false },
		{ Name = "BrilloAzul", Center = Vector3.new(0.000, -1.015, -0.998), Size = Vector3.new(24.802, 2.183, 19.015), Tris = 568, Material = "Neon", Set = nil, Color = Color3.fromRGB(63, 153, 255), Lod = false },
		{ Name = "BrilloRojo", Center = Vector3.new(0.000, -0.710, 8.837), Size = Vector3.new(27.360, 0.177, 1.775), Tris = 104, Material = "Neon", Set = nil, Color = Color3.fromRGB(255, 20, 12), Lod = false },
		{ Name = "NaveLOD", Center = Vector3.new(0.000, 0.519, -2.750), Size = Vector3.new(27.360, 5.338, 27.300), Tris = 3178, Material = "Metal", Set = "lod", Color = nil, Lod = true },
	},
}
