-- PetService: mascotas (adopción en la Protectora de Valmar) y montar a caballo en los Campos.
--
--   * PROTECTORA (Kit/AnimalKit, en Valmar Centro): en el mostrador, «Adoptar» abre la ventana (Remote
--     "Pets", la dibuja EconomyUI): perro o gato, raza y color (shared/Pets), nombre (NameFilter + filtro
--     de Roblox) y una donación voluntaria (gratis si no). Como mucho Pets.MAX_OWNED mascotas. La
--     recepcionista es un vecino (Npc).
--   * VAGABUNDOS (shared/Pets.Strays, los pinta Wildlife): «Llamar» → te sigue; si sigue contigo
--     Pets.STRAY_FOLLOW_TIME segundos, «Adoptar» (le pones nombre). Ese sitio se queda vacío un rato
--     (atributo StrayTaken_<id> de la carpeta "Mascotas": hasta cuándo, en hora del servidor).
--   * TU MASCOTA: una Configuration en workspace.Mascotas por jugador (atributos Owner, PetId, Kind,
--     Breed, Coat, PetName, Mode = "Follow" | "Sit" | "Home", SitAt, HomeAt, OwnerHome, CallAt). Cada
--     cliente la pinta y la mueve detrás de su dueño (Wildlife + Pets.stepFollow): sin coste de red.
--     No entra en el metro ni en tiendas: te espera fuera. «A casa»: se queda en tu casa (en el jardín
--     de tu parcela, o contigo cuando estás dentro de tu vivienda).
--   * Se guarda en la partida: data.Pets = { Owned = { Pet }, Out = id de la que va contigo }.
--   * CABALLOS: poste «Montar a caballo» (HorseStation) del picadero → un caballo ensillado que se
--     lleva como un vehículo (VehicleService.mount "Caballo", gratis; al bajarte se queda en el campo).
--   Ventanas: "Protectora" (pestañas Perros, Gatos, Mias), "Nombre" (nombre y donación), "Mascotas".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Pets = require(ReplicatedStorage.Shared.Pets)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)

local PetService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local folder: Folder

local SHELTER_REACH = 30 -- a esta distancia del mostrador se puede adoptar
local STRAY_REACH = 40 -- para llamar a un vagabundo
local STRAY_ADOPT_REACH = 160 -- para adoptarlo (te ha seguido)

type Pending = { Kind: string, Breed: string, Coat: number, Donation: number, Stray: string? }
local pending: { [Player]: Pending } = {}
local calls: { [Player]: { [string]: number } } = {}
local lastAction: { [Player]: number } = {}
local lastName: { [Player]: number } = {}
local lastRide: { [Player]: number } = {}
local desks: { BasePart } = {}

---------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------
local function petData(player: Player): { Owned: { Pets.Pet }, Out: string }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if type(data.Pets) ~= "table" then
		data.Pets = { Owned = {}, Out = "" }
	end
	if type(data.Pets.Owned) ~= "table" then
		data.Pets.Owned = {}
	end
	if type(data.Pets.Out) ~= "string" then
		data.Pets.Out = ""
	end
	return data.Pets
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Hora del servidor (la misma que ven los clientes con GetServerTimeNow); las pruebas la cambian
PetService.clock = function(): number
	return workspace:GetServerTimeNow()
end
local function serverNow(): number
	return PetService.clock()
end

---------------------------------------------------------------------
-- La mascota que se ve (una por jugador)
---------------------------------------------------------------------
local function configOf(player: Player): Configuration?
	return folder:FindFirstChild(tostring(player.UserId)) :: Configuration?
end

local function show(player: Player, pet: Pets.Pet?, mode: string)
	local config = configOf(player)
	if not pet then
		if config then
			config:Destroy()
		end
		return
	end
	if not config then
		config = Instance.new("Configuration")
		config.Name = tostring(player.UserId)
		config:SetAttribute("Owner", player.UserId)
		config.Parent = folder
	end
	local c = config :: Configuration
	c:SetAttribute("PetId", pet.Id)
	c:SetAttribute("Kind", pet.Kind)
	c:SetAttribute("Breed", pet.Breed)
	c:SetAttribute("Coat", pet.Coat)
	c:SetAttribute("PetName", pet.Name)
	c:SetAttribute("Mode", mode)
	if mode ~= "Sit" then
		c:SetAttribute("SitAt", nil)
	end
end

local function syncShown(player: Player)
	local pd = petData(player)
	if not pd then
		return
	end
	local out = Pets.find(pd.Owned, pd.Out)
	if out then
		show(player, out, "Follow")
	else
		-- Ninguna contigo: la última que adoptaste se queda en casa (se ve en tu casa)
		show(player, pd.Owned[#pd.Owned], "Home")
	end
	player:SetAttribute("PetCount", #pd.Owned)
end

---------------------------------------------------------------------
-- Ventanas (EconomyUI)
---------------------------------------------------------------------
local function button(text: string, action: string, args: { any }?, style: string?, disabled: boolean?): { [string]: any }
	return { Text = text, Action = action, Args = args or {}, Style = style, Disabled = disabled }
end

local function send(player: Player, panel: { [string]: any })
	Remote:FireClient(player, "Panel", panel)
end

local function money(player: Player): number
	local data = DataService.get(player)
	return if data then tonumber(data.Money) or 0 else 0
end

local function shelterPanel(player: Player, tab: string?): { [string]: any }
	tab = if tab == "Gatos" or tab == "Mias" then tab else "Perros"
	local pd = petData(player)
	local count = if pd then #pd.Owned else 0
	local rows = {}
	if tab == "Mias" then
		return nil :: any -- (se manda la de "Mascotas")
	end
	local kind = if tab == "Gatos" then "Gato" else "Perro"
	table.insert(rows, { Header = ("Adoptar es GRATIS (donación voluntaria al final). Tienes %d/%d mascotas."):format(count, Pets.MAX_OWNED) })
	for _, b in Pets.Breeds[kind] do
		local buttons = {}
		for i, coat in b.Coats do
			if #buttons < 3 then
				table.insert(buttons, button(coat[1], "Pick", { kind, b.Id, i }, if i == 1 then "Accent" else nil, count >= Pets.MAX_OWNED))
			end
		end
		table.insert(rows, {
			Icon = Pets.Kinds[kind].Icon,
			Title = b.Name,
			Text = b.Text .. (if b.Scale and b.Scale < 0.8 then " · pequeño" elseif b.Scale and b.Scale > 1.1 then " · grande" else ""),
			Buttons = buttons,
		})
	end
	return {
		Remote = "Pets",
		Id = "Protectora",
		Title = "🐾 Protectora de animales de Valmar",
		Subtitle = "Elige raza y color. Luego le pones nombre.",
		Tabs = { { Id = "Perros", Text = "🐶 Perros" }, { Id = "Gatos", Text = "🐱 Gatos" }, { Id = "Mias", Text = "🐾 Mis mascotas" } },
		Tab = tab,
		Rows = rows,
		Footer = "Tu mascota te sigue, se sienta, la puedes llamar y se queda en tu casa. Se guarda en tu partida.",
	}
end

local function namePanel(player: Player): { [string]: any }?
	local p = pending[player]
	if not p then
		return nil
	end
	local rows = {}
	local icon = Pets.Kinds[p.Kind].Icon
	table.insert(rows, { Header = ("Has elegido: %s %s%s"):format(icon, Pets.describe(p.Kind, p.Breed, p.Coat), if p.Stray then " (te ha seguido por la calle)" else "") })
	if not p.Stray then
		local buttons = {}
		for _, amount in Pets.DONATIONS do
			table.insert(buttons, button(if amount == 0 then "Nada" else Format.money(amount), "Donate", { amount }, if p.Donation == amount then "Accent" else nil))
		end
		table.insert(rows, {
			Icon = "💝",
			Title = "Donación a la protectora (opcional)",
			Text = ("Adoptar es gratis. Con tu donación comen los que aún esperan. Ahora: %s"):format(if p.Donation > 0 then Format.money(p.Donation) else "sin donación"),
			Buttons = buttons,
		})
	end
	table.insert(rows, { Input = { Placeholder = ("Ponle nombre (%d-%d letras)"):format(Pets.NAME_MIN, Pets.NAME_MAX), Button = "Adoptar ❤", Action = "Adopt", Args = {}, Max = Pets.NAME_MAX } })
	if not p.Stray then
		table.insert(rows, { Icon = "↩", Title = "Elegir otro", Text = "Volver a la lista de la protectora.", Buttons = { button("Volver", "Panel", { "Protectora", if p.Kind == "Gato" then "Gatos" else "Perros" }) } })
	end
	return {
		Remote = "Pets",
		Id = "Nombre",
		Title = "🐾 Adopción",
		Subtitle = "Escribe su nombre y pulsa «Adoptar».",
		Rows = rows,
	}
end

local MODE_TEXT = { Follow = "Va contigo", Sit = "Sentado/a esperándote", Home = "En casa" }

local function minePanel(player: Player, confirm: string?): { [string]: any }
	local pd = petData(player)
	local rows = {}
	if not pd or #pd.Owned == 0 then
		table.insert(rows, { Header = "Aún no tienes mascota. Adopta una en la Protectora de Valmar (🐾 en el mapa) o a un perro o gato de la calle que te siga." })
	else
		local config = configOf(player)
		local mode = if config then config:GetAttribute("Mode") else nil
		for _, pet in pd.Owned do
			local out = pd.Out == pet.Id
			local state = if out then (MODE_TEXT[mode or "Follow"] or "Va contigo") else "En casa"
			local buttons
			if confirm == pet.Id then
				buttons = { button("Sí, devolver", "ReleaseYes", { pet.Id }, "Danger"), button("No", "Panel", { "Mascotas" }) }
			elseif out then
				buttons = {
					if mode == "Sit" then button("Seguir", "Follow", { pet.Id }, "Accent") else button("Sentarse", "Sit", { pet.Id }),
					button("Llamar", "Call", { pet.Id }),
					button("A casa", "Home", { pet.Id }),
				}
			else
				buttons = { button("Sacar", "Out", { pet.Id }, "Accent"), button("Devolver", "Release", { pet.Id }) }
			end
			table.insert(rows, {
				Icon = Pets.Kinds[pet.Kind].Icon,
				Title = ("%s · %s"):format(pet.Name, Pets.describe(pet.Kind, pet.Breed, pet.Coat)),
				Text = state .. (if pet.Stray then " · lo encontraste en la calle" else " · de la protectora"),
				Buttons = buttons,
			})
		end
	end
	return {
		Remote = "Pets",
		Id = "Mascotas",
		Title = "🐾 Mis mascotas",
		Subtitle = ("%d/%d · solo una va contigo a la vez"):format(if pd then #pd.Owned else 0, Pets.MAX_OWNED),
		Rows = rows,
		Footer = "No entran en el metro ni en las tiendas: te esperan fuera. «A casa»: te esperan en tu casa.",
	}
end

local function openPanel(player: Player, id: any, tab: any)
	if id == "Protectora" and tab ~= "Mias" then
		send(player, shelterPanel(player, tab))
	elseif id == "Nombre" then
		local panel = namePanel(player)
		if panel then
			send(player, panel)
		end
	else
		send(player, minePanel(player))
	end
end

---------------------------------------------------------------------
-- Adoptar
---------------------------------------------------------------------
-- Filtro de Roblox (obligatorio para enseñar a otros un texto escrito por un jugador)
PetService._robloxFilter = function(text: string, userId: number): (boolean, string?)
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		if RunService:IsStudio() then
			return true, nil
		end
		return false, "No se ha podido comprobar el nombre ahora. Prueba otra vez en un momento."
	end
	if result ~= text then
		return false, "🚫 Roblox no permite ese nombre. Elige otro."
	end
	return true, nil
end

local function nearShelter(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	for _, desk in desks do
		if (desk.Position - root.Position).Magnitude <= SHELTER_REACH then
			return true
		end
	end
	return #desks == 0 -- (sin protectora en el mapa, p. ej. en pruebas, no se mira)
end

local function strayAvailable(id: string): boolean
	local untilAt = folder:GetAttribute("StrayTaken_" .. id)
	return not (type(untilAt) == "number" and serverNow() < untilAt)
end

local function nearStray(player: Player, stray: { [string]: any }, reach: number): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	return Vector2.new(root.Position.X - stray.At[1], root.Position.Z - stray.At[2]).Magnitude <= reach
end

-- Adopta lo que tenga elegido (pending) con este nombre. Devuelve la mascota o nil (y avisa)
function PetService.adopt(player: Player, name: any): Pets.Pet?
	local p = pending[player]
	local pd = petData(player)
	if not p or not pd then
		Notify:FireClient(player, "Info", "Elige primero el animal en la protectora.")
		return nil
	end
	if player:GetAttribute("LifeStage") == "Bebe" then
		Notify:FireClient(player, "Info", "Todavía eres muy pequeño para cuidar de una mascota. 🍼")
		return nil
	end
	if p.Stray then
		local stray = Pets.stray(p.Stray)
		if not stray or not strayAvailable(p.Stray) or not nearStray(player, stray, STRAY_ADOPT_REACH) then
			Notify:FireClient(player, "Error", "Ese animal ya no está contigo.")
			pending[player] = nil
			return nil
		end
	elseif not nearShelter(player) then
		Notify:FireClient(player, "Error", "Para adoptar, ve al mostrador de la protectora.")
		return nil
	end
	local okAdopt, why = Pets.canAdopt(pd.Owned, p.Kind, p.Breed, p.Coat)
	if not okAdopt then
		Notify:FireClient(player, "Error", why or "No se puede adoptar ahora.")
		return nil
	end
	if os.clock() - (lastName[player] or -10) < 2 then
		Notify:FireClient(player, "Info", "Espera un momento antes de probar otro nombre.")
		return nil
	end
	lastName[player] = os.clock()
	local okName, whyName, clean = Pets.checkName(name)
	if okName then
		okName, whyName = PetService._robloxFilter(clean, player.UserId)
	end
	if not okName then
		Notify:FireClient(player, "Error", whyName or "Ese nombre no vale.")
		return nil
	end
	-- Donación (voluntaria): si no te llega el dinero, se adopta igual sin donar
	local donated = 0
	if p.Donation > 0 and table.find(Pets.DONATIONS, p.Donation) then
		if DataService.spend(player, p.Donation) then
			donated = p.Donation
		end
	end
	local pet, err = Pets.adopt(pd.Owned, p.Kind, p.Breed, p.Coat, clean, os.time(), p.Stray ~= nil)
	if not pet then
		if donated > 0 then
			DataService.addMoney(player, donated)
		end
		Notify:FireClient(player, "Error", err or "No se puede adoptar ahora.")
		return nil
	end
	if p.Stray then
		folder:SetAttribute("StrayTaken_" .. p.Stray, serverNow() + Pets.STRAY_BACK)
		if calls[player] then
			calls[player][p.Stray] = nil
		end
	end
	pending[player] = nil
	pd.Out = pet.Id
	syncShown(player)
	Remote:FireClient(player, "Close", "Nombre")
	Notify:FireClient(player, "Success", ("%s ¡%s ya es parte de tu familia!%s"):format(Pets.Kinds[pet.Kind].Icon, pet.Name, if donated > 0 then (" Gracias por tu donación de %s."):format(Format.money(donated)) else ""))
	pcall(function()
		require(script.Parent.Parent.LifeStory.StoryEvents).emit(player, "PetAdopted", { Kind = pet.Kind, Breed = pet.Breed, Stray = pet.Stray == true })
	end)
	return pet
end

---------------------------------------------------------------------
-- Órdenes
---------------------------------------------------------------------
local function setMode(player: Player, petId: any, mode: string)
	local pd = petData(player)
	if not pd then
		return
	end
	local pet = Pets.find(pd.Owned, petId)
	if not pet then
		return
	end
	if mode == "Home" then
		pd.Out = ""
		show(player, pet, "Home")
		Notify:FireClient(player, "Info", ("🏠 %s se va a casa."):format(pet.Name))
	elseif mode == "Follow" or mode == "Sit" then
		pd.Out = pet.Id
		show(player, pet, mode)
		local config = configOf(player)
		if mode == "Sit" and config then
			local root = rootOf(player)
			config:SetAttribute("SitAt", if root then root.Position else nil)
		end
	end
	player:SetAttribute("PetCount", #pd.Owned)
end

local function handle(player: Player, action: any, ...)
	if type(action) ~= "string" then
		return
	end
	local now = os.clock()
	if now - (lastAction[player] or -1) < 0.25 then
		return
	end
	lastAction[player] = now
	local a, b, c = ...
	if action == "Panel" then
		openPanel(player, a, b)
	elseif action == "Pick" then
		if not nearShelter(player) then
			Notify:FireClient(player, "Error", "Para adoptar, ve al mostrador de la protectora.")
			return
		end
		local pd = petData(player)
		local ok, why = Pets.canAdopt(if pd then pd.Owned else {}, a, b, c)
		if not ok then
			Notify:FireClient(player, "Error", why or "No se puede.")
			return
		end
		pending[player] = { Kind = a, Breed = b, Coat = c, Donation = 0 }
		openPanel(player, "Nombre")
	elseif action == "Donate" then
		local p = pending[player]
		if p and not p.Stray and table.find(Pets.DONATIONS, a) then
			if a > money(player) then
				Notify:FireClient(player, "Error", "No llevas tanto dinero. ¡No pasa nada, adoptar es gratis!")
				return
			end
			p.Donation = a
			openPanel(player, "Nombre")
		end
	elseif action == "Adopt" then
		-- (el texto llega el último)
		local name = select(select("#", ...), ...)
		PetService.adopt(player, name)
	elseif action == "Out" or action == "Follow" then
		setMode(player, a, "Follow")
		openPanel(player, "Mascotas")
	elseif action == "Sit" then
		setMode(player, a, "Sit")
		openPanel(player, "Mascotas")
	elseif action == "Home" then
		setMode(player, a, "Home")
		openPanel(player, "Mascotas")
	elseif action == "Call" then
		local pd = petData(player)
		local pet = pd and Pets.find(pd.Owned, a)
		if pet then
			setMode(player, a, "Follow")
			local config = configOf(player)
			if config then
				config:SetAttribute("CallAt", serverNow())
			end
			Notify:FireClient(player, "Info", ("📣 ¡%s, ven!"):format(pet.Name))
		end
	elseif action == "Release" then
		send(player, minePanel(player, a))
	elseif action == "ReleaseYes" then
		local pd = petData(player)
		local pet, index = nil, nil
		if pd then
			pet, index = Pets.find(pd.Owned, a)
		end
		if pd and pet and index then
			table.remove(pd.Owned, index)
			if pd.Out == pet.Id then
				pd.Out = ""
			end
			syncShown(player)
			Notify:FireClient(player, "Info", ("🐾 %s vuelve a la protectora. Allí le buscarán otra familia."):format(pet.Name))
		end
		openPanel(player, "Mascotas")
	elseif action == "StrayCall" then
		local stray = Pets.stray(a)
		if not stray or not strayAvailable(a) or not nearStray(player, stray, STRAY_REACH) then
			return
		end
		calls[player] = calls[player] or {}
		calls[player][a] = now
		Remote:FireClient(player, "StrayFollow", a)
		Notify:FireClient(player, "Info", ("%s Te sigue… Si sigue contigo un rato, podrás adoptarlo."):format(Pets.Kinds[stray.Kind].Icon))
	elseif action == "StrayAdopt" then
		local stray = Pets.stray(a)
		local called = calls[player] and calls[player][a]
		if not stray or not called or not strayAvailable(a) then
			Notify:FireClient(player, "Info", "Llámale primero y deja que te siga un rato.")
			return
		end
		local since = now - called
		if since < Pets.STRAY_FOLLOW_TIME then
			Notify:FireClient(player, "Info", ("Aún no se fía: deja que te siga %d segundos más."):format(math.ceil(Pets.STRAY_FOLLOW_TIME - since)))
			return
		end
		if since > Pets.STRAY_CALL_WINDOW or not nearStray(player, stray, STRAY_ADOPT_REACH) then
			calls[player][a] = nil
			Notify:FireClient(player, "Info", "Se ha cansado de seguirte y ha vuelto a su sitio.")
			return
		end
		local pd = petData(player)
		local ok, why = Pets.canAdopt(if pd then pd.Owned else {}, stray.Kind, stray.Breed, stray.Coat)
		if not ok then
			Notify:FireClient(player, "Error", why or "No se puede.")
			return
		end
		pending[player] = { Kind = stray.Kind, Breed = stray.Breed, Coat = stray.Coat, Donation = 0, Stray = a }
		openPanel(player, "Nombre")
	end
end

---------------------------------------------------------------------
-- Dónde está «tu casa» (para la mascota que se queda en casa)
---------------------------------------------------------------------
local function plotHome(player: Player): Vector3?
	local id = player:GetAttribute("PlotId")
	if id == nil then
		return nil
	end
	for _, model in CollectionService:GetTagged("Plot") do
		if model:GetAttribute("PlotId") == id then
			local origin = model:GetAttribute("Origin")
			if typeof(origin) == "CFrame" then
				return (origin * CFrame.new(5, 1, -21)).Position
			end
		end
	end
	return nil
end

-- ¿Está dentro de su propia vivienda? (InteriorKey = edificio:planta o edificio:vivienda)
local function atOwnHome(player: Player): boolean
	local key = player:GetAttribute("InteriorKey")
	if type(key) ~= "string" then
		return false
	end
	local data = DataService.get(player)
	local list = data and data.Properties
	if type(list) ~= "table" then
		return false
	end
	local ok, InteriorService = pcall(require, script.Parent.InteriorService)
	if not ok then
		return false
	end
	for _, entry in list do
		if type(entry) == "table" and type(entry.Key) == "string" then
			local building = InteriorService.byKey(entry.Key)
			if building then
				local floor = tonumber(entry.Floor) or 0
				local unitOk, unitId = pcall(Floors.unitId, floor, entry.Letter or "A")
				if key == building.Id .. ":" .. tostring(floor) or (unitOk and key == building.Id .. ":" .. tostring(unitId)) then
					return true
				end
			end
		end
	end
	return false
end

local function refreshHomes()
	for _, player in Players:GetPlayers() do
		local config = configOf(player)
		if config then
			local home = config:GetAttribute("Mode") == "Home"
			config:SetAttribute("HomeAt", if home then plotHome(player) else nil)
			config:SetAttribute("OwnerHome", home and atOwnHome(player) or nil)
		end
	end
end

---------------------------------------------------------------------
-- Montar a caballo
---------------------------------------------------------------------
local function setupHorseStation(station: Instance)
	if not station:IsA("BasePart") then
		return
	end
	local prompt = Builder.prompt(station, "Montar a caballo", "🐴 Picadero · gratis", 0.4)
	prompt.MaxActivationDistance = 9
	prompt.Triggered:Connect(function(player)
		if os.clock() - (lastRide[player] or -10) < 4 then
			return
		end
		lastRide[player] = os.clock()
		if player:GetAttribute("LifeStage") == "Bebe" then
			Notify:FireClient(player, "Info", "Todavía eres muy pequeño para montar a caballo. 🍼")
			return
		end
		local ok, VehicleService = pcall(require, script.Parent.VehicleService)
		if ok and VehicleService.mount(player, "Caballo", { Rented = true }) then
			Notify:FireClient(player, "Info", "🐴 Acelera para ir al paso, al trote y al galope. Para bajarte, salta.")
		end
	end)
end

local function setupDesk(desk: Instance)
	if not desk:IsA("BasePart") then
		return
	end
	table.insert(desks, desk)
	local prompt = Builder.prompt(desk, "Adoptar", "🐾 Protectora de animales", 0.2)
	prompt.Triggered:Connect(function(player)
		send(player, shelterPanel(player, "Perros"))
	end)
	local mine = Builder.prompt(desk, "Mis mascotas", "🐾 Protectora de animales", 0.2)
	mine.KeyboardKeyCode = Enum.KeyCode.R
	mine.UIOffset = Vector2.new(0, 58)
	mine.Triggered:Connect(function(player)
		send(player, minePanel(player))
	end)
end

local function setupStaff(spot: Instance)
	if not spot:IsA("BasePart") then
		return
	end
	local ok, npc = pcall(Npc.create, "Recepcionista de la protectora", folder, spot.CFrame * CFrame.new(0, 0, 0), {
		Shirt = Color3.fromRGB(60, 150, 120),
		Pants = Color3.fromRGB(50, 56, 70),
	})
	if ok and npc then
		pcall(Npc.work, npc, "Clipboard")
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
function PetService.init()
	Remote = ReplicatedStorage.Remotes:FindFirstChild("Pets") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Pets"
		Remote.Parent = ReplicatedStorage.Remotes
	end
	folder = Instance.new("Folder")
	folder.Name = "Mascotas"
	folder.Parent = workspace

	Remote.OnServerEvent:Connect(function(player, action, ...)
		local ok, err = pcall(handle, player, action, ...)
		if not ok then
			warn("[Mascotas] " .. tostring(err))
		end
	end)

	DataService.onLoaded(function(player, data)
		data.Pets = if type(data.Pets) == "table" then data.Pets else {}
		data.Pets.Owned = Pets.sanitize(data.Pets.Owned)
		data.Pets.Out = if type(data.Pets.Out) == "string" and Pets.find(data.Pets.Owned, data.Pets.Out) then data.Pets.Out else ""
		syncShown(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local config = configOf(player)
		if config then
			config:Destroy()
		end
		pending[player] = nil
		calls[player] = nil
		lastAction[player] = nil
		lastName[player] = nil
		lastRide[player] = nil
	end)

	for _, desk in CollectionService:GetTagged("PetShelterDesk") do
		setupDesk(desk)
	end
	CollectionService:GetInstanceAddedSignal("PetShelterDesk"):Connect(setupDesk)
	for _, spot in CollectionService:GetTagged("PetShelterStaff") do
		task.spawn(setupStaff, spot)
	end
	for _, station in CollectionService:GetTagged("HorseStation") do
		setupHorseStation(station)
	end
	CollectionService:GetInstanceAddedSignal("HorseStation"):Connect(setupHorseStation)

	task.spawn(function()
		while true do
			task.wait(2)
			local ok, err = pcall(refreshHomes)
			if not ok then
				warn("[Mascotas] " .. tostring(err))
			end
		end
	end)
end

return PetService
