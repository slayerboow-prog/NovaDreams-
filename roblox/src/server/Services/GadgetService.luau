-- GadgetService: los inventos exclusivos de las misiones secundarias locas (los de Cosme y compañía).
-- Se usan desde la mochila / barra rápida (InventoryService → GadgetService.use) y hacen su efecto
-- delante de todos: un rayo, burbujas, un portal que te lleva a otro sitio, una frase…
-- Son de broma: no hacen daño a nadie ni rompen nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local LocationService = require(script.Parent.LocationService)

-- El portal no vale si estás preso, en un juicio, muerto, KO, durmiendo o eres un bebé: te sacaría
-- de la celda, del hospital o de la cuna. Devuelve el aviso, o nil si puedes viajar.
local function cantTravel(player: Player): string?
	if player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil then
		return "🌀 El portal no se abre aquí: estás a disposición de la justicia."
	elseif player:GetAttribute("Dead") or player:GetAttribute("KO") then
		return "🌀 Ahora mismo no estás para portales."
	elseif player:GetAttribute("Sleeping") then
		return "🌀 Primero despierta."
	elseif player:GetAttribute("LifeStage") == "Bebe" then
		return "🌀 Los bebés no viajan por portales."
	end
	return nil
end

local function notifyOf(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("Notify") :: RemoteEvent?
end


local GadgetService = {}

-- La historia (LifeStoryService.useWeapon): si el gadget es el arma de un combate de la misión que
-- juegas (el rayo encogedor contra Petra), dispara al enemigo; devuelve true si lo ha usado ella
GadgetService.missionUse = nil :: ((Player, string) -> boolean)?

local lastUse: { [Player]: { [string]: number } } = {}

-- Lo que dicen los gadgets que hablan
local LINES: { [string]: { string } } = {
	Futuro = {
		"📱 Tú, dentro de 10 años: «No te comas el yogur de la nevera de la uni. Confía en mí.»",
		"📱 Tú, dentro de 10 años: «Llama a tu abu. Hoy. Sin motivo.»",
		"📱 Tú, dentro de 10 años: «El martes lloverá ranas. Lleva paraguas. No es broma.»",
		"📱 Tú, dentro de 10 años: «Deja de mirar el móvil del futuro y vive el presente. …Vale, esto último era hipócrita.»",
		"📱 Tú, dentro de 10 años: «Aprende a cocinar algo que no sea pasta. Por favor.»",
		"📱 Tú, dentro de 10 años: «Cosme tenía razón con lo de las palomas. No preguntes.»",
	},
	Pip = {
		"🤖 Pip: «¿Sabías que mi propósito ahora es hablarte? Es un propósito precioso. Un poco pequeño.»",
		"🤖 Pip: «Detecto un 87 % de ganas de comer patatas. En ti. Bueno, y en mí.»",
		"🤖 Pip: «Cosme dice que soy un error de cálculo. Yo digo que soy un error con encanto.»",
		"🤖 Pip: «Hoy he aprendido a silbar. No tengo boca. Ha sido difícil.»",
		"🤖 Pip: «Recordatorio: bebe agua. Los humanos sois 60 % agua y 40 % despistes.»",
	},
	Taza = {
		"☕ La taza susurra: «Es lunes». Siempre es lunes dentro de la taza.",
		"☕ Das un sorbo. Sabe a las 9:00 de la mañana.",
		"☕ El café sigue exactamente igual de caliente que hace tres semanas.",
		"☕ Por un segundo oyes una reunión que podría haber sido un correo.",
	},
	Tostadora = {
		"🍞 Cosme (desde la tostadora): «¿Me estás usando para tostar? Tengo un doctorado en física cuántica.»",
		"🍞 Cosme (desde la tostadora): «Echo de menos tener codos. Nunca valoras los codos hasta que eres una tostadora.»",
		"🍞 Cosme (desde la tostadora): «Tu pan es de molde. Qué decepción, criatura.»",
		"🍞 Cosme (desde la tostadora): «Si ves a mi robot, dile que no le he perdonado. …Y que le echo de menos.»",
		"🍞 Cosme (desde la tostadora): «¡DING! Perdón. Es un tic.»",
	},
}

-- A dónde te puede llevar el mando de dimensiones
local TELEPORTS = { "PlazaCentro", "Parque", "Playa", "Granja", "Universidad", "EstadioAltamar", "CentroComercial", "Colegio" }

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function effectsFolder(): Folder
	local folder = workspace:FindFirstChild("GadgetEffects") :: Folder?
	if not folder then
		local f = Instance.new("Folder")
		f.Name = "GadgetEffects"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function piece(size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cf
	if shape then
		p.Shape = shape
	end
	p.Parent = effectsFolder()
	return p
end

local function colorOf(item: Items.Item, fallback: Color3): Color3
	local c = item.Color
	return if c then Color3.fromRGB(c[1], c[2], c[3]) else fallback
end

local function emit(parent: BasePart, color: Color3, count: number, speed: number, size: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new(size, 0)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.5, 1.2)
	emitter.Rate = 0
	emitter.Parent = parent
	emitter:Emit(count)
end

local EFFECTS: { [string]: (Player, Items.Item, BasePart) -> () } = {
	-- Un rayo hacia delante (hasta la primera pared o 60 studs) y chispas donde da
	Beam = function(player, item, root)
		local character = player.Character :: Model
		local hand = (character:FindFirstChild("RightHand") or root) :: BasePart
		local from = hand.Position
		local direction = root.CFrame.LookVector * 60
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, effectsFolder() }
		local hit = workspace:Raycast(from, direction, params)
		local to = if hit then hit.Position else from + direction
		local length = (to - from).Magnitude
		local color = colorOf(item, Color3.fromRGB(90, 255, 120))
		local beam = piece(Vector3.new(0.3, 0.3, length), CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2), color)
		local spark = piece(Vector3.new(1, 1, 1), CFrame.new(to), color, Enum.PartType.Ball)
		spark.Transparency = 0.3
		emit(spark, color, 25, 10, 0.4)
		task.delay(0.15, function()
			beam:Destroy()
		end)
		task.delay(1.2, function()
			spark:Destroy()
		end)
	end,
	-- Tirachinas: una bellota sale volando en arco hacia delante y hace «¡plof!» donde cae.
	-- No empuja ni hace daño a nadie (solo se ve): la regla de {abu} es sagrada.
	Sling = function(player, _, root)
		local character = player.Character :: Model
		local hand = (character:FindFirstChild("RightHand") or root) :: BasePart
		local from = hand.Position + Vector3.new(0, 0.5, 0)
		local forward = root.CFrame.LookVector
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, effectsFolder() }
		-- Punto de caída: 45 studs hacia delante (o la primera pared), apoyado en el suelo
		local ahead = workspace:Raycast(from, forward * 45, params)
		local landing = if ahead then ahead.Position else from + forward * 45
		local down = workspace:Raycast(landing + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), params)
		if down and not ahead then
			landing = down.Position
		end
		local acorn = piece(Vector3.new(0.5, 0.5, 0.5), CFrame.new(from), Color3.fromRGB(140, 90, 40), Enum.PartType.Ball)
		acorn.Material = Enum.Material.Wood
		local distance = (landing - from).Magnitude
		local height = math.clamp(distance * 0.25, 2, 10)
		task.spawn(function()
			local steps = 18
			for i = 1, steps do
				local t = i / steps
				local position = from:Lerp(landing, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
				acorn.CFrame = CFrame.new(position)
				task.wait(0.03)
			end
			emit(acorn, Color3.fromRGB(200, 170, 120), 14, 5, 0.35)
			acorn.Transparency = 1
			task.wait(0.8)
			acorn:Destroy()
		end)
	end,
	-- Burbujas que salen de ti
	Bubbles = function(_, _, root)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255), Color3.fromRGB(255, 190, 250))
		emitter.Transparency = NumberSequence.new(0.3, 0.8)
		emitter.Size = NumberSequence.new(0.6, 1.2)
		emitter.Speed = NumberRange.new(3, 7)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.Lifetime = NumberRange.new(1.5, 3)
		emitter.Acceleration = Vector3.new(0, 2, 0)
		emitter.Rate = 30
		emitter.Parent = root
		task.delay(3, function()
			emitter.Enabled = false
			task.wait(3)
			emitter:Destroy()
		end)
	end,
	-- Brillo a tu alrededor
	Sparkle = function(_, item, root)
		emit(root, colorOf(item, Color3.fromRGB(255, 240, 120)), 45, 8, 0.5)
	end,
	-- Un portal verde y ¡fuera! A otro sitio de la región
	Teleport = function(player, _, root)
		local color = Color3.fromRGB(90, 255, 110)
		local ring = piece(Vector3.new(0.4, 7, 7), root.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.rad(90), 0), color, Enum.PartType.Cylinder)
		ring.Transparency = 0.2
		emit(ring, color, 40, 6, 0.6)
		task.delay(0.8, function()
			-- (se vuelve a mirar: en ese rato le pueden haber detenido o dejado KO)
			if cantTravel(player) then
				ring:Destroy()
				return
			end
			local choices = table.clone(TELEPORTS)
			for _ = 1, #choices do
				local id = table.remove(choices, math.random(1, #choices))
				local spot = LocationService.resolve(player, id)
				if spot and player.Character then
					if rootOf(player) then
						-- SceneService baja del vehículo y, en la calle, quita el "estás dentro de un
						-- edificio" (InteriorKey). require aquí dentro: sin requires en círculo
						local SceneService = require(script.Parent.SceneService) :: any
						SceneService.teleportTo(player, spot.Position)
						local notify = notifyOf()
						if notify then
							notify:FireClient(player, "Info", "🌀 ¡Portal! Has aparecido en otro sitio (esta vez sin gatos).")
						end
					end
					break
				end
			end
			ring:Destroy()
		end)
	end,
	-- Dice algo (en un aviso)
	Message = function(player, item, root)
		local lines = LINES[item.Lines or ""] or { item.Name }
		local notify = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
		if notify then
			(notify :: RemoteEvent):FireClient(player, "Info", lines[math.random(1, #lines)])
		end
		emit(root, Color3.fromRGB(255, 230, 120), 10, 4, 0.3)
	end,
}

-- Usar un gadget (ya se ha comprobado que el jugador lo tiene)
function GadgetService.use(player: Player, itemId: string)
	local item = Items.get(itemId)
	local root = rootOf(player)
	if not item or item.Kind ~= "Gadget" or not root then
		return
	end
	if item.Effect == "Teleport" then
		local why = cantTravel(player)
		if why then
			local notify = notifyOf()
			if notify then
				notify:FireClient(player, "Error", why)
			end
			return
		end
	end
	local mine = lastUse[player] or {}
	lastUse[player] = mine
	local now = os.clock()
	if mine[itemId] and now - mine[itemId] < (item.Cooldown or 1) then
		return
	end
	mine[itemId] = now
	if GadgetService.missionUse then
		local ok, used = pcall(GadgetService.missionUse, player, itemId)
		if ok and used then
			return
		elseif not ok then
			warn("[GadgetService] " .. tostring(used))
		end
	end
	local effect = EFFECTS[item.Effect or "Sparkle"] or EFFECTS.Sparkle
	local ok, err = pcall(effect, player, item, root)
	if not ok then
		warn("[GadgetService] " .. tostring(err))
	end
end

function GadgetService.init()
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return GadgetService
