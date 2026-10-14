-- Huertos: zona 19, «Puerta de Villaverde». Huertos urbanos junto a la Carretera de Villaverde y al
-- súper del Oeste. Es un Model «Granja» pequeño: FarmService lo encuentra solo (como las granjas de
-- Villaverde) y lo reparte en 4 fincas de 5 filas (4 bancales y un corral), con su cooperativa delante
-- de la caseta («Granero»): quedarte un huerto, plantar, regar, cosechar (las plantas crecen por fases:
-- brote, mata, con fruto) y vender en la cooperativa o en el almacén del súper. Además:
--   * cocina del huerto («HuertoCocina»: la cocina de FarmService al aire libre, para cocinar lo
--     cosechado), frutales, grifo, compostadores, bancos, farolas y la valla.

local Juegos = require(script.Parent.Juegos)
local Comun = require(script.Parent.Comun)
local Builder = require(script.Parent.Parent.Parent.Builder)

local Huertos = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new

Huertos.Center = V(-1500, 0, -1800)
Huertos.Size = V(164, 0, 112)
Huertos.Top = -0.8 -- el terreno del campo está en -1
Huertos.Fincas = 4

function Huertos.build(world: Instance): Model
	local c = Huertos.Center
	local Y = Huertos.Top
	local W, D = Huertos.Size.X, Huertos.Size.Z
	local m = Comun.site(world, "HuertosPuertaVillaverde", 19)
	Comun.ground(m, CF(c.X, 0, c.Z), W, D, Y)
	local function at(x: number, z: number, yaw: number?): CFrame
		return CF(c.X + x, Y, c.Z + z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end

	-- La granja: 4 fincas × 5 filas de 5 × 22 (a lo largo de Z); la caseta delante (+Z)
	local farm = Builder.model("Granja", m)
	farm:SetAttribute("Huertos", true)
	for f = 0, Huertos.Fincas - 1 do
		for r = 0, 4 do
			local x = -60 + f * 32 + r * 6
			Builder.part({ Name = "Crop", Size = V(5, 0.5, 22), CFrame = at(x, -10) * CF(0, 0, 0), Color = rgb(120, 90, 60), Material = Enum.Material.Ground, Parent = farm })
		end
	end
	local shed = Builder.model("Granero", farm)
	Builder.part({ Name = "Caseta", Size = V(10, 7, 8), CFrame = at(0, 28) * CF(0, 3.5, 0), Color = rgb(150, 110, 76), Material = Enum.Material.WoodPlanks, Parent = shed })
	Builder.part({ Name = "Tejado", ClassName = "WedgePart", Size = V(11, 2, 9), CFrame = at(0, 28) * CF(0, 8, 0), Color = rgb(120, 60, 46), Material = Enum.Material.Slate, Parent = shed })
	Builder.decor({ Name = "Puerta", Size = V(3, 5, 0.2), CFrame = at(0, 28) * CF(0, 2.5, 4.05), Color = rgb(96, 68, 44), Material = Enum.Material.Wood, Parent = shed })

	-- Cocina del huerto: encimera con fogón (cocinar lo cosechado)
	local kitchen = Builder.model("CocinaHuerto", m)
	local counter = Builder.part({ Name = "Encimera", Size = V(8, 3.2, 3), CFrame = at(52, 26, 180) * CF(0, 1.6, 0), Color = rgb(200, 196, 188), Material = Enum.Material.Concrete, Tags = { "HuertoCocina" }, Parent = kitchen })
	counter:SetAttribute("Reason", "Cook")
	Builder.decor({ Name = "Fogon", Size = V(3, 0.3, 2), CFrame = counter.CFrame * CF(-1.6, 1.7, 0), Color = rgb(40, 40, 44), Material = Enum.Material.Metal, Parent = kitchen })
	Builder.decor({ Name = "Olla", Shape = Enum.PartType.Cylinder, Size = V(1.2, 1.6, 1.6), CFrame = counter.CFrame * CF(-1.6, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(170, 172, 176), Material = Enum.Material.Metal, Parent = kitchen })
	Builder.decor({ Name = "Tejadillo", Size = V(10, 0.3, 5), CFrame = counter.CFrame * CF(0, 5.6, 0), Color = rgb(40, 120, 60), Material = Enum.Material.Fabric, Parent = kitchen })
	for _, x in { -4.6, 4.6 } do
		Builder.decor({ Name = "Poste", Size = V(0.3, 5.6, 0.3), CFrame = counter.CFrame * CF(x, 2.8, 1.8), Color = rgb(104, 76, 52), Material = Enum.Material.Wood, Parent = kitchen })
	end
	local board = Builder.part({ Name = "Rotulo", Size = V(6, 1, 0.2), CFrame = counter.CFrame * CF(0, 4.6, -1.6), Color = rgb(40, 120, 60), Material = Enum.Material.Wood, CanCollide = false, Parent = kitchen })
	Builder.sign(board, "COCINA DEL HUERTO", Enum.NormalId.Front)

	-- Frutales al fondo (-Z)
	for i = 0, 4 do
		local x = -64 + i * 32
		local base = at(x, -46)
		Builder.part({ Name = "TroncoFrutal", Size = V(0.9, 5, 0.9), CFrame = base * CF(0, 2.5, 0), Color = rgb(110, 80, 50), Material = Enum.Material.Wood, Parent = m })
		Builder.decor({ Name = "CopaFrutal", Shape = Enum.PartType.Ball, Size = V(7, 6, 7), CFrame = base * CF(0, 6.5, 0), Color = rgb(80, 150, 70), Material = Enum.Material.LeafyGrass, Parent = m })
		local fruit = if i % 2 == 0 then rgb(240, 150, 40) else rgb(220, 50, 50)
		for k = 0, 1 do
			Builder.decor({ Name = "Fruta", Shape = Enum.PartType.Ball, Size = V(0.9, 0.9, 0.9), CFrame = base * CF(-1.6 + k * 3.2, 5.4, -2.6), Color = fruit, Parent = m })
		end
	end

	-- Grifo, compostadores, bancos y farolas
	Builder.part({ Name = "Grifo", Size = V(0.8, 3, 0.8), CFrame = at(-40, 24) * CF(0, 1.5, 0), Color = rgb(150, 156, 164), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Pila", Size = V(2.4, 0.8, 1.6), CFrame = at(-40, 24) * CF(0, 0.4, 1.2), Color = rgb(170, 166, 160), Material = Enum.Material.Concrete, Parent = m })
	for _, x in { -72, -66 } do
		Builder.part({ Name = "Compostador", Size = V(4, 3, 4), CFrame = at(x, 24) * CF(0, 1.5, 0), Color = rgb(60, 110, 60), Material = Enum.Material.Plastic, Parent = m })
	end
	for _, x in { -24, 24 } do
		Juegos.bench(m, at(x, 44, 180))
	end
	for _, x in { -40, 40 } do
		Comun.lantern(m, at(x, 50))
	end

	-- Valla alrededor (con la entrada en el lado de la carretera, +Z)
	local hw, hd = W / 2 - 2, D / 2 - 2
	local function p(x: number, z: number): Vector3
		return (at(x, z)).Position
	end
	Juegos.fence(m, p(-hw, -hd), p(hw, -hd), 16)
	Juegos.fence(m, p(-hw, -hd), p(-hw, hd), 16)
	Juegos.fence(m, p(hw, -hd), p(hw, hd), 16)
	Juegos.fence(m, p(-hw, hd), p(-8, hd), 16)
	Juegos.fence(m, p(8, hd), p(hw, hd), 16)
	Comun.sign(m, at(0, hd + 1), "HUERTOS URBANOS · PUERTA DE VILLAVERDE", rgb(60, 120, 50), 18)
	return m
end

return Huertos
