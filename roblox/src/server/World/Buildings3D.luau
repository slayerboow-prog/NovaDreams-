-- Buildings3D: los bloques de pisos y los rascacielos de la ciudad (Kit/Lite: cajas hechas por
-- código) cambian su fachada por edificios 3D de verdad (MeshPart + SurfaceAppearance PBR) del pack
-- OFICIAL de Roblox "Modular Building Kit – Modern City" (docs/modelos-oficiales-2.md).
--
--   * Al arrancar el servidor (Main, en un hilo aparte) carga una vez el kit y el "Modern City
--     Materials Pack" (AssetService:LoadAssetAsync; si falla, InsertService:LoadAsset). Del kit se
--     quedan los 11 edificios ya montados (PrefabBuildings: A–K y "Model"), sin scripts (el H trae
--     8), sin el cartel del pack (Bldg_Addon_Billboard_A), sin luces ni sonidos, anclados; quedan como
--     plantillas en ServerStorage.Buildings3D, con su planta (ancho de fachada × fondo), su altura,
--     sus piezas y hacia dónde mira su fachada.
--   * Los MaterialVariant de los dos packs van a MaterialService con el prefijo "ModernCity_" (no
--     chocan con los nuestros de shared/Textures) y las piezas de las plantillas que los usaban
--     apuntan al nombre nuevo. No se cambia ningún Override global de materiales.
--   * Qué se cambia: los "Bloque" de las manzanas de pisos, centro, residencia, torres y comercio y
--     los "Rascacielos". NO: casas, villas, hoteles (recepción jugable), talleres, locales de ocio,
--     facultades (residencias e historia), ni los edificios de Kit/Building (plantas bajas que se
--     recorren), ni nada que no sea de Kit/Lite.
--   * Esos bloques se visitan por dentro con el cartel "Entrar" de InteriorService, pero su interior
--     se monta aparte (en el cielo): lo de la calle es solo la fachada. Por eso el modelo se queda
--     (mismo nombre, padre, atributos, etiquetas, cartel con el nombre de la tienda y pieza Door, que
--     dice dónde está la puerta) y solo cambia lo que se ve. Además se espera a que InteriorService
--     haya mirado todos los edificios (atributo InteriorsScanned del workspace): las claves de las
--     viviendas (las casas compradas) salen de la caja del edificio y no deben moverse.
--   * Cómo se coloca: la fachada del bloque es la cara de su puerta (o escaparate, toldo, ventanas
--     de delante, marquesina); si no tiene, la que da a la calle más cercana. Se elige el prefab cuya
--     proporción (ancho de fachada / fondo / alto) encaja mejor, o 2–3 en fila si el bloque es largo,
--     escalado con Model:ScaleTo para caber DENTRO de la huella del bloque (un 2 % más pequeño: nunca
--     sale a la acera), con su fachada pegada a la del bloque mirando a la calle y apoyado en el
--     suelo del bloque. Si ninguno encaja (demasiado bajo, demasiado escalado…), se queda el bloque.
--   * Choque: las MeshPart del prefab no chocan ni bloquean rayos; cada prefab lleva una caja
--     invisible de su tamaño (BuildingCollider). El cuerpo del bloque (Body/Core) y su puerta se
--     quedan invisibles y sin choque, con la etiqueta BuildingShell.
--   * Gráficos Bajo (Controllers/MaterialDetail): se esconden las mallas (etiqueta BuildingMesh) y se
--     enseña la caja de siempre (BuildingShell): no pesa más que antes.
--   * Rendimiento: topes de prefabs y de piezas (MaxCopies, MaxParts), primero los del centro y de las
--     avenidas; sombras solo en lo grande, RenderFidelity Automatic y el modelo sigue cargándose
--     entero por zonas (Atomic, como lo dejó Builder.streamable).
--   * Si la carga falla (o en Lune, sin AssetService ni InsertService) no se toca nada.

local MeshLibrary = require(script.Parent.MeshLibrary)

local Buildings3D = {}

Buildings3D.Packs = {
	Kit = { Id = 13168370735, Name = "Modular Building Kit – Modern City" },
	Materials = { Id = 13168345645, Name = "Modern City Materials Pack" },
}
-- Prefabs que se usan (los 11 de PrefabBuildings; no hay "D")
Buildings3D.Prefabs = { "A", "B", "C", "E", "F", "G", "H", "I", "J", "K", "Model" }
-- Fachada de cada prefab, si se sabe ("-Z", "+Z", "-X", "+X"). Vacío: se averigua sola (frontOf) y
-- se escribe en la consola del servidor; si en el juego alguno sale de espaldas, se pone aquí.
Buildings3D.Front = {} :: { [string]: string }
-- Lo que se borra de lo cargado: el cartel del pack
Buildings3D.Junk = { Bldg_Addon_Billboard_A = true, RobloxBillboard = true }
-- Qué edificios se cambian: nombre del modelo -> manzanas (nombre del padre) donde sí
Buildings3D.Targets = {
	Bloque = {
		Manzana_Downtown = true,
		Manzana_Pisos = true,
		Manzana_Residencia = true,
		Manzana_Towers = true,
		Manzana_Comercio = true,
	},
	Rascacielos = { Manzana_Towers = true },
}
Buildings3D.VariantPrefix = "ModernCity_"

-- Topes (rendimiento): los prefabs son pesados (todo el kit ~800 000 triángulos, 100–500 piezas cada
-- edificio). Se cambian antes los del centro y los de las avenidas; los demás se quedan como estaban.
Buildings3D.MaxCopies = 100 -- prefabs colocados en total
Buildings3D.MaxParts = 30000 -- piezas de malla en total
Buildings3D.Batch = 3 -- bloques por tanda (luego task.wait)
Buildings3D.MaxRow = 3 -- prefabs en fila como mucho en un bloque largo
Buildings3D.MinScale = 0.6 -- más pequeño, las puertas se quedan de juguete
Buildings3D.MaxScale = 1.4 -- más grande, las ventanas parecen de gigante
Buildings3D.MinFill = 0.75 -- el prefab tiene que llenar al menos esto del ancho de la fachada
Buildings3D.HeightRange = { 0.55, 1.9 } -- altura del prefab / altura del bloque permitida
Buildings3D.Fit = 0.98 -- (un pelín más pequeño que la huella: nunca sale a la acera)
Buildings3D.ShadowSize = 10 -- solo dan sombra las piezas que miden al menos esto
Buildings3D.ScanWait = 180 -- segundos esperando a InteriorService como mucho
Buildings3D.Center = Vector3.new(0, 0, 0) -- Valmar Centro (shared/CityPlan)

-- Piezas de Kit/Lite que se van (lo que pinta la caja); se queda lo demás
local LITE_PARTS = {
	Windows = true, BackWindows = true, SideWindows = true, Mullion = true, Balcony = true, Cornice = true,
	RoofUnit = true, StonePlinth = true, Sill = true, Awning = true, ShopGlass = true, DoorJamb = true,
	DoorLintel = true, DoorStep = true, GableWall = true, Gutter = true, Downpipe = true, RidgeTiles = true,
	RoofTiles = true, Roof = true, Verge = true, Band = true, Antenna = true, Canopy = true, OfficeLights = true,
}
local SHELLS = { Body = true, Core = true } -- el cuerpo: se queda invisible (Bajo: se ve)
local DOORS = { Door = true, ShopDoor = true, DoorPanel = true, FakeDoor = true } -- InteriorService
-- Por dónde se sabe la fachada de un bloque (en este orden)
local HINTS = { "Door", "ShopDoor", "DoorPanel", "FakeDoor", "ShopGlass", "Canopy", "Awning", "Windows", "OfficeLights", "Sign" }

export type Template = {
	Name: string,
	Model: Instance,
	Foot: Vector3, -- centro de abajo de la fachada (espacio de la plantilla)
	Front: Vector3, -- hacia dónde mira la fachada (espacio de la plantilla, un eje)
	FW: number, -- ancho de la fachada
	FD: number, -- fondo
	H: number, -- alto
	Parts: number,
	Why: string, -- cómo se ha sabido la fachada (para la consola)
}
export type Info = {
	CFrame: CFrame, -- centro de abajo de la huella; LookVector = fachada (hacia la calle)
	W: number, -- ancho de la fachada
	D: number, -- fondo
	H: number, -- alto del cuerpo
	Why: string,
}
export type Slot = { Template: Template, Scale: number, Offset: number, Score: number }
type Segment = { A: Vector3, B: Vector3, Kind: string? }

local parts = function(root: Instance): { BasePart }
	local list = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end
local bounds = MeshLibrary.bounds

-- Giro (en Y) que lleva el eje -Z a "v" (como Builder.facing)
local function yawOf(v: Vector3): number
	return math.atan2(-v.X, -v.Z)
end

local AXES = {
	["-Z"] = Vector3.new(0, 0, -1),
	["+Z"] = Vector3.new(0, 0, 1),
	["-X"] = Vector3.new(-1, 0, 0),
	["+X"] = Vector3.new(1, 0, 0),
}
local AXIS_ORDER = { "-Z", "+Z", "-X", "+X" }

-- Eje (de los 4 horizontales) más parecido a "v"
local function snap(v: Vector3): Vector3
	if math.abs(v.X) > math.abs(v.Z) then
		return Vector3.new(if v.X > 0 then 1 else -1, 0, 0)
	end
	return Vector3.new(0, 0, if v.Z >= 0 then 1 else -1)
end

---------------------------------------------------------------------
-- Plantillas
---------------------------------------------------------------------

local FRONT_WORDS = { "door", "entrance", "entry", "awning", "storefront", "store", "shop", "sign", "canopy", "marquee", "display", "lobby" }
local BACK_WORDS = { "fireescape", "fire_escape", "escape", "ladder", "dumpster", "hvac", "acunit", "ac_unit", "airconditioner", "vent", "pipe" }

local function hasWord(name: string, words: { string }): boolean
	local lower = string.lower(name)
	for _, w in words do
		if string.find(lower, w, 1, true) then
			return true
		end
	end
	return false
end

-- Hacia dónde mira la fachada de un prefab (en su espacio): la cara con puertas, toldos,
-- escaparates y carteles abajo; las escaleras de incendios y los aparatos de aire restan. Si no se
-- sabe, su eje -Z (el "delante" de Roblox). Devuelve también el porqué.
function Buildings3D.frontOf(name: string, list: { BasePart }, lo: Vector3, hi: Vector3): (Vector3, string)
	local forced = Buildings3D.Front[name]
	if forced and AXES[forced] then
		return AXES[forced], "fijada " .. forced
	end
	local score = { ["-Z"] = 0, ["+Z"] = 0, ["-X"] = 0, ["+X"] = 0 }
	local size = hi - lo
	local groundTop = lo.Y + math.max(size.Y * 0.2, 14)
	for _, p in list do
		local plo, phi = bounds({ p })
		local c = (plo + phi) / 2
		-- (cerca de cada cara: a menos del 15 % del ancho o fondo)
		local near = {
			["-Z"] = (plo.Z - lo.Z) <= size.Z * 0.15,
			["+Z"] = (hi.Z - phi.Z) <= size.Z * 0.15,
			["-X"] = (plo.X - lo.X) <= size.X * 0.15,
			["+X"] = (hi.X - phi.X) <= size.X * 0.15,
		}
		local front = hasWord(p.Name, FRONT_WORDS) or (p.Parent ~= nil and hasWord(p.Parent.Name, FRONT_WORDS))
		local back = hasWord(p.Name, BACK_WORDS) or (p.Parent ~= nil and hasWord(p.Parent.Name, BACK_WORDS))
		local glass = c.Y <= groundTop and (p.Material == Enum.Material.Glass or hasWord(p.Name, { "glass", "window" }))
		for axis, yes in near do
			if yes then
				if front then
					score[axis] += 3
				elseif back then
					score[axis] -= 2
				elseif glass then
					score[axis] += 1
				end
			end
		end
	end
	local best, bestScore, second = "-Z", -math.huge, -math.huge
	for _, axis in AXIS_ORDER do
		if score[axis] > bestScore then
			best, second, bestScore = axis, bestScore, score[axis]
		elseif score[axis] > second then
			second = score[axis]
		end
	end
	if bestScore > 0 and bestScore > second then
		return AXES[best], ("%s (puntos %d)"):format(best, bestScore)
	end
	return AXES["-Z"], "-Z (por defecto)"
end

-- Borra el cartel del pack (y lo que se le parezca) de lo cargado. Devuelve cuántos.
function Buildings3D.stripJunk(root: Instance): number
	local doomed = {}
	for _, d in root:GetDescendants() do
		if Buildings3D.Junk[d.Name] then
			table.insert(doomed, d)
		end
	end
	for _, d in doomed do
		pcall(function()
			d:Destroy()
		end)
	end
	return #doomed
end

-- Lo que no hace falta (o cuesta) en un edificio de fondo: luces, sonidos, partículas, carteles
-- para pulsar y los MaterialVariant que traiga dentro (solo valen en MaterialService)
local DROP_CLASSES = { "Light", "Sound", "ParticleEmitter", "ProximityPrompt", "ClickDetector", "MaterialVariant", "Fire", "Smoke", "Sparkles" }
local function dropExtras(root: Instance)
	local doomed = {}
	for _, d in root:GetDescendants() do
		for _, class in DROP_CLASSES do
			local ok, yes = pcall(function()
				return d:IsA(class)
			end)
			if ok and yes then
				table.insert(doomed, d)
				break
			end
		end
	end
	for _, d in doomed do
		pcall(function()
			d:Destroy()
		end)
	end
end

-- Suelo o acera que traiga el prefab debajo (no es del edificio y lo haría más ancho)
local GROUND_WORDS = { "sidewalk", "ground", "baseplate", "curb", "street", "road", "pavement", "terrain" }
local function dropGround(list: { BasePart }, lo: Vector3, hi: Vector3): boolean
	local area = (hi.X - lo.X) * (hi.Z - lo.Z)
	local dropped = false
	for _, p in list do
		local plo, phi = bounds({ p })
		if phi.Y - plo.Y < 1.5 and plo.Y <= lo.Y + 0.5 and (phi.X - plo.X) * (phi.Z - plo.Z) >= area * 0.6 and hasWord(p.Name, GROUND_WORDS) then
			p:Destroy()
			dropped = true
		end
	end
	return dropped
end

local function setVariant(p: BasePart, map: { [string]: string })
	pcall(function()
		local current = (p :: any).MaterialVariant
		if type(current) == "string" and map[current] then
			(p :: any).MaterialVariant = map[current]
		end
	end)
end

-- Deja una plantilla lista a partir de un prefab del kit
local function makeTemplate(source: Instance, map: { [string]: string }): Template?
	local copy = source:Clone()
	MeshLibrary.stripScripts(copy)
	Buildings3D.stripJunk(copy)
	dropExtras(copy)
	local list = parts(copy)
	if #list == 0 then
		copy:Destroy()
		return nil
	end
	local lo, hi = bounds(list)
	if dropGround(list, lo, hi) then
		list = parts(copy)
		if #list == 0 then
			copy:Destroy()
			return nil
		end
		lo, hi = bounds(list)
	end
	for _, p in list do
		p.Anchored = true
		setVariant(p, map)
	end
	local front, why = Buildings3D.frontOf(source.Name, list, lo, hi)
	local size = hi - lo
	local center = (lo + hi) / 2
	local foot
	if front.Z < -0.5 then
		foot = Vector3.new(center.X, lo.Y, lo.Z)
	elseif front.Z > 0.5 then
		foot = Vector3.new(center.X, lo.Y, hi.Z)
	elseif front.X < -0.5 then
		foot = Vector3.new(lo.X, lo.Y, center.Z)
	else
		foot = Vector3.new(hi.X, lo.Y, center.Z)
	end
	local alongZ = math.abs(front.Z) > 0.5
	copy.Name = source.Name
	copy:SetAttribute("Parts", #list)
	copy:SetAttribute("Front", why)
	return {
		Name = source.Name,
		Model = copy,
		Foot = foot,
		Front = front,
		FW = if alongZ then size.X else size.Z,
		FD = if alongZ then size.Z else size.X,
		H = size.Y,
		Parts = #list,
		Why = why,
	}
end

-- MaterialVariant de lo cargado -> MaterialService (con prefijo). Devuelve nombre viejo -> nuevo.
function Buildings3D.installVariants(roots: { Instance }, service: Instance?): { [string]: string }
	local map: { [string]: string } = {}
	if not service then
		return map
	end
	for _, root in roots do
		for _, d in root:GetDescendants() do
			if d:IsA("MaterialVariant") then
				local new = Buildings3D.VariantPrefix .. d.Name
				map[d.Name] = map[d.Name] or new
				if not service:FindFirstChild(new) then
					local ok = pcall(function()
						local v = d:Clone()
						v.Name = new
						v:SetAttribute("Pack", "ModernCity")
						v.Parent = service
					end)
					if not ok then
						map[d.Name] = nil
					end
				end
			end
		end
	end
	return map
end

-- Los prefabs del kit (Folder PrefabBuildings) como plantillas. Borra los scripts y el cartel de
-- todo lo cargado. "map": MaterialVariant renombrados (installVariants).
function Buildings3D.prepare(roots: { Instance }, map: { [string]: string }?): { Template }
	local templates = {}
	local wanted = {}
	for _, name in Buildings3D.Prefabs do
		wanted[name] = true
	end
	local seen = {}
	for _, root in roots do
		MeshLibrary.stripScripts(root)
		Buildings3D.stripJunk(root)
		local folder = if root.Name == "PrefabBuildings" then root else root:FindFirstChild("PrefabBuildings", true)
		if folder then
			for _, child in folder:GetChildren() do
				if child:IsA("Model") and wanted[child.Name] and not seen[child.Name] then
					local template = makeTemplate(child, map or {})
					if template and template.FW > 1 and template.FD > 1 and template.H > 1 then
						seen[child.Name] = true
						table.insert(templates, template)
					end
				end
			end
		end
	end
	table.sort(templates, function(a, b)
		return a.Name < b.Name
	end)
	return templates
end

---------------------------------------------------------------------
-- El bloque de siempre: huella, altura y fachada
---------------------------------------------------------------------

local function segmentDistance(p: Vector3, s: Segment): number
	local a, b = Vector3.new(s.A.X, 0, s.A.Z), Vector3.new(s.B.X, 0, s.B.Z)
	local q = Vector3.new(p.X, 0, p.Z)
	local ab = b - a
	local len2 = ab:Dot(ab)
	local t = if len2 > 0 then math.clamp((q - a):Dot(ab) / len2, 0, 1) else 0
	return (q - (a + ab * t)).Magnitude
end

local function nearestRoad(p: Vector3, segments: { Segment }?): number
	local best = math.huge
	for _, s in segments or {} do
		best = math.min(best, segmentDistance(p, s))
	end
	return best
end

-- Huella del bloque (su Body, o la planta baja del rascacielos), altura y hacia dónde mira
function Buildings3D.info(model: Instance, segments: { Segment }?): Info?
	local main: BasePart? = nil
	local top = -math.huge
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and SHELLS[child.Name] then
			local area = child.Size.X * child.Size.Z
			if not main or area > main.Size.X * main.Size.Z then
				main = child
			end
			top = math.max(top, child.CFrame.Position.Y + child.Size.Y / 2)
		end
	end
	if not main then
		return nil
	end
	local body = main :: BasePart
	local bottom = body.CFrame.Position.Y - body.Size.Y / 2
	local center = Vector3.new(body.CFrame.Position.X, bottom, body.CFrame.Position.Z)
	-- Fachada: la cara de la puerta (o del escaparate…)
	local localFront: Vector3? = nil
	local why = ""
	for _, name in HINTS do
		local hint = model:FindFirstChild(name)
		if hint and hint:IsA("BasePart") then
			local rel = body.CFrame:VectorToObjectSpace(hint.CFrame.Position - body.CFrame.Position)
			if Vector3.new(rel.X, 0, rel.Z).Magnitude > 1 then
				localFront = snap(rel)
				why = name
				break
			end
		end
	end
	-- Si no: la cara que da a la calle más cercana
	if not localFront and segments and #segments > 0 then
		local best = math.huge
		for _, axis in AXIS_ORDER do
			local a = AXES[axis]
			local half = if math.abs(a.X) > 0.5 then body.Size.X / 2 else body.Size.Z / 2
			local face = body.CFrame:PointToWorldSpace(a * half)
			local d = nearestRoad(face, segments)
			if d < best then
				best, localFront, why = d, a, "calle"
			end
		end
	end
	if not localFront then
		localFront, why = AXES["-Z"], "LookVector"
	end
	local lf = localFront :: Vector3
	local world = body.CFrame:VectorToWorldSpace(lf)
	world = Vector3.new(world.X, 0, world.Z).Unit
	local alongZ = math.abs(lf.Z) > 0.5
	return {
		CFrame = CFrame.new(center) * CFrame.Angles(0, yawOf(world), 0),
		W = if alongZ then body.Size.X else body.Size.Z,
		D = if alongZ then body.Size.Z else body.Size.X,
		H = top - bottom,
		Why = why,
	}
end

---------------------------------------------------------------------
-- Qué prefab (o cuántos en fila) y a qué escala
---------------------------------------------------------------------

type Option = { Template: Template, Scale: number, Score: number }

local function options(templates: { Template }, ws: number, d: number, h: number, n: number): { Option }
	local list = {}
	for _, t in templates do
		local s = math.min(ws * Buildings3D.Fit / t.FW, d * Buildings3D.Fit / t.FD, Buildings3D.MaxScale)
		if s >= Buildings3D.MinScale then
			local fillW = t.FW * s / ws
			local fillD = t.FD * s / d
			local hr = t.H * s / math.max(h, 1)
			if fillW >= Buildings3D.MinFill and hr >= Buildings3D.HeightRange[1] and hr <= Buildings3D.HeightRange[2] then
				-- Lo que más cuenta: llenar la fachada; luego parecerse en altura; el fondo, poco
				local score = (1 - fillW) * 3 + (1 - fillD) * 0.6 + math.abs(math.log(hr)) + (n - 1) * 0.2
				table.insert(list, { Template = t, Scale = s, Score = score })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Score < b.Score
	end)
	return list
end

-- Plan para un bloque: los prefabs en fila (de izquierda a derecha mirando la fachada), su escala
-- y su sitio. nil si ninguno encaja (el bloque se queda como está).
function Buildings3D.plan(info: Info, templates: { Template }): { Slot }?
	if #templates == 0 or info.W <= 0 or info.D <= 0 then
		return nil
	end
	local bestN, bestList, bestScore = 0, nil :: { Option }?, math.huge
	for n = 1, Buildings3D.MaxRow do
		local list = options(templates, info.W / n, info.D, info.H, n)
		if #list > 0 and list[1].Score < bestScore then
			bestN, bestList, bestScore = n, list, list[1].Score
		end
	end
	if not bestList then
		return nil
	end
	-- Variedad: entre los que encajan casi igual de bien, según la posición (siempre el mismo)
	local good = {}
	for _, o in bestList do
		if o.Score <= bestScore + 0.25 then
			table.insert(good, o)
		end
	end
	local ws = info.W / bestN
	local slots = {}
	local previous: string? = nil
	for i = 1, bestN do
		local offset = -info.W / 2 + ws * (i - 0.5)
		local at = info.CFrame:PointToWorldSpace(Vector3.new(offset, 0, 0))
		local k = math.floor(MeshLibrary.hash(at, 7) * #good) + 1
		local o = good[k]
		if #good > 1 and o.Template.Name == previous then
			o = good[k % #good + 1] -- (dos iguales seguidos no)
		end
		previous = o.Template.Name
		table.insert(slots, { Template = o.Template, Scale = o.Scale, Offset = offset, Score = o.Score })
	end
	return slots
end

function Buildings3D.planParts(slots: { Slot }): number
	local n = 0
	for _, s in slots do
		n += s.Template.Parts
	end
	return n
end

---------------------------------------------------------------------
-- Cambiar un bloque
---------------------------------------------------------------------

local function meshFlags(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = math.max(p.Size.X, p.Size.Y, p.Size.Z) >= Buildings3D.ShadowSize
	pcall(function()
		(p :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	p:AddTag("BuildingMesh") -- (gráficos Bajo: se esconde, Controllers/MaterialDetail)
end

local function shellFlags(p: BasePart)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p:AddTag("BuildingShell") -- (gráficos Bajo: se ve, como antes)
end

-- ¿Es un edificio que se cambia? (nombre y manzana; no uno ya cambiado)
function Buildings3D.isTarget(model: Instance): boolean
	if not model:IsA("Model") or model:GetAttribute("Prefab3D") ~= nil then
		return false
	end
	local where = Buildings3D.Targets[model.Name]
	local parent = model.Parent
	return where ~= nil and parent ~= nil and where[parent.Name] == true
end

-- Cambia la fachada de un bloque por prefabs del kit. Devuelve el plan usado (nil: no se ha tocado).
function Buildings3D.replace(model: Model, templates: { Template }, segments: { Segment }?, slots: { Slot }?): { Slot }?
	if not Buildings3D.isTarget(model) then
		return nil
	end
	local info = Buildings3D.info(model, segments)
	if not info then
		return nil
	end
	local plan = slots or Buildings3D.plan(info, templates)
	if not plan then
		return nil
	end
	-- Primero se monta todo aparte; solo si sale bien se toca el bloque
	local made = {}
	local ok, err = pcall(function()
		local front = info.CFrame.LookVector
		for i, slot in plan do
			local t = slot.Template
			local s = slot.Scale
			local foot = info.CFrame:PointToWorldSpace(Vector3.new(slot.Offset, 0, -info.D / 2))
			local yaw = yawOf(front) - yawOf(t.Front)
			local copy = MeshLibrary.placeCopy(t :: any, foot, yaw, s)
			local holder = Instance.new("Model")
			holder.Name = "Fachada3D"
			holder:SetAttribute("Prefab", t.Name)
			holder:SetAttribute("Scale", s)
			for _, p in parts(copy) do
				meshFlags(p)
			end
			for _, child in copy:GetChildren() do
				child.Parent = holder
			end
			copy:Destroy()
			-- Choque: una caja invisible del tamaño del prefab
			local w, h, d = t.FW * s, t.H * s, t.FD * s
			local box = Instance.new("Part")
			box.Name = "BuildingCollider"
			box.Size = Vector3.new(w, h, d)
			box.CFrame = info.CFrame * CFrame.new(slot.Offset, h / 2, -info.D / 2 + d / 2)
			box.Anchored = true
			box.Transparency = 1
			box.CastShadow = false
			box.CanCollide = true
			box.CanQuery = true
			box.CanTouch = true
			box:SetAttribute("Collider", true)
			box.Parent = holder
			made[i] = holder
		end
	end)
	if not ok then
		for _, m in made do
			m:Destroy()
		end
		warn("[Buildings3D] " .. tostring(err))
		return nil
	end
	-- Fuera la caja de Kit/Lite: se borran sus adornos; cuerpo y puerta invisibles; el cartel se queda
	local doomed = {}
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			if SHELLS[child.Name] or DOORS[child.Name] then
				shellFlags(child)
			elseif LITE_PARTS[child.Name] or child:HasTag("CityDetail") then
				table.insert(doomed, child)
			end
		end
	end
	for _, child in doomed do
		child:Destroy()
	end
	local names = {}
	for i, holder in made do
		holder.Parent = model
		table.insert(names, plan[i].Template.Name)
	end
	model:SetAttribute("Prefab3D", table.concat(names, ","))
	return plan
end

---------------------------------------------------------------------
-- Qué se cambia y en qué orden
---------------------------------------------------------------------

local function centerOf(model: Instance): Vector3
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and SHELLS[child.Name] then
			return child.CFrame.Position
		end
	end
	local list = parts(model)
	if #list == 0 then
		return Vector3.new(0, 0, 0)
	end
	local lo, hi = bounds(list)
	return (lo + hi) / 2
end

-- Bloques que se pueden cambiar, primero los del centro y los de las avenidas
function Buildings3D.collect(roots: { Instance }, segments: { Segment }?): { Model }
	local list = {}
	local avenues = {}
	for _, s in segments or {} do
		if s.Kind == "Avenida" then
			table.insert(avenues, s)
		end
	end
	local score: { [Instance]: number } = {}
	for _, root in roots do
		for _, d in root:GetDescendants() do
			if d:IsA("Model") and Buildings3D.isTarget(d) then
				table.insert(list, d)
				local c = centerOf(d)
				local s = Vector3.new(c.X - Buildings3D.Center.X, 0, c.Z - Buildings3D.Center.Z).Magnitude
				if #avenues > 0 and nearestRoad(c, avenues) < 70 then
					s -= 400 -- (los de las avenidas, antes)
				end
				score[d] = s
			end
		end
	end
	table.sort(list, function(a, b)
		return score[a] < score[b]
	end)
	return list
end

-- Cambia los bloques en tandas, sin pasar de los topes. Devuelve { Buildings, Copies, Parts }.
function Buildings3D.run(roots: { Instance }, templates: { Template }, segments: { Segment }?)
	local done = { Buildings = 0, Copies = 0, Parts = 0 }
	if #templates == 0 then
		return done
	end
	local step = 0
	for _, model in Buildings3D.collect(roots, segments) do
		if done.Copies >= Buildings3D.MaxCopies or done.Parts >= Buildings3D.MaxParts then
			break
		end
		local info = Buildings3D.info(model, segments)
		local plan = info and Buildings3D.plan(info, templates)
		if plan then
			local cost = Buildings3D.planParts(plan)
			if done.Copies + #plan <= Buildings3D.MaxCopies and done.Parts + cost <= Buildings3D.MaxParts then
				local ok, result = pcall(Buildings3D.replace, model, templates, segments, plan)
				if ok and result then
					done.Buildings += 1
					done.Copies += #result
					done.Parts += cost
				end
				step += 1
				if step % Buildings3D.Batch == 0 then
					task.wait()
				end
			end
		end
	end
	return done
end

---------------------------------------------------------------------
-- Arranque en el servidor
---------------------------------------------------------------------

-- Carga un modelo: AssetService:LoadAssetAsync (también los de la comunidad) y, si falla,
-- InsertService:LoadAsset (solo los oficiales). nil si no hay manera.
function Buildings3D.loadAsset(id: number): Instance?
	local ok, asset = pcall(function()
		return (game:GetService("AssetService") :: any):LoadAssetAsync(id)
	end)
	if ok and typeof(asset) == "Instance" then
		return asset
	end
	local ok2, asset2 = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	if ok2 and typeof(asset2) == "Instance" then
		return asset2
	end
	warn(("[Buildings3D] No se pudo cargar %d: %s / %s"):format(id, tostring(asset), tostring(asset2)))
	return nil
end

-- Carga los packs, instala los materiales y deja las plantillas en ServerStorage.Buildings3D
function Buildings3D.load(): ({ Template }?, number)
	local ok, templates, variants = pcall(function()
		local ServerStorage = game:GetService("ServerStorage")
		local MaterialService = game:GetService("MaterialService")
		local roots = {}
		for _, key in { "Kit", "Materials" } do
			local asset = Buildings3D.loadAsset(Buildings3D.Packs[key].Id)
			if asset then
				MeshLibrary.stripScripts(asset)
				Buildings3D.stripJunk(asset)
				table.insert(roots, asset)
			end
		end
		if #roots == 0 then
			return nil, 0
		end
		local map = Buildings3D.installVariants(roots, MaterialService)
		local count = 0
		for _ in map do
			count += 1
		end
		local list = Buildings3D.prepare(roots, map)
		local folder = ServerStorage:FindFirstChild("Buildings3D") or Instance.new("Folder")
		folder.Name = "Buildings3D"
		for _, t in list do
			t.Model.Parent = folder
		end
		folder.Parent = ServerStorage
		for _, root in roots do
			root:Destroy()
		end
		return list, count
	end)
	if not ok then
		warn("[Buildings3D] " .. tostring(templates))
		return nil, 0
	end
	return templates, variants or 0
end

-- Main: carga y cambia los bloques (llamar en un hilo aparte: espera)
function Buildings3D.start(segments: { Segment }?)
	local templates, variants = Buildings3D.load()
	if not templates or #templates == 0 then
		warn(("[Buildings3D] Sin prefabs (%d materiales): se quedan los bloques de siempre"):format(variants))
		return
	end
	local summary = {}
	for _, t in templates do
		table.insert(summary, ("%s %dx%dx%d %d piezas, fachada %s"):format(t.Name, t.FW, t.H, t.FD, t.Parts, t.Why))
	end
	print("[Buildings3D] Prefabs: " .. table.concat(summary, " · "))
	-- Las claves de los edificios visitables salen de su caja: antes, que InteriorService las mire
	local waited = os.clock()
	while workspace:GetAttribute("InteriorsScanned") ~= true and os.clock() - waited < Buildings3D.ScanWait do
		task.wait(1)
	end
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	local started = os.clock()
	local done = Buildings3D.run({ town }, templates, segments)
	print(("[Buildings3D] %d materiales · %d bloques cambiados (%d prefabs, %d piezas) en %.1f s"):format(
		variants, done.Buildings, done.Copies, done.Parts, os.clock() - started
	))
end

return Buildings3D
