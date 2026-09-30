-- CrashService (servidor): choques entre vehículos con varios jugadores.
--
-- Cada coche lo mueve el ordenador de quien conduce (Driving.luau), así que cada uno resuelve SU
-- mitad del choque al momento (Controllers/Collisions, con shared/Crash). Lo que no puede hacer un
-- cliente es empujar el coche de otro: eso pasa por aquí.
--   * "Hit" (cliente → servidor): «he chocado con ese vehículo». El servidor NO se cree nada: usa el
--     vehículo que conduces según él (VehicleService.rideModel), las posiciones y velocidades que ve
--     él (limitadas a lo que puede correr cada vehículo), comprueba que de verdad estén juntos
--     (Crash.judge, con margen por el retraso), limita la frecuencia (por pareja y por jugador) y
--     calcula él el impulso, con topes. Luego:
--       - otro jugador al volante → le manda "Impact" con su cambio de velocidad y giro (su
--         ordenador lo aplica, y si va en moto y el golpe es fuerte, se cae)
--       - moto, bici o patinete aparcados → salen despedidos con física de verdad y, cuando se
--         paran, los vuelve a aparcar VehicleService (parkOrphans) de pie en el suelo
--       - coche aparcado → se desplaza un poco (si hay sitio), según el golpe
--   * "Bump": golpe contra una pared, el tráfico o algo anclado (para los daños de chapa).
--   * Daños solo de aspecto (Crash.damageLevel): chapa rozada y, si es fuerte, cristal rajado. Se
--     arreglan solos al aparcar (a los 15 s) o a los 2 minutos.
-- Los barcos no pasan por aquí (tienen su propia regla en el agua).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crash = require(ReplicatedStorage.Shared.Crash)
local Knock = require(ReplicatedStorage.Shared.Knock)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local VehicleService = require(script.Parent.VehicleService)

local CrashService = {}

local Remote: RemoteEvent? = nil
local pairAt: { [string]: number } = {}
local bursts: { [Player]: { number } } = {}
local bumpAt: { [Player]: number } = {}

-- Un número por vehículo (para las parejas del límite de frecuencia); se olvida solo al destruirse
local ids: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local nextId = 0
local function idOf(model: Instance): number
	local id = ids[model]
	if not id then
		nextId += 1
		id = nextId
		ids[model] = id
	end
	return id
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Tipo de vehículo de un modelo (los coches aparcados de la ciudad aún no lo tienen: son coches)
function CrashService.kindOf(model: Instance): string?
	local kind = model:GetAttribute("Kind")
	if typeof(kind) == "string" then
		return kind
	end
	if model.Name == "ParkedCar" or model.Name == "PoliceCar" then
		return "Coche"
	end
	return nil
end

function CrashService.maxSpeed(kind: string?): number
	local vehicle = kind and Gameplay.Vehicles[kind]
	return if vehicle then vehicle.Speed else 60
end

-- La caja de un vehículo vista por el servidor. Con base ("Chassis"), la de la base; si no, la del modelo.
function CrashService.bodyOf(model: Model): (Crash.Body?, BasePart?)
	local kind = CrashService.kindOf(model)
	local chassis = model:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") then
		local cf = chassis.CFrame
		local driven = typeof(model:GetAttribute("Driver")) == "number" and not chassis.Anchored
		local vel = if driven then chassis.AssemblyLinearVelocity else Vector3.zero
		return Crash.body(cf.Position - cf.UpVector * (chassis.Size.Y / 2), cf.LookVector, chassis.Size.Z, chassis.Size.X, vel, 0, kind, not driven), chassis
	end
	local ok, box, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or typeof(box) ~= "CFrame" then
		return nil, nil
	end
	return Crash.body(box.Position - Vector3.new(0, size.Y / 2, 0), box.LookVector, size.Z, size.X, Vector3.zero, 0, kind, true), model.PrimaryPart
end

local function occupied(model: Model): boolean
	for _, seat in model:GetDescendants() do
		if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Daños de chapa (solo aspecto)
---------------------------------------------------------------------
type Saved = { Color: Color3, Transparency: number }
type Damage = { At: number, Parts: { [BasePart]: Saved }, Hits: { [BasePart]: number } }
local damaged: { [Model]: Damage } = {}
local SCUFF = Color3.fromRGB(58, 58, 60)
local CRACKED = Color3.fromRGB(222, 230, 236)

function CrashService.damage(model: Model, point: Vector3, closing: number)
	local level = Crash.damageLevel(closing)
	if level == 0 or not model.Parent then
		return
	end
	local rec = damaged[model]
	if not rec then
		rec = { At = 0, Parts = {}, Hits = {} }
		damaged[model] = rec
	end
	rec.At = os.clock()
	local paint, glass, dp, dg = nil :: BasePart?, nil :: BasePart?, 8, 9
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Chassis" and not d:IsA("Seat") and not d:IsA("VehicleSeat") and d.Transparency < 0.9 then
			local dist = flat(d.Position - point).Magnitude
			if d.Material == Enum.Material.Glass then
				if dist < dg then
					glass, dg = d, dist
				end
			elseif d.Material ~= Enum.Material.Neon and d.Size.X * d.Size.Y * d.Size.Z > 0.5 and dist < dp then
				paint, dp = d, dist
			end
		end
	end
	local function save(part: BasePart)
		if not rec.Parts[part] then
			rec.Parts[part] = { Color = part.Color, Transparency = part.Transparency }
		end
	end
	if paint then
		save(paint)
		local hits = math.min((rec.Hits[paint] or 0) + level, 3)
		rec.Hits[paint] = hits
		paint.Color = rec.Parts[paint].Color:Lerp(SCUFF, 0.14 * hits) -- rozado (nunca negro del todo)
	end
	if level >= 2 and glass then
		save(glass)
		glass.Color = CRACKED -- rajado: blanquecino y menos transparente
		glass.Transparency = math.min(rec.Parts[glass].Transparency, 0.2)
	end
end

local function repair(model: Model)
	local rec = damaged[model]
	damaged[model] = nil
	if not rec then
		return
	end
	for part, saved in rec.Parts do
		if part.Parent then
			part.Color = saved.Color
			part.Transparency = saved.Transparency
		end
	end
end
CrashService.repair = repair

---------------------------------------------------------------------
-- Vehículos aparcados que reciben el golpe
---------------------------------------------------------------------
type Tumble = Knock.Loose & { Model: Model }
local tumbling: { [Model]: Tumble } = {}

-- Moto, bici o patinete aparcados: salen despedidos (física de verdad, del servidor)
local function launchParked(model: Model, relVel: Vector3, hitterMass: number, away: Vector3): boolean
	local chassis = model:FindFirstChild("Chassis")
	local kind = CrashService.kindOf(model)
	if not chassis or not chassis:IsA("BasePart") or not chassis.Anchored or not kind or model:GetAttribute("Knocked") or occupied(model) then
		return false
	end
	local vel, spin, mode = Knock.launch({ Mass = Crash.mass(kind) or 100 }, relVel, hitterMass, away)
	if mode == "none" then
		return false
	end
	model:SetAttribute("Knocked", true) -- (VehicleService no lo vuelve a aparcar mientras vuela)
	chassis.Anchored = false
	pcall(function()
		chassis:SetNetworkOwner(nil)
	end)
	chassis.AssemblyLinearVelocity = vel
	chassis.AssemblyAngularVelocity = spin
	tumbling[model] = { Model = model, Since = os.clock() }
	return true
end

-- Coche aparcado: se desplaza un poco (según las masas y el golpe), solo si hay sitio
local function nudge(model: Model, a: Crash.Body, b: Crash.Body, c: Crash.Contact)
	if occupied(model) or model:GetAttribute("Knocked") then
		return
	end
	local parked = table.clone(b)
	parked.Kinematic = false
	parked.Mass = b.Mass * 3 -- con el freno de mano puesto cuesta más moverlo
	local r = Crash.resolve(a, parked, c)
	local shift = flat(r.VelB) * 0.1
	if shift.Magnitude > 1.2 then
		shift = shift.Unit * 1.2
	end
	local yaw = math.clamp(r.SpinB * 0.1, -0.12, 0.12)
	if shift.Magnitude < 0.15 and math.abs(yaw) < 0.02 then
		return
	end
	local pivot = model:GetPivot()
	local target = CFrame.new(pivot.Position + shift) * CFrame.Angles(0, yaw, 0) * pivot.Rotation
	-- ¿Hay sitio? (nada sólido donde quedaría, salvo él mismo y las personas)
	local ignore: { Instance } = { model }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	params.MaxParts = 10
	local look = (target.Rotation * pivot.Rotation:Inverse()) * b.Dir
	local box = CFrame.lookAt(b.Pos + shift + Vector3.new(0, 2.6, 0), b.Pos + shift + Vector3.new(0, 2.6, 0) + look)
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInBox(box, Vector3.new(b.Width * 0.95, 4, b.Length * 0.95), params)
	end)
	if not ok then
		return
	end
	for _, part in parts do
		if part ~= workspace.Terrain and part.CanCollide then
			return
		end
	end
	model:PivotTo(target)
end

---------------------------------------------------------------------
-- Avisos de los clientes
---------------------------------------------------------------------
local function onHit(player: Player, target: any, info: any)
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not target:IsDescendantOf(workspace) then
		return
	end
	local mine = VehicleService.rideModel(player)
	if not mine or mine == target or not mine.Parent then
		return
	end
	local now = os.clock()
	bursts[player] = bursts[player] or {}
	if not Crash.burst(bursts[player], now, Crash.Server.Burst, Crash.Server.BurstWindow) then
		return
	end
	local ia, ib = idOf(mine), idOf(target)
	local key = if ia < ib then ia .. "|" .. ib else ib .. "|" .. ia
	if not Crash.rate(pairAt, key, now, Crash.Server.PairGap) then
		return
	end
	local a = CrashService.bodyOf(mine)
	local b = CrashService.bodyOf(target)
	if not a or not b then
		return
	end
	local claimed = if type(info) == "table" and type(info.Speed) == "number" then info.Speed else nil
	local judged = Crash.judge(a, b, CrashService.maxSpeed(a.Kind), CrashService.maxSpeed(b.Kind), claimed)
	if not judged.Ok or not judged.Result or not judged.Contact then
		return
	end
	local r, c = judged.Result, judged.Contact
	local driverId = target:GetAttribute("Driver")
	local other = if typeof(driverId) == "number" then Players:GetPlayerByUserId(driverId) else nil
	if other and other ~= player and not b.Kinematic and Remote then
		Remote:FireClient(other, "Impact", {
			From = mine,
			Model = target,
			Dv = flat(r.VelB - b.Vel),
			Spin = r.SpinB - b.Spin,
			Closing = r.Closing,
			Point = c.Point,
			Type = r.Type,
		})
	elseif b.Kinematic and typeof(driverId) ~= "number" then
		-- Aparcado: las motos y bicis salen volando; los coches se mueven un poco
		local rel = a.Vel - b.Vel
		if not (Crash.FallSpeed[b.Kind or ""] and launchParked(target, rel, a.Mass, flat(b.Pos - a.Pos))) then
			nudge(target, a, b, c)
		end
	end
	CrashService.damage(mine, c.Point, r.Closing)
	CrashService.damage(target, c.Point, r.Closing)
end

-- Golpe contra algo que no es otro vehículo (pared, tráfico de tu pantalla, autobús del juego…):
-- solo para los daños de chapa de tu vehículo
local function onBump(player: Player, info: any)
	if type(info) ~= "table" or type(info.Speed) ~= "number" or typeof(info.Point) ~= "Vector3" then
		return
	end
	local mine = VehicleService.rideModel(player)
	if not mine then
		return
	end
	local now = os.clock()
	if now - (bumpAt[player] or -math.huge) < 0.6 then
		return
	end
	bumpAt[player] = now
	local body = CrashService.bodyOf(mine)
	if not body or not Crash.collides(body.Kind) then
		return
	end
	local speed = info.Speed
	if speed ~= speed or speed > CrashService.maxSpeed(body.Kind) * Crash.Server.SpeedSlack + 6 then
		return
	end
	local reach = math.sqrt(body.Length * body.Length + body.Width * body.Width) / 2 + 4
	if (info.Point - body.Pos).Magnitude > reach + 6 then
		return
	end
	CrashService.damage(mine, info.Point, speed)
end

function CrashService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("Crash") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "Crash"
		created.Parent = remotes
		remote = created
	end
	Remote = remote
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player, action, a, b)
		local ok, err = pcall(function()
			if action == "Hit" then
				onHit(player, a, b)
			elseif action == "Bump" then
				onBump(player, a)
			end
		end)
		if not ok then
			warn("[CrashService] " .. tostring(err))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		bursts[player] = nil
		bumpAt[player] = nil
	end)

	-- Cada medio segundo: los vehículos que volaron se vuelven a aparcar cuando se paran; los daños
	-- se arreglan al aparcar (15 s después) o a los 2 minutos
	task.spawn(function()
		local repairEvery = 0
		while true do
			task.wait(0.5)
			local now = os.clock()
			for model, state in tumbling do
				local ok = pcall(function()
					local chassis = model:FindFirstChild("Chassis") :: BasePart?
					if not model.Parent or not chassis then
						tumbling[model] = nil
						return
					end
					Knock.rest(state, now, chassis.AssemblyLinearVelocity.Magnitude)
					local fell = chassis.Position.Y < -200
					if fell or (state.RestSince and now - state.RestSince > 2.5) or now - state.Since > 20 then
						tumbling[model] = nil
						model:SetAttribute("Knocked", nil) -- (VehicleService.parkOrphans lo aparca de pie)
					end
				end)
				if not ok then
					tumbling[model] = nil
				end
			end
			for key, at in pairAt do
				if now - at > 10 then
					pairAt[key] = nil
				end
			end
			repairEvery += 0.5
			if repairEvery >= 5 then
				repairEvery = 0
				for model, rec in damaged do
					if not model.Parent then
						damaged[model] = nil
					elseif (model:GetAttribute("Driver") == nil and now - rec.At > 15) or now - rec.At > 120 then
						pcall(repair, model)
					end
				end
			end
		end
	end)
end

return CrashService
