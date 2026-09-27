-- JusticeCity: la "Ciudad de la Justicia", al este de la ciudad junto a la carretera de la rotonda este.
-- Reúne las instituciones del Estado (shared/Institutions):
--
--   [Agencia Tributaria]  [Palacio de Justicia]  [Centro Penitenciario]  [Cuartel del Ejército]
--          (-310)               (-160)                  (+90)                    (+290)
--                         — parada de autobús interurbano en la entrada —
--
-- Etiquetas que usan los servicios:
--   TaxWindow (ventanilla de Hacienda), TreasuryBoard (cartel con lo recaudado)
--   CourtJudge / CourtDock (sitio del juez y del acusado), PrisonArea (zona de la prisión),
--   PrisonCell (celdas), PrisonExit (salida), PrisonWork (+Work: trabajos de los presos)
--   Pickup_<Oficio> / Dropoff_<Oficio> (tareas de Juez, Funcionario, Militar y Hacienda) y JobBoard.
-- No usa math.random: se construye al final sin cambiar el resto del mapa.

local Builder = require(script.Parent.Parent.Builder)
local Building = require(script.Parent.Building)
local Blocks = require(script.Parent.Blocks)
local Props = require(script.Parent.Props)

local JusticeCity = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local FT = Building.FLOOR_TOP

JusticeCity.Rect = { X0 = 2560, X1 = 3340, Z0 = 40, Z1 = 300 }
JusticeCity.Name = "Ciudad de la Justicia"

local STONE = rgb(214, 208, 196)
local DARK = rgb(44, 46, 52)
local STEEL = rgb(150, 156, 164)
local WOOD = rgb(120, 82, 54)
local LIGHT = rgb(236, 238, 242)

type Lot = typeof(Blocks.lot(JusticeCity.Rect, "N"))

local function solid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function bit(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = parent })
end

-- Punto invisible para tareas / sitios (no choca)
local function spot(parent: Instance, name: string, cf: CFrame, tags: { string }, attributes: { [string]: any }?): BasePart
	return Builder.part({
		Name = name,
		Size = V(2, 2, 2),
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Tags = tags,
		Attributes = attributes,
		Parent = parent,
	})
end

local function desk(parent: Instance, cf: CFrame, color: Color3?): BasePart
	local top = solid(parent, "Desk", V(5, 3, 2.6), cf * CFrame.new(0, 1.5, 0), color or WOOD, Enum.Material.Wood)
	bit(parent, "PC", V(1.6, 1.1, 0.15), cf * CFrame.new(0.8, 3.6, 0.8), DARK)
	bit(parent, "PCScreen", V(1.4, 0.9, 0.05), cf * CFrame.new(0.8, 3.6, 0.72), rgb(90, 160, 230), Enum.Material.Neon)
	bit(parent, "Papers", V(1.2, 0.15, 0.9), cf * CFrame.new(-1.3, 3.05, 0), rgb(250, 248, 240))
	bit(parent, "Chair", V(1.8, 2.6, 1.8), cf * CFrame.new(0, 1.3, -2), DARK, Enum.Material.Fabric)
	return top
end

local function cabinet(parent: Instance, cf: CFrame): BasePart
	local c = solid(parent, "Archivo", V(3, 6, 2), cf * CFrame.new(0, 3, 0), STEEL, Enum.Material.Metal)
	for k = 0, 2 do
		bit(parent, "Drawer", V(2.6, 1.4, 0.1), cf * CFrame.new(0, 1.2 + k * 1.8, -1.02), rgb(170, 176, 184), Enum.Material.Metal)
	end
	return c
end

local function flag(parent: Instance, cf: CFrame, colors: { Color3 })
	bit(parent, "FlagPole", V(0.5, 22, 0.5), cf * CFrame.new(0, 11, 0), STEEL, Enum.Material.Metal)
	for i, color in colors do
		bit(parent, "Flag", V(6, 1.2, 0.1), cf * CFrame.new(3.2, 21 - i * 1.2, 0), color, Enum.Material.Fabric)
	end
end

---------------------------------------------------------------------
-- Agencia Tributaria
---------------------------------------------------------------------
local function hacienda(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("AgenciaTributaria", parent)
	local W, D, setback = 54, 36, 24
	local model, at = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(u, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 3, Style = "Moderno", GroundFloor = "Lobby",
		WallColor = rgb(226, 232, 236), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "AGENCIA TRIBUTARIA", SignColor = rgb(30, 90, 110),
	})
	local front, back = -D / 2, D / 2
	-- Ventanilla de atención (presentar la declaración)
	solid(model, "TaxWindow", V(16, 3.6, 2.4), at(0, 1.8, front + 8), rgb(30, 90, 110), nil, { Tags = { "TaxWindow" } })
	bit(model, "WindowGlass", V(16, 3, 0.12), at(0, 5.2, front + 7.4), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
	local sign = bit(model, "WindowSign", V(10, 1.4, 0.15), at(0, 8, front + 8.6), rgb(30, 90, 110))
	Builder.sign(sign, "DECLARACIÓN DE LA RENTA", Enum.NormalId.Front)
	-- Mesas de los técnicos (tramitar) y archivo (recoger expedientes)
	for k = 0, 2 do
		local d = desk(model, at(-W / 2 + 10 + k * 16, 0, back - 8))
		d:AddTag("Dropoff_Hacienda")
	end
	for k = 0, 2 do
		cabinet(model, at(W / 2 - 3, 0, front + 16 + k * 4) * CFrame.Angles(0, math.rad(-90), 0)):AddTag("Pickup_Hacienda")
	end
	-- Cartel de lo recaudado (lo actualiza TaxService)
	local board = solid(model, "TreasuryBoard", V(12, 4, 0.3), at(-W / 4, 7, back - 0.5), rgb(20, 30, 40), nil, { Tags = { "TreasuryBoard" } })
	Builder.sign(board, "TESORO PÚBLICO\n$0 recaudados", Enum.NormalId.Front, rgb(120, 230, 160))
	Props.jobBoard(m, lot.facing(u + W / 2 - 4, setback - 4, FT), "Hacienda", "AGENCIA TRIBUTARIA")
	return m
end

---------------------------------------------------------------------
-- Palacio de Justicia
---------------------------------------------------------------------
local function juzgado(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("PalacioJusticia", parent)
	local W, D, setback = 60, 48, 22
	local model, at = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(u, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Clasico", GroundFloor = "Lobby", GroundHeight = 18,
		WallColor = STONE, Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "PALACIO DE JUSTICIA", SignColor = rgb(90, 30, 40),
	})
	local front, back = -D / 2, D / 2
	-- Estrado del juez (elevado) con su mesa, balanza y banderas
	solid(model, "Estrado", V(22, 2, 8), at(0, 1, back - 6), WOOD, Enum.Material.Wood)
	local bench = solid(model, "JudgeBench", V(16, 3.6, 2.4), at(0, 3.8, back - 8.5), rgb(96, 60, 38), Enum.Material.Wood)
	bench:AddTag("Dropoff_Juez")
	spot(model, "JudgeSpot", at(0, 4, back - 5) * CFrame.Angles(0, math.pi, 0), { "CourtJudge" })
	bit(model, "JudgeChair", V(2.4, 5, 2.2), at(0, 4.5, back - 4.2), rgb(90, 30, 40), Enum.Material.Fabric)
	local emblem = bit(model, "Emblem", V(8, 5, 0.2), at(0, 11, back - 0.4), rgb(90, 30, 40))
	Builder.sign(emblem, "⚖\nJUSTICIA", Enum.NormalId.Front, rgb(240, 210, 120))
	flag(model, at(-9, 2, back - 2), { rgb(200, 40, 40), rgb(240, 200, 40), rgb(200, 40, 40) })
	-- Banquillo del acusado (en el centro, de cara al juez) y mesas de las partes
	solid(model, "Banquillo", V(5, 2.2, 2), at(0, 1.1, 2), WOOD, Enum.Material.Wood)
	bit(model, "DockRail", V(6, 0.3, 0.3), at(0, 3.4, 3.2), rgb(96, 60, 38), Enum.Material.Wood)
	spot(model, "DockSpot", at(0, 3, 0.5), { "CourtDock" })
	for _, x in { -12, 12 } do
		bit(model, "PartyTable", V(8, 3, 3), at(x, 1.5, 4), WOOD, Enum.Material.Wood)
		bit(model, "PartyChair", V(1.8, 2.6, 1.8), at(x, 1.3, 1.5), DARK, Enum.Material.Fabric)
	end
	-- Público
	for row = 0, 2 do
		for _, x in { -14, 14 } do
			bit(model, "PublicBench", V(14, 0.5, 1.8), at(x, 1.8, front + 5 + row * 4), WOOD, Enum.Material.Wood)
			bit(model, "PublicBack", V(14, 1.6, 0.3), at(x, 2.8, front + 4.2 + row * 4), WOOD, Enum.Material.Wood)
		end
	end
	-- Archivo de expedientes
	for k = 0, 2 do
		cabinet(model, at(-W / 2 + 3, 0, -4 + k * 4) * CFrame.Angles(0, math.rad(90), 0)):AddTag("Pickup_Juez")
	end
	Props.jobBoard(m, lot.facing(u + W / 2 - 4, setback - 4, FT), "Juez", "JUZGADOS")
	return m
end

---------------------------------------------------------------------
-- Centro Penitenciario
---------------------------------------------------------------------
local function prision(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("CentroPenitenciario", parent)
	local W, v0, v1 = 180, 34, 236
	local D = v1 - v0
	local H = 20
	local wall = rgb(190, 184, 172)
	local center = lot.facing(u, (v0 + v1) / 2, 0)
	local function at(x: number, y: number, z: number): CFrame
		-- x a lo largo, z hacia dentro (z = -D/2 es el muro de la entrada)
		return center * CFrame.new(x, y, z)
	end
	-- Suelo del recinto
	solid(m, "PrisonFloor", V(W, 1, D), at(0, 0, 0), rgb(150, 150, 146), Enum.Material.Concrete)
	-- Muros altos con una puerta en el centro de la fachada
	local gate = 16
	solid(m, "WallBack", V(W, H, 2), at(0, H / 2, D / 2), wall, Enum.Material.Concrete)
	solid(m, "WallLeft", V(2, H, D), at(-W / 2, H / 2, 0), wall, Enum.Material.Concrete)
	solid(m, "WallRight", V(2, H, D), at(W / 2, H / 2, 0), wall, Enum.Material.Concrete)
	local side = (W - gate) / 2
	solid(m, "WallFront", V(side, H, 2), at(-(gate / 2 + side / 2), H / 2, -D / 2), wall, Enum.Material.Concrete)
	solid(m, "WallFront", V(side, H, 2), at(gate / 2 + side / 2, H / 2, -D / 2), wall, Enum.Material.Concrete)
	bit(m, "GateBeam", V(gate + 4, 3, 2.4), at(0, H - 1.5, -D / 2), DARK, Enum.Material.Metal)
	local title = bit(m, "PrisonSign", V(34, 3, 0.4), at(-side / 2 - gate / 2, H - 3, -D / 2 - 1.3), rgb(60, 70, 60))
	Builder.sign(title, "CENTRO PENITENCIARIO DE VALMAR", Enum.NormalId.Front)
	-- Alambre de espino encima
	for _, piece in { { V(W, 1, 1), at(0, H + 0.6, D / 2) }, { V(1, 1, D), at(-W / 2, H + 0.6, 0) }, { V(1, 1, D), at(W / 2, H + 0.6, 0) } } do
		bit(m, "Wire", piece[1], piece[2], rgb(120, 124, 130), Enum.Material.DiamondPlate)
	end
	-- Torres de vigilancia en las esquinas (los funcionarios hacen ronda por ellas)
	for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local base = at(c[1] * (W / 2 - 5), 0, c[2] * (D / 2 - 5))
		solid(m, "TowerLeg", V(3, H + 8, 3), base * CFrame.new(0, (H + 8) / 2, 0), wall, Enum.Material.Concrete)
		bit(m, "TowerCabin", V(9, 5, 9), base * CFrame.new(0, H + 10, 0), rgb(80, 84, 90), Enum.Material.Metal)
		bit(m, "TowerRoof", V(11, 0.6, 11), base * CFrame.new(0, H + 12.8, 0), DARK)
		spot(m, "TowerPost", base * CFrame.new(-c[1] * 6, 3, -c[2] * 6), { "Dropoff_Funcionario" })
	end
	-- Garita del funcionario en la entrada (fuera): recoger llaves / parte del turno
	local booth = at(gate / 2 + 8, 0, -D / 2 - 8)
	solid(m, "Garita", V(8, 9, 7), booth * CFrame.new(0, 4.5, 0), rgb(80, 90, 80), Enum.Material.Concrete)
	local window = solid(m, "GaritaMesa", V(6, 3, 1.2), booth * CFrame.new(0, 1.5, -4.2), DARK, Enum.Material.Metal)
	window:AddTag("Pickup_Funcionario")
	-- Módulo de celdas al fondo, de cara al patio
	local cells = 8
	local cellW, cellD = 12, 12
	local rowZ = D / 2 - 1 - cellD / 2
	for i = 1, cells do
		local x = -W / 2 + 12 + (i - 0.5) * cellW * 1.3
		local cell = at(x, 0, rowZ)
		solid(m, "CellWall", V(0.8, 12, cellD), cell * CFrame.new(-cellW / 2, 6, 0), wall, Enum.Material.Concrete)
		solid(m, "CellWall", V(0.8, 12, cellD), cell * CFrame.new(cellW / 2, 6, 0), wall, Enum.Material.Concrete)
		bit(m, "CellRoof", V(cellW + 0.8, 0.6, cellD), cell * CFrame.new(0, 12.3, 0), wall, Enum.Material.Concrete)
		-- Barrotes (con hueco para entrar: la puerta)
		for k = -5, 5 do
			if math.abs(k) > 1 then
				bit(m, "Bar", V(0.25, 11, 0.25), cell * CFrame.new(k, 5.5, -cellD / 2), STEEL, Enum.Material.Metal)
			end
		end
		bit(m, "Bed", V(3, 1.4, 7), cell * CFrame.new(-cellW / 2 + 2.4, 0.9, 1.5), rgb(200, 200, 205), Enum.Material.Fabric)
		bit(m, "Toilet", V(1.6, 1.6, 1.6), cell * CFrame.new(cellW / 2 - 1.6, 0.8, cellD / 2 - 1.6), LIGHT)
		local number = bit(m, "CellNumber", V(3, 1.2, 0.2), cell * CFrame.new(0, 11, -cellD / 2 - 0.3), DARK)
		Builder.sign(number, "CELDA " .. i, Enum.NormalId.Front)
		spot(m, "CellSpot", cell * CFrame.new(0, 3, 1), { "PrisonCell" }, { Cell = i })
		if i % 2 == 1 then
			spot(m, "CellCheck", cell * CFrame.new(0, 3, -cellD / 2 - 3), { "Dropoff_Funcionario" })
		end
	end
	-- Patio: canasta, bancos y los trabajos de los presos
	bit(m, "Court", V(40, 0.1, 26), at(-W / 4, 0.55, -10), rgb(170, 90, 60), Enum.Material.Concrete)
	bit(m, "HoopPost", V(0.6, 10, 0.6), at(-W / 4 - 19, 5, -10), STEEL, Enum.Material.Metal)
	bit(m, "Backboard", V(0.3, 3.5, 6), at(-W / 4 - 18.6, 10, -10), LIGHT)
	for k = 0, 2 do
		bit(m, "YardBench", V(8, 0.5, 2), at(W / 6 + k * 12, 1.8, -D / 2 + 14), STEEL, Enum.Material.Metal)
	end
	local works = {
		{ Work = "Lavandería", At = at(W / 4, 0, 20), Color = rgb(220, 224, 230) },
		{ Work = "Cocina", At = at(W / 4 + 24, 0, 20), Color = rgb(190, 190, 196) },
		{ Work = "Limpiar el patio", At = at(0, 0, -D / 2 + 26), Color = rgb(90, 130, 70) },
	}
	for _, w in works do
		solid(m, "PrisonWork", V(8, 3.4, 3), w.At * CFrame.new(0, 1.7, 0), w.Color, Enum.Material.Metal, { Tags = { "PrisonWork" }, Attributes = { Work = w.Work } })
		local label = bit(m, "WorkSign", V(8, 1.2, 0.2), w.At * CFrame.new(0, 5, -1.6), DARK)
		Builder.sign(label, string.upper(w.Work), Enum.NormalId.Front)
	end
	-- Zona de la prisión (para saber quién está dentro) y salida
	spot(m, "PrisonArea", at(0, 10, 0), { "PrisonArea" }).Size = V(W - 2, 40, D - 2)
	spot(m, "PrisonExit", at(0, 3, -D / 2 - 12) * CFrame.Angles(0, math.pi, 0), { "PrisonExit" })
	Props.jobBoard(m, lot.facing(u - gate / 2 - 10, v0 - 8, FT), "Funcionario", "PRISIONES")
	return m
end

---------------------------------------------------------------------
-- Cuartel del Ejército
---------------------------------------------------------------------
local function tank(parent: Instance, cf: CFrame)
	local green = rgb(78, 92, 56)
	bit(parent, "TankHull", V(10, 3, 16), cf * CFrame.new(0, 2.5, 0), green, Enum.Material.Metal)
	for _, x in { -5.4, 5.4 } do
		bit(parent, "Track", V(2, 2.6, 17), cf * CFrame.new(x, 1.3, 0), DARK, Enum.Material.DiamondPlate)
	end
	bit(parent, "Turret", V(6.5, 2.6, 7), cf * CFrame.new(0, 5.3, 1), green, Enum.Material.Metal)
	bit(parent, "Barrel", V(0.8, 0.8, 11), cf * CFrame.new(0, 5.6, -7.5), green, Enum.Material.Metal)
end

local function jeep(parent: Instance, cf: CFrame)
	local green = rgb(96, 110, 70)
	bit(parent, "JeepBody", V(6, 2.6, 11), cf * CFrame.new(0, 2.4, 0), green, Enum.Material.Metal)
	bit(parent, "JeepHood", V(6, 1, 4), cf * CFrame.new(0, 4, -3.5), green, Enum.Material.Metal)
	bit(parent, "JeepScreen", V(5.6, 2, 0.2), cf * CFrame.new(0, 4.8, -1.4), rgb(80, 120, 150), Enum.Material.Glass, 0.4)
	for _, p in { { -3, -3.5 }, { 3, -3.5 }, { -3, 3.5 }, { 3, 3.5 } } do
		local wheel = bit(parent, "Wheel", V(1.2, 2.6, 2.6), cf * CFrame.new(p[1], 1.3, p[2]), DARK)
		wheel.Shape = Enum.PartType.Cylinder
	end
end

local function cuartel(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("CuartelEjercito", parent)
	local W, v0, v1 = 170, 34, 236
	local D = v1 - v0
	local center = lot.facing(u, (v0 + v1) / 2, 0)
	local function at(x: number, y: number, z: number): CFrame
		return center * CFrame.new(x, y, z)
	end
	solid(m, "BaseFloor", V(W, 1, D), at(0, 0, 0), rgb(160, 150, 120), Enum.Material.Ground)
	-- Valla con puerta y barrera
	local gate = 18
	local fence = rgb(110, 116, 110)
	local function fenceRun(size: Vector3, cf: CFrame)
		bit(m, "Fence", size, cf, fence, Enum.Material.ForceField, 0.3)
		solid(m, "FenceSolid", V(size.X, size.Y, size.Z), cf, fence, nil, { Transparency = 1 })
	end
	fenceRun(V(W, 8, 0.4), at(0, 4, D / 2))
	fenceRun(V(0.4, 8, D), at(-W / 2, 4, 0))
	fenceRun(V(0.4, 8, D), at(W / 2, 4, 0))
	local side = (W - gate) / 2
	fenceRun(V(side, 8, 0.4), at(-(gate / 2 + side / 2), 4, -D / 2))
	fenceRun(V(side, 8, 0.4), at(gate / 2 + side / 2, 4, -D / 2))
	bit(m, "Barrier", V(gate - 2, 0.6, 0.6), at(0, 3.4, -D / 2 - 1), rgb(220, 40, 40))
	local sign = bit(m, "BaseSign", V(28, 3, 0.4), at(-gate / 2 - 16, 9, -D / 2 - 0.6), rgb(70, 90, 50))
	Builder.sign(sign, "CUARTEL DEL EJÉRCITO DE VALMAR", Enum.NormalId.Front)
	-- Garitas de guardia en la puerta
	for _, x in { -gate / 2 - 4, gate / 2 + 4 } do
		local post = at(x, 0, -D / 2 + 4)
		bit(m, "Sentry", V(5, 8, 5), post * CFrame.new(0, 4, 0), rgb(70, 90, 50), Enum.Material.Concrete)
		spot(m, "GuardPost", post * CFrame.new(0, 3, -4), { "Dropoff_Militar" })
	end
	-- Edificio principal (cuartel general) y armería
	local _, bat = Building.build({
		Name = "CuartelGeneral", Parent = m, CFrame = at(0, 0, D / 2 - 22),
		Width = 60, Depth = 28, Floors = 2, Style = "Moderno", GroundFloor = "Lobby",
		WallColor = rgb(200, 196, 170), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "CUARTEL GENERAL", SignColor = rgb(70, 90, 50),
	})
	desk(m, bat(12, 0, 4), rgb(90, 80, 60))
	local armory = solid(m, "Armeria", V(12, 3.6, 3), bat(-14, 1.8, -6), rgb(70, 76, 60), Enum.Material.Metal)
	armory:AddTag("Pickup_Militar")
	local armorySign = bit(m, "ArmeriaSign", V(8, 1.2, 0.2), bat(-14, 6, -7.6), DARK)
	Builder.sign(armorySign, "ARMERÍA", Enum.NormalId.Front)
	flag(m, at(0, 0, -D / 2 + 16), { rgb(200, 40, 40), rgb(240, 200, 40), rgb(200, 40, 40) })
	-- Circuito de instrucción: cuatro puestos
	for k, p in { { -W / 3, -20 }, { -W / 3, 30 }, { W / 3, 30 }, { W / 3, -20 } } do
		bit(m, "Pad", V(10, 0.3, 10), at(p[1], 0.65, p[2]), rgb(200, 180, 60))
		spot(m, "TrainingPost", at(p[1], 3, p[2]), { "Dropoff_Militar" }, { Step = k })
		bit(m, "Hurdle", V(8, 2.4, 0.5), at(p[1], 1.2, p[2] + 9), rgb(150, 110, 70), Enum.Material.Wood)
	end
	-- Vehículos
	tank(m, at(W / 2 - 20, 0, -D / 2 + 30))
	jeep(m, at(W / 2 - 20, 0, -D / 2 + 58))
	jeep(m, at(-W / 2 + 18, 0, -D / 2 + 30))
	Props.jobBoard(m, lot.facing(u + gate / 2 + 10, v0 - 8, FT), "Militar", "EJÉRCITO")
	return m
end

---------------------------------------------------------------------
-- Todo el complejo
---------------------------------------------------------------------

-- Quita árboles y matas que hubiera en el terreno (se construye al final)
function JusticeCity.clear(world: Instance)
	local r = JusticeCity.Rect
	local margin = 10
	for _, folderName in { "Naturaleza", "Campo" } do
		local folder = world:FindFirstChild(folderName)
		for _, d in (if folder then folder:GetDescendants() else {}) do
			if d:IsA("BasePart") and d.Parent then
				local p = d.CFrame.Position -- (CFrame: así también funciona al construir el archivo con Lune)
				if p.X > r.X0 - margin and p.X < r.X1 + margin and p.Z > r.Z0 - margin and p.Z < r.Z1 + margin then
					local model = d:FindFirstAncestorOfClass("Model")
					if model and model ~= folder and model.Parent == folder then
						model:Destroy()
					else
						d:Destroy()
					end
				end
			end
		end
	end
end

function JusticeCity.build(world: Instance)
	JusticeCity.clear(world)
	local r = JusticeCity.Rect
	local m = Builder.model("CiudadJusticia", world)
	local lot = Blocks.lot(r, "N")
	-- Explanada
	Builder.part({
		Name = "Explanada",
		Size = V(r.X1 - r.X0, 1, r.Z1 - r.Z0),
		CFrame = CFrame.new((r.X0 + r.X1) / 2, -0.5, (r.Z0 + r.Z1) / 2),
		Color = rgb(196, 192, 184),
		Material = Enum.Material.Pavement,
		CastShadow = false,
		Parent = m,
	})
	-- Arco de entrada con el nombre y parada del autobús interurbano
	local gate = lot.facing(-235, 10, 0)
	for _, x in { -9, 9 } do
		bit(m, "ArchPillar", V(2, 14, 2), gate * CFrame.new(x, 7, 0), STONE, Enum.Material.Marble)
	end
	local arch = bit(m, "ArchSign", V(22, 3, 1), gate * CFrame.new(0, 15, 0), rgb(90, 30, 40), Enum.Material.Marble)
	Builder.sign(arch, "CIUDAD DE LA JUSTICIA", Enum.NormalId.Front, rgb(240, 220, 160))
	Builder.sign(arch, "CIUDAD DE LA JUSTICIA", Enum.NormalId.Back, rgb(240, 220, 160))
	local Region = require(script.Parent.Parent.Region)
	Region.travelStop(m, lot.facing(-80, 8, 0), JusticeCity.Name)

	hacienda(m, lot, -310)
	juzgado(m, lot, -160)
	prision(m, lot, 90)
	cuartel(m, lot, 290)
	return m
end

return JusticeCity
