-- DialogueLook: las cuentas del aspecto de la caja de diálogo (Controllers/DialogueUI).
--
--   * Retrato de quien habla: la cara de su personaje si está en la escena (una copia de su cabeza en
--     un ViewportFrame, la hace DialogueUI) y, si no se puede, una insignia redonda con su inicial y el
--     color de su ropa (shared/LifeStory/Cast). Los seres de otro mundo (Cast: Glow) llevan el borde de
--     su brillo; quien habla por teléfono, el icono del teléfono; el narrador, sin retrato.
--   * Medidas de la caja (las usa DialogueUI y las comprueba la prueba): ancho, márgenes, retrato,
--     letra, y si la frase más larga cabe en un móvil pequeño sin encoger la letra.
--
-- Cuentas puras (scripts/test-stagedirector, sección 10).

local DialogueLook = {}

---------------------------------------------------------------------
-- Medidas de la caja (en píxeles «naturales», antes de la escala del móvil)
---------------------------------------------------------------------

DialogueLook.BoxWidth = 640
DialogueLook.Padding = 18 -- izquierda y derecha
DialogueLook.PadTop, DialogueLook.PadBottom = 22, 14
DialogueLook.Portrait = 60 -- lado del retrato
DialogueLook.Gap = 12 -- entre el retrato y el texto
DialogueLook.TextSize = 19
DialogueLook.HintSize = 14
DialogueLook.ListGap = 8
DialogueLook.Bottom = 84 -- de la caja al borde de abajo
DialogueLook.NameAbove = 48 -- el nombre flota encima
DialogueLook.CharWidth = 0.55 -- ancho medio de una letra (× tamaño; Gotham, con margen)
DialogueLook.LineHeight = 1.25 -- alto de una línea (× tamaño)
DialogueLook.MinScale = 0.8 -- escala mínima del móvil (Theme.popupScale): la letra no baja de aquí
DialogueLook.TouchTarget = 44 -- alto mínimo de un botón táctil (respuestas)

-- Ancho para el texto (con o sin retrato)
function DialogueLook.textWidth(portrait: boolean?): number
	local w = DialogueLook.BoxWidth - DialogueLook.Padding * 2
	if portrait then
		w -= DialogueLook.Portrait + DialogueLook.Gap
	end
	return w
end

-- Cuántas líneas ocupa una frase de `chars` letras en `width` píxeles con letra `size`
function DialogueLook.lines(chars: number, width: number, size: number?): number
	local s = size or DialogueLook.TextSize
	local perLine = math.max(1, math.floor(width / (s * DialogueLook.CharWidth)))
	return math.max(1, math.ceil(math.max(0, chars) / perLine))
end

-- Alto natural de la caja con una frase de `chars` letras (y el retrato)
function DialogueLook.boxHeight(chars: number, portrait: boolean?): number
	local textH = DialogueLook.lines(chars, DialogueLook.textWidth(portrait)) * DialogueLook.TextSize * DialogueLook.LineHeight
	local body = if portrait then math.max(textH, DialogueLook.Portrait) else textH
	return DialogueLook.PadTop + body + DialogueLook.ListGap + DialogueLook.HintSize + DialogueLook.PadBottom
end

-- ¿Cabe en una pantalla de viewX × viewY sin bajar la escala de MinScale (la misma cuenta que
-- Theme.popupScale)? Devuelve si cabe y la escala que quedaría.
function DialogueLook.fits(chars: number, viewX: number, viewY: number, portrait: boolean?): (boolean, number)
	local natural = DialogueLook.boxHeight(chars, portrait)
	local s = math.clamp(viewY / 850, DialogueLook.MinScale, 1.25)
	s = math.min(s, (viewY - 70) / (natural + DialogueLook.Bottom + DialogueLook.NameAbove), (viewX - 24) / DialogueLook.BoxWidth)
	return s >= DialogueLook.MinScale - 1e-6, s
end

---------------------------------------------------------------------
-- Subtítulos de las escenas (la banda negra de abajo: Controllers/Cinematics y HappeningClient)
---------------------------------------------------------------------

-- La banda mide el 11 % del alto (en un móvil apaisado de 375 px, ~33 px útiles: H3 de la auditoría).
-- El subtítulo, pegado abajo, mide al menos CaptionMinHeight (crece unos px por encima de la banda en
-- un móvil pequeño, sin llegar al «Toca para seguir») para que una frase larga quepa en 2 líneas con
-- letra de CaptionMinText o más.

DialogueLook.Bar = 0.11
DialogueLook.CaptionWidth = 0.86
DialogueLook.CaptionMinHeight = 44
DialogueLook.CaptionMinText = 13
DialogueLook.CaptionMaxText = 20

-- ¿Cabe un subtítulo de `chars` letras en una pantalla viewX × viewY? Devuelve si cabe y la letra
-- (la mayor de CaptionMaxText a CaptionMinText con la que cabe, como TextScaled)
function DialogueLook.captionFits(chars: number, viewX: number, viewY: number): (boolean, number)
	local width = viewX * DialogueLook.CaptionWidth
	local height = math.max(viewY * DialogueLook.Bar - 8, DialogueLook.CaptionMinHeight)
	for size = DialogueLook.CaptionMaxText, DialogueLook.CaptionMinText, -1 do
		if DialogueLook.lines(chars, width, size) * size * 1.15 <= height then
			return true, size
		end
	end
	return false, DialogueLook.CaptionMinText
end

---------------------------------------------------------------------
-- Retrato: la insignia de repuesto
---------------------------------------------------------------------

local UPPER = {
	["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ü"] = "Ü", ["ñ"] = "Ñ", ["ç"] = "Ç",
}
local LETTERS = { ["Á"] = true, ["É"] = true, ["Í"] = true, ["Ó"] = true, ["Ú"] = true, ["Ü"] = true, ["Ñ"] = true, ["Ç"] = true }

-- La inicial de un nombre (la primera letra, en mayúscula, con tildes); sin letras, «?»
function DialogueLook.initial(name: string?): string
	if type(name) ~= "string" then
		return "?"
	end
	for _, code in utf8.codes(name) do
		local ch = utf8.char(code)
		if ch:match("^%a$") then
			return ch:upper()
		elseif UPPER[ch] then
			return UPPER[ch]
		elseif LETTERS[ch] then
			return ch
		end
	end
	return "?"
end

-- Colores de repuesto para quien no está en el reparto (por su nombre: siempre el mismo)
DialogueLook.Palette = {
	{ 66, 133, 244 }, { 219, 68, 55 }, { 15, 157, 88 }, { 171, 71, 188 },
	{ 255, 112, 67 }, { 0, 151, 167 }, { 124, 179, 66 }, { 92, 107, 192 },
}
DialogueLook.MeColor = { 60, 130, 210 }
-- Icono de quien no está (teléfono, mensaje, altavoz…): los de StageDirector.RemoteIcons; si no, 📱
DialogueLook.RemoteIcon = "📱"

local function hash(text: string): number
	local h = 0
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- Un color de fondo con el que la inicial blanca se lee (los muy claros se oscurecen)
function DialogueLook.readable(rgb: { number }): { number }
	local r, g, b = rgb[1], rgb[2], rgb[3]
	local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
	if luminance <= 0.55 then
		return { r, g, b }
	end
	local k = 0.55 / luminance * 0.8
	return { math.floor(r * k), math.floor(g * k), math.floor(b * k) }
end

local function rgbOf(color: any): { number }?
	if typeof and typeof(color) == "Color3" then
		return { math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5) }
	elseif type(color) == "table" and type(color.R) == "number" then
		return { math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5) }
	end
	return nil
end

export type Badge = { Show: boolean, Initial: string, Color: { number }, Ring: { number }?, Icon: string? }

-- La insignia de quien dice la frase.
--   line: { Id, Name, Me, Narrator, Direction = { Remote } } (lo que manda DialogueService)
--   people: Cast.People (opcional: el color de su ropa y su brillo)
--   icons: StageDirector.RemoteIcons (opcional)
function DialogueLook.badge(line: { [string]: any }, people: { [string]: any }?, icons: { [string]: string }?): Badge
	if line.Narrator then
		return { Show = false, Initial = "", Color = { 0, 0, 0 } }
	end
	local direction = if type(line.Direction) == "table" then line.Direction else {}
	local remote = direction.Remote
	local icon = if remote then ((icons and icons[remote]) or DialogueLook.RemoteIcon) else nil
	if line.Me then
		return { Show = true, Initial = DialogueLook.initial(line.Name), Color = DialogueLook.MeColor, Icon = icon }
	end
	local person = if people and type(line.Id) == "string" then people[line.Id] else nil
	local color = person and rgbOf(person.Shirt)
	local ring = person and rgbOf(person.Glow)
	if not color then
		local key = if type(line.Id) == "string" then line.Id elseif type(line.Name) == "string" then line.Name else "?"
		color = DialogueLook.Palette[hash(key) % #DialogueLook.Palette + 1]
	end
	return { Show = true, Initial = DialogueLook.initial(line.Name or line.Id), Color = DialogueLook.readable(color :: { number }), Ring = ring, Icon = icon }
end

-- ¿Se intenta poner su cara (copia de su cabeza)? Solo si está en la escena y no habla por teléfono
function DialogueLook.wantsFace(line: { [string]: any }, hasModel: boolean): boolean
	if line.Narrator or not hasModel then
		return false
	end
	local direction = if type(line.Direction) == "table" then line.Direction else {}
	return direction.Remote == nil
end

return DialogueLook
