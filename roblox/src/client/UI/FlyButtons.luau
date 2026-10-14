-- FlyButtons: los botones grandes del avión en pantalla (móvil), registrados en UI/TouchLayout con sus
-- huecos de volar (HudLayout.Fly). Los usa Controllers/Flying (y scripts/test-hud.luau, para comprobar
-- que volando nada se pisa en ninguna pantalla).
--
-- Como la nave del espacio (queja del dueño: «los controles del avión, la interfaz y todo, debe ser igual
-- que el de las naves espaciales»): redondos, con el mismo estilo y en los mismos sitios que los de
-- UI/ShipButtons:
--   Izquierda: la palanca analógica (UI/FlightStick, Controllers/Flying): tirar hacia ABAJO sube el morro
--              (como un avión de verdad; se cambia en ⚙️ y en la ranura PALANCA), a los lados alabea y
--              gira (timón automático; en tierra, la rueda de morro)
--   Derecha:   MOTOR + (el más grande, donde la nave tiene DISPARO; mantener; la barrita es el gas),
--              MOTOR − a su izquierda (donde MISIL) y FRENOS encima (donde el FRENO de la nave).
--   Abajo en el centro, en la barra de ranuras del HUD (UI/AirCombatHud, Variant = "Plane"): FLAPS,
--   TREN, CÁMARA, PALANCA y BAJARSE (se tocan; antes eran botones sueltos y el del tren desaparecía en
--   la avioneta).
-- En el ordenador y con mando no se ven: sus teclas salen en la tarjeta de teclas del HUD.

local FlyButtons = {}

export type Status = { Throttle: number, Gear: boolean, FixedGear: boolean, Flaps: number, Brake: boolean, Camera: string, CanExit: boolean }
export type Handlers = {
	Flying: () -> boolean, -- ¿a los mandos ahora mismo?
	Hold: (slot: string, down: boolean) -> (), -- "ThrottleUp", "ThrottleDown", "Brake"
	Toggle: ((what: string) -> ())?, -- (ya no hay botones de cambiar: van en las ranuras del HUD)
	Status: () -> Status,
}

local rgb = Color3.fromRGB
-- (los colores de los botones de la nave: el motor como el IMPULSO, los frenos como el FRENO)
local GAS = rgb(30, 120, 200)
local IDLE = rgb(40, 60, 90)
local BRAKE = rgb(90, 90, 110)

FlyButtons.Ids = { "MotorMas", "MotorMenos", "Frenos" }

function FlyButtons.register(TouchLayout: any, h: Handlers)
	local function flying(): boolean
		return h.Flying()
	end
	local function holder(slot: string): (boolean) -> ()
		return function(down: boolean)
			h.Hold(slot, down)
		end
	end
	local function throttle(): number?
		return h.Status().Throttle
	end
	TouchLayout.register({ Id = "MotorMas", Icon = "mas", Label = "MOTOR +", FlySlot = "MotorMas", Tint = GAS, Priority = 1, Key = "Shift", Pad = "RT", Visible = flying, Hold = holder("ThrottleUp"), Meter = throttle })
	TouchLayout.register({ Id = "MotorMenos", Icon = "menos", Label = "MOTOR −", FlySlot = "MotorMenos", Tint = IDLE, Priority = 1.1, Key = "Ctrl", Pad = "LT", Visible = flying, Hold = holder("ThrottleDown") })
	TouchLayout.register({
		Id = "Frenos",
		Icon = "frenar",
		Label = "FRENOS",
		FlySlot = "Frenos",
		Tint = BRAKE,
		Priority = 1.2,
		Key = "B",
		Pad = "X",
		Visible = flying,
		Hold = holder("Brake"),
		Active = function()
			return h.Status().Brake
		end,
	})
end

function FlyButtons.unregister(TouchLayout: any)
	for _, id in FlyButtons.Ids do
		TouchLayout.unregister(id)
	end
end

return FlyButtons
