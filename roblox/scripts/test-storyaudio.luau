-- Prueba: la música por intensidad y el ambiente por tipo de lugar (client/Controllers/StoryAudio).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-storyaudio.luau
--
-- Carga StoryAudio fuera de Roblox (scripts/lib/ModuleLoader) con dobles de SoundFx, TweenService y
-- Sound, y comprueba:
--   * Config.Audio: cada intensidad tiene su pieza, cada pieza su archivo en audio/, cada Fallback existe;
--     cada ambiente usa sonidos de Config.Sounds que existen, y los Amb* tienen su archivo en audio/sfx.
--   * setIntensity: nombres con y sin tildes, cruce suave (la anterior baja y se quita después), el
--     Fallback mientras la pieza nueva no está subida, "Nada" = sin música, la tabla de la pista.
--   * setAmbience: los cinco tipos del encargo y los interiores, NUNCA silencio (con solo los audios
--     que ya están subidos, de día y de noche), las capas que siguen no se cortan, golpes sueltos.
--   * clear y cinematicEnd: nada de lo que pidió la escena sigue sonando.
--   * kindFor: el ambiente automático según dónde estás (casa, salas, colegio, hospital, calle…).
--   * IDs: SoundIds y Config.Audio bien formados («rbxassetid://<número>»), y cada pieza de fondo con
--     una reserva subida por otro camino.
--   * Arranque: con Música: sí por defecto, la música de tu etapa suena a los BootDelay s (sin esperar a
--     ningún capítulo), en bucle, en el grupo Music y con volumen que se oye; el ambiente también.
--   * Si un audio no carga (ContentProvider: Failure), suena su reserva y no se vuelve a pedir; una capa
--     del ambiente que no carga pasa a su opción siguiente.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local V3 = roblox.Vector3
local check = L.check

---------------------------------------------------------------------
-- Dobles
---------------------------------------------------------------------
local function signal()
	return {
		Connect = function()
			return { Disconnect = function() end }
		end,
	}
end

local sounds = {}
local function fakeSound()
	local s = {
		ClassName = "Sound",
		Name = "Sound",
		SoundId = "",
		Volume = 0.5,
		PlaybackSpeed = 1,
		Looped = false,
		IsLoaded = true,
		Playing = false,
		Destroyed = false,
		Ended = signal(),
		Loaded = signal(),
		Children = {},
	}
	function s:Play()
		self.Playing = true
	end
	function s:Destroy()
		self.Destroyed = true
		self.Parent = nil
	end
	function s:IsA(class)
		return class == "Sound"
	end
	table.insert(sounds, s)
	return s
end
L.fakeClasses.Sound = fakeSound
L.fakeClasses.Folder = function()
	return { Name = "Folder", Parent = nil }
end
L.fakeClasses.EqualizerSoundEffect = function()
	return { ClassName = "EqualizerSoundEffect" }
end

local tweens = {}
local TweenInfo = {
	new = function(time)
		return { Time = time }
	end,
}
L.services.TweenService = {
	Create = function(_, object, info, props)
		local tween = { Object = object, Time = info.Time, Props = props }
		table.insert(tweens, tween)
		return {
			Play = function()
				for k, v in props do
					object[k] = v
				end
			end,
		}
	end,
}
L.services.SoundService = {
	FindFirstChild = function()
		return nil
	end,
}
L.services.Lighting = { ClockTime = 12 }
local player = L.player("Ana", 1)
player.Attributes.LifeStage = "Nino"
L.services.Players = { LocalPlayer = player }

local Config = L.load("src/shared/Config")
-- Las pruebas parten de antes de subir las piezas nuevas (luego las «suben» ellas mismas)
local SoundIds = table.clone(L.load("src/shared/SoundIds"))
for _, name in { "descubrimiento", "intima", "tension", "resolucion", "tema_final", "amb_sala", "amb_casa", "amb_colegio", "amb_universidad", "amb_hospital", "amb_calle" } do
	SoundIds[name] = nil
end

-- Lo que hay subido: al principio, lo de SoundIds (como en el juego); las pruebas pueden añadir más
local uploaded: { [string]: boolean } = {}
for name in SoundIds do
	uploaded[name] = true
end
local ambientCalls = {}
local SoundFx = {
	group = function(name)
		return { Name = name }
	end,
	setGroupOn = function() end,
	uploaded = function(file)
		if not file then
			return nil
		end
		local name = string.gsub(file, "%.%a%w*$", "")
		return if uploaded[name] then "rbxassetid://up_" .. name else nil
	end,
	id = function(name)
		local entry = Config.Sounds[name]
		if not entry then
			return nil
		end
		if type(entry.Id) == "string" and entry.Id ~= "" then
			return entry.Id
		elseif type(entry.Id) == "number" and entry.Id > 0 then
			return "rbxassetid://" .. entry.Id
		end
		return if entry.File and uploaded[entry.File] then "rbxassetid://up_" .. entry.File else nil
	end,
	ambient = function(name, volume, pitch)
		table.insert(ambientCalls, { Name = name, Volume = volume, Pitch = pitch })
		return nil
	end,
}
L.mock("src/client/Controllers/SoundFx", SoundFx)
L.mock("src/client/UI/Theme", { create = function() end })
L.mock("src/shared/LifeStory/Strings", {
	get = function(key)
		return key
	end,
})

-- StoryAudio se carga aquí (como ModuleLoader, más TweenInfo, que ModuleLoader no trae)
local warnings = {}
local function loadStoryAudio()
	local luau = require("@lune/luau")
	local path = "src/client/Controllers/StoryAudio"
	local nodeMeta = getmetatable(L.services.ReplicatedStorage.Shared)
	local env = setmetatable({
		script = setmetatable({ __path = path }, nodeMeta),
		require = function(target)
			return L.load(rawget(target, "__path"))
		end,
		game = L.game,
		workspace = L.workspace,
		task = task,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = L.CFrame,
		Enum = roblox.Enum,
		Instance = L.Instance,
		TweenInfo = TweenInfo,
		typeof = roblox.typeof or typeof,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, { __index = _G })
	return luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
end
local StoryAudio = loadStoryAudio()
local AUDIO = Config.Audio
local AMB = AUDIO.Ambience

local function playingMusic()
	local list = {}
	for _, s in sounds do
		if not s.Destroyed and string.sub(s.Name, 1, 6) == "Music_" then
			table.insert(list, s)
		end
	end
	return list
end

local function liveLayers()
	local list = {}
	for _, s in sounds do
		if not s.Destroyed and string.sub(s.Name, 1, 9) == "Ambience_" then
			table.insert(list, s)
		end
	end
	return list
end

-- ¿Algo del ambiente suena (volumen > 0) y no está apagándose?
local function audible(): boolean
	for _, s in liveLayers() do
		if s.Volume > 0.001 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
print("\n▶ Config.Audio: piezas, intensidades y archivos")
---------------------------------------------------------------------
for _, level in { "Nada", "Descubrimiento", "Intima", "Tension", "Resolucion", "Tema" } do
	local def = AUDIO.Intensity[level]
	check(def ~= nil, ("la intensidad %s existe"):format(level))
	if def and def.Cue then
		check(AUDIO.Music[def.Cue] ~= nil, ("%s -> pieza %s en Config.Audio.Music"):format(level, def.Cue))
	end
end
local newPieces = 0
for cue, track in AUDIO.Music do
	check(fs.isFile("audio/" .. track.File), ("%s: el archivo audio/%s existe"):format(cue, track.File))
	if track.Fallback then
		check(AUDIO.Music[track.Fallback] ~= nil, ("%s: su Fallback %s existe"):format(cue, track.Fallback))
	end
	if track.Id == 0 then
		newPieces += 1
	end
end
check(newPieces == 5, ("5 piezas nuevas con Id = 0 (hay %d): suenan al subirlas (SoundIds) sin tocar Config"):format(newPieces))

print("\n▶ Config.Audio.Ambience: tipos, sonidos y archivos")
for _, kind in { "Colegio", "Casa", "Universidad", "Hospital", "Calle" } do
	check(AMB.Kinds[kind] ~= nil, ("el tipo %s existe"):format(kind))
end
local badRefs = {}
for kind, def in AMB.Kinds do
	for _, layer in def.Layers or {} do
		for _, option in layer.Sounds do
			local name = if type(option) == "table" then option.Sound else option
			if not Config.Sounds[name] then
				table.insert(badRefs, kind .. ":" .. tostring(name))
			end
		end
	end
	for _, spot in def.Spots or {} do
		if not Config.Sounds[spot.Sound] then
			table.insert(badRefs, kind .. ":" .. tostring(spot.Sound))
		end
	end
end
for _, target in AMB.Rooms do
	if not AMB.Kinds[target] then
		table.insert(badRefs, "Rooms->" .. target)
	end
end
for _, target in AMB.Aliases do
	if not AMB.Kinds[target] then
		table.insert(badRefs, "Aliases->" .. target)
	end
end
for _, place in AMB.Places do
	if not AMB.Kinds[place.Kind] or (place.Outdoor and not AMB.Kinds[place.Outdoor]) then
		table.insert(badRefs, "Places->" .. place.Kind)
	end
end
check(#badRefs == 0, "todos los sonidos y tipos que se nombran existen " .. table.concat(badRefs, ", "))
for name, entry in Config.Sounds do
	if string.sub(name, 1, 3) == "Amb" and entry.File then
		check(fs.isFile("audio/sfx/" .. entry.File .. ".ogg"), ("%s: el archivo audio/sfx/%s.ogg existe"):format(name, entry.File))
	end
end

---------------------------------------------------------------------
print("\n▶ API para las escenas")
---------------------------------------------------------------------
check(type(StoryAudio.setAmbience) == "function", "StoryAudio.setAmbience")
check(type(StoryAudio.setIntensity) == "function", "StoryAudio.setIntensity")
check(type(StoryAudio.clear) == "function", "StoryAudio.clear")
check(StoryAudio.resolveIntensity("tensión") == "Tension", "«tensión» = Tension")
check(StoryAudio.resolveIntensity("Íntima") == "Intima", "«Íntima» = Intima")
check(StoryAudio.resolveIntensity("Resolución") == "Resolucion", "«Resolución» = Resolucion")
check(StoryAudio.resolveIntensity("TEMA") == "Tema", "«TEMA» = Tema")
check(StoryAudio.resolveIntensity("normal") == "Nada", "«normal» = Nada")
check(StoryAudio.resolveIntensity("peligro") == "Tension", "«peligro» = Tension (la tabla del encargo)")
check(StoryAudio.resolveIntensity("xyz") == nil, "una intensidad que no existe = nil")
check(StoryAudio.resolveKind("hospital") == "Hospital", "«hospital» = Hospital")
check(StoryAudio.resolveKind("escuela") == "Colegio", "«escuela» = Colegio")
check(StoryAudio.resolveKind("Centro de salud") == "Hospital", "«Centro de salud» = Hospital")
check(StoryAudio.resolveKind("luna") == nil, "un ambiente que no existe = nil")

---------------------------------------------------------------------
print("\n▶ Música por intensidad (solo lo que ya está subido)")
---------------------------------------------------------------------
StoryAudio.setAmbient("TemaValmar")
check(StoryAudio.state().Music == "TemaValmar", "fondo del capítulo: TemaValmar")

StoryAudio.setIntensity("Descubrimiento")
check(StoryAudio.state().Intensity == "Descubrimiento", "intensidad Descubrimiento")
check(StoryAudio.state().Music == "TemaValmar", "Descubrimiento sin subir: suena su Fallback (TemaValmar), sin reiniciarla")
check(#playingMusic() == 1, "una sola pieza sonando (no se ha creado otra igual)")

StoryAudio.setIntensity({ Intensity = "Intima" })
check(StoryAudio.state().Music == "Nacimiento", "la tabla de la pista { Intensity = \"Intima\" }: Fallback Nacimiento")
local music = playingMusic()
check(#music == 2, "durante el cruce suenan dos (la que se va y la que llega): " .. #music)
local old, new
for _, s in music do
	if s.Name == "Music_TemaValmar" then
		old = s
	else
		new = s
	end
end
check(old and old.Volume == 0, "la anterior baja a 0")
check(new and new.Volume > 0, "la nueva sube")
local fadeOk = false
for _, t in tweens do
	if t.Object == old and t.Props.Volume == 0 then
		fadeOk = t.Time >= 1
	end
end
check(fadeOk, "el cruce es suave (≥ 1 s)")
task.wait(3.3)
check(old.Destroyed, "la anterior se quita al acabar el fundido")

check(StoryAudio.setIntensity("Tension"), "setIntensity(\"Tension\") = true")
check(StoryAudio.state().Music == nil, "Tension sin subir y sin Fallback: sin música (queda el ambiente)")
check(StoryAudio.setIntensity("nada de nada") == false, "una intensidad desconocida = false")
check(StoryAudio.state().Intensity == "Tension", "y no cambia nada")

print("\n▶ Música por intensidad (con las piezas nuevas subidas)")
for _, file in { "descubrimiento", "intima", "tension", "resolucion", "tema_final" } do
	uploaded[file] = true
end
for level, cue in { Descubrimiento = "Descubrimiento", Intima = "Intima", Tension = "Tension", Resolucion = "Resolucion", Tema = "TemaFinal" } do
	StoryAudio.setIntensity(level)
	check(StoryAudio.state().Music == cue, ("%s: suena %s"):format(level, cue))
end
StoryAudio.setIntensity("Nada")
check(StoryAudio.state().Music == nil and StoryAudio.state().Intensity == "Nada", "Nada: la música se va")
task.wait(3.5)
check(#playingMusic() == 0, "Nada: no queda ninguna pieza sonando")

StoryAudio.clear()
check(StoryAudio.state().Intensity == nil, "clear: sin intensidad")
check(StoryAudio.state().Music == "TemaValmar", "clear: vuelve la música del capítulo")

print("\n▶ La escena acaba: cinematicEnd")
StoryAudio.cinematicStart(nil)
StoryAudio.setIntensity("Tension")
StoryAudio.setAmbience("Hospital")
check(StoryAudio.state().Music == "Tension", "en la escena: Tension")
StoryAudio.cinematicEnd()
check(StoryAudio.state().Intensity == nil and StoryAudio.state().AmbienceOverride == nil, "al acabar: sin intensidad ni ambiente de escena")
task.wait(1.8)
check(StoryAudio.state().Music == "TemaValmar", "y vuelve la música del capítulo")
StoryAudio.cinematicStart("PasanLosAnos")
check(StoryAudio.state().Music == "PasanLosAnos", "cinematicStart(pieza) sigue funcionando como antes")
StoryAudio.cinematicEnd()
task.wait(1.8)
check(StoryAudio.state().Music == "TemaValmar", "y al acabar vuelve el fondo")

---------------------------------------------------------------------
print("\n▶ Ambiente: nunca silencio (solo lo que ya está subido)")
---------------------------------------------------------------------
for name in pairs(table.clone(uploaded)) do
	if not SoundIds[name] then
		uploaded[name] = nil
	end
end
for _, hour in { 12, 3 } do
	L.services.Lighting.ClockTime = hour
	for kind in AMB.Kinds do
		if kind ~= "Metro" then
			StoryAudio.setAmbience("Metro", 0.05) -- (de un tipo vacío a este: se ve qué suena de verdad)
			task.wait(0.1)
			StoryAudio.setAmbience(kind, 0.05)
			check(#StoryAudio.state().Layers > 0 and audible(), ("%s a las %d h: suena algo (%s)"):format(kind, hour, table.concat(StoryAudio.state().Layers, ", ")))
		end
	end
end
L.services.Lighting.ClockTime = 12

print("\n▶ Ambiente: capas, cruces y golpes sueltos")
StoryAudio.setAmbience("Colegio", 0.2)
local base
for _, s in liveLayers() do
	if s.Name == "Ambience_AmbAire" then
		base = s
	end
end
check(base ~= nil, "colegio sin subir: base de aire (el viento ya subido, apagado)")
StoryAudio.setAmbience("Universidad", 0.2)
local same = false
for _, s in liveLayers() do
	if s == base then
		same = true
	end
end
check(same, "de colegio a universidad la capa base sigue (no se corta)")
StoryAudio.setAmbience("Calle", 0.2)
task.wait(0.5)
check(base.Destroyed, "a la calle: la base del interior se va con fundido")

for _, file in { "amb_sala", "amb_casa", "amb_colegio", "amb_universidad", "amb_hospital", "amb_calle" } do
	uploaded[file] = true
end
StoryAudio.setAmbience("hospital", 0.2)
check(table.find(StoryAudio.state().Layers, "AmbHospital@1") ~= nil, "con los ambientes subidos, el hospital usa amb_hospital")
StoryAudio.setAmbience("Casa", 0.2)
check(table.find(StoryAudio.state().Layers, "AmbCasa@1") ~= nil, "y la casa, amb_casa")
table.clear(ambientCalls)
task.wait(2.5)
local ticks = 0
for _, call in ambientCalls do
	if call.Name == "Reloj" then
		ticks += 1
	end
end
check(ticks >= 1, "en casa suena el tic-tac del reloj (" .. ticks .. ")")
StoryAudio.setAmbience("Calle", 0.2)
task.wait(1.2)
table.clear(ambientCalls)
task.wait(1.5)
check(#ambientCalls == 0, "al salir de casa el reloj se calla")

L.services.Lighting.ClockTime = 23
StoryAudio.setAmbience("Colegio", 0.05)
StoryAudio.setAmbience("Colegio") -- (mismo tipo: nada cambia)
local kids
for _, s in liveLayers() do
	if s.Name == "Ambience_AmbColegio" then
		kids = s
	end
end
check(kids ~= nil and kids.Volume == 0, "de noche no hay niños en el colegio (la capa está a 0)")
check(audible(), "pero la sala no está en silencio")
L.services.Lighting.ClockTime = 12

check(StoryAudio.setAmbience("luna") == false, "un ambiente desconocido = false")
check(StoryAudio.state().Ambience == "Colegio", "y no cambia nada")
StoryAudio.setAmbience("Auto")
check(StoryAudio.state().AmbienceOverride == nil and StoryAudio.state().Ambience == StoryAudio.zoneKind(), "«Auto»: vuelve el del sitio donde estás")
StoryAudio.setAmbience({ Kind = "hospital" })
check(StoryAudio.state().Ambience == "Hospital", "la tabla de la pista { Kind = \"hospital\" }")
StoryAudio.clear()
check(StoryAudio.state().AmbienceOverride == nil and StoryAudio.state().Ambience == StoryAudio.zoneKind(), "clear: vuelve el ambiente del sitio")

---------------------------------------------------------------------
print("\n▶ Ambiente automático (kindFor)")
---------------------------------------------------------------------
local marks = {
	{ Kind = "Colegio", Position = V3.new(1000, 0, 0) },
	{ Kind = "Hospital", Position = V3.new(0, 0, 1000) },
	{ Kind = "Facultad", Position = V3.new(-1000, 0, 0) },
	{ Kind = "Parque", Position = V3.new(0, 0, -1000) },
}
local cases = {
	{ "en el metro", { Position = V3.new(0, -30, 0), Underground = true }, "Metro" },
	{ "en la calle", { Position = V3.new(300, 0, 300) }, "Calle" },
	{ "en tu casa", { Position = V3.new(300, 0, 300), AtHome = true }, "Casa" },
	{ "en un piso", { Interior = "Piso", Door = V3.new(300, 0, 300) }, "Casa" },
	{ "en una oficina", { Interior = "Oficina", Door = V3.new(300, 0, 300) }, "Oficina" },
	{ "en un aula junto al colegio", { Interior = "Aula", Door = V3.new(1030, 0, 20) }, "Colegio" },
	{ "en un aula de la facultad", { Interior = "Aula", Door = V3.new(-1060, 0, 30) }, "Universidad" },
	{ "en un aula lejos de todo", { Interior = "Aula", Door = V3.new(300, 0, 300) }, "Universidad" },
	{ "en el pasillo del hospital", { Interior = "Portal", Door = V3.new(20, 0, 1010) }, "Hospital" },
	{ "en una tienda junto al hospital", { Interior = "Local", Door = V3.new(20, 0, 1010) }, "Tienda" },
	{ "en una sala rara", { Interior = "Nada", Door = V3.new(300, 0, 300) }, "Interior" },
	{ "en el museo", { Interior = "Museo" }, "Sala" },
	{ "dentro del hospital (techo)", { Position = V3.new(10, 5, 1010), Roof = true }, "Hospital" },
	{ "en la acera del hospital", { Position = V3.new(10, 0, 1050) }, "Calle" },
	{ "en el patio del colegio", { Position = V3.new(1040, 0, 0) }, "Colegio" },
	{ "en el campus", { Position = V3.new(-1100, 0, 0) }, "Universidad" },
	{ "en el parque", { Position = V3.new(0, 0, -1030) }, "Parque" },
	{ "sin personaje", {}, "Calle" },
}
for _, case in cases do
	local got = StoryAudio.kindFor(case[2], marks)
	check(got == case[3], ("%s: %s (sale %s)"):format(case[1], case[3], tostring(got)))
end

---------------------------------------------------------------------
print("\n▶ IDs de audio bien formados (SoundIds y Config.Audio)")
---------------------------------------------------------------------
-- (el SoundIds de verdad, no la copia recortada de arriba)
local realIds = L.load("src/shared/SoundIds")
local function wellFormedNumber(id: any): boolean
	return type(id) == "number" and id == math.floor(id) and id >= 1e8 and id < 1e17
end
local badIds = {}
for name, value in realIds do
	local digits = type(value) == "string" and string.match(value, "^rbxassetid://(%d+)$")
	if not digits or #digits < 9 or #digits > 17 then
		table.insert(badIds, name .. "=" .. tostring(value))
	end
	if not fs.isFile("audio/" .. name .. ".ogg") and not fs.isFile("audio/sfx/" .. name .. ".ogg") then
		table.insert(badIds, name .. " (sin archivo en audio/)")
	end
end
check(#badIds == 0, ("SoundIds: cada id es «rbxassetid://<número>» de un archivo de audio/ (%s)"):format(table.concat(badIds, ", ")))
for group, list in { Music = AUDIO.Music, Stings = AUDIO.Stings } do
	for cue, track in list do
		check(track.Id == 0 or wellFormedNumber(track.Id), ("Config.Audio.%s.%s: Id es 0 o un número de asset (%s)"):format(group, cue, tostring(track.Id)))
	end
end
-- Cada pieza tiene algún audio subido (su Id, su copia en SoundIds) o una pieza de reserva que lo tiene
local function hasCopy(track): boolean
	return (type(track.Id) == "number" and track.Id > 0) or realIds[(string.gsub(track.File, "%.ogg$", ""))] ~= nil
end
for cue, track in AUDIO.Music do
	local seen, at, ok = {}, cue, false
	while at and not seen[at] do
		seen[at] = true
		if hasCopy(AUDIO.Music[at]) then
			ok = true
			break
		end
		at = AUDIO.Music[at].Fallback
	end
	if cue ~= "Tension" then -- (la tensión sin subir se queda solo con el ambiente, a propósito)
		check(ok, ("%s: tiene audio subido o una pieza de reserva con audio"):format(cue))
	end
end
-- La música de fondo de cada etapa tiene una reserva subida por otro camino (si su Id no carga en el
-- juego, suena la reserva en vez de nada)
for _, cue in { "Nacimiento", "TemaValmar", "VidaAdulta" } do
	local fallback = AUDIO.Music[cue].Fallback
	local backup = fallback and AUDIO.Music[fallback]
	check(backup ~= nil and realIds[(string.gsub(backup.File, "%.ogg$", ""))] ~= nil,
		("%s: su reserva (%s) está en SoundIds"):format(cue, tostring(fallback)))
end

---------------------------------------------------------------------
print("\n▶ Al arrancar suena la música de fondo (Música: sí, sin esperar a ningún capítulo)")
---------------------------------------------------------------------
-- Un StoryAudio nuevo (como al entrar al juego), con un jugador que tiene PlayerGui y señales
uploaded.descubrimiento = true
uploaded.intima = true
uploaded.resolucion = true
player.WaitForChild = function()
	return {}
end
player.GetAttributeChangedSignal = function()
	return signal()
end
player.CharacterAdded = signal()
player.Attributes.LifeStage = "Adulto"
local before = #sounds
local Boot = loadStoryAudio()
check(Boot.isMusicOn(), "Música: sí por defecto")
Boot.init()
task.wait((AUDIO.BootDelay or 2) + 2.5)
local bootMusic = nil
for i = before + 1, #sounds do
	local s = sounds[i]
	if not s.Destroyed and string.sub(s.Name, 1, 6) == "Music_" then
		bootMusic = s
	end
end
check(bootMusic ~= nil, ("a los %s s de arrancar ya suena música (sin capítulo: la de tu etapa)"):format(tostring(AUDIO.BootDelay or 2)))
if bootMusic then
	check(bootMusic.Name == "Music_VidaAdulta", ("de adulto suena VidaAdulta (suena %s)"):format(bootMusic.Name))
	check(bootMusic.Playing, "la pieza se ha mandado tocar (Play)")
	check(bootMusic.Looped, "la música de fondo se repite")
	check(string.match(bootMusic.SoundId, "^rbxassetid://%d+$") ~= nil, ("su SoundId es rbxassetid://<número> (%s)"):format(bootMusic.SoundId))
	check(bootMusic.Volume >= 0.25, ("se oye (volumen %.2f, antes 0,2: casi nada en el móvil)"):format(bootMusic.Volume))
	check(bootMusic.SoundGroup and bootMusic.SoundGroup.Name == "Music", "va en el grupo Music (lo calla «Música: no»)")
	check(bootMusic.Parent ~= nil, "está colgada de SoundService (se oye en todo el mapa)")
end
check(Boot.state().Ambience ~= nil and #Boot.state().Layers > 0, "y el ambiente también suena desde el principio")

---------------------------------------------------------------------
print("\n▶ Si un audio no carga (privado, de otro dueño, en revisión), suena la reserva")
---------------------------------------------------------------------
-- ContentProvider dice que el Id de Config de VidaAdulta y el de AmbCalle no se pueden descargar
local failing = {
	["rbxassetid://" .. string.format("%d", AUDIO.Music.VidaAdulta.Id)] = true,
}
uploaded.amb_calle = true
local calleId = SoundFx.id("AmbCalle") :: string
failing[calleId] = true
L.services.ContentProvider = {
	PreloadAsync = function(_, list, callback)
		for _, item in list do
			-- (StoryAudio le pasa el Sound, no el id en texto: con el texto Roblox dice Failure siempre)
			assert(typeof(item) ~= "string", "PreloadAsync con el id en texto: Roblox dice Failure con todos los audios")
			local id = if type(item) == "table" or typeof(item) == "Instance" then item.SoundId else item
			callback(id, if failing[id] then "Enum.AssetFetchStatus.Failure" else "Enum.AssetFetchStatus.Success")
		end
	end,
}
local Fail = loadStoryAudio()
local mark = #sounds
Fail.setAmbient("VidaAdulta")
task.wait(1.5)
local live = {}
for i = mark + 1, #sounds do
	local s = sounds[i]
	if not s.Destroyed and string.sub(s.Name, 1, 6) == "Music_" then
		table.insert(live, s)
	end
end
check(#live == 1, ("queda una sola pieza sonando (hay %d)"):format(#live))
if live[1] then
	check(not failing[live[1].SoundId], ("ya no es el audio que no carga (%s)"):format(live[1].SoundId))
	check(live[1].Name == "Music_Descubrimiento", ("suena la reserva de VidaAdulta: Descubrimiento (suena %s)"):format(live[1].Name))
end
check(Fail.state().Music == "Descubrimiento", "StoryAudio.state() dice que suena la reserva")
-- Se vuelve a pedir: no se reintenta el audio roto
Fail.setAmbient("TemaValmar")
Fail.setAmbient("VidaAdulta")
task.wait(0.3)
check(Fail.state().Music == "Descubrimiento", "al volver a pedir VidaAdulta va directa a la reserva")
-- El ambiente de la calle: si su audio no carga, la capa pasa a la opción siguiente (el murmullo)
Fail.setAmbience("Calle")
task.wait(0.5)
local layerNames = table.concat(Fail.state().Layers, ",")
check(string.find(layerNames, "Multitud", 1, true) ~= nil and string.find(layerNames, "AmbCalle", 1, true) == nil,
	("la calle suena con el murmullo si AmbCalle no carga (capas: %s)"):format(layerNames))
L.finish("test-storyaudio")
require("@lune/process").exit(0) -- (el bucle del ambiente de init no acaba solo)
