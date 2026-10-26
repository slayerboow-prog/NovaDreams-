-- TÁLASA · la superficie del planeta océano (docs/planetas/diseno-mundos.md §3.3; marco común:
-- docs/planetas/marco-planetas.md; lo jugable ahora: docs/planetas/talasa-vertice.md). Cuentas puras con
-- shared/Cosmos/PlanetSurface.new (mismas funciones que shared/Cosmos/Tefra).
--
-- Tálasa ES el mar: el fondo está bajo el agua en toda la zona, salvo unos islotes de roca coralina y la
-- Ballena Dormida (el esqueleto gigante donde vive un pueblo de pescadores). La capital, Abisalia, es un
-- barrio de cubiertas sobre pilotes y balsas (shared/Cosmos/TalasaCity). En el cielo verde azulado, tres
-- lunas pequeñas y el Archipiélago Suspendido (islas que flotan, con cascadas que caen al mar).
--
-- La desventaja (§3.3.11): la PRESIÓN. Sube bajo el agua (más cuanto más hondo), y en la superficie
-- durante las tormentas eléctricas si estás al descubierto. Contramedidas: el traje de presión (equipo),
-- la carga de oxígeno (consumible) y las compuertas estancas (refugios). Nunca mata: si se llena, te
-- desmayas y despiertas en la compuerta más cercana sin perder nada.
-- El oficio propio: técnico/a de presión (válvulas de las compuertas con las mareas, §3.3.9).

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local Registry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.TalasaCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local WATER = 20

-- Islotes de roca coralina (lo único que asoma del mar): { X, Z, R, H }
local ISLETS = {
	{ X = -430, Z = 380, R = 90, H = 14, Name = "Ballena Dormida" },
	{ X = -360, Z = -300, R = 70, H = 12 },
	{ X = 440, Z = 230, R = 64, H = 10 },
	{ X = -180, Z = 560, R = 56, H = 9 },
	{ X = 560, Z = -420, R = 72, H = 12 },
}

local S = PlanetSurface.new({
	Id = "Talasa",
	Name = "Tálasa",
	Origin = Registry.Slots.Talasa,
	Half = 1024,
	Seed = 33,
	WaterY = WATER,
	PadY = WATER + 14, -- (las cubiertas de Abisalia, sobre pilotes a 14 studs del agua)
	City = City,
	Terrain = { Edge = 0 }, -- (el mar llega hasta el horizonte: sin colinas en el borde)
	rawHeight = function(lx: number, lz: number, _S: any): number
		-- el fondo: 30 studs de agua de media, con dunas de arena y praderas más someras al este
		local h = WATER - 30 + 7 * fbm(lx, lz, 4, 1 / 260, 3.3)
		h += 12 * smooth(140, 260, lx) * smooth(520, 200, math.abs(lz - 120)) * smooth(700, 420, lx) -- Praderas de Luz
		h -= 26 * smooth(380, 720, math.sqrt(lx * lx + lz * lz)) -- (más lejos, más hondo: el Bosque de Columnas)
		for _, i in ISLETS do
			local d = math.sqrt((lx - i.X) ^ 2 + (lz - i.Z) ^ 2)
			local k = smooth(i.R * 1.6, i.R * 0.5, d)
			if k > 0 then
				h = h + (WATER + i.H + 4 * fbm(lx, lz, 3, 1 / 60, 9.1) - h) * k
			end
		end
		return h
	end,
	materialAt = function(lx: number, lz: number, y: number, slope: number, _S: any): string
		if y > WATER + 2 then
			return if slope > 0.7 then "Limestone" else (if fbm(lx, lz, 2, 1 / 40, 4.4) > 0.15 then "LeafyGrass" else "Sandstone")
		elseif y > WATER - 6 then
			return "Sand"
		elseif slope > 0.6 then
			return "Limestone"
		end
		return if fbm(lx, lz, 3, 1 / 90, 7.7) > 0.25 then "Salt" else "Sand"
	end,
	-- (los pinta solo el cliente que está en Tálasa: Controllers/TerrainPaletteClient)
	TerrainColors = {
		Sand = rgb(226, 220, 196), -- arena blanca del fondo
		Salt = rgb(238, 150, 160), -- praderas de coral rosa
		Limestone = rgb(208, 196, 180), -- roca coralina
		Sandstone = rgb(214, 200, 168),
		LeafyGrass = rgb(90, 170, 120), -- algas de los islotes
	},
	WaterColor = rgb(32, 168, 172), -- turquesa
	POIs = {
		{ Id = "Talasa_Plataforma", Name = "Plataforma de Abisalia", X = 0, Z = 0, Flat = 40, Pad = true, Text = "La plataforma de Abisalia: cubierta sobre pilotes en mitad del mar." },
		-- (Flat = 0: no aplanan el fondo; sus avisos los pone el kit en el fondo, bajo la boya)
		{ Id = "Talasa_Muestra1", Name = "Coral negro (muestra 1)", X = 200, Z = 150, Flat = 0, Seabed = true, Action = "Tomar muestra", Text = "🧪 Muestra de coral negro: late, como si tuviera pulso." },
		{ Id = "Talasa_Muestra2", Name = "Coral negro (muestra 2)", X = 236, Z = 112, Flat = 0, Seabed = true, Action = "Tomar muestra", Text = "🧪 Muestra de coral negro: se ha comido media hélice de una barca." },
		{ Id = "Talasa_Muestra3", Name = "Coral negro (muestra 3)", X = 196, Z = 196, Flat = 0, Seabed = true, Action = "Tomar muestra", Text = "🧪 Muestra de coral negro: al acercar la linterna, se encoge." },
		{ Id = "Talasa_Ballena", Name = "La Ballena Dormida", X = -430, Z = 380, Flat = 30, Text = "El esqueleto de una criatura enorme, varado en un islote. Dentro vive un pueblo de pescadores." },
		{ Id = "Talasa_Cementerio", Name = "Cementerio de Submarinos", X = 380, Z = -300, Flat = 0, Seabed = true, Action = "Examinar", Text = "Cascos de submarinos viejos en el fondo, comidos por el coral negro. Ninguno tiene nombre ya." },
	},
	NodeCount = 5,
	NodeOres = { { Id = "Cobalto", Weight = 2 }, { Id = "Cristal", Weight = 1 } },
	DecorCounts = { Palmera = 10, Coral = 14 },
	DecorSlope = { Palmera = 0.5, Coral = 0.9 },
	Islets = ISLETS,
})

S.Kit = "TalasaKit"

-- El cielo verde azulado, el sol blanco y la bruma salada (nombres de DayGrade)
S.Env = {
	Sky = { "CieloTalasa", "Original" },
	Clouds = true,
	Mood = {
		Brightness = 2.6,
		Exposure = 0.05,
		Ambient = rgb(70, 104, 112),
		Outdoor = rgb(136, 186, 190),
		EnvDiffuse = 0.8,
		EnvSpecular = 1,
		Shadow = 0.2,
		SunTint = rgb(40, 70, 60),
		ShadeTint = rgb(12, 40, 60),
		Density = 0.3,
		Offset = 0.12,
		AtmColor = rgb(170, 226, 214),
		Decay = rgb(70, 140, 150),
		Glare = 0.4,
		Haze = 1.6,
		Tint = rgb(236, 255, 250),
		Saturation = 0.06,
		Contrast = 0.1,
		CCBright = 0.02,
		Bloom = 0.9,
		BloomSize = 28,
		Threshold = 1.3,
		Rays = 0.12,
		RaysSpread = 0.4,
		Cover = 0.38,
		CloudDensity = 0.34,
		CloudColor = rgb(214, 238, 236), -- nubes de mar, verdosas
		Veil = 0,
		Overcast = 0,
	},
}

---------------------------------------------------------------------
-- La desventaja: la PRESIÓN
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Presion",
	Name = "Presión",
	Icon = "🌊",
	Max = 100,
	Warn = 60,
	Danger = 85,
	ZoneRate = { Agua = 0.8, Hondo = 2.6, Fondo = 4.4 },
	Exposed = 1.6, -- (al descubierto en la tormenta eléctrica)
	Recovery = 3,
	Gear = {
		Talasa_TrajePresion1 = { Level = 1, Factor = 0.6 },
		Talasa_TrajePresion2 = { Level = 2, Factor = 0.35 },
	},
	Consumable = { Item = "Talasa_CargaOxigeno", Drop = 45, Seconds = 60, Factor = 0.25 },
	Labels = { Normal = "Presión", Aviso = "Cuidado: presión alta", Peligro = "¡Peligro! El casco cruje" },
})
S.HazardTint = rgb(40, 120, 200)
S.HazardHints = {
	Normal = "Bajo el agua sube. Las compuertas la bajan.",
	Aviso = "Sube despacio o usa una carga de oxígeno 🫧",
	Peligro = "¡Sube ya! O una carga de oxígeno de la mochila",
}
S.HazardToasts = {
	Aviso = "🌊 La presión aprieta: el cristal del casco cruje. Sube despacio o usa una 🫧 carga de oxígeno.",
	Peligro = "⚠ ¡Demasiada presión! Pierdes fuerzas: sube a la superficie o métete en una compuerta.",
}
S.KnockText = "💫 La presión te ha dejado sin aire."
S.CounterText = "🫧 Carga de oxígeno: respiras hondo y la presión baja de golpe (y durante un minuto casi no sube)"

-- Lo que rodea al jugador: bajo el agua (cuánto) o al descubierto en la tormenta
local DEPTH_AGUA, DEPTH_HONDO, DEPTH_FONDO = 2, 9, 24
function S.depthAt(pos: Vector3): number
	return (S.Origin.Y + S.WaterY) - pos.Y
end
function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local depth = S.depthAt(pos)
	local ctx: { [string]: any } = { Near = {} }
	if depth > DEPTH_FONDO then
		ctx.Zone = "Fondo"
	elseif depth > DEPTH_HONDO then
		ctx.Zone = "Hondo"
	elseif depth > DEPTH_AGUA then
		ctx.Zone = "Agua"
	elseif City.storm(info.Clock or 12) then
		-- en la tormenta: al descubierto (sobre las cubiertas, fuera de un edificio)
		local lx, lz = S.toLocal(pos)
		ctx.Exposed = City.buildingAt(lx, lz, 0) == nil
	end
	return ctx
end
S.HazardDepths = { Agua = DEPTH_AGUA, Hondo = DEPTH_HONDO, Fondo = DEPTH_FONDO }

-- El momento (para el sonido: Soundscapes.Planets.Talasa.Modes)
function S.moment(clock: number, pos: Vector3?): string?
	if pos and S.depthAt(pos) > DEPTH_AGUA then
		return "Buceo"
	end
	if City.storm(clock) then
		return "Tormenta"
	end
	return nil
end

-- Lo que cae del cielo: rocío de mar, y en la tormenta, lluvia gorda (PlanetClient: Mode)
S.Fx = {
	{ Name = "Rocio", Color = rgb(220, 250, 255), Size = 0.18, Rate = 14 },
	{ Name = "Lluvia", Color = rgb(190, 220, 235), Size = 0.3, Rate = 60, Mode = "Tormenta" },
}

S.CrowdLines = {
	"¿Tú también vienes de abajo?",
	"Dicen que el coral negro ya ha llegado al Mercado.",
	"Mira mis pecas: hoy casi no brillan.",
	"Marea alta en diez minutos. A la compuerta, que no te pille fuera.",
	"Una perla por cada vecino que no vuelve. Ya no quedan perlas.",
	"El Consejo vota esta noche. Otra vez.",
	"Mi hija está en la Cúpula Honda. Nadie nos dice nada.",
	"¿Un barco? Ni lo sueñes. Los ha comprado todos la Corona.",
	"Si oyes crujir el agua, sube. No preguntes, sube.",
	"Gracias por venir. De verdad. Aquí ya no viene nadie.",
}

---------------------------------------------------------------------
-- El oficio propio: técnico/a de presión (§3.3.9)
---------------------------------------------------------------------
-- Las válvulas de las compuertas (junto a sus puertas, por fuera) y el cuadro del Faro (donde se cobra)
S.Valves = {
	{ Id = "Faro", Name = "la Compuerta del Faro", At = { 84, 26 } },
	{ Id = "Balsas", Name = "la Compuerta de las Balsas", At = { -128, 72 } },
	{ Id = "Estacion", Name = "la cámara de la Estación Meridiana", At = { 16, -90 } },
	{ Id = "Muelle", Name = "los pilotes del Muelle", At = { 132, 124 } },
	{ Id = "Jardin", Name = "la bomba del Jardín de algas", At = { 104, 66 } },
}
S.JobBoard = { 64, 16 }
PlanetJobs.register({
	{
		Id = "TalasaTecnicoPresion",
		Planet = "Talasa",
		PlanetName = "Tálasa",
		Name = "Técnico/a de presión",
		Icon = "🔧",
		Desc = "La marea sube y baja cada pocos minutos: ajusta la presión de las válvulas de las compuertas antes de que cambie.",
		Pay = 55,
		MinSeconds = 35,
		Board = S.JobBoard,
		BoardFace = { -1, 0 },
		Place = "Abisalia (Tálasa)",
		EnergyCost = 3,
		CarryColor = rgb(240, 200, 60),
		Drop = { Item = "Talasa_Nacar", Chance = 0.3 },
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local a, ia = PlanetJobs.pick(S.Valves, r)
			local b = PlanetJobs.pick(S.Valves, r, ia)
			local spec = PlanetJobs.timing("Válvula de presión", "🔧", "Gira la válvula cuando la aguja pase por el verde: ni más ni menos", rank)
			return {
				{ Kind = "Go", At = a.At, Text = "Ve a la válvula de " .. a.Name .. " (llevas la llave de presión)", Carry = rgb(240, 200, 60) },
				{ Kind = "Game", Spec = spec },
				{ Kind = "Go", At = b.At, Text = "Ahora la de " .. b.Name .. ": la marea está cambiando" },
				{ Kind = "Game", Spec = spec },
				{ Kind = "Hold", At = { S.JobBoard[1] + 6, S.JobBoard[2] + 4 }, Seconds = 3, Text = "Apunta las presiones en el cuadro del Faro" },
			}
		end,
	},
})
S.Jobs = PlanetJobs.of("Talasa")

return S
