-- SceneTiming: las REGLAS DE TIEMPO de los rótulos y los subtítulos de una escena (cuentas puras, sin
-- servicios de Roblox). Las usan las pruebas (scripts/test-transiciones.luau) con las escenas de los dos
-- sistemas: las cinemáticas viejas (shared/LifeStory/Cinematics: Shots seguidos, Lines con TextKey,
-- Titles) y las escenas del motor (Happenings, ya compiladas con Sequencer).
--
-- Reglas (la queja de la v107: un rótulo encima de una frase, y la frase de Lucía en la puerta del
-- colegio encima del plano de tu casa):
--   1. Rótulo primero, frase después: un rótulo grande y un subtítulo NUNCA están a la vez en pantalla.
--   2. Cada frase de un personaje se queda en SU sitio: se lee entera antes del siguiente corte de
--      escena (un plano que entra con fundido: Dip / Fade, o el final de la escena). La voz del
--      narrador no es de ningún sitio y puede pasar por encima de un corte.
--   3. Dos frases que no son alternativas no se pisan (si no, la segunda espera a que se lea la
--      primera, se va retrasando y acaba en el plano de otro sitio: la foto 1 en la foto 2).
-- Cuánto dura cada cosa en pantalla: el subtítulo, lo que se tarda en leerlo (ReadingTime, como en
-- los clientes) o su Duration si es mayor; el rótulo, su Duration (3 s si no dice) más el fundido de
-- salida (FADE).

local ReadingTime = require(script.Parent.ReadingTime)
local Strings = require(script.Parent.Strings)

local SceneTiming = {}

SceneTiming.FADE = 0.6 -- lo que tarda en irse un rótulo (los clientes lo funden en 0,6–0,8 s)
SceneTiming.EPS = 0.05

export type Item = { At: number, Until: number, Text: string, Speaker: string?, Cond: { [string]: any }?, Alt: boolean? }
export type Cut = { At: number, Kind: string }
export type Norm = { Id: string, Duration: number, Lines: { Item }, Titles: { Item }, Cuts: { Cut } }

local function textOf(value: any): string
	if type(value) ~= "string" then
		return ""
	end
	local ok, text = pcall(Strings.get, value, { nombre = "Alex", abu = "Abu" })
	return if ok and type(text) == "string" then text else value
end

local function condOf(data: { [string]: any }): { [string]: any }?
	if data.If == nil and data.IfNot == nil then
		return nil
	end
	return { If = data.If, IfNot = data.IfNot }
end

local function lineSeconds(text: string, duration: any): number
	return math.max(tonumber(duration) or 0, ReadingTime.seconds(text))
end

-- Escena del motor ya compilada (Sequencer.compile)
function SceneTiming.fromTimeline(id: string, timeline: { [string]: any }): Norm
	local out: Norm = { Id = id, Duration = timeline.Duration or 0, Lines = {}, Titles = {}, Cuts = {} }
	for _, e in timeline.Events or {} do
		local d = e.Data
		if type(d) ~= "table" then
			continue
		end
		if e.Track == "Lines" or e.Track == "Dialogue" then
			if d.Ask or d.Options then
				continue
			end
			local text = textOf(d.Text or d.T)
			if text ~= "" then
				table.insert(out.Lines, {
					At = e.At,
					Until = e.At + lineSeconds(text, d.Duration),
					Text = text,
					Speaker = d.Speaker or d.S,
					Cond = condOf(d),
					Alt = d.Alt == true,
				})
			end
		elseif e.Track == "Titles" then
			local text = textOf(d.Text)
			table.insert(out.Titles, { At = e.At, Until = e.At + (tonumber(d.Duration) or 3) + SceneTiming.FADE, Text = text, Cond = condOf(d) })
		elseif e.Track == "Camera" then
			if d.Cut == "Dip" or d.Cut == "Fade" then
				table.insert(out.Cuts, { At = e.At, Kind = d.Cut })
			end
		end
	end
	return out
end

-- Cinemática vieja (Shots seguidos: cada uno empieza donde acaba el anterior)
function SceneTiming.fromCinematic(id: string, def: { [string]: any }): Norm
	local out: Norm = { Id = id, Duration = def.Duration or 0, Lines = {}, Titles = {}, Cuts = {} }
	local t = 0
	for i, shot in def.Shots or {} do
		if i > 1 and shot.Dip then
			table.insert(out.Cuts, { At = t, Kind = "Dip" })
		end
		t += tonumber(shot.Duration) or 0
	end
	for _, line in def.Lines or {} do
		local text = textOf(line.TextKey)
		table.insert(out.Lines, {
			At = line.At,
			Until = line.At + ReadingTime.seconds(text, ReadingTime.pauseOf(line)),
			Text = text,
			Speaker = line.Speaker,
		})
	end
	for _, title in def.Titles or {} do
		table.insert(out.Titles, { At = title.At, Until = title.At + (tonumber(title.Duration) or 3) + SceneTiming.FADE, Text = textOf(title.TextKey) })
	end
	return out
end

local function same(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- ¿Las dos no pueden salir a la vez? (una pide lo que la otra niega, o la misma decisión con otro valor)
function SceneTiming.exclusive(a: { [string]: any }?, b: { [string]: any }?): boolean
	if not a or not b then
		return false
	end
	if (a.If and b.IfNot and same(a.If, b.IfNot)) or (a.IfNot and b.If and same(a.IfNot, b.If)) then
		return true
	end
	for _, side in { "If", "IfNot" } do
		local ca, cb = a[side], b[side]
		if side == "If" and type(ca) == "table" and type(cb) == "table" then
			for key, value in ca.Choices or {} do
				local other = cb.Choices and cb.Choices[key]
				if other ~= nil and other ~= value then
					return true
				end
			end
		end
	end
	-- Una pide un recuerdo / una marca y la otra pide que NO esté
	if a.If and b.If then
		for _, pair in { { "Flags", "NotFlags" }, { "Memories", "NotMemories" }, { "Completed", "NotCompleted" } } do
			for _, x in (a.If[pair[1]] or {}) do
				if table.find(b.If[pair[2]] or {}, x) then
					return true
				end
			end
			for _, x in (b.If[pair[1]] or {}) do
				if table.find(a.If[pair[2]] or {}, x) then
					return true
				end
			end
		end
		for key, value in a.If.Choices or {} do
			if b.If.NotChoices and b.If.NotChoices[key] == value then
				return true
			end
		end
		for key, value in b.If.Choices or {} do
			if a.If.NotChoices and a.If.NotChoices[key] == value then
				return true
			end
		end
	end
	return false
end

local function overlaps(a: Item, b: Item): boolean
	return a.At < b.Until - SceneTiming.EPS and b.At < a.Until - SceneTiming.EPS
end

local function located(line: Item): boolean
	return line.Speaker ~= nil and line.Speaker ~= "Narrador" and line.Speaker ~= ""
end

-- El siguiente corte de escena después de `t` (o el final)
function SceneTiming.nextCut(norm: Norm, t: number): number
	local best = norm.Duration
	for _, cut in norm.Cuts do
		if cut.At > t + SceneTiming.EPS and cut.At < best then
			best = cut.At
		end
	end
	return best
end

-- Los problemas de la escena: { { Kind, Detail } }
--   TituloYFrase   un rótulo y un subtítulo a la vez en pantalla
--   FraseFueraDeSitio  la frase de un personaje sigue en pantalla después del corte a otro sitio
--   FrasesPisadas  dos frases que no son alternativas se pisan
function SceneTiming.check(norm: Norm): { { Kind: string, Detail: string } }
	local problems = {}
	local function add(kind: string, detail: string)
		table.insert(problems, { Kind = kind, Detail = ("%s: %s"):format(norm.Id, detail) })
	end
	for _, title in norm.Titles do
		for _, line in norm.Lines do
			if overlaps(title, line) and not SceneTiming.exclusive(title.Cond, line.Cond) then
				add("TituloYFrase", ("rótulo «%s» (%.1f–%.1f s) con la frase «%s» (%.1f–%.1f s)"):format(
					title.Text, title.At, title.Until, line.Text:sub(1, 40), line.At, line.Until))
			end
		end
	end
	for _, line in norm.Lines do
		if located(line) then
			local cut = SceneTiming.nextCut(norm, line.At)
			if line.Until > cut + SceneTiming.EPS then
				add("FraseFueraDeSitio", ("«%s» (%s) se lee hasta %.1f s y la escena cambia de sitio a %.1f s"):format(
					line.Text:sub(1, 40), tostring(line.Speaker), line.Until, cut))
			end
		end
	end
	for i, a in norm.Lines do
		for j = i + 1, #norm.Lines do
			local b = norm.Lines[j]
			if overlaps(a, b) and not b.Alt and not a.Alt and not SceneTiming.exclusive(a.Cond, b.Cond) then
				add("FrasesPisadas", ("«%s» (%.1f–%.1f s) y «%s» (%.1f–%.1f s)"):format(
					a.Text:sub(1, 30), a.At, a.Until, b.Text:sub(1, 30), b.At, b.Until))
			end
		end
	end
	return problems
end

return SceneTiming
