-- QuestHooks: la casa de Cosme y la historia (docs/historia/casa-cosme.md, punto 32).
--
-- En el mapa (al construir la casa):
--   * StorySpot (SpotId) de cada sitio de la casa: el de siempre, «GarajeCosme» (delante del garaje,
--     mirando a la calle: ahí empiezan y vuelven las misiones de Cosme), y los nuevos CosmeCocina,
--     CosmeLaboratorio, CosmeMaquina, CosmePortal, CosmeObservatorio, CosmeSecreta… (shared/LifeStory/
--     Locations los conoce con el mismo nombre).
--   * StoryArea (AreaId = "Cosme" .. habitación) con el volumen de cada habitación (Inside = true).
--
-- Mientras se juega (lo llaman CosmeHouse/Interactions y CosmeHouse/NPC), avisos a la historia por
-- server/LifeStory/StoryEvents, sin saber nada de misiones:
--   * "PropUsed" { Prop = PropId }  -> un paso de misión Type = "Use", Prop = "CosmeTelescopio"…
--   * "CosmeHouse" { Action = …, … } -> un paso Type = "Event", Event = "CosmeHouse", Match = { Action = "PortalActivated" }
--     Acciones: PortalActivated (Destination), SecretOpened, DocumentRead (Prop), MachineOn (Target),
--     TelescopeUsed, Experiment (Effect), CosmeTalk (Room)
--   * "Talk" { Npc = "Cosme" } al hablar con Cosme en su casa.
-- Viajes del portal: QuestHooks.onTravel(fn) deja que una misión futura decida qué pasa al activar el
-- portal hacia un destino (fn(player, destId) -> true si se encarga ella). Sin nadie, solo se mira.
-- La casa evoluciona con la historia: QuestHooks.setState(clave, valor) deja atributos en el modelo
-- (State_<clave>) que el cliente y los constructores pueden mirar.

local Layout = require(script.Parent.Layout)

local QuestHooks = {}

QuestHooks.Spots = Layout.Spots

-- Marcas de la historia dentro del modelo de la casa
function QuestHooks.marks(ctx: any, model: Instance)
	local StoryMarks = require(script.Parent.Parent.Kit.StoryMarks)
	local folder = Instance.new("Folder")
	folder.Name = "MarcasHistoria"
	folder.Parent = model
	for id, s in Layout.Spots do
		local cf = ctx.Site * CFrame.new(s[1], s[2] + 2.5, s[3]) * CFrame.Angles(0, math.rad(s[4] or 0), 0)
		StoryMarks.spot(folder, id, cf, { House = "CasaCosme" })
	end
	for _, room in Layout.Rooms do
		local y0, y1 = Layout.levelRange(room.Level)
		local size = Vector3.new(room.X1 - room.X0, y1 - y0, room.Z1 - room.Z0)
		local cf = ctx.Site * CFrame.new((room.X0 + room.X1) / 2, (y0 + y1) / 2, (room.Z0 + room.Z1) / 2)
		local area = StoryMarks.area(folder, "Cosme" .. room.Id, cf, size, { House = "CasaCosme", Room = room.Id })
		area:AddTag("CosmeRoom")
	end
	return folder
end

---------------------------------------------------------------------
-- En el servidor
---------------------------------------------------------------------
local events: any = nil
local function storyEvents(): any
	if events == nil then
		local ok, mod = pcall(function()
			return require(script.Parent.Parent.Parent.LifeStory.StoryEvents)
		end)
		events = if ok then mod else false
	end
	return events or nil
end

function QuestHooks.emit(player: Player, action: string, payload: { [string]: any }?)
	local se = storyEvents()
	if not se then
		return
	end
	local data = table.clone(payload or {})
	data.Action = action
	se.emit(player, "CosmeHouse", data)
end

-- Algo de la casa se ha usado (documento, máquina, telescopio…)
function QuestHooks.used(player: Player, propId: string?, action: string?, extra: { [string]: any }?)
	local se = storyEvents()
	if se and type(propId) == "string" and propId ~= "" then
		se.emit(player, "PropUsed", { Prop = propId })
	end
	if action then
		local data = table.clone(extra or {})
		data.Prop = propId
		QuestHooks.emit(player, action, data)
	end
end

function QuestHooks.talked(player: Player, room: string?)
	local se = storyEvents()
	if se then
		se.emit(player, "Talk", { Npc = "Cosme" })
	end
	QuestHooks.emit(player, "CosmeTalk", { Room = room })
end

local travelHandlers: { (Player, string) -> boolean? } = {}
function QuestHooks.onTravel(fn: (Player, string) -> boolean?)
	table.insert(travelHandlers, fn)
end

-- El portal ha llegado a su destino (lo más alto de la secuencia). true si alguna misión se encarga
function QuestHooks.portalPeak(player: Player, destId: string): boolean
	QuestHooks.emit(player, "PortalActivated", { Destination = destId })
	for _, fn in travelHandlers do
		local ok, handled = pcall(fn, player, destId)
		if ok and handled then
			return true
		end
	end
	return false
end

function QuestHooks.setState(model: Instance, key: string, value: any)
	model:SetAttribute("State_" .. key, value)
end

return QuestHooks
