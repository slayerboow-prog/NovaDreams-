-- NameFilter: nombres que escriben los jugadores (negocios). Primera barrera, sin conexión:
-- palabrotas, insultos y temas prohibidos en español e inglés, aunque se escriban con trucos
-- ("P.U.T.A", "put4", "puuuta", "m i e r d a", "coño" o "cono"...), y nombres que no parecen
-- nombres (enlaces, teléfonos, símbolos raros).
--
-- Después, en el servidor, el nombre pasa SIEMPRE por el filtro de Roblox (TextService), que es
-- obligatorio para enseñar a otros jugadores un texto escrito por un jugador (BusinessService).
--
--   NameFilter.check(text) -> (ok, motivo?, texto limpio)

local NameFilter = {}

NameFilter.MinLength = 3
NameFilter.MaxLength = 28

-- Letras con tilde -> sin tilde (la ñ se queda como "ny" para no confundir "coño" con "cono")
local ACCENTS = {
	["á"] = "a", ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["Á"] = "a", ["À"] = "a", ["Â"] = "a", ["Ä"] = "a",
	["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["Ë"] = "e",
	["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i", ["Í"] = "i", ["Ì"] = "i", ["Î"] = "i", ["Ï"] = "i",
	["ó"] = "o", ["ò"] = "o", ["ô"] = "o", ["ö"] = "o", ["Ó"] = "o", ["Ò"] = "o", ["Ô"] = "o", ["Ö"] = "o",
	["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["Ú"] = "u", ["Ù"] = "u", ["Û"] = "u", ["Ü"] = "u",
	["ñ"] = "ny", ["Ñ"] = "ny", ["ç"] = "c", ["Ç"] = "c",
}
-- Números y símbolos que se usan como letras
local LEET = { ["0"] = "o", ["1"] = "i", ["3"] = "e", ["4"] = "a", ["5"] = "s", ["7"] = "t", ["8"] = "b", ["@"] = "a", ["$"] = "s", ["!"] = "i", ["|"] = "i", ["+"] = "t" }

-- Palabras prohibidas si la palabra ES exactamente esta
local EXACT = {
	"puta", "putas", "puto", "putos", "putita", "putito", "puton", "polla", "pollas", "culo", "culos", "culito", "teta", "tetas",
	"pene", "penes", "zorra", "zorras", "marica", "maricas", "coyon", "hdp", "ctm", "ptm", "mrd", "wtf", "stfu", "cagar", "caca",
	"sexo", "sexy", "sex", "xxx", "cock", "cocks", "dick", "dicks", "tits", "boobs", "anal", "cum", "verga", "vergas",
	"chocho", "chochos", "ojete", "ano", "panchito", "droga", "drogas", "porro", "porros",
}
-- Palabras prohibidas si la palabra EMPIEZA así (y sus variantes: -as, -os, -azo, -ero…)
local PREFIX = {
	"mierd", "joder", "jodid", "jodet", "jodan", "follar", "follad", "follan", "follon", "gilipo", "capull", "cabron", "maricon",
	"hijoput", "hijodeput", "hijaput", "putade", "putero", "puteri", "puticlub", "prostitu", "conyo", "cojon", "mamon", "mamad",
	"pajer", "pajill", "chinga", "chingu", "pendej", "culer", "cagon", "gonorr", "malparid", "huevon", "boludo", "pelotud",
	"subnormal", "retrasad", "mongolo", "mongola", "idiota", "imbecil", "estupid", "tonto", "gilipuertas", "negrat", "sudaca", "bollera",
	"travelo", "nazi", "hitler", "violad", "violar", "violaci", "cocain", "marihuan", "heroin", "porno", "porn",
	"orgia", "masturb", "semen", "vagin", "clitor", "erotic", "prostit", "suicid", "matar", "asesin", "terroris",
	"fuck", "fuk", "fck", "shit", "sht", "bitch", "biatch", "cunt", "whore", "slut", "asshole", "arsehole", "bastard", "nigg",
	"niga", "fagg", "fagot", "dickhead", "motherf", "pussy", "puss", "penis", "rape", "rapist", "retard", "kys", "kill",
}
-- Trozos prohibidos en cualquier parte, aunque vayan pegados a otras palabras ("tiendaputa")
local ANYWHERE = {
	"hijoputa", "hijodeputa", "putamadre", "gilipolla", "mierda", "cabron", "maricon", "puticlub", "conyo",
	"fuck", "shit", "bitch", "nigger", "nigga", "asshole", "motherfuck", "pussy", "porno", "hitler",
	"joder", "follar", "cojon", "pendejo", "chinga", "hijaputa", "putero", "putita",
}

-- Quita repeticiones: "puuuutaaa" -> "puta"
local function collapse(word: string): string
	local out = {}
	local last = ""
	for i = 1, #word do
		local c = word:sub(i, i)
		if c ~= last then
			table.insert(out, c)
		end
		last = c
	end
	return table.concat(out)
end

-- Texto -> palabras en minúsculas, sin tildes, con los trucos de números deshechos
function NameFilter.words(text: string): { string }
	local lower = text
	for from, to in ACCENTS do
		lower = lower:gsub(from, to)
	end
	lower = lower:lower()
	lower = lower:gsub(".", function(c)
		return LEET[c] or c
	end)
	local raw = {}
	for word in lower:gmatch("%a+") do
		table.insert(raw, word)
	end
	-- Letras sueltas seguidas ("p u t a", "m.i.e.r.d.a") se juntan en una palabra
	local words = {}
	local run = ""
	for _, w in raw do
		if #w == 1 then
			run ..= w
		else
			if #run > 0 then
				table.insert(words, run)
				run = ""
			end
			table.insert(words, w)
		end
	end
	if #run > 0 then
		table.insert(words, run)
	end
	return words
end

local function matches(word: string): boolean
	for _, bad in EXACT do
		if word == bad then
			return true
		end
	end
	for _, bad in PREFIX do
		if word:sub(1, #bad) == bad then
			return true
		end
	end
	-- Con letras repetidas ("puuuta", "pollla"): se compara sin repeticiones
	local short = collapse(word)
	if short ~= word then
		for _, bad in EXACT do
			if short == collapse(bad) then
				return true
			end
		end
		for _, bad in PREFIX do
			local b = collapse(bad)
			if short:sub(1, #b) == b then
				return true
			end
		end
	end
	return false
end

-- ¿Lleva algo prohibido?
function NameFilter.isBad(text: string): boolean
	local words = NameFilter.words(text)
	for _, w in words do
		if matches(w) then
			return true
		end
	end
	local joined = table.concat(words, "")
	local joinedShort = collapse(joined)
	for _, bad in ANYWHERE do
		if joined:find(bad, 1, true) then
			return true
		end
		local b = collapse(bad)
		if joinedShort ~= joined and joinedShort:find(b, 1, true) then
			return true
		end
	end
	return false
end

-- Espacios de más fuera
function NameFilter.clean(text: string): string
	local t = text:gsub("[%c]", " "):gsub("%s+", " ")
	t = t:match("^%s*(.-)%s*$") or ""
	return t
end

-- Comprueba un nombre de negocio. Devuelve (vale, motivo si no vale, nombre limpio)
function NameFilter.check(text: any): (boolean, string?, string)
	if type(text) ~= "string" then
		return false, "Escribe un nombre.", ""
	end
	local name = NameFilter.clean(text)
	local length = utf8.len(name) or #name
	if length < NameFilter.MinLength then
		return false, ("El nombre es muy corto (mínimo %d letras)."):format(NameFilter.MinLength), name
	end
	if length > NameFilter.MaxLength then
		return false, ("El nombre es muy largo (máximo %d letras)."):format(NameFilter.MaxLength), name
	end
	-- Solo letras (con tildes y ñ), números, espacios y . , ' & -
	local plain = name
	for from in ACCENTS do
		plain = plain:gsub(from, "a")
	end
	if plain:find("[^%w%s%.,'&%-]") then
		return false, "Usa solo letras, números, espacios y . , ' & -", name
	end
	local lower = name:lower()
	if lower:find("http") or lower:find("www") or lower:find("%.com") or lower:find("%.es") or lower:find("discord") then
		return false, "Nada de enlaces ni redes sociales.", name
	end
	local digits = select(2, name:gsub("%d", ""))
	if digits > 4 then
		return false, "Demasiados números (nada de teléfonos).", name
	end
	if not name:find("%a") then
		return false, "El nombre tiene que llevar letras.", name
	end
	if NameFilter.isBad(name) then
		return false, "🚫 Ese nombre no está permitido. Elige uno apropiado para todo el mundo.", name
	end
	return true, nil, name
end

return NameFilter
