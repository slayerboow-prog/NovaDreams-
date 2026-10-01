-- StoryFx (cliente): reproduce los EFECTOS del catálogo de la historia (shared/StoryFxCatalog, que los
-- construye shared/StoryFxBuild): meteorito con estela e impacto, explosión, portal, grieta en el
-- suelo, orbe de luz, aura de poder, tormenta local, cambio de cielo, cráter, humo y chispas.
-- Solo en tu pantalla (no van por la red): cada jugador ve los de su escena.
--
--   local h = StoryFx.play("Explosion", cframe, params?, extra?)
--     extra = { To = CFrame?, Seconds = n?, Model = Model? (aura), OnEnter = fn? (portal atravesado),
--               OnChain = fn(handle)? (el impacto que lanza un meteorito), Shake = fn(fuerza, s)? }
--   StoryFx.stop(h) · StoryFx.clear()
--
-- Presupuesto según tu nivel gráfico (atributo GraphicsTier: Bajo = menos partículas, sin halos ni
-- sombras de luces) y un tope global de partículas a la vez (shared/StoryFxCatalog.Budgets).
-- Los temblores van a CameraShake (fuera de una escena) o a quien los pida (la cámara de la escena).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage.Shared.StoryFxCatalog)
local Build = require(ReplicatedStorage.Shared.StoryFxBuild)
local SkyMoods = require(ReplicatedStorage.Shared.SkyMoods)

local StoryFx = {}

local player = Players.LocalPlayer

type Active = {
	Handle: Build.Handle,
	Start: number,
	Extra: { [string]: any },
	SkyId: string?,
	Entered: number,
	Radius: number,
}

local active: { Active } = {}
local folder: Folder? = nil
local loopConnection: RBXScriptConnection? = nil
local flashGui: ScreenGui? = nil
local flashFrame: Frame? = nil
local flashUntil, flashStart, flashAmount = 0, 0, 0
local skySerial = 0
local shakeSink: ((number, number) -> ())? = nil

local function tier(): string
	return Catalog.tierName(player:GetAttribute("GraphicsTier"))
end

local function fxFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "StoryFx"
	f.Parent = workspace
	folder = f
	return f
end

-- La cámara de una escena se apunta aquí para recibir los temblores (si no, CameraShake)
function StoryFx.setShakeSink(fn: ((number, number) -> ())?)
	shakeSink = fn
end

local function cameraPosition(): Vector3?
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

-- Un sonido del catálogo (o un nombre de SoundFx) en un punto
local function playSound(name: any, position: Vector3?)
	if type(name) ~= "string" then
		return
	end
	local spec = Catalog.Sounds[name]
	if not spec then
		pcall(function()
			require(script.Parent.SoundFx).play(name)
		end)
		return
	end
	local holder: Instance = fxFolder()
	local part: Part? = nil
	if position then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.CFrame = CFrame.new(position)
		p.Parent = fxFolder()
		holder = p
		part = p
	end
	local sound = Instance.new("Sound")
	sound.SoundId = spec.Id
	sound.Volume = spec.Volume or 0.7
	sound.PlaybackSpeed = (spec.Pitch or 1) * (0.95 + math.random() * 0.1)
	sound.RollOffMaxDistance = 700
	sound.RollOffMinDistance = 25
	pcall(function()
		sound.SoundGroup = require(script.Parent.SoundFx).group("SFX")
	end)
	sound.Parent = holder
	sound:Play()
	task.delay(8, function()
		if part then
			part:Destroy()
		else
			sound:Destroy()
		end
	end)
end

-- Destello de pantalla (blanco o del color que sea), se apaga solo
local function flash(amount: number, color: Color3?, seconds: number)
	if not flashGui or not flashGui.Parent then
		local gui = Instance.new("ScreenGui")
		gui.Name = "StoryFlash"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 60
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Parent = gui
		gui.Parent = player:WaitForChild("PlayerGui")
		flashGui, flashFrame = gui, frame
	end
	(flashFrame :: Frame).BackgroundColor3 = color or Color3.new(1, 1, 1)
	flashAmount = math.clamp(amount, 0, 1)
	flashStart = os.clock()
	flashUntil = flashStart + math.max(seconds, 0.05)
end

function StoryFx.flash(amount: number, color: Color3?, seconds: number?)
	flash(amount, color, seconds or 0.4)
end

local function shake(strength: number, seconds: number, position: Vector3?, radius: number?)
	-- Más flojo cuanto más lejos (radius = hasta dónde se nota)
	local k = 1
	local cam = cameraPosition()
	if position and cam and radius then
		local d = (position - cam).Magnitude
		k = math.clamp(1 - d / radius, 0, 1)
	end
	if k <= 0.02 then
		return
	end
	if shakeSink then
		shakeSink(strength * k, seconds)
	else
		pcall(function()
			require(script.Parent.CameraShake).shake(strength * k, seconds)
		end)
	end
end

local function totalRate(): number
	local sum = 0
	for _, a in active do
		sum += a.Handle.Rate
	end
	return sum
end

local function stepAll()
	local now = os.clock()
	for i = #active, 1, -1 do
		local a = active[i]
		local ok, alive = pcall(a.Handle.Update, 1 / 60, now - a.Start)
		if ok and alive and a.Extra.OnEnter then
			-- Portal: ¿lo estás atravesando?
			local center = a.Handle.Position()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if center and root and now - a.Entered > 2 and now - a.Start > 1 then
				local d = root.Position - center
				if Vector3.new(d.X, 0, d.Z).Magnitude < a.Radius * 0.9 and math.abs(d.Y) < a.Radius + 3 then
					a.Entered = now
					flash(0.9, Color3.fromRGB(200, 255, 220), 0.6)
					playSound("Whoosh", center)
					pcall(a.Extra.OnEnter)
				end
			end
		end
		if not ok or not alive then
			if not ok then
				warn("[StoryFx] " .. tostring(alive))
			end
			pcall(a.Handle.Destroy)
			table.remove(active, i)
		end
	end
	-- Destello
	if flashFrame then
		local u = if flashUntil > flashStart then math.clamp((now - flashStart) / (flashUntil - flashStart), 0, 1) else 1
		flashFrame.BackgroundTransparency = 1 - flashAmount * (1 - u) * (1 - u)
	end
end

local function ensureLoop()
	if loopConnection then
		return
	end
	loopConnection = RunService.RenderStepped:Connect(function()
		local ok, err = pcall(stepAll)
		if not ok then
			warn("[StoryFx] " .. tostring(err))
		end
	end)
end

-- Reproduce la receta `name` en `cf`. Devuelve el handle (o nil si no existe)
function StoryFx.play(name: string, cf: CFrame, params: { [string]: any }?, extra: { [string]: any }?): Build.Handle?
	local recipe = Catalog.get(name)
	if not recipe then
		warn("[StoryFx] Efecto desconocido", name)
		return nil
	end
	local options = extra or {}
	local entry: Active
	local currentTier = tier()
	local estimate = Catalog.rate(1000, currentTier) -- (orientativo: se recalcula con lo que gaste)
	local squeeze = Catalog.squeeze(totalRate(), estimate * 0.3, currentTier)
	local ctx = {
		CFrame = cf,
		To = options.To,
		Seconds = options.Seconds,
		Params = params,
		Tier = currentTier,
		Parent = fxFolder(),
		Model = options.Model,
		Squeeze = squeeze,
		Emit = function(kind: string, a: any, b: any, c: any, d: any)
			if kind == "Sound" then
				playSound(a, b)
			elseif kind == "Shake" then
				shake(a, b, c, d)
			elseif kind == "Flash" then
				-- (los destellos de lejos no ciegan)
				local cam = cameraPosition()
				if not d or not cam or (d - cam).Magnitude < 260 then
					flash(a, b, c)
				end
			elseif kind == "Sky" then
				local mood = SkyMoods.get(a)
				if mood then
					skySerial += 1
					local id = "Fx" .. skySerial
					if entry then
						entry.SkyId = id
					end
					pcall(function()
						require(script.Parent.DayLight).pushLayer(id, mood, b)
					end)
				end
			elseif kind == "SkyPop" then
				if entry and entry.SkyId then
					local id = entry.SkyId
					entry.SkyId = nil
					pcall(function()
						require(script.Parent.DayLight).popLayer(id, a)
					end)
				end
			elseif kind == "Chain" then
				local chained = StoryFx.play(a, b, params and { Scale = params.Scale } or nil, { Shake = options.Shake })
				if chained and options.OnChain then
					pcall(options.OnChain, chained)
				end
			end
		end,
	}
	entry = {
		Handle = nil :: any,
		Start = os.clock(),
		Extra = options,
		SkyId = nil,
		Entered = 0,
		Radius = ((params and params.Radius) or recipe.Radius or 4) * ((params and params.Scale) or 1),
	}
	local ok, handle = pcall(Build.build, name, ctx)
	if not ok or not handle then
		warn("[StoryFx] No se pudo crear " .. name .. ": " .. tostring(handle))
		return nil
	end
	entry.Handle = handle
	table.insert(active, entry)
	ensureLoop()
	return handle
end

-- Para un efecto (el portal se cierra, el orbe se apaga…); si `now`, lo quita ya
function StoryFx.stop(handle: Build.Handle?, now: boolean?)
	if not handle then
		return
	end
	for i, a in active do
		if a.Handle == handle then
			if now then
				pcall(handle.Destroy)
				if a.SkyId then
					pcall(function()
						require(script.Parent.DayLight).popLayer(a.SkyId :: string, 1)
					end)
				end
				table.remove(active, i)
			else
				pcall(handle.Stop)
			end
			return
		end
	end
end

function StoryFx.clear()
	for i = #active, 1, -1 do
		StoryFx.stop(active[i].Handle, true)
	end
end

function StoryFx.count(): number
	return #active
end

return StoryFx
