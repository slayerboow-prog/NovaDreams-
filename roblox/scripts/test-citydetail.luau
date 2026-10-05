-- Prueba del detalle fino de la ciudad (World/Kit/CityDetail, gráficos fase 2) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-citydetail.luau                 (piezas de prueba y reglas del código)
--   lune run scripts/test-citydetail.luau /tmp/x.rbxl      (además, el mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Comprueba que:
--   * las hiladas de teja quedan pegadas al faldón (encima, sin flotar ni hundirse), solapadas y
--     levantadas por abajo, y que ni las tejas ni el desgaste del asfalto gastan math.random
--   * el nivel Bajo esconde la etiqueta CityDetail (shared/Graphics + Controllers/MaterialDetail)
--   * en el mapa: todo lo de CityDetail es adorno (sin colisión, ni consultas, ni toques; lo plano y lo
--     pequeño sin sombra); las casas de tejado inclinado llevan tejas, cumbrera, remates y hastiales;
--     hay bloques bajos con tejado de teja; el desgaste del asfalto va por debajo de las marcas viales
--     y nunca encima de un paso de cebra; bancos, papeleras y buzones nuevos en la acera; farolas con pie
--   * el mapa no se dispara de piezas

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

local randomCalls = 0
local countingMath = setmetatable({
	random = function(...)
		randomCalls += 1
		return math.random(...)
	end,
}, { __index = math })

local function load(path: string, env: { [string]: any }): any
	local full = setmetatable(env, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = full })()
end

local Builder = load("src/server/World/Builder.luau", { Instance = Instance, Enum = Enum, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3 })
local CityDetail = load("src/server/World/Kit/CityDetail.luau", {
	Instance = Instance,
	Enum = Enum,
	Vector3 = Vector3,
	CFrame = CFrame,
	Color3 = Color3,
	math = countingMath,
	script = { Parent = { Parent = {} } },
	require = function()
		return Builder
	end,
})

---------------------------------------------------------------------
print("▶ Tejas con relieve")
---------------------------------------------------------------------
do
	local holder = Instance.new("Model")
	local size = Vector3.new(24, 7, 12)
	local wedgeCf = CFrame.new(100, 20, 50) * CFrame.Angles(0, math.rad(30), 0)
	randomCalls = 0
	local rows = CityDetail.tiles(holder, wedgeCf, size, Color3.fromRGB(170, 80, 50), Enum.Material.ClayRoofTiles)
	CityDetail.verges(holder, wedgeCf, size, Color3.new(1, 1, 1))
	local frame, length = CityDetail.slopeFrame(wedgeCf, size)
	local tiles, onSlope, tagged, decor, tilted = 0, 0, 0, 0, 0
	for _, p in holder:GetChildren() do
		if p.Name == "RoofTiles" then
			tiles += 1
			local q = frame:PointToObjectSpace(p.CFrame.Position)
			-- (encima del faldón, a menos de medio stud, y dentro de su largo)
			if q.Y > 0 and q.Y < 0.5 and math.abs(q.Z) <= length / 2 and math.abs(q.X) < 0.01 then
				onSlope += 1
			end
			-- Cada hilada más larga que la separación (se solapan) y su borde de abajo más alto que el faldón
			local lower = p.CFrame * CFrame.new(0, -p.Size.Y / 2, -p.Size.Z / 2)
			if p.Size.Z > length / rows and frame:PointToObjectSpace(lower.Position).Y > 0.05 then
				tilted += 1
			end
		end
		if p:HasTag("CityDetail") then
			tagged += 1
		end
		if not p.CanCollide and not p.CanQuery and not p.CanTouch then
			decor += 1
		end
	end
	local total = #holder:GetChildren()
	check(rows >= 5 and tiles == rows, ("%d hiladas en un faldón de %.1f studs (una cada %.1f)"):format(tiles, length, CityDetail.TILE_ROW))
	check(onSlope == tiles, "todas las hiladas pegadas encima del faldón (ni flotan ni se hunden)")
	check(tilted == tiles, "se solapan y el borde de abajo de cada una sobresale (el escalón de la teja)")
	check(tagged == total and decor == total, "tejas y remates: adorno sin colisión con la etiqueta CityDetail (el nivel Bajo los esconde)")
	check(randomCalls == 0, "las tejas no gastan math.random (el resto de la ciudad sale igual)")
end

---------------------------------------------------------------------
print("▶ Desgaste del asfalto")
---------------------------------------------------------------------
do
	local holder = Instance.new("Model")
	local ROAD_TOP = 0.4
	randomCalls = 0
	CityDetail.roadWear(holder, "X", 0, 2000, function(u, v, y)
		return Vector3.new(u, y, 300 + v)
	end, 24, ROAD_TOP, function(u)
		return u < 900 or u > 1100 -- (una bocacalle de mentira en medio)
	end)
	local kinds, low, inside, inCut = {}, 0, 0, 0
	for _, p in holder:GetChildren() do
		kinds[p.Name] = (kinds[p.Name] or 0) + 1
		local top = p.CFrame.Position.Y + 0.01
		if top <= ROAD_TOP + 0.035 and p.CFrame.Position.Y > ROAD_TOP then
			low += 1
		end
		if math.abs(p.CFrame.Position.Z - 300) < 12 then
			inside += 1
		end
		if p.CFrame.Position.X > 920 and p.CFrame.Position.X < 1080 then
			inCut += 1
		end
	end
	local n = #holder:GetChildren()
	check((kinds.AsphaltPatch or 0) > 5 and (kinds.OilStain or 0) > 5 and (kinds.Crack or 0) > 5, ("parches (%d), manchas de aceite (%d) y grietas (%d)"):format(kinds.AsphaltPatch or 0, kinds.OilStain or 0, kinds.Crack or 0))
	check(low == n, "todo pegado al asfalto y por debajo de las marcas viales (que suben 0,04)")
	check(inside == n, "todo dentro de la calzada")
	check(inCut == 0, "nada en la bocacalle (ni encima de su paso de cebra)")
	check(randomCalls == 0, "el desgaste no gasta math.random")
end

---------------------------------------------------------------------
print("▶ El nivel Bajo lo esconde")
---------------------------------------------------------------------
do
	local graphics = fs.readFile("src/shared/Graphics.luau")
	local detail = fs.readFile("src/client/Controllers/MaterialDetail.luau")
	local low = graphics:match("Low = {(.-)\n\t}")
	local medium = graphics:match("Medium = {(.-)\n\t}")
	local high = graphics:match("High = {(.-)\n\t}")
	check(low and low:find("CityDetail = false", 1, true) and medium and medium:find("CityDetail = true", 1, true) and high and high:find("CityDetail = true", 1, true), "Graphics: CityDetail apagado en Bajo y encendido en Medio y Alto")
	check(graphics:find('CityDetail = "CityDetail"', 1, true) and detail:find("Graphics.DetailTags", 1, true) and detail:find("GetInstanceAddedSignal(tag)", 1, true) and detail:find("LocalTransparencyModifier", 1, true), "MaterialDetail esconde las piezas CityDetail (también las que llegan después)")
end

---------------------------------------------------------------------
-- Mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("▶ Mapa construido (" .. placePath .. ")")
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local town = place:GetService("Workspace"):FindFirstChild("Town")
	check(town ~= nil, "hay ciudad construida")
	if town then
		local total, detail, badDecor, badShadow = 0, 0, 0, 0
		local names: { [string]: number } = {}
		local zebras = {}
		local wear = {}
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") then
				total += 1
				if d:HasTag("CityDetail") then
					detail += 1
					names[d.Name] = (names[d.Name] or 0) + 1
					if d.CanCollide or d.CanQuery or d.CanTouch then
						badDecor += 1
					end
					local s = d.Size
					if (math.min(s.X, s.Y, s.Z) < 0.2 or math.max(s.X, s.Y, s.Z) < 4) and d.CastShadow then
						badShadow += 1
					end
					if d.Name == "AsphaltPatch" or d.Name == "OilStain" or d.Name == "Crack" then
						table.insert(wear, d)
					end
				elseif d.Name == "Zebra" then
					table.insert(zebras, d)
				end
			end
		end
		check(badDecor == 0, ("%d piezas de detalle, todas de adorno (sin colisión, consultas ni toques)"):format(detail))
		check(badShadow == 0, ("lo plano y lo pequeño no echa sombra (%d sí)"):format(badShadow))

		-- Casas con tejado inclinado: tejas, cumbrera, remates y hastiales
		local houses, full = 0, 0
		local blocks, pitchedBlocks = 0, 0
		for _, m in town:GetDescendants() do
			if m:IsA("Model") and m.Name == "Casa" then
				local wedge, tiles, verge, gable, ridge = 0, 0, 0, 0, 0
				for _, p in m:GetChildren() do
					if p.Name == "Roof" and p:IsA("WedgePart") then
						wedge += 1
					elseif p.Name == "RoofTiles" then
						tiles += 1
					elseif p.Name == "Verge" then
						verge += 1
					elseif p.Name == "GableWall" then
						gable += 1
					elseif p.Name == "Ridge" then
						ridge += 1
					end
				end
				if wedge > 0 then
					houses += 1
					if tiles >= 6 and verge == 4 and gable == 4 and ridge == 1 then
						full += 1
					end
				end
			elseif m:IsA("Model") and m.Name == "Bloque" then
				blocks += 1
				local roof = m:FindFirstChild("Roof")
				if roof and roof:IsA("WedgePart") and m:FindFirstChild("RoofTiles") and m:FindFirstChild("RidgeTiles") then
					pitchedBlocks += 1
				end
			end
		end
		check(houses > 100 and full == houses, ("%d casas con tejado de teja: %d con hiladas, cumbrera, remates y hastiales"):format(houses, full))
		check(pitchedBlocks > 50 and pitchedBlocks < blocks, ("%d de %d bloques con tejado de teja a dos aguas (los altos y los modernos, azotea)"):format(pitchedBlocks, blocks))

		-- Desgaste del asfalto: nunca encima de un paso de cebra
		local CELL = 32
		local grid = {}
		for _, z in zebras do
			local k = math.floor(z.CFrame.Position.X / CELL) .. ":" .. math.floor(z.CFrame.Position.Z / CELL)
			grid[k] = grid[k] or {}
			table.insert(grid[k], z)
		end
		local onZebra = 0
		for _, w in wear do
			local p = w.CFrame.Position
			for gx = math.floor(p.X / CELL) - 1, math.floor(p.X / CELL) + 1 do
				for gz = math.floor(p.Z / CELL) - 1, math.floor(p.Z / CELL) + 1 do
					for _, z in grid[gx .. ":" .. gz] or {} do
						local q = z.CFrame:PointToObjectSpace(p)
						if math.abs(q.X) < z.Size.X / 2 + 1 and math.abs(q.Z) < z.Size.Z / 2 + 1 then
							onZebra += 1
						end
					end
				end
			end
		end
		check(#wear > 1000, ("%d marcas de desgaste en el asfalto"):format(#wear))
		check(onZebra == 0, ("ninguna sobre un paso de cebra (%d sí)"):format(onZebra))
		check((names.TreeGrate or 0) > 200, ("%d alcorques con rejilla"):format(names.TreeGrate or 0))

		-- Mobiliario nuevo de la acera y farolas
		local benches, bins, mail, lamps, footed = 0, 0, 0, 0, 0
		for _, m in town:GetDescendants() do
			if m:IsA("Model") then
				if m.Name == "BancoCalle" and m:HasTag("Bench") and m:FindFirstChild("Seat") then
					benches += 1
				elseif m.Name == "PapeleraCalle" and m:FindFirstChild("Bin") and m.Bin:HasTag("Papelera") then
					bins += 1
				elseif m.Name == "BuzonCorreos" then
					mail += 1
				elseif m.Name == "StreetLamp" then
					lamps += 1
					if m:FindFirstChild("LampFoot") and m:FindFirstChild("LampBrace") then
						footed += 1
					end
				end
			end
		end
		check(benches > 100 and bins > 100 and mail > 30, ("acera con más vida: %d bancos, %d papeleras y %d buzones nuevos"):format(benches, bins, mail))
		check(lamps > 1000 and footed == lamps, ("%d farolas con pie de fundición y tornapuntas"):format(lamps))
		-- (la fase 1 dejó el mapa en ~366.000 piezas; la fase 2 no puede subir más de un 12 %)
		check(total < 366116 * 1.12, ("%d piezas en el mapa (fase 1: 366.116; +%.1f %%)"):format(total, (total / 366116 - 1) * 100))
	end
end

if failures > 0 then
	print(("\n❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("\n✅ Detalle de la ciudad bien")
