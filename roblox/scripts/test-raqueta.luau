-- Prueba del tenis y el pádel de verdad (shared/Sports/RacketSim) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-raqueta.luau
--
-- Comprueba: el saque bota en el campo rival; un golpe bajo da en la red y es punto para el otro;
-- uno largo es fuera; dos botes son punto; en pádel la pelota sigue viva tras rebotar en la pared;
-- la calidad del golpe depende de la altura; partidos enteros (tenis 1c1, pádel 2c2) acaban y se
-- juegan rallies; una persona que golpea bien saca más puntos que una que no hace nada.

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check
local Sim = L.load("src/shared/Sports/RacketSim")

local function newSim(kind: string, seed: number, human: boolean?)
	local sim = Sim.new({ Kind = kind, Rng = L.Random.new(seed), Points = 7 })
	Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = human == true, Skill = 0.6 })
	if kind == "Padel" then
		Sim.addPlayer(sim, { Id = "a2", Team = 1, Skill = 0.55 })
	end
	Sim.addPlayer(sim, { Id = "b1", Team = 2, Skill = 0.45 })
	if kind == "Padel" then
		Sim.addPlayer(sim, { Id = "b2", Team = 2, Skill = 0.45 })
	end
	return sim
end

local function run(sim, seconds)
	local all = {}
	local t = 0
	while t < seconds do
		for _, e in Sim.step(sim, 1 / 30) do
			table.insert(all, e)
		end
		t += 1 / 30
	end
	return all
end
local function find(events, kind)
	for _, e in events do
		if e.Kind == kind then
			return e
		end
	end
	return nil
end

print("\n▶ 1. Reglas")
do
	local good = 0
	for seed = 1, 20 do
		local sim = newSim("Tenis", seed)
		Sim.start(sim)
		sim.Players.b1.Skill = 0 -- (el rival no se mueve: miramos dónde bota)
		sim.BotSpeed = 0
		Sim.serve(sim, sim.Server, nil, 1)
		local e = find(run(sim, 2.5), "Bounce")
		if e and e.P.X * Sim.side(3 - sim.Players[sim.LastHitter].Team) > 0 then
			good += 1
		end
	end
	check(good >= 17, ("Un buen saque bota en el campo rival (%d de 20)"):format(good))
	local sim = newSim("Tenis", 3)
	Sim.start(sim)
	sim.Phase = "Rally"
	sim.LastTeam, sim.Flying = 1, true
	sim.Ball.P = Vector3.new(-4, 1, 0)
	sim.Ball.V = Vector3.new(25, 1, 0)
	local p = find(run(sim, 2), "Point")
	check(p and p.Team == 2, "Golpe bajo a la red: punto para el otro")
	sim = newSim("Tenis", 4)
	Sim.start(sim)
	sim.Phase = "Rally"
	sim.LastTeam, sim.Flying = 1, true
	sim.BotSpeed = 0
	sim.Ball.P = Vector3.new(-10, 3, 0)
	sim.Ball.V = Vector3.new(60, 20, 0)
	p = find(run(sim, 3), "Point")
	check(p and p.Team == 2 and p.Why == "Fuera", "Demasiado largo: fuera")
	sim = newSim("Tenis", 5)
	Sim.start(sim)
	sim.Phase = "Rally"
	sim.LastTeam, sim.Flying = 1, true
	sim.BotSpeed = 0
	sim.Players.b1.P = Vector3.new(20, 0, 9)
	sim.Ball.P = Vector3.new(-6, 3, 0)
	sim.Ball.V = Sim.shot(sim, sim.Ball.P, Vector3.new(10, 0, -5), "Golpe")
	p = find(run(sim, 4), "Point")
	check(p and p.Team == 1, ("Dos botes sin devolverla: punto para quien la pegó (%s)"):format(tostring(p and p.Why)))
	local pad = newSim("Padel", 6)
	Sim.start(pad)
	pad.Phase = "Rally"
	pad.LastTeam, pad.Flying = 1, true
	pad.BotSpeed = 0
	pad.Ball.P = Vector3.new(-6, 3, 0)
	pad.Ball.V = Sim.shot(pad, pad.Ball.P, Vector3.new(15, 0, 0), "Golpe")
	local evs = run(pad, 1.5)
	local bounce = find(evs, "Bounce")
	local early = find(evs, "Point")
	check(bounce and (not early or early.Why ~= "Pared"), "Pádel: bota y rebota en la pared del fondo, y sigue viva")
	local q = newSim("Tenis", 7, true)
	Sim.start(q)
	local me = q.Players.yo
	me.P = Vector3.new(-10, 0, 0)
	q.Ball.P = Vector3.new(-10, 2.6, 1.6)
	local good2 = Sim.quality(q, me)
	q.Ball.P = Vector3.new(-10, 6, 0.2)
	check(good2 > 0.9 and Sim.quality(q, me) < 0.4, "A la altura de la cintura y al lado: golpe perfecto; muy alta y pegada: malo")
end

print("\n▶ 2. Partidos")
local function play(kind: string, seed: number, human: string?)
	local aim = L.Random.new(seed * 7 + 1) -- (determinista: la prueba no depende de la suerte)
	local sim = newSim(kind, seed, human ~= nil)
	Sim.start(sim)
	local over, hits, t = nil, 0, 0
	while t < 600 and not over do
		for _, e in Sim.step(sim, 1 / 30) do
			if e.Kind == "Over" then
				over = e
			elseif e.Kind == "Hit" then
				hits += 1

			elseif e.Kind == "Teleport" and e.Id == "yo" then
				Sim.setHuman(sim, "yo", e.P)
			end
		end
		if human == "good" then
			local me = sim.Players.yo
			if sim.Phase == "Serve" and sim.Server == "yo" then
				Sim.serve(sim, "yo", nil, 0.95)
			end
			local _, at = Sim.predict(sim, 2.6, 3)
			if sim.Phase == "Rally" and at and at.X < 0 and sim.LastTeam ~= 1 then
				local goal = at - Vector3.new(0, 0, 1.4)
				local to = Vector3.new(goal.X - me.P.X, 0, goal.Z - me.P.Z)
				if to.Magnitude > 0.05 then
					Sim.setHuman(sim, "yo", me.P + to.Unit * math.min(to.Magnitude, 17 / 30))
				end
			end
			if Sim.canHit(sim, me) and math.abs(sim.Ball.P.Y - 2.6) < 0.8 then
				Sim.hit(sim, "yo", Vector3.new(sim.Half * 0.6, 0, (aim:NextNumber() * 2 - 1) * 5), "Golpe")
			end
		end
		t += 1 / 30
	end
	return over, hits, t
end
do
	for _, kind in { "Tenis", "Padel" } do
		local o, hits = play(kind, 1, nil)
		check(o and (o.Goals == 7 or o.Against == 7) and hits >= 10, ("%s entre máquinas: %d-%d con %d golpes"):format(kind, o and o.Goals or -1, o and o.Against or -1, hits))
		local good, idle = 0, 0
		for seed = 1, 3 do
			local g = play(kind, seed + 10, "good")
			local i = play(kind, seed + 10, "idle")
			good += g and g.Goals or 0
			idle += i and i.Goals or 0
		end
		check(good > idle + 3, ("%s: golpear bien da puntos (%d frente a %d sin hacer nada)"):format(kind, good, idle))
		local _, _, took = play(kind, 40, "idle")
		check(took < 500, ("%s: sin hacer nada, acaba igual (%.0f s)"):format(kind, took))
	end
end

print("\n▶ 3. El servicio de verdad (RacketService) con un mundo de mentira")
local okService, errService = pcall(function()
	local CFrame = L.CFrame
	local root = { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), AssemblyLinearVelocity = Vector3.zero }
	local function place(cf)
		root.CFrame = cf
		root.Position = cf.Position
	end
	place(CFrame.new(5, 3.4, 2))
	function root:IsA(c)
		return c == "BasePart"
	end
	local humanoid = { HipHeight = 2, Health = 100, WalkSpeed = 16 }
	local char = {}
	function char:FindFirstChild(name)
		return if name == "HumanoidRootPart" then root else nil
	end
	function char:FindFirstChildOfClass(class)
		return if class == "Humanoid" then humanoid else nil
	end
	function char:PivotTo(cf)
		place(cf)
	end
	local leo = L.player("Leo", 5)
	leo.Character = char
	local sent, handlers = {}, {}
	local function fakeRemote(name)
		return {
			Name = name,
			FireClient = function(_, _player, kind, data)
				table.insert(sent, { Remote = name, Kind = kind, Data = data })
			end,
			OnServerEvent = { Connect = function(_, fn)
				handlers[name] = fn
			end },
		}
	end
	local remoteList = { Raqueta = fakeRemote("Raqueta"), RaquetaState = fakeRemote("RaquetaState") }
	L.services.ReplicatedStorage.Remotes = { FindFirstChild = function(_, name)
		return remoteList[name]
	end }
	local heartbeat
	L.services.RunService = { Heartbeat = { Connect = function(_, fn)
		heartbeat = fn
	end }, IsStudio = function()
		return false
	end }
	L.services.Players = { PlayerRemoving = { Connect = function() end }, GetPlayers = function()
		return { leo }
	end }
	local court = L.Instance.new("Part")
	court.Name = "Court"
	court.Size = Vector3.new(60, 0.4, 32)
	court.CFrame = CFrame.new(0, 0.2, 0)
	court.Position = Vector3.new(0, 0.2, 0)
	court.Parent = L.workspace
	L.mock("src/server/World/Npc", { create = function(name)
		local m = { Name = name, Attrs = {} }
		local r = { Size = Vector3.new(2, 2, 1), CFrame = CFrame.new() }
		m.PrimaryPart = r
		function m:SetAttribute(k, v)
			self.Attrs[k] = v
		end
		function m:GetAttribute(k)
			return self.Attrs[k]
		end
		function m:FindFirstChildOfClass()
			return { HipHeight = 2 }
		end
		function m:FindFirstChild(n)
			return if n == "HumanoidRootPart" then r else nil
		end
		function m:Destroy() end
		return m
	end })
	L.mock("src/server/Services/ProgressionService", { addXp = function() end })
	local RS = L.load("src/server/Services/RacketService")
	RS.init()
	handlers.Raqueta(leo, "Join", { Kind = "Tenis" })
	check(leo:GetAttribute("InSport") == "Raqueta", "«Raqueta» en la cancha: partido de tenis")
	local over = false
	for _ = 1, 30 * 400 do
		heartbeat(1 / 30)
		for i = #sent, math.max(1, #sent - 3), -1 do
			if sent[i].Kind == "Event" and sent[i].Data.Kind == "Over" then
				over = true
			end
		end
		if over then
			break
		end
	end
	check(over, "Sin hacer nada, el partido acaba (saques solos)")
	handlers.Raqueta(leo, "Leave", {})
	check(leo:GetAttribute("InSport") == nil, "Salir de la pista")
end)
check(okService, "El servicio funciona sin errores" .. (if okService then "" else ": " .. tostring(errService)))

print("")
if L.failures > 0 then
	print(("❌ test-raqueta: %d fallos"):format(L.failures))
	process.exit(1)
end
print("✅ test-raqueta: todo correcto")
process.exit(0)
