-- DamagePops: pinta los números de daño que TÚ haces a la invasión (shared/DamageNumbers tiene las
-- reglas). Un solo sistema para todo: puñetazos y patadas, cada arma, el cañón de la avioneta y el láser
-- de la nave. Solo pinta lo que confirma el servidor (InvasionService manda "Dmg" a quien hace el daño:
-- Controllers/InvasionClient lo pasa aquí): nunca un número inventado por el cliente.
--
--   * Sale encima del punto donde das, sube y se desvanece (~0,8 s), con contorno.
--   * Color por tipo (blanco, amarillo cabeza/crítico, naranja cuerpo a cuerpo, cian escudo) y un poco
--     más grande cuanto más daño.
--   * Ráfagas al mismo objetivo: un solo número que suma (DamageNumbers.MergeWindow).
--   * Como mucho DamageNumbers.MaxPhone en el móvil (MaxDesktop en el ordenador).
--   * Ajuste «🔢 Números de daño: Sí/No» (menú ⚙️; ShooterPrefs.Numbers, Sí por defecto).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local DamageNumbers = require(ReplicatedStorage.Shared.DamageNumbers)
local ShooterPrefs = require(ReplicatedStorage.Shared.ShooterPrefs)

local DamagePops = {}

local player = Players.LocalPlayer
local state = DamageNumbers.new()
local guis: { [number]: BillboardGui } = {}
local pool: { BillboardGui } = {}
local anchor: Part? = nil
local rgb = Color3.fromRGB

DamagePops.shown = 0 -- (para las pruebas: cuántos se han pintado o sumado)

local function phone(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end
DamagePops.phone = phone

-- ¿Quiere ver los números? (ajuste del menú; Sí por defecto)
function DamagePops.enabled(): boolean
	local v = player:GetAttribute(ShooterPrefs.Attributes.Numbers)
	if v == nil then
		return ShooterPrefs.Defaults.Numbers ~= false
	end
	return v ~= false
end

local function color(t: { number }): Color3
	return rgb(t[1], t[2], t[3])
end

local function newGui(): BillboardGui
	local camera = workspace.CurrentCamera
	if not anchor or not anchor.Parent then
		local a = Instance.new("Part")
		a.Name = "NumerosDano"
		a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch = true, false, false, false
		a.Transparency = 1
		a.Size = Vector3.new(0.1, 0.1, 0.1)
		a.CFrame = CFrame.new()
		a.Parent = camera
		anchor = a
	end
	local g = Instance.new("BillboardGui")
	g.Name = "Dano"
	g.Size = UDim2.fromOffset(90, 34)
	g.AlwaysOnTop = true
	g.LightInfluence = 0
	g.MaxDistance = DamageNumbers.MaxDistance
	g.ResetOnSpawn = false
	g.Enabled = false
	local label = Instance.new("TextLabel")
	label.Name = "T"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = color(DamageNumbers.Stroke)
	label.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

local function release(id: number)
	local g = guis[id]
	if g then
		guis[id] = nil
		g.Enabled = false
		table.insert(pool, g)
	end
end

local function draw(e: DamageNumbers.Entry)
	local g = guis[e.Id]
	if not g then
		g = table.remove(pool) or newGui()
		guis[e.Id] = g
	end
	local gui = g :: BillboardGui
	local label = gui:FindFirstChild("T") :: TextLabel
	local s = DamageNumbers.scale(e.Amount, e.Kill)
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(math.floor(86 * s), math.floor(32 * s))
	local start = e.At + Vector3.new((math.random() - 0.5) * 1.2, 1, 0)
	gui.StudsOffsetWorldSpace = start
	label.Text = DamageNumbers.text(e.Amount)
	label.TextColor3 = color(DamageNumbers.Colors[e.Kind] or DamageNumbers.Colors.Normal)
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	gui.Enabled = true
	local token = os.clock()
	gui:SetAttribute("Token", token)
	local life = DamageNumbers.Life
	pcall(function()
		TweenService:Create(gui, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = start + Vector3.new(0, DamageNumbers.Rise, 0) }):Play()
		TweenService:Create(label, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	local id = e.Id
	task.delay(life + 0.02, function()
		if gui:GetAttribute("Token") == token then
			release(id)
		end
	end)
end

-- Un golpe confirmado por el servidor: { At, Amount, Kind, Kill, Id }
function DamagePops.show(data: any): boolean
	if type(data) ~= "table" or not DamagePops.enabled() then
		return false
	end
	local camera = workspace.CurrentCamera
	if typeof(data.At) ~= "Vector3" or (camera and (camera.CFrame.Position - data.At).Magnitude > DamageNumbers.MaxDistance) then
		return false
	end
	local e, _, evicted = DamageNumbers.push(state, os.clock(), { At = data.At, Amount = tonumber(data.Amount) or 0, Kind = data.Kind, Kill = data.Kill == true, Target = data.Id }, phone())
	if evicted then
		release(evicted.Id)
	end
	if not e then
		return false
	end
	DamagePops.shown += 1
	draw(e)
	return true
end

-- Cuántos números hay ahora en pantalla
function DamagePops.count(): number
	DamageNumbers.prune(state, os.clock())
	return #state.List
end

return DamagePops
