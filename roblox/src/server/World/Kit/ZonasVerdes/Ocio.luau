-- Ocio (zonas verdes, fase 1-2 del plan: docs/zonas-verdes/plan.md): construye los sitios de ocio.
--   Feria    zona 7   Mercadillo y Recinto de Fiestas (Mercadillo)
--   Playa    zona 6   Vóley Playa de Levante y chiringuitos (PlayaLevante)
--   Campus   zona 8   Polideportivo del Campus (PolideportivoCampus)
--   Karting  zona 13  Karting de San Roque (Karting)
--   Skate    zona 10  Skatepark de la Ribera (Skatepark)
-- Lo llama TownBuilder al final (sin azar: no cambia nada más del mapa). Cada sitio es un Model en
-- Town/ZonasOcio; si uno falla, los demás se construyen igual. El juego de cada sitio lo ponen
-- FeriaService, ZonasDeporteService, KartService y SkateService.

local Ocio = {}

Ocio.SITES = {
	{ Id = "Feria", Module = "Mercadillo" },
	{ Id = "Playa", Module = "PlayaLevante" },
	{ Id = "Campus", Module = "PolideportivoCampus" },
	{ Id = "Karting", Module = "Karting" },
	{ Id = "Skate", Module = "Skatepark" },
}

-- Construye un sitio (por su Id de shared/OcioSitios) dentro de parent. Devuelve el modelo o nil.
function Ocio.buildSite(id: string, parent: Instance): Model?
	for _, s in Ocio.SITES do
		if s.Id == id then
			local ok, result = pcall(function()
				return require((script.Parent :: any)[s.Module]).build(parent)
			end)
			if not ok then
				warn(("[ZonasOcio] %s: %s"):format(id, tostring(result)))
				return nil
			end
			result:SetAttribute("OcioSite", id)
			return result
		end
	end
	return nil
end

function Ocio.build(world: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "ZonasOcio"
	folder.Parent = world
	for _, s in Ocio.SITES do
		Ocio.buildSite(s.Id, folder)
	end
	return folder
end

return Ocio
