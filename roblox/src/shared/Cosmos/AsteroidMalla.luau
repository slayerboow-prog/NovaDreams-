-- AsteroidMalla: GENERADO por scripts/espacio/asteroides_blender.py (no editar a mano).
-- Las mallas de asteroide de Blender (assets/asteroides; se suben con scripts/upload-asteroides.sh):
-- una por variante de shared/Cosmos/Asteroids, con su caja («Medida») en radios de choque: la MeshPart
-- se pone de tamaño Medida × radio (World/AsteroidMeshes, shared/Cosmos/AsteroidBuild).
return {
	Variantes = {
		{ Name = "Asteroide1", Variant = 1, Silueta = "Patata", Medida = Vector3.new(1.927, 1.237, 1.462), Tris = 2400 },
		{ Name = "Asteroide2", Variant = 2, Silueta = "Losa", Medida = Vector3.new(1.857, 0.810, 1.489), Tris = 2400 },
		{ Name = "Asteroide3", Variant = 3, Silueta = "Bloque", Medida = Vector3.new(1.876, 1.345, 1.784), Tris = 2400 },
		{ Name = "Asteroide4", Variant = 4, Silueta = "Doble", Medida = Vector3.new(1.986, 0.799, 0.873), Tris = 2400 },
		{ Name = "Asteroide5", Variant = 5, Silueta = "Astilla", Medida = Vector3.new(1.970, 0.821, 0.915), Tris = 2400 },
		{ Name = "Asteroide6", Variant = 6, Silueta = "Pina", Medida = Vector3.new(1.897, 1.287, 1.554), Tris = 2400 },
	},
}
