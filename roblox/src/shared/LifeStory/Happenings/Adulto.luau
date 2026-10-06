-- Escenas de la PROFESIÓN y la VIDA ADULTA (paquete P8d). Formato: shared/LifeStory/Sequencer.luau.
--
-- Las lanzan las misiones Adu01–Adu03, Adu_Profesion (ascenso, despido, ascenso en la policía y la llegada
-- de los veteranos) con un paso { Type = "Cinematic", Id = … } (Misiones/Adu_Escenas.paso). Mientras este
-- grupo no esté en HappeningIndex, esos pasos se juegan como conversación con las mismas frases.
--
-- Cómo están hechas:
--   * Todo el reparto de la misión ya está en su sitio: la escena lo USA (Use) y lo dirige con miradas,
--     emoción y gestos. Quien no es de la misión ENTRA andando y se va andando (Enter / Exit).
--   * El jefe depende de lo que estudiaste o de dónde trabajabas: los sucesos llevan If con esa condición
--     (solo queda el de tu jefe) y así la misma escena sirve para las siete profesiones.
--   * Continuidad: llegar tarde (LlegasTardeContrato, LlegasTardePracticas), el primer caso, el TFG, lo
--     que hiciste aquel verano (BuenTrabajo, MentisteEntrevista), la promesa a Abu, la concha, el grupo…
--   * Nada de {abu} ni {grupo} aquí (la escena solo rellena {nombre}); el género va con {o/a}.
--
-- Anclas: "Yo" = tú al empezar. Los puntos { "Yo", V(x, y, z), true } van referidos a hacia dónde
-- miras (z negativa = delante de ti).

local V = Vector3.new

---------------------------------------------------------------------
-- Condiciones (las mismas que Misiones/Adu01_PrimerContrato)
---------------------------------------------------------------------
local MED = { Flags = { "Graduado" }, Choices = { Estudios = "Medicina" } }
local ING = { Flags = { "Graduado" }, Choices = { Estudios = "Ingenieria" } }
local DER = { Flags = { "Graduado" }, Choices = { Estudios = "Derecho" } }
local ECO = { Flags = { "Graduado" }, Choices = { Estudios = "Economia" } }
local CAFE = { NotFlags = { "Graduado" }, Choices = { Empleo = "Barista" } }
local SUPER = { NotFlags = { "Graduado" }, Choices = { Empleo = "Reponedor" } }
local CORREOS = { NotFlags = { "Graduado" }, Choices = { Empleo = "Repartidor" } }

-- Juntar condiciones: las listas (Flags, NotFlags…) se suman; los mapas (Choices…) se mezclan
local function y(...: { [string]: any }): { [string]: any }
	local out: { [string]: any } = {}
	for _, cond in { ... } do
		for k, v in cond do
			local old = out[k]
			if type(v) == "table" and type(old) == "table" then
				local merged = table.clone(old)
				if #v > 0 then
					for _, x in v do
						table.insert(merged, x)
					end
				else
					for kk, vv in v do
						merged[kk] = vv
					end
				end
				out[k] = merged
			else
				out[k] = if type(v) == "table" then table.clone(v) else v
			end
		end
	end
	return out
end

-- Los siete jefes: quién, con qué condición, dónde está (delante de ti) y qué suena alrededor
local JEFES = {
	{ Npc = "Nuria", If = MED, Amb = "Hospital", Grad = true },
	{ Npc = "Sofia", If = ING, Amb = "Oficina", Grad = true },
	{ Npc = "Montse", If = DER, Amb = "Oficina", Grad = true },
	{ Npc = "Ignacio", If = ECO, Amb = "Oficina", Grad = true },
	{ Npc = "Lola", If = CAFE, Amb = "Tienda" },
	{ Npc = "Paco", If = SUPER, Amb = "Tienda" },
	{ Npc = "Ernesto", If = CORREOS, Amb = "Calle" },
}
local DELANTE = V(0, 0, -6) -- (si no está ya en la escena de la misión, aparece aquí)

local TARDE = { Flags = { "LlegasTardeContrato" } }
local PUNTUAL = { NotFlags = { "LlegasTardeContrato" } }

-- Lo común de una escena con tu jefe: lo coge de la misión, sonido del sitio y plano de situación.
-- extra(j) añade lo propio de cada jefe. Devuelve las pistas.
local function conJefe(opts: { [string]: any }): { [string]: any }
	local tracks = {
		Actors = {},
		Ambience = {},
		Camera = { { At = 0, Duration = opts.Establish or 2.6, Shot = opts.FirstShot or "General" } },
		Dialogue = table.clone(opts.Before or {}),
		Music = opts.Music or {},
		Light = opts.Light,
		Titles = opts.Titles,
	}
	for _, j in JEFES do
		if opts.Only and not opts.Only[j.Npc] then
			continue
		end
		table.insert(tracks.Ambience, { At = 0, Kind = j.Amb, Fade = 1.5, If = j.If })
		table.insert(tracks.Actors, { At = 0, Use = { Key = j.Npc, Npc = j.Npc, Anchor = "Yo", Offset = DELANTE }, If = j.If })
		for _, ev in (opts.Actors and opts.Actors(j)) or {} do
			ev.If = if ev.If then y(j.If, ev.If) else j.If
			table.insert(tracks.Actors, ev)
		end
		for _, ev in (opts.Camera and opts.Camera(j)) or {} do
			ev.If = if ev.If then y(j.If, ev.If) else j.If
			table.insert(tracks.Camera, ev)
		end
		for _, line in opts.Lines(j) do
			line.If = if line.If then y(j.If, line.If) else j.If
			table.insert(tracks.Dialogue, line)
		end
	end
	for _, ev in opts.Common or {} do
		table.insert(tracks.Actors, ev)
	end
	for _, line in opts.After or {} do
		table.insert(tracks.Dialogue, line)
	end
	return tracks
end

---------------------------------------------------------------------
-- Textos por jefe (cada uno con su voz: Cast.luau)
---------------------------------------------------------------------
-- Adu01 · el primer día: cómo te recibe (a tiempo o tarde) y cómo te lleva a firmar
local PRIMER_DIA = {
	Nuria = {
		Puntual = "¡Mirad quién ha llegado! Y en hora. Eso aquí ya es medio diagnóstico.",
		Tarde = "Las ocho y veinte. En urgencias, veinte minutos son una eternidad. Que no se repita, ¿vale?",
		DosVeces = "Llegaste tarde a las prácticas y llegas tarde al contrato. Empiezo a pensar que es una tradición.",
		Sigue = "Ven, que hay papeles. Muchos. Y café, si sobrevives a los papeles.",
	},
	Sofia = {
		Puntual = "¡Justo a tiempo! Como un engranaje recién engrasado.",
		Tarde = "Veinte minutos tarde. En ingeniería lo llamamos «margen de error». No lo conviertas en costumbre.",
		DosVeces = "Tarde a las prácticas, tarde hoy. Si fueras un puente, ya te estaría revisando los cálculos.",
		Sigue = "Ven, ven. Hay algo encima de mi mesa que lleva tu nombre.",
	},
	Montse = {
		Puntual = "Buenos días. Puntual. Me gusta. En este despacho, el tiempo se cobra por horas.",
		Tarde = "Buenos días. …Las nueve y veinte. No voy a levantar la voz. Tampoco lo voy a olvidar.",
		DosVeces = "La primera vez fue en las prácticas. Esta es la segunda. Un tribunal no daría una tercera.",
		Sigue = "Siéntate, por favor. Hay un documento que quiero que leas despacio.",
	},
	Ignacio = {
		Puntual = "¡Puntual al minuto! Los números y yo te damos la bienvenida.",
		Tarde = "Veinte minutos tarde. En intereses de demora, eso sale carísimo. Te lo perdono. Esta vez.",
		DosVeces = "Dos retrasos en dos primeros días. Si esto fuera una gráfica, me preocuparía la tendencia.",
		Sigue = "Ven a mi mesa. He traído un bolígrafo. Bueno, tres. Por si acaso.",
	},
	Lola = {
		Puntual = "¡Ahí estás! ¡Quita de la puerta, que entra el reparto! …Y luego ven, que tenemos que hablar. Sin delantal.",
		Sigue = "Siéntate. No, en esa silla no, que cojea. En esa.",
	},
	Paco = {
		Puntual = "Hmm. Has venido.",
		Sigue = "A mi despacho. Es como el almacén, pero con silla.",
	},
	Ernesto = {
		Puntual = "¡Hombre! ¡Justo a tiempo! Acabo de clasificar tu calle.",
		Sigue = "Hoy no repartes. Hoy te sientas un momento conmigo.",
	},
}

-- Adu01 · después de firmar
local FIRMA = {
	Nuria = { T = "Firmado. Bienvenid{o/a} al equipo. Ahora corre, que la sala tres no se cura sola.", G = "Point" },
	Sofia = { T = "¡Oficial! Te enseño tu mesa. Tiene un cajón que no cierra. Es tradición.", A = "Happy" },
	Montse = { T = "Bienvenid{o/a} al bufete. Despacio y bien: así se trabaja aquí.", G = "Nod" },
	Ignacio = { T = "Tres firmas, cero errores. Empiezas mejor que yo.", G = "Clap" },
	Lola = { T = "¡Encargad{o/a}! ¡Ay, que me emociono! …¡A la barra, que hay cola!", A = "Happy" },
	Paco = { T = "Encargad{o/a}. …Bien.", G = "Nod" },
	Ernesto = { T = "Jef{e/a} de ruta. Ya te sabes las calles. Ahora te sabrás los nombres de los perros.", G = "WaveLite" },
}

-- Ascenso: el motivo, la oferta y cómo se despide
local ASCENSO = {
	Nuria = {
		Abre = "Siéntate. No, no es nada malo. Por una vez en este hospital, no es nada malo.",
		Consejo = "Preguntas cuando dudas. Eso salva más vidas que saberlo todo.",
		Lanzarse = "Te lanzas. A veces demasiado. Pero cuando aciertas, aciertas a lo grande.",
		Oferta = "Quiero que lleves la guardia de los jueves. Tu equipo. Tu nombre en la puerta.",
	},
	Sofia = {
		Abre = "La pasarela del río ya no vibra. ¿Sabes de quién fue la idea de los amortiguadores?",
		Consejo = "Y nunca te ha dado vergüenza preguntar. Eso, en ingeniería, vale oro.",
		Lanzarse = "Te lanzaste y salió bien. Pues ahora, un proyecto entero.",
		Oferta = "Jef{e/a} de proyecto. Tu propio equipo. Tus propios errores, también. ¿Qué me dices?",
	},
	Montse = {
		Abre = "El vecino de las multas ha vuelto. Con su hermana. Y con su cuñado. Todos preguntan por ti.",
		Consejo = "Preguntas antes de firmar. Eso, en un bufete, es raro. Y valioso.",
		Lanzarse = "Te lanzas a los casos como si fueran tuyos. Porque lo son.",
		Oferta = "Te ofrezco ser asociad{o/a}. Despacho propio. Con una ventana más grande.",
	},
	Ignacio = {
		Abre = "Tu cartera de clientes ha crecido un treinta y dos por ciento. Lo he calculado tres veces. Me gusta calcular cosas buenas.",
		Consejo = "Y cuando dudas, preguntas. El banco perdería menos dinero si todos hicieran lo mismo.",
		Lanzarse = "Las bicis de Marcos ya tienen tres tiendas. Te lanzaste. Acertaste.",
		Oferta = "Quiero que lleves las cuentas de empresa. Todas. Con tu firma.",
	},
	Lola = {
		Abre = "Me jubilo pronto, ya lo sabes. Omar se queda la cocina. Pero la barra… la barra necesita a alguien.",
		Oferta = "Te subo el sueldo y te doy las llaves. Las de verdad. Las que pesan.",
	},
	Paco = {
		Abre = "Hmm. Siéntate. …Tres meses. Ni una caja mal puesta. Ni una queja.",
		Oferta = "Jef{e/a} de tienda. Las dos plantas. No me hagas repetirlo.",
	},
	Ernesto = {
		Abre = "Correos abre una ruta nueva: los barrios de la costa. Y necesito a quien conozca cada portal.",
		Oferta = "Jef{e/a} de zona. Coche oficial. Bueno, furgoneta. Con radio.",
	},
}

-- Despido: cómo lo dice cada uno (no es culpa tuya: recortes)
local DESPIDO = {
	Nuria = {
		Abre = "Cierra la puerta, por favor. …Esto es lo peor de mi trabajo. Peor que las guardias.",
		Motivo = "Recortes. Cierran la planta de los jueves. Los últimos en entrar son los primeros en salir. No es justo. Es así.",
	},
	Sofia = {
		Abre = "El ayuntamiento ha cancelado los proyectos del río. Todos. También el tuyo.",
		Motivo = "Sin proyecto no hay equipo. Y sin equipo… Lo siento. De verdad que lo siento.",
	},
	Montse = {
		Abre = "Voy a decirlo despacio, porque no hay otra forma de decirlo.",
		Motivo = "El bufete se fusiona con otro. Sobran despachos. El tuyo es uno de ellos.",
	},
	Ignacio = {
		Abre = "He revisado los números cuarenta veces. Salen igual las cuarenta.",
		Motivo = "La oficina cierra en verano. Recolocan a dos personas. Tú no eres una de ellas.",
	},
	Lola = {
		Abre = "Siéntate. No, en la que cojea no. …Ay, que no sé ni cómo empezar.",
		Motivo = "Han abierto una cadena de cafeterías en la plaza. Han bajado las ventas. No puedo pagar dos encargados.",
	},
	Paco = {
		Abre = "Hmm. …Hmm.",
		Motivo = "Los de arriba cierran la segunda planta. Me obligan a quitar un puesto. Me he negado dos veces. A la tercera, no me dejan.",
	},
	Ernesto = {
		Abre = "Te he guardado una carta. Esta no te va a gustar. Y la he escrito yo.",
		Motivo = "Las máquinas de paquetes. Cada día reparten más y nosotros menos. Me quitan una ruta. La tuya.",
	},
}

-- Una frase de tu jefe con su If (para las de continuidad, que valen para cualquiera)
local function linea(j: { [string]: any }, t: string, extra: { [string]: any }?): { [string]: any }
	local line = { S = j.Npc, T = t }
	for k, v in extra or {} do
		line[k] = v
	end
	return line
end

return {
	---------------------------------------------------------------------
	-- ADU01 · EL PRIMER DÍA (antes de la conversación del contrato)
	-- ¿Qué está pasando? Llegas a tu primer trabajo de verdad; tu jefe está a lo suyo.
	-- ¿Por qué? Te contratan donde hiciste las prácticas (o donde trabajaste en verano).
	-- ¿Qué siente el personaje? Nervios de primer día; el jefe, alegría (o un reproche si llegas tarde).
	-- ¿Qué ve el jugador? El sitio entero → el jefe levanta la vista → se gira → te habla de cerca.
	-- ¿Qué quiero que sienta? Que esto es importante: alguien le esperaba. Y que llegar tarde se nota.
	---------------------------------------------------------------------
	Adu01_PrimerDia = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = conJefe({
			Establish = 2.6,
			Music = { { At = 0, Intensity = "Descubrimiento" } },
			Actors = function(j)
				return {
					{ At = 0.1, Look = { Key = j.Npc, At = "Away" } }, -- (a lo suyo: trabajando)
					{ At = 2.4, Look = { Key = j.Npc, At = "Yo" } }, -- te oye y se gira
					{ At = 2.7, Mood = { Key = j.Npc, Mood = "Joy" }, If = PUNTUAL },
					{ At = 3.2, Gesture = { Key = j.Npc, Play = "Wave" }, If = PUNTUAL },
				}
			end,
			Camera = function(j)
				return { { At = 2.6, Duration = 1.6, Shot = "Reaccion:" .. j.Npc } }
			end,
			Lines = function(j)
				local t = PRIMER_DIA[j.Npc]
				local out = {
					linea(j, t.Puntual, { Pause = 4.4, Shot = "PrimerPlano:" .. j.Npc, If = PUNTUAL }),
				}
				if t.Tarde then
					table.insert(out, linea(j, t.Tarde, { Pause = 4.4, Shot = "PrimerPlano:" .. j.Npc, A = "HandsOnHips", If = TARDE }))
					table.insert(out, linea(j, t.DosVeces, { Beat = "Pensar", If = y(TARDE, { Flags = { "LlegasTardePracticas" } }) }))
				end
				table.insert(out, { S = "Yo", T = "Buenos días. Vengo a… bueno, ya sabes a qué vengo.", Beat = "Respirar", Shot = "Hombro:" .. j.Npc .. ">Yo" })
				table.insert(out, linea(j, t.Sigue, { G = "Point", Shot = "DosPlanos:" .. j.Npc .. ",Yo" }))
				return out
			end,
		}),
	},

	---------------------------------------------------------------------
	-- ADU01 · LA FIRMA (después de la oferta)
	-- ¿Qué está pasando? Firmas tu primer contrato indefinido.
	-- ¿Por qué? Te lo has ganado (prácticas, el verano, la confesión de tu error).
	-- ¿Qué siente el personaje? Vértigo y orgullo. El jefe, satisfacción.
	-- ¿Qué ve el jugador? El papel y la firma (inserto) → tu cara → tu jefe te da la bienvenida.
	-- ¿Qué quiero que sienta? «Esto es mío». Un pequeño triunfo, sin fanfarria.
	---------------------------------------------------------------------
	Adu01_Firma = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = conJefe({
			Establish = 2.4,
			FirstShot = "Inserto:Yo", -- el papel y tu firma
			Music = { { At = 0, Intensity = "Intima" }, { At = 8.5, Intensity = "Resolucion" } },
			Titles = { { At = 6.4, Text = "📝 Contrato indefinido", Sub = "Tu primer trabajo de verdad", Duration = 3 } },
			Before = {
				{ S = "Yo", T = "{nombre}. Mi nombre. En un contrato de verdad.", Pause = 2.4, Shot = "PrimerPlano:Yo" },
				{ S = "Yo", T = "Sin «de prácticas». Sin «de verano». Mío.", Beat = "Respirar" },
			},
			Actors = function(j)
				return {
					{ At = 0.1, Look = { Key = j.Npc, At = "Suelo" } }, -- mira el papel mientras firmas
					{ At = 8.6, Look = { Key = j.Npc, At = "Yo" } },
					{ At = 8.8, Mood = { Key = j.Npc, Mood = "Joy" } },
				}
			end,
			Lines = function(j)
				local f = FIRMA[j.Npc]
				return { linea(j, f.T, { A = f.A, G = f.G, Pause = 0.6, Shot = "PrimerPlano:" .. j.Npc }) }
			end,
		}),
	},

	---------------------------------------------------------------------
	-- ADU01 · EL PRIMER TURNO AL MANDO (sin carrera; sustituye al resumen del narrador)
	-- ¿Qué está pasando? Acaba tu primer turno como responsable.
	-- ¿Por qué? Tu jefe del verano te ha ascendido.
	-- ¿Qué siente el personaje? Cansancio y orgullo. Omar, alegría (y hambre). El jefe, lo calla.
	-- ¿Qué ve el jugador? Omar sale de la cocina andando, bromea; tu jefe recuerda aquel verano y asiente.
	-- ¿Qué quiero que sienta? Que lo que hizo de adolescente (decir la verdad o mentir) se recuerda.
	---------------------------------------------------------------------
	Adu01_PrimerTurno = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = conJefe({
			Only = { Lola = true, Paco = true, Ernesto = true },
			Establish = 2.4,
			Music = { { At = 0, Intensity = "Resolucion" } },
			Titles = { { At = 0.4, Text = "Primer turno al mando", Sub = "Nadie ve lo difícil que es. Salvo tú.", Duration = 2.6 } },
			Actors = function(j)
				local list = {
					{ At = 0.1, Look = { Key = j.Npc, At = "Away" } },
					{ At = 2.2, Look = { Key = j.Npc, At = "Yo" } },
				}
				if j.Npc == "Lola" then
					-- Omar sale de la cocina, se acerca y luego vuelve a sus fogones
					table.insert(list, { At = 0.5, Enter = { Key = "Omar", Npc = "Omar", From = { "Yo", V(-7, 0, -4), true }, To = { "Yo", V(-2.2, 0, -3), true }, Walk = true } })
					table.insert(list, { At = 3, Look = { Key = "Omar", At = "Yo" } })
					table.insert(list, { At = 3.2, Mood = { Key = "Omar", Mood = "Joy" } })
					table.insert(list, { At = 19, Exit = { Key = "Omar", To = { "Yo", V(-8, 0, -4), true }, Walk = true } })
				end
				return list
			end,
			Lines = function(j)
				if j.Npc == "Lola" then
					return {
						{ S = "Omar", T = "¡Encargad{o/a}! ¡Ya puedo decir que mi jefe es mi amigo! …Espera. Eso no es bueno para mí.", Pause = 3, A = "Happy", Shot = "PrimerPlano:Omar" },
						{ S = "Omar", T = "Te he guardado la última croqueta. Bueno, media. La otra media era control de calidad.", Shot = "DosPlanos:Omar,Yo" },
						linea(j, "Aquel verano tiraste una bandeja entera y viniste a decírmelo. Por eso estás hoy aquí.", { If = { Flags = { "BuenTrabajo" } }, Shot = "PrimerPlano:Lola" }),
						linea(j, "Y hoy, sin inventarte experiencia. Que se note la diferencia, ¿eh?", { If = { Flags = { "MentisteEntrevista" } }, A = "HandsOnHips" }),
						linea(j, "Turno cerrado. Ni un plato roto. …Bueno, uno. Pero era feo.", { Beat = "Mirar", G = "Nod", Shot = "PrimerPlano:Lola" }),
					}
				elseif j.Npc == "Paco" then
					return {
						linea(j, "Hmm. Pasillo tres: perfecto. Pasillo cuatro: perfecto.", { Pause = 3, Shot = "PrimerPlano:Paco" }),
						linea(j, "Treinta latas por el suelo aquel verano, y me lo dijiste tú. Por eso firmé.", { If = { Flags = { "BuenTrabajo" } } }),
						linea(j, "La próxima entrevista la haces tú. Sin mentir. Lo sé todo, ¿eh?", { If = { Flags = { "MentisteEntrevista" } }, A = "Angry" }),
						linea(j, "…Bien. Muy bien, incluso.", { Pause = 1.2, Beat = "Mirar", G = "Nod", Shot = "PrimerPlano:Paco" }),
					}
				end
				return {
					linea(j, "Ruta completa. Ni una carta perdida. Y el perro del 14 te ha movido la cola. Eso no lo consigo ni yo.", { Pause = 3, A = "Happy", Shot = "PrimerPlano:Ernesto" }),
					linea(j, "Discreción, puntualidad y ni una queja. Lo de aquel verano no fue suerte.", { If = { Flags = { "BuenTrabajo" } } }),
					linea(j, "Y esta vez sin decir que tenías «muchísima experiencia». Mejor así.", { If = { Flags = { "MentisteEntrevista" } } }),
					linea(j, "Mañana a las siete. Quien lleva la ruta no duerme. Bueno, duerme poco.", { G = "Point", Shot = "DosPlanos:Ernesto,Yo" }),
				}
			end,
		}),
	},

	---------------------------------------------------------------------
	-- ADU01 · EL BUZÓN (final de mes, antes de decidir qué haces con las facturas)
	-- ¿Qué está pasando? Primer sueldo completo… y tres sobres en el buzón.
	-- ¿Por qué? Vivir solo cuesta dinero: alquiler, luz y agua.
	-- ¿Qué siente el personaje? Orgullo que se desinfla en dos segundos. Humor de supervivencia.
	-- ¿Qué ve el jugador? Su casa, de noche; los sobres (inserto); su propia cara al leerlos.
	-- ¿Qué quiero que sienta? Que ser adulto también es esto, y sonría.
	---------------------------------------------------------------------
	Adu01_Buzon = {
		Skippable = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Casa", Fade = 1.5 } },
			Light = { { At = 0, Preset = "InteriorCalido", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Nada" } },
			Camera = {
				{ At = 0, Duration = 2.4, Shot = "Medio:Yo" },
			},
			Dialogue = {
				{ S = "Yo", T = "Primer sueldo completo. Entero. Mío.", Pause = 2.2, A = "Happy" },
				{ S = "Yo", T = "La casa todavía huele a pintura… y ya tiene correo.", If = { NotFlags = { "Graduado" } } },
				{ S = "Yo", T = "…Tres sobres. Alquiler. Luz. Agua.", Beat = "Suelo", Shot = "Inserto:Yo" },
				{ S = "Yo", T = "Nadie me avisó de que ser adult{o/a} venía con buzón.", G = "Shrug", Shot = "PrimerPlano:Yo" },
			},
		},
	},

	---------------------------------------------------------------------
	-- EL ASCENSO (misión Adu_Ascenso): tu jefe te llama a su mesa
	-- ¿Qué está pasando? Tu jefe te ofrece subir un escalón.
	-- ¿Por qué? Por cómo has trabajado: tu primer caso, el TFG, lo que hiciste aquel verano.
	-- ¿Qué siente el personaje? Sorpresa (te esperabas una bronca) y orgullo. El jefe, confianza.
	-- ¿Qué ve el jugador? Plano general → los dos → el jefe de cerca → tu reacción.
	-- ¿Qué quiero que sienta? Que lo que eligió antes cuenta, y que esta vez la decisión es suya.
	---------------------------------------------------------------------
	Adu_Ascenso = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = conJefe({
			Establish = 2.4,
			Music = { { At = 0, Intensity = "Intima" }, { At = 14, Intensity = "Resolucion" } },
			Actors = function(j)
				return {
					{ At = 0.1, Look = { Key = j.Npc, At = "Away" } },
					{ At = 2.2, Look = { Key = j.Npc, At = "Yo" } },
					{ At = 2.5, Mood = { Key = j.Npc, Mood = "Calm" } },
				}
			end,
			Lines = function(j)
				local t = ASCENSO[j.Npc]
				local out = {
					linea(j, t.Abre, { Pause = 2.6, Shot = "DosPlanos:" .. j.Npc .. ",Yo" }),
				}
				if j.Grad then
					table.insert(out, linea(j, t.Consejo, { If = { Choices = { PrimerCaso = "Consejo" } }, Shot = "PrimerPlano:" .. j.Npc }))
					table.insert(out, linea(j, t.Lanzarse, { If = { Choices = { PrimerCaso = "Lanzarse" } }, Shot = "PrimerPlano:" .. j.Npc }))
					table.insert(out, linea(j, "Leí tu trabajo de fin de grado. El de nuestro caso. Lo tengo subrayado.", { If = { Choices = { TemaTFG = "Practicas" } }, G = "ThinkChin" }))
					table.insert(out, linea(j, "Y sí: me acuerdo de que el primer día llegaste tarde. Lo que cuenta es todo lo de después.", { If = TARDE, Beat = "Mirar" }))
				else
					table.insert(out, linea(j, "Aquel verano me dijiste la verdad cuando algo salió mal. Eso no se olvida.", { If = { Flags = { "BuenTrabajo" } } }))
					table.insert(out, linea(j, "Empezaste inventándote experiencia. Ahora la tienes de verdad.", { If = { Flags = { "MentisteEntrevista" } }, A = "HandsOnHips" }))
				end
				table.insert(out, { S = "Yo", T = "¿Esto es… una bronca?", Beat = "Suelo", Shot = "Reaccion:Yo" })
				table.insert(out, linea(j, t.Oferta, { Pause = 0.8, A = "Happy", Shot = "PrimerPlano:" .. j.Npc }))
				table.insert(out, linea(j, "Piénsalo. …No mucho.", { G = "Point", Shot = "Hombro:Yo>" .. j.Npc }))
				return out
			end,
		}),
	},

	---------------------------------------------------------------------
	-- EL DESPIDO (misión Eco_Despido): «Pásate por mi despacho»
	-- ¿Qué está pasando? Te despiden. Recortes: no es (solo) culpa tuya.
	-- ¿Por qué? La empresa va mal; y aquel primer día tarde, o aquella mentira, pesan.
	-- ¿Qué siente el personaje? Un golpe en el estómago. El jefe, culpa y vergüenza.
	-- ¿Qué ve el jugador? Luz fría; el jefe no te mira al empezar; tu cara en silencio.
	-- ¿Qué quiero que sienta? Que duele, que no es el final y que la gente que le quiere estará ahí.
	---------------------------------------------------------------------
	Adu_Despido = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = conJefe({
			Establish = 2.6,
			Music = { { At = 0, Intensity = "Tension" }, { At = 15, Intensity = "Intima" } },
			Light = { { At = 0, Preset = "Tension", Fade = 2, Weight = 0.7 } },
			Actors = function(j)
				return {
					{ At = 0.1, Look = { Key = j.Npc, At = "Suelo" } }, -- no se atreve a mirarte
					{ At = 0.2, Mood = { Key = j.Npc, Mood = "Sad" } },
					{ At = 9, Look = { Key = j.Npc, At = "Yo" } },
				}
			end,
			Lines = function(j)
				local t = DESPIDO[j.Npc]
				return {
					linea(j, t.Abre, { Pause = 2.8, A = "Sad", Shot = "Medio:" .. j.Npc }),
					linea(j, t.Motivo, { Pause = 1, Shot = "PrimerPlano:" .. j.Npc }),
					{ S = "Yo", T = "…", Pause = 1.2, Beat = "Suelo", Duration = 2, Shot = "PPP:Yo" },
					linea(j, "No es por aquel primer día que llegaste tarde. …No solo por eso.", { If = TARDE, Beat = "Apartar" }),
					linea(j, "Lo de la entrevista de aquel verano lo supe hace tiempo. No es por eso. Pero tampoco ayuda.", { If = { Flags = { "MentisteEntrevista" } }, Beat = "Apartar" }),
					linea(j, "Hace nada te ascendí. Y hoy esto. No sé ni cómo mirarte.", { If = { Flags = { "Ascendido" } }, A = "Sad" }),
					linea(j, "Si necesitas cualquier cosa, una carta, una llamada… la tienes. Eso sí puedo dártelo.", { Beat = "Mirar", Shot = "DosPlanos:" .. j.Npc .. ",Yo" }),
				}
			end,
		}),
	},

	---------------------------------------------------------------------
	-- EL DESPIDO · ESA NOCHE (misión Eco_Despido): tu familia llama a la puerta
	-- ¿Qué está pasando? Tu familia se entera y viene con comida.
	-- ¿Por qué? Porque las malas noticias se notan en la voz, aunque digas «estoy bien».
	-- ¿Qué siente el personaje? Vergüenza al principio; luego, alivio.
	-- ¿Qué ve el jugador? Su casa a oscuras; alguien entra andando con un táper; la concha en la estantería.
	-- ¿Qué quiero que sienta? Que la familia (y la promesa a Abu) siguen ahí aunque se caiga un trabajo.
	---------------------------------------------------------------------
	Adu_DespidoCasa = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Casa", Fade = 2 } },
			Light = { { At = 0, Preset = "Noche", Fade = 1.5, Weight = 0.8 }, { At = 6, Preset = "InteriorCalido", Fade = 3 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Actors = {
				{ At = 1.2, Enter = { Key = "Familia", Npc = "Familia", From = { "Yo", V(6, 0, 7), true }, To = { "Yo", V(1.6, 0, -2.6), true }, Walk = true } },
				{ At = 4.6, Look = { Key = "Familia", At = "Yo" } },
				{ At = 4.8, Mood = { Key = "Familia", Mood = "Calm" } },
			},
			Camera = {
				{ At = 0, Duration = 1.6, Shot = "Medio:Yo" },
				{ At = 1.6, Duration = 3, Shot = "Seguir:Familia" },
			},
			Dialogue = {
				{ S = "Familia", T = "Traigo lentejas. No preguntes. Las lentejas no hacen preguntas.", Pause = 4.8, A = "Happy", Shot = "DosPlanos:Familia,Yo" },
				{ S = "Yo", T = "Me han echado.", Pause = 0.8, Beat = "Suelo", Shot = "PrimerPlano:Yo" },
				{ S = "Familia", T = "Ya lo sé. Me lo ha dicho tu voz por teléfono. «Estoy bien», decías. Ya.", Pause = 1, Shot = "PrimerPlano:Familia" },
				{ S = "Familia", T = "A mí me echaron dos veces. Una por llegar tarde y otra por llevar razón. Y aquí estoy, trayendo lentejas." },
				{ S = "Familia", T = "Le prometiste a tu abu hacer cosas bonitas. Eso no venía en ningún contrato.", If = { Choices = { PromesaAbu = "CosasBonitas" } }, Beat = "Mirar" },
				{ S = "Familia", T = "Y el domingo, al mar, como le prometiste. Las cosas se piensan mejor con los pies en la arena.", If = { Choices = { PromesaAbu = "Volver" } }, Beat = "Mirar" },
				{ S = "Familia", T = "Dijiste que cuidarías de la familia. Pues hoy la familia cuida de ti. Por turnos.", If = { Choices = { PromesaAbu = "Familia" } }, Beat = "Mirar" },
				{ S = "Familia", T = "…Todavía tienes la concha de la playa. «Para que vuelvas», dijo. Pues eso: se vuelve.", If = { Items = { ConchaAbu = 1 } }, Beat = "Apartar", Shot = "Inserto:Familia" },
				{ S = "Familia", T = "Mañana, a buscar. Hoy, lentejas.", A = "Happy", Shot = "DosPlanos:Familia,Yo" },
			},
		},
	},

	---------------------------------------------------------------------
	-- ASCENSO EN LA POLICÍA (misión Adu_AscensoPolicia, con el aviso Promoted)
	-- ¿Qué está pasando? Inés te da tu nueva placa; Bruno entra a felicitarte.
	-- ¿Por qué? Has subido de rango a fuerza de patrullas y vecinos ayudados.
	-- ¿Qué siente el personaje? Orgullo. Inés, el de una mentora. Bruno, el de un viejo rival.
	-- ¿Qué ve el jugador? La placa (inserto) → Inés de cerca → Bruno entrando andando.
	-- ¿Qué quiero que sienta? Que la ciudad le reconoce, y que el pasado (expediente, esposas) quedó atrás.
	---------------------------------------------------------------------
	Adu_AscensoRango = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Oficina", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Resolucion" } },
			Actors = {
				{ At = 0, Use = { Key = "Ines", Npc = "Ines", Anchor = "Yo", Offset = DELANTE } },
				{ At = 0.3, Look = { Key = "Ines", At = "Yo" } },
				{ At = 0.4, Mood = { Key = "Ines", Mood = "Joy" } },
				{ At = 9, Enter = { Key = "Bruno", Npc = "Bruno", From = { "Yo", V(7, 0, 6), true }, To = { "Yo", V(2.4, 0, -2.4), true }, Walk = true }, If = { Completed = { "Adu03_Reencuentro" } } },
				{ At = 13, Gesture = { Key = "Bruno", Play = "Wave" }, If = { Completed = { "Adu03_Reencuentro" } } },
			},
			Camera = {
				{ At = 0, Duration = 2.4, Shot = "General" },
			},
			Dialogue = {
				{ S = "Ines", T = "Ven. No, no te has metido en ningún lío. Esta vez.", Pause = 2.4, Shot = "DosPlanos:Ines,Yo" },
				{ S = "Ines", T = "Lee la placa. En voz alta no, que me emociono.", G = "Point", Shot = "Inserto:Yo" },
				{ S = "Ines", T = "Con un expediente de menores, nadie apostaba por ti. Yo sí. Por eso te lo digo yo.", If = { Flags = { "Antecedentes" } }, Beat = "Mirar", Shot = "PrimerPlano:Ines" },
				{ S = "Ines", T = "Conozco a medio Valmar por su nombre. Ahora el otro medio te conoce a ti.", Shot = "PrimerPlano:Ines" },
				{ S = "Bruno", T = "¿Ascenso? ¿Y no me avisáis? Yo te puse las esposas una vez. Hoy solo te doy la mano.", If = { Completed = { "Adu03_Reencuentro" }, Flags = { "Detenido" } }, A = "Happy" },
				{ S = "Bruno", T = "¿Ascenso? ¿Y no me avisáis? Empezamos de cero hace mucho… y mira dónde estamos.", If = { Completed = { "Adu03_Reencuentro" }, NotFlags = { "Detenido" }, Choices = { AdiosBruno = "DeCero" } }, A = "Happy" },
				{ S = "Bruno", T = "¿Ascenso? ¿Y no me avisáis? Ahora me tendrás que llamar «compañero» con respeto.", If = { Completed = { "Adu03_Reencuentro" }, NotFlags = { "Detenido" }, NotChoices = { AdiosBruno = "DeCero" } }, A = "Happy" },
				{ S = "Ines", T = "Felicidades. Y a patrullar, que los gatos no se bajan solos de los árboles.", G = "Nod", Shot = "DosPlanos:Ines,Yo" },
			},
			Titles = { { At = 5.6, Text = "⭐ Ascenso", Sub = "Policía de Valmar", Duration = 3 } },
		},
	},

	---------------------------------------------------------------------
	-- ADU02 · EL HOSPITAL (antes de sentarte con Abu)
	-- ¿Qué está pasando? Abu está en una cama del hospital tras caerse; tu familia y Nuria, con ella.
	-- ¿Por qué? Una caída en la escalera. Nada grave… pero da miedo.
	-- ¿Qué siente el personaje? Miedo que se convierte en alivio. Abu, vergüenza y alegría de verte.
	-- ¿Qué ve el jugador? La habitación → tu familia te ve primero → Nuria → Abu se gira despacio.
	-- ¿Qué quiero que sienta? Ternura y un poco de miedo: Abu se está haciendo mayor.
	---------------------------------------------------------------------
	Adu02_Hospital = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Hospital", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Actors = {
				{ At = 0, Use = { Key = "Abu", Npc = "Abu", Anchor = "Yo", Offset = V(0, 0, -5) } },
				{ At = 0, Use = { Key = "Nuria", Npc = "Nuria", Anchor = "Yo", Offset = V(3, 0, -4) } },
				{ At = 0, Use = { Key = "Familia", Npc = "Familia", Anchor = "Yo", Offset = V(-3, 0, -4) } },
				{ At = 0.1, Look = { Key = "Abu", At = "Away" } }, -- mira por la ventana
				{ At = 0.1, Look = { Key = "Nuria", At = "Suelo" } }, -- lee el informe
				{ At = 0.2, Mood = { Key = "Abu", Mood = "Sad" } },
				{ At = 1.4, Look = { Key = "Familia", At = "Yo" } }, -- te ve la primera
				{ At = 1.6, Mood = { Key = "Familia", Mood = "Nervous" } },
				{ At = 2.2, Gesture = { Key = "Familia", Play = "Wave" } },
				{ At = 9, Look = { Key = "Abu", At = "Yo" } }, -- y Abu se gira despacio
				{ At = 9.3, Mood = { Key = "Abu", Mood = "Joy" } },
			},
			Camera = {
				{ At = 0, Duration = 2.8, Shot = "General" },
			},
			Dialogue = {
				{ S = "Familia", T = "¡Aquí! Está bien. Está bien, ¿eh? Lo primero que ha preguntado al despertar es por la planta.", Pause = 2.8, Shot = "PrimerPlano:Familia" },
				{ S = "Familia", T = "Y por tu ascenso. Se lo ha contado a toda la planta. A la de las camas, no a la del salón.", If = { Flags = { "Ascendido" } } },
				{ S = "Familia", T = "No le he contado lo del trabajo. Hoy no.", If = { Flags = { "Despedido" } }, Beat = "Apartar" },
				{ S = "Nuria", T = "Un golpe y un buen susto. Ahora mismo está mejor que yo después de una guardia.", Beat = "Mirar", G = "Nod", Shot = "Medio:Nuria" },
				{ S = "Abu", T = "¿Ya habéis terminado de hablar de mí como si no estuviera? Ven aquí, que de pie me mareas.", Pause = 0.8, Shot = "PrimerPlano:Abu" },
			},
		},
	},

	---------------------------------------------------------------------
	-- ADU02 · LA ORILLA (antes de que Abu te cuente su historia)
	-- ¿Qué está pasando? Llegáis al mar. Abu lo ve después de muchos años.
	-- ¿Por qué? Era su sitio de los domingos de joven, y ha querido volver contigo.
	-- ¿Qué siente el personaje? Abu: emoción contenida y un poco de fragilidad. Tú: cuidarla.
	-- ¿Qué ve el jugador? El mar a lo ancho → Abu de perfil → sus pies en la arena → su cara con los ojos cerrados.
	-- ¿Qué quiero que sienta? Calma. Que el tiempo se para un momento.
	---------------------------------------------------------------------
	Adu02_Orilla = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Playa", Fade = 2.5 } },
			Light = { { At = 0, Preset = "Atardecer", Fade = 4, Weight = 0.6 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Actors = {
				{ At = 0, Use = { Key = "Abu", Npc = "Abu", Anchor = "Yo", Offset = V(0, 0, -3) } },
				{ At = 0.1, Look = { Key = "Abu", At = "Away" } }, -- mira el mar
				{ At = 0.2, Mood = { Key = "Abu", Mood = "Calm" } },
			},
			Camera = {
				{ At = 0, Duration = 3.2, Shot = "Pan:Abu" },
			},
			Dialogue = {
				{ S = "Abu", T = "Huele igual. Cincuenta años y huele igual.", Pause = 3.4, Shot = "Lateral:Abu" },
				{ S = "Yo", T = "¿Te ayudo con los zapatos?", Shot = "Hombro:Yo>Abu" },
				{ S = "Abu", T = "Puedo yo. …No puedo. Ayúdame. Pero no se lo cuentes a nadie.", Pause = 0.6, Beat = "Suelo", Shot = "PrimerPlano:Abu" },
				{ S = "Abu", T = "Llueve sobre el mar. Da igual: el mar con lluvia también es el mar.", If = { Weather = { "Lluvia", "Tormenta" } }, Beat = "Apartar" },
				{ S = "Yo", T = "Toma mi chaqueta.", If = { Season = "Invierno" } },
				{ S = "Abu", T = "No tengo frío. …Bueno, déjamela. Pero no tengo frío.", If = { Season = "Invierno" }, A = "Happy" },
				{ S = "Abu", T = "Cierra los ojos. Respira conmigo. ¿Lo oyes? Eso no lo venden en ningún sitio.", Pause = 1.2, Beat = "Respirar", Shot = "PPP:Abu" },
			},
		},
	},

	---------------------------------------------------------------------
	-- ADU03 · EL BANCO DEL PARQUE (de noche, antes de la promesa nueva)
	-- ¿Qué está pasando? El grupo de la infancia se sienta en el mismo banco que a los diez años.
	-- ¿Por qué? Después de la inauguración de Omar, nadie quiere irse a casa.
	-- ¿Qué siente el personaje? Nostalgia y risa; todos han cambiado y nadie ha cambiado.
	-- ¿Qué ve el jugador? El parque de noche → el banco con los amigos apretados → cada uno en su gesto.
	-- ¿Qué quiero que sienta? Que la amistad aguanta. Que lo que le pasó (trabajo, Abu) les importa.
	---------------------------------------------------------------------
	Adu03_Banco = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Parque", Fade = 2 } },
			Light = { { At = 0, Preset = "Noche", Fade = 2 } },
			Music = { { At = 0, Intensity = "Intima" } },
			Actors = {
				{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Yo", Offset = V(-2, 0, -4) } },
				{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Yo", Offset = V(0, 0, -4) } },
				{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Yo", Offset = V(2, 0, -4) } },
				{ At = 0, Use = { Key = "Leire", Npc = "Leire", Anchor = "Yo", Offset = V(4, 0, -5) }, If = { Flags = { "ConocesALeire" } } },
				{ At = 0, Use = { Key = "Mateo", Npc = "Mateo", Anchor = "Yo", Offset = V(-4, 0, -5) }, If = { Flags = { "AyudasteAMateo" } } },
				{ At = 0, Use = { Key = "Hugo", Npc = "Hugo", Anchor = "Yo", Offset = V(5, 0, -3) }, If = { Flags = { "HugoConElGrupo" } } },
				{ At = 2.4, Look = { Key = "Nico", At = "Yo" } },
				{ At = 2.6, Gesture = { Key = "Nico", Play = "Wave" } },
				{ At = 2.8, Mood = { Key = "Omar", Mood = "Joy" } },
			},
			Camera = {
				{ At = 0, Duration = 3, Shot = "General" },
			},
			Dialogue = {
				{ S = "Nico", T = "¡Por fin! Te hemos guardado sitio. Bueno, medio sitio.", Pause = 3.2, A = "Happy", Shot = "PrimerPlano:Nico" },
				{ S = "Omar", T = "Apretaos. A los diez años cabíamos todos y sobraba bocadillo.", Shot = "DosPlanos:Omar,Nico" },
				{ S = "Sara", T = "Técnicamente, hemos crecido un cuarenta por ciento. El banco, un cero.", Shot = "Reaccion:Sara" },
				{ S = "Leire", T = "Quietos. No os mováis. Esta toma es buena.", If = { Flags = { "ConocesALeire" } }, G = "Point" },
				{ S = "Mateo", T = "Yo me siento en el borde. Como el primer día. Ahí no se me caen las cosas.", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Nico", T = "Y lo del trabajo… que te den. Bueno, que te den otro. Uno mejor.", If = { Flags = { "Despedido" } }, Beat = "Mirar" },
				{ S = "Omar", T = "¡Y con ascenso! Hoy invitas tú. Mañana también.", If = { Flags = { "Ascendido" }, NotFlags = { "Despedido" } }, A = "Happy" },
				{ S = "Sara", T = "¿Y tu abu? ¿Fuisteis al final a ver el mar?", If = { Memories = { "AtardecerConAbu" } }, Shot = "PrimerPlano:Sara" },
				{ S = "Yo", T = "Fuimos. Y le prometí volver.", If = { Memories = { "AtardecerConAbu" } }, Beat = "Apartar", Shot = "PrimerPlano:Yo" },
			},
		},
	},

	---------------------------------------------------------------------
	-- UNA VIDA NUEVA EN VALMAR (veteranos) · LA BIENVENIDA EN LA PLAZA
	-- ¿Qué está pasando? Acabas de llegar a la ciudad; Ernesto y Lola son los primeros en saludarte.
	-- ¿Por qué? El cartero conoce cada cara nueva; Lola, a cada estómago vacío.
	-- ¿Qué siente el personaje? Un poco de soledad que se rompe. Ellos, curiosidad y simpatía.
	-- ¿Qué ve el jugador? La plaza → Ernesto llega andando con prisa → Lola sale a su encuentro → se van.
	-- ¿Qué quiero que sienta? Que Valmar es un sitio con gente, y qué tiene que hacer: casa, comer, trabajo.
	---------------------------------------------------------------------
	Adulto_Bienvenida = {
		Skippable = true,
		FadeIn = true,
		Anchors = { Yo = "Player" },
		Tracks = {
			Ambience = { { At = 0, Kind = "Calle", Fade = 1.5 } },
			Music = { { At = 0, Intensity = "Descubrimiento" } },
			Actors = {
				{ At = 0.4, Enter = { Key = "Ernesto", Npc = "Ernesto", From = { "Yo", V(9, 0, -6), true }, To = { "Yo", V(1.8, 0, -3.6), true }, Walk = true } },
				{ At = 4, Look = { Key = "Ernesto", At = "Yo" } },
				{ At = 4.2, Mood = { Key = "Ernesto", Mood = "Joy" } },
				{ At = 12, Enter = { Key = "Lola", Npc = "Lola", From = { "Yo", V(-9, 0, -5), true }, To = { "Yo", V(-1.8, 0, -3.6), true }, Walk = true } },
				{ At = 15.5, Look = { Key = "Lola", At = "Yo" } },
				{ At = 33, Exit = { Key = "Ernesto", To = { "Yo", V(12, 0, -8), true }, Walk = true } },
				{ At = 34, Exit = { Key = "Lola", To = { "Yo", V(-12, 0, -8), true }, Walk = true } },
			},
			Camera = {
				{ At = 0, Duration = 4.2, Shot = "General" },
			},
			Dialogue = {
				{ S = "Ernesto", T = "¡Eh! ¡Cara nueva! Yo conozco todas las caras de Valmar… y todos los perros.", Pause = 4.4, A = "Happy", Shot = "PrimerPlano:Ernesto" },
				{ S = "Ernesto", T = "¿Recién llegad{o/a}? Para recibir cartas hace falta buzón. Y para buzón, casa. Busca los carteles de «Se vende».", G = "Point", Shot = "DosPlanos:Ernesto,Yo" },
				{ S = "Lola", T = "¡Ernesto, no le agobies, que acaba de llegar!", Pause = 0.8, A = "HandsOnHips", Shot = "Medio:Lola" },
				{ S = "Lola", T = "Soy Lola, la de la cafetería. Cuando tengas hambre, ven. La primera, invita la casa.", Shot = "PrimerPlano:Lola" },
				{ S = "Ernesto", T = "Y si buscas trabajo, Correos siempre necesita piernas. ¡Bienvenid{o/a} a Valmar!", G = "Wave", Shot = "DosPlanos:Ernesto,Lola" },
			},
		},
	},
}
