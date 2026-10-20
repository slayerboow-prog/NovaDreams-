-- Sitios: las zonas verdes de la fase 1 que se usan (docs/zonas-verdes/plan.md). Lo llama
-- TownBuilder al final (sin math.random: no mueve nada más del mapa). Todo va en la carpeta
-- Town.ZonasVerdes, un Model por sitio (streaming atómico):
--   ParqueVivo × 30   los parques de barrio con columpios, pícnic, pipicán y media pista (Parques)
--   JardinesPlazaMayor (21)        parque infantil grande, pipicán de la Protectora y quiosco (Plaza)
--   HuertosPuertaVillaverde (19)   huertos urbanos con FarmService y cocina del huerto (Huertos)
--   OrillaDelLago (17)             pícnic y hoguera de noche (Lago)
--   CampingVivo                    el Camping de siempre, con tiendas, hoguera y parcelas (Lago)
-- Lo que pasa al usarlos: Services/ParkService (y la diversión, NeedsService + FunService).
-- Otros sitios (mercadillo, deportes, karts…) pueden ir en otros módulos de esta carpeta.

local Parques = require(script.Parent.Parques)
local Plaza = require(script.Parent.Plaza)
local Huertos = require(script.Parent.Huertos)
local Lago = require(script.Parent.Lago)

local Sitios = {}

-- Presupuesto de piezas (plan, apartado 5)
Sitios.MaxPartsPerSite = 600

function Sitios.build(world: Instance): { [string]: any }
	local out = {}
	local function step(name: string, fn: () -> any)
		local ok, result = pcall(fn)
		if ok then
			out[name] = result
		else
			warn(("[ZonasVerdes] %s: %s"):format(name, tostring(result)))
		end
	end
	step("Parques", function()
		return Parques.build(world)
	end)
	step("Plaza", function()
		return Plaza.build(world)
	end)
	step("Huertos", function()
		return Huertos.build(world)
	end)
	step("Lago", function()
		return Lago.build(world)
	end)
	step("Camping", function()
		return Lago.camping(world)
	end)
	return out
end

return Sitios
