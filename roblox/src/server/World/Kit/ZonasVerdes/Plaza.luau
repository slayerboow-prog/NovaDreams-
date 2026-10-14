-- Plaza: zona 21, «Jardines de la Plaza Mayor» (Valmar Centro), en el solar libre al este de la
-- Protectora (x -192..-24, z -352..-206; ver docs/zonas-verdes/plan.md). Sin marcas de la historia
-- (StorySpot / StoryArea / StoryProp) en el solar: se comprobó en el mapa construido (test-zonasverdes).
--   * Pipicán de la Protectora (junto a su pipicán pequeño): valla, vallas de agilidad, túnel y el
--     poste «Lanzar la pelota»: la mascota recién adoptada juega aquí (+diversión).
--   * Parque infantil grande: dos juegos de columpios, tobogán y dos balancines sobre suelo blando.
--   * Quiosco de helados y limonada (FoodService), mesas de pícnic, bancos, farolas y caminos.

local Juegos = require(script.Parent.Juegos)
local Comun = require(script.Parent.Comun)
local Builder = require(script.Parent.Parent.Parent.Builder)

local Plaza = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

Plaza.Rect = { X0 = -192, X1 = -24, Z0 = -352, Z1 = -206 }
Plaza.Top = 0.2 -- la superficie del jardín (el terreno de alrededor está en -1)

function Plaza.build(world: Instance): Model
	local R = Plaza.Rect
	local Y = Plaza.Top
	local cx, cz = (R.X0 + R.X1) / 2, (R.Z0 + R.Z1) / 2
	local m = Comun.site(world, "JardinesPlazaMayor", 21)
	Comun.ground(m, CF(cx, 0, cz), R.X1 - R.X0, R.Z1 - R.Z0, Y)
	local function at(x: number, z: number, yaw: number?): CFrame
		return CF(x, Y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	-- Caminos: uno de este a oeste por el medio y otro hacia la calle del norte
	Comun.path(m, V(R.X0 + 2, 0, -282), V(R.X1 - 2, 0, -282), 6, Y)
	Comun.path(m, V(-112, 0, -280), V(-112, 0, R.Z1 - 2), 6, Y)

	-- Pipicán de la Protectora (al lado de la suya, al oeste del solar), con la puerta al camino
	Juegos.dogRun(m, at(-160, -320, 180), 44, 50, { Hurdles = 3, Tunnel = true, Title = "🐾 PIPICÁN DE LA PROTECTORA" })

	-- Parque infantil grande (al este)
	local play = Builder.model("ParqueInfantil", m)
	Builder.decor({ Name = "SueloBlando", Size = V(62, 0.12, 50), CFrame = at(-60, -318) * CF(0, 0.06, 0), Color = Juegos.Colors.Rubber, Material = Enum.Material.Rubber, Parent = play })
	Juegos.swings(play, at(-78, -334), 3)
	Juegos.swings(play, at(-50, -334), 2)
	Juegos.slide(play, at(-40, -306, 90))
	Juegos.seesaw(play, at(-78, -306))
	Juegos.seesaw(play, at(-62, -300))
	for _, x in { -84, -36 } do
		Juegos.bench(play, at(x, -347, 180)) -- (mirando a los columpios)
	end

	-- Quiosco de helados y limonada junto al camino, mirando a él
	Juegos.kiosk(m, at(-100, -232, 90), "HELADOS · LIMONADA", { "Helado", "Limonada" }, rgb(240, 120, 150))
	-- Mesas de pícnic y bancos a lo largo del camino
	for i, x in { -160, -60, -36 } do
		Juegos.picnicTable(m, at(x, -240 - (i % 2) * 14))
	end
	for _, x in { -178, -140, -84, -40 } do
		Juegos.bench(m, at(x, -275, 0)) -- (mirando al camino)
	end
	for _, x in { -180, -134, -90, -32 } do
		Comun.lantern(m, at(x, -287))
	end
	-- Parterres de flores
	for _, p in { { -150, -222 }, { -74, -222 } } do
		Builder.decor({ Name = "Parterre", Size = V(10, 0.6, 4), CFrame = at(p[1], p[2]) * CF(0, 0.3, 0), Color = rgb(220, 90, 120), Material = Enum.Material.LeafyGrass, Parent = m })
	end
	Comun.sign(m, at(-112, -211, 0), "JARDINES DE LA PLAZA MAYOR", rgb(40, 100, 70), 16)
	return m
end

return Plaza
