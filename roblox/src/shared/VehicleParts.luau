-- VehicleParts: catálogo del «Taller de Tobías» (docs/personalizar-vehiculos.md). SOLO DATOS y
-- funciones puras: sin servicios, sin instancias, sin Color3 (los colores van como {r, g, b}),
-- para que lo usen igual el servidor, el cliente (vista previa) y las pruebas con Lune.
--
-- Decisiones del dueño (definitivas):
--   * «Vida nueva» borra las piezas compradas (las del pase, en Cosmetics, se quedan).
--   * Pintura: paleta fija de 20 colores + 4 acabados (brillante, metalizado, mate, perlado).
--   * Las piezas son SOLO ASPECTO: ninguna pieza lleva velocidad, aceleración, frenada, giro,
--     peso ni nada parecido (scripts/test-vehicleparts.luau lo comprueba). Nada se vende por Robux.
--
-- Cada pieza: Id (lo que se guarda: no cambiarlo nunca), Name (español), Slot (hueco de la
-- Build), Attach (dónde va en el modelo: un ancla de Anchors o «Zone:<zona>» si solo recolorea),
-- Price (€ del juego, precio del coche: moto ×0,6, bici/patinete/monopatín ×0,3), Charge ("Once" =
-- se compra una vez y se queda; "Each" = mano de obra, se paga cada vez), Unlock (Source = "Shop" |
-- "Level" | "Pass"), Kinds (tipos de vehículo), Bodies (carrocerías del coche; nil = todas).
-- Default = true: la pieza de serie (gratis, siempre tuya). Requires = id de un kit que hay que
-- tener (neón y lunas tintadas).
--
-- Usado por shared/VehicleBuild (validar y aplicar una Build a un modelo).

local VehicleParts = {}

-- Interruptor general (como el pase): con false nadie ve el taller. Fase 1 lo enciende.
VehicleParts.Enabled = false

-- Tipos que se pueden personalizar (los de trabajo, alquiler, examen y la calle, no)
VehicleParts.Kinds = { "Coche", "Moto", "Bici", "Patinete", "Monopatin" }
local KIND_SET = {}
for _, kind in VehicleParts.Kinds do
	KIND_SET[kind] = true
end
function VehicleParts.isCustomizable(kind: any): boolean
	return type(kind) == "string" and KIND_SET[kind] == true
end

-- Carrocerías del coche (las de CarModel.Variants)
VehicleParts.Bodies = { "Berlina", "Compacto", "Todoterreno" }

-- Multiplicador de precio por tipo (redondeado a 10 €)
VehicleParts.PriceFactor = { Coche = 1, Moto = 0.6, Bici = 0.3, Patinete = 0.3, Monopatin = 0.3 }

-- Máximo de piezas nuevas (Mod_) por vehículo (móvil primero)
VehicleParts.Budget = { Coche = 70, Moto = 30, Bici = 20, Patinete = 20, Monopatin = 20 }

-- Nombres que otros sistemas buscan por nombre: las piezas nuevas no los usan, y la capa del
-- taller no los mueve, ni los borra, ni los esconde, ni les cambia la colisión.
VehicleParts.Reserved = {
	"Chassis", "DriverSeat", "RideSeat", "PassengerSeat", "Body", "Headlight", "HeadlightRight", "Taillight",
	"ThirdBrake", "Reverse", "Kickstand", "StandWeld", "SirenBlue", "SirenRed", "NamePlate", "BusDoor",
}
function VehicleParts.isReserved(name: string): boolean
	return table.find(VehicleParts.Reserved, name) ~= nil or string.sub(name, 1, 9) == "Indicator"
end
-- «Body» se puede PINTAR (color / material / brillo: es la carrocería), nada más.
VehicleParts.PaintableReserved = { Body = true }

-- Prefijo y atributos de toda pieza nueva
VehicleParts.Prefix = "Mod_"

---------------------------------------------------------------------
-- Zonas: piezas de serie por nombre (fase 0: sin tocar Rides/CarModel)
---------------------------------------------------------------------
VehicleParts.Zones = {
	Coche = {
		Primary = { "Body", "Nose", "Roof", "PillarC", "Mirror" },
		Secondary = { "Mirror", "RoofRail" }, -- (si hay secundaria, pisa a Primary)
		Glass = { "RearWindow", "SideWindow", "SideWindowFront", "SideWindowRear" }, -- el parabrisas NUNCA
		Rim = { "Rim", "Spoke", "Hub" },
		Tire = { "Wheel" },
		BumperF = { "BumperFront" },
		BumperR = { "BumperRear" },
		PlateRear = { "PlateRear" },
		PlateFront = { "PlateFront" },
	},
	Moto = {
		Primary = { "Body", "Tail", "Shield", "FenderFront", "Stem" },
		Secondary = { "SeatPiping", "SidePanelLine" },
		Rim = { "Rim", "Hub" },
		Tire = { "Wheel" },
		PlateRear = { "Plate" },
	},
	Bici = {
		Primary = { "TopTube", "DownTube", "SeatTube", "HeadTube", "ChainStay", "SeatStay", "FenderRear", "FenderFront" },
		Secondary = { "Seat", "Grip" },
		Rim = { "Rim" },
		Tire = { "Wheel" },
	},
	Patinete = {
		Primary = { "Battery", "DeckTrim", "FenderRear", "FenderFront", "Stem" },
		Rim = { "Rim" },
		Tire = { "Wheel" },
	},
	Monopatin = {
		Primary = { "Deck", "Kick" },
		Secondary = { "Bushing" },
		Rim = { "Wheel" }, -- el monopatín no tiene llanta: el «color de llanta» pinta las ruedas
		Tire = { "Wheel" },
	},
}

---------------------------------------------------------------------
-- Anclas: coordenadas locales del vehículo (las de Rides.build: centro a ras de suelo, morro
-- hacia −Z, izquierda = −X, donde va el conductor). Medidas de CarModel (W 6,2 × L 13,5; ruedas
-- r = 1,3 en x = ±2,8, z = ±4,3) y de Rides. La prueba las contrasta con el modelo construido.
---------------------------------------------------------------------
local function carAnchors(trunkZ: number?, roof: { number }, hood: { number })
	return {
		WheelFL = { -2.8, 1.3, -4.3 },
		WheelFR = { 2.8, 1.3, -4.3 },
		WheelRL = { -2.8, 1.3, 4.3 },
		WheelRR = { 2.8, 1.3, 4.3 },
		Trunk = if trunkZ then { 0, 3.3, trunkZ } else nil,
		Roof = roof,
		Hood = hood,
		BumperF = { 0, 1.35, -6.55 },
		BumperR = { 0, 1.35, 6.55 },
		PlateRear = { 0, 2.2, 6.77 },
		PlateFront = { 0, 1.4, -6.87 },
		Under = { 0, 0.35, 0 },
	}
end
VehicleParts.Anchors = {
	Coche = {
		Berlina = carAnchors(5.5, { 0, 5.3, 0.8 }, { 0, 3.3, -4.6 }),
		Compacto = carAnchors(5.8, { 0, 5.4, 1.75 }, { 0, 3.3, -4.7 }),
		Todoterreno = carAnchors(nil, { 0, 6.1, 1.6 }, { 0, 3.5, -4.9 }),
	},
	Moto = { Default = { WheelF = { 0, 1, -2.3 }, WheelR = { 0, 1, 2.3 }, PlateRear = { 0, 1.55, 2.68 }, Under = { 0, 0.45, 0 } } },
	Bici = { Default = { WheelF = { 0, 1.3, -1.8 }, WheelR = { 0, 1.3, 1.8 } } },
	Patinete = { Default = { WheelF = { 0, 0.38, -1.5 }, WheelR = { 0, 0.38, 1.5 }, Under = { 0, 0.2, 0.1 } } },
	Monopatin = {
		Default = { WheelFL = { -0.55, 0.22, -1.3 }, WheelFR = { 0.55, 0.22, -1.3 }, WheelRL = { -0.55, 0.22, 1.3 }, WheelRR = { 0.55, 0.22, 1.3 } },
	},
}
function VehicleParts.anchorsFor(kind: string, body: string?): { [string]: { number } }?
	local byKind = VehicleParts.Anchors[kind]
	if not byKind then
		return nil
	end
	return byKind[body or ""] or byKind.Default or byKind.Berlina
end

-- Ruedas de cada tipo (para construir llantas y bandas): radio, ancho del neumático (a lo largo de
-- X) y diámetro de la llanta de serie.
VehicleParts.Wheels = {
	Coche = { Radius = 1.3, Width = 1.1, RimDiameter = 1.69 },
	Moto = { Radius = 1, Width = 0.6, RimDiameter = 1.3 },
	Bici = { Radius = 1.3, Width = 0.22, RimDiameter = 2.275 },
	Patinete = { Radius = 0.38, Width = 0.3, RimDiameter = 0.5 },
	Monopatin = { Radius = 0.22, Width = 0.22, RimDiameter = 0.44 },
}

-- Pieza de serie que sirve para saber dónde está el vehículo ANTES de Rides.prepare (sin Chassis):
-- nombre y su posición local (todas se crean sin giro respecto al CFrame de construcción).
VehicleParts.Reference = {
	Coche = { Name = "Body", Offset = { 0, 2.2, 0 } },
	Moto = { Name = "Body", Offset = { 0, 1.65, 0.9 } },
	Bici = { Name = "Seat", Offset = { 0, 3.23, 0.85 } },
	Patinete = { Name = "Deck", Offset = { 0, 0.58, 0.1 } },
	Monopatin = { Name = "Deck", Offset = { 0, 0.55, 0 } },
}

---------------------------------------------------------------------
-- Catálogo
---------------------------------------------------------------------
VehicleParts.Parts = {} :: { [string]: { [string]: any } }
VehicleParts.List = {} :: { { [string]: any } }

local ALL = { "Coche", "Moto", "Bici", "Patinete", "Monopatin" }
local SHOP = { Source = "Shop" }

local function add(part: { [string]: any })
	assert(VehicleParts.Parts[part.Id] == nil, "pieza repetida: " .. tostring(part.Id))
	part.Charge = part.Charge or "Once"
	part.Unlock = part.Unlock or SHOP
	part.Price = part.Price or 0
	VehicleParts.Parts[part.Id] = part
	table.insert(VehicleParts.List, part)
end

-- Pinturas: la paleta fija de 20 colores. El color no se cobra: se cobra la mano de obra del
-- acabado (Finish) cada vez que se pinta.
local PAINTS = {
	{ "P_BlancoGlaciar", "Blanco Glaciar", 240, 242, 245 },
	{ "P_NegroNoche", "Negro Noche", 22, 22, 26 },
	{ "P_GrisPlata", "Gris Plata", 175, 180, 188 },
	{ "P_Grafito", "Grafito", 70, 72, 78 },
	{ "P_RojoValmar", "Rojo Valmar", 190, 30, 40 },
	{ "P_Granate", "Granate", 110, 20, 35 },
	{ "P_NaranjaAtardecer", "Naranja Atardecer", 240, 120, 40 },
	{ "P_AmarilloLimon", "Amarillo Limón", 240, 210, 50 },
	{ "P_VerdeVillaverde", "Verde Villaverde", 60, 150, 80 },
	{ "P_VerdeMenta", "Verde Menta", 150, 220, 180 },
	{ "P_TurquesaBrisa", "Turquesa Brisa", 60, 190, 200 },
	{ "P_AzulPuerto", "Azul Puerto", 30, 90, 170 },
	{ "P_AzulMarino", "Azul Marino", 20, 35, 80 },
	{ "P_Celeste", "Celeste", 130, 190, 240 },
	{ "P_MoradoUva", "Morado Uva", 100, 50, 140 },
	{ "P_RosaChicle", "Rosa Chicle", 240, 120, 170 },
	{ "P_ArenaPlayaDorada", "Arena de Playa Dorada", 220, 195, 145 },
	{ "P_Cafe", "Café", 110, 75, 50 },
	{ "P_OroViejo", "Oro Viejo", 190, 150, 60 },
	{ "P_Cobre", "Cobre", 180, 100, 60 },
}
for _, row in PAINTS do
	add({ Id = row[1], Name = row[2], Slot = "Paint", Attach = "Zone:Primary", Kinds = ALL, Color = { row[3], row[4], row[5] }, Price = 0, Charge = "Each" })
end
-- Pinturas especiales del pase (las VehicleSkin de la temporada 1): solo para su tipo, no se
-- compran; se tienen si la recompensa (Reward) está en Cosmetics.Owned.
local PASS_PAINTS = {
	{ "P_BrisaMarina", "Brisa Marina", "Patinete", "S1_P05", 80, 200, 210 },
	{ "P_VerdeVillaverdeBici", "Verde Villaverde (pase)", "Bici", "S1_F15", 60, 150, 80 },
	{ "P_BrisaPlayaDorada", "Brisa de Playa Dorada", "Moto", "S1_P15", 250, 190, 70 },
	{ "P_PerlaFaro", "Perla Faro", "Coche", "S1_P50_Car", 245, 242, 232 },
}
for _, row in PASS_PAINTS do
	add({ Id = row[1], Name = row[2], Slot = "Paint", Attach = "Zone:Primary", Kinds = { row[3] }, Color = { row[5], row[6], row[7] }, Unlock = { Source = "Pass", Reward = row[4] }, Charge = "Each" })
end
VehicleParts.PaletteSize = #PAINTS

-- Acabados (mano de obra de pintar: se paga cada vez que cambia la pintura o el acabado)
add({ Id = "F_Brillante", Name = "Brillante", Slot = "Finish", Attach = "Zone:Primary", Kinds = ALL, Price = 250, Charge = "Each", Default = true, Material = "SmoothPlastic", Reflectance = 0.08, Lighten = 0 })
add({ Id = "F_Mate", Name = "Mate", Slot = "Finish", Attach = "Zone:Primary", Kinds = ALL, Price = 450, Charge = "Each", Material = "SmoothPlastic", Reflectance = 0, Lighten = 0 })
add({ Id = "F_Metalizado", Name = "Metalizado", Slot = "Finish", Attach = "Zone:Primary", Kinds = ALL, Price = 550, Charge = "Each", Material = "SmoothPlastic", Reflectance = 0.25, Lighten = 0 })
add({ Id = "F_Perlado", Name = "Perlado", Slot = "Finish", Attach = "Zone:Primary", Kinds = ALL, Price = 850, Charge = "Each", Material = "SmoothPlastic", Reflectance = 0.35, Lighten = 0.08 })

-- Pintura secundaria: cualquier color de la paleta (Paint2 = id de pintura); mano de obra fija
VehicleParts.Labour = { Paint2 = 150 }
VehicleParts.Paint2Kinds = { Coche = true, Moto = true, Bici = true, Monopatin = true }

-- Llantas: 12 diseños para el coche (4 también para la moto). Design = cómo se construyen (≤ 8
-- piezas por rueda): Lip = aro exterior del color de la llanta; Face = disco de dentro ("Dark",
-- "Color" o "White"); Arms = radios (Through = de lado a lado), Width/Tilt/Pair = forma de los
-- radios (fracción del radio de la llanta, grados); Hub = tamaño del buje.
local CAR, CAR_MOTO = { "Coche" }, { "Coche", "Moto" }
add({ Id = "Rims_Serie", Name = "De serie", Slot = "Rims", Attach = "Wheels", Kinds = ALL, Default = true, Design = nil })
add({ Id = "Rims_Clasica5", Name = "Clásica 5", Slot = "Rims", Attach = "Wheels", Kinds = CAR_MOTO, Price = 400, Design = { Lip = true, Face = "Dark", Arms = 5, Width = 0.26, Hub = 0.4 } })
add({ Id = "Rims_Estrella6", Name = "Estrella 6", Slot = "Rims", Attach = "Wheels", Kinds = CAR_MOTO, Price = 600, Design = { Lip = true, Face = "Dark", Arms = 3, Through = true, Width = 0.18, Hub = 0.35 } })
add({ Id = "Rims_Deportiva10", Name = "Deportiva 10", Slot = "Rims", Attach = "Wheels", Kinds = CAR_MOTO, Price = 900, Design = { Lip = true, Face = "Dark", Arms = 5, Through = true, Width = 0.1, Hub = 0.3 } })
add({ Id = "Rims_RadiosY", Name = "Radios finos en Y", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 800, Design = { Lip = false, Face = "Dark", Arms = 6, Pair = 18, Width = 0.08, Hub = 0.32 } })
add({ Id = "Rims_Malla", Name = "Malla cruzada", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 1500, Unlock = { Source = "Level", Level = 8 }, Design = { Lip = false, Face = "Dark", Arms = 6, Through = true, Width = 0.07, Hub = 0.3 } })
add({ Id = "Rims_Turbina", Name = "Turbina", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 1500, Unlock = { Source = "Level", Level = 10 }, Design = { Lip = true, Face = "Dark", Arms = 5, Width = 0.3, Tilt = 30, Hub = 0.35 } })
add({ Id = "Rims_Monobloque", Name = "Monobloque", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 700, Design = { Lip = true, Face = "Color", Arms = 0, Hub = 0.45 } })
add({ Id = "Rims_Helice", Name = "Hélice", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 1000, Design = { Lip = true, Face = "Dark", Arms = 3, Width = 0.5, Tilt = 35, Hub = 0.4 } })
add({ Id = "Rims_Retro", Name = "Tapacubos retro", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 500, Design = { Lip = true, Face = "White", Arms = 0, Hub = 0.5 } })
add({ Id = "Rims_Todoterreno", Name = "Todoterreno", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Price = 800, Design = { Lip = true, Face = "Dark", Arms = 5, Width = 0.34, Hub = 0.55 } })
add({ Id = "Rims_Faro", Name = "Faro dorada", Slot = "Rims", Attach = "Wheels", Kinds = CAR, Unlock = { Source = "Pass", Reward = "S1_P50_Car" },
	Design = { Lip = true, Face = "Dark", Arms = 5, Width = 0.22, Hub = 0.4, FixedColor = { 255, 196, 64 }, FixedMaterial = "Metal" } })

-- Color de las llantas (mano de obra, cada vez). En bici, patinete y monopatín pinta las de serie.
add({ Id = "RC_Cromo", Name = "Cromo", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", Default = true, Color = { 205, 208, 214 }, Material = "Metal" })
add({ Id = "RC_Negro", Name = "Negro", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", Color = { 25, 25, 28 }, Material = "SmoothPlastic" })
add({ Id = "RC_Grafito", Name = "Grafito", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", Color = { 70, 72, 78 }, Material = "Metal" })
add({ Id = "RC_Bronce", Name = "Bronce", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", Color = { 150, 110, 60 }, Material = "Metal" })
add({ Id = "RC_Blanco", Name = "Blanco", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", Color = { 235, 235, 235 }, Material = "SmoothPlastic" })
add({ Id = "RC_Carroceria", Name = "Color carrocería", Slot = "RimColor", Attach = "Wheels", Kinds = ALL, Price = 100, Charge = "Each", UsePaint = true, Material = "SmoothPlastic" })

-- Neumáticos (coche): bandas en el costado de fuera (el tamaño de la rueda no cambia)
add({ Id = "T_Normal", Name = "Normal", Slot = "Tires", Attach = "Wheels", Kinds = CAR, Default = true })
add({ Id = "T_LetrasBlancas", Name = "Letras blancas", Slot = "Tires", Attach = "Wheels", Kinds = CAR, Price = 300, Band = { Outer = 2.35, Inner = 2.15, Color = { 225, 225, 220 } } })
add({ Id = "T_BandaBlanca", Name = "Banda blanca clásica", Slot = "Tires", Attach = "Wheels", Kinds = CAR, Price = 450, Band = { Outer = 2.2, Color = { 245, 245, 240 } } })

-- Alerones (coche, en la tapa trasera; el todoterreno no lleva y el compacto solo el labio)
add({ Id = "Sp_Labio", Name = "Labio", Slot = "Spoiler", Attach = "Trunk", Kinds = CAR, Bodies = { "Berlina", "Compacto" }, Price = 600 })
add({ Id = "Sp_Deportivo", Name = "Deportivo", Slot = "Spoiler", Attach = "Trunk", Kinds = CAR, Bodies = { "Berlina" }, Price = 900 })
add({ Id = "Sp_GT", Name = "GT", Slot = "Spoiler", Attach = "Trunk", Kinds = CAR, Bodies = { "Berlina" }, Price = 1400, Unlock = { Source = "Level", Level = 15 } })

-- Parachoques: 2 por carrocería en cada punta (el de serie y otro). Replaces = esconde el de
-- serie (sigue ahí, invisible: la colisión no cambia); si no, se añade delante.
add({ Id = "BF_Serie", Name = "Delantero de serie", Slot = "BumperF", Attach = "BumperF", Kinds = CAR, Default = true })
add({ Id = "BR_Serie", Name = "Trasero de serie", Slot = "BumperR", Attach = "BumperR", Kinds = CAR, Default = true })
add({ Id = "BF_Deportivo", Name = "Delantero deportivo", Slot = "BumperF", Attach = "BumperF", Kinds = CAR, Bodies = { "Berlina", "Compacto" }, Price = 700, Replaces = true })
add({ Id = "BR_Deportivo", Name = "Trasero deportivo", Slot = "BumperR", Attach = "BumperR", Kinds = CAR, Bodies = { "Berlina", "Compacto" }, Price = 700, Replaces = true })
add({ Id = "BF_Defensa", Name = "Defensa delantera", Slot = "BumperF", Attach = "BumperF", Kinds = CAR, Bodies = { "Todoterreno" }, Price = 700 })
add({ Id = "BR_Defensa", Name = "Defensa trasera", Slot = "BumperR", Attach = "BumperR", Kinds = CAR, Bodies = { "Todoterreno" }, Price = 700 })

-- Lunas tintadas (coche): el kit se compra una vez; el nivel (Tint 0..3) se cambia gratis.
-- El parabrisas no se tinta nunca (se tiene que ver al conductor).
add({ Id = "Kit_Tint", Name = "Lunas tintadas", Slot = "Kit", Attach = "Zone:Glass", Kinds = CAR, Price = 300 })
VehicleParts.Tints = {
	[0] = { Name = "Sin tintar", Transparency = 0.35, Darken = 0 },
	[1] = { Name = "Claro", Transparency = 0.25, Darken = 0.2 },
	[2] = { Name = "Medio", Transparency = 0.15, Darken = 0.4 },
	[3] = { Name = "Oscuro", Transparency = 0.08, Darken = 0.6 },
}
VehicleParts.MaxTint = 3

-- Neón bajo el vehículo: el kit una vez; el color, cada vez que se cambia
add({ Id = "Kit_Neon", Name = "Neón bajo el vehículo", Slot = "Kit", Attach = "Under", Kinds = { "Coche", "Moto", "Patinete" }, Price = 1200 })
local NEONS = {
	{ "N_Cian", "Cian", 0, 230, 255 },
	{ "N_Azul", "Azul", 40, 90, 255 },
	{ "N_Rosa", "Rosa", 255, 80, 190 },
	{ "N_Morado", "Morado", 160, 70, 255 },
	{ "N_Verde", "Verde", 60, 255, 120 },
	{ "N_Rojo", "Rojo", 255, 40, 40 },
	{ "N_Blanco", "Blanco", 240, 240, 255 },
	{ "N_Ambar", "Ámbar", 255, 170, 40 },
}
for _, row in NEONS do
	add({ Id = row[1], Name = "Neón " .. string.lower(row[2]), Slot = "Neon", Attach = "Under", Kinds = { "Coche", "Moto", "Patinete" }, Price = 150, Charge = "Each", Requires = "Kit_Neon", Color = { row[3], row[4], row[5] } })
end

-- Carrocería (coche). Hoy Rides.coche siempre saca una berlina: cambiarla necesita la fase 2
-- (Rides.coche con variante). La Build ya la guarda y el taller la valida.
add({ Id = "Body_Berlina", Name = "Berlina", Slot = "Body", Attach = "Body", Kinds = CAR, Default = true, Body = "Berlina" })
add({ Id = "Body_Compacto", Name = "Compacto", Slot = "Body", Attach = "Body", Kinds = CAR, Price = 2000, Body = "Compacto" })
add({ Id = "Body_Todoterreno", Name = "Todoterreno", Slot = "Body", Attach = "Body", Kinds = CAR, Price = 2000, Body = "Todoterreno" })

-- Matrícula personalizada (coche y moto): 1–8 caracteres A-Z, 0-9 y espacios, en mayúsculas.
-- Es texto de jugador que ven otros: el servidor la pasa SIEMPRE por NameFilter.check y por el
-- filtro de Roblox (TextService) antes de guardarla. Aquí solo se mira el formato.
VehicleParts.Plate = { MinLength = 1, MaxLength = 8, Pattern = "^[A-Z0-9 ]+$", Kinds = { Coche = true, Moto = true }, FirstPrice = 500, ChangePrice = 150 }

-- Deja la matrícula en su forma guardada (mayúsculas, sin espacios a los lados ni dobles) o
-- devuelve nil y el motivo.
function VehicleParts.plateText(text: any): (string?, string?)
	if type(text) ~= "string" then
		return nil, "La matrícula tiene que ser texto."
	end
	if #text > 64 then
		return nil, "La matrícula es demasiado larga (máximo 8)."
	end
	local clean = string.upper(text)
	clean = string.gsub(clean, "^%s+", "")
	clean = string.gsub(clean, "%s+$", "")
	clean = string.gsub(clean, "%s+", " ")
	local rules = VehicleParts.Plate
	if #clean < rules.MinLength then
		return nil, "Escribe al menos un carácter."
	end
	if #clean > rules.MaxLength then
		return nil, "La matrícula es demasiado larga (máximo 8)."
	end
	if not string.match(clean, rules.Pattern) then
		return nil, "Solo letras (sin tildes ni ñ), números y espacios."
	end
	return clean, nil
end

---------------------------------------------------------------------
-- Consultas
---------------------------------------------------------------------
function VehicleParts.get(id: any): { [string]: any }?
	if type(id) ~= "string" then
		return nil
	end
	return VehicleParts.Parts[id]
end

-- ¿Vale esta pieza para este tipo (y carrocería, si es de coche)?
function VehicleParts.fits(part: { [string]: any }, kind: string, body: string?): boolean
	if not table.find(part.Kinds, kind) then
		return false
	end
	if part.Bodies and kind == "Coche" then
		return table.find(part.Bodies, body or "Berlina") ~= nil
	end
	return true
end

-- Clave con la que se guarda una pieza comprada (data.Garage.Parts): una vez por tipo
function VehicleParts.ownKey(kind: string, id: string): string
	return kind .. ":" .. id
end

-- ¿La tiene? owned = conjunto de claves: "Coche:Rims_Estrella6", "*:Rims_X" (todos los tipos) y,
-- para las del pase, el id de la recompensa ("S1_P50_Car") o el de la pieza.
function VehicleParts.isOwned(part: { [string]: any }, kind: string, owned: { [string]: any }?): boolean
	if part.Default then
		return true
	end
	local set = if type(owned) == "table" then owned else {}
	if part.Unlock.Source == "Pass" then
		return set[part.Id] == true or (part.Unlock.Reward ~= nil and set[part.Unlock.Reward] == true) or set[VehicleParts.ownKey(kind, part.Id)] == true or set["*:" .. part.Id] == true
	end
	return set[VehicleParts.ownKey(kind, part.Id)] == true or set["*:" .. part.Id] == true
end

-- ¿Se puede llevar puesta? Las de serie siempre; las de mano de obra de la tienda (pintura,
-- acabado, color de llanta, color de neón) se pagan al aplicarlas, así que no hace falta
-- «tenerlas»; el resto, sí. Además, su kit (Requires).
function VehicleParts.isUsable(part: { [string]: any }, kind: string, owned: { [string]: any }?): boolean
	if part.Requires then
		local kit = VehicleParts.Parts[part.Requires]
		if not kit or not VehicleParts.isOwned(kit, kind, owned) then
			return false
		end
	end
	if part.Charge == "Each" and part.Unlock.Source ~= "Pass" then
		return true
	end
	return VehicleParts.isOwned(part, kind, owned)
end

-- ¿Se puede comprar ahora? (nivel de personaje, pase)
function VehicleParts.canBuy(part: { [string]: any }, kind: string, level: number?): (boolean, string?)
	if not VehicleParts.fits(part, kind, nil) and not (part.Bodies and table.find(part.Kinds, kind)) then
		return false, "No vale para este vehículo."
	end
	if part.Unlock.Source == "Pass" then
		return false, "Se consigue en el pase de temporada."
	end
	if part.Unlock.Source == "Level" and (level or 0) < (part.Unlock.Level or 0) then
		return false, ("Necesitas nivel %d."):format(part.Unlock.Level)
	end
	return true, nil
end

-- Precio de una pieza para un tipo de vehículo (redondeado a 10 €)
function VehicleParts.priceFor(amount: number, kind: string): number
	local factor = VehicleParts.PriceFactor[kind] or 1
	if factor == 1 then
		return amount
	end
	return math.floor(amount * factor / 10 + 0.5) * 10
end

-- Cuánto cuesta pasar de una Build a otra (las dos ya validadas). owned = lo que ya tiene.
-- Devuelve el total y el desglose { { Id, Name, Price } }.
function VehicleParts.price(kind: string, from: { [string]: any }?, to: { [string]: any }, owned: { [string]: any }?): (number, { { [string]: any } })
	local before = from or {}
	local lines = {}
	local total = 0
	local function charge(id: string, name: string, amount: number)
		local p = VehicleParts.priceFor(amount, kind)
		if p > 0 then
			table.insert(lines, { Id = id, Name = name, Price = p })
			total += p
		end
	end
	local function changed(field: string): boolean
		return (before[field] or "") ~= (to[field] or "")
	end
	-- Pintar (color o acabado): la mano de obra del acabado, una vez
	if changed("Paint") or changed("Finish") then
		local finish = VehicleParts.Parts[to.Finish or ""] or VehicleParts.Parts.F_Brillante
		charge(finish.Id, "Pintura (" .. string.lower(finish.Name) .. ")", finish.Price)
	end
	if changed("Paint2") and (to.Paint2 or "") ~= "" then
		charge("Paint2", "Pintura secundaria", VehicleParts.Labour.Paint2)
	end
	for _, field in { "Body", "Rims", "RimColor", "Tires", "Spoiler", "BumperF", "BumperR", "Neon" } do
		local id = to[field]
		if not changed(field) or type(id) ~= "string" or id == "" then
			continue
		end
		local part = VehicleParts.Parts[id]
		if not part or part.Default or part.Unlock.Source == "Pass" then
			continue
		end
		if part.Charge == "Each" or not VehicleParts.isOwned(part, kind, owned) then
			charge(part.Id, part.Name, part.Price)
		end
		-- el kit, si hace falta y no lo tiene
		if part.Requires then
			local kit = VehicleParts.Parts[part.Requires]
			if kit and not VehicleParts.isOwned(kit, kind, owned) then
				charge(kit.Id, kit.Name, kit.Price)
			end
		end
	end
	if (to.Tint or 0) > 0 and not VehicleParts.isOwned(VehicleParts.Parts.Kit_Tint, kind, owned) then
		charge("Kit_Tint", VehicleParts.Parts.Kit_Tint.Name, VehicleParts.Parts.Kit_Tint.Price)
	end
	if changed("Plate") and (to.Plate or "") ~= "" then
		charge("Plate", "Matrícula personalizada", if (before.Plate or "") == "" then VehicleParts.Plate.FirstPrice else VehicleParts.Plate.ChangePrice)
	end
	return total, lines
end

return VehicleParts
