-- RidePose (cliente): la postura de quien va en un vehículo (cualquier edad).
--
--   * Conduciendo coche, autobús o camión: las manos en el volante (que gira con las curvas: una
--     mano sube y la otra baja, y mira hacia la curva) y las piernas estiradas hacia los pedales.
--   * Moto, bici y patinete: agarrado al manillar, echado hacia delante; en la moto y la bici, a
--     horcajadas (piernas más bajas y algo abiertas). En el patinete va de pie: las piernas no se tocan.
--   * De pasajero (copiloto, detrás, autobús, metro): manos en las piernas y mirando por la ventanilla.
--   * Detrás en la moto: agarrado a la cintura de quien conduce.
-- Entra suave al subir (medio segundo) y sale suave al bajar. Las posturas de brazos y cabeza son
-- las de WorkAnim (Drive, Handlebar, Passenger, Pillion); las piernas, SEAT_LEGS.
--
-- Es la capa 15 de PoseLayers (después de AgeMotion y antes de Locomotion): se retoca
-- Motor6D.Transform encima de la animación de sentarse de Roblox, sin acumular con las otras capas.
-- Las funciones puras (seatPoseFor, steerFor) se prueban fuera de Roblox: scripts/test-ride.luau

local WorkAnim = require(script.Parent.WorkAnim)

local RidePose = {}

local angles = CFrame.Angles
local ACTIVE_DISTANCE = 150
local MAX_ACTIVE = 16

local WHEEL = { Coche = true, Patrulla = true, Autobus = true, Camion = true, Bomberos = true, Lancha = true, Gaviota = true }
local BARS = { Moto = true, Bici = true, Patinete = true }
local STANDING = { Patinete = true, Monopatin = true }

-- Qué postura toca en ese asiento:
--   seatName = nombre del asiento, className = su clase, kind = atributo Kind del vehículo (nil si
--   no es un vehículo), pose = atributo Pose del asiento (los de pasajero lo llevan), metro = es un
--   asiento del metro. Devuelve la postura (nil = la de sentarse de siempre) y si va de pie.
function RidePose.seatPoseFor(seatName: string, className: string, kind: string?, pose: any, metro: boolean): (string?, boolean)
	if className == "VehicleSeat" and seatName == "DriverSeat" and kind then
		if WHEEL[kind] then
			return "Drive", false
		elseif BARS[kind] then
			return "Handlebar", STANDING[kind] == true
		end
		return nil, STANDING[kind] == true -- (monopatín: de pie, brazos libres)
	end
	if type(pose) == "string" and WorkAnim.get(pose) then
		return pose, false
	end
	if metro or kind ~= nil then
		return "Passenger", false -- (autobús, metro)
	end
	return nil, false -- un banco, una silla…
end

-- Piernas en cada postura (encima de la de sentarse): conduciendo, estiradas hacia los pedales;
-- a horcajadas en la moto, más bajas y algo abiertas
local SEAT_LEGS: { [string]: { Hip: number, Open: number, Knee: number } } = {
	Drive = { Hip = 0.1, Open = 0, Knee = 0.45 },
	Handlebar = { Hip = -0.3, Open = 0.1, Knee = 0.25 },
	Pillion = { Hip = -0.3, Open = 0.12, Knee = 0.2 },
}
RidePose.Legs = SEAT_LEGS

-- Cuánto se gira el volante (-1..1) según lo que gira el vehículo de un fotograma a otro
-- (el vehículo gira a la derecha cuando baja el ángulo)
function RidePose.steerFor(lastYaw: number?, yaw: number, dt: number): number
	if not lastYaw or dt <= 0 then
		return 0
	end
	local rate = ((yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi) / dt
	return math.clamp(-rate / 1.2, -1, 1)
end

local function smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

-- Más o menos giro que la animación (k = 1: igual; 0: nada)
local function scaled(cf: CFrame, k: number): CFrame
	if k >= 1 then
		return cf
	end
	local axis, angle = cf:ToAxisAngle()
	if math.abs(angle) < 1e-4 then
		return CFrame.new(cf.Position * k)
	end
	return CFrame.new(cf.Position * k) * CFrame.fromAxisAngle(axis, angle * k)
end

---------------------------------------------------------------------
-- En Roblox
---------------------------------------------------------------------

local JOINTS = { "Neck", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightHip", "LeftHip", "RightKnee", "LeftKnee" }
local ARMS = { RightShoulder = true, LeftShoulder = true, RightElbow = true, LeftElbow = true }

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Joints: { [string]: Motor6D },
	Weight: number, -- 0..1, suave
	Name: string?,
	Standing: boolean,
	Steer: number,
	Yaw: number?,
	Seed: number,
	Pose: WorkAnim.Pose,
}

local bodies: { [Model]: Body } = {}
local Layers: any = nil

local function seatOf(body: Body): (string?, boolean, BasePart?)
	local seat = body.Humanoid.SeatPart
	if not seat then
		return nil, false, nil
	end
	local vehicle = seat:FindFirstAncestorOfClass("Model")
	local kind = vehicle and vehicle:GetAttribute("Drivable") and vehicle:GetAttribute("Kind")
	local name, standing = RidePose.seatPoseFor(seat.Name, seat.ClassName, if type(kind) == "string" then kind else nil, seat:GetAttribute("Pose"), seat:HasTag("MetroSeat"))
	return name, standing, seat
end

local function update(body: Body, t: number, dt: number)
	local name, standing, seat = seatOf(body)
	if name then
		body.Name = name
		body.Standing = standing
	end
	body.Weight = smooth(body.Weight, if name then 1 else 0, if name then 4 else 6, dt)
	local yaw: number? = nil
	if seat then
		local look = seat.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
	body.Steer = smooth(body.Steer, if yaw then RidePose.steerFor(body.Yaw, yaw, dt) else 0, 5, dt)
	body.Yaw = yaw
	local S = if body.Name then body.Weight else 0
	if S < 0.001 then
		body.Name = nil
		return -- (lo que no se escribe, PoseLayers lo devuelve a la animación)
	end
	local p = body.Pose
	WorkAnim.clear(p)
	local work = WorkAnim.get(body.Name)
	if work then
		work.Pose(t, body.Seed, p)
	end
	if body.Name == "Drive" or body.Name == "Handlebar" then
		-- Al girar, una mano sube y la otra baja, y mira hacia la curva
		local k = if body.Name == "Drive" then 0.22 else 0.08
		p.rx -= body.Steer * k
		p.lx += body.Steer * k
		p.ny -= body.Steer * 0.18
	end
	-- (los mismos ángulos que AgeMotion y ActorLife: ver WorkAnim)
	local offsets: { [string]: CFrame } = {
		Neck = angles(p.np * S, p.ny * S, p.nr * S),
		Waist = angles(p.wp * S, p.wy * S, p.wr * S),
		RightShoulder = angles(p.rx * S, p.rt * S, p.rz * S),
		LeftShoulder = angles(p.lx * S, -p.lt * S, -p.lz * S),
		RightElbow = angles(p.re * S, 0, 0),
		LeftElbow = angles(p.le * S, 0, 0),
	}
	local legs = SEAT_LEGS[body.Name :: string]
	if legs and not body.Standing then
		offsets.RightHip = angles(legs.Hip * S, 0, legs.Open * S)
		offsets.LeftHip = angles(legs.Hip * S, 0, -legs.Open * S)
		offsets.RightKnee = angles(legs.Knee * S, 0, 0)
		offsets.LeftKnee = angles(legs.Knee * S, 0, 0)
	end
	for jointName, joint in body.Joints do
		local offset = offsets[jointName]
		if offset and joint.Parent then
			local out = Layers.read(joint)
			-- Los brazos van donde toca (volante, manillar, piernas), no donde los deja sentarse
			if ARMS[jointName] then
				out = scaled(out, 1 - S)
			end
			Layers.write(joint, offset * out)
		end
	end
end

local function track(model: Model, humanoid: Humanoid)
	if bodies[model] or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	local joints = {}
	for _, name in JOINTS do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joints[name] = joint
		end
	end
	local body: Body = {
		Model = model,
		Humanoid = humanoid,
		Joints = joints,
		Weight = 0,
		Name = nil,
		Standing = false,
		Steer = 0,
		Yaw = nil,
		Seed = math.random() * 100,
		Pose = {} :: any,
	}
	WorkAnim.clear(body.Pose)
	bodies[model] = body
end

function RidePose.init()
	local Players = game:GetService("Players")
	Layers = require(script.Parent.PoseLayers)

	-- Quién va sentado cerca (cada medio segundo): los jugadores
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local count = 0
			for _, other in Players:GetPlayers() do
				local character = other.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and humanoid and root and humanoid.SeatPart and count < MAX_ACTIVE and (root.Position - from).Magnitude < ACTIVE_DISTANCE then
					count += 1
					track(character, humanoid)
				end
			end
			-- Fuera los que ya se bajaron del todo (o se fueron)
			for model, body in bodies do
				if not model.Parent or body.Humanoid.Parent ~= model or (body.Weight < 0.001 and not body.Humanoid.SeatPart) then
					bodies[model] = nil
				end
			end
		end
	end)

	Layers.add("RidePose", 15, function(dt, t)
		for model, body in bodies do
			if model.Parent then
				local ok, err = pcall(update, body, t, dt)
				if not ok then
					warn("[RidePose] " .. tostring(err))
					bodies[model] = nil
				end
			end
		end
	end)
end

return RidePose
