-- WeaponController (cliente): empuñar, apuntar, disparar y recargar; la mira, las balas, la tienda
-- de la Armería y el test de la licencia. El servidor (WeaponService) decide si el disparo cuenta.
--
-- Controles (solo con un arma en la mano: se empuña eligiendo su casilla de la barra rápida):
--   Ordenador: clic derecho (mantener) apuntar · clic izquierdo disparar · R recargar · T semi/auto
--              · Mayús apuntando con mira telescópica = contener la respiración
--   Mando:     LT apuntar · RT disparar · cruceta izquierda recargar · cruceta arriba semi/auto
--   Móvil (estilo shooter móvil): el Atacar grande pasa a ser Disparar (mantener = ráfaga en las
--              automáticas y, en las que solo son semiautomáticas, tiro tras tiro a su cadencia;
--              al gastar la última bala recarga sola), Apuntar encima (toca para apuntar /
--              dejar de apuntar), Recargar con las balas «12/90» y un SEGUNDO Disparar a la derecha del
--              joystick (pulgar izquierdo). Todo a la vez: andar + disparar + apuntar + saltar, cada
--              botón con su dedo. La cámara la gira la de Roblox (arrastrar un dedo por la pantalla, también
--              con otro dedo en un botón). «Cambiar» (o Q / cruceta derecha) pasa a la siguiente arma.
--
-- Ayuda al apuntar (shared/AimAssist; ⚙️ «Ayuda al apuntar», shared/ShooterPrefs): SOLO hacia enemigos
-- (alienígenas de la invasión y los de tu combate de misión; nunca jugadores ni gente de la calle).
-- Justo DESPUÉS de la cámara de Roblox: fricción (con la mira encima tu giro va más despacio) e imán
-- suave (solo mientras giras la cámara o andas: quieto, nunca se mueve sola) y el imán de la bala (un
-- disparo que pasa rozando le da). En el móvil, «Disparo automático»: con la mira encima de un enemigo
-- que se ve, dispara solo. Encima del enemigo salen unas esquinas (fijado).
-- Lo que se nota al acertar: aspa blanca (amarilla y más grande en la cabeza, roja si cae), un
-- chasquido distinto para cada cosa y, si están puestos, los números de daño de los alienígenas.
--   Menú de comandos: Disparar, Apuntar, Recargar, Objetos, Defensa, Huir.
--
-- Con el arma en la mano la cámara va al hombro derecho (shoulderCamera, con Humanoid.CameraOffset: la
-- cámara de Roblox sigue mandando, nunca se le fija el CFrame). Apuntar (~0,17 s): la cámara se acerca
-- (zoom de Roblox), el campo de visión se cierra (FootCamera.setAim; con mira telescópica mucho más), el
-- personaje gira hacia donde mira la cámara (AutoRotate apagado; se gira el cuerpo, nunca la cámara),
-- anda más despacio (servidor) y el tronco y los brazos siguen la inclinación de la cámara
-- (WeaponMotion). En ordenador el ratón se queda en el centro mientras apuntas.
-- Mira: círculo con 4 marcas que se abre con la dispersión (moverte, saltar, disparar seguido) y se
-- pone roja encima de alguien (apagada si algo se cruza entre el arma y lo que miras); aspa al
-- acertar. Balas: "12 / 36" arriba a la derecha, junto al minimapa (UI/HudLayout: Items.Ammo).
-- Retroceso: lo acusan el cuerpo y los brazos (WeaponMotion), la mira se abre y la cámara da un
-- golpecito hacia arriba que VUELVE solo a su sitio (pequeño: se lee, no marea). Recargando: barra debajo
-- de la mira y «RECARGANDO» en las balas; con pocas balas, aviso. Agachado y tumbado (atributo Stance) se tiene menos dispersión
-- y retroceso; tumbado no se apunta hacia atrás ni al suelo. Saltando una valla (BusyMove) el arma
-- baja y no se dispara; corriendo sí se dispara (el servidor te pone a andar mientras disparas);
-- contra una pared el cañón se levanta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local AimAssist = require(ReplicatedStorage.Shared.AimAssist)
local ShooterPrefs = require(ReplicatedStorage.Shared.ShooterPrefs)
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local WeaponFx = require(script.Parent.WeaponFx)
local WeaponMotion = require(script.Parent.WeaponMotion)
local FootCamera = require(script.Parent.FootCamera)
local InventoryUI = require(script.Parent.InventoryUI)
local SoundFx = require(script.Parent.SoundFx)
local Prompts = require(script.Parent.Prompts)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local WeaponController = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB
local Remote: RemoteEvent

local AIM = Weapons.Aim

-- Estado local
local wantAim = false
local aimAlpha = 0
local trigger = false
local lastShot = -math.huge
local burst = 0
local bloom = 0
local localMag: number? = nil
local reloadingUntil = 0
local hitMarker = 0
local hitKill = false
local hitHead = false
local savedMax: number? = nil
local startDistance = 12
local holdBreath = false
local lastPitchSent, pitchSentAt = 0, 0
local wallAmount = 0
local mouseLocked = false
local autoRotateSaved: boolean? = nil
-- Cámara al hombro (con el arma en la mano, apuntando o no; ver shoulderCamera): cuánto está puesta
-- (0..1), el desplazamiento (derecha, arriba) que pide el arma suavizado (agacharte o apuntar no hace
-- saltar la cámara) y la parte que cabe sin meterse en una pared (entra de golpe, sale suave).
-- Se pone en Humanoid.CameraOffset: la cámara de Roblox lo usa y sigue girando con el dedo o el ratón
local shoulderAlpha = 0
local aimOffset: Vector2? = nil
local shoulderReach = 1
local baseDistance: number? = nil -- de la cámara de Roblox a tu cabeza
local offsetSet = false -- (hay un CameraOffset nuestro puesto: quitarlo al guardar el arma)
local WALL_GAP = 0.6
-- Móvil: cada dedo que tiene el gatillo (los dos botones de Disparar, el ratón, el mando…). Se dispara
-- mientras haya alguno: soltar uno no corta la ráfaga del otro
local holds: { [string]: boolean } = {}
local resumeAimAfterMenu = false -- (se soltó la mira al abrir un menú: vuelve al cerrarlo si sigue pulsada)
local aimInputHeld: () -> boolean
-- ¿Hay una ventana abierta (mochila, teléfono, mapa, tienda, una conversación, una cinemática…)?
-- Entonces ni mira ni disparo. Main.client añade lo que este módulo no ve.
local menuChecks: { () -> boolean } = {}
-- Ayuda al apuntar, golpe de cámara del retroceso y recarga
type Assisted = { Model: Model, Pos: Vector3, Radius: number }
local candidates: { Assisted } = {}
local candidatesAt = 0
local assistTarget: Assisted? = nil
local assistAngle: number? = nil
local lastLook: Vector3? = nil
local kickUp, kickSide = 0, 0 -- grados (lo que debería estar subida la cámara ahora)
local kickAppliedUp, kickAppliedSide = 0, 0
local reloadStart = 0
local autoHeld = false
-- El número de cada disparo (con la semilla del servidor, WeaponSeed, salen los mismos «dados» de la
-- dispersión aquí y allí: Weapons.shotRoll; el trazo que ves va donde va la bala de verdad)
local shotN = 0
-- La mira se abre y se cierra suave (antes saltaba de golpe con cada disparo)
local reticleShown = 0
local reticleAt = 0
local ammoRefreshAt = 0
local autoReloadAt: number? = nil

-- Interfaz
local gui: ScreenGui
local reticle: Frame
local ticks: { Frame } = {}
local ring: UIStroke
local dot: Frame
local marker: Frame
local ammoPanel: Frame
local ammoText: TextLabel
local ammoInfo: TextLabel
local scope: Frame
local lockFrame: Frame
local reloadBar: Frame
local reloadFill: Frame
local hintLabel: TextLabel
local shopPanel: Frame? = nil
local quizPanel: Frame? = nil

local function weapon(): Weapons.Weapon?
	return Weapons.get(player:GetAttribute("Weapon"))
end

local function parts(): (Humanoid?, BasePart?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChild("Head") :: BasePart?
end

local function stance(): string?
	local s = player:GetAttribute("Stance")
	return if type(s) == "string" then s else nil
end

local function gunModel(character: Model?): Model?
	local model = character and character:FindFirstChild("Arma")
	return if model and model:IsA("Model") then model else nil
end

local function muzzleOf(model: Model?): CFrame?
	local grip = model and model.PrimaryPart
	local boca = grip and grip:FindFirstChild("Boca") :: Attachment?
	return boca and boca.WorldCFrame
end

local function mag(): number
	return localMag or tonumber(player:GetAttribute("WeaponMag")) or 0
end

-- Arma bajada: solo saltando una valla o tumbándose. Corriendo SÍ se dispara (el servidor te pone a
-- andar mientras disparas) y se apunta (apuntando no se corre).
local function lowered(): boolean
	return player:GetAttribute("BusyMove") == true
end

function WeaponController.armed(): boolean
	return weapon() ~= nil
end

function WeaponController.isAiming(): boolean
	return wantAim and weapon() ~= nil
end

---------------------------------------------------------------------
-- Empuñar y guardar
---------------------------------------------------------------------

function WeaponController.equip(ref: string?)
	if Remote then
		Remote:FireServer("Equip", ref)
	end
	localMag = nil
	if not ref then
		WeaponController.setAim(false)
	end
end

function WeaponController.holster()
	WeaponController.equip(nil)
end

function WeaponController.setAim(on: boolean)
	local want = on and weapon() ~= nil
	if want == wantAim then
		return
	end
	wantAim = want
	if want then
		local camera = workspace.CurrentCamera
		-- (la distancia de la cámara de Roblox a tu cabeza)
		startDistance = baseDistance or (camera.CFrame.Position - camera.Focus.Position).Magnitude
		savedMax = savedMax or player.CameraMaxZoomDistance
	end
	if Remote then
		Remote:FireServer("Aim", want)
	end
end

-- ¿Sigue pulsado el botón de apuntar (botón derecho del ratón o gatillo izquierdo del mando)?
function aimInputHeld(): boolean
	local ok, held = pcall(function()
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2)
	end)
	return ok and held == true
end

function WeaponController.toggleAim()
	WeaponController.setAim(not wantAim)
end

---------------------------------------------------------------------
-- Disparar
---------------------------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function ignore(): { Instance }
	local list: { Instance } = {}
	if player.Character then
		table.insert(list, player.Character)
	end
	local fx = workspace.CurrentCamera:FindFirstChild("WeaponFx")
	if fx then
		table.insert(list, fx)
	end
	return list
end

-- Hacia dónde apunta la mira: (punto, pieza). El rayo sale del centro de la pantalla (la cámara va
-- al hombro, así que la mira queda al lado del personaje), pero empieza a la altura de tu cabeza a lo
-- largo del rayo: lo que haya entre la cámara y tú (una farola, una esquina) no cuenta. Luego la bala
-- va de la boca del arma (el servidor: de la cabeza) a ese punto.
local function aimPoint(range: number): (Vector3, Instance?)
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local _, _, head = parts()
	local origin = Weapons.aimStart(ray.Origin, ray.Direction, if head then head.Position else nil)
	rayParams.FilterDescendantsInstances = ignore()
	local result = workspace:Raycast(origin, ray.Direction * (range + 20), rayParams)
	if result then
		return result.Position, result.Instance
	end
	return origin + ray.Direction * range, nil
end

-- ¿Choca la bala con algo antes de llegar a donde mira la mira? (de la cabeza, como el servidor)
-- Devuelve dónde choca o nil si el camino está libre.
local function blockedAt(target: Vector3): Vector3?
	local _, _, head = parts()
	if not head then
		return nil
	end
	local path = target - head.Position
	if path.Magnitude < 1.5 then
		return nil
	end
	rayParams.FilterDescendantsInstances = ignore()
	local hit = workspace:Raycast(head.Position, path.Unit * (path.Magnitude - 1), rayParams)
	return if hit then hit.Position else nil
end

local function isPerson(part: Instance?): boolean
	local node = part and part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node ~= player.Character
		end
		node = node.Parent
	end
	return false
end

---------------------------------------------------------------------
-- Ayuda al apuntar (solo enemigos)
---------------------------------------------------------------------

local function profileName(): string
	local gamepad = false
	pcall(function()
		gamepad = UserInputService.GamepadEnabled and not UserInputService.MouseEnabled
	end)
	return AimAssist.profileFor(TouchLayout.isTouch(), gamepad)
end

local function assistOn(): (boolean, AimAssist.Profile)
	local name = profileName()
	return ShooterPrefs.assistOn(player:GetAttribute("ShooterAssist") or ShooterPrefs.Defaults.Assist, name), AimAssist.Profiles[name]
end
WeaponController.assistOn = assistOn

local function pref(key: string): any
	local v = player:GetAttribute(ShooterPrefs.Attributes[key])
	if v == nil then
		return (ShooterPrefs.Defaults :: any)[key]
	end
	return v
end

-- Los enemigos a los que se puede ayudar a apuntar: alienígenas (InvasionTarget) de tierra y los de tu
-- combate de misión. Nunca jugadores ni gente de la calle.
local function refreshCandidates()
	table.clear(candidates)
	local folder = workspace:FindFirstChild("Invasion")
	local groundFolder = folder and folder:FindFirstChild("Ground")
	for _, m in if groundFolder then groundFolder:GetChildren() else {} do
		if m:IsA("Model") and m.PrimaryPart and AimAssist.isEnemy({ InvasionTarget = m:GetAttribute("InvasionTarget") }) and (tonumber(m:GetAttribute("Hp")) or 1) > 0 then
			local root = m.PrimaryPart :: BasePart
			local h = root.Size.Y
			table.insert(candidates, { Model = m, Pos = root.Position + Vector3.new(0, h * 0.12, 0), Radius = math.max(1, h * 0.18) })
		end
	end
	for _, m in CollectionService:GetTagged("MissionEnemy") do
		if m:IsA("Model") and m:GetAttribute("Owner") == player.UserId and not m:GetAttribute("EnemyDown") and not Players:GetPlayerFromCharacter(m) then
			local ok, pivot = pcall(m.GetPivot, m)
			if ok then
				table.insert(candidates, { Model = m, Pos = pivot.Position, Radius = 1.2 })
			end
		end
	end
end

-- ¿Es esta pieza de ese modelo? (subiendo por los padres)
local function inside(part: Instance?, model: Instance): boolean
	local node = part
	for _ = 1, 8 do
		if not node then
			return false
		end
		if node == model then
			return true
		end
		node = node.Parent
	end
	return false
end

local function updateAssist(look: Vector3, origin: Vector3, p: AimAssist.Profile)
	local now = os.clock()
	if now - candidatesAt > 0.2 then
		candidatesAt = now
		refreshCandidates()
	end
	local list = {}
	for _, c in candidates do
		if c.Model.Parent then
			-- (la posición de ahora mismo: se mueven)
			local root = c.Model.PrimaryPart
			if root and c.Model:GetAttribute("InvasionTarget") then
				c.Pos = root.Position + Vector3.new(0, root.Size.Y * 0.12, 0)
			end
			-- (un caído no se fija: ni el alienígena sin vida ni el enemigo de misión en el suelo)
			local dead = (tonumber(c.Model:GetAttribute("Hp")) or 1) <= 0 or c.Model:GetAttribute("EnemyDown") ~= nil
			table.insert(list, { Id = c, Pos = c.Pos, Radius = c.Radius, Dead = dead })
		end
	end
	local best, angle = AimAssist.pick(look, origin, list, p)
	assistTarget = if best then best.Id :: any else nil
	assistAngle = if best then angle else nil
end

-- Gira la cámara (después de la de Roblox) alrededor de su foco: yaw a la izquierda, pitch arriba
local function turnCamera(camera: Camera, dyaw: number, dpitch: number)
	if math.abs(dyaw) < 1e-6 and math.abs(dpitch) < 1e-6 then
		return
	end
	local cf = camera.CFrame
	local look = cf.LookVector
	local pitch = math.asin(math.clamp(look.Y, -1, 1))
	dpitch = math.clamp(pitch + dpitch, math.rad(-80), math.rad(80)) - pitch
	local focus = camera.Focus.Position
	local rel = cf.Position - focus
	local r = CFrame.fromAxisAngle(Vector3.yAxis, dyaw) * CFrame.fromAxisAngle(cf.RightVector, dpitch)
	local newRel = r:VectorToWorldSpace(rel)
	local newLook = r:VectorToWorldSpace(look)
	camera.CFrame = CFrame.lookAt(focus + newRel, focus + newRel + newLook)
end

local function yawPitch(v: Vector3): (number, number)
	return math.atan2(-v.X, -v.Z), math.asin(math.clamp(v.Y, -1, 1))
end

-- Justo DESPUÉS de la cámara de Roblox: fricción, imán suave y el golpe del retroceso
local function afterCamera(dt: number)
	local camera = workspace.CurrentCamera
	local w = weapon()
	local humanoid, root = parts()
	if not w or not humanoid or not root or camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= humanoid or WeaponController.menuOpen() then
		lastLook = nil
		assistTarget, assistAngle = nil, nil
		kickUp, kickSide, kickAppliedUp, kickAppliedSide = 0, 0, 0, 0
		return
	end
	local on, profile = assistOn()
	local cf = camera.CFrame
	local look = cf.LookVector
	local dyaw, dpitch = 0, 0
	if on then
		updateAssist(look, cf.Position, profile)
	else
		assistTarget, assistAngle = nil, nil
	end
	local turning = false
	if lastLook then
		local y0, p0 = yawPitch(lastLook)
		local y1, p1 = yawPitch(look)
		local uy = (y1 - y0 + math.pi) % (2 * math.pi) - math.pi
		local up = p1 - p0
		turning = math.abs(uy) + math.abs(up) > 1e-4
		if on and assistTarget and turning then
			-- Fricción: con la mira encima, una parte de tu giro no se aplica
			local f = AimAssist.friction(assistAngle, profile)
			dyaw -= uy * (1 - f)
			dpitch -= up * (1 - f)
		end
	end
	if on and assistTarget then
		local moving = humanoid.MoveDirection.Magnitude > 0.1
		local my, mp = AimAssist.magnet(look, cf.Position, assistTarget.Pos, profile, dt, turning or moving or trigger)
		dyaw += my
		dpitch += mp
	end
	-- El golpe del retroceso (sube y vuelve solo)
	local decay = math.exp(-dt * 10)
	kickUp *= decay
	kickSide *= decay
	dpitch += math.rad(kickUp - kickAppliedUp)
	dyaw += math.rad(kickSide - kickAppliedSide)
	kickAppliedUp, kickAppliedSide = kickUp, kickSide
	turnCamera(camera, dyaw, dpitch)
	lastLook = camera.CFrame.LookVector
end

local function dryFire(w: Weapons.Weapon)
	local _, root = parts()
	SoundFx.play("ArmaSeco", 1, 1, root)
	-- Sin balas: recarga sola si tienes munición
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	if reserve ~= 0 then
		WeaponController.reload()
	end
	local _ = w
end

function WeaponController.fire()
	local w = weapon()
	local humanoid, root, head = parts()
	if not w or not humanoid or not root or not head or humanoid.Health <= 0 or humanoid.SeatPart then
		return
	end
	local now = os.clock()
	if now < reloadingUntil or not Weapons.ready(w, lastShot, now, 0) then
		return
	end
	if lowered() or player:GetAttribute("KO") then
		return
	end
	if WeaponController.menuOpen() then
		return -- (con la mochila, el teléfono o el mapa abiertos no se dispara)
	end
	if wallAmount > 0.5 then
		return -- el cañón choca con la pared
	end
	if mag() <= 0 then
		lastShot = now
		dryFire(w)
		return
	end
	-- Ráfaga, dispersión y retroceso
	burst = if now - lastShot <= Weapons.interval(w) * 1.8 then burst + 1 else 1
	bloom = Weapons.bloomAfter(w, if burst == 1 then 0 else bloom, now - lastShot)
	lastShot = now
	localMag = mag() - 1
	local target, aimedPart = aimPoint(w.Range)
	-- Imán de la bala (solo enemigos): si pasa rozando, va a él (salvo que ya le des en la cabeza)
	local on, profile = assistOn()
	if on and assistTarget and not (aimedPart and assistTarget.Model.Parent and inside(aimedPart, assistTarget.Model)) then
		local camera = workspace.CurrentCamera
		local origin = camera.CFrame.Position
		local bent = AimAssist.bend(origin, target - origin, assistTarget.Pos, profile)
		if bent ~= target - origin then
			target = assistTarget.Pos
		end
	end
	local st = stance()
	if st == "Prone" then
		local look = root.CFrame.LookVector
		local dir = Weapons.clampProne(if math.abs(look.Y) > 0.8 then root.CFrame.UpVector else look, target - head.Position)
		target = head.Position + dir * (target - head.Position).Magnitude
	else
		-- Mirando hacia donde disparas (también sin apuntar)
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		if flat.Magnitude > 0.5 and aimAlpha < 0.5 then
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
		end
	end
	-- (el siguiente número de disparo: el servidor lo acepta si es el siguiente o poco más)
	local serverN = tonumber(player:GetAttribute("WeaponShotN")) or 0
	shotN = math.max(shotN, serverN) + 1
	Remote:FireServer("Fire", target, shotN)
	-- Recarga sola al gastar la última bala (si te quedan en la mochila), sin tener que tocar nada
	if localMag == 0 and (tonumber(player:GetAttribute("WeaponAmmo")) or 0) ~= 0 then
		autoReloadAt = now + 0.25
	end

	-- Lo que se ve y se oye al momento en tu pantalla
	local model = gunModel(player.Character)
	local muzzle = muzzleOf(model) or head.CFrame
	-- (la bala sale del arma: si algo se cruza antes del punto de la mira, el trazo acaba ahí)
	local shown = blockedAt(target) or target
	local shotCf = CFrame.lookAt(muzzle.Position, shown)
	WeaponFx.muzzle(shotCf, w)
	local seed = tonumber(player:GetAttribute("WeaponSeed"))
	local spread = Weapons.spread(w, { Aiming = aimAlpha > 0.5, Speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude, Airborne = humanoid.FloorMaterial == Enum.Material.Air, Stance = st, Bloom = bloom, First = burst == 1 })
	for pellet = 1, math.min(w.Pellets, 4) do
		-- (los mismos dados que el servidor: el trazo cae donde cae la bala)
		local u, v = if seed then Weapons.shotRoll(seed, shotN, pellet) else math.random(), math.random()
		local d = Weapons.scatter((shown - muzzle.Position).Unit, spread, u, v)
		WeaponFx.tracer(muzzle.Position, muzzle.Position + d * (shown - muzzle.Position).Magnitude, w)
	end
	WeaponFx.shotSound(w, muzzle.Position)
	WeaponFx.casings(model, w, "Shot")
	WeaponFx.slide(model, localMag == 0, true)
	-- Retroceso: lo acusan el cuerpo y los brazos (la cámara no salta: la mueve solo el jugador)
	local _, stanceRecoil = Weapons.stanceFactor(st)
	WeaponMotion.recoil(player.Character, stanceRecoil)
	-- Golpecito de cámara (vuelve solo; más suave en el móvil y apuntando)
	local up, side = Weapons.recoilKick(w, burst)
	local k = (if TouchLayout.isTouch() then 0.22 else 0.35) * stanceRecoil * (if aimAlpha > 0.5 then 0.75 else 1)
	kickUp = math.min(kickUp + up * k, 3.5)
	kickSide = math.clamp(kickSide + side * k * 0.6, -1.5, 1.5)
end

-- Cambiar a la siguiente arma que llevas (Q, cruceta derecha o «Cambiar» en el móvil)
function WeaponController.nextWeapon()
	local refs = InventoryUI.weaponRefs()
	if #refs == 0 then
		return
	end
	local current = player:GetAttribute("Weapon")
	local i = table.find(refs, current) or 0
	local nextRef = refs[i % #refs + 1]
	if nextRef ~= current then
		WeaponController.equip(nextRef)
		SoundFx.play("Corredera", 0.5, 1.1)
	end
end

function WeaponController.reload()
	local w = weapon()
	if not w or os.clock() < reloadingUntil then
		return
	end
	local loaded = mag()
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	if loaded >= Weapons.capacity(w, loaded) or reserve == 0 then
		return
	end
	Remote:FireServer("Reload")
end

function WeaponController.cycleMode()
	local w = weapon()
	if w and #w.Modes > 1 then
		Remote:FireServer("Mode")
	end
end

-- El gatillo de un dedo (o del ratón / mando: "Main"). Se dispara mientras alguno lo mantenga: con dos
-- botones de Disparar, soltar uno no corta la ráfaga del otro. Pulsar uno nuevo con el otro ya
-- pulsado no dispara de más (la cadencia manda).
local function holdTrigger(source: string, down: boolean)
	local was = trigger
	holds[source] = if down then true else nil
	trigger = next(holds) ~= nil
	if down then
		WeaponController.fire()
	elseif was and not trigger then
		if burst > 0 then
			local w = weapon()
			if w then
				WeaponFx.barrelSmoke(gunModel(player.Character), burst, w)
			end
		end
	end
end
WeaponController.holdTrigger = holdTrigger

local function setTrigger(down: boolean)
	holdTrigger("Main", down)
end
WeaponController.setTrigger = setTrigger

local function dropTrigger()
	table.clear(holds)
	trigger = false
	autoHeld = false
end

-- ¿Está el gatillo pulsado? (pruebas y la mira)
function WeaponController.triggerHeld(): boolean
	return trigger
end

-- Más ventanas que tapan la pantalla (Main.client: mapa, teléfono, ❓, diario…)
function WeaponController.addMenuCheck(check: () -> boolean)
	table.insert(menuChecks, check)
end

-- ¿Hay una ventana grande, una conversación o una cinemática? (sin mira y sin disparar)
function WeaponController.menuOpen(): boolean
	if player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true then
		return true
	end
	if InventoryUI.isOpen() or Dialog.anyOpen() then
		return true
	end
	for _, check in menuChecks do
		local ok, value = pcall(check)
		if ok and value == true then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Lo que llega del servidor
---------------------------------------------------------------------

local function onShot(data: { [string]: any })
	local w = Weapons.get(data.W)
	local shooter = data.S :: Player?
	if not w or not shooter then
		return
	end
	local character = shooter.Character
	local model = gunModel(character)
	if shooter ~= player then
		local muzzle = muzzleOf(model)
		local hits = data.H or {}
		if muzzle and #hits > 0 then
			local target = hits[1].P
			WeaponFx.muzzle(CFrame.lookAt(muzzle.Position, target), w)
			for i = 1, math.min(#hits, 4) do
				WeaponFx.tracer(muzzle.Position, hits[i].P, w)
			end
			WeaponFx.shotSound(w, muzzle.Position)
			WeaponFx.casings(model, w, "Shot")
			local st = shooter:GetAttribute("Stance")
			local _, stanceRecoil = Weapons.stanceFactor(if type(st) == "string" then st else nil)
			WeaponMotion.recoil(character, stanceRecoil)
		end
		WeaponFx.slide(model, data.M == 0, true)
	else
		localMag = nil -- (el servidor manda)
	end
	for _, hit in data.H or {} do
		WeaponFx.impact(hit, w)
	end
	-- La gente de la calle huye si oye disparos de verdad cerca
	if w.Kind == "Real" and character then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local camera = workspace.CurrentCamera
		if root and (camera.CFrame.Position - root.Position).Magnitude < Weapons.Fx.HearDistance then
			local ok, Ambient = pcall(require, script.Parent.Ambient)
			if ok and Ambient.panic then
				Ambient.panic(root.Position, Weapons.Fx.PanicRadius)
			end
		end
	end
end

local function onReload(data: { [string]: any })
	local w = Weapons.get(data.W)
	local shooter = data.S :: Player?
	if not w or not shooter then
		return
	end
	local character = shooter.Character
	local model = gunModel(character)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local seconds = tonumber(data.T) or 1
	if shooter == player then
		reloadStart = os.clock()
		reloadingUntil = os.clock() + seconds
	end
	WeaponMotion.reload(character, seconds)
	local at = if root then root.Position else Vector3.zero
	if data.K == "Shells" then
		local per = w.Reload.PerRound or 0.5
		local count = math.floor((seconds - (w.Reload.Start or 0)) / per + 0.5)
		for i = 1, count do
			task.delay((w.Reload.Start or 0) + (i - 0.5) * per, function()
				WeaponFx.soundAt("CargadorDentro", at, 0.8, 1.2)
			end)
		end
		task.delay(seconds - 0.1, function()
			WeaponFx.soundAt("Corredera", at, 0.9, 1)
		end)
		return
	end
	task.delay(seconds * 0.15, function()
		WeaponFx.soundAt("CargadorFuera", at, 0.8, 1)
		if w.Casing == "Revolver" then
			WeaponFx.casings(model, w, "Reload", data.Spent)
		elseif w.Kind ~= "Toy" then
			WeaponFx.dropMag(model)
		end
	end)
	task.delay(seconds * 0.6, function()
		WeaponFx.soundAt("CargadorDentro", at, 0.9, 1)
		WeaponFx.showMag(model)
	end)
	if data.K == "Empty" and w.Kind == "Real" then
		task.delay(seconds * 0.85, function()
			WeaponFx.soundAt("Corredera", at, 1, 1)
			WeaponFx.slide(model, false)
		end)
	end
end

---------------------------------------------------------------------
-- Interfaz: mira, marcador de acierto, balas y mira telescópica
---------------------------------------------------------------------

-- Números de daño (alienígenas): saltan donde das, amarillos en la cabeza; como mucho 8 a la vez
local numberPool: { BillboardGui } = {}
local numberAnchor: Part? = nil
function WeaponController.damageNumber(at: Vector3, amount: number, head: boolean, kill: boolean)
	if amount <= 0 then
		return
	end
	local camera = workspace.CurrentCamera
	if (camera.CFrame.Position - at).Magnitude > 220 then
		return
	end
	local gui: BillboardGui? = nil
	for _, g in numberPool do
		if not g.Enabled then
			gui = g
			break
		end
	end
	if not gui then
		if #numberPool >= 8 then
			gui = numberPool[1]
			table.remove(numberPool, 1)
			table.insert(numberPool, gui :: BillboardGui)
		else
			local folder = camera:FindFirstChild("WeaponFx") or create("Folder", { Name = "WeaponFx", Parent = camera })
			if not numberAnchor or not numberAnchor.Parent then
				numberAnchor = create("Part", { Name = "Numeros", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1), Parent = folder })
			end
			local g = create("BillboardGui", { Name = "Dano", Size = UDim2.fromOffset(90, 34), AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 260, Parent = player:WaitForChild("PlayerGui") }) :: BillboardGui
			create("TextLabel", { Name = "T", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextScaled = true, TextStrokeTransparency = 0.2, Parent = g })
			table.insert(numberPool, g)
			gui = g
		end
	end
	local g = gui :: BillboardGui
	local label = g:FindFirstChild("T") :: TextLabel
	g.Adornee = numberAnchor
	g.StudsOffsetWorldSpace = at + Vector3.new((math.random() - 0.5) * 1.2, 1, 0)
	label.Text = tostring(math.floor(amount + 0.5))
	label.TextColor3 = if kill then rgb(255, 90, 90) elseif head then rgb(255, 220, 60) else Color3.new(1, 1, 1)
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.2
	g.Size = if head or kill then UDim2.fromOffset(110, 40) else UDim2.fromOffset(86, 32)
	g.Enabled = true
	local token = os.clock()
	g:SetAttribute("Token", token)
	TweenService:Create(g, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = g.StudsOffsetWorldSpace + Vector3.new(0, 2.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.72, function()
		if g:GetAttribute("Token") == token then
			g.Enabled = false
		end
	end)
end

local function buildHud()
	gui = create("ScreenGui", { Name = "WeaponHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	-- La mira, el visor y el aspa van en su propia pantalla, POR DEBAJO de todo (HUD, mochila, teléfono,
	-- mapa, ventanas): nunca se dibujan encima de un menú (y con uno abierto se esconden: menuOpen)
	local reticleGui = create("ScreenGui", { Name = "WeaponReticle", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = -1, Parent = player:WaitForChild("PlayerGui") })
	-- Mira telescópica (solo el francotirador apuntando)
	scope = create("Frame", { Name = "Visor", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = reticleGui })
	local hole = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1, Parent = scope }, {
		create("UIAspectRatioConstraint", { AspectRatio = 1 }),
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		create("UIStroke", { Thickness = 900, Color = Color3.new(0, 0, 0), Transparency = 0.02 }),
	})
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = hole })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = hole })

	-- Mira: círculo + 4 marcas + punto
	reticle = create("Frame", { Name = "Mira", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, Parent = reticleGui })
	local circle = create("Frame", { Name = "Circulo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = reticle }, {
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	ring = create("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.15, Parent = circle })
	for i = 1, 4 do
		local horizontal = i <= 2
		local tick = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = if horizontal then UDim2.fromOffset(10, 2) else UDim2.fromOffset(2, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = reticle,
		}, { create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6 }) })
		ticks[i] = tick
	end
	dot = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = reticle }, {
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	-- Fijado: cuatro esquinas encima del enemigo al que ayuda a apuntar
	lockFrame = create("Frame", { Name = "Fijado", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, Parent = reticleGui })
	for _, corner in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local holder = create("Frame", { AnchorPoint = corner, Position = UDim2.fromScale(corner.X, corner.Y), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = lockFrame })
		create("Frame", { AnchorPoint = Vector2.new(corner.X, 0), Position = UDim2.fromScale(corner.X, if corner.Y > 0 then 1 else 0) - UDim2.fromOffset(0, if corner.Y > 0 then 2 else 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = rgb(255, 90, 90), BorderSizePixel = 0, Parent = holder })
		create("Frame", { AnchorPoint = Vector2.new(0, corner.Y), Position = UDim2.fromScale(if corner.X > 0 then 1 else 0, corner.Y) - UDim2.fromOffset(if corner.X > 0 then 2 else 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = rgb(255, 90, 90), BorderSizePixel = 0, Parent = holder })
	end
	-- Recargando: barra debajo de la mira; con pocas balas, aviso
	reloadBar = create("Frame", { Name = "Recarga", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 46), Size = UDim2.fromOffset(70, 5), BackgroundColor3 = rgb(20, 20, 26), BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, Parent = reticleGui })
	reloadFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(255, 210, 90), BorderSizePixel = 0, Parent = reloadBar })
	hintLabel = create("TextLabel", { Name = "Aviso", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 54), Size = UDim2.fromOffset(160, 18), BackgroundTransparency = 1, Text = "", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 210, 90), TextStrokeTransparency = 0.4, Visible = false, Parent = reticleGui })
	-- Aspa de acierto
	marker = create("Frame", { Name = "Acierto", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Visible = false, Parent = reticleGui })
	for _, angle in { 45, -45 } do
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 3), Rotation = angle, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = marker })
	end
	-- Balas: arriba a la derecha, a la izquierda del minimapa (HudLayout manda: Items.Ammo). En su
	-- propia pantalla con la escala del HUD, como el minimapa y la barra rápida (antes iban en píxeles
	-- fijos desde abajo y en un móvil apaisado de 390 de alto quedaban encima del minimapa).
	local ammoGui = create("ScreenGui", { Name = "WeaponAmmo", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1, Parent = player:WaitForChild("PlayerGui") })
	HudLayout.scaleGui(ammoGui)
	ammoPanel = Theme.panel({ Name = "Balas", Size = UDim2.fromOffset(HudLayout.Sizes.Ammo.X, HudLayout.Sizes.Ammo.Y), Visible = false, Parent = ammoGui })
	HudLayout.onChanged(function(layout)
		HudLayout.apply(ammoPanel, layout.Items.Ammo)
	end)
	ammoText = Theme.title({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 32), Text = "0 / 0", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Right, Parent = ammoPanel })
	ammoInfo = Theme.label({ Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 20), Text = "", TextSize = 13, TextColor3 = Theme.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = ammoPanel })
end

local function refreshAmmo()
	local w = weapon()
	ammoPanel.Visible = w ~= nil
	if not w then
		return
	end
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	local loaded = mag()
	ammoText.Text = ("%d / %s"):format(loaded, if reserve < 0 then "∞" else tostring(reserve))
	ammoText.TextColor3 = if loaded == 0 then Theme.Colors.Error elseif loaded <= math.ceil(w.Magazine / 4) then Theme.Colors.Hunger else Theme.Colors.Text
	local mode = player:GetAttribute("FireMode") or w.Modes[1]
	ammoInfo.Text = if os.clock() < reloadingUntil then "RECARGANDO…" else ("%s %s · %s"):format(w.Icon, w.Name, if mode == "Auto" then "AUTO" else "SEMI")
end

local function updateReticle(w: Weapons.Weapon?, speed: number, airborne: boolean?)
	local camera = workspace.CurrentCamera
	local show = w ~= nil and not (w.Scope and aimAlpha > 0.9)
	reticle.Visible = show
	scope.Visible = w ~= nil and w.Scope == true and aimAlpha > 0.9
	if not w then
		marker.Visible = false
		return
	end
	-- (se abre al moverte, saltar y disparar seguido; se cierra quieto, apuntando o agachado)
	local spread = Weapons.spread(w, { Aiming = aimAlpha > 0.5, Speed = speed, Airborne = airborne, Stance = stance(), Bloom = math.max(0, bloom - (os.clock() - lastShot) * w.Spread.MaxBloom * 2.5), Sprinting = player:GetAttribute("Sprinting") == true })
	local goal = math.clamp(Weapons.reticleRadius(spread, camera.FieldOfView, camera.ViewportSize.Y), 6, 140)
	if w.Pellets > 1 then
		goal = math.max(goal, 22)
	end
	-- (se abre rápido al disparar y se cierra suave: se lee el retroceso sin saltos)
	local clockNow = os.clock()
	reticleShown = Weapons.reticleEase(reticleShown, goal, math.clamp(clockNow - reticleAt, 0, 0.1))
	reticleAt = clockNow
	local radius = reticleShown
	reticle.Size = UDim2.fromOffset(radius * 2, radius * 2)
	local offsets = { Vector2.new(-radius - 7, 0), Vector2.new(radius + 7, 0), Vector2.new(0, -radius - 7), Vector2.new(0, radius + 7) }
	for i, tick in ticks do
		tick.Position = UDim2.new(0.5, offsets[i].X, 0.5, offsets[i].Y)
	end
	local point, part = aimPoint(w.Range)
	-- Si algo se cruza entre el arma y lo que miras (una esquina a tu derecha), la mira se apaga un poco
	-- y no se pone roja: la bala daría en eso
	local blocked = blockedAt(point) ~= nil
	local onTarget = (isPerson(part) or (assistTarget ~= nil and assistAngle ~= nil and assistAngle <= 1.2)) and not blocked
	-- Fijado (esquinas encima del enemigo con ayuda)
	local lock = assistTarget
	if lock and lock.Model.Parent and not lowered() then
		local sp, visible = camera:WorldToViewportPoint(lock.Pos)
		lockFrame.Visible = visible and sp.Z > 0
		if lockFrame.Visible then
			local dist = (lock.Pos - camera.CFrame.Position).Magnitude
			local px = math.clamp(lock.Radius * 2.6 / math.max(dist, 1) / math.tan(math.rad(camera.FieldOfView / 2)) * camera.ViewportSize.Y / 2, 26, 160)
			lockFrame.Position = UDim2.fromOffset(sp.X, sp.Y)
			lockFrame.Size = UDim2.fromOffset(px, px)
		end
	else
		lockFrame.Visible = false
	end
	-- Recargando y pocas balas
	local nowc = os.clock()
	local reloading = nowc < reloadingUntil
	reloadBar.Visible = reloading
	if reloading then
		reloadFill.Size = UDim2.fromScale(math.clamp((nowc - reloadStart) / math.max(reloadingUntil - reloadStart, 0.05), 0, 1), 1)
	end
	local loaded = mag()
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	local low = not reloading and loaded <= math.ceil(w.Magazine / 4) and reserve ~= 0
	hintLabel.Visible = low or (loaded == 0 and reserve == 0)
	if hintLabel.Visible then
		hintLabel.Text = if loaded == 0 and reserve == 0 then "SIN BALAS" elseif TouchLayout.isTouch() then "¡RECARGA!" else "R · RECARGAR"
		hintLabel.TextColor3 = if loaded == 0 then rgb(255, 90, 90) else rgb(255, 210, 90)
	end
	local color = if onTarget then rgb(255, 60, 60) else Color3.new(1, 1, 1)
	ring.Color = color
	dot.BackgroundColor3 = color
	for _, tick in ticks do
		tick.BackgroundColor3 = color
	end
	ring.Transparency = if lowered() then 0.7 elseif blocked then 0.55 else 0.15
	-- Aspa de acierto (blanca; amarilla y más grande en la cabeza; roja si le has dejado K.O. o cae)
	local age = os.clock() - hitMarker
	local span = if hitKill then 0.4 else 0.25
	marker.Visible = age < span
	if marker.Visible then
		local base = if hitKill then 34 elseif hitHead then 30 else 22
		marker.Size = UDim2.fromOffset(base + age * 40, base + age * 40)
		for _, line in marker:GetChildren() do
			if line:IsA("Frame") then
				line.BackgroundColor3 = if hitKill then rgb(255, 60, 60) elseif hitHead then rgb(255, 220, 60) else Color3.new(1, 1, 1)
				line.BackgroundTransparency = age / span
			end
		end
	end
end

---------------------------------------------------------------------
-- Tienda de la Armería y test de la licencia
---------------------------------------------------------------------

local function closeShop()
	if shopPanel then
		shopPanel:Destroy()
		shopPanel = nil
	end
end

local function openShop(data: { [string]: any })
	local keepScroll = 0
	if shopPanel then
		local old = shopPanel:FindFirstChild("Lista") :: ScrollingFrame?
		keepScroll = if old then old.CanvasPosition.Y else 0
		shopPanel:Destroy()
	end
	local panel = Theme.panel({ Name = "Armeria", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 470), Parent = gui })
	shopPanel = panel
	Theme.title({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -80, 0, 30), Text = "🔫 " .. tostring(data.Name or "Armería"), TextSize = 24, Parent = panel })
	Theme.label({ Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 0, 18), Text = "Armas de verdad: mayores de edad con licencia y sin antecedentes. Juguetes: para todos.", TextSize = 13, TextColor3 = Theme.Colors.Muted, Parent = panel })
	local close = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 32), Text = "×", Parent = panel })
	close.Activated:Connect(closeShop)
	local list = create("ScrollingFrame", {
		Name = "Lista", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel,
	}, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for i, entry in data.Items or {} do
		local row = Theme.panel({ Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = Theme.Colors.PanelLight, BackgroundTransparency = 0.3, LayoutOrder = i, Parent = list })
		Theme.label({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(40, 40), Text = entry.Icon or "", TextSize = 28, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(52, 4), Size = UDim2.new(1, -190, 0, 22), Text = entry.Name .. (if entry.Toy then "  · juguete" else ""), Font = Theme.FontBold, TextSize = 16, Parent = row })
		local detail = entry.Desc or ""
		if entry.Stats then
			local st = entry.Stats
			detail = ("Daño %d · %d disp/min · cargador %d · alcance %d · %s"):format(st.Damage, st.RPM, st.Magazine, st.Range, st.Modes)
		end
		if not entry.Ok and entry.Reason then
			detail = "⛔ " .. entry.Reason
		end
		Theme.label({ Position = UDim2.fromOffset(52, 26), Size = UDim2.new(1, -190, 0, 34), Text = detail, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = if entry.Ok then Theme.Colors.Muted else Theme.Colors.Error, Parent = row })
		local buy = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 40),
			Text = if entry.Owned then "✔ Tuya" else Format.money(entry.Price or 0),
			BackgroundColor3 = if entry.Ok then rgb(0, 150, 80) else rgb(70, 70, 80),
			AutoButtonColor = entry.Ok == true,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if not entry.Ok then
				return
			end
			if entry.Kind == "Licence" then
				Remote:FireServer("Licence")
				closeShop()
			else
				Remote:FireServer("Buy", entry.Id)
			end
		end)
	end
	list.CanvasPosition = Vector2.new(0, keepScroll)
	if not data.Refresh then
		Theme.pop(panel)
	end
end

local function closeQuiz()
	if quizPanel then
		quizPanel:Destroy()
		quizPanel = nil
	end
end

local function openQuiz(token: string, data: { [string]: any })
	closeQuiz()
	local panel = Theme.panel({ Name = "TestLicencia", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 380), Parent = gui })
	quizPanel = panel
	local questions = data.Questions or {}
	local answers = {}
	local index = 1
	local title = Theme.title({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 28), Text = "", TextSize = 20, Parent = panel })
	local text = Theme.label({ Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -32, 0, 60), Text = "", TextSize = 17, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	local buttons: { TextButton } = {}
	local function show()
		local q = questions[index]
		if not q then
			Remote:FireServer("Answers", token, answers)
			closeQuiz()
			return
		end
		title.Text = ("💳 Test de seguridad · %d/%d (aprobado con %d)"):format(index, #questions, data.ToPass or 4)
		text.Text = q.Text
		for i, button in buttons do
			button.Visible = q.Options[i] ~= nil
			button.Text = q.Options[i] or ""
		end
	end
	for i = 1, 3 do
		local button = Theme.button({ Position = UDim2.fromOffset(16, 110 + (i - 1) * 78), Size = UDim2.new(1, -32, 0, 68), Text = "", TextSize = 15, TextWrapped = true, Parent = panel })
		buttons[i] = button
		button.Activated:Connect(function()
			answers[index] = i
			index += 1
			show()
		end)
	end
	show()
	Theme.pop(panel)
end

---------------------------------------------------------------------
-- Cada frame: cámara al hombro, retroceso, mira y ráfagas
---------------------------------------------------------------------

local function releaseCamera()
	local humanoid = parts()
	if humanoid then
		if autoRotateSaved ~= nil then
			humanoid.AutoRotate = autoRotateSaved
		end
	end
	autoRotateSaved = nil
	player.CameraMinZoomDistance = 0.5
	if savedMax then
		player.CameraMaxZoomDistance = savedMax
		savedMax = nil
	end
	FootCamera.setAim(0, 70)
	if mouseLocked then
		mouseLocked = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- Cámara al hombro, con Humanoid.CameraOffset (la cámara de Roblox lo suma a tu cabeza, así que la
-- sigue colocando y girando ella: con el dedo, el ratón o el mando; nunca se le fija el CFrame). Corre
-- justo ANTES de la cámara de Roblox: aparta la cámara a la derecha en el eje de la CÁMARA (se pasa al
-- del cuerpo cada fotograma: el cuerpo gira al andar y el hombro no baila) y arriba o abajo según la
-- postura, lo justo para que la mira del centro quede al lado del personaje y no encima
-- (Weapons.shoulderOffset). Entra y sale suave (Shoulder.Blend); primera persona, otra cámara
-- (vehículo, cinemática, conversación: CameraType o CameraSubject distintos) = sin hombro al momento.
-- Choque: de la cabeza al hombro sin atravesar paredes (entra de golpe, vuelve suave); del hombro a
-- la cámara ya se encarga la de Roblox (se acerca sola si hay una pared detrás).
local camParams = RaycastParams.new()
camParams.FilterType = Enum.RaycastFilterType.Exclude
camParams.IgnoreWater = true
camParams.RespectCanCollide = true

local function clearOffset(humanoid: Humanoid)
	if offsetSet then
		offsetSet = false
		humanoid.CameraOffset = Vector3.zero
	end
end

local function shoulderCamera(dt: number, want: boolean, w: Weapons.Weapon?, humanoid: Humanoid, aimEased: number, camStance: string?)
	local S = Weapons.Shoulder
	local camera = workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= humanoid then
		shoulderAlpha, shoulderReach, aimOffset, baseDistance = 0, 1, nil, nil
		clearOffset(humanoid)
		return
	end
	local _, root = parts()
	local cf = camera.CFrame
	local focus = camera.Focus.Position
	local distance = (cf.Position - focus).Magnitude
	baseDistance = distance
	if distance < S.FirstPerson or not root then
		shoulderAlpha, aimOffset = 0, nil
		clearOffset(humanoid)
		return
	end
	shoulderAlpha = math.clamp(shoulderAlpha + (if want then dt else -dt) / S.Blend, 0, 1)
	if shoulderAlpha <= 0 then
		aimOffset = nil
		clearOffset(humanoid)
		return
	end
	if w then
		-- Lo que abre la mira quieto (desde la cadera o apuntando): el personaje, fuera de ella
		local height, fov = camera.ViewportSize.Y, camera.FieldOfView
		local hipOuter = Weapons.reticleOuter(w, Weapons.spread(w, { Stance = camStance }), fov, height)
		local aimOuter = Weapons.reticleOuter(w, Weapons.spread(w, { Aiming = true, Stance = camStance }), fov, height)
		local x, y = Weapons.shoulderOffset(distance, fov, height, hipOuter + (aimOuter - hipOuter) * aimEased, camStance)
		local goal = Vector2.new(x, y)
		aimOffset = if aimOffset then aimOffset:Lerp(goal, 1 - math.exp(-10 * dt)) else goal
	end
	local offset = aimOffset
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if not offset or right.Magnitude < 1e-3 then
		clearOffset(humanoid)
		return
	end
	local e = shoulderAlpha * shoulderAlpha * (3 - 2 * shoulderAlpha)
	-- (arriba en el eje de la cámara: el desplazamiento no cambia la distancia a la cabeza)
	local shift = right.Unit * (offset.X * e) + cf.UpVector * (offset.Y * e)
	camParams.FilterDescendantsInstances = ignore()
	local length = shift.Magnitude
	local reach = 1
	if length > 1e-3 then
		local hit = workspace:Raycast(focus, shift.Unit * (length + WALL_GAP), camParams)
		if hit then
			reach = math.max(0, hit.Distance - WALL_GAP) / length
		end
	end
	shoulderReach = if reach < shoulderReach then reach else math.min(reach, shoulderReach + dt * 2.5)
	-- (CameraOffset va en el eje del cuerpo: se pasa del de la cámara al suyo)
	humanoid.CameraOffset = root.CFrame:VectorToObjectSpace(shift * shoulderReach)
	offsetSet = true
end

local function frame(dt: number)
	local w = weapon()
	local humanoid, root, head = parts()
	local camera = workspace.CurrentCamera
	-- En una conversación o una cinemática no se apunta:
	-- se leen los atributos que ponen DialogueUI y Cinematics, sin requerirlos
	local busy = player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
	if busy or not w or not humanoid or not root or not head or humanoid.Health <= 0 then
		if wantAim then
			WeaponController.setAim(false)
		end
		if aimAlpha > 0 then
			aimAlpha = 0
			releaseCamera()
		end
		dropTrigger()
		updateReticle(nil, 0)
		WeaponMotion.setLocal(0, 0, 0, 0, 0)
		-- Al guardar el arma la cámara vuelve del hombro poco a poco
		if humanoid then
			shoulderCamera(dt, false, nil, humanoid, 0, nil)
		end
		return
	end
	local st = stance()
	-- Con una ventana abierta (mochila, teléfono, mapa…) se suelta la mira (sin zoom ni cámara al
	-- hombro detrás del menú); al cerrarla vuelve solo si sigues pulsando apuntar (ratón/mando)
	local menu = WeaponController.menuOpen()
	if menu and wantAim then
		WeaponController.setAim(false)
		resumeAimAfterMenu = true
	elseif not menu and resumeAimAfterMenu then
		resumeAimAfterMenu = false
		if aimInputHeld() then
			WeaponController.setAim(true)
		end
	end
	local aiming = wantAim and not lowered() and humanoid.SeatPart == nil and not player:GetAttribute("KO")
	aimAlpha = math.clamp(aimAlpha + (if aiming then dt else -dt) / AIM.BlendTime, 0, 1)
	local eased = aimAlpha * aimAlpha * (3 - 2 * aimAlpha)

	-- Apuntando: la cámara se acerca y el campo de visión se cierra (el hombro lo pone shoulderCamera,
	-- más abajo, con la postura de tu pantalla sin esperar al servidor y con transición: agacharte
	-- apuntando no hace saltar la cámara)
	local camStance = player:GetAttribute("StanceLocal") or st
	local fov = if w.Scope and holdBreath then w.AimFov * 0.85 else w.AimFov
	FootCamera.setAim(eased, fov)
	-- Apuntando o con el gatillo pulsado (estilo shooter): el CUERPO gira hacia donde mira la cámara
	-- (tumbado lo gira la locomoción). La cámara no se toca: la gira el jugador.
	local firing = trigger and not menu and humanoid.SeatPart == nil
	if (aimAlpha > 0 or firing) and st ~= "Prone" then
		if autoRotateSaved == nil then
			autoRotateSaved = humanoid.AutoRotate
		end
		humanoid.AutoRotate = false
		local look = camera.CFrame.LookVector
		if Vector3.new(look.X, 0, look.Z).Magnitude > 1e-3 then
			local yaw = math.atan2(-look.X, -look.Z)
			local current = root.CFrame
			local target = CFrame.new(current.Position) * CFrame.Angles(0, yaw, 0)
			root.CFrame = current:Lerp(target, math.min(1, dt * 22))
		end
	end
	if aimAlpha > 0 then
		local distance = startDistance + (AIM.Zoom - startDistance) * eased
		player.CameraMaxZoomDistance = math.max(distance, 1)
		player.CameraMinZoomDistance = if aiming then 0.5 else math.max(0.5, math.min(distance, startDistance))
		if UserInputService.MouseEnabled and not TouchLayout.isTouch() and aiming then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			mouseLocked = true
		end
	elseif not firing and (savedMax or autoRotateSaved ~= nil or mouseLocked) then
		releaseCamera()
	end

	-- Con una ventana abierta (mochila, teléfono, mapa…): sin mira y sin disparo
	if menu and trigger then
		dropTrigger()
	end

	-- Balanceo apuntando (solo en los brazos: WeaponMotion; la cámara no se mueve sola)
	local swayUp, swaySide = Weapons.sway(w, os.clock(), aimAlpha > 0.5, holdBreath)
	local swayK = eased * (if st == "Prone" then 0.3 elseif st == "Crouch" then 0.7 else 1)
	-- Al hombro con el arma en la mano (apuntando o no); no montado, sentado ni K.O.
	local mounted = humanoid.SeatPart ~= nil or player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil
	shoulderCamera(dt, not mounted and not player:GetAttribute("KO"), w, humanoid, eased, if type(camStance) == "string" then camStance else nil)

	-- Hacia dónde apunta (arriba/abajo) y aviso al servidor para que los demás lo vean
	local pitch = math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1))
	if st == "Prone" then
		pitch = math.clamp(pitch, Weapons.ProneLimits.PitchMin, Weapons.ProneLimits.PitchMax)
	end
	local now = os.clock()
	if aimAlpha > 0.5 and math.abs(pitch - lastPitchSent) > 0.03 and now - pitchSentAt > 0.1 then
		lastPitchSent, pitchSentAt = pitch, now
		Remote:FireServer("Pitch", pitch)
	end

	-- Contra una pared: el cañón se levanta y no dispara
	rayParams.FilterDescendantsInstances = ignore()
	local wall = workspace:Raycast(head.Position, root.CFrame.LookVector * (w.Length + 1.5), rayParams)
	local blocked = Weapons.muzzleBlocked(w, if wall then wall.Distance else nil)
	wallAmount += ((if blocked then 1 else 0) - wallAmount) * math.min(1, dt * 10)
	WeaponMotion.setLocal(eased, pitch, wallAmount, math.rad(swayUp) * swayK * 0.5, math.rad(swaySide) * swayK * 0.5)

	-- Disparo automático (móvil): con la mira encima de un enemigo que se ve, dispara solo
	local wantAuto = false
	if TouchLayout.isTouch() and pref("AutoFire") ~= false and not menu and assistTarget then
		local on, profile = assistOn()
		if on then
			local _, seen = aimPoint(w.Range)
			local visible = seen ~= nil and assistTarget.Model.Parent ~= nil and inside(seen, assistTarget.Model)
			wantAuto = AimAssist.autoFire(assistAngle, profile, visible or (assistAngle ~= nil and assistAngle <= profile.Inner and blockedAt(assistTarget.Pos) == nil))
		end
	end
	if wantAuto ~= autoHeld then
		autoHeld = wantAuto
		holdTrigger("Auto", wantAuto)
	end
	-- Ráfaga automática mientras se mantiene el gatillo (el disparo automático, también con las semi:
	-- la cadencia del arma manda)
	local mode = player:GetAttribute("FireMode") or w.Modes[1]
	if trigger and Weapons.holdRepeats(mode, #w.Modes, holds.Auto == true, TouchLayout.isTouch() and (holds.Der == true or holds.Izq == true)) then
		WeaponController.fire()
	end
	-- Recarga sola tras gastar la última bala
	if autoReloadAt and now >= autoReloadAt then
		autoReloadAt = nil
		WeaponController.reload()
	end
	-- Sin disparar un rato: el número de disparo vuelve a ser el del servidor (por si se perdió alguno)
	if now - lastShot > 0.6 then
		shotN = tonumber(player:GetAttribute("WeaponShotN")) or shotN
	end
	-- Las balas en pantalla al momento (la que gastas tú, sin esperar al servidor) y «RECARGANDO…»
	if now - ammoRefreshAt > 0.08 then
		ammoRefreshAt = now
		refreshAmmo()
	end
	local v = root.AssemblyLinearVelocity
	updateReticle(if menu then nil else w, Vector3.new(v.X, 0, v.Z).Magnitude, humanoid.FloorMaterial == Enum.Material.Air)
end

---------------------------------------------------------------------

function WeaponController.init()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapons", 30) :: RemoteEvent
	if not Remote then
		warn("[Armas] No está el remoto Weapons")
		return
	end
	WeaponFx.init()
	WeaponMotion.init()
	buildHud()

	InventoryUI.setWeaponHandler(function(ref: string?, toggle: boolean?)
		if toggle then
			WeaponController.equip(if player:GetAttribute("Weapon") == ref then nil else ref)
		elseif ref ~= player:GetAttribute("Weapon") then
			WeaponController.equip(ref)
		end
	end)

	Remote.OnClientEvent:Connect(function(kind: string, a: any, b: any, c: any)
		if kind == "Shot" then
			onShot(a)
		elseif kind == "Reload" then
			onReload(a)
		elseif kind == "Confirm" then
			hitMarker = os.clock()
			hitKill, hitHead = false, false
			for _, hit in a or {} do
				if hit.KO or hit.Killed then
					hitKill = true
				end
				if hit.Zone == "Head" then
					hitHead = true
				end
				if hit.Xeno and pref("Numbers") ~= false and typeof(hit.At) == "Vector3" then
					WeaponController.damageNumber(hit.At, tonumber(hit.Amount) or 0, hit.Zone == "Head", hit.KO == true)
				end
			end
			-- Un chasquido para cada cosa: acierto, cabeza (más agudo) y cae
			if hitKill then
				SoundFx.play("KO", 0.55, 1.25)
			elseif hitHead then
				SoundFx.play("Punto", 0.6, 1.6)
			else
				SoundFx.play("Clic", 0.6, 2.2)
			end
		elseif kind == "Dry" then
			localMag = 0
			local w = weapon()
			if w then
				dryFire(w)
			end
		elseif kind == "Shop" then
			openShop(a)
		elseif kind == "Quiz" then
			closeShop()
			openQuiz(a, b)
		elseif kind == "QuizResult" then
			closeQuiz()
			local _ = c
		end
	end)

	for _, attribute in { "Weapon", "WeaponMag", "WeaponAmmo", "FireMode" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if attribute ~= "WeaponMag" or (localMag and localMag >= (tonumber(player:GetAttribute("WeaponMag")) or 0)) then
				localMag = nil
			end
			if attribute == "Weapon" and not weapon() then
				WeaponController.setAim(false)
				dropTrigger()
			end
			refreshAmmo()
			TouchLayout.refresh()
		end)
	end
	player.CharacterAdded:Connect(function()
		wantAim, aimAlpha = false, 0
		resumeAimAfterMenu = false
		dropTrigger()
		autoRotateSaved = nil
		offsetSet = false
		savedMax = nil
		releaseCamera()
	end)

	-- Ratón y mando (con un arma en la mano)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not weapon() or UserInputService:GetFocusedTextBox() then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
			WeaponController.setAim(true)
		elseif (t == Enum.UserInputType.MouseButton1 and not processed) or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if not TouchLayout.isTouch() or t ~= Enum.UserInputType.MouseButton1 then
				setTrigger(true)
			end
		elseif processed then
			return
		elseif (input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.T) and Prompts.keyInUse(input.KeyCode) then
			-- Un cartel cercano usa esa tecla: es para él, no para el arma
			return
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.DPadLeft then
			WeaponController.reload()
		elseif input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.DPadUp then
			WeaponController.cycleMode()
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.DPadRight then
			if not Prompts.keyInUse(input.KeyCode) then
				WeaponController.nextWeapon()
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			holdBreath = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
			WeaponController.setAim(false)
		elseif t == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if trigger then
				setTrigger(false)
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			holdBreath = false
		end
	end)

	-- Botones del móvil (y pistas de teclas en el ordenador), estilo shooter móvil: Disparar en el hueco
	-- grande del Atacar, Apuntar encima, Recargar (con las balas) en el de Interactuar y un segundo
	-- Disparar a la derecha del joystick. Agacharse, Saltar, Esquivar y Correr siguen en su sitio.
	local armed = WeaponController.armed
	local function ammoText(): string?
		local w = weapon()
		if not w then
			return nil
		end
		local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
		return ("%d/%s"):format(mag(), if reserve < 0 then "∞" else tostring(reserve))
	end
	WeaponController.ammoText = ammoText
	TouchLayout.register({
		Id = "Disparar", Icon = "disparar", Label = "Disparar", Slot = "Disparar", Priority = 1, Key = "Clic", Pad = "RT",
		Visible = armed,
		Hold = function(down: boolean)
			holdTrigger("Der", down)
		end,
		Active = function()
			return holds.Der == true
		end,
	})
	TouchLayout.register({
		Id = "DispararIzq", Icon = "disparar", Label = "Disparar", Slot = "DispararIzq", Priority = 1,
		Twin = true, -- (el mismo texto que el grande: los dos se ven a la vez)
		Visible = function()
			return armed() and TouchLayout.isTouch()
		end,
		Hold = function(down: boolean)
			holdTrigger("Izq", down)
		end,
		Active = function()
			return holds.Izq == true
		end,
	} :: any)
	TouchLayout.register({
		Id = "Apuntar", Icon = "objetivo", Label = "Apuntar", Slot = "Apuntar", Priority = 1, Key = "Clic dcho", Pad = "LT",
		Visible = armed,
		Active = WeaponController.isAiming,
		Callback = WeaponController.toggleAim,
	})
	TouchLayout.register({
		Id = "Recargar", Icon = "recargar", Label = "Recargar", Slot = "Recargar", Priority = 0.5, Key = "R",
		-- En el móvil siempre con el arma (con las balas «12/90» encima: el racimo no baila); en el
		-- ordenador, la pista de la tecla solo cuando hace falta
		Visible = function()
			local w = weapon()
			if not w then
				return false
			end
			return TouchLayout.isTouch() or (mag() < Weapons.capacity(w, mag()) and (tonumber(player:GetAttribute("WeaponAmmo")) or 0) ~= 0)
		end,
		Badge = ammoText,
		Active = function()
			return if os.clock() < reloadingUntil then "wait" else false
		end,
		Callback = WeaponController.reload,
	})
	TouchLayout.register({
		Id = "ModoFuego", Icon = "pistola", Label = "Semi/Auto", Priority = 12, Key = "T",
		Visible = function()
			local w = weapon()
			return w ~= nil and #w.Modes > 1
		end,
		Callback = WeaponController.cycleMode,
	})
	TouchLayout.register({ Id = "Guardar", Icon = "bajarse", Label = "Guardar", Priority = 13, Visible = armed, Callback = WeaponController.holster })
	-- Cambiar de arma (si llevas más de una)
	TouchLayout.register({
		Id = "CambiarArma", Icon = "pistola", Label = "Cambiar", Priority = 11.5, Key = "Q",
		Visible = function()
			return armed() and #InventoryUI.weaponRefs() > 1
		end,
		Callback = WeaponController.nextWeapon,
	})
	-- Móvil: con mira telescópica no había forma de contener la respiración (en el ordenador es Mayús).
	-- Mientras apuntas con mira sale «Respirar»: mantenlo pulsado para que la mira no se mueva.
	TouchLayout.register({
		Id = "Respirar", Icon = "esquivar", Label = "Respirar", Priority = 2,
		Visible = function()
			local w = weapon()
			return TouchLayout.isTouch() and w ~= nil and w.Scope == true and wantAim
		end,
		Active = function()
			return holdBreath
		end,
		Hold = function(down: boolean)
			holdBreath = down
		end,
	})
	-- Justo ANTES de la cámara de Roblox: el hombro (CameraOffset) y el giro del cuerpo valen ya en
	-- este fotograma; la cámara la coloca y la gira siempre Roblox
	RunService:BindToRenderStep("WeaponCamera", Enum.RenderPriority.Camera.Value - 1, function(dt)
		local ok, err = pcall(frame, dt)
		if not ok then
			warn("[Armas] " .. tostring(err))
		end
	end)
	-- Justo DESPUÉS de la cámara de Roblox: la ayuda al apuntar y el golpe del retroceso (giran la
	-- cámara un poquito sobre lo que ya ha hecho Roblox; la de Roblox parte de ahí el fotograma siguiente)
	RunService:BindToRenderStep("WeaponAssist", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(afterCamera, dt)
		if not ok then
			warn("[Armas] " .. tostring(err))
		end
	end)
	refreshAmmo()
end

return WeaponController
