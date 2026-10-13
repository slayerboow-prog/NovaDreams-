-- Datos de la hoja del ciclo de demostración de la Grieta (scripts/rift/demo-sheet.py la dibuja).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/rift/demo-sheet.luau > /tmp/grieta.json
--   python3 scripts/rift/demo-sheet.py /tmp/grieta.json docs/arte/grieta-ciclo-demo.png
--
-- Las cuentas son las del juego (shared/SkyRift: el horario del ciclo, la línea de tiempo de la
-- transición en directo, el tamaño y la apertura de cada etapa); lo que hace el cliente con la de
-- antes (se rasga y se apaga, o se cose y se encoge) es la misma fórmula que Controllers/SkyRift.

local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")
local Rift = L.load("src/shared/SkyRift")
local Art = L.load("src/shared/SkyRiftArt")

local function stageInfo(n: number)
	local st = Rift.stage(n)
	local art = Art.Stages[n]
	return { Stage = n, Name = st.Name, Width = st.Width, Mood = st.Mood, Ambient = st.Ambient, Texture = art and art.Texture, Aspect = art and art.Aspect, Galaxy = art and art.Galaxy, GalaxyTexture = art and art.GalaxyTexture }
end

local out = { Stages = {}, Cycle = {}, Transitions = {} }
for n = 1, 7 do
	out.Stages[n] = stageInfo(n)
end
for _, slot in Rift.demoSchedule() do
	local ph = Rift.phase(slot.Phase)
	table.insert(out.Cycle, { Phase = slot.Phase, Stage = slot.Stage, From = slot.From, To = slot.To, Open = ph.Open, Intensity = ph.Intensity, Hour = (slot.From + 1.5) % 24 })
end

local function ghostLook(kind: string, u: number): (number, number, number)
	local e = Rift.smooth(u)
	if kind == "Abre" then
		return 1 + 0.35 * e, 1 + 0.55 * e, (1 - u) ^ 1.3
	end
	return 1 - 0.6 * e, math.max(0.02, (1 - e) ^ 2.2), if u < 0.8 then 1 else math.max(0, (1 - u) / 0.2)
end

local function transition(fromPhase: string, toPhase: string, hour: number, times: { number })
	local t = Rift.transitionFor(fromPhase, toPhase) :: any
	local a0, b0 = Rift.phase(fromPhase), Rift.phase(toPhase)
	local frames = {}
	for _, s in times do
		local a = Rift.liveAt(s, t.Kind)
		local f: { [string]: any } = { T = s, Build = a.Build, Flash = a.Flash, Ring = a.Ring, Morph = a.Morph, Kind = t.Kind }
		if not a.Morphed then
			f.Old = { Stage = t.From, Open = a0.Open, Vis = a0.Intensity, Sx = 1, Sy = 1, Alpha = 1 }
		else
			local u = math.clamp((s - Rift.Live.MorphAt) / Rift.Live.MorphSeconds, 0, 1)
			if u < 1 and t.From > 1 then
				local sx, sy, alpha = ghostLook(t.Kind, u)
				f.Old = { Stage = t.From, Open = a0.Open, Vis = a0.Intensity, Sx = sx, Sy = sy, Alpha = alpha, Seam = if t.Kind == "Cierra" then math.clamp(u * 2.2, 0, 1) * alpha else 0 }
			end
			if t.To > 1 then
				f.New = { Stage = t.To, Open = b0.Open * a.Morph, Vis = b0.Intensity * math.min(1, a.Morph * 1.6) }
			end
		end
		table.insert(frames, f)
	end
	table.insert(out.Transitions, { From = t.From, To = t.To, Kind = t.Kind, Hour = hour, Frames = frames })
end
transition("Grande", "Abierta", 18, { 0, 3, 5.5, 7, 9.6, 10.3, 12, 16 })
transition("Ultima", "Cerrada", 6, { 2, 5.5, 7.5, 9.3 })

print(serde.encode("json", out))
