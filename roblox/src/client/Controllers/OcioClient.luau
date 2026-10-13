-- OcioClient (cliente): lo que se ve y se oye en los sitios de ocio de las zonas verdes.
--
--   * Sonidos 3D del mundo que manda el servidor (remoto Ocio: "Sound") por SoundFx (🔔 Efectos):
--     ventas del mercadillo, aplausos de la feria, semáforo del karting…
--   * Karting (KartService): cuenta atrás grande, panel con vuelta, tiempo, mejor vuelta y puesto, y
--     el resultado al cruzar la meta.
--   * Skatepark (SkateService, shared/SkateTricks): montado en un monopatín dentro del skatepark:
--       - al pasar con velocidad el borde alto de una rampa (tag SkateRamp con Launch) sales volando
--         (Controllers/Driving.hop);
--       - en el aire: botón «Kickflip» (móvil: el botón grande del hueco de las luces, 80 de lado; ordenador:
--         K; mando: X) y giros con la dirección;
--       - por una barandilla (tag SkateRail): grind;
--       - el combo se va sumando arriba y se cobra (remoto Ocio "Combo") tras 2 s en el suelo; aterrizar
--         a mitad de un kickflip es caída y se pierde.
--     Reto de trucos: cuenta atrás y puntos del servidor.
--   * Fiesta del sábado (workspace.OcioFiesta): bullicio de gente junto al escenario.

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SportInput = require(script.Parent.SportInput)
local SoundFx = require(script.Parent.SoundFx)
local Driving = require(script.Parent.Driving)
local KartTrack = require(ReplicatedStorage.Shared.KartTrack)
local SkateTricks = require(ReplicatedStorage.Shared.SkateTricks)
local Sitios = require(ReplicatedStorage.Shared.OcioSitios)

local OcioClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local gui: ScreenGui
local panel: Frame
local panelTitle: TextLabel
local panelInfo: TextLabel
local banner: TextLabel
local bannerToken = 0

OcioClient.KICKFLIP_KEY = Enum.KeyCode.K
OcioClient.LAUNCH_MIN_SPEED = 10
OcioClient.MIN_TOUCH = 44 -- (los botones nuevos miden al menos esto en el móvil)

local function showBanner(text: string, color: Color3?, seconds: number?)
	if not banner then
		return
	end
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	banner.Visible = true
	pcall(Theme.pop, banner, 0.1)
	task.delay(seconds or 1.4, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

local function play(name: string, at: any?)
	pcall(SoundFx.play, name, { At = at })
end

---------------------------------------------------------------------
-- Karting
---------------------------------------------------------------------
local kart = { On = false, Go = nil :: number?, LapStart = nil :: number?, Lap = 1, Laps = KartTrack.LAPS, Best = nil :: number?, Place = nil :: number?, Of = nil :: number?, Mode = "" }

local function kartText(): string
	local t = if kart.LapStart then os.clock() - kart.LapStart else 0
	local place = if kart.Place and kart.Mode == "Carrera" then ("  ·  %dº de %d"):format(kart.Place, kart.Of or 4) else ""
	return ("Vuelta %d/%d  ·  %s  ·  Mejor %s%s"):format(math.min(kart.Lap, kart.Laps), kart.Laps, KartTrack.formatTime(t), KartTrack.formatTime(kart.Best), place)
end

local function onKart(kind: string, data: { [string]: any })
	if kind == "KartStart" then
		kart.On, kart.Go, kart.LapStart, kart.Lap, kart.Best, kart.Place = true, nil, nil, 1, nil, 1
		kart.Laps = tonumber(data.Laps) or KartTrack.LAPS
		kart.Of = if data.Mode == "Carrera" then 4 else 1
		kart.Mode = tostring(data.Mode or "")
		panelTitle.Text = if data.Mode == "Carrera" then "🏎️ Carrera de karts" else "🏎️ Contrarreloj"
		panel.Visible = true
		local n = tonumber(data.Countdown) or 3
		task.spawn(function()
			for k = n, 1, -1 do
				if not kart.On or kart.Go then
					return
				end
				showBanner(tostring(k), rgb(255, 80, 70), 0.9)
				task.wait(1)
			end
		end)
	elseif kind == "KartGo" then
		kart.Go = os.clock()
		kart.LapStart = kart.Go
		showBanner("¡YA!", rgb(90, 240, 110), 1)
	elseif kind == "KartLap" then
		kart.Best = tonumber(data.Best) or kart.Best
		kart.Lap = (tonumber(data.Lap) or kart.Lap) + 1
		kart.LapStart = os.clock()
		showBanner(("Vuelta %s%s"):format(KartTrack.formatTime(tonumber(data.Time)), if data.NewBest then "  ⭐" else ""), if data.NewBest then Theme.Colors.Gold else nil, 1.6)
		play(if data.NewBest then "Logro" else "Punto")
	elseif kind == "KartRank" then
		kart.Place, kart.Of = tonumber(data.Place), tonumber(data.Of)
	elseif kind == "KartFinish" then
		kart.LapStart = nil
		local place = tonumber(data.Place) or 1
		local text = if data.Mode == "Carrera" then ("🏁 %dº puesto"):format(place) else "🏁 ¡Meta!"
		showBanner(("%s  ·  mejor vuelta %s%s"):format(text, KartTrack.formatTime(tonumber(data.Best)), if data.Record then "  🏆" else ""), Theme.Colors.Gold, 4)
		play(if place == 1 then "Ovacion" else "Logro")
	elseif kind == "KartEnd" then
		kart.On = false
		panel.Visible = false
	end
end

---------------------------------------------------------------------
-- Skatepark
---------------------------------------------------------------------
local skate = {
	Combo = SkateTricks.newCombo(),
	AirStart = nil :: number?,
	Flips = 0,
	LastFlipAt = nil :: number?,
	LastYaw = nil :: number?,
	Spin = 0,
	GrindStart = nil :: number?,
	LastPos = nil :: Vector3?,
	Challenge = nil :: { Until: number, Goal: number, Score: number }?,
	Active = false,
}

local function boardModel(): Model?
	local model = Driving.current()
	if model and model:GetAttribute("Kind") == "Monopatin" then
		return model
	end
	return nil
end

function OcioClient.inSkatepark(): boolean
	local model = boardModel()
	return model ~= nil and Sitios.inside("Skate", model:GetPivot().Position, 6)
end

local function comboText(): string
	local sum, mult = SkateTricks.score(skate.Combo.Tricks)
	if #skate.Combo.Tricks == 0 then
		return if skate.Challenge then ("Reto: %d / %d  ·  %d s"):format(skate.Challenge.Score, skate.Challenge.Goal, math.max(0, math.ceil(skate.Challenge.Until - os.clock()))) else "Salta en las rampas y desliza por las barandillas"
	end
	local names = {}
	for i = math.max(1, #skate.Combo.Tricks - 3), #skate.Combo.Tricks do
		local t = skate.Combo.Tricks[i]
		table.insert(names, SkateTricks.Tricks[t.Id].Name)
	end
	return ("%s  ·  %d × %d"):format(table.concat(names, " + "), sum, mult)
end

local function addTricks(list: { SkateTricks.Trick })
	if #list == 0 then
		return
	end
	SkateTricks.add(skate.Combo, list, os.clock())
	local last = list[#list]
	showBanner(SkateTricks.Tricks[last.Id].Name .. "!", rgb(255, 220, 90), 0.9)
end

function OcioClient.kickflip()
	if not boardModel() or not Driving.airborne() then
		return
	end
	skate.Flips += 1
	skate.LastFlipAt = os.clock()
	play("Salto", boardModel())
end

local function landed()
	if not skate.AirStart then
		return
	end
	local t = os.clock()
	local airtime = t - skate.AirStart
	skate.AirStart = nil
	if SkateTricks.badLanding(skate.LastFlipAt, t) then
		local lost = SkateTricks.bail(skate.Combo)
		showBanner(if lost > 0 then "¡Caída! Combo perdido" else "¡Caída!", rgb(255, 90, 80), 1.2)
		play("GolpeCaida", boardModel())
	else
		addTricks(SkateTricks.airTricks(airtime, skate.Flips, math.deg(skate.Spin)))
		play("Aterrizaje", boardModel())
	end
	skate.Flips, skate.Spin, skate.LastFlipAt = 0, 0, nil
end

local function cashCombo()
	local done = SkateTricks.expire(skate.Combo, os.clock())
	if done and remote then
		local _, _, total = SkateTricks.score(done)
		showBanner(("+%d"):format(total), rgb(120, 230, 255), 1.2)
		play("Punto")
		remote:FireServer("Combo", { Tricks = done })
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function stepSkate(dt: number)
	local model = boardModel()
	local inPark = model ~= nil and Sitios.inside("Skate", model:GetPivot().Position, 6)
	if inPark ~= skate.Active then
		skate.Active = inPark
		panel.Visible = inPark or kart.On
		if inPark then
			panelTitle.Text = "🛹 Skatepark de la Ribera"
		end
		pcall(TouchLayout.refresh)
	end
	if skate.Challenge and os.clock() > skate.Challenge.Until + 3 then
		skate.Challenge = nil
	end
	if not model or not inPark then
		skate.LastPos, skate.AirStart, skate.GrindStart = nil, nil, nil
		if #skate.Combo.Tricks > 0 then
			cashCombo()
		end
		return
	end
	local cf = model:GetPivot()
	local pos = cf.Position
	local vel = if skate.LastPos and dt > 0 then (pos - skate.LastPos) / dt else Vector3.zero
	skate.LastPos = pos
	local yaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
	-- En el aire: cuenta los giros
	if Driving.airborne() then
		if not skate.AirStart then
			skate.AirStart = os.clock()
			skate.Spin = 0
			skate.LastYaw = yaw
		end
		local d = yaw - (skate.LastYaw or yaw)
		d = (d + math.pi) % (2 * math.pi) - math.pi
		skate.Spin += d
		skate.LastYaw = yaw
		return
	end
	-- En el suelo: ¿qué pisa? (rampa con borde de salto o barandilla)
	rayParams.FilterDescendantsInstances = { model, player.Character :: Instance }
	local hit = workspace:Raycast(pos + Vector3.new(0, 1.5, 0), Vector3.new(0, -4, 0), rayParams)
	local part = hit and hit.Instance
	if part and CollectionService:HasTag(part, "SkateRail") then
		skate.GrindStart = skate.GrindStart or os.clock()
	elseif skate.GrindStart then
		local s = os.clock() - skate.GrindStart
		skate.GrindStart = nil
		if s >= 0.3 then
			addTricks({ { Id = "Grind", S = math.floor(s * 100) / 100 } })
		end
	end
	if part and part:IsA("BasePart") and CollectionService:HasTag(part, "SkateRamp") and part:GetAttribute("Launch") == true then
		-- Borde alto: la +Z de la cuña. Si vas hacia él con velocidad y estás a menos de 1,5 studs, ¡salto!
		local loc = part.CFrame:PointToObjectSpace(pos)
		local along = part.CFrame.LookVector:Dot(vel) * -1 -- (velocidad hacia +Z local)
		if loc.Z > part.Size.Z / 2 - 1.5 and along > OcioClient.LAUNCH_MIN_SPEED then
			if Driving.hop(math.clamp(along * 0.5, 10, 24)) then
				skate.Flips, skate.Spin, skate.LastFlipAt = 0, 0, nil
			end
		end
	end
	cashCombo()
end

local function onSkate(kind: string, data: { [string]: any })
	if kind == "SkateChallenge" then
		skate.Challenge = { Until = os.clock() + (tonumber(data.Seconds) or 60), Goal = tonumber(data.Goal) or 2500, Score = 0 }
		showBanner("🛹 ¡Reto de trucos!", Theme.Colors.Gold, 1.6)
	elseif kind == "SkateScore" then
		if skate.Challenge and tonumber(data.Challenge) then
			skate.Challenge.Score = tonumber(data.Challenge) :: number
		end
	elseif kind == "SkateChallengeEnd" then
		skate.Challenge = nil
		showBanner(if data.Won then ("🏆 ¡Reto superado! %d"):format(tonumber(data.Score) or 0) else ("Reto: %d de %d"):format(tonumber(data.Score) or 0, tonumber(data.Goal) or 0), if data.Won then Theme.Colors.Gold else nil, 3)
	end
end

---------------------------------------------------------------------
-- Fiesta del sábado: bullicio junto al escenario
---------------------------------------------------------------------
local crowd: Sound? = nil
local function stepFiesta()
	local on = workspace:GetAttribute("OcioFiesta") == true
	local stage = CollectionService:GetTagged("OcioStage")[1]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local near = on and stage and root and (stage.Position - root.Position).Magnitude < 160
	if near and not crowd then
		local ok, sound = pcall(SoundFx.loop, "Multitud", stage)
		crowd = if ok then sound else nil
	elseif not near and crowd then
		crowd:Destroy()
		crowd = nil
	end
end

---------------------------------------------------------------------
function OcioClient.init()
	gui = create("ScreenGui", { Name = "OcioGui", ResetOnSpawn = false, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
	panel = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(460, 62), Visible = false, Parent = gui })
	panelTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 26), Font = Theme.FontBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Parent = panel })
	panelInfo = Theme.label({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 26), TextSize = 15, TextWrapped = true, TextColor3 = Theme.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = panel })
	banner = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(640, 60), Font = Theme.FontBold, TextSize = 42, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = gui })

	-- Kickflip: botón grande en el móvil (al volante, el hueco de las luces: el monopatín no lleva) y K / X
	TouchLayout.register({
		Id = "Kickflip",
		Icon = "saltar",
		Label = "Kickflip",
		DriveSlot = "Luces",
		Priority = 2,
		Key = "K",
		Pad = "X",
		Visible = function()
			return skate.Active
		end,
		Callback = OcioClient.kickflip,
		Active = function()
			return Driving.airborne()
		end,
	})
	ContextActionService:BindAction("OcioKickflip", function(_, state)
		if state == Enum.UserInputState.Begin and skate.Active then
			OcioClient.kickflip()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, OcioClient.KICKFLIP_KEY, Enum.KeyCode.ButtonX)
	Driving.onLand(function(kind)
		if kind == "Monopatin" then
			landed()
		end
	end)

	task.spawn(function()
		remote = SportInput.remote("Ocio") :: RemoteEvent
		(remote :: RemoteEvent).OnClientEvent:Connect(function(kind, data)
			data = if type(data) == "table" then data else {}
			local ok, err = pcall(function()
				if kind == "Sound" and type(data.Name) == "string" then
					play(data.Name, if typeof(data.At) == "Vector3" then data.At else nil)
				elseif string.sub(kind, 1, 4) == "Kart" then
					onKart(kind, data)
				elseif string.sub(kind, 1, 5) == "Skate" then
					onSkate(kind, data)
				end
			end)
			if not ok then
				warn("[Ocio] " .. tostring(err))
			end
		end)
	end)

	local fiestaAt = 0
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(stepSkate, dt)
		if not ok then
			warn("[Ocio] " .. tostring(err))
		end
		if kart.On then
			panelInfo.Text = kartText()
		elseif skate.Active then
			panelInfo.Text = comboText()
		end
		fiestaAt += dt
		if fiestaAt > 2 then
			fiestaAt = 0
			pcall(stepFiesta)
		end
	end)
end

return OcioClient
