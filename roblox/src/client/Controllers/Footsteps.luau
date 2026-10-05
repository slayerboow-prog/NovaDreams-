-- Footsteps (cliente): pasos según el suelo, para ti, los demás jugadores y la gente de la ciudad.
--   * Hormigón, ladrillo, madera, cristal… «duro»; hierba, arena, nieve, tierra «blando»; chapa y metal
--     «metal»; moqueta y tela «tela» (shared/SkyExtras.footstep, con un tono distinto por material).
--   * Audios públicos de 131772048424194 y 5033818552 (los no públicos no se usan).
--   * Sirve para todos: el ritmo sale de lo que se mueve el cuerpo (también la gente que se mueve por
--     código, sin físicas), y el material del suelo, del Humanoid o de un rayo hacia abajo.
--   * Solo los más cercanos (8, o 4 en nivel Bajo) a menos de 70 studs. Se calla el paso de siempre
--     de Roblox de los personajes que suenan aquí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkyExtras = require(ReplicatedStorage.Shared.SkyExtras)
local SoundFx = require(script.Parent.SoundFx)
local Perf = require(script.Parent.Parent.UI.Perf)

local Footsteps = {}

local RANGE = 70

type Walker = { Root: BasePart, Humanoid: Humanoid, Last: Vector3?, Timer: number, Sound: Sound?, Left: boolean }

local humanoids: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local walkers: { [Humanoid]: Walker } = setmetatable({}, { __mode = "k" }) :: any
local active: { Walker } = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function rootOf(h: Humanoid): BasePart?
	local model = h.Parent
	if not model then
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return if model:IsA("Model") then model.PrimaryPart else nil
end

local function muteDefault(root: BasePart)
	local running = root:FindFirstChild("Running")
	if running and running:IsA("Sound") and running.Volume > 0 then
		running.Volume = 0
	end
end

local function material(w: Walker): string?
	local floor = w.Humanoid.FloorMaterial
	if floor ~= Enum.Material.Air then
		return floor.Name
	end
	local model = w.Humanoid.Parent
	rayParams.FilterDescendantsInstances = if model then { model, workspace.CurrentCamera } else { workspace.CurrentCamera }
	local hip = math.max(w.Humanoid.HipHeight, 1) + w.Root.Size.Y / 2 + 1.2
	local hit = workspace:Raycast(w.Root.Position, Vector3.new(0, -hip, 0), rayParams)
	return if hit then hit.Material.Name else nil
end

local function step(w: Walker)
	local name = material(w)
	if not name then
		return
	end
	local info = SkyExtras.footstep(name)
	if not info then
		return
	end
	local sound = w.Sound
	if not sound or sound.Parent ~= w.Root then
		local s = Instance.new("Sound")
		s.Name = "Pisada"
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = RANGE
		s.SoundGroup = SoundFx.group("SFX")
		s.Parent = w.Root
		w.Sound = s
		sound = s
	end
	local s = sound :: Sound
	s.SoundId = info.Id
	-- (izquierda y derecha un pelín distintas, y un poco de azar: no suena a máquina)
	w.Left = not w.Left
	s.PlaybackSpeed = info.Pitch * (if w.Left then 0.97 else 1.03) * (0.96 + math.random() * 0.08)
	local mine = Players.LocalPlayer.Character == w.Humanoid.Parent
	s.Volume = info.Volume * (if mine then 1 else 0.8)
	s.TimePosition = 0
	s:Play()
end

-- Elige los más cercanos (cada medio segundo)
local function choose()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local here = cam.CFrame.Position
	local list = {}
	for h in humanoids do
		if h.Parent and h.Health > 0 then
			local root = rootOf(h)
			if root then
				local d = (root.Position - here).Magnitude
				if d < RANGE then
					table.insert(list, { H = h, Root = root, D = d })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local max = if Perf.tierName() == "Low" then 4 else 8
	table.clear(active)
	for i = 1, math.min(max, #list) do
		local entry = list[i]
		local w = walkers[entry.H]
		if not w or w.Root ~= entry.Root then
			w = { Root = entry.Root, Humanoid = entry.H, Last = nil, Timer = 0, Sound = nil, Left = false }
			walkers[entry.H] = w
		end
		muteDefault(entry.Root)
		table.insert(active, w :: Walker)
	end
end

local function update(dt: number)
	for _, w in active do
		if w.Root.Parent then
			local pos = w.Root.Position
			local last = w.Last
			w.Last = pos
			if last and dt > 0 then
				local flat = (pos - last) * Vector3.new(1, 0, 1)
				local speed = flat.Magnitude / dt
				local state = w.Humanoid:GetState()
				local airborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Seated
				local every = if airborne or w.Humanoid.Sit or speed > 60 then nil else SkyExtras.stepInterval(speed)
				if every then
					w.Timer += dt
					if w.Timer >= every then
						w.Timer = 0
						step(w)
					end
				else
					w.Timer = 0.15 -- (al echar a andar, el primer paso llega enseguida)
				end
			end
		end
	end
end

local function watch(item: Instance)
	if item:IsA("Humanoid") then
		humanoids[item] = true
	end
end

function Footsteps.init()
	task.spawn(function()
		for i, item in workspace:GetDescendants() do
			watch(item)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)
	workspace.DescendantAdded:Connect(watch)
	local since = 0
	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since >= 0.5 then
			since = 0
			pcall(choose)
		end
		local ok, err = pcall(update, dt)
		if not ok then
			warn("[Footsteps] " .. tostring(err))
		end
	end)
end

return Footsteps
