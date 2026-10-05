-- TesterPanel: panel «Modo pruebas» (solo para el dueño del juego y los testers de Config.Testers).
--
--   TesterPanel.toggle()  abre o cierra el panel (lo puede llamar un botón del menú)
--   TesterPanel.open() / TesterPanel.close() / TesterPanel.isTester()
--   Chat: /pruebas (lo atiende el servidor, TesterService, y le manda abrir el panel)
--
-- El cliente solo pide; quién es tester y lo que se hace lo decide SIEMPRE el servidor. A un jugador
-- normal el panel no se le abre (no tiene el atributo Tester y el servidor no le contesta).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Dialog = require(script.Parent.Dialog)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local TesterPanel = {}

local player = Players.LocalPlayer
local NAME = "TesterPanel"
local ON = Color3.fromRGB(0, 150, 90)

local remote: RemoteEvent? = nil
local window: Frame? = nil
local state: { [string]: any }? = nil
local refreshers: { () -> () } = {}

local STAGE_NAMES = {
	Nino = "🧒 Niño",
	Adolescente = "🧑 Adolescente",
	AdultoJoven = "🎓 Universidad",
	Adulto = "💼 Adulto",
	Mayor = "👴 Mayor",
}

function TesterPanel.isTester(): boolean
	return player:GetAttribute("Tester") == true
end

local function send(kind: string, a: any?, b: any?)
	if remote then
		remote:FireServer(kind, a, b)
	end
end

function TesterPanel.close()
	if window and window.Parent then
		window:Destroy()
	end
	window = nil
	table.clear(refreshers)
end

function TesterPanel.isOpen(): boolean
	return window ~= nil and window.Parent ~= nil
end

-- Filo cian que brilla (como los paneles del HUD) sobre la ventana de Dialog
local function glow(frame: Frame)
	frame.BackgroundColor3 = H.Navy
	frame.BackgroundTransparency = 0.18
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = H.Glow
		stroke.Thickness = 2
		stroke.Transparency = 0.05
	end
	Theme.halo(frame, H.Glow, 8, 10)
end

local function build()
	local frame, content = Dialog.window(NAME, "🧪 Modo pruebas", Vector2.new(500, 600))
	window = frame
	table.clear(refreshers)
	glow(frame)
	frame.Destroying:Connect(function()
		if window == frame then
			window = nil
			table.clear(refreshers)
		end
	end)

	local list = create("ScrollingFrame", {
		Name = "List",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = if Theme.isTouch() then 8 else 5,
		ScrollBarImageColor3 = H.Glow,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = list })

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function section(text: string): TextLabel
		return Theme.label({
			Size = UDim2.new(1, 0, 0, 26),
			Text = text,
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = H.Glow,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
	end
	local function note(text: string)
		Theme.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = text,
			TextSize = 13,
			TextColor3 = C.Muted,
			TextWrapped = true,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
	end
	local function button(parent: Instance, text: string, onClick: () -> (), layoutOrder: number?): TextButton
		local b = Theme.button({
			Size = UDim2.new(1, 0, 0, 46),
			Text = text,
			TextSize = 16,
			TextWrapped = true,
			BackgroundColor3 = H.NavyLight,
			LayoutOrder = layoutOrder or nextOrder(),
			Parent = parent,
		})
		Theme.touchText(b, 16)
		b.Activated:Connect(onClick)
		return b
	end
	-- Rejilla de botones de dos columnas (táctil: botones grandes)
	local function grid(): Frame
		local g = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
		create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 46),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = g,
		})
		return g
	end
	local function toggle(key: string, label: string)
		local b = button(list, "", function()
			send("Toggle", key)
		end)
		local function refresh()
			local on = state ~= nil and state[key] == true
			b.Text = ("%s: %s"):format(label, if on then "SÍ" else "NO")
			b.BackgroundColor3 = if on then ON else H.NavyLight
		end
		refresh()
		table.insert(refreshers, refresh)
	end

	-- Arriba del todo, un toque: adulto con todos los carnets y sin búsqueda (el servidor corta la
	-- conversación o la misión de niño que hubiera a medias; TesterService "MakeAdult")
	local adult = button(list, "🧑 Hazme adulto (carnets y sin policía)", function()
		send("Action", "MakeAdult")
	end)
	adult.BackgroundColor3 = ON
	local function refreshAdult()
		local now = state and state.Stage
		adult.Text = if now == "Adulto" then "🧑 Ya eres adulto · pulsa para carnets y quitar la policía" else "🧑 Hazme adulto (carnets y sin policía)"
	end
	refreshAdult()
	table.insert(refreshers, refreshAdult)

	section("INTERRUPTORES")
	toggle("Money", "💰 Dinero infinito")
	toggle("Bypass", "🔓 Sin requisitos (oficios, carnets, edad)")
	note("Con el dinero infinito, al apagarlo vuelves a tener el dinero de antes.")

	section("DESBLOQUEAR")
	button(list, "🔓 Desbloquear todo", function()
		send("Action", "UnlockAll")
	end)
	local unlock = grid()
	for i, item in {
		{ "Weapons", "🔫 Todas las armas" },
		{ "Licences", "🪪 Todos los carnets" },
		{ "Vehicles", "🚗 Todos los vehículos" },
		{ "MaxLevel", "⭐ Nivel máximo" },
	} do
		button(unlock, item[2], function()
			send("Action", item[1])
		end, i)
	end

	section("PERSONAJE")
	local body = grid()
	button(body, "❤ Rellenar energía, hambre y salud", function()
		send("Action", "Refill")
	end, 1)
	button(body, "🚔 Quitar búsqueda policial", function()
		send("Action", "ClearWanted")
	end, 2)

	-- Pelea (CombatService / FighterService): un rival con IA y los poderes de la Grieta a mano
	section("COMBATE")
	local fight = grid()
	for i, item in {
		{ "Facil", "🥊 Rival fácil" },
		{ "Normal", "🥊 Rival normal" },
		{ "Dificil", "🥊 Rival difícil" },
	} do
		button(fight, item[2], function()
			send("Action", "Rival", item[1])
			TesterPanel.close()
		end, i)
	end
	button(fight, "⚡ Energía y aguante llenos", function()
		send("Action", "Energy")
	end, 4)
	note("Con «Sin requisitos» tienes todos los poderes de la Grieta (sin jugar la saga). Al rival no te persigue la policía.")

	local stageTitle = section("CAMBIAR ETAPA DE VIDA")
	local function refreshStage()
		local current = state and state.Stage
		stageTitle.Text = "CAMBIAR ETAPA DE VIDA · ahora: " .. (STAGE_NAMES[current or ""] or tostring(current or "-"))
	end
	refreshStage()
	table.insert(refreshers, refreshStage)
	local stages = grid()
	for i, stage in (state and state.Stages) or {} do
		button(stages, STAGE_NAMES[stage] or stage, function()
			send("Action", "Stage", stage)
		end, i)
	end
	note("Cambia la edad, el cuerpo y el capítulo de tu historia (se guarda). Corta la conversación en marcha y deja las misiones de la etapa anterior.")

	section("TELETRANSPORTE")
	local places = grid()
	for i, place in (state and state.Places) or {} do
		button(places, tostring(place.Name), function()
			send("Action", "Teleport", place.Id)
		end, i)
	end

	section("HORA DEL DÍA")
	local hours = grid()
	for i, hour in (state and state.Hours) or {} do
		button(hours, ("🕒 %d:00"):format(hour), function()
			send("Action", "Hour", hour)
		end, i)
	end
	note("La hora cambia para todo el servidor.")

	-- La Grieta del cielo (Controllers/SkyRift): ver cada una de sus 7 etapas al momento (solo tú)
	section("GRIETA DEL CIELO")
	local rift = grid()
	local riftControl = function(): any
		return require(script.Parent.Parent.Controllers.SkyRift :: any)
	end
	button(rift, "🌌 La de mi historia", function()
		riftControl().preview(nil)
	end, 1).Name = "GrietaHistoria"
	for i, label in {
		"1 · Cielo normal",
		"2 · Primera anomalía",
		"3 · La grieta crece",
		"4 · Gran fractura",
		"5 · Portal (abierta del todo)",
		"6 · Grieta colosal",
		"7 · Evento final",
	} do
		button(rift, label, function()
			riftControl().previewStage(i)
		end, i + 1).Name = "GrietaEtapa" .. i
	end
	note("Cada etapa sale al instante, ya abierta del todo (la 5 es la de la imagen de referencia; la 7 tiñe de violeta toda la ciudad). Mírala hacia el norte, un poco hacia arriba. «La de mi historia» vuelve a la de tu partida.")

	-- Vehículos premium del pase: sacar cada uno a tu lado y dártelos todos (TesterService)
	local passVehicles = (state and state.PassVehicles) or {}
	if #passVehicles > 0 then
		section("🏎️ Vehículos del pase")
		local giveAll = button(list, "🎁 Darme todos (salen en «Mis vehículos»)", function()
			send("Action", "PassVehiclesAll")
		end)
		giveAll.Name = "PassVehiclesAll"
		local cars = grid()
		for i, entry in passVehicles do
			local b = button(cars, ("Sacar %s %s"):format(tostring(entry.Icon or "🏎️"), tostring(entry.Name)), function()
				send("Action", "PassVehicle", entry.Id)
				TesterPanel.close()
			end, i)
			b.Name = "PassVehicle_" .. tostring(entry.Id)
		end
		note("«Sacar» lo pone a tu lado aunque no lo tengas (mejor en la calle). «Darme todos» te los da de verdad: en «Mis vehículos» eliges cuál sale al montar el coche o la moto.")
	end

	-- Pase de temporada (solo si está encendido: el servidor manda state.BattlePass)
	if state and type(state.BattlePass) == "table" then
		local bpTitle = section("PASE DE TEMPORADA")
		local function bp(op: string, value: number?)
			send("Action", "BattlePass", { Op = op, Value = value })
		end
		local function refreshBattlePass()
			local info = state and state.BattlePass
			if type(info) == "table" then
				local shift = tonumber(info.ClockShift) or 0
				bpTitle.Text = ("PASE DE TEMPORADA · nivel %s%s%s"):format(tostring(info.Level or "-"), if info.RealPremium then " · premium comprado" elseif info.SimulatedPremium then " · premium simulado" else "", if math.abs(shift) >= 3600 then (" · reloj +%d h"):format(math.floor(shift / 3600)) else "")
			end
		end
		refreshBattlePass()
		table.insert(refreshers, refreshBattlePass)
		local premiumButton = button(list, "", function()
			bp("Premium")
		end)
		local function refreshPremium()
			local on = state ~= nil and type(state.BattlePass) == "table" and state.BattlePass.SimulatedPremium == true
			premiumButton.Text = ("⭐ Premium simulado: %s"):format(if on then "SÍ" else "NO")
			premiumButton.BackgroundColor3 = if on then ON else H.NavyLight
		end
		refreshPremium()
		table.insert(refreshers, refreshPremium)
		local xp = grid()
		for i, item in {
			{ "AddXp", 1000, "🎟 +1.000 XP" },
			{ "AddXp", 10000, "🎟 +10.000 XP" },
			{ "SetLevel", 1, "Nivel 1" },
			{ "SetLevel", 10, "Nivel 10" },
			{ "SetLevel", 30, "Nivel 30" },
			{ "SetLevel", 49, "Nivel 49" },
			{ "SetLevel", 50, "Nivel 50" },
		} do
			button(xp, item[3], function()
				bp(item[1], item[2])
			end, i)
		end
		local clock = grid()
		for i, item in {
			{ "NextDay", "🕒 Día siguiente" },
			{ "NextWeek", "🗓 Semana siguiente" },
			{ "ResetClock", "🕒 Reloj normal" },
			{ "Reset", "♻ Reiniciar el pase" },
		} do
			button(clock, item[2], function()
				bp(item[1])
			end, i)
		end
		button(list, "🏆 Abrir el pase de temporada", function()
			local ok, err = pcall(function()
				require(script.Parent.BattlePassUI :: any).open()
			end)
			if not ok then
				warn("[TesterPanel] " .. tostring(err))
			end
		end)
		note("El premium simulado solo vive en esta sesión: no cuenta como compra y lo reclamado con él queda marcado. El reloj adelantado es solo tuyo (misiones diarias y semanales, fin de temporada).")
	end
end

local function refreshAll()
	for _, refresh in refreshers do
		local ok, err = pcall(refresh)
		if not ok then
			warn("[TesterPanel] " .. tostring(err))
		end
	end
end

-- Pide abrir el panel: el servidor comprueba que eres tester y contesta con el estado ("Open")
function TesterPanel.open()
	if not TesterPanel.isTester() then
		return
	end
	send("Open")
end

function TesterPanel.toggle()
	if TesterPanel.isOpen() then
		TesterPanel.close()
	else
		TesterPanel.open()
	end
end

function TesterPanel.init()
	Dialog.registerBig(NAME, TesterPanel.close, TesterPanel.isOpen)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 60)
		local found = remotes and remotes:WaitForChild("Tester", 60)
		if not found or not found:IsA("RemoteEvent") then
			return
		end
		remote = found
		found.OnClientEvent:Connect(function(kind: string, payload: any)
			if type(payload) ~= "table" then
				return
			end
			if kind == "Open" then
				state = payload
							build()
			elseif kind == "State" then
				state = payload
				if TesterPanel.isOpen() then
					refreshAll()
				end
			end
		end)
	end)
	-- Si deja de ser tester (no debería pasar), se cierra
	player:GetAttributeChangedSignal("Tester"):Connect(function()
		if not TesterPanel.isTester() then
			TesterPanel.close()
		end
	end)
end

return TesterPanel
