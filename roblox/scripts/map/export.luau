-- Exporta la ciudad YA CONSTRUIDA para dibujar el mapa grande visto desde arriba (scripts/map/render.py).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
--   lune run scripts/map/export.luau X.rbxl DIR
--
-- Escribe en DIR:
--   parts.tsv      una línea por pieza visible de workspace.Town (huella vista desde arriba, altura,
--                  color, material y forma). Sin las salas del cielo (interiores), ni lo que está bajo
--                  tierra (metro), ni las piezas solo de Studio (EditOnly: suelo y mar de piezas).
--   plan.json      el plano de la isla (shared/CityPlan: costa, islas, río, lagos, montañas, distritos)
--                  y el del aeropuerto (shared/Airport): el terreno lo pone TerrainBuilder al arrancar
--                  y no está en el archivo, así que el dibujo lo rehace con los mismos datos.
--   landmarks.json los lugares del mapa, buscados igual que WorldService.publishLandmarks (y las
--                  instituciones que InteriorService pone en edificios de la ciudad).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local placePath = process.args[1]
local outDir = process.args[2]
if not placePath or not outDir then
	print("Uso: lune run scripts/map/export.luau X.rbxl DIR")
	process.exit(1)
end
fs.writeDir(outDir)

-- Módulos compartidos (con script.Parent.X)
local cache: { [string]: any } = {}
local function load(name: string): any
	if cache[name] ~= nil then
		return cache[name]
	end
	local parent = setmetatable({}, {
		__index = function(_, key)
			return { __shared = key }
		end,
	})
	local env = setmetatable({
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		script = { Parent = parent },
		require = function(target: any)
			return load(target.__shared)
		end,
	}, { __index = _G })
	local value = luau.load(fs.readFile("src/shared/" .. name .. ".luau"), { debugName = name, environment = env })()
	cache[name] = value
	return value
end
local CityPlan = load("CityPlan")
local MapInfo = load("MapInfo")
local Airport = load("Airport")

print("▶ Leyendo " .. placePath)
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")
local town = workspace:FindFirstChild("Town")
if not town then
	print("❌ El archivo no tiene la ciudad (workspace.Town): ejecuta antes scripts/build-place.luau")
	process.exit(1)
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local SKY = 900 -- las salas de los interiores flotan muy por encima de la ciudad
local lines = {}
local skipped = { Sky = 0, Under = 0, Hidden = 0, Edit = 0 }
local function hasTag(inst: any, tag: string): boolean
	local ok, value = pcall(function()
		return inst:HasTag(tag)
	end)
	return ok and value == true
end
local function f(n: number): string
	return string.format("%.1f", n)
end
local count = 0
for _, part in town:GetDescendants() do
	if not part:IsA("BasePart") then
		continue
	end
	if hasTag(part, "EditOnly") then
		skipped.Edit += 1
		continue
	end
	if part.Transparency >= 0.9 then
		skipped.Hidden += 1
		continue
	end
	local cf, size = part.CFrame, part.Size
	local corners = {}
	local top, bottom = -math.huge, math.huge
	for _, sx in { -0.5, 0.5 } do
		for _, sy in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				local p = cf * roblox.Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
				top = math.max(top, p.Y)
				bottom = math.min(bottom, p.Y)
				table.insert(corners, f(p.X) .. "," .. f(p.Z))
			end
		end
	end
	if bottom > SKY then
		skipped.Sky += 1
		continue
	end
	if top < -6 then
		skipped.Under += 1
		continue
	end
	local shape = "Box"
	if part.ClassName == "Part" then
		local s = part.Shape.Name
		if s == "Ball" or s == "Cylinder" then
			shape = s
		end
	elseif part.ClassName == "WedgePart" or part.ClassName == "CornerWedgePart" then
		shape = "Wedge"
	elseif part.ClassName == "MeshPart" then
		shape = "Mesh"
	end
	-- (un cilindro de Roblox va a lo largo de X: si está de pie, desde arriba es un círculo)
	local upright = shape == "Cylinder" and math.abs(cf.RightVector.Y) > 0.9
	local c = part.Color
	local parentName = if part.Parent then part.Parent.Name else ""
	count += 1
	lines[count] = table.concat({
		if upright then "Disc" else shape,
		f(top),
		f(bottom),
		string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)),
		part.Material.Name,
		string.format("%.2f", part.Transparency),
		f(cf.Position.X) .. "," .. f(cf.Position.Z) .. "," .. f(math.max(size.X, size.Z) / 2) .. "," .. f(if upright then size.Y / 2 else math.min(size.Y, size.Z) / 2),
		table.concat(corners, ";"),
		(string.gsub(part.Name, "[\t\n]", " ")),
		(string.gsub(parentName, "[\t\n]", " ")),
	}, "\t")
end
fs.writeFile(outDir .. "/parts.tsv", table.concat(lines, "\n"))
print(("  %d piezas (fuera: %d en el cielo, %d bajo tierra, %d invisibles, %d solo de Studio)"):format(count, skipped.Sky, skipped.Under, skipped.Hidden, skipped.Edit))

---------------------------------------------------------------------
-- Plano
---------------------------------------------------------------------
local function rect(r: any): any
	local out = {}
	for k, v in r do
		if type(v) == "number" then
			out[k] = v
		end
	end
	return out
end
local districts = {}
for _, d in CityPlan.Districts do
	table.insert(districts, { Id = d.Id, Name = d.Name, Theme = d.Theme, Color = d.Color, Poly = d.Poly })
end
local plan = {
	Coast = CityPlan.Coast,
	Cliffs = CityPlan.Cliffs,
	Islands = CityPlan.Islands,
	River = CityPlan.River,
	Lakes = CityPlan.Lakes,
	Mountains = CityPlan.Mountains,
	Districts = districts,
	Bounds = CityPlan.Bounds,
	Places = CityPlan.Places,
	Airport = {
		Land = rect(Airport.Land),
		Runway = rect(Airport.Runway),
		Taxiway = rect(Airport.Taxiway),
		Apron = rect(Airport.Apron),
		Strip = rect(Airport.Strip),
		StripApron = rect(Airport.StripApron),
	},
}
fs.writeFile(outDir .. "/plan.json", serde.encode("json", plan, true))

---------------------------------------------------------------------
-- Lugares (como WorldService.publishLandmarks)
---------------------------------------------------------------------
-- Centro de la caja que envuelve las piezas de un modelo (Lune no trae GetBoundingBox)
local function boxCenter(model: any): (boolean, any)
	local lo, hi = nil, nil
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local at = p.CFrame.Position
			lo = if lo then lo:Min(at) else at
			hi = if hi then hi:Max(at) else at
		end
	end
	if not lo then
		return false, nil
	end
	return true, roblox.CFrame.new((lo + hi) / 2)
end
local found = {}
for _, model in town:GetDescendants() do
	local kind = model:IsA("Model") and MapInfo.KindByModel[model.Name]
	if kind then
		local ok, cf = boxCenter(model)
		if ok then
			local position = cf.Position
			local merged = false
			if kind.Merge then
				for _, other in found do
					if other.Kind == kind.Model and (other.Position - position).Magnitude < kind.Merge then
						other.Position = (other.Position * other.Count + position) / (other.Count + 1)
						other.Count += 1
						merged = true
						break
					end
				end
			end
			if not merged then
				table.insert(found, { Kind = kind.Model, Position = position, Count = 1, Host = false })
			end
		end
	end
end
-- Instituciones (InteriorService.hostInstitutions): los dos edificios «Edificio_N» más cerca del
-- centro y la nave más al este. (Aquí con el centro del modelo, no con su puerta: unos metros de error)
local center, naves = {}, {}
for _, model in town:GetDescendants() do
	local isCenter = string.match(model.Name, "^Edificio_%d+$") ~= nil
	if model:IsA("Model") and (isCenter or model.Name == "Nave") then
		local ok, cf = boxCenter(model)
		if ok then
			table.insert(if isCenter then center else naves, cf.Position)
		end
	end
end
table.sort(center, function(a, b)
	return a.Magnitude < b.Magnitude
end)
table.sort(naves, function(a, b)
	return a.X > b.X
end)
for _, host in { { center[1], "PalacioJusticia" }, { center[2], "AgenciaTributaria" }, { naves[1], "CuartelEjercito" } } do
	if host[1] then
		table.insert(found, { Kind = host[2], Position = host[1], Count = 1, Host = true })
	end
end
local out = {}
for _, place in found do
	local kind = MapInfo.KindByModel[place.Kind]
	local district = MapInfo.districtAt(place.Position.X, place.Position.Z)
	table.insert(out, {
		Kind = place.Kind,
		Name = kind.Name,
		Icon = kind.Icon,
		Important = kind.Important == true,
		X = math.floor(place.Position.X + 0.5),
		Z = math.floor(place.Position.Z + 0.5),
		District = if district then district.Name else "",
		Host = place.Host,
	})
end
table.sort(out, function(a, b)
	return a.Name < b.Name
end)
fs.writeFile(outDir .. "/landmarks.json", serde.encode("json", out, true))
print(("  %d lugares"):format(#out))
print("✅ " .. outDir)
