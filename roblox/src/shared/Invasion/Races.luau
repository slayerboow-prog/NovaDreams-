-- Races: las especies de otras galaxias que cruzan la Grieta durante la «Invasión de la Grieta»
-- (docs/invasion.md). Datos y cuentas puras (las prueba scripts/test-invasion.luau).
--
-- Lo que pidió el dueño: cada vez que se abre la grieta llega una raza DISTINTA (nunca la misma dos
-- veces seguidas), a veces llegan VARIAS a la vez (y se pelean un poco entre ellas) y, con poca
-- suerte, su DIOS o REY: un jefe enorme y muy difícil de tumbar. Cada raza tiene su aspecto, sus
-- colores, sus armas, cómo se comporta, sus naves, sus sonidos, lo que suelta y en qué convierte a
-- la gente de Valmar cuando la «alcanza» (nada de sangre: la gente se TRANSFORMA en criaturas de su
-- galaxia y se puede devolver a la normalidad: shared/Invasion/Transform).
--
-- Diseños originales (ninguno copia una franquicia). Cada raza:
--   Id, Name (plural), Galaxy, Lore, Palette { Body, Trim, Glow } (colores RGB), Style (cómo se
--   construyen sus modelos: World/Kit/AlienModels), Units { Grunt, Heavy, Ranged, Elite } (nombre y
--   multiplicadores sobre shared/Invasion/Rules.Ground), Air { Fighter, Drone, Dropship } (nombres),
--   Behaviour (Swarm / Siege / Snipe / Blink: cómo pelean), Weapon (arma que sueltan, shared/Weapons),
--   Sounds (de Config.Sounds: nada de ids nuevos sin comprobar), Material y Sample (shared/Invasion/Loot),
--   Creatures (en qué convierten a la gente y a los animales) y King (su dios o rey).

local Races = {}

export type Unit = { Name: string, Hp: number?, Damage: number?, Speed: number?, Range: number? }
export type Race = {
	Id: string,
	Name: string,
	One: string, -- (singular)
	Galaxy: string,
	Lore: string,
	Palette: { Body: { number }, Trim: { number }, Glow: { number } },
	Style: string,
	Behaviour: string,
	Units: { [string]: Unit },
	Air: { Fighter: string, Drone: string, Dropship: string },
	Weapon: string,
	Sounds: { Shot: string, ShotPitch: number, Boom: string, BoomPitch: number, Roar: string, RoarPitch: number },
	Material: string,
	Sample: string,
	Creatures: { { Id: string, Name: string, Hostile: boolean, Animal: boolean? } },
	King: { Id: string, Name: string, Title: string, Lines: { string } },
	Rivals: { string },
}

Races.List = {
	{
		Id = "Vortidos",
		Name = "Vórtidos",
		One = "vórtido",
		Galaxy = "Nebulosa Espiral de Kael",
		Lore = "Una colmena de cristal que crece cantando. Para ellos, una ciudad es una geoda que aún no ha florecido: vienen a «cristalizar» Valmar.",
		Palette = { Body = { 70, 200, 210 }, Trim = { 170, 120, 60 }, Glow = { 140, 255, 250 } },
		Style = "Cristal",
		Behaviour = "Siege", -- avanzan despacio en formación, levantan prismas y se atrincheran en las zonas
		Units = {
			Grunt = { Name = "Esquirla", Hp = 1, Speed = 0.95 },
			Heavy = { Name = "Monolito", Hp = 1.25, Speed = 0.8 },
			Ranged = { Name = "Prisma", Range = 1.15 },
			Elite = { Name = "Custodio de Kael" },
		},
		Air = { Fighter = "Fragata Prisma", Drone = "Astilla", Dropship = "Geoda" },
		Weapon = "XenoPrisma",
		Sounds = { Shot = "NaveLaserEnemigo", ShotPitch = 1.35, Boom = "NaveEstallido", BoomPitch = 1.25, Roar = "NaveChispas", RoarPitch = 0.6 },
		Material = "CristalKael",
		Sample = "MuestraCristal",
		Creatures = {
			{ Id = "CaminanteCristal", Name = "Caminante de cristal", Hostile = false },
			{ Id = "CiervoCuarzo", Name = "Ciervo de cuarzo", Hostile = false, Animal = true },
		},
		-- (la hoja del dueño dice que no tienen género: el título visible ya no es «la Reina Geoda»; el Id
		-- interno se queda igual para no romper nada guardado. docs/invasion.md, «Vórtidos de cristal»)
		King = { Id = "ReinaGeoda", Name = "Kael-Ithra", Title = "La Voz de la Geoda", Lines = { "La ciudad cantará conmigo.", "¡Cristalizad sus calles!", "Mi canto no se rompe… todavía." } },
		Rivals = { "Morfagos" },
	},
	{
		Id = "Morfagos",
		Name = "Mórfagos",
		One = "mórfago",
		Galaxy = "Cúmulo de Tharn",
		Lore = "Seres de membrana y tentáculos que adoptan todo lo que tocan. No odian a nadie: solo quieren que todo el mundo sea… blandito, como ellos.",
		Palette = { Body = { 170, 60, 170 }, Trim = { 60, 30, 80 }, Glow = { 120, 255, 120 } },
		Style = "Membrana",
		Behaviour = "Swarm", -- muchos y rápidos: rodean, saltan encima y se dispersan
		Units = {
			Grunt = { Name = "Larvón", Hp = 0.8, Speed = 1.25 },
			Heavy = { Name = "Coloso de membrana", Hp = 1.3, Speed = 0.85 },
			Ranged = { Name = "Escupidor", Range = 0.9, Damage = 1.1 },
			Elite = { Name = "Matriarca de Tharn" },
		},
		Air = { Fighter = "Medusa de guerra", Drone = "Esporo", Dropship = "Vaina" },
		Weapon = "XenoEsporas",
		Sounds = { Shot = "NaveLaserEnemigo", ShotPitch = 0.7, Boom = "NaveEstallido", BoomPitch = 0.75, Roar = "Multitud", RoarPitch = 0.45 },
		Material = "MembranaTharn",
		Sample = "MuestraMembrana",
		Creatures = {
			{ Id = "BichoTentacular", Name = "Bicho tentacular", Hostile = true },
			{ Id = "BabosaBrillante", Name = "Babosa brillante", Hostile = false, Animal = true },
		},
		King = { Id = "GranMadre", Name = "Tharn-Oo", Title = "La Gran Madre", Lines = { "Venid, pequeños. Todo es más bonito con tentáculos.", "¡Abrazadlos a todos!", "Me hacéis… cosquillas." } },
		Rivals = { "Vortidos", "Luminidos" },
	},
	{
		Id = "Ferrocefalos",
		Name = "Ferrocéfalos",
		One = "ferrocéfalo",
		Galaxy = "Anillo de Ozzar",
		Lore = "Una civilización de autómatas de chatarra que perdió a sus creadores hace milenios. Desmontan ciudades para construir copias de ellas… sin nadie dentro.",
		Palette = { Body = { 190, 95, 40 }, Trim = { 40, 40, 44 }, Glow = { 255, 210, 60 } },
		Style = "Chatarra",
		Behaviour = "Snipe", -- se quedan lejos, disparan desde arriba y montan torretas
		Units = {
			Grunt = { Name = "Remachador", Hp = 1.1, Speed = 0.9 },
			Heavy = { Name = "Martinete", Hp = 1.4, Speed = 0.7, Damage = 1.15 },
			Ranged = { Name = "Sonda telémetro", Range = 1.3 },
			Elite = { Name = "Capataz de Ozzar" },
		},
		Air = { Fighter = "Disco sierra", Drone = "Tuerca voladora", Dropship = "Tolva" },
		Weapon = "XenoRemache",
		Sounds = { Shot = "DisparoSubfusil", ShotPitch = 0.6, Boom = "NaveEstallido", BoomPitch = 0.9, Roar = "ClaxonPesado", RoarPitch = 0.5 },
		Material = "ChatarraOzzar",
		Sample = "MuestraEngranaje",
		Creatures = {
			{ Id = "AutomataChatarra", Name = "Autómata de chatarra", Hostile = false },
			{ Id = "PerroTostadora", Name = "Perro tostadora", Hostile = true, Animal = true },
		},
		King = { Id = "ReyEngranaje", Name = "OZ-0", Title = "El Rey Engranaje", Lines = { "Desmontando Valmar. Tiempo estimado: tres minutos.", "Error: humanos resistentes. Recalculando.", "¿Quién ha apagado mi engranaje principal?" } },
		Rivals = { "Luminidos" },
	},
	{
		Id = "Luminidos",
		Name = "Lumínidos",
		One = "lumínido",
		Galaxy = "Velo de Ilyra",
		Lore = "Seres de luz pura que viajan dentro de los rayos de las estrellas. Creen que la noche es una enfermedad y que Valmar necesita «curarse» de sombras.",
		Palette = { Body = { 250, 220, 140 }, Trim = { 130, 80, 200 }, Glow = { 255, 250, 210 } },
		Style = "Luz",
		Behaviour = "Blink", -- se teletransportan a saltos cortos y atacan de lado
		Units = {
			Grunt = { Name = "Chispa", Hp = 0.75, Speed = 1.35 },
			Heavy = { Name = "Faro", Hp = 1.35, Speed = 0.8 },
			Ranged = { Name = "Lanza solar", Range = 1.25, Damage = 1.1 },
			Elite = { Name = "Heraldo de Ilyra" },
		},
		Air = { Fighter = "Luna creciente", Drone = "Lucerna", Dropship = "Farol" },
		Weapon = "XenoLanzaSolar",
		Sounds = { Shot = "NaveLaser", ShotPitch = 1.6, Boom = "NaveChispas", BoomPitch = 1.4, Roar = "Descubrimiento", RoarPitch = 1.2 },
		Material = "PolvoIlyra",
		Sample = "MuestraLuz",
		Creatures = {
			{ Id = "ZorroLuz", Name = "Zorro de luz", Hostile = false, Animal = true },
			{ Id = "BuhoEstelar", Name = "Búho estelar", Hostile = false, Animal = true },
		},
		King = { Id = "DiosSol", Name = "Ilyra", Title = "El Dios Sol", Lines = { "Que no quede ni una sombra en esta ciudad.", "¡Brillad, hijos míos!", "Vuestra luz… es más terca que la mía." } },
		Rivals = { "Ferrocefalos", "Morfagos" },
	},
	{
		Id = "Brumaridos",
		Name = "Brumáridos",
		One = "brumárido",
		Galaxy = "Mar de Niebla de Oskun",
		Lore = "Navegantes de un mar de niebla sin orillas. Su mundo se secó; buscan un sitio con costa y mucha humedad. Valmar tiene las dos cosas.",
		Palette = { Body = { 90, 120, 150 }, Trim = { 220, 230, 235 }, Glow = { 120, 200, 255 } },
		Style = "Niebla",
		Behaviour = "Swarm",
		Units = {
			Grunt = { Name = "Remero de bruma", Hp = 0.9, Speed = 1.1 },
			Heavy = { Name = "Caparazón de Oskun", Hp = 1.5, Speed = 0.7 },
			Ranged = { Name = "Arponero", Range = 1.1 },
			Elite = { Name = "Almirante de niebla" },
		},
		Air = { Fighter = "Raya de niebla", Drone = "Medusilla", Dropship = "Concha" },
		Weapon = "XenoArpon",
		Sounds = { Shot = "NaveLaserEnemigo", ShotPitch = 0.9, Boom = "Chapuzon", BoomPitch = 0.7, Roar = "Olas", RoarPitch = 0.6 },
		Material = "PerlaOskun",
		Sample = "MuestraBruma",
		Creatures = {
			{ Id = "RanaNiebla", Name = "Rana de niebla", Hostile = true, Animal = true },
			{ Id = "PezCaminante", Name = "Pez caminante", Hostile = false, Animal = true },
		},
		King = { Id = "ReyMarea", Name = "Oskun", Title = "El Rey de la Marea", Lines = { "Esta costa será mi nuevo mar.", "¡Que suba la niebla!", "Ni la marea más alta os ha tumbado." } },
		Rivals = { "Ferrocefalos" },
	},
} :: { Race }

Races.ById = {} :: { [string]: Race }
for _, r in Races.List do
	Races.ById[r.Id] = r
end

function Races.get(id: string?): Race?
	return if id then Races.ById[id] else nil
end

-- Probabilidades (por invasión)
Races.Odds = {
	Second = 0.22, -- llega una segunda raza a la vez
	Third = 0.05, -- y una tercera (solo si ya hay dos)
	King = 0.12, -- aparece el dios o rey de la raza principal
	KingPity = 6, -- si en tantas invasiones seguidas no ha salido ningún rey, sale seguro
	KingMinPlayers = 1,
}

-- Una raza que no sea la de la última invasión (ni ninguna de `exclude`). r() devuelve 0..1
function Races.pick(last: string?, r: () -> number, exclude: { [string]: boolean }?): Race
	local pool = {}
	for _, race in Races.List do
		if race.Id ~= last and not (exclude and exclude[race.Id]) then
			table.insert(pool, race)
		end
	end
	if #pool == 0 then
		pool = Races.List
	end
	local i = math.clamp(math.floor(r() * #pool) + 1, 1, #pool)
	return pool[i]
end

export type Lineup = { Races: { string }, Main: string, King: string?, Rivalry: boolean }

-- Quién viene esta vez: { Races = { ids }, Main, King = id del rey o nil, Rivalry = ¿se pelean? }
-- history = { Last = id?, SinceKing = invasiones seguidas sin rey }
function Races.lineup(history: { Last: string?, SinceKing: number? }?, r: () -> number, opts: { ForceKing: boolean?, ForceRaces: number?, Race: string? }?): Lineup
	local h = history or {}
	local o = opts or {}
	local main = if o.Race and Races.ById[o.Race] then Races.ById[o.Race] else Races.pick(h.Last, r)
	local list = { main.Id }
	local used = { [main.Id] = true }
	local want = o.ForceRaces or 1
	if not o.ForceRaces then
		if r() < Races.Odds.Second then
			want = 2
			if r() < Races.Odds.Third / Races.Odds.Second then
				want = 3
			end
		end
	end
	while #list < math.min(want, #Races.List) do
		local extra = Races.pick(nil, r, used)
		used[extra.Id] = true
		table.insert(list, extra.Id)
	end
	local king = nil
	local since = h.SinceKing or 0
	if o.ForceKing or r() < Races.Odds.King or since + 1 >= Races.Odds.KingPity then
		king = main.Id
	end
	local rivalry = false
	for i = 2, #list do
		if table.find(main.Rivals, list[i]) or table.find((Races.ById[list[i]] :: Race).Rivals, main.Id) then
			rivalry = true
		end
	end
	return { Races = list, Main = main.Id, King = king, Rivalry = rivalry }
end

-- ¿Se pelean estas dos razas entre ellas? (las rivales sí; las demás se ignoran)
function Races.hostile(a: string, b: string): boolean
	if a == b then
		return false
	end
	local ra, rb = Races.ById[a], Races.ById[b]
	return (ra ~= nil and table.find(ra.Rivals, b) ~= nil) or (rb ~= nil and table.find(rb.Rivals, a) ~= nil)
end

function Races.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Nombre de una unidad de tierra de esa raza ("Grunt", "Heavy", "Ranged", "Elite")
function Races.unitName(raceId: string, kind: string): string
	local race = Races.ById[raceId]
	local u = race and race.Units[kind]
	return if u then u.Name else kind
end

-- Nombre de una nave de esa raza ("Fighter", "Drone", "Dropship")
function Races.airName(raceId: string, kind: string): string
	local race = Races.ById[raceId]
	return race and (race.Air :: any)[kind] or kind
end

-- Lista de nombres para el aviso del mundo: «Vórtidos y Mórfagos»
function Races.names(ids: { string }): string
	local names = {}
	for _, id in ids do
		local race = Races.ById[id]
		table.insert(names, if race then race.Name else id)
	end
	if #names <= 1 then
		return names[1] or ""
	end
	return table.concat(names, ", ", 1, #names - 1) .. " y " .. names[#names]
end

return Races
