-- SkateTricks (compartido): los trucos del skatepark de la Ribera del Puerto (zona 10) con el monopatín.
-- Sin Roblox: lo prueba scripts/test-ocio.luau. Lo usan Controllers/OcioClient (detecta los trucos) y
-- Services/SkateService (vuelve a contar los puntos: no se fía del número que manda el cliente).
--
--   * En el aire (al salir de una rampa o de la pista de baches): «Salto» por el tiempo en el aire
--     («Gran salto» desde 0,9 s), «Kickflip» con el botón (dos en el mismo salto: «Doble kickflip») y
--     giros con la dirección: 180°, 360° y 540°.
--   * En una barandilla: «Grind» por segundos deslizando.
--   * Combo: los trucos que encadenas sin parar (menos de COMBO_WINDOW s en el suelo entre uno y otro)
--     se suman y se multiplican por cuántos trucos lleva el combo (hasta ×6). Si caes mal (el kickflip
--     sin terminar al tocar el suelo o te das contra algo), el combo se pierde.
--   * Reto de trucos: 60 s para hacer 6000 puntos.

local SkateTricks = {}

SkateTricks.COMBO_WINDOW = 2.0
SkateTricks.MAX_MULT = 6
SkateTricks.FLIP_TIME = 0.32 -- lo que tarda la tabla en dar la vuelta: pulsar después = caída
SkateTricks.MIN_AIR = 0.3
SkateTricks.BIG_AIR = 0.9
SkateTricks.MAX_AIR = 3 -- (más que esto no se cuenta: nadie vuela tanto en el skatepark)
SkateTricks.MAX_GRIND = 8

SkateTricks.Tricks = {
	Salto = { Name = "Salto", Base = 40, PerSecond = 100 },
	GranSalto = { Name = "Gran salto", Base = 120, PerSecond = 120 },
	Kickflip = { Name = "Kickflip", Base = 150 },
	DobleKickflip = { Name = "Doble kickflip", Base = 260 },
	Giro180 = { Name = "Giro 180", Base = 120 },
	Giro360 = { Name = "Giro 360", Base = 300 },
	Giro540 = { Name = "Giro 540", Base = 520 },
	Grind = { Name = "Grind", Base = 30, PerSecond = 70 },
}

export type Trick = { Id: string, S: number? }

-- Puntos de un truco (S = segundos para Salto, GranSalto y Grind)
function SkateTricks.points(trick: Trick): number
	local def = SkateTricks.Tricks[trick.Id]
	if not def then
		return 0
	end
	local s = tonumber(trick.S) or 0
	if s ~= s then
		s = 0
	end
	if trick.Id == "Grind" then
		s = math.clamp(s, 0, SkateTricks.MAX_GRIND)
	else
		s = math.clamp(s, 0, SkateTricks.MAX_AIR)
	end
	return math.floor(def.Base + (def.PerSecond or 0) * s)
end

-- Los trucos de un salto: tiempo en el aire, kickflips pulsados y grados girados
function SkateTricks.airTricks(airtime: number, flips: number, yawDeg: number): { Trick }
	local out = {}
	if airtime < SkateTricks.MIN_AIR then
		return out
	end
	local t = math.min(airtime, SkateTricks.MAX_AIR)
	table.insert(out, { Id = if t >= SkateTricks.BIG_AIR then "GranSalto" else "Salto", S = math.floor(t * 100) / 100 })
	if flips >= 2 then
		table.insert(out, { Id = "DobleKickflip" })
	elseif flips == 1 then
		table.insert(out, { Id = "Kickflip" })
	end
	local spin = math.abs(yawDeg)
	if spin >= 500 then
		table.insert(out, { Id = "Giro540" })
	elseif spin >= 320 then
		table.insert(out, { Id = "Giro360" })
	elseif spin >= 150 then
		table.insert(out, { Id = "Giro180" })
	end
	return out
end

-- Suma, multiplicador y total de un combo
function SkateTricks.score(list: { Trick }): (number, number, number)
	local sum, count = 0, 0
	for _, trick in list do
		local p = SkateTricks.points(trick)
		if p > 0 then
			sum += p
			count += 1
		end
	end
	local mult = math.clamp(count, 1, SkateTricks.MAX_MULT)
	return sum, mult, sum * mult
end

-- Limpia lo que manda el cliente: solo trucos que existen, como mucho 40, S con su tope, y el tiempo
-- de aire y de grind que suman todos no puede pasar del que ha dado tiempo (seconds desde el combo anterior).
-- Kickflips y giros solo cuentan dentro de un salto de verdad (detrás de su «Salto»/«Gran salto», con
-- al menos MIN_AIR s de aire, que gastan tiempo): como mucho un kickflip y un giro por salto. Antes un
-- cliente trucado mandaba 40 «Giro 540» sin saltar y sacaba 124 800 puntos (y experiencia) cada 0,3 s.
local FLIPS = { Kickflip = true, DobleKickflip = true }
local SPINS = { Giro180 = true, Giro360 = true, Giro540 = true }
function SkateTricks.sanitize(raw: any, seconds: number): { Trick }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	local budget = math.max(0, seconds) + 0.5
	local jump: { Flip: boolean, Spin: boolean }? = nil -- (el salto en el que van los kickflips y giros)
	for i, t in ipairs(raw) do
		if i > 40 then
			break
		end
		if type(t) ~= "table" or type(t.Id) ~= "string" or not SkateTricks.Tricks[t.Id] then
			continue
		end
		local id = t.Id
		if FLIPS[id] or SPINS[id] then
			local slot = if FLIPS[id] then "Flip" else "Spin"
			if not jump or (jump :: any)[slot] then
				continue
			end
			(jump :: any)[slot] = true
			table.insert(out, { Id = id })
			continue
		end
		local s = tonumber(t.S)
		if not s or s ~= s then
			s = 0
		end
		s = math.clamp(s, 0, if id == "Grind" then SkateTricks.MAX_GRIND else SkateTricks.MAX_AIR)
		if s > budget then
			s = budget
		end
		jump = nil
		if id ~= "Grind" then
			if s < SkateTricks.MIN_AIR then
				continue -- (un salto sin tiempo de aire no es un salto)
			end
			if id == "GranSalto" and s < SkateTricks.BIG_AIR then
				id = "Salto"
			end
			jump = { Flip = false, Spin = false }
		elseif s <= 0 then
			continue
		end
		budget -= s
		table.insert(out, { Id = id, S = s })
	end
	return out
end

---------------------------------------------------------------------
-- Combo (lo lleva el cliente mientras patinas)
---------------------------------------------------------------------
export type Combo = { Tricks: { Trick }, LastAt: number?, Grounded: boolean }

function SkateTricks.newCombo(): Combo
	return { Tricks = {}, LastAt = nil, Grounded = true }
end

function SkateTricks.add(combo: Combo, tricks: { Trick }, now: number)
	for _, t in tricks do
		table.insert(combo.Tricks, t)
	end
	if #tricks > 0 then
		combo.LastAt = now
	end
end

-- ¿Se ha acabado el combo? (demasiado tiempo en el suelo desde el último truco) Devuelve los trucos
-- para cobrar y deja el combo vacío; nil si sigue abierto.
function SkateTricks.expire(combo: Combo, now: number): { Trick }?
	if #combo.Tricks == 0 or not combo.LastAt then
		return nil
	end
	if now - combo.LastAt >= SkateTricks.COMBO_WINDOW then
		local done = combo.Tricks
		combo.Tricks = {}
		combo.LastAt = nil
		return done
	end
	return nil
end

-- Caída: se pierde lo que llevabas
function SkateTricks.bail(combo: Combo): number
	local lost = #combo.Tricks
	combo.Tricks = {}
	combo.LastAt = nil
	return lost
end

-- ¿Caída al aterrizar? (el último kickflip pulsado hace menos de FLIP_TIME s)
function SkateTricks.badLanding(lastFlipAt: number?, landedAt: number): boolean
	return lastFlipAt ~= nil and landedAt - lastFlipAt < SkateTricks.FLIP_TIME
end

---------------------------------------------------------------------
-- Reto de trucos
---------------------------------------------------------------------
SkateTricks.Challenge = { Seconds = 60, Goal = 6000, Prize = 40, Fun = 15, Xp = 20 }
SkateTricks.FunPerCombo = 2 -- diversión por combo cobrado (con tope por minuto en el servidor)
SkateTricks.FunPerMinute = 12
SkateTricks.XpPerMinute = 8 -- experiencia por combos en un minuto (el servidor no da más)

return SkateTricks
