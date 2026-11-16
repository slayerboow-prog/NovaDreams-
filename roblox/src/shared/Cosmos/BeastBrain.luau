-- BeastBrain: CÓMO PIENSAN las bestias (fase 3 del plan MMO del dueño). Cuentas puras, sin instancias: las usa
-- Services/BeastService en cada tick y las prueba scripts/test-cerebro-bestias.luau.
--
--   * Estados: Ronda (pasea por su guarida) → Alerta (te ha visto: «!» encima y un instante quieta, te da tiempo
--     a irte) → Caza (te persigue y ataca) → Vuelta (te has alejado demasiado de su casa: vuelve corriendo, no
--     encaja golpes y se cura entera, como en cualquier MMO; nada de matarla tirando de ella) · Huida (las
--     pequeñas, casi muertas, salen corriendo un momento y vuelven).
--   * Cada especie tiene un ESTILO de pelea: Bruto (muerde), Manada (avisa a las suyas y te rodean), Embestida
--     (se para, avisa con una raya en el suelo y carga), Distancia (te escupe/dispara desde lejos: se esquiva
--     moviéndote), Acechador (te ve tarde, pero el primer mordisco duele el doble) y Coloso (lento, encaja más y
--     da un golpe de área que avisa con un anillo).
--   * Amenaza: la bestia va a por quien más daño le hace (cambia solo si otro la supera claramente).
--   * Las bestias que te quedan muy por debajo (15 niveles o más) no te atacan al verte: solo si les pegas.

local BeastBrain = {}

BeastBrain.AlertTime = 0.8 -- (segundos quieta con el «!» antes de lanzarse)
BeastBrain.CallRadius = 25 -- (a cuánto avisa a las suyas una bestia cualquiera; las de manada, más)
BeastBrain.GreyGap = 15 -- (si les sacas tantos niveles, no te atacan al verte)
BeastBrain.SwitchThreat = 1.3 -- (cambia de presa si otro le ha hecho un 30 % más de daño)
BeastBrain.ReturnSpeed = 1.6 -- (al volver a casa corre más)
BeastBrain.ReturnMax = 8 -- (segundos como mucho volviendo: luego aparece en su guarida)
BeastBrain.FleeHp = 0.2
BeastBrain.FleeSeconds = 3
BeastBrain.FleeMaxBaseHp = 160 -- (solo huyen las pequeñas)

BeastBrain.Styles = {
	Bruto = { Name = "Bruto" },
	Manada = { Name = "Manada", Call = 60, Flank = 5 },
	Embestida = { Name = "Embestida", Charge = { Windup = 0.8, Dash = 0.8, Speed = 3, Mul = 1.8, Cooldown = 6, MinD = 12, MaxD = 40, Width = 4 } },
	Distancia = { Name = "Distancia", Ranged = { Keep = 22, Min = 12, Max = 60, Cooldown = 2.4, Mul = 0.8, Speed = 70, Radius = 5 } },
	Acechador = { Name = "Acechador", AggroMul = 0.6, Lunge = 2 },
	Coloso = { Name = "Coloso", Armor = 0.15, Slam = { Windup = 0.9, Radius = 11, Mul = 2, Cooldown = 5 } },
}

-- Las que no siguen la regla general (por su cuerpo)
BeastBrain.Override = {
	-- disparan o escupen desde lejos
	AvispaGrieta = "Distancia", AvispaEnjambre = "Distancia", EspirituCorrupto = "Distancia", DronRebelde = "Distancia",
	MedusaGas = "Distancia", BuitreRayo = "Distancia", DracoHielo = "Distancia", SalamandraVolcan = "Distancia",
	CriaturaVacio = "Distancia", ConstructoRuinas = "Distancia",
	Nigromante = "Distancia", Cultista = "Distancia", MagoOscuro = "Distancia", ElementalFuego = "Distancia", DragonInfernal = "Distancia",
	-- cargan
	JabaliSierra = "Embestida", OsoLanudo = "Embestida", CocodriloMutado = "Embestida", CocodriloAliviadero = "Embestida",
	FocaColmillo = "Embestida", EscarabajoCorteza = "Embestida", OsoGigante = "Embestida", Minotauro = "Embestida",
	-- en manada
	LoboBosque = "Manada", LoboArtico = "Manada", LoboEscarcha = "Manada", ChacalDuna = "Manada", Rondador = "Manada",
	RataChatarra = "Manada", RataCloaca = "Manada", SabuesoMagma = "Manada", BestiaSombria = "Manada", SaqueadorNomada = "Manada",
	EsqueletoGuerrero = "Manada",
	-- a mordiscos (o a golpes), sin más
	SlimeToxico = "Bruto", Momia = "Bruto",
	-- al acecho
	AcechadorPradera = "Acechador", PanteraLiana = "Acechador", VivoraPenasco = "Acechador", SerpienteArena = "Acechador",
	AnguilaArrecife = "Acechador", GusanoColada = "Acechador", AranaBosque = "Acechador", AranaHielo = "Acechador",
	EscorpionGigante = "Acechador", EscorpionSal = "Acechador",
}

-- El estilo de una especie
function BeastBrain.styleOf(id: string?, sp: { [string]: any }): { [string]: any }
	local name = sp.Style or (id and BeastBrain.Override[id])
	if not name then
		if sp.Arms then
			name = "Coloso"
		elseif sp.Body == "Cuadrupedo" then
			name = if (sp.Speed or 0) >= 20 then "Manada" else "Embestida"
		elseif sp.Body == "Serpiente" then
			name = "Acechador"
		elseif sp.Body == "Bipedo" then
			name = "Distancia"
		else
			name = "Bruto"
		end
	end
	return BeastBrain.Styles[name] or BeastBrain.Styles.Bruto
end

-- Los ataques especiales de un jefe (además de su pisotón): según su cuerpo
function BeastBrain.bossMoves(sp: { [string]: any }): { [string]: boolean }
	return {
		Stomp = true,
		Charge = sp.Body == "Cuadrupedo",
		Ranged = sp.Body == "Serpiente" or sp.Body == "Insecto",
		Slam = sp.Arms == true,
	}
end

-- A cuánto te ve (0: no te ataca al verte, le sacas demasiados niveles)
function BeastBrain.aggroRange(sp: { [string]: any }, style: { [string]: any }, beastLevel: number?, playerLevel: number?): number
	local base = (sp.Aggro or 60) * (style.AggroMul or 1)
	if sp.Boss then
		return sp.Aggro or 100
	end
	local b, p = tonumber(beastLevel), tonumber(playerLevel)
	if b and p and p - b >= BeastBrain.GreyGap then
		return 0
	end
	return base
end

-- A quién va: sigue con la presa actual salvo que otra le haya hecho claramente más daño.
-- threat: daño por jugador; eligible: los que puede perseguir ahora mismo
function BeastBrain.pickTarget(current: any, threat: { [any]: number }, eligible: { [any]: boolean }): any
	local cur = if current ~= nil and eligible[current] then current else nil
	local curT = if cur ~= nil then (threat[cur] or 0) else -1
	local best, bestT = cur, curT
	for who, t in threat do
		if eligible[who] and who ~= cur and t > bestT then
			best, bestT = who, t
		end
	end
	if cur ~= nil and best ~= cur and bestT < curT * BeastBrain.SwitchThreat then
		return cur
	end
	return best
end

-- ¿Sale corriendo? (solo las pequeñas, una vez, casi muertas)
function BeastBrain.shouldFlee(sp: { [string]: any }, hpFrac: number, alreadyFled: boolean?): boolean
	return not sp.Boss and not alreadyFled and (sp.Hp or 0) <= BeastBrain.FleeMaxBaseHp and hpFrac > 0 and hpFrac < BeastBrain.FleeHp
end

-- Dónde se pone una de manada alrededor de su presa (cada una en su lado: te rodean)
function BeastBrain.flankOffset(n: number, radius: number): (number, number)
	local a = (n * 2.39996) % (math.pi * 2) -- (ángulo áureo: repartidas)
	return math.cos(a) * radius, math.sin(a) * radius
end

-- Las de distancia: «Acercarse» | «Alejarse» | «Quieta»
function BeastBrain.rangedMove(dist: number, ranged: { [string]: any }): string
	if dist > ranged.Keep + 8 then
		return "Acercarse"
	elseif dist < ranged.Min then
		return "Alejarse"
	end
	return "Quieta"
end

-- ¿Puede cargar a esa distancia?
function BeastBrain.canCharge(dist: number, charge: { [string]: any }): boolean
	return dist >= charge.MinD and dist <= charge.MaxD
end

-- Distancia de un punto (px, pz) al tramo (ax, az)–(bx, bz): para ver a quién arrolla una carga
function BeastBrain.segmentDistance(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number
	local vx, vz = bx - ax, bz - az
	local len2 = vx * vx + vz * vz
	local t = if len2 > 1e-9 then math.clamp(((px - ax) * vx + (pz - az) * vz) / len2, 0, 1) else 0
	local cx, cz = ax + vx * t, az + vz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

-- ¿Debe volver a casa? (su presa o ella misma se han ido demasiado lejos)
function BeastBrain.mustReturn(selfFromHome: number, targetFromHome: number?, leash: number): boolean
	if selfFromHome > leash + 30 then
		return true
	end
	return targetFromHome ~= nil and targetFromHome > leash + 30
end

return BeastBrain
