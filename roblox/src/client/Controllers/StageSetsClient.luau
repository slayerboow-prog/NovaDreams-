-- StageSetsClient (cliente): dibuja los DECORADOS POR FASE de tu historia (shared/LifeStory/StageSets).
--
--   * Los tuyos (Scope = "Player"): el servidor publica en tu atributo StageSets qué decorado toca, en
--     qué estado y dónde (WorldMemoryService); aquí se construyen en tu pantalla (shared/StageBuilders) y
--     se quitan o cambian cuando cambia tu historia. Nadie más los ve. Al volver a entrar siguen ahí
--     (la memoria del mundo se guarda con la partida).
--   * Los de todos (Scope = "Global"): el servidor los construye una vez en workspace.StageSets con una
--     carpeta por estado; aquí se enseña solo la variante de tu historia (las demás, invisibles y sin
--     choque solo para ti, como SceneClient).
--   * Los que se mueven (la criatura que vive en el cráter) hacen su rutina mientras estás cerca.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local StageSets = require(ReplicatedStorage.Shared.LifeStory.StageSets)
local StageBuilders = require(ReplicatedStorage.Shared.StageBuilders)

local StageSetsClient = {}

local player = Players.LocalPlayer
local ANIMATE_DISTANCE = 220 -- más lejos, la rutina se para (no se nota)

type Shown = { State: string, Key: string, Built: StageBuilders.Built?, Folder: Folder }

local shown: { [string]: Shown } = {}
local root: Folder? = nil
local started = os.clock()

local function folder(): Folder
	if root and root.Parent then
		return root
	end
	local f = Instance.new("Folder")
	f.Name = "MisDecorados"
	f.Parent = workspace
	root = f
	return f
end

local function tier(): string
	local t = player:GetAttribute("GraphicsTier")
	return if t == "Low" or t == "High" then t else "Medium"
end

-- Variante de un decorado de todos: solo se ve la de tu estado
local function setHidden(model: Instance, hidden: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
			if hidden and d.CanCollide then
				d:SetAttribute("StageCollide", true)
				d.CanCollide = false
			elseif not hidden and d:GetAttribute("StageCollide") then
				d:SetAttribute("StageCollide", nil)
				d.CanCollide = true
			end
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") then
			(d :: any).Enabled = not hidden
		end
	end
end

local function showGlobal(id: string, state: string?)
	local all = workspace:FindFirstChild("StageSets")
	local holder = all and all:FindFirstChild(id)
	if not holder then
		return
	end
	for _, variant in holder:GetChildren() do
		setHidden(variant, variant.Name ~= state)
	end
end

local function decode(text: any): { [string]: any }
	if type(text) ~= "string" or text == "" then
		return {}
	end
	local ok, value = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	return if ok and type(value) == "table" then value else {}
end

local function refresh()
	local wanted = decode(player:GetAttribute("StageSets"))
	-- Quitar lo que ya no toca (o ha cambiado)
	for id, entry in shown do
		local w = wanted[id]
		local key = w and (tostring(w.S) .. "|" .. HttpService:JSONEncode(w.P or {}) .. "|" .. tostring(w.R)) or nil
		if key ~= entry.Key then
			entry.Folder:Destroy()
			shown[id] = nil
		end
	end
	for id, def in StageSets.Defs do
		local w = wanted[id]
		if def.Scope == "Global" then
			showGlobal(id, w and w.S or nil)
		elseif w and not shown[id] and type(w.P) == "table" then
			local holder = Instance.new("Folder")
			holder.Name = id
			holder.Parent = folder()
			local cf = CFrame.new(w.P[1] or 0, w.P[2] or 0, w.P[3] or 0) * CFrame.Angles(0, math.rad(w.R or 0), 0)
			local ok, built = pcall(StageBuilders.build, def.Builder, holder, cf, StageSets.paramsFor(def, w.S), tier())
			if not ok then
				warn(("[StageSets] No se pudo dibujar %s: %s"):format(id, tostring(built)))
			end
			shown[id] = {
				State = w.S,
				Key = tostring(w.S) .. "|" .. HttpService:JSONEncode(w.P or {}) .. "|" .. tostring(w.R),
				Built = if ok then built else nil,
				Folder = holder,
			}
		end
	end
end

-- (pruebas y depuración) qué decorados tuyos se ven ahora
function StageSetsClient.shown(): { [string]: string }
	local out = {}
	for id, entry in shown do
		out[id] = entry.State
	end
	return out
end

function StageSetsClient.init()
	player:GetAttributeChangedSignal("StageSets"):Connect(function()
		local ok, err = pcall(refresh)
		if not ok then
			warn("[StageSets] " .. tostring(err))
		end
	end)
	player:GetAttributeChangedSignal("GraphicsTier"):Connect(function()
		-- Otro nivel gráfico: se vuelven a dibujar (más o menos rocas, humo…)
		for id, entry in shown do
			entry.Folder:Destroy()
			shown[id] = nil
		end
		pcall(refresh)
	end)
	pcall(refresh)
	-- Los decorados de todos llegan por trozos (el mapa se carga poco a poco): al llegar, su variante
	task.spawn(function()
		local all = workspace:WaitForChild("StageSets", 60)
		if not all then
			return
		end
		local pending = false
		all.DescendantAdded:Connect(function()
			if not pending then
				pending = true
				task.delay(0.5, function()
					pending = false
					pcall(refresh)
				end)
			end
		end)
		pcall(refresh)
	end)
	local last = os.clock()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		local camera = workspace.CurrentCamera
		local eye = camera and camera.CFrame.Position
		for _, entry in shown do
			local built = entry.Built
			if built and built.Update then
				local primary = built.Model.PrimaryPart
				if not eye or not primary or (primary.Position - eye).Magnitude < ANIMATE_DISTANCE then
					pcall(built.Update, dt, now - started)
				end
			end
		end
	end)
end

return StageSetsClient
