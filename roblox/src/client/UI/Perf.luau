-- Perf (cliente): modo ligero para móviles y ordenadores modestos, y nivel de calidad gráfica.
-- En móvil/tableta (pantalla táctil sin teclado) o con la calidad gráfica baja, hay menos coches,
-- gente, animales y sombras a la vez. La ciudad es la misma; solo se mueve menos cosa a la vez.
--
-- Nivel gráfico (Bajo / Medio / Alto, shared/Graphics): cuántas farolas dan luz, sombras, efectos de
-- imagen, nubes, charcos… Se elige al entrar según el dispositivo y, en «Auto», se ajusta con los fps
-- de verdad (Perf.startAuto). El jugador lo puede fijar en el menú (Perf.setChoice) y se guarda con
-- su partida (vuelve al entrar, Perf.restore). Quien dependa
-- del nivel lee Perf.tier() / Perf.tierName() o se apunta a Perf.onTier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Graphics = require(ReplicatedStorage.Shared.Graphics)

local Perf = {}

local function quality(): number?
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if not ok or level == Enum.SavedQualitySetting.Automatic then
		return nil
	end
	return level.Value
end

-- Pantalla táctil sin teclado: móvil o tableta
Perf.mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local q = quality()
Perf.lite = Perf.mobile or (q ~= nil and q <= 3)
-- Cuánta vida en la calle (1 = todo; en modo ligero, la mitad)
Perf.scale = if Perf.lite then 0.5 else 1

-- En modo ligero se esconden (solo en esta pantalla) algunos detalles hechos por código de la calle:
-- mupis, motos aparcadas, aparcabicis, escaparates… (etiqueta LiteDetail, Kit/StreetDetail). Los que
-- dan carácter a la acera y cuestan poco se quedan (Graphics.LiteKeep: obras, jardineras, buzones,
-- bancos…), y nunca uno que ya lleva encima una malla nueva de la Tienda («Malla», World/CityAssets).
-- En Alto se ven TODOS (el móvil en Alto también: se esconden y se vuelven a enseñar, no se borran).
-- Van llegando con la carga por zonas, así que se miran también al llegar.
local liteItems: { [Instance]: boolean } = {}
local liteHidden = false
local function setLiteHidden(item: Instance, hide: boolean)
	local list = item:GetDescendants()
	table.insert(list, item)
	for _, d in list do
		if d:IsA("BasePart") then
			if hide then
				if d:GetAttribute("LiteCollide") == nil then
					d:SetAttribute("LiteCollide", d.CanCollide)
				end
				d.CanCollide = false
			else
				local before = d:GetAttribute("LiteCollide")
				if before ~= nil then
					d.CanCollide = before == true
					d:SetAttribute("LiteCollide", nil)
				end
			end
			d.LocalTransparencyModifier = if hide then 1 else 0
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = if hide then 1 else 0
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = not hide
		end
	end
end
local function refreshLite()
	for item in liteItems do
		if item.Parent then
			pcall(setLiteHidden, item, liteHidden)
		else
			liteItems[item] = nil
		end
	end
end

function Perf.stripDetails()
	if not Perf.lite then
		return
	end
	local CollectionService = game:GetService("CollectionService")
	local function strip(instance: Instance)
		task.defer(function()
			if instance.Parent and Graphics.liteStrips(instance.Name, instance:FindFirstChild("Malla", true) ~= nil) then
				liteItems[instance] = true
				if liteHidden then
					pcall(setLiteHidden, instance, true)
				end
			end
		end)
	end
	liteHidden = Perf.tierName() ~= "High"
	for _, m in CollectionService:GetTagged("LiteDetail") do
		strip(m)
	end
	CollectionService:GetInstanceAddedSignal("LiteDetail"):Connect(strip)
	Perf.onTier(function(name)
		local hide = name ~= "High"
		if hide ~= liteHidden then
			liteHidden = hide
			refreshLite()
		end
	end)
end

---------------------------------------------------------------------
-- Nivel gráfico
---------------------------------------------------------------------

-- (en móvil se empieza en Medio aunque la calidad de Roblox esté baja: shared/Graphics.detect)
local detected: Graphics.TierName = Graphics.detect({ Mobile = Perf.mobile, Quality = q })
local choice: Graphics.Choice = "Auto"
local auto = Graphics.newAuto(detected)
local current: Graphics.TierName = detected
local listeners: { (Graphics.TierName) -> () } = {}
-- Calidad gráfica de Roblox (1..10, o nil en «Automático»): en el móvil manda mucho
Perf.quality = q

local function localPlayer(): Player?
	local ok, player = pcall(function()
		return game:GetService("Players").LocalPlayer
	end)
	return if ok then player else nil
end

local function setCurrent(name: Graphics.TierName)
	if name == current then
		return
	end
	current = name
	pcall(function()
		(localPlayer() :: any):SetAttribute("GraphicsTier", name)
	end)
	for _, fn in listeners do
		task.spawn(fn, name)
	end
end
pcall(function()
	(localPlayer() :: any):SetAttribute("GraphicsTier", current)
end)

-- Nivel de ahora y sus presupuestos
function Perf.tierName(): Graphics.TierName
	return current
end
function Perf.tier(): Graphics.Tier
	return Graphics.tier(current)
end
function Perf.choice(): Graphics.Choice
	return choice
end
-- Avisa cuando cambia el nivel (el que elige el jugador o el automático)
function Perf.onTier(fn: (Graphics.TierName) -> ())
	table.insert(listeners, fn)
end

---------------------------------------------------------------------
-- Lo elegido se guarda con la partida (servidor: Services/SettingsService, remoto GraphicsChoice).
-- Al entrar vuelve en el atributo GraphicsChoice ANTES de que el «Auto» empiece a medir: quien lo
-- dejó en Alto entra en Alto. Con un nivel fijo, el «Auto» no lo toca nunca.
---------------------------------------------------------------------
local restored = false -- ya se sabe lo guardado (o el jugador ha elegido algo en esta partida)
local tipSeen = false

local function save(...)
	local args = table.pack(...)
	pcall(function()
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("GraphicsChoice")
		if remote then
			remote:FireServer(table.unpack(args, 1, args.n))
		end
	end)
end

local function applyChoice(new: Graphics.Choice)
	choice = new
	if new == "Auto" then
		auto = Graphics.newAuto(detected)
		setCurrent(detected)
	else
		setCurrent(new :: Graphics.TierName)
	end
end

-- «Auto» o un nivel fijo (menú «✨ Gráficos» / Ajustes): se aplica y se guarda
function Perf.setChoice(new: Graphics.Choice)
	if not Graphics.isChoice(new) then
		return
	end
	restored = true -- (lo que llegue luego de la partida ya no pisa lo que acaba de elegir)
	applyChoice(new)
	save("Choice", new)
end

-- Lo guardado: solo la primera vez que llega (después manda lo que elija el jugador)
function Perf.restore(value: any)
	if restored or not Graphics.isChoice(value) then
		return
	end
	restored = true
	applyChoice(value)
end
function Perf.restored(): boolean
	return restored
end

do
	local player = localPlayer()
	if player then
		pcall(function()
			tipSeen = player:GetAttribute("GraphicsTipSeen") == true
			Perf.restore(player:GetAttribute("GraphicsChoice"))
			player:GetAttributeChangedSignal("GraphicsChoice"):Connect(function()
				Perf.restore(player:GetAttribute("GraphicsChoice"))
			end)
			player:GetAttributeChangedSignal("GraphicsTipSeen"):Connect(function()
				tipSeen = tipSeen or player:GetAttribute("GraphicsTipSeen") == true
			end)
		end)
	end
end

-- Texto del botón del menú: siempre dice el nivel que se está usando («Auto (ahora Medio)»)
function Perf.choiceLabel(): string
	return Graphics.choiceLabel(choice, current)
end

-- Aviso al cambiar de nivel: qué cambia («Alto: sombras nítidas, reflejos…») y, una sola vez (se
-- guarda), el consejo de subir también la calidad de Roblox si está baja (en el móvil manda mucho)
function Perf.tipIfNeeded(toast: (string, string) -> ()): boolean
	if not Graphics.wantsRobloxTip(choice, q, tipSeen) then
		return false
	end
	tipSeen = true
	save("TipSeen")
	pcall(toast, "Info", "📱 " .. Graphics.RobloxTip)
	return true
end
function Perf.announce(toast: (string, string) -> ())
	local text = "✨ " .. Graphics.describe(current)
	if choice == "Auto" then
		text = ("%s · %s"):format(Perf.choiceLabel(), Graphics.describe(current))
	end
	pcall(toast, "Info", text)
	task.delay(2.5, Perf.tipIfNeeded, toast)
end

-- Mide los fps y, en «Auto», sube o baja de nivel (una sola vez, desde Main)
local WARMUP = 8 -- (los primeros segundos cargan el mapa: no cuentan)
local RESTORE_WAIT = 12 -- (si lo guardado no llega en este rato, el «Auto» empieza igual)
local autoStarted = false
function Perf.startAuto()
	if autoStarted then
		return
	end
	autoStarted = true
	local waited = 0
	RunService.Heartbeat:Connect(function(dt)
		-- (primero lo guardado: un nivel fijo no lo toca nunca el «Auto»)
		if waited < WARMUP or (not restored and waited < RESTORE_WAIT) then
			waited += dt
			return
		end
		if choice ~= "Auto" then
			return
		end
		local changed = Graphics.autoStep(auto, dt)
		if changed then
			setCurrent(changed)
		end
	end)
end

-- Cantidad ajustada (como mínimo `min`)
function Perf.count(n: number, min: number?): number
	return math.max(min or 1, math.floor(n * Perf.scale + 0.5))
end

return Perf
