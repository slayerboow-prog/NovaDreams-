-- Prueba de los muebles, la comida y los objetos de la Tienda en los interiores (World/InteriorProps)
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-interiorprops.luau
--
-- En Lune no hay AssetService: un cargador de mentira hace un asset parecido a cada uno de verdad
-- (con los nombres de docs/assets-usuario*.md) y le mete lo peligroso: scripts, NumberPose,
-- PlaneConstraint, ProximityPrompt, sonidos, Decal, atributos, marcas, nombres de otros juegos.
-- Las salas son las de verdad de World/Interiors. Comprueba que:
--   * no queda ningún script ni nada que no sea pieza, malla, SurfaceAppearance o Texture
--   * no quedan marcas (texturas de las latas, la bolsa de gato con su marca) ni nombres de otros
--     juegos o de miedo; la comida de gato lleva la marca inventada
--   * cada cosa va donde toca, a su talla, apoyada y sin chocar con lo que ya había ni tapar la puerta
--   * si un asset (o todos) no carga, no pasa nada

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame
local V = Vector3.new
local check = L.check

local Interiors = L.load("src/server/World/Interiors")
local P = L.load("src/server/World/InteriorProps")
local MeshLibrary = L.load("src/server/World/MeshLibrary")

---------------------------------------------------------------------
-- Assets de mentira
---------------------------------------------------------------------
local function dirt(parent: Instance)
	-- lo que traen los packs con virus y lo que no debe quedar
	local s = Instance.new("Script")
	s.Name = "CoreValidation"
	s.Parent = parent
	local ls = Instance.new("LocalScript")
	ls.Parent = parent
	local pose = Instance.new("NumberPose")
	pose.Name = "Pose"
	pose.Parent = parent
	local plane = Instance.new("PlaneConstraint")
	plane:SetAttribute("a", ")]1[)'1234'(stcejbOteG:emag")
	plane.Parent = parent
	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = parent
	local sound = Instance.new("Sound")
	sound.Parent = parent
	local decal = Instance.new("Decal")
	decal.Name = "Logo"
	decal.Parent = parent
end

local function part(name: string, size: Vector3, pos: Vector3, parent: Instance, class: string?): BasePart
	local p = Instance.new(class or "MeshPart") :: any
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Anchored = false
	p:SetAttribute("InjectedByDependencyInjector", true)
	p:AddTag("Raro")
	if (class or "MeshPart") == "MeshPart" then
		p.TextureID = "rbxassetid://111"
	end
	local sa = Instance.new("SurfaceAppearance")
	sa.Parent = p
	dirt(p)
	p.Parent = parent
	return p
end

local function model(name: string, parent: Instance, parts: { { any } }): Model
	local m = Instance.new("Model")
	m.Name = name
	for _, d in parts do
		part(d[1], d[2], d[3], m, d[4])
	end
	dirt(m)
	m.Parent = parent
	return m
end

local function asset(build: (Model) -> ()): Model
	local root = Instance.new("Model")
	root.Name = "Model"
	build(root)
	return root
end

local ASSETS: { [number]: () -> Instance? } = {
	[8236576991] = function()
		return asset(function(r)
			part("realistic mesh", V(50, 38.1, 39.2), V(0, 19, 0), r)
		end)
	end,
	[13395313510] = function()
		return asset(function(r)
			local s = Instance.new("Model")
			s.Name = "склад"
			s.Parent = r
			for k = 0, 1 do
				local shelf = Instance.new("Model")
				shelf.Name = "Model"
				shelf.Parent = s
				for i = 0, 9 do
					part("Part", V(10, 1, 10), V(k * 20, 13.9, -45 + i * 10), shelf, "Part")
				end
				part("Upright", V(1, 27.8, 1), V(k * 20, 13.9, -50), shelf, "Part")
				part("Upright", V(1, 27.8, 1), V(k * 20, 13.9, 50), shelf, "Part")
			end
		end)
	end,
	[13262637537] = function()
		return asset(function(r)
			model("Furniture_Credenza_A", r, { { "Credenza", V(7, 3, 2), V(0, 1.5, 0) } })
			model("Furniture_Console_A", r, { { "Console", V(5, 3, 1.5), V(10, 1.5, 0) } })
			model("Amoire_A", r, { { "Amoire", V(5, 8, 2.4), V(20, 4, 0) } })
			model("Couch_Single_Plaid", r, { { "Couch", V(3.5, 3.4, 3.5), V(30, 1.7, 0) } })
			part("Shirvan Kilim", V(20, 0.2, 14), V(40, 0.1, 0), r)
			model("Bones_Assortment", r, { { "Bone", V(1, 1, 1), V(50, 0.5, 0) } })
			model("Dracula poster", r, { { "Poster", V(3, 4, 0.1), V(60, 2, 0) } })
			model("StarterCharacter", r, { { "Head", V(2, 2, 2), V(70, 1, 0) } })
		end)
	end,
	[5674029686] = function()
		return asset(function(r)
			model("Mueble", r, { { "Part", V(8.8, 3.2, 2.9), V(0, 1.6, 0), "Part" } })
		end)
	end,
	[5677783820] = function()
		return asset(function(r)
			model("MuebleComputadora", r, { { "Top", V(5, 0.3, 2.5), V(0, 3, 0), "Part" }, { "Leg", V(0.3, 3, 2.5), V(-2.4, 1.5, 0), "Part" } })
		end)
	end,
	[8136205160] = function()
		return asset(function(r)
			local m = model("t", r, { { "Bowl", V(3.2, 4, 3.7), V(0, 2, 0) }, { "Tank", V(3.2, 4.4, 1.5), V(0, 6.2, 1.1) } })
			local seat = Instance.new("Seat")
			seat.Size = V(3, 0.3, 3)
			seat.Parent = m
		end)
	end,
	[991205683] = function()
		return asset(function(r)
			part("Pillow", V(1.6, 1, 1.7), V(0, 0.5, 0), r, "UnionOperation")
		end)
	end,
	[106442157390222] = function()
		return asset(function(r)
			model("Doors Drawer Hotel Killer Seek Rush Figure RP", r, { { "Drawer", V(3.1, 3.3, 2.7), V(0, 1.65, 0) }, { "Seek Figure", V(1, 1, 1), V(0, 4, 0) } })
		end)
	end,
	[130817699186912] = function()
		return asset(function(r)
			model("Bonsai", r, { { "Bonsai", V(2, 3, 2), V(0, 1.5, 0) } })
			model("Ramen", r, { { "Bowl", V(1.5, 0.8, 1.5), V(5, 0.4, 0) } })
			model("Japanese Lamp", r, { { "Lamp", V(1.5, 5, 1.5), V(10, 2.5, 0) } })
			model("Planter", r, { { "Planter", V(2, 2, 2), V(15, 1, 0) } })
			model("Torii", r, { { "Torii", V(22.2, 16.7, 1.6), V(30, 8, 0) } })
		end)
	end,
	[9802494780] = function()
		return asset(function(r)
			part("MeshPart", V(38.8, 114.6, 36.8), V(0, 57, 0), r)
			part("MeshPart", V(18, 93, 62), V(50, 46, 0), r)
			part("MeshPart", V(24.8, 21.3, 33.1), V(100, 10, 0), r)
			part("MeshPart", V(34.1, 13.5, 30.5), V(150, 7, 0), r)
			part("MeshPart", V(11.1, 10.1, 27.6), V(200, 5, 0), r)
			part("MeshPart", V(8.2, 14.2, 13.4), V(250, 7, 0), r)
		end)
	end,
	[9658188636] = function()
		return asset(function(r)
			model("pergolesi chair", r, { { "Seat", V(2, 3.5, 2), V(0, 1.75, 0) } })
			model("Table", r, { { "Top", V(6, 3, 3), V(10, 1.5, 0) } })
			local lighting = Instance.new("ColorCorrectionEffect")
			lighting.Parent = r
		end)
	end,
	[12110426279] = function()
		return asset(function(r)
			model("Car 1", r, { { "Body", V(15.3, 7.6, 5.8), V(0, 4, 0) } })
			model("Barrel Explosive", r, { { "Barrel", V(2, 3, 2), V(20, 1.5, 0) } })
			model("Fridge", r, { { "Fridge", V(3, 6.5, 2.8), V(30, 3.25, 0) } })
			model("Locker", r, { { "Locker", V(6, 7, 2), V(40, 3.5, 0) } })
			model("Filing Cabinet", r, { { "Cabinet", V(2, 4.5, 2.5), V(50, 2.25, 0) } })
			model("Sofa", r, { { "Sofa", V(7, 3.4, 3), V(60, 1.7, 0) } })
			model("Fire Extinguisher", r, { { "Ext", V(0.8, 1.8, 0.8), V(70, 0.9, 0) } })
			model("Trash Bin", r, { { "Bin", V(1.6, 2.4, 1.6), V(80, 1.2, 0) } })
			model("Dog House", r, { { "House", V(4, 4, 5), V(90, 2, 0) } })
			model("Cafe Chair", r, { { "Chair", V(2, 3.5, 2), V(100, 1.75, 0) } })
		end)
	end,
	[17519952806] = function()
		return asset(function(r)
			model("calamares", r, { { "Ring", V(1.3, 0.4, 3.6), V(0, 0.2, 0) } })
			model("isaw", r, { { "Stick", V(0.8, 3.4, 0.6), V(5, 1.7, 0) } })
		end)
	end,
	[4609898985] = function()
		return asset(function(r)
			model("Model", r, { { "MeshPart", V(1, 1, 1), V(0, 0.5, 0) } })
			local cans = model("Model", r, { { "MeshPart", V(0.5, 1, 0.5), V(5, 0.5, 0) } })
			for _, p in cans:GetChildren() do
				if p:IsA("MeshPart") then
					p.TextureID = "rbxassetid://3152296920"
				end
			end
			model("Model", r, { { "meshblock", V(2, 0.3, 2), V(10, 0.15, 0) } })
		end)
	end,
	[82460675146164] = function()
		return asset(function(r)
			part("MeshPart", V(3.1, 5.9, 1.9), V(0, 3, 0), r)
		end)
	end,
	[95413639317338] = function()
		return asset(function(r)
			part("MeshPart", V(1.3, 0.1, 1.5), V(0, 0.05, 0), r)
		end)
	end,
	[9766849655] = function()
		return asset(function(r)
			model("Cupcake", r, { { "Base", V(0.8, 0.5, 0.8), V(0, 0.25, 0), "Part" }, { "Cherry", V(0.2, 0.2, 0.2), V(0, 0.7, 0), "Part" } })
		end)
	end,
	[15666503758] = function()
		return asset(function(r)
			local tool = Instance.new("Tool")
			tool.Name = "Whiskas"
			tool.Parent = r
			local h = part("Handle", V(1.1, 1.7, 0.9), V(0, 0.85, 0), tool, "Part")
			local mesh = Instance.new("SpecialMesh")
			mesh.TextureId = "http://www.roblox.com/asset/?id=52081598"
			mesh.Parent = h
			local acc = Instance.new("Accessory")
			acc.Parent = h
		end)
	end,
	[1305075170] = function()
		return asset(function(r)
			local stash = Instance.new("Model")
			stash.Name = "stash"
			stash.Parent = r
			for i = 0, 3 do
				local b = model("bandz", stash, { { "Bill", V(1, 0.4, 0.5), V(i, 0.2, 0), "Part" } })
				local gui = Instance.new("SurfaceGui")
				local tb = Instance.new("TextBox")
				tb.Text = "$10,000"
				tb.Parent = gui
				gui.Parent = b:FindFirstChild("Bill")
			end
		end)
	end,
	[11329271645] = function()
		return asset(function(r)
			part("Clipboard", V(1.1, 0.2, 1.6), V(0, 0.1, 0), r)
		end)
	end,
	[11444948273] = function()
		return asset(function(r)
			part("Wood Door", V(3.6, 7.5, 0.6), V(0, 3.75, 0), r)
		end)
	end,
	[166379099] = function()
		return nil -- (no carga: tiene que seguir todo)
	end,
	[123778443128832] = function()
		return asset(function(r)
			model("Group Rewards Chest", r, { { "Body", V(4, 3, 3), V(0, 1.5, 0) }, { "Lid", V(4, 1, 3), V(0, 3.5, 0) } })
			local folder = Instance.new("Configuration")
			folder.Name = "Settings"
			folder:SetAttribute("GroupID", 8582268)
			folder.Parent = r
		end)
	end,
}

local loads: { number } = {}
local function load(id: number): Instance?
	table.insert(loads, id)
	local f = ASSETS[id]
	assert(f, "asset sin doble: " .. tostring(id))
	return f()
end

---------------------------------------------------------------------
-- Choques (GetPartBoundsInBox de mentira: cajas alineadas)
---------------------------------------------------------------------
local World = Instance.new("Folder")
local function overlap(cf: CFrame, size: Vector3, within: Instance?): { BasePart }
	local probe = Instance.new("Part")
	probe.Size = size
	probe.CFrame = cf
	local lo, hi = P.bounds({ probe })
	local out = {}
	for _, d in (within or World):GetDescendants() do
		if d:IsA("BasePart") then
			local a, b = P.bounds({ d })
			if a.X < hi.X and b.X > lo.X and a.Y < hi.Y and b.Y > lo.Y and a.Z < hi.Z and b.Z > lo.Z then
				table.insert(out, d)
			end
		end
	end
	return out
end

---------------------------------------------------------------------
print("Plantillas limpias")
---------------------------------------------------------------------
local library = P.prepare(load, MeshLibrary.stripScripts)
local ruleCount = 0
for _ in library do
	ruleCount += 1
end
for i, rule in P.Rules do
	if not library[i] then
		print("    (sin plantilla: " .. rule.Name .. " " .. rule.Mode .. ")")
	end
end
check(ruleCount >= #P.Rules - 2, ("plantillas para casi todas las reglas (%d de %d; la silla gigante no carga)"):format(ruleCount, #P.Rules))
local seenIds = {}
for _, id in loads do
	check(not seenIds[id], "cada asset se carga una sola vez (" .. id .. ")")
	seenIds[id] = true
end
check(not seenIds[123553303846741], "el pack de texturas de Bloxburg no se carga nunca")

local function allowed(d: Instance): boolean
	return d:IsA("BasePart") or d:IsA("DataModelMesh") or d:IsA("SurfaceAppearance") or d:IsA("Texture") or d:IsA("Model")
		or d.Name == "Etiqueta" or d:IsA("TextLabel")
end
local function cleanTree(root: Instance): (boolean, string?)
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			return false, "script " .. d:GetFullName()
		end
		if not allowed(d) then
			return false, d.ClassName .. " " .. d.Name
		end
		if next(d:GetAttributes()) ~= nil and d.Name ~= "Etiqueta" then
			return false, "atributos en " .. d.Name
		end
		if d:IsA("BasePart") and #d:GetTags() > 0 then
			return false, "etiquetas en " .. d.Name
		end
	end
	return true, nil
end
local allClean, why = true, nil
local badNames = {}
local index = {}
for i, list in library do
	local rule = P.Rules[i]
	index[rule.Name .. "/" .. rule.Mode] = list
	for _, t in list do
		local ok, w = cleanTree(t.Model)
		if not ok then
			allClean, why = false, rule.Name .. ": " .. tostring(w)
		end
		for _, p in t.Model:GetDescendants() do
			if p:IsA("BasePart") then
				if not string.find(p.Name, "^" .. rule.Name) then
					table.insert(badNames, p.Name)
				end
				if P.matchesAny(p.Name, { "seek", "bone", "dracula", "car", "explosive", "whiskas" }) then
					table.insert(badNames, p.Name)
				end
				if not p.Anchored then
					table.insert(badNames, p.Name .. " (sin anclar)")
				end
				local ok2, tex = pcall(function()
					return (p :: any).TextureID
				end)
				if ok2 and tex == "rbxassetid://3152296920" then
					table.insert(badNames, "lata de cola")
				end
			end
		end
	end
end
check(allClean, "sin scripts, sonidos, prompts, Decal, constraints, atributos ni etiquetas " .. tostring(why or ""))
check(#badNames == 0, "nombres en español, ancladas, sin marcas ni cosas de otros juegos " .. table.concat(badNames, ", "))

local grunge = 0
for i, list in library do
	if P.Rules[i].Asset == "MueblesGrunge" then
		grunge += #list
	end
end
check(grunge == 5, "del pack de muebles solo cocina/salón/dormitorio (sin huesos, Drácula ni StarterCharacter): " .. grunge)
check(#(index["PlatoComida/OnTop"] or {}) == 2, "pack de comida: fuera la lata con marca (quedan 2 platos)")
local cat = (index["ComidaGato/OnTop"] or {})[1]
local catOk = cat ~= nil
if cat then
	for _, d in cat.Model:GetDescendants() do
		if d:IsA("SpecialMesh") and string.find(d.TextureId, "52081598") then
			catOk = false
		end
		if d:IsA("TextLabel") and not string.find(d.Text, "KESTREL") then
			catOk = false
		end
	end
	catOk = catOk and cat.Model:FindFirstChild("Etiqueta", true) ~= nil
end
check(catOk, "comida de gato: sin la textura con marca y con la marca inventada KESTREL")
local tv = (index["TeleAntigua/OnTop"] or {})[1]
check(tv and math.max(tv.Size.X, tv.Size.Y, tv.Size.Z) <= 2.61, "la tele (50 studs) se escala a una tele de verdad")
local shelf = (index["EstanteriaAlmacen/Floor"] or {})[1]
print("    estantería", shelf and shelf.Size)
check(shelf and math.abs(shelf.Size.Y - 13) < 0.01 and shelf.Size.Z < 20, "estantería de almacén: un solo tramo, 13 de alto")
local chimney = (index["ChimeneaIndustrial/NaveReplace"] or {})[1]
check(chimney and #chimney.Model:GetChildren() == 1, "chimenea: la más alta del pack industrial")
check(#(index["DepositoIndustrial/NaveSide"] or {}) == 4, "depósitos: los 4 bajos (sin la torre ni la chimenea)")

local store = Instance.new("Folder")
check(P.store(library, store) == 1 and store:FindFirstChild("ModelosPremio"):FindFirstChild("CofreRecompensa") ~= nil, "cofre de recompensa guardado para el pase y los premios")

---------------------------------------------------------------------
print("En las salas de World/Interiors")
---------------------------------------------------------------------
local rooms = Instance.new("Folder")
rooms.Name = "Interiores"
rooms.Parent = World
local slot = 0
local function build(kind: string, shop: string?, seed: string?): Instance
	slot += 1
	local r = Interiors[kind](rooms, CFrame.new(slot * 300, 5000, 0), { Seed = seed or ("prueba" .. slot), Shop = shop })
	r.Model:SetAttribute("Key", seed or ("prueba" .. slot))
	return r.Model
end

local function props(room: Instance): { Model }
	local f = room:FindFirstChild(P.Folder)
	local out = {}
	for _, m in (if f then f:GetChildren() else {}) do
		table.insert(out, m)
	end
	return out
end
local function count(room: Instance, name: string): number
	local n = 0
	for _, m in props(room) do
		if m.Name == name then
			n += 1
		end
	end
	return n
end

-- ¿Dentro de la sala, apoyado y sin chocar con lo de antes?
local function placementOk(room: Instance, m: Model): (boolean, string?)
	local floor = room:FindFirstChild("Floor") :: BasePart
	local flo, fhi = P.bounds({ floor })
	local parts = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
		end
	end
	local lo, hi = P.bounds(parts)
	if lo.X < flo.X - 0.01 or hi.X > fhi.X + 0.01 or lo.Z < flo.Z - 0.01 or hi.Z > fhi.Z + 0.01 then
		return false, "fuera de la sala"
	end
	if lo.Y < fhi.Y - 0.05 then
		return false, "se hunde en el suelo"
	end
	return true, nil
end

local all: { Instance } = {}
local function dress(room: Instance): number
	table.insert(all, room)
	return P.dressRoom(room, library, overlap)
end

-- Casas: varias semillas (las reglas con Chance salen en unas sí y en otras no)
local houses = {}
for k = 1, 6 do
	local kind = ({ "Casa", "Villa", "Piso" })[(k - 1) % 3 + 1]
	local room = build(kind, nil, "casa" .. k)
	dress(room)
	table.insert(houses, room)
end
local casa, villa = houses[1], houses[2]
local pillows, shells = 0, 0
for _, d in casa:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "Pillow" then
		pillows += 1
		if d:HasTag("PropShell") and d.Transparency == 1 and d:GetAttribute("ShellTransparency") == 0 then
			shells += 1
		end
	end
end
check(pillows > 0 and shells == pillows and count(casa, "Almohada") == pillows, ("almohadas de malla en lugar de las de antes (%d)"):format(pillows))
local exit = casa:FindFirstChild("InteriorExit") :: BasePart
check(exit and exit:HasTag("PropShell") and exit:HasTag("InteriorExit") and exit.CanCollide and count(casa, "PuertaMadera") == 1, "puerta de madera en la salida (la de antes sigue siendo la salida)")
local door = nil
for _, m in props(casa) do
	if m.Name == "PuertaMadera" then
		door = m
	end
end
if door then
	local lo, hi = P.bounds({ door:FindFirstChildWhichIsA("BasePart") })
	local a, b = P.bounds({ exit })
	check((lo - a).Magnitude < 0.05 and (hi - b).Magnitude < 0.05, "la puerta ocupa justo el hueco de la salida")
end
local toilet = casa:FindFirstChild("Toilet", true)
local seat = toilet and toilet:FindFirstChildWhichIsA("Seat")
check(count(casa, "Vater") == 1 and seat and not seat:HasTag("PropShell") and seat:HasTag("Interact") and toilet:FindFirstChild("ToiletBowl"):HasTag("PropShell"), "váter de malla (el asiento de antes se sigue usando)")
check(count(villa, "AlfombraPersa") == 1, "alfombra persa en la villa")
local floorItems, floorBad = 0, {}
for _, room in houses do
	for _, m in props(room) do
		local ok, w = placementOk(room, m)
		if not ok and m.Name ~= "PuertaMadera" then
			table.insert(floorBad, m.Name .. ": " .. tostring(w))
		end
		if m.Name == "Mueble" or m.Name == "Aparador" or m.Name == "Consola" or m.Name == "Armario" or m.Name == "SillonCuadros" or m.Name == "ComodaHotel" then
			floorItems += 1
		end
	end
end
check(floorItems > 0, ("muebles de pie en las casas (%d)"):format(floorItems))
check(#floorBad == 0, "todo dentro de la sala y apoyado " .. table.concat(floorBad, "; "))
-- Los muebles de pie son sólidos: el personaje no se mete dentro (caja invisible de su tamaño)
local solidAll, solidCount = true, 0
for _, room in houses do
	for _, m in props(room) do
		if m.Name == "Mueble" or m.Name == "Aparador" or m.Name == "Consola" or m.Name == "Armario" or m.Name == "SillonCuadros" or m.Name == "ComodaHotel" then
			local box = m:FindFirstChild(P.HitboxName)
			local lo, hi = P.bounds(m:GetChildren())
			local tall = (hi - lo).Y
			if box and box:IsA("BasePart") and box.CanCollide and box.Transparency == 1 and math.abs(box.Size.Y - tall) < 0.2 then
				solidCount += 1
			elseif tall >= 2 then
				solidAll = false
			end
		end
	end
end
check(solidAll and solidCount > 0, ("los muebles de pie añadidos son sólidos (no se atraviesan): %d"):format(solidCount))
do
	-- Un mueble hecho de piezas pequeñas y escalado a su talla choca (antes se decidía con la talla del asset)
	local tiny = Instance.new("Model")
	for k = 0, 3 do
		local p = Instance.new("Part")
		p.Size = V(1, 0.4, 0.5)
		p.CFrame = CFrame.new(0, 0.2 + k * 0.4, 0)
		p.Parent = tiny
	end
	local t = P.clean(tiny, "ArmarioPrueba", { Fit = { Height = 7 } })
	local solid = t ~= nil
	for _, p in (if t then t.Model:GetChildren() else {}) do
		if p:IsA("BasePart") and not p.CanCollide then
			solid = false
		end
	end
	check(solid, "un mueble de piezas pequeñas escalado a 7 studs choca")
end

-- Lo añadido de pie no choca con los muebles de antes ni tapa la entrada
local function overlapsOld(room: Instance, m: Model): boolean
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide then
			local lo, hi = P.bounds({ p })
			local box = Instance.new("Part")
			box.Size = (hi - lo) - V(0.2, 0.2, 0.2)
			box.CFrame = CFrame.new((lo + hi) / 2)
			for _, q in overlap(box.CFrame, box.Size, room) do
				local inMine = false
				local node = q.Parent
				while node do
					if node == m then
						inMine = true
					end
					node = node.Parent
				end
				local _, qhi = P.bounds({ q })
				local flo = room:FindFirstChild("Floor") :: BasePart
				local _, fhi = P.bounds({ flo })
				if not inMine and q.Name ~= "Floor" and qhi.Y > fhi.Y + 0.35 then
					return true
				end
			end
		end
	end
	return false
end
local crash = {}
for _, room in houses do
	for _, m in props(room) do
		if m.Name ~= "Almohada" and m.Name ~= "Vater" and m.Name ~= "PuertaMadera" and m.Name ~= "AlfombraPersa" and overlapsOld(room, m) then
			table.insert(crash, m.Name)
		end
	end
end
check(#crash == 0, "los muebles nuevos no se meten en los de antes " .. table.concat(crash, ", "))
local entryClear = true
for _, room in houses do
	local entry = room:FindFirstChild("InteriorEntry") :: BasePart
	for _, m in props(room) do
		local p = m:FindFirstChildWhichIsA("BasePart")
		if p and p.CanCollide and (p.CFrame.Position - entry.CFrame.Position).Magnitude < 3 then
			entryClear = false
		end
	end
end
check(entryClear, "la entrada queda libre")

-- Tags del nivel Bajo
local tagged, solid = true, false
for _, m in props(casa) do
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			tagged = tagged and p:HasTag("DecorProp")
			solid = solid or p:GetAttribute("Solid") == true
		end
	end
end
check(tagged, "todo lo añadido lleva DecorProp (el nivel Bajo lo esconde)")

-- Tiendas y restaurantes
local function shopRoom(shop: string): Instance
	local room = build("Local", shop)
	dress(room)
	return room
end
local pet = shopRoom("MASCOTAS")
check(count(pet, "ComidaGato") >= 1, ("comida de gato KESTREL en la tienda de mascotas (%d)"):format(count(pet, "ComidaGato")))
local bank = shopRoom("BANCO")
check(count(bank, "FajosBilletes") == 1, "fajos de billetes en el mostrador del banco")
local fajos = props(bank)[1]
for _, m in props(bank) do
	if m.Name == "FajosBilletes" then
		fajos = m
	end
end
local counterTop = bank:FindFirstChild("CounterTop", true) :: BasePart
local _, ctHi = P.bounds({ counterTop })
local flo = P.bounds({ fajos:FindFirstChildWhichIsA("BasePart") })
local lowest = math.huge
for _, p in fajos:GetDescendants() do
	if p:IsA("BasePart") then
		local a = P.bounds({ p })
		lowest = math.min(lowest, a.Y)
	end
end
check(math.abs(lowest - ctHi.Y) < 0.05, "los fajos están apoyados en el mostrador")
local sushi = shopRoom("SUSHI")
check(count(sushi, "Ramen") >= 1 and count(sushi, "Bonsai") == 1, ("ramen en las mesas y bonsái en la barra del sushi (%d ramen)"):format(count(sushi, "Ramen")))
check(count(shopRoom("BAR"), "PlatoComida") >= 1, "platos en las mesas del bar")
check(count(shopRoom("KEBAB"), "PinchoCallejero") >= 1, "pinchos en la barra del kebab")
check(count(shopRoom("PANADERIA"), "Magdalena") >= 1, "magdalenas en la panadería")
check(count(shopRoom("JUGUETERIA"), "CofreRecompensa") == 1, "cofre en la juguetería")
local furniture = shopRoom("MUEBLES")
check(count(furniture, "SillaGigante") == 0, "la silla gigante no cargó: la tienda de muebles sigue igual, sin error")
local nave = build("Nave")
dress(nave)
check(count(nave, "EstanteriaAlmacen") >= 1, ("estantería de almacén en la nave (%d)"):format(count(nave, "EstanteriaAlmacen")))
local office = build("Oficina")
dress(office)
check(count(office, "Portapapeles") >= 1, "portapapeles en los escritorios de la oficina")
local cuartel = build("Cuartel")
dress(cuartel)
check(count(cuartel, "Portapapeles") + count(cuartel, "Taquillas") + count(cuartel, "Extintor") >= 1, "cosas en el cuartel")
local bad2 = {}
for _, room in all do
	for _, m in props(room) do
		local ok, w = placementOk(room, m)
		if not ok and m.Name ~= "PuertaMadera" then
			table.insert(bad2, room.Name .. "/" .. m.Name .. ": " .. tostring(w))
		end
	end
end
check(#bad2 == 0, "en todas las salas: dentro y apoyado " .. table.concat(bad2, "; "))
check(P.dressRoom(casa, library, overlap) == 0, "una sala ya amueblada no se vuelve a amueblar")
-- Frutería: cada caja tiene su fruta o verdura (shared/Groceries) para comprarla ahí mismo, con su forma
-- (no bolas lisas iguales) y su cartel de precio
do
	local fruteria = build("Local", "FRUTERIA LA HUERTA", "fruteria1")
	local crates, products, shapes, cards, round = 0, {}, 0, 0, 0
	for _, d in fruteria:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("ProduceCrate") then
			crates += 1
			products[d:GetAttribute("Product")] = true
			local g = d.Parent
			local fruit = g and g:FindFirstChild("Fruta")
			for _, f in (if fruit then fruit:GetDescendants() else {}) do
				if f:IsA("BasePart") then
					shapes += 1
					if f:FindFirstChildOfClass("SpecialMesh") or f.Name == "Platano" or f.Name == "Uva" or f.Name == "Zanahoria" then
						round += 1
					end
				end
			end
			local card = g and g:FindFirstChild("Precio")
			if card and card:FindFirstChildOfClass("SurfaceGui") then
				cards += 1
			end
		end
	end
	local distinct = 0
	for _ in products do
		distinct += 1
	end
	check(crates == 8 and distinct == 8, ("frutería: 8 cajas, cada una con su producto (%d cajas, %d productos)"):format(crates, distinct))
	check(shapes >= 8 * 8 and round >= shapes * 0.4, ("la fruta tiene forma (manzanas, racimos, sandías…), no bolas lisas: %d piezas"):format(shapes))
	check(cards == 8, "cada caja con su cartel de precio")
end
-- Los muebles grandes de las salas chocan: ningún mueble de pie (mesa, estantería, armario, nevera,
-- cama, sofá…) es todo de piezas que se atraviesan. Lo pequeño y fino (lámparas de pie, percheros,
-- taburetes, toalleros, ventanas) puede no chocar, para no quedarse enganchado.
do
	local THIN = { Window = true, FloorLamp = true, CoatRack = true, Stool = true, TowelRail = true, Plant = true, Lamp = true }
	local ghosts = {}
	for _, kind in { "Casa", "Villa", "Piso", "Dorm", "Oficina", "Ocio", "Taller", "Nave", "Aula", "Museo", "CentroComercial", "Estacion" } do
		local room = build(kind, nil, "solido" .. kind)
		for _, m in room:GetDescendants() do
			if m:IsA("Model") and not THIN[m.Name] and m.Name ~= P.Folder then
				local parts, solid = {}, false
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						if d.CanCollide then
							solid = true
						end
						if d.Transparency < 1 then
							table.insert(parts, d)
						end
					end
				end
				if #parts > 0 and not solid then
					local lo, hi = P.bounds(parts)
					local size = hi - lo
					-- (de pie en el suelo: lo de la pared y el techo no estorba al andar)
					if size.Y >= 1.5 and math.max(size.X, size.Z) >= 1.5 and lo.Y < 5001.5 then
						ghosts[kind .. "/" .. m.Name] = true
					end
				end
			end
		end
	end
	for _, shop in { "Ropa", "Supermercado", "Farmacia" } do
		local ok, room = pcall(build, "Local", shop)
		if ok then
			for _, m in room:GetDescendants() do
				if m:IsA("Model") and m.Name == "ShopShelf" then
					local solid = false
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") and d.CanCollide then
							solid = true
						end
					end
					if not solid then
						ghosts["Local " .. shop .. "/ShopShelf"] = true
					end
				end
			end
		end
	end
	local names = {}
	for k in ghosts do
		table.insert(names, k)
	end
	table.sort(names)
	check(#names == 0, "los muebles grandes chocan (no se atraviesan) " .. table.concat(names, ", "))
end

---------------------------------------------------------------------
print("En la ciudad")
---------------------------------------------------------------------
local town = Instance.new("Model")
town.Name = "Town"
town.Parent = World
local nm = Instance.new("Model")
nm.Name = "Nave"
nm.Parent = town
local hall = Instance.new("Part")
hall.Name = "Hall"
hall.Size = V(100, 20, 80)
hall.CFrame = CFrame.new(0, 10, 0)
hall.Parent = nm
local chim = Instance.new("Part")
chim.Name = "Chimney"
chim.Shape = roblox.Enum.PartType.Cylinder
chim.Size = V(42, 4, 4)
chim.CFrame = CFrame.new(40, 21, 30) * CFrame.Angles(0, 0, math.rad(90))
chim.Parent = nm
local hospital = Instance.new("Model")
hospital.Name = "Hospital"
hospital.Parent = town
local desk = Instance.new("Part")
desk.Name = "Desk"
desk.Size = V(3.6, 3, 2.2)
desk.CFrame = CFrame.new(300, 1.5, 0)
desk:AddTag("ClinicDesk")
desk.Parent = hospital
local nurse = Instance.new("Part")
nurse.Name = "NurseDesk"
nurse.Size = V(8, 3.6, 2.4)
nurse.CFrame = CFrame.new(320, 1.8, 0)
nurse.Parent = hospital
local n = P.dressTown(town, library, overlap, function(tag)
	return if tag == "ClinicDesk" then { desk } else {}
end)
check(n >= 4, ("cosas en la ciudad (%d)"):format(n))
check(chim:HasTag("PropShell") and nm:FindFirstChild(P.Folder):FindFirstChild("ChimeneaIndustrial") ~= nil, "chimenea de malla en la nave")
local chimMesh = nm:FindFirstChild(P.Folder):FindFirstChild("ChimeneaIndustrial")
if chimMesh then
	local lo, hi = P.bounds({ chimMesh:FindFirstChildWhichIsA("BasePart") })
	check(math.abs(lo.Y - 0) < 0.05 and math.abs(hi.Y - 42) < 0.05, "la chimenea mide lo mismo que la de antes, desde el suelo")
end
check(nm:FindFirstChild(P.Folder):FindFirstChild("DepositoIndustrial") ~= nil, "depósito al lado de la nave")
check(hospital:FindFirstChild(P.Folder) and #hospital:FindFirstChild(P.Folder):GetChildren() == 2, "portapapeles en la consulta y en el control de enfermería")

---------------------------------------------------------------------
print("Si no carga nada")
---------------------------------------------------------------------
local empty = P.prepare(function()
	error("HTTP 403")
end, MeshLibrary.stripScripts)
check(next(empty) == nil, "sin assets: ninguna plantilla y sin error")
local plain = build("Casa")
local before = #plain:GetDescendants()
check(P.dressRoom(plain, empty, overlap) == 0, "la sala no cambia")
check(P.dressTown(town, empty, overlap) == 0, "la ciudad no cambia")
local broken = P.prepare(function(id)
	if id == 991205683 then
		return nil
	end
	return load(id)
end, MeshLibrary.stripScripts)
check(broken ~= nil and next(broken) ~= nil, "si falla un asset, los demás siguen")
local _ = before

L.finish("test-interiorprops")
