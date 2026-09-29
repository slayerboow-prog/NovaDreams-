-- Wildlife (cliente): animales alrededor del jugador, como el tráfico de Ambient: se simulan en cada
-- dispositivo y solo cerca, así el mundo parece vivo sin coste de red ni de servidor.
--  * Bandadas de pájaros en el cielo (gaviotas en Playa Dorada), de día y si no llueve
--  * Palomas y gorriones en el suelo: picotean, dan saltitos y salen volando si te acercas
--  * Mariposas en primavera y verano; luciérnagas en las noches de verano
--  * Patos y gaviotas flotando en el agua (lagos, estanques y el mar)
--  * Perros y gatos paseando por las ciudades; vacas, ovejas y gallinas en Villaverde
--  * Cómo se mueve cada uno (patas, cabeza, cola; sentarse, pastar, olfatear…): AnimalPose.
--    El perro a veces se acerca a ti, se sienta a tu lado y mueve la cola.
--  * Los que andan por la ciudad (perros, gatos, palomas…) van por aceras, parques y plazas: nunca
--    eligen un sitio en la calzada ni cruzan la calle (shared/Walkable, con las calles que publica el
--    servidor). Las vacas, ovejas y gallinas no se alejan de su granja.
--  * Si pasas a su lado o chocas con ellos se asustan: dan un salto, ladran/maúllan/cacarean y se
--    apartan unos pasos (las palomas salen volando); si los empujas, se mueven. Si viene un coche,
--    saltan a un lado. Nunca se hacen daño.
-- Cuántos salen depende de la estación y del tiempo (shared/Seasons: Birds, Butterflies, Ground).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Walkable = require(ReplicatedStorage.Shared.Walkable)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local AnimalPose = require(script.Parent.AnimalPose)
local Nudge = require(script.Parent.Nudge)

local Wildlife = {}

local player = Players.LocalPlayer

local folder: Folder
local lowQuality = false

type Piece = AnimalPose.Piece
type Animal = {
	Kind: string,
	Pieces: { Piece },
	Info: AnimalPose.Info,
	Pose: AnimalPose.State,
	Frames: { CFrame },
	Root: CFrame,
	Active: boolean,
	State: string, -- "idle" | "walk" | "fly" | "flee" | "float"
	Target: Vector3?,
	Timer: number,
	Phase: number,
	Speed: number,
	Center: Vector3?,
	Radius: number?,
	Height: number?,
	Group: number?,
	NextTry: number?,
	Home: Vector3?, -- (granja) de aquí no se alejan
	ReactAt: number?, -- hasta cuándo no se vuelve a asustar
	Scurry: boolean?, -- huyendo unos pasos (más deprisa)
}

local animals: { [string]: { Animal } } = {}
local roadIndex: Walkable.Index? = nil -- calzadas (no se pisan)
local ROAD_MARGIN = 1.5 -- ni siquiera pegados al bordillo
local FARM_RADIUS = 26
local FARM = { Vaca = true, Oveja = true, Gallina = true }
local VOICE = { Perro = "¡Guau!", Gato = "¡Miau!", Gallina = "¡Cocoró!", Vaca = "¡Muuu!", Oveja = "¡Beee!", Paloma = "¡Currucucú!", Pato = "¡Cuac!" }
local zones: { { Name: string, Center: Vector3 } } = {}

local STAND = AnimalPose.Stand
local WALK_SPEED = AnimalPose.WalkSpeed

local function newAnimal(kind: string): Animal
	local list, info = AnimalPose.build(kind)
	return {
		Kind = kind, Pieces = list, Info = info, Pose = AnimalPose.newState(kind), Frames = {},
		Root = CFrame.new(0, -500, 0), Active = false,
		State = "idle", Timer = 0, Phase = math.random() * 10, Speed = WALK_SPEED[kind] or 2,
	}
end

local function hide(a: Animal)
	a.Active = false
	for _, p in a.Pieces do
		p.Part.CFrame = CFrame.new(0, -500, 0)
	end
end

-- Coloca las piezas (patas, cabeza, cola, alas: AnimalPose). lookYaw: hacia el jugador, si está cerca
local function render(a: Animal, t: number, dt: number, lookYaw: number?, near: boolean)
	local pose = a.Pose
	pose.State = a.State
	pose.Phase = a.Phase
	AnimalPose.step(pose, dt, a.Speed, lookYaw, near)
	AnimalPose.pose(a.Pieces, a.Info, pose, t, a.Frames)
	for i, p in a.Pieces do
		p.Part.CFrame = a.Root * a.Frames[i]
		if p.Role == "Glow" then
			p.Part.Transparency = 0.2 + 0.7 * (0.5 + 0.5 * math.sin(t * 2.5 + a.Phase))
		end
	end
end

---------------------------------------------------------------------
-- Dónde está el suelo (y qué es)
---------------------------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function ground(x: number, z: number, maxY: number): RaycastResult?
	local exclude = { folder, workspace.CurrentCamera }
	if player.Character then
		table.insert(exclude, player.Character)
	end
	rayParams.FilterDescendantsInstances = exclude
	-- (solo suelo de verdad: el perro no se sube al techo de un coche ni a una persona)
	return Ground.cast(Vector3.new(x, maxY, z), Vector3.new(0, -maxY + -200, 0), rayParams)
end

local function playerPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

local function zoneAt(position: Vector3): string?
	local best, bestDistance = nil, math.huge
	for _, zone in zones do
		local d = Vector2.new(position.X - zone.Center.X, position.Z - zone.Center.Z).Magnitude
		if d < bestDistance then
			best, bestDistance = zone.Name, d
		end
	end
	return best
end

-- Un punto de suelo "de calle" cerca (no en un tejado), o nil. En tierra, nunca en la calzada y,
-- si se da "from", que se pueda llegar en línea recta sin cruzar la calle; "home" = no alejarse de ahí
local function groundSpot(around: Vector3, minR: number, maxR: number, wantWater: boolean?, from: Vector3?, home: Vector3?): (Vector3?, Enum.Material?)
	for _ = 1, if wantWater then 4 else 7 do
		local x, z
		if wantWater then
			local angle = math.random() * math.pi * 2
			local r = minR + math.random() * (maxR - minR)
			x, z = around.X + math.cos(angle) * r, around.Z + math.sin(angle) * r
		else
			x, z = Walkable.pick(roadIndex, around, minR, maxR, from, home, FARM_RADIUS, nil, ROAD_MARGIN)
			if not x or not z then
				continue
			end
		end
		local hit = ground(x, z, around.Y + 40)
		if hit and hit.Position.Y < around.Y + 6 and hit.Normal.Y > 0.8 then
			local isWater = hit.Material == Enum.Material.Water
			if isWater == (wantWater == true) then
				return hit.Position, hit.Material
			end
		end
	end
	return nil
end

-- Velocidad del vehículo en el que vas (0 si vas a pie)
local function vehicleSpeed(): number
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat then
		local v = seat.AssemblyLinearVelocity
		return Vector3.new(v.X, 0, v.Z).Magnitude
	end
	return 0
end

---------------------------------------------------------------------
-- Comportamientos
---------------------------------------------------------------------

local function isDay(): boolean
	local h = Lighting.ClockTime
	return h >= 6.5 and h <= 20
end

local function conditions(): (any, any)
	local season = Seasons.Info[workspace:GetAttribute("Season") or "Primavera"] or Seasons.Info.Primavera
	local weather = Seasons.Weather[workspace:GetAttribute("Weather") or "Despejado"] or Seasons.Weather.Despejado
	return season, weather
end

-- Cuántos de cada especie tiene que haber ahora mismo
local function wanted(kind: string, where: string?): number
	local season, weather = conditions()
	local day = isDay()
	local wet = weather.Rain or weather.Snow
	local q = if lowQuality then 0.5 else 1
	if kind == "Pajaro" then
		return if day and not wet and where ~= "Playa Dorada" then math.floor(12 * season.Birds * q) else 0
	elseif kind == "Gaviota" then
		return if day and not weather.Lightning and where == "Playa Dorada" then math.floor(8 * q) else 0
	elseif kind == "Paloma" then
		return if day and not weather.Lightning and not weather.Snow and where ~= "Villaverde" then math.floor(8 * season.Ground * q) else 0
	elseif kind == "Mariposa" then
		return if day and not wet then math.floor(6 * season.Butterflies * q) else 0
	elseif kind == "Luciernaga" then
		return if not day and workspace:GetAttribute("Season") == "Verano" and not wet then math.floor(14 * q) else 0
	elseif kind == "Pato" then
		return if day then math.floor(5 * q) else 0
	elseif kind == "Perro" then
		return if day and not weather.Lightning and where ~= "Villaverde" then 2 else 0
	elseif kind == "Gato" then
		return if not weather.Rain and where ~= "Villaverde" then 2 else 0
	elseif kind == "Vaca" then
		return if where == "Villaverde" and not weather.Lightning then 3 else 0
	elseif kind == "Oveja" then
		return if where == "Villaverde" and not weather.Lightning then 4 else 0
	elseif kind == "Gallina" then
		return if where == "Villaverde" and not wet then 5 else 0
	end
	return 0
end

local FLYERS = { Pajaro = true, Gaviota = true }
local WALKERS = { Paloma = true, Perro = true, Gato = true, Vaca = true, Oveja = true, Gallina = true }

-- Coloca un animal que acaba de "nacer" cerca del jugador
local function spawnAnimal(a: Animal, around: Vector3, index: number): boolean
	if FLYERS[a.Kind] then
		-- Bandadas: cada 6 pájaros comparten centro; vuelan en círculos a 30-60 studs de altura
		local group = (index - 1) // 6
		a.Group = group
		local angle = group * 2.1 + math.random()
		a.Center = around + Vector3.new(math.cos(angle) * 60, 0, math.sin(angle) * 60)
		a.Radius = 18 + math.random() * 14
		a.Height = 32 + group * 8 + math.random() * 6
		a.State = "fly"
		a.Speed = (if a.Kind == "Gaviota" then 0.35 else 0.6) * (0.9 + math.random() * 0.2)
		a.Phase = math.random() * math.pi * 2
		a.Active = true
		return true
	elseif a.Kind == "Mariposa" or a.Kind == "Luciernaga" then
		local spot = groundSpot(around, 6, 26)
		if not spot then
			return false
		end
		a.Center = spot + Vector3.new(0, if a.Kind == "Mariposa" then 1.5 else 1, 0)
		a.State = "fly"
		a.Active = true
		return true
	elseif a.Kind == "Pato" then
		local spot = groundSpot(around, 10, 70, true)
		if not spot then
			return false
		end
		a.Root = CFrame.new(spot + Vector3.new(0, STAND.Pato, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
		a.State = "float"
		a.Pose.Action = "swim"
		a.Timer = 3 + math.random() * 5
		a.Active = true
		return true
	end
	local spot, material = groundSpot(around, 14, 55)
	if not spot then
		return false
	end
	-- Las vacas y ovejas, solo sobre hierba
	if (a.Kind == "Vaca" or a.Kind == "Oveja") and material ~= Enum.Material.Grass and material ~= Enum.Material.LeafyGrass then
		return false
	end
	a.Home = if FARM[a.Kind] then spot else nil
	a.Speed = WALK_SPEED[a.Kind] or 2
	a.Scurry = nil
	a.Root = CFrame.new(spot + Vector3.new(0, STAND[a.Kind] or 0.5, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
	a.State = "idle"
	a.Pose.Action = AnimalPose.chooseAction(a.Kind)
	a.Timer = 1 + math.random() * 4
	a.Active = true
	return true
end

local function stepFlyer(a: Animal, t: number, dt: number, around: Vector3)
	local angle = t * a.Speed + a.Phase
	local center = a.Center :: Vector3
	-- La bandada sigue al jugador poco a poco
	a.Center = center:Lerp(Vector3.new(around.X, center.Y, around.Z), dt * 0.02)
	local pos = (a.Center :: Vector3) + Vector3.new(math.cos(angle) * (a.Radius :: number), (a.Height :: number) + math.sin(t * 0.7 + a.Phase) * 2, math.sin(angle) * (a.Radius :: number))
	local ahead = (a.Center :: Vector3) + Vector3.new(math.cos(angle + 0.1) * (a.Radius :: number), (a.Height :: number), math.sin(angle + 0.1) * (a.Radius :: number))
	a.Root = CFrame.lookAt(pos, Vector3.new(ahead.X, pos.Y, ahead.Z)) * CFrame.Angles(0, 0, math.rad(-18))
end

local function stepFluttery(a: Animal, t: number)
	local c = a.Center :: Vector3
	local p = a.Phase
	local pos = c + Vector3.new(math.sin(t * 0.9 + p) * 3, math.sin(t * 2.3 + p) * 0.6, math.cos(t * 0.7 + p * 2) * 3)
	local ahead = c + Vector3.new(math.sin(t * 0.9 + 0.1 + p) * 3, 0, math.cos(t * 0.7 + 0.1 + p * 2) * 3)
	a.Root = CFrame.lookAt(pos, Vector3.new(ahead.X, pos.Y, ahead.Z))
end

-- Susto: salta, "dice" algo y se aparta unos pasos sin pisar la calzada (ni salir de su granja)
local function startle(a: Animal, t: number, around: Vector3, car: boolean)
	a.ReactAt = t + 2.5
	AnimalPose.startle(a.Pose)
	local voice = VOICE[a.Kind]
	if voice then
		Nudge.say(a.Pieces[1] and a.Pieces[1].Part, voice, 1.4)
	end
	local pos = a.Root.Position
	local target = Walkable.escape(roadIndex, pos, around, if car then 10 else 5 + math.random() * 3, ROAD_MARGIN * 0.5)
	if target and a.Home and Vector2.new(target.X - a.Home.X, target.Z - a.Home.Z).Magnitude > FARM_RADIUS then
		target = nil
	end
	if target then
		local hit = ground(target.X, target.Z, pos.Y + 6)
		if hit and math.abs(hit.Position.Y - (pos.Y - (STAND[a.Kind] or 0.5))) < 3 then
			a.Target = hit.Position + Vector3.new(0, STAND[a.Kind] or 0.5, 0)
			a.State = "walk"
			a.Timer = 3
			a.Speed = (WALK_SPEED[a.Kind] or 2) * (if car then 3.4 else 2.6)
			a.Scurry = true
		end
	end
end

local function stepWalker(a: Animal, t: number, dt: number, around: Vector3)
	local pos = a.Root.Position
	local d = Vector2.new(pos.X - around.X, pos.Z - around.Z).Magnitude
	-- Las palomas salen volando si te acercas demasiado (aleteando)
	if (a.Kind == "Paloma") and a.State ~= "flee" then
		if d < 9 then
			a.State = "flee"
			a.Timer = 3
			AnimalPose.startle(a.Pose)
			local away = Vector3.new(pos.X - around.X, 0, pos.Z - around.Z)
			a.Target = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
		end
	end
	if a.State == "flee" then
		local dir = a.Target :: Vector3
		local newPos = pos + dir * 14 * dt + Vector3.new(0, 7 * dt, 0)
		a.Root = CFrame.lookAt(newPos, newPos + dir)
		a.Timer -= dt
		if a.Timer <= 0 then
			hide(a) -- se ha ido volando; ya saldrá otra
		end
		return
	end
	-- Si pasas a su lado (o viene tu coche), se asusta y se aparta
	local car = vehicleSpeed() > 10
	if (d < 3.4 or (car and d < 9)) and t >= (a.ReactAt or 0) and pos.Y < around.Y + 4 then
		startle(a, t, around, car)
	end
	-- Empujón suave: si te metes encima, se desplaza (sin acabar en la calzada)
	if d < 2.3 and d > 0.01 then
		local away = Vector3.new(pos.X - around.X, 0, pos.Z - around.Z).Unit
		local push = away * math.min(2.3 - d, 6 * dt)
		local np = pos + push
		if not Walkable.onRoad(roadIndex, np.X, np.Z, 0.3) then
			a.Root = a.Root + push
			pos = np
		end
	end
	a.Timer -= dt
	if a.State == "idle" then
		if a.Timer <= 0 then
			-- A andar un poco: a un sitio cercano con suelo. El perro, a veces, viene a verte
			local toPlayer = Vector3.new(around.X - pos.X, 0, around.Z - pos.Z)
			local spot: Vector3? = nil
			if a.Kind == "Perro" and toPlayer.Magnitude < 28 and toPlayer.Magnitude > 4 and math.random() < 0.5 then
				local gx, gz = around.X - toPlayer.Unit.X * 3, around.Z - toPlayer.Unit.Z * 3
				if not Walkable.onRoad(roadIndex, gx, gz, ROAD_MARGIN) and Walkable.pathClear(roadIndex, pos, Vector3.new(gx, pos.Y, gz), ROAD_MARGIN * 0.5) then
					local hit = ground(gx, gz, around.Y + 6)
					spot = hit and hit.Position
				end
			end
			spot = spot or groundSpot(pos, 2, if a.Kind == "Perro" then 12 else 6, false, pos, a.Home)
			if spot then
				a.Target = spot + Vector3.new(0, STAND[a.Kind] or 0.5, 0)
				a.State = "walk"
				a.Timer = 8
			else
				a.Timer = 2
			end
		end
	elseif a.State == "walk" then
		local target = a.Target :: Vector3
		local flat = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		if flat.Magnitude < 0.3 or a.Timer <= 0 then
			a.State = "idle"
			if a.Scurry then
				a.Scurry = nil
				a.Speed = WALK_SPEED[a.Kind] or 2
			end
			-- Qué hace ahora que se ha parado (sentarse, pastar, olfatear…): un rato más largo si se tumba
			local action = AnimalPose.chooseAction(a.Kind)
			local nearPlayer = Vector2.new(around.X - pos.X, around.Z - pos.Z).Magnitude < 6
			if a.Kind == "Perro" and nearPlayer then
				action = "sit" -- a tu lado, moviendo la cola
			end
			a.Pose.Action = action
			a.Timer = if action == "lie" or action == "sit" or action == "graze" then 5 + math.random() * 9 else 2 + math.random() * 6
		else
			local stepLen = math.min(flat.Magnitude, a.Speed * dt)
			local newPos = pos + flat.Unit * stepLen
			newPos = Vector3.new(newPos.X, pos.Y + (target.Y - pos.Y) * math.min(1, dt * 4), newPos.Z)
			-- (por si acaso: nunca un paso dentro de la calzada)
			if Walkable.onRoad(roadIndex, newPos.X, newPos.Z, 0.2) and not Walkable.onRoad(roadIndex, pos.X, pos.Z, 0.2) then
				a.State = "idle"
				a.Timer = 0.5
			else
				a.Root = CFrame.lookAt(newPos, newPos + flat.Unit)
			end
		end
	end
end

local function stepFloat(a: Animal, t: number, dt: number, around: Vector3)
	-- Si te acercas (nadando o por la orilla), se asusta, aletea, hace "¡Cuac!" y se aleja nadando
	local here = a.Root.Position
	local d = Vector2.new(here.X - around.X, here.Z - around.Z).Magnitude
	if d < 5 and t >= (a.ReactAt or 0) then
		a.ReactAt = t + 3
		AnimalPose.startle(a.Pose)
		Nudge.say(a.Pieces[1] and a.Pieces[1].Part, VOICE.Pato, 1.2)
		local away = Vector3.new(here.X - around.X, 0, here.Z - around.Z)
		if away.Magnitude > 0.05 then
			a.Root = CFrame.lookAt(here, here + away.Unit)
		end
	end
	-- A ratos mete la cabeza en el agua (con la cola hacia arriba)
	a.Timer -= dt
	if a.Timer <= 0 then
		a.Pose.Action = if a.Pose.Action == "dabble" then "swim" else AnimalPose.chooseAction("Pato")
		a.Timer = if a.Pose.Action == "dabble" then 1.5 + math.random() * 1.5 else 3 + math.random() * 6
	end
	local pos = a.Root.Position
	local look = a.Root.LookVector
	local turn = math.sin(t * 0.3 + a.Phase) * 0.3 * dt
	local dir = (CFrame.Angles(0, turn, 0) * look)
	local paddle = if t < (a.ReactAt or 0) - 1.5 then 3 else 0.6 -- al asustarse, nada deprisa un momento
	local newPos = pos + dir * paddle * dt + Vector3.new(0, math.sin(t * 1.5 + a.Phase) * 0.004, 0)
	a.Root = CFrame.lookAt(newPos, newPos + dir)
end

---------------------------------------------------------------------

local KINDS = { "Pajaro", "Gaviota", "Paloma", "Mariposa", "Luciernaga", "Pato", "Perro", "Gato", "Vaca", "Oveja", "Gallina" }
local MAX = { Pajaro = 18, Gaviota = 8, Paloma = 8, Mariposa = 8, Luciernaga = 14, Pato = 5, Perro = 2, Gato = 2, Vaca = 3, Oveja = 4, Gallina = 5 }
local DESPAWN = 110 -- más lejos que esto, el animal desaparece y sale otro cerca

local function update(t: number, dt: number)
	local around = playerPosition()
	-- Dentro de un edificio (salas en el cielo) no salen animales en el suelo de la sala
	if not around or around.Y > 3000 then
		return
	end
	local where = zoneAt(around)
	for _, kind in KINDS do
		local list = animals[kind]
		local want = math.min(wanted(kind, where), MAX[kind])
		for i, a in list do
			if i > want then
				if a.Active then
					hide(a)
				end
			elseif not a.Active then
				-- Si no encuentra sitio, lo vuelve a intentar dentro de un rato (sin gastar rayos cada vuelta)
				if t >= (a.NextTry or 0) and not spawnAnimal(a, around, i) then
					a.NextTry = t + 1.5 + math.random()
				end
			else
				local pos = a.Root.Position
				local far = Vector2.new(pos.X - around.X, pos.Z - around.Z).Magnitude > DESPAWN
				if far and not FLYERS[kind] then
					hide(a)
				else
					if FLYERS[kind] then
						stepFlyer(a, t, dt, around)
					elseif kind == "Mariposa" or kind == "Luciernaga" then
						stepFluttery(a, t)
					elseif kind == "Pato" then
						stepFloat(a, t, dt, around)
					elseif WALKERS[kind] then
						stepWalker(a, t, dt, around)
					end
					if a.Active then
						-- ¿Estás cerca? Te mira (y el perro se pone contento)
						local lookYaw: number? = nil
						local rel = a.Root:PointToObjectSpace(around)
						local distance = Vector2.new(rel.X, rel.Z).Magnitude
						if distance < 12 then
							local yaw = math.atan2(-rel.X, -rel.Z)
							if math.abs(yaw) < 2 then
								lookYaw = yaw
							end
						end
						render(a, t, dt, lookYaw, distance < 8)
					end
				end
			end
		end
	end
end

function Wildlife.init()
	folder = Instance.new("Folder")
	folder.Name = "Wildlife"
	folder.Parent = workspace.CurrentCamera -- solo existe para este jugador
	AnimalPose.folder = folder
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	lowQuality = (ok and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 3) or require(script.Parent.Parent.UI.Perf).lite
	-- Calzadas (las publica el servidor): los animales no las pisan
	task.spawn(function()
		local data = ReplicatedStorage:WaitForChild("Ambient", 60)
		local roads = data and data:WaitForChild("Roads", 10)
		if roads then
			roadIndex = Walkable.fromFolder(roads, CityPlan.Roundabouts)
		end
	end)
	local zoneFolder = ReplicatedStorage:WaitForChild("MapZones", 10)
	if zoneFolder then
		for _, config in zoneFolder:GetChildren() do
			local name, center = config:GetAttribute("ZoneName"), config:GetAttribute("Center")
			if type(name) == "string" and typeof(center) == "Vector3" then
				table.insert(zones, { Name = name, Center = center })
			end
		end
	end
	for _, kind in KINDS do
		animals[kind] = {}
		for _ = 1, MAX[kind] do
			local a = newAnimal(kind)
			hide(a)
			table.insert(animals[kind], a)
		end
	end
	local since, t = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		since += dt
		if since < 1 / 30 then
			return
		end
		local ok2, err = pcall(update, t, since)
		since = 0
		if not ok2 then
			warn("[Wildlife] " .. tostring(err))
		end
	end)
end

return Wildlife
