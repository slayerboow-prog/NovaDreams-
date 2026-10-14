-- Missions: las misiones de la «Invasión de la Grieta» (cuentas puras; scripts/test-invasion.luau).
-- Las lleva InvasionService (sucesos del servidor, nunca del cliente) y las guarda en data.Invasion.
-- Cada misión cumplida avisa a la historia (StoryEvents «InvasionMission»: LifeStory/EventCatalog).
--
-- Tres cadenas:
--   * EVENTO («Defensa de Valmar», en cada invasión, se repite): defiende una zona, derriba naves,
--     rescata a vecinos, tumba una nave de desembarco y vence a la élite. Empieza sola al empezar la
--     invasión (estés donde estés en Valmar) y se pierde lo que no acabes al terminar.
--   * VUELO (secundarias que piden avión o nave, solo durante una invasión): «Ojos sobre la bahía»
--     (interceptar al explorador en avioneta), «Corredor de evacuación» (escoltar el vuelo que saca a
--     la gente), «La baliza nodriza» (en la nave, tumbar la baliza que guía a la flota en lo alto del
--     cielo) y «Cazadores del cielo» (derribos en el aire). Las de avioneta piden la licencia de piloto;
--     la de la nave, haber terminado la Saga 1 (como la nave: Cosmos/Access). Los testers, nada.
--   * PAZ («Recuperar la normalidad», tras una invasión que deja la ciudad tocada): muestras,
--     inversor de fase, curar a la gente transformada, reparar, limpiar las bolsas de alienígenas y
--     reabrir los servicios. Si la ciudad se arregla sola antes (Transform.recover), el paso que ya no
--     tiene nada que hacer se da por hecho (nunca te quedas atascado).

local Missions = {}

export type Step = { Id: string, Text: string, Event: string, Count: number?, Match: { [string]: any }?, City: string? }
export type Mission = {
	Id: string,
	Chain: string,
	Title: string,
	Giver: string,
	Brief: { string },
	Steps: { Step },
	Reward: { Money: number, Xp: number, Items: { [string]: number }? },
	Needs: string?, -- "Plane" | "Ship" | "Air" (avión o nave)
	Repeat: boolean?,
	Outro: string,
}

Missions.List = {
	---------------------------------------------------------------------
	-- EVENTO: Defensa de Valmar
	---------------------------------------------------------------------
	{
		Id = "Defensa",
		Chain = "Evento",
		Title = "Defensa de Valmar",
		Giver = "Comisaria Elena Robles",
		Brief = {
			"«A todas las unidades y a cualquiera que me oiga: la grieta se ha abierto y no viene sola.»",
			"«Naves sobre el centro, tropas bajando en las plazas. No sabemos qué quieren, pero no se lo vamos a dar.»",
			"«Defended las zonas, sacad a la gente y tumbad lo que vuele. Valmar no se rinde.»",
		},
		Steps = {
			{ Id = "Zona", Text = "Defiende o recupera una zona de la ciudad", Event = "ZoneDefended" },
			{ Id = "Naves", Text = "Derriba naves alienígenas", Event = "Kill", Count = 3, Match = { Air = true } },
			{ Id = "Rescate", Text = "Rescata a vecinos atrapados", Event = "Rescue", Count = 2 },
			{ Id = "Desembarco", Text = "Destruye una nave de desembarco", Event = "DropshipDown" },
			{ Id = "Elite", Text = "Vence a la élite alienígena", Event = "EliteDown" },
		},
		Reward = { Money = 600, Xp = 250, Items = { Xenita = 3 } },
		Repeat = true,
		Outro = "«Buen trabajo. Hoy Valmar sigue siendo nuestra.» — Comisaria Robles",
	},
	---------------------------------------------------------------------
	-- VUELO
	---------------------------------------------------------------------
	{
		Id = "Bahia",
		Chain = "Vuelo",
		Title = "Ojos sobre la bahía",
		Giver = "Inés Vidal, torre del aeroclub",
		Brief = {
			"«Aquí torre. Tengo un eco raro sobre la bahía: pequeño, rapidísimo y dando vueltas sobre el puerto.»",
			"«Es un explorador. Si vuelve a la grieta con lo que ha visto, la próxima oleada sabrá exactamente dónde golpear.»",
			"«Coge una avioneta (durante la invasión llevan el cañón de la patrulla costera) y no le dejes volver a casa.»",
		},
		Steps = {
			{ Id = "Despega", Text = "Despega en una avioneta", Event = "Airborne", Match = { Via = "Plane" } },
			{ Id = "Explorador", Text = "Derriba al explorador sobre la bahía", Event = "ScoutDown", Match = { Via = "Plane" } },
		},
		Reward = { Money = 900, Xp = 320, Items = { AleacionEstelar = 1 } },
		Needs = "Plane",
		Repeat = true,
		Outro = "«Eco perdido. Lo has tumbado. Sin ojos, la flota va a ciegas. Vuelve a casa, piloto.» — Inés",
	},
	{
		Id = "Evacuacion",
		Chain = "Vuelo",
		Title = "Corredor de evacuación",
		Giver = "Inés Vidal, torre del aeroclub",
		Brief = {
			"«El vuelo de evacuación EV-01 sale ahora con cuarenta personas del hospital: niños, mayores y el turno de noche.»",
			"«Va despacio y no lleva nada para defenderse. Los cazas alienígenas lo han visto.»",
			"«Vuela a su lado hasta que salga del corredor. Si se le acerca algo, que se encuentre contigo primero.»",
		},
		Steps = {
			{ Id = "Despega", Text = "Despega en una avioneta", Event = "Airborne", Match = { Via = "Plane" } },
			{ Id = "Escolta", Text = "Escolta el vuelo de evacuación hasta que salga del corredor", Event = "EscortDone" },
		},
		Reward = { Money = 1000, Xp = 360, Items = { NucleoPlasma = 1 } },
		Needs = "Plane",
		Repeat = true,
		Outro = "«Aquí el EV-01: corredor despejado. De parte de los cuarenta de a bordo: gracias.»",
	},
	{
		Id = "Baliza",
		Chain = "Vuelo",
		Title = "La baliza nodriza",
		Giver = "Capitana Nadia Okafor, Estación Alba",
		Brief = {
			"«Desde aquí arriba lo vemos claro: hay una baliza en lo alto del cielo de Valmar, justo bajo la capa de los aviones.»",
			"«Es un faro: guía a la flota a través de la grieta. Mientras emita, seguirán llegando.»",
			"«Las naves tenéis permiso para bajar al cielo de la ciudad mientras dure la invasión. Bájala.»",
		},
		Steps = {
			{ Id = "Nave", Text = "Sube a tu nave en el puerto espacial", Event = "Airborne", Match = { Via = "Ship" } },
			{ Id = "Baliza", Text = "Destruye la baliza nodriza con la nave", Event = "BeaconDown", Match = { Via = "Ship" } },
		},
		Reward = { Money = 1200, Xp = 420, Items = { PiezaEscudo = 1 } },
		Needs = "Ship",
		Repeat = true,
		Outro = "«Señal perdida. La flota se ha quedado sin faro. Alba, cambio y corto… con una sonrisa.» — Capitana Okafor",
	},
	{
		Id = "Cazadores",
		Chain = "Vuelo",
		Title = "Cazadores del cielo",
		Giver = "Inés Vidal, torre del aeroclub",
		Brief = {
			"«El cielo de Valmar es de los aviones. Que se enteren.»",
			"«Cinco derribos desde el aire, en avioneta o en nave. Ni uno menos.»",
		},
		Steps = {
			{ Id = "Derribos", Text = "Derriba naves desde el aire (avioneta o nave)", Event = "Kill", Count = 5, Match = { Air = true, Airborne = true } },
		},
		Reward = { Money = 800, Xp = 300, Items = { Xenita = 4 } },
		Needs = "Air",
		Repeat = true,
		Outro = "«Cinco. Te voy a pintar una estrellita en la torre.» — Inés",
	},
	---------------------------------------------------------------------
	-- PAZ: Recuperar la normalidad
	---------------------------------------------------------------------
	{
		Id = "Normalidad",
		Chain = "Paz",
		Title = "Recuperar la normalidad",
		Giver = "Doctora Sofía Arenas, Laboratorio Xeno",
		Brief = {
			"«Nadie ha muerto. Repito: nadie. Los que tocaron esas cosas se han… transformado. Siguen siendo ellos, ahí dentro.»",
			"«He montado un laboratorio junto al hospital. Con muestras de los alienígenas puedo fabricar un inversor de fase.»",
			"«Luego hay que arreglar lo roto, limpiar lo que quede y abrir las persianas. Valmar tiene que volver a ser Valmar.»",
		},
		Steps = {
			{ Id = "Muestras", Text = "Consigue 3 muestras alienígenas (criaturas o alienígenas)", Event = "Sample", Count = 3 },
			{ Id = "Inversor", Text = "Fabrica un inversor de fase en el Laboratorio Xeno", Event = "Crafted" },
			{ Id = "Curar", Text = "Devuelve su forma a 2 vecinos transformados", Event = "Cured", Count = 2, City = "Creatures" },
			{ Id = "Reparar", Text = "Repara 3 destrozos de la invasión", Event = "Repaired", Count = 3, City = "Damage" },
			{ Id = "Bolsas", Text = "Limpia una bolsa de alienígenas atrincherados", Event = "PocketCleared", City = "Pockets" },
			{ Id = "Abrir", Text = "Ayuda a reabrir 2 servicios (tiendas, paradas)", Event = "Reopened", Count = 2, City = "Services" },
		},
		Reward = { Money = 1500, Xp = 600, Items = { RelojLunas = 1 } },
		Outro = "«Mira la calle: gente paseando, el quiosco abierto, alguien quejándose del autobús. Eso es Valmar.» — Doctora Arenas",
	},
} :: { Mission }

Missions.ById = {} :: { [string]: Mission }
for _, m in Missions.List do
	Missions.ById[m.Id] = m
end

function Missions.get(id: string?): Mission?
	return if id then Missions.ById[id] else nil
end

-- ¿Encaja el suceso con lo que pide el paso?
local function matches(step: Step, name: string, payload: { [string]: any }): boolean
	if step.Event ~= name then
		return false
	end
	for k, v in step.Match or {} do
		if payload[k] ~= v then
			return false
		end
	end
	return true
end
Missions.matches = matches

export type Prog = { Step: number, Count: number, Started: number }
export type Book = { Active: { [string]: Prog }, Done: { [string]: number } }

function Missions.newBook(): Book
	return { Active = {}, Done = {} }
end

-- Arreglar un libro guardado (partidas viejas o datos rotos)
function Missions.sanitize(book: any): Book
	local b = if type(book) == "table" then book else {}
	if type(b.Active) ~= "table" then
		b.Active = {}
	end
	if type(b.Done) ~= "table" then
		b.Done = {}
	end
	for id, p in b.Active do
		if not Missions.ById[id] or type(p) ~= "table" or type(p.Step) ~= "number" then
			b.Active[id] = nil
		else
			p.Count = tonumber(p.Count) or 0
		end
	end
	return b
end

-- ¿Puede coger esta misión? who = { Pilot = licencia o tester, ShipOk = Saga 1 o tester, Invasion = hay
-- invasión, CityNormal = la ciudad está bien }
function Missions.canStart(book: Book, id: string, who: { [string]: any }): (boolean, string?)
	local m = Missions.ById[id]
	if not m then
		return false, "Esa misión no existe."
	end
	if book.Active[id] then
		return false, "Ya la estás haciendo."
	end
	if not m.Repeat and (book.Done[id] or 0) > 0 then
		return false, "Ya la terminaste."
	end
	if (m.Chain == "Evento" or m.Chain == "Vuelo") and not who.Invasion then
		return false, "Solo durante una invasión."
	end
	if m.Chain == "Paz" and who.CityNormal and not who.Tester then
		return false, "La ciudad está tranquila: no hay nada que recuperar."
	end
	if m.Needs == "Plane" and not who.Pilot then
		return false, "Necesitas la licencia de piloto (aeroclub del aeropuerto)."
	elseif m.Needs == "Ship" and not who.ShipOk then
		return false, "La nave abre al terminar la Saga 1."
	elseif m.Needs == "Air" and not (who.Pilot or who.ShipOk) then
		return false, "Necesitas la licencia de piloto o una nave."
	end
	return true, nil
end

function Missions.start(book: Book, id: string, now: number): Prog
	local p = { Step = 1, Count = 0, Started = now }
	book.Active[id] = p
	return p
end

-- Un suceso. Devuelve lo que ha pasado: { { Id, Kind = "Step" | "Done" | "Count", Step } }
function Missions.event(book: Book, name: string, payload: { [string]: any }?): { { [string]: any } }
	local out = {}
	local data = payload or {}
	for id, p in book.Active do
		local m = Missions.ById[id]
		local step = m and m.Steps[p.Step]
		if step and matches(step, name, data) then
			p.Count += (tonumber(data.Amount) or 1)
			if p.Count >= (step.Count or 1) then
				p.Step += 1
				p.Count = 0
				if p.Step > #m.Steps then
					book.Active[id] = nil
					book.Done[id] = (book.Done[id] or 0) + 1
					table.insert(out, { Id = id, Kind = "Done" })
				else
					table.insert(out, { Id = id, Kind = "Step", Step = p.Step })
				end
			else
				table.insert(out, { Id = id, Kind = "Count", Step = p.Step })
			end
		end
	end
	return out
end

-- Los pasos de PAZ que ya no tienen nada que hacer (la ciudad se ha arreglado sola) se dan por hechos
-- summary = Transform.summary(city)
function Missions.autoSkip(book: Book, summary: { [string]: any }): { { [string]: any } }
	local out = {}
	for id, p in book.Active do
		local m = Missions.ById[id]
		local step = m and m.Steps[p.Step]
		while m and step and step.City and (summary[step.City] or 0) == 0 do
			p.Step += 1
			p.Count = 0
			if p.Step > #m.Steps then
				book.Active[id] = nil
				book.Done[id] = (book.Done[id] or 0) + 1
				table.insert(out, { Id = id, Kind = "Done", Skipped = true })
				break
			end
			table.insert(out, { Id = id, Kind = "Step", Step = p.Step, Skipped = true })
			step = m.Steps[p.Step]
		end
	end
	return out
end

-- Al acabar la invasión: las del evento y las de vuelo que no se terminaron se pierden
function Missions.endInvasion(book: Book): { string }
	local lost = {}
	for id in book.Active do
		local m = Missions.ById[id]
		if m and (m.Chain == "Evento" or m.Chain == "Vuelo") then
			book.Active[id] = nil
			table.insert(lost, id)
		end
	end
	return lost
end

-- Texto del paso actual (para el panel): "Derriba naves alienígenas (1/3)"
function Missions.stepText(id: string, p: Prog?): string
	local m = Missions.ById[id]
	if not m or not p then
		return ""
	end
	local step = m.Steps[p.Step]
	if not step then
		return "¡Completada!"
	end
	if (step.Count or 1) > 1 then
		return ("%s (%d/%d)"):format(step.Text, p.Count, step.Count)
	end
	return step.Text
end

return Missions
