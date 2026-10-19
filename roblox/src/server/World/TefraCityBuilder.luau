-- TefraCityBuilder (servidor): construye Bastión Ceniza, la ciudad de Tefra, con el plano de
-- shared/Cosmos/TefraCity (docs/planetas/tefra-ciudad.md). Lo llama World/PlanetWorld.buildProps la
-- primera vez que alguien se acerca a Tefra (como el terreno: nada de esto está en el archivo del juego).
--
-- Usa los MISMOS constructores que Valmar, con el estilo de Tefra:
--   * Kit/Street: calles con aceras, cruces, farolas y nombres (con Palette.withTheme("Tefra"): asfalto de
--     basalto, losas de toba, marcas y farolas naranjas; sin semáforos: NoSignals).
--   * Kit/Building: edificios con la planta baja jugable y su puerta (estilos TefraBunker, TefraFabrica y
--     TefraCupula de Kit/Palette). Las ventanas se encienden de noche (NightWindow, WorldService) y las
--     farolas también (StreetLamp).
--   * Kit/Props: bancos (Bench: la gente se sienta, Services/CrowdService) y farolas.
-- Y lo que es solo de Tefra: la muralla con torres y puertas, el foso y el Canal de la Forja de lava con
-- sus puentes de hierro (con barandilla: no se cae nadie), las cúpulas del Ovillo, el armazón de la casa de
-- Cosme, el mercado en espiral alrededor del pozo de lava, la estatua de la abuela Nilda, las tiendas de
-- los refugiados, los controles militares, la Lanza, chimeneas y fumarolas con humo y brasas.
-- Gente: marcas CrowdSpot (grupo «Tefra_…») y zonas de paseo (CrowdService.addArea).
--
-- Todo se monta a la altura Y = 0 dentro de un modelo SIN padre y al final se sube a la altura de la
-- meseta (Base = Tefra.padY()): las calles de Kit/Street van siempre a Y = 0 (como Valmar). Así, además,
-- las etiquetas (Shop, Bench, CrowdSpot…) llegan a los servicios con sus atributos ya puestos.
--
-- API: TefraCityBuilder.build(parent, prompt, opts?) → (modelo, resumen { Parts, Buildings, … })
--   prompt(parent, kind, id, action, object, hold) crea un aviso (PlanetWorld: tipo "City")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tefra = require(ReplicatedStorage.Shared.Cosmos.Tefra)
local TefraCity = require(ReplicatedStorage.Shared.Cosmos.TefraCity)
local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)
local Street = require(script.Parent.Kit.Street)
local Building = require(script.Parent.Kit.Building)
local Props = require(script.Parent.Kit.Props)

local TefraCityBuilder = {}

local rgb = Color3.fromRGB
local O = Tefra.Origin
local V3 = Vector3.new

local C = {
	Basalt = rgb(46, 42, 48),
	BasaltLight = rgb(70, 64, 70),
	Tuff = rgb(96, 86, 92),
	Plaza = rgb(112, 100, 106),
	Iron = rgb(40, 38, 42),
	Rust = rgb(130, 76, 46),
	Lava = rgb(255, 110, 30),
	LavaHot = rgb(255, 170, 60),
	Crust = rgb(40, 24, 20),
	Plaster = { rgb(214, 190, 200), rgb(226, 206, 196), rgb(200, 176, 192), rgb(232, 214, 206), rgb(190, 170, 186) },
	Dark = rgb(34, 28, 32),
	Fabric = { rgb(140, 120, 110), rgb(120, 110, 130), rgb(150, 130, 100), rgb(110, 100, 96) },
	Sandbag = rgb(140, 124, 96),
	Military = rgb(70, 76, 62),
}

local function W(lx: number, lz: number, y: number?): Vector3
	return V3(O.X + lx, y or 0, O.Z + lz)
end

local YAW = { N = 0, S = math.pi, E = -math.pi / 2, W = math.pi / 2 }

local function CF(lx: number, lz: number, y: number?, yaw: number?): CFrame
	return CFrame.new(W(lx, lz, y)) * CFrame.Angles(0, yaw or 0, 0)
end

-- Caja alineada (local x0..x1, z0..z1, y0..y1)
local function box(parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, color: Color3, material: Enum.Material, decor: boolean?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = {
		Name = name,
		Size = V3(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
		CFrame = CFrame.new(W((x0 + x1) / 2, (z0 + z1) / 2, (y0 + y1) / 2)),
		Color = color,
		Material = material,
		Parent = parent,
	}
	for k, v in extra or {} do
		props[k] = v
	end
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function ball(parent: Instance, name: string, at: Vector3, size: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart
	local props = { Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = CFrame.new(at), Color = color, Material = material, Parent = parent }
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Cilindro de pie (eje Y) con la base en at
local function column(parent: Instance, name: string, at: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart
	local props = {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = V3(height, diameter, diameter),
		CFrame = CFrame.new(at + V3(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material,
		Parent = parent,
	}
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

local function smoke(parent: Instance, rate: number, big: boolean?)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Humo"
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(6, 9)
	e.Speed = NumberRange.new(5, 8)
	e.SpreadAngle = Vector2.new(10, 10)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, if big then 6 else 3), NumberSequenceKeypoint.new(1, if big then 24 else 12) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(rgb(90, 80, 82), rgb(60, 54, 58))
	e.Acceleration = V3(1, 1.5, 0)
	e.Parent = parent
end

local function embers(parent: Instance, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Brasas"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(1.2, 2.4)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(25, 25)
	e.LightEmission = 1
	e.Color = ColorSequence.new(rgb(255, 170, 60), rgb(255, 60, 20))
	e.Size = NumberSequence.new(0.5, 0)
	e.Parent = parent
end

local function steam(parent: Instance, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Vapor"
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = rate
	e.Lifetime = NumberRange.new(3, 5)
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(30, 30)
	e.Size = NumberSequence.new(2, 8)
	e.Transparency = NumberSequence.new(0.6, 1)
	e.Color = ColorSequence.new(rgb(236, 230, 236))
	e.Parent = parent
end

-- Ventana redonda que se enciende de noche (WorldService: NightWindow)
local function nightGlow(part: BasePart, day: Color3)
	part:AddTag("NightWindow")
	part:SetAttribute("DayColor", day)
	Building.nightSchedule(part, rgb(255, 176, 96), 17.6, 20.5, 22.5, 26)
end

-- Marca de gente (Services/CrowdService: CrowdSpot). y = 0 es el suelo; mira hacia (fx, fz)
local function crowd(parent: Instance, group: string, lx: number, lz: number, floor: number, fx: number, fz: number, work: string?, sit: boolean?)
	local at = W(lx, lz, floor + 2.5)
	local dir = V3(fx - lx, 0, fz - lz)
	local cf = if dir.Magnitude > 0.1 then Builder.facing(at, dir) else CFrame.new(at)
	Builder.part({
		Name = "CrowdSpot",
		Size = V3(2, 5, 2),
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Tags = { "CrowdSpot" },
		Attributes = { Group = "Tefra_" .. group, Work = work, Pose = if sit then "Sit" else nil },
		Parent = parent,
	})
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
type Ctx = {
	Model: Model,
	Prompt: (Instance, string, string, string, string, number?) -> ProximityPrompt,
	Infos: number,
	Areas: { Instance },
}

-- Aviso «Mirar» (kind City) en un punto: Services/PlanetService enseña el texto del plano
local function info(ctx: Ctx, parent: Instance, id: string, lx: number, lz: number, y: number, action: string?, object: string?)
	local anchor = Builder.part({
		Name = "AvisoCiudad",
		Size = V3(3, 4, 3),
		CFrame = CFrame.new(W(lx, lz, y + 2)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = parent,
	})
	local spot = TefraCity.SpotById[id] or TefraCity.BuildingById[id]
	ctx.Prompt(anchor, "City", id, action or "Mirar", object or (spot and spot.Name) or "Bastión Ceniza", 0.3)
	ctx.Infos += 1
end

-- Cartel con letras sobre una placa (mirando hacia face)
local function plate(parent: Instance, text: string, cf: CFrame, w: number, h: number, color: Color3?, textColor: Color3?)
	local p = Builder.decor({ Name = "Cartel", Size = V3(w, h, 0.3), CFrame = cf, Color = color or rgb(30, 26, 30), Material = Enum.Material.Metal, Parent = parent })
	Builder.sign(p, text, Enum.NormalId.Front, textColor or rgb(255, 176, 96))
	return p
end

-- Barandilla de basalto con pasamanos de hierro de (x0, z0) a (x1, z1) (alineada con un eje)
local function parapet(parent: Instance, x0: number, z0: number, x1: number, z1: number, y: number, height: number?)
	local h = height or 3.2
	local alongX = math.abs(x1 - x0) >= math.abs(z1 - z0)
	local t = 0.8
	if alongX then
		box(parent, "Barandilla", x0, x1, z0 - t / 2, z0 + t / 2, y, y + h, C.Basalt, Enum.Material.Basalt)
		box(parent, "Pasamanos", x0, x1, z0 - 0.5, z0 + 0.5, y + h, y + h + 0.3, C.Iron, Enum.Material.Metal, true)
	else
		box(parent, "Barandilla", x0 - t / 2, x0 + t / 2, z0, z1, y, y + h, C.Basalt, Enum.Material.Basalt)
		box(parent, "Pasamanos", x0 - 0.5, x0 + 0.5, z0, z1, y + h, y + h + 0.3, C.Iron, Enum.Material.Metal, true)
	end
end

-- Lava (neón que brilla) entre x0..x1, z0..z1
local function lava(parent: Instance, x0: number, x1: number, z0: number, z1: number)
	local top = -TefraCity.LavaTop
	local p = box(parent, "Lava", x0, x1, z0, z1, top - 1, top, C.Lava, Enum.Material.Neon, false, { CastShadow = false })
	return p
end

---------------------------------------------------------------------
-- Suelo de las manzanas, el canal, los pozos, el foso y la muralla
---------------------------------------------------------------------
local function grounds(ctx: Ctx, folder: Instance)
	local H = TefraCity.BlockHalf
	for c, cx in TefraCity.BlockCols do
		for r, cz in TefraCity.BlockRows do
			local open = TefraCity.OpenBlocks[c .. "," .. r]
			local top = if c == 3 and r == 2 then 0.45 else 0.9
			local color = if open == "Mirador" then C.Plaza elseif open then C.Tuff else C.BasaltLight
			local material = if open then Enum.Material.Cobblestone else Enum.Material.Basalt
			box(folder, "Manzana", cx - H, cx + H, cz - H, cz + H, Street.BASE, top, color, material)
		end
	end
end

local function canal(ctx: Ctx, folder: Instance)
	local R = TefraCity.Rect
	local c = TefraCity.Canal
	local m = Builder.model("CanalForja", folder)
	-- La lava, de lado a lado (sale al foso por debajo de la muralla)
	lava(m, R.X0 - TefraCity.WallThick, R.X1 + TefraCity.WallThick, c.Z - c.Half, c.Z + c.Half)
	-- Paseos a los dos lados (entre las calles: las calles hacen de puente) y su barandilla
	local streetsX = {}
	for _, s in TefraCity.Streets do
		if s.Axis == "Z" and s.From < c.Z and s.To > c.Z then
			table.insert(streetsX, s.At)
		end
	end
	table.sort(streetsX)
	local half = TefraCity.RoadHalf
	local pieces = {}
	local cursor = R.X0
	for _, x in streetsX do
		if x - half > cursor + 1 then
			table.insert(pieces, { cursor, x - half })
		end
		cursor = x + half
	end
	if R.X1 > cursor + 1 then
		table.insert(pieces, { cursor, R.X1 })
	end
	for _, p in pieces do
		box(m, "Paseo", p[1], p[2], c.Z - c.Half - c.Walk, c.Z - c.Half, Street.BASE, Street.WALK_TOP, C.Tuff, Enum.Material.Pavement)
		box(m, "Paseo", p[1], p[2], c.Z + c.Half, c.Z + c.Half + c.Walk, Street.BASE, Street.WALK_TOP, C.Tuff, Enum.Material.Pavement)
		parapet(m, p[1], c.Z - c.Half + 0.4, p[2], c.Z - c.Half + 0.4, Street.WALK_TOP)
		parapet(m, p[1], c.Z + c.Half - 0.4, p[2], c.Z + c.Half - 0.4, Street.WALK_TOP)
	end
	-- Puentes de hierro: barandilla y vigas en cada calle que cruza
	for _, x in streetsX do
		for _, s in { -1, 1 } do
			local bx = x + s * (half + 0.4)
			parapet(m, bx, c.Z - c.Half - 0.5, bx, c.Z + c.Half + 0.5, Street.WALK_TOP, 2.6)
			box(m, "Viga", x + s * (half - 2) - 1, x + s * (half - 2) + 1, c.Z - c.Half, c.Z + c.Half, Street.BASE - 3, Street.BASE, C.Rust, Enum.Material.CorrodedMetal, true)
		end
		-- Arco de hierro sobre el puente
		for _, s in { -1, 1 } do
			box(m, "Poste", x + s * (half + 0.4) - 0.6, x + s * (half + 0.4) + 0.6, c.Z - 0.6, c.Z + 0.6, Street.WALK_TOP, 14, C.Iron, Enum.Material.Metal, true)
		end
		box(m, "Arco", x - half - 1, x + half + 1, c.Z - 0.6, c.Z + 0.6, 13, 14.2, C.Iron, Enum.Material.Metal, true)
	end
	-- El Puente de los Mil Candados (Avenida del Muelle): candados de colores en la barandilla
	local lock = TefraCity.SpotById.Candados
	local rng = Tefra.rng(777)
	local colors = { rgb(220, 180, 60), rgb(190, 190, 196), rgb(200, 90, 70), rgb(80, 130, 200), rgb(150, 200, 120), rgb(230, 140, 200) }
	for _, s in { -1, 1 } do
		local bx = lock.X + s * (half + 0.4)
		for k = 0, 22 do
			local z = c.Z - c.Half + 1 + k * (2 * c.Half - 2) / 22
			box(m, "Candado", bx - 0.5, bx + 0.5, z - 0.35, z + 0.35, Street.WALK_TOP + 2 + rng() * 0.9, Street.WALK_TOP + 2.6 + rng() * 0.9, colors[1 + math.floor(rng() * #colors)], Enum.Material.Metal, true)
		end
	end
	info(ctx, m, "Candados", lock.X + half - 3, lock.Z - c.Half - 2, Street.WALK_TOP, "Mirar los candados")
	-- Luz y brasas a lo largo del canal
	for k = 0, 5 do
		local x = R.X0 + 60 + k * (R.X1 - R.X0 - 120) / 5
		local glow = box(m, "Brillo", x - 1, x + 1, c.Z - 1, c.Z + 1, -TefraCity.LavaTop, -TefraCity.LavaTop + 0.2, C.LavaHot, Enum.Material.Neon, true)
		light(glow, C.Lava, 34, 2.2)
		if k % 2 == 0 then
			embers(glow, 3)
		end
	end
end

local function wells(ctx: Ctx, folder: Instance)
	for _, w in TefraCity.Wells do
		local m = Builder.model(w.Id, folder)
		local top = -TefraCity.LavaTop
		local disc = Builder.part({
			Name = "Lava",
			Shape = Enum.PartType.Cylinder,
			Size = V3(1, w.R * 2, w.R * 2),
			CFrame = CFrame.new(W(w.X, w.Z, top - 0.5)) * CFrame.Angles(0, 0, math.pi / 2),
			Color = C.Lava,
			Material = Enum.Material.Neon,
			CastShadow = false,
			Parent = m,
		})
		light(disc, C.Lava, 36, 2.6)
		embers(disc, 5)
		-- Brocal de basalto alrededor (12 tramos)
		local n = 12
		for k = 0, n - 1 do
			local a = (k + 0.5) / n * math.pi * 2
			local len = 2 * (w.R + 1) * math.tan(math.pi / n) + 0.6
			Builder.part({
				Name = "Brocal",
				Size = V3(len, 3.2 + 1, 1.2),
				CFrame = CFrame.new(W(w.X + math.cos(a) * (w.R + 1), w.Z + math.sin(a) * (w.R + 1), Street.WALK_TOP + 1.6 - 0.5)) * CFrame.Angles(0, -a + math.pi / 2, 0),
				Color = C.Basalt,
				Material = Enum.Material.Basalt,
				Parent = m,
			})
		end
	end
end

local function moat(ctx: Ctx, folder: Instance)
	local R = TefraCity.Rect
	local a, b = TefraCity.WallThick, TefraCity.MoatOut
	local m = Builder.model("Foso", folder)
	lava(m, R.X0 - b, R.X1 + b, R.Z0 - b, R.Z0 - a) -- norte
	lava(m, R.X0 - b, R.X1 + b, R.Z1 + a, R.Z1 + b) -- sur
	lava(m, R.X0 - b, R.X0 - a, R.Z0 - a, R.Z1 + a) -- oeste
	lava(m, R.X1 + a, R.X1 + b, R.Z0 - a, R.Z1 + a) -- este
	-- Luz y brasas (pocas: el móvil)
	local mid = (a + b) / 2
	local spots = {
		{ R.X0 - mid, R.Z0 - mid }, { R.X1 + mid, R.Z0 - mid }, { R.X0 - mid, R.Z1 + mid }, { R.X1 + mid, R.Z1 + mid },
		{ (R.X0 + R.X1) / 2, R.Z0 - mid }, { (R.X0 + R.X1) / 2, R.Z1 + mid }, { R.X0 - mid, (R.Z0 + R.Z1) / 2 }, { R.X1 + mid, (R.Z0 + R.Z1) / 2 },
	}
	for i, p in spots do
		local glow = box(m, "Brillo", p[1] - 1, p[1] + 1, p[2] - 1, p[2] + 1, -TefraCity.LavaTop, -TefraCity.LavaTop + 0.2, C.LavaHot, Enum.Material.Neon, true)
		light(glow, C.Lava, 46, 2.4)
		if i % 2 == 1 then
			embers(glow, 3)
			smoke(glow, 1)
		end
	end
end

-- Muralla: tramos (con hueco en las puertas), almenas, torres con cañón y las puertas con su control
local function wall(ctx: Ctx, folder: Instance)
	local R = TefraCity.Rect
	local t = TefraCity.WallThick
	local H = TefraCity.WallHeight
	local m = Builder.model("Muralla", folder)
	local GAP = TefraCity.GateHalf -- (el hueco de cada puerta: la calzada y sus dos aceras)
	local sides = {
		{ Axis = "X", At0 = R.Z0 - t, At1 = R.Z0, From = R.X0 - t, To = R.X1 + t, Out = -1 },
		{ Axis = "X", At0 = R.Z1, At1 = R.Z1 + t, From = R.X0 - t, To = R.X1 + t, Out = 1 },
		{ Axis = "Z", At0 = R.X0 - t, At1 = R.X0, From = R.Z0, To = R.Z1, Out = -1 },
		{ Axis = "Z", At0 = R.X1, At1 = R.X1 + t, From = R.Z0, To = R.Z1, Out = 1 },
	}
	for _, side in sides do
		-- huecos de las puertas en este lado
		local cuts = {}
		for _, g in TefraCity.Gates do
			local onSide = if side.Axis == "X" then (g.Dir[2] == side.Out) else (g.Dir[1] == side.Out)
			if onSide then
				table.insert(cuts, if side.Axis == "X" then g.X else g.Z)
			end
		end
		table.sort(cuts)
		local runs = {}
		local cursor = side.From
		for _, u in cuts do
			table.insert(runs, { cursor, u - GAP })
			cursor = u + GAP
		end
		table.insert(runs, { cursor, side.To })
		for _, run in runs do
			local u0, u1 = run[1], run[2]
			if u1 - u0 > 1 then
				if side.Axis == "X" then
					box(m, "Muro", u0, u1, side.At0, side.At1, -1, H, C.Basalt, Enum.Material.Basalt)
				else
					box(m, "Muro", side.At0, side.At1, u0, u1, -1, H, C.Basalt, Enum.Material.Basalt)
				end
				-- Almenas (cada 20 studs, por fuera)
				local u = u0 + 6
				while u + 6 <= u1 do
					local o0 = if side.Out < 0 then side.At0 else side.At1 - 2
					if side.Axis == "X" then
						box(m, "Almena", u, u + 6, o0, o0 + 2, H, H + 3, C.Basalt, Enum.Material.Basalt, true)
					else
						box(m, "Almena", o0, o0 + 2, u, u + 6, H, H + 3, C.Basalt, Enum.Material.Basalt, true)
					end
					u += 20
				end
				-- Franja de luz de emergencia por dentro (una pieza por tramo)
				local inner = if side.Out < 0 then side.At1 + 0.05 else side.At0 - 0.25
				if side.Axis == "X" then
					box(m, "Franja", u0, u1, inner, inner + 0.2, H - 3, H - 2.4, rgb(255, 120, 40), Enum.Material.Neon, true)
				else
					box(m, "Franja", inner, inner + 0.2, u0, u1, H - 3, H - 2.4, rgb(255, 120, 40), Enum.Material.Neon, true)
				end
			end
		end
	end
	-- Torres (por FUERA del borde: salen del foso de lava y no pisan las aceras): las cuatro esquinas,
	-- una a cada lado de cada puerta y una a mitad de los lados largos
	local towers = {}
	for _, tw in TefraCity.towers() do
		table.insert(towers, { tw.X, tw.Z, tw.S, tw.H })
	end
	for _, tw in towers do
		local x, z, s, h = tw[1], tw[2], tw[3], tw[4]
		box(m, "Torre", x - s / 2, x + s / 2, z - s / 2, z + s / 2, -TefraCity.LavaDepth, h, C.Basalt, Enum.Material.Basalt)
		box(m, "TorreTecho", x - s / 2 - 1, x + s / 2 + 1, z - s / 2 - 1, z + s / 2 + 1, h, h + 1.5, C.Iron, Enum.Material.CorrodedMetal)
		-- Tronera que brilla y el cañón hacia fuera (hacia el lado de la muralla más cercano)
		local lx, lz = x, z
		local dx = if math.abs(lx - R.X0) < 20 then -1 elseif math.abs(lx - R.X1) < 20 then 1 else 0
		local dz = if dx == 0 then (if math.abs(lz - R.Z0) < 20 then -1 else 1) else 0
		local face = W(lx + dx * (s / 2 + 2), lz + dz * (s / 2 + 2), h - 5)
		Builder.decor({
			Name = "Canon",
			Shape = Enum.PartType.Cylinder,
			Size = V3(7, 1.6, 1.6),
			CFrame = CFrame.new(face) * CFrame.Angles(0, if dz ~= 0 then math.pi / 2 else 0, 0) * CFrame.Angles(0, 0, 0.12 * (if dx < 0 or dz > 0 then -1 else 1)),
			Color = C.Iron,
			Material = Enum.Material.Metal,
			Parent = m,
		})
		box(m, "Tronera", lx + dx * (s / 2 + 0.05) - (if dx == 0 then s * 0.3 else 0.1), lx + dx * (s / 2 + 0.05) + (if dx == 0 then s * 0.3 else 0.1), lz + dz * (s / 2 + 0.05) - (if dz == 0 then s * 0.3 else 0.1), lz + dz * (s / 2 + 0.05) + (if dz == 0 then s * 0.3 else 0.1), h - 9, h - 8.2, rgb(255, 140, 60), Enum.Material.Neon, true)
	end
	-- Las puertas: barandillas del puente sobre el foso y el control de la policía militar por dentro
	for _, g in TefraCity.Gates do
		local half = TefraCity.RoadHalf
		local d0, d1 = TefraCity.WallThick, TefraCity.MoatOut
		for _, s in { -1, 1 } do
			if g.Dir[1] ~= 0 then
				local x0 = g.X + g.Dir[1] * d0
				local x1 = g.X + g.Dir[1] * d1
				parapet(m, math.min(x0, x1), g.Z + s * (half + 0.4), math.max(x0, x1), g.Z + s * (half + 0.4), Street.WALK_TOP, 2.6)
				box(m, "Viga", math.min(x0, x1), math.max(x0, x1), g.Z + s * (half - 2) - 1, g.Z + s * (half - 2) + 1, Street.BASE - 4, Street.BASE, C.Rust, Enum.Material.CorrodedMetal, true)
			else
				local z0 = g.Z + g.Dir[2] * d0
				local z1 = g.Z + g.Dir[2] * d1
				parapet(m, g.X + s * (half + 0.4), math.min(z0, z1), g.X + s * (half + 0.4), math.max(z0, z1), Street.WALK_TOP, 2.6)
				box(m, "Viga", g.X + s * (half - 2) - 1, g.X + s * (half - 2) + 1, math.min(z0, z1), math.max(z0, z1), Street.BASE - 4, Street.BASE, C.Rust, Enum.Material.CorrodedMetal, true)
			end
		end
		-- Arco de la puerta con su nombre (por fuera)
		local dirv = V3(g.Dir[1], 0, g.Dir[2])
		local center = W(g.X + g.Dir[1] * t / 2, g.Z + g.Dir[2] * t / 2, TefraCity.WallHeight - 1.5)
		local arch = Builder.facing(center, dirv)
		Builder.part({ Name = "Dintel", Size = V3(GAP * 2 + 2, 3, t), CFrame = arch, Color = C.Basalt, Material = Enum.Material.Basalt, Parent = m })
		plate(m, string.upper(g.Name), arch * CFrame.new(0, 0, -(t / 2 + 0.2)), 14, 2.4)
		-- Control: garita, barrera y sacos terreros (por dentro, en la acera)
		local spot = TefraCity.SpotById["Puerta" .. g.Id]
		local inX, inZ = spot.X, spot.Z
		local px, pz = g.Dir[2], g.Dir[1] -- (de lado)
		local bx, bz = inX + px * (half - 3), inZ + pz * (half - 3)
		local booth = Builder.model("Control", m)
		box(booth, "Garita", bx - 2.5, bx + 2.5, bz - 2.5, bz + 2.5, Street.WALK_TOP, Street.WALK_TOP + 8, C.Military, Enum.Material.Metal)
		box(booth, "GaritaTecho", bx - 3, bx + 3, bz - 3, bz + 3, Street.WALK_TOP + 8, Street.WALK_TOP + 8.6, C.Iron, Enum.Material.Metal, true)
		box(booth, "Ventanuco", bx - 2.6, bx + 2.6, bz - 2.6, bz + 2.6, Street.WALK_TOP + 5, Street.WALK_TOP + 6, rgb(255, 170, 90), Enum.Material.Neon, true)
		-- Barrera (pluma) cruzando media calzada, levantada a medias
		local boom = CFrame.new(W(inX + px * 4, inZ + pz * 4, Street.ROAD_TOP + 3.4)) * CFrame.Angles(0, if g.Dir[1] ~= 0 then math.pi / 2 else 0, 0) * CFrame.Angles(0, 0, 0.35)
		Builder.decor({ Name = "Barrera", Size = V3(16, 0.5, 0.5), CFrame = boom, Color = rgb(230, 120, 40), Material = Enum.Material.SmoothPlastic, Parent = booth })
		for k = -1, 1 do
			local sx, sz = inX - px * (half - 3) + pz * k * 3, inZ - pz * (half - 3) + px * k * 3
			box(booth, "Sacos", sx - 1.5, sx + 1.5, sz - 1.5, sz + 1.5, Street.WALK_TOP, Street.WALK_TOP + 2.6 - math.abs(k) * 0.5, C.Sandbag, Enum.Material.Fabric)
		end
		plate(booth, "CONTROL · PAPELES", CFrame.new(W(bx, bz, Street.WALK_TOP + 9.6)) * CFrame.Angles(0, if g.Dir[1] ~= 0 then (if g.Dir[1] > 0 then -math.pi / 2 else math.pi / 2) else (if g.Dir[2] > 0 then math.pi else 0), 0), 7, 1.4)
		info(ctx, booth, "Puerta" .. g.Id, bx - g.Dir[1] * 4, bz - g.Dir[2] * 4, Street.WALK_TOP, "Hablar", "Policía militar")
		crowd(booth, "Muralla", bx - g.Dir[1] * 2 + px * 3, bz - g.Dir[2] * 2 + pz * 3, Street.WALK_TOP, inX, inZ, "Guard")
	end
end

---------------------------------------------------------------------
-- Edificios
---------------------------------------------------------------------
local function dome(ctx: Ctx, parent: Instance, b: TefraCity.Building)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local r = b.R or 10
	local rng = Tefra.rng(math.floor(math.abs(b.X * 13 + b.Z * 7)) + 5)
	local color = C.Plaster[1 + math.floor(rng() * #C.Plaster)]
	local shell = ball(m, "Cupula", W(b.X, b.Z, -r * 0.15), r * 2, color, Enum.Material.Plaster)
	-- Puerta y ventanas redondas hacia la calle más cercana
	local _, street = TefraCity.streetDistance(b.X, b.Z)
	local dir = if street.Axis == "X" then V3(0, 0, if street.At > b.Z then 1 else -1) else V3(if street.At > b.X then 1 else -1, 0, 0)
	local front = W(b.X, b.Z, 0) + dir * (r * 0.92)
	ball(m, "Puerta", front + V3(0, r * 0.12, 0), r * 0.42, C.Dark, Enum.Material.Slate, true)
	local side = V3(-dir.Z, 0, dir.X)
	for _, s in { -1, 1 } do
		local win = ball(m, "Ventana", W(b.X, b.Z, r * 0.42) + dir * (r * 0.62) + side * (s * r * 0.5), r * 0.22, rgb(70, 54, 60), Enum.Material.Glass, true)
		if not b.Broken then
			nightGlow(win, rgb(70, 54, 60))
		end
	end
	if b.Broken then
		-- Boquete quemado arriba y escombros redondeados
		ball(m, "Boquete", W(b.X, b.Z, r * 0.55) + side * (r * 0.3), r * 0.7, C.Crust, Enum.Material.CrackedLava, true)
		for k = 1, 3 do
			local a = rng() * math.pi * 2
			ball(m, "Escombro", W(b.X + math.cos(a) * (r + 3), b.Z + math.sin(a) * (r + 3), 0.5), 2 + rng() * 2.5, color, Enum.Material.Plaster)
		end
	else
		-- Chimenea redonda con humo de cocina (en una de cada dos)
		if rng() < 0.5 then
			local top = column(m, "Chimenea", W(b.X, b.Z, r * 0.6) - dir * (r * 0.3), r * 0.4, 2, C.Plaster[2], Enum.Material.Plaster, true)
			smoke(top, 0.6)
		end
	end
	m.PrimaryPart = shell
	Builder.streamable(m)
	return m
end

-- La casa de Cosme: solo el armazón de la cúpula (se entra andando), con la mesa quemada
local function skeleton(ctx: Ctx, parent: Instance, b: TefraCity.Building)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local r = b.R or 14
	Builder.part({
		Name = "Suelo",
		Shape = Enum.PartType.Cylinder,
		Size = V3(1, r * 2, r * 2),
		CFrame = CFrame.new(W(b.X, b.Z, 0.95)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = rgb(150, 130, 136),
		Material = Enum.Material.Limestone,
		Parent = m,
	})
	-- Costillas: 6 arcos de 5 tramos (de la base a la cima); dos están rotos
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local dirv = V3(math.cos(a), 0, math.sin(a))
		local segs = if k == 2 or k == 4 then 3 else 5
		for i = 0, segs - 1 do
			local p0 = i / 5 * math.pi / 2
			local p1 = (i + 1) / 5 * math.pi / 2
			local q0 = W(b.X, b.Z, 1) + dirv * (math.cos(p0) * r) + V3(0, math.sin(p0) * r * 0.85, 0)
			local q1 = W(b.X, b.Z, 1) + dirv * (math.cos(p1) * r) + V3(0, math.sin(p1) * r * 0.85, 0)
			local mid = (q0 + q1) / 2
			local len = (q1 - q0).Magnitude + 0.6
			local cf = CFrame.lookAt(mid, q1)
			Builder.part({ Name = "Costilla", Size = V3(1.2, 1.2, len), CFrame = cf, Color = rgb(120, 104, 110), Material = Enum.Material.Limestone, CanCollide = i == 0, Parent = m })
		end
	end
	-- Mesa de cocina quemada y una silla volcada
	box(m, "Mesa", b.X - 3, b.X + 3, b.Z - 2, b.Z + 2, 2.9, 3.4, rgb(54, 40, 34), Enum.Material.Wood)
	for _, q in { { -2.6, -1.6 }, { 2.6, -1.6 }, { -2.6, 1.6 }, { 2.6, 1.6 } } do
		box(m, "Pata", b.X + q[1] - 0.2, b.X + q[1] + 0.2, b.Z + q[2] - 0.2, b.Z + q[2] + 0.2, 1, 2.9, rgb(54, 40, 34), Enum.Material.Wood, true)
	end
	box(m, "Silla", b.X + 4, b.X + 6, b.Z + 1, b.Z + 3, 1, 1.6, rgb(60, 44, 36), Enum.Material.Wood, true)
	-- El marco de la puerta con las rayas de las alturas
	local _, street = TefraCity.streetDistance(b.X, b.Z)
	local dir = if street.Axis == "X" then V3(0, 0, if street.At > b.Z then 1 else -1) else V3(if street.At > b.X then 1 else -1, 0, 0)
	local door = W(b.X, b.Z, 0) + dir * r
	local cf = Builder.facing(door, dir)
	for _, s in { -1, 1 } do
		Builder.part({ Name = "Marco", Size = V3(0.8, 9, 0.8), CFrame = cf * CFrame.new(s * 3.2, 5.5, 0), Color = rgb(110, 84, 64), Material = Enum.Material.Wood, Parent = m })
	end
	Builder.decor({ Name = "Dintel", Size = V3(7.2, 0.8, 0.8), CFrame = cf * CFrame.new(0, 10.2, 0), Color = rgb(110, 84, 64), Material = Enum.Material.Wood, Parent = m })
	local marks = Builder.decor({ Name = "Rayas", Size = V3(0.2, 3, 0.85), CFrame = cf * CFrame.new(3.65, 4.5, 0), Color = rgb(110, 84, 64), Material = Enum.Material.Wood, Parent = m })
	Builder.sign(marks, "Cosme 8 · Ada 6", Enum.NormalId.Left, rgb(240, 230, 220))
	info(ctx, m, b.Id, door.X - O.X + dir.X * 2, door.Z - O.Z + dir.Z * 2, 1, "Mirar")
	Builder.streamable(m)
	return m
end

local function stall(ctx: Ctx, parent: Instance, b: TefraCity.Building, toward: Vector3)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local at = W(b.X, b.Z, 0.9)
	local dir = (toward - at) * V3(1, 0, 1)
	local cf = Builder.facing(at, if dir.Magnitude > 0.1 then dir.Unit else V3(0, 0, -1))
	local w, d = b.W or 8, b.D or 6
	local rng = Tefra.rng(math.floor(math.abs(b.X * 31 + b.Z * 17)) + 3)
	local cloth = C.Fabric[1 + math.floor(rng() * #C.Fabric)]
	Builder.part({ Name = "Mostrador", Size = V3(w, 3.4, 2), CFrame = cf * CFrame.new(0, 1.7, -d / 2 + 1), Color = rgb(88, 66, 54), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, s in { -1, 1 } do
		Builder.part({ Name = "Poste", Size = V3(0.5, 8, 0.5), CFrame = cf * CFrame.new(s * (w / 2 - 0.3), 4, d / 2 - 0.3), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
	end
	Builder.decor({ Name = "Toldo", Size = V3(w + 0.6, 0.25, d + 1), CFrame = cf * CFrame.new(0, 7.6, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color = cloth, Material = Enum.Material.Fabric, Parent = m })
	-- Género: cajas (latas, pan, piezas) y un farolillo
	for k = -1, 1 do
		Builder.decor({ Name = "Genero", Size = V3(1.6, 1, 1.2), CFrame = cf * CFrame.new(k * (w / 3), 3.9, -d / 2 + 1), Color = if rng() < 0.5 then rgb(170, 130, 70) else rgb(120, 110, 100), Material = Enum.Material.Metal, Parent = m })
	end
	local lamp = Builder.decor({ Name = "Farolillo", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, CFrame = cf * CFrame.new(w / 2 - 0.8, 6.6, d / 2 - 0.8), Color = rgb(255, 170, 90), Material = Enum.Material.Neon, Parent = m })
	if b.ShopId then
		light(lamp, rgb(255, 170, 90), 12, 1.2)
		-- Punto de compra (Services/ShopService: etiqueta Shop + ShopId). Sin «Atracar» (NoHeist)
		Builder.part({
			Name = "ShopEntrance",
			Size = V3(4, 5, 2),
			CFrame = cf * CFrame.new(0, 2.5, -d / 2 - 1.5),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Tags = { "Shop" },
			Attributes = { ShopId = b.ShopId, NoHeist = true },
			Parent = m,
		})
		plate(m, if b.ShopId == "TefraSopa" then "SOPA" else "DE TODO", cf * CFrame.new(0, 6.4, -d / 2 - 0.3), w * 0.6, 1.2)
	end
	m.PrimaryPart = m:FindFirstChild("Mostrador") :: BasePart
	return m
end

local function tank(ctx: Ctx, parent: Instance, b: TefraCity.Building)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local r, h = b.R or 8, b.Height or 20
	local water = b.Kind == "Agua"
	local body = column(m, "Cuerpo", W(b.X, b.Z, 0.9), h, r * 2, if water then rgb(70, 86, 100) else C.Rust, Enum.Material.CorrodedMetal)
	column(m, "Aro", W(b.X, b.Z, 0.9 + h * 0.3), 1, r * 2 + 0.6, C.Iron, Enum.Material.Metal, true)
	column(m, "Aro", W(b.X, b.Z, 0.9 + h * 0.7), 1, r * 2 + 0.6, C.Iron, Enum.Material.Metal, true)
	local top = column(m, "Tapa", W(b.X, b.Z, 0.9 + h), 1, r * 2 - 1, C.Iron, Enum.Material.Metal, true)
	if b.Kind == "Fabrica" then
		steam(top, 4)
		smoke(top, 1.2, true)
	end
	m.PrimaryPart = body
	Builder.streamable(m)
	return m
end

local function spire(ctx: Ctx, parent: Instance, b: TefraCity.Building)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local w, h = b.W or 30, b.Height or 100
	local base = box(m, "Base", b.X - w / 2, b.X + w / 2, b.Z - w / 2, b.Z + w / 2, 0.9, 14, C.Basalt, Enum.Material.Basalt)
	local y = 14
	local d = w * 0.7
	for k = 1, 4 do
		local seg = (h - 14) / 4
		column(m, "Torre", W(b.X, b.Z, y), seg, d, if k % 2 == 0 then C.Iron else rgb(60, 56, 62), Enum.Material.CorrodedMetal)
		y += seg
		d *= 0.7
	end
	-- La lente (aún apagada: un aro y un cristal que brilla poco) y la luz roja de aviso
	Builder.decor({ Name = "Lente", Shape = Enum.PartType.Cylinder, Size = V3(1.5, 14, 14), CFrame = CFrame.new(W(b.X, b.Z, y + 1)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(255, 150, 90), Material = Enum.Material.Glass, Transparency = 0.3, Reflectance = 0.3, Parent = m })
	local beacon = ball(m, "Aviso", W(b.X, b.Z, y + 3), 1.6, rgb(255, 60, 50), Enum.Material.Neon, true)
	light(beacon, rgb(255, 60, 50), 24, 2)
	-- Andamios (cuatro postes y dos pasarelas)
	for _, q in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		box(m, "Andamio", b.X + q[1] * (w / 2 + 2) - 0.4, b.X + q[1] * (w / 2 + 2) + 0.4, b.Z + q[2] * (w / 2 + 2) - 0.4, b.Z + q[2] * (w / 2 + 2) + 0.4, 0.9, 60, rgb(160, 120, 60), Enum.Material.Metal, true)
	end
	for _, hy in { 30, 58 } do
		box(m, "Pasarela", b.X - w / 2 - 3, b.X + w / 2 + 3, b.Z - w / 2 - 3, b.Z - w / 2 - 1, hy, hy + 0.5, rgb(160, 120, 60), Enum.Material.DiamondPlate, true)
	end
	plate(m, "PROHIBIDO EL PASO · OBRAS DEL EJÉRCITO", CFrame.new(W(b.X, b.Z - w / 2 - 0.2, 9)) , 20, 2)
	info(ctx, m, b.Id, b.X, b.Z - w / 2 - 6, 0.9, "Mirar")
	m.PrimaryPart = base
	Builder.streamable(m)
	return m
end

local function greenhouse(ctx: Ctx, parent: Instance, b: TefraCity.Building)
	local m = Builder.model(b.Id, parent)
	m:SetAttribute("TefraKind", b.Kind)
	local w, d, h = b.W or 40, b.D or 20, b.Height or 10
	local x0, x1, z0, z1 = b.X - w / 2, b.X + w / 2, b.Z - d / 2, b.Z + d / 2
	local glassProps = { Transparency = 0.55, Reflectance = 0.1 }
	local glassColor = rgb(200, 170, 160)
	-- Paredes de cristal (la de delante con la entrada abierta en el centro)
	box(m, "Cristal", x0, x1, z1 - 0.3, z1, 0.9, h, glassColor, Enum.Material.Glass, false, glassProps)
	box(m, "Cristal", x0, x0 + 0.3, z0, z1, 0.9, h, glassColor, Enum.Material.Glass, false, glassProps)
	box(m, "Cristal", x1 - 0.3, x1, z0, z1, 0.9, h, glassColor, Enum.Material.Glass, false, glassProps)
	box(m, "Cristal", x0, b.X - 4, z0, z0 + 0.3, 0.9, h, glassColor, Enum.Material.Glass, false, glassProps)
	box(m, "Cristal", b.X + 4, x1, z0, z0 + 0.3, 0.9, h, glassColor, Enum.Material.Glass, false, glassProps)
	box(m, "Techo", x0, x1, z0, z1, h, h + 0.3, glassColor, Enum.Material.Glass, true, glassProps)
	for _, x in { x0, b.X, x1 } do
		box(m, "Perfil", x - 0.3, x + 0.3, z0, z1, h + 0.3, h + 0.8, C.Iron, Enum.Material.Metal, true)
	end
	-- Bancales con setas de ceniza que brillan en naranja
	for k = -1, 1 do
		local cx = b.X + k * (w / 3.2)
		box(m, "Bancal", cx - 5, cx + 5, b.Z - 2, b.Z + 6, 0.9, 2.4, rgb(60, 50, 50), Enum.Material.Slate)
		for s = 0, 2 do
			local cap = ball(m, "Seta", W(cx - 3 + s * 3, b.Z + 2, 3.1), 1.4, rgb(255, 150, 70), Enum.Material.Neon, true)
			if k == 0 and s == 1 then
				light(cap, rgb(255, 150, 70), 18, 1)
			end
		end
	end
	plate(m, "SETAS DE CENIZA", CFrame.new(W(b.X, z0 - 0.2, h - 1.6)), 10, 1.4)
	m.PrimaryPart = m:FindFirstChild("Techo") :: BasePart
	Builder.streamable(m)
	return m
end

-- Edificio con planta baja jugable (Kit/Building) y lo de Tefra encima: cartel, cúpula del Tefra
-- antiguo o blindaje de esquinas, chimeneas de fundición con brasas
local function boxBuilding(ctx: Ctx, parent: Instance, b: TefraCity.Building): Model
	local yaw = YAW[b.Face or "N"]
	local cf = CF(b.X, b.Z, 0, yaw)
	local windowFaces = { Front = true, Back = (b.W or 0) > 40, Left = true, Right = false }
	local model, _at, info2 = Building.build({
		Name = b.Id,
		Parent = parent,
		CFrame = cf,
		Width = b.W or 20,
		Depth = b.D or 20,
		Floors = b.Floors or 1,
		Style = b.Style or "TefraBunker",
		GroundFloor = (b.Ground or "Lobby") :: any,
		ShopId = b.ShopId,
		Interior = true,
		WindowFaces = windowFaces,
		Balconies = false,
		FloorMaterial = Enum.Material.Slate,
		FloorColor = rgb(84, 76, 80),
		LightColor = rgb(255, 196, 140),
	})
	model:SetAttribute("TefraKind", b.Kind)
	local W2, D2 = b.W or 20, b.D or 20
	local top = info2.Top
	-- Cartel en la fachada (encima de la puerta)
	if b.Sign then
		plate(model, b.Sign, cf * CFrame.new(0, info2.GroundTop - 1.6, -D2 / 2 - 0.25), math.min(W2 * 0.7, 26), 2.4)
	end
	-- Sin «Atracar» en las tiendas de Tefra (Services/WantedService: NoHeist)
	local entrance = model:FindFirstChild("ShopEntrance")
	if entrance then
		entrance:SetAttribute("NoHeist", true)
	end
	if b.DomeRoof then
		-- La cúpula del Tefra antiguo encima (redonda: «nada tenía esquinas»)
		local r = math.min(W2, D2) * 0.42
		ball(model, "Cupula", (cf * CFrame.new(0, top - r * 0.35, 0)).Position, r * 2, C.Plaster[2], Enum.Material.Plaster, true)
	elseif b.Style == "TefraBunker" then
		-- Blindaje: chaflanes de chapa en las esquinas y una franja de luz de emergencia
		for _, sx in { -1, 1 } do
			Builder.decor({
				ClassName = "WedgePart",
				Name = "Blindaje",
				Size = V3(1.6, math.min(top, 14), 3),
				CFrame = cf * CFrame.new(sx * (W2 / 2 + 0.4), math.min(top, 14) / 2, -D2 / 2 + 1.5) * CFrame.Angles(0, if sx > 0 then 0 else math.pi, 0),
				Color = C.Rust,
				Material = Enum.Material.CorrodedMetal,
				Parent = model,
			})
		end
		Builder.decor({ Name = "Franja", Size = V3(W2, 0.4, 0.2), CFrame = cf * CFrame.new(0, top + 0.6, -D2 / 2 - 0.4), Color = rgb(255, 120, 40), Material = Enum.Material.Neon, Parent = model })
	elseif b.Style == "TefraFabrica" then
		-- Chimeneas de fundición (la de la esquina echa humo y brasas)
		local n = if W2 >= 80 then 3 else 2
		for k = 1, n do
			local x = (k - (n + 1) / 2) * (W2 / (n + 0.5))
			column(model, "Chimenea", (cf * CFrame.new(x, top, D2 / 4)).Position, 22, 4, rgb(60, 52, 52), Enum.Material.CorrodedMetal)
			local mouth = column(model, "Boca", (cf * CFrame.new(x, top + 21.5, D2 / 4)).Position, 0.6, 3.4, C.LavaHot, Enum.Material.Neon, true)
			if k == 1 then
				smoke(mouth, 1.2, true)
				embers(mouth, 3)
			end
		end
	end
	return model
end

---------------------------------------------------------------------
-- Sitios: la plaza del Mirador, el Campus, el mercado, el Muelle, la explanada, el cremallera
---------------------------------------------------------------------
local function tent(parent: Instance, lx: number, lz: number, yaw: number, color: Color3)
	local cf = CF(lx, lz, 0.9, yaw)
	for _, s in { -1, 1 } do
		Builder.part({ ClassName = "WedgePart", Name = "Lona", Size = V3(6, 4.6, 3.2), CFrame = cf * CFrame.new(0, 2.3, s * 1.6) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0), Color = color, Material = Enum.Material.Fabric, Parent = parent })
	end
	Builder.decor({ Name = "Entrada", Size = V3(0.2, 3, 2.4), CFrame = cf * CFrame.new(3.05, 1.5, 0), Color = C.Dark, Material = Enum.Material.Fabric, Parent = parent })
end

local function statue(ctx: Ctx, parent: Instance)
	local s = TefraCity.SpotById.Estatua
	local m = Builder.model("Tefra_EstatuaNilda", parent)
	local stone = rgb(176, 166, 170)
	box(m, "Pedestal", s.X - 4, s.X + 4, s.Z - 4, s.Z + 4, 0.9, 5, C.BasaltLight, Enum.Material.Basalt)
	box(m, "Placa", s.X - 2.5, s.X + 2.5, s.Z + 4, s.Z + 4.2, 2, 4, rgb(150, 110, 70), Enum.Material.Metal, true)
	local p = Builder.decor({ Name = "PlacaTexto", Size = V3(5, 2, 0.1), CFrame = CFrame.new(W(s.X, s.Z + 4.25, 3)) * CFrame.Angles(0, math.pi, 0), Transparency = 1, Parent = m })
	Builder.sign(p, "NILDA · «Todo es redondo si lo miras con calma»", Enum.NormalId.Front, rgb(255, 230, 200))
	-- La abuela, redondita como la gente de Tefra: cuerpo, cabeza, moño y bufanda de piedra
	column(m, "Cuerpo", W(s.X, s.Z, 5), 7, 5, stone, Enum.Material.Limestone)
	ball(m, "Hombros", W(s.X, s.Z, 12), 5.4, stone, Enum.Material.Limestone)
	ball(m, "Cabeza", W(s.X, s.Z, 15.2), 3.6, stone, Enum.Material.Limestone)
	ball(m, "Mono", W(s.X, s.Z - 1.4, 16.6), 1.8, stone, Enum.Material.Limestone, true)
	box(m, "Bufanda", s.X - 2.6, s.X + 2.6, s.Z - 2.2, s.Z + 2.2, 12.8, 13.8, rgb(160, 150, 156), Enum.Material.Limestone, true)
	box(m, "Punta", s.X + 1.2, s.X + 2.2, s.Z + 2.2, s.Z + 2.8, 9, 13.4, rgb(160, 150, 156), Enum.Material.Limestone, true)
	-- La flor de tela que alguien dejó
	ball(m, "Flor", W(s.X - 2, s.Z + 4.5, 5.3), 0.9, rgb(220, 120, 150), Enum.Material.Fabric, true)
	info(ctx, m, "Estatua", s.X, s.Z + 7, 0.9, "Mirar")
	return m
end

local function mirador(ctx: Ctx, folder: Instance)
	local b = TefraCity.BuildingById.Tefra_Mirador
	local m = Builder.model("Tefra_Mirador", folder)
	m:SetAttribute("TefraKind", "Plaza")
	table.insert(ctx.Areas, m)
	statue(ctx, m)
	-- El «lago templado»: un estanque de agua tibia con vapor
	local px, pz = 160, -125
	Builder.part({ Name = "Brocal", Shape = Enum.PartType.Cylinder, Size = V3(1.4, 22, 22), CFrame = CFrame.new(W(px, pz, 1.6)) * CFrame.Angles(0, 0, math.pi / 2), Color = C.BasaltLight, Material = Enum.Material.Basalt, Parent = m })
	local water = Builder.part({ Name = "Agua", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 19.6, 19.6), CFrame = CFrame.new(W(px, pz, 2.35)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(110, 150, 170), Material = Enum.Material.Glass, Transparency = 0.25, Reflectance = 0.2, Parent = m })
	steam(water, 3)
	-- Bancos alrededor de la estatua (la gente se sienta: CrowdService)
	Palette.withTheme("Tefra", function()
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2 + 0.3
			local q = W(160 + math.cos(a) * 16, -165 + math.sin(a) * 16, 0.9)
			Props.bench(m, Builder.facing(q, V3(math.cos(a), 0, math.sin(a))))
		end
		for _, q in { { 110, -210 }, { 210, -110 }, { 110, -110 } } do
			Props.lamp(m, Builder.facing(W(q[1], q[2], 0.9), V3(160 - q[1], 0, -160 - q[2])))
		end
	end)
	-- Las tiendas de los refugiados (oeste y norte de la plaza)
	local rng = Tefra.rng(2024)
	local k = 0
	for _, q in { { 112, -200 }, { 112, -186 }, { 112, -172 }, { 112, -150 }, { 112, -136 }, { 130, -212 }, { 146, -212 }, { 176, -212 }, { 190, -150 }, { 204, -150 } } do
		k += 1
		tent(m, q[1], q[2], if q[1] < 120 then 0 else math.pi / 2, C.Fabric[1 + math.floor(rng() * #C.Fabric)])
		if k % 3 == 1 then
			crowd(m, "Mirador", q[1] + 5, q[2] + 2, 0.9, 160, -160, "Knit", false)
		end
	end
	-- Una hoguera de las que se encienden de noche (luz cálida)
	local fire = ball(m, "Hoguera", W(140, -190, 1.4), 2, rgb(255, 140, 50), Enum.Material.Neon, true)
	light(fire, rgb(255, 150, 70), 22, 1.8)
	embers(fire, 4)
	-- La terraza: una plataforma de basalto con rampa, para ver por encima de la muralla
	local t = TefraCity.SpotById.Terraza
	box(m, "Terraza", t.X - 10, t.X + 10, t.Z - 10, t.Z + 10, 0.9, 14, C.Basalt, Enum.Material.Basalt)
	for _, side in { { t.X - 10, t.Z - 10, t.X + 10, t.Z - 10 }, { t.X + 10, t.Z - 10, t.X + 10, t.Z + 10 } } do
		parapet(m, side[1], side[2], side[3], side[4], 14)
	end
	Builder.part({
		ClassName = "WedgePart",
		Name = "Rampa",
		Size = V3(8, 13.1, 36),
		CFrame = CFrame.new(W(t.X - 6, t.Z + 10 + 18, 0.9 + 13.1 / 2)) * CFrame.Angles(0, math.pi, 0),
		Color = C.BasaltLight,
		Material = Enum.Material.Basalt,
		Parent = m,
	})
	info(ctx, m, "Terraza", t.X, t.Z, 14, "Mirar el lago")
	-- Cartel del Mirador (con su aviso)
	plate(m, "MIRADOR DE LAS LUNAS", CFrame.new(W(b.X - 52, b.Z + 52, 7)) * CFrame.Angles(0, math.pi * 0.75, 0), 10, 1.6)
	box(m, "Poste", b.X - 52.3, b.X - 51.7, b.Z + 51.7, b.Z + 52.3, 0.9, 6, C.Iron, Enum.Material.Metal, true)
	info(ctx, m, b.Id, b.X - 49, b.Z + 49, 0.9, "Mirar")
	crowd(m, "Mirador", 150, -128, 0.9, 160, -125, "Phone")
	crowd(m, "Mirador", 168, -135, 0.9, 160, -125, nil)
	crowd(m, "Mirador", 175, -175, 0.9, 160, -165, "Watch")
	return m
end

local function campus(ctx: Ctx, folder: Instance)
	local m = Builder.model("Tefra_CampusPatio", folder)
	table.insert(ctx.Areas, m)
	-- Los baños termales: piscina de agua caliente con vapor
	local x0, x1, z0, z1 = 172, 214, -52, -12
	for _, side in { { x0, x1, z0, z0 + 1 }, { x0, x1, z1 - 1, z1 }, { x0, x0 + 1, z0, z1 }, { x1 - 1, x1, z0, z1 } } do
		box(m, "Borde", side[1], side[2], side[3], side[4], 0.9, 2.2, C.BasaltLight, Enum.Material.Basalt)
	end
	local water = box(m, "Agua", x0 + 1, x1 - 1, z0 + 1, z1 - 1, 0.9, 1.7, rgb(120, 170, 180), Enum.Material.Glass, true, { Transparency = 0.3, Reflectance = 0.2 })
	steam(water, 5)
	local rng = Tefra.rng(99)
	tent(m, 150, -40, 0, C.Fabric[1 + math.floor(rng() * #C.Fabric)])
	tent(m, 150, -24, 0, C.Fabric[1 + math.floor(rng() * #C.Fabric)])
	tent(m, 150, 20, 0, C.Fabric[1 + math.floor(rng() * #C.Fabric)])
	Palette.withTheme("Tefra", function()
		Props.bench(m, Builder.facing(W(165, -58, 0.9), V3(0, 0, 1)))
		Props.bench(m, Builder.facing(W(190, -6, 0.9), V3(0, 0, -1)))
	end)
	crowd(m, "Campus", 145, 0, 0.9, 136, 0, "Clipboard")
	crowd(m, "Campus", 160, 48, 0.9, 166, 44, nil)
	crowd(m, "Campus", 162, 52, 0.9, 166, 44, "Phone")
	crowd(m, "Campus", 192, -58, 0.9, 192, -30, nil)
	return m
end

local function market(ctx: Ctx, folder: Instance)
	local m = Builder.model("Tefra_MercadoEspiral", folder)
	table.insert(ctx.Areas, m)
	local well = TefraCity.Wells[1]
	local center = W(well.X, well.Z, 0.9)
	for _, b in TefraCity.Buildings do
		if b.Shape == "Stall" and b.District == "Mercado" then
			stall(ctx, m, b, center)
		end
	end
	-- Cartel alto del mercado
	box(m, "Mastil", well.X + 40 - 0.4, well.X + 40 + 0.4, well.Z - 52 - 0.4, well.Z - 52 + 0.4, 0.9, 16, C.Iron, Enum.Material.Metal)
	plate(m, "MERCADO ESPIRAL", CFrame.new(W(well.X + 40, well.Z - 52, 15)) * CFrame.Angles(0, 0, 0), 14, 2.2)
	local rng = Tefra.rng(31337)
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2
		local r = 34 + rng() * 10
		crowd(m, "Mercado", well.X + math.cos(a) * r, well.Z + math.sin(a) * r, 0.9, well.X, well.Z, if k % 2 == 0 then "Carry" else nil)
	end
	return m
end

local function muelle(ctx: Ctx, folder: Instance)
	local m = Builder.model("Tefra_MuellePatio", folder)
	-- Camiones militares aparcados junto a la plataforma
	for _, q in { { -40, 44 }, { -26, 44 } } do
		local cf = CF(q[1], q[2], 0.45, 0)
		Builder.part({ Name = "Caja", Size = V3(8, 7, 14), CFrame = cf * CFrame.new(0, 4.6, 2), Color = C.Military, Material = Enum.Material.Fabric, Parent = m })
		Builder.part({ Name = "Cabina", Size = V3(8, 5.4, 5), CFrame = cf * CFrame.new(0, 3.8, -7.4), Color = C.Military, Material = Enum.Material.Metal, Parent = m })
		Builder.decor({ Name = "Parabrisas", Size = V3(6.6, 2, 0.2), CFrame = cf * CFrame.new(0, 5, -10), Color = rgb(60, 50, 46), Material = Enum.Material.Glass, Parent = m })
		for _, wx in { -4.2, 4.2 } do
			for _, wz in { -7, 5 } do
				Builder.decor({ Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = V3(1.6, 3.4, 3.4), CFrame = cf * CFrame.new(wx, 1.7, wz), Color = rgb(24, 22, 24), Material = Enum.Material.Rubber, Parent = m })
			end
		end
	end
	-- Control de entrada al Muelle
	box(m, "Garita", -56, -50, 48, 54, 0.45, 8.5, C.Military, Enum.Material.Metal)
	box(m, "Sacos", -40, -32, 56, 58.5, 0.45, 2.8, C.Sandbag, Enum.Material.Fabric)
	crowd(m, "Muelle", -46, 56, 0.45, -46, 80, "Guard")
	crowd(m, "Muelle", 20, -40, 0.45, 0, 0, "Clipboard")
	crowd(m, "Muelle", 12, -90, 0.9, 0, -80, "Guard")
	return m
end

local function explanada(ctx: Ctx, folder: Instance)
	local b = TefraCity.BuildingById.Tefra_Explanada
	local m = Builder.model("Tefra_Explanada", folder)
	table.insert(ctx.Areas, m)
	local w, d = b.W or 60, b.D or 40
	box(m, "Pista", b.X - w / 2, b.X + w / 2, b.Z - d / 2, b.Z + d / 2, 0.9, 0.95, rgb(84, 74, 78), Enum.Material.Slate, true)
	-- Líneas naranjas y dos porterías de chatarra
	box(m, "Linea", b.X - 0.3, b.X + 0.3, b.Z - d / 2, b.Z + d / 2, 0.95, 1, rgb(236, 140, 60), Enum.Material.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		local gx = b.X + s * (w / 2 - 1)
		box(m, "Poste", gx - 0.4, gx + 0.4, b.Z - 6.4, b.Z - 5.6, 0.9, 7, C.Rust, Enum.Material.CorrodedMetal)
		box(m, "Poste", gx - 0.4, gx + 0.4, b.Z + 5.6, b.Z + 6.4, 0.9, 7, C.Rust, Enum.Material.CorrodedMetal)
		box(m, "Larguero", gx - 0.4, gx + 0.4, b.Z - 6.4, b.Z + 6.4, 6.6, 7.4, C.Rust, Enum.Material.CorrodedMetal, true)
	end
	-- La pelota de ceniza (pesada: no rueda, de momento)
	ball(m, "Pelota", W(b.X + 6, b.Z + 3, 2), 2.2, rgb(110, 100, 104), Enum.Material.Basalt)
	info(ctx, m, b.Id, b.X, b.Z + d / 2 + 3, 0.9, "Mirar")
	crowd(m, "Muralla", b.X - 10, b.Z - 8, 0.9, b.X, b.Z, nil)
	crowd(m, "Muralla", b.X + 14, b.Z + 6, 0.9, b.X, b.Z, nil)
	return m
end

local function cremallera(ctx: Ctx, folder: Instance)
	local m = Builder.model("Tefra_Cremallera", folder)
	local z = 326
	for _, s in { -1, 1 } do
		box(m, "Rail", -216, -104, z + s * 2.4 - 0.25, z + s * 2.4 + 0.25, 0.9, 1.5, C.Iron, Enum.Material.Metal)
	end
	box(m, "Cremallera", -216, -104, z - 0.3, z + 0.3, 0.9, 1.8, rgb(90, 80, 70), Enum.Material.DiamondPlate, true)
	for x = -212, -108, 13 do
		box(m, "Traviesa", x - 1, x + 1, z - 3.6, z + 3.6, 0.9, 1.2, rgb(60, 48, 40), Enum.Material.Wood, true)
	end
	-- El vagón blindado (parado: «hoy no hay servicio»)
	local cf = CF(-160, z, 1.8, math.pi / 2)
	Builder.part({ Name = "Vagon", Size = V3(9, 9, 36), CFrame = cf * CFrame.new(0, 5, 0), Color = C.Military, Material = Enum.Material.CorrodedMetal, Parent = m })
	Builder.decor({ Name = "Techo", Size = V3(9.6, 1, 37), CFrame = cf * CFrame.new(0, 10, 0), Color = C.Iron, Material = Enum.Material.Metal, Parent = m })
	for _, s in { -1, 1 } do
		local slit = Builder.decor({ Name = "Troneras", Size = V3(0.2, 1, 28), CFrame = cf * CFrame.new(s * 4.55, 7, 0), Color = rgb(70, 54, 46), Material = Enum.Material.Glass, Parent = m })
		nightGlow(slit, rgb(70, 54, 46))
	end
	return m
end

local function pozos(ctx: Ctx, folder: Instance)
	local m = Builder.model("Tefra_PozosPatio", folder)
	-- Tuberías de la central a las torres de vapor y al pozo de magma
	for _, x in { -35, 0, 35 } do
		Builder.part({ Name = "Tuberia", Shape = Enum.PartType.Cylinder, Size = V3(37, 2.4, 2.4), CFrame = CFrame.new(W(x, 158.5, 4)) * CFrame.Angles(0, math.pi / 2, 0), Color = C.Rust, Material = Enum.Material.CorrodedMetal, Parent = m })
	end
	-- Fumarolas en la explanada de la central (humo y brasas: el calor del suelo)
	for _, q in { { 52, 200 }, { -55, 210 }, { -320, 160 } } do
		local vent = ball(m, "Fumarola", W(q[1], q[2], 1), 5, C.Crust, Enum.Material.CrackedLava, true)
		smoke(vent, 1.5)
		embers(vent, 2)
		light(vent, C.Lava, 16, 1.2)
	end
	-- La cola del agua (Depósito)
	local dep = TefraCity.BuildingById.Tefra_Deposito
	for k = 0, 4 do
		crowd(m, "Agua", dep.X - 18 - k * 2.6, dep.Z + 2, 0.9, dep.X, dep.Z, if k == 0 then "Carry" else nil)
	end
	if dep.Info then
		info(ctx, m, dep.Id, dep.X - 16, dep.Z - 4, 0.9, "Mirar")
	end
	crowd(m, "Pozos", 0, 98, 0.9, 0, 80, "Clipboard")
	return m
end

---------------------------------------------------------------------
-- Construir
---------------------------------------------------------------------
-- Sube todas las piezas dy studs (de Y = 0 a la meseta)
local function lift(model: Instance, dy: number)
	local offset = V3(0, dy, 0)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = d.CFrame + offset
		end
	end
	if model:IsA("Model") then
		pcall(function()
			model.WorldPivot = model.WorldPivot + offset
		end)
	end
end

function TefraCityBuilder.build(parent: Instance, prompt: (Instance, string, string, string, string, number?) -> ProximityPrompt, opts: { Yield: (() -> ())?, Base: number? }?): (Model, { [string]: any })
	local o = opts or {}
	local yield = o.Yield or function() end
	local base = o.Base or (Tefra.Origin.Y + Tefra.padY())
	local model = Instance.new("Model")
	model.Name = "Ciudad"
	model:SetAttribute("City", TefraCity.Name)
	local ctx: Ctx = { Model = model, Prompt = prompt, Infos = 0, Areas = {} }
	local stats: { [string]: any } = { Buildings = 0 }

	-- Calles (Kit/Street con los colores de Tefra), en coordenadas del mundo
	local roads = {}
	for _, s in TefraCity.Streets do
		local r = table.clone(s)
		if s.Axis == "X" then
			r.At = O.Z + s.At
			r.From, r.To = O.X + s.From, O.X + s.To
		else
			r.At = O.X + s.At
			r.From, r.To = O.Z + s.From, O.Z + s.To
		end
		table.insert(roads, r)
	end
	Palette.withTheme("Tefra", function()
		Street.build(model, roads)
	end)
	yield()
	grounds(ctx, model)
	canal(ctx, model)
	wells(ctx, model)
	moat(ctx, model)
	wall(ctx, model)
	yield()
	local buildings = Builder.model("Edificios", model)
	for _, b in TefraCity.Buildings do
		local built: Instance? = nil
		if b.Shape == "Box" then
			built = boxBuilding(ctx, buildings, b)
		elseif b.Shape == "Dome" then
			built = dome(ctx, buildings, b)
		elseif b.Shape == "Skeleton" then
			built = skeleton(ctx, buildings, b)
		elseif b.Shape == "Tank" then
			built = tank(ctx, buildings, b)
		elseif b.Shape == "Spire" then
			built = spire(ctx, buildings, b)
		elseif b.Shape == "Greenhouse" then
			built = greenhouse(ctx, buildings, b)
		elseif b.Shape == "Stall" and b.District ~= "Mercado" then
			built = stall(ctx, buildings, b, W(b.X, b.Z - 10, 0.9))
		end
		if built then
			stats.Buildings += 1
			if b.Info and b.Shape == "Box" then
				local dx, dz, f = TefraCity.door(b)
				if dx and f then
					info(ctx, built, b.Id, dx + f[1] * 3 + f[2] * 4, dz + f[2] * 3 + f[1] * 4, 0.9, "Mirar")
				end
			end
		end
		if stats.Buildings % 6 == 0 then
			yield()
		end
	end
	mirador(ctx, model)
	campus(ctx, model)
	market(ctx, model)
	muelle(ctx, model)
	explanada(ctx, model)
	cremallera(ctx, model)
	pozos(ctx, model)
	-- Gente a la puerta de la panadería (el pan se reparte al amanecer) y del hospital
	local pan = TefraCity.BuildingById.Tefra_Panaderia
	for k = 0, 3 do
		crowd(model, "Ovillo", pan.X - 8 + k * 3, pan.Z + pan.D / 2 + 8, Street.WALK_TOP, pan.X, pan.Z, if k == 0 then "Carry" else nil)
	end
	yield()

	-- Las papeleras de las farolas (Kit/Street) son de adorno: el basurero de Valmar (GarbageService) no
	-- viene hasta Tefra
	for _, d in model:GetDescendants() do
		if d:HasTag("Papelera") then
			d:RemoveTag("Papelera")
		end
	end
	-- A la altura de la meseta
	lift(model, base)
	local parts = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	stats.Parts = parts
	stats.Infos = ctx.Infos
	stats.Areas = ctx.Areas
	model.Parent = parent
	return model, stats
end

return TefraCityBuilder
