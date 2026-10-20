-- FutureCar: el coche deportivo futurista (el «Cometa 66» de Cosme) hecho con piezas, para ponerlo
-- de adorno donde haga falta: el garaje de la casa de Cosme, el garaje del sótano (el de los
-- portales) y las misiones que lo necesiten (FutureCar.build devuelve el modelo; nada más).
--
--   * Carrocería lisa y baja: elipsoides (piezas con malla de esfera estirada) para el casco, los
--     pasos de rueda, el morro, el capó, la zaga y la cúpula de cristal; cuñas y cajas solo para el
--     alerón, el difusor y el splitter.
--   * Pintura plata perla con reflejo, cristal tintado con reflejo, tiras de luz azules (faros, costados,
--     piloto trasero), luz por debajo y ruedas de verdad: neumático, llanta con radios y tapacubos.
--   * No choca (salvo una caja invisible del tamaño del coche, para que no se atraviese); lo pequeño
--     lleva la etiqueta CityDetail (el nivel gráfico Bajo lo esconde). Luces: como mucho dos, y quien
--     lo construye puede pasarlas por su tope (opts.Light).
--
-- No usa las carrocerías de malla de World/Kit/CarBodies: esas se cargan de los packs al arrancar el
-- servidor (en Lune no hay) y visten coches de CarModel, no adornos; este se ve igual en todas partes.
--
-- cf: centro del coche a ras de suelo (en el mundo), con el morro hacia -Z.

local Builder = require(script.Parent.Parent.Builder)

local FutureCar = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material

FutureCar.Length = 13.4
FutureCar.Width = 6.4
FutureCar.Height = 3.95
FutureCar.Paint = rgb(214, 221, 232) -- plata perla
FutureCar.Accent = rgb(70, 190, 255) -- tiras azules
FutureCar.Glass = rgb(28, 46, 66)

export type Opts = {
	Name: string?,
	Paint: Color3?,
	Accent: Color3?,
	Tail: Color3?,
	Plate: string?,
	-- (parte, alcance, brillo, color, tipo "Point" | "Spot") -> crea la luz o no (tope de luces)
	Light: ((BasePart, number, number, Color3, string) -> any)?,
	NoLights: boolean?,
}

local function decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, small: boolean?): BasePart
	local p = Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Parent = parent })
	if small then
		p:AddTag("CityDetail")
	end
	return p
end

local function ellipsoid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, small: boolean?): BasePart
	local p = decor(parent, name, size, cf, color, material, small)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function cylinderX(parent: Instance, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, small: boolean?): BasePart
	local p = decor(parent, name, V(length, diameter, diameter), cf, color, material, small)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function neon(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number?): BasePart
	local p = decor(parent, name, size, cf, color, M.Neon)
	p.CastShadow = false
	p.Transparency = transparency or 0
	return p
end

local function wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.part({ ClassName = "WedgePart", Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent })
end

-- Una rueda (centro en c, el lado de fuera hacia side = ±1 en X)
local function wheel(parent: Instance, c: CFrame, side: number, accent: Color3)
	local m = Instance.new("Model")
	m.Name = "Rueda"
	m.Parent = parent
	cylinderX(m, "Neumatico", 1.05, 2.5, c, rgb(24, 24, 28), M.Rubber)
	local rim = cylinderX(m, "Llanta", 1.09, 1.82, c, rgb(200, 206, 214), M.Metal)
	rim.Reflectance = 0.3
	cylinderX(m, "LlantaFondo", 1.12, 1.32, c, rgb(36, 38, 44), M.Metal)
	-- Cinco radios en la cara de fuera
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		local spoke = decor(m, "Radio", V(0.14, 0.62, 0.24), c * CF(side * 0.5, 0, 0) * ANG(a, 0, 0) * CF(0, 0.42, 0), rgb(214, 218, 226), M.Metal, true)
		spoke.Reflectance = 0.3
	end
	cylinderX(m, "Tapacubos", 1.2, 0.5, c, accent, M.Neon, true)
	-- Pinza de freno (asoma por los radios)
	decor(m, "Pinza", V(0.3, 0.7, 0.5), c * CF(side * 0.3, 0.45, 0.35), accent:Lerp(rgb(255, 255, 255), 0.2), M.SmoothPlastic, true)
	return m
end

function FutureCar.build(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local paint = o.Paint or FutureCar.Paint
	local accent = o.Accent or FutureCar.Accent
	local tail = o.Tail or rgb(255, 60, 110)
	local m = Instance.new("Model")
	m.Name = o.Name or "CocheFuturista"
	m:AddTag("FutureCar")
	m:SetAttribute("Kit", "FutureCar")
	m.Parent = parent
	local body = Instance.new("Model")
	body.Name = "Carroceria"
	body.Parent = m
	local function at(x: number, y: number, z: number): CFrame
		return cf * CF(x, y, z)
	end
	local function shine(p: BasePart, r: number)
		p.Reflectance = r
		return p
	end

	-- Bajos (fibra de carbono) y casco principal
	decor(body, "Bajos", V(5.2, 0.5, 11.6), at(0, 0.95, 0), rgb(30, 32, 38), M.SmoothPlastic)
	shine(ellipsoid(body, "Casco", V(6.1, 2.2, 13.4), at(0, 1.75, 0), paint, M.SmoothPlastic), 0.25)
	-- Pasos de rueda musculosos
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			shine(ellipsoid(body, "PasoRueda", V(1.9, 1.8, 4.3), at(sx * 2.55, 1.85, sz * 4.2), paint, M.SmoothPlastic), 0.25)
		end
	end
	-- Morro bajo, capó esculpido, zaga y techo
	shine(ellipsoid(body, "Morro", V(5.4, 1.1, 3.2), at(0, 1.2, -5.8), paint, M.SmoothPlastic), 0.25)
	shine(ellipsoid(body, "Capo", V(4.6, 0.9, 6.2), at(0, 2.3, -3.1), paint, M.SmoothPlastic), 0.25)
	shine(ellipsoid(body, "Zaga", V(5.5, 1.5, 4.4), at(0, 2.2, 4.4), paint, M.SmoothPlastic), 0.25)
	-- Cúpula de cristal tintado (y la «espina» del techo)
	local canopy = ellipsoid(body, "Cupula", V(4.3, 2.4, 6.6), at(0, 2.75, 0.6), FutureCar.Glass, M.Glass)
	canopy.Transparency = 0.2
	canopy.Reflectance = 0.45
	shine(ellipsoid(body, "Techo", V(1.1, 0.4, 5), at(0, 3.85, 0.8), paint, M.SmoothPlastic), 0.25)
	-- Retrovisores
	for _, sx in { -1, 1 } do
		shine(ellipsoid(body, "Retrovisor", V(0.8, 0.45, 0.9), at(sx * 2.35, 2.75, -1.7), paint, M.SmoothPlastic, true), 0.25)
	end
	-- Splitter, tomas de aire, faldones, difusor y alerón
	decor(body, "Splitter", V(5.6, 0.18, 1.1), at(0, 0.72, -6.5), rgb(26, 28, 34), M.SmoothPlastic)
	for _, sx in { -1, 1 } do
		decor(body, "TomaAire", V(1.4, 0.35, 0.3), at(sx * 1.6, 1.05, -6.6), rgb(20, 22, 28), M.SmoothPlastic, true)
		decor(body, "Faldon", V(0.4, 0.45, 5.2), at(sx * 2.85, 0.85, 0), rgb(26, 28, 34), M.SmoothPlastic)
		decor(body, "Soporte", V(0.2, 0.9, 0.45), at(sx * 1.8, 2.95, 5.8), rgb(26, 28, 34), M.Metal, true)
		wedge(body, "Deriva", V(0.15, 0.7, 1.2), at(sx * 2.75, 3.6, 6.0), paint, M.SmoothPlastic)
	end
	decor(body, "Difusor", V(5, 0.5, 0.8), at(0, 0.9, 6.55), rgb(26, 28, 34), M.SmoothPlastic)
	shine(decor(body, "Aleron", V(5.6, 0.18, 1.2), at(0, 3.45, 6.0) * ANG(math.rad(-6), 0, 0), paint, M.SmoothPlastic), 0.25)

	-- Luces: faros afilados, barra de día, tiras de los costados, piloto trasero y luz de bajos
	local lights = Instance.new("Model")
	lights.Name = "Luces"
	lights.Parent = m
	for _, sx in { -1, 1 } do
		neon(lights, "Faro", V(1.7, 0.16, 0.3), at(sx * 1.75, 1.75, -6.05) * ANG(0, sx * -0.35, 0), rgb(220, 240, 255))
		neon(lights, "TiraCostado", V(0.1, 0.12, 5), at(sx * 3.06, 1.15, 0), accent, 0.05)
		neon(lights, "TiraCintura", V(0.08, 0.08, 4.6), at(sx * 2.12, 2.72, 0.6), accent, 0.1)
		neon(lights, "Piloto", V(1.1, 0.18, 0.12), at(sx * 2.0, 2.15, 6.45) * ANG(0, sx * 0.3, 0), tail)
	end
	neon(lights, "BarraDia", V(3.2, 0.08, 0.1), at(0, 1.48, -6.62), accent)
	neon(lights, "BarraTrasera", V(3.4, 0.1, 0.1), at(0, 2.3, 6.6), accent)
	local under = neon(lights, "LuzBajos", V(4.6, 0.08, 9.6), at(0, 0.42, 0), accent, 0.35)

	-- Ruedas
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			wheel(m, at(sx * 2.75, 1.25, sz * 4.2), sx, accent)
		end
	end

	-- Matrícula
	if o.Plate then
		local plate = decor(body, "Matricula", V(2, 0.5, 0.08), at(0, 1.3, 6.95), rgb(240, 240, 236), M.SmoothPlastic, true)
		Builder.sign(plate, o.Plate, Enum.NormalId.Back, rgb(30, 34, 44), rgb(240, 240, 236))
	end

	-- Caja de choque invisible (no se atraviesa) y luces
	Builder.part({ Name = "CarHitbox", Size = V(5.6, 2.6, 12.6), CFrame = at(0, 1.6, 0), Transparency = 1, CanCollide = true, CanQuery = false, CanTouch = false, CastShadow = false, Parent = m })
	if not o.NoLights then
		local front = neon(lights, "FocoDelantero", V(0.4, 0.4, 0.1), at(0, 1.4, -6.7), rgb(220, 240, 255), 1)
		if o.Light then
			o.Light(under, 12, 1.2, accent, "Point")
			o.Light(front, 18, 1, rgb(220, 240, 255), "Spot")
		else
			local glow = Instance.new("PointLight")
			glow.Range = 12
			glow.Brightness = 1.2
			glow.Color = accent
			glow.Shadows = false
			glow.Parent = under
		end
	end
	return m
end

-- ¿Es un coche de este kit? (para la prueba y para las misiones)
function FutureCar.is(model: Instance): boolean
	return model:IsA("Model") and model:HasTag("FutureCar")
end

return FutureCar
