-- Prueba de la ESCENIFICACIÓN AUTOMÁTICA de las conversaciones (StageDirector, paquete P5).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-stagedirector.luau
--
-- Comprueba:
--   1. Pausas por la puntuación: «…» = 0,6 s, «.» al final de frase = 0,3 s; cuántas letras se ven en
--      cada momento (la caja y el bocadillo se paran a la vez).
--   2. Acotaciones «(susurrando) …» → acción (voz baja, teléfono, desde lejos, mirada, gesto) y texto limpio.
--   3. Token de género {o/a}: chico, chica y sin saber (nunca el doblete «o encargada»).
--   4. Planos: nombres válidos, el plano que elige el director línea a línea, reacción en las preguntas.
--   5. Geometría de los planos (hombro, primer plano, general…) y CameraShots.preset si existe (o falla).
--   6. Reparto, quién se acerca al empezar y dónde se para.
--   7. Validación de los campos nuevos (Pause, Beat, To, Shot, Staging, Stage) y que las misiones de
--      verdad siguen sin errores.
--   8. DialogueService con un cliente de mentira: los campos llegan al cliente, la acotación se hace
--      acción, {o/a} con el atributo Gender, StageApproach se pone y se quita, Staging = false.
--   9. Las 294 escenas de conversación (y las charlas) de verdad pasan por el director sin errores.

local roblox = require("@lune/roblox")
local task = require("@lune/task")
local L =require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local CFrame = L.CFrame
local check = L.check

L.services.Players = {
	GetPlayers = function()
		return {}
	end,
	PlayerRemoving = { Connect = function() end },
	PlayerAdded = { Connect = function() end },
}
L.services.Lighting = { ClockTime = 10 }

local StageDirector = L.load("src/shared/LifeStory/StageDirector")
local Strings = L.load("src/shared/LifeStory/Strings")
local CameraShots = L.load("src/shared/CameraShots")

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

---------------------------------------------------------------------
print("1. Pausas por la puntuación")
---------------------------------------------------------------------
do
	local text = "Yo… no sé si esto es buena idea. Pero tenemos que hacerlo."
	local pauses, tail = StageDirector.pauses(text)
	check(#pauses == 2, ("dos pausas en medio (%d)"):format(#pauses))
	check(pauses[1] and pauses[1].At == 3 and near(pauses[1].Seconds, 0.6), "«Yo…» se para 0,6 s después de los puntos suspensivos")
	check(pauses[2] and near(pauses[2].Seconds, 0.3), "el punto de «buena idea.» se para 0,3 s")
	check(near(tail, 0.3), "el punto final: 0,3 s antes de seguir")
	local _, tail2 = StageDirector.pauses("Pues...")
	check(near(tail2, 0.6), "«...» al final también son 0,6 s")
	local p3, tail3 = StageDirector.pauses("Pesa 3.5 kilos")
	check(#p3 == 0 and tail3 == 0, "un número con punto no es una pausa")
	local p4 = StageDirector.pauses("¿Vienes? ¡Venga!")
	check(#p4 == 1 and near(p4[1].Seconds, 0.3), "una pregunta en medio también hace pausa")
	local p5 = StageDirector.pauses("«Hola.» Y se fue.")
	check(#p5 == 1 and p5[1].At == 7, "las comillas que cierran se escriben antes de parar")
	local none, noneTail = StageDirector.pauses(nil)
	check(#none == 0 and noneTail == 0, "sin texto, sin pausas")

	-- Cuántas letras se ven
	local total = utf8.len(text) :: number
	local speed = 55
	check(StageDirector.revealed(0, speed, total, pauses) == 0, "al empezar no se ve nada")
	check(StageDirector.revealed(3 / speed + 0.3, speed, total, pauses) == 3, "a mitad de la pausa de «…» se queda en «Yo…»")
	check(StageDirector.revealed(3 / speed + 0.61, speed, total, pauses) == 3 + 0, "justo al acabar la pausa sigue escribiendo")
	check(StageDirector.revealed(100, speed, total, pauses) == total, "al final se ve todo")
	check(StageDirector.revealed(1, speed, total, nil) == speed, "sin pausas: letras = segundos × velocidad")
	local seconds = StageDirector.typingSeconds(text, speed)
	check(near(seconds, total / speed + 0.9, 1e-3), ("lo que tarda: texto + pausas (%.2f s)"):format(seconds))
	check(StageDirector.revealed(seconds + 0.01, speed, total, pauses) == total, "en ese tiempo se ha escrito entera")
	-- Pausas escritas
	local b, a = StageDirector.pauseOf({ Pause = 0.8 })
	check(near(b, 0.8) and a == 0, "Pause = 0.8: antes de la frase")
	b, a = StageDirector.pauseOf({ Pause = { Before = 0.2, After = 9 } })
	check(near(b, 0.2) and near(a, StageDirector.MAX_PAUSE), "Pause = { Before, After }, con tope")
	check(StageDirector.beat("Respira") ~= nil and StageDirector.beat("Piensa").Gesture == "ThinkChin", "Beat con nombre: respirar, pensar (mano en la barbilla)")
	check(StageDirector.beat(1.2).Seconds == 1.2 and StageDirector.beat(99).Seconds == StageDirector.MAX_BEAT, "Beat con segundos (con tope)")
	check(StageDirector.beat("Bailar") == nil, "un Beat que no existe no hace nada")
end

---------------------------------------------------------------------
print("2. Acotaciones → acción")
---------------------------------------------------------------------
do
	local clean, d = StageDirector.direction("(susurrando) Si nos pillan, yo solo pasaba por aquí.")
	check(clean == "Si nos pillan, yo solo pasaba por aquí." and d and d.Whisper, "«(susurrando)» → voz baja y fuera del texto")
	clean, d = StageDirector.direction("(al teléfono) ¿Qué tal el primer mes?")
	check(clean == "¿Qué tal el primer mes?" and d and d.Remote == "Telefono", "«(al teléfono)» → habla por teléfono")
	clean, d = StageDirector.direction("(mensaje) Me he quedado en casa.")
	check(d and d.Remote == "Mensaje", "«(mensaje)» → mensaje en el móvil")
	clean, d = StageDirector.direction("(desde lejos) ¡Es verdad! ¡Traigo de todo!")
	check(clean == "¡Es verdad! ¡Traigo de todo!" and d and d.Far, "«(desde lejos)» → plano general")
	clean, d = StageDirector.direction("(Omar levanta el pulgar sin dejar de dibujar)")
	check(d and d.Whole and clean == "Omar levanta el pulgar sin dejar de dibujar" and d.Gesture == "Nod", "acotación entera → la hace (gesto) y queda de subtítulo")
	clean, d = StageDirector.direction("(Rubén, bajito:) Buena suerte. De verdad.")
	check(clean == "Buena suerte. De verdad." and d and d.Whisper, "«(Rubén, bajito:)» → voz baja")
	clean, d = StageDirector.direction("(sin mirarte) Yo iré. Supongo.")
	check(d and d.Look == "Away", "«(sin mirarte)» → aparta la mirada")
	clean, d = StageDirector.direction("(Mateo se pone rojo como un tomate) Vale. Bien. Genial.")
	check(d and d.Look == "Down", "«se pone rojo» → mira al suelo (vergüenza)")
	clean, d = StageDirector.direction("(llorando) No encuentro a mi mamá…")
	check(d and d.Gesture == "Sad", "«(llorando)» → triste")
	clean, d = StageDirector.direction("Hola (esto no es acotación) qué tal")
	check(d == nil and clean == "Hola (esto no es acotación) qué tal", "un paréntesis en medio de la frase se queda")
	clean, d = StageDirector.direction("Sin acotación.")
	check(d == nil and clean == "Sin acotación.", "sin paréntesis no cambia nada")
end

---------------------------------------------------------------------
print("3. Token de género {o/a}")
---------------------------------------------------------------------
do
	local t = "¡Encargad{o/a}! Mi compañer{o/a} de cuarto. {Bienvenido/Bienvenida}, {él/ella} lo sabe."
	check(StageDirector.genderize(t, "M") == "¡Encargado! Mi compañero de cuarto. Bienvenido, él lo sabe.", "chico")
	check(StageDirector.genderize(t, "F") == "¡Encargada! Mi compañera de cuarto. Bienvenida, ella lo sabe.", "chica")
	local unknown = StageDirector.genderize(t, nil)
	check(unknown == "¡Encargado/a! Mi compañero/a de cuarto. Bienvenido/Bienvenida, él/ella lo sabe.", "sin saber: forma corta con barra")
	check(not unknown:find(" o encargada", 1, true), "nunca el doblete «encargado o encargada»")
	check(StageDirector.gender("F") == "F" and StageDirector.gender("Chico") == "M" and StageDirector.gender(nil) == nil, "el atributo Gender se entiende")
	check(Strings.get("Hola, {nombre}. Estás guapísim{o/a}.", { nombre = "Ana", genero = "F" }) == "Hola, Ana. Estás guapísima.", "Strings.get rellena {nombre} y {o/a}")
	check(Strings.get("Contratad{o/a}") == "Contratado/a", "Strings.get sin datos: forma corta")
	check(Strings.get("Hola, {nombre}", {}) == "Hola, {nombre}", "las variables de siempre no cambian")
end

---------------------------------------------------------------------
print("4. Planos que elige el director")
---------------------------------------------------------------------
do
	local parsed = StageDirector.parseShot("Hombro:Yo>Nico")
	check(parsed and parsed.Kind == "Hombro" and parsed.Who[1] == "Yo" and parsed.Who[2] == "Nico", "Hombro:Yo>Nico")
	parsed = StageDirector.parseShot("DosPlanos:Omar,Sara")
	check(parsed and parsed.Who[2] == "Sara", "DosPlanos:Omar,Sara")
	check(StageDirector.parseShot("General") ~= nil, "General")
	check(StageDirector.parseShot("PrimerPlano") == nil, "PrimerPlano sin personaje no vale")
	check(StageDirector.parseShot("Travelling:Nico") == nil, "un plano que no existe no vale")
	check(StageDirector.parseShot("Hombro:Nico") == nil, "Hombro pide dos")

	local st = StageDirector.newState()
	local shots = {}
	local lines = {
		{ Id = "Nico", Text = "¡Hola!" },
		{ Id = "Nico", Text = "Ven." },
		{ Id = "Nico", Text = "Vamos." },
		{ Me = true, Text = "Vale." },
		{ Id = "Omar", To = "Sara", Text = "¿Y tú qué?" },
		{ Id = "Sara", Direction = { Whisper = true }, Text = "Calla." },
		{ Id = "Abu", Direction = { Far = true }, Text = "¡A cenar!" },
		{ Id = "Familia", Direction = { Remote = "Telefono" }, Text = "¿Has comido?" },
		{ Narrator = true, Text = "Pasa el tiempo." },
		{ Id = "Mateo", Shot = "Inserto:Cromo", Text = "Mira." },
	}
	for _, line in lines do
		table.insert(shots, StageDirector.shotFor(st, line) or "-")
	end
	check(StageDirector.establish(StageDirector.newState()) == "General", "al empezar, plano general de situación")
	check(shots[1] == "Hombro:Yo>Nico", "habla Nico: por encima de tu hombro (" .. shots[1] .. ")")
	check(shots[2] == "PrimerPlano:Nico", "sigue Nico: primer plano (" .. shots[2] .. ")")
	check(shots[3] == "Hombro:Yo>Nico", "sigue: vuelve al hombro (no siempre lo mismo)")
	check(shots[4] == "Hombro:Nico>Yo", "hablas tú: contraplano por encima de Nico (" .. shots[4] .. ")")
	check(shots[5] == "DosPlanos:Omar,Sara", "Omar le habla a Sara: plano de los dos")
	check(shots[6] == "PPP:Sara", "susurra: primerísimo primer plano")
	check(shots[7] == "General", "desde lejos: plano general")
	check(shots[8] == "-" and shots[9] == "-", "por teléfono y el narrador no mueven la cámara")
	check(shots[10] == "Inserto:Cromo", "una línea puede pedir su plano (Shot)")
	check(StageDirector.reactionFor({ Id = "Nico", Text = "¿Vienes?" }) == "Reaccion:Yo", "pregunta: plano de reacción sobre ti")
	check(StageDirector.reactionFor({ Id = "Omar", To = "Sara", Text = "¿Y tú qué?" }) == "Reaccion:Sara", "pregunta a Sara: reacción de Sara")
	check(StageDirector.reactionFor({ Id = "Nico", Text = "Ven." }) == nil, "sin pregunta no hay reacción")
	check(StageDirector.reactionFor({ Me = true, Text = "¿Qué?" }) == nil, "tus preguntas no llevan reacción")
end

---------------------------------------------------------------------
print("5. Geometría de los planos")
---------------------------------------------------------------------
do
	local me = Vector3.new(0, 5, 0)
	local nico = Vector3.new(0, 5, -8)
	local sara = Vector3.new(6, 5, -6)
	local positions = { Yo = me, Nico = nico, Sara = sara }
	local function looksAt(cf: any, target: Vector3): number
		return cf.LookVector:Dot((target - cf.Position).Unit)
	end
	local cf, focus = StageDirector.frame("Hombro:Yo>Nico", positions)
	check(cf ~= nil and focus == nico, "hombro: enfoca a Nico")
	check(cf and looksAt(cf, nico) > 0.95, "hombro: la cámara mira a Nico")
	check(cf and (cf.Position - me).Magnitude < 6 and (cf.Position - nico).Magnitude > (cf.Position - me).Magnitude, "hombro: la cámara está junto a ti, detrás")
	cf = StageDirector.frame("PrimerPlano:Nico", positions)
	check(cf and (cf.Position - nico).Magnitude < 6 and looksAt(cf, nico) > 0.9, "primer plano: cerca de Nico y mirándole")
	cf = StageDirector.frame("PPP:Nico", positions)
	check(cf and (cf.Position - nico).Magnitude < 3.5, "primerísimo: aún más cerca")
	cf = StageDirector.frame("General", positions, { From = "Nico" })
	local allIn = cf ~= nil
	for _, p in positions do
		allIn = allIn and looksAt(cf, p) > 0.6
	end
	check(allIn, "general: se ve a todos")
	cf = StageDirector.frame("DosPlanos:Nico,Sara", positions)
	check(cf and looksAt(cf, nico) > 0.6 and looksAt(cf, sara) > 0.6, "de dos: Nico y Sara en plano")
	cf = StageDirector.frame("Reaccion:Yo", positions, { From = "Nico" })
	check(cf and looksAt(cf, me) > 0.9 and (cf.Position - nico).Magnitude < (cf.Position - me).Magnitude + 4, "reacción: te ve desde el lado de Nico")
	check(StageDirector.frame("PrimerPlano:Nadie", positions) == nil, "si falta el personaje, no hay plano (la cámara se queda)")

	-- Con CameraShots.preset (paquete P1): se usa lo que devuelve
	local fake = table.clone(CameraShots)
	local asked = nil
	fake.preset = function(name, actors)
		asked = { name, actors }
		return { Fixed = { "Actor:Nico", Vector3.new(0, 1, -5) }, Look = { "Actor:Nico" }, Duration = 2 }
	end
	local from, to, seconds, focus2 = StageDirector.camera("PrimerPlano:Nico", positions, fake)
	check(asked and asked[1] == "PrimerPlano:Nico" and asked[2].Nico ~= nil and asked[2].Yo ~= nil and asked[2].Player ~= nil, "se le pide el preset con las anclas de todos")
	check(from and to and (to.Position - (nico + Vector3.new(0, 1, -5))).Magnitude < 1e-3 and seconds == 0 and focus2 == nico, "el plano fijo del preset se usa tal cual")
	fake.preset = function()
		return { From = { "Player", Vector3.new(0, 2, 6) }, To = { "Player", Vector3.new(0, 2, 3) }, Look = { "Actor:Nico" }, Duration = 3 }
	end
	from, to, seconds = StageDirector.camera("Medio:Nico", positions, fake)
	check(from and to and (from.Position - to.Position).Magnitude > 2 and seconds == 3, "un travelling (dolly) del preset va de From a To en su Duration")
	fake.preset = function()
		error("preset roto")
	end
	from = StageDirector.camera("PrimerPlano:Nico", positions, fake)
	check(from ~= nil and (from.Position - nico).Magnitude < 6, "si el preset falla, la geometría de siempre")
	fake.preset = function()
		return nil
	end
	from = StageDirector.camera("Hombro:Yo>Nico", positions, fake)
	check(from ~= nil, "si el preset no sabe, la geometría de siempre")
	from = StageDirector.camera("Hombro:Yo>Nico", positions, CameraShots)
	check(from ~= nil, ("sin CameraShots.preset (%s), la geometría de siempre"):format(if CameraShots.preset then "existe" else "aún no existe"))
end

---------------------------------------------------------------------
print("6. Reparto y entradas")
---------------------------------------------------------------------
do
	local cast = StageDirector.castOf({
		{ S = "Narrador", T = "…" },
		{ S = "Nico", T = "Hola" },
		{ S = "Yo", T = "Hola" },
		{ S = "Omar", To = "Sara", T = "Mira" },
		{ Ask = "¿?", Options = { { T = "a", Then = { { S = "Mateo", T = "Vale" } } } } },
		{ S = "Nico", T = "Otra" },
	})
	check(table.concat(cast, ",") == "Nico,Omar,Sara,Mateo", "reparto en orden (también a quien se habla y en las respuestas): " .. table.concat(cast, ","))
	local list = StageDirector.approach({ Nico = 3, Omar = 15, Sara = 200, Mateo = 40 })
	check(table.concat(list, ",") == "Mateo,Omar", "se acercan los que están lejos pero en la escena: " .. table.concat(list, ","))
	local spot = StageDirector.approachSpot(Vector3.new(20, 3, 0), Vector3.new(0, 5, 0))
	check(near(spot.X, StageDirector.APPROACH_STOP) and spot.Y == 3 and near(spot.Z, 0), "se para a unos pasos de ti, a su altura")
end

---------------------------------------------------------------------
print("7. Validación de los campos nuevos")
---------------------------------------------------------------------
do
	local known = function(id)
		return id == "Nico" or id == "Sara"
	end
	local good = { S = "Nico", T = "Hola", Pause = { Before = 0.5, After = 1 }, Beat = "Respira", To = "Sara", Shot = "Hombro:Yo>Nico" }
	check(#StageDirector.problems(good, known) == 0, "una línea bien escrita no tiene problemas")
	check(#StageDirector.problems({ S = "Nico", T = "Hola" }, known) == 0, "el formato viejo sigue valiendo")
	local function has(line, fragment)
		for _, p in StageDirector.problems(line, known) do
			if p:find(fragment, 1, true) then
				return true
			end
		end
		return false
	end
	check(has({ Pause = -1 }, "Pause"), "Pause negativa")
	check(has({ Pause = { Antes = 1 } }, "Pause"), "Pause con un campo mal escrito")
	check(has({ Pause = "mucho" }, "Pause"), "Pause que no es número")
	check(has({ Beat = "Bailar" }, "Beat"), "Beat desconocido")
	check(has({ Beat = 10 }, "Beat"), "Beat demasiado largo")
	check(has({ To = "Fulano" }, "To"), "To a alguien que no está en el reparto")
	check(has({ S = "Nico", To = "Nico" }, "To"), "To a sí mismo")
	check(has({ Shot = "Travelling:Nico" }, "Shot"), "Shot que no existe")
	check(has({ Shot = "PrimerPlano:Fulano" }, "Shot"), "Shot con alguien que no está")
	check(#StageDirector.problems({ Shot = "Inserto:Carta" }, known) == 0, "Inserto: un objeto (no hace falta que sea del reparto)")

	-- Las misiones de verdad: sin errores
	local H = require("./lib/StoryHarness")
	local report = H.loadModule(H.ROOT .. "/shared/LifeStory/Validate").report()
	for _, e in report.Errors do
		print("     " .. e)
	end
	check(#report.Errors == 0, ("las misiones de verdad siguen sin errores (%d)"):format(#report.Errors))
end

---------------------------------------------------------------------
print("8. DialogueService con un cliente de mentira")
---------------------------------------------------------------------
do
	local sent = {}
	local handlers = {}
	local remote = {
		FireClient = function(_, player, kind, payload)
			table.insert(sent, { Player = player, Kind = kind, Payload = payload })
		end,
		OnServerEvent = {
			Connect = function(_, fn)
				table.insert(handlers, fn)
			end,
		},
	}
	local remotes = {
		FindFirstChild = function(_, name)
			return if name == "Dialogue" then remote else nil
		end,
	}
	local rs = L.services.ReplicatedStorage :: any
	rs.WaitForChild = function(_, name)
		return if name == "Remotes" then remotes else nil
	end
	L.services.CollectionService = { GetTagged = function()
		return {}
	end }
	local DialogueService = L.load("src/server/Services/DialogueService")
	DialogueService.init()

	-- Personajes de mentira: un modelo con GetPivot y IsA
	local function model(position: Vector3)
		return {
			Parent = true,
			IsA = function(_, class)
				return class == "Model"
			end,
			GetPivot = function()
				return CFrame.new(position)
			end,
		}
	end
	local actors = { Nico = model(Vector3.new(0, 3, -4)), Sara = model(Vector3.new(0, 3, -20)), Omar = model(Vector3.new(500, 3, 0)) }
	local player = L.player("Ana", 77)
	player.Attributes.Gender = "F"
	local root = { Position = Vector3.new(0, 3, 0) }
	player.Character = {
		FindFirstChild = function(_, name)
			return if name == "HumanoidRootPart" then root else nil
		end,
	}
	local done = false
	local started = DialogueService.play(player, {
		Lines = {
			{ S = "Nico", T = "(susurrando) Eres la encargad{o/a}, {nombre}.", Pause = 0.5, Beat = "Respira", To = "Sara", Shot = "PrimerPlano:Nico" },
			{ S = "Sara", T = "(Sara se ríe)" },
			{ S = "Omar", T = "(al teléfono) ¿Qué tal?", Pause = { After = 1 } },
			{ S = "Narrador", T = "(Ya no la tienes.)" },
		},
	}, {
		actorOf = function(id)
			return actors[id]
		end,
	}, function()
		done = true
	end)
	check(started, "la conversación empieza")
	check(player.Attributes.StageApproach == "Sara", "Sara (a 20 studs) se acerca al empezar; Nico ya está cerca y Omar no está en la escena: " .. tostring(player.Attributes.StageApproach))
	local show = sent[#sent]
	local lines = show and show.Payload.Lines or {}
	check(show and show.Kind == "Show" and show.Payload.Stage == true and show.Payload.Approach and show.Payload.Approach[1] == "Sara", "el primer trozo va escenificado y dice quién se acerca")
	local l1, l2, l3, l4 = lines[1] or {}, lines[2] or {}, lines[3] or {}, lines[4] or {}
	check(l1.Text == "Eres la encargada, Ana.", "la acotación sale del texto y {o/a} con el género del jugador: " .. tostring(l1.Text))
	check(l1.Direction and l1.Direction.Whisper, "«(susurrando)» llega como acción")
	check(l1.Stage and l1.Pause == 0.5 and l1.Beat and l1.Beat.Name == "Respira" and l1.To == "Sara" and l1.ToActor == actors.Sara and l1.Shot == "PrimerPlano:Nico" and l1.Id == "Nico", "Pause, Beat, To (y su modelo), Shot e Id llegan al cliente")
	check(l2.Text == "Sara se ríe" and l2.Direction and l2.Direction.Whole and l2.Emotion == "Laugh", "una acotación entera: subtítulo y el actor se ríe")
	check(l3.Direction and l3.Direction.Remote == "Telefono" and l3.After == 1 and l3.Pause == nil, "por teléfono, con silencio después")
	check(l4.Text == "(Ya no la tienes.)" and l4.Narrator and l4.Direction == nil, "el narrador cuenta como siempre (sus paréntesis se quedan)")
	-- El cliente contesta: se acaba y se quita StageApproach
	for _, fn in handlers do
		fn(player, "Next", show.Payload.Token, nil, show.Payload.Seq)
	end
	task.wait(0.1)
	check(done and player.Attributes.StageApproach == nil and player.Attributes.InDialogue == nil, "al terminar se quita StageApproach (y InDialogue)")

	-- Staging = false: la conversación de siempre
	sent = {}
	DialogueService.play(player, { Staging = false, Lines = { { S = "Nico", T = "Hola.", Pause = 1 } } }, { actorOf = function(id)
		return actors[id]
	end })
	local plain = sent[#sent]
	check(plain and plain.Payload.Stage == nil and plain.Payload.Lines[1].Stage == nil and plain.Payload.Lines[1].Pause == nil, "Staging = false: sin escenificar")
	DialogueService.cancel(player, "prueba")
	check(player.Attributes.StageApproach == nil and not DialogueService.isBusy(player), "al cortarla, todo se quita")
end

---------------------------------------------------------------------
print("9. Todas las conversaciones de verdad pasan por el director")
---------------------------------------------------------------------
do
	local H = require("./lib/StoryHarness")
	local Quests = H.loadModule(H.ROOT .. "/shared/LifeStory/Quests")
	local dialogues, scenes, lineCount, framed, directions, whole, errors = 0, 0, 0, 0, 0, 0, 0
	local function walkLines(list, st)
		for _, line in list or {} do
			if type(line) == "table" then
				if type(line.T) == "string" then
					lineCount += 1
					local narrator = line.S == nil or line.S == "Narrador"
					local text, d = line.T, nil
					if not narrator then
						local ok, clean, dir = pcall(StageDirector.direction, Strings.get(line.T, { nombre = "Ana" }))
						if not ok then
							errors += 1
						else
							text, d = clean, dir
						end
					end
					if d then
						directions += 1
						if d.Whole then
							whole += 1
						end
					end
					local ok, spec = pcall(StageDirector.shotFor, st, {
						Id = if narrator then nil else line.S,
						Me = line.S == "Yo",
						Narrator = narrator,
						To = line.To,
						Shot = line.Shot,
						Direction = d,
						Text = text,
					})
					if not ok then
						errors += 1
					elseif spec then
						framed += 1
						if not StageDirector.parseShot(spec) then
							errors += 1
						end
					end
					local ok2 = pcall(StageDirector.pauses, text)
					if not ok2 then
						errors += 1
					end
				end
				for _, option in line.Options or {} do
					walkLines(option.Then, st)
				end
			end
		end
	end
	local function play(d)
		dialogues += 1
		walkLines(d.Lines or d, StageDirector.newState())
	end
	for _, quest in Quests do
		local named = quest.Dialogues or {}
		for _, d in named do
			play(d)
		end
		local function steps(list)
			for _, s in list or {} do
				if s.Type == "Scene" then
					scenes += 1
					if type(s.Dialogue) == "table" then
						play(s.Dialogue)
					end
				end
				if s.Type == "Group" then
					steps(s.Steps)
				end
			end
		end
		steps(quest.Steps)
	end
	print(("     %d diálogos · %d pasos Scene · %d frases · %d con plano · %d acotaciones convertidas (%d enteras)"):format(dialogues, scenes, lineCount, framed, directions, whole))
	-- (umbrales bajos a propósito: las escenas importantes pasan a escenas del motor, Happenings, y las
	-- acotaciones a A/G/Beat; aquí solo se comprueba que se recorren los datos de verdad)
	check(scenes >= 200, ("están las escenas de conversación (%d)"):format(scenes))
	check(errors == 0, "ninguna frase rompe al director")
	check(framed > lineCount * 0.5, "la mayoría de las frases tienen plano")
	check(directions >= 30, ("las acotaciones escritas de los personajes se convierten en acción (%d)"):format(directions))
end

L.finish("test-stagedirector")
-- (DialogueService deja su vigilante en marcha: se sale aquí)
require("@lune/process").exit(0)
