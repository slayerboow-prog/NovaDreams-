-- Cucarachas (cliente): las cucarachas hechas por código (World/Kit/Cucaracha, etiqueta "Cucaracha")
-- se mueven como cucarachas, solo en tu pantalla y solo cerca de ti:
--   * al correr, las seis patas van en dos trípodes (delantera y trasera de un lado con la media del
--     otro), muy deprisa: corretean;
--   * las antenas se agitan siempre (más al correr), el cuerpo tiembla un poco y la cabeza mira a
--     los lados cuando está quieta.
--
-- Las cuentas son puras (Cucarachas.pose): scripts/test-cucarachas.luau

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Cucarachas = {}

local RADIUS = 220
local angles = CFrame.Angles
local sin = math.sin

-- Las articulaciones de World/Kit/Cucaracha (M_<nombre>) y a qué trípode va cada pata
Cucarachas.TRIPODE = {
	PataDelanteraL = 0, PataTraseraL = 0, PataMediaR = 0,
	PataDelanteraR = 1, PataTraseraR = 1, PataMediaL = 1,
}

-- Postura en el instante t (segundos) con velocidad speed (studs/s): { [articulación] = CFrame }
function Cucarachas.pose(t: number, speed: number, seed: number): { [string]: CFrame }
	local poses = {}
	local run = math.clamp(speed / 10, 0, 1)
	local rate = 14 + 10 * run -- pasos por segundo (rapidísimo)
	for name, group in Cucarachas.TRIPODE do
		local phase = t * rate + group * math.pi
		local swing = sin(phase) * 0.55 * run -- adelante/atrás (giro alrededor de la vertical)
		local lift = math.max(0, sin(phase + math.pi / 2)) * 0.35 * run -- arriba al avanzar
		local side = if string.sub(name, -1) == "L" then -1 else 1
		poses["M_" .. name] = angles(0, swing, side * lift)
	end
	local wiggle = 0.25 + 0.35 * run
	poses.M_AntenaL = angles(sin(t * 7.3 + seed) * wiggle, sin(t * 5.1 + seed) * wiggle, 0)
	poses.M_AntenaR = angles(sin(t * 6.7 + seed + 1.3) * wiggle, sin(t * 4.7 + seed + 0.6) * wiggle, 0)
	poses.M_Cuerpo = CFrame.new(0, sin(t * rate * 2) * 0.04 * run, 0) * angles(0, 0, sin(t * rate) * 0.03 * run)
	local look = if run < 0.2 then sin(t * 0.9 + seed) * 0.5 else 0
	poses.M_Cabeza = angles(sin(t * 2.1 + seed) * 0.08, look, 0)
	return poses
end

type Entry = { Root: BasePart, Motors: { [string]: Motor6D }, Seed: number }
local entries: { [Model]: Entry } = {}

local function add(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	task.defer(function()
		local root = model.PrimaryPart or model:FindFirstChild("Raiz")
		if not root or not root:IsA("BasePart") then
			return
		end
		local motors = {}
		for _, d in model:GetDescendants() do
			if d:IsA("Motor6D") then
				motors[d.Name] = d
			end
		end
		entries[model] = { Root = root, Motors = motors, Seed = math.random() * 10 }
	end)
end

local function remove(model: Instance)
	entries[model :: Model] = nil
end

function Cucarachas.init()
	for _, model in CollectionService:GetTagged("Cucaracha") do
		add(model)
	end
	CollectionService:GetInstanceAddedSignal("Cucaracha"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("Cucaracha"):Connect(remove)
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera or next(entries) == nil then
			return
		end
		local from = camera.CFrame.Position
		local t = os.clock()
		for model, entry in entries do
			if not model.Parent or not entry.Root.Parent then
				entries[model] = nil
				continue
			end
			if (entry.Root.Position - from).Magnitude > RADIUS then
				continue
			end
			local v = entry.Root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			for name, cf in Cucarachas.pose(t, speed, entry.Seed) do
				local motor = entry.Motors[name]
				if motor then
					motor.Transform = cf
				end
			end
		end
	end)
end

return Cucarachas
