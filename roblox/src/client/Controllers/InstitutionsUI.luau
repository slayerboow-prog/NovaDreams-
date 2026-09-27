-- InstitutionsUI (cliente): lo que se ve de las instituciones del Estado.
--   * Juez/a: panel del caso (acusado, delitos, antecedentes) con ABSOLVER, MULTA o PRISIÓN
--     (minutos con − y +) y el tiempo que queda para decidir.
--   * Acusado/a: aviso del juicio y la sentencia.
--   * Preso/a: cuenta atrás de la condena bajo el reloj y cómo reducirla.
--   * Ascensos: aviso grande con el rango nuevo.
--   * Hacienda: aviso de la cuota pendiente.
--   * CareerService.summary: "Mi carrera" (rango y puntos en cada institución) para el menú.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Institutions = require(ReplicatedStorage.Shared.Institutions)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)
local SoundFx = require(script.Parent.SoundFx)

local InstitutionsUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local justiceRemote: RemoteEvent?
local casePanel: Frame?
local jailBar: Frame
local jailText: TextLabel

---------------------------------------------------------------------
-- Panel del juez
---------------------------------------------------------------------
local function closeCase()
	if casePanel then
		casePanel:Destroy()
		casePanel = nil
	end
end

local function openCase(case: { [string]: any })
	closeCase()
	SoundFx.play("Aviso", 1, 0.9)
	local panel = Theme.panel({
		Name = "CasePanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 380),
		Parent = gui,
	})
	casePanel = panel
	Theme.padding(16).Parent = panel
	Theme.title({ Size = UDim2.new(1, 0, 0, 30), Text = "⚖ CASO Nº " .. case.Id, TextSize = 24, Parent = panel })
	Theme.label({ Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold, Text = ("Acusado/a: %s   %s"):format(case.Accused, string.rep("★", case.Stars)), TextSize = 17, Parent = panel })
	Theme.label({ Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 18), Text = ("Antecedentes: %d"):format(case.Records or 0), TextSize = 14, TextColor3 = C.Muted, Parent = panel })
	Theme.label({
		Position = UDim2.fromOffset(0, 84),
		Size = UDim2.new(1, 0, 0, 96),
		Text = "Delitos:\n• " .. table.concat(case.Crimes, "\n• "),
		TextSize = 15,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = panel,
	})
	local timer = Theme.label({ Position = UDim2.fromOffset(0, 186), Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 13, TextColor3 = C.Gold, Parent = panel })
	local minutes = 3
	local function send(kind: string)
		if justiceRemote then
			justiceRemote:FireServer("Verdict", case.Id, kind, minutes)
		end
		SoundFx.play("MenuOk")
		closeCase()
	end
	local row = create("Frame", { Position = UDim2.fromOffset(0, 214), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = panel })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = row })
	Theme.button({ Size = UDim2.fromOffset(136, 44), Text = "Absolver", TextSize = 17, BackgroundColor3 = rgb(40, 130, 80), Parent = row }).Activated:Connect(function()
		send("Absolver")
	end)
	Theme.button({ Size = UDim2.fromOffset(136, 44), Text = "Solo multa", TextSize = 17, BackgroundColor3 = rgb(180, 140, 30), Parent = row }).Activated:Connect(function()
		send("Multa")
	end)
	Theme.button({ Size = UDim2.fromOffset(136, 44), Text = "Prisión", TextSize = 17, BackgroundColor3 = rgb(160, 40, 50), Parent = row }).Activated:Connect(function()
		send("Prision")
	end)
	-- Minutos de prisión
	local stepper = create("Frame", { Position = UDim2.fromOffset(0, 270), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = panel })
	Theme.label({ Size = UDim2.fromOffset(180, 40), Text = "Minutos de prisión:", TextSize = 15, Parent = stepper })
	local value = Theme.title({ Position = UDim2.fromOffset(240, 0), Size = UDim2.fromOffset(60, 40), Text = "3", TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Parent = stepper })
	local function set(n: number)
		minutes = math.clamp(n, 1, case.MaxMinutes or 10)
		value.Text = tostring(minutes)
	end
	Theme.button({ Position = UDim2.fromOffset(190, 0), Size = UDim2.fromOffset(44, 40), Text = "−", TextSize = 22, Parent = stepper }).Activated:Connect(function()
		set(minutes - 1)
	end)
	Theme.button({ Position = UDim2.fromOffset(306, 0), Size = UDim2.fromOffset(44, 40), Text = "+", TextSize = 22, Parent = stepper }).Activated:Connect(function()
		set(minutes + 1)
	end)
	Theme.label({ Position = UDim2.fromOffset(0, 318), Size = UDim2.new(1, 0, 0, 30), Text = "La multa depende de las estrellas. Si no decides a tiempo, se aplica la sentencia automática.", TextSize = 12, TextWrapped = true, TextColor3 = C.Muted, Parent = panel })
	task.spawn(function()
		local left = case.Seconds or 90
		while casePanel == panel and left > 0 do
			timer.Text = ("Tiempo para dictar sentencia: %d s"):format(math.ceil(left))
			left -= task.wait(0.5)
		end
		if casePanel == panel then
			closeCase()
		end
	end)
end

---------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------
local function banner(title: string, subtitle: string, color: Color3)
	local frame = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(620, 110),
		BackgroundColor3 = rgb(8, 14, 34),
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { Theme.corner(14), create("UIStroke", { Color = color, Thickness = 2 }) })
	local scale = create("UIScale", { Scale = 0.6, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	Theme.title({ Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 46), Text = title, TextSize = 34, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
	Theme.label({ Position = UDim2.fromOffset(20, 62), Size = UDim2.new(1, -40, 0, 36), Text = subtitle, TextSize = 17, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
	task.delay(4, function()
		TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		task.wait(0.3)
		frame:Destroy()
	end)
end

local function onJustice(kind: string, data: any)
	if kind == "Case" then
		openCase(data)
	elseif kind == "CaseClosed" then
		closeCase()
	elseif kind == "Trial" then
		banner("⚖ JUICIO", ("Te juzga %s. Espera la sentencia en el banquillo."):format(data.Judge), rgb(240, 210, 120))
	elseif kind == "Sentence" then
		local text
		if data.Kind == "Absolver" then
			text = "Absuelto/a: quedas en libertad sin cargos."
		elseif data.Seconds > 0 then
			text = ("%s de multa y %d min de prisión."):format(Format.money(data.Fine), math.ceil(data.Seconds / 60))
		else
			text = ("Multa de %s."):format(Format.money(data.Fine))
		end
		local by = if data.Judge then " · Juez/a: " .. data.Judge else " (automática)"
		banner("SENTENCIA", text .. by, if data.Kind == "Absolver" then rgb(120, 220, 140) else rgb(255, 120, 100))
	elseif kind == "Released" then
		banner("🔓 EN LIBERTAD", data.How or "Has salido de prisión.", rgb(120, 220, 140))
	end
end

-- Cuenta atrás de la condena
local function paintJail()
	local untilTime = player:GetAttribute("JailUntil")
	jailBar.Visible = type(untilTime) == "number"
	if type(untilTime) == "number" then
		local left = math.max(0, untilTime - os.time())
		local tunnel = player:GetAttribute("Tunnel")
		local extra = if player:GetAttribute("Isolated") then " · 🔒 AISLAMIENTO" elseif tunnel then (" · 🕳 túnel %d%%"):format(tunnel) else ""
		jailText.Text = ("⛓ En prisión · %d:%02d%s · trabaja, estudia o haz deporte para salir antes"):format(left // 60, left % 60, extra)
	end
end

---------------------------------------------------------------------
-- Mi carrera (para el menú de comandos)
---------------------------------------------------------------------
function InstitutionsUI.showCareer()
	local lines = {}
	for _, id in { "Policia", "Justicia", "Prisiones", "Ejercito", "Hacienda" } do
		local inst = Institutions.List[id]
		local points = player:GetAttribute("Career_" .. id) or 0
		if points > 0 then
			local _, rank = Institutions.rankFor(inst, points)
			local toNext = Institutions.toNext(inst, points)
			table.insert(lines, ("%s %s: %s (%d pts%s)"):format(inst.Icon, inst.Short, rank.Name, points, if toNext then (", faltan %d"):format(toNext) else ", jefe/a"))
		end
	end
	if #lines == 0 then
		Hud.toast("Info", "🎖 Aún no has trabajado en ninguna institución. Busca los tablones en la Ciudad de la Justicia.")
	else
		for _, line in lines do
			Hud.toast("Info", line)
		end
	end
	local records = player:GetAttribute("Records") or 0
	if records > 0 then
		Hud.toast("Error", ("📁 Antecedentes penales: %d"):format(records))
	end
end

function InstitutionsUI.init()
	gui = create("ScreenGui", { Name = "InstitutionsGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.55, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	jailBar = create("Frame", {
		Name = "Jail",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(640, 34),
		BackgroundColor3 = rgb(40, 40, 44),
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = gui,
	}, { Theme.corner(8), create("UIStroke", { Color = rgb(170, 174, 180), Thickness = 1.5 }) })
	jailText = Theme.label({ Size = UDim2.fromScale(1, 1), Text = "", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Parent = jailBar })
	task.spawn(function()
		while gui.Parent do
			paintJail()
			task.wait(1)
		end
	end)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	justiceRemote = remotes:WaitForChild("Justice", 30) :: RemoteEvent?
	if justiceRemote then
		justiceRemote.OnClientEvent:Connect(onJustice)
	end
	local career = remotes:WaitForChild("Career", 30) :: RemoteEvent?
	if career then
		career.OnClientEvent:Connect(function(kind: string, data: any)
			if kind == "Promotion" then
				SoundFx.play("MenuOk", 1.5, 0.8)
				banner(("%s ¡ASCENSO!"):format(data.Icon), ("%s: ahora eres %s%s"):format(data.Institution, data.Rank, if data.Chief then " (jefe/a)" else ""), C.Gold)
			end
		end)
	end
	player:GetAttributeChangedSignal("TaxPending"):Connect(function()
		local pending = player:GetAttribute("TaxPending")
		if pending then
			Hud.toast("Info", ("🏛 Tienes pendiente tu declaración de la renta: %s"):format(Format.money(pending)))
		end
	end)
end

return InstitutionsUI
