-- Cinematics: PUENTE de compatibilidad (fase 6 del cine, «un solo motor»).
--
-- Aquí estaban escritas las 21 «cinemáticas viejas» (nacimiento, cabeceras y finales de capítulo, fotos
-- de grupo…) con su propio reproductor (client/Controllers/Cinematics). Ahora son escenas del MOTOR, con
-- el mismo id y el mismo contenido, en shared/LifeStory/Happenings/Capitulos.luau: las lanza
-- CinematicService.play → HappeningService (servidor) y las ve HappeningClient (cliente).
--
-- Este módulo ya no tiene definiciones (Cinematics[id] es nil para todas: nadie las reproduce por el
-- camino viejo). Solo dice qué ids vinieron de aquí, para quien lo necesite:
--   Cinematics.Ids            los 21 ids, en orden
--   Cinematics.isLegacy(id)   ¿vino de aquí? (p. ej. scripts/lib/Reescritura: «una cinemática vieja se
--                             cambia por una escena nueva», no se reescribe con su mismo id)
--   Cinematics.get(id)        su escena del motor (o nil)

local Capitulos = require(script.Parent.Happenings.Capitulos)

local Cinematics = {}

local ids = {}
for id in Capitulos do
	table.insert(ids, id)
end
table.sort(ids)
Cinematics.Ids = table.freeze(ids)

local set = {}
for _, id in ids do
	set[id] = true
end

function Cinematics.isLegacy(id: any): boolean
	return type(id) == "string" and set[id] == true
end

function Cinematics.get(id: any): { [string]: any }?
	return if Cinematics.isLegacy(id) then Capitulos[id] else nil
end

return Cinematics
