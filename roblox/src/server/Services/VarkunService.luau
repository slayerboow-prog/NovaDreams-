-- VarkunService (servidor): el PRÓLOGO de la historia del espacio, «La costura negra» (Varkun, el
-- Deshilador; docs/universo/diseno-espacio.md §2; cuentas en shared/Cosmos/Varkun).
--
-- Pone en el mundo lo que la historia necesita y avisa a la historia (StoryEvents) de lo que pasa; las
-- misiones, sus textos y sus frases son del motor de historia (shared/LifeStory/Misiones/Saga2_Prologo y
-- sus guiones generados desde docs/historia/reescritura/Varkun_*.md).
--   * El carguero destrozado de la Ruta, la anomalía de hilo de la Escarcha y la Rueca (solo mientras
--     alguien está en ese paso): pocas piezas ancladas, sin choques ni consultas, en workspace.VarkunEscena.
--   * Los Hilanderos (Agujas y una Pesada) los pone AirCombatService en la sesión de cada piloto; solo
--     cuentan los derribos de ESOS ids. Si te derriban, te bajas de la nave o sales del juego, se van y
--     el paso vuelve a empezar al volver (nada se queda colgado).
-- No tiene remoto ni bucle propios: SpaceService le llama desde su bucle de 1 s (tick), sus sucesos
-- (event: Dock, Kill, Down), al bajarse (onExit) y para las filas del HUD (row).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Varkun = require(Cosmos.Varkun)
local Access = require(Cosmos.Access)
local Layers = require(Cosmos.Layers)

local DataService = require(script.Parent.DataService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local VarkunService = {}

VarkunService.clock = function(): number
	return os.clock()
end

type RState = { Enemies: { string }, Killed: number, Scan: number, RuecaAt: number?, Last: number?, Kind: string?, AutoStep: string?, AutoAt: number? }
local runtime: { [Player]: RState } = {}
local ruecaUsers: { [Player]: boolean } = {}
local scene: { [string]: Instance } = {}

local function airCombat(): any
	return require(script.Parent.AirCombatService)
end

local function rt(player: Player): RState
	local r = runtime[player]
	if not r then
		r = { Enemies = {}, Killed = 0, Scan = 0 }
		runtime[player] = r
	end
	return r
end

local function storyOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	return data and data.Story
end

local function sagaDone(player: Player): boolean
	local data = DataService.get(player)
	if Access.sagaDone(data) then
		return true
	end
	local ok, yes = pcall(function()
		return require(script.Parent.TesterService).isTester(player)
	end)
	return ok and yes == true
end

---------------------------------------------------------------------
-- Lo que se ve: el carguero destrozado, la anomalía y la Rueca (pocas piezas, ancladas, sin choques)
---------------------------------------------------------------------
local function folder(): Instance?
	local ok, f = pcall(function()
		local existing = workspace:FindFirstChild("VarkunEscena")
		if existing then
			return existing
		end
		local created = Instance.new("Folder")
		created.Name = "VarkunEscena"
		created.Parent = workspace
		return created
	end)
	return if ok then f else nil
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, neon: boolean?, transparency: number?, ball: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.Metal
	p.Transparency = transparency or 0
	if ball then
		p.Shape = Enum.PartType.Ball
	end
	p.Parent = parent
	return p
end

local THREAD = Color3.fromRGB(190, 120, 255)

local function buildWreck(): Model
	local m = Instance.new("Model")
	m.Name = "CargueroDestrozado"
	local c = Varkun.WreckPos
	local hull = Color3.fromRGB(150, 146, 136)
	-- (el carguero partido en tres trozos que se separan, con hilos negros y violetas cosidos al casco)
	part(m, "Proa", Vector3.new(6, 5, 9), CFrame.new(c + Vector3.new(0, 0, -16)) * CFrame.Angles(0.3, 0.2, 0.4), hull)
	part(m, "Centro", Vector3.new(6, 4.4, 14), CFrame.new(c) * CFrame.Angles(-0.2, 0.5, 0.1), Color3.fromRGB(70, 130, 200))
	part(m, "Popa", Vector3.new(5, 4, 8), CFrame.new(c + Vector3.new(4, -3, 17)) * CFrame.Angles(0.6, -0.3, -0.5), hull)
	for i = 1, 5 do
		local a = i * 1.3
		local from = c + Vector3.new(math.cos(a) * 12, math.sin(a * 2) * 6, math.sin(a) * 12)
		local to = c + Vector3.new(math.cos(a + 2) * 30, 10 + i * 3, math.sin(a + 2) * 30)
		local mid, len = (from + to) / 2, (to - from).Magnitude
		part(m, "Hilo", Vector3.new(0.3, 0.3, len), CFrame.lookAt(mid, to), if i % 2 == 0 then Color3.fromRGB(20, 18, 26) else THREAD, i % 2 == 1, 0.15)
	end
	local beacon = part(m, "Baliza", Vector3.new(2, 2, 2), CFrame.new(c + Vector3.new(0, 4, 0)), Color3.fromRGB(255, 70, 60), true, 0, true)
	pcall(function()
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 80, 60)
		light.Range = 40
		light.Brightness = 2
		light.Parent = beacon
	end)
	m.PrimaryPart = beacon
	return m
end

local function buildAnomaly(): Model
	local m = Instance.new("Model")
	m.Name = "AnomaliaDeHilo"
	local c = Varkun.AnomalyPos
	local core = part(m, "Nucleo", Vector3.new(14, 14, 14), CFrame.new(c), THREAD, true, 0.35, true)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local tip = c + Vector3.new(math.cos(a) * 60, math.sin(a * 3) * 25, math.sin(a) * 60)
		part(m, "Hilo", Vector3.new(0.4, 0.4, 60), CFrame.lookAt((c + tip) / 2, tip), if i % 2 == 0 then Color3.fromRGB(240, 235, 250) else THREAD, true, 0.25)
	end
	m.PrimaryPart = core
	return m
end

local function buildRueca(): Model
	local m = Instance.new("Model")
	m.Name = "LaRueca"
	local c = Varkun.RuecaPos
	local R = Varkun.RuecaRadius
	local dark = Color3.fromRGB(28, 24, 36)
	-- (el huso en el centro y una rueda de 16 radios: se ve de lejos como una silueta enorme)
	local huso = part(m, "Huso", Vector3.new(30, 30, 260), CFrame.new(c) * CFrame.Angles(math.rad(70), 0, 0), dark)
	part(m, "Corazon", Vector3.new(40, 40, 40), CFrame.new(c), THREAD, true, 0.2, true)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local rim = c + Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		local nextRim = c + Vector3.new(math.cos(a + math.pi / 8) * R, math.sin(a + math.pi / 8) * R, 0)
		part(m, "Aro", Vector3.new(12, 12, (nextRim - rim).Magnitude + 6), CFrame.lookAt((rim + nextRim) / 2, nextRim), dark)
		if i % 2 == 0 then
			part(m, "Radio", Vector3.new(2, 2, R), CFrame.lookAt((c + rim) / 2, rim), THREAD, true, 0.3)
		end
	end
	m.PrimaryPart = huso
	return m
end

local BUILDERS = { Wreck = buildWreck, Anomaly = buildAnomaly, Rueca = buildRueca }

local function ensure(key: string): Instance?
	local existing = scene[key]
	if existing and existing.Parent then
		return existing
	end
	local f = folder()
	local ok, model = pcall(BUILDERS[key])
	if ok and model and f then
		model.Parent = f
		scene[key] = model
		return model
	end
	return nil
end

local function remove(key: string)
	local m = scene[key]
	scene[key] = nil
	if m then
		pcall(function()
			m:Destroy()
		end)
	end
end

local function useRueca(player: Player, on: boolean)
	ruecaUsers[player] = if on then true else nil
	if next(ruecaUsers) then
		ensure("Rueca")
	else
		remove("Rueca")
	end
end

---------------------------------------------------------------------
-- Enemigos de la escena (Hilanderos)
---------------------------------------------------------------------
local function dropEnemies(player: Player)
	local r = runtime[player]
	if not r then
		return
	end
	local AC = airCombat()
	for _, id in r.Enemies do
		pcall(AC.dropEnemy, player, id)
	end
	r.Enemies = {}
	r.Killed = 0
	r.Kind = nil
	r.RuecaAt = nil
	useRueca(player, false)
end

local function spawnGroup(player: Player, kinds: { string }, center: Vector3, radius: number, kind: string): number
	local r = rt(player)
	local AC = airCombat()
	r.Enemies, r.Killed, r.Kind = {}, 0, kind
	for i, p in Varkun.ring(center, #kinds, radius, #kinds) do
		p = Vector3.new(p.X, math.max(p.Y, Layers.AIMinY + 120), p.Z)
		local id = AC.spawnEnemy(player, kinds[i], p, { Hull = 1, Damage = 1, Fire = 1, Speed = 1, Level = 3 })
		if id then
			table.insert(r.Enemies, id)
		end
	end
	return #r.Enemies
end

-- ¿Cuántos de los suyos siguen vivos?
local function aliveOf(player: Player, r: RState): number
	local alive = {}
	for _, e in airCombat().enemyList(player) do
		alive[e.Id] = true
	end
	local n = 0
	for _, id in r.Enemies do
		if alive[id] then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
-- Cada segundo volando en el espacio
---------------------------------------------------------------------
function VarkunService.tick(player: Player)
	local phase = Varkun.phaseOf(storyOf(player))
	local r = rt(player)
	local t = VarkunService.clock()
	local dt = if r.Last then math.clamp(t - r.Last, 0, 5) else 0
	r.Last = t
	if not phase then
		if r.Kind then
			dropEnemies(player)
		end
		return
	end
	local st = airCombat().status(player)
	if not st then
		return
	end
	if st.Down then
		if r.Kind then
			dropEnemies(player)
		end
		return
	end
	local pos: Vector3 = st.Pos
	local s = phase.Step
	if Varkun.Auto[s] then
		-- (pasos que se cumplen solos al rato: suenan las frases del final sin quitar el control)
		if r.AutoStep ~= s then
			r.AutoStep, r.AutoAt = s, t
		elseif t - (r.AutoAt or t) >= Varkun.Auto[s] then
			r.AutoStep = nil
			StoryEvents.emit(player, "VarkunStep", { Step = s })
		end
		return
	end
	if s == "Wreck" then
		ensure("Wreck")
		if (pos - Varkun.WreckPos).Magnitude <= Varkun.WreckRadius then
			StoryEvents.emit(player, "VarkunStep", { Step = "Wreck" })
		end
	elseif s == "Ambush" then
		ensure("Wreck")
		if r.Kind ~= "Ambush" then
			if (pos - Varkun.WreckPos).Magnitude <= Varkun.AmbushRange then
				spawnGroup(player, Varkun.AmbushKinds, Varkun.WreckPos, 380, "Ambush")
			end
		elseif r.Killed >= #r.Enemies and #r.Enemies > 0 then
			r.Enemies, r.Kind = {}, nil
			StoryEvents.emit(player, "VarkunStep", { Step = "Ambush" })
		elseif aliveOf(player, r) + r.Killed < #r.Enemies then
			-- (se ha escapado alguno: te alejaste mucho) → vuelven a salir cuando vuelvas
			dropEnemies(player)
		end
	elseif s == "Anomaly" then
		ensure("Anomaly")
		if (pos - Varkun.AnomalyPos).Magnitude <= Varkun.AnomalyRadius then
			r.Scan = 0
			StoryEvents.emit(player, "VarkunStep", { Step = "Anomaly" })
		end
	elseif s == "Scanned" then
		ensure("Anomaly")
		if (pos - Varkun.AnomalyPos).Magnitude <= Varkun.ScanRadius then
			r.Scan += dt
			if r.Scan >= Varkun.ScanSeconds then
				StoryEvents.emit(player, "VarkunStep", { Step = "Scanned" })
			end
		end
	elseif s == "Rueca" then
		ensure("Anomaly")
		if r.Kind ~= "Rueca" then
			if (pos - Varkun.AnomalyPos).Magnitude <= Varkun.RuecaRange then
				useRueca(player, true)
				spawnGroup(player, Varkun.RuecaKinds, pos + (Varkun.RuecaPos - pos).Unit * 500, 220, "Rueca")
				r.RuecaAt = t
			end
		else
			local over = t - (r.RuecaAt or t) >= Varkun.RuecaSeconds
			if over or (r.Killed >= #r.Enemies and #r.Enemies > 0) then
				dropEnemies(player) -- (los que queden se van con la Rueca)
				StoryEvents.emit(player, "VarkunStep", { Step = "Rueca" })
			end
		end
	end
end

-- Sucesos de SpaceService: atracar, derribos y derribado
function VarkunService.event(player: Player, ev: { [string]: any })
	if type(ev) ~= "table" then
		return
	end
	if ev.Type == "Dock" then
		local story = storyOf(player)
		local phase = Varkun.phaseOf(story)
		if phase and phase.Step == "Delivered" and ev.Station == Varkun.DeliverStation then
			StoryEvents.emit(player, "VarkunStep", { Step = "Delivered" })
			-- (el carrete se guarda solo mientras suenan las frases; si sales antes, pasa al volver)
			task.delay(Varkun.Auto.Vault, function()
				local now = Varkun.phaseOf(storyOf(player))
				if player.Parent and now and now.Step == "Vault" then
					StoryEvents.emit(player, "VarkunStep", { Step = "Vault" })
				end
			end)
		elseif phase and phase.Step == "Vault" then
			StoryEvents.emit(player, "VarkunStep", { Step = "Vault" })
		end
		-- (la siguiente parte se ofrece al atracar: andando por el vestíbulo, donde salen las tarjetas)
		local part = Varkun.offerPart(story, sagaDone(player))
		if part then
			StoryEvents.emit(player, "VarkunSignal", { Part = part })
		end
	elseif ev.Type == "Kill" and type(ev.Id) == "string" then
		local r = runtime[player]
		if r and table.find(r.Enemies, ev.Id) then
			r.Killed += 1
		end
	elseif ev.Type == "Down" then
		dropEnemies(player)
	end
end

function VarkunService.onExit(player: Player)
	dropEnemies(player)
end

-- Fila de misión del HUD de la nave (o nil)
function VarkunService.row(player: Player): { [string]: any }?
	local r = runtime[player]
	local row = Varkun.row(Varkun.phaseOf(storyOf(player)), r and r.Scan)
	if row then
		row.Id = "Varkun"
	end
	return row
end

function VarkunService.init()
	Players.PlayerRemoving:Connect(function(player)
		dropEnemies(player)
		runtime[player] = nil
		ruecaUsers[player] = nil
		useRueca(player, false)
	end)
end

-- (pruebas)
VarkunService._runtime = runtime
VarkunService._scene = scene

return VarkunService
