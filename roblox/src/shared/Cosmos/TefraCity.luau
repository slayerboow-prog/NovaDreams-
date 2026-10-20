-- TefraCity: el PLANO de Bastión Ceniza, la ciudad de Tefra (docs/planetas/tefra-ciudad.md y
-- docs/planetas/diseno-mundos.md §3.1). Cuentas puras, como shared/CityPlan para Valmar: de aquí salen el
-- terreno de la meseta (shared/Cosmos/Tefra.heightAt), lo que se construye (World/TefraCityBuilder), el
-- minimapa (Controllers/MapUI), los choques de la nave con los edificios, dónde se puede posar, la lava
-- que quema y el tiempo del reloj en Tefra (UI/Hud).
--
-- Coordenadas LOCALES de Tefra (lx, lz: studs desde Tefra.Origin; X = este, Z = sur, el norte es −Z).
-- La plataforma de aterrizaje de siempre (0, 0) queda en el centro del Muelle Bastión: llegas a la ciudad.
-- Altura: la ciudad está sobre una MESETA llana a la altura de la plataforma (Base = Tefra.padY(), la
-- pasa quien llama); las calles y edificios se construyen con su suelo en Base (como Valmar en Y = 0).
--
--                      N (−Z)   ·  Baliza de señal (fuera)
--      ┌──────────── LA MURALLA (anillo con torres) · foso de lava ────────────┐
--      │ BARRIO DEL OVILLO        │ MUELLE BASTIÓN │ MIRADOR DE LAS LUNAS │  ~ Lago de Ceniza
--      │ (cúpulas, casa de Cosme) │  (astillero)   │ (estatua de Nilda)   │
--      │ MERCADO ESPIRAL          │  🛬 plataforma │ CAMPUS NILDA         │ → Puerta Este (Ruinas)
--      │ (bloques del refugio)    │                │ (hospital de campaña)│
--      │ LAS FUNDICIONES          │ LOS POZOS DE MAGMA (central, la Lanza)│
--      │ ~~~~~~~~~~~~~~~~ Canal de la Forja (lava, puentes de hierro) ~~~~~ │
--      │ LA MURALLA (cuartel) │ FUNDICIONES (viviendas, cremallera) │ POZOS │
--      └────────────────────────────────────────────────────────────────────┘
--
-- Las claves (Id) de todo lo de aquí empiezan por «Tefra_»: nunca coinciden con las de Valmar
-- (Casa_x_z, Portal_…, los locales de BusinessService) ni las migra Migrations/BuildingKeyMigration.
-- De momento nada se compra ni se alquila (fase siguiente: docs/planetas/tefra-ciudad.md).

local TefraCity = {}

TefraCity.Id = "BastionCeniza"
TefraCity.Name = "Bastión Ceniza"
TefraCity.KeyPrefix = "Tefra_"

-- Dentro de la muralla (local). Las calles de la ronda van a 20 studs del borde: su acera llega al muro.
TefraCity.Rect = { X0 = -420, X1 = 260, Z0 = -260, Z1 = 420 }
TefraCity.WallThick = 6 -- la muralla (de 0 a 6 studs fuera del borde)
TefraCity.MoatOut = 30 -- el foso de lava (de 6 a 30)
TefraCity.Bank = 38 -- la orilla de fuera, llana (de 30 a 38)
TefraCity.Blend = 130 -- de 38 a 130 el suelo baja (o sube) poco a poco hasta el del planeta
TefraCity.GroundDrop = 0.6 -- el terreno de la ciudad queda justo por debajo de calles y losas
TefraCity.LavaDepth = 12 -- el fondo de los canales y del foso (studs bajo Base)
TefraCity.LavaTop = 9.5 -- la lava que se ve (studs bajo Base)
TefraCity.WallHeight = 16
TefraCity.RoadHalf = 20 -- del centro de una calle al borde de su acera (Kit/Street.HALF)
TefraCity.GateHalf = 21 -- media anchura del hueco de cada puerta en la muralla (calzada + aceras)

-- Calles (como Kit/Street: Axis "X" corre de oeste a este en z = At; Axis "Z" de norte a sur en x = At).
-- NoSignals: sin semáforos (en Tefra no circulan coches). Las cuatro que salen por las puertas pasan
-- por encima del foso (la calzada es el puente).
TefraCity.Streets = {
	-- La ronda de la muralla
	{ Name = "Ronda Norte", Axis = "X", At = -240, From = -400, To = 240 },
	{ Name = "Ronda Sur", Axis = "X", At = 400, From = -400, To = 240 },
	{ Name = "Ronda Oeste", Axis = "Z", At = -400, From = -240, To = 400 },
	{ Name = "Ronda Este", Axis = "Z", At = 240, From = -240, To = 400 },
	-- Las de dentro
	{ Name = "Calle de las Cúpulas", Axis = "X", At = -80, From = -460, To = 240 }, -- (sale por la Puerta Oeste)
	{ Name = "Calle de los Refugiados", Axis = "X", At = 80, From = -400, To = 300 }, -- (sale por la Puerta Este)
	{ Name = "Calle del Ovillo", Axis = "Z", At = -240, From = -300, To = 400 }, -- (sale por la Puerta Norte)
	{ Name = "Avenida del Muelle", Axis = "Z", At = -80, From = -240, To = 460 }, -- (sale por la Puerta Sur)
	{ Name = "Calle de la Academia", Axis = "Z", At = 80, From = -240, To = 400 },
}
for _, s in TefraCity.Streets do
	s.NoSignals = true
	s.LampEvery = 40
end

-- Las puertas de la muralla (donde una calle sale y cruza el foso)
TefraCity.Gates = {
	{ Id = "Norte", Name = "Puerta Norte", X = -240, Z = -260, Dir = { 0, -1 } },
	{ Id = "Este", Name = "Puerta Este", X = 260, Z = 80, Dir = { 1, 0 } },
	{ Id = "Sur", Name = "Puerta Sur", X = -80, Z = 420, Dir = { 0, 1 } },
	{ Id = "Oeste", Name = "Puerta Oeste", X = -420, Z = -80, Dir = { -1, 0 } },
}

-- Lava dentro de la ciudad: el Canal de la Forja (de lado a lado, sale al foso por los dos extremos,
-- por debajo de la muralla) y dos pozos redondos (Mercado Espiral y los Pozos de Magma).
TefraCity.Canal = { Z = 240, Half = 12, Walk = 8, Name = "Canal de la Forja" }
TefraCity.Wells = {
	{ Id = "PozoMercado", X = -160, Z = 0, R = 12, Name = "Pozo del Mercado" },
	{ Id = "PozoMagma", X = 0, Z = 285, R = 10, Name = "Pozo de Magma" },
}

-- Las 16 manzanas (4 × 4): centro y lado del interior (120 × 120; las aceras las pone la calle)
TefraCity.BlockHalf = 60
TefraCity.BlockCols = { -320, -160, 0, 160 }
TefraCity.BlockRows = { -160, 0, 160, 320 }

-- Los 8 barrios (diseno-mundos §3.1.7). Poly en coordenadas locales (líneas de las calles).
TefraCity.Districts = {
	{ Id = "Ovillo", Name = "Barrio del Ovillo", Theme = "El casco viejo de cúpulas", Icon = "🏚", Color = { 214, 150, 190 },
		Poly = { { -400, -240 }, { -80, -240 }, { -80, -80 }, { -400, -80 } } },
	{ Id = "Mercado", Name = "Mercado Espiral", Theme = "Mercado negro y bloques del refugio", Icon = "🛒", Color = { 236, 170, 60 },
		Poly = { { -400, -80 }, { -80, -80 }, { -80, 80 }, { -400, 80 } } },
	{ Id = "Muelle", Name = "Muelle Bastión", Theme = "Puerto espacial y base militar", Icon = "🛬", Color = { 120, 140, 160 },
		Poly = { { -80, -240 }, { 80, -240 }, { 80, 80 }, { -80, 80 } } },
	{ Id = "Mirador", Name = "Mirador de las Lunas", Theme = "Plaza, estatua de Nilda y refugiados", Icon = "🔭", Color = { 170, 130, 230 },
		Poly = { { 80, -240 }, { 240, -240 }, { 240, -80 }, { 80, -80 } } },
	{ Id = "Campus", Name = "Campus Nilda", Theme = "Hospital de campaña y baños termales", Icon = "🏥", Color = { 90, 200, 200 },
		Poly = { { 80, -80 }, { 240, -80 }, { 240, 80 }, { 80, 80 } } },
	{ Id = "Fundiciones", Name = "Las Fundiciones", Theme = "Fábricas día y noche", Icon = "🏭", Color = { 230, 96, 50 },
		Poly = { { -400, 80 }, { -80, 80 }, { -80, 400 }, { -240, 400 }, { -240, 240 }, { -400, 240 } } },
	{ Id = "Pozos", Name = "Los Pozos de Magma", Theme = "La central geotérmica (y la Lanza)", Icon = "🌋", Color = { 255, 120, 30 },
		Poly = { { -80, 80 }, { 240, 80 }, { 240, 400 }, { -80, 400 } } },
	{ Id = "Muralla", Name = "La Muralla", Theme = "Cuartel y torres de artillería", Icon = "🎖", Color = { 150, 150, 150 },
		Poly = { { -400, 240 }, { -240, 240 }, { -240, 400 }, { -400, 400 } } },
}
TefraCity.DistrictById = {}
for _, d in TefraCity.Districts do
	TefraCity.DistrictById[d.Id] = d
end

-- Manzanas «abiertas» (plaza o explanada: se anda por todo el suelo; las puertas que dan dentro valen)
TefraCity.OpenBlocks = { ["3,2"] = "Muelle", ["4,1"] = "Mirador", ["4,2"] = "Campus", ["2,2"] = "Mercado", ["3,4"] = "Pozos", ["4,3"] = "Pozos" }

---------------------------------------------------------------------
-- Edificios
--   Shape: "Box" (Kit/Building: planta baja jugable con su puerta en la fachada), "Dome" (cúpula del
--   Tefra antiguo, maciza), "Skeleton" (la casa de Cosme: solo el armazón, se entra andando),
--   "Stall" (puesto del mercado), "Tower" (torre maciza), "Tank" (depósito redondo), "Spire" (la Lanza),
--   "Hangar" (Box enorme con portones), "Greenhouse" (invernadero de cristal), "Court" (explanada).
--   Face: hacia dónde da la fachada (y la puerta): N (−Z), S (+Z), E (+X), W (−X).
--   Ground (Box): como Kit/Building ("Shop", "Lobby", "House", "Closed", "Garage").
--   Height (sin Floors): altura (studs) de las formas que no son Box.
---------------------------------------------------------------------
export type Building = {
	Id: string,
	District: string,
	Kind: string,
	Shape: string,
	Name: string,
	X: number,
	Z: number,
	W: number?,
	D: number?,
	R: number?,
	Face: string?,
	Floors: number?,
	Style: string?,
	Ground: string?,
	Sign: string?,
	ShopId: string?,
	Info: string?,
	Icon: string?,
	Height: number?,
	Broken: boolean?,
	DomeRoof: boolean?,
}

local list: { Building } = {}
local function add(b: Building)
	b.Id = TefraCity.KeyPrefix .. b.Id
	table.insert(list, b)
end

-- Barrio del Ovillo (redondo: lo antiguo)
add({ Id = "Cupula1", District = "Ovillo", Kind = "Vivienda", Shape = "Dome", Name = "Cúpula", X = -350, Z = -190, R = 17 })
add({ Id = "Cupula2", District = "Ovillo", Kind = "Vivienda", Shape = "Dome", Name = "Cúpula", X = -296, Z = -192, R = 15 })
add({ Id = "Cupula3", District = "Ovillo", Kind = "Vivienda", Shape = "Dome", Name = "Cúpula", X = -352, Z = -132, R = 16 })
add({ Id = "Cupula4", District = "Ovillo", Kind = "Ruina", Shape = "Dome", Name = "Cúpula partida", X = -292, Z = -130, R = 14, Broken = true })
add({ Id = "Horno", District = "Ovillo", Kind = "Vivienda", Shape = "Dome", Name = "Horno de barrio", X = -322, Z = -160, R = 8 })
add({ Id = "CasaCosme", District = "Ovillo", Kind = "Ruina", Shape = "Skeleton", Name = "Casa de la familia de Cosme", X = -180, Z = -170, R = 16, Icon = "🔬",
	Info = "🏚 Lo que queda de la casa de la familia de Cosme: el armazón de la cúpula y una mesa de cocina quemada. En el marco de la puerta, rayas de lápiz con alturas: «Cosme, 8 años», «Ada, 6 años»." })
add({ Id = "Cupula5", District = "Ovillo", Kind = "Vivienda", Shape = "Dome", Name = "Cúpula", X = -120, Z = -180, R = 14 })
add({ Id = "Cupula6", District = "Ovillo", Kind = "Ruina", Shape = "Dome", Name = "Cúpula partida", X = -205, Z = -120, R = 12, Broken = true })
add({ Id = "Panaderia", District = "Ovillo", Kind = "Tienda", Shape = "Box", Name = "Panadería del Ovillo", X = -130, Z = -113, W = 30, D = 26, Face = "S", Floors = 1,
	Style = "TefraCupula", Ground = "Shop", Sign = "PANADERÍA DEL OVILLO", ShopId = "TefraPanaderia", Icon = "🥖", DomeRoof = true })

-- Mercado Espiral (y los bloques del refugio)
for i, spec in { { -351, -42, "N" }, { -289, -42, "N" }, { -351, 42, "S" }, { -289, 42, "S" } } do
	add({ Id = "Bloque" .. i, District = "Mercado", Kind = "Vivienda", Shape = "Box", Name = "Bloque del Refugio " .. i, X = spec[1], Z = spec[2], W = 54, D = 36, Face = spec[3], Floors = 4,
		Style = "TefraBunker", Ground = "Lobby", Sign = "BLOQUE " .. i })
end
do
	-- Puestos en espiral alrededor del pozo de lava (de fuera a dentro, mirando al centro)
	local well = TefraCity.Wells[1]
	local n = 14
	for k = 1, n do
		local t = (k - 1) / (n - 1)
		local a = t * math.pi * 3.4 + 0.4
		local r = 52 - t * 22
		local id = if k == 1 then "PuestoNegro" else "Puesto" .. k
		add({ Id = id, District = "Mercado", Kind = "Tienda", Shape = "Stall", Name = if k == 1 then "Puesto de Madre Hollín" else "Puesto del mercado",
			X = well.X + math.cos(a) * r, Z = well.Z + math.sin(a) * r, W = 8, D = 6, Height = 8,
			ShopId = if k == 1 then "TefraMercado" else nil, Icon = if k == 1 then "🛒" else nil })
	end
end

-- Muelle Bastión (militar: esquinas duras)
add({ Id = "Astillero", District = "Muelle", Kind = "Militar", Shape = "Box", Name = "Astillero del Muelle", X = 0, Z = -198, W = 100, D = 44, Face = "N", Floors = 2,
	Style = "TefraBunker", Ground = "Garage", Sign = "ASTILLERO DEL MUELLE", Icon = "🚀" })
add({ Id = "Calabozos", District = "Muelle", Kind = "Militar", Shape = "Box", Name = "Calabozos del Muelle", X = -30, Z = -115, W = 40, D = 30, Face = "S", Floors = 2,
	Style = "TefraBunker", Ground = "Lobby", Sign = "POLICÍA MILITAR", Icon = "⛓" })
add({ Id = "Armeria", District = "Muelle", Kind = "Tienda", Shape = "Box", Name = "Armería del Muelle", X = 30, Z = -115, W = 40, D = 30, Face = "S", Floors = 2,
	Style = "TefraBunker", Ground = "Shop", Sign = "ARMERÍA DEL MUELLE", Icon = "🎯",
	Info = "🎯 Armería del Muelle: «Solo personal con papeles del Ejército». (La armería abrirá con la cadena «Papeles».)" })
add({ Id = "TorreControl", District = "Muelle", Kind = "Militar", Shape = "Box", Name = "Torre de control", X = 46, Z = -46, W = 14, D = 14, Face = "E", Floors = 6,
	Style = "TefraBunker", Ground = "Lobby", Sign = "CONTROL", Icon = "📡" })
add({ Id = "Combustible", District = "Muelle", Kind = "Militar", Shape = "Tank", Name = "Depósito de combustible", X = -46, Z = -46, R = 7, Height = 12 })

-- Mirador de las Lunas (la plaza: Plaza Mayor de Tefra)
add({ Id = "Mirador", District = "Mirador", Kind = "Plaza", Shape = "Court", Name = "Mirador de las Lunas", X = 160, Z = -160, W = 116, D = 116, Icon = "🔭",
	Info = "🔭 El Mirador de las Lunas. Desde la terraza se ve el Lago de Ceniza y, en el cielo, Ovilla. Hoy es un campamento de refugiados." })

-- Campus Nilda
add({ Id = "Hospital", District = "Campus", Kind = "Hospital", Shape = "Box", Name = "Campus Nilda · Hospital de campaña", X = 118, Z = 0, W = 70, D = 36, Face = "W", Floors = 3,
	Style = "TefraCupula", Ground = "Lobby", Sign = "CAMPUS NILDA · HOSPITAL", Icon = "🏥", DomeRoof = true,
	Info = "🏥 La academia que fundó la abuela Nilda. Hoy es hospital de campaña y refugio. En la entrada: «Aquí se cura a todo el mundo»." })
add({ Id = "Termas", District = "Campus", Kind = "Ocio", Shape = "Box", Name = "Baños termales", X = 210, Z = 35, W = 30, D = 20, Face = "E", Floors = 1,
	Style = "TefraCupula", Ground = "Lobby", Sign = "BAÑOS TERMALES", Icon = "♨", DomeRoof = true })
add({ Id = "Sopa", District = "Campus", Kind = "Tienda", Shape = "Stall", Name = "Puesto de sopa", X = 166, Z = 44, W = 10, D = 6, Height = 8, ShopId = "TefraSopa", Icon = "🍲" })

-- Las Fundiciones
add({ Id = "FundicionNorte", District = "Fundiciones", Kind = "Fabrica", Shape = "Box", Name = "Fundición Norte", X = -320, Z = 122, W = 110, D = 44, Face = "N", Floors = 2,
	Style = "TefraFabrica", Ground = "Garage", Sign = "FUNDICIÓN NORTE", Icon = "🏭" })
add({ Id = "FundicionSur", District = "Fundiciones", Kind = "Fabrica", Shape = "Box", Name = "Fundición Sur", X = -320, Z = 198, W = 110, D = 44, Face = "S", Floors = 2,
	Style = "TefraFabrica", Ground = "Garage", Sign = "FUNDICIÓN SUR" })
add({ Id = "Forja", District = "Fundiciones", Kind = "Tienda", Shape = "Box", Name = "Forja de Bastión", X = -190, Z = 118, W = 50, D = 36, Face = "N", Floors = 2,
	Style = "TefraFabrica", Ground = "Shop", Sign = "FORJA DE BASTIÓN", Icon = "⚒",
	Info = "⚒ La forja de Bastión: aquí se refina la obsidiana y se fabrica el equipo contra el calor (gel térmico, trajes refrigerados). Toca «Fabricar» en la puerta." })
add({ Id = "TallerBlindaje", District = "Fundiciones", Kind = "Negocio", Shape = "Box", Name = "Taller de blindaje", X = -130, Z = 202, W = 50, D = 36, Face = "S", Floors = 2,
	Style = "TefraFabrica", Ground = "Garage", Sign = "TALLER DE BLINDAJE", Icon = "🛡",
	Info = "🛡 Taller de blindaje: «Se traspasa». (Comprar negocios en Tefra llega más adelante.)" })
add({ Id = "OficinaTrabajo", District = "Fundiciones", Kind = "Trabajo", Shape = "Box", Name = "Oficina de trabajo", X = -111, Z = 130, W = 22, D = 22, Face = "E", Floors = 1,
	Style = "TefraBunker", Ground = "Lobby", Sign = "TRABAJO", Icon = "💼",
	Info = "💼 Oficina de trabajo: «SE BUSCA: fundidor/a, desactivador/a de munición, bombero/a de coladas, correo de túnel». Los tablones «Trabajar» están en la acera, junto a la puerta." })
add({ Id = "Viviendas", District = "Fundiciones", Kind = "Vivienda", Shape = "Box", Name = "Viviendas obreras", X = -189, Z = 277, W = 54, D = 34, Face = "N", Floors = 4,
	Style = "TefraBunker", Ground = "Lobby", Sign = "VIVIENDAS OBRERAS" })
add({ Id = "Cremallera", District = "Fundiciones", Kind = "Transporte", Shape = "Box", Name = "Estación del Cremallera", X = -130, Z = 365, W = 50, D = 30, Face = "S", Floors = 1,
	Style = "TefraBunker", Ground = "Lobby", Sign = "TREN DE CREMALLERA", Icon = "🚆",
	Info = "🚆 Estación del tren de cremallera blindado. Pizarra: «Hoy no hay servicio (bombardeo en la vía)». (El tren de Tefra llega más adelante.)" })

-- La Muralla
add({ Id = "Cuartel", District = "Muralla", Kind = "Militar", Shape = "Box", Name = "Cuartel de la Muralla", X = -320, Z = 278, W = 100, D = 36, Face = "N", Floors = 2,
	Style = "TefraBunker", Ground = "Lobby", Sign = "CUARTEL DE LA MURALLA", Icon = "🎖" })
add({ Id = "Explanada", District = "Muralla", Kind = "Ocio", Shape = "Court", Name = "Explanada de la pelota de ceniza", X = -320, Z = 345, W = 70, D = 40, Icon = "⚽",
	Info = "⚽ La explanada de la pelota de ceniza: aquí juegan los críos del Mirador cuando no suenan las sirenas. (El partido de 3 contra 3 llega más adelante.)" })

-- Los Pozos de Magma
add({ Id = "Central", District = "Pozos", Kind = "Fabrica", Shape = "Box", Name = "Central de los Pozos", X = 0, Z = 120, W = 100, D = 40, Face = "N", Floors = 2,
	Style = "TefraFabrica", Ground = "Garage", Sign = "CENTRAL GEOTÉRMICA", Icon = "🌋" })
for i, x in { -35, 0, 35 } do
	add({ Id = "Chimenea" .. i, District = "Pozos", Kind = "Fabrica", Shape = "Tank", Name = "Torre de vapor", X = x, Z = 185, R = 8, Height = 30 })
end
add({ Id = "Refugio", District = "Pozos", Kind = "Refugio", Shape = "Box", Name = "Refugio antibombas", X = 110, Z = 125, W = 30, D = 20, Face = "W", Floors = 1,
	Style = "TefraBunker", Ground = "Lobby", Sign = "REFUGIO", Icon = "🛡" })
add({ Id = "Deposito", District = "Pozos", Kind = "Agua", Shape = "Tank", Name = "Depósito de agua", X = 190, Z = 190, R = 14, Height = 22, Icon = "💧",
	Info = "💧 El depósito de agua limpia. La cola llega hasta la esquina: «Dos cubos por familia»." })
add({ Id = "Lanza", District = "Pozos", Kind = "Militar", Shape = "Spire", Name = "La Lanza (en obras)", X = 0, Z = 340, W = 30, D = 30, Height = 120, Icon = "📍",
	Info = "📍 Una torre enorme con andamios y una lente en lo alto. Los obreros la llaman «la Lanza». Nadie sabe para qué es… todavía." })
add({ Id = "Invernadero", District = "Pozos", Kind = "Granja", Shape = "Greenhouse", Name = "Invernadero de setas de ceniza", X = 160, Z = 365, W = 60, D = 30, Height = 10, Icon = "🍄" })
add({ Id = "Raciones", District = "Pozos", Kind = "Tienda", Shape = "Box", Name = "Reparto de raciones", X = 140, Z = 275, W = 40, D = 30, Face = "N", Floors = 1,
	Style = "TefraBunker", Ground = "Shop", Sign = "REPARTO DE RACIONES", ShopId = "TefraRaciones", Icon = "🥫" })

TefraCity.Buildings = list
TefraCity.BuildingById = {}
for _, b in list do
	TefraCity.BuildingById[b.Id] = b
end

-- Otros sitios (mapa y avisos «Mirar»): la estatua, los puentes, las puertas…
TefraCity.Spots = {
	{ Id = "Estatua", Name = "Estatua de la abuela Nilda", X = 160, Z = -165, Icon = "🗿",
		Info = "🗿 La estatua de la abuela Nilda, con su bufanda de piedra. Está llena de ceniza, pero sigue en pie. Alguien le ha dejado una flor de tela." },
	{ Id = "Candados", Name = "Puente de los Mil Candados", X = -80, Z = 240, Icon = "🔒",
		Info = "🔒 El Puente de los Mil Candados: cada familia cuelga uno con el nombre de los que no volvieron. Hay tantos que la barandilla brilla." },
	{ Id = "Plataforma", Name = "Plataforma del Muelle", X = 0, Z = 0, Icon = "🛬" },
	{ Id = "Terraza", Name = "Terraza del Mirador", X = 205, Z = -205, Icon = "👁",
		Info = "👁 Desde la terraza se ve el Lago de Ceniza y, más allá, las ruinas de las cúpulas. En el cielo, Ovilla; de noche, sus fogonazos." },
}
for _, g in TefraCity.Gates do
	table.insert(TefraCity.Spots, { Id = "Puerta" .. g.Id, Name = g.Name, X = g.X - g.Dir[1] * 30, Z = g.Z - g.Dir[2] * 30, Icon = "🚧", Gate = g.Id,
		Info = "🚧 Control de la policía militar: «Papeles, por favor». Hoy te dejan pasar con un gesto. (Los papeles y las requisas llegan con la cadena «Papeles».)" })
end
TefraCity.SpotById = {}
for _, s in TefraCity.Spots do
	TefraCity.SpotById[s.Id] = s
end

---------------------------------------------------------------------
-- Sitios de la historia de Tefra (docs/planetas/tefra-misiones.md): marcas invisibles StorySpot con
-- SpotId «Tefra_<Id>» (las pone World/TefraCityBuilder) que usan las misiones (shared/LifeStory/
-- Locations: lugares «Tefra_…»). Y = altura sobre el suelo de la ciudad (la terraza); Outside = fuera
-- de la muralla, en el suelo del planeta (Tefra.groundAt). Inside = dentro de la planta baja de un
-- edificio (se entra por su puerta). Ningún lugar de Valmar se llama así: nunca se mezclan.
---------------------------------------------------------------------
local function spot(id: string, name: string, x: number, z: number, extra: { [string]: any }?): { [string]: any }
	local s: { [string]: any } = { Id = id, Name = name, X = x, Z = z }
	for k, v in extra or {} do
		s[k] = v
	end
	return s
end
local hollin = TefraCity.BuildingById.Tefra_PuestoNegro
local hx, hz = hollin.X, hollin.Z
do
	local w = TefraCity.Wells[1]
	local dx, dz = w.X - hx, w.Z - hz
	local len = math.sqrt(dx * dx + dz * dz)
	hx, hz = hx + dx / len * 7, hz + dz / len * 7
end
TefraCity.StorySpots = {
	-- Muelle Bastión
	spot("Plataforma", "Plataforma del Muelle", 24, 34),
	spot("TorreControl", "Torre de control del Muelle", 57, -40),
	spot("DespachoCorvo", "Despacho del General Corvo (torre de control)", 46, -44, { Inside = "Tefra_TorreControl" }),
	spot("Calabozos", "Calabozos del Muelle", -30, -95),
	spot("CalabozosDentro", "Registro de los calabozos", -30, -112, { Inside = "Tefra_Calabozos" }),
	spot("Armeria", "Armería del Muelle", 30, -95),
	spot("Astillero", "Astillero del Muelle", 0, -224),
	-- Barrio del Ovillo
	spot("CasaCosme", "La casa de la familia de Cosme", -180, -168, { Inside = "Tefra_CasaCosme" }),
	spot("CasaCosmePuerta", "La puerta de la casa de Cosme", -201, -170),
	spot("Panaderia", "Panadería del Ovillo", -130, -95),
	spot("RuinasOvillo", "Las cúpulas rotas del Ovillo", -296, -97),
	-- Mercado Espiral
	spot("PuestoHollin", "Puesto de Madre Hollín", hx, hz),
	spot("BloqueRefugio", "Bloque del Refugio 2", -289, -64),
	spot("PozoMercado", "Pozo del Mercado", -160, 22),
	-- Mirador de las Lunas
	spot("Estatua", "Estatua de la abuela Nilda", 160, -142),
	spot("MiradorCentro", "Mirador de las Lunas", 188, -186),
	spot("Terraza", "Terraza del Mirador", 205, -205, { Y = 14 }),
	-- Campus Nilda
	spot("Hospital", "Campus Nilda · hospital de campaña", 96, 0),
	spot("HospitalDentro", "Almacén del hospital", 112, 6, { Inside = "Tefra_Hospital" }),
	spot("Sopa", "Puesto de sopa del Campus", 166, 36),
	spot("Termas", "Baños termales", 226, 35),
	-- Las Fundiciones
	spot("OficinaTrabajo", "Oficina de trabajo", -96, 130),
	spot("FundicionNorte", "Fundición Norte", -320, 96),
	spot("Crisol", "Crisol de la Fundición Norte", -320, 116, { Inside = "Tefra_FundicionNorte" }),
	spot("Forja", "Forja de Bastión", -190, 96),
	spot("Viviendas", "Viviendas obreras", -189, 256),
	spot("Cremallera", "Estación del cremallera", -130, 384),
	-- Los Pozos de Magma
	spot("Central", "Central de los Pozos", 0, 96),
	spot("Conducto1", "Conducto de vapor oeste", -35, 203),
	spot("Conducto2", "Conducto de vapor central", 0, 205),
	spot("Conducto3", "Conducto de vapor este", 35, 203),
	spot("PozoMagma", "Pozo de Magma", 0, 300),
	spot("Lanza", "La Lanza", 0, 318),
	spot("Refugio", "Refugio antibombas", 96, 125),
	spot("RefugioDentro", "Dentro del refugio antibombas", 112, 125, { Inside = "Tefra_Refugio" }),
	spot("Raciones", "Reparto de raciones", 140, 256),
	spot("Deposito", "Depósito de agua", 190, 168),
	-- La Muralla
	spot("Cuartel", "Cuartel de la Muralla", -320, 256),
	spot("Explanada", "Explanada de la pelota de ceniza", -300, 345),
	spot("PuertaEste", "Puerta Este", 230, 80),
	spot("PuertaNorte", "Puerta Norte", -240, -230),
	spot("Candados", "Puente de los Mil Candados", -80, 240),
	-- Fuera de la muralla (suelo del planeta)
	spot("Baliza", "Baliza de señal", -420, -455, { Outside = true }),
	spot("Pecio", "El pecio de la Escuadrilla", -705, 548, { Outside = true }),
	spot("TierraDeNadie", "Tierra de nadie (Trincheras del Este)", 430, 110, { Outside = true }),
	spot("RuinasEste", "Ruinas de cúpulas del Este", 545, 320, { Outside = true }),
}
TefraCity.StorySpotById = {}
for _, s in TefraCity.StorySpots do
	TefraCity.StorySpotById[s.Id] = s
end

-- Refugios: dentro de su planta baja no llega el fuego de los bombardeos y el calor baja
-- (Services/TefraService). Cool = cuánto enfría por segundo (los baños, mucho; los búnkeres, algo).
TefraCity.Shelters = {
	Tefra_Refugio = { Cool = 6, Name = "Refugio antibombas" },
	Tefra_Termas = { Cool = 9, Name = "Baños termales" },
	Tefra_Hospital = { Cool = 5, Name = "Campus Nilda" },
	Tefra_Bloque1 = { Cool = 4, Name = "Bloque del Refugio 1" },
	Tefra_Bloque2 = { Cool = 4, Name = "Bloque del Refugio 2" },
	Tefra_Bloque3 = { Cool = 4, Name = "Bloque del Refugio 3" },
	Tefra_Bloque4 = { Cool = 4, Name = "Bloque del Refugio 4" },
	Tefra_Viviendas = { Cool = 3, Name = "Viviendas obreras" },
	Tefra_Cuartel = { Cool = 3, Name = "Cuartel de la Muralla" },
	Tefra_Calabozos = { Cool = 3, Name = "Calabozos del Muelle" },
	Tefra_Cremallera = { Cool = 3, Name = "Estación del cremallera" },
	Tefra_Panaderia = { Cool = 2, Name = "el sótano de la Panadería del Ovillo" },
	Tefra_Raciones = { Cool = 3, Name = "el almacén del reparto de raciones" },
}

-- ¿En qué refugio está este punto? (dentro de la planta baja de un edificio refugio, a más de un stud
-- de sus paredes) → id, refugio
function TefraCity.shelterAt(lx: number, lz: number): (string?, { [string]: any }?)
	local b = TefraCity.buildingAt(lx, lz, 0)
	if b and TefraCity.Shelters[b.Id] then
		local x0, x1, z0, z1 = TefraCity.footprint(b)
		if lx > x0 + 1 and lx < x1 - 1 and lz > z0 + 1 and lz < z1 - 1 then
			return b.Id, TefraCity.Shelters[b.Id]
		end
	end
	return nil, nil
end

-- La puerta del refugio más cercano (local x, z, por fuera) y su id
function TefraCity.nearestShelter(lx: number, lz: number): (number, number, string)
	local best, bx, bz, bid = math.huge, 0, 0, "Tefra_Refugio"
	for id in TefraCity.Shelters do
		local b = TefraCity.BuildingById[id]
		if b then
			local dx, dz = TefraCity.door(b)
			if dx and dz then
				local d = (dx - lx) ^ 2 + (dz - lz) ^ 2
				if d < best then
					best, bx, bz, bid = d, dx, dz, id
				end
			end
		end
	end
	return bx, bz, bid
end

-- Dentro de un refugio, de verdad (el sitio de dentro de su planta baja, local x, z)
function TefraCity.shelterInside(id: string): (number, number)
	local b = TefraCity.BuildingById[id]
	if not b then
		return 0, 0
	end
	local dx, dz, f = TefraCity.door(b)
	if dx and dz and f then
		return dx - f[1] * 8, dz - f[2] * 8
	end
	return b.X, b.Z
end

---------------------------------------------------------------------
-- Cuentas
---------------------------------------------------------------------
local function smooth(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

-- Distancia (con signo) al rectángulo de la ciudad: negativa dentro
function TefraCity.rectDistance(lx: number, lz: number): number
	local R = TefraCity.Rect
	local dx = math.max(R.X0 - lx, 0, lx - R.X1)
	local dz = math.max(R.Z0 - lz, 0, lz - R.Z1)
	if dx == 0 and dz == 0 then
		return -math.min(lx - R.X0, R.X1 - lx, lz - R.Z0, R.Z1 - lz)
	end
	return math.sqrt(dx * dx + dz * dz)
end

-- ¿Dentro de la ciudad (la muralla incluida)?
function TefraCity.inside(lx: number, lz: number, margin: number?): boolean
	return TefraCity.rectDistance(lx, lz) <= (margin or 0)
end

-- ¿Lava? (el foso, el canal o un pozo). Bajo los puentes también es lava (el puente va por encima).
function TefraCity.inLava(lx: number, lz: number): boolean
	local d = TefraCity.rectDistance(lx, lz)
	if d > TefraCity.WallThick and d < TefraCity.MoatOut then
		return true
	end
	local c = TefraCity.Canal
	local R = TefraCity.Rect
	if math.abs(lz - c.Z) < c.Half and lx > R.X0 - TefraCity.MoatOut and lx < R.X1 + TefraCity.MoatOut then
		return true
	end
	for _, w in TefraCity.Wells do
		if (lx - w.X) ^ 2 + (lz - w.Z) ^ 2 < w.R * w.R then
			return true
		end
	end
	return false
end

-- La forma del suelo: la meseta, la muralla, el foso, la orilla y la bajada al resto del planeta.
-- h = la altura del planeta sin la ciudad (local, como Tefra.rawHeight); base = Tefra.padY().
function TefraCity.shape(lx: number, lz: number, h: number, base: number): number
	local d = TefraCity.rectDistance(lx, lz)
	if d > TefraCity.Blend then
		return h
	end
	local ground = base - TefraCity.GroundDrop
	local lava = base - TefraCity.LavaDepth
	if d <= TefraCity.WallThick then
		return if TefraCity.inLava(lx, lz) then lava else ground
	elseif d < TefraCity.MoatOut then
		return lava
	elseif d <= TefraCity.Bank then
		return ground
	end
	local w = smooth(TefraCity.Blend, TefraCity.Bank, d)
	return h + (ground - h) * w
end

-- La calle más cercana: (distancia al eje, la calle). Solo cuenta el tramo de la calle.
function TefraCity.streetDistance(lx: number, lz: number): (number, any)
	local best, which = math.huge, nil
	for _, s in TefraCity.Streets do
		local along = if s.Axis == "X" then lx else lz
		local across = if s.Axis == "X" then lz else lx
		local u = math.clamp(along, s.From, s.To)
		local d = math.sqrt((along - u) ^ 2 + (across - s.At) ^ 2)
		if d < best then
			best, which = d, s
		end
	end
	return best, which
end

-- Manzana (col, fila) de un punto, si cae dentro de su interior
function TefraCity.blockAt(lx: number, lz: number): (number?, number?)
	local H = TefraCity.BlockHalf
	for c, cx in TefraCity.BlockCols do
		if math.abs(lx - cx) <= H then
			for r, cz in TefraCity.BlockRows do
				if math.abs(lz - cz) <= H then
					return c, r
				end
			end
		end
	end
	return nil, nil
end

-- ¿Se puede andar por aquí a la altura de la calle? (calzada, acera, paseo del canal o una manzana abierta)
function TefraCity.walkable(lx: number, lz: number): boolean
	if not TefraCity.inside(lx, lz, TefraCity.Bank) or TefraCity.inLava(lx, lz) and TefraCity.streetDistance(lx, lz) > TefraCity.RoadHalf then
		return false
	end
	if TefraCity.streetDistance(lx, lz) <= TefraCity.RoadHalf then
		return true
	end
	local c = TefraCity.Canal
	if math.abs(lz - c.Z) <= c.Half + c.Walk then
		return TefraCity.inside(lx, lz, 0)
	end
	local col, row = TefraCity.blockAt(lx, lz)
	return col ~= nil and TefraCity.OpenBlocks[col .. "," .. row] ~= nil
end

-- Huella de un edificio: x0, x1, z0, z1 (local, alineada con los ejes)
function TefraCity.footprint(b: Building): (number, number, number, number)
	if b.Shape == "Dome" or b.Shape == "Skeleton" or b.Shape == "Tank" then
		local r = b.R or 8
		return b.X - r, b.X + r, b.Z - r, b.Z + r
	end
	local w, d = b.W or 10, b.D or 10
	if b.Shape == "Stall" then
		return b.X - w / 2, b.X + w / 2, b.Z - w / 2, b.Z + w / 2 -- (gira: su caja de los dos lados)
	end
	local sx, sz = w, d
	if b.Face == "E" or b.Face == "W" then
		sx, sz = d, w
	end
	return b.X - sx / 2, b.X + sx / 2, b.Z - sz / 2, b.Z + sz / 2
end

local FACE = { N = { 0, -1 }, S = { 0, 1 }, E = { 1, 0 }, W = { -1, 0 } }
TefraCity.FaceDir = FACE

-- La puerta de un edificio con planta baja (Box): (x, z) en la fachada, y la dirección hacia fuera
function TefraCity.door(b: Building): (number?, number?, { number }?)
	if b.Shape ~= "Box" or b.Ground == "Closed" then
		return nil, nil, nil
	end
	local f = FACE[b.Face or "N"]
	local d = b.D or 10
	return b.X + f[1] * d / 2, b.Z + f[2] * d / 2, f
end

-- Altura de lo de arriba de cada edificio (studs sobre Base): para los choques de la nave
function TefraCity.topOf(b: Building): number
	if b.Shape == "Box" then
		local floors = b.Floors or 1
		local ground = if b.Ground == "Shop" then 15 elseif b.Ground == "House" then 11 elseif b.Ground == "Garage" then 16 else 13
		local fh = if b.Ground == "House" then 10 else 12
		return 1 + ground + (floors - 1) * fh + 2.4 + (if b.DomeRoof then 8 else 0)
	elseif b.Shape == "Dome" or b.Shape == "Skeleton" then
		return (b.R or 8) * 0.85
	elseif b.Shape == "Court" then
		return 1
	end
	return b.Height or 10
end

-- Rejilla de 40 studs con los edificios que tocan cada celda (para no recorrer todos en cada cuenta)
local CELL = 40
local grid: { [number]: { Building } }? = nil
local function cellKey(i: number, k: number): number
	return (i + 1000) * 4096 + (k + 1000)
end
local function buildGrid(): { [number]: { Building } }
	local g = {}
	for _, b in list do
		if b.Shape ~= "Court" then
			local x0, x1, z0, z1 = TefraCity.footprint(b)
			for i = math.floor(x0 / CELL), math.floor(x1 / CELL) do
				for k = math.floor(z0 / CELL), math.floor(z1 / CELL) do
					local key = cellKey(i, k)
					g[key] = g[key] or {}
					table.insert(g[key], b)
				end
			end
		end
	end
	return g
end

-- El edificio que hay en (lx, lz) (con margen), o nil
function TefraCity.buildingAt(lx: number, lz: number, margin: number?): Building?
	if not TefraCity.inside(lx, lz, 10 + (margin or 0)) then
		return nil
	end
	grid = grid or buildGrid()
	local m = margin or 0
	for i = math.floor((lx - m) / CELL), math.floor((lx + m) / CELL) do
		for k = math.floor((lz - m) / CELL), math.floor((lz + m) / CELL) do
			for _, b in (grid :: any)[cellKey(i, k)] or {} do
				local x0, x1, z0, z1 = TefraCity.footprint(b)
				if lx >= x0 - m and lx <= x1 + m and lz >= z0 - m and lz <= z1 + m then
					return b
				end
			end
		end
	end
	return nil
end

-- Lo más alto sólido en (lx, lz) sobre Base (edificios y muralla), o nil si no hay nada
function TefraCity.solidTop(lx: number, lz: number, margin: number?): number?
	local d = TefraCity.rectDistance(lx, lz)
	local m = margin or 0
	if d >= -m and d <= TefraCity.WallThick + m then
		-- (por las puertas se pasa)
		for _, g in TefraCity.Gates do
			local along = if g.Dir[1] ~= 0 then lz - g.Z else lx - g.X
			local onSide = if g.Dir[1] ~= 0 then math.abs(lx - g.X) < 40 else math.abs(lz - g.Z) < 40
			if onSide and math.abs(along) < TefraCity.GateHalf then
				return nil
			end
		end
		return TefraCity.WallHeight + 2
	end
	local b = TefraCity.buildingAt(lx, lz, m)
	if b then
		return TefraCity.topOf(b)
	end
	return nil
end

-- ¿Puede posarse aquí la nave? (no encima de edificios, la muralla ni la lava)
function TefraCity.landingBlocked(lx: number, lz: number): boolean
	if not TefraCity.inside(lx, lz, TefraCity.Bank) then
		return false
	end
	if TefraCity.inLava(lx, lz) then
		return true
	end
	return TefraCity.solidTop(lx, lz, 10) ~= nil
end

-- Las torres de la muralla (por fuera del borde): { X, Z, S (lado), H (alto) }
function TefraCity.towers(): { { X: number, Z: number, S: number, H: number } }
	local R = TefraCity.Rect
	local out = {}
	local function add(x: number, z: number, s: number, h: number)
		table.insert(out, { X = x, Z = z, S = s, H = h })
	end
	local cs = 18
	add(R.X0 - cs / 2, R.Z0 - cs / 2, cs, 30)
	add(R.X1 + cs / 2, R.Z0 - cs / 2, cs, 30)
	add(R.X0 - cs / 2, R.Z1 + cs / 2, cs, 30)
	add(R.X1 + cs / 2, R.Z1 + cs / 2, cs, 30)
	local ms = 14
	add(R.X0 - ms / 2, 180, ms, 26)
	add(R.X1 + ms / 2, -120, ms, 26)
	add(80, R.Z1 + ms / 2, ms, 26)
	add(-40, R.Z0 - ms / 2, ms, 26)
	local gs = 12
	for _, g in TefraCity.Gates do
		for _, s in { -1, 1 } do
			local off = (TefraCity.GateHalf + gs / 2) * s
			if g.Dir[1] ~= 0 then
				add(g.X + g.Dir[1] * gs / 2, g.Z + off, gs, 24)
			else
				add(g.X + off, g.Z + g.Dir[2] * gs / 2, gs, 24)
			end
		end
	end
	return out
end

-- El barrio de un punto (o nil)
local function pointIn(poly: { { number } }, x: number, z: number): boolean
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, zi = poly[i][1], poly[i][2]
		local xj, zj = poly[j][1], poly[j][2]
		if (zi > z) ~= (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end
TefraCity.pointIn = pointIn

function TefraCity.districtAt(lx: number, lz: number): { [string]: any }?
	if not TefraCity.inside(lx, lz, 0) then
		return nil
	end
	for _, d in TefraCity.Districts do
		if pointIn(d.Poly, lx, lz) then
			return d
		end
	end
	-- (entre el último eje de calle y la muralla: el barrio de al lado)
	local R = TefraCity.Rect
	local cx = math.clamp(lx, R.X0 + 21, R.X1 - 21)
	local cz = math.clamp(lz, R.Z0 + 21, R.Z1 - 21)
	for _, d in TefraCity.Districts do
		if pointIn(d.Poly, cx, cz) then
			return d
		end
	end
	return TefraCity.DistrictById.Muralla
end

-- Si te caes a la lava: el sitio seguro más cercano a la altura de la calle (local x, z)
function TefraCity.rescueSpot(lx: number, lz: number): (number, number)
	local best, bx, bz = math.huge, 0, 0
	-- (la acera o calle más cercana, en una rejilla de 8 studs alrededor)
	for dx = -48, 48, 8 do
		for dz = -48, 48, 8 do
			local x, z = lx + dx, lz + dz
			if not TefraCity.inLava(x, z) and TefraCity.inside(x, z, 0) and TefraCity.buildingAt(x, z, 3) == nil and TefraCity.walkable(x, z) then
				local dist = dx * dx + dz * dz
				if dist < best then
					best, bx, bz = dist, x, z
				end
			end
		end
	end
	if best < math.huge then
		return bx, bz
	end
	-- (lejos de todo: a la puerta más cercana, por dentro)
	local gate, gd = TefraCity.Gates[1], math.huge
	for _, g in TefraCity.Gates do
		local d = (g.X - lx) ^ 2 + (g.Z - lz) ^ 2
		if d < gd then
			gate, gd = g, d
		end
	end
	return gate.X - gate.Dir[1] * 30, gate.Z - gate.Dir[2] * 30
end

-- Lo que sale en el mapa: { Icon, Name, X, Z, Kind } (edificios con icono y sitios)
function TefraCity.landmarks(): { { [string]: any } }
	local out = {}
	for _, b in list do
		if b.Icon then
			table.insert(out, { Id = b.Id, Icon = b.Icon, Name = b.Name, X = b.X, Z = b.Z, Kind = b.Kind })
		end
	end
	for _, s in TefraCity.Spots do
		table.insert(out, { Id = s.Id, Icon = s.Icon, Name = s.Name, X = s.X, Z = s.Z, Kind = "Sitio" })
	end
	return out
end

-- El tiempo del reloj en Tefra (no el de Valmar): siempre cae ceniza; hace más calor de día y junto a
-- la lava. clock = la hora del juego (0-24).
function TefraCity.weather(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
	local day = math.sin((clock - 8) / 24 * math.pi * 2) -- (de −1 de madrugada a 1 por la tarde)
	return { Id = "Ceniza", Name = "Lluvia de ceniza", Icon = "niebla", Temp = math.floor(31 + 6 * day + 0.5) }
end

return TefraCity
