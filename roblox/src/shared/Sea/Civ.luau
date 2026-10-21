-- Civ: la civilización de los Hondarios, FASE 1 (docs/mar/civilizacion-marina.md, «Fase 1 · Primer
-- contacto», recortada a ~1 h de juego por el dueño). Solo datos y cuentas puras (se prueba con Lune):
-- la usan World/NacaraCityBuilder (construye), Services/SeaCivService (gente, rutinas, charlas, casas,
-- historia), Services/MarJobService (oficios), Services/HondarioService (la vida hondaria de pruebas),
-- shared/Sea/Nacara (las cúpulas con aire: dentro se anda) y las pruebas (test-nacara, test-hondario).
--
-- Lo que hay (todo en el mar de siempre, ENCIMA del fondo, sin tocar puertos, playas, el Cañón de Dorada,
-- los jardines de coral ni el territorio del megalodón):
--   * NÁCARA (Llanura Sumergida, 37 m): la plaza de la fase 0 en el centro y, alrededor, el Barrio de las
--     Conchas (6 conchas de alquiler con aire dentro), los Jardines de Cultivo (bancales de algas), la
--     Concha del Consejo (Maresa) y el Paseo de las Perlas-farola.
--   * LA BURBUJA (Talud del Naufragio, ~20 m): la posada de los secos (cúpula con aire, dos camas) y el
--     puesto de Bartolo, el desguacero.
-- Coordenadas: las de Nácara van en coordenadas de la plaza (Nacara.toWorld: X al este, Z al sur, Y sobre
-- el suelo de la plaza, Nacara.FloorY); las de La Burbuja, en el mundo.

local Nacara = require(script.Parent.Nacara)
local Ocean = require(script.Parent.Ocean)

local Civ = {}

local rgb = Color3.fromRGB
local sqrt = math.sqrt

Civ.Phase = 1
Civ.Budget = 1500 -- piezas del servidor de la fase 1 (barrios nuevos + su gente; la plaza tiene las suyas)
Civ.PeopleReserve = 260
Civ.MaxLights = 6

---------------------------------------------------------------------
-- Barrios (los dos de la fase 1). Safe = los barrios donde un hondario no nota la presión.
---------------------------------------------------------------------
Civ.Districts = {
	{ Id = "Nacara", Name = "Nácara", Sub = "la capital de los Hondarios", X = Nacara.Center.X, Z = Nacara.Center.Z, R = 235, Safe = true, Icon = "🐚" },
	{ Id = "Burbuja", Name = "La Burbuja", Sub = "la posada de los secos", X = -960, Z = 4040, R = 70, Safe = true, Icon = "🫧" },
}
Civ.DistrictById = {}
for _, d in Civ.Districts do
	Civ.DistrictById[d.Id] = d
end

-- Zonas dentro de Nácara (coordenadas de la plaza). La plaza es la de la fase 0 (Nacara.Layout).
Civ.Areas = {
	{ Id = "Plaza", Name = "Plaza de la Corriente", X = 0, Z = 0, R = Nacara.Clear },
	{ Id = "Conchas", Name = "Barrio de las Conchas", X = -168, Z = 14, R = 50 },
	{ Id = "Jardines", Name = "Jardines de Cultivo", X = 162, Z = -18, R = 46 },
	{ Id = "Consejo", Name = "Concha del Consejo", X = -78, Z = -152, R = 32 },
}
Civ.AreaById = {}
for _, a in Civ.Areas do
	Civ.AreaById[a.Id] = a
end

---------------------------------------------------------------------
-- Viviendas: «conchas» de alquiler barato (§3.3). Claves PROPIAS del mar, que Valmar no usa nunca
-- (Migrations/BuildingKeyMap: Casa_, Villa_, Portal_, Local_…): MarCasa_<barrio>_<n>. Dentro hay aire,
-- suelo seco y una hamaca de kelp (cama de verdad: SleepService, etiqueta PublicBed).
---------------------------------------------------------------------
Civ.HomePrefix = { Casa = "MarCasa_", Piso = "MarPiso_", Local = "MarLocal_" }
Civ.Rent = 25 -- € por alquilar una concha (una vez; se puede cambiar de concha)
Civ.HomeAir = 7.5 -- radio del aire dentro de una concha
Civ.Homes = {}
do
	local a = Civ.AreaById.Conchas
	for i = 1, 6 do
		local ang = (i - 1) / 6 * math.pi * 2 + 0.35
		table.insert(Civ.Homes, {
			Key = ("MarCasa_Nacara_%d"):format(i),
			District = "Nacara",
			Name = ("Concha %d · Barrio de las Conchas"):format(i),
			X = a.X + math.cos(ang) * 31,
			Z = a.Z + math.sin(ang) * 31,
			Air = Civ.HomeAir,
			Color = ({ rgb(255, 170, 210), rgb(150, 220, 255), rgb(200, 160, 255), rgb(255, 200, 150), rgb(150, 240, 200), rgb(255, 230, 150) })[i],
		})
	end
end
-- La posada de La Burbuja (dos camas para los secos; se alquilan igual)
Civ.Posada = { X = -960, Z = 4040, Radius = 15, Air = 13.5 }
for i = 1, 2 do
	table.insert(Civ.Homes, {
		Key = ("MarCasa_Burbuja_%d"):format(i),
		District = "Burbuja",
		Name = ("Cama %d · Posada de La Burbuja"):format(i),
		World = true,
		X = Civ.Posada.X + (if i == 1 then -6 else 6),
		Z = Civ.Posada.Z - 6,
		Air = 0, -- (el aire es el de la posada)
	})
end
Civ.HomeByKey = {}
for _, h in Civ.Homes do
	Civ.HomeByKey[h.Key] = h
end
Civ.DefaultHome = "MarCasa_Nacara_1" -- la de la vida hondaria de pruebas

function Civ.isMarKey(key: any): boolean
	if type(key) ~= "string" then
		return false
	end
	for _, prefix in Civ.HomePrefix do
		if string.sub(key, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Cuentas de posición
---------------------------------------------------------------------
-- Suelo de La Burbuja: el del talud en su centro (se allana un poco alrededor)
function Civ.burbujaFloorY(): number
	return Ocean.floorY(Civ.Posada.X, Civ.Posada.Z) or (Ocean.Surface - 20 * Ocean.StudsPerMeter)
end

-- Dónde está una vivienda (los pies, sobre el suelo seco)
function Civ.homePosition(home: { [string]: any }): Vector3
	if home.World then
		return Vector3.new(home.X, Civ.burbujaFloorY() + 1.2, home.Z)
	end
	return Nacara.toWorld(home.X, home.Z, 1.2)
end

-- La cama (hamaca) de una vivienda: el punto para aparecer
function Civ.bedPosition(home: { [string]: any }): Vector3
	return Civ.homePosition(home) + Vector3.new(0, 2.6, 0)
end

-- ¿En qué barrio estás? (nil = fuera)
function Civ.districtAt(pos: Vector3): { [string]: any }?
	for _, d in Civ.Districts do
		local dx, dz = pos.X - d.X, pos.Z - d.Z
		if dx * dx + dz * dz < d.R * d.R and pos.Y < Ocean.Surface then
			return d
		end
	end
	return nil
end

-- Las bolsas de aire de la fase 1 (las conchas y la posada): { Center, Radius }
local pockets: { { Center: Vector3, Radius: number } }? = nil
function Civ.airPockets(): { { Center: Vector3, Radius: number } }
	if pockets then
		return pockets
	end
	local list = {}
	for _, h in Civ.Homes do
		if (h.Air or 0) > 0 then
			table.insert(list, { Center = Civ.homePosition(h) - Vector3.new(0, 1.2, 0), Radius = h.Air })
		end
	end
	table.insert(list, { Center = Vector3.new(Civ.Posada.X, Civ.burbujaFloorY(), Civ.Posada.Z), Radius = Civ.Posada.Air })
	pockets = list
	return list
end

-- ¿Dentro del aire de una concha o de la posada? (como Nacara.inDome: se anda y se respira)
function Civ.inAir(pos: Vector3, margin: number?): boolean
	for _, p in Civ.airPockets() do
		if pos.Y >= p.Center.Y - 2 and (pos - p.Center).Magnitude < p.Radius - (margin or 1.2) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- La gente nueva de la fase 1 (Hondarios; siempre vestidos). Coordenadas de la plaza salvo World = true.
-- Routine = { { From, To, Spot = { x, z, y } } } por horas del juego (GameClock): el servidor los cambia de
-- sitio solo cuando no hay nadie mirando cerca (sin teletransportes delante de ti).
---------------------------------------------------------------------
Civ.People = {
	{ Id = "Maresa", Name = "Maresa", Title = "Guardiana de la Marea", Role = "Quest", X = -78, Z = -150, Y = 6.5,
		Face = { -78, -120 },
		Look = { Skin = rgb(141, 85, 36), Scales = rgb(40, 60, 110), Tunic = rgb(30, 40, 80), Crest = rgb(230, 230, 255), Hair = rgb(200, 200, 210) },
		Routine = { { From = 6, To = 22, Spot = { -78, -150, 6.5 } }, { From = 22, To = 6, Spot = { -60, -146, 5.5 } } } },
	{ Id = "Bartolo", Name = "Bartolo", Title = "desguacero", Role = "Quest", World = true, X = -940, Z = 4064, Y = 5,
		Face = { -960, 4040 },
		Look = { Skin = rgb(224, 172, 105), Scales = rgb(120, 110, 70), Tunic = rgb(90, 70, 40), Crest = rgb(255, 200, 90), Hair = rgb(60, 40, 20) } },
	{ Id = "Tome", Name = "Tomé", Title = "cultivador de algas", Role = "Quest", X = 140, Z = -40, Y = 5.2,
		Face = { 162, -18 },
		Look = { Skin = rgb(198, 134, 66), Scales = rgb(60, 140, 70), Tunic = rgb(50, 90, 50), Crest = rgb(150, 230, 120), Hair = rgb(30, 22, 16) },
		Routine = { { From = 7, To = 20, Spot = { 140, -40, 5.2 } }, { From = 20, To = 7, Spot = { 118, -6, 5.2 } } } },
	{ Id = "Lia", Name = "Lía", Title = "farolera", Role = "Quest", X = 70, Z = -96, Y = 6,
		Face = { 0, 0 },
		Look = { Skin = rgb(255, 219, 172), Scales = rgb(240, 120, 90), Tunic = rgb(130, 60, 50), Crest = rgb(255, 170, 120), Hair = rgb(150, 60, 30) },
		Routine = { { From = 8, To = 18, Spot = { 70, -96, 6 } }, { From = 18, To = 23, Spot = { 104, 92, 6 } }, { From = 23, To = 8, Spot = { -120, 60, 6 } } } },
	{ Id = "GuardiaConsejo", Name = "Guardia del Consejo", Role = "Guard", X = -54, Z = -126, Y = 5,
		Face = { -30, -90 },
		Look = { Skin = rgb(92, 58, 30), Scales = rgb(30, 70, 120), Tunic = rgb(40, 50, 70), Crest = rgb(60, 120, 220), Hair = rgb(20, 20, 22) } },
}
Civ.PersonById = {}
for _, p in Civ.People do
	Civ.PersonById[p.Id] = p
end

-- Dónde está ahora (por la hora del juego, 0–24)
local function inWindow(hour: number, from: number, to: number): boolean
	if from <= to then
		return hour >= from and hour < to
	end
	return hour >= from or hour < to
end
function Civ.spotAt(person: { [string]: any }, hour: number): (number, number, number)
	for _, r in person.Routine or {} do
		if inWindow(hour, r.From, r.To) then
			return r.Spot[1], r.Spot[2], r.Spot[3]
		end
	end
	return person.X, person.Z, person.Y or 5
end

function Civ.personWorld(person: { [string]: any }, x: number, z: number, y: number): Vector3
	if person.World then
		return Vector3.new(x, Civ.burbujaFloorY() + y, z)
	end
	return Nacara.toWorld(x, z, y)
end

---------------------------------------------------------------------
-- Las perlas-farola del Paseo (el oficio de farolero/a las recarga) y los bancales de algas
---------------------------------------------------------------------
Civ.Lamps = {}
for i = 1, 8 do
	local ang = (i - 1) / 8 * math.pi * 2 + 0.2
	local r = if i % 2 == 0 then 96 else 118
	table.insert(Civ.Lamps, { Id = "Farola" .. i, X = math.cos(ang) * r, Z = math.sin(ang) * r * 0.8 - 10 })
end
Civ.Beds = {}
do
	local a = Civ.AreaById.Jardines
	for row = 0, 1 do
		for col = 0, 2 do
			table.insert(Civ.Beds, { Id = ("Bancal%d"):format(#Civ.Beds + 1), X = a.X - 22 + col * 22, Z = a.Z - 11 + row * 22 })
		end
	end
end

-- La cesta de Tomé (los caracoles del oficio de cultivador/a), junto a su tablón
Civ.Basket = { X = 124, Z = -44 }

-- Tablones «Trabajar» de los oficios del mar (coordenadas de la plaza)
Civ.Boards = {
	MarCultivador = { X = 138, Z = -50 },
	MarFarolero = { X = 58, Z = -104 },
}

---------------------------------------------------------------------
-- Sitios de la historia (marcas StorySpot «Mar_…»: shared/LifeStory/Locations). World = coordenadas del
-- mundo; si no, de la plaza. Radius = lo cerca que hay que llegar.
---------------------------------------------------------------------
Civ.StorySpots = {
	{ Id = "Arrecife", Name = "Jardín de coral del sur", World = true, X = Nacara.StartReef.X + 20, Z = Nacara.StartReef.Z + 70, Radius = 22 },
	{ Id = "Ruinas", Name = "Ruinas de Valmar la Vieja", World = true, X = Ocean.PoiById.Ruinas.X + 40, Z = Ocean.PoiById.Ruinas.Z - 40, Radius = 40 },
	{ Id = "Arco", Name = "Arco de entrada de Nácara", X = 0, Z = -60, Radius = 18 },
	{ Id = "Plaza", Name = "Plaza de la Corriente", X = 8, Z = -12, Radius = 30 },
	{ Id = "Consejo", Name = "Concha del Consejo", X = -78, Z = -140, Radius = 22 },
	{ Id = "Conchas", Name = "Barrio de las Conchas", X = -168, Z = 14, Radius = 40 },
	{ Id = "Jardines", Name = "Jardines de Cultivo", X = 150, Z = -30, Radius = 36 },
	{ Id = "KelpNorte", Name = "El bosque de kelp del norte", X = 150, Z = -190, Radius = 20 },
	{ Id = "Burbuja", Name = "La Burbuja · posada de los secos", World = true, X = -960, Z = 4040, Radius = 26 },
}
Civ.SpotById = {}
for _, s in Civ.StorySpots do
	Civ.SpotById[s.Id] = s
end

function Civ.spotPosition(s: { [string]: any }): Vector3
	if s.World then
		local floor = Ocean.floorY(s.X, s.Z) or Nacara.FloorY
		if s.Id == "Burbuja" then
			floor = Civ.burbujaFloorY()
		end
		return Vector3.new(s.X, floor, s.Z)
	end
	return Nacara.toWorld(s.X, s.Z, 0)
end

-- La persecución de «Redes cortadas» (Mar_04): el joven de la Marea Callada huye por el kelp del norte
-- hasta el Barrio de las Conchas. Puntos en coordenadas de la plaza (y = altura sobre el suelo).
Civ.Chase = {
	Npc = "Sargo",
	Speed = 13, -- studs/s (un humano con botella va a ~16; con cola, más: se le alcanza nadando)
	Catch = 9, -- studs: «¡te pillé!»
	Lead = 34, -- si te alejas más que esto, se para a esperarte (para que no se escape del todo)
	Seconds = 150, -- tiempo para alcanzarle; si no, vuelve al principio
	Path = { { 150, -190, 8 }, { 110, -210, 12 }, { 40, -205, 9 }, { -30, -215, 14 }, { -120, -190, 10 }, { -190, -120, 8 }, { -215, -40, 9 }, { -190, 0, 6 } },
	Look = { Skin = rgb(255, 219, 172), Scales = rgb(70, 70, 90), Tunic = rgb(40, 40, 50), Crest = rgb(130, 130, 160), Hair = rgb(20, 20, 22) },
}

-- Punto de la persecución a una distancia d del principio (en studs del camino)
function Civ.chaseLength(): number
	local total = 0
	local P = Civ.Chase.Path
	for i = 1, #P - 1 do
		total += sqrt((P[i + 1][1] - P[i][1]) ^ 2 + (P[i + 1][2] - P[i][2]) ^ 2)
	end
	return total
end
function Civ.chasePoint(d: number): (Vector3, Vector3)
	local P = Civ.Chase.Path
	local left = math.max(0, d)
	for i = 1, #P - 1 do
		local a, b = P[i], P[i + 1]
		local len = sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		if left <= len or i == #P - 1 then
			local t = math.clamp(left / len, 0, 1)
			local pa, pb = Nacara.toWorld(a[1], a[2], a[3]), Nacara.toWorld(b[1], b[2], b[3])
			return pa:Lerp(pb, t), (pb - pa).Unit
		end
		left -= len
	end
	local last = P[#P]
	return Nacara.toWorld(last[1], last[2], last[3]), Vector3.new(0, 0, 1)
end

-- Las perlas que perdió Oriana (secundaria «Las perlas de Oriana»), en coordenadas de la plaza
Civ.LostPearls = { { 36, 56, 1.5 }, { -66, 40, 1.5 }, { 92, 28, 1.5 } }

-- Las conchas del trueque con Bartolo (Mar_02): por el suelo de La Burbuja (mundo, relativas al centro)
Civ.TradeShells = { { -18, 14 }, { 22, 18 }, { 4, -24 } }

-- Puntos de foto para las capturas del dueño (fase 1)
Civ.PhotoSpots = {
	{ Id = "Conchas", Name = "Barrio de las Conchas", At = { -130, -10, 10 }, Look = { -168, 14, 4 } },
	{ Id = "Jardines", Name = "Jardines de Cultivo", At = { 120, -40, 10 }, Look = { 162, -18, 2 } },
	{ Id = "Consejo", Name = "Concha del Consejo", At = { -40, -110, 10 }, Look = { -78, -152, 10 } },
}

return Civ
