-- Ground: rayos hacia abajo que solo aceptan SUELO DE VERDAD.
-- Muchos sistemas buscan el suelo con un rayo (dónde poner a un personaje, una flecha del GPS, un
-- coche, un animal…). Si el rayo se queda con lo primero que toca, acaban encima del techo de un
-- autobús, de un coche aparcado, de la cabeza de alguien o de una hoja de árbol. Aquí se salta todo
-- eso y se vuelve a lanzar el rayo hasta dar con suelo.
--
--   Ground.isGround(hit)                 ¿Este impacto es suelo?
--   Ground.cast(origin, direction, params, maxSkips?)  Como workspace:Raycast, pero saltando lo que
--                                         no es suelo (añade cada cosa saltada a la lista de params)

local Ground = {}

-- Carpetas del mundo con vehículos en marcha (autobuses, coches de jugadores, tráfico)
local VEHICLE_FOLDERS = { "Buses", "Rides", "Traffic", "AmbientTraffic" }

-- ¿Qué hay que saltar? Devuelve lo más grande que se puede ignorar entero (el modelo o la pieza)
function Ground.skipOf(part: Instance): Instance?
	if part:IsA("BasePart") then
		if part.CanCollide == false then
			return part -- (hojas, marcas, adornos: no se pisan. Un suelo invisible que sí choca, sí cuenta)
		end
	end
	for _, name in VEHICLE_FOLDERS do
		local folder = workspace:FindFirstChild(name)
		if folder and part:IsDescendantOf(folder) then
			return folder
		end
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model and model ~= workspace do
		if model:FindFirstChildOfClass("Humanoid") or model.Name == "ParkedCar" or model:GetAttribute("Drivable") or model:GetAttribute("BusLine") then
			return model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function Ground.isGround(hit: RaycastResult?): boolean
	return hit ~= nil and Ground.skipOf(hit.Instance) == nil
end

function Ground.cast(origin: Vector3, direction: Vector3, params: RaycastParams?, maxSkips: number?): RaycastResult?
	local p = params
	if not p then
		p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
	end
	local hit = workspace:Raycast(origin, direction, p)
	for _ = 1, maxSkips or 8 do
		local skip = hit and Ground.skipOf(hit.Instance)
		if not skip then
			break
		end
		local list = p.FilterDescendantsInstances
		table.insert(list, skip)
		p.FilterDescendantsInstances = list
		hit = workspace:Raycast(origin, direction, p)
	end
	return hit
end

return Ground
