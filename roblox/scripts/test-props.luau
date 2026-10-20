-- Prueba de que no quedan piezas sueltas ni flotando por el mundo, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-props.luau                  # solo las reglas y el código
--   lune run scripts/test-props.luau /tmp/x.rbxl      # y además, el mapa construido (build-place)
--
-- Comprueba que:
--     (o que se cae del mapa) y nunca lo que tiene dueño: personas, vehículos enteros, juguetes…
--   * lo que se tira o se rompe se retira solo: piedras, cristales, puertas (se arreglan)
--   * romper de verdad (BreakService con piezas de mentira): balas, piedras, patadas y coches rompen
--     cristales y tiran puertas; escaparates por tramos; se arreglan a tiempo y nunca con alguien
--     en el hueco; topes; «Daños»
--   * helicópteros: el rotor avanza, el foco persigue con retraso y nunca encierra la cámara
--   * el tráfico y los peatones (que se copian de modelos en el origen, el cruce grande de Valmar
--     Centro) se ponen en su sitio en cuanto aparecen: nunca se quedan amontonados en el cruce
--   * los iconos de los guardias y limpiadores del metro (🛡️ 🧽) no se ven a través de paredes y techos
--   * en el mapa construido no hay ninguna pieza sin anclar (todo lo del mapa está quieto)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")


local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("El código")
local function src(path: string): string
	return fs.readFile(path)
end
local breaks = src("src/server/Services/BreakService.luau")
check(select(2, breaks:gsub("Debris:AddItem%(", "")) >= 3, "piedras caídas, cristales rotos y sonidos se retiran solos (Debris)")
check(breaks:find("BreakService.stepRepairs", 1, true) ~= nil, "lo roto (cristales y puertas) se vuelve a poner solo")
local stone = src("src/client/Controllers/StoneThrow.luau")
check(stone:find("if t > 5 then", 1, true) ~= nil, "la piedra en vuelo se quita como mucho a los 5 s")
local traffic = src("src/client/Controllers/Traffic.luau")
local respawn = traffic:match("local function respawn%(.-\nend\n") or ""
check(respawn:find("setActive(agent, true)\n\t\t\tplace(agent, pose(agent))", 1, true) ~= nil, "cada coche del tráfico se pone en su sitio en cuanto aparece (no en el origen)")
check(traffic:find("pcall(stepAgent", 1, true) ~= nil, "si un coche del tráfico falla, se retira ese (no se paran los demás)")
local ambient = src("src/client/Controllers/Ambient.luau")
local respawnPed = ambient:match("local function respawnPed%(.-\nend\n") or ""
check(respawnPed:find("posePed(agent", 1, true) ~= nil, "cada peatón se pone en su sitio en cuanto aparece (no en el origen)")
local metroLife = src("src/server/Services/MetroLifeService.luau")
local loud = 0
for line in metroLife:gmatch("[^\n]+") do
	if line:find("Npc.icon(", 1, true) and not line:find(", true)", 1, true) then
		loud += 1
	end
end
check(loud == 0, "los iconos del metro (🛡️ 🧽 🗿 👞) solo de cerca y sin verse a través de paredes")
local npc = src("src/server/World/Npc.luau")
check(npc:find("head.Position.Y < UNDERGROUND_Y", 1, true) ~= nil and npc:find("g.AlwaysOnTop = not hidden", 1, true) ~= nil, "bajo tierra (metro) ningún icono de NPC se ve a través de techos y vagones")
local combat = src("src/client/Controllers/CombatController.luau")
check(combat:find("CharacterRemoving", 1, true) ~= nil, "el 🛡 de quien se defiende se quita al reaparecer")

---------------------------------------------------------------------
-- Cristales y puertas que se rompen y se arreglan solos: BreakService DE VERDAD en un Roblox de
-- mentira (piezas con propiedades, padres, atributos y etiquetas; el resto, dobles que apuntan)
---------------------------------------------------------------------
print("Romper y arreglar (BreakService)")
local task = require("@lune/task")
local V3, CF, C3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local methods = {}
local meta = {}
meta.__index = function(self, k)
	local m = methods[k]
	if m then
		return m
	end
	local p = rawget(self, "_p")
	if k == "Position" then
		return p.CFrame.Position
	end
	return p[k]
end
meta.__newindex = function(self, k, v)
	local p = rawget(self, "_p")
	if k == "Parent" then
		local old = p.Parent
		if old then
			local kids = rawget(old, "_kids")
			local i = table.find(kids, self)
			if i then
				table.remove(kids, i)
			end
		end
		p.Parent = v
		if v then
			table.insert(rawget(v, "_kids"), self)
		end
		return
	end
	p[k] = v
end
local created: { [string]: number } = {}
local PART_CLASSES = { Part = true, WedgePart = true, MeshPart = true }
local function newInst(class: string)
	local self = setmetatable({
		_p = {
			ClassName = class, Name = class, Transparency = 0, CanCollide = true, CanQuery = true, CanTouch = true,
			Anchored = false, Color = C3.new(1, 1, 1), Material = Enum.Material.Plastic, Reflectance = 0,
			Size = V3.new(1, 1, 1), CFrame = CF.new(), AssemblyLinearVelocity = V3.zero, AssemblyAngularVelocity = V3.zero,
		},
		_kids = {},
		_attrs = {},
		_tags = {},
	}, meta)
	created[class] = (created[class] or 0) + 1
	return self
end
function methods:IsA(c)
	return c == self.ClassName or c == "Instance" or (c == "BasePart" and PART_CLASSES[self.ClassName] == true)
end
function methods:GetAttribute(k)
	return rawget(self, "_attrs")[k]
end
function methods:SetAttribute(k, v)
	rawget(self, "_attrs")[k] = v
end
function methods:HasTag(t)
	return rawget(self, "_tags")[t] == true
end
function methods:AddTag(t)
	rawget(self, "_tags")[t] = true
end
function methods:RemoveTag(t)
	rawget(self, "_tags")[t] = nil
end
function methods:GetChildren()
	return table.clone(rawget(self, "_kids"))
end
function methods:FindFirstChild(name)
	for _, c in rawget(self, "_kids") do
		if c.Name == name then
			return c
		end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(class, recursive)
	for _, c in rawget(self, "_kids") do
		if c:IsA(class) then
			return c
		end
		if recursive then
			local d = c:FindFirstChildWhichIsA(class, true)
			if d then
				return d
			end
		end
	end
	return nil
end
function methods:FindFirstChildOfClass(class)
	for _, c in rawget(self, "_kids") do
		if c.ClassName == class then
			return c
		end
	end
	return nil
end
function methods:FindFirstAncestorOfClass(class)
	local node = self.Parent
	while node do
		if node.ClassName == class then
			return node
		end
		node = node.Parent
	end
	return nil
end
function methods:Clone()
	local copy = newInst(self.ClassName)
	for k, v in rawget(self, "_p") do
		if k ~= "Parent" then
			rawget(copy, "_p")[k] = v
		end
	end
	for k, v in rawget(self, "_attrs") do
		rawget(copy, "_attrs")[k] = v
	end
	for k, v in rawget(self, "_tags") do
		rawget(copy, "_tags")[k] = v
	end
	return copy
end
function methods:Destroy()
	self.Parent = nil
	rawset(self, "_destroyed", true)
end
function methods:Play() end
function methods:GetFullName()
	return self.Name
end
function methods:IsDescendantOf(other)
	local node = self.Parent
	while node do
		if node == other then
			return true
		end
		node = node.Parent
	end
	return false
end

local world = newInst("Workspace")
local rayResult: any = nil
function methods:Raycast()
	return rayResult
end
local function signal()
	return { Connect = function() return { Disconnect = function() end } end, Fire = function() end }
end
local services = {
	CollectionService = {
		GetTags = function(_, inst)
			local list = {}
			for t in rawget(inst, "_tags") do
				table.insert(list, t)
			end
			return list
		end,
		GetTagged = function()
			return {}
		end,
	},
	Debris = { AddItem = function() end },
	Players = {
		GetPlayers = function()
			return {}
		end,
		GetPlayerFromCharacter = function()
			return nil
		end,
		PlayerAdded = signal(),
		PlayerRemoving = signal(),
	},
	RunService = { Heartbeat = signal() },
	TweenService = {
		Create = function(_, inst, _info, goals)
			return { Play = function()
				for k, v in goals do
					inst[k] = v
				end
			end }
		end,
	},
}
local crimes, swings = {}, {}
local mocks = {
	["src/server/World/Npc"] = { say = function() end },
	["src/server/Services/LocationService"] = { zoneAt = function() return "Valmar" end },
	["src/server/LifeStory/StoryEvents"] = { emit = function() end },
	["src/server/Services/WantedService"] = { crime = function(player, crime) table.insert(crimes, { Player = player, Crime = crime }) end },
	["src/server/Services/InteractService"] = { swing = function(part, open) table.insert(swings, { Part = part, Open = open }) part:SetAttribute("Open", open) end },
}
local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
services.ReplicatedStorage = { Shared = node("src/shared") }
local cache = {}
local function load(path: string)
	if mocks[path] then
		return mocks[path]
	end
	if cache[path] then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = { GetService = function(_, name) return services[name] end },
		workspace = world,
		task = task,
		Instance = { new = newInst },
		Vector3 = V3,
		CFrame = CF,
		Color3 = C3,
		Enum = Enum,
		TweenInfo = { new = function() return {} end },
		RaycastParams = { new = function() return {} end },
		typeof = function(v)
			if type(v) == "table" and rawget(v, "_p") then
				return "Instance"
			end
			return typeof(v)
		end,
		warn = function(...)
			print("      [warn]", ...)
		end,
	}, { __index = getfenv(1) })
	local result = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })()
	cache[path] = result
	return result
end
local okBreak, breakErr = pcall(function()
	local Breakables = load("src/shared/Breakables")
	local BreakService = load("src/server/Services/BreakService")
	local function pane(name: string, at: Vector3, size: Vector3, props: { [string]: any }?)
		local p = newInst("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = CF.new(at)
		p.Material = Enum.Material.Glass
		p.Transparency = 0
		for k, v in props or {} do
			p[k] = v
		end
		p.Parent = world
		return p
	end
	local function fakePlayer(name: string)
		local attrs = {}
		return { Name = name, UserId = #name, GetAttribute = function(_, k) return attrs[k] end, SetAttribute = function(_, k, v) attrs[k] = v end }
	end
	local shooter = fakePlayer("Tirador")
	local far = { V3.new(5000, 0, 5000) }

	-- Cristal normal a tiros
	local glass = pane("Glass", V3.new(0, 5, 0), V3.new(4, 6, 0.2))
	local before = created.WedgePart or 0
	check(BreakService.hitStructure(shooter, glass, glass.Position, V3.new(0, 0, -300), "Real") == "Glass", "una bala de verdad rompe la ventana")
	check(glass.Transparency == 1 and not glass.CanCollide and not glass.CanQuery and glass:GetAttribute("Broken") == true, "el hueco queda libre: no se ve, no choca (se puede pasar) y los rayos lo atraviesan")
	check((created.WedgePart or 0) - before >= 5, ("salen trozos de cristal con física (%d)"):format((created.WedgePart or 0) - before))
	local toy = pane("Glass", V3.new(10, 5, 0), V3.new(4, 6, 0.2))
	check(BreakService.hitStructure(shooter, toy, toy.Position, V3.new(0, 0, -300), "Toy") == nil and toy.Transparency == 0 and toy.CanCollide, "una pistola de agua o de pintura no lo rompe")
	local t0 = os.clock()
	BreakService.stepRepairs(t0 + Breakables.Repair.Glass[1] - 1, far)
	check(glass:GetAttribute("Broken") == true, ("a los %d s sigue roto"):format(Breakables.Repair.Glass[1] - 1))
	BreakService.stepRepairs(t0 + Breakables.Repair.Glass[2] + 0.5, { glass.Position + V3.new(0, -2, 1) })
	check(glass:GetAttribute("Broken") == true and not glass.CanCollide, "con alguien en el hueco no se arregla (no le encierra)")
	BreakService.stepRepairs(t0 + Breakables.Repair.Glass[2] + 3, far)
	check(glass:GetAttribute("Broken") == nil and glass.CanCollide and glass.CanQuery and glass.Transparency == 0, ("en cuanto se va, se arregla solo (de %d a %d s, apareciendo poco a poco)"):format(Breakables.Repair.Glass[1], Breakables.Repair.Glass[2]))

	-- Escaparate grande: se rompe por tramos y vuelve a ser una pieza
	local shop = pane("Glass", V3.new(0, 5, 40), V3.new(18, 10, 0.2))
	check(BreakService.hit(shooter, shop, shop.Position + V3.new(7, 0, 0), V3.new(0, 0, -50), "Stone") == "Glass", "una pedrada al escaparate grande")
	local info = BreakService._split[shop]
	check(info ~= nil and #info.Segments == 3, "se parte en tramos (18 studs: 3)")
	check(info ~= nil and info.Segments[3]:GetAttribute("Broken") == true and info.Segments[1]:GetAttribute("Broken") == nil and info.Segments[2]:GetAttribute("Broken") == nil, "solo se rompe el tramo donde das")
	check(shop.Transparency == 1 and not shop.CanCollide, "el escaparate entero se esconde mientras está partido")
	local tall = pane("Glass", V3.new(0, 5, 60), V3.new(12, 10.3, 0.2))
	BreakService.hit(fakePlayer("Otro"), tall, tall.Position + V3.new(-3, 0, 0), V3.new(0, 0, -50), "Stone")
	local tallSplit = BreakService._split[tall]
	check(tallSplit ~= nil and BreakService.kindOf(tallSplit.Segments[2]) == "Glass", "un tramo alto (6 × 10.3) se rompe entero, no se vuelve a partir")
	local function crimesOf(who)
		local list = {}
		for _, c in crimes do
			if c.Player == who then
				table.insert(list, c.Crime)
			end
		end
		return list
	end
	check(#crimesOf(shooter) == 1 and crimesOf(shooter)[1] == "Danos", "romperlo es «Daños» (si lo ve alguien: WantedService)")
	BreakService.hit(shooter, shop, shop.Position + V3.new(-7, 0, 0), V3.new(0, 0, -50), "Stone")
	check(#crimesOf(shooter) == 1, "no se denuncia otra vez enseguida (como mucho cada 90 s)")
	local gunman = fakePlayer("Pistolero")
	BreakService.hitStructure(gunman, pane("Glass", V3.new(40, 5, 0), V3.new(4, 6, 0.2)), V3.new(40, 5, 0), V3.new(0, 0, -300), "Real")
	check(#crimesOf(gunman) == 0, "a tiros no es «Daños» (ya es «Disparos en la vía pública»)")
	local chased = fakePlayer("Perseguido")
	chased:SetAttribute("Wanted", 4)
	BreakService.hit(chased, pane("Glass", V3.new(50, 5, 0), V3.new(4, 6, 0.2)), V3.new(50, 5, 0), V3.new(0, 0, -50), "Stone")
	check(#crimesOf(chased) == 0, "en plena huida (ya te buscan) romper para escapar no suma más estrellas")
	local segs = info and info.Segments or {}
	BreakService.stepRepairs(os.clock() + 40, far)
	task.wait(Breakables.FadeIn + 0.3)
	check(BreakService._split[shop] == nil and shop.Transparency == 0 and shop.CanCollide and shop:GetAttribute("Broken") == nil, "al arreglarse todos los tramos vuelve a ser una sola pieza")
	check(#segs > 0 and segs[1].Parent == nil, "y los tramos se quitan")

	-- Coche contra un escaparate
	local driver = fakePlayer("Conductor")
	local front = pane("ShopGlass", V3.new(0, 4, 80), V3.new(24, 6.5, 0.3), { CanCollide = false })
	check(BreakService.vehicleHit(driver, front, front.Position, V3.new(0, 0, -5), 3) == nil, "despacio, el coche no lo rompe")
	check(BreakService.vehicleHit(driver, front, front.Position, V3.new(0, 0, -35), 3) == "Glass", "a velocidad, lo atraviesa")
	local broke, dark = 0, true
	for _, seg in BreakService._split[front].Segments do
		if seg:GetAttribute("Broken") then
			broke += 1
			dark = dark and seg.Color ~= front.Color and seg.Transparency < 0.5
		end
	end
	check(dark, "pegado a la fachada: queda un hueco oscuro (no un agujero al vacío)")
	check(broke >= 1 and broke <= 2, ("rompe los tramos que toca el coche (%d)"):format(broke))

	-- Puerta: unos golpes y se cae; se arregla sola
	local door = pane("Door", V3.new(0, 3.5, 120), V3.new(4, 7, 0.4), { Material = Enum.Material.Wood })
	local hits = 0
	repeat
		hits += 1
		BreakService.hitStructure(shooter, door, door.Position, V3.new(0, 0, -300), "Real")
	until not door.Anchored or hits > 20
	check(hits == math.ceil(Breakables.DoorHealth / Breakables.DoorDamage.Bullet), ("la puerta aguanta y cae al balazo %d"):format(hits))
	check(not door.CanQuery and door:GetAttribute("Broken") == true, "caída: el hueco queda libre")
	BreakService.stepRepairs(os.clock() + Breakables.Repair.Door[1] - 1, far)
	check(not door.Anchored, ("a los %d s sigue en el suelo"):format(Breakables.Repair.Door[1] - 1))
	BreakService.stepRepairs(os.clock() + Breakables.Repair.Door[2] + 1, { door.Position })
	check(not door.Anchored, "con alguien en el umbral no vuelve")
	BreakService.stepRepairs(os.clock() + Breakables.Repair.Door[2] + 4, far)
	check(door.Anchored and door.CanCollide and door.CFrame.Position == V3.new(0, 3.5, 120), ("vuelve a su sitio sola (de %d a %d s)"):format(Breakables.Repair.Door[1], Breakables.Repair.Door[2]))
	local kicks = 0
	repeat
		kicks += 1
		BreakService.hit(shooter, door, door.Position, V3.new(0, 0, -30), "Melee")
	until not door.Anchored or kicks > 20
	check(kicks == math.ceil(Breakables.DoorHealth / Breakables.DoorDamage.Melee), ("a patadas también (%d)"):format(kicks))
	local rammed = pane("Door", V3.new(20, 3.5, 120), V3.new(4, 7, 0.4), { Material = Enum.Material.Wood })
	BreakService.vehicleHit(driver, rammed, rammed.Position, V3.new(0, 0, -30), 3)
	check(not rammed.Anchored, "un coche rápido la tira de una")

	-- Puerta de una sala por dentro: se abre de golpe y se vuelve a cerrar
	local inner = pane("DoorPanel", V3.new(0, 3.5, 160), V3.new(3, 7, 0.3), { Material = Enum.Material.Wood })
	inner:AddTag("Interact")
	inner:SetAttribute("Use", "Door")
	inner:SetAttribute("Hinge", CF.new(1.5, 3.5, 160))
	inner:SetAttribute("Closed", CF.new(0, 3.5, 160))
	for _ = 1, 4 do
		BreakService.hitStructure(shooter, inner, inner.Position, V3.new(0, 0, -300), "Real")
	end
	check(#swings == 1 and swings[1].Open == true and inner.Anchored, "la puerta de una sala se abre de golpe (no se cae)")
	BreakService.stepRepairs(os.clock() + 50, far)
	check(#swings == 2 and swings[2].Open == false, "y luego se vuelve a cerrar sola")
	local unit = pane("DoorPanel", V3.new(10, 3.5, 160), V3.new(3, 7, 0.3), { Material = Enum.Material.Wood })
	unit:AddTag("Interact")
	unit:AddTag("UnitDoor")
	unit:SetAttribute("Use", "Door")
	unit:SetAttribute("Hinge", CF.new())
	unit:SetAttribute("Closed", CF.new())
	check(BreakService.hitStructure(shooter, unit, unit.Position, V3.new(0, 0, -300), "Real") == nil, "la puerta de una vivienda (con dueño y llave) no")

	-- Golpes cuerpo a cuerpo
	local kick = pane("Glass", V3.new(0, 5, 200), V3.new(4, 6, 0.2))
	rayResult = { Instance = kick, Position = kick.Position, Normal = V3.new(0, 0, 1) }
	check(BreakService.meleeHit(shooter, V3.new(0, 5, 203), V3.new(0, 0, -1), 5, false) == nil and kick.Transparency == 0, "un puñetazo flojo no rompe el cristal")
	check(BreakService.meleeHit(shooter, V3.new(0, 5, 203), V3.new(0, 0, -1), 5, true) == "Glass", "el golpe fuerte sí")
	rayResult = nil

	-- Topes
	local vandal = fakePlayer("Vandalo")
	local count = 0
	for i = 1, 25 do
		if BreakService.hit(vandal, pane("Glass", V3.new(i * 10, 5, 300), V3.new(4, 6, 0.2)), V3.new(i * 10, 5, 300), V3.new(0, 0, -50), "Stone") then
			count += 1
		end
	end
	check(count == Breakables.Budget.PerPlayer, ("cada jugador rompe como mucho %d cosas en %d s (ha roto %d de 25)"):format(Breakables.Budget.PerPlayer, Breakables.Budget.Window, count))
	local keep = Breakables.Budget.MaxBroken
	Breakables.Budget.MaxBroken = 3
	local brokenNow = 0
	for _ in BreakService._broken do
		brokenNow += 1
	end
	BreakService.stepRepairs(os.clock(), far)
	local after = 0
	for _ in BreakService._broken do
		after += 1
	end
	check(after == brokenNow - 1, "si hay demasiadas cosas rotas, la más antigua se arregla ya")
	Breakables.Budget.MaxBroken = keep
end)
check(okBreak, "las pruebas de romper terminan sin errores" .. (if okBreak then "" else ": " .. tostring(breakErr)))

print("Helicópteros: rotores y foco (shared/Helicopter)")
local env = setmetatable({ Vector3 = roblox.Vector3 }, { __index = getfenv(1) })
local Helicopter = luau.load(fs.readFile("src/shared/Helicopter.luau"), { debugName = "Helicopter", environment = env })()
local angle, last = 0, 0
local moved = true
for frame = 1, 120 do
	local t = frame / 60
	local speed = Helicopter.rotorSpeed(t, Helicopter.MainRate)
	local nextAngle = Helicopter.advance(angle, 1 / 60, speed)
	if frame > 5 and nextAngle == angle then
		moved = false
	end
	last, angle = angle, nextAngle
end
check(moved and angle ~= 0, "el ángulo del rotor avanza cada fotograma")
check(Helicopter.rotorSpeed(0, Helicopter.MainRate) == 0 and Helicopter.rotorSpeed(Helicopter.SpinUp, Helicopter.MainRate) == Helicopter.MainRate, "arranca suave y llega a toda velocidad")
check(Helicopter.looksSmooth(Helicopter.MainRate, 30, 4) and Helicopter.looksSmooth(Helicopter.TailRate, 30, 2), "a 30 fps (móvil) se ve girar hacia delante, sin efecto estroboscópico")
local bladeA, discA = Helicopter.blur(1)
check(bladeA > 0.2 and discA < 1, "a toda velocidad: palas medio transparentes y disco borroso")
check(select(2, Helicopter.blur(0)) == 1, "parado, sin disco")
local spot = Helicopter.follow(V3.new(0, 0, 0), V3.new(10, 0, 0), 1 / 60)
check(spot.X > 0 and spot.X < 1, "la mancha del foco sigue al objetivo con retraso (no de golpe)")
local caught = V3.new(0, 0, 0)
for _ = 1, 120 do
	caught = Helicopter.follow(caught, V3.new(10, 0, 0), 1 / 60)
end
check((caught - V3.new(10, 0, 0)).Magnitude < 0.2, "…y en un par de segundos le alcanza")
local lamp, ground = V3.new(0, 90, 0), V3.new(30, 0, 0)
local r1 = Helicopter.spotRadius((ground - lamp).Magnitude)
check(r1 >= Helicopter.Light.MinRadius and r1 <= Helicopter.Light.MaxRadius, ("mancha de tamaño razonable (radio %.1f)"):format(r1))
local across, along = Helicopter.ellipse((ground - lamp).Unit, V3.new(0, 1, 0), r1)
check(along > across, "inclinado, la mancha es una elipse alargada")
check(Helicopter.insideBeam(lamp:Lerp(ground, 0.3), lamp, ground, 0.6, r1, 2), "una cámara en medio del haz cuenta como dentro (el haz se esconde)")
check(not Helicopter.insideBeam(ground + V3.new(0, 12, 14), lamp, ground, 0.6, r1, 2), "la cámara normal detrás del sospechoso: el haz se ve (su final ya está desvanecido)")
check(not Helicopter.insideBeam(V3.new(-60, 10, 40), lamp, ground, 0.6, r1, 2), "lejos del haz, fuera")
local safe = true
for i = 0, 20 do
	local cam = ground:Lerp(lamp, i / 20) + V3.new(0, 0, 0.5)
	local t = 1 - i / 20
	if t <= Helicopter.Light.Visible and not Helicopter.insideBeam(cam, lamp, ground, 0.6, r1, 2) then
		safe = false
	end
end
check(safe, "el foco nunca encierra la cámara: en cualquier punto visible del haz, se esconde")
check(Helicopter.lensAngle(r1, Helicopter.Light.LensBack) > 5 and Helicopter.Light.LensBack < Helicopter.Light.MaxRange, "la luz de verdad va cerca del suelo (dentro de su alcance) y cubre la mancha")
local heliSrc = src("src/server/World/PoliceUnits.luau")
check(not heliSrc:find('"Beam"', 1, true) and heliSrc:find('AddTag("Helicopter")', 1, true) ~= nil, "el helicóptero ya no lleva el cono blanco gigante: el foco lo dibuja cada pantalla")
local heliClient = src("src/client/Controllers/Helicopters.luau")
check(heliClient:find("LocalTransparencyModifier", 1, true) ~= nil and heliClient:find("insideBeam", 1, true) ~= nil, "los rotores giran en cada pantalla y el haz se esconde si la cámara está dentro")

local placePath = process.args[1]
if placePath then
	print("El mapa construido")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	-- (una pieza sin anclar unida con articulaciones a una anclada, como la gallina gigante, está quieta)
	local links: { [any]: { any } } = {}
	local function link(a: any, b: any)
		links[a] = links[a] or {}
		table.insert(links[a], b)
	end
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("JointInstance") or d.ClassName == "WeldConstraint" then
			local p0, p1 = (d :: any).Part0, (d :: any).Part1
			if p0 and p1 then
				link(p0, p1)
				link(p1, p0)
			end
		end
	end
	local function heldByAnchor(part: any): boolean
		local seen, queue = { [part] = true }, { part }
		while #queue > 0 do
			local p = table.remove(queue)
			if p.Anchored then
				return true
			end
			for _, q in links[p] or {} do
				if not seen[q] then
					seen[q] = true
					table.insert(queue, q)
				end
			end
		end
		return false
	end
	local loose, total = {}, 0
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") and d.ClassName ~= "Terrain" then
			total += 1
			if not d.Anchored and not heldByAnchor(d) then
				table.insert(loose, d:GetFullName())
			end
		end
	end
	for i = 1, math.min(#loose, 8) do
		print("      suelta: " .. loose[i])
	end
	check(total > 1000, ("hay mapa (%d piezas)"):format(total))
	check(#loose == 0, ("ninguna pieza del mapa sin anclar (%d sueltas)"):format(#loose))
end

print("")
if failures == 0 then
	print("✅ Piezas sueltas: todo correcto")
	process.exit(0) -- (sin esperar a los trozos de cristal pendientes de desvanecerse)
else
	print(("❌ Piezas sueltas: %d fallos"):format(failures))
	process.exit(1)
end
