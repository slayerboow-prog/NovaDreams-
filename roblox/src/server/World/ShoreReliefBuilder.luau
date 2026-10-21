-- ShoreReliefBuilder (servidor): el relieve del fondo de TODAS las orillas y del mar poco y medio hondo
-- (v126, docs/mar/v3-objetivo.md). Rellena el terreno con lo que dice shared/Sea/ShoreReef.relief en cada
-- parcela de 24 studs: afloramientos de roca (caliza, pizarra, basalto) donde crecen los arrecifes,
-- campos de rocas, ondas de arenisca y dunas bajas de arena, el talud de arena de la orilla (la isla
-- acababa en una pared de 13 studs) y fango en lo hondo. Nada sube a menos de 2,5 m de la superficie y no
-- se toca la orilla de puertos e islas, la Garganta, el Cañón de Dorada ni Nácara (ShoreReef.plan).
--
-- Lo llama World/OceanBuilder.build en su hilo, después del fondo, con su yield (el arranque no se para).
-- Como son decenas de miles de rellenos pequeños, primero se miran celdas grandes de 96 studs y solo se
-- recorren las que están cerca de la costa (o alrededor de Nácara).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local ShoreReef = require(ReplicatedStorage.Shared.Sea.ShoreReef)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)

local ShoreReliefBuilder = {}

ShoreReliefBuilder.Stats = { Balls = 0, Blocks = 0, Cells = 0, Seconds = 0, Kinds = {} :: { [string]: number } }
ShoreReliefBuilder.State = "None"

local MATERIAL_CACHE: { [string]: Enum.Material } = {}
local function materialOf(name: string): Enum.Material
	local m = MATERIAL_CACHE[name]
	if not m then
		local ok, value = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		m = if ok and value then value else Enum.Material.Salt
		MATERIAL_CACHE[name] = m
	end
	return m
end

-- Las parcelas que tocan el relieve (las pruebas lo usan para contar): llama a fn(ix, iz) en cada una
function ShoreReliefBuilder.eachCell(fn: (number, number) -> (), yield: (() -> ())?)
	local C = ShoreReef.Cell
	local BIG = C * 4
	local a = Ocean.Area
	local nc = Nacara.Center
	for bx = a.MinX, a.MaxX - 1, BIG do
		for bz = a.MinZ, a.MaxZ - 1, BIG do
			local mx, mz = bx + BIG / 2, bz + BIG / 2
			local d = Ocean.landDistance(mx, mz)
			local nearNacara = math.sqrt((mx - nc.X) ^ 2 + (mz - nc.Z) ^ 2) < ShoreReef.NacaraRing + BIG
			if (d > -BIG and d < ShoreReef.MaxD + BIG) or nearNacara then
				local ix0, iz0 = math.floor(bx / C), math.floor(bz / C)
				for ix = ix0, ix0 + 3 do
					for iz = iz0, iz0 + 3 do
						fn(ix, iz)
					end
				end
				if yield then
					yield()
				end
			end
		end
	end
end

function ShoreReliefBuilder.apply(terrain: any, op: ShoreReef.Op)
	local mat = materialOf(op.Material)
	if op.Shape == "Ball" then
		terrain:FillBall(Vector3.new(op.X, op.Y, op.Z), op.R, mat)
		ShoreReliefBuilder.Stats.Balls += 1
	else
		local s = op.Size :: { number }
		local cf = CFrame.new(op.X, op.Y, op.Z) * CFrame.Angles(0, op.Yaw or 0, 0) * CFrame.Angles(op.Pitch or 0, 0, 0)
		terrain:FillBlock(cf, Vector3.new(s[1], s[2], s[3]), mat)
		ShoreReliefBuilder.Stats.Blocks += 1
	end
end

function ShoreReliefBuilder.build(terrain: any, yield: (() -> ())?)
	if ShoreReliefBuilder.State ~= "None" then
		return
	end
	ShoreReliefBuilder.State = "Building"
	local t0 = os.clock()
	local stats = ShoreReliefBuilder.Stats
	ShoreReliefBuilder.eachCell(function(ix, iz)
		local plan = ShoreReef.plan(ix, iz)
		if plan.Kind then
			stats.Kinds[plan.Kind] = (stats.Kinds[plan.Kind] or 0) + 1
		end
		local ops = ShoreReef.relief(ix, iz, plan)
		if #ops > 0 then
			stats.Cells += 1
			for _, op in ops do
				local ok, err = pcall(ShoreReliefBuilder.apply, terrain, op)
				if not ok then
					warn("[ShoreReliefBuilder] " .. tostring(err))
					return
				end
			end
		end
	end, yield)
	stats.Seconds = math.floor((os.clock() - t0) * 10) / 10
	ShoreReliefBuilder.State = "Ready"
	workspace:SetAttribute("ShoreRelief", ("%d bolas, %d bloques, %d parcelas, %.1f s"):format(stats.Balls, stats.Blocks, stats.Cells, stats.Seconds))
end

return ShoreReliefBuilder
