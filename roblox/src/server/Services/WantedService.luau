-- WantedService: delitos, testigos y nivel de búsqueda (estrellas) — reglas en shared/Wanted.
--
-- Delitos que se detectan:
--   * Pegar a una persona (CombatService) y dejarla K.O.
--   * Robar dinero a otro jugador (comando ROBAR del menú, junto a él)
--   * Atracar una tienda (cartel "Atracar" en las tiendas, mantener pulsado)
--   * Agredir a un agente de policía
--   * Disparar a una persona o disparar en plena calle (WeaponService; la policía de servicio
--     contra alguien buscado, no)
-- Un delito solo suma estrellas si lo VE la policía (shared/Witness: cono de visión, alcance y nada
-- en medio; agentes, patrullas, helicóptero, policías jugadores de servicio, agentes de la invasión).
-- Un disparo que OYE la policía la hace venir a investigar (si te ve en ese rato, estrellas). Sin
-- policía: impune en el momento… pero un civil que lo ve puede GRABARTE con el móvil y denunciarte:
-- la policía busca entonces a alguien con TU ROPA (si un agente te ve así vestido, te reconoce;
-- cámbiate de ropa). En un atraco te graba la cámara de la tienda. Atacar a la invasión nunca es
-- delito. Las denuncias son de la sesión (no se guardan). Atropellar a alguien (KnockService) solo cuenta si es culpa tuya (shared/Crossing)
-- y lo ve la policía en ese momento (options.PoliceOnly): ni la víctima ni los testigos llaman.
-- Mientras te buscan: más estrellas = más patrullas (PoliceUnits). Si ningún policía te ve durante
-- Wanted.evadeSeconds, te libras. Si te alcanzan: detenido, multa y comisaría.
-- Un policía jugador de servicio también puede detenerte (comando DETENER, junto a ti).
-- Al detenerte pasas a disposición judicial (JusticeService): juicio o sentencia automática.
-- Si eres menor (niño o adolescente), no: la policía te lleva a casa con tu familia (ConductService).
--
-- Al volante (checkDrivers, cada medio segundo): conducir sin el carnet que toca, o siendo menor,
-- solo es delito si te ve la policía (una patrulla de ronda, agentes o un policía jugador de
-- servicio a menos de Wanted.DriveSight y sin nada en medio). Entonces: «¡Alto!», la patrulla
-- enciende la sirena y te sigue, y 1 estrella. Si Wanted.StopSeconds después sigues conduciendo,
-- huida (+1). Si paras, bajan los agentes y te detienen. Modo pruebas con «Sin requisitos»: ni la
-- edad ni el carnet cuentan al volante (forgiveDriving); los delitos de verdad, sí (answersAsAdult).
-- Lo que se sabe de ti también va a tu historial de comportamiento (ConductService).
-- Las estrellas se guardan: salir del juego no borra la búsqueda.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Business = require(ReplicatedStorage.Shared.Business)
local Movement = require(ReplicatedStorage.Shared.Movement)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local PoliceUnits = require(script.Parent.Parent.World.PoliceUnits)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService) -- (hoja: sin dependencias circulares)
local JusticeService = require(script.Parent.JusticeService)
local CareerService = require(script.Parent.CareerService)
local VehicleService = require(script.Parent.VehicleService)
local ConductService = require(script.Parent.ConductService)
local Conduct = require(ReplicatedStorage.Shared.Conduct)
local Witness = require(ReplicatedStorage.Shared.Witness)

local WantedService = {}

type Stop = { At: number, Crime: string, Fled: boolean }
type Suspect = { Crime: string, At: Vector3, Until: number }
type State = { Stars: number, LastSeen: number, LastPosition: Vector3?, CatchSince: number?, StealAt: number, Arresting: boolean, Crimes: { string }, CrimeKeys: { string }?, Stop: Stop?, MisbehavedAt: number?, TesterAgeNoted: boolean?, NpcHits: { [Model]: number }?, Reports: { Witness.Report }?, Suspect: Suspect? }

local states: { [Player]: State } = {}
-- Pausas contra el abuso: un atraco cada HEIST_GAP por jugador y a la misma víctima no se le roba
-- más de una vez cada VICTIM_GAP (antes se podía ir de tienda en tienda o robar sin parar)
local HEIST_GAP = 300
local VICTIM_GAP = 300
-- Disparar a un personaje (NPC): una denuncia por víctima como mucho cada tanto (una ráfaga no son 5★)
local NPC_HIT_GAP = 8
-- (por UserId: salir y volver a entrar no reinicia la pausa)
local heistAt: { [number]: number } = {}
local robbedAt: { [number]: { [number]: number } } = {}
local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = { Stars = 0, LastSeen = 0, StealAt = -math.huge, Arresting = false, Crimes = {} }
		states[player] = state
	end
	return state
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function oldEnough(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return stage == nil or Stages.inRange(stage, Wanted.MinStage, nil)
end

-- ¿Cuentan sus delitos como los de un mayor? Modo pruebas con «Sin requisitos»: la edad no cuenta
-- ni para llevar un arma de verdad ni para librarse de la policía (antes un niño tester podía
-- disparar con un subfusil y solo salía «Si fueras mayor, vendría la policía»).
local MINOR_LABEL = { Bebe = "un bebé", Nino = "un niño", Adolescente = "adolescente" }
local function answersAsAdult(player: Player): boolean
	return oldEnough(player) or TesterService.bypass(player)
end

local function onDuty(player: Player): boolean
	return player:GetAttribute("Job") == "Policia"
end

-- Preso, en un juicio o muerto: la policía no viene a por ti (ya está la justicia)
local function outOfReach(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil or player:GetAttribute("Dead") ~= nil
end

local function setStars(player: Player, stars: number)
	local state = stateOf(player)
	state.Stars = stars
	if stars <= 0 then
		state.Stop = nil -- (sin búsqueda, un nuevo «¡Alto!» vuelve a contar)
	end
	player:SetAttribute("Wanted", if stars > 0 then stars else nil)
	player:SetAttribute("WantedSearching", nil)
	local data = DataService.get(player)
	if data then
		data.Wanted = if stars > 0 then stars else nil
	end
	if stars > 0 then
		PoliceUnits.ensure(player, stars)
	else
		PoliceUnits.dismiss(player)
	end
end

---------------------------------------------------------------------
-- Testigos
---------------------------------------------------------------------

-- ¿Quién puede ver un delito? (shared/Witness: cono de visión, alcance y nada en medio)
--   * policías jugadores de servicio (hacia donde miran)
--   * agentes, coches y helicópteros de las persecuciones y patrullas de ronda (PoliceUnits.observers)
--   * los agentes del cordón de la invasión (InvasionService: WantedService.extraOfficers)
-- Solo se mira cuando pasa algo (un delito, o cada medio segundo para quien tiene una denuncia o una
-- investigación abierta): nunca cada fotograma.
type Observer = { Eye: Vector3, Look: Vector3?, Range: number, Cop: Player? }

-- (InvasionService) ¿hay alienígenas cerca de este punto? y los agentes del cordón
WantedService.aliensNear = nil :: ((Vector3) -> boolean)?
WantedService.extraOfficers = nil :: (() -> { Model })?

local function sightIgnore(offender: Player?): { Instance }
	local ignore: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	-- (los vehículos no tapan: se ve por las ventanillas; ni la propia policía ni los alienígenas)
	for _, name in { "Rides", "Buses", "PoliceResponse", "Invasion" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	return ignore
end

local function caster(offender: Player?): (Vector3, Vector3, { any }) -> any?
	local base = sightIgnore(offender)
	return function(from: Vector3, to: Vector3, skip: { any }): any?
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local list = table.clone(base)
		for _, s in skip do
			table.insert(list, s)
		end
		-- (la gente no tapa la vista: un personaje en medio se atraviesa)
		for _ = 1, 4 do
			params.FilterDescendantsInstances = list
			local hit = workspace:Raycast(from, to - from, params)
			local part = hit and hit.Instance
			local person = part and part:FindFirstAncestorWhichIsA("Model")
			if person and person:FindFirstChildOfClass("Humanoid") then
				table.insert(list, person)
				continue
			end
			return part
		end
		return nil
	end
end
WantedService.caster = caster

local function observers(offender: Player?, near: Vector3, within: number?): { Observer }
	local list: { Observer } = {}
	local reach = within or Witness.SightRange
	for _, cop in Players:GetPlayers() do
		local r = rootOf(cop)
		if cop ~= offender and onDuty(cop) and r and (r.Position - near).Magnitude <= reach then
			table.insert(list, { Eye = r.Position + Vector3.new(0, 1.5, 0), Look = r.CFrame.LookVector, Range = Witness.SightRange, Cop = cop })
		end
	end
	local okUnits, units = pcall(function()
		return PoliceUnits.observers(near, reach)
	end)
	if okUnits and type(units) == "table" then
		for _, o in units do
			table.insert(list, o)
		end
	end
	local extra = WantedService.extraOfficers
	if extra then
		local okExtra, models = pcall(extra)
		for _, model in if okExtra and type(models) == "table" then models else {} do
			local root = model.PrimaryPart
			if root and model.Parent and not model:GetAttribute("Down") and (root.Position - near).Magnitude <= reach then
				table.insert(list, { Eye = root.Position + Vector3.new(0, 1.5, 0), Look = root.CFrame.LookVector, Range = Witness.SightRange })
			end
		end
	end
	return list
end

-- ¿Ve la policía este sitio AHORA? Devuelve quién (o nil). Avisa al policía jugador que lo ve.
local function policeSees(offender: Player, position: Vector3, what: string?): Observer?
	local cast = caster(offender)
	local target = position + Vector3.new(0, 1.5, 0)
	for _, o in observers(offender, position) do
		if Witness.sees(o.Eye, o.Look, target, o.Range, cast) then
			if o.Cop then
				Notify:FireClient(o.Cop, "Info", ("🚨 Has visto un delito: %s%s"):format(offender.DisplayName, if what then " (" .. what .. ")" else ""))
			end
			return o
		end
	end
	return nil
end
WantedService.policeSeesAt = policeSees

-- ¿Ve la policía AHORA? (delitos que solo cuentan si los ve: options.PoliceOnly, los atropellos)
-- Lo de policeSees y, al volante, las patrullas de ronda (PoliceUnits.seesDriver, a Wanted.DriveSight).
function WantedService.policeWitness(offender: Player, position: Vector3): boolean
	if policeSees(offender, position) then
		return true
	end
	local seen = PoliceUnits.seesDriver(offender, Wanted.DriveSight)
	return seen == true
end

-- ¿Oye la policía un disparo hecho en `at`? (no hace falta verlo; dentro de un edificio o con
-- silenciador se oye menos lejos). Devuelve el que lo oye.
local function policeHears(offender: Player, at: Vector3, indoors: boolean, suppressed: boolean): Observer?
	local range = Witness.hearRange(indoors, suppressed)
	local best, bestD = nil, math.huge
	for _, o in observers(offender, at, range) do
		local d = (o.Eye - at).Magnitude
		if d <= range and d < bestD then
			best, bestD = o, d
		end
	end
	return best
end

-- Un personaje cercano que lo ha visto (solo para que tu familia se entere si eres menor)
local function witnessNear(offender: Player, position: Vector3): Model?
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { offender.Character :: Instance }
	local best, bestDistance = nil, math.huge
	-- Agachado o tumbado se te ve menos: los testigos tienen que estar más cerca
	local radius = Wanted.WitnessRadius * Movement.witnessFactor(offender:GetAttribute("Stance"))
	for _, part in workspace:GetPartBoundsInRadius(position, radius, params) do
		local model = part.Parent
		if model and model:IsA("Model") and part.Name == "HumanoidRootPart" and not Players:GetPlayerFromCharacter(model) and not model:GetAttribute("Officer") then
			local distance = (part.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = model, distance
			end
		end
	end
	return best
end

---------------------------------------------------------------------
-- La ropa (para las denuncias): qué llevas puesto, como una clave
---------------------------------------------------------------------
local function colorKey(c: any): string
	if typeof(c) ~= "Color3" then
		return "-"
	end
	return ("%d,%d,%d"):format(math.floor(c.R * 15 + 0.5), math.floor(c.G * 15 + 0.5), math.floor(c.B * 15 + 0.5))
end

local vehicleIds: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local vehicleSerial = 0

-- Lo que llevas: camiseta y pantalón (plantilla y color), accesorios (gorros, máscaras…) y las piezas
-- de ropa de Valmar (carpeta ValmarLook: OutfitBuilder). Y el vehículo en el que vas (si vas en uno).
local function outfitOf(player: Player): ({ string }, string?, string)
	local items: { string } = {}
	local names: { string } = {}
	local character = player.Character
	if not character then
		return items, nil, ""
	end
	for _, d in character:GetDescendants() do
		if d:IsA("Shirt") then
			table.insert(items, "Shirt:" .. tostring((d :: any).ShirtTemplate) .. ":" .. colorKey((d :: any).Color3))
		elseif d:IsA("Pants") then
			table.insert(items, "Pants:" .. tostring((d :: any).PantsTemplate) .. ":" .. colorKey((d :: any).Color3))
		elseif d:IsA("ShirtGraphic") then
			table.insert(items, "Graphic:" .. tostring((d :: any).Graphic))
		elseif d:IsA("Accessory") then
			table.insert(items, "Acc:" .. d.Name)
			table.insert(names, d.Name)
		end
	end
	local look = character:FindFirstChild("ValmarLook")
	if look then
		for _, p in look:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(items, "Look:" .. p.Name .. ":" .. colorKey((p :: any).Color))
				table.insert(names, p.Name)
			end
		end
	end
	local vehicle: string? = nil
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local ride = seat and seat:FindFirstAncestorWhichIsA("Model")
	if ride then
		if not vehicleIds[ride] then
			vehicleSerial += 1
			vehicleIds[ride] = vehicleSerial
		end
		vehicle = ride.Name .. "#" .. vehicleIds[ride]
	end
	return items, vehicle, table.concat(names, ",")
end
function WantedService.outfitKey(player: Player): string
	local items = outfitOf(player)
	return Witness.outfitKey(items)
end

---------------------------------------------------------------------
-- Estrellas
---------------------------------------------------------------------
-- Suma estrellas por un delito ya denunciado (stars: las de una denuncia, menos que en el acto)
local function report(player: Player, crime: string, how: string, stars: number?)
	if not player.Parent or outOfReach(player) then
		return -- (el aviso llega tarde: ya estás preso, en un juicio o muerto)
	end
	local state = stateOf(player)
	local before = state.Stars
	local after = if stars then math.clamp(before + stars, 0, Wanted.MaxStars) else Wanted.starsAfter(before, crime)
	table.insert(state.Crimes, Wanted.Crimes[crime].Text)
	state.CrimeKeys = state.CrimeKeys or {}
	table.insert(state.CrimeKeys :: { string }, crime)
	state.LastSeen = os.clock()
	local r = rootOf(player)
	state.LastPosition = r and r.Position
	setStars(player, after)
	PoliceUnits.setTarget(player, state.LastPosition)
	Remote:FireClient(player, "Crime", { Crime = Wanted.Crimes[crime].Text, How = how, Stars = after, Before = before })
	StoryEvents.emit(player, "Crime", { Crime = crime, Stars = after })
end

---------------------------------------------------------------------
-- Denuncias (un civil te ha grabado): la policía busca a alguien vestido así
---------------------------------------------------------------------
local function publishReports(player: Player, state: State)
	local list = state.Reports or {}
	player:SetAttribute("WantedReport", if #list > 0 then #list else nil)
end

local function addReport(player: Player, crime: string, at: Vector3?, key: string?, vehicle: string?, source: string)
	if not player.Parent or outOfReach(player) then
		return
	end
	local state = stateOf(player)
	local now = os.clock()
	local def = Wanted.Crimes[crime]
	local list = Witness.prune(state.Reports or {}, now)
	table.insert(list, Witness.newReport(crime, def and def.Stars or 1, key, vehicle, at, now, def and def.Text))
	state.Reports = Witness.prune(list, now)
	publishReports(player, state)
	Remote:FireClient(player, "Report", { Crime = def and def.Text, Source = source, Clear = key ~= nil or vehicle ~= nil })
	if key or vehicle then
		Notify:FireClient(player, "Error", "📱 Te han denunciado a la policía con un vídeo: te buscan por tu ropa. Cámbiate de ropa.")
	else
		Notify:FireClient(player, "Info", "📱 Te han grabado, pero con la cara tapada no se te reconoce.")
	end
end
WantedService.addReport = addReport

function WantedService.reports(player: Player): { Witness.Report }
	local state = stateOf(player)
	state.Reports = Witness.prune(state.Reports or {}, os.clock())
	return state.Reports :: { Witness.Report }
end

-- ¿Te reconoce la policía por una denuncia? (cada medio segundo, solo si tienes alguna)
local function checkReports(player: Player, state: State)
	local list = state.Reports
	if not list or #list == 0 then
		return
	end
	local now = os.clock()
	local fresh = Witness.prune(list, now)
	if #fresh ~= #list then
		state.Reports = fresh
		publishReports(player, state)
		if #fresh == 0 then
			Remote:FireClient(player, "ReportExpired", {})
		end
	end
	local r = rootOf(player)
	if #fresh == 0 or not r or state.Arresting or outOfReach(player) or player:GetAttribute("InteriorKey") then
		return
	end
	local items, vehicle = outfitOf(player)
	local match = Witness.matching(fresh, Witness.outfitKey(items), vehicle, now)
	if not match then
		return -- (vas con otra ropa: no te reconocen)
	end
	if not policeSees(player, r.Position, "reconocido por una denuncia") then
		return
	end
	local i = table.find(fresh, match)
	if i then
		table.remove(fresh, i)
	end
	state.Reports = fresh
	publishReports(player, state)
	Notify:FireClient(player, "Error", "👮 ¡Un agente te ha reconocido por la denuncia (tu ropa)!")
	report(player, match.Crime, "Recognised", match.Stars)
end
WantedService.checkReports = function(player: Player)
	checkReports(player, stateOf(player))
end

---------------------------------------------------------------------
-- Civiles que lo ven: graban con el móvil (y denuncian) o huyen
---------------------------------------------------------------------
local filmingNow = 0

-- En plena escena, cinemática o conversación de la historia nadie graba
local function storyBusy(player: Player): boolean
	return player:GetAttribute("InDialogue") == true or player:GetAttribute("InPrologue") == true or player:GetAttribute("SceneId") ~= nil or player:GetAttribute("InCinematic") == true
end

local function crowd(): any
	local ok, service = pcall(function()
		return require(script.Parent.CrowdService) :: any
	end)
	return if ok then service else nil
end

-- Los civiles que lo VEN (cono, alcance, nada en medio), los más cercanos primero
local function civilianWitnesses(offender: Player, position: Vector3): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { offender.Character :: Instance }
	local radius = Witness.CivilianSight * Movement.witnessFactor(offender:GetAttribute("Stance"))
	local cast = caster(offender)
	local found: { [Model]: number } = {}
	local target = position + Vector3.new(0, 1.5, 0)
	for _, part in workspace:GetPartBoundsInRadius(position, radius, params) do
		local model = part.Parent
		if model and model:IsA("Model") and part.Name == "HumanoidRootPart" and not found[model] and model:GetAttribute("Crowd") ~= nil and not Players:GetPlayerFromCharacter(model) then
			local blocked = model:GetAttribute("Officer") or model:GetAttribute("InvasionTarget") ~= nil or model:GetAttribute("MissionEnemy") ~= nil or model:GetAttribute("Leaving") or model:GetAttribute("Panic") or model:GetAttribute("Filming")
			if not blocked then
				local p = part :: BasePart
				local eye = p.Position + Vector3.new(0, 1.5, 0)
				if Witness.sees(eye, p.CFrame.LookVector, target, radius, cast) then
					found[model] = (p.Position - position).Magnitude
				end
			end
		end
	end
	local list = {}
	for model in found do
		table.insert(list, model)
	end
	table.sort(list, function(a, b)
		return found[a] < found[b]
	end)
	return list
end
WantedService.civilianWitnesses = civilianWitnesses

local function setFilmed(player: Player, delta: number)
	local n = math.max(0, (tonumber(player:GetAttribute("Filmed")) or 0) + delta)
	player:SetAttribute("Filmed", if n > 0 then n else nil)
end

-- Te graba: saca el móvil y te mira unos segundos. Si te vas de su vista (o te acercas mucho y se
-- asusta) no acaba; si acaba, denuncia poco después con la descripción de tu ropa.
local function film(npc: Model, offender: Player, crime: string, at: Vector3)
	filmingNow += 1
	local work = npc:GetAttribute("Work")
	npc:SetAttribute("Filming", offender.UserId)
	pcall(Npc.work, npc, "Phone")
	setFilmed(offender, 1)
	Remote:FireClient(offender, "Filming", { On = true })
	pcall(Npc.say, npc, "📱 ¡Te estoy grabando!", 2.5)
	local cast = caster(offender)
	local done, scared = false, false
	local t = 0
	while t < Witness.FilmSeconds do
		task.wait(0.25)
		t += 0.25
		local root = npc.PrimaryPart
		local r = rootOf(offender)
		if not npc.Parent or not root or not r or not offender.Parent or storyBusy(offender) then
			break
		end
		pcall(Npc.face, npc, r.Position)
		if (r.Position - root.Position).Magnitude <= Witness.ScareDistance then
			scared = true
			break
		end
		-- (mientras graba te sigue con el móvil: mira hacia ti; solo cuenta la distancia y la pared)
		if not Witness.sees(root.Position + Vector3.new(0, 1.5, 0), nil, r.Position + Vector3.new(0, 1.5, 0), Witness.CivilianSight * 1.2, cast) then
			break
		end
		if t >= Witness.FilmSeconds then
			done = true
		end
	end
	filmingNow -= 1
	setFilmed(offender, -1)
	Remote:FireClient(offender, "Filming", { On = false, Done = done })
	if npc.Parent then
		npc:SetAttribute("Filming", nil)
		pcall(Npc.work, npc, work)
	end
	if scared then
		pcall(Npc.say, npc, "¡Vale, vale! ¡Ya paro!", 2)
		local c = crowd()
		if c and c.scare then
			pcall(c.scare, npc)
		end
		return
	end
	if not done then
		return
	end
	-- Lo que se ve en el vídeo: tu ropa (si no llevas la cara tapada) y el vehículo
	local items, vehicle, names = outfitOf(offender)
	local masked = Witness.masked({ names })
	local identified = Witness.identifies(masked, math.random())
	local key = if identified then Witness.outfitKey(items) else nil
	task.delay(Witness.ReportDelay, function()
		if npc.Parent then
			pcall(Npc.say, npc, "📞 Ya he mandado el vídeo a la policía.", 2.5)
		end
		addReport(offender, crime, at, key, if identified then vehicle else nil, "Video")
	end)
end
WantedService.film = film

local function civiliansReact(offender: Player, crime: string, at: Vector3)
	if storyBusy(offender) then
		return
	end
	local def = Wanted.Crimes[crime]
	local stars = def and def.Stars or 1
	for i, npc in civilianWitnesses(offender, at) do
		if i > 3 then
			break
		end
		local reaction = Witness.civilianReaction(stars, math.random())
		if reaction == "Film" and filmingNow < Witness.MaxFilming then
			task.spawn(film, npc, offender, crime, at)
			return -- (con uno que grabe basta)
		elseif reaction == "Flee" then
			pcall(Npc.say, npc, "¡Socorro!", 1.5)
			local c = crowd()
			if c and c.scare then
				pcall(c.scare, npc)
			end
		end
	end
end

---------------------------------------------------------------------
-- La policía oye disparos: viene a mirar
---------------------------------------------------------------------
local function investigate(offender: Player, crime: string, at: Vector3)
	local state = stateOf(offender)
	state.Suspect = { Crime = crime, At = at, Until = os.clock() + Witness.InvestigateSeconds }
	offender:SetAttribute("PoliceInvestigating", true)
	pcall(PoliceUnits.investigate, offender, at, Witness.InvestigateSeconds)
	Remote:FireClient(offender, "Investigate", { At = at })
end

local function checkSuspect(player: Player, state: State)
	local s = state.Suspect
	if not s then
		return
	end
	local r = rootOf(player)
	if os.clock() > s.Until or state.Stars > 0 or outOfReach(player) then
		state.Suspect = nil
		player:SetAttribute("PoliceInvestigating", nil)
		if state.Stars <= 0 then
			PoliceUnits.dismiss(player)
		end
		return
	end
	if r and not player:GetAttribute("InteriorKey") and policeSees(player, r.Position, "sospechoso de los disparos") then
		state.Suspect = nil
		player:SetAttribute("PoliceInvestigating", nil)
		report(player, s.Crime, "Police")
	end
end
WantedService.checkSuspect = function(player: Player)
	checkSuspect(player, stateOf(player))
end

---------------------------------------------------------------------
-- Un delito: ¿lo ve la policía? ¿lo oye? ¿lo graba alguien?
---------------------------------------------------------------------
-- options.Gun = true: es un disparo (se oye); options.Suppressed: con silenciador
-- options.Alien = true: era contra la invasión (nunca es delito)
-- options.Alarm = true: la alarma de la prisión (Fuga) avisa siempre; la de una tienda graba con su
--   cámara (una denuncia con tu ropa), no trae estrellas por sí sola
-- options.PoliceOnly = true: solo si lo ve la policía EN ESE MOMENTO (atropellos; sin civiles que graben)
-- options.Witness: (antes) la víctima que llamaba; ahora la víctima es un civil más que puede grabarte
function WantedService.crime(player: Player, crime: string, position: Vector3?, options: { [string]: any }?): boolean?
	if not Wanted.Crimes[crime] or not player.Parent then
		return false
	end
	local at = position or (rootOf(player) and (rootOf(player) :: BasePart).Position)
	-- Defender Valmar de la invasión nunca es delito (ni las balas perdidas cerca de los alienígenas)
	local near = false
	local hook = WantedService.aliensNear
	if hook and at then
		local okNear, result = pcall(hook, at)
		near = okNear and result == true
	end
	if Witness.alienExempt(crime, { Alien = options ~= nil and options.Alien == true, AliensNear = near }) then
		return false
	end
	if options and options.PoliceOnly then
		if not at or not Wanted.appliesTo(crime, answersAsAdult(player)) or player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
			return false
		end
		if WantedService.policeWitness(player, at) then
			report(player, crime, "Police")
			return true
		end
		return false
	end
	if not Wanted.appliesTo(crime, answersAsAdult(player)) then
		Notify:FireClient(player, "Error", "¡Eso no se hace! Si fueras mayor, vendría la policía.")
		-- Si alguien lo ha visto, tu familia se entera (historial de comportamiento)
		local state = stateOf(player)
		if at and os.clock() - (state.MisbehavedAt or -math.huge) > 20 and (witnessNear(player, at) or policeSees(player, at)) then
			state.MisbehavedAt = os.clock()
			StoryEvents.emit(player, "Misbehaved", { Crime = crime })
		end
		return
	end
	if player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return -- dentro de la cárcel (o en un juicio) no viene la policía
	end
	if not at then
		return
	end
	if not oldEnough(player) and not Wanted.appliesTo(crime, false) then
		-- (solo llega aquí un tester menor con «Sin requisitos»: se le explica una vez)
		local state = stateOf(player)
		if not state.TesterAgeNoted then
			state.TesterAgeNoted = true
			Notify:FireClient(player, "Info", ("🧪 Modo pruebas: aunque eres %s, con «Sin requisitos» tus delitos cuentan como los de un adulto (viene la policía)."):format(MINOR_LABEL[player:GetAttribute("LifeStage")] or "menor"))
		end
	end
	-- La prisión: la alarma avisa a la policía (la cárcel es suya)
	if options and options.Alarm and crime == "Fuga" then
		task.delay(Wanted.CallDelay, report, player, crime, "Alarm")
		return true
	end
	-- 1) Lo ve la policía (o es un agente al que agredes: te está viendo)
	if crime == "AgresionPolicia" or policeSees(player, at, Wanted.Crimes[crime].Text) then
		report(player, crime, "Police")
		return true
	end
	-- 2) Un disparo que oye la policía: viene a investigar (si te ve en ese rato, estrellas)
	if Witness.isGunCrime(crime, options) then
		local indoors = player:GetAttribute("InteriorKey") ~= nil
		if policeHears(player, at, indoors, options ~= nil and options.Suppressed == true) then
			investigate(player, crime, at)
		end
	end
	-- 3) La cámara de la tienda (atraco): te graba siempre
	if options and options.Alarm then
		local items, vehicle = outfitOf(player)
		local key = Witness.outfitKey(items)
		task.delay(Wanted.CallDelay, addReport, player, crime, at, key, vehicle, "Camera")
		return false
	end
	-- 4) Civiles que lo ven: alguno te graba y te denuncia (o huye). Sin policía, impune por ahora.
	civiliansReact(player, crime, at)
	return false
end

-- (InvasionService) quien ayuda a tumbar alienígenas: si solo le buscaban por disparos sin víctima o
-- daños (cosas «de la defensa»), la policía lo deja estar
function WantedService.defended(player: Player)
	local state = stateOf(player)
	if state.Stars <= 0 or state.Arresting then
		return
	end
	local keys = state.CrimeKeys or {}
	if #keys == 0 then
		return
	end
	for _, key in keys do
		if not Witness.DefenseCrimes[key] then
			return
		end
	end
	state.Crimes = {}
	state.CrimeKeys = {}
	setStars(player, 0)
	Notify:FireClient(player, "Success", "🛡️ Estás defendiendo Valmar: la policía retira la búsqueda por los disparos.")
end

---------------------------------------------------------------------
-- Detención
---------------------------------------------------------------------
function WantedService.arrest(player: Player, cop: Player?)
	local state = stateOf(player)
	if state.Stars <= 0 or state.Arresting or outOfReach(player) then
		return
	end
	state.Arresting = true
	-- Se programa antes de nada: aunque algo de abajo falle, la detención nunca se queda "a medias" para siempre
	task.delay(4, function()
		state.Arresting = false
		state.CatchSince = nil
	end)
	local stars = state.Stars
	local crimes = state.Crimes
	state.Crimes = {}
	state.CrimeKeys = {}
	if cop then
		DataService.addMoney(cop, Wanted.ArrestReward * stars, true)
		Notify:FireClient(cop, "Success", ("🚔 Has detenido a %s: +%s"):format(player.DisplayName, Format.money(Wanted.ArrestReward * stars)))
		StoryEvents.emit(cop, "JobTaskDone", { JobId = "Policia" })
		CareerService.addPoints(cop, "Policia", "Arrest")
	end
	setStars(player, 0)
	local minor = Conduct.isMinor(player:GetAttribute("LifeStage"))
	Remote:FireClient(player, "Busted", { Stars = stars, By = cop and cop.DisplayName, Minor = minor, Crimes = crimes })
	StoryEvents.emit(player, "Arrested", { Stars = stars, Minor = minor })
	-- Del vehículo, abajo (y el vehículo se queda parado)
	pcall(VehicleService.exitAny, player, true)
	if minor then
		-- Un niño o un adolescente no va a juicio: a casa con su familia
		ConductService.takeHome(player, crimes)
	else
		-- A disposición judicial: juicio (si hay juez de guardia) o sentencia automática
		JusticeService.process(player, stars, if #crimes > 0 then crimes else { "Resistencia a la autoridad" })
	end
end

---------------------------------------------------------------------
-- Robar a una persona
---------------------------------------------------------------------
local function steal(thief: Player, victim: any)
	if typeof(victim) ~= "Instance" or not victim:IsA("Player") or victim == thief then
		return
	end
	local state = stateOf(thief)
	local tr, vr = rootOf(thief), rootOf(victim)
	if not tr or not vr or (tr.Position - vr.Position).Magnitude > Wanted.StealRange then
		return
	end
	if not oldEnough(thief) then
		Notify:FireClient(thief, "Error", "Aún no tienes edad para esto.")
		return
	end
	if os.clock() - state.StealAt < Wanted.StealCooldown then
		Notify:FireClient(thief, "Error", "Espera un poco antes de volver a intentarlo.")
		return
	end
	if victim:GetAttribute("InDialogue") or victim:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	-- Los dos en el mismo sitio (misma casa o edificio, o los dos en la calle): acercarse
	-- teletransportándose a otro interior no vale
	if thief:GetAttribute("InteriorKey") ~= victim:GetAttribute("InteriorKey") then
		return
	end
	-- Recién aparecido, sentado (en un vehículo o una silla) o en una zona segura: no se le roba
	local CombatService = require(script.Parent.CombatService) :: any
	local WeaponService = require(script.Parent.WeaponService) :: any
	if CombatService.isProtected(victim) or WeaponService.safeSpot(vr.Position) or WeaponService.safeSpot(tr.Position) then
		Notify:FireClient(thief, "Error", "Aquí no puedes robar.")
		return
	end
	local mine = robbedAt[thief.UserId]
	if mine and os.clock() - (mine[victim.UserId] or -math.huge) < VICTIM_GAP then
		Notify:FireClient(thief, "Error", "A esta persona ya le has robado hace poco.")
		return
	end
	-- En la cárcel o en un juicio no se roba (dentro no viene la policía: saldría gratis)
	if thief:GetAttribute("JailUntil") or thief:GetAttribute("OnTrial") or victim:GetAttribute("JailUntil") or victim:GetAttribute("OnTrial") then
		Notify:FireClient(thief, "Error", "Aquí no puedes robar.")
		return
	end
	state.StealAt = os.clock()
	robbedAt[thief.UserId] = robbedAt[thief.UserId] or {}
	robbedAt[thief.UserId][victim.UserId] = os.clock()
	local data = DataService.get(victim)
	local amount = Wanted.stealAmount(if data then data.Money else 0)
	if amount <= 0 then
		Notify:FireClient(thief, "Info", victim.DisplayName .. " no lleva dinero encima.")
	else
		DataService.addMoney(victim, -amount)
		DataService.addMoney(thief, amount)
		Notify:FireClient(thief, "Success", ("💸 Le has quitado %s a %s"):format(Format.money(amount), victim.DisplayName))
		Notify:FireClient(victim, "Error", ("💸 ¡%s te ha robado %s!"):format(thief.DisplayName, Format.money(amount)))
	end
	WantedService.crime(thief, "Robo", tr.Position)
end

---------------------------------------------------------------------
-- Atracar tiendas
---------------------------------------------------------------------
local function setupHeist(entrance: Instance)
	if not entrance:IsA("BasePart") or entrance:FindFirstChild("HeistPrompt") then
		return
	end
	-- (las tiendas de Tefra no se atracan: allí no hay policía de Valmar que te persiga)
	if entrance:GetAttribute("NoHeist") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HeistPrompt"
	prompt.ActionText = "Atracar"
	prompt.ObjectText = "🔫 Caja de la tienda"
	prompt.HoldDuration = Wanted.HeistHold
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	-- Teclas libres: V es fijar objetivo y el Y del mando, tirar piedras. Y no la usa nada; X del
	-- mando es la de siempre de los carteles (el menú de comandos reparte si coincide con otro)
	prompt.KeyboardKeyCode = Enum.KeyCode.Y
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("MinStage", Wanted.MinStage) -- (solo lo ven los mayores; JobPrompts)
	-- Tu propia tienda (eres el dueño o trabajas en ella: atributo BusinessStaff de BusinessService) no
	-- se atraca: el cartel no te sale (JobPrompts) y el servidor tampoco te deja
	prompt:SetAttribute("StaffOff", true)
	prompt.Parent = entrance
	prompt.Triggered:Connect(function(player)
		if not oldEnough(player) or outOfReach(player) then
			return
		end
		if Business.isStaff(entrance:GetAttribute("BusinessStaff"), player.UserId) then
			Notify:FireClient(player, "Info", "🏪 Es tu tienda: aquí no se atraca.")
			return
		end
		-- Con la policía ya detrás no se encadenan atracos, y cada jugador tiene su pausa
		-- (si no, se iba de tienda en tienda vaciando cajas)
		if stateOf(player).Stars >= 1 then
			Notify:FireClient(player, "Error", "Te está buscando la policía: no es momento de atracar.")
			return
		end
		if os.clock() - (heistAt[player.UserId] or -math.huge) < HEIST_GAP then
			Notify:FireClient(player, "Error", "Demasiado pronto para otro atraco: espera un rato.")
			return
		end
		local now = os.time()
		if (entrance:GetAttribute("RobbedUntil") or 0) > now then
			Notify:FireClient(player, "Error", "La caja está vacía: la acaban de atracar.")
			return
		end
		entrance:SetAttribute("RobbedUntil", now + Wanted.HeistCooldown)
		heistAt[player.UserId] = os.clock()
		local loot = math.random(Wanted.HeistLoot[1], Wanted.HeistLoot[2])
		DataService.addMoney(player, loot)
		Notify:FireClient(player, "Success", ("💰 Te llevas %s de la caja… ¡ha saltado la alarma!"):format(Format.money(loot)))
		Remote:FireAllClients("Alarm", entrance)
		WantedService.crime(player, "Atraco", entrance.Position, { Alarm = true })
	end)
end

---------------------------------------------------------------------
-- Vigilancia: ¿te ven?, ¿te alcanzan?, ¿te has librado?
---------------------------------------------------------------------
local function watchWanted(player: Player, state: State)
	local r = rootOf(player)
	if not r or state.Arresting or outOfReach(player) then
		return
	end
	local now = os.clock()
	if player:GetAttribute("InteriorKey") then
		-- Escondido dentro de un edificio: la policía espera en la puerta (no te ve)
		local door = player:GetAttribute("InteriorDoor")
		state.LastPosition = if typeof(door) == "Vector3" then door else state.LastPosition
		player:SetAttribute("WantedSearching", true)
		PoliceUnits.setTarget(player, state.LastPosition)
		if now - state.LastSeen > Wanted.evadeSeconds(state.Stars) then
			setStars(player, 0)
			state.Crimes = {}
			state.CrimeKeys = {}
			Remote:FireClient(player, "Evaded", {})
		end
		return
	end
	if PoliceUnits.sees(player) then
		state.LastSeen = now
		state.LastPosition = r.Position
		PoliceUnits.setTarget(player, r.Position)
		player:SetAttribute("WantedSearching", nil)
	else
		-- Te buscan donde te vieron por última vez; las estrellas parpadean
		player:SetAttribute("WantedSearching", true)
		PoliceUnits.setTarget(player, state.LastPosition)
		if now - state.LastSeen > Wanted.evadeSeconds(state.Stars) then
			setStars(player, 0)
			state.Crimes = {}
			state.CrimeKeys = {}
			Remote:FireClient(player, "Evaded", {})
			StoryEvents.emit(player, "EvadedPolice", {})
			return
		end
	end
	-- Te alcanzan: un agente pegado a ti un momento (o estás K.O. con uno cerca)
	local close = PoliceUnits.officersNear(player, r.Position, Wanted.CatchDistance) > 0
	local knocked = player:GetAttribute("KO") == true and PoliceUnits.officersNear(player, r.Position, 10) > 0
	if close or knocked then
		state.CatchSince = state.CatchSince or now
		if knocked or now - state.CatchSince >= Wanted.CatchSeconds then
			WantedService.arrest(player, nil)
			return -- (ya sin estrellas: no hace falta patrulla)
		end
	else
		state.CatchSince = nil
	end
	PoliceUnits.ensure(player, state.Stars)
end

---------------------------------------------------------------------
-- Al volante sin carnet (o siendo menor): solo si te ve la policía
---------------------------------------------------------------------

-- ¿Ve la policía a quien conduce? Un policía jugador de servicio, una patrulla de ronda o los
-- agentes y coches de cualquier persecución. Devuelve también la patrulla de ronda que le vio.
local function policeSeesDriver(player: Player): (boolean, any)
	local r = rootOf(player)
	if not r then
		return false, nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local rides = workspace:FindFirstChild("Rides")
	if rides then
		table.insert(ignore, rides) -- (a quien va en coche se le ve por las ventanillas)
	end
	params.FilterDescendantsInstances = ignore
	for _, cop in Players:GetPlayers() do
		local c = rootOf(cop)
		if cop ~= player and onDuty(cop) and c and (c.Position - r.Position).Magnitude <= Wanted.DriveSight then
			if not workspace:Raycast(c.Position, r.Position - c.Position, params) then
				Notify:FireClient(cop, "Info", ("🚨 %s conduce sin carnet delante de ti"):format(player.DisplayName))
				return true, nil
			end
		end
	end
	return PoliceUnits.seesDriver(player, Wanted.DriveSight)
end
WantedService.policeSeesDriver = policeSeesDriver

-- Delitos de «requisitos» al volante (la edad o el carnet) y la huida de un «¡Alto!» por ellos: el
-- modo pruebas con «Sin requisitos» no los comete (los de verdad, sí: answersAsAdult)
local DRIVING_REQUIREMENT = { SinCarnet = true, MenorVolante = true, Huida = true }
local DRIVING_TEXT: { [string]: boolean } = {}
for key in DRIVING_REQUIREMENT do
	DRIVING_TEXT[Wanted.Crimes[key].Text] = true
end

-- Tester con «Sin requisitos» al volante: ni «¡Alto!» ni estrellas por conducir sin edad o sin carnet.
-- Si ya le buscaban SOLO por eso (le pararon antes de encender el interruptor), se le deja en paz.
local function forgiveDriving(player: Player, state: State)
	state.Stop = nil
	if state.Stars <= 0 or #state.Crimes == 0 or state.Arresting then
		return
	end
	for _, text in state.Crimes do
		if not DRIVING_TEXT[text] then
			return -- (hay algún delito de verdad: la búsqueda sigue)
		end
	end
	state.Crimes = {}
	state.CrimeKeys = {}
	setStars(player, 0)
	Notify:FireClient(player, "Info", "🧪 Modo pruebas: sin requisitos no te buscan por conducir sin carnet ni por la edad.")
end

local function checkDriver(player: Player, state: State)
	if TesterService.bypass(player) then
		forgiveDriving(player, state)
		return
	end
	local offence = VehicleService.drivingOffence(player)
	if not offence or state.Arresting or player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return
	end
	local now = os.clock()
	local stop = state.Stop
	if not stop then
		local seen, patrol = policeSeesDriver(player)
		if seen then
			state.Stop = { At = now, Crime = offence, Fled = false }
			PoliceUnits.pullOver(player, patrol)
			Notify:FireClient(player, "Error", "🚨 ¡Alto! ¡Policía! Para el vehículo y bájate.")
			report(player, offence, "Police")
		end
	elseif not stop.Fled and now - stop.At >= Wanted.StopSeconds and VehicleService.rideSpeed(player) >= Wanted.StopSpeed then
		-- Le han dado el «¡Alto!» y sigue conduciendo: huida
		stop.Fled = true
		report(player, "Huida", "Police")
	end
end

-- Repaso de todos los que van al volante (lo hace el bucle cada medio segundo; las pruebas lo llaman)
function WantedService.checkDrivers()
	for _, player in Players:GetPlayers() do
		if player.Parent and VehicleService.ridingKind(player) then
			local ok, err = pcall(checkDriver, player, stateOf(player))
			if not ok then
				warn("[Wanted] " .. tostring(err))
			end
		end
	end
end

---------------------------------------------------------------------
-- Lo que hace CombatService (golpes) -> delitos
---------------------------------------------------------------------
local function onStoryEvent(player: Player, name: string, payload: { [string]: any })
	if name ~= "HitSomeone" then
		return
	end
	if payload.Vehicle then
		return -- (atropello: lo decide KnockService con Crossing —¿culpa tuya?— y solo si lo ve la policía)
	end
	local model = payload.Model
	if typeof(model) == "Instance" and (model:GetAttribute("Responder") or model:GetAttribute("InvasionTarget") ~= nil) then
		return -- (los agentes del cordón de la invasión y los alienígenas: defender Valmar no es delito)
	end
	if typeof(model) == "Instance" and model:GetAttribute("Officer") then
		WantedService.crime(player, "AgresionPolicia")
		return
	end
	if not payload.Target then
		-- Disparar (o dar con el táser) a un personaje de la calle también es delito: antes solo
		-- contaba si la víctima era un jugador, y a los NPC se les podía acribillar sin que nadie
		-- llamase. La víctima llama a la policía (una denuncia por víctima cada NPC_HIT_GAP).
		local w = Weapons.get(payload.Weapon)
		-- Pegar (a puñetazos o con un poder) a un paseante de la calle (CrowdService) también es
		-- agresión: llama a la policía igual. A un rival de entrenamiento (FighterService), no.
		local street = payload.Street == true and not payload.Rival and not payload.Weapon
		if (street or (w and w.Kind ~= "Toy")) and typeof(model) == "Instance" and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
			if onDuty(player) and model:GetAttribute("Suspect") then
				return -- (la policía de servicio reduciendo al sospechoso de su aviso)
			end
			local state = stateOf(player)
			state.NpcHits = state.NpcHits or {}
			local hits = state.NpcHits :: { [Model]: number }
			local now = os.clock()
			if now - (hits[model] or -math.huge) < NPC_HIT_GAP then
				return
			end
			for other, at in hits do
				if now - at >= NPC_HIT_GAP then
					hits[other] = nil
				end
			end
			hits[model] = now
			local root = model:FindFirstChild("HumanoidRootPart")
			local at = if root and root:IsA("BasePart") then root.Position else nil
			local r = rootOf(player)
			local crime = if street then "Agresion" elseif w and w.Kind == "Taser" then "Agresion" else "Disparo"
			WantedService.crime(player, crime, if r then r.Position else at, { Witness = model, Gun = crime == "Disparo" })
		end
		return
	end
	local victim = Players:GetPlayerByUserId(payload.Target)
	-- Un policía de servicio que reduce a alguien buscado no comete delito
	if victim and onDuty(player) and stateOf(victim).Stars > 0 then
		return
	end
	if payload.Weapon then
		WantedService.crime(player, if payload.Killed then "Homicidio" else "Disparo", nil, { Gun = true })
		return
	end
	WantedService.crime(player, if payload.Killed then "Homicidio" elseif payload.KO then "KO" else "Agresion")
end

-- Sin estrellas
function WantedService.clear(player: Player)
	setStars(player, 0)
	local state = stateOf(player)
	state.Crimes = {} -- (lo de antes ya no cuenta para la próxima vez)
	state.CrimeKeys = {}
	state.Reports = nil
	state.Suspect = nil
	player:SetAttribute("WantedReport", nil)
	player:SetAttribute("PoliceInvestigating", nil)
end

-- ¿Es policía de servicio? (disparar a alguien buscado no es delito para ellos)
function WantedService.onDuty(player: Player): boolean
	return onDuty(player)
end

function WantedService.stars(player: Player): number
	return stateOf(player).Stars
end

function WantedService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Wanted") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Wanted"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, target: any)
		if kind == "Steal" then
			steal(player, target)
		elseif kind == "Arrest" and onDuty(player) and typeof(target) == "Instance" and target:IsA("Player") and target ~= player then
			local a, b = rootOf(player), rootOf(target)
			-- Mismo sitio (misma casa o edificio, o los dos fuera): no vale teletransportarse al lado
			local sameSpot = player:GetAttribute("InteriorKey") == target:GetAttribute("InteriorKey")
			if a and b and sameSpot and (a.Position - b.Position).Magnitude <= 8 and stateOf(target).Stars > 0 then
				WantedService.arrest(target, player)
			end
		end
	end)

	PoliceUnits.init()
	StoryEvents.connect(onStoryEvent)
	for _, entrance in CollectionService:GetTagged("Shop") do
		setupHeist(entrance)
	end
	CollectionService:GetInstanceAddedSignal("Shop"):Connect(setupHeist)

	-- La búsqueda se guarda con la partida: al volver sigues buscado
	DataService.onLoaded(function(player, data)
		local stars = tonumber(data.Wanted) or 0
		if stars > 0 then
			local state = stateOf(player)
			state.LastSeen = os.clock()
			task.delay(6, function()
				if player.Parent then
					local r = rootOf(player)
					state.LastPosition = r and r.Position
					setStars(player, math.clamp(stars, 1, Wanted.MaxStars))
				end
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		PoliceUnits.dismiss(player)
		states[player] = nil
		-- (las esperas van por UserId para que salir y entrar no las reinicie; las ya cumplidas se borran)
		local now = os.clock()
		for id, at in heistAt do
			if now - at >= HEIST_GAP then
				heistAt[id] = nil
			end
		end
		for thief, victims in robbedAt do
			for victim, at in victims do
				if now - at >= VICTIM_GAP then
					victims[victim] = nil
				end
			end
			if next(victims) == nil then
				robbedAt[thief] = nil
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			WantedService.checkDrivers()
			for player, state in states do
				if state.Stars > 0 and player.Parent then
					local ok, err = pcall(watchWanted, player, state)
					if not ok then
						warn("[Wanted] " .. tostring(err))
					end
				elseif player.Parent and (state.Suspect or (state.Reports and #state.Reports > 0)) then
					-- (la policía investiga unos disparos o busca a alguien vestido como en una denuncia)
					local ok, err = pcall(checkSuspect, player, state)
					if ok then
						ok, err = pcall(checkReports, player, state)
					end
					if not ok then
						warn("[Wanted] " .. tostring(err))
					end
				end
			end
		end
	end)
end

return WantedService
