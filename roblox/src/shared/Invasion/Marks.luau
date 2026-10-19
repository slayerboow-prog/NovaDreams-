-- Marks: qué barras de vida de los alienígenas y qué letreros de zona se ven (docs/invasion.md, «HUD»).
-- Puro: lo usa Controllers/InvasionClient y lo prueba scripts/test-invasion.luau.
--
-- Queja del dueño (captura de v119/v120): barras rojas flotando sin alienígena debajo, unas encima de
-- otras, flechas rojas y los letreros verdes de todas las zonas de la ciudad tapando la pantalla.
-- Ahora:
--   * UNA barra pequeña por alienígena, pegada encima de su cabeza, solo si está cerca, se ve en la
--     pantalla y ya le han hecho daño (con la vida llena no hace falta). El rey, siempre.
--   * Dos barras que caerían casi en el mismo sitio de la pantalla: solo la del más cercano.
--   * Como mucho Caps[tier] a la vez (las más cercanas).
--   * Letreros de zona: solo las que están en disputa o conquistadas y no muy lejos (las de Valmar ya
--     no salen: la del sitio donde estás va en el panel EVENTO GLOBAL).

local Marks = {}

Marks.Caps = { Low = 3, Medium = 5, High = 7 }
Marks.Range = { Low = 90, Medium = 130, High = 170 } -- studs
Marks.MinGap = 36 -- píxeles entre dos barras (menos: se pisarían)
Marks.BarSize = { W = 52, H = 7 } -- píxeles (pequeña: no tapa al alienígena)
Marks.ZoneRange = 520 -- studs

export type Entry = {
	Id: any,
	Dist: number,
	Hp: number,
	Max: number,
	King: boolean?,
	OnScreen: boolean?,
	X: number?, -- dónde cae en la pantalla (píxeles)
	Y: number?,
}

-- ¿Merece barra? (sin mirar a los demás)
function Marks.wants(e: Entry, tier: string?): boolean
	if e.Hp <= 0 or e.OnScreen == false then
		return false
	end
	if e.King then
		return true
	end
	local range = Marks.Range[tier or "Medium"] or Marks.Range.Medium
	return e.Dist <= range and e.Hp < e.Max
end

-- Las que se ven: { [Id] = true }. list: cualquier orden (se ordena por distancia; el rey primero).
function Marks.pick(list: { Entry }, tier: string?): { [any]: boolean }
	local sorted = table.clone(list)
	table.sort(sorted, function(a, b)
		if (a.King == true) ~= (b.King == true) then
			return a.King == true
		end
		return a.Dist < b.Dist
	end)
	local cap = Marks.Caps[tier or "Medium"] or Marks.Caps.Medium
	local shown: { [any]: boolean } = {}
	local placed: { Entry } = {}
	local n = 0
	for _, e in sorted do
		if n >= cap and not e.King then
			break
		end
		if not Marks.wants(e, tier) then
			continue
		end
		local clash = false
		if e.X and e.Y then
			for _, o in placed do
				if o.X and o.Y and math.abs(o.X - e.X) < Marks.MinGap * 1.6 and math.abs(o.Y - e.Y) < Marks.MinGap * 0.6 then
					clash = true
					break
				end
			end
		end
		if clash and not e.King then
			continue
		end
		shown[e.Id] = true
		table.insert(placed, e)
		n += 1
	end
	return shown
end

-- ¿Se ve el letrero de una zona? (z: la zona publicada; dist: a ti, en studs)
function Marks.zoneVisible(z: { [string]: any }, dist: number): boolean
	local contested = z.Conquered == true or (tonumber(z.Control) or 0) > 0.02
	return contested and dist <= Marks.ZoneRange
end

return Marks
