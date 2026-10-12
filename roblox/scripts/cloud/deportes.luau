-- deportes: en el servidor de verdad, el fútbol y el baloncesto del mapa
--   1. FootballService y BasketService arrancan sin errores (y su búsqueda de campos, que va a los
--      25 s, tampoco deja errores ni avisos en la consola).
--   2. Campos: las piezas «Pitch» de césped del mapa salen como campo (Sports/Pitch.fromPart, igual
--      que FootballService).
--   3. Canastas: los «Rim» naranjas con su tablero salen como pista (Sports/Court, igual que
--      BasketService).
--   4. Una tanda de penaltis sin jugador (nadie chuta) en un campo de verdad acaba sola y la
--      historia recibe su resultado; y una tanda de tiros a canasta igual.
--
-- Uso: bash scripts/cloud-test.sh --version 106 deportes

local Cloud = Cloud :: any

local Sports = Cloud.Shared:WaitForChild("Sports")
local Pitch = require(Sports.Pitch) :: any
local Court = require(Sports.Court) :: any
local Sim = require(Sports.FootballSim) :: any
local FStory = require(Sports.FootballStory) :: any
local BSim = require(Sports.BasketSim) :: any
local BStory = require(Sports.BasketStory) :: any

Cloud.escuchar()
for _, p in Cloud.prepararMundo() do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end
local malos, deportes = {}, {}
for _, s in Cloud.arrancarServicios() do
	if s.name == "FootballService" or s.name == "BasketService" then
		deportes[s.name] = s
	end
	if not s.ok and not s.saltado and not s.noPublicado then
		table.insert(malos, s.name .. ": " .. tostring(s.err))
	end
end
local tArranque = Cloud.tiempo()
Cloud.check("Servicios arrancados", #malos == 0, if #malos == 0 then "todos bien" else Cloud.lista(malos, 5))
for _, name in { "FootballService", "BasketService" } do
	local s = deportes[name]
	Cloud.check(name .. " arranca", s ~= nil and s.ok == true, if s == nil then "no está en la lista de servicios" elseif s.ok then ("%.1f s"):format(s.s) else tostring(s.err))
end

---------------------------------------------------------------------
-- 2. Campos de fútbol
---------------------------------------------------------------------
local pitches = {}
local candidatos, malPitch = 0, {}
for _, d in workspace:GetDescendants() do
	if d.Name == "Pitch" and d:IsA("BasePart") and d.Material == Enum.Material.Grass then
		local long, short = math.max(d.Size.X, d.Size.Z), math.min(d.Size.X, d.Size.Z)
		if long >= 50 and short >= 28 and d.Size.Y < 3 then
			candidatos += 1
			local siblings = {}
			for _, c in (if d.Parent then d.Parent:GetChildren() else {}) do
				if c:IsA("BasePart") and c ~= d then
					table.insert(siblings, c)
				end
			end
			local ok, pitch = pcall(Pitch.fromPart, d, siblings, "F" .. candidatos)
			if ok and pitch then
				table.insert(pitches, pitch)
			else
				table.insert(malPitch, Cloud.nombre(d) .. ": " .. tostring(pitch))
			end
		end
	end
end
Cloud.check("Campos «Pitch» detectados", #pitches > 0 and #malPitch == 0, ("%d campos de %d piezas de césped"):format(#pitches, candidatos) .. (if #malPitch > 0 then "; fallan: " .. Cloud.lista(malPitch, 4) else ""))
Cloud.info("campos", #pitches)

---------------------------------------------------------------------
-- 3. Canastas
---------------------------------------------------------------------
local rims, conTablero, courts, malCourt = 0, 0, {}, {}
for _, d in workspace:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "Rim" and Court.isRim(d) then
		rims += 1
		local board, bestD = nil, 5
		local scope = d.Parent
		for _ = 1, 2 do
			if not scope or board then
				break
			end
			for _, c in scope:GetDescendants() do
				if c:IsA("BasePart") and c.Name == "Backboard" and (c.Position - d.Position).Magnitude < bestD then
					board, bestD = c, (c.Position - d.Position).Magnitude
				end
			end
			scope = scope.Parent
		end
		if board then
			conTablero += 1
			local ok, court = pcall(Court.fromParts, nil, { { Part = d, Board = board, FloorY = d.Position.Y - 10 } }, "H" .. rims)
			if ok and court then
				table.insert(courts, court)
			else
				table.insert(malCourt, Cloud.nombre(d) .. ": " .. tostring(court))
			end
		end
	end
end
Cloud.check("Canastas «Rim» detectadas", #courts > 0 and #malCourt == 0, ("%d aros, %d con tablero, %d pistas"):format(rims, conTablero, #courts) .. (if #malCourt > 0 then "; fallan: " .. Cloud.lista(malCourt, 4) else ""))
Cloud.info("canastas", #courts)

---------------------------------------------------------------------
-- 4. Partidas sin jugador
---------------------------------------------------------------------
if pitches[1] then
	local ok, a, b = pcall(function()
		local sim = Sim.new(pitches[1], { Mode = "Penaltis", Rounds = 2, Need = 1, Seed = 7 })
		Sim.addPlayer(sim, { Id = "yo", Team = 1, Human = true })
		Sim.addPlayer(sim, { Id = "gk", Name = "Portero", Team = 2, Role = "GK", Skill = 0.5 })
		Sim.start(sim)
		local over, tiros, t = nil, 0, 0
		while t < 200 and not over do
			for _, e in Sim.step(sim, 1 / 20) do
				if e.Kind == "Over" then
					over = e
				elseif e.Kind == "PenResult" then
					tiros += 1
				end
			end
			t += 1 / 20
		end
		local story = FStory.result({ Game = "Penaltis", Need = 1 }, over)
		return over ~= nil and tiros == 2 and story.Won == false, ("%d tiros, %d goles, acaba a los %.0f s; historia: ganada=%s"):format(tiros, over and over.Hits or -1, t, tostring(story.Won))
	end)
	Cloud.check("Penaltis sin jugador: acaba solo", ok and a == true, tostring(if ok then b else a))
else
	Cloud.salta("Penaltis sin jugador", "no hay campo")
end

if courts[1] then
	local ok, a, b = pcall(function()
		local sim = BSim.new(courts[1], { Mode = "Tiros", Rounds = 2, Need = 1, Seed = 7 })
		BSim.addPlayer(sim, { Id = "yo", Team = 1, Human = true })
		BSim.start(sim)
		local over, t = nil, 0
		while t < 200 and not over do
			for _, e in BSim.step(sim, 1 / 20) do
				if e.Kind == "Over" then
					over = e
				end
			end
			t += 1 / 20
		end
		local story = BStory.result({ Game = "Canastas", Need = 1 }, over)
		return over ~= nil and story.Won == false, ("acaba a los %.0f s; historia: ganada=%s"):format(t, tostring(story.Won))
	end)
	Cloud.check("Tiros a canasta sin jugador: acaba solo", ok and a == true, tostring(if ok then b else a))
else
	Cloud.salta("Tiros a canasta sin jugador", "no hay canasta")
end

-- La búsqueda de campos y canastas de los servicios va a los 25 s: se espera a que pase
task.wait(math.max(0, tArranque + 30 - Cloud.tiempo()))
local oido = Cloud.oido()
local deporte = {}
for _, l in oido.errores do
	table.insert(deporte, l)
end
for _, l in oido.avisos do
	table.insert(deporte, l)
end
Cloud.check("Consola sin errores ni avisos", #deporte == 0, if #deporte == 0 then "0 errores, 0 avisos" else Cloud.lista(deporte, 6))

return Cloud.resultado()
