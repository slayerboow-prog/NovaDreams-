-- Consecuencias del arco «La pandilla» (el bien o el mal): llegan horas después de lo que hiciste.
--   Eco_Camaras    si robaste en el súper y escapaste: las cámaras te grabaron
--   Eco_Redada     si entraste en el negocio de las camisetas falsas: la policía desmantela el puesto
--   Eco_RayoAdulto ya de adulto: Rayo vuelve. Lo que pasa depende de todo lo que elegiste

local V = Vector3.new

local DELINCUENTE = { Flags = { "Camino_Delincuente" } }
local CAMBIO = { Flags = { "RayoCambia" } }

return {
	{
		Id = "Eco_Camaras",
		Kind = "Side",
		Title = "Llaman a la puerta",
		Description = "Alguien llama a la puerta. Es la policía.",
		Type = "Consecuencia (2 h después de «La noche del supermercado», si robaste y escapaste)",
		Duration = { 8, 12 },
		Npcs = { "Ines", "Familia", "Paco" },
		Requires = { Stage = { Min = "Adolescente" } },
		Moment = "Las cámaras del supermercado",
		Steps = {
			{ Type = "Talk", Npc = "Ines", Dialogue = "Puerta", Text = "Llaman a la puerta: es la agente Inés",
				Actors = { { Npc = "Ines", Place = "CercaDeTi", Offset = V(0, 0, -5) }, { Npc = "Familia", Place = "CercaDeTi", Offset = V(-3, 0, -3) } } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Basurero" }, Count = 3, Place = "PuntoLimpio",
				Text = "Servicio a la comunidad: limpia en el Punto Limpio ({count}/{total})" },
		},
		Dialogues = {
			Puerta = { Lines = {
				{ S = "Ines", T = "Buenas tardes. La puerta del almacén del súper tiene cámara. Y se te ve muy bien la cara. Muy bien." },
				{ S = "Familia", T = "¿El súper de Paco? ¿Tú? ¿Y lo has escondido todo este tiempo? …No sé qué me duele más." },
				{ S = "Ines", T = "Por ser menor y la primera vez: servicio a la comunidad en el Punto Limpio. Y hablar con Paco." },
				{ Ask = "¿Qué dices?", Options = {
					{ T = "«Fui yo. Lo siento. Se lo diré a Paco a la cara.»", Effects = { Flags = { "PerdonPaco" }, Traits = { Responsabilidad = 1 }, Rel = { Familia = 2, Paco = 2 } }, Then = {
						{ S = "Ines", T = "Eso ya es empezar a arreglarlo. Más de lo que hacen muchos adultos." },
					} },
					{ T = "«Fue idea de Rayo.»", Effects = { Traits = { Rebeldia = 1 }, Rel = { Rayo = -8 } }, Then = {
						{ S = "Ines", T = "Puede. Pero la lata la cogiste tú. Cada uno responde de lo suyo." },
					} },
				} },
			}, Effects = { Flags = { "AvisoPolicia" }, Rel = { Familia = -10, Paco = -8 } } },
		},
	},

	{
		Id = "Eco_Redada",
		Kind = "Side",
		Title = "La redada",
		Description = "La policía ha encontrado el puesto de camisetas falsas.",
		Type = "Consecuencia (3 h después de «El cruce de caminos», si entraste en el negocio)",
		Duration = { 4, 6 },
		Npcs = { "Ines", "Rayo" },
		Requires = { Stage = { Min = "Adolescente" } },
		Moment = "La redada de las camisetas",
		Steps = {
			{ Type = "Talk", Npc = "Ines", Dialogue = "Redada", Text = "La agente Inés te está buscando",
				Actors = { { Npc = "Ines", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
		},
		Dialogues = {
			Redada = { Lines = {
				{ S = "Ines", T = "Otra vez tú. El puesto de camisetas del estadio. Tenemos fotos, tenemos las bolsas y tenemos a Rayo." },
				{ S = "Ines", T = "Esto ya no son unas latas: es vender falsificaciones. Queda en tu expediente de menores. Y hay una multa: lo que ganaste, y algo más." },
				{ S = "Ines", T = "Y ya te conocemos del súper. Esto empieza a ser una costumbre.", If = { Flags = { "AvisoPolicia" } } },
				{ Ask = "¿Qué haces?", Options = {
					{ T = "«Lo dejo. Todo. Se acabó el negocio.»", Effects = { Flags = { "Arrepentido" }, Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Ines", T = "Ojalá. Lo he oído muchas veces. Me gustaría que tú fueras de los que lo cumplen." },
					} },
					{ T = "No dices nada", Effects = { Traits = { Rebeldia = 1 } }, Then = {
						{ S = "Ines", T = "Muy bien. Silencio. Como quieras. Nos volveremos a ver. Espero que no." },
					} },
				} },
			}, Effects = { Flags = { "Antecedentes" }, Spend = 80, Rel = { Familia = -8 } } },
		},
	},

	{
		Id = "Eco_RayoAdulto",
		Kind = "Side",
		Title = "Rayo",
		Description = "Alguien del instituto te está buscando. Hace años que no le ves.",
		Type = "Consecuencia (ya de adulto, de «El cruce de caminos»)",
		Duration = { 6, 15 },
		Npcs = { "Rayo", "Bruno" },
		Requires = { Stage = { Min = "AdultoJoven" } },
		Moment = "Rayo volvió a aparecer",
		Steps = {
			{ Type = "Talk", Npc = "Rayo", Dialogue = "Vuelve", Text = "Rayo te está buscando",
				Actors = { { Npc = "Rayo", Place = "CercaDeTi", Offset = V(0, 0, -5), Mode = "Wave" } } },
			-- Si sigues en el mal camino: «un último trabajo»
			{ Type = "Choice", Key = "UltimoTrabajo", Text = "Rayo te ofrece «un último trabajo». ¿Qué haces?", If = DELINCUENTE,
				Options = {
					{ Id = "Aceptar", Text = "Aceptar: llevar la furgoneta a San Roque sin preguntar", Effects = { Traits = { Rebeldia = 2 } } },
					{ Id = "Rechazar", Text = "Rechazar: «Se acabó, Rayo. Para siempre.»", Effects = { Unflags = { "Camino_Delincuente" }, Flags = { "Camino_Trabajador", "Redimido" }, Traits = { Responsabilidad = 2 } } },
				},
				Actors = { { Npc = "Rayo", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
			{ Type = "Event", Event = "Traveled", Match = { Town = "San Roque" }, Place = "ParadaBus", Text = "Lleva la furgoneta a San Roque (coge la carretera del oeste)",
				If = { Choices = { UltimoTrabajo = "Aceptar" } } },
			{ Type = "Talk", Npc = "Bruno", Dialogue = "Control", Text = "Un control de policía. El agente es… Bruno",
				If = { Choices = { UltimoTrabajo = "Aceptar" } },
				Actors = { { Npc = "Bruno", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
			{ Type = "Scene", Dialogue = "Rechazar", If = { Choices = { UltimoTrabajo = "Rechazar" } },
				Actors = { { Npc = "Rayo", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
		},
		Dialogues = {
			Vuelve = { Lines = {
				-- Rayo cambió (le llevaste al taller de Tomás)
				{ S = "Rayo", T = "¡Eh! ¿Te acuerdas de mí? Mira: «Taller Rayo». Mío. Tomás se jubiló y me lo dejó. El viejo al final me quería.", If = CAMBIO },
				{ S = "Rayo", T = "Llegué a las ocho menos cuarto aquel día. Y todos los días después. Si alguna vez se te rompe el coche, es gratis. Para siempre.", If = CAMBIO },
				{ S = "Rayo", T = "Nunca te lo dije: me salvaste. Así, tal cual. Ya está. No me hagas repetirlo.", If = CAMBIO },
				-- Sigues en el mal camino
				{ S = "Rayo", T = "Cuánto tiempo, socio o socia. Sigo con mis negocios. Más grandes. Y tengo algo para ti.", If = DELINCUENTE },
				{ S = "Rayo", T = "Una furgoneta. La llevas a San Roque, la dejas en un aparcamiento y te vas. No preguntes qué lleva. Doscientos por un viaje.", If = DELINCUENTE },
				-- Nunca entraste del todo, o saliste
				{ S = "Rayo", T = "Hola… Supongo que me recuerdas. El del muro, el del súper. Te debo una disculpa. Te arrastré a cosas.", If = { NotFlags = { "RayoCambia", "Camino_Delincuente" }, Flags = { "HicistePellas" } } },
				{ S = "Rayo", T = "Hola. Tú eres la persona que siempre me decía que no. ¿Sabes? Tenías razón. En todo.", If = { NotFlags = { "RayoCambia", "Camino_Delincuente", "HicistePellas" } } },
				{ S = "Rayo", T = "Ahora trabajo en el puerto de Playa Dorada. Cargando barcos. Es duro. Pero duermo bien. Eso antes no pasaba.", If = { NotFlags = { "RayoCambia", "Camino_Delincuente" } } },
			}, Effects = { Rel = { Rayo = 4 } } },
			Control = { Lines = {
				{ S = "Bruno", T = "Buenas tardes, documentación del vehículo… ¿{nombre}? ¿Tú?" },
				{ S = "Bruno", T = "Abre la parte de atrás. …Cajas sin papeles. Móviles. Muchos. Esto es mercancía robada, {nombre}." },
				{ S = "Bruno", T = "Yo fui el malo del colegio. Tú me enseñaste que se podía cambiar. Y ahora estás tú aquí. Del otro lado." },
				{ S = "Bruno", T = "Tengo que llevarte. Es mi trabajo. Pero voy a contarle al juez que colaboraste. Si colaboras." },
				{ Ask = "¿Qué haces?", Options = {
					{ T = "«Colaboro. Os cuento todo lo de Rayo. Se acabó.»", Effects = { Flags = { "Detenido", "Colaboraste", "Redimido", "Camino_Trabajador" }, Unflags = { "Camino_Delincuente" }, Spend = 200, Rel = { Bruno = 6, Rayo = -20, Familia = -5 } }, Then = {
						{ S = "Bruno", T = "Bien. Te pondrán una multa grande y un tiempo de servicio a la comunidad. Pero es una salida. Aprovéchala." },
						{ S = "Narrador", T = "Esa noche duermes en una celda. Por la mañana te recoge tu familia. Nadie dice nada. Te abrazan igual." },
					} },
					{ T = "No dices nada", Effects = { Flags = { "Detenido", "Antecedentes" }, Spend = 400, Traits = { Rebeldia = 1 }, Rel = { Bruno = -6, Familia = -12 } }, Then = {
						{ S = "Bruno", T = "…Como quieras. Lo siento mucho. De verdad." },
						{ S = "Narrador", T = "Juicio rápido. Una multa enorme y un año de servicio a la comunidad. Tu trabajo se entera. Todo se complica." },
					} },
				} },
			} },
			Rechazar = { Lines = {
				{ S = "Rayo", T = "¿Para siempre? …Vale. Ya me lo imaginaba. Tienes cara de «para siempre»." },
				{ S = "Rayo", T = "Oye… si algún día yo también quiero salir, ¿me ayudarías?" },
				{ S = "Narrador", T = "Le das tu número de verdad. Él lo guarda. No sabes si llamará. Pero lo guarda." },
			} },
		},
	},
}
