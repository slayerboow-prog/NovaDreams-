-- Prueba de los «pelos volando» (fallo del dueño en v114, móvil: «Hay muchos pelos volando por todos
-- lados»: el pelo de bloques de un NPC —gorro + nuca + flequillo— solo en el aire, sin nadie debajo).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-pelos.luau
--
-- Comprueba, con personajes R15 de verdad (lib/FakeRig) vestidos por TODOS los vestidores del juego
-- (Npc.dress con pelo corto, melena, mochila y el disfraz de Cosme; OutfitBuilder con los 30 conjuntos
-- del pase y los 6 peinados; el aspecto de Valmar de AvatarService):
--   1. Cada pieza pegada al cuerpo lleva la etiqueta BodyPiece, va DENTRO de su personaje, sin anclar,
--      sin colisión, y soldada a una parte del cuerpo (no a otra pieza) de ESE personaje.
--   2. Moverlo, teletransportarlo, sentarlo, escalarlo: con las soldaduras resueltas como en Roblox,
--      ninguna pieza se queda atrás (cerca de su parte siempre).
--   3. Quitar el personaje (Destroy) no deja ninguna pieza en el mundo.
--   4. Barrendero del servidor (BodyPieceService): quita lo suelto (sin cabeza, fuera del personaje,
--      lejos de su parte dos vistazos seguidos), suelta el ancla, no toca lo sano ni lo que está fuera
--      del mundo, y avisa como mucho una vez por minuto.
--   5. Guardia del cliente (BodyPieceGuard): esconde en tu pantalla el pelo sin cabeza, el de una
--      cabeza invisible y el que se ha quedado atrás; lo vuelve a enseñar cuando vuelve a estar bien.
--   6. Todo está conectado: Main arranca el barrendero y el guardia; los vestidores marcan sus piezas;
--      quien crea un personaje con CreateHumanoidModelFromDescription lo hace atómico (llega entero) y
--      sus piezas las simula el servidor (Npc.serverOwned).

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local FakeRig = require("./lib/FakeRig")
local check = L.check

local CFrame, Vector3, Color3 = roblox.CFrame, roblox.Vector3, roblox.Color3
local Instance = L.Instance

local world = L.workspace
world.Name = "Workspace"

-- Servicios de mentira
L.services.Players = {
	CreateHumanoidModelFromDescription = function()
		return FakeRig.build(Instance)
	end,
	GetPlayers = function()
		return {}
	end,
}
L.services.TweenService = {
	Create = function()
		return { Play = function() end, Completed = { Wait = function() end, Connect = function() end } }
	end,
}
L.services.ServerStorage = Instance.new("Folder")
L.mock("src/server/World/RoadGuard", {})

local BodyPieces = L.load("src/shared/BodyPieces")
local Npc = L.load("src/server/World/Npc")
local OutfitBuilder = L.load("src/shared/OutfitBuilder")
local Outfits = L.load("src/shared/Outfits")
local CosmeLook = L.load("src/shared/CosmeLook")
pcall(CosmeLook._setIds, {})

-- Aspecto de Valmar (AvatarService._dress) con sus dependencias de mentira
L.mock("src/server/Services/DataService", { get = function()
	return { OwnAvatar = false }
end })
L.mock("src/server/Services/LifeService", { refresh = function() end })
local Avatar = L.load("src/server/Services/AvatarService")

local BodyPieceService = L.load("src/server/Services/BodyPieceService")
local BodyPieceGuard = L.load("src/client/Controllers/BodyPieceGuard")

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------
local function tagged(root: any): { any }
	local list = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag(BodyPieces.TAG) then
			table.insert(list, d)
		end
	end
	return list
end

local BODY = {}
for name in require("./lib/R15Rig").Sizes do
	BODY[name] = true
end

-- Piezas que NO son del cuerpo (todo lo que han añadido los vestidores)
local function added(model: any): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not BODY[d.Name] then
			table.insert(list, d)
		end
	end
	return list
end

-- Problemas de las piezas de un personaje (vacío = todo bien)
local function problems(model: any): { string }
	local bad = {}
	local function add(text: string)
		if #bad < 6 then
			table.insert(bad, text)
		end
	end
	for _, p in added(model) do
		local partner = BodyPieces.partnerOf(p)
		if not p:HasTag(BodyPieces.TAG) then
			add(p.Name .. " sin etiqueta BodyPiece")
		elseif not p:IsDescendantOf(model) or BodyPieces.characterOf(p) ~= model then
			add(p.Name .. " fuera de su personaje")
		elseif p.Anchored then
			add(p.Name .. " anclada")
		elseif p.CanCollide then
			add(p.Name .. " choca")
		elseif not partner or not partner:IsDescendantOf(model) or not BODY[partner.Name] then
			add(p.Name .. " no va soldada a una parte del cuerpo de su personaje")
		elseif p:GetAttribute(BodyPieces.ATTR) ~= partner.Name then
			add(p.Name .. " con BodyOn distinto de su parte")
		else
			local verdict = BodyPieces.verdict(BodyPieces.inspect(p, world))
			if verdict ~= "Keep" then
				add(p.Name .. " juzgada " .. verdict)
			end
		end
	end
	return bad
end

-- Las soldaduras como las resuelve Roblox: se apunta la unión al crearla y, tras mover el cuerpo, cada
-- pieza va donde dice su unión (Weld: Part0 * C0 * C1⁻¹; WeldConstraint: el desfase del momento en que
-- se soldó)
local function captureWelds(model: any): { [any]: any }
	local offsets = {}
	for _, p in added(model) do
		local partner = BodyPieces.partnerOf(p)
		if partner then
			offsets[p] = partner.CFrame:ToObjectSpace(p.CFrame)
		end
	end
	return offsets
end
local function solveWelds(model: any, offsets: { [any]: any })
	for p, offset in offsets do
		local partner = BodyPieces.partnerOf(p)
		if partner and p.Parent then
			p.CFrame = partner.CFrame * offset
		end
	end
end
-- Mueve el cuerpo (raíz + articulaciones) como el motor de Roblox: todas las partes del cuerpo con la
-- raíz; luego, las soldaduras
local function moveBody(model: any, to: any, offsets: { [any]: any })
	local root = model:FindFirstChild("HumanoidRootPart")
	local from = root.CFrame
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and BODY[d.Name] then
			d.CFrame = to * from:ToObjectSpace(d.CFrame)
		end
	end
	solveWelds(model, offsets)
end
local function maxGap(model: any): number
	local worst = 0
	for _, p in added(model) do
		local partner = BodyPieces.partnerOf(p)
		if partner then
			local info = BodyPieces.inspect(p, world)
			if info.Distance and info.Reach then
				worst = math.max(worst, info.Distance / info.Reach)
			end
		end
	end
	return worst
end

local function npcRig(look: any): any
	local model = FakeRig.build(Instance)
	model.Name = "Persona"
	Npc.dress(model, look)
	Npc.atomic(model)
	model.Parent = world
	Npc.serverOwned(model)
	return model
end

---------------------------------------------------------------------
print("▶ 1. Cada vestidor: piezas etiquetadas, dentro de su personaje, sin anclar y soldadas al cuerpo")
---------------------------------------------------------------------
local rigs: { { Name: string, Model: any } } = {}
local function addRig(name: string, model: any)
	table.insert(rigs, { Name = name, Model = model })
end

math.randomseed(7)
addRig("NPC pelo corto", npcRig({ LongHair = false, Hair = Color3.fromRGB(70, 45, 25) }))
addRig("NPC melena", npcRig({ LongHair = true }))
addRig("NPC niño con mochila", npcRig({ Backpack = Color3.fromRGB(220, 60, 60) }))
addRig("NPC al azar", npcRig(nil))
addRig("Cosme", npcRig({ Costume = "Cosme" }))
for _, style in { "Messy", "Short", "Long", "Wavy", "Ponytail", "Twin" } do
	local model = FakeRig.build(Instance)
	local folder = Instance.new("Folder")
	folder.Name = "ValmarLook"
	OutfitBuilder.hair(folder, model, style, Color3.fromRGB(74, 46, 30), L.Random.new(3), false)
	folder.Parent = model
	model.Parent = world
	addRig("Peinado " .. style, model)
end
for _, def in Outfits.List do
	local model = FakeRig.build(Instance)
	OutfitBuilder.dress(model, def, { Seed = 5, Ids = {} })
	model.Parent = world
	addRig("Conjunto " .. tostring(def.Key), model)
end
for _, stage in { "Bebe", "Nino", "Adolescente", "Adulto", "Mayor" } do
	local model = FakeRig.build(Instance)
	model.Parent = world
	local player = L.player("P" .. stage, 900 + #rigs)
	player:SetAttribute("LifeStage", stage)
	Avatar._dress(player, model)
	addRig("Aspecto de Valmar " .. stage, model)
end

local totalPieces = 0
local allOk = true
for _, r in rigs do
	local bad = problems(r.Model)
	totalPieces += #added(r.Model)
	if #bad > 0 then
		allOk = false
		check(false, r.Name .. ": " .. table.concat(bad, "; "))
	end
end
check(allOk, ("%d personajes vestidos, %d piezas: todas bien pegadas"):format(#rigs, totalPieces))
check(totalPieces > 500, "los vestidores ponen piezas de verdad (" .. totalPieces .. ")")
do
	local hairs = 0
	for _, p in added(rigs[1].Model) do
		if p.Name == "Hair" or p.Name == "HairBack" or p.Name == "Fringe" then
			hairs += 1
			check(BodyPieces.partnerOf(p) == rigs[1].Model:FindFirstChild("Head"), p.Name .. " del NPC soldado a SU cabeza")
		end
	end
	check(hairs == 3, "el pelo de la captura (gorro + nuca + flequillo) son 3 piezas")
end

---------------------------------------------------------------------
print("▶ 2. Moverse, teletransportarse, sentarse y cambiar de tamaño: nada se queda atrás")
---------------------------------------------------------------------
do
	local worst = 0
	for _, r in rigs do
		local offsets = captureWelds(r.Model)
		for _, to in {
			CFrame.new(40, 3, -25),
			CFrame.new(-900, 3, 1200) * CFrame.Angles(0, 2.2, 0), -- teletransporte lejos
			CFrame.new(-900, 1.6, 1200) * CFrame.Angles(0, 0.4, 0), -- sentado (raíz más baja)
			CFrame.new(10, 3, 10) * CFrame.Angles(0, 0, math.pi / 2), -- tumbado (atropello: Knock)
		} do
			moveBody(r.Model, to, offsets)
			worst = math.max(worst, maxGap(r.Model))
		end
		for _, p in added(r.Model) do
			if BodyPieces.verdict(BodyPieces.inspect(p, world)) ~= "Keep" then
				worst = math.huge
			end
		end
	end
	check(worst <= 1, ("tras andar, teletransportarse, sentarse y caerse, cada pieza sigue junto a su parte (peor %.2f del alcance)"):format(worst))
end

---------------------------------------------------------------------
print("▶ 3. Quitar el personaje no deja piezas sueltas en el mundo")
---------------------------------------------------------------------
do
	local before = #tagged(world)
	for i = #rigs, 1, -1 do
		if i % 2 == 0 then
			rigs[i].Model:Destroy()
			table.remove(rigs, i)
		end
	end
	local after = #tagged(world)
	local alive = 0
	for _, r in rigs do
		alive += #tagged(r.Model)
	end
	check(after == alive and after < before, ("al quitar la mitad de los personajes no queda ninguna pieza suya (%d → %d)"):format(before, after))
	check(#tagged(world) == alive, "todas las piezas que quedan son de personajes vivos")
end

---------------------------------------------------------------------
print("▶ 4. Barrendero del servidor (BodyPieceService)")
---------------------------------------------------------------------
do
	local healthy = #tagged(world)
	local removed = BodyPieceService.sweep(tagged(world), world)
	check(removed == 0 and #tagged(world) == healthy, "con todo sano no se quita nada (" .. healthy .. " piezas)")

	-- a) Pierde la cabeza (un recambio de piezas, un fallo): el pelo queda sin soldar
	local a = npcRig({ LongHair = false })
	local aHair = #tagged(a)
	a:FindFirstChild("Head"):Destroy()
	-- b) Una pieza que se ha salido de su personaje (a una carpeta del mapa)
	local b = npcRig({ LongHair = false })
	local loose = b:FindFirstChild("HairBack")
	local stray = Instance.new("Folder")
	stray.Name = "PlazaMayor"
	stray.Parent = world
	loose.Parent = stray
	-- c) Pelo que se ha quedado atrás (lejos de su cabeza)
	local c = npcRig({ LongHair = false })
	local behind = c:FindFirstChild("Hair")
	behind.CFrame = behind.CFrame + Vector3.new(0, 0, 120)
	-- d) Pieza anclada (no seguiría a su cabeza)
	local d = npcRig({ LongHair = false })
	local stuck = d:FindFirstChild("Fringe")
	stuck.Anchored = true
	-- e) Fuera del mundo (los del colegio fuera de horario): no se toca aunque esté «suelta»
	local e = FakeRig.build(Instance)
	Npc.dress(e, { LongHair = false })
	e.Parent = L.services.ServerStorage
	e:FindFirstChild("Head"):Destroy()

	local first = BodyPieceService.sweep(tagged(world), world)
	local headless = 0
	for _, p in a:GetDescendants() do
		if p:IsA("BasePart") and (p.Name == "Hair" or p.Name == "HairBack" or p.Name == "Fringe") then
			headless += 1
		end
	end
	check(headless == 0, ("sin cabeza: su pelo se quita (%d piezas)"):format(aHair))
	check(loose.Parent == nil, "la pieza fuera de su personaje se quita")
	check(behind.Parent ~= nil, "la que se ha quedado atrás aguanta un vistazo (un tirón no cuenta)")
	check(stuck.Parent ~= nil and stuck.Anchored == false, "la anclada se suelta (no se borra)")
	local second = BodyPieceService.sweep(tagged(world), world)
	check(behind.Parent == nil, "…y al segundo vistazo seguido, se quita")
	check(#tagged(e) > 0, "lo que está fuera del mundo no se toca")
	check(first >= aHair - 1 and second == 1, ("cuenta lo quitado (%d + %d)"):format(first, second))
	check(BodyPieceService.sweep(tagged(world), world) == 0, "después, todo sano: nada más que quitar")

	-- Aviso limitado (como mucho uno por minuto, con lo acumulado)
	local log = BodyPieces.Log("Prueba", 60)
	check(log.flush(0) == nil, "sin nada quitado, no avisa")
	log.add(3)
	local text = log.flush(100)
	check(text ~= nil and text:find("3 pieza", 1, true) ~= nil, "avisa con cuántas: " .. tostring(text))
	log.add(2)
	check(log.flush(130) == nil, "no vuelve a avisar antes de un minuto")
	log.add(4)
	local later = log.flush(161)
	check(later ~= nil and later:find("6 pieza", 1, true) ~= nil and later:find("total 9", 1, true) ~= nil, "al minuto, lo acumulado y el total: " .. tostring(later))
	check(BodyPieceService._log.Total >= first + second, "el barrendero lleva la cuenta (" .. BodyPieceService._log.Total .. ")")
end

---------------------------------------------------------------------
print("▶ 5. Guardia del cliente (BodyPieceGuard)")
---------------------------------------------------------------------
-- (Lune no da valor por defecto a LocalTransparencyModifier: 0 si no se ha puesto)
local function ltm(p: any): number
	local ok, v = pcall(function()
		return p.LocalTransparencyModifier
	end)
	return if ok and type(v) == "number" then v else 0
end
do
	local m = npcRig({ LongHair = false })
	local hair = m:FindFirstChild("Hair")
	local head = m:FindFirstChild("Head")
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(hair) == 0, "sano: el pelo se ve")
	head.Transparency = 1
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(hair) == 1, "cabeza invisible: el pelo tampoco se ve")
	head.Transparency = 0
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(hair) == 0, "la cabeza vuelve a verse: el pelo también")
	hair.CFrame = hair.CFrame + Vector3.new(80, 0, 0)
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(hair) == 1, "pelo que se ha quedado atrás: escondido en tu pantalla")
	hair.CFrame = hair.CFrame - Vector3.new(80, 0, 0)
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(hair) == 0, "vuelve a su sitio: se enseña")
	-- La carga por zonas se lleva la cabeza (o aún no la ha traído): sin ella, el pelo no se ve
	local back = m:FindFirstChild("HairBack")
	head.Parent = nil
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(back) == 1 and ltm(hair) == 1, "sin la cabeza en tu pantalla: su pelo escondido")
	head.Parent = m
	BodyPieceGuard.check(tagged(world), world)
	check(ltm(back) == 0, "llega la cabeza: el pelo vuelve")
	local other = Instance.new("Part")
	other.LocalTransparencyModifier = 0.5
	other.Parent = world
	BodyPieceGuard.check({ other }, world)
	check(ltm(other) == 0.5, "no toca lo que no es una pieza del cuerpo… (ni las que no escondió)")
	check(BodyPieceGuard.shouldHide("Hidden") and BodyPieceGuard.shouldHide("NoWeld") and not BodyPieceGuard.shouldHide("Keep") and not BodyPieceGuard.shouldHide("Anchored"), "esconde Hidden/NoWeld/NoCharacter/Far, nunca lo sano")
end

---------------------------------------------------------------------
print("▶ 6. Todo conectado")
---------------------------------------------------------------------
local function src(path: string): string
	return fs.readFile(path)
end
do
	local main = src("src/server/Main.server.luau")
	check(main:find('"BodyPieceService"', 1, true) ~= nil, "el servidor arranca el barrendero (BodyPieceService)")
	local client = src("src/client/Main.client.luau")
	check(client:find("Controllers.BodyPieceGuard", 1, true) ~= nil, "el cliente arranca el guardia (BodyPieceGuard)")
	-- Cada soldadura de pieza de un vestidor marca la pieza
	for _, path in {
		"src/server/World/Npc.luau",
		"src/shared/OutfitBuilder.luau",
		"src/shared/CosmeLook.luau",
		"src/server/Services/AvatarService.luau",
		"src/server/Services/CareerService.luau",
		"src/server/Services/PlaceLifeService.luau",
	} do
		local text = src(path)
		local welds = 0
		for _ in text:gmatch('Instance%.new%("Weld[C]?o?n?s?t?r?a?i?n?t?"%)') do
			welds += 1
		end
		local marks = 0
		for _ in text:gmatch("%.mark%(") do
			marks += 1
		end
		check(marks >= 1, path .. ": sus piezas llevan la etiqueta BodyPiece (" .. marks .. " de " .. welds .. " soldaduras)")
	end
	-- Quien crea un personaje de Roblox lo hace atómico (llega entero a cada pantalla)
	for _, path in {
		"src/server/World/Npc.luau",
		"src/server/Services/SceneService.luau",
		"src/server/Services/SchoolService.luau",
		"src/server/LifeStory/StageActors.luau",
	} do
		local text = src(path)
		check(text:find("CreateHumanoidModelFromDescription", 1, true) ~= nil and (text:find("atomic(", 1, true) ~= nil or text:find("atomic,", 1, true) ~= nil), path .. ": personaje atómico")
		check(text:find("serverOwned", 1, true) ~= nil, path .. ": sus piezas las simula el servidor (Npc.serverOwned)")
	end
	local npc = src("src/server/World/Npc.luau")
	local create = npc:match("function Npc%.create.-\nend")
	check(create ~= nil and create:find("model.Parent = parent", 1, true) ~= nil and create:find("Npc.serverOwned(model)", 1, true) ~= nil and create:find("Npc.serverOwned(model)", 1, true) > create:find("model.Parent = parent", 1, true), "Npc.create: dueño servidor DESPUÉS de ponerlo en el mundo")
	check(create ~= nil and create:find("Npc.atomic(model)", 1, true) ~= nil and create:find("Npc.dress(model, look)", 1, true) ~= nil, "Npc.create: atómico y vestido antes de colocarlo")
	check(pcall(Npc.serverOwned, rigs[1].Model), "Npc.serverOwned no falla (sin física: no hace nada)")
end

L.finish("test-pelos")
