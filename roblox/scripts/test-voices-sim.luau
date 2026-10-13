-- Prueba: una conversación entera de Cosme con las voces, con tiempos de verdad (reloj simulado).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-voices-sim.luau
--
-- Para la queja «de Cosme solo se oye hasta que dice su nombre; después habla pero no se oye» (v108).
-- Simula, con un reloj de mentira (segundos simulados, la prueba tarda menos de un segundo):
--   * Roblox: cada voz tarda 2 s en generarse (LoadAsync) y el límite de verdad: 1 + 6 × jugadores
--     frases nuevas por minuto (solo: 7). Si se pasa, LoadAsync devuelve Failure (como en el juego).
--   * DialogueUI: llega la tanda de 12 frases (prefetchDialogue), cada frase se dice (StoryAudio.speak,
--     que corta la anterior), la caja espera a la voz como mucho 0,6 s (waitVoice) y el jugador lee.
--   * La calle: un NPC dice algo cerca cada pocos segundos durante la conversación (SoundFx.voice con
--     Kind = "Street") y un bocadillo de NPC (Kind = "Street").
-- Comprueba:
--   1. Jugador que escucha (pasa de frase al acabar de leer y de oír): las 12 frases suenan, en orden,
--      cada una con su texto, y Roblox nunca falla (nunca se pasa del límite).
--   2. Jugador que lee rápido: lo que suena va en orden; ninguna frase se tira sin más: o suena, o se
--      quedó esperando turno (límite) y el jugador ya había pasado a otra; el aviso del límite sale una
--      sola vez; la calle no gasta ni una voz durante la conversación; el adelanto nunca va más de 2
--      frases por delante y no se piden frases que luego no tocan.
--   3. Una voz que llega tarde suena igual si su frase sigue en pantalla.
--   4. Un fallo suelto de Roblox no deja muda la conversación: se vuelve a probar la misma frase.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local check = L.check

---------------------------------------------------------------------
-- Reloj simulado (corrutinas): task.wait / spawn / delay / defer de mentira
---------------------------------------------------------------------
local Sched = { now = 0, timers = {} :: { any }, seq = 0 }
local function push(t: number, co: thread, ...)
	Sched.seq += 1
	table.insert(Sched.timers, { T = t, Seq = Sched.seq, Co = co, Args = table.pack(...) })
end
local function resume(co: thread, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		error(debug.traceback(co, tostring(err)))
	end
end
local fakeTask = {}
function fakeTask.spawn(fn: any, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	resume(co, ...)
	return co
end
function fakeTask.defer(fn: any, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	push(Sched.now, co, ...)
	return co
end
function fakeTask.delay(seconds: number?, fn: any, ...)
	local co = if type(fn) == "thread" then fn else coroutine.create(fn)
	push(Sched.now + math.max(seconds or 0, 0), co, ...)
	return co
end
function fakeTask.wait(seconds: number?): number
	local co = coroutine.running()
	local t0 = Sched.now
	push(Sched.now + math.max(seconds or 0, 1 / 60), co)
	coroutine.yield()
	return Sched.now - t0
end
function fakeTask.cancel() end
function Sched.run(untilT: number)
	while true do
		local best, bi = nil, nil
		for i, t in Sched.timers do
			if not best or t.T < best.T or (t.T == best.T and t.Seq < best.Seq) then
				best, bi = t, i
			end
		end
		if not best or best.T > untilT then
			break
		end
		table.remove(Sched.timers, bi)
		Sched.now = math.max(Sched.now, best.T)
		resume(best.Co, table.unpack(best.Args, 1, best.Args.n))
	end
	Sched.now = math.max(Sched.now, untilT)
end
local fakeOs = setmetatable({
	clock = function()
		return Sched.now
	end,
}, { __index = os })

L.task = fakeTask

---------------------------------------------------------------------
-- Roblox de mentira: AudioTextToSpeech que tarda GEN s y el límite por minuto de verdad
---------------------------------------------------------------------
local GEN = 2
local PLAYERS = 1
local robloxRequests: { number } = {}
local robloxFailures = 0
local failNext = 0 -- (fallos sueltos a propósito)
local played: { { Text: string, At: number } } = {}

local function signal()
	return {
		Connect = function()
			return { Disconnect = function() end }
		end,
		Once = function()
			return { Disconnect = function() end }
		end,
	}
end
local function instance(class: string, extra: { [string]: any }?)
	local obj: { [string]: any } = { ClassName = class, Name = class, Parent = nil }
	function obj:Destroy()
		self.Parent = nil
		self.Destroyed = true
	end
	function obj:IsA(c)
		return c == class
	end
	for k, v in extra or {} do
		obj[k] = v
	end
	return obj
end
for _, class in { "Folder", "AudioDeviceOutput", "Wire", "AudioFader", "AudioLimiter", "AudioListener", "AudioEmitter" } do
	L.fakeClasses[class] = function()
		local o = instance(class)
		function o:SetDistanceAttenuation() end
		return o
	end
end
L.fakeClasses.AudioTextToSpeech = function()
	local t = instance("AudioTextToSpeech", { Text = "", VoiceId = "", Pitch = 0, Speed = 1, Volume = 1, IsLoaded = false, TimeLength = 0, TimePosition = 0, Ended = signal() })
	function t:LoadAsync()
		-- El límite de Roblox: 1 + 6 × jugadores por minuto (ventana de 60 s)
		local cutoff = Sched.now - 60
		local recent = 0
		for _, at in robloxRequests do
			if at > cutoff then
				recent += 1
			end
		end
		table.insert(robloxRequests, Sched.now)
		fakeTask.wait(GEN)
		if recent >= 1 + 6 * PLAYERS or failNext > 0 then
			failNext = math.max(0, failNext - 1)
			robloxFailures += 1
			return (roblox.Enum :: any).AssetFetchStatus.Failure
		end
		self.IsLoaded = true
		self.TimeLength = #self.Text * 0.06
		return (roblox.Enum :: any).AssetFetchStatus.Success
	end
	function t:Play()
		table.insert(played, { Text = self.Text, At = Sched.now })
	end
	function t:Pause() end
	return t
end

---------------------------------------------------------------------
-- Dobles de servicios y módulos
---------------------------------------------------------------------
local player = L.player("Ana", 1)
player.Attributes.FamilyKey = "NPC.MAMA"
player.Attributes.LifeStage = "Nino"
L.services.Players = {
	LocalPlayer = player,
	GetPlayers = function()
		local list = {}
		for i = 1, PLAYERS do
			list[i] = i
		end
		return list
	end,
}
L.services.SoundService = {
	FindFirstChild = function()
		return nil
	end,
}
L.services.TweenService = {
	Create = function()
		return { Play = function() end }
	end,
}
L.services.Lighting = { ClockTime = 12 }
L.workspace = { CurrentCamera = { Name = "Camera", CFrame = roblox.CFrame.new() } } :: any

local Config = L.load("src/shared/Config")
L.mock("src/client/Controllers/SoundFx", {
	group = function(name)
		return { Name = name }
	end,
	setGroupOn = function() end,
	voiceDuck = function() end,
	uploaded = function()
		return nil
	end,
	id = function()
		return nil
	end,
	ambient = function()
		return nil
	end,
})
L.mock("src/client/UI/Theme", { create = function() end })
L.mock("src/shared/LifeStory/Strings", {
	get = function(key)
		return key
	end,
})
local Speech = L.load("src/client/Controllers/Speech")
Speech._clock = function()
	return Sched.now
end
local warnings: { string } = {}
local function loadStoryAudio()
	local path = "src/client/Controllers/StoryAudio"
	local nodeMeta = getmetatable(L.services.ReplicatedStorage.Shared)
	local env = setmetatable({
		script = setmetatable({ __path = path }, nodeMeta),
		require = function(target)
			return L.load(rawget(target, "__path"))
		end,
		game = L.game,
		workspace = L.workspace,
		task = fakeTask,
		os = fakeOs,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = L.CFrame,
		Enum = roblox.Enum,
		Instance = L.Instance,
		TweenInfo = { new = function() return {} end },
		typeof = roblox.typeof or typeof,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, { __index = _G })
	return luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
end
local StoryAudio = loadStoryAudio()

---------------------------------------------------------------------
-- La conversación: 12 frases de Cosme
---------------------------------------------------------------------
local LINES = {
	"¡Criatura! Pasa, pasa, que no muerdo. Soy Cosme, tu vecino del garaje.",
	"Esto que ves es mi taller. Bueno, mi taller, mi cocina y mi dormitorio.",
	"¿Ves ese cacharro? Es un transmisor de dimensiones. Casi funciona.",
	"Casi, criatura, casi. La última vez solo explotó un poquito.",
	"La ciencia aburrida dice que no se puede. A mí la ciencia aburrida me da igual.",
	"Necesito una mano pequeña y valiente para apretar un tornillo.",
	"No, no te voy a meter dentro de la máquina. Esta vez no.",
	"Pip, trae la llave inglesa. La buena, no la que muerde.",
	"¿Lo oyes? Ese zumbido es el sonido del futuro. O de la nevera.",
	"Si esto sale bien, mañana desayunamos en otra dimensión.",
	"Y si sale mal, también, pero sin desayuno.",
	"Venga, criatura, aprieta. Despacito… ¡Eso es! ¡Genio!",
}
local function lineSet()
	local list = {}
	for _, text in LINES do
		table.insert(list, { Voice = "Cosme", Text = text })
	end
	return list
end

-- Un trozo de calle: un NPC habla cerca cada 6 s (si le dejan, gasta voces)
local streetTries, streetPlayed = 0, 0
local streetSerial = 0
local function streetNoise(untilT: number)
	streetSerial += 1
	local mine = streetSerial
	fakeTask.spawn(function()
		while Sched.now < untilT and mine == streetSerial do
			fakeTask.wait(6)
			streetTries += 1
			local h = Speech.say("¡Hola, vecino! Qué buen día. " .. streetTries, Speech.voiceFor("Hombre"), { Kind = "Street" })
			if h then
				streetPlayed += 1
				h.Stop()
			end
		end
	end)
end

-- El jugador: lee a velocidad normal (1 s + 15 letras por segundo); si `listens`, espera además a que
-- acabe la voz que está sonando antes de pasar. Devuelve cuándo empezó cada frase.
local function conversation(listens: boolean): { number }
	local starts = {}
	local done = false
	player.Attributes.InDialogue = true
	fakeTask.spawn(function()
		local lines = lineSet()
		StoryAudio.prefetchDialogue(lines)
		fakeTask.wait(1.5) -- (plano de situación antes de la primera frase)
		for i, line in lines do
			starts[i] = Sched.now
			StoryAudio.speak(line.Voice, line.Text)
			StoryAudio.waitVoice()
			fakeTask.wait(1 + #line.Text / 15)
			if listens then
				local t0 = Sched.now
				while (not StoryAudio.isVoiceDone()) and Sched.now - t0 < 90 do
					fakeTask.wait(0.1)
				end
			end
		end
		StoryAudio.stopVoice()
		done = true
		player.Attributes.InDialogue = nil
	end)
	local guard = 0
	while not done and guard < 4000 do
		Sched.run(Sched.now + 0.5)
		guard += 1
	end
	return starts
end

-- Empezar de cero: el motor de voces y la memoria de Roblox (pasado el minuto), sin calle
local function fresh()
	streetSerial += 1
	Sched.run(Sched.now + 120)
	Speech._reset()
	Speech._clock = function()
		return Sched.now
	end
	table.clear(robloxRequests)
	table.clear(played)
	table.clear(L.warnings)
	robloxFailures = 0
	streetTries, streetPlayed = 0, 0
end

local function order(list: { { Text: string, At: number } }): (boolean, { number })
	local idx = {}
	for _, p in list do
		local found = table.find(LINES, p.Text)
		if found then
			table.insert(idx, found)
		end
	end
	for i = 2, #idx do
		if idx[i] <= idx[i - 1] then
			return false, idx
		end
	end
	return true, idx
end

---------------------------------------------------------------------
print("▶ 1. Jugador que escucha cada frase (12 frases de Cosme, 2 s por voz, límite real: 7/min solo)")
fresh()
streetNoise(Sched.now + 200)
local t0 = Sched.now
local starts = conversation(true)
local inOrder, idx = order(played)
check(#played == 12, ("las 12 frases suenan (%d)"):format(#played))
check(inOrder, "en orden: " .. table.concat(idx, " "))
check(robloxFailures == 0, ("Roblox nunca falla: nunca se pasa del límite (%d fallos)"):format(robloxFailures))
check(streetPlayed == 0, ("la calle no gasta voces durante la conversación (%d de %d intentos)"):format(streetPlayed, streetTries))
local maxLate = 0
for i, p in played do
	local line = table.find(LINES, p.Text)
	if line and starts[line] then
		maxLate = math.max(maxLate, p.At - starts[line])
	end
end
print(("   (la conversación duró %.0f s simulados; la voz más tardía empezó %.1f s después de su frase)"):format(Sched.now - t0, maxLate))
local st = Speech.state().Stats
check(st.Requested <= 12 + 1, ("no se piden frases de más (%d peticiones para 12 frases)"):format(st.Requested))

---------------------------------------------------------------------
print("\n▶ 2. Jugador que lee rápido (no espera a la voz)")
fresh()
streetNoise(Sched.now + 200)
StoryAudio.prefetchDialogue({}) -- (otra conversación)
local fastStarts = conversation(false)
local ok2, idx2 = order(played)
st = Speech.state().Stats
check(ok2, "lo que suena va en orden: " .. table.concat(idx2, " "))
check(#played >= 1 + 6 * PLAYERS - 1, ("con el límite de 7 por minuto, suenan al menos 6 (%d de 12)"):format(#played))
-- Cada frase que no sonó: estaba esperando turno (límite) y el jugador ya había pasado a otra
local silent = 12 - #played
check(st.Cancelled >= silent and st.Skipped == 0, ("ninguna se tira sin más: %d sin voz, todas esperaban turno cuando pasaste (canceladas %d)"):format(silent, st.Cancelled))
check(robloxFailures == 0, ("Roblox nunca falla (se espera turno antes de pedir): %d fallos"):format(robloxFailures))
local throttleWarnings = 0
for _, w in L.warnings do
	if string.find(w, "Límite de voces", 1, true) then
		throttleWarnings += 1
	end
end
check(silent == 0 or throttleWarnings == 1, ("el aviso del límite sale una vez por partida (%d)"):format(throttleWarnings))
check(streetPlayed == 0, "la calle sigue callada durante la conversación")
check(st.Prefetched <= #played + 2, ("el adelanto no pide frases que luego no tocan (%d adelantadas, %d sonaron)"):format(st.Prefetched, #played))
print(("   (%d de 12 con voz; la conversación duró %.0f s)"):format(#played, Sched.now - (fastStarts[1] or Sched.now)))

---------------------------------------------------------------------
print("\n▶ 3. Una voz que llega tarde suena igual si su frase sigue en pantalla")
fresh()
GEN = 3.5 -- (más de 1,5 s: antes se tiraba)
local doneLate = false
fakeTask.spawn(function()
	StoryAudio.speak("Cosme", "Esta frase tarda tres segundos y medio en generarse.")
	fakeTask.wait(8) -- (sigue en pantalla)
	doneLate = true
end)
while not doneLate do
	Sched.run(Sched.now + 0.5)
end
check(#played == 1, "suena aunque haya tardado 3,5 s (la frase seguía en pantalla)")
table.clear(played)
local doneSkip = false
fakeTask.spawn(function()
	StoryAudio.speak("Cosme", "Esta otra tarda mucho y el jugador pasa enseguida.")
	fakeTask.wait(1)
	StoryAudio.stopVoice() -- (toca para seguir)
	fakeTask.wait(6)
	doneSkip = true
end)
while not doneSkip do
	Sched.run(Sched.now + 0.5)
end
check(#played == 0, "si ya se pasó a otra frase, esa ya no suena (no se desfasa)")
local sceneDone = false
table.clear(played)
fakeTask.spawn(function()
	StoryAudio.speak("Cosme", "Subtítulo de una escena que dura dos segundos.", nil, { Seconds = 2 })
	fakeTask.wait(8)
	sceneDone = true
end)
while not sceneDone do
	Sched.run(Sched.now + 0.5)
end
check(#played == 0, "en una escena, si el subtítulo ya se fue cuando llega la voz, no suena")
GEN = 2

---------------------------------------------------------------------
print("\n▶ 4. Un fallo suelto de Roblox no deja muda la conversación")
fresh()
failNext = 1
local doneFail = false
fakeTask.spawn(function()
	StoryAudio.speak("Cosme", "Primera frase después de un fallo de Roblox.")
	fakeTask.wait(12)
	StoryAudio.speak("Cosme", "Y la siguiente también se oye.")
	fakeTask.wait(8)
	doneFail = true
end)
while not doneFail do
	Sched.run(Sched.now + 0.5)
end
check(#played == 2, ("tras el fallo se vuelve a probar la misma frase y la siguiente suena (%d de 2)"):format(#played))

---------------------------------------------------------------------
print("\n▶ 5. Con más jugadores hay más cupo (1 + 6 × jugadores)")
PLAYERS = 3
check(Speech.perMinute() == 6, "con 3 jugadores, cada uno pide 6 por minuto")
PLAYERS = 1
check(Speech.perMinute() == 7, "solo, 7 por minuto (todo el cupo de Roblox)")

L.finish("test-voices-sim")
