-- TaxService: la Agencia Tributaria de Valmar (reglas en shared/Taxes).
--
--   * Lo que ganas trabajando cuenta para tu renta del ejercicio (DataService.onEarning).
--   * Cada Taxes.Period segundos jugados se cierra el ejercicio y empieza la campaña de la renta:
--     tu cuota queda pendiente y te avisa (atributo TaxPending).
--   * Pagas en la ventanilla "Presentar declaración" de la Agencia Tributaria. Si hay agentes de
--     Hacienda de servicio en la oficina, ellos tramitan tu declaración (cobran y suben de rango).
--   * Si pasan Taxes.Grace ejercicios sin presentarla: inspección (recargo). Los agentes de servicio
--     ven a quién toca inspeccionar y pueden hacerlo a su lado (comando INSPECCIONAR): se cobra la
--     deuda (lo que haya) y el inspector gana su parte.
--   * Lo recaudado va al Tesoro Público (cartel de la oficina, en este servidor).
-- Se guarda en data.Tax = { Earned, Clock, Pending, Unfiled }.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Taxes = require(ReplicatedStorage.Shared.Taxes)
local Format = require(ReplicatedStorage.Shared.Format)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local CareerService = require(script.Parent.CareerService)

local TaxService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local treasury = 0
local TICK = 30

local function taxOf(player: Player): { [string]: number }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local tax = data.Tax
	if type(tax) ~= "table" then
		tax = { Earned = 0, Clock = 0, Pending = 0, Unfiled = 0 }
		data.Tax = tax
	end
	return tax
end

local function sync(player: Player)
	local tax = taxOf(player)
	if not tax then
		return
	end
	player:SetAttribute("TaxPending", if tax.Pending > 0 then tax.Pending else nil)
	player:SetAttribute("TaxOverdue", if tax.Unfiled > Taxes.Grace then true else nil)
	player:SetAttribute("TaxEarned", tax.Earned)
end

local function updateBoard()
	for _, board in CollectionService:GetTagged("TreasuryBoard") do
		local gui = board:FindFirstChildOfClass("SurfaceGui")
		local label = gui and gui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = ("TESORO PÚBLICO\n%s recaudados"):format(Format.money(treasury))
		end
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Agentes de Hacienda de servicio dentro de la oficina (cerca de la ventanilla)
local function agentsAt(window: BasePart): { Player }
	local list = {}
	for _, agent in Players:GetPlayers() do
		local r = rootOf(agent)
		if agent:GetAttribute("Job") == "Hacienda" and r and (r.Position - window.Position).Magnitude < 70 then
			table.insert(list, agent)
		end
	end
	return list
end

-- Cobra lo que se pueda de la deuda (devuelve lo cobrado)
local function collect(player: Player): number
	local tax = taxOf(player)
	local data = DataService.get(player)
	if not tax or not data or tax.Pending <= 0 then
		return 0
	end
	local paid = math.min(tax.Pending, data.Money)
	if paid > 0 then
		DataService.addMoney(player, -paid)
		tax.Pending -= paid
		treasury += paid
		updateBoard()
	end
	if tax.Pending <= 0 then
		tax.Unfiled = 0
	end
	sync(player)
	return paid
end

-- Presentar la declaración en la ventanilla
local function file(player: Player, window: BasePart)
	local tax = taxOf(player)
	if not tax then
		return
	end
	if tax.Pending <= 0 then
		Notify:FireClient(player, "Info", ("🏛 Estás al día con Hacienda. Este ejercicio llevas ganado %s (cuota estimada %s)."):format(Format.money(tax.Earned), Format.money(Taxes.due(tax.Earned))))
		return
	end
	local due = tax.Pending
	local paid = collect(player)
	if paid <= 0 then
		Notify:FireClient(player, "Error", ("🏛 No tienes dinero para pagar tu cuota de %s."):format(Format.money(due)))
		return
	end
	local rest = taxOf(player).Pending
	Notify:FireClient(player, "Success", if rest > 0
		then ("🏛 Has pagado %s. Aún debes %s."):format(Format.money(paid), Format.money(rest))
		else ("🏛 Declaración presentada: has pagado %s. ¡Al día con Hacienda!"):format(Format.money(paid)))
	StoryEvents.emit(player, "TaxFiled", { Paid = paid })
	-- Los agentes que atienden en la oficina tramitan la declaración
	for _, agent in agentsAt(window) do
		if agent ~= player then
			DataService.addMoney(agent, Taxes.AgentPay, true)
			Notify:FireClient(agent, "Money", ("🏛 Declaración de %s tramitada: +%s"):format(player.DisplayName, Format.money(Taxes.AgentPay)))
			CareerService.addPoints(agent, "Hacienda", "Declaration")
			StoryEvents.emit(agent, "JobTaskDone", { JobId = "Hacienda", Pay = Taxes.AgentPay })
			break -- (la tramita uno)
		end
	end
end

-- Inspección: un agente de servicio junto a quien no ha declarado
local function inspect(agent: Player, target: any)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == agent or agent:GetAttribute("Job") ~= "Hacienda" then
		return
	end
	local a, b = rootOf(agent), rootOf(target)
	if not a or not b or (a.Position - b.Position).Magnitude > 10 then
		return
	end
	if not target:GetAttribute("TaxOverdue") then
		Notify:FireClient(agent, "Info", target.DisplayName .. " está al día con Hacienda.")
		return
	end
	local paid = collect(target)
	Notify:FireClient(target, "Error", ("🏛 Inspección de Hacienda (%s): te han cobrado %s."):format(agent.DisplayName, Format.money(paid)))
	DataService.addMoney(agent, Taxes.InspectorPay, true)
	Notify:FireClient(agent, "Money", ("🏛 Inspección a %s: cobrados %s · +%s para ti"):format(target.DisplayName, Format.money(paid), Format.money(Taxes.InspectorPay)))
	CareerService.addPoints(agent, "Hacienda", "Inspection")
	StoryEvents.emit(agent, "JobTaskDone", { JobId = "Hacienda", Pay = Taxes.InspectorPay })
end

-- Cierre de ejercicio: la cuota queda pendiente
local function closeYear(player: Player)
	local tax = taxOf(player)
	if not tax then
		return
	end
	local due = Taxes.due(tax.Earned)
	tax.Earned = 0
	tax.Clock = 0
	if due <= 0 and tax.Pending <= 0 then
		sync(player)
		return
	end
	tax.Pending += due
	tax.Unfiled += 1
	if tax.Unfiled > Taxes.Grace then
		tax.Pending = Taxes.withSurcharge(tax.Pending)
		Notify:FireClient(player, "Error", ("🏛 Hacienda te ha abierto una inspección: debes %s (con recargo)."):format(Format.money(tax.Pending)))
		for _, agent in Players:GetPlayers() do
			if agent:GetAttribute("Job") == "Hacienda" then
				Notify:FireClient(agent, "Info", ("🏛 Inspección pendiente: %s debe %s."):format(player.DisplayName, Format.money(tax.Pending)))
			end
		end
	else
		Notify:FireClient(player, "Info", ("📨 Campaña de la renta: presenta tu declaración en la Agencia Tributaria (cuota %s)."):format(Format.money(tax.Pending)))
	end
	sync(player)
end

function TaxService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Tax") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Tax"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, target: any)
		if kind == "Inspect" then
			inspect(player, target)
		end
	end)

	for _, window in CollectionService:GetTagged("TaxWindow") do
		if window:IsA("BasePart") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Presentar declaración"
			prompt.ObjectText = "🏛 Declaración de la renta"
			prompt.HoldDuration = 1.2
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = window
			prompt.Triggered:Connect(function(player)
				file(player, window)
			end)
		end
	end
	updateBoard()

	DataService.onEarning(function(player, amount)
		local tax = taxOf(player)
		if tax then
			tax.Earned += amount
			player:SetAttribute("TaxEarned", tax.Earned)
		end
	end)
	DataService.onLoaded(function(player)
		sync(player)
	end)

	-- Reloj del ejercicio (tiempo jugado)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local tax = taxOf(player)
				if tax then
					tax.Clock += TICK
					if tax.Clock >= Taxes.Period then
						closeYear(player)
					end
				end
			end
		end
	end)
end

return TaxService
