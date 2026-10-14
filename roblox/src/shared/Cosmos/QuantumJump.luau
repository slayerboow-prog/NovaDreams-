-- QuantumJump: el SALTO CUÁNTICO de la nave (Espacio AAA, fase 6; docs/espacio-aaa/diseno.md). Cuentas
-- puras: el servidor manda (Services/ShipSystems: valida, carga, mueve la nave con
-- AirCombatService.relocate a un sitio seguro y solo entonces gasta), el cliente elige y lo enseña.
--
-- Destinos (del registro de navegación de verdad, nada inventado aparte):
--   * Baliza de Valmar (encima del puerto espacial, en el espacio)
--   * Estaciones (shared/Cosmos/Stations): a la salida de su muelle
--   * Órbita de los 7 planetas (shared/Cosmos/PlanetBodies + Planets): encima de la atmósfera
--   * Puntos de interés DESCUBIERTOS (campos y sectores: shared/Cosmos/NavInfo; data.Space.Found)
--   * El punto de las misiones activas del tablón (NavInfo.missionTargets)
-- Validación: estado, mundo, combate, energía, alcance, distancia mínima, recarga y llegada segura.

local Stations = require(script.Parent.Stations)
local PlanetBodies = require(script.Parent.PlanetBodies)
local Planets = require(script.Parent.Planets)
local NavInfo = require(script.Parent.NavInfo)
local PlanetEntry = require(script.Parent.PlanetEntry)
local ShipAbilities = require(script.Parent.Parent.AirCombat.ShipAbilities)

local QuantumJump = {}

QuantumJump.MaxRange = 60000
QuantumJump.MinRange = 1500
QuantumJump.Clearance = 40 -- radio libre que hace falta al llegar
QuantumJump.Kinds = { Baliza = "Baliza", Estacion = "Estación", Planeta = "Órbita", Campo = "Campo de asteroides", Sector = "Sector (peligro)", Mision = "Misión" }

export type Dest = { Id: string, Name: string, Kind: string, Pos: Vector3, Look: Vector3?, Locked: string?, Note: string? }

-- ctx = { Found = { [poiId] = true }, Missions = data.Space.Missions, PlanetStatus = fn(id) -> estado }
function QuantumJump.list(ctx: { [string]: any }?): { Dest }
	local c = ctx or {}
	local out: { Dest } = {}
	table.insert(out, { Id = "Baliza", Name = "Baliza de Valmar", Kind = "Baliza", Pos = NavInfo.Beacon })
	for _, st in Stations.List do
		local cf = Stations.launch(st)
		table.insert(out, { Id = "Estacion_" .. st.Id, Name = st.Name, Kind = "Estacion", Pos = cf.Position, Look = cf.LookVector })
	end
	for _, b in PlanetBodies.List do
		local p = Planets.ById[b.Id]
		local up = PlanetEntry.frame(b)
		local pos = b.Center + up * (PlanetBodies.entryRadius(b) + 900)
		local status = if c.PlanetStatus then c.PlanetStatus(b.Id) else nil
		table.insert(out, {
			Id = "Planeta_" .. b.Id,
			Name = ("Órbita de %s"):format(if p then p.Name else b.Id),
			Kind = "Planeta",
			Pos = pos,
			Look = (b.Center - pos).Unit,
			Note = if status == "Ready" then "Se puede bajar" else "Solo órbita",
		})
	end
	for _, poi in NavInfo.pois() do
		local found = c.Found and c.Found[poi.Id]
		-- (se llega al borde, mirando hacia el centro: nunca dentro de un campo de rocas)
		local out_ = (poi.Center - NavInfo.Beacon)
		local dir = if out_.Magnitude > 1 then out_.Unit else Vector3.new(1, 0, 0)
		local pos = poi.Center - dir * (poi.Radius + 150)
		table.insert(out, { Id = poi.Id, Name = poi.Name, Kind = poi.Kind, Pos = pos, Look = dir, Locked = if found then nil else "Sin descubrir: ve volando" })
	end
	for _, m in NavInfo.missionTargets(c.Missions) do
		if m.Target then
			table.insert(out, { Id = "Mision_" .. m.Id, Name = ("%s → %s"):format(m.Title, m.TargetName or ""), Kind = "Mision", Pos = m.Target + Vector3.new(0, 120, 0) })
		end
	end
	return out
end

function QuantumJump.find(list: { Dest }, id: string): Dest?
	for _, d in list do
		if d.Id == id then
			return d
		end
	end
	return nil
end

-- Un sitio libre (radio Clearance) cerca del destino: el mismo o en anillos alrededor. collide(pos, r)
function QuantumJump.safeArrival(dest: Dest, collide: (Vector3, number) -> string?, contains: ((Vector3) -> boolean)?): CFrame?
	local look = dest.Look or Vector3.new(0, 0, -1)
	local function free(p: Vector3): boolean
		if collide(p, QuantumJump.Clearance) then
			return false
		end
		if contains and not contains(p) then
			return false
		end
		-- (nunca dentro de la atmósfera de un planeta)
		for _, b in PlanetBodies.List do
			if (p - b.Center).Magnitude < PlanetBodies.entryRadius(b) + 100 then
				return false
			end
		end
		return true
	end
	local function frame(p: Vector3): CFrame
		local l = look.Unit
		local right = l:Cross(Vector3.new(0, 1, 0))
		if right.Magnitude < 1e-3 then
			right = l:Cross(Vector3.new(0, 0, 1))
		end
		right = right.Unit
		return CFrame.fromMatrix(p, right, right:Cross(l).Unit, -l)
	end
	if free(dest.Pos) then
		return frame(dest.Pos)
	end
	for _, r in { 120, 260, 450 } do
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local p = dest.Pos + Vector3.new(math.cos(a) * r, (if k % 2 == 0 then 1 else -1) * r * 0.3, math.sin(a) * r)
			if free(p) then
				return frame(p)
			end
		end
	end
	return nil
end

-- ¿Se puede saltar a `dest` desde aquí? -> ok, motivo, coste, distancia
-- st = { World, Down, Busy, InCombat, Energy, Cooldown, Pos }
function QuantumJump.validate(st: { [string]: any }, dest: Dest?): (boolean, string?, number, number)
	if not dest then
		return false, "Desconocido", 0, 0
	end
	local dist = (dest.Pos - st.Pos).Magnitude
	local cost = ShipAbilities.quantumCost(dist)
	if st.Down then
		return false, "Derribado", cost, dist
	elseif st.Busy then
		return false, "Ocupada", cost, dist
	elseif st.World ~= "Cosmos" then
		return false, if st.World == "Planet" then "Atmosfera" else "Mundo", cost, dist
	elseif dest.Locked then
		return false, "Bloqueada", cost, dist
	elseif (st.Cooldown or 0) > 0 then
		return false, "Recarga", cost, dist
	elseif st.InCombat then
		return false, "Combate", cost, dist
	elseif dist > QuantumJump.MaxRange then
		return false, "Alcance", cost, dist
	elseif dist < QuantumJump.MinRange then
		return false, "Cerca", cost, dist
	elseif (st.Energy or 0) < cost then
		return false, "Energia", cost, dist
	end
	return true, nil, cost, dist
end

return QuantumJump
