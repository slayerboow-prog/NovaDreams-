-- Transform: la gente de Valmar a la que «alcanzan» los alienígenas no muere: se TRANSFORMA en un
-- ser de otra galaxia, un animal raro o una criatura (según la raza: Races.Creatures). Y el estado de
-- la ciudad después de una invasión (cuánta gente transformada, qué zonas dañadas, qué bolsas de
-- alienígenas quedan, qué servicios cerraron), que vuelve a la normalidad cuando los jugadores hacen
-- las misiones de «Recuperar la paz» (shared/Invasion/Missions) o, si nadie lo hace, sola con el tiempo
-- (Recovery: el mundo nunca se queda roto para siempre). Cuentas puras (scripts/test-invasion.luau).
--
--   * Las criaturas siguen ahí después de la invasión: unas son inofensivas (dan vueltas, hacen cosas
--     raras: el caminante de cristal tintinea, el autómata barre la acera) y otras molestan (el bicho
--     tentacular o el perro tostadora te persiguen y dan golpecitos flojos).
--   * Se curan con el INVERSOR DE FASE (Loot.Recipe, Laboratorio Xeno): acércate y «Revertir». La
--     persona vuelve, confundida y agradecida (13+: nada de sangre ni de miedo de verdad).
--   * Topes: nunca más de MaxCreatures criaturas en el servidor (las que pasan del tope se curan solas).

local Races = require(script.Parent.Races)

local Transform = {}

Transform.MaxCreatures = 24 -- en todo el servidor
Transform.PerAttack = 1 -- gente transformada por golpe que alcanza a un vecino
Transform.PerConquest = 2 -- gente transformada al caer una zona
Transform.Recovery = { Creature = { 900, 1500 }, Damage = { 300, 600 }, Pocket = { 1200, 1800 }, Service = { 240, 420 } } -- s (de-hasta) hasta que se arregla solo
Transform.HostileDamage = 3 -- lo que pica una criatura molesta
Transform.HostileRadius = 9
Transform.HostileEvery = 2.5

export type Creature = { Id: string, Race: string, Type: string, Name: string, Hostile: boolean, Pos: Vector3, Home: Vector3, Since: number, RecoverAt: number, Citizen: string }
export type Damage = { Id: string, Zone: string, Pos: Vector3, Since: number, RecoverAt: number }
export type City = {
	Creatures: { [string]: Creature },
	Damage: { [string]: Damage },
	Pockets: { [string]: { Id: string, Race: string, Pos: Vector3, Left: number, RecoverAt: number } },
	Services: { [string]: { Id: string, Name: string, RecoverAt: number } },
	Serial: number,
	Cured: number,
	Repaired: number,
}

function Transform.newCity(): City
	return { Creatures = {}, Damage = {}, Pockets = {}, Services = {}, Serial = 0, Cured = 0, Repaired = 0 }
end

local function between(range: { number }, r: number): number
	return range[1] + (range[2] - range[1]) * r
end

local function count(t: { [string]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end
Transform.count = count

-- Nombres de vecinos (quién era antes; para cuando vuelve)
Transform.Citizens = { "Marta, la del quiosco", "Don Ernesto", "Lucía, corredora", "un repartidor", "Pili, la florista", "un turista despistado", "Andrés, el del bar", "una abuela con su carrito", "Iván, estudiante", "el cartero Paco", "Nerea, paseando al perro", "un conductor de autobús" }

-- Alguien se transforma (devuelve la criatura, o nil si ya hay demasiadas)
function Transform.transform(city: City, raceId: string, pos: Vector3, now: number, r: () -> number): Creature?
	if count(city.Creatures) >= Transform.MaxCreatures then
		return nil
	end
	local race = Races.get(raceId) or Races.List[1]
	local kinds = race.Creatures
	local pick = kinds[math.clamp(math.floor(r() * #kinds) + 1, 1, #kinds)]
	city.Serial += 1
	local id = ("C%d"):format(city.Serial)
	local c: Creature = {
		Id = id,
		Race = race.Id,
		Type = pick.Id,
		Name = pick.Name,
		Hostile = pick.Hostile,
		Pos = pos,
		Home = pos,
		Since = now,
		RecoverAt = now + between(Transform.Recovery.Creature, r()),
		Citizen = Transform.Citizens[math.clamp(math.floor(r() * #Transform.Citizens) + 1, 1, #Transform.Citizens)],
	}
	city.Creatures[id] = c
	return c
end

-- Curada con el inversor de fase (o sola con el tiempo): vuelve a ser quien era
function Transform.cure(city: City, id: string): Creature?
	local c = city.Creatures[id]
	if not c then
		return nil
	end
	city.Creatures[id] = nil
	city.Cured += 1
	return c
end

function Transform.damage(city: City, zone: string, pos: Vector3, now: number, r: () -> number): Damage
	city.Serial += 1
	local id = ("D%d"):format(city.Serial)
	local d = { Id = id, Zone = zone, Pos = pos, Since = now, RecoverAt = now + between(Transform.Recovery.Damage, r()) }
	city.Damage[id] = d
	return d
end

function Transform.repair(city: City, id: string): Damage?
	local d = city.Damage[id]
	if d then
		city.Damage[id] = nil
		city.Repaired += 1
	end
	return d
end

-- Una bolsa de alienígenas que se queda atrincherada al acabar (misión «Bolsas de resistencia»)
function Transform.pocket(city: City, raceId: string, pos: Vector3, left: number, now: number, r: () -> number)
	city.Serial += 1
	local id = ("P%d"):format(city.Serial)
	city.Pockets[id] = { Id = id, Race = raceId, Pos = pos, Left = left, RecoverAt = now + between(Transform.Recovery.Pocket, r()) }
	return city.Pockets[id]
end

-- Un servicio que cerró durante la invasión (tiendas con la persiana bajada, el autobús…)
function Transform.closeService(city: City, id: string, name: string, now: number, r: () -> number)
	if not city.Services[id] then
		city.Services[id] = { Id = id, Name = name, RecoverAt = now + between(Transform.Recovery.Service, r()) }
	end
end

function Transform.reopen(city: City, id: string): boolean
	if city.Services[id] then
		city.Services[id] = nil
		return true
	end
	return false
end

-- Lo que se arregla solo con el tiempo (para que la ciudad nunca se quede rota): devuelve las listas
-- de lo que se ha recuperado { Creatures = {...}, Damage = {...}, Pockets = {...}, Services = {...} }
function Transform.recover(city: City, now: number): { [string]: { any } }
	local out = { Creatures = {}, Damage = {}, Pockets = {}, Services = {} }
	for id, c in city.Creatures do
		if now >= c.RecoverAt then
			city.Creatures[id] = nil
			table.insert(out.Creatures, c)
		end
	end
	for id, d in city.Damage do
		if now >= d.RecoverAt then
			city.Damage[id] = nil
			table.insert(out.Damage, d)
		end
	end
	for id, p in city.Pockets do
		if now >= p.RecoverAt or p.Left <= 0 then
			city.Pockets[id] = nil
			table.insert(out.Pockets, p)
		end
	end
	for id, s in city.Services do
		if now >= s.RecoverAt then
			city.Services[id] = nil
			table.insert(out.Services, s)
		end
	end
	return out
end

-- ¿Está todo en orden? (y cuánto falta, para el panel)
function Transform.summary(city: City): { Creatures: number, Damage: number, Pockets: number, Services: number, Normal: boolean }
	local s = { Creatures = count(city.Creatures), Damage = count(city.Damage), Pockets = count(city.Pockets), Services = count(city.Services), Normal = false }
	s.Normal = s.Creatures + s.Damage + s.Pockets + s.Services == 0
	return s
end

-- Lo que hace una criatura en su sitio (un paseíto raro alrededor de su casa); la molesta, si hay un
-- jugador cerca, le persigue un poco. Devuelve adónde va y si pica.
function Transform.wander(c: Creature, now: number, nearest: Vector3?): (Vector3, boolean)
	if c.Hostile and nearest and (nearest - c.Pos).Magnitude < 30 then
		local to = nearest - c.Pos
		to = Vector3.new(to.X, 0, to.Z)
		local bite = to.Magnitude <= Transform.HostileRadius
		return if to.Magnitude > 3 then c.Pos + to.Unit * 3 else c.Pos, bite
	end
	local seed = #c.Id * 1.7 + c.Since % 7
	local a = now * 0.25 + seed
	local radius = 6 + (seed % 5)
	return c.Home + Vector3.new(math.cos(a) * radius, 0, math.sin(a * 1.3) * radius), false
end

-- Lo que dice la persona al volver (nada de miedo de verdad: confusión y gracias)
Transform.Thanks = {
	"¿Eh? ¿Por qué estoy en el suelo? … ¿Y por qué me apetece tanto el agua de colonia?",
	"¡Gracias! Me sentía como un… no sé. Como una lámpara con patas.",
	"Uf. He soñado que era de cristal. Qué raro. Qué frío.",
	"¿Me he perdido algo? Creo que he ladrado. ¿He ladrado?",
	"¡Vuelvo a tener manos! Gracias, de verdad. Me voy a casa a ducharme.",
	"Recuerdo luces y un zumbido… y que tú me ayudaste. Gracias.",
}

return Transform
