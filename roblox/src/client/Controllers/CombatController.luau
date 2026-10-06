-- CombatController (cliente): pelear, defenderse, esquivar, fijar objetivo, los poderes y ver los golpes.
--
-- Controles (las reglas: shared/Combat y shared/Powers; quien decide es el servidor: CombatService):
--   Ordenador: clic izquierdo o X golpe ligero (pulsa seguido: combo de hasta 6) · clic derecho (toque) o
--              C golpe fuerte (mantener = golpe cargado, rompe la guardia) · mantén F o Z guardia ·
--              Q esquivar (voltereta; con objetivo fijado, en el aire o justo al recibir un golpe y con
--              aguante: DESVANECERSE detrás o a un lado del rival) · V fijar objetivo (otra vez: el
--              siguiente; mantener: soltarlo) · Espacio en el aire: impulso aéreo ·
--              Poderes de la Grieta (si los has despertado): mantén G cargar energía · Y habilidad
--              elegida (la onda se carga manteniendo) · U cambiar de habilidad · R definitiva
--   Mando:     RB ligero · RT fuerte (mantener: cargado) · mantén LB guardia · B esquivar · R3 fijar ·
--              mantén X cargar energía (en plena pelea) · cruceta izquierda habilidad (con LB: cambiar) ·
--              LB + RT definitiva (con la energía llena; en el teclado, también guardia + C)
--   Móvil:     Ataque (ligero), Fuerte (en el hueco de Gestos, en plena pelea; mantener = cargado),
--              Defensa (mantener), Esquivar, Fijar; y con poderes: Cargar (mantener), el botón de la
--              habilidad (con su nombre), Cambiar y Definitiva (UI/TouchLayout)
--   Menú de comandos: Atacar (y en plena pelea: Defender y Huir)
-- Combos y finales: ligero ×1-2 + fuerte = LANZADOR (al aire: sigue con ligeros y el fuerte es el
-- REMATE AÉREO) · ×3-4 + fuerte = EMPUJÓN LEJANO (se estampa contra las paredes) · ×5-6 + fuerte = AL
-- SUELO · fuerte + fuerte = patada giratoria · el sexto ligero empuja.
-- Aquí se anima y se enseña: el golpe (PunchAnim, hecho con código), el impacto con congelación,
-- partículas, temblor y sonido (CombatFx), el empujón y el vuelo de tu personaje (HitReaction), las
-- barras (UI/CombatHud) y la cámara del objetivo fijado (mantiene a los dos en pantalla).
-- Los disparos (WeaponService) llegan por aquí también ("Hit" con Weapon): número donde da la bala.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local MissionCombat = require(ReplicatedStorage.Shared.MissionCombat)
local Powers = require(ReplicatedStorage.Shared.Powers)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local CombatHud = require(script.Parent.Parent.UI.CombatHud)
local ReactMotion = require(script.Parent.ReactMotion)
local RollMotion = require(script.Parent.RollMotion)
local PunchAnim = require(script.Parent.PunchAnim)
local SoundFx = require(script.Parent.SoundFx)
local CameraShake = require(script.Parent.CameraShake)
local CombatFx = require(script.Parent.CombatFx)
local HitReaction = require(script.Parent.HitReaction)
local InventoryUI = require(script.Parent.InventoryUI)
local Controls = require(script.Parent.Controls)

local CombatController = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB
local Remote: RemoteEvent? = nil

local function send(...: any)
	if Remote then
		Remote:FireServer(...)
	end
end

-- Golpe en un personaje: PunchAnim (C0, se ve siempre) o, si no, ReactMotion (directo, cruzado o gancho)
local FALLBACK = { Jab = "Jab", Cross = "Cross", Hook = "Hook", Knee = "Jab", Elbow = "Cross", Kick = "Hook", Uppercut = "Hook", SpinKick = "Hook", Slam = "Hook", Charged = "Hook", Blast = "Jab" }
local function swingPose(character: Model?, anim: string): boolean
	return PunchAnim.play(character, anim) or ReactMotion.play(character, FALLBACK[anim] or "Jab")
end

-- El nombre de la postura de un golpe (shared/Combat.Moves) o, en mensajes antiguos, un número
local function animOf(move: any): string
	if type(move) == "number" then
		return ({ "Jab", "Cross", "Kick" })[math.clamp(move, 1, 3)]
	end
	local def = Combat.Moves[move]
	if def then
		return def.Anim
	end
	return if PunchAnim.Moves[move] then move else "Jab"
end

-- Guardia: igual, PunchAnim y si no ReactMotion
local function guardPose(character: Model?, on: boolean)
	if not PunchAnim.hold(character, "Guard", on) then
		ReactMotion.hold(character, "Guard", on)
	end
end

local function isR15(model: Model?): boolean
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15
end

-- Animaciones de Roblox de golpear con herramienta (para cuerpos R6, donde PunchAnim no llega)
local ANIMS = {
	R15 = { Punch = 522635514, Heavy = 522638767 },
	R6 = { Punch = 129967390, Heavy = 129967478 },
}

local localChain = Combat.newChain()
local localLast: string? = nil
local localLastAt = 0
local blocking = false
local charging = false
local heavyHeldAt: number? = nil
local powerHeld: { Id: string, At: number }? = nil
local lastFight = -math.huge -- última vez que pegaste o te pegaron (para "en plena pelea")
local lastDodge = -math.huge
local lastHitAt = -math.huge -- última vez que te dieron (desvanecerse para escapar)
-- Rodar tras un salto: Esquivar pulsado en el aire (cuándo y si era hacia atrás) y el aterrizaje
local airRollAt: number? = nil
local airRollBack = false
local wasAirborne = false
local landedAt: number? = nil
local lockTarget: Model? = nil
local lockMarker: BillboardGui? = nil
local lockBar: Frame? = nil
local lockConnection: RBXScriptConnection? = nil
local tracks: { [string]: AnimationTrack } = {}
local koGui: ScreenGui? = nil
local selectedPower = 1

local function parts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Poderes despiertos (atributo Powers que pone el servidor)
local function powerSet(): { [string]: boolean }
	return Powers.decode(player:GetAttribute("Powers"))
end

local function abilities(): { Powers.Power }
	return Powers.abilities(powerSet())
end

local function selected(): Powers.Power?
	local list = abilities()
	if #list == 0 then
		return nil
	end
	if selectedPower > #list or selectedPower < 1 then
		selectedPower = 1
	end
	return list[selectedPower]
end

local function energy(): number
	return tonumber(player:GetAttribute("Energia")) or 0
end

local function stamina(): number
	return tonumber(player:GetAttribute("Aguante")) or Combat.StaminaMax
end

-- ¿Puedo pegar ahora? (el servidor lo vuelve a comprobar todo)
function CombatController.canAttack(): boolean
	local humanoid = parts()
	local stage = player:GetAttribute("LifeStage")
	return humanoid ~= nil
		and humanoid.Health > 0
		and humanoid.SeatPart == nil
		and not player:GetAttribute("KO")
		and not player:GetAttribute("InDialogue")
		and not player:GetAttribute("Training") -- (entrenando en el gimnasio)
		and not InventoryUI.isOpen() -- (con la mochila abierta, Q es tirar el objeto)
		and (stage == nil or Stages.inRange(stage, Combat.MinStage, nil))
end

-- ¿Aturdido o en el suelo? (el servidor manda la hora hasta la que dura)
local function stunned(): boolean
	local now = workspace:GetServerTimeNow()
	local stun = tonumber(player:GetAttribute("StunUntil")) or 0
	local down = tonumber(player:GetAttribute("DownUntil")) or 0
	return now < stun - 0.05 or now < down - 0.05
end

local function canAct(): boolean
	return CombatController.canAttack() and not stunned()
end

local function armed(): boolean
	return player:GetAttribute("Weapon") ~= nil
end

local function track(name: string): AnimationTrack?
	local humanoid = parts()
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator then
		return nil
	end
	local rig = if humanoid.RigType == Enum.HumanoidRigType.R15 then "R15" else "R6"
	local key = rig .. name
	local existing = tracks[key]
	if existing and existing.Parent then
		return existing
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. ANIMS[rig][name]
	local ok, loaded = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		return nil
	end
	loaded.Priority = Enum.AnimationPriority.Action
	tracks[key] = loaded
	return loaded
end

---------------------------------------------------------------------
-- Golpes
---------------------------------------------------------------------

-- Con objetivo fijado, el golpe te acerca un poco a él (como en los juegos de lucha)
local function lunge()
	local _, root = parts()
	local other = lockTarget and lockTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not other then
		return
	end
	local d = Vector3.new(other.Position.X - root.Position.X, 0, other.Position.Z - root.Position.Z)
	local distance = d.Magnitude
	if distance > 3.5 and distance < Combat.Range + Combat.LockReach + 3 then
		local v = root.AssemblyLinearVelocity
		local speed = math.min(32, (distance - 2.5) * 7)
		root.AssemblyLinearVelocity = Vector3.new(d.Unit.X * speed, v.Y, d.Unit.Z * speed)
	end
end

-- Un golpe (kind "Light" o "Heavy"): animación al momento y aviso al servidor
local function swing(kind: string, charged: boolean?): boolean
	if not canAct() then
		return false
	end
	local now = os.clock()
	-- Misma pausa que el servidor, para que la animación no vaya por delante del golpe
	if not Combat.readyMove(localLast, localLastAt, now) then
		return false
	end
	local name, chain = Combat.nextMove(localChain, kind, now, charged, HitReaction.isFloating())
	localChain, localLast, localLastAt = chain, name, now
	if blocking then
		CombatController.setBlocking(false)
	end
	if charging then
		CombatController.charge(false)
	end
	lastFight = now
	local move = Combat.Moves[name]
	-- Golpe hecho con código (R15); si este cuerpo no se puede mover así, animación de Roblox
	if not (isR15(player.Character) and swingPose(player.Character, move.Anim)) then
		local anim = track(if move.Heavy then "Heavy" else "Punch")
		if anim then
			anim:Play(0.05, 1, if move.Heavy then 1.1 else 1.6)
		end
	end
	lunge()
	-- Sonido del golpe al aire (los demás lo oyen con "Swing")
	local _, root = parts()
	if root then
		SoundFx.play("Salto", 0.7, if move.Heavy then 0.8 else 1.3, root)
	end
	if kind == "Heavy" then
		send("Heavy", charged == true)
	else
		send("Light")
	end
	TouchLayout.refresh()
	return true
end

-- Un enemigo de tu combate de misión a tiro (las cucarachas, Petra…: etiqueta MissionEnemy)
function CombatController.missionTarget(): Model?
	local _, root = parts()
	if not root then
		return nil
	end
	local mine = MissionCombat.mine(game:GetService("CollectionService"):GetTagged(MissionCombat.ATTR), player.UserId)
	local best = MissionCombat.nearest(mine, root.Position, MissionCombat.Range, function(model: Model)
		return model:GetPivot().Position
	end)
	return best
end

-- Golpe ligero (también el comando Atacar). En un combate de misión, el mismo botón le da al enemigo
-- más cercano desde lejos (lanzar el globo de agua…): nunca hace falta un botón de «Interactuar»
local lastMissionAttack = 0
function CombatController.attack()
	if CombatController.canAttack() and CombatController.missionTarget() then
		local now = os.clock()
		if now - lastMissionAttack < MissionCombat.HitGap then
			return
		end
		lastMissionAttack = now
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("LifeStory")
		if remote then
			(remote :: RemoteEvent):FireServer("Attack")
		end
		ReactMotion.play(player.Character, "Throw")
		return
	end
	swing("Light")
end

-- Golpe fuerte de un toque (comandos)
function CombatController.heavyTap()
	send("HeavyHold")
	swing("Heavy", false)
end

-- Golpe fuerte mantenido: al pulsar empieza a cargar (se ve), al soltar sale (cargado si pasó ChargeTime)
function CombatController.heavy(down: boolean)
	if down then
		if not canAct() then
			return
		end
		-- Con la guardia puesta y la energía llena: la definitiva (mando: LB + RT)
		if blocking and powerSet().Definitiva and energy() >= Powers.Ultimate.Cost then
			CombatController.ultimate()
			return
		end
		heavyHeldAt = os.clock()
		send("HeavyHold")
		local mine = heavyHeldAt
		task.delay(0.18, function()
			if heavyHeldAt == mine then
				PunchAnim.hold(player.Character, "Windup", true)
			end
		end)
		task.delay(Combat.ChargeTime, function()
			if heavyHeldAt == mine then
				CombatFx.windup(player.Character, Combat.MaxChargeHold)
				SoundFx.play("Salto", 0.5, 0.6)
			end
		end)
		-- (si se mantiene demasiado, sale solo)
		task.delay(Combat.MaxChargeHold, function()
			if heavyHeldAt == mine then
				CombatController.heavy(false)
			end
		end)
		return
	end
	local started = heavyHeldAt
	heavyHeldAt = nil
	PunchAnim.hold(player.Character, "Windup", false)
	CombatFx.stopWindup(player.Character)
	if not started then
		return
	end
	swing("Heavy", os.clock() - started >= Combat.ChargeTime)
end

function CombatController.setBlocking(value: boolean)
	if value and not canAct() then
		value = false
	end
	if blocking == value then
		return
	end
	blocking = value
	if value and charging then
		CombatController.charge(false)
	end
	-- La guardia se ve al momento en tu pantalla (sin esperar a que el servidor la confirme)
	guardPose(player.Character, value or player:GetAttribute("Blocking") == true)
	send("Block", value)
	TouchLayout.refresh()
end

function CombatController.isBlocking(): boolean
	return blocking
end

-- ¿En plena pelea? (has pegado o te han pegado hace poco, o tienes a alguien fijado)
function CombatController.inCombat(): boolean
	return os.clock() - lastFight < 8 or lockTarget ~= nil
end

-- Defenderse un momento (el comando Defender del menú)
function CombatController.guard(seconds: number)
	CombatController.setBlocking(true)
	task.delay(seconds, function()
		CombatController.setBlocking(false)
	end)
end

---------------------------------------------------------------------
-- Esquivar: voltereta o desvanecerse
---------------------------------------------------------------------
function CombatController.dodge(backwards: boolean?)
	local humanoid, root = parts()
	if not humanoid or not root or not CombatController.canAttack() then
		return
	end
	local now = os.clock()
	local move = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local direction = if move.Magnitude > 0.1 then move.Unit elseif backwards then -look else look
	-- En el aire tras un salto: la voltereta se guarda y sale al tocar el suelo (amortigua la caída).
	-- (fijado o justo después de un golpe sigue siendo desvanecerse)
	if humanoid.FloorMaterial == Enum.Material.Air and Combat.queueAirRoll(lockTarget ~= nil and not backwards, now - lastHitAt) then
		airRollAt = now
		airRollBack = backwards == true
		player:SetAttribute("RollQueued", true) -- (Locomotion: al caer, sin traspiés)
		return
	end
	-- ¿Desvanecerse? (con aguante: fijado, en el aire o justo después de recibir un golpe)
	local kind = Combat.dodgeKind(stamina(), lockTarget ~= nil and not backwards, now - lastHitAt, HitReaction.airborne())
	if kind == "Vanish" and now - lastDodge >= Combat.VanishCooldown then
		lastDodge = now
		if blocking then
			CombatController.setBlocking(false)
		end
		lastFight = now
		send("Dodge", "Vanish", direction)
		TouchLayout.refresh()
		return
	end
	if stunned() or now - lastDodge < Combat.DodgeCooldown or RollMotion.isLocalRolling() then
		return
	end
	if not RollMotion.roll(direction) then
		return -- (sentado, nadando…: ahora no se puede rodar)
	end
	lastDodge = now
	-- (Locomotion: rodando no hay traspiés de aterrizaje que frene; con arma ni la mira ni el fuego se tocan)
	player:SetAttribute("RollQueued", true)
	task.delay(Combat.RollTime, function()
		if airRollAt == nil then
			player:SetAttribute("RollQueued", nil)
		end
	end)
	if blocking then
		CombatController.setBlocking(false)
	end
	SoundFx.play("Salto", 0.6, 0.8, root)
	send("Dodge", nil, direction)
	TouchLayout.refresh()
end

-- Al tocar el suelo: si se pulsó Esquivar en el aire hace poco (Combat.RollBuffer), rueda YA, hacia
-- donde empuja el joystick (o hacia delante). Lo llama cada fotograma el vigilante de init (y las pruebas).
function CombatController.landingCheck(now: number?)
	local humanoid = parts()
	if not humanoid then
		return
	end
	local t = now or os.clock()
	local inAir = humanoid.FloorMaterial == Enum.Material.Air
	if inAir then
		wasAirborne = true
		if airRollAt and t - airRollAt > Combat.RollBuffer then
			-- (pulsado demasiado pronto: ya no cuenta)
			airRollAt = nil
			player:SetAttribute("RollQueued", nil)
		end
		return
	end
	if wasAirborne then
		wasAirborne = false
		landedAt = t
		local pressed = airRollAt
		airRollAt = nil
		if Combat.rollOnLanding(pressed, t) then
			CombatController.dodge(airRollBack)
		end
		task.delay(0.3, function()
			player:SetAttribute("RollQueued", nil)
		end)
	end
end

-- (pruebas) cuándo aterrizó por última vez
function CombatController._landedAt(): number?
	return landedAt
end

-- Huir: esquivar hacia atrás y soltar al fijado
function CombatController.flee()
	CombatController.setLock(nil)
	CombatController.dodge(true)
end

---------------------------------------------------------------------
-- Poderes de la Grieta (shared/Powers)
---------------------------------------------------------------------
local function aimDir(): Vector3
	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame.LookVector
	end
	local _, root = parts()
	return if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
end

-- Cargar energía (mantener): quieto, con el aura
function CombatController.charge(down: boolean)
	if down and (not powerSet().Energia or not canAct()) then
		down = false
	end
	if charging == down then
		return
	end
	charging = down
	if down and blocking then
		CombatController.setBlocking(false)
	end
	-- (quieto mientras carga: como en los juegos de lucha)
	if down then
		Controls.disable("CargarEnergia")
	else
		Controls.enable("CargarEnergia")
	end
	if down then
		lastFight = os.clock()
	end
	send("Charge", down)
	TouchLayout.refresh()
end

function CombatController.isCharging(): boolean
	return charging
end

-- La habilidad elegida: al pulsar (la onda empieza a cargar) y al soltar (sale)
function CombatController.power(down: boolean)
	local p = selected()
	if not p then
		return
	end
	if down then
		if not canAct() then
			return
		end
		if p.MaxCharge then
			powerHeld = { Id = p.Id, At = os.clock() }
			send("PowerHold", p.Id)
			PunchAnim.hold(player.Character, "Aim", true)
			CombatFx.aura(player.Character, true)
			return
		end
		send("Power", p.Id, aimDir())
		lastFight = os.clock()
		PunchAnim.play(player.Character, "Blast")
		return
	end
	local held = powerHeld
	powerHeld = nil
	if held then
		PunchAnim.hold(player.Character, "Aim", false)
		if not (player:GetAttribute("Charging") or charging) then
			CombatFx.aura(player.Character, false)
		end
		send("Power", held.Id, aimDir())
		lastFight = os.clock()
		PunchAnim.play(player.Character, "Blast")
	end
end

-- Cambiar de habilidad (selector)
function CombatController.nextPower()
	local list = abilities()
	if #list == 0 then
		return
	end
	selectedPower = selectedPower % #list + 1
	local p = list[selectedPower]
	CombatHud.setSelected(p.Id)
	TouchLayout.setLabel("Poder", p.Name)
	TouchLayout.setIcon("Poder", p.Icon)
	SoundFx.play("MenuMover", 0.6)
	TouchLayout.refresh()
end

function CombatController.ultimate()
	if not powerSet().Definitiva or energy() < Powers.Ultimate.Cost or not canAct() then
		return
	end
	lastFight = os.clock()
	send("Ultimate", aimDir())
end

---------------------------------------------------------------------
-- Fijar objetivo: miras siempre a la persona fijada y la cámara os mantiene a los dos en pantalla
---------------------------------------------------------------------
local LOCK_RANGE = 40

-- Candidatos (jugadores y personajes con Humanoid) a menos de LOCK_RANGE, del más cercano al más lejano
local function candidates(): { Model }
	local _, root = parts()
	if not root then
		return {}
	end
	local found: { [Model]: number } = {}
	local function consider(model: Instance?)
		if not model or not model:IsA("Model") or model == player.Character or found[model] then
			return
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local other = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and other and humanoid.Health > 0 then
			local d = (other.Position - root.Position).Magnitude
			if d < LOCK_RANGE then
				found[model] = d
			end
		end
	end
	for _, other in Players:GetPlayers() do
		consider(other.Character)
	end
	-- Personajes cercanos (los que tienen Humanoid): se buscan solo alrededor, sin recorrer el mapa
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local ok, near = pcall(function()
		return workspace:GetPartBoundsInRadius(root.Position, LOCK_RANGE, params)
	end)
	if ok then
		for _, part in near do
			if part.Name == "HumanoidRootPart" and part.Parent then
				consider(part.Parent)
			end
		end
	end
	local list = {}
	for model in found do
		table.insert(list, model)
	end
	-- (primero los rivales de entrenamiento; luego por distancia)
	table.sort(list, function(a, b)
		local fa, fb = a:GetAttribute("Fighter") ~= nil, b:GetAttribute("Fighter") ~= nil
		if fa ~= fb then
			return fa
		end
		return found[a] < found[b]
	end)
	return list
end

local function nearestTarget(): Model?
	return candidates()[1]
end

-- Cámara del objetivo fijado: antes de que Roblox coloque la cámara, se gira para mirar desde detrás de
-- ti hacia el rival (Roblox respeta la distancia y las paredes): los dos quedan en pantalla
local LOCK_CAMERA = "CombatLockCamera"
local lockCameraBound = false
local function lockCamera(dt: number)
	local camera = workspace.CurrentCamera
	local target = lockTarget
	if not camera or not target or camera.CameraType ~= Enum.CameraType.Custom or CombatFx.inCinematic() then
		return
	end
	local _, root = parts()
	local other = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not other then
		return
	end
	local mid = root.Position:Lerp(other.Position, 0.5)
	local toward = Vector3.new(mid.X - root.Position.X, 0, mid.Z - root.Position.Z)
	if toward.Magnitude < 0.5 then
		return
	end
	local separation = (other.Position - root.Position).Magnitude
	-- Un poco desde arriba (más cuanto más lejos está) y mirando al punto medio
	local pitch = -math.clamp(0.2 + separation * 0.006, 0.2, 0.45)
	local flatDir = toward.Unit
	local want = (flatDir + Vector3.new(0, pitch, 0)).Unit
	local current = camera.CFrame.LookVector
	local look = current:Lerp(want, math.min(1, dt * 7))
	if look.Magnitude < 0.01 then
		return
	end
	camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + look.Unit)
end

function CombatController.setLock(target: Model?)
	if lockConnection then
		lockConnection:Disconnect()
		lockConnection = nil
	end
	if lockMarker then
		lockMarker:Destroy()
		lockMarker = nil
		lockBar = nil
	end
	local humanoid = parts()
	if humanoid then
		humanoid.AutoRotate = true
	end
	lockTarget = target
	send("Lock", target)
	TouchLayout.refresh()
	if not target then
		if lockCameraBound then
			lockCameraBound = false
			pcall(function()
				RunService:UnbindFromRenderStep(LOCK_CAMERA)
			end)
		end
		return
	end
	lastFight = os.clock()
	local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
	lockMarker = create("BillboardGui", { Name = "LockOn", Size = UDim2.fromOffset(120, 64), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true, Adornee = head, Parent = player:WaitForChild("PlayerGui") })
	local ring = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, Parent = lockMarker }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(255, 90, 90), Thickness = 3 }),
	})
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(26, 26) }):Play()
	-- Su vida (como en los juegos de lucha: la barra del rival)
	local track = create("Frame", { Name = "Vida", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(110, 10), BackgroundColor3 = rgb(20, 20, 30), BorderSizePixel = 0, Parent = lockMarker }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(0, 0, 0), Thickness = 1.5 }),
	})
	lockBar = create("Frame", { Name = "Relleno", Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 90, 80), BorderSizePixel = 0, Parent = track }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	if not lockCameraBound then
		lockCameraBound = true
		RunService:BindToRenderStep(LOCK_CAMERA, Enum.RenderPriority.Camera.Value - 1, function(dt)
			local ok, err = pcall(lockCamera, dt)
			if not ok then
				warn("[Combate] Cámara: " .. tostring(err))
			end
		end)
	end
	-- Mientras dure, el personaje gira hacia el objetivo (solo esto va cada fotograma, y solo fijado)
	lockConnection = RunService.RenderStepped:Connect(function()
		local me, root = parts()
		local other = target.Parent and target:FindFirstChild("HumanoidRootPart") :: BasePart?
		local otherHumanoid = target:FindFirstChildOfClass("Humanoid")
		if not me or not root or not other or not otherHumanoid or otherHumanoid.Health <= 0 or me.SeatPart
			or (other.Position - root.Position).Magnitude > LOCK_RANGE * 1.5 then
			CombatController.setLock(nil)
			return
		end
		if lockBar then
			lockBar.Size = UDim2.fromScale(math.clamp(otherHumanoid.Health / math.max(1, otherHumanoid.MaxHealth), 0, 1), 1)
		end
		if RollMotion.isLocalRolling() or me.PlatformStand then
			return
		end
		me.AutoRotate = false
		local look = Vector3.new(other.Position.X, root.Position.Y, other.Position.Z)
		if (look - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
	end)
end

-- Fijar: el más cercano; con alguien fijado, el siguiente (después del último, se suelta)
function CombatController.toggleLock()
	if lockTarget then
		local list = candidates()
		local i = table.find(list, lockTarget)
		-- (después del último, se suelta: así en el móvil el mismo botón cambia y suelta)
		local nextOne = if i then list[i + 1] else list[1]
		if nextOne and nextOne ~= lockTarget then
			CombatController.setLock(nextOne)
		else
			CombatController.setLock(nil)
		end
		return
	end
	if not CombatController.canAttack() then
		return
	end
	local target = nearestTarget()
	if target then
		CombatController.setLock(target)
	end
end

function CombatController.isLocked(): boolean
	return lockTarget ~= nil
end

function CombatController.lockedTarget(): Model?
	return lockTarget
end

---------------------------------------------------------------------
-- Lo que se ve y se oye
---------------------------------------------------------------------

-- Número de daño que sube y se desvanece sobre la cabeza (o, con `at`, donde ha dado la bala;
-- zone = "Head" para los disparos a la cabeza)
local function damageNumber(model: Model, amount: number, blocked: boolean, heavy: boolean, at: Vector3?, zone: string?)
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") or amount <= 0 then
		return
	end
	local shot = at ~= nil
	local billboard = create("BillboardGui", {
		Size = UDim2.fromOffset(90, 40),
		StudsOffset = if shot then Vector3.new(0, 0.4, 0) else Vector3.new(math.random(-10, 10) / 10, 2.2, 0),
		StudsOffsetWorldSpace = if shot then (at :: Vector3) - head.Position else Vector3.zero,
		AlwaysOnTop = true,
		Adornee = head,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local label = Theme.label({
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.TitleFace,
		Text = if shot then (if zone == "Head" then "✦" else "") .. tostring(amount) else (if blocked then "🛡 " else "") .. "-" .. tostring(amount),
		TextSize = if shot and zone == "Head" then 32 elseif heavy then 30 else 24,
		TextColor3 = if blocked then rgb(160, 200, 255)
			elseif shot and zone == "Head" then rgb(255, 220, 60)
			elseif shot then rgb(255, 255, 255)
			elseif heavy then rgb(255, 120, 60)
			else rgb(255, 230, 90),
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = billboard,
	})
	TweenService:Create(billboard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.85, function()
		billboard:Destroy()
	end)
end

-- Destello rojo (o azul si se ha defendido)
local function flash(model: Model, blocked: boolean)
	local highlight = create("Highlight", {
		FillColor = if blocked then rgb(120, 180, 255) else rgb(255, 60, 60),
		FillTransparency = 0.35,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Adornee = model,
		Parent = model,
	})
	TweenService:Create(highlight, TweenInfo.new(0.25), { FillTransparency = 1 }):Play()
	task.delay(0.3, function()
		highlight:Destroy()
	end)
end

-- Temblor compartido (CameraShake): va después de la cámara de Roblox, así que sí se ve
local function shake(strength: number, seconds: number?)
	CameraShake.shake(strength, seconds or 0.2)
end

-- K.O.: te caes, no puedes moverte y cuenta atrás; al acabar te levantas
local function showKnockOut(on: boolean)
	local humanoid = parts()
	if humanoid then
		humanoid.PlatformStand = on
		if not on then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if koGui then
		koGui:Destroy()
		koGui = nil
	end
	-- Sin vida (Fallen): la pantalla es la de HAS CAÍDO EN COMBATE (Controllers/DeathUI); esta, solo el
	-- K.O. del táser
	if not on or player:GetAttribute("Fallen") ~= nil then
		return
	end
	local gui = create("ScreenGui", { Name = "KnockOut", ResetOnSpawn = true, IgnoreGuiInset = true, DisplayOrder = 8, Parent = player:WaitForChild("PlayerGui") })
	koGui = gui
	local shade = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(60, 0, 0), BackgroundTransparency = 1, Parent = gui })
	TweenService:Create(shade, TweenInfo.new(0.4), { BackgroundTransparency = 0.55 }):Play()
	Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(400, 80), FontFace = Theme.TitleFace, Text = "K.O.", TextSize = 72, TextColor3 = rgb(255, 90, 80), TextStrokeTransparency = 0.2, TextXAlignment = Enum.TextXAlignment.Center, Parent = gui })
	local counter = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(400, 30), Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = gui })
	task.spawn(function()
		local left = Combat.KOSeconds
		while koGui == gui and left > 0 do
			counter.Text = ("Te levantas en %d…"):format(math.ceil(left))
			left -= task.wait(0.2)
		end
	end)
end

-- El modelo de quien pega (Player -> su personaje; los rivales llegan como Model)
local function modelOf(ref: any): Model?
	if typeof(ref) ~= "Instance" then
		return nil
	end
	if ref:IsA("Player") then
		return ref.Character
	end
	return if ref:IsA("Model") then ref else nil
end

local function onHit(data: { [string]: any })
	local model = data.Victim :: Model?
	if not model or not model.Parent then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local move = Combat.Moves[data.Move or ""]
	local heavy = data.Combo == 3 or (move ~= nil and move.Heavy == true)
	local big = data.Label ~= nil or data.Down ~= nil or data.GuardBroken == true
	local attackerModel = data.AttackerModel or modelOf(data.Attacker)
	local mine = model == player.Character
	local byMe = data.Attacker == player
	-- Los disparos (WeaponService) tienen su propio sonido e impacto (WeaponFx)
	if not data.Weapon then
		SoundFx.play(if data.Down then "GolpeCaida" else "Golpe", if heavy then 1.2 else 0.8, if data.Blocked then 1.6 else (if heavy then 0.8 else 1.1), root)
		-- Impacto: chispas, anillo y destello entre los dos (a la altura del pecho)
		local at = data.At
		if typeof(at) ~= "Vector3" and root then
			local from = attackerModel and attackerModel:FindFirstChild("HumanoidRootPart") :: BasePart?
			at = if from then root.Position:Lerp(from.Position, 0.3) + Vector3.new(0, 0.8, 0) else root.Position + Vector3.new(0, 0.8, 0)
		end
		if typeof(at) == "Vector3" and not data.Toy then
			CombatFx.impact(at, if typeof(data.Direction) == "Vector3" then data.Direction else Vector3.zero, if big then 1 elseif heavy then 0.65 else 0.3, data.Energy == true, data.Blocked == true)
		end
		-- Congelación del impacto (el golpe y los dos cuerpos se paran un instante)
		local stop = tonumber(data.Hitstop) or 0
		if stop > 0 then
			CombatFx.hitstop({ model, attackerModel }, stop)
		end
		if type(data.Label) == "string" and (mine or byMe or big) then
			CombatFx.label(model, data.Label, if data.GuardBroken then rgb(140, 200, 255) elseif data.Energy then rgb(150, 255, 210) else nil)
		end
	end
	if not data.Toy then
		flash(model, data.Blocked)
	end
	-- El cuerpo reacciona: cabeza atrás, tambaleo o caída si es fuerte
	if data.Blocked then
		ReactMotion.play(model, "BlockHit")
	elseif heavy then
		ReactMotion.play(model, "HitHeavy")
	else
		ReactMotion.play(model, "HitLight", { Side = if math.random() < 0.5 then -1 else 1 })
	end
	damageNumber(model, data.Amount, data.Blocked, heavy, if data.Weapon then data.At else nil, data.Zone)
	if mine or byMe then
		lastFight = os.clock()
	end
	if mine then
		lastHitAt = os.clock()
		localChain = Combat.newChain()
		if charging then
			CombatController.charge(false)
		end
		-- El empujón se aplica aquí: tu personaje lo mueve tu dispositivo
		if not data.Weapon then
			HitReaction.received(data)
		elseif data.Knockback and data.Knockback > 0 and typeof(data.Direction) == "Vector3" then
			local _, myRoot = parts()
			if myRoot then
				myRoot.AssemblyLinearVelocity += data.Direction * data.Knockback
			end
		end
		shake(if big then 1.4 elseif heavy then 1.1 else 0.5, if big then 0.35 else 0.2)
	elseif byMe then
		shake(if big then 0.8 elseif heavy then 0.5 else 0.2)
		if not data.Weapon then
			if (data.Amount or 0) > 0 and not data.Blocked then
				CombatHud.countHit()
			end
			if data.Air and not data.Blocked then
				HitReaction.follow(data)
			end
		end
	end
end

local function onSwing(attacker: any, move: any)
	local character = modelOf(attacker)
	if not character or character == player.Character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local def = Combat.Moves[move]
	local heavy = (def and def.Heavy) or move == 3
	if root then
		SoundFx.play("Salto", 0.7, if heavy then 0.8 else 1.3, root)
	end
	PunchAnim.hold(character, "Windup", false)
	CombatFx.stopWindup(character)
	swingPose(character, animOf(move))
end

-- Poderes de cualquiera (visuales)
local function onPower(ref: any, id: string, params: { [string]: any })
	local model = modelOf(ref)
	local p = Powers.get(id)
	if not p or type(params) ~= "table" then
		return
	end
	local origin = if typeof(params.Origin) == "Vector3" then params.Origin else nil
	local dir = if typeof(params.Dir) == "Vector3" then params.Dir else Vector3.new(0, 0, -1)
	if not origin then
		return
	end
	if model then
		PunchAnim.play(model, "Blast")
		if model ~= player.Character or not charging then
			CombatFx.aura(model, false)
		end
	end
	local target = if typeof(params.Target) == "Instance" and params.Target:IsA("Model") then params.Target else nil
	if id == "Esferas" then
		task.spawn(function()
			for i = 1, p.Count or 1 do
				local from = (model and model:FindFirstChild("HumanoidRootPart") :: BasePart?)
				local start = if from then from.Position + Vector3.new(0, 0.6, 0) + dir * 2 else origin
				CombatFx.orb(start, dir, p.Speed or 100, p.Range, target, model)
				SoundFx.play("DisparoTaser", 0.5, 1.2)
				if i < (p.Count or 1) then
					task.wait(0.12)
				end
			end
		end)
	elseif id == "Embestida" then
		CombatFx.dash(model, dir)
		SoundFx.play("Salto", 0.8, 0.6)
		if model and model == player.Character then
			-- Te lanzas tú (tu personaje lo mueve tu dispositivo)
			local _, root = parts()
			if root then
				local flat = Vector3.new(dir.X, 0, dir.Z)
				flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
				root.AssemblyLinearVelocity = flat * (p.Speed or 90) + Vector3.new(0, 4, 0)
				task.delay(0.25, function()
					if root.Parent then
						local v = root.AssemblyLinearVelocity
						root.AssemblyLinearVelocity = Vector3.new(v.X * 0.2, v.Y, v.Z * 0.2)
					end
				end)
			end
		end
	elseif id == "Onda" then
		local charge = tonumber(params.Charge) or 0
		local k = if p.MaxCharge then math.clamp(charge / p.MaxCharge, 0, 1) else 0
		task.delay(0.12, function()
			CombatFx.wave(origin, dir, p.Range, (p.Width or 4) * (0.8 + 0.6 * k), 0.45 + 0.3 * k)
		end)
		if model == player.Character then
			shake(0.6 + 0.6 * k, 0.4)
		end
	elseif id == "Explosivo" then
		task.delay(0.18, function()
			local flat = Vector3.new(dir.X, 0, dir.Z)
			flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zero
			CombatFx.explosion(origin + flat * 4, p.Radius or 8)
		end)
	end
end

local function onUltimate(ref: any, phase: string, params: { [string]: any })
	local model = modelOf(ref)
	params = if type(params) == "table" then params else {}
	local p = Powers.Ultimate
	if phase == "Start" then
		local target = params.Target
		local involved = ref == player or (target ~= nil and target == player.Character)
		CombatFx.ultimateStart(model, tonumber(params.WindUp) or p.WindUp or 1.2, involved)
		if model then
			CombatFx.label(model, p.Name, rgb(150, 255, 210))
		end
	elseif phase == "Fire" then
		local origin = if typeof(params.Origin) == "Vector3" then params.Origin else nil
		local dir = if typeof(params.Dir) == "Vector3" then params.Dir else Vector3.new(0, 0, -1)
		if origin then
			local _, root = parts()
			local near = root ~= nil and (root.Position - origin).Magnitude < 80
			CombatFx.ultimateFire(origin, dir, p.Range, p.Width or 8, near)
			if model then
				PunchAnim.play(model, "Blast")
			end
		end
	elseif phase == "Cancel" then
		CombatFx.aura(model, false)
		PunchAnim.hold(model, "Aim", false)
		if ref == player then
			CombatFx.cancelCinematic()
		end
	end
end

-- 🛡 encima de quien se está defendiendo
local shields: { [Player]: BillboardGui } = {}
local function updateShield(other: Player)
	local on = other:GetAttribute("Blocking") == true
	-- (tu propia guardia sigue a tu dedo, aunque el servidor tarde en confirmarla)
	guardPose(other.Character, on or (other == player and blocking))
	local existing = shields[other]
	-- (el de un personaje que ya no está —reapareció, se fue lejos— se quita: si no, se quedaba
	-- colgado y el nuevo personaje ya no recibía el suyo)
	if existing and not (existing.Adornee and existing.Adornee:IsDescendantOf(workspace)) then
		existing:Destroy()
		shields[other] = nil
		existing = nil
	end
	if on and not existing then
		local head = other.Character and other.Character:FindFirstChild("Head")
		if head then
			local billboard = create("BillboardGui", { Size = UDim2.fromOffset(40, 40), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true, Adornee = head, Parent = player:WaitForChild("PlayerGui") })
			Theme.label({ Size = UDim2.fromScale(1, 1), Text = "🛡", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = billboard })
			shields[other] = billboard
		end
	elseif not on and existing then
		existing:Destroy()
		shields[other] = nil
	end
end

-- Aura de cargar energía (cualquier jugador)
local function updateCharging(other: Player)
	local on = other:GetAttribute("Charging") == true
	local character = other.Character
	-- (el servidor ha cortado tu carga: un golpe, aturdido… se suelta también aquí)
	if other == player and not on and charging then
		CombatController.charge(false)
	end
	if other == player and powerHeld then
		return -- (cargando la onda: ya tiene su aura)
	end
	CombatFx.aura(character, on)
	PunchAnim.hold(character, "Charge", on)
	if on and character and other == player then
		SoundFx.play("DisparoTaser", 0.4, 0.4)
	end
end

---------------------------------------------------------------------
-- Controles
---------------------------------------------------------------------
-- ¿Hay algo en el mundo bajo el ratón que se use con clic? (entonces el clic no es un puñetazo)
local function clickTarget(): boolean
	local ok, used = pcall(function()
		local mouse = player:GetMouse()
		local node: Instance? = mouse.Target
		for _ = 1, 6 do
			if not node then
				return false
			end
			if node:FindFirstChildOfClass("ClickDetector") or node:FindFirstChildOfClass("ProximityPrompt") then
				return true
			end
			node = node.Parent
		end
		return false
	end)
	return ok and used == true
end

-- ¿Se puede pelear con las manos ahora? (sin arma en la mano, a pie, sin nadar)
local function handsFree(): boolean
	local humanoid = parts()
	if not CombatController.canAttack() or armed() then
		return false
	end
	if player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil then
		return false
	end
	if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return false
	end
	return true
end

function CombatController.init()
	-- La voltereta de esquivar (la tuya y la de los demás)
	local okRoll, errRoll = pcall(RollMotion.init)
	if not okRoll then
		warn("[Combate] Voltereta: " .. tostring(errRoll))
	end
	local okHud, errHud = pcall(CombatHud.init)
	if not okHud then
		warn("[Combate] Barras: " .. tostring(errHud))
	end
	pcall(HitReaction.init)
	HitReaction.onWall(function(at)
		send("Wall", at)
	end)
	local function onEvent(kind: string, a: any, b: any, c: any)
		local ok, err = pcall(function()
			if kind == "Hit" then
				onHit(a)
			elseif kind == "Swing" and a ~= player then
				onSwing(a, b)
			elseif kind == "Miss" then
				local model = modelOf(a)
				if model then
					CombatFx.label(model, "¡Esquivado!", rgb(235, 245, 255))
				end
			elseif kind == "Vanish" and typeof(b) == "Vector3" and typeof(c) == "Vector3" then
				CombatFx.vanish(b, c)
				if a == player then
					localChain = Combat.newChain()
				end
			elseif kind == "Guard" then
				guardPose(modelOf(a), b == true)
			elseif kind == "Windup" then
				local model = modelOf(a)
				PunchAnim.hold(model, "Windup", true)
				CombatFx.windup(model, tonumber(b) or Combat.ChargeTime)
				task.delay(tonumber(b) or Combat.ChargeTime, function()
					PunchAnim.hold(model, "Windup", false)
				end)
			elseif kind == "Power" then
				onPower(a, b, c)
			elseif kind == "Ultimate" then
				onUltimate(a, b, c)
			elseif kind == "Wall" and typeof(b) == "Vector3" and a ~= player.Character then
				CombatFx.wall(b)
			end
		end)
		if not ok then
			warn("[Combate] " .. tostring(err))
		end
	end

	-- El remoto lo crea el servidor (CombatService): se espera sin parar el resto (botones y teclas)
	task.spawn(function()
		local found = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat", 30) :: RemoteEvent?
		if not found then
			warn("[Combate] No está el remoto Combat")
			return
		end
		Remote = found
		found.OnClientEvent:Connect(onEvent)
	end)

	local function typing(): boolean
		return UserInputService:GetFocusedTextBox() ~= nil
	end
	local function began(state: Enum.UserInputState): boolean
		return state == Enum.UserInputState.Begin and not typing()
	end
	local function ended(state: Enum.UserInputState): boolean
		return state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel
	end
	ContextActionService:BindAction("CombatAttack", function(_, state)
		if began(state) then
			CombatController.attack()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.X, Enum.KeyCode.ButtonR1)
	-- Fuerte: C (teclado) y RT (mando, sin arma: con arma RT dispara)
	ContextActionService:BindAction("CombatHeavy", function(_, state, input)
		if input.KeyCode == Enum.KeyCode.ButtonR2 and armed() then
			return Enum.ContextActionResult.Pass
		end
		if ended(state) then
			if heavyHeldAt then
				CombatController.heavy(false)
			end
		elseif began(state) and handsFree() then
			CombatController.heavy(true)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C, Enum.KeyCode.ButtonR2)
	ContextActionService:BindAction("CombatBlock", function(_, state, input)
		-- Soltar la tecla siempre cuenta (aunque se esté escribiendo): si no, la guardia se queda puesta
		if ended(state) then
			CombatController.setBlocking(false)
		elseif began(state) then
			-- (F también es levantarse de un asiento y bajarse de un vehículo: entonces no es la guardia)
			if input.KeyCode == Enum.KeyCode.F and not handsFree() then
				return Enum.ContextActionResult.Pass
			end
			CombatController.setBlocking(true)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Z, Enum.KeyCode.F, Enum.KeyCode.ButtonL1)

	ContextActionService:BindAction("CombatDodge", function(_, state)
		if began(state) then
			CombatController.dodge()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	-- V: fijar / el siguiente; mantener V: soltar
	local lockDownAt = 0
	ContextActionService:BindAction("CombatLock", function(_, state)
		if began(state) then
			lockDownAt = os.clock()
			local mine = lockDownAt
			task.delay(0.45, function()
				if lockDownAt == mine and UserInputService:IsKeyDown(Enum.KeyCode.V) and lockTarget then
					lockDownAt = 0
					CombatController.setLock(nil)
				end
			end)
		elseif state == Enum.UserInputState.End and lockDownAt > 0 then
			lockDownAt = 0
			CombatController.toggleLock()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.V)
	-- Mando: R3 fija objetivo solo en plena pelea (y entonces no enciende la linterna); si no, pasa
	ContextActionService:BindActionAtPriority("CombatLockPad", function(_, state)
		if typing() or not (lockTarget or (CombatController.inCombat() and CombatController.canAttack())) then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			CombatController.toggleLock()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR3)
	-- Poderes: G / X (mando, en plena pelea) cargar · Y / cruceta izquierda habilidad · U cambiar · R definitiva
	ContextActionService:BindAction("CombatCharge", function(_, state, input)
		if ended(state) then
			if charging then
				CombatController.charge(false)
			end
			return Enum.ContextActionResult.Pass
		end
		if not began(state) or not powerSet().Energia or not handsFree() then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.ButtonX and not CombatController.inCombat() then
			return Enum.ContextActionResult.Pass -- (fuera de una pelea, X es para los carteles)
		end
		CombatController.charge(true)
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G, Enum.KeyCode.ButtonX)
	ContextActionService:BindAction("CombatPower", function(_, state, input)
		if input.KeyCode == Enum.KeyCode.DPadLeft and armed() then
			return Enum.ContextActionResult.Pass -- (con arma: recargar)
		end
		if ended(state) then
			CombatController.power(false)
		elseif began(state) and handsFree() and selected() then
			-- (mando: con la guardia puesta, la cruceta cambia de habilidad)
			if input.KeyCode == Enum.KeyCode.DPadLeft and blocking then
				CombatController.nextPower()
			else
				CombatController.power(true)
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Y, Enum.KeyCode.DPadLeft)
	ContextActionService:BindAction("CombatNextPower", function(_, state)
		if began(state) then
			CombatController.nextPower()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.U)
	ContextActionService:BindAction("CombatUltimate", function(_, state)
		if began(state) and handsFree() and powerSet().Definitiva then
			local okPrompt, inUse = pcall(function()
				return (require(script.Parent.Prompts) :: any).keyInUse(Enum.KeyCode.R)
			end)
			if not (okPrompt and inUse) then
				CombatController.ultimate()
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R)

	-- Ratón: clic izquierdo ligero; clic derecho fuerte (un toque; mantenerlo quieto = cargado; si
	-- arrastras, es girar la cámara y no pega)
	local rightAt: number? = nil
	local rightPos = Vector2.zero
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or typing() or TouchLayout.isTouch() then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 then
			if handsFree() and not clickTarget() then
				CombatController.attack()
			end
		elseif t == Enum.UserInputType.MouseButton2 then
			if handsFree() then
				rightAt = os.clock()
				rightPos = UserInputService:GetMouseLocation()
				local mine = rightAt
				task.delay(0.22, function()
					-- Quieto con el botón pulsado: empieza a cargar el golpe
					if rightAt == mine and (UserInputService:GetMouseLocation() - rightPos).Magnitude < 8 then
						CombatController.heavy(true)
					end
				end)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 or not rightAt then
			return
		end
		local held = os.clock() - rightAt
		local moved = (UserInputService:GetMouseLocation() - rightPos).Magnitude
		rightAt = nil
		if heavyHeldAt then
			if moved < 14 then
				CombatController.heavy(false)
			else
				-- (se puso a girar la cámara: no sale el golpe)
				heavyHeldAt = nil
				PunchAnim.hold(player.Character, "Windup", false)
				CombatFx.stopWindup(player.Character)
			end
		elseif held < 0.22 and moved < 8 and handsFree() then
			CombatController.heavyTap()
		end
	end)

	-- Impulso aéreo (Saltar en el aire): poder de la Grieta, gasta aguante
	TouchLayout.onJump(function(down: boolean, humanoid: Humanoid)
		if not down or not powerSet().AirDash or humanoid.FloorMaterial ~= Enum.Material.Air then
			return nil
		end
		if stamina() < Combat.AirDashCost or not handsFree() then
			return nil
		end
		local move = humanoid.MoveDirection
		if HitReaction.airDash(move) then
			send("AirDash")
			return true
		end
		return nil
	end)
	-- Ordenador y mando: Espacio / A otra vez en el aire (una pulsación nueva: mantenerla no gasta impulsos)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or typing() or TouchLayout.isTouch() then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.Space and input.KeyCode ~= Enum.KeyCode.ButtonA then
			return
		end
		local humanoid = parts()
		if humanoid and powerSet().AirDash and humanoid.FloorMaterial == Enum.Material.Air and stamina() >= Combat.AirDashCost and handsFree() then
			if HitReaction.airDash(humanoid.MoveDirection) then
				send("AirDash")
			end
		end
	end)

	-- La guardia se quita sola al empezar a hablar, montarse o sentarse (si no, se queda puesta)
	local function dropGuard()
		if blocking or charging then
			local humanoid = parts()
			if player:GetAttribute("InDialogue") or player:GetAttribute("Riding") ~= nil or (humanoid and humanoid.SeatPart) then
				CombatController.setBlocking(false)
				CombatController.charge(false)
			end
		end
	end
	for _, attribute in { "InDialogue", "Riding" } do
		player:GetAttributeChangedSignal(attribute):Connect(dropGuard)
	end
	local function watchSeat(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid:GetPropertyChangedSignal("SeatPart"):Connect(dropGuard)
		end
	end
	if player.Character then
		task.spawn(watchSeat, player.Character)
	end
	player.CharacterAdded:Connect(watchSeat)
	-- Rodar tras un salto: se mira cada fotograma si acabas de tocar el suelo
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(CombatController.landingCheck)
		if not ok then
			warn("[Combate] " .. tostring(err))
		end
	end)
	player.CharacterAdded:Connect(function()
		airRollAt, wasAirborne = nil, false
		player:SetAttribute("RollQueued", nil)
	end)

	-- Botones del racimo (móvil) y pistas de teclas (ordenador): solo cuando se puede pelear
	local function canFight(): boolean
		return CombatController.canAttack()
	end
	-- Móvil: con un arma en la mano, Disparar, Apuntar y Recargar ocupan los huecos de golpear, defender
	-- y fijar; si estos pasaban a la columna de contexto la llenaban y echaban a otros (linterna, foto…)
	local function canPunch(): boolean
		return canFight() and (not TouchLayout.isTouch() or not armed())
	end
	local function fighting(): boolean
		return canPunch() and not armed() and CombatController.inCombat()
	end
	-- Móvil: Fijar objetivo ya no está en el racimo (docs/referencias/hud-movil-botones.jpg): sale en la
	-- columna pequeña de contexto solo en plena pelea
	local function canLock(): boolean
		return canPunch() and (not TouchLayout.isTouch() or CombatController.inCombat() or CombatController.isLocked())
	end
	TouchLayout.register({ Id = "Ataque", Icon = "espada", Label = "Atacar", Slot = "Ataque", Priority = 3, Key = "Clic / X", Pad = "RB", Visible = canPunch, Callback = CombatController.attack })
	-- En un combate de misión el botón grande dice «Atacar» (le da al enemigo más cercano desde lejos)
	task.spawn(function()
		local shown: string? = nil
		while true do
			task.wait(0.4)
			local label = if CombatController.missionTarget() then "Atacar" else nil
			if label ~= shown then
				shown = label
				TouchLayout.setLabel("Ataque", label)
			end
		end
	end)
	TouchLayout.register({
		Id = "Defender", Icon = "escudo", Label = "Defensa", Slot = "Defender", Priority = 4, Key = "F / Z", Pad = "LB",
		Visible = canPunch,
		Active = CombatController.isBlocking,
		Hold = function(down: boolean)
			CombatController.setBlocking(down)
		end,
	})
	TouchLayout.register({ Id = "Esquivar", Icon = "esquivar", Label = "Esquivar", Slot = "Esquivar", Priority = 5, Key = "Q", Pad = "B", Visible = canFight, Callback = CombatController.dodge,
		Meter = function()
			return if CombatController.inCombat() then stamina() / Combat.StaminaMax else nil
		end,
	})
	TouchLayout.register({ Id = "Fijar", Icon = "objetivo", Label = "Fijar", Slot = "Fijar", Priority = 6, Key = "V", Pad = "R3", Visible = canLock, Active = CombatController.isLocked, Callback = CombatController.toggleLock })
	-- Fuerte: en plena pelea ocupa el hueco de Gestos (mantener = golpe cargado)
	TouchLayout.register({
		Id = "Fuerte", Icon = "espada", Label = "Fuerte", Slot = "Gestos", Priority = 6.5, Key = "Clic dcho / C", Pad = "RT",
		Visible = fighting,
		Active = function()
			return if heavyHeldAt then (if os.clock() - heavyHeldAt >= Combat.ChargeTime then true else "wait") else false
		end,
		Hold = function(down: boolean)
			CombatController.heavy(down)
		end,
	})
	-- Poderes de la Grieta (solo despiertos y en plena pelea)
	TouchLayout.register({
		Id = "Cargar", Icon = "rayo", Label = "Cargar", Priority = 8, Key = "G", Pad = "X",
		Visible = function()
			return fighting() and powerSet().Energia == true
		end,
		Active = CombatController.isCharging,
		Meter = function()
			return energy() / Combat.EnergyMax
		end,
		Hold = function(down: boolean)
			CombatController.charge(down)
		end,
	})
	TouchLayout.register({
		Id = "Definitiva", Icon = "corona", Label = "Definitiva", Priority = 8.5, Key = "R", Pad = "LB+RT",
		Visible = function()
			return fighting() and powerSet().Definitiva == true
		end,
		Active = function()
			return energy() >= Powers.Ultimate.Cost
		end,
		Callback = CombatController.ultimate,
	})
	TouchLayout.register({
		Id = "Poder", Icon = "rayo", Label = "Poder", Priority = 9, Key = "Y", Pad = "←",
		Visible = function()
			return fighting() and selected() ~= nil
		end,
		Active = function()
			local p = selected()
			if powerHeld then
				return true
			end
			return if p and energy() >= p.Cost then false else "wait"
		end,
		Hold = function(down: boolean)
			CombatController.power(down)
		end,
	})
	TouchLayout.register({
		Id = "CambiarPoder", Icon = "habilidades", Label = "Cambiar", Priority = 9.5, Key = "U", Pad = "LB+←",
		Visible = function()
			return fighting() and #abilities() > 1
		end,
		Callback = CombatController.nextPower,
	})
	local function syncPowers()
		local p = selected()
		CombatHud.setSelected(p and p.Id)
		if p then
			TouchLayout.setLabel("Poder", p.Name)
			TouchLayout.setIcon("Poder", p.Icon)
		end
		if not powerSet().Energia and charging then
			CombatController.charge(false)
		end
		TouchLayout.refresh()
	end
	player:GetAttributeChangedSignal("Powers"):Connect(syncPowers)
	syncPowers()

	-- Las barras (aguante, energía, guardia), 10 veces por segundo
	task.spawn(function()
		while true do
			task.wait(0.1)
			local ok, err = pcall(CombatHud.update, CombatController.inCombat() or charging, blocking)
			if not ok then
				warn("[Combate] Barras: " .. tostring(err))
				task.wait(2)
			end
		end
	end)

	player:GetAttributeChangedSignal("KO"):Connect(function()
		local ko = player:GetAttribute("KO") == true
		if ko then
			blocking = false
			guardPose(player.Character, false)
			CombatController.charge(false)
		end
		showKnockOut(ko)
	end)
	player.CharacterAdded:Connect(function()
		tracks = {}
		blocking = false
		charging = false
		Controls.enable("CargarEnergia")
		heavyHeldAt = nil
		powerHeld = nil
		localChain = Combat.newChain()
		CombatController.setLock(nil)
		showKnockOut(false)
		HitReaction.reset()
	end)

	local function watch(other: Player)
		other:GetAttributeChangedSignal("Blocking"):Connect(function()
			updateShield(other)
		end)
		other:GetAttributeChangedSignal("Charging"):Connect(function()
			updateCharging(other)
		end)
		-- Al reaparecer (o al quitarse el personaje), el 🛡 del cuerpo anterior se quita
		other.CharacterRemoving:Connect(function()
			if shields[other] then
				shields[other]:Destroy()
				shields[other] = nil
			end
		end)
		other.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			updateShield(other)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerRemoving:Connect(function(other)
		if shields[other] then
			shields[other]:Destroy()
			shields[other] = nil
		end
	end)
end

return CombatController
