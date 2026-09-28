-- Nudge (cliente): la gente reacciona cuando chocas con ella o cuando pasa tu coche.
--
--   * NPC del servidor (gente fija de la calle, dependientes, profes, niños del cole…): si pasas
--     rozándolos se apartan de lado con un traspiés (ReactMotion "Bumped"), te miran (ActorLife) y a
--     veces sueltan un "¡Eh!". Mientras se apartan, en tu pantalla dejan de ser un muro: los empujas
--     un poco en vez de chocar contra ellos. Si llegas con el coche, se tiran a un lado ("Dive").
--   * Nudge.say: bocadillo corto encima de alguien (o de un animal), solo en tu pantalla (UI/SpeechBubbles).
-- Barato: se mira 8 veces por segundo y solo alrededor de tu personaje.
-- Los peatones del tráfico (Ambient) y los animales (Wildlife) hacen su versión en su propio bucle.

local Players = game:GetService("Players")

local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

local Nudge = {}

local player = Players.LocalPlayer

local LINES = { "¡Eh!", "¡Cuidado!", "¡Perdona!", "¡Oye, mira por dónde vas!", "¡Uy!", "¡Sin empujar!" }
local CAR_LINES = { "¡Cuidado!", "¡Frena!", "¡Que me pillas!", "¡Eh, el coche!" }
local COOLDOWN = 2.5

-- Bocadillo solo para ti encima de una pieza (la cabeza de alguien, un animal…): el mismo de todos
-- (UI/SpeechBubbles), así un "¡Eh!" sustituye a lo que estaba diciendo en vez de ponerse encima
function Nudge.say(adornee: BasePart?, text: string, seconds: number?)
	if not adornee or not adornee.Parent then
		return
	end
	SpeechBubbles.show(adornee, text, { Seconds = seconds or 1.6 })
end

-- Qué lado del NPC queda hacia ti (+1 su derecha, -1 su izquierda)
function Nudge.sideOf(npcCFrame: CFrame, from: Vector3): number
	local rel = npcCFrame:PointToObjectSpace(from)
	return if rel.X >= 0 then 1 else -1
end

local recent: { [Model]: number } = {}

-- Mientras se aparta, sus piezas no chocan contigo (solo en tu pantalla): lo empujas un poco
local function letThrough(model: Model, seconds: number)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			d.CanCollide = false
			table.insert(parts, d)
		end
	end
	task.delay(seconds, function()
		for _, p in parts do
			if p.Parent then
				p.CanCollide = true
			end
		end
	end)
end

local function npcOf(part: BasePart): (Model?, Humanoid?)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if Players:GetPlayerFromCharacter(model) or humanoid.Health <= 0 then
				return nil, nil
			end
			return model, humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

local function react(model: Model, me: Vector3, car: boolean)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local now = os.clock()
	if (recent[model] or 0) > now then
		return
	end
	recent[model] = now + COOLDOWN
	local side = Nudge.sideOf(root.CFrame, me)
	local ReactMotion = require(script.Parent.ReactMotion)
	ReactMotion.play(model, if car then "Dive" else "Bumped", { Side = side })
	letThrough(model, if car then 1.3 else 1.1)
	if car or math.random() < 0.6 then
		local lines = if car then CAR_LINES else LINES
		Nudge.say(model:FindFirstChild("Head") :: BasePart?, lines[math.random(1, #lines)], 1.8)
	end
end

function Nudge.init()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	task.spawn(function()
		while true do
			task.wait(0.125)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then
				continue
			end
			local ok, err = pcall(function()
				local seat = humanoid.SeatPart
				local v = if seat then seat.AssemblyLinearVelocity else root.AssemblyLinearVelocity
				local speed = Vector3.new(v.X, 0, v.Z).Magnitude
				local car = seat ~= nil and speed > 10
				local exclude: { Instance } = { character }
				if seat then
					local vehicle = seat:FindFirstAncestorOfClass("Model")
					if vehicle then
						table.insert(exclude, vehicle)
					end
				end
				for _, name in { "AmbientLife", "Traffic" } do
					local f = workspace:FindFirstChild(name)
					if f then
						table.insert(exclude, f)
					end
				end
				if workspace.CurrentCamera then
					table.insert(exclude, workspace.CurrentCamera)
				end
				params.FilterDescendantsInstances = exclude
				-- A pie: quien te roza. En coche: quien está delante, un poco más lejos
				local center = root.Position
				local radius = 3.2
				if car then
					center += Vector3.new(v.X, 0, v.Z).Unit * 4
					radius = 7
				end
				local seen: { [Model]: boolean } = {}
				for _, part in workspace:GetPartBoundsInRadius(center, radius, params) do
					local model = npcOf(part)
					if model and not seen[model] then
						seen[model] = true
						react(model, root.Position, car)
					end
				end
				for model, untilT in recent do
					if untilT < os.clock() or not model.Parent then
						recent[model] = nil
					end
				end
			end)
			if not ok then
				warn("[Nudge] " .. tostring(err))
			end
		end
	end)
end

return Nudge
