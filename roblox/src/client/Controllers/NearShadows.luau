-- NearShadows: sombras de las luces solo cerca del jugador.
--
-- La ciudad tiene casi 600 luces (farolas, luces de techo, faros). Si todas proyectan sombra a la vez,
-- el ordenador se ahoga. Pero la sombra de una farola solo se aprecia de cerca: aquí se encienden
-- las sombras de las luces más cercanas a la cámara (hasta MAX) y se apagan las demás.
-- Se ve igual que con todas encendidas y el juego va mucho más fluido.

local NearShadows = {}

local MAX = 12 -- luces con sombra a la vez
local RANGE = 160 -- más lejos de esto, sin sombra

local tracked: { [Light]: boolean } = {}

local function add(light: Instance)
	if light:IsA("SpotLight") or light:IsA("PointLight") or light:IsA("SurfaceLight") then
		tracked[light] = true
		light.Shadows = false
		light.AncestryChanged:Connect(function(_, parent)
			if not parent then
				tracked[light] = nil
			end
		end)
	end
end

local function position(light: Light): Vector3?
	local parent = light.Parent
	if parent and parent:IsA("BasePart") then
		return parent.Position
	elseif parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	return nil
end

function NearShadows.init()
	for _, instance in workspace:GetDescendants() do
		add(instance)
	end
	workspace.DescendantAdded:Connect(add)

	while true do
		task.wait(0.5)
		local camera = workspace.CurrentCamera
		local eye = camera and camera.CFrame.Position
		if eye then
			local near = {}
			for light in tracked do
				if light.Enabled then
					local p = position(light)
					if p then
						local d = (p - eye).Magnitude
						if d < RANGE then
							table.insert(near, { Light = light, D = d })
						end
					end
				end
			end
			table.sort(near, function(a, b)
				return a.D < b.D
			end)
			local on = {}
			for i = 1, math.min(MAX, #near) do
				on[near[i].Light] = true
			end
			for light in tracked do
				local want = on[light] == true
				if light.Shadows ~= want then
					light.Shadows = want
				end
			end
		end
	end
end

return NearShadows
