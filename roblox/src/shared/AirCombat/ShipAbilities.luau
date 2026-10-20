-- ShipAbilities: la ENERGÍA de la nave, las recargas de las habilidades y las 8 ranuras del HUD
-- (Espacio AAA, docs/espacio-aaa/diseno.md). Cuentas puras: las usa el servidor (manda: gasta, recarga,
-- aprueba; Services/ShipSystems) y el cliente (predice y pinta la barra: UI/AirCombatHud).
--
--   * Energía: 100; se recarga sola (Regen/s) tras Delay segundos sin gastar. La gastan la esquiva, la
--     hipervelocidad (al empezar y por segundo de viaje) y el salto cuántico. El impulso NO: tiene su
--     medidor de calor (ShipFlight.Boost).
--   * Recargas (Cool): segundos hasta poder volver a usar cada habilidad.
--   * Ranuras: 1 cañones · 2 misiles · 3 láser · 4 escudo especial (sobrecarga) · 5 camuflaje ·
--     6 salto cuántico · 7 hipervelocidad · 8 dron (bloqueado hasta desbloquear uno en una estación).
--     Una ranura solo sale bloqueada si de verdad no se puede usar (nunca un botón que no hace nada).

local ShipAbilities = {}

ShipAbilities.Energy = { Max = 100, Regen = 7, Delay = 1.5 }

ShipAbilities.Dodge = { Cost = 18, Cooldown = 1.6, Distance = 38, Duration = 0.28, IFrames = 0.18 }
ShipAbilities.Hyper = { Cost = 15, Drain = 7, MinEnergy = 30, Cooldown = 6 }
ShipAbilities.Quantum = { Base = 25, PerKm = 0.6, MaxCost = 70, Cooldown = 12, Charge = 3 }
ShipAbilities.Reload = { Cooldown = 10 }

-- Motivos (para el aviso: nada se gasta si no se puede)
ShipAbilities.Reasons = {
	Energia = "Sin energía suficiente",
	Recarga = "Aún recargando",
	Derribado = "La nave está derribada",
	Bloqueada = "Próximamente",
	Ocupada = "Ya hay otra maniobra en marcha",
	Combate = "En combate",
	Estacion = "Demasiado cerca de una estación",
	Trafico = "Hay otra nave muy cerca",
	Atmosfera = "Dentro de una atmósfera",
	Obstaculo = "Obstáculo delante",
	Mundo = "Solo en el espacio de Valmar",
	Alcance = "Fuera de alcance",
	Cerca = "Demasiado cerca: ve volando",
	Inseguro = "No hay sitio seguro para salir",
	Desconocido = "Destino desconocido",
	Cancelado = "Cancelado",
	Danado = "Te han dado durante la carga",
	Lleno = "Ya está todo listo",
	SinCargas = "Sin bengalas: se reponen solas",
	SinDron = "No tienes ese dron: desbloquéalo en la tienda de una estación",
	Exploracion = "En modo exploración no hay misiles",
	Tapado = "Algo tapa al objetivo",
	Lejos = "Objetivo demasiado lejos",
	Angulo = "Objetivo fuera del cono",
	Camuflado = "Con el camuflaje no se dispara (se rompe)",
	-- (acrobacias: LOOPING y TONEL, ShipFlight.maneuver)
	Lento = "Demasiado lento para la acrobacia: acelera",
	Bajo = "Demasiado bajo para el looping: sube",
}

export type State = { Energy: number, Max: number, SpentAt: number, Cool: { [string]: number } }

-- max: energía máxima (con las baterías mejoradas; Espacio AAA fase 9)
function ShipAbilities.new(max: number?): State
	local m = max or ShipAbilities.Energy.Max
	return { Energy = m, Max = m, SpentAt = -math.huge, Cool = {} }
end

-- Recarga la energía (cada vuelta del servidor o fotograma del cliente)
function ShipAbilities.tick(st: State, now: number, dt: number)
	local E = ShipAbilities.Energy
	local max = st.Max or E.Max
	if now - st.SpentAt >= E.Delay and st.Energy < max then
		st.Energy = math.min(max, st.Energy + E.Regen * dt)
	end
end

function ShipAbilities.cooldownLeft(st: State, id: string, now: number): number
	return math.max(0, (st.Cool[id] or 0) - now)
end

-- ¿Se puede gastar `cost` y está lista `id`? (sin gastar nada) -> ok, motivo
function ShipAbilities.canUse(st: State, id: string, now: number, cost: number?): (boolean, string?)
	if ShipAbilities.cooldownLeft(st, id, now) > 0 then
		return false, "Recarga"
	end
	if (cost or 0) > st.Energy + 1e-6 then
		return false, "Energia"
	end
	return true, nil
end

function ShipAbilities.spend(st: State, cost: number, now: number): boolean
	if cost > st.Energy + 1e-6 then
		return false
	end
	st.Energy = math.max(0, st.Energy - cost)
	if cost > 0 then
		st.SpentAt = now
	end
	return true
end

function ShipAbilities.startCooldown(st: State, id: string, now: number, seconds: number)
	st.Cool[id] = now + seconds
end

-- Coste del salto cuántico para una distancia (studs)
function ShipAbilities.quantumCost(distance: number): number
	local Q = ShipAbilities.Quantum
	return math.floor(math.min(Q.MaxCost, Q.Base + distance / 1000 * Q.PerKm * 10) + 0.5)
end

---------------------------------------------------------------------
-- Las 8 ranuras del HUD
---------------------------------------------------------------------
export type SlotDef = { Id: string, Name: string, Action: string, Glyph: string, Kind: string, Locked: boolean?, Soon: string? }
ShipAbilities.Overload = { Cost = 30, Cooldown = 20 }
ShipAbilities.CloakCost = 20

ShipAbilities.Slots = {
	{ Id = "Cannons", Name = "Cañones", Action = "Cannons", Glyph = "Canon", Kind = "Weapon" },
	{ Id = "Missiles", Name = "Misiles", Action = "Missile", Glyph = "Misil", Kind = "Ammo" },
	{ Id = "Laser", Name = "Láser", Action = "Laser", Glyph = "Laser", Kind = "Weapon" },
	{ Id = "Shield", Name = "Sobrecarga", Action = "Shield", Glyph = "Escudo", Kind = "Ability" },
	{ Id = "Cloak", Name = "Camuflaje", Action = "Cloak", Glyph = "Camuflaje", Kind = "Ability" },
	{ Id = "Quantum", Name = "Salto cuántico", Action = "Quantum", Glyph = "Salto", Kind = "Ability" },
	{ Id = "Hyper", Name = "Hipervelocidad", Action = "Hyper", Glyph = "Hiper", Kind = "Ability" },
	{ Id = "Drone", Name = "Dron", Action = "Drone", Glyph = "Dron", Kind = "Ability" },
} :: { SlotDef }

ShipAbilities.SlotById = {} :: { [string]: SlotDef }
for i, def in ShipAbilities.Slots do
	ShipAbilities.SlotById[def.Id] = def
	;(def :: any).Index = i
end

export type SlotView = {
	Id: string,
	Name: string,
	Key: string, -- "1".."8"
	Count: string, -- "6", "∞", ""
	Cool: number, -- 0..1 lo que falta de recarga (0 = lista)
	State: string, -- "Ready" | "Active" | "Cooling" | "NoEnergy" | "Locked" | "Blocked"
	Selected: boolean,
	Note: string?, -- motivo o texto corto
}

-- Lo que enseña cada ranura. info (del servidor y la simulación local):
--   { Energy, Weapon ("Cannons"|"Laser"), Missiles, MaxMissiles, MissileReload (0..1), Heat (0..1),
--     Overheated, Cool = { [id] = segundos }, Hyper = fase o nil, Quantum = "Charging" o nil,
--     HyperBlock = motivo?, QuantumBlock = motivo? }
function ShipAbilities.slotViews(info: { [string]: any }): { SlotView }
	local out = {}
	local cool = info.Cool or {}
	local energy = info.Energy or ShipAbilities.Energy.Max
	for i, def in ShipAbilities.Slots do
		local v: SlotView = { Id = def.Id, Name = def.Name, Key = tostring(i), Count = "", Cool = 0, State = "Ready", Selected = false, Note = nil }
		if def.Locked then
			v.State = "Locked"
			v.Note = def.Soon or "Próximamente"
		elseif def.Id == "Cannons" or def.Id == "Laser" then
			v.Count = "∞"
			v.Selected = (info.Weapon or "Cannons") == def.Id
			if v.Selected and info.Overheated then
				v.State = "Cooling"
				v.Cool = math.clamp(info.Heat or 1, 0, 1)
				v.Note = "Recalentado"
			elseif v.Selected then
				v.State = "Active"
			end
		elseif def.Id == "Missiles" then
			local n = info.Missiles or 0
			v.Count = tostring(n)
			if n <= 0 then
				v.State = "Cooling"
				v.Cool = 1 - math.clamp(info.MissileReload or 0, 0, 1)
				v.Note = "Recargando"
			end
		elseif def.Id == "Hyper" then
			local left = cool.Hyper or 0
			if info.Hyper then
				v.State = "Active"
				v.Note = info.Hyper
			elseif left > 0 then
				v.State = "Cooling"
				v.Cool = math.clamp(left / ShipAbilities.Hyper.Cooldown, 0, 1)
			elseif energy < ShipAbilities.Hyper.MinEnergy then
				v.State = "NoEnergy"
				v.Note = ShipAbilities.Reasons.Energia
			elseif info.HyperBlock then
				v.State = "Blocked"
				v.Note = ShipAbilities.Reasons[info.HyperBlock] or info.HyperBlock
			end
		elseif def.Id == "Shield" then
			local left = cool.Overload or 0
			if info.OverloadOn then
				v.State = "Active"
				v.Note = "Sobrecarga"
			elseif left > 0 then
				v.State = "Cooling"
				v.Cool = math.clamp(left / ShipAbilities.Overload.Cooldown, 0, 1)
				v.Note = if info.Overheat then "Recalentado" else nil
			elseif energy < ShipAbilities.Overload.Cost then
				v.State = "NoEnergy"
				v.Note = ShipAbilities.Reasons.Energia
			end
		elseif def.Id == "Cloak" then
			local left = cool.Cloak or 0
			if info.CloakOn then
				v.State = "Active"
				v.Note = "Activo"
			elseif left > 0 then
				v.State = "Cooling"
				v.Cool = math.clamp(left / 15, 0, 1)
			elseif energy < ShipAbilities.CloakCost then
				v.State = "NoEnergy"
				v.Note = ShipAbilities.Reasons.Energia
			end
		elseif def.Id == "Drone" then
			local left = cool.Drone or 0
			if not info.DroneKind then
				v.State = "Locked"
				v.Note = "Desbloquear en estación"
			elseif info.DroneOn then
				v.State = "Active"
				v.Note = info.DroneNote or "Activo"
				v.Count = info.DroneLeft or ""
			elseif left > 0 then
				v.State = "Cooling"
				v.Cool = math.clamp(left / 30, 0, 1)
			end
		elseif def.Id == "Quantum" then
			local left = cool.Quantum or 0
			if info.Quantum then
				v.State = "Active"
				v.Note = "Cargando"
			elseif left > 0 then
				v.State = "Cooling"
				v.Cool = math.clamp(left / ShipAbilities.Quantum.Cooldown, 0, 1)
			elseif energy < ShipAbilities.Quantum.Base then
				v.State = "NoEnergy"
				v.Note = ShipAbilities.Reasons.Energia
			elseif info.QuantumBlock then
				v.State = "Blocked"
				v.Note = ShipAbilities.Reasons[info.QuantumBlock] or info.QuantumBlock
			end
		end
		table.insert(out, v)
	end
	return out
end

return ShipAbilities
