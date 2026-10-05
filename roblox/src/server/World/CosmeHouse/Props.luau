-- Props: los cientos de cosas pequeñas de la casa de Cosme (tazas, papeles, tornillos, cables,
-- pósits, componentes, bombillas, ropa, comida, botellas, herramientas e inventos), hechas de piezas
-- reutilizables. Cada una se apoya en cf (local, la cara de arriba de la superficie donde va).
-- Todo es decorado: no choca, no se consulta, sin sombra, y en el nivel gráfico Bajo se esconde
-- (etiqueta CityDetail, la pone Kit.deco).
--
--   Props.make(ctx, parent, kind, cf)        -> una cosa
--   Props.scatter(ctx, parent, rect, y, n, kinds?) -> n cosas al azar sobre una superficie, sin montarse

local Kit = require(script.Parent.Kit)

local Props = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local LIQUIDS = { rgb(120, 255, 140), rgb(90, 200, 255), rgb(255, 90, 200), rgb(255, 200, 60), rgb(180, 120, 255), rgb(255, 120, 80) }
local PAPER = { rgb(250, 248, 240), rgb(240, 236, 220), rgb(255, 250, 230) }
local POSTIT = { rgb(255, 236, 110), rgb(255, 160, 200), rgb(150, 230, 255), rgb(170, 255, 150), rgb(255, 190, 110) }
local BOOKS = { rgb(150, 40, 40), rgb(40, 70, 130), rgb(40, 110, 70), rgb(200, 160, 60), rgb(90, 60, 110), rgb(230, 230, 220), rgb(30, 30, 34), rgb(200, 90, 50), rgb(70, 140, 160) }

local P = {}

P.Mug = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Taza", 0.55, 0.5, cf * CF(0, 0.28, 0), R.pick({ C.White, rgb(200, 60, 50), rgb(60, 90, 150), rgb(250, 200, 60) }), M.SmoothPlastic)
	Kit.deco(ctx, m, "Asa", V(0.12, 0.3, 0.1), cf * CF(0.3, 0.3, 0), C.White)
	Kit.cyl(ctx, m, "Cafe", 0.02, 0.42, cf * CF(0, 0.54, 0), rgb(70, 40, 20))
end

P.Papers = function(ctx, m, cf)
	local R = ctx.Rand
	for i = 1, R.int(2, 4) do
		Kit.deco(ctx, m, "Papel", V(1.1, 0.03, 1.5), cf * CF(R.range(-0.2, 0.2), 0.02 + i * 0.03, R.range(-0.2, 0.2)) * ANG(0, R.range(-0.5, 0.5), 0), R.pick(PAPER))
	end
	Kit.deco(ctx, m, "Garabato", V(0.7, 0.01, 0.08), cf * CF(0, 0.16, 0), rgb(40, 60, 160))
end

P.Book = function(ctx, m, cf)
	local R = ctx.Rand
	for i = 1, R.int(1, 3) do
		Kit.deco(ctx, m, "Libro", V(1, 0.25, 1.4), cf * CF(0, 0.125 + (i - 1) * 0.25, 0) * ANG(0, R.range(-0.3, 0.3), 0), R.pick(BOOKS))
	end
end

P.Bottle = function(ctx, m, cf)
	local R = ctx.Rand
	local c = R.pick(LIQUIDS)
	Kit.cyl(ctx, m, "Botella", 1, 0.45, cf * CF(0, 0.5, 0), c, M.Glass, false, 0.25)
	Kit.cyl(ctx, m, "Cuello", 0.35, 0.18, cf * CF(0, 1.17, 0), c, M.Glass, false, 0.25)
	Kit.deco(ctx, m, "Etiqueta", V(0.47, 0.35, 0.47), cf * CF(0, 0.5, 0), R.pick(PAPER))
end

P.Flask = function(ctx, m, cf)
	local R = ctx.Rand
	local c = R.pick(LIQUIDS)
	Kit.ball(ctx, m, "Matraz", 0.8, cf * CF(0, 0.4, 0), c, M.Neon, 0.35)
	Kit.cyl(ctx, m, "Cuello", 0.5, 0.2, cf * CF(0, 0.95, 0), rgb(220, 240, 250), M.Glass, false, 0.4)
end

P.TestTubes = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.deco(ctx, m, "Gradilla", V(1.6, 0.4, 0.5), cf * CF(0, 0.2, 0), C.Wood, M.Wood)
	for i = -2, 2 do
		Kit.cyl(ctx, m, "Tubo", 0.9, 0.18, cf * CF(i * 0.3, 0.6, 0), R.pick(LIQUIDS), M.Neon, false, 0.3)
	end
end

P.Tool = function(ctx, m, cf)
	local R = ctx.Rand
	local k = R.int(1, 3)
	if k == 1 then -- llave inglesa
		Kit.deco(ctx, m, "Llave", V(0.18, 0.1, 1.4), cf * CF(0, 0.05, 0) * ANG(0, R.range(0, 3), 0), C.Chrome, M.Metal)
		Kit.deco(ctx, m, "Boca", V(0.45, 0.1, 0.3), cf * CF(0, 0.05, 0) * ANG(0, R.range(0, 3), 0) * CF(0, 0, -0.7), C.Chrome, M.Metal)
	elseif k == 2 then -- destornillador
		Kit.deco(ctx, m, "Mango", V(0.25, 0.25, 0.6), cf * CF(0, 0.125, 0), R.pick({ C.Red, C.Yellow, C.Blue }))
		Kit.deco(ctx, m, "Punta", V(0.08, 0.08, 0.7), cf * CF(0, 0.125, -0.65), C.Chrome, M.Metal)
	else -- martillo
		Kit.deco(ctx, m, "Mango", V(0.18, 0.18, 1.2), cf * CF(0, 0.09, 0), C.Wood, M.Wood)
		Kit.deco(ctx, m, "Cabeza", V(0.7, 0.25, 0.25), cf * CF(0, 0.125, -0.6), C.Dark, M.Metal)
	end
end

P.Screws = function(ctx, m, cf)
	local R = ctx.Rand
	for _ = 1, R.int(4, 7) do
		Kit.deco(ctx, m, "Tornillo", V(0.1, 0.1, 0.3), cf * CF(R.range(-0.4, 0.4), 0.05, R.range(-0.4, 0.4)) * ANG(0, R.range(0, 3), 0), C.Chrome, M.Metal)
	end
	Kit.deco(ctx, m, "Tuerca", V(0.2, 0.08, 0.2), cf * CF(0.2, 0.04, -0.3), C.Steel, M.Metal)
end

P.Chip = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.deco(ctx, m, "Placa", V(1.2, 0.06, 0.8), cf * CF(0, 0.03, 0) * ANG(0, R.range(-0.4, 0.4), 0), rgb(40, 120, 60))
	Kit.deco(ctx, m, "Chip", V(0.35, 0.08, 0.35), cf * CF(0.2, 0.1, 0), C.Dark)
	Kit.neon(ctx, m, "Led", V(0.08, 0.08, 0.08), cf * CF(-0.4, 0.1, 0.2), R.pick({ C.Red, C.Green, C.Cyan }))
end

P.Bulb = function(ctx, m, cf)
	Kit.ball(ctx, m, "Bombilla", 0.4, cf * CF(0, 0.32, 0), rgb(255, 245, 200), M.Glass, 0.2)
	Kit.cyl(ctx, m, "Rosca", 0.15, 0.2, cf * CF(0, 0.08, 0), C.Steel, M.Metal)
end

P.Clothes = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.deco(ctx, m, "Ropa", V(1.6, 0.2, 1.2), cf * CF(0, 0.1, 0) * ANG(0, R.range(0, 3), 0), R.pick({ rgb(70, 90, 140), rgb(200, 200, 196), rgb(140, 60, 60), rgb(60, 60, 66) }), M.Fabric)
	Kit.deco(ctx, m, "Manga", V(0.4, 0.15, 0.9), cf * CF(0.7, 0.07, 0.5) * ANG(0, R.range(0, 3), 0), rgb(235, 235, 225), M.Fabric)
end

P.Food = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Plato", 0.08, 1.1, cf * CF(0, 0.04, 0), C.White)
	local k = R.int(1, 3)
	if k == 1 then
		Kit.deco(ctx, m, "LasanaCuadrada", V(0.6, 0.3, 0.6), cf * CF(0, 0.23, 0), rgb(220, 120, 60))
	elseif k == 2 then
		Kit.ball(ctx, m, "Manzana", 0.4, cf * CF(0.1, 0.28, 0), C.Red)
		Kit.ball(ctx, m, "Manzana", 0.4, cf * CF(-0.2, 0.28, 0.1), C.Green)
	else
		Kit.cyl(ctx, m, "BatidoApio", 0.7, 0.35, cf * CF(0.3, 0.43, 0), rgb(130, 220, 90), M.Glass, false, 0.2)
		Kit.deco(ctx, m, "Tostada", V(0.6, 0.12, 0.6), cf * CF(-0.15, 0.14, 0), rgb(220, 170, 100))
	end
end

P.Gadget = function(ctx, m, cf)
	local R = ctx.Rand
	local w = R.range(0.8, 1.4)
	Kit.deco(ctx, m, "Invento", V(w, 0.6, 0.8), cf * CF(0, 0.3, 0) * ANG(0, R.range(-0.5, 0.5), 0), R.pick({ C.Steel, rgb(200, 120, 60), rgb(80, 90, 110) }), M.Metal)
	Kit.neon(ctx, m, "Indicador", V(0.15, 0.15, 0.05), cf * CF(w / 4, 0.4, -0.42), R.pick({ C.Green, C.Red, C.Cyan, C.Magenta }))
	Kit.deco(ctx, m, "Antenita", V(0.05, 0.6, 0.05), cf * CF(-w / 4, 0.9, 0), C.Dark)
	Kit.deco(ctx, m, "Dial", V(0.25, 0.25, 0.08), cf * CF(-0.1, 0.35, -0.42), C.White)
end

P.Battery = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Pila", 0.8, 0.4, cf * CF(0, 0.4, 0), R.pick({ rgb(230, 140, 40), rgb(60, 60, 66) }), M.Metal)
	Kit.cyl(ctx, m, "Polo", 0.1, 0.15, cf * CF(0, 0.85, 0), C.Chrome, M.Metal)
end

P.Plant = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Maceta", 0.8, 0.9, cf * CF(0, 0.4, 0), R.pick({ rgb(200, 110, 70), C.White, C.Dark }), M.SmoothPlastic)
	Kit.ball(ctx, m, "Hojas", 1.2, cf * CF(0, 1.2, 0), rgb(70, 140, 70), M.Grass)
end

P.Jar = function(ctx, m, cf)
	local R = ctx.Rand
	local c = R.pick(LIQUIDS)
	Kit.cyl(ctx, m, "Tarro", 0.9, 0.7, cf * CF(0, 0.45, 0), rgb(220, 240, 250), M.Glass, false, 0.5)
	Kit.cyl(ctx, m, "Contenido", 0.6, 0.55, cf * CF(0, 0.35, 0), c, M.Neon, false, 0.25)
	Kit.cyl(ctx, m, "Tapa", 0.12, 0.72, cf * CF(0, 0.96, 0), C.Steel, M.Metal)
end

P.Clipboard = function(ctx, m, cf)
	Kit.deco(ctx, m, "Tablilla", V(0.9, 0.05, 1.2), cf * CF(0, 0.03, 0) * ANG(0, ctx.Rand.range(-0.4, 0.4), 0), C.Wood, M.Wood)
	Kit.deco(ctx, m, "Hoja", V(0.8, 0.02, 1), cf * CF(0, 0.07, 0.05), PAPER[1])
	Kit.deco(ctx, m, "Pinza", V(0.4, 0.08, 0.12), cf * CF(0, 0.09, -0.52), C.Chrome, M.Metal)
end

P.Coil = function(ctx, m, cf)
	for i = 0, 3 do
		Kit.cyl(ctx, m, "Espira", 0.12, 0.8, cf * CF(0, 0.1 + i * 0.16, 0), rgb(200, 120, 60), M.Metal)
	end
	Kit.cyl(ctx, m, "Nucleo", 0.8, 0.3, cf * CF(0, 0.4, 0), C.Steel, M.Metal)
end

P.Lamp = function(ctx, m, cf)
	Kit.cyl(ctx, m, "Base", 0.12, 0.7, cf * CF(0, 0.06, 0), C.Dark, M.Metal)
	Kit.deco(ctx, m, "Brazo", V(0.08, 1.2, 0.08), cf * CF(0, 0.65, 0) * ANG(0.3, 0, 0), C.Dark)
	Kit.cyl(ctx, m, "Pantalla", 0.35, 0.5, cf * CF(0, 1.2, -0.35), ctx.Rand.pick({ C.Red, C.Cyan, C.Yellow }), M.Metal)
end

P.Keyboard = function(ctx, m, cf)
	Kit.deco(ctx, m, "Teclado", V(1.8, 0.08, 0.6), cf * CF(0, 0.04, 0), C.Dark)
	Kit.neon(ctx, m, "Teclas", V(1.6, 0.02, 0.45), cf * CF(0, 0.09, 0), ctx.Rand.pick({ C.Cyan, C.Magenta, C.Green }), 0.5)
end

P.Blueprint = function(ctx, m, cf)
	local R = ctx.Rand
	if R.chance(0.5) then
		Kit.cylX(ctx, m, "Rollo", 1.6, 0.25, cf * CF(0, 0.125, 0) * ANG(0, R.range(0, 3), 0), rgb(70, 110, 190))
	else
		Kit.deco(ctx, m, "Plano", V(1.8, 0.02, 1.3), cf * CF(0, 0.01, 0) * ANG(0, R.range(-0.4, 0.4), 0), rgb(40, 80, 170))
		Kit.deco(ctx, m, "Linea", V(1.2, 0.01, 0.05), cf * CF(0, 0.03, 0.2), rgb(220, 235, 255))
	end
end

P.Radio = function(ctx, m, cf)
	Kit.deco(ctx, m, "Radio", V(1.2, 0.7, 0.5), cf * CF(0, 0.35, 0), rgb(120, 80, 50), M.Wood)
	Kit.deco(ctx, m, "Altavoz", V(0.5, 0.45, 0.05), cf * CF(-0.25, 0.38, -0.26), C.Dark, M.Fabric)
	Kit.deco(ctx, m, "Antena", V(0.04, 0.9, 0.04), cf * CF(0.4, 1.1, 0) * ANG(0, 0, 0.4), C.Chrome, M.Metal)
end

-- Cosas que van en el suelo
P.Crate = function(ctx, m, cf)
	local R = ctx.Rand
	local s = R.range(1.6, 2.6)
	Kit.box(ctx, m, "Caja", V(s, s * 0.8, s), cf * CF(0, s * 0.4, 0) * ANG(0, R.range(-0.4, 0.4), 0), R.pick({ rgb(170, 130, 80), rgb(150, 110, 70), rgb(120, 130, 140) }), M.WoodPlanks, { CanQuery = false })
	Kit.deco(ctx, m, "Etiqueta", V(s * 0.5, s * 0.25, 0.05), cf * CF(0, s * 0.45, -s / 2 - 0.03), R.pick({ C.Yellow, C.White, C.Red }))
end

P.Barrel = function(ctx, m, cf)
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Bidon", 2.6, 1.8, cf * CF(0, 1.3, 0), R.pick({ rgb(40, 90, 160), rgb(200, 140, 40), rgb(70, 120, 70) }), M.Metal, true)
	Kit.neon(ctx, m, "Simbolo", V(0.6, 0.6, 0.05), cf * CF(0, 1.5, -0.92), R.pick({ C.Yellow, C.Green }), 0.1)
end

P.CableRun = function(ctx, m, cf)
	local R = ctx.Rand
	local c = R.pick({ C.Dark, rgb(200, 60, 50), rgb(40, 90, 200), rgb(240, 200, 50) })
	local x, z = 0, 0
	for _ = 1, R.int(3, 5) do
		local yaw = R.range(0, math.pi * 2)
		local len = R.range(1.5, 3)
		local nx, nz = x + math.sin(yaw) * len, z + math.cos(yaw) * len
		Kit.deco(ctx, m, "Cable", V(0.15, 0.15, len), cf * CF((x + nx) / 2, 0.075, (z + nz) / 2) * ANG(0, yaw, 0), c, M.Rubber)
		x, z = nx, nz
	end
end

P.Pile = function(ctx, m, cf)
	local R = ctx.Rand
	for i = 1, R.int(3, 5) do
		local s = R.range(0.6, 1.2)
		Kit.deco(ctx, m, "Chatarra", V(s, s * 0.6, s * 0.8), cf * CF(R.range(-0.8, 0.8), s * 0.3 + (i % 2) * 0.2, R.range(-0.8, 0.8)) * ANG(R.range(-0.2, 0.2), R.range(0, 3), 0), R.pick({ C.Steel, rgb(120, 110, 100), rgb(160, 90, 50) }), M.CorrodedMetal)
	end
end

Props.Prefabs = P
Props.Small = { "Mug", "Papers", "Book", "Bottle", "Flask", "Tool", "Screws", "Chip", "Bulb", "Gadget", "Battery", "Jar", "Clipboard", "Coil", "Keyboard", "Blueprint" }
Props.Lab = { "Flask", "TestTubes", "Jar", "Chip", "Coil", "Gadget", "Tool", "Screws", "Battery", "Clipboard", "Bulb", "Papers", "Mug" }
Props.Home = { "Mug", "Papers", "Book", "Plant", "Food", "Radio", "Lamp", "Clothes", "Bulb", "Gadget" }
Props.Office = { "Mug", "Papers", "Book", "Clipboard", "Blueprint", "Lamp", "Chip", "Keyboard", "Gadget" }
Props.Floor = { "Crate", "Barrel", "CableRun", "Pile" }

function Props.make(ctx: any, parent: Instance, kind: string, cf: CFrame): Model
	local m = Kit.group(parent, "Prop_" .. kind)
	local fn = P[kind] or P.Gadget
	fn(ctx, m, cf)
	return m
end

-- n cosas al azar sobre una superficie (rect local, cara de arriba a la altura y), sin montarse
function Props.scatter(ctx: any, parent: Instance, rect: { number }, y: number, n: number, kinds: { string }?): number
	local R = ctx.Rand
	local list = kinds or Props.Small
	local used: { [string]: boolean } = {}
	local cell = 1.3
	local made = 0
	for _ = 1, n * 4 do
		if made >= n then
			break
		end
		local x = R.range(rect[1] + 0.6, rect[2] - 0.6)
		local z = R.range(rect[3] + 0.6, rect[4] - 0.6)
		local key = math.floor(x / cell) .. ":" .. math.floor(z / cell)
		if not used[key] then
			used[key] = true
			Props.make(ctx, parent, R.pick(list), CF(x, y, z) * ANG(0, R.range(0, math.pi * 2), 0))
			made += 1
		end
	end
	return made
end

-- Pósits pegados a una superficie vertical (cf en la superficie, mirando hacia fuera = -Z)
function Props.postits(ctx: any, parent: Instance, cf: CFrame, w: number, h: number, n: number)
	local R = ctx.Rand
	for _ = 1, n do
		Kit.deco(ctx, parent, "Postit", V(0.5, 0.5, 0.03), cf * CF(R.range(-w / 2, w / 2), R.range(-h / 2, h / 2), -0.03) * ANG(0, 0, R.range(-0.3, 0.3)), R.pick(POSTIT))
	end
end

-- Fila de libros de pie en una balda (cf en la balda, a lo largo de X)
function Props.bookRow(ctx: any, parent: Instance, cf: CFrame, length: number, depth: number?)
	local R = ctx.Rand
	local x = -length / 2
	while x < length / 2 - 0.3 do
		local w = R.range(0.25, 0.5)
		local h = R.range(1, 1.7)
		if R.chance(0.08) then
			x += w -- hueco
		else
			Kit.deco(ctx, parent, "Libro", V(w, h, depth or 1.2), cf * CF(x + w / 2, h / 2, 0) * ANG(0, 0, if R.chance(0.1) then 0.2 else 0), R.pick(BOOKS))
			x += w + 0.03
		end
	end
end

-- Estantería grande (cf en el suelo, de espaldas a la pared: los libros miran a -Z)
function Props.shelf(ctx: any, parent: Instance, cf: CFrame, w: number, h: number, fill: string?): Model
	local m = Kit.group(parent, "Estanteria")
	local wood = ctx.Wood
	Kit.box(ctx, m, "Trasera", V(w, h, 0.3), cf * CF(0, h / 2, 0.75), wood:Lerp(C.Dark, 0.3), M.Wood, { CanQuery = false })
	for _, s in { -1, 1 } do
		Kit.box(ctx, m, "Lateral", V(0.3, h, 1.8), cf * CF(s * (w / 2 - 0.15), h / 2, 0), wood, M.Wood, { CanQuery = false })
	end
	local rows = math.max(2, math.floor(h / 2.2))
	for i = 0, rows do
		local y = 0.2 + i * (h - 0.4) / rows
		Kit.deco(ctx, m, "Balda", V(w - 0.6, 0.2, 1.6), cf * CF(0, y, 0), wood, M.Wood, nil, true)
		if i < rows then
			if fill == "Lab" then
				local n = math.floor(w / 1.4)
				for j = 1, n do
					Props.make(ctx, m, ctx.Rand.pick({ "Jar", "Flask", "Bottle", "Coil", "Battery", "Gadget" }), cf * CF(-w / 2 + 0.3 + (j - 0.5) * (w - 0.6) / n, y + 0.1, 0))
				end
			elseif fill == "Boxes" then
				local n = math.floor(w / 2)
				for j = 1, n do
					Kit.deco(ctx, m, "Caja", V(1.6, 1.2, 1.4), cf * CF(-w / 2 + 0.3 + (j - 0.5) * (w - 0.6) / n, y + 0.7, 0), ctx.Rand.pick({ rgb(170, 130, 80), rgb(120, 130, 140), rgb(200, 180, 140) }), M.Cardboard)
				end
			else
				Props.bookRow(ctx, m, cf * CF(0, y + 0.1, 0.1), w - 0.8)
			end
		end
	end
	return m
end

return Props
