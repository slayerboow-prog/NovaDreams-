-- PlaneModel (Kit): los aviones hechos de piezas, con la forma de los de verdad pero pocas piezas.
--
--   * Avión de línea (bimotor de pasillo único, tipo A320 / 737), librea «Valmar Air»: fuselaje
--     redondo con morro afilado (elipsoide) y cono de cola que sube; parabrisas oscuro envolvente;
--     ventanillas en fila y cuatro puertas dibujadas (SurfaceGui); alas en flecha (25°) con diedro,
--     tres tramos que se estrechan y winglets; dos turbofanes bajo las alas (góndola, labio de la
--     toma, fan, cono de escape y pilón); carenado ventral; estabilizadores en flecha y deriva
--     trapezoidal con el logo; tren de morro y principal (dos ruedas por pata); luces de navegación
--     (roja a la izquierda, verde a la derecha, blanca en la cola), destellos y baliza roja.
--   * Avioneta de ala alta (tipo Cessna 172): cabina con parabrisas inclinado y ventanillas, capó con
--     hélice bipala y buje, cono de cola, ala alta con montantes, estabilizador y deriva en flecha,
--     tren fijo triciclo con carenados en las ruedas, luces, franja de color y matrícula.
--
-- Todo se coloca desde cf = el punto del suelo bajo las ruedas, con el morro mirando a -Z (como
-- Shared/Airport.pose). Las piezas decorativas no chocan (Builder.decor); el suelo de la cabina
-- ("Root") es la raíz a la que se suelda todo. Medidas: Shared/Airport.Kinds.
-- Atributos de las piezas que usan otros sistemas:
--   Gear = true (patas y ruedas: el tren se sube), Light = "Beacon" | "Strobe" (parpadean),
--   Prop = "Blade" | "Disc" (hélice parada / girando), Seat: SeatIndex (pasajeros, tag PlaneSeat) y
--   el asiento del piloto se llama "PilotSeat" (solo en los aviones que pilotan los jugadores).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Plan = require(ReplicatedStorage.Shared.Airport)

local PlaneModel = {}

local rgb = Color3.fromRGB
local rad = math.rad

PlaneModel.Airline = "VALMAR AIR"
local BODY = rgb(244, 246, 248)
local NAVY = rgb(18, 44, 96)
local CYAN = rgb(36, 196, 232)
local WING = rgb(190, 196, 204)
local METAL = Palette.Street.Metal
local SILVER = rgb(200, 204, 210)
local DARK = rgb(30, 32, 38)
local GLASS = rgb(26, 34, 46)
local TIRE = rgb(28, 28, 30)
local RED = rgb(255, 40, 40)
local GREEN = rgb(40, 255, 90)
local WHITE = rgb(255, 255, 250)

export type Options = {
	Pilot: boolean?, -- con asiento de piloto (lo pilota un jugador: AviationService)
	Registration: string?, -- matrícula pintada (avioneta)
}

-- Cuántas piezas puede tener cada avión como mucho (scripts/test-flight.luau lo comprueba)
PlaneModel.Budget = { Avion = 110, Avioneta = 64 }

type Ctx = {
	Model: Model,
	CF: CFrame,
}

local function at(c: Ctx, x: number, y: number, z: number): CFrame
	return c.CF * CFrame.new(x, y, z)
end

local function decor(c: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = c.Model }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.decor(props)
end

-- Pieza que choca (las grandes: alas, fuselaje): así nadie atraviesa un avión aparcado
local function solid(c: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, CanTouch = false, Parent = c.Model }
	for k, v in extra or {} do
		props[k] = v
	end
	local p = Builder.part(props)
	p.CastShadow = true
	return p
end

-- Elipsoide (malla de esfera que llena la caja de la pieza): morros, conos de cola, carenados
local function ellipsoid(c: Ctx, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, isSolid: boolean?): BasePart
	local p = if isSolid then solid(c, name, size, cf, color, material) else decor(c, name, size, cf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- Cilindro a lo largo de Z (el eje de los cilindros de Roblox es X)
local ALONG_Z = CFrame.Angles(0, rad(90), 0)
local function tube(c: Ctx, name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?, isSolid: boolean?): BasePart
	local size = Vector3.new(length, diameter, diameter)
	local extra = { Shape = Enum.PartType.Cylinder }
	if isSolid then
		return solid(c, name, size, cf * ALONG_Z, color, material, extra)
	end
	return decor(c, name, size, cf * ALONG_Z, color, material, extra)
end

-- Rueda (cilindro con el eje a lo largo de X)
local function wheel(c: Ctx, x: number, z: number, r: number, width: number, gear: boolean?): BasePart
	return decor(c, "Wheel", Vector3.new(width, r * 2, r * 2), at(c, x, r, z), TIRE, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder, Attributes = if gear then { Gear = true } else nil })
end

local function lamp(c: Ctx, name: string, cf: CFrame, color: Color3, kind: string?)
	decor(c, name, Vector3.new(0.5, 0.5, 0.5), cf, color, Enum.Material.Neon, { Attributes = if kind then { Light = kind } else nil })
end

-- Tira pegada al fuselaje (redondo, radio r y centro a la altura cy): tangente a la piel en el ángulo
-- theta (0 = el costado, + hacia arriba), de z0 a z1 y alto h. Devuelve la pieza y la cara de fuera.
local function skin(c: Ctx, name: string, side: number, theta: number, z0: number, z1: number, h: number, r: number, cy: number, color: Color3?): (BasePart, Enum.NormalId)
	local rr = r + 0.03
	local cf = at(c, side * rr * math.cos(theta), cy + rr * math.sin(theta), (z0 + z1) / 2) * CFrame.Angles(0, 0, side * theta)
	local p = decor(c, name, Vector3.new(0.05, h, z1 - z0), cf, color or BODY, Enum.Material.SmoothPlastic, { Transparency = if color then 0 else 1 })
	return p, if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left
end

local function surface(part: BasePart, face: Enum.NormalId, pps: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps or 24
	gui.LightInfluence = 1
	gui.Parent = part
	return gui
end

local function frame(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do
		(f :: any)[k] = v
	end
	f.Parent = parent
	return f
end

local function round(parent: Instance, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

local function text(parent: Instance, value: string, color: Color3, font: Enum.Font?)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextScaled = true
	label.TextColor3 = color
	label.FontFace = Font.fromEnum(font or Enum.Font.GothamBlack)
	label.Parent = parent
end

-- Asientos: { x, y, z } (y = altura del suelo de la cabina); el primero del piloto si pilot
local function seats(c: Ctx, list: { { number } }, floorY: number, pilot: { number }?, cockpitColor: Color3?)
	if pilot then
		local seat = Builder.part({ ClassName = "Seat", Name = "PilotSeat", Size = Vector3.new(1.8, 0.5, 1.8), CFrame = at(c, pilot[1], pilot[2] + 0.9, pilot[3]), Color = cockpitColor or rgb(60, 60, 66), Material = Enum.Material.Fabric, CanTouch = false, Parent = c.Model })
		seat:SetAttribute("Pilot", true)
		decor(c, "SeatBack", Vector3.new(1.8, 2.4, 0.4), at(c, pilot[1], pilot[2] + 2.2, pilot[3] + 1.05), cockpitColor or rgb(50, 50, 56), Enum.Material.Fabric)
	end
	for i, s in list do
		local seat = Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(1.8, 0.5, 1.8), CFrame = at(c, s[1], floorY + 0.9, s[2]), Color = rgb(40, 70, 130), Material = Enum.Material.Fabric, CanTouch = false, Parent = c.Model }) :: Seat -- (te sienta el vuelo, no rozarlo)
		seat.CanTouch = false -- (solo se sienta quien embarca: FlightService / AviationService)
		seat:SetAttribute("SeatIndex", i)
		seat:AddTag("PlaneSeat")
		decor(c, "SeatBack", Vector3.new(1.8, 2.4, 0.4), at(c, s[1], floorY + 2.2, s[2] + 1.05), rgb(34, 58, 110), Enum.Material.Fabric)
	end
end

---------------------------------------------------------------------
-- Avión de línea
---------------------------------------------------------------------
local CY, R = 8.5, 4.5 -- centro y radio del fuselaje

local function airliner(c: Ctx, color: Color3, opts: Options): BasePart
	local spec = Plan.Kinds.Avion
	local root = solid(c, "Root", Vector3.new(6.6, 0.6, 40), Plan.rootCFrame("Avion", c.CF), rgb(120, 124, 130), Enum.Material.DiamondPlate)
	-- Fuselaje: tubo, morro (elipsoide), cono de cola levantado y carenado ventral
	tube(c, "Fuselage", 40, R * 2, at(c, 0, CY, -2), BODY, Enum.Material.SmoothPlastic, true)
	ellipsoid(c, "Nose", Vector3.new(R * 2, R * 2, 26), at(c, 0, CY, -22), BODY, nil, true)
	ellipsoid(c, "TailCone", Vector3.new(R * 2, R * 2, 34), at(c, 0, CY, 18) * CFrame.Angles(rad(-9), 0, 0), BODY, nil, true)
	ellipsoid(c, "BellyFairing", Vector3.new(8, 3.8, 24), at(c, 0, 4.9, 1), rgb(226, 230, 236))
	-- Parabrisas envolvente y panel de instrumentos (por dentro)
	ellipsoid(c, "Windscreen", Vector3.new(7.2, 2.6, 7), at(c, 0, 11.3, -29.2), GLASS, Enum.Material.Glass)
	decor(c, "Panel", Vector3.new(3.6, 1.2, 0.8), at(c, 0, 8.4, -29.8), DARK)

	-- Librea: franjas azul marino y cian a lo largo, nombre de la aerolínea, ventanillas y puertas
	for _, side in { -1, 1 } do
		skin(c, "Cheatline", side, -0.4, -22, 18, 0.5, R, CY, CYAN)
		skin(c, "Cheatline", side, -0.56, -22, 18, 0.8, R, CY, NAVY)
		local win, face = skin(c, "Windows", side, 0.2, -16.6, 13.6, 1.1, R, CY)
		local gui = surface(win, face)
		local n = 18
		for k = 0, n - 1 do
			local w = frame(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((k + 0.5) / n, 0.5), Size = UDim2.fromScale(0.5 / n, 0.8), BackgroundColor3 = GLASS })
			round(w, UDim.new(0.35, 0))
		end
		local title, tface = skin(c, "Title", side, 0.62, -16, -2.5, 1.6, R, CY)
		text(surface(title, tface, 30), PlaneModel.Airline, NAVY)
		for _, dz in { -19.4, 15.6 } do
			local door, dface = skin(c, "Door", side, -0.15, dz - 1.2, dz + 1.2, 4, R, CY)
			local dgui = surface(door, dface)
			local outline = frame(dgui, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
			round(outline, UDim.new(0.18, 0))
			local stroke = Instance.new("UIStroke")
			stroke.Color = rgb(150, 156, 166)
			stroke.Thickness = 2
			stroke.Parent = outline
			local window = frame(dgui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.36, 0.13), BackgroundColor3 = GLASS })
			round(window, UDim.new(0.4, 0))
		end
	end

	-- Alas en flecha (25°) con diedro (5°): tres tramos cada vez más estrechos y winglet
	local sweep, dihedral = rad(25), rad(5)
	local tanS, tanD = math.tan(sweep), math.tan(dihedral)
	local rootY, rootZ = 4.6, -1
	local function wingY(x: number): number
		return rootY + tanD * x
	end
	local function quarter(x: number): number
		return rootZ + tanS * x
	end
	for _, side in { -1, 1 } do
		for _, p in { { 2.5, 11, 12, 0.9 }, { 11, 21, 8, 0.75 }, { 21, 32, 5, 0.6 } } do
			local x0, x1, chord, thick = p[1], p[2], p[3], p[4]
			local xm = (x0 + x1) / 2
			local size = Vector3.new((x1 - x0) / math.cos(sweep) + 0.6, thick, chord * math.cos(sweep))
			solid(c, "Wing", size, at(c, side * xm, wingY(xm), quarter(xm) + chord / 4) * CFrame.Angles(0, -side * sweep, 0) * CFrame.Angles(0, 0, side * dihedral), WING, Enum.Material.Metal)
		end
		-- Winglet (en flecha, un poco abierto hacia fuera)
		local wedge = decor(c, "Winglet", Vector3.new(0.35, 4.2, 3.4), at(c, side * 32.6, wingY(32) + 2.3, quarter(32) + 0.6) * CFrame.Angles(0, 0, -side * rad(12)), color, Enum.Material.SmoothPlastic, { ClassName = "WedgePart" })
		local _ = wedge
		-- Luces: de navegación en la punta (roja a la izquierda, verde a la derecha) y destellos blancos
		lamp(c, "NavLight", at(c, side * 32.5, wingY(32), quarter(32) - 1.6), if side < 0 then RED else GREEN)
		lamp(c, "Strobe", at(c, side * 32.4, wingY(32), quarter(32) + 2.2), WHITE, "Strobe")
		-- Motor (turbofán) bajo el ala: góndola, labio de la toma, fan, buje, cono de escape y pilón
		local ex, ey, ez = side * 11, 2.9, 0.85
		tube(c, "Engine", 7.5, 4.2, at(c, ex, ey, ez), color, Enum.Material.SmoothPlastic, true)
		tube(c, "Intake", 0.5, 4.3, at(c, ex, ey, ez - 3.55), SILVER, Enum.Material.Metal)
		tube(c, "Fan", 0.1, 3.5, at(c, ex, ey, ez - 3.82), DARK, Enum.Material.Metal)
		ellipsoid(c, "Spinner", Vector3.new(1.2, 1.2, 1.8), at(c, ex, ey, ez - 3.8), SILVER, Enum.Material.Metal)
		ellipsoid(c, "Exhaust", Vector3.new(2.8, 2.8, 4.4), at(c, ex, ey, ez + 3.75), rgb(110, 114, 122), Enum.Material.Metal)
		decor(c, "Pylon", Vector3.new(0.6, 1.1, 6), at(c, ex, 5.25, ez + 1.4), BODY)
		-- Tren principal: pata y dos ruedas (se sube en vuelo)
		decor(c, "Strut", Vector3.new(0.6, 3.4, 0.6), at(c, side * 4.6, 2.85, 3.5), METAL, Enum.Material.Metal, { Attributes = { Gear = true } })
		wheel(c, side * 3.9, 3.5, 1.15, 0.8, true)
		wheel(c, side * 5.3, 3.5, 1.15, 0.8, true)
	end
	-- Tren de morro
	decor(c, "NoseStrut", Vector3.new(0.5, 3.65, 0.5), at(c, 0, 2.7, -28), METAL, Enum.Material.Metal, { Attributes = { Gear = true } })
	wheel(c, -0.45, -28, 0.85, 0.6, true)
	wheel(c, 0.45, -28, 0.85, 0.6, true)

	-- Cola: estabilizadores en flecha (30°) y deriva trapezoidal con el logo
	for _, side in { -1, 1 } do
		local xm = 6.75
		decor(c, "Stabilizer", Vector3.new(12.5 / math.cos(rad(30)), 0.5, 4.8 * math.cos(rad(30))), at(c, side * xm, 10.4, 25.5 + math.tan(rad(30)) * xm + 1.2) * CFrame.Angles(0, -side * rad(30), 0) * CFrame.Angles(0, 0, side * rad(6)), WING, Enum.Material.Metal)
	end
	decor(c, "Fin", Vector3.new(0.9, 13.8, 9.5), at(c, 0, 18.1, 24.75), color, Enum.Material.SmoothPlastic, { ClassName = "WedgePart" })
	decor(c, "Fin", Vector3.new(0.9, 13.8, 5), at(c, 0, 18.1, 32), color)
	local logo = decor(c, "FinLogo", Vector3.new(1, 6, 6), at(c, 0, 18.6, 29.2), color, Enum.Material.SmoothPlastic, { Transparency = 1 })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = surface(logo, face)
		local disc = frame(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86), BackgroundColor3 = CYAN })
		round(disc, UDim.new(0.5, 0))
		text(disc, "V", WHITE)
	end
	-- Luces: blanca en la cola, baliza roja arriba y abajo
	lamp(c, "TailLight", at(c, 0, 11.3, 35), WHITE)
	lamp(c, "Beacon", at(c, 0, CY + R + 0.15, 2), RED, "Beacon")
	lamp(c, "Beacon", at(c, 0, 2.9, 8), RED, "Beacon")

	-- Cabina de pasajeros: 6 filas de 2 asientos mirando al morro (y la del piloto si se pilota)
	local list = {}
	for row = 0, 5 do
		for _, x in { -2, 2 } do
			table.insert(list, { x, -16 + row * 5 })
		end
	end
	seats(c, list, spec.FloorY, if opts.Pilot then { -1.25, spec.FloorY, -27 } else nil)
	if opts.Pilot then
		-- Copiloto (sin mandos): un asiento más en la cabina de mando
		decor(c, "CopilotSeat", Vector3.new(1.8, 0.5, 1.8), at(c, 1.25, spec.FloorY + 0.9, -27), rgb(60, 60, 66), Enum.Material.Fabric)
		decor(c, "SeatBack", Vector3.new(1.8, 2.4, 0.4), at(c, 1.25, spec.FloorY + 2.2, -25.95), rgb(50, 50, 56), Enum.Material.Fabric)
	end
	return root
end

---------------------------------------------------------------------
-- Avioneta (ala alta, tipo Cessna 172)
---------------------------------------------------------------------
local function cessna(c: Ctx, color: Color3, opts: Options): BasePart
	local spec = Plan.Kinds.Avioneta
	local F = spec.FloorY
	local root = solid(c, "Root", Vector3.new(3.6, 0.6, 9), Plan.rootCFrame("Avioneta", c.CF), rgb(120, 124, 130), Enum.Material.DiamondPlate)
	-- Cabina: parte baja, parte alta (bajo el ala) y parabrisas inclinado
	solid(c, "Cabin", Vector3.new(4.4, 4.1, 8.6), at(c, 0, 3.85, -1.3), BODY)
	solid(c, "CabinTop", Vector3.new(4.4, 1.9, 6.4), at(c, 0, 6.85, -0.2), BODY)
	decor(c, "Windshield", Vector3.new(4.2, 1.9, 2.2), at(c, 0, 6.85, -4.5), GLASS, Enum.Material.Glass, { ClassName = "WedgePart" })
	decor(c, "Panel", Vector3.new(3.8, 1, 0.5), at(c, 0, 5.4, -4.9), DARK)
	for _, side in { -1, 1 } do
		decor(c, "SideWindow", Vector3.new(0.06, 1.5, 2.6), at(c, side * 2.22, 6.8, -2), GLASS, Enum.Material.Glass)
		decor(c, "SideWindow", Vector3.new(0.06, 1.4, 2.2), at(c, side * 2.22, 6.8, 1.2), GLASS, Enum.Material.Glass)
		-- Franja de color (cabina y capó) y la matrícula
		decor(c, "Stripe", Vector3.new(0.06, 0.6, 8.6), at(c, side * 2.23, 4.6, -1.3), color)
		decor(c, "Stripe", Vector3.new(0.06, 0.6, 3.4), at(c, side * 1.93, 4.6, -7.3), color)
		local reg = decor(c, "Registration", Vector3.new(0.06, 1, 5), at(c, side * 2.24, 3.3, -0.6), BODY, Enum.Material.SmoothPlastic, { Transparency = 1 })
		text(surface(reg, if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left, 30), opts.Registration or "EC-VAL", NAVY, Enum.Font.GothamBold)
	end
	-- Capó, buje y hélice bipala (Prop: parada se ven las palas; girando, un disco)
	solid(c, "Cowl", Vector3.new(3.8, 3.6, 3.4), at(c, 0, 4.1, -7.3), BODY)
	ellipsoid(c, "CowlNose", Vector3.new(3.8, 3.6, 2.4), at(c, 0, 4.1, -9), BODY)
	decor(c, "Intake", Vector3.new(2.6, 0.5, 0.3), at(c, 0, 3.05, -9.75), DARK)
	ellipsoid(c, "Spinner", Vector3.new(1.5, 1.5, 2), at(c, 0, 4.4, -10.3), color)
	decor(c, "Propeller", Vector3.new(0.25, 6.6, 0.55), at(c, 0, 4.4, -10.7) * CFrame.Angles(0, 0, rad(20)), DARK, Enum.Material.SmoothPlastic, { Attributes = { Prop = "Blade" } })
	decor(c, "PropDisc", Vector3.new(0.08, 6.8, 6.8), at(c, 0, 4.4, -10.75) * ALONG_Z, rgb(60, 62, 70), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Transparency = 1, Attributes = { Prop = "Disc" } })
	-- Cono de cola (sube hacia la deriva)
	ellipsoid(c, "TailCone", Vector3.new(4.4, 5.6, 22), at(c, 0, 5, 3) * CFrame.Angles(rad(-7), 0, 0), BODY, nil, true)
	-- Ala alta: tramo central recto y puntas más estrechas, con montantes
	solid(c, "Wing", Vector3.new(17.2, 0.55, 4.8), at(c, 0, 8.08, -2.6), BODY, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		solid(c, "Wing", Vector3.new(8.2, 0.5, 3.8), at(c, side * 12.3, 8.2, -2.95) * CFrame.Angles(0, 0, side * rad(2)), BODY, Enum.Material.SmoothPlastic)
		decor(c, "WingTip", Vector3.new(0.9, 0.5, 3.6), at(c, side * 16.6, 8.36, -3), color)
		decor(c, "Strut", Vector3.new(8.74, 0.3, 0.6), at(c, side * 5.85, 5.4, -2.4) * CFrame.Angles(0, 0, side * rad(33.3)), SILVER, Enum.Material.Metal)
		lamp(c, "NavLight", at(c, side * 17.15, 8.36, -4), if side < 0 then RED else GREEN)
		-- Tren fijo: pata de ballesta, rueda y carenado
		decor(c, "Leg", Vector3.new(2, 0.25, 0.6), at(c, side * 2.85, 1.9, 0.3) * CFrame.Angles(0, 0, side * rad(-30.5)), SILVER, Enum.Material.Metal)
		wheel(c, side * 3.7, 0.3, 1, 0.7)
		ellipsoid(c, "WheelPant", Vector3.new(1.1, 1.5, 2.8), at(c, side * 3.7, 1.2, 0.3), color)
	end
	decor(c, "NoseStrut", Vector3.new(0.3, 2, 0.3), at(c, 0, 1.95, -8.2), SILVER, Enum.Material.Metal)
	wheel(c, 0, -8.2, 0.85, 0.6)
	ellipsoid(c, "WheelPant", Vector3.new(0.9, 1.2, 2.2), at(c, 0, 1.05, -8.2), color)
	decor(c, "LandingLight", Vector3.new(0.6, 0.3, 0.3), at(c, -6, 8.05, -5.05), WHITE, Enum.Material.Neon)
	-- Cola: estabilizador y deriva en flecha (del color de la avioneta)
	decor(c, "Stabilizer", Vector3.new(11.2, 0.35, 2.6), at(c, 0, 5.9, 12.6), BODY)
	decor(c, "Fin", Vector3.new(0.4, 5, 3.4), at(c, 0, 8.9, 10.7), color, Enum.Material.SmoothPlastic, { ClassName = "WedgePart" })
	decor(c, "Fin", Vector3.new(0.4, 5, 2.2), at(c, 0, 8.9, 13.5), color)
	lamp(c, "TailLight", at(c, 0, 6.6, 14.75), WHITE)
	lamp(c, "Beacon", at(c, 0, 11.55, 13.2), RED, "Beacon")
	-- Asientos: piloto y copiloto delante, dos detrás
	local list = {}
	local pilot = if opts.Pilot then { -1.05, F, -2.4 } else nil
	for _, s in { { -1.05, -2.4 }, { 1.05, -2.4 }, { -1.05, 0.9 }, { 1.05, 0.9 } } do
		if not (pilot and s[1] == pilot[1] and s[2] == pilot[3]) then
			table.insert(list, s)
		end
	end
	seats(c, list, F, pilot)
	return root
end

-- Construye el avión en m (cf = suelo bajo las ruedas, morro a -Z). Devuelve su suelo "Root".
function PlaneModel.build(kind: string, color: Color3, cf: CFrame, m: Model, opts: Options?): BasePart
	local c: Ctx = { Model = m, CF = cf }
	local root = if kind == "Avion" then airliner(c, color, opts or {}) else cessna(c, color, opts or {})
	m.PrimaryPart = root
	return root
end

return PlaneModel
