-- LiftRide (cliente): el viaje en ascensor se ve fluido.
-- El servidor mueve la cabina (World/Lift) y publica el horario del viaje en sus atributos
-- (LiftFrom, LiftTo, LiftStart, LiftDuration, Moving). Aquí, en cada fotograma, se calcula con las
-- mismas cuentas (shared/LiftMath) dónde está la cabina y se pone ahí en tu pantalla; si vas dentro
-- (atributo LiftTower), tu personaje sube o baja con ella sin tirones ni caídas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LiftMath = require(ReplicatedStorage.Shared.LiftMath)
local SoundFx = require(script.Parent.SoundFx)

local LiftRide = {}

local player = Players.LocalPlayer

local function serverNow(): number
	local ok, now = pcall(function()
		return (workspace :: any):GetServerTimeNow()
	end)
	return if ok and type(now) == "number" then now else os.clock()
end

-- La cabina de ese edificio (la torre: Interior_Tower con atributo Key)
local cabinCache: { [string]: Model } = {}
-- Si no se encuentra (aún no ha llegado con la carga por zonas), no se vuelve a recorrer todo el mapa
-- en cada fotograma: se reintenta como mucho una vez por segundo.
local missedAt: { [string]: number } = {}
local function cabinOf(key: string): Model?
	local cached = cabinCache[key]
	if cached and cached.Parent then
		return cached
	end
	local missed = missedAt[key]
	if missed and os.clock() - missed < 1 then
		return nil
	end
	missedAt[key] = os.clock()
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d.Name == "Interior_Tower" and d:GetAttribute("Key") == key then
			local cabin = d:FindFirstChild("Ascensor")
			if cabin and cabin:IsA("Model") then
				cabinCache[key] = cabin
				missedAt[key] = nil
				return cabin
			end
		end
	end
	return nil
end

local riding: { Cabin: Model, LastFloorY: number, Character: Model }? = nil
-- Para el "ding" al llegar: la cabina en la que ibas deja de moverse
local wasMoving = false
local lastCabin: Model? = nil

local function arrivalDing(cabin: Model)
	local floorPart = cabin:FindFirstChild("CabinFloor") :: BasePart?
	if floorPart then
		SoundFx.play("Ascensor", 1, nil, floorPart)
	end
end

-- Pone la cabina (en tu pantalla) a esa altura sobre la planta baja. Mide dónde está de verdad su
-- suelo (lo que llega del servidor puede haberla movido) y la lleva hasta ahí.
local function placeLocal(cabin: Model, height: number)
	local base = cabin:GetAttribute("Base")
	local floorPart = cabin:FindFirstChild("CabinFloor") :: BasePart?
	if typeof(base) ~= "CFrame" or not floorPart then
		return
	end
	local current = floorPart.Position.Y + 0.2 - base.Position.Y
	local dy = height - current
	if math.abs(dy) < 1e-4 then
		return
	end
	for _, p in cabin:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = p.CFrame + Vector3.new(0, dy, 0)
		end
	end
end

local function step()
	local key = player:GetAttribute("LiftTower")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if type(key) ~= "string" then
		-- (el servidor quita LiftTower justo al llegar: si la cabina ya se ha parado, ha llegado)
		if wasMoving and lastCabin and lastCabin.Parent and not lastCabin:GetAttribute("Moving") then
			arrivalDing(lastCabin)
		end
		riding = nil
		wasMoving = false
		lastCabin = nil
		return
	end
	local cabin = cabinOf(key)
	local moving = cabin ~= nil and cabin:GetAttribute("Moving") == true
	if wasMoving and not moving and cabin then
		arrivalDing(cabin) -- ha llegado a la planta
	end
	wasMoving = moving
	lastCabin = cabin
	if not cabin or not root or not moving then
		return
	end
	local from, to = cabin:GetAttribute("LiftFrom"), cabin:GetAttribute("LiftTo")
	local start, duration = cabin:GetAttribute("LiftStart"), cabin:GetAttribute("LiftDuration")
	if type(from) ~= "number" or type(to) ~= "number" or type(start) ~= "number" or type(duration) ~= "number" then
		return
	end
	local h = LiftMath.heightAt(from, to, serverNow() - start, duration)
	placeLocal(cabin, h)
	local base = cabin:GetAttribute("Base") :: CFrame
	-- Si ya no estás en la cabina (te han llevado a otro sitio o has reaparecido), no se te arrastra
	local floorPart = cabin:FindFirstChild("CabinFloor") :: BasePart?
	if floorPart and Vector3.new(root.Position.X - floorPart.Position.X, 0, root.Position.Z - floorPart.Position.Z).Magnitude > 8 then
		riding = nil
		return
	end
	local floorY = base.Position.Y + h
	-- (personaje nuevo —has muerto o reaparecido—: se empieza de cero, sin el desfase del de antes)
	if not riding or riding.Cabin ~= cabin or riding.Character ~= character then
		riding = { Cabin = cabin, LastFloorY = floorY, Character = character :: Model }
	end
	local ride = riding :: { Cabin: Model, LastFloorY: number, Character: Model }
	-- Solo se te mueve lo que se ha movido la cabina en este fotograma (antes se te clavaba a una
	-- altura fija y se borraba toda la velocidad: no se podía saltar ni andar bien dentro)
	local dy = floorY - ride.LastFloorY
	ride.LastFloorY = floorY
	if dy ~= 0 then
		root.CFrame += Vector3.new(0, dy, 0)
	end
	-- De pie en el suelo: sin velocidad vertical (que no se acumule la caída); saltando, se respeta
	local humanoid = (character :: Model):FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
		local v = root.AssemblyLinearVelocity
		if v.Y < 0 then
			root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
		end
	end
end

function LiftRide.init()
	-- Al reaparecer ya no vas en el ascensor (aunque el atributo tarde en llegar del servidor)
	player.CharacterAdded:Connect(function()
		riding = nil
		wasMoving = false
		lastCabin = nil
	end)
	RunService.RenderStepped:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			warn("[LiftRide] " .. tostring(err))
		end
	end)
end

return LiftRide
