-- Ground: rayos hacia abajo que solo aceptan SUELO DE VERDAD.
-- Muchos sistemas buscan el suelo con un rayo (dónde poner a un personaje, una flecha del GPS, un
-- coche, un animal…). Si el rayo se queda con lo primero que toca, acaban encima del techo de un
-- autobús, de un coche aparcado, de la cabeza de alguien o de una hoja de árbol. Aquí se salta todo
-- eso y se vuelve a lanzar el rayo hasta dar con suelo.
--
--   Ground.isGround(hit)                 ¿Este impacto es suelo?
--   Ground.cast(origin, direction, params, maxSkips?)  Como workspace:Raycast, pero saltando lo que
--                                         no es suelo (añade cada cosa saltada a la lista de params)
--   Ground.castVisible(origin, direction, params, maxSkips?)  Igual, pero solo SUELO QUE SE VE: para
--                                         poner de pie (o sentar) a la gente y a los animales.
--   Ground.hidden(part)                  ¿Pieza escondida? (invisible, cascarón de un recambio de malla,
--                                         choque invisible de un árbol)
--   Ground.seatOk(seat)                  ¿Ese asiento sigue de verdad en el mundo (y se ve)?
--
-- Por qué hay dos: los recambios de mallas (World/CityAssets, InteriorProps, MeshLibrary) esconden la
-- pieza de bloques de debajo (Transparency = 1) pero la dejan chocando, y añaden cajas de choque
-- invisibles (troncos, la valla de obras, el instituto). Para un jugador eso es suelo (choca con ello),
-- pero un NPC anclado puesto encima se queda FLOTANDO sobre la acera: la gente y los animales solo
-- pisan lo que se ve.

local Ground = {}

-- Carpetas del mundo con vehículos en marcha (autobuses, coches de jugadores, tráfico)
local VEHICLE_FOLDERS = { "Buses", "Rides", "Traffic", "AmbientTraffic" }

-- Etiquetas de las piezas de bloques que un recambio de malla ha escondido (CityAssetsKit.ShellTag,
-- InteriorProps "PropShell")
Ground.ShellTags = { "BuildingShell", "PropShell" }
-- Lo que no es suelo para una persona aunque se vea y choque (copas, arbustos, flores, troncos)
Ground.NotFloor = { Leaves = true, Bush = true, Flower = true, Trunk = true, TrunkMesh = true, Branch = true }

function Ground.hidden(part: Instance): boolean
	if not part:IsA("BasePart") or part:IsA("Terrain") then
		return false
	end
	local p = part :: BasePart
	if (tonumber(p.Transparency) or 0) >= 0.95 then
		return true
	end
	for _, tag in Ground.ShellTags do
		if p:HasTag(tag) then
			return true
		end
	end
	return p:GetAttribute("Collider") == true
end

-- ¿Qué hay que saltar? Devuelve lo más grande que se puede ignorar entero (el modelo o la pieza).
-- visible: además, lo escondido (Ground.hidden) y lo que no se pisa aunque choque (Ground.NotFloor)
function Ground.skipOf(part: Instance, visible: boolean?): Instance?
	if part:IsA("BasePart") then
		if part.CanCollide == false then
			return part -- (hojas, marcas, adornos: no se pisan. Un suelo invisible que sí choca, sí cuenta)
		end
		if visible and (Ground.hidden(part) or Ground.NotFloor[part.Name]) then
			return part -- (para la gente y los animales, no: se quedaban flotando encima)
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

function Ground.isGround(hit: RaycastResult?, visible: boolean?): boolean
	return hit ~= nil and Ground.skipOf(hit.Instance, visible) == nil
end

function Ground.cast(origin: Vector3, direction: Vector3, params: RaycastParams?, maxSkips: number?, visible: boolean?): RaycastResult?
	local p = params
	if not p then
		p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
	end
	local hit = workspace:Raycast(origin, direction, p)
	for _ = 1, maxSkips or 8 do
		local skip = hit and Ground.skipOf(hit.Instance, visible)
		if not skip then
			break
		end
		local list = p.FilterDescendantsInstances
		table.insert(list, skip)
		p.FilterDescendantsInstances = list
		hit = workspace:Raycast(origin, direction, p)
	end
	if visible and hit and Ground.skipOf(hit.Instance, true) then
		return nil -- (se acabaron los intentos sin dar con suelo: mejor nada que la copa de un árbol)
	end
	return hit
end

-- Solo suelo que se ve: para poner a una persona o a un animal (nunca encima de una caja invisible)
function Ground.castVisible(origin: Vector3, direction: Vector3, params: RaycastParams?, maxSkips: number?): RaycastResult?
	return Ground.cast(origin, direction, params, maxSkips or 12, true)
end

-- ¿Ese asiento sigue ahí de verdad? (no lo ha borrado ni escondido un recambio). El cascarón de un
-- mueble cambiado por su malla vale: la malla está en su sitio. Si no vale, quien se sentaba se levanta.
function Ground.seatOk(seat: Instance?): boolean
	if seat == nil or not seat:IsA("BasePart") then
		return false
	end
	local s = seat :: BasePart
	if s.Parent == nil or not s:IsDescendantOf(workspace) then
		return false
	end
	if (tonumber(s.Transparency) or 0) >= 0.95 then
		for _, tag in Ground.ShellTags do
			if s:HasTag(tag) then
				return true
			end
		end
		return false
	end
	return true
end

return Ground
