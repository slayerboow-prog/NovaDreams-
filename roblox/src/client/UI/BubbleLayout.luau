-- BubbleLayout: las cuentas de los bocadillos de texto (sin nada de Roblox, se prueba con Lune).
--   * Un bocadillo por personaje: si vuelve a hablar, su frase nueva sustituye a la anterior.
--   * Cuánto dura cada frase según lo larga que es.
--   * Tamaño del bocadillo (ancho máximo, líneas) y escala según la distancia y la pantalla.
--   * Si varios personajes hablan cerca, sus bocadillos se apilan hacia arriba sin pisarse.
-- Lo dibuja UI/SpeechBubbles.

local BubbleLayout = {}

BubbleLayout.MaxWidth = 230 -- píxeles (a escala 1)
BubbleLayout.MinWidth = 64
BubbleLayout.TextSize = 17
BubbleLayout.NameSize = 12
BubbleLayout.PadX = 12
BubbleLayout.PadY = 8
BubbleLayout.Tail = 9 -- el pico que apunta a quien habla
BubbleLayout.FadeIn = 0.18
BubbleLayout.FadeOut = 0.3
BubbleLayout.Gap = 6 -- separación entre bocadillos apilados
BubbleLayout.MaxDistance = 60 -- studs: más lejos no se ven
BubbleLayout.MaxVisible = 8 -- como mucho, los más cercanos

local function length(text: string): number
	return utf8.len(text) or #text
end

-- Segundos que se queda una frase: lo justo para leerla (entre 2,2 y 9 s)
function BubbleLayout.duration(text: string): number
	return math.clamp(1.4 + length(text) * 0.065, 2.2, 9)
end

-- Frases "hasta nuevo aviso" (el servidor la quita él): tope por si nadie la quita
function BubbleLayout.stickyCap(text: string): number
	return math.clamp(BubbleLayout.duration(text) * 3, 12, 40)
end

-- Tamaño aproximado (sin medir con Roblox): ancho y alto en píxeles a escala 1
function BubbleLayout.estimate(text: string, name: string?): (number, number)
	local charWidth = BubbleLayout.TextSize * 0.52
	local inner = BubbleLayout.MaxWidth - BubbleLayout.PadX * 2
	local perLine = math.max(1, math.floor(inner / charWidth))
	-- Por palabras: una palabra que no cabe pasa a la línea siguiente
	local lines, current, widest = 1, 0, 0
	for word in string.gmatch(text, "%S+") do
		local w = length(word)
		local need = if current == 0 then w else current + 1 + w
		if need > perLine and current > 0 then
			widest = math.max(widest, current)
			lines += 1
			current = math.min(w, perLine)
			lines += math.floor((w - 1) / perLine)
		else
			current = need
		end
	end
	widest = math.max(widest, current)
	local textWidth = math.min(inner, widest * charWidth)
	return BubbleLayout.sizeFor(textWidth, lines * (BubbleLayout.TextSize + 3), name)
end

-- Tamaño del bocadillo con el texto ya medido (ancho y alto del texto)
function BubbleLayout.sizeFor(textWidth: number, textHeight: number, name: string?): (number, number)
	local nameWidth = if name and name ~= "" then length(name) * BubbleLayout.NameSize * 0.6 else 0
	local width = math.clamp(math.max(textWidth, nameWidth) + BubbleLayout.PadX * 2, BubbleLayout.MinWidth, BubbleLayout.MaxWidth)
	local height = textHeight + BubbleLayout.PadY * 2 + (if nameWidth > 0 then BubbleLayout.NameSize + 2 else 0)
	return math.ceil(width), math.ceil(height)
end

-- Escala según la distancia (más lejos, más pequeño) y la pantalla (en el móvil, algo menor)
function BubbleLayout.scale(distance: number, viewportHeight: number): number
	local near = math.clamp(1.12 - distance / 110, 0.7, 1.05)
	local screen = math.clamp(viewportHeight / 760, 0.82, 1.15)
	return near * screen
end

---------------------------------------------------------------------
-- Quién está hablando: un bocadillo por personaje
---------------------------------------------------------------------
export type Entry = {
	Key: any,
	Text: string,
	Name: string?,
	Start: number, -- cuando apareció (para el fundido)
	PopAt: number, -- cuando cambió la frase (el bocadillo "salta" un poco)
	Until: number, -- cuando empieza a irse
	Sticky: boolean,
	Serial: number,
}
export type Book = { Entries: { [any]: Entry }, Serial: number }

function BubbleLayout.book(): Book
	return { Entries = {}, Serial = 0 }
end

-- Alguien dice algo. opts: Seconds (duración fija), Sticky (hasta que se quite), Name.
-- Devuelve la entrada y si ha cambiado el texto (para volver a hacer el "pop")
function BubbleLayout.put(book: Book, key: any, text: string, now: number, opts: { [string]: any }?): (Entry, boolean)
	local o = opts or {}
	local seconds = if o.Sticky then BubbleLayout.stickyCap(text) else (tonumber(o.Seconds) or BubbleLayout.duration(text))
	local entry = book.Entries[key]
	if entry and now < entry.Until + BubbleLayout.FadeOut then
		-- Ya tenía bocadillo: se cambia el texto en el mismo (nada de dos bocadillos suyos)
		local changed = entry.Text ~= text
		entry.Text = text
		entry.Name = o.Name or entry.Name
		entry.Sticky = o.Sticky == true
		if changed then
			entry.PopAt = now
		end
		if now > entry.Until then
			-- Se estaba yendo: vuelve a entrar desde la opacidad que tenía
			local a = BubbleLayout.alpha(entry, now)
			entry.Start = now - a * BubbleLayout.FadeIn
		end
		entry.Until = now + seconds
		return entry, changed
	end
	book.Serial += 1
	local fresh: Entry = {
		Key = key,
		Text = text,
		Name = o.Name,
		Start = now,
		PopAt = now,
		Until = now + seconds,
		Sticky = o.Sticky == true,
		Serial = book.Serial,
	}
	book.Entries[key] = fresh
	return fresh, true
end

-- Se calla (empieza a irse ya)
function BubbleLayout.quiet(book: Book, key: any, now: number)
	local entry = book.Entries[key]
	if entry and entry.Until > now then
		entry.Until = now
	end
end

-- Quita los que ya se han ido del todo; devuelve sus claves
function BubbleLayout.sweep(book: Book, now: number): { any }
	local gone = {}
	for key, entry in book.Entries do
		if now >= entry.Until + BubbleLayout.FadeOut then
			table.insert(gone, key)
		end
	end
	for _, key in gone do
		book.Entries[key] = nil
	end
	return gone
end

-- ¿Está hablando (con su bocadillo a la vista)?
function BubbleLayout.speaking(book: Book, key: any, now: number): boolean
	local entry = book.Entries[key]
	return entry ~= nil and now < entry.Until
end

-- Opacidad (0 = invisible, 1 = del todo) y "pop" (escala) en este momento
function BubbleLayout.alpha(entry: Entry, now: number): (number, number)
	local t = now - entry.Start
	local fadeIn = math.clamp(t / BubbleLayout.FadeIn, 0, 1)
	local fadeOut = math.clamp((entry.Until + BubbleLayout.FadeOut - now) / BubbleLayout.FadeOut, 0, 1)
	local a = math.min(fadeIn, fadeOut)
	local p = math.clamp((now - entry.PopAt) / BubbleLayout.FadeIn, 0, 1)
	local pop = 0.86 + 0.14 * (1 - (1 - p) ^ 3)
	return a, pop
end

---------------------------------------------------------------------
-- Apilar: que ningún bocadillo pise a otro
---------------------------------------------------------------------
-- items: { Id, X (centro, píxeles), Y (donde apunta el pico, píxeles; Y crece hacia abajo), W, H, Depth }
-- Devuelve { [Id] = cuántos píxeles sube cada uno }. El más cercano a la cámara se queda en su sitio y
-- los demás suben por encima de lo que ya está colocado.
function BubbleLayout.stack(items: { { [string]: any } }, gap: number?): { [any]: number }
	local g = gap or BubbleLayout.Gap
	local order = table.clone(items)
	table.sort(order, function(a, b)
		if a.Depth ~= b.Depth then
			return a.Depth < b.Depth
		end
		return tostring(a.Id) < tostring(b.Id)
	end)
	local placed: { { L: number, R: number, T: number, B: number } } = {}
	local lifts: { [any]: number } = {}
	for _, item in order do
		local left, right = item.X - item.W / 2, item.X + item.W / 2
		local bottom = item.Y
		local moved = true
		local guard = 0
		while moved and guard < 64 do
			moved = false
			guard += 1
			local top = bottom - item.H
			for _, r in placed do
				local overlapX = left < r.R + g and right > r.L - g
				local overlapY = top < r.B + g and bottom > r.T - g
				if overlapX and overlapY then
					bottom = r.T - g -- sube justo por encima
					moved = true
					break
				end
			end
		end
		table.insert(placed, { L = left, R = right, T = bottom - item.H, B = bottom })
		lifts[item.Id] = item.Y - bottom
	end
	return lifts
end

return BubbleLayout
