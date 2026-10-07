-- CinePlanos: la AUDITORÍA VISUAL de las cinemáticas y de las conversaciones escenificadas, sin abrir
-- Roblox. Con el mapa real construido (TownBuilder, vía scripts/build-place.luau) pone en escena cada
-- paso de cada misión como lo haría el juego:
--   * dónde está el jugador (Teleport del paso, el lugar al que llegó, el personaje con quien habla…),
--   * dónde aparece cada actor (LocationService + SceneService: lugar, Index, Offset, Look, suelo con
--     el mismo rayo de SceneService.groundAt, separados entre sí, quien está lejos se acerca),
--   * qué planos salen: conversaciones con StageDirector (plano de situación, hombro, primer plano,
--     reacción tras una pregunta) y escenas del motor (Happenings) con Sequencer + CameraShots,
--   * y dónde acaba la cámara de verdad: el mismo CameraShots.fit que usan los clientes (DialogueUI y
--     HappeningClient) para no meterse en paredes, con rayos contra las piezas del mapa.
-- Luego comprueba cada plano (ver CinePlanos.Checks) y devuelve la lista de problemas.
--
-- Lo usan scripts/audit/cine-planos.luau (informe + datos para dibujar) y scripts/test-cineplanos.luau.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local H = require("./StoryHarness")
local Geo = require("./CineGeo")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local V = Vector3.new
local ROOT, loadModule = H.ROOT, H.loadModule

local Locations = loadModule(ROOT .. "/shared/LifeStory/Locations")
local CameraShots = loadModule(ROOT .. "/shared/CameraShots")
local StageDirector = loadModule(ROOT .. "/shared/LifeStory/StageDirector")
local Sequencer = loadModule(ROOT .. "/shared/LifeStory/Sequencer")
local HappeningIndex = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local Cast = loadModule(ROOT .. "/shared/LifeStory/Cast")
local ActorStaging = loadModule(ROOT .. "/shared/LifeStory/ActorStaging")
local CityPlan = loadModule(ROOT .. "/shared/CityPlan")
local Config = H.Config
local Quests = H.Quests

local E = {}
E.Geo = Geo
E.CameraShots = CameraShots
E.StageDirector = StageDirector

-- Umbrales de las comprobaciones
-- Avisos que no son fallos (límites de la auditoría)
E.Notices = { Terreno = true }

E.Checks = {
	FAR = 70, -- más lejos que esto del sujeto: plano absurdo (el general más largo de StageDirector: ~45)
	NEAR = 1.0, -- más cerca que esto de su cara: la cámara está dentro de su cabeza
	FRAME = 0.97, -- margen del encuadre (1 = el borde de la pantalla)
	ASPECT = 16 / 9,
	FLOAT = 0.7, -- pies a más de esto del suelo: flotando (o hundido)
}

local lookAt = CameraShots.lookAt
local function flat(v: Vector3): Vector3
	return V(v.X, 0, v.Z)
end

---------------------------------------------------------------------
-- 1. El mapa
---------------------------------------------------------------------
function E.buildMap(dir: string?): string
	local base = dir or ((process.env.TMPDIR or "/tmp") .. "/cineplanos-" .. tostring(os.time()))
	fs.writeDir(base)
	local path = base .. "/mapa.rbxl"
	print("▶ Construyendo el mapa (rojo build + build-place) en " .. path)
	local build = process.exec("rojo", { "build", "default.project.json", "-o", path })
	if not build.ok then
		error(build.stderr)
	end
	local town = process.exec("lune", { "run", "scripts/build-place.luau", path })
	if not town.ok then
		error(town.stderr)
	end
	print("  " .. (town.stdout:gsub("%s+$", "")))
	return path
end

export type Spot = { Position: Vector3, CFrame: CFrame, Size: Vector3, Instance: any, Radius: number }

-- Caja de un modelo como Model:GetBoundingBox (orientada como su PrimaryPart / pivote)
local function boundingBox(model: any): (CFrame, Vector3)
	local basis = CFrame.identity
	local ok = pcall(function()
		if model.PrimaryPart then
			basis = model.PrimaryPart.CFrame.Rotation
		else
			basis = model.WorldPivot.Rotation
		end
	end)
	if not ok then
		basis = CFrame.identity
	end
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	local any = false
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			any = true
			local cf, h = d.CFrame, d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = basis:PointToObjectSpace(cf:PointToWorldSpace(V(h.X * sx, h.Y * sy, h.Z * sz)))
						lo = V(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z))
						hi = V(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z))
					end
				end
			end
		end
	end
	if not any then
		return CFrame.new(), V(0, 0, 0)
	end
	local center = basis:PointToWorldSpace((lo + hi) / 2)
	return CFrame.new(center) * basis, hi - lo
end

function E.open(placePath: string): { [string]: any }
	print("▶ Leyendo " .. placePath)
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local workspace = game:GetService("Workspace")
	local t0 = os.clock()
	local world = Geo.load(workspace)
	print(("  %d piezas en la rejilla (%.1f s)"):format(world.Count, os.clock() - t0))
	-- Índices: modelos por nombre y piezas por etiqueta (lo que usan los lugares)
	local wantedModels, wantedTags = {}, {}
	for _, place in Locations.Places do
		if place.Model then
			wantedModels[place.Model] = true
		end
		if place.Tag then
			wantedTags[place.Tag] = true
		end
	end
	local byModel, byTag, plots = {}, {}, {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and wantedModels[d.Name] then
			byModel[d.Name] = byModel[d.Name] or {}
			table.insert(byModel[d.Name], d)
		end
		if d.Name:sub(1, 5) == "Plot_" then
			table.insert(plots, d)
		end
		local ok, tags = pcall(function()
			return d:GetTags()
		end)
		if ok and tags then
			for _, tag in tags do
				if wantedTags[tag] then
					byTag[tag] = byTag[tag] or {}
					table.insert(byTag[tag], d)
				end
			end
		end
	end
	local roads = {}
	pcall(function()
		local ambient = game:GetService("ReplicatedStorage"):FindFirstChild("Ambient")
		local folder = ambient and ambient:FindFirstChild("Roads")
		for _, road in if folder then folder:GetChildren() else {} do
			table.insert(roads, { A = road:GetAttribute("A"), B = road:GetAttribute("B"), Width = road:GetAttribute("Width") })
		end
	end)
	local zones = { { Name = "Valmar Centro", Center = V(0, 0, 0) } }
	for name, at in CityPlan.Towns do
		table.insert(zones, { Name = name, Center = V(at[1], 0, at[2]) })
	end
	local ctx = { Game = game, Workspace = workspace, World = world, ByModel = byModel, ByTag = byTag, Plots = plots, Roads = roads, Zones = zones, Spots = {} }
	-- La casa familiar del jugador: la primera del mapa con HomeId (como si BabyService le diera esa)
	for _, home in byTag.FamilyHome or {} do
		local id = home:GetAttribute("HomeId")
		if id ~= nil then
			ctx.FamilyHomeId = id
			break
		end
	end
	ctx.Plot = plots[1]
	return ctx
end

---------------------------------------------------------------------
-- 2. Los lugares (como LocationService.resolve, para un jugador en `from`)
---------------------------------------------------------------------
local function zoneAt(ctx, position: Vector3): string
	local best, bestDistance = "Valmar Centro", math.huge
	for _, zone in ctx.Zones do
		local distance = flat(position - zone.Center).Magnitude
		if distance < bestDistance then
			best, bestDistance = zone.Name, distance
		end
	end
	return best
end

local function spotFor(ctx, instance: any): Spot?
	local cached = ctx.Spots[instance]
	if cached then
		return cached
	end
	local cf, size
	if instance:IsA("Model") then
		cf, size = boundingBox(instance)
	elseif instance:IsA("BasePart") then
		cf, size = instance.CFrame, instance.Size
	else
		return nil
	end
	local ground = cf.Position - V(0, size.Y / 2, 0)
	local spot = { Instance = instance, Position = ground, CFrame = cf, Size = size, Radius = math.max(size.X, size.Z) / 2 + Config.LifeStory.ReachPadding }
	spot.Zone = zoneAt(ctx, ground)
	ctx.Spots[instance] = spot
	return spot
end

local function pointSpot(instance: any, position: Vector3, rotation: CFrame?, radius: number?): Spot
	return { Instance = instance, Position = position, Radius = radius or 8, CFrame = CFrame.new(position) * (rotation or CFrame.identity), Size = V(4, 4, 4) }
end

local function snapToSidewalk(ctx, point: Vector3): Vector3
	local best, bestDistance = point, math.huge
	for _, road in ctx.Roads do
		local a, b = road.A, road.B
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (b - a).Magnitude > 1 then
			local p0 = flat(point)
			local dir = (b - a).Unit
			local t = math.clamp((p0 - a):Dot(dir), 0, (b - a).Magnitude)
			local onRoad = a + dir * t
			local perp = V(-dir.Z, 0, dir.X)
			local side = if (p0 - onRoad):Dot(perp) >= 0 then 1 else -1
			local width = road.Width or 24
			local offset = if width == 24 then 13 else width / 2 + 3.5
			local p = onRoad + perp * side * offset
			local candidate = V(p.X, point.Y, p.Z)
			local distance = (candidate - point).Magnitude
			if distance < bestDistance then
				best, bestDistance = candidate, distance
			end
		end
	end
	return best
end

-- from = dónde está el jugador; home = su casa (zona "Home")
function E.resolve(ctx, placeId: string, options: { [string]: any }?, from: Vector3?, depth: number?): Spot?
	local place = Locations.Places[placeId]
	if not place or (depth or 0) > 4 then
		return nil
	end
	local spot = E._resolve(ctx, place, options, from or V(0, 0, 0), depth or 0)
	if not spot and place.Fallback then
		return E.resolve(ctx, place.Fallback, options, from, (depth or 0) + 1)
	end
	return spot
end

function E._resolve(ctx, place, options, from: Vector3, depth: number): Spot?
	local spot: Spot? = nil
	if place.Special == "Home" then
		spot = if ctx.Plot then spotFor(ctx, ctx.Plot) else nil
	elseif place.Special == "NearPlayer" then
		local look = ctx.PlayerLook or V(0, 0, -1)
		spot = pointSpot(nil, from + look * 9, lookAt(V(0, 0, 0), -look), 10)
	elseif place.Between then
		local a = E.resolve(ctx, place.Between[1], nil, from, depth + 1)
		local b = E.resolve(ctx, place.Between[2], nil, from, depth + 1)
		if a and b then
			local point = snapToSidewalk(ctx, a.Position:Lerp(b.Position, place.At or 0.5))
			local direction = flat(b.Position - a.Position)
			local rotation = if direction.Magnitude > 1 then lookAt(V(0, 0, 0), direction) else nil
			spot = pointSpot(b.Instance, V(point.X, math.min(a.Position.Y, b.Position.Y), point.Z), rotation, place.Radius or 16)
		end
	else
		local list = {}
		local source = if place.Model then ctx.ByModel[place.Model] elseif place.Tag then ctx.ByTag[place.Tag] else nil
		for _, instance in source or {} do
			local ok = true
			for name, value in place.Attribute or {} do
				if instance:GetAttribute(name) ~= value then
					ok = false
					break
				end
			end
			if ok then
				local s = spotFor(ctx, instance)
				if s then
					table.insert(list, s)
				end
			end
		end
		if #list == 0 then
			return nil
		end
		local zone = place.Zone or "Nearest"
		if zone == "FamilyHome" then
			local mine = {}
			for _, candidate in list do
				if ctx.FamilyHomeId ~= nil and candidate.Instance:GetAttribute("HomeId") == ctx.FamilyHomeId then
					table.insert(mine, candidate)
				end
			end
			list = mine
			if #list == 0 then
				return nil
			end
		elseif zone ~= "Nearest" and zone ~= "Home" then
			local inZone = {}
			for _, candidate in list do
				if candidate.Zone == zone then
					table.insert(inZone, candidate)
				end
			end
			list = if #inZone > 0 then inZone else list
		end
		local origin = from
		if zone == "Home" then
			origin = ctx.Home or from
		end
		local best, bestDistance = nil, math.huge
		for _, candidate in list do
			local distance = (candidate.Position - origin).Magnitude
			if distance < bestDistance then
				best, bestDistance = candidate, distance
			end
		end
		spot = best
		local index = (options and options.Index) or place.Index
		if spot and index then
			local group = {}
			for _, candidate in list do
				if candidate.Instance.Parent == spot.Instance.Parent then
					table.insert(group, candidate)
				end
			end
			local basis = spot.CFrame.Rotation
			table.sort(group, function(x, y)
				local px, py = basis:PointToObjectSpace(x.Position), basis:PointToObjectSpace(y.Position)
				if math.abs(px.X - py.X) > 0.5 then
					return px.X < py.X
				end
				return px.Z < py.Z
			end)
			spot = group[(index - 1) % #group + 1]
		end
		if spot and place.Child then
			local child = spot.Instance:FindFirstChild(place.Child, true)
			spot = if child then spotFor(ctx, child) else nil
		end
	end
	local offset = place.Offset
	if options and options.Offset then
		offset = (offset or V(0, 0, 0)) + options.Offset
	end
	if spot and offset then
		local rotation = spot.CFrame.Rotation
		spot = pointSpot(spot.Instance, spot.Position + rotation:VectorToWorldSpace(offset), rotation, place.Radius)
	end
	return spot
end

---------------------------------------------------------------------
-- 3. Personas: dónde están, cuánto miden, sitio libre
---------------------------------------------------------------------
local HEAD = 4.5 -- (escala 1) de los pies al centro de la cabeza
local ROOT_H = 3 -- de los pies al HumanoidRootPart (el pivote)

local function stageOf(quest: { [string]: any }): string
	local req = quest.Requires
	if type(req) == "table" and type(req.Stage) == "string" then
		return req.Stage
	end
	if type(req) == "table" and type(req.MinStage) == "string" then
		return req.MinStage
	end
	local age = quest.AgeRange
	if type(age) == "table" and type(age[1]) == "number" then
		if age[1] < 12 then
			return "Nino"
		elseif age[1] < 18 then
			return "Adolescente"
		elseif age[1] < 30 then
			return "AdultoJoven"
		end
		return "Adulto"
	end
	return "AdultoJoven"
end
E.stageOf = stageOf

local PLAYER_SCALE = { Bebe = 0.5, Nino = 0.65, Adolescente = 0.85 }

-- ¿Cabe una persona de pie aquí? (suelo debajo y nada sólido a la altura del cuerpo)
local function standsAt(ctx, feet: Vector3, scale: number): boolean
	local world = ctx.World
	for _, h in { 0.6, 1.5, 2.5, 3.5, 4.5, 5.1 } do
		if world:inside(feet + V(0, h * scale, 0), Geo.Solid, 0.1) then
			return false
		end
	end
	return true
end

-- El suelo bajo un punto (SceneService.groundAt) o el punto tal cual
function E.ground(ctx, position: Vector3): (Vector3, boolean)
	local g = ctx.World:groundAt(position)
	return g or position, g ~= nil
end

-- Un sitio libre con suelo cerca de `feet` (SafeSpot), donde se puede llegar andando: el suelo a menos
-- de 1,6 studs de la altura de `feet` (sin subirse a un muro, un banco o un coche). El mismo si vale.
local function walkableGround(ctx, p: Vector3): Vector3?
	-- (rayos desde poco por encima: primero desde la rodilla, luego desde más arriba)
	for _, from in { 1.6, 3.5 } do
		local g = ctx.World:groundAt(p, from, 6)
		if g and math.abs(g.Y - p.Y) <= 1.6 then
			return g
		end
	end
	return nil
end

function E.freeSpot(ctx, feet: Vector3, scale: number, prefer: Vector3?): Vector3
	local g = walkableGround(ctx, feet)
	if g and standsAt(ctx, g, scale) then
		return g
	end
	local base = if prefer and flat(prefer).Magnitude > 0.1 then math.atan2(prefer.Z, prefer.X) else 0
	for _, r in { 1, 2, 3, 4.5, 6, 8, 10, 13 } do
		for i = 0, 15 do
			local k = math.floor((i + 1) / 2) * (if i % 2 == 0 then 1 else -1)
			local a = base + k * math.pi / 8
			local q = walkableGround(ctx, feet + V(math.cos(a) * r, 0, math.sin(a) * r))
			if q and standsAt(ctx, q, scale) then
				return q
			end
		end
	end
	return g or (E.ground(ctx, feet + V(0, 0.5, 0)))
end

-- SceneService.feetAt: el suelo de ahí sin subirse a una mesa ni a un banco (con el código de antes,
-- E.Legacy, el rayo desde 3,5 studs sin más)
function E.feetAt(ctx, position: Vector3): Vector3
	local feet = ctx.World:groundAt(position, 4, 14) or position
	if not E.Legacy and feet.Y - position.Y > 1.6 then
		local low = ctx.World:groundAt(position, 1.6, 14)
		if low and math.abs(low.Y - position.Y) <= 1.6 then
			return low
		end
	end
	return feet
end

export type Person = { Id: string, Feet: Vector3, Facing: Vector3, Scale: number, Ground: boolean, Problem: string? }

function E.head(p: Person): Vector3
	return p.Feet + V(0, HEAD * p.Scale, 0)
end
function E.pivot(p: Person): CFrame
	local at = p.Feet + V(0, ROOT_H * p.Scale, 0)
	local f = flat(p.Facing)
	return if f.Magnitude > 0.01 then lookAt(at, at + f) else CFrame.new(at)
end

-- ¿Está bien de pie ahí? nil si sí; si no, qué le pasa (flotando, hundido, sin suelo, dentro de algo)
function E.footing(ctx, pos: Vector3, scale: number, sitting: boolean?): string?
	local world = ctx.World
	local knee = world:groundAt(pos, 1.6, 14) -- (el suelo justo bajo los pies)
	if knee and math.abs(knee.Y - pos.Y) <= E.Checks.FLOAT then
		if not sitting and not standsAt(ctx, pos, scale) then
			local what = world:inside(pos + V(0, 2.5 * scale, 0), Geo.Solid, 0.1) or world:inside(pos + V(0, 1 * scale, 0), Geo.Solid, 0.1) or world:inside(pos + V(0, 4 * scale, 0), Geo.Solid, 0.1)
			return "dentro de " .. (if what then what.Name else "algo")
		end
		return nil
	end
	if sitting then
		return nil -- (sentado: la silla manda)
	end
	if knee and pos.Y - knee.Y > E.Checks.FLOAT then
		return ("flotando %.1f studs"):format(pos.Y - knee.Y)
	end
	local high = world:groundAt(pos, 4, 14)
	if high and high.Y - pos.Y > E.Checks.FLOAT then
		return ("hundido %.1f studs"):format(high.Y - pos.Y)
	end
	if not knee and not high then
		return "sin suelo debajo"
	end
	return nil
end

-- Pone a los actores de un paso (SceneService.applySet + placement + spaced). me = el jugador.
function E.placeActors(ctx, specs: { any }?, me: Person, stage: string): { [string]: Person }
	local out: { [string]: Person } = {}
	local placed: { Vector3 } = {}
	local follow = 0
	for _, spec in specs or {} do
		if type(spec) ~= "table" or type(spec.Npc) ~= "string" or out[spec.Npc] then
			continue
		end
		local scale = Cast.scaleAt(spec.Npc, stage)
		local cf: CFrame? = nil
		if spec.Mode == "Follow" and spec.Place == nil then
			-- A tu lado (3 + n·2,5 a la derecha, 5 detrás)
			local base = E.pivot(me)
			local p = base:PointToWorldSpace(V(3 + follow * 2.5, -ROOT_H * me.Scale, 5))
			follow += 1
			local feet = E.ground(ctx, p)
			cf = lookAt(feet, feet + me.Facing)
		else
			local placeId = spec.Place or "CercaDeTi"
			local spot = E.resolve(ctx, placeId, { Index = spec.Index, Offset = spec.Offset }, me.Feet)
			if spot then
				local feet = E.feetAt(ctx, spot.Position)
				local rotation = spot.CFrame.Rotation
				local placeDef = Locations.Places[placeId]
				local want = spec.Look or (placeDef and placeDef.Look)
				local look: Vector3? = nil
				if want then
					look = flat(rotation:VectorToWorldSpace(want))
				elseif spot.Instance and spot.Instance:IsA("BasePart") then
					local tagged = false
					pcall(function()
						tagged = spot.Instance:HasTag("StorySpot")
					end)
					if tagged then
						look = flat(spot.Instance.CFrame.LookVector)
					end
				end
				if not look or look.Magnitude < 0.01 then
					look = flat(me.Feet - feet)
				end
				if look.Magnitude < 0.01 then
					look = flat(rotation.LookVector)
				end
				cf = lookAt(feet, feet + look)
			end
		end
		if not cf then
			continue
		end
		local pos = (cf :: CFrame).Position
		if spec.Mode ~= "Sit" then
			-- spaced: a 5 de ti como poco y a 3 de los demás
			local d = flat(pos - me.Feet)
			if d.Magnitude < 5 then
				local dir = if d.Magnitude > 0.2 then d.Unit else me.Facing
				pos = V(me.Feet.X, pos.Y, me.Feet.Z) + dir * 5
			end
			for _, other in placed do
				local f = flat(pos - other)
				if f.Magnitude < 3 then
					local side = if f.Magnitude > 0.2 then f.Unit else V(1, 0, 0)
					pos += side * (3 - f.Magnitude)
				end
			end
		end
		if spec.Mode ~= "Sit" and not E.Legacy then
			-- SceneService.standingSpot: apoyado en el suelo de donde le deja spaced y, si no cabe de
			-- pie, al hueco libre más cercano (a menos de 8 y sin subirse a nada de más de 1,6)
			local g = E.feetAt(ctx, pos)
			local feet = if g.Y - pos.Y <= 1.6 then g else pos
			if not standsAt(ctx, feet, 1) then
				local found = E.freeSpot(ctx, feet, 1)
				if (found - feet).Magnitude < 8 and math.abs(found.Y - feet.Y) <= 1.6 and standsAt(ctx, found, 1) then
					feet = found
				end
			end
			pos = feet
		end
		table.insert(placed, pos)
		local person: Person = { Id = spec.Npc, Feet = pos, Facing = (cf :: CFrame).LookVector, Scale = scale, Ground = true, Sit = spec.Mode == "Sit", Spec = spec }
		local problem = E.footing(ctx, pos, scale, spec.Mode == "Sit")
		person.Ground = problem ~= "sin suelo debajo"
		person.Problem = if problem then ("%s (en %s)"):format(problem, tostring(spec.Place or "tu lado")) else nil
		out[spec.Npc] = person
	end
	return out
end

---------------------------------------------------------------------
-- 4. La cámara: el ajuste de los clientes (CameraShots.fit) con rayos contra el mapa
---------------------------------------------------------------------
-- Lo que tapa: lo que se ve y no es diminuto (como CineCamera en Roblox)
local function blocks(info): boolean
	return Geo.Solid(info) and (info.Size.X >= 1 or info.Size.Y >= 1 or info.Size.Z >= 1)
end
E.blocks = blocks

-- La sonda de CameraShots.fit: rayos contra el mapa y los cuerpos de los personajes de la escena
function E.probe(ctx, people: { [string]: any }?): { [string]: any }
	local world = ctx.World
	local bodies = {}
	for _, p in people or {} do
		table.insert(bodies, { Head = p.Feet + V(0, HEAD * p.Scale, 0), Feet = p.Feet })
	end
	return {
		cast = function(origin: Vector3, direction: Vector3): number?
			local hit = world:raycast(origin, direction, blocks)
			return hit and hit.T
		end,
		bodies = bodies,
	}
end

-- El ajuste de la cámara a las paredes de los clientes. Con CameraShots.fit (el de ahora) se usa el de
-- verdad; sin él (código de antes) se imita lo que había: DialogueUI acercaba la cámara a la pared con
-- un rayo que solo veía piezas con CanCollide (CineCamera.clamp) y HappeningClient no la ajustaba.
function E.fit(ctx, cf: CFrame, focus: Vector3, opts: { [string]: any }): (CFrame, number?)
	if type(CameraShots.fit) == "function" and not E.Legacy then
		return CameraShots.fit(cf, focus, E.probe(ctx, opts.People), opts)
	end
	if opts.Legacy == "Happening" then
		return cf
	end
	if opts.Interior then
		cf = CFrame.new(focus + (cf.Position - focus) * 0.7) * cf.Rotation
	end
	local offset = cf.Position - focus
	if offset.Magnitude < 0.05 then
		return cf
	end
	local hit = ctx.World:raycast(focus, offset, Geo.Collide)
	if hit then
		return CFrame.new(focus + offset.Unit * math.max(0.5, hit.T - 0.5)) * cf.Rotation
	end
	return cf
end

-- ¿Hay algo del mapa entre a y b? (devuelve la pieza)
function E.blocked(ctx, a: Vector3, b: Vector3, stopShort: number?): any
	local d = b - a
	local len = d.Magnitude
	local short = stopShort or 0
	if len <= short + 0.05 then
		return nil
	end
	local hit = ctx.World:raycast(a, d.Unit * (len - short), blocks)
	return hit and hit.Part
end

---------------------------------------------------------------------
-- 5. Comprobar un plano
---------------------------------------------------------------------
-- ¿Sale el punto en pantalla? (cámara cf, campo de visión vertical fov)
function E.inFrame(cf: CFrame, point: Vector3, fov: number): (boolean, number, number)
	local rel = cf:PointToObjectSpace(point)
	local depth = -rel.Z
	if depth <= 0.2 then
		return false, 99, 99
	end
	local ty = math.tan(math.rad(fov) / 2)
	local x = rel.X / (depth * ty * E.Checks.ASPECT)
	local y = rel.Y / (depth * ty)
	return math.abs(x) <= E.Checks.FRAME and math.abs(y) <= E.Checks.FRAME, x, y
end

-- El cuerpo de alguien como esferas (las mismas que usa CameraShots.fit: piernas, tronco y cabeza)
local function spheresOf(p: Person): { { any } }
	return CameraShots.bodySpheres({ Head = E.head(p), Feet = p.Feet })
end

-- ¿Está el punto dentro del cuerpo de alguien?
local function insidePerson(people: { [string]: Person }, point: Vector3): string?
	for id, p in people do
		for _, sphere in spheresOf(p) do
			if (point - sphere[1]).Magnitude < sphere[2] then
				return id
			end
		end
	end
	return nil
end

-- ¿Se cruza alguien (que no sea `except`) entre a y b? (la cara de quien habla tapada por otro). Quien
-- está pegado a su cara (a menos de 1 stud de ella en esa línea) sale con él: no cuenta.
local function personBetween(people: { [string]: Person }, a: Vector3, b: Vector3, except: string): string?
	local ab = b - a
	local length = ab.Magnitude
	if length < 1.1 then
		return nil
	end
	for id, p in people do
		if id == except then
			continue
		end
		for _, sphere in spheresOf(p) do
			local t = math.clamp((sphere[1] - a):Dot(ab) / (length * length), 0, 1)
			if (a + ab * t - sphere[1]).Magnitude < sphere[2] and (1 - t) * length > 1 then
				return id
			end
		end
	end
	return nil
end
E.personBetween = personBetween

-- Un plano ya resuelto: { Cams = { CFrame… } (muestras del movimiento), Fov, Subjects = { id… }, … }
-- people = todos (con "Yo"). Devuelve la lista de problemas { Kind, Detail }.
function E.checkShot(ctx, shot: { [string]: any }, people: { [string]: Person }): { { Kind: string, Detail: string } }
	local problems = {}
	local seen = {}
	local function add(kind: string, detail: string)
		if not seen[kind] then
			seen[kind] = true
			table.insert(problems, { Kind = kind, Detail = detail })
		end
	end
	local world = ctx.World
	local cams = shot.Cams
	local fov = shot.Fov or CameraShots.DEFAULT_FOV
	for i, cf in cams do
		local at = cf.Position
		local inside = world:inside(at, blocks, 0.05)
		if inside then
			add("CamaraDentro", ("dentro de «%s» (%s)"):format(inside.Name, inside.Path))
		end
		local who = insidePerson(people, at)
		if who then
			add("CamaraEnPersonaje", "dentro de " .. who)
		end
		-- Bajo tierra: por debajo del suelo donde están los personajes
		local lowest = math.huge
		for _, id in shot.Subjects do
			local p = people[id]
			if p then
				lowest = math.min(lowest, p.Feet.Y)
			end
		end
		if lowest < math.huge and at.Y < lowest - 0.3 then
			add("BajoTierra", ("%.1f studs por debajo de los pies"):format(lowest - at.Y))
		end
		if i > 1 then
			local part = E.blocked(ctx, cams[i - 1].Position, at, 0)
			if part then
				add("Atraviesa", ("el movimiento cruza «%s» (%s)"):format(part.Name, part.Path))
			end
		end
	end
	-- Sujetos: al principio, a la mitad y al final
	local sample = { cams[1], cams[math.max(1, math.ceil(#cams / 2))], cams[#cams] }
	for _, id in shot.Subjects do
		local p = people[id]
		if not p then
			continue
		end
		local head = E.head(p)
		for k, cf in sample do
			local distance = (head - cf.Position).Magnitude
			if distance > E.Checks.FAR then
				add("Lejos", ("%s a %.0f studs"):format(id, distance))
			elseif distance < E.Checks.NEAR then
				add("Pegada", ("a %.1f studs de la cara de %s"):format(distance, id))
			end
			local ok, x, y = E.inFrame(cf, head, fov)
			-- (en un pan/tilt el sujeto puede entrar a mitad: solo cuenta el final)
			if not ok and (k == 3 or not shot.Moving) then
				add("FueraDeCuadro", ("%s fuera de cuadro (x=%.2f, y=%.2f)"):format(id, x, y))
			end
			if ok then
				local part = E.blocked(ctx, cf.Position, head, 0.5)
				if part then
					add("Tapado", ("%s tapado por «%s» (%s)"):format(id, part.Name, part.Path))
				else
					local other = personBetween(people, cf.Position, head, id)
					if other then
						add("TapadoPorPersona", ("la cara de %s queda detrás de %s"):format(id, other))
					end
				end
			end
		end
	end
	return problems
end

---------------------------------------------------------------------
-- 6. Las escenas: cada paso con conversación o escena del motor
---------------------------------------------------------------------
local function dialogueOf(quest: { [string]: any }, name: any): { any }?
	if type(name) == "table" then
		return name.Lines or name
	end
	if type(name) ~= "string" then
		return nil
	end
	local d = quest.Dialogues and quest.Dialogues[name]
	if d == nil then
		return nil
	end
	return if type(d) == "table" then (d.Lines or d) else nil
end

-- Todas las líneas en orden (las respuestas de las preguntas, detrás)
local function flatten(lines: { any }?, out: { any }?): { any }
	local list = out or {}
	for _, line in lines or {} do
		if type(line) == "table" then
			if line.T or line.Text then
				table.insert(list, line)
			end
			for _, option in line.Options or {} do
				flatten(option.Then, list)
			end
		end
	end
	return list
end

-- Los ids de un plano con nombre ("Hombro:Yo>Nico" → { "Yo", "Nico" })
local function whoOf(spec: string): (string?, { string })
	local parsed = StageDirector.parseShot(spec)
	if parsed then
		return parsed.Kind, parsed.Who
	end
	local kind, args = CameraShots.parsePreset(spec)
	return kind, args or {}
end

-- A quién tiene que enseñar el plano (CameraShots.subjects; los que están en la escena)
local function subjectsOf(spec: string, people: { [string]: Person }): { string }
	local out = {}
	for _, id in CameraShots.subjects(spec) do
		id = if id == "Player" then "Yo" else id
		if people[id] then
			table.insert(out, id)
		end
	end
	return out
end
E.subjectsOf = subjectsOf

-- La pareja de un plano de hombro o de dos como { cabeza A, cabeza B } (CameraShots.pair)
function E.lineOf(spec: string, people: { [string]: Person }): { Vector3 }?
	local pair = if CameraShots.pair then CameraShots.pair(spec) else nil
	if not pair then
		return nil
	end
	local a = people[if pair[1] == "Player" then "Yo" else pair[1]]
	local b = people[if pair[2] == "Player" then "Yo" else pair[2]]
	return if a and b then { E.head(a), E.head(b) } else nil
end

-- Lado de la cámara respecto a la línea entre dos (regla de los 180°): +1 / -1 (0 = encima de la línea)
local function sideOf(a: Vector3, b: Vector3, cam: Vector3): number
	local ab = flat(b - a)
	local ac = flat(cam - a)
	local cross = ab.X * ac.Z - ab.Z * ac.X
	if math.abs(cross) < 0.5 * ab.Magnitude then
		return 0
	end
	return if cross > 0 then 1 else -1
end

-- Revisa la secuencia de planos de una escena: los 180° entre planos seguidos de la misma pareja
local function axisChecks(shots: { any }, people: { [string]: Person })
	local last: { [string]: { Side: number, Index: number } } = {}
	local prevPair: string? = nil
	for i, shot in shots do
		local kind, who = whoOf(shot.Spec or "")
		if (kind == "Hombro" or kind == "DosPlanos") and who[1] and who[2] then
			local a, b = if who[1] == "Player" then "Yo" else who[1], if who[2] == "Player" then "Yo" else who[2]
			if a > b then
				a, b = b, a
			end
			local pa, pb = people[a], people[b]
			if pa and pb then
				local pair = a .. "|" .. b
				local side = sideOf(pa.Feet, pb.Feet, shot.Cams[1].Position)
				local before = last[pair]
				if before and prevPair == pair and side ~= 0 and before.Side ~= 0 and side ~= before.Side then
					table.insert(shot.Problems, { Kind = "Salta180", Detail = ("la cámara cruza la línea %s–%s respecto al plano anterior (%s)"):format(a, b, shots[before.Index].Spec) })
				end
				last[pair] = { Side = side, Index = i }
				prevPair = pair
			end
		elseif kind ~= "Reaccion" and kind ~= "PrimerPlano" and kind ~= "PPP" then
			prevPair = nil -- (un plano de otra cosa corta la secuencia)
		end
	end
end

-- Muestras de un plano de cámara que va de a a b (posición y mirada)
local function samples(a: CFrame, b: CFrame, n: number): { CFrame }
	if (a.Position - b.Position).Magnitude < 0.05 and a.LookVector:Dot(b.LookVector) > 0.9999 then
		return { a }
	end
	local out = {}
	for i = 0, n do
		local u = CameraShots.ease(nil, i / n)
		local p = a.Position:Lerp(b.Position, u)
		local look = (a.LookVector:Lerp(b.LookVector, u))
		table.insert(out, lookAt(p, p + (if look.Magnitude > 1e-3 then look.Unit else a.LookVector)))
	end
	return out
end

-- El plano de conversación como lo pone DialogueUI.frameShot (con el ajuste a las paredes)
function E.dialogueShot(ctx, spec: string, people: { [string]: Person }, from: string?): { [string]: any }?
	local heads: { [string]: Vector3 } = {}
	local me = people.Yo
	for id, p in people do
		if (E.head(p) - E.head(me)).Magnitude < 60 then
			heads[id] = E.head(p)
		end
	end
	local ok, startCf, goalCf, seconds, focus = pcall(StageDirector.camera, spec, heads, CameraShots, { From = from })
	if not ok or not startCf or not goalCf then
		return nil
	end
	local center: Vector3 = focus or heads.Yo
	local interior = me.Feet.Y > 3000
	local raw = { startCf, goalCf }
	local subjects = subjectsOf(spec, people)
	local keep = {}
	for _, id in subjects do
		table.insert(keep, heads[id])
	end
	local line = E.lineOf(spec, people)
	local a, choice = E.fit(ctx, startCf, center, { Interior = interior, Legacy = "Dialogue", People = people, Keep = keep, Line = line })
	local b = E.fit(ctx, goalCf, center, { Interior = interior, Legacy = "Dialogue", People = people, Keep = keep, Line = line, Choice = choice })
	-- (DialogueUI: si el dolly atravesaría algo, el plano se queda quieto)
	if not E.Legacy and CameraShots.clearPath and not CameraShots.clearPath(a.Position, b.Position, E.probe(ctx, people)) then
		a = b
	end
	local moving = seconds ~= nil and seconds > 0.05
	return {
		Spec = spec,
		Cams = if moving then samples(a, b, 6) else { b },
		Raw = raw,
		Focus = center,
		Fov = CameraShots.DEFAULT_FOV, -- (DialogueUI no cambia el campo de visión)
		Moving = moving,
		Subjects = subjects,
	}
end

-- Las líneas de una conversación preparadas como en DialogueService.lineFor
local function prepared(lines: { any }): { { [string]: any } }
	local out = {}
	for _, raw in lines do
		local text = raw.T or raw.Text or ""
		local clean, direction = StageDirector.direction(text)
		local narrator = raw.S == "Narrador" or raw.S == nil
		table.insert(out, {
			Text = clean,
			Me = raw.S == "Yo",
			Narrator = narrator,
			Id = if narrator then nil else raw.S,
			Direction = direction,
			To = raw.To,
			Shot = if type(raw.Shot) == "string" and StageDirector.parseShot(raw.Shot) then raw.Shot else nil,
			Raw = raw,
		})
	end
	return out
end

-- La secuencia de planos de una conversación (DialogueUI: situación, plano por línea, reacción)
function E.dialogueShots(ctx, lines: { any }, people: { [string]: Person }): { any }
	local state = StageDirector.newState()
	local shots = {}
	for _, line in prepared(flatten(lines)) do
		local spec = StageDirector.shotFor(state, line)
		if not spec then
			continue
		end
		local general = StageDirector.establish(state)
		if general then
			local s = E.dialogueShot(ctx, general, people, line.Id)
			if s then
				s.Line = line.Text
				table.insert(shots, s)
			end
		end
		local s = E.dialogueShot(ctx, spec, people, line.Id)
		if s then
			s.Line = line.Text
			s.Speaker = line.Id or (if line.Me then "Yo" else nil)
			table.insert(shots, s)
		end
		local reaction = StageDirector.reactionFor(line)
		if reaction then
			local r = E.dialogueShot(ctx, reaction, people, line.Id)
			if r then
				r.Line = "(reacción) " .. line.Text
				table.insert(shots, r)
			end
		end
	end
	return shots
end

---------------------------------------------------------------------
-- 7. Escenas del motor (Happenings): Sequencer + CameraShots, actores con sus Use/Spawn/Enter/Move
---------------------------------------------------------------------
local WALK, RUN = 10, 18

-- Dónde está cada actor de la escena en el segundo t (a la vista del guion: Spawn/Enter/Use/Move/Exit
-- y miradas a quien habla)
local function happeningPeople(ctx, timeline, base: { [string]: Person }, anchors: { [string]: CFrame }, me: Person, stage: string, t: number): { [string]: Person }
	local people: { [string]: Person } = { Yo = me }
	local keys: { [string]: Person } = {}
	local function point(spec: any): Vector3?
		if type(spec) == "string" then
			spec = { spec }
		end
		if type(spec) ~= "table" then
			return nil
		end
		local name = spec[1]
		local cf: CFrame? = nil
		if name == "Player" then
			cf = E.pivot(me)
		elseif type(name) == "string" and name:sub(1, 6) == "Actor:" then
			local p = keys[name:sub(7)]
			cf = p and E.pivot(p)
		else
			cf = anchors[name]
		end
		if not cf then
			return nil
		end
		local offset = if typeof(spec[2]) == "Vector3" then spec[2] else V(0, 0, 0)
		return if spec[3] then cf:PointToWorldSpace(offset) else cf.Position + offset
	end
	local function mark(spec: { [string]: any }): Vector3
		local b = anchors[spec.Anchor or ""] or E.pivot(me)
		return b.Position + (if typeof(spec.Offset) == "Vector3" then spec.Offset else V(0, 0, 0))
	end
	local function newPerson(key: string, npc: string?, feet: Vector3, face: Vector3?): Person
		local f = if face then flat(face - feet) else flat(me.Feet - feet)
		local scale = Cast.scaleAt(npc or key, stage)
		local g = E.ground(ctx, feet + V(0, 0.5, 0))
		return { Id = key, Feet = g, Facing = if f.Magnitude > 0.01 then f.Unit else V(0, 0, -1), Scale = scale, Ground = true }
	end
	local walks: { [string]: any } = {}
	for _, e in timeline.Events do
		if e.At > t + 1e-6 then
			break
		end
		if e.Track ~= "Actors" then
			continue
		end
		local d = e.Data
		if not Sequencer.passes(d, {}) then
			continue
		end
		if type(d.Use) == "table" and d.Use.Key then
			local key = d.Use.Key
			local own = base[d.Use.Npc or key] or base[key]
			if own then
				keys[key] = table.clone(own)
				keys[key].Id = key
			else
				keys[key] = newPerson(key, d.Use.Npc, mark(d.Use), nil)
			end
		elseif type(d.Spawn) == "table" and d.Spawn.Key then
			local s = d.Spawn
			keys[s.Key] = newPerson(s.Key, s.Npc, mark(s), if s.Face then point(s.Face) else nil)
		elseif type(d.Enter) == "table" and d.Enter.Key then
			local s = d.Enter
			local goal = (if s.To ~= nil then point(s.To) else nil) or mark(s)
			local from = if s.Walk ~= false then point(s.From) else nil
			if from then
				keys[s.Key] = newPerson(s.Key, s.Npc, from, goal)
				walks[s.Key] = { From = from, To = goal, At = e.At, Speed = if s.Run then RUN else WALK }
			else
				keys[s.Key] = newPerson(s.Key, s.Npc, goal, nil)
			end
		elseif type(d.Move) == "table" and d.Move.Key and keys[d.Move.Key] then
			local goal = point(d.Move.To or d.Move.At)
			if goal then
				walks[d.Move.Key] = { From = keys[d.Move.Key].Feet, To = goal, At = e.At, Speed = if d.Move.Run then RUN else WALK }
			end
		elseif type(d.Exit) == "table" and d.Exit.Key then
			keys[d.Exit.Key] = nil
			walks[d.Exit.Key] = nil
		elseif type(d.Face) == "table" and d.Face.Key and keys[d.Face.Key] then
			local target = point(d.Face.At or d.Face.To)
			local p = keys[d.Face.Key]
			if target and flat(target - p.Feet).Magnitude > 0.1 then
				p.Facing = flat(target - p.Feet).Unit
			end
		end
	end
	-- Andando: dónde va ahora
	for key, w in walks do
		local p = keys[key]
		if p then
			local distance = (w.To - w.From).Magnitude
			local k = if distance > 0.01 then math.clamp((t - w.At) * w.Speed / distance, 0, 1) else 1
			local feet = E.ground(ctx, w.From:Lerp(w.To, k) + V(0, 0.5, 0))
			p.Feet = feet
			local dir = flat(w.To - w.From)
			if dir.Magnitude > 0.1 then
				p.Facing = dir.Unit
			end
		end
	end
	-- Quien habla ahora: todos le miran (Look = "Speaker")
	local speaker: string? = nil
	for _, line in (timeline.Def.Tracks or {}).Dialogue or {} do
		if Sequencer.passes(line, {}) and line.At <= t + 1e-6 and t <= line.At + (line.Duration or 2) + (line.After or 0) + 0.5 then
			speaker = line.S
		end
	end
	if speaker and timeline.Def.Look ~= false then
		local sp = if speaker == "Yo" then me else keys[speaker]
		if sp then
			for key, p in keys do
				if key ~= speaker and not walks[key] then
					local dir = flat(sp.Feet - p.Feet)
					if dir.Magnitude > 0.1 then
						p.Facing = dir.Unit
					end
				end
			end
		end
	end
	for key, p in keys do
		people[key] = p
	end
	return people
end

-- Resolver de anclas de la escena (HappeningService.resolveAnchors)
local function happeningAnchors(ctx, def, me: Person): { [string]: CFrame }
	local anchors: { [string]: CFrame } = {}
	for name, anchor in def.Anchors or {} do
		local cf: CFrame? = nil
		if type(anchor) == "table" then
			local spot = E.resolve(ctx, anchor.Place, { Offset = anchor.Offset }, me.Feet)
			cf = spot and spot.CFrame
			if cf and spot.Size == V(4, 4, 4) then
				cf = CFrame.new(spot.Position) * spot.CFrame.Rotation
			elseif spot then
				cf = CFrame.new(spot.Position) * spot.CFrame.Rotation
			end
			if cf and anchor.Ground then
				cf = CFrame.new((E.ground(ctx, cf.Position))) * cf.Rotation
			end
		elseif anchor == "Player" then
			cf = E.pivot(me)
		elseif type(anchor) == "string" then
			local kind, value = anchor:match("^(%a+):(.+)$")
			if kind == "Place" then
				local spot = E.resolve(ctx, value, nil, me.Feet)
				cf = spot and (CFrame.new(spot.Position) * spot.CFrame.Rotation)
			elseif kind == "Zone" then
				for _, z in ctx.Zones do
					if z.Name == value then
						cf = CFrame.new(z.Center)
					end
				end
			end
		end
		anchors[name] = cf or E.pivot(me)
		if anchor == "Rift" then
			anchors[name] = CFrame.new(me.Feet + V(-160, 300, -160))
		end
	end
	return anchors
end

-- Los planos de una escena del motor, cada uno en el instante en que empieza
function E.happeningShots(ctx, id: string, base: { [string]: Person }, me: Person, stage: string): ({ any }?, string?)
	local def = HappeningIndex.get(id)
	if not def then
		return nil, "no existe la escena " .. tostring(id)
	end
	if Sequencer.isLight(def) then
		return {}, nil
	end
	local resolved = Sequencer.resolve(def, function()
		return false
	end)
	local ok, timeline = pcall(Sequencer.compile, id, def, resolved)
	if not ok then
		return nil, tostring(timeline)
	end
	local anchors = happeningAnchors(ctx, timeline.Def, me)
	local shots = {}
	local list = {}
	for _, s in timeline.Shots do
		if Sequencer.passes(s, {}) then
			table.insert(list, s)
		end
	end
	for index, shot in list do
		local at = shot.At or 0
		local people = happeningPeople(ctx, timeline, base, anchors, me, stage, at + 0.05)
		local function resolver(name: string): CFrame?
			if name == "Player" then
				return E.pivot(me)
			end
			local kind, value = name:match("^(%a+):(.+)$")
			if kind == "Actor" then
				local p = people[value]
				return if p then E.pivot(p) else E.pivot(me)
			elseif kind == "Fx" then
				return nil
			end
			return anchors[name]
		end
		local resolve = CameraShots.composite(resolver)
		-- (el plano dura hasta el siguiente)
		local duration = shot.Duration or 1
		local nextShot = list[index + 1]
		if nextShot and (nextShot.At or 0) < at + duration then
			duration = math.max(0.05, (nextShot.At or 0) - at)
		end
		local uEnd = math.clamp(duration / math.max(shot.Duration or 1, 0.01), 0, 1)
		local spec = shot.Shot
		local subjects: { string } = {}
		if type(spec) == "string" then
			subjects = subjectsOf(spec, people)
		elseif type(shot.Look) == "table" and type(shot.Look[1]) == "string" then
			local name = shot.Look[1]
			local key = if name == "Player" then "Yo" else name:match("^Actor:(.+)$")
			if key and people[key] then
				subjects = { key }
			end
		end
		local keep = {}
		for _, id in subjects do
			table.insert(keep, E.head(people[id]))
		end
		local cams = {}
		local n = if CameraShots.kind(shot) == "Fixed" then 0 else 16
		local missing = false
		local choice: number? = nil
		for i = 0, n do
			local u = if n == 0 then 0 else uEnd * i / n
			local cf = CameraShots.base(shot, u, resolve)
			if not cf then
				missing = true
				break
			end
			local focus = CameraShots.point(resolve, shot.Look)
			if not focus and shot.Orbit then
				local o = resolve(shot.Orbit)
				focus = o and o.Position
			end
			if focus then
				cf, choice = E.fit(ctx, cf, focus, { Legacy = "Happening", People = people, Choice = choice, Keep = keep, Line = if type(spec) == "string" then E.lineOf(spec, people) else nil })
			end
			table.insert(cams, cf)
		end
		if missing or #cams == 0 then
			continue
		end
		local moving = false
		for i = 2, #cams do
			if (cams[i].Position - cams[1].Position).Magnitude > 0.05 or cams[i].LookVector:Dot(cams[1].LookVector) < 0.999 then
				moving = true
			end
		end
		table.insert(shots, {
			Spec = if type(spec) == "string" then spec else (CameraShots.kind(shot) or "?"),
			Cams = cams,
			Fov = CameraShots.fov(shot, 0) or CameraShots.DEFAULT_FOV,
			Moving = moving,
			Subjects = subjects,
			At = at,
			People = people,
			Line = nil,
		})
	end
	return shots, nil
end

---------------------------------------------------------------------
-- 8. Recorrer las misiones
---------------------------------------------------------------------
export type Scene = { [string]: any }

-- Lista de escenas a revisar: { Id, Quest, Step, Kind = "Conversacion"|"Cinematica", … }
function E.collect(ctx, filter: ((string) -> boolean)?): { Scene }
	local scenes: { Scene } = {}
	local ids = {}
	for id in Quests do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, questId in ids do
		if filter and not filter(questId) then
			continue
		end
		local quest = Quests[questId]
		local stage = stageOf(quest)
		local scale = PLAYER_SCALE[stage] or 1
		-- El jugador empieza en su casa familiar (o en el centro)
		local homeSpot = E.resolve(ctx, "CasaFamiliar", nil, V(0, 0, 0)) or E.resolve(ctx, "Home", nil, V(0, 0, 0))
		ctx.Home = homeSpot and homeSpot.Position
		local me: Person = { Id = "Yo", Feet = (homeSpot and E.ground(ctx, homeSpot.Position + V(0, 0.5, 0))) or V(0, 3, 0), Facing = V(0, 0, -1), Scale = scale, Ground = true }
		local lastActors = quest.Actors
		local stepCount = 0
		local function moveTo(target: Vector3, inside: boolean?)
			local prev = me.Feet
			local feet = E.freeSpot(ctx, target, scale, flat(prev - target))
			local dir = flat(feet - prev)
			me = { Id = "Yo", Feet = feet, Facing = if dir.Magnitude > 0.5 then dir.Unit else me.Facing, Scale = scale, Ground = true }
			ctx.PlayerLook = me.Facing
		end
		local function reach(placeId: string, teleport: { [string]: any }?)
			local spot = E.resolve(ctx, placeId, if teleport then { Index = teleport.Index, Offset = teleport.Offset } else nil, me.Feet)
			if not spot then
				return
			end
			local place = Locations.Places[placeId] or {}
			local target = spot.Position
			-- Un edificio entero: llegas a su borde (Radius), no a su centro
			if not teleport and not place.Inside and (spot.Size.X > 14 or spot.Size.Z > 14) then
				local away = flat(me.Feet - spot.Position)
				local r = math.max(spot.Size.X, spot.Size.Z) / 2 + 4
				target = spot.Position + (if away.Magnitude > 1 then away.Unit else V(0, 0, 1)) * r
			end
			moveTo(target)
		end
		local function scene(kind: string, stepIndex: number, step: { [string]: any }, extra: { [string]: any })
			-- LifeStoryService.gatherForStep: si quien lleva la escena está lejos, te acerca a él
			if not E.Legacy and not step.Teleport and step.Type ~= "Talk" and step.Type ~= "Choice" then
				local speakers: { string } = {}
				if extra.Happening then
					local def = HappeningIndex.get(extra.Happening)
					for _, line in ((def and def.Tracks) or {}).Dialogue or {} do
						if type(line) == "table" and type(line.S) == "string" and line.S ~= "Yo" and not table.find(speakers, line.S) then
							table.insert(speakers, line.S)
						end
					end
				else
					speakers = StageDirector.castOf(extra.Lines)
				end
				local lead = ActorStaging.lead(step.Actors, speakers)
				local spot = lead and E.resolve(ctx, lead.Place, { Index = lead.Index, Offset = lead.Offset }, me.Feet)
				local target = spot and ActorStaging.gatherSpot(me.Feet, spot.Position, if extra.Happening then "Cinematic" else "Scene")
				if target then
					moveTo(target)
				end
			end
			local actors = E.placeActors(ctx, step.Actors or lastActors, me, stage)
			local item: Scene = {
				Quest = questId,
				Step = stepIndex,
				Kind = kind,
				Stage = stage,
				Name = extra.Name,
				Player = me,
				Actors = actors,
				Lines = extra.Lines,
				Happening = extra.Happening,
				Npc = extra.Npc,
			}
			item.Id = ("%s#%d %s"):format(questId, stepIndex, extra.Name or kind)
			table.insert(scenes, item)
		end
		-- La misión se acepta donde se ofrece (Offer.Place): ahí empieza el jugador
		local offer = quest.Offer
		if type(offer) == "table" and type(offer.Place) == "string" and Locations.Places[offer.Place] then
			reach(offer.Place)
		end
		local function walk(steps: { any }?, groupActors: { any }?)
			for _, step in steps or {} do
				if type(step) ~= "table" then
					continue
				end
				stepCount += 1
				local index = stepCount
				if step.Actors then
					lastActors = step.Actors
				elseif groupActors then
					lastActors = groupActors
				end
				if step.Teleport then
					local t = step.Teleport
					reach(if type(t) == "table" then t.Place else t, if type(t) == "table" then t else {})
				end
				local kind = step.Type
				if kind == "Reach" or kind == "Class" or kind == "Fight" or kind == "Escape" then
					if type(step.Place) == "string" and Locations.Places[step.Place] and not step.Teleport then
						reach(step.Place)
					end
				end
				if kind == "Talk" or kind == "Chase" then
					-- Vas hasta quien te habla (5 studs delante)
					local actors = E.placeActors(ctx, lastActors, me, stage)
					local who = actors[step.Npc]
					if who then
						local away = flat(me.Feet - who.Feet)
						local dir = if away.Magnitude > 0.5 then away.Unit else who.Facing
						moveTo(who.Feet + dir * 5)
					end
				end
				local lines = dialogueOf(quest, step.Dialogue)
				if (kind == "Scene" or kind == "Talk") and lines and step.Stage == nil then
					scene("Conversacion", index, step, { Name = tostring(step.Dialogue), Lines = lines, Npc = step.Npc })
				end
				if kind == "Scene" and step.Stage then
					scene("Cinematica", index, step, { Name = step.Stage, Happening = step.Stage })
				end
				if kind == "Cinematic" and type(step.Id) == "string" and HappeningIndex.has(step.Id) then
					scene("Cinematica", index, step, { Name = step.Id, Happening = step.Id })
				end
				if kind == "Choice" then
					for _, option in step.Options or {} do
						local optionLines = dialogueOf(quest, option.Dialogue)
						if optionLines and option.Npc then
							local actors = E.placeActors(ctx, lastActors, me, stage)
							local who = actors[option.Npc]
							local saved = me
							if who then
								local away = flat(me.Feet - who.Feet)
								moveTo(who.Feet + (if away.Magnitude > 0.5 then away.Unit else who.Facing) * 5)
							end
							scene("Conversacion", index, step, { Name = tostring(option.Dialogue), Lines = optionLines, Npc = option.Npc })
							me = saved
						end
					end
				end
				if kind == "Group" then
					walk(step.Steps, step.Actors or groupActors)
				end
			end
		end
		walk(quest.Steps, nil)
	end
	return scenes
end

-- Pone en escena y revisa una escena: devuelve { Shots, Problems (de la escena), Count }
function E.audit(ctx, scene: Scene): Scene
	local people: { [string]: Person } = { Yo = scene.Player }
	for id, p in scene.Actors do
		people[id] = p
	end
	scene.Problems = {}
	-- Actores mal puestos (los que salen en la escena)
	for id, p in scene.Actors do
		if p.Problem then
			-- (sin suelo de piezas debajo: el monte y las playas son de terreno, que Lune no lee; se avisa
			-- aparte y no cuenta como fallo)
			local kind = if p.Ground == false then "Terreno" else "Actor"
			table.insert(scene.Problems, { Kind = kind, Detail = id .. ": " .. p.Problem })
		end
	end
	local shots
	if scene.Kind == "Conversacion" then
		-- Quien está lejos se acerca (StageDirector.approach) antes de que empiece
		local distances = {}
		for _, id in StageDirector.castOf(scene.Lines) do
			local p = people[id]
			if p then
				distances[id] = (p.Feet - scene.Player.Feet).Magnitude
			end
		end
		for _, id in StageDirector.approach(distances) do
			local p = table.clone(people[id])
			local goal = StageDirector.approachSpot(p.Feet, scene.Player.Feet)
			p.Feet = E.ground(ctx, goal + V(0, 3, 0) - V(0, 2.5, 0))
			local toMe = flat(scene.Player.Feet - p.Feet)
			p.Facing = if toMe.Magnitude > 0.5 then toMe.Unit else p.Facing
			people[id] = p
		end
		-- Quien habla y con quien hablas se gira hacia ti (TalkingTo)
		for _, id in StageDirector.castOf(scene.Lines) do
			local p = people[id]
			if p and not p.Sit then
				local toMe = flat(scene.Player.Feet - p.Feet)
				if toMe.Magnitude > 0.5 and toMe.Magnitude < 30 then
					p = table.clone(p)
					p.Facing = toMe.Unit
					people[id] = p
				end
			end
		end
		-- El jugador mira a quien habla primero
		local first = StageDirector.castOf(scene.Lines)[1]
		if first and people[first] then
			local me = table.clone(scene.Player)
			local d = flat(people[first].Feet - me.Feet)
			if d.Magnitude > 0.5 then
				me.Facing = d.Unit
			end
			people.Yo = me
		end
		shots = E.dialogueShots(ctx, scene.Lines, people)
		for _, shot in shots do
			shot.People = people
		end
	else
		local list, why = E.happeningShots(ctx, scene.Happening, scene.Actors, scene.Player, scene.Stage)
		if not list then
			table.insert(scene.Problems, { Kind = "Escena", Detail = why or "?" })
			list = {}
		end
		shots = list
	end
	for _, shot in shots do
		shot.Problems = E.checkShot(ctx, shot, shot.People or people)
	end
	axisChecks(shots, people)
	scene.People = people
	scene.Shots = shots
	return scene
end

return E
