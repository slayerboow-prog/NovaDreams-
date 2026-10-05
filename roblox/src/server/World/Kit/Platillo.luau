-- Platillo: la nave de las misiones locas («Una nave del tamaño de una furgoneta aterriza en medio
-- del patio»), hecha con piezas. Antes era un disco plano flotando a 14 studs: desde la cámara del
-- móvil no se veía y en el suelo solo quedaba la caja de globos (un cubo azul).
--
--   Platillo.build(opts) -> Model   (piezas alrededor del origen; el suelo en y = 0; la rampa hacia -Z)
--     opts.Aterriza  true: posada en el suelo con patas y rampa (la de las cucarachas); si no, flotando
--     opts.Height    altura a la que flota (sin Aterriza)
--     opts.Beam      false: sin rayo tractor (flotando)
--     opts.Hum       SoundId del zumbido (el que lo llama lo saca de SoundIds)
--     opts.Pilot     color del piloto que se ve en la cúpula (nil = sin piloto)
--
-- Lo mueve el cliente (Controllers/Platillos, etiqueta "Platillo"): baja del cielo, levanta polvo y
-- luz al posarse, abre la rampa, zumba y las luces del borde corren en círculo. Sin el cliente (o
-- antes de que llegue) se ve ya posada y con la rampa abierta.
--
-- Sin require: lo prueba scripts/test-cucarachas.luau con Lune.

local Platillo = {}

Platillo.TAG = "Platillo"
Platillo.DIAMETRO = 20 -- como una furgoneta de larga
Platillo.LUCES = 12

local V = Vector3.new
local C = CFrame.new
local rgb = Color3.fromRGB

local METAL = rgb(186, 192, 204)
local OSCURO = rgb(70, 76, 92)
local CUPULA = rgb(140, 235, 255)
local BRILLO = rgb(120, 255, 210)
local LUZ_A = rgb(255, 226, 90)
local LUZ_B = rgb(255, 90, 210)

local function piece(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Elipsoide (una pieza con malla de esfera: toma la forma de su tamaño)
local function ellipsoid(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = piece(model, name, size, cf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Disco (cilindro con el eje en vertical)
local function disc(model: Model, name: string, diameter: number, thick: number, y: number, color: Color3, material: Enum.Material?): Part
	return piece(model, name, V(thick, diameter, diameter), C(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- Barra (cilindro) de a hasta b
local function strut(model: Model, name: string, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?): Part
	local dir = (b - a).Unit
	local ref = if math.abs(dir.Y) > 0.95 then V(1, 0, 0) else V(0, 1, 0)
	local up = (ref - dir * dir:Dot(ref)).Unit
	return piece(model, name, V((b - a).Magnitude, thick, thick), CFrame.fromMatrix((a + b) / 2, dir, up), color, material, Enum.PartType.Cylinder)
end

-- Las cuentas de la rampa: bisagra bajo el casco (lado -Z) y cuánto baja hasta el suelo
function Platillo.rampa(hullY: number): (CFrame, number, number)
	local hingeY = hullY - 1.3
	local length = 6.2
	local hinge = C(0, hingeY, -6.2)
	-- Abierta: baja hasta el suelo (ángulo desde la horizontal)
	local open = math.asin(math.clamp((hingeY - 0.15) / length, 0, 1))
	return hinge, length, open
end

-- CFrame de la rampa: t = 0 cerrada (de pie, metida en el casco: es la puerta) y t = 1 abierta (se
-- abre como un puente levadizo hacia fuera, -Z, hasta apoyarse en el suelo con el ángulo «open»)
function Platillo.rampaCFrame(hinge: CFrame, length: number, t: number, open: number): CFrame
	local angle = -math.pi / 2 - math.clamp(t, 0, 1) * (math.pi / 2 + open)
	return hinge * CFrame.Angles(angle, 0, 0) * C(0, 0, length / 2)
end

function Platillo.build(opts: { [string]: any }?): Model
	local o = opts or {}
	local model = Instance.new("Model")
	model.Name = "Platillo"
	local landed = o.Aterriza == true
	local D = Platillo.DIAMETRO
	-- Altura del centro del casco: posada, sobre las patas (la panza a ~2,6 studs del suelo)
	local hullY = if landed then 4.2 else (o.Height or 18)

	-- Casco: un platillo de dos piezas (abajo más plano), anillo del borde y la cúpula de cristal
	local hull = ellipsoid(model, "Casco", V(D, 3.4, D), C(0, hullY, 0), METAL, Enum.Material.Metal)
	hull.Reflectance = 0.15
	ellipsoid(model, "CascoAlto", V(D * 0.68, 3.2, D * 0.68), C(0, hullY + 1.1, 0), METAL:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Metal)
	disc(model, "Anillo", D + 0.6, 0.55, hullY, OSCURO, Enum.Material.Metal)
	ellipsoid(model, "Panza", V(D * 0.55, 2.2, D * 0.55), C(0, hullY - 1.1, 0), OSCURO, Enum.Material.DiamondPlate)
	local glow = disc(model, "Motor", D * 0.3, 0.3, hullY - 2.15, BRILLO, Enum.Material.Neon)
	local engine = Instance.new("PointLight")
	engine.Name = "LuzMotor"
	engine.Color = BRILLO
	engine.Range = 16
	engine.Brightness = 2
	engine.Parent = glow
	local dome = piece(model, "Cupula", V(7.5, 7.5, 7.5), C(0, hullY + 2.1, 0), CUPULA, Enum.Material.Glass, Enum.PartType.Ball)
	dome.Transparency = 0.45
	dome.Reflectance = 0.2
	piece(model, "AntenaCupula", V(0.25, 1.8, 0.25), C(0, hullY + 6.6, 0), OSCURO, Enum.Material.Metal)
	local tip = piece(model, "PuntaAntena", V(0.7, 0.7, 0.7), C(0, hullY + 7.6, 0), LUZ_B, Enum.Material.Neon, Enum.PartType.Ball)
	tip:SetAttribute("Parpadea", true)

	-- El piloto en la cúpula (una cucaracha con gorra de capitán, mirando hacia la rampa)
	if o.Pilot then
		local skin: Color3 = o.Pilot
		local seat = C(0, hullY + 2.2, 0)
		ellipsoid(model, "PilotoCuerpo", V(1.8, 2.4, 1.4), seat, skin, Enum.Material.SmoothPlastic)
		ellipsoid(model, "PilotoCabeza", V(1.3, 1.1, 1.2), seat * C(0, 1.5, -0.2), skin:Lerp(Color3.new(0, 0, 0), 0.2))
		for _, s in { -1, 1 } do
			piece(model, "PilotoOjo", V(0.38, 0.38, 0.38), seat * C(s * 0.32, 1.65, -0.72), rgb(250, 250, 250), Enum.Material.Neon, Enum.PartType.Ball)
			strut(model, "PilotoAntena", (seat * C(s * 0.25, 1.9, -0.5)).Position, (seat * C(s * 0.9, 3.3, -1.3)).Position, 0.1, skin)
		end
		piece(model, "PilotoGorra", V(1.3, 0.35, 1.3), seat * C(0, 2.1, -0.1), rgb(40, 50, 120), Enum.Material.Fabric)
	end

	-- Luces del borde (el cliente las hace correr en círculo)
	for i = 1, Platillo.LUCES do
		local a = (i - 1) / Platillo.LUCES * math.pi * 2
		local r = D / 2 + 0.1
		local light = piece(model, "LuzBorde", V(0.9, 0.9, 0.9), C(math.cos(a) * r, hullY, math.sin(a) * r), if i % 2 == 0 then LUZ_A else LUZ_B, Enum.Material.Neon, Enum.PartType.Ball)
		light:SetAttribute("Luz", i)
	end
	-- Ventanillas alrededor del casco alto
	for i = 1, 8 do
		local a = (i - 0.5) / 8 * math.pi * 2
		local r = D * 0.3
		local w = piece(model, "Ventanilla", V(0.2, 0.7, 1.4), C(math.cos(a) * r, hullY + 1.35, math.sin(a) * r) * CFrame.Angles(0, -a, 0), CUPULA, Enum.Material.Neon)
		w.Transparency = 0.15
	end

	if landed then
		-- Cuatro patas de aterrizaje (en diagonal: la rampa sale entre dos de ellas, hacia -Z)
		for i = 0, 3 do
			local a = math.rad(45 + i * 90)
			local top = V(math.cos(a) * 5.2, hullY - 1.2, math.sin(a) * 5.2)
			local foot = V(math.cos(a) * 7.6, 0.45, math.sin(a) * 7.6)
			strut(model, "Pata", top, foot, 0.55, OSCURO, Enum.Material.Metal)
			strut(model, "Amortiguador", top:Lerp(foot, 0.25), top:Lerp(foot, 0.6), 0.85, METAL, Enum.Material.Metal)
			piece(model, "Pie", V(0.35, 2, 2), C(foot.X, 0.18, foot.Z) * CFrame.Angles(0, 0, math.rad(90)), OSCURO, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		-- Rampa (abierta: el cliente la cierra mientras baja y la abre al posarse)
		local hinge, length, open = Platillo.rampa(hullY)
		local ramp = piece(model, "Rampa", V(4.4, 0.3, length), Platillo.rampaCFrame(hinge, length, 1, open), METAL, Enum.Material.DiamondPlate)
		ramp:SetAttribute("Bisagra", hinge)
		ramp:SetAttribute("Largo", length)
		ramp:SetAttribute("Abierta", open)
		for _, s in { -1, 1 } do
			local rail = piece(model, "BordeRampa", V(0.2, 0.25, length), ramp.CFrame * C(s * 2.15, 0.2, 0), BRILLO, Enum.Material.Neon)
			rail:SetAttribute("Rampa", true)
		end
		-- La puerta: luz que sale de dentro
		local door = piece(model, "Puerta", V(4.2, 0.2, 2.6), hinge * C(0, 0.25, 1.4), rgb(255, 250, 220), Enum.Material.Neon)
		local doorLight = Instance.new("SpotLight")
		doorLight.Name = "LuzPuerta"
		doorLight.Face = Enum.NormalId.Bottom
		doorLight.Angle = 70
		doorLight.Range = 14
		doorLight.Brightness = 3
		doorLight.Color = rgb(255, 245, 210)
		doorLight.Parent = door
		-- Polvo al posarse y destello (el cliente los dispara)
		local ground = piece(model, "Suelo", V(D, 0.2, D), C(0, 0.1, 0), OSCURO)
		ground.Transparency = 1
		local dust = Instance.new("ParticleEmitter")
		dust.Name = "Polvo"
		dust.Enabled = false
		dust.Color = ColorSequence.new(rgb(206, 190, 160))
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		dust.Lifetime = NumberRange.new(1.2, 2.2)
		dust.Speed = NumberRange.new(10, 18)
		dust.SpreadAngle = Vector2.new(180, 8)
		dust.Drag = 3
		dust.Rate = 0
		dust.Parent = ground
		local flash = Instance.new("PointLight")
		flash.Name = "Destello"
		flash.Color = BRILLO
		flash.Range = 30
		flash.Brightness = 0
		flash.Parent = ground
	elseif o.Beam ~= false then
		-- Rayo tractor (flotando)
		local beam = piece(model, "Rayo", V(hullY, 8, 8), C(0, hullY / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), BRILLO, Enum.Material.Neon, Enum.PartType.Cylinder)
		beam.Transparency = 0.75
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Color = BRILLO
		light.Range = hullY + 10
		light.Brightness = 4
		light.Parent = hull
	end

	-- Zumbido (bajo y continuo)
	if o.Hum then
		local hum = Instance.new("Sound")
		hum.Name = "Zumbido"
		hum.SoundId = o.Hum
		hum.Looped = true
		hum.Volume = 0.5
		hum.PlaybackSpeed = 0.42
		hum.RollOffMaxDistance = 90
		hum.Parent = hull
	end

	model:SetAttribute("Aterriza", landed)
	model:SetAttribute("AlturaCasco", hullY)
	model:AddTag(Platillo.TAG)
	return model
end

return Platillo
