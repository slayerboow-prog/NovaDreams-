-- TimeContext: que lo que dice la gente cuadre con la hora y el tiempo que hace.
-- Nadie dice "Buenos días" a las 23:00, ni "¡Qué calor!" nevando, ni "Qué buen día hace" bajo la
-- tormenta. Lo usan las conversaciones y frases sueltas (DialogueService), la gente de la ciudad y
-- de los puestos (Npc.say) y las voces de la calle (cliente).
--
--   TimeContext.greeting(hora)              -> "Buenos días" | "Buenas tardes" | "Buenas noches"
--   TimeContext.adapt(texto, hora, tiempo)  -> el texto con el saludo (y la despedida) de esa hora
--   TimeContext.fits(texto, hora, tiempo)   -> ¿se puede decir ahora? (para elegir frases sueltas)
--   TimeContext.pick(lista, hora, tiempo, rng?) -> una frase de la lista que se pueda decir ahora
-- Lo que va entre «comillas» (alguien cuenta lo que dijo otro) no se toca.

local TimeContext = {}

-- Tramos del día (hora de juego, 0-24)
TimeContext.Morning = 6 -- desde las 6:00, "Buenos días"
TimeContext.Afternoon = 13 -- desde las 13:00, "Buenas tardes"
TimeContext.Night = 20.5 -- desde las 20:30, "Buenas noches"

function TimeContext.period(hour: number): string
	if hour >= TimeContext.Morning and hour < TimeContext.Afternoon then
		return "Morning"
	elseif hour >= TimeContext.Afternoon and hour < TimeContext.Night then
		return "Afternoon"
	end
	return "Night"
end

local GREETING = { Morning = "Buenos días", Afternoon = "Buenas tardes", Night = "Buenas noches" }
local FAREWELL = { Morning = "buen día", Afternoon = "buena tarde", Night = "buena noche" }

function TimeContext.greeting(hour: number): string
	return GREETING[TimeContext.period(hour)]
end

-- Parte el texto en trozos fuera y dentro de «comillas» y cambia solo los de fuera
local function outsideQuotes(text: string, fn: (string) -> string): string
	local out = {}
	local rest = text
	while true do
		local a, b = rest:find("«[^»]*»")
		if not a then
			table.insert(out, fn(rest))
			break
		end
		table.insert(out, fn(rest:sub(1, a - 1)))
		table.insert(out, rest:sub(a, b))
		rest = rest:sub(b + 1)
	end
	return table.concat(out)
end

local GREETING_PATTERNS = { "[Bb]uenos días", "[Bb]uenas tardes", "[Bb]uenas noches" }

-- El saludo de la hora que es (respetando mayúscula) y la despedida "que tenga un buen día"
function TimeContext.adapt(text: string, hour: number?, weather: string?): string
	if type(text) ~= "string" or hour == nil then
		return text
	end
	local period = TimeContext.period(hour)
	local greeting = GREETING[period]
	return outsideQuotes(text, function(part)
		for _, pattern in GREETING_PATTERNS do
			part = part:gsub(pattern, function(found)
				local first = found:sub(1, 1)
				return if first == "b" then greeting:lower() else greeting
			end)
		end
		part = part:gsub("un buen día!", function()
			return (if period == "Morning" then "un buen día" elseif period == "Afternoon" then "una buena tarde" else "una buena noche") .. "!"
		end)
		return part
	end)
end
TimeContext.Farewell = FAREWELL

-- Frases que solo se dicen con buen tiempo, de día o con calor
local SUNNY = { "buen día hace", "día más bueno", "qué buen día", "qué sol", "a ver si no llueve" }
local HOT = { "qué calor", "calor que hace" }
local DAYTIME = { "¡a trabajar!", "qué bonito está el mar", "empújame en el columpio", "¡mamá, mira!" }
local WET = { Rain = true, Storm = true, Snow = true, Fog = true, Lluvia = true, Tormenta = true, Nieve = true, Niebla = true }

local function contains(text: string, list: { string }): boolean
	local lower = text:lower()
	for _, fragment in list do
		if lower:find(fragment, 1, true) then
			return true
		end
	end
	return false
end

-- ¿Pega decir esto ahora?
function TimeContext.fits(text: string, hour: number?, weather: string?): boolean
	if type(text) ~= "string" then
		return false
	end
	local period = if hour then TimeContext.period(hour) else "Morning"
	local bad = weather ~= nil and WET[weather] == true
	local cloudy = weather == "Nublado" or weather == "Cloudy"
	if contains(text, SUNNY) and (bad or cloudy or period == "Night") then
		return false
	end
	if contains(text, HOT) and (bad or period == "Night" or weather == "Snow" or weather == "Nieve") then
		return false
	end
	if contains(text, DAYTIME) and period == "Night" then
		return false
	end
	return true
end

-- Una frase de la lista que pegue ahora (ya con el saludo de la hora)
function TimeContext.pick(lines: { string }, hour: number?, weather: string?, rng: Random?): string?
	local fitting = {}
	for _, line in lines do
		if TimeContext.fits(line, hour, weather) then
			table.insert(fitting, line)
		end
	end
	if #fitting == 0 then
		return nil
	end
	local index = if rng then rng:NextInteger(1, #fitting) else math.random(1, #fitting)
	return TimeContext.adapt(fitting[index], hour, weather)
end

-- La hora y el tiempo de ahora en el mundo (servidor o cliente)
function TimeContext.now(): (number, string?)
	local hour = 12
	local weather = nil
	pcall(function()
		hour = game:GetService("Lighting").ClockTime
	end)
	pcall(function()
		local value = workspace:GetAttribute("Weather")
		weather = if type(value) == "string" then value else nil
	end)
	return hour, weather
end

return TimeContext
