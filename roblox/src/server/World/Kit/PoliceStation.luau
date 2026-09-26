-- PoliceStation: la planta baja de la comisaría (oficio de policía, PoliceService).
--
--   PoliceStation.build(model, at, W, D)   (at(x, y, z): y = 0 suelo, -Z = fachada; puerta en x = 0)
--
-- Mostrador de atención (PoliceDesk: aquí se entregan los informes), banco de espera, mesas de
-- los agentes con ordenadores, taquillas, dos calabozos con barrotes, tablón de "SE BUSCA" y
-- banderas. El centro queda libre (ahí la historia coloca a sus personajes). Fuera, el punto del
-- coche patrulla (PolicePatrol). El modelo lleva la etiqueta PoliceStation.

local Builder = require(script.Parent.Parent.Builder)

local PoliceStation = {}

local rgb = Color3.fromRGB
local BLUE = rgb(24, 60, 150)
local LIGHT = rgb(236, 238, 242)
local DARK = rgb(40, 42, 48)
local STEEL = rgb(170, 174, 180)
local WOOD = rgb(150, 110, 76)

function PoliceStation.build(model: Model, at: (number, number, number) -> CFrame, W: number, D: number)
	local function solid(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.part(props)
	end
	local function bit(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = model })
	end
	local front, back = -D / 2, D / 2

	-- Mostrador de atención al público (a la derecha de la entrada)
	local dx, dz = W / 4, front + 7
	solid("FrontDesk", Vector3.new(10, 3.6, 2.4), at(dx, 1.8, dz), BLUE, Enum.Material.SmoothPlastic, { Tags = { "PoliceDesk" } })
	bit("DeskTop", Vector3.new(10.4, 0.2, 3), at(dx, 3.7, dz), LIGHT)
	bit("DeskGlass", Vector3.new(10, 2.6, 0.12), at(dx, 5.1, dz - 0.6), rgb(200, 225, 240), Enum.Material.Glass, 0.6)
	bit("Monitor", Vector3.new(1.8, 1.2, 0.15), at(dx + 2, 4.5, dz + 0.6), DARK)
	bit("MonitorScreen", Vector3.new(1.6, 1, 0.05), at(dx + 2, 4.5, dz + 0.52), rgb(90, 160, 230), Enum.Material.Neon)
	bit("Papers", Vector3.new(1.2, 0.15, 0.9), at(dx - 2, 3.9, dz), rgb(250, 248, 240))
	local deskSign = bit("DeskSign", Vector3.new(6, 1.2, 0.15), at(dx, 7.6, dz + 1), BLUE)
	Builder.sign(deskSign, "ATENCIÓN AL CIUDADANO", Enum.NormalId.Front, rgb(250, 250, 250))
	-- Banco de espera (a la izquierda de la entrada)
	for k = 0, 1 do
		local bench = at(-W / 4 - 2 + k * 5, 0, front + 3)
		bit("Bench", Vector3.new(4.4, 0.4, 1.6), bench * CFrame.new(0, 1.8, 0), STEEL, Enum.Material.Metal)
		bit("BenchBack", Vector3.new(4.4, 1.6, 0.2), bench * CFrame.new(0, 2.8, -0.8), STEEL, Enum.Material.Metal)
		bit("BenchLegs", Vector3.new(4, 1.6, 1.2), bench * CFrame.new(0, 0.8, 0), DARK, Enum.Material.Metal, 0.6)
	end

	-- Mesas de los agentes (lado derecho, detrás del mostrador)
	for k = 0, 1 do
		local desk = at(W / 2 - 6, 0, front + 15 + k * 6)
		bit("OfficeDesk", Vector3.new(5, 3, 2.6), desk * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.Wood)
		bit("PC", Vector3.new(1.6, 1.1, 0.15), desk * CFrame.new(0.8, 3.6, 0.8), DARK)
		bit("PCScreen", Vector3.new(1.4, 0.9, 0.05), desk * CFrame.new(0.8, 3.6, 0.72), rgb(90, 160, 230), Enum.Material.Neon)
		bit("Files", Vector3.new(1.2, 0.8, 0.9), desk * CFrame.new(-1.4, 3.4, 0.3), rgb(220, 190, 110), Enum.Material.Cardboard)
		bit("OfficeChair", Vector3.new(1.8, 2.6, 1.8), desk * CFrame.new(0, 1.3, -2), DARK, Enum.Material.Fabric)
	end
	-- Taquillas junto a la pared derecha
	for k = 0, 4 do
		local locker = at(W / 2 - 1, 0, back - 3 - k * 2)
		bit("Locker", Vector3.new(1.4, 6.5, 1.9), locker * CFrame.new(0, 3.25, 0), rgb(70, 90, 130), Enum.Material.Metal)
		bit("LockerVent", Vector3.new(0.05, 0.6, 1.2), locker * CFrame.new(-0.72, 5.6, 0), DARK)
		bit("LockerHandle", Vector3.new(0.1, 0.8, 0.12), locker * CFrame.new(-0.74, 3.4, 0.6), STEEL, Enum.Material.Metal)
	end

	-- Calabozos con barrotes (lado izquierdo, al fondo)
	local cellW, cellD = 7, 8
	for k = 0, 1 do
		local cx = -W / 2 + 1 + cellW / 2 + k * cellW
		local cell = at(cx, 0, back - cellD / 2 - 0.5)
		solid("CellWall", Vector3.new(0.4, 9, cellD), cell * CFrame.new(cellW / 2, 4.5, 0), LIGHT, Enum.Material.Concrete)
		for b = -3, 3 do
			bit("Bar", Vector3.new(0.18, 8.6, 0.18), cell * CFrame.new(b * 0.95, 4.3, -cellD / 2), STEEL, Enum.Material.Metal)
		end
		bit("BarTop", Vector3.new(cellW, 0.3, 0.3), cell * CFrame.new(0, 8.7, -cellD / 2), STEEL, Enum.Material.Metal)
		bit("BarMid", Vector3.new(cellW, 0.2, 0.25), cell * CFrame.new(0, 4.5, -cellD / 2), STEEL, Enum.Material.Metal)
		bit("CellBed", Vector3.new(2.4, 1.6, 5), cell * CFrame.new(-cellW / 2 + 1.6, 0.8, 1), LIGHT, Enum.Material.Concrete)
		bit("Mattress", Vector3.new(2.2, 0.3, 4.8), cell * CFrame.new(-cellW / 2 + 1.6, 1.75, 1), rgb(90, 110, 140), Enum.Material.Fabric)
		bit("Toilet", Vector3.new(1.2, 1.4, 1.4), cell * CFrame.new(cellW / 2 - 1.2, 0.7, cellD / 2 - 1.2), STEEL, Enum.Material.Metal)
		local num = bit("CellNumber", Vector3.new(1, 0.6, 0.1), cell * CFrame.new(0, 9.4, -cellD / 2 - 0.1), BLUE)
		Builder.sign(num, "C" .. (k + 1), Enum.NormalId.Front, rgb(250, 250, 250))
	end
	-- Tablón de SE BUSCA y banderas
	local board = bit("WantedBoard", Vector3.new(6, 4, 0.2), at(-W / 4, 6, back - 0.6), rgb(200, 170, 120), Enum.Material.Wood)
	Builder.sign(board, "SE BUSCA", Enum.NormalId.Front, rgb(120, 30, 30))
	for k = 0, 2 do
		bit("WantedPoster", Vector3.new(1.4, 1.8, 0.05), at(-W / 4 - 2 + k * 2, 5.3, back - 0.72), rgb(245, 240, 225))
	end
	for k, color in { rgb(200, 30, 40), rgb(250, 200, 30), BLUE } do
		bit("FlagPole", Vector3.new(0.15, 7, 0.15), at(4 + k * 1.5, 3.5, back - 1), rgb(210, 190, 120), Enum.Material.Metal)
		bit("Flag", Vector3.new(1.2, 1.6, 0.05), at(4.6 + k * 1.5, 6, back - 1), color, Enum.Material.Fabric)
	end
	bit("Emblem", Vector3.new(3, 3, 0.1), at(0, 8, back - 0.6), BLUE)
	local emblem = bit("EmblemText", Vector3.new(2.6, 0.8, 0.05), at(0, 8, back - 0.66), BLUE)
	Builder.sign(emblem, "POLICÍA", Enum.NormalId.Front, rgb(250, 200, 30))

	-- Fuera: el punto del coche patrulla, a la izquierda de la puerta
	local patrol = at(-W / 2 + 6, 0, front - 8)
	bit("PatrolBay", Vector3.new(8, 0.05, 15), patrol * CFrame.new(0, 0.03, 0), rgb(255, 255, 255))
	local sign = bit("PatrolSign", Vector3.new(3.4, 1.2, 0.15), patrol * CFrame.new(3.6, 4.4, -7), BLUE)
	Builder.sign(sign, "🚓 PATRULLA", Enum.NormalId.Front, rgb(250, 250, 250))
	bit("PatrolSignPost", Vector3.new(0.25, 4, 0.25), patrol * CFrame.new(3.6, 2, -7), STEEL, Enum.Material.Metal)
	Builder.part({ Name = "PolicePatrol", Size = Vector3.new(4, 3, 4), CFrame = patrol * CFrame.new(3.6, 1.5, -5), Transparency = 1, CanCollide = false, Tags = { "PolicePatrol" }, Parent = model })
	model:AddTag("PoliceStation")
end

return PoliceStation
