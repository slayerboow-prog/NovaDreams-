-- PremiumVehicles: los 13 vehículos premium del pase de temporada (5 deportivos, 5 superdeportivos
-- y 3 motos). SOLO DATOS y funciones puras (sin servicios ni instancias; los colores van como
-- {r, g, b}) para que lo usen igual el servidor (World/Kit/SportsCars los construye), el taller
-- (VehicleParts / VehicleBuild: anclas, ruedas y zonas), el pase (BattlePass/Season1) y las pruebas
-- con Lune (scripts/test-sportscars.luau).
--
-- Reglas del dueño (definitivas):
--   * Sin pagar para ganar: un vehículo premium es un «Coche» o una «Moto» del juego (mismo tipo,
--     Kind). Conduce EXACTAMENTE igual que el mejor coche / la mejor moto que se gana jugando
--     (Gameplay.Vehicles / Gameplay.Driving del tipo): aquí no hay velocidad, aceleración, frenada,
--     giro ni peso. Se diferencian en el diseño, las luces, el sonido del motor (tono) y el prestigio.
--     Las barras de la interfaz (Velocidad / Manejo) salen de las del tipo; la Estética es donde brillan.
--   * Premium = true: el sistema de ruedas y combustible (pinchazos, consumo) lo mira en esta tabla y
--     en el atributo «Premium» del modelo (lo pone SportsCars al construirlo).
--   * Nada de marcas reales: nombres, siluetas, parrillas y pilotos originales. Ni logos ni insignias
--     (la matrícula dice VALMAR). Por eso «Stratos RS» se llama «Strato RS» y «Viper GT», «Víbora GT».
--
-- Convención de todos los vehículos: centro a ras de suelo, el morro mira a −Z, el conductor va a
-- la izquierda (−X). Medidas en studs. Los coches caben en la caja del coche de siempre
-- (Rides.Spec.Coche: 6,2 × 13,5) y las motos en la de la moto (1,6 × 5,8).

local PremiumVehicles = {}

-- Barras de la interfaz (de 0 a 5). Velocidad y Manejo = las del tipo del juego (las comprueba la
-- prueba con Gameplay: Velocidad = Speed / 80 × 5, Manejo = Turn / 2,5 × 5, redondeadas). La de
-- los vehículos que se compran con dinero del juego también está aquí para comparar.
PremiumVehicles.BaseStats = {
	Coche = { Velocidad = 5, Manejo = 3, Estetica = 2 },
	Moto = { Velocidad = 4, Manejo = 4, Estetica = 2 },
}

-- Estética por rareza (la diferencia de verdad)
local AESTHETICS = { Rara = 4, Epica = 5, Legendaria = 5 }

---------------------------------------------------------------------
-- Siluetas de los coches
---------------------------------------------------------------------
-- Hood / Deck: perfil del centro (capó y zaga) {z, altura}. Side: altura de la línea de hombros
-- (aletas y puertas). Cabin: habitáculo (Base = pie del parabrisas, Belt = línea de cintura,
-- RoofFront/RoofBack = techo, Back/BackY = donde acaba la luneta o la tapa del motor, Half = medio
-- ancho de los cristales, Style = Fastback / Notch / Engine). CabBack = donde acaba el suelo del
-- habitáculo (detrás de los asientos). Wheels: X = media vía, Front / Rear = ejes, radio del
-- neumático, ancho y diámetro de la llanta (perfil bajo).
local SHAPES = {
	-- Gran turismo de motor delantero: capó largo, techo bajo que cae en «fastback»
	GT = {
		Wheels = { X = 2.6, Front = -4.4, Rear = 4.3, Radius = 1.3, Width = 1.15, Rim = 2.0 },
		Hood = { { -6.75, 2.05 }, { -6.15, 2.45 }, { -4.2, 2.78 }, { -2.1, 3.0 } },
		Deck = { { 2.3, 2.85 }, { 4.7, 3.15 }, { 6.25, 3.32 }, { 6.75, 3.15 } },
		Side = { Nose = 2.3, Peak = 3.15, DoorF = 3.05, DoorR = 3.1, RearPeak = 3.35, Tail = 3.2 },
		Cabin = { Base = -2.1, Belt = 3.0, RoofFront = -0.1, RoofBack = 1.7, Roof = 4.55, Back = 4.7, BackY = 3.15, Half = 2.45, Style = "Fastback" },
		CabBack = 2.3,
	},
	-- Muscle car: frontal alto y recto, capó larguísimo con toma de aire, techo «notchback»
	Muscle = {
		Wheels = { X = 2.6, Front = -4.45, Rear = 4.25, Radius = 1.3, Width = 1.15, Rim = 2.0 },
		Hood = { { -6.75, 2.6 }, { -6.4, 2.88 }, { -1.5, 3.15 } },
		Deck = { { 3.45, 3.05 }, { 4.15, 3.36 }, { 6.75, 3.42 } },
		Side = { Nose = 2.8, Peak = 3.22, DoorF = 3.2, DoorR = 3.25, RearPeak = 3.4, Tail = 3.38 },
		Cabin = { Base = -1.5, Belt = 3.15, RoofFront = 0.3, RoofBack = 2.4, Roof = 4.8, Back = 4.15, BackY = 3.36, Half = 2.5, Style = "Notch" },
		CabBack = 3.45,
	},
	-- Superdeportivo de motor central: morro bajísimo, habitáculo adelantado, tapa del motor larga
	Super = {
		Wheels = { X = 2.6, Front = -4.55, Rear = 4.25, Radius = 1.3, Width = 1.15, Rim = 2.0 },
		Hood = { { -6.75, 1.75 }, { -6.1, 2.2 }, { -4.4, 2.55 }, { -3.4, 2.78 } },
		Deck = { { 1.25, 2.9 }, { 4.6, 3.22 }, { 6.3, 3.32 }, { 6.75, 3.1 } },
		Side = { Nose = 2.0, Peak = 3.02, DoorF = 2.92, DoorR = 3.18, RearPeak = 3.36, Tail = 3.18 },
		Cabin = { Base = -3.4, Belt = 2.8, RoofFront = -1.3, RoofBack = 0.5, Roof = 4.3, Back = 4.6, BackY = 3.22, Half = 2.35, Style = "Engine" },
		CabBack = 1.25,
	},
}
PremiumVehicles.Shapes = SHAPES

-- Asientos de cada silueta. Driver = {x, y, z} (y = encima del cojín). Passengers como
-- Rides.passengerSeats: {x, y, z, lado por el que se baja, cartel, postura}.
local function twoSeats(y: number, z: number)
	return { Driver = { -1.1, y, z }, Passengers = { { 1.1, y, z, 1, "Subir de copiloto", "Passenger" } } }
end
local function fourSeats(y: number, z: number, rearZ: number)
	return {
		Driver = { -1.1, y, z },
		Passengers = {
			{ 1.1, y, z, 1, "Subir de copiloto", "Passenger" },
			{ -1.0, y, rearZ, -1, "Subir detrás", "Passenger" },
			{ 1.0, y, rearZ, 1, "Subir detrás", "Passenger" },
		},
	}
end

---------------------------------------------------------------------
-- Los 13 vehículos
---------------------------------------------------------------------
-- Campos: Number (orden de la hoja), Name, Kind, Class, Rarity, Shape, Paint / Secondary / Accent /
-- Glow (colores), Finish (Gloss, Metallic, Matte), Rims (Style y color), Caliper (color de las pinzas),
-- Lights (estilo de faros y pilotos), y los detalles de cada uno. Blurb = texto del pase.
PremiumVehicles.Vehicles = {
	VoltexGTR = {
		Number = 1, Name = "Voltex GT-R", Kind = "Coche", Class = "Deportivo", Rarity = "Rara", Shape = "GT", Seats = 4,
		Paint = { 30, 82, 214 }, Secondary = { 22, 23, 28 }, Accent = { 255, 120, 40 }, Glow = { 190, 225, 255 }, Finish = "Metallic",
		Rims = { Style = "Ten", Color = { 46, 50, 60 } }, Caliper = { 235, 70, 40 },
		Head = "Sharp", Drl = "Boomerang", Tail = "QuadRound", Exhaust = "Quad", Wing = "GT", HoodVents = 2, Canards = true,
		EnginePitch = 0.92, Plate = "01 VALMAR",
		Blurb = "Deportivo 2+2 azul con alerón GT, cuatro pilotos redondos, faros afilados con luz diurna en bumerán y llantas de 10 radios.",
	},
	StratoRS = {
		Number = 2, Name = "Strato RS", Kind = "Coche", Class = "Deportivo", Rarity = "Epica", Shape = "GT", Seats = 2,
		Paint = { 205, 26, 32 }, Secondary = { 18, 18, 22 }, Accent = { 255, 210, 60 }, Glow = { 235, 240, 255 }, Finish = "Gloss",
		Rims = { Style = "Five", Color = { 24, 24, 28 } }, Caliper = { 245, 200, 40 },
		Head = "Slim", Drl = "Fang", Tail = "Split", Exhaust = "CenterTwin", Wing = "Duck", SideVents = true,
		Tweak = { Hood = { { -6.75, 1.95 }, { -6.15, 2.38 }, { -4.2, 2.72 }, { -2.1, 2.98 } }, Side = { Nose = 2.2, Peak = 3.18, RearPeak = 3.42 } },
		EnginePitch = 1.05, Plate = "02 VALMAR",
		Blurb = "Deportivo rojo de líneas redondas: luces diurnas en colmillo, cola de pato, pilotos partidos y escape doble central.",
	},
	KairoS = {
		Number = 3, Name = "Kairo S", Kind = "Coche", Class = "Deportivo", Rarity = "Rara", Shape = "GT", Seats = 2,
		Paint = { 182, 186, 194 }, Secondary = { 20, 20, 24 }, Accent = { 230, 50, 45 }, Glow = { 225, 235, 255 }, Finish = "Metallic",
		Rims = { Style = "Y", Color = { 150, 104, 58 } }, Caliper = { 225, 45, 40 },
		Head = "Round", Drl = "Halo", Tail = "FullWidth", Exhaust = "Twin", Wing = "Lip", Stripes = "Twin", HoodVents = 1,
		EnginePitch = 1.0, Plate = "03 VALMAR",
		Blurb = "Plateado con dos franjas negras de carreras de punta a punta, faros redondos con aro de luz, piloto de lado a lado y llantas bronce.",
	},
	RavenT7 = {
		Number = 4, Name = "Raven T7", Kind = "Coche", Class = "Deportivo", Rarity = "Epica", Shape = "Muscle", Seats = 4,
		Paint = { 246, 196, 18 }, Secondary = { 16, 16, 18 }, Accent = { 230, 40, 35 }, Glow = { 240, 244, 255 }, Finish = "Gloss",
		Rims = { Style = "Five", Color = { 20, 20, 22 } }, Caliper = { 225, 40, 35 },
		Head = "Grille", Drl = "Bar", Tail = "Split", Exhaust = "Quad", Wing = "Duck", Stripes = "Twin", Scoop = true, BlackRoof = true,
		EnginePitch = 0.78, Plate = "04 VALMAR",
		Blurb = "Muscle car amarillo de silueta propia: capó larguísimo con toma de aire, franjas y techo negros, faros dentro de la parrilla y escape cuádruple.",
	},
	Zenith = {
		Number = 5, Name = "Zenith", Kind = "Coche", Class = "Deportivo", Rarity = "Rara", Shape = "GT", Seats = 2,
		Paint = { 20, 142, 132 }, Secondary = { 18, 30, 32 }, Accent = { 200, 150, 90 }, Glow = { 210, 255, 245 }, Finish = "Metallic",
		Rims = { Style = "Mesh", Color = { 176, 124, 84 } }, Caliper = { 30, 30, 34 },
		Head = "Slim", Drl = "Bar", Tail = "FullWidth", Exhaust = "Twin", Wing = "Lip", SideVents = true,
		Tweak = { Hood = { { -6.75, 2.0 }, { -6.2, 2.42 }, { -4.2, 2.74 }, { -2.3, 2.98 } }, Cabin = { Base = -2.3 } },
		EnginePitch = 1.1, Plate = "05 VALMAR",
		Blurb = "Turquesa con barra de luz de lado a lado delante y detrás, branquias detrás de las ruedas y llantas de malla color cobre.",
	},
	ShadowF1 = {
		Number = 6, Name = "Shadow F1", Kind = "Coche", Class = "Superdeportivo", Rarity = "Legendaria", Shape = "Super", Seats = 2,
		Paint = { 24, 24, 28 }, Secondary = { 12, 12, 14 }, Accent = { 0, 225, 255 }, Glow = { 0, 225, 255 }, Finish = "Matte",
		Rims = { Style = "Ten", Color = { 18, 18, 20 } }, Caliper = { 0, 200, 240 },
		Head = "Slim", Drl = "Arrow", Tail = "FullWidth", Exhaust = "Center", Wing = "Swan", GlowLines = true, Underglow = true,
		Airbox = true, Canards = true, SideIntakes = true, RainLight = true,
		EnginePitch = 1.25, Plate = "06 VALMAR",
		Blurb = "Negro mate con líneas de luz cian por todo el cuerpo, neón bajo el coche, toma de aire en el techo como un monoplaza, alerón de cuello de cisne y luz de lluvia.",
	},
	Inferno = {
		Number = 7, Name = "Inferno", Kind = "Coche", Class = "Superdeportivo", Rarity = "Epica", Shape = "Super", Seats = 2,
		Paint = { 212, 30, 26 }, Secondary = { 18, 18, 20 }, Accent = { 255, 196, 40 }, Glow = { 255, 236, 220 }, Finish = "Gloss",
		Rims = { Style = "Five", Color = { 22, 22, 24 } }, Caliper = { 255, 196, 40 },
		Head = "Sharp", Drl = "Y", Tail = "Y", Exhaust = "Hex", Wing = "GT", HoodVents = 2, SideIntakes = true, Canards = true,
		EnginePitch = 1.15, Plate = "07 VALMAR",
		Blurb = "Superdeportivo rojo fuego: luces en Y delante y detrás, rejillas negras en el capó, tomas laterales enormes y escapes altos.",
	},
	AuroraX = {
		Number = 8, Name = "Aurora X", Kind = "Coche", Class = "Superdeportivo", Rarity = "Legendaria", Shape = "Super", Seats = 2,
		Paint = { 242, 242, 238 }, Secondary = { 16, 16, 18 }, Accent = { 120, 200, 255 }, Glow = { 230, 245, 255 }, Finish = "Gloss",
		Rims = { Style = "Y", Color = { 18, 18, 20 } }, Caliper = { 120, 200, 255 },
		Head = "Slim", Drl = "X", Tail = "X", Exhaust = "Quad", Wing = "Active", Stripes = "Center", BlackRoof = true, SideIntakes = true,
		EnginePitch = 1.2, Plate = "08 VALMAR",
		Blurb = "Blanco con capó, techo y bajos negros, firma de luz en X delante y detrás, alerón activo y pinzas de color.",
	},
	Obsidian = {
		Number = 9, Name = "Obsidian", Kind = "Coche", Class = "Superdeportivo", Rarity = "Epica", Shape = "Super", Seats = 2,
		Paint = { 38, 18, 64 }, Secondary = { 12, 10, 18 }, Accent = { 170, 80, 255 }, Glow = { 170, 80, 255 }, Finish = "Metallic",
		Rims = { Style = "Mesh", Color = { 20, 18, 26 } }, Caliper = { 170, 80, 255 },
		Head = "Sharp", Drl = "Arrow", Tail = "FullWidth", Exhaust = "Quad", Wing = "GT", GlowLines = true, Underglow = true,
		Louvers = true, SideIntakes = true, Tint = { 60, 30, 90 },
		EnginePitch = 1.1, Plate = "09 VALMAR",
		Blurb = "Negro con reflejos morados y brillo violeta: líneas de luz, neón bajo el coche, lamas en la tapa del motor y cristales tintados en violeta.",
	},
	ViboraGT = {
		Number = 10, Name = "Víbora GT", Kind = "Coche", Class = "Superdeportivo", Rarity = "Legendaria", Shape = "Super", Seats = 2,
		Paint = { 30, 150, 62 }, Secondary = { 16, 18, 16 }, Accent = { 250, 220, 40 }, Glow = { 230, 255, 220 }, Finish = "Metallic",
		Rims = { Style = "Ten", Color = { 20, 22, 20 } }, Caliper = { 250, 220, 40 },
		Head = "Sharp", Drl = "Fang", Tail = "Split", Exhaust = "Quad", Wing = "Swan", HoodVents = 2, Bubble = true, SideIntakes = true, Canards = true,
		EnginePitch = 0.98, Plate = "10 VALMAR",
		Blurb = "Verde serpiente: colmillos de luz, techo de doble burbuja, rejillas enormes en el capó, alerón de cuello de cisne y pinzas amarillas.",
	},
	NexusR = {
		Number = 11, Name = "Nexus R", Kind = "Moto", Class = "Moto", Rarity = "Rara", Style = "Naked",
		Paint = { 24, 46, 120 }, Secondary = { 20, 20, 24 }, Accent = { 70, 150, 255 }, Glow = { 190, 225, 255 }, Finish = "Metallic",
		Rims = { Color = { 30, 70, 170 } }, Caliper = { 70, 150, 255 },
		EnginePitch = 1.0, Plate = "11 VLM",
		Blurb = "Naked azul noche: chasis multitubular a la vista, faro LED con anillo de luz, manillar ancho y escape corto.",
	},
	Blaze1000 = {
		Number = 12, Name = "Blaze 1000", Kind = "Moto", Class = "Moto", Rarity = "Epica", Style = "Sport",
		Paint = { 206, 26, 32 }, Secondary = { 18, 18, 20 }, Accent = { 245, 245, 245 }, Glow = { 240, 245, 255 }, Finish = "Gloss",
		Rims = { Color = { 20, 20, 22 } }, Caliper = { 230, 190, 40 },
		EnginePitch = 1.12, Plate = "12 VLM",
		Blurb = "Deportiva roja carenada: doble faro, cúpula ahumada, carenado con rejillas, colín afilado y escape bajo el motor.",
	},
	Storm = {
		Number = 13, Name = "Storm", Kind = "Moto", Class = "Moto", Rarity = "Legendaria", Style = "Sport",
		Paint = { 240, 240, 244 }, Secondary = { 112, 52, 205 }, Accent = { 175, 95, 255 }, Glow = { 175, 95, 255 }, Finish = "Gloss",
		Rims = { Color = { 112, 52, 205 } }, Caliper = { 175, 95, 255 }, Winglets = true, GlowLines = true,
		EnginePitch = 1.2, Plate = "13 VLM",
		Blurb = "Superbike blanca y morada con alerones en el carenado, líneas de luz violeta, llantas moradas y colín con LED.",
	},
}

-- Orden de la hoja del dueño (01..13)
PremiumVehicles.List = {
	"VoltexGTR", "StratoRS", "KairoS", "RavenT7", "Zenith",
	"ShadowF1", "Inferno", "AuroraX", "Obsidian", "ViboraGT",
	"NexusR", "Blaze1000", "Storm",
}

---------------------------------------------------------------------
-- Silueta efectiva (la de su forma + sus retoques) y datos derivados
---------------------------------------------------------------------
local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for key, value in t do
		out[key] = deepCopy(value)
	end
	return out
end
-- Copia de la silueta con los retoques del coche (las listas se sustituyen; las tablas se mezclan)
local function merge(base: { [string]: any }, tweak: { [string]: any }?): { [string]: any }
	local out = deepCopy(base)
	for key, value in tweak or {} do
		if type(value) == "table" and type(out[key]) == "table" and #value == 0 then
			out[key] = merge(out[key], value)
		else
			out[key] = deepCopy(value)
		end
	end
	return out
end

local MOTO_GEOMETRY = {
	Wheels = { Front = -2.4, Rear = 2.3, Radius = 1.0, Width = 0.66, Rim = 1.56 },
	Seat = { 0, 2.45, 0.45 }, -- encima del asiento del piloto
	Pillion = { 0, 2.78, 1.45 },
	Plate = { 0, 1.72, 2.86 },
	Tank = { 0, 2.95, -0.55 }, -- la pieza «Body» (depósito)
}

for id, v in PremiumVehicles.Vehicles do
	v.Id = id
	v.Premium = true
	if v.Kind == "Coche" then
		local shape = merge(SHAPES[v.Shape], v.Tweak)
		v.Geometry = shape
		local w = shape.Wheels
		local seatY = if v.Shape == "Super" then 0.9 elseif v.Shape == "Muscle" then 1.25 else 1.05
		local seatZ = if v.Shape == "Super" then -0.55 elseif v.Shape == "Muscle" then 0.6 else 0.25
		if v.Seats == 4 then
			local rearZ = if v.Shape == "Muscle" then 2.75 else 2.3
			v.SeatLayout = fourSeats(seatY, if v.Shape == "Muscle" then seatZ else 0.1, rearZ)
			if v.Shape ~= "Muscle" then
				shape.CabBack = 3.0
				shape.Cabin.RoofBack = 2.0
				shape.Cabin.Back = 4.85
				shape.Deck = { { 3.0, 2.95 }, { 4.85, 3.18 }, { 6.25, 3.32 }, { 6.75, 3.15 } }
			end
		else
			v.SeatLayout = twoSeats(seatY, seatZ)
		end
		v.Anchors = {
			WheelFL = { -w.X, w.Radius, w.Front },
			WheelFR = { w.X, w.Radius, w.Front },
			WheelRL = { -w.X, w.Radius, w.Rear },
			WheelRR = { w.X, w.Radius, w.Rear },
			PlateFront = { 0, (shape.Hood[1][2] + 0.94) / 2 - 0.12, -6.82 },
			PlateRear = { 0, 1.62, 6.82 },
			Under = { 0, 0.35, 0 },
		}
		v.WheelInfo = { Radius = w.Radius, Width = w.Width, RimDiameter = w.Rim }
		v.Reference = { Name = "Body", Offset = { 0, 0.76, 0 } }
	else
		local g = table.clone(MOTO_GEOMETRY)
		v.Geometry = g
		v.SeatLayout = { Driver = g.Seat, Passengers = { { g.Pillion[1], g.Pillion[2], g.Pillion[3], -1, "Subir detrás", "Pillion" } } }
		v.Anchors = {
			WheelF = { 0, g.Wheels.Radius, g.Wheels.Front },
			WheelR = { 0, g.Wheels.Radius, g.Wheels.Rear },
			PlateRear = g.Plate,
			Under = { 0, 0.45, 0 },
		}
		v.WheelInfo = { Radius = g.Wheels.Radius, Width = g.Wheels.Width, RimDiameter = g.Wheels.Rim }
		v.Reference = { Name = "Body", Offset = g.Tank }
	end
	local base = PremiumVehicles.BaseStats[v.Kind]
	v.Stats = { Velocidad = base.Velocidad, Manejo = base.Manejo, Estetica = AESTHETICS[v.Rarity] or base.Estetica }
end

---------------------------------------------------------------------
-- Consultas
---------------------------------------------------------------------
function PremiumVehicles.get(id: any): { [string]: any }?
	return if type(id) == "string" then PremiumVehicles.Vehicles[id] else nil
end

-- ¿Es «id» un vehículo premium de este tipo? (para Variant de un modelo, el taller…)
function PremiumVehicles.isPremium(kind: any, id: any): boolean
	local v = PremiumVehicles.get(id)
	return v ~= nil and v.Kind == kind
end

-- Zonas del taller para un premium (las de su tipo + sus piezas propias). Las piezas de pintura de
-- los premium se llaman «Panel» (coche) o como las de la moto de siempre; las franjas y techos de
-- color secundario, «Livery». En las llantas, al poner unas del taller se esconden también el
-- disco, la pinza y el fondo oscuro (las nuevas van por delante).
function PremiumVehicles.zones(kind: string): { [string]: { string } }?
	if kind == "Coche" then
		return {
			Primary = { "Body", "Panel", "Roof", "Mirror", "PillarC" },
			Secondary = { "Livery" },
			Glass = { "RearWindow", "SideWindow", "SideWindowFront", "SideWindowRear", "EngineCover" },
			Rim = { "Rim", "RimInner", "Spoke", "Hub", "BrakeDisc", "Caliper" },
			Tire = { "Wheel" },
			PlateRear = { "PlateRear" },
			PlateFront = { "PlateFront" },
		}
	elseif kind == "Moto" then
		return {
			Primary = { "Body", "Tail", "Shield", "FenderFront" },
			Secondary = { "Livery", "SidePanelLine" },
			Rim = { "Rim", "RimInner", "Spoke", "Hub", "BrakeDisc", "Caliper" },
			Tire = { "Wheel" },
			PlateRear = { "Plate" },
		}
	end
	return nil
end

return PremiumVehicles
