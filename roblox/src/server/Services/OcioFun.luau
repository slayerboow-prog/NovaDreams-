-- OcioFun (servidor, no es un servicio): lo que dan las actividades de ocio de las zonas verdes.
--
--   OcioFun.add(player, amount, reason)   +diversión con la necesidad «Diversión» (NeedsService.addFun)
--                                         si ya existe; si no, no hace nada (así funciona antes y después
--                                         de que llegue esa necesidad)
--   OcioFun.reward(player, { Fun, Money, Xp, Tickets, Reason, Event, Data })
--                                         diversión + dinero (cuenta como ganado) + experiencia + tickets de
--                                         los recreativos, el aviso y el suceso de StoryEvents (pase de
--                                         temporada, misiones) en una sola llamada
--   OcioFun.say(player, kind, text)       aviso (Notify)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)

local OcioFun = {}

local function service(name: string): any
	local ok, svc = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok and type(svc) == "table" then svc else nil
end

-- Remoto «Ocio» (Controllers/OcioClient): sonidos 3D, HUD del karting, trucos del skatepark…
local remote: RemoteEvent? = nil
function OcioFun.remote(): RemoteEvent?
	if remote and remote.Parent then
		return remote
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return nil
	end
	local found = remotes:FindFirstChild("Ocio")
	if not found then
		found = Instance.new("RemoteEvent")
		found.Name = "Ocio"
		found.Parent = remotes
	end
	remote = found :: RemoteEvent
	return remote
end

-- Manda un suceso a un jugador (o a todos si player es nil)
function OcioFun.fire(kind: string, data: { [string]: any }, player: Player?)
	local r = OcioFun.remote()
	if not r then
		return
	end
	if player then
		r:FireClient(player, kind, data)
	else
		r:FireAllClients(kind, data)
	end
end

function OcioFun.say(player: Player, kind: string, text: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local notify = remotes and remotes:FindFirstChild("Notify")
	if notify then
		(notify :: RemoteEvent):FireClient(player, kind, text)
	end
end

-- +diversión (defensivo: la necesidad «Diversión» puede no existir todavía)
function OcioFun.add(player: Player, amount: number, reason: string?): boolean
	if amount == 0 then
		return false
	end
	local Needs = service("NeedsService")
	local addFun = Needs and Needs.addFun
	if type(addFun) ~= "function" then
		return false
	end
	local ok, err = pcall(addFun, player, amount, reason or "Ocio")
	if not ok then
		warn("[OcioFun] addFun: " .. tostring(err))
	end
	return ok
end

function OcioFun.reward(player: Player, r: { [string]: any })
	local parts = {}
	if (r.Money or 0) > 0 then
		local Data = service("DataService")
		if Data then
			Data.addMoney(player, r.Money, true)
			table.insert(parts, "+" .. Format.money(r.Money))
		end
	end
	if (r.Tickets or 0) > 0 then
		local Data = service("DataService")
		local data = Data and Data.get(player)
		if data then
			data.Tickets = (tonumber(data.Tickets) or 0) + r.Tickets
			player:SetAttribute("Tickets", data.Tickets)
			table.insert(parts, ("+%d 🎟️"):format(r.Tickets))
		end
	end
	if (r.Xp or 0) > 0 then
		local Progression = service("ProgressionService")
		if Progression and Progression.addXp then
			pcall(Progression.addXp, player, r.Xp, r.Reason)
		end
	end
	if (r.Fun or 0) > 0 and OcioFun.add(player, r.Fun, r.Reason) then
		table.insert(parts, ("+%d 🎈"):format(r.Fun))
	end
	if r.Event then
		local ok, StoryEvents = pcall(function()
			return require((script.Parent.Parent :: any).LifeStory.StoryEvents)
		end)
		if ok and StoryEvents then
			pcall(StoryEvents.emit, player, r.Event, r.Data or {})
		end
	end
	if r.Text or #parts > 0 then
		OcioFun.say(player, if (r.Money or 0) > 0 then "Money" else "Success", (r.Text or "") .. (if r.Text and #parts > 0 then "  " else "") .. table.concat(parts, "  "))
	end
end

return OcioFun
