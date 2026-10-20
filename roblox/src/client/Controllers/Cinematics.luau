-- Cinematics (cliente): PUENTE de compatibilidad (fase 6 del cine, «un solo motor»).
--
-- Antes aquí había un reproductor propio para las 21 «cinemáticas viejas» (bandas, planos, subtítulos,
-- rótulos, gestos, Saltar, recuperación de errores). Ahora esas escenas son del MOTOR
-- (shared/LifeStory/Happenings/Capitulos) y las reproduce Controllers/HappeningClient con todo lo del
-- motor: encuadre sin paredes, cada paso en su pcall con aviso al servidor (SceneReport), vigilantes,
-- vuelta final, subtítulos con tiempo de lectura, actuación… El servidor ya no manda «Cinematic».
--
-- Lo que queda es la misma API de siempre, porque la usan muchos sitios (la caja de diálogo, el
-- prólogo, la cámara a pie, el parkour, las armas, el HUD…), y responde lo mismo que antes:
--   isOnScreen()  ¿hay en pantalla una de las escenas de siempre? (HappeningClient.legacyOnScreen)
--   isPlaying()   lo mismo, o una que ha llegado y espera turno (hold)
--   hold()        apunta una escena que espera turno; devuelve cómo soltarla (tope HoldMax)
--   interrupt()   la salta (como el botón «Saltar»)
--   play(payload) por si llega un «Cinematic» de un servidor viejo: no hay nada que reproducir aquí, así
--                 que se avisa de que ha acabado (la historia nunca se queda esperando) y del fallo

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneChain = require(script.Parent.Parent.UI.SceneChain)
local SceneClient = require(script.Parent.SceneClient)
local SceneReport = require(script.Parent.SceneReport)

local Cinematics = {}

Cinematics.HoldMax = 180 -- segundos que una escena puede esperar turno contando como en marcha
Cinematics.MaxStepFailures = 4 -- (lo de siempre; los pasos los cuenta ahora HappeningClient)

local pending = 0 -- escenas que han llegado y esperan su turno (cola de momentos de LifeStory)

local function scenes(): any
	local ok, module = pcall(function()
		return require(script.Parent.HappeningClient) :: any
	end)
	return if ok and type(module) == "table" then module else nil
end

-- ¿Hay en pantalla AHORA una de las escenas de siempre (cabecera de capítulo, foto de grupo…)?
function Cinematics.isOnScreen(): boolean
	local module = scenes()
	if not module or type(module.legacyOnScreen) ~= "function" then
		return false
	end
	local ok, on = pcall(module.legacyOnScreen)
	return ok and on == true
end

-- ¿Se está viendo una, o hay una esperando? (los diálogos esperan a que termine)
function Cinematics.isPlaying(): boolean
	return pending > 0 or Cinematics.isOnScreen()
end

-- El puente entre escenas seguidas (UI/SceneChain): lo que esta pantalla tiene en cola
SceneChain.addSource(function()
	return pending > 0
end)

-- Mientras hay una esperando turno, el servidor recibe el latido (las de pantalla ya laten por
-- HappeningClient)
SceneClient.watchBusy(function()
	return pending > 0
end)

-- Corta la escena en pantalla (como el botón Saltar). Para el modo pruebas y otros sistemas.
function Cinematics.interrupt()
	local module = scenes()
	if module and type(module.skipLegacy) == "function" then
		pcall(module.skipLegacy)
	end
end

-- Apunta una escena que acaba de llegar y aún no empieza; devuelve cómo soltarla (al acabar)
function Cinematics.hold(): () -> ()
	pending += 1
	local released = false
	local function release()
		if not released then
			released = true
			pending = math.max(0, pending - 1)
		end
	end
	-- (tope: si la cola se atasca y nadie la suelta, no cuenta para siempre como «escena en marcha»)
	task.delay(Cinematics.HoldMax, release)
	return release
end

-- Un «Cinematic» por el camino viejo (no debería llegar: CinematicService manda todas al motor).
-- No se queda nada a medias: se avisa al servidor de que ha acabado y de que llegó por aquí.
function Cinematics.play(payload: { [string]: any })
	local id = if type(payload) == "table" then payload.Id else nil
	SceneReport.report("Cinematics", if type(id) == "string" then id else nil, "Play", "cinemática por el camino viejo (ya son escenas del motor)", "Abort")
	pcall(function()
		local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("LifeStory")
		if remote and type(id) == "string" then
			(remote :: RemoteEvent):FireServer("CinematicDone", id)
		end
	end)
end

return Cinematics
