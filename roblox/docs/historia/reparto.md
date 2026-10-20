# Reparto: la biblia de voces

Guía para quien escriba diálogos y escenas. Cada personaje importante tiene aquí su voz, cómo se mueve y
tres frases de ejemplo. La fuente de verdad en el juego es `src/shared/LifeStory/Cast.luau`:

- `Bio`: una línea (la primera frase sale en la ficha «¿Quién es?»).
- `Perfil`: personalidad, forma de hablar (vocabulario, ritmo, muletillas), emociones, relaciones, motivación y arco por etapa.
- `Actuar`: emoción de base (`Mood`, nombres de `ActorMoods`) y tendencias (`Fidget`, `Tempo`, `Gaze`, `Gestos`).
- `Edades`: escala y ropa por etapa del jugador, para quien crece contigo (montajes de etapa).

Funciones útiles: `Cast.perfil(id)`, `Cast.acting(id)`, `Cast.defaultMood(id)`, `Cast.scaleAt(id, etapa)`,
`Cast.atStage(id, etapa)` y `Cast.bioText(id)`. La prueba es `lune run scripts/test-cast.luau`.

## Reglas para todos

1. **Una voz se reconoce sin el nombre.** Si tapas quién habla y la frase podría ser de cualquiera, reescríbela.
2. **Frases cortas.** Máximo unos 150 caracteres. Si es más larga, pártela y mete una reacción en medio.
3. **Nada de dobletes.** Nunca «tranquilo o tranquila»: usa `{o/a}` («Estás guap{o/a}») o una frase neutra.
4. **Las muletillas son especia, no plato.** Como mucho una por escena y por personaje.
5. **Recordar es querer.** Si el jugador hizo algo (el nombre del grupo, la promesa a Abu, una pelea), alguien lo nombra.
6. **Mostrar antes que narrar.** Lo que pueda hacer un actor (un gesto, un silencio, una mirada), no lo cuente el narrador.
7. **El jugador («Yo») habla poco.** Contesta, elige y reacciona; no da discursos.

## Cómo se mueven (Actuar)

El motor puede usar `Actuar` como emoción de base de cada actor. En una escena, una línea con `A`/`G` o un
`Mood` propio siempre manda sobre esto.

| Tendencia | Quién | En pantalla |
|---|---|---|
| Nervios (`Nervous`, `Fidget` alto) | Mateo, Pip, Julia, Don Escamas | manos inquietas, cambia el peso de pierna, mira alrededor |
| Alegría (`Joy`, `Tempo` alto) | Nico, Dani, Iván, Cosme, Rubén | gestos rápidos, postura abierta |
| Calma que sostiene la mirada (`Gaze = "Hold"`) | Abu, Lucía, Carmen, Bruno, Cósimo, Candela | pocos gestos, mirada fija |
| Mirada que se escapa (`Avoid`/`Down`) | Hugo, Leire, Nerea, Mateo | cabeza baja, postura cerrada |

## Quién crece contigo (Edades)

Los compañeros de clase (`Kid`) miden 0,65 en el colegio, 0,85 en el instituto y 1 de adultos. De mayores
pierden la mochila y llevan la ropa de su oficio:

- **Nico**: equipación roja de joven; azul y blanca de Altamar de adulto.
- **Bruno**: uniforme de policía de adulto.
- **Sara**: bata blanca de investigadora.
- **Omar**: blanco de cocina.
- **Mateo**: camisa de ingeniero.
- **Hugo**: chaqueta de escritor.
- **Leire**: negro y manga larga, de documentalista.

**Dani** va siempre una etapa por detrás. **Familia** y **Lucía** tienen canas de adultos.
En la etapa Mayor, todos andan encorvados.
Para un montaje: `Cast.atStage("Nico", "Adulto")` da la ropa, la escala (`Scale`) y la edad (`Age`).

---

## La familia

### Familia (Mamá o Papá, según la casa)
- **Quién es.** Quiere muchísimo y lo demuestra con preguntas, comida y fotos. Va siempre con prisa, pero nunca tanta como para no pararse a mirarte. Le da miedo que crezcas demasiado rápido y lo disimula con bromas.
- **Cómo habla.** Ráfagas de tres o cuatro preguntas seguidas sin esperar respuesta, y luego una frase corta y sincera. Se corrige a sí mismo: «Ni un paso más. …Bueno, hasta la esquina». Usa palabras de casa: «cariño», «a ver», «venga».
- **Muletillas.** «Cuéntamelo todo. Bueno, lo que quieras.» · «¿Has comido?» · «Esta va a la nevera.» · «Qué rápido pasa todo.»
- **Emociones.** De niño, orgullo exagerado. De adolescente, preocupación callada. Enfadado no grita: se queda quieto y dice «No sé qué me duele más». Llora a escondidas, en las despedidas.
- **Arco.**
  - Bebé: agotamiento feliz.
  - Niño: te espera en la puerta.
  - Adolescente: aprende a soltar.
  - Adulto joven: mensajes y táperes.
  - Adulto: canas y calma; empieza a contarte su vida.
- **Ejemplos:**
  - «¿Qué tal? ¿Has comido? ¿Te han puesto deberes? ¿Quién es ese Omar del que hablas tanto? …Vale, vale. Cuando quieras.»
  - «Ese dibujo va a la nevera. Al centro. Quito la factura de la luz, que es fea.»
  - «No te voy a preguntar nada. …Solo una cosa. ¿Estás bien? Con eso me vale.»

### Abu (Abu Rosa o Abu Tomás)
- **Quién es.** Tranquilidad absoluta con una picardía escondida. Cuenta la historia de Valmar adornada. Ganó el Gran Torneo de Tirachinas de 1962 y lo recuerda a menudo.
- **Cómo habla.** Lento, con pausa antes del remate. Refranes, algunos inventados. Fechas exactas de cosas absurdas. Repite la palabra importante: «Nunca, nunca, NUNCA».
- **Muletillas.** «Un consejo de los de antes:» · «En mis tiempos a eso lo llamábamos…» · «Se sale. Siempre se sale.»
- **Emociones.** La alegría le sale como travesura; la tristeza, en silencio y mirando por la ventana. No se enfada: se decepciona.
- **Arco.**
  - De niño: cómplice (el tirachinas, la regla de oro).
  - De adolescente: te entiende cuando nadie lo hace.
  - De adulto joven: se hace mayor de verdad (el hospital, la promesa, el atardecer).
  - Después: recuerdo y presencia.
- **Ejemplos:**
  - «Un consejo de los de antes: el primer día, sonríe a una persona que no conozcas. Solo a una.»
  - «En 1971 un gato me robó una sardina delante del alcalde. Aún le guardo rencor. Al alcalde.»
  - «Prométemelo con la boca pequeña, que con la grande se rompen. …Así. Ya está guardado.»

## El colegio

### Lucía (tutora de 1.º A)
- **Quién es.** Exigente porque cree en vosotros. Estudió en ese mismo colegio (la foto de 1998, las coletas). Su humor es seco y lo suelta sin cambiar la cara.
- **Cómo habla.** Frases muy cortas: una orden, un punto. La ternura llega en una sola frase, al final. Cuando se enfada, baja la voz.
- **Muletillas.** «Silencio.» · «No me contestes. Tu cara ya me ha contestado.» · «Y ahora: los deberes.»
- **Arco.** Tutora firme en el colegio. De adulta, directora con la foto de 1998 en la pared.
- **Ejemplos:**
  - «Silencio. Gracias. Ahora sí: buenos días.»
  - «Sin acusar a nadie sin pruebas. Eso también es de mayores.»
  - «Bien hecho. …No te acostumbres, que mañana hay examen.»

### Nico
- **Quién es.** Deportista, impulsivo, competitivo y generoso. Mete la pata rápido y pide perdón rápido (y aprende a pedirlo bien). Sueña con ser futbolista.
- **Cómo habla.** Exclamaciones; empieza gritando tu nombre. Cuando algo le duele, se le acaban los signos de exclamación.
- **Muletillas.** «¡{nombre}!» · «¿Una carrera?» · «…Me pasé.»
- **Arco.**
  - Niño: capitán del patio.
  - Adolescente: el rumor y la pelea con Omar.
  - Adulto: profesional en Altamar, con tu predicción de la cápsula del tiempo enmarcada.
- **Ejemplos:**
  - «¡{nombre}! ¡Hasta la fuente! ¡El último invita a cromos!»
  - «Omar. Me pasé. No hay excusa. …Te echo de menos en el recreo.»
  - «¿Has visto? ¿Lo has visto? ¡Por la escuadra! ¡Golazo histórico!»

### Sara
- **Quién es.** Curiosa, científica y perfeccionista. Necesita el porqué de todo. Le encantan los hongos.
- **Cómo habla.** Rapidísimo, con palabras largas («técnicamente», «hipótesis»). Encadena ideas con «y además» y frena en seco cuando nadie la sigue.
- **Muletillas.** «Técnicamente…» · «Tengo una hipótesis.» · «Yo quería hablar de hongos.»
- **Arco.**
  - Niña: la investigadora del grupo.
  - Adolescente: la presión por las notas.
  - Adulta: micóloga, con un hongo con su nombre (*Mycena sarae*).
- **Ejemplos:**
  - «Tengo una hipótesis. Y además una segunda hipótesis por si falla la primera. Y además…»
  - «Técnicamente, hoy no hay cebolla en el menú.»
  - «Esto lleva ahí muchos años. Mira qué amarillo. Es pr-e-cio-so.»

### Omar
- **Quién es.** Artista tranquilo, siempre con hambre y un lápiz. Sus dibujos son pistas. Cuando algo le duele, se esconde.
- **Cómo habla.** Pausado. Dice algo serio y lo remata con una tontería sobre comida. Se habla a sí mismo.
- **Muletillas.** «Buscando… un bocadillo.» · «Me lo digo a mí mismo.» · «No lloro. Es la cebolla.»
- **Arco.**
  - Niño: dibuja el misterio.
  - Adolescente: crece de golpe, y el rumor le rompe.
  - Adulto: «La Cafetería de Omar», donde reúne al grupo.
- **Ejemplos:**
  - «(susurrando) Si nos pillan, yo solo pasaba por aquí. Buscando… un bocadillo.»
  - «Lo he dibujado antes de que pasara. Ahora me da un poco de miedo mi lápiz.»
  - «Gracias. Ya está. No lloro. Es la cebolla.»

### Mateo
- **Quién es.** Tímido, nuevo en el barrio, colecciona cromos. Se le caen las cosas. Lo ve todo y casi nunca lo dice. Cuando confía, es el más leal.
- **Cómo habla.** Bajito, con puntos suspensivos y tu nombre delante. Se corrige solo.
- **Muletillas.** «{nombre}… yo lo vi.» · «En mi otro cole…» · «Perdón. Perdón.»
- **Cómo se mueve.** Nervioso (`Fidget` alto): manos ocupadas, mirada que se escapa.
- **Arco.** Del nuevo con los libros por el suelo a ingeniero en TecnoVal: la pasarela del río.
- **Ejemplos:**
  - «En mi otro cole también había una sala así. Era el cuarto de la fregona.»
  - «{nombre}… yo lo vi. Pero no se lo digas a nadie. Bueno, a Lucía sí.»
  - «He tocado el balón dos veces. Dos. Es mi récord.»

### Dani
- **Quién es.** El hermano pequeño de Mateo. Todo lo pregunta y todo lo toca. Va siempre una etapa por detrás.
- **Ejemplos:**
  - «¿Y por qué?»
  - «¡Mi balón! ¡Otra vez! ¡Otra vez!»
  - «Mateo dice que eres su amigo. ¿Tú también eres mío?»

### Bruno
- **Quién es.** Líder de «los malotes». Fanfarrón porque necesita que le miren, y su hermano mayor le presiona. Le culpan de todo, y a veces no ha sido él. Su arco es empezar de cero.
- **Cómo habla.** Frases cortas y con fuerza. Cuando se rompe, un «Ya.» y silencio. De adulto, formal de uniforme.
- **Muletillas.** «Siempre soy yo, ¿no?» · «Empezamos de cero, ¿no?» · «Gracias. De verdad.»
- **Arco.**
  - Niño: la mochila, el enfrentamiento y la primera vez que alguien no le culpa.
  - Adolescente: intenta cambiar y nadie le cree.
  - Adulto: agente Bruno.
- **Ejemplos:**
  - «¡YA ESTÁ BIEN! ¡Esta vez NO he sido yo!»
  - «…Gracias por no culparme. No se lo digas a nadie.»
  - «Agente Bruno, para servirle. Hoy he encontrado tres gatos. Récord.»

### Rubén
- **Quién es.** El bromista de Bruno. Quiere caer bien. No piensa antes de actuar.
- **Ejemplos:**
  - «¿Buscas esto?»
  - «Bruno me va a matar. Bueno, a matar no. Pero se va a enfadar.»
  - «Lo de la mochila fue hace mil años. …Perdón. Ya está, ya lo he dicho.»

### Hugo
- **Quién es.** Va con Bruno sin querer. Lee libros de piratas. Encuentra su voz como periodista y como escritor.
- **Cómo habla.** Poco y bajito, con frases que se cortan. Cuando habla de libros, se le acelera.
- **Muletillas.** «En un libro que leí…» · «Lo he leído.» · «…Nadie se fija en eso.»
- **Ejemplos:**
  - «En un libro que leí, detrás de una puerta así había un pasadizo al otro lado del mundo.»
  - «Un buen periodista protege a sus fuentes. Lo he leído. Y ahora lo entiendo.»
  - «Te la dedico en la primera página. …Ya. Me emociono yo solo.»

### Álex, Vega e Iker
- **Álex.** Portera, directa, todo lo convierte en apuesta (sin dinero). Seca.
  - «Puede. Puede que sí. Pero la información es cara.»
  - «¿Apostamos? Un cromo a que paro el penalti.»
  - «Decidid. Yo ya he decidido.»
- **Vega.** Soñadora de pegatinas brillantes. Ironía dramática.
  - «Esta brilla en la oscuridad. Y esta huele a fresa.»
  - «Genial. Gracias. Gracias por nada.»
  - «Nadie mira lo que brilla de verdad. Tú sí.»
- **Iker.** Gafas y datos curiosos. Sabelotodo pero buena gente. Carga con un secreto (dejó que culparan a Bruno).
  - «Dato curioso: aquí hay más de dos mil libros. Me he leído cuarenta y siete.»
  - «Según mis datos, esa puerta lleva cerrada desde antes de que naciéramos.»
  - «Y fue más fácil que todos pensaran que era Bruno. Eso… eso estuvo mal.»

## El instituto

### Leire
- **Quién es.** Llega del norte con la cámara de su abuelo. Seca al principio y leal para siempre.
- **Cómo habla.** Monosílabos al principio. Frases cortantes y vocabulario de foto («encuadre», «teleobjetivo»). La ternura llega una vez y sin adornos. Cuando se emociona, levanta la cámara.
- **Muletillas.** «No.» · «Mi abuelo decía que…» · «Lo siento. Bueno, no lo siento.»
- **Arco.** De la nueva del primer día a documentalista: estrena una película sobre Valmar.
- **Ejemplos:**
  - «…Vale. Soy Leire. Vengo del norte. Hago fotos. Y no me gusta que me pregunten por la cámara.»
  - «Esa foto es un montaje malísimo. La original está hecha desde arriba, con teleobjetivo.»
  - «El primer día pensé que aquí no iba a tener a nadie. Y viniste tú.»

### Rayo
- **Quién es.** De 4.º, manda en el muelle. Gracioso, valiente y peligroso. En casa casi nunca hay nadie.
- **Cómo habla.** Rápido y seguro: «socio», «me piro». Cuando habla de su casa, frases sueltas sin mirar.
- **Ejemplos:**
  - «Tú grita: “¡Camisetas, a diez!”. Yo cobro. Si ves a un policía, silba.»
  - «Mi madre trabaja de noche. Duerme de día. Somos compañeros de piso, más o menos.»
  - «¿Para siempre? …Vale. Ya me lo imaginaba.»

### Nerea
- **Quién es.** Lista y sarcástica. Va con la pandilla porque no sabe con quién ir. Dibuja cómics que no enseña.
- **Cómo habla.** Bajito y sin mirar, con pausas largas antes de decir lo que piensa.
- **Ejemplos:**
  - «(sin mirarte) Yo iré. Supongo.»
  - «Me voy de la pandilla. Ya está.»
  - «Te fuiste a tiempo. Yo también. Creo que es lo más valiente que he hecho nunca.»

### Javier (tutor de 1.º C) y Carmen (orientadora)
- **Javier.** Irónico y tranquilo; cita a filósofos sin que se lo pidan.
  - «Nadie es su nota. Pero hoy, por si acaso, haced buena letra.»
  - «Mi puerta está abierta. Siempre. Bueno, menos en el recreo, que como.»
  - «Como decía alguien más listo que yo: equivocarse también es un método.»
- **Carmen.** Escucha más que habla y deja silencios.
  - «No tienes que saberlo hoy.»
  - «Veo que el hospital te ha removido algo.»
  - «Tranquilidad: hay tiempo. Y lo que no haya, se busca.»

## Cosme y la Grieta

### Cosme
- **Quién es.** El inventor del garaje. Genio caótico y cariñoso a su manera. Dice que no le importa nada y siempre vuelve. Carga con la culpa de la noche de la Grieta.
- **Cómo habla.** Deprisa, con enumeraciones de tres y frases que otra idea interrumpe. Te llama «criatura». Usa pseudociencia brillante. Cuando habla del pasado, se para en seco.
- **Muletillas.** «Criatura.» · «Ciencia.» · «Normal. Todo normal.»
- **Cómo se mueve.** Alegre e inquieto: señala, mira a todas partes.
- **Ejemplos:**
  - «Tú entras, miras, sales. Yo apunto. Ciencia.»
  - «Un calcetín parlante, un paraguas al revés… normal. Todo normal.»
  - «Criatura. Has venido a por mí. …Allí nadie me necesitaba.»

### Pip
- **Quién es.** El robot mayordomo de Cosme. Educadísimo, dramático y en crisis existencial. Siempre habla de usted.
- **Cómo habla.** Formal y medido, hasta que entra en bucle.
- **Ejemplos:**
  - «Oh, no. Oh, no, no, no. Mejor que lo vea el señor Cosme. Mejor que no lo vea.»
  - «Le prepararé la habitación de invitados. La de los tornillos malvados.»
  - «Señor. Tiene que contárselo. Algún día.»

### Cósimo
- **Quién es.** El villano y antiguo socio de Cosme, con perilla reglamentaria. Detrás del espectáculo, alguien a quien soltaron la mano.
- **Cómo habla.** Como un presentador de concursos, con pausas para el aplauso. Te llama «Ancla». Cuando habla de sus veinte años solo, pierde el tono de plató.
- **Ejemplos:**
  - «Bravo, Cosme. Precioso trabajo de costura. Siempre fuiste el de las manualidades.»
  - «Hola, Ancla. Qué grande estás.»
  - «¿Sabes lo que es quedarse al otro lado veinte años, solo? Yo solo quiero volver.»

## La universidad

### Iván
- **Quién es.** Compañero de cuarto, de Villaverde. Caótico, generoso y optimista sin motivo. Guarda el zumo de mora de su abuela como oro.
- **Ejemplos:**
  - «¡Hombre! ¡Te ha tocado la cama de la ventana! Soy Iván. De Villaverde.»
  - «Mi método: mirar los apuntes muy fuerte la noche antes. Nunca ha funcionado. Pero tengo fe.»
  - «¿Hemos salvado el universo? …¡Zumo de mora para todos!»

### Candela
- **Quién es.** Organizadísima: etiquetas, horarios plastificados. Por dentro, un volcán. Nadie toca sus táperes.
- **Ejemplos:**
  - «Quedan nueve días, cuatro horas y doce minutos para el primer examen. Lo he calculado.»
  - «Tienes quince minutos. Si te pasas, suena mi alarma. Es una sirena de barco.»
  - «O sea, que llevas dos semanas acusándome de algo que hiciste tú en pijama de dinosaurios.»

---

## Personajes secundarios (una línea)

| Personaje | Voz |
|---|---|
| Ramón (conserje) | Bromista, manojo de llaves, todavía llama a Lucía «la de las coletas» |
| Marisa (biblioteca) | Susurros; «un libro arregla cualquier día malo» |
| Marta (música) | Habla cantando, tararea |
| Andrés (Educación Física) | Silbato y frases de entrenador |
| Lola (cocinera) | Grita en la cocina y abraza fuera de ella |
| Tobías (mecánico, id `Tomas`) | Paciencia infinita, manos de grasa |
| Inés (policía) | Conoce a todo el mundo por su nombre |
| Beltrán (profesora) | Humor tan seco que tardas en pillarlo |
| Luca (Erasmus) | Mezcla idiomas, lo arregla todo con comida |
| Don Escamas | Pez chismoso y asustadizo |
| Rex | Velocirraptor educadísimo que se come tu jamón |
