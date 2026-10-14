-- CrashFx (cliente): chispas y trocitos al chocar (Controllers/Collisions). Solo en tu pantalla y
-- ligeros: como mucho unos pocos efectos a la vez (menos en el móvil) y cada uno se borra solo en
-- un segundo y medio.

local Debris = game:GetService("Debris")

local Perf = require(script.Parent.Parent.UI.Perf)

local CrashFx = {}

local MAX_ALIVE = if Perf.lite then 3 else 6
local LIFE = 1.4
local alive = 0

local SPARK_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 210)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 190, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 90, 20)),
})

local function holder(point: Vector3, normal: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = "CrashFx"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	local out = Vector3.new(normal.X, 0, normal.Z)
	local at = point + Vector3.new(0, 1.4, 0)
	-- La cara de arriba (Top) mira hacia fuera del golpe y un poco hacia arriba
	local up = if out.Magnitude > 1e-3 then (out.Unit + Vector3.new(0, 0.6, 0)).Unit else Vector3.yAxis
	local right = up:Cross(Vector3.zAxis)
	if right.Magnitude < 1e-3 then
		right = Vector3.xAxis
	end
	part.CFrame = CFrame.fromMatrix(at, right.Unit, up)
	part.Parent = workspace
	return part
end

-- Chispas (y, si el golpe es fuerte, unos trocitos de chapa). strength 0..1 (Crash.strength)
function CrashFx.hit(point: Vector3, normal: Vector3, strength: number, color: Color3?)
	if strength <= 0 or alive >= MAX_ALIVE then
		return
	end
	alive += 1
	task.delay(LIFE, function()
		alive -= 1
	end)
	local ok = pcall(function()
		local part = holder(point, normal)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = SPARK_COLORS
		sparks.LightEmission = 1
		sparks.LightInfluence = 0
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0) })
		sparks.Transparency = NumberSequence.new(0, 0.2)
		sparks.Lifetime = NumberRange.new(0.18, 0.45)
		sparks.Speed = NumberRange.new(14 + 18 * strength, 24 + 26 * strength)
		sparks.SpreadAngle = Vector2.new(55, 55)
		sparks.Acceleration = Vector3.new(0, -70, 0)
		sparks.Drag = 2.5
		sparks.Rate = 0
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Parent = part
		sparks:Emit(math.floor((8 + 26 * strength) * (if Perf.lite then 0.5 else 1)))
		-- Polvo / humo corto en los golpes fuertes
		if strength > 0.35 then
			local dust = Instance.new("ParticleEmitter")
			dust.Color = ColorSequence.new(Color3.fromRGB(150, 146, 140))
			dust.LightInfluence = 1
			dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.2) })
			dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
			dust.Lifetime = NumberRange.new(0.5, 0.9)
			dust.Speed = NumberRange.new(3, 7)
			dust.SpreadAngle = Vector2.new(80, 80)
			dust.Rate = 0
			dust.Parent = part
			dust:Emit(if Perf.lite then 3 else 6)
		end
		Debris:AddItem(part, LIFE)
		-- Trocitos (solo en tu pantalla, sin chocar con nada importante y fuera en 1.4 s)
		if strength > 0.45 then
			local count = if Perf.lite then 2 else 4
			for _ = 1, count do
				local chip = Instance.new("Part")
				chip.Name = "CrashChip"
				chip.Size = Vector3.new(0.35 + math.random() * 0.4, 0.12, 0.3 + math.random() * 0.3)
				chip.Color = color or Color3.fromRGB(70, 72, 76)
				chip.Material = Enum.Material.SmoothPlastic
				chip.CanQuery = false
				chip.CanTouch = false
				chip.CanCollide = true
				chip.Massless = true
				chip.CFrame = CFrame.new(point + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
				local out = Vector3.new(normal.X, 0, normal.Z)
				local dir = (if out.Magnitude > 1e-3 then out.Unit else Vector3.zero) + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
				chip.AssemblyLinearVelocity = dir * (10 + 16 * strength) + Vector3.new(0, 12 + 10 * strength, 0)
				chip.AssemblyAngularVelocity = Vector3.new(math.random() * 20 - 10, math.random() * 20 - 10, math.random() * 20 - 10)
				chip.Parent = workspace
				Debris:AddItem(chip, LIFE)
			end
		end
	end)
	if not ok then
		return
	end
end

return CrashFx
