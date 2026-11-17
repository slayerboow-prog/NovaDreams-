-- FarmDistricts: los DISTRITOS DE CAZA (17-11-2026, petición del dueño: «reduce Valmar a un solo distrito
-- central y el resto de distritos, que sean los de farmeo»).
--
-- prune(world): al montar el mapa (TownBuilder.build, antes del relieve) quita todo lo construido en los
-- distritos con Farm (shared/CityPlan.Districts: Oeste, Sur, Este y Universitario): barrios, manzanas, calles,
-- farolas, paradas… Se queda lo que sirve para cruzarlos y lo que no es de un barrio:
--   * las carreteras principales (Ronda, avenidas, diagonales y puentes: MainRoads),
--   * el metro, el tren de Cercanías, el aeropuerto y el aeródromo, la cárcel y el puerto (con la marina).
-- Sin azar (no cambia nada de lo demás del mapa). Va de arriba abajo: un modelo entero dentro de un distrito de
-- caza se quita; uno que pisa también el Distrito Central se mira por dentro, pieza a pieza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local FarmDistricts = {}

-- Lo que nunca se quita (nombre exacto del modelo)
FarmDistricts.Keep = {
	MainRoads = true,
	Metro = true,
	Cercanias = true,
	Aeropuerto = true,
	Aerodromo = true,
	CentroPenitenciario = true,
	Puerto = true,
	PuertoDarsena = true,
	Marina = true,
	Faro = true,
	Mirador = true,
	PuertoEspacial = true,
	PortalPuertoEspacial = true,
	MonteSilencio = true, -- (el Monte del Silencio de la Saga: Kit/Wilds, junto al distrito de caza del Oeste)
}

type Box = { X0: number, X1: number, Z0: number, Z1: number }

-- La caja (en planta) de cada modelo y carpeta, de abajo arriba y una sola vez
local function boxes(root: Instance): { [Instance]: Box }
	local out: { [Instance]: Box } = {}
	local function visit(inst: Instance): Box?
		local box: Box? = nil
		local function add(b: Box?)
			if not b then
				return
			end
			if not box then
				box = { X0 = b.X0, X1 = b.X1, Z0 = b.Z0, Z1 = b.Z1 }
			else
				local cur = box :: Box
				cur.X0 = math.min(cur.X0, b.X0)
				cur.X1 = math.max(cur.X1, b.X1)
				cur.Z0 = math.min(cur.Z0, b.Z0)
				cur.Z1 = math.max(cur.Z1, b.Z1)
			end
		end
		if inst:IsA("BasePart") then
			local p = (inst :: BasePart).CFrame.Position
			add({ X0 = p.X, X1 = p.X, Z0 = p.Z, Z1 = p.Z })
		end
		for _, child in inst:GetChildren() do
			add(visit(child))
		end
		if box and (inst:IsA("Model") or inst:IsA("Folder")) then
			out[inst] = box
		end
		return box
	end
	visit(root)
	return out
end

-- ¿Está toda la caja dentro de distritos de caza? (las cuatro esquinas y el centro)
local function allFarm(b: Box): boolean
	for _, p in { { b.X0, b.Z0 }, { b.X1, b.Z0 }, { b.X0, b.Z1 }, { b.X1, b.Z1 }, { (b.X0 + b.X1) / 2, (b.Z0 + b.Z1) / 2 } } do
		if not CityPlan.farmAt(p[1], p[2]) then
			return false
		end
	end
	return true
end
local function anyFarm(b: Box): boolean
	for _, p in { { b.X0, b.Z0 }, { b.X1, b.Z0 }, { b.X0, b.Z1 }, { b.X1, b.Z1 }, { (b.X0 + b.X1) / 2, (b.Z0 + b.Z1) / 2 } } do
		if CityPlan.farmAt(p[1], p[2]) then
			return true
		end
	end
	-- (una caja grande puede tener un distrito de caza en medio sin tocarlo en las esquinas)
	return (b.X1 - b.X0) > 900 or (b.Z1 - b.Z0) > 900
end

-- Devuelve cuántos modelos y piezas sueltas ha quitado
function FarmDistricts.prune(world: Instance): { [string]: number }
	local stats = { Models = 0, Parts = 0 }
	local box = boxes(world)
	local function visit(inst: Instance)
		for _, child in inst:GetChildren() do
			if FarmDistricts.Keep[child.Name] then
				continue
			end
			if child:IsA("BasePart") then
				local p = (child :: BasePart).CFrame.Position
				if CityPlan.farmAt(p.X, p.Z) then
					child:Destroy()
					stats.Parts += 1
				end
			elseif child:IsA("Model") or child:IsA("Folder") then
				local b = box[child]
				if b then
					-- (un modelo pequeño entero en un distrito de caza: fuera de una vez)
					if (b.X1 - b.X0) < 900 and (b.Z1 - b.Z0) < 900 and allFarm(b) then
						child:Destroy()
						stats.Models += 1
					elseif anyFarm(b) then
						visit(child)
					end
				end
			end
		end
	end
	visit(world)
	-- El borde: los detalles de la calle (bancos, papeleras…) y el ocio de fuera de los distritos que se quedan
	-- sin su acera o sin su calle al quitar la de al lado (se quedaban flotando o aislados)
	local function nearFarm(x: number, z: number, r: number): boolean
		for _, o in { { 0, 0 }, { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r } } do
			if CityPlan.farmAt(x + o[1], z + o[2]) then
				return true
			end
		end
		return false
	end
	-- (los bancos de la calle y las zonas de ocio: estén donde estén dentro del mapa)
	for _, child in world:GetDescendants() do
		if child:IsA("Model") and child.Parent then
			local bench = child.Name == "BancoCalle"
			local leisure = child.Name:sub(1, 5) == "Ocio_"
			if bench or leisure then
				local b = box[child]
				if b and nearFarm((b.X0 + b.X1) / 2, (b.Z0 + b.Z1) / 2, if bench then 60 else 200) then
					child:Destroy()
					stats.Models += 1
				end
			end
		end
	end
	return stats
end

return FarmDistricts
