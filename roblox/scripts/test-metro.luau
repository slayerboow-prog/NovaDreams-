-- Prueba del metro en el mapa construido (World/Kit/MetroKit + MetroDetails), con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-metro.luau RealLifeSimulator.rbxl
--
-- Comprueba que:
--   * cada andén está girado como su línea (la vía del mapa coincide con el recorrido de los trenes)
--   * hay aseos, guardias, ratas, taquillas, puestos… repartidos por las estaciones y la galería
--   * nada sólido tapa los sitios por donde se pasa (tornos, escaleras, subir al tren, transbordos)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3

local path = process.args[1] or "RealLifeSimulator.rbxl"
local env = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = Color3 }, { __index = getfenv(1) })
local Metro = luau.load(fs.readFile("src/shared/Metro.luau"), { debugName = "Metro", environment = env })()
local game = roblox.deserializePlace(fs.readFile(path))
local under = game:GetService("Workspace"):FindFirstChild("MetroSubterraneo", true)

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("Andenes alineados con las vías")
for _, line in Metro.Lines do
	for i, id in line.Stations do
		local st = under and under:FindFirstChild("Estacion_" .. line.Id .. "_" .. id)
		local bed = st and st:FindFirstChild("TrackBed")
		local center = Metro.center(id, line)
		local ok = false
		if bed then
			local dot = bed.CFrame.LookVector:Dot(Metro.direction(line, i))
			local off = (bed.CFrame.Position - Vector3.new(center.X, bed.CFrame.Position.Y, center.Z)).Magnitude
			ok = dot > 0.999 and off < 0.5
		end
		check(ok, ("%s %s: la vía del andén sigue la línea"):format(line.Id, id))
	end
end

print("Detalles del metro")
local tagged: { [string]: { any } } = {}
for _, d in (under :: any):GetDescendants() do
	if d:IsA("BasePart") then
		for _, t in d:GetTags() do
			tagged[t] = tagged[t] or {}
			table.insert(tagged[t], d)
		end
	end
end
local function count(tag: string): number
	return #(tagged[tag] or {})
end
local stations = 0
for _, line in Metro.Lines do
	stations += #line.Stations
end
check(count("MetroToilet") >= stations, "váteres en los aseos de las estaciones y de la galería")
check(count("MetroSink") >= 1 and count("MetroDryer") >= 1, "lavabos y secamanos")
check(count("MetroGuardPost") >= stations, "guardias (y limpiadores) en cada vestíbulo")
check(count("MetroRatNest") >= stations * 2, "ratas en las vías")
check(count("MetroLocker") >= 6 and count("MetroATM") >= 1 and count("MetroPhone") >= 1 and count("MetroBin") >= 1, "taquillas, cajeros, teléfonos y papeleras")
check(count("MetroFountain") == 1 and count("MetroPiano") == 1 and count("MetroStatue") == 1, "fuente, piano y estatua humana en la galería")
local shopsOk = true
for _, counter in tagged.MetroShop or {} do
	if not Metro.Shops[counter:GetAttribute("ShopId")] then
		shopsOk = false
		print("     tienda sin datos: " .. tostring(counter:GetAttribute("ShopId")))
	end
end
check(shopsOk, "todas las tiendas y puestos tienen su lista de productos")
local guardsOk = true
for _, post in tagged.MetroGuardPost or {} do
	if typeof(post:GetAttribute("A")) ~= "Vector3" or typeof(post:GetAttribute("B")) ~= "Vector3" then
		guardsOk = false
	end
end
for _, nest in tagged.MetroRatNest or {} do
	if typeof(nest:GetAttribute("A")) ~= "Vector3" or typeof(nest:GetAttribute("B")) ~= "Vector3" then
		guardsOk = false
	end
end
check(guardsOk, "guardias y ratas saben por dónde ir (A y B)")

print("Nada sólido tapa el paso")
local keys = {}
for _, tag in { "MetroBoard", "MetroExit", "MetroArrival", "MetroTransfer", "MetroHubArrival", "MetroAlight" } do
	for _, p in tagged[tag] or {} do
		table.insert(keys, { tag, p.CFrame.Position })
	end
end
for _, tag in { "MetroGate", "MetroGateExit" } do
	for _, g in tagged[tag] or {} do
		table.insert(keys, { tag .. " (al pasar)", g:GetAttribute("Through") })
	end
end
local blocked = 0
for _, p in (under :: any):GetDescendants() do
	if p:IsA("BasePart") and p.CanCollide and p.Transparency < 1 and #p:GetTags() == 0 or (p:IsA("BasePart") and p.CanCollide and p.Transparency < 1 and p:HasTag("MetroShop")) then
		for _, k in keys do
			local rel = p.CFrame:PointToObjectSpace(k[2])
			local h = p.Size / 2
			if math.abs(rel.X) < h.X + 0.5 and math.abs(rel.Y) < h.Y + 0.5 and math.abs(rel.Z) < h.Z + 0.5 then
				blocked += 1
				print(("     %s tapa %s"):format(p:GetFullName(), k[1]))
			end
		end
	end
end
check(blocked == 0, "tornos, escaleras, andenes y transbordos libres")

print(if failures == 0 then "\nTodo bien ✅" else ("\n%d fallos ❌"):format(failures))
process.exit(if failures == 0 then 0 else 1)
