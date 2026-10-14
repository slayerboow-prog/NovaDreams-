-- OcioSitios (compartido): los sitios de ocio de las zonas verdes (docs/zonas-verdes/plan.md, fase 1-2).
--
-- Cada sitio es un rectángulo a ras de suelo (el terreno de la isla está en Y = -1), alineado con los
-- ejes: Center = { x, z } del centro y Size = { ancho en X, fondo en Z }. Salen de la máscara de huellas
-- de la ciudad construida (scripts/map/zonas-verdes/1_mascaras.py, semilla 2026): no pisan calles,
-- aceras, manzanas, edificios, río, lagos ni playa (scripts/test-ocio.luau lo comprueba con
-- docs/zonas-verdes/huellas-ocio.json, que hace scripts/map/zonas-verdes/6_huellas_ocio.py).
--   Budget = tope de piezas del sitio (plan, apartado 5). Road = hacia dónde queda la calle de acceso.
--
--   Sitios.get(id)            el sitio (o nil)
--   Sitios.cframe(id)         CFrame del centro del sitio a ras de suelo (Y = Sitios.GROUND)
--   Sitios.inside(id, pos, margin?)  ¿está ese punto dentro del sitio (con margen)?
--   Sitios.toWorld(id, x, z, y?)     de coordenadas del sitio (X este, Z sur) al mundo

local Sitios = {}

Sitios.GROUND = -1 -- altura del terreno de la isla (TerrainBuilder)

export type Sitio = {
	Id: string,
	Zone: number,
	Name: string,
	Center: { number },
	Size: { number },
	Budget: number,
	Road: string,
}

Sitios.List = {
	{ Id = "Feria", Zone = 7, Name = "Mercadillo y Recinto de Fiestas", Center = { 1936, -150 }, Size = { 240, 180 }, Budget = 600, Road = "S" },
	{ Id = "Playa", Zone = 6, Name = "Vóley Playa de Levante", Center = { 4030, -316 }, Size = { 200, 100 }, Budget = 200, Road = "W" },
	{ Id = "Campus", Zone = 8, Name = "Polideportivo del Campus", Center = { 2116, 150 }, Size = { 210, 150 }, Budget = 120, Road = "N" },
	{ Id = "Karting", Zone = 13, Name = "Karting de San Roque", Center = { -1356, 3104 }, Size = { 390, 250 }, Budget = 450, Road = "N" },
	{ Id = "Skate", Zone = 10, Name = "Skatepark de la Ribera", Center = { 1332, 1420 }, Size = { 150, 110 }, Budget = 200, Road = "N" },
} :: { Sitio }

Sitios.ById = {} :: { [string]: Sitio }
for _, s in Sitios.List do
	Sitios.ById[s.Id] = s
end

function Sitios.get(id: string): Sitio?
	return Sitios.ById[id]
end

function Sitios.cframe(id: string): CFrame
	local s = Sitios.ById[id]
	return CFrame.new(s.Center[1], Sitios.GROUND, s.Center[2])
end

function Sitios.toWorld(id: string, x: number, z: number, y: number?): Vector3
	local s = Sitios.ById[id]
	return Vector3.new(s.Center[1] + x, y or Sitios.GROUND, s.Center[2] + z)
end

function Sitios.inside(id: string, pos: Vector3, margin: number?): boolean
	local s = Sitios.ById[id]
	if not s then
		return false
	end
	local m = margin or 0
	return math.abs(pos.X - s.Center[1]) <= s.Size[1] / 2 + m and math.abs(pos.Z - s.Center[2]) <= s.Size[2] / 2 + m
end

-- El sitio en el que está ese punto (o nil)
function Sitios.at(pos: Vector3, margin: number?): Sitio?
	for _, s in Sitios.List do
		if Sitios.inside(s.Id, pos, margin) then
			return s
		end
	end
	return nil
end

return Sitios
