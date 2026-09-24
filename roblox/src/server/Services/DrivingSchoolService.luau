-- DrivingSchoolService: la autoescuela (tag DrivingSchool, atributo Town).
--   1) Eliges carnet (moto A o coche B) y lo pagas.
--   2) Examen teórico: 5 preguntas de tráfico, hay que acertar 4.
--   3) Examen práctico: conduces por las calles del pueblo pasando por 5 puntos antes de que acabe el tiempo.
--      Si te bajas del vehículo o se acaba el tiempo, suspendes.
-- Al aprobar, el carnet se guarda (data.Licenses) y ya puedes conducir tu moto o tu coche.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local Region = require(script.Parent.Parent.World.Region)
local DataService = require(script.Parent.DataService)
local JobService = require(script.Parent.JobService)
local VehicleService = require(script.Parent.VehicleService)
local RestaurantService = require(script.Parent.RestaurantService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local DrivingSchoolService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.DrivingSchool :: RemoteEvent

type Session = {
	Token: string,
	License: string?,
	Phase: "Menu" | "Theory" | "Practical",
	Center: Vector3,
	School: Vector3,
	Correct: { number }?,
	Checkpoints: { Vector3 }?,
	Index: number,
	Deadline: number,
	Marker: BasePart?,
}
local sessions: { [Player]: Session } = {}

-- Vuelta al pueblo por la calle de circunvalación (a 240 studs del centro)
local RING = { { -240, -240 }, { 0, -240 }, { 240, -240 }, { 240, 0 }, { 240, 240 }, { 0, 240 }, { -240, 240 }, { -240, 0 } }

local function townCenter(name: string?, fallback: Vector3): Vector3
	for _, town in Region.Towns do
		if town.Name == name then
			return town.Center
		end
	end
	return fallback
end

local function shuffle<T>(list: { T }): { T }
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function clearTarget(player: Player)
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("ActivityText", nil)
end

local function finish(player: Player, passed: boolean, reason: string?)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if session.Marker then
		session.Marker:Destroy()
	end
	clearTarget(player)
	if session.Phase == "Practical" then
		VehicleService.dismount(player, true)
	end
	local license = session.License and Gameplay.Licenses[session.License]
	if passed and license and session.License then
		VehicleService.grantLicense(player, session.License)
		Notify:FireClient(player, "Success", "🎉 ¡APROBADO! Ya tienes el " .. license.Name .. ".")
		StoryEvents.emit(player, "LicenseEarned", { License = session.License })
	elseif reason then
		Notify:FireClient(player, "Error", "Suspenso: " .. reason)
		StoryEvents.emit(player, "LicenseFailed", { License = session.License })
	end
end

local function placeMarker(session: Session, player: Player)
	local points = session.Checkpoints :: { Vector3 }
	local point = points[session.Index]
	if not session.Marker then
		session.Marker = Builder.part({
			Name = "ExamCheckpoint_" .. player.UserId,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 22, 22),
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Neon,
			Transparency = 0.45,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Parent = workspace,
		})
	end
	(session.Marker :: BasePart).CFrame = CFrame.new(point) * CFrame.Angles(0, 0, math.rad(90))
	player:SetAttribute("TaskTarget", point)
end

local function startPractical(player: Player, session: Session)
	local license = Gameplay.Licenses[session.License :: string]
	session.Phase = "Practical"
	-- Punto de la circunvalación más cercano a la autoescuela y los siguientes en orden
	local nearest, best = 1, math.huge
	for i, p in RING do
		local d = (Vector3.new(session.Center.X + p[1], 0, session.Center.Z + p[2]) - Vector3.new(session.School.X, 0, session.School.Z)).Magnitude
		if d < best then
			nearest, best = i, d
		end
	end
	local points = {}
	for k = 0, Gameplay.Practical.Checkpoints - 1 do
		local p = RING[(nearest - 1 + k) % #RING + 1]
		table.insert(points, Vector3.new(session.Center.X + p[1], 1, session.Center.Z + p[2]))
	end
	session.Checkpoints = points
	session.Index = 1
	session.Deadline = os.clock() + Gameplay.Practical.Seconds
	if not VehicleService.mount(player, license.Vehicle, { Exam = true }) then
		sessions[player] = nil
		DataService.addMoney(player, license.Price) -- no ha podido empezar: se devuelve el dinero
		Notify:FireClient(player, "Error", "No se ha podido empezar el examen práctico. Te devolvemos el dinero.")
		return
	end
	placeMarker(session, player)
	Notify:FireClient(player, "Success", "¡Teórico aprobado! Examen práctico: pasa por los puntos amarillos.")
end

local function startTheory(player: Player, session: Session, licenseKey: string)
	local license = Gameplay.Licenses[licenseKey]
	local data = DataService.get(player)
	if not license or not data then
		sessions[player] = nil
		return
	end
	if VehicleService.hasLicense(player, licenseKey) then
		sessions[player] = nil
		Notify:FireClient(player, "Info", "Ya tienes el " .. license.Name .. ".")
		return
	end
	if not DataService.spend(player, license.Price) then
		sessions[player] = nil
		Notify:FireClient(player, "Error", "Necesitas " .. Format.money(license.Price) .. " para la matrícula.")
		return
	end
	JobService.quit(player, true)
	RestaurantService.quit(player, true)
	session.License = licenseKey
	session.Phase = "Theory"
	local pool = table.clone(Gameplay.TheoryQuestions)
	shuffle(pool)
	local questions, correct = {}, {}
	for i = 1, math.min(Gameplay.Theory.Questions, #pool) do
		local q = pool[i]
		local order = shuffle({ 1, 2, 3 })
		local options = {}
		for k, index in order do
			options[k] = q[2][index]
			if index == 1 then
				correct[i] = k
			end
		end
		table.insert(questions, { Text = q[1], Options = options })
	end
	session.Correct = correct
	Remote:FireClient(player, "Theory", session.Token, { License = license.Name, Questions = questions, ToPass = Gameplay.Theory.ToPass })
end

local function gradeTheory(player: Player, session: Session, answers: any)
	if typeof(answers) ~= "table" then
		return
	end
	local correct = session.Correct or {}
	local right = 0
	for i, answer in correct do
		if answers[i] == answer then
			right += 1
		end
	end
	if right >= Gameplay.Theory.ToPass then
		startPractical(player, session)
	else
		finish(player, false, ("%d de %d respuestas bien en el teórico (necesitas %d)."):format(right, #correct, Gameplay.Theory.ToPass))
	end
end

local function setupSchool(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local prompt = Builder.prompt(part, "Sacarse el carnet", "Autoescuela", 0.3)
	prompt.Triggered:Connect(function(player)
		if sessions[player] then
			Notify:FireClient(player, "Info", "Ya estás haciendo un examen.")
			return
		end
		if not Stages.allows(player:GetAttribute("LifeStage"), "License", { License = Gameplay.LicenseStage }) then
			Notify:FireClient(player, "Error", "Para sacarte el carnet tienes que ser mayor de edad.")
			return
		end
		local session: Session = {
			Token = HttpService:GenerateGUID(false),
			Phase = "Menu",
			Center = townCenter(part:GetAttribute("Town"), part.Position),
			School = part.Position,
			Index = 0,
			Deadline = 0,
		}
		sessions[player] = session
		local menu = {}
		for key, license in Gameplay.Licenses do
			table.insert(menu, { Key = key, Name = license.Name, Price = license.Price, Owned = VehicleService.hasLicense(player, key) })
		end
		table.sort(menu, function(a, b)
			return a.Key < b.Key
		end)
		Remote:FireClient(player, "Menu", session.Token, menu)
	end)
end

function DrivingSchoolService.init()
	for _, part in CollectionService:GetTagged("DrivingSchool") do
		setupSchool(part)
	end
	CollectionService:GetInstanceAddedSignal("DrivingSchool"):Connect(setupSchool)

	Remote.OnServerEvent:Connect(function(player, action, token, value)
		local session = sessions[player]
		if not session or session.Token ~= token then
			return
		end
		if action == "Choose" and session.Phase == "Menu" then
			if typeof(value) == "string" and Gameplay.Licenses[value] then
				startTheory(player, session, value)
			else
				sessions[player] = nil -- ha cancelado
			end
		elseif action == "Answers" and session.Phase == "Theory" then
			gradeTheory(player, session, value)
		end
	end)

	VehicleService.onDismount(function(player)
		local session = sessions[player]
		if session and session.Phase == "Practical" then
			finish(player, false, "te has bajado del vehículo durante el examen.")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			sessions[player] = nil
			if session.Marker then
				session.Marker:Destroy()
			end
		end
	end)

	-- Comprobar los puntos del examen práctico
	task.spawn(function()
		while true do
			task.wait(0.2)
			for player, session in sessions do
				if session.Phase == "Practical" and session.Checkpoints then
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local left = session.Deadline - os.clock()
					if left <= 0 then
						finish(player, false, "se ha acabado el tiempo.")
					elseif root then
						local target = session.Checkpoints[session.Index]
						local offset = root.Position - target
						if Vector3.new(offset.X, 0, offset.Z).Magnitude <= Gameplay.Practical.ReachDistance then
							session.Index += 1
							if session.Index > #session.Checkpoints then
								finish(player, true)
								continue
							end
							placeMarker(session, player)
						end
						player:SetAttribute("ActivityText", ("🚦 Examen práctico · punto %d de %d · %d s"):format(session.Index, #session.Checkpoints, math.ceil(left)))
					end
				end
			end
		end
	end)
end

return DrivingSchoolService
