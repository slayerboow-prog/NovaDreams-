-- Cucaracha: las cucarachas cazarrecompensas del planeta Crujiente (Loco_N2_Bigotes, Aliados), hechas
-- con piezas. Antes eran personas de color marrón con un brillo: «no parecen enemigos de verdad».
--
--   Cucaracha.build(length, at?, opts?) -> Model  (de la cabeza a la punta del abdomen; patas en y = 0,
--       la cabeza hacia -Z). Seis patas de dos tramos y dos antenas largas, con articulaciones (Motor6D)
--       que mueve el cliente (Controllers/Cucarachas): las patas corretean al andar, las antenas se
--       agitan, y el cuerpo tiembla un poco.
--       opts = { Color, Gorra (color de la gorra del sargento), Medallas (número) }
--   Cucaracha.costume(rig, opts?) -> Model?  disfraza a un personaje (Humanoid): el cuerpo de persona
--       no se ve (sigue andando, persiguiendo y recibiendo los disparos) y la cucaracha va soldada a sus pies.
--
-- Las piezas de la cucaracha se pueden tocar con un disparo (CanQuery): la pistola de agua le da.
-- Sin require: lo prueba scripts/test-cucarachas.luau con Lune.

local Cucaracha = {}

Cucaracha.TAG = "Cucaracha"
Cucaracha.LARGO_DISFRAZ = 7 -- (antes de encoger al personaje: con un niño, unos 4,5 studs)

local V = Vector3.new
local C = CFrame.new
local rgb = Color3.fromRGB

type Ctx = { model: Model, at: CFrame, k: number }

local function piece(ctx: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: string?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size * ctx.k
	p.CFrame = ctx.at * (cf.Rotation + cf.Position * ctx.k)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	elseif shape == "Ellipsoid" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true -- (los disparos le dan)
	p.Massless = true
	p.CastShadow = false
	p.Parent = ctx.model
	return p
end

-- Cilindro de a hasta b (coordenadas del dibujo)
local function strut(ctx: Ctx, name: string, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?): BasePart
	local dir = (b - a).Unit
	local ref = if math.abs(dir.Y) > 0.95 then V(1, 0, 0) else V(0, 1, 0)
	local up = (ref - dir * dir:Dot(ref)).Unit
	return piece(ctx, name, V((b - a).Magnitude, thick, thick), CFrame.fromMatrix((a + b) / 2, dir, up), color, material, "Cylinder")
end

local function weld(part0: BasePart, part1: BasePart)
	local w = Instance.new("Weld")
	w.Name = "Soldadura"
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = part0.CFrame:Inverse() * part1.CFrame
	w.C1 = CFrame.new()
	w.Parent = part1
end

-- Articulación que el cliente mueve (gira alrededor de pivot, en coordenadas del dibujo)
local function joint(ctx: Ctx, name: string, part0: BasePart, part1: BasePart, pivot: Vector3)
	local world = ctx.at * C(pivot * ctx.k)
	local m = Instance.new("Motor6D")
	m.Name = "M_" .. name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:Inverse() * world
	m.C1 = part1.CFrame:Inverse() * world
	m.Parent = part0
end

-- Las seis patas: { nombre, z del arranque (en el tórax), cuánto se abren hacia delante/atrás }
Cucaracha.PATAS = {
	{ "Delantera", -0.9, -1.1 },
	{ "Media", -0.1, 0.1 },
	{ "Trasera", 0.7, 1.4 },
}

function Cucaracha.build(length: number, at: CFrame?, opts: { [string]: any }?): Model
	local o = opts or {}
	local model = Instance.new("Model")
	model.Name = "Cucaracha"
	-- Dibujo de 7 unidades de largo (cabeza en z = -3,4 y punta del abdomen en z = +3,6)
	local ctx: Ctx = { model = model, at = at or CFrame.new(), k = length / 7 }
	local shell: Color3 = o.Color or rgb(120, 70, 36)
	local dark = shell:Lerp(Color3.new(0, 0, 0), 0.45)
	local light = shell:Lerp(rgb(255, 210, 150), 0.35)
	local bodyY = 1.25

	-- Raíz (invisible): lo que se suelda al personaje
	local raiz = piece(ctx, "Raiz", V(1, 1, 1), C(0, bodyY, 0), shell)
	raiz.Transparency = 1
	model.PrimaryPart = raiz

	-- Cuerpo: tórax, abdomen con anillos, élitros brillantes con la raya del medio, pronoto y cabeza
	local cuerpo = piece(ctx, "Torax", V(2.4, 1.1, 2.2), C(0, bodyY, -0.3), shell, Enum.Material.SmoothPlastic, "Ellipsoid")
	local partes = {}
	table.insert(partes, piece(ctx, "Abdomen", V(2.8, 1.2, 3.8), C(0, bodyY - 0.05, 1.6), dark, Enum.Material.SmoothPlastic, "Ellipsoid"))
	for i, z in { 0.8, 1.6, 2.4 } do
		table.insert(partes, piece(ctx, "Anillo" .. i, V(2.7 - i * 0.3, 0.12, 0.25), C(0, bodyY - 0.45, z), light, Enum.Material.SmoothPlastic))
	end
	for _, s in { -1, 1 } do
		local elytra = piece(ctx, "Elitro", V(1.45, 0.5, 4.4), C(s * 0.62, bodyY + 0.42, 1.1) * CFrame.Angles(0, s * math.rad(-4), s * math.rad(-10)), shell, Enum.Material.Glass, "Ellipsoid")
		elytra.Reflectance = 0.25
		table.insert(partes, elytra)
	end
	table.insert(partes, piece(ctx, "Raya", V(0.06, 0.08, 3.9), C(0, bodyY + 0.68, 1.1), dark, Enum.Material.SmoothPlastic))
	table.insert(partes, piece(ctx, "Pronoto", V(2.3, 0.7, 1.5), C(0, bodyY + 0.25, -1.3), light, Enum.Material.SmoothPlastic, "Ellipsoid"))
	for _, s in { -1, 1 } do
		table.insert(partes, piece(ctx, "Mancha", V(0.6, 0.2, 0.7), C(s * 0.45, bodyY + 0.55, -1.3), dark, Enum.Material.SmoothPlastic, "Ellipsoid"))
	end
	for _, p in partes do
		weld(raiz, p)
	end
	joint(ctx, "Cuerpo", raiz, cuerpo, V(0, bodyY, 0))

	-- Cabeza (con articulación: se mueve al mirar) y sus ojos grandes y mandíbulas
	local cabeza = piece(ctx, "Cabeza", V(1.3, 0.95, 1.1), C(0, bodyY - 0.05, -2.45), dark, Enum.Material.SmoothPlastic, "Ellipsoid")
	local deCabeza = {}
	for _, s in { -1, 1 } do
		table.insert(deCabeza, piece(ctx, "Ojo", V(0.42, 0.42, 0.42), C(s * 0.5, bodyY + 0.15, -2.7), rgb(20, 20, 24), Enum.Material.Glass, "Ball"))
		table.insert(deCabeza, piece(ctx, "Brillo", V(0.13, 0.13, 0.13), C(s * 0.55, bodyY + 0.28, -2.88), rgb(255, 255, 255), Enum.Material.Neon, "Ball"))
		table.insert(deCabeza, strut(ctx, "Mandibula", V(s * 0.22, bodyY - 0.35, -2.85), V(s * 0.08, bodyY - 0.45, -3.25), 0.13, dark))
	end
	if o.Gorra then
		-- El sargento: gorra de plato y medallas
		table.insert(deCabeza, piece(ctx, "Gorra", V(1.1, 0.25, 1.2), C(0, bodyY + 0.55, -2.4), o.Gorra, Enum.Material.Fabric))
		table.insert(deCabeza, piece(ctx, "Visera", V(1, 0.08, 0.5), C(0, bodyY + 0.45, -3), rgb(30, 30, 30)))
	end
	for _, p in deCabeza do
		weld(cabeza, p)
	end
	joint(ctx, "Cabeza", cuerpo, cabeza, V(0, bodyY, -2))
	for i = 1, (o.Medallas or 0) do
		local medal = piece(ctx, "Medalla", V(0.3, 0.3, 0.08), C(-0.9 + i * 0.3, bodyY + 0.2, -2.0) * CFrame.Angles(math.rad(-35), 0, 0), rgb(240, 200, 60), Enum.Material.Metal, "Ball")
		weld(cuerpo, medal)
	end

	-- Antenas: largas, en dos tramos, con articulación en la base (se agitan)
	for _, s in { -1, 1 } do
		local side = if s < 0 then "L" else "R"
		local base = V(s * 0.3, bodyY + 0.3, -2.9)
		local mid = V(s * 1.0, bodyY + 1.5, -3.9)
		local tip = V(s * 1.9, bodyY + 1.9, -5.0)
		local a1 = strut(ctx, "Antena" .. side, base, mid, 0.1, dark)
		local a2 = strut(ctx, "AntenaPunta" .. side, mid, tip, 0.08, dark)
		weld(a1, a2)
		joint(ctx, "Antena" .. side, cabeza, a1, base)
	end
	-- Cercos (las dos «colitas» de atrás)
	for _, s in { -1, 1 } do
		weld(raiz, strut(ctx, "Cerco", V(s * 0.4, bodyY - 0.1, 3.3), V(s * 0.8, bodyY + 0.1, 4.1), 0.1, dark))
	end

	-- Seis patas de dos tramos (fémur hacia fuera y arriba, tibia hacia el suelo), con espinas
	for _, leg in Cucaracha.PATAS do
		for _, s in { -1, 1 } do
			local side = if s < 0 then "L" else "R"
			local hip = V(s * 0.8, bodyY - 0.25, leg[2])
			local knee = V(s * 2.0, bodyY + 0.35, leg[2] + leg[3] * 0.5)
			local foot = V(s * 2.9, 0.08, leg[2] + leg[3])
			local femur = strut(ctx, "Femur" .. leg[1] .. side, hip, knee, 0.22, shell)
			local tibia = strut(ctx, "Tibia" .. leg[1] .. side, knee, foot, 0.15, dark)
			weld(femur, tibia)
			for j = 1, 2 do
				local at = knee:Lerp(foot, j / 3)
				weld(tibia, strut(ctx, "Espina", at, at + V(s * 0.25, 0.2, 0), 0.05, dark))
			end
			joint(ctx, "Pata" .. leg[1] .. side, raiz, femur, hip)
		end
	end

	model:SetAttribute("Largo", length)
	model:SetAttribute("RaizBase", raiz.Size.X)
	model:AddTag(Cucaracha.TAG)
	return model
end

-- Disfraza a un personaje (Humanoid) de cucaracha: la cucaracha va soldada a sus pies
function Cucaracha.costume(rig: Model, opts: { [string]: any }?): Model?
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not root then
		return nil
	end
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CastShadow = false
		elseif d:IsA("Decal") or d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		end
	end
	local hip = if humanoid then humanoid.HipHeight else 2
	local feet = root.CFrame * C(0, -(hip + root.Size.Y / 2), 0)
	local bug = Cucaracha.build(Cucaracha.LARGO_DISFRAZ, feet, opts)
	bug.Name = "Disfraz"
	local raiz = bug.PrimaryPart :: BasePart
	raiz.Massless = true
	local w = Instance.new("Weld")
	w.Name = "CucarachaPies"
	w.Part0 = root
	w.Part1 = raiz
	w.C0 = root.CFrame:Inverse() * raiz.CFrame
	w.C1 = CFrame.new()
	w.Parent = raiz
	bug.Parent = rig
	return bug
end

return Cucaracha
