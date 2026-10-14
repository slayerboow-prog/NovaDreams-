-- ShipInfo: la ficha de la nave del jugador, el «HX-7 Halcón» (docs/espacio-aaa/nave-realista.md), para
-- los carteles del puerto espacial y del hangar de las estaciones (World/SpaceWorld).
--
--   VELOCIDAD MÁX.       1.250 km/h (la de la ficha, MaxKmh)
--   ESCUDOS / ESTRUCTURA el escudo y el casco de verdad (shared/AirCombat/Shields), en % (100% llena)
--   CAPACIDAD DE CARGA   la bodega de verdad: Mining.CargoMax unidades × KgPerUnit kg (40 × 300 = 12.000 kg)
--
--   ShipInfo.stats(state?) -> { { Label, Value } }   state: { Hull, MaxHull, Shield, MaxShield }? (sin él: llena)
--   ShipInfo.card(state?) -> string                  el texto del cartel (varias líneas)
--   ShipInfo.thousands(n) -> "12.000"

local Mining = require(script.Parent.Parent.Cosmos.Mining)

local ShipInfo = {}

ShipInfo.Name = "HX-7 Halcón"
ShipInfo.Designation = "HX-7"
ShipInfo.Title = "HX-7 HALCÓN" -- (string.upper no sabe de tildes)
ShipInfo.Class = "NAVE ESPACIAL"
ShipInfo.MaxKmh = 1250
ShipInfo.KgPerUnit = 300

function ShipInfo.thousands(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

local function pct(value: number?, max: number?): string
	if not value or not max or max <= 0 then
		return "100%"
	end
	return ("%d%%"):format(math.clamp(math.floor(value / max * 100 + 0.5), 0, 100))
end

function ShipInfo.cargoKg(): number
	return Mining.CargoMax * ShipInfo.KgPerUnit
end

function ShipInfo.stats(state: { Hull: number?, MaxHull: number?, Shield: number?, MaxShield: number? }?): { { Label: string, Value: string } }
	local s = state or {}
	return {
		{ Label = "VELOCIDAD MÁX.", Value = ShipInfo.thousands(ShipInfo.MaxKmh) .. " km/h" },
		{ Label = "ESCUDOS", Value = pct(s.Shield, s.MaxShield) },
		{ Label = "ESTRUCTURA", Value = pct(s.Hull, s.MaxHull) },
		{ Label = "CAPACIDAD DE CARGA", Value = ShipInfo.thousands(ShipInfo.cargoKg()) .. " kg" },
	}
end

function ShipInfo.card(state: any?): string
	local lines = { ("%s · %s"):format(ShipInfo.Title, ShipInfo.Class) }
	for _, row in ShipInfo.stats(state) do
		table.insert(lines, ("%s  %s"):format(row.Label, row.Value))
	end
	return table.concat(lines, "\n")
end

return ShipInfo
