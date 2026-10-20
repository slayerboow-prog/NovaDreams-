-- UmbriaCity: el PLANO del barrio de Las Raíces, en Raíz Honda, la capital de Umbría (docs/planetas/nivalis-umbria.md;
-- diseño: docs/planetas/diseno-mundos.md §3.5). Hecho con el marco común (shared/Cosmos/PlanetCity.new):
-- el barrio más antiguo de la ciudad, al pie del Árbol Madre (el tronco gigante que se ve al norte y
-- sube hasta perderse en la niebla). Casas talladas en tocones, vainas que cuelgan de los arcos de las
-- raíces, setas que brillan, el Tronco Mayor (ayuntamiento), el herbolario, la Flor del Mirador
-- (hospital), el taller de planeadores, el Vivero y la vaina de Nía.
--
-- Coordenadas LOCALES de Umbría (X = este, Z = sur; el norte, −Z, mira al Árbol Madre).
--
--                       N  (EL ÁRBOL MADRE: tronco de 120 studs que sube hasta la niebla)
--      ┌───── empalizada de raíces ──── Puerta del Árbol ──── torre de vigía ┐
--      │ TRONCO MAYOR (ayuntamiento)  tocón   tocón        TALLER DE PLANEADORES│
--      │ tocón              🛬 CLARO DEL ASCENSOR                  FLOR DEL MIRADOR │ Puerta
--  Puerta  HERBOLARIO           (raíces en arco por encima)           (hospital)  │  Este
--      │ ~ sima         seta ·  PLAZA DE LAS RAÍCES  · seta               tocón   │
--      │ EL VIVERO          tocón     barricadas      VAINA DE NÍA               │
--      └──────────────────── Puerta Sur (frente del Vivero) ───────────────────┘
--
-- Todas las claves empiezan por «Umbria_». Nada se guarda nuevo en la partida.

local PlanetCity = require(script.Parent.PlanetCity)

local rgb = Color3.fromRGB

local P = {}

P.Id = "RaizHonda"
P.Name = "Raíz Honda"
P.Planet = "Umbria"
P.KeyPrefix = "Umbria_"
P.Rect = { X0 = -136, X1 = 136, Z0 = -126, Z1 = 126 }
P.Blend = 140
P.OpenGround = true -- (la tierra mullida de entre las raíces: se anda por todo lo que no es edificio)
P.Arrival = { 0, 30 }

-- Suelos: tablones de madera vieja, la plaza de corteza y los senderos de musgo
P.Floors = {
	{ Id = "ClaroAscensor", Kind = "Disc", X = 0, Z = 0, R = 50, Material = Enum.Material.WoodPlanks, Color = rgb(96, 70, 48) },
	{ Id = "PlazaRaices", Kind = "Disc", X = 0, Z = 76, R = 36, Material = Enum.Material.Wood, Color = rgb(84, 62, 44) },
	{ Id = "SenderoNorte", Kind = "Rect", X0 = -10, X1 = 10, Z0 = -126, Z1 = -50, Material = Enum.Material.Pebble, Color = rgb(70, 78, 56) },
	{ Id = "SenderoSur", Kind = "Rect", X0 = -10, X1 = 10, Z0 = 112, Z1 = 126, Material = Enum.Material.Pebble, Color = rgb(70, 78, 56) },
	{ Id = "SenderoEste", Kind = "Rect", X0 = 50, X1 = 136, Z0 = 28, Z1 = 46, Material = Enum.Material.Pebble, Color = rgb(70, 78, 56) },
	{ Id = "SenderoOeste", Kind = "Rect", X0 = -136, X1 = -50, Z0 = 4, Z1 = 20, Material = Enum.Material.Pebble, Color = rgb(70, 78, 56) },
}

-- La sima entre las raíces (si caes, sales a la orilla)
P.Pits = {
	{ Kind = "Disc", X = -100, Z = 75, R = 9, Depth = 28, Name = "La sima de las raíces", Text = "Caes entre las raíces… y una liana te sube a la orilla." },
}

P.Districts = {
	{ Id = "Raices", Name = "Las Raíces", Theme = "Raices", Icon = "🌳", Color = rgb(130, 170, 90), Poly = { { -136, -126 }, { 136, -126 }, { 136, 40 }, { -136, 40 } } },
	{ Id = "Vivero", Name = "El Vivero", Theme = "Vivero", Icon = "🌱", Color = rgb(200, 190, 90), Poly = { { -136, 40 }, { 136, 40 }, { 136, 126 }, { -136, 126 } } },
}

local B = {
	-- Los que se pueden visitar por dentro (madera tallada dentro de las raíces)
	{ Id = "Ayuntamiento", District = "Raices", Shape = "Box", Name = "Tronco Mayor · Ayuntamiento", X = -84, Z = -70, W = 28, D = 22, Face = "E", Floors = 2, Style = "UmbriaCorteza", Ground = "Lobby",
		Sign = "TRONCO MAYOR", Icon = "🏛", Info = "El ayuntamiento de Raíz Honda, tallado en una raíz del Árbol Madre. Ahora es el cuartel de la defensa." },
	{ Id = "Herbolario", District = "Vivero", Shape = "Box", Name = "Herbolario de savias", X = -90, Z = 40, W = 22, D = 16, Face = "E", Floors = 1, Style = "UmbriaCorteza", Ground = "Shop",
		Sign = "HERBOLARIO", ShopId = "UmbriaSavia", Icon = "🌿", Info = "Ungüentos de savia ámbar, hojas para mascarilla y raíces que curan casi todo." },
	{ Id = "Hospital", District = "Raices", Shape = "Box", Name = "Flor del Mirador · Hospital", X = 92, Z = 10, W = 26, D = 22, Face = "W", Floors = 2, Style = "UmbriaFlor", Ground = "Lobby",
		Sign = "FLOR DEL MIRADOR", Icon = "🌸", Info = "El hospital y el último refugio. Sus pétalos se cierran cuando caen las esporas." },
	{ Id = "Taller", District = "Raices", Shape = "Box", Name = "Taller de planeadores", X = 86, Z = -80, W = 24, D = 18, Face = "W", Floors = 1, Style = "UmbriaCorteza", Ground = "Lobby",
		Sign = "GREMIO DE PLANEADORES", Icon = "🪂", Info = "Alas de seda de liana y madera de hierro. Desde aquí se evacúa a la gente de abajo." },
	{ Id = "VainaNia", District = "Vivero", Shape = "Box", Name = "La vaina de Nía", X = 70, Z = 96, W = 16, D = 14, Face = "N", Floors = 1, Style = "UmbriaFlor", Ground = "House",
		Icon = "🏠", Info = "Una vaina redonda con una semilla plantada en la puerta. Dentro se oye un zumbido raro." },
	-- Casas talladas en tocones (con puerta redonda y setas en el tejado)
	{ Id = "ToconA", District = "Raices", Shape = "Tocon", Name = "Casa-tocón", X = -40, Z = -96, R = 9, Height = 20 },
	{ Id = "ToconB", District = "Raices", Shape = "Tocon", Name = "Casa-tocón", X = 40, Z = -100, R = 9, Height = 22 },
	{ Id = "ToconC", District = "Raices", Shape = "Tocon", Name = "Casa-tocón", X = -110, Z = -10, R = 9, Height = 18 },
	{ Id = "ToconD", District = "Vivero", Shape = "Tocon", Name = "Casa-tocón", X = -40, Z = 104, R = 9, Height = 19 },
	{ Id = "ToconE", District = "Vivero", Shape = "Tocon", Name = "Casa-tocón", X = 110, Z = 70, R = 9, Height = 21 },
	-- Las setas gigantes de la plaza (sombrillas que brillan) y el Vivero
	{ Id = "SetaOeste", District = "Vivero", Shape = "SetaGigante", Name = "Seta sombrilla", X = -34, Z = 72, R = 4, Height = 30, Icon = "🍄",
		Info = "Una seta sombrilla del tamaño de una casa. Si caes encima, rebotas. Los niños lo saben." },
	{ Id = "SetaEste", District = "Vivero", Shape = "SetaGigante", Name = "Seta sombrilla", X = 34, Z = 72, R = 4, Height = 26 },
	{ Id = "Vivero", District = "Vivero", Shape = "Vivero", Name = "El Vivero", X = -90, Z = 100, W = 24, D = 16, Face = "N", Height = 14, Icon = "🌱",
		Info = "Semilleros y granjas. Cada nacimiento planta una semilla aquí. Es la primera línea del frente." },
	{ Id = "Vigia", District = "Raices", Shape = "Vigia", Name = "Torre de vigía", X = 118, Z = -108, R = 5, Height = 36, Icon = "🔭",
		Info = "Desde lo alto se ve venir el Enjambre: primero el zumbido, luego el brillo plateado." },
}
P.Buildings = B

-- Lo que dibuja el kit sin ser un edificio del plano (World/UmbriaKit.extras): la empalizada de raíces,
-- los arcos de raíz que cruzan el barrio por encima, las vainas colgantes y las barricadas del Vivero
local D = {}
local function fence(id: string, x0: number, x1: number, z0: number, z1: number)
	table.insert(D, { Id = id, Shape = "Empalizada", X = (x0 + x1) / 2, Z = (z0 + z1) / 2, W = x1 - x0, D = z1 - z0, Face = "N", Height = 14 })
end
fence("EmpalizadaNO", -133, -16, -124, -118)
fence("EmpalizadaNE", 16, 108, -124, -118)
fence("EmpalizadaSO", -133, -16, 118, 124)
fence("EmpalizadaSE", 16, 133, 118, 124)
fence("EmpalizadaON", -134, -128, -118, -12)
fence("EmpalizadaOS", -134, -128, 12, 118)
fence("EmpalizadaEN", 128, 134, -100, 24)
fence("EmpalizadaES", 128, 134, 50, 118)
for i, a in { { -70, -30, 70, -30, 46 }, { -120, 60, -40, -40, 38 }, { 40, -60, 120, 60, 42 } } do
	table.insert(D, { Id = "ArcoRaiz" .. i, Shape = "ArcoRaiz", X0 = a[1], Z0 = a[2], X1 = a[3], Z1 = a[4], Height = a[5] })
end
for i, v in { { -46, -30 }, { 0, -30 }, { 48, -30 }, { -80, 10 }, { 80, 0 } } do
	table.insert(D, { Id = "Vaina" .. i, Shape = "VainaColgante", X = v[1], Z = v[2], Height = 30 + (i % 3) * 4 })
end
for i, x in { -26, 26 } do
	table.insert(D, { Id = "Barricada" .. i, Shape = "Barricada", X = x, Z = 112, W = 20, D = 3, Face = "N", Height = 6 })
end
for _, d in D do
	d.Id = "Umbria_" .. d.Id
end
P.Decor = D

P.Gates = {
	{ Id = "Norte", X = 0, Z = -121, Dir = { 0, -1 } },
	{ Id = "Sur", X = 0, Z = 121, Dir = { 0, 1 } },
	{ Id = "Oeste", X = -131, Z = 0, Dir = { -1, 0 } },
	{ Id = "Este", X = 131, Z = 37, Dir = { 1, 0 } },
}

-- Refugios (sellados contra las esporas: Cool = cuánto bajan por segundo)
P.Shelters = {
	Hospital = { Cool = 7, Name = "la Flor del Mirador" },
	Ayuntamiento = { Cool = 5, Name = "el Tronco Mayor" },
	Herbolario = { Cool = 4, Name = "el herbolario" },
	VainaNia = { Cool = 4, Name = "la vaina de Nía" },
}

local function spot(id: string, name: string, x: number, z: number, extra: { [string]: any }?): { [string]: any }
	local s: { [string]: any } = { Id = id, Name = name, X = x, Z = z }
	for k, v in extra or {} do
		s[k] = v
	end
	return s
end

P.StorySpots = {
	spot("Plataforma", "Claro del Ascensor (la plataforma)", 10, 22),
	spot("Raices", "Plaza de las Raíces", 0, 56),
	spot("PuertaNorte", "Puerta del Árbol", 0, -108),
	spot("PuertaSur", "Puerta Sur (frente del Vivero)", 0, 104),
	spot("ArbolMadre", "Al pie del Árbol Madre", -16, -110),
	spot("Ayuntamiento", "Puerta del Tronco Mayor", -64, -70),
	spot("AyuntamientoDentro", "Despacho de la alcaldesa (Tronco Mayor)", -86, -70, { Inside = "Umbria_Ayuntamiento" }),
	spot("Herbolario", "Puerta del herbolario", -74, 40),
	spot("Hospital", "Puerta de la Flor del Mirador", 74, 10),
	spot("HospitalDentro", "Dentro de la Flor del Mirador", 92, 10, { Inside = "Umbria_Hospital" }),
	spot("Taller", "Taller de planeadores", 68, -80),
	spot("Vivero", "Delante del Vivero", -90, 86),
	spot("Barricada1", "Hueco oeste de la barricada", -44, 108),
	spot("Barricada2", "Hueco del centro de la barricada", 0, 114),
	spot("Barricada3", "Hueco este de la barricada", 44, 108),
	spot("VainaNia", "Puerta de la vaina de Nía", 70, 84),
	spot("VainaNiaDentro", "Dentro de la vaina de Nía", 70, 97, { Inside = "Umbria_VainaNia" }),
	spot("SueloHondo", "El Suelo Hondo (bosque de setas)", -300, 240, { Outside = true }),
	spot("ClaroMuerto", "El Claro Muerto", 340, -300, { Outside = true }),
}

-- El material del planeta: savia ámbar (al pie del Árbol Madre) y seda de liana
P.Gather = {
	{ Id = "Umbria_SaviaArbol", Name = "Savia ámbar", X = -30, Z = -112, Item = "SaviaAmbar", Every = 60, Text = "+1 savia ámbar (pega como la miel y cura como la medicina)" },
	{ Id = "Umbria_SaviaVivero", Name = "Savia ámbar", X = -116, Z = 104, Item = "SaviaAmbar", Every = 75, Text = "+1 savia ámbar" },
	{ Id = "Umbria_SedaLiana", Name = "Seda de liana", X = 118, Z = 54, Item = "SedaLiana", Every = 90, Text = "+1 seda de liana (una cuerda que no pesa nada)" },
}

-- Farolillos de seta (StreetLamp: se encienden de noche) y gente
P.Lamps = {
	{ X = -30, Z = 50 }, { X = 30, Z = 50 }, { X = -22, Z = 104 }, { X = 22, Z = 104 }, { X = 0, Z = 40 },
	{ X = -54, Z = -20 }, { X = 54, Z = -20 }, { X = -54, Z = 26 }, { X = 54, Z = 24 },
	{ X = -16, Z = -100 }, { X = 16, Z = -100 }, { X = 112, Z = 30 }, { X = -112, Z = 24 }, { X = 54, Z = 80 },
}
P.Crowd = {
	{ Group = "Plaza", X = -20, Z = 66, FX = 0, FZ = 76 }, { Group = "Plaza", X = 20, Z = 66, FX = 0, FZ = 76 },
	{ Group = "Plaza", X = -12, Z = 92, FX = 0, FZ = 76 }, { Group = "Plaza", X = 12, Z = 92, FX = 0, FZ = 76 },
	{ Group = "Vivero", X = -90, Z = 82, FX = -90, FZ = 100, Work = "Jardinero" }, { Group = "Vivero", X = -70, Z = 112, FX = -90, FZ = 100, Work = "Jardinero" },
	{ Group = "Defensa", X = -14, Z = 110, FX = 0, FZ = 126, Work = "Guardia" }, { Group = "Defensa", X = 14, Z = 110, FX = 0, FZ = 126, Work = "Guardia" },
	{ Group = "Claro", X = -36, Z = 30, FX = 0, FZ = 0 }, { Group = "Claro", X = 36, Z = -30, FX = 0, FZ = 0 },
	{ Group = "Gremio", X = 66, Z = -70, FX = 77, FZ = -80, Work = "Mecanico" }, { Group = "Hospital", X = 70, Z = 20, FX = 81, FZ = 10 },
}
P.Benches = { { X = -26, Z = 88, Yaw = math.pi * 0.25 }, { X = 26, Z = 88, Yaw = -math.pi * 0.25 } }
P.Areas = { { X0 = -36, X1 = 36, Z0 = 44, Z1 = 108 }, { X0 = -44, X1 = 44, Z0 = -44, Z1 = 40 } }

-- El oficio: el tablón del podador (junto al Tronco Mayor), los árboles enfermos y los cubos de savia
P.Jobs = {
	BoardPodador = { -60, -44 },
	Arboles = { { -120, -110 }, { 120, -40 }, { -60, 20 }, { 50, -46 }, { -120, 112 }, { 120, 108 }, { 16, -112 }, { -60, 60 } },
	Cubos = { { -70, 50 }, { -60, -60 }, { 60, 30 } },
}

-- El tiempo: lluvia torrencial por la mañana (9:00–10:00) y lluvia de esporas al anochecer (18:00–21:00)
function P.rain(clock: number): boolean
	return clock >= 9 and clock < 10
end
function P.spores(clock: number): boolean
	return clock >= 18 and clock < 21
end
function P.night(clock: number): boolean
	return clock >= 21 or clock < 6
end
function P.Weather(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
	if P.rain(clock) then
		return { Id = "Lluvia", Name = "Lluvia torrencial", Icon = "lluvia", Temp = 24 }
	elseif P.spores(clock) then
		return { Id = "Esporas", Name = "Lluvia de esporas", Icon = "niebla", Temp = 26 }
	end
	local day = math.sin((clock - 8) / 24 * math.pi * 2)
	return { Id = "Penumbra", Name = if P.night(clock) then "Noche de luciérnagas" else "Penumbra dorada", Icon = "niebla", Temp = math.floor(27 + 3 * day + 0.5) }
end

return PlanetCity.new(P)
