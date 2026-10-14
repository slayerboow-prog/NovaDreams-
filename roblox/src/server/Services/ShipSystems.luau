-- ShipSystems (servidor): la ENERGÍA y las HABILIDADES de la nave (Espacio AAA, fases 4 a 6;
-- docs/espacio-aaa/diseno.md). Es un ayudante de Services/AirCombatService (trabaja con sus sesiones):
-- todo lo que gasta, recarga, aprueba o mueve la nave se decide AQUÍ, nunca en el cliente.
--
--   * Energía (shared/AirCombat/ShipAbilities): se recarga sola; la gastan la esquiva, la hipervelocidad
--     y el salto cuántico. Va al cliente en «State» (Energy, Cool…).
--   * Esquiva ("Dodge", "L"|"R"|"U"|"D"): recarga, energía, estado → invulnerable IFrames segundos y un
--     margen de movimiento corto (la nave se aparta de verdad: los disparos que iban a su sitio fallan).
--   * Hipervelocidad ("Hyper" / "HyperStop"; shared/AirCombat/Hyperspeed): Prepare → Activate → Travel →
--     Decel. Comprueba combate, estaciones, tráfico, atmósfera y obstáculos (barrido por delante); gasta
--     al activarse y por segundo de viaje; mientras dura, el movimiento admite su velocidad.
--   * Salto cuántico ("QuantumList", "Quantum" id, "QuantumCancel"; shared/Cosmos/QuantumJump): valida,
--     carga (Charge s), busca un sitio seguro y mueve la nave (relocate). Solo entonces gasta. Si algo
--     falla (te dan, cancelas, deja de ser seguro), explica el motivo y no gasta nada. Uno a la vez.
--   * Armas: "Weapon" ("Cannons" | "Laser") y "Reload" (enfría los cañones y repone un misil).
-- Cada petición tiene un mínimo de tiempo entre dos (RequestGap) y todos los datos se comprueban.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AC = ReplicatedStorage.Shared.AirCombat
local ShipAbilities = require(AC.ShipAbilities)
local Hyperspeed = require(AC.Hyperspeed)
local ShipWeapons = require(AC.ShipWeapons)
local ShipFlight = require(AC.ShipFlight)
local Cosmos = ReplicatedStorage.Shared.Cosmos
local QuantumJump = require(Cosmos.QuantumJump)
local PlanetBodies = require(Cosmos.PlanetBodies)
local Stations = require(Cosmos.Stations)

local ShipSystems = {}

ShipSystems.RequestGap = 0.12
ShipSystems.DodgeAllowance = 320 -- studs/s de más mientras dura la esquiva
ShipSystems.Grace = 1.5 -- s de margen tras acabar la hipervelocidad (red)

-- ctx (lo pone AirCombatService): { send(kind, payload), toast(kind, text), geo, others() -> { Vector3 },
--   enemies() -> { Vector3 }, relocate(cf) -> bool, nav() -> { Found, Missions, PlanetStatus }?, now() }
export type Ctx = { [string]: any }

function ShipSystems.attach(s: any)
	s.Abil = ShipAbilities.new()
	s.Weapon = "Cannons"
	s.HurtAt = -math.huge
	s.IFramesUntil = 0
	s.AllowSpeed = 0
	s.AllowUntil = 0
	s.Hyper = nil
	s.Quantum = nil
	s.ReqAt = -math.huge
end

local function pos(s: any): Vector3
	return s.Root.Position
end

local function inCombat(s: any, ctx: Ctx, t: number): boolean
	if t - (s.HurtAt or -math.huge) < Hyperspeed.HurtSeconds then
		return true
	end
	local p = pos(s)
	for _, e in ctx.enemies() do
		if (e - p).Magnitude < Hyperspeed.EnemyRadius then
			return true
		end
	end
	return false
end
ShipSystems.inCombat = inCombat

local function inAtmosphere(p: Vector3): boolean
	for _, b in PlanetBodies.List do
		if (p - b.Center).Magnitude < PlanetBodies.entryRadius(b) + Hyperspeed.AtmosMargin then
			return true
		end
	end
	return false
end

local function obstacleAhead(s: any, ctx: Ctx): string?
	local g = ctx.geo
	local cf = s.Root.CFrame
	local hit = Hyperspeed.sweep(cf.Position, cf.LookVector, Hyperspeed.stopDistance(), 30, function(p, r)
		local h = g.collide(p, r)
		if h then
			return h
		end
		if Stations.safeAt(p) then
			return "una estación"
		end
		if inAtmosphere(p) then
			return "la atmósfera de un planeta"
		end
		return nil
	end, function(p)
		return g.contains(p, 0)
	end, 60)
	return hit
end

function ShipSystems.hyperContext(s: any, ctx: Ctx, t: number): Hyperspeed.Context
	local p = pos(s)
	local traffic = false
	for _, o in ctx.others() do
		if (o - p).Magnitude < Hyperspeed.TrafficRadius then
			traffic = true
		end
	end
	local near = false
	for _, st in Stations.List do
		if (p - st.Center).Magnitude < Hyperspeed.StationRadius then
			near = true
		end
	end
	return {
		World = s.World,
		Mode = ctx.geo.modeAt(p),
		Down = s.Down,
		Busy = s.Quantum ~= nil,
		Energy = s.Abil.Energy,
		MinEnergy = ShipAbilities.Hyper.MinEnergy,
		Cooldown = ShipAbilities.cooldownLeft(s.Abil, "Hyper", t),
		InCombat = inCombat(s, ctx, t),
		NearStation = near,
		Traffic = traffic,
		InAtmosphere = inAtmosphere(p),
		Obstacle = obstacleAhead(s, ctx),
	}
end

-- Margen de movimiento aprobado ahora (para ShipFlight.plausible): velocidad de más
function ShipSystems.allowance(s: any, t: number): number
	local extra = 0
	if s.AllowUntil and t < s.AllowUntil then
		extra = math.max(extra, s.AllowSpeed or 0)
	end
	if s.Hyper then
		extra = math.max(extra, Hyperspeed.allowance(s.Hyper.Phase))
	elseif s.HyperGraceUntil and t < s.HyperGraceUntil then
		extra = math.max(extra, Hyperspeed.Speed * 1.1)
	end
	return extra
end

function ShipSystems.invulnerable(s: any, t: number): boolean
	return t < (s.IFramesUntil or 0)
end

---------------------------------------------------------------------
-- Hipervelocidad
---------------------------------------------------------------------
local function hyperSet(s: any, ctx: Ctx, phase: string?, t: number, reason: string?)
	if phase == nil or phase == "Off" then
		local was = s.Hyper
		s.Hyper = nil
		if was and (was.Phase == "Activate" or was.Phase == "Travel" or was.Phase == "Decel") then
			ShipAbilities.startCooldown(s.Abil, "Hyper", t, ShipAbilities.Hyper.Cooldown)
			s.HyperGraceUntil = t + ShipSystems.Grace
		end
		ctx.send("Hyper", { Phase = "Off", Reason = reason })
		return
	end
	s.Hyper = { Phase = phase, Since = t }
	ctx.send("Hyper", { Phase = phase, Reason = reason })
end

function ShipSystems.hyperStart(s: any, ctx: Ctx, t: number): (boolean, string?)
	if s.Hyper then
		return false, "Ocupada"
	end
	local ok, why = Hyperspeed.check(ShipSystems.hyperContext(s, ctx, t))
	if not ok then
		ctx.send("Hyper", { Phase = "Denied", Reason = why })
		return false, why
	end
	hyperSet(s, ctx, "Prepare", t)
	return true, nil
end

function ShipSystems.hyperStop(s: any, ctx: Ctx, t: number, reason: string?)
	local h = s.Hyper
	if not h then
		return
	end
	if h.Phase == "Prepare" then
		hyperSet(s, ctx, nil, t, reason or "Cancelado") -- (no se había gastado nada)
	elseif h.Phase == "Activate" or h.Phase == "Travel" then
		hyperSet(s, ctx, "Decel", t, reason)
	end
end

local function hyperTick(s: any, ctx: Ctx, t: number, dt: number)
	local h = s.Hyper
	if not h then
		return
	end
	if s.Down then
		s.Hyper = nil
		return
	end
	if h.Phase == "Travel" then
		ShipAbilities.spend(s.Abil, ShipAbilities.Hyper.Drain * dt, t)
		if s.Abil.Energy <= 0 then
			hyperSet(s, ctx, "Decel", t, "Energia")
			return
		end
		if t - (s.HurtAt or -math.huge) < 0.5 then
			hyperSet(s, ctx, "Decel", t, "Combate")
			return
		end
	end
	local nextPhase = Hyperspeed.advance(h, t)
	if nextPhase == "Activate" then
		-- (otra vez todo, y ahora sí se gasta)
		local c = ShipSystems.hyperContext(s, ctx, t)
		c.Busy = false
		local ok, why = Hyperspeed.check(c)
		if not ok or not ShipAbilities.spend(s.Abil, ShipAbilities.Hyper.Cost, t) then
			hyperSet(s, ctx, nil, t, why or "Energia")
			return
		end
		hyperSet(s, ctx, "Activate", t)
	elseif nextPhase == "Travel" then
		hyperSet(s, ctx, "Travel", t)
	elseif nextPhase == "Off" then
		hyperSet(s, ctx, nil, t)
	end
end

---------------------------------------------------------------------
-- Salto cuántico
---------------------------------------------------------------------
local function quantumDests(s: any, ctx: Ctx): { QuantumJump.Dest }
	local nav = ctx.nav and ctx.nav() or nil
	return QuantumJump.list(nav)
end

local function quantumState(s: any, ctx: Ctx, t: number): { [string]: any }
	return {
		World = s.World,
		Down = s.Down,
		Busy = s.Quantum ~= nil or s.Hyper ~= nil,
		InCombat = inCombat(s, ctx, t),
		Energy = s.Abil.Energy,
		Cooldown = ShipAbilities.cooldownLeft(s.Abil, "Quantum", t),
		Pos = pos(s),
	}
end

function ShipSystems.quantumList(s: any, ctx: Ctx, t: number): { { [string]: any } }
	local st = quantumState(s, ctx, t)
	local out = {}
	for _, d in quantumDests(s, ctx) do
		local ok, why, cost, dist = QuantumJump.validate(st, d)
		table.insert(out, { Id = d.Id, Name = d.Name, Kind = d.Kind, Ok = ok, Reason = if d.Locked then d.Locked else why, Cost = cost, Dist = dist, Note = d.Note, Pos = d.Pos })
	end
	return out
end

local function quantumFail(s: any, ctx: Ctx, reason: string)
	s.Quantum = nil
	ctx.send("Quantum", { Phase = "Fail", Reason = reason })
end

function ShipSystems.quantumStart(s: any, ctx: Ctx, t: number, id: any): (boolean, string?)
	if type(id) ~= "string" or #id > 40 then
		return false, "Desconocido"
	end
	if s.Quantum then
		ctx.send("Quantum", { Phase = "Fail", Reason = "Ocupada" })
		return false, "Ocupada"
	end
	local dest = QuantumJump.find(quantumDests(s, ctx), id)
	local ok, why, cost, dist = QuantumJump.validate(quantumState(s, ctx, t), dest)
	if not ok or not dest then
		ctx.send("Quantum", { Phase = "Fail", Reason = why })
		return false, why
	end
	local g = ctx.geo
	local arrival = QuantumJump.safeArrival(dest, g.collide, function(p)
		return g.contains(p, 0)
	end)
	if not arrival then
		ctx.send("Quantum", { Phase = "Fail", Reason = "Inseguro" })
		return false, "Inseguro"
	end
	s.Quantum = { Id = id, Name = dest.Name, Arrival = arrival, Start = t, At = t + ShipAbilities.Quantum.Charge, Cost = cost, Dist = dist }
	ctx.send("Quantum", { Phase = "Charge", Id = id, Name = dest.Name, Seconds = ShipAbilities.Quantum.Charge, Cost = cost, Dist = dist })
	return true, nil
end

function ShipSystems.quantumCancel(s: any, ctx: Ctx)
	if s.Quantum then
		quantumFail(s, ctx, "Cancelado")
	end
end

local function quantumTick(s: any, ctx: Ctx, t: number)
	local q = s.Quantum
	if not q then
		return
	end
	if s.Down then
		quantumFail(s, ctx, "Derribado")
		return
	end
	if (s.HurtAt or -math.huge) > q.Start then
		quantumFail(s, ctx, "Danado")
		return
	end
	if t < q.At then
		return
	end
	-- Comprobar otra vez justo antes de saltar (nada se ha gastado aún)
	local st = quantumState(s, ctx, t)
	st.Busy = s.Hyper ~= nil
	local dest = QuantumJump.find(quantumDests(s, ctx), q.Id)
	local ok, why, cost = QuantumJump.validate(st, dest)
	if not ok or not dest then
		quantumFail(s, ctx, why or "Desconocido")
		return
	end
	local g = ctx.geo
	local arrival = QuantumJump.safeArrival(dest, g.collide, function(p)
		return g.contains(p, 0)
	end)
	if not arrival then
		quantumFail(s, ctx, "Inseguro")
		return
	end
	if not ShipAbilities.spend(s.Abil, cost, t) then
		quantumFail(s, ctx, "Energia")
		return
	end
	s.Quantum = nil
	if not ctx.relocate(arrival) then
		-- (no se pudo mover: devolver la energía, nada perdido)
		s.Abil.Energy = math.min(ShipAbilities.Energy.Max, s.Abil.Energy + cost)
		ctx.send("Quantum", { Phase = "Fail", Reason = "Inseguro" })
		return
	end
	ShipAbilities.startCooldown(s.Abil, "Quantum", t, ShipAbilities.Quantum.Cooldown)
	ctx.send("Quantum", { Phase = "Done", Id = dest.Id, Name = dest.Name, Cost = cost })
end

---------------------------------------------------------------------
-- Esquiva, armas
---------------------------------------------------------------------
local DIRS = { L = true, R = true, U = true, D = true }

function ShipSystems.dodge(s: any, ctx: Ctx, t: number, dir: any): (boolean, string?)
	local D = ShipAbilities.Dodge
	local why: string? = nil
	if s.Down then
		why = "Derribado"
	elseif type(dir) ~= "string" or not DIRS[dir] then
		why = "Desconocido"
	elseif s.Hyper and s.Hyper.Phase ~= "Prepare" then
		why = "Ocupada"
	else
		local ok, r = ShipAbilities.canUse(s.Abil, "Dodge", t, D.Cost)
		if not ok then
			why = r
		end
	end
	if why then
		ctx.send("Ability", { Id = "Dodge", Ok = false, Reason = why })
		return false, why
	end
	ShipAbilities.spend(s.Abil, D.Cost, t)
	ShipAbilities.startCooldown(s.Abil, "Dodge", t, D.Cooldown)
	s.IFramesUntil = t + D.IFrames
	s.AllowSpeed = ShipSystems.DodgeAllowance
	s.AllowUntil = t + D.Duration + 0.6
	ctx.send("Ability", { Id = "Dodge", Ok = true, Dir = dir })
	return true, nil
end

function ShipSystems.weapon(s: any, ctx: Ctx, which: any)
	if which == "Cannons" or which == "Laser" then
		s.Weapon = which
		ctx.send("Ability", { Id = "Weapon", Ok = true, Weapon = which })
	end
end

function ShipSystems.reload(s: any, ctx: Ctx, t: number): boolean
	local ok, why = ShipAbilities.canUse(s.Abil, "Reload", t, 0)
	local g = s.Gun
	if ok and g.Heat <= 0.01 and g.Missiles >= ShipWeapons.Missile.Ammo then
		ok, why = false, "Lleno"
	end
	if not ok or s.Down then
		ctx.send("Ability", { Id = "Reload", Ok = false, Reason = why or "Derribado" })
		return false
	end
	g.Heat = 0
	g.Overheated = false
	if g.Missiles < ShipWeapons.Missile.Ammo then
		g.Missiles += 1
		g.ReloadAt = if g.Missiles < ShipWeapons.Missile.Ammo then t + ShipWeapons.Missile.Reload else 0
	end
	ShipAbilities.startCooldown(s.Abil, "Reload", t, ShipAbilities.Reload.Cooldown)
	ctx.send("Ability", { Id = "Reload", Ok = true })
	return true
end

-- Te han dado (el combate dura un rato; un salto cargando se cancela)
function ShipSystems.hurt(s: any, t: number)
	s.HurtAt = t
end

---------------------------------------------------------------------
-- Peticiones del cliente y cada vuelta
---------------------------------------------------------------------
function ShipSystems.request(s: any, ctx: Ctx, action: string, arg: any): boolean
	local t = ctx.now()
	if t - (s.ReqAt or -math.huge) < ShipSystems.RequestGap and action ~= "HyperStop" and action ~= "QuantumCancel" then
		return false
	end
	s.ReqAt = t
	if action == "Dodge" then
		return (ShipSystems.dodge(s, ctx, t, arg))
	elseif action == "Hyper" then
		return (ShipSystems.hyperStart(s, ctx, t))
	elseif action == "HyperStop" then
		ShipSystems.hyperStop(s, ctx, t, if type(arg) == "string" and #arg < 20 then arg else nil)
		return true
	elseif action == "QuantumList" then
		local list = ShipSystems.quantumList(s, ctx, t)
		ctx.send("Quantum", { Phase = "List", List = list })
		return true
	elseif action == "Quantum" then
		return (ShipSystems.quantumStart(s, ctx, t, arg))
	elseif action == "QuantumCancel" then
		ShipSystems.quantumCancel(s, ctx)
		return true
	elseif action == "Weapon" then
		ShipSystems.weapon(s, ctx, arg)
		return true
	elseif action == "Reload" then
		return ShipSystems.reload(s, ctx, t)
	end
	return false
end

function ShipSystems.tick(s: any, ctx: Ctx, t: number, dt: number)
	ShipAbilities.tick(s.Abil, t, dt)
	hyperTick(s, ctx, t, dt)
	quantumTick(s, ctx, t)
end

-- Lo que va en «State» al cliente
function ShipSystems.state(s: any, ctx: Ctx, t: number): { [string]: any }
	local a = s.Abil
	local hyperBlock, quantumBlock = nil, nil
	if not s.Hyper then
		local _, why = Hyperspeed.check(ShipSystems.hyperContextLight(s, ctx, t))
		hyperBlock = why
	end
	local combat = inCombat(s, ctx, t)
	if s.World ~= "Cosmos" then
		quantumBlock = if s.World == "Planet" then "Atmosfera" else "Mundo"
	elseif combat then
		quantumBlock = "Combate"
	end
	return {
		Energy = a.Energy,
		MaxEnergy = ShipAbilities.Energy.Max,
		Cool = {
			Dodge = ShipAbilities.cooldownLeft(a, "Dodge", t),
			Hyper = ShipAbilities.cooldownLeft(a, "Hyper", t),
			Quantum = ShipAbilities.cooldownLeft(a, "Quantum", t),
			Reload = ShipAbilities.cooldownLeft(a, "Reload", t),
		},
		Weapon = s.Weapon,
		HyperPhase = if s.Hyper then s.Hyper.Phase else nil,
		Charging = if s.Quantum then s.Quantum.Name else nil,
		InCombat = combat,
		HyperBlock = hyperBlock,
		QuantumBlock = quantumBlock,
		MissileReload = if s.Gun.ReloadAt > 0 then math.clamp(1 - (s.Gun.ReloadAt - t) / ShipWeapons.Missile.Reload, 0, 1) else 1,
	}
end

-- (sin el barrido por delante: lo que se puede mirar 10 veces por segundo)
function ShipSystems.hyperContextLight(s: any, ctx: Ctx, t: number): Hyperspeed.Context
	local p = pos(s)
	local near = false
	for _, st in Stations.List do
		if (p - st.Center).Magnitude < Hyperspeed.StationRadius then
			near = true
		end
	end
	return {
		World = s.World,
		Mode = ctx.geo.modeAt(p),
		Down = s.Down,
		Busy = s.Quantum ~= nil,
		Energy = s.Abil.Energy,
		MinEnergy = ShipAbilities.Hyper.MinEnergy,
		Cooldown = ShipAbilities.cooldownLeft(s.Abil, "Hyper", t),
		InCombat = inCombat(s, ctx, t),
		NearStation = near,
		Traffic = false,
		InAtmosphere = inAtmosphere(p),
		Obstacle = nil,
	}
end

-- (para las pruebas)
ShipSystems._flightSpec = ShipFlight.Specs.Caza

return ShipSystems
