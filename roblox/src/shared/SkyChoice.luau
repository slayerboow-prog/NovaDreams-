-- SkyChoice: el cielo de fotos (skybox realista) de día y de noche. Cuentas puras (se prueban fuera de
-- Roblox: scripts/test-graphics.luau).
--
--   * Day / Night: el id del asset de la Tienda de creadores que trae un `Sky` (un modelo con un Sky
--     dentro, o el Sky suelto). 0 = sin cielo de fotos: se queda el de siempre (el Sky del archivo del
--     juego, con nubes volumétricas, bruma, sol, luna y estrellas).
--   * El servidor (World/SkyLoader) los carga al arrancar con AssetService:LoadAssetAsync (o
--     InsertService:LoadAsset), borra cualquier script que traigan y deja solo el Sky en
--     ReplicatedStorage.SkyLibrary ("Day" / "Night"). Si falla o no hay id, no se hace nada.
--   * El cliente (Controllers/DayLight) copia las 6 caras del que toque al Sky de Lighting (no lo
--     sustituye: el sol, la luna y las estrellas siguen siendo los nuestros) y, si no hay cielo para esa
--     hora, vuelve a poner las caras de siempre.
--   * El cambio de un cielo a otro se hace en la hora más oscura del crepúsculo (no se nota el salto).
--
-- Ids elegidos en la revisión de los assets del dueño (docs/assets-implementados.md).
-- Candidato de noche revisado: 7485807340 (Hyper-Realistic Night Pack, docs/assets-usuario-3.md). NO
-- se pone: su Sky lleva la MISMA imagen (83951719, un bosque oscuro) en las 6 caras, también arriba y
-- sobre el mar: sobre Valmar se verían árboles en el cielo. (Sus scripts tampoco valen: primera persona
-- forzada, niebla negra.) Si se quisiera probar igual, basta con poner aquí su id: el cargador busca el
-- Sky dentro del pack y tira todo lo demás.

local SkyChoice = {}

export type Slot = "Day" | "Night"

-- Día: el cielo azul con nubes del «Simple Lighting Pack» (8294099223, limpio). Noche: la Vía Láctea
-- de «Realistic Space Skybox» (136402262, limpio). Del Sky solo se copian las caras: el sol, la luna y
-- las estrellas siguen siendo los nuestros. Los cielos especiales (tormenta, sueño, Grieta…) los pone
-- Controllers/SkyExtras encima (shared/SkyExtras).
SkyChoice.Day = { Id = 8294099223, Note = "Simple Lighting Pack: cielo azul con nubes" }
SkyChoice.Night = { Id = 136402262, Note = "Realistic Space Skybox: la Vía Láctea (7485807340 no vale: bosque en las 6 caras)" }

SkyChoice.Library = "SkyLibrary" -- carpeta en ReplicatedStorage con los Sky cargados
SkyChoice.Faces = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

-- El cielo de noche entra a esta hora y sale a esta otra (en lo más oscuro del crepúsculo, cuando el
-- salto de un cielo a otro no se nota): hora azul -> noche (19,5) y antes del alba (5,2)
SkyChoice.NightFrom = 19.5
SkyChoice.NightUntil = 5.2

function SkyChoice.valid(id: any): boolean
	return type(id) == "number" and id > 0 and id == math.floor(id)
end

-- Los cielos que hay que cargar: { { Slot = "Day", Id = … }, … } (solo los que tienen id)
function SkyChoice.wanted(): { { Slot: Slot, Id: number } }
	local out = {}
	for _, slot in { "Day", "Night" } :: { Slot } do
		local entry = (SkyChoice :: any)[slot]
		if entry and SkyChoice.valid(entry.Id) then
			table.insert(out, { Slot = slot, Id = entry.Id })
		end
	end
	return out
end

function SkyChoice.phase(hour: number): Slot
	hour = hour % 24
	return if hour >= SkyChoice.NightFrom or hour < SkyChoice.NightUntil then "Night" else "Day"
end

-- Qué cielo de fotos poner a esta hora con los que han cargado (have.Day / have.Night).
-- nil = el de siempre (no hay cielo de fotos para esta hora).
function SkyChoice.pick(hour: number, have: { [string]: boolean }): Slot?
	local phase = SkyChoice.phase(hour)
	return if have[phase] then phase else nil
end

-- ¿Este Sky sirve? Tiene que traer las 6 caras (si no, Roblox pinta el cielo de dibujo en las vacías)
function SkyChoice.complete(faces: { [string]: string? }): boolean
	for _, face in SkyChoice.Faces do
		local value = faces[face]
		if type(value) ~= "string" or value == "" then
			return false
		end
	end
	return true
end

return SkyChoice
