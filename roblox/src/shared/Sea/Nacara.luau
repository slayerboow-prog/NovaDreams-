-- Nacara: la plaza de prueba de Nácara, la capital de los Hondarios (fase 0 de
-- docs/mar/civilizacion-marina.md, «Fase 0 · Plaza de prueba»). Solo datos y cuentas puras (sin crear
-- nada de Roblox): las usan World/NacaraBuilder (construye la plaza), Services/NacaraService (gente,
-- charlas y punto del mapa), Controllers/NacaraLife (vida y perlas de guía), Controllers/Swimming y
-- AgeMotion (dentro de la cúpula de aire se anda, no se nada), Controllers/SeaBiome (la luz de la
-- ciudad) y scripts/test-nacara.luau.
--
-- ES UNA PRUEBA: se ve, se visita y se habla, pero no da premios, no vende nada y no guarda nada nuevo
-- (el dueño la mira en su móvil antes de construir el resto de la ciudad).
--
--   Nacara.Center / FloorY       dónde está y a qué altura está el suelo de la plaza (37,5 m)
--   Nacara.toWorld(x, z, y?)     de coordenadas de la plaza (X al este, Z al sur) al mundo
--   Nacara.inDome(pos)           ¿dentro de la cúpula de aire? (se respira y se anda)
--   Nacara.covers(x, z)          ¿pisa la plaza? (SeaBiome no planta ahí su decorado)
--   Nacara.currentAt(pos)        la corriente guía (del jardín de coral más cercano a la plaza)
--   Nacara.routePoints()         los puntos de la ruta (con su altura) para las perlas de guía
--   Nacara.lookNear(look, pos)   la luz bajo el agua cerca de la ciudad (la da la ciudad: perlas y coral)

local Ocean = require(script.Parent.Ocean)

local Nacara = {}

local rgb = Color3.fromRGB
local sqrt, min, max = math.sqrt, math.min, math.max

Nacara.Name = "Nácara (prueba)"
Nacara.Test = true -- (nada de premios, tienda de verdad ni guardado: es para mirar)

-- Llanura Sumergida, a la entrada del Cañón de las Catedrales (decisión 2 del dueño). A 540 studs de
-- las Ruinas de Valmar la Vieja, a 445 de Valmar Hundida y a ~280 del borde del cañón (sus agujas de
-- roca se ven detrás). Lejos de los puertos (> 1600 studs), del Abismo Silente (megalodón: > 2500) y
-- de los barcos (todo queda ≥ 60 studs bajo la superficie).
Nacara.Center = { X = -2650, Z = 5000 }
Nacara.FloorY = -136 -- suelo de la plaza: (−2 − (−136)) / 3,57 ≈ 37,5 m
Nacara.Radius = 50 -- la plaza (disco de nácar)
Nacara.Clear = 60 -- el terreno se allana hasta aquí (la plaza queda un poco hundida en la llanura)
Nacara.Budget = 900 -- piezas del servidor de TODA la plaza (edificios + gente)
Nacara.MaxTop = 64 -- lo más alto de una torre sobre el suelo de la plaza (queda a ~70 studs de la superficie)

-- La cúpula de aire (la Lonja Honda): dentro hay terreno de Aire, suelo seco y se rellena el aire
Nacara.Dome = { X = -28, Z = 4, Radius = 19, Air = 17.5 }

-- Lo que hay en la plaza (coordenadas de la plaza: X al este, Z al sur; R = lo que ocupa en el suelo).
-- test-nacara comprueba que nada se pisa y que todo cabe en la plaza.
Nacara.Layout = {
	{ Id = "Fuente", Kind = "Fountain", X = 0, Z = 0, R = 8 },
	{ Id = "Cupula", Kind = "Dome", X = Nacara.Dome.X, Z = Nacara.Dome.Z, R = Nacara.Dome.Radius },
	{ Id = "TorreRosa", Kind = "Tower", X = 26, Z = -34, R = 6, H = 64, Color = "Pink" },
	{ Id = "TorreVioleta", Kind = "Tower", X = -28, Z = -32, R = 6, H = 56, Color = "Violet" },
	{ Id = "TorreCian", Kind = "Tower", X = -30, Z = 32, R = 6, H = 48, Color = "Cyan" },
	{ Id = "TorreCoral", Kind = "Tower", X = 29, Z = 32, R = 6, H = 58, Color = "Coral" },
	{ Id = "ConchaEste", Kind = "Shell", X = 37, Z = -12, R = 8 },
	{ Id = "ConchaSur", Kind = "Shell", X = 39, Z = 12, R = 7 },
	{ Id = "Terraza1", Kind = "Terrace", X = 0, Z = 30, R = 9, H = 4 },
	{ Id = "Terraza2", Kind = "Terrace", X = -15, Z = 40, R = 7, H = 9 },
	{ Id = "Terraza3", Kind = "Terrace", X = 13, Z = 42, R = 6, H = 14 },
	{ Id = "ArcoNorte", Kind = "Arch", X = 0, Z = -47, R = 3, Facing = "North" },
	{ Id = "ArcoEste", Kind = "Arch", X = 47, Z = 0, R = 3, Facing = "East" },
}
Nacara.ById = {}
for _, item in Nacara.Layout do
	Nacara.ById[item.Id] = item
end

-- Puestos de la Lonja Honda (dentro de la cúpula; el de Oriana cruza la membrana: ella atiende desde el
-- agua y tú desde el aire). Ángulo alrededor del centro de la cúpula (0 = este, hacia la fuente).
Nacara.Stalls = {
	{ Id = "Algas", Name = "Algas y pan de kelp", Angle = 70, Dist = 11, Color = rgb(70, 170, 110) },
	{ Id = "Faroles", Name = "Perlas-farola", Angle = 130, Dist = 11, Color = rgb(150, 220, 255) },
	{ Id = "Perlera", Name = "La perlera de Oriana", Angle = 180, Dist = 16.2, Color = rgb(240, 210, 235), Keeper = "Oriana" },
	{ Id = "Nacar", Name = "Hilo y peines de nácar", Angle = 290, Dist = 11, Color = rgb(255, 180, 150) },
}

-- Los Hondarios de la plaza. Look: colores de escamas, piel y ropa (siempre vestidos: túnica de kelp y
-- peto de nácar; los de la Guardia, armadura de concha y bastón sin punta). Y = altura sobre el suelo.
-- Role: Quest (Ilun: charla de bienvenida), Shop (Oriana), Guard, Folk.
Nacara.People = {
	{ Id = "Ilun", Name = "Ilun", Title = "farolero", Role = "Quest", X = 9, Z = -14, Y = 5.5, Face = { 0, -40 }, Look = { Skin = rgb(198, 134, 66), Scales = rgb(40, 170, 190), Tunic = rgb(40, 96, 80), Crest = rgb(80, 220, 230), Hair = rgb(20, 20, 22) } },
	{ Id = "Oriana", Name = "Oriana", Title = "perlera", Role = "Shop", Stall = "Perlera", Y = 5, Look = { Skin = rgb(241, 194, 125), Scales = rgb(150, 100, 200), Tunic = rgb(90, 60, 120), Crest = rgb(230, 150, 255), Hair = rgb(120, 80, 40) } },
	{ Id = "GuardiaNorte", Name = "Guardia de la Corriente", Role = "Guard", X = -9, Z = -44, Y = 5, Face = { 0, -80 }, Look = { Skin = rgb(141, 85, 36), Scales = rgb(30, 70, 120), Tunic = rgb(40, 50, 70), Crest = rgb(60, 120, 220), Hair = rgb(20, 20, 22) } },
	{ Id = "GuardiaEste", Name = "Guardia de la Corriente", Role = "Guard", X = 44, Z = 9, Y = 5, Face = { 90, 9 }, Look = { Skin = rgb(224, 172, 105), Scales = rgb(40, 90, 110), Tunic = rgb(50, 60, 70), Crest = rgb(90, 200, 200), Hair = rgb(70, 45, 25) } },
	{ Id = "Cantora", Name = "Cantora del Coro", Role = "Folk", X = 13, Z = 42, Y = 19.5, Face = { 0, 0 }, Look = { Skin = rgb(92, 58, 30), Scales = rgb(210, 200, 230), Tunic = rgb(120, 110, 150), Crest = rgb(240, 240, 255), Hair = rgb(190, 190, 195) } },
	{ Id = "Farolera", Name = "Farolera", Role = "Folk", X = 20, Z = -28, Y = 20, Face = { 0, 0 }, Look = { Skin = rgb(255, 219, 172), Scales = rgb(240, 120, 90), Tunic = rgb(130, 60, 50), Crest = rgb(255, 170, 120), Hair = rgb(150, 60, 30) } },
	{ Id = "Cultivador", Name = "Cultivador de algas", Role = "Folk", X = -12, Z = -22, Y = 5, Face = { -28, 4 }, Look = { Skin = rgb(198, 134, 66), Scales = rgb(70, 150, 80), Tunic = rgb(60, 90, 50), Crest = rgb(150, 220, 120), Hair = rgb(40, 28, 20) } },
	{ Id = "Viajera", Name = "Viajera de las corrientes", Role = "Folk", X = 22, Z = 18, Y = 6, Face = { 0, 0 }, Look = { Skin = rgb(141, 85, 36), Scales = rgb(240, 200, 90), Tunic = rgb(150, 110, 40), Crest = rgb(255, 230, 120), Hair = rgb(20, 20, 22) } },
}

-- La cola cuelga ~6,3 studs por debajo de la cadera (que va a ~2 sobre los «pies» de Npc.create): un
-- Hondario flota al menos TailClear studs sobre lo que tenga debajo (suelo o terraza) para no meter la
-- aleta en el nácar (lo comprueba test-nacara)
Nacara.TailClear = 4.6

-- Los carteles (texto de verdad en el juego, SurfaceGui)
Nacara.Signs = {
	{ Id = "Prueba", Text = "NÁCARA · plaza de prueba", Sub = "Fase 0 · aún no se vende ni se gana nada", X = 13, Z = -49, H = 7 },
	{ Id = "Lonja", Text = "LONJA HONDA", Sub = "Cúpula de aire: aquí se respira y se anda", X = -6, Z = 12, H = 6, FaceDome = true },
	{ Id = "Rutas", Text = "↑ Ruinas de Valmar la Vieja", Sub = "↓ Valmar Hundida · Cañón de las Catedrales", X = -14, Z = -49, H = 6 },
}

---------------------------------------------------------------------
-- Cuentas
---------------------------------------------------------------------
local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- De la plaza al mundo (X al este, Z al sur; y = sobre el suelo de la plaza)
function Nacara.toWorld(x: number, z: number, y: number?): Vector3
	return Vector3.new(Nacara.Center.X + x, Nacara.FloorY + (y or 0), Nacara.Center.Z + z)
end

function Nacara.centerPosition(): Vector3
	return Nacara.toWorld(0, 0, 0)
end

function Nacara.depthMeters(): number
	return Ocean.meters(Nacara.FloorY)
end

function Nacara.domeCenter(): Vector3
	return Nacara.toWorld(Nacara.Dome.X, Nacara.Dome.Z, 0)
end

-- ¿Dentro de la cúpula de aire? (el cuerpo: HumanoidRootPart; con 1,5 studs de margen dentro del aire)
-- Fase 1: también dentro de las conchas con aire y de la posada de La Burbuja (shared/Sea/Civ.inAir).
local civ: any = nil
function Nacara.inDome(pos: Vector3, margin: number?): boolean
	local c = Nacara.domeCenter()
	if pos.Y >= Nacara.FloorY - 2 and (pos - c).Magnitude < Nacara.Dome.Air - (margin or 1.5) then
		return true
	end
	if civ == nil then
		local ok, mod = pcall(function()
			return require(script.Parent.Civ) :: any
		end)
		civ = if ok then mod else false
	end
	return civ ~= false and civ.inAir(pos, margin) == true
end

-- ¿Pisa la plaza? (el decorado del cliente no planta nada aquí)
function Nacara.covers(x: number, z: number): boolean
	local dx, dz = x - Nacara.Center.X, z - Nacara.Center.Z
	return dx * dx + dz * dz < (Nacara.Clear + 4) ^ 2
end

-- Dónde está un Hondario (o el sitio de un puesto) en coordenadas de la plaza
function Nacara.stallSpot(stall: { [string]: any }, dist: number?): (number, number)
	local a = math.rad(stall.Angle)
	local d = dist or stall.Dist
	return Nacara.Dome.X + math.cos(a) * d, Nacara.Dome.Z + math.sin(a) * d
end

function Nacara.personSpot(person: { [string]: any }): (number, number, number)
	if person.Stall then
		for _, stall in Nacara.Stalls do
			if stall.Id == person.Stall then
				-- (detrás del mostrador, ya fuera de la membrana: en el agua)
				local x, z = Nacara.stallSpot(stall, Nacara.Dome.Radius + 2.6)
				return x, z, person.Y or 2
			end
		end
	end
	return person.X or 0, person.Z or 0, person.Y or 3
end

---------------------------------------------------------------------
-- La ruta de buceo: del jardín de coral más cercano a la plaza
---------------------------------------------------------------------
-- El jardín de coral de la orilla más cercano (Ocean.ShoreReefs) y, a medio camino, las Ruinas de
-- Valmar la Vieja (punto de buceo del mapa). Las perlas de guía van a ~10 studs del fondo.
local function nearestReef(): { [string]: any }
	local best, bestD = nil, math.huge
	for _, reef in Ocean.ShoreReefs do
		local d = (reef.X - Nacara.Center.X) ^ 2 + (reef.Z - Nacara.Center.Z) ^ 2
		if d < bestD then
			best, bestD = reef, d
		end
	end
	return best :: any
end
Nacara.StartReef = nearestReef()
do
	local ruins = Ocean.PoiById.Ruinas
	Nacara.Route = {
		{ X = Nacara.StartReef.X, Z = Nacara.StartReef.Z, Name = Nacara.StartReef.Name },
		{ X = (Nacara.StartReef.X + ruins.X) / 2 - 40, Z = (Nacara.StartReef.Z + ruins.Z) / 2 },
		{ X = ruins.X + 40, Z = ruins.Z - 40, Name = ruins.Name },
		{ X = Nacara.Center.X + 60, Z = Nacara.Center.Z - 230 },
		{ X = Nacara.Center.X, Z = Nacara.Center.Z - Nacara.Radius - 14, Name = "Arco de entrada de Nácara" },
	}
end
Nacara.RouteHalfWidth = 26 -- la corriente empuja a menos de esto de la línea
Nacara.RouteSpeed = 2.4 -- studs/s de empuje (como las corrientes del mar: se nada en contra sin problema)
Nacara.RouteMarkerStep = 55 -- una perla de guía cada tantos studs

-- Altura de la ruta en un punto: 10 studs sobre el fondo, nunca a menos de 4 de la superficie
local function routeY(x: number, z: number): number
	local floorY = Ocean.floorY(x, z) or Ocean.CoastY
	return min(floorY + 10, Ocean.Surface - 4)
end
Nacara.routeY = routeY

-- Longitud total de la ruta (en el suelo)
function Nacara.routeLength(): number
	local total = 0
	for i = 1, #Nacara.Route - 1 do
		local a, b = Nacara.Route[i], Nacara.Route[i + 1]
		total += sqrt((b.X - a.X) ^ 2 + (b.Z - a.Z) ^ 2)
	end
	return total
end

-- Las perlas de guía: { Position, Dir } cada RouteMarkerStep studs (siempre las mismas)
local markerCache: { { [string]: any } }? = nil
function Nacara.routePoints(): { { [string]: any } }
	if markerCache then
		return markerCache
	end
	local list = {}
	local carry = 0
	for i = 1, #Nacara.Route - 1 do
		local a, b = Nacara.Route[i], Nacara.Route[i + 1]
		local dx, dz = b.X - a.X, b.Z - a.Z
		local len = sqrt(dx * dx + dz * dz)
		local dir = Vector3.new(dx / len, 0, dz / len)
		local d = carry
		while d < len do
			local x, z = a.X + dx * d / len, a.Z + dz * d / len
			table.insert(list, { Position = Vector3.new(x, routeY(x, z), z), Dir = dir })
			d += Nacara.RouteMarkerStep
		end
		carry = d - len
	end
	markerCache = list
	return list
end

-- La corriente guía: empuja suave por la ruta hacia la plaza (solo bajo el agua y cerca de la línea)
function Nacara.currentAt(pos: Vector3): Vector3
	if pos.Y > Ocean.Surface - 1 then
		return Vector3.zero
	end
	local best, bestDir = math.huge, nil
	for i = 1, #Nacara.Route - 1 do
		local a, b = Nacara.Route[i], Nacara.Route[i + 1]
		local dx, dz = b.X - a.X, b.Z - a.Z
		local len2 = dx * dx + dz * dz
		local t = math.clamp(((pos.X - a.X) * dx + (pos.Z - a.Z) * dz) / len2, 0, 1)
		local px, pz = a.X + dx * t, a.Z + dz * t
		local d = sqrt((pos.X - px) ^ 2 + (pos.Z - pz) ^ 2)
		if d < best then
			best = d
			local l = sqrt(len2)
			bestDir = Vector3.new(dx / l, 0, dz / l)
		end
	end
	if not bestDir or best >= Nacara.RouteHalfWidth then
		return Vector3.zero
	end
	-- (ya en la plaza no empuja: se nada libre)
	local dc = sqrt((pos.X - Nacara.Center.X) ^ 2 + (pos.Z - Nacara.Center.Z) ^ 2)
	if dc < Nacara.Radius + 10 then
		return Vector3.zero
	end
	return bestDir * Nacara.RouteSpeed * (1 - smooth(best / Nacara.RouteHalfWidth))
end

---------------------------------------------------------------------
-- La luz cerca de la ciudad (shared/Cosmos/EnvZones.underwaterKey la pinta; SeaBiome la pide)
---------------------------------------------------------------------
-- A 37 m apenas llega el sol: la luz la da la ciudad (perlas-farola y coral de luz). Cerca de la plaza
-- la bioluminiscencia manda (más Bloom en lo Neon), el agua es algo más clara (se ven las torres de lejos)
-- y la luz que rellena va al azul perla en vez de al negro. Lejos (más de NearFar studs), como siempre.
Nacara.NearFull = 110 -- hasta aquí, del todo
Nacara.NearFar = 320 -- desde aquí, nada
Nacara.Glow = {
	Glow = 0.85,
	Exposure = 0.22,
	Density = -0.08,
	Ambient = rgb(70, 100, 150),
	Outdoor = rgb(96, 128, 180),
	FillMix = 0.6,
	Tint = rgb(196, 214, 240),
	Visibility = 1.25,
}

function Nacara.nearness(pos: Vector3): number
	local d = sqrt((pos.X - Nacara.Center.X) ^ 2 + (pos.Z - Nacara.Center.Z) ^ 2)
	local k = 1 - smooth((d - Nacara.NearFull) / (Nacara.NearFar - Nacara.NearFull))
	-- (solo en lo hondo: arriba, cerca de la superficie, manda el sol)
	local deep = smooth((Ocean.meters(pos.Y) - 12) / 14)
	return k * deep
end

function Nacara.lookNear(look: { [string]: any }?, pos: Vector3): { [string]: any }?
	if not look then
		return look
	end
	local k = Nacara.nearness(pos)
	if k <= 0.001 then
		return look
	end
	local G = Nacara.Glow
	local out = table.clone(look)
	out.Glow = max(look.Glow or 0, G.Glow * k)
	out.Exposure = (look.Exposure or 0) + G.Exposure * k
	if type(look.Density) == "number" then
		out.Density = math.clamp(look.Density + G.Density * k, 0, 1)
	end
	if typeof(look.Ambient) == "Color3" then
		out.Ambient = look.Ambient:Lerp(G.Ambient, k)
	end
	if typeof(look.Outdoor) == "Color3" then
		out.Outdoor = look.Outdoor:Lerp(G.Outdoor, k)
	end
	out.FillMix = max(look.FillMix or 0, G.FillMix * k)
	if typeof(look.Tint) == "Color3" then
		out.Tint = look.Tint:Lerp(G.Tint, 0.35 * k)
	end
	if type(look.Visibility) == "number" then
		out.Visibility = look.Visibility * (1 + (G.Visibility - 1) * k)
	end
	return out
end

---------------------------------------------------------------------
-- Las charlas (DialogueService.play). No dan premios ni cambian nada: es la plaza de prueba.
---------------------------------------------------------------------
Nacara.Dialogues = {
	Ilun = {
		{ S = "Narrador", T = "(Plaza de prueba de Nácara: esta charla no cuenta para la historia ni da premios.)" },
		{ S = "Ilun", T = "¡Eh, tú, el de las burbujas! Sí, tú. Bienvenido a Nácara, seco." },
		{ S = "Ilun", T = "Tranquilo, «seco» no es un insulto: así llamamos a los que venís de arriba. Yo soy Ilun, de los Faroleros." },
		{ S = "Ilun", T = "Los Faroleros cuidamos las perlas-farola. Si se apagan, lo hondo se come la ciudad." },
		{
			Ask = "¿Qué le dices?",
			Options = {
				{ T = "¿Qué es este sitio?", Then = {
					{ S = "Ilun", T = "La Plaza de la Corriente. El agua sube por esa columna de luz y se lleva los cantos hasta arriba." },
					{ S = "Ilun", T = "Las torres son coral de luz: lo cultivamos con la forma que queremos. Tardan años en crecer… y mi abuela dice que yo, más." },
				} },
				{ T = "¿Puedo respirar aquí abajo?", Then = {
					{ S = "Ilun", T = "En la Lonja Honda, la cúpula grande. Dentro hay aire de verdad: se anda, se respira y se te llena la botella." },
					{ S = "Ilun", T = "Fuera, con tu botella aguantas. Pero no bajes al cañón sin mirar el aire: allí abajo no hay cúpulas." },
				} },
				{ T = "¿Por qué no os conoce nadie en Valmar?", Then = {
					{ S = "Ilun", T = "Hace mucho comerciábamos con los pescadores. Luego el faro se apagó y muchos de los nuestros pensaron que nos habíais olvidado." },
					{ S = "Ilun", T = "Yo no lo creo. Si no, ¿qué haces tú aquí?" },
				} },
			},
		},
		{ S = "Ilun", T = "Esto todavía es una plaza de prueba. Cuando la ciudad esté lista, te la enseño entera. ¡Palabra de farolero!" },
	},
	Oriana = {
		{ S = "Narrador", T = "(Plaza de prueba de Nácara: la lonja todavía no vende nada de verdad.)" },
		{ S = "Oriana", T = "Bienvenido a la Lonja Honda. Pan de kelp, perlas-farola, hilo de nácar… lo mejor de lo hondo." },
		{
			Ask = "¿Qué quieres?",
			Options = {
				{ T = "Ver lo que vendes", Then = {
					{ S = "Oriana", T = "Hoy solo se mira: la lonja abre de verdad más adelante. Pero fíjate en esta perla… brilla sola toda la noche." },
				} },
				{ T = "¿Qué compráis los hondarios?", Then = {
					{ S = "Oriana", T = "Metal, vidrio y herramientas de tierra. Aquí abajo no hay fuego para fundir, así que un cuchillo vale más que diez perlas." },
				} },
				{ T = "¿Por qué atiendes desde fuera?", Then = {
					{ S = "Oriana", T = "Porque yo respiro agua y tú aire. La membrana nos deja hablar sin que ninguno se ahogue. Buen invento, ¿eh?" },
				} },
				{ T = "Nada, gracias", Then = {} },
			},
		},
		{ S = "Oriana", T = "Vuelve cuando quieras, seco. La cúpula siempre tiene aire." },
	},
}

-- Frases sueltas (bocadillo encima) de la gente de la plaza cuando pasas cerca
Nacara.Barks = {
	Guard = { "Bienvenido a Nácara. Nada de redes en la plaza.", "La Guardia vigila las corrientes. Nada tranquilo.", "¿Un seco? Hacía años que no veía uno." },
	Folk = { "¡Mira, un seco con botella!", "Las perlas de guía llevan a las Ruinas.", "En la cúpula hay aire, si lo necesitas.", "¿Has oído cantar al Coro? Algún día." },
}

-- Puntos de foto para las capturas del dueño (docs/mar/civilizacion-marina.md, Fase 0)
Nacara.PhotoSpots = {
	{ Id = "Fuera40", Name = "Fuera de la plaza, a 40 m", At = { 0, -95, 10 }, Look = { 0, 0, 14 } },
	{ Id = "Cupula", Name = "Dentro de la cúpula de aire", At = { -20, 4, 3 }, Look = { -36, 6, 2.5 } },
	{ Id = "Gente", Name = "Mirando a la gente", At = { 6, -30, 6 }, Look = { 9, -14, 4 } },
	{ Id = "Torres", Name = "Mirando arriba, a las torres", At = { 2, -20, 2 }, Look = { 26, -34, 50 } },
}

return Nacara
