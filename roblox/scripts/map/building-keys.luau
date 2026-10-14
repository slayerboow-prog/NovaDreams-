-- Exporta la clave de cada edificio visitable de un mapa construido, igual que la calcula
-- InteriorService (Entrances.classify + centro de la caja del modelo: "<Tipo>_<X>_<Z>"). Las partidas
-- guardadas usan esas claves (viviendas compradas o alquiladas, negocios, residencias…).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/building-keys.luau X.rbxl SALIDA.json
--
-- SALIDA.json: { Buildings = lista de { Key, Kind, Title, Upper, Floors, X, Z, W, D, Model, District },
--                Premises = lista de { Key, Kind, X, Z, District } } (los negocios de BusinessService:
--                locales "L:<clave del edificio>", hoteles "H:x_z" y gasolineras "G:x_z")

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local Entrances = L.load("src/server/World/Entrances")
local CityPlan = L.load("src/shared/CityPlan")

local placePath, outPath = process.args[1], process.args[2]
if not placePath or not outPath then
	print("Uso: lune run scripts/map/building-keys.luau X.rbxl SALIDA.json")
	process.exit(1)
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")

-- Model:GetBoundingBox() de Roblox (Lune no lo trae): caja orientada como el pivote del modelo (la
-- pieza principal, o WorldPivot; en los modelos hechos por código, sin girar)
local function boundingBox(model: any): (any?, any?)
	local okPivot, pivot = pcall(function()
		return if model.PrimaryPart then model.PrimaryPart.CFrame else model.WorldPivot
	end)
	if not okPivot or not pivot then
		pivot = roblox.CFrame.new()
	end
	pivot = pivot - pivot.Position
	local lo, hi
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size
			for _, sx in { -0.5, 0.5 } do
				for _, sy in { -0.5, 0.5 } do
					for _, sz in { -0.5, 0.5 } do
						local w = cf * roblox.Vector3.new(s.X * sx, s.Y * sy, s.Z * sz)
						local l = pivot:PointToObjectSpace(w)
						lo = if lo then lo:Min(l) else l
						hi = if hi then hi:Max(l) else l
					end
				end
			end
		end
	end
	if not lo then
		return nil, nil
	end
	return pivot * roblox.CFrame.new((lo + hi) / 2), hi - lo
end

local out = {}
for _, model in town:GetDescendants() do
	if model:IsA("Model") then
		local kind, title, upper = Entrances.classify(model)
		if kind then
			local cf, size = boundingBox(model)
			if cf and size and size.Y > 6 then
				local x, z = math.floor(cf.Position.X + 0.5), math.floor(cf.Position.Z + 0.5)
				local d = CityPlan.districtAt(cf.Position.X, cf.Position.Z)
				table.insert(out, {
					Key = ("%s_%d_%d"):format(kind, x, z),
					Kind = kind,
					Title = title,
					Upper = upper,
					Floors = math.clamp(math.floor((size.Y - 2) / 12), 1, 40),
					X = x,
					Z = z,
					W = math.floor(size.X + 0.5),
					D = math.floor(size.Z + 0.5),
					Model = model.Name,
					District = if d then d.Id else "",
				})
			end
		end
	end
end
table.sort(out, function(a, b)
	return a.Key < b.Key
end)

-- Negocios (BusinessService.findPremises): locales, hoteles y gasolineras
local premises = {}
local function round(v: any): string
	return ("%d_%d"):format(math.floor(v.X + 0.5), math.floor(v.Z + 0.5))
end
local function district(x: number, z: number): string
	local d = CityPlan.districtAt(x, z)
	return if d then d.Id else ""
end
for _, b in out do
	if b.Kind == "Local" then
		table.insert(premises, { Key = "L:" .. b.Key, Kind = "Local", X = b.X, Z = b.Z, District = b.District })
	end
end
for _, d in town:GetDescendants() do
	if d:IsA("Model") and d:HasTag("HotelLobby") then
		local staff = d:GetAttribute("Staff")
		if typeof(staff) == "Vector3" then
			table.insert(premises, { Key = "H:" .. round(staff), Kind = "Hotel", X = math.floor(staff.X + 0.5), Z = math.floor(staff.Z + 0.5), District = district(staff.X, staff.Z) })
		end
	elseif d:IsA("Model") and d.Name == "Gasolinera" then
		local pylon = d:FindFirstChild("Pylon")
		if pylon and pylon:IsA("BasePart") then
			local p = pylon.CFrame.Position
			table.insert(premises, { Key = "G:" .. round(p), Kind = "Gas", X = math.floor(p.X + 0.5), Z = math.floor(p.Z + 0.5), District = district(p.X, p.Z) })
		end
	end
end
table.sort(premises, function(a, b)
	return a.Key < b.Key
end)
fs.writeFile(outPath, serde.encode("json", { Buildings = out, Premises = premises }, true))
print(("✅ %d edificios y %d negocios → %s"):format(#out, #premises, outPath))
