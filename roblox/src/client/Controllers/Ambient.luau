-- Ambient (cliente): tráfico y peatones alrededor del jugador.
-- Se simula en cada dispositivo (no en el servidor) y solo cerca del jugador,
-- así la ciudad parece viva sin coste de red ni de servidor.
--  * Vehículos (coches, taxis, motos, bicis y patinetes): ver Traffic.luau.
--  * Peatones: caminan por las aceras con animación de pasos. Hay más en las horas punta (entrada y
--    salida del trabajo, la comida), algo menos a media tarde, pocos de noche y menos con lluvia
--    (Ambient.density). Paseando, corriendo, con el perro, con bolsas, al móvil, niños, parejas de la
--    mano y repartidores con la caja a la espalda. De vez en cuando alguien cerca suelta una frase.
--    Si chocas con uno (o lo empujas), se aparta de lado con un traspiés, te mira y a veces suelta
--    un "¡Eh!"; luego sigue su camino. Si llega tu coche, se tira a un lado.
--    En los cruces con semáforo esperan en el bordillo a tener verde (Traffic.mayCross) y, cruzando,
--    los coches los ven y frenan (Traffic.setWalkers). Si alguien va más despacio delante, le
--    adelantan por la izquierda. Si empieza a llover sacan el paraguas (y aprietan el paso); si
--    para, lo guardan. Aparecen y se retiran fuera de tu vista. Los niños, a casa a las 19:30.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Traffic = require(script.Parent.Traffic)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Sidewalk = require(ReplicatedStorage.Shared.Sidewalk)
local Nudge = require(script.Parent.Nudge)
local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)

local Ambient = {}

local player = Players.LocalPlayer

local Perf = require(script.Parent.Parent.UI.Perf)
-- Presupuesto de peatones (solo en tu pantalla, sin coste de servidor ni de red): 48 en ordenador y
-- 24 en móvil (Perf.count). Cuántos andan a la vez lo decide Ambient.density (hora, lluvia, finde).
local PED_COUNT = Perf.count(48, 20)
local WALK_TOP = 1.0
local TURN_TIME = 0.7 -- lo que tarda en darse la vuelta al final de la acera
local KEEP_RIGHT = 0.9 -- cada uno por su derecha de la acera
local SEEN = 150 -- más cerca que esto del jugador, un peatón no desaparece: sigue o se da la vuelta
local BODY = 0.95 -- medio ancho de un peatón (para no rozar farolas ni papeleras)
-- Cada calle es un tramo recto en cualquier ángulo: A + Dir·u (u de From a To) + Perp·v
-- Ahead/Behind: la calle que sigue recta al pasar el cruce del final (To) o del principio (From);
-- Flip: va en sentido contrario. EndMargin/StartMargin: dónde se da la vuelta si no sigue (antes de
-- pisar la calzada de la calle que cruza).
type Link = { Road: any, Flip: boolean }
type Road = {
	A: Vector3,
	Dir: Vector3,
	Perp: Vector3,
	Len: number,
	From: number,
	To: number,
	Lane: number,
	Walk: number?,
	Half: number,
	Ahead: Link?,
	Behind: Link?,
	StartMargin: number,
	EndMargin: number,
	CrossStart: number?, -- lo que ocupa la calzada de la calle que cruza al principio / al final
	CrossEnd: number?, -- (el paso de peatones: ahí se espera al verde y ahí los coches frenan)
	WalkIn: number?, -- la acera va de WalkIn a WalkOut del centro (a los dos lados)
	WalkOut: number?,
	Obstacles: { Sidewalk.Obstacle }, -- farolas, papeleras, quioscos… (shared/Sidewalk)
}
type Agent = {
	Model: Model,
	Parts: { BasePart },
	Offsets: { CFrame },
	Poses: { CFrame }, -- (tabla reutilizada para BulkMoveTo: una por peatón, no una por fotograma)
	Road: Road?,
	U: number,
	Dir: number,
	Speed: number,
	Cruise: number,
	Side: number,
	Phase: number,
	Active: boolean,
	Style: string,
	Scale: number,
	Index: { [string]: number },
	Umbrella: boolean,
	PanicUntil: number?,
	ReactAt: number?, -- cuándo empezó el último traspiés (choque contigo o con tu coche)
	ReactSide: number?, -- +1: le llegaste por su derecha
	ReactDive: boolean?,
	Shove: number?, -- cuánto se aparta de su sitio en la acera (de lado)
	ShoveNow: number?,
	TurnAt: number?, -- cuándo empezó a darse la vuelta (al final de la acera)
	Keep: number?, -- lo que se arrima a su derecha (los que van y vienen no se atraviesan)
	Dodge: number?, -- lo que se aparta de su sitio para esquivar una farola, una papelera…
	Lateral: number?, -- dónde iba en la acera el último fotograma (para adelantar)
	PassUntil: number?, -- adelantando por la izquierda hasta entonces
	Far: boolean?, -- lejos (o fuera de la vista) el último fotograma: se mueve 1 de cada 3 (LOD)
	Skip: number?, -- fotogramas saltados desde la última vez que se movió
	Acc: number?, -- tiempo acumulado mientras se salta fotogramas
	LastPos: Vector3?, -- dónde estaba la última vez que se movió
}

local roads: { Road } = {}
local peds: { Agent } = {}
local folder: Folder

local function point(road: Road, u: number, v: number, y: number): Vector3
	local p = road.A + road.Dir * u + road.Perp * v
	return Vector3.new(p.X, y, p.Z)
end

local function heading(road: Road, dir: number): CFrame
	local d = road.Dir * dir
	return CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

local function focus(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return camera and camera.Focus.Position
end

local inView = Traffic.inView

-- Elige una calle cercana y una posición en ella a una distancia razonable del jugador
local function spawnPoint(center: Vector3, minDist: number, maxDist: number): (Road?, number)
	for _ = 1, 12 do
		local road = roads[math.random(1, #roads)]
		local rel = center - road.A
		local along = rel:Dot(road.Dir)
		local offset = math.abs(rel:Dot(road.Perp))
		if offset < maxDist then
			local reach = math.sqrt(maxDist * maxDist - offset * offset)
			local u0 = math.max(road.From + 10, along - reach)
			local u1 = math.min(road.To - 10, along + reach)
			if u1 > u0 then
				local u = u0 + math.random() * (u1 - u0)
				local distance = math.sqrt((u - along) ^ 2 + offset * offset)
				if distance >= minDist then
					return road, u
				end
			end
		end
	end
	return nil, 0
end

local function setActive(agent: Agent, active: boolean)
	if agent.Active ~= active then
		agent.Active = active
		agent.Model.Parent = if active then folder else nil
	end
end

---------------------------------------------------------------------
-- Peatones
---------------------------------------------------------------------

local SKIN = { Color3.fromRGB(255, 219, 182), Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 140, 100), Color3.fromRGB(141, 94, 64), Color3.fromRGB(96, 64, 44) }
local CLOTHES = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(50, 90, 170), Color3.fromRGB(40, 140, 90), Color3.fromRGB(230, 200, 70), Color3.fromRGB(240, 240, 240), Color3.fromRGB(40, 40, 44), Color3.fromRGB(150, 80, 160), Color3.fromRGB(240, 140, 60) }
local PANTS = { Color3.fromRGB(40, 50, 90), Color3.fromRGB(30, 30, 34), Color3.fromRGB(110, 90, 70), Color3.fromRGB(80, 80, 86), Color3.fromRGB(60, 80, 120) }
local HAIR = { Color3.fromRGB(30, 22, 18), Color3.fromRGB(90, 60, 30), Color3.fromRGB(200, 170, 110), Color3.fromRGB(150, 60, 30), Color3.fromRGB(180, 180, 180) }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end
local JOG_SHIRTS = { Color3.fromRGB(250, 120, 40), Color3.fromRGB(60, 200, 220), Color3.fromRGB(240, 240, 240), Color3.fromRGB(230, 60, 120) }

-- Tipos de peatón (con su probabilidad): paseando, corriendo, con el perro, con bolsas de la
-- compra, mirando el móvil o niños. Si llueve, casi todos sacan el paraguas.
local STYLES = { { "Walk", 28 }, { "Jog", 9 }, { "Dog", 11 }, { "Bag", 15 }, { "Phone", 13 }, { "Kid", 11 }, { "Couple", 8 }, { "Delivery", 5 } }
local DOG_COLORS = { Color3.fromRGB(150, 100, 60), Color3.fromRGB(40, 36, 34), Color3.fromRGB(230, 220, 200), Color3.fromRGB(200, 150, 80) }
local UMBRELLA_COLORS = { Color3.fromRGB(30, 30, 34), Color3.fromRGB(200, 40, 50), Color3.fromRGB(40, 80, 170), Color3.fromRGB(240, 200, 40), Color3.fromRGB(120, 60, 140) }

local function pickStyle(): string
	local total = 0
	for _, s in STYLES do
		total += s[2]
	end
	local r = math.random() * total
	for _, s in STYLES do
		r -= s[2]
		if r <= 0 then
			return s[1]
		end
	end
	return "Walk"
end

local function raining(): boolean
	local weather = workspace:GetAttribute("Weather")
	return weather == "Lluvia" or weather == "Tormenta"
end

-- Figura de peatón: 1 torso, 2 cabeza, 3 pelo, 4-5 piernas, 6-7 brazos y luego los extras
-- (paraguas, bolsa, móvil, perro y correa) según el tipo
local function makePed(): Agent
	local model = Instance.new("Model")
	model.Name = "Peaton"
	local style = pickStyle()
	local scale = if style == "Kid" then 0.68 else 1
	local skin, shirt, pants = pick(SKIN), pick(CLOTHES), pick(PANTS)
	if style == "Jog" then
		shirt, pants = pick(JOG_SHIRTS), Color3.fromRGB(30, 30, 34)
	end
	local s = scale
	local specs = {
		{ "Torso", Vector3.new(2, 2.3, 1.1) * s, shirt, Enum.PartType.Block },
		{ "Head", Vector3.new(1.3, 1.3, 1.3) * s, skin, Enum.PartType.Ball },
		{ "Hair", Vector3.new(1.4, 0.55, 1.4) * s, pick(HAIR), Enum.PartType.Block },
		{ "LegL", Vector3.new(0.9, 2.4, 0.95) * s, pants, Enum.PartType.Block },
		{ "LegR", Vector3.new(0.9, 2.4, 0.95) * s, pants, Enum.PartType.Block },
		{ "ArmL", Vector3.new(0.7, 2.2, 0.75) * s, shirt, Enum.PartType.Block },
		{ "ArmR", Vector3.new(0.7, 2.2, 0.75) * s, shirt, Enum.PartType.Block },
		-- Paraguas (se esconde si no llueve)
		{ "UmbrellaStick", Vector3.new(0.12, 3.2, 0.12), Color3.fromRGB(50, 50, 54), Enum.PartType.Block },
		{ "Umbrella", Vector3.new(0.5, 5.2, 5.2), pick(UMBRELLA_COLORS), Enum.PartType.Cylinder },
	}
	if style == "Bag" then
		table.insert(specs, { "Bag", Vector3.new(0.5, 1.3, 1.1), pick({ Color3.fromRGB(240, 236, 226), Color3.fromRGB(60, 140, 80), Color3.fromRGB(200, 60, 50) }), Enum.PartType.Block })
	elseif style == "Phone" then
		table.insert(specs, { "Phone", Vector3.new(0.5, 0.9, 0.12), Color3.fromRGB(20, 20, 24), Enum.PartType.Block })
	elseif style == "Delivery" then
		-- Repartidor: caja térmica a la espalda
		table.insert(specs, { "Box", Vector3.new(1.9, 1.9, 1.3), pick({ Color3.fromRGB(240, 180, 40), Color3.fromRGB(40, 190, 170), Color3.fromRGB(220, 50, 60) }), Enum.PartType.Block })
	elseif style == "Couple" then
		-- Pareja: una segunda figura a su lado (de la mano), con su ropa
		local pShirt, pPants = pick(CLOTHES), pick(PANTS)
		table.insert(specs, { "P_Torso", Vector3.new(2, 2.3, 1.1), pShirt, Enum.PartType.Block })
		table.insert(specs, { "P_Head", Vector3.new(1.3, 1.3, 1.3), pick(SKIN), Enum.PartType.Ball })
		table.insert(specs, { "P_Hair", Vector3.new(1.4, 0.55, 1.4), pick(HAIR), Enum.PartType.Block })
		table.insert(specs, { "P_LegL", Vector3.new(0.9, 2.4, 0.95), pPants, Enum.PartType.Block })
		table.insert(specs, { "P_LegR", Vector3.new(0.9, 2.4, 0.95), pPants, Enum.PartType.Block })
		table.insert(specs, { "P_ArmL", Vector3.new(0.7, 2.2, 0.75), pShirt, Enum.PartType.Block })
		table.insert(specs, { "P_ArmR", Vector3.new(0.7, 2.2, 0.75), pShirt, Enum.PartType.Block })
	elseif style == "Dog" then
		local fur = pick(DOG_COLORS)
		table.insert(specs, { "DogBody", Vector3.new(0.9, 0.9, 2.2), fur, Enum.PartType.Block })
		table.insert(specs, { "DogHead", Vector3.new(0.8, 0.8, 0.9), fur, Enum.PartType.Block })
		table.insert(specs, { "DogSnout", Vector3.new(0.45, 0.4, 0.4), fur:Lerp(Color3.new(0, 0, 0), 0.3), Enum.PartType.Block })
		for _, name in { "DogLegFL", "DogLegFR", "DogLegBL", "DogLegBR" } do
			table.insert(specs, { name, Vector3.new(0.28, 0.9, 0.28), fur, Enum.PartType.Block })
		end
		table.insert(specs, { "DogTail", Vector3.new(0.18, 0.18, 0.9), fur, Enum.PartType.Block })
		table.insert(specs, { "Leash", Vector3.new(0.08, 0.08, 1), Color3.fromRGB(200, 40, 40), Enum.PartType.Block })
	end
	local parts, index = {}, {}
	for _, spec in specs do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.Color = spec[3]
		p.Shape = spec[4]
		p.Material = if spec[1] == "Umbrella" then Enum.Material.Fabric else Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = spec[1] ~= "Leash"
		p.Parent = model
		table.insert(parts, p)
		index[spec[1]] = #parts
	end
	return {
		Model = model,
		Parts = parts,
		Offsets = {},
		Poses = table.create(#parts),
		Road = nil,
		U = 0,
		Dir = 1,
		Speed = 0,
		Cruise = 0,
		Side = 1,
		Phase = math.random() * 6,
		Active = false,
		Style = style,
		Scale = scale,
		Index = index,
		Umbrella = false,
	}
end

-- Ropa nueva al reciclarlo (antes, el que se iba lejos volvía a salir cerca con la misma ropa: se
-- veía a la misma persona pasar una y otra vez)
local function redress(agent: Agent)
	local parts, i = agent.Parts, agent.Index
	local skin, shirt, pants = pick(SKIN), pick(CLOTHES), pick(PANTS)
	if agent.Style == "Jog" then
		shirt, pants = pick(JOG_SHIRTS), Color3.fromRGB(30, 30, 34)
	end
	parts[i.Torso].Color, parts[i.ArmL].Color, parts[i.ArmR].Color = shirt, shirt, shirt
	parts[i.LegL].Color, parts[i.LegR].Color = pants, pants
	parts[i.Head].Color, parts[i.Hair].Color = skin, pick(HAIR)
	if i.P_Torso then
		local pShirt, pPants = pick(CLOTHES), pick(PANTS)
		parts[i.P_Torso].Color, parts[i.P_ArmL].Color, parts[i.P_ArmR].Color = pShirt, pShirt, pShirt
		parts[i.P_LegL].Color, parts[i.P_LegR].Color = pPants, pPants
		parts[i.P_Head].Color, parts[i.P_Hair].Color = pick(SKIN), pick(HAIR)
	end
	parts[i.Umbrella].Color = pick(UMBRELLA_COLORS)
end

-- Paraguas: casi todos lo sacan si llueve (los que corren, no)
local function setUmbrella(agent: Agent, rain: boolean)
	agent.Umbrella = rain and agent.Style ~= "Jog" and math.random() < 0.85
	local stick, canopy = agent.Parts[agent.Index.UmbrellaStick], agent.Parts[agent.Index.Umbrella]
	stick.Transparency = if agent.Umbrella then 0 else 1
	canopy.Transparency = if agent.Umbrella then 0 else 1
end

-- ¿Se vería aparecer ahí? (cerca y delante de la cámara)
local function inSight(road: Road, u: number, center: Vector3): boolean
	local at = point(road, u, road.Walk or 15.5, WALK_TOP)
	return (at - center).Magnitude <= 170 and inView(at)
end

local function respawnPed(agent: Agent, center: Vector3, initial: boolean)
	local road, u = spawnPoint(center, if initial then 10 else 90, 200)
	-- Nunca aparece a la vista (salvo lejos): antes salía gente de la nada a 90 studs delante de ti
	if not initial then
		for _ = 1, 4 do
			if not road or not inSight(road, u, center) then
				break
			end
			road, u = spawnPoint(center, 90, 200)
		end
		if road and inSight(road, u, center) then
			road = nil -- (se prueba otra vez en otro fotograma)
		end
	end
	if road and not road.Walk then
		road = nil -- las autovías no tienen acera
	end
	agent.Road = road
	if not road then
		setActive(agent, false)
		return
	end
	agent.U = u
	agent.Dir = if math.random() < 0.5 then 1 else -1
	agent.Side = if math.random() < 0.5 then 1 else -1
	agent.TurnAt, agent.Keep, agent.Dodge, agent.PassUntil, agent.Lateral = nil, nil, nil, nil, nil
	if not initial then
		redress(agent)
	end
	local style = agent.Style
	agent.Cruise = if style == "Jog" then 9 + math.random() * 2.5
		elseif style == "Kid" then 4 + math.random() * 1.5
		elseif style == "Dog" or style == "Phone" or style == "Couple" then 3.5 + math.random() * 1.5
		elseif style == "Delivery" then 7 + math.random() * 1.5
		else 4.5 + math.random() * 2.5
	agent.Speed = agent.Cruise
	setUmbrella(agent, raining())
	setActive(agent, true)
end

-- Traspiés: 0 → 1 → 0 en "dur" segundos (sube rápido y baja suave)
local function reactWeight(agent: Agent, now: number): number
	local start = agent.ReactAt
	if not start then
		return 0
	end
	local dur = if agent.ReactDive then 1.3 else 1.0
	local t = (now - start) / dur
	if t <= 0 or t >= 1 then
		return 0
	end
	return if t < 0.2 then math.sin(t / 0.2 * math.pi / 2) else math.cos((t - 0.2) / 0.8 * math.pi / 2)
end

local function posePed(agent: Agent, root: CFrame, react: number?, still: boolean?)
	local k = react or 0
	if k > 0.001 then
		-- Se echa hacia el lado contrario al choque (mucho más si se tira por un coche)
		local side = agent.ReactSide or 1
		root = root * CFrame.Angles(if agent.ReactDive then -0.25 * k else 0.06 * k, 0, side * (if agent.ReactDive then 0.7 else 0.2) * k)
	end
	local s = agent.Scale
	local jog = agent.Style == "Jog"
	-- (fuera de la vista no hace falta mover brazos y piernas: nadie lo ve)
	local swing = if still then 0 else math.sin(agent.Phase) * (if jog then 0.95 else 0.55)
	local bob = math.abs(math.cos(agent.Phase)) * (if jog then 0.35 else 0.12) * s
	local base = root * CFrame.new(0, bob, 0)
	if jog then
		base *= CFrame.Angles(-0.12, 0, 0) -- inclinado hacia delante
	end
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * s, y * s, z * s)
	end
	local armL = at(-1.38, 4.55, 0) * CFrame.Angles(-swing * 0.8, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	local armR = at(1.38, 4.55, 0) * CFrame.Angles(swing * 0.8, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	if agent.Umbrella then
		armL = at(-1.38, 4.55, 0) * CFrame.Angles(0.9, 0, 0.15) * CFrame.new(0, -1.05 * s, 0)
	end
	if agent.Style == "Phone" then
		armR = at(1.38, 4.55, 0) * CFrame.Angles(1.3, 0, 0.35) * CFrame.new(0, -1.05 * s, 0)
	elseif agent.Style == "Bag" then
		armR = at(1.38, 4.55, 0) * CFrame.Angles(swing * 0.25, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	end
	local headTurn = CFrame.identity
	if k > 0.001 then
		-- Brazos arriba (para no caerse, o por encima de la cabeza si se tira) y la cabeza hacia ti
		local up = if agent.ReactDive then 2.4 else 0.9
		armL = at(-1.38, 4.55, 0) * CFrame.Angles(up * k, 0, -0.5 * k) * CFrame.new(0, -1.05 * s, 0)
		if agent.Style ~= "Bag" then
			armR = at(1.38, 4.55, 0) * CFrame.Angles(up * k, 0, 0.5 * k) * CFrame.new(0, -1.05 * s, 0)
		end
		headTurn = CFrame.Angles(0, -(agent.ReactSide or 1) * 0.7 * k, 0)
	end
	local cframes = agent.Poses
	cframes[1] = at(0, 3.55, 0) -- torso
	cframes[2] = at(0, 5.35, 0) * headTurn -- cabeza
	cframes[3] = at(0, 5.35, 0) * headTurn * CFrame.new(0, 0.6 * s, 0.05 * s) -- pelo
	cframes[4] = at(-0.48, 2.4, 0) * CFrame.Angles(swing, 0, 0) * CFrame.new(0, -1.2 * s, 0)
	cframes[5] = at(0.48, 2.4, 0) * CFrame.Angles(-swing, 0, 0) * CFrame.new(0, -1.2 * s, 0)
	cframes[6] = armL
	cframes[7] = armR
	local rot = base.Rotation
	-- Paraguas en la mano izquierda, abierto encima de la cabeza (sin paraguas no se ve: se deja donde
	-- está y no se calcula)
	if agent.Umbrella then
		local handL = (armL * CFrame.new(0, -1.05 * s, 0)).Position
		local stickTop = handL + Vector3.new(0, 3, 0)
		cframes[8] = CFrame.new(handL + Vector3.new(0, 1.5, 0)) * rot
		cframes[9] = CFrame.new(stickTop + Vector3.new(0, 0.1, 0)) * rot * CFrame.Angles(0, 0, math.rad(90))
	else
		local parts = agent.Parts
		cframes[8] = parts[8].CFrame
		cframes[9] = parts[9].CFrame
	end
	local handR = (armR * CFrame.new(0, -1.05 * s, 0)).Position
	local i = agent.Index
	if i.Bag then
		cframes[i.Bag] = CFrame.new(handR - Vector3.new(0, 0.75, 0)) * rot
	elseif i.Phone then
		cframes[i.Phone] = CFrame.new(handR + rot:VectorToWorldSpace(Vector3.new(-0.25, 0.25, -0.1))) * rot * CFrame.Angles(math.rad(-20), 0, 0)
	elseif i.DogBody then
		-- El perro trota a la derecha, un poco por delante, con la correa en la mano
		local trot = agent.Phase * 1.6
		local dog = root * CFrame.new(2.4, math.abs(math.sin(trot)) * 0.12, -1.8)
		cframes[i.DogBody] = dog * CFrame.new(0, 1.35, 0)
		cframes[i.DogHead] = dog * CFrame.new(0, 1.95, -1.3)
		cframes[i.DogSnout] = dog * CFrame.new(0, 1.8, -1.9)
		local leg = math.sin(trot) * 0.6
		cframes[i.DogLegFL] = dog * CFrame.new(-0.3, 0.9, -0.75) * CFrame.Angles(leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegFR] = dog * CFrame.new(0.3, 0.9, -0.75) * CFrame.Angles(-leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegBL] = dog * CFrame.new(-0.3, 0.9, 0.75) * CFrame.Angles(-leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegBR] = dog * CFrame.new(0.3, 0.9, 0.75) * CFrame.Angles(leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogTail] = dog * CFrame.new(0, 1.85, 1.3) * CFrame.Angles(math.rad(35), math.sin(agent.Phase * 4) * 0.5, 0)
		local collar = (dog * CFrame.new(0, 1.7, -0.9)).Position
		local mid = (handR + collar) / 2
		local leash = agent.Parts[i.Leash]
		local length = (collar - handR).Magnitude
		if math.abs(leash.Size.Z - length) > 0.05 then
			leash.Size = Vector3.new(0.08, 0.08, length)
		end
		cframes[i.Leash] = CFrame.lookAt(mid, collar)
	elseif i.Box then
		cframes[i.Box] = at(0, 3.9, 1.25)
	elseif i.P_Torso then
		-- Su pareja, a su izquierda, con el paso un poco desfasado y dándole la mano
		local pb = base * CFrame.new(-2 * s, 0, 0)
		local ps = math.sin(agent.Phase + 0.7) * 0.5
		local function pat(x: number, y: number, z: number): CFrame
			return pb * CFrame.new(x * s, y * s, z * s)
		end
		cframes[i.P_Torso] = pat(0, 3.55, 0)
		cframes[i.P_Head] = pat(0, 5.35, 0) * CFrame.Angles(0, -0.25, 0)
		cframes[i.P_Hair] = pat(0, 5.35, 0) * CFrame.Angles(0, -0.25, 0) * CFrame.new(0, 0.6 * s, 0.05 * s)
		cframes[i.P_LegL] = pat(-0.48, 2.4, 0) * CFrame.Angles(ps, 0, 0) * CFrame.new(0, -1.2 * s, 0)
		cframes[i.P_LegR] = pat(0.48, 2.4, 0) * CFrame.Angles(-ps, 0, 0) * CFrame.new(0, -1.2 * s, 0)
		cframes[i.P_ArmL] = pat(-1.38, 4.55, 0) * CFrame.Angles(-ps * 0.8, 0, 0) * CFrame.new(0, -1.05 * s, 0)
		cframes[i.P_ArmR] = pat(1.38, 4.55, 0) * CFrame.Angles(0.2, 0, 0.3) * CFrame.new(0, -1.05 * s, 0)
	end
	workspace:BulkMoveTo(agent.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local LINES = { "¡Eh!", "¡Cuidado!", "¡Perdona!", "¡Uy!", "¡Mira por dónde vas!" }

-- Frases sueltas de la calle (según quién sea); TimeContext quita las que no pegan con la hora o el tiempo
local CHATTER = {
	Walk = { "¡Buenos días!", "Voy tarde…", "¿Dónde habré aparcado?", "Qué buen día hace.", "Tengo que llamar a mi madre." },
	Jog = { "¡Uf!", "Un kilómetro más.", "¡Vamos, vamos!" },
	Dog = { "¡Toby, quieto!", "Vamos, chico.", "¡No tires tanto!" },
	Bag = { "Qué cargada voy…", "Se me ha olvidado el pan.", "Todo de oferta." },
	Phone = { "¿Sí? Dime.", "Te llamo luego.", "Ya casi llego.", "¡No me digas!" },
	Kid = { "¡Espérame!", "¡Carrera!", "¡Te pillé!" },
	Couple = { "¿Cenamos fuera?", "Mira ese escaparate.", "¿Vamos al cine?" },
	Delivery = { "¡Paso, paso!", "Voy con prisa.", "Último pedido." },
	Rain = { "¡Vaya chaparrón!", "Menos mal que traje paraguas.", "Esto no para…" },
}
local CHATTER_EVERY = 7 -- segundos entre frase y frase (como mucho una a la vez)
local nextChatter = 0

-- Qué parte de los peatones anda ahora por la calle (0..1): horas punta a tope, pocos de noche,
-- menos con lluvia; el finde, por la mañana, algo más tranquilo
function Ambient.density(clock: number, weather: string?, weekday: number?): number
	local f
	if clock >= 7.5 and clock < 9.5 or clock >= 13 and clock < 15 or clock >= 17.5 and clock < 20.5 then
		f = 1 -- hora punta
	elseif clock >= 9.5 and clock < 20.5 then
		f = 0.8
	elseif clock >= 20.5 and clock < 22.5 or clock >= 6.5 and clock < 7.5 then
		f = 0.55
	else
		f = 0.3 -- de noche
	end
	if weekday and weekday >= 6 and clock < 11 then
		f *= 0.75 -- (sábado y domingo se madruga menos)
	end
	if weather == "Lluvia" then
		f *= 0.65
	elseif weather == "Tormenta" or weather == "Nieve" then
		f *= 0.45
	end
	return f
end

-- Alguien cerca (a la vista, a 10-40 studs) suelta una frase corta de vez en cuando
local function chatter(center: Vector3)
	local now = os.clock()
	if now < nextChatter then
		return
	end
	nextChatter = now + CHATTER_EVERY + math.random() * 5
	local hour, weather = TimeContext.now()
	for _ = 1, 6 do
		local ped = peds[math.random(1, #peds)]
		local head = ped.Active and ped.Parts[ped.Index.Head]
		if head and not ped.ReactAt then
			local d = (head.Position - center).Magnitude
			if d > 10 and d < 40 then
				local lines = if raining() and math.random() < 0.5 then CHATTER.Rain else (CHATTER[ped.Style] or CHATTER.Walk)
				if not ped.Umbrella and lines == CHATTER.Rain then
					-- (lo del paraguas, solo quien lleva uno)
					local dry = {}
					for _, line in lines do
						if not string.find(line, "paraguas", 1, true) then
							table.insert(dry, line)
						end
					end
					lines = dry
				end
				local text = TimeContext.pick(lines, hour, weather)
				if text then
					Nudge.say(head, text, 2.4)
				end
				return
			end
		end
	end
end

-- ¿Espera en el bordillo? Va a pisar la calzada de la calle que cruza (paso de peatones) y el semáforo
-- no le deja (Traffic.mayCross). Una vez cruzando, sigue.
local function waitsAtCurb(ped: Agent, road: Road, nextU: number): boolean
	if ped.Dir > 0 then
		local cross = road.CrossEnd
		if not road.Ahead or not cross or cross <= 0 then
			return false
		end
		local line = road.To - cross
		if ped.U > line or nextU <= line then
			return false
		end
		return not Traffic.mayCross(point(road, road.To, 0, 0), road.Dir)
	end
	local cross = road.CrossStart
	if not road.Behind or not cross or cross <= 0 then
		return false
	end
	local line = road.From + cross
	if ped.U < line or nextU >= line then
		return false
	end
	return not Traffic.mayCross(point(road, road.From, 0, 0), road.Dir)
end

-- ¿Está en la calzada, cruzando? (para que los coches le vean)
local function crossing(ped: Agent, road: Road): boolean
	return (road.CrossEnd ~= nil and road.CrossEnd > 0 and road.Ahead ~= nil and ped.U > road.To - road.CrossEnd)
		or (road.CrossStart ~= nil and road.CrossStart > 0 and road.Behind ~= nil and ped.U < road.From + road.CrossStart)
end

local lastRain: boolean? = nil

-- Tablas reutilizadas en cada fotograma (antes se creaban nuevas: basura para el recolector)
local byRoad: { [Road]: { Agent } } = {}
local walkers: { Vector3 } = {}
local NO_ONE: { Agent } = {}
local NO_WALKERS: { Vector3 } = {}

-- La densidad y la lluvia cambian despacio: se miran una vez por segundo, no en cada fotograma
local share = 1
local rainNow = false
local nextCheck = 0

-- Nivel de detalle: lejos (más de LOD_NEAR) o fuera de la vista, un peatón se mueve solo 1 de cada
-- LOD_EVERY fotogramas (con el tiempo acumulado, así va a la misma velocidad). Muy cerca de ti
-- (LOD_CLOSE), siempre en cada fotograma (por si le das sin mirarle).
local LOD_NEAR = 80
local LOD_CLOSE = 20
local LOD_EVERY = 3

local function updatePeds(frameDt: number, center: Vector3)
	local clock = Lighting.ClockTime
	-- Los niños, solo de 8:00 a 19:30 (de noche no hay críos solos por la calle)
	local kidsOut = clock >= 8 and clock < 19.5
	local now = os.clock()
	if now >= nextCheck then
		nextCheck = now + 1
		rainNow = raining()
		local weekday = nil
		pcall(function()
			weekday = ((workspace:GetAttribute("Day") or 1) - 1) % 7 + 1
		end)
		share = Ambient.density(clock, workspace:GetAttribute("Weather"), weekday)
	end
	-- Cambia el tiempo: sacan o guardan el paraguas
	local rain = rainNow
	if lastRain ~= nil and rain ~= lastRain then
		for _, ped in peds do
			setUmbrella(ped, rain)
		end
	end
	lastRain = rain
	-- Con lluvia, aprietan el paso (los que corren ya van deprisa)
	local hurry = if rain then 1.3 else 1
	-- Quién va por cada calle (para adelantar al que va más despacio)
	for _, list in byRoad do
		table.clear(list)
	end
	for _, ped in peds do
		local r = ped.Road
		if ped.Active and r then
			local list = byRoad[r]
			if not list then
				list = {}
				byRoad[r] = list
			end
			table.insert(list, ped)
		end
	end
	table.clear(walkers)
	-- Dónde estás tú (y si vas en coche, a qué velocidad)
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local carSpeed = 0
	if seat then
		local v = seat.AssemblyLinearVelocity
		carSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
	end
	for i, ped in peds do
		-- Según la hora y el tiempo sale más o menos gente (Ambient.density); de noche, ningún niño
		local wanted = (i - 0.5) / #peds <= share and not (not kidsOut and ped.Style == "Kid")
		if not wanted then
			-- Se retira el que está lejos (y fuera de la vista); el que tienes a la vista sigue su camino
			-- hasta que se aleja (antes, a las 21:30, la mitad de la gente desaparecía de golpe delante de ti)
			local r = ped.Road
			local at = if r then point(r, ped.U, ped.Side * (r.Walk or 15.5), WALK_TOP) else center
			local d = (at - center).Magnitude
			if not ped.Active or not r or (d > SEEN and (d > 200 or not inView(at))) then
				setActive(ped, false)
				ped.Road = nil
				continue
			end
		end
		local road = ped.Road
		if not road then
			respawnPed(ped, center, false)
			ped.Far, ped.Skip, ped.Acc, ped.LastPos = nil, nil, nil, nil
			continue
		end
		local dt = frameDt
		if ped.Far then
			-- Lejos o sin verle: se salta fotogramas y luego avanza con todo el tiempo acumulado
			ped.Acc = (ped.Acc or 0) + frameDt
			ped.Skip = (ped.Skip or 0) + 1
			if ped.Skip < LOD_EVERY then
				-- (si estaba cruzando, los coches le siguen viendo donde estaba)
				local last = ped.LastPos
				if last and crossing(ped, road) and (last - center).Magnitude < 260 then
					table.insert(walkers, last)
				end
				continue
			end
			dt = ped.Acc :: number
		end
		ped.Acc, ped.Skip = 0, 0
		if ped.PanicUntil then
			-- Asustado por unos disparos: corre y luego vuelve a su paso
			if os.clock() > ped.PanicUntil then
				ped.PanicUntil = nil
				ped.Speed = ped.Cruise
			end
		end
		-- Parado un momento mientras se recupera del traspiés (o mientras se da la vuelta)
		local stunned = ped.ReactAt ~= nil and now - ped.ReactAt < (if ped.ReactDive then 1.1 else 0.7)
		local turning = ped.TurnAt ~= nil and now - ped.TurnAt < TURN_TIME
		if turning then
			ped.Phase += dt * 3 -- (unos pasitos en el sitio al girar)
		elseif not stunned then
			local pace = ped.Speed * (if ped.Style == "Jog" or ped.PanicUntil then 1 else hurry)
			local step = ped.Dir * pace * dt
			if not ped.PanicUntil and waitsAtCurb(ped, road, ped.U + step) then
				step = 0 -- (espera al verde en el bordillo)
			end
			ped.U += step
			if step ~= 0 then
				ped.Phase += dt * pace * (if ped.Style == "Kid" then 2.1 elseif ped.Style == "Jog" then 1.1 else 1.5)
			end
		end
		-- Se aparta de lado y, pasado el susto, vuelve poco a poco a su sitio en la acera
		local shoveTarget = if ped.ReactAt and now - ped.ReactAt < 2.2 then (ped.Shove or 0) else 0
		ped.ShoveNow = (ped.ShoveNow or 0) + (shoveTarget - (ped.ShoveNow or 0)) * math.min(1, dt * (if shoveTarget ~= 0 then 7 else 1.5))
		-- Por su derecha: el que viene de frente pasa por el otro lado (antes se atravesaban)
		-- Adelantar: si alcanza a alguien más lento que va por su mismo lado, le pasa por la izquierda
		-- (antes se atravesaban)
		if not turning and not stunned and ped.Lateral then
			for _, other in byRoad[road] or NO_ONE do
				if other ~= ped and other.Dir == ped.Dir and other.Side == ped.Side and other.Lateral then
					local ahead = (other.U - ped.U) * ped.Dir
					if ahead > 0 and ahead < 3.5 and math.abs(other.Lateral - ped.Lateral) < 1.6 and ped.Speed > other.Speed + 0.3 then
						ped.PassUntil = now + 1.8
						break
					end
				end
			end
		end
		local passing = ped.PassUntil ~= nil and now < ped.PassUntil
		local keepTarget = ped.Dir * (if passing then KEEP_RIGHT - 1.9 else KEEP_RIGHT) -- (Perp·Dir es la derecha de hacia donde anda)
		ped.Keep = (ped.Keep or keepTarget) + (keepTarget - (ped.Keep or keepTarget)) * math.min(1, dt * 2)
		-- Esquivar lo que haya en la acera (farolas, papeleras, jardineras, quioscos, árboles…): se
		-- aparta a tiempo por el hueco libre más cercano; si aún lo tiene justo delante, espera a
		-- haberse apartado; si no cabe por ningún lado, se da la vuelta. Nunca lo atraviesa.
		local base = ped.Side * (road.Walk or 15.5) + (ped.Keep or 0)
		local dodgeTarget = 0
		if #road.Obstacles > 0 and road.WalkIn and road.WalkOut then
			local inner, outer = road.WalkIn + BODY + 0.15, road.WalkOut - BODY - 0.15
			local lo, hi = if ped.Side > 0 then inner else -outer, if ped.Side > 0 then outer else -inner
			local now_ = base + (ped.Dodge or 0) + (ped.ShoveNow or 0)
			local look = math.max(4, ped.Speed * 0.9)
			local v, stuck = Sidewalk.lane(road.Obstacles, ped.U, ped.Dir, look, base, lo, hi, BODY, now_)
			if v == nil then
				if not ped.TurnAt then
					ped.Dir = -ped.Dir
					ped.TurnAt = now
				end
			else
				dodgeTarget = v - base
				if stuck and not turning and not stunned then
					ped.U -= ped.Dir * ped.Speed * dt -- (no avanza hasta haberse apartado)
					ped.Phase -= dt * ped.Speed * 0.9
				end
			end
		end
		ped.Dodge = (ped.Dodge or 0) + (dodgeTarget - (ped.Dodge or 0)) * math.min(1, dt * 5)
		local lateral = base + (ped.Dodge or 0) + (ped.ShoveNow or 0)
		ped.Lateral = lateral
		local pos = point(road, ped.U, lateral, WALK_TOP)
		local dist = (pos - center).Magnitude
		local far = dist > SEEN
		local pastEnd = ped.U > road.To - road.EndMargin and ped.Dir > 0
		local pastStart = ped.U < road.From + road.StartMargin and ped.Dir < 0
		-- (a la vista no se recicla: sigue andando hasta que sale de la vista o está muy lejos)
		local hidden = dist > 300 or not inView(pos)
		if (dist > 240 and hidden) or ((pastEnd or pastStart) and far and hidden) then
			-- Lejos del jugador: se recicla cerca de él (aquí nadie lo ve irse)
			respawnPed(ped, center, false)
			ped.ReactAt, ped.Shove, ped.ShoveNow, ped.TurnAt, ped.Keep, ped.Dodge = nil, nil, nil, nil, nil, nil
			ped.Far, ped.LastPos = nil, nil
			continue
		elseif pastEnd or pastStart then
			-- A la vista: sigue recto por la acera de la calle de enfrente (cruzando por el paso de
			-- peatones) o, si no sigue ninguna, se da la vuelta antes de bajar a la calzada
			local link = if pastEnd then road.Ahead else road.Behind
			local over = if pastEnd then ped.U - road.To else road.From - ped.U
			if link and ((pastEnd and ped.U > road.To) or (pastStart and ped.U < road.From)) then
				local nextRoad = link.Road :: Road
				local oldWalk = road.Walk or 15.5
				ped.Road = nextRoad
				if link.Flip then
					-- Misma acera y mismo paso, con la calle al revés: se cambian los signos
					ped.Dir, ped.Side = -ped.Dir, -ped.Side
					ped.ShoveNow, ped.Keep, ped.Dodge = -(ped.ShoveNow or 0), -(ped.Keep or 0), -(ped.Dodge or 0)
					ped.Shove = if ped.Shove then -ped.Shove else nil
				end
				-- Si la acera de enfrente es más ancha o más estrecha, se arrima poco a poco (sin saltos)
				ped.ShoveNow = (ped.ShoveNow or 0) + ped.Side * (oldWalk - (nextRoad.Walk or 15.5))
				ped.U = if ped.Dir > 0 then nextRoad.From + over else nextRoad.To - over
				road = nextRoad
			elseif not link then
				ped.U = if pastEnd then road.To - road.EndMargin else road.From + road.StartMargin
				ped.Dir = -ped.Dir
				ped.TurnAt = now
			end
			pos = point(road, ped.U, ped.Side * (road.Walk or 15.5) + (ped.ShoveNow or 0) + (ped.Keep or 0) + (ped.Dodge or 0), WALK_TOP)
		end
		-- ¿Le has dado (o viene tu coche)?
		if myRoot then
			local rel = Vector3.new(myRoot.Position.X - pos.X, 0, myRoot.Position.Z - pos.Z)
			local d = rel.Magnitude
			local car = carSpeed > 10
			if (d < 3 or (car and d < 9)) and math.abs(myRoot.Position.Y - pos.Y) < 6 and (not ped.ReactAt or now - ped.ReactAt > 2.5) then
				ped.ReactAt = now
				ped.ReactDive = car
				-- Hacia qué lado de la acera se aparta: lejos de ti (sin salirse de la acera)
				local away = if rel:Dot(road.Perp) > 0 then -1 else 1
				ped.Shove = math.clamp((ped.ShoveNow or 0) + away * (if car then 2.6 else 1.4), -2.6, 2.6)
				local facing = road.Dir * ped.Dir
				local rightOfPed = Vector3.new(-facing.Z, 0, facing.X)
				ped.ReactSide = if rel:Dot(rightOfPed) > 0 then 1 else -1
				if car or math.random() < 0.55 then
					Nudge.say(ped.Parts[ped.Index.Head], if car then "¡Cuidado!" else LINES[math.random(1, #LINES)], 1.6)
				end
			elseif d < 2.2 and ped.ReactAt and now - ped.ReactAt < 2.2 then
				-- Empujón: si sigues encima, se aparta un poco más
				local away = if rel:Dot(road.Perp) > 0 then -1 else 1
				ped.Shove = math.clamp((ped.Shove or 0) + away * dt * 4, -2.6, 2.6)
			end
		end
		local facing = heading(road, ped.Dir)
		if ped.TurnAt then
			local k = (now - ped.TurnAt) / TURN_TIME
			if k >= 1 then
				ped.TurnAt = nil
			else
				-- Media vuelta poco a poco (antes daba la vuelta de golpe o desaparecía)
				local ease = (1 - math.cos(k * math.pi)) / 2
				facing = facing * CFrame.Angles(0, math.pi * (1 - ease), 0)
			end
		end
		-- (fuera de la vista, sin balancear brazos y piernas; lejos o sin verle, menos a menudo)
		local visible = inView(pos)
		local here = (pos - center).Magnitude
		ped.Far = here > LOD_NEAR or (here > LOD_CLOSE and not visible)
		ped.LastPos = pos
		posePed(ped, CFrame.new(pos) * facing, reactWeight(ped, now), not visible)
		if ped.Road and crossing(ped, ped.Road) and dist < 260 then
			table.insert(walkers, pos)
		end
	end
	Traffic.setWalkers(walkers)
end

---------------------------------------------------------------------

-- Modo ligero (móvil y ordenadores modestos): de la gente que pone el servidor en las salas, los
-- parques y las tiendas (CrowdService), la mitad no se ve en esta pantalla (atributo CrowdLite)
local function trimCrowd()
	if not Perf.lite then
		return
	end
	local function consider(d: Instance)
		if d:IsA("Model") and d:GetAttribute("CrowdLite") == true then
			task.defer(function()
				if d.Parent then
					d:Destroy()
				end
			end)
		end
	end
	for _, d in workspace:GetDescendants() do
		consider(d)
	end
	workspace.DescendantAdded:Connect(consider)
end

-- Disparos cerca (WeaponFx): la gente de la calle huye corriendo en dirección contraria
function Ambient.panic(position: Vector3, radius: number)
	for _, ped in peds do
		local road = ped.Road
		if road and ped.Active then
			local pos = point(road, ped.U, ped.Side * (road.Walk or 15.5), WALK_TOP)
			local away = pos - position
			if away.Magnitude < radius then
				local along = road.Dir * ped.Dir
				if along:Dot(away) < 0 then
					ped.Dir = -ped.Dir
				end
				ped.Speed = math.max(ped.Cruise, 5) * 2.6
				ped.PanicUntil = os.clock() + 4 + math.random() * 3
			end
		end
	end
end

-- Une las aceras en los cruces: qué calle sigue recta al otro lado de cada extremo y, si no sigue
-- ninguna, dónde darse la vuelta (antes del bordillo de la calle que cruza). Sin cruces a menos de 3
-- studs (fin de calle, rotonda recortada) = se da la vuelta en el extremo.
function Ambient.link(list: { Road })
	local function endOf(r: Road, atEnd: boolean): Vector3
		return if atEnd then r.A + r.Dir * r.Len else r.A
	end
	for _, r in list do
		for _, atEnd in { true, false } do
			local here = endOf(r, atEnd)
			local trimmed = if atEnd then r.To < r.Len - 0.01 else r.From > 0.01
			local best: Link? = nil
			local margin = 0
			for _, q in list do
				if q ~= r then
					for _, qEnd in { true, false } do
						local there = endOf(q, qEnd)
						if Vector3.new(there.X - here.X, 0, there.Z - here.Z).Magnitude < 3 then
							local dot = r.Dir:Dot(q.Dir)
							-- Sigue recta: por el final de r se entra por el principio de q (mismo sentido)
							-- o por el final de q (sentido contrario)
							local straight = if atEnd then (dot > 0.97 and not qEnd) or (dot < -0.97 and qEnd)
								else (dot > 0.97 and qEnd) or (dot < -0.97 and not qEnd)
							if straight and r.Walk and q.Walk and not trimmed then
								best = { Road = q, Flip = dot < 0 }
							elseif math.abs(dot) < 0.97 then
								margin = math.max(margin, q.Half + 1.5) -- (la calzada de la que cruza)
							end
						end
					end
				end
			end
			if atEnd then
				r.Ahead = best
				r.EndMargin = if best then 0 else math.min(margin, math.max(0, (r.To - r.From) / 3))
				r.CrossEnd = if best then math.min(margin, math.max(0, (r.To - r.From) / 3)) else 0
			else
				r.Behind = best
				r.StartMargin = if best then 0 else math.min(margin, math.max(0, (r.To - r.From) / 3))
				r.CrossStart = if best then math.min(margin, math.max(0, (r.To - r.From) / 3)) else 0
			end
		end
	end
end

function Ambient.init()
	task.spawn(trimCrowd)
	local data = ReplicatedStorage:WaitForChild("Ambient", 60)
	if not data then
		warn("[Ambient] No hay datos de calles: sin tráfico ni peatones")
		return
	end
	for _, config in data:WaitForChild("Roads"):GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (b - a).Magnitude > 20 then
			local dir = (b - a).Unit
			local width = config:GetAttribute("Width") or 24
			local kind = config:GetAttribute("Kind")
			local walkIn, walkOut = config:GetAttribute("WalkIn"), config:GetAttribute("WalkOut")
			local walkCenter = if typeof(walkIn) == "number" and typeof(walkOut) == "number" then (walkIn + walkOut) / 2 else width / 2 + 3.5
			-- Por la acera no se entra en una rotonda: se da la vuelta antes de su anillo
			local from, to = 0, (b - a).Magnitude
			for _, rb in CityPlan.Roundabouts do
				local c = Vector3.new(rb[1], a.Y, rb[2])
				local RING = 64
				if (a - c).Magnitude < RING then
					from = math.max(from, RING - (a - c).Magnitude)
				end
				if (b - Vector3.new(rb[1], b.Y, rb[2])).Magnitude < RING then
					to = math.min(to, (b - a).Magnitude - (RING - (b - Vector3.new(rb[1], b.Y, rb[2])).Magnitude))
				end
			end
			table.insert(roads, {
				A = a,
				Dir = dir,
				Perp = Vector3.new(-dir.Z, 0, dir.X),
				Len = (b - a).Magnitude,
				From = from,
				To = to,
				Lane = if width > 30 then width * 0.2 else 2.9,
				Walk = if kind == "Autovia" then nil else walkCenter, -- centro de la acera
				Half = width / 2,
				WalkIn = if typeof(walkIn) == "number" then walkIn else nil,
				WalkOut = if typeof(walkOut) == "number" then walkOut else nil,
				Obstacles = Sidewalk.decode(config:GetAttribute("Obstacles")),
				Ahead = nil,
				Behind = nil,
				StartMargin = 0,
				EndMargin = 0,
			})
		end
	end
	if #roads == 0 then
		return
	end
	Ambient.link(roads)

	folder = Instance.new("Folder")
	folder.Name = "AmbientLife"
	folder.Parent = workspace

	for _ = 1, PED_COUNT do
		table.insert(peds, makePed())
	end

	-- Primera colocación repartida alrededor del jugador
	local center = focus() or Vector3.zero
	for _, ped in peds do
		respawnPed(ped, center, true)
	end

	Traffic.init(data)

	RunService.RenderStepped:Connect(function(dt)
		local c = focus()
		if not c then
			return
		end
		Traffic.update(dt)
		-- Dentro de un edificio (salas en el cielo) no hay peatones que mover: se quedan en su sitio
		if c.Y > 3000 then
			Traffic.setWalkers(NO_WALKERS)
			return
		end
		updatePeds(math.min(dt, 0.1), c)
		chatter(c)
	end)
end

return Ambient
