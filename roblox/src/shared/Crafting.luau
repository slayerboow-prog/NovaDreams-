-- Crafting: FABRICAR cosas con lo que consigues (al estilo Minecraft). Cuentas puras: lo usan
-- Services/CraftingService (el Taller: comprueba, gasta y da; pociones y armaduras), Services/BeastService
-- (el daño de las armas blancas y la armadura contra las bestias), shared/Items (los objetos nuevos),
-- Controllers/CraftingUI (el libro de recetas) y las pruebas (scripts/test-crafting.luau).
--
--   * Materiales: lo que sueltan las bestias (cuero, colmillo, quitina, escama, glándula, hueso, seda), el
--     material raro de cada planeta, los trofeos de los jefes, los minerales (hierro, cobalto, cristal y
--     obsidiana: valen los de la mochila y los de la bodega de tu nave) y los materiales de las misiones.
--   * Bancos: «Mesa» (lo básico: también la mesa plegable, en cualquier sitio), «Forja» (armas y
--     armaduras) y «Alquimia» (pociones fuertes). Los Talleres de las ciudades de los planetas tienen los tres.
--   * Niveles (diseño de los mundos §2.2): 1 Chatarra · 2 Común · 3 Refinado · 4 Raro · 5 Reliquia.
--   * Armaduras: la mejor que lleves en la mochila te protege sola (Defense: parte del daño que no te llega
--     de bestias y enemigos de misión). Armas blancas: la mejor que lleves pega más fuerte a las bestias
--     (Blade: +% a tus golpes). Pociones: se usan desde la mochila.

local Crafting = {}

-- Minerales: se cuentan los de la mochila y los de la bodega de la nave (data.Space.Ore)
Crafting.Ores = { Hierro = true, Cobalto = true, Cristal = true, Obsidiana = true }

Crafting.Levels = { "Chatarra", "Común", "Refinado", "Raro", "Reliquia" }
Crafting.Benches = {
	Mesa = { Name = "Mesa de trabajo", Icon = "🧰" },
	Forja = { Name = "Forja", Icon = "🔨" },
	Alquimia = { Name = "Alquimia", Icon = "⚗️" },
}
Crafting.Categories = { "Armas", "Armaduras", "Pociones", "Herramientas", "Munición", "Materiales" }

-- { Id, Nombre, Icono, Descripción }
Crafting.Materials = {
	-- de las bestias (todos los planetas)
	{ "Cuero", "Cuero de bestia", "🐾", "Piel curtida de una bestia de los planetas. Para armaduras ligeras y correas." },
	{ "Colmillo", "Colmillo", "🦷", "Afilado y duro como el acero. Para cuchillos y puntas de lanza." },
	{ "Quitina", "Placa de quitina", "🐞", "El caparazón de un insecto grande. Ligera y dura: armaduras." },
	{ "Escama", "Escama", "🐉", "Escamas de reptil que aguantan golpes, fuego y frío." },
	{ "Glandula", "Glándula", "🧫", "Lo que hace que una bestia escupa, pique o brille. Base de casi todas las pociones." },
	{ "Hueso", "Hueso grande", "🦴", "Hueso de bestia: mangos, empuñaduras y armaduras pesadas." },
	{ "Seda", "Seda de bestia", "🧵", "Hilo de araña o de avispa. Más fuerte que el acero si lo trenzas bien." },
	-- el material raro de cada planeta
	{ "BrasaViva", "Brasa viva", "🔥", "Un trozo de colada que nunca se enfría (Tefra). Para armas que queman." },
	{ "VidrioTormenta", "Vidrio de tormenta", "🔷", "Arena fundida por los rayos de las tormentas de Siroco." },
	{ "NacarAbisal", "Nácar abisal", "🐚", "El nácar de las Fosas de Tálasa: brilla solo en la oscuridad." },
	{ "HieloEterno", "Hielo eterno", "🧊", "Hielo de Nivalis que no se derrite ni al fuego." },
	{ "SaviaAmbar", "Savia ámbar", "🍯", "La savia de los árboles gigantes de Umbría. Cura y pega." },
	{ "PlataRayo", "Plata de rayo", "⚡", "Plata cargada por los rayos de Miasma. Pica al tocarla." },
	{ "ChipUsado", "Chip usado", "💾", "Un chip de Vértice que todavía guarda algo. Para aparatos." },
	-- los trofeos de los jefes escondidos
	{ "NucleoBrasa", "Núcleo de la Bestia de Brasa", "💠", "Late como un corazón. Trofeo de Tefra." },
	{ "AguijonRey", "Aguijón del Rey Escorpión", "🦂", "Todavía gotea. Trofeo de Siroco." },
	{ "PerlaLeviatan", "Perla del Leviatán", "⚪", "Del tamaño de un puño. Trofeo de Tálasa." },
	{ "CorazonHielo", "Corazón de hielo", "💙", "Frío como el espacio. Trofeo de Nivalis." },
	{ "CuernoEscarabajo", "Cuerno del Gran Escarabajo", "🌿", "Más duro que cualquier metal. Trofeo de Umbría." },
	{ "OjoTormenta", "Ojo de la tormenta", "🌀", "Dentro se ve un remolino. Trofeo de Miasma." },
	{ "PlacaRecaudador", "Placa del Recaudador", "🔩", "Con un número de serie borrado a arañazos. Trofeo de Vértice." },
	-- intermedios que se fabrican
	{ "LingoteHierro", "Lingote de hierro", "🧱", "Hierro fundido y limpio: la base de la Forja." },
	{ "LingoteCobalto", "Lingote de cobalto", "🟦", "Cobalto fundido: más ligero y más duro que el hierro." },
	{ "CuerdaTrenzada", "Cuerda trenzada", "🧶", "Seda y cuero trenzados. Para mangos, arcos y correas." },
	{ "Polvora", "Pólvora casera", "🧂", "Glándula seca y molida con azufre. Para hacer munición." },
}

-- Los objetos que se fabrican (Kind de shared/Items): armaduras (Armor), armas blancas (Blade), pociones
-- (Potion) y herramientas (Tool). Defense: 0..1 · Blade: +% de daño a las bestias
Crafting.Gear = {
	-- Armaduras
	{ Id = "ArmaduraCuero", Name = "Armadura de cuero", Icon = "🦺", Kind = "Armor", Defense = 0.12, Level = 1, Desc = "Llevándola en la mochila, las bestias te hacen un 12 % menos de daño." },
	{ Id = "ArmaduraQuitina", Name = "Armadura de quitina", Icon = "🛡", Kind = "Armor", Defense = 0.22, Level = 2, Desc = "Placas de insecto cosidas sobre cuero: un 22 % menos de daño." },
	{ Id = "ArmaduraEscamas", Name = "Cota de escamas", Icon = "🛡", Kind = "Armor", Defense = 0.3, Level = 3, Desc = "Escamas sobre una malla de cobalto: un 30 % menos de daño." },
	{ Id = "ArmaduraHueso", Name = "Armadura de hueso y hierro", Icon = "🛡", Kind = "Armor", Defense = 0.36, Level = 3, Desc = "Pesada, pero nada la atraviesa fácil: un 36 % menos de daño." },
	{ Id = "ArmaduraPlanetaria", Name = "Armadura de explorador", Icon = "🧥", Kind = "Armor", Defense = 0.44, Level = 4, Desc = "Con los materiales raros de tres planetas: un 44 % menos de daño." },
	{ Id = "ArmaduraTrofeo", Name = "Armadura de cazador de jefes", Icon = "👑", Kind = "Armor", Defense = 0.55, Level = 5, Desc = "Hecha con trofeos de jefes. Quien la ve sabe lo que has hecho: un 55 % menos de daño." },
	-- Armas blancas (contra las bestias)
	{ Id = "CuchilloColmillo", Name = "Cuchillo de colmillo", Icon = "🔪", Kind = "Blade", Blade = 0.25, Level = 1, Desc = "Llevándolo en la mochila, tus golpes a las bestias hacen un 25 % más." },
	{ Id = "HachaHueso", Name = "Hacha de hueso", Icon = "🪓", Kind = "Blade", Blade = 0.45, Level = 2, Desc = "Pesada y fea, pero corta: +45 % a tus golpes contra las bestias." },
	{ Id = "LanzaEscama", Name = "Lanza de escama", Icon = "🔱", Kind = "Blade", Blade = 0.65, Level = 3, Desc = "Punta de escama y mango de cobalto: +65 % contra las bestias." },
	{ Id = "EspadaCristal", Name = "Espada de cristal solar", Icon = "⚔️", Kind = "Blade", Blade = 0.9, Level = 4, Desc = "Brilla un poco al golpear: +90 % contra las bestias." },
	{ Id = "EspadaTrofeo", Name = "Hoja de los jefes", Icon = "🗡", Kind = "Blade", Blade = 1.3, Level = 5, Desc = "Forjada con trofeos de jefe: +130 % contra las bestias." },
	-- Pociones
	{ Id = "PocionCuracion", Name = "Poción de curación", Icon = "🧪", Kind = "Potion", Effect = "Heal", Amount = 50, Level = 1, Desc = "Úsala desde la mochila: te cura 50 de vida al momento." },
	{ Id = "PocionRegeneracion", Name = "Poción de regeneración", Icon = "💚", Kind = "Potion", Effect = "Regen", Amount = 4, Seconds = 25, Level = 2, Desc = "Te cura 4 de vida por segundo durante 25 segundos." },
	{ Id = "PocionFuerza", Name = "Poción de fuerza", Icon = "💪", Kind = "Potion", Effect = "Strength", Amount = 0.5, Seconds = 90, Level = 2, Desc = "Durante 90 segundos tus golpes a las bestias hacen un 50 % más." },
	{ Id = "PocionPiedra", Name = "Poción de piel de piedra", Icon = "🗿", Kind = "Potion", Effect = "Stone", Amount = 0.25, Seconds = 90, Level = 3, Desc = "Durante 90 segundos recibes un 25 % menos de daño (además de tu armadura)." },
	{ Id = "PocionVelocidad", Name = "Poción de velocidad", Icon = "💨", Kind = "Potion", Effect = "Speed", Amount = 8, Seconds = 60, Level = 2, Desc = "Durante un minuto corres bastante más." },
	{ Id = "TonicoEntorno", Name = "Tónico de entorno", Icon = "🌡", Kind = "Potion", Effect = "Hazard", Amount = 50, Level = 3, Desc = "Baja a la mitad el medidor de la desventaja del planeta (calor, sed, frío, esporas, toxinas…)." },
	-- Herramientas
	{ Id = "MesaPlegable", Name = "Mesa de trabajo plegable", Icon = "🧰", Kind = "Tool", Effect = "Bench", Level = 1, Desc = "Úsala desde la mochila para fabricar lo básico (recetas de Mesa) en cualquier sitio. No se gasta." },
	{ Id = "BrujulaBestias", Name = "Brújula de bestias", Icon = "🧭", Kind = "Tool", Effect = "Compass", Level = 2, Desc = "Úsala en un planeta: te dice hacia dónde está la guarida más cercana y si el jefe anda cerca. No se gasta." },
	{ Id = "Ganzua", Name = "Ganzúa de explorador", Icon = "🗝", Kind = "Tool", Effect = "Picklock", Level = 2, Desc = "Con ella en la mochila, los alijos escondidos te dan el doble de dinero." },
}

-- Recetas. Bench: Mesa | Forja | Alquimia. Needs: { [objeto] = cantidad }
Crafting.Recipes = {
	-- Materiales intermedios
	{ Id = "LingoteHierro", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 1, Needs = { Hierro = 3 } },
	{ Id = "LingoteCobalto", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 2, Needs = { Cobalto = 3 } },
	{ Id = "CuerdaTrenzada", Makes = 2, Bench = "Mesa", Category = "Materiales", Level = 1, Needs = { Seda = 2, Cuero = 1 } },
	{ Id = "Polvora", Makes = 2, Bench = "Alquimia", Category = "Materiales", Level = 1, Needs = { Glandula = 1, Hueso = 1 } },
	-- Armas blancas
	{ Id = "CuchilloColmillo", Makes = 1, Bench = "Mesa", Category = "Armas", Level = 1, Needs = { Colmillo = 2, Cuero = 1 } },
	{ Id = "HachaHueso", Makes = 1, Bench = "Forja", Category = "Armas", Level = 2, Needs = { Hueso = 3, LingoteHierro = 1, CuerdaTrenzada = 1 } },
	{ Id = "LanzaEscama", Makes = 1, Bench = "Forja", Category = "Armas", Level = 3, Needs = { Escama = 4, LingoteCobalto = 2, CuerdaTrenzada = 1 } },
	{ Id = "EspadaCristal", Makes = 1, Bench = "Forja", Category = "Armas", Level = 4, Needs = { Cristal = 3, LingoteCobalto = 2, Colmillo = 3, VidrioTormenta = 1 } },
	{ Id = "EspadaTrofeo", Makes = 1, Bench = "Forja", Category = "Armas", Level = 5, Needs = { NucleoBrasa = 1, AguijonRey = 1, LingoteCobalto = 3, Cristal = 2 } },
	-- Armas de fuego (para quien tenga la licencia: se usan igual que las de la Armería)
	{ Id = "Arma_Pistola", Makes = 1, Bench = "Forja", Category = "Armas", Level = 2, Needs = { LingoteHierro = 3, Hueso = 1, Polvora = 2 } },
	{ Id = "Arma_Escopeta", Makes = 1, Bench = "Forja", Category = "Armas", Level = 3, Needs = { LingoteHierro = 4, LingoteCobalto = 1, Hueso = 2, Polvora = 3 } },
	{ Id = "Arma_Fusil", Makes = 1, Bench = "Forja", Category = "Armas", Level = 4, Needs = { LingoteCobalto = 4, ChipUsado = 1, Polvora = 4, Escama = 2 } },
	-- Munición
	{ Id = "Municion_9mm", Makes = 15, Bench = "Forja", Category = "Munición", Level = 1, Needs = { Polvora = 1, Hierro = 1 } },
	{ Id = "Cartuchos_12", Makes = 8, Bench = "Forja", Category = "Munición", Level = 2, Needs = { Polvora = 1, Hierro = 2 } },
	{ Id = "Municion_556", Makes = 20, Bench = "Forja", Category = "Munición", Level = 3, Needs = { Polvora = 2, Cobalto = 1 } },
	-- Armaduras
	{ Id = "ArmaduraCuero", Makes = 1, Bench = "Mesa", Category = "Armaduras", Level = 1, Needs = { Cuero = 5 } },
	{ Id = "ArmaduraQuitina", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 2, Needs = { Quitina = 5, Cuero = 2, CuerdaTrenzada = 1 } },
	{ Id = "ArmaduraEscamas", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 3, Needs = { Escama = 6, LingoteCobalto = 2 } },
	{ Id = "ArmaduraHueso", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 3, Needs = { Hueso = 6, LingoteHierro = 3, Cuero = 2 } },
	{ Id = "ArmaduraPlanetaria", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 4, Needs = { HieloEterno = 2, NacarAbisal = 2, SaviaAmbar = 2, LingoteCobalto = 3 } },
	{ Id = "ArmaduraTrofeo", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 5, Needs = { CorazonHielo = 1, PerlaLeviatan = 1, CuernoEscarabajo = 1, PlacaRecaudador = 1, OjoTormenta = 1 } },
	-- Pociones
	{ Id = "PocionCuracion", Makes = 2, Bench = "Mesa", Category = "Pociones", Level = 1, Needs = { Glandula = 1, SaviaAmbar = 0 } },
	{ Id = "PocionRegeneracion", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 2, SaviaAmbar = 1 } },
	{ Id = "PocionFuerza", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 1, Colmillo = 1, BrasaViva = 1 } },
	{ Id = "PocionPiedra", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 3, Needs = { Glandula = 1, Escama = 2, HieloEterno = 1 } },
	{ Id = "PocionVelocidad", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 1, Seda = 1, PlataRayo = 1 } },
	{ Id = "TonicoEntorno", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 3, Needs = { Glandula = 2, NacarAbisal = 1 } },
	-- Herramientas
	{ Id = "MesaPlegable", Makes = 1, Bench = "Mesa", Category = "Herramientas", Level = 1, Needs = { Hierro = 4, Cuero = 2 } },
	{ Id = "BrujulaBestias", Makes = 1, Bench = "Mesa", Category = "Herramientas", Level = 2, Needs = { Hierro = 2, Glandula = 1, ChipUsado = 1 } },
	{ Id = "Ganzua", Makes = 1, Bench = "Forja", Category = "Herramientas", Level = 2, Needs = { LingoteHierro = 1, Colmillo = 1 } },
}

-- (cantidad 0 = no hace falta: se limpia aquí para que las recetas queden como se leen)
for _, r in Crafting.Recipes do
	for k, v in r.Needs do
		if v <= 0 then
			r.Needs[k] = nil
		end
	end
end

local byId: { [string]: { [string]: any } } = {}
for _, r in Crafting.Recipes do
	byId[r.Id] = r
end
local gearById: { [string]: { [string]: any } } = {}
for _, g in Crafting.Gear do
	gearById[g.Id] = g
end

function Crafting.recipe(id: string): { [string]: any }?
	return byId[id]
end
function Crafting.gear(id: string): { [string]: any }?
	return gearById[id]
end

-- ¿Se puede hacer en este banco? (los Talleres de las ciudades tienen todos: bench = "Taller")
function Crafting.benchHas(bench: string, recipe: { [string]: any }): boolean
	return bench == "Taller" or bench == recipe.Bench
end

-- Cuántas veces se puede fabricar con lo que hay (have: { [objeto] = cantidad })
function Crafting.times(recipe: { [string]: any }, have: { [string]: number }): number
	local n = math.huge
	for item, need in recipe.Needs do
		n = math.min(n, math.floor((have[item] or 0) / need))
	end
	return if n == math.huge then 0 else n
end

-- Lo que falta: { { Item, Have, Need } }
function Crafting.missing(recipe: { [string]: any }, have: { [string]: number }): { { any } }
	local out = {}
	for item, need in recipe.Needs do
		local h = have[item] or 0
		if h < need then
			table.insert(out, { item, h, need })
		end
	end
	table.sort(out, function(a, b)
		return a[1] < b[1]
	end)
	return out
end

-- Lo que hay para fabricar: la mochila + (minerales) la bodega de la nave
function Crafting.have(data: { [string]: any }): { [string]: number }
	local out: { [string]: number } = {}
	for id, n in data.Items or {} do
		if type(n) == "number" and n > 0 then
			out[id] = n
		end
	end
	local ore = data.Space and data.Space.Ore
	if type(ore) == "table" then
		for id in Crafting.Ores do
			local n = tonumber(ore[id])
			if n and n > 0 then
				out[id] = (out[id] or 0) + n
			end
		end
	end
	return out
end

-- La mejor armadura y la mejor arma blanca que lleva alguien (items: data.Items)
function Crafting.defenseOf(items: { [string]: number }?): number
	local best = 0
	for id, n in items or {} do
		local g = gearById[id]
		if g and g.Kind == "Armor" and type(n) == "number" and n > 0 then
			best = math.max(best, g.Defense)
		end
	end
	return best
end
function Crafting.bladeOf(items: { [string]: number }?): number
	local best = 0
	for id, n in items or {} do
		local g = gearById[id]
		if g and g.Kind == "Blade" and type(n) == "number" and n > 0 then
			best = math.max(best, g.Blade)
		end
	end
	return best
end

-- El daño que te llega de una bestia (armadura + piel de piedra, nunca menos del 25 %)
function Crafting.damageTaken(amount: number, defense: number, stone: number?): number
	local k = math.clamp(1 - defense - (stone or 0), 0.25, 1)
	return math.max(1, math.floor(amount * k + 0.5))
end

return Crafting
