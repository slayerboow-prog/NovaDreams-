-- JobService: trabajos. Cada trabajo es un bucle:
--   1) ir al punto de recogida (Pickup_<Trabajo>)  -> el personaje coge el objeto
--   2) llevarlo al punto de entrega (Dropoff_<Trabajo>) -> cobras
--
-- El servidor comprueba la distancia (no se fía del cliente) y le pasa al
-- cliente el objetivo actual con atributos: "Job", "TaskTarget", "TaskText".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoleService = require(script.Parent.RoleService)
local LifeService = require(script.Parent.LifeService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local JobService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

type Shift = {
	JobId: string,
	Phase: "Pickup" | "Dropoff",
	Target: BasePart,
	Carry: BasePart?,
	Context: any?, -- lo que necesite su proveedor (p. ej. en qué supermercado trabaja)
}
local shifts: { [Player]: Shift } = {}

-- Trabajos con sus propios puntos (el reponedor repone SU supermercado, no uno al azar):
--   Pickup(player, shift) -> BasePart?   Dropoff(player, shift) -> BasePart?   Done(player, shift)
export type Provider = {
	Pickup: (Player, any) -> BasePart?,
	Dropoff: (Player, any) -> BasePart?,
	Done: ((Player, any) -> ())?,
}
local providers: { [string]: Provider } = {}

function JobService.setProvider(jobId: string, provider: Provider)
	providers[jobId] = provider
end

-- Oficios con su propio sistema (el barista de CafeService): el tablón "Trabajar" y el botón de
-- dejar el trabajo llaman a Start/Quit de ese sistema en vez de al circuito de recoger y entregar.
export type Handler = { Start: (Player) -> (), Quit: (Player, boolean?) -> () }
local handlers: { [string]: Handler } = {}

function JobService.setHandler(jobId: string, handler: Handler)
	handlers[jobId] = handler
end

function JobService.shiftOf(player: Player): Shift?
	return shifts[player]
end

local function pickTarget(tag: string, avoid: BasePart?): BasePart?
	local options = CollectionService:GetTagged(tag)
	if #options == 0 then
		warn("[JobService] No hay partes con el tag", tag)
		return nil
	end
	if #options > 1 and avoid then
		local index = table.find(options, avoid)
		if index then
			table.remove(options, index)
		end
	end
	return options[math.random(1, #options)]
end

local function removeCarry(shift: Shift)
	if shift.Carry then
		shift.Carry:Destroy()
		shift.Carry = nil
	end
end

-- Pone un objeto (caja, café, bolsa...) en las manos del personaje.
local function giveCarry(player: Player, shift: Shift)
	removeCarry(shift)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local job = Config.Jobs[shift.JobId]
	local item = Instance.new("Part")
	item.Name = "CarriedItem"
	item.Size = job.CarrySize
	item.Color = job.CarryColor
	item.Material = Enum.Material.SmoothPlastic
	item.CanCollide = false
	item.CanQuery = false
	item.Massless = true
	item.CFrame = root.CFrame * CFrame.new(0, 0, -1.8)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = item
	weld.Parent = item
	item.Parent = character
	shift.Carry = item
end

local function publish(player: Player, shift: Shift)
	local job = Config.Jobs[shift.JobId]
	player:SetAttribute("TaskTarget", shift.Target.Position)
	player:SetAttribute("TaskText", if shift.Phase == "Pickup" then job.PickupText else job.DropoffText)
end

local function pickupFor(player: Player, shift: Shift, lastTarget: BasePart?): BasePart?
	local provider = providers[shift.JobId]
	if provider then
		return provider.Pickup(player, shift)
	end
	return pickTarget("Pickup_" .. shift.JobId, lastTarget)
end

local function nextTask(player: Player, shift: Shift, lastTarget: BasePart?)
	local target = pickupFor(player, shift, lastTarget)
	if not target then
		return
	end
	shift.Phase = "Pickup"
	shift.Target = target
	publish(player, shift)
end

function JobService.quit(player: Player, silent: boolean?)
	local shift = shifts[player]
	if not shift then
		local own = handlers[player:GetAttribute("Job") or ""]
		if own then
			own.Quit(player, silent)
		end
		return
	end
	removeCarry(shift)
	shifts[player] = nil
	RoleService.offDuty(player, shift.JobId)
	player:SetAttribute("Job", nil)
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		Notify:FireClient(player, "Info", "Has dejado el trabajo.")
	end
end

function JobService.start(player: Player, jobId: string, context: any?)
	local job = Config.Jobs[jobId]
	if not job or not DataService.get(player) then
		return
	end
	if not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)

	local shift: Shift = { JobId = jobId, Phase = "Pickup", Target = nil :: any, Context = context }
	local target = pickupFor(player, shift, nil)
	if not target then
		return
	end
	shift.Target = target
	shifts[player] = shift
	RoleService.setOnDuty(player, jobId)
	player:SetAttribute("Job", jobId)
	publish(player, shift)
	Notify:FireClient(player, "Success", ("¡Contratado como %s! Sigue la línea azul."):format(job.DisplayName))
end

local function reached(player: Player, shift: Shift)
	local job = Config.Jobs[shift.JobId]
	if shift.Phase == "Pickup" then
		giveCarry(player, shift)
		local provider = providers[shift.JobId]
		local target = if provider then provider.Dropoff(player, shift) else pickTarget("Dropoff_" .. shift.JobId, shift.Target)
		if not target then
			return
		end
		shift.Phase = "Dropoff"
		shift.Target = target
		publish(player, shift)
		return
	end

	-- Entrega completada: cobrar
	removeCarry(shift)
	local provider = providers[shift.JobId]
	if provider and provider.Done then
		provider.Done(player, shift)
	end
	local pay = math.floor(job.Pay * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, pay, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -job.EnergyCost)
	Notify:FireClient(player, "Money", "+" .. Format.money(pay))
	StoryEvents.emit(player, "JobTaskDone", { JobId = shift.JobId, Pay = pay })

	if not NeedsService.canWork(player) then
		JobService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		return
	end
	nextTask(player, shift, shift.Target)
end

local function setupBoard(board: Instance)
	if not board:IsA("BasePart") then
		return
	end
	local jobId = board:GetAttribute("JobId")
	local job = Config.Jobs[jobId]
	if not job then
		warn("[JobService] JobBoard con JobId desconocido:", jobId)
		return
	end
	local prompt = Builder.prompt(board, "Trabajar", ("%s · %s/entrega"):format(job.DisplayName, Format.money(job.Pay)), 0.5)
	prompt.Triggered:Connect(function(player)
		local own = handlers[jobId]
		if own then
			if player:GetAttribute("Job") == jobId then
				own.Quit(player)
			else
				own.Start(player)
			end
			return
		end
		if player:GetAttribute("Job") == jobId then
			JobService.quit(player)
		else
			JobService.start(player, jobId)
		end
	end)
end

function JobService.init()
	for _, board in CollectionService:GetTagged("JobBoard") do
		setupBoard(board)
	end
	CollectionService:GetInstanceAddedSignal("JobBoard"):Connect(setupBoard)

	local QuitJob = ReplicatedStorage.Remotes.QuitJob :: RemoteEvent
	QuitJob.OnServerEvent:Connect(function(player)
		JobService.quit(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		JobService.quit(player, true)
	end)

	-- Si el jugador muere, pierde lo que llevaba y vuelve a la fase de recogida
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local shift = shifts[player]
			if shift then
				removeCarry(shift)
				nextTask(player, shift, nil)
			end
		end)
	end)

	-- Comprobar llegadas 4 veces por segundo
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, shift in shifts do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and shift.Target.Parent then
					local offset = root.Position - shift.Target.Position
					local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if flat <= Config.TaskReachDistance and math.abs(offset.Y) < 12 then
						reached(player, shift)
					end
				end
			end
		end
	end)
end

return JobService
