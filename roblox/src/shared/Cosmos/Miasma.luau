-- Miasma: la SUPERFICIE del planeta Miasma (Saga 2, episodio 6 «Guerra en el cielo»; docs/planetas/
-- diseno-mundos.md §3.6). Hecha con el marco común (shared/Cosmos/PlanetSurface; docs/planetas/
-- marco-planetas.md): un mar de niebla venenosa del que salen picos, y en uno de ellos, Anclaje Siete
-- (shared/Cosmos/MiasmaCity), discos de metal y cristal por encima de la niebla.
--
--   * El mar de niebla es el «agua» del terreno, teñida de verde ácido (WaterY): no se nada, se respira mal.
--   * Los picos: rocas violetas con musgo filtro amarillento; cristales en las cumbres.
--   * La desventaja, las TOXINAS (S.Hazard, Services/PlanetHazardService): suben cerca de la niebla (cuanto
--     más bajo, más), en el Barrio Lastre (el más bajo) y fuera de la ciudad; con la MAREA DE NIEBLA y la
--     LLUVIA ÁCIDA (S.moment), más. Contramedidas: la máscara de filtro y el traje sellado (en la mochila),
--     la cápsula de aire limpio (se usa: baja de golpe) y los refugios con aire filtrado.
--   * El oficio propio: Filtrador/a (cambiar los filtros de las estaciones del borde y limpiarlos con
--     esporas en el taller de Lastre). El material: espora de filtro y plata de rayo.

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local PlanetRegistry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.MiasmaCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local WATER_Y = 60 -- la superficie del mar de niebla
local PAD_Y = 230 -- Anclaje Siete, muy por encima

local S = PlanetSurface.new({
	Id = "Miasma",
	Name = "Miasma",
	Origin = PlanetRegistry.Slots.Miasma,
	Half = 1280,
	Seed = 61,
	WaterY = WATER_Y,
	PadY = PAD_Y,
	ArriveY = 1100,
	ClimbY = 1400,
	CeilingY = 2000,
	PadRadius = 26,
	City = City,
	-- El relieve: el fondo bajo la niebla, picos que salen de ella y el gran pico del Anclaje
	rawHeight = function(lx: number, lz: number, s: any): number
		local seed = 61 * 0.173
		local d = math.sqrt(lx * lx + lz * lz)
		-- (el fondo, casi todo bajo la niebla)
		local h = 18 + 26 * fbm(lx, lz, 4, 1 / 700, seed)
		-- (los picos que salen de la niebla: pocos y altos; ninguno pegado al Anclaje)
		local peak = fbm(lx, lz, 3, 1 / 460, seed + 4.2)
		h += 300 * smooth(0.04, 0.34, peak) * smooth(300, 460, d)
		h += 50 * math.max(0, fbm(lx, lz, 3, 1 / 140, seed + 9.1)) * smooth(90, 180, h)
		-- (el gran pico donde se anclan los discos, por debajo de ellos)
		h += 150 * smooth(340, 80, d)
		return h
	end,
	materialAt = function(lx: number, lz: number, y: number, slope: number, s: any): string
		if y < WATER_Y + 6 then
			return "Mud"
		elseif slope > 1.2 then
			return "Slate"
		elseif slope > 0.75 then
			return "Rock"
		elseif y > 250 then
			return "Salt"
		end
		return if fbm(lx, lz, 3, 1 / 140, 33.3) > 0.05 then "Ground" else "Rock"
	end,
	TerrainColors = {
		Mud = rgb(66, 74, 44), -- la orilla de la niebla
		Rock = rgb(98, 86, 110), -- laderas violetas
		Slate = rgb(62, 56, 76), -- acantilados
		Ground = rgb(150, 156, 60), -- musgo filtro (amarillo ácido)
		Salt = rgb(206, 200, 222), -- cumbres pálidas
	},
	WaterColor = rgb(132, 186, 52),
	POIs = {
		{ Id = "Miasma_Plataforma", Name = "Plataforma del Muelle de Vientos", X = 0, Z = 0, Flat = 30, Pad = true, Text = "🛬 El Muelle de Vientos. Las luces de pista parpadean: la batería antiaérea no para de girar." },
		{ Id = "Miasma_TorreSilbadora", Name = "La Torre Silbadora", X = 520, Z = -220, Flat = 30, Action = "Escuchar",
			Text = "🗼 Una antena antigua que canta con el viento. Sus tubos silban una nota larga, como si llamara a alguien desde abajo." },
		{ Id = "Miasma_Pecio", Name = "Pecio de una góndola", X = 920, Z = -720, Flat = 26,
			Text = "🎈 Una góndola caída en un pico, con el globo deshinchado. Dentro, un juego de té y un pañuelo atado a la puerta." },
		{ Id = "Miasma_Lago", Name = "Lago de Ácido Verde", X = -300, Z = 720, Flat = 34,
			Text = "🟢 Un lago verde en lo alto de un pico. No se nada. En la orilla crecen cristales que brillan de noche." },
	},
	NodeCount = 18,
	NodeOres = { { Id = "Hierro", Weight = 0.5 }, { Id = "Cobalto", Weight = 0.35 }, { Id = "Cristal", Weight = 0.15 } },
	DecorCounts = { Musgo = 70, Roca = 50, Cristal = 26, Medusa = 14 },
	DecorSlope = { Roca = 0.9, Cristal = 0.8, Medusa = 9 },
})

S.Kit = "MiasmaKit"
S.City = City

-- Su cielo y su luz (shared/Cosmos/EnvZones): morado arriba, bruma verde-amarilla abajo, rayos blancos
S.Env = {
	Sky = { "CieloMiasma", "Original" },
	Clouds = true,
	Mood = {
		Brightness = 2.1,
		Exposure = -0.02,
		Ambient = rgb(70, 66, 96),
		Outdoor = rgb(132, 132, 160),
		EnvDiffuse = 0.7,
		EnvSpecular = 0.8,
		Shadow = 0.3,
		SunTint = rgb(60, 50, 96),
		ShadeTint = rgb(26, 30, 46),
		Density = 0.4,
		Offset = 0.2,
		AtmColor = rgb(168, 196, 104),
		Decay = rgb(106, 70, 150),
		Glare = 0.25,
		Haze = 2.4,
		Tint = rgb(236, 250, 226),
		Saturation = 0.04,
		Contrast = 0.16,
		CCBright = 0,
		Bloom = 0.8,
		BloomSize = 26,
		Threshold = 1.4,
		Rays = 0.08,
		RaysSpread = 0.5,
		Cover = 0.5,
		CloudDensity = 0.45,
		CloudColor = rgb(176, 160, 214), -- nubes violetas
		Veil = 0,
		Overcast = 0,
	},
}

-- Lo que flota en el aire: esporas amarillas y una bruma verde fina
S.Fx = {
	{ Name = "Esporas", Color = rgb(220, 230, 120), Size = 0.25, Rate = 0.5, Alpha = 0.35, Speed = 1.5, Acceleration = Vector3.new(0.8, 0.3, 0.4) },
	{ Name = "Bruma", Color = rgb(150, 190, 90), Size = 6, Rate = 0.12, Alpha = 0.85, Speed = 1 },
}

S.CrowdLines = {
	"¿Has visto mi filtro? Juraría que lo dejé aquí.",
	"Dicen que esta noche reparten aire embotellado en la Plaza.",
	"Mi primo se ha apuntado a la Defensa. Tiene quince años.",
	"Otro pañuelo en la barandilla esta mañana…",
	"Si suena la sirena larga, al refugio. Si suena la corta, a los cañones.",
	"El Maestro Olmo dice que la Refinería no para. Pase lo que pase.",
	"La niebla ha subido medio metro desde ayer.",
	"Ración de hoy: caldo de musgo. Otra vez.",
}

---------------------------------------------------------------------
-- La desventaja: TOXINAS
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Toxinas",
	Name = "Toxinas",
	Icon = "☣",
	Bands = {
		Niebla = { { 15, 8 }, { 45, 3 }, { 100, 1.1 }, { 160, 0.3 } }, -- (altura sobre la niebla)
		Marea = { { 0, 0.9 } }, -- (la marea de niebla sube)
		Lluvia = { { 0, 0.7 } }, -- (lluvia ácida, a cielo abierto)
		Filtro = { { 6, 1.5 }, { 12, 0.6 } }, -- (junto a un filtro sucio de una estación del borde)
	},
	ZoneRate = { Lastre = 0.35, Fuera = 0.25 },
	Exposed = 0,
	Recovery = 1.6,
	Gear = { MascaraFiltro = { Level = 1, Factor = 0.5 }, TrajeSellado = { Level = 3, Factor = 0.2 } },
	Consumable = { Item = "CapsulaAire", Drop = 45, Seconds = 60, Factor = 0.25 },
	Labels = { Normal = "Toxinas", Aviso = "Toses: el aire pica", Peligro = "¡Te mareas! Aire limpio, ya" },
})
S.HazardTint = rgb(150, 230, 70)
S.HazardHints = {
	Normal = "Cerca de la niebla y en Lastre suben: máscara de filtro en la mochila",
	Aviso = "Toses y vas más lento: usa una 🫧 cápsula de aire o entra a un refugio",
	Peligro = "Pierdes vida: 🫧 cápsula de aire (mochila) o la enfermería del Muelle",
}
S.HazardToasts = {
	Aviso = "☣ Toses: el aire pica. Una 🫧 cápsula de aire o un refugio con aire filtrado (la enfermería, la cantina).",
	Peligro = "☣ ¡Te mareas! Pierdes vida: usa una 🫧 cápsula de aire o entra en la enfermería del Muelle.",
}
S.KnockText = "☣ Las toxinas te han tumbado."
S.CounterText = "🫧 Aire limpio: las toxinas bajan de golpe y durante un minuto casi no suben"

-- Las estaciones de filtro del borde (el oficio de filtrador)
S.FilterStations = {
	{ Name = "la estación de la Plaza", X = -150, Z = -28 },
	{ Name = "la estación de la Refinería", X = 150, Z = 26 },
	{ Name = "la estación de Lastre", X = -26, Z = 152 },
	{ Name = "la estación de las Góndolas", X = 26, Z = -150 },
	{ Name = "la estación del Muelle", X = 52, Z = -26 },
}

-- Marea de niebla y lluvia ácida (hora de Miasma): para el medidor y el sonido
function S.moment(clock: number, _pos: Vector3?): string?
	if clock >= 17 and clock < 17.5 then
		return "LluviaAcida"
	elseif (clock >= 11 and clock < 12) or (clock >= 23 and clock < 24) then
		return "Marea"
	end
	return nil
end

-- Lo que rodea a quien está a pie (Services/PlanetHazardService añade refugio, equipo, cápsula y novato)
function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local lx, lz = S.toLocal(pos)
	local above = pos.Y - (S.Origin.Y + WATER_Y)
	local near: { [string]: any } = { Niebla = math.max(0, above) }
	local mode = S.moment(info.Clock or 12, pos)
	if mode == "Marea" then
		near.Marea = 0
	elseif mode == "LluviaAcida" then
		near.Lluvia = 0
	end
	local filters = {}
	for _, f in S.FilterStations do
		local d = math.sqrt((lx - f.X) ^ 2 + (lz - f.Z) ^ 2)
		if d < 14 then
			table.insert(filters, d)
		end
	end
	near.Filtro = filters
	local zone: string? = nil
	if not City.inside(lx, lz, 4) then
		zone = "Fuera"
	else
		local d = City.districtAt(lx, lz)
		zone = d and d.Id or nil
	end
	return { Near = near, Zone = zone }
end

---------------------------------------------------------------------
-- El oficio propio: FILTRADOR/A (tablón en la puerta del taller de Lastre)
---------------------------------------------------------------------
PlanetJobs.register({
	{
		Id = "MiasmaFiltrador",
		Planet = "Miasma",
		PlanetName = "Miasma",
		Name = "Filtrador/a",
		Icon = "😷",
		Pay = 45,
		MinSeconds = 25,
		EnergyCost = 3,
		Board = { 6, 112 },
		BoardFace = { -1, 0 },
		PayText = "desde 45 € por filtro cambiado",
		Place = "Taller de filtros · Anclaje Siete",
		Drop = { Item = "EsporaFiltro", Chance = 0.3 },
		CarryColor = rgb(170, 190, 90),
		CarrySize = Vector3.new(1.4, 1.4, 1.4),
		Desc = "Cambia los filtros de las estaciones del borde (donde la niebla se acerca) y límpialos con esporas en el taller.",
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local st = PlanetJobs.pick(S.FilterStations, r)
			return {
				{ Kind = "Go", At = { 14, 116 }, Text = "😷 Coge un filtro nuevo en el taller de Lastre", Carry = rgb(220, 230, 200) },
				{ Kind = "Go", At = { st.X, st.Z }, Text = ("😷 Lleva el filtro a %s (cerca del borde: la niebla pica)"):format(st.Name),
					Game = PlanetJobs.timing("Cambiar el filtro", "😷", "Gira la rosca cuando la marca pase por el verde", rank) },
				{ Kind = "Go", At = { 14, 116 }, Text = "😷 Trae el filtro sucio al taller de Lastre", Carry = rgb(90, 100, 50) },
				{ Kind = "Hold", At = { 14, 116 }, Seconds = 4, Text = "🌿 Límpialo con esporas (quédate junto al banco del taller)", Drop = true },
			}
		end,
	},
})
S.Jobs = PlanetJobs.of("Miasma")

return S
