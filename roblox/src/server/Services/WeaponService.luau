-- WeaponService: armas de fuego (y de juguete), Armerías, licencia de armas y galería de tiro.
-- Las reglas y los números están en shared/Weapons; aquí se decide todo lo que cuenta.
--
-- El cliente (WeaponController) solo pide:
--   "Equip", id|nil      empuñar el arma de la casilla elegida de la barra rápida (nil = guardarla)
--   "Aim", on            apuntar / dejar de apuntar            "Pitch", ángulo   hacia dónde apunta
--   "Fire", punto        disparar hacia ese punto (el de la mira)
--   "Reload"             recargar                              "Mode"            selector semi/auto
--   "Buy", id            comprar en la Armería                 "Answers", token, respuestas (test)
-- El servidor comprueba el arma, la edad, la licencia, las balas, la cadencia, el alcance, la línea
-- de tiro desde la cabeza y las zonas seguras; hace su propio rayo con la dispersión y aplica el daño
-- con CombatService.applyHit (mismo K.O., muerte y hospital que los golpes). Avisa a todos ("Shot")
-- para que vean el fogonazo, el trazador, los impactos, los casquillos y oigan el disparo.
--
-- Normas (shared/Weapons):
--   * Armas de verdad: desde AdultoJoven, con licencia de armas. Los niños solo de juguete.
--   * Licencia: tasa + test de seguridad en la ventanilla de LICENCIAS de las Armerías o en el
--     mostrador de la comisaría. Sin estrellas ni antecedentes. Una condena la retira.
--   * Disparar a alguien -> delito (WantedService: Disparo; si muere, Homicidio). Disparar en la
--     calle -> Disparos (si lo ve alguien). La policía de servicio contra un buscado, no. En la galería
--     de tiro de las Armerías practicar nunca es delito.
--   * Zonas seguras (no se dispara): hospitales, colegios, dentro de casas y de los edificios con
--     interior (salvo la policía de servicio), y las piezas con la etiqueta SafeZone.
--   * Policía de servicio: al empezar el turno (PoliceService) le dan la pistola reglamentaria y el
--     táser, con munición de la comisaría; al acabar se devuelven.
--   * Oficio de armero/a (tablón de la Armería): atiende a los clientes del mostrador y se lleva
--     una comisión de lo que compran los jugadores. Sin nadie de turno atiende un dependiente NPC.
-- Atributos del jugador: Weapon, WeaponMag, WeaponAmmo (-1 = infinita), FireMode, Aiming, AimPitch,
-- Reloading, WeaponLicence, Holstered. Datos guardados: data.WeaponMags = { [arma] = balas }.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Format = require(ReplicatedStorage.Shared.Format)
local Config = require(ReplicatedStorage.Shared.Config)
local WeaponModel = require(script.Parent.Parent.World.Kit.WeaponModel)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService) -- modo pruebas: se salta los requisitos
local InventoryService = require(script.Parent.InventoryService)
local CombatService = require(script.Parent.CombatService)
local WantedService = require(script.Parent.WantedService)
local NeedsService = require(script.Parent.NeedsService)
local JobService = require(script.Parent.JobService)
local RoleService = require(script.Parent.RoleService)
local LifeService = require(script.Parent.LifeService)
local BreakService = require(script.Parent.BreakService)

local WeaponService = {}

local Remote: RemoteEvent
local Notify: RemoteEvent

local PUBLIC_CRIME_GAP = 30 -- segundos entre dos denuncias por disparar en la calle
local CLERK_COMMISSION = 0.1
local CUSTOMER_EVERY = { 30, 50 }
local SAFE_MODELS = { Hospital = "el hospital", CentroSalud = "el centro de salud", Colegio = "el colegio" }

type State = {
	Equipped: string?,
	LastShot: number,
	Shot: number,
	Bloom: number,
	Reloading: number,
	Token: number,
	Mode: { [string]: string },
	PublicCrimeAt: number,
	SafeWarnAt: number,
	PitchAt: number,
	Quiz: { Token: string, Correct: { number } }?,
}

local states: { [Player]: State } = {}
local safeBoxes: { { CFrame: CFrame, Size: Vector3, Name: string } } = {}

local function stateOf(player: Player): State
	local s = states[player]
	if not s then
		s = { Equipped = nil, LastShot = -math.huge, Shot = 0, Bloom = 0, Reloading = 0, Token = 0, Mode = {}, PublicCrimeAt = -math.huge, SafeWarnAt = 0, PitchAt = 0, Quiz = nil }
		states[player] = s
	end
	return s
end

local function partsOf(player: Player): (Humanoid?, BasePart?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChild("Head") :: BasePart?
end

local function inside(part: BasePart, position: Vector3, margin: number?): boolean
	local rel = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2 + Vector3.new(1, 1, 1) * (margin or 0)
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end

local function mags(player: Player): { [string]: number }
	local data = DataService.get(player)
	if not data then
		return {}
	end
	data.WeaponMags = data.WeaponMags or {}
	return data.WeaponMags
end

local function hasLicence(player: Player): boolean
	return InventoryService.count(player, Weapons.Licence.Item) > 0
end

local function owns(player: Player, w: Weapons.Weapon): boolean
	return InventoryService.count(player, Weapons.itemId(w.Id)) > 0
end

local function reserveOf(player: Player, w: Weapons.Weapon): number
	if not w.Ammo then
		return math.huge
	end
	return InventoryService.count(player, w.Ammo)
end

local function publish(player: Player)
	local s = stateOf(player)
	local w = Weapons.get(s.Equipped)
	player:SetAttribute("Weapon", if w then w.Id else nil)
	if w then
		player:SetAttribute("WeaponMag", mags(player)[w.Id] or 0)
		local reserve = reserveOf(player, w)
		player:SetAttribute("WeaponAmmo", if reserve == math.huge then -1 else reserve)
		player:SetAttribute("FireMode", s.Mode[w.Id] or w.Modes[1])
	else
		player:SetAttribute("WeaponMag", nil)
		player:SetAttribute("WeaponAmmo", nil)
		player:SetAttribute("FireMode", nil)
	end
	player:SetAttribute("WeaponLicence", hasLicence(player) or nil)
end

---------------------------------------------------------------------
-- Zonas seguras y galería de tiro
---------------------------------------------------------------------

local function inRange(position: Vector3): boolean
	for _, volume in CollectionService:GetTagged("ShootingRange") do
		if volume:IsA("BasePart") and inside(volume, position, 1) then
			return true
		end
	end
	return false
end

-- Nombre de la zona segura en la que está (o nil)
function WeaponService.safeZone(player: Player, position: Vector3): string?
	if inRange(position) then
		return nil
	end
	local onDuty = WantedService.onDuty(player)
	if player:GetAttribute("InteriorKey") and not onDuty then
		return "dentro de un edificio"
	end
	return WeaponService.safeSpot(position)
end

-- Zona segura solo por el sitio, sin mirar quién es (para quien recibe un disparo, un golpe o un
-- robo: antes solo se miraba al que ataca). En la galería de tiro, nunca.
function WeaponService.safeSpot(position: Vector3): string?
	if inRange(position) then
		return nil
	end
	for _, volume in CollectionService:GetTagged("SafeZone") do
		if volume:IsA("BasePart") and inside(volume, position) then
			return volume:GetAttribute("ZoneName") or "esta zona"
		end
	end
	for _, room in CollectionService:GetTagged("Room") do
		if room:IsA("BasePart") and inside(room, position) then
			return "dentro de una casa"
		end
	end
	for _, room in CollectionService:GetTagged("Classroom") do
		if room:IsA("BasePart") and inside(room, position) then
			return "el colegio"
		end
	end
	for _, box in safeBoxes do
		local rel = box.CFrame:PointToObjectSpace(position)
		local half = box.Size / 2 + Vector3.new(12, 20, 12)
		if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z then
			return box.Name
		end
	end
	return nil
end

local function scanSafeBuildings()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	table.clear(safeBoxes)
	for _, model in town:GetDescendants() do
		local name = model:IsA("Model") and SAFE_MODELS[model.Name]
		if name then
			local ok, cf, size = pcall(function()
				return (model :: Model):GetBoundingBox()
			end)
			if ok then
				table.insert(safeBoxes, { CFrame = cf, Size = size, Name = name })
			end
		end
	end
end

---------------------------------------------------------------------
-- El arma en la mano (o guardada en la cadera / la espalda)
---------------------------------------------------------------------

local function scaleOf(character: Model): number
	local ok, value = pcall(function()
		return (character :: any):GetScale()
	end)
	return if ok and type(value) == "number" then value else 1
end

local function clearModel(character: Model?)
	if not character then
		return
	end
	for _, child in character:GetChildren() do
		if child.Name == "Arma" and child:IsA("Model") then
			child:Destroy()
		end
	end
end

local function attachModel(player: Player, w: Weapons.Weapon?, held: boolean)
	local character = player.Character
	clearModel(character)
	if not character or not w then
		player:SetAttribute("Holstered", nil)
		return
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local scale = scaleOf(character)
	local ok, model = pcall(WeaponModel.build, w, scale, false)
	if not ok or not model then
		return
	end
	local grip = model.PrimaryPart :: BasePart
	local weld = Instance.new("Weld")
	weld.Name = "AgarreArma"
	if held then
		weld.Part0 = hand
		weld.C0 = WeaponModel.gripOffset(w, scale)
	else
		local bodyName, offset = WeaponModel.holsterOffset(w, scale)
		local body = character:FindFirstChild(bodyName) or character:FindFirstChild("Torso")
		if not body or not body:IsA("BasePart") then
			model:Destroy()
			return
		end
		weld.Part0 = body
		weld.C0 = offset
	end
	weld.Part1 = grip
	weld.Parent = grip
	model:SetAttribute("Held", held)
	grip.CFrame = (weld.Part0 :: BasePart).CFrame * weld.C0
	model.Parent = character
	player:SetAttribute("Holstered", if held then nil else w.Id)
end

-- ¿Puede empuñarla ahora? (motivo si no)
local function canEquip(player: Player, w: Weapons.Weapon): (boolean, string?)
	local humanoid = partsOf(player)
	if not humanoid or humanoid.Health <= 0 then
		return false, nil
	end
	local tester = TesterService.bypass(player)
	if not tester and not Weapons.canHold(w, player:GetAttribute("LifeStage")) then
		return false, if w.Kind == "Toy" then "Aún no tienes edad para esto." else "Las armas de verdad no son para niños."
	end
	if not owns(player, w) then
		return false, nil
	end
	if w.Licence and not hasLicence(player) and not tester then
		return false, "Sin licencia de armas no puedes llevarla encima."
	end
	if w.Duty and not WantedService.onDuty(player) and not tester then
		return false, "Es un arma de servicio: solo de turno."
	end
	if player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return false, "Aquí dentro no se permiten armas."
	end
	if player:GetAttribute("Riding") then
		return false, "Primero bájate del vehículo."
	end
	return true, nil
end

function WeaponService.holster(player: Player)
	local s = stateOf(player)
	local w = Weapons.get(s.Equipped)
	s.Equipped = nil
	s.Token += 1
	s.Reloading = 0
	player:SetAttribute("Reloading", nil)
	if player:GetAttribute("Aiming") then
		player:SetAttribute("Aiming", nil)
		NeedsService.refreshSpeed(player)
	end
	-- Se guarda en la pistolera (si sigue siendo tuya y la puedes llevar)
	attachModel(player, if w and owns(player, w) and canEquip(player, w) then w else nil, false)
	publish(player)
end

function WeaponService.equip(player: Player, id: any): boolean
	local w = Weapons.get(id)
	if not w then
		WeaponService.holster(player)
		return false
	end
	local ok, reason = canEquip(player, w)
	if not ok then
		if reason then
			Notify:FireClient(player, "Error", reason)
		end
		return false
	end
	local s = stateOf(player)
	if s.Equipped == w.Id then
		return true
	end
	s.Equipped = w.Id
	s.Token += 1
	s.Reloading = 0
	s.Shot = 0
	s.Bloom = 0
	player:SetAttribute("Reloading", nil)
	local m = mags(player)
	if m[w.Id] == nil then
		m[w.Id] = if w.Ammo then 0 else w.Magazine
	end
	attachModel(player, w, true)
	publish(player)
	if w.Duty and not WantedService.onDuty(player) then
		-- (solo llega aquí el modo pruebas: fuera de turno es un arma más y disparar a alguien es delito)
		Notify:FireClient(player, "Info", "🧪 Arma de servicio fuera de turno: disparar a alguien es delito, como con cualquier arma.")
	end
	return true
end

local function setAiming(player: Player, on: boolean)
	local s = stateOf(player)
	local want = on and s.Equipped ~= nil and not player:GetAttribute("KO")
	if (player:GetAttribute("Aiming") == true) == want then
		return
	end
	player:SetAttribute("Aiming", if want then true else nil)
	if not want then
		player:SetAttribute("AimPitch", nil)
	end
	NeedsService.refreshSpeed(player)
end

---------------------------------------------------------------------
-- Disparar
---------------------------------------------------------------------

-- El personaje (modelo con Humanoid) al que pertenece una pieza
local function humanoidModel(part: Instance): Model?
	local node: Instance? = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function canShoot(player: Player): boolean
	local humanoid, root, head = partsOf(player)
	if not humanoid or not root or not head or humanoid.Health <= 0 or humanoid.SeatPart then
		return false
	end
	if player:GetAttribute("KO") or player:GetAttribute("InDialogue") or player:GetAttribute("JailUntil") or player:GetAttribute("Riding") then
		return false
	end
	return true
end

-- Diana de la galería: puntos según el aro (10 en el centro, 2 en el de fuera)
local function scoreTarget(target: BasePart, position: Vector3, shooter: Player)
	local rel = target.CFrame:PointToObjectSpace(position)
	local ringCenterY = target.Size.Y / 2 - 0.45 * target.Size.Y
	local distance = math.sqrt(rel.X ^ 2 + (rel.Y - ringCenterY) ^ 2)
	local ring = math.ceil(distance / 0.275)
	local points = if ring >= 1 and ring <= 5 then 12 - 2 * ring else 0
	local now = os.clock()
	if now - (target:GetAttribute("LastAt") or 0) > 45 or target:GetAttribute("Shooter") ~= shooter.UserId then
		target:SetAttribute("Score", 0)
		target:SetAttribute("Shots", 0)
	end
	target:SetAttribute("LastAt", now)
	target:SetAttribute("Shooter", shooter.UserId)
	target:SetAttribute("Score", (target:GetAttribute("Score") or 0) + points)
	target:SetAttribute("Shots", (target:GetAttribute("Shots") or 0) + 1)
	target:SetAttribute("LastPoints", points)
	local gui = target:FindFirstChild("Aros")
	local label = gui and gui:FindFirstChild("Puntos")
	if label then
		(label :: TextLabel).Text = ("CALLE %d · %d pts (+%d)"):format(target:GetAttribute("Lane") or 1, target:GetAttribute("Score"), points)
	end
end

local lastPanic: { [Model]: number } = {}
local PANIC_LINES = { "😱 ¡Disparos!", "¡Al suelo!", "¡Socorro, policía!", "😨 ¡Cuidado!" }
-- Los personajes del servidor que lo oyen se asustan (la gente de la calle la mueve cada cliente)
local function scareNpcs(position: Vector3, shooter: Player)
	local ok, found = pcall(function()
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { shooter.Character :: Instance }
		return workspace:GetPartBoundsInRadius(position, 45, params)
	end)
	if not ok or type(found) ~= "table" then
		return
	end
	local count = 0
	local now = os.clock()
	for _, part in found do
		if part.Name == "HumanoidRootPart" then
			local model = part.Parent
			if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) and not model:GetAttribute("Officer") and now - (lastPanic[model] or 0) > 8 then
				lastPanic[model] = now
				count += 1
				Npc.say(model, PANIC_LINES[math.random(1, #PANIC_LINES)])
				task.delay(3, function()
					if model.Parent then
						Npc.say(model, nil)
					end
				end)
				if count >= 4 then
					break
				end
			end
		end
	end
end

-- Lo que dice un personaje al que le dan (antes no decía nada: parecía que el disparo no llegaba)
local HIT_LINES = { "😱 ¡Ay! ¡Me han disparado!", "😨 ¡Socorro!", "¡Llamad a la policía!" }
local TOY_LINES = { Agua = "💦 ¡Eh, que me mojas!", Paintball = "🎨 ¡Oye, que me manchas!" }
local function npcReacts(model: Model, w: Weapons.Weapon)
	if not model.Parent then
		return
	end
	local line
	if w.Kind == "Toy" then
		line = if model:GetAttribute("Officer") then "🙄 Muy gracioso…" else TOY_LINES[w.Class] or "¡Eh!"
	elseif model:GetAttribute("Officer") then
		return -- (el agente ya reacciona: cae o viene a por ti)
	else
		line = if w.Kind == "Taser" then "⚡ ¡Aaah!" else HIT_LINES[math.random(1, #HIT_LINES)]
	end
	lastPanic[model] = os.clock()
	Npc.say(model, line, 1.4)
end

function WeaponService.fire(player: Player, target: any): boolean
	if typeof(target) ~= "Vector3" or target ~= target then
		return false
	end
	local s = stateOf(player)
	local w = Weapons.get(s.Equipped)
	if not w then
		return false
	end
	local now = os.clock()
	if now < s.Reloading or not Weapons.ready(w, s.LastShot, now, 0.2) then
		return false
	end
	if not canShoot(player) then
		return false
	end
	if player:GetAttribute("Sprinting") or player:GetAttribute("BusyMove") then
		return false -- corriendo, saltando una valla o tumbándose se baja el arma
	end
	local humanoid, root, head = partsOf(player)
	local origin = (head :: BasePart).Position
	local zone = WeaponService.safeZone(player, origin)
	if zone then
		if now - s.SafeWarnAt > 3 then
			s.SafeWarnAt = now
			Notify:FireClient(player, "Error", ("🚫 Aquí no se puede disparar (%s)."):format(zone))
		end
		return false
	end
	local m = mags(player)
	local mag = m[w.Id] or 0
	if mag <= 0 then
		Remote:FireClient(player, "Dry", w.Id)
		return false
	end
	-- Cadencia, ráfaga y dispersión
	local since = now - s.LastShot
	s.Shot = if since <= Weapons.interval(w) * 1.8 then s.Shot + 1 else 1
	s.Bloom = Weapons.bloomAfter(w, if s.Shot == 1 then 0 else s.Bloom, since)
	s.LastShot = now
	mag -= 1
	m[w.Id] = mag
	player:SetAttribute("WeaponMag", mag)

	local velocity = (root :: BasePart).AssemblyLinearVelocity
	local airborne = (humanoid :: Humanoid).FloorMaterial == Enum.Material.Air
	local spread = Weapons.spread(w, {
		Aiming = player:GetAttribute("Aiming") == true,
		Speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude,
		Airborne = airborne,
		Stance = if type(player:GetAttribute("Stance")) == "string" then player:GetAttribute("Stance") else nil,
		Bloom = s.Bloom,
	})
	local direction = target - origin
	if direction.Magnitude < 0.5 then
		direction = (root :: BasePart).CFrame.LookVector
	end
	direction = direction.Unit
	if player:GetAttribute("Stance") == "Prone" then
		-- Tumbado: ni hacia atrás ni al suelo
		local cf = (root :: BasePart).CFrame
		direction = Weapons.clampProne(if math.abs(cf.LookVector.Y) > 0.8 then cf.UpVector else cf.LookVector, direction)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	params.IgnoreWater = false

	type Fx = { P: Vector3, N: Vector3?, M: string?, K: string }
	local fx: { Fx } = {}
	local hitModels: { [Model]: { Amount: number, At: Vector3, Zone: string } } = {}
	-- Lo que ha roto (o golpeado) este disparo: los perdigones de la escopeta cuentan una vez por pieza
	local struck: { [Instance]: string | false } = {}
	local order: { Model } = {}
	for _ = 1, w.Pellets do
		local d = Weapons.scatter(direction, spread, math.random(), math.random())
		local result = workspace:Raycast(origin, d * w.Range, params)
		if result then
			local part = result.Instance
			local distance = (result.Position - origin).Magnitude
			local model = humanoidModel(part)
			if model then
				local zoneName = Weapons.zoneOf(part.Name)
				local amount = Weapons.damageAt(w, distance, zoneName)
				local entry = hitModels[model]
				if not entry then
					entry = { Amount = 0, At = result.Position, Zone = zoneName }
					hitModels[model] = entry
					table.insert(order, model)
				end
				entry.Amount += amount
				if zoneName == "Head" then
					entry.Zone = "Head"
				end
				table.insert(fx, { P = result.Position, N = result.Normal, K = "Char" })
			else
				local kind = "World"
				-- Cristales y puertas (BreakService): solo las balas de verdad (ni agua ni pintura)
				if w.Kind == "Real" then
					local before = struck[part]
					if before == nil then
						local okBreak, broke = pcall(BreakService.hitStructure, player, part, result.Position, d * 300, w.Kind)
						before = if okBreak and broke then broke else false
						struck[part] = before
					end
					if before then
						kind = before
					end
				end
				if part:HasTag("RangeTarget") and part:IsA("BasePart") then
					scoreTarget(part, result.Position, player)
				end
				table.insert(fx, { P = result.Position, N = result.Normal, M = result.Material.Name, K = kind })
			end
		else
			table.insert(fx, { P = origin + d * w.Range, K = "Miss" })
		end
	end

	-- Daño (con el mismo camino que los golpes)
	local hitPerson = false
	local confirms = {}
	for _, model in order do
		local entry = hitModels[model]
		-- A quien está en una zona segura o en otro interior (su casa, otro edificio) no le llega el
		-- disparo: la zona segura se miraba solo en el tirador
		local hitPlayer = Players:GetPlayerFromCharacter(model)
		if hitPlayer then
			local _, hitRoot = partsOf(hitPlayer)
			if hitPlayer:GetAttribute("InteriorKey") ~= player:GetAttribute("InteriorKey") or WeaponService.safeSpot(if hitRoot then hitRoot.Position else entry.At) then
				continue
			end
		end
		local ok, result = pcall(CombatService.applyHit, player, model, {
			Amount = entry.Amount,
			Direction = direction,
			Weapon = w.Id,
			Heavy = entry.Amount >= 40 or w.Pellets > 1,
			Stun = w.Stun,
			Toy = w.Kind == "Toy",
			At = entry.At,
			Zone = entry.Zone,
		})
		if ok and result and result.Hit then
			if result.Player then
				hitPerson = true
				if w.Kind == "Toy" then
					Notify:FireClient(result.Player, "Info", if w.Class == "Agua" then "💦 ¡Te han mojado!" else "🎨 ¡Te han dado con una bola de pintura!")
				end
			else
				-- Un personaje (NPC): con un arma de verdad es disparar a una persona (WantedService lo
				-- denuncia con la víctima de testigo; no cuenta además como «disparos al aire»)
				if w.Kind ~= "Toy" then
					hitPerson = true
				end
				npcReacts(model, w)
			end
			table.insert(confirms, { Amount = result.Amount, At = entry.At, Zone = entry.Zone, KO = result.KO, Killed = result.Killed })
		elseif not ok then
			warn("[Armas] " .. tostring(result))
		elseif w.Kind == "Toy" and model:GetAttribute("Officer") then
			npcReacts(model, w) -- (a un agente, el agua o la pintura no le hacen nada, pero se nota)
		end
	end

	Remote:FireAllClients("Shot", { S = player, W = w.Id, H = fx, N = s.Shot, M = mag })
	if #confirms > 0 then
		Remote:FireClient(player, "Confirm", confirms)
	end

	-- Consecuencias: disparar de verdad en la calle (no en la galería ni la policía de servicio)
	if w.Kind == "Real" and not inRange(origin) then
		scareNpcs(origin, player)
		if not hitPerson and not WantedService.onDuty(player) and now - s.PublicCrimeAt > PUBLIC_CRIME_GAP then
			s.PublicCrimeAt = now
			WantedService.crime(player, "Disparos", origin)
		end
		StoryEvents.emit(player, "ShotFired", { Weapon = w.Id })
	end
	return true
end

---------------------------------------------------------------------
-- Recargar
---------------------------------------------------------------------

function WeaponService.reload(player: Player): boolean
	local s = stateOf(player)
	local w = Weapons.get(s.Equipped)
	local now = os.clock()
	if not w or now < s.Reloading or not canShoot(player) then
		return false
	end
	local m = mags(player)
	local loaded = m[w.Id] or 0
	local plan = Weapons.reloadPlan(w, loaded, reserveOf(player, w))
	if not plan then
		if loaded < Weapons.capacity(w, loaded) and reserveOf(player, w) <= 0 then
			Notify:FireClient(player, "Error", "No te queda munición para esta arma (se compra en la Armería).")
		end
		return false
	end
	s.Reloading = now + plan.Time
	s.Token += 1
	local token = s.Token
	player:SetAttribute("Reloading", true)
	local spent = math.max(0, w.Magazine - loaded)
	Remote:FireAllClients("Reload", { S = player, W = w.Id, K = plan.Kind, T = plan.Time, Spent = spent })
	task.delay(plan.Time, function()
		if s.Token ~= token or s.Equipped ~= w.Id then
			return
		end
		local used = plan.Used
		if w.Ammo then
			used = math.min(used, InventoryService.count(player, w.Ammo))
			if used > 0 then
				InventoryService.remove(player, w.Ammo, used)
			end
		end
		m[w.Id] = (m[w.Id] or 0) + used
		s.Reloading = 0
		player:SetAttribute("Reloading", nil)
		publish(player)
	end)
	return true
end

---------------------------------------------------------------------
-- Armerías: comprar, licencia (tasa + test) y oficio de armero/a
---------------------------------------------------------------------

local function buyerOf(player: Player): Weapons.Buyer
	local data = DataService.get(player)
	-- (modo pruebas: se le vende todo como a un adulto con licencia)
	local tester = TesterService.bypass(player)
	return {
		Stage = if tester then "Adulto" else player:GetAttribute("LifeStage"),
		Licence = tester or hasLicence(player),
		Stars = WantedService.stars(player),
		Records = if data and type(data.Record) == "table" then #data.Record else (player:GetAttribute("Records") or 0),
		Money = if data then data.Money else 0,
		Jailed = player:GetAttribute("JailUntil") ~= nil,
	}
end

-- Lo que ve cada uno en el menú de la tienda (con el motivo si no puede comprarlo)
function WeaponService.catalog(player: Player): { { [string]: any } }
	local buyer = buyerOf(player)
	local list = {}
	local okLicence, whyLicence = Weapons.licenceCheck(buyer)
	table.insert(list, {
		Id = "Licencia", Kind = "Licence", Name = "Licencia de armas", Icon = "💳", Price = Weapons.Licence.Price,
		Desc = ("Tasa + test de seguridad (%d de %d preguntas)."):format(Weapons.Licence.ToPass, Weapons.Licence.Questions),
		Ok = okLicence, Reason = whyLicence, Owned = buyer.Licence,
	})
	for _, id in Weapons.ShopOrder do
		local w = Weapons.get(id) :: Weapons.Weapon
		local ok, why = Weapons.buyCheck(w, buyer)
		table.insert(list, {
			Id = id, Kind = "Weapon", Name = w.Name, Icon = w.Icon, Price = w.Price, Class = w.Class, Toy = w.Kind == "Toy",
			Stats = { Damage = w.Damage * w.Pellets, RPM = w.RPM, Magazine = w.Magazine, Range = w.Range, Modes = table.concat(w.Modes, "/"), Aim = w.Spread.Aim, Recoil = w.Recoil.Up },
			Ok = ok and not owns(player, w), Reason = if owns(player, w) then "Ya la tienes." else why, Owned = owns(player, w),
		})
	end
	for _, id in Weapons.AmmoOrder do
		local ammo = Weapons.AmmoTypes[id]
		local ok, why = true, nil
		if ammo.Real and not Weapons.stageAtLeast(buyer.Stage, "AdultoJoven") then
			ok, why = false, "La munición solo se vende a adultos."
		elseif ammo.Real and not buyer.Licence then
			ok, why = false, "Necesitas la licencia de armas."
		elseif (buyer.Money or 0) < ammo.Price then
			ok, why = false, "No te llega el dinero."
		end
		table.insert(list, { Id = id, Kind = "Ammo", Name = ("%s (×%d)"):format(ammo.Name, ammo.Box), Icon = ammo.Icon, Price = ammo.Price, Ok = ok, Reason = why })
	end
	return list
end

local clerks: { [BasePart]: Player } = {}
local clerkNpcs: { [BasePart]: Model } = {}

local function counterNear(player: Player, range: number): BasePart?
	local _, root = partsOf(player)
	if not root then
		return nil
	end
	local best, bestDistance = nil, range
	for _, counter in CollectionService:GetTagged("GunShop") do
		if counter:IsA("BasePart") then
			local d = (counter.Position - root.Position).Magnitude
			if d < bestDistance then
				best, bestDistance = counter, d
			end
		end
	end
	return best
end

local function payCommission(player: Player, price: number)
	local counter = counterNear(player, 40)
	local clerk = counter and clerks[counter]
	if clerk and clerk ~= player and clerk.Parent then
		local amount = math.floor(price * CLERK_COMMISSION)
		if amount > 0 then
			DataService.addMoney(clerk, amount, true)
			Notify:FireClient(clerk, "Money", ("+%s de comisión"):format(Format.money(amount)))
		end
	end
end

function WeaponService.buy(player: Player, id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	local buyer = buyerOf(player)
	local w = Weapons.get(id)
	if w then
		local ok, why = Weapons.buyCheck(w, buyer)
		if ok and owns(player, w) then
			ok, why = false, "Ya la tienes."
		end
		if ok and not InventoryService.canAdd(player, Weapons.itemId(w.Id), 1) then
			ok, why = false, "No te cabe en la mochila."
		end
		if not ok then
			Notify:FireClient(player, "Error", why or "No se puede.")
			return false
		end
		if not DataService.spend(player, w.Price :: number) then
			return false
		end
		InventoryService.add(player, Weapons.itemId(w.Id), 1)
		mags(player)[w.Id] = w.Magazine -- (viene con un cargador lleno)
		Notify:FireClient(player, "Success", ("%s %s comprada. Elígela en la barra rápida para empuñarla."):format(w.Icon, w.Name))
		StoryEvents.emit(player, "BoughtItem", { ShopId = "Armeria", Item = w.Id })
		payCommission(player, w.Price :: number)
		publish(player)
		return true
	end
	local ammo = Weapons.AmmoTypes[id]
	if ammo then
		if ammo.Real and (not Weapons.stageAtLeast(buyer.Stage, "AdultoJoven") or not buyer.Licence) then
			Notify:FireClient(player, "Error", "La munición de verdad solo se vende a adultos con licencia de armas.")
			return false
		end
		if not InventoryService.canAdd(player, id, ammo.Box) then
			Notify:FireClient(player, "Error", "No te cabe más munición de esa.")
			return false
		end
		if not DataService.spend(player, ammo.Price) then
			Notify:FireClient(player, "Error", "No te llega el dinero.")
			return false
		end
		InventoryService.add(player, id, ammo.Box)
		Notify:FireClient(player, "Success", ("%s %s ×%d"):format(ammo.Icon, ammo.Name, ammo.Box))
		payCommission(player, ammo.Price)
		publish(player)
		return true
	end
	return false
end

-- Licencia: se paga la tasa y empieza el test de seguridad
function WeaponService.startLicence(player: Player): boolean
	local ok, why = Weapons.licenceCheck(buyerOf(player))
	if not ok then
		Notify:FireClient(player, "Error", why or "No se puede.")
		return false
	end
	if not DataService.spend(player, Weapons.Licence.Price) then
		return false
	end
	local pool = table.clone(Weapons.Quiz)
	local questions, correct = {}, {}
	for i = 1, math.min(Weapons.Licence.Questions, #pool) do
		local entry = table.remove(pool, math.random(1, #pool))
		local options = table.clone(entry[2])
		local good = options[1]
		for j = #options, 2, -1 do
			local k = math.random(1, j)
			options[j], options[k] = options[k], options[j]
		end
		questions[i] = { Text = entry[1], Options = options }
		correct[i] = table.find(options, good) :: number
	end
	local token = HttpService:GenerateGUID(false)
	stateOf(player).Quiz = { Token = token, Correct = correct }
	Remote:FireClient(player, "Quiz", token, { Questions = questions, ToPass = Weapons.Licence.ToPass, Price = Weapons.Licence.Price })
	return true
end

local function gradeLicence(player: Player, token: any, answers: any)
	local s = stateOf(player)
	local quiz = s.Quiz
	if not quiz or quiz.Token ~= token or type(answers) ~= "table" then
		return
	end
	s.Quiz = nil
	local right, passed = Weapons.gradeQuiz(quiz.Correct, answers)
	if passed and InventoryService.add(player, Weapons.Licence.Item, 1) then
		Notify:FireClient(player, "Success", ("💳 ¡Licencia de armas aprobada! (%d de %d)"):format(right, #quiz.Correct))
		Remote:FireClient(player, "QuizResult", true, right, #quiz.Correct)
		StoryEvents.emit(player, "GotLicence", { Kind = "Armas" })
	else
		Notify:FireClient(player, "Error", ("Test suspendido: %d de %d (necesitas %d). Puedes volver a intentarlo."):format(right, #quiz.Correct, Weapons.Licence.ToPass))
		Remote:FireClient(player, "QuizResult", false, right, #quiz.Correct)
	end
	publish(player)
end

-- Condena (JusticeService apunta antecedentes): se retira la licencia y las armas de verdad se guardan
local function revokeLicence(player: Player)
	if not hasLicence(player) then
		return
	end
	InventoryService.remove(player, Weapons.Licence.Item, 1)
	local w = Weapons.get(stateOf(player).Equipped)
	if w and w.Licence then
		WeaponService.holster(player)
	end
	Notify:FireClient(player, "Error", "💳 Te han retirado la licencia de armas por tus antecedentes.")
	publish(player)
end

-- Modo pruebas (TesterService): la licencia de armas sin test. Devuelve true si es nueva.
function WeaponService.grantLicence(player: Player): boolean
	if not DataService.get(player) or hasLicence(player) then
		return false
	end
	local ok = InventoryService.add(player, Weapons.Licence.Item, 1)
	publish(player)
	return ok
end

-- Modo pruebas (TesterService): todas las armas de Weapons.List (con el cargador lleno), la
-- munición de cada tipo hasta el máximo de la casilla y la licencia. Por la mochila de siempre
-- (InventoryService), como una compra. Devuelve (cosas añadidas, cosas que no caben).
function WeaponService.grantAll(player: Player): (number, number)
	if not DataService.get(player) then
		return 0, 0
	end
	local given, missing = 0, 0
	if WeaponService.grantLicence(player) then
		given += 1
	end
	local ids = {}
	for id in Weapons.List do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local w = Weapons.List[id]
		if not owns(player, w) then
			if InventoryService.add(player, Weapons.itemId(id), 1) then
				given += 1
			else
				missing += 1
			end
		end
		if owns(player, w) then
			mags(player)[id] = w.Magazine
		end
	end
	for _, ammoId in Weapons.AmmoOrder do
		local ammo = Weapons.AmmoTypes[ammoId]
		local room = ammo.Stack - InventoryService.count(player, ammoId)
		if room > 0 then
			if InventoryService.add(player, ammoId, room) then
				given += 1
			else
				missing += 1
			end
		end
	end
	publish(player)
	return given, missing
end

-- Policía de servicio: pistola reglamentaria y táser (y se devuelven al acabar)
local DUTY = { "PistolaPolicia", "Taser" }
local function dutyWeapons(player: Player, on: boolean)
	if on then
		local given = false
		for _, id in DUTY do
			local w = Weapons.get(id) :: Weapons.Weapon
			if not owns(player, w) and InventoryService.add(player, Weapons.itemId(id), 1) then
				mags(player)[id] = w.Magazine
				given = true
			end
		end
		if given then
			Notify:FireClient(player, "Info", "🔫 Te dan la pistola reglamentaria y el táser (barra rápida). Solo contra sospechosos buscados.")
		end
	else
		local s = stateOf(player)
		local current = Weapons.get(s.Equipped)
		if current and current.Duty and not TesterService.bypass(player) then
			WeaponService.holster(player)
		end
		-- (modo pruebas: el tester se queda sus armas de servicio al dejar el turno)
		for _, id in if TesterService.bypass(player) then {} else DUTY do
			if InventoryService.count(player, Weapons.itemId(id)) > 0 then
				InventoryService.remove(player, Weapons.itemId(id), 1)
			end
		end
		local holstered = Weapons.get(player:GetAttribute("Holstered"))
		if holstered and holstered.Duty then
			attachModel(player, nil, false)
		end
	end
	publish(player)
end

-- Oficio de armero/a
local customers: { [BasePart]: { Npc: Model?, Prompt: ProximityPrompt? } } = {}
local ORDERS = { "una caja de munición 9 mm", "cartuchos del 12", "limpiar su fusil", "una funda de pistola", "una diana nueva", "consejo para el test de la licencia" }

local function clearCustomer(counter: BasePart)
	local c = customers[counter]
	if c then
		if c.Npc then
			c.Npc:Destroy()
		end
		if c.Prompt then
			c.Prompt:Destroy()
		end
		customers[counter] = nil
	end
end

local function spawnCustomer(counter: BasePart, clerk: Player)
	clearCustomer(counter)
	local front = counter.CFrame * CFrame.new(0, 1.4, -3.4)
	local okNpc, npc = pcall(Npc.create, "Npc_ClienteArmeria", counter.Parent :: Instance, CFrame.lookAt(front.Position, counter.Position + Vector3.new(0, 1.4, 0)), nil)
	local order = ORDERS[math.random(1, #ORDERS)]
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Atender cliente"
	prompt.ObjectText = "🔫 Quiere " .. order
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JobOnly", "Armero")
	prompt:SetAttribute("OwnerUserId", clerk.UserId)
	prompt.Parent = counter
	customers[counter] = { Npc = if okNpc then npc else nil, Prompt = prompt }
	if okNpc and npc then
		Npc.say(npc, "Buenas, venía por " .. order .. ".")
	end
	prompt.Triggered:Connect(function(who)
		if who ~= clerk or clerks[counter] ~= clerk then
			return
		end
		clearCustomer(counter)
		local pay = Config.Jobs.Armero.Pay
		DataService.addMoney(clerk, pay, true)
		Notify:FireClient(clerk, "Money", "+" .. Format.money(pay))
		StoryEvents.emit(clerk, "JobTaskDone", { JobId = "Armero", Pay = pay })
		task.delay(math.random(CUSTOMER_EVERY[1], CUSTOMER_EVERY[2]), function()
			if clerks[counter] == clerk and clerk.Parent then
				spawnCustomer(counter, clerk)
			end
		end)
	end)
end

function WeaponService.startClerk(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not Weapons.stageAtLeast(player:GetAttribute("LifeStage"), "AdultoJoven") and not TesterService.bypass(player) then
		Notify:FireClient(player, "Error", "Para trabajar en la Armería hay que ser mayor de edad.")
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Te falta energía o tienes demasiada hambre para trabajar.")
		return
	end
	local counter = counterNear(player, 60)
	if not counter then
		return
	end
	if clerks[counter] and clerks[counter] ~= player and clerks[counter].Parent then
		Notify:FireClient(player, "Error", "Ya hay alguien atendiendo esta Armería.")
		return
	end
	JobService.quit(player, true)
	clerks[counter] = player
	local npc = clerkNpcs[counter]
	if npc and npc.Parent then
		npc.Parent = nil -- (el dependiente NPC se va al almacén mientras atiendes tú)
	end
	RoleService.setOnDuty(player, "Armero")
	player:SetAttribute("Job", "Armero")
	Notify:FireClient(player, "Success", "¡De turno en la Armería! Atiende a los clientes del mostrador; te llevas una comisión de lo que compran los jugadores.")
	spawnCustomer(counter, player)
end

function WeaponService.quitClerk(player: Player, silent: boolean?)
	for counter, clerk in clerks do
		if clerk == player then
			clerks[counter] = nil
			clearCustomer(counter)
			local npc = clerkNpcs[counter]
			if npc and not npc.Parent then
				npc.Parent = counter.Parent
			end
		end
	end
	RoleService.offDuty(player, "Armero")
	if player:GetAttribute("Job") == "Armero" then
		player:SetAttribute("Job", nil)
	end
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado el turno en la Armería.")
	end
end

local function setupShop(counter: Instance)
	if not counter:IsA("BasePart") or counter:FindFirstChild("GunShopPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GunShopPrompt"
	prompt.ActionText = "Comprar"
	prompt.ObjectText = "🔫 " .. (counter:GetAttribute("ShopName") or "Armería")
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	prompt.Triggered:Connect(function(player)
		Remote:FireClient(player, "Shop", { Name = counter:GetAttribute("ShopName") or "Armería", Items = WeaponService.catalog(player) })
	end)
	local spot = counter:GetAttribute("StaffSpot")
	if typeof(spot) == "Vector3" then
		local feet = Npc.feetAt(spot) -- (pies en el suelo detrás del mostrador: con +3 flotaba)
		local ok, clerk = pcall(Npc.create, "Npc_Armero", counter.Parent :: Instance, CFrame.lookAt(feet, Vector3.new(counter.Position.X, feet.Y, counter.Position.Z)), { Shirt = Color3.fromRGB(60, 70, 50), Pants = Color3.fromRGB(40, 40, 44) })
		if ok and clerk then
			clerkNpcs[counter] = clerk
		end
	end
end

local function setupLicenceDesk(desk: Instance, label: string)
	if not desk:IsA("BasePart") or desk:FindFirstChild("LicencePrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LicencePrompt"
	prompt.ActionText = "Licencia de armas"
	prompt.ObjectText = ("💳 %s · %s + test"):format(label, Format.money(Weapons.Licence.Price))
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX -- (el Y del mando es tirar piedras)
	prompt:SetAttribute("MinStage", Weapons.Licence.MinStage)
	prompt.Parent = desk
	prompt.Triggered:Connect(function(player)
		WeaponService.startLicence(player)
	end)
end

---------------------------------------------------------------------

function WeaponService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	Remote = remotes:FindFirstChild("Weapons") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Weapons"
		Remote.Parent = remotes
	end
	local lastRequest: { [Player]: number } = {}
	Remote.OnServerEvent:Connect(function(player: Player, action: any, a: any, b: any)
		if action == "Fire" then
			WeaponService.fire(player, a)
			return
		elseif action == "Pitch" then
			local s = stateOf(player)
			local now = os.clock()
			if type(a) == "number" and a == a and now - s.PitchAt > 0.07 and player:GetAttribute("Aiming") then
				s.PitchAt = now
				player:SetAttribute("AimPitch", math.floor(math.clamp(a, -1.3, 1.3) * 50 + 0.5) / 50)
			end
			return
		end
		local now = os.clock()
		if now - (lastRequest[player] or 0) < 0.08 then
			return
		end
		lastRequest[player] = now
		if action == "Equip" then
			if a == nil then
				WeaponService.holster(player)
			else
				WeaponService.equip(player, a)
			end
		elseif action == "Aim" then
			setAiming(player, a == true)
		elseif action == "Reload" then
			WeaponService.reload(player)
		elseif action == "Mode" then
			local s = stateOf(player)
			local w = Weapons.get(s.Equipped)
			if w and #w.Modes > 1 then
				s.Mode[w.Id] = Weapons.nextMode(w, s.Mode[w.Id] or w.Modes[1])
				player:SetAttribute("FireMode", s.Mode[w.Id])
			end
		elseif action == "Buy" then
			local counter = counterNear(player, 16)
			if counter then
				WeaponService.buy(player, a)
				Remote:FireClient(player, "Shop", { Name = counter:GetAttribute("ShopName") or "Armería", Items = WeaponService.catalog(player), Refresh = true })
			end
		elseif action == "Licence" then
			if counterNear(player, 16) then
				WeaponService.startLicence(player)
			end
		elseif action == "Answers" then
			gradeLicence(player, a, b)
		end
	end)

	JobService.setHandler("Armero", { Start = WeaponService.startClerk, Quit = WeaponService.quitClerk })

	for _, counter in CollectionService:GetTagged("GunShop") do
		setupShop(counter)
	end
	CollectionService:GetInstanceAddedSignal("GunShop"):Connect(setupShop)
	for _, desk in CollectionService:GetTagged("GunLicence") do
		setupLicenceDesk(desk, "Ventanilla")
	end
	CollectionService:GetInstanceAddedSignal("GunLicence"):Connect(function(desk)
		setupLicenceDesk(desk, "Ventanilla")
	end)
	-- En la comisaría también se tramita la licencia
	for _, desk in CollectionService:GetTagged("PoliceDesk") do
		setupLicenceDesk(desk, "Comisaría")
	end
	CollectionService:GetInstanceAddedSignal("PoliceDesk"):Connect(function(desk)
		setupLicenceDesk(desk, "Comisaría")
	end)
	task.defer(scanSafeBuildings)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			local s = stateOf(player)
			s.Equipped = nil
			s.Token += 1
			s.Reloading = 0
			player:SetAttribute("Aiming", nil)
			player:SetAttribute("AimPitch", nil)
			player:SetAttribute("Reloading", nil)
			player:SetAttribute("Holstered", nil)
			publish(player)
		end)
		player:GetAttributeChangedSignal("Job"):Connect(function()
			dutyWeapons(player, player:GetAttribute("Job") == "Policia")
		end)
		player:GetAttributeChangedSignal("KO"):Connect(function()
			if player:GetAttribute("KO") then
				setAiming(player, false)
			end
		end)
		player:GetAttributeChangedSignal("Riding"):Connect(function()
			if player:GetAttribute("Riding") and stateOf(player).Equipped then
				WeaponService.holster(player)
			end
		end)
		local records = player:GetAttribute("Records") or 0
		player:GetAttributeChangedSignal("Records"):Connect(function()
			local now = player:GetAttribute("Records") or 0
			if now > records then
				revokeLicence(player)
			end
			records = now
		end)
		-- Si deja de tener el arma (se la quitan, la vende…), se le cae de la mano
		player:GetAttributeChangedSignal("Inventory"):Connect(function()
			local w = Weapons.get(stateOf(player).Equipped)
			if w and not owns(player, w) then
				WeaponService.holster(player)
			elseif w then
				publish(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	DataService.onLoaded(function(player)
		-- Armas de servicio que se quedaron en la mochila (salió a mitad de turno)
		if player:GetAttribute("Job") ~= "Policia" and not TesterService.isTester(player) then
			for _, id in DUTY do
				if InventoryService.count(player, Weapons.itemId(id)) > 0 then
					InventoryService.remove(player, Weapons.itemId(id), 1)
				end
			end
		end
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		WeaponService.quitClerk(player, true)
		states[player] = nil
		lastRequest[player] = nil
	end)
end

return WeaponService
