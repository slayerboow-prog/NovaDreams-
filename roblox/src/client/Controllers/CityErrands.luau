-- CityErrands (cliente): los «Encargos de la ciudad» (servidor: CityErrandService).
--   * CityErrands.list(): la gente con ❗ que tienes cerca (atributo CityErrandMarks): MapUI los pinta.
--   * CityErrands.current(): el encargo que estás haciendo (atributo CityErrand, JSON) para el panel
--     de misiones, el ❓ y las pistas (UI/Hud).
--   * CityErrands.abandon(): dejarlo.
--   * Los objetos y la gente del encargo de otro jugador (workspace.CityErrands.Items_<id>, atributo
--     ErrandOwner) no se ven: cada uno ve solo los suyos.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityErrands = {}

local player = Players.LocalPlayer

export type Mark = { Id: string, Title: string, Giver: string, X: number, Y: number, Z: number }
export type State = { Id: string, Title: string, Giver: string, Step: string, StepNum: number, StepTotal: number, Money: number, Xp: number, Carry: string?, Left: number? }

local function decode(name: string): any
	local raw = player:GetAttribute(name)
	if type(raw) ~= "string" then
		return nil
	end
	local ok, value = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok then value else nil
end

-- La lista se guarda ya descifrada y solo se vuelve a descifrar cuando cambia el atributo (MapUI la
-- pide 10 veces por segundo: antes era un JSONDecode cada vez). No la cambies: es compartida.
local marksRaw: any = nil
local marksList: { Mark } = {}
function CityErrands.list(): { Mark }
	local raw = player:GetAttribute("CityErrandMarks")
	if raw ~= marksRaw then
		marksRaw = raw
		local marks = decode("CityErrandMarks")
		marksList = if type(marks) == "table" then marks else {}
	end
	return marksList
end

function CityErrands.current(): State?
	local state = decode("CityErrand")
	return if type(state) == "table" and type(state.Title) == "string" then state else nil
end

function CityErrands.abandon()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("CityErrand")
	if remote then
		(remote :: RemoteEvent):FireServer("Abandon")
	end
end

-- Esconde lo de los encargos de los demás (también lo que llegue después)
local function hide(instance: Instance)
	if instance:IsA("BasePart") then
		instance.LocalTransparencyModifier = 1
	elseif instance:IsA("ProximityPrompt") then
		instance.Enabled = false
	elseif instance:IsA("BillboardGui") or instance:IsA("Highlight") then
		instance.Enabled = false
	end
end

local function watch(folder: Instance)
	local owner = folder:GetAttribute("ErrandOwner")
	if owner == nil or owner == player.UserId then
		return
	end
	for _, descendant in folder:GetDescendants() do
		hide(descendant)
	end
	folder.DescendantAdded:Connect(function(descendant)
		task.defer(hide, descendant)
	end)
end

function CityErrands.init()
	local root = workspace:WaitForChild("CityErrands", 60)
	if not root then
		return
	end
	for _, child in root:GetChildren() do
		watch(child)
	end
	root.ChildAdded:Connect(function(child)
		task.defer(watch, child)
	end)
end

return CityErrands
