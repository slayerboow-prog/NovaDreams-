-- Prueba: los volúmenes del menú Ajustes (🎵 Música, 🗣️ Voces, 🔔 Efectos, 🌳 Ambiente, de 0 a 10):
-- shared/AudioSettings, Controllers/AudioMix, SoundFx (grupos, 3D), Services/SettingsService (se guardan).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-audiomix.luau
--
-- Comprueba:
--   * La curva 0..10 -> ganancia ((v/10)^2): 0 = nada, 10 = como antes, siempre sube, pasos parecidos.
--   * Los − / + no salen de 0 … 10 (también con valores raros).
--   * Cada sonido va a su control: Config.Sounds (Bus), los bucles del ambiente (Weather, GameSfx, metro,
--     StoryAudio), la grieta (Efectos, no Ambiente) y ningún Sound del código se queda sin grupo.
--   * Proximidad: cada sonido World de Config.Sounds va en 3D con su curva (InverseTapered, Min < Max) y
--     los disparos se oyen lejos; todo Sound con alcance lleva su modo de caída.
--   * Con los niveles por defecto, un motor cerca, un disparo o la grieta (etapas 5-7) se oyen claramente
--     por encima de la ciudad, los pájaros, los grillos, las olas, el viento o la lluvia.
--   * AudioMix: aplica los de por defecto, lo guardado al llegar, el agache de la música encima del
--     nivel elegido, y manda guardar (una vez) lo que cambias.
--   * SettingsService: guarda en data.Audio, valida (enteros 0 … 10, solo las cuatro claves), limita la
--     frecuencia y al volver a entrar los devuelve (ida y vuelta) y una vida nueva los conserva.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local check = L.check
local Config = L.load("src/shared/Config")
local SOUNDS = Config.Sounds
local AudioSettings = L.load("src/shared/AudioSettings")

---------------------------------------------------------------------
-- Dobles (como en test-sfx)
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Once = function(_, fn)
			table.insert(handlers, fn)
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
	}
end

L.fakeClasses.Sound = function()
	local s = {
		ClassName = "Sound",
		SoundId = "",
		Volume = 0.5,
		PlaybackSpeed = 1,
		Looped = false,
		Playing = false,
		Destroyed = false,
		RollOffMode = nil,
		RollOffMinDistance = 10,
		RollOffMaxDistance = 10000,
		Ended = signal(),
		Destroying = signal(),
	}
	function s:Play()
		self.Playing = true
	end
	function s:Stop()
		self.Playing = false
	end
	function s:IsA(c)
		return c == "Sound"
	end
	function s:Destroy()
		if not self.Destroyed then
			self.Destroyed = true
			self.Parent = nil
			self.Destroying:Fire()
		end
	end
	return s
end
L.fakeClasses.Attachment = function()
	local a = { ClassName = "Attachment", WorldPosition = nil, Parent = nil, Destroyed = false }
	function a:IsA(c)
		return c == "Attachment"
	end
	function a:Destroy()
		self.Destroyed = true
		self.Parent = nil
	end
	return a
end
L.workspace = { Terrain = { Name = "Terrain" }, DescendantAdded = signal(), GetDescendants = function()
	return {}
end }

local function newPlayer(name: string)
	local p = { Name = name, Attributes = {}, signals = {}, Character = nil, CharacterAdded = signal() }
	function p:GetAttribute(k)
		return self.Attributes[k]
	end
	function p:SetAttribute(k, v)
		if self.Attributes[k] == v then
			return
		end
		self.Attributes[k] = v
		if self.signals[k] then
			self.signals[k]:Fire()
		end
	end
	function p:GetAttributeChangedSignal(k)
		self.signals[k] = self.signals[k] or signal()
		return self.signals[k]
	end
	return p
end

local localPlayer = newPlayer("Cliente")
local soundService = roblox.Instance.new("Folder")
soundService.Name = "SoundService"
L.services.SoundService = soundService
L.services.Players = { LocalPlayer = localPlayer, PlayerRemoving = signal() }
L.services.ContextActionService = { BindAction = function() end, UnbindAction = function() end }
L.services.Lighting = { ClockTime = 12 }
L.services.RunService.Heartbeat = signal()

-- Remotos: el cliente manda (FireServer) y el servidor escucha (OnServerEvent)
local fired = {}
local audioRemote = {
	Name = "AudioVolume",
	OnServerEvent = signal(),
	IsA = function(_, c)
		return c == "RemoteEvent"
	end,
	FireServer = function(_, ...)
		table.insert(fired, table.pack(...))
	end,
}
local graphicsRemote = { Name = "GraphicsChoice", OnServerEvent = signal() }
local shooterRemote = { Name = "ShooterPrefs", OnServerEvent = signal() } -- (SettingsService también lo escucha)
L.services.ReplicatedStorage.Remotes = {
	FindFirstChild = function(_, n)
		return if n == "AudioVolume" then audioRemote elseif n == "GraphicsChoice" then graphicsRemote elseif n == "ShooterPrefs" then shooterRemote else nil
	end,
}
local realShared = L.services.ReplicatedStorage.Shared
L.services.ReplicatedStorage.Shared = setmetatable({ __path = "src/shared" }, {
	__index = function(_, key)
		if key == "FindFirstChild" then
			return function(_, name)
				if fs.isFile("src/shared/" .. name .. ".luau") then
					return { __path = "src/shared/" .. name, IsA = function(_, c)
						return c == "ModuleScript"
					end }
				end
				return nil
			end
		end
		return realShared[key]
	end,
})
L.mock("src/client/UI/TouchLayout", { register = function() end, riding = function()
	return false
end })
L.mock("src/client/UI/SpeechBubbles", { show = function() end, onSpoken = function() end })

local SFX_PATH = "src/client/Controllers/SoundFx"
local function freshSoundFx()
	L.reset(SFX_PATH)
	return L.load(SFX_PATH)
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

---------------------------------------------------------------------
print("\n📈 Curva 0..10 -> ganancia")
---------------------------------------------------------------------
check(AudioSettings.gain(0) == 0, "0 = apagado (ganancia 0)")
check(AudioSettings.gain(10) == 1, "10 = como antes (ganancia 1)")
check(near(AudioSettings.gain(5), 0.25) and near(AudioSettings.gain(7), 0.49), "curva perceptiva (v/10)^2: 5 -> 0.25, 7 -> 0.49")
local rising, prev = true, -1
for v = 0, 10 do
	local g = AudioSettings.gain(v)
	if g <= prev or g < 0 or g > 1 then
		rising = false
	end
	prev = g
end
check(rising, "cada paso sube (de 0 a 1, sin saltos hacia atrás)")
-- Pasos parecidos al oído: con una recta, del 10 al 9 solo baja 0,9 dB (no se nota) y del 2 al 1, 6 dB;
-- con la curva, del 10 al 9 ya baja 1,8 dB y ningún paso del 2 al 10 pasa de 7 dB. El 1 es muy
-- bajito (-40 dB) pero no apagado.
local even = true
for v = 3, 10 do
	local step = AudioSettings.decibels(v) - AudioSettings.decibels(v - 1)
	if step < 1.8 or step > 7.1 then
		even = false
	end
end
check(even and near(AudioSettings.decibels(1), -40), "pasos de 1,8 a 7 dB entre 2 y 10; el 1 a -40 dB (muy bajito, no apagado)")
local d = AudioSettings.Defaults
check(d.Music == 6 and d.Voice == 9 and d.Sfx == 8 and d.Ambience == 5, "por defecto: Música 6, Voces 9, Efectos 8, Ambiente 5")
check(d.Voice > d.Music and d.Sfx > d.Ambience, "las voces por encima de la música y los efectos por encima del ambiente")

---------------------------------------------------------------------
print("\n➖➕ Los − / + no salen de 0 … 10")
---------------------------------------------------------------------
check(AudioSettings.step(10, 1) == 10 and AudioSettings.step(0, -1) == 0, "+ en 10 se queda en 10; − en 0 se queda en 0")
check(AudioSettings.step(5, 1) == 6 and AudioSettings.step(5, -1) == 4, "un paso cada vez")
check(AudioSettings.clamp(-3) == 0 and AudioSettings.clamp(15) == 10 and AudioSettings.clamp(6.6) == 7, "lo que se sale se recorta (-3 -> 0, 15 -> 10, 6,6 -> 7)")
check(AudioSettings.clamp(0 / 0, "Music") == 6 and AudioSettings.clamp("x", "Voice") == 9, "lo que no es número: el de por defecto")
local v = 7
for _ = 1, 30 do
	v = AudioSettings.step(v, 1)
end
local w = 3
for _ = 1, 30 do
	w = AudioSettings.step(w, -1)
end
check(v == 10 and w == 0, "treinta + seguidos: 10; treinta −: 0")
check(AudioSettings.label("Music", 7) == "🎵 Música: 7" and AudioSettings.label("Ambience", 0) == "🌳 Ambiente: 0", "texto del menú: «🎵 Música: 7»")
local SettingsRows = L.load("src/client/Commands/SettingsRows")
local rows, _, kinds = SettingsRows.build({
	{ Text = AudioSettings.label("Music", 6), Order = 1, Press = function()
		return ""
	end },
	{ Text = AudioSettings.label("Voice", 9), Order = 1.5, Press = function()
		return ""
	end },
	{ Text = AudioSettings.label("Sfx", 8), Order = 2, Press = function()
		return ""
	end },
	{ Text = AudioSettings.label("Ambience", 5), Order = 2.1, Press = function()
		return ""
	end },
}, "Auto")
local okRows = #rows == 4
for i, row in rows do
	if kinds[i] ~= "Stepper" or not row.Stepper or row.Stepper.Min ~= 0 or row.Stepper.Max ~= 10 or row.Section ~= "Sonido" then
		okRows = false
	end
end
check(okRows and rows[1].Stepper.Value == 6 and rows[4].Stepper.Value == 5, "en Ajustes (Sonido): las cuatro filas con − / + de 0 a 10")
local phoneSrc = fs.readFile("src/client/UI/Phone.luau")
check(phoneSrc:find("local STEP_SIZE = 44", 1, true) ~= nil, "botones − / + de 44 px en el ValPhone (dedo)")

---------------------------------------------------------------------
print("\n🧭 Cada sonido va a su control")
---------------------------------------------------------------------
local AMBIENT = { "AmbSala", "AmbCasa", "AmbColegio", "AmbUniversidad", "AmbHospital", "AmbCalle", "AmbAire", "Reloj", "Monitor", "Grillos", "Olas", "Multitud", "MetroAnden", "PublicoEstadio" }
local EFFECTS = {
	"Motor", "Helicoptero", "Claxon", "ClaxonPesado", "Timbre", "Derrape", "ChoqueLeve", "ChoqueFuerte", "Arranque",
	"DisparoPistola", "DisparoRevolver", "DisparoEscopeta", "DisparoSubfusil", "DisparoFusil", "DisparoFrancotirador", "EcoDisparo", "ImpactoBala",
	"Golpe", "GolpeCaida", "KO", "Clic", "Aviso", "Dinero", "SubirNivel", "FutbolChute", "BalonBote", "Puerta", "PatineteZumbido",
}
local wrongBus = {}
for _, name in AMBIENT do
	if not SOUNDS[name] or AudioSettings.busOf(SOUNDS[name]) ~= "Ambience" then
		table.insert(wrongBus, name .. "≠Ambiente")
	end
end
for _, name in EFFECTS do
	if not SOUNDS[name] or AudioSettings.busOf(SOUNDS[name]) ~= "Sfx" then
		table.insert(wrongBus, name .. "≠Efectos")
	end
end
local badBus = {}
for name, entry in SOUNDS do
	if entry.Bus ~= nil and entry.Bus ~= "Ambience" then
		table.insert(badBus, name)
	end
end
check(#wrongBus == 0, "ciudad, salas, grillos, olas… en 🌳 Ambiente; motores, claxon, disparos, golpes, interfaz… en 🔔 Efectos " .. table.concat(wrongBus, ", "))
check(#badBus == 0, "Bus solo puede ser \"Ambience\" (lo demás, Efectos) " .. table.concat(badBus, ", "))

-- De verdad: cada sonido de Config.Sounds que suena, en una pieza y suelto, en el grupo de su control
local part = roblox.Instance.new("Part")
local misrouted = {}
for name, entry in SOUNDS do
	local SoundFx = freshSoundFx()
	if SoundFx.id(name) then
		local expected = AudioSettings.Groups[AudioSettings.busOf(entry)]
		local played = SoundFx.play(name, { At = part, NoLayers = true })
		if played and (not played.SoundGroup or played.SoundGroup.Name ~= expected) then
			table.insert(misrouted, name .. " (play)")
		end
		local looped = SoundFx.loop(name, part)
		if looped and (not looped.SoundGroup or looped.SoundGroup.Name ~= expected) then
			table.insert(misrouted, name .. " (loop)")
		end
		local amb = SoundFx.ambient(name)
		if amb and amb.SoundGroup.Name ~= "Ambience" then
			table.insert(misrouted, name .. " (ambient)")
		end
	end
end
check(#misrouted == 0, "al sonar, cada uno en el grupo de su control (SFX / Ambience) " .. table.concat(misrouted, ", "))

-- Los bucles y sonidos de los controladores del ambiente y de la grieta
local function src(path: string): string
	return fs.readFile(path)
end
local weather = src("src/client/Controllers/Weather.luau")
check(weather:find('SoundFx.group("Ambience")', 1, true) and not weather:find('group("SFX")', 1, true), "Weather: lluvia, viento, pájaros y trueno en 🌳 Ambiente")
local gameSfx = src("src/client/Controllers/GameSfx.luau")
check(gameSfx:find('SoundFx.loop("Grillos", nil, "Ambience")', 1, true) and gameSfx:find('SoundFx.loop("Olas", nil, "Ambience")', 1, true), "GameSfx: grillos y olas en 🌳 Ambiente")
check(src("src/client/Controllers/MetroTrains.luau"):find('SoundFx.loop("MetroAnden", nil, "Ambience")', 1, true) ~= nil, "el andén del metro en 🌳 Ambiente")
local storyAudio = src("src/client/Controllers/StoryAudio.luau")
check(storyAudio:find('SoundFx.group("Ambience")', 1, true) and storyAudio:find('SoundFx.group("Music")', 1, true) and storyAudio:find('SoundFx.group("Voice")', 1, true), "StoryAudio: capas del ambiente en Ambiente, música en Music y voces grabadas en Voice")
local skyRift = src("src/client/Controllers/SkyRift.luau")
local riftBody = skyRift:match("local function sfxGroup%(%).-\nend")
check(riftBody and riftBody:find('group("SFX")', 1, true) and not skyRift:find('FindFirstChild("Ambience")', 1, true), "la grieta (zumbido, rugido, crepitar, trueno y rumor) en 🔔 Efectos, no en Ambiente")
check(select(2, skyRift:gsub("sfxGroup%(%)", "")) >= 3, "también los truenos y el rumor de la transición")

-- Ningún Sound del código sin grupo (o sin el atributo SfxGroup, que el cliente pasa a su grupo)
local strays = {}
local function scanDir(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scanDir(path)
		elseif name:match("%.luau$") then
			local lines = string.split(fs.readFile(path), "\n")
			for i, line in lines do
				local code = line:gsub("%-%-.*$", "")
				if code:find('Instance.new("Sound")', 1, true) or code:find('make("Sound"', 1, true) then
					local window = table.concat(lines, "\n", i, math.min(#lines, i + 24))
					if not (window:find("SoundGroup", 1, true) or window:find("SfxGroup", 1, true)) then
						table.insert(strays, path:gsub("^src/", "") .. ":" .. i)
					end
				end
			end
		end
	end
end
scanDir("src")
check(#strays == 0, "cada Sound que crea el código va a un grupo (SoundGroup o SfxGroup) " .. table.concat(strays, ", "))
-- Y los que no (de un modelo, de un personaje…): SoundFx los mete en Efectos
do
	local SoundFx = freshSoundFx()
	local tagged = L.fakeClasses.Sound()
	tagged.GetAttribute = function(_, k)
		return if k == "SfxGroup" then "Ambience" else nil
	end
	local plain = L.fakeClasses.Sound()
	plain.GetAttribute = function()
		return nil
	end
	SoundFx.tagSound(plain)
	SoundFx.tagSound(tagged)
	check(plain.SoundGroup and plain.SoundGroup.Name == "SFX", "un Sound suelto del mundo, sin grupo: a 🔔 Efectos")
	check(tagged.SoundGroup and tagged.SoundGroup.Name == "Ambience", "uno con SfxGroup = Ambience: a 🌳 Ambiente")
end

---------------------------------------------------------------------
print("\n📍 Proximidad: lo del mundo, en 3D")
---------------------------------------------------------------------
local badWorld, notWorld = {}, {}
for name, entry in SOUNDS do
	if entry.World then
		if type(entry.MinDistance) ~= "number" or type(entry.MaxDistance) ~= "number" or entry.MinDistance <= 0 or entry.MinDistance >= entry.MaxDistance then
			table.insert(badWorld, name)
		end
	end
end
for _, name in {
	"Motor", "Helicoptero", "Claxon", "ClaxonPesado", "Timbre", "Derrape", "ChoqueLeve", "ChoqueFuerte",
	"DisparoPistola", "DisparoRevolver", "DisparoEscopeta", "DisparoSubfusil", "DisparoFusil", "DisparoFrancotirador",
	"Puerta", "Nevera", "FutbolChute", "BalonBote", "AroRebote", "RaquetaGolpe", "VoleyGolpe", "MetroPuertas", "Tele", "Piano",
} do
	if not (SOUNDS[name] and SOUNDS[name].World) then
		table.insert(notWorld, name)
	end
end
check(#badWorld == 0, "cada sonido World tiene MinDistance < MaxDistance " .. table.concat(badWorld, ", "))
check(#notWorld == 0, "vehículos, armas, puertas, nevera, balones, metro, tele y piano marcados World " .. table.concat(notWorld, ", "))
local gunsFar = true
for name, entry in SOUNDS do
	if name:match("^Disparo") and name ~= "DisparoTaser" and name ~= "DisparoAgua" and name ~= "DisparoPaintball" and (entry.MaxDistance or 0) < 200 then
		gunsFar = false
	end
end
check(gunsFar and SOUNDS.Claxon.MaxDistance > SOUNDS.Motor.MaxDistance and SOUNDS.Motor.MaxDistance > SOUNDS.Tele.MaxDistance, "los disparos se oyen a 200+ studs; un claxon más lejos que un motor, y un motor más que una tele")
-- De verdad: cada World que suena en una pieza va en 3D con su curva (y en un punto suelto, también)
local flat = {}
for name, entry in SOUNDS do
	if entry.World then
		local SoundFx = freshSoundFx()
		if SoundFx.id(name) then
			local s = SoundFx.play(name, { At = part, NoLayers = true })
			if s and (s.RollOffMode ~= roblox.Enum.RollOffMode.InverseTapered or s.RollOffMinDistance ~= entry.MinDistance or s.RollOffMaxDistance ~= entry.MaxDistance or s.Parent ~= part) then
				table.insert(flat, name .. " (play)")
			end
			local loop = SoundFx.loop(name, part)
			if loop and (loop.RollOffMode ~= roblox.Enum.RollOffMode.InverseTapered or loop.RollOffMaxDistance ~= entry.MaxDistance) then
				table.insert(flat, name .. " (loop)")
			end
		end
	end
end
check(#flat == 0, "cada sonido World suena en 3D (InverseTapered) con su Min/Max " .. table.concat(flat, ", "))
do
	local SoundFx = freshSoundFx()
	local at = roblox.Vector3.new(10, 2, 30)
	local s = SoundFx.play("BalonBote", { At = at })
	check(s and s.Parent and s.Parent.ClassName == "Attachment" and s.Parent.WorldPosition == at and s.RollOffMode == roblox.Enum.RollOffMode.InverseTapered, "en un punto suelto (el balón): un Attachment ahí, en 3D")
	if s then
		local spot = s.Parent
		s.Ended:Fire()
		check(spot.Destroyed, "y el punto se quita al acabar")
	end
	local ui = SoundFx.play("Clic")
	check(ui and ui.RollOffMode == nil, "la interfaz sigue en 2D")
end
-- Todo Sound con alcance (RollOffMaxDistance) dice también cómo cae (RollOffMode o make3D)
local noMode = {}
local function scanRoll(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scanRoll(path)
		elseif name:match("%.luau$") then
			local lines = string.split(fs.readFile(path), "\n")
			for i, line in lines do
				if (line:gsub("%-%-.*$", "")):find("RollOffMaxDistance", 1, true) then
					local window = table.concat(lines, "\n", math.max(1, i - 6), math.min(#lines, i + 6))
					if not (window:find("RollOffMode", 1, true) or window:find("make3D", 1, true)) then
						table.insert(noMode, path:gsub("^src/", "") .. ":" .. i)
					end
				end
			end
		end
	end
end
scanRoll("src")
check(#noMode == 0, "cada sonido con alcance tiene su curva de caída (RollOffMode) " .. table.concat(noMode, ", "))
local sports = src("src/client/Controllers/BasketClient.luau") .. src("src/client/Controllers/VolleyClient.luau") .. src("src/client/Controllers/RacketClient.luau") .. src("src/client/Controllers/FootballClient.luau")
check(select(2, sports:gsub("At = if typeof%(", "")) >= 4, "los balones de baloncesto, voleibol, raqueta y fútbol suenan desde la pelota")

---------------------------------------------------------------------
print("\n🔊 Con los niveles por defecto: motores, disparos y la grieta por encima del ambiente")
---------------------------------------------------------------------
local sfxGain, ambGain = AudioSettings.gain(d.Sfx), AudioSettings.gain(d.Ambience)
local LEVELS = Config.Seasons.SoundLevels
local SeasonsMod = L.load("src/shared/Seasons")
local maxBirds = 1
for _, info in SeasonsMod.Info or {} do
	maxBirds = math.max(maxBirds, info.Birds or 0)
end
-- El ambiente más fuerte que puede sonar (volumen de base, ya en el sitio más ruidoso)
local beds = {
	Ciudad = SOUNDS.Multitud.Volume,
	Pajaros = LEVELS.Birds * maxBirds,
	Grillos = SOUNDS.Grillos.Volume,
	Olas = SOUNDS.Olas.Volume,
	Viento = LEVELS.Wind,
	Lluvia = LEVELS.Rain * LEVELS.RainMaxLevel,
	Estadio = SOUNDS.PublicoEstadio.Volume,
}
local loudestBed, loudestName = 0, ""
for name, base in beds do
	if base > loudestBed then
		loudestBed, loudestName = base, name
	end
end
local ambient = loudestBed * ambGain
-- Los efectos que se tienen que oír por encima (lo más flojo de cada uno)
local Rift = L.load("src/shared/SkyRift")
local engineIdle = SOUNDS.Motor.Volume * 0.7 -- (SoundFx: al ralentí 0.7 de su volumen, a tope 1.2)
local gunshot = math.huge
for _, name in { "DisparoPistola", "DisparoRevolver", "DisparoEscopeta", "DisparoSubfusil", "DisparoFusil", "DisparoFrancotirador" } do
	gunshot = math.min(gunshot, SOUNDS[name].Volume)
end
local rift5 = Rift.soundFor(5).Hum
local loud = { Motor = engineIdle * sfxGain, Disparo = gunshot * sfxGain, Grieta5 = rift5 * sfxGain, Grieta7 = Rift.soundFor(7).Hum * sfxGain }
local RATIO = 1.5 -- (+3,5 dB como poco: se nota)
for name, level in loud do
	check(level >= ambient * RATIO, ("%s (%.2f) claramente por encima del ambiente más fuerte, %s (%.2f)"):format(name, level, loudestName, ambient))
end
check(SOUNDS.Motor.Volume * 1.2 <= 1, ("el motor a tope no pasa de 1 (%.2f, sin saturar)"):format(SOUNDS.Motor.Volume * 1.2))
check(Rift.soundFor(7).Hum <= 1 and Rift.soundFor(7).Roar <= 1, "la grieta en la etapa 7, sin pasar de 1")
check(SOUNDS.Multitud.Volume <= 0.6 and LEVELS.Wind <= 0.5 and LEVELS.Birds <= 0.35, "las camas del ambiente, modestas en su volumen de base")

---------------------------------------------------------------------
print("\n🎚️ AudioMix: aplica los niveles (cliente)")
---------------------------------------------------------------------
local story = { musicOn = true, voice = nil, calls = 0 }
L.mock("src/client/Controllers/StoryAudio", {
	isMusicOn = function()
		return story.musicOn
	end,
	setMusicOn = function(on)
		story.musicOn = on
		story.calls += 1
	end,
	setVoiceVolume = function(g)
		story.voice = g
	end,
})
local SoundFx = freshSoundFx()
L.mock(SFX_PATH, SoundFx)
local AudioMix = L.load("src/client/Controllers/AudioMix")
AudioMix.init()
check(near(SoundFx.group("Music").Volume, 0.36) and near(SoundFx.group("SFX").Volume, 0.64) and near(SoundFx.group("Ambience").Volume, 0.25), "al entrar: música 6 (0.36), efectos 8 (0.64), ambiente 5 (0.25)")
check(story.voice and near(story.voice, 0.81) and story.musicOn, "voces 9 (0.81, al Speech vía StoryAudio) y la música encendida")
-- Llega lo guardado (atributos del servidor)
localPlayer:SetAttribute("VolMusic", 2)
localPlayer:SetAttribute("VolAmbience", 1)
check(AudioMix.level("Music") == 2 and near(SoundFx.group("Music").Volume, 0.04) and near(SoundFx.group("Ambience").Volume, 0.01), "lo guardado se pone en cuanto llega (música 2, ambiente 1)")
check(#fired == 0, "restaurar lo guardado no vuelve a guardar")
-- El jugador toca − / +
check(AudioMix.step("Sfx", 1) == "🔔 Efectos: 9" and near(SoundFx.group("SFX").Volume, 0.81), "+ en Efectos: 9 (0.81)")
for _ = 1, 5 do
	AudioMix.step("Sfx", 1)
end
check(AudioMix.level("Sfx") == 10, "+ no pasa de 10")
for _ = 1, 15 do
	AudioMix.step("Voice", -1)
end
check(AudioMix.level("Voice") == 0 and story.voice == 0, "− no baja de 0 (voces apagadas)")
AudioMix.step("Music", -1)
AudioMix.step("Music", -1)
check(AudioMix.level("Music") == 0 and story.musicOn == false and SoundFx.group("Music").Volume == 0, "música a 0: apagada")
AudioMix.step("Music", 1)
check(story.musicOn == true and near(SoundFx.group("Music").Volume, 0.01), "y al subirla vuelve a sonar")
localPlayer:SetAttribute("VolMusic", 9)
check(AudioMix.level("Music") == 1, "lo que llegue tarde no pisa lo que acabas de tocar")
task.wait(0.9)
local sent = {}
for _, call in fired do
	sent[call[2]] = (sent[call[2]] or 0) + 1
	check(call[1] == "Set" and AudioSettings.isLevel(call[3]), ("se manda guardar %s = %s"):format(tostring(call[2]), tostring(call[3])))
end
check(sent.Sfx == 1 and sent.Voice == 1 and sent.Music == 1 and sent.Ambience == nil, "un solo guardado por control aunque pulses muchas veces (el último valor)")
-- El agache de la música bajo las fanfarrias va encima del nivel elegido
AudioMix.set("Music", 6)
SoundFx.duck(0.5, 0.3)
task.wait(0.2)
check(near(SoundFx.group("Music").Volume, 0.18), ("con la música a 6, la fanfarria la baja a la mitad de su nivel (%.3f)"):format(SoundFx.group("Music").Volume))
task.wait(1.5)
check(near(SoundFx.group("Music").Volume, 0.36), ("y vuelve a su nivel, no a 1 (%.3f)"):format(SoundFx.group("Music").Volume))
local storySrc = src("src/client/Controllers/StoryAudio.luau")
check(storySrc:find("speaking > 0 then base * AUDIO.DuckVolume", 1, true) ~= nil, "bajo las voces la música sigue bajando (StoryAudio: en el Sound, encima del grupo)")
local mainSrc = src("src/client/Main.client.luau")
check(mainSrc:find("Hud.addMenuStepper", 1, true) and not mainSrc:find("Voces: alto", 1, true) and not mainSrc:find("Sonidos: no", 1, true) and not mainSrc:find("Música: sí", 1, true), "el menú usa los cuatro − / + (fuera alto/medio/bajo/no y sí/no)")

---------------------------------------------------------------------
print("\n💾 SettingsService: se guarda con la partida y vuelve")
---------------------------------------------------------------------
local saves = {}
local loadedFns = {}
L.mock("src/server/Services/DataService", {
	get = function(p)
		return saves[p]
	end,
	onLoaded = function(fn)
		table.insert(loadedFns, fn)
	end,
})
local Settings = L.load("src/server/Services/SettingsService")
Settings.init()
local owner = newPlayer("Dueño")
saves[owner] = { Money = 0 } -- (partida vieja, sin Audio)
for _, fn in loadedFns do
	fn(owner, saves[owner])
end
check(owner:GetAttribute("VolMusic") == 6 and owner:GetAttribute("VolVoice") == 9 and owner:GetAttribute("VolSfx") == 8 and owner:GetAttribute("VolAmbience") == 5, "partida vieja (sin Audio): los de por defecto")
audioRemote.OnServerEvent:Fire(owner, "Set", "Music", 3)
audioRemote.OnServerEvent:Fire(owner, "Set", "Ambience", 2)
check(saves[owner].Audio.Music == 3 and saves[owner].Audio.Ambience == 2 and owner:GetAttribute("VolMusic") == 3, "bajar la música a 3 y el ambiente a 2 se guarda en data.Audio")
for _, bad in { { "Music", 11 }, { "Music", -1 }, { "Music", 2.5 }, { "Music", 0 / 0 }, { "Music", "5" }, { "Volumen", 4 }, { "Music", math.huge }, { { "Music" }, 4 } } do
	audioRemote.OnServerEvent:Fire(owner, "Set", bad[1], bad[2])
end
audioRemote.OnServerEvent:Fire(owner, "Borrar", "Music", 1)
check(saves[owner].Audio.Music == 3 and owner:GetAttribute("VolMusic") == 3, "lo que no vale (11, -1, 2.5, NaN, texto, clave rara…) no se guarda")
local keys = 0
for key in saves[owner].Audio do
	if key ~= "TextSpeed" then
		keys += 1
	end
end
-- (y la velocidad del texto de las conversaciones, shared/LifeStory/TextSpeed: va con los ajustes de sonido)
check(keys == 4 and (saves[owner].Audio.TextSpeed == nil or saves[owner].Audio.TextSpeed == "Normal"), "data.Audio solo tiene las cuatro claves (y la velocidad del texto)")
-- Límite: cien seguidos de golpe -> solo unos pocos pasan
local spammer = newPlayer("Prisas")
saves[spammer] = {}
for _, fn in loadedFns do
	fn(spammer, saves[spammer])
end
local accepted = 0
for i = 1, 100 do
	local before = spammer:GetAttribute("VolSfx")
	audioRemote.OnServerEvent:Fire(spammer, "Set", "Sfx", i % 2 * 10)
	if spammer:GetAttribute("VolSfx") ~= before then
		accepted += 1
	end
end
check(accepted <= 9, ("cien cambios de golpe: solo pasan unos pocos (%d)"):format(accepted))
task.wait(0.6)
audioRemote.OnServerEvent:Fire(spammer, "Set", "Voice", 4)
check(spammer:GetAttribute("VolVoice") == 4, "y al poco vuelve a dejar")
-- Ida y vuelta: otro servidor carga lo guardado
local again = newPlayer("Dueño")
saves[again] = { Audio = saves[owner].Audio }
for _, fn in loadedFns do
	fn(again, saves[again])
end
check(again:GetAttribute("VolMusic") == 3 and again:GetAttribute("VolAmbience") == 2 and again:GetAttribute("VolVoice") == 9, "al volver a entrar, vuelven (atributos VolMusic, VolAmbience…)")
-- Y el cliente los aplica al llegar
do
	local p2 = newPlayer("Cliente2")
	L.services.Players.LocalPlayer = p2
	L.reset("src/client/Controllers/AudioMix")
	local Fx = freshSoundFx()
	L.mock(SFX_PATH, Fx)
	local Mix = L.load("src/client/Controllers/AudioMix")
	Mix.init()
	for _, key in AudioSettings.Keys do
		p2:SetAttribute(AudioSettings.attribute(key), again:GetAttribute(AudioSettings.attribute(key)))
	end
	check(Mix.level("Music") == 3 and near(Fx.group("Music").Volume, 0.09) and near(Fx.group("Ambience").Volume, 0.04), "ida y vuelta: el cliente pone la música a 3 y el ambiente a 2")
end
-- Partida con basura en Audio: se arregla al cargar
local messy = newPlayer("Raro")
saves[messy] = { Audio = { Music = 99, Voice = "alto", Sfx = 4, Extra = 1 } }
for _, fn in loadedFns do
	fn(messy, saves[messy])
end
check(saves[messy].Audio.Music == 6 and saves[messy].Audio.Voice == 9 and saves[messy].Audio.Sfx == 4 and saves[messy].Audio.Extra == nil, "una partida con valores raros se arregla al cargar (lo que no vale, por defecto)")
local SaveCheck = L.load("src/shared/SaveCheck")
check(#SaveCheck.scan({ Audio = saves[owner].Audio }) == 0, "data.Audio se puede guardar en el DataStore")
local dataSrc = src("src/server/Services/DataService.luau")
check(dataSrc:find("Audio = { Music = 6, Voice = 9, Sfx = 8, Ambience = 5 }", 1, true) and dataSrc:find("fresh.Audio = data.Audio", 1, true), "DataService: los de por defecto (iguales que AudioSettings) y se conservan en una vida nueva")
check(fs.readFile("default.project.json"):find('"AudioVolume"', 1, true) ~= nil, "el remoto AudioVolume existe")

L.finish("test-audiomix")
