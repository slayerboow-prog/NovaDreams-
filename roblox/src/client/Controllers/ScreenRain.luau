-- ScreenRain (cliente): gotas de lluvia en la «lente» de la cámara mientras te mojas (v108, petición
-- del dueño). Cuándo y cuántas lo decide shared/RainLook (se prueba fuera de Roblox):
--   * Solo si llueve, la cámara no tiene nada encima (ni un toldo: Controllers/Shelter), no estás
--     dentro, ni en el metro, ni en un vehículo con techo (en bici, moto o patinete sí), ni en una
--     cinemática (cámara de cine).
--   * Más gotas mirando al frente o arriba; mirando al suelo casi ninguna.
--   * Cada gota aparece, se queda un momento, resbala dejando un rastro y se va.
-- Sutiles y baratas: como mucho 4 (Bajo) / 7 (Medio) / 10 (Alto) a la vez, muy transparentes, pequeñas,
-- nunca en el centro (donde está tu personaje) y DEBAJO del HUD (DisplayOrder negativo): no tapan
-- ningún botón. Sin lluvia no hace nada (ni recorre las gotas).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RainLook = require(ReplicatedStorage.Shared.RainLook)
local RideState = require(ReplicatedStorage.Shared.RideState)
local Metro = require(ReplicatedStorage.Shared.Metro)
local Shelter = require(script.Parent.Shelter)
local Perf = require(script.Parent.Parent.UI.Perf)

local ScreenRain = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local POOL = 10 -- (el máximo de Alto)

type Drop = { Frame: Frame, Trail: Frame, Age: number, Life: number, X: number, Y: number, Size: number, Fall: number, Alive: boolean }
local drops: { Drop } = {}
local gui: ScreenGui

local function make(className: string, props: { [string]: any }): any
	local inst = Instance.new(className)
	for key, value in props do
		(inst :: any)[key] = value
	end
	return inst
end

local function build()
	gui = make("ScreenGui", {
		Name = "RainLens",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = -5, -- debajo de todo el HUD
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	for _ = 1, POOL do
		-- El rastro de agua que deja al resbalar (una línea fina y tenue por encima de la gota)
		local trail = make("Frame", {
			Name = "Rastro",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = rgb(225, 234, 246),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = gui,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trail })
		local frame = make("Frame", {
			Name = "Gota",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = rgb(205, 216, 230),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = gui,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = frame })
		-- Cuerpo de agua: más claro abajo (la luz que atraviesa la gota) y borde fino brillante
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(rgb(150, 162, 178), rgb(240, 246, 255)),
			Parent = frame,
		})
		make("UIStroke", { Color = rgb(245, 250, 255), Thickness = 1, Transparency = 1, Parent = frame })
		-- Brillo pequeño arriba a la izquierda
		local shine = make("Frame", {
			Name = "Brillo",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.34, 0.3),
			Size = UDim2.fromScale(0.28, 0.22),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = frame,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = shine })
		table.insert(drops, { Frame = frame, Trail = trail, Age = 0, Life = 1, X = 0, Y = 0, Size = 12, Fall = 0, Alive = false })
	end
end

-- Un sitio para una gota nueva: fuera del centro (ahí está tu personaje) y no pegado a los bordes
local function spot(view: Vector2): (number, number)
	for _ = 1, 6 do
		local x, y = math.random(), 0.06 + math.random() * 0.62
		local dx, dy = (x - 0.5) / 0.3, (y - 0.55) / 0.3
		if dx * dx + dy * dy > 1 then
			return x * view.X, y * view.Y
		end
	end
	return (if math.random() < 0.5 then 0.12 else 0.88) * view.X, 0.25 * view.Y
end

local function spawnDrop(view: Vector2): boolean
	for _, d in drops do
		if not d.Alive then
			d.Alive = true
			d.Age = 0
			d.Life = 2.2 + math.random() * 2.5
			d.X, d.Y = spot(view)
			-- Tamaño según la pantalla (en el móvil, unos 10-22 px de alto)
			local unit = math.min(view.X, view.Y)
			d.Size = unit * (0.014 + math.random() * 0.022)
			d.Fall = unit * (0.08 + math.random() * 0.14)
			d.Frame.Visible = true
			return true
		end
	end
	return false
end

local function hide(d: Drop)
	d.Alive = false
	d.Frame.Visible = false
	d.Trail.Visible = false
end

local function draw(d: Drop)
	local alpha, slide, stretch = RainLook.lensDrop(d.Age, d.Life)
	local frame, trail = d.Frame, d.Trail
	local y = d.Y + d.Fall * slide
	frame.Position = UDim2.fromOffset(d.X, y)
	frame.Size = UDim2.fromOffset(d.Size * (1 - 0.15 * (stretch - 1)), d.Size * stretch)
	-- Muy transparente: se adivina el agua, no tapa
	frame.BackgroundTransparency = 1 - 0.32 * alpha
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 1 - 0.4 * alpha
	end
	local shine = frame:FindFirstChild("Brillo") :: Frame?
	if shine then
		shine.BackgroundTransparency = 1 - 0.55 * alpha
	end
	if slide > 0.02 then
		trail.Visible = true
		trail.Position = UDim2.fromOffset(d.X, y - d.Size * stretch * 0.4)
		trail.Size = UDim2.fromOffset(math.max(1, d.Size * 0.22), d.Fall * slide)
		trail.BackgroundTransparency = 1 - 0.18 * alpha
	else
		trail.Visible = false
	end
end

function ScreenRain.init()
	build()
	local Weather = require(script.Parent.Weather)
	local spawnCredit = 0
	local alive = 0
	local check = 0
	local allowed = false
	local facing = 1
	RunService.RenderStepped:Connect(function(dt)
		check += dt
		if check >= 0.25 then
			check = 0
			local camera = workspace.CurrentCamera
			local level = Weather.rainLevel()
			if level < 0.05 and alive == 0 then
				allowed = false
				if gui.Enabled then
					gui.Enabled = false
				end
				return
			end
			local shelter = Shelter.camera()
			allowed = RainLook.lensAllowed({
				Intensity = level,
				Roof = shelter.Covered,
				Enclosed = shelter.Enclosed,
				Vehicle = RideState.vehicleOf(player),
				Cinematic = camera.CameraType == Enum.CameraType.Scriptable,
				Underground = camera.CFrame.Position.Y < Metro.Underground,
			})
			facing = RainLook.lensFacing(camera.CFrame.LookVector.Y)
		end
		if not allowed and alive == 0 then
			return
		end
		gui.Enabled = true
		local view = workspace.CurrentCamera.ViewportSize
		local count, perSecond = RainLook.lensBudget(Weather.rainLevel(), Perf.tierName(), facing)
		if allowed then
			spawnCredit = math.min(spawnCredit + perSecond * dt, 2)
			if spawnCredit >= 1 and alive < count then
				if spawnDrop(view) then
					spawnCredit -= 1
				end
			end
		else
			spawnCredit = 0
		end
		alive = 0
		for _, d in drops do
			if d.Alive then
				-- Sin lluvia encima (bajo techo, en el coche…) las que quedan se van deprisa
				d.Age += if allowed then dt else dt * 4
				if d.Age >= d.Life then
					hide(d)
				else
					alive += 1
					draw(d)
				end
			end
		end
		if alive == 0 and not allowed then
			gui.Enabled = false
		end
	end)
end

return ScreenRain
