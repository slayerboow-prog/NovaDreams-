-- Prueba de TEFRA · «Ceniza en Bastión»: misiones, oficios, calor y bombardeos (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-tefra.luau          (~10 min; «rapido»: sin jugar las misiones enteras)
--
-- Comprueba (docs/planetas/tefra-misiones.md):
--   1. Las cuentas puras: calor (TefraHeat), bombardeos (TefraWar), oficios (TefraJobs: rangos, paga,
--      trampas, puzle de los cables con una sola solución, patrullas) y la Forja (TefraCraft).
--   2. El plano: cada sitio de la historia y cada punto de los oficios está donde se puede estar (sin
--      lava, sin meterse en un edificio cerrado), los refugios existen y cada zona de bombardeo tiene un
--      refugio cerca; los lugares «Tefra_…» de las misiones son solo de Tefra.
--   3. La historia con el motor de verdad (StoryHarness): sin estar en Tefra no se ofrece nada; en Tefra
--      el episodio entero (7 misiones) se juega de principio a fin con las dos ramas de cada decisión, y
--      las cadenas secundarias (El padre de Brasa, Papeles, Candados) también; lo que dejan (objetos,
--      recuerdos, tregua, memoria del mundo) llega y la partida se puede guardar.
--   4. Los oficios (TefraJobService con dobles): cada uno se juega de punta a punta, paga, sube de rango,
--      guarda la carrera en data.Careers, castiga las trampas, el desactivador explota sin daño si
--      cortas mal, el bombero falla si se acaba el tiempo, el correo con patrullas y papeles.
--   5. La vida (TefraService con dobles): el medidor de calor sube junto a la lava y baja en el refugio,
--      frena, nunca mata (derriba), el traje y el gel ayudan; el bombardeo con sirenas, refugios,
--      derribos SIN daño, nada en mitad de una escena, el horario y la tregua; la Forja fabrica.
--   6. Valmar no cambia: la velocidad sin calor, los requisitos de siempre, ningún sitio de Valmar.

local roblox = require("@lune/roblox")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

-- Que nunca se quede colgada (un error en mitad deja vivos los bucles de la historia)
task.delay(1200, function()
	print("❌ test-tefra no ha terminado en 20 minutos")
	process.exit(1)
end)

local L = require("./lib/ModuleLoader")
local check = L.check
local Vector3 = roblox.Vector3

local TefraCity = L.load("src/shared/Cosmos/TefraCity")
local Tefra = L.load("src/shared/Cosmos/Tefra")
local TefraHeat = L.load("src/shared/Cosmos/TefraHeat")
local TefraWar = L.load("src/shared/Cosmos/TefraWar")
local TefraJobs = L.load("src/shared/Cosmos/TefraJobs")
local TefraCraft = L.load("src/shared/Cosmos/TefraCraft")
local Items = L.load("src/shared/Items")
local Config = L.load("src/shared/Config")

---------------------------------------------------------------------
print("\n▶ 1. Cuentas puras")
---------------------------------------------------------------------
do
	-- Calor
	local lava = TefraHeat.rate({ Lava = 3 })
	local far = TefraHeat.rate({ Lava = 200 })
	check(lava > 2 and far < 0, ("junto a la lava sube (%.1f/s); lejos de todo, baja (%.1f/s)"):format(lava, far))
	check(TefraHeat.rate({ Lava = 3, Shelter = 6 }) == -6, "dentro de un refugio solo baja (aunque haya lava cerca)")
	check(TefraHeat.rate({ Lava = 3, Suit = 0.4 }) < lava and TefraHeat.rate({ Lava = 3, Gel = true }) < lava and TefraHeat.rate({ Lava = 3, Newbie = true }) < lava,
		"el traje, el gel y la ayuda de las primeras horas lo hacen subir menos")
	check(TefraHeat.rate({ District = "Fundiciones", Lava = 200 }) > 0 and TefraHeat.rate({ Outside = true, Day = true, Lava = 200 }) > 0 and TefraHeat.rate({ Outside = true, Day = false, Lava = 200 }) < 0,
		"las Fundiciones calientan; fuera de la muralla, solo de día")
	local h, t = 0, 0
	while h < TefraHeat.Danger and t < 300 do
		h = TefraHeat.step(h, { Lava = 10 }, 0.5)
		t += 0.5
	end
	local hs, ts = 0, 0
	while hs < TefraHeat.Danger and ts < 600 do
		hs = TefraHeat.step(hs, { Lava = 10, Suit = TefraHeat.Suits.TrajeRefrigerado3.Factor }, 0.5)
		ts += 0.5
	end
	check(t >= 30, ("junto a la lava se tarda %d s en llegar a Peligro (nunca de golpe)"):format(t))
	check(ts > t * 2, ("con el traje de nivel 3, %d s (más del doble)"):format(ts))
	local c, ct = 100, 0
	while c > 0 and ct < 100 do
		c = TefraHeat.step(c, { Shelter = TefraCity.Shelters.Tefra_Refugio.Cool }, 0.5)
		ct += 0.5
	end
	check(ct <= 20, ("en el refugio antibombas se enfría del todo en %d s"):format(ct))
	check(TefraHeat.step(99, { Lava = 0 }, 10) == 100 and TefraHeat.step(1, { Shelter = 9 }, 10) == 0, "el medidor nunca pasa de 100 ni baja de 0")
	check(TefraHeat.phase(10) == "Normal" and TefraHeat.phase(70) == "Aviso" and TefraHeat.phase(90) == "Peligro", "fases: Normal, Aviso, Peligro")
	check(TefraHeat.slow("Normal") == 1 and TefraHeat.slow("Aviso") < 1 and TefraHeat.slow("Peligro") < TefraHeat.slow("Aviso"), "con calor se anda más lento")
	check(not TefraHeat.knocked(70, 100, 5) and not TefraHeat.knocked(100, 2, 80) and TefraHeat.knocked(100, 7, 80) and TefraHeat.knocked(90, 0, 15),
		"te derriba (no te mata) solo en Peligro: medidor lleno un rato o poca vida")
	local same = #TefraHeat.Pools == #Tefra.LavaPools
	for i, p in TefraHeat.Pools do
		local q = Tefra.LavaPools[i]
		same = same and q ~= nil and p.X == q.X and p.Z == q.Z and p.R == q.R
	end
	check(same, "los lagos de lava del calor son los del planeta (Tefra.LavaPools)")
	check(TefraHeat.lavaDistance(0, 240) == 0 and TefraHeat.lavaDistance(0, 0) > 40 and TefraHeat.lavaDistance(0, 222) < 14, "distancia a la lava: el canal quema, el Muelle no")
	check(TefraHeat.onBridge(-80, 240) and not TefraHeat.onBridge(-160, 240), "sobre el puente no se está en la lava (debajo sí)")
	check(TefraHeat.suitFactor({ TrajeRefrigerado2 = 1, TrajeRefrigerado3 = 1 }) == TefraHeat.Suits.TrajeRefrigerado3.Factor and TefraHeat.suitFactor({}) == 1, "cuenta el mejor traje de la mochila")

	-- Bombardeos
	local a1 = TefraWar.pickZones(5, 1)
	local a2 = TefraWar.pickZones(5, 1)
	local b1 = TefraWar.pickZones(5, 2)
	check(#a1 == TefraWar.ZonesPerRaid and a1[1].Id == a2[1].Id and a1[3].Id == a2[3].Id, "las zonas de un bombardeo son siempre las mismas para ese día y turno")
	check(a1[1].Id ~= a1[2].Id and a1[2].Id ~= a1[3].Id and a1[1].Id ~= a1[3].Id, "tres zonas distintas")
	local differs = false
	for i = 1, 20 do
		differs = differs or TefraWar.pickZones(i, 1)[1].Id ~= TefraWar.pickZones(i + 1, 1)[1].Id
	end
	check(differs and b1 ~= nil, "cambian de un día a otro")
	local zonesOk = true
	for _, z in TefraWar.Zones do
		local pad = (z.X ^ 2 + z.Z ^ 2) ^ 0.5
		local dx, dz = TefraCity.nearestShelter(z.X, z.Z)
		local toShelter = ((dx - z.X) ^ 2 + (dz - z.Z) ^ 2) ^ 0.5
		zonesOk = zonesOk and pad > z.R + Tefra.PadRadius and toShelter < 160 and TefraCity.inside(z.X, z.Z, 0)
		for _, s in TefraWar.shells(z, 3, 8) do
			zonesOk = zonesOk and (s[1] - z.X) ^ 2 + (s[2] - z.Z) ^ 2 <= z.R * z.R
		end
	end
	check(zonesOk, "las zonas no tocan la plataforma, están dentro de la muralla, tienen un refugio cerca y las bombas caen dentro")
	local rx, rz = TefraCity.shelterInside("Tefra_Refugio")
	check(TefraCity.shelterAt(rx, rz) == "Tefra_Refugio", "dentro del refugio antibombas se está a salvo")
	check(not TefraWar.exposed({ { X = rx, Z = rz, R = 60 } }, rx, rz) and TefraWar.exposed({ { X = 0, Z = 0, R = 30 } }, 0, 0),
		"en una zona y al descubierto te alcanza; en el refugio, no")
	local lead = TefraWar.gameHours(TefraWar.WarnSeconds, Config.DayLengthMinutes)
	check(math.abs(lead - TefraWar.WarnSeconds / (Config.DayLengthMinutes * 60) * 24) < 1e-9, ("las sirenas duran %.2f horas de juego (60 s)"):format(lead))
	local key, slot = TefraWar.due(9 - lead / 2, 4, lead, {}, false)
	check(key == "4:1" and slot == 1, "a las 9 menos un poco suenan las sirenas del bombardeo de la mañana")
	check(TefraWar.due(9 - lead / 2, 4, lead, { ["4:1"] = true }, false) == nil and TefraWar.due(12, 4, lead, {}, false) == nil, "no se repite y a mediodía no toca")
	check(TefraWar.due(19 - lead / 2, 4, lead, {}, false) == "4:2", "y a las 19, el de la tarde")
	check(TefraWar.due(9 - lead / 2, 4, lead, {}, true) == nil and TefraWar.due(9 - lead / 2, 6, lead, {}, true) == "6:1" and TefraWar.due(19 - lead / 2, 6, lead, {}, true) == nil,
		"con la tregua, solo el de la mañana y uno de cada tres días")

	-- Oficios
	local last = -1
	local mono = true
	for i, r in TefraJobs.Ranks do
		mono = mono and r.Points > last and (i == 1 or r.Mult > TefraJobs.Ranks[i - 1].Mult)
		last = r.Points
	end
	check(mono and TefraJobs.Ranks[1].Mult == 1 and TefraJobs.Ranks[5].Mult == 2.1, "cinco rangos (×1 … ×2,1), cada uno pide más")
	check(TefraJobs.pay("TefraFundidor", 0, 1, 1) == 40 and TefraJobs.pay("TefraFundidor", 300, 1, 1) == 84, "paga del fundidor: 40 € de aprendiz, 84 € de maestro")
	check(TefraJobs.pay("TefraFundidor", 0, 0, 1) < TefraJobs.pay("TefraFundidor", 0, 1, 1), "lo bien que sale cuenta")
	check(TefraJobs.pay("TefraFundidor", 0, 1, 20) < TefraJobs.pay("TefraFundidor", 0, 1, 1) and TefraJobs.streakFactor(100) == 0.7, "repetir mucho lo mismo paga un poco menos (nunca menos del 70 %)")
	check(TefraJobs.pay("TefraCorreo", 0, 1, 1, TefraJobs.CurfewBonus) > TefraJobs.pay("TefraCorreo", 0, 1, 1), "de noche (toque de queda) el correo cobra más")
	check(not TefraJobs.allowed("TefraFundidor", {}, 100, 110) and TefraJobs.allowed("TefraFundidor", {}, 100, 130), "no se puede acabar un encargo antes de su tiempo mínimo")
	local full = {}
	for i = 1, TefraJobs.MaxPerHour do
		full[i] = 1000 + i
	end
	check(not TefraJobs.allowed("TefraFundidor", full, 1000, 2000) and TefraJobs.allowed("TefraFundidor", full, 1000, 1000 + 3700), "tope de encargos por hora")
	local job5 = TefraJobs.storyFor("TefraDesactivador", 5)
	check(job5 ~= nil and TefraJobs.storyFor("TefraDesactivador", 4) == nil and TefraJobs.storyFor("TefraDesactivador", 10) ~= job5, "uno de cada cinco encargos trae historia (y van cambiando)")
	local storiesOk = true
	for id, list in TefraJobs.Stories do
		storiesOk = storiesOk and TefraJobs.Jobs[id] ~= nil
		for _, s in list do
			storiesOk = storiesOk and #s.Options >= 2 and type(s.Ask) == "string"
		end
	end
	check(storiesOk, "cada historia de oficio tiene una pregunta y al menos dos opciones")
	local specsOk = true
	for _, id in TefraJobs.Order do
		for rank = 1, 5 do
			local spec = TefraJobs.gameSpec(id, rank)
			specsOk = specsOk and spec.Game == "Timing" and spec.Rounds >= spec.Need and spec.Zone > 0.1
		end
	end
	check(specsOk, "los minijuegos de los oficios son válidos en todos los rangos (MiniGameService: Timing)")
	-- Patrullas
	local route = TefraJobs.Patrols[1]
	local x0, z0 = TefraJobs.patrolAt(route, 0)
	local xm, zm = TefraJobs.patrolAt(route, 400 / TefraJobs.PatrolSpeed)
	local xb, zb = TefraJobs.patrolAt(route, 800 / TefraJobs.PatrolSpeed)
	check(x0 == -80 and z0 == -200 and math.abs(zm - 200) < 1e-6 and math.abs(zb + 200) < 1e-6 and xm == -80 and xb == -80, "la patrulla va y vuelve por su calle")
	check(TefraJobs.seenBy(0, -80, -195, false) ~= nil and TefraJobs.seenBy(0, -80, -150, false) == nil, "la patrulla ve lo que tiene cerca, no lo de lejos")
	check(TefraJobs.seenBy(0, -80, -188, true) ~= nil and TefraJobs.seenBy(0, -80, -188, false) == nil, "de noche ve más lejos")
	check(TefraJobs.curfew(23) and TefraJobs.curfew(3) and not TefraJobs.curfew(12), "toque de queda de 22:00 a 6:00")
end

-- El puzle de los cables: se resuelve leyendo SOLO la pista (como el jugador)
local function solveClue(wires: { string }, clue: string): number?
	local a, b = clue:match("^Corta el que no es ni (%S+) ni (%S+)%.$")
	if a then
		for i, w in wires do
			if w ~= a and w ~= b then
				return i
			end
		end
	end
	local where = clue:match("^Corta (el de la izquierda)%.$") or clue:match("^Corta (el del medio)%.$") or clue:match("^Corta (el de la derecha)%.$")
	if where then
		return ({ ["el de la izquierda"] = 1, ["el del medio"] = 2, ["el de la derecha"] = 3 })[where]
	end
	local after = clue:match("^Corta el que va justo después del (%S+) ")
	if after then
		for i, w in wires do
			if w == after then
				return i % 3 + 1
			end
		end
	end
	local banned = clue:match("^No cortes el (%S+) ni")
	if banned then
		for i, w in wires do
			if w == banned then
				local right = i % 3 + 1
				return 6 - i - right
			end
		end
	end
	return nil
end
do
	local okAll, kinds = true, {}
	for seed = 1, 400 do
		local p = TefraJobs.cablePuzzle(seed)
		local solved = solveClue(p.Wires, p.Clue)
		okAll = okAll and solved == p.Answer and p.Answer >= 1 and p.Answer <= 3 and #p.Wires == 3
		kinds[p.Clue:sub(1, 16)] = true
	end
	local n = 0
	for _ in kinds do
		n += 1
	end
	check(okAll, "400 bombas: la pista lleva siempre a un solo cable (y es el bueno)")
	check(n >= 4, ("hay %d tipos de pista distintos"):format(n))
	-- La Forja
	local ok1, why1 = TefraCraft.check("TrajeRefrigerado3", { ObsidianaIgnea = 9, CuarzoMalva = 9, GelTermico = 9 }, 999)
	local ok2 = TefraCraft.check("TrajeRefrigerado3", { ObsidianaIgnea = 9, CuarzoMalva = 9, GelTermico = 9, RecetaTraje3 = 1 }, 999)
	local ok3, why3 = TefraCraft.check("GelTermico", { LiquenTermico = 1 }, 99)
	check(not ok1 and why1 == "Te falta la receta" and ok2, "el traje de nivel 3 necesita su receta (la del episodio)")
	check(not ok3 and (why3 or ""):find("AzufreNegro", 1, true) ~= nil, "y dice lo que falta")
	local spend, gain, money = TefraCraft.plan("GelTermico")
	check(spend.LiquenTermico == 1 and spend.AzufreNegro == 1 and gain.GelTermico == 2 and money == 5, "el gel térmico: liquen + azufre → 2 geles (5 €)")
	local itemsOk = true
	for _, r in TefraCraft.Recipes do
		itemsOk = itemsOk and Items.get(r.Id) ~= nil and (r.Recipe == nil or Items.get(r.Recipe) ~= nil)
		for item in r.Needs do
			itemsOk = itemsOk and Items.get(item) ~= nil
		end
	end
	for _, job in TefraJobs.Jobs do
		itemsOk = itemsOk and (job.Drop == nil or Items.get(job.Drop.Item) ~= nil) and Config.Jobs[job.Id] ~= nil
	end
	check(itemsOk, "todo lo que se fabrica, se gasta o se gana existe en la mochila, y cada oficio está en Config.Jobs")
end

---------------------------------------------------------------------
print("\n▶ 2. El plano: sitios de la historia, puntos de los oficios y refugios")
---------------------------------------------------------------------
local Locations = L.load("src/shared/LifeStory/Locations")
do
	local function badPoint(x: number, z: number, out: boolean?, inside: string?): string?
		if out then
			if TefraCity.inside(x, z, TefraCity.MoatOut) then
				return "dice que es de fuera pero está en la ciudad"
			end
			if math.abs(x) > Tefra.Half - 100 or math.abs(z) > Tefra.Half - 100 then
				return "fuera del planeta"
			end
			return nil
		end
		if not TefraCity.inside(x, z, 0) then
			return "fuera de la muralla"
		end
		if TefraCity.inLava(x, z) and TefraCity.streetDistance(x, z) > TefraCity.RoadHalf then
			return "en la lava"
		end
		local b = TefraCity.buildingAt(x, z, 0)
		if inside then
			if not b or b.Id ~= inside then
				return "no está dentro de " .. inside
			end
			return nil
		end
		if b and b.Shape ~= "Court" and not (b.Shape == "Box" and b.Ground ~= "Closed") and b.Shape ~= "Skeleton" then
			return "dentro de " .. b.Id
		end
		return nil
	end
	local bad = {}
	for _, s in TefraCity.StorySpots do
		local why = badPoint(s.X, s.Z, s.Outside, s.Inside)
		if why then
			table.insert(bad, s.Id .. ": " .. why)
		end
	end
	check(#bad == 0, ("los %d sitios de la historia están donde se puede estar %s"):format(#TefraCity.StorySpots, table.concat(bad, "; ")))
	local badJobs = {}
	for _, p in TefraJobs.allPoints() do
		local inBox = TefraCity.buildingAt(p.X, p.Z, 0)
		local why = badPoint(p.X, p.Z, p.Out, if inBox and inBox.Shape == "Box" then inBox.Id else nil)
		if why then
			table.insert(badJobs, p.Kind .. ": " .. why)
		end
	end
	check(#badJobs == 0, ("los %d puntos de los oficios están donde se puede estar %s"):format(#TefraJobs.allPoints(), table.concat(badJobs, "; ")))
	local sheltersOk = true
	for id in TefraCity.Shelters do
		local b = TefraCity.BuildingById[id]
		sheltersOk = sheltersOk and b ~= nil and b.Shape == "Box" and b.Ground ~= "Closed"
		local ix, iz = TefraCity.shelterInside(id)
		sheltersOk = sheltersOk and TefraCity.shelterAt(ix, iz) == id
	end
	check(sheltersOk, "los refugios son edificios con planta baja (se entra) y su sitio de dentro cuenta como refugio")
	local places, missing = 0, {}
	for _, s in TefraCity.StorySpots do
		local place = Locations.Places["Tefra_" .. s.Id]
		places += 1
		if not place or place.Tag ~= "StorySpot" or place.Attribute.SpotId ~= "Tefra_" .. s.Id or place.Fallback ~= nil then
			table.insert(missing, s.Id)
		end
	end
	check(#missing == 0, ("cada sitio es un lugar «Tefra_…» de la historia, sin lugar de repuesto en Valmar (%d)"):format(places))
	local valmarHasTefra = false
	for id, place in Locations.Places do
		if id:sub(1, 6) ~= "Tefra_" and type(place.Attribute) == "table" and tostring(place.Attribute.SpotId or ""):sub(1, 6) == "Tefra_" then
			valmarHasTefra = true
		end
	end
	check(not valmarHasTefra, "ningún lugar de Valmar apunta a una marca de Tefra")
end

---------------------------------------------------------------------
print("\n▶ 3. La historia de Tefra con el motor de verdad")
---------------------------------------------------------------------
local H = require("./lib/StoryHarness")
local profiles = H.profiles
H.boot()
local Quests = H.Quests
local EPISODE = { "Tefra_01_Caida", "Tefra_02_Casa", "Tefra_03_Lista", "Tefra_04_Pozos", "Tefra_05_OtroLado", "Tefra_06_Lanza", "Tefra_07_Tregua" }
local CHAINS = { "Tefra_Brasa", "Tefra_Papeles", "Tefra_Candados" }
do
	local problems = H.loadModule(H.ROOT .. "/shared/LifeStory/Validate").run()
	local mine = {}
	for _, p in problems do
		if p:find("Tefra", 1, true) then
			table.insert(mine, p)
			print("    " .. p)
		end
	end
	check(#mine == 0, "las misiones de Tefra pasan la validación del motor")
	local onlyTefra = true
	local function placeOf(step: any)
		if type(step) ~= "table" then
			return
		end
		for _, key in { "Place", "Respawn" } do
			local p = step[key]
			if type(p) == "string" and p:sub(1, 6) ~= "Tefra_" then
				onlyTefra = false
				print("    lugar de Valmar en una misión de Tefra: " .. p)
			end
		end
		for _, a in step.Actors or {} do
			if a.Place and a.Place:sub(1, 6) ~= "Tefra_" then
				onlyTefra = false
				print("    actor en un lugar de Valmar: " .. a.Place)
			end
		end
		for _, child in step.Steps or {} do
			placeOf(child)
		end
	end
	local planetReq = true
	local allIds = table.clone(EPISODE)
	for _, id in CHAINS do
		table.insert(allIds, id)
	end
	for _, id in allIds do
		local q = Quests[id]
		planetReq = planetReq and q ~= nil and q.Requires and q.Requires.Planet == "Tefra" and q.Offer and q.Offer.Place:sub(1, 6) == "Tefra_"
		for _, step in (q and q.Steps) or {} do
			placeOf(step)
		end
		for _, prop in (q and q.Props) or {} do
			placeOf(prop)
		end
	end
	check(planetReq, "todas piden estar en Tefra (Requires.Planet) y se ofrecen en un sitio de Bastión Ceniza")
	check(onlyTefra, "ningún paso, actor ni objeto de Tefra manda a un sitio de Valmar")
	local canon = true
	for _, id in EPISODE do
		canon = canon and Quests[id].Canon == true
	end
	check(canon, "las siete del episodio son canónicas (marca dorada, empiezan solas al llegar)")
end

-- Ir al sitio, aceptar si se ofrece, y jugarla entera
local function playTefra(player, id: string): boolean
	local story = profiles[player].Story
	local q = Quests[id]
	for _ = 1, 12 do
		if story.Active[id] or story.Completed[id] then
			break
		end
		player.At = q.Offer.Place
		H.passTime(player, 5)
		for _, m in player.Inbox do
			if m.Kind == "Offer" and not m.Answered then
				m.Answered = true
				H.fromClient(player, "Offer", m.Payload.QuestId, m.Payload.QuestId == id)
			end
		end
	end
	return story.Completed[id] ~= nil or (story.Active[id] ~= nil and H.playQuest(player, id, 220))
end

if process.args[1] ~= "rapido" then -- (rapido: sin jugar las misiones enteras)
	-- Sin estar en Tefra no se ofrece nada (ni en el sitio)
	local valmar = H.newPlayer("Valmareña", "Adulto", 9999)
	valmar.At = "Tefra_Plataforma"
	H.passTime(valmar, 5)
	H.passTime(valmar, 5)
	local story = profiles[valmar].Story
	check(story.Active.Tefra_01_Caida == nil and story.Completed.Tefra_01_Caida == nil, "en Valmar, Tefra_01 no empieza (aunque el sitio exista)")
	local marks = valmar:GetAttribute("CanonMarks") or "[]"
	check(not marks:find("Tefra_", 1, true), "ni sale su marca dorada")
	H.leave(valmar)

	-- Rama A: ayudar a Brasa, llevárselo todo, sacar a Orsi, contárselo a Tobi, apoyar a Dalia
	local a = H.newPlayer("Ana", "Adulto", 9999)
	a:SetAttribute("Planeta", "Tefra")
	a.Picks = { TefraBrasa = "Ayudar", TefraPapelesDesertores = "Todo", TefraOrsi = "Sacar", TefraTobiLanza = "Contar", TefraApoyoDalia = "Apoyar", TefraMurria = "Hablar", TefraFerra = "Favor" }
	local all = true
	for _, id in EPISODE do
		local ok = playTefra(a, id)
		all = all and ok
		if not ok then
			print("    ❌ no termina: " .. id)
			break
		end
	end
	check(all, "rama A: el episodio «Ceniza en Bastión» se juega entero (7 misiones)")
	local dataA = profiles[a]
	local storyA = dataA.Story
	check(storyA.Flags.TreguaTefra and storyA.World and storyA.World["Tefra.Tregua"] == true and storyA.World["Tefra.Lanza"] == "Caida",
		"al acabar: tregua (marca y memoria del mundo) y la Lanza caída")
	check(dataA.Items.BufandaAda == 1 and dataA.Items.InsigniaDalia == 1 and dataA.Items.RecetaTraje3 == 1 and dataA.Items.CartaTobi == 1 and dataA.Items.EscudoNaveTefra == 1,
		"la bufanda de Ada, la insignia de Dalia, la receta del traje, el escudo de nave y la carta de Tobi (se lo contaste)")
	check(dataA.Items.TrajeRefrigerado2 == 1 and (dataA.Items.GelTermico or 0) >= 2, "el primer equipo contra el calor llega en la misión 1 (Fermina)")
	check(storyA.Memories.LlegadaTefra and storyA.Memories.AltoElFuego and storyA.Memories.LaLanza, "y los recuerdos del episodio")
	check(storyA.Choices.TefraOrsi and storyA.Choices.TefraOrsi.V == "Sacar" and storyA.Flags.OrsiVive and storyA.Flags.ApoyasteADalia, "las decisiones quedan guardadas")
	check(H.said(a, "Tú también nos disparabas, Dalia.") and H.said(a, "…Te perdono, Dalia. No por ti. Por mí. Ya pesaba demasiado."), "el momento fuerte con Tobi y el perdón de Fermina (rama de apoyar)")
	check(H.said(a, "¡Las torretas ya no os ven!"), "Orsi sabotea la Lanza desde dentro (rama de sacarle)")
	local chains = true
	for _, id in CHAINS do
		local ok = playTefra(a, id)
		chains = chains and ok
		if not ok then
			print("    ❌ no termina: " .. id)
		end
	end
	check(chains, "las tres cadenas secundarias se juegan enteras (El padre de Brasa, Papeles, Candados)")
	check(dataA.Items.DibujoBrasa == 1 and dataA.Items.PapelesTefra == 1 and dataA.Items.CandadoAda == 1 and storyA.Flags.BrasaVendedora and storyA.Flags.ArmeriaAbierta,
		"lo que dejan: el dibujo de Brasa, los papeles de Bastión y la llave del candado de Ada")
	check(H.said(a, "Ya está. Ahora ya sabe que volví."), "Candados acaba con Cosme en silencio en el puente")
	print(("    dinero ganado en el episodio y las cadenas: %d €"):format(dataA.Money))
	check(dataA.Money >= 600 and dataA.Money <= 2500, "la paga de la historia es razonable para ~2 h (ni de más ni de menos)")

	-- Rama B: dejar a Brasa, solo las órdenes, dejar a Orsi, callar, quedarse atrás
	local b = H.newPlayer("Beto", "Adulto", 9999)
	b:SetAttribute("Planeta", "Tefra")
	b.Picks = { TefraBrasa = "Dejar", TefraPapelesDesertores = "Ordenes", TefraOrsi = "Dejar", TefraTobiLanza = "Callar", TefraApoyoDalia = "Atras", TefraFerra = "Delatar" }
	local allB = true
	for _, id in EPISODE do
		allB = allB and playTefra(b, id)
	end
	check(allB, "rama B: el episodio también se juega entero con las otras decisiones")
	local dataB = profiles[b]
	check(dataB.Items.CartaTobi == nil and H.said(b, "De Ovilla no llega ninguna carta."), "si callaste ante Tobi, no llega su carta")
	check(H.said(b, "Hemos salido. Él no.") and not H.said(b, "¡Las torretas ya no os ven!"), "si dejaste a Orsi, Dalia lo cuenta y tú apagas las torretas")
	check(H.said(b, "Lo sé. Y no puedo. Hoy no. Quizá nunca."), "si te quedaste atrás, Fermina no perdona a Dalia")
	b.At = "Tefra_PuestoHollin"
	H.passTime(b, 5)
	check(profiles[b].Story.Active.Tefra_Brasa == nil and not H.received(b, "Offer", "El padre de Brasa"), "«El padre de Brasa» solo se abre si ayudaste a Brasa")
	check(playTefra(b, "Tefra_Papeles") and dataB.Story.Flags.LumoDelatado, "Papeles con la otra decisión (delatar a Lumo)")

	local saveProblems = H.saveProblems()
	check(#saveProblems == 0, "las partidas se pueden guardar (SaveCheck) " .. table.concat(saveProblems, "; "))
	H.leave(a)
	H.leave(b)
end

---------------------------------------------------------------------
print("\n▶ 4. Los oficios (TefraJobService)")
---------------------------------------------------------------------
local fakeT = 1000
local profile = {
	Money = 0,
	Stats = { TasksDone = 0 },
	Items = {},
	Careers = {},
	Space = { Chispas = 0, Ore = { Obsidiana = 2 } },
	Story = { Counters = {}, Flags = {} },
	Hunger = 100,
	Energy = 100,
}
local log = { Knock = 0, Spent = 0, Games = 0, Dialogs = 0, Refresh = 0, Teleports = 0 }
local wirePick = "right" -- "right" | "wrong"
local gameWon = true
L.services.Lighting = { ClockTime = 12 }
L.services.Players = { GetPlayers = function()
	return {}
end, PlayerRemoving = { Connect = function() end } }
L.mock("src/server/Services/DataService", {
	get = function()
		return profile
	end,
	addMoney = function(_, n)
		profile.Money += n
		return true
	end,
	spend = function(_, n)
		if profile.Money < n then
			return false
		end
		profile.Money -= n
		log.Spent += n
		return true
	end,
})
L.mock("src/server/Services/InventoryService", {
	add = function(_, id, n)
		profile.Items[id] = (profile.Items[id] or 0) + (n or 1)
		return true
	end,
	remove = function(_, id, n)
		profile.Items[id] = math.max(0, (profile.Items[id] or 0) - (n or 1))
		return true
	end,
	count = function(_, id)
		return profile.Items[id] or 0
	end,
	onUse = function() end,
})
L.mock("src/server/Services/NeedsService", { change = function() end, canWork = function()
	return true
end, refreshSpeed = function()
	log.Refresh += 1
end })
L.mock("src/server/Services/MonetizationService", { payMultiplier = function()
	return 1
end })
L.mock("src/server/Services/SpaceService", { spaceData = function()
	return profile.Space
end })
L.mock("src/server/Services/LifeService", { allows = function()
	return true
end })
L.mock("src/server/Services/JobService", { setHandler = function() end, quit = function() end })
L.mock("src/server/World/PlanetWorld", { folder = function()
	return L.workspace
end })
L.mock("src/server/Services/MiniGameService", {
	start = function(_, spec, onDone)
		log.Games += 1
		onDone({ Won = gameWon, Score = if gameWon then spec.Rounds else 0 })
		return true
	end,
	cancel = function() end,
})
L.mock("src/server/Services/DialogueService", {
	play = function(_, dialogue, ctx, onDone)
		log.Dialogs += 1
		-- Como un jugador: lee las frases y elige; en el puzle de los cables, lee la pista
		local wires, clue = nil, nil
		for _, line in dialogue.Lines do
			if type(line.T) == "string" then
				local a, b, c = line.T:match("izquierda a derecha: (%S+), (%S+) y (%S+)%.$")
				if a then
					wires = { a, b, c }
				end
				clue = line.T:match("«(.+)»$") or clue
			end
			if line.Options then
				local pick = 1
				if wires and clue then
					local right = solveClue(wires, clue) or 1
					pick = if wirePick == "right" then right else (right % 3 + 1)
				end
				ctx.apply(line.Options[pick].Effects, "/o")
			end
		end
		onDone()
		return true
	end,
})
L.mock("src/server/Services/TefraService", {
	knockDown = function()
		log.Knock += 1
	end,
	recentRaid = function()
		return nil
	end,
})
local Jobs = L.load("src/server/Services/TefraJobService")
Jobs.Clock = function()
	return fakeT
end
local worker = L.player("Obrera", 4242)
local root = roblox.Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Position = Vector3.new(Tefra.Origin.X, 100, Tefra.Origin.Z)
worker.Character = {
	FindFirstChild = function(_, name)
		return if name == "HumanoidRootPart" then root else nil
	end,
	FindFirstChildOfClass = function()
		return nil
	end,
}
worker:SetAttribute("Planeta", "Tefra")

-- Va al objetivo de la fase y deja pasar un poco de tiempo (como un jugador andando)
local function walkTo(target: Vector3?, seconds: number?)
	if not target then
		return
	end
	fakeT += seconds or 8
	root.Position = target + Vector3.new(0, 3, 0)
	Jobs._tick()
	task.wait(0.02)
end
local function shift()
	return Jobs._shifts[worker]
end
-- Juega encargos hasta cobrar n veces (o rendirse)
local function work(jobId: string, n: number): boolean
	local before = profile.Careers[jobId] and profile.Careers[jobId].Tasks or 0
	for _ = 1, 60 * n do
		local s = shift()
		if not s then
			return false
		end
		walkTo(s.Target, 15)
		if (profile.Careers[jobId] and profile.Careers[jobId].Tasks or 0) >= before + n then
			return true
		end
	end
	return false
end

do
	check(Jobs.start(worker, "TefraFundidor") and worker:GetAttribute("Job") == "TefraFundidor" and typeof(worker:GetAttribute("TaskTarget")) == "Vector3",
		"el tablón «Trabajar» empieza el turno de fundidor (Job, TaskTarget y TaskText para el HUD y el GPS)")
	check(shift().Phase == "Cargar", "fase 1: cargar el mineral")
	walkTo(shift().Target)
	check(shift().Phase == "Crisol", "fase 2: el crisol")
	walkTo(shift().Target)
	check(shift().Phase == "Molde" and log.Games == 1, "la temperatura del crisol es un minijuego (aguja)")
	local money = profile.Money
	walkTo(shift().Target, 30)
	check(profile.Money > money and profile.Careers.TefraFundidor.Tasks == 1 and profile.Careers.TefraFundidor.Points >= 1, ("cobra (%d €) y suma a la carrera (data.Careers)"):format(profile.Money - money))
	check(shift() and shift().Phase == "Cargar", "y empieza el siguiente encargo")

	-- Trampas: acabar demasiado rápido no cobra
	local m2 = profile.Money
	walkTo(shift().Target, 0)
	walkTo(shift().Target, 0)
	walkTo(shift().Target, 0)
	check(profile.Money == m2 and profile.Careers.TefraFundidor.Tasks == 1, "un encargo hecho demasiado rápido no se paga (tiempo mínimo)")
	fakeT += 60
	-- Sube de rango trabajando
	check(work("TefraFundidor", 14), "el fundidor sigue trabajando")
	local _, rank = TefraJobs.rankFor(profile.Careers.TefraFundidor.Points)
	check(rank.Id ~= "Aprendiz", ("sube de rango: %s con %d puntos"):format(rank.Name, profile.Careers.TefraFundidor.Points))
	check(log.Dialogs >= 2, ("encargos con historia: %d decisiones en el turno"):format(log.Dialogs))
	check((profile.Items.CuarzoMalva or 0) >= 1, ("a veces te llevas cuarzo malva (%d)"):format(profile.Items.CuarzoMalva or 0))

	-- Desactivador: cables correctos
	check(Jobs.start(worker, "TefraDesactivador"), "cambio a desactivador (deja el oficio de antes)")
	check(shift().Phase == "Detectar", "el detector te lleva a la zona")
	local b = shift().Data.B
	walkTo(Jobs.worldPoint(b.X, b.Z, b.Out))
	check(shift().Phase == "Bomba", "al acercarte, el sitio exacto")
	local chispas = profile.Space.Chispas
	local m3 = profile.Money
	walkTo(shift().Target)
	check(shift().Phase == "Polvorin", "pista leída, cable bueno y pulso firme: a llevar la carcasa al polvorín")
	walkTo(shift().Target, 40)
	check(profile.Money > m3 and profile.Space.Chispas == chispas + 1, "cobra y gana una ✨ Chispa (oficio peligroso)")
	-- Cable equivocado: ¡BUM! sin daño y sin paga
	wirePick = "wrong"
	local knocks = log.Knock
	local m4 = profile.Money
	local bb = shift().Data.B
	walkTo(Jobs.worldPoint(bb.X, bb.Z, bb.Out), 40)
	walkTo(shift().Target)
	check(log.Knock == knocks + 1 and profile.Money == m4, "cable equivocado: ¡BUM! (Derribado, sin daño) y no cobra")
	wirePick = "right"
	task.wait(2.7)
	check(shift() and shift().Phase == "Detectar", "y luego le dan otra bomba")

	-- Bombero: con tiempo, y sin tiempo
	check(Jobs.start(worker, "TefraBombero") and shift().Phase == "Aviso", "bombero de coladas: el aviso")
	walkTo(shift().Target, 40)
	check(shift().Phase == "Barreras" and #Jobs.hotSpots() > #TefraJobs.Foundries, "la colada está ahí (y calienta: hotSpots)")
	walkTo(shift().Target, 5)
	walkTo(shift().Target, 5)
	walkTo(shift().Target, 5)
	check(shift().Phase == "Enfriar", "tres barreras a tiempo")
	local m5 = profile.Money
	walkTo(shift().Target, 5)
	check(profile.Money > m5 and #Jobs.hotSpots() == #TefraJobs.Foundries, "agua a presión: cobra y la colada se apaga")
	walkTo(shift().Target, 40)
	check(shift().Phase == "Barreras", "otra colada")
	fakeT += TefraJobs.BarrierSeconds + 5
	Jobs._tick()
	task.wait(0.6)
	check(shift().Phase == "Aviso" or shift().Phase == "", "si se acaba el tiempo de las barreras, falla (sin perder nada) y vuelve a empezar")

	-- Correo: la patrulla
	check(Jobs.start(worker, "TefraCorreo"), "correo de túnel")
	walkTo(shift().Target, 40)
	check(shift().Phase == "Tunel", "con la saca, a la boca del túnel")
	-- Ponerse delante de una patrulla
	fakeT += 10
	local px, pz = TefraJobs.patrolAt(TefraJobs.Patrols[1], fakeT)
	root.Position = Jobs.worldPoint(px, pz) + Vector3.new(0, 3, 0)
	profile.Money += 50
	local m6 = profile.Money
	Jobs._tick()
	check(shift().Phase == "Saca" and profile.Money == m6 - TefraJobs.CaughtFine, "la patrulla te ve: multa y vuelta a la estafeta")
	-- Con papeles de Bastión, te dejan seguir
	profile.Items.PapelesTefra = 1
	walkTo(shift().Target, 10)
	fakeT += 10
	px, pz = TefraJobs.patrolAt(TefraJobs.Patrols[1], fakeT)
	root.Position = Jobs.worldPoint(px, pz) + Vector3.new(0, 3, 0)
	local m7 = profile.Money
	Jobs._tick()
	check(shift().Phase == "Tunel" and profile.Money == m7, "con los Papeles de Bastión la patrulla te deja seguir")
	check(work("TefraCorreo", 1), "y la carta se entrega")

	-- Comunes de la galaxia: la experiencia local de Tefra
	check(Jobs.start(worker, "GalaxiaRescatista") and work("GalaxiaRescatista", 2), "rescatista: escombros → levantar → hospital")
	check(profile.Careers.GalaxiaRescatista.Local and profile.Careers.GalaxiaRescatista.Local.Tefra == 2, "los oficios de la galaxia guardan la experiencia de Tefra (Local.Tefra)")
	check(Jobs.start(worker, "GalaxiaIngeniero") and work("GalaxiaIngeniero", 2), "ingeniero de obras: bloques → Muralla → prueba de carga")

	-- Salir de Tefra deja el oficio
	worker:SetAttribute("Planeta", nil)
	Jobs._tick()
	check(shift() == nil and worker:GetAttribute("Job") == nil and worker:GetAttribute("TaskTarget") == nil, "al salir de Tefra se deja el oficio (sin TaskTarget colgando)")
	check(not Jobs.start(worker, "TefraFundidor"), "y en Valmar los tablones de Tefra no contratan")
	local ok = pcall(function()
		serde.encode("json", profile.Careers)
	end)
	check(ok, "la carrera se guarda como datos normales (JSON)")
end

---------------------------------------------------------------------
print("\n▶ 5. La vida de Tefra: calor, bombardeos y la Forja (TefraService)")
---------------------------------------------------------------------
do
	local events = {}
	local StoryEvents = L.load("src/server/LifeStory/StoryEvents")
	StoryEvents.connect(function(player, name, payload)
		table.insert(events, { P = player, Name = name, Payload = payload })
	end)
	local playersList = {}
	L.services.Players = { GetPlayers = function()
		return playersList
	end, PlayerRemoving = { Connect = function() end } }
	L.mock("src/server/Services/SceneService", { teleportTo = function(player, target)
		log.Teleports += 1
		player.Character.Root.Position = target
	end })
	L.mock("src/server/Services/AirCombatService", { world = function()
		return nil
	end })
	L.mock("src/server/Services/TefraJobService", { hotSpots = function()
		return {}
	end })
	L.mock("src/server/Services/TefraService", nil)
	L.reset("src/server/Services/TefraService")
	local Life = L.load("src/server/Services/TefraService")
	local clock = 5000
	Life.Clock = function()
		return clock
	end
	local base = Tefra.Origin.Y + Tefra.padY()
	local function person(name: string, id: number)
		local p = L.player(name, id)
		local r = roblox.Instance.new("Part")
		local hum = { Health = 100, MaxHealth = 100 }
		p.Character = {
			Root = r,
			Hum = hum,
			FindFirstChild = function(_, n)
				return if n == "HumanoidRootPart" then r else nil
			end,
			FindFirstChildOfClass = function(_, c)
				return if c == "Humanoid" then hum else nil
			end,
		}
		p:SetAttribute("Planeta", "Tefra")
		table.insert(playersList, p)
		return p
	end
	local function at(p, lx: number, lz: number, y: number?)
		p.Character.Root.Position = Tefra.toWorld(lx, lz, base + (y or 3))
	end
	local function run(seconds: number)
		local n = math.floor(seconds / Life.Tick + 0.5)
		for _ = 1, n do
			clock += Life.Tick
			Life._tick(Life.Tick)
		end
		task.wait(0.05)
	end
	local function emitted(p, name: string, key: string?, value: any?): boolean
		for _, e in events do
			if e.P == p and e.Name == name and (key == nil or e.Payload[key] == value) then
				return true
			end
		end
		return false
	end

	local hot = person("Calor", 7001)
	profile.Story.Counters.TefraSegundos = 99999 -- (sin la ayuda de las primeras horas)
	at(hot, 0, 224) -- junto al Canal de la Forja
	run(4)
	local h1 = Life.heatOf(hot)
	check(h1 > 4 and hot:GetAttribute("TefraCalor") ~= nil, ("junto al canal de lava el calor sube (%d en 4 s) y se ve en el HUD (TefraCalor)"):format(h1))
	run(13)
	check(hot:GetAttribute("TefraFase") ~= "Normal" and emitted(hot, "HeatChanged", "Phase", "Aviso"), "llega a Aviso y se avisa a la historia (HeatChanged)")
	check(hot:GetAttribute("HeatSlow") ~= nil and hot:GetAttribute("HeatSlow") < 1 and log.Refresh > 0, "con calor se anda más lento (HeatSlow → NeedsService)")
	run(60)
	local hum = hot.Character.Hum
	check(hum.Health >= TefraHeat.KnockHealth - 1, ("en Peligro pierde vida poco a poco, pero nunca baja de %d (vida %d)"):format(TefraHeat.KnockHealth - 1, math.floor(hum.Health)))
	check(log.Teleports >= 1 and Life.heatOf(hot) <= TefraHeat.AfterKnock + 5, "con el medidor lleno, el calor te DERRIBA: despiertas en un refugio (sin morir)")
	local lx, lz = Tefra.toLocal(hot.Character.Root.Position)
	check(TefraCity.shelterAt(lx, lz) ~= nil, "y el sitio donde despiertas es dentro de un refugio")
	run(20)
	check(Life.heatOf(hot) == 0 and hot:GetAttribute("TefraFase") == "Normal" and emitted(hot, "HazardSurvived", "Hazard", "Calor"), "dentro del refugio se enfría del todo (HazardSurvived: Calor)")

	-- El traje y el gel
	local suit = person("Traje", 7002)
	at(hot, 0, 224)
	at(suit, 2, 224)
	profile.Items = { TrajeRefrigerado3 = 1 }
	Life._heat[hot] = nil
	Life._heat[suit] = nil
	-- (los dos comparten el perfil del doble: primero sin traje, luego con)
	profile.Items = {}
	run(6)
	local noSuit = Life.heatOf(hot)
	Life._heat[hot] = nil
	profile.Items = { TrajeRefrigerado3 = 1 }
	run(6)
	local withSuit = Life.heatOf(hot)
	check(withSuit < noSuit, ("con el traje refrigerado sube menos (%d contra %d)"):format(withSuit, noSuit))
	profile.Items = { GelTermico = 1 }
	Life._heat[hot].Heat = 80
	check(Life.useGel(hot) and Life.heatOf(hot) == 40 and (profile.Items.GelTermico or 0) == 0, "el gel térmico baja 40 de golpe y se gasta")
	local before = Life.heatOf(hot)
	run(4)
	check(Life.heatOf(hot) - before < noSuit * 4 / 6 / 2, ("y durante un rato el calor casi no sube (+%d en 4 s)"):format(Life.heatOf(hot) - before))
	at(suit, 0, 0)
	at(hot, 0, 0)
	-- En la nave o fuera de Tefra, nada
	hot:SetAttribute("Planeta", nil)
	run(1)
	check(hot:GetAttribute("TefraCalor") == nil and hot:GetAttribute("HeatSlow") == nil, "fuera de Tefra no hay medidor ni frenazo")
	hot:SetAttribute("Planeta", "Tefra")

	-- Bombardeo
	table.clear(events)
	local zones = TefraWar.pickZones(1, 1)
	local z = zones[1]
	local outside = person("Fuera", 7003)
	local inside = person("Dentro", 7004)
	local watching = person("Escena", 7005)
	at(outside, z.X, z.Z)
	local rx, rz = TefraCity.shelterInside("Tefra_Refugio")
	at(inside, rx, rz)
	at(watching, z.X, z.Z)
	watching:SetAttribute("InScene", true)
	at(hot, 0, 0)
	at(suit, 0, 0)
	L.workspace:SetAttribute("Day", 1)
	local teleports = log.Teleports
	local r = Life.startRaid("1:1", 1, 2)
	local war = serde.decode("json", L.workspace:GetAttribute("TefraWar"))
	check(r ~= nil and war.State == "Aviso" and #war.Zones == 3, "sirenas: aviso con tres zonas (atributo TefraWar para el HUD)")
	run(3)
	check(Life.raidState() == "Fuego", "a los segundos del aviso, fuego")
	local booms, safeBooms = 0, true
	for _, d in L.workspace:GetDescendants() do
		if d:IsA("Explosion") then
			booms += 1
			safeBooms = safeBooms and d.BlastPressure == 0 and d.DestroyJointRadiusPercent == 0
		end
	end
	check(booms > 0 and safeBooms, ("las explosiones (%d) no hacen daño (BlastPressure y DestroyJointRadiusPercent a 0)"):format(booms))
	check(log.Teleports == teleports + 1, "quien está en una zona y al descubierto cae «Derribado» una vez (a un refugio)")
	run(TefraWar.FireSeconds + 1)
	check(Life.raidState() == "Despues", "después del fuego, «después»")
	check(emitted(inside, "HazardSurvived", "Hazard", "Bombardeo") and not emitted(outside, "HazardSurvived", "Hazard", "Bombardeo"), "quien estaba en el refugio sobrevive al bombardeo (HazardSurvived); a quien alcanzó, no")
	check(not emitted(watching, "HazardSurvived", "Hazard", "Nada") and log.Teleports == teleports + 1, "a quien estaba en mitad de una escena no se le toca")
	check(Life.recentRaid() ~= nil, "los oficios saben que acaba de haber un bombardeo (paga extra)")
	-- Pan de sirena
	profile.Items = {}
	Life.prompt(inside, "PanSirena")
	Life.prompt(inside, "PanSirena")
	check(profile.Items.PanSirena == 1, "en la Panadería del Ovillo, un pan de sirena por persona y bombardeo")
	run(TefraWar.AfterSeconds + 2)
	check(Life.raidState() == nil and L.workspace:GetAttribute("TefraWar") == nil, "y luego vuelve la calma")
	-- El horario y la tregua
	Life._reset()
	local lead = TefraWar.gameHours(TefraWar.WarnSeconds, Config.DayLengthMinutes)
	L.services.Lighting.ClockTime = 9 - lead / 2
	L.workspace:SetAttribute("Day", 4)
	run(0.5)
	check(Life.raidState() == "Aviso", "a las 9 de Tefra (menos las sirenas) empieza el bombardeo de la mañana")
	Life._reset()
	profile.Story.Flags.TreguaTefra = true
	run(0.5)
	check(Life.raidState() == nil, "con la tregua (todos los de Tefra vieron el alto el fuego), ese día no hay bombardeo")
	profile.Story.Flags.TreguaTefra = nil
	L.services.Lighting.ClockTime = 12

	-- La Forja
	profile.Money = 500
	profile.Items = { LiquenTermico = 1, AzufreNegro = 3, CuarzoMalva = 4, ObsidianaIgnea = 3 }
	local okGel = Life.craft(hot, "GelTermico")
	check(okGel and profile.Items.GelTermico == 2 and profile.Items.LiquenTermico == 0, "Forja: liquen + azufre → 2 geles térmicos")
	local okNo, whyNo = Life.craft(hot, "TrajeRefrigerado3")
	check(not okNo and whyNo:find("receta", 1, true) ~= nil, "sin la receta no se puede el traje de nivel 3")
	profile.Items.RecetaTraje3 = 1
	check(Life.craft(hot, "TrajeRefrigerado3") and profile.Items.TrajeRefrigerado3 == 1 and profile.Items.RecetaTraje3 == 1, "con la receta del episodio, sí (y la receta no se gasta)")
	check(Life.craft(hot, "TrajeRefrigerado2") and profile.Items.TrajeRefrigerado2 == 1, "el traje de nivel 2 lo puede hacer cualquiera")
	check(Life.craft(hot, "Refinar") and profile.Space.Ore.Obsidiana == 1 and profile.Items.ObsidianaIgnea == 1, "refinar: la obsidiana de la bodega de la nave pasa a la mochila")
	check(emitted(hot, "ItemCrafted", "Item", "GelTermico"), "fabricar avisa a la historia (ItemCrafted)")
	-- El invernadero
	profile.Items = {}
	Life.prompt(hot, "Invernadero")
	Life.prompt(hot, "Invernadero")
	check(profile.Items.LiquenTermico == 1 and profile.Items.SetaCeniza == 1, "el invernadero da liquen y setas (con espera entre una vez y otra)")
end

---------------------------------------------------------------------
print("\n▶ 6. Valmar no cambia")
---------------------------------------------------------------------
do
	local Gameplay = L.load("src/shared/Gameplay")
	local plain = Gameplay.walkSpeed({ Stage = 16 })
	check(plain == 16 and Gameplay.walkSpeed({ Stage = 16, Heat = nil }) == 16 and Gameplay.walkSpeed({ Stage = 16, Heat = 0.72 }) < 16, "la velocidad al andar solo cambia con el calor de Tefra")
	local Conditions = L.load("src/shared/LifeStory/Conditions")
	local ctx = { Stage = "Adulto", ClockTime = 12, Weekday = 1, Completed = {}, Flags = {}, Choices = {}, Discovered = {} }
	check(Conditions.check({ Stage = { Min = "Adulto" } }, ctx) and not Conditions.check({ Planet = "Tefra" }, ctx), "los requisitos de siempre no cambian; Planet pide estar en el planeta")
	ctx.Planet = "Tefra"
	check(Conditions.check({ Planet = "Tefra" }, ctx) and not Conditions.check({ Premium = true }, ctx), "en Tefra, sí; y Premium pide el pase (no hay nada de pago en estas misiones)")
	check(Config.Jobs.Barista.Pay == 25 and Config.Jobs.Reponedor.Pay == 30 and Config.DayLengthMinutes == 20 and Config.DataStoreName ~= nil, "las pagas de Valmar, el día y el guardado siguen igual")
end

L.failures += H.failures
L.finish("test-tefra")
process.exit(if L.failures > 0 then 1 else 0)
