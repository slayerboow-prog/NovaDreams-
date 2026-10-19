-- PlanetService (servidor): bajar a los planetas desde el espacio y volver, sin pantalla de carga
-- (docs/planetas.md). Ahora mismo, Tefra (Saga 2, episodio 1) entero; los otros seis se ven en el
-- espacio y dicen «próximamente».
--
--   * Remoto "Planet" (cliente → servidor):
--       "Status"            ¿a qué planetas puedes bajar? (responde "Status" { [id] = estado })
--       "Near" (id)         te acercas a un planeta: se empieza a construir su superficie
--       "Descend"           has llegado al fondo de la entrada en la atmósfera: el SERVIDOR comprueba
--                           que tu nave está de verdad ahí (AirCombatService.status), que el planeta
--                           está abierto para ti (SpaceService.planetStatus: Saga 1 o tester, orden de
--                           la saga) y calcula a dónde va (shared/Cosmos/PlanetEntry.toSurface) →
--                           AirCombatService.relocate (la nave sigue volando, con su velocidad)
--       "Ascend"            has subido hasta el techo del planeta → de vuelta al espacio (toSpace)
--     (servidor → cliente): "Status", "Denied" (texto), "Found" (punto de interés), "Mine".
--   * Bajarse (botón BAJAR / Salir de la nave: SpaceService lo manda aquí): solo con la nave POSADA
--     (pegada al suelo y quieta). La nave se queda aparcada (World/PlanetWorld.park) con «Subir a la
--     nave»; al subir, despegas desde ahí (AirCombatService.enter con World = "Planet", Landed).
--   * Minar a pie (aviso «Extraer» de cada mineral): lo decide el servidor con las reglas de
--     shared/Cosmos/Mining (ritmo, bodega, cerca de verdad) y va a la bodega de tu nave (data.Space.Ore).
--   * Puntos de interés (baliza, ruinas, restos, plataforma): el primero de cada uno da $25 y queda
--     apuntado en data.Space.Pistas (ganchos de la historia de la Saga 2).
--   * Atributo del jugador "Planeta" (id) mientras está en un planeta (en la nave o a pie) y
--     "SpaceReturn" (si se desconecta a pie, vuelve al puerto espacial: PositionService).
-- API: toOrbit(player) · land(player) (modo pruebas) · disembark(player) · reboard(player) ·
--   leave(player) · harvest(player, id) · descend(player) · ascend(player)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local PlanetBodies = require(Cosmos.PlanetBodies)
local PlanetEntry = require(Cosmos.PlanetEntry)
local Planets = require(Cosmos.Planets)
local Tefra = require(Cosmos.Tefra)
local Mining = require(Cosmos.Mining)
local Access = require(Cosmos.Access)
local Landing = require(Cosmos.Landing)

local PlanetService = {}

-- Las superficies que existen (las demás, «próximamente»)
PlanetService.Surfaces = { Tefra = Tefra } :: { [string]: any }
PlanetService.DescendSlack = 320 -- studs de margen (red) sobre la capa Reloc para aceptar "Descend"
PlanetService.AscendSlack = 160
PlanetService.LandedAGL = 9 -- para bajarse: la nave a menos de esto del suelo…
PlanetService.LandedSpeed = 8 -- …y casi quieta
PlanetService.PoiReward = 25
PlanetService.ActionGap = 0.35

type PState = { Rate: Mining.Rate, LastAction: number, Asked: { [string]: boolean } }
local states: { [Player]: PState } = {}
local nodeRocks: { [string]: Mining.Rock } = {}
local emptied: { [string]: boolean } = {}
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local loop: RBXScriptConnection? = nil
local wired: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function service(name: string): any
	return require(script.Parent[name])
end

local function world(): any
	return require(script.Parent.Parent.World.PlanetWorld)
end

local function now(): number
	return os.clock()
end

local function stateOf(player: Player): PState
	local s = states[player]
	if not s then
		s = { Rate = Mining.newRate(), LastAction = -math.huge, Asked = {} }
		states[player] = s
	end
	return s
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function send(player: Player, kind: string, payload: any?)
	if remote and player.Parent then
		remote:FireClient(player, kind, payload)
	end
end

local function AC(): any
	return service("AirCombatService")
end

local function Space(): any
	return service("SpaceService")
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ¿Puede bajar a este planeta? ("Ready" y con superficie hecha)
function PlanetService.canLand(player: Player, id: string): (boolean, string)
	local okS, status, need = pcall(function()
		return Space().planetStatus(player, id)
	end)
	status = if okS then status else "Locked"
	if status ~= "Ready" or not PlanetService.Surfaces[id] then
		local text = Planets.message(id, if status == "Ready" then "Soon" else status, need)
		return false, text
	end
	return true, "Ready"
end

function PlanetService.statusFor(player: Player): { [string]: string }
	local out = {}
	for _, p in Planets.List do
		local ok, status = pcall(function()
			return Space().planetStatus(player, p.Id)
		end)
		local st = if ok then status else "Locked"
		if st == "Ready" and not PlanetService.Surfaces[p.Id] then
			st = "Soon"
		end
		out[p.Id] = st
	end
	return out
end

local function setOnPlanet(player: Player, id: string?)
	player:SetAttribute("Planeta", id)
	player:SetAttribute("SpaceReturn", if id then Access.arrival().Position else nil)
end

-- Línea del panel de la nave en el planeta
local function objectiveFor(player: Player): () -> string?
	return function(): string?
		local st = AC().status(player)
		local sp = Space().spaceData(player)
		if not st or not sp then
			return nil
		end
		local S = PlanetService.Surfaces[st.Planet or ""]
		local parts = { ("🪐 %s"):format(if S then S.Name else "Planeta") }
		if S then
			local g = S.groundAt(st.Pos.X, st.Pos.Z)
			local agl = math.max(0, st.Pos.Y - g)
			if st.Pos.Y > S.ClimbY then
				table.insert(parts, "☁ sube para volver al espacio")
			elseif agl < Landing.GearAGL then
				table.insert(parts, "🛬 frena: se posa sola")
			else
				table.insert(parts, ("%d m"):format(math.floor(agl * 0.28 + 0.5)))
			end
		end
		table.insert(parts, Mining.cargoText(sp.Ore))
		table.insert(parts, ("✨ %d"):format(sp.Chispas))
		return table.concat(parts, " · ")
	end
end

local function exitHandler(): ((Player) -> ())?
	local ok, fn = pcall(function()
		return Space().onExitRequest
	end)
	return if ok then fn else nil
end

---------------------------------------------------------------------
-- Bajar y subir (sin cortar el vuelo)
---------------------------------------------------------------------
function PlanetService.descend(player: Player): boolean
	local st = AC().status(player)
	if not st or st.Down or st.World ~= "Cosmos" then
		return false
	end
	local body, best = nil, math.huge
	for _, b in PlanetBodies.List do
		local d = (st.Pos - b.Center).Magnitude
		if d <= PlanetBodies.relocRadius(b) + PlanetService.DescendSlack and d < best then
			body, best = b, d
		end
	end
	if not body then
		return false
	end
	local ok, text = PlanetService.canLand(player, body.Id)
	if not ok then
		send(player, "Denied", { Id = body.Id, Text = text })
		return false
	end
	local S = PlanetService.Surfaces[body.Id]
	pcall(function()
		world().ensure()
	end)
	local cf = PlanetEntry.toSurface(body, S.Surface, st.Pos, st.Look)
	if not AC().relocate(player, cf, { World = "Planet", Geo = S, Planet = body.Id }) then
		return false
	end
	setOnPlanet(player, body.Id)
	AC().setObjective(player, objectiveFor(player))
	local ps = stateOf(player)
	if not ps.Asked["Llegada" .. body.Id] then
		ps.Asked["Llegada" .. body.Id] = true
		toast(player, "Success", ("🪐 %s. Para posarte, FRENA cerca del suelo llano y la nave baja sola; BAJAR para salir a pie. Sube del todo para volver al espacio."):format(S.Name))
	end
	return true
end

function PlanetService.ascend(player: Player): boolean
	local st = AC().status(player)
	if not st or st.Down or st.World ~= "Planet" then
		return false
	end
	local S = PlanetService.Surfaces[st.Planet or ""]
	local body = PlanetBodies.ById[st.Planet or ""]
	if not S or not body or st.Pos.Y < S.CeilingY - PlanetService.AscendSlack then
		return false
	end
	local cf = PlanetEntry.toSpace(body, S.Surface, st.Pos, st.Look)
	if not AC().relocate(player, cf, { World = "Cosmos" }) then
		return false
	end
	setOnPlanet(player, nil)
	pcall(function()
		AC().setObjective(player, Space().objectiveFor(player))
	end)
	toast(player, "Hint", ("🌌 Sales de la atmósfera de %s"):format(S.Name))
	return true
end

-- A la órbita de Tefra (el VIAJAR de la estrella y el modo pruebas): en la nave, encima de la cara
-- del planeta que mira a Valmar, mirando hacia él
function PlanetService.toOrbit(player: Player, id: string?): boolean
	local body = PlanetBodies.ById[id or "Tefra"]
	if not body then
		return false
	end
	local ac = AC()
	if ac.world(player) == nil then
		if not Space().board(player, "Alba") then
			return false
		end
	end
	local w = ac.world(player)
	if w == "Planet" then
		PlanetService.leave(player)
	end
	if w ~= "Cosmos" and w ~= "Planet" then
		return false
	end
	local up = PlanetEntry.frame(body)
	local p = body.Center + up * (PlanetBodies.entryRadius(body) + 900)
	local look = (body.Center - p).Unit
	local ok = ac.relocate(player, CFrame.new(p) * PlanetEntry.facing(look), { World = "Cosmos" })
	if ok then
		setOnPlanet(player, nil)
		pcall(function()
			ac.setObjective(player, Space().objectiveFor(player))
		end)
		pcall(function()
			world().ensure()
		end)
		toast(player, "Success", ("🪐 En órbita de %s: vuela hacia él para entrar en la atmósfera."):format(body.Id))
	end
	return ok
end

-- (modo pruebas) Directamente sobre la plataforma de Tefra, volando
function PlanetService.land(player: Player): boolean
	local ac = AC()
	if ac.world(player) == nil then
		if not Space().board(player, "Alba") then
			return false
		end
	end
	if ac.world(player) == "Arena" then
		return false
	end
	pcall(function()
		world().ensure()
	end)
	local pad = Tefra.toWorld(0, 0, Tefra.padY())
	local p = pad + Vector3.new(0, 260, 520)
	local look = (pad + Vector3.new(0, 40, 0) - p).Unit
	local ok = ac.relocate(player, CFrame.new(p) * PlanetEntry.facing(look), { World = "Planet", Geo = Tefra, Planet = "Tefra" })
	if ok then
		setOnPlanet(player, "Tefra")
		ac.setObjective(player, objectiveFor(player))
		toast(player, "Success", "🛬 Tefra: la plataforma está delante. FRENA cerca del suelo y la nave se posa sola.")
	end
	return ok
end

---------------------------------------------------------------------
-- Bajarse, aparcar y volver a subir
---------------------------------------------------------------------
-- ¿Está la nave posada? (pura: para las pruebas) S = superficie, pos, vel
function PlanetService.isLanded(S: any, pos: Vector3, vel: Vector3?): (boolean, string?)
	local g, water = S.groundAt(pos.X, pos.Z)
	if water then
		return false, "Water"
	end
	if pos.Y - g > PlanetService.LandedAGL then
		return false, "High"
	end
	if vel and vel.Magnitude > PlanetService.LandedSpeed then
		return false, "Fast"
	end
	return true, nil
end

function PlanetService.disembark(player: Player): boolean
	local ac = AC()
	local st = ac.status(player)
	if not st or st.Down or st.World ~= "Planet" then
		return false
	end
	local S = PlanetService.Surfaces[st.Planet or ""]
	if not S then
		return false
	end
	local ok, why = PlanetService.isLanded(S, st.Pos, st.Vel)
	if not ok then
		toast(player, "Hint", if why == "Water" then "🌊 Aquí hay agua: posa la nave en tierra para bajarte" else "🛬 Posa la nave primero: FRENA (o suelta el motor) cerca del suelo llano y baja sola")
		return false
	end
	local cf: CFrame = st.CFrame
	local level = Landing.level(cf - cf.Position)
	local g = S.groundAt(st.Pos.X, st.Pos.Z)
	local parkCF = CFrame.new(Vector3.new(st.Pos.X, g + Landing.RestHeight, st.Pos.Z)) * level
	-- Te bajas al lado izquierdo de la nave
	local side = parkCF * Vector3.new(-12, 0, 0)
	local feet = S.groundAt(side.X, side.Z)
	local out = CFrame.new(Vector3.new(side.X, feet + 3.5, side.Z)) * level
	ac.setReturn(player, out)
	ac.exit(player, "exit")
	world().park(player, parkCF)
	setOnPlanet(player, S.Id)
	toast(player, "Hint", ("🚶 Estás en %s. «Subir a la nave» junto a tu nave para despegar. VISOR marca el mineral y los puntos de interés."):format(S.Name))
	return true
end

function PlanetService.reboard(player: Player): boolean
	local model = world().parked(player)
	local root = rootOf(player)
	if not model or not root or not model.PrimaryPart then
		return false
	end
	if (root.Position - model.PrimaryPart.Position).Magnitude > 30 then
		return false
	end
	local ok, why = Space().canFly(player)
	if not ok then
		toast(player, "Info", Access.Messages[why or "Locked"] or Access.Messages.Locked)
		return false
	end
	local id = player:GetAttribute("Planeta")
	local S = PlanetService.Surfaces[if type(id) == "string" then id else "Tefra"] or Tefra
	local cf = model.PrimaryPart.CFrame
	local ship = Space().shipState(player) or {}
	world().unpark(player)
	local entered = AC().enter(player, {
		World = "Planet",
		Geo = S,
		Planet = S.Id,
		Trusted = true,
		Start = cf,
		Return = Access.arrival(),
		Objective = objectiveFor(player),
		OnExit = exitHandler(),
		Hull = ship.Hull,
		Missiles = ship.Missiles,
		Landed = true,
	})
	if not entered then
		world().park(player, cf)
		return false
	end
	setOnPlanet(player, S.Id)
	-- (cómo despegar lo dice ya la pista de la nave al subir: AirCombatClient; antes salían las dos)
	return true
end

-- Se va del planeta (VALMAR, otro sitio, se desconecta): fuera la nave aparcada y los atributos
function PlanetService.leave(player: Player)
	pcall(function()
		world().unpark(player)
	end)
	if player.Parent then
		setOnPlanet(player, nil)
	end
end

---------------------------------------------------------------------
-- Minar a pie y puntos de interés
---------------------------------------------------------------------
function PlanetService.harvest(player: Player, id: string): string?
	local node = Tefra.node(id)
	local root = rootOf(player)
	if not node or not root then
		return nil
	end
	if AC().world(player) ~= nil then
		return "Ship"
	end
	if (root.Position - node.Pos).Magnitude > Tefra.Reach + node.Radius + 4 then
		return "Far"
	end
	local sp = Space().spaceData(player)
	if not sp then
		return nil
	end
	local t = now()
	local r = nodeRocks[id]
	if not r then
		r = Mining.newRock(node.Radius * 6)
		nodeRocks[id] = r
	end
	Mining.refill(r, t)
	if r.Units <= 0 then
		toast(player, "Info", "⛏ Agotado: vuelve a brillar en unos minutos")
		return "Dry"
	end
	local ok, why = Mining.allow(stateOf(player).Rate, t, Mining.cargo(sp.Ore), root.Position, node.Pos, false)
	if not ok then
		if why == "Cargo" then
			toast(player, "Info", ("⛏ Bodega llena (%d/%d): vende el mineral en una estación"):format(Mining.cargo(sp.Ore), Mining.CargoMax))
		end
		return why
	end
	local result = Mining.extract(r, t)
	if result == "Empty" then
		emptied[id] = true
		pcall(function()
			world().setNodeLit(id, false)
		end)
		PlanetService.ensureLoop()
	end
	sp.Ore[node.Ore] = (tonumber(sp.Ore[node.Ore]) or 0) + 1
	sp.Mined += 1
	local ore = Mining.Ores[node.Ore]
	send(player, "Mine", { Pos = node.Pos, Ore = node.Ore, Cargo = Mining.cargo(sp.Ore), Empty = result == "Empty" })
	toast(player, "Success", ("⛏ +1 %s · bodega %d/%d"):format(if ore then ore.Name else node.Ore, Mining.cargo(sp.Ore), Mining.CargoMax))
	pcall(function()
		Space().event(player, { Type = "Mine", Ore = node.Ore, Count = 1 })
	end)
	return result
end

function PlanetService.poi(player: Player, id: string): boolean
	local p = Tefra.PoiById[id]
	local root = rootOf(player)
	if not p or not root then
		return false
	end
	local pos = Tefra.toWorld(p.X, p.Z, Tefra.Origin.Y + Tefra.poiY(id))
	if (root.Position - pos).Magnitude > p.Flat + 60 then
		return false
	end
	local sp = Space().spaceData(player)
	local first = false
	if sp then
		if type(sp.Pistas) ~= "table" then
			sp.Pistas = {}
		end
		if not sp.Pistas[id] then
			sp.Pistas[id] = os.time()
			first = true
			pcall(function()
				service("DataService").addMoney(player, PlanetService.PoiReward, true)
			end)
		end
	end
	send(player, "Found", { Id = id, Name = p.Name, Text = p.Text, First = first })
	toast(player, "Info", p.Text .. (if first then (" (+$%d)"):format(PlanetService.PoiReward) else ""))
	return true
end

local function tick()
	local t = now()
	for id in table.clone(emptied) do
		local r = nodeRocks[id]
		if r and Mining.refill(r, t) then
			emptied[id] = nil
			pcall(function()
				world().setNodeLit(id, true)
			end)
		elseif not r then
			emptied[id] = nil
		end
	end
	if next(emptied) == nil and loop then
		loop:Disconnect()
		loop = nil
	end
end
PlanetService._tick = tick

function PlanetService.ensureLoop()
	if loop then
		return
	end
	local acc = 0
	loop = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 5 then
			acc = 0
			tick()
		end
	end)
end

---------------------------------------------------------------------
-- Avisos y remoto
---------------------------------------------------------------------
local function wirePrompts()
	for kind, list in world().prompts() do
		for _, pp in list do
			if not wired[pp] then
				wired[pp] = true
				pp.Triggered:Connect(function(player: Player)
					local ok, err = pcall(function()
						local id = pp:GetAttribute("Id")
						if kind == "Node" then
							PlanetService.harvest(player, id)
						elseif kind == "Poi" then
							PlanetService.poi(player, id)
						elseif kind == "Ship" then
							if tostring(player.UserId) == id then
								PlanetService.reboard(player)
							else
								toast(player, "Info", "🔒 Esta nave es de otro piloto")
							end
						end
					end)
					if not ok then
						warn("[PlanetService] " .. tostring(err))
					end
				end)
			end
		end
	end
end

local function onRemote(player: Player, action: any, a: any)
	local ps = stateOf(player)
	local t = now()
	if t - ps.LastAction < PlanetService.ActionGap and action ~= "Status" then
		return
	end
	ps.LastAction = t
	if action == "Descend" then
		PlanetService.descend(player)
	elseif action == "Ascend" then
		PlanetService.ascend(player)
	elseif action == "Status" then
		send(player, "Status", PlanetService.statusFor(player))
	elseif action == "Near" then
		if type(a) == "string" and PlanetService.Surfaces[a] and PlanetService.canLand(player, a) then
			pcall(function()
				world().ensure()
			end)
		end
	end
end
PlanetService._onRemote = onRemote

function PlanetService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild("Planet") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "Planet"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, action, a)
		local ok, err = pcall(onRemote, player, action, a)
		if not ok then
			warn("[PlanetService] " .. tostring(err))
		end
	end)
	-- Tefra: el VIAJAR de su estrella te lleva a su órbita (las otras seis siguen «próximamente»)
	pcall(function()
		Space().registerPlanet("Tefra", {
			Travel = function(player: Player)
				PlanetService.toOrbit(player, "Tefra")
			end,
		})
	end)
	pcall(function()
		world().setupLooks()
	end)
	world().prompts(function()
		task.defer(wirePrompts)
	end)
	-- Si muere a pie en el planeta (o reaparece por otra cosa), ya no está allí
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				if player:GetAttribute("Planeta") ~= nil and AC().world(player) == nil then
					PlanetService.leave(player)
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		pcall(function()
			world().unpark(player)
		end)
		states[player] = nil
	end)
end

-- (pruebas)
PlanetService._states = states
PlanetService._nodeRocks = nodeRocks

return PlanetService
