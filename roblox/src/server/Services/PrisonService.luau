-- PrisonService: la vida dentro del Centro Penitenciario (el recinto: World/Kit/Prison; las condenas:
-- JusticeService). Hay mucho que hacer mientras cumples tu condena:
--
--   Trabajos (lavandería, cocina, carpintería, huerto, limpiar el patio): cobras un poco (peculio)
--     y la condena baja unos segundos.
--   Deporte: gimnasio, pesas, saco, cinta, canasta y partido de fútbol (minijuegos) -> experiencia.
--   Biblioteca: leer (un poco menos de condena) y estudiar el graduado en prisión (6 lecciones:
--     te lo sacas y la condena baja bastante).
--   Comedor, economato, enfermería, sala de TV, capilla, teléfono y dormir en tu litera.
--   Túnel: en el rincón de cada celda se puede cavar a escondidas (25 veces). Si lo terminas, te
--     escapas… con 3 estrellas y la alarma sonando. Un funcionario de servicio puede REGISTRAR a un
--     preso: si tiene túnel, se tapa y le suben la condena.
--   Pelearse dentro: más condena y a aislamiento un rato.
--   Uniforme naranja mientras estás preso.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Justice = require(ReplicatedStorage.Shared.Justice)
local Format = require(ReplicatedStorage.Shared.Format)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local JusticeService = require(script.Parent.JusticeService)
local WantedService = require(script.Parent.WantedService)
local CareerService = require(script.Parent.CareerService)
local NeedsService = require(script.Parent.NeedsService)
local ProgressionService = require(script.Parent.ProgressionService)
local MiniGameService = require(script.Parent.MiniGameService)
local SceneService = require(script.Parent.SceneService)

local PrisonService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local cooldowns: { [Player]: { [string]: number } } = {}
local isolated: { [Player]: number } = {}
local searchedAt: { [Player]: number } = {}
local uniforms: { [Player]: Folder } = {}

local WORK = { Lavanderia = "Lavandería", Cocina = "Cocina", Carpinteria = "Carpintería", Huerto = "Huerto", Limpiar = "Limpieza del patio" }
local PECULIO = 4 -- lo que se cobra por un trabajo dentro
local CALLS = {
	"Tu madre te dice que te echa de menos y que te portes bien.",
	"Tu amigo te cuenta las novedades del barrio. Te anima a salir pronto.",
	"Tu hermano te promete venir a verte a la sala de visitas.",
	"Tu abuela te recuerda que nunca es tarde para cambiar.",
}

local function say(player: Player, kind: string, text: string)
	Notify:FireClient(player, kind, text)
end

-- ¿Puede hacerlo ya? (cada actividad tiene su tiempo de espera)
local function ready(player: Player, key: string, seconds: number): boolean
	local list = cooldowns[player] or {}
	cooldowns[player] = list
	local last = list[key]
	if last and os.clock() - last < seconds then
		say(player, "Error", ("Espera %d s para volver a hacerlo."):format(math.ceil(seconds - (os.clock() - last))))
		return false
	end
	list[key] = os.clock()
	return true
end

local function reduce(player: Player, seconds: number, why: string)
	local left = JusticeService.adjust(player, -seconds)
	say(player, "Success", ("%s · -%d s de condena (quedan %d:%02d)"):format(why, seconds, left // 60, left % 60))
end

local function timing(player: Player, title: string, icon: string, rounds: number, need: number, speed: number, onWin: () -> ())
	local started = MiniGameService.start(player, { Game = "Timing", Title = title, Icon = icon, Rounds = rounds, Need = need, Speed = speed, Zone = 0.24 }, function(result)
		if result.Won then
			onWin()
		else
			say(player, "Info", "Casi… inténtalo otra vez.")
		end
	end)
	if not started then
		say(player, "Error", "Termina lo que estás haciendo primero.")
	end
end

---------------------------------------------------------------------
-- Actividades
---------------------------------------------------------------------
local ACTIONS: { [string]: (Player, BasePart) -> () } = {}

for kind, name in WORK do
	ACTIONS[kind] = function(player)
		if not ready(player, "Work", Justice.WorkCooldown) then
			return
		end
		DataService.addMoney(player, PECULIO, true)
		ProgressionService.addXp(player, 3, "PrisonWork")
		reduce(player, Justice.WorkReduction, ("🧺 %s: +%s"):format(name, Format.money(PECULIO)))
		StoryEvents.emit(player, "PrisonWork", { Work = kind })
	end
end

ACTIONS.Comer = function(player)
	if ready(player, "Comer", 90) then
		NeedsService.change(player, 40, 5)
		say(player, "Success", "🍲 Has comido en el comedor: lentejas y un yogur.")
	end
end

ACTIONS.Economato = function(player)
	if not ready(player, "Economato", 20) then
		return
	end
	if DataService.spend(player, 10) then
		NeedsService.change(player, 25, 10)
		say(player, "Success", "🛒 Economato: bocadillo y refresco (10 €).")
	else
		say(player, "Error", "No tienes 10 €. Trabaja en los talleres para ganar peculio.")
	end
end

ACTIONS.Curarse = function(player)
	if not ready(player, "Curarse", 60) then
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	say(player, "Success", "🏥 La enfermera te ha curado.")
end

ACTIONS.Leer = function(player)
	if ready(player, "Leer", 25) then
		ProgressionService.addXp(player, 6, "PrisonRead")
		reduce(player, 5, "📖 Has leído un capítulo")
	end
end

ACTIONS.Estudiar = function(player)
	local jail = JusticeService.jailData(player)
	if not jail or not ready(player, "Estudiar", 30) then
		return
	end
	if (jail.Course or 0) >= Justice.CourseLessons then
		say(player, "Info", "🎓 Ya tienes el graduado. Puedes seguir leyendo en la biblioteca.")
		return
	end
	timing(player, "Lección del graduado", "🎓", 3, 2, 1, function()
		local now = JusticeService.jailData(player)
		if not now then
			return
		end
		now.Course = (now.Course or 0) + 1
		ProgressionService.addXp(player, 10, "PrisonStudy")
		if now.Course >= Justice.CourseLessons then
			ProgressionService.addXp(player, 80, "PrisonDegree")
			reduce(player, Justice.CourseReduction, "🎓 ¡Te has sacado el graduado en prisión!")
			StoryEvents.emit(player, "PrisonDegree", {})
		else
			say(player, "Success", ("🎓 Lección aprobada (%d/%d)"):format(now.Course, Justice.CourseLessons))
		end
	end)
end

local function sport(title: string, icon: string, rounds: number, need: number, speed: number, xp: number, cut: number)
	return function(player: Player)
		if not ready(player, "Deporte", 15) then
			return
		end
		timing(player, title, icon, rounds, need, speed, function()
			ProgressionService.addXp(player, xp, "PrisonSport")
			NeedsService.change(player, -3, -5)
			if cut > 0 then
				reduce(player, cut, icon .. " Buen entrenamiento")
			else
				say(player, "Success", icon .. " ¡Bien hecho! +" .. xp .. " XP")
			end
		end)
	end
end
ACTIONS.Gimnasio = sport("Levanta las pesas", "🏋", 4, 2, 1.1, 10, 5)
ACTIONS.Pesas = sport("Pesas del patio", "🏋", 4, 2, 1.1, 10, 5)
ACTIONS.Saco = sport("Golpea el saco", "🥊", 5, 3, 1.3, 10, 5)
ACTIONS.Cinta = sport("Mantén el ritmo", "🏃", 4, 2, 1, 8, 5)
ACTIONS.Canasta = sport("Tira a canasta", "🏀", 5, 3, 1.2, 8, 0)

ACTIONS.Futbol = function(player)
	if not ready(player, "Futbol", 60) then
		return
	end
	local started = MiniGameService.start(player, { Game = "Futbol", Plays = 6, Rival = "Recluso", Position = "Delantero" }, function(result)
		ProgressionService.addXp(player, if result.Won then 20 else 8, "PrisonFootball")
		if result.Won then
			reduce(player, 20, "⚽ ¡Has ganado el partido del patio!")
		else
			say(player, "Info", "⚽ Esta vez ganaron los del Módulo B.")
		end
	end)
	if not started then
		say(player, "Error", "Termina lo que estás haciendo primero.")
	end
end

ACTIONS.TV = function(player)
	if ready(player, "TV", 60) then
		NeedsService.change(player, 0, 10)
		say(player, "Success", "📺 Has visto las noticias un rato: +10 de energía.")
	end
end

ACTIONS.Reflexionar = function(player)
	if ready(player, "Reflexionar", 60) then
		reduce(player, 5, "🕯 Has reflexionado sobre lo que hiciste")
	end
end

ACTIONS.Telefono = function(player)
	if ready(player, "Telefono", 120) then
		NeedsService.change(player, 0, 5)
		say(player, "Info", "📞 " .. CALLS[math.random(1, #CALLS)])
	end
end

ACTIONS.Dormir = function(player)
	if ready(player, "Dormir", 90) then
		NeedsService.change(player, 0, 30)
		say(player, "Success", "🛏 Has echado una siesta en la litera: +30 de energía.")
	end
end

-- Túnel de fuga
ACTIONS.Cavar = function(player)
	local jail = JusticeService.jailData(player)
	if not jail or not ready(player, "Cavar", 10) then
		return
	end
	jail.Tunnel = math.min(100, (jail.Tunnel or 0) + Justice.TunnelStep)
	player:SetAttribute("Tunnel", jail.Tunnel)
	if jail.Tunnel < 100 then
		say(player, "Info", ("🕳 Cavas en silencio… túnel al %d%%. Que no te pille un funcionario."):format(jail.Tunnel))
		return
	end
	-- ¡Fuga!
	local exit = CollectionService:GetTagged("PrisonTunnelExit")[1] :: BasePart?
	JusticeService.release(player, "Te has fugado por el túnel")
	if exit then
		SceneService.teleportTo(player, exit.Position)
	end
	player:SetAttribute("Tunnel", nil)
	say(player, "Error", "🚨 ¡Te has fugado! Suena la alarma de la prisión.")
	task.delay(1, function()
		WantedService.crime(player, "Fuga", exit and exit.Position, { Alarm = true })
	end)
	StoryEvents.emit(player, "PrisonEscape", {})
end

local function setup(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChild("PrisonPrompt") then
		return
	end
	local kind = part:GetAttribute("Activity")
	local action = ACTIONS[kind or ""]
	if not action then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PrisonPrompt"
	prompt.ActionText = if WORK[kind] then "Trabajar" elseif kind == "Cavar" then "Cavar" else "Usar"
	prompt.ObjectText = part:GetAttribute("Label") or kind
	prompt.HoldDuration = if WORK[kind] then 2.5 elseif kind == "Cavar" then 3 else 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JailedOnly", true) -- (solo los presos; JobPrompts)
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if not JusticeService.isJailed(player) then
			return
		end
		action(player, part)
	end)
end

---------------------------------------------------------------------
-- Funcionarios: registrar a un preso
---------------------------------------------------------------------
local function search(guard: Player, target: any)
	if guard:GetAttribute("Job") ~= "Funcionario" or typeof(target) ~= "Instance" or not target:IsA("Player") or not JusticeService.isJailed(target) then
		return
	end
	local a = guard.Character and guard.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local b = target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not a or not b or (a.Position - b.Position).Magnitude > 10 then
		return
	end
	if os.clock() - (searchedAt[target] or -math.huge) < 60 then
		say(guard, "Info", target.DisplayName .. " ya ha sido registrado hace poco.")
		return
	end
	searchedAt[target] = os.clock()
	local jail = JusticeService.jailData(target)
	if jail and (jail.Tunnel or 0) > 0 then
		jail.Tunnel = 0
		target:SetAttribute("Tunnel", nil)
		JusticeService.adjust(target, Justice.TunnelPenalty)
		say(target, "Error", ("🔦 %s ha encontrado tu túnel: tapado y +%d s de condena."):format(guard.DisplayName, Justice.TunnelPenalty))
		say(guard, "Success", "🔦 ¡Túnel encontrado y tapado!")
		DataService.addMoney(guard, 20, true)
		CareerService.addPoints(guard, "Prisiones", "Inmate", 8)
	else
		say(target, "Info", ("🔦 %s te ha registrado. Todo en orden."):format(guard.DisplayName))
		say(guard, "Info", "🔦 Registro sin novedad.")
		CareerService.addPoints(guard, "Prisiones", "Inmate", 1)
	end
end

---------------------------------------------------------------------
-- Uniforme naranja
---------------------------------------------------------------------
local function removeUniform(player: Player)
	if uniforms[player] then
		uniforms[player]:Destroy()
		uniforms[player] = nil
	end
end

local function dress(player: Player)
	removeUniform(player)
	if not JusticeService.isJailed(player) then
		return
	end
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not torso then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PrisonUniform"
	local function piece(to: BasePart?, name: string, scale: Vector3)
		if not to then
			return
		end
		local p = Instance.new("Part")
		p.Name = name
		p.Size = to.Size * scale
		p.Color = Color3.fromRGB(235, 120, 30)
		p.Material = Enum.Material.Fabric
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = to.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = to
		weld.Part1 = p
		weld.Parent = p
		p.Parent = folder
	end
	piece(torso, "Jumpsuit", Vector3.new(1.08, 1.02, 1.14))
	for _, name in { "LeftUpperLeg", "RightUpperLeg", "LeftUpperArm", "RightUpperArm", "Left Leg", "Right Leg", "Left Arm", "Right Arm" } do
		piece(character:FindFirstChild(name) :: BasePart?, "Jumpsuit", Vector3.new(1.12, 1.02, 1.12))
	end
	folder.Parent = character
	uniforms[player] = folder
end

---------------------------------------------------------------------
-- Peleas dentro: más condena y a aislamiento
---------------------------------------------------------------------
-- A una celda de aislamiento (sin tocar el tiempo que le queda)
local function toIsolation(player: Player): boolean
	local cells = CollectionService:GetTagged("PrisonIsolation")
	if #cells == 0 then
		return false
	end
	local cell = cells[math.random(1, #cells)] :: BasePart
	SceneService.teleportTo(player, cell.Position)
	return true
end

-- Una pelea nueva: empieza el tiempo de aislamiento
local function isolate(player: Player)
	if #CollectionService:GetTagged("PrisonIsolation") == 0 then
		return
	end
	isolated[player] = os.clock() + Justice.IsolationSeconds
	player:SetAttribute("Isolated", true)
	toIsolation(player)
end

-- Si está en aislamiento, de vuelta a su celda de aislamiento (al reaparecer; HospitalService)
function PrisonService.sendToIsolation(player: Player): boolean
	return isolated[player] ~= nil and JusticeService.isJailed(player) and toIsolation(player)
end

function PrisonService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Prison") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Prison"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, target: any)
		if kind == "Search" then
			search(player, target)
		end
	end)

	for _, part in CollectionService:GetTagged("PrisonActivity") do
		setup(part)
	end
	CollectionService:GetInstanceAddedSignal("PrisonActivity"):Connect(setup)

	StoryEvents.connect(function(player: Player, name: string, payload: { [string]: any })
		if name == "HitSomeone" and JusticeService.isJailed(player) and (payload.Target or payload.Model) then
			JusticeService.adjust(player, Justice.FightPenalty)
			say(player, "Error", ("⛓ Pelea en prisión: +%d s de condena y a aislamiento."):format(Justice.FightPenalty))
			isolate(player)
		end
	end)

	local function watch(player: Player)
		player:GetAttributeChangedSignal("JailUntil"):Connect(function()
			dress(player)
			if not player:GetAttribute("JailUntil") then
				isolated[player] = nil
				player:SetAttribute("Isolated", nil)
				player:SetAttribute("Tunnel", nil)
			else
				local jail = JusticeService.jailData(player)
				player:SetAttribute("Tunnel", jail and jail.Tunnel ~= 0 and jail.Tunnel or nil)
			end
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.6)
			dress(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		isolated[player] = nil
		searchedAt[player] = nil
		removeUniform(player)
	end)

	-- Aislamiento: no se puede salir de la celda hasta que pase el tiempo
	task.spawn(function()
		while true do
			task.wait(1)
			for player, untilTime in isolated do
				if os.clock() >= untilTime or not JusticeService.isJailed(player) then
					isolated[player] = nil
					player:SetAttribute("Isolated", nil)
					if JusticeService.isJailed(player) then
						say(player, "Info", "⛓ Se acabó el aislamiento. Vuelves al módulo.")
						JusticeService.sendToCell(player)
					end
				else
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local nearest = math.huge
					for _, cell in CollectionService:GetTagged("PrisonIsolation") do
						if root then
							nearest = math.min(nearest, (root.Position - (cell :: BasePart).Position).Magnitude)
						end
					end
					if root and nearest > 12 then
						toIsolation(player) -- (solo volver: el tiempo no se reinicia)
					end
				end
			end
		end
	end)
end

return PrisonService
