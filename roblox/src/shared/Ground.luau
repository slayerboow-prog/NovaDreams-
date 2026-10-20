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

---------------------------------------------------------------------
-- Sitios para sentarse (v124: «sentados en un banco mal situado, en el suelo»)
---------------------------------------------------------------------
-- La gente de la calle (CrowdService, PlaceLifeService) se sienta en un extremo de un banco con
-- Npc.sit. Antes valía cualquier pieza «Seat» de un modelo con la etiqueta Bench: también una tumbona
-- (más larga en Z que en X: el extremo «a lo largo» caía en la arena y miraba al respaldo) o un banco
-- hundido, flotando o tapado. Ahora un sitio vale solo si:
--   * el asiento está derecho (su arriba es el arriba del mundo) y es un banco: largo en X, de
--     SeatMinLength o más (el extremo donde se sienta queda encima del asiento);
--   * debajo hay suelo de verdad que se ve (Ground.castVisible, sin contar el propio banco) y la cara
--     de arriba del asiento está entre SeatMinHeight y SeatMaxHeight por encima: ni hundido en la acera
--     ni flotando;
--   * encima del asiento, hasta SeatHeadroom, no hay nada (ni una pared ni un tejado);
--   * delante (donde van los pies) también hay suelo, a la misma altura (± SeatFeetStep).

Ground.SeatMinHeight = 1.0
Ground.SeatMaxHeight = 3.4
Ground.SeatMinLength = 2.2
Ground.SeatHeadroom = 3
Ground.SeatFeetStep = 1.0
Ground.SeatEnd = 1.1 -- de un extremo del banco a donde se sienta
Ground.SitLift = 1.35 -- de la cara del asiento a la raíz de un R15 de tamaño normal (HipHeight 2)

-- La cuenta pura: ¿vale este asiento? (ok, motivo si no)
--   up: el arriba del asiento (Y de su UpVector); size: su tamaño; top: Y de su cara de arriba
--   floor: Y del suelo debajo (nil si no hay); above: Y de lo más alto que hay encima hasta la holgura
--   (nil si nada); feet: Y del suelo delante (nil si no hay)
function Ground.seatFits(up: number, size: Vector3, top: number, floor: number?, above: number?, feet: number?): (boolean, string?)
	if up < 0.95 then
		return false, "Tumbado"
	end
	if size.X < Ground.SeatMinLength or size.Z > size.X then
		return false, "NoEsBanco"
	end
	if above ~= nil then
		return false, "Tapado"
	end
	if floor == nil then
		return false, "SinSuelo"
	end
	local h = top - floor
	if h < Ground.SeatMinHeight then
		return false, "Hundido"
	end
	if h > Ground.SeatMaxHeight then
		return false, "Flotando"
	end
	if feet == nil or math.abs(feet - floor) > Ground.SeatFeetStep then
		return false, "SinSitioPies"
	end
	return true, nil
end

-- Donde se sienta alguien en un banco: un extremo (side = 1 derecha, -1 izquierda), a lo largo de su
-- largo (X), sobre la cara de arriba. Devuelve una «pieza» { CFrame, Size } para Npc.sit
function Ground.seatSpot(seat: BasePart, side: number): { CFrame: CFrame, Size: Vector3 }
	local along = math.max(0, seat.Size.X / 2 - Ground.SeatEnd)
	return { CFrame = seat.CFrame * CFrame.new(side * along, 0, 0), Size = seat.Size }
end

-- Lo que sube la raíz de quien se sienta sobre la cara del asiento, a su tamaño (R15 escalado con
-- ScaleTo: su HipHeight crece con él; un R6 —HipHeight 0— como uno normal)
function Ground.sitLift(hipHeight: number?): number
	local h = tonumber(hipHeight) or 0
	if h <= 0.2 then
		return Ground.SitLift
	end
	return Ground.SitLift * math.clamp(h / 2, 0.4, 2)
end

-- Con el mundo de verdad (rayos hacia abajo): ¿se puede sentar alguien en este asiento?
-- (ok, motivo, altura del asiento sobre el suelo)
function Ground.seatPlaced(seat: Instance?): (boolean, string?, number?)
	if not Ground.seatOk(seat) then
		return false, "NoEsta", nil
	end
	local s = seat :: BasePart
	local cf, size = s.CFrame, s.Size
	local top = cf.Position.Y + size.Y / 2
	local bench = s:FindFirstAncestorOfClass("Model")
	local function down(at: Vector3): RaycastResult?
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { if bench and bench ~= workspace then bench else s }
		return Ground.castVisible(Vector3.new(at.X, top + Ground.SeatHeadroom, at.Z), Vector3.new(0, -(Ground.SeatHeadroom + Ground.SeatMaxHeight + 6), 0), params)
	end
	-- (el centro del asiento y el extremo donde se sienta: los dos)
	local floor: number?, above: number? = nil, nil
	for _, x in { 0, size.X / 2 - Ground.SeatEnd } do
		local p = cf * CFrame.new(x, 0, 0)
		local hit = down(p.Position)
		if hit then
			if hit.Position.Y > top + 0.15 then
				above = hit.Position.Y
			else
				floor = if floor then math.max(floor, hit.Position.Y) else hit.Position.Y
			end
		end
	end
	local feetHit = down((cf * CFrame.new(size.X / 2 - Ground.SeatEnd, 0, -(size.Z / 2 + 1))).Position)
	local feet = if feetHit and feetHit.Position.Y <= top + 0.15 then feetHit.Position.Y else nil
	local ok, why = Ground.seatFits(cf.UpVector.Y, size, top, floor, above, feet)
	return ok, why, if floor then top - floor else nil
end

return Ground
