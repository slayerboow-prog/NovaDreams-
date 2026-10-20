-- Siroco: la SUPERFICIE del planeta Siroco (Saga 2, episodio 2 «El último Gran Premio»; docs/planetas/
-- diseno-mundos.md §3.2). Hecha con el marco común (shared/Cosmos/PlanetSurface; docs/planetas/
-- marco-planetas.md): un desierto rojo bajo un sol que crece, mesas y dunas, y un cañón donde está
-- Puerto Calcina (shared/Cosmos/SirocoCity), la ciudad de adobe y chatarra con su calle-circuito.
--
--   * Terreno: dunas de arena ocre, mesas rojas, el cañón de Calcina (paredes de arenisca a los lados de
--     la ciudad) y las Salinas Blancas al este. Sin agua: el agua de verdad está escondida bajo tierra.
--   * La desventaja, la SED (S.Hazard, Services/PlanetHazardService): sube SIEMPRE un poco, más al sol de
--     día y fuera de la ciudad; en la HORA ROJA (mediodía) muchísimo y con la TORMENTA DE ARENA algo más
--     (S.moment). Contramedidas: la cantimplora y la ropa de sol (en la mochila), el agua fresca (se usa:
--     baja de golpe) y la sombra de los refugios (los Túneles, la cantina…).
--   * El oficio propio: Aguador/a (llenar los bidones en la fuente de Pozo Hondo y repartirlos sin
--     derramar por las casas de la roca). El material: sal de rocío, chatarra antigua, vidrio de tormenta.

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local PlanetRegistry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.SirocoCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local FLOOR = 62 -- el fondo del cañón (la ciudad)

local S = PlanetSurface.new({
	Id = "Siroco",
	Name = "Siroco",
	Origin = PlanetRegistry.Slots.Siroco,
	Half = 1280,
	Seed = 23,
	WaterY = 8,
	PadY = FLOOR,
	ArriveY = 1100,
	ClimbY = 1400,
	CeilingY = 2000,
	PadRadius = 28,
	City = City,
	-- Dunas, mesas y el cañón de Calcina (de norte a sur, con la ciudad en el fondo)
	rawHeight = function(lx: number, lz: number, s: any): number
		local seed = 23 * 0.173
		local h = 70 + 16 * fbm(lx, lz, 3, 1 / 260, seed) + 34 * math.max(0, fbm(lx, lz, 2, 1 / 900, seed + 2.2))
		local mesa = fbm(lx, lz, 3, 1 / 620, seed + 5.1)
		h += 120 * smooth(0.16, 0.26, mesa)
		-- El cañón: paredes a los dos lados de la ciudad, de unos 130 studs de alto
		local c = math.abs(lx)
		local along = smooth(950, 700, math.abs(lz))
		local canyon = FLOOR + 135 * smooth(132, 190, c) + 20 * fbm(lx, lz, 2, 1 / 90, seed + 7.7) * smooth(140, 200, c)
		local k = along * smooth(330, 250, c)
		return h + (canyon - h) * k
	end,
	materialAt = function(lx: number, lz: number, y: number, slope: number, s: any): string
		if slope > 0.9 then
			return if y > FLOOR + 60 then "Sandstone" else "Rock"
		elseif slope > 0.45 then
			return "Sandstone"
		end
		-- Las Salinas Blancas (al este del cañón)
		if (lx - 760) ^ 2 + (lz + 300) ^ 2 < 300 * 300 then
			return "Salt"
		end
		if math.abs(lx) < 140 and math.abs(lz) < 700 then
			return "Ground" -- (el fondo del cañón: tierra pisada)
		end
		return if fbm(lx, lz, 3, 1 / 200, 41.2) > 0.25 then "Rock" else "Sand"
	end,
	TerrainColors = {
		Sand = rgb(214, 150, 96), -- dunas ocre
		Sandstone = rgb(178, 88, 56), -- las paredes rojas del cañón
		Rock = rgb(138, 74, 54), -- roca tostada
		Ground = rgb(170, 116, 78), -- tierra pisada de la ciudad
		Salt = rgb(238, 228, 216), -- las Salinas Blancas
	},
	WaterColor = rgb(90, 140, 150),
	POIs = {
		{ Id = "Siroco_Plataforma", Name = "Plataforma del Muelle de Velas", X = 0, Z = -140, Flat = 28, Pad = true, Text = "🛬 El Muelle de Velas. El viento sopla arena contra el metal: suena como lluvia." },
		{ Id = "Siroco_Cementerio", Name = "Cementerio de Deslizadores", X = 430, Z = -300, Flat = 60, Action = "Rebuscar",
			Text = "🏁 Miles de deslizadores rotos, medio enterrados. Los chacales de chatarra te miran desde un capó." },
		{ Id = "Siroco_Esfinge", Name = "La Esfinge Ciega", X = -600, Z = 500, Flat = 40, Action = "Mirar",
			Text = "🗿 Una estatua enorme de la Ciudad Primera, con los ojos tapados. Mira al sol. Dicen que es un faro." },
		{ Id = "Siroco_Salinas", Name = "Las Salinas Blancas", X = 760, Z = -300, Flat = 50, Action = "Mirar",
			Text = "🧂 Una llanura de sal que deslumbra de día y cruje de noche. Aquí se corren las carreras de velocidad pura." },
	},
	NodeCount = 18,
	NodeOres = { { Id = "Hierro", Weight = 0.55 }, { Id = "Cobalto", Weight = 0.3 }, { Id = "Cristal", Weight = 0.15 } },
	DecorCounts = { Cactus = 60, Roca = 50, Vidrio = 24, Chatarra = 24 },
	DecorSlope = { Roca = 0.9 },
})

S.Kit = "SirocoKit"
S.City = City

-- Su cielo y su luz: rojo y ocre de día, el sol enorme y blanco-rojo; la noche azul es el alivio
S.Env = {
	Sky = { "CieloSiroco", "Original" },
	Clouds = false,
	Mood = {
		Brightness = 2.9,
		Exposure = 0.06,
		Ambient = rgb(112, 78, 64),
		Outdoor = rgb(206, 150, 118),
		EnvDiffuse = 0.75,
		EnvSpecular = 0.7,
		Shadow = 0.22,
		SunTint = rgb(150, 66, 30),
		ShadeTint = rgb(46, 20, 30),
		Density = 0.3,
		Offset = 0.12,
		AtmColor = rgb(232, 164, 112),
		Decay = rgb(160, 72, 44),
		Glare = 0.5,
		Haze = 1.7,
		Tint = rgb(255, 232, 214),
		Saturation = 0.1,
		Contrast = 0.18,
		CCBright = 0.01,
		Bloom = 0.9,
		BloomSize = 28,
		Threshold = 1.3,
		Rays = 0.14,
		RaysSpread = 0.7,
		Cover = 0,
		CloudDensity = 0,
		CloudColor = rgb(230, 170, 120),
		Veil = 0,
		Overcast = 0,
	},
}

-- Lo que vuela: polvo rojo fino
S.Fx = {
	{ Name = "Polvo", Color = rgb(220, 150, 100), Size = 0.3, Rate = 0.6, Alpha = 0.4, Speed = 4, Direction = Enum.NormalId.Left, Acceleration = Vector3.new(6, -0.2, 1) },
}

S.CrowdLines = {
	"¿Has visto el precio del agua hoy? Otro euro más.",
	"Esta noche corre el hijo de los Ardiles. Diez a uno.",
	"Dicen que las Arcas despegan antes de fin de año.",
	"¡Que viene la hora roja! Bajad a los Túneles.",
	"Mi abuela vio llover una vez. Una.",
	"Rafa Quiroga… ¿el Zorro? Ese ya no corre.",
	"Brindo con agua por los que se fueron. Un poquito a la arena.",
	"La Guardia de Hierro ha cerrado otro pozo en Pozo Hondo.",
}

---------------------------------------------------------------------
-- La desventaja: SED
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Sed",
	Name = "Sed",
	Icon = "💧",
	Bands = {
		HoraRoja = { { 0, 1.4 } }, -- (al sol en la hora roja: casi mortal fuera)
		Tormenta = { { 0, 0.3 } },
	},
	ZoneRate = { Fuera = 0.3, Recta = 0.08 },
	Exposed = 0.24, -- (al sol, de día)
	Base = 0.16, -- (la sed sube siempre un poco)
	Recovery = 1.2,
	Gear = { Cantimplora = { Level = 1, Factor = 0.6 }, RopaSol = { Level = 2, Factor = 0.45 } },
	Consumable = { Item = "AguaFresca", Drop = 50, Seconds = 90, Factor = 0.2 },
	Slow = { Aviso = 0.88, Peligro = 0.74 },
	Labels = { Normal = "Sed", Aviso = "Tienes mucha sed", Peligro = "¡Te deshidratas! Agua, ya" },
})
S.HazardTint = rgb(255, 150, 70)
S.HazardHints = {
	Normal = "Sube siempre (más al sol): bebe 💧 agua fresca o busca sombra",
	Aviso = "Vas más lento: 💧 agua fresca (mochila) o la sombra de un refugio",
	Peligro = "Pierdes vida: 💧 agua fresca ya, o baja a los Túneles",
}
S.HazardToasts = {
	Aviso = "💧 Tienes mucha sed: bebe 💧 agua fresca (mochila) o métete a la sombra (la cantina, los Túneles).",
	Peligro = "💧 ¡Te deshidratas! Pierdes vida: 💧 agua fresca ya, o baja a los Túneles.",
}
S.KnockText = "💧 El calor y la sed te han tumbado."
S.CounterText = "💧 Agua fresca: la sed baja de golpe y durante un rato casi no sube"

-- La hora roja (mediodía) y las tormentas de arena (hora de Siroco)
function S.moment(clock: number, _pos: Vector3?): string?
	if clock >= 13 and clock < 14 then
		return "HoraRoja"
	elseif (clock >= 16 and clock < 16.5) or (clock >= 4 and clock < 4.5) then
		return "Tormenta"
	end
	return nil
end

function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local lx, lz = S.toLocal(pos)
	local near: { [string]: any } = {}
	local mode = S.moment(info.Clock or 10, pos)
	if mode == "HoraRoja" then
		near.HoraRoja = 0
	elseif mode == "Tormenta" then
		near.Tormenta = 0
	end
	local zone: string? = nil
	if not City.inside(lx, lz, 4) then
		zone = "Fuera"
	else
		local d = City.districtAt(lx, lz)
		zone = d and d.Id or nil
	end
	return { Near = near, Zone = zone, Exposed = info.Day == true }
end

---------------------------------------------------------------------
-- El oficio propio: AGUADOR/A (tablón junto a la fuente de Pozo Hondo)
---------------------------------------------------------------------
S.Deliveries = {
	{ Name = "las casas de las Gradas", X = -104, Z = 66 },
	{ Name = "las casas de la roca", X = -104, Z = 140 },
	{ Name = "las casas del este", X = 104, Z = 118 },
	{ Name = "las Gradas del este", X = 104, Z = -6 },
	{ Name = "el taller del Abuelo Tornillo", X = 38, Z = 80 },
	{ Name = "la casa de Luz", X = -48, Z = 132 },
}

PlanetJobs.register({
	{
		Id = "SirocoAguador",
		Planet = "Siroco",
		PlanetName = "Siroco",
		Name = "Aguador/a",
		Icon = "💧",
		Pay = 45,
		MinSeconds = 30,
		EnergyCost = 3,
		Board = { -14, 140 },
		BoardFace = { 1, 0 },
		PayText = "desde 45 € por reparto",
		Place = "La fuente de Pozo Hondo · Puerto Calcina",
		Drop = { Item = "SalRocio", Chance = 0.25 },
		CarryColor = rgb(80, 150, 200),
		CarrySize = Vector3.new(1.6, 2, 1.6),
		Desc = "Llena los bidones en la fuente de Pozo Hondo y repártelos por las casas de la roca sin derramar ni una gota.",
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local a, ia = PlanetJobs.pick(S.Deliveries, r)
			local b = PlanetJobs.pick(S.Deliveries, r, ia)
			return {
				{ Kind = "Hold", At = { -30, 130 }, Seconds = 3, Text = "💧 Llena los bidones en la fuente de Pozo Hondo (quédate junto a ella)" },
				{ Kind = "Go", At = { a.X, a.Z }, Text = ("💧 Lleva el agua a %s sin derramar"):format(a.Name), Carry = rgb(80, 150, 200),
					Game = PlanetJobs.timing("Sin derramar", "💧", "Endereza el bidón cuando la marca pase por el verde", rank) },
				{ Kind = "Go", At = { b.X, b.Z }, Text = ("💧 Y el segundo bidón a %s"):format(b.Name), Carry = rgb(80, 150, 200),
					Game = PlanetJobs.timing("Sin derramar", "💧", "Endereza el bidón cuando la marca pase por el verde", rank) },
				{ Kind = "Go", At = { -30, 128 }, Text = "💧 Vuelve a la fuente con los bidones vacíos", Drop = true },
			}
		end,
	},
})
S.Jobs = PlanetJobs.of("Siroco")

return S
