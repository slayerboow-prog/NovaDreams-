-- DiscoverToast: el aviso de «Has descubierto <barrio>» (Controllers/LifeStory, evento «Discover»).
--
-- Antes era un letrero de 30 px en el centro de la pantalla (showMoment) que se montaba encima de los
-- demás avisos: en la nave, «Has descubierto San Roque» gigante sobre «La grieta del cielo se está
-- cerrando…» y la mira (captura del dueño, docs/bugs/espacio-cielo-azul.png). Ahora:
--   * es un aviso normal del HUD (Hud.toast, tipo Success): tamaño de aviso, en la columna de avisos
--     (debajo de los letreros de arriba y del panel de la nave: UI/TopStack), nunca encima de otro;
--   * de uno en uno: dos descubrimientos seguidos salen separados Gap segundos (en cola);
--   * el mismo no se repite en Repeat segundos.
-- La cola es pura (DiscoverToast.plan) y la prueba scripts/test-hud.luau.

local DiscoverToast = {}

DiscoverToast.Kind = "Success"
DiscoverToast.Icon = "📍 "
DiscoverToast.Gap = 3.5 -- segundos entre dos descubrimientos
DiscoverToast.Repeat = 30

export type State = { LastAt: number, Seen: { [string]: number } }

function DiscoverToast.new(): State
	return { LastAt = -math.huge, Seen = {} }
end

-- ¿Sale, y cuándo? (nil = no sale: repetido). Apunta en `st` que sale.
function DiscoverToast.plan(st: State, text: string, now: number): number?
	local seen = st.Seen[text]
	if seen and now - seen < DiscoverToast.Repeat then
		return nil
	end
	st.Seen[text] = now
	local delay = math.max(0, st.LastAt + DiscoverToast.Gap - now)
	st.LastAt = now + delay
	return delay
end

local state = DiscoverToast.new()

-- Lo enseña con el HUD (hud = UI/Hud). false si no hay HUD (el que llama usa su respaldo).
function DiscoverToast.show(text: string, hud: any, now: number?): boolean
	if type(hud) ~= "table" or type(hud.toast) ~= "function" then
		return false
	end
	local delay = DiscoverToast.plan(state, text, now or os.clock())
	if delay == nil then
		return true
	end
	local message = DiscoverToast.Icon .. text
	if delay <= 0 then
		hud.toast(DiscoverToast.Kind, message)
	else
		task.delay(delay, function()
			pcall(hud.toast, DiscoverToast.Kind, message)
		end)
	end
	return true
end

-- (pruebas) empezar de cero
function DiscoverToast._reset()
	state = DiscoverToast.new()
end

return DiscoverToast
