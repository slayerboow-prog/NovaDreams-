-- Pliegues: las zonas misteriosas de la historia. Cronos lo dice en «El piso 13» (Misiones/Rarezas):
-- «El piso 13 es un pliegue. Aquí se guarda lo que todavía no ha pasado». La Grieta dobla Valmar y en
-- los dobleces quedan sitios que no salen en los mapas. Se construyen al arrancar, LEJOS de la ciudad
-- (como Kit/DreamIsland), con los kits de terror que eligió Sebastián (sin un solo nombre de SCP ni
-- de las Backrooms a la vista, sin sangre):
--
--   Vestíbulo         sala de hormigón con cuatro arcos (uno por pliegue) y la puerta de vuelta a Valmar
--   Pliegue Amarillo  kit «backrooms level 0.01» (13843689263). Lo ronda EL PÁLIDO (malla 14062245022)
--   Pliegue Azul      kit «poolrooms» (17536656565). Lo ronda EL AULLADOR (malla 9879827254)
--   Planta 13         el pasillo en silencio (10491752124) y, al fondo, la escalera sin fin (13583409363,
--                     solo los últimos 70 studs: entera son 755 000 triángulos). Aquí pasa «El piso 13».
--   Valmar Gris       la feria que cerró antes de abrir: noria oxidada (16845477360), cementerio
--                     (522578234), árbol y puerta del Horror Pack (14887624955)
--
-- Cómo se llega: la misión «El piso 13» te sube a la Planta 13 (lugar Piso13 de Locations, con plan B
-- en la biblioteca); y una puerta vieja que no debería estar, en el bosque junto al camping («Abrir la
-- puerta»). Se vuelve por la puerta del vestíbulo (al sitio de donde viniste).
--
-- Las criaturas NO hacen daño: rondan su pliegue y, si te alcanzan, te devuelven al vestíbulo con un
-- aviso. Las mueve el servidor (piezas ancladas; nada de las animaciones ni la IA de sus packs, que
-- eran de otros y mataban). Solo se mueven si hay alguien en su pliegue.
-- Si un kit no carga, su arco lleva a una sala vacía con el cartel y el juego sigue.

local Builder = require(script.Parent.Parent.Builder)
local StoryMarks = require(script.Parent.StoryMarks)

local Pliegues = {}

Pliegues.Origin = Vector3.new(-5600, 1600, 5600)
Pliegues.Assets = {
	Amarillo = 13843689263,
	Azul = 17536656565,
	Pasillo = 10491752124,
	Escalera = 13583409363,
	HorrorPack = 14887624955,
	Noria = 16845477360,
	Cementerio = 522578234,
	Palido = 14062245022,
	Aullador = 9879827254,
}
-- Dónde va cada pliegue (desde el origen; y = 0 es el suelo)
Pliegues.Zones = {
	Amarillo = { Offset = Vector3.new(0, 0, 500), Title = "PLIEGUE AMARILLO", Sub = "Zumbido de fluorescentes. Moqueta húmeda. No hay ventanas.", Color = Color3.fromRGB(230, 200, 80) },
	Azul = { Offset = Vector3.new(500, 0, 0), Title = "PLIEGUE AZUL", Sub = "Piscinas sin nadie. El agua no moja.", Color = Color3.fromRGB(90, 180, 230) },
	Piso13 = { Offset = Vector3.new(-500, 0, 0), Title = "PLANTA 13", Sub = "Silencio. Mucho silencio.", Color = Color3.fromRGB(120, 255, 160) },
	Gris = { Offset = Vector3.new(0, 0, -600), Title = "VALMAR GRIS", Sub = "La feria que cerró antes de abrir.", Color = Color3.fromRGB(170, 170, 176) },
}
Pliegues.Order = { "Amarillo", "Azul", "Piso13", "Gris" }
Pliegues.StairsOffset = Vector3.new(-500, 0, 300)
Pliegues.StairsCrop = 70 -- studs de escalera que se quedan (la de arriba)
Pliegues.MaxParts = { Amarillo = 400, Azul = 400, Pasillo = 60, Escalera = 500, Noria = 200, Cementerio = 700, HorrorPack = 200 }
-- La puerta del bosque (junto al Camping de Districts: -2400, -900)
Pliegues.HiddenDoor = Vector3.new(-2330, 0, -830)
Pliegues.Creatures = {
	{ Id = "Palido", Name = "ElPalido", Zone = "Amarillo", Height = 8.5, Speed = 9, Text = "😶 El Pálido te ha devuelto al vestíbulo. No le mires mucho rato." },
	{ Id = "Aullador", Name = "ElAullador", Zone = "Azul", Height = 7, Speed = 13, Text = "🐺 El Aullador te ha echado del Pliegue Azul." },
}

local rgb = Color3.fromRGB
local V = Vector3.new

type Zone = { Name: string, Origin: Vector3, Lo: Vector3, Hi: Vector3, Spawn: CFrame, Model: Model }
Pliegues.Built = {} :: { [string]: Zone }
Pliegues.VestibuleSpawn = CFrame.new(Pliegues.Origin + V(0, 3, 6))

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function wall(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.part({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.Concrete, Parent = parent })
end

local function sign(parent: Instance, cf: CFrame, w: number, h: number, text: string, color: Color3): BasePart
	local board = Builder.decor({ Name = "Cartel", Size = V(w, h, 0.2), CFrame = cf, Color = rgb(24, 24, 28), Parent = parent })
	Builder.sign(board, text, Enum.NormalId.Front, color)
	return board
end

-- Copia los Texture de las losetas «de pared» del Horror Pack (las imágenes se pueden reutilizar)
function Pliegues.borrowTextures(pack: Instance?, word: string): { Texture }
	local out = {}
	if not pack then
		return out
	end
	for _, d in pack:GetDescendants() do
		if d:IsA("Texture") and d.Parent and string.find(string.lower(d.Parent.Name), word, 1, true) then
			table.insert(out, d)
			if #out >= 3 then
				break
			end
		end
	end
	return out
end

local function dress(part: BasePart, textures: { Texture })
	local t = textures[1]
	if not t then
		return
	end
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local copy = t:Clone()
		copy.Face = face
		copy.Parent = part
	end
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------

-- Vestíbulo: 44 × 44, arcos en las paredes +X, -X, +Z y -Z… la puerta de Valmar en -Z, en medio
function Pliegues.buildVestibule(parent: Instance, textures: { Texture }, door: any?, Arsenal: any?): Model
	local m = Builder.model("Vestibulo", parent)
	local O = Pliegues.Origin
	local S, H = 44, 16
	wall(m, "Suelo", V(S, 1, S), CFrame.new(O + V(0, -0.5, 0)), rgb(70, 70, 72))
	wall(m, "Techo", V(S, 1, S), CFrame.new(O + V(0, H + 0.5, 0)), rgb(40, 40, 42))
	for _, spec in { { V(S, H, 1), V(0, H / 2, S / 2) }, { V(S, H, 1), V(0, H / 2, -S / 2) }, { V(1, H, S), V(S / 2, H / 2, 0) }, { V(1, H, S), V(-S / 2, H / 2, 0) } } do
		dress(wall(m, "Pared", spec[1], CFrame.new(O + spec[2]), rgb(120, 116, 108)), textures)
	end
	local lamp = Builder.decor({ Name = "Fluorescente", Size = V(8, 0.3, 1), CFrame = CFrame.new(O + V(0, H - 0.2, 0)), Color = rgb(230, 240, 220), Material = Enum.Material.Neon, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 0.6
	light.Color = rgb(220, 235, 210)
	light.Parent = lamp
	sign(m, CFrame.new(O + V(0, H - 3, S / 2 - 0.7)) * CFrame.Angles(0, math.pi, 0), 26, 3.4, "LOS PLIEGUES\nDonde la Grieta guarda lo que no cabe en Valmar", rgb(120, 255, 160))
	-- Puerta de vuelta (la del Horror Pack si cargó; si no, una de madera)
	local doorAt = CFrame.new(O + V(0, 0, -S / 2 + 0.6))
	if door and Arsenal then
		Arsenal.place(door, m, doorAt, { Height = 8 }, { Name = "PuertaVuelta" })
	else
		wall(m, "PuertaVuelta", V(4.4, 8, 0.4), doorAt * CFrame.new(0, 4, 0), rgb(96, 64, 40), Enum.Material.Wood)
	end
	local exit = Builder.part({ Name = "SalidaValmar", Size = V(5, 8, 1.6), CFrame = doorAt * CFrame.new(0, 4, 1), Transparency = 1, CanCollide = false, CanQuery = false, Parent = m })
	exit:SetAttribute("PliegueExit", true)
	Builder.prompt(exit, "Volver a Valmar", "Puerta")
	-- Arcos: dos en la pared del fondo y uno a cada lado
	local arches = {
		{ Zone = "Amarillo", At = V(-9, 0, S / 2 - 0.6), Yaw = math.pi },
		{ Zone = "Piso13", At = V(9, 0, S / 2 - 0.6), Yaw = math.pi },
		{ Zone = "Azul", At = V(S / 2 - 0.6, 0, 4), Yaw = -math.pi / 2 },
		{ Zone = "Gris", At = V(-S / 2 + 0.6, 0, 4), Yaw = math.pi / 2 },
	}
	for _, a in arches do
		local z = Pliegues.Zones[a.Zone]
		local cf = CFrame.new(O + a.At) * CFrame.Angles(0, a.Yaw, 0)
		Builder.decor({ Name = "Arco", Size = V(6, 9, 0.3), CFrame = cf * CFrame.new(0, 4.5, 0.3), Color = rgb(10, 10, 12), Parent = m })
		for _, x in { -3.3, 3.3 } do
			Builder.decor({ Name = "MarcoArco", Size = V(0.5, 9.5, 0.5), CFrame = cf * CFrame.new(x, 4.75, 0), Color = z.Color, Material = Enum.Material.Neon, Parent = m })
		end
		Builder.decor({ Name = "MarcoArco", Size = V(7.1, 0.5, 0.5), CFrame = cf * CFrame.new(0, 9.5, 0), Color = z.Color, Material = Enum.Material.Neon, Parent = m })
		sign(m, cf * CFrame.new(0, 11.6, -0.2), 9, 1.6, z.Title, z.Color)
		local portal = Builder.part({ Name = "Arco_" .. a.Zone, Size = V(6, 9, 1.6), CFrame = cf * CFrame.new(0, 4.5, -0.8), Transparency = 1, CanCollide = false, CanQuery = false, Parent = m })
		portal:SetAttribute("PliegueGo", a.Zone)
		Builder.prompt(portal, "Cruzar", z.Title)
	end
	return m
end

-- Caja (en coordenadas del mundo) de un modelo
local function boxOf(model: Instance, Arsenal: any): (Vector3, Vector3)
	local list = Arsenal.partsOf(model)
	if #list == 0 then
		return Vector3.zero, Vector3.zero
	end
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in list do
		local half = p.Size / 2
		local c = p.CFrame.Position
		local r = math.max(half.X, half.Y, half.Z) -- (aprox. con giro: basta para el área de un pliegue)
		lo = lo:Min(c - Vector3.new(r, r, r))
		hi = hi:Max(c + Vector3.new(r, r, r))
	end
	return lo, hi
end

-- Busca un sitio con suelo y aire alrededor (en Roblox; fuera de él, el centro)
function Pliegues.findSpot(lo: Vector3, hi: Vector3, floorY: number, ignore: { Instance }?): Vector3
	local center = Vector3.new((lo.X + hi.X) / 2, floorY, (lo.Z + hi.Z) / 2)
	local ok, found = pcall(function(): Vector3?
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = ignore or {}
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = ignore or {}
		local top = math.min(hi.Y - 1, floorY + 12)
		for ring = 0, 8 do
			local step = ring * 6
			for _, d in { V(0, 0, 0), V(step, 0, 0), V(-step, 0, 0), V(0, 0, step), V(0, 0, -step), V(step, 0, step), V(-step, 0, -step) } do
				local p = center + d
				if p.X > lo.X and p.X < hi.X and p.Z > lo.Z and p.Z < hi.Z then
					local hit = workspace:Raycast(Vector3.new(p.X, top, p.Z), Vector3.new(0, -(top - floorY + 4), 0), params)
					if hit and hit.Position.Y < floorY + 3 then
						local stand = hit.Position + Vector3.new(0, 3, 0)
						local blockers = workspace:GetPartBoundsInBox(CFrame.new(stand), Vector3.new(3, 4.5, 3), overlap)
						local solid = 0
						for _, b in blockers do
							if b.CanCollide then
								solid += 1
							end
						end
						if solid == 0 then
							return hit.Position
						end
					end
				end
			end
		end
		return nil
	end)
	if ok and found then
		return found
	end
	return center
end

-- Pone un kit en su pliegue (pivote = centro de la base en el origen del pliegue). Devuelve la zona.
function Pliegues.buildZone(parent: Instance, name: string, template: any?, Arsenal: any, fit: { [string]: number }?): Zone
	local z = Pliegues.Zones[name]
	local origin = Pliegues.Origin + z.Offset
	local m = Builder.model("Pliegue_" .. name, parent)
	if template then
		Arsenal.place(template, m, CFrame.new(origin), fit or { Scale = 1 }, { Collide = true, Name = "Kit" })
	end
	local lo, hi = boxOf(m, Arsenal)
	if not template or (hi - lo).Magnitude < 1 then
		-- Sala vacía (el kit no cargó): suelo, paredes y cartel
		lo, hi = origin - V(20, 0, 20), origin + V(20, 12, 20)
		wall(m, "Suelo", V(40, 1, 40), CFrame.new(origin + V(0, -0.5, 0)), rgb(60, 60, 64))
		for _, spec in { { V(40, 12, 1), V(0, 6, 20) }, { V(40, 12, 1), V(0, 6, -20) }, { V(1, 12, 40), V(20, 6, 0) }, { V(1, 12, 40), V(-20, 6, 0) } } do
			wall(m, "Pared", spec[1], CFrame.new(origin + spec[2]), rgb(90, 88, 84))
		end
	end
	-- Red de seguridad: si algo del kit tiene un agujero, se cae aquí (invisible)
	Builder.part({ Name = "SueloSeguridad", Size = V(hi.X - lo.X + 40, 1, hi.Z - lo.Z + 40), CFrame = CFrame.new((lo.X + hi.X) / 2, origin.Y - 3, (lo.Z + hi.Z) / 2), Transparency = 1, Parent = m })
	local spot = Pliegues.findSpot(lo, hi, origin.Y, { m:FindFirstChild("SueloSeguridad") :: Instance })
	local zone = { Name = name, Origin = origin, Lo = lo, Hi = hi, Spawn = CFrame.new(spot + V(0, 3, 0)), Model = m }
	-- Puerta de vuelta al vestíbulo, donde apareces
	local back = Builder.part({ Name = "VueltaVestibulo", Size = V(3, 6, 1), CFrame = CFrame.new(spot + V(0, 3, 2.5)), Color = z.Color, Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, CanQuery = false, Parent = m })
	back:SetAttribute("PliegueGo", "Vestibulo")
	Builder.prompt(back, "Volver al vestíbulo", z.Title)
	Pliegues.Built[name] = zone
	return zone
end

-- Recorta la escalera: solo las piezas de los últimos «crop» studs
function Pliegues.cropTop(asset: Instance, crop: number, Arsenal: any): number
	local list = Arsenal.partsOf(asset)
	local top = -math.huge
	for _, p in list do
		top = math.max(top, p.CFrame.Position.Y + p.Size.Y / 2)
	end
	local removed = 0
	for _, p in list do
		if p.CFrame.Position.Y < top - crop then
			p:Destroy()
			removed += 1
		end
	end
	return removed
end

---------------------------------------------------------------------
-- Ir y volver
---------------------------------------------------------------------
local function notify(player: Player, text: string)
	pcall(function()
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("Notify")
		if remote then
			(remote :: RemoteEvent):FireClient(player, "Info", text)
		end
	end)
end

local function teleport(player: Player, cf: CFrame)
	local ok = pcall(function()
		require(script.Parent.Parent.Parent.Services.SceneService).teleportTo(player, cf.Position)
	end)
	if not ok then
		pcall(function()
			player:RequestStreamAroundAsync(cf.Position, 3)
			local character = player.Character
			if character then
				character:PivotTo(cf)
			end
		end)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function Pliegues.inside(pos: Vector3, zone: Zone, margin: number?): boolean
	local e = margin or 4
	return pos.X > zone.Lo.X - e and pos.X < zone.Hi.X + e and pos.Z > zone.Lo.Z - e and pos.Z < zone.Hi.Z + e and pos.Y > zone.Lo.Y - 10 and pos.Y < zone.Hi.Y + 10
end

local function returnPoint(player: Player): Vector3
	local saved = player:GetAttribute("PliegueVuelta")
	if typeof(saved) == "Vector3" then
		return saved
	end
	-- (llegó por la misión del piso 13: a la biblioteca)
	local CollectionService = game:GetService("CollectionService")
	for _, tag in { "Library", "SpawnLocation" } do
		local list = CollectionService:GetTagged(tag)
		if list[1] and list[1]:IsA("BasePart") then
			return (list[1] :: BasePart).Position + V(0, 4, 6)
		end
	end
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		return spawn.Position + V(0, 4, 0)
	end
	return V(0, 60, 0)
end

function Pliegues.go(player: Player, where: string)
	if where == "Vestibulo" then
		teleport(player, Pliegues.VestibuleSpawn)
	elseif where == "Valmar" then
		local target = returnPoint(player)
		player:SetAttribute("PliegueVuelta", nil)
		teleport(player, CFrame.new(target))
	else
		local zone = Pliegues.Built[where]
		if zone then
			teleport(player, zone.Spawn)
			local z = Pliegues.Zones[where]
			if z then
				notify(player, ("%s · %s"):format(z.Title, z.Sub))
			end
		end
	end
end

local function hookPrompts(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Parent then
			local holder = d.Parent :: Instance
			local go = holder:GetAttribute("PliegueGo")
			local exit = holder:GetAttribute("PliegueExit")
			local enter = holder:GetAttribute("PliegueEnter")
			if go or exit or enter then
				d.Triggered:Connect(function(player: Player)
					if enter then
						local root = rootOf(player)
						if root then
							player:SetAttribute("PliegueVuelta", root.Position + V(0, 0, 0))
						end
						notify(player, "🚪 La puerta da a un sitio que no sale en los mapas. Huele a fluorescente.")
						Pliegues.go(player, "Vestibulo")
					elseif exit then
						Pliegues.go(player, "Valmar")
					else
						Pliegues.go(player, go)
					end
				end)
			end
		end
	end
end

-- La puerta del bosque (raycast al suelo; si no hay suelo firme, no se pone)
function Pliegues.hiddenDoor(parent: Instance, door: any?, Arsenal: any): BasePart?
	local base = Pliegues.HiddenDoor
	local ok, hit = pcall(function()
		return workspace:Raycast(Vector3.new(base.X, 800, base.Z), Vector3.new(0, -1200, 0))
	end)
	if not ok or not hit or hit.Material == Enum.Material.Water then
		return nil
	end
	local m = Builder.model("PuertaQueNoDeberiaEstar", parent)
	local cf = CFrame.new(hit.Position) * CFrame.Angles(0, math.rad(35), 0)
	if door then
		Arsenal.place(door, m, cf, { Height = 8 }, { Collide = true, Name = "PuertaVieja" })
	else
		wall(m, "PuertaVieja", V(4.4, 8, 0.4), cf * CFrame.new(0, 4, 0), rgb(80, 60, 44), Enum.Material.Wood)
		wall(m, "Marco", V(5.4, 9, 0.6), cf * CFrame.new(0, 4.5, 0.4), rgb(60, 48, 36), Enum.Material.Wood)
	end
	local prompt = Builder.part({ Name = "EntradaPliegue", Size = V(5, 8, 2), CFrame = cf * CFrame.new(0, 4, 0), Transparency = 1, CanCollide = false, CanQuery = false, Parent = m })
	prompt:SetAttribute("PliegueEnter", true)
	Builder.prompt(prompt, "Abrir la puerta", "Una puerta en medio del bosque", 1)
	return prompt
end

---------------------------------------------------------------------
-- Criaturas (sin daño)
---------------------------------------------------------------------
type Creature = { Model: Model, Parts: { BasePart }, Rel: { CFrame }, Pivot: CFrame, Zone: Zone, Speed: number, Text: string, Goal: Vector3?, Rest: number }

local function makeCreature(model: Model, pivot: CFrame, zone: Zone, spec: any): Creature
	local parts, rel = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(rel, pivot:Inverse() * d.CFrame)
		end
	end
	return { Model = model, Parts = parts, Rel = rel, Pivot = pivot, Zone = zone, Speed = spec.Speed, Text = spec.Text, Goal = nil, Rest = 0 }
end

-- Un paso (dt segundos). players: { { Player, Vector3 } } de los que están en su pliegue.
-- Devuelve el jugador alcanzado (o nil). Pura (se prueba en Lune).
function Pliegues.step(c: Creature, dt: number, players: { { any } }, random: () -> number): any?
	if c.Rest > 0 then
		c.Rest -= dt
		return nil
	end
	local here = c.Pivot.Position
	local floorY = here.Y
	local target: Vector3? = nil
	local victim: any = nil
	local best = 60
	for _, entry in players do
		local pos = entry[2] :: Vector3
		local flat = Vector3.new(pos.X, floorY, pos.Z)
		local d = (flat - here).Magnitude
		if d < best then
			best = d
			target = flat
			victim = entry[1]
		end
	end
	if not target then
		if not c.Goal or (c.Goal - here).Magnitude < 2 then
			local z = c.Zone
			c.Goal = Vector3.new(z.Lo.X + (z.Hi.X - z.Lo.X) * random(), floorY, z.Lo.Z + (z.Hi.Z - z.Lo.Z) * random())
		end
		target = c.Goal
	end
	local delta = (target :: Vector3) - here
	local dist = delta.Magnitude
	if victim and dist < 3.5 then
		c.Rest = 4
		return victim
	end
	if dist > 0.01 then
		local speed = if victim then c.Speed else c.Speed * 0.4
		local move = delta.Unit * math.min(dist, speed * dt)
		local look = delta.Unit
		local right = look:Cross(Vector3.new(0, 1, 0))
		c.Pivot = CFrame.fromMatrix(here + move, right, Vector3.new(0, 1, 0))
		for i, p in c.Parts do
			p.CFrame = c.Pivot * c.Rel[i]
		end
	end
	return nil
end

local function runCreatures(list: { Creature })
	if #list == 0 then
		return
	end
	local Players = game:GetService("Players")
	local rng = Random.new()
	local caught: { [Player]: number } = {}
	local TICK = 0.1
	while true do
		task.wait(TICK)
		for _, c in list do
			local near = {}
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root and Pliegues.inside(root.Position, c.Zone) then
					table.insert(near, { player, root.Position })
				end
			end
			if #near > 0 then
				local victim = Pliegues.step(c, TICK, near, function()
					return rng:NextNumber()
				end)
				if victim and os.clock() - (caught[victim] or 0) > 3 then
					caught[victim] = os.clock()
					notify(victim, c.Text)
					Pliegues.go(victim, "Vestibulo")
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Arranque (lo llama World/UserArsenal con su módulo de ayudas)
---------------------------------------------------------------------
function Pliegues.start(Arsenal: any, getter: ((number) -> Instance?)?)
	if workspace:FindFirstChild("Pliegues") then
		return
	end
	local root = Builder.model("Pliegues", workspace)
	local A = Pliegues.Assets
	local function load(id: number): Instance?
		return Arsenal.fetch(id, getter)
	end
	local function whole(id: number, name: string, opts: { [string]: any }?): any?
		local asset = load(id)
		if not asset then
			return nil
		end
		local ok, t = pcall(Arsenal.wholeTemplate, asset, name, opts)
		return if ok then t else nil
	end

	-- Horror Pack: texturas de pared, la puerta y el árbol (las 72 losetas y su Lighting no)
	local horror = load(A.HorrorPack)
	local textures: { Texture } = {}
	local door, tree = nil, nil
	if horror then
		Arsenal.sanitize(horror, {})
		textures = Pliegues.borrowTextures(horror, "wall")
		for _, d in horror:GetDescendants() do
			if d:IsA("Model") then
				local n = string.lower(d.Name)
				if not door and string.find(n, "door", 1, true) then
					door = Arsenal.wholeTemplate(d:Clone(), "PuertaVieja", {})
				elseif not tree and string.find(n, "tree", 1, true) then
					tree = Arsenal.wholeTemplate(d:Clone(), "ArbolSeco", {})
				end
			end
		end
	end

	Pliegues.buildVestibule(root, textures, door, Arsenal)
	local M = Pliegues.MaxParts
	Pliegues.buildZone(root, "Amarillo", whole(A.Amarillo, "PliegueAmarillo", { MaxParts = M.Amarillo, NoDecals = true }), Arsenal)
	Pliegues.buildZone(root, "Azul", whole(A.Azul, "PliegueAzul", { MaxParts = M.Azul, NoDecals = true }), Arsenal)

	-- Planta 13: pasillo y, aparte, la escalera recortada
	local hall = whole(A.Pasillo, "PasilloPlanta13", { MaxParts = M.Pasillo, NoDecals = true })
	local floor13 = Pliegues.buildZone(root, "Piso13", hall, Arsenal)
	local stairsAsset = load(A.Escalera)
	local stairs = nil
	if stairsAsset then
		Pliegues.cropTop(stairsAsset, Pliegues.StairsCrop, Arsenal)
		local ok, t = pcall(Arsenal.wholeTemplate, stairsAsset, "EscaleraSinFin", { MaxParts = M.Escalera, NoDecals = true })
		stairs = if ok then t else nil
	end
	if stairs then
		local sm = Builder.model("EscaleraSinFin", root)
		local at = Pliegues.Origin + Pliegues.StairsOffset
		Arsenal.place(stairs, sm, CFrame.new(at), { Scale = 1 }, { Collide = true, Name = "Escalera" })
		local lo, hi = boxOf(sm, Arsenal)
		local spot = Pliegues.findSpot(lo, hi, hi.Y - 12, {})
		Builder.part({ Name = "SueloSeguridad", Size = V(hi.X - lo.X + 30, 1, hi.Z - lo.Z + 30), CFrame = CFrame.new((lo.X + hi.X) / 2, lo.Y - 3, (lo.Z + hi.Z) / 2), Transparency = 1, Parent = sm })
		Pliegues.Built.Escalera = { Name = "Escalera", Origin = at, Lo = lo, Hi = hi, Spawn = CFrame.new(spot + V(0, 3, 0)), Model = sm }
		local back = Builder.part({ Name = "VueltaVestibulo", Size = V(3, 6, 1), CFrame = CFrame.new(spot + V(0, 3, 2.5)), Color = rgb(120, 255, 160), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, CanQuery = false, Parent = sm })
		back:SetAttribute("PliegueGo", "Vestibulo")
		Builder.prompt(back, "Volver al vestíbulo", "Escalera sin fin")
		-- Al fondo del pasillo, la puerta de la escalera
		local f = floor13
		local size = f.Hi - f.Lo
		local along = if size.X > size.Z then V(1, 0, 0) else V(0, 0, 1)
		local down = Builder.part({ Name = "PuertaEscalera", Size = V(3, 7, 1), CFrame = CFrame.new(f.Spawn.Position + along * 8 + V(0, 0.5, 0)), Color = rgb(30, 30, 34), Material = Enum.Material.Metal, CanCollide = false, Parent = f.Model })
		down:SetAttribute("PliegueGo", "Escalera")
		Builder.prompt(down, "Bajar la escalera", "Planta 13")
	end
	-- Marca de la historia: «El piso 13» pasa aquí (Locations.Piso13), mirando a lo largo del pasillo
	do
		local f = floor13
		local size = f.Hi - f.Lo
		local look = if size.X > size.Z then V(1, 0, 0) else V(0, 0, 1)
		local center = V((f.Lo.X + f.Hi.X) / 2, f.Origin.Y, (f.Lo.Z + f.Hi.Z) / 2)
		local feet = Pliegues.findSpot(f.Lo, f.Hi, f.Origin.Y, {})
		local at = V(center.X, feet.Y, center.Z)
		StoryMarks.spot(f.Model, "Pliegue_Piso13", CFrame.fromMatrix(at + V(0, 2.5, 0), look:Cross(V(0, 1, 0)), V(0, 1, 0)))
	end

	-- Valmar Gris: suelo propio, noria, cementerio, árboles
	local gris = Pliegues.buildZone(root, "Gris", nil, Arsenal)
	do
		local O = gris.Origin
		local gm = gris.Model
		for _, d in gm:GetChildren() do
			if d.Name == "Pared" or d.Name == "Suelo" then
				d:Destroy()
			end
		end
		wall(gm, "Suelo", V(320, 1, 320), CFrame.new(O + V(0, -0.5, 0)), rgb(70, 72, 66), Enum.Material.Ground)
		for _, spec in { { V(320, 30, 2), V(0, 15, 160) }, { V(320, 30, 2), V(0, 15, -160) }, { V(2, 30, 320), V(160, 15, 0) }, { V(2, 30, 320), V(-160, 15, 0) } } do
			Builder.part({ Name = "Niebla", Size = spec[1], CFrame = CFrame.new(O + spec[2]), Color = rgb(150, 150, 156), Material = Enum.Material.SmoothPlastic, Transparency = 0.15, Parent = gm })
		end
		local wheel = whole(A.Noria, "NoriaAbandonada", { MaxParts = M.Noria, NoDecals = true })
		if wheel then
			Arsenal.place(wheel, gm, CFrame.new(O + V(-60, 0, -70)), { Scale = 1 }, { Collide = true, Name = "NoriaAbandonada" })
		end
		local graves = whole(A.Cementerio, "Cementerio", { MaxParts = M.Cementerio })
		if graves then
			-- (no sabemos su tamaño: como mucho 90 studs de lado)
			local longest = math.max(graves.Size.X, graves.Size.Z)
			Arsenal.place(graves, gm, CFrame.new(O + V(60, 0, 40)), { Scale = math.min(1, 90 / math.max(longest, 1)) }, { Collide = true, Name = "Cementerio" })
		end
		if tree then
			for i, p in { V(20, 0, -30), V(-30, 0, 50), V(90, 0, -60), V(-100, 0, 20) } do
				Arsenal.place(tree, gm, CFrame.new(O + p) * CFrame.Angles(0, i * 1.3, 0), { Height = 18 + i * 2 }, { Collide = true, Name = "ArbolSeco" })
			end
		end
		sign(gm, CFrame.new(gris.Spawn.Position + V(0, 4, -8)), 14, 2.4, "VALMAR GRIS\nLa feria que cerró antes de abrir", rgb(200, 200, 206))
		gris.Lo, gris.Hi = O - V(160, 0, 160), O + V(160, 30, 160)
	end

	-- Criaturas
	local creatures = {}
	for _, spec in Pliegues.Creatures do
		local zone = Pliegues.Built[spec.Zone]
		local t = whole(A[spec.Id], spec.Name, {})
		if t and zone then
			local spot = zone.Spawn.Position + V(0, -3, 0)
			-- (lejos de donde apareces: en la otra punta del pliegue)
			local far = V(zone.Lo.X + (zone.Hi.X - zone.Lo.X) * 0.8, spot.Y, zone.Lo.Z + (zone.Hi.Z - zone.Lo.Z) * 0.8)
			local pivot = CFrame.new(far)
			local model = Arsenal.place(t, zone.Model, pivot, { Height = spec.Height }, { Name = spec.Name })
			model:SetAttribute("Creature", spec.Name)
			table.insert(creatures, makeCreature(model, pivot, zone, spec))
		end
	end

	-- La puerta del bosque
	pcall(Pliegues.hiddenDoor, root, door, Arsenal)
	hookPrompts(root)
	if horror then
		horror:Destroy()
	end
	local zones = 0
	for _ in Pliegues.Built do
		zones += 1
	end
	print(("[Pliegues] %d pliegues, %d criaturas"):format(zones, #creatures))
	task.spawn(runCreatures, creatures)
end

return Pliegues
