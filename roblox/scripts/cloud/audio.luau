-- audio: ¿la música y los sonidos subidos son audios de verdad, del dueño del juego, y cargan?
--
-- Para la queja «Nunca ha sonado la música» (móvil). Para cada id de audio del juego
-- (Config.Audio.Music y Stings, shared/SoundIds, Config.Sounds y Config.Seasons.Sounds con número):
--   1. MarketplaceService:GetProductInfo: AssetTypeId = 3 (Audio; no un decal ni un modelo) y que el
--      creador sea el dueño del juego (game.CreatorType / game.CreatorId). Un audio privado de otro
--      creador NO suena en el juego.
--   2. ContentProvider:PreloadAsync: Success / Failure (privado, en revisión, rechazado o borrado).
--   3. Un Sound con ese id en SoundService: ¿IsLoaded y TimeLength > 0? (en un servidor puede no
--      cargar nunca el sonido: solo es un aviso).
--
-- Uso (desde roblox/, con una clave con permiso «luau-execution-sessions»):
--   bash scripts/cloud-test.sh -v audio
-- Lo que hay que mirar: las líneas [audio] con ❌. Qué hacer si falla, en audio/README.md
-- («Si la música no suena»).

local Cloud = Cloud :: any
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local Shared = Cloud.Shared
local Config = require(Shared:WaitForChild("Config")) :: any
local SoundIds = require(Shared:WaitForChild("SoundIds")) :: any

local function line(s: string)
	print("[audio] " .. s)
end

local ownerType = tostring(game.CreatorType):match("%.(%w+)$") or tostring(game.CreatorType)
local ownerId = game.CreatorId
line(("Dueño del juego: %s %d (PlaceId %d, versión %d)"):format(ownerType, ownerId, game.PlaceId, game.PlaceVersion))
Cloud.info("Dueño", ("%s %d"):format(ownerType, ownerId))
Cloud.info("PlaceVersion", game.PlaceVersion)

-- Todos los ids: nombre -> número
local ids: { { Name: string, Id: number, Music: boolean } } = {}
local seen: { [number]: boolean } = {}
local function add(name: string, value: any, music: boolean)
	local n: number? = nil
	if type(value) == "number" then
		n = value
	elseif type(value) == "string" then
		n = tonumber(value:match("^rbxassetid://(%d+)$"))
	end
	if n and n > 0 and not seen[n] then
		seen[n] = true
		table.insert(ids, { Name = name, Id = n, Music = music })
	end
end
for cue, track in Config.Audio.Music do
	add("Music." .. cue, track.Id, true)
	add("Music." .. cue .. " (SoundIds)", SoundIds[(string.gsub(track.File or "", "%.ogg$", ""))], true)
end
for cue, sting in Config.Audio.Stings or {} do
	add("Stings." .. cue, sting.Id, true)
end
for name, value in SoundIds do
	add("SoundIds." .. name, value, false)
end
for name, entry in Config.Sounds do
	add("Sounds." .. name, entry.Id, false)
end
for name, value in (Config.Seasons and Config.Seasons.Sounds) or {} do
	add("Seasons." .. name, value, false)
end
table.sort(ids, function(a, b)
	if a.Music ~= b.Music then
		return a.Music
	end
	return a.Name < b.Name
end)
line(("%d audios con id"):format(#ids))

-- (Se le pasa un Sound, no el id en texto: con «rbxassetid://…» en texto PreloadAsync dice Failure con
-- todos los audios, también los de Roblox. Comprobado en un servidor de verdad.)
local function preload(id: string): string
	local status = "?"
	local probe = Instance.new("Sound")
	probe.SoundId = id
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync({ probe }, function(_, s)
			status = tostring(s):match("%.(%w+)$") or tostring(s)
		end)
	end)
	probe:Destroy()
	return if ok then status else ("error: " .. tostring(err))
end

local musicOk, musicBad = 0, 0
for _, item in ids do
	if Cloud.quedan() < 20 then
		Cloud.salta("Quedan audios sin mirar", "se acaba el tiempo de la prueba")
		break
	end
	local contentId = "rbxassetid://" .. string.format("%d", item.Id)
	local typeId, creatorType, creatorId, creatorName = nil, "?", -1, "?"
	local okInfo, errInfo = pcall(function()
		local info = MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
		typeId = info.AssetTypeId
		local c = info.Creator or {}
		creatorType = tostring(c.CreatorType)
		creatorId = tonumber(c.CreatorTargetId or c.Id) or -1
		creatorName = tostring(c.Name)
	end)
	local isAudio = typeId == 3
	local sameOwner = creatorType == ownerType and creatorId == ownerId
	local fetch = preload(contentId)
	-- (un Sound de verdad: ¿carga?)
	local sound = Instance.new("Sound")
	sound.SoundId = contentId
	sound.Parent = SoundService
	local deadline = os.clock() + 1.5
	while not sound.IsLoaded and os.clock() < deadline do
		task.wait(0.2)
	end
	local loaded, length = sound.IsLoaded, sound.TimeLength
	sound:Destroy()

	local good = okInfo and isAudio and sameOwner and fetch ~= "Failure"
	if item.Music then
		if good then
			musicOk += 1
		else
			musicBad += 1
		end
	end
	local detail = if okInfo
		then ("AssetTypeId=%s (%s), creador %s %d «%s» (%s), PreloadAsync=%s, IsLoaded=%s, %.1f s"):format(
			tostring(typeId), if isAudio then "Audio" else "NO es audio", creatorType, creatorId, creatorName,
			if sameOwner then "el dueño del juego" else "OTRO creador: no suena aquí", fetch, tostring(loaded), length)
		else ("GetProductInfo falla: %s · PreloadAsync=%s"):format(tostring(errInfo), fetch)
	line(("%s %s %s: %s"):format(if good then "✅" else "❌", item.Name, contentId, detail))
	Cloud.check(("%s es un audio del dueño del juego y se puede descargar"):format(item.Name), good, contentId .. " · " .. detail)
	if good and not loaded then
		Cloud.aviso(("%s carga en un Sound del servidor"):format(item.Name), false, "IsLoaded = false a los 1,5 s (en un servidor puede ser normal)")
	end
end
line(("Música: %d bien, %d mal"):format(musicOk, musicBad))
Cloud.info("Música bien", musicOk)
Cloud.info("Música mal", musicBad)

return Cloud.resultado()
