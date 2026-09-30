-- FarmService: agricultores y ganaderos en las granjas de Villaverde (reglas en shared/Farming).
--
--   * FINCAS: cada granja de Villaverde se reparte en fincas de 5 filas de cultivo: 4 BANCALES y un
--     CORRAL. En la entrada de cada finca hay un cartel: "Quedarme esta finca". Es tuya mientras
--     estás en el servidor; lo plantado y tus animales se guardan contigo (data.Farm) y crecen
--     aunque no estés. Al volver a entrar se te da una finca libre con lo mismo.
--   * BANCAL (estaca con cartel en la cabecera de la fila): Plantar (eliges semilla; si no la
--     tienes, se compra al momento), Regar (una vez; si llueve se riega solo), Cosechar.
--     "Arrancar" (mantener) deja el bancal vacío (p. ej. para quitar un árbol).
--   * CORRAL (abrevadero): "Atender" da de comer a los animales con hambre (pienso, trigo o maíz)
--     y recoge lo que dan cuando está listo.
--   * COOPERATIVA (puesto delante del granero de cada granja): semillas, árboles, animales y pienso;
--     compra todo lo del campo; y el OBRADOR (molino, horno, quesería, almazara, conservas,
--     exprimidor y telar) para fabricar alimentos.
--   * SUPERMERCADOS: en el almacén, "Entregar productos del campo": pagan más que la cooperativa y
--     ponen en sus estanterías lo que venden (frutas, verduras, huevos, leche, queso, pan…).
--   * La COCINA (platos) está en los restaurantes y cafeterías de los jugadores (BusinessService
--     llama a FarmService.openKitchen).
--
-- Para el cliente: atributos FarmLevel y FarmXp; paneles por el Remote "Farm" (EconomyUI).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Farming = require(ReplicatedStorage.Shared.Farming)
local Groceries = require(ReplicatedStorage.Shared.Groceries)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local SupermarketService = require(script.Parent.SupermarketService)

local FarmService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent

-- Reloj (las pruebas lo cambian para que las cosechas crezcan al momento)
FarmService._clock = function(): number
	return os.time()
end
local function now(): number
	return FarmService._clock()
end

type Finca = {
	Id: number,
	Farm: Model,
	Rows: { BasePart }, -- 4 bancales
	Corral: BasePart,
	Front: Vector3, -- hacia la cabecera de las filas
	Ground: number,
	Stakes: { BasePart },
	Trough: BasePart,
	Sign: BasePart,
	SignLabel: TextLabel,
	Owner: Player?,
	Visual: Folder,
	Plants: { [number]: string }, -- lo que se ve en cada bancal (para no rehacerlo si no cambia)
	Herd: string,
}

local fincas: { Finca } = {}
local fincaOf: { [Player]: Finca } = {}
local coops: { BasePart } = {}
local stations: { [Player]: { List: { string }, Part: BasePart } } = {}
local lastRequest: { [Player]: number } = {}
local folder: Folder

local REACH = 22 -- distancia para usar la cooperativa, el obrador o tu finca

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function nameOf(player: Player): string
	return if player.DisplayName and player.DisplayName ~= "" then player.DisplayName else player.Name
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function near(player: Player, part: BasePart?, distance: number?): boolean
	local root = rootOf(player)
	return root ~= nil and part ~= nil and (root.Position - part.Position).Magnitude <= (distance or REACH)
end

local function canFarm(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	if type(stage) == "string" and Stages.isValid(stage) and not Stages.inRange(stage, Farming.MinStage, nil) then
		Notify:FireClient(player, "Info", "Todavía eres muy pequeño para trabajar en el campo. 🍼")
		return false
	end
	return true
end

local function duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return ("%d h %d min"):format(seconds // 3600, (seconds % 3600) // 60)
	elseif seconds >= 60 then
		local s = seconds % 60
		return if s > 0 then ("%d min %d s"):format(seconds // 60, s) else ("%d min"):format(seconds // 60)
	end
	return ("%d s"):format(seconds)
end

local function itemName(id: string): string
	local item = Items.get(id)
	return if item then item.Icon .. " " .. item.Name else id
end

---------------------------------------------------------------------
-- Datos del jugador
---------------------------------------------------------------------
type FarmData = { Xp: number, Has: boolean?, Plots: { [string]: any }, Animals: { any } }

local function farmData(player: Player): FarmData?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local fd = data.Farm
	if type(fd) ~= "table" then
		fd = {}
		data.Farm = fd
	end
	fd.Xp = if type(fd.Xp) == "number" then fd.Xp else 0
	fd.Plots = if type(fd.Plots) == "table" then fd.Plots else {}
	fd.Animals = if type(fd.Animals) == "table" then fd.Animals else {}
	return fd
end

local function levelOf(player: Player): number
	local fd = farmData(player)
	return Farming.levelFor(if fd then fd.Xp else 0)
end

local function syncLevel(player: Player)
	local fd = farmData(player)
	if fd then
		player:SetAttribute("FarmLevel", Farming.levelFor(fd.Xp))
		player:SetAttribute("FarmXp", fd.Xp)
	end
end

local function addXp(player: Player, xp: number)
	local fd = farmData(player)
	if not fd or xp <= 0 then
		return
	end
	local before = Farming.levelFor(fd.Xp)
	fd.Xp += xp
	local after = Farming.levelFor(fd.Xp)
	syncLevel(player)
	if after > before then
		local unlocked = {}
		for _, c in Farming.Crops do
			if c.Level > before and c.Level <= after then
				table.insert(unlocked, c.Icon .. " " .. c.Name)
			end
		end
		for _, a in Farming.Animals do
			if a.Level > before and a.Level <= after then
				table.insert(unlocked, a.Icon .. " " .. a.Name)
			end
		end
		for _, r in Farming.Recipes do
			if r.Level > before and r.Level <= after and r.Station ~= "Cocina" then
				table.insert(unlocked, itemName(r.Output))
			end
		end
		local extra = if #unlocked > 0 then " Nuevo: " .. table.concat(unlocked, ", ") .. "." else ""
		Notify:FireClient(player, "Success", ("🌾 ¡Nivel %d de agricultor!%s"):format(after, extra))
	end
end

local function plotOf(player: Player, index: number): Farming.PlotState?
	local fd = farmData(player)
	local plot = fd and fd.Plots[tostring(index)]
	return if type(plot) == "table" and Farming.cropById[plot.Crop] then plot else nil
end

local function setPlot(player: Player, index: number, plot: Farming.PlotState?)
	local fd = farmData(player)
	if fd then
		fd.Plots[tostring(index)] = plot
	end
end

-- Mete en la mochila; si no cabe todo, no mete nada
local function give(player: Player, id: string, count: number): boolean
	if count <= 0 then
		return true
	end
	return InventoryService.add(player, id, count)
end

---------------------------------------------------------------------
-- Lo que se ve: plantas, animales y carteles
---------------------------------------------------------------------
local function rowPoint(finca: Finca, row: BasePart, t: number, height: number): Vector3
	-- t = 0 en la cabecera, 1 al fondo
	local len = row.Size.Z
	local p = row.Position + finca.Front * (len / 2 - 3 - t * (len - 6))
	return Vector3.new(p.X, finca.Ground + height, p.Z)
end

local function stageOf(plot: Farming.PlotState?): (string, number)
	if not plot then
		return "Empty", 0
	end
	local phase = Farming.plotPhase(plot, now())
	if phase == "Ready" then
		return "Ready", 4
	end
	return "Growing", math.clamp(math.floor(Farming.growth(plot, now()) * 4), 0, 3)
end

local STEM = Color3.fromRGB(70, 150, 60)
local TRUNK = Color3.fromRGB(110, 80, 50)

local function drawPlants(finca: Finca, index: number, plot: Farming.PlotState?)
	local stage, step = stageOf(plot)
	local signature = if plot then ("%s:%s:%d:%s"):format(plot.Crop, stage, step, tostring(plot.Watered)) else "Empty"
	if finca.Plants[index] == signature then
		return
	end
	finca.Plants[index] = signature
	local old = finca.Visual:FindFirstChild("Plot" .. index)
	if old then
		old:Destroy()
	end
	local row = finca.Rows[index]
	-- Tierra húmeda si está regado
	row.Color = if plot and plot.Watered then Color3.fromRGB(78, 56, 38) else Color3.fromRGB(120, 90, 60)
	row.Material = Enum.Material.Ground
	if not plot then
		return
	end
	local c = Farming.cropById[plot.Crop]
	local m = Instance.new("Folder")
	m.Name = "Plot" .. index
	m.Parent = finca.Visual
	local count = if c.Tree then 3 else 6
	local grow = (step + 1) / 5
	for i = 1, count do
		local base = rowPoint(finca, row, (i - 0.5) / count, 0.5)
		if c.Tree then
			local h = 2 + grow * 7
			Builder.decor({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.8, 0.8), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = TRUNK, Material = Enum.Material.Wood, Parent = m })
			local crown = 2 + grow * 5
			Builder.decor({ Name = "Crown", Shape = Enum.PartType.Ball, Size = Vector3.new(crown, crown, crown), CFrame = CFrame.new(base + Vector3.new(0, h + crown * 0.3, 0)), Color = STEM, Material = Enum.Material.LeafyGrass, Parent = m })
			if stage == "Ready" then
				for k = 1, 4 do
					local a = k * math.pi / 2
					Builder.decor({ Name = "Fruit", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(base + Vector3.new(math.cos(a) * crown * 0.45, h + crown * 0.2, math.sin(a) * crown * 0.45)), Color = c.Color, Parent = m })
				end
			end
		else
			local h = 0.4 + grow * 2.2
			Builder.decor({ Name = "Leaves", Size = Vector3.new(1.4 + grow * 1.6, h, 1.4 + grow * 1.6), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)), Color = if step == 0 then Color3.fromRGB(110, 170, 80) else STEM, Material = Enum.Material.LeafyGrass, Parent = m })
			if stage == "Ready" then
				Builder.decor({ Name = "Fruit", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(base + Vector3.new(0, h + 0.5, 0)), Color = c.Color, Parent = m })
			end
		end
	end
end

local function drawHerd(finca: Finca, animals: { any })
	local parts = {}
	for _, a in animals do
		table.insert(parts, a.Kind)
	end
	local signature = table.concat(parts, ",")
	if finca.Herd == signature then
		return
	end
	finca.Herd = signature
	local old = finca.Visual:FindFirstChild("Herd")
	if old then
		old:Destroy()
	end
	if #animals == 0 then
		return
	end
	local m = Instance.new("Folder")
	m.Name = "Herd"
	m.Parent = finca.Visual
	for i, a in animals do
		local def = Farming.animalById[a.Kind]
		if def then
			local base = rowPoint(finca, finca.Corral, (i - 0.5) / math.max(#animals, 4), 0.5)
			local yaw = CFrame.Angles(0, (i * 2.4) % (math.pi * 2), 0)
			local body = CFrame.new(base + Vector3.new(0, def.Size.Y / 2, 0)) * yaw
			Builder.decor({ Name = def.Id, Size = def.Size, CFrame = body, Color = def.Color, Material = Enum.Material.Fabric, Parent = m })
			if def.Id ~= "Colmena" then
				local head = math.min(def.Size.X, def.Size.Y) * 0.7
				Builder.decor({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(head, head, head), CFrame = body * CFrame.new(0, def.Size.Y * 0.35, -def.Size.Z / 2), Color = def.Color, Material = Enum.Material.Fabric, Parent = m })
			end
			if def.Id == "Vaca" then
				Builder.decor({ Name = "Spot", Size = Vector3.new(def.Size.X + 0.05, 1, 1.4), CFrame = body * CFrame.new(0, 0.3, 0.6), Color = Color3.fromRGB(40, 40, 44), Parent = m })
			end
		end
	end
end

local function plotLabel(index: number, plot: Farming.PlotState?): string
	if not plot then
		return ("Bancal %d · vacío"):format(index)
	end
	local c = Farming.cropById[plot.Crop]
	if Farming.plotPhase(plot, now()) == "Ready" then
		return ("Bancal %d · %s %s ¡listo!"):format(index, c.Icon, c.Name)
	end
	return ("Bancal %d · %s %s · %s%s"):format(index, c.Icon, c.Name, duration(plot.ReadyAt - now()), if plot.Watered then " 💧" else "")
end

local function refreshFinca(finca: Finca)
	local owner = finca.Owner
	if not owner then
		finca.SignLabel.Text = "FINCA LIBRE"
		finca.Sign.Color = Color3.fromRGB(60, 120, 60)
		for i, stake in finca.Stakes do
			local p = stake:FindFirstChild("PlotPrompt") :: ProximityPrompt
			p.ActionText = "Finca libre"
			p.ObjectText = ("Bancal %d"):format(i)
			local r = stake:FindFirstChild("ClearPrompt") :: ProximityPrompt
			r.Enabled = false
			drawPlants(finca, i, nil)
		end
		local tp = finca.Trough:FindFirstChild("TroughPrompt") :: ProximityPrompt
		tp.ObjectText = "Corral"
		drawHerd(finca, {})
		local sp = finca.Sign:FindFirstChild("SignPrompt") :: ProximityPrompt
		sp.ActionText = "Quedarme esta finca"
		sp.Enabled = true
		return
	end
	finca.SignLabel.Text = ("FINCA DE %s"):format(string.upper(nameOf(owner)))
	finca.Sign.Color = Color3.fromRGB(150, 110, 60)
	local sp = finca.Sign:FindFirstChild("SignPrompt") :: ProximityPrompt
	sp.ActionText = "Mi finca"
	for i, stake in finca.Stakes do
		local plot = plotOf(owner, i)
		local phase = Farming.plotPhase(plot, now())
		local p = stake:FindFirstChild("PlotPrompt") :: ProximityPrompt
		p.ActionText = if phase == "Empty" then "Plantar" elseif phase == "Ready" then "Cosechar" elseif plot and not plot.Watered then "Regar" else "Ver"
		p.ObjectText = plotLabel(i, plot)
		local r = stake:FindFirstChild("ClearPrompt") :: ProximityPrompt
		r.Enabled = plot ~= nil
		drawPlants(finca, i, plot)
	end
	local fd = farmData(owner)
	local animals = if fd then fd.Animals else {}
	local ready, hungry = 0, 0
	for _, a in animals do
		if not a.ReadyAt then
			hungry += 1
		elseif now() >= a.ReadyAt then
			ready += 1
		end
	end
	local tp = finca.Trough:FindFirstChild("TroughPrompt") :: ProximityPrompt
	tp.ObjectText = if #animals == 0 then "Corral vacío (animales en la cooperativa)" else ("Corral · %d animales · %d listos · %d con hambre"):format(#animals, ready, hungry)
	drawHerd(finca, animals)
end

---------------------------------------------------------------------
-- Fincas: coger, soltar
---------------------------------------------------------------------
local function release(player: Player)
	local finca = fincaOf[player]
	if not finca then
		return
	end
	fincaOf[player] = nil
	finca.Owner = nil
	player:SetAttribute("FincaAt", nil)
	refreshFinca(finca)
end

local function assign(player: Player, finca: Finca)
	release(player)
	finca.Owner = player
	fincaOf[player] = finca
	local fd = farmData(player)
	if fd then
		fd.Has = true
	end
	player:SetAttribute("FincaAt", finca.Sign.Position)
	refreshFinca(finca)
end

local function freeFinca(): Finca?
	for _, finca in fincas do
		if not finca.Owner then
			return finca
		end
	end
	return nil
end

local function onSign(player: Player, finca: Finca)
	if finca.Owner == player then
		Notify:FireClient(player, "Info", "🌾 Tu finca: 4 bancales (estacas de cada fila) y el corral (abrevadero). Semillas, animales y obrador en la cooperativa, junto al granero.")
		return
	end
	if finca.Owner then
		Notify:FireClient(player, "Info", ("Esta finca es de %s."):format(nameOf(finca.Owner)))
		return
	end
	if not canFarm(player) then
		return
	end
	local had = fincaOf[player] ~= nil
	assign(player, finca)
	if had then
		Notify:FireClient(player, "Success", "🌾 Te has cambiado a esta finca. Tus cultivos y animales se vienen contigo.")
	else
		Notify:FireClient(player, "Success", "🌾 ¡Esta finca es tuya! Compra semillas en la cooperativa (junto al granero) y planta en los bancales.")
	end
end

---------------------------------------------------------------------
-- Paneles (EconomyUI los dibuja; los botones vuelven por el Remote)
---------------------------------------------------------------------
local function button(text: string, action: string, args: { any }, style: string?, disabled: boolean?): { [string]: any }
	return { Text = text, Action = action, Args = args, Style = style, Disabled = disabled }
end

local function recipeText(r: Farming.Recipe): string
	local parts = {}
	local keys = {}
	for id in r.Inputs do
		table.insert(keys, id)
	end
	table.sort(keys)
	for _, id in keys do
		table.insert(parts, ("%s ×%d"):format(itemName(id), r.Inputs[id]))
	end
	return table.concat(parts, " + ")
end

local function stationRows(player: Player, list: { string }): { any }
	local level = levelOf(player)
	local rows = {}
	local function have(id: string): number
		return InventoryService.count(player, id)
	end
	for _, stationId in list do
		local st = Farming.Stations[stationId]
		table.insert(rows, { Header = ("%s %s"):format(st.Icon, st.Name) })
		for _, r in Farming.Recipes do
			if r.Station == stationId then
				local times = Farming.canMake(r, have)
				local locked = level < r.Level
				local out = Farming.Products[r.Output]
				table.insert(rows, {
					Icon = out.Icon,
					Title = ("%s ×%d"):format(out.Name, r.Count),
					Text = ("Con: %s%s"):format(recipeText(r), if times > 0 then ("  ·  puedes hacer %d"):format(times) else ""),
					Buttons = if locked
						then { button(Farming.lockedText(level, r.Level), "", {}, "Dim", true) }
						else {
							button("Hacer 1", "Make", { r.Id, 1 }, "Accent", times < 1),
							button(("Hacer %d"):format(math.min(math.max(times, 1), 10)), "Make", { r.Id, math.min(times, 10) }, nil, times < 2),
						},
				})
			end
		end
	end
	return rows
end

local function coopPanel(player: Player, tab: string?): { [string]: any }
	tab = tab or "Semillas"
	local level = levelOf(player)
	local fd = farmData(player)
	local rows = {}
	if tab == "Semillas" then
		for _, c in Farming.Crops do
			local seed = Farming.seedItem(c.Id)
			local have = InventoryService.count(player, seed)
			local p = Farming.Products[c.Product]
			local locked = level < c.Level
			table.insert(rows, {
				Icon = c.Icon,
				Title = ("%s · %s"):format(Items.get(seed).Name, Format.money(c.Seed)),
				Text = ("Crece en %s · da %d-%d %s (%s c/u)%s%s"):format(
					duration(c.Grow),
					c.Yield[1],
					c.Yield[2],
					p.Name:lower(),
					Format.money(Farming.sellPrice(c.Product, "Coop")),
					if c.Regrow then (" · árbol: vuelve a dar fruto cada %s"):format(duration(c.Regrow)) else "",
					if have > 0 then (" · tienes %d"):format(have) else ""
				),
				Buttons = if locked
					then { button(Farming.lockedText(level, c.Level), "", {}, "Dim", true) }
					else { button("Comprar 1", "BuySeed", { c.Id, 1 }, "Accent"), button("Comprar 5", "BuySeed", { c.Id, 5 }) },
			})
		end
	elseif tab == "Animales" then
		local count = if fd then #fd.Animals else 0
		local room = Farming.corralSize(level)
		table.insert(rows, { Header = ("🐾 Tu corral: %d/%d animales (más sitio con más nivel)"):format(count, room) })
		table.insert(rows, {
			Icon = "🥣",
			Title = ("Saco de pienso · %s"):format(Format.money(Farming.FeedPrice)),
			Text = ("Cada animal come 1 al atenderlo (también comen trigo o maíz). Tienes %d."):format(InventoryService.count(player, Farming.Feed)),
			Buttons = { button("Comprar 5", "BuyFeed", { 5 }, "Accent"), button("Comprar 20", "BuyFeed", { 20 }) },
		})
		for _, a in Farming.Animals do
			local locked = level < a.Level
			local p = Farming.Products[a.Product]
			table.insert(rows, {
				Icon = a.Icon,
				Title = ("%s · %s"):format(a.Name, Format.money(a.Price)),
				Text = ("Da %d %s cada %s después de comer (%s c/u)."):format(a.Yield, p.Name:lower(), duration(a.Period), Format.money(Farming.sellPrice(a.Product, "Coop"))),
				Buttons = if locked
					then { button(Farming.lockedText(level, a.Level), "", {}, "Dim", true) }
					else { button(if count >= room then "Corral lleno" else "Comprar", "BuyAnimal", { a.Id }, "Accent", count >= room) },
			})
		end
	elseif tab == "Vender" then
		local total = 0
		local mine = {}
		for _, id in Farming.ProductOrder do
			local n = InventoryService.count(player, id)
			if n > 0 then
				table.insert(mine, id)
				total += n * Farming.sellPrice(id, "Coop")
			end
		end
		if #mine == 0 then
			table.insert(rows, { Header = "No llevas nada del campo. ¡A cosechar! 🌾" })
		else
			table.insert(rows, {
				Icon = "💰",
				Title = ("Vender todo · %s"):format(Format.money(total)),
				Text = "En los supermercados pagan un 30 % más (se entrega en el almacén) y en tu propia tienda lo pones al precio que quieras.",
				Buttons = { button("Vender todo", "Sell", { "*" }, "Gold") },
			})
			for _, id in mine do
				local p = Farming.Products[id]
				local n = InventoryService.count(player, id)
				table.insert(rows, {
					Icon = p.Icon,
					Title = ("%s ×%d"):format(p.Name, n),
					Text = ("Cooperativa: %s c/u%s"):format(Format.money(Farming.sellPrice(id, "Coop")), if p.Grocery then (" · supermercado: %s"):format(Format.money(Farming.sellPrice(id, "Super"))) else ""),
					Buttons = { button("Vender 1", "Sell", { id, 1 }), button("Vender todo", "Sell", { id, n }, "Accent") },
				})
			end
		end
	elseif tab == "Obrador" then
		rows = stationRows(player, Farming.Obrador)
	end
	return {
		Remote = "Farm",
		Id = "Coop",
		Title = "🧑‍🌾 Cooperativa agrícola de Villaverde",
		Subtitle = ("Agricultor/a nivel %d · %s"):format(level, Format.money(DataService.get(player) and DataService.get(player).Money or 0)),
		Tabs = { { Id = "Semillas", Text = "🌱 Semillas" }, { Id = "Animales", Text = "🐄 Animales" }, { Id = "Vender", Text = "💰 Vender" }, { Id = "Obrador", Text = "🏭 Obrador" } },
		Tab = tab,
		Rows = rows,
	}
end

local function seedPanel(player: Player, index: number): { [string]: any }
	local level = levelOf(player)
	local rows = {}
	for _, c in Farming.Crops do
		if level >= c.Level then
			local have = InventoryService.count(player, Farming.seedItem(c.Id))
			table.insert(rows, {
				Icon = c.Icon,
				Title = c.Name,
				Text = ("Crece en %s · da %d-%d%s"):format(duration(c.Grow), c.Yield[1], c.Yield[2], if c.Regrow then " · árbol" else ""),
				Buttons = { button(if have > 0 then ("Plantar (tienes %d)"):format(have) else ("Comprar y plantar %s"):format(Format.money(c.Seed)), "Plant", { index, c.Id }, if have > 0 then "Accent" else nil) },
			})
		end
	end
	return {
		Remote = "Farm",
		Id = "Seeds",
		Context = index,
		Title = ("🌱 Plantar en el bancal %d"):format(index),
		Subtitle = "Elige qué plantar. Regar una vez lo acelera.",
		Rows = rows,
	}
end

local function kitchenPanel(player: Player): { [string]: any }
	return {
		Remote = "Farm",
		Id = "Kitchen",
		Title = "🍳 Cocina",
		Subtitle = "Cocina platos con lo que traes del campo y del obrador. Luego ponlos a la venta en tu negocio.",
		Rows = stationRows(player, { "Cocina" }),
	}
end

local function send(player: Player, panel: { [string]: any })
	Remote:FireClient(player, "Panel", panel)
end

---------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------
local function nearestCoop(player: Player): BasePart?
	for _, coop in coops do
		if near(player, coop) then
			return coop
		end
	end
	return nil
end

local function stakeIndex(finca: Finca, stake: BasePart): number?
	return table.find(finca.Stakes, stake)
end

local function plant(player: Player, index: number, cropId: string)
	local finca = fincaOf[player]
	local c = Farming.cropById[cropId]
	if not finca or not c or not finca.Stakes[index] or not near(player, finca.Stakes[index], 30) then
		return
	end
	if plotOf(player, index) then
		Notify:FireClient(player, "Info", "Ese bancal ya tiene algo plantado.")
		return
	end
	if levelOf(player) < c.Level then
		Notify:FireClient(player, "Error", ("Necesitas nivel %d de agricultor para plantar %s."):format(c.Level, c.Name:lower()))
		return
	end
	local seed = Farming.seedItem(c.Id)
	if not InventoryService.remove(player, seed, 1) then
		if not DataService.spend(player, c.Seed) then
			Notify:FireClient(player, "Error", ("No tienes semillas ni %s para comprarlas."):format(Format.money(c.Seed)))
			return
		end
	end
	local plot = Farming.plant(c.Id, now())
	local weather = workspace:GetAttribute("Weather")
	if weather == "Lluvia" or weather == "Tormenta" then
		Farming.water(plot, now())
	end
	setPlot(player, index, plot)
	addXp(player, 1)
	refreshFinca(finca)
	Notify:FireClient(player, "Success", ("🌱 Has plantado %s. Estará en %s.%s"):format(c.Name:lower(), duration(plot.ReadyAt - now()), if plot.Watered then " (la lluvia lo ha regado)" else " Riégalo para que crezca antes."))
end

local function onStake(player: Player, finca: Finca, stake: BasePart)
	local index = stakeIndex(finca, stake)
	if not index then
		return
	end
	if finca.Owner ~= player then
		Notify:FireClient(player, "Info", if finca.Owner then ("Esta finca es de %s."):format(nameOf(finca.Owner)) else "Quédate la finca primero: cartel de la entrada, «Quedarme esta finca».")
		return
	end
	if not canFarm(player) then
		return
	end
	local plot = plotOf(player, index)
	local phase = Farming.plotPhase(plot, now())
	if phase == "Empty" then
		send(player, seedPanel(player, index))
	elseif phase == "Growing" and plot then
		if Farming.water(plot, now()) then
			addXp(player, 1)
			Notify:FireClient(player, "Success", ("💧 Regado. Estará en %s."):format(duration(plot.ReadyAt - now())))
		else
			Notify:FireClient(player, "Info", ("⏳ Le falta %s. Crece aunque no estés."):format(duration(plot.ReadyAt - now())))
		end
		refreshFinca(finca)
	elseif plot then
		local c = Farming.cropById[plot.Crop]
		local amount, rest = Farming.harvest(plot, now(), math.random())
		if not give(player, c.Product, amount) then
			Notify:FireClient(player, "Error", "🎒 No te cabe en la mochila. Vende algo en la cooperativa y vuelve.")
			return
		end
		setPlot(player, index, rest)
		addXp(player, Farming.harvestXp(c, amount))
		StoryEvents.emit(player, "FarmHarvest", { Crop = c.Id, Amount = amount })
		refreshFinca(finca)
		Notify:FireClient(player, "Success", ("%s ¡Cosecha! +%d %s%s"):format(c.Icon, amount, Farming.Products[c.Product].Name:lower(), if rest then (" · el %s volverá a dar fruto en %s"):format(c.Name:lower(), duration(rest.ReadyAt - now())) else ""))
	end
end

local function onClear(player: Player, finca: Finca, stake: BasePart)
	local index = stakeIndex(finca, stake)
	if not index or finca.Owner ~= player or not plotOf(player, index) then
		return
	end
	local c = Farming.cropById[(plotOf(player, index) :: any).Crop]
	setPlot(player, index, nil)
	refreshFinca(finca)
	Notify:FireClient(player, "Info", ("🪓 Has arrancado %s. El bancal está libre."):format(c.Name:lower()))
end

-- Comida para un animal: pienso primero, luego maíz y trigo
local function feedOne(player: Player): boolean
	if InventoryService.remove(player, Farming.Feed, 1) then
		return true
	end
	for _, id in Farming.FeedAlso do
		if InventoryService.remove(player, id, 1) then
			return true
		end
	end
	return false
end

local function onTrough(player: Player, finca: Finca)
	if finca.Owner ~= player then
		Notify:FireClient(player, "Info", if finca.Owner then ("Este corral es de %s."):format(nameOf(finca.Owner)) else "Quédate la finca primero (cartel de la entrada).")
		return
	end
	local fd = farmData(player)
	if not fd or #fd.Animals == 0 then
		Notify:FireClient(player, "Info", "🐔 Tu corral está vacío. Compra animales en la cooperativa, junto al granero.")
		return
	end
	local got: { [string]: number } = {}
	local fed, full, noFeed = 0, false, false
	for _, a in fd.Animals do
		local def = Farming.animalById[a.Kind]
		if def then
			if a.ReadyAt and now() >= a.ReadyAt then
				if give(player, def.Product, def.Yield) then
					got[def.Product] = (got[def.Product] or 0) + def.Yield
					a.ReadyAt = nil
					addXp(player, Farming.animalXp(def))
				else
					full = true
				end
			end
			if not a.ReadyAt then
				if feedOne(player) then
					a.ReadyAt = now() + def.Period
					fed += 1
				else
					noFeed = true
				end
			end
		end
	end
	local parts = {}
	for id, n in got do
		table.insert(parts, ("+%d %s"):format(n, itemName(id)))
	end
	table.sort(parts)
	if #parts > 0 then
		Notify:FireClient(player, "Success", "🧺 " .. table.concat(parts, ", "))
	end
	if fed > 0 then
		Notify:FireClient(player, "Info", ("🥣 Has dado de comer a %d %s."):format(fed, if fed == 1 then "animal" else "animales"))
	end
	if full then
		Notify:FireClient(player, "Error", "🎒 La mochila está llena: no cabe todo lo que dan tus animales.")
	end
	if noFeed then
		Notify:FireClient(player, "Error", "No tienes pienso (ni trigo ni maíz) para darles de comer. Cómpralo en la cooperativa.")
	end
	if #parts == 0 and fed == 0 and not full and not noFeed then
		local soonest = math.huge
		for _, a in fd.Animals do
			if a.ReadyAt then
				soonest = math.min(soonest, a.ReadyAt - now())
			end
		end
		Notify:FireClient(player, "Info", ("⏳ Tus animales ya han comido. Lo próximo estará en %s."):format(duration(soonest)))
	end
	refreshFinca(finca)
end

local function buySeed(player: Player, cropId: string, count: number)
	local c = Farming.cropById[cropId]
	count = math.clamp(math.floor(count), 1, 20)
	if not c or levelOf(player) < c.Level then
		return
	end
	local seed = Farming.seedItem(c.Id)
	if not InventoryService.canAdd(player, seed, count) then
		Notify:FireClient(player, "Error", "🎒 No te caben en la mochila.")
		return
	end
	if not DataService.spend(player, c.Seed * count) then
		Notify:FireClient(player, "Error", ("Necesitas %s."):format(Format.money(c.Seed * count)))
		return
	end
	InventoryService.add(player, seed, count)
	Notify:FireClient(player, "Success", ("🌱 +%d %s"):format(count, Items.get(seed).Name:lower()))
end

local function buyFeed(player: Player, count: number)
	count = math.clamp(math.floor(count), 1, 50)
	if not InventoryService.canAdd(player, Farming.Feed, count) then
		Notify:FireClient(player, "Error", "🎒 No te caben en la mochila.")
		return
	end
	if not DataService.spend(player, Farming.FeedPrice * count) then
		Notify:FireClient(player, "Error", ("Necesitas %s."):format(Format.money(Farming.FeedPrice * count)))
		return
	end
	InventoryService.add(player, Farming.Feed, count)
	Notify:FireClient(player, "Success", ("🥣 +%d sacos de pienso"):format(count))
end

local function buyAnimal(player: Player, animalId: string)
	local def = Farming.animalById[animalId]
	local fd = farmData(player)
	if not def or not fd or levelOf(player) < def.Level then
		return
	end
	if #fd.Animals >= Farming.corralSize(levelOf(player)) then
		Notify:FireClient(player, "Error", "Tu corral está lleno. Sube de nivel para tener más sitio.")
		return
	end
	if not DataService.spend(player, def.Price) then
		Notify:FireClient(player, "Error", ("Necesitas %s."):format(Format.money(def.Price)))
		return
	end
	table.insert(fd.Animals, { Kind = def.Id })
	local finca = fincaOf[player]
	if finca then
		refreshFinca(finca)
	end
	Notify:FireClient(player, "Success", ("%s ¡Tienes una %s nueva! Está en el corral de tu finca: dale de comer en el abrevadero."):format(def.Icon, def.Name:lower()))
	if not finca then
		Notify:FireClient(player, "Info", "Quédate una finca (cartel de la entrada) para ver a tus animales.")
	end
end

-- Vende a la cooperativa: id = "*" (todo) o un producto
local function sellCoop(player: Player, id: string, count: number?)
	local total, sold = 0, 0
	local list = if id == "*" then Farming.ProductOrder else { id }
	for _, pid in list do
		if Farming.Products[pid] then
			local have = InventoryService.count(player, pid)
			local n = if id == "*" then have else math.clamp(math.floor(count or have), 0, have)
			if n > 0 and InventoryService.remove(player, pid, n) then
				total += n * Farming.sellPrice(pid, "Coop")
				sold += n
			end
		end
	end
	if sold == 0 then
		Notify:FireClient(player, "Info", "No llevas nada del campo para vender.")
		return
	end
	DataService.addMoney(player, total, true)
	Notify:FireClient(player, "Money", ("+%s · has vendido %d %s a la cooperativa"):format(Format.money(total), sold, if sold == 1 then "producto" else "productos"))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Agricultor", Pay = total })
end

-- Entrega en el almacén del supermercado: paga más y llena sus estanterías
local function sellSuper(player: Player, point: BasePart)
	if not canFarm(player) then
		return
	end
	local total, sold, shelved = 0, 0, 0
	local others = 0
	for _, pid in Farming.ProductOrder do
		local p = Farming.Products[pid]
		local have = InventoryService.count(player, pid)
		if have > 0 then
			if p.Grocery and Groceries.byId[p.Grocery] and InventoryService.remove(player, pid, have) then
				local room = SupermarketService.fishRoom(point, p.Grocery)
				if room > 0 then
					shelved += SupermarketService.addFish(point, p.Grocery, math.min(room, have))
				end
				total += have * Farming.sellPrice(pid, "Super")
				sold += have
			else
				others += have
			end
		end
	end
	if sold == 0 then
		Notify:FireClient(player, "Info", if others > 0 then "El supermercado solo compra fruta, verdura, huevos, leche, queso, pan y lo que tiene en sus estanterías. Lo demás, a la cooperativa o a tu tienda." else "No llevas productos del campo.")
		return
	end
	DataService.addMoney(player, total, true)
	local data = DataService.get(player)
	if data and data.Stats then
		data.Stats.TasksDone += 1
	end
	Notify:FireClient(player, "Money", ("+%s · el supermercado te ha comprado %d %s%s"):format(Format.money(total), sold, if sold == 1 then "producto" else "productos", if shelved > 0 then (" (%d a sus estanterías)"):format(shelved) else ""))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Agricultor", Pay = total })
end

local function make(player: Player, recipeId: string, times: number)
	local r = Farming.recipeById[recipeId]
	times = math.clamp(math.floor(times), 1, 10)
	if not r then
		return
	end
	-- ¿Estás junto a un sitio con esa máquina?
	local allowed = false
	if r.Station == "Cocina" then
		local ctx = stations[player]
		allowed = ctx ~= nil and table.find(ctx.List, "Cocina") ~= nil and near(player, ctx.Part, 30)
	else
		allowed = nearestCoop(player) ~= nil
	end
	if not allowed then
		Notify:FireClient(player, "Error", if r.Station == "Cocina" then "Hay que cocinar en la cocina de tu restaurante o tu cafetería." else "El obrador está en la cooperativa, junto al granero.")
		return
	end
	if levelOf(player) < r.Level then
		Notify:FireClient(player, "Error", ("Necesitas nivel %d de agricultor para hacer eso."):format(r.Level))
		return
	end
	local function have(id: string): number
		return InventoryService.count(player, id)
	end
	times = math.min(times, Farming.canMake(r, have))
	if times < 1 then
		Notify:FireClient(player, "Error", "Te faltan ingredientes: " .. recipeText(r))
		return
	end
	local out = r.Count * times
	if not InventoryService.canAdd(player, r.Output, out) then
		Notify:FireClient(player, "Error", "🎒 No cabe en la mochila.")
		return
	end
	for id, n in r.Inputs do
		InventoryService.remove(player, id, n * times)
	end
	InventoryService.add(player, r.Output, out)
	addXp(player, Farming.recipeXp(r, times))
	local st = Farming.Stations[r.Station]
	Notify:FireClient(player, "Success", ("%s %s: +%d %s"):format(st.Icon, st.Name, out, itemName(r.Output)))
	StoryEvents.emit(player, "FarmMade", { Recipe = r.Id, Count = out })
end

---------------------------------------------------------------------
-- API para otros servicios
---------------------------------------------------------------------
function FarmService.level(player: Player): number
	return levelOf(player)
end

-- La cocina de un restaurante o cafetería (BusinessService)
function FarmService.openKitchen(player: Player, part: BasePart)
	stations[player] = { List = { "Cocina" }, Part = part }
	send(player, kitchenPanel(player))
end

function FarmService.fincaOf(player: Player): any
	return fincaOf[player]
end

---------------------------------------------------------------------
-- Construcción: fincas y cooperativas en las granjas del mapa
---------------------------------------------------------------------
local function prompt(parent: Instance, action: string, object: string, hold: number?, distance: number?, key: Enum.KeyCode?): ProximityPrompt
	local p = Builder.prompt(parent, action, object, hold)
	p.MaxActivationDistance = distance or 9
	if key then
		p.KeyboardKeyCode = key
	end
	return p
end

local function buildFinca(farm: Model, rows: { BasePart }, front: Vector3, ground: number): Finca
	local id = #fincas + 1
	local visual = Instance.new("Folder")
	visual.Name = "Finca" .. id
	visual.Parent = folder
	local finca: Finca = {
		Id = id,
		Farm = farm,
		Rows = { rows[1], rows[2], rows[3], rows[4] },
		Corral = rows[5],
		Front = front,
		Ground = ground,
		Stakes = {},
		Trough = nil :: any,
		Sign = nil :: any,
		SignLabel = nil :: any,
		Owner = nil,
		Visual = visual,
		Plants = {},
		Herd = "",
	}
	-- Estacas en la cabecera de cada bancal
	for i = 1, 4 do
		local row = rows[i]
		local head = row.Position + front * (row.Size.Z / 2 + 1.2)
		local stake = Builder.part({ Name = "Estaca", Size = Vector3.new(0.4, 3, 0.4), CFrame = CFrame.new(Vector3.new(head.X, ground + 1.5, head.Z)), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, CanCollide = false, Parent = visual })
		local p = prompt(stake, "Plantar", ("Bancal %d"):format(i), 0.2, 9)
		p.Name = "PlotPrompt"
		p.Triggered:Connect(function(player)
			onStake(player, finca, stake)
		end)
		local clear = prompt(stake, "Arrancar", ("Bancal %d"):format(i), 1.2, 7, Enum.KeyCode.R)
		clear.Name = "ClearPrompt"
		clear.Enabled = false
		clear.Triggered:Connect(function(player)
			onClear(player, finca, stake)
		end)
		finca.Stakes[i] = stake
	end
	-- Corral: hierba, valla y abrevadero
	local corral = rows[5]
	corral.Color = Color3.fromRGB(96, 150, 70)
	corral.Material = Enum.Material.Grass
	local right = front:Cross(Vector3.yAxis).Unit
	local len = corral.Size.Z
	for _, side in { -1, 1 } do
		for _, h in { 1.2, 2.4 } do
			local c = corral.Position + right * side * 2.9
			Builder.decor({ Name = "Valla", Size = Vector3.new(0.25, 0.3, len), CFrame = CFrame.lookAt(Vector3.new(c.X, ground + h, c.Z), Vector3.new(c.X, ground + h, c.Z) + front), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, Parent = visual })
		end
	end
	local troughAt = corral.Position + front * (len / 2 - 2)
	local trough = Builder.part({ Name = "Abrevadero", Size = Vector3.new(3.6, 1.2, 1.4), CFrame = CFrame.lookAt(Vector3.new(troughAt.X, ground + 0.6, troughAt.Z), Vector3.new(troughAt.X, ground + 0.6, troughAt.Z) + right), Color = Color3.fromRGB(120, 90, 60), Material = Enum.Material.WoodPlanks, Parent = visual })
	Builder.decor({ Name = "Agua", Size = Vector3.new(3.2, 0.2, 1), CFrame = trough.CFrame * CFrame.new(0, 0.55, 0), Color = Color3.fromRGB(80, 150, 210), Material = Enum.Material.Glass, Transparency = 0.3, Parent = visual })
	local tp = prompt(trough, "Atender animales", "Corral", 0.3, 9)
	tp.Name = "TroughPrompt"
	tp.Triggered:Connect(function(player)
		onTrough(player, finca)
	end)
	finca.Trough = trough
	-- Cartel de la finca, delante del bancal del medio
	local mid = (rows[2].Position + rows[3].Position) / 2 + front * (rows[2].Size.Z / 2 + 5)
	local base = Vector3.new(mid.X, ground, mid.Z)
	Builder.part({ Name = "Poste", Size = Vector3.new(0.4, 5, 0.4), CFrame = CFrame.new(base + Vector3.new(0, 2.5, 0)), Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, CanCollide = false, Parent = visual })
	local sign = Builder.part({ Name = "CartelFinca", Size = Vector3.new(7, 2, 0.3), CFrame = CFrame.lookAt(base + Vector3.new(0, 5, 0), base + Vector3.new(0, 5, 0) + front), Color = Color3.fromRGB(60, 120, 60), Material = Enum.Material.Wood, CanCollide = false, Parent = visual })
	finca.SignLabel = Builder.sign(sign, "FINCA LIBRE", Enum.NormalId.Front)
	local back = Builder.sign(sign, "FINCA", Enum.NormalId.Back)
	back.Text = ("FINCA %d"):format(id)
	local sp = prompt(sign, "Quedarme esta finca", ("🌾 Finca %d · 4 bancales y corral"):format(id), 0.5, 12)
	sp.Name = "SignPrompt"
	sp.Triggered:Connect(function(player)
		onSign(player, finca)
	end)
	finca.Sign = sign
	table.insert(fincas, finca)
	refreshFinca(finca)
	return finca
end

local function buildCoop(farm: Model, front: Vector3, ground: number)
	local barn = farm:FindFirstChild("Granero")
	if not barn or not barn:IsA("Model") then
		return
	end
	local cf, size = barn:GetBoundingBox()
	local right = front:Cross(Vector3.yAxis).Unit
	local extent = (math.abs(cf.RightVector:Dot(front)) * size.X + math.abs(cf.LookVector:Dot(front)) * size.Z) / 2
	local at = cf.Position + front * (extent + 5)
	local base = Vector3.new(at.X, ground, at.Z)
	local face = CFrame.lookAt(base, base + front)
	local m = Builder.model("Cooperativa", folder)
	local counter = Builder.part({ Name = "Mostrador", Size = Vector3.new(12, 3.4, 2.4), CFrame = face * CFrame.new(0, 1.7, 0), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.decor({ Name = "Toldo", Size = Vector3.new(13, 0.3, 5), CFrame = face * CFrame.new(0, 7.6, 0.6) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(40, 120, 60), Material = Enum.Material.Fabric, Parent = m })
	for _, x in { -6, 6 } do
		Builder.part({ Name = "Poste", Size = Vector3.new(0.4, 7.5, 0.4), CFrame = face * CFrame.new(x, 3.75, 2.6), Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, Parent = m })
	end
	local board = Builder.part({ Name = "Rotulo", Size = Vector3.new(12, 1.6, 0.3), CFrame = face * CFrame.new(0, 8.8, 2.8), Color = Color3.fromRGB(40, 120, 60), CanCollide = false, Parent = m })
	Builder.sign(board, "COOPERATIVA AGRÍCOLA", Enum.NormalId.Front)
	for i, box in { Color3.fromRGB(220, 60, 50), Color3.fromRGB(240, 140, 40), Color3.fromRGB(110, 180, 70) } do
		Builder.decor({ Name = "Caja", Size = Vector3.new(2.2, 0.9, 1.4), CFrame = face * CFrame.new(-4 + (i - 1) * 4, 3.85, 0), Color = box, Material = Enum.Material.Fabric, Parent = m })
	end
	-- Tres avisos separados (uno por tecla) para que se vean todos
	local spots = {}
	for i, x in { -4, 0, 4 } do
		spots[i] = Builder.part({ Name = "Punto", Size = Vector3.new(1, 1, 1), CFrame = face * CFrame.new(x, 2, -1.6), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m })
	end
	local shop = prompt(spots[1], "Cooperativa", "🌱 Semillas, animales y pienso", 0.2, 10, Enum.KeyCode.E)
	shop.Triggered:Connect(function(player)
		if canFarm(player) then
			send(player, coopPanel(player, "Semillas"))
		end
	end)
	local workshop = prompt(spots[2], "Obrador", "🏭 Molino, horno, quesería…", 0.2, 10, Enum.KeyCode.F)
	workshop.Triggered:Connect(function(player)
		if canFarm(player) then
			send(player, coopPanel(player, "Obrador"))
		end
	end)
	local sell = prompt(spots[3], "Vender cosecha", "💰 La cooperativa lo compra todo", 0.2, 10, Enum.KeyCode.R)
	sell.Triggered:Connect(function(player)
		if canFarm(player) then
			send(player, coopPanel(player, "Vender"))
		end
	end)
	table.insert(coops, counter)
	pcall(function()
		Npc.create("Npc_Cooperativa", m, face * CFrame.new(0, 3, 2), { Shirt = Color3.fromRGB(60, 120, 60), Pants = Color3.fromRGB(70, 90, 140) })
	end)
	-- La cooperativa en el mapa
	counter:AddTag("FarmCoop")
end

local function setupFarm(farm: Model)
	local rows = {}
	for _, child in farm:GetChildren() do
		if child.Name == "Crop" and child:IsA("BasePart") then
			table.insert(rows, child)
		end
	end
	if #rows < Farming.PlotsPerFinca then
		return
	end
	local across = rows[1].CFrame.RightVector
	local along = rows[1].CFrame.LookVector
	table.sort(rows, function(a, b)
		return a.Position:Dot(across) < b.Position:Dot(across)
	end)
	local center = Vector3.zero
	for _, row in rows do
		center += row.Position
	end
	center /= #rows
	local barn = farm:FindFirstChild("Granero")
	local barnAt = if barn and barn:IsA("Model") then barn:GetPivot().Position else center - along * 50
	local front = along * (if (barnAt - center):Dot(along) >= 0 then 1 else -1)
	front = Vector3.new(front.X, 0, front.Z).Unit
	local ground = rows[1].Position.Y - rows[1].Size.Y / 2
	for i = 1, #rows - Farming.PlotsPerFinca + 1, Farming.PlotsPerFinca do
		buildFinca(farm, { rows[i], rows[i + 1], rows[i + 2], rows[i + 3], rows[i + 4] }, front, ground)
	end
	buildCoop(farm, front, ground)
end

local function setupStockroom(point: Instance)
	if not point:IsA("BasePart") or point:GetAttribute("Index") ~= 1 or point:FindFirstChild("FarmPrompt") then
		return
	end
	local p = prompt(point, "Entregar productos del campo", "🧑‍🌾 Almacén · pagan más que la cooperativa", 0.5, 10, Enum.KeyCode.F)
	p.Name = "FarmPrompt"
	p.Triggered:Connect(function(player)
		sellSuper(player, point)
	end)
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
function FarmService.init()
	Remote = ReplicatedStorage.Remotes:FindFirstChild("Farm") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Farm"
		Remote.Parent = ReplicatedStorage.Remotes
	end
	folder = Instance.new("Folder")
	folder.Name = "Fincas"
	folder.Parent = workspace

	local town = workspace:FindFirstChild("Town")
	for _, d in if town then town:GetDescendants() else {} do
		if d:IsA("Model") and d.Name == "Granja" then
			local ok, err = pcall(setupFarm, d)
			if not ok then
				warn("[Granja] " .. tostring(err))
			end
		end
	end
	for _, point in CollectionService:GetTagged("SuperStock") do
		setupStockroom(point)
	end
	CollectionService:GetInstanceAddedSignal("SuperStock"):Connect(setupStockroom)

	-- Número entero y finito (lo que llega del cliente puede ser NaN o infinito y romper la mochila)
	local function isInt(x: any): boolean
		return type(x) == "number" and x == x and math.abs(x) < 1e9 and x == math.floor(x)
	end

	Remote.OnServerEvent:Connect(function(player, action, a, b, c)
		local t = os.clock()
		if t - (lastRequest[player] or 0) < 0.15 then
			return
		end
		lastRequest[player] = t
		if type(action) ~= "string" then
			return
		end
		if action == "Panel" then
			if a == "Coop" and nearestCoop(player) then
				send(player, coopPanel(player, if type(b) == "string" then b else nil))
			elseif a == "Kitchen" and stations[player] and near(player, stations[player].Part, 30) then
				send(player, kitchenPanel(player))
			elseif a == "Seeds" and isInt(c) then
				send(player, seedPanel(player, c))
			end
			return
		end
		if not canFarm(player) then
			return
		end
		if action == "Plant" and isInt(a) and type(b) == "string" then
			plant(player, math.floor(a), b)
			Remote:FireClient(player, "Close", "Seeds")
		elseif action == "BuySeed" and type(a) == "string" and isInt(b) and nearestCoop(player) then
			buySeed(player, a, b)
			send(player, coopPanel(player, "Semillas"))
		elseif action == "BuyFeed" and isInt(a) and nearestCoop(player) then
			buyFeed(player, a)
			send(player, coopPanel(player, "Animales"))
		elseif action == "BuyAnimal" and type(a) == "string" and nearestCoop(player) then
			buyAnimal(player, a)
			send(player, coopPanel(player, "Animales"))
		elseif action == "Sell" and type(a) == "string" and nearestCoop(player) then
			sellCoop(player, a, if isInt(b) then b else nil)
			send(player, coopPanel(player, "Vender"))
		elseif action == "Make" and type(a) == "string" and isInt(b) then
			make(player, a, b)
			local r = Farming.recipeById[a]
			if r and r.Station == "Cocina" then
				if stations[player] then
					send(player, kitchenPanel(player))
				end
			elseif nearestCoop(player) then
				send(player, coopPanel(player, "Obrador"))
			end
		end
	end)

	DataService.onLoaded(function(player, _data)
		syncLevel(player)
		local fd = farmData(player)
		if fd and fd.Has then
			-- Tenías finca: te damos una libre con lo mismo (si queda alguna)
			local finca = freeFinca()
			if finca then
				assign(player, finca)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		stations[player] = nil
		lastRequest[player] = nil
	end)

	-- Las plantas crecen a la vista; con lluvia se riega todo lo plantado
	task.spawn(function()
		while true do
			task.wait(2)
			local weather = workspace:GetAttribute("Weather")
			local raining = weather == "Lluvia" or weather == "Tormenta"
			for _, finca in fincas do
				local owner = finca.Owner
				if owner then
					-- El riego con lluvia también va dentro del pcall: un error no para las fincas
					local ok, err = pcall(function()
						if raining then
							for i = 1, Farming.Plots do
								local plot = plotOf(owner, i)
								if plot and not plot.Watered then
									Farming.water(plot, now())
								end
							end
						end
						refreshFinca(finca)
					end)
					if not ok then
						warn("[Granja] " .. tostring(err))
					end
				end
			end
		end
	end)
	print(("[Granja] %d fincas y %d cooperativas en Villaverde"):format(#fincas, #coops))
end

return FarmService
