-- Missions: las misiones secundarias del espacio (tablón de las estaciones; cuentas puras;
-- docs/espacio.md). Todas se repiten: al terminar una, se puede volver a coger.
--
--   Kill    derriba Count enemigos (Kind opcional: "Dron", "Caza")
--   Mine    extrae Count unidades de mineral (Ore opcional: "Cristal"…)
--   Deliver lleva una carga de la estación From a la To (si te derriban, la carga se pierde y la
--           misión vuelve al tablón)
--
-- Estado guardado (data.Space.Missions): { [id] = { P = progreso, At = os.time() al cogerla } }.
-- Como mucho MaxActive a la vez. La recompensa la da el servidor (SpaceService) al completarla.

local Missions = {}

export type Def = {
	Id: string,
	Title: string,
	Text: string,
	Type: string,
	Count: number,
	Kind: string?,
	Ore: string?,
	From: string?,
	To: string?,
	Money: number,
	Chispas: number,
	MinSeconds: number?, -- (entrega) segundos mínimos desde que se coge: no se puede llegar antes volando
}

Missions.MaxActive = 2

Missions.List = {
	{ Id = "Drones", Title = "Limpieza de drones", Text = "Derriba 6 drones de las patrullas (Campo Brasa o Nube Escarcha).", Type = "Kill", Kind = "Dron", Count = 6, Money = 300, Chispas = 3 },
	{ Id = "Cazas", Title = "Duelo de cazas", Text = "Derriba 3 cazas enemigos.", Type = "Kill", Kind = "Caza", Count = 3, Money = 500, Chispas = 5 },
	{ Id = "Mineral", Title = "Pedido de mineral", Text = "Extrae 12 unidades de mineral de cualquier asteroide.", Type = "Mine", Count = 12, Money = 250, Chispas = 2 },
	{ Id = "Cristales", Title = "Cristales solares", Text = "Extrae 3 cristales solares (los asteroides que brillan dorado).", Type = "Mine", Ore = "Cristal", Count = 3, Money = 400, Chispas = 4 },
	{ Id = "CargaCenit", Title = "Carga para Cénit", Text = "Lleva esta carga de la Estación Alba a la Estación Cénit sin que te derriben.", Type = "Deliver", From = "Alba", To = "Cenit", Count = 1, Money = 450, Chispas = 4, MinSeconds = 15 },
	{ Id = "CargaAlba", Title = "Carga para Alba", Text = "Lleva esta carga de la Estación Cénit a la Estación Alba sin que te derriben.", Type = "Deliver", From = "Cenit", To = "Alba", Count = 1, Money = 450, Chispas = 4, MinSeconds = 15 },
} :: { Def }

Missions.ById = {} :: { [string]: Def }
for _, m in Missions.List do
	Missions.ById[m.Id] = m
end

local function active(state: { [string]: any }): number
	local n = 0
	for id, v in state do
		if Missions.ById[id] and type(v) == "table" then
			n += 1
		end
	end
	return n
end
Missions.activeCount = active

-- ¿Se puede coger aquí? (motivo si no: "Unknown", "Active", "Full", "Station")
function Missions.canAccept(state: { [string]: any }, id: string, station: string?): (boolean, string?)
	local def = Missions.ById[id]
	if not def then
		return false, "Unknown"
	end
	if type(state[id]) == "table" then
		return false, "Active"
	end
	if active(state) >= Missions.MaxActive then
		return false, "Full"
	end
	if def.From and def.From ~= station then
		return false, "Station"
	end
	return true, nil
end

function Missions.accept(state: { [string]: any }, id: string, station: string?, now: number): boolean
	if not Missions.canAccept(state, id, station) then
		return false
	end
	state[id] = { P = 0, At = now }
	return true
end

function Missions.abandon(state: { [string]: any }, id: string)
	state[id] = nil
end

-- Un suceso: { Type = "Kill", Kind = "Dron" } · { Type = "Mine", Ore = "Hierro", Count = 1 } ·
-- { Type = "Dock", Station = "Cenit" } · { Type = "Down" }. Devuelve las misiones completadas (y las
-- quita del estado) y las que se pierden (carga derribada).
function Missions.progress(state: { [string]: any }, ev: { [string]: any }): ({ Def }, { Def })
	local done, lost = {}, {}
	for id, st in table.clone(state) do
		local def = Missions.ById[id]
		if not def or type(st) ~= "table" then
			continue
		end
		local add = 0
		if def.Type == "Kill" and ev.Type == "Kill" and (def.Kind == nil or def.Kind == ev.Kind) then
			add = 1
		elseif def.Type == "Mine" and ev.Type == "Mine" and (def.Ore == nil or def.Ore == ev.Ore) then
			add = math.max(0, math.floor(tonumber(ev.Count) or 1))
		elseif def.Type == "Deliver" and ev.Type == "Dock" and ev.Station == def.To and (ev.Now == nil or (tonumber(st.At) or 0) + (def.MinSeconds or 0) <= ev.Now) then
			add = 1
		elseif def.Type == "Deliver" and ev.Type == "Down" then
			state[id] = nil
			table.insert(lost, def)
			continue
		end
		if add > 0 then
			st.P = math.min(def.Count, (tonumber(st.P) or 0) + add)
			if st.P >= def.Count then
				state[id] = nil
				table.insert(done, def)
			end
		end
	end
	return done, lost
end

-- Una línea para el panel: «📋 Drones 2/6 · Carga → Cénit»
function Missions.summary(state: { [string]: any }): string
	local parts = {}
	for _, def in Missions.List do
		local st = state[def.Id]
		if type(st) == "table" then
			if def.Type == "Deliver" then
				table.insert(parts, ("📦 Carga → %s"):format(def.To == "Alba" and "Alba" or "Cénit"))
			else
				table.insert(parts, ("📋 %s %d/%d"):format(def.Title, tonumber(st.P) or 0, def.Count))
			end
		end
	end
	return table.concat(parts, " · ")
end

return Missions
