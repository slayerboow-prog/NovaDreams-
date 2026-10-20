-- Revisión por cinemática (docs/cine/revision-cinematicas.md): las cuentas de cada escena que se miran
-- en su hoja A–P. Sin mapa (lo de las paredes y el encuadre lo mira test-cineplanos).
--
-- Uso (desde roblox/):
--   lune run scripts/audit/cine-revision.luau <Id>…        escenas del motor (fase 6: también las 21 de
--                                                         siempre, Happenings/Capitulos)
--   lune run scripts/audit/cine-revision.luau --lista      las de la revisión (Revision.List)
--   (--hoja: además, lo que hay en cada pista: actores, efectos, música, mundo…)
--
-- Por cada escena: duración, planos (cuántos, el más corto, huecos sin plano), frases (cuántas, de
-- quién), si alguna frase se pisa con la siguiente (no da tiempo a leerla) o con un rótulo, reacciones
-- escritas (Mood/Gesture/Look de actores y A/G/Mood de las frases), si hay un silencio (≥ 2 s sin frases)
-- después de un golpe (Fx de impacto, explosión, portal, sonido Boom/Crack/Thunder), y si quien habla
-- está en la escena.

local process = require("@lune/process")

local L = require("../lib/ModuleLoader")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local Cinematics = L.load("src/shared/LifeStory/Cinematics")
local ReadingTime = L.load("src/shared/LifeStory/ReadingTime")

local Revision = {}

-- Las de la revisión (capítulos, despedidas, la Grieta y el final)
Revision.List = {
	"Prologo_Apertura", "Bebe_NacimientoCuna", "Bebe_PrimerosPasosAbu", "Montaje_Bebe_Nino", "Cole01_Bienvenida",
	"Cole12_Despedida", "Cole12_FinDeEpisodio", "Montaje_Nino_Adolescente", "Ins01_Parada", "Ins06_Noche",
	"Ins06_Graduacion", "Uni01_Campus", "Uni06_Ceremonia", "Uni06_Final", "Adulto_Bienvenida", "Adu02_Hospital",
	"Adu02_Orilla", "Grieta_Caen", "Grieta_Coser", "Grieta_Rota", "Grieta_Fusion", "Grieta_Final",
	"Vida_MirarAtras", "Prologo_Cierre",
}

local BIG_FX = { Meteor = true, MeteorImpact = true, Explosion = true, Portal = true, GroundCrack = true, Crater = true, Flash = true }
local BIG_SOUND = { Boom = true, Crack = true, Thunder = true, Rumble = true }

local function textOf(d: { [string]: any }): string
	return tostring(d.Text or d.T or d.TextKey or "")
end

function Revision.engine(id: string): { [string]: any }?
	local source = HappeningIndex.get(id)
	if not source then
		return nil
	end
	local ok, tl = pcall(Sequencer.compile, id, source)
	if not ok then
		return { Id = id, Error = tostring(tl) }
	end
	local r = { Id = id, Kind = "Motor", Duration = tl.Duration, Shots = #tl.Shots, Lines = 0, Speakers = {}, Reactions = 0, Overlaps = {}, TitleClash = {}, Big = {}, Silence = {}, Gaps = {}, Missing = {} }
	-- Planos: el más corto y los huecos
	local spans = {}
	for _, s in tl.Shots do
		table.insert(spans, { A = tonumber(s.At) or 0, B = (tonumber(s.At) or 0) + (tonumber(s.Duration) or 0) })
	end
	table.sort(spans, function(a, b)
		return a.A < b.A
	end)
	r.MinShot = math.huge
	local covered = 0
	for _, sp in spans do
		r.MinShot = math.min(r.MinShot, sp.B - sp.A)
		if sp.A > covered + 0.05 and not (source.Light) then
			table.insert(r.Gaps, ("%.1f–%.1f"):format(covered, sp.A))
		end
		covered = math.max(covered, sp.B)
	end
	if #spans == 0 then
		r.MinShot = 0
	end
	-- Actores de la escena
	local keys = Sequencer.actorKeys(source)
	-- Frases y reacciones
	local lines, titles = {}, {}
	for _, e in tl.Events do
		local d = e.Data
		if e.Track == "Lines" or e.Track == "Dialogue" then
			table.insert(lines, e)
			local who = d.Speaker or d.S
			if who then
				r.Speakers[who] = true
				if who ~= "Narrador" and who ~= "Yo" and not keys[who] and not (type(source.Speakers) == "table" and source.Speakers[who]) then
					table.insert(r.Missing, who)
				end
			end
			if d.Mood or d.A or d.G then
				r.Reactions += 1
			end
		elseif e.Track == "Titles" then
			table.insert(titles, e)
		elseif e.Track == "Actors" and (d.Mood or d.Gesture or d.Look) then
			r.Reactions += 1
		elseif (e.Track == "Fx" and BIG_FX[d.Play or ""]) or (e.Track == "Sound" and BIG_SOUND[d.Play or ""]) then
			table.insert(r.Big, e.At + (if e.Track == "Fx" and d.Play == "Meteor" then (tonumber(d.Seconds) or 2.6) else 0))
		end
	end
	r.Lines = #lines
	for i, e in lines do
		local nextLine = lines[i + 1]
		local need = ReadingTime.seconds(textOf(e.Data))
		-- (las alternativas If/IfNot salen a la vez: no se pisan)
		if nextLine and nextLine.At < e.At + need - 0.3 and not (e.Data.If or e.Data.IfNot or nextLine.Data.If or nextLine.Data.IfNot) then
			table.insert(r.Overlaps, ("%.1f s «%s» (necesita %.1f s, la siguiente a los %.1f s)"):format(e.At, textOf(e.Data):sub(1, 28), need, nextLine.At - e.At))
		end
		for _, t in titles do
			local a, b = t.At, t.At + (tonumber(t.Data.Duration) or 3)
			if e.At >= a - 0.2 and e.At < b then
				table.insert(r.TitleClash, ("%.1f s"):format(e.At))
			end
		end
	end
	-- ¿Silencio después de cada golpe? (≥ 2 s sin que empiece ninguna frase)
	for _, at in r.Big do
		local quiet = true
		for _, e in lines do
			if e.At > at - 0.1 and e.At < at + 2 then
				quiet = false
			end
		end
		table.insert(r.Silence, { At = at, Quiet = quiet })
	end
	return r
end

function Revision.old(id: string): { [string]: any }?
	local def = Cinematics[id]
	if not def then
		return nil
	end
	local r = { Id = id, Kind = "Vieja", Duration = def.Duration, Shots = #(def.Shots or {}), Lines = #(def.Lines or {}), Speakers = {}, Reactions = #(def.Anims or {}), Overlaps = {}, TitleClash = {}, Big = {}, Silence = {}, Gaps = {}, Missing = {} }
	local total = 0
	r.MinShot = math.huge
	for _, s in def.Shots or {} do
		total += s.Duration or 0
		r.MinShot = math.min(r.MinShot, s.Duration or 0)
	end
	if total < (def.Duration or 0) - 0.05 then
		table.insert(r.Gaps, ("planos hasta %.1f de %.1f s"):format(total, def.Duration))
	end
	local lines = table.clone(def.Lines or {})
	table.sort(lines, function(a, b)
		return a.At < b.At
	end)
	for i, l in lines do
		r.Speakers[l.Speaker or "Narrador"] = true
		local nextLine = lines[i + 1]
		if nextLine then
			local need = 2.5 -- (texto en Strings: se cuenta lo mínimo)
			if nextLine.At - l.At < need then
				table.insert(r.Overlaps, ("%.1f s (la siguiente a los %.1f s)"):format(l.At, nextLine.At - l.At))
			end
		end
		for _, t in def.Titles or {} do
			if l.At >= t.At - 0.2 and l.At < t.At + (t.Duration or 3) then
				table.insert(r.TitleClash, ("%.1f s"):format(l.At))
			end
		end
	end
	return r
end

function Revision.of(id: string): { [string]: any }?
	return Revision.engine(id) or Revision.old(id)
end

function Revision.format(r: { [string]: any }): string
	if r.Error then
		return ("%s: ERROR %s"):format(r.Id, r.Error)
	end
	local speakers = {}
	for s in r.Speakers do
		table.insert(speakers, s)
	end
	table.sort(speakers)
	local silence = {}
	for _, s in r.Silence do
		table.insert(silence, ("%.1f%s"):format(s.At, if s.Quiet then "✓" else "✗"))
	end
	return ("%s [%s] %.1f s · %d planos (el más corto %.1f s)%s · %d frases (%s) · %d reacciones%s%s%s%s"):format(
		r.Id, r.Kind, r.Duration or 0, r.Shots, if r.MinShot == math.huge then 0 else r.MinShot,
		if #r.Gaps > 0 then " · huecos " .. table.concat(r.Gaps, ", ") else "",
		r.Lines, table.concat(speakers, ", "), r.Reactions,
		if #r.Overlaps > 0 then "\n    se pisan: " .. table.concat(r.Overlaps, " | ") else "",
		if #r.TitleClash > 0 then "\n    frase con rótulo: " .. table.concat(r.TitleClash, ", ") else "",
		if #silence > 0 then "\n    golpes (✓ = silencio de 2 s después): " .. table.concat(silence, " ") else "",
		if #r.Missing > 0 then "\n    habla y no está en la escena: " .. table.concat(r.Missing, ", ") else "")
end

-- Los datos de la hoja (lo que hay en cada pista)
function Revision.sheet(id: string): string
	local source = HappeningIndex.get(id)
	local out = {}
	if source then
		local def = Sequencer.expand(source)
		local tracks = def.Tracks or {}
		local function list(track: string, field: string): string
			local seen, items = {}, {}
			for _, d in tracks[track] or {} do
				local v = d[field]
				if type(v) == "table" then
					v = v.Key and (tostring(v.Key) .. (if v.Mood then "=" .. tostring(v.Mood) elseif v.Play then "→" .. tostring(v.Play) else "")) or nil
				end
				if v ~= nil and not seen[tostring(v)] then
					seen[tostring(v)] = true
					table.insert(items, tostring(v))
				end
			end
			return table.concat(items, ", ")
		end
		local actors = {}
		for key in Sequencer.actorKeys(source) do
			table.insert(actors, key)
		end
		table.sort(actors)
		table.insert(out, "actores: " .. table.concat(actors, ", "))
		table.insert(out, "fx: " .. list("Fx", "Play") .. " · sonido: " .. list("Sound", "Play"))
		table.insert(out, "música: " .. list("Music", "Intensity") .. " " .. list("Music", "Play") .. " · ambiente: " .. list("Ambience", "Kind") .. " · luz: " .. list("Light", "Preset") .. " · cielo: " .. list("Sky", "Mood"))
		table.insert(out, "emociones: " .. list("Actors", "Mood") .. " · gestos: " .. list("Actors", "Gesture"))
		local world = {}
		for _, d in tracks.World or {} do
			for k, v in d.Set or {} do
				table.insert(world, k .. "=" .. tostring(v))
			end
		end
		table.insert(out, "mundo: " .. table.concat(world, ", ") .. " · rótulos: " .. list("Titles", "Text") .. " · esperas: " .. list("Wait", "Input"))
	end
	return table.concat(out, "\n    ")
end

local ids = {}
local sheets = false
for _, a in process.args do
	if a == "--hoja" then
		sheets = true
		continue
	end
	if a == "--lista" then
		for _, id in Revision.List do
			table.insert(ids, id)
		end
	else
		table.insert(ids, a)
	end
end
if #ids == 0 then
	return Revision
end
for _, id in ids do
	local r = Revision.of(id)
	print(if r then Revision.format(r) else id .. ": no existe")
	if sheets then
		print("    " .. Revision.sheet(id))
	end
end
return Revision
