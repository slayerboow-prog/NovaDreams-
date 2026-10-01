-- GallinaGigante: Petra, la gallina de seis metros de Villaverde (misión loca «La gallina de seis
-- metros», Loco_N3_Pollo), hecha con piezas desde código. También sirve para gallinas normales.
--
--   GallinaGigante.build(altura, cf?, opts?) -> Model
--       Una gallina de esa altura (de los pies a lo alto de la cresta) con los pies en cf (en el
--       suelo, mirando a -Z). Cuerpo de bolas, plumas en capas (más claras y más oscuras), alas,
--       cola en abanico, cresta y barbillas rojas, pico, ojos con brillo y patas con dedos.
--       Solo la raíz (GallinaRaiz, invisible) está anclada; el resto va soldado a ella con
--       articulaciones (Motor6D) en el cuerpo, la cabeza, las alas, la cola y las patas: el cliente
--       (Controllers/GiantHen) las mueve como una gallina (respira, cabezazos, picotea, se acomoda).
--       opts.Simple = true: gallina de pocas piezas (las del corral, de adorno).
--
--   GallinaGigante.costume(rig) -> Model
--       Disfraza de gallina a un personaje de la historia (un Humanoid R15 de SceneService): esconde
--       el cuerpo de persona y le suelda la gallina a los pies. El personaje sigue andando, buscando
--       caminos y persiguiendo como siempre; lo que se ve es la gallina. Model:ScaleTo la agranda o
--       la encoge entera (el rayo encogedor).
--
-- Proporciones: Petra mide 2,4 veces una persona (Scale = 2.4 en la misión): unos 20 studs, seis
-- metros. El disfraz se hace a escala 1 (ALTURA_DISFRAZ) y crece con el personaje.

local GallinaGigante = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local rad = math.rad

GallinaGigante.ALTURA_DISFRAZ = 8.4 -- a escala 1; con Scale 2.4 queda en ~20 studs (6 m)
GallinaGigante.TAG = "GallinaGigante"

-- Altura del dibujo en unidades (de los pies a lo alto de la cresta): se escala a la altura pedida
local ALTO = 10.25

local COLORES = {
	Pluma = rgb(250, 247, 238), -- Petra es blanca
	Sombra = rgb(231, 222, 202),
	Dorada = rgb(242, 228, 190), -- gorguera del cuello
	Puntas = rgb(214, 206, 188),
	Cresta = rgb(214, 38, 40),
	Barbilla = rgb(196, 28, 36),
	Pico = rgb(240, 178, 58),
	Pata = rgb(246, 192, 62),
	Una = rgb(150, 110, 70),
	Iris = rgb(232, 138, 40),
	Pupila = rgb(22, 18, 18),
	Brillo = rgb(255, 255, 255),
}

-- Las piezas que hacen sombra (en una gallina grande): el bulto del cuerpo, la cabeza y las alas
local SOMBRA = { Cuerpo = true, Pecho = true, Grupa = true, Vientre = true, Cabeza = true, AlaL = true, AlaR = true, Cola = true }

type Ctx = { model: Model, at: CFrame, k: number, big: boolean }

-- Una pieza en coordenadas del dibujo (unidades; los pies en y = 0, el pico hacia -Z)
local function piece(ctx: Ctx, name: string, shape: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	local p: BasePart
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		p = part
	end
	p.Name = name
	p.Size = size * ctx.k
	p.CFrame = ctx.at * (cf.Rotation + cf.Position * ctx.k)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	-- Solo lo grande de una gallina grande hace sombra (lo pequeño casi no se nota y cuesta)
	p.CastShadow = ctx.big and SOMBRA[name] == true
	p.Parent = ctx.model
	return p
end

local function ball(ctx: Ctx, name: string, d: number, x: number, y: number, z: number, color: Color3, material: Enum.Material?): BasePart
	return piece(ctx, name, "Ball", V(d, d, d), C(x, y, z), color, material)
end

-- Suelda una pieza a otra tal como están ahora
local function weld(part0: BasePart, part1: BasePart)
	local w = Instance.new("Weld")
	w.Name = "Soldadura"
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = part0.CFrame:Inverse() * part1.CFrame
	w.C1 = CFrame.new()
	w.Parent = part1
end

-- Articulación que el cliente mueve (gira alrededor de "pivot", en coordenadas del dibujo)
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

function GallinaGigante.build(height: number, at: CFrame?, opts: { Simple: boolean? }?): Model
	local model = Instance.new("Model")
	model.Name = "Gallina"
	local k = height / ALTO
	local ctx: Ctx = { model = model, at = at or CFrame.new(), k = k, big = height >= 6 }
	local simple = opts ~= nil and opts.Simple == true
	local P = COLORES

	-- Raíz invisible en el suelo, entre las patas (la única pieza anclada)
	local raiz = piece(ctx, "GallinaRaiz", "Block", V(1, 0.2, 1), C(0, 0.1, 0), P.Pluma)
	raiz.Transparency = 1
	raiz.Anchored = true
	raiz.Massless = false
	raiz.CastShadow = false
	model.PrimaryPart = raiz

	-- Cuerpo: varias bolas que juntas hacen el huevo del cuerpo, el pecho y la grupa
	local cuerpo = ball(ctx, "Cuerpo", 5.4, 0, 5.0, 0.2, P.Pluma)
	local cuerpoPartes = {
		ball(ctx, "Pecho", 4.6, 0, 5.2, -1.6, P.Pluma),
		ball(ctx, "Grupa", 4.4, 0, 5.9, 1.9, P.Pluma),
		ball(ctx, "Vientre", 3.8, 0, 3.9, 0.5, P.Sombra),
		ball(ctx, "Cuello", 2.6, 0, 7.0, -2.0, P.Pluma),
	}
	for _, s in { -1, 1 } do
		table.insert(cuerpoPartes, ball(ctx, if s < 0 then "MusloL" else "MusloR", 2.2, s * 1.1, 3.4, 0.6, P.Sombra))
	end
	if not simple then
		-- Gorguera: plumas doradas alrededor del cuello
		for i = 0, 6 do
			local a = rad(-120 + i * 40)
			table.insert(cuerpoPartes, ball(ctx, "Gorguera", 1.35, math.sin(a) * 1.25, 6.45 - math.abs(math.sin(a)) * 0.2, -2.0 + math.cos(a) * 1.15, P.Dorada, Enum.Material.Fabric))
		end
		-- Plumas en capas por los costados: filas de plumas que se solapan, una más clara y otra más oscura
		for _, s in { -1, 1 } do
			for row = 1, 3 do
				for col = 1, 4 do
					local y = 6.3 - row * 0.85
					local z = -1.5 + col * 1.05 + (row % 2) * 0.5
					local r = 2.45 - math.abs(y - 5.2) * 0.35
					local color = if (row + col) % 2 == 0 then P.Pluma else P.Sombra
					table.insert(cuerpoPartes, piece(ctx, "Pluma", "Ball", V(1.25, 1.05, 1.4), C(s * r, y, z), color, Enum.Material.Fabric))
				end
			end
		end
	end
	for _, p in cuerpoPartes do
		weld(cuerpo, p)
	end
	joint(ctx, "Cuerpo", raiz, cuerpo, V(0, 3.2, 0.4))

	-- Cabeza (con cresta, barbillas, pico y ojos): gira sobre el cuello
	local cabeza = ball(ctx, "Cabeza", 2.4, 0, 8.3, -2.7, P.Pluma)
	local cabezaPartes = {}
	local cresta = { { 0.7, 9.3, -3.45 }, { 0.9, 9.6, -3.05 }, { 1.0, 9.75, -2.6 }, { 0.9, 9.6, -2.15 }, { 0.7, 9.35, -1.8 } }
	for i, c in cresta do
		if not simple or i % 2 == 1 then
			table.insert(cabezaPartes, ball(ctx, "Cresta", c[1], 0, c[2], c[3], P.Cresta))
		end
	end
	table.insert(cabezaPartes, piece(ctx, "CrestaBase", "Block", V(0.35, 0.7, 1.9), C(0, 9.2, -2.65), P.Cresta))
	-- Pico: arriba y abajo (cuñas que acaban en punta hacia delante)
	table.insert(cabezaPartes, piece(ctx, "Pico", "Wedge", V(0.7, 0.45, 1.1), C(0, 8.28, -4.2), P.Pico))
	table.insert(cabezaPartes, piece(ctx, "PicoBajo", "Wedge", V(0.56, 0.3, 0.8), C(0, 7.94, -4.05) * CFrame.Angles(0, 0, math.pi), P.Pico))
	for _, s in { -1, 1 } do
		local side = if s < 0 then "L" else "R"
		table.insert(cabezaPartes, ball(ctx, "Barbilla" .. side, 0.75, s * 0.28, 7.3, -3.55, P.Barbilla))
		table.insert(cabezaPartes, ball(ctx, "Ojo" .. side, 0.62, s * 1.0, 8.6, -3.25, P.Iris))
		table.insert(cabezaPartes, ball(ctx, "Pupila" .. side, 0.42, s * 1.13, 8.62, -3.32, P.Pupila))
		if not simple then
			table.insert(cabezaPartes, ball(ctx, "Barbilla2" .. side, 0.55, s * 0.28, 6.82, -3.5, P.Barbilla))
			table.insert(cabezaPartes, ball(ctx, "Brillo" .. side, 0.14, s * 1.31, 8.74, -3.42, P.Brillo, Enum.Material.Neon))
			table.insert(cabezaPartes, ball(ctx, "Orejilla" .. side, 0.5, s * 1.05, 8.0, -2.3, P.Cresta))
		end
	end
	for _, p in cabezaPartes do
		weld(cabeza, p)
	end
	joint(ctx, "Cabeza", cuerpo, cabeza, V(0, 7.1, -2.1))

	-- Alas: una placa de plumas, el hombro redondo y las plumas largas (remeras) con las puntas más oscuras
	for _, s in { -1, 1 } do
		local side = if s < 0 then "L" else "R"
		local ala = piece(ctx, "Ala" .. side, "Block", V(0.7, 2.6, 3.6), C(s * 2.65, 5.4, 0.7) * CFrame.Angles(rad(12), 0, rad(-s * 8)), P.Pluma, Enum.Material.Fabric)
		local alaPartes = { ball(ctx, "Hombro" .. side, 2.0, s * 2.55, 6.05, -0.45, P.Pluma, Enum.Material.Fabric) }
		if not simple then
			for i = 0, 2 do
				table.insert(alaPartes, piece(ctx, "Remera" .. side, "Block", V(0.35, 0.75, 2.7), C(s * (2.75 + i * 0.08), 4.75 + i * 0.42, 2.0 + i * 0.25) * CFrame.Angles(rad(16 + i * 4), 0, rad(-s * 6)), if i == 0 then P.Puntas else P.Sombra, Enum.Material.Fabric))
			end
		end
		for _, p in alaPartes do
			weld(ala, p)
		end
		joint(ctx, "Ala" .. side, cuerpo, ala, V(s * 2.3, 6.3, -0.6))
	end

	-- Cola en abanico (hacia atrás y arriba)
	local base = V(0, 6.6, 3.0)
	local plumas = {}
	local angulos = if simple then { -24, 0, 24 } else { -36, -24, -12, 0, 12, 24, 36 }
	for i, a in angulos do
		local rot = CFrame.Angles(rad(-35), 0, rad(a))
		local cf = C(base) * rot * C(0, 1.8, 0)
		table.insert(plumas, piece(ctx, "Cola", "Block", V(0.35, 3.6, 1.0), cf, if i % 2 == 0 then P.Sombra else P.Pluma, Enum.Material.Fabric))
	end
	local cola = plumas[math.ceil(#plumas / 2)]
	for _, p in plumas do
		if p ~= cola then
			weld(cola, p)
		end
	end
	joint(ctx, "Cola", cuerpo, cola, base)

	-- Patas amarillas con tres dedos delante y uno detrás
	for _, s in { -1, 1 } do
		local side = if s < 0 then "L" else "R"
		local pata = piece(ctx, "Pata" .. side, "Cylinder", V(2.8, 0.5, 0.5), C(s * 1.0, 1.65, 0.45) * CFrame.Angles(0, 0, rad(90)), P.Pata)
		local partes = { ball(ctx, "Tobillo" .. side, 0.6, s * 1.0, 0.32, 0.4, P.Pata) }
		for _, a in { -28, 0, 28 } do
			local dir = CFrame.Angles(0, rad(a * s), 0)
			local center = V(s * 1.0, 0.13, 0.4) + dir:VectorToWorldSpace(V(0, 0, -0.75))
			table.insert(partes, piece(ctx, "Dedo" .. side, "Block", V(0.3, 0.24, 1.45), C(center) * dir, P.Pata))
			if not simple then
				local tip = V(s * 1.0, 0.13, 0.4) + dir:VectorToWorldSpace(V(0, 0, -1.5))
				table.insert(partes, ball(ctx, "Una" .. side, 0.26, tip.X, tip.Y, tip.Z, P.Una))
			end
		end
		table.insert(partes, piece(ctx, "DedoAtras" .. side, "Block", V(0.28, 0.22, 0.8), C(s * 1.0, 0.12, 0.85), P.Pata))
		for _, p in partes do
			weld(pata, p)
		end
		joint(ctx, "Pata" .. side, raiz, pata, V(s * 1.0, 3.0, 0.45))
	end

	model:SetAttribute("Altura", height)
	model:SetAttribute("RaizBase", raiz.Size.X)
	model:AddTag(GallinaGigante.TAG)
	return model
end

-- Disfraza a un personaje (Humanoid) de gallina: la gallina va soldada a sus pies
function GallinaGigante.costume(rig: Model): Model?
	local root = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not root then
		return nil
	end
	-- El cuerpo de persona no se ve (pero sigue ahí: es el que anda, salta y busca el camino)
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
	local hen = GallinaGigante.build(GallinaGigante.ALTURA_DISFRAZ, feet)
	hen.Name = "Disfraz"
	local raiz = hen.PrimaryPart :: BasePart
	raiz.Anchored = false
	raiz.Massless = true
	local w = Instance.new("Weld")
	w.Name = "GallinaPies"
	w.Part0 = root
	w.Part1 = raiz
	w.C0 = root.CFrame:Inverse() * raiz.CFrame
	w.C1 = CFrame.new()
	w.Parent = raiz
	hen.Parent = rig
	return hen
end

return GallinaGigante
