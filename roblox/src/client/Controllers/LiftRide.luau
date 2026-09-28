-- LiftRide (cliente): el viaje en ascensor se ve fluido.
-- El servidor mueve la cabina (World/Lift) y publica el horario del viaje en sus atributos
-- (LiftFrom, LiftTo, LiftStart, LiftDuration, Moving). Aquí, en cada fotograma, se calcula con las
-- mismas cuentas (shared/LiftMath) dónde está la cabina y se pone ahí en tu pantalla; si vas dentro
-- (atributo LiftTower), tu personaje sube o baja con ella sin tirones ni caídas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LiftMath = require(ReplicatedStorage.Shared.LiftMath)

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
local function cabinOf(key: string): Model?
	local cached = cabinCache[key]
	if cached and cached.Parent then
		return cached
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d.Name == "Interior_Tower" and d:GetAttribute("Key") == key then
			local cabin = d:FindFirstChild("Ascensor")
			if cabin and cabin:IsA("Model") then
				cabinCache[key] = cabin
				return cabin
			end
		end
	end
	return nil
end

local riding: { Cabin: Model, Offset: number }? = nil

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
		riding = nil
		return
	end
	local cabin = cabinOf(key)
	if not cabin or not root or not cabin:GetAttribute("Moving") then
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
	local floorY = base.Position.Y + h
	if not riding or riding.Cabin ~= cabin then
		riding = { Cabin = cabin, Offset = root.Position.Y - floorY }
	end
	local pos = root.Position
	root.CFrame = CFrame.new(pos.X, floorY + riding.Offset, pos.Z) * (root.CFrame - pos)
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

function LiftRide.init()
	RunService.RenderStepped:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			warn("[LiftRide] " .. tostring(err))
		end
	end)
end

return LiftRide
