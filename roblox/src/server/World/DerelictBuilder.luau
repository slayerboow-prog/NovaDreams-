-- DerelictBuilder (servidor): construye los PECIOS de la Deriva (shared/Cosmos/Derelicts) la primera vez
-- que hacen falta. Un modelo por pecio en workspace.Pecios, entero de una vez al acercarse (Atomic).
--
--   * Fuera: el casco largo con la cruz médica medio borrada, el bloque de motores, la brecha, restos que
--     flotan, la baliza médica que parpadea y el aro azul de la esclusa (donde se atraca).
--   * Dentro: la cubierta (suelo, techo, paredes y tabiques con huecos de puerta), luces de emergencia
--     rojas (siempre) y luces blancas apagadas (las enciende Controllers/DerelictClient en tu pantalla
--     según los fusibles que lleves), barreras láser (las enseña el cliente; el daño lo pone el servidor),
--     las chispas de Máquinas, camillas, cajas y pantallas rotas.
--   * Paneles (ProximityPrompt) de fusibles, registros, núcleo y «Volver a la nave», y marcas StorySpot
--     «Deriva_<Id>» para las escenas (shared/LifeStory/Locations).
-- Devuelve { Model, Prompts = { Fuse = { [n] = prompt }, Log = { [id] = prompt }, Core, Exit } }.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Derelicts = require(ReplicatedStorage.Shared.Cosmos.Derelicts)

local DerelictBuilder = {}

local rgb = Color3.fromRGB
local V = Vector3.new

local HULL = rgb(118, 122, 126)
local HULL_DARK = rgb(70, 72, 76)
local INNER = rgb(150, 156, 160)
local FLOOR = rgb(84, 88, 92)
local RED = rgb(230, 60, 50)

local function folder(): Instance
	local f = workspace:FindFirstChild("Pecios")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Pecios"
		f.Parent = workspace
	end
	return f
end

local function box(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.CanQuery = collide ~= false
	p.CastShadow = collide ~= false
	p.Size = V(math.max(size.X, 0.2), math.max(size.Y, 0.2), math.max(size.Z, 0.2))
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function prompt(parent: Instance, action: string, object: string, hold: number?): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

-- Una pared entre dos x (o dos z) con huecos de puerta { centro, ancho }
local function wallAlongX(parent: Instance, d: any, z: number, x0: number, x1: number, gaps: { { number } }, h: number, color: Color3)
	table.sort(gaps, function(a, b)
		return a[1] < b[1]
	end)
	local cur = x0
	local function seg(a: number, b: number)
		if b - a > 0.5 then
			box(parent, "Pared", CFrame.new(Derelicts.world(d, V((a + b) / 2, h / 2, z))), V(b - a, h, 1.4), color)
		end
	end
	for _, g in gaps do
		seg(cur, g[1] - g[2] / 2)
		-- (dintel encima de la puerta)
		box(parent, "Dintel", CFrame.new(Derelicts.world(d, V(g[1], h - 2, z))), V(g[2], 4, 1.4), color)
		cur = g[1] + g[2] / 2
	end
	seg(cur, x1)
end

local function wallAlongZ(parent: Instance, d: any, x: number, z0: number, z1: number, h: number, color: Color3, gap: { number }?)
	if gap then
		local a, b = gap[1] - gap[2] / 2, gap[1] + gap[2] / 2
		if a - z0 > 0.5 then
			box(parent, "Tabique", CFrame.new(Derelicts.world(d, V(x, h / 2, (z0 + a) / 2))), V(1.4, h, a - z0), color)
		end
		if z1 - b > 0.5 then
			box(parent, "Tabique", CFrame.new(Derelicts.world(d, V(x, h / 2, (b + z1) / 2))), V(1.4, h, z1 - b), color)
		end
		box(parent, "Dintel", CFrame.new(Derelicts.world(d, V(x, h - 2, gap[1]))), V(1.4, 4, gap[2]), color)
	else
		box(parent, "Tabique", CFrame.new(Derelicts.world(d, V(x, h / 2, (z0 + z1) / 2))), V(1.4, h, z1 - z0), color)
	end
end

local function light(parent: Instance, d: any, p: Vector3, kind: string, fuse: number?): Part
	local lamp = box(parent, if kind == "Blanca" then "LuzBlanca" else "LuzEmergencia", CFrame.new(Derelicts.world(d, p)), V(4, 0.4, 1.2), if kind == "Blanca" then rgb(220, 230, 235) else RED, Enum.Material.Neon, false)
	local l = Instance.new("PointLight")
	if kind == "Blanca" then
		l.Color = rgb(225, 235, 255)
		l.Range = 28
		l.Brightness = 1.6
		l.Enabled = false -- (las enciende Controllers/DerelictClient según tus fusibles)
		lamp.Transparency = 0.6
		lamp:SetAttribute("Fuse", fuse or 0)
		CollectionService:AddTag(lamp, "PecioLuz")
	else
		l.Color = rgb(255, 60, 40)
		l.Range = 16
		l.Brightness = 0.7
	end
	l.Shadows = false
	l.Parent = lamp
	return lamp
end

local function spot(parent: Instance, d: any, s: any)
	local p = box(parent, "StorySpot_Deriva_" .. s.Id, CFrame.new(Derelicts.world(d, s.P + V(0, 3, 0))), V(2, 2, 2), rgb(255, 255, 255), Enum.Material.SmoothPlastic, false)
	p.Transparency = 1
	p:SetAttribute("SpotId", "Deriva_" .. s.Id)
	CollectionService:AddTag(p, "StorySpot")
end

-- Lo de dentro: la cubierta
local function buildDeck(m: Model, d: any): { [string]: any }
	local D = d.Deck
	local hx, hz, h = D.HalfX, D.HalfZ, D.Height
	local prompts = { Fuse = {}, Log = {} }
	-- Suelo, techo y casco (las paredes de fuera)
	box(m, "Suelo", CFrame.new(Derelicts.world(d, V(0, -1, 0))), V(hx * 2 + 4, 2, hz * 2 + 4), FLOOR, Enum.Material.DiamondPlate)
	box(m, "Techo", CFrame.new(Derelicts.world(d, V(0, h + 1, 0))), V(hx * 2 + 4, 2, hz * 2 + 4), HULL_DARK, Enum.Material.Metal)
	box(m, "CascoOeste", CFrame.new(Derelicts.world(d, V(-hx - 1, h / 2, 0))), V(2, h + 4, hz * 2 + 4), HULL)
	box(m, "CascoEste", CFrame.new(Derelicts.world(d, V(hx + 1, h / 2, 0))), V(2, h + 4, hz * 2 + 4), HULL)
	box(m, "CascoNorte", CFrame.new(Derelicts.world(d, V(0, h / 2, -hz - 1))), V(hx * 2 + 4, h + 4, 2), HULL)
	-- (lado de la esclusa: la pared con la compuerta de cristal en el centro)
	box(m, "CascoSur1", CFrame.new(Derelicts.world(d, V((-hx - 8) / 2, h / 2, hz + 1))), V(hx - 8 + 2, h + 4, 2), HULL)
	box(m, "CascoSur2", CFrame.new(Derelicts.world(d, V((hx + 8) / 2, h / 2, hz + 1))), V(hx - 8 + 2, h + 4, 2), HULL)
	local hatch = box(m, "Compuerta", CFrame.new(Derelicts.world(d, V(0, h / 2, hz + 1))), V(16, h + 4, 1), rgb(120, 180, 230), Enum.Material.Glass)
	hatch.Transparency = 0.55
	-- Tabiques del pasillo (con puertas a las salas) y entre salas
	local southGaps, northGaps = {}, {}
	for _, r in d.Rooms do
		if r.Door and r.Id ~= "Puente" then
			if r.Door.Z > 0 then
				table.insert(southGaps, { r.Door.X, 8 })
			else
				table.insert(northGaps, { r.Door.X, 8 })
			end
		end
	end
	wallAlongX(m, d, 6, d.BridgeX, hx, southGaps, h, INNER)
	wallAlongX(m, d, -6, d.BridgeX, hx, northGaps, h, INNER)
	for _, x in d.Dividers.South do
		wallAlongZ(m, d, x, 6.7, hz, h, INNER)
	end
	for _, x in d.Dividers.North do
		wallAlongZ(m, d, x, -hz, -6.7, h, INNER)
	end
	-- El puente: tabique con la puerta (sin corriente, un campo rojo que no deja pasar; el servidor te
	-- devuelve al pasillo y tu pantalla lo quita cuando ya tienes la corriente)
	wallAlongZ(m, d, d.BridgeX, -hz, hz, h, INNER, { 0, 8 })
	local door = box(m, "PuertaPuente", CFrame.new(Derelicts.world(d, V(d.BridgeX, (h - 4) / 2, 0))), V(0.6, h - 4, 8), RED, Enum.Material.ForceField, false)
	door.Transparency = 0.25
	CollectionService:AddTag(door, "PecioPuerta")
	-- Luces: una roja de emergencia por sala (siempre) y blancas apagadas
	for _, r in d.Rooms do
		light(m, d, V(r.C.X, h - 0.4, r.C.Z), "Emergencia")
		local n = math.max(1, math.floor(r.S.X / 40))
		for i = 1, n do
			local x = r.C.X - r.S.X / 2 + (i - 0.5) * r.S.X / n
			light(m, d, V(x, h - 0.3, r.C.Z), "Blanca", r.Fuse)
		end
	end
	-- Barreras láser: un emisor a cada lado y el rayo (lo enseña el cliente)
	for i, L in d.Lasers do
		for _, side in { -1, 1 } do
			box(m, "EmisorLaser", CFrame.new(Derelicts.world(d, V(L.X, 4, side * 5.6))), V(1.2, 8, 0.8), HULL_DARK)
		end
		for k = 0, 3 do
			local beam = box(m, "Laser", CFrame.new(Derelicts.world(d, V(L.X, 1.2 + k * 2.2, 0))), V(0.25, 0.25, 11), RED, Enum.Material.Neon, false)
			beam:SetAttribute("Laser", i)
			CollectionService:AddTag(beam, "PecioLaser")
		end
	end
	-- Chispas de Máquinas: un cuadro eléctrico roto con su emisor (lo dispara el cliente)
	local S = d.Sparks
	local panel = box(m, "CuadroRoto", CFrame.new(Derelicts.world(d, S.C + V(0, 4, 8))), V(6, 8, 1), HULL_DARK)
	local att = Instance.new("Attachment")
	att.Parent = panel
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Chispas"
	pe.Color = ColorSequence.new(rgb(255, 230, 140), rgb(255, 140, 40))
	pe.LightEmission = 1
	pe.Size = NumberSequence.new(0.25, 0)
	pe.Lifetime = NumberRange.new(0.4, 0.9)
	pe.Speed = NumberRange.new(14, 30)
	pe.SpreadAngle = Vector2.new(70, 70)
	pe.Acceleration = V(0, -30, 0)
	pe.Rate = 0
	pe.Parent = att
	CollectionService:AddTag(panel, "PecioChispas")
	-- Fusibles, registros, núcleo y salida (paneles con su luz)
	for _, f in d.Fuses do
		local p = box(m, "Fusible" .. f.N, CFrame.new(Derelicts.world(d, f.P)), V(2.4, 3.2, 1), rgb(60, 60, 64))
		local led = box(m, "LedFusible", CFrame.new(Derelicts.world(d, f.P + V(0, 2.2, 0))), V(0.8, 0.8, 0.8), RED, Enum.Material.Neon, false)
		led:SetAttribute("Fuse", f.N)
		CollectionService:AddTag(led, "PecioLed")
		prompts.Fuse[f.N] = prompt(p, "Cambiar el fusible", ("Fusible %d · %s"):format(f.N, f.Room), 1.2)
	end
	for _, lg in d.Logs do
		local p = box(m, "Registro", CFrame.new(Derelicts.world(d, lg.P)), V(2, 1.4, 0.4), rgb(40, 120, 160), Enum.Material.Neon, false)
		p.Transparency = 0.2
		prompts.Log[lg.Id] = prompt(p, "Escuchar el registro", "Registro · " .. lg.Room, 0)
	end
	local core = box(m, "Nucleo", CFrame.new(Derelicts.world(d, d.Core)), V(2, 3, 2), rgb(120, 220, 255), Enum.Material.Neon, false)
	prompts.Core = prompt(core, "Sacar el núcleo de datos", "Puente", 1.5)
	local exit = box(m, "PanelEsclusa", CFrame.new(Derelicts.world(d, d.Exit)), V(3, 4, 0.6), rgb(80, 160, 220), Enum.Material.Neon, false)
	exit.Transparency = 0.3
	prompts.Exit = prompt(exit, "Volver a la nave", "Esclusa", 0)
	-- Atrezo: camillas vacías, cajas, pantallas rotas, el sillón del puente
	local seed = Random.new(7)
	for _, r in d.Rooms do
		if r.Id == "Triaje" or r.Id == "Enfermeria" or r.Id == "Cuarentena" then
			for i = 1, 4 do
				local x = r.C.X - r.S.X / 2 + 8 + (i - 1) * (r.S.X - 16) / 3
				local z = r.C.Z + (if r.C.Z < 0 then -6 else 6)
				local bed = box(m, "Camilla", CFrame.new(Derelicts.world(d, V(x, 1.4, z))) * CFrame.Angles(0, seed:NextNumber(-0.25, 0.25), 0), V(3, 0.5, 7), rgb(200, 205, 210), Enum.Material.SmoothPlastic)
				bed.CastShadow = false
				box(m, "Sabana", CFrame.new(Derelicts.world(d, V(x, 1.75, z))) * CFrame.Angles(0, seed:NextNumber(-0.3, 0.3), 0), V(2.6, 0.2, 3.4), rgb(175, 190, 200), Enum.Material.Fabric, false)
			end
		elseif r.Id == "Almacen" or r.Id == "Maquinas" then
			for _ = 1, 6 do
				local x = r.C.X + seed:NextNumber(-r.S.X / 2 + 4, r.S.X / 2 - 4)
				local z = r.C.Z + seed:NextNumber(-6, 6)
				box(m, "Caja", CFrame.new(Derelicts.world(d, V(x, 1.5, z))) * CFrame.Angles(0, seed:NextNumber(0, 1.5), 0), V(3, 3, 3), rgb(150, 120, 70), Enum.Material.WoodPlanks)
			end
		elseif r.Id == "Comunicaciones" then
			for i = 1, 3 do
				box(m, "PantallaRota", CFrame.new(Derelicts.world(d, V(r.C.X - 20 + i * 10, 5, -27.2))), V(6, 3.5, 0.4), rgb(20, 30, 36), Enum.Material.Glass)
			end
		end
	end
	-- (sillón a un lado y consola contra el ventanal: el holograma de la doctora queda despejado en el
	-- centro del puente para la cinemática)
	box(m, "Sillon", CFrame.new(Derelicts.world(d, V(-121, 1.5, 9))) * CFrame.Angles(0, math.rad(120), 0), V(3, 3, 3), rgb(60, 40, 40), Enum.Material.Leather)
	box(m, "ConsolaPuente", CFrame.new(Derelicts.world(d, V(-138.6, 1.8, 0))), V(1.4, 3.6, 14), HULL_DARK)
	-- Marcas de la historia
	for _, s in d.Spots do
		spot(m, d, s)
	end
	return prompts
end

-- Un cartel con texto en una cara (SurfaceGui)
local function sign(parent: Instance, d: any, p: Vector3, size: Vector3, face: Enum.NormalId, text: string, color: Color3?, bg: Color3?)
	local plate = box(parent, "Cartel", CFrame.new(Derelicts.world(d, p)), size, bg or rgb(28, 30, 34), Enum.Material.SmoothPlastic, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.4
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or rgb(230, 230, 220)
	label.Parent = gui
	return plate
end

-- Detalle de cada sala (lo que se ve al explorar: cuenta lo que pasó sin decirlo)
local function decorate(m: Model, d: any)
	local h = d.Deck.Height
	local rng = Random.new(23)
	local W = function(v: Vector3): CFrame
		return CFrame.new(Derelicts.world(d, v))
	end
	-- Pasillo: tuberías en el techo, cables colgando, líneas de peligro en el suelo y carteles de rumbo
	for _, z in { -4.6, 4.6 } do
		box(m, "Tuberia", W(V(14, h - 1.4, z)) * CFrame.Angles(0, 0, math.rad(90)), V(1.2, 250, 1.2), rgb(96, 100, 92), Enum.Material.Metal, false).Shape = Enum.PartType.Cylinder
	end
	for i = 1, 7 do
		local x = -100 + i * 30 + rng:NextNumber(-6, 6)
		box(m, "Cable", W(V(x, h - 3.2, rng:NextNumber(-3, 3))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.3, 0.3)), V(0.2, 4, 0.2), rgb(20, 20, 22), Enum.Material.Rubber, false)
	end
	for _, z in { -5.4, 5.4 } do
		box(m, "LineaPeligro", W(V(14, 0.02, z)), V(250, 0.05, 0.5), rgb(220, 180, 30), Enum.Material.SmoothPlastic, false)
	end
	sign(m, d, V(-6, 9, -5.9), V(10, 2.2, 0.2), Enum.NormalId.Back, "◄ PUENTE · TRIAJE")
	sign(m, d, V(30, 9, 5.9), V(12, 2.2, 0.2), Enum.NormalId.Front, "CUARENTENA · MÁQUINAS ►")
	sign(m, d, V(-108, 13, -5.9), V(8, 2, 0.2), Enum.NormalId.Back, "PUENTE · SOLO TRIPULACIÓN", rgb(255, 210, 200), rgb(90, 20, 18))
	-- Triaje: sueros, cortinas, papeles por el suelo, una camilla volcada y el peluche del niño
	for i = 1, 4 do
		local x = -104 + i * 17
		box(m, "PieSuero", W(V(x, 3, -24)), V(0.3, 6, 0.3), rgb(180, 185, 190), Enum.Material.Metal, false)
		box(m, "BolsaSuero", W(V(x, 5.6, -23.6)), V(0.9, 1.3, 0.3), rgb(200, 230, 240), Enum.Material.Glass, false).Transparency = 0.3
		local curtain = box(m, "Cortina", W(V(x + 6, 4.5, -19)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), V(0.15, 8, 7), rgb(150, 175, 170), Enum.Material.Fabric, false)
		curtain.Transparency = 0.15
	end
	for _ = 1, 14 do
		box(m, "Papel", W(V(rng:NextNumber(-108, -32), 0.05, rng:NextNumber(-26, -8))) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), V(1.1, 0.04, 1.5), rgb(225, 222, 210), Enum.Material.SmoothPlastic, false)
	end
	box(m, "CamillaVolcada", W(V(-50, 1.6, -12)) * CFrame.Angles(0, 0.8, math.rad(80)), V(3, 0.5, 7), rgb(200, 205, 210), Enum.Material.SmoothPlastic)
	local toy = box(m, "Peluche", W(V(-58, 0.6, -20)), V(1.2, 1.2, 1.2), rgb(150, 110, 70), Enum.Material.Fabric, false)
	toy.Shape = Enum.PartType.Ball
	box(m, "PelucheCabeza", W(V(-58, 1.5, -20.2)), V(0.9, 0.9, 0.9), rgb(150, 110, 70), Enum.Material.Fabric, false).Shape = Enum.PartType.Ball
	sign(m, d, V(-70, 10, -27.2), V(10, 2, 0.2), Enum.NormalId.Front, "TRIAJE")
	-- Cuarentena: mampara de cristal precintada, franjas de peligro, escarcha y el aviso de la doctora
	local glass = box(m, "Mampara", W(V(72, h / 2, 17)), V(0.5, h - 1, 20), rgb(170, 200, 210), Enum.Material.Glass)
	glass.Transparency = 0.45
	for i = 0, 4 do
		box(m, "Precinto", W(V(71.6, 2 + i * 3, 17)) * CFrame.Angles(math.rad(25), 0, 0), V(0.2, 0.4, 20), if i % 2 == 0 then rgb(230, 190, 30) else rgb(20, 20, 20), Enum.Material.SmoothPlastic, false)
	end
	sign(m, d, V(71.4, 9, 12), V(0.2, 2.6, 8), Enum.NormalId.Left, "CUARENTENA · NO ABRIR", rgb(255, 230, 120), rgb(70, 20, 16))
	for _ = 1, 10 do
		box(m, "Escarcha", W(V(rng:NextNumber(74, 93), 0.05, rng:NextNumber(8, 27))), V(rng:NextNumber(2, 5), 0.05, rng:NextNumber(2, 5)), rgb(220, 235, 245), Enum.Material.Ice, false).Transparency = 0.3
	end
	sign(m, d, V(57.5, 10, 27.2), V(12, 2, 0.2), Enum.NormalId.Back, "CUARENTENA")
	-- Máquinas: dos generadores, tuberías gruesas y vapor
	for i, x in { 102, 110 } do
		local gen = box(m, "Generador", W(V(x, 3.5, 24)) * CFrame.Angles(0, 0, math.rad(90)), V(7, 6, 6), rgb(60, 70, 64), Enum.Material.Metal)
		gen.Shape = Enum.PartType.Cylinder
		local att = Instance.new("Attachment")
		att.Position = V(3, 0, 0)
		att.Parent = gen
		local steam = Instance.new("ParticleEmitter")
		steam.Name = "Vapor" .. i
		steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		steam.Color = ColorSequence.new(rgb(210, 215, 220))
		steam.Transparency = NumberSequence.new(0.6, 1)
		steam.Size = NumberSequence.new(1, 4)
		steam.Lifetime = NumberRange.new(2, 3)
		steam.Rate = 3
		steam.Speed = NumberRange.new(1, 3)
		steam.Parent = att
	end
	box(m, "TuberiaGruesa", W(V(117, h - 2, 26)) * CFrame.Angles(0, 0, math.rad(90)), V(2.4, 44, 2.4), rgb(110, 90, 70), Enum.Material.CorrodedMetal, false).Shape = Enum.PartType.Cylinder
	sign(m, d, V(117.5, 10, 27.2), V(10, 2, 0.2), Enum.NormalId.Back, "MÁQUINAS")
	-- Almacén: estanterías con cajas médicas
	for i = 0, 3 do
		local x = -18 + i * 22
		box(m, "Estanteria", W(V(x, 4, -26)), V(14, 8, 2.4), rgb(90, 92, 96), Enum.Material.Metal)
		for k = 0, 2 do
			box(m, "CajaMedica", W(V(x - 4 + k * 4, 6.2, -25.6)), V(3, 2, 1.6), rgb(225, 225, 220), Enum.Material.SmoothPlastic, false)
			box(m, "CruzCaja", W(V(x - 4 + k * 4, 6.2, -24.75)), V(1, 1, 0.05), rgb(200, 40, 40), Enum.Material.SmoothPlastic, false)
		end
	end
	sign(m, d, V(16, 10, -27.2), V(10, 2, 0.2), Enum.NormalId.Front, "ALMACÉN MÉDICO")
	-- Comunicaciones: consolas con pantallas tenues y la antena interior
	for i = 0, 3 do
		local x = 72 + i * 16
		box(m, "Consola", W(V(x, 1.6, -22)), V(8, 3.2, 3), rgb(50, 54, 60), Enum.Material.Metal)
		local screen = box(m, "PantallaTenue", W(V(x, 3.6, -23.4)) * CFrame.Angles(math.rad(-20), 0, 0), V(6, 2.4, 0.2), rgb(40, 120, 110), Enum.Material.Neon, false)
		screen.Transparency = 0.55
	end
	sign(m, d, V(100, 10, -27.2), V(12, 2, 0.2), Enum.NormalId.Front, "COMUNICACIONES")
	-- Puente: ventanal al espacio, mesa de cartas y la placa de la nave
	local window = box(m, "Ventanal", W(V(-139.6, 8, 0)), V(0.4, 8, 30), rgb(120, 170, 220), Enum.Material.Glass, false)
	window.Transparency = 0.7
	box(m, "MesaCartas", W(V(-124, 2.2, 12)), V(6, 0.4, 8), rgb(40, 60, 80), Enum.Material.Glass)
	sign(m, d, V(-113, 9, 10), V(0.2, 2.4, 9), Enum.NormalId.Right, "MISERICORDIA · OVILLA · NAVE HOSPITAL 07", rgb(240, 235, 220), rgb(30, 34, 40))
end

-- Lo de fuera: casco, motores, cruz médica, brecha, restos, baliza y aro de la esclusa
local function buildOutside(m: Model, d: any)
	local hx, hz, h = d.Deck.HalfX, d.Deck.HalfZ, d.Deck.Height
	-- Proa afilada y lomo del casco
	local nose = Instance.new("WedgePart")
	nose.Name = "Proa"
	nose.Anchored = true
	nose.Size = V(hz * 2 + 4, h + 8, 40)
	nose.CFrame = CFrame.new(Derelicts.world(d, V(-hx - 21, h / 2, 0))) * CFrame.Angles(0, math.rad(90), 0)
	nose.Color = HULL
	nose.Material = Enum.Material.Metal
	nose.Parent = m
	box(m, "Lomo", CFrame.new(Derelicts.world(d, V(0, h + 4, 0))), V(hx * 2 - 20, 6, hz * 2 - 10), HULL_DARK, Enum.Material.CorrodedMetal)
	box(m, "Quilla", CFrame.new(Derelicts.world(d, V(0, -5, 0))), V(hx * 2 - 10, 6, hz * 2 - 16), HULL_DARK, Enum.Material.CorrodedMetal)
	-- Motores de popa (dos toberas apagadas)
	box(m, "BloqueMotores", CFrame.new(Derelicts.world(d, V(hx + 22, h / 2 - 2, 0))), V(44, 30, 50), HULL_DARK, Enum.Material.CorrodedMetal)
	for _, z in { -12, 12 } do
		local noz = box(m, "Tobera", CFrame.new(Derelicts.world(d, V(hx + 48, h / 2 - 2, z))) * CFrame.Angles(0, 0, math.rad(90)), V(10, 14, 14), rgb(40, 38, 40), Enum.Material.Metal)
		noz.Shape = Enum.PartType.Cylinder
	end
	-- La cruz médica, medio borrada (una cara)
	for _, side in { 1, -1 } do
		local z = side * (hz + 2.2)
		box(m, "CruzV", CFrame.new(Derelicts.world(d, V(-60, h / 2, z))), V(8, 18, 0.3), rgb(215, 215, 210), Enum.Material.SmoothPlastic, false)
		box(m, "CruzH", CFrame.new(Derelicts.world(d, V(-60, h / 2, z))), V(22, 6, 0.3), rgb(215, 215, 210), Enum.Material.SmoothPlastic, false)
		box(m, "Quemadura", CFrame.new(Derelicts.world(d, V(-54, h / 2 - 3, z + side * 0.2))) * CFrame.Angles(0, 0, 0.5), V(10, 7, 0.3), rgb(30, 26, 24), Enum.Material.Slate, false)
	end
	-- La brecha del casco (por Cuarentena): un hueco negro con chapas dobladas
	box(m, "Brecha", CFrame.new(Derelicts.world(d, V(70, h + 2, 20))), V(18, 3, 14), rgb(10, 10, 12), Enum.Material.Slate, false)
	for i = 1, 4 do
		box(m, "ChapaDoblada", CFrame.new(Derelicts.world(d, V(62 + i * 4, h + 5, 14 + i * 3))) * CFrame.Angles(0.6 * i, 0.3, 0.8), V(5, 0.4, 8), HULL, Enum.Material.CorrodedMetal, false)
	end
	-- Restos que flotan alrededor
	local rng = Random.new(11)
	for _ = 1, 22 do
		local p = V(rng:NextNumber(-220, 220), rng:NextNumber(-40, 60), rng:NextNumber(-120, 120))
		if math.abs(p.X) > hx + 30 or math.abs(p.Z) > hz + 30 or p.Y > h + 20 or p.Y < -20 then
			local s = rng:NextNumber(2, 9)
			box(m, "Resto", CFrame.new(Derelicts.world(d, p)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)), V(s, s * 0.3, s * 0.8), HULL, Enum.Material.CorrodedMetal, false)
		end
	end
	-- Baliza médica (parpadeo rojo/blanco: Controllers/DerelictClient)
	local beacon = box(m, "BalizaMedica", CFrame.new(Derelicts.world(d, V(-60, h + 12, 0))), V(3, 3, 3), RED, Enum.Material.Neon, false)
	beacon.Shape = Enum.PartType.Ball
	local bl = Instance.new("PointLight")
	bl.Color = RED
	bl.Range = 60
	bl.Brightness = 3
	bl.Parent = beacon
	CollectionService:AddTag(beacon, "PecioBaliza")
	box(m, "Antena", CFrame.new(Derelicts.world(d, V(-60, h + 6, 0))), V(0.8, 10, 0.8), HULL_DARK, Enum.Material.Metal, false)
	-- Aro azul de la esclusa (donde se atraca)
	local dock = Derelicts.world(d, d.Dock)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local a2 = (i + 1) / 16 * math.pi * 2
		local p1 = dock + V(math.cos(a) * 26, math.sin(a) * 26, 0)
		local p2 = dock + V(math.cos(a2) * 26, math.sin(a2) * 26, 0)
		box(m, "AroEsclusa", CFrame.lookAt((p1 + p2) / 2, p2), V(1.2, 1.2, (p2 - p1).Magnitude + 0.4), rgb(80, 170, 255), Enum.Material.Neon, false)
	end
	-- (pasarela de la nave a la compuerta)
	box(m, "Pasarela", CFrame.new(Derelicts.world(d, V(0, 1, hz + 18))), V(10, 1, 34), HULL_DARK, Enum.Material.DiamondPlate)
end

local built: { [string]: any } = {}

function DerelictBuilder.build(d: any): { [string]: any }
	if built[d.Id] and built[d.Id].Model.Parent then
		return built[d.Id]
	end
	local m = Instance.new("Model")
	m.Name = "Pecio_" .. d.Id
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local prompts = buildDeck(m, d)
	decorate(m, d)
	buildOutside(m, d)
	m:SetAttribute("Pecio", d.Id)
	m.Parent = folder()
	local out = { Model = m, Prompts = prompts }
	built[d.Id] = out
	return out
end

function DerelictBuilder.get(id: string): { [string]: any }?
	local b = built[id]
	return if b and b.Model.Parent then b else nil
end

return DerelictBuilder
