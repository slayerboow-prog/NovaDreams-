-- Prueba del baloncesto de verdad (shared/Sports: Court, Hoops, BasketSim, BasketStory) FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-baloncesto.luau
--
-- Comprueba:
--   1. El balón: bota cada vez menos, un tiro perfecto entra (de cerca, de media y de tres), uno muy
--      largo o muy corto no, al aro o al tablero rebota, y la canasta solo cuenta bajando por el aro.
--   2. El lanzamiento: soltar bien entra casi siempre; soltar mal, casi nunca; con un defensor encima
--      se falla más; las bandejas entran a menudo.
--   3. La pista del mapa: con dos aros (pista entera), con uno (media pista del parque) o sin suelo
--      (el gimnasio del colegio); los «Rim» de las ruedas no son aros.
--   4. Partidos entre máquinas (1c1, 2c2, 3c3, pista entera y media): sin errores, hay canastas,
--      rebotes y robos, y acaban.
--   5. Tandas de tiros (también sin tirar nunca: acaban igual) y lo que recibe la historia.

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame, Color3 = roblox.Vector3, L.CFrame, roblox.Color3
local check = L.check

local Court = L.load("src/shared/Sports/Court")
local Hoops = L.load("src/shared/Sports/Hoops")
local Sim = L.load("src/shared/Sports/BasketSim")
local Story = L.load("src/shared/Sports/BasketStory")

local R = Hoops.Config.Radius
local full = Court.new(CFrame.new(50, 0.4, 20), 60, 32, { [-1] = Court.hoop(60, -1, 9, 1), [1] = Court.hoop(60, 1, 9, 1) })

local function finite(v): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
end

local function fly(state, seconds, court)
	local events = {}
	local t = 0
	while t < seconds do
		for _, e in Hoops.step(state, 1 / 60, court or full) do
			table.insert(events, e)
		end
		t += 1 / 60
	end
	return events
end
local function count(events, kind): number
	local n = 0
	for _, e in events do
		if e.Kind == kind then
			n += 1
		end
	end
	return n
end

print("\n▶ 1. El balón")
do
	local drop = Hoops.new(Vector3.new(0, 6, 0))
	local evs = fly(drop, 3)
	local bounces = {}
	for _, e in evs do
		if e.Kind == "Bounce" then
			table.insert(bounces, e.Speed)
		end
	end
	check(#bounces >= 3 and bounces[2] < bounces[1] and bounces[3] < bounces[2], ("Bota cada vez menos (%d botes)"):format(#bounces))
	local rim = full.Hoops[1].Rim
	for _, d in { 4, 9, 15 } do
		local from = Vector3.new(rim.X - d, 4.6, rim.Z + 0.3)
		local s = Hoops.new(from)
		s.V = Hoops.shotVelocity(from, rim, Hoops.arcFor(d))
		local e = fly(s, 3)
		check(count(e, "Basket") == 1, ("Tiro perfecto desde %d studs: dentro"):format(d))
	end
	local from = Vector3.new(rim.X - 10, 4.6, 0)
	local long = Hoops.new(from)
	long.V = Hoops.shotVelocity(from, rim, 4) * 1.15
	check(count(fly(long, 3), "Basket") == 0, "Muy largo: fuera")
	local short = Hoops.new(from)
	short.V = Hoops.shotVelocity(from, rim, 4) * 0.85
	local se = fly(short, 3)
	check(count(se, "Basket") == 0, "Muy corto: fuera")
	local rimHit = Hoops.new(from)
	rimHit.V = Hoops.shotVelocity(from, rim + Vector3.new(0, 0, 1.15), 4)
	local re = fly(rimHit, 3)
	check(count(re, "Rim") >= 1, "Al aro: rebota en el hierro")
	local board = Hoops.new(from)
	board.V = Hoops.shotVelocity(from, full.Hoops[1].Board + Vector3.new(-0.3, 0.5, 1.2), 3)
	check(count(fly(board, 2), "Board") >= 1, "Al tablero: rebota")
	local up = Hoops.new(Vector3.new(rim.X, 2, rim.Z))
	up.V = Vector3.new(0, 30, 0)
	check(count(fly(up, 2), "Basket") == 0, "Por debajo del aro hacia arriba no cuenta")
	local wild = Hoops.new(Vector3.new(0, 3, 0))
	wild.V = Vector3.new(400, 20, -300)
	fly(wild, 4)
	check(finite(wild.P) and math.abs(wild.P.X) <= full.BoardX and math.abs(wild.P.Z) <= full.BoardZ, "Las paredes invisibles lo guardan")
end

print("\n▶ 2. El lanzamiento")
do
	local sim = Sim.new(full, { Mode = "Libre", Rng = L.Random.new(1) })
	local me = Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true })
	local rim = full.Hoops[1].Rim
	local function rate(dist: number, quality: number, contest: number): number
		local made = 0
		for seed = 1, 100 do
			me.P = Vector3.new(rim.X - dist, 0, 0.5)
			me.Facing = Vector3.new(1, 0, 0)
			local from, v = Sim.shotFor(sim, me, quality, seed, contest)
			local s = Hoops.new(from)
			s.V = v
			if count(fly(s, 3), "Basket") > 0 then
				made += 1
			end
		end
		return made
	end
	local perfect = rate(11, 1, 0)
	local bad = rate(11, 0.15, 0)
	local guarded = rate(11, 0.8, 1)
	local open = rate(11, 0.8, 0)
	local layup = rate(3, 0.5, 0)
	check(perfect >= 85, ("Suelta perfecta desde 11: %d de 100"):format(perfect))
	check(bad <= 35, ("Suelta mala desde 11: %d de 100"):format(bad))
	check(guarded < open, ("Con un defensor encima se falla más (%d frente a %d)"):format(guarded, open))
	check(layup >= 70, ("Bandeja: %d de 100"):format(layup))
	local three = rate(19, 1, 0)
	check(three >= 60, ("Triple perfecto: %d de 100"):format(three))
end

print("\n▶ 3. Pistas del mapa")
do
	local orange = Color3.fromRGB(230, 90, 30)
	local cf = CFrame.new(10, 0.2, 10) * CFrame.Angles(0, math.rad(30), 0)
	local floor = { Name = "Court", Size = Vector3.new(60, 0.4, 32), CFrame = cf, Position = cf.Position }
	local rims = {}
	for _, side in { -1, 1 } do
		local hoopCf = cf * CFrame.new(side * 31, 0, 0) * CFrame.Angles(0, math.rad(side * 90), 0)
		local rimCf = hoopCf * CFrame.new(0, 9, -2.3)
		local boardCf = hoopCf * CFrame.new(0, 10, -1)
		table.insert(rims, {
			Part = { Name = "Rim", Color = orange, Size = Vector3.new(0.2, 2, 2), Position = rimCf.Position, CFrame = rimCf },
			Board = { Name = "Backboard", Size = Vector3.new(6, 3.6, 0.3), Position = boardCf.Position, CFrame = boardCf },
		})
	end
	check(Court.isRim(rims[1].Part) and not Court.isRim({ Name = "Rim", Color = Color3.fromRGB(200, 204, 210), Size = Vector3.new(1.14, 1.9, 1.9) }), "Aro naranja sí; la llanta de una rueda no")
	local court = Court.fromParts(floor, rims, "Cole")
	check(court and court.Hoops[1] and court.Hoops[-1] and not court.Half, "Pista entera con dos canastas")
	if court then
		local h = court.Hoops[1]
		check(math.abs(h.Rim.Y - 8.8) < 0.3 and h.Rim.X > 25 and h.Normal.X < -0.9, ("Aro a %.1f de altura, mirando a la pista"):format(h.Rim.Y))
		local s = Hoops.new(Vector3.new(h.Rim.X - 8, 4.6, 0))
		s.V = Hoops.shotVelocity(s.P, h.Rim, 4)
		check(count(fly(s, 3, court), "Basket") == 1, "Y se encesta en ella")
	end
	local gym = Court.fromParts(nil, { rims[2] }, "Gimnasio")
	check(gym and gym.Half and gym.Hoops[1] and gym.Length == 20, "Sin suelo (gimnasio): media pista delante del aro")
end

print("\n▶ 4. Partidos entre máquinas")
local function playMatch(court, size: number, seed: number, seconds: number)
	local sim = Sim.new(court, { Mode = "Partido", Duration = seconds, Rng = L.Random.new(seed) })
	Sim.fillTeams(sim, size, { "Alex", "Omar" }, { "Bruno" })
	Sim.start(sim)
	local st = { Shots = 0, Baskets = 0, Rebounds = 0, Steals = 0, Blocks = 0, Over = false, Bad = 0 }
	local t = 0
	while t < seconds * 3 + 60 and not st.Over do
		for _, e in Sim.step(sim, 1 / 20) do
			if e.Kind == "Shot" then
				st.Shots += 1
			elseif e.Kind == "Basket" then
				st.Baskets += 1
			elseif e.Kind == "Rebound" then
				st.Rebounds += 1
			elseif e.Kind == "Steal" and e.Ok then
				st.Steals += 1
			elseif e.Kind == "Block" then
				st.Blocks += 1
			elseif e.Kind == "Over" then
				st.Over = true
			end
		end
		if not finite(sim.Ball.P) then
			st.Bad += 1
		end
		t += 1 / 20
	end
	return sim, st
end
do
	local half = Court.new(CFrame.new(0, 0, 0), 22, 20, { [1] = Court.hoop(22, 1, 9, 1) })
	for _, cfg in { { full, 3, 1 }, { full, 2, 2 }, { half, 1, 3 }, { half, 3, 4 } } do
		local ok, sim, st = pcall(playMatch, cfg[1], cfg[2], cfg[3], 120)
		if not ok then
			check(false, "Partido: " .. tostring(sim))
			continue
		end
		local o = Sim.outcome(sim)
		check(st.Over and st.Bad == 0 and st.Shots >= 8 and st.Baskets >= 2, ("%dc%d %s: %d-%d · %d tiros, %d canastas, %d rebotes, %d robos, %d tapones"):format(
			cfg[2], cfg[2], if cfg[1].Half then "media pista" else "pista entera", o.Goals, o.Against, st.Shots, st.Baskets, st.Rebounds, st.Steals, st.Blocks))
	end
	-- En media pista las máquinas no meten casi todo (antes: más del 70 %, casi todo bandejas)
	local shots, baskets = 0, 0
	for seed = 11, 14 do
		local ok, _, st = pcall(playMatch, half, 2, seed, 90)
		if ok then
			shots += st.Shots
			baskets += st.Baskets
		end
	end
	check(shots > 20 and baskets / shots < 0.6, ("Media pista 2c2: las máquinas fallan lo suyo (%d de %d)"):format(baskets, shots))
end

print("\n▶ 5. Tandas de tiros y la historia")
do
	local function tanda(seed: number, quality: number?, spots: string?)
		local sim = Sim.new(full, { Mode = "Tiros", Rounds = 6, Need = 3, Spots = spots, Rng = L.Random.new(seed) })
		Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true })
		Sim.start(sim)
		local over, t = nil, 0
		while t < 400 and not over do
			for _, e in Sim.step(sim, 1 / 20) do
				if e.Kind == "Over" then
					over = e
				elseif e.Kind == "Teleport" and e.Id == "yo" then
					Sim.setHuman(sim, "yo", e.P, Vector3.zero, e.Facing)
				end
			end
			if quality and sim.Phase == "ShotReady" and sim.Owner == "yo" and sim.T > sim.PhaseUntil - 24 then
				Sim.shoot(sim, "yo", quality, math.floor(t * 1000))
			end
			t += 1 / 20
		end
		return over, t
	end
	local good = tanda(1, 0.95)
	check(good and good.Hits >= 3, ("Tiros libres bien soltados: %d de %d"):format(good and good.Hits or -1, good and good.Taken or -1))
	local varied = tanda(2, 0.95, "Variado")
	check(varied and varied.Over, ("Tiros desde sitios distintos: %d de %d"):format(varied and varied.Hits or -1, varied and varied.Taken or -1))
	local idle, took = tanda(3, nil)
	check(idle and idle.Hits == 0 and idle.Taken >= 3 and took < 200, ("Sin tirar nunca, acaba igual (%.0f s)"):format(took))
	local r = Story.result({ Game = "Canastas", Need = 3 }, good)
	check(r.Won == ((good and good.Hits or 0) >= 3) and r.Score == (good and good.Hits), "La historia recibe las canastas")
	local m = Story.result({ Game = "Baloncesto" }, { Goals = 12, Against = 9 })
	check(m.Won and m.Score == 12 and m.Against == 9, "Partido 12-9: victoria")
	check(not Story.result({ Game = "Baloncesto" }, { Goals = 4, Against = 0 }, true).Won, "Irse a mitad no gana")
	local opts = Story.options({ Game = "Baloncesto", Team = { "Alex", "Omar" }, Rivals = { "Bruno", "Ruben", "Alumno1" } })
	check(opts.Mode == "Partido" and opts.Size == 3, "Partido de la historia: 3c3")
	check(Story.maxSeconds({ Game = "Canastas", Rounds = 8 }) > 0, "Siempre hay tiempo máximo")
	-- Los pasos de baloncesto de las misiones se juegan de verdad
	local fs = require("@lune/fs")
	local bad, found = {}, 0
	for _, file in fs.readDir("src/shared/LifeStory/Misiones") do
		for line in fs.readFile("src/shared/LifeStory/Misiones/" .. file):gmatch("[^\n]+") do
			if line:find('Type = "MiniGame"') and line:find("🏀") then
				found += 1
				local game = line:match('Game = "(%w+)"')
				if not Story.Games[game or ""] then
					table.insert(bad, file .. ": " .. tostring(game))
				end
			end
		end
	end
	check(found >= 3 and #bad == 0, ("Los pasos de baloncesto se juegan de verdad (%d pasos%s)"):format(found, if #bad > 0 then "; con barra: " .. table.concat(bad, ", ") else ""))
end

print("\n▶ 6. El servicio de verdad (BasketService) con un mundo de mentira")
local okService, errService = pcall(function()
	local task = require("@lune/task")
	local root = { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), AssemblyLinearVelocity = Vector3.zero }
	local function place(cf)
		root.CFrame = cf
		root.Position = cf.Position
	end
	place(CFrame.new(0, 3.4, 0))
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
	function char:GetScale()
		return 1
	end
	function char:PivotTo(cf)
		place(cf)
	end
	local ana = L.player("Ana", 88)
	ana.Character = char
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
	local remoteList = { Basket = fakeRemote("Basket"), BasketState = fakeRemote("BasketState"), Notify = fakeRemote("Notify") }
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
		return { ana }
	end }
	-- La cancha del colegio: suelo 60 × 32 y dos canastas
	local model = L.Instance.new("Model")
	model.Name = "Colegio"
	model.Parent = L.workspace
	local function part(name, size, cf, color)
		local p = L.Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Position = cf.Position
		if color then
			p.Color = color
		end
		p.Parent = model
		return p
	end
	part("Court", Vector3.new(60, 0.4, 32), CFrame.new(0, 0.2, 0))
	for _, side in { -1, 1 } do
		local hoopCf = CFrame.new(side * 31, 0, 0) * CFrame.Angles(0, math.rad(side * 90), 0)
		part("Backboard", Vector3.new(6, 3.6, 0.3), hoopCf * CFrame.new(0, 10, -1))
		part("Rim", Vector3.new(0.2, 2, 2), hoopCf * CFrame.new(0, 9, -2.3), Color3.fromRGB(230, 90, 30))
	end
	local bots = 0
	L.mock("src/server/World/Npc", { create = function(name)
		bots += 1
		local m = { Name = name, Attrs = {}, Parent = true }
		local r = { Size = Vector3.new(2, 2, 1), CFrame = CFrame.new(), Position = Vector3.zero }
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
		function m:PivotTo(cf)
			r.CFrame = cf
		end
		function m:ScaleTo() end
		function m:Destroy()
			self.Parent = nil
		end
		return m
	end })
	L.mock("src/server/Services/ProgressionService", { addXp = function() end })
	local BS = L.load("src/server/Services/BasketService")
	BS.init()
	local function run(seconds)
		for _ = 1, math.floor(seconds * 30) do
			heartbeat(1 / 30)
		end
	end
	-- Tanda de tiros libres de la historia: suelta siempre en el verde
	local result = nil
	local ok = BS.startStory(ana, { Game = "Canastas", Rounds = 6, Need = 3, Spots = "Libres", Title = "Tiros libres" }, function(r)
		result = r
	end)
	check(ok and ana:GetAttribute("InSport") == "Baloncesto", "Empieza la tanda en la cancha")
	for _ = 1, 6 do
		run(0.4)
		handlers.Basket(ana, "Shot", { Quality = 1, Seed = 1234 })
		run(3.5)
		if result then
			break
		end
	end
	task.wait(3.3)
	run(0.1)
	check(result ~= nil and result.Won and result.Score >= 3, ("Tiros perfectos: la historia recibe %s canastas y gana"):format(tostring(result and result.Score)))
	-- Partido 3c3 y te vas: acaba sin ganar
	local result2 = nil
	place(CFrame.new(0, 3.4, 0))
	BS.startStory(ana, { Game = "Baloncesto", Seconds = 60, Size = 3, Team = { "Alex", "Omar" }, Rivals = { "Alumno1", "Alumno2" } }, function(r)
		result2 = r
	end)
	run(1)
	check(bots >= 5, ("Partido 3c3: %d máquinas en la pista"):format(bots))
	place(CFrame.new(300, 3.4, 300))
	local t0 = os.clock()
	while not result2 and os.clock() - t0 < 45 do
		run(0.5)
		task.wait(0.5)
	end
	check(result2 ~= nil and result2.Won == false, "Te vas de la pista: acaba y la historia sigue")
	place(CFrame.new(3, 3.4, 2))
	handlers.Basket(ana, "Join", {})
	run(0.3)
	check(ana:GetAttribute("InSport") == "Baloncesto", "«Jugar» en la cancha: tirar libre")
	handlers.Basket(ana, "Leave", {})
	check(ana:GetAttribute("InSport") == nil, "Dejar de jugar")
end)
check(okService, "El servicio funciona sin errores" .. (if okService then "" else ": " .. tostring(errService)))

-- 6. La máquina de canastas de los recreativos (la jaula de Kit/Civic, con la física de verdad)
print("▶ Máquina de canastas (recreativos)")
do
	local Arcade = L.load("src/shared/Sports/ArcadeHoops")
	-- Como en Civic.arcade: mostrador en z = -2.6, aro a 6.2 de alto en z = 8.9, tablero en z = 9.9
	local base = CFrame.new(40, 10, -30) * CFrame.Angles(0, math.rad(35), 0)
	local function w(x, y, z)
		return base:PointToWorldSpace(Vector3.new(x, y, z))
	end
	local m = Arcade.machine(w(3.5, 4.4, -3), w(3.5, 6.2, 8.9), 1.1, w(3.5, 7.4, 9.9), Vector3.new(4.4, 3, 0.3), 10.4, 2.4)
	local hoop = m.Court.Hoops[1]
	check(math.abs(hoop.Rim.Y - 5.8) < 0.01 and hoop.Rim.X > m.From.X + 10, "Máquina: el aro, alto y al fondo de la jaula")
	local allFinite = true
	local function rate(power: number): number
		local n = 0
		for seed = 1, 40 do
			local s = Arcade.shoot(m, power, L.Random.new(seed))
			local t = 0
			while t < Arcade.Life do
				local scored = Arcade.step(m, s, 1 / 60)
				if scored then
					n += 1
					break
				end
				t += 1 / 60
			end
			allFinite = allFinite and finite(s.P)
		end
		return n / 40
	end
	local good, short, long = rate(Arcade.Sweet), rate(0.4), rate(1)
	check(good >= 0.85, ("Máquina: soltar en la franja dorada entra casi siempre (%.0f %%)"):format(good * 100))
	check(short <= 0.1, ("Máquina: soltar pronto se queda corto (%.0f %%)"):format(short * 100))
	check(long <= 0.15, ("Máquina: soltar tarde se va largo (%.0f %%)"):format(long * 100))
	local edge = rate(Arcade.Sweet - Arcade.Window - 0.06)
	check(allFinite, "Máquina: el balón nunca se va a NaN")
	check(edge < good, ("Máquina: un poco fuera de la franja entra menos (%.0f %%)"):format(edge * 100))
	-- La barra sube y baja; con racha va más deprisa
	check(math.abs(Arcade.meter(Arcade.Period * 0.5) - 0.5) < 1e-6 and math.abs(Arcade.meter(Arcade.Period * 1.5) - 0.5) < 1e-6, "Máquina: la barra sube y baja")
	check(Arcade.meter(Arcade.Period * 0.5, 10) > 0.6, "Máquina: con racha la barra va más rápida")
	-- En 20 s, tirando sin parar y perfecto, no se pasa del tope del servidor (50 canastas)
	local most = math.floor(20 / (Arcade.Reload + (Arcade.Sweet * Arcade.Period) / 2))
	check(most <= 50, ("Máquina: ni perfecto se pasa del tope del servidor (%d)"):format(most))
end

print("")
if L.failures > 0 then
	print(("❌ test-baloncesto: %d fallos"):format(L.failures))
	process.exit(1)
end
print("✅ test-baloncesto: todo correcto")
process.exit(0) -- (los bucles del servicio siguen vivos: se sale aquí)
