-- Panic: la gente de Valmar huye como una ciudad de verdad en peligro (cuentas puras; las usan el
-- cliente —Controllers/Ambient y Traffic: peatones y coches de tu pantalla— y el servidor
-- —InvasionService y CrowdService: la gente de las plazas y los parques—; las prueba
-- scripts/test-invasion.luau).
--
-- Barato: el SERVIDOR decide las amenazas (dónde hay alienígenas, dónde aterrizan las naves y dónde
-- explota algo) y los SITIOS SEGUROS (puertas de edificios, bocas de metro, comisarías, refugios) y
-- los publica (atributos InvasionThreats / InvasionSafe de workspace); cada cliente anima a su gente
-- con estas cuentas (sin red por cada peatón). Lo que hace cada uno (Panic.behaviour, repetible por su
-- semilla): correr lejos de la amenaza hacia el sitio seguro más cercano, tropezar y levantarse,
-- esconderse agachado detrás de algo y asomarse, llamar a la policía señalando a los alienígenas, o
-- —los padres— agarrar a los niños y correr con ellos. Los conductores aceleran para salir de ahí,
-- algunos abandonan el coche y se oyen cláxones (atascos). Al acabar, la gente vuelve poco a poco
-- (Panic.returnShare). Topes de efectos según el nivel gráfico (Panic.Caps).

local Panic = {}

export type Threat = { Pos: Vector3, Radius: number, Weight: number? }
export type Safe = { Pos: Vector3, Kind: string, Name: string? }

Panic.Radius = 120 -- un alienígena asusta a la gente de alrededor
Panic.LandingRadius = 160
Panic.ExplosionRadius = 90
Panic.RunSpeed = 2.7 -- veces su paso normal
Panic.SafeKinds = { Door = 1, Metro = 0.9, Police = 1.1, Shelter = 1.2, Away = 0.6 } -- (cuánto prefieren cada tipo)
Panic.ReturnSeconds = 150 -- al acabar, en cuánto vuelve toda la gente a la calle
Panic.Caps = {
	Low = { Runners = 10, Barks = 1, BarkEvery = 2.5, Honks = 1 },
	Medium = { Runners = 18, Barks = 2, BarkEvery = 1.6, Honks = 2 },
	High = { Runners = 30, Barks = 3, BarkEvery = 1.1, Honks = 3 },
}

-- Gritos y frases (13+: miedo de película, nada desagradable)
Panic.Barks = {
	Run = { "¡Corred!", "¡Al metro, rápido!", "¡Están aterrizando!", "¡Por aquí, por aquí!", "¡Mamá, vámonos!", "¡No mires atrás!", "¡Que alguien llame a la policía!" },
	Call = { "¿Policía? ¡Hay naves en la plaza!", "¡Allí, allí! ¡Mirad!", "¡Están en el parque!", "¡Ayuda! ¡Por favor!" },
	Hide = { "Shhh… no hagas ruido.", "Aquí detrás no nos ven.", "¿Se han ido ya?" },
	Trip = { "¡Ay!", "¡Mi zapato!", "¡Estoy bien, estoy bien!" },
	Grab = { "¡Dame la mano, cariño!", "¡Agárrate fuerte!", "¡Ven conmigo, rápido!" },
	Return = { "Parece que ya ha pasado…", "Qué día más raro.", "¿Has visto eso? Increíble.", "Menos mal que vinieron a ayudar." },
	Rescued = { "¡Gracias! ¡Pensaba que no salía de esta!", "¡Me has salvado!", "Voy al refugio. ¡Ten cuidado!" },
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Cuánto miedo hay aquí (0..1): la amenaza más cercana dentro de su radio
function Panic.level(pos: Vector3, threats: { Threat }): number
	local best = 0
	for _, t in threats do
		local d = flat(pos - t.Pos).Magnitude
		if d < t.Radius then
			local k = (1 - d / t.Radius) * (t.Weight or 1)
			if k > best then
				best = k
			end
		end
	end
	return math.clamp(best, 0, 1)
end

-- Hacia dónde huir (unitario en planta): lejos de todas las amenazas cercanas (las más cercanas
-- empujan más). nil si no hay ninguna cerca.
function Panic.fleeDir(pos: Vector3, threats: { Threat }): Vector3?
	local push = Vector3.zero
	for _, t in threats do
		local away = flat(pos - t.Pos)
		local d = away.Magnitude
		if d < t.Radius then
			local k = (1 - d / t.Radius) ^ 2 * (t.Weight or 1)
			push += (if d > 0.1 then away / d else Vector3.new(1, 0, 0)) * k
		end
	end
	if push.Magnitude < 1e-4 then
		return nil
	end
	return push.Unit
end

-- El sitio seguro al que corre: el más cercano que esté MÁS LEJOS de las amenazas que él y al que no
-- haya que pasar por delante de un alienígena (preferencias por tipo). nil = solo correr lejos.
function Panic.chooseSafe(pos: Vector3, threats: { Threat }, safes: { Safe }, maxDist: number?): Safe?
	local here = Panic.level(pos, threats)
	local flee = Panic.fleeDir(pos, threats)
	local best, bestScore = nil, math.huge
	for _, s in safes do
		local to = flat(s.Pos - pos)
		local d = to.Magnitude
		if d <= (maxDist or 260) then
			local there = Panic.level(s.Pos, threats)
			-- (no corre HACIA el peligro: el sitio tiene que estar más tranquilo y no detrás de la amenaza)
			local toward = flee and d > 1 and (to / d):Dot(flee) < -0.35
			if there < here - 0.05 or (here == 0 and there == 0) then
				if not toward then
					local score = d / (Panic.SafeKinds[s.Kind] or 1) + there * 300
					if score < bestScore then
						best, bestScore = s, score
					end
				end
			end
		end
	end
	return best
end

-- Lo que hace cada persona (repetible por su semilla 0..1 y el miedo que hay). Los niños con un
-- adulto cerca: «Grab» (los agarran). Devuelve "Run" | "Trip" | "Hide" | "Call" | "Grab" | "Calm"
function Panic.behaviour(seed: number, level: number, isKid: boolean?, adultNear: boolean?): string
	if level <= 0.02 then
		return "Calm"
	end
	if isKid and adultNear then
		return "Grab"
	end
	local s = seed % 1
	if level > 0.6 then
		if s < 0.1 then
			return "Trip"
		elseif s < 0.25 then
			return "Hide"
		end
		return "Run"
	end
	if s < 0.18 then
		return "Call"
	elseif s < 0.4 then
		return "Hide"
	elseif s < 0.47 then
		return "Trip"
	end
	return "Run"
end

-- En una acera solo se puede ir hacia un lado o el otro: el que más aleja de la amenaza (+1 / -1)
function Panic.sidewalkSign(along: Vector3, flee: Vector3?): number
	if not flee then
		return 1
	end
	return if flat(along):Dot(flee) >= 0 then 1 else -1
end

-- Lo que hace un conductor (semilla 0..1 y miedo): "Speed" (acelera para salir de ahí), "Abandon"
-- (para, se baja y corre) o "Honk" (atasco: pita y espera)
function Panic.driver(seed: number, level: number): string
	if level <= 0.05 then
		return "Normal"
	end
	local s = seed % 1
	if level > 0.5 and s < 0.15 then
		return "Abandon"
	elseif s < 0.4 then
		return "Honk"
	end
	return "Speed"
end
Panic.DriverSpeed = { Normal = 1, Speed = 1.45, Honk = 0.35, Abandon = 0 }

-- Al acabar: qué parte de la gente ha vuelto a la calle (0.15 → 1 en ReturnSeconds)
function Panic.returnShare(sinceEnd: number?): number
	if sinceEnd == nil then
		return 1
	end
	local t = math.clamp(sinceEnd / Panic.ReturnSeconds, 0, 1)
	return 0.15 + 0.85 * (t * t * (3 - 2 * t))
end

-- Durante la invasión: qué parte de la gente sigue en la calle según el miedo del barrio (el resto se
-- ha metido en casa, en el metro o en las tiendas)
function Panic.streetShare(level: number): number
	return math.clamp(1 - level * 0.75, 0.2, 1)
end

-- Los puntos del cordón policial alrededor de una zona (conos y cinta)
function Panic.cordon(center: Vector3, radius: number, n: number): { Vector3 }
	local out = {}
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		table.insert(out, center + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
	end
	return out
end

-- Los topes del nivel gráfico ("Low" | "Medium" | "High")
function Panic.caps(tier: string?): { Runners: number, Barks: number, BarkEvery: number, Honks: number }
	return Panic.Caps[tier or "Medium"] or Panic.Caps.Medium
end

-- Una frase de un tipo (repetible por la semilla)
function Panic.bark(kind: string, seed: number): string?
	local list = Panic.Barks[kind]
	if not list or #list == 0 then
		return nil
	end
	return list[math.clamp(math.floor((seed % 1) * #list) + 1, 1, #list)]
end

-- Para publicar las amenazas (atributo de workspace: lista corta y redondeada)
function Panic.encode(threats: { Threat }, max: number?): { { number } }
	local out = {}
	for i, t in threats do
		if i > (max or 24) then
			break
		end
		table.insert(out, { math.floor(t.Pos.X + 0.5), math.floor(t.Pos.Z + 0.5), math.floor(t.Radius), math.floor((t.Weight or 1) * 10 + 0.5) / 10 })
	end
	return out
end

function Panic.decode(list: any): { Threat }
	local out = {}
	if type(list) ~= "table" then
		return out
	end
	for _, e in list do
		if type(e) == "table" and type(e[1]) == "number" and type(e[2]) == "number" then
			table.insert(out, { Pos = Vector3.new(e[1], 0, e[2]), Radius = tonumber(e[3]) or Panic.Radius, Weight = tonumber(e[4]) or 1 })
		end
	end
	return out
end

return Panic
