-- HappeningIndex: todas las ESCENAS de la historia (acontecimientos con planos, efectos, actores,
-- diálogos y consecuencias), juntas por grupos en shared/LifeStory/Happenings/<Grupo>.luau.
-- Para añadir un grupo nuevo (la granja, el instituto…): crea Happenings/<Grupo>.luau y ponlo en GROUPS.
--
-- Una misión las lanza con un paso de cine normal (el id de la escena en vez del de una cinemática):
--   { Type = "Cinematic", Id = "Grieta_Caen", Actors = { … } }
-- o como efecto de un paso, de una frase de diálogo o de un objeto (no para la historia):
--   Effects = { Scene = "Grieta_Recoger" }
-- El motor: shared/LifeStory/Sequencer (cuentas), server/Services/HappeningService (lanza, actores,
-- consecuencias) y client/Controllers/HappeningClient (cámara, efectos, sonido, diálogo).

local HappeningIndex = {}

local GROUPS = { "Cielo", "Etapas", "Colegio", "Universidad", "Instituto", "Adulto" }

local all: { [string]: { [string]: any } } = {}
local groupOf: { [string]: string } = {}
for _, group in GROUPS do
	local ok, list = pcall(function()
		return require((script.Parent.Happenings :: any)[group])
	end)
	if ok and type(list) == "table" then
		for id, def in list do
			if all[id] then
				warn(("[HappeningIndex] Escena repetida '%s' (%s y %s)"):format(id, groupOf[id], group))
			end
			all[id] = def
			groupOf[id] = group
		end
	else
		warn(("[HappeningIndex] No se pudo cargar el grupo '%s': %s"):format(group, tostring(list)))
	end
end

function HappeningIndex.get(id: any): { [string]: any }?
	return if type(id) == "string" then all[id] else nil
end

function HappeningIndex.has(id: any): boolean
	return type(id) == "string" and all[id] ~= nil
end

function HappeningIndex.all(): { [string]: { [string]: any } }
	return all
end

function HappeningIndex.groupOf(id: string): string?
	return groupOf[id]
end

HappeningIndex.Groups = GROUPS

return HappeningIndex
