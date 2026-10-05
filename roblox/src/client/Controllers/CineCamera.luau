-- CineCamera (cliente): ayudas compartidas por la cámara de las conversaciones (DialogueUI) y la de
-- las cinemáticas (Cinematics).
--   * clamp: si entre lo que se mira y donde quiere ponerse la cámara hay una pared, la cámara se
--     acerca hasta justo antes de ella (no atraviesa muros ni se mete dentro de los muebles).
--   * inInterior: dentro de una casa o tienda (las salas están muy arriba, Y > 3000) los planos se
--     hacen más cortos.
--   * restore: devuelve la cámara al juego donde estaba (o detrás de ti mirando al frente). La vuelta
--     es SUAVE (~1 s, C-04): la cámara viaja desde el último plano hasta detrás de ti y solo entonces
--     se suelta al juego. Es de golpe si se pide (Instant, p. ej. con la pantalla en negro), si no
--     había cámara de escena o si te han llevado lejos (no cruza el mapa volando).
--   * quietLabels: mientras hay una escena o una conversación, se esconden los nombres y los
--     iconos flotantes ("!") de los personajes, que tapaban los primeros planos. Contador por motivo.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CineCamera = {}
CineCamera.ReturnSeconds = 1 -- lo que tarda la vuelta suave al juego
CineCamera.FarJump = 120 -- más lejos que esto, la vuelta es un corte (te han teletransportado)

local player = Players.LocalPlayer
local INTERIOR_Y = 3000
CineCamera.InteriorRadius = 5 -- radio máximo de los planos que giran alrededor dentro de una sala

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function()
	rayParams.RespectCanCollide = true -- las zonas invisibles y los cristales sin choque no cuentan
end)

local function ignoreList(): { Instance }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	local scenes = workspace:FindFirstChild("StoryScenes")
	if scenes then
		table.insert(list, scenes)
	end
	return list
end

-- Posición de la cámara sin atravesar paredes: si algo se cruza entre focus y desired, se queda
-- a medio stud de ello (nunca más cerca de 0.5 del foco)
function CineCamera.clamp(focus: Vector3, desired: Vector3): Vector3
	local offset = desired - focus
	local distance = offset.Magnitude
	if distance < 0.05 then
		return desired
	end
	local ok, hit = pcall(function()
		rayParams.FilterDescendantsInstances = ignoreList()
		return workspace:Raycast(focus, offset, rayParams)
	end)
	if ok and hit and typeof(hit) == "RaycastResult" then
		return focus + offset.Unit * math.max(0.5, hit.Distance - 0.5)
	end
	return desired
end

-- El mismo plano (misma orientación) con la posición corregida
function CineCamera.clampCFrame(cf: CFrame, focus: Vector3): CFrame
	local position = CineCamera.clamp(focus, cf.Position)
	if position == cf.Position then
		return cf
	end
	return CFrame.new(position) * cf.Rotation
end

function CineCamera.inInterior(): boolean
	if player:GetAttribute("InteriorKey") ~= nil then
		return true
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and root.Position.Y > INTERIOR_Y
end

-- Detrás de ti, un poco por encima, mirando hacia donde miras
function CineCamera.behind(): CFrame?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	local position = CineCamera.clamp(focus, focus - flat * 10 + Vector3.new(0, 2.5, 0))
	return CFrame.lookAt(position, focus + flat * 4)
end

-- Dónde acaba la vuelta: saved = donde estaba antes de la escena (si sigue cerca de ti se vuelve
-- ahí; si te has movido lejos o no hay, detrás de ti)
function CineCamera.returnTarget(saved: CFrame?): CFrame?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if saved and root and (saved.Position - root.Position).Magnitude < 40 then
		return CFrame.new(CineCamera.clamp(root.Position + Vector3.new(0, 1.5, 0), saved.Position)) * saved.Rotation
	end
	return CineCamera.behind()
end

-- Suelta la cámara al juego en este mismo fotograma
local function release(camera: Camera, target: CFrame?, fov: number?)
	if target then
		camera.CFrame = target
	end
	if fov then
		camera.FieldOfView = fov
	end
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- ¿Ha movido otro la cámara? (lo que la vuelta escribió y lo que hay ahora no coinciden)
local function moved(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude > 0.05 or a.LookVector:Dot(b.LookVector) < 0.9995
end

-- ¿Tiene alguien la cámara? (una conversación, una escena del motor o el sueño del prólogo)
local function owned(): boolean
	return player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true or player:GetAttribute("InPrologue") == true
end

local glideToken = 0
local gliding = false

-- ¿Está la cámara volviendo al juego ahora mismo?
function CineCamera.isReturning(): boolean
	return gliding
end

-- Corta la vuelta suave en curso (una escena nueva que coge la cámara). No toca la cámara.
function CineCamera.cancelRestore()
	glideToken += 1
	gliding = false
end

-- Red de seguridad: si nadie usa la cámara (sin escena, sin conversación, sin vuelta en curso) y se
-- ha quedado fija, vuelve al juego. Devuelve si ha tenido que hacerlo.
function CineCamera.ensureReleased(): boolean
	local camera = workspace.CurrentCamera
	if not camera or gliding or camera.CameraType ~= Enum.CameraType.Scriptable then
		return false
	end
	if owned() then
		return false
	end
	release(camera, CineCamera.returnTarget(nil), nil)
	return true
end

export type RestoreOptions = { Instant: boolean?, Seconds: number?, Fov: number? }

-- Devuelve la cámara al juego (ver arriba). options: Instant (de golpe), Seconds (lo que tarda),
-- Fov (campo de visión al que vuelve, también suave)
function CineCamera.restore(saved: CFrame?, options: RestoreOptions?)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local opts: RestoreOptions = options or {}
	local target = CineCamera.returnTarget(saved)
	local seconds = opts.Seconds or CineCamera.ReturnSeconds
	local from = camera.CFrame
	local scripted = camera.CameraType == Enum.CameraType.Scriptable
	if opts.Instant or not target or not scripted or seconds <= 0 or (from.Position - target.Position).Magnitude > CineCamera.FarJump then
		CineCamera.cancelRestore()
		release(camera, target, opts.Fov)
		return
	end
	if gliding then
		return -- (ya está volviendo: quien llama en cada fotograma no la reinicia)
	end
	glideToken += 1
	local token = glideToken
	gliding = true
	local fromFov = camera.FieldOfView
	task.spawn(function()
		local ok, err = pcall(function()
			local start = os.clock()
			local last = from
			local goal = target
			while token == glideToken do
				if camera.CameraType ~= Enum.CameraType.Scriptable then
					return -- (otro la ha devuelto al juego ya)
				end
				if moved(camera.CFrame, last) then
					-- Otro mueve la cámara: si es una conversación o una escena, manda ella; si no,
					-- se suelta al juego ya (nunca se queda la cámara fija sin dueño)
					if not owned() then
						release(camera, nil, opts.Fov)
					end
					return
				end
				local k = smooth((os.clock() - start) / seconds)
				if k >= 1 then
					break
				end
				goal = CineCamera.returnTarget(saved) or goal -- (sigue a tu personaje si te mueves)
				last = from:Lerp(goal, k)
				camera.CFrame = last
				if opts.Fov then
					camera.FieldOfView = fromFov + (opts.Fov - fromFov) * k
				end
				RunService.RenderStepped:Wait()
			end
			if token == glideToken then
				release(camera, CineCamera.returnTarget(saved) or goal, opts.Fov)
			end
		end)
		if token == glideToken then
			gliding = false
		end
		if not ok then
			warn("[CineCamera] " .. tostring(err))
			pcall(release, camera, nil, opts.Fov) -- pase lo que pase, la cámara vuelve al juego
		end
	end)
end

---------------------------------------------------------------------
-- Nombres e iconos flotantes
---------------------------------------------------------------------

local QUIET_GUIS = { Bubble = true, Icon = true }
local quietHolders: { [string]: boolean } = {}
local savedHumanoids: { [Humanoid]: Enum.HumanoidDisplayDistanceType } = {}
local savedGuis: { [BillboardGui]: boolean } = {}
local addedConnection: RBXScriptConnection? = nil

local function quiet(instance: Instance)
	if instance:IsA("Humanoid") then
		if savedHumanoids[instance] == nil and instance.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
			savedHumanoids[instance] = instance.DisplayDistanceType
			instance.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	elseif instance:IsA("BillboardGui") and QUIET_GUIS[instance.Name] then
		if savedGuis[instance] == nil and instance.Enabled then
			savedGuis[instance] = true
			instance.Enabled = false
		end
	end
end

local function quietAll()
	local roots: { Instance } = {}
	local scenes = workspace:FindFirstChild("StoryScenes")
	if scenes then
		table.insert(roots, scenes)
	end
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			table.insert(roots, other.Character)
		end
	end
	for _, root in roots do
		for _, d in root:GetDescendants() do
			quiet(d)
		end
	end
	if scenes and not addedConnection then
		-- Los que aparecen en mitad de la escena, también sin nombre
		addedConnection = scenes.DescendantAdded:Connect(function(d)
			if next(quietHolders) ~= nil then
				task.defer(quiet, d)
			end
		end)
	end
end

local function restoreAll()
	if addedConnection then
		addedConnection:Disconnect()
		addedConnection = nil
	end
	for humanoid, value in savedHumanoids do
		-- (si otro sistema lo cambió mientras tanto, manda lo suyo; y si SceneClient lo ha escondido
		-- porque es de la historia de otro jugador, sigue sin nombre)
		local head = humanoid.Parent and humanoid.Parent:FindFirstChild("Head")
		local hidden = head and head:IsA("BasePart") and head.LocalTransparencyModifier >= 1
		if humanoid.Parent and not hidden and humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None then
			humanoid.DisplayDistanceType = value
		end
	end
	for gui in savedGuis do
		if gui.Parent and not gui.Enabled then
			-- El icono del servidor se apaga dejando el texto vacío: solo vuelve si aún dice algo
			local label = gui:FindFirstChildOfClass("TextLabel")
			gui.Enabled = label == nil or label.Text ~= ""
		end
	end
	table.clear(savedHumanoids)
	table.clear(savedGuis)
end

function CineCamera.quietLabels(reason: string, on: boolean)
	local was = next(quietHolders) ~= nil
	quietHolders[reason] = if on then true else nil
	local now = next(quietHolders) ~= nil
	local ok, err = pcall(function()
		if now then
			quietAll() -- (también al pasar de un motivo a dos: recoge a los nuevos)
		elseif was then
			restoreAll()
		end
	end)
	if not ok then
		warn("[CineCamera] " .. tostring(err))
	end
end

return CineCamera
