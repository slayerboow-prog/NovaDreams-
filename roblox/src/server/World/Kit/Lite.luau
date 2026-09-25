-- Lite: edificios ligeros y variados para llenar la ciudad sin cargar el juego.
--
-- Cada edificio usa pocas piezas grandes (cuerpo, franjas de ventanas por planta, montantes, cornisa,
-- bajo comercial con escaparate, toldo y cartel) y se combinan al azar: estilo, color, material,
-- altura, balcones, tejado… Así no hay dos iguales. Los interiores importantes siguen siendo los de
-- Civic/Home (colegios, casas familiares…); estos son los edificios "de relleno" de las calles.
--
-- Todos reciben un CFrame en el suelo (Y = 0) cuyo LookVector mira a la calle (la fachada).

local Builder = require(script.Parent.Parent.Builder)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)

local Lite = {}

local rgb = Color3.fromRGB
local FH = 11 -- alto de una planta

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local function part(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, decor: boolean?): BasePart
	local props = { Name = name, CFrame = cf, Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	return if decor then Builder.decor(props) else Builder.part(props)
end

---------------------------------------------------------------------
-- Estilos de edificio
---------------------------------------------------------------------
Lite.Styles = {
	Moderno = {
		Walls = { rgb(236, 236, 232), rgb(210, 214, 218), rgb(180, 186, 192), rgb(90, 96, 104), rgb(232, 226, 214) },
		Material = Enum.Material.Concrete,
		Glass = { rgb(120, 170, 200), rgb(90, 130, 160), rgb(140, 180, 196) },
		Trim = rgb(60, 64, 70),
	},
	Clasico = {
		Walls = { rgb(232, 214, 184), rgb(222, 196, 160), rgb(240, 228, 206), rgb(214, 180, 150), rgb(196, 170, 140) },
		Material = Enum.Material.Plaster,
		Glass = { rgb(70, 90, 110), rgb(80, 100, 120) },
		Trim = rgb(248, 244, 236),
	},
	Ladrillo = {
		Walls = { rgb(160, 84, 64), rgb(140, 72, 56), rgb(176, 100, 76), rgb(120, 70, 60) },
		Material = Enum.Material.Brick,
		Glass = { rgb(60, 80, 100), rgb(70, 92, 112) },
		Trim = rgb(236, 230, 220),
	},
	Colorido = {
		Walls = { rgb(240, 196, 120), rgb(150, 200, 220), rgb(236, 150, 140), rgb(170, 210, 160), rgb(250, 230, 150), rgb(200, 170, 220) },
		Material = Enum.Material.Plaster,
		Glass = { rgb(80, 110, 140), rgb(90, 120, 150) },
		Trim = rgb(250, 250, 246),
	},
}

local SHOPS = {
	"FARMACIA", "PANADERÍA", "ZAPATERÍA", "BANCO", "INMOBILIARIA", "FLORISTERÍA", "LIBRERÍA", "PELUQUERÍA",
	"FERRETERÍA", "ÓPTICA", "BAR", "PIZZERÍA", "HELADERÍA", "GIMNASIO", "FRUTERÍA", "ROPA", "CAFETERÍA",
	"ELECTRÓNICA", "MUEBLES", "VIDEOJUEGOS", "MASCOTAS", "PAPELERÍA", "DEPORTES", "JUGUETERÍA", "SUSHI",
	"HAMBURGUESERÍA", "TALLER", "SUPERMERCADO", "ESTANCO", "TELEFONÍA", "JOYERÍA", "LAVANDERÍA",
}
local AWNINGS = { rgb(170, 40, 40), rgb(40, 90, 150), rgb(40, 120, 70), rgb(200, 150, 40), rgb(90, 60, 110), rgb(220, 110, 40), rgb(30, 30, 34) }

Lite.ShopNames = SHOPS

-- Bajo comercial: escaparate, puerta, toldo y (a veces) cartel
local function shopFront(m: Instance, cf: CFrame, w: number, d: number, name: string?)
	local front = cf * CFrame.new(0, 0, -d / 2)
	part(m, "ShopGlass", front * CFrame.new(0, 4, -0.2), Vector3.new(w - 4, 6.5, 0.3), rgb(150, 190, 210), Enum.Material.Glass, true).Transparency = 0.25
	part(m, "Awning", front * CFrame.new(0, 7.8, -1.6) * CFrame.Angles(math.rad(-14), 0, 0), Vector3.new(w - 3, 0.3, 3.2), pick(AWNINGS), Enum.Material.Fabric, true)
	if name then
		local sign = part(m, "Sign", front * CFrame.new(0, 9.6, -0.35), Vector3.new(math.min(w - 6, #name * 1.6 + 4), 2, 0.3), rgb(24, 28, 36))
		Builder.sign(sign, name, Enum.NormalId.Front)
	end
end

-- Edificio de pisos (o de oficinas). opts: Style, Shop (nombre o true), Balconies, Night, Color
function Lite.building(parent: Instance, cf: CFrame, w: number, d: number, floors: number, opts: { [string]: any }?): Model
	opts = opts or {}
	local style = Lite.Styles[opts.Style or pick({ "Moderno", "Clasico", "Ladrillo", "Colorido" })]
	local m = Builder.model("Bloque", parent)
	local wall = opts.Color or pick(style.Walls)
	local glass = pick(style.Glass)
	local ground = if opts.Shop then 10 else 0 -- bajo comercial más alto
	local H = ground + floors * FH
	part(m, "Body", cf * CFrame.new(0, H / 2, 0), Vector3.new(w, H, d), wall, style.Material)
	-- Franjas de ventanas (una por planta en la fachada y otra en un lateral) y montantes
	local night = opts.Night ~= false
	for f = 1, floors do
		local y = ground + (f - 0.5) * FH + 0.5
		local strip = part(m, "Windows", cf * CFrame.new(0, y, -d / 2 - 0.15), Vector3.new(w - 4, FH * 0.52, 0.3), glass, Enum.Material.Glass, true)
		if night and math.random() < 0.25 then
			strip:AddTag("NightWindow")
			strip:SetAttribute("DayColor", glass)
			strip:SetAttribute("OnAt", 18 + math.random() * 2)
			strip:SetAttribute("OffAt", 23 + math.random() * 3)
		end
		-- Fachada trasera y laterales (así no hay "cajas lisas" vistas desde atrás)
		part(m, "BackWindows", cf * CFrame.new(0, y, d / 2 + 0.15), Vector3.new(w - 4, FH * 0.52, 0.3), glass, Enum.Material.Glass, true)
		part(m, "SideWindows", cf * CFrame.new(if f % 2 == 1 then w / 2 + 0.15 else -w / 2 - 0.15, y, 0), Vector3.new(0.3, FH * 0.52, d - 6), glass, Enum.Material.Glass, true)
	end
	local mullions = math.max(2, math.floor(w / 9))
	for i = 1, mullions - 1 do
		local x = -w / 2 + 2 + (w - 4) * i / mullions
		part(m, "Mullion", cf * CFrame.new(x, ground + floors * FH / 2, -d / 2 - 0.35), Vector3.new(0.7, floors * FH - 1, 0.4), style.Trim, style.Material, true)
	end
	-- Balcones en la fachada (algunos edificios)
	if opts.Balconies or (opts.Balconies == nil and math.random() < 0.4 and floors >= 3) then
		for f = 2, floors, 2 do
			part(m, "Balcony", cf * CFrame.new(0, ground + (f - 1) * FH + 0.3, -d / 2 - 1.2), Vector3.new(w * 0.7, 0.5, 2.4), style.Trim, style.Material, true)
		end
	end
	-- Cornisa y máquinas en la azotea
	part(m, "Cornice", cf * CFrame.new(0, H + 0.6, 0), Vector3.new(w + 1, 1.2, d + 1), style.Trim, style.Material)
	if math.random() < 0.7 then
		part(m, "RoofUnit", cf * CFrame.new((math.random() - 0.5) * w * 0.5, H + 2.7, (math.random() - 0.5) * d * 0.4), Vector3.new(6, 3, 5), rgb(150, 154, 160), Enum.Material.Metal, true)
	end
	-- Planta baja: tienda o portal
	if opts.Shop then
		shopFront(m, cf, w, d, if type(opts.Shop) == "string" then opts.Shop elseif math.random() < 0.6 then pick(SHOPS) else nil)
	else
		part(m, "Door", cf * CFrame.new(0, 3.5, -d / 2 - 0.2), Vector3.new(4, 7, 0.4), rgb(80, 60, 44), Enum.Material.Wood, true)
	end
	Builder.streamable(m)
	return m
end

-- Rascacielos de cristal con bandas por planta, escalonado y con antena
function Lite.tower(parent: Instance, cf: CFrame, w: number, d: number, floors: number, name: string?): Model
	local m = Builder.model("Rascacielos", parent)
	local glass = pick({ rgb(90, 140, 180), rgb(70, 110, 150), rgb(120, 160, 190), rgb(60, 90, 120), rgb(150, 170, 180) })
	local band = pick({ rgb(226, 228, 230), rgb(60, 64, 70), rgb(200, 190, 170) })
	local fh = 10
	local y = 0
	local sections = if floors > 20 then 3 elseif floors > 12 then 2 else 1
	local per = math.ceil(floors / sections)
	local cw, cd = w, d
	for s = 1, sections do
		local n = math.min(per, floors - (s - 1) * per)
		if n <= 0 then
			break
		end
		local h = n * fh
		local body = part(m, "Core", cf * CFrame.new(0, y + h / 2, 0), Vector3.new(cw, h, cd), glass, Enum.Material.Glass)
		body.Reflectance = 0.15
		for f = 1, n, 2 do
			part(m, "Band", cf * CFrame.new(0, y + f * fh - 0.5, 0), Vector3.new(cw + 0.6, 1, cd + 0.6), band, Enum.Material.Concrete, true)
		end
		if math.random() < 0.5 then
			local lit = part(m, "OfficeLights", cf * CFrame.new(0, y + h * 0.5, -cd / 2 - 0.12), Vector3.new(cw - 3, h * 0.8, 0.1), glass, Enum.Material.Glass, true)
			lit:AddTag("NightWindow")
			lit:SetAttribute("DayColor", glass)
			lit:SetAttribute("NightColor", rgb(206, 222, 240))
			lit:SetAttribute("OnAt", 17.5)
			lit:SetAttribute("OffAt", 22 + math.random() * 3)
		end
		y += h
		cw, cd = cw * 0.78, cd * 0.78
	end
	part(m, "Roof", cf * CFrame.new(0, y + 0.5, 0), Vector3.new(cw / 0.78 + 1, 1, cd / 0.78 + 1), band, Enum.Material.Concrete)
	part(m, "Antenna", cf * CFrame.new(0, y + 12, 0), Vector3.new(0.8, 24, 0.8), rgb(200, 200, 204), Enum.Material.Metal, true)
	-- Entrada con marquesina y nombre
	part(m, "Canopy", cf * CFrame.new(0, 9, -d / 2 - 4), Vector3.new(math.min(w - 6, 24), 0.8, 8), rgb(50, 54, 60), Enum.Material.Metal, true)
	if name then
		local sign = part(m, "Sign", cf * CFrame.new(0, 12, -d / 2 - 0.4), Vector3.new(math.min(w - 8, #name * 1.8 + 6), 3, 0.4), rgb(20, 24, 32))
		Builder.sign(sign, name, Enum.NormalId.Front)
	end
	Builder.streamable(m)
	return m
end

---------------------------------------------------------------------
-- Casas
---------------------------------------------------------------------
local HOUSE_WALLS = {
	rgb(244, 238, 226), rgb(236, 220, 190), rgb(214, 190, 160), rgb(200, 216, 226), rgb(226, 206, 206),
	rgb(206, 222, 196), rgb(250, 240, 210), rgb(180, 150, 130), rgb(170, 90, 70), rgb(236, 236, 236),
}
local ROOFS = { rgb(160, 60, 44), rgb(120, 60, 48), rgb(80, 84, 92), rgb(60, 64, 70), rgb(140, 100, 70), rgb(40, 70, 110) }

-- Casa unifamiliar. opts: Floors (1-2), Garage, Porch, Flat (tejado plano)
function Lite.house(parent: Instance, cf: CFrame, w: number, d: number, opts: { [string]: any }?): Model
	opts = opts or {}
	local m = Builder.model("Casa", parent)
	local floors = opts.Floors or math.random(1, 2)
	local h = floors * 10
	local wall = pick(HOUSE_WALLS)
	local roof = pick(ROOFS)
	part(m, "Body", cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d), wall, if math.random() < 0.2 then Enum.Material.Brick else Enum.Material.Plaster)
	local flat = opts.Flat or math.random() < 0.25
	if flat then
		part(m, "Roof", cf * CFrame.new(0, h + 0.5, 0), Vector3.new(w + 1.4, 1, d + 1.4), rgb(236, 234, 228), Enum.Material.Concrete)
	else
		local rh = math.min(w, d) * 0.35
		-- Tejado a dos aguas: dos cuñas que suben hacia el centro
		Builder.part({ ClassName = "WedgePart", Name = "Roof", Size = Vector3.new(w + 1.6, rh, d / 2 + 0.8), CFrame = cf * CFrame.new(0, h + rh / 2, -d / 4 - 0.2), Color = roof, Material = Enum.Material.Slate, Parent = m })
		Builder.part({ ClassName = "WedgePart", Name = "Roof", Size = Vector3.new(w + 1.6, rh, d / 2 + 0.8), CFrame = cf * CFrame.new(0, h + rh / 2, d / 4 + 0.2) * CFrame.Angles(0, math.pi, 0), Color = roof, Material = Enum.Material.Slate, Parent = m })
		if math.random() < 0.5 then
			part(m, "Chimney", cf * CFrame.new(w / 3, h + rh * 0.7, d / 5), Vector3.new(2, rh + 2, 2), rgb(140, 90, 70), Enum.Material.Brick, true)
		end
	end
	-- Puerta y ventanas de la fachada
	part(m, "Door", cf * CFrame.new(-w / 5, 3.5, -d / 2 - 0.2), Vector3.new(3.6, 7, 0.4), rgb(90, 60, 40), Enum.Material.Wood, true)
	local glass = rgb(90, 120, 150)
	for f = 1, floors do
		part(m, "Window", cf * CFrame.new(w / 5, (f - 1) * 10 + 5.5, -d / 2 - 0.15), Vector3.new(w * 0.35, 4, 0.3), glass, Enum.Material.Glass, true)
	end
	if floors == 2 then
		part(m, "Window", cf * CFrame.new(-w / 5, 15.5, -d / 2 - 0.15), Vector3.new(w * 0.25, 4, 0.3), glass, Enum.Material.Glass, true)
	end
	-- Porche o garaje
	if opts.Porch or (opts.Porch == nil and math.random() < 0.4) then
		part(m, "Porch", cf * CFrame.new(-w / 5, 8, -d / 2 - 3), Vector3.new(8, 0.6, 6), rgb(236, 232, 224), Enum.Material.Wood, true)
		for _, x in { -3.6, 3.6 } do
			part(m, "PorchPost", cf * CFrame.new(-w / 5 + x, 4, -d / 2 - 5.6), Vector3.new(0.6, 8, 0.6), rgb(236, 232, 224), Enum.Material.Wood, true)
		end
	end
	if opts.Garage or (opts.Garage == nil and math.random() < 0.45) then
		part(m, "Garage", cf * CFrame.new(w / 2 + 6, 4.5, 0), Vector3.new(12, 9, d * 0.7), wall, Enum.Material.Plaster)
		part(m, "GarageDoor", cf * CFrame.new(w / 2 + 6, 4, -d * 0.35 - 0.2), Vector3.new(10, 7.5, 0.3), rgb(220, 220, 216), Enum.Material.DiamondPlate, true)
		part(m, "Drive", cf * CFrame.new(w / 2 + 6, 0.1, -d * 0.35 - 7), Vector3.new(10, 0.2, 14), rgb(170, 168, 164), Enum.Material.Pavement, true)
	end
	-- Camino a la puerta y un arbusto
	part(m, "Path", cf * CFrame.new(-w / 5, 0.1, -d / 2 - 7), Vector3.new(3.4, 0.2, 14), rgb(206, 196, 178), Enum.Material.Pavement, true)
	if math.random() < 0.6 then
		Nature.bush(m, (cf * CFrame.new(w / 3, 0, -d / 2 - 5)).Position)
	end
	return m
end

-- Villa de lujo: dos volúmenes blancos, grandes cristaleras, piscina y palmeras
function Lite.villa(parent: Instance, cf: CFrame, w: number, d: number): Model
	local m = Builder.model("Villa", parent)
	local white = pick({ rgb(246, 244, 238), rgb(236, 232, 224), rgb(230, 226, 214) })
	local wood = rgb(150, 110, 76)
	part(m, "Body", cf * CFrame.new(-w * 0.1, 6, d * 0.1), Vector3.new(w * 0.7, 12, d * 0.55), white, Enum.Material.Plaster)
	part(m, "Upper", cf * CFrame.new(w * 0.12, 16, d * 0.05), Vector3.new(w * 0.55, 8, d * 0.45), white, Enum.Material.Plaster)
	part(m, "Cladding", cf * CFrame.new(w * 0.12, 16, d * 0.05 - d * 0.225 - 0.2), Vector3.new(w * 0.2, 7.6, 0.3), wood, Enum.Material.Wood, true)
	part(m, "Glass", cf * CFrame.new(-w * 0.1, 5, d * 0.1 - d * 0.275 - 0.15), Vector3.new(w * 0.6, 8, 0.3), rgb(110, 160, 190), Enum.Material.Glass, true).Transparency = 0.2
	part(m, "Roof", cf * CFrame.new(-w * 0.1, 12.4, d * 0.1), Vector3.new(w * 0.72, 0.8, d * 0.58), rgb(60, 64, 70), Enum.Material.Concrete)
	part(m, "Roof", cf * CFrame.new(w * 0.12, 20.4, d * 0.05), Vector3.new(w * 0.58, 0.8, d * 0.48), rgb(60, 64, 70), Enum.Material.Concrete)
	-- Terraza con piscina delante
	local pool = cf * CFrame.new(-w * 0.05, 0, -d * 0.3)
	part(m, "Deck", pool * CFrame.new(0, 0.3, 0), Vector3.new(w * 0.75, 0.6, d * 0.26), rgb(214, 204, 186), Enum.Material.Limestone)
	part(m, "PoolWater", pool * CFrame.new(0, 0.62, 0), Vector3.new(w * 0.45, 0.1, d * 0.15), rgb(60, 170, 220), Enum.Material.Glass, true)
	for _, x in { -w * 0.4, w * 0.4 } do
		Nature.palm(m, (cf * CFrame.new(x, 0, -d * 0.38)).Position)
	end
	return m
end

-- Hotel: torre esbelta con nombre, balcones y piscina
local HOTELS = { "HOTEL MARINA", "HOTEL VALMAR", "GRAN HOTEL", "HOTEL SOL", "HOTEL COSTA", "HOTEL MIRAMAR", "HOTEL PALACE" }
function Lite.hotel(parent: Instance, cf: CFrame, w: number, d: number): Model
	local m = Lite.building(parent, cf, w, d, math.random(6, 12), { Style = pick({ "Moderno", "Clasico" }), Balconies = true, Shop = pick(HOTELS) })
	m.Name = "Hotel"
	local pool = cf * CFrame.new(w / 2 + 12, 0, 0)
	part(m, "PoolRim", pool * CFrame.new(0, 0.3, 0), Vector3.new(14, 0.6, 22), rgb(236, 232, 224), Enum.Material.Limestone)
	part(m, "PoolWater", pool * CFrame.new(0, 0.62, 0), Vector3.new(12, 0.1, 20), rgb(60, 170, 220), Enum.Material.Glass, true)
	return m
end

---------------------------------------------------------------------
-- Espacios abiertos
---------------------------------------------------------------------

-- Aparcamiento en superficie con plazas y coches
function Lite.parking(parent: Instance, cf: CFrame, w: number, d: number)
	local m = Builder.model("Aparcamiento", parent)
	part(m, "Parking", cf * CFrame.new(0, 0.15, 0), Vector3.new(w, 0.3, d), rgb(64, 66, 70), Enum.Material.Asphalt)
	for x = -w / 2 + 6, w / 2 - 6, 9 do
		for _, z in { -d / 4, d / 4 } do
			part(m, "Line", cf * CFrame.new(x, 0.32, z), Vector3.new(0.35, 0.05, d / 2 - 12), rgb(236, 236, 230), nil, true)
		end
	end
	for _ = 1, math.floor(w / 25) do
		local x = math.random(-math.floor(w / 18), math.floor(w / 18)) * 9 + 4.5
		local z = if math.random() < 0.5 then -d / 4 else d / 4
		Props.car(m, cf * CFrame.new(x, 0.3, z) * CFrame.Angles(0, math.rad(90), 0))
	end
	return m
end

-- Plaza o parque urbano: caminos, árboles, bancos, fuente
function Lite.park(parent: Instance, cf: CFrame, w: number, d: number, paved: boolean?)
	local m = Builder.model("Jardin", parent)
	local stone = rgb(214, 204, 186)
	if paved then
		part(m, "Plaza", cf * CFrame.new(0, 0.15, 0), Vector3.new(w - 6, 0.3, d - 6), rgb(214, 206, 190), Enum.Material.Pavement)
	else
		part(m, "Path", cf * CFrame.new(0, 0.15, 0), Vector3.new(6, 0.3, d - 8), stone, Enum.Material.Pavement)
		part(m, "Path", cf * CFrame.new(0, 0.16, 0), Vector3.new(w - 8, 0.3, 6), stone, Enum.Material.Pavement)
	end
	Builder.part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 16, 16), CFrame = cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(200, 196, 188), Material = Enum.Material.Limestone, Parent = m })
	Builder.decor({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 14, 14), CFrame = cf * CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 160, 210), Material = Enum.Material.Glass, Transparency = 0.2, Parent = m })
	for _ = 1, math.clamp(math.floor(w * d / 1600), 4, 30) do
		local x, z = (math.random() - 0.5) * (w - 20), (math.random() - 0.5) * (d - 20)
		if math.abs(x) > 8 and math.abs(z) > 8 then
			Nature.tree(m, (cf * CFrame.new(x, 0, z)).Position, 0.9 + math.random() * 0.5)
		end
	end
	for _, q in { { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } } do
		Props.bench(m, cf * CFrame.new(q[1] * 12, 0, q[2] * 6) * CFrame.Angles(0, if q[2] > 0 then 0 else math.pi, 0))
	end
	return m
end

return Lite
