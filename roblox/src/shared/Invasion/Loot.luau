-- Loot: lo que sueltan los alienígenas y sus naves (materiales, minerales, armas, planos y piezas de
-- naves y «objetos de otras galaxias»). Cuentas puras (scripts/test-invasion.luau); lo reparte
-- InvasionService (siempre el servidor) y lo guarda la mochila (shared/Items, InventoryService). Lo
-- que no cabe en la mochila va a la Xenobodega (data.Invasion.Stash) y se recoge en el Laboratorio
-- Xeno (junto al hospital), donde también se vende y se fabrica el inversor de fase (Transform).
--
-- Reglas contra las granjas (nada de quedarse matando para hacerse rico):
--   * Solo cuenta quien derriba (o, en naves grandes y el rey, quien haya ayudado lo bastante).
--   * Topes por invasión (PerInvasion) y por hora real (PerHour) de cada tipo; las armas, los planos y
--     los objetos únicos además solo una vez (Unique) o con su propio tope.
--   * Fuera de una invasión no cae nada (no hay alienígenas que tumbar).

local Races = require(script.Parent.Races)

local Loot = {}

export type Def = { Id: string, Name: string, Icon: string, Kind: string, Rarity: string, Price: number, Stack: number, Desc: string, Race: string? }

-- Rarezas (para el color del aviso)
Loot.Rarity = {
	Comun = { Name = "Común", Color = { 200, 200, 210 } },
	Raro = { Name = "Raro", Color = { 80, 170, 255 } },
	Epico = { Name = "Épico", Color = { 190, 100, 255 } },
	Legendario = { Name = "Legendario", Color = { 255, 190, 40 } },
}

local defs: { [string]: Def } = {}
local function add(d: Def)
	defs[d.Id] = d
end

-- Materiales de cada raza (comunes) y sus muestras (para curar a la gente transformada)
for _, race in Races.List do
	local mat = ({
		Vortidos = { "Cristal de Kael", "💠", "Un trozo de cristal que zumba bajito. Si lo acercas al oído, tararea." },
		Morfagos = { "Membrana de Tharn", "🫧", "Elástica, tibia y ligeramente pegajosa. Huele a menta (no se sabe por qué)." },
		Ferrocefalos = { "Chatarra de Ozzar", "⚙️", "Tornillos que no encajan en ninguna rosca de la Tierra. Pesan menos de lo que parece." },
		Luminidos = { "Polvo de Ilyra", "✨", "Brilla en la oscuridad y se escapa de los bolsillos si no los cierras bien." },
		Brumaridos = { "Perla de Oskun", "🫧", "Siempre está húmeda. Dentro se ve un mar en miniatura." },
	})[race.Id]
	add({ Id = race.Material, Name = mat[1], Icon = mat[2], Kind = "Material", Rarity = "Comun", Price = 28, Stack = 60, Desc = mat[3] .. " Se vende en el Laboratorio Xeno.", Race = race.Id })
	add({ Id = race.Sample, Name = "Muestra " .. ({ Vortidos = "cristalina", Morfagos = "de membrana", Ferrocefalos = "de engranaje", Luminidos = "de luz", Brumaridos = "de bruma" })[race.Id], Icon = "🧪", Kind = "Sample", Rarity = "Comun", Price = 6, Stack = 30, Desc = ("Una muestra de los %s. Con tres muestras y un material se fabrica el inversor de fase en el Laboratorio Xeno."):format(race.Name), Race = race.Id })
end
-- Minerales de otras galaxias (de las naves sobre todo)
add({ Id = "Xenita", Name = "Xenita", Icon = "🪨", Kind = "Mineral", Rarity = "Comun", Price = 18, Stack = 80, Desc = "Mineral verde que flota un milímetro por encima de la mesa." })
add({ Id = "AleacionEstelar", Name = "Aleación estelar", Icon = "🔩", Kind = "Mineral", Rarity = "Raro", Price = 65, Stack = 40, Desc = "Ligera como el aluminio y dura como el diamante. A los astilleros les encanta." })
add({ Id = "NucleoPlasma", Name = "Núcleo de plasma", Icon = "🔆", Kind = "Mineral", Rarity = "Epico", Price = 190, Stack = 10, Desc = "El corazón de un motor alienígena. Calentito. No lo metas en el microondas." })
-- Munición de las armas alienígenas
add({ Id = "CeldaXeno", Name = "Celda de energía xeno", Icon = "🔋", Kind = "Ammo", Rarity = "Comun", Price = 4, Stack = 200, Desc = "Munición de las armas alienígenas (se gasta al recargar)." })
-- Planos y piezas de naves (para el astillero de la Saga 2; se guardan también en data.Space.Blueprints)
add({ Id = "PlanoNave", Name = "Plano de nave alienígena", Icon = "📐", Kind = "Blueprint", Rarity = "Legendario", Price = 0, Stack = 5, Desc = "Planos completos de una nave de otra galaxia. Algún día, en el astillero, servirán de algo muy grande." })
add({ Id = "PiezaMotor", Name = "Pieza: motor de deriva", Icon = "🛠️", Kind = "ShipPart", Rarity = "Epico", Price = 0, Stack = 10, Desc = "Pieza de motor alienígena. Se guarda para mejorar tu nave en el astillero." })
add({ Id = "PiezaEscudo", Name = "Pieza: emisor de escudo", Icon = "🛡️", Kind = "ShipPart", Rarity = "Epico", Price = 0, Stack = 10, Desc = "Un emisor de escudo que aún chisporrotea. Para el astillero." })
add({ Id = "PiezaCanon", Name = "Pieza: cañón de fase", Icon = "🎯", Kind = "ShipPart", Rarity = "Epico", Price = 0, Stack = 10, Desc = "El cañón de una nave alienígena, desmontado. Para el astillero." })
-- El inversor de fase (cura a una persona transformada; se fabrica en el Laboratorio Xeno)
add({ Id = "InversorFase", Name = "Inversor de fase", Icon = "💉", Kind = "Device", Rarity = "Raro", Price = 0, Stack = 5, Desc = "Devuelve a su forma a una persona transformada por los alienígenas. Acércate a la criatura y úsalo («Revertir»)." })
-- Objetos de otras galaxias (coleccionables, cada uno una sola vez)
Loot.Collectibles = {
	{ "BrujulaCasa", "Brújula que apunta a casa", "🧭", "Siempre señala hacia el sitio donde te sientes en casa. Ahora mismo apunta a Valmar." },
	{ "SemillaEstrella", "Semilla de estrella", "🌰", "Dicen que, plantada en una noche sin nubes, en mil años da una estrella pequeñita." },
	{ "DiscoTharn", "Disco de música de Tharn", "💿", "Suena como una ballena cantando dentro de un globo. Es el número uno en el Cúmulo de Tharn." },
	{ "MonedaOzzar", "Moneda de Ozzar", "🪙", "Tiene un engranaje en cada cara. Gira sola cuando nadie la mira." },
	{ "PlumaLuz", "Pluma de luz", "🪶", "Escribe con luz. Lo que escribes se lee solo de noche." },
	{ "CaracolaNiebla", "Caracola de niebla", "🐚", "Si te la acercas al oído no se oye el mar: se oye la niebla. Es más bajito." },
	{ "MapaEstelar", "Mapa estelar arrugado", "🗺️", "Un mapa de otra galaxia con una cruz y una nota: «aquí se está muy bien en verano»." },
	{ "HuevoCristal", "Huevo de cristal (vacío)", "🥚", "Lo que fuera que había dentro ya se fue. Esperemos que a un sitio bonito." },
	{ "LlaveSinPuerta", "Llave sin puerta", "🗝️", "Abre una puerta que aún no existe. Paciencia." },
	{ "RelojLunas", "Reloj de doce lunas", "🕰️", "Doce agujas, doce lunas. Ninguna marca la hora de Valmar, pero todas aciertan en algún sitio." },
}
for _, c in Loot.Collectibles do
	add({ Id = c[1], Name = c[2], Icon = c[3], Kind = "Collectible", Rarity = "Epico", Price = 120, Stack = 1, Desc = "Objeto de otra galaxia. " .. c[4] })
end

Loot.Defs = defs

function Loot.get(id: string?): Def?
	return if id then defs[id] else nil
end

-- Armas alienígenas (shared/Weapons: XenoPrisma, XenoEsporas, XenoRemache, XenoLanzaSolar, XenoArpon)
function Loot.weaponItem(raceId: string): string?
	local race = Races.get(raceId)
	return race and ("Arma_" .. race.Weapon) or nil
end

-- Topes contra las granjas
Loot.PerInvasion = { Material = 30, Sample = 12, Mineral = 18, Ammo = 120, Weapon = 1, Blueprint = 1, ShipPart = 2, Collectible = 2 }
Loot.PerHour = { Weapon = 2, Blueprint = 1, ShipPart = 4, Collectible = 3 }

export type Counters = { Invasion: { [string]: number }, Hour: { [string]: number }, HourStart: number }

function Loot.newCounters(now: number): Counters
	return { Invasion = {}, Hour = {}, HourStart = now }
end

-- ¿Cabe uno más de este tipo para este jugador? (y lo apunta si cabe)
function Loot.allow(c: Counters, kind: string, count: number, now: number): boolean
	if now - c.HourStart >= 3600 then
		c.Hour = {}
		c.HourStart = now
	end
	local inv = Loot.PerInvasion[kind]
	local hour = Loot.PerHour[kind]
	if inv and (c.Invasion[kind] or 0) + count > inv then
		return false
	end
	if hour and (c.Hour[kind] or 0) + count > hour then
		return false
	end
	c.Invasion[kind] = (c.Invasion[kind] or 0) + count
	c.Hour[kind] = (c.Hour[kind] or 0) + count
	return true
end

-- Qué cae al tumbar a un enemigo (lista de { Id, Count }); r() = 0..1. kind: Grunt, Heavy, Ranged,
-- Elite, Fighter, Drone, Dropship, Scout, King, Creature
export type Drop = { Id: string, Count: number }
function Loot.roll(kind: string, raceId: string, r: () -> number): { Drop }
	local race = Races.get(raceId) or Races.List[1]
	local out: { Drop } = {}
	local function maybe(chance: number, id: string, count: number)
		if r() < chance then
			table.insert(out, { Id = id, Count = count })
		end
	end
	if kind == "Creature" then
		maybe(0.8, race.Sample, 1)
		return out
	end
	local ground = kind == "Grunt" or kind == "Heavy" or kind == "Ranged" or kind == "Elite"
	if ground then
		maybe(0.75, race.Material, if kind == "Heavy" then 2 else 1)
		maybe(0.35, race.Sample, 1)
		maybe(0.5, "CeldaXeno", 12)
		maybe(if kind == "Elite" then 0.5 else 0.08, "Xenita", 1 + math.floor(r() * 2))
		if kind == "Elite" then
			maybe(0.3, Loot.weaponItem(race.Id) :: string, 1)
			maybe(0.15, "AleacionEstelar", 1)
		elseif kind == "Heavy" then
			maybe(0.03, Loot.weaponItem(race.Id) :: string, 1)
		end
		maybe(0.01, Loot.Collectibles[1 + math.floor(r() * #Loot.Collectibles) % #Loot.Collectibles][1], 1)
	elseif kind == "Drone" then
		maybe(0.6, "Xenita", 1)
		maybe(0.25, race.Material, 1)
	elseif kind == "Fighter" or kind == "Scout" then
		maybe(0.8, "Xenita", 2)
		maybe(0.3, "AleacionEstelar", 1)
		maybe(0.04, "NucleoPlasma", 1)
		maybe(0.03, ({ "PiezaMotor", "PiezaEscudo", "PiezaCanon" })[1 + math.floor(r() * 3) % 3], 1)
		maybe(if kind == "Scout" then 0.25 else 0.01, Loot.Collectibles[1 + math.floor(r() * #Loot.Collectibles) % #Loot.Collectibles][1], 1)
	elseif kind == "Dropship" then
		table.insert(out, { Id = "Xenita", Count = 3 })
		maybe(0.6, "AleacionEstelar", 1)
		maybe(0.2, "NucleoPlasma", 1)
		maybe(0.08, ({ "PiezaMotor", "PiezaEscudo", "PiezaCanon" })[1 + math.floor(r() * 3) % 3], 1)
		maybe(0.02, "PlanoNave", 1)
	elseif kind == "King" then
		table.insert(out, { Id = "NucleoPlasma", Count = 2 })
		table.insert(out, { Id = "AleacionEstelar", Count = 3 })
		table.insert(out, { Id = Loot.weaponItem(race.Id) :: string, Count = 1 })
		table.insert(out, { Id = ({ "PiezaMotor", "PiezaEscudo", "PiezaCanon" })[1 + math.floor(r() * 3) % 3], Count = 1 })
		maybe(0.5, "PlanoNave", 1)
		table.insert(out, { Id = Loot.Collectibles[1 + math.floor(r() * #Loot.Collectibles) % #Loot.Collectibles][1], Count = 1 })
	end
	return out
end

-- El tipo de cada objeto para los topes ("Weapon" para las armas)
function Loot.kindOf(id: string): string
	if string.sub(id, 1, 9) == "Arma_Xeno" then
		return "Weapon"
	end
	local d = defs[id]
	return if d then d.Kind else "Other"
end

-- Precio de venta en el Laboratorio Xeno (0 = no se vende)
function Loot.price(id: string): number
	local d = defs[id]
	return if d then d.Price else 0
end

-- Inversor de fase: 3 muestras (de cualquier raza) + 1 material alienígena
Loot.Recipe = { Samples = 3, Materials = 1, Out = "InversorFase" }

-- ¿Puede fabricarlo con lo que tiene? (have = { [id] = count }) -> ok, qué gastar { [id] = n }
function Loot.craftPlan(have: { [string]: number }): (boolean, { [string]: number })
	local spend: { [string]: number } = {}
	local needS, needM = Loot.Recipe.Samples, Loot.Recipe.Materials
	for _, race in Races.List do
		local s = math.min(have[race.Sample] or 0, needS)
		if s > 0 then
			spend[race.Sample] = s
			needS -= s
		end
		local m = math.min(have[race.Material] or 0, needM)
		if m > 0 then
			spend[race.Material] = (spend[race.Material] or 0) + m
			needM -= m
		end
	end
	return needS <= 0 and needM <= 0, spend
end

return Loot
