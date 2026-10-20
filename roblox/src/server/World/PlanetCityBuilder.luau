-- PlanetCityBuilder (servidor): construye el barrio de la capital de un planeta con su plano
-- (shared/Cosmos/PlanetCity) y su KIT (marco común de los planetas, docs/planetas/marco-planetas.md).
-- Lo llama World/PlanetWorld la primera vez que alguien se acerca al planeta (nada de esto está en el
-- archivo del juego). Bastión Ceniza (Tefra) tiene su propio constructor a mano: World/TefraCityBuilder.
--
-- Lo común (para todos los planetas):
--   * Suelos (plan.Floors: losas y plataformas), calles de Kit/Street (plan.Streets, con el tema de
--     Kit/Palette del planeta si tiene: plan.Theme), edificios Box de Kit/Building (planta baja jugable,
--     su puerta, ventanas que se encienden de noche) con los estilos del planeta (Kit/Palette.Styles).
--   * Farolas (StreetLamp: WorldService las enciende de noche), bancos (Bench), marcas de gente
--     (CrowdSpot, grupo «<Planeta>_…»), zonas de paseo (CrowdService.addArea), los avisos «Mirar» de los
--     sitios con texto (tipo "City"), los de recoger el material del planeta (tipo "Gather"), las marcas
--     de la historia (StorySpot «<Planeta>_<Id>») y los tablones «Trabajar» de sus oficios (PlanetJobs).
-- Lo de cada planeta lo pone su KIT (World/<S.Kit>, opcional): kit.Colors, kit.lamp(ctx, parent, cf),
-- kit.Shapes[Shape](ctx, parent, b) (formas que no son Box: discos, torres, cúpulas…), kit.floor(ctx,
-- parent, f) (un suelo especial), kit.pit(ctx, parent, p) (lo que se ve en un hueco: niebla, lava…) y
-- kit.extras(ctx, model) (el monumento, los toldos, los cables…). Todo se monta a Y = 0 y al final se
-- sube a la meseta (Base = S.padY()), como World/TefraCityBuilder.
--
-- API: PlanetCityBuilder.build(parent, prompt, S, opts?) → (modelo, resumen { Parts, Buildings, Areas, … })
--      PlanetCityBuilder.helpers(S) → (W, CF, box, ball, column, light) para los kits

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)
local Street = require(script.Parent.Kit.Street)
local Building = require(script.Parent.Kit.Building)
local Props = require(script.Parent.Kit.Props)
local PlanetJobs = require(ReplicatedStorage.Shared.Cosmos.PlanetJobs)

local PlanetCityBuilder = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local YAW = { N = 0, S = math.pi, E = -math.pi / 2, W = math.pi / 2 }
PlanetCityBuilder.Yaw = YAW
PlanetCityBuilder.FloorTop = 0.9 -- (lo de encima de los suelos: como la acera de Kit/Street)

export type Ctx = {
	S: any,
	City: any,
	Kit: any,
	Model: Model,
	Prompt: (Instance, string, string, string, string, number?) -> ProximityPrompt,
	Infos: number,
	Areas: { Instance },
	W: (number, number, number?) -> Vector3,
	CF: (number, number, number?, number?) -> CFrame,
	box: (Instance, string, number, number, number, number, number, number, Color3, Enum.Material, boolean?, { [string]: any }?) -> BasePart,
	ball: (Instance, string, Vector3, number, Color3, Enum.Material, boolean?) -> BasePart,
	column: (Instance, string, Vector3, number, number, Color3, Enum.Material, boolean?) -> BasePart,
	light: (Instance, Color3, number, number) -> (),
	crowd: (Instance, string, number, number, number, number, number, string?, boolean?) -> (),
	info: (Instance, string, number, number, number, string?, string?) -> (),
	sign: (Instance, string, CFrame, number, number, Color3?, Color3?) -> BasePart,
}

-- Las herramientas de dibujo en coordenadas locales del planeta (las usan los kits)
function PlanetCityBuilder.helpers(S: any): { [string]: any }
	local O = S.Origin
	local h: { [string]: any } = {}
	function h.W(lx: number, lz: number, y: number?): Vector3
		return V3(O.X + lx, y or 0, O.Z + lz)
	end
	function h.CF(lx: number, lz: number, y: number?, yaw: number?): CFrame
		return CFrame.new(h.W(lx, lz, y)) * CFrame.Angles(0, yaw or 0, 0)
	end
	function h.box(parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, color: Color3, material: Enum.Material, decor: boolean?, extra: { [string]: any }?): BasePart
		local props: { [string]: any } = {
			Name = name,
			Size = V3(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
			CFrame = CFrame.new(h.W((x0 + x1) / 2, (z0 + z1) / 2, (y0 + y1) / 2)),
			Color = color,
			Material = material,
			Parent = parent,
		}
		for k, v in extra or {} do
			props[k] = v
		end
		return if decor then Builder.decor(props) else Builder.part(props)
	end
	function h.ball(parent: Instance, name: string, at: Vector3, size: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart
		local props = { Name = name, Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = CFrame.new(at), Color = color, Material = material, Parent = parent }
		return if decor then Builder.decor(props) else Builder.part(props)
	end
	-- Cilindro de pie (eje Y) con la base en at
	function h.column(parent: Instance, name: string, at: Vector3, height: number, diameter: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart
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
	function h.light(parent: Instance, color: Color3, range: number, brightness: number)
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = range
		l.Brightness = brightness
		l.Shadows = false
		l.Parent = parent
	end
	return h
end

local function nightGlow(part: BasePart, day: Color3, night: Color3)
	part:AddTag("NightWindow")
	part:SetAttribute("DayColor", day)
	Building.nightSchedule(part, night, 17.6, 20.5, 22.5, 26)
end
PlanetCityBuilder.nightGlow = nightGlow

-- Farola sencilla del marco (si el kit no trae la suya): poste, cabeza y bombilla StreetLamp
local function defaultLamp(ctx: Ctx, parent: Instance, cf: CFrame)
	local colors = ctx.Kit.Colors or {}
	local metal = colors.Metal or rgb(60, 60, 64)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Pie", Size = V3(1, 0.8, 1), CFrame = cf * CFrame.new(0, 0.4, 0), Color = metal, Material = Enum.Material.Metal, Parent = m })
	Builder.part({ Name = "Poste", Shape = Enum.PartType.Cylinder, Size = V3(10, 0.45, 0.45), CFrame = cf * CFrame.new(0, 5.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = metal, Material = Enum.Material.Metal, Parent = m })
	local bulb = Builder.decor({ Name = "Bombilla", Size = V3(1.3, 1.3, 1.3), CFrame = cf * CFrame.new(0, 10.8, 0), Color = colors.Lamp or rgb(255, 214, 160), Material = Enum.Material.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 1.6
	light.Color = colors.Lamp or rgb(255, 214, 160)
	light.Shadows = false
	light.Enabled = false
	light.Parent = bulb
	return m
end

-- Un edificio Box (Kit/Building) con su cartel; el kit puede añadirle lo suyo (kit.dressBox)
local function boxBuilding(ctx: Ctx, parent: Instance, b: { [string]: any }): Model
	local yaw = YAW[b.Face or "N"]
	local cf = ctx.CF(b.X, b.Z, 0, yaw)
	local colors = ctx.Kit.Colors or {}
	local model, _at, info2 = Building.build({
		Name = b.Id,
		Parent = parent,
		CFrame = cf,
		Width = b.W or 20,
		Depth = b.D or 20,
		Floors = b.Floors or 1,
		Style = b.Style or "Moderno",
		GroundFloor = (b.Ground or "Lobby") :: any,
		ShopId = b.ShopId,
		Interior = true,
		WindowFaces = { Front = true, Back = (b.W or 0) > 40, Left = true, Right = false },
		Balconies = false,
		FloorMaterial = colors.FloorMaterial or Enum.Material.Slate,
		FloorColor = colors.Floor or rgb(90, 86, 84),
		LightColor = colors.Light or rgb(255, 210, 160),
	})
	model:SetAttribute("PlanetKind", b.Kind)
	if b.Sign then
		ctx.sign(model, b.Sign, cf * CFrame.new(0, info2.GroundTop - 1.6, -(b.D or 20) / 2 - 0.25), math.min((b.W or 20) * 0.7, 24), 2.2)
	end
	local entrance = model:FindFirstChild("ShopEntrance")
	if entrance then
		entrance:SetAttribute("NoHeist", true) -- (allí no hay policía de Valmar que te persiga)
	end
	if ctx.Kit.dressBox then
		ctx.Kit.dressBox(ctx, model, b, cf, info2)
	end
	return model
end

-- Bloque macizo sencillo (si el kit no sabe dibujar la forma)
local function blockShape(ctx: Ctx, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local colors = ctx.Kit.Colors or {}
	ctx.box(m, "Cuerpo", x0, x1, z0, z1, 0, ctx.City.topOf(b), colors.Wall or rgb(150, 140, 130), Enum.Material.Concrete)
	return m
end

local function storySpot(parent: Instance, prefix: string, planet: string, s: { [string]: any }, at: Vector3)
	Builder.part({
		Name = "StorySpot_" .. s.Id,
		Size = V3(4, 5, 4),
		CFrame = CFrame.new(at + V3(0, 2.5, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Tags = { "StorySpot" },
		Attributes = { SpotId = prefix .. s.Id, Planet = planet },
		Parent = parent,
	})
end

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

local function loadKit(S: any): any
	if type(S.Kit) == "table" then
		return S.Kit
	end
	if type(S.Kit) == "string" then
		local ok, kit = pcall(function()
			return require((script.Parent :: any)[S.Kit])
		end)
		if ok and type(kit) == "table" then
			return kit
		end
		warn("[PlanetCityBuilder] kit " .. S.Kit .. ": " .. tostring(kit))
	end
	return {}
end
PlanetCityBuilder.loadKit = loadKit

function PlanetCityBuilder.build(parent: Instance, prompt: (Instance, string, string, string, string, number?) -> ProximityPrompt, S: any, opts: { Yield: (() -> ())?, Base: number?, Kit: any? }?): (Model, { [string]: any })
	local o = opts or {}
	local yield = o.Yield or function() end
	local City = S.City
	local kit = o.Kit or loadKit(S)
	local base = o.Base or (S.Origin.Y + S.padY())
	local prefix = City.KeyPrefix
	local model = Instance.new("Model")
	model.Name = "Ciudad"
	model:SetAttribute("City", City.Name)
	model:SetAttribute("Planet", S.Id)
	local h = PlanetCityBuilder.helpers(S)
	local ctx: Ctx = {
		S = S,
		City = City,
		Kit = kit,
		Model = model,
		Prompt = prompt,
		Infos = 0,
		Areas = {},
		W = h.W,
		CF = h.CF,
		box = h.box,
		ball = h.ball,
		column = h.column,
		light = h.light,
	} :: any
	local colors = kit.Colors or {}
	local FT = PlanetCityBuilder.FloorTop

	function ctx.crowd(p: Instance, group: string, lx: number, lz: number, floor: number, fx: number, fz: number, work: string?, sit: boolean?)
		local at = h.W(lx, lz, floor + 2.5)
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
			Attributes = { Group = prefix .. group, Work = work, Pose = if sit then "Sit" else nil },
			Parent = p,
		})
	end
	function ctx.info(p: Instance, id: string, lx: number, lz: number, y: number, action: string?, object: string?)
		local anchor = Builder.part({
			Name = "AvisoCiudad",
			Size = V3(3, 4, 3),
			CFrame = CFrame.new(h.W(lx, lz, y + 2)),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = p,
		})
		local spot = City.SpotById[id] or City.BuildingById[id]
		prompt(anchor, "City", id, action or "Mirar", object or (spot and spot.Name) or City.Name, 0.3)
		ctx.Infos += 1
	end
	function ctx.sign(p: Instance, text: string, cf: CFrame, w: number, hh: number, color: Color3?, textColor: Color3?): BasePart
		local plate = Builder.decor({ Name = "Cartel", Size = V3(w, hh, 0.3), CFrame = cf, Color = color or colors.Sign or rgb(30, 28, 30), Material = Enum.Material.Metal, Parent = p })
		Builder.sign(plate, text, Enum.NormalId.Front, textColor or colors.SignText or rgb(255, 214, 140))
		return plate
	end
	local stats: { [string]: any } = { Buildings = 0 }

	-- Suelos (losas, plataformas) y lo que se ve en los huecos
	local floors = Builder.model("Suelos", model)
	for _, f in City.Floors do
		if kit.floor and kit.floor(ctx, floors, f) then
			continue
		end
		local color = f.Color or colors.Floor or rgb(120, 116, 110)
		local material = f.Material or Enum.Material.Slate
		if f.Kind == "Disc" then
			h.column(floors, f.Id or "Suelo", h.W(f.X, f.Z, Street.BASE), FT - Street.BASE, f.R * 2, color, material)
		else
			h.box(floors, f.Id or "Suelo", f.X0, f.X1, f.Z0, f.Z1, Street.BASE, FT, color, material)
		end
	end
	for _, p in City.Pits do
		if kit.pit then
			kit.pit(ctx, floors, p)
		end
	end
	-- Calles (Kit/Street, con el tema del planeta si tiene)
	if #City.Streets > 0 then
		local O = S.Origin
		local roads = {}
		for _, s in City.Streets do
			local r = table.clone(s)
			r.NoSignals = true
			if s.Axis == "X" then
				r.At = O.Z + s.At
				r.From, r.To = O.X + s.From, O.X + s.To
			else
				r.At = O.X + s.At
				r.From, r.To = O.Z + s.From, O.Z + s.To
			end
			table.insert(roads, r)
		end
		if City.Theme and Palette.Themes[City.Theme] then
			Palette.withTheme(City.Theme, function()
				Street.build(model, roads)
			end)
		else
			Street.build(model, roads)
		end
	end
	yield()

	-- Edificios
	local buildings = Builder.model("Edificios", model)
	for _, b in City.Buildings do
		local built: Instance? = nil
		if b.Shape == "Box" then
			built = boxBuilding(ctx, buildings, b)
		elseif b.Shape ~= "Court" then
			local shape = kit.Shapes and kit.Shapes[b.Shape]
			built = if shape then shape(ctx, buildings, b) else blockShape(ctx, buildings, b)
		end
		if built then
			stats.Buildings += 1
			if b.Info then
				local dx, dz, f = City.door(b)
				if dx and f then
					ctx.info(built, b.Id, dx + f[1] * 3 + f[2] * 4, dz + f[2] * 3 + f[1] * 4, FT, "Mirar")
				else
					local x0, x1, _z0, z1 = City.footprint(b)
					ctx.info(built, b.Id, (x0 + x1) / 2, z1 + 3, FT, "Mirar")
				end
			end
		end
		if stats.Buildings % 4 == 0 then
			yield()
		end
	end
	-- Sitios con texto («Mirar»)
	local sites = Builder.model("Sitios", model)
	for _, s in City.Spots do
		if s.Info then
			ctx.info(sites, s.Id, s.X, s.Z, s.Y or FT, s.Action or "Mirar")
		end
	end
	-- Farolas, bancos y gente
	local street = Builder.model("Calle", model)
	for _, l in City.Lamps do
		local cf = h.CF(l.X, l.Z, FT, l.Yaw or 0)
		if kit.lamp then
			kit.lamp(ctx, street, cf)
		else
			defaultLamp(ctx, street, cf)
		end
	end
	for _, bn in City.Benches or {} do
		Props.bench(street, h.CF(bn.X, bn.Z, FT, bn.Yaw or 0))
	end
	for _, c in City.Crowd do
		ctx.crowd(street, c.Group or "Plaza", c.X, c.Z, FT, c.FX or c.X, c.FZ or (c.Z - 1), c.Work, c.Sit)
	end
	for i, a in City.Areas do
		local area = Builder.model("Paseo" .. i, model)
		h.box(area, "SueloPaseo", a.X0, a.X1, a.Z0, a.Z1, FT - 0.05, FT, colors.Floor or rgb(120, 116, 110), Enum.Material.Slate, true, { Transparency = 1 })
		h.box(area, "AltoPaseo", a.X0 + 1, a.X0 + 2, a.Z0 + 1, a.Z0 + 2, FT, FT + 6, colors.Floor or rgb(120, 116, 110), Enum.Material.Slate, true, { Transparency = 1 })
		table.insert(ctx.Areas, area)
	end
	-- Recoger el material del planeta
	local gather = Builder.model("Recoger", model)
	for _, g in City.Gather do
		local anchor = Builder.part({
			Name = "Recoger_" .. g.Id,
			Size = V3(3, 4, 3),
			CFrame = CFrame.new(h.W(g.X, g.Z, FT + 2)),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = gather,
		})
		if kit.gather then
			kit.gather(ctx, gather, g)
		end
		prompt(anchor, "Gather", g.Id, g.Action or "Recoger", g.Name, 0.6)
	end
	-- Los tablones «Trabajar» de los oficios del planeta
	local jobs = Builder.model("Oficios", model)
	for _, job in PlanetJobs.of(S.Id) do
		if job.Board then
			local dir = if job.BoardFace then V3(job.BoardFace[1], 0, job.BoardFace[2]) else V3(0, 0, -1)
			Props.jobBoard(jobs, Builder.facing(h.W(job.Board[1], job.Board[2], FT), dir), job.Id, job.Icon .. " " .. job.Name)
		end
	end
	-- Las marcas de la historia (dentro del barrio)
	local marks = Builder.model("Historia", model)
	for _, s in City.StorySpots do
		if not s.Outside then
			storySpot(marks, prefix, S.Id, s, h.W(s.X, s.Z, s.Y or FT))
		end
	end
	-- Lo propio del planeta (el monumento, los toldos, los cables…)
	if kit.extras then
		kit.extras(ctx, model)
	end
	yield()

	-- (las papeleras de Kit/Street son de adorno: el basurero de Valmar no llega a los planetas)
	for _, d in model:GetDescendants() do
		if d:HasTag("Papelera") then
			d:RemoveTag("Papelera")
		end
	end
	lift(model, base)
	-- Las marcas de fuera del barrio: en el suelo del planeta
	local outside = parent:FindFirstChild("HistoriaFuera") or Builder.model("HistoriaFuera", parent)
	for _, s in City.StorySpots do
		if s.Outside and not outside:FindFirstChild("StorySpot_" .. s.Id) then
			local wx, wz = S.Origin.X + s.X, S.Origin.Z + s.Z
			storySpot(outside, prefix, S.Id, s, V3(wx, (S.groundAt(wx, wz)), wz))
		end
	end
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

return PlanetCityBuilder
