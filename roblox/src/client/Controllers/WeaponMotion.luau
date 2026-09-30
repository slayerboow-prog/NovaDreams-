-- WeaponMotion (cliente): el cuerpo con un arma, en todos los jugadores cercanos (capa 25 de PoseLayers,
-- después de la locomoción y antes de las reacciones a golpes). Las posturas salen de WeaponPose.
--
--   * Mira los atributos del dueño: Weapon (qué lleva), Aiming y AimPitch (apunta y hacia dónde),
--     Sprinting, Stance ("Crouch" / "Prone"), BusyMove (saltando una valla) y KO.
--   * Tu propio personaje usa lo de tu pantalla al momento (WeaponController llama a setLocal).
--   * El retroceso (recoil) y la recarga (reload) los avisan WeaponController y WeaponFx.
-- Los brazos se mezclan hacia la postura del arma (la animación de andar no los mueve); el tronco y
-- la cabeza se suman encima. Todo entra y sale suave: al desenfundar sube el peso en ~0,3 s.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Joints = require(ReplicatedStorage.Shared.Joints)
local WeaponPose = require(script.Parent.WeaponPose)
local PoseLayers = require(script.Parent.PoseLayers)

local WeaponMotion = {}

local player = Players.LocalPlayer

local JOINTS = {
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	LeftShoulder = "LeftUpperArm",
	RightElbow = "RightLowerArm",
	LeftElbow = "LeftLowerArm",
}

type Body = {
	Model: Model,
	Owner: Player,
	Root: BasePart,
	Humanoid: Humanoid,
	Joints: { [string]: any },
	Hold: number,
	Aim: number,
	Sprint: number,
	Busy: number,
	Crouch: number,
	Prone: number,
	Pitch: number,
	Recoil: number,
	RecoilV: number,
	ReloadStart: number,
	ReloadTime: number,
	Phase: number,
}

local bodies: { [Model]: Body } = {}
local localState = { Aim = 0, Pitch = 0, Wall = 0, SwayX = 0, SwayY = 0 }

local function bodyOf(model: Model?, owner: Player): Body?
	if not model or not model.Parent then
		return nil
	end
	local body = bodies[model]
	if body then
		-- (al aplicar el aspecto Roblox cambia las piezas y sus articulaciones: se vuelven a buscar)
		if Joints.stale(body.Joints, model) then
			body.Joints = Joints.collect(model, JOINTS)
		end
		return body
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	local joints = Joints.collect(model, JOINTS) -- (Motor6D o AnimationConstraint)
	if not joints.RightShoulder then
		return nil
	end
	body = {
		Model = model, Owner = owner, Root = root :: BasePart, Humanoid = humanoid, Joints = joints,
		Hold = 0, Aim = 0, Sprint = 0, Busy = 0, Crouch = 0, Prone = 0, Pitch = 0, Recoil = 0, RecoilV = 0,
		ReloadStart = 0, ReloadTime = 0, Phase = 0,
	}
	bodies[model] = body
	return body
end

local function approach(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * math.min(1, dt * rate)
end

-- Lo que pasa en tu pantalla (apuntar, hacia dónde, pared, balanceo)
function WeaponMotion.setLocal(aim: number, pitch: number, wall: number, swayX: number, swayY: number)
	localState.Aim, localState.Pitch, localState.Wall, localState.SwayX, localState.SwayY = aim, pitch, wall, swayX, swayY
end

-- Un disparo: el cuerpo acusa el retroceso (fuerza = Weapons Recoil.Body por la postura)
function WeaponMotion.recoil(model: Model?, strength: number)
	local owner = model and Players:GetPlayerFromCharacter(model)
	local body = owner and bodyOf(model, owner)
	if body then
		body.RecoilV += 20 * strength
	end
end

function WeaponMotion.reload(model: Model?, seconds: number)
	local owner = model and Players:GetPlayerFromCharacter(model)
	local body = owner and bodyOf(model, owner)
	if body then
		body.ReloadStart = os.clock()
		body.ReloadTime = seconds
	end
end

local StancesModule: any = nil

local function step(body: Body, dt: number, now: number)
	local owner = body.Owner
	local w = Weapons.get(owner:GetAttribute("Weapon"))
	local mine = owner == player
	local ko = owner:GetAttribute("KO") == true or body.Humanoid.Health <= 0
	local holding = w ~= nil and not ko and body.Humanoid.SeatPart == nil
	body.Hold = approach(body.Hold, if holding then 1 else 0, if holding then 7 else 9, dt)
	if body.Hold < 0.002 and not holding then
		bodies[body.Model] = nil
		return
	end
	local v = body.Root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	body.Phase = (body.Phase + dt * math.min(speed, 30) * 0.42) % (math.pi * 2)
	local sprinting = owner:GetAttribute("Sprinting") == true and speed > 10
	local stance = owner:GetAttribute("Stance")
	local busy = owner:GetAttribute("BusyMove") == true
	-- Correr baja el arma; al soltar o al apuntar vuelve arriba rápido (~0,2 s)
	body.Sprint = approach(body.Sprint, if sprinting then 1 else 0, if sprinting then 6 else 12, dt)
	body.Busy = approach(body.Busy, if busy then 1 else 0, 12, dt)
	-- Agachado: el mismo peso con el que Stances dobla el cuerpo (si lo lleva), para que el tronco y
	-- los brazos vayan a la par que las piernas; si no, por el atributo
	local seen = nil
	if StancesModule == nil then
		local ok, module = pcall(function()
			return require(script.Parent.Stances)
		end)
		StancesModule = if ok then module else false
	end
	if StancesModule then
		seen = StancesModule.crouchWeight(body.Model)
	end
	body.Crouch = if type(seen) == "number" then seen else approach(body.Crouch, if stance == "Crouch" then 1 else 0, 8, dt)
	body.Prone = approach(body.Prone, if stance == "Prone" then 1 else 0, 6, dt)
	local aimTarget, pitchTarget
	if mine then
		aimTarget, pitchTarget = localState.Aim, localState.Pitch
	else
		aimTarget = if owner:GetAttribute("Aiming") then 1 else 0
		pitchTarget = tonumber(owner:GetAttribute("AimPitch")) or 0
	end
	body.Aim = if mine then aimTarget else approach(body.Aim, aimTarget, 9, dt)
	body.Pitch = approach(body.Pitch, pitchTarget, if mine then 30 else 10, dt)
	body.Recoil, body.RecoilV = Weapons.spring(body.Recoil, body.RecoilV, if w then w.Recoil.Return * 14 else 150, dt)
	local reload = nil
	if body.ReloadTime > 0 then
		local t = (now - body.ReloadStart) / body.ReloadTime
		if t >= 1 then
			body.ReloadTime = 0
		else
			reload = t
		end
	end
	local weapon = w or Weapons.List.Pistola
	local _, stanceRecoil = Weapons.stanceFactor(if type(stance) == "string" then stance else nil)
	local pose = WeaponPose.pose({
		Hold = body.Hold,
		Aim = body.Aim * (1 - body.Busy),
		Pitch = body.Pitch,
		TwoHands = weapon.Hands == 2,
		Stock = weapon.Stock,
		Sprint = body.Sprint,
		Reload = reload,
		Recoil = body.Recoil,
		Body = weapon.Recoil.Body * stanceRecoil,
		Wall = if mine then localState.Wall else 0,
		SwayX = if mine then localState.SwayX else 0,
		SwayY = if mine then localState.SwayY else 0,
		Phase = body.Phase,
		Busy = body.Busy,
		Crouch = body.Crouch,
		Prone = body.Prone,
	})
	for name, target in pose.Arms do
		local joint = body.Joints[name]
		if joint then
			PoseLayers.write(joint, PoseLayers.read(joint):Lerp(WeaponPose.cframe(target), pose.Weight))
		end
	end
	for name, offset in pose.Add do
		local joint = body.Joints[name]
		if joint then
			PoseLayers.write(joint, WeaponPose.cframe(offset) * PoseLayers.read(joint))
		end
	end
end

function WeaponMotion.init()
	PoseLayers.add("WeaponMotion", 25, function(dt, now)
		local me = player.Character
		local myRoot = me and me:FindFirstChild("HumanoidRootPart") :: BasePart?
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if character and other:GetAttribute("Weapon") and not bodies[character] then
				local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (not myRoot or (root.Position - myRoot.Position).Magnitude < 150) then
					bodyOf(character, other)
				end
			end
		end
		for model, body in bodies do
			if not model.Parent then
				bodies[model] = nil
			else
				local ok, err = pcall(step, body, dt, now)
				if not ok then
					warn("[WeaponMotion] " .. tostring(err))
					bodies[model] = nil
				end
			end
		end
	end)
end

return WeaponMotion
