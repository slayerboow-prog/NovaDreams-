-- ConductService: el historial de buen o mal comportamiento («chico o chica malo») — reglas en
-- shared/Conduct.
--
--   * Escucha lo malo que se sabe (StoryEvents): delitos que ha visto o denunciado alguien
--     ("Crime", WantedService), travesuras de los más pequeños ("Misbehaved") y cristales rotos
--     ("Vandalism", BreakService). Cada cosa suma puntos al historial (data.Conduct).
--   * Si eres menor, además se entera tu familia: te llaman al móvil («¡Nos ha llamado la
--     policía!»), baja la relación con tus padres (y un poco con Abu), sube tu Rebeldía (rasgo de
--     la historia) y te castigan: sin paga y a casa antes de la noche.
--   * Si la policía detiene a un menor, no hay juicio: le lleva a casa (takeHome) y allí le espera
--     la charla con su familia.
--   * La paga: los niños y adolescentes reciben un poco de dinero cada día de juego (si no están
--     castigados). Portarse bien borra puntos poco a poco.
-- Lo que ve el cliente (ficha del personaje): atributos Conduct, ConductLevel, ConductLast,
-- ConductCount y GroundedUntil.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conduct = require(ReplicatedStorage.Shared.Conduct)
local Config = require(ReplicatedStorage.Shared.Config)
local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Format = require(ReplicatedStorage.Shared.Format)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)

-- Antes de llevar a alguien a otro sitio: que se levante del asiento en que vaya (coche, autobús,
-- metro). Si no, se llevaba el vehículo con él (un coche del metro acababa en la calle).
local function standUpBefore(character: Model?)
	local ok, who = pcall(function()
		return character and game:GetService("Players"):GetPlayerFromCharacter(character)
	end)
	if ok and who then
		pcall(function()
			require(script.Parent.VehicleService).standUp(who)
		end)
	end
end


local ConductService = {}

ConductService.HomeDelay = 3 -- segundos de «te llevamos a casa» antes de llegar
local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

-- Servicios que se cargan cuando hacen falta (así no hay requires en círculo)
local function lazy(name: string): any
	local ok, module = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok then module else nil
end

local function conductOf(data: { [string]: any }): { [string]: any }
	local c = data.Conduct
	if type(c) ~= "table" then
		c = {}
		data.Conduct = c
	end
	c.Points = tonumber(c.Points) or 0
	c.Log = if type(c.Log) == "table" then c.Log else {}
	return c
end

local function familyName(player: Player): string
	return Strings.get(Cast.nameOf("Familia", { FamilyKey = player:GetAttribute("FamilyKey") or "NPC.MAMA" }))
end

local function textOf(kind: string): string
	local crime = Wanted.Crimes[kind]
	return Conduct.Texts[kind] or (crime and crime.Text) or kind
end

local function grounded(c: { [string]: any }): boolean
	return (tonumber(c.GroundedUntil) or 0) > os.time()
end

local function publish(player: Player, c: { [string]: any })
	local level = Conduct.level(c.Points)
	player:SetAttribute("Conduct", c.Points)
	player:SetAttribute("ConductLevel", level.Icon .. " " .. level.Name)
	local last = c.Log[#c.Log]
	player:SetAttribute("ConductLast", if last then last.Tx else nil)
	player:SetAttribute("ConductCount", #c.Log)
	player:SetAttribute("GroundedUntil", if grounded(c) then c.GroundedUntil else nil)
end

function ConductService.isMinor(player: Player): boolean
	return Conduct.isMinor(player:GetAttribute("LifeStage"))
end

function ConductService.points(player: Player): number
	local data = DataService.get(player)
	return if data then conductOf(data).Points else 0
end

function ConductService.isGrounded(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and grounded(conductOf(data))
end

---------------------------------------------------------------------
-- La familia se entera (solo menores)
---------------------------------------------------------------------
local function family(player: Player, data: { [string]: any }, c: { [string]: any }, kind: string, arrested: boolean)
	local F = Conduct.Family
	local story = lazy("LifeStoryService")
	if story then
		pcall(story.addRel, player, "Familia", if arrested then F.RelArrest else F.Rel)
		pcall(story.addAffinity, player, "Familia", F.Affinity)
		pcall(story.addRel, player, "Abu", math.ceil(F.Rel / 2))
	end
	-- Rebeldía (rasgo de la historia: cuenta para «el camino» del instituto)
	if type(data.Story) == "table" then
		data.Story.Traits = data.Story.Traits or {}
		data.Story.Traits.Rebeldia = (data.Story.Traits.Rebeldia or 0) + F.Rebeldia
		if story and story.updateCamino then
			pcall(story.updateCamino, player, data.Story)
		end
	end
	-- Castigo: se suma al que ya tuviera (con un máximo)
	local now = os.time()
	local left = math.max(0, ((tonumber(c.GroundedUntil) or 0) - now) / 60)
	c.GroundedUntil = now + Conduct.groundedAfter(left) * 60
	if story and story.logEvent then
		pcall(story.logEvent, player, if arrested then "La policía te trajo a casa" else "Tu familia se enteró: " .. textOf(kind), nil, "Moment")
	end
	-- Te llaman al móvil (si te trae la policía, te lo dicen en casa)
	if not arrested then
		local call = Conduct.Calls[(#c.Log - 1) % #Conduct.Calls + 1]
		Notify:FireClient(player, "Error", Strings.get(call, { familia = familyName(player), crimen = textOf(kind) }))
	end
end

-- Apunta algo en el historial. options.Arrested = la policía le trae a casa (menores).
function ConductService.note(player: Player, kind: string, options: { [string]: any }?)
	local data = DataService.get(player)
	if not data or type(kind) ~= "string" then
		return
	end
	local c = conductOf(data)
	local points = Conduct.pointsOf(kind)
	c.Points += points
	c.CalmAt = os.time()
	local stage = player:GetAttribute("LifeStage")
	table.insert(c.Log, { K = kind, Tx = textOf(kind), P = points, T = os.time(), S = stage })
	while #c.Log > Conduct.LogLimit do
		table.remove(c.Log, 1)
	end
	local level = Conduct.level(c.Points)
	Notify:FireClient(player, "Info", ("%s Historial: %s (+%d)"):format(level.Icon, textOf(kind), points))
	if Conduct.isMinor(stage) then
		family(player, data, c, kind, options ~= nil and options.Arrested == true)
	end
	publish(player, c)
	StoryEvents.emit(player, "ConductNoted", { Kind = kind, Points = c.Points })
end

---------------------------------------------------------------------
-- Menor detenido: a casa con su familia (en vez de juicio y prisión)
---------------------------------------------------------------------
local function homeSpot(player: Player): Vector3?
	local id = player:GetAttribute("FamilyHomeId")
	if id == nil then
		return nil
	end
	for _, model in CollectionService:GetTagged("FamilyHome") do
		if model:GetAttribute("HomeId") == id then
			local spot = model:FindFirstChild("Familia_Padre", true) or model:FindFirstChild("Room_Salon", true)
			if spot and spot:IsA("BasePart") then
				return (spot.CFrame * CFrame.new(0, 0, -4)).Position
			end
			return model:GetPivot().Position
		end
	end
	return nil
end
ConductService.homeSpot = homeSpot

function ConductService.takeHome(player: Player, crimes: { string }?)
	local vehicles = lazy("VehicleService")
	if vehicles and vehicles.exitAny then
		pcall(vehicles.exitAny, player, true)
	end
	ConductService.note(player, "Detenido", { Arrested = true })
	local crime = if crimes and crimes[1] then string.lower(crimes[1]) else "portarte así"
	Notify:FireClient(player, "Info", "🚓 La policía te lleva a casa con tu familia…")
	task.delay(ConductService.HomeDelay, function()
		if not player.Parent then
			return
		end
		local spot = homeSpot(player)
		if spot then
			local scene = lazy("SceneService")
			local ok = scene and scene.teleportTo and pcall(scene.teleportTo, player, spot)
			if not ok and player.Character then
				pcall(function()
					standUpBefore(player.Character)
					;(player.Character :: Model):PivotTo(CFrame.new(spot + Vector3.new(0, 3, 0)))
				end)
			end
		end
		-- La charla en casa
		local dialogue = lazy("DialogueService")
		local played = dialogue and dialogue.play and dialogue.play(player, { Lines = Conduct.HomeScene }, { args = { crimen = crime } })
		if not played then
			Notify:FireClient(player, "Error", ("🏠 %s: ¿Cómo que «%s»? ¡Estás castigado/a!"):format(familyName(player), crime))
		end
		local data = DataService.get(player)
		local left = if data then math.max(0, (tonumber(conductOf(data).GroundedUntil) or 0) - os.time()) else 0
		Notify:FireClient(player, "Info", ("🏠 Castigado/a %d min: sin paga y a casa antes de la noche."):format(math.ceil(left / 60)))
		StoryEvents.emit(player, "TakenHome", {})
	end)
end

---------------------------------------------------------------------
-- Paga, fin del castigo, toque de queda y portarse bien (cada pocos segundos)
---------------------------------------------------------------------
local curfewWarned: { [Player]: number } = {}

function ConductService.tick(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local c = conductOf(data)
	local now = os.time()
	-- Se acabó el castigo
	if c.GroundedUntil and not grounded(c) then
		c.GroundedUntil = nil
		Notify:FireClient(player, "Success", "🙂 Se acabó el castigo.")
	end
	-- Portarse bien borra puntos poco a poco
	local calm = Conduct.CalmMinutes * 60
	if c.Points > 0 and c.CalmAt and now - c.CalmAt >= calm then
		local steps = math.floor((now - c.CalmAt) / calm)
		c.Points = Conduct.calmed(c.Points, steps)
		c.CalmAt += steps * calm
		Notify:FireClient(player, "Success", "😇 Te estás portando bien: tu historial mejora.")
	end
	local minor = Conduct.isMinor(player:GetAttribute("LifeStage"))
	-- La paga (cada día de juego)
	local amount = Conduct.Family.Allowance[player:GetAttribute("LifeStage")]
	if minor and amount then
		if not c.PaidAt then
			c.PaidAt = now
		elseif now - c.PaidAt >= Config.DayLengthMinutes * 60 then
			c.PaidAt = now
			if grounded(c) then
				Notify:FireClient(player, "Error", "💶 Hoy no hay paga: estás castigado/a.")
			else
				DataService.addMoney(player, amount)
				Notify:FireClient(player, "Money", ("💶 %s te da la paga: %s"):format(familyName(player), Format.money(amount)))
			end
		end
	end
	-- Castigado y de noche fuera de casa: te llaman
	if minor and grounded(c) and Conduct.curfew(Lighting.ClockTime) and now - (curfewWarned[player] or 0) >= 90 then
		local spot = homeSpot(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if spot and root and (root.Position - spot).Magnitude > 80 then
			curfewWarned[player] = now
			Notify:FireClient(player, "Error", ("📱 %s: ¡Estás castigado/a! A casa, que ya es de noche."):format(familyName(player)))
		end
	end
	publish(player, c)
end

function ConductService.init()
	DataService.onLoaded(function(player, data)
		local c = conductOf(data)
		-- El castigo solo corre mientras juegas: se corre el tiempo que estuvo desconectado
		local away = if DataService.offlineSeconds then DataService.offlineSeconds(player) else 0
		local groundedUntil = tonumber(c.GroundedUntil)
		if groundedUntil and groundedUntil > 0 and away > 0 then
			c.GroundedUntil = groundedUntil + away
		end
		publish(player, c)
	end)
	StoryEvents.connect(function(player: Player, name: string, payload: { [string]: any })
		if name == "Crime" or name == "Misbehaved" then
			if type(payload.Crime) == "string" then
				ConductService.note(player, payload.Crime)
			end
		elseif name == "Vandalism" then
			ConductService.note(player, "Vandalismo")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		curfewWarned[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(ConductService.tick, player)
				if not ok then
					warn("[Conduct] " .. tostring(err))
				end
			end
		end
	end)
end

return ConductService
