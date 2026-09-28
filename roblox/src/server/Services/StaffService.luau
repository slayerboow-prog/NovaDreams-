-- StaffService: que cada sitio que atiende al público tenga a alguien en su puesto.
--
--   * Puestos (post): en el mapa, piezas StaffSpot (Kit/Decor: dependientes del centro comercial,
--     cajeros de la gasolinera y la hamburguesería, recepción de las oficinas y del hospital,
--     agente de guardia de la comisaría, bomberos del parque, funcionarios de Correos, bibliotecaria,
--     conserje de la facultad, encargado de los recreativos, profesor de la autoescuela, monitor/a
--     del gimnasio…) con Role, Work y, si es un oficio de jugadores, JobId. Otros servicios pueden
--     pedir un puesto con StaffService.ensure(sitio, rol, cf, tarea, opciones).
--   * Si no hay ningún jugador cubriendo ese oficio allí (atributo Job del jugador = JobId y cerca
--     del puesto), lo hace una persona (World/Npc) con su uniforme y su tarea (Npc.work: teclear,
--     cobrar, apuntar…). Cuando un jugador empieza ese oficio allí, la persona se aparta y se va; y
--     cuando lo deja (o se va de allí), vuelve a su puesto andando.
--   * Solo hay personas donde hay algún jugador cerca (ACTIVE studs): la ciudad no gasta nada donde
--     no mira nadie. Al acercarte te miran; con "Hablar" te dicen algo de su oficio.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local OpeningHours = require(game:GetService("ReplicatedStorage").Shared.OpeningHours)
local TimeContext = require(game:GetService("ReplicatedStorage").Shared.LifeStory.TimeContext)
local Npc = require(script.Parent.Parent.World.Npc)

local StaffService = {}

StaffService.ACTIVE = 170 -- solo hay personal si algún jugador está a menos de esto
StaffService.COVER = 60 -- un jugador de ese oficio a menos de esto cubre el puesto
StaffService.TICK = 1
StaffService.LEAVE_SEEN = 14 -- quien se retira no se esfuma con un jugador a menos de esto…
StaffService.LEAVE_MAX = 25 -- …salvo que pase este rato (s): entonces se va igual

local rgb = Color3.fromRGB

-- Uniformes, icono y frases de cada puesto
type Role = { Look: Npc.Look, Icon: string, Lines: { string } }
local ROLES: { [string]: Role } = {
	Dependiente = { Look = { Shirt = rgb(40, 140, 110), Pants = rgb(40, 40, 50) }, Icon = "🛍️", Lines = { "¡Hola! Si buscas algo, pregúntame.", "Hoy tenemos rebajas.", "¿Te lo envuelvo para regalo?" } },
	Cajero = { Look = { Shirt = rgb(30, 150, 80), Pants = rgb(40, 40, 46) }, Icon = "💳", Lines = { "¿Tarjeta o efectivo?", "¿Quiere bolsa?", "¡Que tenga un buen día!" } },
	Cajera = { Look = { Shirt = rgb(220, 60, 40), Pants = rgb(40, 40, 46) }, Icon = "🍔", Lines = { "¿Qué te pongo?", "¿Menú grande o normal?", "¡Marchando!" } },
	Cocinero = { Look = { Shirt = rgb(245, 245, 245), Pants = rgb(40, 40, 46) }, Icon = "👨‍🍳", Lines = { "¡Salen dos hamburguesas!", "Cuidado, que quema." } },
	Cocinera = { Look = { Shirt = rgb(245, 245, 245), Pants = rgb(40, 40, 46), LongHair = true }, Icon = "👩‍🍳", Lines = { "¡Menú del día recién hecho!", "¿Te pongo patatas?" } },
	Recepcionista = { Look = { Shirt = rgb(245, 245, 245), Pants = rgb(40, 40, 50) }, Icon = "🛎️", Lines = { "¡Bienvenido! ¿En qué puedo ayudarte?", "Firme aquí, por favor.", "Los ascensores están al fondo." } },
	Informadora = { Look = { Shirt = rgb(30, 60, 110), Pants = rgb(30, 30, 36), LongHair = true }, Icon = "ℹ️", Lines = { "Los aseos están al fondo a la derecha.", "Hoy cerramos a las diez.", "La zona de comidas está a la derecha." } },
	Vigilante = { Look = { Shirt = rgb(55, 55, 60), Pants = rgb(35, 35, 40), LongSleeves = true }, Icon = "🛡️", Lines = { "Buenos días.", "Pase por los tornos, por favor." } },
	["Agente de guardia"] = { Look = { Shirt = rgb(40, 60, 110), Pants = rgb(30, 35, 60), LongSleeves = true }, Icon = "👮", Lines = { "¿Viene a poner una denuncia?", "Rellene este formulario, por favor.", "Todo tranquilo en el barrio." } },
	Bombero = { Look = { Shirt = rgb(200, 170, 110), Pants = rgb(60, 60, 66), LongSleeves = true }, Icon = "🚒", Lines = { "El camión está listo por si hay aviso.", "Revisa los detectores de humo de casa.", "¡Hoy toca simulacro!" } },
	Bombera = { Look = { Shirt = rgb(200, 170, 110), Pants = rgb(60, 60, 66), LongSleeves = true, LongHair = true }, Icon = "🚒", Lines = { "Estoy repasando el material.", "Si ves humo, llama al 112." } },
	["Funcionaria de Correos"] = { Look = { Shirt = rgb(250, 200, 30), Pants = rgb(30, 60, 140), LongHair = true }, Icon = "📮", Lines = { "¿Carta o paquete?", "Son dos sellos para el extranjero.", "Coja número, por favor." } },
	["Funcionario de Correos"] = { Look = { Shirt = rgb(250, 200, 30), Pants = rgb(30, 60, 140) }, Icon = "📮", Lines = { "¿Certificado o normal?", "Firme aquí el acuse de recibo." } },
	Bibliotecaria = { Look = { Shirt = rgb(150, 110, 170), Pants = rgb(60, 50, 70), LongHair = true, LongSleeves = true }, Icon = "📚", Lines = { "Shhh… esto es una biblioteca.", "Tienes quince días para devolverlo.", "Las novedades están a la entrada." } },
	Conserje = { Look = { Shirt = rgb(110, 110, 120), Pants = rgb(60, 60, 70), LongSleeves = true }, Icon = "🔑", Lines = { "Las aulas están arriba, en el ascensor.", "El tablón tiene los horarios." } },
	["Encargado de premios"] = { Look = { Shirt = rgb(200, 40, 160), Pants = rgb(30, 30, 36) }, Icon = "🎟️", Lines = { "¡Cambia aquí tus tickets!", "El peluche grande cuesta 500 tickets." } },
	["Profesor de autoescuela"] = { Look = { Shirt = rgb(40, 90, 150), Pants = rgb(50, 50, 60), LongSleeves = true }, Icon = "🚗", Lines = { "Primero la teoría y luego al coche.", "¡Cinturón y retrovisores!", "El STOP se respeta siempre." } },
	Monitora = { Look = { Shirt = rgb(230, 110, 30), Pants = rgb(30, 30, 36), LongHair = true }, Icon = "💪", Lines = { "¡Espalda recta!", "Bebe agua entre series.", "¡Tú puedes, una más!" } },
}
local DEFAULT_ROLE: Role = { Look = {}, Icon = "🙂", Lines = { "¡Hola!", "¿Qué tal?" } }

export type Post = {
	Id: number,
	Role: string,
	CFrame: CFrame, -- pies en el suelo, mirando hacia donde atiende
	Work: string?,
	JobId: string?,
	Parent: Instance,
	Look: Npc.Look?,
	Npc: Model?,
	Busy: boolean, -- creando o apartándose
	Aside: boolean, -- se apartó por un jugador: vuelve andando
	Hours: { number }?, -- { abre, cierra } (nil = siempre)
	Talking: boolean,
	Leaving: Model?, -- se está retirando (cierre o un jugador le cubre): si hace falta, vuelve
}

local posts: { Post } = {}
local folder: Folder? = nil -- (las personas de los puestos de la ciudad van aquí, no dentro de los edificios)
local byPart: { [Instance]: Post } = {}
local nextId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Un puesto de trabajo. place: donde va la persona (su modelo); cf: pies, mirando al público
function StaffService.ensure(place: Instance, role: string, cf: CFrame, work: string?, opts: { JobId: string?, Look: Npc.Look?, Hours: { number }? }?): Post
	nextId += 1
	local post: Post = {
		Id = nextId,
		Role = role,
		CFrame = cf,
		Work = work,
		JobId = opts and opts.JobId,
		Parent = place,
		Look = opts and opts.Look,
		Npc = nil,
		Busy = false,
		Aside = false,
		Hours = opts and opts.Hours,
		Talking = false,
		Leaving = nil,
	}
	table.insert(posts, post)
	return post
end

local function fromSpot(spot: Instance)
	if byPart[spot] or not spot:IsA("BasePart") then
		return
	end
	local role = spot:GetAttribute("Role")
	if type(role) ~= "string" then
		return
	end
	local work = spot:GetAttribute("Work")
	local job = spot:GetAttribute("JobId")
	local post = StaffService.ensure(folder or workspace, role, spot.CFrame * CFrame.new(0, -spot.Size.Y / 2, 0), if type(work) == "string" then work else nil, {
		JobId = if type(job) == "string" then job else nil,
	})
	byPart[spot] = post
	spot.Destroying:Connect(function()
		StaffService.remove(post)
	end)
end

-- Un puesto a partir de su marca StaffSpot (Role, Work, JobId)
StaffService.register = fromSpot

function StaffService.remove(post: Post)
	local i = table.find(posts, post)
	if i then
		table.remove(posts, i)
	end
	if post.Npc then
		post.Npc:Destroy()
		post.Npc = nil
	end
	if post.Leaving then
		post.Leaving:Destroy()
		post.Leaving = nil
	end
end

function StaffService.posts(): { Post }
	return posts
end

-- ¿Algún jugador a menos de radius de un punto?
local function playerWithin(p: Vector3, radius: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - p).Magnitude <= radius then
			return true
		end
	end
	return false
end

-- ¿Algún jugador cerca del puesto? (si no, no hace falta nadie)
local function anyoneNear(post: Post, radius: number): boolean
	local p = post.CFrame.Position
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - p).Magnitude <= radius then
			return true
		end
	end
	return false
end

-- ¿Un jugador de ese oficio lo cubre? (trabajando cerca del puesto)
function StaffService.covered(post: Post): boolean
	if not post.JobId then
		return false
	end
	local p = post.CFrame.Position
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Job") == post.JobId then
			local root = rootOf(player)
			if root and (root.Position - p).Magnitude <= StaffService.COVER then
				return true
			end
		end
	end
	return false
end

-- Horario del puesto: el suyo o el de su oficio (OpeningHours); nil = 24 horas
local function hoursOf(post: Post): { number }?
	return post.Hours or OpeningHours.forRole(post.Role)
end

local function open(post: Post): boolean
	local ok, clock = pcall(function()
		return game:GetService("Lighting").ClockTime
	end)
	return OpeningHours.isOpen(hoursOf(post), if ok and type(clock) == "number" then clock else 12)
end
StaffService.isOpen = open

-- Cartel de CERRADO en el puesto (con la hora a la que abre) mientras alguien está cerca
local function setClosedSign(post: Post, shown: boolean)
	local sign = (post :: any).Sign :: BasePart?
	if shown and not sign then
		local hours = hoursOf(post)
		local part = Instance.new("Part")
		part.Name = "CerradoSign"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.CFrame = post.CFrame + Vector3.new(0, 4.5, 0)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(190, 46)
		billboard.MaxDistance = 45
		billboard.Parent = part
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
		label.BackgroundTransparency = 0.1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = "🔒 CERRADO" .. (if hours then " · " .. OpeningHours.label(hours) else "")
		label.Parent = billboard
		part.Parent = folder or workspace
		;(post :: any).Sign = part
	elseif not shown and sign then
		sign:Destroy()
		;(post :: any).Sign = nil
	end
end
function StaffService.hasClosedSign(post: Post): boolean
	return (post :: any).Sign ~= nil
end

-- Dónde se aparta (a un lado del puesto)
local function asideOf(post: Post): CFrame
	return post.CFrame * CFrame.new(5, 0, 2.5)
end

local function roleOf(post: Post): Role
	return ROLES[post.Role] or DEFAULT_ROLE
end

local function talk(post: Post, npc: Model, player: Player)
	if post.Talking then
		return
	end
	post.Talking = true
	local root = rootOf(player)
	if root then
		Npc.faceSmooth(npc, root.Position)
	end
	-- Una frase que pegue con la hora y el tiempo (y con el saludo de la hora)
	local lines = roleOf(post).Lines
	local hour, weather = TimeContext.now()
	Npc.say(npc, TimeContext.pick(lines, hour, weather) or lines[math.random(1, #lines)])
	task.delay(4, function()
		if npc.Parent then
			Npc.say(npc, nil)
			if post.Npc == npc then
				Npc.face(npc, (post.CFrame * CFrame.new(0, 0, -4)).Position)
			end
		end
		post.Talking = false
	end)
end

local function spawnNpc(post: Post)
	-- ¿Se estaba retirando? Vuelve a su puesto andando (no aparece otro encima de él)
	local leaving = post.Leaving
	if leaving and leaving.Parent then
		post.Leaving = nil
		post.Npc = leaving
		leaving:SetAttribute("Leaving", nil)
		post.Busy = true
		pcall(Npc.say, leaving, nil)
		pcall(Npc.icon, leaving, roleOf(post).Icon)
		local talkPrompt = leaving.PrimaryPart and leaving.PrimaryPart:FindFirstChild("TalkPrompt")
		if talkPrompt and talkPrompt:IsA("ProximityPrompt") then
			talkPrompt.Enabled = true
		end
		pcall(Npc.walkTo, leaving, { post.CFrame.Position }, 7)
		if post.Npc == leaving and leaving.Parent then
			pcall(Npc.face, leaving, (post.CFrame * CFrame.new(0, 0, -4)).Position)
			pcall(Npc.work, leaving, post.Work)
		end
		post.Aside = false
		post.Busy = false
		return
	end
	post.Leaving = nil
	post.Busy = true
	local role = roleOf(post)
	local start = if post.Aside then asideOf(post) else post.CFrame
	local ok, npc = pcall(Npc.create, post.Role, post.Parent, start, post.Look or role.Look)
	if not ok or not npc then
		post.Busy = false
		return
	end
	npc:SetAttribute("StaffRole", post.Role)
	npc:SetAttribute("StaffPost", post.Id)
	post.Npc = npc
	pcall(Npc.icon, npc, role.Icon)
	if post.Aside then
		-- Vuelve a su puesto andando
		pcall(Npc.walkTo, npc, { post.CFrame.Position }, 7)
		pcall(Npc.face, npc, (post.CFrame * CFrame.new(0, 0, -4)).Position)
		post.Aside = false
	end
	pcall(Npc.work, npc, post.Work)
	local root = npc.PrimaryPart
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = "Hablar"
		prompt.ObjectText = role.Icon .. " " .. post.Role
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(function(player)
			talk(post, npc, player)
		end)
	end
	post.Busy = false
end

-- Se retira del puesto (un jugador lo cubre, o cierra): deja la tarea, se despide y se aparta andando.
-- Ya no es la persona del puesto (npcOf = nil), pero no se esfuma delante de nadie: se va cuando no
-- queda ningún jugador al lado (LEAVE_SEEN) o pasado LEAVE_MAX. Si le vuelven a necesitar antes,
-- vuelve a su sitio (spawnNpc) en vez de aparecer otro encima.
local function retire(post: Post, line: string?)
	local npc = post.Npc
	if not npc then
		return
	end
	post.Npc = nil
	post.Leaving = npc
	npc:SetAttribute("Leaving", true)
	post.Talking = false
	pcall(Npc.work, npc, nil)
	pcall(Npc.icon, npc, nil)
	local talkPrompt = npc.PrimaryPart and npc.PrimaryPart:FindFirstChild("TalkPrompt")
	if talkPrompt and talkPrompt:IsA("ProximityPrompt") then
		talkPrompt.Enabled = false -- (ya no atiende)
	end
	if line then
		pcall(Npc.say, npc, line, 4)
	end
	pcall(Npc.walkTo, npc, { asideOf(post).Position }, 7)
	local waited = 0
	while npc.Parent and post.Leaving == npc and waited < StaffService.LEAVE_MAX do
		local root = npc.PrimaryPart
		if not root or not playerWithin(root.Position, StaffService.LEAVE_SEEN) then
			break
		end
		task.wait(1)
		waited += 1
	end
	if post.Leaving == npc then
		post.Leaving = nil
		npc:Destroy()
	end
end
StaffService._retire = retire

-- Un jugador ocupa su puesto: se aparta, se despide y se va
local function stepAside(post: Post)
	post.Aside = true
	retire(post, "¡Todo tuyo! Me tomo un descanso.")
end

-- Una pasada: pone o quita a cada persona según haya jugadores cerca y quién cubre el oficio
function StaffService.tick()
	for _, post in table.clone(posts) do
		if post.Busy then
			continue
		end
		if post.Npc and not post.Npc.Parent then
			post.Npc = nil
		end
		local near = anyoneNear(post, StaffService.ACTIVE)
		local covered = StaffService.covered(post)
		local isOpen = open(post)
		local want = near and not covered and isOpen
		-- Cerrado: nadie en el puesto (se ha ido a casa) y el cartel con la hora a la que abre
		setClosedSign(post, near and not isOpen and not covered)
		if post.Leaving and not post.Leaving.Parent then
			post.Leaving = nil
		end
		if want and not post.Npc then
			task.spawn(spawnNpc, post)
		elseif not want and post.Npc then
			if covered then
				task.spawn(stepAside, post)
			elseif near then
				-- Cierra con gente delante: recoge y se va andando (no desaparece de golpe)
				post.Aside = false
				task.spawn(retire, post, "¡Cerramos! Hasta mañana.")
			else
				post.Npc:Destroy()
				post.Npc = nil
				post.Aside = false
			end
		elseif not near and post.Leaving then
			-- Ya no queda nadie cerca: el que se retiraba se va del todo
			post.Leaving:Destroy()
			post.Leaving = nil
		elseif post.Npc and not post.Talking then
			-- Mira a quien se acerca al mostrador
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root and (root.Position - post.CFrame.Position).Magnitude < 8 then
					Npc.face(post.Npc, root.Position)
					break
				end
			end
		end
	end
end

-- La persona de un puesto (nil si ahora no hay)
function StaffService.npcOf(post: Post): Model?
	return if post.Npc and post.Npc.Parent then post.Npc else nil
end

function StaffService.init()
	local f = Instance.new("Folder")
	f.Name = "Personal"
	f.Parent = workspace
	folder = f
	for _, spot in CollectionService:GetTagged("StaffSpot") do
		fromSpot(spot)
	end
	CollectionService:GetInstanceAddedSignal("StaffSpot"):Connect(fromSpot)
	task.spawn(function()
		while true do
			task.wait(StaffService.TICK)
			local ok, err = pcall(StaffService.tick)
			if not ok then
				warn("[StaffService] " .. tostring(err))
			end
		end
	end)
end

return StaffService
