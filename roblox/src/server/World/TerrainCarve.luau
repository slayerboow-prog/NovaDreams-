-- TerrainCarve: abrir huecos de AGUA en terreno macizo.
--
-- En Roblox, Terrain:FillBlock / FillBall / FillCylinder con Enum.Material.Water NO sustituye el terreno macizo:
-- el agua solo llena lo que está vacío (aire). Por eso el río y los lagos de World/TerrainBuilder se abren antes
-- con aire. El mar hondo no lo hacía: el agua de Ocean.planWater caía sobre la capa de arena de TerrainBuilder
-- (de −24 a −14) y la dejaba tal cual. En un servidor de verdad (sonda mar-v3-sonda, v131) el fondo del mar
-- quedaba PLANO a −14 en todas partes: el Jardín Escarlata (−45), el kelp (−40), el abismo (−436) y el Gran Veril.
--
-- TerrainCarve.wrap(terrain) devuelve el mismo terreno, pero cada relleno de agua va antes con aire en la misma
-- forma (así sí abre). Lo demás pasa tal cual al terreno de verdad.

local TerrainCarve = {}

local WATER = Enum.Material.Water
local AIR = Enum.Material.Air

function TerrainCarve.wrap(terrain: any): any
	if type(terrain) == "table" and rawget(terrain, "__carve") then
		return terrain
	end
	local proxy = { __carve = true, Terrain = terrain }
	function proxy.FillBlock(_, cf: CFrame, size: Vector3, material: Enum.Material)
		if material == WATER then
			terrain:FillBlock(cf, size, AIR)
		end
		terrain:FillBlock(cf, size, material)
	end
	function proxy.FillBall(_, center: Vector3, radius: number, material: Enum.Material)
		if material == WATER then
			terrain:FillBall(center, radius, AIR)
		end
		terrain:FillBall(center, radius, material)
	end
	function proxy.FillCylinder(_, cf: CFrame, height: number, radius: number, material: Enum.Material)
		if material == WATER then
			terrain:FillCylinder(cf, height, radius, AIR)
		end
		terrain:FillCylinder(cf, height, radius, material)
	end
	return setmetatable(proxy, {
		__index = function(_, key)
			local v = terrain[key]
			if type(v) == "function" then
				return function(_, ...)
					return v(terrain, ...)
				end
			end
			return v
		end,
	})
end

return TerrainCarve
