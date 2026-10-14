-- Stations: las estaciones espaciales encima de Valmar (cuentas puras; docs/espacio.md).
--
-- Cada estación es una ZONA SEGURA (radio SafeRadius): dentro no se puede disparar, los enemigos no
-- te atacan y no recibes daño. Se ATRACA acercando la nave a su muelle (DockRadius): te bajas en el
-- vestíbulo, que tiene suelo, paredes y techo de cristal. Dentro:
--   * Tienda: vender minerales (dinero de Valmar), reparar el casco y recargar misiles.
--   * Tablón de misiones secundarias (shared/Cosmos/Missions).
--   * Hangar: «Subir a la nave» (despegas desde el muelle).
--   * Portal «Volver a Valmar» (al puerto espacial del islote).

local Stations = {}

export type Station = {
	Id: string,
	Name: string,
	Sign: string, -- (en mayúsculas, con sus tildes: el cartel)
	Center: Vector3, -- centro del suelo del vestíbulo
	Dock: Vector3, -- el muelle (fuera, por donde llegan y salen las naves)
	Out: Vector3, -- hacia dónde sale la nave al despegar (unitario)
	Color: Color3,
}

Stations.SafeRadius = 520
Stations.DockRadius = 240
Stations.HallHalf = 44 -- medio lado del vestíbulo
Stations.HallHeight = 28

Stations.List = {
	{
		Id = "Alba",
		Name = "Estación Alba",
		Sign = "ESTACIÓN ALBA",
		Center = Vector3.new(-1800, 4300, 1400),
		Dock = Vector3.new(-1800 + 150, 4300 + 10, 1400),
		Out = Vector3.new(1, 0, 0),
		Color = Color3.fromRGB(110, 200, 255),
	},
	{
		Id = "Cenit",
		Name = "Estación Cénit",
		Sign = "ESTACIÓN CÉNIT",
		Center = Vector3.new(2600, 5600, -2400),
		Dock = Vector3.new(2600, 5600 + 10, -2400 + 150),
		Out = Vector3.new(0, 0, 1),
		Color = Color3.fromRGB(255, 190, 110),
	},
} :: { Station }

Stations.ById = {} :: { [string]: Station }
for _, s in Stations.List do
	Stations.ById[s.Id] = s
end

-- La estación cuya zona segura contiene `pos` (o nil)
function Stations.safeAt(pos: Vector3): Station?
	for _, s in Stations.List do
		if (pos - s.Center).Magnitude <= Stations.SafeRadius then
			return s
		end
	end
	return nil
end

-- La estación en cuyo muelle está la nave (o nil)
function Stations.dockAt(pos: Vector3): Station?
	for _, s in Stations.List do
		if (pos - s.Dock).Magnitude <= Stations.DockRadius then
			return s
		end
	end
	return nil
end

function Stations.nearest(pos: Vector3): Station
	local best, bestD = Stations.List[1], math.huge
	for _, s in Stations.List do
		local d = (pos - s.Center).Magnitude
		if d < bestD then
			best, bestD = s, d
		end
	end
	return best
end

-- Dónde aparece quien entra andando (portal o atracar): en el suelo del vestíbulo
function Stations.arrival(s: Station): CFrame
	local p = s.Center + Vector3.new(0, 3, 14)
	return CFrame.new(p)
end

-- Dónde sale la nave al despegar: delante del muelle, mirando hacia fuera
function Stations.launch(s: Station): CFrame
	local p = s.Dock + s.Out * 60
	local l = s.Out.Unit
	local right = l:Cross(Vector3.new(0, 1, 0)).Unit
	return CFrame.fromMatrix(p, right, right:Cross(l).Unit, -l)
end

-- Las cajas sólidas de cada estación para la nave (Espacio AAA: ya no se atraviesan, se choca y se
-- rebota): el vestíbulo y los dos brazos con sus paneles solares (World/SpaceWorld). { Center, Half }
function Stations.hulls(s: Station): { { Center: Vector3, Half: Vector3 } }
	local C, H, T = s.Center, Stations.HallHalf, Stations.HallHeight
	local out = { { Center = C + Vector3.new(0, T / 2 - 1, 0), Half = Vector3.new(H + 2, T / 2 + 3, H + 2) } }
	for _, side in { -1, 1 } do
		table.insert(out, { Center = C + Vector3.new(0, -6, side * 120), Half = Vector3.new(35, 1.5, 13) })
		table.insert(out, { Center = C + Vector3.new(0, -6, side * 74), Half = Vector3.new(2, 2, 30) })
	end
	return out
end

-- ¿Toca una esfera (pos, radio) el casco de alguna estación? La estación o nil
function Stations.hullHit(pos: Vector3, radius: number): Station?
	for _, s in Stations.List do
		if (pos - s.Center).Magnitude < 200 + radius then
			for _, box in Stations.hulls(s) do
				local d = pos - box.Center
				local q = Vector3.new(math.max(math.abs(d.X) - box.Half.X, 0), math.max(math.abs(d.Y) - box.Half.Y, 0), math.max(math.abs(d.Z) - box.Half.Z, 0))
				if q.Magnitude <= radius then
					return s
				end
			end
		end
	end
	return nil
end

-- ¿Está dentro del vestíbulo (andando)?
function Stations.inHall(s: Station, pos: Vector3): boolean
	local d = pos - s.Center
	return math.abs(d.X) <= Stations.HallHalf + 4 and math.abs(d.Z) <= Stations.HallHalf + 4 and d.Y >= -6 and d.Y <= Stations.HallHeight + 4
end

---------------------------------------------------------------------
-- Tienda
---------------------------------------------------------------------
Stations.RepairPerPoint = 2 -- $ por punto de casco
Stations.MissilePrice = 15 -- $ por misil

-- Lo que cuesta dejar la nave nueva
function Stations.repairCost(hull: number, maxHull: number): number
	return math.max(0, math.ceil((maxHull - hull) * Stations.RepairPerPoint))
end

function Stations.missileCost(missiles: number, maxMissiles: number): number
	return math.max(0, (maxMissiles - missiles) * Stations.MissilePrice)
end

return Stations
