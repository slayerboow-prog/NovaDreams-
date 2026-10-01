-- Prueba de la ADOPCIÓN de mascotas y de montar a caballo, FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-adoption.luau                 (sin mapa: reglas y PetService)
--   lune run scripts/test-adoption.luau <place.rbxl>     (y además lo construido en el mapa)
--
-- Comprueba que:
--   * el nombre se filtra (palabrotas, trucos, enlaces, corto/largo) y también con el filtro de Roblox
--   * adoptar en la protectora: elegir raza y color, ponerle nombre, donación voluntaria (se cobra
--     solo si se elige), límite de mascotas, lejos del mostrador no se puede
--   * la mascota sale contigo (Configuration con su nombre, raza y modo), se sienta, la llamas, se va
--     a casa, la devuelves… y todo se guarda en la partida (SaveCheck sin problemas, vuelve igual)
--   * vagabundos: llamar → te sigue → solo tras un rato se puede adoptar; luego ese sitio queda vacío
--   * caballo: es un vehículo (oculto del menú) con su silla; las patas se sueldan girando desde la
--     cadera sin moverse de su sitio
--   * con el mapa: la protectora (mostrador, recepcionista, 6 cheniles), los cercados con su valla,
--     comedero y abrevadero, el poste de montar, y que los vagabundos y gatos de casa están al aire
--     libre (sin techo encima, ni en el metro)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3, Instance = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
-- Cargador de módulos (shared y server) con lo que haga falta de mentira
---------------------------------------------------------------------
local fakes: { [string]: any } = {} -- ruta del módulo -> sustituto
local cache: { [string]: any } = {}
local baseEnv: { [string]: any } = {}

local function node(path: string, parent: any?): any
	local self = { __path = path, Parent = parent }
	if fs.isDir(path) then
		for _, name in fs.readDir(path) do
			local child = path .. "/" .. name
			if fs.isDir(child) then
				self[name] = node(child, self)
			elseif name:match("%.luau$") and not name:match("%.server%.luau$") and not name:match("%.client%.luau$") then
				self[(name:gsub("%.luau$", ""))] = node(child, self)
			end
		end
	end
	return self
end
local tree = { shared = node("src/shared"), server = node("src/server") }

local requireModule
function requireModule(target: any): any
	local path = rawget(target, "__path")
	if fakes[path] then
		return fakes[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({ script = target, require = requireModule }, { __index = getfenv(1) })
	for k, v in baseEnv do
		env[k] = v
	end
	local result = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	cache[path] = result
	return result
end

---------------------------------------------------------------------
-- Un Roblox de mentira (lo justo para PetService)
---------------------------------------------------------------------
local function signal()
	local list = {}
	return {
		Connect = function(_, fn)
			table.insert(list, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in list do
				fn(...)
			end
		end,
	}
end

local clock = 1000
local sent: { { any } } = {}
local notes: { { any } } = {}
local function lastPanel(): any
	for i = #sent, 1, -1 do
		if sent[i][2] == "Panel" then
			return sent[i][3]
		end
	end
	return nil
end
local function lastNote(): string
	local n = notes[#notes]
	return if n then tostring(n[3]) else ""
end

local petsRemote = { OnServerEvent = signal(), FireClient = function(_, player, ...)
	table.insert(sent, { player, ... })
end }
local notify = { FireClient = function(_, player, ...)
	table.insert(notes, { player, ... })
end }
local remotes = { Notify = notify, FindFirstChild = function(_, name)
	return if name == "Pets" then petsRemote else nil
end }

local deskPos = Vector3.new(-256, 5.4, -325.2)
local tagged: { [string]: { any } } = {
	PetShelterDesk = { { Position = deskPos, CFrame = CFrame.new(deskPos), IsA = function(_, c)
		return c == "BasePart"
	end } },
	PetShelterStaff = {},
	HorseStation = {},
	Plot = {},
}
local players: { any } = {}
local playerRemoving = signal()
local workspace = Instance.new("Folder")
workspace.Name = "Workspace"

local filterBad = { ["Malnombre"] = true } -- lo que el filtro de Roblox tacharía
local fakeGame = { GetService = function(_, name)
	if name == "ReplicatedStorage" then
		return { Remotes = remotes, Shared = tree.shared }
	elseif name == "CollectionService" then
		return {
			GetTagged = function(_, tag)
				return tagged[tag] or {}
			end,
			GetInstanceAddedSignal = function()
				return signal()
			end,
		}
	elseif name == "Players" then
		return { GetPlayers = function()
			return players
		end, PlayerRemoving = playerRemoving }
	elseif name == "RunService" then
		return { IsStudio = function()
			return false
		end }
	elseif name == "TextService" then
		return { FilterStringAsync = function(_, text)
			return { GetNonChatStringForBroadcastAsync = function()
				return if filterBad[text] then string.rep("#", #text) else text
			end }
		end }
	end
	return setmetatable({}, { __index = function()
		return function() end
	end })
end }

-- DataService de mentira: una partida en memoria
local profiles: { [any]: any } = {}
local loaded: { (any, any) -> () } = {}
fakes["src/server/Services/DataService.luau"] = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function(cb)
		table.insert(loaded, cb)
	end,
	spend = function(player, n)
		local d = profiles[player]
		if d and d.Money >= n then
			d.Money -= n
			return true
		end
		return false
	end,
	addMoney = function(player, n)
		profiles[player].Money += n
		return true
	end,
}
local prompts: { any } = {}
fakes["src/server/World/Builder.luau"] = {
	prompt = function(parent, action)
		local p = { ActionText = action, Triggered = signal(), Parent = parent }
		table.insert(prompts, p)
		return p
	end,
}
fakes["src/server/World/Npc.luau"] = { create = function()
	return {}
end, work = function() end }

local fakeOs = setmetatable({ clock = function()
	return clock
end, time = function()
	return 1700000000 + math.floor(clock)
end }, { __index = os })
local fakeTask = {
	spawn = function(fn, ...)
		pcall(fn, ...)
	end,
	wait = function()
		error("(fin de la prueba)")
	end,
	defer = function(fn, ...)
		pcall(fn, ...)
	end,
}
baseEnv = {
	game = fakeGame, workspace = workspace, os = fakeOs, task = fakeTask,
	Instance = Instance, Vector3 = Vector3, Vector2 = roblox.Vector2, CFrame = CFrame, Color3 = Color3, Enum = roblox.Enum,
	ColorSequence = roblox.ColorSequence, UDim2 = roblox.UDim2, NumberRange = roblox.NumberRange,
	warn = function(...)
		print("    (aviso)", ...)
	end,
}

local Pets = requireModule(tree.shared.Pets)
local SaveCheck = requireModule(tree.shared.SaveCheck)

---------------------------------------------------------------------
print("Nombres")
---------------------------------------------------------------------
for _, case in { { "Toby", true }, { "Nieve Ñandú", true }, { "Luna", true }, { "Bo", false }, { "puta", false }, { "P.U.T.A", false }, { "mierda", false }, { "www.perro.com", false }, { "Supercalifragilístico", false }, { "", false }, { 42, false } } do
	local ok = Pets.checkName(case[1])
	check(ok == case[2], ("«%s» %s"):format(tostring(case[1]), if case[2] then "vale" else "no vale"))
end

---------------------------------------------------------------------
print("Reglas de adopción")
---------------------------------------------------------------------
do
	local owned = {}
	local a = Pets.adopt(owned, "Perro", "Labrador", 2, "  Rex  ", 100)
	check(a ~= nil and a.Name == "Rex" and a.Coat == 2 and #owned == 1, "adoptar un labrador chocolate llamado «Rex» (nombre limpio)")
	check(Pets.adopt(owned, "Perro", "Caniche", 1, "Fifi", 100) == nil, "una raza que no existe, no")
	check(Pets.adopt(owned, "Gato", "Siames", 9, "Kira", 100) == nil, "un color que no existe, no")
	check(Pets.adopt(owned, "Loro", "Comun", 1, "Paco", 100) == nil, "solo perros y gatos")
	check(Pets.adopt(owned, "Gato", "Siames", 1, "puta", 100) == nil and #owned == 1, "con un nombre feo, no")
	Pets.adopt(owned, "Gato", "Siames", 1, "Kira", 100)
	Pets.adopt(owned, "Perro", "Beagle", 1, "Snoopy", 100)
	check(#owned == Pets.MAX_OWNED, ("hasta %d mascotas"):format(Pets.MAX_OWNED))
	local extra, why = Pets.adopt(owned, "Perro", "Mestizo", 1, "Coco", 100)
	check(extra == nil and why ~= nil and #owned == Pets.MAX_OWNED, "ni una más del límite (" .. tostring(why) .. ")")
	local ids = {}
	for _, p in owned do
		ids[p.Id] = true
	end
	check(ids.m1 and ids.m2 and ids.m3, "cada una con su id")
	-- Partida rota o vieja: se arregla al cargar
	local raw = { owned[1], owned[1], { Id = "x", Kind = "Dragon", Breed = "Rojo", Coat = 1, Name = "Smaug" }, { Id = "y", Kind = "Gato", Breed = "Negro", Coat = 99, Name = "Noche" }, "basura", owned[2], owned[3] }
	local clean = Pets.sanitize(raw)
	check(#clean == Pets.MAX_OWNED and clean[1].Id == owned[1].Id and clean[2].Id == "y" and clean[2].Coat == 1, "una partida con duplicados, especies raras y colores imposibles se arregla")
	check(#Pets.sanitize(nil) == 0 and #Pets.sanitize("x") == 0, "sin datos: lista vacía")
end

---------------------------------------------------------------------
print("PetService: adoptar en la protectora")
---------------------------------------------------------------------
local PetService = requireModule(tree.server.Services.PetService)
PetService.clock = function()
	return clock
end
PetService._robloxFilter = PetService._robloxFilter -- (usa el TextService de mentira)
PetService.init()
local folder = workspace:FindFirstChild("Mascotas")
check(folder ~= nil, "crea la carpeta workspace.Mascotas")

local attrs = {}
local root = { Position = deskPos + Vector3.new(0, -2, -3) }
local character = { FindFirstChild = function(_, name)
	return if name == "HumanoidRootPart" then root else nil
end }
local player = {
	UserId = 4242, Name = "Ana", DisplayName = "Ana", Character = character,
	GetAttribute = function(_, k)
		return attrs[k]
	end,
	SetAttribute = function(_, k, v)
		attrs[k] = v
	end,
}
table.insert(players, player)
profiles[player] = { Money = 100, Pets = { Owned = {}, Out = "" } }
for _, cb in loaded do
	cb(player, profiles[player])
end
local function act(...)
	clock += 3 -- (entre pulsación y pulsación)
	petsRemote.OnServerEvent:Fire(player, ...)
end
local function config()
	return folder:FindFirstChild(tostring(player.UserId))
end
local data = profiles[player]

check(#prompts >= 2 and prompts[1].ActionText == "Adoptar", "el mostrador tiene el cartel «Adoptar» (y «Mis mascotas»)")
prompts[1].Triggered:Fire(player)
local panel = lastPanel()
check(panel and panel.Id == "Protectora" and panel.Tab == "Perros" and #panel.Rows == #Pets.Breeds.Perro + 1, "«Adoptar» abre la protectora con todas las razas de perro")
act("Panel", "Protectora", "Gatos")
panel = lastPanel()
check(panel and panel.Tab == "Gatos" and #panel.Rows == #Pets.Breeds.Gato + 1, "pestaña de gatos")

-- Lejos del mostrador no se puede
root.Position = deskPos + Vector3.new(200, 0, 0)
act("Pick", "Perro", "Labrador", 1)
check(lastNote():find("mostrador") ~= nil, "lejos del mostrador no se puede elegir")
root.Position = deskPos + Vector3.new(0, -2, -3)
act("Pick", "Perro", "Labrador", 1)
panel = lastPanel()
check(panel and panel.Id == "Nombre", "elegir raza y color abre la ventana del nombre")
local hasInput = false
for _, row in panel.Rows do
	if row.Input and row.Input.Action == "Adopt" then
		hasInput = true
	end
end
check(hasInput, "con un campo para escribir el nombre y el botón «Adoptar»")
act("Donate", 50)
check(lastNote():find("dinero") == nil, "elige donar 50")
act("Adopt", "puta")
check(#data.Pets.Owned == 0 and lastNote():find("permitido") ~= nil, "un nombre feo no se acepta")
act("Adopt", "Malnombre")
check(#data.Pets.Owned == 0 and lastNote():find("Roblox") ~= nil, "lo que tacha el filtro de Roblox tampoco")
act("Adopt", "Toby")
check(#data.Pets.Owned == 1 and data.Pets.Owned[1].Name == "Toby" and data.Pets.Owned[1].Breed == "Labrador", "«Toby» adoptado")
check(data.Money == 50, ("se cobra la donación elegida (te quedan %d)"):format(data.Money))
check(data.Pets.Out == data.Pets.Owned[1].Id, "y va contigo")
local c = config()
check(c and c:GetAttribute("PetName") == "Toby" and c:GetAttribute("Kind") == "Perro" and c:GetAttribute("Mode") == "Follow" and c:GetAttribute("Owner") == 4242, "se ve: workspace.Mascotas con su nombre, raza y «te sigue»")
check(attrs.PetCount == 1, "el jugador sabe cuántas tiene (PetCount)")

-- Gratis si no donas
act("Pick", "Gato", "Siames", 1)
act("Adopt", "Kira")
check(#data.Pets.Owned == 2 and data.Money == 50, "sin donación, gratis")
check(data.Pets.Out == data.Pets.Owned[2].Id and config():GetAttribute("PetName") == "Kira", "la nueva va contigo (la otra se queda en casa)")
-- Donación sin dinero: avisa y no se cobra
act("Pick", "Perro", "Mestizo", 2)
data.Money = 10
act("Donate", 20)
check(lastNote():find("dinero") ~= nil, "no puedes donar más de lo que llevas (adoptar sigue siendo gratis)")
act("Donate", 999)
data.Money = 50
act("Adopt", "Coco")
check(#data.Pets.Owned == 3 and data.Money == 50, "tercera mascota")
act("Pick", "Perro", "Beagle", 1)
check(lastNote():find("máximo") ~= nil, ("con %d no deja elegir más"):format(Pets.MAX_OWNED))
act("Adopt", "Otro")
check(#data.Pets.Owned == 3, "ni adoptar una cuarta")

print("PetService: órdenes")
local coco = data.Pets.Owned[3]
act("Sit", coco.Id)
check(config():GetAttribute("Mode") == "Sit" and typeof(config():GetAttribute("SitAt")) == "Vector3", "«Sentarse»: se queda donde estaba")
act("Follow", coco.Id)
check(config():GetAttribute("Mode") == "Follow" and config():GetAttribute("SitAt") == nil, "«Seguir»")
act("Call", coco.Id)
check(config():GetAttribute("CallAt") == clock, "«Llamar»: viene corriendo")
act("Home", coco.Id)
check(data.Pets.Out == "" and config():GetAttribute("Mode") == "Home", "«A casa»: se queda en casa")
act("Out", data.Pets.Owned[1].Id)
check(data.Pets.Out == data.Pets.Owned[1].Id and config():GetAttribute("PetName") == "Toby", "«Sacar» a Toby")
act("Panel", "Mascotas")
panel = lastPanel()
check(panel and panel.Id == "Mascotas" and #panel.Rows == 3, "«Mis mascotas» las enseña todas")
act("Release", coco.Id)
act("ReleaseYes", coco.Id)
check(#data.Pets.Owned == 2 and Pets.find(data.Pets.Owned, coco.Id) == nil, "devolver a la protectora (pide confirmación)")

print("Se guarda en la partida")
local problems = SaveCheck.scan(data)
check(#problems == 0, ("la partida con mascotas se puede guardar (%d problemas)"):format(#problems))
local copy = Pets.sanitize(SaveCheck.restore(SaveCheck.sanitize(data.Pets.Owned)))
local same = #copy == #data.Pets.Owned
for i, p in copy do
	local q = data.Pets.Owned[i]
	same = same and p.Id == q.Id and p.Name == q.Name and p.Breed == q.Breed and p.Coat == q.Coat and p.Kind == q.Kind
end
check(same, "al volver a entrar están igual (nombre, raza, color)")
-- Otro servidor: al cargar sale la que iba contigo
local player2attrs = {}
local player2 = { UserId = 5151, Name = "Leo", DisplayName = "Leo", Character = character, GetAttribute = function(_, k)
	return player2attrs[k]
end, SetAttribute = function(_, k, v)
	player2attrs[k] = v
end }
profiles[player2] = { Money = 0, Pets = { Owned = Pets.sanitize(data.Pets.Owned), Out = data.Pets.Out } }
for _, cb in loaded do
	cb(player2, profiles[player2])
end
local c2 = folder:FindFirstChild("5151")
check(c2 and c2:GetAttribute("PetName") == "Toby" and c2:GetAttribute("Mode") == "Follow", "al entrar en otro servidor, tu mascota vuelve contigo")
playerRemoving:Fire(player2)
check(folder:FindFirstChild("5151") == nil, "al salir del juego se va contigo")

print("Vagabundos")
local stray = Pets.Strays[1]
check(stray ~= nil, "hay vagabundos")
-- dejamos sitio (2/3)
root.Position = Vector3.new(stray.At[1] + 200, 1, stray.At[2])
act("StrayCall", stray.Id)
check(sent[#sent][2] ~= "StrayFollow", "lejos no le puedes llamar")
root.Position = Vector3.new(stray.At[1] + 5, 1, stray.At[2])
act("StrayCall", stray.Id)
check(sent[#sent][2] == "StrayFollow" and sent[#sent][3] == stray.Id, "«Llamar»: te sigue")
clock += 1
petsRemote.OnServerEvent:Fire(player, "StrayAdopt", stray.Id)
check(lastNote():find("fía") ~= nil, "nada más llamarle aún no se deja adoptar")
clock += Pets.STRAY_FOLLOW_TIME + 1
act("StrayAdopt", stray.Id)
panel = lastPanel()
check(panel and panel.Id == "Nombre", ("tras seguirte %d s, «Adoptar»"):format(Pets.STRAY_FOLLOW_TIME))
act("Adopt", "Canelita")
local adopted = data.Pets.Owned[#data.Pets.Owned]
check(#data.Pets.Owned == 3 and adopted.Name == "Canelita" and adopted.Stray == true and adopted.Breed == stray.Breed, "adoptado el vagabundo, con su raza y color")
local taken = folder:GetAttribute("StrayTaken_" .. stray.Id)
check(type(taken) == "number" and taken > clock + 60, "ese sitio se queda vacío un rato (no hay dos iguales)")
act("StrayCall", stray.Id)
check(sent[#sent][2] ~= "StrayFollow", "y ya no se le puede llamar")

---------------------------------------------------------------------
print("Caballo")
---------------------------------------------------------------------
do
	local Gameplay = requireModule(tree.shared.Gameplay)
	check(Gameplay.Vehicles.Caballo and Gameplay.Vehicles.Caballo.Hidden and Gameplay.Driving.Caballo, "el caballo se lleva como un vehículo (y no sale en la tienda de vehículos)")
	fakes["src/server/World/Builder.luau"] = nil -- (Rides necesita el de verdad)
	local Rides = requireModule(tree.server.World.Kit.Rides)
	check(Rides.Spec.Caballo ~= nil, "tiene asiento (silla)")
	local cf = CFrame.new(10, 0, 20) * CFrame.Angles(0, 0.7, 0)
	local m = Rides.build("Caballo", nil, cf, Color3.fromRGB(120, 72, 40))
	local before = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Leg") then
			before[p] = p.CFrame
		end
	end
	local chassis = Rides.prepare(m, "Caballo", cf)
	local welds, stay = 0, true
	for p, was in before do
		local weld = p:FindFirstChild("LegWeld")
		if weld then
			welds += 1
			local now = chassis.CFrame * weld.C0 * weld.C1:Inverse()
			if (now.Position - was.Position).Magnitude > 0.01 then
				stay = false
			end
			if typeof(weld:GetAttribute("HipC0")) ~= "CFrame" then
				stay = false
			end
		end
	end
	check(welds == 8, ("las 4 patas (con sus cascos) giran desde la cadera (%d soldaduras)"):format(welds))
	check(stay, "y al soldarlas no se mueven de su sitio")
	check(m:FindFirstChild("DriverSeat") ~= nil and m:FindFirstChild("Saddle") ~= nil, "con silla y asiento de jinete")
	local ride = fs.readFile("src/client/Controllers/RidePose.luau")
	check(ride:find("Caballo = true") ~= nil, "el jinete va a horcajadas con las riendas (RidePose)")
end

---------------------------------------------------------------------
-- Con el mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("En el mapa (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local shelter = town and town:FindFirstChild("Protectora")
	local fields = town and town:FindFirstChild("CampoAnimales")
	check(shelter ~= nil, "la Protectora de animales está en el mapa")
	check(fields ~= nil, "los Campos de Valmar (cercados) están en el mapa")
	local count = {}
	for _, d in town:GetDescendants() do
		for _, tag in d:GetTags() do
			count[tag] = (count[tag] or 0) + 1
		end
	end
	check(count.PetShelterDesk == 1 and count.PetShelterStaff == 1, "mostrador y recepcionista")
	check(count.PetShelterKennel == #Pets.ShelterResidents, ("%d cheniles con su animal"):format(count.PetShelterKennel or 0))
	check(count.HorseStation == 1, "poste para montar a caballo")
	-- Piezas sólidas (para ver si algo tiene techo encima)
	local solids = {}
	for _, p in town:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide and p.Transparency < 0.9 then
			local cf, s = p.CFrame, p.Size
			local hx = math.abs(cf.RightVector.X) * s.X / 2 + math.abs(cf.UpVector.X) * s.Y / 2 + math.abs(cf.LookVector.X) * s.Z / 2
			local hy = math.abs(cf.RightVector.Y) * s.X / 2 + math.abs(cf.UpVector.Y) * s.Y / 2 + math.abs(cf.LookVector.Y) * s.Z / 2
			local hz = math.abs(cf.RightVector.Z) * s.X / 2 + math.abs(cf.UpVector.Z) * s.Y / 2 + math.abs(cf.LookVector.Z) * s.Z / 2
			local P = cf.Position
			table.insert(solids, { P.X - hx, P.X + hx, P.Y - hy, P.Y + hy, P.Z - hz, P.Z + hz })
		end
	end
	local function roofAbove(x: number, z: number, y: number): boolean
		for _, b in solids do
			if x > b[1] and x < b[2] and z > b[5] and z < b[6] and b[3] > y + 3 and b[3] < y + 60 then
				return true
			end
		end
		return false
	end
	local function groundAt(x: number, z: number): number?
		local best = nil
		for _, b in solids do
			if x > b[1] and x < b[2] and z > b[5] and z < b[6] and b[4] < 8 and b[4] > -6 and (not best or b[4] > best) then
				best = b[4]
			end
		end
		return best
	end
	for _, s in Pets.Strays do
		local y = groundAt(s.At[1], s.At[2]) or -1
		check(Pets.looseSpotOk(y) and not roofAbove(s.At[1], s.At[2], y), ("vagabundo %s (%s): al aire libre, ni en el metro ni bajo techo"):format(s.Id, s.Where))
	end
	local roofedCats = 0
	for _, spot in Pets.HouseCats do
		local y = groundAt(spot[1], spot[2]) or -1
		if not Pets.looseSpotOk(y) or roofAbove(spot[1], spot[2], y) then
			roofedCats += 1
		end
	end
	check(roofedCats == 0, ("los gatos de casa están fuera de las casas, en su puerta (%d mal)"):format(roofedCats))
	-- Cercados: valla en los 4 lados y nada sólido dentro que no sea suyo
	local FarmAnimals = requireModule(tree.shared.FarmAnimals)
	for _, pen in FarmAnimals.Pens do
		local sides = { N = 0, S = 0, W = 0, E = 0 }
		for _, p in fields:GetDescendants() do
			if p:IsA("BasePart") and p.Name == "Travesano" then
				local P = p.CFrame.Position
				if math.abs(P.Z - pen.Z0) < 0.5 and P.X > pen.X0 - 1 and P.X < pen.X1 + 1 then
					sides.N += 1
				elseif math.abs(P.Z - pen.Z1) < 0.5 and P.X > pen.X0 - 1 and P.X < pen.X1 + 1 then
					sides.S += 1
				elseif math.abs(P.X - pen.X0) < 0.5 and P.Z > pen.Z0 - 1 and P.Z < pen.Z1 + 1 then
					sides.W += 1
				elseif math.abs(P.X - pen.X1) < 0.5 and P.Z > pen.Z0 - 1 and P.Z < pen.Z1 + 1 then
					sides.E += 1
				end
			end
		end
		check(sides.N > 0 and sides.S > 0 and sides.W > 0 and sides.E > 0, pen.Name .. ": vallado por los 4 lados")
		local intruders = 0
		for _, p in town:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide and not p:IsDescendantOf(fields) then
				local P = p.CFrame.Position
				if FarmAnimals.inside(pen, P.X, P.Z, 1) and P.Y > -0.5 and P.Y < 12 then
					intruders += 1
				end
			end
		end
		check(intruders == 0, ("%s: nada de otros dentro (árboles, farolas…: %d)"):format(pen.Name, intruders))
	end
	-- La protectora no pisa la calle (la acera acaba en z -355)
	local overlapStreet = 0
	for _, p in shelter:GetDescendants() do
		if p:IsA("BasePart") then
			local P, s = p.CFrame.Position, p.Size
			if P.Z - s.Z / 2 < -355 then
				overlapStreet += 1
			end
		end
	end
	check(overlapStreet == 0, "la protectora no se mete en la acera ni en la calle")
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
