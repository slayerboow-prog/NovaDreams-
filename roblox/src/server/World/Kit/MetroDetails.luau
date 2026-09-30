-- MetroDetails: los detalles que dan vida al metro (los usa MetroKit; los anima MetroLifeService).
--
--   * Andenes: columnas, cámaras de seguridad, altavoces, extintor, interfono de emergencia
--     (MetroIntercom), cabina de teléfono (MetroPhone), carteles de anuncios, grafitis junto a los
--     túneles, goteras con charcos, basura en la vía y nidos de ratas (MetroRatNest).
--   * Vestíbulos: aseos con váteres (MetroToilet), lavabos (MetroSink) y secamanos (MetroDryer);
--     garita de seguridad con guardia que patrulla (MetroGuardPost), taquillas (MetroLocker),
--     cajero (MetroATM), papelera (MetroBin), puesto de comida (MetroShop), limpiador/a y una
--     lámpara que parpadea (MetroFlicker).
--   * Galería de Plaza Mayor: carritos y puestos (MetroShop), aseos grandes, fuente de los deseos
--     (MetroFountain), piano de cola (MetroPiano), limpiabotas (MetroShine), estatua humana
--     (MetroStatue), panel de salidas (MetroDisplay), oficina de seguridad con monitores y guardias.
--
-- Todas las funciones reciben el CFrame de la zona (el mismo marco que MetroKit: X a la derecha,
-- Z a lo largo de la vía, Y = 0 en el suelo).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Metro = require(ReplicatedStorage.Shared.Metro)

local MetroDetails = {}

local rgb = Color3.fromRGB
local DARK = rgb(34, 36, 42)
local STEEL = rgb(170, 174, 180)
local WHITE = rgb(240, 240, 238)
local RED = rgb(200, 30, 40)
local WOOD = rgb(140, 100, 64)
local TILE_BLUE = rgb(150, 190, 215)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function decor(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

local function marker(parent: Instance, name: string, cf: CFrame, tag: string, attrs: { [string]: any }?, size: Vector3?): BasePart
	return Builder.part({
		Name = name,
		Size = size or Vector3.new(2, 2, 2),
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Tags = { tag },
		Attributes = attrs,
		Parent = parent,
	})
end

local function sign(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3, textColor: Color3?): BasePart
	local board = decor(parent, "Sign", size, cf, color)
	Builder.sign(board, text, Enum.NormalId.Front, textColor)
	return board
end

local function lamp(parent: Instance, cf: CFrame, size: Vector3, range: number, color: Color3?): BasePart
	local l = decor(parent, "Lamp", size, cf, rgb(250, 250, 255), Enum.Material.Neon)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 120
	light.Range = range
	light.Brightness = 1.2
	light.Color = color or rgb(255, 248, 235)
	light.Shadows = false
	light.Parent = l
	return l
end

-- Gotas que caen del techo (y el charco debajo)
local function drip(parent: Instance, top: CFrame, floorY: number)
	local p = decor(parent, "Leak", Vector3.new(0.6, 0.1, 0.6), top, rgb(90, 88, 84), Enum.Material.Concrete)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Drips"
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Rate = 2
	e.Lifetime = NumberRange.new(0.9, 1.2)
	e.Speed = NumberRange.new(4, 5)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Size = NumberSequence.new(0.14)
	e.Color = ColorSequence.new(rgb(170, 200, 230))
	e.Transparency = NumberSequence.new(0.3)
	e.LightEmission = 0.2
	e.Parent = p
	local puddle = decor(parent, "Puddle", Vector3.new(0.05, 3.2, 3.8), CFrame.new(top.Position.X, floorY + 0.03, top.Position.Z) * CFrame.Angles(0, 0, math.rad(90)), rgb(70, 90, 110), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.35, Reflectance = 0.25 })
	local _ = puddle
end

-- Cámara de seguridad con su lucecita roja
local function camera(parent: Instance, cf: CFrame)
	decor(parent, "CamArm", Vector3.new(0.3, 0.3, 1.4), cf * CFrame.new(0, 0, 0.7), DARK, Enum.Material.Metal)
	decor(parent, "Camera", Vector3.new(0.9, 0.8, 1.6), cf * CFrame.new(0, -0.3, -0.4) * CFrame.Angles(math.rad(-20), 0, 0), WHITE)
	decor(parent, "CamLed", Vector3.new(0.18, 0.18, 0.1), cf * CFrame.new(0.25, -0.1, -1.25), rgb(255, 30, 30), Enum.Material.Neon)
end

-- Extintor rojo en la pared con su cartelito
local function extinguisher(parent: Instance, cf: CFrame)
	decor(parent, "Extinguisher", Vector3.new(0.9, 2.2, 0.9), cf * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.rad(90)), RED, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	decor(parent, "ExtHose", Vector3.new(0.2, 1.2, 0.2), cf * CFrame.new(0.45, 2.3, -0.2), DARK)
	sign(parent, cf * CFrame.new(0, 3.9, 0.35), Vector3.new(1.4, 0.9, 0.1), "🧯", RED)
end

-- Cartel de anuncio iluminado
local ADS = {
	{ "🍔 BURGER VALMAR\n¡2x1 los martes!", rgb(230, 120, 30) },
	{ "🏖️ PLAYA DORADA\nEl verano empieza en la L1", rgb(40, 160, 200) },
	{ "🎬 ESTRENO\n«Robots en la ciudad»", rgb(120, 40, 160) },
	{ "📱 ValPhone 12\nMás batería que nunca", rgb(30, 30, 40) },
	{ "🏥 Hospital de Valmar\nDona sangre, salva vidas", rgb(200, 40, 60) },
	{ "🎡 FERIA DE VALMAR\nNoria gratis los domingos", rgb(240, 180, 30) },
	{ "🥛 Leche La Vaquita\nFresca de verdad", rgb(80, 160, 90) },
	{ "🚗 AUTOESCUELA VALMAR\n¡Saca el carnet ya!", rgb(30, 90, 170) },
	{ "🐾 ADOPTA\nRefugio de animales de Valmar", rgb(150, 100, 60) },
	{ "💤 COLCHONES NUBE\nDuerme como un bebé", rgb(110, 140, 220) },
}
local adIndex = 0
local function advert(parent: Instance, cf: CFrame, size: Vector2)
	adIndex = adIndex % #ADS + 1
	local ad = ADS[adIndex]
	decor(parent, "AdFrame", Vector3.new(size.X + 0.6, size.Y + 0.6, 0.2), cf * CFrame.new(0, 0, 0.12), rgb(200, 200, 205), Enum.Material.Metal)
	local board = decor(parent, "Advert", Vector3.new(size.X, size.Y, 0.1), cf, ad[2])
	Builder.sign(board, ad[1], Enum.NormalId.Front, Color3.new(1, 1, 1), ad[2])
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Front
	light.Range = 6
	light.Brightness = 0.6
	light.Parent = board
end

-- Grafiti: manchas de colores y unas letras en la pared
local GRAFFITI = { "VLM", "L1 4EVER", "METRO KINGS", "☮", "SUB-WAY", "ZONA 8", "¿Y TÚ QUÉ MIRAS?" }
local function graffiti(parent: Instance, cf: CFrame, seed: number)
	local colors = { rgb(240, 60, 150), rgb(60, 220, 120), rgb(250, 210, 40), rgb(60, 160, 250), rgb(250, 110, 40) }
	for i = 1, 4 do
		local c = colors[(seed + i) % #colors + 1]
		decor(parent, "Paint", Vector3.new(2 + (i * 1.3) % 3, 1 + (i * 0.7) % 1.5, 0.05), cf * CFrame.new(-3 + i * 1.6, -1 + (i % 2) * 1.2, 0) * CFrame.Angles(0, 0, math.rad(-15 + i * 9)), c)
	end
	local board = decor(parent, "Tag", Vector3.new(7, 2.2, 0.05), cf * CFrame.new(0, 0.2, -0.05), Color3.new(0, 0, 0), nil, { Transparency = 1 })
	local label = Builder.sign(board, GRAFFITI[seed % #GRAFFITI + 1], Enum.NormalId.Front, colors[seed % #colors + 1])
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextStrokeTransparency = 0
	label.Rotation = -6
end

-- Basura por el suelo (latas, papeles, chicles)
local function litter(parent: Instance, cf: CFrame, count: number, spread: Vector2, seed: number)
	-- Generador propio (siempre igual para la misma semilla, también al construir con Lune)
	local state = seed * 7919 + 17
	local function rand(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
	local function between(a: number, b: number): number
		return a + (b - a) * rand()
	end
	for _ = 1, count do
		local x, z = between(-spread.X, spread.X), between(-spread.Y, spread.Y)
		local kind = math.floor(rand() * 3) + 1
		if kind == 1 then
			decor(parent, "Can", Vector3.new(0.8, 0.45, 0.45), cf * CFrame.new(x, 0.23, z) * CFrame.Angles(0, between(0, 6.28), 0), Color3.fromHSV(rand(), 0.7, 0.8), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		elseif kind == 2 then
			decor(parent, "Paper", Vector3.new(0.6, 0.5, 0.6), cf * CFrame.new(x, 0.25, z), rgb(235, 232, 220), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		else
			decor(parent, "Gum", Vector3.new(0.4, 0.05, 0.4), cf * CFrame.new(x, 0.03, z), rgb(60, 60, 64))
		end
	end
end

-- Papelera con la que se puede rebuscar
local function bin(parent: Instance, cf: CFrame)
	local b = part(parent, "Bin", Vector3.new(1.4, 2.2, 1.4), cf * CFrame.new(0, 1.1, 0), rgb(50, 110, 70), Enum.Material.Metal, { Tags = { "MetroBin" } })
	local _ = b
	decor(parent, "BinLid", Vector3.new(1.6, 0.2, 1.6), cf * CFrame.new(0, 2.3, 0), DARK, Enum.Material.Metal)
	decor(parent, "BinTrash", Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(0.2, 2.5, 0.1), rgb(230, 225, 210), nil, { Shape = Enum.PartType.Ball })
end

-- Guardia de seguridad: MetroLifeService lo crea cuando hay alguien cerca y lo hace patrullar de A a B
local function guardPost(parent: Instance, a: Vector3, b: Vector3, role: string?, name: string?)
	marker(parent, name or "GuardPost", CFrame.new(a + Vector3.new(0, 1, 0)), "MetroGuardPost", { A = a, B = b, Role = role or "Guard" })
end

-- Nido de ratas: corretean entre A y B
local function ratNest(parent: Instance, a: Vector3, b: Vector3)
	marker(parent, "RatNest", CFrame.new(a + Vector3.new(0, 0.5, 0)), "MetroRatNest", { A = a, B = b })
end

---------------------------------------------------------------------
-- Aseos (marco local: la puerta en la cara -Z, W de ancho en X, D de fondo en Z)
---------------------------------------------------------------------
function MetroDetails.restroom(parent: Instance, cf: CFrame, W: number, D: number, H: number, stalls: number)
	local m = Builder.model("Aseos", parent)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local door = 4.4
	-- Suelo de baldosas, paredes y techo
	decor(m, "RestFloor", Vector3.new(W - 0.4, 0.06, D - 0.4), at(0, 0.03, 0), TILE_BLUE, Enum.Material.Slate)
	local side = (W - door) / 2
	part(m, "RestFront", Vector3.new(side, H, 0.6), at(-W / 2 + side / 2, H / 2, -D / 2), WHITE, Enum.Material.Marble)
	part(m, "RestFront", Vector3.new(side, H, 0.6), at(W / 2 - side / 2, H / 2, -D / 2), WHITE, Enum.Material.Marble)
	part(m, "RestFrontTop", Vector3.new(door, 1.6, 0.6), at(0, H - 0.8, -D / 2), WHITE, Enum.Material.Marble)
	part(m, "RestBack", Vector3.new(W, H, 0.6), at(0, H / 2, D / 2), WHITE, Enum.Material.Marble)
	for _, x in { -W / 2, W / 2 } do
		part(m, "RestSide", Vector3.new(0.6, H, D), at(x, H / 2, 0), WHITE, Enum.Material.Marble)
	end
	part(m, "RestCeiling", Vector3.new(W, 0.4, D), at(0, H + 0.2, 0), rgb(220, 220, 215), Enum.Material.Concrete)
	decor(m, "Tiles", Vector3.new(W - 1.2, 3, 0.1), at(0, 1.5, D / 2 - 0.35), TILE_BLUE, Enum.Material.Slate)
	lamp(m, at(0, H - 0.1, 0), Vector3.new(W * 0.5, 0.15, 1), 14)
	-- Cartel de la puerta (por fuera)
	local s = decor(m, "RestSign", Vector3.new(5, 1.3, 0.15), at(0, H + 0.9, -D / 2 - 0.35) * CFrame.Angles(0, math.rad(180), 0), rgb(30, 90, 170))
	Builder.sign(s, "🚻 ASEOS", Enum.NormalId.Front)
	-- Cabinas con váter en el fondo
	local sw = 3.6
	for i = 0, stalls - 1 do
		local x = -W / 2 + 0.3 + sw * (i + 0.5)
		if x + sw / 2 > W / 2 - 3.5 then
			break
		end
		part(m, "Partition", Vector3.new(0.2, 6, 4.2), at(x + sw / 2, 3.3, D / 2 - 2.4), rgb(80, 150, 190))
		if i == 0 then
			part(m, "Partition", Vector3.new(0.2, 6, 4.2), at(x - sw / 2, 3.3, D / 2 - 2.4), rgb(80, 150, 190))
		end
		-- Puerta de la cabina, abierta hacia fuera
		decor(m, "StallDoor", Vector3.new(0.15, 5.4, 2.6), at(x - sw / 2 + 0.2, 3.2, D / 2 - 5.8) * CFrame.Angles(0, math.rad(-35), 0), rgb(80, 150, 190))
		-- Váter: taza, cisterna y rollo
		part(m, "Bowl", Vector3.new(1.6, 1.4, 2), at(x, 0.7, D / 2 - 1.6), WHITE, Enum.Material.Marble)
		decor(m, "Tank", Vector3.new(1.8, 1.8, 0.7), at(x, 2.2, D / 2 - 0.65), WHITE, Enum.Material.Marble)
		decor(m, "Flush", Vector3.new(0.4, 0.15, 0.4), at(x, 3.15, D / 2 - 0.65), STEEL, Enum.Material.Metal)
		decor(m, "Roll", Vector3.new(0.5, 0.7, 0.7), at(x + 1.4, 2.2, D / 2 - 1.2) * CFrame.Angles(0, 0, math.rad(90)), WHITE, nil, { Shape = Enum.PartType.Cylinder })
		local seat = Instance.new("Seat")
		seat.Name = "ToiletSeat"
		seat.Size = Vector3.new(1.6, 0.2, 1.8)
		seat.CFrame = at(x, 1.45, D / 2 - 1.8) * CFrame.Angles(0, math.rad(180), 0) -- mirando a la puerta
		seat.Color = WHITE
		seat.Material = Enum.Material.SmoothPlastic
		seat.Anchored = true
		seat:AddTag("MetroToilet")
		seat.Parent = m
	end
	-- Lavabos y espejo en la pared derecha
	local sx = W / 2 - 1.1
	for i, z in { -D / 2 + 2.6, -D / 2 + 5 } do
		if z < D / 2 - 5 then
			part(m, "Sink", Vector3.new(1.6, 0.6, 1.8), at(sx, 3, z), WHITE, Enum.Material.Marble, { Tags = { "MetroSink" } })
			decor(m, "SinkPipe", Vector3.new(0.4, 2.7, 0.4), at(sx + 0.3, 1.35, z), STEEL, Enum.Material.Metal)
			local tap = decor(m, "Tap", Vector3.new(0.6, 0.3, 0.2), at(sx + 0.5, 3.6, z), STEEL, Enum.Material.Metal)
			tap:SetAttribute("Index", i)
			local water = Instance.new("ParticleEmitter")
			water.Name = "Water"
			water.Enabled = false
			water.EmissionDirection = Enum.NormalId.Bottom
			water.Rate = 40
			water.Lifetime = NumberRange.new(0.25)
			water.Speed = NumberRange.new(3)
			water.Size = NumberSequence.new(0.18)
			water.Color = ColorSequence.new(rgb(170, 210, 240))
			water.Transparency = NumberSequence.new(0.3)
			water.Parent = tap
		end
	end
	decor(m, "Mirror", Vector3.new(0.1, 2.4, 3), at(W / 2 - 0.35, 5.6, -D / 2 + 2.6), rgb(200, 215, 225), Enum.Material.Glass, { Reflectance = 0.6 })
	local dryer = part(m, "HandDryer", Vector3.new(0.9, 1.2, 1.4), at(W / 2 - 0.8, 4.2, -D / 2 + 5.2), STEEL, Enum.Material.Metal, { Tags = { "MetroDryer" } })
	local air = Instance.new("ParticleEmitter")
	air.Name = "Air"
	air.Enabled = false
	air.EmissionDirection = Enum.NormalId.Bottom
	air.Rate = 30
	air.Lifetime = NumberRange.new(0.3, 0.5)
	air.Speed = NumberRange.new(6)
	air.Size = NumberSequence.new(0.2, 0.6)
	air.Transparency = NumberSequence.new(0.6, 1)
	air.Parent = dryer
	-- Cartel de "suelo mojado" y papelera
	local wet = decor(m, "WetFloor", Vector3.new(1.4, 2.2, 0.15), at(-W / 2 + 2, 1.1, -D / 2 + 1.6) * CFrame.Angles(math.rad(-12), math.rad(20), 0), rgb(250, 210, 30))
	Builder.sign(wet, "⚠️\nSUELO\nMOJADO", Enum.NormalId.Front, DARK, rgb(250, 210, 30))
	decor(m, "RestBin", Vector3.new(1, 1.4, 1), at(W / 2 - 1, 0.7, -D / 2 + 1.2), STEEL, Enum.Material.Metal)
	return m
end

---------------------------------------------------------------------
-- Taquillas (se abren y se cierran; a veces hay algo dentro)
---------------------------------------------------------------------
local function lockers(parent: Instance, cf: CFrame, cols: number, rows: number)
	local m = Builder.model("Taquillas", parent)
	local w, h = 1.6, 2.2
	part(m, "LockerFrame", Vector3.new(cols * w + 0.2, rows * h + 0.2, 1.4), cf * CFrame.new(0, rows * h / 2 + 0.6, 0.7), rgb(90, 96, 110), Enum.Material.Metal)
	local colors = { rgb(230, 110, 40), rgb(40, 150, 200), rgb(90, 180, 90), rgb(220, 60, 90) }
	for c = 0, cols - 1 do
		for r = 0, rows - 1 do
			local x = -cols * w / 2 + w * (c + 0.5)
			local y = 0.6 + h * (r + 0.5)
			local door = part(m, "LockerDoor", Vector3.new(w - 0.15, h - 0.15, 0.12), cf * CFrame.new(x, y, -0.06), colors[(c + r) % #colors + 1], Enum.Material.Metal, { Tags = { "MetroLocker" } })
			door:SetAttribute("Hinge", (cf * CFrame.new(x - w / 2 + 0.1, y, -0.06)).Position)
			Builder.sign(door, tostring(c * rows + r + 1), Enum.NormalId.Front, Color3.new(1, 1, 1))
		end
	end
end

-- Cajero automático
local function atm(parent: Instance, cf: CFrame)
	part(parent, "ATM", Vector3.new(2.6, 5.4, 1.4), cf * CFrame.new(0, 2.7, 0.7), rgb(40, 60, 90), Enum.Material.Metal, { Tags = { "MetroATM" } })
	decor(parent, "ATMScreen", Vector3.new(1.6, 1.1, 0.1), cf * CFrame.new(0, 3.9, -0.05), rgb(90, 200, 255), Enum.Material.Neon)
	decor(parent, "ATMKeys", Vector3.new(1.4, 0.8, 0.3), cf * CFrame.new(0, 2.7, -0.15) * CFrame.Angles(math.rad(-30), 0, 0), STEEL, Enum.Material.Metal)
	sign(parent, cf * CFrame.new(0, 5.8, -0.02), Vector3.new(2.6, 0.7, 0.1), "💳 CAJERO", rgb(30, 90, 170))
end

-- Cabina de teléfono
local function phone(parent: Instance, cf: CFrame)
	decor(parent, "PhoneHood", Vector3.new(2.6, 3.6, 1.6), cf * CFrame.new(0, 5.2, 0.4), rgb(20, 110, 180), Enum.Material.SmoothPlastic, { Transparency = 0.1 })
	local p = part(parent, "Phone", Vector3.new(1.2, 1.8, 0.6), cf * CFrame.new(0, 4.6, 0), rgb(60, 62, 70), Enum.Material.Metal, { Tags = { "MetroPhone" } })
	local _ = p
	decor(parent, "Handset", Vector3.new(0.35, 1.2, 0.35), cf * CFrame.new(-0.75, 4.7, -0.2), DARK)
	sign(parent, cf * CFrame.new(0, 7.3, -0.45), Vector3.new(2.4, 0.7, 0.1), "📞 TELÉFONO", rgb(20, 110, 180))
end

-- Interfono de emergencia
local function intercom(parent: Instance, cf: CFrame)
	part(parent, "Intercom", Vector3.new(1.4, 2, 0.4), cf * CFrame.new(0, 4.4, 0), rgb(250, 200, 30), Enum.Material.SmoothPlastic, { Tags = { "MetroIntercom" } })
	decor(parent, "SOSButton", Vector3.new(0.6, 0.6, 0.15), cf * CFrame.new(0, 4.1, -0.25), RED, Enum.Material.Neon)
	sign(parent, cf * CFrame.new(0, 5.8, -0.05), Vector3.new(1.6, 0.6, 0.1), "SOS", RED)
end

-- Altavoz del techo
local function speaker(parent: Instance, cf: CFrame)
	decor(parent, "Speaker", Vector3.new(1.2, 0.8, 1.2), cf, rgb(220, 220, 220), Enum.Material.SmoothPlastic)
	decor(parent, "SpeakerGrill", Vector3.new(0.9, 0.1, 0.9), cf * CFrame.new(0, -0.42, 0), DARK)
end

-- Carrito / puesto con toldo de rayas: MetroShop con dependiente detrás
local function cart(parent: Instance, cf: CFrame, shopId: string, title: string, color: Color3)
	local m = Builder.model("Puesto_" .. shopId, parent)
	local counter = part(m, "Cart", Vector3.new(6, 3.2, 2.6), cf * CFrame.new(0, 1.6, 0), color:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.SmoothPlastic, { Tags = { "MetroShop" } })
	counter:SetAttribute("ShopId", shopId)
	counter:SetAttribute("StaffSpot", (cf * CFrame.new(0, 0.4, 2.8)).Position)
	decor(m, "CartTop", Vector3.new(6.4, 0.3, 3), cf * CFrame.new(0, 3.35, 0), WOOD, Enum.Material.Wood)
	for _, x in { -2.9, 2.9 } do
		decor(m, "AwningPole", Vector3.new(0.25, 4.4, 0.25), cf * CFrame.new(x, 5.4, 1.1), STEEL, Enum.Material.Metal)
	end
	for i = 0, 5 do
		decor(m, "Awning", Vector3.new(1.1, 0.2, 3.6), cf * CFrame.new(-2.75 + i * 1.1, 7.7, 0.3) * CFrame.Angles(math.rad(-12), 0, 0), if i % 2 == 0 then color else WHITE)
	end
	local s = decor(m, "CartSign", Vector3.new(5.6, 1.1, 0.15), cf * CFrame.new(0, 6.6, -1.3), color)
	Builder.sign(s, title, Enum.NormalId.Front)
	-- Cosas encima del mostrador
	for i = -2, 2 do
		decor(m, "Goods", Vector3.new(0.8, 0.8, 0.8), cf * CFrame.new(i * 1.1, 3.9, -0.4), color:Lerp(Color3.fromHSV((i + 3) / 6, 0.6, 0.95), 0.6), nil, { Shape = if i % 2 == 0 then Enum.PartType.Ball else Enum.PartType.Block })
	end
	for _, x in { -2.3, 2.3 } do
		decor(m, "Wheel", Vector3.new(0.4, 1.2, 1.2), cf * CFrame.new(x, 0.6, -1.35) * CFrame.Angles(0, 0, 0), DARK, nil, { Shape = Enum.PartType.Cylinder })
	end
	local glow = Instance.new("PointLight")
	glow.Range = 10
	glow.Brightness = 0.8
	glow.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	glow.Parent = s
	return m
end

---------------------------------------------------------------------
-- Andén
---------------------------------------------------------------------
function MetroDetails.platform(m: Instance, cf: CFrame, line: Metro.Line, stationId: string, seed: number)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local P = Metro.PlatformLength / 2
	local faceTrack = CFrame.Angles(0, math.rad(90), 0) -- mirando a -X (hacia la vía), para lo pegado a la pared del andén
	-- Columnas de azulejo con franja de la línea
	for _, z in { -64, -18, 18, 64 } do
		part(m, "Column", Vector3.new(1.6, 16, 1.6), at(13.5, 7.5, z), rgb(225, 222, 214), Enum.Material.Marble)
		decor(m, "ColumnBand", Vector3.new(1.7, 0.6, 1.7), at(13.5, 8.5, z), line.Color)
		decor(m, "ColumnSign", Vector3.new(0.1, 1, 1.5), at(12.65, 10.5, z), line.Color)
	end
	-- Bandas táctiles al borde del andén
	decor(m, "TactileStrip", Vector3.new(0.9, 0.08, P * 2 - 2), at(6.5, 0.04, 0), rgb(190, 190, 185), Enum.Material.DiamondPlate)
	-- Cámaras, altavoces, extintor, interfono, teléfono y anuncios
	for _, z in { -60, 0, 60 } do
		camera(m, at(16.6, 14.5, z) * faceTrack * CFrame.Angles(0, 0, 0))
	end
	for _, z in { -45, -5, 35 } do
		speaker(m, at(9, 15.6, z))
	end
	extinguisher(m, at(16.5, 0, -8) * faceTrack)
	-- (el interfono, lejos de los tornos: pegado a ellos, su "Pulsar SOS" le quitaba el botón
	-- Interactuar al torno en el móvil, a los dos lados del cristal)
	intercom(m, at(16.75, 0, 46) * faceTrack)
	phone(m, at(16.2, 0, -22) * faceTrack)
	for _, z in { -58, -12, 22, 60 } do
		advert(m, at(16.9, 6, z) * faceTrack, Vector2.new(6, 4))
	end
	-- Anuncios grandes en la pared del otro lado de la vía (entre los nombres de la estación)
	for _, z in { -33.25, -1.25, 30.75 } do
		advert(m, at(-5.4, 6.5, z) * CFrame.Angles(0, math.rad(-90), 0), Vector2.new(7, 4.4))
	end
	-- Grafitis junto a las bocas de los túneles
	graffiti(m, at(-5.35, 4, -P + 6) * CFrame.Angles(0, math.rad(-90), 0), seed)
	graffiti(m, at(-5.35, 4, P - 6) * CFrame.Angles(0, math.rad(-90), 0), seed + 3)
	-- Goteras con charco (una en la vía y otra en el andén)
	drip(m, at(2, 16, -50 + (seed % 3) * 10), at(0, -1, 0).Position.Y + 0.02)
	drip(m, at(14, 16, 50 - (seed % 4) * 8), at(0, 0, 0).Position.Y)
	-- Basura en la vía y alguna lata en el andén
	litter(m, at(0, -0.95, 0), 14, Vector2.new(4, P - 6), seed * 7 + 1)
	litter(m, at(14, 0, 0), 4, Vector2.new(1.5, P - 10), seed * 7 + 2)
	-- Ratas correteando por la vía
	ratNest(m, at(-3.2, -1, -P + 8).Position, at(-3.2, -1, -12).Position)
	ratNest(m, at(3.4, -1, 12).Position, at(3.4, -1, P - 8).Position)
	-- Cartel de "no cruzar la vía" y reloj
	local caution = decor(m, "Warning", Vector3.new(0.1, 1.6, 4), at(16.9, 3, 30), rgb(250, 210, 30))
	Builder.sign(caution, "⚠️ NO CRUCES LA VÍA", Enum.NormalId.Left, DARK, rgb(250, 210, 30))
	local _ = stationId
end

---------------------------------------------------------------------
-- Vestíbulo (X0..X1 a lo ancho, ±LZ a lo largo, LH de alto)
---------------------------------------------------------------------
local LOBBY_SHOPS = {
	Poniente = { "Donuts", "🍩 DÓNUTS & CO.", rgb(230, 110, 160) },
	Levante = { "Pizza", "🍕 PIZZA AL CORTE", rgb(220, 70, 40) },
	PlayaDorada = { "Palomitas", "🍿 PALOMITAS", rgb(240, 180, 30) },
	Norte = { "Kebab", "🌯 KEBAB ANDÉN 2", rgb(180, 110, 40) },
	SanRoque = { "Floristeria", "💐 FLORISTERÍA", rgb(80, 170, 90) },
	Puerto = { "Recuerdos", "🧲 RECUERDOS", rgb(40, 130, 200) },
}

function MetroDetails.lobby(m: Instance, cf: CFrame, line: Metro.Line, stationId: string, hub: boolean, seed: number)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local X0, X1, LZ, LH = 17.5, 47.5, 25, 13
	-- Aseos en el rincón del fondo (en Plaza Mayor están en la galería)
	if not hub then
		MetroDetails.restroom(m, at(42.9, 0, -4) * CFrame.Angles(0, math.rad(90), 0), 16, 8.6, 8.5, 2)
	end
	-- Garita de seguridad con monitores
	part(m, "GuardDesk", Vector3.new(2.4, 3.2, 5), at(23, 1.6, 15), rgb(50, 56, 70), Enum.Material.Metal)
	decor(m, "DeskTop", Vector3.new(2.8, 0.2, 5.4), at(23, 3.3, 15), rgb(120, 124, 130), Enum.Material.Metal)
	for i, z in { 13.6, 15, 16.4 } do
		local screen = decor(m, "Monitor", Vector3.new(0.2, 1, 1.3), at(23.8, 4.1, z), rgb(60, 110 + i * 30, 90), Enum.Material.Neon)
		Builder.sign(screen, "CAM " .. i, Enum.NormalId.Right, Color3.new(1, 1, 1))
	end
	sign(m, at(23, 5.6, 12.2) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(3.6, 0.9, 0.15), "🛡️ SEGURIDAD", rgb(30, 50, 90))
	guardPost(m, at(24, 0, 10).Position, at(36, 0, -8).Position, "Guard")
	-- Limpiador/a que pasa la fregona por el vestíbulo
	-- (en Plaza Mayor las escaleras mecánicas bajan del techo junto a la galería: allí friega más adentro)
	guardPost(m, at(28, 0, 4).Position, at(if hub then 30 else 40, 0, if hub then -6 else 10).Position, "Cleaner", "CleanerPost")
	-- Taquillas, cajero y papelera en la pared +Z
	lockers(m, at(22, 0, LZ - 0.8), 3, 2)
	atm(m, at(30.5, 0, LZ - 0.7))
	bin(m, at(33, 0, LZ - 2))
	bin(m, at(X0 + 1.2, 0, -19)) -- (apartada de los tornos)
	-- Puesto de comida (cada estación el suyo)
	local shop = LOBBY_SHOPS[stationId]
	if shop and not hub then
		cart(m, at(30.5, 0, 17.5), shop[1], shop[2], shop[3])
	end
	-- Cámaras, extintor, anuncio y banco
	camera(m, at(X0 + 1.2, LH - 0.6, -LZ + 1.2) * CFrame.Angles(0, math.rad(-135), 0))
	camera(m, at(X1 - 1.2, LH - 0.6, LZ - 1.2) * CFrame.Angles(0, math.rad(45), 0))
	extinguisher(m, at(26.5, 0, LZ - 0.5))
	advert(m, at(36, 7.5, LZ - 0.55), Vector2.new(5, 3.4))
	-- (el banco, apartado del rellano de las escaleras mecánicas, que llegan por la pared -Z)
	part(m, "LobbyBench", Vector3.new(5, 0.4, 1.6), at(36, 1.5, -21), WOOD, Enum.Material.Wood)
	decor(m, "BenchLeg", Vector3.new(0.3, 1.3, 1.4), at(34, 0.65, -21), DARK)
	decor(m, "BenchLeg", Vector3.new(0.3, 1.3, 1.4), at(38, 0.65, -21), DARK)
	-- Planta grande en una maceta
	part(m, "BigPot", Vector3.new(2.4, 2, 2.4), at(41.5, 1, -LZ + 2), rgb(160, 90, 60), Enum.Material.Concrete)
	decor(m, "BigPlant", Vector3.new(3.2, 4.2, 3.2), at(41.5, 4, -LZ + 2), rgb(60, 140, 70), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
	-- Una lámpara que parpadea (MetroLifeService)
	local flick = lamp(m, at(34, LH - 0.12, 4), Vector3.new(4, 0.15, 1), 16, rgb(230, 240, 255))
	flick:AddTag("MetroFlicker")
	-- Gotera y un poco de basura
	drip(m, at(26, LH, 6 - (seed % 3) * 3), at(0, 0, 0).Position.Y)
	litter(m, at(32, 0, 0), 5, Vector2.new(10, 18), seed * 11 + 5)
	-- Ratilla junto a la pared del fondo (antes correteaba pegada a los tornos y su "Espantar" tapaba
	-- el torno en el móvil). En Plaza Mayor, por la pared -Z (por el +Z bajan las escaleras mecánicas)
	if hub then
		ratNest(m, at(30, 0, -LZ + 1.7).Position, at(38.5, 0, -LZ + 1.7).Position)
	else
		ratNest(m, at(35.5, 0, LZ - 1.7).Position, at(45, 0, LZ - 1.7).Position)
	end
	local _ = line
end

---------------------------------------------------------------------
-- Galería comercial (Plaza Mayor)
---------------------------------------------------------------------
function MetroDetails.galleria(m: Instance, cf: CFrame)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local H = 14
	-- Carritos y puestos del pasillo central
	cart(m, at(64, 0, 6) * CFrame.Angles(0, math.rad(180), 0), "Donuts", "🍩 DÓNUTS & CO.", rgb(230, 110, 160))
	cart(m, at(64, 0, -6), "Palomitas", "🍿 PALOMITAS", rgb(240, 180, 30))
	cart(m, at(112, 0, 6) * CFrame.Angles(0, math.rad(180), 0), "Pizza", "🍕 PIZZA AL CORTE", rgb(220, 70, 40))
	cart(m, at(136, 0, 6) * CFrame.Angles(0, math.rad(180), 0), "Floristeria", "💐 FLORISTERÍA RAÍCES", rgb(80, 170, 90))
	-- Puestos pegados a la pared -Z
	local wall = CFrame.Angles(0, math.rad(180), 0)
	cart(m, at(100, 0, -30) * wall, "Farmacia", "💊 FARMACIA", rgb(40, 170, 110))
	cart(m, at(110, 0, -30) * wall, "Libreria", "📚 LIBROS AL PASO", rgb(150, 90, 50))
	cart(m, at(120, 0, -30) * wall, "Recuerdos", "🧲 RECUERDOS", rgb(40, 130, 200))
	cart(m, at(139.5, 0, -30) * wall, "Kebab", "🌯 KEBAB ANDÉN 2", rgb(180, 110, 40))
	-- Aseos grandes (esquina -Z del fondo)
	MetroDetails.restroom(m, at(151, 0, -30.4) * CFrame.Angles(0, math.rad(180), 0), 16, 9.4, 9, 3)
	-- Fuente de los deseos
	local fx, fz = 87.5, 0
	part(m, "FountainRim", Vector3.new(1.4, 8, 8), at(fx, 0.7, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 196, 188), Enum.Material.Marble, { Shape = Enum.PartType.Cylinder })
	local water = part(m, "FountainWater", Vector3.new(0.2, 7, 7), at(fx, 1.35, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 150, 210), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.3, Reflectance = 0.2, CanCollide = false, Tags = { "MetroFountain" } })
	local _ = water
	part(m, "FountainPillar", Vector3.new(0.9, 3, 0.9), at(fx, 2.5, fz), rgb(200, 196, 188), Enum.Material.Marble)
	local spout = decor(m, "Spout", Vector3.new(1.4, 0.4, 1.4), at(fx, 4.1, fz), rgb(200, 196, 188), Enum.Material.Marble, { Shape = Enum.PartType.Ball })
	local jet = Instance.new("ParticleEmitter")
	jet.Name = "Jet"
	jet.EmissionDirection = Enum.NormalId.Top
	jet.Rate = 60
	jet.Lifetime = NumberRange.new(0.8, 1)
	jet.Speed = NumberRange.new(9, 11)
	jet.SpreadAngle = Vector2.new(25, 25)
	jet.Acceleration = Vector3.new(0, -28, 0)
	jet.Size = NumberSequence.new(0.25, 0.1)
	jet.Color = ColorSequence.new(rgb(180, 220, 250))
	jet.Transparency = NumberSequence.new(0.2, 0.8)
	jet.Parent = spout
	for i = 1, 9 do
		local a = i * 0.7
		decor(m, "Coin", Vector3.new(0.05, 0.35, 0.35), at(fx + math.cos(a) * (1 + i % 3), 1.47, fz + math.sin(a) * (1 + i % 3)) * CFrame.Angles(0, 0, math.rad(90)), rgb(230, 190, 60), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	end
	local light = Instance.new("PointLight")
	light.Range = 10
	light.Color = rgb(150, 210, 255)
	light.Brightness = 0.7
	light.Parent = spout
	-- Piano de cola
	local px, pz = 114, -17
	local piano = part(m, "Piano", Vector3.new(4.2, 1.4, 5.4), at(px, 3.3, pz), rgb(15, 15, 18), Enum.Material.SmoothPlastic, { Tags = { "MetroPiano" } })
	local _p = piano
	decor(m, "PianoLid", Vector3.new(4.1, 0.15, 5), at(px + 0.9, 5.2, pz) * CFrame.Angles(0, 0, math.rad(35)), rgb(15, 15, 18))
	decor(m, "Keys", Vector3.new(4, 0.2, 1), at(px, 3.9, pz + 3.1), WHITE)
	for i = 0, 7 do
		decor(m, "BlackKey", Vector3.new(0.22, 0.25, 0.6), at(px - 1.7 + i * 0.5, 4.05, pz + 2.9), DARK)
	end
	for _, dx in { -1.6, 1.6 } do
		decor(m, "PianoLeg", Vector3.new(0.35, 2.6, 0.35), at(px + dx, 1.3, pz + 1.8), rgb(15, 15, 18))
	end
	decor(m, "PianoLeg", Vector3.new(0.35, 2.6, 0.35), at(px, 1.3, pz - 2.2), rgb(15, 15, 18))
	part(m, "PianoStool", Vector3.new(2.4, 0.4, 1.2), at(px, 1.9, pz + 4.6), rgb(15, 15, 18))
	-- (sin patas, la banqueta quedaba flotando a 1.7 studs del suelo)
	for _, dx in { -0.9, 0.9 } do
		decor(m, "StoolLeg", Vector3.new(0.3, 1.7, 0.9), at(px + dx, 0.85, pz + 4.6), rgb(15, 15, 18))
	end
	sign(m, at(px, 7.4, pz - 2.8) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(6, 1, 0.15), "🎹 PIANO LIBRE · ¡TÓCALO!", rgb(20, 20, 26))
	-- Limpiabotas
	part(m, "ShineChair", Vector3.new(2.6, 1, 2.2), at(70, 2.8, -22), rgb(120, 30, 30), Enum.Material.Fabric, { Tags = { "MetroShine" } })
	decor(m, "ShineBack", Vector3.new(2.6, 2.4, 0.4), at(70, 4.3, -23), rgb(120, 30, 30), Enum.Material.Fabric)
	decor(m, "ShineBase", Vector3.new(2.8, 2.3, 2.6), at(70, 1.15, -22), WOOD, Enum.Material.Wood)
	decor(m, "ShineFootrest", Vector3.new(1.6, 0.3, 0.8), at(70, 1.4, -20.4), STEEL, Enum.Material.Metal)
	sign(m, at(70, 6.4, -23.3) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(4, 0.9, 0.15), "👞 LIMPIABOTAS", rgb(120, 30, 30))
	marker(m, "Shiner", at(71.8, 1, -20.2), "MetroStaff", { Role = "Shiner", Face = (at(70, 0, -22)).Position })
	-- Estatua humana
	part(m, "StatueBox", Vector3.new(2.6, 1.6, 2.6), at(96, 0.8, -18), rgb(200, 200, 205), Enum.Material.Marble)
	marker(m, "Statue", at(96, 4.1, -18), "MetroStatue", { Face = (at(96, 0, -5)).Position }, Vector3.new(2, 5, 2))
	decor(m, "Hat", Vector3.new(1.2, 0.5, 1.2), at(97.8, 0.25, -16.2), DARK, nil, { Shape = Enum.PartType.Cylinder })
	-- Panel de salidas de las dos líneas
	for i, lineId in { "L1", "L2" } do
		local l = Metro.lineById[lineId]
		local z = if i == 1 then -6 else 6
		local board = decor(m, "Departures", Vector3.new(0.3, 1.6, 8), at(52, 11.4, z), DARK)
		Builder.sign(board, "PRÓXIMO TREN", Enum.NormalId.Right, rgb(255, 200, 40), DARK)
		board:AddTag("MetroDisplay")
		board:SetAttribute("Line", lineId)
		board:SetAttribute("Station", "PlazaMayor")
		sign(m, at(52.2, 12.7, z) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(8, 0.8, 0.1), l.Name .. " · " .. (if lineId == "L1" then "🔴" else "🔵"), l.Color)
		decor(m, "BoardWire", Vector3.new(0.1, 1.4, 0.1), at(52, 13.5, z), STEEL)
	end
	-- Oficina de seguridad con monitores y guardias patrullando
	part(m, "SecurityDesk", Vector3.new(6, 3.2, 2.4), at(53, 1.6, -15), rgb(50, 56, 70), Enum.Material.Metal)
	for i = 0, 3 do
		local screen = decor(m, "Monitor", Vector3.new(1.3, 1, 0.2), at(51.1 + i * 1.3, 4.1, -15.6), rgb(60, 140, 100), Enum.Material.Neon)
		Builder.sign(screen, "CAM " .. (i + 1), Enum.NormalId.Back, Color3.new(1, 1, 1))
	end
	sign(m, at(53, 6.2, -16.3) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(5, 1, 0.15), "🛡️ SEGURIDAD DEL METRO", rgb(30, 50, 90))
	guardPost(m, at(55, 0, -9.5).Position, at(150, 0, -9.5).Position, "Guard", "GuardPost1")
	guardPost(m, at(150, 0, 9.5).Position, at(56, 0, 9.5).Position, "Guard", "GuardPost2")
	guardPost(m, at(60, 0, 18).Position, at(140, 0, 18).Position, "Cleaner", "CleanerPost")
	-- Cámaras, altavoces, extintores, papeleras, teléfonos, cajero, taquillas
	for _, x in { 78, 104, 128 } do
		camera(m, at(x, H - 0.6, -34.3) * CFrame.Angles(0, math.rad(180), 0))
	end
	for x = 64, 152, 22 do
		speaker(m, at(x, H - 0.2, 0))
	end
	extinguisher(m, at(74, 0, -34.6) * CFrame.Angles(0, math.rad(180), 0))
	for _, x in { 70, 124, 148 } do
		bin(m, at(x, 0, if x == 148 then -14 else 14))
	end
	phone(m, at(92, 0, -34.6) * CFrame.Angles(0, math.rad(180), 0))
	phone(m, at(95, 0, -34.6) * CFrame.Angles(0, math.rad(180), 0))
	atm(m, at(127, 0, -34.9) * CFrame.Angles(0, math.rad(180), 0))
	lockers(m, at(132, 0, -34.9) * CFrame.Angles(0, math.rad(180), 0), 4, 2)
	-- Máquinas expendedoras en fila
	for i, x in { 84, 87, 90 } do
		local v = part(m, "Vending", Vector3.new(2.6, 6, 2.4), at(x, 3, -33.4), if i == 2 then rgb(30, 90, 180) else rgb(200, 40, 50), Enum.Material.SmoothPlastic, { Tags = { "MetroShop" } })
		v:SetAttribute("ShopId", "Maquina")
		decor(m, "VendingGlass", Vector3.new(2, 3.6, 0.1), at(x, 3.6, -32.15), rgb(200, 230, 240), Enum.Material.Glass, { Transparency = 0.4 })
		decor(m, "VendingLight", Vector3.new(2, 0.3, 0.1), at(x, 5.7, -32.15), rgb(255, 255, 255), Enum.Material.Neon)
	end
	-- Anuncios en las columnas y banderolas colgando del techo
	for x = 64, 136, 24 do
		for _, z in { -12, 12 } do
			advert(m, at(x - 0.5, 6.5, z + (if z < 0 then 1.12 else -1.12)) * CFrame.Angles(0, if z < 0 then math.rad(180) else 0, 0), Vector2.new(1.6, 3))
		end
		local banner = decor(m, "Banner", Vector3.new(0.15, 3, 5), at(x + 6, H - 2.6, 0), if (x // 24) % 2 == 0 then rgb(215, 40, 50) else rgb(40, 110, 215))
		Builder.sign(banner, "GALERÍA DEL METRO", Enum.NormalId.Left)
		Builder.sign(banner, "GALERÍA DEL METRO", Enum.NormalId.Right)
	end
	-- Una lámpara que falla y alguna rata en el rincón de los aseos
	local flick = lamp(m, at(146, H - 0.15, -18), Vector3.new(4, 0.15, 1), 16, rgb(230, 240, 255))
	flick:AddTag("MetroFlicker")
	ratNest(m, at(158, 0, -24).Position, at(140, 0, -24).Position)
	ratNest(m, at(48.8, 0, 30).Position, at(48.8, 0, 14).Position)
	drip(m, at(142, H, -14), at(0, 0, 0).Position.Y)
	litter(m, at(105, 0, 0), 8, Vector2.new(50, 20), 99)
end

-- Para las bocas de metro (Kit/MetroAccess): los mismos anuncios, cámaras, papeleras y extintores
MetroDetails.advert = advert
MetroDetails.camera = camera
MetroDetails.bin = bin
MetroDetails.extinguisher = extinguisher
MetroDetails.speaker = speaker

return MetroDetails
