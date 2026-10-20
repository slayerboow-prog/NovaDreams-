-- OnboardingService: guarda los primeros pasos de cada jugador (el tutorial guiado y los consejos de la
-- primera vez) para que nunca se repitan. Lo que se enseña y cuándo lo decide el cliente
-- (Controllers/Guide); aquí solo se decide si le toca el tutorial y se apunta lo que va haciendo.
--
--   * Al cargar el perfil: jugador nuevo -> "Pendiente"; quien ya jugaba antes -> "Veterano" (sin tutorial).
--   * Atributos del jugador (los lee el cliente):
--       Tutorial      = "Pendiente" | "Hecho" | "Saltado" | "Veterano"
--       TutorialSteps = "Correr,Mover"  (pasos ya hechos)
--       TipsSeen      = "Tienda,Vehiculo" (consejos ya vistos)
--   * Remoto "Onboarding" (del cliente):
--       ("Step", id)  -> paso hecho (al completar todos: "Hecho")
--       ("Skip")      -> botón «Saltar»
--       ("Restart")   -> «Ver tutorial otra vez» del menú
--       ("Tip", id)   -> consejo visto

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Onboarding = require(ReplicatedStorage.Shared.Onboarding)
local DataService = require(script.Parent.DataService)

local OnboardingService = {}

local Remote: RemoteEvent

local function stateOf(data: { [string]: any }): { [string]: any }
	local ob = data.Onboarding
	if type(ob) ~= "table" then
		ob = { Tutorial = "", Steps = {}, Tips = {} }
		data.Onboarding = ob
	end
	ob.Steps = if type(ob.Steps) == "table" then ob.Steps else {}
	ob.Tips = if type(ob.Tips) == "table" then ob.Tips else {}
	return ob
end

local function publish(player: Player, ob: { [string]: any })
	player:SetAttribute("Tutorial", ob.Tutorial)
	player:SetAttribute("TutorialSteps", Onboarding.encode(ob.Steps))
	player:SetAttribute("TipsSeen", Onboarding.encode(ob.Tips))
end

local function onLoaded(player: Player, data: { [string]: any })
	local ob = stateOf(data)
	local stats = data.Stats
	ob.Tutorial = Onboarding.decide(ob.Tutorial, if type(stats) == "table" then stats.PlaySeconds else 0)
	publish(player, ob)
end

-- Lo que manda el cliente (se comprueba todo: puede llegar cualquier cosa)
function OnboardingService.handle(player: Player, kind: any, id: any)
	local data = DataService.get(player)
	if not data then
		return
	end
	local ob = stateOf(data)
	if kind == "Step" then
		if type(id) ~= "string" or not Onboarding.StepById[id] or ob.Tutorial ~= Onboarding.Pending then
			return
		end
		ob.Steps[id] = true
		if Onboarding.allDone(ob.Steps) then
			ob.Tutorial = Onboarding.Done
		end
	elseif kind == "Skip" then
		if ob.Tutorial ~= Onboarding.Pending then
			return
		end
		ob.Tutorial = Onboarding.Skipped
	elseif kind == "Restart" then
		ob.Tutorial = Onboarding.Pending
		ob.Steps = {}
	elseif kind == "Tip" then
		if type(id) ~= "string" or not Onboarding.Tips[id] then
			return
		end
		ob.Tips[id] = true
	else
		return
	end
	publish(player, ob)
end

function OnboardingService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Onboarding") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Onboarding"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(OnboardingService.handle)
	DataService.onLoaded(onLoaded) -- (también llama por los que ya habían cargado)
end

return OnboardingService
