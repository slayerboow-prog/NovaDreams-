-- Parques: «parques vivos». A cada uno de los parques de barrio (manzanas «Parque» de Kit/Districts,
-- hechas con Lite.park: caminos en cruz, fuente en medio, 4 bancos y árboles) se le añaden cosas que
-- se usan, una en cada cuarto del parque (entre los caminos), según su tamaño:
--   grande (cuartos de 40 o más)   parque infantil (columpios, tobogán, balancín), mesas de pícnic,
--                                  pipicán con agilidad y media pista de baloncesto
--   mediano (26 a 40)              parque infantil y mesas de pícnic
--   pequeño                        mesas de pícnic
-- El orden de los cuartos cambia de un parque a otro (según dónde está, sin math.random). Los árboles
-- que caían encima se quitan (Comun.prune). Cada parque vivo es un Model «ParqueVivo» en la carpeta
-- ZonasVerdes (60–120 piezas).

local Builder = require(script.Parent.Parent.Parent.Builder)
local Juegos = require(script.Parent.Juegos)
local Comun = require(script.Parent.Comun)

local Parques = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

Parques.MaxParts = 120
Parques.MinParts = 60

-- Lo que va en un cuarto: cada uno devuelve el rectángulo que ocupa (en planta) para quitar árboles
type Module = (m: Instance, cf: CFrame, q: number) -> { Comun.Rect }

local modules: { [string]: Module } = {}

-- Parque infantil: suelo blando, columpios, tobogán y balancín (y un banco para los mayores)
modules.Infantil = function(m, cf, q)
	local w, d = math.min(32, q - 2), math.min(26, q - 2)
	local zone = Builder.model("ParqueInfantil", m)
	Builder.decor({ Name = "SueloBlando", Size = V(w, 0.12, d), CFrame = cf * CF(0, 0.06, 0), Color = Juegos.Colors.Rubber, Material = Enum.Material.Rubber, Parent = zone })
	Juegos.swings(zone, cf * CF(-w / 2 + 7, 0, -d / 2 + 5), 2)
	Juegos.slide(zone, cf * CF(w / 2 - 5, 0, d / 2 - 7))
	Juegos.seesaw(zone, cf * CF(-w / 2 + 7, 0, d / 2 - 5))
	Juegos.bench(zone, cf * CF(0, 0, -d / 2 - 2.5) * CFrame.Angles(0, math.pi, 0))
	return { Comun.rect(cf, w + 4, d + 8) }
end

-- Dos mesas de pícnic y una papelera
modules.Picnic = function(m, cf, q)
	local zone = Builder.model("Picnic", m)
	local gap = math.min(9, q / 4)
	Juegos.picnicTable(zone, cf * CF(-gap, 0, 0))
	Juegos.picnicTable(zone, cf * CF(gap, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
	Builder.part({ Name = "Papelera", Shape = Enum.PartType.Cylinder, Size = V(2.4, 1.4, 1.4), CFrame = cf * CF(0, 1.2, 7) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(56, 96, 70), Material = Enum.Material.Metal, Parent = zone })
	return { Comun.rect(cf, gap * 2 + 12, 16) }
end

-- Pipicán con dos saltos
modules.Perros = function(m, cf, q)
	local w, d = math.min(30, q - 4), math.min(24, q - 4)
	Juegos.dogRun(m, cf, w, d, { Hurdles = 2 })
	return { Comun.rect(cf, w + 3, d + 5) }
end

-- Media pista de baloncesto (BasketService la encuentra sola) y un banco al lado
modules.Canasta = function(m, cf, q)
	local zone = Builder.model("Canasta", m)
	local w, d = math.min(22, q - 4), math.min(20, q - 4)
	Juegos.halfCourt(zone, cf, w, d)
	Juegos.bench(zone, cf * CF(w / 2 + 3, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))
	return { Comun.rect(cf, w + 8, d + 2) }
end

local ORDER = { "Infantil", "Picnic", "Perros", "Canasta" }

-- Qué lleva un parque de cuartos de tamaño q
function Parques.plan(q: number): { string }
	if q >= 40 then
		return { "Infantil", "Picnic", "Perros", "Canasta" }
	elseif q >= 26 then
		return { "Infantil", "Picnic" }
	end
	return { "Picnic" }
end

-- Un número fijo para cada sitio (sin math.random: no cambia el resto del mapa)
local function hash(x: number, z: number): number
	return math.floor(math.abs(math.sin(x * 12.9898 + z * 78.233) * 43758.5453) * 1000) % 1000
end

-- Viste un parque: block = la manzana (Model «Manzana_Parque»), rect = su suelo
function Parques.dress(world: Instance, block: Instance, rect: Comun.Rect, index: number): Model?
	-- El parque de Lite.park: inner(rect, 4) → w, d
	local cx, cz = (rect.X0 + rect.X1) / 2, (rect.Z0 + rect.Z1) / 2
	local w, d = rect.X1 - rect.X0 - 8, rect.Z1 - rect.Z0 - 8
	-- Un cuarto va de 3 (el camino) al borde: se deja sitio a los dos lados
	local qx, qz = w / 2 - 9, d / 2 - 9
	local q = math.min(qx, qz)
	if q < 14 then
		return nil
	end
	local m = Comun.site(world, "ParqueVivo", "P" .. index)
	m:SetAttribute("Park", block:GetFullName())
	local list = Parques.plan(q)
	-- Los cuartos, empezando por uno distinto en cada parque
	local quarters = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
	local start = hash(cx, cz) % 4
	local rects: { Comun.Rect } = {}
	for i, name in list do
		local s = quarters[(start + i - 1) % 4 + 1]
		-- Centro del cuarto (entre el camino y el borde) y mirando hacia el centro del parque
		local x = s[1] * (3 + 1.5 + qx / 2)
		local z = s[2] * (3 + 1.5 + qz / 2)
		local cf = CF(cx + x, 0.3, cz + z) * CFrame.Angles(0, if s[2] > 0 then math.pi else 0, 0)
		for _, r in modules[name](m, cf, q) do
			table.insert(rects, r)
		end
	end
	-- Los árboles (y lo suelto) del parque que caían encima de lo nuevo, fuera
	local roots: { Instance } = { block }
	for _, child in block:GetChildren() do
		if child:IsA("Model") then
			table.insert(roots, child)
		end
	end
	local removed = Comun.prune(roots, rects, 3)
	m:SetAttribute("TreesRemoved", removed)
	m:SetAttribute("Modules", table.concat(list, ","))
	return m
end

-- Todos los parques de barrio del mapa
function Parques.build(world: Instance): { Model }
	local out = {}
	local blocks = {}
	for _, d in world:GetDescendants() do
		if d:IsA("Model") and d.Name == "Manzana_Parque" then
			table.insert(blocks, d)
		end
	end
	-- (siempre en el mismo orden: por posición)
	local function center(b: Instance): (number, number)
		local g = b:FindFirstChild("BlockGround")
		if g and g:IsA("BasePart") then
			return g.CFrame.Position.X, g.CFrame.Position.Z
		end
		return 0, 0
	end
	table.sort(blocks, function(a, b)
		local ax, az = center(a)
		local bx, bz = center(b)
		return if ax ~= bx then ax < bx else az < bz
	end)
	for i, block in blocks do
		local g = block:FindFirstChild("BlockGround")
		if g and g:IsA("BasePart") then
			local p = g.CFrame.Position
			-- (BlockGround es 4 más ancho y largo que la manzana)
			local rect = { X0 = p.X - g.Size.X / 2 + 2, X1 = p.X + g.Size.X / 2 - 2, Z0 = p.Z - g.Size.Z / 2 + 2, Z1 = p.Z + g.Size.Z / 2 - 2 }
			local park = Parques.dress(world, block, rect, i)
			if park then
				table.insert(out, park)
			end
		end
	end
	return out
end

return Parques
