-- SpaceEvents: los EVENTOS GLOBALES del Sistema Valmar (puro; lo enseña el HUD de la nave en la fila
-- «EVENTO GLOBAL» con su reloj, y lo aplica Services/SpaceService). Todos los servidores y todos los
-- jugadores ven lo mismo sin mandar nada por la red: el evento sale de la hora del servidor
-- (workspace:GetServerTimeNow()).
--
--   * Cada ciclo (15 min) empieza con un evento de 5 min y luego 10 min de calma (el HUD dice cuál
--     viene y en cuánto).
--   * Tormenta de asteroides en un campo: minar allí da una unidad más por golpe (si cabe en la bodega).
--   * Incursión pirata en un sector: cada derribo allí da ✨ +1 Chispa de estrella (con el tope por hora
--     de siempre).

local Zone = require(script.Parent.Zone)

local SpaceEvents = {}

SpaceEvents.Cycle = 900
SpaceEvents.Active = 300

export type Kind = { Id: string, Title: string, Where: string, Effect: string }
SpaceEvents.Kinds = {
	{ Id = "Tormenta", Title = "Tormenta de asteroides", Where = "Fields", Effect = "minar da el doble" },
	{ Id = "Incursion", Title = "Incursión pirata", Where = "Sectors", Effect = "✨ +1 por derribo" },
} :: { Kind }

export type Event = {
	Id: string,
	Kind: string,
	Title: string,
	PlaceId: string,
	PlaceName: string,
	Effect: string,
	Active: boolean,
	Left: number, -- segundos hasta que acaba (activo) o hasta que empieza (en calma)
}

local function eventOf(n: number): (Kind, { Id: string, Name: string })
	local kind = SpaceEvents.Kinds[n % #SpaceEvents.Kinds + 1]
	local list: { any } = if kind.Where == "Fields" then Zone.Fields else Zone.Sectors
	local place = list[(n // #SpaceEvents.Kinds) % #list + 1]
	return kind, place
end

-- El evento a la hora `t` (segundos de servidor): el que está en marcha o el siguiente
function SpaceEvents.at(t: number): Event
	local n = math.floor(t / SpaceEvents.Cycle)
	local into = t - n * SpaceEvents.Cycle
	local active = into < SpaceEvents.Active
	local idx = if active then n else n + 1
	local kind, place = eventOf(idx)
	return {
		Id = ("%s_%d"):format(kind.Id, idx),
		Kind = kind.Id,
		Title = kind.Title,
		PlaceId = place.Id,
		PlaceName = place.Name,
		Effect = kind.Effect,
		Active = active,
		Left = if active then SpaceEvents.Active - into else SpaceEvents.Cycle - into,
	}
end

-- mm:ss
function SpaceEvents.clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	return ("%02d:%02d"):format(s // 60, s % 60)
end

-- Textos para la fila del HUD: título y paso (con el reloj)
function SpaceEvents.texts(ev: Event): (string, string)
	local title = ("%s en %s"):format(ev.Title, ev.PlaceName)
	if ev.Active then
		return title, ("Termina en %s · %s"):format(SpaceEvents.clock(ev.Left), ev.Effect)
	end
	return "Próximo: " .. title, ("Empieza en %s · %s"):format(SpaceEvents.clock(ev.Left), ev.Effect)
end

-- ¿Minar en este campo da una unidad más ahora?
function SpaceEvents.mineBonus(t: number, fieldId: string?): boolean
	local ev = SpaceEvents.at(t)
	return ev.Active and ev.Kind == "Tormenta" and ev.PlaceId == fieldId
end

-- ¿Un derribo en este sector da una Chispa más ahora?
function SpaceEvents.killBonus(t: number, sectorId: string?): boolean
	local ev = SpaceEvents.at(t)
	return ev.Active and ev.Kind == "Incursion" and ev.PlaceId == sectorId
end

return SpaceEvents
