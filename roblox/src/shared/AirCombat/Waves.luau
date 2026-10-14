-- Waves: oleadas de enemigos del combate aéreo (cuentas puras: AirCombatService las usa y
-- scripts/test-aircombat.luau las prueba).
--
--   Waves.compose(n, sección)   qué sale en la oleada n: { { Kind = "Dron", Count = 3 }, … }
--   Waves.scale(n, dificultad)  cuánto más duros son (casco, daño, cadencia, velocidad)
--   Waves.new(opciones) / Waves.step(spawner, dt, vivos)  la máquina de oleadas:
--     "Intermission" (cuenta atrás) → evento Spawn → "Fighting" → cuando no queda ninguno, evento
--     Cleared → otra cuenta atrás… Con MaxWaves, al limpiar la última, evento Done.
-- Dificultad: "Facil" | "Normal" | "Dificil" (el modo pruebas y, en la Saga 2, la misión).

local Waves = {}

Waves.Difficulty = {
	Facil = { Count = 0.75, Hull = 0.8, Damage = 0.6, Fire = 0.75, Speed = 0.9 },
	Normal = { Count = 1, Hull = 1, Damage = 1, Fire = 1, Speed = 1 },
	Dificil = { Count = 1.3, Hull = 1.3, Damage = 1.3, Fire = 1.25, Speed = 1.1 },
}
Waves.MaxAlive = 12 -- nunca más enemigos a la vez (móvil)

export type Group = { Kind: string, Count: number }
export type Scale = { Hull: number, Damage: number, Fire: number, Speed: number }

-- Las tres primeras de cada sección están hechas a mano (se aprende); luego crecen solas
local FIRST = {
	Atmos = {
		{ { Kind = "Dron", Count = 3 } },
		{ { Kind = "Dron", Count = 4 }, { Kind = "Torreta", Count = 1 } },
		{ { Kind = "Dron", Count = 4 }, { Kind = "Caza", Count = 1 }, { Kind = "Torreta", Count = 2 } },
	},
	Space = {
		{ { Kind = "Dron", Count = 4 } },
		{ { Kind = "Dron", Count = 3 }, { Kind = "Caza", Count = 1 } },
		{ { Kind = "Dron", Count = 4 }, { Kind = "Caza", Count = 2 }, { Kind = "Torreta", Count = 1 } },
	},
}

local function total(groups: { Group }): number
	local n = 0
	for _, g in groups do
		n += g.Count
	end
	return n
end

function Waves.compose(n: number, section: string?, difficulty: string?): { Group }
	local sec = if section == "Space" then "Space" else "Atmos"
	local d = Waves.Difficulty[difficulty or "Normal"] or Waves.Difficulty.Normal
	local base: { Group }
	if n <= #FIRST[sec] then
		base = FIRST[sec][math.max(1, n)]
	else
		local k = n - #FIRST[sec]
		base = {
			{ Kind = "Dron", Count = 4 + k },
			{ Kind = "Caza", Count = 1 + math.floor((k + 1) / 2) },
			{ Kind = "Torreta", Count = if sec == "Atmos" then 2 else 1 },
		}
	end
	-- Dificultad (nunca menos de 1 de cada) y tope de enemigos a la vez
	local out: { Group } = {}
	for _, g in base do
		table.insert(out, { Kind = g.Kind, Count = math.max(1, math.floor(g.Count * d.Count + 0.5)) })
	end
	while total(out) > Waves.MaxAlive do
		-- se quitan drones primero (son los que más hay)
		local trimmed = false
		for _, g in out do
			if g.Kind == "Dron" and g.Count > 1 then
				g.Count -= 1
				trimmed = true
				break
			end
		end
		if not trimmed then
			for _, g in out do
				if g.Count > 1 then
					g.Count -= 1
					trimmed = true
					break
				end
			end
		end
		if not trimmed then
			break
		end
	end
	return out
end

function Waves.count(n: number, section: string?, difficulty: string?): number
	return total(Waves.compose(n, section, difficulty))
end

function Waves.scale(n: number, difficulty: string?): Scale
	local d = Waves.Difficulty[difficulty or "Normal"] or Waves.Difficulty.Normal
	local k = math.max(0, n - 1)
	return {
		Hull = math.min(2.2, 1 + 0.12 * k) * d.Hull,
		Damage = math.min(1.8, 1 + 0.08 * k) * d.Damage,
		Fire = math.min(1.6, 1 + 0.06 * k) * d.Fire,
		Speed = math.min(1.25, 1 + 0.03 * k) * d.Speed,
	}
end

export type Spawner = {
	Section: string,
	Difficulty: string,
	Wave: number,
	Phase: string, -- "Intermission" | "Fighting" | "Done"
	Timer: number,
	Intermission: number,
	MaxWaves: number?,
}

function Waves.new(opts: { Section: string?, Difficulty: string?, Intermission: number?, FirstDelay: number?, MaxWaves: number? }?): Spawner
	local o = opts or {}
	return {
		Section = if o.Section == "Space" then "Space" else "Atmos",
		Difficulty = if o.Difficulty and Waves.Difficulty[o.Difficulty] then o.Difficulty else "Normal",
		Wave = 0,
		Phase = "Intermission",
		Timer = o.FirstDelay or 3,
		Intermission = o.Intermission or 5,
		MaxWaves = o.MaxWaves,
	}
end

export type Event = { Type: string, Wave: number, Groups: { Group }?, Scale: Scale? }

-- Avanza la máquina. `alive` = enemigos de la oleada que quedan. Devuelve un evento o nil.
function Waves.step(sp: Spawner, dt: number, alive: number): Event?
	if sp.Phase == "Done" then
		return nil
	elseif sp.Phase == "Intermission" then
		sp.Timer -= dt
		if sp.Timer <= 0 then
			sp.Wave += 1
			sp.Phase = "Fighting"
			return { Type = "Spawn", Wave = sp.Wave, Groups = Waves.compose(sp.Wave, sp.Section, sp.Difficulty), Scale = Waves.scale(sp.Wave, sp.Difficulty) }
		end
		return nil
	end
	if alive <= 0 then
		if sp.MaxWaves and sp.Wave >= sp.MaxWaves then
			sp.Phase = "Done"
			return { Type = "Done", Wave = sp.Wave }
		end
		sp.Phase = "Intermission"
		sp.Timer = sp.Intermission
		return { Type = "Cleared", Wave = sp.Wave }
	end
	return nil
end

-- Cambiar de sección (subir al espacio o bajar a la atmósfera): la siguiente oleada ya es de allí
function Waves.setSection(sp: Spawner, section: string)
	sp.Section = if section == "Space" then "Space" else "Atmos"
end

-- Puntos de salida en un anillo alrededor de `center` (repetibles: misma oleada, mismos sitios)
function Waves.ring(count: number, center: Vector3, radius: number, wave: number?): { Vector3 }
	local out = {}
	local offset = ((wave or 1) * 0.77) % (math.pi * 2)
	for i = 1, count do
		local a = offset + (i - 1) / math.max(1, count) * math.pi * 2
		local y = math.sin(a * 2 + offset) * radius * 0.15
		table.insert(out, center + Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius))
	end
	return out
end

-- Texto del objetivo para el panel
function Waves.objective(sp: Spawner, alive: number): string
	if sp.Phase == "Done" then
		return "¡Arena superada!"
	elseif sp.Phase == "Intermission" then
		if sp.Wave == 0 then
			return ("Prepárate: llegan enemigos en %d s"):format(math.max(0, math.ceil(sp.Timer)))
		end
		return ("Oleada %d superada · siguiente en %d s"):format(sp.Wave, math.max(0, math.ceil(sp.Timer)))
	end
	return ("Oleada %d · derriba %d %s"):format(sp.Wave, alive, if alive == 1 then "enemigo" else "enemigos")
end

return Waves
