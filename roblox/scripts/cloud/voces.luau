-- voces: ¿la voz sintetizada de Roblox (AudioTextToSpeech) habla español en el motor de verdad?
--
-- Para la queja «los personajes no tienen voz». Crea un AudioTextToSpeech con una frase en español
-- para cada VoiceId (las dos voces españolas 101/102, las inglesas 1…11 y una sin VoiceId, como estaba
-- antes el juego) y para unas cuantas voces del reparto (CastVoices: tono y velocidad), llama a
-- LoadAsync y dice qué devuelve (Success / Failure), si IsLoaded y cuánto dura (TimeLength).
--   * "sin VoiceId" con Failure = la causa de que no se oyera nada (el juego no ponía VoiceId).
--   * Ojo: Roblox limita a 1 + 6 × jugadores frases por minuto en todo el juego; con el juego vacío son
--     ~7 por minuto, así que la prueba pide pocas y espera entre una y otra. Si salen Failure seguidos al
--     final, puede ser el límite: vuelve a probar en un minuto.
--
-- Uso (desde roblox/, con una clave con permiso «luau-execution-sessions»):
--   bash scripts/cloud-test.sh -v voces

local Cloud = Cloud :: any
local Shared = Cloud.Shared
-- (CastVoices solo está en las versiones publicadas después de este cambio; si no, voces fijas)
local okCast, CastVoices = pcall(function()
	return require(Shared:WaitForChild("LifeStory"):FindFirstChild("CastVoices") :: any) :: any
end)
local FIXED = {
	Cosme = { VoiceId = "101", Pitch = -2, Speed = 1.18 },
	Sara = { VoiceId = "102", Pitch = 5, Speed = 1.18 },
	Lucia = { VoiceId = "102", Pitch = 0.5, Speed = 0.98 },
}
local SoundService = game:GetService("SoundService")

local function line(s: string)
	print("[voces] " .. s)
end

local TEXT = "¡Hola, criatura! Hoy vamos a la playa con la abuela."
line(("PlaceVersion %d"):format(game.PlaceVersion))
Cloud.info("PlaceVersion", game.PlaceVersion)

local okClass = pcall(function()
	Instance.new("AudioTextToSpeech"):Destroy()
end)
Cloud.check("existe la clase AudioTextToSpeech en el servidor", okClass)
if not okClass then
	return Cloud.resultado()
end

local function try(label: string, voiceId: string?, pitch: number?, speed: number?, text: string?): (string, number)
	local tts = Instance.new("AudioTextToSpeech")
	tts.Text = text or TEXT
	if voiceId then
		tts.VoiceId = voiceId
	end
	tts.Pitch = pitch or 0
	tts.Speed = speed or 1
	pcall(function()
		tts.AutoLocalize = false
	end)
	tts.Parent = SoundService
	local status: any = nil
	local ok, err = pcall(function()
		status = tts:LoadAsync()
	end)
	local loaded, length = tts.IsLoaded, tts.TimeLength
	tts:Destroy()
	local result = if ok then tostring(status) else ("error: " .. tostring(err))
	line(("%s %s: LoadAsync=%s, IsLoaded=%s, %.2f s"):format(if loaded then "✅" else "❌", label, result, tostring(loaded), length))
	return result, length
end

-- 1. Las voces españolas, que son las que usa el juego ahora
local r101, l101 = try("VoiceId 101 (Spanish male)", "101")
task.wait(9)
local r102, l102 = try("VoiceId 102 (Spanish female)", "102")
Cloud.check("101 (hombre, español) genera la frase", l101 > 0, r101)
Cloud.check("102 (mujer, español) genera la frase", l102 > 0, r102)

-- 2. Como estaba antes el juego: sin VoiceId
task.wait(9)
local rNone, lNone = try("sin VoiceId (como antes)", nil)
Cloud.aviso("sin VoiceId también genera (si no: por eso no se oía nada)", lNone > 0, rNone)

-- 3. Unas voces del reparto (tono y velocidad de CastVoices)
for _, who in { "Cosme", "Sara", "Lucia" } do
	if Cloud.quedan() < 40 then
		Cloud.salta("reparto " .. who, "sin tiempo")
		break
	end
	task.wait(9)
	local v = if okCast and CastVoices then CastVoices.resolve(who, { FamilyKey = "NPC.MAMA", AbuKey = "NPC.ABU_ROSA", LifeStage = "Nino" }) else FIXED[who]
	local r, l = try(("%s (%s %+.1f st ×%.2f)"):format(who, v.VoiceId, v.Pitch, v.Speed), v.VoiceId, v.Pitch, v.Speed)
	Cloud.check(("la voz de %s genera la frase"):format(who), l > 0, r)
end

-- 4. Una voz inglesa con texto español (por curiosidad: ¿lo lee o falla?)
if Cloud.quedan() > 30 then
	task.wait(9)
	local rEn, lEn = try("VoiceId 1 (British male) con texto español", "1")
	Cloud.aviso("una voz inglesa también lee el texto (no se usa)", lEn > 0, rEn)
end

return Cloud.resultado()
