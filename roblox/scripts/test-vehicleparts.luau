-- Prueba del TALLER (fase 0 de docs/personalizar-vehiculos.md) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-vehicleparts.luau
--
-- Carga los módulos compartidos nuevos (shared/VehicleParts y shared/VehicleBuild) y los modelos
-- DE VERDAD (World/Builder, Kit/Palette, Kit/CarModel, Kit/Rides) con instancias de Lune.
-- Comprueba:
--   * catálogo: ids únicos, huecos, tipos, precios, desbloqueos, recuentos (20 pinturas, 4 acabados,
--     12 llantas × 6 colores, 3 neumáticos, 3 alerones, 2 parachoques por carrocería, 4 lunas,
--     8 neones), sin campos de rendimiento ni de Robux; anclas = modelo construido;
--   * validate: ids desconocidos, de otro tipo/carrocería, bloqueados, kits, pase, números con
--     tope, basura, 10.000 campos, migración V0, V futura, matrícula;
--   * apply/clear en todas las carrocerías del coche, moto, bici, patinete y monopatín: piezas
--     Mod_ sin colisión, dentro de la caja del chasis, presupuesto, sin tocar los nombres
--     reservados, misma colisión y asientos, determinista, y clear lo deja todo como estaba;
--   * guardar/cargar como el DataStore (JSON) y precios.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local CFrame, Vector3, Color3, Enum, Instance = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Cargar módulos (require por nombre)
---------------------------------------------------------------------
local mods = {}
local baseEnv = {
	Instance = Instance,
	CFrame = CFrame,
	Vector3 = Vector3,
	Color3 = Color3,
	Enum = Enum,
	UDim2 = roblox.UDim2,
	UDim = roblox.UDim,
	Font = roblox.Font,
}
local function load(path: string, name: string)
	local env = setmetatable(table.clone(baseEnv), { __index = getfenv(1) })
	env.script = { Parent = { Parent = { Builder = "Builder" }, Palette = "Palette", CarModel = "CarModel", VehicleParts = "VehicleParts" } }
	env.require = function(key)
		return mods[key] or error("módulo sin cargar: " .. tostring(key))
	end
	mods[name] = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	return mods[name]
end
load("src/server/World/Builder.luau", "Builder")
load("src/server/World/Kit/Palette.luau", "Palette")
local CarModel = load("src/server/World/Kit/CarModel.luau", "CarModel")
local Rides = load("src/server/World/Kit/Rides.luau", "Rides")
local VehicleParts = load("src/shared/VehicleParts.luau", "VehicleParts")
local VehicleBuild = load("src/shared/VehicleBuild.luau", "VehicleBuild")

local PAINT = Color3.fromRGB(200, 60, 60)
local CF = CFrame.new(120, 4, -35) * CFrame.Angles(0, 0.7, 0) -- sitio girado: las cuentas no dependen del origen

-- Modelo de serie: el coche del jugador (Rides.coche = berlina) o cualquier carrocería de CarModel
local function makeModel(kind: string, body: string?, cf: any?)
	local at = cf or CF
	math.randomseed(7) -- (Rides.coche pone una matrícula al azar: así sale siempre la misma)
	if kind == "Coche" and body and body ~= "Berlina" then
		local m = CarModel.build(nil, at, PAINT, { Name = "Coche", Variant = body, Interior = true, Plate = "0000 VLM" })
		return m
	end
	return Rides.build(kind, nil, at, PAINT)
end

local function r3(n: number): string
	return string.format("%.3f", n)
end
local function vstr(v): string
	return r3(v.X) .. "," .. r3(v.Y) .. "," .. r3(v.Z)
end
local function cfstr(cf): string
	local c = { cf:GetComponents() }
	local out = {}
	for _, n in c do
		table.insert(out, r3(n))
	end
	return table.concat(out, ",")
end
local function colorstr(c): string
	return r3(c.R) .. "," .. r3(c.G) .. "," .. r3(c.B)
end
local function partString(p, withLook: boolean): string
	local s = p.ClassName .. "|" .. p.Name .. "|" .. vstr(p.Size) .. "|" .. cfstr(p.CFrame) .. "|" .. tostring(p.CanCollide) .. "|" .. tostring(p.Anchored)
	if withLook then
		s ..= "|" .. colorstr(p.Color) .. "|" .. p.Material.Name .. "|" .. r3(p.Reflectance) .. "|" .. r3(p.Transparency)
	end
	return s
end
-- Foto de todas las piezas (y textos de matrícula) del modelo
local function snapshot(model): { string }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, partString(d, true))
		elseif d:IsA("TextLabel") then
			table.insert(out, "Text|" .. d.Text)
		end
	end
	return out
end
local function same(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end
local function mods_(model): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, 4) == "Mod_" then
			table.insert(list, d)
		end
	end
	return list
end
local function isReservedName(name: string): boolean
	return VehicleParts.isReserved(name)
end
-- Piezas con nombre reservado: forma, sitio, colisión y (salvo Body) aspecto
local function reservedSnapshot(model): { string }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and isReservedName(d.Name) then
			table.insert(out, partString(d, d.Name ~= "Body") .. "|" .. r3(d.Transparency))
		end
	end
	return out
end
local function collideSnapshot(model): { string }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and (d.CanCollide or d:GetAttribute("Collide") == true) then
			table.insert(out, d.Name .. "|" .. vstr(d.Size) .. "|" .. cfstr(d.CFrame))
		end
	end
	return out
end
local function heightOf(model, origin): number
	local top = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, 4) ~= "Mod_" then
			local p = origin:PointToObjectSpace(d.CFrame.Position)
			top = math.max(top, p.Y + d.Size.Magnitude / 2)
		end
	end
	return top
end
-- ¿La pieza cabe en la caja del chasis (+0,3) y por encima del suelo?
local function insideBox(part, origin, kind: string, top: number): (boolean, string)
	local size = Rides.Spec[kind].Size
	local hx, hz = size.X / 2 + 0.3 + 1e-3, size.Z / 2 + 0.3 + 1e-3
	local h = part.Size / 2
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local world = part.CFrame * CFrame.new(sx * h.X, sy * h.Y, sz * h.Z)
				local p = origin:PointToObjectSpace(world.Position)
				if math.abs(p.X) > hx or math.abs(p.Z) > hz or p.Y < -0.05 or p.Y > top + 0.3 then
					return false, part.Name .. " en " .. vstr(p)
				end
			end
		end
	end
	return true, ""
end

---------------------------------------------------------------------
print("Catálogo")
---------------------------------------------------------------------
local SLOTS = { Paint = true, Finish = true, Rims = true, RimColor = true, Tires = true, Spoiler = true, BumperF = true, BumperR = true, Neon = true, Kit = true, Body = true }
local SOURCES = { Shop = true, Level = true, Pass = true }
local count = 0
for _ in VehicleParts.Parts do
	count += 1
end
check(count == #VehicleParts.List, ("ids únicos (%d piezas)"):format(count))
local problems = {}
for _, part in VehicleParts.List do
	local function bad(what: string)
		table.insert(problems, part.Id .. ": " .. what)
	end
	if type(part.Id) ~= "string" or not string.match(part.Id, "^[%w_]+$") then
		bad("id raro")
	end
	if type(part.Name) ~= "string" or #part.Name < 2 or string.find(part.Name, "_") or string.find(part.Name, "Nova") then
		bad("nombre")
	end
	if not SLOTS[part.Slot] then
		bad("hueco " .. tostring(part.Slot))
	end
	if type(part.Attach) ~= "string" then
		bad("sin Attach")
	end
	if type(part.Kinds) ~= "table" or #part.Kinds == 0 then
		bad("sin tipos")
	else
		for _, kind in part.Kinds do
			if not VehicleParts.isCustomizable(kind) then
				bad("tipo " .. tostring(kind))
			end
		end
	end
	for _, body in part.Bodies or {} do
		if not table.find(VehicleParts.Bodies, body) then
			bad("carrocería " .. tostring(body))
		end
	end
	if type(part.Price) ~= "number" or part.Price < 0 or part.Price % 1 ~= 0 then
		bad("precio")
	end
	if part.Charge ~= "Once" and part.Charge ~= "Each" then
		bad("cobro")
	end
	if not SOURCES[part.Unlock.Source] then
		bad("desbloqueo")
	end
	if part.Unlock.Source == "Level" and type(part.Unlock.Level) ~= "number" then
		bad("nivel")
	end
	if part.Unlock.Source == "Pass" and (part.Price ~= 0 or type(part.Unlock.Reward) ~= "string") then
		bad("pase con precio o sin recompensa")
	end
	if part.Requires and not VehicleParts.Parts[part.Requires] then
		bad("kit desconocido")
	end
	if part.Default and part.Price ~= 0 then
		bad("de serie con precio")
	end
end
check(#problems == 0, "cada pieza: id, nombre, hueco, anclaje, tipos, precio, cobro y desbloqueo válidos" .. (if #problems > 0 then " → " .. table.concat(problems, "; ") else ""))

local function countWhere(fn): number
	local n = 0
	for _, part in VehicleParts.List do
		if fn(part) then
			n += 1
		end
	end
	return n
end
check(countWhere(function(p) return p.Slot == "Paint" and p.Unlock.Source ~= "Pass" end) == 20, "20 pinturas en la paleta")
check(countWhere(function(p) return p.Slot == "Finish" end) == 4, "4 acabados (brillante, mate, metalizado, perlado)")
check(countWhere(function(p) return p.Slot == "Rims" end) == 12, "12 diseños de llanta")
check(countWhere(function(p) return p.Slot == "Rims" and table.find(p.Kinds, "Moto") and p.Design ~= nil end) == 3, "moto: 4 llantas (serie + 3)")
check(countWhere(function(p) return p.Slot == "RimColor" end) == 6, "6 colores de llanta")
check(countWhere(function(p) return p.Slot == "Tires" end) == 3, "3 neumáticos")
check(countWhere(function(p) return p.Slot == "Spoiler" end) == 3, "3 alerones")
check(countWhere(function(p) return p.Slot == "Neon" end) == 8, "8 colores de neón")
check(VehicleParts.Tints[0] and VehicleParts.Tints[3] and #VehicleParts.Tints == 3, "4 niveles de lunas (0..3)")
for _, body in VehicleParts.Bodies do
	local f = countWhere(function(p) return p.Slot == "BumperF" and VehicleParts.fits(p, "Coche", body) end)
	local r = countWhere(function(p) return p.Slot == "BumperR" and VehicleParts.fits(p, "Coche", body) end)
	check(f == 2 and r == 2, body .. ": 2 parachoques delante y 2 detrás")
end
check(not VehicleParts.fits(VehicleParts.Parts.Sp_GT, "Coche", "Compacto") and VehicleParts.fits(VehicleParts.Parts.Sp_Labio, "Coche", "Compacto"), "compacto: solo el alerón labio")
check(countWhere(function(p) return p.Slot == "Spoiler" and VehicleParts.fits(p, "Coche", "Todoterreno") end) == 0, "todoterreno: sin alerón")
for _, row in { { "P_RojoValmar", "Rojo Valmar" }, { "P_ArenaPlayaDorada", "Arena de Playa Dorada" }, { "F_Perlado", "Perlado" }, { "Rims_Helice", "Hélice" } } do
	check(VehicleParts.Parts[row[1]] and VehicleParts.Parts[row[1]].Name == row[2], "nombre en español: " .. row[2])
end

-- Nada de rendimiento ni de Robux en ninguna pieza (ni en tablas dentro)
local STAT = { "speed", "accel", "brak", "turn", "steer", "handling", "grip", "mass", "weight", "power", "torque", "boost", "fuel", "durab", "armor", "armour", "health", "damage", "tuning", "stat", "velocity", "drift", "traction" }
local MONEY = { "robux", "product", "gamepass", "marketplace", "devproduct" }
local statHits = {}
local function scan(t, path: string, depth: number)
	if depth > 6 then
		return
	end
	for key, value in t do
		local k = string.lower(tostring(key))
		for _, word in STAT do
			if string.find(k, word, 1, true) then
				table.insert(statHits, path .. "." .. tostring(key))
			end
		end
		for _, word in MONEY do
			if string.find(k, word, 1, true) then
				table.insert(statHits, path .. "." .. tostring(key))
			end
		end
		if type(value) == "table" then
			scan(value, path .. "." .. tostring(key), depth + 1)
		end
	end
end
for _, part in VehicleParts.List do
	scan(part, part.Id, 0)
end
check(#statHits == 0, "ninguna pieza lleva campos de rendimiento ni de Robux" .. (if #statHits > 0 then " → " .. table.concat(statHits, ", ") else ""))
for _, path in { "src/shared/VehicleParts.luau", "src/shared/VehicleBuild.luau" } do
	local src = fs.readFile(path)
	check(not string.find(src, "MarketplaceService", 1, true) and not string.find(src, "require(script.Parent.Gameplay", 1, true) and not string.find(src, "math.random", 1, true),
		path .. ": sin MarketplaceService, sin Gameplay y sin azar")
end
check(VehicleParts.Enabled == false, "el taller empieza apagado (Enabled = false)")

-- Anclas = modelo construido
local function localPos(part, cf)
	return cf:PointToObjectSpace(part.CFrame.Position)
end
local function near(a, b, tol: number?): boolean
	return (a - b).Magnitude < (tol or 0.1)
end
local function vecOf(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function anchorsMatch(kind: string, body: string?)
	local model = makeModel(kind, body)
	local anchors = VehicleParts.anchorsFor(kind, body)
	local label = kind .. (if body then " " .. body else "")
	-- ruedas
	local wheels = {}
	for _, child in model:GetChildren() do
		if child.Name == "Wheel" then
			table.insert(wheels, localPos(child, CF))
		end
	end
	local anchorWheels = {}
	for key, value in anchors do
		if string.sub(key, 1, 5) == "Wheel" then
			table.insert(anchorWheels, vecOf(value))
		end
	end
	local matched = #wheels == #anchorWheels
	for _, a in anchorWheels do
		local found = false
		for _, w in wheels do
			if near(a, w) then
				found = true
			end
		end
		matched = matched and found
	end
	check(matched, label .. ": las anclas de las ruedas coinciden con el modelo (" .. #wheels .. " ruedas)")
	local info = VehicleParts.Wheels[kind]
	local wheel = model:FindFirstChild("Wheel")
	check(wheel and math.abs(wheel.Size.Y - info.Radius * 2) < 0.02 and math.abs(wheel.Size.X - info.Width) < 0.02, label .. ": radio y ancho de rueda")
	local rim = model:FindFirstChild("Rim")
	if rim then
		check(math.abs(rim.Size.Y - info.RimDiameter) < 0.02, label .. ": diámetro de la llanta de serie")
	end
	for anchorName, partName in { BumperF = "BumperFront", BumperR = "BumperRear", PlateRear = if kind == "Coche" then "PlateRear" else "Plate", PlateFront = "PlateFront" } do
		if anchors[anchorName] then
			local part = model:FindFirstChild(partName)
			check(part and near(localPos(part, CF), vecOf(anchors[anchorName])), label .. ": ancla " .. anchorName .. " = " .. partName)
		end
	end
	if anchors.Trunk then
		local bodyPart = model:FindFirstChild("Body")
		local top = localPos(bodyPart, CF).Y + bodyPart.Size.Y / 2
		check(math.abs(top - anchors.Trunk[2]) < 0.05, label .. ": el maletero está a la altura de la carrocería")
	end
	-- pieza de referencia (para saber dónde está el vehículo antes de Rides.prepare)
	local ref = VehicleParts.Reference[kind]
	local refPart = model:FindFirstChild(ref.Name)
	local origin = refPart and refPart.CFrame * CFrame.new(-ref.Offset[1], -ref.Offset[2], -ref.Offset[3])
	check(origin and near(origin.Position, CF.Position, 0.01) and near(origin.LookVector, CF.LookVector, 0.001), label .. ": la pieza de referencia (" .. ref.Name .. ") da el sitio de construcción")
	model:Destroy()
end
for _, body in VehicleParts.Bodies do
	anchorsMatch("Coche", body)
end
for _, kind in { "Moto", "Bici", "Patinete", "Monopatin" } do
	anchorsMatch(kind, nil)
end

---------------------------------------------------------------------
print("Validación")
---------------------------------------------------------------------
local ALL_OWNED = {}
for _, part in VehicleParts.List do
	for _, kind in part.Kinds do
		ALL_OWNED[VehicleParts.ownKey(kind, part.Id)] = true
	end
	if part.Unlock.Reward then
		ALL_OWNED[part.Unlock.Reward] = true
	end
end
local validate = VehicleBuild.validate

local b, w = validate({ V = 1, Paint = "P_RojoValmar", Finish = "F_Metalizado" }, {}, "Coche")
check(b.Paint == "P_RojoValmar" and b.Finish == "F_Metalizado" and #w == 0, "pintura y acabado de la tienda: valen sin «tenerlos» (se pagan al pintar)")
b, w = validate({ V = 1, Paint = "P_Inventada", Rims = "Rims_NoExiste" }, ALL_OWNED, "Coche")
check(b.Paint == "" and b.Rims == "" and #w == 2, "ids desconocidos -> de serie, con aviso")
b = validate({ V = 1, Rims = "Rims_Estrella6" }, {}, "Coche")
check(b.Rims == "", "llanta sin comprar -> fuera")
b = validate({ V = 1, Rims = "Rims_Estrella6" }, { ["Coche:Rims_Estrella6"] = true }, "Coche")
check(b.Rims == "Rims_Estrella6", "llanta comprada -> se queda")
b = validate({ V = 1, Rims = "Rims_Estrella6" }, { ["Moto:Rims_Estrella6"] = true }, "Coche")
check(b.Rims == "", "comprada para la moto no vale en el coche")
b = validate({ V = 1, Rims = "Rims_Turbina" }, ALL_OWNED, "Moto")
check(b.Rims == "", "llanta de coche en la moto -> fuera")
b = validate({ V = 1, Rims = "P_RojoValmar" }, ALL_OWNED, "Coche")
check(b.Rims == "", "pieza de otro hueco -> fuera")
b = validate({ V = 1, Body = "Compacto", Spoiler = "Sp_GT" }, ALL_OWNED, "Coche")
check(b.Body == "Compacto" and b.Spoiler == "", "alerón GT en el compacto -> fuera")
b = validate({ V = 1, Body = "Compacto", Spoiler = "Sp_Labio" }, ALL_OWNED, "Coche")
check(b.Spoiler == "Sp_Labio", "alerón labio en el compacto -> vale")
b = validate({ V = 1, Body = "Todoterreno", BumperF = "BF_Deportivo", BumperR = "BR_Defensa" }, ALL_OWNED, "Coche")
check(b.BumperF == "" and b.BumperR == "BR_Defensa", "parachoques según la carrocería")
b = validate({ V = 1, Body = "Compacto" }, {}, "Coche")
check(b.Body == "", "carrocería sin comprar -> berlina")
b = validate({ V = 1, Body = "Descapotable" }, ALL_OWNED, "Coche")
check(b.Body == "", "carrocería desconocida -> berlina")
b = validate({ V = 1, Neon = "N_Cian" }, {}, "Coche")
check(b.Neon == "", "neón sin el kit -> fuera")
b = validate({ V = 1, Neon = "N_Cian" }, { ["Coche:Kit_Neon"] = true }, "Coche")
check(b.Neon == "N_Cian", "neón con el kit -> vale (el color se paga cada vez)")
b = validate({ V = 1, Neon = "N_Cian" }, ALL_OWNED, "Bici")
check(b.Neon == "", "la bici no lleva neón")
b = validate({ V = 1, Tint = 99 }, { ["Coche:Kit_Tint"] = true }, "Coche")
check(b.Tint == 3, "Tint = 99 -> 3")
b = validate({ V = 1, Tint = -4 }, { ["Coche:Kit_Tint"] = true }, "Coche")
check(b.Tint == 0, "Tint = -4 -> 0")
b = validate({ V = 1, Tint = 2 }, {}, "Coche")
check(b.Tint == 0, "lunas sin el kit -> sin tintar")
b = validate({ V = 1, Tint = "2", Paint = 5, Rims = { "x" }, Spoiler = true }, ALL_OWNED, "Coche")
check(b.Tint == 0 and b.Paint == "" and b.Rims == "" and b.Spoiler == "", "tipos equivocados (texto, número, tabla, sí/no) se descartan")
b = validate({ V = 1, Tint = 0 / 0 }, ALL_OWNED, "Coche")
check(b.Tint == 0, "Tint = NaN -> 0")
b = validate({ V = 1, Paint = "P_PerlaFaro", Rims = "Rims_Faro" }, {}, "Coche")
check(b.Paint == "" and b.Rims == "", "piezas del pase sin la recompensa -> fuera")
b = validate({ V = 1, Paint = "P_PerlaFaro", Rims = "Rims_Faro" }, { S1_P50_Car = true }, "Coche")
check(b.Paint == "P_PerlaFaro" and b.Rims == "Rims_Faro", "piezas del pase con la recompensa (Cosmetics.Owned) -> valen")
b = validate({ V = 1, Paint = "P_PerlaFaro" }, { S1_P50_Car = true }, "Moto")
check(b.Paint == "", "pintura del pase de coche no vale en la moto")
b = validate({ V = 1, Paint2 = "P_Negro" }, ALL_OWNED, "Coche")
check(b.Paint2 == "", "Paint2 desconocida -> fuera")
b = validate({ V = 1, Paint2 = "P_NegroNoche" }, {}, "Coche")
check(b.Paint2 == "P_NegroNoche", "Paint2 de la paleta -> vale")
b = validate({ V = 1, Paint2 = "P_NegroNoche" }, {}, "Patinete")
check(b.Paint2 == "", "el patinete no tiene pintura secundaria")
b, w = validate({ V = 1, Paint = "P_Cafe" }, ALL_OWNED, "Autobus")
check(b.Paint == "" and #w == 1, "autobús (trabajo) -> no se personaliza")
b = validate({ V = 1, Paint = "P_Cafe" }, ALL_OWNED, nil)
check(b.Paint == "", "sin tipo -> no se personaliza")
for _, junk in { "hola", 42, true, nil :: any } do
	local ok, clean = pcall(validate, junk, ALL_OWNED, "Coche")
	check(ok and clean.V == 1 and clean.Paint == "", "build basura (" .. type(junk) .. ") -> de serie sin error")
end
local okOwned, cleanOwned = pcall(validate, { V = 1, Rims = "Rims_Clasica5" }, "no soy una tabla", "Coche")
check(okOwned and cleanOwned.Rims == "", "ownedParts basura -> nada desbloqueado, sin error")
local huge = { V = 1, Paint = "P_Celeste" }
for i = 1, 10000 do
	huge["Campo" .. i] = { i, { deep = { i } } }
end
local okHuge, cleanHuge, warnHuge = pcall(validate, huge, ALL_OWNED, "Coche")
local extraKeys = 0
if okHuge then
	for key in cleanHuge do
		if not table.find(VehicleBuild.Fields, key) and key ~= "V" then
			extraKeys += 1
		end
	end
end
check(okHuge and cleanHuge.Paint == "P_Celeste" and extraKeys == 0 and #warnHuge <= 40, "10.000 campos anidados: se borran y no rompe")
b = validate({ Color = "P_Granate", Wheels = "Rims_Clasica5" }, ALL_OWNED, "Coche")
check(b.V == 1 and b.Paint == "P_Granate" and b.Rims == "Rims_Clasica5" and b.Color == nil, "migración V0 -> V1 (Color -> Paint, Wheels -> Rims)")
b = validate({ V = 7, Paint = "P_Granate", Horn = "H_Barco", Vinyl = "V_Llamas", Raro = { 1 } }, ALL_OWNED, "Coche")
check(b.V == 7 and b.Paint == "P_Granate" and b.Horn == "H_Barco" and b.Vinyl == "V_Llamas" and b.Raro == nil, "V del futuro: se conserva lo que no se entiende (sencillo), lo raro no")
b = validate({ V = 1, Horn = "H_Barco" }, ALL_OWNED, "Coche")
check(b.Horn == nil, "V actual: campos desconocidos se borran")
-- Matrícula
check(VehicleParts.plateText("  valmar  1 ") == "VALMAR 1", "matrícula: mayúsculas, sin espacios de sobra")
check(VehicleParts.plateText("ABC$%") == nil, "matrícula con símbolos -> rechazada")
check(VehicleParts.plateText("ÑANDÚ") == nil, "matrícula con ñ o tildes -> rechazada")
check(VehicleParts.plateText("123456789") == nil, "matrícula de 9 -> rechazada")
check(VehicleParts.plateText("   ") == nil and VehicleParts.plateText(12) == nil, "matrícula vacía o no texto -> rechazada")
b = validate({ V = 1, Plate = "lola 7" }, {}, "Moto")
check(b.Plate == "LOLA 7", "matrícula en la moto")
b = validate({ V = 1, Plate = "LOLA" }, {}, "Bici")
check(b.Plate == "", "la bici no lleva matrícula")

---------------------------------------------------------------------
print("Guardar y cargar (JSON, como el DataStore) y precios")
---------------------------------------------------------------------
local FULL = {
	V = 1,
	Body = "",
	Paint = "P_AzulPuerto",
	Finish = "F_Perlado",
	Paint2 = "P_NegroNoche",
	Rims = "Rims_Turbina",
	RimColor = "RC_Bronce",
	Tires = "T_LetrasBlancas",
	Tint = 2,
	Spoiler = "Sp_GT",
	BumperF = "BF_Deportivo",
	BumperR = "BR_Deportivo",
	Neon = "N_Cian",
	Plate = "VALMAR 1",
}
local fullClean = validate(FULL, ALL_OWNED, "Coche")
local json = serde.encode("json", fullClean)
local back = validate(serde.decode("json", json), ALL_OWNED, "Coche")
local equal = true
for _, field in VehicleBuild.Fields do
	equal = equal and back[field] == FULL[field]
end
check(equal, "build completa -> JSON -> validate = la misma")
check(#json < 400, ("tamaño guardado %d bytes (< 400)"):format(#json))
local total = VehicleParts.price("Coche", VehicleBuild.default(), fullClean, {})
check(total >= 7500 and total <= 10500, ("coche «de ensueño» desde cero: %d € (≈ 8.000–10.000)"):format(total))
local again = VehicleParts.price("Coche", VehicleBuild.default(), fullClean, ALL_OWNED)
check(again < total and again > 0, ("con las piezas ya compradas solo se paga la mano de obra: %d €"):format(again))
check(VehicleParts.price("Coche", fullClean, fullClean, {}) == 0, "sin cambios, 0 €")
local motoFrom, motoTo = VehicleBuild.default(), validate({ V = 1, Rims = "Rims_Clasica5" }, ALL_OWNED, "Moto")
check(VehicleParts.price("Moto", motoFrom, motoTo, {}) == 240, "moto ×0,6 (llanta de 400 € -> 240 €)")
local ok15 = VehicleParts.canBuy(VehicleParts.Parts.Sp_GT, "Coche", 14)
local ok16 = VehicleParts.canBuy(VehicleParts.Parts.Sp_GT, "Coche", 15)
check(not ok15 and ok16, "el alerón GT pide nivel 15")
check(not VehicleParts.canBuy(VehicleParts.Parts.Rims_Faro, "Coche", 99), "las piezas del pase no se compran")

---------------------------------------------------------------------
print("Aplicar y quitar")
---------------------------------------------------------------------
-- Una build por cada pieza que vale para ese tipo/carrocería, y la build «completa»
local function buildsFor(kind: string, body: string?): { { [string]: any } }
	local list = {}
	for _, part in VehicleParts.List do
		if not VehicleParts.fits(part, kind, body) then
			continue
		end
		local b1 = VehicleBuild.default()
		if part.Slot == "Kit" then
			if part.Id == "Kit_Tint" then
				b1.Tint = 3
			else
				continue
			end
		elseif part.Slot == "Body" then
			continue
		else
			local field = part.Slot
			b1[field] = part.Id
			if part.Slot == "Paint" and VehicleParts.Paint2Kinds[kind] then
				b1.Paint2 = part.Id
			end
			if part.Slot == "RimColor" then
				b1.Rims = if kind == "Coche" then "Rims_Turbina" elseif kind == "Moto" then "Rims_Deportiva10" else ""
			end
		end
		table.insert(list, { Label = part.Id, Build = b1 })
	end
	local all = VehicleBuild.default()
	all.Paint, all.Finish = "P_Cobre", "F_Perlado"
	if VehicleParts.Paint2Kinds[kind] then
		all.Paint2 = "P_BlancoGlaciar"
	end
	all.RimColor = "RC_Carroceria"
	if kind == "Coche" then
		all.Body = body or ""
		all.Rims, all.Tires, all.Tint = "Rims_Turbina", "T_LetrasBlancas", 3
		all.Spoiler = if body == "Todoterreno" then "" elseif body == "Compacto" then "Sp_Labio" else "Sp_GT"
		all.BumperF = if body == "Todoterreno" then "BF_Defensa" else "BF_Deportivo"
		all.BumperR = if body == "Todoterreno" then "BR_Defensa" else "BR_Deportivo"
		all.Neon, all.Plate = "N_Rosa", "VALMAR 1"
	elseif kind == "Moto" then
		all.Rims, all.Neon, all.Plate = "Rims_Deportiva10", "N_Verde", "MOTO 5"
	elseif kind == "Patinete" then
		all.Neon = "N_Ambar"
	end
	table.insert(list, { Label = "completa", Build = all, Full = true })
	return list
end

local function runKind(kind: string, body: string?)
	local label = kind .. (if body then " " .. body else "")
	local stock = makeModel(kind, body)
	local stockSnap = snapshot(stock)
	local stockTop = heightOf(stock, CF)
	local stockReserved = reservedSnapshot(stock)
	local stockCollide = collideSnapshot(stock)
	-- asientos y chasis de serie (tras Rides.prepare)
	local stockPrepared = makeModel(kind, body)
	Rides.prepare(stockPrepared, kind, CF)
	local seatsStock = {}
	for _, d in stockPrepared:GetChildren() do
		if d.Name == "DriverSeat" or d.Name == "RideSeat" or d.Name == "Chassis" then
			table.insert(seatsStock, partString(d, false))
		end
	end
	local preparedCollide = collideSnapshot(stockPrepared)
	stockPrepared:Destroy()

	local errors, outside, collide, reservedTouched, clearFailed, notDeterministic, overBudget, seatsChanged = {}, {}, {}, {}, {}, {}, {}, {}
	local maxParts, fullCount = 0, 0
	local cases = buildsFor(kind, body)
	for _, case in cases do
		local model = makeModel(kind, body)
		local ok, n, warns = pcall(VehicleBuild.apply, model, case.Build)
		if not ok then
			table.insert(errors, case.Label .. ": " .. tostring(n))
			continue
		end
		if #warns > 0 then
			table.insert(errors, case.Label .. ": " .. table.concat(warns, " / "))
		end
		maxParts = math.max(maxParts, n)
		if case.Full then
			fullCount = n
		end
		local list = mods_(model)
		if #list ~= n or n > VehicleParts.Budget[kind] then
			table.insert(overBudget, case.Label)
		end
		for _, p in list do
			local inside, why = insideBox(p, CF, kind, stockTop)
			if not inside then
				table.insert(outside, case.Label .. ": " .. why)
			end
			if p.CanCollide or p.CanQuery or p.CanTouch or not p.Massless or p:GetAttribute("Mod") ~= true or type(p:GetAttribute("Slot")) ~= "string" or isReservedName(string.sub(p.Name, 5)) then
				table.insert(collide, case.Label .. ": " .. p.Name)
			end
		end
		if not same(reservedSnapshot(model), stockReserved) then
			table.insert(reservedTouched, case.Label)
		end
		if not same(collideSnapshot(model), stockCollide) then
			table.insert(collide, case.Label .. ": cambió la colisión")
		end
		-- determinista e idempotente: otro modelo igual da las mismas piezas; aplicar dos veces, igual
		local twin = makeModel(kind, body)
		VehicleBuild.apply(twin, case.Build)
		local a, bb = {}, {}
		for _, p in list do
			table.insert(a, partString(p, true))
		end
		for _, p in mods_(twin) do
			table.insert(bb, partString(p, true))
		end
		local n2 = VehicleBuild.apply(model, case.Build)
		if not same(a, bb) or n2 ~= n then
			table.insert(notDeterministic, case.Label)
		end
		twin:Destroy()
		-- tras Rides.prepare: soldadas, sin masa, sin colisión; chasis y asientos iguales
		Rides.prepare(model, kind, CF)
		local seats = {}
		for _, d in model:GetChildren() do
			if d.Name == "DriverSeat" or d.Name == "RideSeat" or d.Name == "Chassis" then
				table.insert(seats, partString(d, false))
			end
		end
		if not same(seats, seatsStock) or not same(collideSnapshot(model), preparedCollide) then
			table.insert(seatsChanged, case.Label)
		end
		for _, p in mods_(model) do
			if p.Anchored or not p.Massless or p:GetAttribute("Collide") ~= false or not p:FindFirstChildWhichIsA("WeldConstraint") then
				table.insert(collide, case.Label .. ": tras prepare " .. p.Name)
			end
		end
		model:Destroy()
		-- clear: todo como estaba
		local again2 = makeModel(kind, body)
		VehicleBuild.apply(again2, case.Build)
		VehicleBuild.clear(again2)
		if not same(snapshot(again2), stockSnap) then
			table.insert(clearFailed, case.Label)
		end
		again2:Destroy()
	end
	check(#errors == 0, ("%s: %d builds se aplican sin errores ni avisos"):format(label, #cases) .. (if #errors > 0 then " → " .. table.concat(errors, "; ") else ""))
	check(#overBudget == 0, ("%s: dentro del presupuesto (máx. %d de %d; completa %d)"):format(label, maxParts, VehicleParts.Budget[kind], fullCount) .. (if #overBudget > 0 then " → " .. table.concat(overBudget, ", ") else ""))
	check(#outside == 0, label .. ": todas las piezas Mod_ dentro de la caja del chasis + 0,3" .. (if #outside > 0 then " → " .. table.concat(outside, "; ", 1, math.min(#outside, 6)) else ""))
	check(#collide == 0, label .. ": piezas Mod_ sin colisión (CanCollide/CanQuery/CanTouch), sin masa, marcadas y soldadas; misma colisión que de serie" .. (if #collide > 0 then " → " .. table.concat(collide, "; ", 1, math.min(#collide, 6)) else ""))
	check(#reservedTouched == 0, label .. ": faros, pilotos, intermitentes, pata, Body… intactos (Body solo pintado)" .. (if #reservedTouched > 0 then " → " .. table.concat(reservedTouched, ", ") else ""))
	check(#seatsChanged == 0, label .. ": Chassis, DriverSeat y RideSeat iguales que de serie tras Rides.prepare" .. (if #seatsChanged > 0 then " → " .. table.concat(seatsChanged, ", ") else ""))
	check(#notDeterministic == 0, label .. ": determinista (mismo resultado en otro modelo y al aplicar dos veces)" .. (if #notDeterministic > 0 then " → " .. table.concat(notDeterministic, ", ") else ""))
	check(#clearFailed == 0, label .. ": clear() lo deja exactamente como de serie" .. (if #clearFailed > 0 then " → " .. table.concat(clearFailed, ", ") else ""))
	-- build vacía = modelo de serie
	local empty = makeModel(kind, body)
	local emptyN = VehicleBuild.apply(empty, VehicleBuild.default())
	check(emptyN == 0 and same(snapshot(empty), stockSnap), label .. ": build vacía = el mismo modelo que sin taller")
	empty:Destroy()
	stock:Destroy()
end
for _, body in VehicleParts.Bodies do
	runKind("Coche", body)
end
for _, kind in { "Moto", "Bici", "Patinete", "Monopatin" } do
	runKind(kind, nil)
end

-- Lo que se ve de verdad en el coche completo
local car = makeModel("Coche", "Berlina")
local fullBuild = validate(FULL, ALL_OWNED, "Coche")
VehicleBuild.apply(car, fullBuild)
local body = car:FindFirstChild("Body")
local blue = Color3.fromRGB(30, 90, 170):Lerp(Color3.new(1, 1, 1), 0.08)
check(near(Vector3.new(body.Color.R, body.Color.G, body.Color.B), Vector3.new(blue.R, blue.G, blue.B), 0.01) and math.abs(body.Reflectance - 0.35) < 1e-3, "carrocería pintada (azul perlado)")
local plateLabel = car:FindFirstChild("PlateRear"):FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
check(plateLabel.Text == "VALMAR 1", "matrícula de detrás con el texto guardado")
check(car:FindFirstChild("PlateFront"):FindFirstChild("Mod_PlateGui") ~= nil, "matrícula de delante con el texto")
local windshield = car:FindFirstChild("Windshield")
local side = car:FindFirstChild("SideWindow")
check(math.abs(windshield.Transparency - 0.35) < 1e-3 and math.abs(side.Transparency - 0.15) < 1e-3, "lunas tintadas, el parabrisas no")
check(typeof(car:GetAttribute("NeonColor")) == "Color3" and car:FindFirstChild("Mod_Neon") ~= nil, "neón con NeonColor en el modelo (para el cliente)")
local hiddenRims = 0
for _, d in car:GetChildren() do
	if d.Name == "Rim" and d.Transparency == 1 then
		hiddenRims += 1
	end
end
check(hiddenRims == 4 and car:FindFirstChild("BumperFront") and car:FindFirstChild("BumperFront").Transparency == 1, "llantas y parachoques de serie escondidos (siguen ahí)")
VehicleBuild.clear(car)
check(plateLabel.Text ~= "VALMAR 1" and car:FindFirstChild("Mod_Neon") == nil and car:GetAttribute("NeonColor") == nil, "clear quita el texto, el neón y el atributo")
car:Destroy()

-- Aplicar sobre un vehículo YA preparado (vista previa / sustituir en el taller): se suelda
local prepared = makeModel("Moto", nil)
Rides.prepare(prepared, "Moto", CF)
local nPrepared = VehicleBuild.apply(prepared, validate({ V = 1, Rims = "Rims_Estrella6", Neon = "N_Rojo", Plate = "ABC 123" }, ALL_OWNED, "Moto"))
local welded, insideAll = true, true
for _, p in mods_(prepared) do
	welded = welded and not p.Anchored and p:FindFirstChildWhichIsA("WeldConstraint") ~= nil
	insideAll = insideAll and insideBox(p, CF, "Moto", 6)
end
check(nPrepared > 0 and welded and insideAll, ("moto ya preparada: %d piezas soldadas al chasis y en su sitio"):format(nPrepared))
check(prepared:FindFirstChild("Plate"):FindFirstChild("Mod_PlateGui") ~= nil, "moto: matrícula con texto")
prepared:Destroy()

-- Presupuesto: si no cabe, se para (sin error) y avisa
local savedBudget = VehicleParts.Budget.Coche
VehicleParts.Budget.Coche = 5
local tight = makeModel("Coche", "Berlina")
local nTight, warnTight = VehicleBuild.apply(tight, fullBuild)
check(nTight == 5 and #mods_(tight) == 5 and #warnTight > 0, "con presupuesto de 5 piezas, pone 5 y avisa")
VehicleParts.Budget.Coche = savedBudget
tight:Destroy()

-- Un modelo que no se personaliza (autobús) no cambia
local bus = Rides.build("Autobus", nil, CF, PAINT)
local busSnap = snapshot(bus)
local nBus = VehicleBuild.apply(bus, fullBuild)
check(nBus == 0 and same(snapshot(bus), busSnap), "autobús: apply no hace nada")
bus:Destroy()

-- La build pide una carrocería que el modelo no tiene: se miran las piezas contra el modelo
local compact = makeModel("Coche", "Compacto")
local nCompact, warnCompact = VehicleBuild.apply(compact, { V = 1, Spoiler = "Sp_GT" })
check(nCompact == 0 and #warnCompact == 1, "alerón GT sobre un compacto: no se pone (aviso)")
compact:Destroy()

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
