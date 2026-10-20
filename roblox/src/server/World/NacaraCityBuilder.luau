-- NacaraCityBuilder: construye la FASE 1 de la civilización de los Hondarios (docs/mar/civilizacion-marina.md)
-- UNA vez en el servidor, después de la plaza de la fase 0 (World/NacaraBuilder). Lo llama
-- Services/SeaCivService. Dónde y qué hay: shared/Sea/Civ.
--
--   * Nácara crece alrededor de la plaza: el Barrio de las Conchas (6 conchas de alquiler con AIRE dentro,
--     suelo seco y una hamaca de kelp que es una cama de verdad), los Jardines de Cultivo (6 bancales del
--     oficio de cultivador/a), la Concha del Consejo (Maresa y sus cinco puertas, una por Corriente), el
--     Paseo de las Perlas-farola (8 perlas del oficio de farolero/a), caminos de perlas, kelp y carteles.
--   * La Burbuja (Talud del Naufragio, ~20 m): la posada de los secos (cúpula con aire y dos camas) y el
--     puesto de Bartolo.
--   * Las marcas invisibles de la historia (StorySpot «Mar_…»: shared/LifeStory/Locations) y los tablones
--     «Trabajar» de los oficios del mar (JobBoard: Services/JobService).
--   * Para el móvil: modelos Atomic (con StreamingEnabled llegan enteros o no llegan), todo anclado, el
--     decorado sin choques ni consultas (CanCollide/CanQuery false: solo el suelo seco, las terrazas y los
--     tablones chocan), pocas luces (Civ.MaxLights, sin sombras: la luz es Neon) y Civ.Budget piezas para
--     todo lo de la fase 1 (la gente la apunta SeaCivService con NacaraCityBuilder.take).
--   * Nada de materiales que cambia World/UserMaterials (mármol, pizarra, arena…): SmoothPlastic, Neon,
--     Glass, Fabric y Salt (el grano blanco del fondo).
-- Etiquetas: SeaAirPocket (atributo Radius: DivingService rellena el aire dentro), NacaraDome, PublicBed
-- (SleepService: «Dormir»), MarHome (atributo HomeKey: SeaCivService pone «Alquilar»), MarLamp (LampId),
-- MarBed (BedId), JobBoard (JobId), StorySpot (SpotId). Atributo NacaraCityReady en workspace al terminar.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local Civ = require(ReplicatedStorage.Shared.Sea.Civ)

local NacaraCityBuilder = {}

NacaraCityBuilder.State = "None"
NacaraCityBuilder.Stats = { Parts = 0, Lights = 0, Models = 0, Fills = 0, Seconds = 0 }

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad
local cos, sin, pi = math.cos, math.sin, math.pi

local NACRE = rgb(218, 214, 234)
local NACRE_WARM = rgb(226, 212, 204)
local NACRE_DARK = rgb(150, 160, 186)
local KELP = rgb(70, 110, 62)
local KELP_DARK = rgb(46, 76, 46)
local PEARL = rgb(236, 244, 255)
local CYAN = rgb(90, 235, 255)
local SAND = rgb(196, 182, 172)
local CURRENTS = { rgb(110, 210, 120), rgb(255, 220, 120), rgb(90, 150, 255), rgb(230, 150, 255), rgb(255, 160, 110) } -- Cultivo, Luz, Guardia, Canto, Viaje

local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local NEON, GLASS, SMOOTH, FABRIC = Enum.Material.Neon, Enum.Material.Glass, Enum.Material.SmoothPlastic, Enum.Material.Fabric

local parts, lights = 0, 0

local function folder(): Folder
	local f = workspace:FindFirstChild("NacaraCiudad")
	if not f then
		f = Instance.new("Folder")
		f.Name = "NacaraCiudad"
		f.Parent = workspace
	end
	return f :: Folder
end
NacaraCityBuilder.folder = folder

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	m.Parent = folder()
	NacaraCityBuilder.Stats.Models += 1
	return m
end

-- La gente (SeaCivService) apunta aquí sus piezas
function NacaraCityBuilder.take(n: number): boolean
	if parts + n > Civ.Budget then
		return false
	end
	parts += n
	NacaraCityBuilder.Stats.Parts = parts
	return true
end

type Spec = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: Enum.Material?, Shape: Enum.PartType?, Collide: boolean?, Transparency: number?, Name: string?, Reflect: number?, Query: boolean? }
local function part(parent: Instance, s: Spec): BasePart?
	if parts >= Civ.Budget - Civ.PeopleReserve then
		return nil
	end
	parts += 1
	local p = Instance.new("Part")
	p.Name = s.Name or "Pieza"
	p.Anchored = true
	p.Size = s.Size
	p.CFrame = s.CFrame
	p.Color = s.Color
	p.Material = s.Material or SMOOTH
	local size = s.Size
	if s.Shape == BALL and (math.abs(size.X - size.Y) > 0.01 or math.abs(size.X - size.Z) > 0.01) then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif s.Shape then
		p.Shape = s.Shape
	end
	p.Reflectance = s.Reflect or 0
	p.CanCollide = s.Collide == true
	p.CanTouch = false
	p.CanQuery = s.Collide == true or s.Query == true
	p.CastShadow = false
	p.Transparency = s.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function light(p: BasePart?, color: Color3, range: number, brightness: number)
	if not p or lights >= Civ.MaxLights then
		return
	end
	lights += 1
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = p
end

local function upright(at: Vector3): CFrame
	return CF(at) * ANG(0, 0, rad(90))
end
local function between(parent: Instance, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?, name: string?): BasePart?
	local d = b - a
	if d.Magnitude < 0.05 then
		return nil
	end
	local cf = CFrame.lookAt((a + b) / 2, b) * ANG(0, rad(90), 0)
	return part(parent, { Name = name or "Tramo", Shape = CYL, Size = V(d.Magnitude, thick, thick), CFrame = cf, Color = color, Material = material })
end

local function label(board: BasePart?, title: string, sub: string?)
	if not board then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local t = Instance.new("TextLabel")
	t.Name = "Titulo"
	t.Size = UDim2.fromScale(1, if sub then 0.58 else 1)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = rgb(235, 250, 255)
	t.Parent = gui
	if sub then
		local s = Instance.new("TextLabel")
		s.Name = "Sub"
		s.Position = UDim2.fromScale(0.04, 0.6)
		s.Size = UDim2.fromScale(0.92, 0.34)
		s.BackgroundTransparency = 1
		s.Text = sub
		s.TextScaled = true
		s.Font = Enum.Font.Gotham
		s.TextColor3 = rgb(150, 230, 245)
		s.Parent = gui
	end
end

-- Un cartel de poste mirando hacia `toward`
local function sign(m: Instance, at: Vector3, toward: Vector3, title: string, sub: string?, height: number?)
	local dir = (toward - at) * V(1, 0, 1)
	dir = if dir.Magnitude > 0.1 then dir.Unit else V(0, 0, -1)
	local cf = CFrame.lookAt(at, at + dir)
	local h = height or 6
	part(m, { Name = "PosteCartel", Shape = CYL, Size = V(h, 0.5, 0.5), CFrame = upright(at + V(0, h / 2, 0)), Color = NACRE_DARK })
	local board = part(m, { Name = "Cartel", Size = V(8, 3, 0.3), CFrame = cf * CF(0, h + 0.8, 0), Color = rgb(18, 34, 62), Collide = true })
	part(m, { Name = "MarcoCartel", Size = V(8.6, 0.28, 0.36), CFrame = cf * CF(0, h + 2.45, 0), Color = CYAN, Material = NEON })
	if board then
		-- (Front de la pieza = −Z del CFrame: mira hacia `toward`)
		board.CFrame = cf * CF(0, h + 0.8, 0)
		label(board, title, sub)
	end
	return board
end

local W = Nacara.toWorld

---------------------------------------------------------------------
-- Terreno: un suelo plano para cada zona (como la plaza) y el aire de las conchas y la posada
---------------------------------------------------------------------
function NacaraCityBuilder.terrain(terrain: any)
	local function count()
		NacaraCityBuilder.Stats.Fills += 1
	end
	for _, a in Civ.Areas do
		if a.Id ~= "Plaza" then
			local c = W(a.X, a.Z, 0)
			terrain:FillCylinder(CF(c + V(0, 12, 0)), 24, a.R + 4, Enum.Material.Water)
			terrain:FillCylinder(CF(c - V(0, 7, 0)), 14, a.R + 4, Enum.Material.Salt)
			count()
			count()
		end
	end
	-- el aire de cada concha (una burbuja; el suelo de debajo se vuelve a poner)
	for _, h in Civ.Homes do
		if (h.Air or 0) > 0 then
			local c = Civ.homePosition(h) - V(0, 1.2, 0)
			terrain:FillBall(c, h.Air, Enum.Material.Air)
			terrain:FillCylinder(CF(c - V(0, 7, 0)), 14, h.Air + 2, Enum.Material.Salt)
			count()
			count()
		end
	end
	-- La Burbuja: el talud se allana un poco y la posada se llena de aire
	local p = Civ.Posada
	local y = Civ.burbujaFloorY()
	local c = V(p.X, y, p.Z)
	terrain:FillCylinder(CF(c + V(0, 12, 0)), 24, p.Radius + 18, Enum.Material.Water)
	terrain:FillCylinder(CF(c - V(0, 7, 0)), 14, p.Radius + 18, Enum.Material.Salt)
	terrain:FillBall(c, p.Air, Enum.Material.Air)
	terrain:FillCylinder(CF(c - V(0, 7, 0)), 14, p.Air + 2, Enum.Material.Salt)
	for _ = 1, 4 do
		count()
	end
end

---------------------------------------------------------------------
-- Una cúpula con aire (concha o posada): suelo seco, membrana de «medusa de vidrio» y costillas
---------------------------------------------------------------------
local function airShell(m: Model, center: Vector3, air: number, tint: Color3, ribs: number, name: string): BasePart?
	part(m, { Name = "SueloSeco", Shape = CYL, Size = V(1.2, (air + 1.2) * 2, (air + 1.2) * 2), CFrame = upright(center + V(0, 0.5, 0)), Color = SAND, Collide = true })
	local membrane = part(m, { Name = "Membrana", Shape = BALL, Size = V(air * 2 + 1.4, air * 2 + 1.4, air * 2 + 1.4), CFrame = CF(center), Color = NACRE:Lerp(tint, 0.35), Material = GLASS, Transparency = 0.72 })
	if membrane then
		CollectionService:AddTag(membrane, "SeaAirPocket")
		CollectionService:AddTag(membrane, "NacaraDome")
		membrane:SetAttribute("Radius", air + 0.5)
		membrane:SetAttribute("Pocket", name)
	end
	part(m, { Name = "AnilloMembrana", Shape = CYL, Size = V(0.2, air * 2 + 1.8, air * 2 + 1.8), CFrame = upright(center + V(0, 1.15, 0)), Color = tint, Material = NEON, Transparency = 0.25 })
	for k = 0, ribs - 1 do
		local a = k / ribs * pi + pi / 8
		local prev: Vector3? = nil
		for i = 0, 3 do
			local e = pi * i / 3
			local q = center + V(cos(a) * cos(e) * (air + 0.6), sin(e) * (air + 0.6), sin(a) * cos(e) * (air + 0.6))
			if prev then
				between(m, prev, q, 0.45, NACRE_WARM, SMOOTH, "Costilla")
			end
			prev = q
		end
	end
	return membrane
end

-- Una hamaca de kelp que es una cama de verdad (PublicBed: «Dormir» y tu punto de reaparición)
local function hammock(m: Model, at: Vector3, yaw: number, key: string): BasePart?
	local cf = CF(at) * ANG(0, yaw, 0)
	for s = -1, 1, 2 do
		part(m, { Name = "PosteHamaca", Shape = CYL, Size = V(3.2, 0.4, 0.4), CFrame = upright((cf * CF(s * 3.1, 1.6, 0)).Position), Color = NACRE_DARK })
	end
	local bed = part(m, { Name = "Hamaca", Size = V(5.2, 0.5, 2.6), CFrame = cf * CF(0, 1.6, 0), Color = rgb(96, 150, 70), Material = FABRIC, Query = true })
	if bed then
		CollectionService:AddTag(bed, "PublicBed")
		bed:SetAttribute("HomeKey", key)
	end
	return bed
end

---------------------------------------------------------------------
-- Barrio de las Conchas (viviendas)
---------------------------------------------------------------------
local function homes(m: Model)
	local area = Civ.AreaById.Conchas
	local center = W(area.X, area.Z, 0)
	for i, h in Civ.Homes do
		if not h.World then
			local c = Civ.homePosition(h) - V(0, 1.2, 0)
			local toCenter = (center - c) * V(1, 0, 1)
			local face = if toCenter.Magnitude > 0.1 then toCenter.Unit else V(0, 0, -1)
			local yaw = math.atan2(-face.X, -face.Z)
			airShell(m, c, h.Air, h.Color, 3, h.Key)
			hammock(m, c - face * 3.2, yaw + pi / 2, h.Key)
			-- mesa de concha y perla-lámpara (Neon)
			part(m, { Name = "Mesa", Shape = CYL, Size = V(0.4, 2.6, 2.6), CFrame = upright(c + face * 2.2 + V(face.Z, 0, -face.X) * 2.6 + V(0, 2.2, 0)), Color = NACRE })
			part(m, { Name = "Lampara", Shape = BALL, Size = V(1.1, 1.1, 1.1), CFrame = CF(c + V(0, h.Air - 1.6, 0)), Color = rgb(255, 230, 190), Material = NEON })
			-- la puerta (arco de luz hacia la calle del barrio) y su número
			local door = c + face * (h.Air + 0.4)
			local doorCf = CFrame.lookAt(door + V(0, 3.2, 0), door + V(0, 3.2, 0) + face)
			part(m, { Name = "ArcoPuerta", Size = V(4.4, 0.4, 0.4), CFrame = doorCf * CF(0, 2.4, 0), Color = h.Color, Material = NEON })
			local board = part(m, { Name = "Numero", Size = V(4.6, 1.3, 0.25), CFrame = doorCf * CF(0, 3.4, 0.1), Color = rgb(18, 34, 62), Query = true })
			if board then
				board.CFrame = CFrame.lookAt(board.CFrame.Position, board.CFrame.Position + face)
				label(board, ("Concha %d"):format(i), "Se alquila")
				CollectionService:AddTag(board, "MarHome")
				board:SetAttribute("HomeKey", h.Key)
			end
		end
	end
	sign(m, W(area.X + 46, area.Z - 6, 0), W(0, 0, 0), "BARRIO DE LAS CONCHAS", "Conchas con aire · se alquilan")
	light(part(m, { Name = "PerlaBarrio", Shape = BALL, Size = V(3, 3, 3), CFrame = CF(center + V(0, 16, 0)), Color = PEARL, Material = NEON }), rgb(200, 230, 255), 50, 1)
	part(m, { Name = "TalloPerla", Shape = CYL, Size = V(15, 0.6, 0.6), CFrame = upright(center + V(0, 7.5, 0)), Color = rgb(190, 170, 210) })
end

---------------------------------------------------------------------
-- Jardines de Cultivo (bancales de algas del oficio)
---------------------------------------------------------------------
local function gardens(m: Model)
	local area = Civ.AreaById.Jardines
	for _, b in Civ.Beds do
		local c = W(b.X, b.Z, 0)
		local bed = part(m, { Name = "Bancal", Size = V(14, 0.8, 9), CFrame = CF(c + V(0, 0.4, 0)), Color = rgb(60, 70, 60), Query = true })
		if bed then
			CollectionService:AddTag(bed, "MarBed")
			bed:SetAttribute("BedId", b.Id)
		end
		part(m, { Name = "BordeBancal", Size = V(14.6, 0.5, 9.6), CFrame = CF(c + V(0, 0.15, 0)), Color = NACRE_DARK })
		for k = -1, 1 do
			part(m, { Name = "Brote", Shape = CYL, Size = V(2.4 + (k + 1) * 0.6, 0.5, 0.5), CFrame = upright(c + V(k * 4, 1.6, (k % 2) * 2 - 1)), Color = rgb(96, 170, 80), Material = FABRIC })
		end
	end
	-- vallas de coral bajitas alrededor
	for i = 0, 5 do
		local a = i / 6 * pi * 2
		part(m, { Name = "Valla", Shape = BALL, Size = V(5, 2.2, 2.2), CFrame = CF(W(area.X + cos(a) * (area.R - 4), area.Z + sin(a) * (area.R - 4), 0.9)) * ANG(0, -a, 0), Color = CURRENTS[1] })
	end
	sign(m, W(area.X - 44, area.Z + 10, 0), W(0, 0, 0), "JARDINES DE CULTIVO", "Corriente del Cultivo · algas y pan de kelp")
end

---------------------------------------------------------------------
-- La Concha del Consejo (cinco puertas, una por Corriente)
---------------------------------------------------------------------
local function council(m: Model)
	local a = Civ.AreaById.Consejo
	local c = W(a.X, a.Z, 0)
	local toPlaza = (Nacara.centerPosition() - c) * V(1, 0, 1)
	local face = toPlaza.Unit
	local yaw = math.atan2(-face.X, -face.Z)
	-- la gran concha: media bola de nácar, abierta hacia la plaza (la espalda y el techo)
	part(m, { Name = "ConchaConsejo", Shape = BALL, Size = V(48, 34, 20), CFrame = CF(c - face * 18 + V(0, 2, 0)) * ANG(0, yaw, 0), Color = NACRE, Reflect = 0.18 })
	-- costillas de vieira por encima
	for i = -3, 3 do
		local ang = yaw + i * 0.34
		local dir = V(-sin(ang), 0, -cos(ang))
		part(m, { Name = "Costilla", Size = V(1.1, 16, 12), CFrame = CF(c - face * 18 - dir * 6 + V(0, 12, 0)) * ANG(0, ang, 0) * ANG(rad(-30), 0, 0), Color = NACRE_WARM, Reflect = 0.18 })
	end
	-- el estrado y las cinco puertas de luz (Cultivo, Luz, Guardia, Canto, Viaje)
	part(m, { Name = "Estrado", Shape = CYL, Size = V(1.2, 30, 30), CFrame = upright(c + V(0, 0.6, 0)), Color = NACRE_DARK, Collide = true })
	part(m, { Name = "AnilloEstrado", Shape = CYL, Size = V(0.16, 31, 31), CFrame = upright(c + V(0, 1.25, 0)), Color = CYAN, Material = NEON, Transparency = 0.2 })
	local side = V(face.Z, 0, -face.X)
	for i = 1, 5 do
		local off = (i - 3) * 6.5
		local at = c + face * 9 + side * off
		local col = CURRENTS[i]
		for s = -1, 1, 2 do
			part(m, { Name = "PilarPuerta", Shape = CYL, Size = V(9, 0.9, 0.9), CFrame = upright(at + side * (s * 2.1) + V(0, 4.5, 0)), Color = NACRE })
		end
		part(m, { Name = "ArcoCorriente", Size = V(0.6, 0.6, 5), CFrame = CFrame.lookAt(at + V(0, 9.2, 0), at + V(0, 9.2, 0) + side), Color = col, Material = NEON })
	end
	-- el sillón de la Guardiana (una concha alta) y la perla del Consejo
	part(m, { Name = "Sillon", Shape = BALL, Size = V(7, 8, 3), CFrame = CF(c - face * 4 + V(0, 4, 0)) * ANG(0, yaw, 0), Color = rgb(200, 190, 230) })
	light(part(m, { Name = "PerlaConsejo", Shape = BALL, Size = V(3.4, 3.4, 3.4), CFrame = CF(c - face * 6 + V(0, 15, 0)), Color = PEARL, Material = NEON }), rgb(210, 230, 255), 50, 1.1)
	sign(m, c + face * 22 + side * 12, c + face * 60, "CONCHA DEL CONSEJO", "Consejo de las Corrientes · Maresa, Guardiana de la Marea")
end

---------------------------------------------------------------------
-- El Paseo de las Perlas-farola (oficio de farolero/a), caminos y kelp
---------------------------------------------------------------------
local function lamps(m: Model)
	for _, l in Civ.Lamps do
		local c = W(l.X, l.Z, 0)
		part(m, { Name = "TalloFarola", Shape = CYL, Size = V(8, 0.55, 0.55), CFrame = upright(c + V(0, 4, 0)), Color = rgb(190, 170, 210) })
		part(m, { Name = "Cuna", Shape = CYL, Size = V(0.4, 2.6, 2.6), CFrame = upright(c + V(0, 8.1, 0)), Color = rgb(190, 170, 210) })
		local pearl = part(m, { Name = "PerlaFarola", Shape = BALL, Size = V(2.2, 2.2, 2.2), CFrame = CF(c + V(0, 9.3, 0)), Color = PEARL, Material = NEON, Query = true })
		if pearl then
			CollectionService:AddTag(pearl, "MarLamp")
			pearl:SetAttribute("LampId", l.Id)
		end
	end
end

local function paths(m: Model)
	-- perlas en el suelo de la plaza a cada zona (para que se vea por dónde se va)
	for _, id in { "Conchas", "Jardines", "Consejo" } do
		local a = Civ.AreaById[id]
		local from, to = W(0, 0, 0), W(a.X, a.Z, 0)
		local dir = (to - from) * V(1, 0, 1)
		local len = dir.Magnitude
		local n = 7
		for i = 1, n do
			local d = Nacara.Clear + 4 + (len - Nacara.Clear - a.R - 6) * (i - 1) / (n - 1)
			local q = from + dir.Unit * d
			part(m, { Name = "PerlaCamino", Shape = CYL, Size = V(0.3, 2.4, 2.4), CFrame = upright(q + V(0, 0.2, 0)), Color = if i % 2 == 0 then CYAN else NACRE, Material = if i % 2 == 0 then NEON else SMOOTH, Transparency = if i % 2 == 0 then 0.2 else 0 })
		end
	end
end

local function kelp(m: Model, cx: number, cz: number, count: number, radius: number, seed: number)
	for i = 0, count - 1 do
		local a = i / count * pi * 2 + seed
		local r = radius * (0.55 + ((i * 37 + seed * 11) % 10) / 22)
		local base = W(cx + cos(a) * r, cz + sin(a) * r, 0)
		local h = 22 + (i * 7) % 14
		local prev = base
		for k = 1, 4 do
			local q = base + V(sin(i + k * 0.9) * 1.4, h * k / 4, cos(i * 1.3 + k) * 1.4)
			between(m, prev, q, 0.85 - k * 0.1, if k % 2 == 0 then KELP else KELP_DARK, FABRIC, "TalloKelp")
			prev = q
		end
		part(m, { Name = "Flotador", Shape = BALL, Size = V(1, 1, 1), CFrame = CF(prev + V(0, 0.5, 0)), Color = rgb(150, 160, 70) })
	end
end

---------------------------------------------------------------------
-- La Burbuja (posada de los secos) y el puesto de Bartolo
---------------------------------------------------------------------
local function burbuja(m: Model)
	local p = Civ.Posada
	local y = Civ.burbujaFloorY()
	local c = V(p.X, y, p.Z)
	airShell(m, c, p.Air, rgb(150, 220, 255), 4, "Posada")
	for _, h in Civ.Homes do
		if h.World then
			hammock(m, V(h.X, y, h.Z), 0, h.Key)
			local board = part(m, { Name = "Numero", Size = V(3.6, 1.1, 0.25), CFrame = CF(V(h.X, y + 5.2, h.Z - 1.8)), Color = rgb(18, 34, 62), Query = true })
			if board then
				board.CFrame = CFrame.lookAt(board.CFrame.Position, board.CFrame.Position + V(0, 0, 1))
				label(board, h.Name:match("^Cama %d") or "Cama", "Se alquila")
				CollectionService:AddTag(board, "MarHome")
				board:SetAttribute("HomeKey", h.Key)
			end
		end
	end
	light(part(m, { Name = "LamparaPosada", Shape = BALL, Size = V(2.6, 2.6, 2.6), CFrame = CF(c + V(0, p.Air - 3.5, 0)), Color = rgb(255, 230, 190), Material = NEON }), rgb(255, 225, 180), 26, 1)
	-- el puesto de Bartolo (fuera, en el agua: los desguaceros respiran agua)
	local stall = CF(V(p.X + 20, y, p.Z + 22)) * ANG(0, rad(-135), 0)
	part(m, { Name = "Mostrador", Size = V(7, 3, 2.2), CFrame = stall * CF(0, 1.5, 0), Color = rgb(120, 100, 80), Collide = true })
	part(m, { Name = "Toldo", Shape = BALL, Size = V(8.5, 0.6, 4.2), CFrame = stall * CF(0, 7.2, 0.8) * ANG(rad(-14), 0, 0), Color = rgb(200, 150, 80) })
	part(m, { Name = "Ancla", Size = V(0.6, 4, 0.6), CFrame = stall * CF(-2.4, 5, 0), Color = rgb(90, 90, 100) })
	part(m, { Name = "Timon", Shape = CYL, Size = V(0.4, 2.4, 2.4), CFrame = stall * CF(1.6, 4.1, 0) * ANG(0, rad(90), 0), Color = rgb(150, 110, 60) })
	part(m, { Name = "Botella", Size = V(0.6, 1.2, 0.6), CFrame = stall * CF(0, 3.6, 0), Color = rgb(120, 230, 170), Material = GLASS, Transparency = 0.3 })
	local board = part(m, { Name = "Rotulo", Size = V(7, 1.1, 0.2), CFrame = stall * CF(0, 5.6, -0.9), Color = rgb(24, 40, 70) })
	if board then
		label(board, "BARTOLO · DESGUACERO", nil)
	end
	sign(m, V(p.X, y, p.Z - 30), V(p.X, y, p.Z - 80), "LA BURBUJA", "Posada de los secos · aquí se respira")
end

---------------------------------------------------------------------
-- La historia (StorySpot «Mar_…») y los tablones de los oficios
---------------------------------------------------------------------
local function storyMarks(m: Model)
	for _, s in Civ.StorySpots do
		local at = Civ.spotPosition(s)
		local p = part(m, { Name = "StorySpot_Mar_" .. s.Id, Size = V(4, 5, 4), CFrame = CF(at + V(0, 2.5, 0)), Color = PEARL, Transparency = 1 })
		if p then
			CollectionService:AddTag(p, "StorySpot")
			p:SetAttribute("SpotId", "Mar_" .. s.Id)
		end
	end
end

local function boards(m: Model)
	local titles = { MarCultivador = { "🌿 TRABAJAR", "Cultivador/a de algas" }, MarFarolero = { "🔆 TRABAJAR", "Farolero/a" } }
	for jobId, b in Civ.Boards do
		local at = W(b.X, b.Z, 0)
		part(m, { Name = "PosteTablon", Shape = CYL, Size = V(4.5, 0.5, 0.5), CFrame = upright(at + V(0, 2.25, 0)), Color = NACRE_DARK })
		local board = part(m, { Name = "TablonTrabajar", Size = V(5, 3, 0.4), CFrame = CFrame.lookAt(at + V(0, 5.6, 0), Nacara.centerPosition() + V(0, 5.6, 0)), Color = rgb(30, 60, 90), Collide = true })
		if board then
			board:SetAttribute("JobId", jobId)
			label(board, titles[jobId][1], titles[jobId][2])
			CollectionService:AddTag(board, "JobBoard")
		end
	end
end

---------------------------------------------------------------------

function NacaraCityBuilder.sites()
	local steps = {
		function()
			homes(model("Nacara_BarrioConchas"))
		end,
		function()
			gardens(model("Nacara_Jardines"))
		end,
		function()
			council(model("Nacara_Consejo"))
		end,
		function()
			lamps(model("Nacara_Farolas"))
		end,
		function()
			local m = model("Nacara_Caminos")
			paths(m)
		end,
		function()
			local m = model("Nacara_KelpNorte")
			kelp(m, 130, -205, 9, 34, 0.7)
			kelp(m, -150, -195, 6, 26, 2.1)
		end,
		function()
			burbuja(model("Burbuja_Posada"))
		end,
		function()
			local m = model("Mar_Historia")
			storyMarks(m)
			boards(m)
		end,
	}
	for _, fn in steps do
		local ok, err = pcall(fn)
		if not ok then
			warn("[NacaraCityBuilder] " .. tostring(err))
		end
	end
	NacaraCityBuilder.Stats.Parts = parts
	NacaraCityBuilder.Stats.Lights = lights
end

function NacaraCityBuilder.build(terrain: any?)
	if NacaraCityBuilder.State ~= "None" then
		return
	end
	NacaraCityBuilder.State = "Building"
	local started = os.clock()
	local ok, err = pcall(NacaraCityBuilder.terrain, terrain or workspace.Terrain)
	if not ok then
		warn("[NacaraCityBuilder] terreno: " .. tostring(err))
	end
	NacaraCityBuilder.sites()
	NacaraCityBuilder.State = "Ready"
	NacaraCityBuilder.Stats.Seconds = os.clock() - started
	workspace:SetAttribute("NacaraCityReady", true)
	print(("[NacaraCityBuilder] Nácara (fase 1) y La Burbuja: %d piezas, %d luces, %d modelos, %.2f s"):format(parts, lights, NacaraCityBuilder.Stats.Models, NacaraCityBuilder.Stats.Seconds))
end

function NacaraCityBuilder._reset()
	parts, lights = 0, 0
	NacaraCityBuilder.State = "None"
	NacaraCityBuilder.Stats = { Parts = 0, Lights = 0, Models = 0, Fills = 0, Seconds = 0 }
end

local _ = Ocean
return NacaraCityBuilder
