-- DeepReliefBuilder (servidor, v4): la roca del Gran Veril y de su fosa (shared/Sea/DeepReef) en el terreno.
-- Solo con Config.Sea.V4. Lo llama World/OceanBuilder.build en su hilo, después del fondo y del relieve de las
-- orillas, con su yield. Primero la roca (respaldo, bultos, voladizos, agujas, arcos) y al final, el agua de
-- las cuevas: así una parcela vecina no vuelve a tapar una boca.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeepReef = require(ReplicatedStorage.Shared.Sea.DeepReef)

local DeepReliefBuilder = {}

DeepReliefBuilder.State = "None"
DeepReliefBuilder.Stats = { Balls = 0, Blocks = 0, Caves = 0, Cells = 0, Seconds = 0 }

local MATERIAL_CACHE: { [string]: Enum.Material } = {}
local function materialOf(name: string): Enum.Material
	local m = MATERIAL_CACHE[name]
	if not m then
		local ok, value = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		m = if ok and value then value else Enum.Material.Rock
		MATERIAL_CACHE[name] = m
	end
	return m
end

function DeepReliefBuilder.apply(terrain: any, op: DeepReef.Op)
	local mat = materialOf(op.Material)
	if op.Shape == "Ball" then
		terrain:FillBall(Vector3.new(op.X, op.Y, op.Z), op.R, mat)
		DeepReliefBuilder.Stats.Balls += 1
	else
		local s = op.Size :: { number }
		local cf = CFrame.new(op.X, op.Y, op.Z) * CFrame.Angles(0, op.Yaw or 0, 0) * CFrame.Angles(op.Pitch or 0, 0, 0)
		terrain:FillBlock(cf, Vector3.new(s[1], s[2], s[3]), mat)
		DeepReliefBuilder.Stats.Blocks += 1
	end
end

function DeepReliefBuilder.build(terrain: any, yield: (() -> ())?)
	if not DeepReef.Enabled or DeepReliefBuilder.State ~= "None" then
		return
	end
	DeepReliefBuilder.State = "Building"
	local t0 = os.clock()
	local stats = DeepReliefBuilder.Stats
	local caves: { DeepReef.Op } = {}
	DeepReef.eachCell(function(ix, iz)
		local ops = DeepReef.relief(ix, iz)
		if #ops > 0 then
			stats.Cells += 1
		end
		for _, op in ops do
			if op.Material == "Water" then
				table.insert(caves, op)
			else
				local ok, err = pcall(DeepReliefBuilder.apply, terrain, op)
				if not ok then
					warn("[DeepReliefBuilder] " .. tostring(err))
				end
			end
		end
	end, yield)
	for i, op in caves do
		pcall(DeepReliefBuilder.apply, terrain, op)
		stats.Caves += 1
		if yield and i % 40 == 0 then
			yield()
		end
	end
	stats.Seconds = math.floor((os.clock() - t0) * 10) / 10
	DeepReliefBuilder.State = "Ready"
	workspace:SetAttribute("DeepRelief", ("%d bolas, %d bloques, %d cuevas, %d parcelas, %.1f s"):format(stats.Balls, stats.Blocks, stats.Caves, stats.Cells, stats.Seconds))
end

return DeepReliefBuilder
