-- Prueba de las ZONAS VERDES (fase 1) y de la necesidad 🎈 DIVERSIÓN, FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-zonasverdes.luau               (reglas: diversión, juegos de los parques, camping…)
--   lune run scripts/test-zonasverdes.luau X.rbxl        (y además el mapa construido:
--       rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl)
--
-- Comprueba que:
--   * NeedsService: la diversión baja despacio con el tiempo (no dormido), sube con addFun (con tope por
--     actividad y minuto), una partida vieja sin «Fun» empieza llena, «aburrido» (Bored) por debajo de
--     FunLow con un aviso amable (uno cada FunHintEvery) y la XP sube un poco más despacio (no a 0)
--   * FunService: pescar, cine, recreativos… suben la diversión; jugando (InSport), en monopatín
--     (Riding) y paseando a la mascota también
--   * ParkService: columpio (se mece y da diversión, más a los niños), tobogán, balancín, pícnic
--     (come de la mochila: hambre ×1,2, +energía y +diversión; sin comida, un aviso), pipicán (la
--     pelota con la mascota; sin mascota, un aviso; con espera entre lanzamientos), hoguera (solo de
--     noche: malvaviscos y troncos), tiendas del camping (se alquilan una vez, nadie te quita la tuya),
--     parcelas (montar tu tienda; nadie más en tu parcela) y la cocina del huerto (FarmService)
--   * con el mapa: 30 parques vivos de 60–120 piezas, cada sitio por debajo de 600, nada encima de
--     calles, aceras, edificios ni árboles (la misma regla de «construido» que la máscara de
--     scripts/map/zonas-verdes/1_mascaras.py), sin marcas de la historia en los Jardines de la Plaza
--     Mayor, la media pista la ve BasketService (Sports/Court), la granja de los huertos tiene 4 fincas
--     para FarmService y el Camping tiene tiendas, hoguera y parcelas

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L = require("./lib/ModuleLoader")
local check = L.check

local Vector3, CFrame = roblox.Vector3, roblox.CFrame

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

---------------------------------------------------------------------
-- Roblox de mentira
---------------------------------------------------------------------
local prompts = {}
L.fakeClasses.ProximityPrompt = function()
	local p = { ClassName = "ProximityPrompt", Triggered = signal(), Enabled = true }
	table.insert(prompts, p)
	return p
end
local notices = {}
local remotes = {
	Notify = { FireClient = function(_, player, kind, text)
		table.insert(notices, { Player = player, Kind = kind, Text = text })
	end },
}
function remotes:FindFirstChild(name)
	return rawget(self, name)
end
remotes.WaitForChild = remotes.FindFirstChild
L.services.ReplicatedStorage.Remotes = remotes
local players = {}
L.services.Players = { PlayerRemoving = signal(), PlayerAdded = signal(), GetPlayers = function()
	return players
end }
local tweens = {}
L.services.TweenService = { Create = function(_, inst, _info, goal)
	local t = { Instance = inst, Goal = goal }
	function t:Play()
		table.insert(tweens, self)
	end
	function t:Cancel() end
	return t
end }
L.services.Lighting = { ClockTime = 12 }
L.services.SoundService = { FindFirstChild = function()
	return nil
end }
L.services.CollectionService.GetInstanceAddedSignal = function()
	return signal()
end

local profiles = {}
L.mock("src/server/Services/DataService", {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function() end,
	spend = function(player, price)
		local d = profiles[player]
		if not d or d.Money < price then
			return false
		end
		d.Money -= price
		return true
	end,
})
L.mock("src/server/Services/MonetizationService", { needsMultiplier = function()
	return 1
end })
L.mock("src/server/Services/TesterService", { bypass = function()
	return false
end })
local events = {}
local listeners = {}
L.mock("src/server/LifeStory/StoryEvents", {
	emit = function(player, name, payload)
		table.insert(events, { Player = player, Name = name, Payload = payload })
	end,
	connect = function(fn)
		table.insert(listeners, fn)
	end,
})
L.mock("src/server/Services/InventoryService", {
	remove = function(player, id, n)
		local d = profiles[player]
		d.Items[id] = (d.Items[id] or 0) - (n or 1)
		if d.Items[id] <= 0 then
			d.Items[id] = nil
		end
		return true
	end,
})
local petFollowing = {}
local fetches = {}
L.mock("src/server/Services/PetService", {
	following = function(player)
		return petFollowing[player] == true
	end,
	fetch = function(player, at)
		if not petFollowing[player] then
			return false
		end
		table.insert(fetches, { Player = player, At = at })
		return true
	end,
})
local sleeps = {}
L.mock("src/server/Services/SleepService", { sleep = function(player, bed)
	table.insert(sleeps, { Player = player, Bed = bed })
end })
local kitchens = {}
L.mock("src/server/Services/FarmService", { openKitchen = function(player, part)
	table.insert(kitchens, { Player = player, Part = part })
end })
-- Bancos de siempre (Props.bench usa la biblioteca de modelos de Roblox)
L.mock("src/server/World/Kit/Props", { bench = function(parent, cf)
	local m = roblox.Instance.new("Model")
	m.Name = "Bench"
	m:AddTag("Bench")
	local seat = roblox.Instance.new("Seat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(6, 0.4, 1.8)
	seat.CFrame = cf * CFrame.new(0, 1.9, 0)
	seat.Parent = m
	m.Parent = parent
	return m
end })

local Config = L.load("src/shared/Config")
local Items = L.load("src/shared/Items")
local NeedsService = L.load("src/server/Services/NeedsService")
local clock = 1000
NeedsService._clock = function()
	return clock
end

-- Un jugador con personaje de mentira (humanoide con asiento y una raíz de verdad)
local function newPlayer(id: number, stage: string?): any
	local p = L.player("P" .. id, id)
	p:SetAttribute("LifeStage", stage or "Adulto")
	-- (una tabla: las piezas de Lune no tienen AssemblyLinearVelocity)
	local root = { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), CFrame = CFrame.new(0, 3, 0), Anchored = false, Parent = true, AssemblyLinearVelocity = Vector3.zero }
	function root:IsA(class)
		return class == "BasePart" or class == "Part"
	end
	local humanoid = { SeatPart = nil, WalkSpeed = 16, Health = 100 }
	local character = { Root = root, Humanoid = humanoid }
	function character:FindFirstChildOfClass(class)
		return if class == "Humanoid" then humanoid else nil
	end
	function character:FindFirstChild(name)
		return if name == "HumanoidRootPart" then root else nil
	end
	p.Character = character
	profiles[p] = { Money = 100, Hunger = 50, Energy = 50, Items = {} } -- (sin «Fun»: partida de antes)
	table.insert(players, p)
	return p
end
local function lastNotice(player): any
	for i = #notices, 1, -1 do
		if notices[i].Player == player then
			return notices[i]
		end
	end
	return nil
end

---------------------------------------------------------------------
print("▶ 1. NeedsService: la diversión")
---------------------------------------------------------------------
local ana = newPlayer(1)
local data = profiles[ana]
check(NeedsService.getFun(ana) == Config.Needs.Max and data.Fun == Config.Needs.Max, "Partida de antes sin «Fun»: empieza llena (100)")
NeedsService.step(ana, 60)
check(math.abs(data.Fun - (100 - Config.Needs.FunPerMinute)) < 1e-6, ("Baja despacio: %.1f en un minuto"):format(100 - data.Fun))
check(ana:GetAttribute("Fun") == math.floor(data.Fun + 0.5), "El atributo Fun (lo pinta el HUD) sigue al dato")
ana:SetAttribute("Sleeping", true)
local before = data.Fun
NeedsService.step(ana, 60)
check(data.Fun == before, "Durmiendo no baja")
ana:SetAttribute("Sleeping", nil)
check(Config.Needs.FunPerMinute < Config.Needs.EnergyPerMinute and Config.Needs.FunPerMinute < Config.Needs.HungerPerMinute, "Baja más despacio que el hambre y la energía")

data.Fun = 50
check(NeedsService.addFun(ana, 30, "Swing") == 30, "addFun sube lo que se pide")
check(NeedsService.addFun(ana, 30, "Swing") == Config.Needs.FunReasonCap - 30, ("Con la misma actividad, como mucho %d por minuto"):format(Config.Needs.FunReasonCap))
check(NeedsService.addFun(ana, 5, "Swing") == 0 and NeedsService.addFun(ana, 5, "Fish") == 5, "…pero otra actividad sí suma")
clock += 61
check(NeedsService.addFun(ana, 5, "Swing") == 5, "Pasado el minuto vuelve a sumar")
data.Fun = 98
check(NeedsService.addFun(ana, 10) == 2 and data.Fun == 100, "Nunca pasa de 100")
check(NeedsService.addFun(ana, -150) == -100 and data.Fun == 0, "Ni baja de 0")
check(NeedsService.addFun(ana, 0 / 0) == 0 and NeedsService.addFun(ana, "x" :: any) == 0, "Cantidades rotas no hacen nada")

-- Aburrido: aviso amable una vez y la XP un poco más despacio
data.Fun = Config.Needs.FunLow + 0.4
NeedsService.step(ana, 60)
check(ana:GetAttribute("Bored") == true and NeedsService.isBored(ana), "Por debajo de FunLow: «aburrido» (atributo Bored)")
local hint = lastNotice(ana)
check(hint and hint.Kind == "Info" and string.find(hint.Text, "🎈", 1, true) ~= nil, "Un aviso amable (sugiere parque, mascota, pesca…)")
local nNotices = #notices
NeedsService.addFun(ana, 20, "Fish")
check(ana:GetAttribute("Bored") == nil, "Al divertirse se le pasa")
data.Fun = Config.Needs.FunLow - 1
NeedsService.change(ana, 0, 0)
check(ana:GetAttribute("Bored") == true and #notices == nNotices, ("Otra vez aburrido enseguida: sin repetir el aviso (uno cada %d s)"):format(Config.Needs.FunHintEvery))
check(Config.Needs.BoredXpFactor >= 0.8 and Config.Needs.BoredXpFactor < 1, "Aburrido, la XP sube algo más despacio, nunca castiga (factor 0,8–1)")
check(ana.Character.Humanoid.WalkSpeed >= Config.TiredWalkSpeed and data.Hunger > Config.Needs.LowThreshold, "Aburrido no camina más lento (no es como el hambre)")
NeedsService.change(ana, 0, 0, 25)
check(math.abs(data.Fun - (Config.Needs.FunLow + 24)) < 1e-6, "change(…, fun) también la sube (el helado del quiosco)")
check(Config.Foods.Helado and Config.Foods.Helado.Fun > 0, "El helado da diversión (FoodService)")

-- XP: ProgressionService.addXp con Bored
do
	local progSrc = fs.readFile("src/server/Services/ProgressionService.luau")
	check(string.find(progSrc, 'GetAttribute("Bored")', 1, true) ~= nil and string.find(progSrc, "BoredXpFactor", 1, true) ~= nil and string.find(progSrc, "math.max(1,", 1, true) ~= nil,
		"ProgressionService.addXp: aburrido → XP × BoredXpFactor (como mínimo 1)")
end

---------------------------------------------------------------------
print("\n▶ 2. FunService: lo que ya existía también divierte")
---------------------------------------------------------------------
local FunService = L.load("src/server/Services/FunService")
local leo = newPlayer(2)
local ld = profiles[leo]
ld.Fun = 50
check(FunService.onEvent(leo, "CaughtFish", {}) == Config.Fun.Fish, "Pescar un pez: +" .. Config.Fun.Fish)
check(FunService.onEvent(leo, "WatchedMovie", {}) == Config.Fun.Movie, "Ver una peli en el cine: +" .. Config.Fun.Movie)
check(FunService.onEvent(leo, "JobTaskDone", {}) == 0, "Trabajar no cuenta como diversión")
ld.Fun = 50
leo:SetAttribute("InSport", "Baloncesto")
check(math.abs(FunService.step(leo, 60) - Config.Fun.SportPerMinute) < 1e-6, "Jugando una pachanga: +" .. Config.Fun.SportPerMinute .. " por minuto")
leo:SetAttribute("InSport", nil)
leo:SetAttribute("Riding", "Monopatin")
leo.Character.Root.AssemblyLinearVelocity = Vector3.new(20, 0, 0)
check(FunService.step(leo, 60) > 0, "En monopatín moviéndote (skate) sube")
leo.Character.Root.AssemblyLinearVelocity = Vector3.zero
check(FunService.step(leo, 60) == 0, "…parado, no")
leo:SetAttribute("Riding", nil)
leo.Character.Root.AssemblyLinearVelocity = Vector3.new(8, 0, 0)
check(FunService.step(leo, 60) == 0, "Andando solo, no")
petFollowing[leo] = true
check(FunService.step(leo, 60) > 0, "Paseando a tu mascota, sí")
petFollowing[leo] = nil
leo.Character.Root.AssemblyLinearVelocity = Vector3.zero

---------------------------------------------------------------------
print("\n▶ 3. ParkService: los juegos de los parques")
---------------------------------------------------------------------
local Juegos = L.load("src/server/World/Kit/ZonasVerdes/Juegos")
local ParkService = L.load("src/server/Services/ParkService")
local night = false
ParkService._isNight = function()
	return night
end
ParkService._clock = function()
	return clock
end
local town = roblox.Instance.new("Folder")
local function tagged(root, tag)
	local out = {}
	for _, d in root:GetDescendants() do
		if d:HasTag(tag) then
			table.insert(out, d)
		end
	end
	return out
end
local function promptOf(part, action)
	for _, p in prompts do
		if p.Parent == part and (action == nil or p.ActionText == action) then
			return p
		end
	end
	return nil
end
local function setupAll(root)
	for tag, fn in ParkService._setups do
		for _, d in tagged(root, tag) do
			fn(d)
		end
	end
end

-- Columpios
local swingSet = Juegos.swings(town, CFrame.new(0, 0, 0), 2)
setupAll(swingSet)
local seats = tagged(swingSet, "FunSwing")
check(#seats == 2 and seats[1]:IsA("Seat"), "Columpios: dos asientos Seat «FunSwing»")
local seat = seats[1]
local s = ParkService._swings[seat]
check(s ~= nil and #s.Parts >= 3, "Cada columpio se mece entero (asiento y cadenas)")
local base = seat.CFrame
ParkService._swingMotion(s, true)
local pivot = seat:GetAttribute("Pivot")
check((seat.CFrame.Position - base.Position).Magnitude > 1 and math.abs((seat.CFrame.Position - pivot).Magnitude - (base.Position - pivot).Magnitude) < 0.01, "Al sentarte se mece (gira alrededor del travesaño)")
check(#tweens > 0 and tweens[#tweens].Instance == s.Angle, "…con un vaivén que no para (Tween que va y vuelve)")
ParkService._swingMotion(s, false)
check((seat.CFrame.Position - base.Position).Magnitude < 1e-3, "Al bajarte vuelve a su sitio")

local kid = newPlayer(3, "Nino")
local kd = profiles[kid]
kd.Fun = 20
clock += 100
ana.Character.Humanoid.SeatPart = seat
data.Fun = 20
ParkService.step(ana, 60)
check(math.abs(data.Fun - (20 + Config.Fun.SwingPerMinute)) < 1e-6, ("Un minuto columpiándose: +%d"):format(Config.Fun.SwingPerMinute))
kid.Character.Humanoid.SeatPart = seats[2]
ParkService.step(kid, 60)
check(math.abs(kd.Fun - (20 + Config.Fun.SwingPerMinute * Config.Fun.ChildBonus)) < 1e-6, ("Un niño, más (×%.1f)"):format(Config.Fun.ChildBonus))
ana.Character.Humanoid.SeatPart = nil
kid.Character.Humanoid.SeatPart = nil

-- Balancín
local saw = Juegos.seesaw(town, CFrame.new(30, 0, 0))
local sawSeats = tagged(saw, "FunSeat")
check(#sawSeats == 2, "Balancín: dos asientos")
data.Fun = 20
clock += 100
ana.Character.Humanoid.SeatPart = sawSeats[1]
ParkService.step(ana, 60)
check(data.Fun > 20, "Sentado en el balancín sube")
ana.Character.Humanoid.SeatPart = nil

-- Tobogán
local slide = Juegos.slide(town, CFrame.new(60, 0, 0))
setupAll(slide)
local spot = tagged(slide, "FunSlide")[1]
check(spot and typeof(spot:GetAttribute("TopAt")) == "Vector3" and typeof(spot:GetAttribute("BottomAt")) == "Vector3", "Tobogán: sitio para tirarse con arriba y abajo")
check(spot and promptOf(spot, "Tirarse") ~= nil, "…con su cartel «Tirarse»")
data.Fun = 20
clock += 100
local root = ana.Character.Root
check(ParkService.slide(ana, spot) and root.Anchored and (root.CFrame.Position - spot:GetAttribute("TopAt")).Magnitude < 0.01, "Tirarse: sube arriba del todo")
check(math.abs(data.Fun - (20 + Config.Fun.Slide)) < 1e-6, "+" .. Config.Fun.Slide .. " de diversión")
check(not ParkService.slide(ana, spot), "Mientras bajas no puedes volver a tirarte")
task.wait(1.05)
check(not root.Anchored and (root.CFrame.Position - spot:GetAttribute("BottomAt")).Magnitude < 0.01, "…y acaba abajo, suelto")

-- Pícnic
local tableModel = Juegos.picnicTable(town, CFrame.new(90, 0, 0))
setupAll(tableModel)
check(tableModel:HasTag("Bench") and #tagged(tableModel, "FunSeat") == 2, "Mesa de pícnic: dos bancos (sentado se descansa: Bench)")
local top = tagged(tableModel, "PicnicTable")[1]
check(top and promptOf(top, "Comer de la mochila") ~= nil, "…y «Comer de la mochila»")
local foodId
for _, item in Items.List do
	if item.Kind == "Food" and (item.Hunger or 0) > 0 then
		foodId = item.Id
		break
	end
end
data.Items = {}
check(not ParkService.picnic(ana) and string.find(lastNotice(ana).Text, "No llevas comida", 1, true) ~= nil, "Sin comida en la mochila: un aviso con dónde comprarla")
data.Items[foodId] = 2
data.Hunger, data.Energy, data.Fun = 20, 20, 20
clock += 100
local item = Items.get(foodId)
check(ParkService.picnic(ana), "Con comida: se la come en la mesa (" .. tostring(item.Name) .. ")")
check(data.Items[foodId] == 1, "…gasta una de la mochila")
check(math.abs(data.Hunger - math.min(100, 20 + math.floor(item.Hunger * 1.2 + 0.5))) < 1e-6 and data.Energy >= 25 - 1e-6, "…y sabe mejor: hambre ×1,2 y +5 de energía")
check(math.abs(data.Fun - (20 + Config.Fun.PicnicMeal)) < 1e-6, "…y +" .. Config.Fun.PicnicMeal .. " de diversión")
local ate = events[#events - 1]
check(ate and ate.Name == "Ate" and ate.Payload.Picnic == true, "Cuenta como comer para la historia (Ate)")

-- Pipicán
local run = Juegos.dogRun(town, CFrame.new(150, 0, 0), 30, 24)
setupAll(run)
local post = tagged(run, "DogRunPost")[1]
check(#ParkService._dogRuns >= 1 and post ~= nil and promptOf(post, "Lanzar la pelota") ~= nil, "Pipicán: su zona y el poste «Lanzar la pelota»")
clock += 100
check(not ParkService.fetch(ana, post) and string.find(lastNotice(ana).Text, "Protectora", 1, true) ~= nil, "Sin mascota: te dice dónde adoptar una")
petFollowing[ana] = true
data.Fun = 20
check(ParkService.fetch(ana, post) and #fetches == 1, "Con tu mascota: la pelota vuela y va a por ella (PetService.fetch)")
local area = ParkService._dogRuns[#ParkService._dogRuns]
local l = area.CFrame:PointToObjectSpace(fetches[1].At)
check(math.abs(l.X) < area.Size.X / 2 and math.abs(l.Z) < area.Size.Z / 2, "…y cae dentro del pipicán")
check(math.abs(data.Fun - (20 + Config.Fun.Fetch)) < 1e-6, "+" .. Config.Fun.Fetch .. " de diversión")
check(not ParkService.fetch(ana, post), "Hay que esperar un poco para volver a lanzarla")
root.CFrame = CFrame.new(150, 3, 0)
check(ParkService.inDogRun(ana), "Dentro del pipicán…")
data.Fun = 20
clock += 100
ParkService.step(ana, 60)
check(math.abs(data.Fun - (20 + Config.Fun.DogParkPerMinute)) < 1e-6, "…con tu mascota sube la diversión")
petFollowing[ana] = nil
root.CFrame = CFrame.new(0, 3, 0)

-- Media pista
local court = Juegos.halfCourt(town, CFrame.new(200, 0, 0))
local Court = L.load("src/shared/Sports/Court")
local found = Court.scanMap(court:GetDescendants())
check(#found == 1, "Media pista: BasketService la reconoce (aro, tablero y suelo HalfCourt)")

-- Hoguera
local fire = Juegos.campfire(town, CFrame.new(250, 0, 0), 4, 7)
setupAll(fire)
local flame = tagged(fire, "Campfire")[1]
check(flame and promptOf(flame, "Tostar malvaviscos") ~= nil, "Hoguera: «Tostar malvaviscos»")
check(flame and flame:GetAttribute("Lit") == false and flame.Transparency == 1, "De día está apagada")
data.Fun, data.Hunger = 20, 20
clock += 100
check(not ParkService.marshmallow(ana, flame) and string.find(lastNotice(ana).Text, "anochecer", 1, true) ~= nil, "De día: «se enciende al anochecer»")
night = true
check(ParkService.marshmallow(ana, flame) and math.abs(data.Fun - (20 + Config.Fun.Marshmallow)) < 1e-6 and data.Hunger > 20, "De noche: malvavisco tostado (+diversión y algo de hambre)")
local logs = tagged(fire, "FunSeat")
check(#logs == 4 and logs[1]:GetAttribute("NightOnly") == true, "Troncos alrededor para sentarse (cuentan de noche)")
data.Fun, data.Energy = 20, 20
clock += 100
ana.Character.Humanoid.SeatPart = logs[1]
ParkService.step(ana, 60)
check(math.abs(data.Fun - 30) < 1e-6 and data.Energy > 20, "Un minuto junto al fuego de noche: +10 de diversión y algo de energía")
night = false
data.Fun = 20
clock += 100
ParkService.step(ana, 60)
check(data.Fun == 20, "De día, sentado en el tronco, nada (la hoguera está apagada)")
ana.Character.Humanoid.SeatPart = nil
local lake = (fs.readFile("src/server/World/Kit/ZonasVerdes/Lago.luau"))
check(string.find(lake, "Monitor", 1, true) ~= nil, "Junto a la hoguera del lago hay un monitor (WorkerSpot)")

---------------------------------------------------------------------
print("\n▶ 4. Camping: tiendas y parcelas")
---------------------------------------------------------------------
local tent = Juegos.tent(town, CFrame.new(300, 0, 0), roblox.Color3.new(1, 0.5, 0), "Camping_1")
setupAll(tent)
local bed = tagged(tent, "CampTent")[1]
check(bed and promptOf(bed, "Dormir en la tienda") ~= nil, "Tienda de campaña: «Dormir en la tienda»")
data.Money = 100
clock += 100
check(ParkService.useTent(ana, bed) and data.Money == 100 - ParkService.TentPrice and #sleeps == 1, ("Se alquila (%d €) y se duerme como en una cama (SleepService)"):format(ParkService.TentPrice))
check(ParkService.useTent(ana, bed) and data.Money == 100 - ParkService.TentPrice, "Volver a dormir en tu tienda alquilada no se cobra otra vez")
check(not ParkService.useTent(leo, bed) and #sleeps == 2, "Otro jugador no puede quitártela")
profiles[leo].Money = 3
local tent2 = Juegos.tent(town, CFrame.new(320, 0, 0), roblox.Color3.new(0, 0.5, 1), "Camping_2")
local bed2 = tagged(tent2, "CampTent")[1]
check(not ParkService.useTent(leo, bed2) and string.find(lastNotice(leo).Text, "cuesta", 1, true) ~= nil, "Sin dinero: no se alquila")

local pitch = roblox.Instance.new("Part")
pitch.Name = "ParcelaLibre"
pitch.Size = Vector3.new(2, 1, 2)
pitch.CFrame = CFrame.new(350, 0.5, 0)
pitch:AddTag("CampPitch")
pitch.Parent = town
setupAll(pitch.Parent)
check(promptOf(pitch, "Montar mi tienda") ~= nil, "Parcela libre: «Montar mi tienda»")
check(ParkService.pitch(ana, pitch) and ParkService._pitched[ana] ~= nil, "Montas tu tienda gratis en la parcela")
local mine = ParkService._pitched[ana].Model
local myBed = mine:FindFirstChild("CamaTienda")
check(myBed and myBed:GetAttribute("Owner") == ana.UserId, "…es tuya (solo duermes tú)")
check(not ParkService.pitch(leo, pitch), "Nadie más puede montar en tu parcela")
check(not ParkService.useTent(leo, myBed), "…ni dormir en tu tienda")
local n = #sleeps
check(ParkService.pitch(ana, pitch) and #sleeps == n + 1, "Pulsar otra vez en tu parcela: a dormir")

---------------------------------------------------------------------
print("\n▶ 5. Huertos: la cocina")
---------------------------------------------------------------------
local cocina = roblox.Instance.new("Part")
cocina.Name = "Encimera"
cocina:AddTag("HuertoCocina")
cocina.Parent = town
ParkService._setups.HuertoCocina(cocina)
local cook = promptOf(cocina, "Cocinar con la cosecha")
check(cook ~= nil, "Cocina del huerto: «Cocinar con la cosecha»")
if cook then
	task.wait(0.2)
	cook.Triggered:Fire(ana)
	check(#kitchens == 1 and kitchens[1].Part == cocina, "…abre la cocina de FarmService (platos con lo cosechado)")
end
local huertos = fs.readFile("src/server/World/Kit/ZonasVerdes/Huertos.luau")
check(string.find(huertos, 'Builder.model("Granja"', 1, true) ~= nil and string.find(huertos, '"Crop"', 1, true) ~= nil and string.find(huertos, '"Granero"', 1, true) ~= nil,
	"Los huertos son un Model «Granja» con filas «Crop» y su «Granero» (FarmService lo monta solo)")

---------------------------------------------------------------------
-- 6. El mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if not placePath then
	print("\n(sin mapa: pasa un .rbxl construido para comprobar los sitios en el mapa)")
	L.finish("Zonas verdes y diversión")
	return
end
print("\n▶ 6. El mapa construido: " .. placePath)
local game = roblox.deserializePlace(fs.readFile(placePath))
local world = game:GetService("Workspace"):FindFirstChild("Town")
local folder = world and world:FindFirstChild("ZonasVerdes")
check(folder ~= nil, "Town.ZonasVerdes existe")
if not folder then
	L.finish("Zonas verdes y diversión")
	return
end
local function countParts(m): number
	local c = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			c += 1
		end
	end
	return c
end
local Parques = L.load("src/server/World/Kit/ZonasVerdes/Parques")
local sites, parks = {}, {}
for _, m in folder:GetChildren() do
	table.insert(sites, m)
	if m.Name == "ParqueVivo" then
		table.insert(parks, m)
	end
end
check(#parks == 30, ("30 parques vivos (%d)"):format(#parks))
local minP, maxP, total = math.huge, 0, 0
for _, park in parks do
	local c = countParts(park)
	minP, maxP = math.min(minP, c), math.max(maxP, c)
end
for _, m in sites do
	total += countParts(m)
end
check(minP >= Parques.MinParts and maxP <= Parques.MaxParts, ("Cada parque vivo, de %d a %d piezas (%d–%d)"):format(Parques.MinParts, Parques.MaxParts, minP, maxP))
local over = {}
for _, m in sites do
	local c = countParts(m)
	print(("     %-26s %4d piezas"):format(m.Name .. (if m:GetAttribute("ZoneId") then " (" .. tostring(m:GetAttribute("ZoneId")) .. ")" else ""), c))
	if c > 600 then
		table.insert(over, m.Name)
	end
end
check(#over == 0, "Ningún sitio pasa de 600 piezas" .. (if #over > 0 then ": " .. table.concat(over, ", ") else ""))
print(("     total: %d piezas nuevas"):format(total))
local streamOk = true
for _, m in sites do
	local ok, mode = pcall(function()
		return (m :: any).ModelStreamingMode
	end)
	if ok and mode ~= nil and mode ~= roblox.Enum.ModelStreamingMode.Atomic then
		streamOk = false
	end
end
check(streamOk, "Cada sitio llega entero con StreamingEnabled (Atomic)")

-- Lo que se usa, con su etiqueta
local function countTag(root, tag)
	local c = 0
	for _, d in root:GetDescendants() do
		if d:HasTag(tag) then
			c += 1
		end
	end
	return c
end
check(countTag(folder, "FunSwing") >= 60 and countTag(folder, "FunSlide") >= 29 and countTag(folder, "PicnicTable") >= 60, ("Columpios (%d), toboganes (%d) y mesas de pícnic (%d)"):format(countTag(folder, "FunSwing"), countTag(folder, "FunSlide"), countTag(folder, "PicnicTable")))
check(countTag(folder, "DogRunPost") >= 2 and countTag(folder, "DogRun") >= 2, ("Pipicanes (%d)"):format(countTag(folder, "DogRun")))
local courts = Court.scanMap(folder:GetDescendants())
check(#courts >= 20, ("Medias pistas que ve BasketService: %d"):format(#courts))
check(countTag(folder, "Campfire") >= 1 and countTag(world, "Campfire") >= 2, "Hogueras en el lago y en el Camping")
check(countTag(folder, "CampTent") >= 8 and countTag(folder, "CampPitch") == 4, ("Camping: %d tiendas que se alquilan y 4 parcelas"):format(countTag(folder, "CampTent")))
check(countTag(folder, "HuertoCocina") == 1, "Huertos: la cocina")
local farm = folder:FindFirstChild("HuertosPuertaVillaverde")
local farmModel = farm and farm:FindFirstChild("Granja")
local crops = 0
if farmModel then
	for _, c in farmModel:GetChildren() do
		if c:IsA("BasePart") and c.Name == "Crop" then
			crops += 1
		end
	end
end
check(crops == 20 and farmModel:FindFirstChild("Granero") ~= nil, ("Huertos: «Granja» con %d filas (4 fincas de 5) y su caseta"):format(crops))
check(countTag(folder, "FoodStand") >= 4, "Quioscos con comida (helado, limonada, bocadillos)")

-- Marcas de la historia en el solar de los Jardines de la Plaza Mayor (Valmar Centro)
local Plaza = L.load("src/server/World/Kit/ZonasVerdes/Plaza")
local R = Plaza.Rect
local marks = {}
for _, d in world:GetDescendants() do
	if d:IsA("BasePart") and (d:HasTag("StorySpot") or d:HasTag("StoryArea") or d:HasTag("StoryProp")) then
		local p = d.CFrame.Position
		if p.X > R.X0 - 10 and p.X < R.X1 + 10 and p.Z > R.Z0 - 10 and p.Z < R.Z1 + 10 then
			table.insert(marks, d.Name)
		end
	end
end
check(#marks == 0, "En los Jardines de la Plaza Mayor no hay marcas de la historia (StorySpot/StoryArea/StoryProp)" .. (if #marks > 0 then ": " .. table.concat(marks, ", ") else ""))

-- Nada encima de calles, aceras, edificios ni árboles (planta, con SAT de polígonos convexos)
local TREE = { Leaves = true, Branch = true, Trunk = true, Root = true, Frond = true, Flower = true, Bush = true, Hedge = true, Grass = true, Crown = true, Canopy = true }
local function footprint(part): { { number } }
	local cf, size = part.CFrame, part.Size
	local pts = {}
	for _, sx in { -0.5, 0.5 } do
		for _, sy in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				local p = cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
				table.insert(pts, { p.X, p.Z, p.Y })
			end
		end
	end
	-- Envolvente convexa en planta (cadena monótona)
	table.sort(pts, function(a, b)
		return if a[1] ~= b[1] then a[1] < b[1] else a[2] < b[2]
	end)
	local function cross(o, a, b)
		return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
	end
	local lower, upper = {}, {}
	for _, p in pts do
		while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 1e-9 do
			table.remove(lower)
		end
		table.insert(lower, p)
	end
	for i = #pts, 1, -1 do
		local p = pts[i]
		while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 1e-9 do
			table.remove(upper)
		end
		table.insert(upper, p)
	end
	table.remove(lower)
	table.remove(upper)
	for _, p in upper do
		table.insert(lower, p)
	end
	return lower
end
local function bounds(poly)
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for _, p in poly do
		x0, x1, z0, z1 = math.min(x0, p[1]), math.max(x1, p[1]), math.min(z0, p[2]), math.max(z1, p[2])
	end
	return x0, x1, z0, z1
end
local TOL = 0.35 -- (rozarse por el borde no cuenta)
local function overlap(a, b): boolean
	for _, poly in { a, b } do
		for i = 1, #poly do
			local p, q = poly[i], poly[i % #poly + 1]
			local nx, nz = q[2] - p[2], p[1] - q[1]
			local len = math.sqrt(nx * nx + nz * nz)
			if len > 1e-6 then
				nx, nz = nx / len, nz / len
				local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
				for _, v in a do
					local d = v[1] * nx + v[2] * nz
					amin, amax = math.min(amin, d), math.max(amax, d)
				end
				for _, v in b do
					local d = v[1] * nx + v[2] * nz
					bmin, bmax = math.min(bmin, d), math.max(bmax, d)
				end
				if amax - TOL <= bmin or bmax - TOL <= amin then
					return false
				end
			end
		end
	end
	return true
end
-- Las piezas nuevas (visibles) por sitio y su caja
local mine = {}
local boxes = {}
for _, m in sites do
	local list = {}
	local bx0, bx1, bz0, bz1 = math.huge, -math.huge, math.huge, -math.huge
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.9 then
			local poly = footprint(d)
			local x0, x1, z0, z1 = bounds(poly)
			table.insert(list, { Part = d, Poly = poly, X0 = x0, X1 = x1, Z0 = z0, Z1 = z1 })
			bx0, bx1, bz0, bz1 = math.min(bx0, x0), math.max(bx1, x0, x1), math.min(bz0, z0), math.max(bz1, z1)
		end
	end
	mine[m] = list
	boxes[m] = { bx0 - 2, bx1 + 2, bz0 - 2, bz1 + 2 }
end
-- Lo construido (como 1_mascaras.py): todo menos los suelos de manzana, el césped plano, los árboles,
-- lo invisible y lo de las zonas verdes. Solo lo que está a ras de suelo (abajo por debajo de 2.5).
local obstacles = {}
local inFolder = {}
for _, d in folder:GetDescendants() do
	inFolder[d] = true
end
for _, d in world:GetDescendants() do
	if d:IsA("BasePart") and not inFolder[d] and d.Transparency < 0.9 and d.Name ~= "BlockGround" and not TREE[d.Name] then
		local p = d.CFrame.Position
		local mat = d.Material
		local flatGrass = (mat == roblox.Enum.Material.Grass or mat == roblox.Enum.Material.LeafyGrass) and p.Y + d.Size.Y / 2 < 1.5
		if not flatGrass and p.Y < 60 and not d:HasTag("EditOnly") then
			for _, m in sites do
				local b = boxes[m]
				local reach = math.max(d.Size.X, d.Size.Y, d.Size.Z)
				if p.X > b[1] - reach and p.X < b[2] + reach and p.Z > b[3] - reach and p.Z < b[4] + reach then
					local poly = footprint(d)
					local x0, x1, z0, z1 = bounds(poly)
					local cf, size = d.CFrame, d.Size
					local bottom, topY = math.huge, -math.huge
					for _, sx in { -0.5, 0.5 } do
						for _, sy in { -0.5, 0.5 } do
							for _, sz in { -0.5, 0.5 } do
								local y = (cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)).Y
								bottom, topY = math.min(bottom, y), math.max(topY, y)
							end
						end
					end
					if bottom < 2.5 and topY > -2 then -- (a ras de suelo; lo de debajo, el metro, no cuenta)
						table.insert(obstacles, { Part = d, Poly = poly, X0 = x0, X1 = x1, Z0 = z0, Z1 = z1, Site = m })
					end
					break
				end
			end
		end
	end
end
local clashes = {}
for _, o in obstacles do
	for _, mp in mine[o.Site] do
		if mp.X1 > o.X0 + TOL and mp.X0 < o.X1 - TOL and mp.Z1 > o.Z0 + TOL and mp.Z0 < o.Z1 - TOL and overlap(mp.Poly, o.Poly) then
			table.insert(clashes, ("%s/%s ↔ %s/%s"):format(o.Site.Name, mp.Part.Name, o.Part.Parent and o.Part.Parent.Name or "?", o.Part.Name))
			break
		end
	end
end
for i = 1, math.min(#clashes, 15) do
	print("     ⚠ " .. clashes[i])
end
check(#clashes == 0, ("Nada encima de calles, aceras, edificios ni árboles (%d cruces; %d piezas mías frente a %d de alrededor)"):format(#clashes, (function()
	local c = 0
	for _, l in mine do
		c += #l
	end
	return c
end)(), #obstacles))

L.finish("Zonas verdes y diversión")
