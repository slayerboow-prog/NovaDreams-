-- AudioSettings: los cuatro volúmenes del menú Ajustes (🎵 Música, 🗣️ Voces, 🔔 Efectos, 🌳 Ambiente),
-- cada uno de 0 a 10 (0 = apagado). Lo comparten el cliente (Controllers/AudioMix, que los aplica) y el
-- servidor (Services/SettingsService, que los guarda con la partida en data.Audio).
--
--   * Curva perceptiva: ganancia = (nivel / 10)^2, así cada paso se oye parecido (el oído no es lineal:
--     con una recta, del 10 al 7 casi no cambia y del 3 al 0 se va de golpe). 10 = como antes.
--   * Por defecto la música baja y las voces arriba («para poder bajar la música y se oigan más los
--     diálogos que los pajaritos»): Música 6, Voces 9, Efectos 8, Ambiente 5.
--   * Qué es cada sonido de Config.Sounds: Bus = "Ambience" (camas de fondo: ciudad, pájaros, grillos,
--     olas, viento, lluvia, salas) o, si no dice nada, "Sfx" (interfaz, acciones, vehículos, deportes,
--     armas, la grieta del cielo…). La grieta y los motores son efectos: un suceso, no el fondo.

local AudioSettings = {}

AudioSettings.Max = 10
AudioSettings.Keys = { "Music", "Voice", "Sfx", "Ambience" }
AudioSettings.Defaults = { Music = 6, Voice = 9, Sfx = 8, Ambience = 5 }

-- Texto del menú (con su emoji; SettingsRows lo reconoce por el nombre)
AudioSettings.Labels = { Music = "🎵 Música", Voice = "🗣️ Voces", Sfx = "🔔 Efectos", Ambience = "🌳 Ambiente" }
AudioSettings.Names = { Music = "Música", Voice = "Voces", Sfx = "Efectos", Ambience = "Ambiente" }

-- Grupo de sonido (SoundService) de cada control
AudioSettings.Groups = { Music = "Music", Voice = "Voice", Sfx = "SFX", Ambience = "Ambience" }

-- Atributo del jugador con lo guardado (lo pone el servidor al cargar la partida)
function AudioSettings.attribute(key: string): string
	return "Vol" .. key
end

function AudioSettings.isKey(key: any): boolean
	return type(key) == "string" and AudioSettings.Defaults[key] ~= nil
end

-- ¿Vale para guardar? Un número entero de 0 a 10 (nada de NaN, infinitos ni decimales)
function AudioSettings.isLevel(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value <= AudioSettings.Max and math.floor(value) == value
end

-- Cualquier cosa -> un nivel válido (0 … 10, entero); lo que no es número, el de por defecto
function AudioSettings.clamp(value: any, key: string?): number
	local n = tonumber(value)
	if n == nil or n ~= n then
		return if key and AudioSettings.Defaults[key] then AudioSettings.Defaults[key] else 0
	end
	return math.clamp(math.floor(n + 0.5), 0, AudioSettings.Max)
end

-- Botones − / +: un paso, sin salirse de 0 … 10
function AudioSettings.step(value: any, delta: number): number
	return AudioSettings.clamp(AudioSettings.clamp(value) + (if delta >= 0 then 1 else -1) * math.max(1, math.abs(math.floor(delta))))
end

-- Nivel (0 … 10) -> ganancia (0 … 1), curva cuadrática
function AudioSettings.gain(level: any): number
	local v = AudioSettings.clamp(level) / AudioSettings.Max
	return v * v
end

-- La misma ganancia en decibelios (-inf con 0): para las pruebas y el DebugHud
function AudioSettings.decibels(level: any): number
	local g = AudioSettings.gain(level)
	return if g <= 0 then -math.huge else 20 * math.log10(g)
end

-- Lo guardado en la partida (data.Audio) -> los cuatro niveles; lo que falte o no valga, por defecto
function AudioSettings.sanitize(saved: any): { [string]: number }
	local out = {}
	for _, key in AudioSettings.Keys do
		local value = if type(saved) == "table" then saved[key] else nil
		out[key] = if AudioSettings.isLevel(value) then value else AudioSettings.Defaults[key]
	end
	return out
end

-- Texto de la fila del menú: «🎵 Música: 7»
function AudioSettings.label(key: string, level: number): string
	return ("%s: %d"):format(AudioSettings.Labels[key] or key, AudioSettings.clamp(level))
end

-- Control al que va un sonido de Config.Sounds (por su entrada): "Ambience" o "Sfx"
function AudioSettings.busOf(entry: any): string
	if type(entry) == "table" and entry.Bus == "Ambience" then
		return "Ambience"
	end
	return "Sfx"
end

return AudioSettings
