-- FlyButtons: los mandos del avión en pantalla (móvil), registrados en UI/TouchLayout con sus huecos de
-- volar (HudLayout.Fly). Los usa Controllers/Flying (y scripts/test-hud.luau, para comprobar que
-- volando nada se pisa en ninguna pantalla).
--
--   Izquierda: la palanca analógica (UI/FlightStick, Controllers/Flying): arriba sube el morro, abajo
--              lo baja, a los lados alabea y gira (timón automático; en tierra, la rueda de morro)
--   Derecha:   MOTOR + (alto, con la barrita del gas) y MOTOR − en la esquina; FRENOS a su izquierda;
--              encima el tren (solo el avión de línea) y Bajarse (parado en tierra); y los flaps y la
--              cámara (persecución / cabina). Ya no hay botones de timón (los hace la palanca).
-- En el ordenador no se ven: las teclas salen en la lista de teclas y en el panel de instrumentos.

local FlyButtons = {}

export type Status = { Throttle: number, Gear: boolean, FixedGear: boolean, Flaps: number, Brake: boolean, Camera: string, CanExit: boolean }
export type Handlers = {
	Flying: () -> boolean, -- ¿a los mandos ahora mismo?
	Hold: (slot: string, down: boolean) -> (), -- "ThrottleUp", "ThrottleDown", "Brake"
	Toggle: (what: string) -> (), -- "Gear", "Flaps", "Camera", "Exit"
	Status: () -> Status,
}

local rgb = Color3.fromRGB
local GAS = rgb(0, 150, 80)
local IDLE = rgb(30, 70, 150)
local BRAKE = rgb(190, 50, 45)

FlyButtons.Ids = { "MotorMas", "MotorMenos", "Frenos", "Tren", "Flaps", "CamaraAvion", "BajarseAvion" }

function FlyButtons.register(TouchLayout: any, h: Handlers)
	local function flying(): boolean
		return h.Flying()
	end
	local function holder(slot: string): (boolean) -> ()
		return function(down: boolean)
			h.Hold(slot, down)
		end
	end
	local function toggler(what: string): () -> ()
		return function()
			h.Toggle(what)
		end
	end
	local function throttle(): number?
		return h.Status().Throttle
	end
	TouchLayout.register({ Id = "MotorMas", Icon = "mas", Label = "MOTOR +", FlySlot = "MotorMas", Shape = "Pedal", Tint = GAS, Priority = 1, Key = "Shift", Pad = "RT", Visible = flying, Hold = holder("ThrottleUp"), Meter = throttle })
	TouchLayout.register({ Id = "MotorMenos", Icon = "menos", Label = "MOTOR −", FlySlot = "MotorMenos", Shape = "Pedal", Tint = IDLE, Priority = 1, Key = "Ctrl", Pad = "LT", Visible = flying, Hold = holder("ThrottleDown") })
	TouchLayout.register({
		Id = "Frenos",
		Icon = "frenar",
		Label = "FRENOS",
		FlySlot = "Frenos",
		Shape = "Pedal",
		Tint = BRAKE,
		Priority = 2,
		Key = "B",
		Pad = "X",
		Visible = flying,
		Hold = holder("Brake"),
		Active = function()
			return h.Status().Brake
		end,
	})
	TouchLayout.register({
		Id = "Tren",
		Icon = "tren",
		Label = "Tren",
		FlySlot = "Tren",
		Priority = 3,
		Key = "G",
		Pad = "Y",
		Visible = function()
			return flying() and not h.Status().FixedGear
		end,
		Callback = toggler("Gear"),
		Active = function()
			return h.Status().Gear
		end,
		Badge = function()
			return if h.Status().Gear then "Abajo" else "Arriba"
		end,
	})
	TouchLayout.register({
		Id = "Flaps",
		Icon = "flaps",
		Label = "Flaps",
		FlySlot = "Flaps",
		Priority = 3.1,
		Key = "F",
		Pad = "DPadDown",
		Visible = flying,
		Callback = toggler("Flaps"),
		Active = function()
			return h.Status().Flaps > 0
		end,
		Badge = function()
			return tostring(h.Status().Flaps)
		end,
	})
	TouchLayout.register({
		Id = "CamaraAvion",
		Icon = "camara",
		Label = "Cámara",
		FlySlot = "Camara",
		Priority = 3.2,
		Key = "C",
		Pad = "R3",
		Visible = flying,
		Callback = toggler("Camera"),
		Badge = function()
			return if h.Status().Camera == "Cabina" then "Cabina" else nil
		end,
	})
	TouchLayout.register({
		Id = "BajarseAvion",
		Icon = "bajarse",
		Label = "Bajarse",
		FlySlot = "Bajarse",
		Priority = 3.3,
		Key = "Espacio",
		Pad = "A",
		Visible = function()
			return flying() and h.Status().CanExit
		end,
		Callback = toggler("Exit"),
	})
end

function FlyButtons.unregister(TouchLayout: any)
	for _, id in FlyButtons.Ids do
		TouchLayout.unregister(id)
	end
end

return FlyButtons
