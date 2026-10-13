-- KartService (servidor): el Karting de San Roque (zona 13). Trazado y cronómetro en shared/KartTrack;
-- el sitio, en Kit/ZonasVerdes/Karting.
--
--   * Taquilla (tag OcioKartDesk): «Correr · Karts» (3 vueltas contra 3 karts de la máquina) y
--     «Contrarreloj · Karts» (3 vueltas tú solo). La tanda cuesta KartTrack.Entry.
--   * Te sube a un kart de verdad (vehículo «Kart» de VehicleService: lo conduces con Controllers/Driving)
--     en la parrilla. Semáforo (tag OcioKartLight): 3 rojas y verde. Si sales antes, +3 s.
--   * Cronómetro por puertas (KartTrack.feed) 10 veces por segundo con la posición del kart: vuelta,
--     tiempo, mejor vuelta y puesto (Controllers/OcioClient lo enseña). Las máquinas siguen la línea
--     central (KartTrack.botSpeed).
--   * Al acabar: diversión, experiencia, premio por puesto (carrera) y la mejor vuelta a la
--     clasificación del servidor (panel OcioKartBoard) y a tu récord (data.Ocio.KartBest).
--   * El kart solo corre por el circuito: si sales del karting, se acaba la tanda. Bajarte también.
--   * El oficio «Mecánico/a de boxes» es el de siempre de JobService (Config.Jobs.Boxes).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KartTrack = require(ReplicatedStorage.Shared.KartTrack)
local Sitios = require(ReplicatedStorage.Shared.OcioSitios)
local Format = require(ReplicatedStorage.Shared.Format)
local OcioFun = require(script.Parent.OcioFun)

local KartService = {}

KartService.COUNTDOWN = 3
KartService.MAX_SECONDS = 300
KartService.FALSE_START = 3 -- s de castigo por salir antes del verde
KartService.BOTS = 3
KartService.MAX_RACERS = 4
KartService.TICK = 0.1

type Bot = { Model: Model, S: number, Speed: number, Skill: number, Timer: KartTrack.Timer, Lane: number }
type Session = {
	Player: Player,
	Mode: string, -- "Carrera" | "Contrarreloj"
	Kart: Model?,
	Timer: KartTrack.Timer?,
	Go: number?, -- cuándo se puso verde
	Started: number,
	Grid: CFrame,
	Penalty: number,
	Bots: { Bot },
	Folder: Folder?,
	Finished: boolean,
	Ended: boolean,
	LastRank: number?,
}

local sessions: { [Player]: Session } = {}
local board: { { [string]: any } } = {}
local points = KartTrack.centerline(4)
local gates = KartTrack.gates(points)
local lengths: { number } = {}
local lapLength = 0
for i = 1, #points do
	lengths[i] = KartTrack.dist(points[i], points[i % #points + 1])
	lapLength += lengths[i]
end
local rng = Random.new()

local function service(name: string): any
	local ok, svc = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok and type(svc) == "table" then svc else nil
end

local function now(): number
	return os.clock()
end

local function site()
	return Sitios.get("Karting") :: any
end

-- Del sitio (x, z) al mundo, a la altura del asfalto
local function toWorld(x: number, z: number): Vector3
	local s = site()
	return Vector3.new(s.Center[1] + x, 0.15, s.Center[2] + z)
end

local function toLocal(p: Vector3): (number, number)
	local s = site()
	return p.X - s.Center[1], p.Z - s.Center[2]
end

-- Punto y dirección de la línea central a una distancia s desde la meta
local function along(s: number): (number, number, number, number)
	local startIdx = gates[1][3]
	local d = s % lapLength
	local i = startIdx
	for _ = 1, #points do
		local seg = lengths[i]
		if d <= seg then
			local a, b = points[i], points[i % #points + 1]
			local t = d / seg
			return a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, (b[1] - a[1]) / seg, (b[2] - a[2]) / seg
		end
		d -= seg
		i = i % #points + 1
	end
	local p = points[startIdx]
	return p[1], p[2], 1, 0
end

local function indexAt(s: number): number
	local startIdx = gates[1][3]
	local d = s % lapLength
	local i = startIdx
	for _ = 1, #points do
		if d <= lengths[i] then
			return i
		end
		d -= lengths[i]
		i = i % #points + 1
	end
	return startIdx
end

-- Sitio de la parrilla (slot 1..4): detrás de la meta, en dos filas
function KartService.gridFrame(slot: number): CFrame
	local back = 12 + math.floor((slot - 1) / 2) * 10
	local x, z, dx, dz = along(lapLength - back)
	local side = if slot % 2 == 1 then -5 else 5
	local px, pz = x + -dz * side, z + dx * side
	local p = toWorld(px, pz)
	return CFrame.new(p) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
end

---------------------------------------------------------------------
-- Semáforo, clasificación y récord
---------------------------------------------------------------------
local LIGHT_OFF, RED, GREEN = Color3.fromRGB(60, 20, 20), Color3.fromRGB(255, 40, 30), Color3.fromRGB(40, 230, 70)
local function lights(n: number, green: boolean?)
	for _, l in CollectionService:GetTagged("OcioKartLight") do
		if l:IsA("BasePart") then
			local k = tonumber(l:GetAttribute("Light")) or 0
			local on = green or k <= n
			l.Color = if green then GREEN elseif on then RED else LIGHT_OFF
			l.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

function KartService.boardText(): string
	local lines = { "🏁 MEJORES VUELTAS" }
	for i, row in board do
		if i > 8 then
			break
		end
		table.insert(lines, ("%d. %s  %s"):format(i, row.Name, KartTrack.formatTime(row.Time)))
	end
	if #board == 0 then
		table.insert(lines, "¡Sé el primero!")
	end
	return table.concat(lines, "\n")
end

local function refreshBoard()
	for _, b in CollectionService:GetTagged("OcioKartBoard") do
		local gui = b:FindFirstChildWhichIsA("SurfaceGui")
		local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.Text = KartService.boardText()
		end
	end
end

function KartService.board(): { { [string]: any } }
	return board
end

local function personalBest(player: Player, lapTime: number): boolean
	local Data = service("DataService")
	local data = Data and Data.get(player)
	if not data then
		return false
	end
	data.Ocio = if type(data.Ocio) == "table" then data.Ocio else {}
	local old = tonumber(data.Ocio.KartBest)
	if not old or lapTime < old then
		data.Ocio.KartBest = math.floor(lapTime * 100 + 0.5) / 100
		return old ~= nil
	end
	return false
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------
-- (las pruebas lo cambian: fuera de Roblox no hay PivotTo)
function KartService.moveBot(model: Model, cf: CFrame)
	model:PivotTo(cf)
end

local function spawnBots(session: Session)
	local Rides = require(script.Parent.Parent.World.Kit.Rides)
	local folder = Instance.new("Folder")
	folder.Name = "Karts_" .. session.Player.UserId
	folder.Parent = workspace
	session.Folder = folder
	local colors = { Color3.fromRGB(30, 120, 220), Color3.fromRGB(250, 190, 30), Color3.fromRGB(40, 170, 80) }
	for i = 1, KartService.BOTS do
		local cf = KartService.gridFrame(i + 1)
		local model = Rides.build("Kart", folder, cf, colors[i])
		model.Name = "KartMaquina"
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
			end
		end
		-- Piloto (casco)
		local helmet = Instance.new("Part")
		helmet.Name = "Helmet"
		helmet.Shape = Enum.PartType.Ball
		helmet.Size = Vector3.new(1.4, 1.4, 1.4)
		helmet.Color = colors[i]
		helmet.Anchored = true
		helmet.CanCollide = false
		helmet.CanQuery = false
		helmet.CFrame = cf * CFrame.new(0, 2.4, 0.9)
		helmet.Parent = model
		local pivot = Instance.new("Part")
		pivot.Name = "Pivot"
		pivot.Size = Vector3.new(1, 1, 1)
		pivot.Transparency = 1
		pivot.Anchored = true
		pivot.CanCollide = false
		pivot.CanQuery = false
		pivot.CFrame = cf
		pivot.Parent = model
		model.PrimaryPart = pivot
		local s = lapLength - (12 + math.floor(i / 2) * 10) -- (el mismo hueco que gridFrame(i + 1))
		local timer = KartTrack.newTimer(gates, KartTrack.LAPS, now())
		table.insert(session.Bots, { Model = model, S = s, Speed = 0, Skill = 0.45 + rng:NextNumber() * 0.4, Timer = timer, Lane = if (i + 1) % 2 == 1 then -5 else 5 })
	end
end

local function stepBots(session: Session, dt: number)
	if not session.Go then
		return
	end
	for _, bot in session.Bots do
		if bot.Timer.Done then
			continue
		end
		local idx = indexAt(bot.S)
		local target = KartTrack.botSpeed(points, idx, bot.Skill)
		local accel = if target > bot.Speed then 24 else 40
		bot.Speed = if target > bot.Speed then math.min(target, bot.Speed + accel * dt) else math.max(target, bot.Speed - accel * dt)
		bot.S += bot.Speed * dt
		-- La calle se va cerrando hacia el centro de la pista al arrancar
		bot.Lane *= math.max(0, 1 - dt * 0.4)
		local x, z, dx, dz = along(bot.S)
		local px, pz = x - dz * bot.Lane, z + dx * bot.Lane
		local cf = CFrame.new(toWorld(px, pz)) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
		KartService.moveBot(bot.Model, cf)
		KartTrack.feed(bot.Timer, now(), x, z)
	end
end

---------------------------------------------------------------------
-- Tanda
---------------------------------------------------------------------
local function finishFor(session: Session): number
	-- Puesto: 1 + máquinas que ya han acabado
	local place = 1
	for _, bot in session.Bots do
		if bot.Timer.Done then
			place += 1
		end
	end
	return place
end

local function liveRank(session: Session): number
	local timer = session.Timer
	if not timer then
		return 1
	end
	local mine = KartTrack.progress(timer)
	local place = 1
	for _, bot in session.Bots do
		if KartTrack.progress(bot.Timer) > mine then
			place += 1
		end
	end
	return place
end

function KartService.endSession(session: Session, why: string?)
	if session.Ended then
		return
	end
	session.Ended = true
	sessions[session.Player] = nil
	local player = session.Player
	player:SetAttribute("OcioKart", nil)
	if player.Parent then
		OcioFun.fire("KartEnd", {}, player)
		if why then
			OcioFun.say(player, "Info", why)
		end
	end
	local Vehicles = service("VehicleService")
	if Vehicles and player.Parent and Vehicles.ridingKind and Vehicles.ridingKind(player) == "Kart" then
		pcall(Vehicles.dismount, player, true)
	end
	if session.Kart then
		session.Kart:Destroy()
	end
	if session.Folder then
		session.Folder:Destroy()
	end
end

local function finish(session: Session, event: { [string]: any })
	session.Finished = true
	local player = session.Player
	local timer = session.Timer :: KartTrack.Timer
	local total = event.Total + session.Penalty
	local best = timer.Best or event.Best
	local place = if session.Mode == "Carrera" then finishFor(session) else 1
	local pos = KartTrack.insertBoard(board, player.DisplayName, player.UserId, best)
	refreshBoard()
	local record = personalBest(player, best)
	local prize = if session.Mode == "Carrera" then (KartTrack.Prize[place] or 0) else 0
	OcioFun.fire("KartFinish", { Place = place, Of = if session.Mode == "Carrera" then KartService.BOTS + 1 else 1, Total = total, Best = best, Record = record, Board = pos, Mode = session.Mode }, player)
	OcioFun.reward(player, {
		Fun = KartTrack.Fun + (if place == 1 and session.Mode == "Carrera" then 4 else 0),
		Money = prize,
		Xp = 10,
		Reason = "Karting",
		Event = "KartRace",
		Data = { Place = place, Best = best, Mode = session.Mode },
		Text = if session.Mode == "Carrera" then ("🏁 %dº puesto · mejor vuelta %s"):format(place, KartTrack.formatTime(best)) else ("🏁 Contrarreloj · mejor vuelta %s"):format(KartTrack.formatTime(best)),
	})
	if record then
		OcioFun.say(player, "Success", "🏆 ¡Récord personal en el Karting de San Roque!")
	end
	task.delay(4, function()
		KartService.endSession(session)
	end)
end

function KartService.step(session: Session, dt: number)
	local player = session.Player
	if not player.Parent then
		KartService.endSession(session)
		return
	end
	local Vehicles = service("VehicleService")
	local kart = session.Kart
	if not kart or not kart.Parent or (Vehicles and Vehicles.ridingKind and Vehicles.ridingKind(player) ~= "Kart") then
		KartService.endSession(session, "🏎️ Te has bajado del kart: se acaba la tanda.")
		return
	end
	if now() - session.Started > KartService.MAX_SECONDS then
		KartService.endSession(session, "🏎️ Se ha acabado el tiempo de la tanda.")
		return
	end
	local pos = kart:GetPivot().Position
	if not Sitios.inside("Karting", pos, 10) then
		KartService.endSession(session, "🏎️ El kart solo corre por el circuito.")
		return
	end
	if not session.Go then
		-- Salida anticipada: se ha movido de la parrilla antes del verde
		if (pos - session.Grid.Position).Magnitude > 4 and session.Penalty == 0 then
			session.Penalty = KartService.FALSE_START
			OcioFun.say(player, "Error", ("🚦 ¡Salida anticipada! +%d s"):format(KartService.FALSE_START))
		end
		return
	end
	stepBots(session, dt)
	if session.Finished then
		return
	end
	local x, z = toLocal(pos)
	for _, e in KartTrack.feed(session.Timer :: KartTrack.Timer, now(), x, z) do
		if e.Kind == "Lap" then
			OcioFun.fire("KartLap", { Lap = e.Lap, Laps = KartTrack.LAPS, Time = e.Time, Best = e.Best, NewBest = e.NewBest }, player)
		elseif e.Kind == "Finish" then
			finish(session, e)
		elseif e.Kind == "Gate" then
			local rank = liveRank(session)
			if rank ~= session.LastRank and session.Mode == "Carrera" then
				session.LastRank = rank
				OcioFun.fire("KartRank", { Place = rank, Of = KartService.BOTS + 1 }, player)
			end
		end
	end
end

-- Empieza una tanda. mode = "Carrera" | "Contrarreloj". Devuelve true si empieza.
function KartService.start(player: Player, mode: string): boolean
	if sessions[player] or player:GetAttribute("InSport") then
		return false
	end
	local count = 0
	for _ in sessions do
		count += 1
	end
	if count >= KartService.MAX_RACERS then
		OcioFun.say(player, "Error", "🏎️ La pista está llena. Espera a que acabe una tanda.")
		return false
	end
	local Data, Vehicles = service("DataService"), service("VehicleService")
	if not Data or not Vehicles or not Vehicles.launchAt then
		return false
	end
	if not Data.spend(player, KartTrack.Entry) then
		OcioFun.say(player, "Error", ("Te faltan %s para la tanda."):format(Format.money(KartTrack.Entry)))
		return false
	end
	local slot = (count % 4) + 1
	-- (con máquinas, el humano sale el primero; varias personas, cada una en su hueco)
	if mode == "Carrera" then
		slot = 1
	end
	local grid = KartService.gridFrame(slot)
	local kart = Vehicles.launchAt(player, "Kart", grid, { Color = Color3.fromRGB(230, 50, 40) })
	if not kart then
		Data.addMoney(player, KartTrack.Entry, false)
		return false
	end
	local session: Session = {
		Player = player,
		Mode = if mode == "Carrera" then "Carrera" else "Contrarreloj",
		Kart = kart,
		Timer = nil,
		Go = nil,
		Started = now(),
		Grid = grid,
		Penalty = 0,
		Bots = {},
		Finished = false,
		Ended = false,
	}
	sessions[player] = session
	player:SetAttribute("OcioKart", session.Mode)
	if session.Mode == "Carrera" then
		spawnBots(session)
	end
	OcioFun.fire("KartStart", { Mode = session.Mode, Laps = KartTrack.LAPS, Countdown = KartService.COUNTDOWN }, player)
	OcioFun.reward(player, { Event = "OcioPlayed", Data = { Activity = "Karting", Mode = session.Mode } })
	task.spawn(function()
		for n = 1, KartService.COUNTDOWN do
			if session.Ended then
				return
			end
			lights(n)
			OcioFun.fire("Sound", { Name = "Seleccion", At = grid.Position }, player)
			task.wait(1)
		end
		if session.Ended then
			return
		end
		lights(3, true)
		session.Go = now()
		session.Timer = KartTrack.newTimer(gates, KartTrack.LAPS, session.Go)
		for _, bot in session.Bots do
			bot.Timer = KartTrack.newTimer(gates, KartTrack.LAPS, session.Go)
		end
		OcioFun.fire("KartGo", {}, player)
		OcioFun.fire("Sound", { Name = "PistolaSalida", At = grid.Position }, player)
		task.delay(2, function()
			lights(0)
		end)
	end)
	return true
end

function KartService.session(player: Player): Session?
	return sessions[player]
end

function KartService.init()
	OcioFun.remote()
	for _, desk in CollectionService:GetTagged("OcioKartDesk") do
		if desk:IsA("BasePart") then
			for i, mode in { "Carrera", "Contrarreloj" } do
				local p = Instance.new("ProximityPrompt")
				p.ActionText = if mode == "Carrera" then "Correr" else "Contrarreloj"
				p.ObjectText = ("🏎️ Karts · %s · %d vueltas"):format(Format.money(KartTrack.Entry), KartTrack.LAPS)
				p.HoldDuration = 0.2
				p.MaxActivationDistance = 10
				p.RequiresLineOfSight = false
				p.KeyboardKeyCode = if i == 1 then Enum.KeyCode.E else Enum.KeyCode.R
				p.Parent = desk
				p.Triggered:Connect(function(player)
					KartService.start(player, mode)
				end)
			end
		end
	end
	refreshBoard()
	Players.PlayerRemoving:Connect(function(player)
		local s = sessions[player]
		if s then
			KartService.endSession(s)
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < KartService.TICK then
			return
		end
		local step = acc
		acc = 0
		for _, s in sessions do
			local ok, err = pcall(KartService.step, s, step)
			if not ok then
				warn("[Karting] " .. tostring(err))
				pcall(KartService.endSession, s)
			end
		end
	end)
end

return KartService
