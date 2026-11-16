-- RegionBanner: el CARTEL que sale arriba al entrar en una de las ocho regiones de caza de Valmar
-- (shared/Cosmos/ValmarRegions): su nombre, sus niveles y si es peligrosa para el tuyo. Al volver a la
-- ciudad: «Valmar · zona segura». Solo a pie o en coche por Valmar (no en un planeta ni en el espacio).
--
-- Una región cuenta cuando estás de verdad en el campo: lejos del centro y en terreno salvaje (el relieve
-- horneado, ReplicatedStorage.ReliefMap, dice lo salvaje que es cada punto); así no salta en un barrio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ValmarRegions = require(ReplicatedStorage.Shared.Cosmos.ValmarRegions)
local Relief = require(ReplicatedStorage.Shared.Relief)
local Theme = require(script.Parent.Parent.UI.Theme)

local RegionBanner = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local DANGER = {
	Facil = { "Fácil para tu nivel: da poca experiencia", rgb(170, 200, 170) },
	Justa = { "Buena zona para tu nivel", rgb(150, 255, 150) },
	Dificil = { "⚠ Difícil para tu nivel", rgb(255, 210, 90) },
	Peligro = { "☠ Peligro: estas criaturas te superan de largo", rgb(255, 90, 80) },
}

local gui: ScreenGui
local frame: Frame
local title: TextLabel
local sub: TextLabel
local note: TextLabel
local field: any = nil
local current: string? = nil -- id de la región, "Ciudad" o nil (aún nada)
local candidate: string? = nil
local seen = 0
local hideToken = 0

local function where(): string?
	if player:GetAttribute("Planeta") ~= nil or player:GetAttribute("EnEspacio") then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local p = root.Position
	if p.Y > 1500 then
		return nil
	end
	local reg = ValmarRegions.at(p.X, p.Z, true)
	if not reg then
		return "Ciudad"
	end
	-- (en el campo de verdad: colinas salvajes y nada construido cerca; al otro lado del mar, siempre)
	if field and ValmarRegions.outside(p.X, p.Z) <= 0 then
		if Relief.amplitude(field, p.X, p.Z) < 30 or Relief.builtAt(field, p.X, p.Z) > 0.02 then
			return "Ciudad"
		end
	end
	return reg.Id
end

local function show(id: string)
	hideToken += 1
	local token = hideToken
	if id == "Ciudad" then
		title.Text = "VALMAR"
		title.TextColor3 = rgb(255, 255, 255)
		sub.Text = "Zona segura"
		note.Text = ""
	else
		local reg = ValmarRegions.ById[id]
		title.Text = (reg.Icon .. "  " .. reg.Name):upper()
		title.TextColor3 = reg.Color
		sub.Text = ("Nivel %d-%d"):format(reg.MinLevel, reg.MaxLevel)
		local level = tonumber(player:GetAttribute("Level")) or 1
		local d = DANGER[ValmarRegions.danger(reg, level)]
		note.Text = d[1]
		note.TextColor3 = d[2]
	end
	frame.Visible = true
	for _, l in { title, sub, note } do
		l.TextTransparency = 1
		TweenService:Create(l, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
	end
	task.delay(4.5, function()
		if token ~= hideToken then
			return
		end
		for _, l in { title, sub, note } do
			TweenService:Create(l, TweenInfo.new(1.2), { TextTransparency = 1 }):Play()
		end
		task.delay(1.3, function()
			if token == hideToken then
				frame.Visible = false
			end
		end)
	end)
end

function RegionBanner.init()
	local touch = game:GetService("UserInputService").TouchEnabled
	gui = create("ScreenGui", { Name = "RegionBanner", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
	frame = create("Frame", { Size = UDim2.new(0.8, 0, 0, if touch then 74 else 92), Position = UDim2.new(0.5, 0, 0, if touch then 70 else 96),
		AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Visible = false, Parent = gui })
	title = create("TextLabel", { Size = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextScaled = true,
		Text = "", TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.4, Parent = frame }, { create("UITextSizeConstraint", { MaxTextSize = 34, MinTextSize = 14 }) })
	sub = create("TextLabel", { Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextScaled = true,
		Text = "", TextColor3 = rgb(235, 235, 235), TextStrokeTransparency = 0.5, Parent = frame }, { create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 10 }) })
	note = create("TextLabel", { Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.new(0, 0, 0.75, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextScaled = true,
		Text = "", TextColor3 = rgb(200, 255, 200), TextStrokeTransparency = 0.5, Parent = frame }, { create("UITextSizeConstraint", { MaxTextSize = 17, MinTextSize = 9 }) })
	task.spawn(function()
		-- (el relieve horneado, sin frenar el arranque del resto)
		local okF, f = pcall(function()
			return Relief.fromValue(ReplicatedStorage:WaitForChild("ReliefMap", 30))
		end)
		field = okF and f or nil
		while true do
			task.wait(1)
			local ok, id = pcall(where)
			if ok then
				if id == nil then
					current, candidate, seen = nil, nil, 0
				elseif id ~= current then
					-- (dos lecturas seguidas iguales: que no parpadee en el borde)
					if id == candidate then
						seen += 1
					else
						candidate, seen = id, 1
					end
					if seen >= 2 then
						local first = current == nil
						current = id
						-- (al aparecer en la ciudad no hace falta decirlo)
						if not (first and id == "Ciudad") then
							show(id)
						end
					end
				end
			end
		end
	end)
end

return RegionBanner
