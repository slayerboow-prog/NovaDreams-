-- VehicleControls: los mandos del vehículo que no son el volante ni el acelerador (y cómo se ven).
--
--   * Flechas ◀ ▶ (móvil): girar mientras las mantienes; el volante entra suave y vuelve solo al centro
--     (el suavizado es Driving.smoothInputs: aquí solo se decide hacia dónde se pide girar)
--   * Pedales: ACELERAR y FRENO. El freno frena mientras vas hacia delante y, ya parado, si lo sigues
--     pisando, da marcha atrás (lo mismo que S / ↓ / gatillo izquierdo: una sola lógica para todos)
--   * Freno de mano: mantenido en marcha bloquea las ruedas de atrás (el coche derrapa en las curvas);
--     pulsado PARADO lo deja echado (P en el cuadro): se queda así al soltarlo y se quita solo al
--     acelerar o frenar (como el freno de mano eléctrico) o volviéndolo a pulsar
--   * Luces: apagadas / cortas (toque) / largas (mantener). De noche se sugiere encenderlas una vez
--   * Intermitentes: izquierdo, derecho y emergencia (los cuatro). Se apagan solos al acabar el giro
--     (cuando has girado de verdad hacia ese lado y el volante vuelve al centro)
--
-- Lo que se ve lo replica el servidor como atributos del vehículo (todos los ordenadores lo pintan con
-- Controllers/VehicleLights):
--   Lights (0 apagadas, 1 cortas, 2 largas) · Indicator ("", "L", "R", "H") · Braking · Reversing · Handbrake
-- Todo aquí es puro (sin Roblox): lo prueba scripts/test-ride.luau.

local VehicleControls = {}

-- Qué mandos tiene cada vehículo (lo demás no sale en pantalla ni responde a sus teclas)
VehicleControls.Features = {
	Coche = { Lights = true, Indicators = true, Handbrake = true },
	Patrulla = { Lights = true, Indicators = true, Handbrake = true },
	Camion = { Lights = true, Indicators = true, Handbrake = true },
	Bomberos = { Lights = true, Indicators = true, Handbrake = true },
	Autobus = { Lights = true, Indicators = true, Handbrake = true },
	Moto = { Lights = true, Indicators = true, Handbrake = true },
	Bici = { Lights = true, Indicators = false, Handbrake = false },
	Patinete = { Lights = true, Indicators = false, Handbrake = false },
	Monopatin = { Lights = false, Indicators = false, Handbrake = false },
	Lancha = { Lights = true, Indicators = false, Handbrake = false },
	Gaviota = { Lights = true, Indicators = false, Handbrake = false },
}
local NONE = { Lights = false, Indicators = false, Handbrake = false }

function VehicleControls.features(kind: string?): { Lights: boolean, Indicators: boolean, Handbrake: boolean }
	return (kind and VehicleControls.Features[kind]) or NONE
end

VehicleControls.BLINK_HZ = 1.5 -- intermitentes: 1,5 destellos por segundo
VehicleControls.PARK_SPEED = 1 -- por debajo de esto (studs/s) el freno de mano se queda echado
VehicleControls.CANCEL_TURN = math.rad(50) -- lo que hay que girar para que el intermitente se apague solo
VehicleControls.HIGH_BEAM_HOLD = 0.45 -- segundos manteniendo «Luces» para las largas

export type Controls = {
	Lights: number, -- 0, 1, 2
	Indicator: string, -- "", "L", "R" (el que se pidió)
	Hazard: boolean, -- emergencia (los cuatro)
	Turned: number, -- radianes girados hacia el lado del intermitente desde que se puso
	Parked: boolean, -- freno de mano echado (parado)
	HandDown: boolean, -- ¿se está pulsando el freno de mano? (para ver cuándo empieza)
}

function VehicleControls.new(): Controls
	return { Lights = 0, Indicator = "", Hazard = false, Turned = 0, Parked = false, HandDown = false }
end

---------------------------------------------------------------------
-- Volante y pedales
---------------------------------------------------------------------

-- Flechas en pantalla -> volante pedido (-1 izquierda .. 1 derecha). Las dos a la vez = recto.
function VehicleControls.arrowSteer(left: boolean, right: boolean): number
	return (if right then 1 else 0) - (if left then 1 else 0)
end

-- Pedales en pantalla -> acelerador pedido (-1 freno / marcha atrás .. 1)
function VehicleControls.pedalThrottle(gas: boolean, brake: boolean): number
	return (if gas then 1 else 0) - (if brake then 1 else 0)
end

-- Qué hace el pedal ahora mismo, para las luces y el cuadro: "Acelera", "Frena", "Atras" o "Nada"
function VehicleControls.pedalMeaning(throttle: number, speed: number): string
	if throttle > 0.02 then
		return if speed < -0.5 then "Frena" else "Acelera"
	elseif throttle < -0.02 then
		return if speed > 0.5 then "Frena" else "Atras"
	end
	return "Nada"
end

---------------------------------------------------------------------
-- Freno de mano
---------------------------------------------------------------------

-- Cada fotograma: down = se pulsa el freno de mano; speed = velocidad; throttle = pedal pedido.
-- Devuelve si el freno de mano actúa (pulsado o echado) y si se acaba de echar / quitar ("Echado",
-- "Quitado" o nil) para el sonido y el cuadro.
function VehicleControls.handbrakeStep(c: Controls, down: boolean, speed: number, throttle: number): (boolean, string?)
	local event: string? = nil
	local pressed = down and not c.HandDown
	c.HandDown = down
	if pressed then
		if c.Parked then
			c.Parked = false
			event = "Quitado"
		elseif math.abs(speed) < VehicleControls.PARK_SPEED then
			c.Parked = true
			event = "Echado"
		end
	elseif c.Parked and not down and math.abs(throttle) > 0.1 then
		-- Echado y pisas un pedal: se quita solo (y el coche sale)
		c.Parked = false
		event = "Quitado"
	end
	return down or c.Parked, event
end

---------------------------------------------------------------------
-- Luces
---------------------------------------------------------------------

-- Toque: apagadas <-> cortas (y de largas, a apagadas). Mantener: largas (o de largas a cortas).
function VehicleControls.nextLights(level: number, long: boolean): number
	if long then
		return if level == 2 then 1 else 2
	end
	return if level == 0 then 1 else 0
end

-- ¿Es de noche para las luces? (la misma hora que VehicleService: de 18:18 a 7:12)
function VehicleControls.isDark(clockTime: number): boolean
	return clockTime >= 18.3 or clockTime < 7.2
end

-- ¿Sugerir encender las luces? (de noche, apagadas y aún no se ha dicho en esta partida)
function VehicleControls.shouldHint(clockTime: number, lights: number, shown: boolean, kind: string?): boolean
	return not shown and lights == 0 and VehicleControls.isDark(clockTime) and VehicleControls.features(kind).Lights
end

---------------------------------------------------------------------
-- Intermitentes
---------------------------------------------------------------------

-- side = "L", "R" o "H" (emergencia). Pulsar el que ya está puesto lo quita; el otro lado lo cambia.
function VehicleControls.toggleIndicator(c: Controls, side: string)
	if side == "H" then
		c.Hazard = not c.Hazard
		return
	end
	if side ~= "L" and side ~= "R" then
		return
	end
	c.Indicator = if c.Indicator == side then "" else side
	c.Turned = 0
end

-- Cada fotograma: turnedRight = lo que ha girado el vehículo en este fotograma (radianes, + derecha);
-- steer = volante (-1..1). Si ha girado de verdad hacia el lado del intermitente y el volante vuelve al
-- centro, se apaga solo. Devuelve true cuando se apaga.
function VehicleControls.indicatorStep(c: Controls, turnedRight: number, steer: number): boolean
	if c.Indicator == "" then
		return false
	end
	local sign = if c.Indicator == "R" then 1 else -1
	local toward = turnedRight * sign
	if toward > 0 then
		c.Turned += toward
	end
	if c.Turned >= VehicleControls.CANCEL_TURN and math.abs(steer) < 0.2 then
		c.Indicator = ""
		c.Turned = 0
		return true
	end
	return false
end

-- Lo que se replica: "" / "L" / "R" / "H" (la emergencia manda sobre el intermitente)
function VehicleControls.indicatorShown(c: Controls): string
	return if c.Hazard then "H" else c.Indicator
end

-- ¿Luce el intermitente en este instante? (1,5 Hz: mitad encendido, mitad apagado)
function VehicleControls.blinkOn(t: number): boolean
	return (t * VehicleControls.BLINK_HZ) % 1 < 0.5
end

---------------------------------------------------------------------
-- Lo que se ve (cada ordenador lo pinta a partir de los atributos)
---------------------------------------------------------------------
export type Lamps = { Head: number, Tail: string, Reverse: boolean, Left: boolean, Right: boolean }

-- attrs: los atributos del vehículo; t = reloj (para el parpadeo).
-- Head: 0/1/2 · Tail: "Off" | "On" (posición) | "Brake" · Reverse · Left / Right (intermitentes ahora)
function VehicleControls.lamps(attrs: { [string]: any }, t: number): Lamps
	local lights = if type(attrs.Lights) == "number" then math.clamp(math.floor(attrs.Lights), 0, 2) else 0
	local braking = attrs.Braking == true
	local tail = if braking then "Brake" elseif lights > 0 then "On" else "Off"
	local indicator = if type(attrs.Indicator) == "string" then attrs.Indicator else ""
	local on = VehicleControls.blinkOn(t)
	return {
		Head = lights,
		Tail = tail,
		Reverse = attrs.Reversing == true,
		Left = on and (indicator == "L" or indicator == "H"),
		Right = on and (indicator == "R" or indicator == "H"),
	}
end

-- Lo que manda el conductor al servidor, limpio (nil si no vale): el servidor no se fía de nada más
function VehicleControls.sanitize(payload: any): { Lights: number, Indicator: string, Braking: boolean, Reversing: boolean, Handbrake: boolean }?
	if type(payload) ~= "table" then
		return nil
	end
	local lights = payload.Lights
	local indicator = payload.Indicator
	if type(lights) ~= "number" or lights ~= lights or type(indicator) ~= "string" then
		return nil
	end
	if indicator ~= "" and indicator ~= "L" and indicator ~= "R" and indicator ~= "H" then
		return nil
	end
	return {
		Lights = math.clamp(math.floor(lights), 0, 2),
		Indicator = indicator,
		Braking = payload.Braking == true,
		Reversing = payload.Reversing == true,
		Handbrake = payload.Handbrake == true,
	}
end

-- ¿Ha cambiado algo de lo que se ve? (solo entonces se manda)
function VehicleControls.same(a: { [string]: any }?, b: { [string]: any }?): boolean
	if a == nil or b == nil then
		return a == b
	end
	return a.Lights == b.Lights and a.Indicator == b.Indicator and a.Braking == b.Braking and a.Reversing == b.Reversing and a.Handbrake == b.Handbrake
end

VehicleControls.ATTRIBUTES = { "Lights", "Indicator", "Braking", "Reversing", "Handbrake" }

-- Pone el estado en los atributos del vehículo (el servidor; el conductor también, para verlo ya)
function VehicleControls.write(model: any, state: { [string]: any })
	for _, name in VehicleControls.ATTRIBUTES do
		if model:GetAttribute(name) ~= state[name] then
			model:SetAttribute(name, state[name])
		end
	end
end

-- Al subirse (todo apagado) y al aparcar (todo apagado, con el freno de mano echado)
-- (las luces de emergencia que estaban puestas siguen parpadeando al aparcar y al volver a subir)
function VehicleControls.reset(model: any, parked: boolean?)
	local keepHazard = model:GetAttribute("Indicator") == "H"
	VehicleControls.write(model, { Lights = 0, Indicator = if keepHazard then "H" else "", Braking = false, Reversing = false, Handbrake = parked == true })
end

return VehicleControls
