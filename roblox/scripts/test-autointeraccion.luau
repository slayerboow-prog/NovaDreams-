-- Prueba: nada se usa solo (docs/bugs/auto-interaccion-v121). FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-autointeraccion.luau
--
-- En el móvil, junto a la estación de Valmar Centro, el juego te subía solo al patinete, te bajaba
-- («Te has bajado») y otra vez arriba, en bucle; y lo mismo con puertas y casas. Aquí se comprueba, en
-- el código, que ninguna interacción pasa sin un toque de verdad:
--   * en el cliente solo hay dos sitios que disparan carteles (Prompts: el cartel, solo con teclado o
--     ratón; ContextDetector.trigger: el botón Interactuar, la burbuja y la tira) y el segundo avisa
--     antes al servidor (PromptIntent "Use")
--   * en el móvil el cartel flotante nunca se toca, los carteles no tienen tecla ni se pueden clicar
--     (el motor no puede dispararlos por su cuenta) y los botones solo cuentan un TOQUE (TouchLayout.isTap,
--     y lo mismo las filas de la tira): ni arrastrar para girar la cámara ni un dedo apoyado
--   * en el servidor, todos los carteles que suben a algo o llevan a algún sitio (vehículos, alquiler,
--     puertas y casas, ascensores, autobús, tren, metro, avión, barco, residencia, hotel, muebles)
--     preguntan a PromptIntent.allows antes de hacer nada
--   * la estación de alquiler no da otro vehículo justo después de bajarse (RentCooldown)
--   * ningún asiento sienta al rozarlo: los de los vehículos nacen con CanTouch = false y los del mapa
--     pasan por InteractService.guardSeat; nadie usa Touched para subir o meter a nadie en ningún sitio
--     ni hay ClickDetector en el mundo (un toque para mover la cámara lo dispararía)
-- (Lo que pasa de verdad al pulsar —subir, bajarse, la espera— lo prueban test-gameplay y test-hud.)

local fs = require("@lune/fs")
local process = require("@lune/process")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function read(path: string): string
	return fs.readFile(path)
end

local function scan(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scan(path, out)
		elseif string.sub(name, -5) == ".luau" then
			table.insert(out, path)
		end
	end
	return out
end

local function has(text: string, needle: string): boolean
	return string.find(text, needle, 1, true) ~= nil
end

-- Cada `.Triggered:Connect(function(player)` (o `who`) de este archivo pregunta a PromptIntent en
-- las primeras líneas de su manejador. Devuelve los que no (número de línea).
local function ungated(path: string, only: { string }?): { number }
	local lines = string.split(read(path), "\n")
	local missing = {}
	for i, line in lines do
		if string.find(line, "Triggered:Connect(function(player", 1, true) or string.find(line, "Triggered:Connect(function(who", 1, true) then
			local interesting = only == nil
			for _, word in only or {} do
				if has(line, word) then
					interesting = true
				end
			end
			if interesting then
				local found = false
				for j = i + 1, math.min(#lines, i + 3) do
					if has(lines[j], "PromptIntent.allows(") then
						found = true
					end
				end
				if not found then
					table.insert(missing, i)
				end
			end
		end
	end
	return missing
end

print("▶ Cliente: un solo camino para disparar carteles, y con un toque de verdad")
do
	local holders = {}
	for _, path in scan("src/client", {}) do
		if has(read(path), ":InputHoldBegin(") then
			table.insert(holders, (string.gsub(path, "^src/client/", "")))
		end
	end
	table.sort(holders)
	check(#holders == 2 and holders[1] == "Commands/ContextDetector.luau" and holders[2] == "Controllers/Prompts.luau",
		"solo ContextDetector y Prompts disparan carteles (" .. table.concat(holders, ", ") .. ")")
	local detector = read("src/client/Commands/ContextDetector.luau")
	local triggerAt = string.find(detector, "function ContextDetector.trigger", 1, true) or 0
	local body = string.sub(detector, triggerAt, (string.find(detector, "\nend\n", triggerAt, true) or #detector))
	local useAt = string.find(body, 'FireServer("Use", prompt)', 1, true)
	local holdAt = string.find(body, "prompt:InputHoldBegin()", 1, true)
	check(useAt ~= nil and holdAt ~= nil and useAt < holdAt, "ContextDetector.trigger avisa al servidor (PromptIntent «Use») ANTES de disparar")
	check(has(body, "MenuLogic.freshTouch(since, lastTouchBegan"), "…y en el móvil solo con un toque nuevo")
	check(has(detector, "instance.ClickablePrompt = false"), "en el móvil ningún cartel se activa tocándolo en el mundo (ClickablePrompt)")
	check(has(detector, "prompt.KeyboardKeyCode = Enum.KeyCode.Unknown") and has(detector, "prompt.GamepadKeyCode = Enum.KeyCode.Unknown") and has(detector, "or noKeys then Enum.KeyCode.Unknown"),
		"en el móvil (sin mando) los carteles no tienen tecla: el motor no los dispara por su cuenta")
	check(has(detector, 'remote:FireServer("Device", TOUCH_DEVICE)'), "el móvil dice al servidor que es solo táctil")
	local prompts = read("src/client/Controllers/Prompts.luau")
	check(has(prompts, "local infoOnly = TOUCH or inputType == Enum.ProximityPromptInputType.Touch"), "en el móvil el cartel flotante es solo informativo SIEMPRE (aunque Roblox diga otro tipo de entrada)")
	local touch = read("src/client/UI/TouchLayout.luau")
	check(has(touch, "function TouchLayout.isTap(") and has(touch, "TouchLayout.isTap(press.From, press.Input.Position, pressAt[button], now)"),
		"los botones que usan carteles (Interactuar, Acciones) solo cuentan un toque: ni arrastre ni dedo apoyado")
	local strip = read("src/client/Commands/ContextStrip.luau")
	check(has(strip, "moved > ContextStrip.TapSlop or os.clock() - current.At > ContextStrip.TapMax"), "las filas de la tira de acciones tampoco se usan arrastrando o con el dedo apoyado")
	local menu = read("src/client/Commands/CommandMenu.luau")
	check(has(menu, 'Id = "Interactuar"') and has(menu, "FreshPress = true"), "el botón Interactuar (el grande) y la burbuja piden un toque nuevo")
	local logic = read("src/client/Commands/MenuLogic.luau")
	check(has(logic, "MenuLogic.FreshMax = 1.5"), "un toque que empezó hace más de 1,5 s ya no usa nada (antes 4 s)")
end

print("▶ Servidor: todo lo que sube o lleva a algún sitio pregunta a PromptIntent")
do
	local S = "src/server/Services/"
	local intent = read(S .. "PromptIntent.luau")
	check(has(intent, "function PromptIntent.allows(") and has(intent, "intents[player] = nil"), "PromptIntent.allows existe y gasta el aviso (un toque, una vez)")
	check(has(read(S .. "VehicleService.luau"), "pcall(PromptIntent.init)"), "el remoto PromptIntent se crea al arrancar (VehicleService.init)")
	for _, entry in {
		{ "VehicleService.luau", nil, 7, "vehículos: alquiler, conducir, montar, coche aparcado, asientos y surtidor" },
		{ "InteriorService.luau", nil, 10, "puertas, casas, salidas y ascensores de los edificios" },
		{ "InteractService.luau", { "prompt.Triggered" }, 1, "muebles (sentarse, dormir, puertas de dentro…)" },
		{ "BusService.luau", { "prompt.Triggered" }, 3, "subir al autobús y conducirlo" },
		{ "RailService.luau", { "Subir al tren" }, 1, "subir al tren" },
		{ "MetroService.luau", { "p.Triggered", "ascensor", "Ascensor" }, 5, "subir al metro y ascensores del metro" },
		{ "FlightService.luau", { "prompt.Triggered" }, 2, "embarcar en el avión" },
		{ "AviationService.luau", { "fly.Triggered", "ride.Triggered" }, 2, "pilotar o subir a la avioneta" },
		{ "BoatService.luau", { "prompt.Triggered" }, 1, "barcos del puerto" },
		{ "ResidenceService.luau", { "prompt.Triggered", "up.Triggered" }, 2, "residencia: salir y subir al cuarto" },
		{ "HotelService.luau", { "Subir a tu habitación" }, 1, "ascensor del hotel" },
	} do
		local path = S .. entry[1]
		local text = read(path)
		local missing = ungated(path, entry[2])
		local _, count = string.gsub(text, "PromptIntent%.allows%(", "")
		check(#missing == 0 and count >= entry[3], ("%s (%s): %d carteles con PromptIntent%s"):format(entry[4], entry[1], count,
			if #missing > 0 then " · sin él en las líneas " .. table.concat(missing, ", ") else ""))
	end
	local vehicles = read(S .. "VehicleService.luau")
	local stationAt = string.find(vehicles, "local function setupStation", 1, true) or 0
	local station = string.sub(vehicles, stationAt, (string.find(vehicles, "\nfunction VehicleService.init", stationAt, true) or #vehicles))
	check(has(station, "PromptIntent.allows(player, prompt)") and has(station, "VehicleService.rentBlocked(player)"),
		"la estación de alquiler: solo con un toque de verdad y nunca justo después de bajarse")
	check(has(vehicles, "VehicleService.RentCooldown = 3"), "espera de la estación tras bajarse: 3 s")
	local boardAt = string.find(vehicles, "function VehicleService.board(", 1, true) or 0
	check(has(string.sub(vehicles, boardAt, boardAt + 1200), "if justExited(player) or justLeft(player, model) then"), "subir de pasajero: tampoco justo después de bajarse")
	check(has(vehicles, "or justExited(player) or justLeft(player, model) then"), "«Montar»/«Conducir»: tampoco justo después de bajarse")
end

print("▶ Asientos, Touched y ClickDetector")
do
	local rides = read("src/server/World/Kit/Rides.luau")
	check(has(rides, 'seat.CanTouch = false -- nadie se sube al tocarlo') and has(rides, "passenger.CanTouch = false"), "los asientos de los vehículos (conductor y pasajeros) nacen sin CanTouch")
	local interact = read("src/server/Services/InteractService.luau")
	check(has(interact, "function InteractService.guardSeat(") and has(interact, "part.CanTouch = false") and has(interact, 'if d:IsA("Seat") or d:IsA("VehicleSeat") then'),
		"cualquier otro asiento del mapa (o que se construya después) deja de sentar al rozarlo (guardSeat)")
	local touched, clicks = {}, {}
	for _, path in scan("src/server", scan("src/client", {})) do
		local text = read(path)
		for line in string.gmatch(text, "[^\n]+") do
			if string.find(line, "%.Touched:Connect") and not string.find(line, "^%s*%-%-") then
				table.insert(touched, path)
			end
			if string.find(line, 'Instance.new%("ClickDetector"%)') or string.find(line, 'ClassName = "ClickDetector"') then
				table.insert(clicks, path)
			end
		end
	end
	-- (el único Touched: los juguetes que se recogen al pisarlos —ToyService—; no sube ni mete a nadie en ningún sitio)
	check(#touched == 1 and string.find(touched[1], "ToyService", 1, true) ~= nil, "nadie usa Touched para subir, entrar o teletransportar (" .. table.concat(touched, ", ") .. ")")
	check(#clicks == 0, "no hay ClickDetector en el mundo (un toque para mover la cámara lo dispararía)")
end

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
