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
--   9. Las escenas de conversación (y las charlas) de verdad pasan por el director sin errores.
--  10. Fase 2 del diálogo: velocidad del texto (TextSpeed: valores, menú, acompasar con la voz, tecleo,
--      tocar = entera / siguiente), dónde se guarda (SettingsService: data.Audio.TextSpeed y el atributo,
--      sin campo nuevo), el retrato de repuesto (DialogueLook.badge) y que la frase más larga de la
--      historia cabe en la caja y en el subtítulo de un móvil pequeño.

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
	-- Contracciones: solo la preposición suelta (antes «sabía el» salía «sabíal», «enseña el» «enseñal»)
	local A = { nombre = "Ana" }
	check(Strings.get("Vamos a el parque y luego de el cole a casa.", A) == "Vamos al parque y luego del cole a casa.", "«a el» → «al» y «de el» → «del»")
	check(Strings.get("A el final, {nombre} gana.", A) == "Al final, Ana gana.", "al principio de la frase también")
	check(Strings.get("¡A el agua!", A) == "¡Al agua!", "detrás de un signo (¡) también")
	check(Strings.get("Paula se sabía el nombre de cada gallina", A) == "Paula se sabía el nombre de cada gallina", "«sabía el» no se toca (la «a» es de la palabra)")
	check(Strings.get("Sería el reto más grande. Te guiña el ámbar. Marisa te enseña el anuario.", A) == "Sería el reto más grande. Te guiña el ámbar. Marisa te enseña el anuario.", "«sería el», «guiña el», «enseña el» no se tocan")
	check(Strings.get("Sara el lunes; desde el puente.", A) == "Sara el lunes; desde el puente.", "ni detrás de otra letra («Sara el», «desde el»)")
	-- Todas las frases de la historia con «…a el» / «…de el» al final de una palabra con tilde o eñe
	do
		local fs = require("@lune/fs")
		local broken, total = {}, 0
		local function scan(dir: string)
			for _, name in fs.readDir(dir) do
				local path = dir .. "/" .. name
				if fs.isDir(path) then
					scan(path)
				elseif name:match("%.luau$") then
					local function count(s: string): number
						local _, n1 = s:gsub("[\128-\255]a el ", "")
						local _, n2 = s:gsub("[\128-\255]de el ", "")
						return n1 + n2
					end
					for literal in fs.readFile(path):gmatch('"([^"\n]*)"') do
						local before = count(literal)
						if before > 0 then
							total += 1
							if count(Strings.get(literal, A)) ~= before then
								table.insert(broken, literal)
							end
						end
					end
				end
			end
		end
		scan("src/shared/LifeStory")
		check(total > 0 and #broken == 0, ("ninguna frase de la historia pierde letras al rellenarla (%d revisadas%s)"):format(total, if #broken > 0 then ": " .. broken[1] else ""))
	end
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

	-- El vigilante no se adelanta a quien sigue leyendo (auditoría del sistema de cine, bug 2): con la
	-- conversación en pantalla el cliente manda «Alive» y el servidor espera; sin señales, sigue sola
	local timeout, cap, every = DialogueService.Timeout, DialogueService.AliveCap, DialogueService.WatchEvery
	DialogueService.Timeout, DialogueService.WatchEvery = 1, 0.1
	task.wait(DialogueService.WatchEvery + 5.2) -- (el vigilante estaba esperando sus 5 s de antes)
	local function fire(kind: string, ...)
		for _, fn in handlers do
			fn(player, kind, ...)
		end
	end
	local function showsSince(from: number): number
		local n = 0
		for i = from + 1, #sent do
			if sent[i].Kind == "Show" then
				n += 1
			end
		end
		return n
	end
	sent = {}
	local finished = false
	DialogueService.play(player, {
		Staging = false,
		Lines = {
			{ S = "Nico", T = "Hola." },
			{ Ask = "¿Vienes?", Options = { { T = "Sí", Then = { { S = "Nico", T = "¡Bien!" } } }, { T = "No", Then = { { S = "Nico", T = "Vaya." } } } } },
		},
	}, {}, function()
		finished = true
	end)
	local askShow = sent[#sent]
	check(askShow and askShow.Payload.Options and #askShow.Payload.Options == 2, "llega la pregunta con sus dos respuestas")
	local before = #sent
	-- 2,5 s (más del plazo de 1 s) pensando, con la pregunta en pantalla
	for _ = 1, 10 do
		task.wait(0.25)
		fire("Alive", askShow.Payload.Token)
	end
	check(showsSince(before) == 0 and DialogueService.isBusy(player), "con la pregunta en pantalla, el servidor espera tu respuesta (no elige por ti)")
	fire("Next", askShow.Payload.Token, 2, askShow.Payload.Seq)
	local reply = sent[#sent]
	check(reply and reply.Payload.Lines and reply.Payload.Lines[1] and reply.Payload.Lines[1].Text == "Vaya.", "tu respuesta (la segunda) es la que cuenta: " .. tostring(reply and reply.Payload.Lines and reply.Payload.Lines[1] and reply.Payload.Lines[1].Text))
	-- Sin señales (la pantalla se perdió): pasado el plazo, la conversación sigue sola
	task.wait(1.6)
	check(finished and not DialogueService.isBusy(player), "sin señales del cliente, a los Timeout s sigue sola (la historia no se atasca)")
	-- Un «Alive» de otra conversación (u otro token) no alarga nada; y el tope AliveCap se respeta
	DialogueService.AliveCap = 1.5
	finished = false
	DialogueService.play(player, { Staging = false, Lines = { { S = "Nico", T = "Una frase." } } }, {}, function()
		finished = true
	end)
	local only = sent[#sent]
	for _ = 1, 14 do
		task.wait(0.25)
		fire("Alive", only.Payload.Token)
	end
	check(finished and not DialogueService.isBusy(player), "con «Alive» para siempre, el tope AliveCap acaba la conversación igual")
	DialogueService.Timeout, DialogueService.AliveCap, DialogueService.WatchEvery = timeout, cap, every
	-- Fase 3: la caja falló en la pantalla y pide «Again»: se le vuelve a mandar lo último enseguida
	-- (solo de SU conversación y como mucho AgainMax veces)
	DialogueService.play(player, { Staging = false, Lines = { { S = "Nico", T = "Otra vez." } } }, {}, function() end)
	local last = sent[#sent]
	local beforeAgain = #sent
	fire("Again", last.Payload.Token)
	check(showsSince(beforeAgain) == 1 and sent[#sent].Payload.Token == last.Payload.Token, "«Again» (la caja falló en tu pantalla): se vuelve a mandar el trozo enseguida")
	fire("Again", (last.Payload.Token :: number) + 999)
	check(showsSince(beforeAgain) == 1, "«Again» de otra conversación no manda nada")
	for _ = 1, DialogueService.AgainMax + 2 do
		fire("Again", last.Payload.Token)
	end
	check(showsSince(beforeAgain) == DialogueService.AgainMax, ("«Again» como mucho %d veces por conversación (%d)"):format(DialogueService.AgainMax, showsSince(beforeAgain)))
	DialogueService.cancel(player, "prueba")
end

---------------------------------------------------------------------
print("9. Todas las conversaciones de verdad pasan por el director")
---------------------------------------------------------------------
local longest = { Chars = 0, Text = "" } -- (la frase más larga, para la sección 10)
do
	local H = require("./lib/StoryHarness")
	local Quests = H.loadModule(H.ROOT .. "/shared/LifeStory/Quests")
	local dialogues, scenes, lineCount, framed, directions, whole, errors = 0, 0, 0, 0, 0, 0, 0
	local HappeningIndex = H.loadModule(H.ROOT .. "/shared/LifeStory/HappeningIndex")
	local engine = 0 -- pasos de cine que son escenas del motor (Happenings)
	local function walkLines(list, st)
		for _, line in list or {} do
			if type(line) == "table" then
				if type(line.T) == "string" then
					lineCount += 1
					-- (con un nombre de jugador de 20 letras: lo más largo que puede salir)
					local okFull, full = pcall(Strings.get, line.T, { nombre = "Maximiliana_Rodrigue" })
					local n = if okFull and type(full) == "string" then (utf8.len(full) or #full) else 0
					if n > longest.Chars then
						longest.Chars, longest.Text = n, full
					end
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
				if s.Type == "Cinematic" and HappeningIndex.has(s.Id) then
					engine += 1 -- (una escena escrita a mano en el motor sustituye a una conversación)
				end
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
	print(("     %d diálogos · %d pasos Scene (+%d del motor) · %d frases · %d con plano · %d acotaciones convertidas (%d enteras)"):format(dialogues, scenes, engine, lineCount, framed, directions, whole))
	-- (umbrales bajos a propósito: las escenas importantes pasan a escenas del motor, Happenings, y las
	-- acotaciones a A/G/Beat; aquí solo se comprueba que se recorren los datos de verdad)
	-- Umbrales RELATIVOS: cada escena que pasa al motor (Happenings) quita un paso Scene a propósito; lo
	-- que se mira es que, entre las dos formas, la historia sigue contada en escenas, y que las frases
	-- que quedan pasan bien por el director.
	check(scenes > 0 and scenes + engine >= 200, ("están las escenas de conversación (%d Scene + %d del motor)"):format(scenes, engine))
	check(errors == 0, "ninguna frase rompe al director")
	check(lineCount > 0 and framed > lineCount * 0.5, "la mayoría de las frases tienen plano")
	check(directions > 0 and directions >= lineCount * 0.005, ("las acotaciones escritas de los personajes se convierten en acción (%d de %d frases)"):format(directions, lineCount))
end

---------------------------------------------------------------------
print("10. Fase 2: velocidad del texto, dónde se guarda, retrato y la frase más larga")
---------------------------------------------------------------------
do
	local TextSpeed = L.load("src/shared/LifeStory/TextSpeed")
	local DialogueLook = L.load("src/shared/LifeStory/DialogueLook")
	-- Valores y menú
	check(#TextSpeed.Values == 4 and TextSpeed.Default == "Normal" and TextSpeed.rate("Normal") == 55, "cuatro velocidades; Normal es la de siempre (55 letras/s)")
	check(TextSpeed.rate("Lento") < TextSpeed.rate("Normal") and TextSpeed.rate("Normal") < TextSpeed.rate("Rapido") and TextSpeed.instant("Instantaneo"), "Lento < Normal < Rápido, e Instantáneo sale de golpe")
	check(TextSpeed.sanitize("Turbo") == "Normal" and TextSpeed.sanitize(nil) == "Normal" and TextSpeed.sanitize(3) == "Normal", "lo que no vale es Normal")
	check(TextSpeed.next("Lento") == "Normal" and TextSpeed.next("Normal") == "Rapido" and TextSpeed.next("Rapido") == "Instantaneo" and TextSpeed.next("Instantaneo") == "Lento", "el botón del menú da la vuelta: Lento → Normal → Rápido → Instantáneo → Lento")
	check(TextSpeed.label("Rapido") == "💬 Velocidad del texto: Rápido" and TextSpeed.label("x") == "💬 Velocidad del texto: Normal", "texto de la fila del menú, con tildes")
	local SettingsRows = L.load("src/client/Commands/SettingsRows")
	local name, value = SettingsRows.parse(TextSpeed.label("Lento"))
	local rows = SettingsRows.build({ { Text = TextSpeed.label("Lento"), Order = 2.15, Press = function()
		return ""
	end } })
	check(name == "Velocidad del texto" and value == "Lento" and rows[1] and rows[1].Section == "Juego" and rows[1].Value == "Lento", "en la app Ajustes sale en «Juego» con su valor")
	-- Tocar: entera / siguiente
	check(TextSpeed.tapAction({ Holding = true, Typed = false }) == "SkipHold", "tocar en una pausa la acaba")
	check(TextSpeed.tapAction({ Typed = false, SinceTyped = 0, Guard = 0.35 }) == "Finish", "tocar mientras se escribe: la frase sale entera (no se pasa)")
	check(TextSpeed.tapAction({ Typed = true, SinceTyped = 0.1, Guard = 0.35 }) == "Ignore", "un segundo toque justo después no se come la frase (TAP_GUARD)")
	check(TextSpeed.tapAction({ Typed = true, SinceTyped = 0.5, Guard = 0.35 }) == "Advance", "otro toque ya con la frase entera: la siguiente")
	-- Acompasar con la voz (H2)
	local chars = 150
	local paced = TextSpeed.paced("Normal", chars, 4)
	check(math.abs(chars / paced - 4 * 0.85) < 0.05, ("Normal con una voz de 4 s: el texto acaba al ~85 %% de la voz (%.1f s)"):format(chars / paced))
	check(TextSpeed.paced("Normal", chars, 60) == 55 * 0.5 and TextSpeed.paced("Normal", chars, 0.6) == 55 * 2, "sin pasarse: entre la mitad y el doble de lo elegido")
	check(TextSpeed.paced("Normal", chars, nil) == 55 and TextSpeed.paced("Rapido", chars, 4) == 110 and TextSpeed.paced("Instantaneo", chars, 4) == 0, "sin voz conocida, Rápido e Instantáneo: lo elegido")
	-- Tecleo
	check(TextSpeed.blipEvery(0) == 0 and TextSpeed.blipEvery(30) == 3 and TextSpeed.blipEvery(110) == 10, "un «tic» cada pocas letras (ninguno en Instantáneo)")
	local blips = 0
	for shown = 1, 110 do
		if TextSpeed.blip(shown - 1, shown, TextSpeed.blipEvery(110)) then
			blips += 1
		end
	end
	check(blips <= TextSpeed.BlipsPerSecond, ("en Rápido, como mucho %d «tics» por segundo (%d)"):format(TextSpeed.BlipsPerSecond, blips))
	check(not TextSpeed.blip(5, 5, 3) and TextSpeed.blip(2, 9, 3) and not TextSpeed.blip(0, 9, 0), "uno por paso como mucho; sin «tic» si no avanza")

	-- Dónde se guarda: SettingsService (data.Audio.TextSpeed y el atributo TextSpeed), sin campo nuevo
	local saves: { [any]: any } = {}
	local loadedFns = {}
	L.mock("src/server/Services/DataService", {
		get = function(player)
			return saves[player]
		end,
		onLoaded = function(fn)
			table.insert(loadedFns, fn)
		end,
	})
	local handlers: { [string]: any } = {}
	local function fakeRemote(remoteName: string)
		return {
			Name = remoteName,
			IsA = function()
				return true
			end,
			OnServerEvent = { Connect = function(_, fn)
				handlers[remoteName] = fn
			end },
		}
	end
	local fakeRemotes = { GraphicsChoice = fakeRemote("GraphicsChoice"), AudioVolume = fakeRemote("AudioVolume"), ShooterPrefs = fakeRemote("ShooterPrefs") }
	local rs = L.services.ReplicatedStorage :: any
	local oldWait = rs.WaitForChild
	rs.WaitForChild = function(_, n)
		return if n == "Remotes" then { FindFirstChild = function(_, k)
			return fakeRemotes[k]
		end } else nil
	end
	local SettingsService = L.load("src/server/Services/SettingsService")
	SettingsService.init()
	rs.WaitForChild = oldWait
	local p = L.player("Lectora", 77)
	saves[p] = { Audio = { Music = 3, Voice = 9, Sfx = 8, Ambience = 5 } }
	for _, fn in loadedFns do
		fn(p, saves[p])
	end
	check(p:GetAttribute("TextSpeed") == "Normal" and saves[p].Audio.TextSpeed == "Normal" and saves[p].Audio.Music == 3, "al entrar sin nada guardado: Normal (atributo TextSpeed) y los volúmenes como estaban")
	handlers.AudioVolume(p, "Set", "TextSpeed", "Rapido")
	check(saves[p].Audio.TextSpeed == "Rapido" and p:GetAttribute("TextSpeed") == "Rapido", "con el remoto de los volúmenes (AudioVolume «Set», «TextSpeed») se guarda en data.Audio.TextSpeed")
	handlers.AudioVolume(p, "Set", "TextSpeed", "Turbo")
	handlers.AudioVolume(p, "Set", "TextSpeed", 7)
	check(saves[p].Audio.TextSpeed == "Rapido", "lo que no vale no se guarda")
	handlers.AudioVolume(p, "Set", "Music", 7)
	check(saves[p].Audio.Music == 7 and saves[p].Audio.TextSpeed == "Rapido", "cambiar un volumen no borra la velocidad del texto")
	-- Vuelve al entrar otra vez (otra partida con lo guardado)
	local again = L.player("Lectora", 77)
	saves[again] = { Audio = table.clone(saves[p].Audio) }
	for _, fn in loadedFns do
		fn(again, saves[again])
	end
	check(again:GetAttribute("TextSpeed") == "Rapido", "al volver a entrar, la velocidad guardada llega en el atributo")
	local messy = L.player("Rara", 78)
	saves[messy] = { Audio = { Music = 6, TextSpeed = { "hack" } } }
	for _, fn in loadedFns do
		fn(messy, saves[messy])
	end
	check(saves[messy].Audio.TextSpeed == "Normal" and messy:GetAttribute("TextSpeed") == "Normal", "una partida con un valor raro se arregla al cargar")
	local fs = require("@lune/fs")
	local dataSrc = fs.readFile("src/server/Services/DataService.luau")
	check(dataSrc:find("fresh.Audio = data.Audio", 1, true) ~= nil and not dataSrc:find("TextSpeed", 1, true), "sin campo nuevo en la partida: va dentro de data.Audio, que ya sigue en una vida nueva")

	-- Retrato de repuesto (DialogueLook.badge)
	local Cast = L.load("src/shared/LifeStory/Cast")
	local cosme = DialogueLook.badge({ Id = "Cosme", Name = "Cosme" }, Cast.People, StageDirector.RemoteIcons)
	check(cosme.Show and cosme.Initial == "C" and cosme.Ring == nil, "Cosme: insignia con su inicial")
	local lum = (0.299 * cosme.Color[1] + 0.587 * cosme.Color[2] + 0.114 * cosme.Color[3]) / 255
	check(lum <= 0.56 and Cast.People.Cosme.Shirt.R > 0.9, ("…del color de su bata, oscurecido para que la inicial blanca se lea (%.2f)"):format(lum))
	local pip = DialogueLook.badge({ Id = "Pip", Name = "Pip" }, Cast.People)
	check(pip.Ring ~= nil and pip.Ring[3] == 255, "un ser de otro mundo (Glow): el borde de su brillo")
	local cosimo = DialogueLook.badge({ Id = "Cosimo", Name = "Doctor Cósimo" }, Cast.People)
	check(cosimo.Initial == "D" and cosimo.Ring ~= nil, "el villano de otra dimensión también")
	local who = DialogueLook.badge({ Id = "Desconocido", Name = "Álvaro" }, Cast.People)
	local who2 = DialogueLook.badge({ Id = "Desconocido", Name = "Álvaro" }, nil)
	check(who.Show and who.Initial == "Á" and who.Color[1] == who2.Color[1] and who.Color[2] == who2.Color[2], "quien no está en el reparto: su inicial (con tilde) y siempre el mismo color")
	local me = DialogueLook.badge({ Me = true, Id = "Yo", Name = "ñandú_99" })
	check(me.Show and me.Initial == "Ñ", "tú: tu inicial (también con ñ)")
	local phone = DialogueLook.badge({ Id = "Familia", Name = "Mamá", Direction = { Remote = "Telefono" } }, Cast.People, StageDirector.RemoteIcons)
	check(phone.Icon == "📱" and not DialogueLook.wantsFace({ Id = "Familia", Direction = { Remote = "Telefono" } }, true), "al teléfono: icono 📱 y sin cara (no está en la escena)")
	check(not DialogueLook.badge({ Narrator = true }).Show, "el narrador no lleva retrato")
	check(DialogueLook.initial("¡¿123?!") == "?" and DialogueLook.initial(nil) == "?" and DialogueLook.initial("  éLena") == "É", "sin letras: «?»; la primera letra, en mayúscula")
	check(DialogueLook.wantsFace({ Id = "Cosme" }, true) and not DialogueLook.wantsFace({ Id = "Cosme" }, false), "con su personaje en la escena se intenta su cara; si no, la insignia")

	-- La frase más larga de la historia cabe (H3)
	print(("     la frase más larga: %d letras («%s…»)"):format(longest.Chars, longest.Text:sub(1, 40)))
	check(longest.Chars >= 100, "se ha encontrado la frase más larga de verdad")
	for _, view in { { 640, 360 }, { 667, 375 }, { 844, 390 }, { 1366, 768 } } do
		local ok, scale = DialogueLook.fits(longest.Chars, view[1], view[2], true)
		check(ok, ("caja de diálogo en %d×%d: cabe con retrato sin encoger la letra (escala %.2f, %d líneas)"):format(view[1], view[2], scale, DialogueLook.lines(longest.Chars, DialogueLook.textWidth(true))))
	end
	check(DialogueLook.fits(140, 640, 360, true), "y una de 140 letras también")
	-- Subtítulo de las escenas (con el nombre de quien habla delante: «Nombre: …»): la frase más larga de
	-- las cinemáticas viejas y de las escenas del motor (sus pistas Lines)
	local H = require("./lib/StoryHarness")
	local defs = {
		H.loadModule(H.ROOT .. "/shared/LifeStory/HappeningIndex").all(),
		H.loadModule(H.ROOT .. "/shared/LifeStory/Cinematics"),
	}
	local caption = { Chars = 0, Text = "" }
	local seen = {}
	local function scan(t: any)
		if type(t) ~= "table" or seen[t] then
			return
		end
		seen[t] = true
		if type(t.Lines) == "table" then
			for _, l in t.Lines do
				if type(l) == "table" and (type(l.Text) == "string" or type(l.TextKey) == "string") then
					local okT, text = pcall(Strings.get, l.Text or l.TextKey, { nombre = "Maximiliana_Rodrigue" })
					local speaker = if type(l.Speaker) == "string" then Strings.get(Cast.nameOf(l.Speaker)) else nil
					local whole = (if speaker then speaker .. ": " else "") .. (if okT and type(text) == "string" then text else "")
					local n = utf8.len(whole) or #whole
					if n > caption.Chars then
						caption.Chars, caption.Text = n, whole
					end
				end
			end
		end
		for _, v in t do
			scan(v)
		end
	end
	for _, d in defs do
		scan(d)
	end
	print(("     el subtítulo más largo: %d letras con el nombre («%s…»)"):format(caption.Chars, caption.Text:sub(1, 40)))
	check(caption.Chars >= 60, "se ha encontrado el subtítulo más largo de verdad")
	for _, view in { { 640, 360 }, { 667, 375 } } do
		local ok, size = DialogueLook.captionFits(caption.Chars, view[1], view[2])
		check(ok and size >= DialogueLook.CaptionMinText, ("subtítulo en %d×%d: la más larga cabe con letra de %d px"):format(view[1], view[2], size))
	end
	-- (fase 6: las cinemáticas de siempre ya las reproduce HappeningClient; Controllers/Cinematics es un
	-- puente sin interfaz propia: un solo subtítulo para todas las escenas)
	local happ = fs.readFile("src/client/Controllers/HappeningClient.luau")
	local minH = ("MinSize = Vector2.new(0, %d)"):format(DialogueLook.CaptionMinHeight)
	check(happ:find(minH, 1, true) and happ:find("MinTextSize = " .. DialogueLook.CaptionMinText, 1, true), "el subtítulo de las escenas (todas, también las de siempre) usa esas medidas")
	check(not fs.readFile("src/client/Controllers/Cinematics.luau"):find("ScreenGui", 1, true), "Controllers/Cinematics ya no dibuja su propia banda de cine (un solo reproductor)")
end

---------------------------------------------------------------------
print("11. Fase 3: avisos de fallos de escena (SceneFaults en los dos lados y SceneErrorLog en el servidor)")
---------------------------------------------------------------------
do
	local fs = require("@lune/fs")
	local SceneFaults = L.load("src/shared/LifeStory/SceneFaults")
	local Log = L.load("src/shared/Log")
	local SceneErrorLog = L.load("src/server/LifeStory/SceneErrorLog")
	-- Limpiar: sin nombre, id, rutas del jugador ni números largos; una línea; corto y sin romper letras
	local names = { "LeoGamer99", "Leo el Grande", "123456789" }
	local clean = SceneFaults.clean("Players.LeoGamer99.PlayerGui.Escena:12: Leo el Grande (123456789) no tiene Humanoid\nlínea 2", names)
	check(not clean:find("Leo", 1, true) and not clean:find("123456789", 1, true) and not clean:find("\n", 1, true), "clean quita el nombre, el id, la ruta del jugador y los saltos de línea: " .. clean)
	local long = SceneFaults.clean(string.rep("ñ", 400))
	check(#long <= SceneFaults.MaxMessage + 4 and utf8.len(long) ~= nil, ("un mensaje largo se corta (%d bytes) sin partir una letra"):format(#long))
	check(SceneFaults.normalize({ Source = "Hacker", Message = "x" }) == nil and SceneFaults.normalize("texto") == nil, "una fuente que no existe (o un aviso que no es tabla) no vale")
	local n = SceneFaults.normalize({ Source = "Happening", Scene = "Grieta_Caen<script>", Step = string.rep("x", 200), Kind = "Raro", Message = 42 })
	check(n and n.Scene == "Grieta_Caenscript" and #n.Step <= SceneFaults.MaxId and n.Kind == "Error" and n.Message == "42", "escena y paso: solo letras seguras y cortos; un tipo raro pasa a Error")
	-- El servidor: limpia otra vez, cuenta, limita y escribe en el log sin decir de quién es
	local lines = {}
	local oldSink, oldLevel, oldRate = Log.sink, Log.level, Log.RateLimit
	Log.sink = function(level, category, text)
		table.insert(lines, { L = level, C = category, T = text })
	end
	Log.level = Log.Levels.Debug
	Log.RateLimit = 1000
	local clock = 0
	SceneErrorLog._clock = function()
		return clock
	end
	SceneErrorLog._reset()
	local ana = L.player("AnaPruebas", 5550123)
	local accepted = SceneErrorLog.accept(ana, { Source = "Dialogue", Scene = "Saga_02_Grieta", Step = "Line", Message = "AnaPruebas: fallo en Players.AnaPruebas.PlayerGui (5550123)" })
	check(accepted ~= nil and #lines == 1 and lines[1].C == "SCENE" and lines[1].L == "Warn", "un aviso de un jugador sale en el log del servidor (SCENE, Warn)")
	check(lines[1] and not lines[1].T:find("Ana", 1, true) and not lines[1].T:find("5550123", 1, true), "…sin su nombre ni su id: " .. tostring(lines[1] and lines[1].T))
	for _ = 1, 20 do
		SceneErrorLog.accept(ana, { Source = "Happening", Scene = "Grieta_Caen", Step = "Shot", Message = "x" })
	end
	local summary = SceneErrorLog.summary()
	check(summary.Logged == SceneErrorLog.Burst and summary.Dropped == 21 - SceneErrorLog.Burst, ("límite por jugador: %d apuntados, %d de sobra contados sin escribir"):format(summary.Logged, summary.Dropped))
	clock += SceneErrorLog.RefillSeconds * 2
	SceneErrorLog.accept(ana, { Source = "Happening", Scene = "Grieta_Caen", Step = "Shot", Message = "x" })
	check(SceneErrorLog.summary().Logged == SceneErrorLog.Burst + 1, "con el tiempo, el jugador puede volver a avisar")
	check(SceneErrorLog.summary().ByKey["Happening|Grieta_Caen|Shot|Error"] ~= nil and SceneErrorLog.summary().Players == 1 and SceneErrorLog.summary().BySource.Dialogue == 1, "contadores por escena + paso, por fuente y nº de jugadores distintos")
	check(SceneErrorLog.accept(ana, { Source = "Nada" }) == nil and SceneErrorLog.summary().Invalid == 1, "un aviso que no vale se cuenta como inválido y no se escribe")
	-- Límite del servidor entero
	SceneErrorLog._reset()
	clock = 1000
	local logged = 0
	for i = 1, SceneErrorLog.ServerPerMinute + 30 do
		if SceneErrorLog.accept(L.player("P" .. i, i), { Source = "Camera", Scene = "Restore", Step = "Glide", Message = "x" }) then
			logged += 1
		end
	end
	check(logged == SceneErrorLog.ServerPerMinute, ("límite del servidor: %d por minuto entre todos (%d)"):format(SceneErrorLog.ServerPerMinute, logged))
	-- El remoto: CinematicService lo recibe por Remotes.Scene ("Error", aviso)
	local cine = fs.readFile("src/server/Services/CinematicService.luau")
	check(cine:find('kind == "Error"', 1, true) and cine:find("SceneErrorLog.accept", 1, true), "CinematicService pasa los avisos del remoto Scene a SceneErrorLog")
	Log.sink, Log.level, Log.RateLimit = oldSink, oldLevel, oldRate
	SceneErrorLog._clock = os.clock
	SceneErrorLog._reset()
	-- Ningún DataStore: el registro vive mientras dura el servidor
	local src = fs.readFile("src/server/LifeStory/SceneErrorLog.luau")
	check(not src:find("DataStoreService", 1, true) and not src:find("DataService", 1, true), "SceneErrorLog no guarda nada en el DataStore")
end

L.finish("test-stagedirector")
-- (DialogueService deja su vigilante en marcha: se sale aquí)
require("@lune/process").exit(0)
