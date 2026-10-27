-- NacaraV2: el plano de Nácara v2, la ciudad del mapa del dueño (docs/mar/referencia/ciudad-marina-dueno.png,
-- diseño en docs/mar/nacara-v2/diseno.md). Solo datos y cuentas puras (sin crear nada de Roblox): las usan
-- World/NacaraV2Builder (el prototipo: Palacio Real y Plaza Central), scripts/map/nacara-v2-export.luau (las
-- vistas previas) y scripts/test-nacara-v2.luau.
--
-- ESTÁ APAGADO (Config.Sea.NacaraV2 = false): el dueño aprueba antes las vistas previas. Hasta entonces el juego
-- es la Nácara de la fase 1, sin ningún cambio.
--
--   NacaraV2.On                      ¿encendido? (Config.Sea.NacaraV2)
--   NacaraV2.Districts / ById        los 16 barrios del mapa: dónde (coordenadas de la plaza, X al este, Z al
--                                    sur), radio de su isla, para qué sirven, qué reutilizan y en qué fase van
--   NacaraV2.Links                   pasarelas y tubos de cristal entre islas
--   NacaraV2.Palace                  las medidas del Palacio Real (prototipo)
--   NacaraV2.fromReference(px, py)   de un píxel del mapa del dueño a coordenadas de la plaza
--   NacaraV2.toWorld(x, z, y?)       de la plaza al mundo (como Nacara.toWorld)

local Nacara = require(script.Parent.Nacara)

local NacaraV2 = {}

local okConfig, Config = pcall(function()
	return require(script.Parent.Parent.Config)
end)
NacaraV2.On = okConfig and type(Config) == "table" and type(Config.Sea) == "table" and Config.Sea.NacaraV2 == true

-- El mapa del dueño (1536 × 1024 px, el norte arriba). El Palacio Real está en el píxel Center y queda en
-- Palace (coordenadas de la plaza: al norte de la plaza de la fase 0, que es la Plaza Central del mapa).
-- Scale = studs por píxel: con 0,72 la ciudad mide ~900 studs de lado a lado (el radio ≈ 450 de
-- docs/mar/civilizacion-marina.md §3.1) y la Plaza Central cae justo en la plaza de la fase 0.
NacaraV2.Reference = { Center = { 770, 420 }, Scale = 0.72 }
NacaraV2.PalaceAt = { X = 5, Z = -152 } -- (al norte de la plaza; deja libres la Concha del Consejo y la perla-farola 7)

function NacaraV2.fromReference(px: number, py: number): (number, number)
	local r = NacaraV2.Reference
	return NacaraV2.PalaceAt.X + (px - r.Center[1]) * r.Scale, NacaraV2.PalaceAt.Z + (py - r.Center[2]) * r.Scale
end

function NacaraV2.toWorld(x: number, z: number, y: number?): Vector3
	return Nacara.toWorld(x, z, y)
end

-- Los 16 barrios. Px = dónde está en el mapa del dueño; X/Z se calculan de ahí salvo Fixed (lo que ya existe y
-- no se mueve). R = radio de la isla. Icons = los iconos de la leyenda del mapa (Mision, Secundaria, Npc, Tienda,
-- Trabajo, Vivienda, Transporte, Ambiental, Pesca, Evento, Camara). Reuse = lo que ya existe y se aprovecha.
-- Phase = en qué fase se construye (docs/mar/nacara-v2/diseno.md §6). Budget = piezas del servidor como mucho.
NacaraV2.Districts = {
	{ Id = "Palacio", Name = "Palacio Real", Px = { 770, 420 }, R = 46, Phase = 1, Budget = 230,
		Icons = { "Mision", "Npc", "Evento" }, Reuse = "Concha del Consejo (ala oeste: el juicio y Maresa)" },
	{ Id = "Plaza", Name = "Plaza Central", Px = { 790, 600 }, Fixed = { X = 0, Z = 0 }, R = 60, Phase = 1, Budget = 80,
		Icons = { "Mision", "Npc", "Evento", "Camara" }, Reuse = "Plaza de la Corriente (fase 0): fuente, faro de luz, Lonja Honda, Ilun y Oriana" },
	{ Id = "Residencias", Name = "Residencias de Sirenas", Px = { 590, 180 }, R = 56, Phase = 2, Budget = 260,
		Icons = { "Vivienda", "Npc" }, Reuse = "las conchas MarCasa_Nacara_1…6 (mismas llaves) y pisos MarPiso_" },
	{ Id = "Universidad", Name = "Universidad Marina", Px = { 1000, 190 }, R = 62, Phase = 3, Budget = 240,
		Icons = { "Mision", "Trabajo", "Npc" }, Reuse = "Acto II «El pacto del faro» (etapa universidad)" },
	{ Id = "Hospital", Name = "Hospital Marino", Px = { 520, 330 }, R = 50, Phase = 2, Budget = 180,
		Icons = { "Trabajo", "Npc" }, Reuse = "HospitalService: un hondario se despierta aquí" },
	{ Id = "Mercado", Name = "Mercado Submarino", Px = { 310, 440 }, R = 56, Phase = 2, Budget = 260,
		Icons = { "Tienda", "Trabajo", "Npc" }, Reuse = "la Lonja Honda (precios del mar) y los locales MarLocal_" },
	{ Id = "Comercios", Name = "Comercios y Tiendas", Px = { 1060, 410 }, R = 56, Phase = 2, Budget = 220,
		Icons = { "Tienda", "Trabajo" }, Reuse = "ShopService: ropa hondaria, muebles de coral, equipo" },
	{ Id = "Biblioteca", Name = "Biblioteca de las Profundidades", Px = { 460, 570 }, R = 56, Phase = 3, Budget = 200,
		Icons = { "Secundaria", "Npc", "Ambiental" }, Reuse = "el archivo de la historia del mar (secundarias)" },
	{ Id = "Cueva", Name = "Cueva de las Perlas", Px = { 270, 280 }, R = 56, Phase = 3, Budget = 200,
		Icons = { "Pesca", "Trabajo", "Ambiental" }, Reuse = "oficio de pescador/a de perlas (fase 1 bis) y Oriana" },
	{ Id = "Templo", Name = "Templo de los Sirenos", Px = { 1380, 510 }, R = 62, Phase = 3, Budget = 220,
		Icons = { "Mision", "Evento" }, Reuse = "el ritual del don (Mar_12_Don)" },
	{ Id = "Santuario", Name = "Santuario del Océano", Px = { 1360, 300 }, R = 62, Phase = 3, Budget = 220,
		Icons = { "Secundaria", "Ambiental", "Camara" }, Reuse = "los Grandes (criaturas) y los faros de perla" },
	{ Id = "Torre", Name = "Torre de Observación", Px = { 1040, 650 }, R = 44, Phase = 3, Budget = 150,
		Icons = { "Camara", "Transporte" }, Reuse = "puntos de foto (Civ.PhotoSpots) y la parada central de corrientes" },
	{ Id = "Entrenamiento", Name = "Zona de Entrenamiento", Px = { 330, 750 }, R = 60, Phase = 3, Budget = 200,
		Icons = { "Trabajo", "Secundaria" }, Reuse = "la Guardia de la Corriente (CombatService, sin armas con punta)" },
	{ Id = "Acuario", Name = "Acuario Gigante", Px = { 600, 850 }, R = 70, Phase = 3, Budget = 220,
		Icons = { "Ambiental", "Evento", "Camara" }, Reuse = "la fauna del mar (MarFauna) en una cúpula grande" },
	{ Id = "Puerto", Name = "Puerto de Sirenas", Px = { 1220, 790 }, R = 54, Phase = 3, Budget = 240,
		Icons = { "Transporte", "Trabajo", "Tienda" }, Reuse = "submarinos al Cañón: Valmar Hundida y la Catedral Abisal" },
	{ Id = "Jardines", Name = "Jardines de Coral", Px = { 1140, 930 }, R = 56, Phase = 2, Budget = 200,
		Icons = { "Pesca", "Trabajo", "Ambiental" }, Reuse = "los Jardines de Cultivo (bancales, Tomé, oficio de cultivador/a)" },
}
NacaraV2.ById = {}
for _, d in NacaraV2.Districts do
	if d.Fixed then
		d.X, d.Z = d.Fixed.X, d.Fixed.Z
	else
		d.X, d.Z = NacaraV2.fromReference(d.Px[1], d.Px[2])
		d.X, d.Z = math.round(d.X), math.round(d.Z)
	end
	NacaraV2.ById[d.Id] = d
end

-- Pasarelas (Kind = "Walk": camino sobre roca) y tubos de cristal (Kind = "Tube": con corriente rápida en la
-- fase 4). Como en el mapa: todo sale del palacio y de la plaza hacia fuera.
NacaraV2.Links = {
	{ "Plaza", "Palacio", Kind = "Tube" },
	{ "Palacio", "Residencias", Kind = "Tube" },
	{ "Palacio", "Universidad", Kind = "Tube" },
	{ "Palacio", "Hospital", Kind = "Walk" },
	{ "Palacio", "Comercios", Kind = "Walk" },
	{ "Hospital", "Mercado", Kind = "Walk" },
	{ "Hospital", "Cueva", Kind = "Walk" },
	{ "Mercado", "Biblioteca", Kind = "Walk" },
	{ "Plaza", "Biblioteca", Kind = "Walk" },
	{ "Plaza", "Acuario", Kind = "Tube" },
	{ "Plaza", "Torre", Kind = "Tube" },
	{ "Biblioteca", "Entrenamiento", Kind = "Walk" },
	{ "Comercios", "Santuario", Kind = "Walk" },
	{ "Comercios", "Templo", Kind = "Walk" },
	{ "Torre", "Puerto", Kind = "Tube" },
	{ "Torre", "Jardines", Kind = "Walk" },
	{ "Puerto", "Jardines", Kind = "Walk" },
}

-- El Palacio Real (prototipo de la fase 1): isla de roca, tambor de nácar, cúpula de cristal con el corazón de
-- luz, agujas alrededor y la aguja mayor. Alturas sobre el suelo de la plaza (Nacara.FloorY). Nada pasa de
-- Nacara.MaxTop (queda a ~70 studs de la superficie: los barcos pasan por encima).
NacaraV2.Palace = {
	Island = 8, -- la isla sube 8 studs sobre la plaza (como las demás: NacaraV2.IslandTop)
	Drum = { R = 26, H = 10 },
	Terrace = { R = 40 },
	Dome = { R = 24, H = 22 },
	Spires = { Count = 12, Ring = 34, Low = 22, High = 34 },
	Crown = 63, -- la punta de la aguja mayor (sobre el suelo de la plaza)
}

-- La plaza de la fase 0 no se toca; el prototipo solo le pone su cartel y el borde de luz de la isla
NacaraV2.PlazaRim = { R = 58, Gaps = { 0, 90, 180, 270 } }

NacaraV2.MaxLights = 2 -- luces de verdad POR BARRIO (el resto, Neon, sin sombras)

-- (v2 «como el mapa») Las islas: roca de basalto que sube IslandTop studs sobre el fondo de la plaza, con
-- acantilado de peñascos, coral del kit del mar al borde, kelp gigante alrededor y plantas que brillan. La Plaza
-- Central es la de la fase 0 (a 0): solo se le pone el anillo de peñascos alrededor.
NacaraV2.IslandTop = 8
-- Lo que se construye en el juego al encenderlo (fase 1: palacio y plaza). Las vistas previas dibujan todo.
NacaraV2.BuildPhase = 1
-- Presupuesto de los enlaces (tubos y pasarelas) y de las mallas del kit de toda la ciudad
NacaraV2.LinkBudget = 460
NacaraV2.KitBudget = 1150

return NacaraV2
