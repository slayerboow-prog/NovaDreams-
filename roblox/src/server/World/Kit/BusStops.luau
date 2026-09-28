-- BusStops: las paradas de la red de autobuses urbanos (shared/BusLines).
--
-- Cada parada es una marquesina en la acera de la derecha de su calle:
--   * techo, cristal trasero, banco (se puede sentar), panel de anuncios a un lado
--   * plano de las líneas que paran allí (con "estás aquí") pegado al cristal
--   * panel de llegadas (EtaBoard): lo pinta el cliente con luces ámbar (Controllers/BusBoards)
--   * poste con la señal de BUS, las líneas (con su color) y el nombre de la parada (BusStopSign,
--     etiqueta "BusStop": ahí pone el servidor el cartel para subir y los tiempos de llegada)
--   * "BUS" pintado en el carril, donde para el autobús
-- La marquesina se corre un poco por la acera si allí hay una farola, un árbol, una papelera…
-- Todo lo decorativo va sin colisión y casi todo sin sombra (pocas piezas por parada).
-- Se construye al final de TownBuilder y no usa números al azar (no mueve nada del resto del mapa).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local BusLines = require(ReplicatedStorage.Shared.BusLines)

local BusStops = {}

local rgb = Color3.fromRGB
local WALK = 1 -- altura de las aceras (Kit/Street y Kit/Roads)
local METAL = rgb(64, 70, 78)
local GLASS = Palette.Street.Glass or rgb(160, 196, 214)
local SIGN_BLUE = rgb(24, 92, 190)

-- Anuncios de las marquesinas (se reparten por orden, sin azar)
local ADS = {
	{ "🏖️ PLAYA DORADA\nLa L1 te deja en la arena", rgb(20, 120, 200) },
	{ "🍔 BURGER VALMAR\n2×1 los martes", rgb(210, 60, 40) },
	{ "🎓 CAMPUS VALMAR\nMatrícula abierta", rgb(150, 30, 40) },
	{ "🚇 METRO + BUS\nCombina y llega antes", rgb(40, 110, 215) },
	{ "🎡 PARQUE DE ATRACCIONES\n¡Nueva montaña rusa!", rgb(160, 90, 220) },
	{ "🛒 SUPERMERCADO\nFruta fresca cada día", rgb(40, 150, 80) },
	{ "🎬 CINE VALMAR\nEstrenos cada viernes", rgb(30, 30, 40) },
	{ "💪 GIMNASIO VALMAR\nPrimer mes gratis", rgb(230, 120, 20) },
}

---------------------------------------------------------------------
-- Calles (las mismas, y en el mismo orden, que ReplicatedStorage.Ambient.Roads)
---------------------------------------------------------------------

function BusStops.roads(): { BusLines.Road }
	local Region = require(script.Parent.Parent.Region)
	local Roads = require(script.Parent.Roads)
	local list: { BusLines.Road } = {}
	for _, road in Region.roads() do
		local a = if road.Axis == "X" then Vector3.new(road.From, 0, road.At) else Vector3.new(road.At, 0, road.From)
		local b = if road.Axis == "X" then Vector3.new(road.To, 0, road.At) else Vector3.new(road.At, 0, road.To)
		table.insert(list, { A = a, B = b, Width = 24 })
	end
	for _, segment in Roads.segments() do
		table.insert(list, { A = segment.A, B = segment.B, Width = Roads.Kinds[segment.Kind].Road, Kind = segment.Kind })
	end
	return list
end

---------------------------------------------------------------------
-- Huecos libres en la acera
---------------------------------------------------------------------

type Box = { Min: Vector3, Max: Vector3 }

local function partBox(part: BasePart): Box
	local cf, size = part.CFrame, part.Size
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local h = Vector3.new(
		math.abs(r.X) * size.X / 2 + math.abs(u.X) * size.Y / 2 + math.abs(l.X) * size.Z / 2,
		math.abs(r.Y) * size.X / 2 + math.abs(u.Y) * size.Y / 2 + math.abs(l.Y) * size.Z / 2,
		math.abs(r.Z) * size.X / 2 + math.abs(u.Z) * size.Y / 2 + math.abs(l.Z) * size.Z / 2
	)
	return { Min = cf.Position - h, Max = cf.Position + h }
end

-- Caja (en el mundo) de un trozo de la marquesina dado en sus coordenadas
local function localBox(cf: CFrame, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number): Box
	local lo, hi = nil, nil
	for _, x in { x0, x1 } do
		for _, y in { y0, y1 } do
			for _, z in { z0, z1 } do
				local p = cf * Vector3.new(x, y, z)
				lo = if lo then Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z)) else p
				hi = if hi then Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z)) else p
			end
		end
	end
	return { Min = lo :: Vector3, Max = hi :: Vector3 }
end

local function overlaps(a: Box, b: Box): boolean
	return a.Min.X < b.Max.X and a.Max.X > b.Min.X and a.Min.Y < b.Max.Y and a.Max.Y > b.Min.Y and a.Min.Z < b.Max.Z and a.Max.Z > b.Min.Z
end

-- Lo que hay en la acera cerca de cada parada (farolas, árboles, bancos, papeleras, carteles…)
local function obstacles(world: Instance, plan: BusLines.Plan): { [string]: { Box } }
	local CELL = 100
	local grid: { [string]: { string } } = {}
	for _, id in plan.Order do
		local p = plan.Stops[id].Shelter
		local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
		grid[key] = grid[key] or {}
		table.insert(grid[key], id)
	end
	local found: { [string]: { Box } } = {}
	for _, id in plan.Order do
		found[id] = {}
	end
	local REACH = 50 -- lo lejos que se puede correr la marquesina (y un poco más)
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") and (part.Transparency or 0) < 0.95 and part.CFrame and part.Size then
			local box = partBox(part)
			-- Lo que está a ras de suelo (aceras, bordillos, pasos de cebra) o muy alto no estorba
			if box.Max.Y > WALK + 0.25 and box.Min.Y < WALK + 11 and (box.Max.X - box.Min.X) < 400 and (box.Max.Z - box.Min.Z) < 400 then
				local seen: { [string]: boolean } = {}
				for cx = math.floor((box.Min.X - REACH) / CELL), math.floor((box.Max.X + REACH) / CELL) do
					for cz = math.floor((box.Min.Z - REACH) / CELL), math.floor((box.Max.Z + REACH) / CELL) do
						for _, id in grid[cx .. ":" .. cz] or {} do
							local p = plan.Stops[id].Shelter
							if not seen[id] and box.Max.X > p.X - REACH and box.Min.X < p.X + REACH and box.Max.Z > p.Z - REACH and box.Min.Z < p.Z + REACH then
								seen[id] = true
								table.insert(found[id], box)
							end
						end
					end
				end
			end
		end
	end
	return found
end

---------------------------------------------------------------------
-- Carteles
---------------------------------------------------------------------

local function surface(part: BasePart, face: Enum.NormalId, canvas: Vector2): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = canvas
	gui.LightInfluence = 0
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

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- Señal del poste: BUS, las líneas (cuadros de color) y el nombre de la parada
local function poleSign(sign: BasePart, info: BusLines.StopInfo)
	for _, face in { Enum.NormalId.Right, Enum.NormalId.Left } do
		local gui = surface(sign, face, Vector2.new(280, 380))
		frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(245, 247, 250) })
		local head = frame(gui, { Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = SIGN_BLUE })
		text(head, { Size = UDim2.fromScale(1, 1), Text = "🚏 BUS", FontFace = Font.fromEnum(Enum.Font.GothamBlack) })
		local row = frame(gui, { Position = UDim2.fromOffset(10, 132), Size = UDim2.new(1, -20, 0, 90), BackgroundTransparency = 1 })
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, 8)
		layout.Parent = row
		for _, lineId in info.Lines do
			local def = BusLines.byId[lineId]
			local badge = frame(row, { Size = UDim2.fromOffset(78, 90), BackgroundColor3 = BusLines.color(def) })
			corner(badge, 12)
			text(badge, { Size = UDim2.fromScale(1, 1), Text = lineId, FontFace = Font.fromEnum(Enum.Font.GothamBlack) })
		end
		text(gui, { Position = UDim2.fromOffset(10, 234), Size = UDim2.new(1, -20, 0, 136), Text = info.Name, TextColor3 = rgb(20, 30, 50) })
	end
end

-- Plano de las líneas que paran aquí: una fila por línea con sus paradas y "estás aquí"
local function lineMap(poster: BasePart, info: BusLines.StopInfo, plan: BusLines.Plan)
	local gui = surface(poster, Enum.NormalId.Front, Vector2.new(560, 400))
	frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(250, 250, 246) })
	text(gui, { Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 40), Text = "Líneas en esta parada", TextColor3 = rgb(30, 40, 60), TextXAlignment = Enum.TextXAlignment.Left })
	local rowHeight = math.min(110, math.floor(340 / math.max(1, #info.Lines)))
	for i, lineId in info.Lines do
		local def = BusLines.byId[lineId]
		local color = BusLines.color(def)
		local linePlan: BusLines.LinePlan? = nil
		for _, l in plan.Lines do
			if l.Id == lineId then
				linePlan = l
			end
		end
		if not linePlan then
			continue
		end
		local row = frame(gui, { Position = UDim2.fromOffset(12, 52 + (i - 1) * rowHeight), Size = UDim2.new(1, -24, 0, rowHeight - 8), BackgroundTransparency = 1 })
		local badge = frame(row, { Size = UDim2.new(0, 64, 0.5, 0), BackgroundColor3 = color })
		corner(badge, 8)
		text(badge, { Size = UDim2.fromScale(1, 1), Text = lineId, FontFace = Font.fromEnum(Enum.Font.GothamBlack) })
		local here, count = 1, #linePlan.Stops
		for k, s in linePlan.Stops do
			if s.Id == info.Id then
				here = k
			end
		end
		local nextStop = plan.Stops[linePlan.Stops[here % count + 1].Id]
		local title = if def.Out == def.Back then ("%s · siguiente: %s"):format(def.Name, nextStop.Name) else ("%s ⇄ %s · siguiente: %s"):format(def.Back, def.Out, nextStop.Name)
		text(row, { Position = UDim2.fromOffset(74, 0), Size = UDim2.new(1, -74, 0.5, 0), Text = title, TextColor3 = rgb(30, 40, 60), TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.fromEnum(Enum.Font.Gotham) })
		-- La línea con un punto por parada (la de aquí, grande y blanca)
		local bar = frame(row, { Position = UDim2.new(0, 10, 0.72, -3), Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = color })
		for k = 1, count do
			local isHere = k == here
			local d = if isHere then 22 else 12
			local dot = frame(bar, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((k - 1) / math.max(1, count - 1), 0, 0.5, 0),
				Size = UDim2.fromOffset(d, d),
				BackgroundColor3 = if isHere then Color3.new(1, 1, 1) else color,
			})
			corner(dot, d)
			if isHere then
				local stroke = Instance.new("UIStroke")
				stroke.Color = color
				stroke.Thickness = 4
				stroke.Parent = dot
			end
		end
		text(row, { Position = UDim2.new(0, 10, 0.8, 4), Size = UDim2.new(1, -20, 0.2, 0), Text = "● Estás aquí: " .. info.Name, TextColor3 = rgb(90, 96, 110), TextXAlignment = Enum.TextXAlignment.Left, FontFace = Font.fromEnum(Enum.Font.Gotham) })
	end
end

---------------------------------------------------------------------
-- Marquesina
---------------------------------------------------------------------

-- cf: a ras de acera, mirando hacia la calzada. side = +1/-1: hacia dónde va el autobús (X local)
local function shelter(parent: Instance, cf: CFrame, side: number, info: BusLines.StopInfo, plan: BusLines.Plan, index: number, stopPoint: Vector3): Model
	local m = Builder.model("ParadaBus", parent)
	m:SetAttribute("StopId", info.Id)
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local at = function(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local firstColor = BusLines.color(BusLines.byId[info.Lines[1]])
	-- Techo (da sombra) con una franja del color de la línea
	Builder.decor({ Name = "Roof", Size = Vector3.new(12, 0.35, 4.6), CFrame = at(0, 8.3, 0.2), Color = METAL, Material = Enum.Material.Metal, CastShadow = true, Parent = m })
	Builder.decor({ Name = "RoofStripe", Size = Vector3.new(12, 0.45, 0.12), CFrame = at(0, 8.25, -2.15), Color = firstColor, Material = Enum.Material.SmoothPlastic, Parent = m })
	-- Cristal del fondo (sólido: no se atraviesa) y dos postes
	Builder.part({ Name = "BackGlass", Size = Vector3.new(11.6, 6.6, 0.2), CFrame = at(0, 4.55, 2.2), Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.55, CastShadow = false, Parent = m })
	for _, x in { -5.85, 5.85 } do
		Builder.decor({ Name = "Post", Size = Vector3.new(0.3, 7.95, 0.3), CFrame = at(x, 4.25, 2.2), Color = METAL, Material = Enum.Material.Metal, Parent = m })
	end
	-- Banco (se puede sentar)
	Builder.part({ ClassName = "Seat", Name = "Seat", Size = Vector3.new(5.4, 1.4, 1.3), CFrame = at(-side * 1.2, 0.7, 1.35), Color = METAL, Material = Enum.Material.Metal, CanTouch = false, CastShadow = false, Parent = m })
	-- Panel de anuncios (en el lado hacia donde va el autobús), iluminado por las dos caras
	local ad = ADS[(index - 1) % #ADS + 1]
	local panel = Builder.part({ Name = "AdPanel", Size = Vector3.new(0.3, 6, 3.6), CFrame = at(side * 5.5, 4.4, 0.2), Color = rgb(240, 240, 240), CastShadow = false, Parent = m })
	Builder.sign(panel, ad[1], Enum.NormalId.Right, Color3.new(1, 1, 1), ad[2])
	Builder.sign(panel, ad[1], Enum.NormalId.Left, Color3.new(1, 1, 1), ad[2])
	-- Plano de las líneas, pegado al cristal (se lee desde el banco y desde la acera)
	local poster = Builder.decor({ Name = "LineMap", Size = Vector3.new(5.6, 4, 0.08), CFrame = at(-side * 2.6, 5.6, 2.06), Color = rgb(250, 250, 246), Parent = m })
	lineMap(poster, info, plan)
	-- Panel de llegadas colgado del techo (lo pinta el cliente: Controllers/BusBoards)
	Builder.decor({ Name = "EtaBoard", Size = Vector3.new(5.4, 1.5, 0.3), CFrame = at(side * 1.6, 7.35, -1.4), Color = rgb(12, 12, 14), Material = Enum.Material.Metal, Parent = m })
	-- Poste con la señal (junto al bordillo, hacia donde para el morro del autobús)
	Builder.decor({ Name = "SignPole", Size = Vector3.new(0.3, 10.4, 0.3), CFrame = at(side * 7, 5.2, -1.7), Color = METAL, Material = Enum.Material.Metal, Parent = m })
	local sign = Builder.part({
		Name = "BusStopSign",
		Size = Vector3.new(0.25, 3.8, 2.8),
		CFrame = at(side * 7, 9, -1.7),
		Color = rgb(245, 247, 250),
		CanCollide = false,
		CastShadow = false,
		Tags = { "BusStop" },
		Attributes = { StopId = info.Id, StopName = info.Name, Lines = table.concat(info.Lines, ","), StopPoint = stopPoint },
		Parent = m,
	})
	poleSign(sign, info)
	return m
end

-- "BUS" pintado en el carril, donde para el autobús
local function laneMark(parent: Instance, info: BusLines.StopInfo, p: Vector3)
	local mark = Builder.decor({
		Name = "BusLaneMark",
		Size = Vector3.new(7, 0.05, 16),
		CFrame = Builder.facing(Vector3.new(p.X, 0.43, p.Z), info.Along),
		Transparency = 1,
		Parent = parent,
	})
	local label = Builder.sign(mark, "BUS", Enum.NormalId.Top, rgb(250, 200, 40))
	label.Rotation = 180
end

-- Coches aparcados encima del carril por donde pasa el autobús: se quitan
local function clearLanes(world: Instance, plan: BusLines.Plan): number
	local removed = 0
	for _, model in world:GetDescendants() do
		if model:IsA("Model") and model.Name == "ParkedCar" and model.Parent then
			local ok, cf = pcall(function()
				return model:GetPivot()
			end)
			if ok then
				local p = Vector3.new(cf.Position.X, 0, cf.Position.Z)
				local blocked = false
				for _, line in plan.Lines do
					local route = line.Route
					for i, a in route do
						local b = route[if i < #route then i + 1 else 1]
						local fa, fb = Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z)
						local ab = fb - fa
						local len2 = ab:Dot(ab)
						local t = if len2 > 0 then math.clamp((p - fa):Dot(ab) / len2, 0, 1) else 0
						if (fa + ab * t - p).Magnitude < 7.5 then
							blocked = true
							break
						end
					end
					if blocked then
						break
					end
				end
				if blocked then
					model:Destroy()
					removed += 1
				end
			end
		end
	end
	return removed
end

-- Construye todas las paradas. Devuelve el plan (por si quien llama lo quiere usar).
function BusStops.build(world: Instance, roads: { BusLines.Road }?): BusLines.Plan
	local plan = BusLines.plan(roads or BusStops.roads())
	local folder = Builder.model("ParadasBus", world)
	local near = obstacles(world, plan)
	for index, id in plan.Order do
		local info = plan.Stops[id]
		local base = Builder.facing(Vector3.new(info.Shelter.X, WALK, info.Shelter.Z), -info.Right)
		local side = if base.RightVector:Dot(info.Along) >= 0 then 1 else -1
		-- Se prueba en su sitio y, si algo estorba, un poco antes o después por la acera
		local chosen, moved = base, 0
		for _, shift in { 0, 6, -6, 12, -12, 18, -18, 24, -24, 30, -30, 36, -36 } do
			local cf = base * CFrame.new(side * shift, 0, 0)
			local body = localBox(cf, -6.2, 6.2, 0.25, 9, -2.3, 2.4)
			local pole = localBox(cf, side * 7 - 0.7, side * 7 + 0.7, 0.25, 11, -2.4, -1)
			local clear = true
			for _, box in near[id] do
				if overlaps(box, body) or overlaps(box, pole) then
					clear = false
					break
				end
			end
			if clear then
				chosen, moved = cf, shift
				break
			end
		end
		-- El autobús para con la puerta delantera a la altura de la marquesina
		local stopPoint = info.Center + info.Along * moved + info.Right * BusLines.Lane
		shelter(folder, chosen, side, info, plan, index, Vector3.new(stopPoint.X, 0.4, stopPoint.Z))
		laneMark(folder, info, stopPoint)
	end
	clearLanes(world, plan)
	return plan
end

return BusStops
