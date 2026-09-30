-- Npc: personajes sencillos controlados por el servidor (clientes, camarero, barman…).
--   Npc.create(name, parent, cf, look?)  -> Model con HumanoidRootPart anclado (se mueve con tweens)
--   Npc.say(npc, text?, seconds?)        -> bocadillo de texto sobre la cabeza (nil lo oculta); lo dibuja
--                                           cada cliente a menos de SPEECH_RANGE (UI/SpeechBubbles, remoto "Speech")
--   Npc.icon(npc, text?, quiet?)         -> icono pequeño sobre la cabeza (✋, ⏳, 😋…); quiet: solo de
--                                           cerca y sin verse a través de las paredes (oficios normales)
--   Npc.outfits(n) / Npc.tint(look)      -> ropa sin repetir en un grupo / un uniforme con el tono un poco cambiado
--   Npc.vary(npc)                        -> un poco más alto o más bajo (±6 %), con los pies en su sitio
--   Npc.walkTo(npc, { Vector3 }, speed)  -> camina por esos puntos (espera hasta llegar)
--   Npc.sit(npc, seat) / Npc.stand(npc)  -> sentarse en una silla y levantarse (el cliente le pone la
--                                           postura de sentado: atributo UsePose, Controllers/UseMotion)
--   Npc.sitAt(npc, cf)                   -> sentarse en un punto (banco o silla sin Seat)
--   Npc.dress(npc, look)                 -> ropa (camiseta, pantalón, zapatos), pelo y, si es niño, mochila
--   Npc.placeFeet(npc, cf)               -> lo pone de pie con los pies justo en cf (no bajo tierra)
--   Npc.work(npc, "Sweep")               -> su tarea mientras espera (barrer, cobrar…); la anima el cliente
-- Usa el avatar por defecto de Roblox con colores al azar; si falla, un muñeco de bloques.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Joints = require(ReplicatedStorage.Shared.Joints)

local Npc = {}

local rgb = Color3.fromRGB
local SKINS = { rgb(255, 219, 172), rgb(241, 194, 125), rgb(224, 172, 105), rgb(198, 134, 66), rgb(141, 85, 36), rgb(92, 58, 30) }
local SHIRTS = { rgb(200, 60, 60), rgb(60, 110, 200), rgb(60, 160, 90), rgb(240, 200, 60), rgb(150, 80, 170), rgb(240, 240, 240), rgb(40, 40, 46), rgb(230, 120, 40) }
local PANTS = { rgb(40, 50, 80), rgb(30, 30, 34), rgb(110, 90, 70), rgb(80, 80, 90), rgb(60, 70, 110) }
local SHOES = { rgb(245, 245, 245), rgb(30, 30, 34), rgb(120, 70, 40), rgb(200, 50, 50), rgb(40, 90, 180) }
local HAIR = { rgb(40, 28, 20), rgb(70, 45, 25), rgb(120, 80, 40), rgb(200, 160, 90), rgb(20, 20, 22), rgb(150, 60, 30), rgb(190, 190, 195) }

export type Look = { Skin: Color3?, Shirt: Color3?, Pants: Color3?, Shoes: Color3?, Hair: Color3?, LongHair: boolean?, Backpack: Color3?, LongSleeves: boolean? }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

-- Ropa para n personas de un mismo grupo: las camisetas se barajan y no se repiten hasta que se
-- acaban (antes salían dos o tres clones con la misma ropa, uno al lado del otro)
function Npc.outfits(n: number): { Look }
	local deck = table.clone(SHIRTS)
	local list = {}
	for i = 1, n do
		local k = (i - 1) % #deck + 1
		if k == 1 then
			for j = #deck, 2, -1 do
				local r = math.random(1, j)
				deck[j], deck[r] = deck[r], deck[j]
			end
		end
		table.insert(list, { Shirt = deck[k], Pants = pick(PANTS) })
	end
	return list
end

local function shade(c: Color3, k: number): Color3
	local f = 1 + (math.random() * 2 - 1) * k
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

-- El mismo uniforme con el tono un poco cambiado (una tela más gastada, otra más nueva): un grupo de
-- compañeros ya no parecen copias
function Npc.tint(look: Look?, amount: number?): Look?
	if not look then
		return nil
	end
	local k = amount or 0.07
	local copy = table.clone(look)
	if copy.Shirt then
		copy.Shirt = shade(copy.Shirt, k)
	end
	if copy.Pants then
		copy.Pants = shade(copy.Pants, k)
	end
	return copy
end

-- Muñeco de bloques (por si no se puede crear el avatar de Roblox)
local function blockRig(look: Look): Model
	local m = Instance.new("Model")
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CFrame = CFrame.new(offset)
		p.Parent = m
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), look.Shirt :: Color3)
	root.Transparency = 1
	part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), look.Shirt :: Color3)
	part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), look.Skin :: Color3)
	for _, x in { -1.5, 1.5 } do
		part("Arm", Vector3.new(1, 2, 1), Vector3.new(x, 3, 0), look.Skin :: Color3)
	end
	for i, x in { -0.5, 0.5 } do
		part(if i == 1 then "LeftLeg" else "RightLeg", Vector3.new(1, 2, 1), Vector3.new(x, 1, 0), look.Pants :: Color3)
	end
	for _, p in m:GetChildren() do
		if p ~= root and p:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = m
	m.PrimaryPart = root
	return m
end

local SKIN_PARTS = { "Head", "LeftHand", "RightHand" }
local SHIRT_PARTS = { "UpperTorso", "LeftUpperArm", "RightUpperArm" }
local SLEEVE_PARTS = { "LeftLowerArm", "RightLowerArm" }
local PANTS_PARTS = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
local SHOE_PARTS = { "LeftFoot", "RightFoot" }

local function paint(model: Model, names: { string }, color: Color3)
	for _, name in names do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

local function attach(model: Model, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = size.Magnitude > 1
	part.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = part
	part.Parent = model
	return part
end

-- Viste a un personaje R15 (el de Roblox por defecto sale de un solo color, como un maniquí).
-- Sirve para cualquier NPC: clientes, familia, compañeros de clase, profesores…
function Npc.dress(model: Model, look: Look?)
	local l = look or {}
	local skin = l.Skin or pick(SKINS)
	local shirt = l.Shirt or pick(SHIRTS)
	paint(model, SKIN_PARTS, skin)
	paint(model, SHIRT_PARTS, shirt)
	paint(model, SLEEVE_PARTS, if l.LongSleeves or (l.LongSleeves == nil and math.random() < 0.4) then shirt else skin)
	paint(model, PANTS_PARTS, l.Pants or pick(PANTS))
	paint(model, SHOE_PARTS, l.Shoes or pick(SHOES))
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	if torso then
		-- Cuello de la camiseta un poco más oscuro: se nota que es ropa
		attach(model, torso, "Collar", Vector3.new(torso.Size.X * 0.5, 0.12, torso.Size.Z * 1.02), CFrame.new(0, torso.Size.Y / 2 - 0.06, 0), shirt:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	if head then
		local s = head.Size
		local hair = l.Hair or pick(HAIR)
		-- Si el aspecto no lo dice, algunas personas llevan melena (antes todas iban con el pelo corto)
		local long = l.LongHair or (l.LongHair == nil and math.random() < 0.35)
		attach(model, head, "Hair", Vector3.new(s.X * 1.06, s.Y * 0.36, s.Z * 1.08), CFrame.new(0, s.Y * 0.36, 0.03 * s.Z), hair, Enum.Material.Fabric)
		attach(model, head, "HairBack", Vector3.new(s.X * 1.04, s.Y * (if long then 0.95 else 0.55), s.Z * 0.3), CFrame.new(0, if long then -s.Y * 0.1 else s.Y * 0.12, s.Z * 0.42), hair, Enum.Material.Fabric)
		attach(model, head, "Fringe", Vector3.new(s.X * 0.9, s.Y * 0.14, s.Z * 0.2), CFrame.new(0, s.Y * 0.3, -s.Z * 0.48), hair, Enum.Material.Fabric)
	end
	if l.Backpack and torso then
		local t = torso.Size
		attach(model, torso, "SchoolBackpack", Vector3.new(t.X * 0.8, t.Y * 0.85, t.Z * 0.6), CFrame.new(0, -t.Y * 0.05, t.Z * 0.75), l.Backpack, Enum.Material.Fabric)
	end
end

-- De pie con los pies en cf. La raíz de un personaje está a la altura de la cadera
-- (HipHeight + media raíz), NO en el centro de su silueta: por eso salían bajo tierra.
function Npc.placeFeet(model: Model, cf: CFrame)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and root and humanoid.RigType == Enum.HumanoidRigType.R15 then
		model:PivotTo(cf * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
	else
		local _, size = model:GetBoundingBox()
		model:PivotTo(cf * CFrame.new(0, size.Y / 2, 0))
	end
end

-- Dónde pisar bajo un punto (las marcas StaffSpot y parecidas van un poco por encima del suelo): el
-- primer suelo sólido de verdad de ahí hacia abajo (sin mostradores ni personas); si no hay, el punto.
-- Así nadie queda flotando detrás del mostrador ni hundido en él.
function Npc.feetAt(point: Vector3, depth: number?): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	local from = point + Vector3.new(0, 1, 0)
	for _ = 1, 6 do
		params.FilterDescendantsInstances = skip
		local ok, hit = pcall(function()
			return workspace:Raycast(from, Vector3.new(0, -((depth or 8) + 1), 0), params)
		end)
		if not ok or not hit then
			break
		end
		local part = hit.Instance
		local model = part:FindFirstAncestorOfClass("Model")
		local isPerson = model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
		if not isPerson and hit.Normal.Y > 0.8 and (part:IsA("Terrain") or (part :: BasePart).CanCollide) then
			return hit.Position
		end
		table.insert(skip, if isPerson then model :: Instance else part)
	end
	return point
end

-- Un poco más alto o más bajo (±amount, 6 % por defecto) sin que se hunda ni flote: se miden los pies
-- antes y se vuelven a poner en el mismo sitio. Llamar antes de sentarlo.
function Npc.vary(model: Model, amount: number?)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end
	local feet = root.CFrame * CFrame.new(0, -(humanoid.HipHeight + root.Size.Y / 2), 0)
	local k = amount or 0.06
	pcall(function()
		model:ScaleTo(1 + (math.random() * 2 - 1) * k)
		Npc.placeFeet(model, feet)
	end)
end

-- Que llegue entero a los jugadores (el mapa se carga por trozos): sin esto a veces llegaba el
-- humanoide sin la cabeza o sin el cuello y el cliente no podía animarlo (ActorLife, UseMotion)
function Npc.atomic(model: Model)
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
end

function Npc.create(name: string, parent: Instance, cf: CFrame, look: Look?): Model
	local l: Look = {
		Skin = (look and look.Skin) or pick(SKINS),
		Shirt = (look and look.Shirt) or pick(SHIRTS),
		Pants = (look and look.Pants) or pick(PANTS),
	}
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = l.Skin :: Color3
		desc.LeftArmColor = l.Skin :: Color3
		desc.RightArmColor = l.Skin :: Color3
		desc.TorsoColor = l.Shirt :: Color3
		desc.LeftLegColor = l.Pants :: Color3
		desc.RightLegColor = l.Pants :: Color3
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = blockRig(l)
	end
	model.Name = name
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
		end
	end
	root.Anchored = true
	model.PrimaryPart = root
	Npc.atomic(model)
	if ok then
		Npc.dress(model, look)
	end
	-- cf = pies en el suelo, mirando hacia donde mira cf
	root.CFrame = cf * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	model.Parent = parent
	return model
end

local function billboard(npc: Model, name: string, offset: number, size: UDim2, quiet: boolean?): TextLabel?
	local head = npc:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil
	end
	local gui = head:FindFirstChild(name) :: BillboardGui?
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = name
		g.Size = size
		g.StudsOffset = Vector3.new(0, offset, 0)
		-- Callado (un oficio normal: dependiente, cajero…): solo de cerca y tapado por las paredes;
		-- si no, el icono se veía desde toda la calle a través de los edificios
		g.MaxDistance = if quiet then 15 else 70
		g.AlwaysOnTop = not quiet
		g.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.TextScaled = true
		label.TextWrapped = true
		label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		label.Parent = g
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = label
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 4)
		pad.Parent = label
		gui = g
	end
	return (gui :: BillboardGui):FindFirstChildOfClass("TextLabel")
end

-- Remoto de los bocadillos (lo crea si falta; false si no se puede, p. ej. en las pruebas)
local speechRemote: RemoteEvent | false | nil = nil
local function speech(): RemoteEvent?
	if speechRemote == nil then
		local ok, found = pcall(function()
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if not remotes then
				return nil
			end
			local remote = remotes:FindFirstChild("Speech")
			if not remote then
				remote = Instance.new("RemoteEvent")
				remote.Name = "Speech"
				remote.Parent = remotes
			end
			return remote
		end)
		speechRemote = if ok and found then found else false
	end
	return if speechRemote then speechRemote else nil
end

Npc.SPEECH_RANGE = 120 -- (studs) las frases solo se mandan a los jugadores a menos de esto
local heardBy: { [Model]: { [Player]: boolean } } = setmetatable({}, { __mode = "k" }) :: any -- (quién oyó la última)

-- Bocadillo de texto (nil lo oculta). Sin seconds se queda hasta que se quite (el cliente le pone
-- un tope); con seconds se va solo. Lo dibuja cada jugador cerca (UI/SpeechBubbles): un bocadillo
-- por personaje, y el atributo Says dice qué está diciendo (el cliente gesticula, las pruebas lo leen).
function Npc.say(npc: Model, text: string?, seconds: number?)
	if not npc then
		return
	end
	local line = if text ~= nil and text ~= "" then text else nil
	if line then
		-- El saludo de la hora que es (nadie dice "Buenos días" a las once de la noche)
		local ok, adapted = pcall(function()
			local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)
			local hour, weather = TimeContext.now()
			return TimeContext.adapt(line, hour, weather)
		end)
		if ok and type(adapted) == "string" then
			line = adapted
		end
	end
	pcall(function()
		npc:SetAttribute("Says", line)
	end)
	local remote = speech()
	if remote then
		local payload = {
			Speaker = npc,
			Text = line,
			Seconds = seconds,
			Name = npc:GetAttribute("SpeakerName"),
		}
		-- Solo a quien está cerca (el cliente ni dibuja las de más de 100 studs); el "ya no habla" va
		-- también a quien recibió la frase anterior, aunque se haya alejado (que no se le quede puesto)
		local ok, at = pcall(function()
			return npc:GetPivot().Position
		end)
		-- Los personajes de un encargo de la ciudad solo los ve quien lo hace (los demás los tienen
		-- escondidos: Controllers/CityErrands): su bocadillo, igual, solo para él
		local owner: any = nil
		local node: Instance? = npc
		while node and node ~= workspace do
			owner = node:GetAttribute("ErrandOwner")
			if owner ~= nil then
				break
			end
			node = node.Parent
		end
		if not ok then
			if owner ~= nil then
				local who = Players:GetPlayerByUserId(owner)
				if who then
					remote:FireClient(who, payload)
				end
			else
				remote:FireAllClients(payload)
			end
		else
			local before = heardBy[npc]
			local now: { [Player]: boolean } = {}
			for _, player in Players:GetPlayers() do
				if owner ~= nil and player.UserId ~= owner then
					continue
				end
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local near = root ~= nil and root:IsA("BasePart") and (root.Position - at).Magnitude <= Npc.SPEECH_RANGE
				if near then
					now[player] = true
				end
				if near or (before and before[player]) then
					remote:FireClient(player, payload)
				end
			end
			heardBy[npc] = if line then now else nil
		end
	end
	if seconds and line then
		task.delay(seconds, function()
			if npc.Parent and npc:GetAttribute("Says") == line then
				pcall(function()
					npc:SetAttribute("Says", nil)
				end)
			end
		end)
	end
end

-- Icono pequeño sobre la cabeza (nil lo oculta)
function Npc.icon(npc: Model, text: string?, quiet: boolean?)
	local label = billboard(npc, "Icon", 2.2, UDim2.fromOffset(46, 46), quiet)
	if label then
		label.Text = text or ""
		label.Parent.Enabled = text ~= nil
	end
end

local walking: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local walkSeq: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any -- (el último walkTo manda)
local turning: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any -- (Npc.face: el último giro manda)

-- Cuánto hay que girar (radianes, 0..pi) para pasar de mirar a `a` a mirar a `b`
local function turnAngle(a: CFrame, b: CFrame): number
	local la, lb = a.LookVector, b.LookVector
	local dot = math.clamp(la.X * lb.X + la.Z * lb.Z, -1, 1)
	return math.acos(dot)
end

-- Camina por los puntos (a la altura del suelo) mirando hacia donde va. Espera hasta llegar.
-- Gira mientras da los primeros pasos de cada tramo (no de golpe en cada esquina), y el cliente le
-- pone la animación de andar al paso que lleva (ActorLife mide cuánto avanza).
function Npc.walkTo(npc: Model, points: { Vector3 }, speed: number?)
	local root = npc.PrimaryPart
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or not npc.Parent then
		return
	end
	local pace = speed or 9
	local height = humanoid.HipHeight + root.Size.Y / 2
	walking[npc] = true
	turning[npc] = (turning[npc] or 0) + 1 -- (si se estaba girando con Npc.face, ya no)
	-- Si otro sistema le manda andar a otro sitio mientras va, manda el último: este paseo se para
	-- (antes los dos tweens se pisaban y el personaje daba saltos o se deslizaba de lado)
	local token = (walkSeq[npc] or 0) + 1
	walkSeq[npc] = token
	local function superseded(): boolean
		return walkSeq[npc] ~= token or not npc.Parent
	end
	for _, point in points do
		if superseded() then
			break
		end
		local target = point + Vector3.new(0, height, 0)
		local from = root.Position
		local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
		local distance = flat.Magnitude
		if distance > 0.1 then
			local facing = CFrame.new(from) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
			-- Primeros pasos girando (más pasos cuanto más gira: una esquina cerrada no es un giro en seco)
			local angle = turnAngle(root.CFrame, facing)
			if angle > 1.6 then
				-- Media vuelta: primero se gira casi del todo sin avanzar (no anda de espaldas)
				local look = root.CFrame.LookVector
				local current = math.atan2(-look.X, -look.Z)
				local goal = math.atan2(-flat.X, -flat.Z)
				local diff = (goal - current + math.pi) % (2 * math.pi) - math.pi
				local pre = TweenService:Create(root, TweenInfo.new((angle - 1) * 0.22, Enum.EasingStyle.Sine), {
					CFrame = CFrame.new(from) * CFrame.Angles(0, current + diff * (angle - 1) / angle, 0),
				})
				pre:Play()
				pre.Completed:Wait()
				if superseded() then
					break
				end
				angle = turnAngle(root.CFrame, facing)
			end
			-- (un giro pequeño también se hace en los primeros pasos, en unos 0,15 s: antes era de golpe
			-- y se notaba un tirón en cada punto del camino)
			local turnSteps = if angle < 0.3 then math.min(distance, math.max(0.1, pace * 0.15)) else math.min(distance, math.max(0.8, angle * 1.4))
			do
				local along = from + (target - from) * (turnSteps / distance)
				local turn = TweenService:Create(root, TweenInfo.new(turnSteps / pace, Enum.EasingStyle.Linear), {
					CFrame = CFrame.new(along) * facing.Rotation,
				})
				turn:Play()
				turn.Completed:Wait()
				if superseded() then
					break
				end
			end
			local rest = (target - root.Position).Magnitude
			if rest > 0.05 then
				local tween = TweenService:Create(root, TweenInfo.new(rest / pace, Enum.EasingStyle.Linear), {
					CFrame = CFrame.new(target) * facing.Rotation,
				})
				tween:Play()
				tween.Completed:Wait()
			end
		end
	end
	if walkSeq[npc] == token then
		walking[npc] = nil
	end
end

-- ¿Está andando ahora (Npc.walkTo)?
function Npc.isWalking(npc: Model): boolean
	return walking[npc] == true
end

-- Tarea que hace mientras espera: el cliente le mueve los brazos y le pone el objeto en la mano
-- (Controllers/WorkAnim: Sweep, Clipboard, Phone, Type, Scan, Cut, Coffee, Tray, Wipe, Count, Call,
-- Present, Watch, Fold, Knit, Stir, Book, Guard, Traffic). nil = ninguna.
function Npc.work(npc: Model, work: string?)
	npc:SetAttribute("Work", work)
end

-- Se vuelve hacia un punto poco a poco (unos 0,3 s), como una persona; sin moverse del sitio
function Npc.faceSmooth(npc: Model, point: Vector3, seconds: number?)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if flat.Magnitude <= 0.1 then
		return
	end
	local goal = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
	if not root.Anchored then
		root.CFrame = goal
		return
	end
	local ok = pcall(function()
		TweenService:Create(root, TweenInfo.new(seconds or 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = goal }):Play()
	end)
	if not ok then
		root.CFrame = goal
	end
end

-- Mira hacia un punto (sin moverse)
function Npc.face(npc: Model, point: Vector3)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if flat.Magnitude > 0.1 then
		local goal = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
		local angle = turnAngle(root.CFrame, goal)
		turning[npc] = (turning[npc] or 0) + 1
		local token = turning[npc]
		-- Se da la vuelta en un momento, no de golpe. Solo gira: si mientras tanto otro lo cambia de
		-- sitio (se sienta, se levanta), no se le devuelve adonde estaba.
		-- (también los giros pequeños, en unos 0,15 s: de golpe se notaba un tirón)
		local ok = not walking[npc] and angle >= 0.01 and pcall(function()
			local value = Instance.new("CFrameValue")
			value.Value = root.CFrame.Rotation
			value.Changed:Connect(function(rotation: CFrame)
				if turning[npc] == token and not walking[npc] and root.Parent then
					root.CFrame = CFrame.new(root.Position) * rotation
				end
			end)
			local tween = TweenService:Create(value, TweenInfo.new(if angle < 0.35 then 0.15 else math.clamp(angle * 0.22, 0.2, 0.55), Enum.EasingStyle.Sine), { Value = goal.Rotation })
			tween.Completed:Connect(function()
				value:Destroy()
			end)
			tween:Play()
		end)
		if not ok then
			root.CFrame = goal -- (andando ya mira hacia donde va; un giro pequeño no se nota)
		end
	end
end

-- La postura sentada también la ve el cliente (UseMotion: manos en el regazo, respira, mira alrededor)
local function setPose(npc: Model, pose: string?)
	pcall(function()
		npc:SetAttribute("UsePose", pose)
		local CollectionService = game:GetService("CollectionService")
		if pose then
			CollectionService:AddTag(npc, "UsePoseNpc")
		else
			CollectionService:RemoveTag(npc, "UsePoseNpc")
		end
	end)
end
Npc.setPose = setPose

local LEG_JOINTS = { LeftHip = 90, RightHip = 90, LeftKnee = -90, RightKnee = -90 }

-- Dobla las piernas para sentarse (y guarda la postura original en "BaseC0"). Motor6D o
-- AnimationConstraint (si el NPC lleva las articulaciones nuevas de Roblox: su C0 es el CFrame de
-- Attachment0; shared/Joints)
local function bendLegs(npc: Model)
	for name, angle in LEG_JOINTS do
		local joint = Joints.find(npc, name)
		if joint and not joint:GetAttribute("BaseC0") then
			local c0 = Joints.c0(joint)
			joint:SetAttribute("BaseC0", c0)
			Joints.setC0(joint, c0 * CFrame.Angles(math.rad(angle), 0, 0))
		end
	end
end

-- Se sienta en la silla (seat: la pieza del asiento, mirando hacia la mesa)
function Npc.sit(npc: Model, seat: BasePart)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	bendLegs(npc)
	turning[npc] = (turning[npc] or 0) + 1
	root.CFrame = seat.CFrame * CFrame.new(0, seat.Size.Y / 2 + 1.35, 0.4)
	setPose(npc, "Sit")
end

-- Se sienta en un punto (cf: la superficie del asiento, mirando hacia donde mira quien se sienta),
-- para bancos y sillas sin pieza Seat: dobla las piernas y apoya la cadera en el asiento.
function Npc.sitAt(npc: Model, cf: CFrame)
	local root = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	bendLegs(npc)
	turning[npc] = (turning[npc] or 0) + 1
	local lift = root.Size.Y / 2 + 0.25
	npc:PivotTo(cf * CFrame.new(0, lift, 0) * root.CFrame:ToObjectSpace(npc:GetPivot()))
	setPose(npc, "Sit")
end

function Npc.stand(npc: Model, feet: Vector3?)
	if npc:GetAttribute("UsePose") == "Sit" then
		setPose(npc, nil)
	end
	for name in LEG_JOINTS do
		local joint = Joints.find(npc, name)
		if joint then
			local base = joint:GetAttribute("BaseC0")
			if typeof(base) == "CFrame" then
				Joints.setC0(joint, base)
				joint:SetAttribute("BaseC0", nil)
			end
		end
	end
	local root = npc.PrimaryPart
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if root and humanoid and feet then
		root.CFrame = CFrame.new(feet + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)) * root.CFrame.Rotation
	end
end

return Npc
