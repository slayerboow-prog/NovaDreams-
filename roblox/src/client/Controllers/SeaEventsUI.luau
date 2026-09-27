-- SeaEventsUI (cliente): lo que se ve y se siente en las catástrofes marinas (SeaEventService).
--   * Alerta arriba con el nombre, el sitio, qué hacer y la cuenta atrás; sirena al empezar.
--   * Tsunami: una pared de agua con espuma que avanza desde el mar y entra en la costa; al pasar
--     tiembla la cámara y, si te pilla, te arrastra. Luego la costa se queda inundada un rato.
--   * Temporal: rayos que caen en el mar (destello, trueno) y el barco que se mece (la cámara).
--     Si nadas, las olas te empujan.
--   * Remolino: anillos de espuma que giran; si nadas cerca, te arrastra hacia el centro.
--   * Tiburón: aletas que dan vueltas cerca de la playa. Medusas: muchas medusas en el agua.
--   * La marea negra son manchas del servidor (se ven para todos): aquí solo la alerta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Perf = require(script.Parent.Parent.UI.Perf)
local SeaEvents = require(ReplicatedStorage.Shared.SeaEvents)
local SoundFx = require(script.Parent.SoundFx)

local SeaEventsUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SeaEvent") :: RemoteEvent
local rgb = Color3.fromRGB
local angles = CFrame.Angles
local sin, cos = math.sin, math.cos
local SURFACE = -2

local folder: Folder? = nil
local parts: { [string]: any } = {}
local shake = 0 -- temblor de la cámara (se va apagando)

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.clock()
end

local function getFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "SeaEventFx"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function piece(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	if shape then
		p.Shape = shape
	end
	p.Parent = getFolder()
	return p
end

local function clearFx()
	if folder then
		folder:Destroy()
		folder = nil
	end
	table.clear(parts)
end

local function rootOf(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inWater(root: BasePart): boolean
	return root.Position.Y < SURFACE + 0.6
end

---------------------------------------------------------------------
-- Cada catástrofe
---------------------------------------------------------------------

local function buildTsunami(center: Vector3, dir: Vector3)
	local kind = SeaEvents.Kinds.Tsunami
	local width = kind.Radius * 2
	local look = CFrame.lookAt(center, center + dir)
	parts.Wave = piece(Vector3.new(width, 34, 30), look, rgb(30, 110, 130), Enum.Material.Glass, 0.2)
	parts.Foam = piece(Vector3.new(width, 5, 18), look, rgb(235, 245, 250), Enum.Material.SmoothPlastic, 0.1)
	parts.Look = look
	parts.Flood = nil
end

local function updateTsunami(t: number, center: Vector3, dir: Vector3, startAt: number, endAt: number)
	local kind = SeaEvents.Kinds.Tsunami
	local front = SeaEvents.waveFront(startAt, t)
	local look: CFrame = parts.Look
	local wave: Part = parts.Wave
	local foam: Part = parts.Foam
	if front > kind.Inland + 40 then
		-- Ya ha entrado: se deshace y queda la costa inundada
		if wave.Transparency < 1 then
			wave.Transparency = 1
			foam.Transparency = 1
			local mid = look * CFrame.new(0, 0, -(kind.Inland / 2))
			parts.Flood = piece(Vector3.new(kind.Radius * 2, 2, kind.Inland + 60), mid - Vector3.new(0, mid.Position.Y - 0.5, 0), rgb(40, 110, 120), Enum.Material.Glass, 0.35)
			parts.FloodAt = t
		end
		local flood: Part? = parts.Flood
		if flood then
			local k = math.clamp((t - parts.FloodAt) / SeaEvents.FloodSeconds, 0, 1)
			flood.Transparency = 0.35 + 0.65 * k
			flood.Position = Vector3.new(flood.Position.X, 0.5 - 3 * k, flood.Position.Z)
		end
		return
	end
	-- Crece al acercarse a la costa y se rompe al llegar
	local height = if front < -200 then 12 elseif front < 0 then 12 + (front + 200) / 200 * 22 else math.max(8, 34 - front * 0.1)
	local at = look * CFrame.new(0, 0, -front) -- (lookAt mira hacia -Z: avanzar es -Z)
	wave.Size = Vector3.new(wave.Size.X, height, 30)
	local flat = at - Vector3.new(0, at.Position.Y, 0) -- (a la altura 0)
	wave.CFrame = flat + Vector3.new(0, SURFACE + height / 2 - 1, 0)
	foam.CFrame = flat * CFrame.new(0, 0, -8) + Vector3.new(0, SURFACE + height - 1.5 + sin(t * 3) * 0.5, 0)
	local root = rootOf()
	if root then
		local d = (root.Position - wave.Position) * Vector3.new(1, 0, 1)
		local along = d:Dot(dir)
		if math.abs(along) < 90 then
			shake = math.max(shake, 1 - math.abs(along) / 90)
		end
	end
end

local function buildRemolino(center: Vector3)
	local kind = SeaEvents.Kinds.Remolino
	local rings = {}
	local count = if Perf.mobile then 14 else 24
	for r = 1, 3 do
		local radius = kind.Radius * r / 3
		local ring = {}
		for i = 1, count do
			table.insert(ring, piece(Vector3.new(radius * 0.25, 0.3, 1.2), CFrame.new(center), rgb(230, 240, 245), Enum.Material.SmoothPlastic, 0.25))
		end
		table.insert(rings, { Parts = ring, Radius = radius })
	end
	parts.Rings = rings
	parts.Core = piece(Vector3.new(0.4, kind.CoreRadius * 2.2, kind.CoreRadius * 2.2), CFrame.new(center + Vector3.new(0, 0.05, 0)) * angles(0, 0, math.rad(90)), rgb(8, 30, 40), Enum.Material.SmoothPlastic, 0.1, Enum.PartType.Cylinder)
end

local function updateRemolino(t: number, dt: number, center: Vector3)
	for r, ring in parts.Rings do
		local speed = 1.6 / r
		for i, p in ring.Parts do
			local a = t * speed + i * (math.pi * 2 / #ring.Parts)
			local pos = center + Vector3.new(cos(a) * ring.Radius, 0.15 - (3 - r) * 0.15, sin(a) * ring.Radius)
			p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-sin(a), 0, cos(a))) * angles(0, math.rad(90), 0)
		end
	end
	-- Te arrastra si nadas cerca
	local root = rootOf()
	if root and inWater(root) then
		local offset = (root.Position - center) * Vector3.new(1, 0, 1)
		local dist = offset.Magnitude
		local kind = SeaEvents.Kinds.Remolino
		if dist < kind.Radius and dist > 0.5 then
			local inward = -offset.Unit
			local tangent = Vector3.new(-inward.Z, 0, inward.X)
			local k = 1 - dist / kind.Radius
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = v + (inward * 14 + tangent * 18) * k * dt * 4 + Vector3.new(0, -6 * k * dt * 4, 0)
			shake = math.max(shake, k * 0.4)
		end
	end
end

local function buildFins(center: Vector3)
	local fins = {}
	for i = 1, 2 do
		local fin = piece(Vector3.new(0.3, 1.8, 1.6), CFrame.new(center), rgb(90, 100, 110), Enum.Material.SmoothPlastic)
		table.insert(fins, { Part = fin, Phase = i * 2.3, Radius = 25 + i * 18 })
	end
	parts.Fins = fins
end

local function updateFins(t: number, center: Vector3)
	for _, f in parts.Fins do
		local a = t * 0.35 + f.Phase
		local pos = Vector3.new(center.X + cos(a) * f.Radius, SURFACE + 0.6 + sin(t * 2 + f.Phase) * 0.15, center.Z + sin(a) * f.Radius)
		f.Part.CFrame = CFrame.lookAt(pos, pos + Vector3.new(-sin(a), 0, cos(a))) * angles(0, 0, math.rad(8))
	end
end

local function buildJellies(center: Vector3)
	local jellies = {}
	local radius = SeaEvents.Kinds.Medusas.Radius
	for i = 1, (if Perf.mobile then 14 else 28) do
		local a = math.random() * math.pi * 2
		local d = math.random() * radius
		local at = center + Vector3.new(cos(a) * d, -3 - math.random() * 6, sin(a) * d)
		local color = rgb(240, 150, 220):Lerp(rgb(160, 200, 255), math.random())
		local bell = piece(Vector3.new(1.3, 0.9, 1.3), CFrame.new(at), color, Enum.Material.Glass, 0.4, Enum.PartType.Ball)
		table.insert(jellies, { Part = bell, Base = at, Phase = math.random() * 10 })
	end
	parts.Jellies = jellies
end

local function updateJellies(t: number)
	for _, j in parts.Jellies do
		local pulse = 1 + sin(t * 2.2 + j.Phase) * 0.1
		j.Part.Size = Vector3.new(1.3 * pulse, 0.9 / pulse, 1.3 * pulse)
		j.Part.CFrame = CFrame.new(j.Base + Vector3.new(sin(t * 0.3 + j.Phase) * 1.5, sin(t * 0.7 + j.Phase) * 1.2, 0))
	end
end

-- Rayo: línea de luz de las nubes al mar, destello y trueno
local function strike(pos: Vector3)
	local top = pos + Vector3.new(math.random(-20, 20), 220, math.random(-20, 20))
	local points = { top }
	for i = 1, 6 do
		local k = i / 7
		table.insert(points, top:Lerp(pos, k) + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
	end
	table.insert(points, pos)
	local bolt = {}
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local p = piece(Vector3.new(0.6, 0.6, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), rgb(220, 230, 255), Enum.Material.Neon)
		table.insert(bolt, p)
	end
	local glow = piece(Vector3.new(1, 1, 1), CFrame.new(pos), rgb(255, 255, 255), Enum.Material.Neon, 1)
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 8
	light.Color = rgb(210, 220, 255)
	light.Parent = glow
	pcall(SoundFx.play, "Golpe", 1, 0.4)
	local root = rootOf()
	if root and (root.Position - pos).Magnitude < 80 then
		shake = math.max(shake, 0.8)
	end
	task.delay(0.25, function()
		for _, p in bolt do
			p:Destroy()
		end
		glow:Destroy()
	end)
end

---------------------------------------------------------------------
-- Alerta
---------------------------------------------------------------------
local banner: Frame
local bannerText: TextLabel
local built: string? = nil

local function state(): (string?, Vector3?, Vector3?, number, number)
	local id = workspace:GetAttribute("SeaEvent")
	local pos = workspace:GetAttribute("SeaEventPos")
	local dir = workspace:GetAttribute("SeaEventDir")
	return if type(id) == "string" then id else nil, if typeof(pos) == "Vector3" then pos else nil, if typeof(dir) == "Vector3" then dir else nil, workspace:GetAttribute("SeaEventAt") or 0, workspace:GetAttribute("SeaEventEnd") or 0
end

local function siren()
	task.spawn(function()
		for i = 1, 6 do
			pcall(SoundFx.play, "Aviso", 1, if i % 2 == 0 then 0.8 else 1.1)
			task.wait(0.45)
		end
	end)
end

function SeaEventsUI.init()
	local gui = Theme.create("ScreenGui", { Name = "SeaEventGui", ResetOnSpawn = false, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	banner = Theme.panel({ Name = "SeaAlert", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(560, 58), Visible = false, Parent = gui })
	local stroke = banner:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Theme.Colors.Error
	end
	bannerText = Theme.label({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 1, -8), Text = "", RichText = true, TextSize = 15, TextWrapped = true, Parent = banner })

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Start" then
			siren()
		elseif action == "End" then
			banner.Visible = false
		elseif action == "Strike" then
			strike(data.Pos)
		elseif action == "Hit" then
			-- La ola te arrastra tierra adentro
			local root = rootOf()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root then
				root.AssemblyLinearVelocity = data.Dir * 70 + Vector3.new(0, 35, 0)
			end
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
			shake = 1
			pcall(SoundFx.play, "Chapuzon", 1, 0.6)
		elseif action == "Bite" then
			shake = math.max(shake, 0.7)
			pcall(SoundFx.play, "Golpe", 1, if data.Kind == "Tiburon" then 0.7 else 1.4)
		end
	end)

	local nextPush = 0
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			local t = serverNow()
			local id, center, dir, startAt, endAt = state()
			-- Monta o quita lo que se ve
			if id ~= built then
				clearFx()
				built = id
				if id and center and dir then
					if id == "Tsunami" then
						buildTsunami(center, dir)
					elseif id == "Remolino" then
						buildRemolino(center)
					elseif id == "Tiburon" then
						buildFins(center)
					elseif id == "Medusas" then
						buildJellies(center)
					end
				end
			end
			-- Alerta con cuenta atrás
			if id then
				local kind = SeaEvents.Kinds[id]
				local site = workspace:GetAttribute("SeaEventSite") or ""
				local left = workspace:GetAttribute("SeaEventLeft")
				local wait = math.ceil(startAt - t)
				local status = if wait > 0 then ("⏳ en %d s"):format(wait) else ("⏱️ %d s"):format(math.max(0, math.ceil(endAt - t)))
				if id == "MareaNegra" and typeof(left) == "number" then
					status ..= (" · manchas: %d"):format(left)
				end
				banner.Visible = true
				bannerText.Text = ("%s <b>%s</b> · %s · %s\n<font color=\"#ffd166\">%s</font>"):format(kind.Icon, string.upper(kind.Name), site, status, kind.Tip)
			else
				banner.Visible = false
			end
			-- (el tsunami se ve desde el aviso: la ola ya viene de lejos)
			if id == "Tsunami" and center and dir then
				updateTsunami(t, center, dir, startAt, endAt)
			elseif id == "Remolino" and center and t >= startAt then
				updateRemolino(os.clock(), dt, center)
			elseif id == "Tiburon" and center then
				updateFins(os.clock(), center)
			elseif id == "Medusas" then
				updateJellies(os.clock())
			elseif id == "Temporal" and center and t >= startAt then
				-- Las olas del temporal empujan a quien nada y mecen el barco
				local root = rootOf()
				if root and (root.Position - center).Magnitude < SeaEvents.Kinds.Temporal.Radius then
					if inWater(root) and os.clock() > nextPush then
						nextPush = os.clock() + 3 + math.random() * 2
						local a = math.random() * math.pi * 2
						root.AssemblyLinearVelocity += Vector3.new(cos(a) * 18, 10, sin(a) * 18)
					end
					shake = math.max(shake, 0.12)
				end
			end
		end)
		if not ok then
			warn("[SeaEventsUI] " .. tostring(err))
		end
	end)
	-- Temblor de la cámara (después de que Roblox coloque la cámara)
	RunService:BindToRenderStep("SeaEventShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if shake > 0.01 then
			local camera = workspace.CurrentCamera
			local k = shake * 0.035
			camera.CFrame *= angles(sin(os.clock() * 31) * k, cos(os.clock() * 27) * k, sin(os.clock() * 23) * k * 1.5)
			shake = math.max(0, shake - dt * 1.2)
		end
	end)
end

return SeaEventsUI
