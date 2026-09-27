-- RideCamera (cliente): la cámara cuando vas en un vehículo (conduciendo o de pasajero), en el
-- autobús y en el metro. Sin tirones, sin meterse dentro del coche ni atravesar la carrocería.
--
-- Cómo funciona: la cámara de Roblox (tipo Custom: se gira con el ratón, el dedo o el mando y se
-- acerca con la rueda) sigue a una pieza invisible, el "foco", en vez de al personaje:
--   * Coches, motos, bicis, camiones y autobús ("Fuera"): el foco va por encima del techo, en el
--     centro del vehículo, y lo sigue con muelle (predice por dónde va y corrige suave): así no
--     tiembla aunque el vehículo lo mueva otro ordenador (vas de pasajero). La carrocería no tapa
--     la cámara (en marcha no choca), así que nunca salta al interior. Mientras el vehículo
--     avanza y no mueves la cámara, se coloca sola detrás, poco a poco.
--     Distancia mínima según el tamaño del vehículo: nada de primera persona dentro del coche.
--   * Metro ("Dentro"): la cámara sigue a tu personaje como siempre, pero no sale del vagón
--     (antes atravesaba la pared y se iba al túnel): si la pared o la ventana quedan entre tu
--     cabeza y la cámara, la cámara se pone delante. Distancia corta.
-- Al bajarte vuelve la cámara normal, detrás de tu personaje y a una distancia cómoda.
-- Las cuentas (muelle, giro, distancias) son funciones puras que se prueban fuera de Roblox:
-- scripts/test-ridecamera.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local RideCamera = {}

local player = Players.LocalPlayer

export type View = {
	Mode: string, -- "Fuera" | "Dentro"
	Height: number, -- altura del foco sobre la base del vehículo (o sobre el asiento, en el metro)
	Min: number, -- distancia mínima de la cámara
	Start: number, -- distancia al subir
	Max: number, -- distancia máxima
}

---------------------------------------------------------------------
-- Cuentas (puras)
---------------------------------------------------------------------

-- Cómo se ve cada cosa según su tamaño (ancho, alto, largo del vehículo)
function RideCamera.view(size: Vector3, metro: boolean): View
	if metro then
		return { Mode = "Dentro", Height = 2.3, Min = 3, Start = 7, Max = 12 }
	end
	local min = math.clamp(size.Z * 0.75 + 2, 7, 30)
	return {
		Mode = "Fuera",
		Height = size.Y + 1.2,
		Min = min,
		Start = min + 4,
		Max = math.max(min * 3, 40),
	}
end

-- Ángulo con signo (en horizontal) para girar de la dirección a a la b
function RideCamera.yawBetween(a: Vector3, b: Vector3): number
	local ya = math.atan2(-a.X, -a.Z)
	local yb = math.atan2(-b.X, -b.Z)
	return (yb - ya + math.pi) % (2 * math.pi) - math.pi
end

-- Muelle del foco: predice con la velocidad y corrige hacia el objetivo (más suave en vertical,
-- para los baches y bordillos). Si el objetivo salta lejos (teletransporte), se va directo.
function RideCamera.follow(focus: Vector3, velocity: Vector3, target: Vector3, dt: number): Vector3
	local predicted = focus + velocity * dt
	if (target - predicted).Magnitude > 25 then
		return target
	end
	local h = 1 - math.exp(-16 * dt)
	local v = 1 - math.exp(-8 * dt)
	return Vector3.new(predicted.X + (target.X - predicted.X) * h, predicted.Y + (target.Y - predicted.Y) * v, predicted.Z + (target.Z - predicted.Z) * h)
end

-- Cuánto se coloca detrás este fotograma (0 = nada): solo en marcha y si no mueves la cámara
function RideCamera.autoTurn(diff: number, speed: number, idle: number, dt: number): number
	if idle < 1.6 or speed < 4 then
		return 0
	end
	local strength = math.clamp((speed - 4) / 20, 0, 1) * math.clamp((idle - 1.6) / 0.8, 0, 1)
	return diff * strength * (1 - math.exp(-2.2 * dt))
end

---------------------------------------------------------------------
-- En el juego
---------------------------------------------------------------------

type Active = {
	Seat: BasePart,
	Root: BasePart, -- lo que se sigue (la base del vehículo, o el asiento en el metro)
	View: View,
	Focus: Vector3,
	Velocity: Vector3,
	LastTarget: Vector3,
	SavedMin: number,
	SavedMax: number,
	SetMax: number,
	Walls: { BasePart }?, -- (metro) las paredes del vagón
}
local active: Active? = nil
local WALLS = { Side = true, Window = true, Upper = true, Roof = true, End = true, Door = true, Windshield = true, Nose = true }
local anchor: Part? = nil
local lastManual = -math.huge -- última vez que el jugador movió la cámara él mismo

local function humanoidOf(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function flat(v: Vector3): Vector3?
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 0.05 then f.Unit else nil
end

-- Dónde debería estar el foco ahora (vehículos: por encima del techo, en el centro)
local function targetOf(a: Active): Vector3
	local root = a.Root
	return root.Position + root.CFrame.UpVector * (a.View.Height - root.Size.Y / 2)
end

local function getAnchor(): Part
	if anchor and anchor.Parent then
		return anchor
	end
	local part = Instance.new("Part")
	part.Name = "RideCameraFocus"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = workspace.CurrentCamera
	anchor = part
	return part
end

-- ¿Qué se ve desde este asiento? nil = un asiento normal (banco, cine…): cámara de siempre
local function classify(seat: BasePart): (BasePart?, View?)
	if seat:HasTag("MetroSeat") then
		-- (lo que se sigue es el vagón entero: sus paredes, ventanas y techo)
		local car = seat:FindFirstAncestorOfClass("Model")
		return (if car and car.PrimaryPart then car.PrimaryPart else seat), RideCamera.view(Vector3.zero, true)
	end
	local model = seat:FindFirstAncestorOfClass("Model")
	while model and not model:GetAttribute("Drivable") do
		model = model:FindFirstAncestorOfClass("Model")
	end
	if not model or not model.PrimaryPart then
		return nil, nil
	end
	local ok, size = pcall(function()
		return model:GetExtentsSize()
	end)
	return model.PrimaryPart, RideCamera.view(if ok then size else model.PrimaryPart.Size, false)
end

local function leave()
	local a = active
	if not a then
		return
	end
	active = nil
	local camera = workspace.CurrentCamera
	local humanoid = humanoidOf()
	-- La distancia: la de antes (sin quedarse lejísimos, como con el autobús)
	local distance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local comfy = math.clamp(distance, math.max(a.SavedMin, 6), math.min(a.SavedMax, 16))
	player.CameraMinZoomDistance = a.SavedMin
	player.CameraMaxZoomDistance = comfy -- (acerca la cámara hasta ahí…)
	task.delay(0.12, function()
		if player.CameraMaxZoomDistance == comfy then
			player.CameraMaxZoomDistance = a.SavedMax -- (…y deja alejarla otra vez como siempre)
		end
	end)
	local subject = camera.CameraSubject
	if humanoid and (subject == anchor or subject == nil or subject:IsA("VehicleSeat") or subject:IsA("Seat")) then
		camera.CameraSubject = humanoid
	end
	-- Detrás del personaje, mirando hacia donde miraba, un poco desde arriba (sin ángulos raros)
	if camera.CameraType == Enum.CameraType.Custom then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local look = flat(camera.CFrame.LookVector) or flat(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
			local pitch = math.rad(-16)
			local dir = look * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
			local head = root.Position + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(head - dir * comfy, head)
		end
	end
end

local function enter(seat: BasePart)
	leave()
	local root, view = classify(seat)
	if not root or not view then
		return
	end
	local camera = workspace.CurrentCamera
	local a: Active = {
		Seat = seat,
		Root = root,
		View = view,
		Focus = Vector3.zero,
		Velocity = Vector3.zero,
		LastTarget = Vector3.zero,
		SavedMin = player.CameraMinZoomDistance,
		SavedMax = player.CameraMaxZoomDistance,
		SetMax = 0,
	}
	a.Focus = targetOf(a)
	a.LastTarget = a.Focus
	active = a
	-- Distancias: más lejos que el mínimo al subir; luego se puede acercar hasta el mínimo
	local max = math.max(view.Max, view.Start)
	if view.Mode == "Fuera" then
		max = math.max(max, a.SavedMax)
	end
	a.SetMax = max
	player.CameraMaxZoomDistance = max
	player.CameraMinZoomDistance = math.min(view.Start, max)
	task.delay(0.15, function()
		if active == a then
			player.CameraMinZoomDistance = view.Min
		end
	end)
	if view.Mode ~= "Fuera" then
		-- En el metro la cámara sigue a tu personaje, como siempre, mirando a lo largo del vagón
		-- (detrás del asiento está la pared: por ahí no se ve nada)
		local character = player.Character
		local head = character and character:FindFirstChild("Head") :: BasePart?
		local along = flat(root.CFrame.LookVector)
		if head and along and camera.CameraType == Enum.CameraType.Custom then
			if along:Dot(flat(camera.CFrame.LookVector) or along) < 0 then
				along = -along
			end
			camera.CFrame = CFrame.lookAt(head.Position - along * view.Start + Vector3.new(0, 1.2, 0), head.Position)
		end
		return
	end
	local focus = getAnchor()
	focus.CFrame = CFrame.new(a.Focus)
	camera.CameraSubject = focus
	-- Detrás del vehículo, un poco desde arriba
	if camera.CameraType == Enum.CameraType.Custom then
		local look = flat(root.CFrame.LookVector) or Vector3.new(0, 0, -1)
		local pitch = math.rad(-14)
		local dir = look * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
		camera.CFrame = CFrame.lookAt(a.Focus - dir * view.Start, a.Focus)
	end
end

-- Antes de la cámara de Roblox: mueve el foco
local function beforeCamera(dt: number)
	local a = active
	if not a then
		return
	end
	local humanoid = humanoidOf()
	if not humanoid or humanoid.SeatPart ~= a.Seat or not a.Root.Parent then
		leave()
		return
	end
	if a.View.Mode ~= "Fuera" then
		return
	end
	local focus = getAnchor()
	local target = targetOf(a)
	if dt > 0 then
		-- Velocidad del vehículo (por lo que se mueve, así vale también para el metro y el autobús
		-- que mueve el servidor)
		local measured = (target - a.LastTarget) / dt
		if measured.Magnitude > 200 then
			measured = Vector3.zero -- (un teletransporte)
		end
		a.Velocity = a.Velocity:Lerp(measured, 1 - math.exp(-10 * dt))
	end
	a.LastTarget = target
	a.Focus = RideCamera.follow(a.Focus, a.Velocity, target, dt)
	focus.CFrame = CFrame.new(a.Focus)
	-- Si algo (un diálogo, una cinemática) devolvió la cámara al personaje, se recupera el foco
	local camera = workspace.CurrentCamera
	local subject = camera.CameraSubject
	if camera.CameraType == Enum.CameraType.Custom and subject ~= focus then
		if subject == nil or subject == humanoid or subject:IsA("VehicleSeat") or subject:IsA("Seat") then
			camera.CameraSubject = focus
		end
	end
end

-- Metro: la cámara no sale del vagón (si una pared o ventana tapa la cabeza, se pone delante)
local function keepInside(a: Active)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local car = a.Root:FindFirstAncestorOfClass("Model") or a.Root.Parent
	if camera.CameraType ~= Enum.CameraType.Custom or not head or not car then
		return
	end
	local from = head.Position
	local offset = camera.CFrame.Position - from
	if offset.Magnitude < 0.5 then
		return
	end
	-- Solo la caja del vagón (paredes, ventanas, puertas, techo): no los asientos ni las barras
	if not a.Walls then
		local walls = {}
		for _, part in car:GetDescendants() do
			if part:IsA("BasePart") and WALLS[part.Name] then
				table.insert(walls, part)
			end
		end
		a.Walls = walls
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = a.Walls :: any
	params.RespectCanCollide = false -- (también las ventanas, que no chocan)
	local hit = workspace:Raycast(from, offset, params)
	if hit then
		local keep = math.max(0.3, (hit.Position - from).Magnitude - 0.5)
		camera.CFrame = CFrame.new(from + offset.Unit * keep) * camera.CFrame.Rotation
	end
end

-- Después de la cámara de Roblox: se coloca sola detrás del vehículo en marcha
local function afterCamera(dt: number)
	local a = active
	if not a then
		return
	end
	if a.View.Mode ~= "Fuera" then
		keepInside(a)
		return
	end
	local camera = workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= anchor then
		return
	end
	local forward = flat(a.Root.CFrame.LookVector)
	local look = flat(camera.CFrame.LookVector)
	if not forward or not look then
		return
	end
	local speed = Vector3.new(a.Velocity.X, 0, a.Velocity.Z).Magnitude
	-- (marcha atrás: se queda mirando hacia delante, no da la vuelta)
	if a.Velocity:Dot(forward) < 0 then
		speed = 0
	end
	local turn = RideCamera.autoTurn(RideCamera.yawBetween(look, forward), speed, os.clock() - lastManual, dt)
	if math.abs(turn) > 1e-5 then
		local pivot = a.Focus
		camera.CFrame = CFrame.new(pivot) * CFrame.Angles(0, turn, 0) * CFrame.new(-pivot) * camera.CFrame
	end
end

function RideCamera.init()
	-- ¿Mueve el jugador la cámara él mismo? (ratón con el botón derecho, dedo, joystick derecho, rueda)
	UserInputService.InputChanged:Connect(function(input, processed)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseMovement then
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				lastManual = os.clock()
			end
		elseif kind == Enum.UserInputType.Touch and not processed then
			lastManual = os.clock()
		elseif kind == Enum.UserInputType.MouseWheel and not processed then
			lastManual = os.clock()
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 and input.Position.Magnitude > 0.25 then
			lastManual = os.clock()
		end
	end)

	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		humanoid.Seated:Connect(function(isSeated, seat)
			if isSeated and seat then
				task.defer(function()
					if humanoid.SeatPart == seat then
						enter(seat)
					end
				end)
			else
				leave()
			end
		end)
		humanoid.Died:Connect(leave)
		if humanoid.SeatPart then
			enter(humanoid.SeatPart)
		end
	end
	if player.Character then
		task.spawn(watch, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		leave()
		watch(character)
	end)

	RunService:BindToRenderStep("RideCameraFocus", Enum.RenderPriority.Camera.Value - 1, beforeCamera)
	RunService:BindToRenderStep("RideCameraFollow", Enum.RenderPriority.Camera.Value + 1, afterCamera)
end

return RideCamera
