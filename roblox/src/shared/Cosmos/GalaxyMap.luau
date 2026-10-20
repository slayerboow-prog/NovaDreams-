-- GalaxyMap: las cuentas del MAPA GALÁCTICO (cuentas puras; lo dibuja Controllers/GalaxyMapUI, los datos
-- del jugador los manda Services/GalaxyMapService; referencia del dueño:
-- docs/espacio-aaa/referencia-mapa-galactico.png, explicado en docs/espacio-aaa/mapa-galactico.md).
--
-- NUESTRO universo, no el del dibujo: en el centro el Sistema Valmar (Valmar, su luna y las estaciones
-- Alba y Cénit) y, en el anillo, los 7 planetas de la Saga 2 en el orden del dueño (Tefra → Miasma →
-- Siroco → Nivalis → Umbría → Tálasa → Vértice). Por dentro, los puntos de interés que ya existen en el
-- juego (campos de asteroides y sectores de shared/Cosmos/Zone, estaciones de shared/Cosmos/Stations) y
-- el Frente de Ovilla (órbita de Tefra, aún sin construir: «próximamente»).
--
--   GalaxyMap.entries(snap, opts)   la lista de lo que sale en el mapa con su estado DE VERDAD (datos del
--                                   jugador: planetas abiertos o cerrados, visitados, terminados,
--                                   descubiertos, misiones activas, evento global, dónde estás)
--   GalaxyMap.travel(entry, st)     ¿se puede VIAJAR ahí ahora? Siempre por el camino que ya existe:
--                                   salto cuántico (shared/Cosmos/QuantumJump, lo valida el servidor en
--                                   Services/ShipSystems), VALMAR (SpaceService.home) o, sin nave, la ruta
--                                   del GPS al puerto espacial. Nunca un teletransporte gratis.
--   GalaxyMap.place(entry, cx, cy, rx, ry)   dónde va en la elipse (píxeles del lienzo)
--   GalaxyMap.Legend                las 7 filas de la LEYENDA con su color

local Planets = require(script.Parent.Planets)
local PlanetBodies = require(script.Parent.PlanetBodies)
local Stations = require(script.Parent.Stations)
local Zone = require(script.Parent.Zone)
local NavInfo = require(script.Parent.NavInfo)
local QuantumJump = require(script.Parent.QuantumJump)
local SpaceEvents = require(script.Parent.SpaceEvents)
local Access = require(script.Parent.Access)
local ShipAbilities = require(script.Parent.Parent.AirCombat.ShipAbilities)

local GalaxyMap = {}

local rgb = Color3.fromRGB

GalaxyMap.Title = "MAPA GALÁCTICO"
GalaxyMap.Subtitle = "Explora el universo · Descubre nuevos mundos"
GalaxyMap.System = NavInfo.System -- «Sistema Valmar» (nunca otro nombre)
GalaxyMap.CenterSub = "Valmar · su luna · Estaciones Alba y Cénit"

-- Orden del dueño (docs/planetas/diseno-mundos.md): así van por el anillo, empezando arriba a la izquierda
-- y siguiendo como las agujas del reloj (ángulos de pantalla: 0 = derecha, 90 = abajo)
GalaxyMap.Order = { "Tefra", "Miasma", "Siroco", "Nivalis", "Umbria", "Talasa", "Vertice" }
GalaxyMap.Angles = { Tefra = -150, Miasma = -100, Siroco = -48, Nivalis = 2, Umbria = 55, Talasa = 116, Vertice = 168 }

-- Colores de la leyenda (como el dibujo: rombos de colores)
GalaxyMap.Colors = {
	You = rgb(70, 190, 255),
	Visited = rgb(70, 225, 150),
	Unknown = rgb(150, 162, 186),
	Main = rgb(255, 200, 60),
	Side = rgb(70, 200, 255),
	Event = rgb(255, 75, 75),
	Poi = rgb(190, 120, 255),
}
GalaxyMap.Legend = {
	{ Id = "You", Text = "Tu posición" },
	{ Id = "Visited", Text = "Planeta visitado" },
	{ Id = "Unknown", Text = "Planeta no descubierto" },
	{ Id = "Main", Text = "Misión principal" },
	{ Id = "Side", Text = "Misión secundaria" },
	{ Id = "Event", Text = "Evento global" },
	{ Id = "Poi", Text = "Punto de interés" },
}

-- Textos de cada estado (la línea de debajo del nombre)
GalaxyMap.StatusText = {
	Home = "Tu hogar",
	MainHere = "Misión principal",
	Explored = "Explorado",
	Visited = "Visitado",
	Unexplored = "Por explorar",
	Event = "Evento global",
	Missions = "Misiones activas",
	Unknown = "Desconocido 🔒",
	Safe = "Zona segura",
	Found = "Descubierto",
	Hidden = "Sin descubrir 🔒",
	Soon = "Próximamente 🔒",
}

-- Puntos de interés por dentro del anillo: los que ya hay en el juego. Su sitio en el mapa es aproximado
-- (repartido para que se lea en el móvil); el de verdad lo usa el salto cuántico.
--   Ring: 0 = el centro, 1 = el anillo de los planetas
GalaxyMap.Inner = {
	{ Id = "Estacion_Alba", Kind = "Station", Station = "Alba", Angle = 180, Ring = 0.3 },
	{ Id = "Estacion_Cenit", Kind = "Station", Station = "Cenit", Angle = 0, Ring = 0.3 },
	{ Id = "Hierro", Kind = "Poi", Field = "Hierro", Angle = 148, Ring = 0.62 },
	{ Id = "Escarcha", Kind = "Poi", Field = "Escarcha", Sector = "Escarcha", Angle = -32, Ring = 0.6 },
	{ Id = "Brasa", Kind = "Poi", Field = "Brasa", Sector = "Brasa", Angle = 30, Ring = 0.6 },
	{ Id = "Ruta", Kind = "Poi", Sector = "Ruta", Angle = 92, Ring = 0.62 },
	-- (diseño de Tefra, docs/planetas/diseno-mundos.md: la órbita entre Tefra y su luna. Aún no existe)
	{ Id = "Ovilla", Kind = "Future", Name = "Frente de Ovilla", Sub = "Órbita de Tefra", Angle = -128, Ring = 0.8 },
}

export type Entry = {
	Id: string,
	Kind: string, -- "Center" | "Planet" | "Station" | "Poi" | "Future"
	Name: string,
	Sub: string,
	Status: string, -- clave de GalaxyMap.StatusText
	StatusText: string,
	Icon: string, -- clave de GalaxyMap.Colors (el rombo)
	Color: Color3,
	Locked: string?, -- motivo (no se puede viajar)
	Here: boolean, -- estás aquí (marcador «Tu posición»)
	Missions: number,
	Event: string?,
	Angle: number,
	Ring: number,
	Size: number, -- tamaño relativo (1 = un planeta normal)
	Planet: string?, -- id del planeta (textura)
	Hue: Color3,
	Dest: string?, -- destino del salto cuántico (shared/Cosmos/QuantumJump)
	Lines: { { string } }, -- filas de la tarjeta: { etiqueta, valor }
}

local function count(t: any): number
	local n = 0
	if type(t) == "table" then
		for _, v in t do
			if v then
				n += 1
			end
		end
	end
	return n
end

-- La misión del tablón que lleva a este sitio (por su nombre: NavInfo.missionTargets)
local function sideMissionsAt(snap: { [string]: any }, names: { string }): number
	local n = 0
	for _, m in snap.SideMissions or {} do
		for _, name in names do
			if m.TargetName == name then
				n += 1
			end
		end
	end
	return n
end

-- El evento global de ahora (shared/Cosmos/SpaceEvents) si está en marcha en este campo o sector
local function eventAt(ev: SpaceEvents.Event?, field: string?, sector: string?): string?
	if not ev or not ev.Active then
		return nil
	end
	if (ev.Kind == "Tormenta" and ev.PlaceId == field) or (ev.Kind == "Incursion" and ev.PlaceId == sector) then
		return ev.Title
	end
	return nil
end

-- Lo que sale en el mapa. snap = lo que manda el servidor (Services/GalaxyMapService.snapshot) o {}:
--   { SagaDone, Tester, CanFly, Planets = { [id] = { Status, Need, Text, Done, Visited, Missions } },
--     Found = { [poiId] = true }, SideMissions = { { Id, Title, Progress, TargetName } }, Invasion = texto? }
-- opts = { Now = segundos de servidor, Main = texto de la misión principal?, Where = dónde estás:
--          { Planet = id?, InShip = bool?, World = "Cosmos"|"Planet"?, Pos = Vector3? } }
function GalaxyMap.entries(snap: { [string]: any }?, opts: { [string]: any }?): { Entry }
	local s = snap or {}
	local o = opts or {}
	local where = o.Where or {}
	local ev = if o.Now then SpaceEvents.at(o.Now) else nil
	local here = GalaxyMap.hereId(where)
	local out: { Entry } = {}
	local C = GalaxyMap.Colors

	-- Centro: el Sistema Valmar
	do
		local invasion = if type(s.Invasion) == "string" and s.Invasion ~= "" then s.Invasion else nil
		local main = if type(o.Main) == "string" and o.Main ~= "" then o.Main else nil
		local status = if invasion then "Event" elseif main then "MainHere" else "Home"
		local icon = if invasion then "Event" elseif main then "Main" else "Visited"
		local missions = (if main then 1 else 0)
		table.insert(out, {
			Id = "Valmar",
			Kind = "Center",
			Name = GalaxyMap.System,
			Sub = GalaxyMap.CenterSub,
			Status = status,
			StatusText = if invasion then "Evento global" else GalaxyMap.StatusText[status],
			Icon = icon,
			Color = C[icon],
			Locked = nil,
			Here = here == "Valmar",
			Missions = missions,
			Event = invasion,
			Angle = 0,
			Ring = 0,
			Size = 1.25,
			Planet = "Valmar",
			Hue = rgb(120, 200, 255),
			Dest = nil,
			Lines = {
				{ "Mundos", "Valmar y su luna" },
				{ "Estaciones", ("%d (%s)"):format(#Stations.List, "Alba y Cénit") },
				{ "Estado", if invasion then "⚠ " .. invasion else (if main then "Misión principal activa" else "Tu hogar") },
			},
		})
	end

	-- Los 7 planetas
	for _, id in GalaxyMap.Order do
		local p = Planets.ById[id]
		local body = PlanetBodies.ById[id]
		local info = (s.Planets and s.Planets[id]) or {}
		local status = info.Status
		if type(status) ~= "string" then
			status = (Planets.status(id, { SagaDone = s.SagaDone, Tester = s.Tester, Done = {} }))
		end
		local locked: string? = nil
		if status ~= "Ready" then
			locked = if type(info.Text) == "string" then info.Text else Planets.message(id, status, info.Need)
		end
		local missions = math.max(0, math.floor(tonumber(info.Missions) or 0))
		local key
		if locked then
			key = "Unknown"
		elseif missions > 0 then
			key = "Missions"
		elseif info.Done then
			key = "Explored"
		elseif info.Visited or here == id then
			key = "Visited"
		else
			key = "Unexplored"
		end
		local icon = if locked then "Unknown" elseif missions > 0 then "Side" elseif info.Done or info.Visited or here == id then "Visited" else "Unknown"
		local size = if body then math.clamp(body.Radius / 2500, 0.8, 1.2) else 1
		table.insert(out, {
			Id = id,
			Kind = "Planet",
			Name = p.Name,
			Sub = p.City,
			Status = key,
			StatusText = GalaxyMap.StatusText[key],
			Icon = icon,
			Color = C[icon],
			Locked = locked,
			Here = here == id,
			Missions = missions,
			Event = nil,
			Angle = GalaxyMap.Angles[id] or 0,
			Ring = 1,
			Size = size,
			Planet = id,
			Hue = p.Hue,
			Dest = "Planeta_" .. id,
			Lines = {
				{ "Ciudad", if locked then "???" else p.City },
				{ "Misiones", tostring(missions) },
				{ "Estado", GalaxyMap.StatusText[key] },
			},
		})
	end

	-- Por dentro: estaciones, campos, sectores y el Frente de Ovilla
	local found = s.Found or {}
	for _, def in GalaxyMap.Inner do
		local e: Entry
		if def.Kind == "Station" then
			local st = Stations.ById[def.Station]
			local missions = sideMissionsAt(s, { st.Name })
			local key = if missions > 0 then "Missions" else "Safe"
			e = {
				Id = def.Id, Kind = "Station", Name = st.Name, Sub = "Estación · tienda y tablón", Status = key,
				StatusText = GalaxyMap.StatusText[key], Icon = if missions > 0 then "Side" else "Poi", Color = C.Poi,
				Locked = nil, Here = here == def.Id, Missions = missions, Event = nil, Angle = def.Angle, Ring = def.Ring, Size = 0.5,
				Planet = nil, Hue = rgb(150, 210, 255), Dest = def.Id,
				Lines = { { "Tipo", "Estación (zona segura)" }, { "Misiones", tostring(missions) }, { "Estado", GalaxyMap.StatusText[key] } },
			}
		elseif def.Kind == "Future" then
			e = {
				Id = def.Id, Kind = "Future", Name = def.Name, Sub = def.Sub, Status = "Soon",
				StatusText = GalaxyMap.StatusText.Soon, Icon = "Unknown", Color = C.Unknown,
				Locked = "🔒 Frente de Ovilla: llegará con la historia de Tefra (próximamente)", Here = false, Missions = 0,
				Event = nil, Angle = def.Angle, Ring = def.Ring, Size = 0.5, Planet = nil, Hue = rgb(180, 150, 160), Dest = nil,
				Lines = { { "Tipo", "Órbita de Tefra" }, { "Misiones", "0" }, { "Estado", "Próximamente" } },
			}
		else
			local field = nil
			for _, f in Zone.Fields do
				if f.Id == def.Field then
					field = f
				end
			end
			local sector = nil
			for _, z in Zone.Sectors do
				if z.Id == def.Sector then
					sector = z
				end
			end
			local fieldId = if field then "Campo_" .. field.Id else nil
			local sectorId = if sector then "Sector_" .. sector.Id else nil
			-- (se puede saltar al campo si está descubierto; si no, al sector si lo está)
			local dest = if fieldId and found[fieldId] then fieldId elseif sectorId and found[sectorId] then sectorId else (fieldId or sectorId)
			local isFound = (fieldId ~= nil and found[fieldId] ~= nil) or (sectorId ~= nil and found[sectorId] ~= nil)
			local names = {}
			if field then
				table.insert(names, field.Name)
			end
			if sector then
				table.insert(names, sector.Name)
			end
			local missions = sideMissionsAt(s, names)
			local event = eventAt(ev, def.Field, def.Sector)
			local key = if not isFound then "Hidden" elseif event then "Event" elseif missions > 0 then "Missions" else "Found"
			local name = if field then field.Name else (if sector then sector.Name else def.Id)
			local sub = if field and sector then ("Campo de asteroides · peligro %d"):format(sector.Level)
				elseif field then "Campo de asteroides"
				elseif sector then ("Sector peligroso · nivel %d"):format(sector.Level)
				else ""
			local icon = if event then "Event" elseif missions > 0 then "Side" elseif isFound then "Poi" else "Unknown"
			e = {
				Id = def.Id, Kind = "Poi", Name = name, Sub = sub, Status = key, StatusText = GalaxyMap.StatusText[key],
				Icon = icon, Color = C[icon],
				Locked = if isFound then nil else "🔒 " .. name .. ": sin descubrir. Ve volando hasta allí para añadirlo al salto cuántico",
				Here = here == def.Id, Missions = missions, Event = event, Angle = def.Angle, Ring = def.Ring, Size = 0.5,
				Planet = nil, Hue = if sector then rgb(255, 120, 90) else rgb(190, 160, 120), Dest = dest,
				Lines = { { "Tipo", sub }, { "Misiones", tostring(missions) }, { "Estado", if event then "⚠ " .. event else GalaxyMap.StatusText[key] } },
			}
		end
		table.insert(out, e)
	end
	return out
end

-- ¿Dónde estás? (id de una entrada del mapa): en un planeta, ese; en la nave en el espacio, lo más cercano
-- (estación, campo, sector o planeta); si no, Valmar.
function GalaxyMap.hereId(where: { [string]: any }?): string
	local w = where or {}
	local planet = Planets.canonical(w.Planet)
	if planet and Planets.ById[planet] then
		return planet
	end
	if w.World == "Cosmos" and typeof(w.Pos) == "Vector3" then
		local pos = w.Pos :: Vector3
		for _, st in Stations.List do
			if (pos - st.Center).Magnitude < 1500 then
				return "Estacion_" .. st.Id
			end
		end
		for _, b in PlanetBodies.List do
			if (pos - b.Center).Magnitude < PlanetBodies.entryRadius(b) + PlanetBodies.ApproachDepth then
				return b.Id
			end
		end
		for _, def in GalaxyMap.Inner do
			for _, f in Zone.Fields do
				if f.Id == def.Field and (pos - f.Center).Magnitude <= f.Radius then
					return def.Id
				end
			end
			for _, z in Zone.Sectors do
				if z.Id == def.Sector and (pos - z.Center).Magnitude <= z.Radius then
					return def.Id
				end
			end
		end
	end
	return "Valmar"
end

-- Dónde va una entrada en la elipse del anillo (centro cx, cy; radios rx, ry)
function GalaxyMap.place(e: { Angle: number, Ring: number }, cx: number, cy: number, rx: number, ry: number): (number, number)
	local a = math.rad(e.Angle)
	return cx + math.cos(a) * rx * e.Ring, cy + math.sin(a) * ry * e.Ring
end

export type Travel = { Ok: boolean, Action: string?, Dest: string?, Label: string, Reason: string?, Cost: number?, Dist: number? }

-- ¿Se puede viajar a `e` ahora? st = lo que se sabe en el cliente (Controllers/GalaxyMapUI):
--   { CanFly, InShip, World ("Cosmos" | "Planet" | nil), Planet (id a pie o en la nave), Down, NearPort,
--     Busy, InCombat, Energy, Cooldown, Pos, Found }
-- Devuelve Action: "Quantum" (salto cuántico a Dest), "Home" (VALMAR) o "Route" (GPS al puerto espacial).
-- Las reglas son las del juego (QuantumJump.validate, Access.canFly…): el servidor lo vuelve a mirar todo.
function GalaxyMap.travel(e: Entry, st: { [string]: any }): Travel
	local label = "VIAJAR"
	if e.Locked then
		return { Ok = false, Label = label, Reason = e.Locked }
	end
	local planet = Planets.canonical(st.Planet)
	if e.Kind == "Center" then
		if not st.InShip and not planet then
			return { Ok = false, Label = label, Reason = "🏠 Ya estás en Valmar" }
		end
		if not st.InShip then
			return { Ok = false, Label = label, Reason = "🚀 Sube a tu nave: desde ella, VALMAR te lleva a casa" }
		end
		if st.Down then
			return { Ok = false, Label = label, Reason = "⛔ " .. ShipAbilities.Reasons.Derribado }
		end
		return { Ok = true, Action = "Home", Label = label }
	end
	if not e.Dest then
		return { Ok = false, Label = label, Reason = "Próximamente" }
	end
	if not st.CanFly then
		return { Ok = false, Label = label, Reason = Access.Messages.Locked }
	end
	if not st.InShip then
		if planet then
			if planet == e.Planet then
				return { Ok = false, Label = label, Reason = ("📍 Ya estás en %s"):format(e.Name) }
			end
			return { Ok = false, Label = label, Reason = "🚀 Sube a tu nave y sal a la órbita para saltar" }
		end
		if st.NearPort then
			return { Ok = false, Label = label, Reason = "🚀 Sube a la nave en la pista del puerto espacial («Subir a la nave») y despega" }
		end
		return { Ok = true, Action = "Route", Label = "RUTA AL PUERTO", Reason = "🚀 Hace falta la nave: el GPS te lleva al puerto espacial (islote del oeste)" }
	end
	if st.World == "Planet" then
		if planet == e.Planet then
			return { Ok = false, Label = label, Reason = ("📍 Ya estás en %s"):format(e.Name) }
		end
		return { Ok = false, Label = label, Reason = "⛔ " .. ShipAbilities.Reasons.Atmosfera .. ": sube hasta el espacio para saltar" }
	end
	-- En la nave, en el espacio: el salto cuántico de siempre (mismos destinos y mismas reglas)
	local list = QuantumJump.list({ Found = st.Found or {} })
	local dest = QuantumJump.find(list, e.Dest)
	if not dest then
		return { Ok = false, Label = label, Reason = "⛔ " .. ShipAbilities.Reasons.Desconocido }
	end
	local pos = if typeof(st.Pos) == "Vector3" then st.Pos else NavInfo.Beacon
	local ok, why, cost, dist = QuantumJump.validate({
		World = "Cosmos",
		Down = st.Down,
		Busy = st.Busy,
		InCombat = st.InCombat,
		Energy = if st.Energy ~= nil then st.Energy else ShipAbilities.Energy.Max,
		Cooldown = st.Cooldown or 0,
		Pos = pos,
	}, dest)
	if not ok then
		local text = ShipAbilities.Reasons[why or ""] or why or "?"
		if why == "Recarga" and (st.Cooldown or 0) > 0 then
			text = ("%s (%d s)"):format(text, math.ceil(st.Cooldown))
		elseif why == "Energia" then
			text = ("%s (⚡ %d)"):format(text, cost)
		end
		return { Ok = false, Label = label, Reason = "⛔ " .. text, Cost = cost, Dist = dist }
	end
	return { Ok = true, Action = "Quantum", Dest = dest.Id, Label = label, Cost = cost, Dist = dist }
end

-- Cuántas cosas hay que hacer en total (para la tarjeta del centro y las pruebas)
function GalaxyMap.count(t: any): number
	return count(t)
end

return GalaxyMap
