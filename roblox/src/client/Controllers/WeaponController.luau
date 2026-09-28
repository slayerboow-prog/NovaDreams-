-- WeaponController (cliente): empuñar, apuntar, disparar y recargar; la mira, las balas, la tienda
-- de la Armería y el test de la licencia. El servidor (WeaponService) decide si el disparo cuenta.
--
-- Controles (solo con un arma en la mano: se empuña eligiendo su casilla de la barra rápida):
--   Ordenador: clic derecho (mantener) apuntar · clic izquierdo disparar · R recargar · T semi/auto
--              · Mayús apuntando con mira telescópica = contener la respiración
--   Mando:     LT apuntar · RT disparar · cruceta izquierda recargar · cruceta arriba semi/auto
--   Móvil:     botones Apuntar (toca para apuntar / dejar de apuntar), Disparar (mantener = ráfaga) y
--              Recargar (TouchLayout), y arrastrar en la derecha de la pantalla sigue moviendo la cámara.
--   Menú de comandos: Disparar, Apuntar, Recargar, Objetos, Defensa, Huir.
--
-- Apuntar (~0,17 s): la cámara se pone por encima del hombro derecho (Humanoid.CameraOffset) y se
-- acerca, el campo de visión se cierra (FootCamera.setAim; con mira telescópica mucho más), el
-- personaje mira hacia donde mira la cámara (AutoRotate apagado), anda más despacio (servidor) y el
-- tronco y los brazos siguen la inclinación de la cámara (WeaponMotion). En ordenador el ratón se
-- queda en el centro mientras apuntas.
-- Mira: círculo con 4 marcas que se abre con la dispersión (moverte, saltar, disparar seguido) y se
-- pone roja encima de alguien; aspa al acertar. Balas: "12 / 36" abajo a la derecha.
-- Retroceso: la cámara salta arriba (y a un lado según el dibujo del arma) y vuelve con un muelle;
-- el cuerpo lo acusa (WeaponMotion). Agachado y tumbado (atributo Stance) se tiene menos dispersión
-- y retroceso; tumbado no se apunta hacia atrás ni al suelo. Corriendo o saltando una valla
-- (BusyMove) el arma baja y no se dispara; contra una pared el cañón se levanta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local WeaponFx = require(script.Parent.WeaponFx)
local WeaponMotion = require(script.Parent.WeaponMotion)
local FootCamera = require(script.Parent.FootCamera)
local InventoryUI = require(script.Parent.InventoryUI)
local SoundFx = require(script.Parent.SoundFx)

local WeaponController = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB
local Remote: RemoteEvent

local AIM = Weapons.Aim

-- Estado local
local wantAim = false
local aimAlpha = 0
local trigger = false
local lastShot = -math.huge
local burst = 0
local bloom = 0
local localMag: number? = nil
local reloadingUntil = 0
local camPitch, camPitchV, camYaw, camYawV = 0, 0, 0, 0
local hitMarker = 0
local hitKill = false
local savedMax: number? = nil
local startDistance = 12
local holdBreath = false
local lastPitchSent, pitchSentAt = 0, 0
local wallAmount = 0
local mouseLocked = false
local autoRotateSaved: boolean? = nil

-- Interfaz
local gui: ScreenGui
local reticle: Frame
local ticks: { Frame } = {}
local ring: UIStroke
local dot: Frame
local marker: Frame
local ammoPanel: Frame
local ammoText: TextLabel
local ammoInfo: TextLabel
local scope: Frame
local shopPanel: Frame? = nil
local quizPanel: Frame? = nil

local function weapon(): Weapons.Weapon?
	return Weapons.get(player:GetAttribute("Weapon"))
end

local function parts(): (Humanoid?, BasePart?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChild("Head") :: BasePart?
end

local function stance(): string?
	local s = player:GetAttribute("Stance")
	return if type(s) == "string" then s else nil
end

local function gunModel(character: Model?): Model?
	local model = character and character:FindFirstChild("Arma")
	return if model and model:IsA("Model") then model else nil
end

local function muzzleOf(model: Model?): CFrame?
	local grip = model and model.PrimaryPart
	local boca = grip and grip:FindFirstChild("Boca") :: Attachment?
	return boca and boca.WorldCFrame
end

local function mag(): number
	return localMag or tonumber(player:GetAttribute("WeaponMag")) or 0
end

local function lowered(): boolean
	return player:GetAttribute("Sprinting") == true or player:GetAttribute("BusyMove") == true
end

function WeaponController.armed(): boolean
	return weapon() ~= nil
end

function WeaponController.isAiming(): boolean
	return wantAim and weapon() ~= nil
end

---------------------------------------------------------------------
-- Empuñar y guardar
---------------------------------------------------------------------

function WeaponController.equip(ref: string?)
	if Remote then
		Remote:FireServer("Equip", ref)
	end
	localMag = nil
	if not ref then
		WeaponController.setAim(false)
	end
end

function WeaponController.holster()
	WeaponController.equip(nil)
end

function WeaponController.setAim(on: boolean)
	local want = on and weapon() ~= nil
	if want == wantAim then
		return
	end
	wantAim = want
	if want then
		local camera = workspace.CurrentCamera
		startDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		savedMax = savedMax or player.CameraMaxZoomDistance
	end
	if Remote then
		Remote:FireServer("Aim", want)
	end
end

function WeaponController.toggleAim()
	WeaponController.setAim(not wantAim)
end

---------------------------------------------------------------------
-- Disparar
---------------------------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function ignore(): { Instance }
	local list: { Instance } = {}
	if player.Character then
		table.insert(list, player.Character)
	end
	local fx = workspace.CurrentCamera:FindFirstChild("WeaponFx")
	if fx then
		table.insert(list, fx)
	end
	return list
end

-- Hacia dónde apunta la mira: (punto, pieza)
local function aimPoint(range: number): (Vector3, Instance?)
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	rayParams.FilterDescendantsInstances = ignore()
	local result = workspace:Raycast(ray.Origin, ray.Direction * (range + 20), rayParams)
	if result then
		return result.Position, result.Instance
	end
	return ray.Origin + ray.Direction * range, nil
end

local function isPerson(part: Instance?): boolean
	local node = part and part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node ~= player.Character
		end
		node = node.Parent
	end
	return false
end

local function dryFire(w: Weapons.Weapon)
	local _, root = parts()
	SoundFx.play("ArmaSeco", 1, 1, root)
	-- Sin balas: recarga sola si tienes munición
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	if reserve ~= 0 then
		WeaponController.reload()
	end
	local _ = w
end

function WeaponController.fire()
	local w = weapon()
	local humanoid, root, head = parts()
	if not w or not humanoid or not root or not head or humanoid.Health <= 0 or humanoid.SeatPart then
		return
	end
	local now = os.clock()
	if now < reloadingUntil or not Weapons.ready(w, lastShot, now, 0) then
		return
	end
	if lowered() or player:GetAttribute("KO") then
		return
	end
	if wallAmount > 0.5 then
		return -- el cañón choca con la pared
	end
	if mag() <= 0 then
		lastShot = now
		dryFire(w)
		return
	end
	-- Ráfaga, dispersión y retroceso
	burst = if now - lastShot <= Weapons.interval(w) * 1.8 then burst + 1 else 1
	bloom = Weapons.bloomAfter(w, if burst == 1 then 0 else bloom, now - lastShot)
	lastShot = now
	localMag = mag() - 1
	local target = aimPoint(w.Range)
	local st = stance()
	if st == "Prone" then
		local look = root.CFrame.LookVector
		local dir = Weapons.clampProne(if math.abs(look.Y) > 0.8 then root.CFrame.UpVector else look, target - head.Position)
		target = head.Position + dir * (target - head.Position).Magnitude
	else
		-- Mirando hacia donde disparas (también sin apuntar)
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		if flat.Magnitude > 0.5 and aimAlpha < 0.5 then
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
		end
	end
	Remote:FireServer("Fire", target)

	-- Lo que se ve y se oye al momento en tu pantalla
	local model = gunModel(player.Character)
	local muzzle = muzzleOf(model) or head.CFrame
	local shotCf = CFrame.lookAt(muzzle.Position, target)
	WeaponFx.muzzle(shotCf, w)
	for _ = 1, math.min(w.Pellets, 4) do
		local spread = Weapons.spread(w, { Aiming = aimAlpha > 0.5, Speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude, Stance = st, Bloom = bloom })
		local d = Weapons.scatter((target - muzzle.Position).Unit, spread, math.random(), math.random())
		WeaponFx.tracer(muzzle.Position, muzzle.Position + d * (target - muzzle.Position).Magnitude, w)
	end
	WeaponFx.shotSound(w, muzzle.Position)
	WeaponFx.casings(model, w, "Shot")
	WeaponFx.slide(model, localMag == 0, true)
	local up, side = Weapons.recoilKick(w, burst)
	local _, stanceRecoil = Weapons.stanceFactor(st)
	local k = stanceRecoil * (if aimAlpha > 0.5 then 1 else 1.25)
	camPitchV += math.rad(up) * k * 16
	camYawV += math.rad(side) * k * 16
	WeaponMotion.recoil(player.Character, stanceRecoil)
end

function WeaponController.reload()
	local w = weapon()
	if not w or os.clock() < reloadingUntil then
		return
	end
	local loaded = mag()
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	if loaded >= Weapons.capacity(w, loaded) or reserve == 0 then
		return
	end
	Remote:FireServer("Reload")
end

function WeaponController.cycleMode()
	local w = weapon()
	if w and #w.Modes > 1 then
		Remote:FireServer("Mode")
	end
end

local function setTrigger(down: boolean)
	trigger = down
	if down then
		WeaponController.fire()
	else
		if burst > 0 then
			local w = weapon()
			if w then
				WeaponFx.barrelSmoke(gunModel(player.Character), burst, w)
			end
		end
	end
end
WeaponController.setTrigger = setTrigger

---------------------------------------------------------------------
-- Lo que llega del servidor
---------------------------------------------------------------------

local function onShot(data: { [string]: any })
	local w = Weapons.get(data.W)
	local shooter = data.S :: Player?
	if not w or not shooter then
		return
	end
	local character = shooter.Character
	local model = gunModel(character)
	if shooter ~= player then
		local muzzle = muzzleOf(model)
		local hits = data.H or {}
		if muzzle and #hits > 0 then
			local target = hits[1].P
			WeaponFx.muzzle(CFrame.lookAt(muzzle.Position, target), w)
			for i = 1, math.min(#hits, 4) do
				WeaponFx.tracer(muzzle.Position, hits[i].P, w)
			end
			WeaponFx.shotSound(w, muzzle.Position)
			WeaponFx.casings(model, w, "Shot")
			local st = shooter:GetAttribute("Stance")
			local _, stanceRecoil = Weapons.stanceFactor(if type(st) == "string" then st else nil)
			WeaponMotion.recoil(character, stanceRecoil)
		end
		WeaponFx.slide(model, data.M == 0, true)
	else
		localMag = nil -- (el servidor manda)
	end
	for _, hit in data.H or {} do
		WeaponFx.impact(hit, w)
	end
	-- La gente de la calle huye si oye disparos de verdad cerca
	if w.Kind == "Real" and character then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local camera = workspace.CurrentCamera
		if root and (camera.CFrame.Position - root.Position).Magnitude < Weapons.Fx.HearDistance then
			local ok, Ambient = pcall(require, script.Parent.Ambient)
			if ok and Ambient.panic then
				Ambient.panic(root.Position, Weapons.Fx.PanicRadius)
			end
		end
	end
end

local function onReload(data: { [string]: any })
	local w = Weapons.get(data.W)
	local shooter = data.S :: Player?
	if not w or not shooter then
		return
	end
	local character = shooter.Character
	local model = gunModel(character)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local seconds = tonumber(data.T) or 1
	if shooter == player then
		reloadingUntil = os.clock() + seconds
	end
	WeaponMotion.reload(character, seconds)
	local at = if root then root.Position else Vector3.zero
	if data.K == "Shells" then
		local per = w.Reload.PerRound or 0.5
		local count = math.floor((seconds - (w.Reload.Start or 0)) / per + 0.5)
		for i = 1, count do
			task.delay((w.Reload.Start or 0) + (i - 0.5) * per, function()
				WeaponFx.soundAt("CargadorDentro", at, 0.8, 1.2)
			end)
		end
		task.delay(seconds - 0.1, function()
			WeaponFx.soundAt("Corredera", at, 0.9, 1)
		end)
		return
	end
	task.delay(seconds * 0.15, function()
		WeaponFx.soundAt("CargadorFuera", at, 0.8, 1)
		if w.Casing == "Revolver" then
			WeaponFx.casings(model, w, "Reload", data.Spent)
		elseif w.Kind ~= "Toy" then
			WeaponFx.dropMag(model)
		end
	end)
	task.delay(seconds * 0.6, function()
		WeaponFx.soundAt("CargadorDentro", at, 0.9, 1)
		WeaponFx.showMag(model)
	end)
	if data.K == "Empty" and w.Kind == "Real" then
		task.delay(seconds * 0.85, function()
			WeaponFx.soundAt("Corredera", at, 1, 1)
			WeaponFx.slide(model, false)
		end)
	end
end

---------------------------------------------------------------------
-- Interfaz: mira, marcador de acierto, balas y mira telescópica
---------------------------------------------------------------------

local function buildHud()
	gui = create("ScreenGui", { Name = "WeaponHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	-- Mira telescópica (solo el francotirador apuntando)
	scope = create("Frame", { Name = "Visor", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
	local hole = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1, Parent = scope }, {
		create("UIAspectRatioConstraint", { AspectRatio = 1 }),
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		create("UIStroke", { Thickness = 900, Color = Color3.new(0, 0, 0), Transparency = 0.02 }),
	})
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = hole })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = hole })

	-- Mira: círculo + 4 marcas + punto
	reticle = create("Frame", { Name = "Mira", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, Parent = gui })
	local circle = create("Frame", { Name = "Circulo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = reticle }, {
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	ring = create("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.15, Parent = circle })
	for i = 1, 4 do
		local horizontal = i <= 2
		local tick = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = if horizontal then UDim2.fromOffset(10, 2) else UDim2.fromOffset(2, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = reticle,
		}, { create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.6 }) })
		ticks[i] = tick
	end
	dot = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = reticle }, {
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
	})
	-- Aspa de acierto
	marker = create("Frame", { Name = "Acierto", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Visible = false, Parent = gui })
	for _, angle in { 45, -45 } do
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 3), Rotation = angle, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = marker })
	end
	-- Balas (abajo a la derecha, por encima de los botones)
	ammoPanel = Theme.panel({ Name = "Balas", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, if TouchLayout.isTouch() then -330 else -120), Size = UDim2.fromOffset(170, 62), Visible = false, Parent = gui })
	ammoText = Theme.title({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 32), Text = "0 / 0", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Right, Parent = ammoPanel })
	ammoInfo = Theme.label({ Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 20), Text = "", TextSize = 13, TextColor3 = Theme.Colors.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = ammoPanel })
end

local function refreshAmmo()
	local w = weapon()
	ammoPanel.Visible = w ~= nil
	if not w then
		return
	end
	local reserve = tonumber(player:GetAttribute("WeaponAmmo")) or 0
	local loaded = mag()
	ammoText.Text = ("%d / %s"):format(loaded, if reserve < 0 then "∞" else tostring(reserve))
	ammoText.TextColor3 = if loaded == 0 then Theme.Colors.Error elseif loaded <= math.ceil(w.Magazine / 4) then Theme.Colors.Hunger else Theme.Colors.Text
	local mode = player:GetAttribute("FireMode") or w.Modes[1]
	ammoInfo.Text = ("%s %s · %s"):format(w.Icon, w.Name, if mode == "Auto" then "AUTO" else "SEMI")
end

local function updateReticle(w: Weapons.Weapon?, speed: number)
	local camera = workspace.CurrentCamera
	local show = w ~= nil and not (w.Scope and aimAlpha > 0.9)
	reticle.Visible = show
	scope.Visible = w ~= nil and w.Scope == true and aimAlpha > 0.9
	if not w then
		marker.Visible = false
		return
	end
	local spread = Weapons.spread(w, { Aiming = aimAlpha > 0.5, Speed = speed, Stance = stance(), Bloom = math.max(0, bloom - (os.clock() - lastShot) * w.Spread.MaxBloom * 2.5), Sprinting = lowered() })
	local radius = math.clamp(Weapons.reticleRadius(spread, camera.FieldOfView, camera.ViewportSize.Y), 6, 140)
	if w.Pellets > 1 then
		radius = math.max(radius, 22)
	end
	reticle.Size = UDim2.fromOffset(radius * 2, radius * 2)
	local offsets = { Vector2.new(-radius - 7, 0), Vector2.new(radius + 7, 0), Vector2.new(0, -radius - 7), Vector2.new(0, radius + 7) }
	for i, tick in ticks do
		tick.Position = UDim2.new(0.5, offsets[i].X, 0.5, offsets[i].Y)
	end
	local _, part = aimPoint(w.Range)
	local onTarget = isPerson(part)
	local color = if onTarget then rgb(255, 60, 60) else Color3.new(1, 1, 1)
	ring.Color = color
	dot.BackgroundColor3 = color
	for _, tick in ticks do
		tick.BackgroundColor3 = color
	end
	ring.Transparency = if lowered() then 0.7 else 0.15
	-- Aspa de acierto (blanca; roja si le has dejado K.O.)
	local age = os.clock() - hitMarker
	marker.Visible = age < 0.25
	if marker.Visible then
		marker.Size = UDim2.fromOffset(22 + age * 40, 22 + age * 40)
		for _, line in marker:GetChildren() do
			if line:IsA("Frame") then
				line.BackgroundColor3 = if hitKill then rgb(255, 60, 60) else Color3.new(1, 1, 1)
				line.BackgroundTransparency = age / 0.25
			end
		end
	end
end

---------------------------------------------------------------------
-- Tienda de la Armería y test de la licencia
---------------------------------------------------------------------

local function closeShop()
	if shopPanel then
		shopPanel:Destroy()
		shopPanel = nil
	end
end

local function openShop(data: { [string]: any })
	local keepScroll = 0
	if shopPanel then
		local old = shopPanel:FindFirstChild("Lista") :: ScrollingFrame?
		keepScroll = if old then old.CanvasPosition.Y else 0
		shopPanel:Destroy()
	end
	local panel = Theme.panel({ Name = "Armeria", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 470), Parent = gui })
	shopPanel = panel
	Theme.title({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -80, 0, 30), Text = "🔫 " .. tostring(data.Name or "Armería"), TextSize = 24, Parent = panel })
	Theme.label({ Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 0, 18), Text = "Armas de verdad: mayores de edad con licencia y sin antecedentes. Juguetes: para todos.", TextSize = 13, TextColor3 = Theme.Colors.Muted, Parent = panel })
	local close = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 32), Text = "✕", Parent = panel })
	close.Activated:Connect(closeShop)
	local list = create("ScrollingFrame", {
		Name = "Lista", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -76), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel,
	}, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for i, entry in data.Items or {} do
		local row = Theme.panel({ Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = Theme.Colors.PanelLight, BackgroundTransparency = 0.3, LayoutOrder = i, Parent = list })
		Theme.label({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(40, 40), Text = entry.Icon or "", TextSize = 28, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(52, 4), Size = UDim2.new(1, -190, 0, 22), Text = entry.Name .. (if entry.Toy then "  · juguete" else ""), Font = Theme.FontBold, TextSize = 16, Parent = row })
		local detail = entry.Desc or ""
		if entry.Stats then
			local st = entry.Stats
			detail = ("Daño %d · %d disp/min · cargador %d · alcance %d · %s"):format(st.Damage, st.RPM, st.Magazine, st.Range, st.Modes)
		end
		if not entry.Ok and entry.Reason then
			detail = "⛔ " .. entry.Reason
		end
		Theme.label({ Position = UDim2.fromOffset(52, 26), Size = UDim2.new(1, -190, 0, 34), Text = detail, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = if entry.Ok then Theme.Colors.Muted else Theme.Colors.Error, Parent = row })
		local buy = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 40),
			Text = if entry.Owned then "✔ Tuya" else Format.money(entry.Price or 0),
			BackgroundColor3 = if entry.Ok then rgb(0, 150, 80) else rgb(70, 70, 80),
			AutoButtonColor = entry.Ok == true,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if not entry.Ok then
				return
			end
			if entry.Kind == "Licence" then
				Remote:FireServer("Licence")
				closeShop()
			else
				Remote:FireServer("Buy", entry.Id)
			end
		end)
	end
	list.CanvasPosition = Vector2.new(0, keepScroll)
	if not data.Refresh then
		Theme.pop(panel)
	end
end

local function closeQuiz()
	if quizPanel then
		quizPanel:Destroy()
		quizPanel = nil
	end
end

local function openQuiz(token: string, data: { [string]: any })
	closeQuiz()
	local panel = Theme.panel({ Name = "TestLicencia", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 380), Parent = gui })
	quizPanel = panel
	local questions = data.Questions or {}
	local answers = {}
	local index = 1
	local title = Theme.title({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 28), Text = "", TextSize = 20, Parent = panel })
	local text = Theme.label({ Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -32, 0, 60), Text = "", TextSize = 17, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = panel })
	local buttons: { TextButton } = {}
	local function show()
		local q = questions[index]
		if not q then
			Remote:FireServer("Answers", token, answers)
			closeQuiz()
			return
		end
		title.Text = ("🪪 Test de seguridad · %d/%d (aprobado con %d)"):format(index, #questions, data.ToPass or 4)
		text.Text = q.Text
		for i, button in buttons do
			button.Visible = q.Options[i] ~= nil
			button.Text = q.Options[i] or ""
		end
	end
	for i = 1, 3 do
		local button = Theme.button({ Position = UDim2.fromOffset(16, 110 + (i - 1) * 78), Size = UDim2.new(1, -32, 0, 68), Text = "", TextSize = 15, TextWrapped = true, Parent = panel })
		buttons[i] = button
		button.Activated:Connect(function()
			answers[index] = i
			index += 1
			show()
		end)
	end
	show()
	Theme.pop(panel)
end

---------------------------------------------------------------------
-- Cada frame: cámara al hombro, retroceso, mira y ráfagas
---------------------------------------------------------------------

local function releaseCamera()
	local humanoid = parts()
	if humanoid then
		humanoid.CameraOffset = Vector3.zero
		if autoRotateSaved ~= nil then
			humanoid.AutoRotate = autoRotateSaved
		end
	end
	autoRotateSaved = nil
	player.CameraMinZoomDistance = 0.5
	if savedMax then
		player.CameraMaxZoomDistance = savedMax
		savedMax = nil
	end
	FootCamera.setAim(0, 70)
	if mouseLocked then
		mouseLocked = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function frame(dt: number)
	local w = weapon()
	local humanoid, root, head = parts()
	local camera = workspace.CurrentCamera
	-- En una conversación o una cinemática no se apunta (ni se mueve la cámara con el retroceso):
	-- se leen los atributos que ponen DialogueUI y Cinematics, sin requerirlos
	local busy = player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
	if busy or not w or not humanoid or not root or not head or humanoid.Health <= 0 then
		if wantAim then
			WeaponController.setAim(false)
		end
		if aimAlpha > 0 then
			aimAlpha = 0
			releaseCamera()
		end
		trigger = false
		updateReticle(nil, 0)
		WeaponMotion.setLocal(0, 0, 0, 0, 0)
		return
	end
	local st = stance()
	local aiming = wantAim and not lowered() and humanoid.SeatPart == nil and not player:GetAttribute("KO")
	aimAlpha = math.clamp(aimAlpha + (if aiming then dt else -dt) / AIM.BlendTime, 0, 1)
	local eased = aimAlpha * aimAlpha * (3 - 2 * aimAlpha)

	-- Cámara al hombro (tumbado, más baja) y más cerca; campo de visión más cerrado
	local offset = if st == "Prone" then Vector3.new(1.4, -1.2, 0) elseif st == "Crouch" then Vector3.new(1.8, -0.2, 0) else AIM.CameraOffset
	humanoid.CameraOffset = offset * eased
	local fov = if w.Scope and holdBreath then w.AimFov * 0.85 else w.AimFov
	FootCamera.setAim(eased, fov)
	if aimAlpha > 0 then
		local distance = startDistance + (AIM.Zoom - startDistance) * eased
		player.CameraMaxZoomDistance = math.max(distance, 1)
		player.CameraMinZoomDistance = if aiming then 0.5 else math.max(0.5, math.min(distance, startDistance))
		-- El cuerpo mira hacia donde mira la cámara (tumbado lo gira la locomoción)
		if st ~= "Prone" then
			if autoRotateSaved == nil then
				autoRotateSaved = humanoid.AutoRotate
			end
			humanoid.AutoRotate = false
			local look = camera.CFrame.LookVector
			local yaw = math.atan2(-look.X, -look.Z)
			local current = root.CFrame
			local target = CFrame.new(current.Position) * CFrame.Angles(0, yaw, 0)
			root.CFrame = current:Lerp(target, math.min(1, dt * 22))
		end
		if UserInputService.MouseEnabled and not TouchLayout.isTouch() and aiming then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			mouseLocked = true
		end
	elseif savedMax or autoRotateSaved ~= nil or mouseLocked then
		releaseCamera()
	end

	-- Retroceso de la cámara (muelle) y balanceo apuntando
	camPitch, camPitchV = Weapons.spring(camPitch, camPitchV, w.Recoil.Return * 12, dt)
	camYaw, camYawV = Weapons.spring(camYaw, camYawV, w.Recoil.Return * 12, dt)
	local swayUp, swaySide = Weapons.sway(w, os.clock(), aimAlpha > 0.5, holdBreath)
	local swayK = eased * (if st == "Prone" then 0.3 elseif st == "Crouch" then 0.7 else 1)
	local kick = CFrame.Angles(camPitch + math.rad(swayUp) * swayK, camYaw + math.rad(swaySide) * swayK, 0)
	camera.CFrame = camera.CFrame * kick

	-- Hacia dónde apunta (arriba/abajo) y aviso al servidor para que los demás lo vean
	local pitch = math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1))
	if st == "Prone" then
		pitch = math.clamp(pitch, Weapons.ProneLimits.PitchMin, Weapons.ProneLimits.PitchMax)
	end
	local now = os.clock()
	if aimAlpha > 0.5 and math.abs(pitch - lastPitchSent) > 0.03 and now - pitchSentAt > 0.1 then
		lastPitchSent, pitchSentAt = pitch, now
		Remote:FireServer("Pitch", pitch)
	end

	-- Contra una pared: el cañón se levanta y no dispara
	rayParams.FilterDescendantsInstances = ignore()
	local wall = workspace:Raycast(head.Position, root.CFrame.LookVector * (w.Length + 1.5), rayParams)
	local blocked = Weapons.muzzleBlocked(w, if wall then wall.Distance else nil)
	wallAmount += ((if blocked then 1 else 0) - wallAmount) * math.min(1, dt * 10)
	WeaponMotion.setLocal(eased, pitch, wallAmount, math.rad(swayUp) * swayK * 0.5, math.rad(swaySide) * swayK * 0.5)

	-- Ráfaga automática mientras se mantiene el gatillo
	local mode = player:GetAttribute("FireMode") or w.Modes[1]
	if trigger and mode == "Auto" then
		WeaponController.fire()
	end
	local v = root.AssemblyLinearVelocity
	updateReticle(w, Vector3.new(v.X, 0, v.Z).Magnitude)
end

---------------------------------------------------------------------

function WeaponController.init()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapons", 30) :: RemoteEvent
	if not Remote then
		warn("[Armas] No está el remoto Weapons")
		return
	end
	WeaponFx.init()
	WeaponMotion.init()
	buildHud()

	InventoryUI.setWeaponHandler(function(ref: string?, toggle: boolean?)
		if toggle then
			WeaponController.equip(if player:GetAttribute("Weapon") == ref then nil else ref)
		elseif ref ~= player:GetAttribute("Weapon") then
			WeaponController.equip(ref)
		end
	end)

	Remote.OnClientEvent:Connect(function(kind: string, a: any, b: any, c: any)
		if kind == "Shot" then
			onShot(a)
		elseif kind == "Reload" then
			onReload(a)
		elseif kind == "Confirm" then
			hitMarker = os.clock()
			hitKill = false
			for _, hit in a or {} do
				if hit.KO or hit.Killed then
					hitKill = true
				end
			end
			SoundFx.play("Clic", 0.6, 2.2)
		elseif kind == "Dry" then
			localMag = 0
			local w = weapon()
			if w then
				dryFire(w)
			end
		elseif kind == "Shop" then
			openShop(a)
		elseif kind == "Quiz" then
			closeShop()
			openQuiz(a, b)
		elseif kind == "QuizResult" then
			closeQuiz()
			local _ = c
		end
	end)

	for _, attribute in { "Weapon", "WeaponMag", "WeaponAmmo", "FireMode" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if attribute ~= "WeaponMag" or (localMag and localMag >= (tonumber(player:GetAttribute("WeaponMag")) or 0)) then
				localMag = nil
			end
			if attribute == "Weapon" and not weapon() then
				WeaponController.setAim(false)
				trigger = false
			end
			refreshAmmo()
			TouchLayout.refresh()
		end)
	end
	player.CharacterAdded:Connect(function()
		wantAim, aimAlpha, trigger = false, 0, false
		autoRotateSaved = nil
		savedMax = nil
		releaseCamera()
	end)

	-- Ratón y mando (con un arma en la mano)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not weapon() or UserInputService:GetFocusedTextBox() then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
			WeaponController.setAim(true)
		elseif (t == Enum.UserInputType.MouseButton1 and not processed) or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if not TouchLayout.isTouch() or t ~= Enum.UserInputType.MouseButton1 then
				setTrigger(true)
			end
		elseif processed then
			return
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.DPadLeft then
			WeaponController.reload()
		elseif input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.DPadUp then
			WeaponController.cycleMode()
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			holdBreath = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
			WeaponController.setAim(false)
		elseif t == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if trigger then
				setTrigger(false)
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			holdBreath = false
		end
	end)

	-- Botones del móvil (y pistas de teclas en el ordenador): en los huecos de golpear, defender y fijar
	local armed = WeaponController.armed
	TouchLayout.register({
		Id = "Disparar", Icon = "disparar", Label = "Disparar", Slot = "Disparar", Priority = 1, Key = "Clic", Pad = "RT",
		Visible = armed,
		Hold = function(down: boolean)
			setTrigger(down)
		end,
		Badge = function()
			return if weapon() then tostring(mag()) else nil
		end,
	})
	TouchLayout.register({
		Id = "Apuntar", Icon = "objetivo", Label = "Apuntar", Slot = "Apuntar", Priority = 1, Key = "Clic dcho", Pad = "LT",
		Visible = armed,
		Active = WeaponController.isAiming,
		Callback = WeaponController.toggleAim,
	})
	TouchLayout.register({
		Id = "Recargar", Icon = "recargar", Label = "Recargar", Slot = "Recargar", Priority = 1, Key = "R",
		Visible = function()
			local w = weapon()
			return w ~= nil and mag() < Weapons.capacity(w, mag()) and (tonumber(player:GetAttribute("WeaponAmmo")) or 0) ~= 0
		end,
		Active = function()
			return if os.clock() < reloadingUntil then "wait" else false
		end,
		Callback = WeaponController.reload,
	})
	TouchLayout.register({
		Id = "ModoFuego", Icon = "pistola", Label = "Semi/Auto", Priority = 12, Key = "T",
		Visible = function()
			local w = weapon()
			return w ~= nil and #w.Modes > 1
		end,
		Callback = WeaponController.cycleMode,
	})
	TouchLayout.register({ Id = "Guardar", Icon = "bajarse", Label = "Guardar", Priority = 13, Visible = armed, Callback = WeaponController.holster })

	RunService:BindToRenderStep("WeaponCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(frame, dt)
		if not ok then
			warn("[Armas] " .. tostring(err))
		end
	end)
	refreshAmmo()
end

return WeaponController
