-- MetroAccess: las bocas de metro que se bajan andando (la geometría sale de Shared/Metro.access).
--
--   calle ─▶ boca con barandillas, la gran M y el ascensor (modelo "BocaMetro", sale en el mapa)
--        ─▶ dos tramos de escalera con rellano
--        ─▶ vestíbulo bajo la calle: máquinas de billetes, plano, panel de próximos trenes, anuncios
--        ─▶ pozo inclinado: escalera mecánica de bajada, escalera fija y escalera mecánica de subida
--        ─▶ vestíbulo de andenes (tornos) ─▶ andén
--
-- Las escaleras mecánicas llevan de verdad: su suelo invisible (tag MetroEscalator) tiene una
-- velocidad (atributo Velocity) que MetroService le pone como cinta transportadora; los peldaños que
-- se ven los mueve cada cliente (MetroUI) solo cuando está cerca. Las escaleras fijas son una rampa
-- invisible con los peldaños de adorno encima (se sube y se baja sin tropezar).
-- El ascensor de la boca (tag MetroEntrance) es el único atajo: baja directo al vestíbulo de andenes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local MetroDetails = require(script.Parent.MetroDetails)
local Metro = require(ReplicatedStorage.Shared.Metro)

local MetroAccess = {}

local rgb = Color3.fromRGB
local TILE = rgb(236, 232, 222)
local DARK = rgb(34, 36, 42)
local STEEL = rgb(170, 174, 180)
local GRANITE = rgb(128, 126, 122)
local STEP = rgb(150, 148, 142)
local RAIL_GREEN = rgb(38, 70, 52) -- barandillas de hierro pintado, como las de siempre
local M_RED = rgb(200, 30, 40)
local V3 = Vector3.new

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

-- Pieza invisible por la que se anda (rampas y cintas)
local function walkable(parent: Instance, name: string, size: Vector3, cf: CFrame, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Transparency = 1, CastShadow = false, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function signBoard(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3, both: boolean?, textColor: Color3?): BasePart
	local board = decor(parent, "Sign", size, cf, color)
	Builder.sign(board, text, Enum.NormalId.Front, textColor)
	if both then
		Builder.sign(board, text, Enum.NormalId.Back, textColor)
	end
	return board
end

local function surfaceLight(target: BasePart, face: Enum.NormalId, range: number, brightness: number?)
	local light = Instance.new("SurfaceLight")
	light.Face = face
	light.Angle = 120
	light.Range = range
	light.Brightness = brightness or 1.3
	light.Color = rgb(255, 246, 230)
	light.Shadows = false
	light.Parent = target
end

-- Caja alineada con el mundo entre dos esquinas
local function wbox(parent: Instance, name: string, lo: Vector3, hi: Vector3, color: Color3, material: Enum.Material?, isDecor: boolean?, extra: { [string]: any }?): BasePart?
	local size = hi - lo
	if size.X < 0.05 or size.Y < 0.05 or size.Z < 0.05 then
		return nil
	end
	local fn = if isDecor then decor else part
	return fn(parent, name, size, CFrame.new((lo + hi) / 2), color, material, extra)
end

local function linesAt(stationId: string): { Metro.Line }
	local list = {}
	for _, line in Metro.Lines do
		if table.find(line.Stations, stationId) then
			table.insert(list, line)
		end
	end
	return list
end

-- Tramo de escalera: peldaños de adorno y una rampa invisible que pasa por el borde de cada peldaño
-- (top = centro del borde de arriba, dir = hacia dónde baja, en horizontal)
local function flight(parent: Instance, top: Vector3, dir: Vector3, steps: number, rise: number, run: number, width: number, color: Color3, material: Enum.Material?, nosing: Color3?)
	local cf = Builder.facing(top, dir)
	for i = 1, steps do
		local y = -rise * i
		local h = rise + 1
		decor(parent, "Step", V3(width, h, run), cf * CFrame.new(0, y - h / 2, -(run * (i - 0.5))), color, material or Enum.Material.Granite)
		if nosing and i % 2 == 1 then
			-- Borde antideslizante (uno sí y otro no: menos piezas y se ve igual)
			decor(parent, "Nosing", V3(width, 0.06, 0.3), cf * CFrame.new(0, y + 0.03, -(run * (i - 1) + 0.2)), nosing, Enum.Material.DiamondPlate)
		end
	end
	local a = math.atan2(rise * steps, run * steps)
	local len = math.sqrt((run * steps) ^ 2 + (rise * steps) ^ 2)
	local mid = cf * CFrame.new(0, -rise * steps / 2, -run * steps / 2)
	walkable(parent, "Ramp", V3(width, 1, len), mid * CFrame.Angles(-a, 0, 0) * CFrame.new(0, -0.5, 0))
end

-- Pieza inclinada paralela a una pendiente: centro en la línea (dist0..dist1) desplazada "up" en
-- perpendicular. cf = marco del tramo (mirando hacia donde baja), tan = pendiente
local function sloped(cf: CFrame, x: number, dist0: number, dist1: number, tan: number, up: number): (CFrame, number)
	local a = math.atan(tan)
	local mid = (dist0 + dist1) / 2
	local len = (dist1 - dist0) / math.cos(a)
	return cf * CFrame.new(x, -mid * tan, -mid) * CFrame.Angles(-a, 0, 0) * CFrame.new(0, up, 0), len
end

---------------------------------------------------------------------
-- La boca en la calle
---------------------------------------------------------------------

-- Agujero en el suelo de la calle: parte en trozos las losas que lo tapan (plaza, césped, suelo de
-- previsualización) y quita lo pequeño que estorbe. rect = { lo, hi } en X/Z (mundo)
local function cutGround(world: Instance, skip: Instance, holes: { { Vector3 } })
	-- (una sola pasada por toda la ciudad para todos los agujeros)
	local found = {}
	for _, p in world:GetDescendants() do
		-- (las zonas invisibles, como las de la historia, no se tocan)
		if p:IsA("BasePart") and p.Transparency < 0.99 then
			local pos, s = p.CFrame.Position, p.Size
			local r = math.max(s.X, s.Y, s.Z) / 2 + 0.1
			for _, h in holes do
				local lo, hi = h[1], h[2]
				if pos.X + r > lo.X and pos.X - r < hi.X and pos.Z + r > lo.Z and pos.Z - r < hi.Z and not p:IsDescendantOf(skip) then
					table.insert(found, { p, lo, hi })
				end
			end
		end
	end
	-- (una pieza puede tocar dos agujeros: si ya se partió o quitó con el primero, se salta; en el
	-- constructor, mirar Parent de una pieza destruida da error)
	for _, item in found do
		local p, lo, hi = item[1], item[2], item[3]
		local okParent, parent = pcall(function()
			return p.Parent
		end)
		if not okParent or not parent then
			continue
		end
		local c = { p.CFrame:GetComponents() }
		local s = p.Size
		-- Caja de la pieza en el mundo (solo si está recta o girada 90°)
		local straight = p:IsA("Part") and (p :: Part).Shape == Enum.PartType.Block
		for i = 4, 12 do
			local v = math.abs(c[i])
			if v > 1e-3 and math.abs(v - 1) > 1e-3 then
				straight = false
			end
		end
		local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
		local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
		local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
		if not straight then
			hx, hz = math.max(s.X, s.Z) / 2, math.max(s.X, s.Z) / 2
			hy = s.Y / 2
		end
		local x0, x1, z0, z1 = c[1] - hx, c[1] + hx, c[3] - hz, c[3] + hz
		local y0, y1 = c[2] - hy, c[2] + hy
		if x1 > lo.X and x0 < hi.X and z1 > lo.Z and z0 < hi.Z and y1 > -16 and y0 < 1.6 then
			if straight and (x1 - x0) * (z1 - z0) > 40 then
				-- Losa grande: se queda alrededor del agujero (hasta 4 trozos)
				local pieces = {
					{ x0, lo.X, z0, z1 },
					{ hi.X, x1, z0, z1 },
					{ math.max(x0, lo.X), math.min(x1, hi.X), z0, lo.Z },
					{ math.max(x0, lo.X), math.min(x1, hi.X), hi.Z, z1 },
				}
				for _, q in pieces do
					if q[2] - q[1] > 0.05 and q[4] - q[3] > 0.05 then
						local piece = p:Clone()
						-- (el tamaño en los ejes de la pieza, que puede estar girada 90°)
						local wx, wz = q[2] - q[1], q[4] - q[3]
						-- (columna 1 de la rotación = eje X de la pieza; columna 3 = eje Z)
						local sx = if math.abs(c[4]) > 0.5 then wx elseif math.abs(c[10]) > 0.5 then wz else s.X
						local sz = if math.abs(c[12]) > 0.5 then wz elseif math.abs(c[6]) > 0.5 then wx else s.Z
						piece.Size = V3(sx, s.Y, sz)
						piece.CFrame = CFrame.new((q[1] + q[2]) / 2, c[2], (q[3] + q[4]) / 2) * (p.CFrame - p.CFrame.Position)
						piece.Parent = p.Parent
					end
				end
				p:Destroy()
			elseif math.max(s.X, s.Y, s.Z) < 20 then
				-- Algo pequeño en medio (un parterre, una papelera…): fuera, con su modelo si es suyo
				local model = p.Parent
				if model and model:IsA("Model") and model.Parent and #model:GetChildren() < 40 and not model:IsA("Workspace") then
					model:Destroy()
				elseif p.Parent then
					p:Destroy()
				end
			end
		end
	end
end

local function railing(parent: Instance, a: Vector3, b: Vector3, y: number)
	-- Barandilla de hierro: postes, pasamanos y una barrera invisible para no caerse
	local d = b - a
	local len = d.Magnitude
	if len < 0.5 then
		return
	end
	local cf = Builder.facing((a + b) / 2, d)
	part(parent, "Curb", V3(0.7, 0.5, len + 0.7), cf * CFrame.new(0, y + 0.25, 0), GRANITE, Enum.Material.Granite)
	decor(parent, "Handrail", V3(0.3, 0.3, len + 0.4), cf * CFrame.new(0, y + 3.6, 0), RAIL_GREEN, Enum.Material.Metal)
	decor(parent, "MidRail", V3(0.15, 0.15, len), cf * CFrame.new(0, y + 2, 0), RAIL_GREEN, Enum.Material.Metal)
	walkable(parent, "RailBarrier", V3(0.4, 3.6, len), cf * CFrame.new(0, y + 2.3, 0))
	local posts = math.max(1, math.floor(len / 3.2))
	for i = 0, posts do
		decor(parent, "RailPost", V3(0.25, 3.5, 0.25), cf * CFrame.new(0, y + 2.05, -len / 2 + i * len / posts), RAIL_GREEN, Enum.Material.Metal)
	end
end

local function mouth(root: Instance, A: any, station: Metro.Station): (Model, Vector3, Vector3)
	local m = Builder.model("BocaMetro", root)
	m:SetAttribute("PlaceName", "Metro · " .. station.Name)
	m:SetAttribute("Station", station.Id)
	local S = A.Stair
	local W = S.Width
	local sd = S.Dir
	local right = V3(-sd.Z, 0, sd.X) -- la x local del marco de abajo (a la derecha bajando)
	local cf = Builder.facing(S.Top, sd) -- x a la derecha bajando, -z hacia abajo
	-- (x a lo ancho, y ALTURA en el mundo, dist = cuánto se ha bajado en horizontal desde arriba)
	local function at(x: number, y: number, dist: number): CFrame
		return cf * CFrame.new(x, y - S.Top.Y, -dist)
	end
	local street = Metro.StreetY
	local lines = linesAt(station.Id)

	-- Tramos de escalera y rellano (peldaños de granito con el borde metálico)
	for i, f in S.Flights do
		flight(m, f.Top, sd, f.Steps, f.Rise, f.Run, W, STEP, Enum.Material.Granite, STEEL)
		local land = S.Landings[i]
		if land then
			local len = (land.To - land.From).Magnitude
			part(m, "Landing", V3(W, 1, len), Builder.facing((land.From + land.To) / 2, sd) * CFrame.new(0, -0.5, 0), STEP, Enum.Material.Granite)
		end
	end
	-- Paredes del hueco (de azulejo blanco con una franja de la línea) de arriba abajo
	local bottomY = Metro.HallY - 1
	for _, side in { -1, 1 } do
		part(m, "StairWall", V3(0.6, street - bottomY, S.Length + 0.6), at(side * (W / 2 + 0.3), (street + bottomY) / 2, S.Length / 2 - 0.3), TILE, Enum.Material.Marble)
		decor(m, "WallBand", V3(0.1, 0.8, S.Length), at(side * (W / 2 + 0.02), -9, S.Length / 2), lines[1].Color)
		-- Pasamanos pegados a la pared, siguiendo cada tramo
		for _, f in S.Flights do
			local d0 = (V3(f.Top.X, 0, f.Top.Z) - V3(S.Top.X, 0, S.Top.Z)).Magnitude
			local d1 = d0 + f.Steps * f.Run
			local rcf, len = sloped(cf * CFrame.new(0, f.Top.Y - S.Top.Y + d0 * f.Rise / f.Run, 0), side * (W / 2 - 0.15), d0, d1, f.Rise / f.Run, 3)
			decor(m, "WallHandrail", V3(0.2, 0.2, len), rcf, STEEL, Enum.Material.Metal)
		end
	end
	-- Techo de la parte cubierta (bajo la calle) y luces
	local open = S.Open
	part(m, "StairCover", V3(W + 1.2, 3.5, S.Length - open + 0.3), at(0, -2.75, (open + S.Length) / 2 + 0.15), rgb(90, 88, 84), Enum.Material.Concrete)
	local lamp = decor(m, "StairLamp", V3(W - 1, 0.15, 1), at(0, -4.6, (open + S.Length) / 2), rgb(250, 250, 255), Enum.Material.Neon)
	surfaceLight(lamp, Enum.NormalId.Bottom, 16)
	local wallLamp = decor(m, "StairLamp", V3(0.2, 0.6, 3), at(-(W / 2 - 0.1), -3, S.Flights[1].Steps * S.Flights[1].Run + 1.8), rgb(255, 240, 210), Enum.Material.Neon)
	surfaceLight(wallLamp, Enum.NormalId.Right, 14, 1)

	-- Barandillas alrededor del hueco (la entrada, arriba, queda abierta)
	for _, side in { -1, 1 } do
		railing(m, (at(side * (W / 2 + 0.3), 0, 0)).Position, (at(side * (W / 2 + 0.3), 0, open)).Position, street)
	end
	railing(m, (at(-(W / 2 + 0.3), 0, open)).Position, (at(W / 2 + 0.3, 0, open)).Position, street)

	-- Pórtico de la entrada: dos pilares y el cartel METRO (por encima de la cabeza) con las franjas
	-- de sus líneas
	for _, side in { -1, 1 } do
		part(m, "Pillar", V3(0.7, 7.6, 0.7), at(side * (W / 2 + 0.3), street + 3.8, -0.2), RAIL_GREEN, Enum.Material.Metal)
		decor(m, "PillarLamp", V3(0.9, 0.9, 0.9), at(side * (W / 2 + 0.3), street + 8, -0.2), rgb(255, 236, 190), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	end
	local header = signBoard(m, at(0, street + 6.9, -0.2), V3(W + 1.4, 1.3, 0.35), "METRO · " .. string.upper(station.Name), DARK, true)
	local _ = header
	for i, line in lines do
		decor(m, "LineStripe", V3(W + 1.4, 0.25, 0.4), at(0, street + 7.7 + (i - 1) * 0.3, -0.2), line.Color, Enum.Material.Neon)
	end

	-- La gran M roja encima de un poste (con luz) al lado de la entrada que queda lejos de la calzada
	local st = Metro.Stations[station.Id]
	local away = V3(-st.Facing[1], 0, -st.Facing[2])
	local roadSide = if right:Dot(away) > 0 then 1 else -1 -- (en realidad: el lado lejos de la calzada)
	local totem = at(roadSide * (W / 2 + 2.4), 0, -2)
	part(m, "TotemPole", V3(0.5, 9, 0.5), totem * CFrame.new(0, street + 4.5, 0), DARK, Enum.Material.Metal)
	local cube = part(m, "MetroSign", V3(2.6, 2.6, 2.6), totem * CFrame.new(0, street + 10.3, 0), M_RED, Enum.Material.Neon) -- (brilla de noche)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		Builder.sign(cube, "M", face, Color3.new(1, 1, 1), M_RED)
	end
	local glow = Instance.new("PointLight")
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Color = rgb(255, 120, 120)
	glow.Parent = cube
	-- Panel del próximo tren (uno por línea) colgado del poste de la M
	for i, line in lines do
		local board = decor(m, "Departures", V3(4.6, 1, 0.2), totem * CFrame.new(0, street + 7.4 - (i - 1) * 1.15, 0) * CFrame.Angles(0, math.pi / 2, 0), DARK)
		Builder.sign(board, "PRÓXIMO TREN", Enum.NormalId.Front, rgb(255, 200, 40), DARK)
		Builder.sign(board, "PRÓXIMO TREN", Enum.NormalId.Back, rgb(255, 200, 40), DARK)
		board:AddTag("MetroDisplay")
		board:SetAttribute("Line", line.Id)
		board:SetAttribute("Station", station.Id)
		decor(m, "LineTag", V3(0.3, 1, 0.24), totem * CFrame.new(0, street + 7.4 - (i - 1) * 1.15, 0) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(-2.45, 0, 0), line.Color, Enum.Material.Neon)
	end
	-- Señales en la acera, a unos pasos por cada lado: "🚇 METRO 50 m ▶"
	if not st.Hub then
		local access = st.Access :: any
		local inward = access.Stair - access.Edge + 1.2
		for _, dist in { -50, S.Length + 50 } do
			local p = S.Top + sd * dist - away * inward
			local cfSign = Builder.facing(V3(p.X, street, p.Z), -away)
			part(m, "MetroPointerPole", V3(0.3, 7.5, 0.3), cfSign * CFrame.new(0, 3.75, 0), DARK, Enum.Material.Metal)
			local plate = decor(m, "MetroPointer", V3(4.4, 1.3, 0.12), cfSign * CFrame.new(0, 6.6, 0), M_RED)
			local toMouth = if dist < 0 then sd else -sd
			local frontRight = toMouth:Dot(cfSign.RightVector) < 0
			local meters = math.floor(math.abs(if dist < 0 then dist else dist - S.Length) + 0.5)
			Builder.sign(plate, ("🚇 METRO %d m %s"):format(meters, if frontRight then "▶" else "◀"), Enum.NormalId.Front, Color3.new(1, 1, 1), M_RED)
			Builder.sign(plate, ("%s 🚇 METRO %d m"):format(if frontRight then "◀" else "▶", meters), Enum.NormalId.Back, Color3.new(1, 1, 1), M_RED)
		end
	end
	-- Plano de la red en un mupi junto a la barandilla
	local mupi = at(roadSide * (W / 2 + 2.2), 0, S.Open * 0.72)
	part(m, "MapStand", V3(0.5, 6, 3.2), mupi * CFrame.new(0, street + 3, 0), DARK, Enum.Material.Metal)
	local map = decor(m, "NetworkMap", V3(0.1, 4, 2.8), mupi * CFrame.new(0.3, street + 3.6, 0), rgb(245, 245, 240))
	Builder.sign(map, "🚇 METRO\n\n🔴 L1\nPoniente · Plaza Mayor · Levante · Playa Dorada\n\n🔵 L2\nNorte · Plaza Mayor · San Roque · Puerto", Enum.NormalId.Right, DARK, rgb(245, 245, 240))
	Builder.sign(map, "🚇 METRO\n\n🔴 L1\nPoniente · Plaza Mayor · Levante · Playa Dorada\n\n🔵 L2\nNorte · Plaza Mayor · San Roque · Puerto", Enum.NormalId.Left, DARK, rgb(245, 245, 240))

	-- Ascensor (accesible): caseta de cristal; su puerta mira a la acera
	local lift = at(roadSide * (W / 2 + 5.4), 0, -5.5)
	local LW = 4.4
	for _, x in { -LW / 2, LW / 2 } do
		for _, z in { -LW / 2, LW / 2 } do
			decor(m, "LiftFrame", V3(0.35, 7.4, 0.35), lift * CFrame.new(x, street + 3.7, z), DARK, Enum.Material.Metal)
		end
	end
	part(m, "LiftGlass", V3(0.2, 7, LW), lift * CFrame.new(-LW / 2, street + 3.5, 0), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.5 })
	part(m, "LiftGlass", V3(0.2, 7, LW), lift * CFrame.new(LW / 2, street + 3.5, 0), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.5 })
	part(m, "LiftGlass", V3(LW, 7, 0.2), lift * CFrame.new(0, street + 3.5, -LW / 2), rgb(170, 210, 230), Enum.Material.Glass, { Transparency = 0.5 })
	part(m, "LiftRoof", V3(LW + 0.8, 0.5, LW + 0.8), lift * CFrame.new(0, street + 7.6, 0), DARK, Enum.Material.Metal)
	part(m, "LiftFloor", V3(LW, 0.2, LW), lift * CFrame.new(0, street + 0.1, 0), STEEL, Enum.Material.DiamondPlate)
	signBoard(m, lift * CFrame.new(0, street + 6.6, LW / 2 + 0.05) * CFrame.Angles(0, math.pi, 0), V3(LW, 0.9, 0.1), "♿ ASCENSOR", rgb(30, 90, 170))
	-- La puerta del ascensor (MetroService: "Bajar en ascensor"); su frente (-Z) mira hacia fuera
	Builder.part({
		Name = "MetroLift",
		Size = V3(3, 5, 2),
		CFrame = lift * CFrame.new(0, street + 2.5, 0) * CFrame.Angles(0, math.pi, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Tags = { "MetroEntrance" },
		Attributes = { Station = station.Id },
		Parent = m,
	})

	-- Suelo alrededor: en la calle, una losa de baldosas hasta el borde de la acera; en la plaza,
	-- el suelo que ya había, con el agujero de la escalera
	local openLo, openHi
	do
		local p1 = (at(-(W / 2 + 0.6), 0, 0)).Position
		local p2 = (at(W / 2 + 0.6, 0, open)).Position
		openLo = V3(math.min(p1.X, p2.X), 0, math.min(p1.Z, p2.Z))
		openHi = V3(math.max(p1.X, p2.X), 0, math.max(p1.Z, p2.Z))
	end
	if not st.Hub then
		local q1 = (at(-(W / 2 + 8), 0, -9)).Position
		local q2 = (at(W / 2 + 8, 0, S.Length + 1.5)).Position
		local lo = V3(math.min(q1.X, q2.X), street - 2, math.min(q1.Z, q2.Z))
		local hi = V3(math.max(q1.X, q2.X), street, math.max(q1.Z, q2.Z))
		-- Hasta el borde de la acera, sin pisarla
		local edge = (st.Access :: any).Edge
		local c = V3(st.Surface[1], 0, st.Surface[2])
		local along = away.X * c.X + away.Z * c.Z + edge
		if math.abs(away.X) > 0.5 then
			if away.X > 0 then
				lo = V3(along, lo.Y, lo.Z)
			else
				hi = V3(-along, hi.Y, hi.Z)
			end
		else
			if away.Z > 0 then
				lo = V3(lo.X, lo.Y, along)
			else
				hi = V3(hi.X, hi.Y, -along)
			end
		end
		local color, mat = rgb(188, 182, 170), Enum.Material.Pavement
		wbox(m, "Apron", lo, V3(openLo.X, hi.Y, hi.Z), color, mat)
		wbox(m, "Apron", V3(openHi.X, lo.Y, lo.Z), hi, color, mat)
		wbox(m, "Apron", V3(openLo.X, lo.Y, lo.Z), V3(openHi.X, hi.Y, openLo.Z), color, mat)
		wbox(m, "Apron", V3(openLo.X, lo.Y, openHi.Z), V3(openHi.X, hi.Y, hi.Z), color, mat)
		-- Bordillo alrededor de la losa (donde no toca la acera) y alguna cosa encima
		local border = rgb(150, 146, 138)
		for _, e in { { V3(lo.X - 0.4, lo.Y, lo.Z - 0.4), V3(hi.X + 0.4, hi.Y + 0.02, lo.Z) }, { V3(lo.X - 0.4, lo.Y, hi.Z), V3(hi.X + 0.4, hi.Y + 0.02, hi.Z + 0.4) } } do
			wbox(m, "ApronEdge", e[1], e[2], border, Enum.Material.Concrete)
		end
		for _, e in { { V3(lo.X - 0.4, lo.Y, lo.Z), V3(lo.X, hi.Y + 0.02, hi.Z) }, { V3(hi.X, lo.Y, lo.Z), V3(hi.X + 0.4, hi.Y + 0.02, hi.Z) } } do
			wbox(m, "ApronEdge", e[1], e[2], border, Enum.Material.Concrete)
		end
		-- Una papelera y un banco al lado de la boca
		MetroDetails.bin(m, at(roadSide * (W / 2 + 3), street, S.Length - 1))
		local bench = at(roadSide * (W / 2 + 4.6), street, open * 0.35) * CFrame.Angles(0, roadSide * math.pi / 2, 0)
		part(m, "Bench", V3(5, 0.4, 1.6), bench * CFrame.new(0, 1.5, 0), rgb(140, 100, 64), Enum.Material.Wood)
		for _, x in { -2, 2 } do
			decor(m, "BenchLeg", V3(0.3, 1.3, 1.4), bench * CFrame.new(x, 0.65, 0), DARK, Enum.Material.Metal)
		end
		decor(m, "BenchBack", V3(5, 1.4, 0.25), bench * CFrame.new(0, 2.4, 0.7), rgb(140, 100, 64), Enum.Material.Wood)
	end
	return m, openLo, openHi
end

---------------------------------------------------------------------
-- Vestíbulo bajo la calle
---------------------------------------------------------------------

-- Huecos de cada pared: { lado = "X-", "X+", "Z-", "Z+"; a, b = tramo; top = hasta qué altura }
local function wallKey(normal: Vector3): string
	if math.abs(normal.X) > 0.5 then
		return if normal.X > 0 then "X+" else "X-"
	end
	return if normal.Z > 0 then "Z+" else "Z-"
end

local function hall(root: Instance, A: any, station: Metro.Station): Model
	local m = Builder.model("Vestibulo_" .. station.Id, root)
	m:SetAttribute("PlaceName", "Metro · " .. station.Name)
	local lo, hi = A.Hall.Min, A.Hall.Max
	local y0, y1 = lo.Y, hi.Y
	local lines = linesAt(station.Id)
	local line = lines[1]
	-- Suelo de terrazo, techo y rodapié
	wbox(m, "HallFloor", V3(lo.X, y0 - 1, lo.Z), V3(hi.X, y0, hi.Z), rgb(214, 208, 196), Enum.Material.Marble)
	wbox(m, "HallCeiling", V3(lo.X, y1, lo.Z), V3(hi.X, y1 + 0.5, hi.Z), rgb(200, 198, 192), Enum.Material.Concrete)
	-- Huecos: por uno entra la escalera de la calle y por otro salen las mecánicas
	local S, K = A.Stair, A.Shaft
	local holes: { [string]: { { number } } } = { ["X-"] = {}, ["X+"] = {}, ["Z-"] = {}, ["Z+"] = {} }
	local function addHole(normal: Vector3, center: Vector3, half: number, top: number)
		local key = wallKey(normal)
		local c = if math.abs(normal.X) > 0.5 then center.Z else center.X
		table.insert(holes[key], { c - half, c + half, top })
	end
	addHole(-S.Dir, S.Bottom, S.Width / 2 + 0.6, y1)
	addHole(K.Dir, K.Top, K.Width / 2, y0 + Metro.Shaft.Headroom)
	local T = 0.6
	local walls = {
		{ Key = "X-", A = lo.Z, B = hi.Z, At = lo.X - T / 2, Normal = V3(1, 0, 0) },
		{ Key = "X+", A = lo.Z, B = hi.Z, At = hi.X + T / 2, Normal = V3(-1, 0, 0) },
		{ Key = "Z-", A = lo.X - T, B = hi.X + T, At = lo.Z - T / 2, Normal = V3(0, 0, 1) },
		{ Key = "Z+", A = lo.X - T, B = hi.X + T, At = hi.Z + T / 2, Normal = V3(0, 0, -1) },
	}
	local free = {}
	for _, w in walls do
		local list = holes[w.Key]
		table.sort(list, function(a, b)
			return a[1] < b[1]
		end)
		local function piece(a: number, b: number, ya: number, yb: number, band: boolean)
			if b - a < 0.05 then
				return
			end
			local isX = w.Key == "X-" or w.Key == "X+"
			local l0 = if isX then V3(w.At - T / 2, ya, a) else V3(a, ya, w.At - T / 2)
			local h0 = if isX then V3(w.At + T / 2, yb, b) else V3(b, yb, w.At + T / 2)
			wbox(m, "HallWall", l0, h0, TILE, Enum.Material.Marble)
			if band then
				-- Franja de azulejo con el color de la línea (por dentro)
				local inset = w.Normal * (T / 2 + 0.02)
				local c = (l0 + h0) / 2 + inset
				local size = if isX then V3(0.05, 0.9, b - a) else V3(b - a, 0.9, 0.05)
				decor(m, "HallBand", size, CFrame.new(c.X, y0 + 5.2, c.Z), line.Color)
			end
		end
		local cursor = w.A
		for _, h in list do
			piece(cursor, h[1], y0 - 1, y1 + 0.5, true)
			if h[3] < y1 then
				piece(h[1], h[2], h[3], y1 + 0.5, false)
			end
			if h[1] - cursor > 4 then
				table.insert(free, { Wall = w, A = cursor + 0.8, B = h[1] - 0.8 })
			end
			cursor = h[2]
		end
		piece(cursor, w.B, y0 - 1, y1 + 0.5, true)
		if w.B - cursor > 4 then
			table.insert(free, { Wall = w, A = cursor + (if #list > 0 then 0.8 else 1.4), B = w.B - 1.4 })
		end
	end
	-- Luces del techo (paneles; solo algunos con luz de verdad)
	local lights = 0
	for x = lo.X + 5, hi.X - 3, 10 do
		for z = lo.Z + 4, hi.Z - 3, 10 do
			local panel = decor(m, "CeilingLamp", V3(4, 0.15, 1.2), CFrame.new(x, y1 - 0.08, z), rgb(250, 250, 255), Enum.Material.Neon)
			if lights < 3 and (x - lo.X) % 20 < 10 then
				surfaceLight(panel, Enum.NormalId.Bottom, 18)
				lights += 1
			end
		end
	end
	if lights == 0 then
		local panel = decor(m, "CeilingLamp", V3(4, 0.15, 1.2), CFrame.new((lo.X + hi.X) / 2, y1 - 0.08, (lo.Z + hi.Z) / 2), rgb(250, 250, 255), Enum.Material.Neon)
		surfaceLight(panel, Enum.NormalId.Bottom, 20)
	end
	-- Carteles sobre los huecos (por dentro)
	local function over(center: Vector3, normal: Vector3, width: number, height: number, text: string, color: Color3)
		-- normal = hacia dentro del vestíbulo
		local p = center + normal * 0.45
		local cf = Builder.facing(V3(p.X, height, p.Z), normal)
		signBoard(m, cf, V3(width, 1.2, 0.15), text, color)
	end
	local dests = {}
	for _, l in lines do
		table.insert(dests, l.Name)
	end
	local stairWall = S.Bottom
	local kTop = K.Top
	over(V3(stairWall.X, 0, stairWall.Z), S.Dir, S.Width, y1 - 0.8, "↑ SALIDA · CALLE", DARK)
	over(V3(kTop.X, 0, kTop.Z), -K.Dir, math.min(K.Width - 1, 10), y0 + Metro.Shaft.Headroom + 0.1, "↓ ANDENES · " .. table.concat(dests, " · "), line.Color)
	-- Lo que va en las paredes libres: máquinas de billetes, plano, panel, anuncios, banco…
	table.sort(free, function(a, b)
		return (a.B - a.A) > (b.B - b.A)
	end)
	local items = { "Machines", "Map", "Advert", "Bench", "Advert", "Advert" }
	local slots = {}
	for _, f in free do
		local cursor = f.A
		table.insert(slots, { F = f, Cursor = cursor })
	end
	local function take(width: number): (CFrame?, any)
		for _, s in slots do
			if s.Cursor + width <= s.F.B then
				local c = s.Cursor + width / 2
				s.Cursor += width + 0.6
				local w = s.F.Wall
				local isX = w.Key == "X-" or w.Key == "X+"
				local inner = w.At + (if isX then w.Normal.X else w.Normal.Z) * (T / 2)
				local pos = if isX then V3(inner, y0, c) else V3(c, y0, inner)
				return Builder.facing(pos, w.Normal), w
			end
		end
		return nil, nil
	end
	for _, item in items do
		if item == "Machines" then
			local cf = take(5.4)
			if cf then
				for _, x in { -1.35, 1.35 } do
					part(m, "TicketMachine", V3(2.2, 5.6, 1.6), cf * CFrame.new(x, 2.8, -0.8), rgb(30, 90, 170), Enum.Material.SmoothPlastic, { Tags = { "MetroTicketMachine" } })
					decor(m, "TicketScreen", V3(1.6, 1.4, 0.1), cf * CFrame.new(x, 3.9, -1.65), rgb(120, 200, 255), Enum.Material.Neon)
				end
				signBoard(m, cf * CFrame.new(0, 6.6, -0.1), V3(5, 0.9, 0.1), "🎫 BILLETES", rgb(30, 90, 170))
			end
		elseif item == "Map" then
			local cf = take(7)
			if cf then
				local map = decor(m, "HallMap", V3(6.4, 3.8, 0.1), cf * CFrame.new(0, 4.4, -0.1), rgb(245, 245, 240))
				Builder.sign(map, "PLANO DEL METRO DE VALMAR\n🔴 L1 Poniente · Plaza Mayor · Levante · Playa Dorada\n🔵 L2 Norte · Plaza Mayor · San Roque · Puerto", Enum.NormalId.Front, DARK, rgb(245, 245, 240))
				decor(m, "HallMapFrame", V3(6.8, 4.2, 0.1), cf * CFrame.new(0, 4.4, -0.04), STEEL, Enum.Material.Metal)
			end
		elseif item == "Advert" then
			local cf = take(5.4)
			if cf then
				MetroDetails.advert(m, cf * CFrame.new(0, 4.6, -0.25), Vector2.new(4.6, 3))
			end
		elseif item == "Bench" then
			local cf = take(5.6)
			if cf then
				part(m, "HallBench", V3(5, 0.4, 1.6), cf * CFrame.new(0, 1.5, -1.1), rgb(140, 100, 64), Enum.Material.Wood)
				for _, x in { -2, 2 } do
					decor(m, "BenchLeg", V3(0.3, 1.3, 1.4), cf * CFrame.new(x, 0.65, -1.1), DARK, Enum.Material.Metal)
				end
			end
		end
	end
	-- Panel de próximos trenes colgado del techo, delante de las escaleras mecánicas
	for i, l in lines do
		local c = kTop - K.Dir * (Metro.LandingLength + 1.5)
		local off = V3(K.Dir.Z, 0, -K.Dir.X) * ((i - (#lines + 1) / 2) * 5)
		local pos = V3(c.X, y1 - 1.3, c.Z) + off
		local board = decor(m, "Departures", V3(4.6, 1.2, 0.3), Builder.facing(pos, -K.Dir), DARK)
		Builder.sign(board, "PRÓXIMO TREN", Enum.NormalId.Front, rgb(255, 200, 40), DARK)
		Builder.sign(board, "PRÓXIMO TREN", Enum.NormalId.Back, rgb(255, 200, 40), DARK)
		board:AddTag("MetroDisplay")
		board:SetAttribute("Line", l.Id)
		board:SetAttribute("Station", station.Id)
		decor(m, "BoardWire", V3(0.1, 0.8, 0.1), CFrame.new(pos + V3(0, 1, 0)), STEEL)
	end
	-- Cámara y papelera
	MetroDetails.camera(m, CFrame.new(V3(lo.X + 1, y1 - 0.6, lo.Z + 1)) * CFrame.Angles(0, math.rad(-135), 0))
	MetroDetails.bin(m, CFrame.new(V3(hi.X - 1.4, y0, hi.Z - 1.4)))
	return m
end

---------------------------------------------------------------------
-- Pozo de las escaleras mecánicas
---------------------------------------------------------------------

local function shaft(root: Instance, A: any, station: Metro.Station): Model
	local m = Builder.model("Escaleras_" .. station.Id, root)
	m:SetAttribute("PlaceName", "Metro · " .. station.Name)
	local K = A.Shaft
	local SH = Metro.Shaft
	local tan = K.Rise / K.Run
	local a = math.atan(tan)
	local L = K.Length
	local cf = Builder.facing(K.Top, K.Dir) -- x a la derecha bajando, -z hacia abajo
	local line = A.Line
	local Hv = SH.Headroom
	local half = K.Width / 2
	local xStairs = 0
	local xBal = SH.Stairs / 2 + SH.Balustrade / 2
	local xEsc = SH.Stairs / 2 + SH.Balustrade + SH.Escalator / 2
	local xWall = half - SH.Wall / 2

	-- Escalera fija en medio
	flight(m, K.Top + V3(0, 0, 0), K.Dir, K.Steps, K.Rise, K.Run, SH.Stairs, rgb(140, 138, 132), Enum.Material.Granite, rgb(245, 200, 30))
	local _ = xStairs
	-- Cajón de debajo (lo que se ve desde abajo) y techo inclinado
	local truss, len = sloped(cf, 0, 0, L, tan, -1.3)
	decor(m, "Truss", V3(K.Width - 0.2, 1.6, len), truss, rgb(70, 72, 78), Enum.Material.Metal)
	local roof = sloped(cf, 0, 0, L, tan, Hv * math.cos(a) + 0.3)
	part(m, "ShaftRoof", V3(K.Width, 0.6, len), roof, rgb(200, 198, 192), Enum.Material.Concrete)
	-- Escaleras mecánicas: la de la derecha baja y la de la izquierda sube
	for _, side in { 1, -1 } do
		local x = side * xEsc
		local goingDown = side > 0
		local slopeDir = (cf * V3(0, -tan, -1) - cf.Position).Unit -- hacia abajo por la pendiente
		local belt = walkable(m, "EscalatorBelt", V3(SH.Escalator, 1, len), (sloped(cf, x, 0, L, tan, -0.5)), {
			Tags = { "MetroEscalator" },
			Attributes = { Velocity = slopeDir * (if goingDown then SH.Speed else -SH.Speed), Down = goingDown },
		})
		local _b = belt
		-- Peldaños que se mueven (los anima MetroUI en cada cliente)
		local steps = Builder.model("EscaleraMecanica", m)
		local pitch = 1.3 -- en horizontal
		local count = math.floor(L / pitch)
		pitch = L / count
		steps:SetAttribute("Origin", cf * CFrame.new(x, 0, 0))
		steps:SetAttribute("Tan", tan)
		steps:SetAttribute("Pitch", pitch)
		steps:SetAttribute("Count", count)
		steps:SetAttribute("Speed", (if goingDown then 1 else -1) * SH.Speed * math.cos(a))
		steps:AddTag("MetroEscalatorSteps")
		local stepColor = rgb(92, 94, 100)
		for k = 0, count - 1 do
			local d = (k + 0.5) * pitch
			local p = decor(steps, "EscStep", V3(SH.Escalator - 0.3, pitch * tan, pitch), cf * CFrame.new(x, -d * tan - pitch * tan / 2 + 0.05, -d), stepColor, Enum.Material.DiamondPlate)
			p:SetAttribute("I", k)
		end
		-- Faldón y pasamanos del lado de la pared
		local skirt = sloped(cf, side * (xEsc + SH.Escalator / 2 - 0.1), 0, L, tan, 0.6)
		decor(m, "Skirt", V3(0.2, 1.2, len), skirt, rgb(60, 62, 68), Enum.Material.Metal)
		local rail = sloped(cf, side * (xEsc + SH.Escalator / 2 - 0.25), 0, L, tan, 3.3)
		decor(m, "EscHandrail", V3(0.35, 0.3, len), rail, DARK, Enum.Material.Fabric)
		-- Placas de peine arriba y abajo
		decor(m, "CombPlate", V3(SH.Escalator, 0.08, 1.4), cf * CFrame.new(x, 0.04, 0.7), STEEL, Enum.Material.DiamondPlate)
		decor(m, "CombPlate", V3(SH.Escalator, 0.08, 1.4), cf * CFrame.new(x, -L * tan + 0.04, -L - 0.7), STEEL, Enum.Material.DiamondPlate)
		-- Flechas en el suelo de arriba y de abajo (entrada verde, prohibido rojo)
		local enterTop = goingDown
		local top = signBoard(m, cf * CFrame.new(x, 0.1, 2.2) * CFrame.Angles(math.pi / 2, 0, 0), V3(SH.Escalator - 0.4, 1.2, 0.05), if enterTop then "⬇" else "⛔", if enterTop then rgb(40, 160, 70) else rgb(190, 40, 40))
		local _t = top
		local bottomSign = signBoard(m, cf * CFrame.new(x, -L * tan + 0.1, -L - 2.2) * CFrame.Angles(math.pi / 2, 0, 0), V3(SH.Escalator - 0.4, 1.2, 0.05), if enterTop then "⛔" else "⬆", if enterTop then rgb(190, 40, 40) else rgb(40, 160, 70))
		local _bs = bottomSign
	end
	-- Barandillas de cristal entre la escalera fija y las mecánicas (con su pasamanos negro)
	for _, side in { 1, -1 } do
		local bcf = sloped(cf, side * xBal, 0, L, tan, 1.7)
		part(m, "Balustrade", V3(SH.Balustrade, 3.4, len), bcf, rgb(190, 215, 230), Enum.Material.Glass, { Transparency = 0.55 })
		decor(m, "BalHandrail", V3(SH.Balustrade + 0.2, 0.3, len), (sloped(cf, side * xBal, 0, L, tan, 3.5)), DARK, Enum.Material.Fabric)
		decor(m, "BalLight", V3(0.1, 0.1, len - 1), (sloped(cf, side * xBal, 0, L, tan, 0.25)), rgb(255, 250, 230), Enum.Material.Neon)
	end
	-- Paredes: tramos verticales escalonados (sus bordes quedan tapados por el techo y el suelo)
	local seg = 10
	local n = math.max(1, math.ceil(L / seg))
	local segLen = L / n
	for i = 0, n - 1 do
		local d0, d1 = i * segLen, (i + 1) * segLen
		local yTop = -d0 * tan + Hv + 1
		local yBot = -d1 * tan - 3
		if not K.Ceiling then
			for _, side in { -1, 1 } do
				part(m, "ShaftWall", V3(SH.Wall, yTop - yBot, segLen + 0.02), cf * CFrame.new(side * xWall, (yTop + yBot) / 2, -(d0 + d1) / 2), TILE, Enum.Material.Marble)
			end
		end
		-- Anuncios en las paredes (uno sí y otro no, a los dos lados)
		if i % 2 == 1 then
			local side = if i % 4 == 1 then 1 else -1
			local y = -((d0 + d1) / 2) * tan + 4.2
			local adCf = cf * CFrame.new(side * (xWall - SH.Wall / 2 - 0.15), y, -(d0 + d1) / 2) * CFrame.Angles(0, if side > 0 then math.pi / 2 else -math.pi / 2, 0)
			MetroDetails.advert(m, adCf, Vector2.new(4.4, 2.8))
		end
	end
	-- Bajando del techo (Plaza Mayor): paredes inclinadas, que por debajo se ven desde el vestíbulo
	if K.Ceiling then
		local wallH = Hv + 2.2
		for _, side in { -1, 1 } do
			-- (arriba se alarga un poco hacia el vestíbulo para no dejar rendija)
			local wcf, wlen = sloped(cf, side * xWall, -2, L, tan, wallH / 2 - 1.6)
			part(m, "ShaftWall", V3(SH.Wall, wallH, wlen), wcf, TILE, Enum.Material.Marble)
		end
	end
	-- Franja de color de la línea en las paredes
	for _, side in { -1, 1 } do
		decor(m, "ShaftBand", V3(0.06, 0.8, len), (sloped(cf, side * (xWall - SH.Wall / 2 - 0.03), 0, L, tan, 6.6)), line.Color)
	end
	-- Luces en el techo (tiras de neón; unas pocas con luz de verdad)
	local count = math.max(2, math.floor(L / 14))
	for i = 0, count - 1 do
		local d = (i + 0.5) * L / count
		local lampCf = sloped(cf, 0, d - 2.5, d + 2.5, tan, Hv * math.cos(a) - 0.05)
		local lamp = decor(m, "ShaftLamp", V3(1.2, 0.12, 5), lampCf, rgb(250, 250, 255), Enum.Material.Neon)
		if i % 2 == 0 and i < 8 then
			surfaceLight(lamp, Enum.NormalId.Bottom, 20, 1.2)
		end
	end
	-- Carteles: arriba "↓ ANDENES", abajo "↑ SALIDA"
	signBoard(m, cf * CFrame.new(0, Hv - 1.2, 0.4) * CFrame.Angles(0, math.pi, 0), V3(8, 1.2, 0.15), "↓ " .. line.Name .. " · ANDENES", line.Color)
	signBoard(m, cf * CFrame.new(0, -L * tan + Hv - 1.2, -L - 0.4), V3(8, 1.2, 0.15), "↑ SALIDA · CALLE · " .. string.upper(station.Name), DARK)
	return m
end

---------------------------------------------------------------------

-- Todas las bocas. world: la ciudad (para abrir el hueco de cada escalera en el suelo de la calle;
-- skip: lo que no se toca, el propio metro)
function MetroAccess.build(root: Instance, world: Instance?, skip: Instance): { Model }
	local list, holes = {}, {}
	for id, station in Metro.Stations do
		local A = Metro.access(id)
		local m = Builder.model("Acceso_" .. id, root)
		m:SetAttribute("Station", id)
		local _, lo, hi = mouth(m, A, station)
		table.insert(holes, { lo, hi })
		hall(m, A, station)
		shaft(m, A, station)
		table.insert(list, m)
	end
	if world then
		cutGround(world, skip, holes)
	end
	return list
end

-- Cajas (CFrame, tamaño) de roca que hay que vaciar para cada boca (TerrainBuilder)
function MetroAccess.carveBoxes(stationId: string): { { any } }
	local A = Metro.access(stationId)
	local boxes = {}
	local S, K = A.Stair, A.Shaft
	local W = S.Width + 2
	-- Escalera: al aire libre hasta arriba; la parte cubierta, hasta el techo del vestíbulo
	local function along(p: Vector3, dir: Vector3, d0: number, d1: number, width: number, ya: number, yb: number)
		local c = p + dir * ((d0 + d1) / 2)
		table.insert(boxes, { Builder.facing(V3(c.X, (ya + yb) / 2, c.Z), dir), V3(width, yb - ya, d1 - d0) })
	end
	along(S.Top, S.Dir, -1, S.Open, W, Metro.HallY - 2, 10)
	along(S.Top, S.Dir, S.Open, S.Length + 0.5, W, Metro.HallY - 2, Metro.HallY + Metro.HallHeight + 0.5)
	local lo, hi = A.Hall.Min, A.Hall.Max
	table.insert(boxes, { CFrame.new((lo.X + hi.X) / 2, (Metro.HallY - 2 + hi.Y + 0.5) / 2, (lo.Z + hi.Z) / 2), V3(hi.X - lo.X + 1.4, hi.Y + 0.5 - (Metro.HallY - 2), hi.Z - lo.Z + 1.4) })
	-- Pozo: hasta donde su techo baja de la arena del fondo (-24)
	local tan = K.Rise / K.Run
	local deep = math.min(K.Length, (Metro.HallY + Metro.Shaft.Headroom + 1 + 24) / tan + 2)
	local ya = math.max(K.Bottom.Y, Metro.HallY - deep * tan) - 2
	along(K.Top, K.Dir, -1, deep, K.Width + 1.5, ya, Metro.HallY + Metro.HallHeight + 0.5)
	return boxes
end

-- ¿Cae (x, z) sobre la boca de alguna estación? (con margen: ahí no se planta nada)
local blockRects: { { number } }? = nil
function MetroAccess.blocked(x: number, z: number): boolean
	if not blockRects then
		local list = {}
		for id in Metro.Stations do
			local S = Metro.access(id).Stair
			local a = S.Top - S.Dir * 14
			local b = S.Top + S.Dir * (S.Length + 6)
			local r = S.Width / 2 + 14
			table.insert(list, { math.min(a.X, b.X) - r, math.max(a.X, b.X) + r, math.min(a.Z, b.Z) - r, math.max(a.Z, b.Z) + r })
		end
		blockRects = list
	end
	for _, r in blockRects :: { { number } } do
		if x > r[1] and x < r[2] and z > r[3] and z < r[4] then
			return true
		end
	end
	return false
end

return MetroAccess
