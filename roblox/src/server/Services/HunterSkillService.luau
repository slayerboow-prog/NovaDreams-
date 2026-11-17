-- HunterSkillService: las HABILIDADES DE CAZADOR (shared/HunterSkills) contra las bestias de los planetas.
--
--   * El cliente (Controllers/HunterSkillsUI) pide «Use» con el id; aquí se comprueba TODO: que estés en un
--     planeta, en pie, con el nivel de cazador que pide y que haya pasado su espera. El daño lo hace
--     Services/BeastService.hit (que ya cuenta tu arma, sus mejoras, tus accesorios y tu nivel).
--   * «Area»: a las bestias de alrededor. «Dash»: te lanza hacia delante y golpea lo que cruzas.
--     «Buff»: el atributo BuffFuria / BuffFuriaHasta que lee BeastService.
--   * Cada uso deja un destello sencillo (un anillo de luz que crece) para que se vea.
-- Remoto «HunterSkill»: cliente → «Use» (id); servidor → «Used» (id, espera) o «No» (id, texto).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _TweenService = game:GetService("TweenService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Crafting = require(ReplicatedStorage.Shared.Crafting)
local HunterSkills = require(ReplicatedStorage.Shared.HunterSkills)

local HunterSkillService = {}

local Remote: RemoteEvent? = nil
local used: { [Player]: { [string]: number } } = {}
local lastFight: { [Player]: number } = {} -- (la última habilidad: el espíritu vuelve más despacio en plena pelea)

local function beastService(): any
	return require(script.Parent.BeastService)
end

-- El modo pruebas (el dueño) tiene todas las habilidades desde el principio
local function allUnlocked(player: Player): boolean
	local ok, yes = pcall(function()
		return (require(script.Parent.TesterService) :: any).bypass(player)
	end)
	return ok and yes == true
end

local function dataOf(player: Player): { [string]: any }?
	local ok, d = pcall(function()
		return (require(script.Parent.DataService) :: any).get(player)
	end)
	return if ok then d else nil
end

function HunterSkillService.rankOf(player: Player, id: string): number
	local d = dataOf(player)
	return HunterSkills.rankOf(d and type(d.Hunter) == "table" and d.Hunter.Skills or nil, id)
end

-- Gasta un punto de habilidad en subir un rango. Devuelve (ok, texto)
function HunterSkillService.rankUp(player: Player, id: any): (boolean, string)
	local sk = HunterSkills.get(id)
	if not sk then
		return false, "Habilidad desconocida."
	end
	local d = dataOf(player)
	if not d then
		return false, "Tus datos aún no han cargado."
	end
	d.Hunter = if type(d.Hunter) == "table" then d.Hunter else { Xp = 0 }
	d.Hunter.Skills = if type(d.Hunter.Skills) == "table" then d.Hunter.Skills else {}
	local level = Crafting.hunterLevel(d.Hunter.Xp)
	if not HunterSkills.unlocked(sk, level, HunterSkillService.knownOf(player)) then
		return false, ("%s se aprende en la Academia (o con nivel de cazador %d al graduarte)."):format(sk.Name, sk.Level)
	end
	local rank = HunterSkills.rankOf(d.Hunter.Skills, sk.Id)
	if rank >= HunterSkills.MaxRank then
		return false, sk.Name .. " ya es Maestra."
	end
	if HunterSkills.pointsLeft(level, d.Hunter.Skills) < 1 then
		return false, "No te quedan puntos de habilidad: sube de nivel de cazador."
	end
	d.Hunter.Skills[sk.Id] = rank + 1
	return true, ("%s %s: %s"):format(sk.Icon, sk.Name, HunterSkills.rankName(rank + 1))
end

-- Lo que sabes (shared/HunterSkills.unlocked). Las partidas de antes de la Academia (sin Learned): graduadas.
function HunterSkillService.knownOf(player: Player): { [string]: any }?
	local d = dataOf(player)
	if not d then
		return nil
	end
	d.Hunter = if type(d.Hunter) == "table" then d.Hunter else { Xp = 0 }
	if type(d.Hunter.Learned) ~= "table" then
		d.Hunter.Learned = {}
		if d.Hunter.Graduated == nil then
			d.Hunter.Graduated = true
		end
	end
	return { Learned = d.Hunter.Learned, Graduated = d.Hunter.Graduated == true }
end

local function publishKnown(player: Player)
	local known = HunterSkillService.knownOf(player)
	if known then
		player:SetAttribute("HabilidadesSabidas", HunterSkills.knownToText(known))
	end
end

-- Personaje nuevo: empieza sin habilidades (las enseña la Academia). Lo llama LifeStoryService al crearlo.
function HunterSkillService.startStudent(player: Player)
	local d = dataOf(player)
	if not d then
		return
	end
	d.Hunter = if type(d.Hunter) == "table" then d.Hunter else { Xp = 0 }
	d.Hunter.Learned = {}
	d.Hunter.Graduated = false
	publishKnown(player)
end

-- La Academia te enseña una habilidad ("*" o "Graduado": te gradúas y las demás llegan con el nivel)
function HunterSkillService.learn(player: Player, id: string): boolean
	local known = HunterSkillService.knownOf(player)
	if not known then
		return false
	end
	local d = dataOf(player) :: any
	if id == "*" or id == "Graduado" then
		d.Hunter.Graduated = true
	elseif HunterSkills.get(id) then
		d.Hunter.Learned[id] = true
	else
		return false
	end
	publishKnown(player)
	return true
end

function HunterSkillService.levelOf(player: Player): number
	local d = dataOf(player)
	return Crafting.hunterLevel(d and type(d.Hunter) == "table" and d.Hunter.Xp or 0)
end

-- Los efectos (17-11-2026: antes, cilindros de neón; ahora animación, estelas y partículas en Controllers/SkillFx):
-- se avisa a todos los clientes y cada uno lo dibuja
local function fx(player: Player, id: string, from: Vector3, dir: Vector3)
	if Remote then
		(Remote :: RemoteEvent):FireAllClients("Fx", player.UserId, id, from, dir)
	end
end

-- Usa una habilidad. now: para las pruebas. Devuelve (ok, texto o nil, bestias alcanzadas)
function HunterSkillService.use(player: Player, id: any, now: number?): (boolean, string?, number)
	local sk = HunterSkills.get(id)
	if not sk then
		return false, "Habilidad desconocida.", 0
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or player:GetAttribute("KO") or player:GetAttribute("Fallen") then
		return false, nil, 0
	end
	local onPlanet = type(player:GetAttribute("Planeta")) == "string"
	if not HunterSkills.unlocked(sk, HunterSkillService.levelOf(player), HunterSkillService.knownOf(player)) and not allUnlocked(player) then
		return false, ("%s se aprende en la Academia de guerreros (o con nivel de cazador %d al graduarte)."):format(sk.Name, sk.Level), 0
	end
	local t = now or os.clock()
	used[player] = used[player] or {}
	local rank = HunterSkillService.rankOf(player, sk.Id)
	local last = used[player][sk.Id]
	if last and t - last < HunterSkills.cooldown(sk, rank) then
		return false, nil, 0
	end
	-- Espíritu: cada habilidad gasta el suyo
	local cost = sk.Mana or 0
	local mana = tonumber(player:GetAttribute("Espiritu")) or HunterSkills.manaMax(HunterSkillService.levelOf(player))
	if cost > 0 and mana < cost then
		return false, ("Te falta espíritu para %s (%d de %d)."):format(sk.Name, math.floor(mana), cost), 0
	end
	player:SetAttribute("Espiritu", mana - cost)
	lastFight[player] = t
	used[player][sk.Id] = t
	local hits = 0
	if sk.Kind == "Buff" then
		local name = sk.Buff or "Furia"
		player:SetAttribute("Buff" .. name, HunterSkills.buffAmount(sk, rank))
		player:SetAttribute("Buff" .. name .. "Hasta", workspace:GetServerTimeNow() + sk.Seconds)
		fx(player, sk.Id, root.Position, root.CFrame.LookVector)
	else
		local Beasts = beastService()
		local base = Combat.Damage[#Combat.Damage] * HunterSkills.power(sk, rank)
		local from = root.Position
		local look = root.CFrame.LookVector
		local dir = Vector3.new(look.X, 0, look.Z)
		dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
		local reach = if sk.Kind == "Dash" then sk.Distance + 8 else sk.Radius
		-- en un planeta, contra las bestias; fuera (Valmar), contra quien haya cerca con las reglas de un golpe
		-- (enemigos de misión, alienígenas de la Invasión, jugadores sin protección…)
		local Fight = if onPlanet then nil else require(script.Parent.CombatService) :: any
		local targets = if onPlanet then Beasts.near(from, reach) else Fight.near(character, from, reach)
		for _, model in targets do
			if hits >= sk.MaxTargets then
				break
			end
			local pos = (model :: Model):GetPivot().Position
			local inside = if sk.Kind == "Dash" then HunterSkills.inDash(sk, from, dir, pos) else (pos - from).Magnitude <= sk.Radius
			if inside then
				local counted = false
				if onPlanet then
					counted = Beasts.hit(player, model, base, { Melee = true, Heavy = true, Skill = sk.Id })
				else
					local ok, res = pcall(Fight.applyHit, player, model, { Amount = base, Direction = (pos - from).Unit, Heavy = true, Melee = true, Skill = sk.Id, Weapon = sk.Name, At = pos })
					counted = ok and res and res.Hit == true
				end
				if counted then
					hits += 1
				end
			end
		end
		-- (el empujón de la Embestida lo hace el cliente en su personaje: se lo pide el remoto «Used»)
		fx(player, sk.Id, from, dir)
	end
	return true, nil, hits
end

function HunterSkillService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local found = remotes:FindFirstChild("HunterSkill")
	if not found then
		local r = Instance.new("RemoteEvent")
		r.Name = "HunterSkill"
		r.Parent = remotes
		found = r
	end
	Remote = found :: RemoteEvent
	;(Remote :: RemoteEvent).OnServerEvent:Connect(function(player, action, id)
		if action == "Use" then
			local sk = HunterSkills.get(id)
			local ok, text = HunterSkillService.use(player, id)
			if ok and sk then
				(Remote :: RemoteEvent):FireClient(player, "Used", sk.Id, HunterSkills.cooldown(sk, HunterSkillService.rankOf(player, sk.Id)))
				pcall(function() -- (las clases de la Academia esperan a que la uses)
					local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents) :: any
					StoryEvents.emit(player, "SkillUsed", { Skill = sk.Id })
				end)
			elseif text then
				(Remote :: RemoteEvent):FireClient(player, "No", id, text)
			end
		end
	end)
	local function publish(player: Player)
		local level = HunterSkillService.levelOf(player)
		player:SetAttribute("NivelCazador", level)
		player:SetAttribute("HabilidadesTodas", allUnlocked(player)) -- (el cliente las enseña desbloqueadas)
		publishKnown(player)
		local max = HunterSkills.manaMax(level)
		player:SetAttribute("EspirituMax", max)
		if player:GetAttribute("Espiritu") == nil then
			player:SetAttribute("Espiritu", max)
		end
	end
	-- el espíritu se recupera solo (más deprisa si llevas un rato sin pelear) y el nivel puede subir
	task.spawn(function()
		while true do
			task.wait(0.5)
			local t = os.clock()
			for _, p in Players:GetPlayers() do
				local max = tonumber(p:GetAttribute("EspirituMax"))
				if max then
					local cur = tonumber(p:GetAttribute("Espiritu")) or max
					if cur < max then
						local fighting = lastFight[p] ~= nil and t - lastFight[p] < 8
						p:SetAttribute("Espiritu", math.min(max, cur + HunterSkills.manaRegen(max, fighting) * 0.5))
					end
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(15)
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("EspirituMax") ~= nil then
					pcall(publish, p)
				end
			end
		end
	end)
	Players.PlayerAdded:Connect(function(p)
		task.delay(6, function()
			if p.Parent then
				publish(p)
			end
		end)
	end)
	for _, p in Players:GetPlayers() do
		task.delay(6, function()
			if p.Parent then
				publish(p)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(p)
		used[p] = nil
		lastFight[p] = nil
	end)
end

return HunterSkillService
