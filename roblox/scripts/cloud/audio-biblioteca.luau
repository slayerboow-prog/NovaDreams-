-- audio-biblioteca: ¿los efectos de la biblioteca de Roblox (Config.Sounds con Id) cargan y duran lo que toca?
--
-- Los efectos «AAA» del juego son audios públicos de la biblioteca de Roblox (subidos por Roblox o por la
-- librería profesional con licencia ProSoundEffects): cualquier experiencia los puede reproducir. Esta
-- prueba NO necesita que el juego esté publicado con ellos: la lista va aquí abajo (copia de
-- Config.Sounds; scripts/test-sfx.luau comprueba que no se desfasa). Para cada id:
--   1. MarketplaceService:GetProductInfo: AssetTypeId = 3 (Audio) y quién lo subió.
--   2. ContentProvider:PreloadAsync con un Sound: Success / Failure (privado, en revisión, borrado…).
--   3. Un Sound con ese id: IsLoaded y TimeLength (la duración de verdad); si el efecto usa un trozo
--      (Region), que el trozo quepa en el audio.
--
-- Uso (desde roblox/, con una clave con permiso «luau-execution-sessions»):
--   bash scripts/cloud-test.sh -v audio-biblioteca

local Cloud = Cloud :: any
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

-- Config.Sounds con Id de la biblioteca (nombre, id y, si usa un trozo, dónde acaba)
local LIBRARY: { { Name: string, Id: number, RegionEnd: number? } } = {
	{ Name = "AroRebote", Id = 9116764099 },
	{ Name = "Aviso", Id = 17208361335 },
	{ Name = "AvisoAeropuerto", Id = 9114132512, RegionEnd = 3.2 },
	{ Name = "BalonBote", Id = 9113329573 },
	{ Name = "Beber", Id = 9114686828, RegionEnd = 1.2 },
	{ Name = "BiciCadena", Id = 9113438203, RegionEnd = 9 },
	{ Name = "BocinaTren", Id = 9120247994 },
	{ Name = "Brazada", Id = 9120589166, RegionEnd = 4.5 },
	{ Name = "CambioMarcha", Id = 9113018515, RegionEnd = 0.95 },
	{ Name = "Claxon", Id = 9113013987 },
	{ Name = "ClaxonPesado", Id = 9114661361 },
	{ Name = "Clic", Id = 15675059323 },
	{ Name = "Cocinar", Id = 9114542867, RegionEnd = 5 },
	{ Name = "Coger", Id = 17208323435 },
	{ Name = "Comer", Id = 9113138343 },
	{ Name = "Derrape", Id = 9120399191, RegionEnd = 4.8 },
	{ Name = "Descubrimiento", Id = 9119447936 },
	{ Name = "Dinero", Id = 17208380755 },
	{ Name = "Error", Id = 17208353912 },
	{ Name = "Fabricar", Id = 9114756156, RegionEnd = 0.9 },
	{ Name = "FutbolChute", Id = 9119327232 },
	{ Name = "FutbolPoste", Id = 9116764099 },
	{ Name = "FutbolSilbato", Id = 9117261163 },
	{ Name = "Grillos", Id = 9112762281 },
	{ Name = "KO", Id = 9113798204 },
	{ Name = "KOCaida", Id = 9113469292, RegionEnd = 1 },
	{ Name = "Logro", Id = 15675043410 },
	{ Name = "MenuAbrir", Id = 17208405682 },
	{ Name = "MenuAtras", Id = 17208186900 },
	{ Name = "MenuMover", Id = 17208339919 },
	{ Name = "MenuOk", Id = 17208396156 },
	{ Name = "MetroGong", Id = 9114132738, RegionEnd = 3.5 },
	{ Name = "MisionEmpieza", Id = 15675085146 },
	{ Name = "MonopatinRodar", Id = 9125955674, RegionEnd = 22 },
	{ Name = "MovilAbrir", Id = 17208408337 },
	{ Name = "Multitud", Id = 9112767169 },
	{ Name = "Olas", Id = 9119677145 },
	{ Name = "Ovacion", Id = 9120974911 },
	{ Name = "Pago", Id = 9113728756 },
	{ Name = "PatineteZumbido", Id = 9116980359, RegionEnd = 3.2 },
	{ Name = "PesasGolpe", Id = 9113271308 },
	{ Name = "PistolaSalida", Id = 9114700217, RegionEnd = 1.8 },
	{ Name = "PublicoEstadio", Id = 9119562817 },
	{ Name = "Puerta", Id = 9120839870, RegionEnd = 2.3 },
	{ Name = "PuertaCoche", Id = 9113205539 },
	{ Name = "PuertaCocheAbrir", Id = 9113205239 },
	{ Name = "RaquetaGolpe", Id = 9119985541, RegionEnd = 1.75 },
	{ Name = "RedSwish", Id = 9113342890, RegionEnd = 0.62 },
	{ Name = "Seleccion", Id = 17208339919 },
	{ Name = "SilbatoGol", Id = 9125965988 },
	{ Name = "Tension", Id = 9125404320 },
	{ Name = "Timbre", Id = 9125390528, RegionEnd = 2.3 },
	{ Name = "VoleyGolpe", Id = 9113330443 },
	{ Name = "Xp", Id = 17208319162 },
}

local function line(s: string)
	print("[audio-biblioteca] " .. s)
end

local function preload(sound: Sound): string
	local status = "?"
	local ok, err = pcall(function()
		ContentProvider:PreloadAsync({ sound }, function(_, s)
			status = tostring(s):match("%.(%w+)$") or tostring(s)
		end)
	end)
	return if ok then status else ("error: " .. tostring(err))
end

local byId: { [number]: { string } } = {}
local regionEnd: { [number]: number } = {}
local order: { number } = {}
for _, item in LIBRARY do
	if not byId[item.Id] then
		byId[item.Id] = {}
		table.insert(order, item.Id)
	end
	table.insert(byId[item.Id], item.Name)
	if item.RegionEnd then
		regionEnd[item.Id] = math.max(regionEnd[item.Id] or 0, item.RegionEnd)
	end
end
line(("%d efectos, %d audios distintos"):format(#LIBRARY, #order))
Cloud.info("Audios", #order)

local good, bad = 0, 0
for _, id in order do
	if Cloud.quedan() < 15 then
		Cloud.salta("Quedan audios sin mirar", "se acaba el tiempo de la prueba")
		break
	end
	local names = table.concat(byId[id], ", ")
	local contentId = "rbxassetid://" .. string.format("%d", id)
	local typeId, creator, title = nil, "?", "?"
	local okInfo, errInfo = pcall(function()
		local info = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset)
		typeId = info.AssetTypeId
		creator = tostring((info.Creator or {}).Name)
		title = tostring(info.Name)
	end)
	local sound = Instance.new("Sound")
	sound.SoundId = contentId
	sound.Parent = SoundService
	local fetch = preload(sound)
	local deadline = os.clock() + 4
	while not sound.IsLoaded and os.clock() < deadline do
		task.wait(0.1)
	end
	local loaded, length = sound.IsLoaded, sound.TimeLength
	sound:Destroy()
	local fits = regionEnd[id] == nil or not loaded or regionEnd[id] <= length + 0.05
	local ok = okInfo and typeId == 3 and fetch ~= "Failure" and loaded and length > 0 and fits
	if ok then
		good += 1
	else
		bad += 1
	end
	local detail = ("%s · %s · «%s» de %s · PreloadAsync=%s · IsLoaded=%s · %.2f s%s"):format(
		names, contentId, title, creator, fetch, tostring(loaded), length,
		if regionEnd[id] then (" · trozo hasta %.2f s%s"):format(regionEnd[id], if fits then "" else " (NO CABE)") else "")
	if not okInfo then
		detail ..= " · GetProductInfo falla: " .. tostring(errInfo)
	elseif typeId ~= 3 then
		detail ..= " · AssetTypeId=" .. tostring(typeId) .. " (NO es audio)"
	end
	line(("%s %s"):format(if ok then "✅" else "❌", detail))
	Cloud.check(("%s carga en el motor"):format(names), ok, detail)
end
-- Los trozos (Region) se ponen con PlaybackRegion/LoopRegion: ¿el motor los acepta?
do
	local probe = Instance.new("Sound")
	local okRegion, errRegion = pcall(function()
		local range = NumberRange.new(0.2, 1.2)
		probe.PlaybackRegionsEnabled = true
		probe.PlaybackRegion = range
		probe.LoopRegion = range
	end)
	probe:Destroy()
	Cloud.check("PlaybackRegion y LoopRegion se pueden poner en un Sound", okRegion, if okRegion then nil else tostring(errRegion))
end
line(("Bien: %d · mal: %d"):format(good, bad))
Cloud.info("Bien", good)
Cloud.info("Mal", bad)

return Cloud.resultado()
