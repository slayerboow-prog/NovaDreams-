-- RailKit: el tren de Cercanías de Valmar (datos en Shared/Rail.luau; lo mueve RailService).
--
--   * Vía en superficie: balasto, traviesas y dos carriles, en trozos largos (pocas piezas). Sobre el
--     río, un puente con barandillas y pilares.
--   * Pasos a nivel donde la vía cruza una calle: el asfalto y las aceras siguen enteros (los carriles
--     van encastrados, sin chocar), con cuatro barreras (tag RailCrossing: las mueve el cliente,
--     Controllers/RailUI) y postes con la cruz de San Andrés y dos luces rojas que parpadean.
--   * Estaciones: andén a la altura del tren, línea amarilla, marquesina con bancos, máquina de
--     billetes (RailTicketMachine), panel de salidas (RailDisplay), carteles con el nombre, farolas,
--     botones de subir al tren en el borde (RailBoard), sitio donde se baja (RailAlight) y una rampa
--     (y en Levante y Campus un camino) que baja hasta la acera de la calle de al lado.
--   * Tren: 3 coches (los del metro, con los colores de Cercanías: MetroKit.car), tag RailTrain.
--     Las soldaduras se hacen al arrancar el servidor (MetroKit.weldCar), como en el metro.
-- Se construye al final y sin azar: antes quita lo que haya quedado encima de la vía (árboles del
-- campo, alguna farola de la acera justo donde cruza).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local MetroKit = require(script.Parent.MetroKit)
local Props = require(script.Parent.Props)
local Roads = require(script.Parent.Roads)
local Street = require(script.Parent.Street)
local Region = require(script.Parent.Parent.Region)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Rail = require(ReplicatedStorage.Shared.Rail)

local RailKit = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local BALLAST = rgb(128, 122, 114)
local SLEEPER = rgb(104, 96, 88)
local STEEL = rgb(150, 154, 160)
local CONCRETE = rgb(196, 192, 184)
local DARK = rgb(40, 42, 48)
local YELLOW = rgb(245, 200, 30)
local RED = Rail.Line.Color
local WHITE = rgb(240, 240, 236)

local SLEEPER_STEP = 5 -- una traviesa cada 5 studs
local CHUNK = 80 -- largo máximo de cada trozo de balasto y de carril
local BED_TOP = 0.1
local BED_BOTTOM = -1.5 -- (el campo está en Y = -1: el balasto se hunde un poco)
local POST_OFFSET = 7 -- de la vía a los postes del paso a nivel

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

local function marker(parent: Instance, name: string, cf: CFrame, tag: string, attrs: { [string]: any }, size: Vector3?): BasePart
	return Builder.part({
		Name = name,
		Size = size or V3(4, 5, 2),
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

local function flat(v: Vector3): Vector3
	return V3(v.X, 0, v.Z)
end

-- CFrame a la altura y en el punto p, mirando a lo largo de dir (horizontal)
local function along(p: Vector3, dir: Vector3, y: number): CFrame
	return Builder.facing(V3(p.X, y, p.Z), flat(dir))
end

---------------------------------------------------------------------
-- Calles que cruza la vía (pasos a nivel)
---------------------------------------------------------------------
export type Crossing = {
	S0: number, -- donde la vía entra en la huella de la calle (acera incluida)
	S1: number, -- donde sale
	S: number, -- en medio
	Name: string,
	Dir: Vector3, -- dirección de la calle
	Normal: Vector3, -- perpendicular a la calle (en horizontal)
	Origin: Vector3, -- un punto del eje de la calle
	HalfRoad: number, -- media calzada
	HalfTotal: number, -- media calle con las aceras
}

type Footprint = { Name: string, A: Vector3, B: Vector3, HalfRoad: number, HalfTotal: number }

local footprintCache: { Footprint }? = nil
local function footprints(): { Footprint }
	if footprintCache then
		return footprintCache
	end
	local list: { Footprint } = {}
	for _, s in Roads.segments() do
		local kind = Roads.Kinds[s.Kind]
		table.insert(list, { Name = s.Name, A = flat(s.A), B = flat(s.B), HalfRoad = kind.Road / 2, HalfTotal = kind.Road / 2 + kind.Walk })
	end
	for _, road in Region.roads() do
		local a = if road.Axis == "X" then V3(road.From, 0, road.At) else V3(road.At, 0, road.From)
		local b = if road.Axis == "X" then V3(road.To, 0, road.At) else V3(road.At, 0, road.To)
		table.insert(list, { Name = ("Calle %s=%d"):format(if road.Axis == "X" then "Z" else "X", road.At), A = a, B = b, HalfRoad = Street.ROAD_WIDTH / 2, HalfTotal = Street.HALF })
	end
	footprintCache = list
	return list
end

-- ¿En qué calle está el punto (en horizontal)? Devuelve la huella y la distancia al eje
local function roadAt(p: Vector3): (Footprint?, number)
	for _, f in footprints() do
		local ab = f.B - f.A
		local len = ab.Magnitude
		if len > 0 then
			local dir = ab / len
			local rel = flat(p) - f.A
			local u = rel:Dot(dir)
			if u >= -0.01 and u <= len + 0.01 then
				local v = math.abs(rel.X * dir.Z - rel.Z * dir.X)
				if v <= f.HalfTotal then
					return f, v
				end
			end
		end
	end
	return nil, 0
end

local crossingCache: { Crossing }? = nil

-- Los pasos a nivel: tramos del recorrido que pisan una calle (la usan RailKit, RailService y las pruebas)
function RailKit.crossings(): { Crossing }
	if crossingCache then
		return crossingCache
	end
	local points, _, length = Rail.path()
	local list: { Crossing } = {}
	local current: Footprint? = nil
	local start = 0
	local STEP = 0.5
	local s = 0
	while s <= length + STEP do
		local p = Rail.sample(points, math.min(s, length))
		local f = if s <= length then roadAt(p) else nil
		if f ~= current then
			if current then
				local dir = (current.B - current.A).Unit
				table.insert(list, {
					S0 = start,
					S1 = s - STEP,
					S = (start + s - STEP) / 2,
					Name = current.Name,
					Dir = dir,
					Normal = V3(-dir.Z, 0, dir.X),
					Origin = current.A,
					HalfRoad = current.HalfRoad,
					HalfTotal = current.HalfTotal,
				})
			end
			current = f
			start = s
		end
		s += STEP
	end
	crossingCache = list
	return list
end

-- ¿Cae la distancia s del recorrido en un paso a nivel? (con margen)
local function inCrossing(s: number, margin: number): Crossing?
	for _, c in RailKit.crossings() do
		if s >= c.S0 - margin and s <= c.S1 + margin then
			return c
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Vía
---------------------------------------------------------------------

-- Trozos rectos del recorrido entre s0 y s1 (partidos en los puntos del recorrido y cada CHUNK studs)
local function pieces(s0: number, s1: number, maxLen: number): { { A: Vector3, B: Vector3 } }
	local points = Rail.path()
	local out = {}
	local walked = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local len = (b - a).Magnitude
		local lo, hi = math.max(s0, walked), math.min(s1, walked + len)
		if hi - lo > 0.05 then
			local n = math.max(1, math.ceil((hi - lo) / maxLen))
			for k = 0, n - 1 do
				local u0 = lo + (hi - lo) * k / n
				local u1 = lo + (hi - lo) * (k + 1) / n
				table.insert(out, { A = a:Lerp(b, (u0 - walked) / len), B = a:Lerp(b, (u1 - walked) / len) })
			end
		end
		walked += len
	end
	return out
end

local function overWater(p: Vector3): boolean
	return CityPlan.riverDistance(p.X, p.Z) < CityPlan.River.Width / 2 + 6
end

-- Tramos del recorrido que no son paso a nivel: { { s0, s1 } }
local function openSpans(): { { number } }
	local _, _, length = Rail.path()
	local spans = {}
	local from = 0
	for _, c in RailKit.crossings() do
		table.insert(spans, { from, c.S0 - 1 })
		from = c.S1 + 1
	end
	table.insert(spans, { from, length })
	return spans
end

local function buildTrack(parent: Instance)
	local m = Builder.model("Via", parent)
	local points, _, length = Rail.path()
	local half = Rail.Gauge / 2
	for _, span in openSpans() do
		for _, piece in pieces(span[1], span[2], CHUNK) do
			local a, b = piece.A, piece.B
			local len = (b - a).Magnitude
			local mid = (a + b) / 2
			local dir = (b - a).Unit
			-- Balasto (un poco más largo: tapa la rendija de las curvas)
			part(m, "Ballast", V3(9, BED_TOP - BED_BOTTOM, len + 1), along(mid, dir, (BED_TOP + BED_BOTTOM) / 2), BALLAST, Enum.Material.Slate, { CastShadow = false })
			for _, side in { -1, 1 } do
				local off = V3(-dir.Z, 0, dir.X) * side * half
				decor(m, "Rail", V3(0.4, 0.45, len + 0.3), along(mid + off, dir, Rail.RailTop - 0.225), STEEL, Enum.Material.Metal)
			end
		end
	end
	-- Traviesas (fuera de los pasos a nivel)
	local s = SLEEPER_STEP / 2
	while s < length do
		if not inCrossing(s, 1.5) then
			local p, t = Rail.sample(points, s)
			decor(m, "Sleeper", V3(7.2, 0.3, 1.2), along(p, t, BED_TOP + 0.15), SLEEPER, Enum.Material.Concrete)
		end
		s += SLEEPER_STEP
	end
	-- Topes al final de la vía
	for _, e in { { 0, 1 }, { length, -1 } } do
		local p, t = Rail.sample(points, e[1])
		local cf = along(p, t * e[2], 0) -- (mirando hacia dentro de la vía)
		part(m, "BufferStop", V3(8, 3, 2), cf * CFrame.new(0, 1.6, 1), RED, Enum.Material.Metal)
		decor(m, "BufferStripe", V3(8.1, 0.6, 2.1), cf * CFrame.new(0, 2.4, 1), WHITE)
		decor(m, "BufferLamp", V3(0.8, 0.8, 0.3), cf * CFrame.new(0, 3.5, 0.5), rgb(255, 40, 40), Enum.Material.Neon)
	end
	-- Puente sobre el río: tablero, barandillas y pilares (cada 10 studs se mira si hay agua debajo)
	local bridge: Model? = nil
	local s2 = 0
	while s2 < length do
		local p, t = Rail.sample(points, s2 + 5)
		if overWater(p) then
			bridge = bridge or Builder.model("PuenteCercanias", parent)
			local b = bridge :: Model
			local cf = along(p, t, 0)
			part(b, "Deck", V3(12, 1.2, 10.4), cf * CFrame.new(0, BED_BOTTOM - 0.6, 0), CONCRETE, Enum.Material.Concrete)
			for _, side in { -1, 1 } do
				part(b, "Parapet", V3(0.5, 3.2, 10.4), cf * CFrame.new(side * 6.25, BED_BOTTOM + 1, 0), CONCRETE, Enum.Material.Concrete)
				decor(b, "Handrail", V3(0.3, 0.3, 10.4), cf * CFrame.new(side * 6.25, BED_BOTTOM + 2.8, 0), STEEL, Enum.Material.Metal)
			end
			if math.floor(s2 / 10) % 3 == 0 then
				part(b, "Pier", V3(6, 14, 3), cf * CFrame.new(0, BED_BOTTOM - 8.2, 0), CONCRETE, Enum.Material.Concrete)
			end
		end
		s2 += 10
	end
	return m
end

---------------------------------------------------------------------
-- Pasos a nivel
---------------------------------------------------------------------

-- Punto a un lado de la vía (lateral l) justo fuera de la calle, del lado sigma (+1/-1 de su eje)
local function beside(c: Crossing, lateral: number, sigma: number, extra: number): Vector3?
	local points = Rail.path()
	local p, t = Rail.sample(points, c.S)
	local n = V3(-t.Z, 0, t.X)
	local base = flat(p) + n * lateral
	local dm = flat(t):Dot(c.Normal)
	if math.abs(dm) < 0.2 then
		return nil
	end
	local target = sigma * (c.HalfTotal + extra)
	local k = (target - (base - c.Origin):Dot(c.Normal)) / dm
	return base + flat(t) * k
end

local function crossingPost(parent: Instance, c: Crossing, pos: Vector3, sigma: number, index: number)
	-- El poste mira hacia los coches que llegan (a lo largo de la calle, hacia fuera de la vía)
	local points = Rail.path()
	local center = flat((Rail.sample(points, c.S)))
	local out = if (pos - center):Dot(c.Dir) >= 0 then c.Dir else -c.Dir
	local cf = Builder.facing(V3(pos.X, 0, pos.Z), -out) -- (LookVector hacia la vía: la cara de delante, a los coches)
	local m = Builder.model("PostePasoNivel", parent)
	part(m, "Post", V3(0.6, 7, 0.6), cf * CFrame.new(0, 2.5, 0), WHITE, Enum.Material.Metal)
	decor(m, "PostBand", V3(0.65, 0.8, 0.65), cf * CFrame.new(0, 1.2, 0), RED, Enum.Material.Metal)
	-- Cruz de San Andrés (mirando a los coches)
	for _, ang in { 40, -40 } do
		decor(m, "CrossSign", V3(4, 0.5, 0.12), cf * CFrame.new(0, 6.6, 0.4) * CFrame.Angles(0, 0, math.rad(ang)), WHITE, Enum.Material.SmoothPlastic)
		decor(m, "CrossSignBorder", V3(4.1, 0.14, 0.1), cf * CFrame.new(0, 6.6, 0.47) * CFrame.Angles(0, 0, math.rad(ang)), RED)
	end
	-- Dos luces rojas (parpadean con el tren: RailUI)
	decor(m, "LightBar", V3(2.6, 0.4, 0.3), cf * CFrame.new(0, 4.6, 0.45), DARK)
	for i, x in { -0.9, 0.9 } do
		decor(m, "CrossingLight", V3(0.7, 0.7, 0.2), cf * CFrame.new(x, 4.6, 0.65), rgb(90, 20, 20), Enum.Material.SmoothPlastic, { Attributes = { Pair = i } })
	end
	-- Barrera: gira sobre la bisagra (arriba = levantada). Cada trozo guarda dónde va respecto a la
	-- bisagra con la barrera bajada (Local); el cliente la sube y la baja.
	local arm = Builder.model("Barrera", m)
	local toward = -c.Normal * sigma -- (bajada, cruza la calle hacia su eje)
	local hingePos = V3(pos.X, 3.2, pos.Z) + toward * 0.6
	local hinge = Builder.facing(hingePos, toward)
	local length = c.HalfTotal + 1.5
	arm:SetAttribute("Hinge", hinge)
	arm:SetAttribute("Index", index)
	local raised = hinge * CFrame.Angles(math.rad(88), 0, 0)
	local function armPart(name: string, size: Vector3, localCf: CFrame, color: Color3)
		decor(arm, name, size, raised * localCf, color, Enum.Material.SmoothPlastic, { Attributes = { Local = localCf }, Tags = { "RailArm" } })
	end
	armPart("Arm", V3(0.35, 0.35, length), CFrame.new(0, 0, -length / 2), WHITE)
	local k = 0
	local z = 1.5
	while z < length - 1 do
		k += 1
		if k % 2 == 1 then
			armPart("ArmStripe", V3(0.38, 0.38, 1.4), CFrame.new(0, 0, -z - 0.7), RED)
		end
		z += 1.4
	end
	part(m, "Counterweight", V3(0.8, 1.2, 1.4), Builder.facing(hingePos - toward * 0.9, toward) * CFrame.new(0, 0, 0), DARK, Enum.Material.Metal)
	return m
end

local function buildCrossings(parent: Instance)
	local points = Rail.path()
	local half = Rail.Gauge / 2
	for i, c in RailKit.crossings() do
		local m = Builder.model("PasoANivel", parent)
		m:AddTag("RailCrossing")
		-- Se carga entero en cada ordenador (con las cuatro barreras): así el cliente las mueve todas
		pcall(function()
			(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		end)
		m:SetAttribute("S", c.S)
		m:SetAttribute("Line", Rail.Line.Id)
		m:SetAttribute("Road", c.Name)
		local p, t = Rail.sample(points, c.S)
		m:SetAttribute("Center", V3(p.X, Street.ROAD_TOP, p.Z))
		-- Dónde paran los coches (a lo largo de la calle, desde la vía): un poco antes de las barreras
		local sin = math.max(0.3, math.abs(flat(t):Dot(c.Normal)))
		m:SetAttribute("Stop", POST_OFFSET / sin + 3)
		-- Carriles encastrados a ras del asfalto y de la acera (decorado: no se tropieza nadie) y el
		-- relleno de goma entre los dos
		-- (trozos de 1 stud según lo que hay debajo de cada carril; los seguidos a la misma altura van en
		-- una sola pieza)
		local function runs(lateral: number): { { number } }
			local list: { { number } } = {}
			local s = c.S0 - 1
			while s < c.S1 + 1 do
				local s1 = math.min(s + 1, c.S1 + 1)
				local q, t = Rail.sample(points, (s + s1) / 2)
				local f, v = roadAt(q + V3(-t.Z, 0, t.X) * lateral)
				local top = if f and v <= f.HalfRoad then Street.ROAD_TOP elseif f then Street.WALK_TOP else BED_TOP + 0.3
				local last = list[#list]
				local _, t0 = Rail.sample(points, if last then last[1] else s)
				local _, t1 = Rail.sample(points, s1)
				if last and last[3] == top and t0:Dot(t1) > 0.9998 then
					last[2] = s1
				else
					table.insert(list, { s, s1, top })
				end
				s = s1
			end
			return list
		end
		for _, side in { -1, 1 } do
			for _, run in runs(side * half) do
				local q, t = Rail.sample(points, (run[1] + run[2]) / 2)
				local off = V3(-t.Z, 0, t.X) * side * half
				decor(m, "Rail", V3(0.4, 0.16, run[2] - run[1] + 0.05), along(q + off, t, run[3] + 0.06), STEEL, Enum.Material.Metal)
			end
		end
		for _, run in runs(0) do
			local q, t = Rail.sample(points, (run[1] + run[2]) / 2)
			decor(m, "CrossingPanel", V3(Rail.Gauge - 0.6, 0.04, run[2] - run[1] + 0.05), along(q, t, run[3] + 0.02), DARK, Enum.Material.Rubber)
		end
		-- Cuatro postes con barrera (dos a cada lado de la vía)
		local index = 0
		for _, sigma in { -1, 1 } do
			for _, lateral in { -POST_OFFSET, POST_OFFSET } do
				local pos = beside(c, lateral, sigma, 2)
				if pos then
					index += 1
					crossingPost(m, c, pos, sigma, (i - 1) * 4 + index)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Estaciones
---------------------------------------------------------------------

local function stationName(id: string): string
	return Rail.Stations[id].Name
end

local function signBoard(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3, textColor: Color3?): BasePart
	local board = decor(parent, "Sign", size, cf, color)
	Builder.sign(board, text, Enum.NormalId.Front, textColor)
	Builder.sign(board, text, Enum.NormalId.Back, textColor)
	return board
end

local function station(parent: Instance, id: string, index: number)
	local st = Rail.Stations[id]
	local f = Rail.frame(id)
	local m = Builder.model("Estacion_" .. id, parent)
	m:SetAttribute("Station", id)
	local G, W, L = Rail.PlatformGap, Rail.PlatformWidth, Rail.PlatformLength
	local D = Rail.Deck
	local az = st.Access.Z
	local rw = Rail.RampWidth
	local function at(x: number, y: number, z: number): CFrame
		return f * CFrame.new(x, y, z)
	end
	local cx = G + W / 2
	-- Andén (macizo desde el suelo), borde blanco, línea amarilla y bandas de botones
	part(m, "Platform", V3(W, D + 1, L), at(cx, (D - 1) / 2, 0), CONCRETE, Enum.Material.Concrete)
	decor(m, "Coping", V3(0.8, 0.06, L), at(G + 0.4, D + 0.03, 0), WHITE, Enum.Material.Concrete)
	decor(m, "SafetyLine", V3(0.5, 0.06, L), at(G + 1.6, D + 0.03, 0), YELLOW)
	decor(m, "Tactile", V3(0.9, 0.05, L), at(G + 2.3, D + 0.03, 0), rgb(220, 196, 90), Enum.Material.DiamondPlate)
	-- Barandilla del lado del campo (menos donde baja la rampa) y en las puntas
	local backX = G + W - 0.2
	for _, span in { { -L / 2, az - rw / 2 }, { az + rw / 2, L / 2 } } do
		local len = span[2] - span[1]
		if len > 1 then
			part(m, "Railing", V3(0.2, 3, len), at(backX, D + 1.5, (span[1] + span[2]) / 2), STEEL, Enum.Material.Metal, { Transparency = 0.2 })
			decor(m, "RailingTop", V3(0.3, 0.2, len), at(backX, D + 3.05, (span[1] + span[2]) / 2), RED, Enum.Material.Metal)
		end
	end
	for _, z in { -L / 2 + 0.2, L / 2 - 0.2 } do
		part(m, "Railing", V3(W - 3, 3, 0.2), at(cx + 1.5, D + 1.5, z), STEEL, Enum.Material.Metal, { Transparency = 0.2 })
	end
	-- Marquesina con bancos y panel de salidas
	local sz = az - 38
	if sz - 18 < -L / 2 then
		sz = az + 38
	end
	local roofX = G + W - 3.8
	for _, z in { sz - 16, sz, sz + 16 } do
		part(m, "ShelterPost", V3(0.5, 8.6, 0.5), at(G + W - 1.2, D + 4.3, z), STEEL, Enum.Material.Metal)
	end
	part(m, "ShelterRoof", V3(7.6, 0.4, 38), at(roofX, D + 8.8, sz) * CFrame.Angles(0, 0, math.rad(-4)), RED, Enum.Material.Metal)
	decor(m, "ShelterGlass", V3(0.2, 6, 34), at(G + W - 0.8, D + 3.6, sz), rgb(170, 200, 220), Enum.Material.Glass, { Transparency = 0.55 })
	for _, z in { sz - 8, sz + 8 } do
		Props.bench(m, at(G + W - 2.4, D, z) * CFrame.Angles(0, math.rad(90), 0))
	end
	local display = decor(m, "Departures", V3(0.3, 1.6, 8), at(G + 3.5, D + 7.4, sz), DARK)
	display:AddTag("RailDisplay")
	display:SetAttribute("Station", id)
	display:SetAttribute("Line", Rail.Line.Id)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Builder.sign(display, "🚆 " .. Rail.Line.Id .. " · Cercanías", face, rgb(255, 200, 60), DARK)
	end
	decor(m, "DisplayHanger", V3(0.15, 1, 0.15), at(G + 3.5, D + 8.6, sz - 3), STEEL)
	decor(m, "DisplayHanger", V3(0.15, 1, 0.15), at(G + 3.5, D + 8.6, sz + 3), STEEL)
	-- Plano de la línea en la marquesina
	local names = {}
	for _, sid in Rail.Line.Stations do
		table.insert(names, stationName(sid))
	end
	local plan = decor(m, "LinePlan", V3(0.2, 2.6, 7), at(G + W - 0.95, D + 4, sz + 12), WHITE)
	Builder.sign(plan, "🚆 CERCANÍAS " .. Rail.Line.Id .. "\n" .. table.concat(names, " · "), Enum.NormalId.Left, DARK, WHITE)
	-- Lo que ya ocupa la franja de atrás del andén (marquesina, rampa, máquina): los carteles y las
	-- farolas van donde quede sitio
	local mz = az - rw / 2 - 3
	if mz < -L / 2 + 3 then
		mz = az + rw / 2 + 3
	end
	local taken = { { sz - 20, sz + 20 }, { az - rw / 2 - 2, az + rw / 2 + 2 }, { mz - 2, mz + 2 } }
	local function spot(candidates: { number }, half: number): { number }
		local out = {}
		for _, z in candidates do
			local ok = z - half > -L / 2 + 1 and z + half < L / 2 - 1
			for _, r in taken do
				if z + half > r[1] and z - half < r[2] then
					ok = false
				end
			end
			if ok and #out < 2 then
				table.insert(out, z)
				table.insert(taken, { z - half, z + half })
			end
		end
		return out
	end
	-- Carteles con el nombre
	for _, z in spot({ -L / 2 + 14, L / 2 - 14, -20, 20, 0 }, 4.5) do
		part(m, "SignPost", V3(0.4, 7, 0.4), at(G + W - 1.4, D + 3.5, z - 3), STEEL, Enum.Material.Metal)
		part(m, "SignPost", V3(0.4, 7, 0.4), at(G + W - 1.4, D + 3.5, z + 3), STEEL, Enum.Material.Metal)
		signBoard(m, at(G + W - 1.4, D + 7.4, z) * CFrame.Angles(0, math.rad(90), 0), V3(8, 1.6, 0.2), string.upper(stationName(id)), rgb(30, 60, 140))
	end
	-- Máquina de billetes (junto a la rampa)
	local machine = part(m, "TicketMachine", V3(1.6, 5.6, 2.2), at(G + W - 1.4, D + 2.8, mz), RED, Enum.Material.SmoothPlastic, { Tags = { "RailTicketMachine" }, Attributes = { Station = id } })
	decor(m, "TicketScreen", V3(0.1, 1.2, 1.4), at(G + W - 2.25, D + 3.8, mz), rgb(40, 120, 200), Enum.Material.Neon)
	Builder.sign(machine, "🎫 BILLETES", Enum.NormalId.Left, WHITE)
	-- Farolas del andén (se encienden de noche como las de la calle)
	for _, z in spot({ -L / 2 + 30, L / 2 - 30, -L / 2 + 6, L / 2 - 6, 0 }, 1.5) do
		Props.lamp(m, at(G + W - 1.2, D, z) * CFrame.Angles(0, math.rad(90), 0))
	end
	-- Botones de subir al tren (a la altura de cada coche) y sitio donde se baja
	local step = Rail.CarLength + Rail.CarGap
	for k = 1, Rail.Cars do
		local z = (k - (Rail.Cars + 1) / 2) * step
		marker(m, "RailBoard", at(G + 1.4, D + 2.5, z), "RailBoard", { Station = id, Line = Rail.Line.Id, Car = k })
	end
	local alightZ = if az + 8 < L / 2 - 4 then az + 8 else az - 8
	marker(m, "RailAlight", at(G + 5, D + 3, alightZ) * CFrame.Angles(0, math.rad(-90), 0), "RailAlight", { Station = id, Line = Rail.Line.Id }, V3(2, 2, 2))
	-- Rampa hasta la acera: base maciza y cuña (alta en el andén, a ras de la acera abajo)
	local x0, x1 = G + W, Rail.RampReach
	local rampLen = x1 - x0
	part(m, "RampBase", V3(rampLen, 2, rw), at((x0 + x1) / 2, 0, az), CONCRETE, Enum.Material.Concrete)
	part(m, "Ramp", V3(rw, D - Rail.WalkY, rampLen), at((x0 + x1) / 2, (D + Rail.WalkY) / 2, az) * CFrame.Angles(0, math.rad(-90), 0), CONCRETE, Enum.Material.Concrete, { ClassName = "WedgePart" })
	local slope = math.atan2(D - Rail.WalkY, rampLen)
	for _, side in { -1, 1 } do
		local z = az + side * (rw / 2 + 0.15)
		decor(m, "RampRail", V3(rampLen + 0.4, 0.2, 0.2), at((x0 + x1) / 2, (D + Rail.WalkY) / 2 + 3, z) * CFrame.Angles(0, 0, -slope), STEEL, Enum.Material.Metal)
		part(m, "RampWall", V3(rampLen, 1.2, 0.3), at((x0 + x1) / 2, (D + Rail.WalkY) / 2 + 0.6, z) * CFrame.Angles(0, 0, -slope), CONCRETE, Enum.Material.Concrete)
	end
	-- Camino hasta la acera (Levante y Campus)
	local path = st.Access.Path
	if path then
		for i = 1, #path - 1 do
			local a = V3(path[i][1], 0, path[i][2])
			local b = V3(path[i + 1][1], 0, path[i + 1][2])
			local len = (b - a).Magnitude
			local mid = (a + b) / 2
			part(m, "Path", V3(6, Rail.WalkY + 1, len), along(mid, b - a, (Rail.WalkY - 1) / 2), rgb(186, 182, 174), Enum.Material.Pavement, { CastShadow = false })
		end
	end
	-- Tótem en la calle: se ve desde lejos dónde está la estación
	local foot = (f * CFrame.new(Rail.RampReach - 1, 0, az + rw / 2 + 2.5)).Position
	if path then
		local last = path[#path]
		local prev = path[#path - 1]
		local dir = V3(last[1] - prev[1], 0, last[2] - prev[2]).Unit
		foot = V3(last[1], 0, last[2]) - dir * 4 + V3(-dir.Z, 0, dir.X) * 4.5
	end
	local totem = Builder.facing(V3(foot.X, 0, foot.Z), f.RightVector)
	-- (el modelo "EstacionCercanias" sale en el mapa y en el GPS: está en la calle, en la entrada)
	local entrance = Builder.model("EstacionCercanias", m)
	entrance:SetAttribute("Station", id)
	part(entrance, "Totem", V3(1.6, 12, 1.6), totem * CFrame.new(0, 5, 0), RED, Enum.Material.Metal)
	signBoard(entrance, totem * CFrame.new(0, 10, 0), V3(1.7, 3.4, 1.7), "🚆", RED, WHITE)
	signBoard(entrance, totem * CFrame.new(0, 6.6, 0) * CFrame.Angles(0, math.rad(90), 0), V3(1.7, 1.4, 1.7), "C1", WHITE, RED)
	local label = part(entrance, "EntranceSign", V3(6, 1.2, 0.2), totem * CFrame.new(0, 12.6, 0), rgb(30, 60, 140), Enum.Material.SmoothPlastic)
	Builder.sign(label, "Cercanías · " .. stationName(id), Enum.NormalId.Front)
	Builder.sign(label, "Cercanías · " .. stationName(id), Enum.NormalId.Back)
	-- Para el mapa y el GPS
	marker(m, "RailEntrance", CFrame.new(Rail.entrance(id) + V3(0, 2, 0)), "RailEntrance", { Station = id, Index = index }, V3(2, 2, 2))
	return m
end

---------------------------------------------------------------------
-- Tren
---------------------------------------------------------------------
function RailKit.train(parent: Instance): Model
	local line = Rail.Line
	local m = Instance.new("Model")
	m.Name = "Cercanias_" .. line.Id
	m:SetAttribute("Line", line.Id)
	m:AddTag("RailTrain")
	-- Siempre cargado y entero en cada ordenador (como el metro)
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)
	m.Parent = parent
	local points, centers = Rail.path()
	local step = Rail.CarLength + Rail.CarGap
	local names = {}
	for _, id in line.Stations do
		table.insert(names, stationName(id))
	end
	local style = {
		Length = Rail.CarLength,
		Gap = Rail.CarGap,
		DoorTag = "RailDoor",
		SeatTag = "RailSeat",
		Icon = "🚆",
		StationNames = names,
		Ads = { "Cercanías: del campo al Campus", "Bono Cercanías: 10 viajes", "Villaverde: productos de la huerta", "Abono de metro: también vale en el tren", "Levante: todo el comercio" },
	}
	for k = 1, Rail.Cars do
		local offset = (k - (Rail.Cars + 1) / 2) * step
		local p, t = Rail.sample(points, centers[1] - offset)
		local cf = Builder.facing(p, t)
		local car = MetroKit.car(m, cf, line, k, Rail.Cars, style)
		-- Ruedas y faldón (el suelo del coche va a la altura del andén: las ruedas pisan los carriles)
		for _, z in { -Rail.CarLength / 2 + 5, -Rail.CarLength / 2 + 8, Rail.CarLength / 2 - 8, Rail.CarLength / 2 - 5 } do
			for _, x in { -Rail.Gauge / 2, Rail.Gauge / 2 } do
				decor(car, "Wheel", V3(0.5, 2.3, 2.3), cf * CFrame.new(x, -(Rail.Deck - Rail.RailTop) + 1.15, z) * CFrame.Angles(0, 0, 0), DARK, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
			end
		end
		decor(car, "Skirt", V3(Rail.CarWidth - 0.4, 1, Rail.CarLength - 20), cf * CFrame.new(0, -1.1, 0), RED, Enum.Material.Metal)
	end
	return m
end

---------------------------------------------------------------------
-- Despejar la vía y construir
---------------------------------------------------------------------

type Box = { C: Vector3, U: Vector3, HU: number, HV: number }

-- Zonas que tienen que quedar libres: la vía (con el tren), los andenes, las rampas y los caminos
function RailKit.keepOut(): { Box }
	local list: { Box } = {}
	local _, _, length = Rail.path()
	for _, piece in pieces(0, length, 20) do
		local dir = flat(piece.B - piece.A)
		local len = dir.Magnitude
		table.insert(list, { C = flat((piece.A + piece.B) / 2), U = dir / len, HU = len / 2 + 1, HV = Rail.Clearance })
	end
	for id, st in Rail.Stations do
		local f = Rail.frame(id)
		local x0, x1 = Rail.PlatformGap - 0.5, Rail.RampReach
		local center = (f * CFrame.new((x0 + x1) / 2, 0, 0)).Position
		table.insert(list, { C = flat(center), U = flat(f.LookVector), HU = Rail.PlatformLength / 2 + 1, HV = (x1 - x0) / 2 })
		local path = st.Access.Path
		if path then
			for i = 1, #path - 1 do
				local a, b = V3(path[i][1], 0, path[i][2]), V3(path[i + 1][1], 0, path[i + 1][2])
				table.insert(list, { C = (a + b) / 2, U = (b - a).Unit, HU = (b - a).Magnitude / 2 + 3, HV = 4 })
			end
		end
	end
	return list
end

-- ¿Se tocan la caja (alineada con los ejes) [lo, hi] en horizontal y la zona b?
local function touches(lo: Vector3, hi: Vector3, b: Box): boolean
	local c = (lo + hi) / 2
	local h = (hi - lo) / 2
	local u, v = b.U, V3(-b.U.Z, 0, b.U.X)
	local d = V3(c.X - b.C.X, 0, c.Z - b.C.Z)
	-- ejes de la zona
	if math.abs(d:Dot(u)) > b.HU + h.X * math.abs(u.X) + h.Z * math.abs(u.Z) then
		return false
	end
	if math.abs(d:Dot(v)) > b.HV + h.X * math.abs(v.X) + h.Z * math.abs(v.Z) then
		return false
	end
	-- ejes del mundo
	if math.abs(d.X) > h.X + b.HU * math.abs(u.X) + b.HV * math.abs(v.X) then
		return false
	end
	if math.abs(d.Z) > h.Z + b.HU * math.abs(u.Z) + b.HV * math.abs(v.Z) then
		return false
	end
	return true
end

-- Caja (alineada con los ejes) de una pieza
local function bounds(p: BasePart): (Vector3, Vector3)
	local c = { p.CFrame:GetComponents() }
	local s = p.Size
	local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
	local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
	local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
	return V3(c[1] - hx, c[2] - hy, c[3] - hz), V3(c[1] + hx, c[2] + hy, c[3] + hz)
end
RailKit.bounds = bounds
RailKit.touches = touches

-- Quita lo que estorba encima de la vía y de las estaciones (árboles, farolas, bancos…): el modelo
-- pequeño que lo contiene entero. Lo que está a ras del suelo (calzadas, aceras, césped) se queda.
function RailKit.clear(world: Instance): number
	local boxes = RailKit.keepOut()
	local CELL = 64
	local grid: { [string]: { Box } } = {}
	for _, b in boxes do
		local r = b.HU + b.HV
		for gx = math.floor((b.C.X - r) / CELL), math.floor((b.C.X + r) / CELL) do
			for gz = math.floor((b.C.Z - r) / CELL), math.floor((b.C.Z + r) / CELL) do
				local k = gx .. ":" .. gz
				grid[k] = grid[k] or {}
				table.insert(grid[k], b)
			end
		end
	end
	-- ¿El modelo cabe en 40 studs? (se deja de mirar en cuanto se pasa)
	local smallCache: { [Instance]: boolean } = {}
	local function small(model: Instance): boolean
		local known = smallCache[model]
		if known ~= nil then
			return known
		end
		local lo, hi = V3(math.huge, 0, math.huge), V3(-math.huge, 0, -math.huge)
		local ok = true
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				local a, b = bounds(d)
				lo = V3(math.min(lo.X, a.X), 0, math.min(lo.Z, a.Z))
				hi = V3(math.max(hi.X, b.X), 0, math.max(hi.Z, b.Z))
				if hi.X - lo.X > 40 or hi.Z - lo.Z > 40 then
					ok = false
					break
				end
			end
		end
		smallCache[model] = ok
		return ok
	end
	local doomed: { [Instance]: boolean } = {}
	for _, p in world:GetDescendants() do
		if p:IsA("BasePart") then
			local lo, hi = bounds(p)
			if hi.Y > 1.3 and lo.Y < 16 and hi.X - lo.X < 200 and hi.Z - lo.Z < 200 then
				local hit = false
				for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
					for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
						for _, b in grid[gx .. ":" .. gz] or {} do
							if touches(lo, hi, b) then
								hit = true
								break
							end
						end
						if hit then
							break
						end
					end
					if hit then
						break
					end
				end
				if hit then
					-- El modelo más grande que siga siendo pequeño (una farola, un árbol, un banco)
					local target: Instance = p
					local node = p.Parent
					while node and node ~= world and node:IsA("Model") and small(node) do
						target = node
						node = node.Parent
					end
					doomed[target] = true
				end
			end
		end
	end
	local removed = 0
	for inst in doomed do
		if inst.Parent then
			inst:Destroy()
			removed += 1
		end
	end
	return removed
end

function RailKit.build(world: Instance): Model
	RailKit.clear(world)
	local root = Builder.model("Cercanias", world)
	buildTrack(root)
	buildCrossings(root)
	for i, id in Rail.Line.Stations do
		station(root, id, i)
	end
	RailKit.train(root)
	return root
end

return RailKit
