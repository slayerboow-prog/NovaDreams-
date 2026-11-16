-- test-cerebro-bestias: cómo piensan y pelean las bestias (shared/Cosmos/BeastBrain; lo usa
-- Services/BeastService). lune run scripts/test-cerebro-bestias.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local Bestiary = L.load("src/shared/Cosmos/Bestiary")
local Brain = L.load("src/shared/Cosmos/BeastBrain")

print("🧠 Estilos de pelea")
local count, allOk = {}, true
for id, sp in Bestiary.Species do
	local st = Brain.styleOf(id, sp)
	allOk = allOk and st ~= nil and st.Name ~= nil
	count[st.Name] = (count[st.Name] or 0) + 1
end
check(allOk, "cada especie tiene su estilo de pelea")
for _, name in { "Manada", "Embestida", "Distancia", "Acechador", "Coloso" } do
	check((count[name] or 0) >= 3, ("hay bestias de estilo %s (%d)"):format(name, count[name] or 0))
end
for id in Brain.Override do
	check(Bestiary.Species[id] ~= nil, "la excepción " .. id .. " es una especie de verdad")
end
check(Brain.styleOf("LoboBosque", Bestiary.Species.LoboBosque).Name == "Manada"
	and Brain.styleOf("GolemLava", Bestiary.Species.GolemLava).Name == "Coloso"
	and Brain.styleOf("DracoHielo", Bestiary.Species.DracoHielo).Name == "Distancia"
	and Brain.styleOf("JabaliSierra", Bestiary.Species.JabaliSierra).Name == "Embestida",
	"lobos en manada, gólems colosos, dracos a distancia, jabalíes que cargan")
local dragon = Brain.bossMoves(Bestiary.Species.DragonInvierno)
local titan = Brain.bossMoves(Bestiary.Species.TitanVolcan)
local rey = Brain.bossMoves(Bestiary.Species.ReyLlanuras)
check(dragon.Ranged and titan.Slam and rey.Charge and dragon.Stomp, "los jefes: el dragón escupe, el titán golpea el suelo, el Rey carga")

print("👁 Verte y elegir presa")
local lobo = Bestiary.Species.LoboBosque
local st = Brain.styleOf("LoboBosque", lobo)
check(Brain.aggroRange(lobo, st, 20, 20) == lobo.Aggro, "una bestia de tu nivel te ve a su distancia de siempre")
check(Brain.aggroRange(lobo, st, 20, 40) == 0, "si le sacas 15 niveles o más, no te ataca al verte")
check(Brain.aggroRange(Bestiary.Species.DragonInvierno, st, 90, 110) > 0, "los jefes atacan a cualquiera")
local acecho = Brain.styleOf("AcechadorPradera", Bestiary.Species.AcechadorPradera)
check(Brain.aggroRange(Bestiary.Species.AcechadorPradera, acecho, 30, 30) < Bestiary.Species.AcechadorPradera.Aggro and acecho.Lunge == 2,
	"el acechador te ve más tarde, pero su primer mordisco duele el doble")
local A, B, C = {}, {}, {}
check(Brain.pickTarget(nil, { [A] = 10, [B] = 50 }, { [A] = true, [B] = true }) == B, "sin presa, va a por quien más le ha pegado")
check(Brain.pickTarget(A, { [A] = 100, [B] = 120 }, { [A] = true, [B] = true }) == A, "no cambia por poco")
check(Brain.pickTarget(A, { [A] = 100, [B] = 140 }, { [A] = true, [B] = true }) == B, "cambia si otro le pega claramente más")
check(Brain.pickTarget(A, { [A] = 100, [B] = 999 }, { [A] = true }) == A, "no va a por quien no puede perseguir")
check(Brain.pickTarget(A, { [B] = 5 }, { [B] = true, [C] = true }) == B, "si su presa se ha ido, la siguiente que le pegó")
check(Brain.pickTarget(nil, {}, {}) == nil, "sin nadie, nadie")

print("⚔ Moverse y atacar")
local R = Brain.Styles.Distancia.Ranged
check(Brain.rangedMove(50, R) == "Acercarse" and Brain.rangedMove(5, R) == "Alejarse" and Brain.rangedMove(22, R) == "Quieta",
	"las de distancia guardan la distancia")
local Ch = Brain.Styles.Embestida.Charge
check(Brain.canCharge(20, Ch) and not Brain.canCharge(5, Ch) and not Brain.canCharge(80, Ch), "solo cargan desde media distancia")
check(Ch.Windup >= 0.5 and Brain.Styles.Coloso.Slam.Windup >= 0.5 and Brain.AlertTime >= 0.5, "cargas, golpes y «!» avisan antes (da tiempo a apartarse)")
check(math.abs(Brain.segmentDistance(5, 3, 0, 0, 10, 0) - 3) < 1e-6 and math.abs(Brain.segmentDistance(-4, 3, 0, 0, 10, 0) - 5) < 1e-6,
	"la carga arrolla a quien está en su camino")
local x1, z1 = Brain.flankOffset(1, 5)
local x2, z2 = Brain.flankOffset(2, 5)
check(math.abs(math.sqrt(x1 * x1 + z1 * z1) - 5) < 1e-6 and math.abs(x1 - x2) + math.abs(z1 - z2) > 3, "las de manada te rodean, cada una por un lado")
check(Brain.shouldFlee(Bestiary.Species.JabaliSierra, 0.1, false) and not Brain.shouldFlee(Bestiary.Species.JabaliSierra, 0.1, true)
	and not Brain.shouldFlee(Bestiary.Species.GolemLava, 0.1, false) and not Brain.shouldFlee(Bestiary.Species.TitanVolcan, 0.05, false),
	"solo las pequeñas huyen, una vez; los gólems y jefes, nunca")
check(Brain.mustReturn(200, 10, 120) and Brain.mustReturn(10, 200, 120) and not Brain.mustReturn(50, 60, 120), "vuelve a casa si se aleja demasiado")

print("🔌 Montado en el servidor")
local src = fs.readFile("src/server/Services/BeastService.luau")
check(src:find("BeastBrain", 1, true) ~= nil and src:find('b.State == "Vuelta"', 1, true) ~= nil, "BeastService usa el cerebro y no encaja golpes volviendo a casa")
check(src:find("callPack", 1, true) ~= nil and src:find("startCharge", 1, true) ~= nil and src:find("spit(", 1, true) ~= nil
	and src:find("ringAttack", 1, true) ~= nil, "manadas, cargas, disparos y golpes de área")

print("🏹 Reglas de caza")
local H = L.load("src/shared/Cosmos/HuntRules")
local function fixed(v)
	return function()
		return v
	end
end
check(H.rollChampion(lobo, fixed(0.01)) and not H.rollChampion(lobo, fixed(0.5)) and not H.rollChampion(Bestiary.Species.TitanVolcan, fixed(0)),
	"a veces sale una campeona; los jefes nunca")
check(H.Champion.Hp > 1 and H.Champion.Xp >= 2 and H.Champion.Luck > 0, "la campeona aguanta más y da más experiencia y botín")
check(H.con(50, 30).Name == "Gris" and H.con(50, 44).Name == "Verde" and H.con(50, 52).Name == "Amarillo"
	and H.con(50, 57).Name == "Naranja" and H.con(50, 65).Name == "Rojo", "colores de dificultad: gris, verde, amarillo, naranja, rojo")
local x1 = H.killXp(800, false, false, 30, 30, 1)
local x2 = H.killXp(800, false, false, 30, 40, 1)
local x3 = H.killXp(800, false, true, 30, 30, 1)
local xb = H.killXp(800, true, false, 30, 30, 1)
check(x1 == 100 and x2 == 150 and x3 == 300 and xb == 300 and H.killXp(800, false, false, 30, 30, 0.1) == 10,
	"experiencia: más por más nivel, x3 campeona y jefe, poca si te sobra nivel")
local c1 = H.crit(0, fixed(0.05))
local c2 = H.crit(0, fixed(0.2))
local c3, m3 = H.crit(50, fixed(0.2))
check(c1 and not c2 and c3 and m3 > 1.5, "críticos: a veces; más con Suerte")
check(H.tier(0.9).Name == "Común" and H.tier(0.1).Name == "Raro" and H.tier(0.01).Name == "Legendario", "rarezas según lo que cuesta que caiga")
local drops = Bestiary.Species.LoboBosque.Drops
local rare = drops[#drops]
check(H.bestTier(drops, { [rare[1]] = 1 }).Rank >= H.tier(rare[4]).Rank and H.bestTier(drops, {}).Rank == 1, "la luz de botín es del color de lo mejor que cae")
-- (la XP de subir 1→110 matando bestias de tu nivel: que no sean ni 50 ni 50.000 por nivel)
local Gameplay = L.load("src/shared/Gameplay")
local perLevel = {}
for _, lv in { 15, 50, 100 } do
	local hp = Bestiary.Species.LoboBosque.Hp * Bestiary.levelScale(lv).Hp
	table.insert(perLevel, math.ceil(Gameplay.xpToNext(lv) / H.killXp(hp, false, false, lv, lv, 1)))
end
check(perLevel[1] >= 10 and perLevel[3] <= 80, ("bestias de tu nivel por cada nivel: %s"):format(table.concat(perLevel, "/")))
local plates = fs.readFile("src/client/Controllers/BeastPlates.luau")
check(plates:find("HuntRules.con", 1, true) ~= nil and fs.readFile("src/client/Main.client.luau"):find("BeastPlates", 1, true) ~= nil,
	"las placas de las bestias salen con el color de su dificultad")
local kit = fs.readFile("src/server/World/Kit/BeastKit.luau")
check(kit:find("Colmillo", 1, true) ~= nil and kit:find("Corona", 1, true) ~= nil and kit:find("Garra", 1, true) ~= nil, "bestias con detalles y campeonas con corona")

print("🐾 Cómo se mueven")
L.services.Players = L.services.Players or { LocalPlayer = {} }
local Anim = L.load("src/client/Controllers/BeastAnim")
check(Anim.pulse(0.19, 0.38) > 0.99 and Anim.pulse(0.5, 0.38) == 0 and Anim.pulse(-1, 0.38) == 0, "los golpes y respingos van y vuelven")
local a = Anim.jointPose("Cuadrupedo", "Pata", 1, 1, 1, math.pi / 2, 1, 0, false, 0, 0)
local b2 = Anim.jointPose("Cuadrupedo", "Pata", -1, -1, 2, math.pi / 2, 1, 0, false, 0, 0)
local c = Anim.jointPose("Cuadrupedo", "Pata", -1, 1, 3, math.pi / 2, 1, 0, false, 0, 0)
local function pitch(cf)
	local x = cf:ToEulerAnglesXYZ()
	return x
end
check(math.abs(pitch(a) - pitch(b2)) < 1e-6 and math.abs(pitch(a) + pitch(c)) < 1e-6 and math.abs(pitch(a)) > 0.3,
	"al andar, las patas van en diagonal (como un animal de verdad)")
local still = Anim.jointPose("Cuadrupedo", "Pata", 1, 1, 1, math.pi / 2, 0, 0, false, 0, 0)
check(math.abs(pitch(still)) < 1e-6, "quieta, las patas no se mueven")
local idle1 = Anim.bodyPose(1, 0, 0, 0.3, false, 0, 0, 0, 0, 0, "Cuadrupedo")
local idle2 = Anim.bodyPose(1, 0, 0, 1.0, false, 0, 0, 0, 0, 0, "Cuadrupedo")
check(math.abs(idle1.Position.Y - idle2.Position.Y) > 0.01, "quieta, respira")
local bite = Anim.bodyPose(1, 0, 0, 0, false, 1, 0, 0, 0, 0, "Cuadrupedo")
local ouch = Anim.bodyPose(1, 0, 0, 0, false, 0, 1, 0, 0, 0, "Cuadrupedo")
local dead = Anim.bodyPose(1, 0, 0, 0, false, 0, 0, 0, 0, 1, "Cuadrupedo")
check(bite.Position.Z < -0.5 and ouch.Position.Z > 0.2 and dead.Position.Y < -0.5, "al morder se lanza, al recibir se echa atrás, al caer se vuelca")
local kit2 = fs.readFile("src/server/World/Kit/BeastKit.luau")
local srv = fs.readFile("src/server/Services/BeastService.luau")
check(kit2:find("Motor6D", 1, true) ~= nil and kit2:find("rig(model, hub, shape)", 1, true) ~= nil, "las bestias tienen articulaciones para moverse")
check(srv:find("WanderSpeed", 1, true) ~= nil and srv:find("StunUntil", 1, true) ~= nil and srv:find('SetAttribute("Golpe"', 1, true) ~= nil,
	"pasean al paso y persiguen a la carrera; los golpes fuertes las aturden; avisan al cliente de cada golpe")

L.finish("test-cerebro-bestias")
