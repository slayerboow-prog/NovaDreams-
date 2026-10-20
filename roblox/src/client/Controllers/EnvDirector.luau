-- EnvDirector (cliente): el ÚNICO dueño del cielo y del entorno por zona (shared/Cosmos/EnvZones,
-- docs/espacio-aaa/entorno.md). Cada jugador el suyo: cada uno puede estar en un sitio distinto.
--
--   * 10 veces por segundo mira dónde está la cámara (Valmar, la transición, el espacio, entrando en un
--     planeta o en su superficie, la arena) y lo suaviza (EnvZones.approach: sin fogonazos al pasar de
--     la nave a la superficie). Los interruptores llevan histéresis (EnvZones.flags): sin parpadeos.
--   * Se lo da a Controllers/DayLight (setZone): el cielo de la zona manda sobre todos, su luz se mezcla
--     la última, y DayLight aparta la bruma (Atmosphere), las nubes y el etalonaje de Valmar en el
--     espacio, y sube las estrellas según el nivel gráfico.
--   * La Grieta del cielo (SkyRift, motivo "Zona"), la lluvia y la nieve (Weather), la tormenta, la luna
--     3D y las estrellas fugaces (SkyExtras) preguntan aquí si les toca (EnvDirector.allows).
--   * El HUD de Valmar en un planeta: fuera el GPS, el minimapa, la tarjeta de misión de Valmar y sus
--     marcadores (UI/FlightFocus.setZone). La luz del planeta, sus estrellas y su VISOR siguen.
--   * Bajo el agua (zona «Submarino», mar enorme v120): Controllers/SeaBiome le cuenta cuánto está la
--     cámara bajo el agua y la luz del agua de la zona y la hondura (setSea); EnvZones lo mezcla y
--     DayLight lo pinta. Sin lluvia ni nieve bajo el agua.
--   * EL SONIDO DE LA ZONA (docs/audio/zonas.md): con la misma zona, shared/Cosmos/Soundscapes dice qué
--     ambiente y qué música tocan (espacio, crucero, combate, estación, Tefra y sus bombardeos, el mar,
--     Nácara, los demás planetas) y se lo da a Controllers/StoryAudio (setZone: fundido cruzado). Los
--     bucles de Valmar (pájaros, viento, lluvia, grillos, olas, la ciudad) preguntan aquí cuánto les
--     toca (EnvDirector.valmarAudio: 1 en Valmar, 0 fuera). Un solo dueño: el cielo y el sonido nunca
--     dicen zonas distintas.
-- En la arena de pruebas no hace nada con el cielo: allí manda AirCombatClient (su cielo y su luz).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local EnvZones = require(Cosmos.EnvZones)
local Tefra = require(Cosmos.Tefra)
local Soundscapes = require(Cosmos.Soundscapes)

local EnvDirector = {}

local player = Players.LocalPlayer
EnvDirector.Every = 0.1 -- segundos entre vueltas

-- Las superficies que hay (como PlanetClient)
local SURFACES: { [string]: any } = { Tefra = Tefra }

local env: EnvZones.Env? = nil
local flags: EnvZones.Flags? = nil
local riftOff: boolean? = nil
local planetHud: boolean? = nil
local sea: EnvZones.Sea? = nil
local scape: Soundscapes.Scape? = nil -- el sonido de la zona (shared/Cosmos/Soundscapes)
local pushed: Soundscapes.Scape? = nil -- el último que se dio a StoryAudio
local combatUntil: number? = nil -- (la cola de la música de combate)

-- Bajo el agua (lo llama Controllers/SeaBiome): cuánto (0..1, ya suavizado) y la luz del agua
-- (OceanBiomes.look; nil = río, lago o sin saber aún). nil = fuera del agua.
function EnvDirector.setSea(under: number?, look: { [string]: any }?)
	if not under or under <= 0.001 then
		sea = nil
	else
		sea = { Under = under, Look = look }
	end
end

-- (perezosos: DayLight, SkyRift y PlanetClient se cargan cuando ya existen; sin ciclos al arrancar)
local LOADERS: { [string]: () -> any } = {
	DayLight = function()
		return require(script.Parent.DayLight)
	end,
	SkyRift = function()
		return require(script.Parent.SkyRift)
	end,
	PlanetClient = function()
		return require(script.Parent.PlanetClient)
	end,
	StoryAudio = function()
		return require(script.Parent.StoryAudio)
	end,
	AirCombatClient = function()
		return require(script.Parent.AirCombatClient)
	end,
	-- (lo de shared que solo hace falta para el sonido)
	Stations = function()
		return require(Cosmos.Stations)
	end,
	Varkun = function()
		return require(Cosmos.Varkun)
	end,
	TefraCity = function()
		return require(Cosmos.TefraCity)
	end,
	Nacara = function()
		return require(ReplicatedStorage.Shared.Sea.Nacara)
	end,
}
local loaded: { [string]: any } = {}
local function lazy(name: string): any
	local mod = loaded[name]
	if mod == nil then
		local ok, result = pcall(LOADERS[name])
		if ok then
			loaded[name] = result
			mod = result
		end
	end
	return mod
end

-- Lo que hay ahora alrededor de la cámara (para EnvZones.resolve)
function EnvDirector.input(camPos: Vector3): EnvZones.Input
	local arena = player:GetAttribute("AirCombatWorld") == "Arena"
	local surface: string? = nil
	if not arena then
		for id, S in SURFACES do
			if S.inRegion(camPos, 200) then
				surface = id
				break
			end
		end
	end
	local entry = nil
	local PlanetClient = lazy("PlanetClient")
	if PlanetClient and PlanetClient.envEntry then
		entry = PlanetClient.envEntry()
	end
	return { Pos = camPos, Arena = arena, Surface = surface, Entry = entry, Sea = sea }
end

-- Lo que pasa alrededor para el sonido (shared/Cosmos/Soundscapes.Context). camPos = la cámara; el
-- refugio de Tefra y Nácara miran el cuerpo (con la cámara de lejos, el cuerpo es el que está dentro).
-- now = reloj (para la cola del combate).
function EnvDirector.soundContext(camPos: Vector3, now: number?): Soundscapes.Context
	local ctx: Soundscapes.Context = {}
	local t = now or os.clock()
	local body = camPos
	pcall(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			body = root.Position
		end
	end)
	-- Combate: el servidor dice si hay peligro (enemigos cerca, te acaban de dar: piratas, patrullas,
	-- los Hilanderos de Varkun) y la Rueca de Varkun, mientras está en el cielo
	local fighting = false
	pcall(function()
		if player:GetAttribute("AirCombat") == nil then
			return -- (sin nave: no hay combate en el espacio)
		end
		local AC = lazy("AirCombatClient")
		local q = AC and AC.quantumState and AC.quantumState()
		fighting = type(q) == "table" and q.InCombat == true
	end)
	pcall(function()
		local Varkun = lazy("Varkun")
		local scene = workspace:FindFirstChild("VarkunEscena")
		if Varkun and scene and scene:FindFirstChild("LaRueca") and (camPos - Varkun.RuecaPos).Magnitude < 3000 then
			fighting = true
		end
	end)
	ctx.Combat, combatUntil = Soundscapes.latch(combatUntil, fighting, t)
	-- Estaciones: atracado (el servidor) o cerca (su zona segura)
	pcall(function()
		ctx.Docked = player:GetAttribute("SpaceStation") ~= nil
		local Stations = lazy("Stations")
		if Stations then
			for _, st in Stations.List do
				if (camPos - st.Center).Magnitude < Stations.SafeRadius then
					ctx.NearStation = true
					break
				end
			end
		end
	end)
	-- Tefra: refugios, bombardeos (workspace.TefraWar) y la tregua (memoria del mundo del jugador)
	if Tefra.inRegion(body, 200) then
		pcall(function()
			local TefraCity = lazy("TefraCity")
			if TefraCity then
				local lx, lz = Tefra.toLocal(body)
				ctx.Shelter = TefraCity.shelterAt(lx, lz) ~= nil
			end
		end)
		pcall(function()
			local war = workspace:GetAttribute("TefraWar")
			if type(war) == "string" then
				ctx.Raid = string.match(war, '"State"%s*:%s*"(%a+)"')
			end
			local memory = player:GetAttribute("WorldState")
			ctx.Tregua = type(memory) == "string" and string.find(memory, '"Tefra.Tregua"', 1, true) ~= nil
		end)
	end
	-- Nácara: bajo el mar, junto a su plaza (o dentro de la cúpula de aire)
	pcall(function()
		local Nacara = lazy("Nacara")
		if Nacara and body.Y < -2 then
			local dx, dz = body.X - Nacara.Center.X, body.Z - Nacara.Center.Z
			ctx.Nacara = dx * dx + dz * dz < Soundscapes.NacaraRadius * Soundscapes.NacaraRadius
		end
	end)
	return ctx
end

-- El sonido de la zona: se resuelve con la misma zona que el cielo y se da a StoryAudio solo si cambia
local function updateSound(e: EnvZones.Env, pos: Vector3, now: number?)
	scape = Soundscapes.resolve(e, EnvDirector.soundContext(pos, now), scape)
	if not Soundscapes.same(scape, pushed) then
		pushed = scape
		local StoryAudio = lazy("StoryAudio")
		if StoryAudio and StoryAudio.setZone then
			local ok, err = pcall(StoryAudio.setZone, scape)
			if not ok then
				warn("[EnvDirector] sonido: " .. tostring(err))
			end
		end
	end
end

-- Una vuelta (puro salvo lo que pinta: lo usan las pruebas con dt de mentira)
function EnvDirector.update(dt: number, camPos: Vector3?, now: number?)
	local pos = camPos
	if not pos then
		local camera = workspace.CurrentCamera
		pos = if camera then camera.CFrame.Position else Vector3.zero
	end
	local target = EnvZones.resolve(EnvDirector.input(pos :: Vector3))
	env = EnvZones.approach(env, target, dt)
	flags = EnvZones.flags(env :: EnvZones.Env, flags)
	local e, f = env :: EnvZones.Env, flags :: EnvZones.Flags
	local DayLight = lazy("DayLight")
	if DayLight and DayLight.setZone then
		DayLight.setZone(if e.Zone == "Arena" then nil else e, if e.Zone == "Arena" then nil else f)
	end
	-- La Grieta de Valmar: ni en el espacio ni en un planeta (la arena lleva su propio motivo)
	local off = e.Zone ~= "Arena" and not f.Rift
	if off ~= riftOff then
		riftOff = off
		local SkyRift = lazy("SkyRift")
		if SkyRift and SkyRift.setSuppressed then
			pcall(SkyRift.setSuppressed, off, "Zona")
		end
	end
	-- El sonido de la zona (ambiente, música y los bucles de Valmar)
	updateSound(e, pos :: Vector3, now)
	-- El HUD de Valmar en un planeta (también a pie, al bajarte de la nave)
	local onPlanet = player:GetAttribute("Planeta") ~= nil
	if onPlanet ~= planetHud then
		planetHud = onPlanet
		pcall(function()
			require(script.Parent.Parent.UI.FlightFocus).setZone(if onPlanet then "Planeta" else nil)
		end)
	end
end

-- La zona y los interruptores de ahora
function EnvDirector.current(): (EnvZones.Env?, EnvZones.Flags?)
	return env, flags
end

-- ¿Le toca a esto ahora? ("Weather", "Rift", "ValmarSky", "Clouds", "Atmosphere"). Sin saber aún la
-- zona, sí (Valmar de siempre).
function EnvDirector.allows(what: string): boolean
	local f = flags
	if not f then
		return true
	end
	local value = (f :: any)[what]
	return if type(value) == "boolean" then value else true
end

-- El sonido de la zona de ahora (shared/Cosmos/Soundscapes.Scape; nil = aún no se sabe)
function EnvDirector.soundscape(): Soundscapes.Scape?
	return scape
end

-- Cuánto suenan los bucles de Valmar (pájaros, viento, lluvia, grillos, olas, la ciudad): 1 en Valmar,
-- 0 en el espacio, los planetas, la arena y bajo el mar; en la subida, de 1 a 0. Sin saber aún, 1.
function EnvDirector.valmarAudio(): number
	return if scape then scape.Valmar else 1
end

-- ¿Estás en el espacio (o casi)? Para el brillo del sol sin tiempo de Valmar (SkyExtras)
function EnvDirector.inSpace(): boolean
	return env ~= nil and (env :: EnvZones.Env).Zone ~= "Arena" and (env :: EnvZones.Env).Space > 0.6 and (env :: EnvZones.Env).PlanetMix < 0.5
end

-- (pruebas) empezar de cero
function EnvDirector._reset()
	env, flags, riftOff, planetHud, sea = nil, nil, nil, nil, nil
	scape, pushed, combatUntil = nil, nil, nil
end

function EnvDirector.init()
	local since = EnvDirector.Every
	RunService.RenderStepped:Connect(function(dt)
		since += dt
		if since < EnvDirector.Every then
			return
		end
		local step = since
		since = 0
		local ok, err = pcall(EnvDirector.update, step)
		if not ok then
			warn("[EnvDirector] " .. tostring(err))
		end
	end)
end

return EnvDirector
