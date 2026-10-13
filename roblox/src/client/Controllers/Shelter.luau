-- Shelter (cliente): ¿le cae la lluvia a la cámara o a alguien? Las mismas reglas para todos los
-- efectos de lluvia (shared/RainLook.blocksRain / enclosed), para que no se contradigan:
--   * Controllers/Weather: la lluvia que cae solo se quita DENTRO (tejado y paredes alrededor); bajo
--     un balcón o un saliente de la fachada se sigue viendo llover en la calle (antes bastaba cualquier
--     cosa encima de la cámara para quitar toda la lluvia: andando pegado a los edificios no llovía).
--   * Controllers/ScreenRain: gotas en la pantalla solo si no hay NADA encima (ni un toldo).
--   * Controllers/WetWorld: la gente se moja si no tiene nada encima.
-- Los rayos de la cámara se cachean (como mucho 5 veces por segundo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RainLook = require(ReplicatedStorage.Shared.RainLook)

local Shelter = {}

local UP = 80 -- hasta dónde se mira hacia arriba
local SIDE = 36 -- distancia a la que una pared cuenta como «paredes alrededor»
local EVERY = 0.2
local AHEAD = 14 -- studs por delante de la cámara para ver si el tejado sigue

local solid = RaycastParams.new() -- solo lo que choca (paredes y tejados de verdad)
solid.FilterType = Enum.RaycastFilterType.Exclude
solid.RespectCanCollide = true
local any = RaycastParams.new() -- todo lo que se vea (toldos, marquesinas, balcones decorativos)
any.FilterType = Enum.RaycastFilterType.Exclude

local function ignoreList(extra: { Instance }?): { Instance }
	local list: { Instance } = { workspace.CurrentCamera }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	if extra then
		for _, item in extra do
			table.insert(list, item)
		end
	end
	return list
end

-- ¿Algo tapa la lluvia encima de este punto? (respectCollide: solo tejados que chocan)
function Shelter.roofAbove(point: Vector3, ignore: { Instance }?, respectCollide: boolean?, height: number?): boolean
	local params = if respectCollide then solid else any
	params.FilterDescendantsInstances = ignore or ignoreList()
	local hit = workspace:Raycast(point, Vector3.new(0, height or UP, 0), params)
	return hit ~= nil and RainLook.blocksRain(hit.Instance.Transparency, hit.Material.Name)
end

type CameraState = { Roof: boolean, Covered: boolean, Enclosed: boolean, At: number }
local cached: CameraState = { Roof = false, Covered = false, Enclosed = false, At = -1 }

-- La cámara: Roof = tejado de verdad encima; Covered = cualquier cosa encima (toldo incluido);
-- Enclosed = dentro (tejado encima y más allá, o paredes en 3 de 4 lados)
function Shelter.camera(): CameraState
	local now = os.clock()
	if now - cached.At < EVERY then
		return cached
	end
	cached.At = now
	local camera = workspace.CurrentCamera
	local from = camera.CFrame.Position
	local ignore = ignoreList()
	local roof = Shelter.roofAbove(from, ignore, true)
	local covered = roof or Shelter.roofAbove(from, ignore, false, 40)
	local walls = 0
	if roof then
		solid.FilterDescendantsInstances = ignore
		for _, dir in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local hit = workspace:Raycast(from, dir * SIDE, solid)
			if hit and hit.Instance.Transparency < 0.9 then
				walls += 1
			end
		end
	end
	-- Un poco más allá de donde mira: ¿también hay tejado? (bajo un saliente mirando a la calle, no)
	local roofAhead = false
	if roof then
		local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude > 0.05 then
			roofAhead = Shelter.roofAbove(from + look.Unit * AHEAD, ignore, true)
		end
	end
	cached.Roof = roof
	cached.Covered = covered
	cached.Enclosed = RainLook.enclosed(roof, walls, roofAhead)
	return cached
end

return Shelter
