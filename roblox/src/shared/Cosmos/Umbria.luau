-- Umbría: la SUPERFICIE del planeta selva (Saga 2, episodio 5 «El Enjambre»; diseño en
-- docs/planetas/diseno-mundos.md §3.5, lo que se juega ya en docs/planetas/nivalis-umbria.md). Hecho con el
-- marco común (docs/planetas/marco-planetas.md): PlanetSurface.new + su barrio (shared/Cosmos/UmbriaCity),
-- su kit (World/UmbriaKit), su cielo y su luz (S.Env), su desventaja (las ESPORAS, S.Hazard) y su oficio
-- (el podador, PlanetJobs).
--
-- El planeta: el Suelo Hondo de un bosque de árboles gigantes (troncos que se pierden en la niebla verde),
-- setas sombrilla, esporeras que brillan, el Lago Espejo y el Claro Muerto que ha pelado el Enjambre.
-- Abajo siempre es penumbra; por la mañana cae una lluvia torrencial y al anochecer, lluvia de esporas.

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local Registry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.UmbriaCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local CLEARING = { X = 340, Z = -300, R = 150 } -- el Claro Muerto (pelado por el Enjambre)

-- Los campos de esporeras del Suelo Hondo (local x, z, radio): ahí las esporas suben deprisa
local SPORE_FIELDS = {
	{ X = -300, Z = 240, R = 90 },
	{ X = 420, Z = 260, R = 80 },
	{ X = -520, Z = -160, R = 100 },
	{ X = 160, Z = 560, R = 90 },
	{ X = -160, Z = -520, R = 80 },
}

local function rawHeight(lx: number, lz: number, S: any): number
	local seed = S.Seed * 0.173
	-- el suelo del bosque: lomas suaves, raíces y barrancos
	local h = 56 + 30 * fbm(lx, lz, 4, 1 / 520, seed) + 9 * fbm(lx, lz, 3, 1 / 120, seed + 2.3)
	local v = math.abs(fbm(lx, lz, 3, 1 / 900, seed + 6.1))
	h -= 34 * smooth(0.12, 0.0, v) -- (los barrancos de los ríos secos)
	-- el Claro Muerto: llano y pelado
	local dc = math.sqrt((lx - CLEARING.X) ^ 2 + (lz - CLEARING.Z) ^ 2)
	h = h + (62 - h) * smooth(CLEARING.R * 1.3, CLEARING.R * 0.7, dc)
	return h
end

local function materialAt(lx: number, lz: number, y: number, slope: number, S: any): string
	if y < S.WaterY + 3 then
		return "Sandstone" -- (orilla de barro oscuro)
	end
	if math.sqrt((lx - CLEARING.X) ^ 2 + (lz - CLEARING.Z) ^ 2) < CLEARING.R then
		return if fbm(lx, lz, 2, 1 / 60, 7.7) > 0.1 then "Basalt" else "Asphalt" -- (tierra quemada y astillas)
	end
	if slope > 1.1 then
		return "Slate"
	elseif slope > 0.7 then
		return "Basalt"
	end
	if fbm(lx, lz, 3, 1 / 140, 23.9 + S.Seed) > 0.2 then
		return "Cobblestone" -- (piedras con musgo)
	end
	return "Limestone" -- (el musgo del suelo del bosque)
end

local S = PlanetSurface.new({
	Id = "Umbria",
	Name = "Umbría",
	Origin = Registry.Slots.Umbria,
	Half = 1100,
	Seed = 57,
	WaterY = 30,
	ArriveY = 1300,
	ClimbY = 1600,
	CeilingY = 2200,
	Floor = -40,
	City = City,
	rawHeight = rawHeight,
	materialAt = materialAt,
	Terrain = { Edge = 300 },
	Lakes = { { X = -460, Z = 420, R = 120, Name = "Lago Espejo" } },
	TerrainColors = {
		Limestone = rgb(58, 80, 46), -- musgo del suelo del bosque
		Cobblestone = rgb(72, 78, 58), -- piedras con musgo
		Sandstone = rgb(70, 56, 40), -- barro oscuro de la orilla
		Slate = rgb(50, 58, 48), -- roca mojada
		Basalt = rgb(42, 44, 40), -- roca negra y tierra quemada
		Asphalt = rgb(56, 48, 40), -- astillas del Claro Muerto
	},
	WaterColor = rgb(40, 84, 76),
	POIs = {
		{ Id = "Umbria_Plataforma", Name = "Claro del Ascensor de Raíz Honda", X = 0, Z = 0, Flat = 44, Pad = true,
			Text = "🛬 El Claro del Ascensor, en Las Raíces de Raíz Honda. Encima, el Árbol Madre se pierde en la niebla." },
		{ Id = "Umbria_Baliza", Name = "Baliza de la Compañía", X = CLEARING.X + 20, Z = CLEARING.Z - 20, Flat = 24,
			Text = "📡 La baliza de la Compañía Torca: una antena de metal en mitad de un bosque de tocones. Todavía parpadea." },
		{ Id = "Umbria_LagoEspejo", Name = "Lago Espejo", X = -460, Z = 420 - 150, Flat = 18,
			Text = "🪞 Agua quieta al pie de una cascada colgante. Debajo, dicen, están las ruinas del Templo de Raíz." },
		{ Id = "Umbria_Templo", Name = "Templo de Raíz", X = -640, Z = 120, Flat = 30,
			Text = "🛕 Piedras talladas con marcas que nadie sabe leer: el primer pueblo de Umbría vivió aquí abajo." },
		{ Id = "Umbria_Nido", Name = "Nido del Gran Escarabajo", X = 600, Z = 300, Flat = 26,
			Text = "🪲 Un nido del tamaño de una casa. Huele a madera mojada. Algo se mueve dentro." },
		{ Id = "Umbria_VainaEnea", Name = "Una vaina vieja", X = 180, Z = 420, Flat = 16,
			Text = "🫘 Una vaina colgada de una raíz baja, cerrada con cuerda. En la puerta pone «Enea». Nadie contesta." },
	},
	NodeCount = 10,
	NodeOres = { { Id = "Hierro", Weight = 3 }, { Id = "Cobalto", Weight = 1 } },
	DecorCounts = { Arbol = 40, SetaGrande = 30, Helecho = 40, Esporera = 30 },
	DecorSlope = { Arbol = 0.6, SetaGrande = 0.6, Helecho = 0.8, Esporera = 0.6 },
})

S.Clearing = CLEARING
S.SporeFields = SPORE_FIELDS
S.Kit = "UmbriaKit"

-- Su cielo y su luz: penumbra verde y dorada bajo las copas, niebla húmeda y las setas que brillan
S.Env = {
	Sky = { "EspacioProfundo", "Original" },
	Clouds = false,
	Mood = {
		Brightness = 1.15,
		Exposure = 0.06,
		Ambient = rgb(38, 56, 40),
		Outdoor = rgb(70, 98, 62),
		EnvDiffuse = 0.6,
		EnvSpecular = 0.6,
		Shadow = 0.45,
		SunTint = rgb(76, 62, 22), -- (la luz dorada que se cuela entre las hojas)
		ShadeTint = rgb(8, 28, 18),
		Density = 0.52,
		Offset = 0.22,
		AtmColor = rgb(72, 108, 78),
		Decay = rgb(36, 66, 48),
		Glare = 0.12,
		Haze = 2.6,
		Tint = rgb(232, 255, 236),
		Saturation = 0.06,
		Contrast = 0.16,
		CCBright = 0,
		Bloom = 1.15,
		BloomSize = 32,
		Threshold = 1.2,
		Rays = 0.04,
		RaysSpread = 0.7,
		Cover = 0,
		CloudDensity = 0,
		CloudColor = rgb(90, 120, 90),
		Veil = 0,
		Overcast = 0,
	},
}

-- Lo que cae (o flota): esporas brillantes siempre; más al anochecer; y la lluvia torrencial
S.Fx = {
	{ Name = "Esporas", Color = rgb(210, 255, 150), Size = 0.25, Rate = 0.5, Speed = 1, Alpha = 0.2, Acceleration = Vector3.new(0.4, 0.3, 0.2), Direction = Enum.NormalId.Bottom },
	{ Name = "LluviaEsporas", Mode = "Esporas", Color = rgb(255, 230, 120), Size = 0.4, Rate = 2, Speed = 2, Alpha = 0.1, Acceleration = Vector3.new(1, -0.4, 0.6) },
	{ Name = "Lluvia", Mode = "Lluvia", Color = rgb(190, 220, 230), Size = 0.15, Rate = 3, Speed = 40, Alpha = 0.3, Acceleration = Vector3.new(0, -60, 0) },
}

---------------------------------------------------------------------
-- Las ESPORAS (diseno-mundos §3.5.11): suben en el Suelo Hondo, deprisa junto a las esporeras y al
-- anochecer (lluvia de esporas); la lluvia de la mañana las lava. Mascarilla de hojas, ungüento de savia
-- y refugios. De noche, abajo, sin farolillo de setas no ves dónde pisas: entran más.
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Esporas",
	Name = "Esporas",
	Icon = "🍄",
	Max = 100,
	Warn = 60,
	Danger = 85,
	Bands = { Esporera = { { 30, 1.4 }, { 90, 0.6 } }, Oscuridad = { { 1, 0.3 } } },
	ZoneRate = { Barrio = 0.1, BarrioEsporas = 0.28, Suelo = 0.45, SueloLluvia = 0.2 },
	Exposed = 0.5, -- (fuera, en la lluvia de esporas del anochecer)
	Recovery = 1.3,
	Gear = {
		MascarillaHojas = { Level = 1, Factor = 0.55 },
		MascarillaSeda = { Level = 2, Factor = 0.3 },
	},
	Consumable = { Item = "UnguentoSavia", Drop = 45, Seconds = 90, Factor = 0.25 },
	Slow = { Aviso = 0.86, Peligro = 0.72 },
	Labels = { Normal = "Esporas", Aviso = "Te pican los ojos (esporas)", Peligro = "¡Demasiadas esporas! Busca un refugio" },
})
S.HazardTint = rgb(200, 255, 140)
S.HazardHints = {
	Normal = "Abajo, en el Suelo Hondo, las esporas suben: 😷 mascarilla de hojas y 🔦 farolillo de setas de noche",
	Aviso = "Vas más lento y estornudas: 🍯 ungüento de savia (mochila) o un refugio",
	Peligro = "Pierdes vida: 🍯 ungüento ya, o la Flor del Mirador, el Tronco Mayor o el herbolario",
}
S.HazardToasts = {
	Aviso = "🍄 Te pican los ojos y estornudas: vas más lento. Ungüento de savia o un refugio.",
	Peligro = "🤧 ¡No puedes respirar de tanta espora! Úntate el ungüento o métete en un refugio ya.",
}
S.KnockText = "🤧 Las esporas te han tumbado. Un vigía te ha subido a un refugio."
S.CounterText = "🍯 Ungüento de savia: las esporas bajan de golpe y durante un rato casi no suben."

function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local lx, lz = S.toLocal(pos)
	local clock = tonumber(info and info.Clock) or 12
	local inside = City.inside(lx, lz, 0)
	local ctx: { [string]: any } = { Near = {} }
	if inside then
		ctx.Zone = if City.spores(clock) then "BarrioEsporas" else "Barrio"
		return ctx
	end
	ctx.Zone = if City.rain(clock) then "SueloLluvia" else "Suelo"
	ctx.Exposed = City.spores(clock)
	local near = {}
	for _, f in SPORE_FIELDS do
		local d = math.sqrt((lx - f.X) ^ 2 + (lz - f.Z) ^ 2) - f.R
		if d < 90 then
			table.insert(near, math.max(0, d))
		end
	end
	ctx.Near.Esporera = near
	local items = info and info.Items
	if City.night(clock) and not (items and (tonumber(items.FarolSetas) or 0) > 0) then
		ctx.Near.Oscuridad = 0
	end
	return ctx
end

function S.moment(clock: number, _pos: Vector3?): string?
	if City.spores(clock) then
		return "Esporas"
	elseif City.rain(clock) then
		return "Lluvia"
	end
	return nil
end

S.CrowdLines = {
	"Toca la corteza al pasar. Así saluda la gente de Raíz Honda.",
	"¿Has oído el zumbido? Antes de verlas, se oyen.",
	"Mi turno de guardia es a medianoche. El tuyo, si vives aquí, también llegará.",
	"Nunca se corta un árbol vivo. Nunca. Ni para frenar a las máquinas.",
	"Al anochecer caen esporas. Son preciosas. Y pican como mil demonios.",
	"Dicen que Garza ha vuelto. El hijo de Enea. Después de veinte años.",
	"Las máquinas se comen la madera y hacen más máquinas. ¿Quién inventa algo así?",
	"Si suena el cuerno tres veces, todo el mundo a la Flor del Mirador.",
}

---------------------------------------------------------------------
-- El oficio de Umbría: PODADOR/A (diseno-mundos §3.5.9). Ir al árbol enfermo → cortar la rama muerta
-- (minijuego) → coger savia ámbar de un cubo → untar la herida (quieto un rato).
---------------------------------------------------------------------
PlanetJobs.register({
	{
		Id = "UmbriaPodador",
		Planet = "Umbria",
		PlanetName = "Umbría",
		Name = "Podador/a",
		Icon = "🪓",
		Desc = "Cura los árboles de Raíz Honda: corta las ramas muertas y pon savia ámbar en las heridas.",
		Pay = 45,
		MinSeconds = 20,
		Board = City.Jobs.BoardPodador,
		BoardFace = { 1, 0 },
		PayText = "desde 45 € por árbol (más con el rango)",
		Place = "Raíz Honda (Umbría)",
		EnergyCost = 4,
		Drop = { Item = "SaviaAmbar", Chance = 0.35 },
		CarryColor = rgb(230, 160, 50),
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local trees = City.Jobs.Arboles
			local tree = trees[math.floor(r() * #trees) + 1]
			local bucket = City.Jobs.Cubos[math.floor(r() * #City.Jobs.Cubos) + 1]
			return {
				{ Kind = "Go", At = tree, Text = "Ve al árbol enfermo y corta la rama muerta (con cuidado: no la sana)",
					Game = PlanetJobs.timing("Cortar la rama muerta", "🪓", "Pulsa cuando el hacha esté sobre la madera seca", rank) },
				{ Kind = "Go", At = bucket, Text = "Coge un cubo de savia ámbar", },
				{ Kind = "Go", At = tree, Text = "Lleva la savia al árbol (que no se derrame)", Carry = rgb(230, 160, 50) },
				{ Kind = "Hold", At = tree, Seconds = 3, Drop = true, Text = "Unta la savia en la herida… despacio" },
			}
		end,
	},
})
S.Jobs = PlanetJobs.of("Umbria")

return S
