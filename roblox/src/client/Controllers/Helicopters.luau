-- Helicopters (cliente): lo que se ve y se oye de los helicópteros (etiqueta Helicopter; el servidor
-- solo los mueve, PoliceUnits). Las cuentas están en shared/Helicopter.
--
--   * Rotores: las palas del servidor se esconden en esta pantalla (LocalTransparencyModifier) y se
--     dibujan unas copias locales que giran cada fotograma pegadas al buje (así nunca pelean con lo
--     que manda el servidor). Arranque suave y, a toda velocidad, palas medio transparentes y un disco
--     borroso. Rotor de cola igual. Solo los que están cerca (Helicopter.Near).
--   * Sonido: el motor en bucle, grave y con el «chop-chop» de las palas.
--   * Foco: la mancha de luz en el suelo (elipse) persigue al sospechoso con un poco de retraso; una
--     luz de verdad cerca del suelo (SpotLight, en la línea del haz) le ilumina; y un haz fino y
--     suave (tres Beam apilados, cada vez más anchos y transparentes) que se desvanece antes de llegar
--     al suelo. Si la cámara queda dentro de la parte visible del haz, el haz se esconde.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Helicopter = require(ReplicatedStorage.Shared.Helicopter)
local SoundFx = require(script.Parent.SoundFx)

local Helicopters = {}

local player = Players.LocalPlayer
local LIGHT = Color3.fromRGB(255, 248, 225)

type BladeInfo = { Server: BasePart, Local: BasePart, Phase: number }
type Fx = {
	Lamp: Attachment,
	Tip: Attachment,
	Anchor: BasePart,
	Beams: { Beam },
	Pool: BasePart,
	Core: BasePart,
	Lens: BasePart,
	Light: SpotLight,
}
type Heli = {
	Model: Model,
	Seen: number,
	Main: number,
	Tail: number,
	Hub: BasePart?,
	Blades: { BladeInfo },
	TailServer: BasePart?,
	TailLocal: BasePart?,
	Disc: BasePart?,
	TailDisc: BasePart?,
	Lamp: BasePart?,
	Sound: Sound?,
	Spot: Vector3?,
	Fx: Fx?,
	Hidden: boolean,
}

local helis: { [Model]: Heli } = {}
local folder: Folder? = nil

Helicopters._helis = helis -- (pruebas)

local function fxFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "HeliFx"
	f.Parent = workspace
	folder = f
	return f
end

local function ghost(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

local function localCopy(server: BasePart): BasePart
	local copy = server:Clone()
	for _, child in copy:GetChildren() do
		child:Destroy()
	end
	for _, tag in CollectionService:GetTags(copy) do
		copy:RemoveTag(tag)
	end
	ghost(copy)
	copy.Parent = fxFolder()
	return copy
end

local function disc(size: number, color: Color3): BasePart
	local d = Instance.new("Part")
	d.Name = "RotorBlur"
	d.Shape = Enum.PartType.Cylinder
	d.Size = Vector3.new(0.05, size, size)
	d.Color = color
	d.Material = Enum.Material.SmoothPlastic
	d.Transparency = 1
	ghost(d)
	d.Parent = fxFolder()
	return d
end

---------------------------------------------------------------------
-- Foco
---------------------------------------------------------------------

local function seq(points: { { number } }): NumberSequence
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local BEAMS = {
	-- ancho al salir, parte del radio de la mancha al final, transparencia al salir y a media altura
	{ W0 = 0.45, W1 = 0.5, A = 0.78, B = 0.9 },
	{ W0 = 0.8, W1 = 0.78, A = 0.88, B = 0.95 },
	{ W0 = 1.2, W1 = 1.05, A = 0.94, B = 0.975 },
}

local function buildFx(): Fx
	local f = fxFolder()
	local anchor = Instance.new("Part")
	anchor.Name = "FocoAnclaje"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	ghost(anchor)
	anchor.CFrame = CFrame.new()
	anchor.Parent = f
	local lamp = Instance.new("Attachment")
	lamp.Name = "Lampara"
	lamp.Parent = anchor
	local tip = Instance.new("Attachment")
	tip.Name = "Punta"
	tip.Parent = anchor
	local visible = Helicopter.Light.Visible
	local beams = {}
	for _, spec in BEAMS do
		local b = Instance.new("Beam")
		b.Attachment0 = lamp
		b.Attachment1 = tip
		b.FaceCamera = true
		b.Segments = 1
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Color = ColorSequence.new(LIGHT)
		b.Transparency = seq({ { 0, spec.A }, { visible * 0.6, spec.B }, { visible, 0.99 }, { 1, 1 } })
		b.Width0 = spec.W0
		b.Width1 = 6
		b.Parent = anchor
		table.insert(beams, b)
	end
	-- Mancha en el suelo: un disco claro y un centro más brillante (sin chocar ni sombra)
	local pool = Instance.new("Part")
	pool.Name = "FocoSuelo"
	pool.Shape = Enum.PartType.Cylinder
	pool.Material = Enum.Material.Neon
	pool.Color = LIGHT
	pool.Transparency = 0.86
	ghost(pool)
	pool.Parent = f
	local core = pool:Clone()
	core.Name = "FocoCentro"
	core.Transparency = 0.78
	core.Parent = f
	-- La luz de verdad (cerca del suelo: más lejos no llega)
	local lens = Instance.new("Part")
	lens.Name = "FocoLuz"
	lens.Size = Vector3.new(0.2, 0.2, 0.2)
	lens.Transparency = 1
	ghost(lens)
	lens.Parent = f
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Color = LIGHT
	light.Brightness = Helicopter.Light.Brightness
	light.Range = Helicopter.Light.MaxRange
	light.Angle = Helicopter.Light.Angle
	-- Sombras solo en ordenador (en el móvil cuestan mucho)
	light.Shadows = not UserInputService.TouchEnabled
	light.Parent = lens
	return { Lamp = lamp, Tip = tip, Anchor = anchor, Beams = beams, Pool = pool, Core = core, Lens = lens, Light = light }
end

local function hideFx(fx: Fx)
	for _, b in fx.Beams do
		b.Enabled = false
	end
	fx.Pool.Transparency = 1
	fx.Core.Transparency = 1
	fx.Light.Enabled = false
end

-- A quién sigue el foco: si es a ti (o a alguien que tu pantalla ve), su posición de verdad; si no,
-- la que manda el servidor
local function targetOf(model: Model): Vector3?
	local id = model:GetAttribute("SpotUser")
	local who = if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
	local character = who and who.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position - Vector3.new(0, 2.5, 0)
	end
	local at = model:GetAttribute("SpotTarget")
	return if typeof(at) == "Vector3" then at else nil
end

-- Dónde da el haz: lo primero que encuentra (suelo, tejado…), sin contar personas ni helicópteros
local function groundHit(model: Model, from: Vector3, to: Vector3): (Vector3, Vector3)
	local dir = to - from
	if dir.Magnitude < 1 then
		return to, Vector3.yAxis
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { model, fxFolder() }
	params.FilterDescendantsInstances = ignore
	local reach = dir.Unit * (dir.Magnitude + 12)
	for _ = 1, 4 do
		local result = workspace:Raycast(from, reach, params)
		if not result then
			return to, Vector3.yAxis
		end
		local hit = result.Instance
		local person = hit:FindFirstAncestorOfClass("Model")
		local isPerson = person ~= nil and person:FindFirstChildOfClass("Humanoid") ~= nil
		if isPerson or hit.Transparency > 0.9 or hit:IsDescendantOf(fxFolder()) then
			table.insert(ignore, if isPerson then person :: Instance else hit)
			params.FilterDescendantsInstances = ignore
		else
			return result.Position, result.Normal
		end
	end
	return to, Vector3.yAxis
end

local function stepLight(heli: Heli, dt: number, camPos: Vector3)
	local lampPart = heli.Lamp
	local target = targetOf(heli.Model)
	if not heli.Fx then
		heli.Fx = buildFx()
	end
	local fx = heli.Fx :: Fx
	if not lampPart or not target then
		hideFx(fx)
		return
	end
	heli.Spot = Helicopter.follow(heli.Spot or target, target, dt)
	local lampPos = lampPart.Position
	local hit, normal = groundHit(heli.Model, lampPos, heli.Spot :: Vector3)
	local axis = hit - lampPos
	local length = axis.Magnitude
	if length < 2 then
		hideFx(fx)
		return
	end
	local dir = axis / length
	local radius = Helicopter.spotRadius(length)
	-- Mancha (elipse a lo largo de por donde llega el haz)
	local across, along = Helicopter.ellipse(dir, normal, radius)
	local flatDir = dir - normal * dir:Dot(normal)
	if flatDir.Magnitude < 1e-3 then
		flatDir = if math.abs(normal.X) < 0.9 then normal:Cross(Vector3.xAxis) else normal:Cross(Vector3.zAxis)
	end
	flatDir = flatDir.Unit
	local side = normal:Cross(flatDir).Unit
	local poolCf = CFrame.fromMatrix(hit + normal * 0.07, normal, flatDir, side)
	fx.Pool.Size = Vector3.new(0.06, along, across)
	fx.Pool.CFrame = poolCf
	fx.Pool.Transparency = 0.86
	fx.Core.Size = Vector3.new(0.07, along * 0.55, across * 0.55)
	fx.Core.CFrame = poolCf * CFrame.new(0.01, 0, 0)
	fx.Core.Transparency = 0.78
	-- Luz de verdad: en la línea del haz, a LensBack de la mancha (o en la lámpara si está más cerca)
	local back = math.min(Helicopter.Light.LensBack, length)
	local lensPos = hit - dir * back
	fx.Lens.CFrame = CFrame.lookAt(lensPos, hit)
	fx.Light.Range = math.min(Helicopter.Light.MaxRange, back + 10)
	fx.Light.Angle = Helicopter.lensAngle(radius * 1.25, back)
	fx.Light.Enabled = true
	-- Haz: de la lámpara hacia la mancha (se desvanece antes de llegar)
	fx.Anchor.CFrame = CFrame.new(lampPos)
	fx.Lamp.WorldPosition = lampPos
	fx.Tip.WorldPosition = hit - dir * 0.5
	local inside = Helicopter.insideBeam(camPos, lampPos, hit, BEAMS[#BEAMS].W0 / 2, radius * BEAMS[#BEAMS].W1, 2)
	for i, b in fx.Beams do
		b.Width1 = 2 * radius * BEAMS[i].W1
		b.Enabled = not inside
	end
end

---------------------------------------------------------------------
-- Rotores y sonido
---------------------------------------------------------------------

local function setup(model: Instance)
	if not model:IsA("Model") or helis[model] then
		return
	end
	helis[model] = {
		Model = model,
		Seen = os.clock(),
		Main = math.random() * math.pi,
		Tail = 0,
		Blades = {},
		Hidden = false,
	}
end

-- Busca (o vuelve a buscar, si aún no habían llegado) las piezas del helicóptero
local function bind(heli: Heli)
	local model = heli.Model
	if not heli.Hub then
		local hub = model:FindFirstChild("RotorHub")
		if hub and hub:IsA("BasePart") then
			heli.Hub = hub
		end
	end
	local hub = heli.Hub
	if hub and #heli.Blades == 0 then
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and child.Name == "Blade" then
				local rel = hub.CFrame:ToObjectSpace(child.CFrame)
				local _, yaw = rel:ToEulerAnglesYXZ()
				child.LocalTransparencyModifier = 1
				table.insert(heli.Blades, { Server = child, Local = localCopy(child), Phase = yaw })
			end
		end
		if #heli.Blades > 0 then
			heli.Disc = disc(heli.Blades[1].Server.Size.X, Color3.fromRGB(30, 30, 34))
		end
	end
	if not heli.TailServer then
		local tail = model:FindFirstChild("TailRotor")
		if tail and tail:IsA("BasePart") then
			heli.TailServer = tail
			tail.LocalTransparencyModifier = 1
			heli.TailLocal = localCopy(tail)
			heli.TailDisc = disc(tail.Size.Y, Color3.fromRGB(40, 40, 44))
		end
	end
	if not heli.Lamp then
		local lamp = model:FindFirstChild("Searchlight")
		if lamp and lamp:IsA("BasePart") then
			heli.Lamp = lamp
		end
	end
	if not heli.Sound then
		local body = model:FindFirstChild("Body")
		if body and body:IsA("BasePart") then
			local s = SoundFx.loop("Helicoptero", body)
			if s then
				s.RollOffMode = Enum.RollOffMode.InverseTapered
				s.RollOffMinDistance = 25
				s.RollOffMaxDistance = 420
				heli.Sound = s
			end
		end
	end
end

local function cleanup(heli: Heli)
	for _, b in heli.Blades do
		b.Local:Destroy()
	end
	for _, p in { heli.TailLocal, heli.Disc, heli.TailDisc } do
		if p then
			p:Destroy()
		end
	end
	if heli.Sound then
		heli.Sound:Destroy()
	end
	if heli.Fx then
		heli.Fx.Anchor:Destroy()
		heli.Fx.Pool:Destroy()
		heli.Fx.Core:Destroy()
		heli.Fx.Lens:Destroy()
	end
end

local function setHidden(heli: Heli, hidden: boolean)
	if heli.Hidden == hidden then
		return
	end
	heli.Hidden = hidden
	for _, b in heli.Blades do
		b.Local.Transparency = 1
	end
	for _, p in { heli.TailLocal, heli.Disc, heli.TailDisc } do
		if p then
			p.Transparency = 1
		end
	end
	if heli.Sound then
		heli.Sound.Volume = 0
	end
	if hidden and heli.Fx then
		hideFx(heli.Fx)
	end
end

-- Un fotograma: rotores, sonido y foco de cada helicóptero cercano
function Helicopters.step(dt: number)
	local camera = workspace.CurrentCamera
	local camPos = if camera then camera.CFrame.Position else Vector3.zero
	local now = os.clock()
	for model, heli in helis do
		if not model.Parent then
			cleanup(heli)
			helis[model] = nil
			continue
		end
		bind(heli)
		local hub = heli.Hub
		if not hub or (hub.Position - camPos).Magnitude > Helicopter.Near then
			setHidden(heli, true)
			continue
		end
		setHidden(heli, false)
		local t = now - heli.Seen
		local main = Helicopter.rotorSpeed(t, Helicopter.MainRate)
		heli.Main = Helicopter.advance(heli.Main, dt, main)
		heli.Tail = Helicopter.advance(heli.Tail, dt, Helicopter.rotorSpeed(t, Helicopter.TailRate))
		local bladeAlpha, discAlpha = Helicopter.blur(main / Helicopter.MainRate)
		for _, b in heli.Blades do
			b.Local.CFrame = hub.CFrame * CFrame.Angles(0, b.Phase + heli.Main, 0)
			b.Local.Transparency = bladeAlpha
		end
		if heli.Disc then
			heli.Disc.CFrame = hub.CFrame * CFrame.Angles(0, 0, math.pi / 2)
			heli.Disc.Transparency = discAlpha
		end
		local tail = heli.TailServer
		if tail and heli.TailLocal then
			heli.TailLocal.CFrame = tail.CFrame * CFrame.Angles(heli.Tail, 0, 0)
			heli.TailLocal.Transparency = bladeAlpha
			if heli.TailDisc then
				heli.TailDisc.CFrame = tail.CFrame
				heli.TailDisc.Transparency = discAlpha
			end
		end
		if heli.Sound then
			-- «chop-chop»: dos palas cruzadas = cuatro golpes por vuelta
			local chop = 0.78 + 0.22 * math.abs(math.sin(heli.Main * 2))
			heli.Sound.Volume = 0.55 * chop * math.clamp(t / Helicopter.SpinUp, 0.3, 1)
		end
		local ok, err = pcall(stepLight, heli, dt, camPos)
		if not ok then
			warn("[Helicopters] " .. tostring(err))
			if heli.Fx then
				hideFx(heli.Fx)
			end
		end
	end
end

function Helicopters.init()
	for _, model in CollectionService:GetTagged("Helicopter") do
		setup(model)
	end
	CollectionService:GetInstanceAddedSignal("Helicopter"):Connect(setup)
	CollectionService:GetInstanceRemovedSignal("Helicopter"):Connect(function(model)
		local heli = helis[model :: Model]
		if heli then
			cleanup(heli)
			helis[model :: Model] = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if next(helis) == nil then
			return
		end
		local ok, err = pcall(Helicopters.step, dt)
		if not ok then
			warn("[Helicopters] " .. tostring(err))
		end
	end)
end

return Helicopters
