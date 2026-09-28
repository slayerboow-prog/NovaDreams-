-- Decor: las plantas bajas de verdad de la ciudad (las que se recorren andando) bien decoradas y
-- con sitio para su gente. Es un repaso final sobre la ciudad ya construida (TownBuilder.build y,
-- si el archivo trae una ciudad de antes, al arrancar el servidor: Decor.dressTown).
--
--   * Busca cada edificio de Building.build (piezas Floor y Ceiling) y según lo que es (centro
--     comercial, tienda de la gasolinera, vestíbulo de las torres, facultades y biblioteca,
--     hospital, comisaría, Correos, recreativos, autoescuela, hamburguesería, restaurante, cafetería,
--     cine, tienda de pesca) le pone lo que le falta: cuadros, carteles, tablones, relojes,
--     estantes con cosas, plantas, papeleras, máquinas expendedoras, bancos, alfombras, lámparas…
--     y en los que estaban vacíos, su mobiliario completo (tiendas del centro comercial con su
--     dependiente, mostrador de la gasolinera, recepción de las oficinas, estanterías y mesas de
--     lectura de la biblioteca…).
--   * Nada se mete dentro de otra cosa (World/Space: sitio ocupado), la puerta y el paso quedan
--     libres, y en la comisaría, el hospital y las facultades el centro sigue libre (ahí la historia
--     coloca a sus personajes). Lo pequeño no choca, no se consulta y no da sombra.
--   * Las tiendas de la calle que por dentro eran una caja vacía y a oscuras se cierran con su
--     puerta de cristal (ShopDoor): al entrar se va a su interior montado (InteriorService, Local),
--     con lo que dice su cartel (farmacia, banco, bar, peluquería…).
--   * Marcas para la gente (las usan StaffService y CrowdService):
--       StaffSpot (Role, Work, JobId?, Icon?) -> puesto de trabajo: dependiente, recepcionista,
--         agente del mostrador, bomberos del parque… (un jugador de ese oficio lo cubre)
--       CrowdSpot (Pose = "Stand" | "Sit", Work?, Group) -> clientes, pacientes, lectores…
--   Todo sale de un número fijo por edificio (su posición): siempre igual.

local Builder = require(script.Parent.Parent.Builder)
local Furniture = require(script.Parent.Parent.Furniture)
local Space = require(script.Parent.Parent.Space)

local Decor = {}

Decor.VERSION = 1

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local PI = math.pi
local M = Enum.Material
local WHITE, DARK, STEEL = Furniture.WHITE, Furniture.DARK, Furniture.STEEL
local P = Furniture.Palette

export type Room = {
	Model: Model, -- donde van las piezas nuevas (modelo "Decor" dentro del edificio o de la sala)
	Building: Instance, -- el edificio o la sala
	Space: Space.Space,
	HX: number, -- medio ancho libre (de pared a pared)
	HZ: number, -- medio fondo libre
	H: number, -- alto libre (del suelo al techo)
	Kind: string,
	Key: string,
	Rand: Furniture.Rng,
	Ctx: Furniture.Ctx,
	Center: boolean?, -- el centro se deja libre
	Parts: number, -- piezas añadidas
}

-- Lo que pone el cartel de un edificio (nil si no tiene)
local function signText(model: Instance): string?
	local s = model:FindFirstChild("Sign")
	local gui = s and s:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	return if label then label.Text else nil
end
Decor.signText = signText

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function count(r: Room, part: Instance)
	r.Parts += 1
	return part
end

-- Detalle sin colisión (en coordenadas de la sala)
local function bit(r: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Transparency = transparency or 0, Parent = r.Model })
	p.CastShadow = false
	if size.Magnitude < 3 then
		p.CanQuery = false
	end
	count(r, p)
	return p
end

-- Mueble grande: choca (no se atraviesa) pero no lo consultan los rayos
local function solid(r: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local p = Builder.part({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, CanQuery = false, CanTouch = false, CastShadow = false, Parent = r.Model })
	count(r, p)
	return p
end

local function signOn(part: BasePart, text: string, color: Color3?)
	Builder.sign(part, text, Enum.NormalId.Front, color or WHITE)
end

-- CFrame del mundo en (x, y, z) de la sala mirando hacia (dx, dz)
local function at(r: Room, x: number, y: number, z: number, dx: number?, dz: number?): CFrame
	return r.Space:at(x, y, z, dx, dz)
end

-- Cuenta las piezas que añade una función de Furniture (van dentro de r.Model)
local function furnish(r: Room, fn: () -> ())
	local g = Instance.new("Model")
	g.Name = "Mueble"
	g.Parent = r.Model
	r.Ctx.Model = g
	fn()
	r.Ctx.Model = r.Model
	for _, d in g:GetDescendants() do
		if d:IsA("BasePart") then
			r.Parts += 1
		end
	end
end

-- Marca invisible (puestos de trabajo y sitios para la gente)
local function marker(r: Room, tag: string, cf: CFrame, attributes: { [string]: any }, size: Vector3?)
	local p = Builder.part({
		Name = tag,
		Size = size or V(1, 1, 1),
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Tags = { tag },
		Attributes = attributes,
		Parent = r.Model,
	})
	count(r, p)
	return p
end

-- Puesto de trabajo en (x, z) mirando hacia (dx, dz)
local function staff(r: Room, x: number, z: number, dx: number, dz: number, role: string, work: string?, jobId: string?)
	r.Space:addBox(V(x, 2.5, z), V(2, 5, 2))
	return marker(r, "StaffSpot", at(r, x, 0, z, dx, dz), { Role = role, Work = work, JobId = jobId, Group = r.Key })
end

-- Sitio para una persona de pie (si cabe) en (x, z) mirando hacia (dx, dz)
local function crowd(r: Room, x: number, z: number, dx: number, dz: number, work: string?): boolean
	if not r.Space:claim(V(x, 2.6, z), V(2.2, 5, 2.2)) then
		return false
	end
	marker(r, "CrowdSpot", at(r, x, 0, z, dx, dz), { Pose = "Stand", Work = work, Group = r.Key })
	return true
end

-- Sitio para una persona sentada (cf del asiento: centro de su tabla, mirando hacia donde mira quien se sienta)
local function crowdSeat(r: Room, seatCf: CFrame, work: string?)
	marker(r, "CrowdSpot", seatCf, { Pose = "Sit", Work = work, Group = r.Key }, V(2, 0.3, 2))
end

---------------------------------------------------------------------
-- Muebles propios (los de Furniture sirven para las salas; estos son para la calle)
---------------------------------------------------------------------

-- Banco con asiento de verdad (etiqueta Bench: el jugador se sienta con "Sentarse")
local function bench(r: Room, x: number, z: number, dx: number, dz: number, length: number, color: Color3?): boolean
	local w = math.abs(dx) > 0.5
	local size = if w then V(2.4, 3.6, length) else V(length, 3.6, 2.4)
	if not r.Space:claim(V(x, 1.8, z), size) then
		return false
	end
	local cf = at(r, x, 0, z, dx, dz)
	local m = Instance.new("Model")
	m.Name = "Bench"
	m.Parent = r.Model
	m:AddTag("Bench")
	local c = color or r.Rand.pick({ r.Ctx.Wood, rgb(60, 90, 150), rgb(70, 72, 78) })
	local seat = Builder.part({ ClassName = "Seat", Name = "Seat", Size = V(length, 0.4, 1.8), CFrame = cf * CF(0, 1.9, 0), Color = c, Material = M.Wood, CanTouch = false, CanQuery = false, CastShadow = false, Parent = m })
	count(r, seat)
	count(r, Builder.decor({ Name = "Back", Size = V(length, 1.6, 0.3), CFrame = cf * CF(0, 3, 0.95) * ANG(math.rad(-10), 0, 0), Color = c, Material = M.Wood, Parent = m }))
	for _, sx in { -1, 1 } do
		count(r, Builder.decor({ Name = "Leg", Size = V(0.3, 1.8, 1.6), CFrame = cf * CF(sx * (length / 2 - 0.4), 0.9, 0.1), Color = DARK, Material = M.Metal, Parent = m }))
	end
	-- (la gente se sienta en un extremo: el otro queda para los jugadores)
	if length >= 5 then
		crowdSeat(r, cf * CF(length / 2 - 1.1, 1.9, 0))
	end
	return true
end

-- Mostrador con caja; el dependiente detrás, mirando a los clientes (hacia dx, dz).
-- force: sin comprobar el sitio (ya reservado, p. ej. dentro de una tienda del centro comercial)
local function counter(r: Room, x: number, z: number, dx: number, dz: number, width: number, color: Color3, role: string, work: string?, jobId: string?, force: boolean?): boolean
	local along = math.abs(dx) < 0.5
	local size = if along then V(width + 0.6, 3.8, 2.8) else V(2.8, 3.8, width + 0.6)
	if force then
		r.Space:addBox(V(x, 1.9, z), size)
	elseif not r.Space:claim(V(x, 1.9, z), size) then
		return false
	end
	local cf = at(r, x, 0, z, dx, dz)
	solid(r, "Counter", V(width, 3.6, 2.4), cf * CF(0, 1.8, 0), color, M.Wood)
	bit(r, "CounterTop", V(width + 0.4, 0.2, 2.8), cf * CF(0, 3.7, 0), WHITE, M.Marble)
	bit(r, "Register", V(1.6, 0.8, 1.4), cf * CF(width / 2 - 1.4, 4.2, 0.3), DARK)
	bit(r, "RegisterScreen", V(1.2, 0.8, 0.1), cf * CF(width / 2 - 1.4, 4.9, 0.1) * ANG(math.rad(-20), 0, 0), rgb(80, 200, 140), M.Neon)
	bit(r, "CardReader", V(0.5, 0.2, 0.8), cf * CF(width / 2 - 2.8, 3.9, -0.6), DARK)
	for i = 0, math.min(4, math.floor(width / 2) - 1) do
		bit(r, "Candy", V(0.5, 0.3, 0.8), cf * CF(-width / 2 + 1.2 + i * 0.6, 3.95, -0.8), r.Rand.pick(P.Products))
	end
	staff(r, x - dx * 2.7, z - dz * 2.7, dx, dz, role, work, jobId)
	return true
end

-- Planta en maceta (si cabe)
local function plant(r: Room, x: number, z: number, size: number?): boolean
	local s = size or 1.2
	if not r.Space:claim(V(x, 2.5 * s, z), V(2.6 * s, 5 * s, 2.6 * s)) then
		return false
	end
	furnish(r, function()
		Furniture.plant(r.Ctx, at(r, x, 0, z), s)
	end)
	return true
end

-- Papelera
local function bin(r: Room, x: number, z: number): boolean
	if not r.Space:claim(V(x, 1.3, z), V(1.6, 2.6, 1.6)) then
		return false
	end
	local cf = at(r, x, 0, z)
	local b = bit(r, "Papelera", V(2.4, 1.4, 1.4), cf * CF(0, 1.2, 0) * ANG(0, 0, PI / 2), r.Rand.pick({ rgb(60, 130, 80), DARK, rgb(40, 90, 160), STEEL }), M.Metal)
	b.Shape = Enum.PartType.Cylinder
	bit(r, "BinBag", V(1.3, 0.12, 1.3), cf * CF(0, 2.42, 0), rgb(30, 30, 34))
	return true
end

-- Máquina expendedora contra la pared (dx, dz: hacia la sala)
local function vending(r: Room, x: number, z: number, dx: number, dz: number, drinks: boolean?): boolean
	local size = if math.abs(dx) > 0.5 then V(2.4, 7, 3.6) else V(3.6, 7, 2.4)
	if not r.Space:claim(V(x, 3.5, z), size) then
		return false
	end
	local cf = at(r, x, 0, z, dx, dz)
	local color = if drinks then r.Rand.pick({ rgb(200, 30, 40), rgb(30, 90, 180) }) else rgb(40, 44, 52)
	solid(r, "Vending", V(3.4, 6.8, 2.2), cf * CF(0, 3.4, 0), color, M.Metal)
	bit(r, "VendingGlass", V(2.2, 4.4, 0.1), cf * CF(-0.4, 4, -1.12), rgb(200, 225, 240), M.Glass, 0.4)
	for row = 0, 3 do
		for k = 0, 3 do
			bit(r, "Snack", V(0.4, 0.6, 0.3), cf * CF(-1.2 + k * 0.55, 2.6 + row * 1.05, -0.9), r.Rand.pick(P.Products))
		end
	end
	bit(r, "VendingPanel", V(0.7, 1.6, 0.1), cf * CF(1.2, 4.4, -1.12), DARK)
	bit(r, "VendingLight", V(3.2, 0.4, 0.1), cf * CF(0, 6.3, -1.12), rgb(250, 250, 240), M.Neon)
	return true
end

-- Fuente de agua
local function cooler(r: Room, x: number, z: number, dx: number, dz: number): boolean
	if not r.Space:claim(V(x, 2.6, z), V(2, 5.2, 2)) then
		return false
	end
	local cf = at(r, x, 0, z, dx, dz)
	solid(r, "CoolerBody", V(1.6, 3.4, 1.6), cf * CF(0, 1.7, 0), WHITE)
	local bottle = bit(r, "Bottle", V(1.8, 1.4, 1.4), cf * CF(0, 4.3, 0) * ANG(0, 0, PI / 2), rgb(150, 200, 240), M.Glass, 0.3)
	bottle.Shape = Enum.PartType.Cylinder
	bit(r, "TapSpout", V(0.3, 0.3, 0.4), cf * CF(0, 2.8, -0.9), rgb(60, 120, 220))
	return true
end

-- Alfombra en el suelo (solo donde no hay nada)
local function rug(r: Room, x: number, z: number, w: number, d: number, color: Color3?): boolean
	if not r.Space:free(V(x, 0.05, z), V(w, 0.1, d)) then
		return false
	end
	local c = color or r.Rand.pick(P.Fabrics)
	bit(r, "Rug", V(w, 0.08, d), at(r, x, 0.06, z), c, M.Fabric)
	bit(r, "RugBorder", V(w - 0.8, 0.09, d - 0.8), at(r, x, 0.065, z), c:Lerp(WHITE, 0.3), M.Fabric)
	bit(r, "RugCenter", V(w - 1.6, 0.1, d - 1.6), at(r, x, 0.07, z), c, M.Fabric)
	return true
end

-- Lámpara colgante (solo se ve; la luz la ponen los plafones)
local function pendant(r: Room, x: number, z: number): boolean
	local drop = math.min(4, r.H * 0.3)
	if not r.Space:claim(V(x, r.H - drop / 2, z), V(2.2, drop, 2.2)) then
		return false
	end
	local cf = at(r, x, r.H, z)
	bit(r, "Cord", V(0.08, drop - 0.6, 0.08), cf * CF(0, -(drop - 0.6) / 2, 0), DARK)
	local shade = bit(r, "Shade", V(1.8, 1, 1.8), cf * CF(0, -drop + 0.4, 0), r.Ctx.Accent)
	shade.Shape = Enum.PartType.Ball
	local bulb = bit(r, "Bulb", V(0.7, 0.7, 0.7), cf * CF(0, -drop, 0), rgb(255, 244, 220), M.Neon)
	bulb.Shape = Enum.PartType.Ball
	return true
end

---------------------------------------------------------------------
-- Paredes: cuadros, carteles, tablones, relojes, estantes, extintores…
---------------------------------------------------------------------
local POSTERS: { [string]: { string } } = {
	Clinic = { "LÁVATE LAS MANOS", "VACÚNATE", "BEBE AGUA", "SILENCIO, POR FAVOR", "PIDE CITA EN ADMISIÓN", "DONA SANGRE", "CUIDA TU CORAZÓN" },
	Police = { "SE BUSCA", "DENUNCIA AQUÍ", "112 EMERGENCIAS", "CIUDAD SEGURA", "OBJETOS PERDIDOS", "CINTURÓN SIEMPRE" },
	Post = { "ENVÍOS URGENTES", "SELLOS", "PAQUETERÍA", "APARTADOS", "RECOGIDA DE AVISOS", "CARTAS AL MUNDO" },
	Arcade = { "¡RÉCORD!", "INSERT COIN", "GAME OVER", "NIVEL 99", "¡JUEGA YA!", "TICKETS x2" },
	DrivingSchool = { "STOP", "CEDA EL PASO", "PROHIBIDO ADELANTAR", "50", "CURVA PELIGROSA", "PASO DE CEBRA" },
	Burger = { "MENÚ MEGA", "¡NUEVA!", "PATATAS XL", "2x1 MARTES", "BATIDOS", "HELADOS" },
	Restaurant = { "MENÚ DEL DÍA", "VINOS", "POSTRES CASEROS", "RESERVAS" },
	Cafe = { "CAFÉ DE ESPECIALIDAD", "BOLLERÍA", "TÉ Y CHOCOLATE", "WIFI GRATIS" },
	Cinema = { "ESTRENO", "PRÓXIMAMENTE", "PALOMITAS", "SESIÓN GOLFA", "3D", "¡TAQUILLAZO!" },
	FishShop = { "CAÑAS", "CEBOS", "CONCURSO DE PESCA", "RÉCORD: 12 KG", "CARRETES" },
	Mall = { "REBAJAS", "-30 %", "NUEVA COLECCIÓN", "¡OFERTAS!", "ABIERTO 10-22 H", "ASEOS", "SALIDA", "INFORMACIÓN" },
	GasShop = { "¡OFERTAS!", "CAFÉ 1 $", "HIELO", "PRENSA", "LAVADO" },
	Lobby = { "BIENVENIDOS", "PLANTAS 1-20", "RECEPCIÓN", "SALIDA" },
	Faculty = { "MATRÍCULA ABIERTA", "CONFERENCIA HOY", "BECAS", "TUTORÍAS", "EXÁMENES", "CLUB DE DEBATE", "SALIDA" },
	Library = { "SILENCIO", "PRÉSTAMO", "NOVEDADES", "SALA DE LECTURA", "HEMEROTECA" },
	Gym = { "¡A POR ELLO!", "HIDRÁTATE", "CLASES DIRIGIDAS", "SPINNING 19 H" },
	Generic = { "BIENVENIDOS", "SALIDA", "PROHIBIDO FUMAR", "ASEOS" },
}

local function wallItem(r: Room, kind: string, cf: CFrame, w: number, h: number)
	local R = r.Rand
	if kind == "Picture" then
		furnish(r, function()
			Furniture.picture(r.Ctx, cf, w, h)
		end)
	elseif kind == "Poster" then
		local list = POSTERS[r.Kind] or POSTERS.Generic
		local color = R.pick({ rgb(200, 50, 50), rgb(40, 90, 170), rgb(240, 200, 50), rgb(60, 150, 90), rgb(240, 240, 236), rgb(30, 30, 36), rgb(230, 120, 40) })
		bit(r, "PosterFrame", V(w + 0.3, h + 0.3, 0.1), cf * CF(0, 0, -0.05), DARK)
		local p = bit(r, "Poster", V(w, h, 0.08), cf * CF(0, 0, -0.12), color)
		signOn(p, R.pick(list), if color == rgb(240, 240, 236) or color == rgb(240, 200, 50) then DARK else WHITE)
	elseif kind == "Notice" then
		bit(r, "NoticeBoard", V(w, h, 0.2), cf * CF(0, 0, -0.1), rgb(186, 146, 96), M.Wood)
		for k = 0, 5 do
			local nx = -w / 2 + 0.8 + (k % 3) * (w - 1.6) / 2
			local ny = (math.floor(k / 3) - 0.5) * h * 0.45
			bit(r, "Note", V(math.min(1.2, w / 4), math.min(1.4, h / 3), 0.05), cf * CF(nx, ny, -0.23) * ANG(0, 0, R.range(-0.15, 0.15)), R.pick({ WHITE, rgb(250, 240, 150), rgb(200, 230, 250), rgb(250, 200, 210) }))
			bit(r, "Pin", V(0.15, 0.15, 0.1), cf * CF(nx, ny + 0.5, -0.28), R.pick({ rgb(220, 40, 40), rgb(40, 90, 200) }))
		end
	elseif kind == "Clock" then
		furnish(r, function()
			Furniture.clock(r.Ctx, cf)
		end)
	elseif kind == "Shelf" then
		bit(r, "WallShelf", V(w, 0.2, 1.2), cf * CF(0, -h / 2 + 0.1, -0.6), r.Ctx.Wood, M.Wood)
		for _, sx in { -1, 1 } do
			bit(r, "Bracket", V(0.15, 0.6, 1), cf * CF(sx * (w / 2 - 0.4), -h / 2 - 0.2, -0.5), DARK, M.Metal)
		end
		local x = -w / 2 + 0.5
		while x < w / 2 - 0.5 do
			local pw, ph = R.range(0.4, 0.8), R.range(0.5, 1.3)
			local item = bit(r, "ShelfItem", V(pw, ph, 0.7), cf * CF(x + pw / 2, -h / 2 + 0.2 + ph / 2, -0.6), R.pick(if r.Kind == "Library" or r.Kind == "Faculty" then P.Books else P.Products))
			if R.chance(0.25) then
				item.Shape = Enum.PartType.Cylinder
				item.Size = V(ph, pw, pw)
				item.CFrame = cf * CF(x + pw / 2, -h / 2 + 0.2 + ph / 2, -0.6) * ANG(0, 0, PI / 2)
			end
			x += pw + 0.2
		end
	elseif kind == "Extinguisher" then
		local e = bit(r, "Extinguisher", V(1.6, 0.8, 0.8), cf * CF(0, 0, -0.5) * ANG(0, 0, PI / 2), rgb(210, 30, 30), M.Metal)
		e.Shape = Enum.PartType.Cylinder
		local s = bit(r, "ExtinguisherSign", V(0.9, 0.9, 0.05), cf * CF(0, 1.5, -0.05), rgb(210, 30, 30))
		signOn(s, "🧯")
	elseif kind == "TV" then
		furnish(r, function()
			Furniture.wallTV(r.Ctx, cf, w)
		end)
	elseif kind == "Mirror" then
		bit(r, "MirrorFrame", V(w + 0.3, h + 0.3, 0.1), cf * CF(0, 0, -0.05), r.Ctx.Wood, M.Wood)
		bit(r, "Mirror", V(w, h, 0.08), cf * CF(0, 0, -0.12), rgb(200, 215, 225), M.Glass).Reflectance = 0.5
	elseif kind == "Sconce" then
		bit(r, "SconceBase", V(0.6, 1, 0.2), cf * CF(0, 0, -0.1), DARK, M.Metal)
		bit(r, "Sconce", V(0.9, 0.7, 0.6), cf * CF(0, 0.3, -0.45), rgb(255, 236, 200), M.Neon)
	end
end

-- Recorre las paredes y cuelga cosas donde hay pared de verdad (ni puertas, ni ventanas, ni muebles)
local WALL_SIZES: { [string]: { number } } = {
	Picture = { 4, 3.2, 6.5 }, -- ancho, alto, altura del centro
	Poster = { 3, 4, 6.5 },
	Notice = { 5, 3.4, 6 },
	Clock = { 2, 2, 8.6 },
	Shelf = { 5, 1.8, 6.2 },
	Extinguisher = { 1, 3, 3.2 },
	TV = { 6, 3.4, 7.6 },
	Mirror = { 3, 5, 5.5 },
	Sconce = { 1, 1.4, 8 },
}

local function dressWalls(r: Room, weights: { [string]: number }, step: number?)
	local kinds, total = {}, 0
	for kind, w in weights do
		table.insert(kinds, { kind, w })
		total += w
	end
	table.sort(kinds, function(a, b)
		return a[1] < b[1]
	end)
	local function choose(): string
		local x = r.Rand.next() * total
		for _, k in kinds do
			x -= k[2]
			if x <= 0 then
				return k[1]
			end
		end
		return kinds[#kinds][1]
	end
	local gap = step or 7
	local sides = {
		-- punto de partida (sobre la pared), dirección a lo largo, hacia la sala, largo
		{ V(-r.HX, 0, r.HZ), V(1, 0, 0), V(0, 0, -1), 2 * r.HX }, -- fondo
		{ V(-r.HX, 0, -r.HZ), V(0, 0, 1), V(1, 0, 0), 2 * r.HZ }, -- izquierda
		{ V(r.HX, 0, -r.HZ), V(0, 0, 1), V(-1, 0, 0), 2 * r.HZ }, -- derecha
		{ V(-r.HX, 0, -r.HZ), V(1, 0, 0), V(0, 0, 1), 2 * r.HX }, -- fachada (por dentro)
	}
	for _, side in sides do
		local origin, along, normal, length = side[1], side[2], side[3], side[4]
		local u = r.Rand.range(2, gap)
		while u < length - 2 do
			local kind = choose()
			local s = WALL_SIZES[kind]
			local w, h, y = s[1], s[2], math.min(s[3], r.H - s[2] / 2 - 0.6)
			local p = origin + along * u
			local center = Vector3.new(p.X, y, p.Z)
			local depth = if kind == "Shelf" then 1.4 elseif kind == "TV" or kind == "Extinguisher" then 1 else 0.4
			-- La caja entra un poco en la pared (así choca con los cristales de las ventanas)
			local boxCenter = center + normal * (depth / 2 - 0.35)
			local boxSize = if math.abs(along.X) > 0.5 then V(w, h, depth + 0.7) else V(depth + 0.7, h, w)
			local onWall = true
			for _, du in { -w / 2 + 0.2, 0, w / 2 - 0.2 } do
				for _, dy in { -h / 2 + 0.2, h / 2 - 0.2 } do
					if not r.Space:onWall(center + along * du + Vector3.new(0, dy, 0), normal) then
						onWall = false
					end
				end
			end
			if onWall and r.Space:free(boxCenter, boxSize) then
				r.Space:addBox(boxCenter, boxSize)
				wallItem(r, kind, at(r, center.X, center.Y, center.Z, normal.X, normal.Z), w, h)
				u += w + gap * r.Rand.range(0.6, 1.2)
			else
				u += 1.5
			end
		end
	end
end

-- Cosas de suelo pegadas a las paredes: plantas en las esquinas, papeleras, máquinas, bancos…
local function dressFloor(r: Room, items: { string }, tries: number?)
	-- Esquinas: plantas
	for _, c in { { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 } } do
		plant(r, c[1] * (r.HX - 1.8), c[2] * (r.HZ - 1.8), r.Rand.range(1.1, 1.5))
	end
	local n = tries or 12
	for i = 1, n do
		local item = items[(i - 1) % #items + 1]
		-- Un sitio pegado a una pared, al azar
		local side = r.Rand.int(1, 4)
		local u = r.Rand.range(-1, 1)
		local x, z, dx, dz
		if side == 1 then
			x, z, dx, dz = u * (r.HX - 3), r.HZ - 1.4, 0, -1
		elseif side == 2 then
			x, z, dx, dz = -r.HX + 1.4, u * (r.HZ - 3), 1, 0
		elseif side == 3 then
			x, z, dx, dz = r.HX - 1.4, u * (r.HZ - 3), -1, 0
		else
			x, z, dx, dz = u * (r.HX - 3), -r.HZ + 1.4, 0, 1
		end
		if item == "Plant" then
			plant(r, x, z, r.Rand.range(1, 1.4))
		elseif item == "Bin" then
			bin(r, x - dx * 0.2, z - dz * 0.2)
		elseif item == "Vending" then
			vending(r, x + dx * 0.4, z + dz * 0.4, dx, dz, r.Rand.chance(0.5))
		elseif item == "Cooler" then
			cooler(r, x, z, dx, dz)
		elseif item == "Bench" then
			bench(r, x + dx * 0.3, z + dz * 0.3, dx, dz, 6)
		elseif item == "Cabinet" then
			if r.Space:claim(V(x, 2.3, z), V(2.6, 4.6, 2.6)) then
				furnish(r, function()
					Furniture.filingCabinet(r.Ctx, at(r, x, 0, z, dx, dz))
				end)
			end
		elseif item == "Bookshelf" then
			local size = if math.abs(dx) > 0.5 then V(2, 8, 6.4) else V(6.4, 8, 2)
			if r.Space:claim(V(x + dx * 0.3, 4, z + dz * 0.3), size) then
				furnish(r, function()
					Furniture.bookshelf(r.Ctx, at(r, x + dx * 0.3, 0, z + dz * 0.3, dx, dz), 6, 7.5)
				end)
			end
		end
	end
end

-- Un sitio libre para una persona cerca de (x, z)
local function freeSpot(r: Room, x: number, z: number, radius: number): (number?, number?)
	for ring = 0, 6 do
		local d = ring * radius / 6
		for k = 0, 7 do
			local a = k / 8 * PI * 2 + ring
			local px, pz = x + math.cos(a) * d, z + math.sin(a) * d
			if math.abs(px) < r.HX - 1.5 and math.abs(pz) < r.HZ - 1.5 and r.Space:free(V(px, 2.6, pz), V(2.4, 5, 2.4)) then
				return px, pz
			end
		end
	end
	return nil, nil
end

-- Unas cuantas personas de pie repartidas (junto a las paredes si el centro es de la historia)
local function crowdAround(r: Room, n: number, works: { string })
	local placed = 0
	for _ = 1, n * 5 do
		if placed >= n then
			break
		end
		local x, z
		if r.Center then
			local side = r.Rand.int(1, 3)
			if side == 1 then
				x, z = r.Rand.range(-r.HX + 3, r.HX - 3), r.HZ - r.Rand.range(3, 5)
			else
				x, z = (if side == 2 then -1 else 1) * (r.HX - r.Rand.range(3, 5)), r.Rand.range(-r.HZ + 8, r.HZ - 3)
			end
		else
			x, z = r.Rand.range(-r.HX + 3, r.HX - 3), r.Rand.range(-r.HZ + 8, r.HZ - 3)
		end
		local a = r.Rand.range(0, PI * 2)
		if crowd(r, x, z, math.cos(a), math.sin(a), r.Rand.pick(works)) then
			placed += 1
		end
	end
end

---------------------------------------------------------------------
-- Tiendas del centro comercial, de la gasolinera…: escaparate con estanterías y dependiente
---------------------------------------------------------------------
local MALL_SHOPS = {
	{ "MODA", "Clothes", rgb(220, 60, 90) },
	{ "ZAPATOS", "Clothes", rgb(120, 70, 40) },
	{ "TECNO", "Tech", rgb(40, 100, 200) },
	{ "JUGUETES", "Toys", rgb(240, 160, 40) },
	{ "LIBROS", "Books", rgb(110, 70, 40) },
	{ "DEPORTES", "Toys", rgb(40, 150, 90) },
	{ "PERFUMES", "Pharmacy", rgb(200, 110, 160) },
	{ "HOGAR", "Tools", rgb(40, 140, 110) },
}

-- Local de x0..x1 (a lo largo de la pared del fondo) con fondo depth
local function storefront(r: Room, x0: number, x1: number, depth: number, shop: { any })
	local w = x1 - x0
	local cx = (x0 + x1) / 2
	local zFront = r.HZ - depth
	if not r.Space:free(V(cx, r.H / 2, zFront + depth / 2), V(w, r.H - 0.2, depth)) then
		return
	end
	-- Escaparate de cristal con hueco de puerta, cartel encima y paredes de los lados
	local doorW = 6
	local glassW = (w - doorW) / 2
	for _, s in { -1, 1 } do
		bit(r, "ShopFront", V(glassW, 9, 0.3), at(r, cx + s * (doorW / 2 + glassW / 2), 4.5, zFront), rgb(200, 225, 240), M.Glass, 0.6)
		solid(r, "ShopSide", V(0.6, r.H, depth), at(r, cx + s * (w / 2 - 0.3), r.H / 2, zFront + depth / 2), r.Rand.pick({ rgb(236, 232, 226), rgb(210, 214, 220) }))
	end
	bit(r, "ShopFascia", V(w, r.H - 9, 0.6), at(r, cx, 9 + (r.H - 9) / 2, zFront), shop[3])
	local signPart = bit(r, "ShopSign", V(math.min(w - 2, 14), 2, 0.3), at(r, cx, 10.5, zFront - 0.4, 0, -1), DARK)
	signOn(signPart, shop[1], rgb(250, 240, 210))
	r.Space:addBox(V(cx, r.H / 2, zFront + depth / 2), V(w, r.H, depth))
	-- Dentro: estanterías, mostrador con dependiente y un cliente mirando
	for _, sgn in { -1, 1 } do
		furnish(r, function()
			Furniture.shopShelf(r.Ctx, at(r, cx + sgn * (w / 4), 0, r.HZ - 1.4, 0, -1), math.min(8, w / 2 - 2), shop[2])
		end)
	end
	if depth >= 10 then
		furnish(r, function()
			Furniture.shopShelf(r.Ctx, at(r, cx - w / 4, 0, zFront + depth / 2, 0, -1), math.min(6, w / 2 - 3), shop[2])
		end)
	end
	counter(r, cx + w / 4, zFront + depth / 2 - 1, 0, -1, 5, shop[3], "Dependiente", "Fold", nil, true)
	marker(r, "CrowdSpot", at(r, cx - w / 4, 0, zFront + depth / 2 - 2.6, 0, 1), { Pose = "Stand", Work = "Phone", Group = r.Key })
end

---------------------------------------------------------------------
-- Cada tipo de sitio
---------------------------------------------------------------------
local Kinds: { [string]: (Room) -> () } = {}

-- Centro comercial: tiendas al fondo y a los lados, fuente, bancos, jardineras, zona de comidas e información
Kinds.Mall = function(r)
	local R = r.Rand
	-- Tiendas al fondo
	local depth = math.min(14, r.HZ * 0.45)
	local n = math.max(1, math.floor((2 * r.HX - 4) / 24))
	local w = (2 * r.HX - 4) / n
	for i = 0, n - 1 do
		storefront(r, -r.HX + 2 + i * w, -r.HX + 2 + (i + 1) * w, depth, MALL_SHOPS[(i + R.int(0, 7)) % #MALL_SHOPS + 1])
	end
	-- Fuente con jardinera en el centro y bancos alrededor
	local cz = -r.HZ * 0.05
	if r.Space:claim(V(0, 1.5, cz), V(14, 3, 14)) then
		local rim = bit(r, "FountainRim", V(2, 13, 13), at(r, 0, 1, cz) * ANG(0, 0, PI / 2), rgb(214, 210, 200), M.Marble)
		rim.Shape = Enum.PartType.Cylinder
		local water = bit(r, "FountainWater", V(0.3, 11.4, 11.4), at(r, 0, 1.9, cz) * ANG(0, 0, PI / 2), rgb(80, 170, 230), M.Glass, 0.25)
		water.Shape = Enum.PartType.Cylinder
		water:AddTag("Fountain")
		local column = bit(r, "FountainColumn", V(4, 1.6, 1.6), at(r, 0, 3.8, cz) * ANG(0, 0, PI / 2), rgb(214, 210, 200), M.Marble)
		column.Shape = Enum.PartType.Cylinder
		bit(r, "FountainBowl", V(0.6, 5, 5), at(r, 0, 5.6, cz) * ANG(0, 0, PI / 2), rgb(214, 210, 200), M.Marble).Shape = Enum.PartType.Cylinder
	end
	for _, b in { { -11, cz, 1, 0 }, { 11, cz, -1, 0 }, { 0, cz + 11, 0, -1 } } do
		bench(r, b[1], b[2], b[3], b[4], 7)
	end
	-- Jardineras con árbol
	for _, p in { { -r.HX * 0.55, cz }, { r.HX * 0.55, cz }, { -r.HX * 0.3, cz + r.HZ * 0.35 }, { r.HX * 0.3, cz + r.HZ * 0.35 } } do
		if r.Space:claim(V(p[1], 3, p[2]), V(6, 6, 6)) then
			solid(r, "Planter", V(5.6, 2, 5.6), at(r, p[1], 1, p[2]), rgb(180, 176, 166), M.Concrete)
			bit(r, "Soil", V(5, 0.2, 5), at(r, p[1], 2.05, p[2]), rgb(70, 50, 36), M.Ground)
			bit(r, "Trunk", V(0.6, 6, 0.6), at(r, p[1], 5, p[2]), rgb(110, 80, 50), M.Wood)
			bit(r, "Crown", V(6, 5, 6), at(r, p[1], 9, p[2]), R.pick({ rgb(70, 130, 60), rgb(90, 150, 70) }), M.Grass).Shape = Enum.PartType.Ball
		end
	end
	-- Información
	counter(r, -r.HX * 0.62, -r.HZ + 12, 0, -1, 7, rgb(30, 60, 110), "Informadora", "Type")
	local info = bit(r, "InfoSign", V(7, 1.4, 0.2), at(r, -r.HX * 0.62, 7, -r.HZ + 12, 0, -1), rgb(30, 60, 110))
	signOn(info, "ℹ INFORMACIÓN")
	-- Zona de comidas: mesas con sillas (gente sentada) y un puesto
	local fx = r.HX * 0.6
	for k = 0, 2 do
		local tx, tz = fx - 8 + (k % 2) * 8, -r.HZ + 10 + math.floor(k / 2) * 8 + (k % 2) * 3
		if r.Space:claim(V(tx, 2, tz), V(8, 4, 8)) then
			furnish(r, function()
				Furniture.table(r.Ctx, at(r, tx, 0, tz), 3.4, 3.4, WHITE)
				local s1 = Furniture.chair(r.Ctx, at(r, tx, 0, tz - 2.6, 0, 1), rgb(200, 60, 50))
				Furniture.chair(r.Ctx, at(r, tx, 0, tz + 2.6, 0, -1), rgb(200, 60, 50))
				crowdSeat(r, s1.CFrame, "Coffee")
			end)
		end
	end
	counter(r, r.HX - 6, -r.HZ + 20, -1, 0, 8, rgb(230, 120, 40), "Cocinera", "Stir")
	local food = bit(r, "FoodSign", V(0.2, 1.6, 8), at(r, r.HX - 0.3, 9, -r.HZ + 20), rgb(230, 120, 40))
	Builder.sign(food, "🍔 COMIDAS", Enum.NormalId.Left, WHITE)
	-- Lucernarios y banderolas en el techo
	for k = -1, 1 do
		bit(r, "Skylight", V(12, 0.2, 8), at(r, k * r.HX * 0.5, r.H - 0.15, cz), rgb(210, 235, 255), M.Neon, 0.3)
	end
	for k = 0, 3 do
		local x = -r.HX * 0.6 + k * r.HX * 0.4
		if r.Space:claim(V(x, r.H - 3, -r.HZ * 0.4), V(4, 5, 0.6)) then
			local b = bit(r, "Banner", V(3.4, 4.4, 0.1), at(r, x, r.H - 3.5, -r.HZ * 0.4), R.pick({ rgb(220, 60, 90), rgb(40, 100, 200), rgb(240, 180, 40), rgb(40, 150, 90) }), M.Fabric)
			signOn(b, R.pick({ "REBAJAS", "-30 %", "NUEVO", "¡OFERTAS!" }))
		end
	end
	dressWalls(r, { Poster = 3, Clock = 1, Extinguisher = 1, Picture = 1 }, 8)
	dressFloor(r, { "Bin", "Vending", "Bin", "Plant", "Bench" }, 10)
	crowdAround(r, 5, { "Phone", "Phone", "Watch", "Carry" })
end

-- Tienda de la gasolinera: estanterías, neveras, mostrador con cajero, café y prensa
Kinds.GasShop = function(r)
	counter(r, r.HX - 4.5, -r.HZ + 5, -1, 0, 6, rgb(30, 150, 80), "Cajero", "Count")
	for k = 0, 1 do
		local x = 2 + k * 4.4
		if r.Space:claim(V(x, 3.5, r.HZ - 1.4), V(4.2, 7.2, 2.6)) then
			furnish(r, function()
				Furniture.drinksCooler(r.Ctx, at(r, x, 0, r.HZ - 1.4, 0, -1))
			end)
		end
	end
	for k = 0, 1 do
		local z = -0.5 + k * 4.1
		if r.Space:claim(V(-5, 3.5, z), V(8.4, 7, 2.6)) then
			furnish(r, function()
				Furniture.shopShelf(r.Ctx, at(r, -5, 0, z, 0, -1), 8, if k == 0 then "Food" else "Tools")
			end)
		end
	end
	-- Café, prensa y hielo
	if r.Space:claim(V(r.HX - 1.4, 2, r.HZ - 3), V(2.4, 4, 4)) then
		solid(r, "CoffeeStand", V(2.2, 3.4, 3.6), at(r, r.HX - 1.4, 1.7, r.HZ - 3), rgb(90, 60, 40), M.Wood)
		bit(r, "CoffeeMachine", V(1.6, 1.8, 1.2), at(r, r.HX - 1.4, 4.3, r.HZ - 3.8), DARK, M.Metal)
		for k = 0, 3 do
			bit(r, "Cup", V(0.4, 0.5, 0.4), at(r, r.HX - 1.2, 3.65, r.HZ - 2.4 + k * 0.5), WHITE)
		end
	end
	if r.Space:claim(V(-r.HX + 1.4, 1.8, -r.HZ + 4), V(2.6, 3.6, 3)) then
		solid(r, "NewsRack", V(1.2, 3.4, 2.8), at(r, -r.HX + 1, 1.7, -r.HZ + 4), STEEL, M.Metal)
		for k = 0, 3 do
			bit(r, "Newspaper", V(0.1, 1.2, 1.1), at(r, -r.HX + 1.7, 1 + k * 0.8, -r.HZ + 4) * ANG(0, 0, -0.2), r.Rand.pick({ WHITE, rgb(240, 230, 200), rgb(200, 60, 50) }))
		end
		solid(r, "IceChest", V(3, 2.4, 2), at(r, -r.HX + 1.8, 1.2, -r.HZ + 7.5), rgb(40, 110, 200), M.Metal)
		local ice = bit(r, "IceSign", V(2.4, 0.8, 0.1), at(r, -r.HX + 1.8, 1.8, -r.HZ + 6.44, 0, -1), rgb(40, 110, 200))
		signOn(ice, "HIELO")
	end
	dressWalls(r, { Poster = 3, Clock = 1, Shelf = 1 }, 5)
	dressFloor(r, { "Bin" }, 2)
	crowdAround(r, 2, { "Phone", "Watch" })
end

-- Vestíbulo de las torres de oficinas: recepción, vigilante, sofás, tornos y ascensores
Kinds.Lobby = function(r)
	local R = r.Rand
	local company = "OFICINAS"
	local text = signText(r.Building)
	if text and text ~= "" then
		company = text
	end
	counter(r, 0, 2, 0, -1, 12, rgb(40, 50, 70), "Recepcionista", "Type")
	if r.Space:claim(V(0, 6, 6.5), V(18, 8, 1)) then
		local wall = bit(r, "LogoWall", V(16, 5.6, 0.4), at(r, 0, 7.5, 6.6, 0, -1), rgb(30, 36, 50))
		local logo = bit(r, "Logo", V(14, 2.2, 0.1), at(r, 0, 7.8, 6.35, 0, -1), rgb(30, 36, 50))
		signOn(logo, company, rgb(240, 210, 130))
		local _ = wall
	end
	-- Ascensores al fondo (de adorno) y tornos delante
	for _, x in { -r.HX * 0.55, r.HX * 0.55 } do
		if r.Space:claim(V(x, 5, r.HZ - 0.6), V(7.4, 10, 1.2)) then
			bit(r, "ElevatorFrame", V(7, 10, 0.4), at(r, x, 5, r.HZ - 0.25, 0, -1), STEEL, M.Metal)
			bit(r, "ElevatorDoors", V(5, 8.5, 0.2), at(r, x, 4.25, r.HZ - 0.55, 0, -1), rgb(190, 196, 204), M.Metal)
			bit(r, "ElevatorLight", V(1.2, 0.5, 0.1), at(r, x, 9.2, r.HZ - 0.5, 0, -1), rgb(120, 220, 255), M.Neon)
		end
		for k = -1, 1, 2 do
			local tx = x + k * 2.2
			if r.Space:claim(V(tx, 1.7, r.HZ - 9), V(0.8, 3.4, 2.4)) then
				bit(r, "Turnstile", V(0.6, 3.4, 2.2), at(r, tx, 1.7, r.HZ - 9), STEEL, M.Metal)
				bit(r, "TurnstileLight", V(0.2, 0.3, 0.6), at(r, tx, 3.5, r.HZ - 9.8), rgb(80, 220, 120), M.Neon)
			end
		end
	end
	staff(r, r.HX * 0.55 - 5, r.HZ - 10, 0, -1, "Vigilante", "Guard")
	-- Zona de espera
	local wx = -r.HX + 7
	rug(r, wx, -2, 9, 11, rgb(70, 80, 100))
	if r.Space:claim(V(-r.HX + 1.9, 2, -2), V(3.4, 4, 9)) then
		furnish(r, function()
			Furniture.sofa(r.Ctx, at(r, -r.HX + 1.9, 0, -2, 1, 0), r.Ctx.Fabric, 3)
		end)
		crowdSeat(r, at(r, -r.HX + 2.3, 1.9, -2 + 2.2, 1, 0), "Phone")
	end
	if r.Space:claim(V(wx, 1, -2), V(3.4, 2, 5.4)) then
		furnish(r, function()
			Furniture.coffeeTable(r.Ctx, at(r, wx, 0, -2, 1, 0), 3, 5)
		end)
	end
	if r.Space:claim(V(r.HX - 5, 2, -4), V(3, 4, 3)) then
		furnish(r, function()
			Furniture.armchair(r.Ctx, at(r, r.HX - 5, 0, -4, -1, 0), r.Ctx.Fabric)
		end)
	end
	-- Directorio
	if r.Space:claim(V(r.HX - 0.3, 5, 4), V(0.8, 5, 4)) then
		local directory = bit(r, "Directory", V(0.2, 5, 4), at(r, r.HX - 0.1, 5, 4), rgb(30, 36, 50))
		Builder.sign(directory, "DIRECTORIO\n" .. company .. "\nPlantas 1 a 20", Enum.NormalId.Left, rgb(240, 220, 160))
	end
	-- Otro rincón de espera a la derecha: sillones, mesita con revistas y lámpara de pie
	local ax = r.HX - 6
	for _, dz in { -3, 3 } do
		if r.Space:claim(V(ax, 2, -8 + dz), V(3.2, 4, 3.2)) then
			furnish(r, function()
				Furniture.armchair(r.Ctx, at(r, ax, 0, -8 + dz, -1, 0), r.Rand.pick(P.Fabrics))
			end)
		end
	end
	if r.Space:claim(V(ax - 3.4, 1, -8), V(2.4, 2, 3.4)) then
		furnish(r, function()
			Furniture.coffeeTable(r.Ctx, at(r, ax - 3.4, 0, -8, -1, 0), 2, 3)
		end)
		for k = 0, 2 do
			bit(r, "Magazine", V(1, 0.1, 1.4), at(r, ax - 3.4, 2.2 + k * 0.1, -8.6 + k * 0.6) * ANG(0, k * 0.5, 0), r.Rand.pick(P.Books))
		end
	end
	if r.Space:claim(V(r.HX - 1.5, 3.5, -12), V(2, 7, 2)) then
		furnish(r, function()
			Furniture.floorLamp(r.Ctx, at(r, r.HX - 1.5, 0, -12), "Main")
		end)
	end
	for k = -1, 1 do
		pendant(r, k * r.HX * 0.45, -r.HZ * 0.3)
	end
	dressWalls(r, { Picture = 3, Clock = 1, Sconce = 1 }, 6)
	dressFloor(r, { "Plant", "Bin", "Cooler", "Plant", "Bench", "Vending" }, 10)
	crowdAround(r, 2, { "Phone", "Watch", "Clipboard" })
	local _ = R
end

-- Biblioteca: estanterías en filas, mesas de lectura con lámparas, mostrador de préstamo
Kinds.Library = function(r)
	counter(r, -r.HX + 8, -r.HZ + 8, 0, -1, 8, rgb(110, 70, 40), "Bibliotecaria", "Type")
	local desk = bit(r, "LoanSign", V(6, 1.2, 0.2), at(r, -r.HX + 8, 7, -r.HZ + 8, 0, -1), rgb(110, 70, 40))
	signOn(desk, "PRÉSTAMO")
	-- Filas de estanterías a la derecha
	local x = r.HX - 5
	while x > 6 do
		for _, z in { -r.HZ + 10, 0, r.HZ - 10 } do
			if z < r.HZ - 4 and r.Space:claim(V(x, 4, z), V(7, 8, 2.4)) then
				furnish(r, function()
					Furniture.bookshelf(r.Ctx, at(r, x, 0, z, 0, -1), 6.5, 7.5)
				end)
			end
		end
		x -= 8
	end
	-- Mesas de lectura a la izquierda (fuera del centro): gente leyendo
	for i = 0, 3 do
		local tx = -r.HX + 7 + (i % 2) * 9
		local tz = -2 + math.floor(i / 2) * 9
		if r.Space:claim(V(tx, 2, tz), V(8, 4, 7)) then
			furnish(r, function()
				Furniture.table(r.Ctx, at(r, tx, 0, tz), 6, 3.2, r.Ctx.Wood)
				Furniture.tableLamp(r.Ctx, at(r, tx, 3.15, tz), "Main")
				for _, sx in { -1.6, 1.6 } do
					local a = Furniture.chair(r.Ctx, at(r, tx + sx, 0, tz - 2.4, 0, 1), r.Ctx.Wood)
					Furniture.chair(r.Ctx, at(r, tx + sx, 0, tz + 2.4, 0, -1), r.Ctx.Wood)
					if sx < 0 then
						crowdSeat(r, a.CFrame, "Book")
					end
				end
			end)
		end
	end
	dressWalls(r, { Poster = 1, Clock = 1, Picture = 2, Shelf = 2 }, 6)
	dressFloor(r, { "Bookshelf", "Bookshelf", "Plant", "Bin" }, 10)
	crowdAround(r, 2, { "Book", "Book", "Phone" })
end

-- Facultad: conserjería, tablones, bancos, máquinas y vitrina de trofeos
Kinds.Faculty = function(r)
	counter(r, -r.HX + 7, -r.HZ + 7, 0, -1, 6, rgb(110, 30, 40), "Conserje", "Clipboard")
	if r.Space:claim(V(r.HX - 1.4, 4, r.HZ - 8), V(2.6, 8, 8)) then
		solid(r, "TrophyCase", V(2, 7.4, 7.6), at(r, r.HX - 1.2, 3.7, r.HZ - 8), r.Ctx.Wood, M.Wood)
		bit(r, "TrophyGlass", V(0.1, 5.6, 7), at(r, r.HX - 2.25, 4.4, r.HZ - 8), rgb(210, 230, 240), M.Glass, 0.6)
		for k = 0, 5 do
			local t = bit(r, "Trophy", V(0.6, 1.2, 0.6), at(r, r.HX - 1.4, 2.4 + math.floor(k / 3) * 2.4, r.HZ - 10.4 + (k % 3) * 2.4), rgb(230, 190, 70), M.Metal)
			t.Shape = Enum.PartType.Cylinder
		end
	end
	dressWalls(r, { Notice = 3, Poster = 2, Picture = 1, Clock = 1 }, 6)
	dressFloor(r, { "Bench", "Vending", "Bench", "Bin", "Plant", "Cooler" }, 12)
	crowdAround(r, 4, { "Phone", "Book", "Book", "Clipboard" })
end

Kinds.Clinic = function(r)
	for _, desk in r.Building:GetChildren() do
		if desk:IsA("BasePart") and desk:HasTag("ClinicReception") then
			local l = r.Space.Frame:PointToObjectSpace(desk.CFrame.Position)
			staff(r, l.X + 2, l.Z + 2.6, 0, -1, "Recepcionista", "Type")
		end
	end
	dressWalls(r, { Poster = 3, Notice = 1, Clock = 1, Extinguisher = 1, TV = 1 }, 6)
	dressFloor(r, { "Bin", "Plant", "Vending", "Bench" }, 8)
	crowdAround(r, 2, { "Phone", "Watch" })
end

Kinds.Police = function(r)
	for _, desk in r.Building:GetChildren() do
		if desk:IsA("BasePart") and desk:HasTag("PoliceDesk") then
			local l = r.Space.Frame:PointToObjectSpace(desk.CFrame.Position)
			staff(r, l.X, l.Z + 2.6, 0, -1, "Agente de guardia", "Type", "Policia")
		end
	end
	dressWalls(r, { Poster = 3, Notice = 2, Clock = 1, Extinguisher = 1 }, 6)
	dressFloor(r, { "Cabinet", "Bin", "Plant", "Cooler" }, 8)
	crowdAround(r, 2, { "Phone", "Watch" })
end

Kinds.Post = function(r)
	for _, c in r.Building:GetChildren() do
		if c:IsA("BasePart") and c.Name == "Counter" then
			local l = r.Space.Frame:PointToObjectSpace(c.CFrame.Position)
			staff(r, l.X - 8, l.Z + 2.8, 0, -1, "Funcionaria de Correos", "Scan")
			staff(r, l.X + 8, l.Z + 2.8, 0, -1, "Funcionario de Correos", "Count")
			for k = 0, 2 do
				crowd(r, l.X - 8 + k * 2.6, l.Z - 5, 0, 1, if k == 0 then "Carry" else "Phone")
			end
		end
	end
	dressWalls(r, { Poster = 3, Notice = 1, Clock = 1 }, 6)
	dressFloor(r, { "Bin", "Plant", "Bench" }, 6)
end

Kinds.Arcade = function(r)
	for _, c in r.Building:GetChildren() do
		if c:IsA("BasePart") and c:HasTag("PrizeCounter") then
			local l = r.Space.Frame:PointToObjectSpace(c.CFrame.Position)
			staff(r, l.X + 2.4, l.Z, -1, 0, "Encargado de premios", "Count")
		end
	end
	dressWalls(r, { Poster = 4, Sconce = 1 }, 5)
	dressFloor(r, { "Vending", "Bin" }, 4)
	crowdAround(r, 3, { "Watch", "Phone" })
end

Kinds.DrivingSchool = function(r)
	staff(r, 3, r.HZ - 4.5, 0, -1, "Profesor de autoescuela", "Present")
	dressWalls(r, { Poster = 3, Notice = 1, Clock = 1 }, 5)
	dressFloor(r, { "Plant", "Cooler", "Bin" }, 4)
	crowdAround(r, 2, { "Book", "Phone" })
end

Kinds.Burger = function(r)
	staff(r, -4, 12.6, 0, -1, "Cajera", "Count")
	staff(r, 4, 12.6, 0, -1, "Cocinero", "Stir")
	-- Menús iluminados encima de la barra
	for k = -1, 1 do
		if r.Space:claim(V(k * 7, r.H - 3, r.HZ - 0.5), V(6, 3, 1)) then
			local board = bit(r, "MenuBoard", V(5.6, 2.6, 0.2), at(r, k * 7, r.H - 3, r.HZ - 0.4, 0, -1), DARK)
			signOn(board, ({ "🍔 MEGA 5 $", "🍟 PATATAS 2 $", "🥤 REFRESCO 1 $" })[k + 2], rgb(250, 200, 60))
		end
	end
	dressWalls(r, { Poster = 3, Clock = 1 }, 5)
	dressFloor(r, { "Bin", "Plant" }, 4)
	crowdAround(r, 3, { "Phone", "Watch" })
end

Kinds.Restaurant = function(r)
	dressWalls(r, { Picture = 3, Shelf = 1, Sconce = 2, Mirror = 1 }, 5)
	dressFloor(r, { "Plant" }, 4)
	for k = -1, 1 do
		pendant(r, k * 10, -r.HZ + 7)
	end
end

Kinds.Cafe = function(r)
	dressWalls(r, { Picture = 2, Shelf = 2, Poster = 1, Clock = 1 }, 5)
	dressFloor(r, { "Plant", "Bin" }, 4)
end

Kinds.Cinema = function(r)
	dressWalls(r, { Poster = 4, Sconce = 1 }, 5)
	dressFloor(r, { "Bin", "Plant", "Bench" }, 5)
	crowdAround(r, 2, { "Phone", "Watch" })
end

Kinds.FishShop = function(r)
	dressWalls(r, { Poster = 2, Picture = 1, Shelf = 1 }, 5)
	dressFloor(r, { "Bin", "Plant" }, 3)
end

-- Gimnasio: un monitor/a de sala (si hay un jugador monitor, se aparta: StaffService)
Kinds.Gym = function(r)
	local x, z = freeSpot(r, 0, r.HZ * 0.2, 10)
	if x and z then
		staff(r, x, z, 0, -1, "Monitora", "Clipboard", "MonitorGimnasio")
	end
	dressWalls(r, { Poster = 2, Clock = 1 }, 7)
end

---------------------------------------------------------------------
-- Qué es cada edificio
---------------------------------------------------------------------

function Decor.kindOf(model: Model): string?
	local name = model.Name
	local parentName = if model.Parent then model.Parent.Name else ""
	local lit = model:FindFirstChild("CeilingLamp") ~= nil
	if not lit then
		local open = model:FindFirstChild("DoorPanel") == nil and model:FindFirstChild("GarageDoor") == nil and model:FindFirstChild("ShopDoor") == nil
		if open and signText(model) and (name == "Edificio" or string.match(name, "^Edificio_%d+$") ~= nil) and parentName ~= "Bomberos" then
			return "DarkShop"
		end
		return nil
	end
	if parentName == "CentroComercial" then
		return "Mall"
	elseif name == "Tienda" and parentName == "Gasolinera" then
		return "GasShop"
	elseif name == "Torre" then
		return "Lobby"
	elseif parentName == "Facultad" then
		return if model.Parent and model.Parent:HasTag("Library") then "Library" else "Faculty"
	elseif parentName == "Hospital" or parentName == "CentroSalud" then
		return "Clinic"
	elseif parentName == "Policia" then
		return "Police"
	elseif name == "Correos" then
		return "Post"
	elseif name == "Recreativos" then
		return "Arcade"
	elseif name == "Autoescuela" then
		return "DrivingSchool"
	elseif name == "MegaBurger" then
		return "Burger"
	elseif name == "Restaurante" then
		return "Restaurant"
	elseif name == "Cafeteria" then
		return "Cafe"
	elseif name == "Cine" then
		return "Cinema"
	elseif name == "TiendaPesca" then
		return "FishShop"
	elseif name == "GimnasioValmar" then
		return "Gym"
	end
	return nil
end

-- Las tiendas vacías y a oscuras: puerta de cristal (se entra a su interior: InteriorService)
local function closeShop(model: Model): number
	local floor = model:FindFirstChild("Floor") :: BasePart
	local frame = floor.CFrame * CF(0, floor.Size.Y / 2, 0)
	local hz = floor.Size.Z / 2
	local door = Builder.part({
		Name = "ShopDoor",
		Size = V(7.8, 9.8, 0.4),
		CFrame = frame * CF(0, 4.9, -hz - 0.5),
		Color = rgb(60, 76, 90),
		Material = M.Glass,
		Transparency = 0.15,
		Reflectance = 0.2,
		CastShadow = false,
		CanQuery = false,
		Parent = model,
	})
	door:SetAttribute("Shop", signText(model))
	Builder.decor({ Name = "DoorBar", Size = V(0.3, 3, 0.3), CFrame = frame * CF(1.2, 4.6, -hz - 0.8), Color = rgb(200, 202, 208), Material = M.Metal, Parent = model })
	local sticker = Builder.decor({ Name = "DoorSticker", Size = V(3, 0.9, 0.05), CFrame = frame * CF(-1.6, 6.2, -hz - 0.75), Color = rgb(250, 250, 250), Parent = model })
	Builder.sign(sticker, "ABIERTO", Enum.NormalId.Front, rgb(40, 150, 70))
	return 3
end

-- La sala libre de un edificio con lo que ya hay dentro
function Decor.roomOf(model: Model, kind: string, nearby: { BasePart }): Room?
	local floor = model:FindFirstChild("Floor")
	local ceiling = model:FindFirstChild("Ceiling")
	if not floor or not ceiling or not floor:IsA("BasePart") or not ceiling:IsA("BasePart") then
		return nil
	end
	local frame = floor.CFrame * CF(0, floor.Size.Y / 2, 0)
	local hx, hz = floor.Size.X / 2, floor.Size.Z / 2
	local height = (ceiling.CFrame.Position.Y - ceiling.Size.Y / 2) - frame.Position.Y
	local space = Space.new(frame, hx, hz, height)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Wall" then
			space:addWall(part)
		end
	end
	for _, part in nearby do
		if part ~= floor and part ~= ceiling and part.Name ~= "Wall" and part.Parent then
			local box = space:boxOf(part.CFrame, part.Size)
			if box.Max.X > -hx - 0.6 and box.Min.X < hx + 0.6 and box.Max.Z > -hz - 0.6 and box.Min.Z < hz + 0.6 and box.Max.Y > 0.02 and box.Min.Y < height then
				table.insert(space.Boxes, box)
			end
		end
	end
	local p = frame.Position
	local key = ("%s_%d_%d"):format(kind, math.floor(p.X + 0.5), math.floor(p.Z + 0.5))
	local rand = Furniture.rng("Decor:" .. key)
	local holder = Instance.new("Model")
	holder.Name = "Decor"
	holder.Parent = model
	local r: Room = {
		Model = holder,
		Building = model,
		Space = space,
		HX = hx,
		HZ = hz,
		H = height,
		Kind = kind,
		Key = key,
		Rand = rand,
		Ctx = { Model = holder, Rand = rand, Wood = rand.pick(P.Woods), Fabric = rand.pick(P.Fabrics), Accent = rand.pick(P.Accents) },
		Center = kind == "Clinic" or kind == "Police" or kind == "Faculty" or kind == "Library",
		Parts = 0,
	}
	-- La puerta y el paso hasta el ascensor quedan libres; en algunos, el centro también
	local half = if hx < 16 then 3.5 else 5.5
	space:block(-half, half, -hz - 1, -hz + math.min(11, hz * 0.8))
	if r.Center then
		space:block(-7, 7, -7, 7)
	end
	return r
end

-- Decora un edificio (kind: Decor.kindOf). Devuelve las piezas añadidas.
function Decor.dress(model: Model, kind: string, nearby: { BasePart }): number
	if kind == "DarkShop" then
		return closeShop(model)
	end
	local fn = Kinds[kind]
	local r = fn and Decor.roomOf(model, kind, nearby)
	if not r then
		return 0
	end
	fn(r)
	model:SetAttribute("DecorKind", kind)
	return r.Parts
end

-- Bomberos (sin planta baja jugable): dos bomberos en el parque, junto al camión y el material
local function fireStation(station: Instance): number
	local rack = station:FindFirstChild("GearRack")
	local bay = station:FindFirstChild("FireTruckSpot")
	if not rack or not bay or not rack:IsA("BasePart") or not bay:IsA("BasePart") then
		return 0
	end
	local n = 0
	for i, cf in { rack.CFrame * CF(-3.5, -rack.Size.Y / 2, -2.2), bay.CFrame * CF(4, -bay.Size.Y / 2, -2) } do
		Builder.part({
			Name = "StaffSpot",
			Size = V(1, 1, 1),
			CFrame = cf,
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Tags = { "StaffSpot" },
			Attributes = { Role = if i == 1 then "Bombera" else "Bombero", Work = if i == 1 then "Clipboard" else "Hose", JobId = "Bombero", Group = "Bomberos_" .. math.floor(cf.Position.X) },
			Parent = station,
		})
		n += 1
	end
	return n
end

-- Repaso de toda la ciudad (una vez: la ciudad guarda la versión en DecorVersion)
function Decor.dressTown(town: Instance): { [string]: number }
	local stats: { [string]: number } = {}
	if town:GetAttribute("DecorVersion") == Decor.VERSION then
		return stats
	end
	town:SetAttribute("DecorVersion", Decor.VERSION)
	-- Rejilla con todas las piezas (para saber qué hay dentro de cada planta baja)
	local CELL = 40
	local grid: { [string]: { BasePart } } = {}
	local buildings: { { Model: Model, Kind: string } } = {}
	local stations: { Instance } = {}
	for _, d in town:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			local key = math.floor(p.X / CELL) .. "," .. math.floor(p.Z / CELL)
			local list = grid[key]
			if not list then
				list = {}
				grid[key] = list
			end
			table.insert(list, d)
		elseif d:IsA("Model") then
			if d:FindFirstChild("Floor") and d:FindFirstChild("Ceiling") then
				local kind = Decor.kindOf(d)
				if kind then
					table.insert(buildings, { Model = d, Kind = kind })
				end
			end
			if d.Name == "Bomberos" then
				table.insert(stations, d)
			end
		end
	end
	for _, b in buildings do
		local floor = b.Model:FindFirstChild("Floor") :: BasePart
		local p = floor.CFrame.Position
		local reach = math.max(floor.Size.X, floor.Size.Z) / 2 + 20
		local nearby = {}
		for gx = math.floor((p.X - reach) / CELL), math.floor((p.X + reach) / CELL) do
			for gz = math.floor((p.Z - reach) / CELL), math.floor((p.Z + reach) / CELL) do
				for _, part in grid[gx .. "," .. gz] or {} do
					table.insert(nearby, part)
				end
			end
		end
		local ok, added = pcall(Decor.dress, b.Model, b.Kind, nearby)
		if ok then
			stats[b.Kind] = (stats[b.Kind] or 0) + added
		else
			warn("[Decor] " .. b.Model.Name .. ": " .. tostring(added))
		end
	end
	for _, station in stations do
		stats.FireStation = (stats.FireStation or 0) + fireStation(station)
	end
	return stats
end

---------------------------------------------------------------------
-- Salas montadas (World/Interiors): más detalles en las paredes y en el suelo
---------------------------------------------------------------------
local ROOM_RECIPES: { [string]: { Walls: { [string]: number }, Floor: { string }?, Step: number? } } = {
	OficinaLobby = { Walls = { Picture = 2, Clock = 1, Sconce = 1 }, Floor = { "Plant", "Bin" } },
	Oficina = { Walls = { Picture = 1, Notice = 2, Clock = 1, Poster = 1 }, Floor = { "Plant", "Bin", "Cabinet" } },
	Local = { Walls = { Poster = 2, Shelf = 2, Clock = 1 }, Floor = { "Plant", "Bin" } },
	Nave = { Walls = { Poster = 1, Notice = 1, Extinguisher = 2, Clock = 1 }, Floor = { "Bin" }, Step = 10 },
	Taller = { Walls = { Poster = 2, Shelf = 2, Extinguisher = 1, Clock = 1 }, Floor = { "Bin" } },
	Ocio = { Walls = { Poster = 2, Sconce = 2, Mirror = 1 }, Floor = { "Plant", "Bin" } },
	Aula = { Walls = { Notice = 2, Poster = 1, Picture = 1 }, Floor = { "Plant", "Bin" } },
	Ayuntamiento = { Walls = { Picture = 3, Notice = 1, Sconce = 1 }, Floor = { "Plant", "Bin", "Bench" }, Step = 9 },
	Museo = { Walls = { Sconce = 1, Extinguisher = 1 }, Floor = { "Plant", "Bin", "Bench" }, Step = 10 },
	Teatro = { Walls = { Sconce = 3, Poster = 1 }, Floor = { "Plant" }, Step = 8 },
	Estacion = { Walls = { Poster = 2, Clock = 1, Notice = 1, TV = 1 }, Floor = { "Bin", "Vending", "Plant", "Bench" }, Step = 8 },
	CentroComercial = { Walls = { Poster = 3, Clock = 1 }, Floor = { "Bin", "Vending", "Plant" }, Step = 8 },
	Juzgado = { Walls = { Picture = 2, Sconce = 1 }, Floor = { "Plant", "Bin" } },
	Hacienda = { Walls = { Poster = 2, Notice = 2, Clock = 1 }, Floor = { "Plant", "Bin", "Cabinet" } },
	Cuartel = { Walls = { Notice = 2, Poster = 1, Extinguisher = 1 }, Floor = { "Bin", "Cabinet" }, Step = 10 },
}
Decor.RoomRecipes = ROOM_RECIPES

-- r: la sala de World/Interiors (Model, W, D, H, at, Rand…). Devuelve las piezas añadidas.
function Decor.room(room: { [string]: any }, seed: string?): number
	local recipe = ROOM_RECIPES[room.Kind]
	if not recipe then
		return 0
	end
	local model: Model = room.Model
	local frame = room.at(0, 0, 0)
	local space = Space.new(frame, room.W / 2, room.D / 2, room.H)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local name = part.Name
			if name == "WallBack" or name == "WallLeft" or name == "WallRight" or name == "WallFront" or name == "Wall" then
				space:addWall(part)
			elseif name ~= "Floor" and name ~= "Ceiling" and name ~= "FloorFinish" and name ~= "WallFinish" and name ~= "Baseboard" then
				space:addPart(part)
			end
			-- Delante de las puertas y del ascensor no se pone nada (hay que poder pasar)
			if part:HasTag("TowerStairs") or part:HasTag("InteriorElevator") or part:HasTag("InteriorExit") or part:HasTag("InteriorEntry") then
				local l = frame:PointToObjectSpace(part.Position)
				space:addBox(Vector3.new(l.X, 4, l.Z), Vector3.new(math.max(part.Size.X, part.Size.Z) + 5, 8, math.max(part.Size.X, part.Size.Z) + 5))
			end
		end
	end
	local rand = Furniture.rng("DecorRoom:" .. room.Kind .. ":" .. (seed or room.Kind))
	local holder = Instance.new("Model")
	holder.Name = "Decor"
	holder.Parent = model
	local r: Room = {
		Model = holder,
		Building = model,
		Space = space,
		HX = room.W / 2,
		HZ = room.D / 2,
		H = room.H,
		Kind = room.Kind,
		Key = room.Kind,
		Rand = rand,
		Ctx = { Model = holder, Rand = rand, Wood = room.Wood, Fabric = room.Fabric, Accent = room.Accent },
		Parts = 0,
	}
	space:block(-4, 4, -r.HZ - 1, -r.HZ + 8)
	dressWalls(r, recipe.Walls, recipe.Step)
	if recipe.Floor then
		dressFloor(r, recipe.Floor, 8)
	end
	-- Unas lámparas colgantes donde no hay nada en el techo
	if r.H >= 11 then
		for _ = 1, 3 do
			pendant(r, rand.range(-r.HX + 4, r.HX - 4), rand.range(-r.HZ + 4, r.HZ - 4))
		end
	end
	return r.Parts
end

return Decor
