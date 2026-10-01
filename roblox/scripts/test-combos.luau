-- Prueba del estilo de lucha (combos y finales, impacto, guardia, esquivar y desvanecerse, energía y
-- poderes de la Grieta, fijar objetivo, la IA de los rivales y la policía al pegar) FUERA de Roblox.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-combos.luau
--
-- 1) Reglas puras: shared/Combat (combos, finales, guardia, aguante), shared/Powers (qué despierta la
--    historia y el Modo pruebas) y shared/CombatAI (qué decide un rival).
-- 2) El servidor DE VERDAD (CombatService, FighterService, WantedService, TesterService) en el Roblox de
--    mentira de scripts/lib/CrimeHarness: golpes entre jugadores, finales, congelación y empujón en lo
--    que se manda a los clientes, guardia rota, voltereta y desvanecerse con aguante, energía y poderes
--    bloqueados/desbloqueados, fijar objetivo, un rival con IA y las estrellas de búsqueda.
-- 3) El cliente: que los controles (móvil, ordenador y mando) y los botones existen.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local failures = 0
local function check(condition: any, message: string)
	if condition then
		print("  ✅ " .. message)
	else
		failures += 1
		print("  ❌ " .. message)
	end
end

local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()
local Powers = luau.load(fs.readFile("src/shared/Powers.luau"), { debugName = "Powers" })()
local CombatAI = luau.load(fs.readFile("src/shared/CombatAI.luau"), {
	debugName = "CombatAI",
	environment = setmetatable({ script = { Parent = { Combat = "Combat" } }, require = function()
		return Combat
	end }, { __index = getfenv(1) }),
})()

---------------------------------------------------------------------
print("▶ Combos de ligeros")
local chain = Combat.newChain()
local names = {}
local t = 10
for _ = 1, 7 do
	local name
	name, chain = Combat.nextMove(chain, "Light", t)
	table.insert(names, name)
	t += 0.3
end
check(table.concat(names, ",") == "L1,L2,L3,L4,L5,L6,L1", "seis ligeros seguidos (el séptimo vuelve a empezar): " .. table.concat(names, ","))
check(Combat.Moves.L6.Knockback > Combat.Moves.L5.Knockback * 4, "el sexto ligero empuja")
local _, c1 = Combat.nextMove(Combat.newChain(), "Light", 0)
local _, late = Combat.nextMove(c1, "Light", Combat.ChainWindow + 0.1)
check(late.Lights == 1, "si tardas más de ChainWindow, el combo vuelve al primero")

print("▶ Finales según la combinación")
local function finisher(lights: number, opts: { Charged: boolean?, Air: boolean? }?): string
	local c = Combat.newChain()
	local now = 0
	for _ = 1, lights do
		_, c = Combat.nextMove(c, "Light", now)
		now += 0.3
	end
	local name = Combat.nextMove(c, "Heavy", now, opts and opts.Charged, opts and opts.Air)
	return name
end
check(finisher(0) == "H1", "fuerte solo: golpe fuerte")
do
	local c = Combat.newChain()
	local a
	a, c = Combat.nextMove(c, "Heavy", 0)
	local b = Combat.nextMove(c, "Heavy", 0.6)
	check(a == "H1" and b == "H2", "fuerte + fuerte: patada giratoria")
end
check(finisher(1) == "Lanzador" and finisher(2) == "Lanzador", "ligero ×1-2 + fuerte: LANZADOR")
check(finisher(3) == "Empujon" and finisher(4) == "Empujon", "ligero ×3-4 + fuerte: EMPUJÓN LEJANO")
check(finisher(5) == "Suelo" and finisher(6) == "Suelo", "ligero ×5-6 + fuerte: GOLPE AL SUELO")
check(finisher(2, { Charged = true }) == "Cargado", "fuerte mantenido: golpe cargado (en cualquier momento)")
check(finisher(2, { Air = true }) == "Remate" and Combat.nextMove(Combat.newChain(), "Light", 0, false, true) == "AirL", "en el aire: ligeros aéreos y el fuerte es el REMATE AÉREO")
local L = Combat.Moves
check(L.Lanzador.Launch and L.Lanzador.Lift > 40 and L.Lanzador.Air > 1, "el lanzador sube al rival (y al que pega) y lo deja flotando")
check(L.Empujon.Wall and L.Empujon.Knockback >= 60 and L.Empujon.Down, "el empujón lejano manda a volar, derriba y puede estampar contra una pared")
check(L.Suelo.Down and L.Suelo.Lift < 0 and L.Remate.Lift < 0, "al suelo y el remate aéreo empujan hacia abajo y derriban")
check(L.Cargado.GuardBreak and not L.H1.GuardBreak, "solo el golpe cargado rompe la guardia de golpe")

print("▶ Impacto: congelación (hitstop), aturdido y pausas")
local allStop = true
for name, move in L do
	allStop = allStop and move.Hitstop > 0 and move.Hitstop <= 0.2 and move.Stun > 0 and move.Recovery > 0
	local _ = name
end
check(allStop, "todos los golpes tienen congelación (0-0,2 s), aturdido y pausa")
check(L.Cargado.Hitstop > L.Empujon.Hitstop and L.Empujon.Hitstop > L.L1.Hitstop, "más fuerte, más congelación")
check(not Combat.readyMove("L1", 10, 10.1) and Combat.readyMove("L1", 10, 10.25), "entre ligeros, una pausa corta")
check(not Combat.readyMove("Empujon", 10, 10.4) and Combat.readyMove("Empujon", 10, 10.7), "después de un final, la pausa es más larga")
check(Combat.stunFor(L.Suelo) > L.Suelo.Down, "derribado: el suelo y luego levantarse")
check(Combat.moveDamage("L1", 0, 0, false) == 5 and Combat.moveDamage("Suelo", 0, 0, false) == 18, "daño: ligero 5, al suelo 18")
check(Combat.moveDamage("Empujon", 0, 0, true) < Combat.moveDamage("Empujon", 0, 0, false) / 3, "defendido pasa muy poco")
check(Combat.moveDamage("L1", 10, 100, false) > Combat.moveDamage("L1", 0, 0, false), "la Fuerza y el gimnasio pegan más")

print("▶ Guardia")
local g, broken = Combat.guardHit(100, L.L1)
check(g == 100 - L.L1.GuardDamage and not broken, "cubrirse gasta la barra de guardia")
g, broken = Combat.guardHit(5, L.H1)
check(g == 0 and broken, "con la barra casi vacía, un golpe la rompe")
g, broken = Combat.guardHit(100, L.Cargado)
check(broken, "el golpe cargado la rompe aunque esté llena")
check(Combat.regen(50, 100, 20, 0.2, 1, 1) == 50 and Combat.regen(50, 100, 20, 2, 1, 1) == 70, "se recupera sola, pero solo un rato después del último golpe")

print("▶ Esquivar y desvanecerse (aguante)")
check(Combat.dodgeKind(100, false, 99, false) == "Roll", "sin fijar a nadie: voltereta")
local kind, cost = Combat.dodgeKind(100, true, 99, false)
check(kind == "Vanish" and cost == Combat.VanishCost, "con objetivo fijado y aguante: desvanecerse")
kind, cost = Combat.dodgeKind(100, false, 0.2, false)
check(kind == "Vanish" and cost == Combat.EscapeCost and Combat.EscapeCost > Combat.VanishCost, "justo al recibir un golpe: escapar desvaneciéndose (cuesta más)")
check(Combat.dodgeKind(Combat.VanishCost - 1, true, 99, false) == "Roll", "sin aguante, solo voltereta")
check(Combat.dodgeKind(100, false, 99, true) == "Vanish", "en el aire, desvanecerse")
check(math.floor(Combat.StaminaMax / Combat.VanishCost) == 2 or math.floor(Combat.StaminaMax / Combat.VanishCost) == 3, "con la barra llena caben 2-3 seguidas")
check(not Combat.canAct(10, 10.5, 0) and Combat.canAct(11, 10.5, 0) and not Combat.canAct(11, 0, 12), "aturdido o en el suelo no se puede actuar")

---------------------------------------------------------------------
print("▶ Poderes de la Grieta: bloqueados al principio, los despierta la saga")
check(next(Powers.unlocked({ Story = {} }, false)) == nil, "al empezar: ningún poder (ni energía)")
local s2 = Powers.unlocked({ Story = { Completed = { Saga_02_Grieta = 1 } } }, false)
check(s2.Energia and s2.Esferas and not s2.Embestida and not s2.Definitiva and not s2.AirDash, "«La grieta en el cielo»: la energía y la ráfaga de esferas")
local s6 = Powers.unlocked({ Story = { Completed = { Saga_02_Grieta = 1, Saga_06_Coser = 1 } } }, false)
check(s6.Embestida and s6.AirDash and not s6.Onda, "«Coser el cielo»: embestida e impulso aéreo")
local sFlags = Powers.unlocked({ Story = { Completed = { Saga_02_Grieta = 1 }, Flags = { SagaActo2 = true, CosmeRescatado = true, SagaActo3 = true } } }, false)
check(sFlags.Onda and sFlags.Explosivo and sFlags.Definitiva, "también valen las marcas de la historia (fin de los actos II y III)")
check(next(Powers.unlocked({ Story = { Flags = { SagaActo3 = true } } }, false)) == nil, "sin la energía despierta no hay poderes")
check(Powers.unlocked({ Story = { Completed = { Saga_02_Grieta = 1 }, Skipped = { Saga_02_Grieta = true } } }, false).Energia == nil, "una misión saltada no cuenta")
local all = Powers.unlocked({ Story = {} }, true)
check(all.Energia and all.AirDash and all.Esferas and all.Embestida and all.Onda and all.Explosivo and all.Definitiva, "Modo pruebas: todos")
check(Powers.encode(all) == "Energia,AirDash,Esferas,Embestida,Onda,Explosivo,Definitiva" and Powers.decode(Powers.encode(s6)).Embestida, "se pasan al cliente en el atributo Powers")
check(#Powers.abilities(all) == 4 and Powers.Ultimate.Cost == Combat.EnergyMax, "4 habilidades y una definitiva que necesita la energía llena")
local newOnes = Powers.newOnes(s2, s6)
check(table.find(newOnes, "Embestida") ~= nil and table.find(newOnes, "Esferas") == nil, "se sabe qué acaba de despertar (para avisar)")
local ok1, why1 = Powers.canUse(Powers.get("Onda"), s2, 100, nil, 0)
local ok2, why2 = Powers.canUse(Powers.get("Esferas"), s2, 5, nil, 0)
local ok3 = Powers.canUse(Powers.get("Esferas"), s2, 50, 5, 0)
check(not ok1 and why1 ~= nil and not ok2 and why2 ~= nil and not ok3 and Powers.canUse(Powers.get("Esferas"), s2, 50, nil, 0), "hace falta tenerlo, energía y que no esté en pausa")
check(Powers.damage(Powers.get("Onda"), 1.5) > Powers.damage(Powers.get("Onda"), 0), "la onda cargada hace más daño")
check(Powers.inLine(0, 0, -20, 0, 0, 0, 0, 0, -1, 40, 3) and not Powers.inLine(10, 0, -20, 0, 0, 0, 0, 0, -1, 40, 3) and not Powers.inLine(0, 0, 10, 0, 0, 0, 0, 0, -1, 40, 3), "la onda da a quien está en su línea (ni al lado ni detrás)")
local banned = { "kamehameha", "saiyan", "kaioken", "goku", "vegeta", "dragon ball", "xenoverse", "genkidama", "%f[%a]ki%f[%A]" }
local clean = true
for _, file in { "src/shared/Combat.luau", "src/shared/Powers.luau", "src/shared/CombatAI.luau", "src/server/Services/CombatService.luau", "src/server/Services/FighterService.luau", "src/client/Controllers/CombatController.luau", "src/client/Controllers/CombatFx.luau", "src/client/Controllers/HitReaction.luau", "src/client/UI/CombatHud.luau" } do
	local text = string.lower(fs.readFile(file))
	for _, word in banned do
		if string.find(text, word) then
			clean = false
			print("     (" .. file .. ": «" .. word .. "»)")
		end
	end
end
check(clean, "nombres propios del juego (nada de nombres de otras sagas)")

---------------------------------------------------------------------
print("▶ IA de los rivales (CombatAI)")
local function fixed(...)
	local values = { ... }
	local i = 0
	return function()
		i += 1
		return values[math.min(i, #values)] or 0
	end
end
local Normal, Dificil, Facil = CombatAI.Levels.Normal, CombatAI.Levels.Dificil, CombatAI.Levels.Facil
local base = { Distance = 3, CanAct = true, Ready = true, TargetAttacking = false, TargetAttackAge = 9, TargetBlocking = false, TargetBlockingFor = 0, TargetDown = false, Blocking = false, JustBlocked = false, Stamina = 100, ComboStep = 0, ComboWant = 3, Health = 1 }
local function view(changes)
	local v = table.clone(base)
	for k, x in changes do
		v[k] = x
	end
	return v
end
check(CombatAI.decide(view({ CanAct = false }), Normal, fixed(0)) == "Wait", "aturdido: espera")
check(CombatAI.decide(view({ Distance = 20 }), Normal, fixed(0.9)) == "Approach", "lejos: se acerca")
check(CombatAI.decide(view({ TargetAttacking = true, TargetAttackAge = 0.3 }), Dificil, fixed(0.1)) == "Vanish", "difícil: le atacan y se desvanece (con aguante)")
check(CombatAI.decide(view({ TargetAttacking = true, TargetAttackAge = 0.3, Stamina = 0 }), Dificil, fixed(0.1)) ~= "Vanish", "sin aguante no se desvanece")
check(CombatAI.decide(view({ TargetAttacking = true, TargetAttackAge = 0.3 }), Normal, fixed(0.2)) == "Block", "normal: le atacan y se cubre")
check(CombatAI.decide(view({ TargetAttacking = true, TargetAttackAge = 0.3 }), Normal, fixed(0.15 + 0.4 + 0.05)) == "Roll", "…o rueda")
check(CombatAI.decide(view({ TargetAttacking = true, TargetAttackAge = 0.3 }), Facil, fixed(0.01)) ~= "Vanish", "fácil: nunca se desvanece")
check(CombatAI.decide(view({ Blocking = true, JustBlocked = true, TargetAttacking = true, TargetAttackAge = 0.1 }), Dificil, fixed(0.3)) == "Light", "después de parar un golpe, contraataca")
check(CombatAI.decide(view({ Blocking = true, TargetAttackAge = 2 }), Normal, fixed(0.99)) == "Unblock", "si ya no le atacan, deja de cubrirse")
check(CombatAI.decide(view({ ComboStep = 1 }), Normal, fixed(0.9)) == "Light", "en distancia: encadena ligeros…")
check(CombatAI.decide(view({ ComboStep = 3 }), Normal, fixed(0.1)) == "Heavy", "…y remata con el fuerte (el final)")
check(CombatAI.decide(view({ TargetBlocking = true, TargetBlockingFor = 1.5 }), Dificil, fixed(0.1)) == "Charged", "si te cubres mucho, carga el golpe (rompe la guardia)")
check(CombatAI.decide(view({ TargetDown = true }), Normal, fixed(0.1)) == "Wait", "no pega a quien está en el suelo")
check(CombatAI.decide(view({ TargetAir = true, ComboStep = 2 }), Normal, fixed(0.9)) == "Heavy", "con el rival en el aire, remata")
check(Dificil.React < Normal.React and Normal.React < Facil.React and Dificil.Health > Facil.Health, "más difícil: reacciona antes y aguanta más")
local lengths = {}
for i = 0, 10 do
	lengths[CombatAI.comboLength(Dificil, fixed(i / 10.001))] = true
end
check(lengths[Dificil.ComboMin] and lengths[Dificil.ComboMax], "combos de largo variable (de ComboMin a ComboMax)")

---------------------------------------------------------------------
-- El servidor de verdad
---------------------------------------------------------------------
local okRun, runError = pcall(function()
	local H = require("./lib/CrimeHarness")
	local V = roblox.Vector3.new
	local CF = roblox.CFrame
	-- Npc.create de mentira para los rivales (un personaje con raíz que se mueve por CFrame)
	local Inst = getmetatable(H.inst("Folder", "x")).__index
	local function syncedPart(name: string, parent: any, at: any)
		local p = H.inst("Part", name, parent)
		local cf = CF.new(at)
		setmetatable(p, {
			__index = function(_, k)
				if k == "CFrame" then
					return cf
				elseif k == "Position" then
					return cf.Position
				end
				return Inst[k]
			end,
			__newindex = function(self, k, v)
				if k == "CFrame" then
					cf = v
				elseif k == "Position" then
					cf = CF.new(v)
				else
					rawset(self, k, v)
				end
			end,
		})
		return p
	end
	local npcMock = H.mocks["src/server/World/Npc"]
	rawset(npcMock, "create", function(name, parent, cf)
		local model = H.inst("Model", name, parent)
		local humanoid = H.inst("Humanoid", "Humanoid", model)
		humanoid.Health, humanoid.MaxHealth, humanoid.HipHeight = 100, 100, 2
		local root = syncedPart("HumanoidRootPart", model, cf.Position + V(0, 3, 0))
		root.Size = V(2, 2, 1)
		local head = H.inst("Part", "Head", model)
		head.Position = cf.Position + V(0, 4.5, 0)
		model.PrimaryPart = root
		table.insert(H.npcs, model)
		return model
	end)
	H.boot()
	local CS = H.CombatService
	-- CFrame.lookAt de Lune mira al revés: FighterService (que coloca a los rivales con lookAt) se carga
	-- con el de Roblox, como en test-clientboot
	local function lookAt(at: any, target: any): any
		local look = target - at
		if look.Magnitude < 1e-6 then
			return CF.new(at)
		end
		look = look.Unit
		local right = look:Cross(roblox.Vector3.yAxis)
		if right.Magnitude < 1e-6 then
			right = look:Cross(roblox.Vector3.zAxis)
		end
		right = right.Unit
		return CF.fromMatrix(at, right, right:Cross(look).Unit, -look)
	end
	local FixedCF = setmetatable({ lookAt = lookAt }, { __index = CF })
	local Fighter = H.loadWith("src/server/Services/FighterService", {
		CFrame = FixedCF,
		-- (su carpeta con Owner tiene que ser de verdad: así solo su jugador le puede pegar)
		Instance = { new = function(class)
			return H.inst(class, class)
		end },
	})
	Fighter.init()
	local events = {}
	H.remotes.Combat.FireAllClients = function(_, kind, a, b, c)
		table.insert(events, { Kind = kind, A = a, B = b, C = c })
	end
	local function hitsOn(model, from: number?): { any }
		local list = {}
		for i = (from or 0) + 1, #events do
			local e = events[i]
			if e.Kind == "Hit" and e.A.Victim == model then
				table.insert(list, e.A)
			end
		end
		return list
	end
	local function face(p, at)
		local root = p.Character:FindFirstChild("HumanoidRootPart")
		root.CFrame = lookAt(root.Position, at)
	end
	local function fighter(name, id, pos)
		local p = H.player(name, id, "Adulto", pos)
		table.insert(H.npcs, p.Character) -- (para que los golpes lo encuentren: GetPartBoundsInRadius)
		return p
	end

	print("▶ Combos entre jugadores (servidor)")
	local A = fighter("Ana", 6001, V(0, 0, 0))
	local B = fighter("Beto", 6002, V(0, 0, -4))
	local mark = #events
	local moves = {}
	for _, k in { "Light", "Light", "Light" } do
		table.insert(moves, CS.handle(A, k))
		task.wait(0.26)
	end
	table.insert(moves, CS.handle(A, "Heavy", false))
	check(table.concat(moves, ",") == "L1,L2,L3,Empujon", "ligero ×3 + fuerte = empujón lejano: " .. table.concat(moves, ","))
	local hits = hitsOn(B.Character, mark)
	check(#hits == 4, ("los cuatro golpes entran (%d)"):format(#hits))
	local last = hits[#hits]
	check(last and last.Move == "Empujon" and last.Label ~= nil, "el final sale con su nombre en pantalla")
	check(last and last.Hitstop and last.Hitstop >= 0.1, "con congelación del impacto (Hitstop) para los clientes")
	check(last and last.Knockback >= 60 and last.Wall and last.Down, "con empujón fuerte, derribo y choque contra paredes")
	check(B.Character:FindFirstChild("Humanoid").Health < 100 - 20, ("Beto pierde vida (%d)"):format(B.Character:FindFirstChild("Humanoid").Health))
	local bs = CS.state(B)
	check(bs.DownUntil > os.clock() and B:GetAttribute("DownUntil") ~= nil, "Beto queda derribado (y su cliente lo sabe)")
	check(CS.handle(B, "Light") == nil, "derribado no puede pegar")
	mark = #events
	task.wait(0.7)
	CS.handle(A, "Light")
	check(#hitsOn(B.Character, mark) == 0, "a quien está en el suelo no se le pega")
	local swings = 0
	for _, e in events do
		if e.Kind == "Swing" and e.A == A then
			swings += 1
		end
	end
	check(swings >= 5, "todos ven cada golpe (Swing)")

	print("▶ Lanzador y combo aéreo")
	task.wait(Combat.Moves.Empujon.Down + Combat.GetUpInvulnerable + 0.4)
	mark = #events
	local launch = { CS.handle(A, "Light") }
	task.wait(0.26)
	table.insert(launch, CS.handle(A, "Heavy", false))
	local lh = hitsOn(B.Character, mark)
	check(launch[2] == "Lanzador" and lh[#lh] and lh[#lh].Air and lh[#lh].Launch, "ligero + fuerte = lanzador (al aire)")
	check(CS.state(A).AirUntil > os.clock() and CS.state(B).AirUntil > os.clock(), "los dos quedan en el aire un momento")
	task.wait(0.4)
	local air1 = CS.handle(A, "Light")
	task.wait(0.26)
	local air2 = CS.handle(A, "Heavy", false)
	check(air1 == "AirL" and air2 == "Remate", "en el aire: ligero aéreo y remate (" .. tostring(air1) .. ", " .. tostring(air2) .. ")")

	print("▶ Guardia y guardia rota")
	task.wait(Combat.Moves.Remate.Down + Combat.GetUpInvulnerable + 0.4)
	face(B, A.Character:FindFirstChild("HumanoidRootPart").Position)
	CS.handle(B, "Block", true)
	check(B:GetAttribute("Blocking") == true, "Beto se cubre")
	local before = B.Character:FindFirstChild("Humanoid").Health
	mark = #events
	CS.handle(A, "Light")
	local blockedHit = hitsOn(B.Character, mark)[1]
	check(blockedHit and blockedHit.Blocked and blockedHit.Amount <= 2, "cubierto de cara: entra muy poco daño")
	check(B.Character:FindFirstChild("Humanoid").Health >= before - 2 and CS.state(B).Guard < Combat.GuardMax, "y gasta su barra de guardia")
	task.wait(0.4)
	CS.state(B).Guard = 4
	mark = #events
	CS.handle(A, "Light")
	local breakHit = hitsOn(B.Character, mark)[1]
	check(breakHit and breakHit.GuardBroken and B:GetAttribute("Blocking") == nil and CS.state(B).StunUntil > os.clock(), "con la barra vacía: ¡guardia rota! (aturdido)")
	task.wait(Combat.GuardBreakStun + 0.3)
	CS.handle(B, "Block", true)
	CS.handle(A, "HeavyHold")
	task.wait(Combat.ChargeTime + 0.05)
	mark = #events
	local charged = CS.handle(A, "Heavy", true)
	local chargedHit = hitsOn(B.Character, mark)[1]
	check(charged == "Cargado" and chargedHit and chargedHit.GuardBroken and not chargedHit.Blocked, "el golpe cargado rompe la guardia y entra entero")
	task.wait(1)
	CS.handle(A, "HeavyHold")
	task.wait(0.05)
	check(CS.handle(A, "Heavy", true) ~= "Cargado", "decir «cargado» sin haberlo mantenido no cuela")

	print("▶ Esquivar: voltereta y desvanecerse")
	task.wait(3)
	local C = fighter("Cris", 6003, V(100, 0, 0))
	local D = fighter("Dani", 6004, V(100, 0, -4))
	check(CS.handle(D, "Dodge", nil, V(1, 0, 0)) == "Roll" and D:GetAttribute("Roll") ~= nil, "voltereta (todos la ven: atributo Roll)")
	mark = #events
	CS.handle(C, "Light")
	local missed = false
	for i = mark + 1, #events do
		if events[i].Kind == "Miss" and events[i].A == D.Character then
			missed = true
		end
	end
	check(#hitsOn(D.Character, mark) == 0 and missed, "durante la voltereta el golpe no entra («¡Esquivado!»)")
	task.wait(1.3)
	check(CS.handle(D, "Dodge", "Vanish") == nil, "sin fijar a nadie ni recibir un golpe, Esquivar no es desvanecerse")
	CS.handle(D, "Lock", C.Character)
	local stam = CS.state(D).Stamina
	mark = #events
	check(CS.handle(D, "Dodge", "Vanish", V(0, 0, 1)) == "Vanish", "con objetivo fijado y aguante: se desvanece")
	check(math.abs(CS.state(D).Stamina - (stam - Combat.VanishCost)) < 0.5 and D:GetAttribute("Aguante") ~= nil, "gasta aguante (y el cliente ve su barra)")
	local vanished = false
	for i = mark + 1, #events do
		if events[i].Kind == "Vanish" and events[i].A == D then
			vanished = true
		end
	end
	check(vanished and CS.state(D).InvulnUntil > os.clock(), "todos lo ven y un instante no le dan")
	task.wait(Combat.VanishCooldown + 0.05)
	CS.handle(D, "Dodge", "Vanish")
	task.wait(Combat.VanishCooldown + 0.05)
	local third = CS.handle(D, "Dodge", "Vanish")
	check(third == nil and CS.state(D).Stamina < Combat.VanishCost, "sin aguante ya no puede (se recupera solo)")
	task.wait(Combat.StaminaRegenDelay + 1.2)
	check(CS.state(D).Stamina > Combat.VanishCost - 1, "el aguante se recupera")
	-- Escapar justo al recibir un golpe (cuesta más)
	CS.handle(D, "Lock", nil)
	CS.state(D).Stamina = Combat.StaminaMax
	CS.state(D).InvulnUntil = 0
	face(D, V(100, 0, 10))
	local dr = D.Character:FindFirstChild("HumanoidRootPart")
	dr.Position = V(100, 0, -4)
	CS.handle(C, "Light")
	check(CS.handle(D, "Dodge", "Vanish") == "Vanish" and math.abs(CS.state(D).Stamina - (Combat.StaminaMax - Combat.EscapeCost)) < 0.5, "justo después de recibir un golpe: escapa desvaneciéndose (cuesta más)")

	print("▶ Fijar objetivo")
	local E = fighter("Eva", 6005, V(200, 0, 0))
	local Fx = fighter("Fede", 6006, V(200, 0, -(Combat.Range + 2)))
	mark = #events
	CS.handle(E, "Light")
	check(#hitsOn(Fx.Character, mark) == 0, "sin fijar, desde lejos no llega")
	CS.handle(E, "Lock", Fx.Character)
	check(CS.state(E).Lock == Fx.Character, "fija a Fede")
	task.wait(0.3)
	mark = #events
	CS.handle(E, "Light")
	check(#hitsOn(Fx.Character, mark) == 1, "fijado, llega un poco más lejos (se lanza hacia él)")
	local far = fighter("Lejos", 6007, V(200, 0, -200))
	CS.handle(E, "Lock", far.Character)
	check(CS.state(E).Lock == nil, "no se puede fijar a alguien muy lejos")

	print("▶ Energía y poderes (bloqueados hasta la historia)")
	local G = fighter("Gabi", 6008, V(300, 0, 0))
	local powers = CS.powers(G)
	check(next(powers) == nil and G:GetAttribute("Powers") == nil, "al empezar no tiene poderes")
	CS.handle(G, "Charge", true)
	check(G:GetAttribute("Charging") == nil, "no puede cargar energía")
	check(CS.handle(G, "Power", "Esferas") ~= true and CS.handle(G, "Ultimate") ~= true, "ni usar habilidades ni la definitiva")
	H.profiles[G].Story.Completed = { Saga_02_Grieta = os.time() }
	local mark2 = #H.sent
	powers = CS.powers(G)
	check(powers.Energia and powers.Esferas and not powers.Definitiva, "tras «La grieta en el cielo»: energía y esferas")
	check(G:GetAttribute("Powers") == "Energia,Esferas", "el cliente lo sabe (atributo Powers)")
	check(H.noticeHas(G, "despertado", mark2), "y se le avisa de lo que ha despertado")
	CS.handle(G, "Charge", true)
	check(G:GetAttribute("Charging") == true, "ahora sí carga energía (aura)")
	task.wait(1.1)
	check(CS.state(G).Energy >= 25, ("la energía sube cargando (%d)"):format(CS.state(G).Energy))
	CS.handle(G, "Charge", false)
	local target = H.npc("Saco", V(300, 0, -10), { Owner = G.UserId })
	mark = #events
	check(CS.handle(G, "Power", "Esferas", V(0, 0, -1)) == true, "lanza la ráfaga de esferas")
	check(CS.state(G).Energy < 25, "gasta energía")
	task.wait(1)
	local orbHits = hitsOn(target, mark)
	check(#orbHits >= 3 and orbHits[1].Energy and orbHits[1].Power == "Esferas", ("las esferas vuelan y dan (%d)"):format(#orbHits))
	check(CS.handle(G, "Power", "Esferas") ~= true, "en pausa y sin energía no se repite")
	check(CS.handle(G, "Ultimate") ~= true, "la definitiva sigue bloqueada")
	local owner = fighter("Dueño", H.CREATOR, V(400, 0, 0))
	powers = CS.powers(owner)
	check(powers.Definitiva and powers.Onda and powers.Explosivo and powers.Embestida and powers.AirDash, "Modo pruebas («Sin requisitos»): todos los poderes")
	check(H.TesterService.handle(owner, "Action", "Energy") == true and CS.state(owner).Energy == Combat.EnergyMax, "el panel de pruebas llena la energía")
	local dummy = H.npc("Saco2", V(400, 0, -12), { Owner = owner.UserId })
	mark = #events
	check(CS.handle(owner, "Ultimate", V(0, 0, -1)) == true, "definitiva con la energía llena")
	local started = false
	for i = mark + 1, #events do
		if events[i].Kind == "Ultimate" and events[i].B == "Start" then
			started = true
		end
	end
	check(started and CS.state(owner).Energy == 0, "empieza la mini-cinemática y gasta toda la energía")
	task.wait(Powers.Ultimate.WindUp + 0.3)
	local fired = false
	for i = mark + 1, #events do
		if events[i].Kind == "Ultimate" and events[i].B == "Fire" then
			fired = true
		end
	end
	check(fired and #hitsOn(dummy, mark) >= 1, "y estalla: da al que tiene delante")
	CS.fillEnergy(owner)
	local sack = fighter("Saco3", 6009, V(400, 0, -16))
	task.wait(0.5)
	CS.handle(owner, "PowerHold", "Onda")
	task.wait(1)
	mark = #events
	check(CS.handle(owner, "Power", "Onda", V(0, 0, -1)) == true, "onda de energía cargada")
	task.wait(0.4)
	local wave = hitsOn(sack.Character, mark)[1]
	check(wave and wave.Amount > Powers.get("Onda").Damage, "cargada hace más daño")
	H.profiles[owner].Tester.Bypass = false
	check(next(CS.powers(owner)) == nil, "con «Sin requisitos» apagado, el tester vuelve a no tener poderes (su historia)")
	H.profiles[owner].Tester.Bypass = true
	CS.powers(owner)
	check(CS.handle(owner, "AirDash") == true, "impulso aéreo: gasta aguante")

	print("▶ Rival con IA (FighterService)")
	local P = fighter("Pepa", 6010, V(600, 0, 0))
	local rival = Fighter.spawn(P, V(600, 0, -6), "Dificil")
	check(rival ~= nil and rival:GetAttribute("Fighter") == "Dificil" and rival.Parent:GetAttribute("Owner") == P.UserId, "sale un rival difícil de Pepa")
	check(rival:FindFirstChild("Humanoid").MaxHealth == CombatAI.Levels.Dificil.Health and CS.state(rival) ~= nil, "con su vida y pelea con las mismas reglas")
	local fv = Fighter.view(Fighter._fighter(rival), os.clock())
	check(fv and fv.Distance > 5 and fv.CanAct ~= nil, "ve a Pepa (distancia, si ataca, si se cubre…)")
	-- Deja pensar a la IA un rato: se acerca y pega
	mark = #events
	local hp0 = P.Character:FindFirstChild("Humanoid").Health
	for _ = 1, 60 do
		Fighter._think(rival)
		Fighter._step(0.12)
		task.wait(0.12)
		if P.Character:FindFirstChild("Humanoid").Health < hp0 then
			break
		end
	end
	local rivalHits = 0
	for i = mark + 1, #events do
		local e = events[i]
		if e.Kind == "Hit" and e.A.Victim == P.Character and e.A.AttackerModel == rival then
			rivalHits += 1
		end
	end
	check(rivalHits >= 1 and P.Character:FindFirstChild("Humanoid").Health < hp0, ("el rival se acerca y le pega (%d golpes)"):format(rivalHits))
	-- Pepa le pega: no es delito
	local pr = P.Character:FindFirstChild("HumanoidRootPart")
	face(P, rival:FindFirstChild("HumanoidRootPart").Position)
	pr.Position = rival:FindFirstChild("HumanoidRootPart").Position + V(0, -3, 3)
	local rhp = rival:FindFirstChild("Humanoid").Health
	CS.handle(P, "Lock", rival)
	CS.state(rival).InvulnUntil = 0
	CS.state(rival).DodgeAt = nil
	CS.state(rival).Blocking = false
	task.wait(0.5)
	CS.handle(P, "Light")
	check(rival:FindFirstChild("Humanoid").Health < rhp, "Pepa le quita vida al rival")
	-- Otro jugador no le puede pegar ni el rival a él
	local Q = fighter("Quique", 6011, V(600, 0, -10))
	check(CS.state(rival).OwnerId == P.UserId, "el rival solo pelea con quien lo ha sacado")
	-- Derrotado: se rinde y se va
	rival:FindFirstChild("Humanoid").Health = 2
	CS.state(rival).InvulnUntil = 0
	CS.state(rival).DownUntil = 0
	CS.state(rival).Blocking = false
	CS.state(rival).DodgeAt = nil
	task.wait(0.4)
	CS.handle(P, "Light")
	check(CS.state(rival) == nil or CS.state(rival).Defeated, "al quedarse sin vida se rinde")
	task.wait(4.3)
	check(rival.Parent == nil or rival.Parent.Parent == nil, "y se va")
	task.wait(Combat.Moves.L1.Recovery)
	local _ = Q

	print("▶ Policía al pegar")
	local W = fighter("Wil", 6012, V(800, 0, 0))
	local X = fighter("Xavi", 6013, V(800, 0, -4))
	H.npc("Testigo", V(806, 0, 0))
	CS.handle(W, "Light")
	task.wait(H.Wanted.CallDelay + 0.6)
	check((W:GetAttribute("Wanted") or 0) >= 1, "pegar a otro jugador: agresión (estrellas)")
	local Y = fighter("Yago", 6014, V(1000, 0, 0))
	local walker = H.npc("Paseante", V(1000, 0, -4), { Crowd = "Calle" })
	CS.handle(Y, "Light")
	task.wait(H.Wanted.CallDelay + 0.6)
	check((Y:GetAttribute("Wanted") or 0) >= 1 and H.saidAny(walker, "📞"), "pegar a un paseante: llama a la policía")
	local Z = fighter("Zoe", 6015, V(1200, 0, 0))
	local sparring = Fighter.spawn(Z, V(1200, 0, -4), "Facil")
	CS.state(sparring).InvulnUntil = 0
	task.wait(0.3)
	CS.handle(Z, "Light")
	task.wait(H.Wanted.CallDelay + 0.6)
	check(Z:GetAttribute("Wanted") == nil, "pegar a tu rival de entrenamiento no es delito")
	Fighter.dismiss(Z)
	local _ = X
end)
check(okRun, "las pruebas del servidor terminan sin errores" .. (if okRun then "" else ": " .. tostring(runError)))

---------------------------------------------------------------------
print("▶ Controles (cliente)")
local controller = fs.readFile("src/client/Controllers/CombatController.luau")
local function has(text: string): boolean
	return string.find(controller, text, 1, true) ~= nil
end
check(has("MouseButton1") and has("MouseButton2") and has("Enum.KeyCode.C") and has("Enum.KeyCode.F"), "ordenador: clic izquierdo ligero, clic derecho / C fuerte, F guardia")
check(has("Enum.KeyCode.G") and has("Enum.KeyCode.Y") and has("Enum.KeyCode.U") and has("Enum.KeyCode.R"), "ordenador: G cargar, Y habilidad, U cambiar, R definitiva")
check(has("ButtonR1") and has("ButtonR2") and has("ButtonL1") and has("ButtonX") and has("DPadLeft"), "mando: RB, RT, LB, X y la cruceta")
for _, id in { "Ataque", "Fuerte", "Defender", "Esquivar", "Fijar", "Cargar", "Poder", "CambiarPoder", "Definitiva" } do
	check(has('Id = "' .. id .. '"'), "móvil: botón " .. id)
end
check(has('Slot = "Gestos"') and has("Hold = function(down: boolean)\n\t\t\tCombatController.heavy(down)"), "móvil: Fuerte en el hueco de Gestos y se mantiene para cargarlo")
check(has("Camera.Value - 1") and has("lockCamera"), "fijar: la cámara gira para tener a los dos en pantalla")
check(has("RollMotion.roll(direction)") and has('send("Dodge", "Vanish"'), "Esquivar integra la voltereta y desvanecerse")
local fx = fs.readFile("src/client/Controllers/CombatFx.luau")
check(fx:find("function CombatFx.hitstop", 1, true) and fx:find("PunchAnim.freeze", 1, true) and fx:find("AdjustSpeed(0)", 1, true), "congelación del impacto: el golpe y las animaciones se paran")
check(fx:find("function CombatFx.impact", 1, true) and fx:find("ParticleEmitter", 1, true) and fx:find("ultimateCamera", 1, true), "partículas de impacto y mini-cinemática de la definitiva")
local hitReaction = fs.readFile("src/client/Controllers/HitReaction.luau")
check(hitReaction:find("watchWall", 1, true) and hitReaction:find("VectorForce", 1, true) and hitReaction:find("PlatformStand", 1, true), "empujón: vuela, flota en el aire, choca con las paredes y cae derribado")
local swim = fs.readFile("src/shared/Swim.luau")
check(swim:find("Fuerte = true", 1, true) ~= nil, "nadando no salen los botones de pelea nuevos")
local tester = fs.readFile("src/client/UI/TesterPanel.luau")
check(tester:find('"Rival"', 1, true) and tester:find('"Energy"', 1, true), "panel de pruebas: rivales y energía llena")

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
