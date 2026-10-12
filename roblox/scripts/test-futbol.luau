-- Prueba del fútbol de verdad (shared/Sports) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-futbol.luau
--
-- Comprueba:
--   1. El balón (Sports/Ball): rueda y se para, bota cada vez menos, un tiro a puerta vacía es gol, al
--      poste rebota y no cuenta, dentro de la red se queda, las vallas lo guardan, el efecto curva y
--      un pase raso llega a donde se pide (ni corto ni largo).
--   2. El campo (Sports/Pitch): salidas por banda y por fondo, punto de penalti y la descripción de un
--      campo del mapa a partir de sus postes.
--   3. El portero (Sports/FootballAI): para casi siempre el tiro flojo al centro y casi nunca el
--      fuerte a la escuadra; un tiro que va fuera lo deja ir.
--   4. Las decisiones: cerca de la portería se tira; apretado y con un compañero libre se pasa; si
--      no, se conduce.
--   5. Partidos enteros entre máquinas (3c3 y 5c5): sin errores, el balón siempre dentro del recinto
--      y sin NaN, hay golpeos y goles, saques de banda/puerta/córner, y el partido acaba.
--   6. Penaltis (con persona de mentira que chuta a la escuadra) y pases; y si no chutas nunca, los
--      penaltis acaban igual (la historia no se para).
--   7. La historia: el resultado del juego se convierte en el de siempre (ganar/perder/empate, goles).

local process = require("@lune/process")
local fakeRemote_onServer: any = nil
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, L.CFrame
local check = L.check

local Pitch = L.load("src/shared/Sports/Pitch")
local Ball = L.load("src/shared/Sports/Ball")
local AI = L.load("src/shared/Sports/FootballAI")
local Sim = L.load("src/shared/Sports/FootballSim")
local Story = L.load("src/shared/Sports/FootballStory")

local R = Ball.Config.Radius
local school = Pitch.new(CFrame.new(100, 0.35, -40), 80, 50, { GoalLine = 39, GoalWidth = 12, GoalHeight = 6 })

local function finite(v): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
end

local function run(state, seconds, pitch, bodies)
	local events = {}
	local t = 0
	while t < seconds do
		for _, e in Ball.step(state, 1 / 60, pitch or school, bodies) do
			table.insert(events, e)
		end
		t += 1 / 60
	end
	return events
end
local function has(events, kind): boolean
	for _, e in events do
		if e.Kind == kind then
			return true
		end
	end
	return false
end

print("\n▶ 1. El balón")
do
	local s = Ball.new(Vector3.new(0, R, 0))
	s.V = Vector3.new(20, 0, 0)
	run(s, 8)
	check(s.V.Magnitude == 0 and s.P.X > 5 and s.P.X < 30, ("Rueda y se para (recorre %.1f studs a 20 studs/s)"):format(s.P.X))

	local drop = Ball.new(Vector3.new(0, 10, 0))
	local heights, lastY, rising = {}, drop.P.Y, false
	for _ = 1, 600 do
		Ball.step(drop, 1 / 120, school)
		if drop.V.Y > 0 then
			rising = true
		elseif rising and drop.V.Y <= 0 then
			table.insert(heights, drop.P.Y)
			rising = false
		end
		lastY = drop.P.Y
	end
	check(#heights >= 2 and heights[2] < heights[1] and heights[1] < 10, ("Bota cada vez menos (%d botes, %.1f → %.1f)"):format(#heights, heights[1] or 0, heights[2] or 0))
	check(math.abs(lastY - R) < 0.05, "Acaba quieto en el césped")

	local shot = Ball.new(Vector3.new(25, R, 0))
	shot.V = select(1, Ball.shotVelocity(Vector3.new(1, 0, 0), 0.6, 0, 0))
	local ev = run(shot, 3)
	check(has(ev, "Goal") and shot.InGoal == 1, "Tiro a puerta vacía: gol")
	check(shot.P.X <= school.GoalLine + school.GoalDepth and math.abs(shot.P.Z) <= school.GoalWidth / 2 and shot.P.Y < school.GoalHeight, "El balón se queda dentro de la red")

	local post = Ball.new(Vector3.new(25, 3, 6))
	post.V = Vector3.new(60, 0, 0)
	local pev = run(post, 2)
	check(has(pev, "Post") and not has(pev, "Goal"), "Al poste: rebota y no es gol")

	local high = Ball.new(Vector3.new(20, R, 0))
	high.V = select(1, Ball.shotVelocity(Vector3.new(1, 0, 0), 1, 0.8, 0))
	local hev = run(high, 3)
	check(not has(hev, "Goal"), "Pasarse de fuerza con vaselina manda el balón por encima")

	local wild = Ball.new(Vector3.new(0, R, 0))
	wild.V = Vector3.new(0, 30, 300)
	run(wild, 5)
	check(math.abs(wild.P.Z) <= school.BoardZ and math.abs(wild.P.X) <= school.BoardX and finite(wild.P), "Las vallas invisibles no lo dejan escapar del recinto")

	local straight = Ball.new(Vector3.new(-20, R, 0))
	straight.V, straight.Spin = Ball.shotVelocity(Vector3.new(1, 0, 0), 0.7, 0, 0)
	local curled = Ball.new(Vector3.new(-20, R, 0))
	curled.V, curled.Spin = Ball.shotVelocity(Vector3.new(1, 0, 0), 0.7, 0, 1)
	run(straight, 0.4)
	run(curled, 0.4)
	check(math.abs(straight.P.Z) < 0.01 and math.abs(curled.P.Z) > 0.6, ("El efecto curva el tiro (%.2f studs de lado)"):format(curled.P.Z))

	for _, d in { 10, 20, 32 } do
		local pass = Ball.new(Vector3.new(-30, R, 0))
		pass.V = Ball.passVelocity(Vector3.new(1, 0, 0), d)
		local where
		for _ = 1, 600 do
			Ball.step(pass, 1 / 60, school)
			if pass.V.Magnitude <= Ball.Config.Pass.Arrive + 0.5 then
				where = pass.P.X + 30
				break
			end
		end
		check(where and math.abs(where - d) < d * 0.18 + 1, ("Pase raso de %d studs: llega a %.1f"):format(d, where or -1))
	end
	local lob = Ball.new(Vector3.new(-30, R, 0))
	lob.V = Ball.passVelocity(Vector3.new(1, 0, 0), 50)
	local landed
	for _ = 1, 300 do
		local evs = Ball.step(lob, 1 / 60, school)
		if #evs > 0 and evs[1].Kind == "Bounce" then
			landed = lob.P.X + 30
			break
		end
	end
	check(landed and landed > 30 and landed < 55, ("Pase largo por alto: cae a %.1f de 50"):format(landed or -1))

	local nan = Ball.new(Vector3.new(0, R, 0))
	nan.V = Vector3.new(0 / 0, 0, 0)
	Ball.step(nan, 0.1, school)
	check(finite(nan.P) and finite(nan.V), "Un NaN nunca se queda en el balón")

	local body = Ball.new(Vector3.new(-5, 2, 0))
	body.V = Vector3.new(40, 0, 0)
	local bev = run(body, 0.5, school, { { Id = "x", A = Vector3.new(0, 0.5, 0), B = Vector3.new(0, 4, 0), R = 0.8 } })
	check(has(bev, "Block") and body.P.X < 0, "Un jugador en medio para el balón")
end

print("\n▶ 2. El campo")
do
	check(Pitch.exit(school, Vector3.new(0, R, 26)) == "Side", "Fuera por la banda")
	check(Pitch.exit(school, Vector3.new(40, R, 10)) == "End", "Fuera por el fondo")
	check(Pitch.exit(school, Vector3.new(40, R, 2)) == nil, "Dentro de la portería no es «fuera»")
	check(Pitch.exit(school, Vector3.new(10, R, 10)) == nil, "Dentro del campo")
	local spot = Pitch.penaltySpot(school, 1)
	check(spot.X > 25 and spot.X < 32, ("Punto de penalti a %.1f de la portería"):format(school.GoalLine - spot.X))
	-- Un campo del mapa: césped de 80×50 con postes a ±39 y 12 de ancho
	local cf = CFrame.new(0, 0.18, 0) * CFrame.Angles(0, math.rad(90), 0)
	local part = { Size = Vector3.new(80, 0.35, 50), CFrame = cf, Position = cf.Position, Name = "Pitch" }
	local sibs = {}
	for _, sx in { -1, 1 } do
		for _, z in { -6, 6 } do
			local p = cf * CFrame.new(sx * 39, 3.3, z)
			table.insert(sibs, { Name = "GoalPost", Position = p.Position, CFrame = p, Size = Vector3.new(0.4, 6, 0.4) })
		end
	end
	local described = Pitch.fromPart(part, sibs, "Colegio")
	check(math.abs(described.GoalLine - 39) < 0.1 and math.abs(described.GoalWidth - 12) < 0.1 and math.abs(described.GoalHeight - 6) < 0.1,
		("Campo del mapa: línea %.1f, portería %.1f × %.1f"):format(described.GoalLine, described.GoalWidth, described.GoalHeight))
	local worldGoal = Pitch.toWorld(described, Vector3.new(39, 0, 0))
	check((worldGoal - (cf * CFrame.new(39, 0.175, 0)).Position).Magnitude < 0.05, "Las coordenadas del campo giran con él")
end

print("\n▶ 3. El portero")
do
	local function penaltyTrial(seed: number, aimZ: number, power: number, aimY: number?): string
		local sim = Sim.new(school, { Mode = "Penaltis", Rounds = 1, Need = 1, Rng = L.Random.new(seed) })
		Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true, Role = "FW" })
		Sim.addPlayer(sim, { Id = "gk", Team = 2, Role = "GK", Skill = 0.5 })
		Sim.start(sim)
		Sim.step(sim, 0.1)
		local spot = Pitch.penaltySpot(school, 1)
		Sim.setHuman(sim, "yo", spot - Vector3.new(1.5, 0, 0), Vector3.zero, Vector3.new(1, 0, 0))
		local target = Vector3.new(school.GoalLine, 0, aimZ)
		local ok = Sim.kick(sim, "yo", { Kind = "Shoot", Dir = target - spot, Power = power })
		assert(ok, "no se pudo chutar")
		local result = "?"
		for _ = 1, 200 do
			for _, e in Sim.step(sim, 1 / 30) do
				if e.Kind == "PenResult" then
					result = if e.Ok then "Goal" else e.Reason
				end
			end
			if result ~= "?" then
				break
			end
		end
		return result
	end
	local saved, scoredCorner, wide, medium = 0, 0, 0, 0
	for seed = 1, 60 do
		if penaltyTrial(seed, 0, 0.3) ~= "Goal" then
			saved += 1
		end
		if penaltyTrial(seed + 1000, 5.2, 0.85) == "Goal" then
			scoredCorner += 1
		end
		if penaltyTrial(seed + 3000, 3, 0.5) == "Goal" then
			medium += 1
		end
		if penaltyTrial(seed + 2000, 9.5, 0.6) ~= "Goal" then
			wide += 1
		end
	end
	check(saved >= 40, ("Tiro flojo al centro: lo para casi siempre (%d de 60)"):format(saved))
	check(scoredCorner >= 45, ("Tiro fuerte y ajustado al palo: casi siempre gol (%d de 60)"):format(scoredCorner))
	check(medium >= 12 and medium <= 48, ("Tiro a media altura y a media fuerza: a veces lo para (%d goles de 60)"):format(medium))
	check(wide == 60, "Tiro desviado: fuera")
	-- Tiro desde lejos en juego: el portero se estira hacia el balón
	local sim = Sim.new(school, { Mode = "Libre", Rng = L.Random.new(7) })
	Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true, Role = "FW" })
	Sim.addPlayer(sim, { Id = "gk", Team = 2, Role = "GK", Skill = 0.8 })
	Sim.start(sim)
	Sim.step(sim, 0.5)
	Sim.setHuman(sim, "yo", Vector3.new(18, 0, 0), Vector3.zero, Vector3.new(1, 0, 0))
	sim.Ball.P = Vector3.new(19.5, R, 0)
	Sim.kick(sim, "yo", { Kind = "Shoot", Dir = Vector3.new(school.GoalLine - 19.5, 0, 4.5), Power = 0.55 })
	local dived = false
	for _ = 1, 40 do
		Sim.step(sim, 1 / 30)
		if sim.Players.gk.Dive then
			dived = true
		end
	end
	check(dived, "En juego, el portero se estira a un tiro a puerta")
end

print("\n▶ 4. Decisiones")
do
	local sim = Sim.new(school, { Mode = "Partido", Rng = L.Random.new(3) })
	Sim.addPlayer(sim, { Id = "a", Team = 1, Role = "FW", Skill = 0.6, P = Vector3.new(30, 0, 2) })
	Sim.addPlayer(sim, { Id = "gk", Team = 2, Role = "GK", P = Vector3.new(38, 0, 0) })
	Sim.arrange(sim)
	sim.Players.a.Role = "FW"
	local shoot = AI.carrierDecision(sim, sim.Players.a, L.Random.new(1))
	check(shoot.Kind == "Shoot", "En el área, tira")
	local sim2 = Sim.new(school, { Mode = "Partido", Rng = L.Random.new(3) })
	Sim.addPlayer(sim2, { Id = "a", Team = 1, Role = "MF", P = Vector3.new(-20, 0, 0) })
	Sim.addPlayer(sim2, { Id = "b", Team = 1, Role = "FW", P = Vector3.new(-5, 0, 15) })
	Sim.addPlayer(sim2, { Id = "x", Team = 2, Role = "DF", P = Vector3.new(-17, 0, 0) })
	sim2.Players.a.Role, sim2.Players.b.Role = "MF", "FW"
	local passes = 0
	for seed = 1, 20 do
		local d = AI.carrierDecision(sim2, sim2.Players.a, L.Random.new(seed))
		if d.Kind == "Pass" and d.To == "b" then
			passes += 1
		end
	end
	check(passes >= 14, ("Apretado y con un compañero libre: pasa (%d de 20)"):format(passes))
	local sim3 = Sim.new(school, { Mode = "Partido", Rng = L.Random.new(3) })
	Sim.addPlayer(sim3, { Id = "a", Team = 1, Role = "MF", P = Vector3.new(-25, 0, 0) })
	Sim.addPlayer(sim3, { Id = "x", Team = 2, Role = "DF", P = Vector3.new(10, 0, 10) })
	sim3.Players.a.Role = "MF"
	local d3 = AI.carrierDecision(sim3, sim3.Players.a, L.Random.new(2))
	check(d3.Kind == "Dribble" and d3.Target.X > -25, "Solo y lejos: conduce hacia delante")
end

print("\n▶ 5. Partidos enteros entre máquinas")
local function playMatch(size: number, seed: number, seconds: number, pitch)
	local sim = Sim.new(pitch or school, { Mode = "Partido", Duration = seconds, Rng = L.Random.new(seed) })
	Sim.fillTeams(sim, size, { "Nico", "Sara", "Omar" }, { "Bruno", "Ruben" }, { Keeper1 = "Omar" })
	Sim.start(sim)
	local stats = { Shots = 0, Kicks = 0, Goals = 0, Restarts = {}, Over = false, Bad = 0, Controls = 0, Tackles = 0, Saves = 0 }
	local t = 0
	while t < seconds * 2 + 120 and not stats.Over do
		for _, e in Sim.step(sim, 1 / 20) do
			if e.Kind == "Kick" then
				stats.Kicks += 1
				if e.Type == "Shoot" then
					stats.Shots += 1
				end
			elseif e.Kind == "Goal" then
				stats.Goals += 1
				if e.Carried then
					stats.Carried = (stats.Carried or 0) + 1
				end
			elseif e.Kind == "Restart" then
				stats.Restarts[e.Type] = true
			elseif e.Kind == "Over" then
				stats.Over = true
			elseif e.Kind == "Control" then
				stats.Controls += 1
			elseif e.Kind == "Tackle" then
				stats.Tackles += 1
			elseif e.Kind == "Save" then
				stats.Saves += 1
			end
		end
		local p = sim.Ball.P
		if not finite(p) or math.abs(p.X) > sim.Pitch.BoardX + 0.01 or math.abs(p.Z) > sim.Pitch.BoardZ + 0.01 then
			stats.Bad += 1
			stats.Why = stats.Why or ("balón en %s (fase %s, dueño %s)"):format(tostring(p), sim.Phase, tostring(sim.Owner))
		end
		for _, id in sim.Order do
			local q = sim.Players[id].P
			if not finite(q) then
				stats.Bad += 1
			end
		end
		t += 1 / 20
	end
	return sim, stats
end
do
	local totalGoals = 0
	for _, cfg in { { 3, 11 }, { 5, 12 }, { 5, 13 }, { 3, 14 } } do
		local ok, sim, stats = pcall(playMatch, cfg[1], cfg[2], 150)
		if not ok then
			check(false, "Partido " .. cfg[1] .. "c" .. cfg[1] .. ": " .. tostring(sim))
			continue
		end
		totalGoals += stats.Goals
		local o = Sim.outcome(sim)
		check(stats.Over and o.Over and stats.Bad == 0, ("%dc%d (semilla %d): acaba bien %d-%d · %d golpeos, %d controles, %d entradas, %d paradas, %d goles conduciendo, %d tiros%s"):format(
			cfg[1], cfg[1], cfg[2], o.Goals, o.Against, stats.Kicks, stats.Controls, stats.Tackles, stats.Saves, stats.Carried or 0, stats.Shots, if stats.Why then " · " .. stats.Why else ""))
		check(stats.Kicks >= 20 and stats.Controls >= 10, "  …y se juega de verdad (pases y tiros)")
		check(stats.Restarts.Side or stats.Restarts.GoalKick or stats.Restarts.Corner, "  …con saques de banda, de puerta o córner")
	end
	check(totalGoals >= 2 and totalGoals <= 32, ("Hay goles, pero no un festival (%d en 4 partidos de 150 s)"):format(totalGoals))
	-- El estadio (110 × 70) también
	local stadium = Pitch.new(CFrame.new(0, 0, 0), 110, 70, { GoalLine = 55 })
	local ok, sim, stats = pcall(playMatch, 5, 21, 120, stadium)
	check(ok and stats.Over and stats.Bad == 0, "5c5 en el estadio: acaba bien" .. (if ok then "" else ": " .. tostring(sim)))
	-- Con una persona quieta en el equipo 1 (de delantero): no rompe nada
	local sim2 = Sim.new(school, { Mode = "Partido", Duration = 60, Rng = L.Random.new(5) })
	Sim.addPlayer(sim2, { Id = "yo", Team = 1, Human = true, Role = "FW" })
	Sim.fillTeams(sim2, 4, { "Nico" }, { "Bruno" })
	Sim.start(sim2)
	local over, teleported = false, false
	for _ = 1, 2400 do
		for _, e in Sim.step(sim2, 1 / 20) do
			if e.Kind == "Over" then
				over = true
			elseif e.Kind == "Teleport" and e.Id == "yo" then
				teleported = true
			end
		end
		if over then
			break
		end
	end
	check(over and teleported, "Con una persona en el campo: saque de centro con ella colocada y el partido acaba")
	check(sim2.Players.yo.Role == "FW", "La persona juega en su puesto (delantero)")
	local sim3 = Sim.new(school, { Mode = "Partido", Duration = 60, Rng = L.Random.new(5) })
	Sim.addPlayer(sim3, { Id = "yo", Team = 1, Human = true, Role = "GK" })
	Sim.fillTeams(sim3, 4, { "Nico", "Omar" }, { "Bruno" }, { Keeper1 = "Omar" })
	check(sim3.Players.yo.Role == "GK" and sim3.Keepers[-1] == "yo", "Si eliges portero, la portería es tuya (Omar juega de campo)")
end

print("\n▶ 6. Penaltis y pases")
do
	local function playPens(seed: number, shooter: (sim: any, spot: Vector3) -> ()?)
		local sim = Sim.new(school, { Mode = "Penaltis", Rounds = 3, Need = 2, Rng = L.Random.new(seed) })
		Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true })
		Sim.addPlayer(sim, { Id = "gk", Team = 2, Name = "Nico", Skill = 0.35 })
		Sim.start(sim)
		local over, results, t = nil, {}, 0
		while t < 200 and not over do
			for _, e in Sim.step(sim, 1 / 20) do
				if e.Kind == "Over" then
					over = e
				elseif e.Kind == "PenResult" then
					table.insert(results, e)
				elseif e.Kind == "Teleport" and e.Id == "yo" then
					Sim.setHuman(sim, "yo", e.P, Vector3.zero, e.Facing)
				end
			end
			if shooter and sim.Phase == "PenSetup" and sim.T > sim.PhaseUntil - 28 then
				shooter(sim, Pitch.penaltySpot(school, 1))
			end
			t += 1 / 20
		end
		return over, results, t
	end
	local over, results = playPens(4, function(sim, spot)
		local z = if sim.Round % 2 == 0 then -4.6 else 4.6
		Sim.kick(sim, "yo", { Kind = "Shoot", Dir = Vector3.new(school.GoalLine, 0, z) - spot, Power = 0.8 })
	end)
	check(over and #results >= 2 and #results <= 3, ("Tanda de 3: acaba (%d tiros, %d goles)"):format(#results, over and over.Hits or -1))
	local story = Story.result({ Game = "Penaltis", Need = 2 }, over)
	check(story.Won == ((over and over.Hits or 0) >= 2) and story.Score == (over and over.Hits), "La historia recibe los goles y si metiste los que hacían falta")
	local idle, idleResults, took = playPens(5, nil)
	check(idle and #idleResults == 2 and idle.Hits == 0 and took < 120, ("Sin chutar nunca, acaba igual (%.0f s): la historia sigue"):format(took))

	-- Pases a Dani
	local sim = Sim.new(school, { Mode = "Pases", Rounds = 4, Need = 2, Rng = L.Random.new(8) })
	Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true, Role = "MF", P = Vector3.new(-10, 0, 0) })
	Sim.addPlayer(sim, { Id = "dani", Team = 1, Name = "Dani", Role = "MF", Skill = 0.6 })
	sim.Receiver = "dani"
	Sim.start(sim)
	local passOver, good = nil, 0
	for _ = 1, 4000 do
		for _, e in Sim.step(sim, 1 / 20) do
			if e.Kind == "Over" then
				passOver = e
			elseif e.Kind == "PassResult" and e.Ok then
				good += 1
			end
		end
		if passOver then
			break
		end
		if sim.Phase == "PassReady" and sim.Owner == "yo" then
			local me, mate = sim.Players.yo, sim.Players.dani
			local d = AI.flatDistance(me.P, mate.P)
			Sim.kick(sim, "yo", { Kind = "Pass", Dir = mate.P - me.P, Dist = d, To = "dani", BallP = sim.Ball.P })
		end
	end
	check(passOver and good >= 2, ("Pases a Dani: %d buenos y acaba"):format(good))
end

print("\n▶ 7. La historia")
do
	local win = Story.result({ Game = "Futbol" }, { Goals = 3, Against = 1 })
	check(win.Won and win.Score == 3 and win.Against == 1 and not win.Detail.Draw, "3-1: victoria")
	local draw = Story.result({ Game = "Futbol" }, { Goals = 2, Against = 2 })
	check(not draw.Won and draw.Detail.Draw, "2-2: empate (la misión pone su bandera de empate)")
	local lose = Story.result({ Game = "Futbol" }, { Goals = 0, Against = 1 })
	check(not lose.Won and not lose.Detail.Draw, "0-1: derrota")
	local left = Story.result({ Game = "Futbol" }, { Goals = 2, Against = 0 }, true)
	check(not left.Won and not left.Detail.Draw, "Irse a mitad: no gana (pero la historia sigue)")
	local none = Story.result({ Game = "Penaltis", Need = 2 }, nil)
	check(not none.Won and none.Score == 0, "Sin resultado: cuenta como no ganado")
	local opts = Story.options({ Game = "Futbol", Plays = 6, Position = "Portero", Team = { "Nico", "Sara", "Omar" }, Rivals = { "Bruno", "Ruben", "Hugo", "Alex" }, RivalKeeper = "Alex", Keeper = "Omar" })
	check(opts.Mode == "Partido" and opts.HumanRole == "GK" and opts.Size == 4 and opts.Duration == 150, "Partido de la historia: 4c4, 150 s, de portero si lo elegiste")
	check(Story.options({ Game = "Penaltis", Rounds = 3, Need = 2, Keeper = "Nico" }).Rivals[1] == "Nico", "Penaltis: Nico se pone de portero")
	check(Story.maxSeconds({ Game = "Futbol", Plays = 6 }) > 150 and Story.maxSeconds({ Game = "Penaltis", Rounds = 3 }) >= 120, "Siempre hay un tiempo máximo (la historia nunca se queda parada)")
	-- Cada paso de fútbol de las misiones lleva un juego de verdad
	local fs = require("@lune/fs")
	local found = {}
	for _, file in fs.readDir("src/shared/LifeStory/Misiones") do
		local text = fs.readFile("src/shared/LifeStory/Misiones/" .. file)
		for line in text:gmatch("[^\n]+") do
			if line:find('Type = "MiniGame"') and (line:find("⚽") or line:find("🥅") or line:find("penalti") or line:find("[Pp]ase")) then
				local game = line:match('Game = "(%w+)"')
				table.insert(found, { File = file, Game = game, Line = line })
			end
		end
	end
	local bad = {}
	for _, f in found do
		if not Story.Games[f.Game] then
			table.insert(bad, f.File .. ": " .. tostring(f.Game))
		end
	end
	check(#found >= 4 and #bad == 0, ("Los pasos de fútbol de las misiones se juegan de verdad (%d pasos%s)"):format(#found, if #bad > 0 then "; con barra: " .. table.concat(bad, ", ") else ""))
end

print("\n▶ 8. La historia nunca se queda parada (MiniGameService)")
do
	local task = require("@lune/task")
	local fired = {}
	local fakeRemote = {
		Name = "MiniGame",
		FireClient = function(_, _player, kind, payload)
			table.insert(fired, { Kind = kind, Payload = payload })
		end,
		OnServerEvent = { Connect = function(_, fn)
			fakeRemote_onServer = fn
		end },
	}
	local remotes = { FindFirstChild = function(_, name)
		return if name == "MiniGame" then fakeRemote else nil
	end }
	L.services.ReplicatedStorage.Remotes = remotes
	L.services.Players = { PlayerRemoving = { Connect = function() end } }
	local mode = "ok"
	local calls = {}
	L.mock("src/server/Services/FootballService", {
		startStory = function(_player, spec, onDone)
			table.insert(calls, spec.Game)
			if mode == "ok" then
				task.delay(0.05, function()
					onDone(Story.result(spec, { Goals = 2, Against = 1, Hits = 2 }))
				end)
				return true
			elseif mode == "silent" then
				return true -- (empieza y nunca contesta)
			end
			return false -- (sin campo cerca)
		end,
		stopStory = function() end,
		cancelStory = function() end,
	})
	local MGS = L.load("src/server/Services/MiniGameService")
	MGS.init()
	local fakePlayer = { Name = "Leo", UserId = 1 }
	local function play(spec)
		local got = nil
		local started = MGS.start(fakePlayer, spec, function(result)
			got = result
		end)
		for _ = 1, 40 do
			if got then
				break
			end
			task.wait(0.05)
		end
		return started, got
	end
	mode = "ok"
	local started, result = play({ Game = "Futbol", Plays = 6 })
	check(started and result and result.Won and result.Score == 2 and calls[#calls] == "Futbol", "Partido de verdad: el resultado del campo llega a la misión")
	mode = "silent"
	local started2, result2 = play({ Game = "Penaltis", Rounds = 3, Need = 2, MaxSeconds = 0.3 })
	check(started2 and result2 and result2.Won == false, "Si el juego no contesta, al acabarse el tiempo la historia sigue (sin ganar)")
	mode = "nofield"
	fired = {}
	local got3 = nil
	local started3 = MGS.start(fakePlayer, { Game = "Penaltis", Rounds = 3, Need = 2 }, function(r)
		got3 = r
	end)
	check(started3 and #fired == 1 and fired[1].Kind == "Start", "Sin campo cerca: se juega el panel de siempre")
	task.wait(1.2)
	fakeRemote_onServer(fakePlayer, "Result", fired[1].Payload.Token, { Hits = 2 })
	check(got3 and got3.Won, "…y su resultado (2 de 3) cuenta igual")
end

print("")
if L.failures > 0 then
	print(("❌ test-futbol: %d fallos"):format(L.failures))
	process.exit(1)
end
print("✅ test-futbol: todo correcto")
