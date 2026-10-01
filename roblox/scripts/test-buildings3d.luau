-- Prueba de los edificios 3D (World/Buildings3D) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-buildings3d.luau                (kit falso y bloques como los de Kit/Lite)
--   lune run scripts/test-buildings3d.luau /tmp/x.rbxl     (además, con los bloques del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- En Lune no hay AssetService ni InsertService: se hace un kit falso ("Modular Building Kit - Modern
-- City" con PrefabBuildings A–K y "Model" de MeshPart con las tallas del doc, los 8 scripts del H, el
-- cartel del pack, luces y una carpeta Materials) y un "Modern City Materials Pack" falso. Comprueba:
--   * se borran los scripts, el cartel y las luces; los MaterialVariant van a MaterialService con
--     prefijo (sin chocar con los nuestros) y las piezas apuntan al nombre nuevo
--   * la fachada de cada prefab (toldos y puertas delante, escalera de incendios detrás)
--   * se elige el prefab por proporción (o varios en fila), escalado dentro de la huella del bloque,
--     con la fachada hacia la calle y apoyado en el suelo; sin hueco: el bloque se queda
--   * el bloque conserva nombre, padre, atributos, etiquetas, puerta y cartel (InteriorService sigue
--     igual); cuerpo invisible sin choque (BuildingShell), mallas sin choque (BuildingMesh) y una caja
--     invisible de choque por prefab
--   * no se tocan casas, hoteles, facultades ni edificios de Kit/Building; sin plantillas, nada; topes

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Vector3, Color3, CFrame, Instance = roblox.Enum, roblox.Vector3, roblox.Color3, roblox.CFrame, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }): any
	local full = setmetatable(env, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = full })()
end

local waits = 0
local base = {
	Enum = Enum,
	Vector3 = Vector3,
	Color3 = Color3,
	CFrame = CFrame,
	Instance = Instance,
	task = {
		wait = function()
			waits += 1
		end,
	},
	warn = function() end,
}
local function env(extra: { [string]: any }): { [string]: any }
	local out = table.clone(base)
	for k, v in extra do
		out[k] = v
	end
	return out
end

local MESHLIB = {}
local MeshLibrary = load("src/server/World/MeshLibrary.luau", env({}))
local Buildings3D = load("src/server/World/Buildings3D.luau", env({
	script = { Parent = { MeshLibrary = MESHLIB } },
	require = function(m)
		if m == MESHLIB then
			return MeshLibrary
		end
		error("require inesperado")
	end,
}))
local Entrances = load("src/server/World/Entrances.luau", env({}))

---------------------------------------------------------------------
-- Kit falso (mismos nombres y tallas que el de verdad: docs/modelos-oficiales-2.md)
---------------------------------------------------------------------
local OFFSET = Vector3.new(500, 3, -200) -- el kit no está en el origen
local SIZES = {
	A = { 34, 94, 49 }, B = { 34, 94, 57 }, C = { 55, 69, 70 }, E = { 64, 86, 64 }, F = { 50, 94, 58 },
	G = { 39, 104, 44 }, I = { 109, 164, 84 }, J = { 53, 183, 119 }, K = { 87, 247, 57 }, H = { 88, 209, 61 },
	Model = { 35, 78, 32 },
}
local FRONTS = { C = "+X" } -- (el C mira a +X; los demás a -Z)

local function mesh(parent: any, name: string, size: any, center: any)
	local p = Instance.new("MeshPart")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(center)
	p.Anchored = false
	p.CanCollide = true
	local sa = Instance.new("SurfaceAppearance")
	sa.Parent = p
	p.Parent = parent
	return p
end

local function prefab(parent: any, name: string, dims: { number }, front: string?)
	local m = Instance.new("Model")
	m.Name = name
	local x, y, z = dims[1], dims[2], dims[3]
	local wall = mesh(m, "Bldg_Wall_Low_A", Vector3.new(x - 1, y, z - 1), OFFSET + Vector3.new(0, y / 2, 0))
	pcall(function()
		(wall :: any).MaterialVariant = "Plaster_A"
	end)
	-- Fachada: toldos, puerta y escaparate abajo; detrás, la escalera de incendios y el aire
	local fx, fz = 0, -z / 2 + 1.5
	local ax, az = 0, z / 2 - 1.5
	local awningSize = Vector3.new(x * 0.6, 1, 3)
	if front == "+X" then
		fx, fz, ax, az = x / 2 - 1.5, 0, -x / 2 + 1.5, 0
		awningSize = Vector3.new(3, 1, z * 0.6)
	end
	mesh(m, "Bldg_Addon_Awning_A", awningSize, OFFSET + Vector3.new(fx, 10, fz))
	mesh(m, "Bldg_Door_A", Vector3.new(4, 8, 1), OFFSET + Vector3.new(fx * 0.98, 4, fz * 0.98))
	mesh(m, "Bldg_Addon_FireEscape_A", Vector3.new(6, y * 0.6, 2), OFFSET + Vector3.new(ax, y * 0.4, az))
	mesh(m, "Bldg_Addon_ACUnit_A", Vector3.new(3, 3, 2), OFFSET + Vector3.new(ax * 0.9, 20, az * 0.9))
	-- Detalle pequeño (tornillería: sin sombra)
	mesh(m, "Bldg_Trim_Small", Vector3.new(1, 1, 1), OFFSET + Vector3.new(0, y - 0.5, 0))
	if name == "E" then
		-- Este trae la acera debajo (no es del edificio)
		mesh(m, "Sidewalk_Base", Vector3.new(x + 12, 0.5, z + 12), OFFSET + Vector3.new(0, 0.25 - 0.5, 0))
	end
	if name == "K" then
		Instance.new("PointLight").Parent = wall
	end
	if name == "H" then
		for i = 1, 8 do
			local s = Instance.new(if i % 2 == 0 then "Script" else "LocalScript")
			s.Name = "Script" .. i
			s.Parent = if i <= 4 then m else wall
		end
	end
	m.Parent = parent
	return m
end

local function fakeKit()
	local root = Instance.new("Model")
	root.Name = "Model"
	local kit = Instance.new("Folder")
	kit.Name = "Modular Building Kit - Modern City"
	kit.Parent = root
	local prefabs = Instance.new("Folder")
	prefabs.Name = "PrefabBuildings"
	prefabs.Parent = kit
	for name, dims in SIZES do
		prefab(prefabs, name, dims, FRONTS[name])
	end
	-- Piezas del kit (no son edificios enteros: no se usan)
	local pieces = Instance.new("Folder")
	pieces.Name = "Modular Building Kit"
	pieces.Parent = kit
	mesh(pieces, "Bldg_Wall_High_B", Vector3.new(16, 16, 1), Vector3.new(0, 8, 0))
	local placards = Instance.new("Folder")
	placards.Name = "Information Placards"
	placards.Parent = kit
	local billboard = Instance.new("Model")
	billboard.Name = "Bldg_Addon_Billboard_A"
	mesh(billboard, "Board", Vector3.new(20, 10, 1), Vector3.new(0, 5, 0))
	billboard.Parent = placards
	local materials = Instance.new("Folder")
	materials.Name = "Materials"
	materials.Parent = kit
	for _, n in { "Plaster_A", "Brick_A" } do
		local v = Instance.new("MaterialVariant")
		v.Name = n
		v.Parent = materials
	end
	return root
end

local MATERIALS = { "Plaster_A", "PaintedBrick", "Sidewalk_A", "Concrete_A", "Concrete_B", "Concrete_C", "CarPaint_A", "Metal_A" }
local function fakeMaterials()
	local root = Instance.new("Model")
	root.Name = "Model"
	for _, n in MATERIALS do
		local v = Instance.new("MaterialVariant")
		v.Name = n
		v.Parent = root
	end
	return root
end

---------------------------------------------------------------------
-- Bloques como los de Kit/Lite (cuerpo, franjas, montantes, cornisa, zócalo, puerta, cartel)
---------------------------------------------------------------------
local function part(parent: any, name: string, cf: any, size: any)
	local p = Instance.new("Part")
	p.Name = name
	p.CFrame = cf
	p.Size = size
	p.Anchored = true
	p.Parent = parent
	return p
end

local function liteBlock(parent: any, cf: any, w: number, d: number, h: number, name: string?, plain: boolean?)
	local m = Instance.new("Model")
	m.Name = name or "Bloque"
	part(m, "Body", cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d))
	if not plain then
		for f = 1, math.max(1, math.floor(h / 11)) do
			local y = (f - 0.5) * 11
			local win = part(m, "Windows", cf * CFrame.new(0, y, -d / 2 - 0.15), Vector3.new(w - 4, 5, 0.3))
			if f == 1 then
				win:AddTag("NightWindow")
			end
			part(m, "BackWindows", cf * CFrame.new(0, y, d / 2 + 0.15), Vector3.new(w - 4, 5, 0.3))
			part(m, "SideWindows", cf * CFrame.new(w / 2 + 0.15, y, 0), Vector3.new(0.3, 5, d - 6))
		end
		part(m, "Mullion", cf * CFrame.new(0, h / 2, -d / 2 - 0.35), Vector3.new(0.7, h - 1, 0.4))
		part(m, "Cornice", cf * CFrame.new(0, h + 0.6, 0), Vector3.new(w + 1, 1.2, d + 1))
		part(m, "StonePlinth", cf * CFrame.new(0, 0.7, 0), Vector3.new(w + 0.36, 1.4, d + 0.36)):AddTag("CityDetail")
		part(m, "Door", cf * CFrame.new(0, 3.5, -d / 2 - 0.2), Vector3.new(4, 7, 0.4))
		local sign = part(m, "Sign", cf * CFrame.new(0, 9.6, -d / 2 - 0.35), Vector3.new(14, 2, 0.3))
		local gui = Instance.new("SurfaceGui")
		local label = Instance.new("TextLabel")
		label.Text = "FARMACIA"
		label.Parent = gui
		gui.Parent = sign
	end
	m:SetAttribute("Foo", 7)
	m:AddTag("SomeTag")
	m.Parent = parent
	return m
end

local function folder(parent: any, name: string)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function countClass(root: any, pred: (any) -> boolean): number
	local n = 0
	for _, d in root:GetDescendants() do
		if pred(d) then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
print("Plantillas (kit falso)")
---------------------------------------------------------------------
local kit, mats = fakeKit(), fakeMaterials()
local service = Instance.new("Folder")
service.Name = "MaterialService"
local map = Buildings3D.installVariants({ kit, mats }, service)
local templates = Buildings3D.prepare({ kit, mats }, map)
local byName = {}
for _, t in templates do
	byName[t.Name] = t
end
check(#templates == 11, ("11 prefabs (A–K y Model): %d"):format(#templates))
check(countClass(kit, function(d)
	return d:IsA("LuaSourceContainer")
end) == 0, "se borran todos los scripts de lo cargado (los 8 del H)")
local scriptsLeft = 0
for _, t in templates do
	scriptsLeft += countClass(t.Model, function(d)
		return d:IsA("LuaSourceContainer")
	end)
end
check(scriptsLeft == 0, "las plantillas no llevan scripts")
check(kit:FindFirstChild("Bldg_Addon_Billboard_A", true) == nil, "fuera el cartel del pack (Bldg_Addon_Billboard_A)")
local lights = 0
for _, t in templates do
	lights += countClass(t.Model, function(d)
		return d:IsA("PointLight") or d:IsA("MaterialVariant")
	end)
end
check(lights == 0, "sin luces (ni variants) dentro de las plantillas")
check(byName.E and math.abs(byName.E.FW - 64) < 0.01 and math.abs(byName.E.FD - 64) < 0.01, "la acera que trae un prefab debajo no cuenta (E: 64×64)")
local frontsOk = true
for name, t in byName do
	local want = if FRONTS[name] == "+X" then Vector3.new(1, 0, 0) else Vector3.new(0, 0, -1)
	if (t.Front - want).Magnitude > 0.01 then
		frontsOk = false
		print("    fachada mal: " .. name .. " " .. t.Why)
	end
end
check(frontsOk, "fachada de cada prefab: la de los toldos y la puerta (C mira a +X; el resto a -Z)")
check(byName.C and math.abs(byName.C.FW - 70) < 0.01 and math.abs(byName.C.FD - 55) < 0.01, "C: ancho de fachada 70 y fondo 55 (mira a +X)")
check(byName.A.Parts == 5 and byName.A.H > 93 and byName.A.H < 95, ("piezas y alto medidos (A: %d piezas, %.0f de alto)"):format(byName.A.Parts, byName.A.H))
-- Materiales
local nVariants, clash = 0, false
local Textures = load("src/shared/Textures.luau", env({}))
for _, v in service:GetChildren() do
	if v:IsA("MaterialVariant") then
		nVariants += 1
		if Textures.Variants[v.Name] or not v.Name:match("^ModernCity_") then
			clash = true
		end
	end
end
check(nVariants == 9 and not clash, ("MaterialVariant en MaterialService con prefijo ModernCity_ (%d; no chocan con shared/Textures)"):format(nVariants))
local wall = byName.A.Model:FindFirstChild("Bldg_Wall_Low_A", true)
local okVariant = pcall(function()
	assert((wall :: any).MaterialVariant == "ModernCity_Plaster_A")
end)
check(okVariant, "las piezas del prefab usan el variant con su nombre nuevo")

---------------------------------------------------------------------
print("Qué prefab y a qué escala")
---------------------------------------------------------------------
local function infoOf(w: number, d: number, h: number)
	return { CFrame = CFrame.new(0, 0, 0), W = w, D = d, H = h, Why = "" }
end
do
	local plan = Buildings3D.plan(infoOf(34, 50, 94), templates)
	check(plan and #plan == 1 and plan[1].Template.Name == "A", "estrecho y hondo (34×50×94): A (34×49)")
	plan = Buildings3D.plan(infoOf(62, 62, 80), templates)
	check(plan and #plan == 1 and plan[1].Template.Name == "E", "cuadrado (62×62×80): E (64×64)")
	plan = Buildings3D.plan(infoOf(70, 56, 70), templates)
	check(plan and #plan == 1 and plan[1].Template.Name == "C", "70×56×70: C (de lado: 70 de fachada)")
	plan = Buildings3D.plan(infoOf(120, 34, 60), templates)
	check(plan and #plan >= 2, ("largo (120×34): %d en fila"):format(if plan then #plan else 0))
	local inside = true
	for _, info in { infoOf(68, 34, 44), infoOf(120, 34, 60), infoOf(56, 40, 120), infoOf(60, 50, 300) } do
		local p = Buildings3D.plan(info, templates)
		for _, s in p or {} do
			local ws = info.W / #p
			if s.Template.FW * s.Scale > ws + 1e-6 or s.Template.FD * s.Scale > info.D + 1e-6 or s.Scale < Buildings3D.MinScale or s.Scale > Buildings3D.MaxScale then
				inside = false
			end
			if s.Template.FW * s.Scale < ws * Buildings3D.MinFill then
				inside = false
			end
		end
	end
	check(inside, "cada prefab cabe en su hueco (ancho y fondo), llena la fachada y con escala razonable")
	check(Buildings3D.plan(infoOf(40, 32, 21), templates) == nil, "una tienda de una planta (40×32×21): ninguno encaja, se queda el bloque")
	check(Buildings3D.plan(infoOf(40, 32, 40), {}) == nil, "sin plantillas: no hay plan")
end

---------------------------------------------------------------------
print("Cambiar un bloque")
---------------------------------------------------------------------
local function localBounds(model: any, frame: any, filter: (any) -> boolean)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and filter(p) then
			local cf, s = p.CFrame, p.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local c = frame:PointToObjectSpace(cf:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)))
						lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
						hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
					end
				end
			end
		end
	end
	return lo, hi
end
local function isMesh(p: any): boolean
	return p:IsA("MeshPart") and p.Parent and p.Parent.Name == "Fachada3D"
end

-- Comprueba un bloque cambiado: dentro de la huella, fachada a la calle, en el suelo
local function verify(model: any, frame: any, w: number, d: number, bottom: number): { [string]: boolean }
	local r = { Inside = true, Front = true, Ground = true }
	local lo, hi = localBounds(model, frame, isMesh)
	if lo.X < -w / 2 - 0.5 or hi.X > w / 2 + 0.5 or lo.Z < -d / 2 - 0.5 or hi.Z > d / 2 + 0.5 then
		r.Inside = false
	end
	if math.abs(lo.Y - bottom) > 0.05 then
		r.Ground = false
	end
	-- (frame: -Z = fachada) los toldos y la puerta del prefab, delante; la escalera de incendios, detrás
	for _, p in model:GetDescendants() do
		if isMesh(p) then
			local z = frame:PointToObjectSpace(p.Position).Z
			if (p.Name == "Bldg_Addon_Awning_A" or p.Name == "Bldg_Door_A") and z > -d / 2 + 5 then
				r.Front = false
			elseif p.Name == "Bldg_Addon_FireEscape_A" and z < 0 then
				r.Front = false
			end
		end
	end
	return r
end

do
	local town = Instance.new("Model")
	town.Name = "Town"
	local manzana = folder(town, "Manzana_Pisos")
	-- Bloque girado: su fachada mira a +X (la calle está al este)
	local cf = CFrame.new(300, 2, 100) * CFrame.Angles(0, -math.pi / 2, 0)
	local block = liteBlock(manzana, cf, 62, 62, 80)
	local kindBefore, titleBefore = Entrances.classify(block)
	local doorBefore = Entrances.doorPart(block)
	local info = Buildings3D.info(block, nil)
	check(info and (info.CFrame.LookVector - Vector3.new(1, 0, 0)).Magnitude < 1e-3 and info.Why == "Door", "fachada del bloque: la de su puerta (mira a +X)")
	check(info and math.abs(info.W - 62) < 1e-6 and math.abs(info.D - 62) < 1e-6 and math.abs(info.H - 80) < 1e-6, "huella y alto del bloque (su Body)")
	local plan = Buildings3D.replace(block, templates, nil)
	check(plan ~= nil and block:GetAttribute("Prefab3D") == "E", "cambiado por el E (" .. tostring(block:GetAttribute("Prefab3D")) .. ")")
	local frame = (info :: any).CFrame
	local r = verify(block, frame, 62, 62, 2)
	check(r.Inside, "dentro de la huella del bloque (nunca más de 0,5 fuera: no pisa la acera)")
	check(r.Front, "la fachada del prefab (toldos, puerta) mira a la calle; la escalera de incendios, detrás")
	check(r.Ground, "apoyado en el suelo del bloque")
	check(block.Name == "Bloque" and block.Parent == manzana and block:GetAttribute("Foo") == 7 and block:HasTag("SomeTag"), "mismo nombre, padre, atributos y etiquetas")
	local body = block:FindFirstChild("Body")
	check(body and body.Transparency == 1 and not body.CanCollide and not body.CanQuery and body:HasTag("BuildingShell"), "el cuerpo se queda invisible y sin choque (BuildingShell: en Bajo se ve)")
	local door = block:FindFirstChild("Door")
	check(door and door == doorBefore and door:HasTag("BuildingShell") and door.Transparency == 1, "la puerta (Door) se queda, invisible: InteriorService sabe dónde entrar")
	check(block:FindFirstChild("Sign") and Entrances.signText(block) == "FARMACIA", "el cartel se queda (la tienda de dentro va con él)")
	local kindAfter, titleAfter = Entrances.classify(block)
	check(kindAfter == kindBefore and titleAfter == titleBefore and Entrances.doorPart(block) == doorBefore, "InteriorService lo clasifica igual (" .. tostring(kindAfter) .. ")")
	check(not block:FindFirstChild("Windows") and not block:FindFirstChild("Cornice") and not block:FindFirstChild("StonePlinth") and not block:FindFirstChild("Mullion"), "fuera las franjas de ventanas, montantes, cornisa y zócalo")
	local okMesh, shadows, small = true, 0, true
	for _, p in block:GetDescendants() do
		if isMesh(p) then
			if p.CanCollide or p.CanQuery or p.CanTouch or not p.Anchored or not p:HasTag("BuildingMesh") then
				okMesh = false
			end
			if p.CastShadow then
				shadows += 1
			end
			if p.Name == "Bldg_Trim_Small" and p.CastShadow then
				small = false
			end
		end
	end
	check(okMesh, "mallas ancladas, sin choque ni consultas, con BuildingMesh (en Bajo se esconden)")
	check(shadows > 0 and small, "sombra solo en lo grande")
	local colliders = 0
	for _, d in block:GetDescendants() do
		if d.Name == "BuildingCollider" then
			colliders += 1
			local lo, hi = localBounds(d.Parent, frame, function(p)
				return p == d
			end)
			if not d.CanCollide or d.Transparency ~= 1 or lo.X < -31.5 or hi.X > 31.5 or lo.Z < -31.5 or hi.Z > 31.5 then
				colliders = -100
			end
		end
	end
	check(colliders == #(plan or {}), "una caja de choque invisible por prefab, dentro de la huella")
	check(Buildings3D.replace(block, templates, nil) == nil, "un bloque ya cambiado no se vuelve a cambiar")

	-- Prefab de lado (C mira a +X) en un bloque que mira a -Z
	local side = liteBlock(manzana, CFrame.new(-400, 0, 50), 70, 56, 70)
	local sideInfo = Buildings3D.info(side, nil)
	Buildings3D.replace(side, templates, nil)
	local rs = verify(side, (sideInfo :: any).CFrame, 70, 56, 0)
	check(side:GetAttribute("Prefab3D") == "C" and rs.Inside and rs.Front and rs.Ground, "prefab girado (C: fachada en +X) mirando a la calle del bloque, dentro y en el suelo")

	-- Bloque largo: varios en fila
	local long = liteBlock(manzana, CFrame.new(0, 0, -600) * CFrame.Angles(0, math.pi, 0), 120, 34, 60)
	local longInfo = Buildings3D.info(long, nil)
	local longPlan = Buildings3D.replace(long, templates, nil)
	local rl = verify(long, (longInfo :: any).CFrame, 120, 34, 0)
	check(longPlan and #longPlan >= 2 and rl.Inside and rl.Front and rl.Ground, ("bloque largo: %d prefabs en fila, dentro, de cara a la calle y en el suelo"):format(if longPlan then #longPlan else 0))
end

---------------------------------------------------------------------
print("Fachada por la calle (bloque sin puerta ni ventanas)")
---------------------------------------------------------------------
do
	local m = folder(Instance.new("Model"), "Manzana_Downtown")
	local block = liteBlock(m, CFrame.new(1000, 0, 1000), 50, 40, 90, nil, true)
	local segments = { { A = Vector3.new(900, 0, 1040), B = Vector3.new(1100, 0, 1040), Kind = "Calle" } }
	local info = Buildings3D.info(block, segments)
	check(info and (info.CFrame.LookVector - Vector3.new(0, 0, 1)).Magnitude < 1e-3 and info.Why == "calle", "sin pistas: mira a la calle más cercana (+Z)")
	check(info and math.abs(info.W - 50) < 1e-6 and math.abs(info.D - 40) < 1e-6, "ancho y fondo según esa fachada")
end

---------------------------------------------------------------------
print("Lo que no se toca")
---------------------------------------------------------------------
do
	local town = Instance.new("Model")
	local campus = folder(town, "Manzana_Campus")
	local hotelBlock = folder(town, "Manzana_Hotel")
	local casas = folder(town, "Manzana_Casas")
	local centro = folder(town, "Colegio")
	local fac = liteBlock(campus, CFrame.new(0, 0, 0), 62, 62, 80)
	local hotel = liteBlock(hotelBlock, CFrame.new(200, 0, 0), 62, 62, 80, "Hotel")
	local casa = liteBlock(casas, CFrame.new(400, 0, 0), 62, 62, 80, "Casa")
	local edificio = liteBlock(centro, CFrame.new(600, 0, 0), 62, 62, 80, "Edificio")
	local taller = liteBlock(folder(town, "Manzana_Taller"), CFrame.new(800, 0, 0), 62, 62, 80, "Taller")
	local before = #town:GetDescendants()
	local found = Buildings3D.collect({ town }, nil)
	check(#found == 0, "facultades (residencias), hoteles, casas, talleres y edificios de Kit/Building no entran")
	local untouched = true
	for _, b in { fac, hotel, casa, edificio, taller } do
		if Buildings3D.replace(b, templates, nil) ~= nil or b:GetAttribute("Prefab3D") ~= nil then
			untouched = false
		end
	end
	local done = Buildings3D.run({ town }, templates, nil)
	check(untouched and done.Buildings == 0 and #town:GetDescendants() == before, "se quedan enteros")
end

---------------------------------------------------------------------
print("Sin plantillas (falla la carga)")
---------------------------------------------------------------------
do
	local town = Instance.new("Model")
	local m = folder(town, "Manzana_Pisos")
	local block = liteBlock(m, CFrame.new(0, 0, 0), 62, 62, 80)
	local before = #town:GetDescendants()
	local empty = Buildings3D.prepare({})
	local done = Buildings3D.run({ town }, empty, nil)
	check(#empty == 0 and done.Buildings == 0 and #town:GetDescendants() == before, "no se cambia nada")
	check(Buildings3D.replace(block, empty, nil) == nil and block:FindFirstChild("Windows") ~= nil, "replace sin plantillas deja el bloque como estaba")
	local okLoad, result = pcall(Buildings3D.load)
	check(okLoad and result == nil, "Buildings3D.load() en Lune (sin AssetService) no rompe y no devuelve nada")
	local okStart = pcall(Buildings3D.start, {})
	check(okStart, "Buildings3D.start() tampoco rompe (se quedan los bloques)")
	check(Buildings3D.loadAsset(1) == nil, "loadAsset sin servicios: nil")
end

---------------------------------------------------------------------
print("Topes y orden")
---------------------------------------------------------------------
do
	local town = Instance.new("Model")
	local m = folder(town, "Manzana_Pisos")
	local far, near = {}, {}
	for i = 1, 4 do
		table.insert(far, liteBlock(m, CFrame.new(3000 + i * 100, 0, 3000), 62, 62, 80))
		table.insert(near, liteBlock(m, CFrame.new(i * 100, 0, 200), 62, 62, 80))
	end
	local oldCopies, oldParts = Buildings3D.MaxCopies, Buildings3D.MaxParts
	Buildings3D.MaxCopies = 3
	waits = 0
	local done = Buildings3D.run({ town }, templates, nil)
	Buildings3D.MaxCopies = oldCopies
	local nearDone = 0
	for _, b in near do
		if b:GetAttribute("Prefab3D") then
			nearDone += 1
		end
	end
	local farDone = 0
	for _, b in far do
		if b:GetAttribute("Prefab3D") then
			farDone += 1
		end
	end
	check(done.Copies <= 3 and done.Buildings == 3 and nearDone == 3 and farDone == 0, ("tope de prefabs (3): %d cambiados, primero los del centro"):format(done.Buildings))
	check(waits > 0, "va en tandas (task.wait entre tandas)")
	Buildings3D.MaxParts = byName.E.Parts * 2
	local done2 = Buildings3D.run({ town }, templates, nil)
	Buildings3D.MaxParts = oldParts
	check(done2.Parts <= byName.E.Parts * 2 and done2.Buildings <= 2, ("tope de piezas: %d piezas"):format(done2.Parts))
end

---------------------------------------------------------------------
print("Enganches (Main, InteriorService, MaterialDetail)")
---------------------------------------------------------------------
do
	local main = fs.readFile("src/server/Main.server.luau")
	check(main:find("World.Buildings3D", 1, true) and main:find("task.spawn", 1, true), "Main arranca Buildings3D en un hilo aparte")
	local interiors = fs.readFile("src/server/Services/InteriorService.luau")
	check(interiors:find('SetAttribute("InteriorsScanned", true)', 1, true), "InteriorService avisa cuando ya ha mirado los edificios")
	local detail = fs.readFile("src/client/Controllers/MaterialDetail.luau")
	check(detail:find('BuildingMesh = "CityDetail"', 1, true) and detail:find('BuildingShell = "CityDetail"', 1, true), "gráficos Bajo: se esconden las mallas y se enseña la caja de antes")
	local src = fs.readFile("src/server/World/Buildings3D.luau")
	check(src:find("LoadAssetAsync", 1, true) and src:find("InsertService", 1, true), "carga con AssetService:LoadAssetAsync y, si falla, InsertService:LoadAsset")
	check(not src:find("SetBaseMaterialOverride", 1, true), "no cambia los overrides globales de materiales")
end

---------------------------------------------------------------------
-- El mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("Mapa construido (" .. placePath .. ")")
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local ws = place:GetService("Workspace")
	local town = ws:FindFirstChild("Town")
	local found = Buildings3D.collect({ town }, nil)
	check(#found > 800, ("%d bloques que se pueden cambiar"):format(#found))
	local planned, slots, parts = 0, 0, 0
	for _, b in found do
		local info = Buildings3D.info(b, nil)
		local plan = info and Buildings3D.plan(info, templates)
		if plan then
			planned += 1
			slots += #plan
		end
	end
	print(("    con el kit falso encajan %d de %d (%d prefabs)"):format(planned, #found, slots))
	check(planned > #found * 0.3, "una buena parte encaja con algún prefab")
	local bad, n, sameKind = 0, 0, true
	for i = 1, #found, 17 do
		local b = found[i]
		local info = Buildings3D.info(b, nil)
		local kind = Entrances.classify(b)
		local door = Entrances.doorPart(b)
		local bottom = info and info.CFrame.Position.Y or 0
		local ok, plan = pcall(Buildings3D.replace, b, templates, nil)
		if ok and plan then
			n += 1
			local r = verify(b, (info :: any).CFrame, info.W, info.D, bottom)
			if not (r.Inside and r.Front and r.Ground) then
				bad += 1
			end
			if Entrances.classify(b) ~= kind or Entrances.doorPart(b) ~= door then
				sameKind = false
			end
		elseif not ok then
			bad += 1
			print("    " .. tostring(plan))
		end
	end
	check(n > 10 and bad == 0, ("%d bloques del mapa cambiados: dentro de su huella, de cara a la calle y en el suelo (%d raros)"):format(n, bad))
	check(sameKind, "InteriorService los clasifica igual y su puerta es la misma")
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
