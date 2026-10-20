-- Prueba de la VIDA HONDARIA (modo pruebas) y de la FASE 1 de Nácara (docs/mar/civilizacion-marina.md),
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-hondario.luau
--
-- Comprueba:
--   * shared/Sea/MerForm: cola en el agua y piernas en tierra / barco / cúpula / «forma humana»; el aire
--     de las branquias no baja nunca; presión hasta 120 m (nunca en los barrios de Nácara); el nado con cola
--     es +40 % y acelera poco a poco
--   * shared/Sea/Civ: los barrios no tocan puertos, playas, jardines de coral, sitios del mar ni el
--     territorio del megalodón; las zonas de Nácara no se pisan entre sí ni con la plaza; las viviendas
--     con claves MarCasa_ (nunca como las de Valmar), dentro de su barrio y con aire
--   * World/NacaraCityBuilder: modelos Atomic, presupuesto de piezas, pocas luces, todo anclado, el
--     decorado sin choques ni consultas, el aire de las conchas y la posada, marcas de la historia y tablones
--   * World/MerBody: la cola (piezas normales, sin mallas subidas), esconder y enseñar las piernas
--   * Services/HondarioService: solo testers; empieza la vida hondaria (adulto, casa en Nácara, cama de
--     reaparición, te lleva allí), la forma cambia sola, «Quedarme en forma humana», y vuelve a la vida
--     humana (devuelve lo de antes)
--   * Services/DivingService con branquias: el aire se queda lleno a 37 m y no hay daño

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local check = L.check

-- CollectionService que de verdad pone las etiquetas (Lune: Instance:AddTag)
L.services.CollectionService = {
	AddTag = function(_, inst, tag)
		inst:AddTag(tag)
	end,
	GetTagged = function()
		return {}
	end,
	GetInstanceAddedSignal = function()
		return { Connect = function() end }
	end,
}

local Ocean = L.load("src/shared/Sea/Ocean")
local Nacara = L.load("src/shared/Sea/Nacara")
local Civ = L.load("src/shared/Sea/Civ")
local MerForm = L.load("src/shared/Sea/MerForm")

---------------------------------------------------------------------
print("▶ Las reglas del cuerpo hondario (shared/Sea/MerForm)")
do
	check(MerForm.form({ Gift = true, Underwater = true }) == "Cola", "con el don, bajo el agua: cola")
	check(MerForm.form({ Gift = true, Underwater = false }) == "Piernas", "en tierra: piernas")
	check(MerForm.form({ Gift = true, Underwater = true, InAir = true }) == "Piernas", "dentro de una cúpula de aire: piernas (se anda)")
	check(MerForm.form({ Gift = true, Underwater = true, Seated = true }) == "Piernas", "sentado en un barco: piernas")
	check(MerForm.form({ Gift = true, Underwater = true, StayHuman = true }) == "Piernas", "«Quedarme en forma humana»: piernas también bajo el agua")
	check(MerForm.form({ Gift = false, Underwater = true }) == "Piernas", "sin el don, nunca cola")
	local o, dmg, _, p = MerForm.breath({ Max = 240, Meters = 40 })
	check(o == 240 and dmg == 0 and p == "Ok", "branquias a 40 m: el aire no baja (240/240), sin daño")
	local o2, d2, _, p2 = MerForm.breath({ Max = 240, Meters = 140, Over = 10 })
	check(o2 == 240 and p2 == "Over" and d2 > 0, ("más hondo que %d m la presión aprieta (pero el aire sigue lleno)"):format(MerForm.Depth))
	local _, d3, _, p3 = MerForm.breath({ Max = 240, Meters = 140, Safe = true, Over = 10 })
	check(d3 == 0 and p3 == "Ok", "en un barrio de Nácara, la presión nunca hace daño")
	-- el nado con cola: +40 % y acelera poco a poco
	local goal = MerForm.targetSpeed(false)
	check(math.abs(goal - MerForm.BaseSpeed * 1.4) < 0.01, ("nado con cola: %.1f studs/s (+40 %%)"):format(goal))
	local v, t = 0, 0
	local after05 = nil
	while v < goal - 0.01 and t < 10 do
		v = MerForm.swimSpeed(v, true, false, 1 / 30)
		t += 1 / 30
		if not after05 and t >= 0.5 then
			after05 = v
		end
	end
	check(after05 ~= nil and after05 < goal * 0.4 and t > 1.5 and t < 4, ("acelera suave: a los 0,5 s va a %.1f; llega a %.1f en %.1f s"):format(after05 or -1, goal, t))
	local stop = MerForm.swimSpeed(goal, false, false, 0.5)
	check(stop < goal and stop > 0, "al soltar frena poco a poco")
	check(MerForm.targetSpeed(true) > goal, "con Correr, más rápido todavía")
end

---------------------------------------------------------------------
print("\n▶ Los barrios de la fase 1 (shared/Sea/Civ)")
do
	-- los barrios: en el mar, lejos de puertos, playas, jardines de coral, sitios y megalodón
	for _, d in Civ.Districts do
		local s = Ocean.sample(d.X, d.Z)
		check(s.Floor ~= nil and s.Keep == 0 and s.Basin == 0 and s.Trench == 0, ("%s: en el mar, sin puertos ni abismo ni sima"):format(d.Name))
		local nearKeep = math.huge
		for _, k in Ocean.Keep do
			nearKeep = math.min(nearKeep, math.sqrt((k.X - d.X) ^ 2 + (k.Z - d.Z) ^ 2) - k.R)
		end
		check(nearKeep > d.R + 150, ("%s: a %.0f studs de cualquier puerto o isla con muelle"):format(d.Name, nearKeep))
		local clash = {}
		for _, poi in Ocean.Pois do
			if math.sqrt((poi.X - d.X) ^ 2 + (poi.Z - d.Z) ^ 2) < poi.Radius + d.R + 20 then
				table.insert(clash, poi.Id)
			end
		end
		for _, reef in Ocean.ShoreReefs do
			if math.sqrt((reef.X - d.X) ^ 2 + (reef.Z - d.Z) ^ 2) < d.R + 60 then
				table.insert(clash, reef.Id)
			end
		end
		check(#clash == 0, ("%s: no pisa ningún sitio del mar ni jardín de coral"):format(d.Name) .. (if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
		local B = Ocean.Basin
		check(math.sqrt(((d.X - B.X) / B.RX) ^ 2 + ((d.Z - B.Z) / B.RZ) ^ 2) > 1.5, ("%s: fuera del territorio del megalodón"):format(d.Name))
	end
	local a, b = Civ.Districts[1], Civ.Districts[2]
	check(math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2) > a.R + b.R, "los dos barrios no se pisan")
	-- el Cañón de Dorada (zona de referencia del mar v2) está lejos
	local ReefZone = L.load("src/shared/Sea/ReefZone")
	local box = ReefZone.Box
	local function boxDist(x, z)
		local dx = math.max(box.MinX - x, 0, x - box.MaxX)
		local dz = math.max(box.MinZ - z, 0, z - box.MaxZ)
		return math.sqrt(dx * dx + dz * dz)
	end
	check(boxDist(a.X, a.Z) > a.R + 1000 and boxDist(b.X, b.Z) > b.R + 1000, ("lejos del Cañón de Dorada (a %.0f y %.0f studs)"):format(boxDist(a.X, a.Z), boxDist(b.X, b.Z)))
	-- las zonas de Nácara: dentro del barrio, sin pisarse, fuera del cañón y de la ruta de buceo
	local overlaps = {}
	for i, x in Civ.Areas do
		if math.sqrt(x.X ^ 2 + x.Z ^ 2) + x.R > a.R then
			table.insert(overlaps, x.Id .. " se sale")
		end
		for j = i + 1, #Civ.Areas do
			local y = Civ.Areas[j]
			if math.sqrt((x.X - y.X) ^ 2 + (x.Z - y.Z) ^ 2) < x.R + y.R + 4 then
				table.insert(overlaps, x.Id .. "/" .. y.Id)
			end
		end
		if x.Id ~= "Plaza" then
			local s = Ocean.sample(Nacara.Center.X + x.X, Nacara.Center.Z + x.Z)
			if s.Cathedrals > 0 or s.Canyon > 0 then
				table.insert(overlaps, x.Id .. " en el cañón")
			end
			for _, poi in Ocean.Pois do
				if math.sqrt((poi.X - Nacara.Center.X - x.X) ^ 2 + (poi.Z - Nacara.Center.Z - x.Z) ^ 2) < poi.Radius + x.R + 30 then
					table.insert(overlaps, x.Id .. " pisa " .. poi.Id)
				end
			end
		end
	end
	check(#overlaps == 0, ("%d zonas de Nácara (plaza, conchas, jardines, consejo) sin pisarse ni salirse"):format(#Civ.Areas) .. (if #overlaps > 0 then ": " .. table.concat(overlaps, ", ") else ""))
	-- las perlas-farola y los tablones no caen dentro de un edificio
	local inside = {}
	for _, lamp in Civ.Lamps do
		for _, x in Civ.Areas do
			if x.Id ~= "Jardines" and math.sqrt((lamp.X - x.X) ^ 2 + (lamp.Z - x.Z) ^ 2) < x.R - 4 and x.Id ~= "Plaza" then
				table.insert(inside, lamp.Id .. " en " .. x.Id)
			end
		end
		if math.sqrt(lamp.X ^ 2 + lamp.Z ^ 2) < Nacara.Radius + 4 then
			table.insert(inside, lamp.Id .. " en la plaza")
		end
	end
	check(#inside == 0, ("%d perlas-farola por el paseo, fuera de los edificios"):format(#Civ.Lamps) .. (if #inside > 0 then ": " .. table.concat(inside, ", ") else ""))
	-- viviendas: claves propias del mar, únicas, dentro de su barrio, con aire
	local keys, bad = {}, {}
	local VALMAR = { "Casa_", "Villa_", "Portal_", "Local_", "Aula_", "Nave_", "Taller_", "Ocio_" }
	for _, h in Civ.Homes do
		if keys[h.Key] then
			table.insert(bad, h.Key .. " repetida")
		end
		keys[h.Key] = true
		if not Civ.isMarKey(h.Key) then
			table.insert(bad, h.Key .. " sin prefijo del mar")
		end
		for _, prefix in VALMAR do
			if string.sub(h.Key, 1, #prefix) == prefix then
				table.insert(bad, h.Key .. " empieza como Valmar")
			end
		end
		local pos = Civ.homePosition(h)
		local d = Civ.districtAt(pos)
		if not d or d.Id ~= h.District then
			table.insert(bad, h.Key .. " fuera de su barrio")
		end
		if not Nacara.inDome(pos + Vector3.new(0, 2, 0)) then
			table.insert(bad, h.Key .. " sin aire")
		end
	end
	check(#bad == 0 and #Civ.Homes >= 6, ("%d viviendas MarCasa_… únicas, en su barrio y con aire (se anda dentro)"):format(#Civ.Homes) .. (if #bad > 0 then ": " .. table.concat(bad, ", ") else ""))
	local Map = L.load("src/server/Migrations/BuildingKeyMap")
	local clash = 0
	for key in Map.Buildings or {} do
		if Civ.isMarKey(key) or keys[key] then
			clash += 1
		end
	end
	if fs.isFile("scripts/map/data/claves-v1.json") then
		local raw = fs.readFile("scripts/map/data/claves-v1.json")
		for _, h in Civ.Homes do
			if string.find(raw, '"' .. h.Key .. '"', 1, true) then
				clash += 1
			end
		end
	end
	check(clash == 0, "ninguna clave de Valmar (mapa de antes y de ahora) choca con las del mar")
	check(Civ.HomeByKey[Civ.DefaultHome] ~= nil and Civ.HomeByKey[Civ.DefaultHome].District == "Nacara", "la casa de la vida hondaria es una concha de Nácara")
	-- fuera del aire, no
	check(not Nacara.inDome(Nacara.toWorld(-168, 14, 3)) and not Nacara.inDome(Nacara.toWorld(162, -18, 3)), "en la calle del barrio y en los jardines hay agua (se nada)")
	check(Civ.districtAt(Nacara.toWorld(0, 0, 10)).Id == "Nacara" and Civ.districtAt(Vector3.new(0, -20, 0)) == nil, "Civ.districtAt: en Nácara sí; lejos, ninguno")
	-- rutinas
	local maresa = Civ.PersonById.Maresa
	local dx, dz = Civ.spotAt(maresa, 12)
	local nx, nz = Civ.spotAt(maresa, 23)
	check((dx ~= nx or dz ~= nz), "las rutinas cambian de sitio con la hora (Maresa de día en el Consejo, de noche en casa)")
	local tooLow = {}
	for _, p in Civ.People do
		for _, r in p.Routine or { { Spot = { p.X, p.Z, p.Y } } } do
			if (r.Spot[3] or 0) < Nacara.TailClear then
				table.insert(tooLow, p.Id)
			end
		end
	end
	check(#tooLow == 0, "la gente nueva flota lo bastante alta (la cola no atraviesa el suelo)")
end

---------------------------------------------------------------------
print("\n▶ La construcción de la fase 1 (World/NacaraCityBuilder)")
local fills = {}
local airBalls = {}
local fakeTerrain = {}
local function record(material)
	fills[material.Name] = (fills[material.Name] or 0) + 1
end
function fakeTerrain.FillBlock(_, _, _, m)
	record(m)
end
function fakeTerrain.FillCylinder(_, _, _, _, m)
	record(m)
end
function fakeTerrain.FillBall(_, c, r, m)
	record(m)
	if m == roblox.Enum.Material.Air then
		table.insert(airBalls, { Center = c, Radius = r })
	end
end
local Builder = L.load("src/server/World/NacaraCityBuilder")
Builder.build(fakeTerrain)
local folder = L.workspace:FindFirstChild("NacaraCiudad")
for _, w in L.warnings do
	print("    [warn] " .. w)
end
local buildingParts, models, atomic, lightsN = 0, 0, 0, 0
local unanchored, colliders, queries = 0, {}, 0
local forbidden = {}
local tags = { SeaAirPocket = 0, PublicBed = 0, MarHome = 0, MarLamp = 0, MarBed = 0, JobBoard = 0, StorySpot = 0 }
local meshes = 0
local BAD = { "Marble", "Slate", "Sand", "Limestone", "Cobblestone", "Concrete", "Brick", "Plaster", "Pavement", "Asphalt", "Grass", "Wood", "WoodPlanks", "Basalt", "Rock", "Ground", "Pebble", "Mud" }
local COLLIDE_OK = { SueloSeco = true, Estrado = true, Mostrador = true, Cartel = true, TablonTrabajar = true }
do
	check(Builder.State == "Ready" and L.workspace:GetAttribute("NacaraCityReady") == true, "se construye una vez y avisa (workspace.NacaraCityReady)")
	for _, m in (if folder then folder:GetChildren() else {}) do
		if m:IsA("Model") then
			models += 1
			local ok, mode = pcall(function()
				return (m :: any).ModelStreamingMode
			end)
			if ok and mode == roblox.Enum.ModelStreamingMode.Atomic then
				atomic += 1
			end
		end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				buildingParts += 1
				if not d.Anchored then
					unanchored += 1
				end
				if d.CanCollide and not COLLIDE_OK[d.Name] then
					table.insert(colliders, d.Name)
				end
				if d.CanQuery then
					queries += 1
				end
				for _, b in BAD do
					if d.Material.Name == b then
						forbidden[b] = true
					end
				end
				for tag in tags do
					if d:HasTag(tag) then
						tags[tag] += 1
					end
				end
			elseif d:IsA("PointLight") then
				lightsN += 1
			elseif d:IsA("SpecialMesh") then
				if d.MeshType ~= roblox.Enum.MeshType.Sphere then
					meshes += 1
				end
			elseif d:IsA("MeshPart") then
				meshes += 1
			end
		end
	end
	check(models >= 8 and atomic == models, ("%d modelos Atomic (StreamingEnabled: llegan enteros)"):format(models))
	check(buildingParts > 250 and buildingParts <= Civ.Budget - Civ.PeopleReserve, ("edificios de la fase 1: %d piezas (tope %d)"):format(buildingParts, Civ.Budget - Civ.PeopleReserve))
	check(lightsN >= 2 and lightsN <= Civ.MaxLights, ("solo %d luces de verdad (sin sombras): la luz es Neon"):format(lightsN))
	check(unanchored == 0, "todo anclado (en el agua nada flota suelto)")
	check(#colliders == 0, "el decorado no choca (solo el suelo seco, el estrado, los mostradores, carteles y tablones)" .. (if #colliders > 0 then ": " .. table.concat(colliders, ", ", 1, math.min(8, #colliders)) else ""))
	check(queries < 60, ("casi nada se consulta con rayos (%d piezas con CanQuery: suelos, camas, tablones, perlas del oficio)"):format(queries))
	check(next(forbidden) == nil, "sin materiales que cambia World/UserMaterials")
	check(meshes == 0, "sin mallas subidas (MeshPart ni SpecialMesh con MeshId): solo piezas y la esfera de Roblox")
	local pockets = 0
	for _, h in Civ.Homes do
		if (h.Air or 0) > 0 then
			pockets += 1
		end
	end
	check(#airBalls == pockets + 1, ("terreno: %d burbujas de Aire (las conchas y la posada)"):format(#airBalls))
	check(tags.SeaAirPocket == pockets + 1, "cada burbuja con su membrana SeaAirPocket (DivingService rellena el aire)")
	check(tags.PublicBed == #Civ.Homes and tags.MarHome == #Civ.Homes, ("%d hamacas (camas de verdad) y %d carteles «Alquilar»"):format(tags.PublicBed, tags.MarHome))
	check(tags.MarLamp == #Civ.Lamps and tags.MarBed == #Civ.Beds, ("%d perlas-farola y %d bancales para los oficios"):format(tags.MarLamp, tags.MarBed))
	check(tags.JobBoard == 2 and tags.StorySpot == #Civ.StorySpots, ("2 tablones «Trabajar» y %d marcas de la historia"):format(tags.StorySpot))
	local total = Builder.Stats.Parts
	check(total + 782 <= 2500, ("Nácara entera (plaza 782 + fase 1 %d) ≤ 2500 piezas"):format(total))
end

---------------------------------------------------------------------
print("\n▶ El cuerpo hondario (World/MerBody)")
local R15 = { "UpperTorso", "LowerTorso", "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
local SIZES = { UpperTorso = Vector3.new(2, 1.6, 1), LowerTorso = Vector3.new(2, 0.4, 1), Head = Vector3.new(1.2, 1.2, 1.2) }
local function character(at: Vector3)
	local m = roblox.Instance.new("Model")
	m.Name = "Personaje"
	local root = roblox.Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(at)
	root.Parent = m
	for i, n in R15 do
		local p = roblox.Instance.new("Part")
		p.Name = n
		p.Size = SIZES[n] or Vector3.new(1, 1.1, 1)
		p.CFrame = root.CFrame * CFrame.new(0, 2 - i * 0.2, 0)
		p.Parent = m
	end
	roblox.Instance.new("Humanoid").Parent = m
	m.PrimaryPart = root
	return m
end
local MerBody = L.load("src/server/World/MerBody")
do
	local c = character(Vector3.new(0, 10, 0))
	local f = MerBody.build(c)
	check(f ~= nil and c:FindFirstChild("MerBody") ~= nil and c:GetAttribute("SeaForm") == "Piernas", "se monta escondido (empieza con piernas)")
	local n = MerBody.count(c)
	local mesh = 0
	for _, d in f:GetDescendants() do
		if d:IsA("MeshPart") or (d:IsA("SpecialMesh") and d.MeshType ~= roblox.Enum.MeshType.Sphere) then
			mesh += 1
		end
	end
	check(n >= 15 and n <= 30 and mesh == 0, ("%d piezas normales (cola, aleta, aletas de brazo, cresta, branquias, peto), sin mallas subidas"):format(n))
	check(f:FindFirstChild("Cola4") and f.Cola1:FindFirstChildOfClass("Motor6D") and f:FindFirstChild("Aleta") and f:FindFirstChild("AletaBrazo") and f:FindFirstChild("Cresta") and f:FindFirstChild("PetoNacar"), "cola de cuatro tramos con Motor6D, aleta, aletas en los antebrazos, cresta y peto de nácar")
	local quiet = true
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") and (d.CanCollide or d.CanQuery or d.CanTouch or not d.Massless or d.Transparency < 1) then
			quiet = false
		end
	end
	check(quiet, "sin choques, sin masa y escondido hasta que hay cola")
	c.LeftUpperLeg.Transparency = 0
	MerBody.setForm(c, "Cola")
	check(c:GetAttribute("SeaForm") == "Cola" and c.LeftUpperLeg.Transparency == 1 and c.RightFoot.Transparency == 1 and f.Cola1.Transparency == 0, "con cola: piernas escondidas y la cola a la vista")
	c.LeftUpperLeg.Transparency = 0 -- (otra ropa vuelve a enseñarla)
	MerBody.enforce(c)
	check(c.LeftUpperLeg.Transparency == 1, "si algo vuelve a enseñar una pierna con cola, se esconde otra vez")
	MerBody.setForm(c, "Piernas")
	check(c.LeftUpperLeg.Transparency == 0 and f.Cola1.Transparency == 1, "con piernas: todo como estaba")
	MerBody.remove(c)
	check(c:FindFirstChild("MerBody") == nil and c:GetAttribute("SeaForm") == nil, "se quita del todo (vuelta a la vida humana)")
end

---------------------------------------------------------------------
print("\n▶ La vida hondaria (Services/HondarioService)")
local profiles = {}
local testers = {}
local teleports = {}
local under = {}
local civCalls = {}
do
	L.services.Players = { GetPlayers = function()
		return {}
	end, PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end } }
	L.mock("src/server/Services/DataService", {
		get = function(p)
			return profiles[p]
		end,
		onLoaded = function() end,
	})
	L.mock("src/server/Services/TesterService", { isTester = function(p)
		return testers[p] == true
	end })
	L.mock("src/server/Services/SceneService", { teleportTo = function(p, pos)
		teleports[p] = pos
	end })
	L.mock("src/server/Services/DivingService", { underwater = function(p)
		return under[p] == true
	end })
	L.mock("src/server/Services/SeaCivService", {
		setHome = function(p, key, free)
			table.insert(civCalls, { "Home", key, free })
			return true
		end,
		startStory = function(p)
			table.insert(civCalls, { "Story" })
			return true
		end,
	})
	L.mock("src/server/Services/LocationService", { resolve = function(_, id)
		return if id == "Playa" then { Position = Vector3.new(-1750, 4, 3200) } else nil
	end })
	local HS = L.load("src/server/Services/HondarioService")
	local owner = L.player("Sebas", 1)
	local other = L.player("Otro", 2)
	testers[owner] = true
	local before = { X = 10, Y = 5, Z = 20 }
	profiles[owner] = { Life = { Stage = "Adulto" }, SpawnPoint = before, Sea = {} }
	profiles[other] = { Life = { Stage = "Adulto" } }
	owner.Character = character(Vector3.new(0, 10, 0))
	other.Character = character(Vector3.new(0, 10, 0))
	check(HS.enable(other, "Adulto") == false and profiles[other].Tester == nil and other:GetAttribute("Hondario") == nil, "a quien no es tester no le hace nada (ni guarda nada)")
	check(HS.enable(owner, "Nino") == true and HS.active(owner), "el tester empieza la vida hondaria")
	local h = profiles[owner].Tester.Hondario
	check(h.On == true and h.Home == Civ.DefaultHome and h.Prev.Stage == "Nino" and h.Prev.Spawn.X == 10, "se guarda en los ajustes del tester, con su etapa y su cama de antes (para devolverlas)")
	check(owner:GetAttribute("Hondario") == true and owner:GetAttribute("Gills") == true and owner:GetAttribute("HondarioHome") == Civ.DefaultHome, "atributos: Hondario, Gills (branquias) y su casa")
	local bed = Civ.bedPosition(Civ.HomeByKey[Civ.DefaultHome])
	local sp = profiles[owner].SpawnPoint
	check(sp and math.abs(sp.X - bed.X) < 0.2 and math.abs(sp.Z - bed.Z) < 0.2, "su punto de reaparición es la hamaca de su concha")
	check(teleports[owner] and (teleports[owner] - bed).Magnitude < 0.5 and Nacara.inDome(teleports[owner]), "aparece en su concha de Nácara (dentro, con aire)")
	check(Civ.districtAt(teleports[owner]).Id == "Nacara", "…en Nácara")
	check(#civCalls >= 2 and civCalls[1][1] == "Home" and civCalls[1][2] == Civ.DefaultHome and civCalls[1][3] == true and civCalls[#civCalls][1] == "Story", "la concha queda como su vivienda del mar (gratis) y empieza la historia del mar")
	check(owner.Character:FindFirstChild("MerBody") ~= nil, "se le monta el cuerpo hondario")
	-- la forma, sola
	local root = owner.Character.HumanoidRootPart
	root.CFrame = CFrame.new(Nacara.toWorld(60, 60, 12))
	under[owner] = true
	HS.step(owner, 0)
	check(owner.Character:GetAttribute("SeaForm") == "Piernas", "un instante bajo el agua no cambia aún (sin parpadeos)")
	HS.step(owner, MerForm.FormGrace + 0.1)
	check(owner.Character:GetAttribute("SeaForm") == "Cola" and owner.Character.LeftUpperLeg.Transparency == 1, "bajo el agua: cola (las piernas se esconden)")
	check(owner:GetAttribute("HondarioSafe") == "Nacara", "en Nácara: sin presión (HondarioSafe)")
	-- dentro de su concha: piernas
	root.CFrame = CFrame.new(bed)
	HS.step(owner, 10)
	HS.step(owner, 11)
	check(owner.Character:GetAttribute("SeaForm") == "Piernas", "dentro de la concha (aire): piernas, se anda")
	-- en tierra
	root.CFrame = CFrame.new(Vector3.new(0, 20, 0))
	under[owner] = false
	HS.step(owner, 20)
	HS.step(owner, 21)
	check(owner.Character:GetAttribute("SeaForm") == "Piernas" and owner:GetAttribute("HondarioSafe") == nil, "en tierra (Valmar): piernas, como siempre")
	-- forma humana
	root.CFrame = CFrame.new(Nacara.toWorld(60, 60, 12))
	under[owner] = true
	check(HS.setStayHuman(owner, true) == true and owner:GetAttribute("HondarioStayHuman") == true, "«Quedarme en forma humana» se enciende")
	HS.step(owner, 30)
	HS.step(owner, 31)
	check(owner.Character:GetAttribute("SeaForm") == "Piernas" and owner:GetAttribute("Gills") == true, "en forma humana bajo el agua: piernas, y sigue respirando")
	HS.setStayHuman(owner, false)
	HS.step(owner, 40)
	HS.step(owner, 41)
	check(owner.Character:GetAttribute("SeaForm") == "Cola", "al apagarlo, vuelve la cola")
	check(HS.setStayHuman(other, true) == nil, "a quien no vive la vida hondaria, el botón no le hace nada")
	-- si deja de ser tester, el ajuste guardado no vale
	testers[owner] = false
	check(not HS.active(owner), "si ya no es tester, lo guardado no le da nada")
	testers[owner] = true
	-- volver a la vida humana
	local ok, prev = HS.disable(owner)
	check(ok and prev == "Nino", "«Volver a vida humana» devuelve la etapa de antes (la pone TesterService)")
	check(profiles[owner].SpawnPoint and profiles[owner].SpawnPoint.X == 10 and profiles[owner].Tester.Hondario.On == false, "y su cama de antes")
	check(owner:GetAttribute("Hondario") == nil and owner:GetAttribute("Gills") == nil and owner.Character:FindFirstChild("MerBody") == nil and owner.Character.LeftUpperLeg.Transparency == 0, "sin atributos, sin cola, con sus piernas")
	check(teleports[owner] and teleports[owner].Y > -3, "y a tierra firme (la playa)")
	check(not HS.disable(owner), "pulsarlo otra vez no hace nada")
end

---------------------------------------------------------------------
print("\n▶ Respirar bajo el agua (Services/DivingService con branquias)")
do
	local remotes = {}
	local function remoteDouble()
		return { FireClient = function() end, FireServer = function() end, OnServerEvent = { Connect = function() end } }
	end
	remotes.Notify = remoteDouble()
	remotes.Diving = remoteDouble()
	rawset(L.services.ReplicatedStorage, "Remotes", remotes)
	L.mock("src/server/Services/FishingService", { isWater = function()
		return true
	end, levelOf = function()
		return 1
	end, toolsOf = function()
		return {}
	end })
	L.mock("src/server/Services/InventoryService", { count = function()
		return 0
	end })
	L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
	L.mock("src/server/Services/DivingService", nil)
	L.reset("src/server/Services/DivingService")
	local Diving = L.load("src/server/Services/DivingService")
	local p = L.player("Buzo", 3)
	local depthY = Nacara.FloorY + 6
	local fakeRoot = { Position = Vector3.new(Nacara.Center.X + 60, depthY, Nacara.Center.Z + 60) }
	local hum = { Health = 100, MaxHealth = 100 }
	p.Character = {
		FindFirstChild = function(_, n)
			return if n == "HumanoidRootPart" then fakeRoot else nil
		end,
		FindFirstChildOfClass = function()
			return hum
		end,
		GetScale = function()
			return 1
		end,
	}
	p:SetAttribute("Gills", true)
	p:SetAttribute("HondarioSafe", "Nacara")
	for _ = 1, 600 do
		Diving._breathe(p)
	end
	check(p:GetAttribute("Oxygen") == p:GetAttribute("OxygenMax") and hum.Health == 100, ("10 minutos a %.0f m sin equipo: el aire sigue lleno y no hay daño"):format(Ocean.meters(depthY)))
	check(p:GetAttribute("DivePressure") == "Ok" and p:GetAttribute("DiveLimit") == MerForm.Depth, ("sin aviso de presión; el límite que enseña el HUD es %d m"):format(MerForm.Depth))
	-- sin branquias, el mismo sitio ahoga
	local q = L.player("Humano", 4)
	q.Character = p.Character
	for _ = 1, 40 do
		Diving._breathe(q)
	end
	check((q:GetAttribute("Oxygen") or 0) <= 0 and hum.Health < 100, "sin el don, en el mismo sitio, el aire se acaba (como siempre)")
	local hud = fs.readFile("src/client/Controllers/DiveHud.luau")
	check(string.find(hud, 'GetAttribute("Gills")', 1, true) ~= nil, "el HUD de buceo enseña «Branquias» con la barra llena")
	local swim = fs.readFile("src/client/Controllers/Swimming.luau")
	check(string.find(swim, "MerForm.swimSpeed", 1, true) ~= nil and string.find(swim, '"SeaForm"', 1, true) ~= nil, "Swimming: con cola, nado más rápido con aceleración suave")
end

---------------------------------------------------------------------
print("\n▶ El cliente y el panel")
do
	L.mock("src/client/UI/Theme", setmetatable({}, { __index = function()
		return function() end
	end }))
	L.mock("src/client/UI/TopStack", { register = function() end, set = function() end, Priority = { World = 1 } })
	L.services.RunService = { RenderStepped = { Connect = function() end } }
	local ok, Client = pcall(L.load, "src/client/Controllers/MerForm")
	check(ok, "Controllers/MerForm se carga" .. (if ok then "" else ": " .. tostring(Client)))
	if ok then
		check(Client.hudText("Cola", false, "Nacara") == "🐚 Hondario · forma de cola · Nácara" and string.find(Client.hudText("Piernas", true, nil), "forma humana", 1, true) ~= nil, "el letrero dice quién eres: «🐚 Hondario · forma de cola · Nácara»")
		check(Client.toggleText(false) == "🧍 Quedarme en forma humana", "y el botón «Quedarme en forma humana»")
	end
	local panel = fs.readFile("src/client/UI/TesterPanel.luau")
	check(string.find(panel, '"HondarioLife"', 1, true) ~= nil and string.find(panel, '"HumanLife"', 1, true) ~= nil, "el panel de pruebas tiene «🐚 Nueva vida: Hondario» y «🧍 Volver a vida humana»")
	local tester = fs.readFile("src/server/Services/TesterService.luau")
	check(string.find(tester, 'a == "HondarioLife"', 1, true) ~= nil and string.find(tester, 'a == "HumanLife"', 1, true) ~= nil, "TesterService atiende las dos acciones (solo testers: handle lo comprueba primero)")
	local main = fs.readFile("src/server/Main.server.luau")
	check(string.find(main, '"HondarioService"', 1, true) ~= nil and string.find(main, '"SeaCivService"', 1, true) ~= nil, "Main.server arranca SeaCivService y HondarioService")
	local mc = fs.readFile("src/client/Main.client.luau")
	check(string.find(mc, "Controllers.MerForm", 1, true) ~= nil, "Main.client arranca MerForm")
end

L.finish("test-hondario")
