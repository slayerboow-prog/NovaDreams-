-- PlanetPerilService (servidor): los PELIGROS DEL TERRENO de cada planeta (shared/Cosmos/TerrainPerils;
-- cada planeta los declara en S.Perils). Se suman a la desventaja con medidor (PlanetHazardService) y
-- SE VEN: las zonas del suelo (arenas movedizas, ciénaga, hielo fino…) tienen su mancha y sus burbujas;
-- los rayos y lo que cae avisan con un círculo rojo en el suelo antes de golpear.
--
--   * Pozo: dentro andas lento (atributo TerrainSlow, NeedsService), el medidor sube y, si quema, algo
--     de vida (nunca por debajo de 15). Se sale andando.
--   * Hielo: quieto encima un rato → cruje (aviso) → se rompe: el medidor sube de golpe y sales en la
--     orilla, empapado. Moverse lo evita.
--   * Rayo / Caida: en su momento, a quien está al descubierto: círculo de aviso → golpe. Si sales del
--     círculo a tiempo, nada.
--   * Empuje: en su momento, ráfagas de lado al descubierto (el cliente aplica el empujón:
--     Controllers/PlanetPerilClient, remoto «PlanetPeril»).
--   * Nada pasa en mitad de una escena o una conversación, ni en el refugio, ni en la nave.
--   * La historia lo oye: PerilHit { Planet, Peril, Kind } (te ha pillado) y PerilDodged { Planet,
--     Peril, Kind } (lo has esquivado: saliste del círculo, te moviste del hielo, saliste del pozo).
-- API: _tick(dt) · zonesFolder(id) · _reset() · _states

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage.Shared
local PlanetRegistry = require(Shared.Cosmos.PlanetRegistry)
local TerrainPerils = require(Shared.Cosmos.TerrainPerils)
local SoundIds = require(Shared.SoundIds)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local PlanetPerilService = {}

PlanetPerilService.Tick = 0.25
PlanetPerilService.Random = Random.new()

type PState = {
	Planet: string,
	Seen: { [string]: boolean }, -- avisos ya dados (la primera vez de cada peligro)
	Next: { [string]: number }, -- cuándo toca el siguiente rayo / ráfaga (por peligro)
	Still: number, -- segundos quieto sobre hielo fino
	Crack: number?, -- cuándo crujió (y dónde)
	CrackAt: Vector3?,
	InPozo: string?, -- el pozo en el que está
	Slow: number,
}
local states: { [Player]: PState } = {}
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local built: { [string]: Instance } = {}

PlanetPerilService.Clock = os.clock
local function now(): number
	return PlanetPerilService.Clock()
end

local function service(name: string): any
	return require(script.Parent[name])
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function busy(player: Player): boolean
	return player:GetAttribute("InScene") == true
		or player:GetAttribute("InDialogue") == true
		or player:GetAttribute("InCinematic") == true
		or player:GetAttribute("Dead") == true
end

local function hurt(player: Player, amount: number)
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Health > 0 and amount > 0 then
		humanoid.Health = math.max(math.min(15, humanoid.Health), humanoid.Health - amount)
	end
end

local function bump(player: Player, amount: number?)
	if amount and amount ~= 0 then
		pcall(function()
			service("PlanetHazardService").bump(player, amount)
		end)
	end
end

local function sound(name: string, at: Vector3, volume: number?)
	local id = SoundIds[name]
	if not id then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = "PerilSound"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(at)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.8
	s.RollOffMaxDistance = 220
	s.Parent = holder
	holder.Parent = workspace
	s:Play()
	Debris:AddItem(holder, 6)
end

local function disc(name: string, at: Vector3, radius: number, color: Color3, material: Enum.Material, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Vector3.new(0.3, radius * 2, radius * 2)
	p.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material
	p.Transparency = transparency
	return p
end

-- ¿Al descubierto? (fuera de los refugios de la ciudad)
local function exposed(S: any, position: Vector3): boolean
	local City = S.City
	if City and City.shelterAt then
		local lx, lz = S.toLocal(position)
		local ok, shelter = pcall(City.shelterAt, lx, lz)
		if ok and shelter and position.Y - (S.Origin.Y + S.padY()) < 14 then
			return false
		end
	end
	return true
end

local function onGround(S: any, position: Vector3): boolean
	local ground = S.groundAt(position.X, position.Z)
	return position.Y - ground < 7
end

---------------------------------------------------------------------
-- Las zonas del suelo se ven (una vez por planeta, cuando llega alguien)
---------------------------------------------------------------------
function PlanetPerilService.zonesFolder(id: string): Instance?
	if built[id] and built[id].Parent then
		return built[id]
	end
	local S = PlanetRegistry.get(id)
	if not S then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = "Peligros_" .. id
	for _, peril in TerrainPerils.of(S) do
		if peril.Kind == "Pozo" or peril.Kind == "Hielo" then
			for i, z in TerrainPerils.zones(S, peril) do
				local x, zz = S.Origin.X + z.X, S.Origin.Z + z.Z
				local y = S.groundAt(x, zz)
				local color = peril.Color or Color3.fromRGB(120, 90, 60)
				local mark = disc(("%s_%d"):format(peril.Id, i), Vector3.new(x, y + 0.2, zz), z.R, color, peril.Material or Enum.Material.Mud, 0.15)
				mark:SetAttribute("Peril", peril.Id)
				-- (burbujas, vapor o escarcha: que se note que ahí pasa algo)
				local emitter = Instance.new("ParticleEmitter")
				emitter.Rate = math.clamp(z.R * 0.4, 2, 10)
				emitter.Lifetime = NumberRange.new(1.2, 2.4)
				emitter.Speed = NumberRange.new(0.5, 1.6)
				emitter.SpreadAngle = Vector2.new(10, 10)
				emitter.Size = NumberSequence.new(0.5, 1.4)
				emitter.Transparency = NumberSequence.new(0.4, 1)
				emitter.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.45))
				emitter.EmissionDirection = Enum.NormalId.Right -- (el cilindro está tumbado: su «arriba» es X)
				emitter.Parent = mark
				mark.Parent = folder
			end
		end
	end
	folder.Parent = workspace
	built[id] = folder
	return folder
end

-- Las manchas se apoyan en el terreno DE VERDAD (los vóxeles redondean la altura de la cuenta y
-- quedaban enterradas ~2 studs): rayo hacia abajo contra el terreno cuando ya está construido ahí
local terrainOnly: RaycastParams? = nil
local function terrainParams(): RaycastParams
	if not terrainOnly then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain }
		terrainOnly = params
	end
	return terrainOnly :: RaycastParams
end

-- La altura del suelo que se ve (el terreno de verdad; si aún no está, la de la cuenta)
local function surfaceAt(S: any, x: number, z: number, near: number?): number
	local guess = near or S.groundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, guess + 40, z), Vector3.new(0, -120, 0), terrainParams())
	return if hit then hit.Position.Y else S.groundAt(x, z)
end

local function snapNear(id: string, position: Vector3)
	local folder = built[id]
	if not folder then
		return
	end
	terrainParams()
	for _, mark in folder:GetChildren() do
		if mark:IsA("BasePart") and not mark:GetAttribute("Snapped") then
			local at = mark.Position
			if (Vector3.new(at.X, 0, at.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude < 260 then
				local hit = workspace:Raycast(at + Vector3.new(0, 60, 0), Vector3.new(0, -160, 0), terrainOnly)
				if hit then
					mark.CFrame = CFrame.new(at.X, hit.Position.Y + 0.15, at.Z) * CFrame.Angles(0, 0, math.rad(90))
					mark:SetAttribute("Snapped", true)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Rayo / Caida: círculo de aviso y golpe
---------------------------------------------------------------------
local function strike(player: Player, S: any, peril: TerrainPerils.Peril, center: Vector3)
	local reach = peril.Reach or 7
	local warn = peril.Warn or 1.6
	local ground = surfaceAt(S, center.X, center.Z, center.Y - 3)
	local at = Vector3.new(center.X, ground + 0.25, center.Z)
	local ring = disc("Aviso_" .. peril.Id, at, reach, Color3.fromRGB(255, 60, 40), Enum.Material.Neon, 0.45)
	ring.Parent = workspace
	Debris:AddItem(ring, warn + 0.5)
	task.delay(warn, function()
		if ring.Parent then
			ring:Destroy()
		end
		-- El golpe: un rayo (columna de luz) o algo que cae
		local visual = Instance.new("Part")
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanQuery = false
		visual.CanTouch = false
		visual.CastShadow = false
		if peril.Kind == "Rayo" then
			visual.Name = "Rayo"
			visual.Material = Enum.Material.Neon
			visual.Color = Color3.fromRGB(210, 230, 255)
			visual.Size = Vector3.new(1.2, 160, 1.2)
			visual.CFrame = CFrame.new(at + Vector3.new(0, 80, 0))
			local light = Instance.new("PointLight")
			light.Brightness = 8
			light.Range = 40
			light.Color = visual.Color
			light.Parent = visual
			sound("trueno_cerca", at, 1)
			Debris:AddItem(visual, 0.35)
		else
			visual.Name = "Cae_" .. peril.Id
			visual.Material = peril.Material or Enum.Material.Wood
			visual.Color = peril.Color or Color3.fromRGB(90, 70, 50)
			visual.Size = Vector3.new(reach * 0.9, 1.4, 2.2)
			visual.CFrame = CFrame.new(at + Vector3.new(0, 1, 0)) * CFrame.Angles(0, PlanetPerilService.Random:NextNumber(0, math.pi), math.rad(8))
			sound("golpe_caida", at, 1)
			Debris:AddItem(visual, 6)
		end
		visual.Parent = workspace
		-- ¿Quién sigue dentro?
		for _, other in Players:GetPlayers() do
			local root = rootOf(other)
			if root and other:GetAttribute("Planeta") == S.Id and not busy(other) then
				local flat = Vector3.new(root.Position.X - at.X, 0, root.Position.Z - at.Z)
				if flat.Magnitude <= reach and root.Position.Y - at.Y < 12 then
					hurt(other, peril.Damage or 20)
					bump(other, peril.Drop)
					if remote then
						local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(1, 0, 0)
						remote:FireClient(other, { Push = dir * 34 + Vector3.new(0, 18, 0), Shake = 0.6 })
					end
					toast(other, "Error", peril.Hit or ("%s ¡Te ha dado!"):format(peril.Icon))
					StoryEvents.emit(other, "PerilHit", { Planet = S.Id, Peril = peril.Id, Kind = peril.Kind })
				elseif other == player then
					StoryEvents.emit(other, "PerilDodged", { Planet = S.Id, Peril = peril.Id, Kind = peril.Kind })
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- Cada jugador
---------------------------------------------------------------------
local function clear(player: Player)
	local st = states[player]
	states[player] = nil
	if st and st.Slow < 1 and player.Parent then
		player:SetAttribute("TerrainSlow", nil)
		pcall(function()
			service("NeedsService").refreshSpeed(player)
		end)
	end
	if player.Parent then
		player:SetAttribute("PeligroTerreno", nil)
	end
end

local function setSlow(player: Player, st: PState, factor: number)
	if math.abs(st.Slow - factor) < 1e-3 then
		return
	end
	st.Slow = factor
	player:SetAttribute("TerrainSlow", if factor < 1 then factor else nil)
	pcall(function()
		service("NeedsService").refreshSpeed(player)
	end)
end

local function firstTime(player: Player, st: PState, peril: TerrainPerils.Peril)
	if not st.Seen[peril.Id] then
		st.Seen[peril.Id] = true
		toast(player, "Info", peril.Text)
	end
end

local function stepPlayer(player: Player, dt: number)
	local ok, id, S = pcall(function()
		return service("PlanetHazardService").planetOf(player)
	end)
	if not ok or not id or not S or #TerrainPerils.of(S) == 0 then
		if states[player] then
			clear(player)
		end
		return
	end
	PlanetPerilService.zonesFolder(id)
	local st = states[player]
	if not st or st.Planet ~= id then
		if st then
			clear(player)
		end
		st = { Planet = id, Seen = {}, Next = {}, Still = 0, Slow = 1 }
		states[player] = st
	end
	local s = st :: PState
	local root = rootOf(player) :: BasePart
	if busy(player) then
		setSlow(player, s, 1)
		s.Still, s.Crack = 0, nil
		return
	end
	local pos = root.Position
	snapNear(id, pos)
	local lx, lz = S.toLocal(pos)
	local grounded = onGround(S, pos)
	local open = exposed(S, pos)
	local mode = service("PlanetHazardService").modeFor(S, player, pos)
	local slow = 1
	local inPozo: string? = nil
	local onIce = false
	local label: string? = nil
	for _, peril in TerrainPerils.of(S) do
		local kind = peril.Kind
		if kind == "Pozo" and grounded then
			if TerrainPerils.zoneAt(S, peril, lx, lz) then
				inPozo = peril.Id
				slow = math.min(slow, peril.Slow or 0.5)
				bump(player, (peril.Rate or 0) * dt)
				hurt(player, (peril.Burn or 0) * dt)
				firstTime(player, s, peril)
				label = peril.Icon .. " " .. peril.Name
				if s.InPozo ~= peril.Id then
					StoryEvents.emit(player, "PerilHit", { Planet = id, Peril = peril.Id, Kind = kind })
				end
			end
		elseif kind == "Hielo" and grounded then
			local zone = TerrainPerils.zoneAt(S, peril, lx, lz)
			if zone then
				onIce = true
				label = peril.Icon .. " " .. peril.Name
				local speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
				if speed < 2 then
					s.Still += dt
				else
					s.Still = math.max(0, s.Still - dt * 2)
					if s.Crack and s.CrackAt and (pos - s.CrackAt).Magnitude > 5 then
						s.Crack, s.CrackAt = nil, nil
						StoryEvents.emit(player, "PerilDodged", { Planet = id, Peril = peril.Id, Kind = kind })
					end
				end
				if not s.Crack and s.Still >= (peril.Hold or 3) then
					s.Crack = now()
					s.CrackAt = pos
					firstTime(player, s, peril)
					toast(player, "Error", ("%s ¡El hielo cruje bajo tus pies! Muévete."):format(peril.Icon))
					sound("choque_leve", pos, 0.9)
					local crack = disc("Grieta", Vector3.new(pos.X, surfaceAt(S, pos.X, pos.Z, pos.Y - 3) + 0.3, pos.Z), 4, Color3.fromRGB(220, 240, 255), Enum.Material.Glass, 0.3)
					crack.Parent = workspace
					Debris:AddItem(crack, 3)
				elseif s.Crack and now() - s.Crack >= 1.4 then
					-- Se rompe: al agua helada y a la orilla
					s.Crack, s.CrackAt, s.Still = nil, nil, 0
					bump(player, peril.Drop or 40)
					hurt(player, peril.Damage or 10)
					sound("golpe_caida", pos, 1)
					local sx, sz = TerrainPerils.shore(zone, lx, lz, 6)
					local wx, wz = S.Origin.X + sx, S.Origin.Z + sz
					local target = Vector3.new(wx, surfaceAt(S, wx, wz) + 4, wz)
					local moved = pcall(function()
						service("SceneService").teleportTo(player, target, { Dip = true })
					end)
					if not moved then
						root.CFrame = CFrame.new(target)
					end
					toast(player, "Error", peril.Hit or ("%s El hielo se rompe. Sales a la orilla chorreando, con el frío metido en los huesos."):format(peril.Icon))
					StoryEvents.emit(player, "PerilHit", { Planet = id, Peril = peril.Id, Kind = kind })
				end
			end
		elseif (kind == "Rayo" or kind == "Caida") and open and TerrainPerils.active(peril, mode) then
			local due = s.Next[peril.Id]
			if not due then
				s.Next[peril.Id] = now() + PlanetPerilService.Random:NextNumber(2, (peril.Every or 12) * 0.6)
			elseif now() >= due then
				s.Next[peril.Id] = now() + (peril.Every or 12) * PlanetPerilService.Random:NextNumber(0.8, 1.25)
				firstTime(player, s, peril)
				local r = PlanetPerilService.Random
				local offset = Vector3.new(r:NextNumber(-4, 4), 0, r:NextNumber(-4, 4))
				strike(player, S, peril, pos + offset)
			end
		elseif kind == "Empuje" and open and grounded and TerrainPerils.active(peril, mode) then
			local due = s.Next[peril.Id]
			if not due then
				s.Next[peril.Id] = now() + 2
				firstTime(player, s, peril)
			elseif now() >= due then
				s.Next[peril.Id] = now() + (peril.Every or 6) * PlanetPerilService.Random:NextNumber(0.7, 1.3)
				local dir = (peril.Dir or Vector3.new(1, 0, 0.3)).Unit
				if remote then
					remote:FireClient(player, { Push = dir * (peril.Force or 30), Shake = 0.3 })
				end
				sound("viento_tormenta", pos, 0.6)
			end
		end
	end
	if not onIce then
		s.Still, s.Crack, s.CrackAt = 0, nil, nil
	end
	if s.InPozo and not inPozo then
		StoryEvents.emit(player, "PerilDodged", { Planet = id, Peril = s.InPozo, Kind = "Pozo" })
	end
	s.InPozo = inPozo
	setSlow(player, s, slow)
	if player:GetAttribute("PeligroTerreno") ~= label then
		player:SetAttribute("PeligroTerreno", label)
	end
end

function PlanetPerilService._tick(dt: number)
	for _, p in Players:GetPlayers() do
		local ok, err = pcall(stepPlayer, p, dt)
		if not ok then
			warn("[PlanetPerilService] " .. tostring(err))
		end
	end
end

PlanetPerilService._states = states
function PlanetPerilService._reset()
	for p in table.clone(states) do
		clear(p)
	end
end

function PlanetPerilService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	remote = remotes:FindFirstChild("PlanetPeril") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "PlanetPeril"
		created.Parent = remotes
		remote = created
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PlanetPerilService.Tick)
			PlanetPerilService._tick(PlanetPerilService.Tick)
		end
	end)
end

return PlanetPerilService
