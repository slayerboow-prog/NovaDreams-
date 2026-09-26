-- Wildlife (cliente): animales alrededor del jugador, como el tráfico de Ambient: se simulan en cada
-- dispositivo y solo cerca, así el mundo parece vivo sin coste de red ni de servidor.
--  * Bandadas de pájaros en el cielo (gaviotas en Playa Dorada), de día y si no llueve
--  * Palomas y gorriones en el suelo: picotean, dan saltitos y salen volando si te acercas
--  * Mariposas en primavera y verano; luciérnagas en las noches de verano
--  * Patos y gaviotas flotando en el agua (lagos, estanques y el mar)
--  * Perros y gatos paseando por las ciudades; vacas, ovejas y gallinas en Villaverde
-- Cuántos salen depende de la estación y del tiempo (shared/Seasons: Birds, Butterflies, Ground).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Seasons = require(ReplicatedStorage.Shared.Seasons)

local Wildlife = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local V = Vector3.new

local folder: Folder
local lowQuality = false

type Piece = { Part: BasePart, Offset: CFrame, Role: string? }
type Animal = {
	Kind: string,
	Pieces: { Piece },
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
}

local animals: { [string]: { Animal } } = {}
local zones: { { Name: string, Center: Vector3 } } = {}

---------------------------------------------------------------------
-- Modelos hechos con piezas (sin mallas: ligeros y siempre disponibles)
---------------------------------------------------------------------

local function piece(list: { Piece }, size: Vector3, color: Color3, offset: CFrame, role: string?, shape: Enum.PartType?, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	table.insert(list, { Part = p, Offset = offset, Role = role })
end

local BALL = Enum.PartType.Ball
local C = CFrame.new

local BUILDERS: { [string]: (list: { Piece }) -> () } = {
	-- Pájaro pequeño (gorrión, golondrina)
	Pajaro = function(l)
		local body, wing = rgb(96, 74, 56), rgb(70, 54, 42)
		piece(l, V(0.5, 0.45, 0.8), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.36, 0.36, 0.36), body, C(0, 0.2, -0.42), nil, BALL)
		piece(l, V(0.08, 0.08, 0.18), rgb(230, 170, 60), C(0, 0.18, -0.64))
		piece(l, V(0.7, 0.05, 0.4), wing, C(-0.45, 0.08, 0), "WingL")
		piece(l, V(0.7, 0.05, 0.4), wing, C(0.45, 0.08, 0), "WingR")
		piece(l, V(0.25, 0.05, 0.4), wing, C(0, 0.05, 0.55))
	end,
	Gaviota = function(l)
		local body, wing = rgb(240, 240, 240), rgb(170, 176, 186)
		piece(l, V(0.8, 0.7, 1.4), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.55, 0.55, 0.55), body, C(0, 0.3, -0.7), nil, BALL)
		piece(l, V(0.12, 0.12, 0.35), rgb(240, 200, 60), C(0, 0.25, -1.05))
		piece(l, V(1.6, 0.06, 0.6), wing, C(-0.95, 0.12, 0), "WingL")
		piece(l, V(1.6, 0.06, 0.6), wing, C(0.95, 0.12, 0), "WingR")
		piece(l, V(0.4, 0.06, 0.5), wing, C(0, 0.08, 0.85))
	end,
	Paloma = function(l)
		local body, wing = rgb(150, 150, 160), rgb(120, 120, 132)
		piece(l, V(0.7, 0.65, 1), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.42, 0.42, 0.42), rgb(96, 110, 120), C(0, 0.35, -0.45), "Head", BALL)
		piece(l, V(0.08, 0.08, 0.2), rgb(60, 60, 60), C(0, 0.32, -0.72), "Head")
		piece(l, V(0.9, 0.05, 0.45), wing, C(-0.4, 0.15, 0.05), "WingL")
		piece(l, V(0.9, 0.05, 0.45), wing, C(0.4, 0.15, 0.05), "WingR")
		piece(l, V(0.06, 0.35, 0.06), rgb(220, 110, 110), C(-0.15, -0.45, 0), "Leg1")
		piece(l, V(0.06, 0.35, 0.06), rgb(220, 110, 110), C(0.15, -0.45, 0), "Leg2")
	end,
	Mariposa = function(l)
		local colors = { rgb(250, 190, 40), rgb(120, 170, 250), rgb(250, 250, 250), rgb(240, 120, 60), rgb(200, 120, 230) }
		local color = colors[math.random(1, #colors)]
		piece(l, V(0.06, 0.06, 0.35), rgb(40, 30, 30), C(0, 0, 0))
		piece(l, V(0.4, 0.02, 0.35), color, C(-0.22, 0, 0), "WingL", nil, Enum.Material.Neon)
		piece(l, V(0.4, 0.02, 0.35), color, C(0.22, 0, 0), "WingR", nil, Enum.Material.Neon)
	end,
	Luciernaga = function(l)
		piece(l, V(0.15, 0.15, 0.15), rgb(220, 255, 120), C(0, 0, 0), "Glow", BALL, Enum.Material.Neon)
	end,
	Pato = function(l)
		piece(l, V(0.9, 0.6, 1.4), rgb(120, 96, 70), C(0, 0, 0), nil, BALL)
		piece(l, V(0.5, 0.5, 0.5), rgb(30, 110, 60), C(0, 0.45, -0.55), "Head", BALL)
		piece(l, V(0.3, 0.1, 0.35), rgb(240, 190, 50), C(0, 0.4, -0.9), "Head")
		piece(l, V(0.3, 0.1, 0.3), rgb(250, 250, 250), C(0, 0.25, -0.35))
	end,
	Perro = function(l)
		local coat = ({ rgb(200, 150, 90), rgb(60, 50, 45), rgb(230, 220, 200) })[math.random(1, 3)]
		piece(l, V(0.9, 0.8, 1.8), coat, C(0, 0, 0))
		piece(l, V(0.7, 0.7, 0.7), coat, C(0, 0.45, -1.1), "Head")
		piece(l, V(0.35, 0.3, 0.4), coat:Lerp(Color3.new(0, 0, 0), 0.2), C(0, 0.3, -1.55), "Head")
		piece(l, V(0.2, 0.35, 0.15), coat:Lerp(Color3.new(0, 0, 0), 0.3), C(-0.25, 0.9, -1.05), "Head")
		piece(l, V(0.2, 0.35, 0.15), coat:Lerp(Color3.new(0, 0, 0), 0.3), C(0.25, 0.9, -1.05), "Head")
		piece(l, V(0.15, 0.15, 0.7), coat, C(0, 0.35, 1.1) * CFrame.Angles(math.rad(35), 0, 0), "Tail")
		for i, pos in { V(-0.3, -0.7, -0.6), V(0.3, -0.7, -0.6), V(-0.3, -0.7, 0.6), V(0.3, -0.7, 0.6) } do
			piece(l, V(0.22, 0.7, 0.22), coat, C(pos), "Leg" .. i)
		end
	end,
	Gato = function(l)
		local coat = ({ rgb(230, 140, 50), rgb(40, 40, 44), rgb(160, 160, 165), rgb(245, 240, 230) })[math.random(1, 4)]
		piece(l, V(0.6, 0.55, 1.3), coat, C(0, 0, 0))
		piece(l, V(0.55, 0.5, 0.5), coat, C(0, 0.35, -0.8), "Head")
		piece(l, V(0.12, 0.2, 0.08), coat, C(-0.17, 0.68, -0.8), "Head")
		piece(l, V(0.12, 0.2, 0.08), coat, C(0.17, 0.68, -0.8), "Head")
		piece(l, V(0.1, 0.1, 0.9), coat, C(0, 0.45, 0.95) * CFrame.Angles(math.rad(-50), 0, 0), "Tail")
		for i, pos in { V(-0.2, -0.45, -0.45), V(0.2, -0.45, -0.45), V(-0.2, -0.45, 0.45), V(0.2, -0.45, 0.45) } do
			piece(l, V(0.14, 0.45, 0.14), coat, C(pos), "Leg" .. i)
		end
	end,
	Vaca = function(l)
		local white, black = rgb(245, 245, 240), rgb(30, 30, 32)
		piece(l, V(2, 1.8, 3.4), white, C(0, 0, 0))
		piece(l, V(1.2, 1.2, 0.1), black, C(0.5, 0.3, 0.2) * CFrame.Angles(0, math.rad(90), 0))
		piece(l, V(1.2, 1.2, 1.4), white, C(0, 0.5, -2.1), "Head")
		piece(l, V(0.9, 0.6, 0.4), rgb(240, 170, 170), C(0, 0.2, -2.85), "Head")
		piece(l, V(0.15, 0.4, 0.15), rgb(230, 220, 190), C(-0.5, 1.25, -2), "Head")
		piece(l, V(0.15, 0.4, 0.15), rgb(230, 220, 190), C(0.5, 1.25, -2), "Head")
		for i, pos in { V(-0.7, -1.4, -1.2), V(0.7, -1.4, -1.2), V(-0.7, -1.4, 1.2), V(0.7, -1.4, 1.2) } do
			piece(l, V(0.4, 1.3, 0.4), white, C(pos), "Leg" .. i)
		end
	end,
	Oveja = function(l)
		local wool, face = rgb(240, 238, 230), rgb(50, 45, 45)
		piece(l, V(1.4, 1.2, 1.9), wool, C(0, 0, 0), nil, nil, Enum.Material.Fabric)
		piece(l, V(0.6, 0.7, 0.7), face, C(0, 0.3, -1.2), "Head")
		for i, pos in { V(-0.4, -0.9, -0.6), V(0.4, -0.9, -0.6), V(-0.4, -0.9, 0.6), V(0.4, -0.9, 0.6) } do
			piece(l, V(0.2, 0.8, 0.2), face, C(pos), "Leg" .. i)
		end
	end,
	Gallina = function(l)
		local body = ({ rgb(250, 245, 235), rgb(170, 90, 40) })[math.random(1, 2)]
		piece(l, V(0.7, 0.7, 0.9), body, C(0, 0, 0), nil, BALL)
		piece(l, V(0.4, 0.4, 0.4), body, C(0, 0.45, -0.35), "Head", BALL)
		piece(l, V(0.1, 0.2, 0.25), rgb(220, 40, 40), C(0, 0.72, -0.35), "Head")
		piece(l, V(0.1, 0.1, 0.18), rgb(240, 190, 50), C(0, 0.45, -0.6), "Head")
		piece(l, V(0.06, 0.35, 0.06), rgb(240, 190, 50), C(-0.15, -0.5, 0), "Leg1")
		piece(l, V(0.06, 0.35, 0.06), rgb(240, 190, 50), C(0.15, -0.5, 0), "Leg2")
	end,
}

-- Altura del centro del cuerpo sobre el suelo (para que las patas toquen el suelo)
local STAND = { Paloma = 0.62, Perro = 1.4, Gato = 0.9, Vaca = 2.7, Oveja = 1.7, Gallina = 0.85, Pato = 0.15, Gaviota = 0.25 }
local WALK_SPEED = { Paloma = 1.2, Perro = 5, Gato = 3, Vaca = 1.6, Oveja = 2, Gallina = 2.2 }

local function newAnimal(kind: string): Animal
	local list = {}
	BUILDERS[kind](list)
	return {
		Kind = kind, Pieces = list, Root = CFrame.new(0, -500, 0), Active = false,
		State = "idle", Timer = 0, Phase = math.random() * 10, Speed = WALK_SPEED[kind] or 2,
	}
end

local function hide(a: Animal)
	a.Active = false
	for _, p in a.Pieces do
		p.Part.CFrame = CFrame.new(0, -500, 0)
	end
end

-- Coloca las piezas: alas que aletean, patas que andan, cabeza que picotea
local function render(a: Animal, t: number)
	local flap = 0
	if a.State == "fly" or a.State == "flee" then
		flap = math.sin(t * (if a.Kind == "Gaviota" then 9 else 22) + a.Phase) * 0.9
	elseif a.Kind == "Mariposa" then
		flap = math.sin(t * 18 + a.Phase) * 1.1
	end
	local walking = a.State == "walk"
	local swing = if walking then math.sin(t * a.Speed * 3 + a.Phase) * 0.6 else 0
	local peck = if a.State == "idle" and (a.Kind == "Paloma" or a.Kind == "Gallina") then math.max(0, math.sin(t * 3 + a.Phase)) * 0.6 else 0
	for _, p in a.Pieces do
		local offset = p.Offset
		local role = p.Role
		if role == "WingL" then
			offset = CFrame.new(offset.Position.X * 0.2, offset.Position.Y, offset.Position.Z) * CFrame.Angles(0, 0, flap) * CFrame.new(offset.Position.X * 0.8, 0, 0)
		elseif role == "WingR" then
			offset = CFrame.new(offset.Position.X * 0.2, offset.Position.Y, offset.Position.Z) * CFrame.Angles(0, 0, -flap) * CFrame.new(offset.Position.X * 0.8, 0, 0)
		elseif role == "Head" and peck > 0 then
			offset = CFrame.new(0, -peck * 0.4, -peck * 0.15) * offset
		elseif role and role:sub(1, 3) == "Leg" and walking then
			local sign = if (tonumber(role:sub(4)) or 1) % 2 == 0 then 1 else -1
			offset = offset * CFrame.Angles(swing * sign, 0, 0)
		elseif role == "Tail" and a.Kind == "Perro" then
			offset = offset * CFrame.Angles(0, math.sin(t * 12 + a.Phase) * 0.5, 0)
		elseif role == "Glow" then
			p.Part.Transparency = 0.2 + 0.7 * (0.5 + 0.5 * math.sin(t * 2.5 + a.Phase))
		end
		p.Part.CFrame = a.Root * offset
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
	return workspace:Raycast(Vector3.new(x, maxY, z), Vector3.new(0, -maxY + -200, 0), rayParams)
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

-- Un punto de suelo "de calle" cerca (no en un tejado), o nil
local function groundSpot(around: Vector3, minR: number, maxR: number, wantWater: boolean?): (Vector3?, Enum.Material?)
	for _ = 1, 4 do
		local angle = math.random() * math.pi * 2
		local r = minR + math.random() * (maxR - minR)
		local x, z = around.X + math.cos(angle) * r, around.Z + math.sin(angle) * r
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
	a.Root = CFrame.new(spot + Vector3.new(0, STAND[a.Kind] or 0.5, 0)) * CFrame.Angles(0, math.random() * 6.28, 0)
	a.State = "idle"
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

local function stepWalker(a: Animal, t: number, dt: number, around: Vector3)
	local pos = a.Root.Position
	-- Las palomas y las gallinas salen volando si te acercas demasiado
	if (a.Kind == "Paloma") and a.State ~= "flee" then
		local d = Vector2.new(pos.X - around.X, pos.Z - around.Z).Magnitude
		if d < 9 then
			a.State = "flee"
			a.Timer = 3
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
	a.Timer -= dt
	if a.State == "idle" then
		if a.Timer <= 0 then
			-- A andar un poco: a un sitio cercano con suelo
			local spot = groundSpot(pos, 2, if a.Kind == "Perro" then 12 else 6)
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
			a.Timer = 2 + math.random() * 6
		else
			local stepLen = math.min(flat.Magnitude, a.Speed * dt)
			local newPos = pos + flat.Unit * stepLen
			newPos = Vector3.new(newPos.X, pos.Y + (target.Y - pos.Y) * math.min(1, dt * 4), newPos.Z)
			a.Root = CFrame.lookAt(newPos, newPos + flat.Unit)
		end
	end
end

local function stepFloat(a: Animal, t: number, dt: number)
	local pos = a.Root.Position
	local look = a.Root.LookVector
	local turn = math.sin(t * 0.3 + a.Phase) * 0.3 * dt
	local dir = (CFrame.Angles(0, turn, 0) * look)
	local newPos = pos + dir * 0.6 * dt + Vector3.new(0, math.sin(t * 1.5 + a.Phase) * 0.004, 0)
	a.Root = CFrame.lookAt(newPos, newPos + dir)
end

---------------------------------------------------------------------

local KINDS = { "Pajaro", "Gaviota", "Paloma", "Mariposa", "Luciernaga", "Pato", "Perro", "Gato", "Vaca", "Oveja", "Gallina" }
local MAX = { Pajaro = 18, Gaviota = 8, Paloma = 8, Mariposa = 8, Luciernaga = 14, Pato = 5, Perro = 2, Gato = 2, Vaca = 3, Oveja = 4, Gallina = 5 }
local DESPAWN = 110 -- más lejos que esto, el animal desaparece y sale otro cerca

local function update(t: number, dt: number)
	local around = playerPosition()
	if not around then
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
						stepFloat(a, t, dt)
					elseif WALKERS[kind] then
						stepWalker(a, t, dt, around)
					end
					if a.Active then
						render(a, t)
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
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	lowQuality = (ok and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 3) or require(script.Parent.Parent.UI.Perf).lite
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
