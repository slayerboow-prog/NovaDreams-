-- Prueba de los árboles (World/Kit/Nature) y de las montañas del fondo (shared/Horizon) FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-nature.luau                 (árboles de prueba y montañas)
--   lune run scripts/test-nature.luau /tmp/x.rbxl      (además, los árboles del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Comprueba que:
--   * cada árbol tiene tronco que se estrecha (dos tramos que chocan), 2-4 ramas, raíces a veces y
--     una copa de 8 a 16 racimos de formas y tonos distintos, sin colisión y con sombra
--   * los racimos de relleno y las raíces llevan LeafDetail (el nivel Bajo los esconde) y sin ellos
--     el árbol conserva la silueta (núcleo, punta de cada rama y copete)
--   * los nombres son los que esperan los demás (Trunk/Branch/Root con corteza, Leaves para la
--     estación y el viento) y el árbol no gasta números de math.random (no cambia el resto de la
--     ciudad al azar); el mismo sitio da el mismo árbol
--   * cipreses con varios husos y el mismo cuidado
--   * montañas del fondo: una silueta por montaña del terreno, que se esconde al acercarte; la
--     sierra lejana queda lejos del mar y de lo jugable; ninguna pieza pasa de 2048 studs

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

-- math con contador de math.random (para ver que el árbol no los gasta)
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

local base = { Enum = Enum, Vector3 = Vector3, Color3 = Color3, CFrame = CFrame, Instance = Instance }
local function env(extra: { [string]: any }): { [string]: any }
	local out = table.clone(base)
	for k, v in extra do
		out[k] = v
	end
	return out
end

local BUILDER, PALETTE, ASSETS, CITYPLAN = {}, {}, {}, {}
local Builder = load("src/server/World/Builder.luau", env({}))
local Palette = load("src/server/World/Kit/Palette.luau", env({}))
local AssetLibrary = { spawn = function() return nil end }
local Nature = load("src/server/World/Kit/Nature.luau", env({
	math = countingMath,
	script = { Parent = { Parent = { Builder = BUILDER }, Palette = PALETTE, AssetLibrary = ASSETS } },
	require = function(m)
		if m == BUILDER then
			return Builder
		elseif m == PALETTE then
			return Palette
		elseif m == ASSETS then
			return AssetLibrary
		end
		error("require inesperado")
	end,
}))
local Textures = load("src/shared/Textures.luau", env({}))

---------------------------------------------------------------------
-- Un árbol: lo que tiene
---------------------------------------------------------------------
type Info = { Trunk: { any }, Branch: { any }, Root: { any }, Leaves: { any }, Other: { any }, Parts: number }
local function inspect(m: any): Info
	local info: Info = { Trunk = {}, Branch = {}, Root = {}, Leaves = {}, Other = {}, Parts = 0 }
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			info.Parts += 1
			local list = (info :: any)[d.Name] or info.Other
			table.insert(list, d)
		end
	end
	return info
end

print("Árboles de hoja ancha (Kit/Nature.tree)")
local world = Instance.new("Model")
local trees = {}
randomCalls = 0
for i = 1, 60 do
	local pos = Vector3.new((i % 10) * 37.3 - 160, 0, math.floor(i / 10) * 41.7 - 120)
	table.insert(trees, Nature.tree(world, pos, if i % 3 == 0 then nil else 0.8 + (i % 7) * 0.1))
end
check(randomCalls <= 2 * #trees, ("el árbol casi no gasta math.random (%d llamadas en %d árboles: solo el giro y el tono)"):format(randomCalls, #trees))

local okTrunk, okBranch, okLeaves, okShadow, okTags, okDetail, okNames, okSilhouette, okTaper = true, true, true, true, true, true, true, true, true
local totalParts, hiddenLow, blocks, balls, minLeaves, maxLeaves, withRoots = 0, 0, 0, 0, math.huge, 0, 0
local tones = {}
for _, m in trees do
	local info = inspect(m)
	totalParts += info.Parts
	if #info.Trunk ~= 2 then
		okTrunk = false
	else
		for _, t in info.Trunk do
			if not t.CanCollide or t.Material ~= Enum.Material.Wood or not Textures.Bark[t.Name] then
				okTrunk = false
			end
		end
		-- El de abajo, más grueso
		local a, b = info.Trunk[1], info.Trunk[2]
		local low, high = if a.CFrame.Position.Y < b.CFrame.Position.Y then a else b, if a.CFrame.Position.Y < b.CFrame.Position.Y then b else a
		if not (low.Size.Y > high.Size.Y) then
			okTaper = false
		end
	end
	if #info.Branch < 2 or #info.Branch > 4 then
		okBranch = false
	end
	for _, b in info.Branch do
		if b.CanCollide or not Textures.Bark[b.Name] then
			okBranch = false
		end
	end
	if #info.Root > 0 then
		withRoots += 1
	end
	for _, r in info.Root do
		if r.CanCollide or not r:HasTag("LeafDetail") or not Textures.Bark[r.Name] then
			okBranch = false
		end
	end
	minLeaves = math.min(minLeaves, #info.Leaves)
	maxLeaves = math.max(maxLeaves, #info.Leaves)
	local shadows, main = 0, 0
	local toneSet = {}
	for _, l in info.Leaves do
		if l.CanCollide or l.CanQuery or l.Material ~= Enum.Material.LeafyGrass then
			okLeaves = false
		end
		if not l:HasTag("Sway") or typeof(l:GetAttribute("Pivot")) ~= "Vector3" then
			okTags = false
		end
		if l.CastShadow then
			shadows += 1
		end
		if l:HasTag("LeafDetail") then
			hiddenLow += 1
		else
			main += 1
		end
		if l.Shape == Enum.PartType.Block then
			blocks += 1
		else
			balls += 1
		end
		toneSet[("%d,%d,%d"):format(l.Color.R * 255, l.Color.G * 255, l.Color.B * 255)] = true
	end
	hiddenLow += #info.Root
	local n = 0
	for _ in toneSet do
		n += 1
	end
	table.insert(tones, n)
	if shadows < #info.Leaves * 0.6 then
		okShadow = false
	end
	-- Silueta sin el relleno: núcleo + una por rama + copete
	if main < #info.Branch + 2 then
		okSilhouette = false
	end
	if main == #info.Leaves then
		okDetail = false
	end
	if #info.Other > 0 then
		okNames = false
	end
end
table.sort(tones)
check(okTrunk and okTaper, "tronco en dos tramos que se estrecha hacia arriba, de madera con corteza y que choca")
check(okBranch, "2-4 ramas principales y raíces: sin colisión, con corteza (Textures.Bark); las raíces son detalle")
check(withRoots > #trees * 0.4 and withRoots < #trees, ("raíces en algunos árboles (%d de %d)"):format(withRoots, #trees))
check(minLeaves >= 8 and maxLeaves <= 16 and maxLeaves > minLeaves + 3, ("copa de %d a %d racimos según el tamaño"):format(minLeaves, maxLeaves))
check(okLeaves and okTags, "racimos de LeafyGrass (la estación los pinta), sin colisión ni consultas, que se mecen (Sway + Pivot)")
check(okShadow, "la copa echa sombra (casi todos los racimos)")
check(blocks > 0 and balls > blocks, ("formas variadas: %d bolas y %d bloques girados"):format(balls, blocks))
check(tones[1] >= 6, ("cada racimo con su tono de verde (como mínimo %d tonos por árbol)"):format(tones[1]))
check(okDetail and okSilhouette, "el relleno lleva LeafDetail y sin él queda la silueta (núcleo, ramas y copete)")
check(okNames, "solo piezas con nombre conocido (Trunk, Branch, Root, Leaves)")
local avg = totalParts / #trees
check(avg <= 20, ("piezas por árbol: %.1f de media (≤ 20)"):format(avg))
check((totalParts - hiddenLow) / #trees <= 13, ("en el nivel Bajo se pintan %.1f por árbol"):format((totalParts - hiddenLow) / #trees))
local again = Nature.tree(Instance.new("Model"), Vector3.new(12.5, 0, -40), 1)
local again2 = Nature.tree(Instance.new("Model"), Vector3.new(12.5, 0, -40), 1)
local i1, i2 = inspect(again), inspect(again2)
check(i1.Parts == i2.Parts and #i1.Leaves == #i2.Leaves and #i1.Branch == #i2.Branch, "el mismo sitio da el mismo árbol")

print("Cipreses (Kit/Nature.cypress)")
do
	local okC = true
	for i = 1, 20 do
		local m = Nature.cypress(world, Vector3.new(i * 11.1, 0, 300))
		local info = inspect(m)
		local detail = 0
		for _, l in info.Leaves do
			if l.CanCollide or l.Material ~= Enum.Material.LeafyGrass or not l:FindFirstChildOfClass("SpecialMesh") then
				okC = false
			end
			if l:HasTag("LeafDetail") then
				detail += 1
			end
		end
		if #info.Trunk ~= 1 or not info.Trunk[1].CanCollide or #info.Leaves < 4 or detail < 1 or detail >= #info.Leaves - 2 then
			okC = false
		end
	end
	check(okC, "ciprés: tronco que choca y copa de varios husos (elipsoides) con relleno LeafDetail")
end

---------------------------------------------------------------------
-- Montañas del fondo (shared/Horizon)
---------------------------------------------------------------------
print("Montañas del fondo (shared/Horizon)")
local CityPlan = load("src/shared/CityPlan.luau", env({}))
local Horizon = load("src/shared/Horizon.luau", env({
	script = { Parent = { CityPlan = CITYPLAN } },
	require = function(m)
		if m == CITYPLAN then
			return CityPlan
		end
		error("require inesperado")
	end,
}))
local mountains = Horizon.mountainPieces()
local rocks = 0
for _, m in CityPlan.Mountains do
	if m.Rock then
		rocks += 1
	end
end
check(#mountains == #CityPlan.Mountains + rocks, ("una silueta por montaña del terreno (%d piezas)"):format(#mountains))
local okInside, okHide = true, true
for _, p in mountains do
	if not p.HideWithin or p.HideWithin < 768 + 100 then
		okHide = false
	end
	if p.Far then
		okInside = false
	end
	if p.Size.X > Horizon.MaxSize or p.Size.Y > Horizon.MaxSize or p.Size.Z > Horizon.MaxSize then
		okInside = false
	end
end
-- La silueta no asoma por el terreno: en cualquier punto, la altura del elipsoide no pasa de la del terreno
for i, m in CityPlan.Mountains do
	local p = mountains[1]
	for _, q in mountains do
		if q.Name == "Monte" .. i then
			p = q
		end
	end
	local a, b = p.Size.X / 2, p.Size.Y / 2
	for d = 0, a, a / 20 do
		local ell = b * math.sqrt(math.max(0, 1 - (d / a) ^ 2))
		local cap = math.sqrt(math.max(0, m.R * m.R - d * d)) - (m.R - m.H)
		if ell > cap + 0.5 then
			okInside = false
		end
	end
end
check(okHide, "cada silueta se esconde al acercarte (más allá de la carga por zonas, 768 studs)")
check(okInside, "las siluetas quedan dentro del terreno de verdad (no asoman) y no pasan de 2048 studs")
local far = Horizon.farPieces()
local seaEdge = CityPlan.Bounds.MinZ - 800
local okFar = #far >= 12
for _, p in far do
	if not p.Far or p.HideWithin ~= nil or p.Center.Z + p.Size.Z / 2 > seaEdge - Horizon.SeaMargin + 0.01 then
		okFar = false
	end
	if p.Size.X > Horizon.MaxSize or p.Size.Y > Horizon.MaxSize or p.Size.Z > Horizon.MaxSize then
		okFar = false
	end
end
check(okFar, ("sierra lejana: %d montañas más allá del mar (≥ %d studs del agua), sin pasar de 2048"):format(#far, Horizon.SeaMargin))
local first = mountains[1]
check(not Horizon.visible(first, first.Center + Vector3.new(100, 20, 0)) and Horizon.visible(first, first.Center + Vector3.new(first.HideWithin + 10, 0, 0)) and Horizon.visible(far[1], Vector3.zero), "de cerca la silueta se esconde; de lejos se ve; la sierra lejana, siempre")
local client = fs.readFile("src/client/Controllers/Horizon.luau")
check(client:find("FarRange", 1, true) and client:find("CanCollide = false", 1, true) and client:find("CanQuery = false", 1, true) and client:find("CastShadow = false", 1, true), "el cliente las pinta sin colisión, consultas ni sombra, y la sierra solo en Medio y Alto")
check(fs.readFile("src/client/Main.client.luau"):find("Controllers.Horizon", 1, true) ~= nil, "Main arranca las montañas del fondo")

---------------------------------------------------------------------
-- El mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("Mapa construido (" .. placePath .. ")")
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local count, parts, bad, detail = 0, 0, 0, 0
	for _, d in place:GetService("Workspace"):GetDescendants() do
		if d:IsA("Model") and d.Name == "Tree" and d:FindFirstChild("Trunk") then
			count += 1
			local info = inspect(d)
			parts += info.Parts
			if #info.Leaves < 8 or #info.Trunk ~= 2 then
				bad += 1
			end
			for _, l in info.Leaves do
				if l:HasTag("LeafDetail") then
					detail += 1
				end
			end
		end
	end
	check(count > 1000, ("hay %d árboles"):format(count))
	check(bad == 0, ("todos con tronco en dos tramos y copa de racimos (%d raros)"):format(bad))
	check(count > 0 and parts / count <= 20, ("%.1f piezas por árbol de media (%d en total)"):format(parts / math.max(count, 1), parts))
	check(detail > count * 2, ("%d racimos de relleno que el nivel Bajo esconde"):format(detail))
end

if failures > 0 then
	print(("\n❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("\n✅ Árboles y montañas del fondo bien")
