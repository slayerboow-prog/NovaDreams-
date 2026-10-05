-- PortalSystem: los portales de la casa de Cosme (el gigante de la sala de portales, el del garaje,
-- el vórtice de la torre-portal, el que falla en el salón y el incompleto de la habitación secreta).
--
-- Un portal NO es un círculo plano: es una ventana a otro sitio con profundidad.
--   * Aro exterior de metal con remaches y un aro de neón; aro interior que gira (CosmeSpin, en el
--     cliente) y bobinas alrededor.
--   * Túnel: discos semitransparentes apilados hacia atrás, cada uno más pequeño y más oscuro, y al
--     fondo la «ventana» del destino (imagen redonda: shared/RiftTextureIds o colores del destino).
--   * Brazos en espiral (Beams curvos hacia el fondo), remolino que gira (imagen en el disco central),
--     partículas que salen y luz.
--   * Etiqueta CosmePortal y atributos Destination (número de shared Destinations) y Active.
--
-- En el servidor (PortalSystem.activate): la secuencia de encendido (luces que parpadean, sonido,
-- aros más rápidos, cambio de destino) y el aviso a la historia (CosmeHouse/QuestHooks). El temblor
-- de cámara, la distorsión y el chorro de partículas los pone cada cliente (Controllers/CosmeHouseClient).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)

local PortalSystem = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local riftIds: { [string]: string } = {}
pcall(function()
	riftIds = require(ReplicatedStorage.Shared.RiftTextureIds) :: any
end)

-- Destinos que enseña el portal (la ventana del fondo). Travel: lo que dice la historia si cruzas.
PortalSystem.Destinations = {
	{ Id = "Espacio", Name = "Espacio profundo", Image = "rift_galaxy", Colors = { rgb(20, 10, 60), rgb(90, 60, 220), rgb(220, 160, 255) } },
	{ Id = "Pliegues", Name = "Los Pliegues", Image = "rift_interior", Colors = { rgb(40, 0, 50), rgb(200, 60, 200), rgb(255, 170, 240) } },
	{ Id = "Bosque", Name = "El bosque de otra Valmar", Image = nil, Colors = { rgb(10, 50, 20), rgb(60, 160, 80), rgb(200, 255, 170) } },
	{ Id = "Luna", Name = "La Luna (casi)", Image = nil, Colors = { rgb(10, 12, 24), rgb(150, 150, 170), rgb(240, 240, 250) } },
	{ Id = "Dimension66B", Name = "Dimensión 66-B", Image = "rift_s6_galaxy", Colors = { rgb(50, 0, 10), rgb(220, 50, 70), rgb(255, 190, 120) } },
}

function PortalSystem.imageOf(dest: { [string]: any }): string?
	local name = dest.Image
	return if name then riftIds[name] else nil
end

-- La ventana del destino: imagen redonda o, sin imagen, un paisaje de colores (cielo, suelo, siluetas)
local function paintWindow(gui: SurfaceGui, dest: { [string]: any })
	for _, c in gui:GetChildren() do
		c:Destroy()
	end
	local bg = Instance.new("Frame")
	bg.Name = "Fondo"
	bg.BorderSizePixel = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = dest.Colors[1]
	bg.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = bg
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(dest.Colors[1], dest.Colors[2])
	grad.Rotation = 90
	grad.Parent = bg
	local image = PortalSystem.imageOf(dest)
	if image then
		local img = Instance.new("ImageLabel")
		img.Name = "Destino"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = image
		img.Parent = bg
		local c2 = Instance.new("UICorner")
		c2.CornerRadius = UDim.new(0.5, 0)
		c2.Parent = img
	else
		-- Siluetas: árboles (bosque) o cráteres y la Tierra (luna)
		for i = 1, 7 do
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = if dest.Id == "Bosque" then rgb(20, 70, 30):Lerp(rgb(10, 30, 15), i / 7) else rgb(120, 120, 135)
			local w = if dest.Id == "Bosque" then 0.08 + (i % 3) * 0.03 else 0.12
			local h = if dest.Id == "Bosque" then 0.3 + (i % 4) * 0.08 else 0.06
			f.Size = UDim2.fromScale(w, h)
			f.Position = UDim2.fromScale(0.05 + i * 0.12, 0.85 - h)
			f.Parent = bg
			if dest.Id ~= "Bosque" then
				local c3 = Instance.new("UICorner")
				c3.CornerRadius = UDim.new(0.5, 0)
				c3.Parent = f
			end
		end
		local glow = Instance.new("Frame")
		glow.BorderSizePixel = 0
		glow.BackgroundColor3 = dest.Colors[3]
		glow.Size = UDim2.fromScale(0.16, 0.16)
		glow.Position = UDim2.fromScale(0.62, 0.18)
		glow.Parent = bg
		local c4 = Instance.new("UICorner")
		c4.CornerRadius = UDim.new(0.5, 0)
		c4.Parent = glow
	end
	local label = Instance.new("TextLabel")
	label.Name = "Nombre"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.8, 0.08)
	label.Position = UDim2.fromScale(0.1, 0.06)
	label.TextScaled = true
	label.TextColor3 = dest.Colors[3]
	label.TextTransparency = 0.2
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.Text = dest.Name
	label.Parent = bg
end
PortalSystem.paintWindow = paintWindow

-- Construye un portal. cf (local): centro del aro, mirando hacia -Z (desde donde se mira).
-- opts: Color (neón), Depth (fondo del túnel), Layers (discos), Spin (vueltas/s del aro interior),
--       Destination (índice), Broken (portal defectuoso: aro incompleto), Name
function PortalSystem.build(ctx: any, parent: Instance, cf: CFrame, radius: number, opts: { [string]: any }?): Model
	local o = opts or {}
	local m = Kit.group(parent, o.Name or "Portal")
	local glow = o.Color or C.Purple
	local depth = o.Depth or radius * 1.4
	local layers = o.Layers or 10
	local destIndex = o.Destination or 1
	local dest = PortalSystem.Destinations[destIndex] or PortalSystem.Destinations[1]
	local center = ctx.Site * cf
	m:AddTag("CosmePortal")
	m:SetAttribute("Destination", destIndex)
	m:SetAttribute("Active", false)
	m:SetAttribute("Radius", radius)

	-- 1) Aro exterior (metal) y aro de neón
	local n = math.max(16, math.floor(radius * 3))
	local thick = math.max(0.8, radius * 0.16)
	local seg = 2 * math.pi * (radius + thick / 2) / n + 0.15
	local frameModel = Kit.group(m, "Aro")
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		if not (o.Broken and i % 5 == 2) then
			local pos = CF(math.cos(a) * (radius + thick / 2), math.sin(a) * (radius + thick / 2), 0)
			Kit.box(ctx, frameModel, "AroMetal", V(seg, thick, thick * 1.2), cf * pos * ANG(0, 0, a + math.pi / 2), rgb(70, 74, 88), M.DiamondPlate, { CanQuery = false })
			local inner = CF(math.cos(a) * (radius + 0.05), math.sin(a) * (radius + 0.05), -thick * 0.62)
			Kit.neon(ctx, frameModel, "AroNeon", V(2 * math.pi * radius / n + 0.1, 0.25, 0.2), cf * inner * ANG(0, 0, a + math.pi / 2), glow)
			if i % math.max(2, math.floor(n / 8)) == 0 then
				Kit.deco(ctx, frameModel, "Remache", V(thick * 0.6, thick * 1.3, thick * 1.4), cf * pos * ANG(0, 0, a + math.pi / 2), rgb(150, 156, 170), M.Metal)
			end
		end
	end
	-- 2) Aro interior que gira (con marcas para que se note el giro)
	local spinner = Kit.group(m, "AroGiratorio")
	local n2 = math.max(12, math.floor(radius * 2))
	local r2 = radius - thick * 0.35
	for i = 0, n2 - 1 do
		local a = (i + 0.5) / n2 * math.pi * 2
		local p = CF(math.cos(a) * r2, math.sin(a) * r2, -thick * 0.1)
		local color = if i % 3 == 0 then glow else rgb(110, 116, 136)
		local part = Kit.deco(ctx, spinner, "Segmento", V(2 * math.pi * r2 / n2 * 0.8, thick * 0.35, thick * 0.5), cf * p * ANG(0, 0, a + math.pi / 2), color, if i % 3 == 0 then M.Neon else M.Metal, nil, true)
		part.CastShadow = false
	end
	Kit.spin(spinner, o.Spin or 0.12, "Z")
	spinner:SetAttribute("SpinCenter", center)

	-- 3) Túnel: discos cada vez más pequeños y profundos (hacia +Z, detrás del aro)
	local tunnel = Kit.group(m, "Tunel")
	for k = 1, layers do
		local t = k / layers
		local rr = radius * (1 - 0.62 * t ^ 0.8)
		local z = depth * t ^ 1.25
		local color = glow:Lerp(dest.Colors[1], t * 0.85)
		local disc = Kit.deco(ctx, tunnel, "Capa" .. k, V(0.12, rr * 2, rr * 2), cf * CF(0, 0, z) * ANG(0, math.pi / 2, 0), color, M.Neon, 0.62 - t * 0.3, true)
		disc.Shape = Enum.PartType.Cylinder
		disc.CastShadow = false
		disc:SetAttribute("Layer", k)
		-- Anillos del túnel (cada tres capas): «costillas» que dan sensación de pasillo
		if k % 3 == 0 then
			local rib = Kit.deco(ctx, tunnel, "Costilla", V(0.3, rr * 2 + 0.6, rr * 2 + 0.6), cf * CF(0, 0, z) * ANG(0, math.pi / 2, 0), dest.Colors[2], M.Neon, 0.75, true)
			rib.Shape = Enum.PartType.Cylinder
		end
	end
	-- Ventana del destino al fondo (redonda) y remolino que gira
	local back = Kit.deco(ctx, tunnel, "VentanaDestino", V(radius * 0.8, radius * 0.8, 0.1), cf * CF(0, 0, depth + 0.1), rgb(10, 10, 20), M.SmoothPlastic, 1, true)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Destino"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Parent = back
	paintWindow(gui, dest)
	local swirlPart = Kit.deco(ctx, tunnel, "Remolino", V(radius * 1.5, radius * 1.5, 0.05), cf * CF(0, 0, depth * 0.35), rgb(0, 0, 0), M.SmoothPlastic, 1, true)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Remolino"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 16
	sg.LightInfluence = 0
	sg.Brightness = 1.5
	sg.Parent = swirlPart
	local swirl = Instance.new("ImageLabel")
	swirl.Name = "Espiral"
	swirl.BackgroundTransparency = 1
	swirl.Size = UDim2.fromScale(1, 1)
	swirl.Image = riftIds.rift_glow or ""
	swirl.ImageColor3 = glow
	swirl.ImageTransparency = 0.35
	swirl:SetAttribute("SwirlSpeed", 40) -- grados por segundo (lo gira el cliente)
	swirl.Parent = sg
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0.5, 0)
	sc.Parent = swirl

	-- 4) Brazos en espiral (Beams curvos del aro al fondo)
	local core = Kit.neon(ctx, tunnel, "Nucleo", V(0.6, 0.6, 0.6), cf * CF(0, 0, depth * 0.9), dest.Colors[3], 0.1)
	core.Shape = Enum.PartType.Ball
	local arms = o.Arms or 4
	for i = 0, arms - 1 do
		local a = i / arms * math.pi * 2
		local anchor = Kit.deco(ctx, tunnel, "Brazo", V(0.2, 0.2, 0.2), cf * CF(math.cos(a) * radius * 0.92, math.sin(a) * radius * 0.92, 0.1), glow, M.Neon, 1, true)
		local beam = Kit.beam(anchor, core, glow:Lerp(dest.Colors[3], 0.4), radius * 0.18)
		beam.Width1 = 0.05
		beam.CurveSize0 = radius * 0.9
		beam.CurveSize1 = -radius * 0.4
		beam.FaceCamera = true
	end
	-- 5) Partículas y luz
	Kit.fx(core, "Portal", math.floor(10 + radius * 3))
	local light = Kit.light(ctx, core, math.min(40, radius * 4), 2, glow)
	if light then
		light.Name = "PortalLight"
	end
	local dust = Kit.neon(ctx, tunnel, "Polvo", V(radius, radius, 0.1), cf * CF(0, 0, -0.2), glow, 1)
	Kit.fx(dust, "Dust", 8)

	-- 6) Bobinas alrededor (a los lados y abajo), soldadas al aro
	if not o.NoCoils then
		for _, side in { -1, 1 } do
			local base = cf * CF(side * (radius + thick + 0.4), -radius * 0.45, 0)
			local coil = Kit.group(m, "Bobina")
			Kit.cyl(ctx, coil, "Nucleo", radius * 0.9, 0.9, base, rgb(60, 64, 76), M.Metal)
			for j = 0, 5 do
				Kit.cyl(ctx, coil, "Espira", 0.18, 1.6, base * CF(0, -radius * 0.38 + j * radius * 0.15, 0), rgb(200, 120, 60), M.Metal)
			end
			local tip = Kit.ball(ctx, coil, "Punta", 1.1, base * CF(0, radius * 0.5, 0), glow, M.Neon, 0.1)
			Kit.fx(tip, "Sparks", 6)
			local arc = Kit.beam(tip, core, rgb(200, 230, 255), 0.15, 6)
			arc.CurveSize0 = 2 * side
		end
	end
	-- Pie: del borde de abajo del aro hasta el suelo (Stand = cuánto baja)
	if o.Stand and o.Stand > 0 then
		local bottom = -(radius + thick)
		Kit.box(ctx, m, "Pie", V(radius * 0.9, o.Stand + 0.4, thick * 2), cf * CF(0, bottom - o.Stand / 2 + 0.2, 0), rgb(60, 64, 76), M.DiamondPlate, { CanQuery = false })
		Kit.box(ctx, m, "Base", V(radius * 1.6, 0.6, thick * 4), cf * CF(0, bottom - o.Stand + 0.3, 0), rgb(48, 52, 62), M.Metal, { CanQuery = false })
	end
	-- Lo de dentro flota a propósito: el túnel, el aro que levita y los brazos de energía
	Kit.anomaly(spinner)
	Kit.anomaly(tunnel)
	m:SetAttribute("Center", center)
	return m
end

---------------------------------------------------------------------
-- En el servidor: encender el portal (secuencia) y cambiar de destino
---------------------------------------------------------------------
local busy: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function setDestination(portal: Model, index: number)
	local count = #PortalSystem.Destinations
	local i = ((index - 1) % count) + 1
	portal:SetAttribute("Destination", i)
	local dest = PortalSystem.Destinations[i]
	for _, d in portal:GetDescendants() do
		if d:IsA("SurfaceGui") and d.Name == "Destino" then
			paintWindow(d, dest)
		elseif d:IsA("BasePart") and d:GetAttribute("Layer") then
			local t = (d:GetAttribute("Layer") :: number) / 12
			d.Color = d.Color:Lerp(dest.Colors[2], 0.35 + t * 0.3)
		end
	end
	return dest
end
PortalSystem.setDestination = setDestination

-- Pantallas de la sala que dicen el destino (SurfaceGui ScreenKind = "Portal")
local function updateConsoles(room: Instance?, text: string)
	if not room then
		return
	end
	for _, d in room:GetDescendants() do
		if d:IsA("SurfaceGui") and d:GetAttribute("ScreenKind") == "Portal" then
			for _, l in d:GetDescendants() do
				if l:IsA("TextLabel") then
					l.Text = "PORTAL · " .. string.upper(text)
				end
			end
		end
	end
end

-- Siguiente destino (consola de la sala). Devuelve el destino nuevo.
function PortalSystem.cycle(portal: Model): { [string]: any }
	local dest = setDestination(portal, (portal:GetAttribute("Destination") or 1) + 1)
	updateConsoles(portal.Parent, dest.Name)
	return dest
end

-- Secuencia de encendido (unos 9 s): parpadeo, zumbido, aros a toda velocidad, destino nuevo.
-- onPeak(dest): en lo más alto (QuestHooks avisa a la historia). Devuelve false si ya estaba en marcha.
function PortalSystem.activate(portal: Model, onPeak: ((any) -> ())?): boolean
	if busy[portal] then
		return false
	end
	busy[portal] = true
	task.spawn(function()
		local room = portal.Parent
		portal:SetAttribute("Active", true)
		portal:SetAttribute("ActivatedAt", workspace:GetServerTimeNow())
		-- Luces de la sala: parpadeo morado
		local lights = {}
		if room then
			for _, d in room:GetDescendants() do
				if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
					table.insert(lights, { L = d, B = d.Brightness, C = d.Color })
				end
			end
		end
		-- Zumbido (sonido de la casa: shared/SoundIds «viento» y «trueno», si están subidos)
		local sound: Sound? = nil
		pcall(function()
			local ids = require(ReplicatedStorage.Shared.SoundIds) :: any
			local core = portal:FindFirstChild("Nucleo", true) :: BasePart?
			if core and ids.viento then
				local s = Instance.new("Sound")
				s.Name = "Zumbido"
				s.SoundId = ids.viento
				s.Volume = 1.2
				s.PlaybackSpeed = 0.6
				s.RollOffMaxDistance = 120
				s.Looped = true
				s.Parent = core
				s:Play()
				sound = s
			end
		end)
		for i = 1, 10 do
			for _, l in lights do
				l.L.Brightness = if i % 2 == 0 then l.B * 2.2 else l.B * 0.25
				l.L.Color = if i % 2 == 0 then C.Purple else l.C
			end
			if sound then
				sound.PlaybackSpeed = 0.6 + i * 0.08
			end
			task.wait(0.25)
		end
		local dest = PortalSystem.cycle(portal)
		if onPeak then
			pcall(onPeak, dest)
		end
		pcall(function()
			local ids = require(ReplicatedStorage.Shared.SoundIds) :: any
			local core = portal:FindFirstChild("Nucleo", true) :: BasePart?
			if core and ids.trueno then
				local s = Instance.new("Sound")
				s.SoundId = ids.trueno
				s.Volume = 0.8
				s.RollOffMaxDistance = 120
				s.Parent = core
				s:Play()
				game:GetService("Debris"):AddItem(s, 6)
			end
		end)
		task.wait(6)
		for _, l in lights do
			l.L.Brightness = l.B
			l.L.Color = l.C
		end
		if sound then
			sound:Destroy()
		end
		portal:SetAttribute("Active", false)
		busy[portal] = nil
	end)
	return true
end

return PortalSystem
