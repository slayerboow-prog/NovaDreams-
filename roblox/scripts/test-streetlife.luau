-- Prueba: la gente y los animales de la calle pisan suelo de verdad, los bocadillos de la historia
-- siempre se leen y los comentarios sueltos no cortan las misiones.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-streetlife.luau
--
--   1. Suelo (shared/Ground): los recambios de mallas esconden piezas (Transparency = 1) que siguen
--      chocando y añaden cajas de choque invisibles. Ground.castVisible las salta (la gente y los
--      animales ya no se quedan flotando encima de la acera); un asiento que ya no está o se ha
--      escondido no vale (Ground.seatOk: quien se sentaba se levanta). El perro de un paseante apoya
--      las patas en el suelo y una mascota sin suelo debajo va a la altura de los pies de su dueño.
--   2. Bocadillos (UI/BubbleLayout): los de la historia, encima de todo (AlwaysOnTop) y desde más lejos.
--   3. Comentarios sueltos: no salen en una conversación o una escena, ni encima de un actor de una
--      misión, ni cortan una frase de la historia.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Enum, Instance = roblox.Vector3, roblox.CFrame, roblox.Enum, roblox.Instance
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

---------------------------------------------------------------------
-- Un mundo de mentira: piezas de verdad (Lune) y un rayo hacia abajo sencillo
---------------------------------------------------------------------
local world = Instance.new("Workspace")
roblox.implementMethod("Workspace", "Raycast", function(_self, origin: any, direction: any, params: any)
	local excluded = (params and params.FilterDescendantsInstances) or {}
	local best, bestTop = nil, -math.huge
	for _, part in world:GetDescendants() do
		if not part:IsA("BasePart") or not part.CanQuery then
			continue
		end
		local skip = false
		for _, e in excluded do
			if part == e or part:IsDescendantOf(e) then
				skip = true
				break
			end
		end
		if skip then
			continue
		end
		local c, s = part.CFrame.Position, part.Size
		local top = c.Y + s.Y / 2
		if math.abs(origin.X - c.X) <= s.X / 2 and math.abs(origin.Z - c.Z) <= s.Z / 2 and top <= origin.Y and top >= origin.Y + direction.Y and top > bestTop then
			best, bestTop = part, top
		end
	end
	if not best then
		return nil
	end
	return { Instance = best, Position = V(origin.X, bestTop, origin.Z), Normal = V(0, 1, 0), Material = best.Material, Distance = origin.Y - bestTop }
end)

local function part(name: string, size: any, at: any, props: { [string]: any }?): any
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(at)
	p.Anchored = true
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = world
	return p
end

local env = {
	workspace = world,
	Enum = Enum,
	Vector3 = Vector3,
	CFrame = CFrame,
	RaycastParams = { new = function()
		return { FilterDescendantsInstances = {} }
	end },
	typeof = roblox.typeof or typeof,
}
local Ground = loadWith("src/shared/Ground.luau", env)

---------------------------------------------------------------------
print("\n▶ La gente y los animales pisan suelo que se ve")
---------------------------------------------------------------------
-- La acera (arriba a y = 0.5) y, encima, la valla de obras invisible que sí choca (Kit/StreetDetail)
local sidewalk = part("Sidewalk", V(40, 1, 40), V(0, 0, 0))
local barrier = part("WorksBarrier", V(5.2, 3, 1.6), V(0, 2, 0), { Transparency = 1 })
local from, down = V(0, 14, 0), V(0, -40, 0)

local old = Ground.cast(from, down, nil)
check(old and old.Instance == barrier, "(la causa) el rayo de siempre se queda encima de la caja invisible, a 3 studs de la acera")
local hit = Ground.castVisible(from, down, nil)
check(hit and hit.Instance == sidewalk and math.abs(hit.Position.Y - 0.5) < 1e-3, "Ground.castVisible salta la caja invisible y da con la acera")

-- La pieza de bloques que esconde un recambio de malla (CityAssetsKit.hide / InteriorProps): cascarón
barrier.Parent = nil
local shell = part("Pallet", V(4, 1.2, 4), V(10, 1.1, 0), { Transparency = 1 })
shell:AddTag("BuildingShell")
local overShell = Ground.castVisible(V(10, 14, 0), down, nil)
check(overShell and overShell.Instance == sidewalk, "la pieza escondida por un recambio de malla (BuildingShell) no es suelo")
check(Ground.hidden(shell) and not Ground.hidden(sidewalk), "Ground.hidden: lo escondido sí, la acera no")
local propShell = part("Mesa", V(4, 3, 4), V(-10, 2, 0), { Transparency = 0.2 })
propShell:AddTag("PropShell")
local overProp = Ground.castVisible(V(-10, 14, 0), down, nil)
check(overProp and overProp.Instance == sidewalk, "el cascarón de un mueble de InteriorProps (PropShell) tampoco")

-- El choque invisible que deja MeshLibrary en el sitio del tronco de un árbol
local trunk = part("Trunk", V(1.5, 4, 1.5), V(5, 2.5, 8), { Transparency = 1 })
trunk:SetAttribute("Collider", true)
local overTrunk = Ground.castVisible(V(5, 14, 8), down, nil)
check(overTrunk and overTrunk.Instance == sidewalk, "el choque invisible de un árbol de malla (Collider) no es suelo")

-- Arbustos y copas: se ven, pero no se pisan
local bush = part("Bush", V(3, 2.5, 3), V(-6, 1.75, 8))
local overBush = Ground.castVisible(V(-6, 14, 8), down, nil)
check(overBush and overBush.Instance == sidewalk and Ground.cast(V(-6, 14, 8), down, nil).Instance == bush, "nadie se sube encima de un arbusto")

-- Un suelo que se ve sigue valiendo (un escalón, un banco de piedra…)
local step = part("Step", V(4, 1, 4), V(0, 1, -10))
local overStep = Ground.castVisible(V(0, 14, -10), down, nil)
check(overStep and overStep.Instance == step, "lo que se ve y se pisa sigue siendo suelo")

-- Si se acaban los intentos sin suelo, nada (antes devolvía lo último que tocaba: una copa, una caja)
for k = 1, 6 do
	part("Hueco" .. k, V(2, 0.2, 2), V(14, 1 + k, 14), { Transparency = 1 })
end
local exhausted = Ground.castVisible(V(14, 14, 14), down, nil, 3)
check(exhausted == nil, "sin suelo que se vea a mano, no hay suelo (no una caja invisible)")
check(Ground.cast(V(14, 14, 14), down, nil, 3) ~= nil, "(el rayo de siempre, para los jugadores y los coches, no cambia)")

---------------------------------------------------------------------
print("\n▶ Bancos que ya no están: se levantan")
---------------------------------------------------------------------
local seat = part("Seat", V(5.4, 0.35, 1.7), V(20, 1.85, 0))
check(Ground.seatOk(seat), "un banco que se ve vale para sentarse")
seat.Transparency = 1
check(not Ground.seatOk(seat), "un banco escondido (sin malla en su sitio) no vale: nadie se sienta en el aire")
seat:AddTag("PropShell")
check(Ground.seatOk(seat), "el cascarón de un mueble cambiado por su malla sí vale (la malla está ahí)")
seat:RemoveTag("PropShell")
seat.Transparency = 0
seat.Parent = nil
check(not Ground.seatOk(seat), "un banco quitado del mundo no vale")
check(not Ground.seatOk(nil), "sin banco, de pie")

---------------------------------------------------------------------
print("\n▶ Perros y mascotas en el suelo")
---------------------------------------------------------------------
local shared = { ReplicatedStorage = { Shared = { NameFilter = {} } } }
local petsEnv = {
	Vector3 = Vector3,
	CFrame = CFrame,
	Enum = Enum,
	game = { GetService = function(_, name)
		return shared[name]
	end },
	require = function(_)
		return { clean = function(s)
			return s
		end }
	end,
}
local Pets = loadWith("src/shared/Pets.luau", petsEnv)
for _, feet in { -3, -2.6, -3.4 } do
	local dog = Pets.walkerDog(feet)
	local legBottom = dog.PerroPataDI.Position.Y - Pets.WalkerDogLeg / 2
	local bellyBottom = dog.PerroCuerpo.Position.Y - 0.45
	check(math.abs(legBottom - feet) < 1e-3 and bellyBottom >= feet + Pets.WalkerDogLeg - 1e-3 and bellyBottom < feet + 0.7,
		("perro del paseante: las patas apoyan en el suelo y la tripa justo encima (pies a %.1f)"):format(feet))
end
local goal = Pets.fallbackGoal(V(3, 53.5, 4), V(1, 3.5, 2), 0.8)
check(math.abs(goal.Y - (0.5 + 0.8)) < 1e-3 and goal.X == 3 and goal.Z == 4, "mascota sin suelo debajo: a la altura de los pies de su dueño, no 50 studs en el aire")

---------------------------------------------------------------------
print("\n▶ Bocadillos de la historia: siempre se leen")
---------------------------------------------------------------------
local B = loadWith("src/client/UI/BubbleLayout.luau", {})
local storyStyle, streetStyle = B.style(true), B.style(false)
check(storyStyle.AlwaysOnTop == true, "los bocadillos de la historia y de las misiones van encima de todo (las paredes no los tapan)")
check(storyStyle.MaxDistance > streetStyle.MaxDistance and storyStyle.Lift > 0, "…se ven desde más lejos y van un poco más arriba")
check(streetStyle.AlwaysOnTop == false, "los de la calle siguen detrás de las paredes (no se ven a través de los edificios)")
local items = {
	{ Id = "calle", Depth = 5 },
	{ Id = "mision", Depth = 40, Story = true },
	{ Id = "otro", Depth = 8 },
}
table.sort(items, B.before)
check(items[1].Id == "mision", "con muchos bocadillos, el de la historia nunca se queda fuera")

---------------------------------------------------------------------
print("\n▶ Los comentarios sueltos no cortan las misiones")
---------------------------------------------------------------------
local book = B.book()
local actor, vecino = {}, {}
B.put(book, actor, "Tienes que encontrar la llave antes de que anochezca.", 0, { Story = true })
check(not B.barkAllowed(book, actor, 1, {}), "un «¡Eh!» de un choque no sustituye la frase de la misión que se está leyendo")
check(book.Entries[actor].Text == "Tienes que encontrar la llave antes de que anochezca.", "(la frase de la misión sigue ahí)")
check(B.barkAllowed(book, actor, 60, {}), "cuando ya ha terminado la frase, vuelve a reaccionar")
check(not B.barkAllowed(book, vecino, 1, { InDialogue = true }), "durante una conversación, nadie de alrededor suelta frases")
check(not B.barkAllowed(book, vecino, 1, { InCinematic = true }), "durante una escena, tampoco")
check(not B.barkAllowed(book, vecino, 1, { StoryActor = true }), "un actor de una misión no suelta «¡Oye, disculpa!» al acercarte")
check(not B.barkAllowed(book, vecino, 1, { Held = true }), "quien tiene la frase de una conversación tampoco")
check(B.barkAllowed(book, vecino, 1, {}), "un vecino cualquiera, fuera de la historia, sí reacciona")
B.put(book, vecino, "¡Eh!", 2, { Seconds = 1.6 })
check(not book.Entries[vecino].Story, "(un «¡Eh!» no cuenta como frase de la historia)")

---------------------------------------------------------------------
print("\n▶ Cada sistema usa lo de arriba")
---------------------------------------------------------------------
local function src(path: string): string
	return fs.readFile(path)
end
local placeLife = src("src/server/Services/PlaceLifeService.luau")
check(string.find(placeLife, "pcall(Ground.castVisible", 1, true) and string.find(placeLife, "Ground.seatOk(seat)", 1, true) and string.find(placeLife, "PlaceLifeService.keepSeated", 1, true),
	"PlaceLifeService: suelo que se ve, solo bancos que siguen ahí y se levantan si se los quitan")
check(string.find(placeLife, "Pets.walkerDog", 1, true) and string.find(placeLife, "InDialogue", 1, true), "PlaceLifeService: el perro con patas en el suelo y sin frases sueltas al lado de una conversación")
local crowd = src("src/server/Services/CrowdService.luau")
check(string.find(crowd, "Ground.skipOf(part, true)", 1, true) and string.find(crowd, "Ground.seatOk", 1, true) and string.find(crowd, "busyNear", 1, true),
	"CrowdService: suelo que se ve, bancos que siguen ahí y sin frases al lado de una conversación")
for _, path in { "src/client/Controllers/PetLife.luau", "src/client/Controllers/Wildlife.luau", "src/server/Services/SceneService.luau", "src/server/Services/SchoolService.luau", "src/server/Services/CityErrandService.luau" } do
	check(string.find(src(path), "Ground.castVisible", 1, true) ~= nil, path:match("[^/]+$") .. ": pone a los suyos en suelo que se ve")
end
check(string.find(src("src/server/World/Npc.luau"), "not Ground.hidden(part)", 1, true) ~= nil, "Npc.feetAt: no pisa piezas escondidas")
local nudge = src("src/client/Controllers/Nudge.luau")
check(string.find(nudge, "Ambient = true", 1, true) and string.find(nudge, "if Nudge.quiet(model) then", 1, true), "Nudge: el «¡Eh!» es un comentario suelto y un actor de misión no reacciona al empujón")
local bubbles = src("src/client/UI/SpeechBubbles.luau")
check(string.find(bubbles, "BubbleLayout.style(isStory)", 1, true) and string.find(bubbles, "StoryScenes", 1, true) and string.find(bubbles, "if o.Ambient and not SpeechBubbles.barkAllowed(key)", 1, true),
	"SpeechBubbles: estilo de la historia, actores de misión y comentarios sueltos filtrados")
check(string.find(src("src/client/Controllers/DialogueUI.luau"), "Story = true", 1, true) and string.find(src("src/client/Controllers/Baby.luau"), "Story = true", 1, true) and string.find(src("src/client/Controllers/HappeningClient.luau"), "Story = true", 1, true),
	"conversaciones, frases de la familia y sucesos: bocadillos de la historia")

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
