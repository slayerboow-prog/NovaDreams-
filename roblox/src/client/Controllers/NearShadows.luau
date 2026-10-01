-- NearShadows: presupuesto de luces de la noche (solo en la pantalla de cada jugador).
--
-- La ciudad tiene más de 3.000 farolas (unas 1.600 con luz de verdad) y cientos de luces de techo.
-- Encenderlas todas a la vez (y con sombras) hunde los fps, sobre todo en el móvil. Aquí, cada medio
-- segundo y según el nivel gráfico (UI/Perf, presupuestos en shared/Graphics):
--   * Farolas: solo las N más cercanas a la cámara iluminan el suelo de verdad (charco de luz cálida);
--     las demás siguen brillando (la bombilla es de neón y el resplandor la hace brillar), que de lejos
--     es lo que se ve. Alto 40, Medio 18, Bajo 8. Encendidas o no lo dice el servidor (WorldService)
--     con el material de la bombilla: neón = encendida.
--   * Al construir la ciudad solo 1 de cada 2 farolas lleva luz (para ahorrar): aquí cada bombilla sin
--     luz recibe la suya (solo en esta pantalla). Como el presupuesto manda, no cuesta más, pero las
--     farolas cercanas que se encienden son el doble de seguidas: calles con charcos de luz continuos.
--   * Cada farola tiene su luz: la mayoría LED cálido y alguna de sodio, más naranja (siempre la misma
--     para la misma farola), con el foco hacia abajo y el alcance justo para pintar la acera y la calzada.
--   * Sombras: solo las luces más cercanas echan sombra (Alto 8, Medio 2, Bajo ninguna).
--   * Carteles de las tiendas: de noche resplandecen un poco (no en el nivel Bajo).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Graphics = require(ReplicatedStorage.Shared.Graphics)
local Perf = require(script.Parent.Parent.UI.Perf)

local NearShadows = {}

local TICK = 0.5
local LAMP_BRIGHTNESS = { Led = 3.4, Sodium = 3.8 }
local LAMP_RANGE = 50 -- alcance de la luz de una farola (la bombilla está a unos 14 studs)
local LAMP_ANGLE = 125
local SIGN_NIGHT = 1.7 -- brillo de los carteles de noche (de día, 1)
local SIGN_PARTS = { Sign = true, Banner = true, Advert = true, MupiAd = true, AdPanel = true }

type Lamp = { Light: Light, Bulb: BasePart }

local others: { [Light]: boolean } = {} -- luces que no son farolas (solo se les quitan o ponen sombras)
local lamps: { [Light]: Lamp } = {}
local signs: { [SurfaceGui]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local signNight: boolean? = nil
local desired: { [Light]: boolean } = {} -- lo que este presupuesto quiere para cada farola

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function isNight(): boolean
	local clock = Lighting.ClockTime
	return clock >= Config.LampsOnAt or clock < Config.LampsOffAt
end

local function styleLamp(light: Light, bulb: BasePart)
	local kind = Graphics.lampKind(bulb.Position)
	local color = rgb(if kind == "Sodium" then Graphics.LampSodium else Graphics.LampLed)
	light.Color = color
	light.Brightness = LAMP_BRIGHTNESS[kind]
	light.Range = LAMP_RANGE
	if light:IsA("SpotLight") then
		light.Angle = LAMP_ANGLE
	end
	if bulb.Transparency < 1 then
		bulb.Color = color -- la bombilla, del mismo color que su luz
	end
end

local function setSign(gui: SurfaceGui, night: boolean)
	local want = if night and Perf.tier().SignGlow then SIGN_NIGHT else 1
	if gui.Brightness ~= want then
		gui.Brightness = want
	end
end

local function add(instance: Instance)
	-- (también la usan las pruebas: NearShadows.add)
	if instance:IsA("SpotLight") or instance:IsA("PointLight") or instance:IsA("SurfaceLight") then
		local light = instance :: Light
		if lamps[light] or others[light] then
			return
		end
		local bulb = light.Parent
		light.Shadows = false
		if bulb and bulb:IsA("BasePart") and bulb:HasTag("StreetLamp") then
			lamps[light] = { Light = light, Bulb = bulb }
			styleLamp(light, bulb)
			-- El servidor enciende todas las farolas al anochecer: aquí se vuelve enseguida a lo que
			-- toca (sin esperar a la siguiente vuelta, que se notaría un tirón con todas encendidas)
			light:GetPropertyChangedSignal("Enabled"):Connect(function()
				local want = desired[light]
				if want ~= nil and light.Enabled ~= want then
					light.Enabled = want
				end
			end)
		else
			others[light] = true
		end
		light.AncestryChanged:Connect(function(_, parent)
			if not parent then
				lamps[light] = nil
				others[light] = nil
				desired[light] = nil
			end
		end)
	elseif instance:IsA("SurfaceGui") then
		local parent = instance.Parent
		if parent and SIGN_PARTS[parent.Name] and instance.LightInfluence == 0 then
			signs[instance] = true
			if signNight ~= nil then
				setSign(instance, signNight)
			end
		end
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

-- Una vuelta del presupuesto (la usan también las pruebas). Devuelve cuántas farolas dan luz.
function NearShadows.step(eye: Vector3): number
	local tier = Perf.tier()
	-- Farolas encendidas (bombilla de neón) y, de ellas, las más cercanas dan luz de verdad
	local list: { Lamp } = {}
	local points: { Vector3 } = {}
	for _, lamp in lamps do
		if lamp.Bulb.Material == Enum.Material.Neon then
			table.insert(list, lamp)
			table.insert(points, lamp.Bulb.Position)
		end
	end
	local chosen = Graphics.nearest(points, eye, tier.LampLights, tier.LampRange)
	local lit = 0
	local onSet: { [Light]: boolean } = {}
	for i, lamp in list do
		if chosen[i] then
			onSet[lamp.Light] = true
			lit += 1
		end
	end
	for light in lamps do
		local want = onSet[light] == true
		desired[light] = want
		if light.Enabled ~= want then
			light.Enabled = want
		end
	end
	-- Sombras: las luces encendidas más cercanas
	local shadowPoints: { Vector3 } = {}
	local shadowLights: { Light } = {}
	if tier.ShadowLights > 0 then
		for light in onSet do
			table.insert(shadowLights, light)
			table.insert(shadowPoints, lamps[light].Bulb.Position)
		end
		for light in others do
			if light.Enabled then
				local p = position(light)
				if p then
					table.insert(shadowLights, light)
					table.insert(shadowPoints, p)
				end
			end
		end
	end
	local withShadow = Graphics.nearest(shadowPoints, eye, tier.ShadowLights, tier.ShadowRange)
	local shadowOn: { [Light]: boolean } = {}
	for i in withShadow do
		shadowOn[shadowLights[i]] = true
	end
	for _, group in { lamps, others } :: { { [Light]: any } } do
		for light in group do
			local want = shadowOn[light] == true
			if light.Shadows ~= want then
				light.Shadows = want
			end
		end
	end
	-- Carteles: solo cuando cambia la noche (o el nivel)
	local night = isNight()
	if night ~= signNight then
		signNight = night
		for gui in signs do
			if gui.Parent then
				setSign(gui, night)
			end
		end
	end
	return lit
end

NearShadows.add = add

-- Una bombilla de farola sin luz (Kit/Props pone luz en 1 de cada 2): se le pone una aquí
function NearShadows.fillLamp(bulb: Instance)
	if not bulb:IsA("BasePart") or not bulb.Parent or bulb:FindFirstChildWhichIsA("Light") then
		return
	end
	local light = Instance.new("SpotLight")
	light.Name = "LuzLocal"
	light.Face = Enum.NormalId.Bottom
	light.Shadows = false
	light.Enabled = false
	light.Parent = bulb
	if not lamps[light] then
		add(light) -- (en Roblox ya llega por DescendantAdded; así también sin él)
	end
end

function NearShadows.init()
	-- Relieve de las texturas PBR según el nivel (sin mapas normales en el Bajo)
	local ok, err = pcall(function()
		require(script.Parent.MaterialDetail).init()
	end)
	if not ok then
		warn("[MaterialDetail] " .. tostring(err))
	end
	for _, instance in workspace:GetDescendants() do
		add(instance)
	end
	workspace.DescendantAdded:Connect(add)
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		NearShadows.fillLamp(bulb)
	end
	CollectionService:GetInstanceAddedSignal("StreetLamp"):Connect(function(bulb)
		-- (un momento después: con la carga por zonas, la luz del servidor puede llegar justo detrás)
		task.delay(1, NearShadows.fillLamp, bulb)
	end)
	Perf.onTier(function()
		signNight = nil -- (que se vuelvan a pintar los carteles con el nivel nuevo)
	end)

	while true do
		task.wait(TICK)
		local camera = workspace.CurrentCamera
		if camera then
			local ok, err = pcall(NearShadows.step, camera.CFrame.Position)
			if not ok then
				warn("[NearShadows] " .. tostring(err))
			end
		end
	end
end

return NearShadows
