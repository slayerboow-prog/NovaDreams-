-- DerivaService (servidor): los PECIOS de la Deriva y su historia (expansión «La Deriva», Acto I;
-- docs/espacio-aaa/expansion-15h.md; cuentas en shared/Cosmos/Derelicts).
--
-- Como VarkunService: pone en el mundo lo que la historia necesita y avisa a la historia (StoryEvents)
-- de lo que pasa; la misión, sus textos y sus frases son del motor de historia (shared/LifeStory/Misiones/
-- Deriva_ActoI y su guion generado desde docs/historia/reescritura/Deriva_01_Misericordia.md).
--   * El pecio (World/DerelictBuilder) se construye la primera vez que alguien lo necesita.
--   * Atracar en su esclusa: SpaceService.dockDerelict te baja dentro (como en una estación) y aquí se
--     te marca «EnPecio». Volver a la nave: SpaceService.boardAt te sube fuera de la esclusa.
--   * Dentro, cada 0,2 s: barreras láser y chispas (daño sin bajar de 15 de vida: nadie muere dentro),
--     la puerta del puente (sin corriente te devuelve al pasillo) y los fusibles que llevas (atributo
--     DerivaPower: tu pantalla enciende las luces y apaga los láseres; Controllers/DerelictClient).
--   * Fuera, volando (SpaceService le llama cada segundo): llegar al pecio y la emboscada al salir.
--   * Sucesos de SpaceService (event): atracar (ofrecer la misión, entregar en Alba), derribos y derribado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Derelicts = require(Cosmos.Derelicts)
local Stations = require(Cosmos.Stations)
local Layers = require(Cosmos.Layers)

local DataService = require(script.Parent.DataService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local DerivaService = {}

DerivaService.TickSeconds = 0.2
DerivaService.RewardMats = { Componentes = 12, Datos = 10 }

type RState = { Enemies: { string }, Killed: number, Kind: string?, HurtAt: number, Logs: { [string]: boolean } }
local runtime: { [Player]: RState } = {}
local wired = false
local loop: RBXScriptConnection? = nil
local acc = 0

local function service(name: string): any
	return require(script.Parent[name])
end

local function airCombat(): any
	return service("AirCombatService")
end

local function rt(player: Player): RState
	local r = runtime[player]
	if not r then
		r = { Enemies = {}, Killed = 0, HurtAt = -math.huge, Logs = {} }
		runtime[player] = r
	end
	return r
end

local function storyOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	return data and data.Story
end

local function phaseOf(player: Player): Derelicts.Phase?
	return Derelicts.phaseOf(storyOf(player))
end

local function toast(player: Player, kind: string, text: string)
	pcall(function()
		service("SpaceService").toast(player, kind, text)
	end)
end

local function serverTime(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

local function emit(player: Player, step: string)
	StoryEvents.emit(player, "DerivaStep", { Step = step })
end

local function setPower(player: Player)
	player:SetAttribute("DerivaPower", Derelicts.power(phaseOf(player)))
end

---------------------------------------------------------------------
-- El pecio en el mundo y sus paneles
---------------------------------------------------------------------
local onPrompt: (Player, string, any) -> ()

function DerivaService.ensure(): { [string]: any }?
	local ok, built = pcall(function()
		return require(script.Parent.Parent.World.DerelictBuilder).build(Derelicts.Misericordia)
	end)
	if not ok then
		warn("[DerivaService] no se pudo construir el pecio: " .. tostring(built))
		return nil
	end
	if not wired then
		wired = true
		local P = built.Prompts
		local function wire(pp: ProximityPrompt?, kind: string, arg: any)
			if pp then
				pp.Triggered:Connect(function(player: Player)
					local okP, err = pcall(onPrompt, player, kind, arg)
					if not okP then
						warn("[DerivaService] " .. tostring(err))
					end
				end)
			end
		end
		for n, pp in P.Fuse do
			wire(pp, "Fuse", n)
		end
		for id, pp in P.Log do
			wire(pp, "Log", id)
		end
		wire(P.Core, "Core", nil)
		wire(P.Exit, "Exit", nil)
	end
	return built
end

local function inPecio(player: Player): boolean
	return player:GetAttribute("EnPecio") == Derelicts.Misericordia.Id
end

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	return root, hum
end

onPrompt = function(player: Player, kind: string, arg: any)
	if not inPecio(player) then
		return
	end
	local d = Derelicts.Misericordia
	local phase = phaseOf(player)
	if kind == "Fuse" then
		local n = tonumber(arg) or 0
		if not phase or phase.Step ~= "Fuses" then
			toast(player, "Info", if Derelicts.power(phase) >= 3 then "⚡ Este fusible ya funciona." else "⚡ El fusible está quemado. Ahora no puedes hacer nada con él.")
			return
		end
		if phase.Fuses[n] then
			toast(player, "Info", "⚡ Este ya lo has cambiado.")
			return
		end
		StoryEvents.emit(player, "DerivaFuse", { N = n })
		task.defer(function()
			setPower(player)
			local p = Derelicts.power(phaseOf(player))
			toast(player, "Success", if p >= 3 then "⚡ Corriente restaurada en toda la nave. El puente se abre." else ("⚡ Fusible cambiado (%d de 3). Vuelve algo de luz."):format(p))
		end)
	elseif kind == "Log" then
		local r = rt(player)
		for _, lg in d.Logs do
			if lg.Id == arg then
				r.Logs[lg.Id] = true
				pcall(function()
					service("HappeningService").play(player, lg.Scene)
				end)
			end
		end
	elseif kind == "Core" then
		if phase and phase.Step == "Core" then
			emit(player, "Core")
			toast(player, "Success", "💾 Tienes el núcleo de datos de la Misericordia. Vuelve a tu nave por la esclusa.")
		elseif Derelicts.power(phase) < 3 then
			toast(player, "Info", "💾 El núcleo no responde: no hay corriente.")
		end
	elseif kind == "Exit" then
		DerivaService.leave(player)
	end
end

---------------------------------------------------------------------
-- Entrar y salir
---------------------------------------------------------------------
function DerivaService.entryCFrame(): CFrame
	local d = Derelicts.Misericordia
	local p = Derelicts.world(d, d.Entry)
	return CFrame.lookAt(p, p + d.EntryLook)
end

function DerivaService.launchCFrame(): CFrame
	local d = Derelicts.Misericordia
	local p = Derelicts.world(d, d.Launch)
	local l = d.LaunchLook.Unit
	local right = l:Cross(Vector3.new(0, 1, 0)).Unit
	return CFrame.fromMatrix(p, right, right:Cross(l).Unit, -l)
end

-- Lo llama SpaceService.dockDerelict cuando ya te ha bajado dentro
function DerivaService.onEnter(player: Player)
	DerivaService.ensure()
	player:SetAttribute("EnPecio", Derelicts.Misericordia.Id)
	setPower(player)
	DerivaService.ensureLoop()
	local phase = phaseOf(player)
	if phase and phase.Step == "Board" then
		emit(player, "Board")
	end
end

-- «Volver a la nave» en la esclusa
function DerivaService.leave(player: Player): boolean
	local ok = service("SpaceService").boardAt(player, DerivaService.launchCFrame(), "pecio")
	if ok then
		player:SetAttribute("EnPecio", nil)
		local phase = phaseOf(player)
		if phase and phase.Step == "Launch" then
			emit(player, "Launch")
		end
	end
	return ok
end

---------------------------------------------------------------------
-- Dentro: peligros, puerta del puente y paso del puente
---------------------------------------------------------------------
local function hurt(player: Player, hum: Humanoid, amount: number, text: string)
	local r = rt(player)
	local t = os.clock()
	if t - r.HurtAt < 1 then
		return
	end
	local dmg = Derelicts.damageFor(Derelicts.Misericordia, hum.Health, amount)
	r.HurtAt = t
	if dmg > 0 then
		hum:TakeDamage(dmg)
	end
	toast(player, "Error", text)
end

local function insideTick(player: Player)
	local d = Derelicts.Misericordia
	local root, hum = rootOf(player)
	if not root or not hum or hum.Health <= 0 then
		player:SetAttribute("EnPecio", nil)
		return
	end
	local pos = root.Position
	if not Derelicts.inside(d, pos, 30) then
		-- (se ha ido de otra forma: la historia, un portal, morir… ya no está dentro)
		player:SetAttribute("EnPecio", nil)
		return
	end
	local phase = phaseOf(player)
	local power = Derelicts.power(phase)
	if player:GetAttribute("DerivaPower") ~= power then
		player:SetAttribute("DerivaPower", power)
	end
	local t = serverTime()
	local l = Derelicts.toLocal(d, pos)
	-- Barreras láser (con la corriente restaurada, el sistema de seguridad se reinicia y se apagan)
	if power < 3 then
		for i in d.Lasers do
			if Derelicts.inLaser(d, i, pos) and Derelicts.laserOn(d, i, t) then
				hurt(player, hum, d.LaserDamage, "🔴 ¡El láser de seguridad te ha quemado! Cruza cuando se apague.")
				-- (te aparta hacia el lado del que venías)
				local back = if (root.AssemblyLinearVelocity.X or 0) > 0 then -5 else 5
				root.CFrame = root.CFrame + Vector3.new(back, 0, 0)
			end
		end
	end
	-- Chispas de Máquinas
	local S = d.Sparks
	if Derelicts.sparkState(d, t) == "Burst" and (Vector3.new(l.X, 0, l.Z) - Vector3.new(S.C.X, 0, S.C.Z)).Magnitude <= S.Radius then
		hurt(player, hum, S.Damage, "⚡ ¡Una descarga del cuadro roto! Espera a que deje de chisporrotear.")
	end
	-- Puerta del puente: sin corriente no se pasa
	if l.X < d.BridgeX + 1 and power < 3 then
		root.CFrame = CFrame.new(Derelicts.world(d, Vector3.new(d.BridgeX + 6, 3, 0))) * root.CFrame.Rotation
		toast(player, "Info", "🚪 La puerta del puente no tiene corriente. Cambia los tres fusibles.")
	elseif l.X < d.BridgeX - 2 and phase and phase.Step == "Bridge" then
		emit(player, "Bridge")
	end
end

---------------------------------------------------------------------
-- Fuera, volando (SpaceService.tick, cada segundo, para quien vuela en el espacio)
---------------------------------------------------------------------
local function dropEnemies(player: Player)
	local r = runtime[player]
	if not r then
		return
	end
	for _, id in r.Enemies do
		pcall(airCombat().dropEnemy, player, id)
	end
	r.Enemies, r.Killed, r.Kind = {}, 0, nil
end

local function spawnAmbush(player: Player)
	local d = Derelicts.Misericordia
	local r = rt(player)
	local AC = airCombat()
	r.Enemies, r.Killed, r.Kind = {}, 0, "Ambush"
	local center = Derelicts.world(d, d.Launch)
	for i, kind in d.AmbushKinds do
		local a = (i - 1) / #d.AmbushKinds * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * d.AmbushRadius, 60 + 30 * math.sin(a * 2), math.sin(a) * d.AmbushRadius)
		p = Vector3.new(p.X, math.max(p.Y, Layers.AIMinY + 120), p.Z)
		local id = AC.spawnEnemy(player, kind, p, { Hull = 1, Damage = 1, Fire = 1, Speed = 1, Level = 3 })
		if id then
			table.insert(r.Enemies, id)
		end
	end
end

function DerivaService.tick(player: Player)
	local phase = phaseOf(player)
	local r = rt(player)
	if not phase then
		if r.Kind then
			dropEnemies(player)
		end
		return
	end
	local st = airCombat().status(player)
	if not st or st.Down then
		if r.Kind then
			dropEnemies(player)
		end
		return
	end
	local d = Derelicts.Misericordia
	local dock = Derelicts.world(d, d.Dock)
	if phase.Step == "Approach" then
		if (st.Pos - dock).Magnitude <= d.ApproachRadius then
			DerivaService.ensure()
			emit(player, "Approach")
		end
	elseif phase.Step == "Ambush" then
		if r.Kind ~= "Ambush" then
			if (st.Pos - dock).Magnitude <= 2500 then
				spawnAmbush(player)
			end
		elseif #r.Enemies > 0 and r.Killed >= #r.Enemies then
			r.Enemies, r.Kind = {}, nil
			emit(player, "Ambush")
		else
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
			if n + r.Killed < #r.Enemies then
				dropEnemies(player) -- (se ha escapado alguno: vuelven a salir al acercarte)
			end
		end
	end
end

-- Sucesos de SpaceService: atracar, derribos y derribado
function DerivaService.event(player: Player, ev: { [string]: any })
	if type(ev) ~= "table" then
		return
	end
	if ev.Type == "Dock" then
		local story = storyOf(player)
		local phase = Derelicts.phaseOf(story)
		if phase and phase.Step == "Delivered" and ev.Station == Derelicts.Misericordia.DeliverStation then
			emit(player, "Delivered")
			local Space = service("SpaceService")
			for id, n in DerivaService.RewardMats do
				pcall(Space.addMat, player, id, n)
			end
			toast(player, "Success", ("💾 Entregas el núcleo: ⚙ +%d Componentes · 📡 +%d Datos"):format(DerivaService.RewardMats.Componentes, DerivaService.RewardMats.Datos))
			task.delay(1.5, function()
				if player.Parent then
					pcall(function()
						service("HappeningService").play(player, "Deriva_Alba_Fin")
					end)
				end
			end)
		end
		if Derelicts.offer(story) then
			StoryEvents.emit(player, "DerivaSignal", { Part = 1 })
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

function DerivaService.onExit(player: Player)
	dropEnemies(player)
end

-- Fila de misión del HUD de la nave (o nil)
function DerivaService.row(player: Player): { [string]: any }?
	local alba = Stations.ById[Derelicts.Misericordia.DeliverStation]
	local row = Derelicts.row(phaseOf(player), alba and alba.Dock)
	if row then
		row.Id = "Deriva"
	end
	return row
end

---------------------------------------------------------------------
-- Bucle de dentro (solo mientras alguien está dentro)
---------------------------------------------------------------------
function DerivaService.ensureLoop()
	if loop then
		return
	end
	acc = 0
	loop = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < DerivaService.TickSeconds then
			return
		end
		acc = 0
		local anyone = false
		for _, player in Players:GetPlayers() do
			if inPecio(player) then
				anyone = true
				local ok, err = pcall(insideTick, player)
				if not ok then
					warn("[DerivaService] " .. tostring(err))
				end
			end
		end
		if not anyone and loop then
			loop:Disconnect()
			loop = nil
		end
	end)
end

function DerivaService.init()
	Players.PlayerRemoving:Connect(function(player)
		dropEnemies(player)
		runtime[player] = nil
	end)
	-- (el pecio se construye ya: es pequeño y así sus sitios existen para la historia y la nave lo ve)
	task.defer(DerivaService.ensure)
end

-- (pruebas)
DerivaService._runtime = runtime
DerivaService._insideTick = insideTick
DerivaService._onPrompt = function(player: Player, kind: string, arg: any)
	onPrompt(player, kind, arg)
end

return DerivaService
