-- PlanetRegistry: QUÉ PLANETAS tienen superficie jugable y DÓNDE está cada uno (marco común de los
-- planetas, docs/planetas/marco-planetas.md). Cuentas puras; lo usan el servidor (PlanetService,
-- PlanetWorld, PlanetHazardService, PlanetJobService, GalaxyMapService), el cliente (PlanetClient,
-- EnvDirector, PlanetHazardHud, Hud) y la historia (LifeStory/Locations).
--
-- Cada planeta jugable es un módulo de shared/Cosmos con la superficie (Tefra.luau va a mano; los demás,
-- shared/Cosmos/PlanetSurface.new) y, colgando de él:
--   S.City      el plano del barrio (TefraCity o shared/Cosmos/PlanetCity.new)
--   S.Env       su cielo y su luz (shared/Cosmos/EnvZones: { Sky, Clouds, Mood })      (opcional)
--   S.Sound     su sonido (shared/Cosmos/Soundscapes.Planets: { Mood, Ambience, Music, Modes }) (opcional)
--   S.Hazard    su desventaja (shared/Cosmos/PlanetHazard.new)  (Tefra lleva la suya: TefraService)
--   S.Jobs      sus oficios (shared/Cosmos/PlanetJobs)                                   (opcional)
--   S.Fx        lo que cae del cielo en la superficie: { { Color, Size, Rate } }        (opcional)
--   S.Kit       el nombre del kit del servidor que dibuja sus formas (World/<Kit>)    (opcional)
--
-- AÑADIR UN PLANETA: una línea en PlanetRegistry.Modules (y su hueco de Slots ya está reservado), y su
-- id en shared/Cosmos/Planets.EarlyAccess si se puede visitar ya (como Tefra: Saga 1 o tester).

local PlanetRegistry = {}

-- Huecos en el mundo (centro de cada zona de superficie): muy lejos de Valmar, del espacio, de la arena
-- de pruebas (24 000, 24 000) y entre ellos. Zonas de hasta 3072 × 3072.
PlanetRegistry.Slots = {
	Tefra = Vector3.new(-25000, 0, 25000),
	Miasma = Vector3.new(25000, 0, -25000),
	Siroco = Vector3.new(-25000, 0, -25000),
	Nivalis = Vector3.new(-32000, 0, 0),
	Umbria = Vector3.new(0, 0, 32000),
	Talasa = Vector3.new(0, 0, -32000),
	Vertice = Vector3.new(32000, 0, 0),
}

-- Los planetas con superficie (id → nombre del módulo de shared/Cosmos). UNA LÍNEA POR PLANETA.
PlanetRegistry.Modules = {
	Tefra = "Tefra",
	Miasma = "Miasma",
	Siroco = "Siroco",
	Nivalis = "Nivalis",
}

-- (orden fijo para recorrerlos: el de la saga)
PlanetRegistry.Order = { "Tefra", "Miasma", "Siroco", "Nivalis", "Umbria", "Talasa", "Vertice" }

local cache: { [string]: any } = {}

-- La superficie de un planeta (o nil si aún no tiene)
function PlanetRegistry.get(id: string?): any
	if type(id) ~= "string" then
		return nil
	end
	local found = cache[id]
	if found ~= nil then
		return found or nil
	end
	local name = PlanetRegistry.Modules[id]
	if not name then
		return nil
	end
	local ok, mod = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	if not ok then
		warn("[PlanetRegistry] " .. id .. ": " .. tostring(mod))
		cache[id] = false
		return nil
	end
	cache[id] = mod
	return mod
end

-- Los ids con superficie, en el orden de la saga
function PlanetRegistry.ids(): { string }
	local out = {}
	for _, id in PlanetRegistry.Order do
		if PlanetRegistry.Modules[id] then
			table.insert(out, id)
		end
	end
	for id in PlanetRegistry.Modules do
		if not table.find(out, id) then
			table.insert(out, id)
		end
	end
	return out
end

-- { [id] = superficie } de todos los que hay
function PlanetRegistry.surfaces(): { [string]: any }
	local out = {}
	for _, id in PlanetRegistry.ids() do
		local S = PlanetRegistry.get(id)
		if S then
			out[id] = S
		end
	end
	return out
end

-- La superficie cuya zona tiene dentro este punto (o nil) → (id, superficie)
function PlanetRegistry.at(pos: Vector3, margin: number?): (string?, any)
	for _, id in PlanetRegistry.ids() do
		local S = PlanetRegistry.get(id)
		if S and S.inRegion(pos, margin) then
			return id, S
		end
	end
	return nil, nil
end

-- El planeta de un id con prefijo («Miasma_L3», «Siroco_Pozo») → (id, superficie)
function PlanetRegistry.byKey(key: string?): (string?, any)
	if type(key) ~= "string" then
		return nil, nil
	end
	local id = string.match(key, "^(%a+)_")
	if id and PlanetRegistry.Modules[id] then
		return id, PlanetRegistry.get(id)
	end
	return nil, nil
end

return PlanetRegistry
