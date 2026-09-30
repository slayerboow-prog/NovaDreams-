-- DriveButtons: los mandos del vehículo en pantalla (móvil), registrados en UI/TouchLayout con sus
-- huecos de conducir (HudLayout.Drive / DriveLeft). Los usa Controllers/Driving (y scripts/test-hud.luau
-- para comprobar que al volante nada se pisa en ninguna pantalla).
--
--   Izquierda: ◀ ▶ girar (mantener; el volante entra suave y vuelve solo al centro al soltar)
--   Derecha:   ACELERAR (alto) y FRENO (frena y, ya parado, marcha atrás: sale una «R» en el botón)
--              Freno de mano (mantener en marcha = derrapar; tocar parado = echado, «P»)
--              Luces (tocar = cortas / apagar; mantener = largas)
--              Intermitentes ⬅ ➡ y emergencia ⚠ (se encienden en azul; la emergencia en ámbar)
-- En el ordenador no se ven (las teclas salen en la lista de teclas: Espacio, L, Q, E, X).

local VehicleControls = require(game:GetService("ReplicatedStorage").Shared.VehicleControls)

local DriveButtons = {}

export type Status = { Lights: number, Indicator: string, Hazard: boolean, Parked: boolean, Reversing: boolean }
export type Handlers = {
	Driving: () -> boolean, -- ¿al volante ahora mismo?
	Kind: () -> string?, -- qué vehículo (para saber qué mandos tiene)
	Hold: (slot: string, down: boolean) -> (), -- "Gas", "Brake", "Left", "Right", "Handbrake"
	Lights: (long: boolean) -> (), -- toque (false) o mantener (true)
	Indicator: (side: string) -> (), -- "L", "R" o "H"
	Status: () -> Status,
}

local rgb = Color3.fromRGB
local GAS = rgb(0, 150, 80)
local BRAKE = rgb(190, 50, 45)

DriveButtons.Ids = { "GiroIzq", "GiroDer", "Acelerar", "Frenar", "FrenoMano", "Luces", "IntIzq", "IntDer", "Emergencia" }

function DriveButtons.register(TouchLayout: any, h: Handlers)
	local function has(feature: string): () -> boolean
		return function()
			return h.Driving() and (feature == "" or (VehicleControls.features(h.Kind()) :: any)[feature] == true)
		end
	end
	local function holder(slot: string): (boolean) -> ()
		return function(down: boolean)
			h.Hold(slot, down)
		end
	end

	-- Flechas de girar
	TouchLayout.register({ Id = "GiroIzq", Icon = "izquierda", Label = "Izquierda", DriveSlot = "GiroIzq", Shape = "Arrow", Chevron = 180, Priority = 1, Visible = has(""), Hold = holder("Left") })
	TouchLayout.register({ Id = "GiroDer", Icon = "derecha", Label = "Derecha", DriveSlot = "GiroDer", Shape = "Arrow", Chevron = 0, Priority = 1, Visible = has(""), Hold = holder("Right") })
	-- Pedales
	TouchLayout.register({ Id = "Acelerar", Icon = "acelerar", Label = "ACELERAR", DriveSlot = "Acelerar", Shape = "Pedal", Tint = GAS, Priority = 1, Visible = has(""), Hold = holder("Gas") })
	TouchLayout.register({
		Id = "Frenar",
		Icon = "frenar",
		Label = "FRENO",
		DriveSlot = "Frenar",
		Shape = "Pedal",
		Tint = BRAKE,
		Priority = 1,
		Visible = has(""),
		Hold = holder("Brake"),
		-- Parado y pisándolo: marcha atrás
		Badge = function()
			return if h.Status().Reversing then "R" else nil
		end,
	})
	-- Freno de mano
	TouchLayout.register({
		Id = "FrenoMano",
		Icon = "frenomano",
		Label = "Freno mano",
		DriveSlot = "FrenoMano",
		Priority = 3,
		Key = "Espacio",
		Pad = "A",
		Visible = has("Handbrake"),
		Hold = holder("Handbrake"),
		Active = function()
			return h.Status().Parked
		end,
	})
	-- Luces: tocar = cortas / apagar; mantener = largas
	local pressedAt: number? = nil
	TouchLayout.register({
		Id = "Luces",
		Icon = "luces",
		Label = "Luces",
		DriveSlot = "Luces",
		Priority = 3.1,
		Key = "L",
		Pad = "R3",
		Visible = has("Lights"),
		Hold = function(down: boolean)
			if down then
				local at = os.clock()
				pressedAt = at
				task.delay(VehicleControls.HIGH_BEAM_HOLD, function()
					if pressedAt == at then
						pressedAt = nil
						h.Lights(true)
						TouchLayout.refresh()
					end
				end)
			elseif pressedAt then
				pressedAt = nil
				h.Lights(false)
				TouchLayout.refresh()
			end
		end,
		Active = function()
			return h.Status().Lights > 0
		end,
		Badge = function()
			return if h.Status().Lights == 2 then "Largas" else nil
		end,
	})
	-- Intermitentes y emergencia
	local function indicator(id: string, icon: string, label: string, side: string, key: string, pad: string, priority: number)
		TouchLayout.register({
			Id = id,
			Icon = icon,
			Label = label,
			DriveSlot = id,
			Priority = priority,
			Key = key,
			Pad = pad,
			Visible = has("Indicators"),
			Callback = function()
				h.Indicator(side)
			end,
			Active = function()
				local status = h.Status()
				if side == "H" then
					return if status.Hazard then "wait" else false -- (ámbar)
				end
				return status.Indicator == side
			end,
		})
	end
	indicator("IntIzq", "intizq", "Señal izq.", "L", "Q", "LB", 3.2)
	indicator("IntDer", "intder", "Señal der.", "R", "E", "RB", 3.3)
	indicator("Emergencia", "emergencia", "Emergencia", "H", "X", "Y", 3.4)
end

return DriveButtons
