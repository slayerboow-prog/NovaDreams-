-- CraftingService: el TALLER (fabricar al estilo Minecraft; recetas en shared/Crafting).
--
--   * Se abre con «Fabricar» en un Taller de las ciudades de los planetas (etiqueta «Taller»: Mesa, Forja y
--     Alquimia) o usando la mesa plegable desde la mochila (solo recetas de Mesa, en cualquier sitio).
--   * El cliente (Controllers/CraftingUI) pide «Craft» con una receta y cuántas; aquí se comprueba TODO: que el
--     banco tenga esa receta, que sigas al lado del Taller, que tengas los materiales (mochila + minerales de la
--     bodega de tu nave) y que te quepa lo que sale. Se gasta y se da en el servidor.
--   * Pociones (desde la mochila): curación al momento, regeneración, fuerza y piel de piedra (atributos
--     Buff<X>/Buff<X>Hasta que lee Services/BeastService), velocidad y el tónico de entorno (baja el medidor de
--     la desventaja del planeta: Services/PlanetHazardService).
--   * Herramientas: la mesa plegable, la brújula de bestias (hacia dónde queda la guarida más cercana) y la
--     ganzúa (pasiva: Services/BeastService).
-- Remoto «Crafting»: cliente → «Craft» (id, veces); servidor → «Open» { Bench, Have }, «Have» {…}, «Result» (ok, texto).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Items = require(ReplicatedStorage.Shared.Items)
local Bestiary = require(ReplicatedStorage.Shared.Cosmos.Bestiary)
local PlanetRegistry = require(ReplicatedStorage.Shared.Cosmos.PlanetRegistry)

local CraftingService = {}

CraftingService.BenchReach = 22 -- studs: hay que seguir al lado del Taller para fabricar
CraftingService.MaxTimes = 10

local Remote: RemoteEvent? = nil
local Notify: RemoteEvent? = nil
local open: { [Player]: { Bench: string, At: Vector3? } } = {}
local lastCraft: { [Player]: number } = {}

local function data(player: Player): { [string]: any }?
	local ok, d = pcall(function()
		return (require(script.Parent.DataService) :: any).get(player)
	end)
	return if ok then d else nil
end

local function inv(): any
	return require(script.Parent.InventoryService)
end

local function tell(player: Player, kind: string, text: string)
	if Notify then
		Notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function haveOf(player: Player): { [string]: number }
	local d = data(player)
	return if d then Crafting.have(d) else {}
end

local function nameOf(id: string): string
	local item = Items.get(id)
	if item then
		return item.Icon .. " " .. item.Name
	end
	local ok, Mining = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.Mining)
	end)
	local ore = ok and Mining.Ores[id]
	return if ore then "⛏ " .. ore.Name else id
end

-- Lo que el libro enseña además de los materiales: mejoras, dinero y nivel de cazador
local function extraOf(player: Player): { [string]: any }
	local d = data(player)
	return {
		Refine = d and d.Refine or {},
		Money = d and d.Money or 0,
		Xp = d and type(d.Hunter) == "table" and d.Hunter.Xp or 0,
		Skills = d and type(d.Hunter) == "table" and d.Hunter.Skills or {},
		Style = player:GetAttribute("EstiloArma") or "",
	}
end

function CraftingService.openFor(player: Player, bench: string, at: Vector3?)
	open[player] = { Bench = bench, At = at }
	if Remote then
		Remote:FireClient(player, "Open", { Bench = bench, Have = haveOf(player), Extra = extraOf(player) })
	end
end

-- MEJORAR un objeto de equipo (+1). Se puede en cualquier sitio, desde la mochila. roll: para las pruebas.
-- Devuelve (ok, texto, resultado "Ok" | "Fail" | "Saved" | "Drop" | nil)
function CraftingService.refine(player: Player, id: any, roll: number?): (boolean, string, string?)
	if type(id) ~= "string" or not Crafting.isEquip(id) then
		return false, "Eso no se puede mejorar.", nil
	end
	local d = data(player)
	if not d then
		return false, "Tus datos aún no han cargado.", nil
	end
	if (tonumber(d.Items and d.Items[id]) or 0) < 1 then
		return false, "No llevas ese objeto en la mochila.", nil
	end
	local t = os.clock()
	if lastCraft[player] and t - lastCraft[player] < 0.35 then
		return false, "Despacio…", nil
	end
	lastCraft[player] = t
	d.Refine = if type(d.Refine) == "table" then d.Refine else {}
	local level = Crafting.refineOf(d.Refine, id)
	local step = Crafting.refineStep(level)
	if not step then
		return false, "Ya está al máximo (+" .. Crafting.MaxRefine .. ").", nil
	end
	local have = Crafting.have(d)
	if (have[step.Stone] or 0) < step.Stones then
		return false, ("Te falta: %s %d/%d"):format(nameOf(step.Stone), have[step.Stone] or 0, step.Stones), nil
	end
	if (tonumber(d.Money) or 0) < step.Money then
		return false, ("Te falta dinero: cuesta %d €."):format(step.Money), nil
	end
	local DataService = require(script.Parent.DataService) :: any
	if not DataService.spend(player, step.Money) then
		return false, ("Te falta dinero: cuesta %d €."):format(step.Money), nil
	end
	if not inv().remove(player, step.Stone, step.Stones) then
		DataService.addMoney(player, step.Money)
		return false, "No se han podido gastar las piedras.", nil
	end
	local hasSeal = (tonumber(d.Items and d.Items.SelloHerrero) or 0) > 0
	local newLevel, outcome = Crafting.refineRoll(level, roll or math.random(), hasSeal)
	if outcome == "Saved" then
		inv().remove(player, "SelloHerrero", 1)
	end
	d.Refine[id] = if newLevel > 0 then newLevel else nil
	local item = Items.get(id)
	local name = (item and item.Icon or "") .. " " .. Crafting.refinedName(item and item.Name or id, newLevel)
	if outcome == "Ok" then
		return true, ("✨ ¡Mejora conseguida! %s"):format(name), outcome
	elseif outcome == "Saved" then
		return false, ("🔏 La mejora ha fallado, pero el Sello del herrero ha protegido tu objeto: %s"):format(name), outcome
	elseif outcome == "Drop" then
		return false, ("💥 La mejora ha fallado y el objeto ha bajado un nivel: %s"):format(name), outcome
	end
	return false, ("La mejora ha fallado. Tu objeto sigue igual: %s"):format(name), outcome
end

-- Gasta `n` de un material: los minerales, primero de la bodega de la nave y luego de la mochila
local function spend(player: Player, d: { [string]: any }, id: string, n: number): boolean
	local left = n
	if Crafting.Ores[id] and d.Space and type(d.Space.Ore) == "table" then
		local inHold = tonumber(d.Space.Ore[id]) or 0
		local take = math.min(inHold, left)
		if take > 0 then
			d.Space.Ore[id] = inHold - take
			left -= take
		end
	end
	if left > 0 then
		return inv().remove(player, id, left)
	end
	return true
end

-- Fabricar (todo comprobado aquí). Devuelve (ok, texto)
function CraftingService.craft(player: Player, recipeId: any, timesRaw: any): (boolean, string)
	if type(recipeId) ~= "string" then
		return false, "Receta desconocida."
	end
	local r = Crafting.recipe(recipeId)
	if not r then
		return false, "Receta desconocida."
	end
	local session = open[player]
	if not session then
		return false, "Abre un Taller (o tu mesa plegable) para fabricar."
	end
	if not Crafting.benchHas(session.Bench, r) then
		return false, ("Esto se hace en %s %s: búscala en el Taller de una ciudad."):format(Crafting.Benches[r.Bench].Icon, Crafting.Benches[r.Bench].Name)
	end
	if session.At then
		local root = rootOf(player)
		if not root or (root.Position - session.At).Magnitude > CraftingService.BenchReach then
			return false, "Te has alejado del Taller."
		end
	end
	local t = os.clock()
	if lastCraft[player] and t - lastCraft[player] < 0.35 then
		return false, "Despacio…"
	end
	lastCraft[player] = t
	local times = math.clamp(math.floor(tonumber(timesRaw) or 1), 1, CraftingService.MaxTimes)
	local d = data(player)
	if not d then
		return false, "Tus datos aún no han cargado."
	end
	local have = Crafting.have(d)
	local can = Crafting.times(r, have)
	if can < 1 then
		local miss = Crafting.missing(r, have)
		local parts = {}
		for _, m in miss do
			table.insert(parts, ("%s %d/%d"):format(nameOf(m[1]), m[2], m[3]))
		end
		return false, "Te falta: " .. table.concat(parts, ", ")
	end
	times = math.min(times, can)
	local total = r.Makes * times
	if not inv().canAdd(player, r.Id, total) then
		return false, "No te cabe en la mochila: haz sitio primero."
	end
	for id, need in r.Needs do
		if not spend(player, d, id, need * times) then
			return false, "No se ha podido gastar " .. nameOf(id) .. "."
		end
	end
	inv().add(player, r.Id, total)
	return true, ("🛠 Fabricado: %s ×%d"):format(nameOf(r.Id), total)
end

---------------------------------------------------------------------
-- Pociones y herramientas (desde la mochila)
---------------------------------------------------------------------
local function setBuff(player: Player, name: string, amount: number, seconds: number)
	player:SetAttribute("Buff" .. name, amount)
	player:SetAttribute("Buff" .. name .. "Hasta", workspace:GetServerTimeNow() + seconds)
end

local function humanoidOf(player: Player): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function usePotion(player: Player, g: { [string]: any })
	local hum = humanoidOf(player)
	if not hum or hum.Health <= 0 then
		return
	end
	if g.Effect == "Hazard" then
		local okH, Hazard = pcall(require, script.Parent.PlanetHazardService)
		if not okH or not (Hazard :: any).planetOf(player) then
			tell(player, "Info", "🌡 Aquí no hay nada que aguantar: guárdalo para un planeta.")
			return
		end
		local v = (Hazard :: any).valueOf(player)
		;(Hazard :: any).bump(player, -v * (g.Amount / 100))
	end
	if not inv().remove(player, g.Id, 1) then
		return
	end
	if g.Effect == "Heal" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + g.Amount)
	elseif g.Effect == "Regen" then
		task.spawn(function()
			for _ = 1, g.Seconds do
				task.wait(1)
				local h = humanoidOf(player)
				if not h or h.Health <= 0 then
					break
				end
				h.Health = math.min(h.MaxHealth, h.Health + g.Amount)
			end
		end)
	elseif g.Effect == "Strength" then
		setBuff(player, "Fuerza", g.Amount, g.Seconds)
	elseif g.Effect == "Stone" then
		setBuff(player, "Piedra", g.Amount, g.Seconds)
	elseif g.Effect == "Speed" then
		setBuff(player, "Velocidad", g.Amount, g.Seconds)
		local before = hum.WalkSpeed
		hum.WalkSpeed = before + g.Amount
		task.delay(g.Seconds, function()
			local h = humanoidOf(player)
			if h and h.WalkSpeed >= before + g.Amount - 0.1 then
				h.WalkSpeed = math.max(before, h.WalkSpeed - g.Amount)
			end
		end)
	end
	local secs = if g.Seconds then (" (%d s)"):format(g.Seconds) else ""
	tell(player, "Success", ("%s %s%s"):format(g.Icon, g.Name, secs))
end

local DIRS = { "norte", "noreste", "este", "sureste", "sur", "suroeste", "oeste", "noroeste" }
local function compass(player: Player)
	local root = rootOf(player)
	local id = player:GetAttribute("Planeta")
	local S = type(id) == "string" and PlanetRegistry.get(id)
	if not root or not S then
		tell(player, "Info", "🧭 La aguja da vueltas: aquí no hay bestias. Úsala en un planeta.")
		return
	end
	local places = Bestiary.places(S)
	local O = S.Origin
	local best, bd = nil, math.huge
	for _, l in places.Lairs do
		local d = (Vector3.new(O.X + l.X, 0, O.Z + l.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
		if d < bd then
			best, bd = l, d
		end
	end
	if not best then
		tell(player, "Info", "🧭 No notas nada cerca.")
		return
	end
	local dx, dz = O.X + best.X - root.Position.X, O.Z + best.Z - root.Position.Z
	local ang = math.deg(math.atan2(dx, -dz)) % 360
	local dir = DIRS[(math.floor((ang + 22.5) / 45) % 8) + 1]
	local text = ("🧭 %s: hacia el %s, a unos %d m."):format(best.Name, dir, math.floor(bd * 0.28 + 0.5))
	local boss = places.Boss
	if boss then
		local d = (Vector3.new(O.X + boss.X, 0, O.Z + boss.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
		if d < 600 then
			text ..= " La aguja tiembla: algo muy grande anda cerca."
		end
	end
	tell(player, "Info", text)
end

function CraftingService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	local found = remotes:FindFirstChild("Crafting")
	if not found then
		local r = Instance.new("RemoteEvent")
		r.Name = "Crafting"
		r.Parent = remotes
		found = r
	end
	Remote = found :: RemoteEvent
	;(Remote :: RemoteEvent).OnServerEvent:Connect(function(player, action, a, b)
		if action == "Craft" then
			local ok, text = CraftingService.craft(player, a, b)
			;(Remote :: RemoteEvent):FireClient(player, "Result", ok, text)
			;(Remote :: RemoteEvent):FireClient(player, "Have", haveOf(player), extraOf(player))
		elseif action == "Refine" then
			local ok, text = CraftingService.refine(player, a)
			;(Remote :: RemoteEvent):FireClient(player, "Result", ok, text)
			;(Remote :: RemoteEvent):FireClient(player, "Have", haveOf(player), extraOf(player))
		elseif action == "SkillUp" then
			local okS, Skill = pcall(require, script.Parent.HunterSkillService)
			if okS then
				local ok, text = (Skill :: any).rankUp(player, a)
				;(Remote :: RemoteEvent):FireClient(player, "Result", ok, text)
			end
			;(Remote :: RemoteEvent):FireClient(player, "Have", haveOf(player), extraOf(player))
		elseif action == "OpenBag" then
			-- fabricar y mejorar desde la mochila, en cualquier sitio
			CraftingService.openFor(player, "Mochila", nil)
		elseif action == "Close" then
			open[player] = nil
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if CollectionService:HasTag(prompt, "Taller") then
			local part = prompt.Parent
			CraftingService.openFor(player, "Taller", if part and part:IsA("BasePart") then part.Position else nil)
		end
	end)
	-- pociones y herramientas: se usan desde la mochila
	local InventoryService = inv()
	for _, g in Crafting.Gear do
		if g.Kind == "Potion" then
			InventoryService.onUse(g.Id, function(player: Player)
				usePotion(player, g)
			end)
		elseif g.Id == "MesaPlegable" then
			InventoryService.onUse(g.Id, function(player: Player)
				CraftingService.openFor(player, "Mesa", nil)
			end)
		elseif g.Id == "BrujulaBestias" then
			InventoryService.onUse(g.Id, function(player: Player)
				compass(player)
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		open[p] = nil
		lastCraft[p] = nil
	end)
end

return CraftingService
