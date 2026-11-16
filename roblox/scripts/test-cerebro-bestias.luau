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

L.finish("test-cerebro-bestias")
