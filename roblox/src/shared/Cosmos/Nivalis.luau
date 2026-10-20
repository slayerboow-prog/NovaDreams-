-- Nivalis: la SUPERFICIE del planeta helado (Saga 2, episodio 4 «La noche del Regente»; diseño en
-- docs/planetas/diseno-mundos.md §3.4, lo que se juega ya en docs/planetas/nivalis-umbria.md). Hecho con el
-- marco común (docs/planetas/marco-planetas.md): PlanetSurface.new + su barrio (shared/Cosmos/NivalisCity),
-- su kit (World/NivalisKit), su cielo y su luz (S.Env), su desventaja (el FRÍO, S.Hazard) y su oficio (el
-- farolero, PlanetJobs).
--
-- El planeta: el Valle de Albor (nieve pisada, el Bosque de Escarcha, el Lago de los Ahogados helado y
-- las Fuentes Calientes) cerrado por glaciares y por los Picos del Silencio. Noche eterna: la luz la dan
-- las auroras (verdes y rosas) y los faroles. Dos ventiscas al día.

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local Registry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.NivalisCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local LAKE = { X = -380, Z = 300, R = 95, Y = 56 } -- el Lago de los Ahogados (helado: hielo, no agua)
local SPRINGS = { X = 420, Z = 380, R = 26 } -- las Fuentes Calientes (el único sitio cálido de fuera)
local GLACIER = { X = -620, Z = -520 } -- la lengua del Glaciar Azul (baja de los picos del noroeste)

local function rawHeight(lx: number, lz: number, S: any): number
	local seed = S.Seed * 0.173
	local d = math.sqrt(lx * lx + lz * lz)
	-- el fondo del valle: nieve con dunas suaves
	local h = 64 + 12 * fbm(lx, lz, 4, 1 / 340, seed) + 5 * fbm(lx, lz, 3, 1 / 90, seed + 1.7)
	-- las montañas que cierran el valle (crestas afiladas: 1 − |ruido|)
	local ridge = 1 - math.abs(fbm(lx, lz, 4, 1 / 520, seed + 4.2))
	h += smooth(360, 900, d) * (220 + 330 * ridge * ridge)
	-- la lengua del Glaciar Azul: una rampa ancha y lisa que baja del noroeste
	local gx, gz = lx - GLACIER.X, lz - GLACIER.Z
	local along = (gx * 0.6 + gz * 0.8)
	local across = math.abs(-gx * 0.8 + gz * 0.6)
	local tongue = smooth(150, 40, across) * smooth(-500, 200, -along)
	h = h + (110 + along * -0.15 - h) * tongue * 0.6
	-- el lago helado: llano
	local dl = math.sqrt((lx - LAKE.X) ^ 2 + (lz - LAKE.Z) ^ 2)
	h = h + (LAKE.Y - h) * smooth(LAKE.R * 1.4, LAKE.R * 0.9, dl)
	-- las fuentes calientes: una hondonada
	local ds = math.sqrt((lx - SPRINGS.X) ^ 2 + (lz - SPRINGS.Z) ^ 2)
	h -= 8 * smooth(SPRINGS.R * 1.8, SPRINGS.R * 0.6, ds)
	return h
end

local function materialAt(lx: number, lz: number, y: number, slope: number, S: any): string
	if math.sqrt((lx - LAKE.X) ^ 2 + (lz - LAKE.Z) ^ 2) < LAKE.R * 0.98 then
		return "Ice"
	end
	if math.sqrt((lx - SPRINGS.X) ^ 2 + (lz - SPRINGS.Z) ^ 2) < SPRINGS.R then
		return "Basalt" -- (la piedra negra mojada de las fuentes)
	end
	if slope > 1.15 then
		return "Slate"
	elseif slope > 0.72 then
		return "Basalt"
	end
	if y > 330 then
		return "Glacier"
	end
	local gx, gz = lx - GLACIER.X, lz - GLACIER.Z
	if math.abs(-gx * 0.8 + gz * 0.6) < 110 and (gx * 0.6 + gz * 0.8) < 260 then
		return "Glacier"
	end
	if fbm(lx, lz, 3, 1 / 160, 31.7 + S.Seed) > 0.22 then
		return "Salt" -- (nieve costrosa que el viento ha endurecido)
	end
	return "Snow"
end

local S = PlanetSurface.new({
	Id = "Nivalis",
	Name = "Nivalis",
	Origin = Registry.Slots.Nivalis,
	Half = 1100,
	Seed = 41,
	WaterY = -200, -- (no hay agua líquida: el lago está helado)
	ArriveY = 1400,
	ClimbY = 1700,
	CeilingY = 2300,
	Floor = -40,
	City = City,
	rawHeight = rawHeight,
	materialAt = materialAt,
	Terrain = { Edge = 320 },
	TerrainColors = {
		Snow = rgb(232, 240, 250), -- nieve pisada, azulada por la noche
		Salt = rgb(204, 218, 234), -- nieve costrosa del viento
		Glacier = rgb(136, 188, 226), -- el Glaciar Azul
		Ice = rgb(162, 204, 232), -- el lago helado
		Slate = rgb(88, 98, 118), -- piedra gris de los riscos
		Basalt = rgb(54, 60, 76), -- roca oscura
	},
	WaterColor = rgb(90, 130, 170),
	POIs = {
		{ Id = "Nivalis_Plataforma", Name = "Patio de Armas de Fortaleza Albor", X = 0, Z = 0, Flat = 44, Pad = true,
			Text = "🛬 El Patio de Armas de Fortaleza Albor. Las piedras tienen mil años y la escarcha, una noche." },
		{ Id = "Nivalis_MiradorValle", Name = "Mirador del Valle", X = 0, Z = -300, Flat = 22,
			Text = "🏔 Desde aquí se ve el Palacio de Escarcha y, sobre los Picos del Silencio, la antena que llama a las auroras." },
		{ Id = "Nivalis_LagoAhogados", Name = "Lago de los Ahogados", X = LAKE.X, Z = LAKE.Z - LAKE.R - 20, Flat = 18,
			Text = "🧊 Hielo fino. Dicen que debajo hay un barco atrapado desde hace siglos. Nadie ha bajado a mirarlo… todavía." },
		{ Id = "Nivalis_Fuentes", Name = "Fuentes Calientes", X = SPRINGS.X, Z = SPRINGS.Z + SPRINGS.R + 10, Flat = 16,
			Text = "♨ Agua caliente que sale de la roca. Aquí el frío no sube: el único sitio cálido del valle." },
		{ Id = "Nivalis_Monasterio", Name = "Monasterio de Hielo", X = 560, Z = -420, Flat = 30,
			Text = "🛕 Abandonado, dicen. Pero hay huellas recientes en la nieve y una campana que suena sola." },
		{ Id = "Nivalis_Antena", Name = "Antena de las Auroras", X = -520, Z = -700, Flat = 26,
			Text = "📡 La antena antigua que atrae las auroras sobre el valle. El Regente decide hacia qué barrio apunta." },
		{ Id = "Nivalis_Cabana", Name = "Cabaña del Ermitaño", X = 640, Z = 180, Flat = 18,
			Text = "🛖 Humo en la chimenea y huellas de lanudo. Alguien vive aquí, lejos del Regente." },
	},
	NodeCount = 14,
	NodeOres = { { Id = "Cobalto", Weight = 3 }, { Id = "Hierro", Weight = 2 }, { Id = "Cristal", Weight = 1 } },
	DecorCounts = { PinoEscarcha = 80, Roca = 30, Cristal = 22 },
	DecorSlope = { PinoEscarcha = 0.5, Roca = 0.9, Cristal = 0.8 },
})

S.Lake = LAKE
S.Springs = SPRINGS
S.Glacier = GLACIER
S.Kit = "NivalisKit"

-- Su cielo y su luz (nombres de shared/DayGrade): noche eterna, estrellas, luz de luna azul y el verde de
-- la aurora en las caras que miran al norte; bruma fría y brillo en el hielo. Nunca el cielo de Valmar.
S.Env = {
	Sky = { "EspacioProfundo", "Original" },
	Clouds = false,
	Mood = {
		Brightness = 0.95,
		Exposure = 0.12,
		Ambient = rgb(44, 58, 88),
		Outdoor = rgb(78, 106, 152),
		EnvDiffuse = 0.55,
		EnvSpecular = 1,
		Shadow = 0.32,
		SunTint = rgb(24, 70, 64), -- (el verde de la aurora)
		ShadeTint = rgb(8, 18, 48),
		Density = 0.3,
		Offset = 0.1,
		AtmColor = rgb(128, 168, 212),
		Decay = rgb(56, 84, 128),
		Glare = 0.1,
		Haze = 1.4,
		Tint = rgb(220, 236, 255),
		Saturation = -0.04,
		Contrast = 0.14,
		CCBright = 0,
		Bloom = 1,
		BloomSize = 30,
		Threshold = 1.3,
		Rays = 0,
		RaysSpread = 0.4,
		Cover = 0,
		CloudDensity = 0,
		CloudColor = rgb(150, 170, 200),
		Veil = 0,
		Overcast = 0,
	},
}

-- Lo que cae del cielo: nieve fina siempre y, en la ventisca, nieve a ráfagas (PlanetClient: Mode)
S.Fx = {
	{ Name = "Nieve", Color = rgb(240, 246, 255), Size = 0.35, Rate = 0.9, Speed = 3, Alpha = 0.15, Acceleration = Vector3.new(2, -3, 1) },
	{ Name = "Ventisca", Mode = "Ventisca", Color = rgb(236, 244, 255), Size = 0.7, Rate = 2.6, Speed = 16, Alpha = 0.1, Acceleration = Vector3.new(32, -5, 12), Direction = Enum.NormalId.Left },
}

---------------------------------------------------------------------
-- El FRÍO (diseno-mundos §3.4.11): sube siempre fuera; dentro de la muralla, despacio; en los picos y
-- en la ventisca, deprisa. Las hogueras de musgo y las Fuentes Calientes calientan; los refugios
-- (Termas, el puesto de sopa, la casa de Tila) lo vacían. Abrigo de lana de lanudo y sopa caliente.
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Frio",
	Name = "Frío",
	Icon = "❄",
	Max = 100,
	Warn = 60,
	Danger = 85,
	ZoneRate = { Barrio = 0.16, BarrioVentisca = 0.34, Valle = 0.5, Picos = 0.9 },
	Exposed = 0.55, -- (fuera, en plena ventisca)
	Recovery = 1.2,
	Gear = {
		AbrigoLana = { Level = 1, Factor = 0.6 },
		AbrigoLana2 = { Level = 2, Factor = 0.35 },
	},
	Consumable = { Item = "SopaAlbor", Drop = 45, Seconds = 90, Factor = 0.25 },
	Slow = { Aviso = 0.86, Peligro = 0.72 },
	Labels = { Normal = "Frío", Aviso = "Tienes mucho frío", Peligro = "¡Te congelas! Busca una hoguera o un refugio" },
})
S.HazardTint = rgb(150, 200, 255)
S.HazardHints = {
	"❄ El frío sube siempre fuera de la muralla: dentro, más despacio.",
	"🔥 Junto a una hoguera de musgo el frío baja. Las Termas y la sopa de Brisa, también.",
	"🧥 Con el abrigo de lana en la mochila sube mucho menos.",
	"🌨 En la ventisca no se ve nada y el frío muerde: busca un refugio.",
}
S.HazardToasts = {
	Aviso = "❄ Tiemblas de frío: vas más lento. Una hoguera, las Termas o una sopa caliente.",
	Peligro = "🥶 ¡Te estás congelando! Métete en un refugio o tómate la sopa ya.",
}
S.KnockText = "🥶 El frío te ha tumbado. Alguien te ha arrastrado hasta un sitio caliente."
S.CounterText = "🍲 Sopa caliente: el frío baja de golpe y durante un rato casi no sube."

S.FireReach = 14
S.SpringReach = 34

-- Lo que rodea al jugador (lo lee Services/PlanetHazardService): zona, ventisca, hogueras y fuentes
function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local lx, lz = S.toLocal(pos)
	local clock = tonumber(info and info.Clock) or 0
	local storm = City.blizzard(clock)
	local inside = City.inside(lx, lz, 0)
	local ctx: { [string]: any } = {}
	if inside then
		ctx.Zone = if storm then "BarrioVentisca" else "Barrio"
		for _, f in City.Fires do
			if (lx - f.X) ^ 2 + (lz - f.Z) ^ 2 <= S.FireReach * S.FireReach then
				ctx.Shelter = 3 -- (calentarse junto a la hoguera)
				ctx.Fire = true
			end
		end
	else
		local high = pos.Y - S.Origin.Y > 300
		ctx.Zone = if high then "Picos" else "Valle"
		ctx.Exposed = storm
		if (lx - SPRINGS.X) ^ 2 + (lz - SPRINGS.Z) ^ 2 <= S.SpringReach * S.SpringReach then
			ctx.Shelter = 5
			ctx.Exposed = false
		end
	end
	return ctx
end

-- El momento del planeta (para el sonido: Soundscapes.Planets.Nivalis.Modes)
function S.moment(clock: number, _pos: Vector3): string?
	return if City.blizzard(clock) then "Ventisca" else nil
end

-- Lo que susurra la gente (CrowdService): es la hora del silencio
S.CrowdLines = {
	"(susurra) Ni una palabra en la plaza. Es la hora del silencio.",
	"(susurra) Esta noche la aurora no ha venido al barrio. Otra vez.",
	"(susurra) Brisa pone la sopa más caliente cuando hay guardias. Para que se vayan antes.",
	"(susurra) Han vuelto a dejar una vela en la estatua. Nadie ha visto quién.",
	"(susurra) No mires al Cuerpo de Guardia. Ellos sí te miran a ti.",
	"(susurra) Mi abuela cantaba. Ahora ni tararea.",
	"(susurra) Si oyes una campana en el Monasterio, no es el viento.",
	"(susurra) ¿Forastero? Abrígate. Aquí el frío no perdona y el Regente tampoco.",
}

---------------------------------------------------------------------
-- El oficio de Nivalis: FAROLERO/A (diseno-mundos §3.4.9). Ruta → encender faroles (minijuego) →
-- dejar el mensaje escondido de la resistencia en un buzón de la muralla sin prisa (si corres, se oye).
---------------------------------------------------------------------
local function pickDistinct(r: () -> number, list: { { number } }, n: number): { { number } }
	local pool = table.clone(list)
	local out = {}
	for _ = 1, math.min(n, #pool) do
		local i = math.floor(r() * #pool) + 1
		table.insert(out, table.remove(pool, i))
	end
	return out
end

PlanetJobs.register({
	{
		Id = "NivalisFarolero",
		Planet = "Nivalis",
		PlanetName = "Nivalis",
		Name = "Farolero/a",
		Icon = "🏮",
		Desc = "Enciende los faroles de Fortaleza Albor y deja los mensajes de la resistencia en los buzones de la muralla.",
		Pay = 45,
		MinSeconds = 20,
		Board = City.Jobs.BoardFarolero,
		BoardFace = { 0, 1 },
		PayText = "desde 45 € por ronda (más con el rango)",
		Place = "Fortaleza Albor (Nivalis)",
		EnergyCost = 3,
		Drop = { Item = "CristalEco", Chance = 0.3 },
		CarryColor = rgb(236, 220, 180),
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local phases = {}
			local lamps = pickDistinct(r, City.Jobs.Faroles, if rank >= 3 then 3 else 2)
			for i, at in lamps do
				table.insert(phases, {
					Kind = "Go",
					At = at,
					Text = ("Enciende el farol %d de %d (sube la mecha sin que se apague)"):format(i, #lamps),
					Game = PlanetJobs.timing("Encender el farol", "🏮", "Pulsa cuando la llama pase por el ámbar", rank),
				})
			end
			local box = City.Jobs.Buzones[math.floor(r() * #City.Jobs.Buzones) + 1]
			table.insert(phases, { Kind = "Go", At = box, Text = "Lleva el mensaje escondido al buzón de la muralla (andando: si corres, se oye)", Carry = rgb(236, 220, 180) })
			table.insert(phases, { Kind = "Hold", At = box, Seconds = 3, Drop = true, Text = "Escóndelo en la piedra suelta… quieto, sin ruido" })
			return phases
		end,
	},
})
S.Jobs = PlanetJobs.of("Nivalis")

return S
