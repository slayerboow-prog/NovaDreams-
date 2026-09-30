-- BattlePassClient: envoltorio del remoto "BattlePass" para la interfaz del pase de temporada.
-- Solo habla con el servidor y guarda el último estado: NO pinta nada (la interfaz va aparte y usa
-- esto). El servidor lo decide todo; aquí solo se PIDE. Contrato en docs/pase-de-temporada.md.
--
--   local BP = require(Controllers.BattlePassClient)
--   BP.start()
--   BP.onState(function(state) ... end)        -- cada estado completo (Season, Premium, Progress…)
--   BP.on("Unlocked", function(info) ... end)   -- también "Result", "MissionDone", "Premium"
--   BP.refresh()                               -- pide el estado (al abrir el panel)
--   BP.claim("Free", 5) · BP.claimAll() · BP.buy() · BP.equip("Title", id) · BP.track(missionId)
--   BP.reroll(missionId) · BP.choose(storyId, optionId) · BP.buyToken(itemId)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlePassClient = {}

local remote: RemoteEvent? = nil
local current: { [string]: any }? = nil
local stateListeners: { ({ [string]: any }) -> () } = {}
local listeners: { [string]: { (any) -> () } } = {}
local started = false

local function fire(list: { (any) -> () }?, value: any)
	for _, fn in list or {} do
		task.spawn(fn, value)
	end
end

function BattlePassClient.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local found = remotes and remotes:WaitForChild("BattlePass", 30)
		if not found or not found:IsA("RemoteEvent") then
			return -- (servidor sin pase de temporada: no pasa nada)
		end
		remote = found
		found.OnClientEvent:Connect(function(kind, payload)
			if kind == "State" and type(payload) == "table" then
				current = payload
				fire(stateListeners :: any, payload)
			end
			fire(listeners[kind], payload)
		end)
	end)
end

-- Último estado recibido (nil hasta el primero)
function BattlePassClient.state(): { [string]: any }?
	return current
end

function BattlePassClient.onState(fn: ({ [string]: any }) -> ())
	table.insert(stateListeners, fn)
	if current then
		task.spawn(fn, current)
	end
end

function BattlePassClient.on(kind: string, fn: (any) -> ())
	listeners[kind] = listeners[kind] or {}
	table.insert(listeners[kind], fn)
end

function BattlePassClient.request(action: string, a: any?, b: any?, c: any?): boolean
	if not remote then
		return false
	end
	remote:FireServer(action, a, b, c)
	return true
end

function BattlePassClient.refresh(): boolean
	return BattlePassClient.request("Get")
end
function BattlePassClient.claim(track: string, level: number): boolean
	return BattlePassClient.request("Claim", track, level)
end
function BattlePassClient.claimAll(): boolean
	return BattlePassClient.request("ClaimAll")
end
function BattlePassClient.buy(): boolean
	return BattlePassClient.request("Buy")
end
function BattlePassClient.equip(slot: string, id: string?, kind: string?): boolean
	return BattlePassClient.request("Equip", slot, id, kind)
end
function BattlePassClient.track(missionId: string?): boolean
	return BattlePassClient.request("Track", missionId)
end
function BattlePassClient.reroll(missionId: string): boolean
	return BattlePassClient.request("Reroll", missionId)
end
function BattlePassClient.choose(storyId: string, optionId: string): boolean
	return BattlePassClient.request("StoryChoice", storyId, optionId)
end
function BattlePassClient.buyToken(itemId: string): boolean
	return BattlePassClient.request("BuyToken", itemId)
end

return BattlePassClient
