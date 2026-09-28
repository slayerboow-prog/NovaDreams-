-- MetroLifeService: la vida pequeña del metro (lo construye World/Kit/MetroDetails.luau).
--
--   * Guardias de seguridad que patrullan vestíbulos y galería (se puede hablar con ellos) y
--     limpiadores/as con la fregona. Solo existen si hay alguien cerca.
--   * Ratas que corretean por las vías y los rincones: "Espantar" y el metro te da una propina.
--   * Aseos: váteres (te sientas y tiras de la cadena), lavabos con agua y secamanos.
--   * Taquillas que se abren (a veces hay algo), papeleras para rebuscar, cajero (ver saldo),
--     teléfono público, interfono de emergencia, fuente de los deseos, piano libre,
--     limpiabotas y estatua humana (propina).
--   * Lámparas que parpadean.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Metro = require(ReplicatedStorage.Shared.Metro)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)

local MetroLifeService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local LIFE = Metro.Life
local rgb = Color3.fromRGB

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function anyoneNear(position: Vector3, range: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude < range then
			return true
		end
	end
	return false
end

local function nearestPlayer(position: Vector3, range: number): Player?
	local best, bestD = nil, range
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local d = root and (root.Position - position).Magnitude
		if d and d < bestD then
			best, bestD = player, d
		end
	end
	return best
end

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local function prompt(parent: Instance, action: string, object: string, hold: number?, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0.2
	p.MaxActivationDistance = distance or 8
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

-- Enfriamiento por jugador y por clave
local cooldowns: { [Player]: { [any]: number } } = {}
local function ready(player: Player, key: any, seconds: number): boolean
	local list = cooldowns[player] or {}
	cooldowns[player] = list
	local last = list[key]
	if last and os.clock() - last < seconds then
		return false
	end
	list[key] = os.clock()
	return true
end

local function info(player: Player, text: string)
	Notify:FireClient(player, "Info", text)
end

-- Emite unas partículas un rato
local function burst(emitter: ParticleEmitter?, seconds: number)
	if not emitter then
		return
	end
	emitter.Enabled = true
	task.delay(seconds, function()
		emitter.Enabled = false
	end)
end

-- Texto flotante que sube y se desvanece (notas del piano, "¡Iiic!" de las ratas…)
local function floatText(at: Vector3, text: string, color: Color3?, seconds: number?)
	local anchor = Instance.new("Part")
	anchor.Name = "FloatText"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 50)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 60
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	label.Parent = gui
	local t = seconds or 1.6
	TweenService:Create(anchor, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(at + Vector3.new(math.random(-10, 10) / 10, 3.5, 0)) }):Play()
	TweenService:Create(label, TweenInfo.new(t), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(t, function()
		anchor:Destroy()
	end)
end

---------------------------------------------------------------------
-- Guardias y limpiadores
---------------------------------------------------------------------

local GUARD_LINES = {
	"Buenas. Todo tranquilo por aquí.",
	"Si ves algo raro, avísame por el interfono.",
	"No se puede saltar el torno, ¿eh? Que te estoy viendo. 👀",
	"Cuidado con las ratas de la vía, son más listas que yo.",
	"El último tren sale… bueno, aquí no cierra nunca.",
	"¿Has perdido algo? Pregunta en Objetos Perdidos, en la galería.",
	"Detrás de la línea amarilla, por favor.",
	"Si espantas ratas, el metro te da una propina. Palabra.",
	"Llevo 20 años en el metro. He visto de todo. DE TODO.",
	"Los aseos están al fondo del vestíbulo.",
}
local CLEANER_LINES = {
	"¡Cuidado, que resbala! 🧽",
	"Recién fregado, ¿eh?",
	"¿Quién tira chicles al suelo? ¿Quién?",
	"Las ratas me ayudan con las migas. Somos un equipo.",
	"Ya casi está… ¡no pises ahí!",
}

local GUARD_LOOK = { Shirt = rgb(30, 45, 80), Pants = rgb(25, 28, 35) }
local CLEANER_LOOK = { Shirt = rgb(60, 150, 170), Pants = rgb(50, 70, 90) }

local posts: { [BasePart]: Model } = {}

local function feet(v: any): Vector3?
	return if typeof(v) == "Vector3" then v else nil
end

local function speak(npc: Model, text: string, seconds: number?)
	Npc.say(npc, text)
	task.delay(seconds or 4, function()
		if npc.Parent then
			Npc.say(npc, nil)
		end
	end)
end

local function spawnPatrol(post: BasePart)
	local a, b = feet(post:GetAttribute("A")), feet(post:GetAttribute("B"))
	if not a or not b then
		return
	end
	local role = post:GetAttribute("Role")
	local cleaner = role == "Cleaner"
	local npc = Npc.create(if cleaner then "Limpiador" else "Guardia", post.Parent :: Instance, CFrame.new(a), if cleaner then CLEANER_LOOK else GUARD_LOOK)
	Npc.face(npc, b)
	Npc.icon(npc, if cleaner then "🧽" else "🛡️")
	posts[post] = npc
	local root = npc.PrimaryPart
	if root then
		local p = prompt(root, "Hablar", if cleaner then "🧽 Limpieza" else "🛡️ Seguridad", 0, 9)
		p.Triggered:Connect(function(player)
			local proot = rootOf(player)
			if proot then
				Npc.face(npc, proot.Position)
			end
			speak(npc, pick(if cleaner then CLEANER_LINES else GUARD_LINES), 5)
		end)
	end
	-- Patrulla: va de A a B, se para a mirar (o a fregar) y vuelve
	task.spawn(function()
		local points = { b, a }
		local i = 1
		while npc.Parent do
			Npc.work(npc, nil)
			Npc.walkTo(npc, { points[i] }, if cleaner then 3.5 else 5)
			if not npc.Parent then
				break
			end
			Npc.work(npc, if cleaner then "Sweep" else "Guard")
			local near = nearestPlayer(points[i], 14)
			if near and math.random() < 0.5 then
				local nroot = rootOf(near)
				if nroot then
					Npc.face(npc, nroot.Position)
				end
				speak(npc, pick(if cleaner then CLEANER_LINES else GUARD_LINES), 4)
			end
			task.wait(math.random(30, 70) / 10)
			i = i % #points + 1
			-- De camino, a veces se para en medio
			if math.random() < 0.3 and npc.Parent then
				local mid = a:Lerp(b, math.random(25, 75) / 100)
				Npc.work(npc, nil)
				Npc.walkTo(npc, { mid }, if cleaner then 3.5 else 5)
				Npc.work(npc, if cleaner then "Sweep" else "Guard")
				task.wait(math.random(15, 35) / 10)
			end
		end
	end)
end

-- Personajes quietos: limpiabotas (MetroStaff) y estatua humana (MetroStatue)
local statics: { [BasePart]: Model } = {}

local function spawnStatic(marker: BasePart)
	local statue = marker:HasTag("MetroStatue")
	local look = if statue
		then { Skin = rgb(190, 192, 198), Shirt = rgb(175, 178, 185), Pants = rgb(160, 162, 170) }
		else { Shirt = rgb(120, 30, 30), Pants = rgb(40, 40, 45) }
	local cf = CFrame.new(marker.Position - Vector3.new(0, marker.Size.Y / 2, 0)) -- pies en la base del marcador
	local npc = Npc.create(if statue then "EstatuaHumana" else "Limpiabotas", marker.Parent :: Instance, cf, look)
	local face = feet(marker:GetAttribute("Face"))
	if face then
		Npc.face(npc, face)
	end
	if statue then
		Npc.work(npc, "Present")
		Npc.icon(npc, "🗿")
	else
		Npc.icon(npc, "👞")
	end
	statics[marker] = npc
end

---------------------------------------------------------------------
-- Ratas
---------------------------------------------------------------------

local RAT_GREY = rgb(95, 90, 88)

local function buildRat(parent: Instance, at: Vector3): Model
	local m = Instance.new("Model")
	m.Name = "Rata"
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.Fabric
		p.Shape = shape or Enum.PartType.Block
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.CFrame = CFrame.new(at) * offset
		p.Parent = m
		return p
	end
	local body = piece("Body", Vector3.new(0.9, 0.6, 1.5), CFrame.new(0, 0.35, 0), RAT_GREY, Enum.PartType.Block, Enum.Material.Fabric)
	body.Anchored = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	piece("Head", Vector3.new(0.55, 0.5, 0.7), CFrame.new(0, 0.4, -0.95), RAT_GREY, Enum.PartType.Ball)
	piece("Nose", Vector3.new(0.15, 0.15, 0.15), CFrame.new(0, 0.38, -1.32), rgb(230, 150, 160), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
	for _, x in { -0.22, 0.22 } do
		piece("Ear", Vector3.new(0.28, 0.28, 0.08), CFrame.new(x, 0.72, -0.85), rgb(210, 150, 155), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
		piece("Eye", Vector3.new(0.1, 0.1, 0.1), CFrame.new(x * 0.7, 0.5, -1.18), rgb(20, 10, 10), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
	end
	piece("Tail", Vector3.new(0.1, 0.1, 1.6), CFrame.new(0, 0.18, 1.45) * CFrame.Angles(math.rad(8), 0, 0), rgb(200, 150, 150), Enum.PartType.Block, Enum.Material.SmoothPlastic)
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = p
			weld.Parent = p
		end
	end
	m.PrimaryPart = body
	m.Parent = parent
	return m
end

type Rat = { Model: Model, Body: BasePart, Nest: BasePart, Fleeing: boolean }
local nests: { [BasePart]: { Rat } } = {}
local ratFolder: Folder

-- Mueve la rata hasta un punto (a ras de suelo), mirando hacia donde va
local function scurry(rat: Rat, target: Vector3, speed: number)
	local body = rat.Body
	local from = body.Position
	local goal = target + Vector3.new(0, 0.35, 0)
	local flat = Vector3.new(goal.X - from.X, 0, goal.Z - from.Z)
	if flat.Magnitude < 0.2 then
		return
	end
	local rot = CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
	body.CFrame = CFrame.new(from) * rot
	local tween = TweenService:Create(body, TweenInfo.new(flat.Magnitude / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = CFrame.new(goal) * rot })
	tween:Play()
	tween.Completed:Wait()
end

local function spawnRat(nest: BasePart)
	local a, b = feet(nest:GetAttribute("A")), feet(nest:GetAttribute("B"))
	if not a or not b then
		return
	end
	local start = a:Lerp(b, math.random())
	local model = buildRat(ratFolder, start)
	local rat: Rat = { Model = model, Body = model.PrimaryPart :: BasePart, Nest = nest, Fleeing = false }
	local list = nests[nest] or {}
	nests[nest] = list
	table.insert(list, rat)
	local p = prompt(rat.Body, "Espantar", "🐀 Rata", 0, 10)
	p.Triggered:Connect(function(player)
		if rat.Fleeing then
			return
		end
		rat.Fleeing = true
		p.Enabled = false
		floatText(rat.Body.Position + Vector3.new(0, 1.5, 0), "¡Iiic! 🐀", rgb(255, 230, 120))
		if ready(player, "Rat", LIFE.RatCooldown) then
			DataService.addMoney(player, LIFE.RatBounty, true)
			Notify:FireClient(player, "Success", ("🐀 ¡Fuera, rata! El metro te da %s por espantarla."):format(Format.money(LIFE.RatBounty)))
		else
			info(player, "🐀 ¡Fuera! (sale disparada hacia el túnel)")
		end
	end)
	-- Corretea: va a un sitio al azar, se para a husmear, y otra vez
	task.spawn(function()
		while model.Parent and not rat.Fleeing do
			local target = a:Lerp(b, math.random()) + Vector3.new(math.random(-6, 6) / 10, 0, math.random(-6, 6) / 10)
			scurry(rat, target, math.random(8, 14))
			local waited = 0
			local stop = math.random(5, 30) / 10
			while waited < stop and not rat.Fleeing and model.Parent do
				task.wait(0.1)
				waited += 0.1
			end
		end
		if model.Parent and rat.Fleeing then
			-- Huye hacia el extremo más lejano y desaparece
			local pos = rat.Body.Position
			local exit = if (pos - a).Magnitude > (pos - b).Magnitude then a else b
			scurry(rat, exit, 26)
			model:Destroy()
		end
	end)
end

---------------------------------------------------------------------
-- Cacharros del metro
---------------------------------------------------------------------

local PHONE_CALLS = {
	{ "📞 Riiing… «¿Pizzería Mamma Mía? ¿No? Uy, perdón.»" },
	{ "📞 «Hola, abuela. Sí, estoy en el metro. Sí, he comido. Sí, llevo chaqueta.»" },
	{ "📞 Marcas un número al azar… «¿Hola? ¿Quién es? ¿Eres tú, Paco?» Cuelgas rápido." },
	{ "📞 «Radio Valmar, está usted en antena. ¿Qué canción quiere dedicar?»" },
	{ "📞 Solo se oye un pitido. Y luego… ¿una risa? Qué miedo." },
	{ "📞 «Ha llamado al servicio de horóscopos. Hoy es tu día de suerte. Fin del mensaje.»" },
}
local FORTUNES = {
	"🪙 Plin. La moneda cae al fondo. Algo bueno va a pasar hoy.",
	"🪙 Plin. Dicen que el deseo se cumple si no se lo cuentas a nadie.",
	"🪙 Plin. Un pez imaginario te guiña un ojo. Buena señal.",
	"🪙 Plin. La fuente burbujea. ¿Eso es un sí?",
	"🪙 Plin. Te sientes con suerte. Mucha suerte.",
}
local BIN_FINDS = {
	"🗑️ Solo hay un chicle masticado. Puaj.",
	"🗑️ Un billete de metro usado. No sirve.",
	"🗑️ Media rosquilla. Mejor no.",
	"🗑️ Un periódico de ayer. Nada interesante.",
	"🗑️ ¡Una rata te mira desde dentro! Mejor cierras. 🐀",
	"🗑️ Envoltorios de chuches y una lata vacía.",
}
local LOCKER_FINDS = {
	"🔓 Está vacía.",
	"🔓 Hay un calcetín solitario. 🧦",
	"🔓 Una nota: «Quien lea esto, que tenga un buen día».",
	"🔓 Un paraguas roto y un olor raro.",
	"🔓 Nada. Solo polvo.",
}
local INTERCOM_LINES = {
	"📢 «Seguridad del metro, ¿dígame?… Vale, vamos para allá. Gracias por avisar.»",
	"📢 «¿Hola? Aquí seguridad. Si es por las ratas, ya lo sabemos.»",
	"📢 «Seguridad. ¿Todo bien? Recuerda: detrás de la línea amarilla.»",
}

local SETUP: { [string]: (BasePart) -> () } = {
	MetroToilet = function(seat)
		if not seat:IsA("Seat") then
			return
		end
		prompt(seat, "Usar el váter", "🚽 Aseo", 0.3, 7).Triggered:Connect(function(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = rootOf(player)
			if not humanoid or not root then
				return
			end
			local s = seat :: Seat
			if s.Occupant and s.Occupant ~= humanoid then
				info(player, "🚽 Ocupado. Espera tu turno.")
				return
			end
			if humanoid.SeatPart ~= s then
				-- Primero se baja del vehículo (si no, se llevaría la bici al váter). (require aquí
				-- dentro: así no hay requires en círculo)
				require(script.Parent.VehicleService).standUp(player)
			end
			root.CFrame = s.CFrame * CFrame.new(0, 2.5, 0)
			s:Sit(humanoid)
			task.delay(4, function()
				if s.Occupant == humanoid then
					NeedsService.change(player, 0, 2)
					Notify:FireClient(player, "Success", "🚽 *Fluuuush* ¡Qué alivio! No olvides lavarte las manos. 🧼")
					floatText(s.Position + Vector3.new(0, 2, 0), "💦 FLUSH", rgb(150, 210, 255))
				end
			end)
		end)
	end,
	MetroSink = function(sink)
		prompt(sink, "Lavarse las manos", "🚰 Lavabo", 0.8, 7).Triggered:Connect(function(player)
			-- El grifo más cercano a este lavabo
			local best, bestD = nil, math.huge
			for _, p in (sink.Parent :: Instance):GetChildren() do
				if p.Name == "Tap" and p:IsA("BasePart") then
					local d = (p.Position - sink.Position).Magnitude
					if d < bestD then
						best, bestD = p, d
					end
				end
			end
			burst(best and best:FindFirstChild("Water") :: ParticleEmitter?, 2.5)
			Notify:FireClient(player, "Success", "🧼 Manos limpias y brillantes. ✨")
		end)
	end,
	MetroDryer = function(dryer)
		prompt(dryer, "Secarse las manos", "💨 Secamanos", 0.5, 7).Triggered:Connect(function(player)
			burst(dryer:FindFirstChild("Air") :: ParticleEmitter?, 2.5)
			floatText(dryer.Position + Vector3.new(0, 1.2, 0), "BRRRRRR", rgb(220, 230, 240), 2)
			info(player, "💨 Brrrrrrr… Manos secas (más o menos).")
		end)
	end,
	MetroPhone = function(phone)
		prompt(phone, ("Llamar (%s)"):format(Format.money(LIFE.PhonePrice)), "📞 Teléfono", 0.4, 7).Triggered:Connect(function(player)
			if not DataService.spend(player, LIFE.PhonePrice) then
				Notify:FireClient(player, "Error", "No tienes ni una moneda para llamar.")
				return
			end
			local call = pick(PHONE_CALLS)
			for i, line in call do
				task.delay((i - 1) * 3, function()
					info(player, line)
				end)
			end
		end)
	end,
	MetroATM = function(machine)
		prompt(machine, "Consultar saldo", "💳 Cajero", 0.5, 7).Triggered:Connect(function(player)
			local data = DataService.get(player)
			if data then
				info(player, ("💳 Tu saldo: %s. ¡Que no se te vaya todo en churros!"):format(Format.money(data.Money or 0)))
			end
		end)
	end,
	MetroLocker = function(door)
		local hinge = door:GetAttribute("Hinge")
		if typeof(hinge) ~= "Vector3" then
			return
		end
		local closed = door.CFrame
		local open = false
		-- Gira sobre la bisagra (a la izquierda de la puerta)
		local pivot = CFrame.new(hinge) * closed.Rotation
		local offset = pivot:ToObjectSpace(closed)
		local p = prompt(door, "Abrir taquilla", "🔐 Taquilla", 0.3, 6)
		p.Triggered:Connect(function(player)
			open = not open
			p.ActionText = if open then "Cerrar taquilla" else "Abrir taquilla"
			local goal = if open then pivot * CFrame.Angles(0, math.rad(100), 0) * offset else closed
			TweenService:Create(door, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = goal }):Play()
			if open then
				if ready(player, door, 120) and math.random() < LIFE.LockerCoinChance then
					DataService.addMoney(player, 1, false)
					Notify:FireClient(player, "Success", "🔓 ¡Alguien se dejó una moneda! +" .. Format.money(1))
				else
					info(player, pick(LOCKER_FINDS))
				end
			end
		end)
	end,
	MetroBin = function(bin)
		prompt(bin, "Rebuscar", "🗑️ Papelera", 0.8, 7).Triggered:Connect(function(player)
			if not ready(player, "Bin", LIFE.BinCooldown) then
				info(player, "🗑️ Ya has rebuscado hace nada. Qué asco, por cierto.")
				return
			end
			if math.random() < LIFE.BinCoinChance then
				DataService.addMoney(player, 1, false)
				Notify:FireClient(player, "Success", "🗑️ Entre la basura brilla algo… ¡una moneda! +" .. Format.money(1))
			else
				info(player, pick(BIN_FINDS))
			end
		end)
	end,
	MetroIntercom = function(box)
		prompt(box, "Pulsar SOS", "📢 Interfono", 0.6, 7).Triggered:Connect(function(player)
			if not ready(player, "Intercom", 5) then
				return
			end
			info(player, "📢 Bzzz… Conectando con seguridad…")
			task.delay(2, function()
				info(player, pick(INTERCOM_LINES))
			end)
		end)
	end,
	MetroFountain = function(water)
		prompt(water, ("Tirar una moneda (%s)"):format(Format.money(LIFE.WishPrice)), "⛲ Fuente de los deseos", 0.4, 9).Triggered:Connect(function(player)
			if not DataService.spend(player, LIFE.WishPrice) then
				Notify:FireClient(player, "Error", "No te quedan monedas para pedir un deseo.")
				return
			end
			local root = rootOf(player)
			local at = if root then water.Position:Lerp(root.Position, 0.35) else water.Position
			floatText(Vector3.new(at.X, water.Position.Y + 0.8, at.Z), "🪙 plin", rgb(250, 220, 90))
			info(player, pick(FORTUNES))
		end)
	end,
	MetroPiano = function(piano)
		local notes = { "🎵", "🎶", "♪", "♫" }
		prompt(piano, "Tocar el piano", "🎹 Piano libre", 0.3, 9).Triggered:Connect(function(player)
			if not ready(player, "Piano", 3) then
				return
			end
			for i = 0, 5 do
				task.delay(i * 0.35, function()
					floatText(piano.Position + Vector3.new(math.random(-15, 15) / 10, 2.5, math.random(-10, 10) / 10), pick(notes), Color3.fromHSV(math.random(), 0.5, 1), 1.8)
				end)
			end
			info(player, pick({ "🎹 Tocas una melodía. Alguien aplaude a lo lejos. 👏", "🎹 Plin, plon… ¡Te sale el «Cumpleaños feliz»!", "🎹 Aporreas las teclas con mucho sentimiento.", "🎹 Una melodía tranquila llena la galería." }))
		end)
	end,
	MetroShine = function(chair)
		prompt(chair, ("Limpiar zapatos (%s)"):format(Format.money(LIFE.ShinePrice)), "👞 Limpiabotas", 0.5, 8).Triggered:Connect(function(player)
			if not DataService.spend(player, LIFE.ShinePrice) then
				Notify:FireClient(player, "Error", "No te llega para la limpieza de zapatos.")
				return
			end
			local root = rootOf(player)
			if root then
				local sparkle = Instance.new("Sparkles")
				sparkle.SparkleColor = rgb(255, 240, 180)
				sparkle.Parent = root
				task.delay(6, function()
					sparkle:Destroy()
				end)
			end
			for marker, npc in statics do
				if marker:GetAttribute("Role") == "Shiner" and npc.Parent then
					speak(npc, "¡Como espejos! Vuelve cuando quieras. ✨", 4)
				end
			end
			Notify:FireClient(player, "Success", "👞 ¡Zapatos relucientes! Se ven desde el otro andén. ✨")
		end)
	end,
	MetroStatue = function(marker)
		prompt(marker, "Dar propina (1 €)", "🗿 Estatua humana", 0.3, 9).Triggered:Connect(function(player)
			if not DataService.spend(player, 1) then
				Notify:FireClient(player, "Error", "No tienes ni una moneda.")
				return
			end
			local npc = statics[marker]
			if npc and npc.Parent then
				Npc.work(npc, nil)
				speak(npc, pick({ "¡Gracias! *hace una reverencia*", "*te guiña un ojo sin moverse*", "*se mueve como un robot* ¡Bip, gracias!" }), 3)
				task.delay(3, function()
					if npc.Parent then
						Npc.work(npc, "Present")
					end
				end)
			end
			info(player, "🗿 La estatua cobra vida un segundo para darte las gracias.")
		end)
	end,
}

---------------------------------------------------------------------
-- Bucle: aparecer/desaparecer según haya gente cerca, y lámparas que fallan
---------------------------------------------------------------------

local function tick()
	local range = LIFE.ActiveRange
	for _, post in CollectionService:GetTagged("MetroGuardPost") do
		if post:IsA("BasePart") then
			local active = anyoneNear(post.Position, range)
			local npc = posts[post]
			if active and not (npc and npc.Parent) then
				spawnPatrol(post)
			elseif not active and npc then
				npc:Destroy()
				posts[post] = nil
			end
		end
	end
	for _, tag in { "MetroStaff", "MetroStatue" } do
		for _, marker in CollectionService:GetTagged(tag) do
			if marker:IsA("BasePart") then
				local active = anyoneNear(marker.Position, range)
				local npc = statics[marker]
				if active and not (npc and npc.Parent) then
					spawnStatic(marker)
				elseif not active and npc then
					npc:Destroy()
					statics[marker] = nil
				end
			end
		end
	end
	for _, nest in CollectionService:GetTagged("MetroRatNest") do
		if nest:IsA("BasePart") then
			local list = nests[nest] or {}
			nests[nest] = list
			for i = #list, 1, -1 do
				if not list[i].Model.Parent then
					table.remove(list, i)
				end
			end
			local active = anyoneNear(nest.Position, range * 0.6)
			if active and #list < LIFE.RatsPerNest and math.random() < 0.15 then
				spawnRat(nest)
			elseif not active then
				for _, rat in list do
					rat.Model:Destroy()
				end
				table.clear(list)
			end
		end
	end
end

local function flicker()
	for _, lamp in CollectionService:GetTagged("MetroFlicker") do
		if lamp:IsA("BasePart") and anyoneNear(lamp.Position, 80) and math.random() < 0.35 then
			local light = lamp:FindFirstChildOfClass("SurfaceLight")
			task.spawn(function()
				for _ = 1, math.random(2, 5) do
					lamp.Material = Enum.Material.SmoothPlastic
					if light then
						light.Enabled = false
					end
					task.wait(math.random(3, 12) / 100)
					lamp.Material = Enum.Material.Neon
					if light then
						light.Enabled = true
					end
					task.wait(math.random(5, 20) / 100)
				end
			end)
		end
	end
end

function MetroLifeService.init()
	ratFolder = Instance.new("Folder")
	ratFolder.Name = "MetroRatas"
	ratFolder.Parent = workspace
	for tag, fn in SETUP do
		for _, part in CollectionService:GetTagged(tag) do
			if part:IsA("BasePart") then
				fn(part)
			end
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			if part:IsA("BasePart") then
				fn(part)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(tick)
			if not ok then
				warn("[MetroLifeService] " .. tostring(err))
			end
			pcall(flicker)
		end
	end)
end

return MetroLifeService
