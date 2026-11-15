-- PlanetCityMeshes (servidor): los EDIFICIOS y OBJETOS DE CALLE de las ciudades de los planetas hechos con
-- Blender (scripts/planetas/edificios_blender.py, subidos con scripts/upload-ciudades.sh →
-- shared/Cosmos/CiudadAssetIds; medidas en shared/Cosmos/CiudadMalla). Los usa World/PlanetMetroBuilder en lugar
-- de los edificios de piezas (que se quedan si la malla no está o no se puede descargar).
--
--   * Cada pieza es un Model con mallas «<Nombre>_<Seccion>_<Grupo>»:
--       Seccion  Base (planta baja) · Medio (un tramo de pisos, se REPITE hasta la altura del solar) · Tope (azotea)
--       Grupo    Cuerpo, Cristal, Luz, Metal, Techo, Nieve, Toldo, Hoja (material y color: los del planeta)
--   * load(nombre) la descarga UNA vez y la deja como plantilla; place(…) la copia en un solar, estirada a su
--     ancho y fondo y con los tramos «Medio» que hagan falta para su altura.
--   * La plantilla se normaliza al cargarla: escala (por si Roblox la importó a otra), origen en el centro de la
--     base y el frente hacia -Z (se sabe por la malla de «prueba» de CiudadMalla, la más descentrada).
--
-- API: PlanetCityMeshes.prepare(nombre, contenedor) → plantilla?   (pura: la usan las pruebas)
--      PlanetCityMeshes.load(nombre) → plantilla?                  (descarga; cede)
--      PlanetCityMeshes.place(plantilla, parent, cf, w, d, h, estilo) → (Model, { MeshPart })
--      PlanetCityMeshes.layout(info, h) → sb, n, sm, st            (cuánto se estira cada sección y cuántos tramos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlanetCityMeshes = {}

local V3 = Vector3.new
local MAX_MID = 4 -- (tramos «Medio» como mucho: más alto que eso, se estiran)

export type Entry = { Part: BasePart, Sec: string, Group: string, Off: Vector3, Rot: CFrame, Size: Vector3 }
export type Template = { Name: string, Info: any, Entries: { Entry } }

local function ids(): { [string]: any }
	local ok, mod = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.CiudadAssetIds)
	end)
	return if ok and type(mod) == "table" then mod else {}
end

local function shapes(): { [string]: any }
	local ok, mod = pcall(function()
		return require(ReplicatedStorage.Shared.Cosmos.CiudadMalla)
	end)
	return if ok and type(mod) == "table" then mod else {}
end

function PlanetCityMeshes.idOf(value: any): number?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local n = tonumber(string.match(tostring(value), "(%d+)%s*$") or "")
	return if n and n > 0 then n else nil
end

function PlanetCityMeshes.has(name: string): boolean
	local list = ids().Mallas
	return type(list) == "table" and PlanetCityMeshes.idOf(list[name]) ~= nil and shapes()[name] ~= nil
end

-- Lo que ocupa una pieza girada, en los ejes del mundo
local function extents(rot: CFrame, size: Vector3): Vector3
	local x, y, z = rot.XVector, rot.YVector, rot.ZVector
	return V3(
		math.abs(x.X) * size.X + math.abs(y.X) * size.Y + math.abs(z.X) * size.Z,
		math.abs(x.Y) * size.X + math.abs(y.Y) * size.Y + math.abs(z.Y) * size.Z,
		math.abs(x.Z) * size.X + math.abs(y.Z) * size.Y + math.abs(z.Z) * size.Z
	)
end

-- Cuánto crece cada eje PROPIO de una pieza girada cuando el mundo se estira s (giros de 90°: exacto)
local function localScale(rot: CFrame, s: Vector3): Vector3
	local function along(v: Vector3): number
		return math.abs(v.X) * s.X + math.abs(v.Y) * s.Y + math.abs(v.Z) * s.Z
	end
	return V3(along(rot.XVector), along(rot.YVector), along(rot.ZVector))
end

-- Deja lista una plantilla con las mallas de `container` (un Model recién descargado, o uno de prueba)
function PlanetCityMeshes.prepare(name: string, container: Instance): Template?
	local info = shapes()[name]
	if not info then
		return nil
	end
	local found: { { Part: BasePart, Sec: string, Group: string } } = {}
	for _, d in container:GetDescendants() do
		if d:IsA("BasePart") then
			local sec, group = string.match(d.Name, "_(%a+)_(%a+)$")
			if sec and group then
				table.insert(found, { Part = d, Sec = sec, Group = group })
			end
		end
	end
	if #found == 0 then
		return nil
	end
	-- la caja de todo
	local lo, hi = V3(math.huge, math.huge, math.huge), V3(-math.huge, -math.huge, -math.huge)
	for _, f in found do
		local p = f.Part
		local rot = p.CFrame - p.CFrame.Position
		local e = extents(rot, p.Size) / 2
		lo = lo:Min(p.CFrame.Position - e)
		hi = hi:Max(p.CFrame.Position + e)
	end
	local center, size = (lo + hi) / 2, hi - lo
	if size.Y < 0.01 then
		return nil
	end
	-- escala (Blender exporta en studs; si Roblox la importó a otra, se corrige con la altura)
	local k = info.Size.Y / size.Y
	if math.abs(k - 1) <= 0.02 then
		k = 1
	end
	-- ¿hacia dónde quedó el frente? (la malla de prueba está a un lado conocido del centro)
	local flipped = false
	local probe = info.Probe and info.Parts and info.Parts[info.Probe]
	if probe then
		local expected = probe.C.Z - info.Center.Z
		for _, f in found do
			if f.Sec .. "_" .. f.Group == info.Probe then
				local actual = (f.Part.CFrame.Position.Z - center.Z) * k
				flipped = math.abs(expected) > 0.5 and actual * expected < 0
			end
		end
	end
	-- (en CiudadMalla el frente queda en +Z; los edificios se colocan con el frente en -Z: media vuelta, salvo
	-- que la malla ya viniera girada)
	local turn = if flipped then CFrame.new() else CFrame.Angles(0, math.pi, 0)
	local c = info.Center
	local entries: { Entry } = {}
	for _, f in found do
		local p = f.Part
		local rot = p.CFrame - p.CFrame.Position
		local rel = (p.CFrame.Position - center) * k -- (respecto al centro de la caja, en los ejes en que llegó)
		local off = turn * rel + V3(-c.X, c.Y, -c.Z)
		-- (centro de la caja respecto al centro de la base, ya con el frente en -Z: X y Z cambian de signo)
		table.insert(entries, { Part = p, Sec = f.Sec, Group = f.Group, Off = off, Rot = turn * rot, Size = p.Size * k })
	end
	return { Name = name, Info = info, Entries = entries }
end

-- Cuánto se estira cada sección para una altura h: (base, nº de tramos «Medio», cada tramo, tope)
function PlanetCityMeshes.layout(info: any, h: number): (number, number, number, number)
	local base, mid, top = info.Base, info.Mid or 0, info.Top or 0
	if mid <= 0 then
		return math.clamp(h / (base + top), 0.5, 3), 0, 1, math.clamp(h / (base + top), 0.5, 3)
	end
	local rest = h - base - top
	if rest < mid * 0.45 then
		local s = math.clamp(h / (base + top), 0.5, 1.6)
		return s, 0, 1, s
	end
	local n = math.clamp(math.floor(rest / mid + 0.5), 1, MAX_MID)
	return 1, n, rest / (n * mid), 1
end

-- Copia la plantilla en un solar. cf: centro de la base, mirando (LookVector) a la calle. w, d, h: lo que mide
-- el edificio. style(group, part): le pone material y color.
function PlanetCityMeshes.place(tpl: Template, parent: Instance, cf: CFrame, w: number, d: number, h: number, style: (string, BasePart, string) -> ()): (Model, { BasePart })
	local info = tpl.Info
	local sx, sz = w / info.W, d / info.D
	local sb, n, sm, st = PlanetCityMeshes.layout(info, h)
	local model = Instance.new("Model")
	model.Name = "Malla_" .. tpl.Name
	local out: { BasePart } = {}
	local function put(e: Entry, y0: number, yStart: number, sy: number)
		local p = e.Part:Clone()
		local s = localScale(e.Rot, V3(sx, sy, sz))
		p.Size = V3(math.max(0.05, e.Size.X * s.X), math.max(0.05, e.Size.Y * s.Y), math.max(0.05, e.Size.Z * s.Z))
		p.CFrame = cf * CFrame.new(e.Off.X * sx, yStart + (e.Off.Y - y0) * sy, e.Off.Z * sz) * e.Rot
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		style(e.Group, p, e.Sec)
		p.Parent = model
		table.insert(out, p)
	end
	local midStart = info.Base * sb
	local topStart = midStart + n * (info.Mid or 0) * sm
	for _, e in tpl.Entries do
		if e.Sec == "Base" then
			put(e, 0, 0, sb)
		elseif e.Sec == "Medio" then
			for i = 0, n - 1 do
				put(e, info.Base, midStart + i * info.Mid * sm, sm)
			end
		elseif e.Sec == "Tope" then
			put(e, info.Base + (info.Mid or 0), topStart, st)
		end
	end
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	model.Parent = parent
	return model, out
end

-- Descarga una pieza (una vez por servidor) y la deja como plantilla. Cede mientras descarga.
local cache: { [string]: Template | false } = {}
function PlanetCityMeshes.load(name: string): Template?
	local hit = cache[name]
	if hit ~= nil then
		return if hit then hit else nil
	end
	cache[name] = false
	local id = PlanetCityMeshes.idOf((ids().Mallas or {})[name])
	if not id or not shapes()[name] then
		return nil
	end
	local ok, asset = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	if not ok or not asset then
		warn("[PlanetCityMeshes] no se pudo cargar " .. name .. ": " .. tostring(asset))
		return nil
	end
	local tpl = PlanetCityMeshes.prepare(name, asset)
	if not tpl then
		warn("[PlanetCityMeshes] " .. name .. " llegó sin mallas con nombre «_<Seccion>_<Grupo>»")
		asset:Destroy()
		return nil
	end
	for _, e in tpl.Entries do
		e.Part.Anchored = true
	end
	cache[name] = tpl
	return tpl
end

return PlanetCityMeshes
