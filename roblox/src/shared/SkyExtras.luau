-- SkyExtras: los cielos especiales, la luna, el fuego, la lluvia, las partículas y los pasos que vienen
-- de los assets de la Tienda que pidió el dueño (docs/assets-implementados.md, sección «Cielo, tiempo,
-- efectos, luz y sonidos»). Solo datos y cuentas puras (se prueban fuera de Roblox:
-- scripts/test-skyextras.luau). Lo carga el servidor (World/SkyAssets) y lo pinta el cliente
-- (Controllers/SkyExtras y Controllers/Footsteps).
--
-- Seguridad: los cielos 113036863157630, 135266547724797 y 92375378852064 traen una puerta trasera
-- (docs/assets-usuario-4.md, familias 2, 4 y 5): NO se cargan. Aquí solo están los números de sus
-- imágenes (una imagen no ejecuta nada) y el cliente los pone en un Sky nuevo hecho por nosotros.

local SkyExtras = {}

SkyExtras.Library = "SkyLibrary" -- (la misma carpeta que shared/SkyChoice)
SkyExtras.FxLibrary = "FxLibrary" -- ReplicatedStorage.FxLibrary: plantillas e imágenes cargadas
SkyExtras.Faces = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

local function six(bk: number, dn: number, ft: number, lf: number, rt: number, up: number): { [string]: string }
	local ids = { bk, dn, ft, lf, rt, up }
	local out = {}
	for i, face in SkyExtras.Faces do
		out[face] = "rbxassetid://" .. ids[i]
	end
	return out
end

-- Cielos hechos a mano con las imágenes de los assets (orden Bk, Dn, Ft, Lf, Rt, Up)
SkyExtras.Skies = {
	-- 113036863157630 «Green Clouds Skybox»: verde oscuro tormentoso → sucesos raros (la Grieta verde)
	Verde = { Source = 113036863157630, Faces = six(921881811, 921881907, 921881989, 921882045, 921882121, 921882259) },
	-- 135266547724797 «Sky Cloud Floating Island»: una sola imagen morada en las 6 caras → el sueño del prólogo
	Isla = { Source = 135266547724797, Faces = six(2245858419, 2245858419, 2245858419, 2245858419, 2245858419, 2245858419) },
	-- 92375378852064 «Rainbow Sky»: degradado arcoíris pastel → sueños (dormir) y momentos dorados
	Arcoiris = { Source = 92375378852064, Faces = six(12877085497, 12877086914, 12877085497, 12877085497, 12877085497, 12877083856) },
	-- 295604372 «Asteroid space skybox» (limpio): la noche de la lluvia de estrellas
	Asteroides = { Source = 295604372, Faces = six(198433424, 198442292, 198433337, 198437520, 198437454, 198433823) },
}

-- 102765136165948 «Classic Skyboxes Collection» (11 cielos clásicos de Roblox). El pack trae puerta
-- trasera (familia 4): el servidor lo descarga a memoria SIN meterlo en el juego, copia solo las 6
-- caras de cada Sky a un Sky nuevo y lo destruye entero al momento (ningún script llega a correr).
SkyExtras.ClassicId = 102765136165948
SkyExtras.Classic = {
	{ Match = "winter", Slot = "Clasico_Invierno" },
	{ Match = "autumn", Slot = "Clasico_Otono" },
	{ Match = "utter east", Slot = "Clasico_Este" },
	{ Match = "great west", Slot = "Clasico_Oeste" },
	{ Match = "starry", Slot = "Clasico_Estrellas" },
	{ Match = "oblivion", Slot = "Clasico_Olvido" },
	{ Match = "tron", Slot = "Clasico_Rejilla" },
	{ Match = "broken", Slot = "Clasico_Roto" },
	{ Match = "alien", Slot = "Clasico_Rojo" },
	{ Match = "2009%-2013", Slot = "Clasico_Liso" },
	{ Match = "2006%-2009", Slot = "Clasico_Antiguo" },
}

-- El nombre de un Sky del pack clásico -> su hueco en SkyLibrary (nil = no se conoce)
function SkyExtras.classicSlot(name: string): string?
	local lower = string.lower(name)
	for _, entry in SkyExtras.Classic do
		if string.find(lower, entry.Match) then
			return entry.Slot
		end
	end
	return nil
end

-- Una cara de cielo que vale: un id de imagen normal (nada raro dentro)
function SkyExtras.validFace(value: any): boolean
	if type(value) ~= "string" or #value > 80 then
		return false
	end
	return string.match(value, "^rbxassetid://%d+$") ~= nil
		or string.match(value, "^http://www%.roblox%.com/asset/%?id=%d+$") ~= nil
		or string.match(value, "^https?://www%.roblox%.com/asset/%?id=%d+$") ~= nil
		or string.match(value, "^rbxasset://[%w_/%.]+$") ~= nil
end

---------------------------------------------------------------------
-- Qué cielo especial toca ahora (encima del de día / noche de shared/SkyChoice)
---------------------------------------------------------------------

-- Capas de cielo de la historia (shared/SkyMoods) que cambian también las caras del cielo
SkyExtras.MoodSkies = {
	GrietaVerde = "Verde", -- algo sale de la grieta: cielo verde
	Ominoso = "Verde",
	Apagon = "Clasico_Olvido", -- apagón: cielo negro
	Dorado = "Arcoiris", -- un momento feliz y dorado: el cielo de sueño
}
-- El tiempo de día: con lluvia, tormenta o nieve no pega un cielo azul de foto
SkyExtras.WeatherSkies = {
	Lluvia = "Clasico_Roto",
	Tormenta = "Clasico_Roto",
	Nieve = "Clasico_Invierno",
	Niebla = "Original",
}

-- La lluvia de estrellas (4927992927 «Meteors!» hacía daño: aquí solo se ven): unas noches de cada
-- cinco días de juego, de 22:00 a 1:30. Igual para todo el servidor (sale del día y la hora).
function SkyExtras.meteorNight(day: number, hour: number): boolean
	hour = hour % 24
	return (math.floor(day) % 5 == 2) and (hour >= 22 or hour < 1.5)
end

export type SkyState = {
	Prologue: boolean?, -- en el sueño del prólogo (isla del cielo)
	Sleeping: boolean?, -- durmiendo: se sueña
	Moods: { string }?, -- capas de cielo de la historia que están puestas
	Weather: string?,
	Hour: number?,
	Day: number?,
	Night: boolean?, -- ¿es de noche para el cielo de fotos? (SkyChoice.phase)
}

-- Devuelve el hueco de SkyLibrary que hay que enseñar ("Original" = el cielo de siempre del archivo,
-- nil = el normal de día / noche). have: los cielos que hay cargados (have[slot] = true).
function SkyExtras.pick(state: SkyState, have: { [string]: boolean }): string?
	local function ok(slot: string?): boolean
		return slot ~= nil and (slot == "Original" or have[slot] == true)
	end
	if state.Prologue and ok("Isla") then
		return "Isla"
	end
	for _, mood in state.Moods or {} do
		local slot = SkyExtras.MoodSkies[mood]
		if ok(slot) then
			return slot
		end
	end
	if state.Sleeping and ok("Arcoiris") then
		return "Arcoiris"
	end
	if state.Day and state.Hour and SkyExtras.meteorNight(state.Day, state.Hour) and ok("Asteroides") then
		return "Asteroides"
	end
	if not state.Night and state.Weather then
		local slot = SkyExtras.WeatherSkies[state.Weather]
		if slot then
			return if ok(slot) then slot else "Original"
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Luna (12737479807 y 8159177542)
---------------------------------------------------------------------

-- 12737479807 «Realistic Moon/Sun Graphics»: solo sus valores de la luna (el script no se usa: el
-- desenfoque emborrona y la luz ya la lleva DayLight)
SkyExtras.Moon = { TextureId = "rbxassetid://9013498676", AngularSize = 14 }
-- 8159177542 «Most Realistic Moon in PBR»: la luna 3D (malla con SurfaceAppearance) de noche
SkyExtras.MoonMeshId = 8159177542
SkyExtras.MoonDistance = 900 -- studs delante de la cámara (sin paralaje: se mueve con ella)
SkyExtras.MoonDegrees = 3.2 -- lo que ocupa en el cielo

-- Diámetro (studs) para que algo a `distance` ocupe `degrees` del cielo
function SkyExtras.moonDiameter(distance: number, degrees: number): number
	return 2 * distance * math.tan(math.rad(degrees) / 2)
end

-- ¿Se ve la luna 3D? De noche (el sol bajo) y con la luna por encima del horizonte
function SkyExtras.moonVisible(hour: number, moonHeight: number): boolean
	hour = hour % 24
	return (hour >= 19.2 or hour < 5.6) and moonHeight > 0.05
end

---------------------------------------------------------------------
-- Fuego, lluvia, nube de tormenta y agua
---------------------------------------------------------------------

SkyExtras.FireId = 11365590395 -- «Realistic Fire With Smoke»: ParticleEmitter + Smoke
SkyExtras.FireImage = "rbxassetid://160041569" -- (su imagen, por si no carga)
SkyExtras.RainId = 11552439884 -- «Realistic Rain»: nos quedamos su gota (la nuestra era humo estirado)
SkyExtras.RainImage = "rbxassetid://3806148993"
SkyExtras.RainSound = "rbxassetid://9064263922" -- (público; solo si nuestra lluvia no tiene audio)
SkyExtras.CloudId = 979423743 -- «lightning & thunder cloud»: la nube de malla para las tormentas
SkyExtras.WaterId = 223224044 -- «Realistic Animated water»: sus texturas, movidas por nosotros
SkyExtras.ParticlesId = 13188926423 -- «Bingus Particle Pack»: 240 imágenes para partículas

-- Imágenes del pack de partículas que se usan, por palabras de su nombre (en orden de preferencia)
SkyExtras.ImageKeys = {
	{ Key = "Chispa", Words = { "spark" } },
	{ Key = "Cometa", Words = { "comet" } },
	{ Key = "Rayo", Words = { "lightning" } },
	{ Key = "Copo", Words = { "snowflake", "snow" } },
	{ Key = "Hoja", Words = { "leaf" } },
	{ Key = "HumoDenso", Words = { "dense fog" } },
	{ Key = "Humo", Words = { "small fog", "fog cluster", "smoke", "fog" } },
	{ Key = "Burbuja", Words = { "bubble" } },
	{ Key = "Fuegos", Words = { "firework" } },
	{ Key = "Destello", Words = { "star sparkle", "sparkle" } },
	{ Key = "Golpe", Words = { "slash" } },
}

-- El nombre de una pieza del pack -> la clave que usamos (nil = no se usa)
function SkyExtras.imageKey(name: string): string?
	local clean = string.lower(name)
	clean = string.gsub(clean, "[%d_%-%.]+", " ")
	clean = string.gsub(clean, "%s+", " ")
	for _, entry in SkyExtras.ImageKeys do
		for _, word in entry.Words do
			if string.find(clean, word, 1, true) then
				return entry.Key
			end
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Pasos según el suelo (131772048424194 y 5033818552)
---------------------------------------------------------------------

-- Los audios PÚBLICOS de los dos packs (los demás no suenan en nuestro juego). Origen: SCP:
-- Containment Breach (CC BY-SA 3.0, crédito en docs/assets-implementados.md) y «Carpet Footstep»
-- (bloberous). En el juego no sale ningún nombre.
SkyExtras.Steps = {
	Duro = { Id = "rbxassetid://137390607880889", Volume = 0.42 },
	Blando = { Id = "rbxassetid://136262802708360", Volume = 0.5 },
	Metal = { Id = "rbxassetid://5676592633", Volume = 0.4 },
	Tela = { Id = "rbxassetid://133705377", Volume = 0.45 },
}
local STEP_KIND = {
	Grass = "Blando", LeafyGrass = "Blando", Sand = "Blando", Snow = "Blando", Ground = "Blando",
	Mud = "Blando", Salt = "Blando", Glacier = "Blando",
	Metal = "Metal", DiamondPlate = "Metal", CorrodedMetal = "Metal", Foil = "Metal", ForceField = "Metal",
	Fabric = "Tela", Carpet = "Tela", Rubber = "Tela", Leather = "Tela",
}
-- Tono por material (la misma pisada suena distinta en madera, piedra o cristal)
local STEP_PITCH = {
	Wood = 0.82, WoodPlanks = 0.8, Glass = 1.18, Ice = 1.15, Marble = 1.08, Granite = 1.02,
	Sand = 0.9, Snow = 0.85, Mud = 0.75, Grass = 1.05, LeafyGrass = 1, Metal = 1, DiamondPlate = 1.08,
}
local SILENT = { Air = true, Water = true }

-- El sonido de una pisada: { Id, Volume, Pitch } o nil (aire, agua)
function SkyExtras.footstep(material: string): { Id: string, Volume: number, Pitch: number }?
	if SILENT[material] then
		return nil
	end
	local kind = STEP_KIND[material] or "Duro"
	local base = SkyExtras.Steps[kind]
	return { Id = base.Id, Volume = base.Volume, Pitch = STEP_PITCH[material] or 1 }
end

-- Cada cuánto suena un paso a esta velocidad (studs/s); nil = parado
function SkyExtras.stepInterval(speed: number): number?
	if speed < 2.5 then
		return nil
	end
	return math.clamp(6.5 / speed, 0.24, 0.62)
end

return SkyExtras
