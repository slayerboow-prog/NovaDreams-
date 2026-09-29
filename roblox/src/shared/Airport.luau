-- Airport: el Aeropuerto de Valmar y el Aeródromo de la Isla de las Gaviotas (datos compartidos).
--   * Kit/Airport construye los dos (pistas, terminal, torre, aviones…), FlightService los mueve y
--     vende los billetes, y Controllers/Flights los mueve fluidos en cada pantalla y enseña el vuelo.
--   * El aeropuerto está en tierra ganada al mar, al suroeste de la isla (al sur de la costa oeste).
--     Se llega por la carretera del aeropuerto (sale de la calle de x = -2375) o en el autobús
--     interurbano (parada «Aeropuerto de Valmar»).
--   * Cada avión sigue una ruta fija: rodaje, despegue, vuelo, aterrizaje y rodaje hasta su puerta.
--     La ruta es una curva suave por puntos; el servidor y los clientes calculan con Airport.pose
--     dónde va el avión a cada segundo del vuelo (todos lo ven en el mismo sitio).
--
-- Coordenadas en studs (X = este, Z = sur). El suelo de pistas y plataforma está en Y = Airport.GROUND.

local Airport = {}

Airport.Name = "Aeropuerto de Valmar"
Airport.GROUND = 0.4 -- cara de arriba del asfalto (la misma que las calles)

---------------------------------------------------------------------
-- Plano del aeropuerto (rectángulos X0..X1, Z0..Z1)
---------------------------------------------------------------------
-- Tierra ganada al mar: toda la plataforma del aeropuerto
Airport.Land = { X0 = -3780, X1 = -2240, Z0 = 2960, Z1 = 3520 }
-- Pista principal (de oeste a este), calle de rodaje paralela y sus tres salidas a la pista
Airport.Runway = { X0 = -3640, X1 = -2700, Z = 3420, Width = 50 }
Airport.Taxiway = { X0 = -3615, X1 = -2725, Z = 3330, Width = 20, Exits = { -3615, -3170, -2725 }, ExitWidth = 40 }
-- Plataforma de estacionamiento de los aviones, delante de la terminal
Airport.Apron = { X0 = -3020, X1 = -2560, Z0 = 3175, Z1 = 3320 }
-- Terminal: la mitad norte es la zona pública (mostradores, cafetería) y la sur, las puertas de
-- embarque; las separa el control de seguridad (Split)
Airport.Terminal = { X0 = -2990, X1 = -2710, Z0 = 3050, Z1 = 3150, Split = 3100, Floor = 1.0, Height = 22 }
-- Carretera de acceso (sale de la esquina de la calle de x = -2375 con la de z = 2625), el carril de
-- llegadas delante de la terminal, la acera de la terminal y el aparcamiento
Airport.Access = { X = -2375, Z0 = 2645, Z1 = 3005 }
Airport.Lane = { X0 = -3000, X1 = -2355, Z0 = 3005, Z1 = 3035 }
Airport.Walk = { X0 = -3000, X1 = -2700, Z0 = 3035, Z1 = 3050 }
Airport.Parking = { X0 = -2690, X1 = -2440, Z0 = 3035, Z1 = 3145 }
-- Torre de control y hangar
Airport.Tower = { X = -3110, Z = 3095 }
Airport.Hangar = { X0 = -3230, X1 = -3090, Z0 = 3180, Z1 = 3280 }
-- Puertas de embarque (X del puesto de estacionamiento de cada avión)
Airport.Gates = {
	Avion = { Number = 1, X = -2900 },
	Avioneta = { Number = 2, X = -2780 },
}

-- Aeródromo de la Isla de las Gaviotas (CityPlan.Islands): pista corta y caseta
Airport.Strip = { X0 = 2740, X1 = 3060, Z = -3950, Width = 24 }
Airport.StripApron = { X0 = 2995, X1 = 3060, Z0 = -4015, Z1 = -3962 }
Airport.StripHut = { X = 2975, Z = -4035 }

-- Sitios a los que se vuela
Airport.Places = {
	Valmar = { Id = "Valmar", Name = "Aeropuerto de Valmar", Short = "Valmar", Model = "Aeropuerto" },
	Gaviotas = { Id = "Gaviotas", Name = "Aeródromo de las Gaviotas", Short = "Isla de las Gaviotas", Model = "Aerodromo" },
}

---------------------------------------------------------------------
-- Aviones y billetes
---------------------------------------------------------------------
-- FloorY: altura del suelo de la cabina (la pieza Root) sobre el suelo, con el tren de aterrizaje.
Airport.Kinds = {
-- RootZ: dónde va el centro de la pieza Root (a lo largo del avión)
	Avion = { Name = "Avión", Length = 64, Span = 60, FloorY = 5, RootZ = -2, Seats = 12 },
	Avioneta = { Name = "Avioneta", Length = 26, Span = 34, FloorY = 3, RootZ = -1, Seats = 4 },
}

-- Dónde va la pieza Root del avión cuando sus ruedas están en "pose"
function Airport.rootCFrame(kind: string, pose: CFrame): CFrame
	local k = Airport.Kinds[kind]
	return pose * CFrame.new(0, k.FloorY - 0.3, k.RootZ)
end

-- Billetes: los niños vuelan gratis (con un adulto o solos) y los adolescentes pagan la mitad
Airport.FreeStages = { Nino = true }
Airport.HalfStages = { Adolescente = true }
Airport.MinStage = "Nino" -- los bebés no vuelan solos

-- Cada avión repite sus rutas en orden. Board = segundos de embarque en la puerta.
-- Pilot: (más adelante) el oficio de piloto podrá llevar un avión; ahora vuelan solos.
Airport.Planes = {
	{ Id = "VLM101", Kind = "Avion", Color = Color3.fromRGB(30, 90, 170), Routes = { "Vuelta" }, Board = 50, Pilot = nil },
	{ Id = "VLM205", Kind = "Avioneta", Color = Color3.fromRGB(220, 60, 50), Routes = { "IdaGaviotas", "VueltaGaviotas" }, Board = 40, Pilot = nil },
}

---------------------------------------------------------------------
-- Rutas: tramos por puntos con velocidad al empezar y al acabar (acelera o frena poco a poco)
---------------------------------------------------------------------
local G = Airport.GROUND
local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end
local function g(x: number, z: number): Vector3
	return Vector3.new(x, G, z)
end

type LegSpec = { Phase: string, Points: { Vector3 }, V0: number, V1: number, Reverse: boolean? }
export type Leg = LegSpec & { Pts: { Vector3 }, Cum: { number }, Length: number, T0: number, D: number, Ground: boolean }
export type Route = { Id: string, Name: string, From: string, To: string, Kind: string, Price: number, Legs: { Leg }, Total: number }

local RY = Airport.Runway.Z
local TY = Airport.Taxiway.Z
local AV = Airport.Gates.Avion.X
local AT = Airport.Gates.Avioneta.X
local SZ = Airport.Strip.Z
-- Puestos de estacionamiento (el morro mira al norte, hacia la terminal)
Airport.Stands = {
	Avion = g(AV, 3213),
	Avioneta = g(AT, 3194),
	Gaviotas = g(3025, -3990),
}

local SPECS: { [string]: { Name: string, From: string, To: string, Kind: string, Price: number, Legs: { LegSpec } } } = {
	-- Vuelta a la isla en avión: despega hacia el oeste, rodea la isla y aterriza hacia el este
	Vuelta = {
		Name = "Vuelta a la isla", From = "Valmar", To = "Valmar", Kind = "Avion", Price = 40,
		Legs = {
			{ Phase = "Retroceso", Reverse = true, V0 = 12, V1 = 1, Points = { g(AV, 3213), g(AV, 3285), g(AV - 15, 3320), g(AV - 45, TY) } },
			{ Phase = "Rodaje", V0 = 1, V1 = 20, Points = { g(AV - 45, TY), g(-2800, TY), g(-2742, TY + 8), g(-2725, 3385), g(-2740, RY - 4), g(-2770, RY) } },
			{ Phase = "Despegue", V0 = 20, V1 = 85, Points = { g(-2770, RY), g(-3000, RY), g(-3300, RY) } },
			{ Phase = "Ascenso", V0 = 85, V1 = 170, Points = { g(-3300, RY), v(-3500, 18, RY), v(-3800, 70, 3400), v(-4200, 160, 3200), v(-4300, 260, 2600) } },
			{ Phase = "Crucero", V0 = 170, V1 = 240, Points = { v(-4300, 260, 2600), v(-4000, 380, 1500), v(-3300, 440, 0), v(-2400, 480, -1800), v(-900, 520, -2850), v(900, 520, -2900), v(2500, 500, -2300), v(3600, 480, -800) } },
			{ Phase = "Crucero", V0 = 240, V1 = 240, Points = { v(3600, 480, -800), v(3900, 450, 900), v(3300, 400, 2400), v(2000, 340, 3500), v(0, 300, 3950) } },
			{ Phase = "Descenso", V0 = 240, V1 = 95, Points = { v(0, 300, 3950), v(-1800, 260, 4000), v(-3600, 220, 3950), v(-4600, 180, 3800), v(-5000, 150, 3560), v(-4750, 110, RY + 5), v(-4300, 70, RY) } },
			{ Phase = "Aproximación", V0 = 95, V1 = 65, Points = { v(-4300, 70, RY), v(-3900, 30, RY), g(-3560, RY) } },
			{ Phase = "Aterrizaje", V0 = 65, V1 = 16, Points = { g(-3560, RY), g(-3100, RY), g(-2760, RY) } },
			{ Phase = "Rodaje", V0 = 16, V1 = 20, Points = { g(-2760, RY), g(-2732, RY - 8), g(-2725, 3375), g(-2745, TY + 3), g(-2800, TY), g(AV + 20, TY) } },
			{ Phase = "Rodaje", V0 = 20, V1 = 3, Points = { g(AV + 20, TY), g(AV + 4, TY - 10), g(AV, 3290), g(AV, 3213) } },
		},
	},
	-- Avioneta de Valmar a la Isla de las Gaviotas (aterriza hacia el este en la pista corta)
	IdaGaviotas = {
		Name = "Isla de las Gaviotas", From = "Valmar", To = "Gaviotas", Kind = "Avioneta", Price = 25,
		Legs = {
			{ Phase = "Retroceso", Reverse = true, V0 = 12, V1 = 1, Points = { g(AT, 3194), g(AT, 3290), g(AT - 10, 3322), g(AT - 30, TY) } },
			{ Phase = "Rodaje", V0 = 1, V1 = 16, Points = { g(AT - 30, TY), g(-2745, TY + 2), g(-2725, 3380), g(-2742, RY - 3), g(-2770, RY) } },
			{ Phase = "Despegue", V0 = 16, V1 = 55, Points = { g(-2770, RY), g(-2900, RY), g(-3050, RY) } },
			{ Phase = "Ascenso", V0 = 55, V1 = 120, Points = { g(-3050, RY), v(-3200, 15, RY), v(-3450, 60, 3380), v(-3700, 120, 3150), v(-3600, 250, 2300) } },
			{ Phase = "Crucero", V0 = 120, V1 = 170, Points = { v(-3600, 250, 2300), v(-2600, 320, 800), v(-1300, 340, -600), v(0, 360, -1800), v(1300, 360, -2900) } },
			{ Phase = "Descenso", V0 = 170, V1 = 70, Points = { v(1300, 360, -2900), v(1000, 330, -3500), v(1300, 240, -3900), v(1700, 160, SZ) } },
			{ Phase = "Aproximación", V0 = 70, V1 = 48, Points = { v(1700, 160, SZ), v(2300, 70, SZ), g(2760, SZ) } },
			{ Phase = "Aterrizaje", V0 = 48, V1 = 8, Points = { g(2760, SZ), g(2900, SZ), g(3000, SZ) } },
			{ Phase = "Rodaje", V0 = 8, V1 = 2, Points = { g(3000, SZ), g(3018, SZ - 6), g(3025, -3975), g(3025, -3990) } },
		},
	},
	-- Y de vuelta a Valmar (despega hacia el oeste y aterriza hacia el este, como el avión)
	VueltaGaviotas = {
		Name = "Valmar", From = "Gaviotas", To = "Valmar", Kind = "Avioneta", Price = 25,
		Legs = {
			{ Phase = "Retroceso", Reverse = true, V0 = 6, V1 = 1, Points = { g(3025, -3990), g(3025, -3966), g(3035, -3953), g(3050, SZ) } },
			{ Phase = "Despegue", V0 = 1, V1 = 52, Points = { g(3050, SZ), g(2950, SZ), g(2800, SZ) } },
			{ Phase = "Ascenso", V0 = 52, V1 = 120, Points = { g(2800, SZ), v(2650, 15, SZ), v(2400, 70, SZ), v(2000, 200, -3800), v(1200, 340, -2800) } },
			{ Phase = "Crucero", V0 = 120, V1 = 170, Points = { v(1200, 340, -2800), v(0, 360, -1200), v(-1200, 360, 300), v(-2200, 320, 1700) } },
			{ Phase = "Descenso", V0 = 170, V1 = 70, Points = { v(-2200, 320, 1700), v(-3500, 250, 2400), v(-4300, 200, 3000), v(-4700, 150, 3350), v(-4500, 110, RY + 2), v(-4050, 60, RY) } },
			{ Phase = "Aproximación", V0 = 70, V1 = 48, Points = { v(-4050, 60, RY), v(-3800, 25, RY), g(-3580, RY) } },
			{ Phase = "Aterrizaje", V0 = 48, V1 = 16, Points = { g(-3580, RY), g(-3350, RY), g(-3195, RY) } },
			{ Phase = "Rodaje", V0 = 16, V1 = 22, Points = { g(-3195, RY), g(-3174, RY - 12), g(-3170, 3375), g(-3155, TY + 4), g(-3110, TY), g(AT - 20, TY) } },
			{ Phase = "Rodaje", V0 = 22, V1 = 3, Points = { g(AT - 20, TY), g(AT - 4, TY - 10), g(AT, 3290), g(AT, 3194) } },
		},
	},
}

-- Nombre de cada fase para el panel del vuelo
Airport.PhaseText = {
	Retroceso = "Saliendo de la puerta",
	Rodaje = "Rodando por la pista",
	Despegue = "Despegando",
	Ascenso = "Subiendo",
	Crucero = "En vuelo",
	Descenso = "Descendiendo",
	["Aproximación"] = "Aproximación",
	Aterrizaje = "Aterrizando",
}

---------------------------------------------------------------------
-- Curvas (Catmull-Rom) muestreadas en una línea de puntos con su distancia acumulada
---------------------------------------------------------------------
local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 + (p1 * 3 - p0 - p2 * 3 + p3) * t3) * 0.5
end

local function buildLeg(spec: LegSpec): Leg
	local P = spec.Points
	local pts = { P[1] }
	for i = 1, #P - 1 do
		local p0 = P[math.max(1, i - 1)]
		local p1, p2 = P[i], P[i + 1]
		local p3 = P[math.min(#P, i + 2)]
		-- (en las puntas se prolonga en línea recta: así la curva sale y llega recta)
		if i == 1 then
			p0 = p1 - (p2 - p1)
		end
		if i == #P - 1 then
			p3 = p2 + (p2 - p1)
		end
		local n = math.max(4, math.ceil((p2 - p1).Magnitude / 6))
		for k = 1, n do
			table.insert(pts, catmull(p0, p1, p2, p3, k / n))
		end
	end
	local cum = { 0 }
	for i = 2, #pts do
		cum[i] = cum[i - 1] + (pts[i] - pts[i - 1]).Magnitude
	end
	local length = cum[#cum]
	local ground = true
	for _, p in P do
		if math.abs(p.Y - G) > 0.01 then
			ground = false
		end
	end
	local leg = table.clone(spec) :: any
	leg.Pts, leg.Cum, leg.Length, leg.Ground = pts, cum, length, ground
	leg.D = 2 * length / math.max(0.1, spec.V0 + spec.V1) -- acelera (o frena) de V0 a V1 en el tramo
	return leg :: Leg
end

-- Punto a la distancia s del tramo
local function at(leg: Leg, s: number): Vector3
	local cum, pts = leg.Cum, leg.Pts
	if s <= 0 then
		return pts[1]
	elseif s >= leg.Length then
		return pts[#pts]
	end
	local lo, hi = 1, #cum
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if cum[mid] <= s then
			lo = mid
		else
			hi = mid
		end
	end
	local span = cum[hi] - cum[lo]
	local t = if span > 0 then (s - cum[lo]) / span else 0
	return pts[lo]:Lerp(pts[hi], t)
end
Airport._at = at

Airport.Routes = {} :: { [string]: Route }
for id, spec in SPECS do
	local legs = {}
	local t = 0
	for _, legSpec in spec.Legs do
		local leg = buildLeg(legSpec)
		leg.T0 = t
		t += leg.D
		table.insert(legs, leg)
	end
	Airport.Routes[id] = { Id = id, Name = spec.Name, From = spec.From, To = spec.To, Kind = spec.Kind, Price = spec.Price, Legs = legs, Total = t }
end

---------------------------------------------------------------------
-- Dónde va el avión a los t segundos de su ruta
---------------------------------------------------------------------
local MAX_BANK = math.rad(32)

-- Tramo en el que va y cuánto lleva en él
function Airport.legAt(route: Route, t: number): (Leg, number, number)
	for i, leg in route.Legs do
		if t < leg.T0 + leg.D or i == #route.Legs then
			return leg, math.clamp(t - leg.T0, 0, leg.D), i
		end
	end
	local last = route.Legs[#route.Legs]
	return last, last.D, #route.Legs
end

local function travelled(leg: Leg, tau: number): number
	local s = leg.V0 * tau + (leg.V1 - leg.V0) * tau * tau / (2 * leg.D)
	return math.clamp(s, 0, leg.Length)
end

local function heading(d: Vector3): number
	return math.atan2(-d.X, -d.Z)
end

-- CFrame del avión a ras de suelo (sus ruedas); el morro mira hacia -Z del CFrame.
-- Devuelve también la fase ("Rodaje", "Crucero"…) y la velocidad.
function Airport.pose(route: Route, t: number): (CFrame, string, number)
	local leg, tau = Airport.legAt(route, t)
	local s = travelled(leg, tau)
	local p = at(leg, s)
	local a, b = at(leg, s - 3), at(leg, s + 3)
	local dir = b - a
	if dir.Magnitude < 0.01 then
		local n = #leg.Pts
		dir = leg.Pts[n] - leg.Pts[math.max(1, n - 1)]
	end
	if leg.Reverse then
		dir = -dir
	end
	local speed = leg.V0 + (leg.V1 - leg.V0) * (if leg.D > 0 then tau / leg.D else 1)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	local yaw = if flat.Magnitude > 0.001 then heading(flat) else 0
	local pitch = 0
	local bank = 0
	if not leg.Ground and dir.Magnitude > 0.001 then
		pitch = math.asin(math.clamp(dir.Unit.Y, -1, 1))
		-- Se inclina en las curvas (más cuanto más rápido y más cerrada es la curva)
		local d0 = at(leg, s - 20) - at(leg, s - 30)
		local d1 = at(leg, s + 30) - at(leg, s + 20)
		local h0 = heading(Vector3.new(d0.X, 0, d0.Z))
		local h1 = heading(Vector3.new(d1.X, 0, d1.Z))
		local dh = (h1 - h0 + math.pi) % (2 * math.pi) - math.pi
		local rate = dh / 50 -- (radianes por stud)
		local lift = math.clamp((p.Y - G - 3) / 25, 0, 1)
		bank = math.clamp(math.atan(speed * speed * rate / 120), -MAX_BANK, MAX_BANK) * lift
	end
	local cf = CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, bank)
	return cf, leg.Phase, speed
end

-- Dónde espera el avión antes de salir en esta ruta (en su puerta)
function Airport.parkPose(route: Route): CFrame
	return (Airport.pose(route, 0))
end

-- ¿Qué ruta de este avión sale de este sitio? (la primera de su lista)
function Airport.routeFrom(plane: { [string]: any }, place: string): string?
	for _, id in plane.Routes do
		local route = Airport.Routes[id]
		if route and route.From == place then
			return id
		end
	end
	return nil
end

function Airport.planeById(id: string): { [string]: any }?
	for _, plane in Airport.Planes do
		if plane.Id == id then
			return plane
		end
	end
	return nil
end

-- Precio del billete según la edad (niños gratis, adolescentes la mitad)
function Airport.fare(route: Route, stage: string?): number
	if stage and Airport.FreeStages[stage] then
		return 0
	elseif stage and Airport.HalfStages[stage] then
		return math.floor(route.Price / 2)
	end
	return route.Price
end

-- Tiempo en texto: "45 s", "2 min"
function Airport.duration(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds < 60 then
		return ("%d s"):format(seconds)
	end
	return ("%d min"):format(math.ceil(seconds / 60))
end

-- ¿El punto (x, z) está dentro de un rectángulo (con margen)?
function Airport.inRect(r: { [string]: number }, x: number, z: number, margin: number?): boolean
	local m = margin or 0
	return x >= r.X0 - m and x <= r.X1 + m and z >= r.Z0 - m and z <= r.Z1 + m
end

-- Suelo pavimentado por donde ruedan los aviones (para las pruebas: nunca se salen del asfalto)
function Airport.paved(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	local R, T, S = Airport.Runway, Airport.Taxiway, Airport.Strip
	if x >= R.X0 - m and x <= R.X1 + m and math.abs(z - R.Z) <= R.Width / 2 + m then
		return true
	end
	if x >= T.X0 - T.Width / 2 - m and x <= T.X1 + T.Width / 2 + m and math.abs(z - T.Z) <= T.Width / 2 + m then
		return true
	end
	for _, ex in T.Exits do
		if math.abs(x - ex) <= T.ExitWidth / 2 + m and z >= T.Z - m and z <= R.Z + m then
			return true
		end
	end
	if Airport.inRect(Airport.Apron, x, z, m) or Airport.inRect(Airport.StripApron, x, z, m) then
		return true
	end
	return x >= S.X0 - m and x <= S.X1 + m and math.abs(z - S.Z) <= S.Width / 2 + m
end

return Airport
