-- NearShadows: sombras de las luces solo cerca del jugador.
--
-- La ciudad tiene casi 600 luces (farolas, luces de techo, faros). Si todas proyectan sombra a la vez,
-- el ordenador se ahoga. Pero la sombra de una farola solo se aprecia de cerca: aquí se encienden
-- las sombras de las luces más cercanas a la cámara (hasta MAX) y se apagan las demás.
-- Se ve igual que con todas encendidas y el juego va mucho más fluido.

local NearShadows = {}

local LITE = require(script.Parent.Parent.UI.Perf).lite
local MAX = if LITE then 4 else 12 -- luces con sombra a la vez (en móvil, menos)
local RANGE = 160 -- más lejos de esto, sin sombra
-- Modo ligero (móvil): de noche solo dan luz de verdad las farolas cercanas. Las lejanas siguen
-- brillando (la bombilla es de neón), pero sin iluminar el suelo, que es lo que cuesta.
-- El servidor dice si toca que estén encendidas con el material de la bombilla (neón = encendida).
local LAMP_RANGE = 200

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
		if eye and LITE then
			for light in tracked do
				local bulb = light.Parent
				if bulb and bulb:IsA("BasePart") and bulb:HasTag("StreetLamp") then
					local want = bulb.Material == Enum.Material.Neon and (bulb.Position - eye).Magnitude < LAMP_RANGE
					if light.Enabled ~= want then
						light.Enabled = want
					end
				end
			end
		end
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
