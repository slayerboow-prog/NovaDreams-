-- Prueba: nadie se queda BAJO TIERRA ni atascado (el fallo de la gallina gigante), FUERA de Roblox,
-- con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-underground.luau
--
-- Lo que pasó: Petra (la gallina de seis metros) te atrapaba y te mandaba al "Respawn" del combate,
-- que era el silo de la granja (un modelo): te dejaba DENTRO del silo / bajo el suelo, sin poder
-- moverte; ese sitio se guardaba y al volver a entrar aparecías otra vez enterrado. Y el rayo
-- encogedor no estaba en tu mochila. Comprueba:
--   * Shared/SafeGround: sitios guardados válidos, búsqueda del sitio libre más cercano (al lado del
--     silo, no dentro ni encima de su tejado; si estás enterrado, el suelo de encima), dónde te deja
--     quien te atrapa, cuánto hay que esperar para rescatar, lo que no sobrevive a un guardado
--   * World/SafeSpot en un mundo de mentira (terreno macizo bajo y = 0, el silo): detecta a quien está
--     enterrado o dentro del silo, le saca de pie sobre el suelo y le devuelve el poder andar
--     (velocidad, salto, sin anclar, sin PlatformStand)
--   * Services/SceneService: la captura es segura (te deja en el suelo, quien te atrapa descansa y
--     se aparta, nada te deja anclado, seguro a los pocos segundos) y nunca salta encima de ti
--   * La misión: el combate te presta el rayo encogedor (en la barra) y la huida vuelve al patio

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Enum, Color3 = roblox.Vector3, roblox.CFrame, roblox.Enum, roblox.Color3
local V = Vector3.new

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function loadWith(path: string, env: { [string]: any }): any
	local e = setmetatable(env, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local base = { Vector3 = Vector3, CFrame = CFrame, Enum = Enum, Color3 = Color3 }

-- Carga un módulo de src/ con sus require de verdad (script.Parent.X → el archivo)
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
local cache = {}
local function loadModule(path: string): any
	if cache[path] == nil then
		local env = table.clone(base)
		env.script = node(path)
		env.Vector2, env.UDim2, env.NumberRange, env.NumberSequence, env.ColorSequence = roblox.Vector2, roblox.UDim2, roblox.NumberRange, roblox.NumberSequence, roblox.ColorSequence
		env.require = function(target)
			return loadModule(rawget(target, "__path"))
		end
		cache[path] = loadWith(path .. ".luau", env)
	end
	return cache[path]
end
local SafeGround = loadWith("src/shared/SafeGround.luau", table.clone(base))

---------------------------------------------------------------------
print("\n▶ SafeGround: sitios guardados")
---------------------------------------------------------------------
check(SafeGround.validSaved({ X = 10, Y = 3, Z = -4, Yaw = 1 }), "un sitio normal vale")
check(not SafeGround.validSaved({ X = 0 / 0, Y = 3, Z = 0 }), "NaN no vale")
check(not SafeGround.validSaved({ X = 1, Y = "3", Z = 0 }), "sin números no vale")
check(not SafeGround.validSaved({ X = 1, Y = -400, Z = 0 }), "debajo de todo el mapa no vale")
check(SafeGround.validSaved({ X = 1, Y = -60, Z = 0 }), "el andén del metro (-42 / -66) sí vale")
check(not SafeGround.validSaved({ X = 1e9, Y = 3, Z = 0 }), "un número enorme no vale")
local broken = { Position = { X = 0 / 0, Y = 1, Z = 1 }, SpawnPoint = { X = 1, Y = 3, Z = 1 } }
local fixed = SafeGround.repairSaved(broken)
check(broken.Position == nil and broken.SpawnPoint ~= nil and #fixed == 1, "al cargar, una partida con el sitio roto se arregla (se tira el sitio, la cama se queda)")
local prog = { Step = 6, Count = 0, Caught = 3, Grabbed = true, GrabbedAt = 123, Frozen = true }
check(SafeGround.cleanProgress(prog) and prog.Grabbed == nil and prog.Frozen == nil and prog.Step == 6 and prog.Caught == 3, "una misión guardada en plena captura no carga la captura (sigue en su paso)")

---------------------------------------------------------------------
print("\n▶ SafeGround: el sitio libre más cercano")
---------------------------------------------------------------------
-- Mundo de cuentas: suelo (terreno) en y = 0 en todas partes, macizo de -8 a 0. El silo: cilindro de
-- radio 5 de y = 0.6 a 34.6 con base de 11 × 11 y tejado (bola) hasta y = 39.8.
local function inSilo(p: Vector3): boolean
	local r = math.sqrt(p.X ^ 2 + p.Z ^ 2)
	return (r < 5 and p.Y > 0.6 and p.Y < 34.6) or (math.abs(p.X) < 5.5 and math.abs(p.Z) < 5.5 and p.Y >= 0 and p.Y <= 0.6)
		or (V(p.X, p.Y - 34.6, p.Z).Magnitude < 5.2)
end
local function inGround(p: Vector3): boolean
	return p.Y < 0 and p.Y > -8
end
local pureWorld = {
	groundAt = function(x: number, z: number, fromY: number): number?
		local start = V(x, fromY, z)
		local r = math.sqrt(x * x + z * z)
		-- (un rayo que empieza dentro de algo no lo ve: así es Roblox)
		local inside = inSilo(start)
		if r < 5.2 and not inside and fromY > 39.8 - (5.2 - math.sqrt(5.2 ^ 2 - r ^ 2)) then
			return 34.6 + math.sqrt(5.2 ^ 2 - r ^ 2) -- tejado
		end
		if math.abs(x) < 5.5 and math.abs(z) < 5.5 and fromY > 0.6 and (not inside or r < 5) then
			return 0.6 -- base del silo
		end
		if fromY > 0 then
			return 0
		end
		return nil -- (desde dentro del terreno)
	end,
	free = function(feet: Vector3): boolean
		for _, y in { 0.8, 2, 3.5, 5 } do
			local p = feet + V(0, y, 0)
			if inSilo(p) or inGround(p) then
				return false
			end
			for _, d in { V(0.8, 0, 0), V(-0.8, 0, 0), V(0, 0, 0.5), V(0, 0, -0.5) } do
				if inSilo(p + d) then
					return false
				end
			end
		end
		return true
	end,
}
local siloSpot = SafeGround.findSpot(V(0, 0.6, 0), pureWorld)
check(siloSpot and math.sqrt(siloSpot.X ^ 2 + siloSpot.Z ^ 2) > 5.5 and siloSpot.Y < 1, ("ir «al silo» te deja AL LADO del silo, en el suelo (%s), no dentro ni en su tejado"):format(tostring(siloSpot)))
local buriedSpot = SafeGround.findSpot(V(40, -5, 40), pureWorld)
check(buriedSpot and math.abs(buriedSpot.Y) < 0.01 and (V(buriedSpot.X, 0, buriedSpot.Z) - V(40, 0, 40)).Magnitude < 1, "enterrado bajo el terreno: el suelo justo encima de ti")
local open = SafeGround.findSpot(V(60, 0, 60), pureWorld)
check(open and (open - V(60, 0, 60)).Magnitude < 0.01, "en un sitio libre: ahí mismo")
local nothing = SafeGround.findSpot(V(0, 0, 0), { groundAt = function()
	return nil
end, free = function()
	return true
end })
check(nothing == nil, "sin suelo en ningún sitio (agua, el vacío): nil (y entonces, a la cama o a la entrada)")

---------------------------------------------------------------------
print("\n▶ SafeGround: la captura")
---------------------------------------------------------------------
local hen, me = V(0, 7, 0), V(5, 3, 0)
local drop = SafeGround.dropPoint(hen, me)
check((drop - me).Magnitude > 10 and drop.X > me.X, "quien te atrapa te deja a unos pasos, lejos de él")
check(SafeGround.CatchCooldown >= 5 and SafeGround.StartGrace >= 3, "tras atraparte descansa (≥ 5 s) y al empezar hay ventaja (≥ 3 s)")
local state = {}
check(not SafeGround.track(state, true, 10) and not SafeGround.track(state, true, 11.5), "enterrado un momento: aún no se rescata")
check(SafeGround.track(state, true, 12.1), "enterrado más de 2 s: se rescata")
check(not SafeGround.track(state, false, 13) and state.Since == nil, "si sale solo, la cuenta empieza de cero")
local changes = SafeGround.restoreHumanoid({ WalkSpeed = 0, JumpPower = 0, UseJumpPower = true, PlatformStand = true, Sit = true, Anchored = true })
check(changes.WalkSpeed == 16 and changes.JumpPower == 50 and changes.PlatformStand == false and changes.Sit == false and changes.Anchored == false, "un humanoide atascado vuelve a andar y saltar (16 y 50)")
check(next(SafeGround.restoreHumanoid({ WalkSpeed = 20, JumpHeight = 7.2, UseJumpPower = false })) == nil, "a uno que anda bien no se le toca")

---------------------------------------------------------------------
print("\n▶ World/SafeSpot en un mundo de mentira (terreno y silo)")
---------------------------------------------------------------------
local function fakePart(name: string)
	local part = { Name = name, CanCollide = true, Anchored = true, Parent = true }
	function part:IsA(class)
		return class == "BasePart" or class == "Part" or (class == "Terrain" and name == "Terrain")
	end
	function part:FindFirstAncestorOfClass()
		return nil
	end
	return part
end
local terrainPart = fakePart("Terrain")
local siloPart = fakePart("SiloCuerpo")
siloPart.Size = V(34, 10, 10)
local terrain = {
	ReadVoxels = function(_, region, _res)
		local c = region.CFrame.Position
		local solid = c.Y < 0 and c.Y > -8
		return { { { if solid then Enum.Material.Grass else Enum.Material.Air } } }, { { { if solid then 1 else 0 } } }
	end,
}
local players = {}
local fakeWorkspace = {}
function fakeWorkspace:Raycast(origin, direction)
	local y = pureWorld.groundAt(origin.X, origin.Z, origin.Y)
	if not y or origin.Y + direction.Y > y then
		return nil
	end
	return { Position = V(origin.X, y, origin.Z), Instance = if y == 0 then terrainPart else siloPart, Material = Enum.Material.Grass, Normal = V(0, 1, 0) }
end
function fakeWorkspace:FindFirstChild()
	return nil
end
function fakeWorkspace:FindFirstChildOfClass(class)
	return if class == "Terrain" then terrain else nil
end
function fakeWorkspace:FindFirstChildWhichIsA()
	return { Position = V(200, 0.5, 200), Size = V(6, 1, 6), Parent = true }
end
function fakeWorkspace:GetPartsInPart(probe)
	local cf, size = probe.CFrame, probe.Size
	for _, dx in { -0.5, 0, 0.5 } do
		for _, dy in { -0.5, 0, 0.5 } do
			for _, dz in { -0.5, 0, 0.5 } do
				if inSilo(cf * V(size.X * dx, size.Y * dy, size.Z * dz)) then
					return { siloPart }
				end
			end
		end
	end
	return {}
end
local services = {
	Players = { GetPlayers = function()
		return players
	end },
	ReplicatedStorage = { Shared = { Ground = "src/shared/Ground.luau", SafeGround = "src/shared/SafeGround.luau" } },
}
local env = table.clone(base)
env.game = { GetService = function(_, name)
	return services[name]
end }
env.workspace = fakeWorkspace
env.RaycastParams = { new = function()
	return { FilterDescendantsInstances = {} }
end }
env.OverlapParams = { new = function()
	return { FilterDescendantsInstances = {} }
end }
env.Region3 = { new = function(a, b)
	return { CFrame = CFrame.new((a + b) / 2), Size = b - a }
end }
env.Instance = { new = function(class)
	return { ClassName = class }
end }
env.require = function(path)
	return loadWith(path, table.clone(env))
end
local SafeSpot = loadWith("src/server/World/SafeSpot.luau", table.clone(env))

-- Un personaje R15 de mentira (y atascado: anclado, quieto, tumbado, sin saltar)
local function fakeCharacter(at: Vector3)
	local root = { Name = "HumanoidRootPart", Size = V(2, 2, 1), Anchored = true, AssemblyLinearVelocity = V(0, -50, 0), AssemblyAngularVelocity = V() }
	root.Position = at
	root.CFrame = CFrame.new(at)
	function root:IsA(class)
		return class == "BasePart"
	end
	local humanoid = { WalkSpeed = 0, JumpPower = 0, JumpHeight = 0, UseJumpPower = true, PlatformStand = true, Sit = false, SeatPart = nil, HipHeight = 2, RigType = Enum.HumanoidRigType.R15, State = Enum.HumanoidStateType.PlatformStanding }
	function humanoid:GetState()
		return self.State
	end
	function humanoid:ChangeState(s)
		self.State = s
	end
	local character = { Root = root, Humanoid = humanoid }
	function character:FindFirstChild(name)
		return if name == "HumanoidRootPart" then root else nil
	end
	function character:FindFirstChildOfClass(class)
		return if class == "Humanoid" then humanoid else nil
	end
	function character:GetChildren()
		return { root }
	end
	function character:GetAttribute()
		return nil
	end
	function character:PivotTo(cf)
		root.CFrame = cf
		root.Position = cf.Position
	end
	return character
end

local standing = fakeCharacter(V(30, 3, 30))
check(not SafeSpot.buried(standing :: any), "de pie sobre el suelo: no está enterrado")
local underground = fakeCharacter(V(20, -4, 20))
check(SafeSpot.buried(underground :: any), "con el cuerpo dentro del terreno: enterrado")
local inside = fakeCharacter(V(0, 3.6, 0))
check(SafeSpot.buried(inside :: any), "dentro del silo: enterrado (dentro de algo sólido)")
local fallen = fakeCharacter(V(20, -300, 20))
check(SafeSpot.buried(fallen :: any), "cayendo por debajo de todo el mapa: también")
check(not SafeSpot.free(V(0, 0.6, 0)) and SafeSpot.free(V(30, 0, 30)), "dentro del silo no cabes; en el patio sí")
check(SafeSpot.stuckAt(V(0, 0.6, 0)) and SafeSpot.stuckAt(V(20, -6, 20)) and not SafeSpot.stuckAt(V(30, 0, 30)), "llevarte «al silo» o bajo el terreno te dejaría atrapado (y se busca otro hueco); al patio, no")

local function rescued(character, label: string)
	local player = { Character = character, RequestStreamAroundAsync = function() end }
	local at = SafeSpot.rescue(player :: any)
	local root, humanoid = character.Root, character.Humanoid
	check(at ~= nil and not SafeSpot.buried(character) and root.Position.Y > 2.5 and root.Position.Y < 5, ("%s: sale de pie sobre el suelo (raíz a y = %.1f)"):format(label, root.Position.Y))
	check(root.Anchored == false and humanoid.WalkSpeed == 16 and humanoid.JumpPower == 50 and humanoid.PlatformStand == false and humanoid.State ~= Enum.HumanoidStateType.PlatformStanding, label .. ": y puede andar y saltar (sin anclar, sin PlatformStand)")
	check(root.AssemblyLinearVelocity.Magnitude < 0.01, label .. ": sin la velocidad de la caída")
	return at
end
local a1 = rescued(underground, "enterrado bajo el terreno")
check(a1 and (V(a1.X, 0, a1.Z) - V(20, 0, 20)).Magnitude < 1, "  …en el mismo sitio, justo encima")
local a2 = rescued(inside, "dentro del silo")
check(a2 and math.sqrt(a2.X ^ 2 + a2.Z ^ 2) > 5.5 and a2.Y < 1, "  …al lado del silo, no en su tejado")
local a3 = rescued(fallen, "caído bajo el mapa")
check(a3 and (V(a3.X, 0, a3.Z) - V(200, 0, 200)).Magnitude < 1, "  …a la entrada del juego (no tenía cama)")

---------------------------------------------------------------------
print("\n▶ El código: captura segura, vigilante y rayo")
---------------------------------------------------------------------
local scene = fs.readFile("src/server/Services/SceneService.luau")
local story = fs.readFile("src/server/Services/LifeStoryService.luau")
local position = fs.readFile("src/server/Services/PositionService.luau")
local gadget = fs.readFile("src/server/Services/GadgetService.luau")
local function body(src: string, header: string): string
	local start = string.find(src, header, 1, true)
	if not start then
		return ""
	end
	local stop = string.find(src, "\nfunction ", start + #header, true) or string.find(src, "\nlocal function ", start + #header, true) or #src
	return string.sub(src, start, stop)
end
local catch = body(scene, "function SceneService.catch(")
check(catch ~= "" and string.find(catch, "teleportTo", 1, true) and string.find(catch, "SafeSpot.release", 1, true)
	and string.find(catch, "task.delay(SafeGround.ReleaseSeconds", 1, true) and string.find(catch, "SafeSpot.rescue", 1, true), "SceneService.catch: te deja en el suelo libre, te suelta y a los pocos segundos lo comprueba otra vez")
check(not string.find(catch, "Anchored = true", 1, true) and not string.find(catch, "PlatformStand = true", 1, true) and not string.find(catch, "WalkSpeed = 0", 1, true), "la captura nunca te ancla ni te deja quieto")
check(string.find(catch, "RestUntil", 1, true) ~= nil, "quien te atrapa descansa y se aparta (no se queda esperándote al reaparecer)")
local teleport = body(scene, "function SceneService.teleportTo(")
check(string.find(teleport, "SafeSpot.stuckAt", 1, true) ~= nil and string.find(teleport, "SafeSpot.find", 1, true) ~= nil, "cualquier teletransporte de la historia va a un hueco libre (nunca dentro de un modelo como el silo)")
check(not string.find(scene, "PivotTo(CFrame.new(root.Position + offset.Unit * 6", 1, true) and not string.find(scene, "PivotTo(CFrame.new(me.Position - offset.Unit * 25", 1, true), "el que te persigue ya no salta ENCIMA de ti cuando se atasca")
local caughtFn = body(scene, "function SceneService.caught(")
check(string.find(caughtFn, "GraceUntil", 1, true) and string.find(caughtFn, "RestUntil", 1, true), "no te atrapa al empezar (ventaja) ni mientras descansa")
local tickStart = string.find(story, 'elseif step.Type == "Escape" or step.Type == "Fight" then', 1, true) or 1
local tick = string.sub(story, tickStart, (string.find(story, 'elseif step.Type == "Wait" then', tickStart, true) or tickStart))
check(string.find(tick, "SceneService.catch(", 1, true) and not string.find(tick, "SceneService.teleport(player, step.Respawn)", 1, true), "la historia usa la captura segura (antes: te mandaba al Respawn del combate, DENTRO del silo)")
check(string.find(tick, "ensureWeapon(", 1, true) ~= nil, "durante el combate, si pierdes el arma prestada (reaparecer, volver a entrar) se te vuelve a dar")
check(string.find(position, "SafeSpot.buried", 1, true) and string.find(position, "PositionService.checkBuried", 1, true) and string.find(position, "SafeGround.repairSaved", 1, true), "PositionService: no apunta sitios enterrados, arregla las partidas rotas y vigila a todos")
check(string.find(gadget, "missionUse", 1, true) ~= nil and string.find(story, "missionUse = LifeStoryService.useWeapon", 1, true) ~= nil, "el rayo de la barra (también en el móvil) dispara a Petra")

---------------------------------------------------------------------
print("\n▶ La misión de la gallina")
---------------------------------------------------------------------
local ok, nino = pcall(loadModule, "src/shared/LifeStory/Misiones/Loco_Nino")
if not ok then
	print("    " .. tostring(nino))
end
local N3 = nil
if ok and type(nino) == "table" then
	for _, q in nino do
		if type(q) == "table" and q.Id == "Loco_N3_Pollo" then
			N3 = q
		end
	end
end
check(N3 ~= nil, "la misión carga")
if N3 then
	local fight, escape = nil, nil
	for _, s in N3.Steps do
		if s.Type == "Fight" then
			fight = s
		elseif s.Type == "Escape" then
			escape = s
		end
	end
	local Items = loadModule("src/shared/Items")
	local ray = Items.get(fight and fight.Weapon)
	check(fight and fight.Weapon == "RayoEncogedor" and ray and ray.Kind == "Gadget", "el combate te presta el 🔬 Rayo encogedor (un gadget de la barra)")
	check(fight and fight.Respawn ~= "GranjaSilo" and escape and escape.Respawn == "GranjaPatio", "nada te manda «al silo» (un modelo macizo): la huida vuelve al patio")
	local said = false
	for _, line in N3.Dialogues.Rayo.Lines do
		if type(line.T) == "string" and string.find(line.T, "barra", 1, true) then
			said = true
		end
	end
	check(said, "Cosme te dice que el rayo está en tu barra")
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
