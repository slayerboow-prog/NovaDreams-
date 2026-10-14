-- Planets: los 7 planetas de la Saga 2 («Ragnarock», docs/historia/saga-2-siete-planetas.md) como
-- ESTRELLAS brillantes al fondo del espacio, y el registro que dice a dónde lleva cada una
-- (cuentas puras; docs/espacio.md).
--
-- Cada planeta tiene una dirección fija en el cielo (Dir), su color (Hue) y su forma de brillar: rayos
-- (Rays, cuántos y su giro Tilt), destellos (Twinkle Hz y Depth), giro de los rayos (Spin °/s) y, algunos,
-- parpadeo doble (Blink) o un halo que late (Pulse). Se ven en el espacio y, muy flojitas, desde
-- Valmar de noche.
--
-- Viajar: apunta a una estrella (cono AimCone) o tócala → nombre y estado. Si su episodio existe y
-- está abierto, se viaja (fundido); si no, «Planeta X — próximamente» o el motivo del cerrojo.
--
-- REGISTRO (para los episodios futuros): Planets.setDestination("Lontana", { Travel = function(player)
-- … end, Available = function(player) return true end }) desde el servidor del episodio. Sin destino,
-- el planeta sale como «próximamente». Orden (decisión del dueño): Lontana primero; Ocrea, Marena,
-- Velaria, Fronda y Zéfira en el orden que quieras tras Lontana; Mercadia la última (tras los otros 6).

local Planets = {}

export type Planet = {
	Id: string,
	Name: string,
	City: string,
	Episode: number,
	Dir: Vector3, -- dirección en el cielo (unitaria)
	Hue: Color3,
	Glow: Color3, -- color del halo (más suave)
	Size: number, -- tamaño en pantalla (px del núcleo, a 1)
	Rays: number,
	Tilt: number, -- grados de giro de los rayos
	Spin: number, -- °/s
	Twinkle: number, -- Hz
	Depth: number, -- 0..1 cuánto baja el brillo al titilar
	Pulse: number?, -- Hz del halo que late
	Blink: boolean?, -- parpadeo doble (como un anuncio)
}

local function dir(azimuth: number, elevation: number): Vector3
	local a, e = math.rad(azimuth), math.rad(elevation)
	return Vector3.new(math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e))
end

local rgb = Color3.fromRGB

Planets.List = {
	{ Id = "Lontana", Name = "Lontana", City = "Redonda", Episode = 1, Dir = dir(20, 28), Hue = rgb(255, 172, 92), Glow = rgb(255, 120, 60), Size = 26, Rays = 4, Tilt = 0, Spin = 0, Twinkle = 0.7, Depth = 0.35 },
	{ Id = "Ocrea", Name = "Ocrea", City = "Rampa Mayor", Episode = 2, Dir = dir(70, 18), Hue = rgb(255, 112, 64), Glow = rgb(200, 60, 30), Size = 30, Rays = 6, Tilt = 15, Spin = 4, Twinkle = 0.35, Depth = 0.2, Pulse = 0.25 },
	{ Id = "Marena", Name = "Marena", City = "Pleamar", Episode = 3, Dir = dir(125, 34), Hue = rgb(84, 232, 222), Glow = rgb(30, 150, 200), Size = 24, Rays = 8, Tilt = 0, Spin = -10, Twinkle = 2.4, Depth = 0.3 },
	{ Id = "Velaria", Name = "Velaria", City = "Nevalumbre", Episode = 4, Dir = dir(185, 46), Hue = rgb(196, 224, 255), Glow = rgb(120, 170, 255), Size = 22, Rays = 4, Tilt = 45, Spin = 0, Twinkle = 3.2, Depth = 0.5 },
	{ Id = "Fronda", Name = "Fronda", City = "Copalta", Episode = 5, Dir = dir(240, 22), Hue = rgb(116, 240, 128), Glow = rgb(40, 170, 80), Size = 26, Rays = 6, Tilt = 0, Spin = 2, Twinkle = 0.5, Depth = 0.15 },
	{ Id = "Zefira", Name = "Zéfira", City = "Volandera", Episode = 6, Dir = dir(295, 38), Hue = rgb(232, 144, 255), Glow = rgb(160, 70, 230), Size = 25, Rays = 8, Tilt = 22, Spin = 18, Twinkle = 1.2, Depth = 0.25 },
	{ Id = "Mercadia", Name = "Mercadia", City = "Ciudad Saldo", Episode = 7, Dir = dir(340, 55), Hue = rgb(255, 222, 92), Glow = rgb(255, 170, 40), Size = 32, Rays = 12, Tilt = 0, Spin = 6, Twinkle = 1.6, Depth = 0.45, Blink = true },
} :: { Planet }

Planets.ById = {} :: { [string]: Planet }
for _, p in Planets.List do
	Planets.ById[p.Id] = p
end

Planets.AimCone = math.rad(7) -- apuntar con el morro así de cerca = «mirando a la estrella»
Planets.AimSeconds = 1.2 -- y mantenerlo esto para que salga VIAJAR
Planets.Distance = 1500 -- a qué distancia de la cámara se dibujan (dentro del campo de estrellas)

-- Destinos de los episodios (servidor): [id] = { Travel = fn(player), Available = fn(player)? }
local destinations: { [string]: { [string]: any } } = {}

function Planets.setDestination(id: string, dest: { [string]: any }?)
	if Planets.ById[id] then
		destinations[id] = dest
	end
end

function Planets.destination(id: string): { [string]: any }?
	return destinations[id]
end

-- ¿Abierto según el orden de la saga? done = { [id] = true } episodios terminados
function Planets.orderOpen(id: string, done: { [string]: any }?): (boolean, string?)
	local d = done or {}
	if id == "Lontana" then
		return true, nil
	elseif id == "Mercadia" then
		for _, p in Planets.List do
			if p.Id ~= "Mercadia" and not d[p.Id] then
				return false, "Mercadia"
			end
		end
		return true, nil
	end
	if not d.Lontana then
		return false, "Lontana"
	end
	return true, nil
end

-- Estado de un planeta para un jugador: "Ready" (se puede viajar), "Soon" (episodio aún no hecho),
-- "Locked" (Saga 1 sin terminar) u "Order" (antes otro episodio). ctx = { SagaDone, Tester, Done }
function Planets.status(id: string, ctx: { [string]: any }): (string, string?)
	local p = Planets.ById[id]
	if not p then
		return "Unknown", nil
	end
	if not (ctx.SagaDone or ctx.Tester) then
		return "Locked", nil
	end
	local dest = destinations[id]
	if not dest then
		return "Soon", nil
	end
	local open, need = Planets.orderOpen(id, ctx.Done)
	if not open and not ctx.Tester then
		return "Order", need
	end
	return "Ready", nil
end

function Planets.message(id: string, status: string, need: string?): string
	local p = Planets.ById[id]
	local name = if p then p.Name else id
	if status == "Ready" then
		return ("🪐 Rumbo a %s…"):format(name)
	elseif status == "Soon" then
		return ("🪐 Planeta %s — próximamente (episodio %d de «Ragnarock»)"):format(name, if p then p.Episode else 0)
	elseif status == "Locked" then
		return ("🔒 %s: termina la Saga 1 para viajar a los planetas de «Ragnarock»"):format(name)
	elseif status == "Order" then
		local other = need and Planets.ById[need]
		return ("🔒 %s: antes tienes que terminar %s"):format(name, if need == "Mercadia" then "los otros seis planetas" elseif other then other.Name else "otro episodio")
	end
	return name
end

-- El planeta al que apunta una dirección (dentro del cono), o nil
function Planets.aimed(look: Vector3, cone: number?): Planet?
	local c = cone or Planets.AimCone
	local best, bestA = nil, c
	for _, p in Planets.List do
		local a = math.acos(math.clamp(look.Unit:Dot(p.Dir.Unit), -1, 1))
		if a <= bestA then
			best, bestA = p, a
		end
	end
	return best
end

-- Brillo (0..1) de la estrella en el instante t: titila a su ritmo; Blink = dos destellos seguidos
function Planets.brightness(p: Planet, t: number): number
	local phase = p.Episode * 1.37
	local b = 1 - p.Depth * (0.5 + 0.5 * math.sin(t * p.Twinkle * math.pi * 2 + phase))
	if p.Blink then
		local k = (t * 0.5 + phase) % 1
		if (k > 0.1 and k < 0.14) or (k > 0.2 and k < 0.24) then
			b = math.min(1, b + 0.6)
		end
	end
	return math.clamp(b, 0, 1)
end

-- Giro de los rayos (grados) en el instante t
function Planets.rayAngle(p: Planet, t: number): number
	return (p.Tilt + p.Spin * t) % 360
end

return Planets
