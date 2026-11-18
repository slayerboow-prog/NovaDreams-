-- ForestSanctuary: el SANTUARIO DEL BOSQUE alrededor del Árbol Ancestral (18-11-2026, el dueño: «construye un
-- santuario completo a su alrededor», referencia docs/mapa/santuario-referencia*.png). La arquitectura, con piezas
-- (el árbol, con mallas: World/Kit/AncientTree). Todo abandonado hace siglos y comido por la naturaleza:
--
--   * Plaza circular de piedra con su anillo de runas que brillan, y senderos de losas entre las raíces.
--   * Escalinata monumental de tres tramos hacia la ciudad y, arriba, la puerta antigua (arco con runas).
--   * Columnas antiguas con runas (alguna rota, con su trozo en el suelo) y muros medio derruidos con musgo y lianas.
--   * Dos estatuas de antiguos guardianes con espada a los lados de la puerta.
--   * Tres altares con su cristal (las RUNAS PERDIDAS de la misión: atributo RunaSantuario) y el altar del NÚCLEO
--     a los pies del árbol (atributo AltarNucleo).
--   * Faroles y antorchas, estandartes con el árbol, flores que brillan y una cascada pequeña con su poza.
-- ForestSanctuary.build(parent, center CFrame, seed) -> (Model, puntos: { Guardian, Runes, Core })

local Builder = require(script.Parent.Parent.Builder)

local ForestSanctuary = {}

ForestSanctuary.Elevation = 14 -- la altura de la terraza (el árbol va encima: World/RegionLandmarks)
ForestSanctuary.ColumnScale = 1.7 -- columnas y estatuas a la escala del árbol gigante
ForestSanctuary.StatueScale = 6 -- (el guerrero de piedra mide unos 30 studs)

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material

local STONE = { rgb(150, 146, 136), rgb(132, 128, 120), rgb(168, 162, 150), rgb(118, 116, 110) }
local MOSS = rgb(78, 128, 70)
local RUNE = rgb(110, 210, 255)

local function rng(seed: number): () -> number
	local s = math.max(1, math.floor(seed) % 2147483646)
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function P(parent: Instance, props: { [string]: any }): BasePart
	props.Parent = parent
	return Builder.part(props)
end

local function glow(parent: Instance, props: { [string]: any }): BasePart
	props.Material = M.Neon
	props.CanCollide = false
	props.CastShadow = false
	props.Parent = parent
	return Builder.part(props)
end

local function light(part: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
end

-- Runas dibujadas con trazos de luz en una cara (cf: el centro de la cara, mirando hacia fuera = −Z)
local function runes(parent: Instance, cf: CFrame, h: number, r: () -> number)
	for k = 0, 2 do
		local y = (k - 1) * h * 0.3
		local c = cf * CF(0, y, -0.08)
		-- un círculo y dos trazos: cada runa distinta
		glow(parent, { Name = "Runa", Shape = Enum.PartType.Cylinder, Size = V3(0.15, 2.4, 2.4), CFrame = c * ANG(0, math.rad(90), 0), Color = RUNE, Transparency = 0.25 })
		glow(parent, { Name = "Runa", Size = V3(0.3, 2.6, 0.15), CFrame = c * ANG(0, 0, r() * 1.2 - 0.6), Color = RUNE })
		glow(parent, { Name = "Runa", Size = V3(1.6, 0.3, 0.15), CFrame = c * CF(0, -0.6 + r() * 1.2, 0), Color = RUNE })
	end
end

local function column(parent: Instance, base: CFrame, h: number, broken: boolean, r: () -> number)
	local m = Builder.model("Columna", parent)
	local stone = STONE[1 + math.floor(r() * #STONE) % #STONE]
	P(m, { Name = "Basa", Size = V3(9, 3, 9), CFrame = base * CF(0, 1.5, 0), Color = stone, Material = M.Cobblestone })
	local hh = if broken then h * (0.35 + r() * 0.3) else h
	P(m, { Name = "Fuste", Size = V3(6, hh, 6), CFrame = base * CF(0, 3 + hh / 2, 0) * ANG(0, r() * 0.3, 0), Color = stone, Material = M.Slate })
	runes(m, base * CF(0, 3 + hh * 0.55, -3.02), hh, r)
	if not broken then
		P(m, { Name = "Capitel", Size = V3(9, 2.4, 9), CFrame = base * CF(0, 3 + hh + 1.2, 0), Color = stone, Material = M.Cobblestone })
		local f = glow(m, { Name = "Llama", Shape = Enum.PartType.Ball, Size = V3(2.2, 2.2, 2.2), CFrame = base * CF(0, 3 + hh + 4, 0), Color = rgb(150, 230, 255) })
		light(f, RUNE, 26, 1.4)
	else
		-- el trozo caído, al lado, medio enterrado y con musgo
		P(m, { Name = "Trozo", Size = V3(6, h * 0.4, 6), CFrame = base * CF(7, 2.4, 6) * ANG(math.rad(84), r() * 3, 0), Color = stone, Material = M.Slate })
	end
	Builder.decor({ Name = "Musgo", Size = V3(9.4, 1.2, 9.4), CFrame = base * CF(0, 3.2, 0), Color = MOSS, Material = M.LeafyGrass, Parent = m })
	-- hiedra que trepa
	for k = 1, 3 do
		Builder.decor({ Name = "Hiedra", Size = V3(0.6, hh * (0.3 + r() * 0.4), 0.6), CFrame = base * CF((r() - 0.5) * 5, 3 + hh * 0.3, -3.1) * ANG(0, 0, r() * 0.3 - 0.15), Color = rgb(70, 120, 60), Material = M.Grass, Parent = m })
	end
	-- (a la escala del árbol gigante)
	m.WorldPivot = base
	pcall(function()
		m:ScaleTo(ForestSanctuary.ColumnScale)
	end)
	return m
end

-- Una estatua de un antiguo guardián: un guerrero (el personaje de Roblox de siempre) convertido en piedra, con
-- yelmo, capa y la espada clavada delante, sobre su pedestal, a la escala del árbol (StatueScale)
local function statue(parent: Instance, base: CFrame)
	local m = Builder.model("EstatuaGuardian", parent)
	local stone = rgb(150, 148, 140)
	P(m, { Name = "Pedestal", Size = V3(16, 6, 16), CFrame = base * CF(0, 3, 0), Color = rgb(120, 118, 112), Material = M.Cobblestone })
	Builder.decor({ Name = "Musgo", Size = V3(16.4, 1.2, 16.4), CFrame = base * CF(0, 6.1, 0), Color = MOSS, Material = M.LeafyGrass, Parent = m })
	local okNpc, Npc = pcall(function()
		return require(script.Parent.Parent.Npc) :: any
	end)
	local fig: Model? = nil
	if okNpc then
		local ok, made = pcall(Npc.create, "Guerrero", m, base * CF(0, 9.2, 0), { Skin = stone, Shirt = stone, Pants = stone })
		fig = if ok then made else nil
	end
	if fig then
		local f = fig :: Model
		-- solo el cuerpo (fuera pelo, cuello y demás piezas sueltas: en piedra sobran y aún no están en su sitio)
		local BODY = { HumanoidRootPart = true, Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
			LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
			LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
			["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true }
		for _, d in f:GetChildren() do
			if d:IsA("BasePart") and not BODY[d.Name] then
				d:Destroy()
			end
		end
		-- de piedra: sin ropa ni cara, todo del mismo gris, quieto
		for _, d in f:GetDescendants() do
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("Decal") or d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Material = M.Slate
				d.Color = stone
				d.CanCollide = false
				pcall(function()
					(d :: any).TextureID = ""
				end)
			end
		end
		local hum = f:FindFirstChildOfClass("Humanoid")
		-- la postura: los dos brazos hacia delante, las manos juntas sobre la empuñadura
		for _, side in { "Right", "Left" } do
			local upper = f:FindFirstChild(side .. "UpperArm")
			local joint = upper and upper:FindFirstChild(side .. "Shoulder")
			if joint and joint:IsA("Motor6D") then
				joint.C0 = joint.C0 * ANG(math.rad(55), 0, math.rad(if side == "Right" then 18 else -18))
			end
		end
		local head = f:FindFirstChild("Head") :: BasePart?
		local torso = (f:FindFirstChild("UpperTorso") or f:FindFirstChild("Torso")) :: BasePart?
		if hum then
			hum:Destroy()
		end
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		-- (de pie sobre el pedestal, mirando hacia delante, ANTES de agrandarla)
		local bcf, bsize = f:GetBoundingBox()
		local _ = bcf
		f:PivotTo(base * CF(0, 6 + bsize.Y / 2, 0))
		-- yelmo, hombreras, capa y la espada
		if head then
			P(f, { Name = "Yelmo", Size = V3(1.5, 1.1, 1.5), CFrame = head.CFrame * CF(0, 0.35, 0), Color = stone, Material = M.Slate })
			P(f, { Name = "Cresta", ClassName = "WedgePart", Size = V3(0.3, 0.8, 1.4), CFrame = head.CFrame * CF(0, 1.2, 0.1), Color = stone, Material = M.Slate })
			local eye = glow(f, { Name = "Ojos", Size = V3(0.9, 0.15, 0.05), CFrame = head.CFrame * CF(0, 0.1, -0.62), Color = RUNE })
			light(eye, RUNE, 4, 1)
		end
		if torso then
			for _, sx in { -1, 1 } do
				P(f, { Name = "Hombrera", Shape = Enum.PartType.Ball, Size = V3(1.1, 0.8, 1.1), CFrame = torso.CFrame * CF(sx * 1.05, 0.55, 0), Color = stone, Material = M.Slate })
			end
			P(f, { Name = "Capa", ClassName = "WedgePart", Size = V3(2.4, 4.2, 0.5), CFrame = torso.CFrame * CF(0, -1.4, 0.75) * ANG(0, math.pi, 0), Color = stone:Lerp(rgb(0, 0, 0), 0.12), Material = M.Slate })
			local front = torso.CFrame * CF(0, -1.9, -1.6)
			P(f, { Name = "Hoja", Size = V3(0.35, 3.6, 0.12), CFrame = front * CF(0, -1.2, 0), Color = rgb(170, 168, 160), Material = M.Slate })
			P(f, { Name = "Guarda", Size = V3(1.4, 0.2, 0.25), CFrame = front * CF(0, 0.65, 0), Color = stone, Material = M.Slate })
			P(f, { Name = "Pomo", Size = V3(0.25, 0.8, 0.25), CFrame = front * CF(0, 1.1, 0), Color = stone, Material = M.Slate })
		end
		f.WorldPivot = base * CF(0, 6, 0)
		pcall(function()
			f:ScaleTo(ForestSanctuary.StatueScale)
		end)
		f:PivotTo(base * CF(0, 6, 0))
		-- (los pies, encima del pedestal)
		local lo = math.huge
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				lo = math.min(lo, d.Position.Y - d.Size.Y / 2)
			end
		end
		local top = (base * CF(0, 6, 0)).Position.Y
		if lo < math.huge then
			f:PivotTo(f:GetPivot() + V3(0, top - lo, 0))
		end
	end
	return m
end

local function lantern(parent: Instance, base: CFrame)
	local m = Builder.model("Farol", parent)
	P(m, { Name = "Poste", Size = V3(1.2, 14, 1.2), CFrame = base * CF(0, 7, 0), Color = rgb(92, 68, 46), Material = M.Wood })
	P(m, { Name = "Brazo", Size = V3(5, 0.8, 0.8), CFrame = base * CF(2, 13.6, 0), Color = rgb(92, 68, 46), Material = M.Wood })
	P(m, { Name = "Jaula", Size = V3(2.2, 2.8, 2.2), CFrame = base * CF(4, 11.6, 0), Color = rgb(60, 56, 52), Material = M.Metal, Transparency = 0.2 })
	local f = glow(m, { Name = "Luz", Size = V3(1.4, 1.8, 1.4), CFrame = base * CF(4, 11.6, 0), Color = rgb(255, 210, 140) })
	light(f, rgb(255, 200, 130), 22, 1.6)
	return m
end

local function banner(parent: Instance, base: CFrame)
	local m = Builder.model("Estandarte", parent)
	P(m, { Name = "Mastil", Size = V3(1, 20, 1), CFrame = base * CF(0, 10, 0), Color = rgb(96, 70, 46), Material = M.Wood })
	P(m, { Name = "Travesano", Size = V3(8, 0.8, 0.8), CFrame = base * CF(0, 19, 0), Color = rgb(96, 70, 46), Material = M.Wood })
	P(m, { Name = "Tela", Size = V3(7, 11, 0.3), CFrame = base * CF(0, 13, 0), Color = rgb(36, 60, 120), Material = M.Fabric })
	P(m, { Name = "Pico", ClassName = "WedgePart", Size = V3(0.3, 2.4, 3.5), CFrame = base * CF(1.75, 6.3, 0) * ANG(0, math.rad(90), math.rad(180)), Color = rgb(36, 60, 120), Material = M.Fabric })
	P(m, { Name = "Pico", ClassName = "WedgePart", Size = V3(0.3, 2.4, 3.5), CFrame = base * CF(-1.75, 6.3, 0) * ANG(0, math.rad(-90), math.rad(180)), Color = rgb(36, 60, 120), Material = M.Fabric })
	-- el árbol bordado (tronco y copa en plata)
	P(m, { Name = "Bordado", Size = V3(0.6, 4, 0.1), CFrame = base * CF(0, 12, -0.2), Color = rgb(220, 226, 236), Material = M.SmoothPlastic })
	P(m, { Name = "Bordado", Shape = Enum.PartType.Cylinder, Size = V3(0.1, 4.4, 4.4), CFrame = base * CF(0, 15, -0.2) * ANG(0, math.rad(90), 0), Color = rgb(220, 226, 236), Material = M.SmoothPlastic })
	return m
end

local function flowers(parent: Instance, at: Vector3, r: () -> number, n: number)
	for k = 1, n do
		local p = at + V3((r() - 0.5) * 16, 0, (r() - 0.5) * 16)
		Builder.decor({ Name = "Tallo", Size = V3(0.3, 2, 0.3), CFrame = CF(p + V3(0, 1, 0)), Color = rgb(70, 130, 60), Material = M.Grass, Parent = parent })
		local c = if k % 3 == 0 then rgb(255, 170, 230) elseif k % 3 == 1 then rgb(150, 220, 255) else rgb(200, 160, 255)
		glow(parent, { Name = "Flor", Shape = Enum.PartType.Ball, Size = V3(1.1, 1.1, 1.1), CFrame = CF(p + V3(0, 2.2, 0)), Color = c })
	end
end

function ForestSanctuary.build(parent: Instance, center: CFrame, seed: number?): (Model, { [string]: any })
	local r = rng(seed or 1717)
	local m = Builder.model("SantuarioDelBosque", parent)
	local points = { Runes = {} }
	-- (la plaza es una TERRAZA de Elevation studs: la escalinata baja de ella hasta el suelo, hacia la ciudad)
	local E = ForestSanctuary.Elevation
	local top = center * CF(0, E, 0)
	-- 1) la plaza: el muro de la terraza, losas en anillos, el anillo de runas que brilla y musgo entre las piedras
	P(m, { Name = "Terraza", Shape = Enum.PartType.Cylinder, Size = V3(E + 6, 410, 410), CFrame = center * CF(0, (E - 6) / 2, 0) * ANG(0, 0, math.rad(90)), Color = rgb(112, 110, 104), Material = M.Cobblestone })
	P(m, { Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = V3(2, 402, 402), CFrame = top * CF(0, 0.2, 0) * ANG(0, 0, math.rad(90)), Color = rgb(122, 120, 112), Material = M.Slate })
	P(m, { Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = V3(2.1, 250, 250), CFrame = top * CF(0, 0.3, 0) * ANG(0, 0, math.rad(90)), Color = rgb(140, 136, 126), Material = M.Cobblestone })
	for k = 0, 47 do
		local a = k / 48 * math.pi * 2
		local seg = top * ANG(0, a, 0) * CF(0, 1.42, -132)
		glow(m, { Name = "AnilloRunas", Size = V3(14, 0.2, 1.4), CFrame = seg, Color = RUNE, Transparency = 0.2 })
		if k % 4 == 0 then
			glow(m, { Name = "RunaSuelo", Size = V3(3, 0.22, 3), CFrame = seg * CF(0, 0, -6) * ANG(0, math.rad(45), 0), Color = RUNE, Transparency = 0.15 })
		end
	end
	for k = 1, 40 do
		local a = r() * math.pi * 2
		local d = 30 + r() * 130
		Builder.decor({ Name = "Musgo", Size = V3(8 + r() * 14, 0.4, 6 + r() * 10), CFrame = top * ANG(0, a, 0) * CF(0, 1.45, -d) * ANG(0, r() * 3, 0), Color = MOSS, Material = M.LeafyGrass, Parent = m })
	end
	-- (los «hacia la ciudad»: −Z de center apunta al centro de la isla)
	-- 2) la escalinata monumental (tres tramos con rellanos) que baja de la terraza hasta el suelo
	local steps, drop = 18, E / 18
	local z = -205
	for i = 0, steps - 1 do
		local y = E - (i + 1) * drop
		P(m, { Name = "Escalon", Size = V3(56, y + 6, 4.6), CFrame = center * CF(0, (y - 6) / 2 + 0.8, z - 2.3), Color = STONE[1 + i % #STONE], Material = M.Slate })
		z -= 4.6
		if i == 5 or i == 11 then
			P(m, { Name = "Rellano", Size = V3(56, y + 6, 10), CFrame = center * CF(0, (y - 6) / 2 + 0.8, z - 5), Color = STONE[2], Material = M.Slate })
			for _, side in { -1, 1 } do
				lantern(m, center * CF(side * 31, y + 0.8, z - 5) * ANG(0, if side > 0 then math.pi else 0, 0))
			end
			z -= 10
		end
	end
	-- la puerta: dos pilares con runas y el dintel
	for _, side in { -1, 1 } do
		column(m, top * CF(side * 34, 0, -196), 34, false, r)
	end
	P(m, { Name = "Dintel", Size = V3(84, 9, 14), CFrame = top * CF(0, 69, -196), Color = STONE[3], Material = M.Slate })
	runes(m, top * CF(0, 69, -203.1) * ANG(0, 0, math.rad(90)), 30, r)
	-- 3) columnas con runas alrededor (alguna rota) y muros medio derruidos
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2 + math.pi / 12
		local c = top * ANG(0, a, 0) * CF(0, 1.3, -150)
		if math.abs(math.sin(a / 2)) > 0.12 then -- (deja libre la entrada)
			column(m, c * ANG(0, math.pi, 0), 30 + r() * 10, k % 3 == 1, r)
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.6
		local c = top * ANG(0, a, 0) * CF(0, 1.3, -172)
		local w = 26 + r() * 16
		local hh = 8 + r() * 12
		local wall = P(m, { Name = "Muro", Size = V3(w, hh, 5), CFrame = c * CF(0, hh / 2, 0), Color = STONE[1 + k % #STONE], Material = M.Cobblestone })
		local _ = wall
		-- el borde roto (escalonado) y piedras caídas
		P(m, { Name = "Muro", Size = V3(w * 0.4, hh * 0.5, 5), CFrame = c * CF(-w * 0.2, hh + hh * 0.25, 0), Color = STONE[2], Material = M.Cobblestone })
		for q = 1, 3 do
			P(m, { Name = "Piedra", Size = V3(3 + r() * 3, 2 + r() * 2, 3 + r() * 3), CFrame = c * CF((r() - 0.5) * w, 1.4, -4 - r() * 6) * ANG(r(), r() * 3, r()), Color = STONE[q % #STONE + 1], Material = M.Cobblestone })
		end
		Builder.decor({ Name = "Musgo", Size = V3(w + 0.4, 1.6, 5.4), CFrame = c * CF(0, hh + 0.4, 0), Color = MOSS, Material = M.LeafyGrass, Parent = m })
		for q = 1, 4 do
			Builder.decor({ Name = "Liana", Size = V3(0.5, hh * (0.5 + r() * 0.5), 0.5), CFrame = c * CF((r() - 0.5) * w, hh * 0.5, -2.7), Color = rgb(66, 118, 58), Material = M.Grass, Parent = m })
		end
	end
	-- 4) las estatuas de los guardianes a los lados de la puerta
	for _, side in { -1, 1 } do
		statue(m, top * CF(side * 66, 0.8, -186) * ANG(0, math.pi, 0))
	end
	-- 5) los altares de las runas perdidas (tres) y el altar del núcleo a los pies del árbol
	for k = 1, 3 do
		local a = math.rad(-90 + (k - 2) * 75) + math.pi
		local c = top * ANG(0, a, 0) * CF(0, 1.3, -112)
		local alt = Builder.model("AltarRuna" .. k, m)
		P(alt, { Name = "Base", Size = V3(10, 4, 10), CFrame = c * CF(0, 2, 0), Color = STONE[3], Material = M.Cobblestone })
		P(alt, { Name = "Mesa", Size = V3(7, 3, 7), CFrame = c * CF(0, 5.5, 0), Color = STONE[1], Material = M.Slate })
		local crystal = glow(alt, { Name = "Runa", Size = V3(2.4, 5, 2.4), CFrame = c * CF(0, 9.5, 0) * ANG(0, math.rad(45), 0), Color = rgb(70, 90, 120), Transparency = 0.1 })
		crystal:SetAttribute("RunaSantuario", k)
		table.insert(points.Runes, crystal)
		flowers(m, (c * CF(0, 0.2, 0)).Position, r, 8)
	end
	local coreAltar = Builder.model("AltarNucleo", m)
	local ca = top * CF(0, 1.3, -60)
	P(coreAltar, { Name = "Base", Size = V3(16, 3, 12), CFrame = ca * CF(0, 1.5, 0), Color = STONE[3], Material = M.Cobblestone })
	local plate = P(coreAltar, { Name = "Placa", Size = V3(12, 5, 8), CFrame = ca * CF(0, 5.5, 0), Color = STONE[1], Material = M.Slate })
	runes(coreAltar, ca * CF(0, 5.5, -4.05), 4, r)
	plate:SetAttribute("AltarNucleo", true)
	points.Core = plate
	points.Guardian = top * CF(14, 1.4, -70) * ANG(0, math.pi, 0)
	-- 6) faroles por la plaza, estandartes y flores que brillan
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + math.pi / 8
		lantern(m, top * ANG(0, a, 0) * CF(0, 1.3, -126) * ANG(0, math.pi / 2, 0))
	end
	for _, side in { -1, 1 } do
		banner(m, top * CF(side * 34, 1.3, -142))
		banner(m, top * CF(side * 60, 1.3, -120))
	end
	for k = 1, 14 do
		local a = r() * math.pi * 2
		flowers(m, (top * ANG(0, a, 0) * CF(0, 1.4, -(60 + r() * 100))).Position, r, 6)
	end
	-- 7) la cascada pequeña con su poza (a un lado, detrás de los muros)
	local wf = top * ANG(0, math.rad(115), 0) * CF(0, 0, -150)
	P(m, { Name = "Roca", Size = V3(30, 34, 14), CFrame = wf * CF(0, 17, -8), Color = rgb(110, 108, 104), Material = M.Rock })
	P(m, { Name = "Roca", Shape = Enum.PartType.Ball, Size = V3(18, 16, 16), CFrame = wf * CF(-10, 34, -8), Color = rgb(104, 104, 98), Material = M.Rock })
	local water = P(m, { Name = "Agua", Size = V3(9, 30, 0.8), CFrame = wf * CF(0, 16, -0.8), Color = rgb(160, 220, 255), Material = M.Glass, Transparency = 0.25, CanCollide = false })
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(rgb(230, 245, 255))
	mist.Size = NumberSequence.new(3, 8)
	mist.Transparency = NumberSequence.new(0.5, 1)
	mist.Lifetime = NumberRange.new(1.2, 2)
	mist.Speed = NumberRange.new(2, 4)
	mist.Rate = 10
	mist.Parent = water
	P(m, { Name = "Poza", Shape = Enum.PartType.Cylinder, Size = V3(1, 24, 24), CFrame = wf * CF(0, 1, 10) * ANG(0, 0, math.rad(90)), Color = rgb(70, 160, 210), Material = M.Glass, Transparency = 0.2, CanCollide = false })
	-- 8) senderos de losas desde la puerta hasta el altar del núcleo
	for k = 0, 16 do
		local z = -196 + k * 8
		P(m, { Name = "Losa", Size = V3(7 + r() * 3, 0.5, 4 + r() * 1.5), CFrame = top * CF((r() - 0.5) * 3, 1.5, z) * ANG(0, r() * 0.4 - 0.2, 0), Color = STONE[1 + k % #STONE], Material = M.Slate })
	end
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	return m, points
end

return ForestSanctuary
