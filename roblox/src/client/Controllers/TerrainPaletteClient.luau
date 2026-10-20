-- TerrainPaletteClient (cliente): los colores del terreno según DÓNDE está tu cámara (shared/TerrainPalette).
--
-- El terreno es uno solo para todo el place: si el servidor pintaba Tefra, el fondo del mar de Valmar
-- quedaba gris ceniza (el «campo de nieve» de la v124). Ahora el servidor solo pone la paleta de
-- Valmar y aquí, en tu pantalla:
--   * en Tefra: sus colores (los de Valmar de esos materiales se guardan antes). Los planetas nuevos
--     (shared/Cosmos/PlanetSurface: Miasma, Siroco…) los pinta Controllers/PlanetClient.tintTerrain
--   * al volver a Valmar: se devuelven los guardados
--   * en Valmar, cada segundo: el fondo del mar (TerrainPalette.Sea) con sus colores; si algo los ha
--     cambiado, se devuelven y se cuenta en el atributo TerrainPaletteFixes del jugador (la sonda de la
--     nube y el probador lo leen: tiene que quedarse en 0)
-- (Los cambios de SetMaterialColor hechos en el cliente solo se ven en ese cliente: no tocan a nadie más.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TerrainPalette = require(ReplicatedStorage.Shared.TerrainPalette)

local TerrainPaletteClient = {}

-- Los planetas con terreno propio (se cargan con pcall: si uno falla, Valmar sigue bien)
local function planets(): { any }
	local list = {}
	local ok, Tefra = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.Tefra)
	end)
	if ok and Tefra and Tefra.TerrainColors then
		table.insert(list, { Id = "Tefra", contains = Tefra.contains, TerrainColors = Tefra.TerrainColors })
	end
	-- (Miasma, Siroco…: si tienen terreno con colores propios, se añaden aquí con su contains y sus
	-- TerrainColors; NUNCA con SetMaterialColor en el servidor)
	return list
end

local zone = "Valmar"
local saved: { [string]: Color3 } = {}

local function set(terrain: Terrain, name: string, color: Color3)
	pcall(function()
		terrain:SetMaterialColor((Enum.Material :: any)[name], color)
	end)
end

local function get(terrain: Terrain, name: string): Color3?
	local ok, color = pcall(function()
		return terrain:GetMaterialColor((Enum.Material :: any)[name])
	end)
	return if ok then color else nil
end

-- Un paso (cada segundo; las pruebas lo llaman a mano). Devuelve cuántos colores del mar corrigió.
function TerrainPaletteClient.step(terrain: Terrain, at: Vector3, list: { any }): number
	local id, colors = TerrainPalette.zoneAt(at, list)
	if id ~= zone then
		-- Al salir de un planeta: lo guardado de Valmar
		for name, color in saved do
			set(terrain, name, color)
		end
		table.clear(saved)
		if colors then
			for name, color in colors do
				local before = get(terrain, name)
				if before then
					saved[name] = before
				end
				set(terrain, name, color)
			end
		end
		zone = id
	end
	if zone ~= "Valmar" or not TerrainPalette.inValmar(at) then
		return 0 -- (en un planeta de PlanetSurface pinta Controllers/PlanetClient: aquí no se toca)
	end
	local fixes = 0
	for name, want in TerrainPalette.Sea do
		local now = get(terrain, name)
		if now and not TerrainPalette.same(now, want) then
			set(terrain, name, want)
			fixes += 1
		end
	end
	return fixes
end

function TerrainPaletteClient.zone(): string
	return zone
end

function TerrainPaletteClient.init()
	local list = planets()
	local player = Players.LocalPlayer
	local total = 0
	task.spawn(function()
		task.wait(3) -- (el terreno y sus colores llegan del servidor al entrar)
		while true do
			local camera = workspace.CurrentCamera
			if camera then
				local ok, fixes = pcall(TerrainPaletteClient.step, workspace.Terrain, camera.Focus.Position, list)
				if ok and fixes > 0 then
					total += fixes
					player:SetAttribute("TerrainPaletteFixes", total)
					warn(("[TerrainPalette] el fondo del mar había cambiado de color: devuelto (%d)"):format(total))
				end
			end
			task.wait(1)
		end
	end)
end

return TerrainPaletteClient
