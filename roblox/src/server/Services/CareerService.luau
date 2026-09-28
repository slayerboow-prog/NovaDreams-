-- CareerService: la carrera en las instituciones del Estado (shared/Institutions).
--
--   * Oficios nuevos de la Ciudad de la Justicia (tablón "Trabajar" de cada edificio):
--       Juez/a (Palacio de Justicia), Funcionario/a de prisiones (Centro Penitenciario),
--       Militar (Cuartel) y Agente de Hacienda (Agencia Tributaria).
--     Tareas con recoger y entregar (JobService) con textos propios; los juicios, las
--     declaraciones y las inspecciones los llevan JusticeService y TaxService.
--   * Puntos de servicio por cada tarea, caso, detención… y ascensos automáticos por rango.
--     Cada rango cobra un plus sobre el sueldo (también la policía, que ya tenía su oficio).
--   * Uniforme con el color y el nombre de la institución mientras estás de servicio.
--   * Atributos del jugador para la interfaz: Rank (nombre del rango), RankInst, Chief (rango
--     más alto) y Career_<Institución> (puntos).
-- Los puntos se guardan en data.Careers.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Institutions = require(ReplicatedStorage.Shared.Institutions)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local JobService = require(script.Parent.JobService)

local CareerService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local uniforms: { [Player]: Folder } = {}

local function careers(player: Player): { [string]: { Points: number } }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	data.Careers = data.Careers or {}
	return data.Careers
end

function CareerService.points(player: Player, instId: string): number
	local list = careers(player)
	local entry = list and list[instId]
	return entry and entry.Points or 0
end

-- Rango actual en una institución
function CareerService.rank(player: Player, instId: string): (number, Institutions.Rank?)
	local inst = Institutions.List[instId]
	if not inst then
		return 0, nil
	end
	return Institutions.rankFor(inst, CareerService.points(player, instId))
end

function CareerService.isChief(player: Player, instId: string): boolean
	local inst = Institutions.List[instId]
	return inst ~= nil and Institutions.isTop(inst, CareerService.points(player, instId))
end

-- Pone en el jugador lo que enseña la interfaz (rango del oficio que tiene ahora)
local function refreshAttributes(player: Player)
	for id in Institutions.List do
		player:SetAttribute("Career_" .. id, CareerService.points(player, id))
	end
	local inst = Institutions.byJob(player:GetAttribute("Job"))
	if inst then
		local index, rank = CareerService.rank(player, inst.Id)
		player:SetAttribute("Rank", rank and rank.Name)
		player:SetAttribute("RankInst", inst.Id)
		player:SetAttribute("Chief", if index == #inst.Ranks then inst.Id else nil)
	else
		player:SetAttribute("Rank", nil)
		player:SetAttribute("RankInst", nil)
		player:SetAttribute("Chief", nil)
	end
end

-- Suma puntos de servicio (reason = clave de inst.Points: Task, Case, Arrest…); avisa si asciende
function CareerService.addPoints(player: Player, instId: string, reason: string, amount: number?)
	local inst = Institutions.List[instId]
	local list = careers(player)
	if not inst or not list then
		return
	end
	local add = amount or inst.Points[reason] or 0
	if add <= 0 then
		return
	end
	local entry = list[instId] or { Points = 0 }
	list[instId] = entry
	local before = Institutions.rankFor(inst, entry.Points)
	entry.Points += add
	local after, rank = Institutions.rankFor(inst, entry.Points)
	if after > before then
		Remote:FireClient(player, "Promotion", { Institution = inst.Name, Rank = rank.Name, Chief = after == #inst.Ranks, Icon = inst.Icon })
		StoryEvents.emit(player, "Promoted", { Institution = instId, Rank = rank.Id })
	end
	refreshAttributes(player)
end

---------------------------------------------------------------------
-- Uniformes (la policía tiene el suyo en PoliceService)
---------------------------------------------------------------------
local UNIFORM = {
	Juez = { Body = Color3.fromRGB(20, 20, 24), Trim = Color3.fromRGB(240, 240, 240), Text = "JUSTICIA", Hat = false, Robe = true },
	Funcionario = { Body = Color3.fromRGB(70, 90, 110), Trim = Color3.fromRGB(230, 230, 230), Text = "PRISIONES", Hat = true },
	Militar = { Body = Color3.fromRGB(86, 100, 62), Trim = Color3.fromRGB(60, 72, 44), Text = "EJÉRCITO", Hat = true, Beret = true },
	Hacienda = { Body = Color3.fromRGB(30, 60, 80), Trim = Color3.fromRGB(230, 200, 90), Text = "HACIENDA", Hat = false },
}

local function removeUniform(player: Player)
	if uniforms[player] then
		uniforms[player]:Destroy()
		uniforms[player] = nil
	end
end

local function dress(player: Player)
	removeUniform(player)
	local style = UNIFORM[player:GetAttribute("Job") or ""]
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not style or not head or not torso then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "InstitutionUniform"
	local function piece(to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.Fabric
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = to.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = to
		weld.Part1 = p
		weld.Parent = p
		p.Parent = folder
		return p
	end
	local h, t = head.Size, torso.Size
	if style.Robe then
		-- Toga negra con puñetas blancas
		piece(torso, "Toga", Vector3.new(t.X * 1.12, t.Y * 1.25, t.Z * 1.18), CFrame.new(0, -t.Y * 0.1, 0), style.Body)
		piece(torso, "Collar", Vector3.new(t.X * 0.5, t.Y * 0.14, t.Z * 1.2), CFrame.new(0, t.Y * 0.45, 0), style.Trim)
	else
		piece(torso, "Jacket", Vector3.new(t.X * 1.06, t.Y * 0.98, t.Z * 1.12), CFrame.new(0, -t.Y * 0.01, 0), style.Body)
		piece(torso, "Belt", Vector3.new(t.X * 1.08, t.Y * 0.1, t.Z * 1.14), CFrame.new(0, -t.Y * 0.42, 0), style.Trim, Enum.Material.SmoothPlastic)
	end
	if style.Hat then
		if style.Beret then
			piece(head, "Beret", Vector3.new(h.X * 1.1, h.Y * 0.28, h.Z * 1.1), CFrame.new(-h.X * 0.05, h.Y * 0.48, 0) * CFrame.Angles(0, 0, math.rad(-8)), style.Body)
		else
			piece(head, "Cap", Vector3.new(h.X * 1.1, h.Y * 0.35, h.Z * 1.1), CFrame.new(0, h.Y * 0.45, 0), style.Body)
			piece(head, "CapPeak", Vector3.new(h.X * 0.9, 0.08, h.Z * 0.45), CFrame.new(0, h.Y * 0.3, -h.Z * 0.62), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
		end
	end
	piece(torso, "Badge", Vector3.new(t.X * 0.14, t.X * 0.16, 0.05), CFrame.new(-t.X * 0.28, t.Y * 0.22, -t.Z * 0.62), Color3.fromRGB(250, 200, 40), Enum.Material.Metal)
	local back = piece(torso, "BackLabel", Vector3.new(t.X * 0.8, t.Y * 0.3, 0.05), CFrame.new(0, t.Y * 0.15, t.Z * 0.62), style.Body)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(220, 60)
	gui.Parent = back
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = style.Text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(250, 250, 250)
	label.Parent = gui
	folder.Parent = character
	uniforms[player] = folder
end

---------------------------------------------------------------------
-- Tareas de los oficios nuevos (circuito de JobService con sus propios puntos)
---------------------------------------------------------------------
local function pick(tag: string, avoid: BasePart?): BasePart?
	local list = CollectionService:GetTagged(tag)
	if #list > 1 and avoid then
		local index = table.find(list, avoid)
		if index then
			table.remove(list, index)
		end
	end
	return if #list > 0 then list[math.random(1, #list)] else nil
end

local function canJoin(player: Player, inst: Institutions.Institution): boolean
	local stage = player:GetAttribute("LifeStage")
	if stage and not Stages.inRange(stage, inst.MinStage, nil) then
		Notify:FireClient(player, "Error", ("Para trabajar en %s hay que ser mayor."):format(inst.Name))
		return false
	end
	if player:GetAttribute("Wanted") then
		Notify:FireClient(player, "Error", "Con la policía buscándote no te van a contratar.")
		return false
	end
	if player:GetAttribute("JailUntil") then
		Notify:FireClient(player, "Error", "Primero cumple tu condena.")
		return false
	end
	return true
end

local TEXTS = {
	Juez = function(phase: string, target: BasePart?)
		return if phase == "Pickup" then "⚖ Recoge un expediente del archivo" else "⚖ Estúdialo y firma el auto en el estrado"
	end,
	Funcionario = function(phase: string, target: BasePart?)
		if phase == "Pickup" then
			return "⛓ Recoge las llaves y el parte en la garita"
		end
		return if target and target.Name == "TowerPost" then "⛓ Ronda: sube a vigilar desde la torre marcada" else "⛓ Recuento: revisa la celda marcada"
	end,
	Militar = function(phase: string, target: BasePart?)
		if phase == "Pickup" then
			return "🎖 Recoge tu equipo en la armería"
		end
		if target and target.Name == "GuardPost" then
			return "🎖 Guardia: cubre la garita de la entrada"
		end
		return ("🎖 Instrucción: llega al puesto %d del circuito"):format(target and target:GetAttribute("Step") or 1)
	end,
	Hacienda = function(phase: string, target: BasePart?)
		return if phase == "Pickup" then "🏛 Recoge un expediente fiscal del archivo" else "🏛 Tramítalo en una mesa de la oficina"
	end,
}

local function registerJob(inst: Institutions.Institution)
	local jobId = inst.JobId
	local texts = TEXTS[jobId]
	JobService.setProvider(jobId, {
		Start = function(player)
			return canJoin(player, inst)
		end,
		Pickup = function(_, shift)
			return pick("Pickup_" .. jobId, shift and shift.Target)
		end,
		Dropoff = function(_, shift)
			return pick("Dropoff_" .. jobId, shift and shift.Target)
		end,
		Text = function(_, shift)
			return texts and texts(shift.Phase, shift.Target)
		end,
	})
end

function CareerService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Career") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Career"
		Remote.Parent = remotes
	end
	for _, inst in Institutions.List do
		if inst.JobId ~= "Policia" then
			registerJob(inst)
		end
	end

	-- Cada tarea hecha en una institución: puntos de servicio y el plus del rango
	StoryEvents.connect(function(player: Player, name: string, payload: { [string]: any })
		if name ~= "JobTaskDone" then
			return
		end
		local inst = Institutions.byJob(payload.JobId)
		if not inst then
			return
		end
		local pay = tonumber(payload.Pay) or 0
		local bonus = Institutions.pay(inst, CareerService.points(player, inst.Id), pay) - pay
		if bonus > 0 then
			DataService.addMoney(player, bonus, true)
			Notify:FireClient(player, "Money", ("+%s (plus de %s)"):format(Format.money(bonus), player:GetAttribute("Rank") or "rango"))
		end
		CareerService.addPoints(player, inst.Id, "Task")
	end)

	local function watch(player: Player)
		player:GetAttributeChangedSignal("Job"):Connect(function()
			refreshAttributes(player)
			dress(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.5)
			dress(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(removeUniform)
	DataService.onLoaded(function(player)
		refreshAttributes(player)
	end)
end

return CareerService
