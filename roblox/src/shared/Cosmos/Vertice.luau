-- VÉRTICE · la superficie del planeta-ciudad (docs/planetas/diseno-mundos.md §3.7; marco común:
-- docs/planetas/marco-planetas.md; lo jugable ahora: docs/planetas/talasa-vertice.md). Cuentas puras con
-- shared/Cosmos/PlanetSurface.new.
--
-- Vértice es UNA ciudad: abajo, el Nivel Bajo (asfalto, fábricas y los Aliviaderos inundados); a 90 studs,
-- el Nivel Medio de Distrito Cero (shared/Cosmos/VerticeCity), colgado sobre el hueco. Arriba, la Cúpula
-- de anuncios que hace de cielo, y más allá, los anillos de los Astilleros Orbitales.
--
-- La desventaja (§3.7.10-11): la VIGILANCIA de MegaVerso. Sube cerca de las cámaras, al correr por la
-- acera («multa automática») y sin permiso fuera del Distrito. Contramedidas: la gorra
-- antirreconocimiento y el traje Camaleón (equipo), el inhibidor de cámaras (consumible) y los sitios sin
-- cámaras (refugios: el Arcade, el Rastro, la clínica, la casa de Rosa). Nunca quita nada: si se llena,
-- la seguridad privada te «acompaña» a un sitio del Rastro y la multa se archiva.
-- El oficio propio: técnico/a de cúpula (paneles y farolas antes del apagón, §3.7.9).

local PlanetSurface = require(script.Parent.PlanetSurface)
local PlanetHazard = require(script.Parent.PlanetHazard)
local PlanetJobs = require(script.Parent.PlanetJobs)
local Registry = require(script.Parent.PlanetRegistry)
local City = require(script.Parent.VerticeCity)

local rgb = Color3.fromRGB
local smooth = PlanetSurface.smooth
local fbm = PlanetSurface.fbm

local GROUND = 30
local WATER = 12

local S = PlanetSurface.new({
	Id = "Vertice",
	Name = "Vértice",
	Origin = Registry.Slots.Vertice,
	Half = 1024,
	Seed = 77,
	WaterY = WATER,
	PadY = GROUND + 90, -- (el Nivel Medio: 90 studs sobre el Nivel Bajo)
	City = City,
	Terrain = { Edge = 0 },
	rawHeight = function(lx: number, lz: number, _S: any): number
		-- el Nivel Bajo: llano, con los Aliviaderos (canales inundados) en cuadrícula
		local h = GROUND + 1.5 * fbm(lx, lz, 2, 1 / 300, 1.7)
		local gx = math.abs(((lx + 60) % 240) - 120)
		local gz = math.abs(((lz + 60) % 300) - 150)
		local canal = math.max(smooth(14, 6, gx), smooth(14, 6, gz) * smooth(400, 300, math.abs(lx)))
		return h - (GROUND - WATER + 6) * canal
	end,
	materialAt = function(lx: number, lz: number, y: number, slope: number, _S: any): string
		if y < WATER + 2 then
			return "Concrete"
		elseif slope > 0.5 then
			return "Concrete"
		end
		local gx = math.abs(((lx + 60) % 60) - 30)
		local gz = math.abs(((lz + 60) % 60) - 30)
		return if gx < 4 or gz < 4 then "Pavement" else "Asphalt"
	end,
	TerrainColors = {
		Asphalt = rgb(26, 26, 36), -- el asfalto negro del Nivel Bajo
		Pavement = rgb(60, 58, 76), -- aceras con líneas
		Concrete = rgb(70, 72, 86),
	},
	WaterColor = rgb(40, 60, 90), -- el agua oscura de los Aliviaderos
	POIs = {
		{ Id = "Vertice_Plataforma", Name = "Plataforma de Distrito Cero", X = 0, Z = 0, Flat = 40, Pad = true, Text = "La plataforma de Distrito Cero, colgada sobre el Nivel Bajo." },
		{ Id = "Vertice_Vertedero", Name = "El Vertedero Infinito", X = -520, Z = 360, Flat = 50, Action = "Rebuscar", Text = "El Vertedero Infinito: montañas de pantallas, carros y anuncios rotos. Los Chatarreros saben qué vale." },
		{ Id = "Vertice_Cementerio", Name = "Cementerio de Marcas", X = 480, Z = -380, Flat = 40, Text = "Carteles gigantes de empresas quebradas, uno detrás de otro. Ninguna existe ya. Todas siguen sonriendo." },
		{ Id = "Vertice_Central", Name = "Central de Luz Embotellada", X = 420, Z = 420, Flat = 50, Text = "La Central de Luz Embotellada. Zumba. Por las ventanas sale una luz que no calienta." },
	},
	NodeCount = 5,
	NodeOres = { { Id = "Hierro", Weight = 3 }, { Id = "Cobalto", Weight = 1 } },
	DecorCounts = { Basura = 16 },
	DecorSlope = { Basura = 0.6 },
})

S.Kit = "VerticeKit"

-- La luz de la Cúpula: blanco frío, neones de anuncio y bruma rosada (nombres de DayGrade)
S.Env = {
	Sky = { "CieloVertice", "Original" },
	Clouds = false,
	Mood = {
		Brightness = 1.8,
		Exposure = 0.02,
		Ambient = rgb(70, 60, 110),
		Outdoor = rgb(120, 120, 170),
		EnvDiffuse = 0.7,
		EnvSpecular = 1,
		Shadow = 0.3,
		SunTint = rgb(30, 40, 70),
		ShadeTint = rgb(30, 10, 50),
		Density = 0.38,
		Offset = 0.2,
		AtmColor = rgb(200, 150, 220),
		Decay = rgb(90, 60, 130),
		Glare = 0.2,
		Haze = 2.2,
		Tint = rgb(246, 240, 255),
		Saturation = 0.12,
		Contrast = 0.18,
		CCBright = 0,
		Bloom = 1.3,
		BloomSize = 30,
		Threshold = 1.05,
		Rays = 0.04,
		RaysSpread = 0.3,
		Cover = 0,
		CloudDensity = 0,
		Veil = 0,
		Overcast = 0,
	},
}

---------------------------------------------------------------------
-- La desventaja: la VIGILANCIA
---------------------------------------------------------------------
S.Hazard = PlanetHazard.new({
	Id = "Vigilancia",
	Name = "Vigilancia",
	Icon = "👁",
	Max = 100,
	Warn = 60,
	Danger = 85,
	Bands = {
		Camara = { { 12, 2.2 }, { 26, 0.7 } },
		Correr = { { 1, 1.4 } },
	},
	ZoneRate = { SinPermiso = 1.4, Torre = 1.2 },
	Recovery = 2.6,
	DangerDamage = 1,
	Gear = {
		Vertice_GorraAnti = { Level = 1, Factor = 0.55 },
		Vertice_TrajeCamaleon = { Level = 2, Factor = 0.3 },
	},
	Consumable = { Item = "Vertice_Inhibidor", Drop = 45, Seconds = 60, Factor = 0.2 },
	Labels = { Normal = "Vigilancia", Aviso = "Te están mirando", Peligro = "¡Seguridad en camino!" },
})
S.HazardTint = rgb(255, 60, 160)
S.HazardHints = {
	Normal = "Las cámaras de MegaVerso suben el medidor. No corras por la acera.",
	Aviso = "Aléjate de las cámaras o usa un inhibidor 📵",
	Peligro = "¡Escóndete en el Arcade, el Rastro o la clínica!",
}
S.HazardToasts = {
	Aviso = "👁 «Cliente detectado. Comportamiento irregular». Aléjate de las cámaras o usa un 📵 inhibidor.",
	Peligro = "🚨 «Seguridad privada en camino». Escóndete donde no haya cámaras: el Arcade, el Rastro, la clínica.",
}
S.KnockText = "🚨 La seguridad privada te ha «acompañado» al Rastro. La multa se archiva (esta vez)."
S.CounterText = "📵 Inhibidor de cámaras: durante un minuto las cámaras te ven borroso"

-- Lo que rodea al jugador: cámaras cerca, si corre, si está fuera del Distrito o al pie de la Torre
function S.hazardContext(pos: Vector3, info: { [string]: any }): { [string]: any }
	local lx, lz = S.toLocal(pos)
	local ctx: { [string]: any } = { Near = {} }
	if not City.inside(lx, lz, 20) then
		ctx.Zone = "SinPermiso"
		return ctx
	end
	ctx.Near.Camara = City.cameraDistances(lx, lz)
	if lz < -60 and math.abs(lx) < 60 then
		ctx.Zone = "Torre"
	end
	-- (correr por la acera: lo mira el servidor con la velocidad de verdad del cuerpo)
	local player = info.Player
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and typeof(root) == "Instance" then
		local v = (root :: BasePart).AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > 20 then
			ctx.Near.Correr = 0
		end
	end
	return ctx
end

-- El momento (Soundscapes.Planets.Vertice.Modes): la Cúpula apagada (23-7) y la hora punta
function S.moment(clock: number, _pos: Vector3?): string?
	local h = clock % 24
	if h >= 23 or h < 7 then
		return "Apagon"
	elseif (h >= 8 and h < 9) or (h >= 18 and h < 19) then
		return "HoraPunta"
	end
	return nil
end

-- Lo que cae del cielo: chispas de los anuncios (rosa y cian) y, a la hora del riego, lluvia
S.Fx = {
	{ Name = "ChispasRosa", Color = rgb(255, 90, 200), Size = 0.14, Rate = 6 },
	{ Name = "ChispasCian", Color = rgb(80, 240, 255), Size = 0.14, Rate = 6 },
}

S.CrowdLines = {
	"Gracias por su compra.",
	"¿Has visto el precio del pan? Ayer valía la mitad.",
	"Cuidado con correr: la cámara de la esquina multa.",
	"Tres empleos y no me llega. Pero tengo puntos.",
	"Dicen que en el Rastro todavía se puede hablar alto.",
	"Mi bloque sale en la lista. Liquidación Total, dicen.",
	"La Cúpula se apaga a las once. Que no te pille en la calle.",
	"¿Tú también eres de fuera? Aquí todos somos de fuera.",
	"¡Oferta relámpago! …No, era un anuncio. Siempre es un anuncio.",
	"Mi puntuación de cliente es 412. Ya no me dejan entrar al mag-lev.",
}

---------------------------------------------------------------------
-- El oficio propio: técnico/a de cúpula (§3.7.9)
---------------------------------------------------------------------
-- Las farolas y paneles que fallan (por fuera de los edificios, en las cubiertas)
S.Panels = {
	{ Id = "Plaza", Name = "el panel de la Plaza del Primer Cliente", At = { 40, 64 } },
	{ Id = "Avenida", Name = "la farola grande de la Avenida", At = { -100, 108 } },
	{ Id = "Oficinas", Name = "el panel de luz de la Torre", At = { 30, -70 } },
	{ Id = "Maglev", Name = "el foco del andén del mag-lev", At = { 130, 22 } },
	{ Id = "Plantilla", Name = "la farola del Barrio Plantilla", At = { 116, 64 } },
	{ Id = "Rastro", Name = "el cable del Rastro", At = { -120, 4 } },
}
S.JobBoard = { 30, 58 }
PlanetJobs.register({
	{
		Id = "VerticeTecnicoCupula",
		Planet = "Vertice",
		PlanetName = "Vértice",
		Name = "Técnico/a de cúpula",
		Icon = "💡",
		Desc = "La luz embotellada falla y los paneles se apagan: repáralos antes del próximo apagón.",
		Pay = 55,
		MinSeconds = 35,
		Board = S.JobBoard,
		BoardFace = { 0, -1 },
		Place = "Distrito Cero (Vértice)",
		EnergyCost = 3,
		CarryColor = rgb(255, 230, 120),
		Drop = { Item = "Vertice_ChipUsado", Chance = 0.35 },
		task = function(r: () -> number, rank: number, _job: any): { { [string]: any } }
			local a, ia = PlanetJobs.pick(S.Panels, r)
			local b = PlanetJobs.pick(S.Panels, r, ia)
			local spec = PlanetJobs.timing("Panel de luz", "💡", "Suelda el contacto cuando la aguja pase por el verde", rank)
			return {
				{ Kind = "Go", At = a.At, Text = "Ve a " .. a.Name .. " (llevas una botella de luz de repuesto)", Carry = rgb(255, 230, 120) },
				{ Kind = "Game", Spec = spec },
				{ Kind = "Go", At = b.At, Text = "Ahora " .. b.Name .. ": parpadea, va a apagarse" },
				{ Kind = "Game", Spec = spec },
				{ Kind = "Hold", At = { S.JobBoard[1] + 6, S.JobBoard[2] + 4 }, Seconds = 3, Text = "Firma el parte en el tablón (MegaVerso no paga sin parte)" },
			}
		end,
	},
})
S.Jobs = PlanetJobs.of("Vertice")

return S
