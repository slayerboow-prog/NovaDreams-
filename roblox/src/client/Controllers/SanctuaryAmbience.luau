-- SanctuaryAmbience: el AMBIENTE del Santuario del Bosque (18-11-2026, el dueño: «atmósfera de fantasía
-- cinematográfica: cielo azul violáceo, luz azul del árbol, partículas, nada oscuro»).
--
--   * Al acercarte (menos de Near studs del santuario, etiqueta SantuarioBosque), el color del mundo pasa poco a poco a
--     un tono azul violáceo suave con algo de resplandor (un ColorCorrection y un Bloom PROPIOS: no se tocan los del
--     cielo ni del tiempo, Controllers/EnvDirector). Al irte, vuelve.
--   * Las vetas de energía del árbol (atributo Latido) y las runas laten despacio.
-- Solo en el cliente y barato: se mira cada 0,25 s; el latido, solo cerca.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SanctuaryAmbience = {}

SanctuaryAmbience.Near = 650
SanctuaryAmbience.Full = 320

local player = Players.LocalPlayer

function SanctuaryAmbience.init()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "SantuarioTono"
	cc.Enabled = false
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "SantuarioBrillo"
	bloom.Enabled = false
	bloom.Parent = Lighting
	local k = 0
	local glowing: { BasePart } = {}
	local acc = 0
	local nearModel: Instance? = nil
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc >= 0.25 then
			acc = 0
			local c = player.Character
			local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			local best, bd = nil, math.huge
			if root then
				for _, m in CollectionService:GetTagged("SantuarioBosque") do
					if m:IsA("Model") then
						local d = (m:GetPivot().Position - root.Position).Magnitude
						if d < bd then
							best, bd = m, d
						end
					end
				end
			end
			local target = if bd < SanctuaryAmbience.Near then math.clamp((SanctuaryAmbience.Near - bd) / (SanctuaryAmbience.Near - SanctuaryAmbience.Full), 0, 1) else 0
			k += (target - k) * 0.25
			if best ~= nearModel then
				nearModel = best
				table.clear(glowing)
				if best and bd < SanctuaryAmbience.Near then
					for _, d in best:GetDescendants() do
						if d:IsA("BasePart") and (d:GetAttribute("Latido") or d.Name == "AnilloRunas" or d.Name == "Runa" or d.Name == "RunaSuelo") then
							table.insert(glowing, d)
						end
					end
				end
			end
		end
		cc.Enabled = k > 0.01
		bloom.Enabled = k > 0.01
		if k > 0.01 then
			cc.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(196, 206, 255), k)
			cc.Saturation = 0.12 * k
			cc.Brightness = 0.03 * k
			cc.Contrast = 0.06 * k
			bloom.Intensity = 0.55 * k
			bloom.Size = 26
			bloom.Threshold = 1.25
			-- el latido (vetas del árbol y runas)
			local wave = math.sin(os.clock() * 1.6)
			for _, p in glowing do
				if p.Parent then
					-- (las vetas del árbol, más suaves que las runas)
					p.Transparency = if p:GetAttribute("Latido") then 0.14 + 0.1 * wave else 0.25 + 0.2 * wave
				end
			end
		end
	end)
end

return SanctuaryAmbience
