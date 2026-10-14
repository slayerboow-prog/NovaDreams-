-- NavInfo: navegación de la nave en el Sistema Valmar (cuentas puras; Espacio AAA,
-- docs/espacio-aaa/diseno.md). Lo usan el HUD (zona B: sistema, zona, distancia; zona D: radar; zona E:
-- misiones), el servidor (lo que manda en «Nav») y el salto cuántico (shared/Cosmos/QuantumJump).
--
--   NavInfo.System                     "Sistema Valmar" (nunca otro nombre)
--   NavInfo.place(world, pos, planet)  { Zone, Detail } (estación, campo, sector, planeta, capa…)
--   NavInfo.missionTargets(state)      misiones del tablón activas con su progreso y a dónde ir
--   NavInfo.pois()                     puntos de interés que se descubren (campos y sectores)
--   NavInfo.discoverAt(pos, found)     los que se descubren al pasar por aquí (para data.Space.Found)
--   NavInfo.distanceText(studs)        «850 m», «2,4 km»

local Layers = require(script.Parent.Layers)
local Stations = require(script.Parent.Stations)
local Zone = require(script.Parent.Zone)
local Missions = require(script.Parent.Missions)
local PlanetBodies = require(script.Parent.PlanetBodies)
local Planets = require(script.Parent.Planets)
local Access = require(script.Parent.Access)

local NavInfo = {}

NavInfo.System = "Sistema Valmar"
NavInfo.MetersPerStud = 0.28 -- (como la altitud del avión: shared/Flight.METERS)

-- La baliza de Valmar: en el espacio, encima del puerto espacial
NavInfo.Beacon = Vector3.new(Access.Port.X, Layers.SpaceY + 300, Access.Port.Z)

function NavInfo.distanceText(studs: number): string
	local m = math.max(0, studs) * NavInfo.MetersPerStud
	if m < 1000 then
		return ("%d m"):format(math.floor(m / 10 + 0.5) * 10)
	end
	local km = m / 1000
	local text = if km < 10 then ("%.1f km"):format(km) else ("%d km"):format(math.floor(km + 0.5))
	return (string.gsub(text, "%.", ","))
end

-- Dónde estás, en palabras: { Zone = "Cinturón de Hierro", Detail = "Campo de asteroides" }
function NavInfo.place(world: string?, pos: Vector3, planet: string?): { Zone: string, Detail: string }
	if world == "Planet" then
		local p = planet and Planets.ById[planet]
		return { Zone = if p then p.Name else "Planeta", Detail = "Superficie" }
	elseif world == "Arena" then
		return { Zone = "Arena de pruebas", Detail = "Combate" }
	end
	local st = Stations.safeAt(pos)
	if st then
		return { Zone = st.Name, Detail = "Zona segura" }
	end
	local body = PlanetBodies.approachAt(pos)
	if body then
		local p = Planets.ById[body.Id]
		return { Zone = ("Órbita de %s"):format(if p then p.Name else body.Id), Detail = ("Altura %s"):format(NavInfo.distanceText(PlanetBodies.altitude(body, pos))) }
	end
	local sector = Zone.sectorAt(pos)
	if sector then
		return { Zone = sector.Name, Detail = ("Peligro · nivel %d"):format(sector.Level) }
	end
	local field = Zone.fieldAt(pos)
	if field then
		return { Zone = field.Name, Detail = "Campo de asteroides" }
	end
	local layer = Layers.layerAt(pos.Y)
	return { Zone = Layers.Names[layer] or layer, Detail = ("Altitud %s"):format(NavInfo.distanceText(pos.Y)) }
end

-- Puntos de interés que se descubren volando (campos de asteroides y sectores)
export type Poi = { Id: string, Name: string, Kind: string, Center: Vector3, Radius: number }
function NavInfo.pois(): { Poi }
	local out = {}
	for _, f in Zone.Fields do
		table.insert(out, { Id = "Campo_" .. f.Id, Name = f.Name, Kind = "Campo", Center = f.Center, Radius = f.Radius })
	end
	for _, s in Zone.Sectors do
		table.insert(out, { Id = "Sector_" .. s.Id, Name = s.Name, Kind = "Sector", Center = s.Center, Radius = s.Radius })
	end
	return out
end

-- Los que se descubren al estar en `pos` y aún no están en `found` ({ [id] = true })
function NavInfo.discoverAt(pos: Vector3, found: { [string]: any }?): { Poi }
	local out = {}
	for _, p in NavInfo.pois() do
		if not (found and found[p.Id]) and (pos - p.Center).Magnitude <= p.Radius then
			table.insert(out, p)
		end
	end
	return out
end

-- A dónde llevan las misiones del tablón (para el HUD, el radar y el salto)
local MISSION_TARGET = {
	Drones = function()
		return Zone.Sectors[1].Center, Zone.Sectors[1].Name
	end,
	Cazas = function()
		return Zone.Sectors[2].Center, Zone.Sectors[2].Name
	end,
	Mineral = function()
		return Zone.Fields[1].Center, Zone.Fields[1].Name
	end,
	Cristales = function()
		return Zone.Fields[3].Center, Zone.Fields[3].Name
	end,
}

export type MissionTarget = { Id: string, Title: string, Text: string, Progress: string, Done: number, Count: number, Target: Vector3?, TargetName: string? }
function NavInfo.missionTargets(state: { [string]: any }?): { MissionTarget }
	local out = {}
	for _, def in Missions.List do
		local st = state and state[def.Id]
		if type(st) == "table" then
			local target, name = nil, nil
			if def.Type == "Deliver" and def.To and Stations.ById[def.To] then
				local station = Stations.ById[def.To]
				target, name = station.Dock, station.Name
			elseif MISSION_TARGET[def.Id] then
				target, name = MISSION_TARGET[def.Id]()
			end
			local p = math.floor(tonumber(st.P) or 0)
			table.insert(out, {
				Id = def.Id,
				Title = def.Title,
				Text = def.Text,
				Progress = if def.Type == "Deliver" then "Entregar" else ("%d/%d"):format(p, def.Count),
				Done = p,
				Count = def.Count,
				Target = target,
				TargetName = name,
			})
		end
	end
	return out
end

-- Rumbo (grados, 0 = norte = -Z, 90 = este = +X) de una dirección
function NavInfo.heading(look: Vector3): number
	local deg = math.deg(math.atan2(look.X, -look.Z))
	return (deg % 360 + 360) % 360
end

return NavInfo
