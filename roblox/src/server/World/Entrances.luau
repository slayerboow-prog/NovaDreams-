-- Entrances: qué edificios del mapa se pueden visitar por dentro (InteriorService) y dónde está su
-- puerta. Solo mira el modelo (nombre, padre y piezas): no construye nada, así las pruebas de Lune
-- (scripts/test-interiors.luau, con el mapa construido) usan exactamente la misma regla que el juego.
--
--   Entrances.classify(model)        -> tipo de la sala de la planta baja, título y plantas de arriba
--                                       (nil = no es un edificio visitable)
--   Entrances.doorPart(model)        -> la pieza de la puerta (ShopDoor, Door, DoorPanel o FakeDoor)
--   Entrances.doorOut(part, center)  -> hacia dónde da esa puerta (atributo DoorOut si lo tiene; si
--                                       no, del centro del edificio hacia la puerta)
--   Entrances.isHome(kind, upper)    -> ¿es una vivienda (casa, villa o edificio de pisos)?
--
-- Convención para los kits (World/Kit/*): la puerta de verdad de un edificio visitable es una pieza
-- hija directa llamada "Door" (o ShopDoor/DoorPanel). Si la puerta no está en la fachada que mira
-- al centro del edificio (p. ej. la villa, con la piscina delante), se le pone el atributo
-- DoorOut = hacia fuera (Vector3, en planta).

local Entrances = {}

local function hasChild(model: Instance, name: string): BasePart?
	local child = model:FindFirstChild(name)
	return if child and child:IsA("BasePart") then child else nil
end
Entrances.hasChild = hasChild

-- Lo que pone el cartel del edificio (tiendas: su interior va a juego)
function Entrances.signText(model: Instance): string?
	local sign = model:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	return if label and label:IsA("TextLabel") then label.Text else nil
end

-- Tipo de interior, título y plantas de arriba (nil = este modelo no es un edificio visitable)
function Entrances.classify(model: Model): (string?, string?, string?)
	local name, parent = model.Name, (model.Parent and model.Parent.Name or "")
	if name == "Casa" and (parent == "Manzana_Casas" or parent == "Vivienda") then
		return "Casa", "🏠 Casa", nil
	elseif name == "Villa" then
		return "Villa", "🏡 Villa", nil
	elseif name == "Bloque" then
		if parent == "Manzana_Comercio" then
			return "Local", "🏬 Comercio y viviendas", "Piso"
		elseif parent == "Manzana_Campus" then
			return "Aula", "🎓 Facultad", "Aula"
		elseif parent == "Manzana_Towers" then
			return "OficinaLobby", "🏢 Oficinas", "Oficina"
		elseif parent == "Manzana_Downtown" then
			return "Portal", "🏢 Viviendas y oficinas", "Piso"
		elseif parent == "Manzana_Residencia" or parent == "Manzana_Pisos" then
			return "Portal", "🏢 Edificio de viviendas", "Piso"
		end
	elseif name == "Rascacielos" or name == "Oficinas" then
		return "OficinaLobby", "🏙 Oficinas", "Oficina"
	elseif name == "Nave" then
		return "Nave", "🏭 Nave industrial", nil
	elseif name == "Taller" then
		return "Taller", "🔧 Taller mecánico", nil
	elseif name == "Ocio_Local" then
		return "Ocio", "🎶 Local de ocio", nil
	elseif name == "TorreValmar" then
		return "OficinaLobby", "🏙 Torre de Valmar", "Oficina"
	elseif name == "Ayuntamiento" then
		return "Ayuntamiento", "🏛 Ayuntamiento", nil
	elseif name == "Museo" then
		return "Museo", "🖼 Museo de Valmar", nil
	elseif name == "Teatro" then
		return "Teatro", "🎭 Teatro Principal", nil
	elseif name == "EstacionCentral" then
		return "Estacion", "🚆 Estación Central", nil
	elseif name == "GranCentroComercial" then
		return "CentroComercial", "🛍 Centro Comercial Valmar", "Local"
	elseif name == "Edificio" or name:match("^Edificio_%d+$") then
		if hasChild(model, "ShopDoor") then
			-- Tienda de la calle con su puerta de cristal (Kit/Decor): se entra a su interior
			local shop = Entrances.signText(model)
			return "Local", "🏬 " .. (if shop and shop ~= "" then shop else "Comercio"), "Piso"
		end
		if hasChild(model, "GarageDoor") and not hasChild(model, "DoorPanel") then
			return "Nave", "🚒 Cocheras", nil
		elseif hasChild(model, "DoorPanel") then
			return "Portal", "🏢 Edificio de viviendas", "Piso"
		end
		-- Planta baja de verdad (tienda, colegio, hospital…): solo el ascensor
		local civic = parent == "Colegio" or parent == "Hospital" or parent == "CentroSalud" or parent == "Policia" or parent == "Facultad" or parent == "CentroComercial"
		return "Walk", "🏢 Edificio", if parent == "Facultad" or parent == "Colegio" then "Aula" elseif civic then "Oficina" else "Piso"
	end
	return nil, nil, nil
end

-- La pieza de la puerta de verdad (si el kit la tiene)
function Entrances.doorPart(model: Model): BasePart?
	return hasChild(model, "ShopDoor") or hasChild(model, "Door") or hasChild(model, "DoorPanel") or hasChild(model, "FakeDoor")
end

-- Hacia dónde da la puerta (en planta, unitario): el atributo DoorOut del kit; si no lo tiene, del
-- centro del edificio hacia la puerta (nil si la puerta está en el centro: que decida quien llama)
function Entrances.doorOut(part: BasePart, center: Vector3): Vector3?
	local facing = part:GetAttribute("DoorOut")
	if typeof(facing) == "Vector3" then
		local flat = Vector3.new(facing.X, 0, facing.Z)
		if flat.Magnitude > 0.1 then
			return flat.Unit
		end
	end
	local at = part.CFrame.Position
	local offset = Vector3.new(at.X - center.X, 0, at.Z - center.Z)
	return if offset.Magnitude > 0.5 then offset.Unit else nil
end

-- Viviendas: casas y villas (una por edificio) y los edificios con pisos arriba
function Entrances.isHome(kind: string?, upper: string?): boolean
	return kind == "Casa" or kind == "Villa" or upper == "Piso" or upper == "Dorm"
end

return Entrances
