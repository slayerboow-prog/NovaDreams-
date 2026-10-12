-- RaceSim (compartido): carreras de verdad sin nada de Roblox (Sports/Track). El servidor (RaceService)
-- la hace avanzar con la posición de la persona y sus «¡ya!»; aquí corren las máquinas, se da la
-- salida y se ve quién llega antes. Se prueba en scripts/test-atletismo.luau.
--
-- Modos:
--   Carrera  una recta, una calle por corredor. «Preparados… listos… ¡YA!» con espera al azar; quien
--            sale antes del disparo hace salida nula (la primera vez se repite la salida; la segunda,
--            descalificado). Puesto 1 = el primero en cruzar la meta.
--   Relevo   ida y vuelta (relevo de lanzadera): cada equipo en su calle, 4 postas. La persona corre
--            la última: tiene que coger el testigo (botón) cuando su compañero llega a la zona de
--            relevo; si tarda, el testigo se cae y pierde tiempo. Gana el equipo que acaba antes.
--
-- Cada corredor: { Id, Team, Lane, Human, Skill, X (distancia en su posta), Leg, Done, Time }.

local Track = require(script.Parent.Track)

local RaceSim = {}

export type Sim = { [string]: any }

RaceSim.Config = {
	Tick = 1 / 30,
	SetMin = 1.4, -- «listos…» dura entre esto…
	SetMax = 2.6, -- …y esto (al azar: no se puede adivinar)
	FalseStartLimit = 2, -- a la segunda, descalificado
	ZoneBefore = 7, -- la zona de relevo empieza antes de la línea…
	ZoneAfter = 3, -- …y acaba algo después
	TakeReach = 3.5, -- distancia para coger el testigo
	DropPenalty = 2, -- segundos que se pierden si se cae el testigo
	TakeTimeout = 2.2, -- sin cogerlo en este tiempo, se cae
	Timeout = 90, -- la carrera termina sí o sí (la historia nunca se para)
}
local CFG = RaceSim.Config

local function event(sim: Sim, kind: string, data: { [string]: any }?)
	local e = data or {}
	e.Kind = kind
	e.T = sim.T
	table.insert(sim.Events, e)
end

function RaceSim.new(track: Track.Track, opts: { [string]: any }?): Sim
	local o = opts or {}
	return {
		Track = track,
		Mode = o.Mode or "Carrera",
		Legs = o.Legs or 4,
		SpeedScale = o.SpeedScale or 1,
		Rng = o.Rng or Random.new(o.Seed or 1),
		T = 0,
		Phase = "Idle",
		PhaseUntil = 0,
		GunAt = 0,
		Runners = {},
		Order = {},
		Finish = {}, -- ids (o equipos, en el relevo) por orden de llegada
		FalseStarts = 0,
		Events = {},
		Over = false,
		Accumulator = 0,
	}
end

-- spec: { Id, Name, Npc, Team, Lane, Human, Skill, Leg (relevo: qué posta corre, 1..Legs) }
function RaceSim.addRunner(sim: Sim, spec: { [string]: any })
	local r = {
		Id = spec.Id,
		Name = spec.Name or spec.Id,
		Npc = spec.Npc,
		Team = spec.Team or spec.Lane or 1,
		Lane = spec.Lane or 1,
		Human = spec.Human == true,
		Skill = math.clamp(spec.Skill or 0.5, 0, 1),
		Leg = spec.Leg or 1,
		X = 0, -- recorrido en su posta (0 = su línea)
		Speed = 0,
		Running = false,
		Done = false,
		Time = nil :: number?,
		Reaction = 0.15 + (1 - (spec.Skill or 0.5)) * 0.15,
		Waiting = nil :: number?, -- (relevo) desde cuándo espera el testigo en la zona
	}
	sim.Runners[r.Id] = r
	table.insert(sim.Order, r.Id)
	return r
end

-- Dónde está un corredor (en coordenadas de la recta)
function RaceSim.position(sim: Sim, r: any): Vector3
	local t = sim.Track
	local forward = sim.Mode ~= "Relevo" or r.Leg % 2 == 1
	local x = if forward then r.X else t.Length - r.X
	return Track.lanePoint(t, r.Lane, x)
end

-- Hacia dónde corre (+1 / -1 en X)
function RaceSim.direction(sim: Sim, r: any): number
	if sim.Mode == "Relevo" and r.Leg % 2 == 0 then
		return -1
	end
	return 1
end

local function topSpeed(sim: Sim, r: any): number
	return Track.Stride.Walk * sim.SpeedScale * (1.2 + 0.3 * r.Skill)
end

function RaceSim.start(sim: Sim)
	sim.Over = false
	for _, id in sim.Order do
		local r = sim.Runners[id]
		r.X = 0
		r.Speed = 0
		r.Done = false
		r.Time = nil
		-- En el relevo empieza corriendo la primera posta de cada equipo
		r.Running = false
		r.Active = sim.Mode ~= "Relevo" or r.Leg == 1
		event(sim, "Place", { Id = id, P = RaceSim.position(sim, r), Dir = RaceSim.direction(sim, r) })
	end
	sim.Phase = "Marks"
	sim.PhaseUntil = sim.T + 1.6
	event(sim, "Marks", {})
end

-- La persona ha salido (se ha movido o ha pulsado) antes o después del disparo
function RaceSim.humanGo(sim: Sim, id: string)
	local r = sim.Runners[id]
	if not r or not r.Active or r.Running or r.Done then
		return
	end
	if sim.Phase == "Marks" or sim.Phase == "Set" then
		sim.FalseStarts += 1
		if sim.FalseStarts >= CFG.FalseStartLimit then
			r.Done = true
			r.Disqualified = true
			event(sim, "FalseStart", { Id = id, Out = true })
			-- La carrera sigue sin ti (la historia la da por perdida al acabar)
			sim.Phase = "Run"
			sim.GunAt = sim.T
			for _, oid in sim.Order do
				local o = sim.Runners[oid]
				if o.Active and not o.Done then
					o.Running = true
					o.StartAt = sim.T + o.Reaction
				end
			end
		else
			event(sim, "FalseStart", { Id = id, Out = false })
			RaceSim.start(sim)
		end
		return
	end
	if sim.Phase == "Run" then
		r.Running = true
		r.StartAt = sim.T
		event(sim, "Go", { Id = id, Reaction = sim.T - sim.GunAt })
	end
end

-- La posición de la persona (lo que ha corrido en su posta, en studs) y su velocidad
function RaceSim.setHuman(sim: Sim, id: string, x: number, speed: number?)
	local r = sim.Runners[id]
	if not r or r.Done then
		return
	end
	if r.Running then
		r.X = math.max(r.X, math.min(x, sim.Track.Length + 2))
		r.Speed = speed or r.Speed
	end
end

-- Relevo: la persona intenta coger el testigo
function RaceSim.take(sim: Sim, id: string): boolean
	local r = sim.Runners[id]
	if not r or sim.Mode ~= "Relevo" or r.Active or r.Done then
		return false
	end
	local incoming = RaceSim.incoming(sim, r)
	if not incoming then
		return false
	end
	local gap = sim.Track.Length - incoming.X
	if gap <= CFG.TakeReach then
		RaceSim.handOver(sim, incoming, r, false)
		return true
	end
	return false
end

-- El compañero que le trae el testigo (la posta anterior de su equipo, si está corriendo)
function RaceSim.incoming(sim: Sim, r: any): any
	for _, id in sim.Order do
		local o = sim.Runners[id]
		if o.Team == r.Team and o.Leg == r.Leg - 1 and o.Active and not o.Done then
			return o
		end
	end
	return nil
end

function RaceSim.handOver(sim: Sim, from: any, to: any, dropped: boolean)
	from.Done = true
	from.Active = false
	from.Running = false
	to.Active = true
	to.Running = true
	to.StartAt = sim.T + (if dropped then CFG.DropPenalty else 0)
	to.Waiting = nil
	event(sim, "Exchange", { From = from.Id, To = to.Id, Dropped = dropped, Team = to.Team })
end

local function finishRunner(sim: Sim, r: any)
	r.Done = true
	r.Running = false
	r.Time = sim.T - sim.GunAt
	local key = if sim.Mode == "Relevo" then r.Team else r.Id
	if not table.find(sim.Finish, key) then
		table.insert(sim.Finish, key)
		event(sim, "Finish", { Id = r.Id, Team = r.Team, Place = #sim.Finish, Time = r.Time })
	end
end

local function allDone(sim: Sim): boolean
	for _, id in sim.Order do
		local r = sim.Runners[id]
		if r.Active and not r.Done then
			return false
		end
		if sim.Mode == "Relevo" and r.Leg == sim.Legs and not r.Done then
			return false
		end
	end
	return true
end

local function tick(sim: Sim, dt: number)
	sim.T += dt
	local phase = sim.Phase
	if phase == "Idle" or phase == "Over" then
		return
	end
	if phase == "Marks" and sim.T >= sim.PhaseUntil then
		sim.Phase = "Set"
		sim.PhaseUntil = sim.T + CFG.SetMin + sim.Rng:NextNumber() * (CFG.SetMax - CFG.SetMin)
		event(sim, "Set", {})
	elseif phase == "Set" and sim.T >= sim.PhaseUntil then
		sim.Phase = "Run"
		sim.GunAt = sim.T
		event(sim, "Gun", {})
		for _, id in sim.Order do
			local r = sim.Runners[id]
			if r.Active and not r.Human then
				r.Running = true
				r.StartAt = sim.T + r.Reaction + sim.Rng:NextNumber() * 0.08
			end
		end
	elseif phase == "Run" then
		local length = sim.Track.Length
		for _, id in sim.Order do
			local r = sim.Runners[id]
			if r.Done then
				continue
			end
			if not r.Human and r.Running and sim.T >= (r.StartAt or 0) then
				-- Acelera hacia su velocidad punta y, al final, pierde un poco
				local top = topSpeed(sim, r)
				local run = sim.T - r.StartAt
				local fatigue = if run > 3.5 then (run - 3.5) * 0.03 * (1.2 - r.Skill) else 0
				local want = top * (1 - math.exp(-run / 0.75)) * (1 - math.min(fatigue, 0.25))
				r.Speed = want
				r.X += want * dt
			end
			if r.Running and r.X >= length then
				r.X = length
				if sim.Mode == "Relevo" and r.Leg < sim.Legs then
					-- Llega a la zona: le pasa el testigo al siguiente (las máquinas, solas)
					local nextRunner = nil
					for _, oid in sim.Order do
						local o = sim.Runners[oid]
						if o.Team == r.Team and o.Leg == r.Leg + 1 then
							nextRunner = o
						end
					end
					if nextRunner and not nextRunner.Human then
						RaceSim.handOver(sim, r, nextRunner, false)
					elseif nextRunner then
						r.Running = false
						nextRunner.Waiting = nextRunner.Waiting or sim.T
					else
						finishRunner(sim, r)
					end
				else
					finishRunner(sim, r)
				end
			end
		end
		-- Relevo: la persona no coge el testigo a tiempo → se cae y sale tarde
		if sim.Mode == "Relevo" then
			for _, id in sim.Order do
				local r = sim.Runners[id]
				if r.Human and r.Waiting and not r.Active and sim.T - r.Waiting > CFG.TakeTimeout then
					local incoming = RaceSim.incoming(sim, r)
					if incoming then
						RaceSim.handOver(sim, incoming, r, true)
					end
				end
			end
		end
		if allDone(sim) or sim.T - sim.GunAt > CFG.Timeout then
			RaceSim.finish(sim)
		end
	end
end

function RaceSim.finish(sim: Sim)
	if sim.Over then
		return
	end
	sim.Over = true
	sim.Phase = "Over"
	event(sim, "Over", RaceSim.outcome(sim))
end

-- El puesto de la persona (o de su equipo) y su tiempo
function RaceSim.outcome(sim: Sim): { [string]: any }
	local place, time, out = nil, nil, false
	for _, id in sim.Order do
		local r = sim.Runners[id]
		if r.Human then
			out = r.Disqualified == true
			local key = if sim.Mode == "Relevo" then r.Team else r.Id
			place = table.find(sim.Finish, key)
			time = r.Time
		end
	end
	local runners = if sim.Mode == "Relevo" then 0 else #sim.Order
	if sim.Mode == "Relevo" then
		local teams = {}
		for _, id in sim.Order do
			teams[sim.Runners[id].Team] = true
		end
		for _ in teams do
			runners += 1
		end
	end
	return { Mode = sim.Mode, Place = if out then nil else place, Of = runners, Time = time, Disqualified = out, Over = sim.Over }
end

function RaceSim.step(sim: Sim, dt: number): { { [string]: any } }
	sim.Accumulator += math.clamp(dt, 0, 0.25)
	while sim.Accumulator >= CFG.Tick do
		sim.Accumulator -= CFG.Tick
		tick(sim, CFG.Tick)
	end
	local out = sim.Events
	sim.Events = {}
	return out
end

-- La zona de relevo de una posta (desde dónde puede salir a coger el testigo), en su recorrido
function RaceSim.zone(sim: Sim): (number, number)
	return -CFG.ZoneAfter, CFG.ZoneBefore
end

return RaceSim
