-- Fishing: peces, niveles, cañas, herramientas, cebo, bancos de peces, monstruos marinos y oficio de
-- pescador (FishingService, FishingUI, SupermarketService, Items).
--
-- Se pesca en cualquier orilla con agua delante ("Pescar aquí") y en los sitios de pesca
-- (tag FishingSpot): el muelle del puerto, los pantalanes de los lagos y del río, y el barco de pesca.
-- Cada sitio tiene su agua (Water) y en cada agua viven unos peces:
--   * Río y lago: agua dulce. Mar: desde la orilla y el puerto. Alta mar: solo desde el barco.
--   * Cada pez pide un NIVEL de pesca, una CAÑA mínima y a veces una HERRAMIENTA (nasa, red, arpón,
--     sonar). Los peces pequeños salen desde el principio; los grandes, más adelante.
--   * Los grandes pelean: hay que tirar varias veces seguidas antes de que se suelten. Una caña
--     mejor de lo necesario hace falta tirar menos veces.
--   * Cada pez que pescas da experiencia y subes de nivel.
--   * Si pica uno que aún no puedes sacar, rompe el sedal y te dice qué te falta.
--   * Bancos de peces: cada agua tiene un número de peces de cada especie. Al pescar bajan; si una
--     especie se acaba, vuelve a salir al cabo de unas capturas o de un rato. Nunca se queda vacía.
--   * Monstruos (Megalodón, Kraken): solo en alta mar, solo si hay varios pescadores expertos a la
--     vez en el barco, y solo se sacan tirando todos juntos.
-- Lo que pescas va a la mochila y se vende en la pescadería del supermercado (los peces que el
-- supermercado vende van a su mostrador; los demás los compra la lonja).

local Fishing = {}

export type Species = {
	Id: string, -- id del pez
	Item: string, -- objeto de la mochila
	Name: string,
	Icon: string,
	Waters: { [string]: number }, -- peso (probabilidad) en cada agua
	Level: number, -- nivel de pesca que hace falta
	Rod: number, -- caña mínima (Tier)
	Tool: string?, -- herramienta que hace falta (Fishing.Tools)
	Pulls: number, -- tirones para sacarlo (1 = sale al momento)
	Window: number, -- segundos para reaccionar cuando pica
	Pop: number, -- cuántos hay en cada agua (banco de peces)
	Xp: number,
	Rarity: string,
	Rare: boolean?,
	Price: number, -- lo que paga la pescadería por cada uno
	Product: string?, -- producto del supermercado que repone (Groceries); si no, lo compra la lonja
	Kg: { number }, -- peso mínimo y máximo (solo para contarlo bonito)
}

Fishing.Waters = {
	Mar = "el mar",
	AltaMar = "alta mar",
	Rio = "el río",
	Lago = "el lago",
}
Fishing.WaterIcons = { Rio = "🏞️", Lago = "🌿", Mar = "🌊", AltaMar = "⛴️" }

---------------------------------------------------------------------
-- Nivel de pesca
---------------------------------------------------------------------
Fishing.MaxLevel = 50

-- Experiencia total que hace falta para llegar a un nivel
function Fishing.xpFor(level: number): number
	return math.floor(6 * (math.max(level, 1) - 1) ^ 1.8)
end

function Fishing.levelFor(xp: number): number
	local level = 1
	while level < Fishing.MaxLevel and xp >= Fishing.xpFor(level + 1) do
		level += 1
	end
	return level
end

local function rarityOf(level: number): string
	if level >= 35 then
		return "Legendario"
	elseif level >= 25 then
		return "Épico"
	elseif level >= 15 then
		return "Raro"
	elseif level >= 5 then
		return "Poco común"
	end
	return "Común"
end
Fishing.RarityColors = {
	["Común"] = Color3.fromRGB(200, 210, 225),
	["Poco común"] = Color3.fromRGB(110, 230, 120),
	["Raro"] = Color3.fromRGB(80, 170, 255),
	["Épico"] = Color3.fromRGB(190, 120, 255),
	["Legendario"] = Color3.fromRGB(255, 190, 60),
}

---------------------------------------------------------------------
-- Especies
---------------------------------------------------------------------
local function sp(id: string, name: string, icon: string, waters: { [string]: number }, level: number, rod: number, tool: string?, price: number, kg: { number }, pulls: number, product: string?): Species
	local weight = 0
	for _, w in waters do
		weight = math.max(weight, w)
	end
	return {
		Id = id,
		Item = "Pez_" .. id,
		Name = name,
		Icon = icon,
		Waters = waters,
		Level = level,
		Rod = rod,
		Tool = tool,
		Pulls = pulls,
		Window = math.max(1, 1.8 - level * 0.016),
		Pop = math.clamp(math.floor(weight * 1.2), 3, 36),
		Xp = 3 + level * 2 + pulls,
		Rarity = rarityOf(level),
		Rare = level >= 10,
		Price = price,
		Product = product,
		Kg = kg,
	}
end

Fishing.Species = {
	-- Agua dulce: río y lagos
	sp("Gobio", "Gobio", "🐟", { Rio = 30, Lago = 20 }, 1, 1, nil, 2, { 0.02, 0.08 }, 1),
	sp("Trucha", "Trucha", "🐟", { Rio = 30, Lago = 25 }, 1, 1, nil, 5, { 0.3, 1.5 }, 1, "Trucha"),
	sp("Carpa", "Carpa", "🐟", { Lago = 32, Rio = 10 }, 2, 1, nil, 4, { 1, 6 }, 2),
	sp("Perca", "Perca", "🐠", { Lago = 22, Rio = 12 }, 3, 1, nil, 5, { 0.2, 1 }, 2),
	sp("Barbo", "Barbo", "🐟", { Rio = 18 }, 4, 1, nil, 6, { 0.5, 3 }, 2),
	sp("CangrejoRio", "Cangrejo de río", "🦀", { Rio = 14, Lago = 10 }, 5, 1, "Nasa", 6, { 0.05, 0.15 }, 1),
	sp("Tenca", "Tenca", "🐟", { Lago = 14 }, 6, 2, nil, 7, { 0.5, 2.5 }, 2),
	sp("BlackBass", "Black bass", "🐟", { Lago = 12 }, 8, 2, nil, 9, { 0.5, 4 }, 3),
	sp("Anguila", "Anguila", "🐍", { Rio = 10 }, 10, 2, nil, 11, { 0.5, 3 }, 3),
	sp("Salmon", "Salmón", "🐟", { Rio = 9, Lago = 4 }, 11, 2, nil, 12, { 2, 6 }, 3, "Salmon"),
	sp("Lucio", "Lucio", "🐊", { Lago = 7 }, 14, 3, nil, 16, { 2, 12 }, 4),
	sp("Siluro", "Siluro gigante", "🐋", { Rio = 5 }, 20, 3, nil, 26, { 20, 90 }, 6),
	sp("Esturion", "Esturión", "🦈", { Rio = 3, Lago = 2 }, 27, 4, nil, 45, { 30, 150 }, 7),
	-- Mar: desde la orilla, las playas y el puerto
	sp("Sardina", "Sardina", "🐟", { Mar = 30, AltaMar = 12 }, 1, 1, nil, 3, { 0.05, 0.15 }, 1, "Sardinas"),
	sp("Boqueron", "Boquerón", "🐟", { Mar = 26 }, 1, 1, nil, 3, { 0.02, 0.06 }, 1),
	sp("Caballa", "Caballa", "🐟", { Mar = 20, AltaMar = 10 }, 2, 1, nil, 4, { 0.2, 0.8 }, 1),
	sp("Dorada", "Dorada", "🐠", { Mar = 18, AltaMar = 5 }, 3, 1, nil, 6, { 0.3, 1.2 }, 2, "Dorada"),
	sp("Cangrejo", "Cangrejo", "🦀", { Mar = 14 }, 4, 1, "Nasa", 5, { 0.1, 0.5 }, 1),
	sp("Lubina", "Lubina", "🐟", { Mar = 14, AltaMar = 8 }, 5, 1, nil, 7, { 0.4, 2 }, 2, "Lubina"),
	sp("Sepia", "Sepia", "🦑", { Mar = 12 }, 6, 2, nil, 8, { 0.3, 2 }, 2),
	sp("Calamar", "Calamar", "🦑", { Mar = 10, AltaMar = 8 }, 8, 2, "Red", 10, { 0.2, 1.5 }, 2),
	sp("Pulpo", "Pulpo", "🐙", { Mar = 7, AltaMar = 5 }, 10, 2, nil, 12, { 1, 4 }, 3, "Pulpo"),
	sp("Morena", "Morena", "🐍", { Mar = 6 }, 13, 2, nil, 14, { 1, 8 }, 4),
	sp("Langosta", "Langosta", "🦞", { Mar = 4, AltaMar = 4 }, 15, 3, "Nasa", 30, { 0.5, 3 }, 3),
	sp("Rape", "Rape", "🐟", { Mar = 5, AltaMar = 5 }, 16, 3, nil, 20, { 2, 15 }, 4),
	sp("Raya", "Raya", "🪁", { Mar = 5 }, 17, 3, nil, 18, { 2, 20 }, 5),
	sp("Mero", "Mero", "🐟", { Mar = 4, AltaMar = 4 }, 19, 3, nil, 28, { 5, 40 }, 6),
	-- Alta mar: solo desde el barco de pesca
	sp("Merluza", "Merluza", "🐟", { AltaMar = 22 }, 2, 1, nil, 8, { 0.8, 3 }, 2, "Merluza"),
	sp("Gamba", "Gambas", "🦐", { AltaMar = 16 }, 3, 1, nil, 5, { 0.2, 0.5 }, 1, "Gambas"),
	sp("Bonito", "Bonito", "🐟", { AltaMar = 14 }, 8, 2, "Red", 12, { 2, 8 }, 3),
	sp("Atun", "Atún rojo", "🐟", { AltaMar = 7 }, 15, 3, nil, 30, { 8, 60 }, 5, "Atun"),
	sp("Lampuga", "Lampuga", "🐠", { AltaMar = 7 }, 18, 3, nil, 24, { 3, 20 }, 5),
	sp("PezLuna", "Pez luna", "🌕", { AltaMar = 4 }, 22, 3, nil, 35, { 50, 300 }, 6),
	sp("PezEspada", "Pez espada", "🗡️", { AltaMar = 5 }, 24, 4, "Arpon", 60, { 30, 150 }, 8),
	sp("TiburonAzul", "Tiburón azul", "🦈", { AltaMar = 4 }, 26, 4, "Arpon", 70, { 40, 180 }, 8),
	sp("PezLinterna", "Pez linterna", "🏮", { AltaMar = 5 }, 28, 4, "Sonar", 50, { 0.05, 0.2 }, 3),
	sp("Marlin", "Marlín azul", "🐟", { AltaMar = 3 }, 30, 4, "Arpon", 90, { 80, 400 }, 10),
	sp("TiburonMartillo", "Tiburón martillo", "🦈", { AltaMar = 3 }, 32, 4, "Arpon", 110, { 100, 350 }, 10),
	sp("RapeAbisal", "Rape abisal", "🎣", { AltaMar = 3 }, 34, 5, "Sonar", 120, { 5, 30 }, 8),
	sp("CalamarGigante", "Calamar gigante", "🦑", { AltaMar = 2 }, 36, 5, "Sonar", 180, { 100, 400 }, 12),
	sp("TiburonBlanco", "Gran tiburón blanco", "🦈", { AltaMar = 2 }, 38, 5, "Arpon", 250, { 500, 1500 }, 14),
	sp("Celacanto", "Celacanto", "🐟", { AltaMar = 1 }, 42, 5, "Sonar", 400, { 50, 90 }, 12),
} :: { Species }

Fishing.byId = {} :: { [string]: Species }
Fishing.byItem = {} :: { [string]: Species }
for _, s in Fishing.Species do
	Fishing.byId[s.Id] = s
	Fishing.byItem[s.Item] = s
end

-- A veces sale algo que no es un pez (en cualquier agua)
Fishing.Junk = {
	{ Name = "una bota vieja", Icon = "🥾" },
	{ Name = "una lata oxidada", Icon = "🥫" },
	{ Name = "un montón de algas", Icon = "🌿" },
}
Fishing.JunkWeight = 6
Fishing.LockedWeight = 0.3 -- los que aún no puedes sacar pican menos (y rompen el sedal)

---------------------------------------------------------------------
-- Cañas, herramientas y cebo (tienda de pesca del centro)
---------------------------------------------------------------------
Fishing.Rods = {
	CanaPescar = { Id = "CanaPescar", Name = "Caña de pescar", Icon = "🎣", Tier = 1, Level = 1, Price = 25, Bite = 1, Rare = 1, Desc = "Para empezar: peces pequeños en cualquier agua." },
	CanaPro = { Id = "CanaPro", Name = "Caña profesional", Icon = "🎣", Tier = 2, Level = 5, Price = 120, Bite = 0.85, Rare = 1.4, Desc = "Pican antes. Para sepias, anguilas, salmones…" },
	CanaCarbono = { Id = "CanaCarbono", Name = "Caña de carbono", Icon = "🎣", Tier = 3, Level = 12, Price = 450, Bite = 0.75, Rare = 1.7, Desc = "Ligera y fuerte: lucios, atunes, meros…" },
	CanaAltura = { Id = "CanaAltura", Name = "Caña de altura", Icon = "🎣", Tier = 4, Level = 20, Price = 1500, Bite = 0.65, Rare = 2, Desc = "Para los grandes de alta mar: peces espada, marlines, tiburones." },
	CanaAbisal = { Id = "CanaAbisal", Name = "Caña abisal", Icon = "🔱", Tier = 5, Level = 32, Price = 6000, Bite = 0.55, Rare = 2.4, Desc = "La mejor. Para los monstruos del fondo del mar." },
}
Fishing.RodOrder = { "CanaAbisal", "CanaAltura", "CanaCarbono", "CanaPro", "CanaPescar" } -- se usa la mejor que tengas
Fishing.RodByTier = {} :: { [number]: any }
for _, rod in Fishing.Rods do
	Fishing.RodByTier[rod.Tier] = rod
end

Fishing.Tools = {
	Gafas = { Id = "Gafas", Name = "Gafas y tubo", Icon = "🤿", Level = 1, Price = 40, Desc = "Para bucear: aguantas más sin respirar (45 s)." },
	Nasa = { Id = "Nasa", Name = "Nasa", Icon = "🧺", Level = 4, Price = 90, Desc = "Trampa para cangrejos y langostas." },
	FusilSubmarino = { Id = "FusilSubmarino", Name = "Fusil submarino", Icon = "🏹", Level = 3, Price = 150, Desc = "Pesca buceando: dispara a los peces bajo el agua." },
	Red = { Id = "Red", Name = "Red de pesca", Icon = "🕸️", Level = 8, Price = 250, Desc = "Para los bancos de calamares y bonitos." },
	Botella = { Id = "Botella", Name = "Equipo de buceo", Icon = "🫧", Level = 15, Price = 900, Desc = "Botella de aire: 150 s bajo el agua y los peces del fondo." },
	Arpon = { Id = "Arpon", Name = "Arpón", Icon = "🔱", Level = 22, Price = 1200, Desc = "Con caña: peces espada, marlines y tiburones. Buceando: los grandes." },
	Sonar = { Id = "Sonar", Name = "Sonar de pesca", Icon = "📡", Level = 28, Price = 2500, Desc = "Encuentra los peces del abismo (en alta mar)." },
}
Fishing.ToolOrder = { "Gafas", "FusilSubmarino", "Nasa", "Red", "Botella", "Arpon", "Sonar" }

---------------------------------------------------------------------
-- Pesca submarina: nadar, bucear y disparar con el fusil o el arpón (DivingService, DivingUI)
---------------------------------------------------------------------
Fishing.Dive = {
	Surface = -2, -- altura del agua (mar, río y lagos)
	Oxygen = { Base = 20, Gafas = 45, Botella = 150 }, -- segundos de aire
	Refill = 10, -- aire que recuperas por segundo fuera del agua
	DrownDamage = 15, -- vida que pierdes por segundo sin aire
	MaxFish = 5, -- peces nadando alrededor de cada buceador
	FishLife = 90, -- segundos que se queda un pez antes de irse
	Range = 30, -- distancia máxima del disparo
	ShotGap = 0.7, -- recarga entre disparos
	BoatRadius = 400, -- cerca del barco de pesca es alta mar
}
local NO_SPEAR = { Gamba = true, PezLinterna = true, Boqueron = true, Sardina = true, Gobio = true }

-- ¿Se puede pescar buceando? (los muy pequeños y los de nasa o red, no)
function Fishing.spearable(s: Species): boolean
	return not NO_SPEAR[s.Id] and s.Tool ~= "Nasa" and s.Tool ~= "Red"
end

-- Qué te falta para cazarlo buceando: nivel, fusil (o arpón para los grandes) y botella para los del fondo
function Fishing.spearMissing(s: Species, level: number, tools: { [string]: boolean }): { string }
	local list = {}
	if level < s.Level then
		table.insert(list, ("nivel %d"):format(s.Level))
	end
	if s.Rod >= 4 then
		if not tools.Arpon then
			table.insert(list, "arpón")
		end
	elseif not tools.Arpon and not tools.FusilSubmarino then
		table.insert(list, "fusil submarino")
	end
	if (s.Tool == "Sonar" or s.Level >= 30) and not tools.Botella then
		table.insert(list, "equipo de buceo")
	end
	return list
end

-- Un pez al azar para que nade cerca de un buceador (los que no puedes cazar salen menos)
function Fishing.pickSpear(water: string, rng: Random, pop: { [string]: number }?, can: (Species) -> boolean): Species?
	local list, total = {}, 0
	for _, s in Fishing.Species do
		local w = s.Waters[water]
		if w and Fishing.spearable(s) and (not pop or (pop[s.Id] or 0) > 0) then
			local weight = if can(s) then w else w * Fishing.LockedWeight
			table.insert(list, { s, weight })
			total += weight
		end
	end
	local r = rng:NextNumber() * total
	for _, e in list do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return if #list > 0 then list[#list][1] else nil
end

Fishing.Bait = { Id = "Cebo", Name = "Cebo", Icon = "🪱", Price = 4, Pack = 5, Bite = 0.6, Desc = "Un cebo por lanzamiento: pican mucho antes." }
Fishing.BoatPrice = 15 -- alquilar el barco de pesca (los pescadores de turno van gratis)

-- Tiempos (segundos)
Fishing.BiteMin, Fishing.BiteMax = 5, 14 -- lo que tardan en picar (sin cebo y con caña normal)
Fishing.Window = 1.8 -- tiempo para tirar cuando pica (los grandes dan menos)
Fishing.MoveCancel = 8 -- si te alejas más del sitio, se recoge el sedal

-- Pelea con los peces grandes: tirones que hacen falta y tiempo para darlos
function Fishing.pullsFor(species: Species, rodTier: number): number
	return math.max(1, species.Pulls - (rodTier - species.Rod) * 2)
end
function Fishing.fightSeconds(pulls: number): number
	return 3 + pulls * 0.45
end

---------------------------------------------------------------------
-- Bancos de peces: vuelven siempre
---------------------------------------------------------------------
Fishing.Respawn = {
	AfterCatches = 10, -- una especie agotada vuelve tras tantas capturas en esa agua…
	Seconds = 90, -- …o al cabo de este tiempo
	RegenSeconds = 20, -- y cada tanto vuelve un pez de cada especie que no esté completa
}

---------------------------------------------------------------------
-- Monstruos marinos: solo en alta mar y entre varios
---------------------------------------------------------------------
Fishing.Bosses = {
	Megalodon = {
		Id = "Megalodon",
		Item = "Pez_Megalodon",
		Name = "Megalodón",
		Icon = "🦈",
		Level = 40,
		Rod = 5,
		Tool = "Arpon",
		MinPlayers = 3, -- pescadores que tienen que tirar a la vez
		MinPulls = 10, -- tirones de cada uno para contar como que ha ayudado
		Hp = 260,
		Seconds = 45,
		Price = 4000,
		Xp = 600,
		Kg = { 20000, 50000 },
		Desc = "El tiburón más grande que ha existido. Solo lo sacan varios pescadores juntos.",
	},
	Kraken = {
		Id = "Kraken",
		Item = "Pez_Kraken",
		Name = "Kraken (súper calamar)",
		Icon = "🦑",
		Level = 45,
		Rod = 5,
		Tool = "Sonar",
		MinPlayers = 4,
		MinPulls = 10,
		Hp = 380,
		Seconds = 50,
		Price = 6000,
		Xp = 900,
		Kg = { 5000, 12000 },
		Desc = "Un calamar gigantesco del abismo. Hace falta un buen equipo para sacarlo.",
	},
}
Fishing.BossOrder = { "Megalodon", "Kraken" }
Fishing.BossChance = 0.2 -- al picar en alta mar, si hay bastantes pescadores preparados
Fishing.BossCooldown = 240
Fishing.BossPullGap = 0.22 -- cada jugador cuenta como mucho unos 4 tirones por segundo

---------------------------------------------------------------------
-- Requisitos
---------------------------------------------------------------------
-- Qué te falta para un pez o monstruo (lista vacía = puedes sacarlo)
function Fishing.missing(target: { [string]: any }, level: number, rodTier: number, tools: { [string]: boolean }): { string }
	local list = {}
	if level < target.Level then
		table.insert(list, ("nivel %d"):format(target.Level))
	end
	if rodTier < target.Rod then
		local rod = Fishing.RodByTier[target.Rod]
		table.insert(list, if rod then string.lower(rod.Name) else "una caña mejor")
	end
	if target.Tool and not tools[target.Tool] then
		local tool = Fishing.Tools[target.Tool]
		table.insert(list, if tool then string.lower(tool.Name) else target.Tool)
	end
	return list
end

-- Lo que puede picar en un agua, con sus pesos. `pop` (opcional) dice cuántos quedan de cada uno.
-- `can(species)` dice si lo puedes sacar; los que no, pican menos.
function Fishing.table(water: string, rareBoost: number, pop: { [string]: number }?, can: ((Species) -> boolean)?): { { Species: Species?, Weight: number, Locked: boolean? } }
	local list = {}
	for _, s in Fishing.Species do
		local w = s.Waters[water]
		if w and (not pop or (pop[s.Id] or 0) > 0) then
			local ok = not can or can(s)
			local weight = if s.Rare then w * rareBoost else w
			table.insert(list, { Species = s, Weight = if ok then weight else weight * Fishing.LockedWeight, Locked = not ok })
		end
	end
	table.insert(list, { Species = nil, Weight = Fishing.JunkWeight })
	return list
end

function Fishing.pick(water: string, rareBoost: number, rng: Random, pop: { [string]: number }?, can: ((Species) -> boolean)?): (Species?, boolean)
	local list = Fishing.table(water, rareBoost, pop, can)
	local total = 0
	for _, e in list do
		total += e.Weight
	end
	local r = rng:NextNumber() * total
	for _, e in list do
		r -= e.Weight
		if r <= 0 then
			return e.Species, e.Locked == true
		end
	end
	return nil, false
end

-- Un pez al azar de los que salen al principio (lo usa el pescador NPC)
function Fishing.roll(water: string, rareBoost: number, rng: Random): Species?
	local species, locked = Fishing.pick(water, rareBoost, rng, nil, function(s)
		return s.Level <= 1 and s.Tool == nil
	end)
	return if locked then nil else species
end

-- Oficio de pescador
Fishing.Job = {
	Name = "Pescador",
	Icon = "🎣",
	PayBonus = 1.5, -- el supermercado paga más a los pescadores de turno
	EnergyCost = 1, -- por cada venta
	CarryGoal = 6, -- con tantos peces, la guía te lleva al supermercado
}

-- Pescador NPC del puerto: si ningún jugador pesca de turno, cada cierto tiempo trae algo de pescado
Fishing.NpcDeliveryEvery = 150
Fishing.NpcDeliveryCount = 2

return Fishing
