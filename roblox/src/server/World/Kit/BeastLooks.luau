-- BeastLooks (servidor): los cuerpos «con aspecto propio» de las bestias de las ocho regiones de Valmar (el
-- cartel del dueño: cabezas grandes, ojos que brillan, armas en la mano, capuchas, cuernos y alas). Lo llama
-- World/Kit/BeastKit cuando la especie lleva Look (shared/Cosmos/Bestiary):
--
--   BeastLooks.humanoid(x)   de pie: Bandido, Minotauro, Mago (nigromante, cultista, mago oscuro), Momia,
--                            Esqueleto, Caballero, Demonio, Gigante, Elemental (flota, sin piernas)
--   BeastLooks.blob(x)       una masa gelatinosa (slime) con núcleo y ojos
--   BeastLooks.dragonWings / BeastLooks.spiderLegs   piezas sueltas para cuadrúpedos, serpientes e insectos
--
-- x = { Model, Root, Sp, K, Hip, Limb, Eye, Mat }: Limb y Eye son los de BeastKit (piezas soldadas al «Centro»).
-- Los nombres de pieza importan: «Pierna», «Brazo», «Ala», «Cola» pasan a articulaciones (BeastKit.rig) y el
-- cliente las anima (Controllers/BeastAnim); «Cabeza» sitúa la corona de campeona. Lo que cuelga de un brazo
-- (arma, escudo, mano) se suelda a ese brazo para que se mueva con él.

local BeastLooks = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local IVORY = rgb(232, 224, 200)
local STEEL = rgb(170, 176, 188)
local WOOD = rgb(86, 62, 44)
local GOLD = rgb(240, 196, 80)
local DARK = rgb(14, 12, 18)

type Ctx = { Model: Model, Root: BasePart, Sp: { [string]: any }, K: number, Hip: number, Limb: any, Eye: any, Mat: Enum.Material }

local function tools(x: Ctx)
	local k = x.K
	-- una pieza: tamaño y sitio en «unidades de bestia» (se multiplican por su escala)
	local function P(name: string, sx: number, sy: number, sz: number, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, attach: BasePart?): BasePart
		return x.Limb(x.Model, x.Root, name, V3(sx * k, sy * k, sz * k), cf, color, material or x.Mat, shape, attach)
	end
	local function at(px: number, py: number, pz: number): CFrame
		return CFrame.new(px * k, py * k, pz * k)
	end
	local function neon(p: BasePart): BasePart
		p.Material = Enum.Material.Neon
		p.CastShadow = false
		return p
	end
	return P, at, neon
end

-- El arma en la mano (hand: la mano en el espacio de la raíz; todo soldado al brazo)
local function weapon(x: Ctx, kind: string, arm: BasePart, hand: CFrame)
	local P, at, neon = tools(x)
	local glow = x.Sp.Colors.Glow
	local metal = Enum.Material.Metal
	if kind == "Espada" or kind == "Daga" then
		local L = if kind == "Daga" then 1.1 else 2.5
		local g = hand * CFrame.Angles(math.rad(-75), 0, 0)
		P("Mango", 0.2, 0.6, 0.2, g, WOOD, Enum.Material.Wood, nil, arm)
		P("Guarda", 0.9, 0.16, 0.3, g * at(0, 0.35, 0), GOLD, metal, nil, arm)
		P("Hoja", 0.14, L, 0.42, g * at(0, 0.45 + L / 2, 0), STEEL, metal, nil, arm)
		if x.Sp.Look == "Caballero" or kind == "Daga" then
			neon(P("Filo", 0.16, L * 0.85, 0.1, g * at(0, 0.45 + L / 2, 0), glow, nil, nil, arm))
		end
	elseif kind == "Hacha" then
		local g = hand * CFrame.Angles(math.rad(-55), 0, 0)
		P("Asta", 0.26, 3.8, 0.26, g * at(0, 1.1, 0), WOOD, Enum.Material.Wood, nil, arm)
		P("Hoja", 0.18, 1.5, 1.5, g * at(0, 2.6, -0.7), STEEL, metal, nil, arm)
		P("Hoja", 0.18, 1.0, 0.9, g * at(0, 2.6, 0.55), STEEL, metal, nil, arm)
		P("Remate", 0.4, 0.4, 0.4, g * at(0, 3.1, 0), GOLD, metal, nil, arm)
	elseif kind == "Baston" then
		local g = hand * CFrame.Angles(math.rad(-8), 0, 0)
		P("Asta", 0.2, 4.2, 0.2, g * at(0, 1.2, 0), WOOD, Enum.Material.Wood, nil, arm)
		neon(P("Orbe", 0.75, 0.75, 0.75, g * at(0, 3.6, 0), glow, nil, Enum.PartType.Ball, arm))
		for _, s in { -1, 1 } do
			P("Garfio", 0.14, 0.7, 0.14, g * at(s * 0.4, 3.5, 0) * CFrame.Angles(0, 0, s * 0.5), WOOD, Enum.Material.Wood, nil, arm)
		end
	elseif kind == "Maza" then
		local g = hand * CFrame.Angles(math.rad(-50), 0, 0)
		P("Asta", 0.34, 3.2, 0.34, g * at(0, 0.9, 0), WOOD, Enum.Material.Wood, nil, arm)
		P("Cabezal", 1.4, 1.4, 1.4, g * at(0, 2.8, 0), rgb(190, 232, 255), Enum.Material.Ice, nil, arm)
		for _, s in { -1, 1 } do
			P("Pincho", 0.35, 0.35, 0.8, g * at(0, 2.8, s * 1.0), rgb(220, 244, 255), Enum.Material.Ice, nil, arm)
			P("Pincho", 0.8, 0.35, 0.35, g * at(s * 1.0, 2.8, 0), rgb(220, 244, 255), Enum.Material.Ice, nil, arm)
		end
	elseif kind == "Lanza" then
		local g = hand * CFrame.Angles(math.rad(-15), 0, 0)
		P("Asta", 0.2, 5.2, 0.2, g * at(0, 1.2, 0), WOOD, Enum.Material.Wood, nil, arm)
		neon(P("Punta", 0.3, 0.9, 0.3, g * at(0, 4.2, 0), glow, nil, nil, arm))
	end
end

function BeastLooks.humanoid(x: Ctx)
	local P, at, neon = tools(x)
	local sp, k, hip = x.Sp, x.K, x.Hip
	local C = sp.Colors
	local body, belly, glow = C.Body, C.Belly, C.Glow
	local skin = C.Skin or belly
	local look = sp.Look
	local Yk = -x.Root.Size.Y / 2 / k -- (la parte de abajo del tronco, en unidades)
	local hipk = hip / k
	local bone = look == "Esqueleto"
	local big = look == "Minotauro" or look == "Demonio" or look == "Gigante"
	local floats = look == "Elemental"
	local robe = look == "Mago"
	local fire = Enum.Material.Neon

	-- TRONCO
	local W = 0.95 -- (medio ancho de hombros)
	if bone then
		W = 0.75
		P("Tronco", 0.35, 2.3, 0.35, at(0, 0, 0), IVORY)
		for i = 0, 2 do
			P("Costilla", 1.5 - i * 0.15, 0.22, 0.9, at(0, 0.8 - i * 0.5, 0), IVORY)
		end
		P("Pelvis", 1.3, 0.4, 0.7, at(0, -1.05, 0), IVORY)
		P("Peto", 1.6, 0.7, 1.0, at(0, 0.9, 0), belly, Enum.Material.Metal) -- (lo que le queda de la armadura)
	elseif floats then
		neon(P("Tronco", 1.7, 1.9, 1.2, at(0, 0.2, 0), body, fire))
		neon(P("Llama", 1.25, 0.9, 0.95, at(0, -1.1, 0), body:Lerp(belly, 0.5), fire))
		neon(P("Llama", 0.85, 0.85, 0.7, at(0, -1.9, 0), belly, fire))
		local tip = neon(P("Llama", 0.45, 0.8, 0.45, at(0, -2.65, 0), glow, fire))
		tip.Transparency = 0.25
		neon(P("Nucleo", 0.8, 0.8, 0.8, at(0, 0.3, -0.45), glow, fire, Enum.PartType.Ball))
	elseif big then
		W = 1.4
		P("Tronco", 2.8, 1.5, 1.7, at(0, 0.5, 0), body)
		P("Cintura", 1.9, 1.1, 1.3, at(0, -0.7, 0), if look == "Gigante" then skin else body)
		P("Faldon", 2.1, 0.9, 1.5, at(0, -1.3, 0), belly, Enum.Material.Fabric)
		if look == "Gigante" then
			P("Pieles", 2.9, 0.7, 1.8, at(0, 1.0, 0), rgb(236, 240, 246), Enum.Material.Snow)
		elseif look == "Minotauro" then
			P("Correa", 0.4, 1.9, 1.8, at(0.5, 0.4, 0) * CFrame.Angles(0, 0, 0.5), belly, Enum.Material.Fabric)
		end
	else
		P("Tronco", 1.9, 2.3, 1.15, at(0, 0, 0), body)
		P("Cinto", 2.0, 0.3, 1.25, at(0, -0.7, 0), belly:Lerp(DARK, 0.4))
		if robe then
			P("Tunica", 2.1, hipk * 0.8, 1.5, at(0, Yk - hipk * 0.4, 0), body, Enum.Material.Fabric)
			neon(P("Ribete", 2.14, 0.14, 1.54, at(0, Yk - hipk * 0.75, 0), glow))
			P("Manto", 2.5, 0.5, 1.6, at(0, 1.05, 0), belly, Enum.Material.Fabric)
			neon(P("Broche", 0.4, 0.4, 0.12, at(0, 0.6, -0.62), glow))
		elseif look == "Momia" then
			for i = -1, 1 do
				P("Venda", 1.96, 0.22, 1.2, at(0, i * 0.7, 0) * CFrame.Angles(0, 0, 0.25 * (if i == 0 then -1 else 1)), body:Lerp(DARK, 0.3), Enum.Material.Fabric)
			end
			P("Jiron", 0.3, 1.2, 0.1, at(0.6, -1.6, -0.5), belly, Enum.Material.Fabric)
		elseif look == "Caballero" then
			P("Peto", 2.0, 1.2, 1.3, at(0, 0.5, 0), belly, Enum.Material.Metal)
			neon(P("Emblema", 0.5, 0.5, 0.1, at(0, 0.6, -0.68), glow))
			P("Capa", 1.9, 3.2, 0.15, at(0, -0.6, 0.8) * CFrame.Angles(math.rad(-10), 0, 0), glow:Lerp(DARK, 0.75), Enum.Material.Fabric)
		elseif look == "Bandido" then
			P("Correa", 0.3, 2.5, 1.2, at(0, 0, 0) * CFrame.Angles(0, 0, 0.6), belly, Enum.Material.Fabric)
		end
	end

	-- CABEZA (grande, como en el cartel)
	local hs = if big then 1.6 elseif bone then 1.3 else 1.5
	local headY = (if big then 1.25 else 1.2) + hs / 2 + 0.05
	local head = at(0, headY, -0.1)
	local function eyes(dy: number, size: number, color: Color3?)
		for _, s in { -1, 1 } do
			x.Eye(x.Model, x.Root, head * at(s * hs * 0.24, dy, -hs / 2), size * k, color or glow)
		end
	end
	if bone then
		P("Cabeza", hs, hs, hs, head, IVORY)
		for _, s in { -1, 1 } do
			P("Cuenca", 0.4, 0.4, 0.1, head * at(s * 0.3, 0.1, -hs / 2 - 0.01), DARK)
		end
		eyes(0.1, 0.2)
		P("Mandibula", 1.0, 0.3, 0.9, head * at(0, -hs / 2 - 0.1, -0.15), IVORY)
		P("Casco", 1.4, 0.5, 1.4, head * at(0, hs / 2, 0), belly, Enum.Material.Metal)
	elseif robe then
		P("Cabeza", 1.2, 1.2, 1.2, head, if sp.Skull then IVORY else DARK)
		if sp.Skull then
			for _, s in { -1, 1 } do
				P("Cuenca", 0.36, 0.36, 0.1, head * at(s * 0.28, 0.1, -0.61), DARK)
			end
			eyes(0.1, 0.2)
		else
			eyes(0.1, 0.3)
		end
		local F = Enum.Material.Fabric
		P("Capucha", 1.7, 0.45, 1.7, head * at(0, 0.8, 0.1), body, F)
		P("Capucha", 1.7, 1.6, 0.4, head * at(0, 0.05, 0.8), body, F)
		for _, s in { -1, 1 } do
			P("Capucha", 0.26, 1.5, 1.5, head * at(s * 0.73, 0.05, 0.15), body, F)
		end
		P("Capucha", 0.8, 0.5, 0.9, head * at(0, 0.85, 1.0) * CFrame.Angles(math.rad(-25), 0, 0), body, F)
	elseif floats then
		neon(P("Cabeza", 1.25, 1.25, 1.25, head, body, fire))
		for i = -1, 1 do
			neon(P("Llama", 0.4, 0.9 - math.abs(i) * 0.3, 0.4, head * at(i * 0.4, 0.95 - math.abs(i) * 0.15, 0.1), if i == 0 then glow else belly, fire))
		end
		eyes(0.05, 0.34, rgb(255, 255, 230))
	else
		local headColor = if look == "Caballero" then belly elseif look == "Minotauro" or look == "Demonio" then body else skin
		P("Cabeza", hs, hs * (if big then 0.95 else 1), hs, head, headColor, if look == "Caballero" then Enum.Material.Metal else nil)
		if look == "Caballero" then
			neon(P("Visor", 1.1, 0.18, 0.1, head * at(0, 0.1, -hs / 2 - 0.01), glow))
			neon(P("Cresta", 0.2, 0.7, 1.4, head * at(0, hs / 2 + 0.3, 0.1), glow))
			for _, s in { -1, 1 } do
				P("Cuerno", 0.26, 1.0, 0.26, head * at(s * 0.85, 0.75, 0) * CFrame.Angles(0, 0, s * -0.5), DARK, Enum.Material.Metal)
			end
		elseif look == "Bandido" then
			eyes(0.15, 0.28)
			P("Panuelo", hs + 0.06, 0.6, hs + 0.06, head * at(0, -0.42, 0), glow:Lerp(DARK, 0.55), Enum.Material.Fabric)
			P("Capucha", hs + 0.1, 0.4, hs + 0.1, head * at(0, hs / 2 + 0.05, 0), body, Enum.Material.Fabric)
			P("Capucha", hs + 0.1, 1.2, 0.3, head * at(0, 0.1, hs / 2 + 0.1), body, Enum.Material.Fabric)
		elseif look == "Momia" then
			eyes(0.15, 0.3)
			for _, dy in { -0.4, 0.5 } do
				P("Venda", hs + 0.06, 0.22, hs + 0.06, head * at(0, dy, 0) * CFrame.Angles(0, 0, 0.12), body:Lerp(DARK, 0.3), Enum.Material.Fabric)
			end
			P("Jiron", 0.25, 1.0, 0.1, head * at(-0.5, -0.9, 0.6), belly, Enum.Material.Fabric)
		elseif look == "Minotauro" then
			eyes(0.2, 0.3)
			P("Hocico", 1.0, 0.8, 0.8, head * at(0, -0.3, -1.05), belly)
			P("Aro", 0.5, 0.5, 0.1, head * at(0, -0.65, -1.48), GOLD, Enum.Material.Metal)
			for _, s in { -1, 1 } do
				P("Cuerno", 1.1, 0.36, 0.36, head * at(s * 1.25, 0.5, 0), IVORY)
				P("Cuerno", 0.3, 1.0, 0.3, head * at(s * 1.78, 0.95, -0.1) * CFrame.Angles(math.rad(-15), 0, s * 0.15), IVORY)
				P("Oreja", 0.5, 0.3, 0.2, head * at(s * 1.0, 0.05, 0.2), belly)
			end
			P("Melena", 1.4, 1.4, 0.6, head * at(0, -0.3, 0.9), body:Lerp(DARK, 0.4), Enum.Material.Fabric)
		elseif look == "Demonio" then
			eyes(0.2, 0.32)
			P("Mandibula", 1.2, 0.35, 1.2, head * at(0, -hs / 2 - 0.05, -0.2), belly)
			for _, s in { -1, 1 } do
				P("Colmillo", 0.16, 0.4, 0.16, head * at(s * 0.4, -hs / 2 + 0.15, -hs / 2 - 0.05), IVORY)
				P("Cuerno", 0.34, 1.0, 0.34, head * at(s * 0.65, 1.1, 0.1) * CFrame.Angles(math.rad(-15), 0, s * -0.45), DARK)
				neon(P("Punta", 0.24, 0.5, 0.24, head * at(s * 1.0, 1.75, -0.1) * CFrame.Angles(math.rad(-30), 0, s * -0.15), glow))
			end
		elseif look == "Gigante" then
			eyes(0.2, 0.3)
			P("Ceja", 1.5, 0.25, 0.3, head * at(0, 0.5, -hs / 2), rgb(236, 240, 246), Enum.Material.Snow)
			P("Barba", 1.3, 1.1, 0.45, head * at(0, -0.85, -hs / 2 + 0.1), rgb(236, 240, 246), Enum.Material.Snow)
			P("Casco", hs + 0.1, 0.5, hs + 0.1, head * at(0, hs / 2, 0), STEEL, Enum.Material.Metal)
			for _, s in { -1, 1 } do
				P("Cuerno", 0.3, 0.9, 0.3, head * at(s * 0.95, hs / 2 + 0.4, 0) * CFrame.Angles(0, 0, s * -0.4), IVORY)
			end
		else
			eyes(0.15, 0.3)
		end
	end

	-- PIERNAS (el elemental no tiene: flota)
	if not floats then
		local t = if big then 0.95 elseif bone then 0.32 else 0.7
		local legColor = if bone then IVORY elseif look == "Momia" then belly elseif big then body else belly:Lerp(DARK, 0.35)
		for _, s in { -1, 1 } do
			P("Pierna", t, hipk + 0.3, t + 0.1, at(s * (if big then 0.75 else 0.5), Yk - hipk / 2 + 0.15, 0), legColor)
		end
	end

	-- BRAZOS, manos, arma y escudo
	local armLen = if big then 2.7 else 2.2
	local t = if big then 0.95 elseif bone then 0.3 else 0.6
	local armColor = if bone then IVORY elseif look == "Caballero" then belly elseif floats then body elseif look == "Momia" then belly elseif big then body else body
	local shoulderY = if big then 1.15 else 1.0
	for _, s in { -1, 1 } do
		local ax = s * (W + t / 2 + 0.05)
		local cf = at(ax, shoulderY - armLen / 2, 0)
		if look == "Momia" then
			-- (los brazos por delante, como buscándote)
			cf = at(ax, shoulderY - 0.1, 0) * CFrame.Angles(math.rad(80), 0, 0) * at(0, -armLen / 2, 0)
		end
		local arm = P("Brazo", t, armLen, t, cf, armColor, if floats then fire elseif look == "Caballero" then Enum.Material.Metal else nil)
		if floats then
			neon(arm)
		end
		local hand = cf * at(0, -armLen / 2, 0)
		local handPart = P("Mano", t * 1.2, 0.4, t * 1.2, hand, if bone then IVORY elseif floats then glow elseif look == "Caballero" then DARK else skin, nil, nil, arm)
		if floats then
			neon(handPart)
		end
		if look == "Caballero" or look == "Gigante" or look == "Minotauro" then
			P("Hombrera", t * 1.6, 0.5, t * 1.7, cf * at(0, armLen / 2, 0), if look == "Caballero" then belly else belly:Lerp(DARK, 0.2), if look == "Caballero" then Enum.Material.Metal else nil, nil, arm)
		elseif look == "Momia" then
			P("Venda", t + 0.06, 0.2, t + 0.06, cf * at(0, -0.4, 0), body:Lerp(DARK, 0.3), Enum.Material.Fabric, nil, arm)
		elseif look == "Demonio" then
			for i = -1, 1 do
				P("Garra", 0.14, 0.5, 0.14, hand * at(i * 0.3, -0.4, -0.1), DARK, nil, nil, arm)
			end
		end
		if s == 1 and sp.Weapon then
			weapon(x, sp.Weapon, arm, hand)
		elseif s == -1 and sp.Shield then
			P("Escudo", 0.2, 1.8, 1.5, cf * at(-0.5, -0.5, -0.25), belly, Enum.Material.Metal, nil, arm)
			neon(P("Emblema", 0.1, 0.6, 0.5, cf * at(-0.62, -0.5, -0.25), glow, nil, nil, arm))
		end
	end

	-- ALAS y COLA del demonio
	if look == "Demonio" then
		for _, s in { -1, 1 } do
			local wing = P("Ala", 2.8, 2.4, 0.15, at(s * 2.0, 1.2, 1.0) * CFrame.Angles(0, s * -0.35, s * 0.25), belly:Lerp(DARK, 0.3))
			P("Hueso", 2.9, 0.22, 0.22, at(s * 2.0, 1.2, 1.0) * CFrame.Angles(0, s * -0.35, s * 0.25) * at(0, 1.2, 0), DARK, nil, nil, wing)
		end
		local tail = P("Cola", 0.3, 0.3, 2.2, at(0, -1.2, 1.7) * CFrame.Angles(math.rad(-20), 0, 0), body)
		neon(P("Punta", 0.6, 0.15, 0.6, at(0, -0.75, 2.85) * CFrame.Angles(math.rad(-20), 0.78, 0), glow, nil, nil, tail))
	end

	-- el elemental arde
	if floats then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Fuego"
		pe.Color = ColorSequence.new(glow, body)
		pe.LightEmission = 0.8
		pe.Transparency = NumberSequence.new(0.2, 1)
		pe.Size = NumberSequence.new(k * 0.9, 0)
		pe.Lifetime = NumberRange.new(0.5, 0.9)
		pe.Rate = 14
		pe.Speed = NumberRange.new(2, 4)
		pe.SpreadAngle = Vector2.new(25, 25)
		pe.Parent = x.Root
		local light = Instance.new("PointLight")
		light.Name = "Fuego"
		light.Color = body
		light.Range = 14
		light.Brightness = 1.2
		light.Shadows = false
		light.Parent = x.Root
	end
end

-- Una MASA gelatinosa (slime): bola translúcida sobre un charco, con núcleo que brilla, ojos y burbujas
function BeastLooks.blob(x: Ctx)
	local P, at, neon = tools(x)
	local C = x.Sp.Colors
	local Yk = -x.Root.Size.Y / 2 / x.K
	local hipk = x.Hip / x.K
	local jelly = P("Cabeza", 2.8, 2.8, 2.8, at(0, 0.25, 0), C.Body, Enum.Material.Glass, Enum.PartType.Ball)
	jelly.Transparency = 0.3
	local base = P("Charco", 0.8, 3.5, 3.5, at(0, Yk - hipk + 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), C.Belly, Enum.Material.Glass, Enum.PartType.Cylinder)
	base.Transparency = 0.25
	neon(P("Nucleo", 1.0, 1.0, 1.0, at(0, 0.1, 0.1), C.Glow, nil, Enum.PartType.Ball))
	for _, s in { -1, 1 } do
		x.Eye(x.Model, x.Root, at(s * 0.5, 0.6, -1.22), 0.42 * x.K, rgb(255, 255, 220))
		P("Pupila", 0.16, 0.22, 0.1, at(s * 0.5, 0.6, -1.42), DARK)
	end
	P("Boca", 0.9, 0.16, 0.1, at(0, -0.05, -1.4), DARK)
	local bubbles = { { 0.6, 1.5, 0.2, 0.55 }, { -0.5, 1.4, -0.3, 0.4 }, { 0.1, 1.75, -0.4, 0.3 }, { -1.3, 0.2, 0.5, 0.45 }, { 1.35, -0.1, 0.2, 0.35 } }
	for _, b in bubbles do
		local p = P("Burbuja", b[4], b[4], b[4], at(b[1], b[2], b[3]), C.Glow, Enum.Material.Glass, Enum.PartType.Ball)
		p.Transparency = 0.35
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Gotas"
	pe.Color = ColorSequence.new(C.Glow)
	pe.Transparency = NumberSequence.new(0.3, 1)
	pe.Size = NumberSequence.new(x.K * 0.25, 0)
	pe.Lifetime = NumberRange.new(0.6, 1)
	pe.Rate = 4
	pe.Speed = NumberRange.new(1, 2.5)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.Parent = x.Root
end

-- Las ALAS de un dragón (cuadrúpedo o serpiente): membrana con su hueso, a cada lado del lomo
function BeastLooks.dragonWings(x: Ctx, y: number, z: number, span: number)
	local P, at = tools(x)
	local C = x.Sp.Colors
	for _, s in { -1, 1 } do
		local cf = at(s * (0.9 + span / 2), y, z) * CFrame.Angles(0, 0, s * 0.35)
		local wing = P("Ala", span, 0.14, span * 0.7, cf, C.Glow:Lerp(C.Body, 0.6))
		P("Hueso", span, 0.24, 0.24, cf * at(0, 0.1, -span * 0.33), C.Body:Lerp(DARK, 0.3), nil, nil, wing)
		P("Hueso", 0.2, 0.2, span * 0.65, cf * at(s * span * 0.45, 0.1, 0), C.Body:Lerp(DARK, 0.3), nil, nil, wing)
	end
end

-- Las OCHO PATAS de una araña: un tramo que sube desde el cuerpo y otro que baja hasta el suelo
function BeastLooks.spiderLegs(x: Ctx, floorY: number)
	local P, at = tools(x)
	local C = x.Sp.Colors
	local k = x.K
	for _, s in { -1, 1 } do
		for _, i in { -1.5, -0.5, 0.5, 1.5 } do
			local z = i * 0.75 - 0.4
			local upper = P("Pata", 1.6, 0.26, 0.26, at(s * 1.6, 0.3, z) * CFrame.Angles(0, 0, s * 0.45), C.Body)
			-- (del codo —arriba y fuera— al suelo)
			local elbow = Vector3.new(s * 2.32, 0.65, z)
			local foot = Vector3.new(s * 2.9, floorY / k, z)
			local mid = (elbow + foot) / 2
			local len = (foot - elbow).Magnitude
			P("Pata2", len, 0.2, 0.2, at(mid.X, mid.Y, mid.Z) * CFrame.Angles(0, 0, -s * math.atan2(elbow.Y - foot.Y, math.abs(foot.X - elbow.X))), C.Belly, nil, nil, upper)
		end
	end
end

return BeastLooks
