-- Juegos: las piezas que se usan en las zonas verdes (parques vivos, Plaza Mayor, lago, huertos).
-- Cada builder recibe un CFrame EN EL SUELO (Y = la superficie) cuyo LookVector es el frente, y
-- devuelve su Model. Sin math.random (se construyen al final y no deben mover nada del mapa).
-- Pocas piezas: lo pequeño es adorno (Builder.decor) y lo que se usa lleva etiqueta para los servicios:
--
--   Juegos.swings      columpios: cada asiento (Seat «FunSwing») con su grupo «Columpio» que se mece
--                      alrededor de Pivot (ParkService); +diversión mientras te columpias (niños más)
--   Juegos.slide       tobogán: pieza «FunSlide» con TopAt/BottomAt (tirarse: subes y bajas, ParkService)
--   Juegos.seesaw      balancín: dos asientos «FunSeat» (diversión mientras estás sentado)
--   Juegos.picnicTable mesa de pícnic: «PicnicTable» («Comer de la mochila») y bancos Seat «FunSeat»
--                      dentro de un modelo «Bench» (sentado se descansa: NeedsService)
--   Juegos.dogRun      pipicán con valla, vallas de agilidad y poste «DogRunPost» («Lanzar la pelota») y
--                      su zona «DogRun» (con tu mascota dentro sube la diversión)
--   Juegos.halfCourt   media pista de baloncesto («HalfCourt» + canasta: la encuentra BasketService)
--   Juegos.campfire    hoguera «Campfire» («Tostar malvaviscos», se enciende de noche) con troncos para
--                      sentarse alrededor («FunSeat» de noche)
--   Juegos.tent        tienda de campaña: cama «CampTent» (alquilar / dormir, CampService)
--   Juegos.kiosk       quiosco con mostradores «FoodStand» (FoodService)
--   Juegos.fence       valla de madera entre dos puntos

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Parent.Builder)
local Props = require(script.Parent.Parent.Props)
local Toys = require(ReplicatedStorage.Shared.Toys)

local Juegos = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

Juegos.Colors = {
	Wood = rgb(150, 110, 76),
	DarkWood = rgb(104, 76, 52),
	Metal = rgb(70, 76, 86),
	Red = rgb(220, 70, 60),
	Yellow = rgb(245, 200, 50),
	Blue = rgb(60, 140, 220),
	Green = rgb(70, 160, 90),
	Rubber = rgb(196, 90, 70),
	Sand = rgb(226, 206, 160),
}
local C = Juegos.Colors

local function solid(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, CFrame = cf, Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function bit(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, CFrame = cf, Size = size, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

-- Pieza invisible que solo lleva un aviso o marca (no se ve, no choca)
local function marker(parent: Instance, name: string, cf: CFrame, size: Vector3, tags: { string }, attrs: { [string]: any }?): BasePart
	return Builder.part({
		Name = name,
		CFrame = cf,
		Size = size,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Tags = tags,
		Attributes = attrs,
		Parent = parent,
	})
end

-- CFrame en `at` mirando a `target` (como CFrame.lookAt; el de Lune falla mirando hacia +Z)
local function lookAt(at: Vector3, target: Vector3, up: Vector3?): CFrame
	local look = target - at
	if look.Magnitude < 1e-6 then
		return CFrame.new(at)
	end
	look = look.Unit
	local right = look:Cross(up or Vector3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.zAxis)
	end
	right = right.Unit
	return CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end
Juegos.lookAt = lookAt

-- Un poste inclinado entre dos puntos
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?, decor: boolean?): BasePart
	local mid = (a + b) / 2
	local dir = b - a
	local cf = lookAt(mid, b, if math.abs(dir.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis)
	local f = if decor then bit else solid
	return f(parent, name, cf, V(thick, thick, dir.Magnitude), color, material or Enum.Material.Metal)
end

---------------------------------------------------------------------
-- Columpios (count asientos en fila a lo largo de X)
---------------------------------------------------------------------
function Juegos.swings(parent: Instance, cf: CFrame, count: number?): Model
	local n = count or 2
	local m = Builder.model("Columpios", parent)
	local H = 8.5
	local span = n * 4 + 2
	-- Pórtico: dos A con un travesaño
	for _, x in { -span / 2, span / 2 } do
		for _, z in { -1, 1 } do
			beam(m, "Pata", (cf * CF(x, 0, z * 2.6)).Position, (cf * CF(x, H, 0)).Position, 0.45, C.Red)
		end
	end
	solid(m, "Travesano", cf * CF(0, H, 0), V(span + 0.6, 0.5, 0.5), C.Red, Enum.Material.Metal)
	for i = 1, n do
		local x = -span / 2 + 1 + (i - 0.5) * 4
		local swing = Builder.model("Columpio", m)
		local pivot = cf * CF(x, H - 0.3, 0)
		for _, dx in { -0.9, 0.9 } do
			bit(swing, "Cadena", cf * CF(x + dx, H / 2 + 1, 0), V(0.12, H - 2.6, 0.12), rgb(170, 172, 176), Enum.Material.Metal)
		end
		local seat = solid(swing, "SwingSeat", cf * CF(x, 1.75, 0), V(2.2, 0.3, 1.2), if i % 2 == 0 then C.Blue else C.Yellow, Enum.Material.Plastic, {
			ClassName = "Seat",
			CanTouch = false,
			Tags = { "FunSwing" },
			Attributes = { Pivot = pivot.Position },
		})
		seat:SetAttribute("Reason", "Swing")
	end
	return m
end

---------------------------------------------------------------------
-- Tobogán: torre con escalera por detrás y rampa hacia delante (-Z del cf = frente)
---------------------------------------------------------------------
function Juegos.slide(parent: Instance, cf: CFrame): Model
	local m = Builder.model("Tobogan", parent)
	local top = 5
	for _, x in { -1.8, 1.8 } do
		for _, z in { -1.8, 1.8 } do
			solid(m, "Poste", cf * CF(x, (top + 3) / 2, z), V(0.4, top + 3, 0.4), C.Blue, Enum.Material.Metal)
		end
	end
	solid(m, "Plataforma", cf * CF(0, top - 0.2, 0), V(4, 0.4, 4), C.Wood, Enum.Material.WoodPlanks)
	bit(m, "Tejadillo", cf * CF(0, top + 3.2, 0), V(4.6, 0.4, 4.6), C.Yellow, Enum.Material.Plastic)
	-- Escalera (detrás, +Z)
	for _, x in { -0.9, 0.9 } do
		beam(m, "Larguero", (cf * CF(x, 0, 5)).Position, (cf * CF(x, top, 2)).Position, 0.25, C.Blue, Enum.Material.Metal, true)
	end
	for k = 1, 3 do
		local t = k / 4
		bit(m, "Peldano", cf * CF(0, top * t, 5 - 3 * t), V(1.8, 0.2, 0.4), C.Metal, Enum.Material.Metal)
	end
	-- Rampa: de la plataforma (z = -2) al suelo (z = -11)
	local a, b = cf * CF(0, top - 0.1, -2), cf * CF(0, 0.6, -11)
	local mid = (a.Position + b.Position) / 2
	local len = (a.Position - b.Position).Magnitude
	local ramp = lookAt(mid, b.Position, cf.UpVector)
	solid(m, "Rampa", ramp, V(2.2, 0.3, len + 0.4), C.Yellow, Enum.Material.Plastic)
	for _, x in { -1.15, 1.15 } do
		bit(m, "Borde", ramp * CF(x, 0.4, 0), V(0.25, 0.6, len), C.Red, Enum.Material.Plastic)
	end
	-- Lo que usa ParkService: subir (TopAt) y bajar por la rampa (BottomAt)
	local spot = marker(m, "SlidePrompt", cf * CF(0, 2.5, 5.6), V(2, 2, 1), { "FunSlide" }, {
		TopAt = (cf * CF(0, top + 2.8, -0.5)).Position,
		BottomAt = (cf * CF(0, 2.8, -12.5)).Position,
	})
	spot:SetAttribute("Reason", "Slide")
	return m
end

---------------------------------------------------------------------
-- Balancín (dos asientos)
---------------------------------------------------------------------
function Juegos.seesaw(parent: Instance, cf: CFrame): Model
	local m = Builder.model("Balancin", parent)
	solid(m, "Eje", cf * CF(0, 0.9, 0), V(0.8, 1.8, 1.2), C.Metal, Enum.Material.Metal)
	solid(m, "Tabla", cf * CF(0, 1.9, 0), V(10, 0.3, 1), C.Green, Enum.Material.Plastic)
	for _, x in { -4.3, 4.3 } do
		solid(m, "Asiento", cf * CF(x, 2.2, 0), V(1.4, 0.3, 1.2), C.Red, Enum.Material.Plastic, {
			ClassName = "Seat",
			CanTouch = false,
			Tags = { "FunSeat" },
			Attributes = { FunPerMinute = 14, Reason = "Seesaw", ChildBonus = true },
		})
		bit(m, "Asa", cf * CF(x * 0.8, 3, 0), V(0.2, 1.2, 1), C.Metal, Enum.Material.Metal)
	end
	return m
end

---------------------------------------------------------------------
-- Mesa de pícnic (bancos a los dos lados a lo largo de X)
---------------------------------------------------------------------
function Juegos.picnicTable(parent: Instance, cf: CFrame): Model
	local m = Builder.model("MesaPicnic", parent)
	m:AddTag("Bench") -- sentado se descansa (NeedsService)
	local top = solid(m, "Tablero", cf * CF(0, 2.7, 0), V(8, 0.4, 3.2), C.Wood, Enum.Material.WoodPlanks, { Tags = { "PicnicTable" } })
	top:SetAttribute("Reason", "Picnic")
	for _, x in { -3, 3 } do
		bit(m, "Pata", cf * CF(x, 1.25, 0), V(0.4, 2.5, 5.6), C.DarkWood, Enum.Material.Wood)
	end
	for _, z in { -2.7, 2.7 } do
		solid(m, "Banco", cf * CF(0, 1.55, z) * CFrame.Angles(0, if z < 0 then math.pi else 0, 0), V(8, 0.35, 1.1), C.Wood, Enum.Material.WoodPlanks, {
			ClassName = "Seat",
			CanTouch = false,
			Tags = { "FunSeat" },
			Attributes = { FunPerMinute = 4, Reason = "Picnic" },
		})
	end
	return m
end

---------------------------------------------------------------------
-- Valla de madera de a hasta b (postes cada `every` y dos largueros)
---------------------------------------------------------------------
function Juegos.fence(parent: Instance, a: Vector3, b: Vector3, every: number?, color: Color3?)
	local dir = b - a
	local len = dir.Magnitude
	if len < 0.5 then
		return
	end
	local col = color or C.Wood
	local face = lookAt((a + b) / 2, b)
	for _, h in { 1.1, 2.4 } do
		solid(parent, "Larguero", face * CF(0, h, 0), V(0.25, 0.3, len), col, Enum.Material.Wood)
	end
	local posts = math.max(1, math.floor(len / (every or 8)))
	for i = 0, posts do
		local p = a + dir * (i / posts)
		bit(parent, "PosteValla", CFrame.new(p) * CF(0, 1.4, 0), V(0.4, 2.8, 0.4), C.DarkWood, Enum.Material.Wood)
	end
end

---------------------------------------------------------------------
-- Pipicán: w × d vallado, con la puerta en el frente (-Z), vallas de agilidad y el poste de la pelota
---------------------------------------------------------------------
function Juegos.dogRun(parent: Instance, cf: CFrame, w: number, d: number, opts: { [string]: any }?): Model
	local o = opts or {}
	local m = Builder.model("Pipican", parent)
	local hw, hd = w / 2, d / 2
	bit(m, "Arena", cf * CF(0, 0.08, 0), V(w - 1, 0.16, d - 1), C.Sand, Enum.Material.Sand)
	local p = function(x: number, z: number): Vector3
		return (cf * CF(x, 0, z)).Position
	end
	-- Valla: tres lados enteros y el frente con una puerta de 5 en medio
	Juegos.fence(m, p(-hw, hd), p(hw, hd), 10)
	Juegos.fence(m, p(-hw, -hd), p(-hw, hd), 10)
	Juegos.fence(m, p(hw, -hd), p(hw, hd), 10)
	Juegos.fence(m, p(-hw, -hd), p(-2.5, -hd), 10)
	Juegos.fence(m, p(2.5, -hd), p(hw, -hd), 10)
	-- Vallas de agilidad (saltos bajos)
	local hurdles = o.Hurdles or 2
	for i = 1, hurdles do
		local x = -hw + w * i / (hurdles + 1)
		for _, dz in { -1.6, 1.6 } do
			bit(m, "PosteSalto", cf * CF(x, 0.8, dz), V(0.3, 1.6, 0.3), C.Blue, Enum.Material.Plastic)
		end
		bit(m, "Salto", cf * CF(x, 1.2, 0), V(0.2, 0.2, 3.2), C.Yellow, Enum.Material.Plastic)
	end
	if o.Tunnel then
		Builder.decor({ Name = "Tunel", Shape = Enum.PartType.Cylinder, Size = V(6, 2.6, 2.6), CFrame = cf * CF(0, 1.3, hd * 0.5), Color = C.Red, Material = Enum.Material.Fabric, Transparency = 0.15, Parent = m })
	end
	-- Fuente para perros
	solid(m, "Fuente", cf * CF(hw - 2, 0.6, hd - 2), V(1.6, 1.2, 1.6), C.Metal, Enum.Material.Metal)
	-- La zona (con tu mascota dentro sube la diversión) y el poste con la pelota junto a la puerta
	marker(m, "DogRun", cf * CF(0, 4, 0), V(w, 8, d), { "DogRun" })
	local post = solid(m, "PostePelota", cf * CF(-4.5, 1.6, -hd + 1.6), V(0.6, 3.2, 0.6), C.Green, Enum.Material.Wood, { Tags = { "DogRunPost" } })
	post:SetAttribute("Reason", "Fetch")
	bit(m, "CestaPelotas", cf * CF(-4.5, 3.4, -hd + 1.6), V(1.4, 0.6, 1.4), C.Yellow, Enum.Material.Fabric)
	-- Cartel
	local board = solid(m, "Cartel", cf * CF(4.5, 3.4, -hd - 0.2), V(5, 1.6, 0.2), rgb(40, 100, 70), Enum.Material.Wood)
	Builder.sign(board, o.Title or "🐾 PIPICÁN", Enum.NormalId.Front)
	bit(m, "PosteCartel", cf * CF(4.5, 1.3, -hd - 0.2), V(0.3, 2.6, 0.3), C.DarkWood, Enum.Material.Wood)
	return m
end

---------------------------------------------------------------------
-- Media pista de baloncesto: suelo «HalfCourt» de w × d con la canasta en el fondo (+Z)
---------------------------------------------------------------------
function Juegos.halfCourt(parent: Instance, cf: CFrame, w: number?, d: number?): Model
	local m = Builder.model("MediaPista", parent)
	local W, D = w or 22, d or 20
	solid(m, "HalfCourt", cf * CF(0, 0.21, 0), V(W, 0.42, D), rgb(56, 128, 96), Enum.Material.Concrete)
	bit(m, "Linea", cf * CF(0, 0.44, -D / 2 + 0.3), V(W, 0.05, 0.4), rgb(240, 240, 240))
	bit(m, "Zona", cf * CF(0, 0.44, D / 2 - 4), V(6, 0.05, 8), rgb(200, 90, 60))
	-- La canasta mira hacia el centro de la pista (como Civic.hoop)
	local base = cf * CF(0, 0.42, D / 2 - 1) -- (mira hacia el centro de la pista: -Z)
	solid(m, "HoopPost", base * CF(0, 5, 1), V(0.5, 10, 0.5), C.Metal, Enum.Material.Metal)
	bit(m, "Backboard", base * CF(0, 10, 0), V(6, 3.6, 0.3), rgb(250, 250, 250))
	bit(m, "Rim", base * CF(0, 9, -1.3) * CFrame.Angles(0, 0, math.rad(90)), V(0.2, 2, 2), rgb(230, 90, 30), nil, { Shape = Enum.PartType.Cylinder })
	Toys.make("Baloncesto", cf * CF(W / 2 - 2, 1.1, -D / 2 + 2), m)
	return m
end

---------------------------------------------------------------------
-- Hoguera con troncos alrededor (radius)
---------------------------------------------------------------------
function Juegos.campfire(parent: Instance, cf: CFrame, seats: number?, radius: number?): Model
	local m = Builder.model("Hoguera", parent)
	local r = radius or 7
	Builder.part({ Name = "Piedras", Shape = Enum.PartType.Cylinder, Size = V(0.8, 5, 5), CFrame = cf * CF(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(110, 106, 100), Material = Enum.Material.Slate, Parent = m })
	for k = 0, 1 do
		bit(m, "Lena", cf * CF(0, 1, 0) * CFrame.Angles(0, k * math.pi / 2, math.rad(18)), V(3.4, 0.5, 0.5), C.DarkWood, Enum.Material.Wood)
	end
	local fire = bit(m, "Fuego", cf * CF(0, 1.6, 0), V(1.6, 1.8, 1.6), rgb(255, 140, 40), Enum.Material.Neon, { Tags = { "Campfire" }, Transparency = 0.2 })
	fire:SetAttribute("Reason", "Campfire")
	local light = Instance.new("PointLight")
	light.Name = "Luz"
	light.Color = rgb(255, 150, 70)
	light.Range = 22
	light.Brightness = 2
	light.Shadows = false
	light.Parent = fire
	local n = seats or 4
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local at = cf * CFrame.Angles(0, a, 0) * CF(0, 0, -r)
		-- Tronco para sentarse mirando al fuego
		Builder.part({
			ClassName = "Seat",
			Name = "Tronco",
			Size = V(4.5, 1.1, 1.3),
			CFrame = at * CF(0, 0.55, 0) * CFrame.Angles(0, math.pi, 0),
			Color = rgb(120, 86, 58),
			Material = Enum.Material.Wood,
			CanTouch = false,
			Tags = { "FunSeat" },
			Attributes = { FunPerMinute = 10, Reason = "Campfire", NightOnly = true, EnergyPerMinute = 3 },
			Parent = m,
		})
	end
	return m
end

---------------------------------------------------------------------
-- Tienda de campaña (la puerta mira a -Z): dos lonas y la cama «CampTent» dentro
---------------------------------------------------------------------
function Juegos.tent(parent: Instance, cf: CFrame, color: Color3, id: string, rented: boolean?): Model
	local m = Builder.model("Tienda", parent)
	-- (como las del Camping: la cumbrera a lo largo de Z, abierta por delante y por detrás)
	local ridge = cf * CFrame.Angles(0, math.pi / 2, 0)
	solid(m, "Lona", ridge * CF(0, 2.5, -2), V(8, 5, 4), color, Enum.Material.Fabric, { ClassName = "WedgePart" })
	solid(m, "Lona", ridge * CF(0, 2.5, 2) * CFrame.Angles(0, math.pi, 0), V(8, 5, 4), color, Enum.Material.Fabric, { ClassName = "WedgePart" })
	marker(m, "CamaTienda", cf * CF(0, 1, -4.6), V(3, 2, 2), { "CampTent" }, { TentId = id, Rented = rented == true, LieAt = (cf * CF(0, 1.2, 0)).Position })
	return m
end

---------------------------------------------------------------------
-- Quiosco con dos mostradores de comida (FoodService: FoodStand + FoodId)
---------------------------------------------------------------------
function Juegos.kiosk(parent: Instance, cf: CFrame, title: string, foods: { string }, color: Color3?): Model
	local m = Builder.model("Quiosco", parent)
	local col = color or rgb(90, 170, 200)
	solid(m, "Caseta", cf * CF(0, 3.5, 2), V(8, 7, 5), rgb(240, 236, 226), Enum.Material.SmoothPlastic)
	solid(m, "Mostrador", cf * CF(0, 1.7, -1.2), V(8, 3.4, 1.4), col, Enum.Material.SmoothPlastic)
	bit(m, "Toldo", cf * CF(0, 7.3, -1.6) * CFrame.Angles(math.rad(-15), 0, 0), V(8.8, 0.3, 3.4), col, Enum.Material.Fabric)
	local board = solid(m, "Rotulo", cf * CF(0, 8.4, -0.5), V(8, 1.4, 0.3), col, Enum.Material.SmoothPlastic)
	Builder.sign(board, title, Enum.NormalId.Front)
	for i, foodId in foods do
		local x = -2 + (i - 1) * 4
		solid(m, "Food_" .. foodId, cf * CF(x, 3.9, -1.2), V(1.4, 1, 1.2), rgb(250, 250, 250), Enum.Material.SmoothPlastic, {
			Tags = { "FoodStand" },
			Attributes = { FoodId = foodId },
		})
	end
	return m
end

-- Banco de los de siempre (Props.bench) mirando a `look`
function Juegos.bench(parent: Instance, cf: CFrame): Instance?
	return Props.bench(parent, cf)
end

return Juegos
