-- ShipKeys: las teclas de la nave en UNA tabla (ordenador y mando), para poder reasignarlas en el
-- futuro sin tocar el controlador (Controllers/AirCombatClient) y para las pistas del HUD
-- (UI/AirCombatHud). Cuentas puras (scripts/test-espacio-aaa.luau comprueba que no hay dos acciones con
-- la misma tecla).
--
-- Mientras escribes en el chat o en un cuadro de texto la nave NO coge ninguna tecla (lo mira
-- AirCombatClient con UserInputService:GetFocusedTextBox()).
--
-- Cambios respecto a antes del Espacio AAA (docs/espacio-aaa/diseno.md): Espacio ya no dispara (sube),
-- F ya no lanza misiles (interactúa: atracar / viajar), X ya no sale (salto cuántico; salir es B) y, a los
-- mandos, 1-8 son las ranuras de la nave (no equipan la barra rápida, que está escondida).

local ShipKeys = {}

-- Acción -> { Keys = { nombres de Enum.KeyCode / Enum.UserInputType del teclado y el ratón }, Pad = { … } }
ShipKeys.Bindings = {
	ThrottleUp = { Keys = { "W" }, Pad = { "DPadUp" }, Label = "Acelerar" },
	ThrottleDown = { Keys = { "S" }, Pad = { "DPadDown" }, Label = "Decelerar" },
	StrafeLeft = { Keys = { "A" }, Pad = {}, Label = "Lateral izquierda" },
	StrafeRight = { Keys = { "D" }, Pad = {}, Label = "Lateral derecha" },
	Up = { Keys = { "Space" }, Pad = {}, Label = "Subir" },
	Down = { Keys = { "LeftAlt" }, Pad = {}, Label = "Bajar" },
	PitchUp = { Keys = { "Up" }, Pad = {}, Label = "Morro arriba" },
	PitchDown = { Keys = { "Down" }, Pad = {}, Label = "Morro abajo" },
	YawLeft = { Keys = { "Left" }, Pad = {}, Label = "Girar izquierda" },
	YawRight = { Keys = { "Right" }, Pad = {}, Label = "Girar derecha" },
	RollLeft = { Keys = { "Q" }, Pad = {}, Label = "Giro izquierda" },
	RollRight = { Keys = { "E" }, Pad = {}, Label = "Giro derecha" },
	Fire = { Keys = { "MouseButton1" }, Pad = { "ButtonR2" }, Label = "Disparar" },
	Precision = { Keys = { "MouseButton2" }, Pad = {}, Label = "Precisión" },
	Missile = { Keys = { "Two", "MouseButton3" }, Pad = { "ButtonR1" }, Label = "Misil" },
	Boost = { Keys = { "LeftShift", "RightShift" }, Pad = { "ButtonL1" }, Label = "Impulso" },
	Brake = { Keys = { "LeftControl", "RightControl" }, Pad = { "ButtonL2" }, Label = "Freno (doble: emergencia)" },
	Dodge = { Keys = { "C" }, Pad = { "ButtonA" }, Label = "Esquiva" },
	Quantum = { Keys = { "X", "Six" }, Pad = { "ButtonSelect" }, Label = "Salto cuántico" },
	Hyper = { Keys = { "Seven" }, Pad = { "ButtonR3" }, Label = "Hipervelocidad" },
	Cloak = { Keys = { "Z", "Five" }, Pad = {}, Label = "Camuflaje" },
	Shield = { Keys = { "Four" }, Pad = {}, Label = "Escudo especial" },
	Drone = { Keys = { "Eight" }, Pad = {}, Label = "Dron" },
	Reload = { Keys = { "R" }, Pad = {}, Label = "Recargar" },
	Cannons = { Keys = { "One" }, Pad = {}, Label = "Cañones" },
	Laser = { Keys = { "Three" }, Pad = {}, Label = "Láser" },
	Mode = { Keys = { "T" }, Pad = {}, Label = "Modo combate / crucero / exploración" },
	-- (segunda tanda) bengalas y cambiar de objetivo
	Flares = { Keys = { "K" }, Pad = { "DPadLeft" }, Label = "Bengalas" },
	TargetNext = { Keys = { "Tab" }, Pad = { "DPadRight" }, Label = "Cambiar de objetivo" },
	Assist = { Keys = { "Y" }, Pad = {}, Label = "Asistencia de vuelo" },
	Interact = { Keys = { "F", "G" }, Pad = { "ButtonX" }, Label = "Interactuar" },
	Home = { Keys = { "V" }, Pad = { "ButtonY" }, Label = "Volver a Valmar" },
	Exit = { Keys = { "B" }, Pad = { "ButtonB" }, Label = "Bajarse / aterrizar" },
	Visor = { Keys = { "I" }, Pad = { "ButtonL3" }, Label = "Visor (planeta)" },
}

-- Acciones que se leen cada fotograma (mantener) y las que se disparan al pulsar
ShipKeys.Held = { "ThrottleUp", "ThrottleDown", "StrafeLeft", "StrafeRight", "Up", "Down", "PitchUp", "PitchDown", "YawLeft", "YawRight", "RollLeft", "RollRight", "Boost", "Brake" }
-- (las de otros controladores: atracar/viajar y Valmar en Controllers/SpaceClient, el visor en PlanetClient)
ShipKeys.Elsewhere = { Interact = true, Home = true, Visor = true }

-- Texto corto de una tecla para el HUD
local SHORT = {
	LeftShift = "Shift", RightShift = "Shift", LeftControl = "Ctrl", RightControl = "Ctrl", LeftAlt = "Alt",
	Space = "Espacio", MouseButton1 = "Clic", MouseButton2 = "Clic der.", MouseButton3 = "Rueda",
	Tab = "Tab", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8",
	Up = "↑", Down = "↓", Left = "←", Right = "→",
	ButtonR2 = "RT", ButtonL2 = "LT", ButtonR1 = "RB", ButtonL1 = "LB", ButtonA = "A", ButtonB = "B", ButtonX = "X",
	ButtonY = "Y", ButtonSelect = "Select", ButtonR3 = "R3", ButtonL3 = "L3", DPadUp = "↑", DPadDown = "↓",
	DPadLeft = "←", DPadRight = "→",
}

function ShipKeys.short(name: string): string
	return SHORT[name] or name
end

-- La tecla (o botón del mando) que se enseña para una acción: device = "Keyboard" | "Gamepad"
function ShipKeys.label(action: string, device: string?): string
	local b = ShipKeys.Bindings[action]
	if not b then
		return ""
	end
	local list = if device == "Gamepad" then b.Pad else b.Keys
	local first = list[1]
	return if first then ShipKeys.short(first) else ""
end

-- ¿Qué acción es esta tecla? (nombre de KeyCode o de UserInputType) -> acción o nil
function ShipKeys.actionFor(name: string): string?
	for action, b in ShipKeys.Bindings do
		if table.find(b.Keys, name) or table.find(b.Pad, name) then
			return action
		end
	end
	return nil
end

-- Reasignar (en el futuro, desde los ajustes). Devuelve false si la tecla ya es de otra acción.
function ShipKeys.remap(action: string, keys: { string }, pad: { string }?): boolean
	local b = ShipKeys.Bindings[action]
	if not b then
		return false
	end
	for _, k in keys do
		local other = ShipKeys.actionFor(k)
		if other and other ~= action then
			return false
		end
	end
	b.Keys = table.clone(keys)
	if pad then
		b.Pad = table.clone(pad)
	end
	return true
end

-- Teclas repetidas en dos acciones (debe estar vacía)
function ShipKeys.conflicts(): { string }
	local seen: { [string]: string } = {}
	local out = {}
	for action, b in ShipKeys.Bindings do
		for _, list in { b.Keys, b.Pad } do
			for _, k in list do
				if seen[k] and seen[k] ~= action then
					table.insert(out, ("%s: %s y %s"):format(k, seen[k], action))
				end
				seen[k] = action
			end
		end
	end
	return out
end

-- Todos los KeyCode (teclado y mando) que la nave se queda mientras pilotas (sin el ratón ni los de
-- otros controladores)
function ShipKeys.keyCodes(): { string }
	local out = {}
	for action, b in ShipKeys.Bindings do
		if ShipKeys.Elsewhere[action] then
			continue
		end
		for _, list in { b.Keys, b.Pad } do
			for _, k in list do
				if string.sub(k, 1, 5) ~= "Mouse" and not table.find(out, k) then
					table.insert(out, k)
				end
			end
		end
	end
	table.sort(out)
	return out
end

-- Pistas para el ordenador (zona G del HUD): { { Key, Text } }
ShipKeys.HintOrder = { "ThrottleUp", "StrafeLeft", "Up", "RollLeft", "Fire", "Missile", "Boost", "Brake", "Dodge", "Flares", "TargetNext", "Hyper", "Quantum", "Cloak", "Mode", "Exit" }
function ShipKeys.hints(device: string?): { { Key: string, Text: string } }
	local out = {}
	for _, action in ShipKeys.HintOrder do
		local key = ShipKeys.label(action, device)
		if action == "ThrottleUp" and device ~= "Gamepad" then
			key = "W/S"
		elseif action == "StrafeLeft" then
			key = if device == "Gamepad" then "RS" else "A/D"
		elseif action == "Up" then
			key = if device == "Gamepad" then "RS ↕" else "Espacio/Alt"
		elseif action == "RollLeft" then
			key = if device == "Gamepad" then "" else "Q/E"
		end
		if key ~= "" then
			local b = ShipKeys.Bindings[action]
			local text = b.Label
			if action == "ThrottleUp" then
				text = "Motor"
			elseif action == "StrafeLeft" then
				text = "Lateral"
			elseif action == "Up" then
				text = "Subir / bajar"
			elseif action == "RollLeft" then
				text = "Alabeo"
			end
			table.insert(out, { Key = key, Text = text })
		end
	end
	return out
end

return ShipKeys
