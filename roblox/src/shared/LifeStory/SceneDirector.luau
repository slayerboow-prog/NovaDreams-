-- SceneDirector: la DIRECCIÓN AUTOMÁTICA de las escenas del motor (v125.6, «son súper sosas»).
--
-- Lo que una escena escrita a mano no dice, lo pone el director (sin tocar las escenas: el cliente,
-- Controllers/HappeningClient, lo pide al empezar cada escena con cámara):
--   * Ambiente: si la escena no trae pista Ambience, el del sitio donde estás («Auto»: la playa suena a
--     playa, la calle a calle). Una escena con Silence (el silencio después del impacto) no lleva.
--   * Luz según la hora: de noche, la capa «Noche» y una LUZ DE RELLENO en las caras (KeyLight: si no,
--     de noche se veían siluetas negras); en la hora dorada, «Atardecer»; una escena íntima de día,
--     «Intima». Si la escena trae su pista Light, manda la suya (de noche, con la luz de relleno igual).
--   * Planos fijos que respiran: un plano fijo largo (sin Fov propio) se acerca un poco mientras dura
--     (CameraShots.fov con Drift): la cámara nunca está muerta.
-- Módulo puro: se prueba con Lune (scripts/test-scenes.luau, sección 13).

local SceneDirector = {}

SceneDirector.NIGHT_FROM = 19.5 -- (hora del juego, Lighting.ClockTime)
SceneDirector.NIGHT_TO = 6.5
SceneDirector.GOLDEN = { { 6.5, 8 }, { 17.5, 19.5 } }
SceneDirector.NIGHT_WEIGHT = 0.55
SceneDirector.GOLDEN_WEIGHT = 0.45
SceneDirector.INTIMATE_WEIGHT = 0.5

function SceneDirector.isNight(clock: number?): boolean
	if type(clock) ~= "number" then
		return false
	end
	local h = clock % 24
	return h >= SceneDirector.NIGHT_FROM or h < SceneDirector.NIGHT_TO
end

function SceneDirector.isGolden(clock: number?): boolean
	if type(clock) ~= "number" then
		return false
	end
	local h = clock % 24
	for _, range in SceneDirector.GOLDEN do
		if h >= range[1] and h < range[2] then
			return true
		end
	end
	return false
end

local function hasTrack(def: { [string]: any }, name: string): boolean
	local tracks = def.Tracks
	return type(tracks) == "table" and type(tracks[name]) == "table" and #tracks[name] > 0
end

-- Lo que pone el director a una escena: { Ambience = "Auto"?, Light = preset?, Weight?, KeyLight = bool }
-- def = la escena; clock = la hora (Lighting.ClockTime); light = escena ligera (sin cámara: no se toca)
function SceneDirector.mood(def: { [string]: any }, clock: number?, light: boolean?): { [string]: any }
	local out: { [string]: any } = { KeyLight = false }
	if light or type(def) ~= "table" or def.Director == false then
		return out
	end
	if not hasTrack(def, "Ambience") and not def.Silence then
		out.Ambience = "Auto"
	end
	local night = SceneDirector.isNight(clock)
	out.KeyLight = night
	if not hasTrack(def, "Light") then
		if night then
			out.Light, out.Weight = "Noche", SceneDirector.NIGHT_WEIGHT
		elseif SceneDirector.isGolden(clock) then
			out.Light, out.Weight = "Atardecer", SceneDirector.GOLDEN_WEIGHT
		elseif def.Intensity == "Intima" then
			out.Light, out.Weight = "Intima", SceneDirector.INTIMATE_WEIGHT
		end
	end
	return out
end

-- La luz de relleno de noche: dónde va respecto a la cámara (arriba y a un lado, por delante) y cómo es
SceneDirector.KEY_OFFSET = Vector3.new(1.5, 1.2, -1)
SceneDirector.KEY = { Brightness = 1.4, Range = 22, Color = Color3.fromRGB(255, 226, 196) }

return SceneDirector
