-- Prueba: los efectos de sonido (client/Controllers/SoundFx + GameSfx, Config.Sounds y Config.SfxMix).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-sfx.luau
--
-- Carga SoundFx de verdad fuera de Roblox (scripts/lib/ModuleLoader) con un Sound de mentira y comprueba:
--   * Registro: cada nombre de Config.Sounds da un id o nada, sin errores; cada File tiene su .ogg en
--     audio/sfx; los Fallback son sonidos de Roblox; las capas (Layers) nombran sonidos que existen;
--     las categorías existen en Config.SfxMix.
--   * Sin subir: los nuevos (Dinero, SubirNivel…) NO suenan (mejor nada que un pitido) y los de siempre
--     (Clic, Aviso, FutbolChute…) siguen con su sonido de Roblox. Un nombre que no existe: nil, sin error.
--   * Subidos (un Sound en ReplicatedStorage > Sonidos con el nombre del archivo): cada uno suena con
--     el suyo, con la variación de tono, en el grupo SFX y en 3D con caída suave si va en una pieza.
--   * Volumen 0 / «Sonidos: no»: no se crea ningún sonido. Nivel del menú = volumen del grupo SFX.
--   * Cooldown (el «ka-ching» no ametralla), tope de sonidos a la vez, capas del gol y agache de la música.
--   * GameSfx: qué suena al cobrar, pagar, subir XP o nivel, con la historia, grillos y olas.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")

local check = L.check
local Config = L.load("src/shared/Config")
local SOUNDS = Config.Sounds

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
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
	}
end

local created = {}
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
	function s:Destroy()
		if not self.Destroyed then
			self.Destroyed = true
			self.Parent = nil
			self.Destroying:Fire()
		end
	end
	table.insert(created, s)
	return s
end

local player = {
	Name = "Prueba",
	Attributes = {},
	Character = nil,
	CharacterAdded = signal(),
	signals = {},
}
function player:GetAttribute(k)
	return self.Attributes[k]
end
function player:GetAttributeChangedSignal(k)
	self.signals[k] = self.signals[k] or signal()
	return self.signals[k]
end
function player:set(k, v)
	self.Attributes[k] = v
	if self.signals[k] then
		self.signals[k]:Fire()
	end
end

local soundService = roblox.Instance.new("Folder")
soundService.Name = "SoundService"
L.services.SoundService = soundService
L.services.Players = { LocalPlayer = player }
L.services.ContextActionService = { BindAction = function() end, UnbindAction = function() end }
L.services.Lighting = { ClockTime = 12 }
L.services.RunService.Heartbeat = signal()
L.services.ReplicatedStorage.Remotes = { WaitForChild = function()
	return nil
end }

-- ReplicatedStorage.Shared con FindFirstChild (SoundFx busca SoundIds así) y el resto como nodos
-- (los require de ReplicatedStorage.Shared.X: el cargador sigue la ruta con nodos)
local realShared = L.services.ReplicatedStorage.Shared
local sharedProxy = setmetatable({ __path = "src/shared" }, {
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
L.services.ReplicatedStorage.Shared = sharedProxy

L.mock("src/client/UI/TouchLayout", { register = function() end, riding = function()
	return false
end })
L.mock("src/client/UI/SpeechBubbles", { show = function() end, onSpoken = function() end })

local SFX_PATH = "src/client/Controllers/SoundFx"
local function freshSoundFx()
	L.reset(SFX_PATH)
	return L.load(SFX_PATH)
end

local function isRobloxSound(id: any): boolean
	return type(id) == "string" and string.match(id, "^rbxasset://sounds/") ~= nil
end

---------------------------------------------------------------------
print("\n🔊 Registro (Config.Sounds y Config.SfxMix)")
---------------------------------------------------------------------
local MIX = Config.SfxMix
check(type(MIX) == "table" and type(MIX.Categories) == "table", "Config.SfxMix con volumen por categoría")
check(type(MIX.MaxActive) == "number" and MIX.MaxActive >= 8 and MIX.MaxActive <= 32, "tope de efectos a la vez razonable para el móvil: " .. tostring(MIX.MaxActive))
check(type(MIX.Steps) == "table" and MIX.Steps[1] == 1 and MIX.Steps[#MIX.Steps] == 0, "menú «Sonidos»: de alto a no")
local badFiles, badFallback, badLayers, badCategory = {}, {}, {}, {}
for name, entry in SOUNDS do
	if entry.File and not fs.isFile("audio/sfx/" .. entry.File .. ".ogg") then
		table.insert(badFiles, name)
	end
	if entry.Fallback and not isRobloxSound(entry.Fallback.Id) then
		table.insert(badFallback, name)
	end
	for _, layer in entry.Layers or {} do
		if not SOUNDS[layer.Name] or layer.Name == name then
			table.insert(badLayers, name .. "→" .. tostring(layer.Name))
		end
	end
	if entry.Category and type(MIX.Categories[entry.Category]) ~= "number" then
		table.insert(badCategory, name)
	end
	if entry.Category and entry.Category ~= "UI" and entry.Category ~= "Recompensa" and entry.Category ~= "Momento" and entry.Category ~= "Mundo" then
		table.insert(badCategory, name)
	end
end
check(#badFiles == 0, "cada File tiene su archivo en audio/sfx " .. table.concat(badFiles, ", "))
check(#badFallback == 0, "cada Fallback es un sonido de Roblox (suena en cualquier juego) " .. table.concat(badFallback, ", "))
check(#badLayers == 0, "cada capa nombra otro sonido que existe " .. table.concat(badLayers, ", "))
check(#badCategory == 0, "cada categoría existe en Config.SfxMix " .. table.concat(badCategory, ", "))

-- Los nuevos efectos (los que pide el encargo) están registrados con su archivo
local NEW = {
	Clic = "ui_toque", Aviso = "notificacion", Error = "error_suave", MenuAbrir = "ui_abrir", MenuAtras = "ui_cerrar",
	Seleccion = "ui_seleccion", MovilAbrir = "movil_abrir", Dinero = "dinero", Pago = "caja_registradora", Xp = "xp",
	SubirNivel = "nivel_sube", MisionEmpieza = "mision_empieza", MisionCompleta = "mision_completa", Logro = "logro",
	Descubrimiento = "descubrimiento_fx", Tension = "tension_golpe", Coger = "coger_objeto", Puerta = "puerta_madera",
	FutbolChute = "balon_patada", FutbolSilbato = "silbato", Ovacion = "estadio_ovacion", BalonBote = "balon_bote",
	AroRebote = "aro_rebote", RedSwish = "red_swish", RaquetaGolpe = "raqueta_golpe", PesasGolpe = "pesas_golpe",
	Grillos = "grillos", Olas = "olas",
}
local missing = {}
for name, file in NEW do
	if not SOUNDS[name] or SOUNDS[name].File ~= file then
		table.insert(missing, name)
	end
end
check(#missing == 0, "los efectos nuevos tienen su archivo " .. table.concat(missing, ", "))

-- Ningún archivo de audio/sfx se queda sin usar (el script de subida los sube todos)
local used = {}
for _, entry in SOUNDS do
	if entry.File then
		used[entry.File] = true
	end
end
for _, file in Config.Seasons.SoundFiles or {} do
	used[file] = true
end
local unused = {}
for _, name in fs.readDir("audio/sfx") do
	local stem = string.match(name, "^(.-)%.ogg$")
	if stem and not used[stem] then
		table.insert(unused, stem)
	end
end
check(#unused == 0, "todos los .ogg de audio/sfx se usan " .. table.concat(unused, ", "))

---------------------------------------------------------------------
print("\n🔇 Sin subir: los nuevos no suenan, los de siempre siguen, nada da error")
---------------------------------------------------------------------
local SoundFx = freshSoundFx()
local SoundIds = L.load("src/shared/SoundIds")
local errors = {}
for name, entry in SOUNDS do
	local ok, id = pcall(SoundFx.id, name)
	if not ok then
		table.insert(errors, name .. ": " .. tostring(id))
	elseif id ~= nil and type(id) ~= "string" then
		table.insert(errors, name .. " id raro")
	end
	-- Lo que debe salir: su Id, su archivo subido (SoundIds) o su Fallback; si no, nada
	local expected = nil
	if type(entry.Id) == "string" and entry.Id ~= "" then
		expected = entry.Id
	elseif type(entry.Id) == "number" and entry.Id > 0 then
		expected = "rbxassetid://" .. entry.Id
	elseif entry.File and SoundIds[entry.File] then
		expected = SoundIds[entry.File]
	elseif entry.Fallback then
		expected = entry.Fallback.Id
	end
	if ok and id ~= expected then
		table.insert(errors, ("%s: %s (esperaba %s)"):format(name, tostring(id), tostring(expected)))
	end
end
check(#errors == 0, "cada nombre se resuelve o cae a su reserva " .. table.concat(errors, "; "))
-- (los que ya tienen su audio de la biblioteca de Roblox en Id no cuentan aquí)
local function noLibraryId(name: string): boolean
	local id = SOUNDS[name].Id
	return id == 0 or id == nil
end
for _, name in { "Dinero", "SubirNivel", "MisionCompleta", "Logro", "Xp", "Ovacion", "Grillos" } do
	if noLibraryId(name) and not SoundIds[SOUNDS[name].File] then
		check(SoundFx.id(name) == nil, name .. ": sin subir no suena (nada de pitidos de reserva)")
	end
end
for _, name in { "Clic", "Aviso", "Error", "FutbolChute", "FutbolSilbato", "Puerta" } do
	if noLibraryId(name) and not SoundIds[SOUNDS[name].File] then
		check(isRobloxSound(SoundFx.id(name)), name .. ": sin subir, el de Roblox de siempre")
	end
end
local ok1, r1 = pcall(SoundFx.play, "NoExisteEsteSonido")
check(ok1 and r1 == nil, "un nombre que no existe: nil, sin error")
local ok2, r2 = pcall(SoundFx.play, "SubirNivel", { Volume = 1 })
check(ok2 and r2 == nil, "uno sin audio subido: nil, sin error")
local ok3 = pcall(SoundFx.play, "FutbolGol")
check(ok3, "unas capas sin audio subido: sin error")

---------------------------------------------------------------------
print("\n🔊 Subidos (ReplicatedStorage > Sonidos): cada uno suena con el suyo")
---------------------------------------------------------------------
local sonidos = roblox.Instance.new("Folder")
sonidos.Name = "Sonidos"
for _, name in fs.readDir("audio/sfx") do
	local stem = string.match(name, "^(.-)%.ogg$")
	if stem then
		local s = roblox.Instance.new("Sound")
		s.Name = stem
		s.SoundId = "rbxassetid://up_" .. stem
		s.Parent = sonidos
	end
end
L.services.ReplicatedStorage.Sonidos = sonidos
SoundFx = freshSoundFx()
local wrong = {}
for name, entry in SOUNDS do
	if entry.File and (entry.Id == 0 or entry.Id == nil) and not SoundIds[entry.File] then
		if SoundFx.id(name) ~= "rbxassetid://up_" .. entry.File then
			table.insert(wrong, name)
		end
	end
end
check(#wrong == 0, "cada efecto usa su archivo subido " .. table.concat(wrong, ", "))

table.clear(created)
local s = SoundFx.play("Dinero")
check(s ~= nil and s.SoundId == "rbxassetid://" .. SOUNDS.Dinero.Id and s.Playing, "Dinero suena con el de la biblioteca (su Id manda sobre el archivo subido)")
check(s and s.SoundGroup and s.SoundGroup.Name == "SFX", "en el grupo SFX (el silencio y el nivel del menú valen)")
check(s and s.PlaybackSpeed >= 0.96 and s.PlaybackSpeed <= 1.04, "con una pizca de variación de tono")
check(SoundFx.play("Dinero") == nil, "dos «ka-ching» seguidos: el segundo no (cooldown)")

local part = roblox.Instance.new("Part")
local hit = SoundFx.play("BalonBote", { At = part })
check(hit ~= nil and hit.Parent == part, "un bote suena en la pieza (3D)")
check(hit and hit.RollOffMode == roblox.Enum.RollOffMode.InverseTapered and hit.RollOffMaxDistance <= 200, "con caída suave y alcance limitado")
local ui = SoundFx.play("MovilAbrir")
check(ui ~= nil and ui.Parent == nil and ui.RollOffMode == nil, "la interfaz suena en 2D (sin pieza)")

-- Variación real: diez botes no suenan iguales
local speeds = {}
for _ = 1, 10 do
	task.wait(0.07)
	local b = SoundFx.play("BalonBote", { At = part })
	if b then
		speeds[string.format("%.3f", b.PlaybackSpeed)] = true
	end
end
local distinct = 0
for _ in speeds do
	distinct += 1
end
check(distinct >= 5, ("los botes varían de tono (%d tonos distintos de 10)"):format(distinct))

---------------------------------------------------------------------
print("\n🎚️ Volumen 0, nivel del menú y silencio")
---------------------------------------------------------------------
SoundFx.setLevel(0)
table.clear(created)
check(SoundFx.play("Clic") == nil and #created == 0, "nivel 0: no se crea ningún sonido")
SoundFx.setLevel(0.6)
check(math.abs(SoundFx.group("SFX").Volume - 0.6) < 1e-6, "nivel medio: el grupo SFX a 0.6")
check(SoundFx.play("Clic") ~= nil, "nivel medio: suena")
SoundFx.setMuted(true)
table.clear(created)
check(SoundFx.play("Aviso") == nil and #created == 0, "«Sonidos: no»: no se crea ningún sonido")
check(SoundFx.group("SFX").Volume == 0 and SoundFx.group("Ambience").Volume == 0, "y los grupos SFX y Ambience a 0")
SoundFx.setMuted(false)
SoundFx.setLevel(1)
check(SoundFx.group("SFX").Volume == 1, "al volver: el grupo SFX a su nivel")

---------------------------------------------------------------------
print("\n🧮 Tope de sonidos a la vez y capas")
---------------------------------------------------------------------
SoundFx = freshSoundFx()
local before = SoundFx.activeCount()
local made = 0
for _ = 1, 60 do
	-- (sin cooldown: el golpe del choque)
	if SoundFx.play("Golpe", { At = part }) then
		made += 1
	end
end
check(SoundFx.activeCount() <= MIX.MaxActive, ("como mucho %d efectos del mundo a la vez (%d)"):format(MIX.MaxActive, SoundFx.activeCount()))
check(made < 60 and before == 0, "los que sobran no se crean")
check(SoundFx.play("Aviso") ~= nil, "la interfaz aún suena con el mundo lleno")
for _, snd in created do
	snd:Destroy()
end
check(SoundFx.activeCount() == 0, "al acabar, la cuenta vuelve a 0")

table.clear(created)
SoundFx.play("FutbolGol")
task.wait(0.5)
local ids = {}
for _, snd in created do
	ids[snd.SoundId] = true
end
local function idOf(name: string): string
	return if noLibraryId(name) then "rbxassetid://up_" .. SOUNDS[name].File else "rbxassetid://" .. SOUNDS[name].Id
end
check(ids[idOf("SilbatoGol")] and ids[idOf("RedSwish")] and ids[idOf("Ovacion")], "gol: silbato, red y grada (capas)")

---------------------------------------------------------------------
print("\n🎵 Agache de la música con las fanfarrias")
---------------------------------------------------------------------
local music = SoundFx.group("Music")
SoundFx.setGroupOn("Music", true)
task.wait((SOUNDS.FutbolGol.DuckHold or 2) + (MIX.DuckRelease or 1) + 0.3) -- (que acabe el agache del gol)
check(music.Volume == 1, "música a 1 antes")
SoundFx.play("SubirNivel")
task.wait(0.3)
check(music.Volume < 0.7, ("al subir de nivel la música baja (%.2f)"):format(music.Volume))
task.wait((SOUNDS.SubirNivel.DuckHold or 2) + (MIX.DuckRelease or 1) + 0.4)
check(math.abs(music.Volume - 1) < 1e-3, ("y vuelve sola (%.2f)"):format(music.Volume))
SoundFx.setGroupOn("Music", false)
SoundFx.play("MisionCompleta")
task.wait(0.2)
check(music.Volume == 0, "con la música apagada sigue a 0 durante el agache")
SoundFx.setGroupOn("Music", true)

---------------------------------------------------------------------
print("\n🎮 GameSfx: qué suena con cada cosa")
---------------------------------------------------------------------
L.mock(SFX_PATH, SoundFx)
local GameSfx = L.load("src/client/Controllers/GameSfx")
check(GameSfx.moneyCue(100, 150, true) == "Dinero", "cobrar: «ka-ching»")
check(GameSfx.moneyCue(150, 100, true) == "Pago", "pagar: el lector y el cajón")
check(GameSfx.moneyCue(nil, 500, true) == nil and GameSfx.moneyCue(100, 500, false) == nil, "al cargar la partida: nada")
check(GameSfx.progressCue(10, 40, 3, 3, true) == "Xp", "XP que sube: destello")
check(GameSfx.progressCue(90, 5, 3, 4, true) == "SubirNivel", "nivel nuevo: fanfarria (y no la XP a la vez)")
check(GameSfx.progressCue(40, 10, 3, 3, true) == nil, "XP que baja (otra vida): nada")
check(GameSfx.storyCue("QuestIntro") == "MisionEmpieza" and GameSfx.storyCue("Done") == "MisionCompleta", "misión que empieza y que se cumple")
check(GameSfx.storyCue("Discover") == "Descubrimiento" and GameSfx.storyCue("State") == nil, "sitio descubierto; el estado no suena")
check(GameSfx.itemCount('[{"i":"Manzana","n":3},{"i":"Llave"}]') == 4 and GameSfx.itemCount(nil) == nil, "cuenta lo que llevas en la mochila")
local square = { { 0, 0 }, { 100, 0 }, { 100, 100 }, { 0, 100 } }
check(math.abs(GameSfx.coastDistance(50, 10, square) - 10) < 1e-6, "distancia a la costa")
check(GameSfx.waveAmount(20) == 1 and GameSfx.waveAmount(1000) == 0, "olas: fuertes en la orilla, nada tierra adentro")
check(GameSfx.nightAmount(23) == 1 and GameSfx.nightAmount(13) == 0 and GameSfx.nightAmount(20.25) > 0, "grillos: de noche, con fundido al anochecer")
-- Los cues de GameSfx existen en el registro
for _, cue in { "Dinero", "Pago", "Xp", "SubirNivel", "MisionEmpieza", "MisionCompleta", "Descubrimiento", "Aviso", "Coger", "Grillos", "Olas", "Tension" } do
	check(SOUNDS[cue] ~= nil, cue .. " registrado")
end

-- De verdad con atributos: cobrar después de cargar → «ka-ching»
GameSfx.init()
player:set("Money", 500)
table.clear(created)
player:set("Money", 600)
check(#created == 0, "el dinero de la carga no suena")

---------------------------------------------------------------------
print("\n📚 Biblioteca de Roblox: ids, trozos y huecos nuevos")
---------------------------------------------------------------------
local badIds, badRegions = {}, {}
for name, entry in SOUNDS do
	if type(entry.Id) == "number" and entry.Id ~= 0 and (entry.Id < 1e6 or entry.Id ~= math.floor(entry.Id)) then
		table.insert(badIds, name)
	end
	local r = entry.Region
	if r ~= nil and (type(r) ~= "table" or type(r[1]) ~= "number" or type(r[2]) ~= "number" or r[1] < 0 or r[2] <= r[1] or r[2] - r[1] > 30) then
		table.insert(badRegions, name)
	end
	if entry.Region and (type(entry.Id) ~= "number" or entry.Id == 0) then
		table.insert(badRegions, name .. " (Region sin Id)")
	end
	if entry.FadeOut and not entry.Region then
		table.insert(badRegions, name .. " (FadeOut sin Region)")
	end
end
check(#badIds == 0, "los Id de la biblioteca son números de asset " .. table.concat(badIds, ", "))
check(#badRegions == 0, "cada Region es { desde, hasta } de un Id de la biblioteca " .. table.concat(badRegions, ", "))
local NEW_SLOTS = {
	"BiciCadena", "PatineteZumbido", "MonopatinRodar", "Derrape", "CambioMarcha", "PuertaCoche", "PuertaCocheAbrir",
	"ClaxonPesado", "Comer", "Beber", "Cocinar", "Fabricar", "PistolaSalida", "KO", "KOCaida", "Brazada",
	"BocinaTren", "AvisoAeropuerto", "PublicoEstadio", "SilbatoGol",
}
local missingSlots = {}
for _, name in NEW_SLOTS do
	local entry = SOUNDS[name]
	if not entry or type(entry.Id) ~= "number" or entry.Id <= 0 then
		table.insert(missingSlots, name)
	end
end
check(#missingSlots == 0, "los huecos nuevos tienen su audio de la biblioteca " .. table.concat(missingSlots, ", "))
check(SoundFx.id("Comer") == "rbxassetid://" .. SOUNDS.Comer.Id, "un hueco nuevo se resuelve a su Id")
-- La prueba en el motor (scripts/cloud/audio-biblioteca.luau) lleva la misma lista: que no se desfase
local cloudList = fs.readFile("scripts/cloud/audio-biblioteca.luau")
local stale = {}
for name, entry in SOUNDS do
	if type(entry.Id) == "number" and entry.Id > 0 then
		local row = ('{ Name = "%s", Id = %d'):format(name, entry.Id)
		local region = if entry.Region then (", RegionEnd = %s"):format(tostring(entry.Region[2])) else ""
		if not string.find(cloudList, row .. region .. " }", 1, true) then
			table.insert(stale, name)
		end
	end
end
check(#stale == 0, "la lista de scripts/cloud/audio-biblioteca.luau es la de Config.Sounds " .. table.concat(stale, ", "))

-- Un trozo (Region) se aplica al Sound si el motor tiene NumberRange (en Lune puede no haberlo)
if NumberRange then
	SoundFx = freshSoundFx()
	local b = SoundFx.play("Beber")
	check(b ~= nil and b.PlaybackRegionsEnabled == true, "Beber suena solo su trozo (PlaybackRegion)")
else
	print("  (sin NumberRange en Lune: el trozo se comprueba en el motor, scripts/cloud/audio.luau)")
end

-- Marchas: sube al pasar cada umbral y no baja hasta perder algo más de velocidad
check(SoundFx.gearFor(0, 1) == 1 and SoundFx.gearFor(0.3, 1) == 2 and SoundFx.gearFor(0.9, 1) == 5, "marchas según la velocidad")
check(SoundFx.gearFor(0.36, 2) == 2 and SoundFx.gearFor(0.1, 3) == 1, "al bajar, con margen (no suena dos veces)")
-- Derrape: solo coches y camiones, con freno de mano o frenando a fondo deprisa
check(SoundFx.skidAmount("Coche", true, false, 30) > 0.5 and SoundFx.skidAmount("Coche", false, false, 30) == 0, "derrape con el freno de mano")
check(SoundFx.skidAmount("Coche", false, true, 40) > 0 and SoundFx.skidAmount("Coche", false, true, 10) == 0, "frenazo fuerte solo deprisa")
check(SoundFx.skidAmount("Bici", true, true, 40) == 0 and SoundFx.skidAmount("Caballo", true, true, 40) == 0 and SoundFx.skidAmount("Lancha", true, true, 40) == 0, "ni bici, ni caballo, ni barco")
-- Cocinar y fabricar según el puesto de la receta; comer y beber según el gesto
check(SoundFx.craftSound("Cocina") == "Cocinar" and SoundFx.craftSound("Horno") == "Cocinar" and SoundFx.craftSound("Telar") == "Fabricar" and SoundFx.craftSound(nil) == nil, "cocinar y fabricar")
check(SoundFx.gesture("Eat") == "Comer" and SoundFx.gesture("Drink") == "Beber" and SoundFx.gesture("PickUp") == nil, "comer y beber con el gesto")
-- La grada de los deportes
check(GameSfx.crowdAmount("Futbol") == 1 and GameSfx.crowdAmount("Raqueta") > 0 and GameSfx.crowdAmount(nil) == 0 and GameSfx.crowdAmount("Pesca") == 0, "grada: según el deporte")
for _, name in { "PistolaSalida", "AvisoAeropuerto", "KO", "BocinaTren", "PublicoEstadio" } do
	check(SOUNDS[name] ~= nil, name .. " registrado")
end
check(type(SOUNDS.MetroFreno.Layers) == "table" and SOUNDS.MetroFreno.Layers[1].Name == "BocinaTren", "el tren pita al llegar (capa del frenazo)")

L.finish("test-sfx")
-- (GameSfx deja sus bucles de grillos y olas en marcha: se sale aquí)
require("@lune/process").exit(0)
