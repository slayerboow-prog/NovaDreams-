-- ShipButtons: los mandos en pantalla (móvil) de la nave del combate aéreo, registrados en UI/TouchLayout
-- con sus huecos de volar (HudLayout.Fly: Fuego, Misil, Turbo, FrenoNave, SalirNave). Los usa
-- Controllers/AirCombatClient (y scripts/test-aircombat.luau comprueba tamaños y que nada se pise).
--
--   Izquierda: la palanca (UI/FlightStick). Derecha (Espacio AAA, como la referencia): DISPARO (el más
--              grande; mantener: cañones o láser, con ayuda a apuntar), MISIL (con un blanco fijado: la
--              barrita dice cuántos quedan), IMPULSO (mantener; la barrita es su medidor), FRENO (mantener:
--              frena y gira cerrado; más de 0,6 s = freno de emergencia), ESQUIVA (hacia donde lleves la
--              palanca; la barrita es su recarga) y Salir. Las habilidades (salto, hipervelocidad…) van en
--              la barra de 8 ranuras del HUD (UI/AirCombatHud), que también se toca.
-- En el ordenador y con mando no se ven: sus teclas salen en la lista de teclas.

local ShipButtons = {}

export type Status = { Missiles: number, MaxMissiles: number, Boost: number, BoostReady: boolean, Locked: boolean, Firing: boolean, Boosting: boolean, Braking: boolean, DodgeReady: number?, Flares: number?, MaxFlares: number?, Enemies: boolean? }
export type Handlers = {
	Active: () -> boolean, -- ¿a los mandos de la nave?
	Hold: (slot: string, down: boolean) -> (), -- "Fire", "Boost", "Brake"
	Press: (what: string) -> (), -- "Missile", "Exit", "Dodge"
	Status: () -> Status,
}

local rgb = Color3.fromRGB
local FIRE = rgb(200, 60, 50)
local MISSILE = rgb(200, 120, 30)
local BOOST = rgb(30, 120, 200)
local BRAKE = rgb(90, 90, 110)

ShipButtons.Ids = { "NaveFuego", "NaveMisil", "NaveTurbo", "NaveFreno", "NaveEsquiva", "NaveBengalas", "NaveObjetivo", "NaveSalir" }

function ShipButtons.register(TouchLayout: any, h: Handlers)
	local function active(): boolean
		return h.Active()
	end
	local function holder(slot: string): (boolean) -> ()
		return function(down: boolean)
			h.Hold(slot, down)
		end
	end
	TouchLayout.register({
		Id = "NaveFuego",
		Icon = "disparar",
		Label = "DISPARO",
		FlySlot = "Fuego",
		Tint = FIRE,
		Priority = 1,
		Key = "Clic",
		Pad = "RT",
		Visible = active,
		Hold = holder("Fire"),
		Active = function()
			return h.Status().Firing
		end,
	})
	TouchLayout.register({
		Id = "NaveMisil",
		Icon = "objetivo",
		Label = "MISIL",
		FlySlot = "Misil",
		Tint = MISSILE,
		Priority = 1.1,
		Key = "2",
		Pad = "RB",
		Visible = active,
		Callback = function()
			h.Press("Missile")
		end,
		Active = function()
			local st = h.Status()
			return if st.Locked and st.Missiles > 0 then true elseif st.Missiles <= 0 then "wait" else false
		end,
		Meter = function()
			local st = h.Status()
			return if st.MaxMissiles > 0 then st.Missiles / st.MaxMissiles else nil
		end,
		Badge = function()
			return tostring(h.Status().Missiles)
		end,
	})
	TouchLayout.register({
		Id = "NaveTurbo",
		Icon = "rayo",
		Label = "IMPULSO",
		FlySlot = "Turbo",
		Tint = BOOST,
		Priority = 1.2,
		Key = "Shift",
		Pad = "LB",
		Visible = active,
		Hold = holder("Boost"),
		Active = function()
			local st = h.Status()
			return if st.Boosting then true elseif not st.BoostReady then "wait" else false
		end,
		Meter = function()
			return h.Status().Boost
		end,
	})
	TouchLayout.register({
		Id = "NaveFreno",
		Icon = "frenar",
		Label = "FRENO",
		FlySlot = "FrenoNave",
		Tint = BRAKE,
		Priority = 1.3,
		Key = "Ctrl",
		Pad = "LT",
		Visible = active,
		Hold = holder("Brake"),
		Active = function()
			return h.Status().Braking
		end,
	})
	TouchLayout.register({
		Id = "NaveBengalas",
		Icon = "linterna",
		Label = "BENGALAS",
		FlySlot = "BengalasNave",
		Tint = rgb(200, 90, 40),
		Priority = 1.4,
		Key = "K",
		Pad = "←",
		Visible = active,
		Callback = function()
			h.Press("Flares")
		end,
		Active = function()
			local st = h.Status()
			return if (st.Flares or 0) <= 0 then "wait" else false
		end,
		Badge = function()
			return tostring(h.Status().Flares or 0)
		end,
	})
	TouchLayout.register({
		Id = "NaveObjetivo",
		Icon = "objetivo",
		Label = "OBJETIVO",
		FlySlot = "ObjetivoNave",
		Tint = rgb(150, 40, 50),
		Priority = 1.45,
		Key = "Tab",
		Pad = "→",
		Visible = function()
			return active() and h.Status().Enemies == true
		end,
		Callback = function()
			h.Press("TargetNext")
		end,
	})
	TouchLayout.register({
		Id = "NaveEsquiva",
		Icon = "esquivar",
		Label = "ESQUIVA",
		FlySlot = "EsquivaNave",
		Tint = rgb(40, 150, 170),
		Priority = 1.35,
		Key = "C",
		Pad = "A",
		Visible = active,
		Callback = function()
			h.Press("Dodge")
		end,
		Active = function()
			local r = h.Status().DodgeReady
			return if r and r < 1 then "wait" else false
		end,
		Meter = function()
			return h.Status().DodgeReady
		end,
	})
	TouchLayout.register({
		Id = "NaveSalir",
		Icon = "volver",
		Label = "Salir",
		FlySlot = "SalirNave",
		Priority = 2,
		Key = "B",
		Pad = "B",
		Visible = active,
		Callback = function()
			h.Press("Exit")
		end,
	})
end

function ShipButtons.unregister(TouchLayout: any)
	for _, id in ShipButtons.Ids do
		TouchLayout.unregister(id)
	end
end

return ShipButtons
