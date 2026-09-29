-- PlaceLifeService: la "vida por lugar". Cada sitio de Valmar tiene su gente haciendo lo que se hace
-- allí (datos en shared/PlaceLife): en el parque charlan en corros, corren, pasean al perro, los niños
-- juegan a la pelota y los abuelos a la petanca o a las cartas; en la playa toman el sol en la toalla;
-- en la plaza hay un músico con su público y gente haciendo fotos; en las paradas y bocas de metro
-- esperan; a la salida del cole, los padres; en las tiendas, cola en hora punta y el dependiente
-- tomándose un café en la puerta; en las oficinas, gente en su descanso…
--
-- Presupuesto (pensado para móvil; ver PlaceLife):
--   * Solo se llenan los sitios a menos de PlaceLife.Radius (200) de algún jugador y se vacían cuando
--     ya no hay nadie a menos de PlaceLife.Keep (240).
--   * Como mucho PlaceLife.PlayerBudget (40) personas del servidor alrededor de cada jugador (contando
--     también las de CrowdService) y PlaceLife.GlobalCap (90) de este sistema en todo el servidor.
--   * Aparecen poco a poco (PlaceLife.SpawnPerTick grupos cada 2 s), nunca a menos de 5 studs de un
--     jugador ni a menos de 30 delante de él, y se funden al aparecer y al irse (atributos FadeIn /
--     FadeOut, Controllers/ActorLife).
--   * Con lluvia o de noche queda menos gente (PlaceLife.amount); los que sobran se despiden y se van.
--   Son los NPC baratos de siempre (Npc.create: anclados, sin colisiones, sin nombre de Roblox encima).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Npc = require(script.Parent.Parent.World.Npc)
local PlaceLife = require(ReplicatedStorage.Shared.PlaceLife)
local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)
local Ground = require(ReplicatedStorage.Shared.Ground)
local GameClock = require(ReplicatedStorage.Shared.GameClock)

local PlaceLifeService = {}

local rgb = Color3.fromRGB

type Anchor = {
	Kind: string,
	Place: any,
	Instance: Instance,
	Frame: CFrame, -- centro (solo girado en horizontal)
	Half: Vector3, -- media caja
	Level: number, -- altura del suelo del sitio
	Seat: BasePart?, -- (bancos)
	Groups: { Group },
}
type Group = {
	Anchor: Anchor,
	Activity: string,
	Npcs: { Model },
	Props: { Instance },
	Path: { Vector3 }?, -- puntos por los que anda (el primero de la lista anda; los demás le siguen al lado)
	Step: number,
	NextAt: number,
	Ball: BasePart?,
	Holder: number?,
}

local anchors: { Anchor } = {}
local byInstance: { [Instance]: Anchor } = {}
local folder: Instance? = nil
local lastChatter = 0

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function pick<T>(list: { T }?): T?
	if not list or #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Dónde están los jugadores y hacia dónde miran
local function viewers(): { { Player: Player, Pos: Vector3, Look: Vector3 } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root then
			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			table.insert(list, { Player = player, Pos = root.Position, Look = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1) })
		end
	end
	return list
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Distancia (en planta) de un punto a la caja del sitio
local function anchorDistance(a: Anchor, pos: Vector3): number
	if math.abs(pos.Y - a.Level) > 80 then
		return math.huge -- (dentro de un edificio en el cielo o en el metro: no cuenta)
	end
	local l = a.Frame:PointToObjectSpace(pos)
	local dx = math.max(0, math.abs(l.X) - a.Half.X)
	local dz = math.max(0, math.abs(l.Z) - a.Half.Z)
	return math.sqrt(dx * dx + dz * dz)
end

-- ¿Se puede aparecer aquí? Nunca a menos de MinGap de un jugador ni a menos de FrontGap delante de él
local function pointOk(p: Vector3, list: { { Player: Player, Pos: Vector3, Look: Vector3 } }): boolean
	for _, v in list do
		local d = Vector3.new(p.X - v.Pos.X, 0, p.Z - v.Pos.Z)
		local dist = d.Magnitude
		if dist < PlaceLife.MinGap then
			return false
		end
		if dist < PlaceLife.FrontGap and d.Unit:Dot(v.Look) > PlaceLife.FrontCone then
			return false
		end
	end
	return true
end
PlaceLifeService._pointOk = pointOk

local SKIP = { Interiores = true, StoryScenes = true, Gente = true, VidaLugares = true }
local function skipped(instance: Instance): boolean
	local node = instance.Parent
	while node and node ~= workspace do
		if SKIP[node.Name] then
			return true
		end
		node = node.Parent
	end
	return false
end

-- Suelo de verdad bajo un punto (Ground.cast), a la altura del sitio; sin agua. Sin rayo (pruebas): el punto.
local function groundAt(a: Anchor, p: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder :: any }
	local ok, hit = pcall(Ground.cast, Vector3.new(p.X, a.Level + 14, p.Z), Vector3.new(0, -40, 0), params)
	if not ok then
		return Vector3.new(p.X, a.Level, p.Z)
	end
	if not hit then
		return Vector3.new(p.X, a.Level, p.Z)
	end
	if hit.Normal.Y < 0.8 or hit.Material == Enum.Material.Water then
		return nil
	end
	if hit.Position.Y < a.Level - 3 or hit.Position.Y > a.Level + 6 then
		return nil -- (encima de un muro, de un tejado o en el hueco de una escalera)
	end
	return hit.Position
end

-- ¿Hay sitio para una persona (nada sólido a la altura del cuerpo)?
local function roomFor(p: Vector3): boolean
	local ok, found = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { folder :: any }
		params.RespectCanCollide = true
		return workspace:GetPartBoundsInBox(CFrame.new(p + Vector3.new(0, 3, 0)), Vector3.new(2, 3.6, 2), params)
	end)
	if not ok or type(found) ~= "table" then
		return true
	end
	for _, part in found do
		if Ground.skipOf(part) == nil then
			return false -- (farolas, muros, mesas…; la gente y los coches no cuentan)
		end
	end
	return true
end

-- Un punto al azar del sitio según su forma
local function candidate(a: Anchor): Vector3
	local place = a.Place
	if place.Shape == "Area" then
		local hx, hz = math.max(2, a.Half.X - 6), math.max(2, a.Half.Z - 6)
		return a.Frame * Vector3.new((math.random() * 2 - 1) * hx, 0, (math.random() * 2 - 1) * hz)
	elseif place.Shape == "Around" then
		-- Junto a una de sus fachadas, por fuera
		local side = math.random(1, 4)
		local out = (place.Min or 3) + math.random() * ((place.Max or 9) - (place.Min or 3))
		local along = math.random() * 2 - 1
		local x, z
		if side == 1 then
			x, z = along * a.Half.X, -a.Half.Z - out
		elseif side == 2 then
			x, z = along * a.Half.X, a.Half.Z + out
		elseif side == 3 then
			x, z = -a.Half.X - out, along * a.Half.Z
		else
			x, z = a.Half.X + out, along * a.Half.Z
		end
		return a.Frame * Vector3.new(x, 0, z)
	elseif place.Shape == "Front" then
		-- Delante de la puerta (hacia donde mira la marca), a lo largo de la fachada
		local out = (place.Min or 1.5) + math.random() * ((place.Max or 6) - (place.Min or 1.5))
		return a.Frame * Vector3.new((math.random() * 2 - 1) * 5, 0, -out)
	end
	local angle = math.random() * math.pi * 2
	local r = (place.Min or 3) + math.random() * ((place.Max or 8) - (place.Min or 3))
	return a.Frame * Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

-- Un punto libre de verdad (suelo, sitio y lejos de los jugadores); nil si no lo encuentra
local function freePoint(a: Anchor, list, tries: number?): Vector3?
	for _ = 1, tries or 6 do
		local c = candidate(a)
		if pointOk(c, list) then
			local g = groundAt(a, c)
			if g and roomFor(g) then
				return g
			end
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Aspecto y objetos
---------------------------------------------------------------------
local SPORT = { { Shirt = rgb(250, 120, 40), Pants = rgb(30, 30, 34) }, { Shirt = rgb(60, 200, 220), Pants = rgb(30, 30, 34) }, { Shirt = rgb(230, 60, 120), Pants = rgb(40, 40, 46) } }
local ELDER = { { Shirt = rgb(120, 100, 80), Pants = rgb(70, 60, 50), Hair = rgb(200, 200, 205), LongSleeves = true }, { Shirt = rgb(90, 110, 140), Pants = rgb(60, 60, 70), Hair = rgb(190, 190, 195), LongSleeves = true, LongHair = true } }
local UNIFORM = { { Shirt = rgb(60, 66, 80), Pants = rgb(40, 44, 54), LongSleeves = true }, { Shirt = rgb(240, 240, 240), Pants = rgb(30, 30, 34) }, { Shirt = rgb(180, 40, 40), Pants = rgb(30, 30, 34) } }
local UMBRELLAS = { rgb(30, 30, 34), rgb(200, 40, 50), rgb(40, 80, 170), rgb(240, 200, 40), rgb(120, 60, 140) }
local TOWELS = { rgb(230, 60, 60), rgb(60, 140, 230), rgb(250, 200, 50), rgb(90, 200, 120), rgb(240, 120, 200) }

local NAMES = {
	Banco = "Vecino", Charla = "Vecina", Correr = "Corredora", Perro = "Paseante con perro", Pasear = "Paseante", Leer = "Lector",
	Fotos = "Turista", Toalla = "Bañista", Pelota = "Niño", Petanca = "Abuelo", Cartas = "Abuela", Puesto = "Clienta",
	EsperarBus = "Viajero", EsperarMetro = "Viajera", Recoger = "Madre", Llamar = "Familiar", Compras = "Compradora",
	Pescar = "Pescador", Estudiar = "Estudiante", Repostar = "Conductor", Musico = "Músico callejero", Pareja = "Paseante",
	Cola = "Cliente", Descanso = "Empleada", Reparto = "Repartidor", Viajar = "Viajero",
}

local function prop(g: Group, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	if shape then
		p.Shape = shape
	end
	p.Parent = folder or workspace
	table.insert(g.Props, p)
	return p
end

-- Pieza pegada al cuerpo (se mueve con él)
local function carry(npc: Model, name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	if shape then
		p.Shape = shape
	end
	p.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = npc
end

local function umbrella(npc: Model)
	carry(npc, "PalParaguas", Vector3.new(0.14, 3.2, 0.14), CFrame.new(-1.1, 1.4, -0.4), rgb(50, 50, 54))
	carry(npc, "Paraguas", Vector3.new(0.4, 5, 5), CFrame.new(-1.1, 3.1, -0.4) * CFrame.Angles(0, 0, math.rad(90)), pick(UMBRELLAS) :: Color3, Enum.PartType.Cylinder)
	npc:SetAttribute("Umbrella", true)
end

-- Perro de bloques al lado de su dueño (pegado a él: anda con él sin coste)
local function dogFor(npc: Model)
	local fur = pick({ rgb(150, 100, 60), rgb(40, 36, 34), rgb(230, 220, 200), rgb(200, 160, 90) }) :: Color3
	carry(npc, "PerroCuerpo", Vector3.new(0.9, 0.9, 2.1), CFrame.new(2.2, -1.7, -1), fur)
	carry(npc, "PerroCabeza", Vector3.new(0.8, 0.8, 0.9), CFrame.new(2.2, -1.1, -2.3), fur)
	carry(npc, "PerroCola", Vector3.new(0.18, 0.18, 0.8), CFrame.new(2.2, -1.2, 0.2) * CFrame.Angles(math.rad(35), 0, 0), fur)
end

-- Una persona del sitio. cf: pies en el suelo, mirando hacia donde mira
local function person(g: Group, cf: CFrame, look: Npc.Look?, kid: boolean?, elder: boolean?): Model?
	local ok, npc = pcall(Npc.create, NAMES[g.Activity] or "Paseante", folder or workspace, cf, look)
	if not ok or not npc then
		return nil
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- (sin el nombre de Roblox encima)
	end
	npc:SetAttribute("PlaceLife", g.Anchor.Kind)
	npc:SetAttribute("Activity", g.Activity)
	npc:SetAttribute("FadeIn", true) -- (el cliente lo funde al llegar: no aparece de golpe)
	if kid then
		npc:SetAttribute("Age", "Nino")
		pcall(function()
			npc:ScaleTo(0.62)
		end)
		pcall(Npc.placeFeet, npc, cf)
	elseif elder then
		npc:SetAttribute("Age", "Mayor")
	end
	table.insert(g.Npcs, npc)
	return npc
end

---------------------------------------------------------------------
-- Montar cada actividad
---------------------------------------------------------------------
local function facing(from: Vector3, to: Vector3): CFrame
	local flat = Vector3.new(to.X, from.Y, to.Z)
	if (flat - from).Magnitude < 0.05 then
		return CFrame.new(from)
	end
	return CFrame.lookAt(from, flat)
end

-- Un segundo punto para andar (a 10-25 studs), en suelo de verdad
local function walkTarget(a: Anchor, from: Vector3, list): Vector3?
	for _ = 1, 5 do
		local c = candidate(a)
		local d = flatDistance(c, from)
		if d > 8 and d < 60 then
			local g = groundAt(a, c)
			if g then
				return g
			end
		end
	end
	return nil
end

local function loopPath(a: Anchor, start: Vector3): { Vector3 }
	local path = { start }
	if a.Place.Shape == "Area" then
		local hx, hz = math.max(4, a.Half.X - 8), math.max(4, a.Half.Z - 8)
		for _, q in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
			local g = groundAt(a, a.Frame * Vector3.new(q[1] * hx, 0, q[2] * hz))
			if g then
				table.insert(path, g)
			end
		end
	else
		local c = a.Frame.Position
		local r = math.max(10, (a.Place.Max or 8) + 6)
		for k = 0, 3 do
			local g = groundAt(a, Vector3.new(c.X + math.cos(k * math.pi / 2) * r, 0, c.Z + math.sin(k * math.pi / 2) * r))
			if g then
				table.insert(path, g)
			end
		end
	end
	return path
end

-- Monta la actividad en el sitio. Devuelve el grupo (o nil si no cabe ahora)
local function build(a: Anchor, name: string, size: number, list, weather: string?): Group?
	local activity = PlaceLife.Activities[name]
	if not activity then
		return nil
	end
	local g: Group = { Anchor = a, Activity = name, Npcs = {}, Props = {}, Path = nil, Step = 1, NextAt = os.clock() + 3 + math.random() * 5 }
	local wet = PlaceLife.umbrella(weather)
	local function look(): Npc.Look?
		if activity.Elders then
			return pick(ELDER)
		elseif name == "Correr" then
			return pick(SPORT)
		elseif activity.Uniform then
			return pick(UNIFORM)
		end
		return nil
	end
	-- Sentado en un banco (en un lado: el otro queda libre para el jugador)
	if activity.Pose == "Sit" then
		local seat = a.Seat
		if not seat or not pointOk(seat.Position, list) then
			return nil
		end
		local npc = person(g, seat.CFrame * CFrame.new(0, 0, -2), look())
		if npc then
			local side = { CFrame = seat.CFrame * CFrame.new(-(seat.Size.X / 2 - 1.1), 0, 0), Size = seat.Size }
			pcall(Npc.sit, npc, side :: any)
			npc:SetAttribute("Seated", true)
			pcall(Npc.work, npc, pick(activity.Works))
		end
		return if #g.Npcs > 0 then g else nil
	end
	local at = freePoint(a, list)
	if not at then
		return nil
	end
	local toCenter = a.Frame.Position
	if name == "Toalla" then
		-- Toalla (y a veces sombrilla) y la persona tumbada encima, boca arriba
		local angle = math.random() * math.pi * 2
		local head = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local towelCf = CFrame.lookAt(at + Vector3.new(0, 0.06, 0), at + Vector3.new(0, 0.06, 0) + head)
		prop(g, "Toalla", Vector3.new(2.6, 0.1, 6), towelCf, pick(TOWELS) :: Color3)
		if math.random() < 0.5 then
			prop(g, "PalSombrilla", Vector3.new(0.2, 6, 0.2), CFrame.new(at + head * 3.4 + Vector3.new(1.8, 3, 0)), rgb(240, 240, 240))
			prop(g, "Sombrilla", Vector3.new(0.4, 7, 7), CFrame.new(at + head * 3.4 + Vector3.new(1.8, 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), pick(TOWELS) :: Color3, Enum.PartType.Cylinder)
		end
		local npc = person(g, CFrame.new(at), nil)
		if npc and npc.PrimaryPart then
			local up = Vector3.new(0, 1, 0)
			local right = head:Cross(-up)
			npc.PrimaryPart.CFrame = CFrame.fromMatrix(at + Vector3.new(0, 0.6, 0), right, head)
			pcall(Npc.setPose, npc, "Lie")
		end
		return g
	end
	if activity.CardTable then
		-- Mesita plegable con taburetes y los abuelos sentados alrededor
		prop(g, "MesaCartas", Vector3.new(3, 0.25, 3), CFrame.new(at + Vector3.new(0, 2.5, 0)), rgb(120, 90, 60))
		prop(g, "PataMesa", Vector3.new(0.3, 2.4, 0.3), CFrame.new(at + Vector3.new(0, 1.2, 0)), rgb(60, 60, 64))
		for k = 1, size do
			local angle = k / size * math.pi * 2
			local p = at + Vector3.new(math.cos(angle) * 2.6, 0, math.sin(angle) * 2.6)
			prop(g, "Taburete", Vector3.new(1.2, 1.5, 1.2), CFrame.new(p + Vector3.new(0, 0.75, 0)), rgb(70, 70, 76))
			local npc = person(g, facing(p, at), look(), false, true)
			if npc then
				pcall(Npc.sitAt, npc, facing(p + Vector3.new(0, 1.5, 0), at + Vector3.new(0, 1.5, 0)))
				npc:SetAttribute("Seated", true)
				pcall(Npc.work, npc, pick(activity.Works))
			end
		end
		return g
	end
	if activity.Queue then
		-- Cola delante de la puerta, a lo largo de la fachada, mirando hacia la puerta
		local door = a.Frame.Position
		local out = a.Frame.LookVector * 1.8 -- (un poco hacia fuera)
		local along = a.Frame.RightVector * (if math.random() < 0.5 then 1 else -1)
		local placed = 0
		for k = 1, size do
			local p = door + out + along * (1.5 + k * 2.2)
			local grounded = groundAt(a, p)
			if grounded and pointOk(grounded, list) then
				local npc = person(g, facing(grounded, door + out), look())
				if npc then
					placed += 1
					if k > 1 or math.random() < 0.5 then
						pcall(Npc.work, npc, pick(activity.Works))
					end
					if wet then
						umbrella(npc)
					end
				end
			end
		end
		return if placed > 0 then g else nil
	end
	if activity.Ball then
		-- Niños pasándose la pelota (la pelota va de uno a otro)
		local spots = { at }
		for k = 2, size do
			local angle = k / size * math.pi * 2 + math.random()
			local p = groundAt(a, at + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8))
			if p and pointOk(p, list) then
				table.insert(spots, p)
			end
		end
		if #spots < 2 then
			return nil
		end
		local middle = Vector3.zero
		for _, p in spots do
			middle += p
		end
		middle /= #spots
		for _, p in spots do
			person(g, facing(p, middle), { Backpack = if math.random() < 0.3 then pick(TOWELS) else nil }, true)
		end
		g.Ball = prop(g, "Pelota", Vector3.new(1.1, 1.1, 1.1), CFrame.new(spots[1] + Vector3.new(0, 0.55, 0)), pick({ rgb(240, 240, 240), rgb(230, 60, 60), rgb(250, 200, 50) }) :: Color3, Enum.PartType.Ball)
		g.Holder = 1
		return g
	end
	if activity.Boules then
		-- Petanca: las bolas en la arena, delante; los abuelos en fila mirándolas
		local dir = (toCenter - at)
		dir = if Vector3.new(dir.X, 0, dir.Z).Magnitude > 1 then Vector3.new(dir.X, 0, dir.Z).Unit else Vector3.new(0, 0, -1)
		local target = at + dir * 7
		prop(g, "Boliche", Vector3.new(0.35, 0.35, 0.35), CFrame.new(target + Vector3.new(0, 0.18, 0)), rgb(230, 60, 60), Enum.PartType.Ball)
		for k = 1, 3 do
			local off = Vector3.new(math.random() * 3 - 1.5, 0.3, math.random() * 3 - 1.5)
			prop(g, "Bola", Vector3.new(0.6, 0.6, 0.6), CFrame.new(target + off), rgb(150, 150, 160), Enum.PartType.Ball)
		end
		local side = Vector3.new(-dir.Z, 0, dir.X)
		for k = 1, size do
			local p = groundAt(a, at + side * ((k - (size + 1) / 2) * 2.4)) or at
			if pointOk(p, list) then
				local npc = person(g, facing(p, target), look(), false, true)
				if npc and k == 1 then
					pcall(Npc.work, npc, pick(activity.Works))
				end
			end
		end
		return if #g.Npcs > 0 then g else nil
	end
	if activity.Lead then
		-- Músico en el centro y su público delante, en semicírculo
		local musician = person(g, CFrame.new(at) * CFrame.Angles(0, math.random() * math.pi * 2, 0), nil)
		if not musician then
			return nil
		end
		pcall(Npc.work, musician, activity.Lead)
		prop(g, "Funda", Vector3.new(1.2, 0.3, 3.2), musician:GetPivot() * CFrame.new(0, -2.85, -2.2), rgb(40, 30, 26))
		local front = musician:GetPivot().LookVector
		for k = 2, size do
			local angle = (k - 2 - (size - 2) / 2) * 0.6
			local dir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(Vector3.new(front.X, 0, front.Z))
			local p = groundAt(a, at + dir * (5 + math.random() * 2))
			if p and pointOk(p, list) then
				local npc = person(g, facing(p, at), nil)
				if npc and wet then
					umbrella(npc)
				end
			end
		end
		return g
	end
	if size > 1 and not activity.Walk then
		-- Corro de 2 a 4 personas mirándose (charlando, esperando juntos…)
		local placed = 0
		for k = 1, size do
			local angle = k / size * math.pi * 2 + math.random() * 0.4
			local p = groundAt(a, at + Vector3.new(math.cos(angle) * 1.9, 0, math.sin(angle) * 1.9))
			if p and pointOk(p, list) then
				local npc = person(g, facing(p, at), look(), activity.Kids, activity.Elders)
				if npc then
					placed += 1
					if math.random() < 0.4 then
						pcall(Npc.work, npc, pick(activity.Works))
					end
					if wet then
						umbrella(npc)
					end
				end
			end
		end
		return if placed > 0 then g else nil
	end
	-- Una persona (o una pareja) de pie o andando
	local lookAt = if name == "Fotos" or name == "Pescar" or name == "Musico" then toCenter else toCenter + (at - toCenter) * 2
	if name == "Pescar" then
		lookAt = at + (at - toCenter) -- (de cara al agua, hacia fuera)
	end
	local lead = person(g, facing(at, lookAt), look(), activity.Kids, activity.Elders)
	if not lead then
		return nil
	end
	if activity.Works then
		pcall(Npc.work, lead, pick(activity.Works))
	end
	if name == "Pescar" then
		carry(lead, "Caña", Vector3.new(0.12, 0.12, 7), CFrame.new(0.9, 0.4, -3.2) * CFrame.Angles(math.rad(25), 0, 0), rgb(90, 70, 50))
	elseif name == "Reparto" then
		carry(lead, "CajaReparto", Vector3.new(2, 2, 1.6), CFrame.new(0, 0.6, 1.4), rgb(240, 180, 40))
	elseif name == "Compras" then
		carry(lead, "Bolsa", Vector3.new(0.5, 1.3, 1.1), CFrame.new(1.3, -0.9, 0), pick({ rgb(240, 236, 226), rgb(60, 140, 80), rgb(200, 60, 50) }) :: Color3)
	end
	if activity.Dog then
		dogFor(lead)
	end
	if wet and name ~= "Correr" then
		umbrella(lead)
	end
	if activity.Pair then
		-- Su pareja, al lado (andan juntos)
		local side = facing(at, lookAt).RightVector
		local p = at + side * 1.8
		local partner = person(g, facing(p, lookAt + side * 1.8), nil)
		if partner and wet then
			umbrella(partner)
		end
	end
	if activity.Walk == "Loop" then
		g.Path = loopPath(a, at)
		g.NextAt = os.clock() + 0.5
	elseif activity.Walk == "Line" then
		local other = walkTarget(a, at, list)
		g.Path = if other then { at, other } else nil
	end
	return g
end

---------------------------------------------------------------------
-- Quitar gente
---------------------------------------------------------------------
local function dropGroup(g: Group)
	local a = g.Anchor
	local i = table.find(a.Groups, g)
	if i then
		table.remove(a.Groups, i)
	end
end

-- Se va: fundido (el cliente la desvanece) y fuera. Con alguien al lado, antes se despide y se aleja.
local function removeGroup(g: Group, line: string?)
	dropGroup(g)
	for _, npc in g.Npcs do
		if npc.Parent then
			npc:SetAttribute("Leaving", true) -- (ya no hace lo suyo: se está yendo)
		end
	end
	local anyone = false
	for _, npc in g.Npcs do
		local root = npc.PrimaryPart
		if root then
			for _, v in viewers() do
				if flatDistance(v.Pos, root.Position) < 30 then
					anyone = true
				end
			end
		end
	end
	local function vanish()
		for _, npc in g.Npcs do
			if npc.Parent then
				npc:SetAttribute("FadeOut", true)
			end
		end
		task.delay(0.7, function()
			for _, npc in g.Npcs do
				if npc.Parent then
					npc:Destroy()
				end
			end
			for _, p in g.Props do
				if p.Parent then
					p:Destroy()
				end
			end
		end)
	end
	if anyone and line and g.Npcs[1] then
		-- Se despide, recoge y se aleja un poco antes de irse
		pcall(Npc.say, g.Npcs[1], line, 2.5)
		task.spawn(function()
			for _, npc in g.Npcs do
				local root = npc.PrimaryPart
				if root and npc.Parent and not npc:GetAttribute("Seated") and npc:GetAttribute("UsePose") == nil then
					pcall(Npc.work, npc, nil)
					local away = root.Position - g.Anchor.Frame.Position
					away = if Vector3.new(away.X, 0, away.Z).Magnitude > 0.5 then Vector3.new(away.X, 0, away.Z).Unit else Vector3.new(1, 0, 0)
					local goal = root.Position + away * 14
					task.spawn(function()
						pcall(Npc.walkTo, npc, { Vector3.new(goal.X, g.Anchor.Level, goal.Z) }, 5)
					end)
				end
			end
			task.wait(2.5)
			vanish()
		end)
	else
		vanish()
	end
end

---------------------------------------------------------------------
-- Registro de sitios
---------------------------------------------------------------------
function PlaceLifeService.addAnchor(kind: string, instance: Instance): Anchor?
	local place = PlaceLife.Places[kind]
	if not place or byInstance[instance] or skipped(instance) then
		return nil
	end
	local cf: CFrame, size: Vector3
	local seat: BasePart? = nil
	if kind == "BancoCalle" then
		if instance.Name == "BusStop" then
			return nil
		end
		local s = if instance:IsA("BasePart") then instance else instance:FindFirstChild("Seat")
		if not s or not s:IsA("BasePart") then
			return nil
		end
		seat = s :: BasePart
		cf, size = (s :: BasePart).CFrame, (s :: BasePart).Size
	elseif instance:IsA("Model") then
		local ok, c, sz = pcall(function()
			return (instance :: Model):GetBoundingBox()
		end)
		if not ok then
			return nil
		end
		cf, size = c, sz
	elseif instance:IsA("BasePart") then
		cf, size = instance.CFrame, instance.Size
	else
		return nil
	end
	if place.Shape == "Area" and (size.X < (place.MinSize or 20) or size.Z < (place.MinSize or 20)) then
		return nil
	end
	local center = cf.Position
	if place.Every then
		-- (siempre los mismos: uno de cada Every; CrowdService usa el resto 0 con los bancos)
		if math.floor(center.X * 7 + center.Z * 13) % place.Every ~= 1 % place.Every then
			return nil
		end
	end
	local lookFlat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	local frame = if lookFlat.Magnitude > 0.01 then CFrame.lookAt(center, center + lookFlat) else CFrame.new(center)
	-- Media caja en horizontal (girada como el sitio)
	local rx = math.abs(frame.RightVector:Dot(cf.RightVector)) * size.X + math.abs(frame.RightVector:Dot(cf.LookVector)) * size.Z
	local rz = math.abs(frame.LookVector:Dot(cf.RightVector)) * size.X + math.abs(frame.LookVector:Dot(cf.LookVector)) * size.Z
	local a: Anchor = {
		Kind = kind,
		Place = place,
		Instance = instance,
		Frame = frame,
		Half = if place.Shape == "Ring" or place.Shape == "Front" then Vector3.zero else Vector3.new(rx / 2, size.Y / 2, rz / 2),
		Level = center.Y - size.Y / 2,
		Seat = seat,
		Groups = {},
	}
	table.insert(anchors, a)
	byInstance[instance] = a
	return a
end

function PlaceLifeService.anchors(kind: string?): { Anchor }
	if not kind then
		return table.clone(anchors)
	end
	local list = {}
	for _, a in anchors do
		if a.Kind == kind then
			table.insert(list, a)
		end
	end
	return list
end

-- Busca en el mapa los sitios de cada tipo (etiquetas y nombres de modelo)
function PlaceLifeService.scan()
	local byName: { [string]: string } = {}
	for _, kind in PlaceLife.Order do
		local place = PlaceLife.Places[kind]
		for _, tag in place.Tags or {} do
			for _, instance in CollectionService:GetTagged(tag) do
				PlaceLifeService.addAnchor(kind, instance)
			end
		end
		for _, name in place.Models or {} do
			byName[name] = kind
		end
	end
	local town = workspace:FindFirstChild("Town")
	if town then
		for _, d in town:GetDescendants() do
			local kind = byName[d.Name]
			if kind and d:IsA("Model") then
				PlaceLifeService.addAnchor(kind, d)
			end
		end
	end
end

---------------------------------------------------------------------
-- La vuelta (cada PlaceLife.Tick segundos)
---------------------------------------------------------------------
local function crowdNear(pos: Vector3, radius: number): number
	local ok, n = pcall(function()
		local CrowdService = require(script.Parent.CrowdService) :: any
		return if CrowdService.nearCount then CrowdService.nearCount(pos, radius) else 0
	end)
	return if ok and type(n) == "number" then n else 0
end

local function groupSize(g: Group): number
	return #g.Npcs
end

function PlaceLifeService.count(kind: string?): number
	local n = 0
	for _, a in anchors do
		if not kind or a.Kind == kind then
			for _, g in a.Groups do
				n += groupSize(g)
			end
		end
	end
	return n
end

-- Cuánta gente de este sistema hay a menos de radius de un punto
function PlaceLifeService.nearCount(pos: Vector3, radius: number): number
	local n = 0
	for _, a in anchors do
		for _, g in a.Groups do
			for _, npc in g.Npcs do
				local root = npc.PrimaryPart
				if root and npc.Parent and flatDistance(root.Position, pos) <= radius then
					n += 1
				end
			end
		end
	end
	return n
end

local function now(): (number, string?, number)
	local hour, weather = TimeContext.now()
	local weekday = 1
	pcall(function()
		weekday = GameClock.now().Weekday
	end)
	return hour, weather, weekday
end

-- Mueve a los que andan, pasa la pelota…
local function animate(g: Group)
	local t = os.clock()
	if t < g.NextAt then
		return
	end
	local lead = g.Npcs[1]
	if not lead or not lead.Parent then
		return
	end
	if g.Ball and g.Ball.Parent and #g.Npcs >= 2 then
		-- Pasa la pelota al siguiente
		local nextHolder = (g.Holder or 1) % #g.Npcs + 1
		local from, to = g.Npcs[g.Holder or 1], g.Npcs[nextHolder]
		if from.PrimaryPart and to.PrimaryPart then
			local goal = to.PrimaryPart.Position
			local feet = Vector3.new(goal.X, g.Anchor.Level + 0.55, goal.Z)
			pcall(function()
				TweenService:Create(g.Ball, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(feet) }):Play()
			end)
			pcall(Npc.face, to, from.PrimaryPart.Position)
		end
		g.Holder = nextHolder
		g.NextAt = t + 1.8 + math.random() * 1.5
		return
	end
	local path = g.Path
	if path and #path >= 2 and not Npc.isWalking(lead) then
		g.Step = g.Step % #path + 1
		local goal = path[g.Step]
		local activity = PlaceLife.Activities[g.Activity]
		local speed = activity and activity.Speed or 5
		local work = lead:GetAttribute("Work")
		for i, npc in g.Npcs do
			local offset = Vector3.zero
			if i > 1 and lead.PrimaryPart then
				-- La pareja va a su lado
				local dir = goal - lead.PrimaryPart.Position
				local flat = Vector3.new(dir.X, 0, dir.Z)
				offset = if flat.Magnitude > 0.1 then Vector3.new(-flat.Unit.Z, 0, flat.Unit.X) * 1.8 else Vector3.new(1.8, 0, 0)
			end
			task.spawn(function()
				if g.Activity ~= "Fotos" then
					pcall(Npc.work, npc, nil)
				end
				pcall(Npc.walkTo, npc, { goal + offset }, speed)
				if work and npc.Parent then
					pcall(Npc.work, npc, work)
				end
			end)
		end
		g.NextAt = t + (if g.Activity == "Correr" then 0.3 else 6 + math.random() * 10)
	end
end

-- Frases de la calle: una cada ChatterEvery segundos en todo el servidor, solo cerca de alguien
function PlaceLifeService.chatter(force: boolean?)
	local t = os.clock()
	if not force and t - lastChatter < PlaceLife.ChatterEvery then
		return
	end
	local hour, weather = TimeContext.now()
	local list = viewers()
	local near: { Group } = {}
	for _, a in anchors do
		for _, g in a.Groups do
			local root = g.Npcs[1] and g.Npcs[1].PrimaryPart
			if root then
				for _, v in list do
					if flatDistance(v.Pos, root.Position) < 45 then
						table.insert(near, g)
						break
					end
				end
			end
		end
	end
	local g = pick(near)
	if not g then
		return
	end
	local activity = PlaceLife.Activities[g.Activity]
	local lines = PlaceLife.Lines[activity and activity.Lines or "Charla"] or PlaceLife.Lines.Charla
	if PlaceLife.wet(weather) and math.random() < 0.4 then
		lines = PlaceLife.Lines.Lluvia
	end
	local speaker = pick(g.Npcs)
	if not speaker or speaker:GetAttribute("Says") then
		return
	end
	lastChatter = t
	pcall(Npc.say, speaker, TimeContext.pick(lines, hour, weather) or lines[1], 3.5)
	-- En un corro, otro le contesta
	if #g.Npcs >= 2 and (g.Activity == "Charla" or g.Activity == "Cartas" or g.Activity == "Petanca" or g.Activity == "Pareja") then
		local other = g.Npcs[(table.find(g.Npcs, speaker) or 1) % #g.Npcs + 1]
		task.delay(2.8, function()
			if other.Parent then
				pcall(Npc.say, other, TimeContext.pick(lines, hour, weather) or lines[#lines], 3)
			end
		end)
	end
end

function PlaceLifeService.tick()
	local hour, weather, weekday = now()
	local list = viewers()
	-- 1) Cuánta gente del servidor tiene ya cada jugador alrededor (la de aquí y la de CrowdService)
	local budget: { [any]: number } = {}
	for _, v in list do
		budget[v] = PlaceLifeService.nearCount(v.Pos, PlaceLife.Radius) + crowdNear(v.Pos, PlaceLife.Radius)
	end
	local total = PlaceLifeService.count()
	-- 2) Vaciar lo lejano y lo que sobra (lluvia, noche); anotar lo que falta
	local wanting: { { Anchor: Anchor, Distance: number, Want: number } } = {}
	for _, a in anchors do
		for i = #a.Groups, 1, -1 do
			local g = a.Groups[i]
			local alive = false
			for _, npc in g.Npcs do
				alive = alive or npc.Parent ~= nil
			end
			if not alive then
				table.remove(a.Groups, i)
			end
		end
		local nearest = math.huge
		for _, v in list do
			nearest = math.min(nearest, anchorDistance(a, v.Pos))
		end
		local have = 0
		for _, g in a.Groups do
			have += groupSize(g)
		end
		if nearest > PlaceLife.Keep then
			for _, g in table.clone(a.Groups) do
				removeGroup(g)
			end
		else
			local want = PlaceLife.amount(a.Kind, hour, weather, weekday)
			if not a.Instance.Parent then
				want = 0
			end
			local line = if PlaceLife.wet(weather) then "¡Que llueve! Me voy." elseif hour >= 20.5 or hour < 6.5 then "Qué tarde se ha hecho. ¡A casa!" else "Bueno, me voy yendo."
			-- Lo que ya no pega (la toalla o la pelota con lluvia, los columpios de noche): recogen y se van
			for i = #a.Groups, 1, -1 do
				local g = a.Groups[i]
				local activity = PlaceLife.Activities[g.Activity]
				if activity and not PlaceLife.fits(activity, hour, weather) then
					have -= groupSize(g)
					removeGroup(g, line)
				end
			end
			if have > want then
				-- Sobra gente (empieza a llover, se hace de noche, cierran): se van los últimos en llegar
				for i = #a.Groups, 1, -1 do
					if have <= want then
						break
					end
					local g = a.Groups[i]
					have -= groupSize(g)
					removeGroup(g, line)
				end
			elseif nearest <= PlaceLife.Radius and have < want then
				table.insert(wanting, { Anchor = a, Distance = nearest, Want = want - have })
			end
			for _, g in a.Groups do
				pcall(animate, g)
			end
		end
	end
	total = PlaceLifeService.count()
	-- 3) Llenar (los más cercanos primero) sin pasarse de ningún tope
	table.sort(wanting, function(x, y)
		return x.Distance < y.Distance
	end)
	local made = 0
	for _, w in wanting do
		if made >= PlaceLife.SpawnPerTick or total >= PlaceLife.GlobalCap then
			break
		end
		local a = w.Anchor
		local name, size = nil, 0
		for _ = 1, 3 do
			local n = PlaceLife.pick(a.Kind, hour, weather)
			if n then
				local s = PlaceLife.groupSize(n)
				local activity = PlaceLife.Activities[n]
				local minimum = if activity.Size then activity.Size[1] else 1
				s = math.min(s, w.Want)
				if s >= minimum then
					name, size = n, s
					break
				end
			end
		end
		-- ¿Cabe en el presupuesto de cada jugador que lo vería?
		local fits = name ~= nil and total + size <= PlaceLife.GlobalCap
		local affected = {}
		if fits then
			for _, v in list do
				if anchorDistance(a, v.Pos) <= PlaceLife.Radius then
					table.insert(affected, v)
					if budget[v] + size > PlaceLife.PlayerBudget then
						fits = false
					end
				end
			end
		end
		if fits and name then
			local ok, g = pcall(build, a, name, size, list, weather)
			if ok and g then
				table.insert(a.Groups, g)
				made += 1
				total += #g.Npcs
				for _, v in affected do
					budget[v] += #g.Npcs
				end
			elseif ok and not g then
				-- (no cabía ahora: se prueba en otra vuelta)
			else
				warn("[PlaceLifeService] " .. tostring(g))
			end
		end
	end
end

function PlaceLifeService.init()
	local f = Instance.new("Folder")
	f.Name = "VidaLugares"
	f.Parent = workspace
	folder = f
	task.defer(PlaceLifeService.scan)
	for _, kind in PlaceLife.Order do
		for _, tag in PlaceLife.Places[kind].Tags or {} do
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
				task.defer(PlaceLifeService.addAnchor, kind, instance)
			end)
		end
	end
	task.spawn(function()
		while true do
			task.wait(PlaceLife.Tick)
			local ok, err = pcall(PlaceLifeService.tick)
			if not ok then
				warn("[PlaceLifeService] " .. tostring(err))
			end
			pcall(PlaceLifeService.chatter)
		end
	end)
end

return PlaceLifeService
