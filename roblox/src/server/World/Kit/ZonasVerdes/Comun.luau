-- Comun: herramientas que comparten los sitios de las zonas verdes (Parques, Plaza, Huertos, Lago).
--
--   Comun.site(world, name, id)     el Model del sitio (en la carpeta «ZonasVerdes», con ZoneId y
--                                   streaming atómico: con StreamingEnabled llega entero o no llega)
--   Comun.ground(m, cf, w, d, top)  el césped del sitio (una pieza, top = altura de la superficie)
--   Comun.path(m, a, b, width, y)   camino de tierra o losa (adorno plano)
--   Comun.prune(roots, rects)       quita los árboles (y otros modelos sueltos) que caen encima
--   Comun.lantern(m, cf)            farolillo con luz de noche (StreetLamp: lo enciende WorldService)
--   Comun.sign(m, cf, text, color)  cartel con dos postes
-- Sin math.random.

local Builder = require(script.Parent.Parent.Parent.Builder)

local Comun = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

export type Rect = { X0: number, X1: number, Z0: number, Z1: number }

local function folderOf(world: Instance): Instance
	local f = world:FindFirstChild("ZonasVerdes")
	if not f then
		f = Builder.model("ZonasVerdes", world)
	end
	return f :: Instance
end
Comun.folderOf = folderOf

function Comun.site(world: Instance, name: string, id: number | string): Model
	local m = Builder.model(name, folderOf(world))
	m:SetAttribute("ZoneId", id)
	m:AddTag("ZonaVerde")
	Builder.streamable(m)
	return m
end

function Comun.ground(m: Instance, cf: CFrame, w: number, d: number, top: number?, color: Color3?, material: Enum.Material?): BasePart
	local y = top or 0
	return Builder.part({
		Name = "SueloZonaVerde",
		Size = V(w, 1.2, d),
		CFrame = CF(cf.Position.X, y - 0.6, cf.Position.Z) * (cf - cf.Position),
		Color = color or rgb(98, 150, 72),
		Material = material or Enum.Material.Grass,
		CastShadow = false,
		Parent = m,
	})
end

function Comun.path(m: Instance, a: Vector3, b: Vector3, width: number, y: number, color: Color3?, material: Enum.Material?): BasePart
	local mid = (a + b) / 2
	local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	return Builder.decor({
		Name = "Camino",
		Size = V(width, 0.12, dir.Magnitude),
		CFrame = Builder.facing(Vector3.new(mid.X, y + 0.06, mid.Z), dir),
		Color = color or rgb(196, 176, 140),
		Material = material or Enum.Material.Pavement,
		Parent = m,
	})
end

-- Dónde está un modelo (su pieza principal o la primera que tenga)
local function positionOf(model: Instance): Vector3?
	local primary = (model :: any).PrimaryPart
	if primary then
		return primary.CFrame.Position
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			return d.CFrame.Position
		end
	end
	return nil
end
Comun.positionOf = positionOf

local KEEP = { Bench = true, BancoCalle = true, Jardinera = true }

-- Quita los modelos sueltos (árboles, arbustos…) que tienen el pie dentro de algún rectángulo.
-- roots: carpetas o modelos en los que buscar (solo sus hijos directos). Devuelve cuántos ha quitado.
function Comun.prune(roots: { Instance }, rects: { Rect }, margin: number?): number
	local mg = margin or 2
	local removed = 0
	for _, root in roots do
		for _, child in root:GetChildren() do
			if child:IsA("Model") and not KEEP[child.Name] and not child:HasTag("ZonaVerde") then
				local p = positionOf(child)
				if p then
					for _, r in rects do
						if p.X > r.X0 - mg and p.X < r.X1 + mg and p.Z > r.Z0 - mg and p.Z < r.Z1 + mg then
							child:Destroy()
							removed += 1
							break
						end
					end
				end
			end
		end
	end
	return removed
end

-- Rectángulo (en planta) de un trozo de w × d alrededor de cf
function Comun.rect(cf: CFrame, w: number, d: number): Rect
	local xs, zs = {}, {}
	for _, sx in { -0.5, 0.5 } do
		for _, sz in { -0.5, 0.5 } do
			local p = cf * V(w * sx, 0, d * sz)
			table.insert(xs, p.X)
			table.insert(zs, p.Z)
		end
	end
	return { X0 = math.min(table.unpack(xs)), X1 = math.max(table.unpack(xs)), Z0 = math.min(table.unpack(zs)), Z1 = math.max(table.unpack(zs)) }
end

function Comun.lantern(m: Instance, cf: CFrame)
	Builder.part({ Name = "PosteFarol", Size = V(0.4, 7, 0.4), CFrame = cf * CF(0, 3.5, 0), Color = rgb(50, 54, 60), Material = Enum.Material.Metal, Parent = m })
	local glass = Builder.decor({ Name = "Farol", Size = V(1.2, 1.4, 1.2), CFrame = cf * CF(0, 7.6, 0), Color = rgb(255, 214, 140), Material = Enum.Material.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m }) -- (se enciende de noche como las farolas: WorldService)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 200, 130)
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = glass
end

function Comun.sign(m: Instance, cf: CFrame, text: string, color: Color3?, width: number?)
	local w = width or 12
	for _, x in { -w / 2 + 0.5, w / 2 - 0.5 } do
		Builder.decor({ Name = "PosteCartel", Size = V(0.4, 5, 0.4), CFrame = cf * CF(x, 2.5, 0), Color = rgb(104, 76, 52), Material = Enum.Material.Wood, Parent = m })
	end
	local board = Builder.part({ Name = "Cartel", Size = V(w, 2.4, 0.3), CFrame = cf * CF(0, 5.4, 0), Color = color or rgb(40, 100, 70), Material = Enum.Material.Wood, Parent = m })
	Builder.sign(board, text, Enum.NormalId.Front)
	Builder.sign(board, text, Enum.NormalId.Back)
end

-- Cuenta las piezas de un modelo
function Comun.count(m: Instance): number
	local n = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

return Comun
