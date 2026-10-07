-- Prueba de CONTROL, CÁMARA Y AISLAMIENTO de las escenas (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-scenecontrol.luau
--
-- Comprueba:
--   1. CinematicService (servidor): InScene y SceneId al lanzar una escena (también una del motor
--      Happenings); se quitan con clientDone; el latido la mantiene; sin latido se cierra sola y la
--      historia sigue; tope aunque siga latiendo; un latido sin escena abre «Cliente» y se cierra al
--      parar; un latido rezagado no reabre; al irse el jugador no queda nada.
--   2. Controls (cliente): un motivo con pregunta se suelta solo cuando ya no hace falta (también al
--      reaparecer); sin pregunta no; releaseAll.
--   3. CineCamera (cliente): vuelta SUAVE al juego (sigue fija al principio, a medias va de camino y
--      al final queda en Custom detrás de ti con su campo de visión); de golpe si se pide o si te han
--      llevado lejos; si una conversación coge la cámara, se aparta; si otro la mueve sin escena, se
--      suelta; ensureReleased.
--   4. SceneClient (cliente): qué sale en el plano; los otros jugadores en plano se ocultan solo en tu
--      pantalla durante la escena y vuelven al acabar; los de fuera del plano no; latido al servidor
--      mientras hay escena; avisos de interrupción.
--   5. BabyService: Abu no dice «levántate» mientras el servidor marca InScene (M-04).

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, L.CFrame
local Enum = roblox.Enum
local check = L.check
local realNew = roblox.Instance.new

local function signal()
	local s = { Handlers = {} }
	function s:Connect(fn)
		table.insert(self.Handlers, fn)
		return {
			Disconnect = function()
				local i = table.find(self.Handlers, fn)
				if i then
					table.remove(self.Handlers, i)
				end
			end,
		}
	end
	function s:Fire(...)
		for _, fn in table.clone(self.Handlers) do
			fn(...)
		end
	end
	function s:Wait()
		return task.wait(1 / 60)
	end
	return s
end

-- Servicios de mentira (los mismos para el servidor y el cliente)
local playerList = {}
local Players = {
	PlayerAdded = signal(),
	PlayerRemoving = signal(),
	GetPlayers = function()
		return playerList
	end,
	CreateHumanoidModelFromDescription = function()
		error("sin Roblox")
	end,
}
L.services.Players = Players
L.services.RunService.RenderStepped = signal()
L.services.RunService.Heartbeat = signal()
L.services.StarterGui = { SetCoreGuiEnabled = function() end, GetCoreGuiEnabled = function()
	return true
end }
L.services.CollectionService.GetInstanceAddedSignal = function()
	return signal()
end
L.services.Lighting = { ClockTime = 12 }

local fired = {} -- lo que el servidor manda a los clientes
local beats = 0 -- latidos que el cliente manda
local function fakeRemote(name: string)
	return {
		Name = name,
		OnServerEvent = signal(),
		OnClientEvent = signal(),
		FireClient = function(_, player, kind, payload)
			table.insert(fired, { Remote = name, Player = player, Kind = kind, Payload = payload })
		end,
		FireServer = function(_, kind)
			if name == "Scene" and kind == "Beat" then
				beats += 1
			end
		end,
		IsA = function(_, class)
			return class == "RemoteEvent"
		end,
	}
end
local remotes = {
	LifeStory = fakeRemote("LifeStory"),
	Scene = fakeRemote("Scene"),
	Baby = fakeRemote("Baby"),
	Notify = fakeRemote("Notify"),
}
function remotes:FindFirstChild(name)
	return rawget(self, name)
end
function remotes:WaitForChild(name)
	return rawget(self, name)
end
L.services.ReplicatedStorage.Remotes = remotes

-- Reloj del servidor que avanza la prueba
local T = 1000

---------------------------------------------------------------------
print("1. InScene en el servidor (CinematicService)")
---------------------------------------------------------------------
local happeningPlays = {}
L.mock("src/server/Services/LocationService", {
	resolve = function()
		return nil
	end,
	zoneCenter = function()
		return nil
	end,
})
L.mock("src/server/Services/SceneService", { actorOf = function()
	return nil
end })
L.mock("src/server/Services/DataService", {
	get = function()
		return nil
	end,
	onLoaded = function() end,
})
L.mock("src/server/Services/HappeningService", {
	has = function(id)
		return id == "Escena_Motor"
	end,
	play = function(player, id)
		table.insert(happeningPlays, id)
		return 12
	end,
})
local CinematicService = L.load("src/server/Services/CinematicService")
CinematicService.now = function()
	return T
end
CinematicService.init()

local ana = L.player("Ana", 1)
table.insert(playerList, ana)

local duration = CinematicService.play(ana, "Bebe_Nacimiento")
check(duration > 0, ("la escena del nacimiento dura algo (%.1f s)"):format(duration))
check(ana:GetAttribute("InScene") == true, "al lanzarla, el SERVIDOR marca InScene")
check(ana:GetAttribute("SceneId") == "Bebe_Nacimiento", "y SceneId dice cuál")
check(CinematicService.inScene(ana), "inScene() dice que sí")

-- La historia espera; la pantalla avisa de que ha acabado
local done = 0
CinematicService.waitFor(ana, "Bebe_Nacimiento", 300, function()
	done += 1
end)
CinematicService.beat(ana)
T += 2
CinematicService.clientDone(ana, "Bebe_Nacimiento")
task.wait(0.05)
check(ana:GetAttribute("InScene") == nil and not CinematicService.inScene(ana), "con clientDone se quita InScene")
check(done == 1, "y la historia sigue (una vez)")
CinematicService.clientDone(ana, "Bebe_Nacimiento")
task.wait(0.05)
check(done == 1, "un clientDone repetido no hace seguir dos veces")

-- Un latido que llega justo después de cerrar (iba por el camino) no reabre nada
T += 0.5
CinematicService.beat(ana)
check(ana:GetAttribute("InScene") == nil, "un latido rezagado no vuelve a abrir la escena")

-- El latido la mantiene; si se corta, el servidor la cierra y la historia sigue
T += 10
CinematicService.play(ana, "Bebe_Nacimiento")
local done2 = 0
CinematicService.waitFor(ana, "Bebe_Nacimiento", 300, function()
	done2 += 1
end)
for _ = 1, 30 do
	T += 1
	CinematicService.beat(ana)
end
check(CinematicService.inScene(ana), "con latido cada segundo sigue abierta 30 s después")
T += CinematicService.Timing.BeatTimeout + 0.5
check(not CinematicService.inScene(ana), "sin latido (la pantalla se colgó), el servidor cierra la escena")
check(ana:GetAttribute("InScene") == nil, "y quita InScene")
task.wait(0.05)
check(done2 == 1, "y la historia no espera más")

-- Sin ningún latido: se da tiempo a llegar a la pantalla y luego se cierra (la historia sigue con su
-- propio tope, sin adelantarse)
T += 10
CinematicService.play(ana, "Bebe_Nacimiento")
local done3 = 0
CinematicService.waitFor(ana, "Bebe_Nacimiento", 300, function()
	done3 += 1
end)
T += CinematicService.Timing.StartGrace - 1
check(CinematicService.inScene(ana), "antes del primer latido se espera (el mapa carga, la escena espera turno)")
T += 2
check(not CinematicService.inScene(ana), "si nunca llega el latido, se cierra")
task.wait(0.05)
check(done3 == 0, "pero la historia sigue con su propio tope (waitFor), no antes")

-- Tope: aunque siga latiendo, no dura para siempre
T += 10
CinematicService.play(ana, "Bebe_Nacimiento")
local beganAt = T
local capped = false
for _ = 1, 400 do
	T += 1
	CinematicService.beat(ana)
	if not CinematicService.inScene(ana) then
		capped = true
		break
	end
end
check(capped and T - beganAt < 17 + 2.5 + CinematicService.Timing.CapExtra + 2, ("hay tope aunque siga latiendo (%d s)"):format(T - beganAt))

-- Escena del motor (Happenings) lanzada por aquí: también marca InScene
T += 10
local d = CinematicService.play(ana, "Escena_Motor")
check(d == 12 and happeningPlays[1] == "Escena_Motor", "una escena del motor la dirige HappeningService")
check(ana:GetAttribute("InScene") == true and ana:GetAttribute("SceneId") == "Escena_Motor", "y también marca InScene")
CinematicService.clientDone(ana, "Escena_Motor")
check(ana:GetAttribute("InScene") == nil, "y se quita al acabar")

-- Una escena que solo conoce la pantalla (otro sistema la lanzó): el latido abre «Cliente»
T += 10
CinematicService.beat(ana)
check(ana:GetAttribute("InScene") == true and ana:GetAttribute("SceneId") == CinematicService.CLIENT_ID, "un latido sin escena abre «Cliente»")
T += 1
CinematicService.beat(ana)
T += 3
check(CinematicService.inScene(ana), "sigue mientras late")
T += CinematicService.Timing.BeatTimeout
check(not CinematicService.inScene(ana) and ana:GetAttribute("InScene") == nil, "y se cierra cuando para")

-- Si el cliente nunca contesta, la escena se cierra al seguir la historia (sin bloquear a las pruebas)
T += 10
CinematicService.play(ana, "Bebe_Nacimiento")
local done4 = 0
CinematicService.waitFor(ana, "Bebe_Nacimiento", 0.1, function()
	done4 += 1
end)
task.wait(0.3)
check(done4 == 1 and ana:GetAttribute("InScene") == nil, "sin noticias de la pantalla, al seguir la historia se quita InScene")

-- Varios a la vez: cada uno lo suyo
local bea = L.player("Bea", 2)
table.insert(playerList, bea)
T += 10
CinematicService.play(ana, "Bebe_Nacimiento")
check(ana:GetAttribute("InScene") == true and bea:GetAttribute("InScene") == nil, "la escena de Ana no marca a Bea")

-- Se va del juego: no queda nada suyo
Players.PlayerRemoving:Fire(ana)
check(not CinematicService.inScene(ana), "al irse, no queda ninguna escena suya abierta")

---------------------------------------------------------------------
print("2. Controls")
---------------------------------------------------------------------
-- El jugador local (cliente)
local me = L.player("Yo", 10)
me.CharacterAdded = signal()
me.OnTeleport = signal()
local controlsState = { Enabled = true, Calls = 0 }
L.mock("fake/PlayerModule", {
	GetControls = function()
		return {
			Enable = function()
				controlsState.Enabled = true
				controlsState.Calls += 1
			end,
			Disable = function()
				controlsState.Enabled = false
				controlsState.Calls += 1
			end,
		}
	end,
})
local playerScripts = {
	WaitForChild = function()
		return { __path = "fake/PlayerModule" }
	end,
}
function me:WaitForChild(name)
	if name == "PlayerScripts" then
		return playerScripts
	end
	return nil
end
function me:GetAttributeChangedSignal()
	return signal()
end
Players.LocalPlayer = me
table.insert(playerList, me)

-- Las piezas de Lune no calculan Position a partir de CFrame: se ponen las dos
local function place(part: any, cf: any)
	part.CFrame = cf
	part.Position = cf.Position
end

-- Cuerpo de un jugador (en el mundo, como en Roblox)
local world = realNew("Folder")
local function body(name: string, at: any)
	local model = realNew("Model")
	model.Name = name
	model.Parent = world
	local root = realNew("Part")
	root.Name = "HumanoidRootPart"
	place(root, at)
	root.Parent = model
	local head = realNew("Part")
	head.Name = "Head"
	place(head, at + Vector3.new(0, 2, 0))
	head.Parent = model
	local face = realNew("Decal")
	face.Parent = head
	for _, piece in { root, head, face } do
		(piece :: any).LocalTransparencyModifier = 0 -- (Lune no trae su valor por defecto)
	end
	local humanoid = realNew("Humanoid")
	humanoid.Parent = model
	return model
end
me.Character = body("Yo", CFrame.new(0, 3, 0))

local Controls = L.load("src/client/Controllers/Controls")
Controls.SweepSeconds = 0.2
local stillNeeded = true
Controls.disable("Cinematica", function()
	return stillNeeded
end)
check(not controlsState.Enabled and Controls.isDisabled("Cinematica"), "una escena quita el control")
Controls.disable("Escena") -- (sin pregunta)
check(Controls.sweep() == 0, "mientras hace falta, no se suelta")
stillNeeded = false
check(Controls.sweep() == 1 and not Controls.isDisabled("Cinematica"), "si la escena se rompe sin devolverlo, se suelta solo")
check(not controlsState.Enabled, "pero otro motivo sin pregunta (Escena) lo sigue teniendo")
Controls.enable("Escena")
check(controlsState.Enabled and not Controls.isDisabled(), "al soltarlo todo, vuelve el control")

-- Al reaparecer se miran las preguntas
local alive = true
Controls.disable("Cinematica", function()
	return alive
end)
alive = false
me.CharacterAdded:Fire(me.Character)
task.wait(0.1)
check(controlsState.Enabled and not Controls.isDisabled(), "al reaparecer, un motivo que ya no hace falta se suelta")

-- Y solo con el reloj (sin reaparecer)
local need = true
Controls.disable("Cinematica", function()
	return need
end)
need = false
task.wait(0.5)
check(not Controls.isDisabled(), "cada pocos segundos también se mira (nadie se queda congelado)")
Controls.disable("A")
Controls.disable("B")
Controls.releaseAll()
check(controlsState.Enabled and not Controls.isDisabled(), "releaseAll lo devuelve todo")

---------------------------------------------------------------------
print("3. CineCamera: vuelta suave al juego")
---------------------------------------------------------------------
local camera = {
	CFrame = CFrame.lookAt(Vector3.new(30, 20, 30), Vector3.new(0, 0, 0)),
	CameraType = Enum.CameraType.Scriptable,
	FieldOfView = 40,
	CameraSubject = nil,
	ViewportSize = Vector2.new(1600, 900),
}
L.workspace = {
	CurrentCamera = camera,
	FindFirstChild = function()
		return nil
	end,
	Raycast = function()
		return nil
	end,
}
-- Los módulos de cámara del cliente se cargan con su propio entorno (RaycastParams y una cámara de
-- mentira en workspace, que el cargador común no trae)
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local clientWarnings = {}
local function loadClient(path: string): any
	local env = setmetatable({
		-- (ReplicatedStorage.Shared.X → src/shared/X, como el cargador común: p. ej. CameraShots)
		require = function(target)
			return L.load(rawget(target, "__path"))
		end,
		game = L.game,
		workspace = L.workspace,
		task = task,
		Vector3 = Vector3,
		Vector2 = Vector2,
		CFrame = CFrame,
		Enum = Enum,
		typeof = roblox.typeof or typeof,
		RaycastParams = { new = function()
			return { FilterDescendantsInstances = {}, RespectCanCollide = true }
		end },
		warn = function(...)
			table.insert(clientWarnings, table.concat({ ... }, " "))
		end,
	}, { __index = _G })
	return luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
end

-- Cada fotograma (como RenderStepped): la prueba lo hace avanzar
local CineCamera = loadClient("src/client/Controllers/CineCamera")
CineCamera.ReturnSeconds = 0.6
local humanoid = me.Character:FindFirstChildOfClass("Humanoid")
local startCF = camera.CFrame
CineCamera.restore(nil, { Fov = 70 })
check(camera.CameraType == Enum.CameraType.Scriptable and CineCamera.isReturning(), "la vuelta empieza: la cámara aún es de la escena (no hay corte)")
task.wait(0.3)
local mid = camera.CFrame.Position
local goal = CineCamera.behind()
check(goal ~= nil, "hay sitio detrás de ti")
local midOk = goal and (mid - startCF.Position).Magnitude > 1 and (mid - goal.Position).Magnitude > 1
check(midOk, "a medias va de camino (ni en el plano ni detrás de ti)")
check(camera.FieldOfView > 40 and camera.FieldOfView < 70, ("el campo de visión también vuelve poco a poco (%.1f)"):format(camera.FieldOfView))
task.wait(0.5)
check(camera.CameraType == Enum.CameraType.Custom, "al final la cámara vuelve al juego (Custom)")
check(camera.CameraSubject == humanoid, "siguiendo a tu personaje")
check(goal and (camera.CFrame.Position - goal.Position).Magnitude < 0.5, "detrás de ti")
check(camera.FieldOfView == 70 and not CineCamera.isReturning(), "con su campo de visión y sin vuelta en curso")

-- De golpe: si se pide (pantalla en negro) o si te han llevado lejos
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCF
CineCamera.restore(nil, { Instant = true })
check(camera.CameraType == Enum.CameraType.Custom, "Instant: de golpe (con la pantalla en negro no hace falta viajar)")
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(Vector3.new(900, 50, 900), Vector3.new(900, 0, 880))
CineCamera.restore(nil)
check(camera.CameraType == Enum.CameraType.Custom and not CineCamera.isReturning(), "te han llevado lejos: corte, sin cruzar el mapa volando")

-- Una conversación coge la cámara a mitad de la vuelta: manda ella
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCF
me:SetAttribute("InDialogue", true)
CineCamera.restore(nil)
task.wait(0.1)
local dialogueShot = CFrame.lookAt(Vector3.new(5, 5, 5), Vector3.new(0, 3, 0))
camera.CFrame = dialogueShot
task.wait(0.15)
check(camera.CameraType == Enum.CameraType.Scriptable and camera.CFrame == dialogueShot, "si una conversación coge la cámara, la vuelta se aparta")
check(not CineCamera.isReturning(), "y deja de volver")
me:SetAttribute("InDialogue", nil)

-- Otro la mueve sin escena ni conversación: se suelta al juego (nunca queda fija sin dueño)
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCF
CineCamera.restore(nil)
task.wait(0.1)
camera.CFrame = CFrame.lookAt(Vector3.new(6, 6, 6), Vector3.new(0, 3, 0))
task.wait(0.15)
check(camera.CameraType == Enum.CameraType.Custom, "si otro la mueve sin escena, se suelta al juego")

-- Una escena nueva corta la vuelta
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCF
CineCamera.restore(nil)
CineCamera.cancelRestore()
task.wait(0.8)
check(camera.CameraType == Enum.CameraType.Scriptable and (camera.CFrame.Position - startCF.Position).Magnitude < 0.01, "cancelRestore: la escena nueva manda (la vuelta no toca nada)")

-- Red de seguridad
me:SetAttribute("InCinematic", true)
check(not CineCamera.ensureReleased(), "ensureReleased no toca nada si hay escena")
me:SetAttribute("InCinematic", nil)
check(CineCamera.ensureReleased() and camera.CameraType == Enum.CameraType.Custom, "ensureReleased suelta una cámara fija sin dueño")
check(not CineCamera.ensureReleased(), "y si ya está en el juego, no hace nada")

---------------------------------------------------------------------
print("4. SceneClient: otros jugadores en plano, latido e interrupciones")
---------------------------------------------------------------------
local SceneClient = loadClient("src/client/Controllers/SceneClient")
local camCF = CFrame.lookAt(Vector3.new(0, 5, 0), Vector3.new(0, 5, -10))
check(SceneClient.inShot(camCF, 70, 16 / 9, Vector3.new(0, 4, -30), 160), "delante de la cámara: en plano")
check(not SceneClient.inShot(camCF, 70, 16 / 9, Vector3.new(0, 4, 30), 160), "detrás: fuera de plano")
check(not SceneClient.inShot(camCF, 70, 16 / 9, Vector3.new(80, 4, -10), 160), "muy a un lado: fuera de plano")
check(not SceneClient.inShot(camCF, 70, 16 / 9, Vector3.new(0, 4, -300), 160), "muy lejos: no cuenta")
check(SceneClient.inShot(camCF, 70, 16 / 9, Vector3.new(2, 4, 1), 160), "pegado a la cámara: tapa el plano")

camera.CFrame = camCF
camera.FieldOfView = 70
local other = L.player("Otro", 20)
other.Character = body("Otro", CFrame.new(0, 3, -25))
local far = L.player("Lejos", 21)
far.Character = body("Lejos", CFrame.new(0, 3, 60)) -- detrás de la cámara
table.insert(playerList, other)
table.insert(playerList, far)
local function hidden(model: any): boolean
	return model.HumanoidRootPart.LocalTransparencyModifier >= 1 and model.Head.LocalTransparencyModifier >= 1
end

check(SceneClient.refreshOthers() == 0 and not hidden(other.Character), "sin escena no se oculta a nadie")
me:SetAttribute("InCinematic", true)
check(SceneClient.refreshOthers() == 1, "en una escena, el jugador que está en plano se oculta")
check(hidden(other.Character), "(invisible en tu pantalla: cuerpo y cabeza)")
check(other.Character.Head:FindFirstChildOfClass("Decal").LocalTransparencyModifier >= 1, "(y la cara)")
check(not hidden(far.Character) and not SceneClient.isHiddenOther(far.Character), "el que está fuera de plano, no")
check(not hidden(me.Character), "a ti mismo nunca")
-- Sale del plano: sigue oculto hasta el final (sin parpadeos)
place(other.Character.HumanoidRootPart, CFrame.new(0, 3, 60))
SceneClient.refreshOthers()
check(hidden(other.Character), "si sale del plano, sigue oculto hasta el final (no parpadea)")
me:SetAttribute("InCinematic", nil)
check(SceneClient.refreshOthers() == 0 and not hidden(other.Character), "al acabar la escena, vuelve a verse")
-- Conversación: solo los que están cerca
me:SetAttribute("InDialogue", true)
place(other.Character.HumanoidRootPart, CFrame.new(0, 3, -90))
SceneClient.refreshOthers()
check(not hidden(other.Character), "en una conversación, uno lejos al fondo no se oculta")
place(other.Character.HumanoidRootPart, CFrame.new(0, 3, -20))
SceneClient.refreshOthers()
check(hidden(other.Character), "pero uno que se cruza cerca, sí")
me:SetAttribute("InDialogue", nil)
SceneClient.refreshOthers()
check(not hidden(other.Character), "y vuelve al acabar la conversación")
-- Otro motivo (para otros sistemas)
SceneClient.hideOthers("Prueba", true)
check(hidden(other.Character), "hideOthers con un motivo también oculta")
SceneClient.hideOthers("Prueba", false)
check(not hidden(other.Character), "y al quitarlo vuelve")
-- Se va del juego mientras está oculto
me:SetAttribute("InCinematic", true)
SceneClient.refreshOthers()
table.remove(playerList, table.find(playerList, other))
check(SceneClient.refreshOthers() == 0, "si se va del juego, se olvida (no queda nada a medias)")
me:SetAttribute("InCinematic", nil)
SceneClient.refreshOthers()

-- Latido: solo mientras hay escena
local showing = false
SceneClient.watchBusy(function()
	return showing
end)
SceneClient.BeatSeconds = 0.1
check(not SceneClient.isBusy(), "sin escena no hay latido")
SceneClient.start()
task.wait(0.35)
check(beats == 0, "sin escena no se manda nada al servidor")
showing = true
task.wait(0.35)
check(beats >= 2, ("con una escena en pantalla, el servidor recibe el latido (%d)"):format(beats))
showing = false
local before = beats
me:SetAttribute("InCinematic", true) -- (una escena del motor, HappeningClient)
task.wait(0.25)
check(beats > before, "también con una escena del motor (InCinematic)")
me:SetAttribute("InCinematic", nil)
task.wait(0.15)
before = beats
task.wait(0.3)
check(beats == before, "al acabar, el latido para")

-- Interrupciones
local got = {}
SceneClient.onInterrupt(function(reason)
	table.insert(got, reason)
end)
me.CharacterAdded:Fire(body("Yo", CFrame.new(0, 3, 0)))
me.OnTeleport:Fire(Enum.TeleportState.Started)
task.wait(0.1)
check(table.find(got, "Reaparecer") ~= nil, "al reaparecer, se avisa")
check(table.find(got, "Teletransporte") ~= nil, "al irte a otro lugar, se avisa")

---------------------------------------------------------------------
print("5. BabyService: Abu espera a que acabe la escena (M-04)")
---------------------------------------------------------------------
L.fakeClasses.ProximityPrompt = function()
	return { ClassName = "ProximityPrompt", Triggered = signal() }
end
local Home = L.load("src/server/World/Kit/Home")
local town = realNew("Folder")
local homeModel = Home.familyHouse(town, CFrame.new(60, 0, 0), "Prueba_1")
L.services.CollectionService = {
	AddTag = function(_, instance, tag)
		instance:AddTag(tag)
	end,
	GetTagged = function(_, tag)
		return if tag == "FamilyHome" then { homeModel } else {}
	end,
	GetInstanceAddedSignal = function()
		return signal()
	end,
}
local babyData = { Life = { Stage = "Bebe" }, Story = { Flags = {}, Active = {} }, Hunger = 100 }
local baby = L.player("Bebe", 30)
baby.CharacterAdded = signal()
function baby:GetAttributeChangedSignal()
	return signal()
end
L.mock("src/server/Services/DataService", {
	get = function(player)
		return if player == baby then babyData else nil
	end,
	onLoaded = function() end,
})
L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
L.mock("src/server/Services/NeedsService", { change = function() end })
L.mock("src/server/Services/CinematicService", { play = function()
	return 0
end })
L.mock("src/server/World/Npc", {
	dress = function() end,
	work = function() end,
	placeFeet = function() end,
})
local BabyService = L.load("src/server/Services/BabyService")
playerList = {}
BabyService.init()
baby:SetAttribute("LifeStage", "Bebe")
-- El nacimiento está en pantalla (lo marca el servidor) y el capítulo aún no ha empezado
baby:SetAttribute("InScene", true)
table.clear(fired)
BabyService.ensureFamily(baby)
local function saidStand(): boolean
	for _, f in fired do
		if f.Remote == "Baby" and f.Kind == "Say" and type(f.Payload) == "table" and f.Payload.TextKey == "DLG.ABU.BEBE.LEVANTATE" then
			return true
		end
	end
	return false
end
task.wait(5)
check(not saidStand(), "durante la escena del nacimiento (InScene), Abu no dice «levántate»")
babyData.Story.Chapter = "Bebe_PrimerosPasos"
task.wait(1.5)
check(not saidStand(), "tampoco mientras siga la escena aunque ya haya capítulo")
baby:SetAttribute("InScene", nil)
local waited = 0
while not saidStand() and waited < 6 do
	waited += task.wait(0.25)
end
check(saidStand(), ("al acabar la escena, Abu lo dice (%.1f s después)"):format(waited))
check(waited >= 1, "y no al instante: deja respirar un momento")

if L.failures > 0 then
	L.finish("test-scenecontrol")
end
print("")
print("✅ test-scenecontrol: todo correcto")
process.exit(0) -- (los bucles del juego seguirían esperando)
