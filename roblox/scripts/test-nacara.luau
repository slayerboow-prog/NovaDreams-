-- Prueba de la plaza de prueba de Nácara (fase 0, docs/mar/civilizacion-marina.md), FUERA de Roblox,
-- con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-nacara.luau
--
-- Comprueba:
--   * el sitio: Llanura Sumergida a la entrada del Cañón de las Catedrales, suelo a 37–47 m, dentro del
--     mar que se construye, lejos de puertos, islas, playas, del territorio del megalodón (y de su ronda),
--     de la sima, del cañón y de las agujas; sin pisar ningún sitio del mar (POI) ni sus piezas, ni los
--     recursos del fondo; todo ≥ 20 studs bajo la superficie (los barcos pasan por encima)
--   * que lo de la plaza no se pisa entre sí y cabe en la plaza
--   * World/NacaraBuilder: terreno (allanado + burbuja de Aire de la cúpula), modelos Atomic, piezas y
--     luces dentro del presupuesto, materiales que no cambia UserMaterials, la cúpula con SeaAirPocket
--   * la cúpula de aire: dentro se respira (DivingService.inPocket de verdad y Diving.tick: el aire sube
--     y la presión no hace daño) y se anda (Swimming y AgeMotion no nadan dentro)
--   * Services/NacaraService: 8 Hondarios con cola, cresta y peto; Ilun y Oriana con «Hablar»; la charla
--     empieza (DialogueService.play) y no lleva efectos, premios ni guardado; el punto del mapa
--   * la ruta de buceo: del jardín de coral más cercano a la plaza, siempre en el agua; la corriente
--     guía empuja hacia la plaza; las perlas de guía
--   * la luz de la ciudad (Nacara.lookNear) y los topes del cliente (Controllers/NacaraLife)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check

local Ocean = L.load("src/shared/Sea/Ocean")
local Nacara = L.load("src/shared/Sea/Nacara")
local Diving = L.load("src/shared/Sea/Diving")

local function meters(y: number): number
	return (Ocean.Surface - y) / Ocean.StudsPerMeter
end
local C = Nacara.Center

---------------------------------------------------------------------
print("▶ El sitio de la plaza")
do
	local s = Ocean.sample(C.X, C.Z)
	check(s.Zone == "Llanura", ("En la Llanura Sumergida (zona: %s)"):format(tostring(s.Zone)))
	local m = Nacara.depthMeters()
	check(m >= 37 and m <= 47, ("El suelo de la plaza a %.1f m (la capital va a 37–47 m)"):format(m))
	check(Ocean.inArea(C.X - Nacara.Clear, C.Z - Nacara.Clear) and Ocean.inArea(C.X + Nacara.Clear, C.Z + Nacara.Clear), "Dentro del mar que construye OceanBuilder")
	-- a la entrada del Cañón de las Catedrales: el cañón empieza a menos de 400 studs y la plaza no lo toca
	local dist = Ocean.along(Ocean.Cathedrals, C.X, C.Z)
	check(dist < 450 and dist > Ocean.Cathedrals.HalfWidth + Ocean.Cathedrals.Wall + Nacara.Clear, ("A la entrada del Cañón de las Catedrales: su eje a %.0f studs, sin tocar sus paredes"):format(dist))
	-- todo el disco: mar, sin puertos/islas, sin cañones ni sima, fuera del abismo, lejos de la costa
	local ok, minLand, maxFloor, minFloor = true, math.huge, -math.huge, math.huge
	for dx = -Nacara.Clear, Nacara.Clear, 6 do
		for dz = -Nacara.Clear, Nacara.Clear, 6 do
			if dx * dx + dz * dz <= Nacara.Clear ^ 2 then
				local p = Ocean.sample(C.X + dx, C.Z + dz)
				if not p.Floor or p.Keep > 0 or p.Trench > 0 or p.Canyon > 0 or p.Cathedrals > 0 or p.Basin > 0 then
					ok = false
				end
				minLand = math.min(minLand, p.D)
				maxFloor = math.max(maxFloor, p.Floor or 0)
				minFloor = math.min(minFloor, p.Floor or 0)
			end
		end
	end
	check(ok, "El disco entero es llanura: nada de puertos, islas, sima, garganta, cañón ni abismo")
	check(minLand > 1000, ("Lejos de la costa y las playas (a %.0f studs de tierra, como poco)"):format(minLand))
	check(maxFloor - Nacara.FloorY < 12 and Nacara.FloorY - minFloor < 8, ("El fondo de alrededor está cerca del suelo de la plaza (de %.1f a %.1f; plaza %.0f): se allana poco"):format(minFloor, maxFloor, Nacara.FloorY))
	for _, k in Ocean.Keep do
		local d = math.sqrt((k.X - C.X) ^ 2 + (k.Z - C.Z) ^ 2)
		if d < k.R + 1200 then
			check(false, "Lejos de " .. k.Name)
		end
	end
	check(true, "A más de 1200 studs de cualquier puerto, marina o isla con muelle (Ocean.Keep)")
	-- el megalodón: su elipse y su ronda de verdad
	local B = Ocean.Basin
	local e = math.sqrt(((C.X - B.X) / B.RX) ^ 2 + ((C.Z - B.Z) / B.RZ) ^ 2)
	check(e > 1.8, ("Fuera del Abismo Silente, el territorio del megalodón (elipse ×%.2f)"):format(e))
	local SeaBeasts = L.load("src/shared/Sea/SeaBeasts")
	local mg = SeaBeasts.newMegalodon()
	local nearest = math.huge
	for _ = 1, 4000 do
		mg = SeaBeasts.stepMegalodon(mg, 0.125, {})
		nearest = math.min(nearest, math.sqrt((mg.Pos.X - C.X) ^ 2 + (mg.Pos.Z - C.Z) ^ 2))
	end
	check(nearest > 1500, ("El megalodón nunca pasa cerca (lo más cerca: %.0f studs)"):format(nearest))
	-- sitios del mar (POI) y agujas de roca
	local clash = {}
	for _, poi in Ocean.Pois do
		local d = math.sqrt((poi.X - C.X) ^ 2 + (poi.Z - C.Z) ^ 2)
		if d < poi.Radius + Nacara.Clear + 150 then
			table.insert(clash, poi.Id)
		end
	end
	check(#clash == 0, "No pisa ningún sitio del mar (ni a 150 studs: Ruinas a 541, Valmar Hundida a 445)" .. (if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
	local spireClash = 0
	for _, sp in Ocean.spires() do
		if math.sqrt((sp.X - C.X) ^ 2 + (sp.Z - C.Z) ^ 2) < sp.R + Nacara.Clear + 20 then
			spireClash += 1
		end
	end
	check(spireClash == 0, "Ninguna aguja de roca dentro de la plaza (las del cañón se ven detrás)")
	for _, f in Ocean.JellyFields do
		if math.sqrt((f.X - C.X) ^ 2 + (f.Z - C.Z) ^ 2) < f.R + Nacara.Clear then
			check(false, "Lejos del campo de medusas " .. f.Name)
		end
	end
	check(Ocean.currentAt(Nacara.centerPosition() + Vector3.new(0, 10, 0)).Magnitude < 0.01, "Sin corrientes del mar en la plaza")
end

---------------------------------------------------------------------
print("\n▶ Lo que hay en la plaza no se pisa")
do
	local overlaps = {}
	for i, a in Nacara.Layout do
		if math.sqrt(a.X ^ 2 + a.Z ^ 2) + a.R > Nacara.Radius + 0.6 then
			table.insert(overlaps, a.Id .. " se sale")
		end
		for j = i + 1, #Nacara.Layout do
			local b = Nacara.Layout[j]
			if math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2) < a.R + b.R then
				table.insert(overlaps, a.Id .. "/" .. b.Id)
			end
		end
	end
	check(#overlaps == 0, ("%d cosas en la plaza sin pisarse (fuente, cúpula, 4 torres, 2 conchas, 3 terrazas, 2 arcos)"):format(#Nacara.Layout) .. (if #overlaps > 0 then ": " .. table.concat(overlaps, ", ") else ""))
	local towers, top = 0, 0
	for _, item in Nacara.Layout do
		if item.Kind == "Tower" then
			towers += 1
			top = math.max(top, item.H)
		end
	end
	check(towers == 4 and top <= Nacara.MaxTop, ("4 torres de coral; la más alta, %d studs"):format(top))
	check(#Nacara.Stalls >= 3 and #Nacara.Stalls <= 4, ("%d puestos en la Lonja Honda"):format(#Nacara.Stalls))
	local inside = 0
	for _, s in Nacara.Stalls do
		local x, z = Nacara.stallSpot(s)
		local d = math.sqrt((x - Nacara.Dome.X) ^ 2 + (z - Nacara.Dome.Z) ^ 2)
		if d + 1.2 < Nacara.Dome.Air then
			inside += 1
		end
	end
	check(inside == #Nacara.Stalls, "Los mostradores están dentro del aire de la cúpula (se compra de pie)")
	check(#Nacara.People >= 6 and #Nacara.People <= 10, ("%d Hondarios en la plaza"):format(#Nacara.People))
	-- la cola no se mete en el suelo ni en las terrazas
	local sunk = {}
	for _, person in Nacara.People do
		local x, z, y = Nacara.personSpot(person)
		local under = 0
		for _, item in Nacara.Layout do
			if item.Kind == "Terrace" and math.sqrt((x - item.X) ^ 2 + (z - item.Z) ^ 2) < item.R then
				under = math.max(under, item.H + 0.5)
			end
		end
		if y < under + Nacara.TailClear then
			table.insert(sunk, person.Id)
		end
	end
	check(#sunk == 0, "Cada Hondario flota lo bastante alto: la cola no atraviesa el suelo ni las terrazas" .. (if #sunk > 0 then ": " .. table.concat(sunk, ", ") else ""))
	local signs = {}
	for _, s in Nacara.Signs do
		table.insert(signs, s.Text)
	end
	check(string.find(table.concat(signs, " "), "plaza de prueba", 1, true) ~= nil, "Cartel «Nácara · plaza de prueba»")
end

---------------------------------------------------------------------
print("\n▶ La construcción (World/NacaraBuilder)")
local fills = { Water = 0, Salt = 0, Air = 0, Other = 0 }
local airBall: any = nil
local fakeTerrain = {}
local function record(material: any)
	local name = material.Name
	fills[name] = (fills[name] or 0) + 1
end
function fakeTerrain.FillBlock(_, _cf, _size, material)
	record(material)
end
function fakeTerrain.FillCylinder(_, _cf, _h, _r, material)
	record(material)
end
function fakeTerrain.FillBall(_, center, radius, material)
	record(material)
	if material == roblox.Enum.Material.Air then
		airBall = { Center = center, Radius = radius }
	end
end
local NacaraBuilder = L.load("src/server/World/NacaraBuilder")
NacaraBuilder.build(fakeTerrain)
local folder = L.workspace:FindFirstChild("Nacara")
local buildingParts, models, atomic, highest, lightsN = 0, 0, 0, -math.huge, 0
local forbidden, unanchored, colliders = {}, 0, 0
local dome: any = nil
local BAD = { "Marble", "Slate", "Sand", "Limestone", "Cobblestone", "Concrete", "Brick", "Plaster", "Pavement", "Asphalt", "Grass", "Wood", "WoodPlanks", "Basalt", "Rock", "Ground", "Pebble", "Mud", "CeramicTiles", "DiamondPlate", "ClayRoofTiles" }
do
	check(NacaraBuilder.State == "Ready" and L.workspace:GetAttribute("NacaraReady") == true, "Se construye una vez y avisa (workspace.NacaraReady)")
	for _, m in (if folder then folder:GetChildren() else {}) do
		if m:IsA("Model") then
			models += 1
			local okMode, mode = pcall(function()
				return (m :: any).ModelStreamingMode
			end)
			if okMode and mode == roblox.Enum.ModelStreamingMode.Atomic then
				atomic += 1
			end
		end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				buildingParts += 1
				highest = math.max(highest, d.CFrame.Position.Y + d.Size.Y / 2)
				if not d.Anchored then
					unanchored += 1
				end
				if d.CanCollide then
					colliders += 1
				end
				for _, bad in BAD do
					if d.Material.Name == bad then
						forbidden[bad] = true
					end
				end
				if d:HasTag("SeaAirPocket") then
					dome = d
				end
			elseif d:IsA("PointLight") then
				lightsN += 1
			end
		end
	end
	check(models >= 8 and atomic == models, ("%d modelos Atomic (StreamingEnabled: llegan enteros)"):format(models))
	check(buildingParts > 300 and buildingParts <= Nacara.Budget - NacaraBuilder.PeopleReserve, ("Edificios: %d piezas (tope %d, %d para la gente)"):format(buildingParts, Nacara.Budget - NacaraBuilder.PeopleReserve, NacaraBuilder.PeopleReserve))
	check(lightsN <= NacaraBuilder.MaxLights and lightsN >= 3, ("Solo %d luces de verdad (PointLight, sin sombras): la luz es Neon y Bloom"):format(lightsN))
	check(unanchored == 0, "Todo anclado (en el agua nada flota suelto)")
	check(next(forbidden) == nil, "Sin materiales que cambia World/UserMaterials (mármol, pizarra, arena…): nácar de SmoothPlastic, Neon, Glass y Fabric")
	check(highest < Ocean.Surface - 20 and highest <= Nacara.FloorY + Nacara.MaxTop + 4, ("Lo más alto a %.0f (%.0f studs bajo la superficie: los barcos pasan por encima)"):format(highest, Ocean.Surface - highest))
	check(fills.Water >= 1 and fills.Salt >= 2 and fills.Air == 1, ("Terreno: se allana (agua %d, grano blanco %d) y la cúpula se llena de Aire (%d)"):format(fills.Water, fills.Salt, fills.Air))
	check(airBall ~= nil and (airBall.Center - Nacara.domeCenter()).Magnitude < 0.01 and airBall.Radius == Nacara.Dome.Air, ("La burbuja de Aire de la cúpula: radio %.1f studs"):format(Nacara.Dome.Air))
	check(dome ~= nil and dome:HasTag("NacaraDome") and dome:GetAttribute("Radius") >= Nacara.Dome.Air and not dome.CanCollide, "La membrana: etiqueta SeaAirPocket (DivingService rellena el aire) y se cruza nadando (sin choque)")
	-- suelo seco dentro
	local dry = false
	for _, d in (folder :: any):GetDescendants() do
		if d.Name == "SueloSeco" and d.CanCollide then
			dry = true
		end
	end
	check(dry, "Suelo seco dentro de la cúpula (se anda)")
	-- carteles con texto
	local texts = {}
	for _, d in (folder :: any):GetDescendants() do
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		end
	end
	local all = table.concat(texts, " | ")
	check(string.find(all, "NÁCARA · plaza de prueba", 1, true) ~= nil and string.find(all, "LONJA HONDA", 1, true) ~= nil, ("Carteles en el juego (%d textos): «NÁCARA · plaza de prueba», «LONJA HONDA»…"):format(#texts))
end

---------------------------------------------------------------------
print("\n▶ No pisa lo que ya hay en el mar")
do
	local OceanBuilder = L.load("src/server/World/OceanBuilder")
	OceanBuilder.sites()
	local mar = L.workspace:FindFirstChild("Mar")
	local near = 0
	for _, d in (if mar then mar:GetDescendants() else {}) do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			if math.sqrt((p.X - C.X) ^ 2 + (p.Z - C.Z) ^ 2) < Nacara.Clear + 40 then
				near += 1
			end
		end
	end
	check(mar ~= nil and near == 0, "Ninguna pieza de los sitios del mar (OceanBuilder) cerca de la plaza")
	-- los recursos del fondo (OceanService.plan): ninguno queda debajo de la plaza
	local remotes = {}
	local function remoteDouble()
		return { FireClient = function() end, FireServer = function() end, OnServerEvent = { Connect = function() end } }
	end
	remotes.Notify = remoteDouble()
	remotes.Sea = remoteDouble()
	remotes.Diving = remoteDouble()
	function remotes:FindFirstChild(name)
		return rawget(self, name)
	end
	rawset(L.services.ReplicatedStorage, "Remotes", remotes)
	L.services.Players = { GetPlayers = function()
		return {}
	end, PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end } }
	L.mock("src/server/Services/DataService", { get = function() return nil end, addMoney = function() return true end })
	L.mock("src/server/Services/InventoryService", { count = function() return 0 end, add = function() return true end })
	L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
	L.mock("src/server/Services/DivingService", { underwater = function() return false end })
	local OceanService = L.load("src/server/Services/OceanService")
	local under = 0
	for _, spec in OceanService.plan() do
		if Nacara.covers(spec.Position.X, spec.Position.Z) then
			under += 1
		end
	end
	check(under == 0, "Ningún recurso del fondo (conchas, perlas…) queda debajo de la plaza")
	L.reset("src/server/Services/DivingService")
	L.mock("src/server/Services/DivingService", nil)
end

---------------------------------------------------------------------
print("\n▶ La cúpula de aire: se respira y se anda")
do
	local d = Nacara.domeCenter()
	local insideP = d + Vector3.new(4, 3, -2)
	local outsideP = d + Vector3.new(Nacara.Dome.Radius + 4, 3, 0)
	check(Nacara.inDome(insideP) and not Nacara.inDome(outsideP) and not Nacara.inDome(Nacara.centerPosition() + Vector3.new(0, 4, 0)), "Nacara.inDome: dentro sí; fuera de la membrana y en la fuente, no")
	-- DivingService de verdad: la bolsa de aire es la membrana (CollectionService con la cúpula)
	L.services.CollectionService = {
		AddTag = function() end,
		GetTagged = function(_, tag)
			if tag == "SeaAirPocket" then
				-- (la membrana; en Lune una pieza no da su Position: se pasa con la de su CFrame)
				return { {
					IsA = function(_, class)
						return class == "BasePart"
					end,
					Position = dome.CFrame.Position,
					GetAttribute = function(_, key)
						return dome:GetAttribute(key)
					end,
				} }
			end
			return {}
		end,
	}
	L.mock("src/server/Services/FishingService", { isWater = function() return true end, levelOf = function() return 1 end, toolsOf = function() return {} end })
	L.mock("src/server/Services/InventoryService", { count = function() return 0 end })
	L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
	L.reset("src/server/Services/DivingService")
	local okD, DivingService = pcall(L.load, "src/server/Services/DivingService")
	check(okD, "DivingService se carga" .. (if okD then "" else ": " .. tostring(DivingService)))
	if okD then
		check(DivingService.inPocket(insideP) == true and DivingService.inPocket(outsideP) == false, "DivingService.inPocket: dentro de la cúpula se respira; fuera, no")
	end
	-- el aire sube dentro (con botella, a 37 m) y la presión no hace daño
	local depth = meters(insideP.Y)
	local o, dmg = Diving.tick({ Oxygen = 40, Max = 240, Under = true, Meters = depth, Gear = "Botella", Pocket = true })
	check(o > 40 and dmg == 0, ("Dentro de la cúpula (%.0f m) el aire sube: 40 → %d s"):format(depth, o))
	local o2 = Diving.tick({ Oxygen = 40, Max = 240, Under = true, Meters = depth, Gear = "Botella", Pocket = false })
	check(o2 < 40, "Fuera, con la botella, el aire baja como siempre")
	local _, dmgNo = Diving.tick({ Oxygen = 10, Max = 30, Under = true, Meters = depth, Gear = nil, Pocket = true, Over = 10 })
	check(dmgNo == 0, "Dentro de la cúpula la presión no hace daño (aire de verdad)")
	check(Diving.pressure(Nacara.depthMeters() + 3, "Botella") == "Ok", "Con el equipo de buceo (75 m) se llega a la plaza sin aviso de presión")
	-- se anda: el control de nadar no se engancha dentro (tu personaje y lo que ves de los demás)
	local swimming = fs.readFile("src/client/Controllers/Swimming.luau")
	local age = fs.readFile("src/client/Controllers/AgeMotion.luau")
	check(string.find(swimming, "and not Nacara.inDome(pos)", 1, true) ~= nil, "Swimming: dentro de la cúpula no nadas (andas por el suelo seco)")
	check(string.find(age, "Nacara.inDome(position)", 1, true) ~= nil, "AgeMotion: a los demás dentro de la cúpula tampoco se les pone la postura de nadar")
end

---------------------------------------------------------------------
print("\n▶ Los Hondarios y las charlas (Services/NacaraService)")
local NacaraService: any = nil
local played: { any } = {}
do
	-- un personaje R15 de bloques (el de Roblox no existe en Lune)
	local R15 = { "UpperTorso", "LowerTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
	local SIZES = { UpperTorso = Vector3.new(2, 1.6, 1), LowerTorso = Vector3.new(2, 0.4, 1), Head = Vector3.new(1.2, 1.2, 1.2) }
	L.mock("src/server/World/Npc", {
		create = function(name, parent, cf)
			local m = roblox.Instance.new("Model")
			m.Name = name
			local root = roblox.Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Size = Vector3.new(2, 2, 1)
			root.CFrame = cf * roblox.CFrame.new(0, 3, 0)
			root.Anchored = true
			root.Parent = m
			for i, n in R15 do
				local p = roblox.Instance.new("Part")
				p.Name = n
				p.Size = SIZES[n] or Vector3.new(1, 1.1, 1)
				p.CFrame = root.CFrame * roblox.CFrame.new(0, 2 - i * 0.2, 0)
				p.Parent = m
			end
			-- (el pelo y el cuello que pone Npc.dress)
			for _, n in { "Collar", "Hair", "HairBack", "Fringe" } do
				local p = roblox.Instance.new("Part")
				p.Name = n
				p.Parent = m
			end
			roblox.Instance.new("Humanoid").Parent = m
			m.PrimaryPart = root
			m.Parent = parent
			return m
		end,
	})
	L.fakeClasses.ProximityPrompt = function()
		local handlers = {}
		local prompt = { Name = "ProximityPrompt", Parent = nil, Triggered = { Connect = function(_, fn)
			table.insert(handlers, fn)
		end } }
		prompt._fire = function(player)
			for _, fn in handlers do
				fn(player)
			end
		end
		L.prompts = L.prompts or {}
		table.insert(L.prompts, prompt)
		return prompt
	end
	L.mock("src/server/Services/DialogueService", {
		play = function(player, dialogue, context)
			table.insert(played, { Player = player, Dialogue = dialogue, Context = context })
			return true
		end,
		bark = function() end,
	})
	L.services.Players = { GetPlayers = function()
		return {}
	end, PlayerRemoving = { Connect = function() end } }
	local landmarks = roblox.Instance.new("Folder")
	landmarks.Name = "MapLandmarks"
	rawset(L.services.ReplicatedStorage, "MapLandmarks", landmarks)
	NacaraService = L.load("src/server/Services/NacaraService")
	NacaraService.setup(fakeTerrain) -- (el edificio ya está: no se vuelve a construir)
	local people, tails, crests, plates, guards = 0, 0, 0, 0, 0
	for _, person in Nacara.People do
		local m = NacaraService.People[person.Id]
		if m then
			people += 1
			if m:FindFirstChild("Cola4") and m:FindFirstChild("Aleta") and m.Cola1:FindFirstChildOfClass("Motor6D") then
				tails += 1
			end
			if m:FindFirstChild("Cresta") and m:FindFirstChild("AletaBrazo") then
				crests += 1
			end
			if m:FindFirstChild("PetoNacar") and m:FindFirstChild("Fajin") then
				plates += 1
			end
			if person.Role == "Guard" and m:FindFirstChild("Baston") then
				guards += 1
			end
			local leg = m:FindFirstChild("LeftUpperLeg")
			if leg and leg.Transparency < 1 then
				tails -= 1
			end
		end
	end
	check(people == #Nacara.People, ("%d Hondarios en la plaza"):format(people))
	check(tails == people, "Todos con cola de cuatro tramos (Motor6D, el cliente la mueve) y aleta, sin piernas a la vista")
	check(crests == people and plates == people, "Cresta de aleta, aletas en los antebrazos y siempre vestidos: túnica de kelp, peto de nácar y fajín")
	check(guards == 2, "La Guardia lleva bastón sin punta (de golpe, no de corte)")
	local total = NacaraBuilder.Stats.Parts
	check(total <= Nacara.Budget, ("Plaza + gente: %d piezas del servidor (tope %d); gente: %d piezas"):format(total, Nacara.Budget, NacaraService.Stats.PeopleParts))
	-- en el agua, flotando sobre el suelo
	local floating = true
	for _, m in NacaraService.People do
		local home = m:GetAttribute("Home")
		if typeof(home) ~= "CFrame" or home.Position.Y < Nacara.FloorY + 2 or home.Position.Y > Ocean.Surface - 20 then
			floating = false
		end
	end
	check(floating, "Cada Hondario flota en su sitio (atributo Home para el cliente)")
	-- Oriana atiende desde el agua (fuera de la membrana) y su puesto está dentro
	local oriana = NacaraService.People.Oriana
	check(oriana ~= nil and not Nacara.inDome(oriana:GetAttribute("Home").Position, 0) and (oriana:GetAttribute("Home").Position - Nacara.domeCenter()).Magnitude < Nacara.Dome.Radius + 5, "Oriana atiende desde el agua, justo fuera de la membrana de su puesto")
	-- «Hablar»: Ilun y Oriana
	local prompts = L.prompts or {}
	check(#prompts == 2, ("«Hablar» con Ilun y con Oriana (%d)"):format(#prompts))
	local player = L.player("Sebas", 1)
	for _, p in prompts do
		p._fire(player)
	end
	check(#played == 2 and played[1].Dialogue.Lines == Nacara.Dialogues.Ilun or (played[2] and played[2].Dialogue.Lines == Nacara.Dialogues.Ilun), "La charla empieza (DialogueService.play) con Ilun y con Oriana")
	local asks, effects, speakers = 0, 0, {}
	local function scan(lines)
		for _, line in lines do
			if line.Ask then
				asks += 1
				for _, o in line.Options do
					if o.Effects then
						effects += 1
					end
					scan(o.Then or {})
				end
			end
			if line.Effects or line.If then
				effects += 1
			end
			if line.S then
				speakers[line.S] = true
			end
		end
	end
	scan(Nacara.Dialogues.Ilun)
	scan(Nacara.Dialogues.Oriana)
	check(asks == 2 and effects == 0, "Cada charla tiene su pregunta y NINGÚN efecto (sin premios, marcas ni dinero)")
	check(played[1].Context.actorOf("Ilun") == NacaraService.People.Ilun, "La cámara de la charla mira al Hondario que habla (actorOf)")
	-- es una prueba: nada de dinero, mochila ni guardado
	local src = fs.readFile("src/server/Services/NacaraService.luau") .. fs.readFile("src/server/World/NacaraBuilder.luau") .. fs.readFile("src/shared/Sea/Nacara.luau")
	local writes = { "DataService", "addMoney", "InventoryService", "DataStoreService", "SetAsync", "UpdateAsync", "StoryEvents" }
	local found = {}
	for _, w in writes do
		if string.find(src, w, 1, true) then
			table.insert(found, w)
		end
	end
	check(#found == 0, "No da premios ni guarda nada (sin DataService, mochila, DataStore ni StoryEvents)" .. (if #found > 0 then ": " .. table.concat(found, ", ") else ""))
	-- el mapa
	check(NacaraService.publishLandmark() and landmarks:FindFirstChild("PuntoNacara_Plaza") ~= nil, "En el mapa: punto «PuntoNacara» (🐚 Nácara (prueba))")
	local MapInfo = L.load("src/shared/MapInfo")
	local MapLegend = L.load("src/shared/MapLegend")
	local kind = MapInfo.KindByModel and MapInfo.KindByModel.PuntoNacara
	local inLegend = false
	for _, cat in MapLegend.Categories or MapLegend do
		if type(cat) == "table" and cat.Models and table.find(cat.Models, "PuntoNacara") then
			inLegend = true
		end
	end
	check(kind ~= nil and kind.Name == "Nácara (prueba)" and inLegend, "MapInfo y la leyenda del mapa saben qué es (se puede marcar como destino)")
end

---------------------------------------------------------------------
print("\n▶ La ruta de buceo y la corriente guía")
do
	-- empieza en el jardín de coral de la orilla más cercano
	local nearest, nd = nil, math.huge
	for _, reef in Ocean.ShoreReefs do
		local d = math.sqrt((reef.X - C.X) ^ 2 + (reef.Z - C.Z) ^ 2)
		if d < nd then
			nearest, nd = reef, d
		end
	end
	check(Nacara.StartReef == nearest, ("Empieza en el jardín de coral más cercano: %s (%.0f studs)"):format(nearest.Name, nd))
	local last = Nacara.Route[#Nacara.Route]
	check(math.sqrt((last.X - C.X) ^ 2 + (last.Z - C.Z) ^ 2) < Nacara.Radius + 20, "Acaba en el arco de entrada de la plaza")
	local wet, pts = true, Nacara.routePoints()
	for _, m in pts do
		local f = Ocean.floorY(m.Position.X, m.Position.Z)
		if not f or m.Position.Y <= f + 2 or m.Position.Y > Ocean.Surface - 3 then
			wet = false
		end
	end
	check(#pts > 20 and wet, ("%d perlas de guía (una cada %d studs), todas en el agua sobre el fondo"):format(#pts, Nacara.RouteMarkerStep))
	local length = Nacara.routeLength()
	check(length < 2600, ("La ruta mide %.0f studs (%.0f m): con la botella (240 s) y la corriente se llega de sobra"):format(length, length / Ocean.StudsPerMeter))
	-- la corriente empuja hacia la plaza por toda la ruta
	local good, total = 0, 0
	for i, m in pts do
		if i < #pts - 1 then
			total += 1
			local push = Nacara.currentAt(m.Position)
			local nextP = pts[i + 1].Position
			if push.Magnitude > 0.5 and push:Dot((nextP - m.Position) * Vector3.new(1, 0, 1)) > 0 then
				good += 1
			end
		end
	end
	check(total > 0 and good >= total - 2, ("La corriente guía empuja hacia la plaza (%d de %d puntos)"):format(good, total))
	check(Nacara.currentAt(Nacara.centerPosition() + Vector3.new(0, 5, 0)).Magnitude == 0 and Nacara.currentAt(Vector3.new(0, -20, 0)).Magnitude == 0, "En la plaza y lejos de la ruta no empuja")
	check(Nacara.RouteSpeed <= 3, ("Empuja suave (%.1f studs/s): se nada en contra sin problema"):format(Nacara.RouteSpeed))
	local swimming = fs.readFile("src/client/Controllers/Swimming.luau")
	check(string.find(swimming, "Nacara.currentAt(pos)", 1, true) ~= nil, "Swimming suma la corriente guía buceando")
end

---------------------------------------------------------------------
print("\n▶ La luz de la ciudad (zona «Submarino»)")
do
	local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")
	local base = OceanBiomes.look("Llanura", 38, nil, 1)
	local here = Nacara.lookNear(base, Nacara.centerPosition() + Vector3.new(0, 8, 0))
	check(here and here.Glow >= 0.8 and here.Exposure > base.Exposure + 0.15 and here.FillMix >= 0.6, ("En la plaza de noche manda la luz de la ciudad: brillo %.2f, exposición %+.2f"):format(here.Glow, here.Exposure - base.Exposure))
	local far = Nacara.lookNear(base, Vector3.new(C.X + 900, -130, C.Z))
	check(far == base, "Lejos de la ciudad la luz es la de siempre (sin tocarla)")
	local shallow = Nacara.lookNear(base, Vector3.new(C.X, -10, C.Z))
	check(shallow == base, "Cerca de la superficie, tampoco")
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local okK, key = pcall(EnvZones.underwaterKey, { Exposure = 0, Bloom = 0.5, Threshold = 1.4 }, here)
	check(okK and key.Bloom > 0.5 and key.Exposure > -0.1, "EnvZones.underwaterKey la pinta (más Bloom en el Neon de las perlas y el coral)")
	local biome = fs.readFile("src/client/Controllers/SeaBiome.luau")
	check(string.find(biome, "Nacara.lookNear(target, camPos)", 1, true) ~= nil and string.find(biome, "not Nacara.covers(x, z)", 1, true) ~= nil, "SeaBiome: pide la luz de la ciudad y no planta decorado encima de la plaza")
end

---------------------------------------------------------------------
print("\n▶ El cliente (Controllers/NacaraLife)")
do
	L.mock("src/client/UI/Perf", { mobile = true, lite = true })
	L.services.RunService = { RenderStepped = { Connect = function() end }, IsStudio = function() return false end }
	local okL, Life = pcall(L.load, "src/client/Controllers/NacaraLife")
	check(okL, "NacaraLife se carga" .. (if okL then "" else ": " .. tostring(Life)))
	if okL then
		local mob, pc = Life.Caps.Mobile, Life.Caps.Desktop
		local mobParts = mob.Fish + mob.Jelly * 2 + mob.Markers
		local pcParts = pc.Fish + pc.Jelly * 2 + pc.Markers
		check(mobParts <= 24 and pcParts <= 40 and mob.Npcs <= 8, ("Vida de la ciudad con tope: móvil %d piezas y %d Hondarios animados; ordenador %d piezas"):format(mobParts, mob.Npcs, pcParts))
		local dy = Life.bob(1.3, 0.5)
		check(math.abs(dy) <= 0.4 and math.abs(Life.tailWave(2, 0.5, 4)) < 0.5, "Se mecen poco y la cola hace la onda (barato)")
		local near = Life.nearestMarkers(Nacara.routePoints(), Nacara.routePoints()[5].Position, 8, 300)
		check(#near >= 4 and #near <= 8, ("Solo las perlas de guía cercanas (%d)"):format(#near))
	end
	local main = fs.readFile("src/client/Main.client.luau")
	check(string.find(main, "Controllers.NacaraLife", 1, true) ~= nil, "Main.client arranca NacaraLife")
	local server = fs.readFile("src/server/Main.server.luau")
	check(string.find(server, '"NacaraService"', 1, true) ~= nil, "Main.server arranca NacaraService")
end

print(("\nResumen: plaza a %.1f m · edificios %d piezas · gente %d piezas · total %d / %d · %d luces · %d modelos"):format(Nacara.depthMeters(), buildingParts, NacaraService and NacaraService.Stats.PeopleParts or 0, NacaraBuilder.Stats.Parts, Nacara.Budget, lightsN, models))
L.finish("test-nacara")
