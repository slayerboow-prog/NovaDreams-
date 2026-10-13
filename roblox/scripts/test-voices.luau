-- Prueba: las voces de los personajes (shared/LifeStory/CastVoices y client/Controllers/Speech).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-voices.luau
--
-- Comprueba:
--   * Cada personaje del reparto (Cast.People) tiene su voz en CastVoices: una de las dos voces de
--     Roblox en español ("101" hombre, "102" mujer), tono en semitonos (-12 … 12) y velocidad (0,5 … 2).
--   * Cada uno suena distinto (no hay dos con la misma voz, tono y velocidad).
--   * La familia según la casa: Mamá y Abu Rosa con voz de mujer, Papá y Abu Tomás de hombre; «tú»
--     (TuFuturo, clones) según tu género; los niños más agudos que los adultos y los mayores más graves y
--     lentos; los compañeros que crecen contigo bajan la voz con tu etapa.
--   * Los perfiles de Config.Audio.Voices.Speakers y StreetVoices.Presets tienen VoiceId de verdad.
--   * speakable: sin etiquetas, sin emojis, sin *acotaciones*, 300 caracteres como mucho.
--   * Speech (con dobles de AudioTextToSpeech): pide con la voz del personaje y AutoLocalize = false,
--     2D sin posición o con AudioEmitter + AudioListener (grupo "Voces") desde la cabeza; la misma frase
--     se repite sin volver a pedirla; un fallo NO apaga las voces para siempre: espera y vuelve a probar;
--     el límite por minuto y el cupo de la calle; volumen 0 = no se pide nada; Stop corta.

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")
local check = L.check

---------------------------------------------------------------------
-- Dobles
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
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			local list = handlers
			handlers = {}
			for _, fn in list do
				fn(...)
			end
		end,
	}
end

local loadStatus = "Success" -- lo que devuelve LoadAsync en esta prueba
local created: { any } = {}
local function instance(class: string, extra: { [string]: any }?)
	local obj: { [string]: any } = { ClassName = class, Name = class, Parent = nil, Destroyed = false }
	function obj:Destroy()
		self.Destroyed = true
		self.Parent = nil
	end
	function obj:IsA(c)
		return c == class
	end
	for k, v in extra or {} do
		obj[k] = v
	end
	table.insert(created, obj)
	return obj
end
L.fakeClasses.Folder = function()
	return instance("Folder")
end
L.fakeClasses.AudioDeviceOutput = function()
	return instance("AudioDeviceOutput")
end
L.fakeClasses.Wire = function()
	return instance("Wire")
end
L.fakeClasses.AudioFader = function()
	return instance("AudioFader", { Volume = 1 })
end
L.fakeClasses.AudioLimiter = function()
	return instance("AudioLimiter", { MaxLevel = 0 })
end
L.fakeClasses.AudioListener = function()
	return instance("AudioListener", { AudioInteractionGroup = "" })
end
L.fakeClasses.AudioEmitter = function()
	local e = instance("AudioEmitter", { AudioInteractionGroup = "" })
	function e:SetDistanceAttenuation(curve)
		self.Curve = curve
	end
	return e
end
local loads = 0
local loadSeconds = 0 -- lo que «tarda» LoadAsync (adelanta el reloj de mentira)
local loadYield = 0 -- y lo que espera de verdad (para ver dos peticiones a la vez)
local clock = 1000
L.fakeClasses.AudioTextToSpeech = function()
	local t = instance("AudioTextToSpeech", {
		Text = "",
		VoiceId = "",
		Pitch = 0,
		Speed = 1,
		Volume = 1,
		AutoLocalize = true,
		IsLoaded = false,
		TimeLength = 0,
		TimePosition = 0,
		Playing = false,
		Ended = signal(),
	})
	function t:LoadAsync()
		loads += 1
		clock += loadSeconds
		if loadYield > 0 then
			task.wait(loadYield)
		end
		if loadStatus == "Success" then
			self.IsLoaded = true
			self.TimeLength = 2
		end
		return (roblox.Enum :: any).AssetFetchStatus[loadStatus]
	end
	function t:Play()
		self.Playing = true
	end
	function t:Pause()
		self.Playing = false
	end
	return t
end

local camera = { Name = "Camera", CFrame = roblox.CFrame.new(0, 5, 0) }
L.workspace = { CurrentCamera = camera } :: any
L.services.SoundService = {
	FindFirstChild = function()
		return nil
	end,
}
local player = L.player("Ana", 1)
L.services.Players = { LocalPlayer = player }

local Config = L.load("src/shared/Config")
local Cast = L.load("src/shared/LifeStory/Cast")
local CastVoices = L.load("src/shared/LifeStory/CastVoices")

local MALE, FEMALE = CastVoices.MALE, CastVoices.FEMALE
local function valid(v: any): boolean
	return type(v) == "table"
		and (v.VoiceId == MALE or v.VoiceId == FEMALE)
		and type(v.Pitch) == "number"
		and v.Pitch >= -12
		and v.Pitch <= 12
		and type(v.Speed) == "number"
		and v.Speed >= 0.5
		and v.Speed <= 2
end
local function show(v: any): string
	return ("%s %+.1f st ×%.2f"):format(v.VoiceId, v.Pitch, v.Speed)
end

---------------------------------------------------------------------
print("▶ Cada personaje del reparto tiene su voz")
local attrs = { FamilyKey = "NPC.MAMA", AbuKey = "NPC.ABU_TOMAS", Gender = "F", LifeStage = "Nino" }
local missing, bad, total = {}, {}, 0
local seen: { [string]: string } = {}
local clashes = {}
for id in Cast.People do
	total += 1
	if not CastVoices.known(id) then
		table.insert(missing, id)
	end
	local v = CastVoices.resolve(id, attrs)
	if not valid(v) then
		table.insert(bad, id)
	end
	-- (Familia y Abu cambian con la casa; los «tú» con tu género: se miran aparte)
	if id ~= "Familia" and id ~= "Abu" and CastVoices.People[id] and CastVoices.People[id].G ~= "P" then
		local key = show(v)
		if seen[key] then
			table.insert(clashes, seen[key] .. " = " .. id .. " (" .. key .. ")")
		else
			seen[key] = id
		end
	end
end
table.sort(missing)
check(#missing == 0, ("los %d personajes tienen voz propia en CastVoices.People%s"):format(total, if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
check(#bad == 0, "todas son 101/102, tono -12…12 y velocidad 0,5…2" .. (if #bad > 0 then " (mal: " .. table.concat(bad, ", ") .. ")" else ""))
check(#clashes == 0, "no hay dos personajes con la misma voz" .. (if #clashes > 0 then " (" .. table.concat(clashes, "; ") .. ")" else ""))
local extra = {}
for id in CastVoices.People do
	if not Cast.People[id] and id ~= "Chispa" then
		table.insert(extra, id)
	end
end
check(#extra == 0, "CastVoices no tiene personajes que ya no existen" .. (if #extra > 0 then " (" .. table.concat(extra, ", ") .. ")" else ""))

---------------------------------------------------------------------
print("\n▶ Hombres, mujeres, niños y mayores")
local function r(id: string, a: any?)
	return CastVoices.resolve(id, a or attrs)
end
check(r("Familia", { FamilyKey = "NPC.MAMA" }).VoiceId == FEMALE, "Mamá: voz de mujer (" .. show(r("Familia", { FamilyKey = "NPC.MAMA" })) .. ")")
check(r("Familia", { FamilyKey = "NPC.PAPA" }).VoiceId == MALE, "Papá: voz de hombre (" .. show(r("Familia", { FamilyKey = "NPC.PAPA" })) .. ")")
check(r("Abu", { AbuKey = "NPC.ABU_ROSA" }).VoiceId == FEMALE and r("Abu", { AbuKey = "NPC.ABU_ROSA" }).Speed < 1, "Abu Rosa: mujer mayor, despacio")
check(r("Abu", { AbuKey = "NPC.ABU_TOMAS" }).VoiceId == MALE and r("Abu", { AbuKey = "NPC.ABU_TOMAS" }).Pitch < 0, "Abu Tomás: hombre mayor, grave")
check(valid(r("Familia", {})) and valid(r("Abu", {})), "sin saber la casa también tienen voz")
check(r("Cosme").VoiceId == MALE and r("Cosme").Pitch < 0, "Cosme: hombre mayor (" .. show(r("Cosme")) .. ")")
check(r("Lucia").VoiceId == FEMALE and r("Ramon").VoiceId == MALE and r("Andres").VoiceId == MALE and r("Marta").VoiceId == FEMALE, "profes: Lucía y Marta mujeres, Ramón y Andrés hombres")
check(r("Sara").VoiceId == FEMALE and r("Nico").VoiceId == MALE, "Sara niña, Nico niño")
check(r("TuFuturo", { Gender = "M" }).VoiceId == MALE and r("TuFuturo", { Gender = "F" }).VoiceId == FEMALE, "«tú dentro de 10 años» según tu género")
local kidMin, adultMax, oldMax = math.huge, -math.huge, -math.huge
for id, p in Cast.People do
	local v = r(id)
	if p.Kid and not p.Glow and not p.Body and CastVoices.Grows[id] then
		kidMin = math.min(kidMin, v.Pitch)
	elseif p.Old then
		oldMax = math.max(oldMax, v.Pitch)
		check(v.Speed < 1, id .. " (mayor) habla despacio")
	elseif not p.Kid and not p.Teen and not p.Glow and not p.Body then
		adultMax = math.max(adultMax, v.Pitch)
	end
end
check(kidMin > adultMax, ("los niños son más agudos que los adultos (niños desde %+.1f, adultos hasta %+.1f)"):format(kidMin, adultMax))
check(oldMax < 0, ("los mayores, más graves (hasta %+.1f)"):format(oldMax))
local nicoKid = r("Nico", { LifeStage = "Nino" }).Pitch
local nicoTeen = r("Nico", { LifeStage = "Adolescente" }).Pitch
local nicoAdult = r("Nico", { LifeStage = "Adulto" }).Pitch
check(nicoKid > nicoTeen and nicoTeen > nicoAdult and nicoAdult <= 2, ("los compañeros crecen contigo: Nico %+.1f → %+.1f → %+.1f"):format(nicoKid, nicoTeen, nicoAdult))
local g1, g2 = CastVoices.resolve("Señora del quiosco"), CastVoices.resolve("Señora del quiosco")
check(valid(g1) and show(g1) == show(g2), "quien no está en el reparto tiene una voz fija para su nombre")
check(valid(CastVoices.resolve(nil)) and show(CastVoices.resolve(nil)) == show(CastVoices.resolve("Narrador")), "sin nadie: la del narrador")

---------------------------------------------------------------------
print("\n▶ Perfiles de Config")
for name, profile in Config.Audio.Voices.Speakers do
	check(valid(CastVoices.resolve(name)) and profile.VoiceId ~= "", "Speakers." .. name .. ": " .. show(CastVoices.resolve(name)))
end
for age, list in Config.StreetVoices.Presets do
	for i, v in list do
		check(valid(v), ("StreetVoices.Presets.%s[%d]: %s"):format(age, i, show(v)))
	end
end
check(Config.Audio.Voices.AutoLocalize == false, "AutoLocalize = false: se dice en español, igual que el subtítulo")

---------------------------------------------------------------------
print("\n▶ Lo que se lee en voz alta")
check(CastVoices.speakable("<i>Hola</i>, <b>criatura</b>") == "Hola, criatura", "sin etiquetas")
check(CastVoices.speakable("¡Bip, gracias! *hace una reverencia* 🤖✨") == "¡Bip, gracias!", "sin *acotaciones* ni emojis")
check(CastVoices.speakable("(susurrando) Ven aquí.") == "Ven aquí.", "sin la acotación del principio")
check(CastVoices.speakable("📱") == nil and CastVoices.speakable("   ") == nil, "nada que decir: nil")
check(CastVoices.speakable("¿Qué tal? Muy bien, ñandú.") == "¿Qué tal? Muy bien, ñandú.", "tildes, eñes y signos se quedan")
local long = string.rep("Esto es una frase bastante larga para probar. ", 12)
local cut = CastVoices.speakable(long) or ""
check(#cut <= 300 and #cut > 150 and string.sub(cut, -1) == ".", ("un texto largo se corta en una frase (%d → %d bytes)"):format(#long, #cut))

---------------------------------------------------------------------
print("\n▶ Speech: generar, repetir, fallar y volver a probar")
local Speech = L.load("src/client/Controllers/Speech")
Speech._clock = function()
	return clock
end
local function lastTts()
	for i = #created, 1, -1 do
		if created[i].ClassName == "AudioTextToSpeech" then
			return created[i]
		end
	end
	return nil
end

player.Attributes.FamilyKey = "NPC.MAMA"
local mama = Speech.voiceFor("Familia")
check(mama.VoiceId == FEMALE, "voiceFor usa la casa del jugador (Mamá)")
local handle = Speech.say("¡Buenos días, cariño!", mama)
local tts = lastTts()
check(handle ~= nil and tts and tts.Playing, "suena")
check(tts and tts.VoiceId == FEMALE and tts.Pitch == mama.Pitch and tts.Speed == mama.Speed, "con la voz, el tono y la velocidad de Mamá")
check(tts and tts.AutoLocalize == false, "AutoLocalize = false")
check(tts and tts.Text == "¡Buenos días, cariño!", "con el texto de la frase")
local function wireFrom(source: any): any
	for _, obj in created do
		if obj.ClassName == "Wire" and obj.SourceInstance == source and not obj.Destroyed then
			return obj.TargetInstance
		end
	end
	return nil
end
local fader = wireFrom(tts)
local limiter = fader and wireFrom(fader)
local out = limiter and wireFrom(limiter)
check(handle and not handle.Spatial and fader and fader.ClassName == "AudioFader", "sin posición (la historia): 2D, al bus de las voces")
check(limiter and limiter.ClassName == "AudioLimiter" and out and out.ClassName == "AudioDeviceOutput", "bus: ganancia → limitador → altavoces")
check(fader and fader.Volume == Config.Audio.Voices.Gain and Config.Audio.Voices.Gain >= 2, ("ganancia del bus x%s"):format(tostring(fader and fader.Volume)))
check(tts and tts.Volume == 3, ("volumen de la voz al máximo de Roblox (%s)"):format(tostring(tts and tts.Volume)))
check(limiter and limiter.MaxLevel <= 0 and limiter.MaxLevel >= -12, "el limitador no deja saturar")
check(Config.Audio.DuckVolume <= 0.35, ("la música baja al %d%% mientras hablan"):format(Config.Audio.DuckVolume * 100))
if handle then
	handle.Stop()
end
check(tts and not tts.Playing, "Stop la corta")
local before = loads
local again = Speech.say("¡Buenos días, cariño!", mama)
check(again ~= nil and loads == before, "la misma frase con la misma voz se repite sin pedirla otra vez")
if again then
	again.Stop()
end

-- Con posición: la cabeza de quien habla
local head = { Name = "Head", Parent = true, Position = roblox.Vector3.new(4, 5, 0) }
function head:IsA(c)
	return c == "BasePart"
end
local h3 = Speech.say("Ven, que te enseño el garaje.", Speech.voiceFor("Cosme"), { At = head })
local emitter, listener = nil, nil
for _, obj in created do
	if obj.ClassName == "AudioEmitter" and obj.Parent == head then
		emitter = obj
	elseif obj.ClassName == "AudioListener" then
		listener = obj
	end
end
check(h3 ~= nil and h3.Spatial and emitter ~= nil, "con At: AudioEmitter en la cabeza de quien habla")
check(emitter and emitter.AudioInteractionGroup == "Voces" and listener and listener.AudioInteractionGroup == "Voces" and listener.Parent == camera, "emisor y oyente (en la cámara) del grupo Voces")
check(emitter and type(emitter.Curve) == "table", "con su curva de distancia")
if h3 then
	h3.Stop()
end
check(emitter and emitter.Destroyed, "al acabar se quita el emisor")

-- A tiempo: adelanto, espera a la que ya se genera y frases que llegan tarde
print("\n▶ Speech: a tiempo (generación simulada de 0,8 s)")
loadSeconds = 0.8
local t0 = clock
local cold = Speech.say("Frase sin adelantar.", mama)
local coldDelay = clock - t0
check(cold ~= nil and math.abs(coldDelay - 0.8) < 1e-6, ("sin adelanto, la voz llega %.1f s después de pedirla"):format(coldDelay))
if cold then
	cold.Stop()
end
local script = { "Primera frase de la escena.", "Segunda frase de la escena.", "Tercera frase de la escena." }
local items = {}
for _, text in script do
	table.insert(items, { Text = text, Voice = mama })
end
Speech.prefetch(items, true)
for _ = 1, 20 do
	if Speech.state().Queued == 0 and Speech.ready(script[3], mama) then
		break
	end
	task.wait(0.01)
end
check(Speech.ready(script[1], mama) and Speech.ready(script[2], mama) and Speech.ready(script[3], mama), "prefetch deja listas las frases que vienen")
local worst = 0
for _, text in script do
	local s0 = clock
	local hh = Speech.say(text, mama, { MaxDelay = 1.5 })
	worst = math.max(worst, clock - s0)
	check(hh ~= nil, "suena: " .. text)
	if hh then
		hh.Stop()
	end
end
check(worst == 0, ("con adelanto, cada voz sale a la vez que su texto (retraso máximo %.1f s)"):format(worst))
check(Speech.state().Stats.Prefetched == 3, "(3 adelantadas)")
-- Pedir una que el adelanto aún está generando: se espera a esa, no se pide dos veces
loadSeconds, loadYield = 0, 0.15
Speech.prefetch({ { Text = "Se está generando ya.", Voice = mama } })
local before2 = loads
local both = Speech.say("Se está generando ya.", mama)
check(both ~= nil and loads == before2, "si ya se está generando, se espera a esa (una sola petición)")
if both then
	both.Stop()
end
loadYield = 0
-- Llega tarde: no se dice
loadSeconds = 2
local lateHandle = Speech.say("Esta llega tarde.", mama, { MaxDelay = 1.5 })
check(lateHandle == nil and Speech.state().Stats.Late == 1, "si el audio llega más de 1,5 s tarde, esa frase no se dice")
loadSeconds = 0
local replay = Speech.say("Esta llega tarde.", mama, { MaxDelay = 1.5 })
check(replay ~= nil, "(se queda guardada: si se repite, ya suena a tiempo)")
if replay then
	replay.Stop()
end
check(Config.Audio.Voices.WaitText <= 0.6 and Config.Audio.Voices.MaxDelay <= 1.5, "la caja espera a la voz como mucho 0,6 s; tarde = más de 1,5 s")
clock += 61

-- Un fallo: espera y vuelve a probar (no se apaga para siempre)
loadStatus = "Failure"
local failed = Speech.say("Esta no carga.", mama)
check(failed == nil, "si LoadAsync falla, no suena (quedan los subtítulos)")
check(#L.warnings == 1, "se avisa una vez en la consola")
loadStatus = "Success"
local during = Speech.say("Otra frase nueva.", mama)
check(during == nil and Speech.state().Backoff > 0, "durante la espera no se pide nada")
clock += 61
local after = Speech.say("Otra frase nueva.", mama)
check(after ~= nil, "pasada la espera, vuelve a hablar")
if after then
	after.Stop()
end
Speech.say("Y otra más que no carga.", mama)
check(#L.warnings == 1, "(el aviso no se repite)")
clock += 120

-- Límite por minuto y cupo de la calle
Speech._reset()
Speech._clock = function()
	return clock
end
local per = Config.Audio.Voices.PerMinute
for i = 1, per do
	local hh = Speech.say("Frase número " .. i .. ".", mama)
	if hh then
		hh.Stop()
	end
	clock += 0.5
end
check(Speech.say("Una de más.", mama) == nil, ("como mucho %d frases nuevas por minuto"):format(per))
check(not Speech.canRequest("Street"), "la gente de la calle no gasta lo que queda")
clock += 61
check(Speech.canRequest("Street"), "al minuto, la calle puede volver a hablar")

-- Volumen 0
Speech.setVolume(0)
local count = loads
check(Speech.say("No debería sonar.", mama) == nil and loads == count, "volumen 0: no se pide nada")
Speech.setVolume(0.6)
local quiet = Speech.say("Más bajito.", mama)
local qt = lastTts()
check(quiet ~= nil and qt and math.abs(qt.Volume - Config.Audio.Voices.Volume * 0.6) < 1e-6, "el volumen del menú se aplica")
if quiet then
	quiet.Stop()
end

L.finish("test-voices")
