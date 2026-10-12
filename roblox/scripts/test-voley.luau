-- Prueba del vóley playa de verdad (shared/Sports/VolleySim y VolleyStory) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-voley.luau
--
-- Comprueba:
--   1. El balón: el saque pasa la red y cae en el campo rival; uno bajo da en la red.
--   2. Los golpes: recibir manda el balón al colocador, colocar lo sube junto a la red, rematar lo
--      manda fuerte y hacia abajo al otro campo; a destiempo se tuerce.
--   3. Partidos enteros: entre máquinas y con una persona que golpea bien o que no hace nada; siempre
--      acaban (a 7 puntos o por tiempo) y se juegan rallies de verdad.
--   4. La historia: gana quien hace más puntos; el paso de la playa se juega de verdad.

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check

local Sim = L.load("src/shared/Sports/VolleySim")
local Story = L.load("src/shared/Sports/VolleyStory")

local function newSim(seed: number)
	local sim = Sim.new({ Rng = L.Random.new(seed), Points = 7 })
	Sim.addPlayer(sim, { Id = "a1", Team = 1, Skill = 0.6 })
	Sim.addPlayer(sim, { Id = "a2", Team = 1, Skill = 0.6 })
	Sim.addPlayer(sim, { Id = "b1", Team = 2, Skill = 0.5 })
	Sim.addPlayer(sim, { Id = "b2", Team = 2, Skill = 0.5 })
	return sim
end

print("\n▶ 1. El balón")
do
	local sim = newSim(1)
	Sim.start(sim)
	local lands = 0
	for seed = 1, 20 do
		sim = newSim(seed)
		Sim.start(sim)
		Sim.serve(sim, sim.Server, nil, 1)
		local _, at = Sim.landing(sim, 0.9, 5)
		if at and at.X > 0 and at.X < sim.Half and math.abs(at.Z) < sim.Width / 2 then
			lands += 1
		end
	end
	check(lands >= 17, ("Un buen saque cae en el campo rival (%d de 20)"):format(lands))
	local low = newSim(2)
	Sim.start(low)
	low.Phase = "Rally"
	low.Ball.P = Vector3.new(-1.5, 2, 0)
	low.Ball.V = Vector3.new(20, 2, 0)
	local net = false
	for _ = 1, 60 do
		for _, e in Sim.step(low, 1 / 30) do
			if e.Kind == "Net" then
				net = true
			end
		end
	end
	check(net, "Un balón bajo da en la red")
end

print("\n▶ 2. Los golpes")
do
	local sim = newSim(3)
	Sim.start(sim)
	sim.Phase = "Rally"
	local p = sim.Players.a1
	p.P = Vector3.new(-10, 0, 0)
	sim.Ball.P = Vector3.new(-10, 3, 0.5)
	sim.Ball.V = Vector3.new(-2, -8, 0)
	sim.TouchTeam = 2
	sim.Touches = 3
	check(Sim.shotKind(sim, p) == "Recibir", "Balón bajo lejos de la red: recibir")
	Sim.hit(sim, "a1", nil, 1)
	local _, at = Sim.landing(sim, 4, 4)
	check(at and math.abs(at.X + 3.5) < 2.5, ("Recibir lo manda al colocador (cae en x = %.1f)"):format(at and at.X or 0))
	local q = Sim.new({ Rng = L.Random.new(4) })
	Sim.addPlayer(q, { Id = "s", Team = 1, Human = true })
	Sim.start(q)
	q.Phase = "Rally"
	local h = q.Players.s
	h.P = Vector3.new(-2, 0, 0)
	q.Ball.P = Vector3.new(-2, 8.3, 0)
	q.Ball.V = Vector3.new(0, -2, 0)
	q.TouchTeam, q.Touches = 1, 2
	q.LastTouch = "otro"
	check(Sim.shotKind(q, h) == "Remate", "Alto y junto a la red: remate")
	Sim.hit(q, "s", Vector3.new(8, 0, 2), 1)
	local _, down = Sim.landing(q, 0.9, 3)
	check(down and down.X > 0 and down.X < q.Half and math.abs(down.Z) < q.Width / 2, "El remate pasa la red y cae en el campo rival")
	check(Sim.quality(q, h, "Remate") > 0.8, "A la altura buena, golpe de calidad")
	q.Ball.P = Vector3.new(-2, 1.2, 0)
	check(Sim.quality(q, h, "Remate") < 0.3, "A destiempo, de mala calidad")
end

print("\n▶ 3. Partidos enteros")
local function play(seed: number, human: string?): ({ [string]: any }?, number, number)
	local sim = Sim.new({ Rng = L.Random.new(seed), Points = 7 })
	Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = human ~= nil, Skill = 0.6 })
	Sim.addPlayer(sim, { Id = "a2", Team = 1, Skill = 0.55 })
	Sim.addPlayer(sim, { Id = "b1", Team = 2, Skill = 0.42 })
	Sim.addPlayer(sim, { Id = "b2", Team = 2, Skill = 0.42 })
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
			-- Va a donde cae el balón y golpea en su punto
			local _, land = Sim.landing(sim, 2.5, 4)
			if sim.Phase == "Rally" and land and land.X < 0 then
				local to = Vector3.new(land.X - me.P.X, 0, land.Z - me.P.Z)
				local step = math.min(to.Magnitude, 16 / 30)
				if to.Magnitude > 0.01 then
					Sim.setHuman(sim, "yo", me.P + to.Unit * step)
				end
			end
			local can = Sim.canHit(sim, me)
			if can and sim.Ball.V.Y < 0 and sim.Ball.P.Y < 3.5 then
				Sim.hit(sim, "yo", Vector3.new(10, 0, 0))
			end
		end
		t += 1 / 30
	end
	return over, hits, t
end
do
	local goodPoints, idlePoints = 0, 0
	for seed = 1, 4 do
		local o, hits = play(seed, nil)
		check(o and (o.Goals == 7 or o.Against == 7) and hits >= 14, ("Máquinas: %d-%d con %d golpes"):format(o and o.Goals or -1, o and o.Against or -1, hits))
		local good = play(seed + 10, "good")
		local idle = play(seed + 10, "idle")
		goodPoints += good and good.Goals or 0
		idlePoints += idle and idle.Goals or 0
	end
	check(goodPoints > idlePoints + 4, ("Jugar bien da puntos: %d frente a %d sin hacer nada"):format(goodPoints, idlePoints))
	local idle, _, took = play(30, "idle")
	check(idle and idle.Over and took < 400, ("Sin hacer nada, el partido acaba igual (%.0f s)"):format(took))
end

print("\n▶ 4. La historia")
do
	check(Story.result({ Game = "Voley" }, { Goals = 7, Against = 4 }).Won, "7-4: ganas")
	check(not Story.result({ Game = "Voley" }, { Goals = 3, Against = 7 }).Won, "3-7: pierdes")
	check(not Story.result({ Game = "Voley" }, nil).Won, "Sin resultado: no ganas")
	local fs = require("@lune/fs")
	local text = fs.readFile("src/shared/LifeStory/Misiones/Uni_Secundarias.luau")
	local line = text:match('[^\n]*Voley playa[^\n]*')
	check(line and line:find('Game = "Voley"'), "El vóley de la playa se juega de verdad")
end

print("")
if L.failures > 0 then
	print(("❌ test-voley: %d fallos"):format(L.failures))
	process.exit(1)
end
print("✅ test-voley: todo correcto")
process.exit(0)
