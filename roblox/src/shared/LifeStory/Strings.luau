-- Strings: los textos de la historia de vida, en español, por clave.
-- El código nunca escribe frases: pide una clave. Así, para traducir al inglés basta con añadir
-- otra tabla (o subir estas claves a la tabla de localización de Roblox, ver docs/historia/09).
-- Variables entre llaves: "{place}" se sustituye por el valor que se pase.

local Strings = {}

Strings.es = {
	-- Tarjeta y pantallas
	["STORY.CARD.HEADER"] = "Tu vida",
	["STORY.WAIT.HOURS"] = "Podrás seguir entre las {from}:00 y las {to}:00.",
	["STORY.WAIT.DAYS"] = "Podrás seguir otro día de la semana.",
	["STORY.OFFER.ACCEPT"] = "Vale, te ayudo",
	["STORY.OFFER.DECLINE"] = "Ahora no",
	["STORY.CHAPTER.LABEL"] = "Capítulo",
	["STORY.CARD.SWITCH"] = "Ver: {title}",
	["STORY.DISCOVER.ZONE"] = "Has descubierto {zone}",

	-- Etapas de la vida (se guardan en la biografía al cambiar)
	["STAGE.Bebe"] = "Has nacido.",
	["STAGE.Nino"] = "Ya eres un niño.",
	["STAGE.Adolescente"] = "Ya eres adolescente.",
	["STAGE.AdultoJoven"] = "Ya eres adulto.",
	["STAGE.Adulto"] = "Has entrado en la madurez.",
	["STAGE.Mayor"] = "Has llegado a la edad de la experiencia.",

	-- Puestos que ocupan jugadores o, si no hay, NPC (shared/Roles.luau)
	["ROLE.BARISTA"] = "Barista",
	["ROLE.REPONEDOR"] = "Reponedor",
	["ROLE.BASURERO"] = "Basurero",
	["ROLE.REPARTIDOR"] = "Repartidor",
	["ROLE.PROFESOR"] = "Profesor",
	["ROLE.PROFESOR_UNI"] = "Profesor de universidad",
	["ROLE.ENTRENADOR"] = "Entrenador",
	["ROLE.MEDICO"] = "Médico",
	["ROLE.POLICIA"] = "Policía",
	["ROLE.BOMBERO"] = "Bombero",

	-- Lugares
	["PLACE.HOME"] = "tu casa",
	["PLACE.HOME_SALON"] = "el salón",
	["PLACE.HOME_COCINA"] = "la cocina",
	["PLACE.HOME_DORMITORIO"] = "tu habitación",
	["PLACE.FAMILIA_ABU"] = "Abu",
	["PLACE.FAMILIA_PADRE"] = "tu familia",
	["PLACE.VENTANAL"] = "el ventanal",
	["PLACE.CASA_FAMILIAR"] = "tu casa familiar",
	["PLACE.CUNA"] = "la cuna",
	["PLACE.PLAZA_CENTRO"] = "la Plaza Mayor",
	["PLACE.CAFETERIA_CENTRAL"] = "la Cafetería Central",
	["PLACE.CORREOS"] = "Correos",
	["PLACE.SUPERMERCADO"] = "el supermercado",
	["PLACE.PUNTO_LIMPIO"] = "el Punto Limpio",
	["PLACE.PARADA_BUS"] = "la parada del autobús",
	["PLACE.COLEGIO"] = "el colegio",
	["PLACE.PARQUE"] = "el parque",
	["PLACE.COLUMPIOS"] = "los columpios",
	["PLACE.CENTRO_SALUD"] = "el centro de salud",
	["PLACE.HOSPITAL"] = "el hospital",
	["PLACE.BOMBEROS"] = "el parque de bomberos",
	["PLACE.POLICIA"] = "la comisaría",
	["PLACE.CENTRO_COMERCIAL"] = "el centro comercial",
	["PLACE.GASOLINERA"] = "la gasolinera",
	["PLACE.OCIO"] = "el cine y los recreativos",
	["PLACE.UNIVERSIDAD"] = "la Universidad de Valmar",
	["PLACE.ESTADIO_UNI"] = "el Estadio Universitario",
	["PLACE.ESTADIO_ALTAMAR"] = "el Estadio Altamar",
	["PLACE.PLAZA_FINANCIERA"] = "la Plaza Financiera",
	["PLACE.PLAYA"] = "Playa Dorada",
	["PLACE.GRANJA"] = "las granjas de Villaverde",

	-- Capítulos
	["CHAPTER.BEBE.TITLE"] = "Primeros pasos",
	["CHAPTER.BEBE.INTRO"] = "Acabas de llegar al mundo. Todo es nuevo.",
	["CHAPTER.BEBE.OUTRO"] = "Han pasado varios años…",
	["CHAPTER.NINO.TITLE"] = "El colegio",
	["CHAPTER.NINO.INTRO"] = "Hoy empieza algo grande: el colegio.",
	["CHAPTER.NINO.OUTRO"] = "Has crecido mucho.",
	["CHAPTER.NINO_PUENTE.TITLE"] = "Tu barrio",
	["CHAPTER.NINO_PUENTE.INTRO"] = "Ya eres mayor para salir a jugar. Los Pinos te espera.",
	["CHAPTER.NINO_PUENTE.OUTRO"] = "Pasan los años…",
	["CHAPTER.NUEVA_VIDA.TITLE"] = "Una nueva vida en Valmar",
	["CHAPTER.NUEVA_VIDA.INTRO"] = "Valmar: donde el valle se encuentra con el mar. Aquí empieza tu historia.",
	["CHAPTER.NUEVA_VIDA.OUTRO"] = "Valmar ya es tu ciudad.",

	["TRANSITION.ANOS_DESPUES"] = "Han pasado varios años…",
	["TRANSITION.CRECES"] = "Pasan los años: el colegio, el instituto, los amigos… Y un día, sin darte cuenta, ya has crecido.",

	-- Bebé
	["QUEST.BEBE_CAMINAR.TITLE"] = "Aprende a caminar",
	["QUEST.BEBE_CAMINAR.S1"] = "Intenta levantarte (pulsa «¡Levántate!»)",
	["QUEST.BEBE_CAMINAR.S2"] = "Da tus primeros pasos",
	["QUEST.BEBE_CAMINAR.S3"] = "Llega hasta Abu",
	["QUEST.BEBE_CASA.TITLE"] = "Explora tu casa",
	["QUEST.BEBE_CASA.S1"] = "Recorre la casa",
	["QUEST.BEBE_CASA.SALON"] = "Entra en el salón",
	["QUEST.BEBE_CASA.COCINA"] = "Mira la cocina",
	["QUEST.BEBE_CASA.DORMITORIO"] = "Ve a tu habitación",
	["QUEST.BEBE_CASA.TELE"] = "Mira la tele del salón",
	["QUEST.BEBE_CASA.JUGUETES"] = "Juega con tus bloques en tu habitación",
	["QUEST.BEBE_CASA.S2"] = "Tienes hambre: pide el biberón a tu familia en la cocina",
	["QUEST.BEBE_SALIR.TITLE"] = "Es hora de salir",
	["QUEST.BEBE_SALIR.S1"] = "Asómate al ventanal del salón",

	-- Puente de niño
	["QUEST.BARRIO.TITLE"] = "Tu barrio",
	["QUEST.BARRIO.PARQUE"] = "Sal a jugar a {place}",
	["QUEST.BARRIO.COLEGIO"] = "Asómate a {place}: pronto será tu colegio",

	-- Tutorial de bebé: interfaz, objetos y personas
	["BABY.STAND_BUTTON"] = "¡Levántate!",
	["BABY.TOO_SMALL_OUT"] = "Aún no tienes edad para salir de casa sin tu familia.",
	["BABY.PROMPT.TALK"] = "Hablar",
	["BABY.PROMPT.PLAY"] = "Jugar",
	["BABY.PROMPT.TV"] = "Mirar la tele",
	["BABY.PROMPT.WINDOW"] = "Mirar por la ventana",
	["BABY.OBJECT.TOYS"] = "Bloques",
	["BABY.OBJECT.TV"] = "Tele",
	["BABY.OBJECT.WINDOW"] = "Ventanal",
	["BABY.TOYS"] = "¡Una torre de bloques! ¡Y se cae! Otra vez…",
	["BABY.TV"] = "En la tele salen dibujos del Faro de la Punta.",
	["NPC.ABU_ROSA"] = "Abu Rosa",
	["NPC.ABU_TOMAS"] = "Abu Tomás",
	["NPC.MAMA"] = "Mamá",
	["NPC.PAPA"] = "Papá",

	-- Diálogos del tutorial de bebé (ver docs/historia/08-dialogos.md)
	["DLG.ABU.BEBE.LEVANTATE"] = "Vamos, tesoro. Intenta levantarte.",
	["DLG.ABU.BEBE.VEN"] = "Agárrate bien… ¡eso es! Ahora, ven con Abu al salón.",
	["DLG.ABU.BEBE.PASOS"] = "¡Has llegado hasta aquí sin ayuda! Esto hay que celebrarlo con una foto.",
	["DLG.ABU.BEBE.EXPLORA"] = "¿Por qué no exploras la casa? La cocina, la tele del salón, tus bloques…",
	["DLG.ABU.BEBE.BARRIGA"] = "Uy, esa barriguita… Ve a la cocina, que te preparan el biberón.",
	["DLG.ABU.BEBE.VENTANA"] = "¿Ves el ventanal? Asómate: ahí fuera está Valmar.",
	["DLG.ABU.BEBE.CIUDAD"] = "Eso de ahí es Valmar. Algún día lo recorrerás entero.",
	["DLG.ABU.BEBE.GENERICO"] = "Qué ganas tienes de explorar, ¿eh?",
	["DLG.FAMILIA.BIBERON"] = "¡Aquí está tu biberón! Qué bien comes.",
	["DLG.FAMILIA.GENERICO"] = "¿Me ayudas a cocinar? Bueno… cuando seas un poco mayor.",

	-- Cinemáticas (docs/historia/10, apartado 10.17)
	["CINE.SKIP"] = "Saltar ▶▶",
	["CINE.NACIMIENTO.LUGAR"] = "Valmar",
	["CINE.NACIMIENTO.CUANDO"] = "Un día de primavera, en Los Pinos",
	["CINE.VALMAR.TITULO"] = "Valmar",
	["CINE.VALMAR.LEMA"] = "Donde el valle se encuentra con el mar",
	["CINE.ANOS.RECUERDOS"] = "El parque, las bicis, los primeros amigos…",
	["CINE.CRECES.COLEGIO"] = "El colegio…",
	["CINE.CRECES.ESTUDIOS"] = "El instituto, los exámenes, los primeros sueños…",
	["CINE.CRECES.SUENOS"] = "Los amigos, los veranos, las grandes decisiones…",
	["CINE.CRECES.FINAL"] = "…y un día, sin darte cuenta, ya has crecido.",
	["CINE.LLEGADA.NARRADOR"] = "Aquí empieza tu vida adulta. ¿Qué harás con ella?",
	["DLG.ABU.NACER.01"] = "Te damos la bienvenida al mundo, {nombre}. Valmar te estaba esperando.",
	["DLG.ABU.NACER.02"] = "Mira qué manitas tan pequeñas… ¡y qué ganas de explorar!",
	["STORY.AUDIO.ON"] = "🔊",
	["STORY.AUDIO.OFF"] = "🔇",

	-- Límites por edad
	["LIMIT.Work"] = "Aún no tienes edad para trabajar.",
	["LIMIT.ClaimHome"] = "Para tener casa propia tienes que ser mayor de edad.",
	["LIMIT.Travel"] = "Aún no tienes edad para coger el autobús sin compañía.",

	-- Niño
	["QUEST.PRIMER_DIA.TITLE"] = "Tu primer día de colegio",
	["QUEST.PRIMER_DIA.SALIR"] = "Sal de casa",
	["QUEST.PRIMER_DIA.IR"] = "Ve andando a {place}",
	["QUEST.PRIMER_DIA.AULA"] = "Encuentra tu aula",
	["QUEST.PRIMER_DIA.PROFE"] = "Conoce a tu profesor",
	["QUEST.PRIMER_DIA.CLASE"] = "Completa tu primera clase",
	["QUEST.PRIMER_DIA.RECREO"] = "Sal al recreo",
	["QUEST.PRIMER_DIA.COMPANERO"] = "Habla con un compañero",
	["QUEST.PRIMER_DIA.VOLVER"] = "Vuelve a {place}",

	-- Capítulo puente
	["QUEST.LLEGADA.TITLE"] = "Llegar a Valmar",
	["QUEST.LLEGADA.PLAZA"] = "Ve a {place}",
	["QUEST.LLEGADA.CASA"] = "Busca un cartel de SE VENDE y consigue tu casa",
	["QUEST.LLEGADA.COMER"] = "Come algo: el viaje ha sido largo",
	["QUEST.SUELDO.TITLE"] = "Ganarte la vida",
	["QUEST.SUELDO.TRABAJA"] = "Busca un cartel de SE BUSCA y trabaja ({count}/{total})",
	["QUEST.REGION.TITLE"] = "Conoce la región",
	["QUEST.REGION.DECIDE"] = "Decide adónde irás en tu primer día libre",
	["QUEST.REGION.PREGUNTA"] = "Tienes un día libre. ¿Qué te apetece descubrir?",
	["QUEST.REGION.OPT_CAMPUS"] = "La universidad y el campus",
	["QUEST.REGION.OPT_PLAYA"] = "La playa y el paseo marítimo",
	["QUEST.REGION.OPT_CAMPO"] = "El campo y las granjas",
	["QUEST.REGION.PARADA"] = "Ve a {place}",
	["QUEST.REGION.IR_CAMPUS"] = "Viaja en autobús y llega a {place}",
	["QUEST.REGION.IR_PLAYA"] = "Viaja en autobús y llega a {place}",
	["QUEST.REGION.IR_CAMPO"] = "Viaja en autobús y llega a {place}",

	-- Secundarias
	["QUEST.MOCHILA.TITLE"] = "La mochila perdida",
	["QUEST.MOCHILA.OFFER"] = "Una niña te para en la puerta del colegio: «He perdido mi mochila en el parque… ¿me ayudas a buscarla?»",
	["QUEST.MOCHILA.BUSCA"] = "Busca la mochila en {place}",
	["QUEST.MOCHILA.DEVUELVE"] = "Devuélvela en {place}",
	["QUEST.MEDICINAS.TITLE"] = "Medicinas urgentes",
	["QUEST.MEDICINAS.OFFER"] = "Te llaman de Correos: «Hay un paquete urgente de medicinas. ¿Puedes llevarlo tú?»",
	["QUEST.MEDICINAS.LLEVA"] = "Lleva las medicinas a {place}",
	["QUEST.PLAYA.TITLE"] = "Una tarde de playa",
	["QUEST.PLAYA.OFFER"] = "Huele a sal y a helado. ¿Te quedas a pasar la tarde en la playa?",
	["QUEST.PLAYA.MERIENDA"] = "Merienda algo",
	["QUEST.PLAYA.ATARDECER"] = "Disfruta del atardecer",

	-- Momentos de vida (lo que se celebra y se guarda en tu biografía)
	["MOMENT.PRIMEROS_PASOS"] = "Has dado tus primeros pasos.",
	["MOMENT.CONOCES_FAMILIA"] = "Has conocido a tu familia.",
	["MOMENT.YA_ERES_NINO"] = "Ya no eres un bebé.",
	["MOMENT.TU_COLEGIO"] = "Has visto tu futuro colegio.",
	["MOMENT.YA_ERES_ADULTO"] = "Empieza tu vida adulta.",
	["MOMENT.PRIMER_DIA_COLEGIO"] = "Has terminado tu primer día de colegio.",
	["MOMENT.PRIMER_HOGAR"] = "Ya tienes un hogar en Valmar.",
	["MOMENT.PRIMER_SUELDO"] = "Has cobrado tu primer sueldo en Valmar.",
	["MOMENT.CONOCES_REGION"] = "Hoy has descubierto un rincón nuevo de Valmar.",
	["MOMENT.AYUDASTE_NINO"] = "Has ayudado a una niña del barrio. No lo olvidará.",
	["MOMENT.MEDICINAS"] = "Gracias a ti, alguien tiene hoy sus medicinas.",
	["MOMENT.TARDE_PLAYA"] = "Has visto atardecer en Playa Dorada.",
}

-- Devuelve el texto de una clave con sus variables sustituidas. Si falta, devuelve la clave
-- (así se ve enseguida qué texto falta en lugar de romper el juego).
function Strings.get(key: string, args: { [string]: any }?): string
	local text = Strings.es[key]
	if not text then
		return key
	end
	if args then
		text = text:gsub("{(%w+)}", function(name)
			local value = args[name]
			return if value ~= nil then tostring(value) else "{" .. name .. "}"
		end)
		-- Contracciones del español al rellenar variables: "a el parque" -> "al parque", "de el" -> "del"
		text = text:gsub("%f[%a]([Aa]) el ", "%1l "):gsub("%f[%a]([Dd])e el ", "%1el ")
	end
	return text
end

function Strings.has(key: string): boolean
	return Strings.es[key] ~= nil
end

return Strings
