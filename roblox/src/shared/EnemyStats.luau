-- EnemyStats: la vida por puntos de los enemigos de las misiones (pasos Fight) y lo que hace cada
-- cosa que les da. Datos y cuentas puras (sin servicios): lo usan DamageService y LifeStoryService
-- (servidor), Controllers/HealthBars (cliente) y scripts/test-damage.luau.
--
-- Reglas:
--   * Cada enemigo tiene MaxHealth y Health (en el servidor; el cliente los ve en los atributos
--     EnemyMaxHealth / EnemyHealth del modelo). Al llegar a 0 CAE: se cae al suelo, se desvanece y
--     cuenta para la misión. El paso Fight se completa cuando han caído todos.
--   * Las misiones de antes decían «HP = N golpes». Un golpe de entonces vale HitDamage puntos: la
--     vida es N × HitDamage y el botón de atacar (globo de agua, rayo, aguja…) quita HitDamage, así
--     que con el botón el combate dura lo mismo que antes. Un enemigo puede llevar su propia vida en
--     puntos (Health = 180) y, si no dice nada, usa la de su tipo (Types).
--   * Cada bala quita lo de su arma (Weapons.damageAt: cabeza, brazos/piernas y distancia). Las
--     armas de juguete (pistola de agua, paintball) no hacen daño a las personas (Damage = 0), pero
--     sí a los enemigos de misión «de juguete» (Toy: las cucarachas, Petra, los electrodomésticos…).
--   * Cuerpo a cuerpo y lo que se lanza (piedras) tienen su propio daño (Sources).
--   * Cuando te atrapa un enemigo te quita su Damage. Si te quedas sin vida en un combate de misión,
--     caes en combate y, a los PlayerFallSeconds, el combate vuelve a empezar desde el principio del
--     paso (la misión no se pierde).

local EnemyStats = {}

EnemyStats.HitDamage = 25 -- un «golpe» de las misiones de antes (HP = N golpes -> N × 25 de vida)
EnemyStats.MaxPerHit = 400 -- tope de daño de un solo impacto (nadie manda daño de mentira)
EnemyStats.FallSeconds = 2.2 -- el enemigo caído se queda en el suelo esto antes de desvanecerse
EnemyStats.PlayerFallSeconds = 6 -- tú, caído en combate, antes de reintentar el paso

-- Daño de lo que no es una bala
EnemyStats.Sources = {
	Attack = 25, -- el botón de atacar de la misión (globo de agua, rayo, aguja, desenchufar…)
	Gadget = 25, -- el arma de la misión desde la barra (rayo encogedor)
	Melee = 20, -- puñetazo / patada
	MeleeHeavy = 35, -- golpe fuerte o cargado
	Stone = 25, -- piedra lanzada
}

-- Armas de juguete contra enemigos «de juguete» (por gota / por bola: Weapons.Damage es 0)
EnemyStats.ToyDamage = {
	PistolaAgua = 10, -- 8 disparos por segundo
	Paintball = 22,
}

export type EnemyType = {
	Health: number, -- vida si la misión no dice nada (puntos)
	Damage: number, -- lo que te quita cuando te atrapa
	Toy: boolean, -- ¿le hacen daño las armas de juguete?
	Boss: boolean?,
	Name: string,
}

-- Tipos de enemigo (poca vida los bichos, mucha los jefes)
EnemyStats.Types = {
	Cucaracha = { Name = "Cucaracha espacial", Health = 50, Damage = 8, Toy = true },
	GallinaGigante = { Name = "Gallina gigante", Health = 125, Damage = 18, Toy = true, Boss = true },
	Alien = { Name = "Alienígena", Health = 75, Damage = 10, Toy = true },
	Electrodomestico = { Name = "Electrodoméstico rebelde", Health = 75, Damage = 10, Toy = true },
	Robot = { Name = "Robot", Health = 110, Damage = 12, Toy = false },
	Dron = { Name = "Dron", Health = 90, Damage = 10, Toy = false },
	Paloma = { Name = "Paloma robot", Health = 60, Damage = 8, Toy = true },
	Monstruo = { Name = "Monstruo", Health = 175, Damage = 15, Toy = true, Boss = true },
	Jefe = { Name = "Jefe", Health = 200, Damage = 15, Toy = false, Boss = true },
	Persona = { Name = "Rival", Health = 75, Damage = 8, Toy = true },
	Default = { Name = "Enemigo", Health = 75, Damage = 10, Toy = true },
} :: { [string]: EnemyType }

-- De qué tipo es cada enemigo de las misiones (por su id sin el número: Cucaracha3 -> Cucaracha)
EnemyStats.KindOf = {
	Cucaracha = "Cucaracha",
	PolloGigante = "GallinaGigante",
	Blorp = "Alien", Zarg = "Alien", CapitanNoz = "Jefe", Plof = "Alien", Glub = "Alien",
	Cafetera = "Electrodomestico", Batidora = "Electrodomestico", Aspiradora = "Electrodomestico", Microondas = "Electrodomestico",
	RobotSeguridad = "Robot", DronCosimo = "Dron", PalomaRobot = "Paloma",
	CalcetinMonstruo = "Monstruo", DonPinzas = "Monstruo", Hilacha = "Monstruo", Lapiz = "Monstruo",
	Cosimo = "Jefe", DJZumbido = "Jefe", TuMalvado = "Jefe",
	Fan = "Persona", Seguidor = "Persona", Gnomo = "Persona", Impostor = "Persona", Clon = "Persona",
}
-- Por el cuerpo (Cast.People[npc].Body), si lo tiene
EnemyStats.KindOfBody = { Cucaracha = "Cucaracha", GallinaGigante = "GallinaGigante" }

function EnemyStats.kindOf(npc: string?, body: string?): string
	if body and EnemyStats.KindOfBody[body] then
		return EnemyStats.KindOfBody[body]
	end
	if type(npc) ~= "string" then
		return "Default"
	end
	local base = string.gsub(npc, "%d+$", "")
	return EnemyStats.KindOf[base] or "Default"
end

function EnemyStats.typeOf(npc: string?, body: string?): EnemyType
	return EnemyStats.Types[EnemyStats.kindOf(npc, body)] or EnemyStats.Types.Default
end

-- Vida máxima de un enemigo de un paso Fight: la suya en puntos (Health), la de los golpes de antes
-- (HP del enemigo o del paso × HitDamage) o la de su tipo
function EnemyStats.maxHealth(enemy: { [string]: any }, step: { [string]: any }?, body: string?): number
	if type(enemy.Health) == "number" and enemy.Health > 0 then
		return math.floor(enemy.Health)
	end
	local hits = enemy.HP or (step and step.HP)
	if type(hits) == "number" and hits > 0 then
		return math.floor(hits * EnemyStats.HitDamage + 0.5)
	end
	return EnemyStats.typeOf(enemy.Npc, body).Health
end

-- Lo que te quita al atraparte
function EnemyStats.damageToPlayer(enemy: { [string]: any }, body: string?): number
	if type(enemy.Damage) == "number" then
		return math.max(0, enemy.Damage)
	end
	return EnemyStats.typeOf(enemy.Npc, body).Damage
end

-- ¿Le hacen daño las armas de juguete?
function EnemyStats.toyHurts(enemy: { [string]: any }, body: string?): boolean
	if type(enemy.Toy) == "boolean" then
		return enemy.Toy
	end
	return EnemyStats.typeOf(enemy.Npc, body).Toy
end

-- Daño que llega a un enemigo de misión. kind: "Bullet" (amount = Weapons.damageAt), "Toy"
-- (weaponId: la de juguete), "Attack", "Gadget", "Melee", "MeleeHeavy", "Stone", "Power" (amount).
-- Devuelve el daño (0 = no le hace nada) y si es inmune a eso (agua contra un robot).
function EnemyStats.damageFrom(kind: string, amount: number?, weaponId: string?, toyOk: boolean): (number, boolean)
	local n: number
	if kind == "Toy" then
		if not toyOk then
			return 0, true
		end
		n = EnemyStats.ToyDamage[weaponId or ""] or 0
	elseif kind == "Bullet" or kind == "Power" then
		n = amount or 0
	else
		n = EnemyStats.Sources[kind] or amount or 0
	end
	if type(n) ~= "number" or n ~= n then
		return 0, false
	end
	return math.clamp(math.floor(n + 0.5), 0, EnemyStats.MaxPerHit), false
end

-- Quitar vida: (vida que queda, ¿ha caído?)
function EnemyStats.apply(health: number, amount: number): (number, boolean)
	local after = math.max(0, health - math.max(0, amount))
	return after, after <= 0
end

-- Cuántos impactos de `perHit` hacen falta para tumbar `health`
function EnemyStats.hitsToDown(health: number, perHit: number): number
	if perHit <= 0 then
		return math.huge
	end
	return math.ceil(health / perHit)
end

-- Fracción de vida perdida (0 entero, 1 caído): el rayo encogedor encoge a Petra según esto
function EnemyStats.lost(health: number, maxHealth: number): number
	if maxHealth <= 0 then
		return 1
	end
	return math.clamp(1 - health / maxHealth, 0, 1)
end

-- Cliente: ¿se enseña la barra de vida? (dañado hace poco o cerca)
EnemyStats.BarRange = 28 -- studs
EnemyStats.BarAfterHit = 6 -- segundos
function EnemyStats.showBar(distance: number, sinceHit: number?, health: number, maxHealth: number): boolean
	if health <= 0 or maxHealth <= 0 then
		return false
	end
	if sinceHit and sinceHit <= EnemyStats.BarAfterHit then
		return true
	end
	return distance <= EnemyStats.BarRange
end

-- Cliente: los números de daño seguidos se agrupan (una ráfaga = un número que va sumando)
EnemyStats.GroupSeconds = 0.35
function EnemyStats.group(last: { Amount: number, At: number, Head: boolean }?, amount: number, head: boolean, now: number): ({ Amount: number, At: number, Head: boolean }, boolean)
	if last and now - last.At <= EnemyStats.GroupSeconds then
		last.Amount += amount
		last.At = now
		last.Head = last.Head or head
		return last, true
	end
	return { Amount = amount, At = now, Head = head }, false
end

return EnemyStats
