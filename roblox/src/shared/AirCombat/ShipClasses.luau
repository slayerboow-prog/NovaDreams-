-- ShipClasses: las CLASES de nave del jugador (expansión espacial «La Deriva», fase 1;
-- docs/espacio-aaa/expansion-15h.md §7). Cuentas puras: las usan el servidor (Services/AirCombatService:
-- validar el vuelo y el casco; Services/SpaceService: el astillero), el cliente (Controllers/AirCombatClient:
-- la misma física que el servidor) y las pruebas (scripts/test-shipclasses.luau).
--
-- Cada clase se PILOTA distinto (no es una pintura): sale del caza de siempre (ShipFlight.Specs.Caza)
-- con sus multiplicadores de vuelo, su casco y escudo, su bodega, su radar y su POTENCIA (cuántos niveles
-- de módulos caben encendidos a la vez: shared/AirCombat/ShipCombat.Upgrades).
--   Caza         todo terreno (la de siempre; la tiene todo el mundo)
--   Interceptor  muy rápido y ágil, poco casco, bodega pequeña
--   Carguero     lento, mucho casco y escudo, bodega enorme
--   Explorador   ágil, radar y escáner lejanos, casco medio
-- (las demás clases del diseño —alienígena, fragata y la Aguja— llegan con su fase)

local ShipFlight = require(script.Parent.ShipFlight)

local ShipClasses = {}

export type Def = {
	Name: string,
	Text: string,
	Flight: { [string]: number }, -- multiplicadores sobre ShipFlight.Specs.Caza
	Shield: { Hull: number, Shield: number, Delay: number, Regen: number },
	Cargo: number, -- multiplicador de la bodega (Mining.CargoMax)
	Radar: number, -- multiplicador del alcance del radar y del escáner
	Power: number, -- niveles de módulos encendidos a la vez
	Price: { Money: number, Chispas: number, Componentes: number?, Datos: number? }?,
}

ShipClasses.Default = "Caza"
ShipClasses.Order = { "Caza", "Interceptor", "Carguero", "Explorador" }

ShipClasses.Defs = {
	Caza = {
		Name = "Caza",
		Text = "Equilibrado: para todo",
		Flight = {},
		Shield = { Hull = 100, Shield = 60, Delay = 3, Regen = 18 },
		Cargo = 1,
		Radar = 1,
		Power = 12,
		Price = nil,
	},
	Interceptor = {
		Name = "Interceptor",
		Text = "El más rápido y ágil; poco casco y bodega pequeña",
		Flight = { MaxSpeed = 1.22, BoostSpeed = 1.2, Accel = 1.3, PitchRate = 1.18, YawRate = 1.18, RollRate = 1.2, StrafeSpeed = 1.15 },
		Shield = { Hull = 70, Shield = 45, Delay = 2.5, Regen = 22 },
		Cargo = 0.6,
		Radar = 1,
		Power = 10,
		Price = { Money = 12000, Chispas = 40, Componentes = 10 },
	},
	Carguero = {
		Name = "Carguero pesado",
		Text = "Lento pero muy duro; bodega enorme para minar y comerciar",
		Flight = { MaxSpeed = 0.8, BoostSpeed = 0.82, Accel = 0.72, PitchRate = 0.74, YawRate = 0.74, RollRate = 0.7, StrafeSpeed = 0.8 },
		Shield = { Hull = 190, Shield = 110, Delay = 3.5, Regen = 16 },
		Cargo = 2.5,
		Radar = 1,
		Power = 16,
		Price = { Money = 15000, Chispas = 35, Componentes = 12 },
	},
	Explorador = {
		Name = "Explorador",
		Text = "Ágil, con radar y escáner lejanos; para descubrir lo que nadie ha visto",
		Flight = { MaxSpeed = 1.08, BoostSpeed = 1.05, PitchRate = 1.1, YawRate = 1.1, RollRate = 1.05 },
		Shield = { Hull = 85, Shield = 55, Delay = 3, Regen = 18 },
		Cargo = 0.8,
		Radar = 1.6,
		Power = 13,
		Price = { Money = 13000, Chispas = 35, Datos = 20 },
	},
} :: { [string]: Def }

function ShipClasses.valid(id: any): boolean
	return type(id) == "string" and ShipClasses.Defs[id] ~= nil
end

function ShipClasses.def(id: any): Def
	return ShipClasses.Defs[if ShipClasses.valid(id) then id else ShipClasses.Default]
end

-- La física de vuelo de esa clase con la mejora del impulsor (speedBonus: fracción, 0,08 = +8 %). Igual en
-- el servidor y en el cliente (sale de los mismos datos). Se registra en ShipFlight.Specs con su nombre
-- para que ShipFlight.new(nombre) la use.
local cache: { [string]: any } = {}
function ShipClasses.flightSpec(id: any, speedBonus: number?): (string, any)
	local cls = if ShipClasses.valid(id) then id else ShipClasses.Default
	local bonus = math.clamp(tonumber(speedBonus) or 0, 0, 0.5)
	local key = ("%s@%d"):format(cls, math.floor(bonus * 1000 + 0.5))
	if cache[key] then
		return key, cache[key]
	end
	local base = ShipFlight.Specs.Caza :: any
	local spec = table.clone(base)
	for field, mult in ShipClasses.Defs[cls].Flight do
		if type(spec[field]) == "number" then
			spec[field] = spec[field] * mult
		end
	end
	spec.MaxSpeed *= 1 + bonus
	spec.BoostSpeed *= 1 + bonus
	spec.Name = ShipClasses.Defs[cls].Name
	cache[key] = spec
	ShipFlight.Specs[key] = spec
	return key, spec
end

-- Casco y escudo (para Shields.new)
function ShipClasses.shieldSpec(id: any): { [string]: number }
	return ShipClasses.def(id).Shield
end

return ShipClasses
