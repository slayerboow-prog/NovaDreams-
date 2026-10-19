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
-- En la arena de pruebas no hace nada: allí manda AirCombatClient (su cielo y su luz).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local EnvZones = require(Cosmos.EnvZones)
local Tefra = require(Cosmos.Tefra)

local EnvDirector = {}

local player = Players.LocalPlayer
EnvDirector.Every = 0.1 -- segundos entre vueltas

-- Las superficies que hay (como PlanetClient)
local SURFACES: { [string]: any } = { Tefra = Tefra }

local env: EnvZones.Env? = nil
local flags: EnvZones.Flags? = nil
local riftOff: boolean? = nil
local planetHud: boolean? = nil

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
	return { Pos = camPos, Arena = arena, Surface = surface, Entry = entry }
end

-- Una vuelta (puro salvo lo que pinta: lo usan las pruebas con dt de mentira)
function EnvDirector.update(dt: number, camPos: Vector3?)
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

-- ¿Estás en el espacio (o casi)? Para el brillo del sol sin tiempo de Valmar (SkyExtras)
function EnvDirector.inSpace(): boolean
	return env ~= nil and (env :: EnvZones.Env).Zone ~= "Arena" and (env :: EnvZones.Env).Space > 0.6 and (env :: EnvZones.Env).PlanetMix < 0.5
end

-- (pruebas) empezar de cero
function EnvDirector._reset()
	env, flags, riftOff, planetHud = nil, nil, nil, nil
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
