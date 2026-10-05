-- Prueba de la casa familiar y de la leyenda del mapa FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-familyhome.luau
--
-- Comprueba:
--   * Family.chooseHome: casa libre al azar la primera vez; la misma al volver a entrar; otra libre
--     si la guardada ya no existe o vive en ella otro jugador; con todo lleno, la guardada o la menos llena
--   * Family.household: en todas las casas viven Papá, Mamá y la abuela (y la pareja de la historia)
--   * BabyService con las casas de verdad (World/Kit/Home): todos tienen casa (también los adultos),
--     se guarda, se conserva al volver, se cambia si no vale; la familia (NPC) está dentro de casa y de
--     noche lleva luz; FamilyHomePos para el 🏠 de los mapas
--   * SleepService: la cama de la casa familiar deja dormir a quien vive allí (y a nadie más)
--   * HomeMapService: casa propia de un adulto (la que eligió) y nada para un niño; filtros guardados
--   * MapLegend: categorías sin repetir, cada tipo en una sola, «🏋️ Gimnasios (7)», ocultar una
--     categoría oculta TODOS sus lugares y mostrarla los devuelve; 🏠 Casa siempre, sin filtros

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")
local check = L.check

local Vector3, CFrame = roblox.Vector3, roblox.CFrame

-- Señales de mentira (Lune no tiene eventos)
local function signal()
	local s = { Handlers = {} }
	function s:Connect(fn)
		table.insert(self.Handlers, fn)
		return { Disconnect = function() end }
	end
	function s:Fire(...)
		for _, fn in self.Handlers do
			fn(...)
		end
	end
	return s
end

-- Los ProximityPrompt de Lune no tienen eventos: los cambiamos por tablas que los apuntan
local prompts = {}
local realNew = roblox.Instance.new
L.fakeClasses.ProximityPrompt = function()
	local p = { ClassName = "ProximityPrompt", Triggered = signal() }
	table.insert(prompts, p)
	return p
end

local Family = L.load("src/shared/LifeStory/Family")
local MapInfo = L.load("src/shared/MapInfo")
local MapLegend = L.load("src/shared/MapLegend")

---------------------------------------------------------------------
print("\n▶ Family.chooseHome")
local ids = { "H1", "H2", "H3", "H4" }
local rng = L.Random.new(7)
local first, why = Family.chooseHome(ids, nil, {}, rng)
check(first ~= nil and table.find(ids, first) ~= nil and why == "New", ("La primera vez: una casa del mapa (%s, %s)"):format(tostring(first), why))
local again, why2 = Family.chooseHome(ids, first, {}, rng)
check(again == first and why2 == "Kept", "Al volver a entrar: la misma casa")
local seen = {}
for i = 1, 40 do
	seen[(Family.chooseHome(ids, nil, {}, L.Random.new(i)))] = true
end
local distinct = 0
for _ in seen do
	distinct += 1
end
check(distinct >= 3, ("Al azar: salen casas distintas (%d de 4)"):format(distinct))
local fixed, why3 = Family.chooseHome(ids, "Borrada", {}, rng)
check(fixed ~= "Borrada" and table.find(ids, fixed) ~= nil and why3 == "Invalid", "Casa guardada que ya no existe: otra libre")
local moved, why4 = Family.chooseHome(ids, "H2", { H2 = 1 }, rng)
check(moved ~= "H2" and why4 == "Taken", "Casa guardada donde vive otro jugador: otra libre")
local onlyFree = Family.chooseHome(ids, nil, { H1 = 1, H2 = 1, H4 = 2 }, rng)
check(onlyFree == "H3", "Nunca una ocupada si queda alguna libre")
local full, whyFull = Family.chooseHome(ids, "H1", { H1 = 1, H2 = 1, H3 = 1, H4 = 1 }, rng)
check(full == "H1" and whyFull == "Kept", "Todo lleno: se queda con la suya")
local least = Family.chooseHome(ids, nil, { H1 = 2, H2 = 1, H3 = 2, H4 = 3 }, rng)
check(least == "H2", "Todo lleno y sin casa: la menos llena")
check(Family.chooseHome({}, nil, {}, rng) == nil, "Sin casas en el mapa: nil (sin errores)")

print("\n▶ Family.household")
for index = 1, 4 do
	local names = {}
	for _, member in Family.household(index) do
		names[member.NameKey] = true
	end
	local familyKey, abuKey = Family.keysFor(index)
	check(names["NPC.PAPA"] and names["NPC.MAMA"] and names["NPC.ABU_ROSA"] and names[familyKey] and names[abuKey], ("Casa %d: Papá, Mamá, la abuela y la pareja de la historia"):format(index))
end

---------------------------------------------------------------------
print("\n▶ BabyService con las casas del mapa")
local Home = L.load("src/server/World/Kit/Home")
local town = realNew("Folder")
local homeModels = {}
for i = 1, 5 do
	table.insert(homeModels, Home.familyHouse(town, CFrame.new(i * 60, 0, 0), "Prueba_" .. i))
end

local notices = {}
local players = {}
local lighting = { ClockTime = 22 }
local remotesFolder = {
	Notify = { FireClient = function(_, player, kind, text)
		table.insert(notices, { Player = player, Kind = kind, Text = text })
	end },
}
L.services.Lighting = lighting
L.services.Players = {
	PlayerAdded = signal(),
	PlayerRemoving = signal(),
	GetPlayers = function()
		return players
	end,
	CreateHumanoidModelFromDescription = function()
		error("sin Roblox")
	end,
}
L.services.CollectionService = {
	AddTag = function(_, instance, tag)
		instance:AddTag(tag)
	end,
	GetTagged = function(_, tag)
		if tag == "FamilyHome" then
			local out = {}
			for _, model in homeModels do
				if model.Parent then
					table.insert(out, model)
				end
			end
			return out
		end
		return {}
	end,
	GetInstanceAddedSignal = function()
		return signal()
	end,
}
function remotesFolder:WaitForChild(name)
	return rawget(self, name)
end
L.services.ReplicatedStorage.Remotes = remotesFolder

local saves: { [number]: any } = {} -- partidas guardadas por UserId
local loaded: { [any]: any } = {}
L.mock("src/server/Services/DataService", {
	get = function(player)
		return loaded[player]
	end,
	onLoaded = function() end,
})
L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
L.mock("src/server/Services/NeedsService", { change = function() end })
L.mock("src/server/Services/CinematicService", { play = function()
	return 0
end })
L.mock("src/server/World/Npc", {
	dress = function() end,
	work = function() end,
	placeFeet = function(model, cf)
		local root = model:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = cf * CFrame.new(0, 2.5, 0)
		end
	end,
})
local BabyService = L.load("src/server/Services/BabyService")

local function join(userId: number, stage: string): any
	local player = L.player("P" .. userId, userId)
	player.Parent = true
	player.CharacterAdded = signal()
	saves[userId] = saves[userId] or { Life = {}, Story = { Flags = {}, Active = {} }, Hunger = 100 }
	loaded[player] = saves[userId]
	player:SetAttribute("LifeStage", stage)
	table.insert(players, player)
	BabyService.ensureFamily(player)
	return player
end
local function leave(player)
	local i = table.find(players, player)
	if i then
		table.remove(players, i)
	end
	player.Parent = nil
	loaded[player] = nil
	L.services.Players.PlayerRemoving:Fire(player) -- (sin init no hay quien escuche: se limpia a mano abajo)
end

local a = join(101, "Adulto")
local aHome = a:GetAttribute("FamilyHomeId")
check(type(aHome) == "string" and saves[101].Life.FamilyHomeId == aHome, ("Un adulto también tiene casa familiar, guardada (%s)"):format(tostring(aHome)))
check(typeof(a:GetAttribute("FamilyHomePos")) == "Vector3", "FamilyHomePos para el 🏠 de los mapas")
check(type(a:GetAttribute("FamilyKey")) == "string" and type(a:GetAttribute("AbuKey")) == "string", "Y los nombres de su familia")

-- La familia está en casa: Papá, Mamá y la abuela, dentro de la casa
local homeModel
for _, model in homeModels do
	if model:GetAttribute("HomeId") == aHome then
		homeModel = model
	end
end
local function insideRoom(model, position, roomName): boolean
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("Room") and d:GetAttribute("Room") == roomName then
			local rel = d.CFrame:PointToObjectSpace(position)
			if math.abs(rel.X) <= d.Size.X / 2 and math.abs(rel.Z) <= d.Size.Z / 2 then
				return true
			end
		end
	end
	return false
end
local Strings = L.load("src/shared/LifeStory/Strings")
local found = {}
local lightsOn = 0
for _, child in homeModel:GetChildren() do
	if child:IsA("Model") and child:HasTag("StaticNpc") then
		found[child.Name] = child
		local root = child:FindFirstChild("HumanoidRootPart")
		local glow = root and root:FindFirstChild("HomeGlow")
		if glow and glow.Enabled then
			lightsOn += 1
		end
	end
end
local papa, mama, abuela = found[Strings.get("NPC.PAPA")], found[Strings.get("NPC.MAMA")], found[Strings.get("NPC.ABU_ROSA")]
check(papa ~= nil and mama ~= nil and abuela ~= nil, "La familia (NPC) está en casa: Papá, Mamá y la abuela")
local inHouse = true
for _, npc in { papa, mama, abuela } do
	local root = npc and npc:FindFirstChild("HumanoidRootPart")
	local at = root and root.CFrame.Position
	if not at or not (insideRoom(homeModel, at, "Salon") or insideRoom(homeModel, at, "Cocina") or insideRoom(homeModel, at, "Dormitorio")) then
		inHouse = false
	end
end
check(inHouse, "Todos dentro de una habitación de la casa (salón o cocina)")
check(lightsOn >= 3, ("De noche llevan su luz encendida (%d)"):format(lightsOn))
local talkPrompts = 0
for _, p in prompts do
	if p.ActionText == Strings.get("BABY.PROMPT.TALK") then
		talkPrompts += 1
	end
end
check(talkPrompts >= 3, ("Se puede hablar con cada uno (%d avisos)"):format(talkPrompts))

-- Volver a entrar: la misma casa
leave(a)
local a2 = join(101, "Adulto")
check(a2:GetAttribute("FamilyHomeId") == aHome, "Al volver a entrar: la misma casa familiar")
-- Reaparecer (la comprobación de cada vez): sigue igual
BabyService.ensureFamily(a2)
check(a2:GetAttribute("FamilyHomeId") == aHome and saves[101].Life.FamilyHomeId == aHome, "Al reaparecer: sigue siendo la misma")

-- Otro jugador con la misma casa guardada (de otro servidor): le toca otra libre
saves[202] = { Life = { FamilyHomeId = aHome }, Story = { Flags = {}, Active = {} }, Hunger = 100 }
local b = join(202, "Nino")
local bHome = b:GetAttribute("FamilyHomeId")
check(bHome ~= nil and bHome ~= aHome and saves[202].Life.FamilyHomeId == bHome, "Si ya vive otro jugador en tu casa guardada, te toca otra libre (y se guarda)")
local warned = false
for _, n in notices do
	if n.Player == b and string.find(n.Text, "Casa", 1, true) then
		warned = true
	end
end
check(warned, "Y se le avisa (sale en el mapa como 🏠 Casa)")

-- Casa borrada del mapa: se reasigna sola
for _, model in homeModels do
	if model:GetAttribute("HomeId") == bHome then
		model.Parent = nil
	end
end
BabyService.ensureFamily(b)
local bNew = b:GetAttribute("FamilyHomeId")
check(bNew ~= nil and bNew ~= bHome and bNew ~= aHome, "Casa guardada que ya no existe: otra libre, sola")
check(saves[202].Life.FamilyHomeId == bNew, "La nueva queda guardada")

-- Vida nueva (partida sin casa guardada): nace con una casa libre
saves[303] = { Life = {}, Story = { Flags = {}, Active = {} }, Hunger = 100 }
local c = join(303, "Nino")
check(c:GetAttribute("FamilyHomeId") ~= nil and c:GetAttribute("FamilyHomeId") ~= aHome and c:GetAttribute("FamilyHomeId") ~= bNew, "Vida nueva: le toca una casa libre")

---------------------------------------------------------------------
print("\n▶ Dormir en la cama de casa")
local sleptBy = {}
L.mock("src/server/Services/ProgressionService", {})
local storyBeds = {}
for _, model in homeModels do
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("StoryProp") then
			table.insert(storyBeds, d)
		end
	end
end
L.services.CollectionService.GetTagged = function(_, tag)
	return if tag == "StoryProp" then storyBeds else {}
end
L.services.ReplicatedStorage.WaitForChild = function(self, name)
	return rawget(self, name)
end
L.mock("src/server/Services/DataService", { get = function(player)
	return loaded[player]
end, onLoaded = function() end })
L.reset("src/server/Services/SleepService")
local SleepService = L.load("src/server/Services/SleepService")
SleepService.sleep = function(player)
	table.insert(sleptBy, player)
end
local okInit, initErr = pcall(SleepService.init)
check(okInit, "SleepService arranca" .. (if okInit then "" else (": " .. tostring(initErr))))
local myBed
for _, bed in storyBeds do
	if bed:GetAttribute("PropId") == "Cama" and bed:GetAttribute("HomeId") == aHome then
		myBed = bed
	end
end
check(myBed ~= nil, "La casa familiar tiene su cama")
local bedPrompt
for _, p in prompts do
	if p.Parent == myBed and p.ActionText == "Dormir" then
		bedPrompt = p
	end
end
check(bedPrompt ~= nil, "La cama tiene «Dormir»")
if bedPrompt then
	bedPrompt.Triggered:Fire(a2)
	task.wait()
	check(table.find(sleptBy, a2) ~= nil, "Quien vive allí duerme en ella")
	bedPrompt.Triggered:Fire(c)
	task.wait()
	check(table.find(sleptBy, c) == nil, "Otro jugador no («Esta cama no es tuya»)")
end

---------------------------------------------------------------------
print("\n▶ HomeMapService: tu casa propia")
L.mock("src/server/Services/InteriorService", {
	byKey = function(key)
		if key == "Piso_1" then
			return { Key = key, Door = Vector3.new(500, 0, 20), Title = "Bloque 1" }
		elseif key == "Piso_2" then
			return { Key = key, Door = Vector3.new(800, 0, 40), Title = "Bloque 2" }
		end
		return nil
	end,
})
local filtersSaved = {}
L.mock("src/server/Services/DataService", { get = function(player)
	return loaded[player]
end, onLoaded = function() end })
local HomeMap = L.load("src/server/Services/HomeMapService")
saves[101].Properties = { { Key = "Piso_1", Floor = 1, Letter = "A", Title = "Piso 1ºA" }, { Key = "Piso_2", Floor = 2, Letter = "B", Title = "Casa nueva" } }
saves[101].Housing = { Home = { Key = "Piso_2", Floor = 2, Letter = "B" } }
HomeMap.refresh(a2)
check(a2:GetAttribute("OwnHomePos") == Vector3.new(800, 0, 40), "Adulto: su casa es la que eligió (se actualiza al mudarse)")
local markers = MapLegend.homeMarkers(a2:GetAttribute("FamilyHomePos"), a2:GetAttribute("OwnHomePos"))
check(#markers == 2 and markers[1].Name == "Casa" and markers[2].Name == "Casa familiar", "En el mapa: 🏠 Casa (la suya) y 🏠 Casa familiar")
saves[101].Housing = { Home = { Key = "Piso_1", Floor = 1, Letter = "A" } }
HomeMap.refresh(a2)
check(a2:GetAttribute("OwnHomePos") == Vector3.new(500, 0, 20), "Se muda: el 🏠 Casa cambia de sitio")
HomeMap.refresh(b)
check(b:GetAttribute("OwnHomePos") == nil, "Un niño no tiene casa propia: su 🏠 Casa es la de su familia")
local kid = MapLegend.homeMarkers(b:GetAttribute("FamilyHomePos"), b:GetAttribute("OwnHomePos"))
check(#kid == 1 and kid[1].Name == "Casa" and kid[1].Family, "Niño: un solo 🏠 Casa, en la casa familiar")
HomeMap.setFilters(a2, "Gimnasios,NoExiste,Hoteles")
check(a2:GetAttribute("MapHidden") == "Gimnasios,Hoteles" and saves[101].MapHidden == "Gimnasios,Hoteles", "Filtros: se guardan con la partida (solo categorías que existen)")
_ = filtersSaved

---------------------------------------------------------------------
print("\n▶ MapLegend")
local names, idsSeen, dupes = {}, {}, {}
for _, category in MapLegend.Categories do
	if names[category.Name] or idsSeen[category.Id] then
		table.insert(dupes, category.Name)
	end
	names[category.Name] = true
	idsSeen[category.Id] = true
end
check(#dupes == 0, "Ninguna categoría repetida")
local owners: { [string]: number } = {}
for _, category in MapLegend.Categories do
	for _, model in category.Models do
		owners[model] = (owners[model] or 0) + 1
	end
end
local loose, twice = {}, {}
for _, kind in MapInfo.Kinds do
	if not owners[kind.Model] then
		table.insert(loose, kind.Model)
	elseif owners[kind.Model] > 1 then
		table.insert(twice, kind.Model)
	end
end
check(#loose == 0, "Cada tipo de lugar está en una categoría" .. (if #loose > 0 then (": faltan " .. table.concat(loose, ", ")) else ""))
check(#twice == 0, "Y en una sola" .. (if #twice > 0 then (": " .. table.concat(twice, ", ")) else ""))
local unknown = {}
for model in owners do
	if MapInfo.KindByModel[model] == nil then
		table.insert(unknown, model)
	end
end
check(#unknown == 0, "Las categorías solo usan tipos que existen" .. (if #unknown > 0 then (": " .. table.concat(unknown, ", ")) else ""))

-- Un mapa con lugares repetidos: 5 gimnasios grandes + 2 de barrio, 3 supermercados, 4 bares, 1 restaurante…
local map = {}
local function add(model, n)
	for _ = 1, n do
		table.insert(map, model)
	end
end
add("GimnasioValmar", 5)
add("LocalGimnasio", 2)
add("Supermercado", 3)
add("LocalComida", 4)
add("Restaurante", 1)
add("LocalRopa", 6)
add("Gasolinera", 2)
add("Hospital", 1)
local summary = MapLegend.summary(map)
local byId = {}
local titles = {}
for _, entry in summary do
	check(byId[entry.Category.Id] == nil, "Una sola fila para " .. entry.Category.Name)
	byId[entry.Category.Id] = entry.Count
	titles[entry.Category.Id] = MapLegend.title(entry.Category, entry.Count)
end
check(byId.Gimnasios == 7 and titles.Gimnasios == "🏋️ Gimnasios (7)", "«🏋️ Gimnasios (7)»: todos los gimnasios juntos, con icono y número")
check(byId.Supermercados == 3 and byId.Restaurantes == 5 and byId.Ropa == 6 and byId.Gasolineras == 2, "Supermercados (3), Restaurantes y bares (5), Tiendas de ropa (6), Gasolineras (2)")
check(byId.Hoteles == nil, "Las categorías sin ningún lugar no salen")

-- Ocultar y mostrar: todos los marcadores de la categoría a la vez (como hace MapUI en los dos mapas)
local hidden = {}
local function visibleCount(model)
	local n = 0
	for _, m in map do
		if m == model and MapLegend.visible(hidden, m) then
			n += 1
		end
	end
	return n
end
check(MapLegend.toggle(hidden, "Gimnasios") == true, "Tocar «Gimnasios» la oculta")
check(visibleCount("GimnasioValmar") == 0 and visibleCount("LocalGimnasio") == 0, "Se ocultan TODOS los gimnasios (los grandes y los de barrio)")
check(visibleCount("Supermercado") == 3, "Las demás categorías siguen a la vista")
check(MapLegend.toggle(hidden, "Gimnasios") == false and visibleCount("GimnasioValmar") == 5 and visibleCount("LocalGimnasio") == 2, "Tocar otra vez: vuelven todos")
local saved = MapLegend.encode({ Ropa = true, Gimnasios = true })
local back = MapLegend.decode(saved)
check(back.Ropa and back.Gimnasios and not back.Hoteles, "Guardar y cargar los filtros («" .. saved .. "»)")
check(next(MapLegend.decode("Inventada,,")) == nil and next(MapLegend.decode(nil)) == nil, "Lo que no es una categoría no se carga")

-- 🏠 Casa: siempre, aunque se oculte todo
MapLegend.setAll(hidden, true)
local anyVisible = false
for _, m in map do
	if MapLegend.visible(hidden, m) then
		anyVisible = true
	end
end
check(not anyVisible, "«Ocultar todo» oculta todas las categorías")
local homes = MapLegend.homeMarkers(Vector3.new(10, 0, 10), nil)
check(#homes == 1 and homes[1].Icon == "🏠" and homes[1].Name == "Casa", "Con todos los filtros quitados, el 🏠 Casa sigue ahí")
check(MapLegend.categoryOf("Casa") == nil, "Casa no es una categoría: no se puede ocultar")
check(#MapLegend.homeMarkers(nil, nil) == 0, "Sin casa todavía: sin 🏠 (y sin errores)")
local same = MapLegend.homeMarkers(Vector3.new(10, 0, 10), Vector3.new(15, 0, 12))
check(#same == 1 and same[1].Name == "Casa", "Si las dos casas son la misma, un solo 🏠 Casa")
MapLegend.setAll(hidden, false)
check(next(hidden) == nil, "«Mostrar todo» las devuelve todas")

L.finish("Casa familiar y leyenda del mapa")
