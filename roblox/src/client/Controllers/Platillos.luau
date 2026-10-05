-- Platillos (cliente): las naves de las misiones locas (World/Kit/Platillo, etiqueta "Platillo"), solo
-- en tu pantalla:
--   * la que Aterriza baja del cielo balanceándose, con el motor encendido; al posarse levanta una
--     nube de polvo, da un destello de luz y tiembla un poco; luego abre la rampa (puente levadizo)
--     y por la puerta sale luz (las cucarachas salen por ahí);
--   * la que flota sube y baja despacio;
--   * todas zumban (bajo, en bucle) y las luces del borde corren en círculo; la antena parpadea.
--
-- Las cuentas son funciones puras (Platillos.landing, Platillos.lightOn): scripts/test-cucarachas.luau

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Platillos = {}

Platillos.DROP = 55 -- studs: desde dónde baja
Platillos.DESCENT = 3.2 -- segundos bajando
Platillos.RAMP_DELAY = 0.6 -- tras posarse, la rampa empieza a abrirse
Platillos.RAMP_TIME = 1.4 -- segundos abriéndose
local RADIUS = 300

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Cómo va el aterrizaje t segundos después de aparecer:
--   height (studs sobre su sitio), tilt (radianes de balanceo), ramp (0 cerrada .. 1 abierta),
--   flash (0..1 destello), landed (ya en el suelo)
function Platillos.landing(t: number): { [string]: any }
	local D = Platillos.DESCENT
	if t < D then
		local x = t / D
		-- Frena al llegar (ease-out) y se balancea cada vez menos
		local height = Platillos.DROP * (1 - x) ^ 2.2
		local tilt = math.sin(t * 5) * 0.12 * (1 - x)
		return { height = height, tilt = tilt, ramp = 0, flash = 0, landed = false }
	end
	local after = t - D
	local flash = math.max(0, 1 - after / 0.8)
	-- Un pequeño rebote de amortiguadores al posarse
	local bounce = if after < 0.5 then -math.sin(after / 0.5 * math.pi) * 0.35 else 0
	local ramp = smooth((after - Platillos.RAMP_DELAY) / Platillos.RAMP_TIME)
	return { height = bounce, tilt = 0, ramp = ramp, flash = flash, landed = true }
end

-- ¿Está encendida la luz i (de n) del borde en el instante t? (corren en círculo, de 3 en 3)
function Platillos.lightOn(i: number, n: number, t: number): boolean
	local head = math.floor(t * 10) % n
	local d = (i - 1 - head) % n
	return d < 3
end

type Entry = {
	Model: Model,
	Home: CFrame,
	Born: number,
	Landed: boolean,
	Dusted: boolean,
	Ramp: { { Part: BasePart, Offset: CFrame } },
	RampPart: BasePart?,
	Lights: { BasePart },
	Blink: { BasePart },
	Flash: PointLight?,
	Dust: ParticleEmitter?,
	Hum: Sound?,
	Colors: { [BasePart]: Color3 },
}

local entries: { [Model]: Entry } = {}

local function add(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	task.defer(function()
		if not model.Parent then
			return
		end
		local entry: Entry = {
			Model = model,
			Home = model:GetPivot(),
			Born = os.clock(),
			Landed = model:GetAttribute("Aterriza") ~= true,
			Dusted = false,
			Ramp = {},
			RampPart = nil,
			Lights = {},
			Blink = {},
			Flash = nil,
			Dust = nil,
			Hum = nil,
			Colors = {},
		}
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "Rampa" then
					entry.RampPart = d
				elseif d:GetAttribute("Luz") then
					table.insert(entry.Lights, d)
					entry.Colors[d] = d.Color
				elseif d:GetAttribute("Parpadea") then
					table.insert(entry.Blink, d)
				end
			elseif d:IsA("PointLight") and d.Name == "Destello" then
				entry.Flash = d
			elseif d:IsA("ParticleEmitter") and d.Name == "Polvo" then
				entry.Dust = d
			elseif d:IsA("Sound") and d.Name == "Zumbido" then
				entry.Hum = d
			end
		end
		local ramp = entry.RampPart
		if ramp then
			-- Lo que va pegado a la rampa (los bordes que brillan) se mueve con ella
			table.insert(entry.Ramp, { Part = ramp, Offset = CFrame.new() })
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d:GetAttribute("Rampa") then
					table.insert(entry.Ramp, { Part = d, Offset = ramp.CFrame:Inverse() * d.CFrame })
				end
			end
		end
		if entry.Hum then
			pcall(function()
				(entry.Hum :: Sound):Play()
			end)
		end
		entries[model] = entry
	end)
end

local function remove(model: Instance)
	entries[model :: Model] = nil
end

local function setRamp(entry: Entry, t: number)
	local ramp = entry.RampPart
	if not ramp then
		return
	end
	local hinge = ramp:GetAttribute("Bisagra")
	local length = ramp:GetAttribute("Largo")
	local open = ramp:GetAttribute("Abierta")
	if typeof(hinge) ~= "CFrame" or type(length) ~= "number" or type(open) ~= "number" then
		return
	end
	local angle = -math.pi / 2 - math.clamp(t, 0, 1) * (math.pi / 2 + open)
	local cf = entry.Model:GetPivot() * hinge * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, length / 2)
	for _, item in entry.Ramp do
		item.Part.CFrame = cf * item.Offset
	end
end

function Platillos.init()
	for _, model in CollectionService:GetTagged("Platillo") do
		add(model)
	end
	CollectionService:GetInstanceAddedSignal("Platillo"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("Platillo"):Connect(remove)

	RunService.RenderStepped:Connect(function()
		if next(entries) == nil then
			return
		end
		local camera = workspace.CurrentCamera
		local from = camera and camera.CFrame.Position
		local now = os.clock()
		for model, entry in entries do
			if not model.Parent then
				entries[model] = nil
				continue
			end
			if from and (entry.Home.Position - from).Magnitude > RADIUS then
				continue
			end
			local t = now - entry.Born
			-- Luces del borde y antena
			for _, light in entry.Lights do
				local on = Platillos.lightOn(light:GetAttribute("Luz") :: number, #entry.Lights, t)
				local base = entry.Colors[light]
				light.Color = if on then base else base:Lerp(Color3.new(0, 0, 0), 0.6)
			end
			for _, part in entry.Blink do
				part.Transparency = if math.floor(t * 2) % 2 == 0 then 0 else 0.7
			end
			if model:GetAttribute("Aterriza") == true then
				if not entry.Landed then
					local state = Platillos.landing(t)
					model:PivotTo(entry.Home * CFrame.new(0, state.height, 0) * CFrame.Angles(state.tilt, 0, state.tilt * 0.6))
					setRamp(entry, state.ramp)
					if entry.Flash then
						entry.Flash.Brightness = state.flash * 6
					end
					if state.landed and not entry.Dusted then
						entry.Dusted = true
						if entry.Dust then
							entry.Dust:Emit(70)
						end
					end
					if state.landed and state.ramp >= 1 and state.flash <= 0 then
						entry.Landed = true
						model:PivotTo(entry.Home)
						setRamp(entry, 1)
						if entry.Flash then
							entry.Flash.Brightness = 0
						end
					end
				end
			else
				-- Flotando: sube y baja despacio
				model:PivotTo(entry.Home * CFrame.new(0, math.sin(t * 1.3) * 0.8, 0) * CFrame.Angles(0, t * 0.15, 0))
			end
		end
	end)
end

return Platillos
