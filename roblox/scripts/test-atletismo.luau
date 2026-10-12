-- Prueba del atletismo de verdad (shared/Sports: Track, RaceSim, RaceStory) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-atletismo.luau
--
-- Comprueba:
--   1. La zancada: más rápido cuanto más rápido alternas los pies; repetir pie hace trastabillar;
--      a tope se gasta el aliento y sin aliento no se esprinta.
--   2. La recta sobre una pieza del mapa (a lo largo del lado más largo, calles a lo ancho).
--   3. Carreras: el que pulsa rápido gana a máquinas normales y el que pulsa despacio no; salida nula
--      (la primera se repite, la segunda descalifica); la carrera acaba siempre.
--   4. Relevos: coger el testigo a tiempo; si no lo coges, se cae, sales tarde, y la carrera acaba.
--   5. Lo que recibe la historia (puesto, ganar si llegas entre los N primeros).

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, L.CFrame
local check = L.check

local Track = L.load("src/shared/Sports/Track")
local Race = L.load("src/shared/Sports/RaceSim")
local Story = L.load("src/shared/Sports/RaceStory")

print("\n▶ 1. La zancada")
local function sprint(hz: number, seconds: number, sameFoot: boolean?): (number, number, { [string]: any })
	local st = Track.newStride()
	local t, dist, nextTap, foot = 0, 0, 0, "L"
	local top = 0
	while t < seconds do
		if hz > 0 and t >= nextTap then
			Track.tap(st, foot, t)
			if not sameFoot then
				foot = if foot == "L" then "R" else "L"
			end
			nextTap += 1 / hz
		end
		local v = Track.stepStride(st, t, 1 / 30, 1)
		top = math.max(top, v)
		dist += v / 30
		t += 1 / 30
	end
	return dist, top, st
end
do
	local slow = sprint(3, 4)
	local fast = sprint(7, 4)
	check(fast > slow * 1.3, ("Alternar rápido corre más (%.0f frente a %.0f studs en 4 s)"):format(fast, slow))
	local stumble = sprint(7, 4, true)
	check(stumble < slow, ("Repetir pie hace trastabillar (%.0f studs)"):format(stumble))
	local _, top, st = sprint(8, 12)
	check(st.Stamina < 0.3 and top <= 16 * Track.Stride.Max + 0.01, ("A tope se gasta el aliento (queda %.2f)"):format(st.Stamina))
	local none = sprint(0, 3)
	check(none < 0.5, "Sin pulsar no se corre")
end

do
	-- Nadando: más lento y hay que respirar
	local function swim(breathe: boolean): (number, number)
		local st = Track.newStride()
		local t, dist, nextTap, foot = 0, 0, 0, "L"
		while t < 8 do
			if t >= nextTap then
				Track.tap(st, foot, t)
				foot = if foot == "L" then "R" else "L"
				nextTap += 1 / 6
				if breathe and Track.needsAir(st) then
					Track.breathe(st, t)
				end
			end
			dist += Track.stepStride(st, t, 1 / 30, 1, true) / 30
			t += 1 / 30
		end
		return dist, st.Stamina
	end
	local run = sprint(6, 8)
	local withAir, airLeft = swim(true)
	local noAir, noAirLeft = swim(false)
	check(withAir < run * 0.8, ("Nadando se va más lento que corriendo (%.0f frente a %.0f)"):format(withAir, run))
	check(noAirLeft < airLeft and noAir < withAir, ("Sin respirar se gasta el aire y se acaba yendo más lento (%.0f frente a %.0f)"):format(noAir, withAir))
end

print("\n▶ 2. La recta")
do
	local cf = CFrame.new(10, 0.2, 5) * CFrame.Angles(0, math.rad(90), 0)
	local part = { Size = Vector3.new(80, 0.35, 50), CFrame = cf }
	local t = Track.fromPart(part, 4, 60, "Cole")
	check(t.Length == 60 and t.Lanes == 4, "Recta de 60 con 4 calles sobre el campo")
	local finish = Track.toWorld(t, Vector3.new(60, 0, 0))
	local start = Track.toWorld(t, Vector3.zero)
	check(math.abs((finish - start).Magnitude - 60) < 0.01 and math.abs(start.Y - 0.375) < 0.01, "Salida y meta a 60 studs, a ras del césped")
	check(math.abs(Track.lanePoint(t, 1, 0).Z - Track.lanePoint(t, 4, 0).Z) > 9, "Calles separadas a lo ancho")
end

local track = Track.new(CFrame.new(), 60, 4)

local function race(hz: number, seed: number, falseStarts: number?): ({ [string]: any }?, number)
	local sim = Race.new(track, { Mode = "Carrera", Rng = L.Random.new(seed) })
	Race.addRunner(sim, { Id = "yo", Lane = 1, Human = true })
	for i = 2, 4 do
		Race.addRunner(sim, { Id = "m" .. i, Lane = i, Skill = 0.45 })
	end
	Race.start(sim)
	local st = Track.newStride()
	local over, t, foot, nextTap, fs = nil, 0, "L", 0, falseStarts or 0
	while t < 120 and not over do
		for _, e in Race.step(sim, 1 / 30) do
			if e.Kind == "Over" then
				over = e
			end
		end
		local me = sim.Runners.yo
		if fs > 0 and sim.Phase == "Set" then
			fs -= 1
			Race.humanGo(sim, "yo")
		elseif sim.Phase == "Run" and not me.Running and not me.Done and sim.T - sim.GunAt > 0.2 then
			Race.humanGo(sim, "yo")
		end
		if me.Running then
			if t >= nextTap then
				Track.tap(st, foot, t)
				foot = if foot == "L" then "R" else "L"
				nextTap = t + 1 / hz
			end
			local v = Track.stepStride(st, t, 1 / 30, 1)
			Race.setHuman(sim, "yo", me.X + v / 30, v)
		end
		t += 1 / 30
	end
	return over, t
end

print("\n▶ 3. Carreras")
do
	local wins, slowWins = 0, 0
	for seed = 1, 10 do
		local o = race(6.5, seed)
		if o and o.Place == 1 then
			wins += 1
		end
		local s = race(3, seed + 50)
		if s and s.Place == 1 then
			slowWins += 1
		end
	end
	check(wins >= 7, ("Pulsando rápido (6,5 por segundo) se gana casi siempre: %d de 10"):format(wins))
	check(slowWins <= 2, ("Pulsando despacio no: %d de 10"):format(slowWins))
	local once = race(6.5, 3, 1)
	check(once and once.Place ~= nil and not once.Disqualified, "Una salida nula: se repite la salida y se corre")
	local twice, took = race(6.5, 3, 2)
	check(twice and twice.Disqualified and twice.Place == nil and took < 60, "Dos salidas nulas: descalificado, y la carrera acaba igual")
end

print("\n▶ 4. Relevos")
local function relay(takeIt: boolean, seed: number): ({ [string]: any }?, { string })
	local sim = Race.new(track, { Mode = "Relevo", Rng = L.Random.new(seed) })
	for leg = 1, 4 do
		Race.addRunner(sim, { Id = "a" .. leg, Team = 1, Lane = 1, Leg = leg, Human = leg == 4, Skill = 0.5 })
		Race.addRunner(sim, { Id = "b" .. leg, Team = 2, Lane = 2, Leg = leg, Skill = 0.45 })
	end
	Race.start(sim)
	local st = Track.newStride()
	local over, t, foot, nextTap = nil, 0, "L", 0
	local kinds = {}
	while t < 200 and not over do
		for _, e in Race.step(sim, 1 / 30) do
			table.insert(kinds, e.Kind .. (if e.Dropped then "!" else ""))
			if e.Kind == "Over" then
				over = e
			end
		end
		local me = sim.Runners.a4
		if takeIt and not me.Active and not me.Done then
			Race.take(sim, "a4")
		end
		if me.Running and sim.T >= (me.StartAt or 0) then
			if t >= nextTap then
				Track.tap(st, foot, t)
				foot = if foot == "L" then "R" else "L"
				nextTap = t + 1 / 6.5
			end
			local v = Track.stepStride(st, t, 1 / 30, 1)
			Race.setHuman(sim, "a4", me.X + v / 30, v)
		end
		t += 1 / 30
	end
	return over, kinds
end
do
	local good, kinds = relay(true, 1)
	local exchanges, drops = 0, 0
	for _, k in kinds do
		if k == "Exchange" then
			exchanges += 1
		elseif k == "Exchange!" then
			drops += 1
		end
	end
	check(good and good.Place ~= nil and exchanges >= 6 and drops == 0, ("Relevo cogiendo el testigo a tiempo: puesto %s, %d relevos"):format(tostring(good and good.Place), exchanges))
	local bad, kinds2 = relay(false, 1)
	local dropped = false
	for _, k in kinds2 do
		if k == "Exchange!" then
			dropped = true
		end
	end
	check(bad and dropped and bad.Place ~= nil, "Sin coger el testigo: se cae, sales tarde y la carrera acaba")
	check(good.Time and bad.Time and bad.Time > good.Time, "…y tardas más")
end

print("\n▶ 5. La historia")
do
	check(Story.result({ Game = "Carrera", Puesto = 2 }, { Place = 2 }).Won, "Segundo con Puesto = 2: clasificado")
	check(not Story.result({ Game = "Carrera", Puesto = 1 }, { Place = 2 }).Won, "Segundo en la final: no gana")
	check(not Story.result({ Game = "Carrera" }, { Place = nil, Disqualified = true }).Won, "Descalificado: no gana")
	check(not Story.result({ Game = "Relevo" }, nil).Won, "Sin resultado: no gana")
	check(Story.options({ Game = "Carrera", Rivals = { "A", "B", "C" } }).Lanes == 4, "Una calle por corredor")
	check(Story.maxSeconds({ Game = "Relevo" }) > 0, "Siempre hay tiempo máximo")
	local fs = require("@lune/fs")
	local bad, found = {}, 0
	local text = fs.readFile("src/shared/LifeStory/Misiones/Cole08_Torneo.luau")
	for line in text:gmatch("[^\n]+") do
		if line:find('Type = "MiniGame"') and (line:find("🏃") or line:find("relevo")) then
			found += 1
			local game = line:match('Game = "(%w+)"')
			if not Story.Games[game or ""] then
				table.insert(bad, tostring(game))
			end
		end
	end
	check(found >= 2 and #bad == 0, ("Las carreras del torneo se corren de verdad (%d pasos%s)"):format(found, if #bad > 0 then "; con barra: " .. table.concat(bad, ", ") else ""))
end

print("\n▶ 6. El servicio de verdad (RaceService) con un mundo de mentira")
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
	local eva = L.player("Eva", 99)
	eva.Character = char
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
	local remoteList = { Carrera = fakeRemote("Carrera"), CarreraState = fakeRemote("CarreraState") }
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
		return { eva }
	end }
	local field = L.Instance.new("Part")
	field.Name = "Pitch"
	field.Size = Vector3.new(80, 0.35, 50)
	field.CFrame = CFrame.new(0, 0.175, 0)
	field.Position = Vector3.new(0, 0.175, 0)
	field.Parent = L.workspace
	L.mock("src/server/World/Npc", { create = function(name)
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
		function m:ScaleTo() end
		function m:Destroy() end
		return m
	end })
	L.mock("src/server/Services/ProgressionService", { addXp = function() end })
	local RS = L.load("src/server/Services/RaceService")
	RS.init()
	local function lastEvent(kind)
		for i = #sent, 1, -1 do
			if sent[i].Kind == "Event" and sent[i].Data.Kind == kind then
				return sent[i].Data
			end
		end
		return nil
	end
	-- Carrera: corres de verdad (la raíz avanza por la calle a 24 studs/s tras el disparo)
	local result = nil
	local ok = RS.startStory(eva, { Game = "Carrera", Rivals = { "Alumno1", "Alumno2", "4.º B" }, Puesto = 2 }, function(r)
		result = r
	end)
	check(ok and eva:GetAttribute("InSport") == "Carrera", "Empieza la carrera sobre el campo (4 calles)")
	local trackInfo
	for _, m in sent do
		if m.Kind == "Session" then
			trackInfo = m.Data.Track
		end
	end
	local gunSeen = false
	for _ = 1, 30 * 20 do
		heartbeat(1 / 30)
		if lastEvent("Gun") then
			if not gunSeen then
				gunSeen = true
				handlers.Carrera(eva, "Go")
			end
			local loc = trackInfo.CFrame:PointToObjectSpace(root.Position)
			place(CFrame.new(trackInfo.CFrame:PointToWorldSpace(loc + Vector3.new(24 / 30, 0, 0))))
		end
		if lastEvent("Over") then
			break
		end
	end
	task.wait(2.8)
	heartbeat(1 / 30)
	check(gunSeen and result and result.Won and result.Score == 1, ("Corriendo rápido ganas (puesto %s)"):format(tostring(result and result.Score)))
	-- Relevo sin coger nunca el testigo ni moverte: acaba igual
	sent = {}
	local result2 = nil
	place(CFrame.new(0, 3.4, 0))
	RS.startStory(eva, { Game = "Relevo", Team = { "Sara", "Omar" }, Rivals = { "Bruno", "Ruben" } }, function(r)
		result2 = r
	end)
	for _ = 1, 30 * 100 do
		heartbeat(1 / 30)
		if lastEvent("Over") then
			break
		end
	end
	task.wait(2.8)
	heartbeat(1 / 30)
	check(result2 ~= nil and result2.Won == false, "Relevo sin hacer nada: acaba y la historia sigue (sin ganar)")
	check(eva:GetAttribute("InSport") == nil, "Y vuelves a tus botones")
	-- Carrera por gusto (botón «Deportes»): empieza y se puede dejar
	handlers.Carrera(eva, "Pickup", { Kind = "Carrera" })
	check(eva:GetAttribute("InSport") == "Carrera", "Carrera de velocidad por gusto en el campo")
	heartbeat(1 / 30)
	handlers.Carrera(eva, "Leave")
	check(eva:GetAttribute("InSport") == nil, "…y dejarla")
end)
check(okService, "El servicio funciona sin errores" .. (if okService then "" else ": " .. tostring(errService)))

print("")
if L.failures > 0 then
	print(("❌ test-atletismo: %d fallos"):format(L.failures))
	process.exit(1)
end
print("✅ test-atletismo: todo correcto")
process.exit(0)
