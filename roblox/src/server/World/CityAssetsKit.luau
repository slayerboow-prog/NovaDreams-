-- CityAssetsKit: herramientas comunes para meter en la calle los modelos de la Tienda que eligió
-- Sebastián (calles, ciudad y edificios por fuera). Lo usa World/CityAssets (qué va dónde).
--
--   * Limpieza (sanitize): PRIMERO se borra todo script (Script, LocalScript, ModuleScript: varios packs
--     traen virus, docs/assets-usuario-4.md «familias 1–5»). Luego se queda SOLO lo que se ve: piezas,
--     Model/Folder, SurfaceAppearance, mallas especiales y, si el pack lo pide, imágenes y luces. Todo lo
--     demás se tira (sonidos, GUIs con textos y marcas, ClickDetector, ProximityPrompt, restricciones,
--     NumberPose, PlaneConstraint, ParticleEmitter «VFXParticles», valores, huesos…). Se quitan
--     atributos y etiquetas, se anclan las piezas y se apagan los asientos. Las imágenes y las piezas con
--     nombre de marca real (Daikin, Funiki, International…) o de otros juegos se borran.
--   * Plantillas: copia limpia con nombre en español, su caja (Size) y su base (centro de abajo).
--     Nada de Model:ScaleTo / PivotTo / GetBoundingBox: se hace con CFrame a mano (así se prueba en Lune).
--   * Overlay: pone la malla encima de una pieza de bloques que ya existe (el aire acondicionado de una
--     fachada, un cono de obra, un palé…): la malla cabe en la caja de la pieza y la pieza se queda
--     invisible (etiqueta BuildingShell: en gráficos Bajo vuelve a verse y la malla, BuildingMesh, se
--     esconde: Controllers/MaterialDetail). Si la pieza sale despedida al chocar (KnockService), la malla
--     va soldada a ella y se mueve con ella.
--   * Sitios libres (findSpot): en el suelo de una manzana, el primer hueco donde una caja del tamaño del
--     objeto (más un margen) no toca nada (workspace:GetPartBoundsInBox), lo más cerca posible del punto
--     preferido.

local CityAssetsKit = {}

CityAssetsKit.DetailTag = "CityDetail" -- el nivel Bajo lo esconde
CityAssetsKit.MeshTag = "BuildingMesh" -- malla encima de una pieza de bloques (Bajo: se esconde)
CityAssetsKit.ShellTag = "BuildingShell" -- la pieza de bloques de debajo (Bajo: se vuelve a ver)
CityAssetsKit.MaxTemplateParts = 450 -- plantillas más grandes no se usan (salvo que se pida más)

-- Marcas reales, otros juegos y nombres prohibidos (en minúsculas; se busca dentro del nombre)
CityAssetsKit.BrandWords = {
	"logo", "daikin", "panasonic", "mitsubishi", "kirigamine", "funiki", "carrier", "saijo", "luxiar",
	"eminent", "international", "union pacific", "pennsylvania", "lackawanna", "pullman", "new york central",
	"strasburg", "rainier", "consult", "coca", "coke", "bloxy", "roblox", "onlyfan", "csgo", "cs:go",
	"half-life", "hl2", "wu-tang", "wutang", "bloxburg", "mimic", "scp", "nova", "smash mouth", "sanic",
	"saints", "black mesa", "bms_", "c1a2c", "general technologies",
}
-- Siglas que solo cuentan como palabra suelta («CN», «PRR», «NYC»…)
CityAssetsKit.BrandAcronyms = { "cn", "prr", "nyc", "s&n" }

local KEEP = { Model = true, Folder = true, SurfaceAppearance = true, SpecialMesh = true, BlockMesh = true, CylinderMesh = true }
local LIGHTS = { SurfaceLight = true, SpotLight = true, PointLight = true }
local IMAGES = { Decal = true, Texture = true }

export type Policy = {
	Images: boolean?, -- quedarse con Decal/Texture (sin marca)
	ImageFilter: ((Instance) -> boolean)?, -- además, solo las que pasen esto
	Lights: boolean?,
	Seats: boolean?, -- dejar los asientos encendidos (bancos de la pista de tenis)
	StripTexture: boolean?, -- quitar la textura de las MeshPart (el logo va pintado en ella)
}
export type Stats = { Scripts: number, Removed: number, Brands: number }
export type Template = {
	Name: string,
	Model: Model,
	Base: CFrame, -- centro de abajo de su caja
	Size: Vector3,
	Parts: number,
}

---------------------------------------------------------------------
-- Limpieza
---------------------------------------------------------------------

local function isCode(d: Instance): boolean
	local ok, yes = pcall(function()
		return d:IsA("LuaSourceContainer")
	end)
	if ok then
		return yes
	end
	return d.ClassName == "Script" or d.ClassName == "LocalScript" or d.ClassName == "ModuleScript"
end

local function plain(s: string): string
	return (string.gsub(s, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- ¿El texto tiene una marca real, otro juego o un nombre prohibido?
function CityAssetsKit.branded(text: string): boolean
	local s = string.lower(text)
	for _, w in CityAssetsKit.BrandWords do
		if string.find(s, w, 1, true) then
			return true
		end
	end
	for _, w in CityAssetsKit.BrandAcronyms do
		if string.find(" " .. s .. " ", "[^%w]" .. plain(w) .. "[^%w]") then
			return true
		end
	end
	return false
end

-- Limpia lo cargado (ver la cabecera). Devuelve cuánto se ha quitado.
function CityAssetsKit.sanitize(root: Instance, policy: Policy?): Stats
	local p = policy or {}
	local stats = { Scripts = 0, Removed = 0, Brands = 0 }
	-- 1) Todos los scripts, lo primero
	for _, d in root:GetDescendants() do
		if isCode(d) then
			stats.Scripts += 1
			pcall(d.Destroy, d)
		end
	end
	-- 2) Solo lo que se ve
	for _, d in root:GetDescendants() do
		if d.Parent == nil then
			continue -- (ya se fue con su padre)
		end
		local keep = false
		local brand = false
		if d:IsA("BasePart") or d:IsA("Model") then
			keep = true
			brand = CityAssetsKit.branded(d.Name)
		elseif KEEP[d.ClassName] then
			keep = true
		elseif LIGHTS[d.ClassName] then
			keep = p.Lights == true
		elseif IMAGES[d.ClassName] then
			keep = p.Images == true
			brand = CityAssetsKit.branded(d.Name)
			if keep and not brand and p.ImageFilter and not p.ImageFilter(d) then
				keep = false
			end
		end
		if brand then
			keep = false
			stats.Brands += 1
		end
		if not keep then
			stats.Removed += 1
			pcall(d.Destroy, d)
		end
	end
	-- 3) Sin atributos ni etiquetas; piezas ancladas, sin tocar, asientos apagados
	for _, d in root:GetDescendants() do
		pcall(function()
			for name in d:GetAttributes() do
				d:SetAttribute(name, nil)
			end
		end)
		pcall(function()
			for _, tag in d:GetTags() do
				d:RemoveTag(tag)
			end
		end)
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			if (d.ClassName == "Seat" or d.ClassName == "VehicleSeat") and not p.Seats then
				pcall(function()
					(d :: any).Disabled = true
				end)
			end
			if p.StripTexture and d:IsA("MeshPart") then
				pcall(function()
					(d :: any).TextureID = ""
				end)
				for _, sa in d:GetChildren() do
					if sa:IsA("SurfaceAppearance") then
						sa:Destroy()
					end
				end
			end
		end
	end
	return stats
end

---------------------------------------------------------------------
-- Cajas y plantillas
---------------------------------------------------------------------

function CityAssetsKit.parts(root: Instance): { BasePart }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- Caja alineada con los ejes del mundo (teniendo en cuenta el giro de cada pieza)
function CityAssetsKit.bounds(list: { BasePart }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in list do
		local cf, s = p.CFrame, p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local e = Vector3.new(
			math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
			math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
			math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
		)
		local c = cf.Position
		lo = Vector3.new(math.min(lo.X, c.X - e.X), math.min(lo.Y, c.Y - e.Y), math.min(lo.Z, c.Z - e.Z))
		hi = Vector3.new(math.max(hi.X, c.X + e.X), math.max(hi.Y, c.Y + e.Y), math.max(hi.Z, c.Z + e.Z))
	end
	return lo, hi
end

-- Mueve (y escala) todas las piezas: lo que estaba en «from» pasa a «to», s veces más grande
function CityAssetsKit.transform(root: Instance, from: CFrame, to: CFrame, s: number)
	for _, p in CityAssetsKit.parts(root) do
		local rel = from:ToObjectSpace(p.CFrame)
		local rot = rel - rel.Position
		if s ~= 1 then
			p.Size = p.Size * s
		end
		p.CFrame = to * CFrame.new(rel.Position * s) * rot
	end
	if s ~= 1 then
		for _, d in root:GetDescendants() do
			if d:IsA("SpecialMesh") then
				d.Scale = d.Scale * s
				d.Offset = d.Offset * s
			elseif d:IsA("Texture") then
				pcall(function()
					d.StudsPerTileU = d.StudsPerTileU * s
					d.StudsPerTileV = d.StudsPerTileV * s
				end)
			end
		end
	end
end

-- Plantilla limpia (ya sanitizada) con nombre en español. nil si no tiene piezas o pesa demasiado.
-- opts.Upright: si la caja es más alta que larga (malla tumbada), se pone el lado largo en horizontal.
function CityAssetsKit.template(source: Instance, name: string, opts: { MaxParts: number?, Upright: boolean?, Color: Color3?, Material: Enum.Material? }?): Template?
	local o = opts or {}
	local copy = source:Clone()
	local model = Instance.new("Model")
	model.Name = name
	copy.Parent = model
	local list = CityAssetsKit.parts(model)
	if #list == 0 or #list > (o.MaxParts or CityAssetsKit.MaxTemplateParts) then
		model:Destroy()
		return nil
	end
	for _, p in list do
		p.Name = name
		p.Anchored = true
		p.CanTouch = false
		if o.Color then
			p.Color = o.Color
		end
		if o.Material then
			p.Material = o.Material
		end
	end
	if copy:IsA("Model") or copy:IsA("Folder") then
		copy.Name = name
	end
	local lo, hi = CityAssetsKit.bounds(list)
	local size = hi - lo
	if o.Upright and size.Y > 1.4 * math.max(size.X, size.Z) then
		-- tumbada: se gira 90° para que lo largo quede en horizontal (a lo largo de Z)
		local center = (lo + hi) / 2
		local c = CFrame.new(center)
		local turned = if size.X >= size.Z then CFrame.Angles(0, 0, math.pi / 2) else CFrame.Angles(math.pi / 2, 0, 0)
		CityAssetsKit.transform(model, c, c * turned, 1)
		lo, hi = CityAssetsKit.bounds(list)
		size = hi - lo
	end
	return {
		Name = name,
		Model = model,
		Base = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2),
		Size = size,
		Parts = #list,
	}
end

-- Escala para que una caja quepa entera en otra
function CityAssetsKit.fit(size: Vector3, box: Vector3): number
	return math.min(box.X / math.max(size.X, 0.01), box.Y / math.max(size.Y, 0.01), box.Z / math.max(size.Z, 0.01))
end

-- Hacia dónde queda «la parte de atrás» de una plantilla en su eje Z o X (el lado donde se amontonan
-- más piezas: la red de una portería, la caja de un aire): +1 / -1 en el eje más corto en planta.
function CityAssetsKit.backSign(t: Template): (string, number)
	local axis = if t.Size.X <= t.Size.Z then "X" else "Z"
	local sum, n = 0, 0
	for _, p in CityAssetsKit.parts(t.Model) do
		local rel = t.Base:PointToObjectSpace(p.CFrame.Position)
		sum += if axis == "X" then rel.X else rel.Z
		n += 1
	end
	return axis, if n > 0 and sum < 0 then -1 else 1
end

export type Flags = {
	Collide: boolean?, -- las piezas grandes chocan (las pequeñas nunca)
	Detail: boolean?, -- etiqueta CityDetail (Bajo lo esconde)
	Mesh: boolean?, -- etiqueta BuildingMesh (va encima de una pieza de bloques)
	Shadow: number?, -- dan sombra las piezas de al menos esto (por defecto 4)
	Name: string?,
}

-- Copia de una plantilla con su base en «at» y s veces su tamaño, dentro de «parent»
function CityAssetsKit.spawn(t: Template, at: CFrame, s: number, parent: Instance?, flags: Flags?): Model
	local f = flags or {}
	local model = t.Model:Clone()
	if f.Name then
		model.Name = f.Name
	end
	CityAssetsKit.transform(model, t.Base, at, s)
	local shadow = f.Shadow or 4
	for _, p in CityAssetsKit.parts(model) do
		local big = math.max(p.Size.X, p.Size.Y, p.Size.Z)
		local solid = f.Collide == true and big >= 1.5 and p.Transparency < 1
		p.Anchored = true
		p.CanCollide = solid
		p.CanQuery = solid
		p.CanTouch = false
		p.CastShadow = big >= shadow
		if f.Detail then
			p:AddTag(CityAssetsKit.DetailTag)
		end
		if f.Mesh then
			p:AddTag(CityAssetsKit.MeshTag)
		end
	end
	model.Parent = parent
	return model
end

---------------------------------------------------------------------
-- Overlay: la malla encima de una pieza de bloques
---------------------------------------------------------------------

-- Piezas que salen despedidas al chocar (shared/Knock): la malla va soldada a ellas
CityAssetsKit.Knockable = { Bin = true, Cone = true, WorksBarrier = true, WorksFence = true, Papelera = true }

-- Esconde la pieza de bloques (sigue chocando igual). Si KnockService la devuelve a su sitio con su
-- transparencia de antes, se vuelve a esconder.
function CityAssetsKit.hide(part: BasePart)
	part.Transparency = 1
	part:AddTag(CityAssetsKit.ShellTag)
	if CityAssetsKit.Knockable[part.Name] then
		pcall(function()
			part:GetPropertyChangedSignal("Transparency"):Connect(function()
				if part.Transparency < 1 then
					part.Transparency = 1
				end
			end)
		end)
	end
end

export type OverlayOpts = {
	Grow: number?, -- la caja de la pieza se agranda esto (1 = igual)
	Yaw: number?, -- giro extra (radianes)
	Weld: boolean?, -- soldar a la pieza (si no, según Knockable)
	Facing: Vector3?, -- la «parte de atrás» de la plantilla mira hacia aquí (mundo)
	KeepBase: boolean?, -- no esconder la pieza de debajo
}

function CityAssetsKit.overlay(orig: BasePart, t: Template, opts: OverlayOpts?): Model?
	local o = opts or {}
	local box = orig.Size * (o.Grow or 1)
	local long = box.X >= box.Z
	local rotate = long ~= (t.Size.X >= t.Size.Z)
	local turned = if rotate then Vector3.new(t.Size.Z, t.Size.Y, t.Size.X) else t.Size
	local s = CityAssetsKit.fit(turned, box)
	if s <= 0 or s ~= s then
		return nil
	end
	local yaw = (if rotate then math.pi / 2 else 0) + (o.Yaw or 0)
	local at = orig.CFrame * CFrame.new(0, -orig.Size.Y / 2, 0) * CFrame.Angles(0, yaw, 0)
	if o.Facing then
		-- la parte de atrás de la plantilla, hacia «Facing»
		local axis, sign = CityAssetsKit.backSign(t)
		local back = (if axis == "X" then at.RightVector else at.LookVector) * sign
		if back:Dot(o.Facing) < 0 then
			at = at * CFrame.Angles(0, math.pi, 0)
		end
	end
	local weld = o.Weld or CityAssetsKit.Knockable[orig.Name] == true
	local model = CityAssetsKit.spawn(t, at, s, nil, { Mesh = true, Shadow = 6 })
	model.Name = "Malla"
	for _, p in CityAssetsKit.parts(model) do
		p.Name = "Malla"
		if weld then
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = orig
			w.Part1 = p
			w.Parent = p
		end
	end
	model.Parent = orig
	if not o.KeepBase then
		CityAssetsKit.hide(orig)
	end
	return model
end

---------------------------------------------------------------------
-- Sitios libres
---------------------------------------------------------------------

export type Area = { CFrame: CFrame, Size: Vector3 } -- centro de la cara de arriba del suelo; Size X/Z
export type Query = (CFrame, Vector3) -> { Instance }

-- Lo que no cuenta como estorbo: el agua
CityAssetsKit.IgnoreNames = { Sea = true, River = true, Lake = true, Water = true }

local overlapParams: any = nil
function CityAssetsKit.defaultQuery(cf: CFrame, size: Vector3): { Instance }
	if not overlapParams then
		overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {}
	end
	local out = {}
	for _, p in workspace:GetPartBoundsInBox(cf, size, overlapParams) do
		if not CityAssetsKit.IgnoreNames[p.Name] then
			table.insert(out, p)
		end
	end
	return out
end

-- Suelo de una pieza (cara de arriba)
function CityAssetsKit.areaOf(part: BasePart): Area
	local cf = part.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
	return { CFrame = cf, Size = part.Size }
end

export type SpotOpts = {
	Step: number?,
	Margin: number?, -- espacio libre alrededor
	Prefer: Vector3?, -- lo más cerca posible de aquí
	Query: Query?,
	Lift: number?, -- la caja empieza a esta altura sobre el suelo (lo plano de debajo no cuenta)
	MaxTries: number?,
	Yaws: { number }?,
}

-- Primer hueco libre en el suelo de un área para una caja «foot» (ancho X, alto Y, fondo Z).
-- Devuelve el CFrame del centro de abajo (girado) o nil.
function CityAssetsKit.findSpot(area: Area, foot: Vector3, opts: SpotOpts?): CFrame?
	local o = opts or {}
	local query = o.Query or CityAssetsKit.defaultQuery
	local margin = o.Margin or 1
	local lift = o.Lift or 0.6
	local step = o.Step or math.clamp(math.min(foot.X, foot.Z) / 2, 3, 12)
	local hx, hz = area.Size.X / 2, area.Size.Z / 2
	local cands = {}
	local nx, nz = math.floor(hx / step), math.floor(hz / step)
	for i = -nx, nx do
		for j = -nz, nz do
			table.insert(cands, area.CFrame * CFrame.new(i * step, 0, j * step))
		end
	end
	local prefer = o.Prefer or area.CFrame.Position
	table.sort(cands, function(a, b)
		local da = Vector3.new(a.Position.X - prefer.X, 0, a.Position.Z - prefer.Z).Magnitude
		local db = Vector3.new(b.Position.X - prefer.X, 0, b.Position.Z - prefer.Z).Magnitude
		return da < db
	end)
	local tries = 0
	local yaws = o.Yaws or { 0, math.pi / 2 }
	for _, c in cands do
		for _, yaw in yaws do
			local q = math.abs(math.cos(yaw)) > 0.5
			local fw = if q then foot.X else foot.Z
			local fd = if q then foot.Z else foot.X
			local rel = area.CFrame:ToObjectSpace(c).Position
			if math.abs(rel.X) + fw / 2 + margin <= hx and math.abs(rel.Z) + fd / 2 + margin <= hz then
				tries += 1
				if tries > (o.MaxTries or 600) then
					return nil
				end
				local spot = c * CFrame.Angles(0, yaw, 0)
				local box = spot * CFrame.new(0, lift + foot.Y / 2, 0)
				local hits = query(box, Vector3.new(foot.X + margin * 2, foot.Y, foot.Z + margin * 2))
				if #hits == 0 then
					return spot
				end
			end
		end
	end
	return nil
end

-- Lo mismo, en una lista de áreas (la primera que tenga hueco)
function CityAssetsKit.findIn(areas: { Area }, foot: Vector3, opts: SpotOpts?): (CFrame?, number?)
	for i, a in areas do
		local spot = CityAssetsKit.findSpot(a, foot, opts)
		if spot then
			return spot, i
		end
	end
	return nil, nil
end

-- Número pseudoaleatorio fijo por posición (el mismo sitio, la misma elección)
function CityAssetsKit.hash(pos: Vector3, salt: number?): number
	local x = math.floor(pos.X * 7 + 0.5)
	local z = math.floor(pos.Z * 13 + 0.5)
	local h = (x * 73856093 + z * 19349663 + (salt or 0) * 83492791) % 2147483647
	h = (h * 1103515245 + 12345) % 2147483648
	return h / 2147483648
end

-- Lista de mallas de vía uno detrás de otro a lo largo de Z (desde «at», hacia -Z), hasta «length»
function CityAssetsKit.layTrack(t: Template, at: CFrame, length: number, s: number, parent: Instance): number
	local piece = t.Size.Z * s
	if piece <= 0 then
		return 0
	end
	local alongX = t.Size.X > t.Size.Z
	if alongX then
		piece = t.Size.X * s
	end
	local n = math.max(1, math.ceil(length / piece))
	for i = 0, n - 1 do
		local cf = at * CFrame.new(0, 0, -(i + 0.5) * piece) * (if alongX then CFrame.Angles(0, math.pi / 2, 0) else CFrame.new())
		CityAssetsKit.spawn(t, cf, s, parent, { Collide = true, Shadow = 50 })
	end
	return n
end

return CityAssetsKit
