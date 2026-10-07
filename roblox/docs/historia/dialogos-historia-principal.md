# Real Life Simulator · Guion de la historia principal

_Generado automáticamente desde los datos del juego con `lune run scripts/audit/exportar-dialogos.luau` (no editar a mano: se sobrescribe)._

## PROMPT PARA CHATGPT (copiar desde aquí)

Eres guionista y director de cinemáticas de videojuegos. Te paso el guion completo de la historia principal de mi juego para que me ayudes a mejorarlo.

**El juego.** Es «Real Life Simulator», un juego de Roblox para todos los públicos. Vives una vida entera en la ciudad ficticia de Valmar: naces, eres bebé, vas al colegio (Los Pinos), al instituto, quizá a la universidad, trabajas, tienes casa y, al final, de mayor, miras atrás. Las misiones son «cosas que te pasan en la vida» y tus decisiones cambian relaciones, recuerdos y escenas posteriores. En paralelo hay una línea fantástica y cómica, la «Saga de la Grieta»: una raja de luz en el cielo, el inventor Cosme (tu vecino del garaje), su robot Pip, su antiguo socio Cósimo y el Consorcio MegaVerso. Se juega mucho en móvil.

**El motor de cinemáticas.** Las escenas son líneas de tiempo con pistas: cámara, actores que entran y salen andando, gestos, miradas, diálogo, rótulos, música, ambiente y luz. Los planos con nombre son: General, Medio, PrimerPlano, PPP (primerísimo primer plano), Hombro (por encima del hombro de uno hacia otro), DosPlanos, Lateral, Reacción (la cara de quien escucha), Seguir (la cámara sigue a alguien), Inserto (detalle de un objeto), Dolly (la cámara se acerca o se aleja), Pan (giro horizontal) y Tilt (giro vertical). La música cambia por intensidad (Nada, Descubrimiento, Íntima, Tensión, Resolución, Tema). Cada frase puede llevar: a quién se habla, plano, gesto, una pausa con un gesto («beat») y condiciones (solo sale si el jugador hizo algo antes). Los cambios de etapa son montajes de unos 36 s con «fotos vivas» de tus recuerdos.

**Cómo leer el guion.**
- Está en orden de juego: capítulo → misión (con su identificador, p. ej. `Cole01_PrimerDia`) → pasos numerados (Paso 3, Paso 5.2…). Tras cada paso, entre comillas, el objetivo que ve el jugador en pantalla. «Lugar» y «En escena» solo se indican cuando cambian.
- «**Lucía:** texto» es quien habla. «Tú» es el jugador. _Narrador_ en cursiva son textos sin personaje (narración, transiciones, rótulos).
- «Mamá/Papá» y «Abu» dependen de la casa donde naces (Mamá o Papá; Abu Rosa o Abu Tomás). «[tu nombre]» es el nombre del jugador. «o/a» es el género del jugador (sale la forma que toque).
- _(si …)_ delante de una frase o de una opción = variante: solo sale si se cumple esa condición (una decisión, una marca, un recuerdo, una relación).
- ❓ es una pregunta al jugador y ➤ cada respuesta posible, con su efecto y las frases a las que lleva (la rama).
- 🎬 son las cinemáticas o escenas de cámara, con su música, reparto, planos, rótulos (🪧) y frases. _[plano …, gesto …]_ son las acotaciones actuales.
- 💬 son comentarios sueltos de un personaje al pasar; 🖐 lo que pasa al usar un objeto; 🗨 charlas opcionales.

**Reparto principal.**

- **Mamá/Papá**: Cariño con prisas. Habla: De casa: «cariño», «a ver», «venga», «¿has comido?».
- **Abu**: Calma y refranes. Habla: Refranes (algunos inventados), «cariño», «en mis tiempos», «los de antes».
- **Profe Lucía**: Tutora de 1.º A. Habla: Claro y de aula: «silencio», «sin acusar a nadie sin pruebas», «los deberes».
- **Nico**: Deportista, impulsivo, competitivo pero generoso. Habla: De patio y de equipo: «entreno», «chiripa», «golazo», «revancha».
- **Sara**: Curiosa y científica, habla rapidísimo y usa palabras largas. Habla: Palabras largas y exactas: «técnicamente», «hipótesis», «estadísticamente».
- **Omar**: Artista tranquilo, siempre tiene hambre y un lápiz. Habla: Sencillo y visual: colores, formas, comida.
- **Mateo**: Tímido, nuevo en el barrio, colecciona cromos. Habla: Comparaciones con «mi otro cole».
- **Dani**: Hermano pequeño de Mateo (5 años). Habla: De niño pequeño: «¿y por qué?», «mío», «¡otra vez!».
- **Bruno**: Líder de 'los malotes'. Habla: Retos y amenazas de patio: «os vais a enterar», «de chiripa», «pringado».
- **Rubén**: El bromista de Bruno. Habla: Chistes malos, «rarísimo», «no es mi estilo».
- **Hugo**: Va con Bruno pero no quiere. Habla: Referencias a libros («en un libro que leí…»), aventuras, islas, llaves.
- **Álex**: Deportista, portera del equipo, directa y justa. Habla: Deporte y tratos: «la información es cara», «¿apostamos?», «decidid».
- **Vega**: Artista, soñadora, colecciona pegatinas brillantes. Habla: Colores, brillos, olores («esta huele a fresa»).
- **Iker**: El que se lo sabe todo. Habla: «Dato curioso», «según mis datos», cifras exactas.
- **Leire**: Nueva en Valmar (viene del norte). Habla: De foto: «encuadre», «teleobjetivo», «montaje», «la original».
- **Rayo**: De 4.º, el que manda en el muelle. Habla: Calle y trato: «socio», «me piro», «negocios», «a diez».
- **Nerea**: De la pandilla de Rayo. Habla: Sarcasmo seco, «supongo», «ya está».
- **Javier**: Tutor de 1.º C y profe de Historia. Habla: Culto con guiño: citas, «charlas que no me habéis pedido».
- **Carmen**: Orientadora del instituto. Habla: Cálido y preciso: «veo que…», «tranquilidad», «hay tiempo».
- **Cosme**: El vecino del garaje. Habla: Pseudociencia brillante: «potasio cuántico», «técnicamente», «ciencia».
- **Pip**: El robot mayordomo de Cosme. Habla: Formal de mayordomo: «señor», «le prepararé», «permítame».
- **Doctor Cósimo**: El villano. Habla: De presentador de concursos: «bravo», «precioso trabajo», «nuestro concursante».
- **Iván**: Compañero de cuarto. Habla: De pueblo y de fiesta: «¡hombre!», «mi abuela dice», moras, el monte.
- **Candela**: Compañera de cuarto. Habla: Cálculos y planificación: «lo he calculado», «resumen para mi hoja de cálculo», horas y minutos exactos.

**Lo que te pido.** Lee todo el guion y respóndeme con:

1. **Mejoras de guion:** diálogos más naturales, ritmo (escenas que se alargan o se quedan cortas), coherencia entre misiones y voz propia de cada personaje (que se reconozca quién habla sin ver el nombre).
2. **Cinemáticas:** qué escenas o pasos convertirías en cinemática y cómo: qué planos usarías (de la lista de arriba) en qué frases, qué música o intensidad, quién entra y sale, y qué gesto o silencio pondrías.
3. **Momentos que faltan:** escenas emotivas, giros, recompensas emocionales o momentos en que algún personaje debería recordar lo que hizo el jugador antes.
4. **Errores e incoherencias:** contradicciones, personajes que saben cosas que no deberían, frases repetidas, condiciones que no encajan, cambios de tono bruscos.
5. **Formato de la respuesta:** propuestas CONCRETAS agrupadas por misión, indicando siempre el identificador de la misión y el número de paso (por ejemplo: «`Cole01_PrimerDia` · Paso 15 (Cena): cambiar la frase de Abu por…; plano PrimerPlano de Abu; música Íntima»). Si propones una frase nueva, escríbela entera y di quién la dice. Empieza por las 10 mejoras más importantes de todo el juego y luego ve misión por misión.

Reglas: todo debe ser apto para todos los públicos (es Roblox: nada de violencia explícita, contenido adulto ni lenguaje ofensivo), sin marcas, productos, famosos ni lugares reales, en español de España, con frases cortas (máximo unos 150 caracteres por bocadillo) y sin dobletes de género (usa «o/a» o frases neutras).

## FIN DEL PROMPT · el guion empieza aquí

## Índice (orden de juego)

- **Prólogo**: `Prologo_Sueno`
- **Capítulo «Primeros pasos»**: `Bebe_AprendeACaminar`, `Bebe_ExploraLaCasa`, `Bebe_HoraDeSalir`
- **Capítulo «El colegio»**: `Cole01_PrimerDia`, `Cole02_Mochila`, `Cole03_Grupo`, `Cole04_Malotes`, `Cole05_Venganza`, `Cole06_Examen`, `Nino_Recados`, `Cole07_Excursion`, `Cole08_Torneo`, `Cole09_Misterio`, `Cole10_Festival`, `Cole11_Proyecto`, `Cole12_UltimoDia`
- **Saga de la Grieta · Acto I «La Grieta»**: `Loco_N1_Cosme`, `Saga_02_Grieta`, `Saga_03_Pez`, `Saga_04_Ventanilla`, `Saga_05_Perdidas`, `Saga_06_Coser`
- **Capítulo «El instituto»**: `Ins01_NuevoInstituto`, `Ins02_Clubes`, `Ins03_QueQuieresSer`, `Pan1_MalasCompanias`, `Pan2_LaNoche`, `Ins04_PrimerEmpleo`, `Pan3_Cruce`, `Ins05_ElRumor`, `Ins06_LaGranDecision`
- **Saga de la Grieta · Acto II**: `Saga_07_Costuras`, `Saga_08_MegaVerso`, `Saga_09_Archivo`, `Saga_10_Fiesta`, `Saga_11_Cronos`, `Saga_12_Graduacion`
- **Capítulo «La universidad»**: `Uni01_PrimerDia`, `Uni01b_Residencia`, `Uni02_ElProyecto`, `UniEx1_Enero`, `Uni03_PrimerTrabajo`, `UniEx2_Junio`, `Uni04_Practicas`, `UniEx3_Parcial`, `Uni05_PrimerPiso`, `UniEx4_TFG`, `Uni06_Graduacion`
- **Capítulo «Volar del nido»**: `Adu01_PrimerContrato`, `Adu02_Atardecer`, `Adu03_Reencuentro`
- **Saga de la Grieta · Acto III**: `Saga_13_SinCosme`, `Saga_14_Bigotes`, `Saga_15_Reestreno`, `Saga_16_66B`, `Saga_17_Rescate`, `Saga_18_Precio`
- **Saga de la Grieta · Acto IV y epílogo**: `Saga_19_Recuerdos`, `Saga_20_Aliados`, `Saga_21_Consorcio`, `Saga_22_Ancla`, `Saga_23_Fusion`, `Saga_24_Final`
- **Capítulo «Tu vida»**: `Adulto_MirarAtras`
- **Capítulo «Una nueva vida en Valmar»**: `Adulto_LlegadaValmar`, `Adulto_PrimerSueldo`, `Adulto_ConoceLaRegion`

_Fuera de este guion (no son historia principal): 88 misiones: Capítulo desactivado (puente antiguo) (1); Consecuencia (15); Consecuencia diferida (1); Día normal generado (Jornada) (4); Metro (1); Misión de aliado (7); Misión loca (20); Profesión (2); Rareza de la Grieta (24); Secundaria (4); Trabajo (1); Universidad (8)._

# Prólogo

> Tutorial de controles contado como historia. Solo la primera vez, antes del nacimiento.

### Prologo_Sueno · «Prólogo: el sueño»

**Resumen:** La noche en que naces, sueñas con lo que está por venir. Aprende a moverte por Valmar… y conoce a alguien que te estaba esperando.

_Tipo: Prólogo · Duración: 2-4 min_

**Presentes en toda la misión:** Cosme

**Pasos:**

- **Paso 1 · Cinemática**
  - _Lugar:_ El sueño
  - 🎬 **Cinemática «Prologo_Apertura»** _(vuelo de cámara, 19.5 s, 3 planos; música: TemaValmar)_
    - 🪧 _Rótulo:_ «Valmar» — Aquí vas a vivir una vida entera: de bebé a persona adulta.
    - 🪧 _Rótulo:_ «Esto es un sueño…» — …de lo que está por venir.
    - _Narrador:_ _Lo que elijas cambiará tu historia… y cómo te recuerda la gente._
    - _Narrador:_ _Pero en Valmar pasa algo raro. Una raja de fuego y luz cruza el cielo: la Grieta._
    - _Narrador:_ _Y tu vecino Cosme, el inventor del garaje, sabe más de lo que dice._
- **Paso 2 · Ir a** El círculo de luz — «Camina hasta el círculo de luz»
- **Paso 3 · Acción del jugador** — «¡Corre! Algo brilla al fondo»
- **Paso 4 · Ir a** Detrás de la valla de flores — «Salta la valla de flores»
- **Paso 5 · Hablar** con Cosme — «Habla con el señor de la bata»
  - _Narrador:_ _Es un sueño. En el sueño ya no eres un bebé: eres un poco mayor. Y alguien te está esperando._
  - **Cosme:** ¡Ah, criatura! Llegas pronto. O tarde. En los sueños nunca se sabe. _[plano Medio de Cosme · gesto Happy]_
  - **Cosme:** Soy Cosme. Inventor. Genio. Vecino.
  - **Cosme:** Todavía no nos conocemos… pero nos conoceremos. _[plano PrimerPlano de Cosme · en la pausa: Piensa]_
  - **Cosme:** ¿Ves esa raja de luz en el cielo? Se llama la Grieta. _[ademán Point]_
  - **Cosme:** No debería estar ahí. Es… culpa mía. Un poco. Bastante. _[plano PPP de Cosme · gesto Sad · en la pausa: Baja]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Yo te ayudo a arreglarla!» _(efecto: valentia +1; decisión «prologo» = Ayudar)_
      - **Cosme:** ¿Ayudar? ¿Tú? Qué valiente. Me gusta. Ya verás: en Valmar, lo que eliges cambia tu historia.
    - ➤ «¿Y eso es peligroso?» _(efecto: curiosidad +1; decisión «prologo» = Preguntar)_
      - **Cosme:** Un poco. Buena pregunta. En Valmar, lo que preguntas y lo que eliges cambia tu historia… y cómo te recuerda la gente.
  - **Cosme:** Antes de despertar, coge ese tornillo que brilla. Es importante. Creo. Mañana no te acordarás de nada. Bueno, de casi nada.
- **Paso 6 · Usar** — «Recoge el tornillo que brilla»
  - 🖐 _Al usar «Un tornillo que brilla»:_
    - _Narrador:_ _El tornillo está calentito y zumba como un moscardón feliz. Por un segundo, el cielo parpadea en verde._
- **Paso 7 · Ir a** La puerta del garaje — «Sigue las flechas azules del suelo hasta la puerta del garaje»
- **Paso 8 · Acción del jugador** — «Abre el mapa de Valmar»
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Prologo_Cierre»** _(vuelo de cámara, 14 s, 1 planos; música: Nacimiento)_
    - 🪧 _Rótulo:_ «⭐ Tu vida» — La historia principal: crecer, estudiar, trabajar… y querer a los tuyos.
    - 🪧 _Rótulo:_ «🌀 Misiones locas» — Aventuras rarísimas con Cosme, tu vecino inventor.
    - 🪧 _Rótulo:_ «❗ La Saga de la Grieta» — Busca el ❗ dorado en el mapa: ahí sigue el misterio.
    - _Narrador:_ _El sueño se apaga. Ahora empieza tu vida de verdad._

---


# Capítulo «Primeros pasos»

_Id: Bebe_PrimerosPasos · Etapa: Bebe · Música de fondo: Nacimiento_

**Texto de entrada del capítulo:** «Acabas de llegar al mundo. Todo es nuevo.»

- 🎬 **Cabecera del capítulo (cinemática) «Bebe_NacimientoCuna»** _(música: Nacimiento)_
  - _En escena:_ Mamá/Papá, Abu · _salen:_ Mamá/Papá, Abu
  - _Cámara:_ 3 planos
  - 🪧 _Rótulo:_ «Valmar» — Un día de primavera, en Los Pinos
  - 🪧 _Rótulo:_ «Primeros pasos» — Acabas de llegar al mundo. Todo es nuevo.
  - **Mamá/Papá:** Mira… No llora. Solo mira. _[a Abu · plano PrimerPlano de Mamá/Papá · gesto Happy · silencio 9.6 s]_
  - **Abu:** Te damos la bienvenida al mundo, [tu nombre]. Valmar te estaba esperando. _[plano PrimerPlano de Abu]_
  - **Mamá/Papá:** Hola. Soy yo. Llevaba meses ensayando qué decirte… y ahora no me sale nada. _[plano Reaccion de Mamá/Papá · en la pausa: Respirar]_
  - _(si tienes el recuerdo «sueno grieta»)_ **Abu:** Mira qué manitas… y cómo sonríe. Algo bonito habrá soñado esta noche. _[a Mamá/Papá · plano Inserto de Cuna]_
  - _(si NO se cumple: tienes el recuerdo «sueno grieta»)_ _(o bien)_ **Abu:** Mira qué manitas tan pequeñas… y qué ganas de explorar. _[plano Inserto de Cuna]_
  - **Mamá/Papá:** Ya estás en casa. _[plano PPP de Mamá/Papá]_

### Bebe_AprendeACaminar · «Aprende a caminar»

**Resumen:** Acabas de nacer y tu familia te mira con ilusión. Hoy te toca levantarte y dar tus primeros pasos hasta tu abu.

**Pasos:**

- **Paso 1 · Acción del jugador** — «Intenta levantarte (pulsa «¡Levántate!»)»
- **Paso 2 · Acción del jugador** — «Da tus primeros pasos»
- **Paso 3 · Hablar** con Abu — «Llega hasta Abu»
  - _Lugar:_ Abu
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Bebe_PrimerosPasosAbu»** _(música: → Resolucion efecto PrimerosPasos)_
    - _En escena:_ Mamá/Papá · _entran andando:_ Mamá/Papá · _salen:_ Mamá/Papá
    - _Cámara:_ 1 planos
    - 🪧 _Rótulo:_ «Has dado tus primeros pasos.»
    - **Abu:** Eso es… Un pasito más. Otro. Mírame a mí, no a los pies. _[plano Hombro de Tú → Abu · silencio 1.0 s]_
    - **Abu:** ¡Has llegado hasta aquí sin ayuda! _[plano Hombro de Abu → Tú · gesto Happy · silencio 0.6 s]_
    - **Mamá/Papá:** ¿Qué ha pasado? ¿Ha andado? ¿¡Ha andado y me lo he perdido!? _[a Abu · plano Seguir de Mamá/Papá]_
    - **Abu:** Ha andado. Y ha venido derechito a su abu. Que conste. _[a Mamá/Papá · plano Hombro de Mamá/Papá → Abu]_
    - **Mamá/Papá:** Pues esto hay que celebrarlo con una foto. ¡Que no se mueva nadie! …Bueno, tú sí, que ahora ya no hay quien te pare. _[plano Reaccion de Mamá/Papá]_

**Al terminar (momento de la biografía):** «Has dado tus primeros pasos.»

---

### Bebe_ExploraLaCasa · «Explora tu casa»

**Resumen:** Ya caminas. Tu casa está llena de cosas nuevas: la cocina, la tele, los juguetes… y tu familia quiere enseñártelas.

**Requisitos:** has terminado «Aprende a caminar»

**Pasos:**

- **Paso 1 · Varios objetivos (en cualquier orden)** — «Recorre la casa»
  - **Paso 1.1 · Ir a** la cocina — «Mira la cocina»
  - **Paso 1.2 · Acción del jugador** — «Mira la tele del salón»
  - **Paso 1.3 · Acción del jugador** — «Juega con tus bloques en tu habitación»
- **Paso 2 · Hablar** con Mamá/Papá — «Tienes hambre: pide el biberón a tu familia en la cocina»
  - _Lugar:_ tu familia

**Al terminar (momento de la biografía):** «Has conocido a tu familia.»

---

### Bebe_HoraDeSalir · «Es hora de salir»

**Resumen:** Por el ventanal se ve Valmar, la ciudad donde vas a crecer. Asómate: ahí fuera te espera tu vida.

**Requisitos:** has terminado «Explora tu casa»

**Pasos:**

- **Paso 1 · Acción del jugador** — «Asómate al ventanal del salón»
  - _Lugar:_ el ventanal
- **Paso 2 · Transición (pasa el tiempo)** — «Han pasado varios años…»
  - ⏳ _Pantalla de transición:_ «Han pasado varios años…» _(pasas a la etapa Nino)_
  - 🎬 **Montaje / cinemática de transición «Montaje_Bebe_Nino»** _(música: → Intima TemaValmar PasanLosAnos; montaje de cambio de etapa Bebe → Nino)_
    - _En escena:_ Abu, Mamá/Papá, Profe Lucía, Nico, Sara, Omar · _entran andando:_ Nico, Sara, Omar
    - _Cámara:_ 10 planos (PrimerPlano)
    - 🪧 _Rótulo:_ «Primeros pasos» — Fin del capítulo
    - 🪧 _Rótulo:_ «Los Pinos» — El colegio de tu barrio
    - _(si has terminado «Aprende a caminar»)_ 🪧 _Rótulo:_ «Tus primeros pasos» — Directo a los brazos de tu abu
    - _(si NO has terminado «Aprende a caminar»)_ 🪧 _Rótulo:_ «Tu primera noche en casa» — Alguien te vigiló el sueño
    - _(si has terminado «Explora tu casa»)_ 🪧 _Rótulo:_ «La cocina, la tele, los juguetes» — Todo era nuevo. Todo era tuyo.
    - _(si NO has terminado «Explora tu casa»)_ 🪧 _Rótulo:_ «Tu casa» — Los Pinos, Valmar
    - 🪧 _Rótulo:_ «Las tardes en el parque» — Primeros pasos, primeras palabras… y un día dejas de ser un bebé.
    - 🪧 _Rótulo:_ «Seis años después» — Ya no eres un bebé
    - **Abu:** Shhh… Ya se ha dormido.
    - **Mamá/Papá:** Hoy se ha asomado al ventanal. Media hora mirando la ciudad.
    - **Abu:** Mañana, y pasado, y al otro… Así se crece: un día detrás de otro.
    - _(si has terminado «Aprende a caminar»)_ **Abu:** ¡Mira, mira! ¡Ya viene sin agarrarse!
    - **Profe Lucía:** ¡Buenos días! ¿Primer día? Pasad, pasad. Los nervios se quedan en la puerta.

**Al terminar (momento de la biografía):** «Ya no eres un bebé.»

---

**Texto de cierre del capítulo:** «Primeros pasos, primeras palabras… y un día dejas de ser un bebé.»

# Capítulo «El colegio»

_Id: Nino_ElColegio · Etapa: Nino · Música de fondo: TemaValmar_

**Texto de entrada del capítulo:** «Hoy empieza algo grande: el colegio.»

- 🎬 **Cabecera del capítulo (cinemática) «Cole01_Amanecer»** _(vuelo de cámara, 10 s, 2 planos; música: TemaValmar)_
  - 🪧 _Rótulo:_ «El colegio» — Hoy empieza algo grande: el colegio.

_Entre misión y misión se repite un «día normal» generado (Nino_Jornada): no se exporta, no es guion fijo._

### Cole01_PrimerDia · «El primer día»

**Resumen:** Hoy empiezas el colegio. Nuevos lugares, nuevas caras… y un montón de cosas que aprender.

_Tipo: Historia · Edad: 6-6 años · Duración: 15-20 min_

**Lo que puede cambiar:** Amigo de Mateo o no · Sitio en clase (Sara, Nico o Mateo) · Grupo del recreo · Llegaste tarde o a tiempo

**Pasos:**

- **Paso 1 · Escena** — «Despierta: hoy empiezas el cole»
  - _Lugar:_ tu habitación · _En escena:_ Mamá/Papá, Abu
  - _Narrador:_ _Los Pinos, por la mañana temprano. Hoy no es un día cualquiera._
  - **Mamá/Papá:** ¡Buenos días, [tu nombre]! Arriba, que hoy es un día MUY importante.
  - **Tú:** Mmmm… ¿qué día?
  - **Mamá/Papá:** ¡Tu primer día de cole! Mochila nueva, profe nueva, amigos nuevos…
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Cinco minutitos más…» _(efecto: humor +1)_
      - **Mamá/Papá:** ¿Cinco minutitos? Eso decía yo a tu edad. Y siempre llegaba tarde. ¡Arriba!
    - ➤ «¡Ya voy! ¡Ya voy!» _(efecto: responsabilidad +1)_
      - **Mamá/Papá:** ¡Así me gusta! ¡Qué energía!
    - ➤ «¿Y si no voy? Me duele… la tripa.» _(efecto: humor +1)_
      - **Mamá/Papá:** Qué casualidad: justo hoy. Eso son nervios, cariño. Se pasan en cuanto llegas.
      - **Mamá/Papá:** A mí me pasaba igual. Y mira: sobreviví.
  - **Mamá/Papá:** Tienes que vestirte, preparar la mochila y desayunar. El cole empieza enseguida.
  - **Mamá/Papá:** Yo estoy en la cocina. Si tardas mucho, llegarás tarde… ¡y la profe lo notará!
  - _Narrador:_ _Acércate a los objetos que brillan y usa el botón de acción (E)._
  - 🗨 _Charla opcional con Abu (si te acercas a hablar):_
    - **Abu:** Ven aquí, que te vea. ¡Qué mayor! Parece que fue ayer cuando gateabas por esta alfombra.
    - **Abu:** Un consejo de tu abu: en el cole, el que ayuda a los demás nunca está solo.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Prepárate para el cole»
  - _Lugar:_ la cocina
  - ⏰ _Si tardas, Mamá/Papá dice:_ «¡[tu nombre]! ¡Que vas a llegar tarde!»
  - 🖐 _Al usar «Tu cama»:_
    - _Narrador:_ _Estiras la sábana, colocas la almohada… queda casi perfecta._
    - **Mamá/Papá:** ¿Has hecho la cama TÚ SOLO? ¡Hoy es un día histórico!
  - 🖐 _Al usar «Espejo»:_
    - _Narrador:_ _Te miras al espejo. Ensayas._
    - ❓ **Pregunta al jugador:** ¿Cómo te presentarás?
      - ➤ «Hola, soy [tu nombre]. ¡Me alegro de conoceros!» _(efecto: valentia +1)_
      - ➤ «¿Qué pasa, gente? Soy [tu nombre] y vengo a ganar.» _(efecto: humor +1)_
      - ➤ (Sonríes y ya está. Con eso vale.) _(efecto: empatia +1)_
    - _Narrador:_ _Perfecto. Ya tienes tu frase preparada._
  - **Paso 2.1 · Usar** — «Vístete (el armario del dormitorio)»
    - 🖐 _Al usar «Armario»:_
      - _Narrador:_ _Tres opciones colgadas. Tres versiones de ti para tu primer día._
      - ❓ **Pregunta al jugador:** ¿Qué te pones?
        - ➤ «La camiseta de dinosaurios 🦖» _(efecto: humor +1; decisión «ropa» = Dinosaurios)_
          - **Tú:** El T-Rex me da poderes. Es un hecho científico.
        - ➤ «La sudadera azul del cole» _(efecto: responsabilidad +1; decisión «ropa» = Sudadera)_
          - **Tú:** Con el escudo del cole. Así ya parezco de allí.
        - ➤ «La camisa elegante de las fotos» _(efecto: decisión «ropa» = Camisa)_
          - **Tú:** Impecable. Aunque pica un poquito el cuello.
  - **Paso 2.2 · Usar** — «Prepara la mochila»
    - 🖐 _Al usar «Tu mochila nueva»:_
      - _Narrador:_ _Estuche, cuaderno, lápices de colores… y en el cajón, tu cromo de la suerte._
      - ❓ **Pregunta al jugador:** ¿Te llevas el cromo?
        - ➤ «¡Claro! Un portero legendario nunca falla.» _(efecto: marca «lleva cromo»; objeto cromo suerte)_
          - **Tú:** Al bolsillo pequeño. Para emergencias.
        - ➤ «Mejor no, no vaya a perderse.» _(efecto: responsabilidad +1)_
          - **Tú:** Se queda en casa, a salvo. Solo lo del cole.
      - _Narrador:_ _Mochila lista. La encontrarás en tu mochila (botón Objetos, tecla E)._
  - **Paso 2.3 · Usar** — «Desayuna en la cocina»
    - 🖐 _Al usar «Desayuno»:_
      - **Mamá/Papá:** ¡Siéntate, que se enfría! ¿Qué te apetece?
      - ❓ **Pregunta al jugador:** Para desayunar…
        - ➤ «Tostadas con tomate»
          - **Mamá/Papá:** Como tu abu. Con su chorrito de aceite.
        - ➤ «Cereales con leche»
          - **Tú:** ¡Los que tienen un dinosaurio en la caja!
        - ➤ «Fruta… y un poquito de chocolate» _(efecto: humor +1)_
          - **Mamá/Papá:** Un poquito, he dicho. POQUITO.
      - **Mamá/Papá:** Y bebe algo, que en el cole se corre mucho.
- **Paso 3 · Hablar** con Mamá/Papá — «Dile a mamá/papá que ya lo tienes todo»
  - **Tú:** ¡Listo todo! Ropa, mochila y desayuno.
  - _(si en «ropa» elegiste «Camisa»)_ **Mamá/Papá:** Deja que te vea… ¡Qué elegancia!
  - _(si en «ropa» elegiste «Dinosaurios»)_ **Mamá/Papá:** Con los dinosaurios. Muy tú. ¡Me encanta!
  - _(si en «ropa» elegiste «Sudadera»)_ **Mamá/Papá:** ¡Con la sudadera del cole! Pareces de sexto.
  - _(si tienes la marca «llegas tarde»)_ **Mamá/Papá:** Aunque… ¡mira qué hora es! ¡Corre!
  - **Mamá/Papá:** El cole está cerca. ¿Quieres que te acompañe?
  - ❓ **Pregunta al jugador:** ¿Vas por tu cuenta o con compañía?
    - ➤ «Sí, acompáñame, porfa.» _(efecto: Mamá/Papá +3; decisión «acompanante» = Familia)_
      - **Mamá/Papá:** ¡Claro que sí! Pero en la puerta me das un beso rapidito, que ya sé que da vergüenza.
    - ➤ «¡Voy yo solo, que ya soy mayor!» _(efecto: valentia +1; decisión «acompanante» = Solo)_
      - **Mamá/Papá:** Vale, vale, que ya eres mayor. Ve por la acera y sigue la luz. Te miro desde la ventana.
- **Paso 4 · Ir a** Camino al cole — «Ve hacia el colegio (sigue la luz)»
  - _Lugar:_ Camino al cole · _En escena:_ Mamá/Papá (si en «acompanante» elegiste «Familia») (te acompaña), Dani
- **Paso 5 · Escena**
  - _Narrador:_ _Un balón naranja rueda hasta tus pies. Un niño pequeño viene corriendo detrás._
  - **Dani:** ¡Eh! ¡EH! ¡Ese es mi balón! ¿Me lo pasas? ¡Porfa, porfa, porfa!
  - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** Venga, pásaselo. Pero con cuidado, que es pequeñito.
- **Paso 6 · Minijuego** — «Pásale el balón a Dani»
  - 🎮 _Cómo se juega:_ Pulsa cuando la aguja esté en la zona verde
- **Paso 7 · Escena**
  - _(si tienes la marca «pase a dani»)_ **Dani:** ¡HALA! ¡Qué pase! ¡Eres como los de la tele!
  - _(si tienes la marca «fallaste pase»)_ **Dani:** Jajaja, se ha ido a la farola. No pasa nada, ¡ya lo cojo yo!
  - **Dani:** Me llamo Dani. Tengo cinco años y MEDIO.
  - **Dani:** Mi hermano Mateo también empieza hoy en tu cole. Es un poco… vergonzoso. No habla casi.
  - **Dani:** ¡Si lo ves, dile que Dani dice que se ría más! ¡Adiós!
- **Paso 8 · Ir a** el colegio — «Llega a la entrada del colegio»
  - _Lugar:_ el colegio · _En escena:_ Ramón, Alumno, Alumna, Alumno de 6.º, Una madre, Un padre, Mamá/Papá (si en «acompanante» elegiste «Familia») (te acompaña)
  - 💬 _Comentario al pasar cerca de Un padre:_ «Pórtate bien, ¿eh? ¡Y come la fruta!»
- **Paso 9 · Escena**
  - _Narrador:_ _La puerta del colegio es un hervidero: mochilas, abrazos, un autobús amarillo y muchísimo ruido._
  - **Ramón:** ¡Buenos días, buenos días! ¡Los mayores, por la izquierda; los de primero, por la puerta grande!
  - **Ramón:** Uy, ¿y tú? Cara nueva. Me llamo Ramón, soy el conserje. Si algo se rompe, se pierde o se atasca: Ramón.
  - _(si tienes la marca «llegas tarde»)_ **Ramón:** ¿Llegando tarde el primer día? Tranquilidad, lo apunto en mi libreta de secretos. Jejeje.
  - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** Bueno… aquí te dejo. ¡Pásalo genial! Te espero para cenar y me lo cuentas TODO.
  - **Ramón:** Tu tutora es Lucía. Está en el pasillo. La reconocerás: jersey amarillo y una risa que se oye desde aquí.
- **Paso 10 · Hablar** con Profe Lucía — «Busca a tu tutora: lleva un jersey amarillo»
  - _Lugar:_ Pasillo · _En escena:_ Profe Lucía, Andrés, Marta, Ramón
  - **Profe Lucía:** ¡Hola! Tú debes de ser [tu nombre]. Yo soy Lucía, tu tutora de 1.º A. _[plano Medio de Profe Lucía · gesto Happy]_
  - _(si NO tienes la marca «llegas tarde»)_ **Profe Lucía:** Ya estás aquí. Buena señal.
  - _(si tienes la marca «llegas tarde»)_ **Profe Lucía:** Un poquito tarde, ¿eh? Hoy te lo perdono. Mañana, un poco antes. _[plano PrimerPlano de Profe Lucía · en la pausa: Mira]_
  - _(si tienes la marca «llegas tarde»)_ **Ramón:** Apuntado en mi libreta, Lucía. Jejeje. _[a Profe Lucía]_
  - **Profe Lucía:** Antes de empezar, una misión para ti: conoce el colegio. _[plano Hombro de Tú → Profe Lucía]_
  - **Profe Lucía:** La biblioteca, el comedor, el patio, el gimnasio y el campo. Todo. _[ademán Point]_
  - **Profe Lucía:** Por el camino encontrarás gente que te contará cosas. Y luego… encuentra tu aula tú solo. La de 1.º A. _[en la pausa: Sonrie]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Hecho! Me encanta explorar.» _(efecto: Profe Lucía +3; valentia +1)_
      - **Profe Lucía:** Eso quiero ver. ¡Suerte, y a explorar!
    - ➤ «¿Y si me pierdo?» _(efecto: Profe Lucía +3)_
      - **Profe Lucía:** Entonces preguntas. Preguntar no es de perdidos: es de listos. _[plano PrimerPlano de Profe Lucía · en la pausa: Piensa]_
  - 🗨 _Charla opcional con Andrés (si te acercas a hablar):_
    - **Andrés:** ¿Yo, tu tutor? ¡Ojalá! Soy Andrés, el de Educación Física. Me verás con silbato.
    - **Andrés:** Lucía es la del jersey amarillo. Y no corras por el pasillo… todavía.
  - 🗨 _Charla opcional con Marta (si te acercas a hablar):_
    - **Marta:** Hola, cielo. Soy Marta, la profe de música. El piano del fondo es mío.
    - **Marta:** ¿Buscas a Lucía? Mira: la amarilla que se está riendo. No tiene pérdida.
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Conoce el colegio»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Iker, Vega, Ramón
  - **Paso 11.1 · Ir a** Biblioteca del cole — «La biblioteca»
  - **Paso 11.2 · Ir a** Comedor — «El comedor»
  - **Paso 11.3 · Ir a** el patio — «El patio»
  - **Paso 11.4 · Ir a** Gimnasio — «El gimnasio»
  - **Paso 11.5 · Ir a** Campo de fútbol — «El campo de fútbol»
  - **Paso 11.6 · Hablar** con Iker — «Habla con el niño de las gafas (biblioteca)»
    - **Iker:** Shhh… es la biblioteca. Hola. Soy Iker. Dato curioso: aquí hay más de dos mil libros. Me he leído cuarenta y siete.
    - **Iker:** Si buscas 1.º A, está en el edificio principal, a la izquierda del vestíbulo. La otra es 1.º B. Y al fondo, la de música.
    - ❓ **Pregunta al jugador:** ¿Qué le contestas?
      - ➤ «¡Qué listo eres!» _(efecto: Iker +5)_
        - **Iker:** Ya lo sé. Digo… gracias.
      - ➤ «¿Y cuánto mide una pista de tenis?» _(efecto: Iker +3; curiosidad +1)_
        - **Iker:** ¡Veintitrés metros y setenta y siete centímetros! Por fin alguien pregunta.
  - **Paso 11.7 · Hablar** con Vega — «Habla con la niña de las pegatinas (comedor)»
    - **Vega:** ¿Te gustan las pegatinas? Esta brilla en la oscuridad. Y esta huele a fresa.
    - **Vega:** Consejo de experta del comedor: los jueves hay macarrones. Y NUNCA te sientes en la mesa de los de sexto.
  - **Paso 11.8 · Hablar** con Ramón — «Habla con Ramón, el conserje (puerta del gimnasio)»
    - **Ramón:** ¡Anda, si es la exploración oficial! Esto es el gimnasio. Y al fondo, detrás de la canasta, está el almacén.
    - **Ramón:** En el almacén no se entra sin permiso. Balones, colchonetas… y cosas que llevan AÑOS ahí dentro.
    - **Ramón:** Y si alguna vez pierdes algo en este cole, pregúntame. Yo encuentro de todo.
- **Paso 12 · Ir a** Aula de 1.º A — «Encuentra tu aula: 1.º A (dentro del edificio)»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Vega, Omar, Álex, Bruno, Rubén, Mateo, Hugo, Nico
- **Paso 13 · Cinemática**
  - _Lugar:_ Tu pupitre
  - 🎬 **Cinemática «Cole01_Bienvenida»**
    - _En escena:_ Profe Lucía, Nico, Sara, Bruno, Rubén, Mateo, Omar, Iker, Hugo, Vega, Álex
    - _Cámara:_ 3 planos (Hombro, Reaccion)
    - _(si NO se cumple: tienes la marca «llegas tarde»)_ **Profe Lucía:** ¡Mirad quién ha encontrado el aula! _[plano Medio de Profe Lucía · silencio 1.5 s]_
    - _(si tienes la marca «llegas tarde»)_ _(o bien)_ **Profe Lucía:** ¡Mirad quién ha encontrado el aula! Un poquito tarde… pero la ha encontrado. _[plano Medio de Profe Lucía · silencio 1.5 s]_
    - **Profe Lucía:** Chicos, chicas: hoy tenemos a alguien nuevo en clase. Se llama [tu nombre]. _[plano Lateral de Sara]_
    - **Nico:** ¿Juegas al fútbol? Necesitamos uno para el recreo. _[plano PrimerPlano de Nico · gesto Happy]_
    - **Sara:** Nico, déjale llegar. _[a Nico · plano Reaccion de Sara]_
    - **Sara:** Hola. Soy Sara. Ya tengo hechos los deberes de mañana. _[plano PrimerPlano de Sara]_
    - **Bruno:** Otro más… Como si no fuéramos ya muchos. _[plano Reaccion de Bruno · gesto ArmsCrossed · en la pausa: Apartar · silencio 0.6 s]_
    - **Profe Lucía:** Bruno. Eso no se dice. _[a Bruno · plano PrimerPlano de Profe Lucía · en la pausa: Mirar · silencio 0.5 s]_
    - **Profe Lucía:** [tu nombre], busca sitio. Hay tres libres: elige bien, que es para todo el curso.
- **Paso 14 · Decisión** — «Elige dónde sentarte (las sillas brillantes)»
  - ➤ **Opción «Delante, junto a Sara»** _(efecto: decisión «asiento» = Sara; Sara +8; curiosidad +1)_
  - ➤ **Opción «Al fondo, junto a Nico»** _(efecto: decisión «asiento» = Nico; Nico +8; deportividad +1)_
  - ➤ **Opción «Junto al niño callado»** _(efecto: decisión «asiento» = Mateo; Mateo +8; empatia +1)_
- **Paso 15 · Escena** _(solo si en «asiento» elegiste «Sara»)_
  - _(si en «asiento» elegiste «Sara»)_ **Sara:** Has elegido bien: aquí delante se entiende todo. Y la pizarra no tiene reflejos.
  - _(si en «asiento» elegiste «Nico»)_ **Nico:** ¡Bien! Desde aquí se ve la ventana y el campo. Si miras mucho, Lucía te pilla.
  - _(si en «asiento» elegiste «Mateo»)_ **Mateo:** …Hola. _[plano PrimerPlano de Mateo · gesto Ashamed · en la pausa: Baja]_
  - _(si en «asiento» elegiste «Mateo»)_ **Rubén:** Psst. Te has sentado en la fila de los guays. Jejeje.
  - **Profe Lucía:** Vamos a presentarnos. Cada uno dice su nombre y algo que le guste. _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** [tu nombre], empiezas tú. _[en la pausa: Mira · silencio 0.5 s]_
  - ❓ **Pregunta al jugador:** Te toca. ¿Qué dices?
    - ➤ «Soy [tu nombre] y me encanta el fútbol.» _(efecto: decisión «gusto» = Futbol)_
      - **Nico:** ¡LO SABÍA! ¡Recreo, partido, tú y yo!
    - ➤ «Soy [tu nombre] y me gusta dibujar.» _(efecto: decisión «gusto» = Dibujar)_
      - **Omar:** Mola. _[plano Reaccion de Omar · gesto Nod]_
    - ➤ «Soy [tu nombre] y me encantan los experimentos.» _(efecto: decisión «gusto» = Ciencia)_
      - **Sara:** ¿Experimentos de verdad? ¿Con volcanes? Tenemos que hablar.
    - ➤ «Soy [tu nombre] y me gusta… dormir cinco minutitos más.» _(efecto: humor +1; decisión «gusto» = Dormir)_
      - **Nico:** ¡Jajajaja! _[gesto Laugh]_
      - **Profe Lucía:** Tomo nota para cuando llegues tarde. _[plano PrimerPlano de Profe Lucía · gesto Laugh]_
  - _(si tienes la marca «ensayo espejo»)_ **Profe Lucía:** Se nota que lo traías ensayado. Así da gusto. _[gesto Happy]_
  - **Profe Lucía:** Muy bien. Y ahora… ¡matemáticas! Sin quejas, que se oyen desde aquí.
- **Paso 16 · Escena** _(solo si en «asiento» elegiste «Nico»)_
  - _(la misma conversación «Presentaciones» de arriba)_
- **Paso 17 · Escena** _(solo si en «asiento» elegiste «Mateo»)_
  - _(la misma conversación «Presentaciones» de arriba)_
- **Paso 18 · Clase** — «Tu primera clase: Matemáticas»
  - _Lugar:_ Aula de 1.º A
- **Paso 19 · Escena**
  - _Lugar:_ Tu pupitre
  - _Narrador:_ _¡RIIIING!_
  - **Profe Lucía:** ¡Recreo! Tenéis quince minutos. Nada de subirse a la valla, Nico.
  - **Nico:** ¡Yo no he hecho nada! …Todavía.
- **Paso 20 · Ir a** el patio — «¡Recreo! Sal al patio»
  - _Lugar:_ el patio · _En escena:_ Nico, Álex, Omar, Vega, Sara, Iker, Bruno, Rubén, Hugo
  - 💬 _Comentario al pasar cerca de Bruno:_ «¿Y tú qué miras?»
  - 💬 _Comentario al pasar cerca de Rubén:_ «Jejeje. Nada, nada.»
  - 💬 _Comentario al pasar cerca de Hugo:_ «…Hola.»
  - 🗨 _Charla opcional con Álex (si te acercas a hablar):_
    - **Álex:** Soy la portera. Si Nico te dice que me ha metido gol alguna vez, miente.
  - 🗨 _Charla opcional con Vega (si te acercas a hablar):_
    - **Vega:** Omar está dibujando una nube con forma de bocadillo. Todas sus nubes tienen forma de bocadillo.
  - 🗨 _Charla opcional con Iker (si te acercas a hablar):_
    - **Iker:** ¿Sabías que el recreo se inventó para que los cerebros descansen? Bueno, lo he leído en algún sitio.
- **Paso 21 · Decisión** — «Acércate a uno de los grupos»
  - ➤ **Opción «Los deportistas (la cancha)»** (con Nico) _(efecto: decisión «grupo recreo» = Deportistas; Álex +6; Nico +6; deportividad +1)_
    - **Nico:** ¡Has venido! Esta es Álex. Es portera. Nadie le mete gol. Bueno, yo a veces.
    - **Álex:** Nunca. Nunca me ha metido gol. Hola.
    - _(si en «gusto» elegiste «Futbol»)_ **Nico:** ¡Tú dijiste que te gusta el fútbol! Mañana juegas con nosotros.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «Te apuesto a que yo sí te marco, Álex.» _(efecto: Álex +5; valentia +1; marca «apuesta alex»)_
        - **Álex:** Apuesta aceptada. El que pierda lleva los balones una semana.
      - ➤ «Yo mejor de defensa, que corro mucho.» _(efecto: Nico +5)_
        - **Nico:** ¡Alguien en defensa! ¡Justo lo que nos faltaba!
  - ➤ **Opción «Los artistas (la zona de juegos)»** (con Omar) _(efecto: decisión «grupo recreo» = Artistas; Omar +6; Vega +6; creatividad +1)_
    - **Omar:** …Espera. No te muevas. Te estoy dibujando.
    - **Vega:** Omar dibuja a todo el mundo. Es su forma de decir hola.
    - **Omar:** Ya está. Te he puesto una capa. Quedas mejor con capa.
    - _(si en «gusto» elegiste «Dibujar»)_ **Omar:** ¿Tú también dibujas? Mañana te dejo mi rotulador dorado.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «¡Hala! ¡Me encanta! ¿Me lo regalas?» _(efecto: Omar +6)_
        - **Omar:** Cuando lo termine. Los dibujos buenos se terminan despacio.
      - ➤ «¿Y a Vega qué le has puesto?» _(efecto: Vega +5; humor +1)_
        - **Vega:** Alas. De mariposa. Evidentemente.
  - ➤ **Opción «Los curiosos (junto al edificio)»** (con Sara) _(efecto: decisión «grupo recreo» = Estudiantes; Iker +6; Sara +6; curiosidad +1)_
    - **Sara:** Estábamos discutiendo una cosa importantísima: ¿las hormigas duermen?
    - **Iker:** Sí. Doscientas cincuenta siestas de un minuto al día. Lo leí.
    - **Sara:** Eso hay que comprobarlo EXPERIMENTALMENTE.
    - _(si en «gusto» elegiste «Ciencia»)_ **Sara:** ¡Tú dijiste que te gustan los experimentos! Estás dentro.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «Yo vigilo el hormiguero con vosotros.» _(efecto: Iker +4; Sara +6; curiosidad +1)_
        - **Sara:** ¡Equipo científico formado! Mañana traigo lupa.
      - ➤ «¿Y los peces? ¿Los peces duermen?» _(efecto: Iker +6)_
        - **Iker:** …No lo sé. Por primera vez en mi vida, NO LO SÉ.
- **Paso 22 · Cinemática**
  - _En escena:_ Nico, Álex, Omar, Vega, Sara, Iker, Bruno, Rubén, Hugo, Mateo
  - 🎬 **Cinemática «Cole01_LibrosCaen»**
    - _En escena:_ Mateo, Rubén, Bruno, Hugo, Nico, Sara, Omar
    - _Cámara:_ 2 planos (General, Inserto)
    - 🪧 _Rótulo:_ «¿Le ayudas a recoger sus cosas?»
    - **Rubén:** ¡Jajajaja! ¡Mirad al nuevo número dos! _[plano Reaccion de Rubén · en la pausa: Laugh · silencio 1.4 s]_
    - **Mateo:** … _[plano PPP de Mateo]_
    - _(si tienes las marcas «pase a dani» y «lleva cromo»)_ **Tú:** El hermano de Dani… y su álbum de cromos. Como el mío.
    - _(si tienes la marca «pase a dani» y NO tienes la marca «lleva cromo»)_ _(o bien)_ **Tú:** Es Mateo… el hermano de Dani. El del balón.
    - _(si tienes la marca «lleva cromo» y NO tienes la marca «pase a dani»)_ _(o bien)_ **Tú:** Ese álbum… es de cromos. Como el mío.
    - **Mateo:** … _[plano PrimerPlano de Mateo]_
- **Paso 23 · Varios objetivos (en cualquier orden)** — «¿Ayudas a Mateo a recoger sus cosas?»
  - **Paso 23.1 · Usar** — «Libro rojo»
  - **Paso 23.2 · Usar** — «Libro azul»
  - **Paso 23.3 · Usar** — «Cuaderno verde»
  - **Paso 23.4 · Usar** — «Álbum de cromos»
- **Paso 24 · Escena** _(solo si tienes la marca «ayudaste a mateo»)_
  - **Mateo:** G-gracias. Nadie… Bueno. Gracias. _[plano PrimerPlano de Mateo · gesto Ashamed · en la pausa: Baja]_
  - _(si tienes la marca «pase a dani»)_ **Mateo:** ¿Fuiste tú quien le pasó el balón a mi hermano esta mañana? No para de hablar de ti.
  - _(si tienes la marca «fallaste pase»)_ **Mateo:** Dani dice que alguien esta mañana casi le da a una farola con su balón. ¿Fuiste tú? Jeje.
  - **Mateo:** Me llamo Mateo. Colecciono cromos. Tengo repetido el portero legendario, por si… por si lo quieres.
  - _(si tienes la marca «lleva cromo»)_ **Tú:** ¡Yo tengo ese cromo! Es mi cromo de la suerte.
  - _(si tienes la marca «lleva cromo»)_ **Mateo:** ¿En serio? Entonces… somos del mismo equipo.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¿Mañana te sientas conmigo?» _(efecto: Mateo +8)_
      - **Mateo:** Vale. _[plano PrimerPlano de Mateo · gesto Happy · en la pausa: Sonrie]_
    - ➤ «Tu hermano dice que te rías más.» _(efecto: Mateo +5; humor +1)_
      - **Mateo:** Jajaja… Dani siempre dice eso. Es un pesado. Pero tiene razón.
- **Paso 25 · Escena** _(solo si tienes la marca «ignoraste a mateo»)_
  - **Rubén:** Jejeje… El nuevo número dos. Jejeje. _[plano Reaccion de Rubén · gesto Laugh]_
  - **Mateo:** … _[plano PrimerPlano de Mateo · gesto Ashamed · en la pausa: Baja]_
  - _Narrador:_ _Mateo recoge sus cosas él solo y se va a comer su bocadillo al rincón más lejano del patio._
- **Paso 26 · Escena**
  - _En escena:_ Profe Lucía, Ramón
  - _Narrador:_ _El resto del día pasa volando: más clases, más nombres nuevos, más ruido._
  - **Profe Lucía:** ¡Hasta mañana! Y recordad: mañana, con la mochila. ¡Que siempre hay alguno que se la deja!
  - **Ramón:** ¡O que la pierde! ¡Jejeje! _[a Profe Lucía · plano Reaccion de Ramón · gesto Laugh]_
- **Paso 27 · Ir a** tu casa familiar — «Vuelve a casa»
- **Paso 28 · Escena**
  - _Lugar:_ la cocina · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Por fin! Siéntate, que he hecho macarrones. ¿Y bien? ¿Qué tal tu primer día? _[plano Hombro de Tú → Mamá/Papá]_
  - **Abu:** Cuéntanoslo todo. Con detalles, que yo ya no me entero de nada. _[plano PrimerPlano de Abu · gesto Happy]_
  - _(si tienes la marca «llegas tarde»)_ **Mamá/Papá:** Y lo de llegar tarde… Mañana salimos cinco minutos antes. Los cinco minutitos, ya sabes. _[gesto Shrug]_
  - _(si en «ropa» elegiste «Dinosaurios»)_ **Abu:** ¿Y los dinosaurios de la camiseta? ¿Han causado sensación?
  - ❓ **Pregunta al jugador:** ¿Qué les cuentas primero?
    - ➤ _(si tienes la marca «ayudaste a mateo»)_ «¡He hecho un amigo! Se llama Mateo.» _(efecto: Mamá/Papá +3)_
      - **Abu:** ¿Ves? Lo que te dije: el que ayuda nunca está solo. _[plano PrimerPlano de Abu · en la pausa: Sonrie]_
    - ➤ _(si en «asiento» elegiste «Sara»)_ «Me he sentado con Sara. ¡Sabe muchísimo!»
      - **Mamá/Papá:** Una buena compañera de pupitre vale oro. Ya verás en los exámenes.
    - ➤ _(si en «grupo recreo» elegiste «Deportistas»)_ «Nico dice que mañana juego al fútbol con ellos.»
      - **Mamá/Papá:** ¡Pues habrá que lavar esas zapatillas!
    - ➤ _(si en «grupo recreo» elegiste «Artistas»)_ «Un niño que se llama Omar me ha dibujado con capa.»
      - **Abu:** ¡Un superhéroe en la familia! Ya era hora.
    - ➤ _(si en «grupo recreo» elegiste «Estudiantes»)_ «Hemos investigado si las hormigas duermen.»
      - **Abu:** ¿Y duermen? …¿No? ¿Todavía no lo sabéis? Qué emoción.
    - ➤ «Ha sido un rollo. Bueno… no tanto.» _(efecto: humor +1)_
      - **Mamá/Papá:** «No tanto» en idioma de niño significa «me lo he pasado genial». Lo sé.
  - _(si tienes la marca «ignoraste a mateo»)_ **Mamá/Papá:** ¿Y ese niño que se cayó? ¿Nadie le ayudó? _[en la pausa: Piensa]_
  - _(si tienes la marca «ignoraste a mateo»)_ **Mamá/Papá:** Mañana, si le ves solo, ve con él. ¿Vale?
  - **Mamá/Papá:** Qué orgullo, de verdad. Primer día: superado. _[plano Reaccion de Mamá/Papá · en la pausa: Sonrie · silencio 0.6 s]_
  - _Narrador:_ _Primer día de colegio: completado. Pero esto… no ha hecho más que empezar._

**Al terminar (momento de la biografía):** «Tu primer día de colegio»

---

### Cole02_Mochila · «La mochila desaparecida»

**Resumen:** Tu mochila ha desaparecido. Alguien sabe algo… y vas a descubrir quién.

_Tipo: Historia · Investigación · Edad: 6-7 años · Duración: 15-25 min_

**Requisitos:** has terminado «El primer día» y has vivido el 8 % de la etapa

**Lo que puede cambiar:** Enfadarte con Rubén · Perdonarle · Contárselo a Lucía · Devolverle la broma

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unos días después…»
  - ⏳ _Pantalla de transición:_ «Unos días después…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase (1.º A)»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Vega, Omar, Álex, Hugo, Bruno, Mateo, Nico
- **Paso 3 · Escena**
  - _Lugar:_ Tu pupitre
  - **Profe Lucía:** ¡Buenos días! [tu nombre], ¿me haces un favor? Lleva esta lista de clase a Ramón, a conserjería.
  - **Profe Lucía:** Deja la mochila en tu silla, que vuelves enseguida.
  - _Narrador:_ _Cuelgas la mochila en el respaldo. Al fondo, Bruno le susurra algo a Rubén. Rubén se ríe._
- **Paso 4 · Hablar** con Ramón — «Lleva la lista de clase a Ramón (conserjería, en la entrada)»
  - _Lugar:_ Conserjería · _En escena:_ Ramón
  - **Ramón:** ¡La lista! Gracias. Veinte nombres, veinte mochilas, veinte bocadillos. Y un conserje.
  - **Ramón:** ¿Sabes cuántas cosas pierde un colegio en un año? Trescientas doce. Las tengo apuntadas.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¿Y dónde van todas esas cosas?» _(efecto: Ramón +3; curiosidad +1)_
      - **Ramón:** Unas a mi caja de objetos perdidos. Otras… a sitios donde nadie mira. Jejeje.
    - ➤ «¡Me tengo que ir, que me espera Lucía!» _(efecto: responsabilidad +1)_
      - **Ramón:** ¡Corre, corre! Qué responsabilidad tan grande tan pequeña.
- **Paso 5 · Ir a** Aula de 1.º A — «Vuelve a clase»
  - _Lugar:_ Aula de 1.º A
- **Paso 6 · Escena**
  - _Narrador:_ _Vuelves a tu sitio. La silla está vacía._
  - **Tú:** …¿Y mi mochila?
  - _Narrador:_ _No está. Ni en la silla, ni debajo. Tu mochila azul, con tu nombre bordado, ha desaparecido._
  - _Narrador:_ _(Ya no la tienes.)_
  - _(si tienes la marca «lleva cromo»)_ **Tú:** Y el cromo de la suerte estaba dentro…
  - _Narrador:_ _Busca bien por el aula. A lo mejor alguien la ha cambiado de sitio._
- **Paso 7 · Varios objetivos (en cualquier orden)** — «Busca tu mochila en el aula»
  - **Paso 7.1 · Usar** — «Tu pupitre»
    - 🖐 _Al usar «Tu sitio»:_
      - _Narrador:_ _Debajo del pupitre: una goma, dos lápices sin punta y un chicle pegado de hace años. Ni rastro._
  - **Paso 7.2 · Usar** — «Tu taquilla del pasillo»
    - 🖐 _Al usar «Tu taquilla (la 3)»:_
      - _Narrador:_ _Tu taquilla, la número 3. Dentro: el chándal de gimnasia y una foto de tu familia. La mochila no cabe aquí._
  - **Paso 7.3 · Usar** — «La papelera (por si acaso)»
    - 🖐 _Al usar «Papelera»:_
      - _Narrador:_ _Miras dentro de la papelera. Solo papeles. Y una piel de plátano que te mira con pena._
      - **Tú:** Vale. Esto ya no es un despiste. Alguien se la ha llevado.
- **Paso 8 · Escena**
  - _En escena:_ Profe Lucía
  - **Profe Lucía:** ¿Qué pasa, [tu nombre]? Tienes cara de haber visto un fantasma.
  - **Tú:** Mi mochila. No está. La dejé aquí y… no está.
  - **Profe Lucía:** Vaya. Mochilas no vuelan. Pregunta a tus compañeros: alguien habrá visto algo. Yo aviso a Ramón.
- **Paso 9 · Varios objetivos (en cualquier orden)** — «Pregunta a tus compañeros»
  - _En escena:_ Sara, Omar, Iker, Mateo (si tienes la marca «ayudaste a mateo»), Nico
  - 🗨 _Charla opcional con Nico (si te acercas a hablar):_
    - **Nico:** ¿Tu mochila? ¡Qué fuerte! Si pillo al que ha sido, le reto a una carrera. Y le gano.
  - **Paso 9.1 · Hablar** con Mateo — «Mateo quiere decirte algo (zona de juegos)» _(solo si tienes la marca «ayudaste a mateo»)_
    - **Mateo:** [tu nombre]… yo lo vi. Fue Rubén. Bruno le dijo que lo hiciera.
    - **Mateo:** No dije nada porque… me dio miedo. Perdona.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Gracias por contármelo. Eres valiente.» _(efecto: Mateo +10; empatia +1)_
        - **Mateo:** ¿Yo? ¿Valiente? …Nadie me había dicho eso.
      - ➤ «¿Por qué no lo dijiste antes?» _(efecto: Mateo -3)_
        - **Mateo:** Ya… lo siento. Es que Bruno da miedo.
  - **Paso 9.2 · Hablar** con Sara — «Sara (en el aula)»
    - **Sara:** ¿Una mochila azul? Sí. Hace diez minutos. Por la ventana. Hacia el patio.
    - **Sara:** La llevaba alguien con prisa. Y con sudadera morada. Dato importante: la sudadera era MORADA.
  - **Paso 9.3 · Hablar** con Omar — «Omar (en el pasillo)»
    - **Omar:** Espera, que lo tengo dibujado. Dibujo todo lo que pasa en el pasillo. Es mi sitio.
    - _Narrador:_ _Omar te enseña su cuaderno: un niño corriendo con una mochila azul hacia… el gimnasio._
    - **Omar:** No le vi la cara. Iba muy rápido y los dibujos rápidos salen borrosos.
  - **Paso 9.4 · Hablar** con Iker — «Iker (en la biblioteca)»
    - **Iker:** Oí algo. «La mochila azul», dijo uno. «Al sitio de siempre», dijo otro. Y se rieron.
    - **Iker:** Dato curioso: el sitio de siempre suele ser el sitio donde nadie mira.
- **Paso 10 · Varios objetivos (en cualquier orden)** — «Busca pistas en el patio»
  - **Paso 10.1 · Usar** — «Un papel arrugado»
    - 🖐 _Al usar «Papel arrugado»:_
      - _Narrador:_ _Un horario de clase arrugado. En una esquina, alguien ha dibujado una calavera y ha firmado: «R.»_
  - **Paso 10.2 · Usar** — «Algo que brilla»
    - 🖐 _Al usar «Algo brillante»:_
      - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _¡Es tu cromo de la suerte! El portero legendario, tirado en el suelo. Se ha caído de tu mochila._
      - _(si NO tienes la marca «lleva cromo»)_ _Narrador:_ _Una pegatina de dinosaurio. Es la que estaba pegada en tu mochila. Se ha despegado aquí._
      - **Tú:** Mi mochila ha pasado por aquí. Seguro.
  - **Paso 10.3 · Usar** — «Huellas de barro»
    - 🖐 _Al usar «Huellas de barro»:_
      - _Narrador:_ _Huellas de barro. Zapatillas pequeñas. Van hacia el gimnasio… y se nota que alguien corría._
  - **Paso 10.4 · Usar** — «Un llavero»
    - 🖐 _Al usar «Llavero»:_
      - _Narrador:_ _Un llavero rojo con una «B» enorme. B… de Bruno._
      - **Tú:** Bruno no estaba solo. Pero este llavero es suyo.
  - **Paso 10.5 · Usar** — «Un envoltorio»
    - 🖐 _Al usar «Envoltorio rosa»:_
      - _Narrador:_ _Un envoltorio de chicle de fresa. Huele a fresa. Nada más. A veces una pista es solo basura._
- **Paso 11 · Escena**
  - _Narrador:_ _Repasas lo que sabes:_
  - _(si tienes la marca «pista sara»)_ _Narrador:_ _· Alguien con sudadera morada se la llevó hacia el patio._
  - _(si tienes la marca «pista omar»)_ _Narrador:_ _· Omar dibujó a alguien corriendo hacia el gimnasio._
  - _(si tienes la marca «pista iker»)_ _Narrador:_ _· «Al sitio de siempre», el sitio donde nadie mira._
  - _(si tienes la marca «pista mateo»)_ _Narrador:_ _· Mateo vio a Rubén. Y Bruno se lo mandó._
  - _(si tienes la marca «pista r»)_ _Narrador:_ _· Un papel firmado con una «R»._
  - _(si tienes la marca «pista b»)_ _Narrador:_ _· Un llavero con una «B»._
  - _(si tienes la marca «pista huellas»)_ _Narrador:_ _· Huellas de barro hacia el gimnasio._
  - **Tú:** Todo apunta al gimnasio. Allí, junto a la canasta, siempre están los mayores con Álex.
- **Paso 12 · Ir a** Gimnasio — «Sigue las huellas hasta el gimnasio»
  - _Lugar:_ Gimnasio · _En escena:_ Álex, Alumno de 6.º, Alumna de 6.º
  - 💬 _Comentario al pasar cerca de Alumno de 6.º:_ «¡Ni la toques, que es nuestra canasta!»
  - 💬 _Comentario al pasar cerca de Alumna de 6.º:_ «Álex siempre gana. Siempre.»
- **Paso 13 · Hablar** con Álex — «Habla con Álex»
  - **Álex:** Hola. ¿Buscas algo? Tienes cara de buscar algo.
  - **Tú:** Mi mochila. ¿Has visto a alguien pasar corriendo con una mochila azul?
  - **Álex:** Puede. Puede que sí. Pero la información es cara.
  - **Álex:** Trato: mete tres canastas. Si las metes, te lo cuento todo.
  - _(si tienes la marca «apuesta alex»)_ **Álex:** Y ya me debes una por la apuesta del otro día, que lo sé.
- **Paso 14 · Minijuego** — «¡Mete 3 canastas!»
  - 🎮 _Cómo se juega:_ Suelta cuando la aguja esté en verde. Cada canasta, más difícil.
- **Paso 15 · Escena**
  - _(si tienes la marca «canastas alex»)_ **Álex:** Vale, vale. Tres canastas. Un trato es un trato.
  - _(si tienes la marca «sin canastas»)_ **Álex:** Ni una. Uf. Mira… te lo cuento igual, que me das pena. Pero que no se entere nadie.
  - **Álex:** Rubén pasó con una mochila azul hace un rato. Se metió en el almacén del gimnasio.
  - **Álex:** Y Rubén solo hace cosas cuando Bruno se lo dice.
  - _(si tienes la marca «sabe del almacen»)_ **Tú:** El almacén… Ramón dijo que ahí no se entra sin permiso.
- **Paso 16 · Ir a** Almacén del gimnasio — «Ve al almacén del gimnasio»
- **Paso 17 · Escena**
  - _Narrador:_ _La puerta del almacén está entreabierta. Dentro huele a goma, a polvo y a secretos._
  - _Narrador:_ _Colchonetas, balones deshinchados… y varias mochilas amontonadas en una esquina._
- **Paso 18 · Varios objetivos (en cualquier orden)** — «Revisa las mochilas del almacén»
  - **Paso 18.1 · Usar** — «La roja»
    - 🖐 _Al usar «Mochila roja»:_
      - _Narrador:_ _Roja, con un llavero de unicornio. No es la tuya._
  - **Paso 18.2 · Usar** — «La verde»
    - 🖐 _Al usar «Mochila verde»:_
      - _Narrador:_ _Verde. Huele muchísimo a bocadillo de chorizo. Definitivamente, no es la tuya._
  - **Paso 18.3 · Usar** — «La amarilla»
    - 🖐 _Al usar «Mochila amarilla»:_
      - _Narrador:_ _Amarilla y gastada. Dentro, un libro de piratas con el nombre «Hugo» en la primera página._
      - **Tú:** ¿Hugo? ¿El amigo de Bruno lee libros de piratas?
- **Paso 19 · Escena**
  - _En escena:_ Rubén
  - **Rubén:** ¿Buscas esto?
  - _Narrador:_ _Rubén está detrás de ti. Señala la mochila azul del rincón: ¡la tuya! Sonríe… pero no mucho._
  - **Rubén:** Era una BROMA. Bruno dijo que a los nuevos hay que darles la bienvenida. Es una tradición.
  - _(si tienes la marca «pista mateo»)_ **Tú:** Mateo te vio. Y Bruno te lo mandó.
  - **Rubén:** …Mateo es un chivato. Bueno. Da igual. Ahí la tienes, entera.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «¡Enfadarte! «¡No tiene gracia!»» _(efecto: Bruno -5; Rubén -15; valentia +2; decisión «mochila ruben» = Enfado; marca «ruben rival»)_
      - **Tú:** ¡No tiene NINGUNA gracia! ¡Me he pasado la mañana buscándola!
      - **Rubén:** Vale, vale, no grites… Jo. Era solo una broma.
    - ➤ «Perdonarle. «Vale. Pero no lo vuelvas a hacer.»» _(efecto: Rubén +15; empatia +2; decisión «mochila ruben» = Perdon; marca «ruben perdonado»)_
      - **Tú:** Vale. Te perdono. Pero no vuelvas a hacerlo, ¿eh?
      - **Rubén:** ¿En serio? …Vale. Oye. Gracias. Bruno no perdona nunca a nadie.
    - ➤ «Contárselo a Lucía.» _(efecto: Bruno -10; Profe Lucía +5; Rubén -5; responsabilidad +2; decisión «mochila ruben» = Profe; marca «avisaste a lucia»)_
      - **Tú:** Esto se lo tiene que saber Lucía.
      - **Rubén:** ¡No! ¡Espera! …Uf. Bruno me va a matar. Bueno, a matar no. Pero se va a enfadar.
    - ➤ «Devolverle la broma…» _(efecto: Rubén +5; humor +2; decisión «mochila ruben» = Broma; marca «broma de vuelta»)_
      - _Narrador:_ _Rubén deja la mochila en el suelo para atarse una zapatilla. Su gorra morada se queda junto a una caja…_
      - _Narrador:_ _Una idea malvada (pero pequeñita) cruza tu cabeza._
- **Paso 20 · Usar** — «Esconde la gorra de Rubén» _(solo si en «mochila ruben» elegiste «Broma»)_
  - 🖐 _Al usar «La gorra de Rubén (en una caja)»:_
    - _Narrador:_ _Metes la gorra de Rubén dentro de la caja de balones deshinchados. Perfecto._
    - **Rubén:** ¿Y mi gorra? ¿DÓNDE ESTÁ MI GORRA? …Ah. Ya. Ja. Ja. Muy gracioso.
    - **Rubén:** …Vale, vale. Ha tenido gracia. Un poco.
- **Paso 21 · Escena**
  - _En escena:_ Rubén, Profe Lucía
  - **Profe Lucía:** ¿Qué hacéis los dos en el almacén? ¿No os ha dicho Ramón mil veces que aquí no se entra?
  - _(si en «mochila ruben» elegiste «Profe»)_ **Profe Lucía:** Rubén. Explícamelo. Ahora.
  - _(si en «mochila ruben» elegiste «Profe»)_ **Rubén:** Fue… una broma. Bruno me dijo… Da igual. Lo siento, [tu nombre]. De verdad.
  - _(si en «mochila ruben» elegiste «Profe»)_ **Profe Lucía:** Gracias por contármelo, [tu nombre]. Hablaré con Bruno y con Rubén. Esto no es una tradición: es una tontería.
  - _(si en «mochila ruben» elegiste «Perdon»)_ **Rubén:** Nada, profe. Estábamos… buscando un balón. Ya lo hemos encontrado.
  - _(si en «mochila ruben» elegiste «Perdon»)_ **Profe Lucía:** Ya. Un balón azul con forma de mochila. Id a clase, anda. Los dos.
  - _(si en «mochila ruben» elegiste «Enfado»)_ **Rubén:** ¡Me ha gritado, profe!
  - _(si en «mochila ruben» elegiste «Enfado»)_ **Profe Lucía:** Normal, Rubén. Yo también gritaría si me escondieran la mochila. [tu nombre]: la próxima vez, respira hondo y ven a buscarme.
  - _(si en «mochila ruben» elegiste «Broma»)_ **Rubén:** ¡Profe! ¡Me ha escondido la gorra!
  - _(si en «mochila ruben» elegiste «Broma»)_ **Profe Lucía:** Y tú a su mochila. Empate técnico. Ahora os la devolvéis los dos y a clase. Sin más bromas.
  - _Narrador:_ _Recuperas tu mochila. Dentro está todo. (Vuelves a tenerla.)_
  - _Narrador:_ _Al salir, ves a Bruno mirándoos desde la puerta del gimnasio. No parece contento._
  - _(si tienes la marca «sabe libro hugo»)_ _Narrador:_ _Detrás de él, Hugo baja la mirada. Como si quisiera estar en cualquier otro sitio._

**Al terminar (momento de la biografía):** «Recuperaste tu mochila»

---

### Cole03_Grupo · «El grupo»

**Resumen:** Nico te quiere en su equipo, Omar en su mural y Sara en su expedición. Hoy nace algo importante.

_Tipo: Historia · Amistad · Edad: 7-7 años · Duración: 20-25 min_

**Requisitos:** has terminado «La mochila desaparecida» y has vivido el 13 % de la etapa

**Lo que puede cambiar:** Partido ganado, perdido o empatado · Sueño de mayor · Nombre del grupo · Secundaria: el gato del colegio

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Una semana después…»
  - ⏳ _Pantalla de transición:_ «Una semana después…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Omar, Hugo, Bruno, Rubén, Mateo, Nico
- **Paso 3 · Clase** — «Clase de Ciencias»
- **Paso 4 · Escena**
  - _Lugar:_ Tu pupitre
  - **Profe Lucía:** Y por eso las plantas giran hacia el sol. ¡Recreo! Y Nico: el balón NO se lanza dentro del aula.
  - **Nico:** ¡Si todavía no lo he sacado!
- **Paso 5 · Ir a** el patio — «Sal al recreo»
  - _Lugar:_ el patio · _En escena:_ Nico, Omar, Sara
- **Paso 6 · Decisión** — «Nico, Omar y Sara quieren que vayas con ellos. ¿Con quién vas?»
  - _Lugar:_ Pista
  - ➤ **Opción «Nico: «¡Calienta, que hay partido!»»** (con Nico) _(efecto: decisión «invitacion» = Nico; Nico +6)_
    - **Nico:** ¡Por fin! Hoy jugamos contra los de Bruno. Me falta gente buena. Y tú eres gente buena.
    - **Nico:** Pero antes, calentamiento. Tres penaltis. Si metes dos, eres titular.
    - _(si en «gusto» elegiste «Futbol»)_ **Nico:** ¡Y encima te gusta el fútbol! Lo dijiste el primer día. Me acuerdo de TODO.
  - ➤ **Opción «Omar: «¿Me ayudas con el mural?»»** (con Omar) _(efecto: decisión «invitacion» = Omar; Omar +6)_
    - **Omar:** Lucía me deja pintar esta parte de la valla. Tres trozos: el cielo, el colegio y… nosotros.
    - **Omar:** Yo dibujo las líneas y tú rellenas. Es un trabajo en equipo. Y luego merendamos. Tengo hambre.
  - ➤ **Opción «Sara: «¡He visto un escarabajo rarísimo!»»** (con Sara) _(efecto: decisión «invitacion» = Sara; Sara +6)_
    - **Sara:** ¡Rápido! ¡Un escarabajo VERDE BRILLANTE! No sale en mi libro de insectos. ¡Puede ser una especie nueva!
    - **Sara:** Si lo descubrimos nosotros, le ponemos nuestro nombre. «Escarabajus Sara-y-[tu nombre]».
- **Paso 7 · Minijuego** — «Calienta: tres penaltis» _(solo si en «invitacion» elegiste «Nico»)_
  - _Lugar:_ Cancha de baloncesto · _En escena:_ Nico
  - 🎮 _Cómo se juega:_ Chuta cuando la aguja esté en verde
- **Paso 8 · Varios objetivos (en cualquier orden)** — «Pinta el mural con Omar» _(solo si en «invitacion» elegiste «Omar»)_
  - _Lugar:_ el patio · _En escena:_ Omar
  - **Paso 8.1 · Usar** — «El cielo»
    - 🖐 _Al usar «Mural: el cielo»:_
      - **Omar:** El cielo. Azul, pero no un azul cualquiera: azul de «hoy no hay deberes».
      - ❓ **Pregunta al jugador:** ¿Qué le añades?
        - ➤ «Un sol con gafas de sol» _(efecto: humor +1)_
          - **Omar:** Genial. Un sol que se protege del sol.
        - ➤ «Un cohete» _(efecto: curiosidad +1)_
          - **Omar:** Rumbo a Marte. Sara lo va a aprobar.
  - **Paso 8.2 · Usar** — «El colegio»
    - 🖐 _Al usar «Mural: el colegio»:_
      - **Omar:** El colegio. Con Ramón en la puerta, que si no, no es nuestro colegio.
      - _Narrador:_ _Pintas a Ramón con su manojo gigante de llaves. Le sale una sonrisa enorme._
  - **Paso 8.3 · Usar** — «Nosotros»
    - 🖐 _Al usar «Mural: nosotros»:_
      - **Omar:** Y aquí… nosotros. Tú, yo, y los que vengan. Dejo sitio. Siempre hay que dejar sitio.
      - **Omar:** ¿Sabes? No suelo dejar pintar a nadie en mis dibujos. Contigo es distinto.
- **Paso 9 · Usar** — «Sigue al escarabajo (zona de juegos)» _(solo si en «invitacion» elegiste «Sara»)_
  - _En escena:_ Sara (te acompaña)
  - 🖐 _Al usar «Escarabajo brillante»:_
    - **Sara:** ¡Ahí! No respires. Seis patas, caparazón verde… ¡y brilla! ¡BRILLA!
    - _Narrador:_ _El escarabajo abre las alas y sale volando hacia la cancha._
    - **Sara:** ¡Síguelo! ¡La ciencia no espera!
- **Paso 10 · Usar** — «¡Se ha ido volando hacia la cancha!» _(solo si en «invitacion» elegiste «Sara»)_
  - 🖐 _Al usar «Escarabajo brillante»:_
    - **Sara:** Se ha posado aquí. Fíjate: cuando le da el sol, cambia de color. ¡Es iridiscente!
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «¿Iri-qué?» _(efecto: humor +1)_
        - **Sara:** Iridiscente. Como las pompas de jabón. Te lo apunto.
      - ➤ «Como las pompas de jabón, ¿no?» _(efecto: Sara +3; curiosidad +1)_
        - **Sara:** ¡EXACTO! ¡Por fin alguien de mi nivel!
- **Paso 11 · Usar** — «¡Ahora está junto al edificio!» _(solo si en «invitacion» elegiste «Sara»)_
  - 🖐 _Al usar «Escarabajo brillante»:_
    - _Narrador:_ _El escarabajo se queda quieto en la pared. Sara saca su cuaderno y lo dibuja con muchísimo cuidado._
    - **Sara:** Registro científico número uno. Descubridores: Sara y [tu nombre]. Fecha: hoy.
    - **Sara:** Oye… ha sido el mejor recreo de mi vida.
- **Paso 12 · Escena**
  - _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña)
  - **Nico:** ¡EH! ¡Vosotros! ¡Nos faltan jugadores! Bruno dice que si no somos cinco, perdemos sin jugar.
  - **Omar:** Yo no sé jugar. Pero puedo ponerme de portero y no moverme. Soy muy bueno no moviéndome.
  - **Sara:** Estadísticamente, con cinco jugadores nuestras probabilidades suben un… bueno, suben. ¡Vamos!
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** ¿Yo… también puedo jugar?
  - _(si tienes la marca «ayudaste a mateo»)_ **Nico:** ¡Claro que sí, Mateo! ¡Cuantos más, mejor!
- **Paso 13 · Ir a** Campo de fútbol — «Ve al campo de fútbol»
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Hugo, Álex
- **Paso 14 · Escena**
  - **Andrés:** ¡Bien! Partido amistoso. A-MIS-TO-SO. Sin empujones, sin trampas y dando la mano al final. ¿Entendido?
  - _(si tienes la marca «avisaste a lucia»)_ **Bruno:** Mirad quién viene. Quien se chiva a los profes.
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Suerte. Pero no mucha, ¿eh? _[gesto WaveLite]_
  - _(si tienes la marca «broma de vuelta»)_ **Rubén:** Hoy me toca ganar a mí. Por lo de la gorra.
  - **Bruno:** Esto va a ser muy fácil. Cinco minutos y os vais llorando.
  - **Hugo:** …Bruno, que es solo un partido.
  - **Nico:** ¿Dónde juegas?
  - ❓ **Pregunta al jugador:** Elige tu posición
    - ➤ «Delante: ¡a marcar goles!» _(efecto: valentia +1; decisión «posicion» = Delantero)_
      - **Nico:** ¡Dúo de ataque! Tú y yo. Que tiemble Álex.
    - ➤ «Defensa: que no pase nadie.» _(efecto: responsabilidad +1; decisión «posicion» = Defensa)_
      - **Sara:** Un muro humano. Sólido. Me gusta.
    - ➤ «Portería: que Omar descanse.» _(efecto: Omar +4; decisión «posicion» = Portero)_
      - **Omar:** ¡Gracias! Yo defiendo el bocadillo del banquillo.
  - **Andrés:** ¡Preparados…! ¡PRRRRIII!
- **Paso 15 · Minijuego** — «¡Partido contra el equipo de Bruno!»
- **Paso 16 · Escena**
  - **Andrés:** ¡Final! Y ahora, todos a dar la mano. Todos, Bruno.
  - _(si tienes la marca «partido ganado»)_ **Nico:** ¡HEMOS GANADO! ¡HEMOS GANADO A BRUNO! ¡Esto hay que contárselo a mis nietos!
  - _(si tienes la marca «partido empate»)_ **Nico:** Empate. Bueno. Un empate contra Bruno es como ganar. Casi.
  - _(si tienes la marca «partido perdido»)_ **Nico:** Hemos perdido… Pero ¿habéis visto esa jugada? La próxima vez, les ganamos.
  - **Sara:** He contado los pases: veintitrés. Somos un equipo con futuro. Los datos no mienten.
  - **Omar:** Lo he dibujado todo. Toma, este es para ti. Sales tú marcando. Más o menos así fue.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo… he tocado el balón dos veces. Dos. Es mi récord.
  - **Hugo:** Buen partido. En serio. _[gesto Ashamed · en la pausa: Baja]_
  - ❓ **Pregunta al jugador:** ¿Qué dices al grupo?
    - ➤ «¡Somos un equipazo!» _(efecto: Nico +3; Omar +3; Sara +3; deportividad +1)_
    - ➤ «Omar, casi te comes el bocadillo en plena jugada.» _(efecto: Omar +4; humor +1)_
      - **Omar:** Estaba defendiéndolo. Es distinto.
    - ➤ «Lo mejor ha sido jugar juntos.» _(efecto: Mateo +3; Nico +3; Omar +3; Sara +3; empatia +1)_
  - **Nico:** Oye… ¿y si después de clase vamos todos al parque? Hay canasta, columpios, y un quiosco de helados.
  - ❓ **Pregunta al jugador:** ¿Vas?
    - ➤ «¡Sí! ¡Nos vemos allí!» _(efecto: decisión «permiso» = Directo)_
    - ➤ «Primero pido permiso en casa.» _(efecto: responsabilidad +1; decisión «permiso» = Casa)_
      - **Sara:** Muy responsable. Te esperamos en la puerta de tu casa.
- **Paso 17 · Transición (pasa el tiempo)** — «Por la tarde…»
  - ⏳ _Pantalla de transición:_ «Por la tarde…»
- **Paso 18 · Ir a** tu casa familiar — «Pide permiso en casa» _(solo si en «permiso» elegiste «Casa»)_
- **Paso 19 · Hablar** con Mamá/Papá — «Habla con mamá/papá» _(solo si en «permiso» elegiste «Casa»)_
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá
  - **Tú:** ¿Puedo ir al parque con mis amigos? ¡Porfa! Volvemos antes de cenar.
  - **Mamá/Papá:** ¿Amigos? ¿Ya tienes amigos? ¡Eso es maravilloso!
  - **Mamá/Papá:** Claro que sí. Antes de cenar. Y nada de subirse a los árboles.
- **Paso 20 · Escena**
  - _Lugar:_ La puerta de casa · _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Mateo (si tienes la marca «ayudaste a mateo») (te acompaña)
  - **Nico:** ¡Estamos todos! ¡Al parque!
  - **Omar:** Yo me he traído merienda. Por si acaso. Siempre por si acaso.
  - _Narrador:_ _Tus amigos te siguen. Guíales hasta el parque._
- **Paso 21 · Ir a** el parque — «Ve al parque con tus amigos (te siguen)»
  - _Lugar:_ el parque
- **Paso 22 · Varios objetivos (en cualquier orden)** — «Pasa la tarde en el parque»
  - _Lugar:_ Parque · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 22.1 · Usar** — «Tirar a canasta con Nico»
    - 🖐 _Al usar «Canasta del parque»:_
      - **Nico:** Reto: el que meta desde más lejos, elige el helado de todos.
      - ❓ **Pregunta al jugador:** ¿Cómo tiras?
        - ➤ «Tiro lejano. A lo grande.» _(efecto: valentia +1)_
          - _Narrador:_ _El balón vuela… rebota en el aro… ¡y entra! Nico se tira al suelo de la emoción._
        - ➤ «Bandeja, sin arriesgar.» _(efecto: responsabilidad +1)_
          - _Narrador:_ _Canasta segura. Nico falla la suya a propósito para que ganes. Luego lo niega._
  - **Paso 22.2 · Usar** — «Columpios con Omar»
    - 🖐 _Al usar «Columpios»:_
      - **Omar:** Cuando te columpias muy alto, las nubes parecen dibujos. Esa es un dragón comiéndose un bocadillo.
      - **Tú:** Tú ves bocadillos en todas partes.
      - **Omar:** Y tú, cuando te conozca más, también.
  - **Paso 22.3 · Usar** — «Experimento con Sara en la fuente»
    - 🖐 _Al usar «Fuente»:_
      - **Sara:** Experimento en la fuente: ¿qué flota? Tenemos una hoja, una piedrecita y una piña.
      - ❓ **Pregunta al jugador:** ¿Qué flotará?
        - ➤ «La hoja y la piña» _(efecto: Sara +4; curiosidad +1)_
          - **Sara:** ¡Correcto! La piña tiene aire dentro. Serías una científica o un científico estupendo.
        - ➤ «La piedra, que es muy valiente» _(efecto: Sara +2; humor +1)_
          - _Narrador:_ _¡PLOP! La piedra se hunde. Sara se ríe tanto que casi se cae al estanque._
  - **Paso 22.4 · Usar** — «Helados en el quiosco»
    - 🖐 _Al usar «Quiosco de helados»:_
      - _Narrador:_ _El quiosquero os mira por encima de las gafas. Helados a 2 $._
      - ❓ **Pregunta al jugador:** ¿Qué haces?
        - ➤ «¡Invito yo a todos! (8 $)» _(efecto: Mateo +3; Nico +3; Omar +3; Sara +3; objeto helado)_
          - _(si NO tienes la marca «sin dinero»)_ **Omar:** Eres la mejor persona que conozco. Después de mi abuela.
          - _(si tienes la marca «sin dinero»)_ **Mateo:** No te llega… Yo tengo mi paga. Invito yo. Nunca había invitado a nadie.
        - ➤ «Uno para mí (2 $)» _(efecto: objeto helado)_
          - _(si NO tienes la marca «sin dinero»)_ **Omar:** ¿Me das un chupito? Solo la puntita.
          - _(si tienes la marca «sin dinero»)_ _Narrador:_ _No te llega el dinero. Omar comparte el suyo contigo sin decir nada._
- **Paso 23 · Usar** — «Sentaos en el banco»
- **Paso 24 · Escena**
  - _Narrador:_ _El sol empieza a bajar. Os sentáis todos apretados en el banco._
  - **Sara:** Pregunta importante. ¿Qué queréis ser de mayores?
  - **Nico:** Futbolista. Obvio. En la selección. Y luego entrenador. Y luego presidente del club.
  - **Omar:** Dibujante de cómics. De los que salen en las tiendas. Con mi nombre en la portada.
  - **Sara:** Yo, astronauta. O científica. O las dos: científica en el espacio.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo… veterinario. Para cuidar animales que nadie quiere.
  - **Sara:** ¿Y tú, [tu nombre]?
  - ❓ **Pregunta al jugador:** ¿Qué quieres ser de mayor?
    - ➤ «Salvar vidas en un hospital» _(efecto: empatia +1; decisión «sueno infancia» = Medicina)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Tú curas a las personas y yo a los animales. Somos un equipo.
    - ➤ «Inventar cosas que no existen» _(efecto: curiosidad +1; decisión «sueno infancia» = Ingenieria)_
      - **Sara:** ¡Me haces un cohete y yo lo piloto!
    - ➤ «Defender a la gente en los juzgados» _(efecto: valentia +1; decisión «sueno infancia» = Derecho)_
      - **Nico:** Pues ya puedes empezar defendiéndome de los deberes.
    - ➤ «Tener mi propia tienda o empresa» _(efecto: responsabilidad +1; decisión «sueno infancia» = Economia)_
      - **Omar:** Que sea una tienda de bocadillos. Te hago el cartel.
    - ➤ «Ser artista» _(efecto: creatividad +1; decisión «sueno infancia» = Arte)_
      - **Omar:** ¡Lo sabía! Haremos un cómic juntos.
    - ➤ «Deportista profesional» _(efecto: deportividad +1; decisión «sueno infancia» = Deporte)_
      - **Nico:** ¡En mi equipo! ¡Fichado!
  - _Narrador:_ _Nadie lo sabe todavía, pero este momento volverá a tu memoria muchos años después._
- **Paso 25 · Escena**
  - **Omar:** Por cierto… ¿sabéis que en el cole vive un gato? Naranja. Duerme detrás del gimnasio.
  - **Sara:** Nadie sabe de quién es. Ramón le deja agua, pero dice que no es suyo.
  - **Omar:** Esta semana no le he visto. Y a lo mejor tiene hambre. ¿Me ayudáis a buscarlo?
  - ❓ **Pregunta al jugador:** ¿Buscaréis al gato?
    - ➤ «¡Claro! Mañana lo buscamos.» _(efecto: Omar +4; empatia +1; más tarde empieza «El gato del colegio»)_
      - **Omar:** Sabía que dirías que sí. Le llamo Bigotes. En secreto.
    - ➤ «Seguro que está bien, los gatos saben cuidarse.»
      - **Omar:** Ya… seguramente.
- **Paso 26 · Escena**
  - **Nico:** Oye. Ahora somos un grupo, ¿no? Los grupos tienen nombre. Es la ley.
  - ❓ **Pregunta al jugador:** ¿Cómo os llamáis?
    - ➤ «Los Imparables» _(efecto: decisión «nombre grupo» = Los Imparables)_
    - ➤ «La Patrulla Valmar» _(efecto: decisión «nombre grupo» = La Patrulla Valmar)_
    - ➤ «Los del Banco Azul» _(efecto: decisión «nombre grupo» = Los del Banco Azul)_
    - ➤ _(si en «ropa» elegiste «Dinosaurios»)_ «Los Dinosaurios» _(efecto: decisión «nombre grupo» = Los Dinosaurios)_
  - **Nico:** ¡[nombre de tu grupo]! ¡Me encanta! ¡Grito de guerra!
  - **Omar:** Foto. Tenemos que hacernos una foto. Para dibujarla luego.
  - **Sara:** Todos juntos. Tres, dos, uno…
- **Paso 27 · Cinemática**
  - 🎬 **Cinemática «Cole03_Foto»** _(vuelo de cámara, 7 s, 1 planos; música: efecto Momento)_
    - 🪧 _Rótulo:_ «📸 ¡Patata!» — Tu grupo de amigos

**Al terminar (momento de la biografía):** «Ya tienes tu grupo de amigos»

---

### Cole04_Malotes · «Los malotes»

**Resumen:** Bruno y su pandilla se han pasado de la raya. Esta vez, algo tuyo ha desaparecido.

_Tipo: Historia · Conflicto · Edad: 7-8 años · Duración: 20-30 min_

**Requisitos:** has terminado «El grupo» y has vivido el 18 % de la etapa

**Lo que puede cambiar:** Lucía interviene · Hablas con Bruno (lo de su hermano) · Tu grupo se planta · Lo dejas estar

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unas semanas después…»
  - ⏳ _Pantalla de transición:_ «Unas semanas después…»
- **Paso 2 · Ir a** el patio — «Es la hora del recreo: busca a tu grupo»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 3 · Escena**
  - _Lugar:_ Banco junto al edificio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Hugo
  - _Narrador:_ _Recreo. Tu grupo está en el banco de siempre. Hasta que llegan ellos._
  - **Bruno:** Mira, mira. El grupito del banco. ¿Qué pasa, os habéis perdido?
  - **Bruno:** ¿Seguís con ese nombre? «[nombre de tu grupo]». Suena a club de abuelos. _[plano Hombro de Tú → Bruno · gesto HandsOnHips]_
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Je… je. _[gesto Ashamed · en la pausa: Aparta]_
  - _(si tienes la marca «avisaste a lucia»)_ **Rubén:** ¡Cuidado, que aquí hay quien se chiva! ¡Que viene Lucía! Jajaja.
  - _(si tienes la marca «partido ganado»)_ **Bruno:** El otro día ganasteis de chiripa. La próxima os vais a enterar.
  - **Hugo:** …Bruno, vámonos ya.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Ignorarles y seguir hablando con los tuyos» _(efecto: responsabilidad +1)_
      - **Sara:** Estadísticamente, el que busca pelea se aburre en treinta segundos.
    - ➤ «Por lo menos nosotros tenemos nombre, Bruno.» _(efecto: Bruno -3; Nico +3; humor +1)_
      - **Nico:** ¡Jajaja! ¡Toma ya!
      - **Bruno:** Muy gracioso. Ya te reirás menos.
    - ➤ «Levantarte y ponerte delante: «Déjanos en paz.»» _(efecto: Bruno -2; valentia +2)_
      - **Bruno:** Uy, qué valiente. Vale, vale. Ya nos vamos.
  - _Narrador:_ _Se van riéndose. Al pasar junto a tu mochila, Bruno le da un golpecito con el pie. Nadie le da importancia._
- **Paso 4 · Ir a** Aula de 1.º A — «Vuelve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 5 · Escena** _(solo si tienes la marca «lleva cromo»)_
  - _Narrador:_ _Vuelves a clase. Abres el bolsillo pequeño de la mochila, el de las emergencias…_
  - **Tú:** ¿Mi cromo? ¿Dónde está mi cromo de la suerte?
  - _Narrador:_ _No está. El portero legendario ha desaparecido. (Ya no está en tu mochila.)_
- **Paso 6 · Escena** _(solo si NO tienes la marca «lleva cromo»)_
  - _Narrador:_ _Vuelves a clase y buscas en la mochila la foto del grupo, la del parque…_
  - **Tú:** ¿Y la foto? Estaba aquí. ¡Estaba AQUÍ!
  - _Narrador:_ _No está. La foto del grupo ha desaparecido. (Ya no está en tu mochila.)_
- **Paso 7 · Varios objetivos (en cualquier orden)** — «Averigua qué ha pasado»
  - _Lugar:_ Pista · _En escena:_ Nico, Sara, Omar, Profe Lucía, Ramón, Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 7.1 · Hablar** con Mateo — «Mateo quiere decirte algo» _(solo si tienes la marca «ayudaste a mateo»)_
    - **Mateo:** Lo vi. Cuando Bruno pasó junto a tu mochila, Hugo se agachó y cogió algo. Pero… ponía cara de no querer.
  - **Paso 7.2 · Hablar** con Nico — «Nico (en la pista)»
    - **Nico:** ¡Sabía que Bruno tramaba algo! Al salir del recreo iban los tres juntos, riéndose, hacia el pasillo.
    - **Nico:** Si quieres les reto a una carrera y el que gane se queda… vale, no, eso no funciona así.
  - **Paso 7.3 · Hablar** con Sara — «Sara (en el aula)»
    - **Sara:** Datos: los tres salieron del recreo dos minutos antes que nadie. Suelen esconderse en el pasillo, junto a las taquillas.
    - **Sara:** Y otro dato: Hugo no se reía. En ningún momento. Lo anoté.
  - **Paso 7.4 · Hablar** con Omar — «Omar (en el pasillo)»
    - **Omar:** Tengo un dibujo de hace un rato: Bruno enseñándole algo pequeño a Rubén. Y Hugo mirando al suelo.
    - **Omar:** Los dibujos no mienten. Bueno, a veces pongo capas. Pero en esto no.
  - **Paso 7.5 · Hablar** con Profe Lucía — «Lucía (en la pizarra)»
    - **Profe Lucía:** ¿Te han quitado algo? Uf. Sin pruebas no puedo acusar a nadie, [tu nombre]. Pero te creo.
    - **Profe Lucía:** Si lo encuentras, ven a contármelo. Y nada de correr por los pasillos, ¿eh?
  - **Paso 7.6 · Hablar** con Ramón — «Ramón (en conserjería)»
    - **Ramón:** ¿Bruno y compañía? Hace un rato los he visto en el pasillo, junto a las taquillas. Como siempre.
    - **Ramón:** Y cuando les pillan, salen corriendo hacia el gimnasio. Se creen que no lo sé. Lo sé todo.
- **Paso 8 · Ir a** Pasillo — «Ve al pasillo»
  - _Lugar:_ Pasillo · _En escena:_ Bruno, Rubén, Hugo
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Cole04_LosVes»** _(música: → Tension)_
    - _En escena:_ Bruno, Rubén, Hugo
    - _Cámara:_ 1 planos (Hombro)
    - _(si tienes la marca «objeto cromo»)_ **Bruno:** …y ni se ha dado cuenta. Mira qué brillo: el portero legendario. _[a Rubén · plano Inserto de Bruno · silencio 1.4 s]_
    - _(si NO se cumple: tienes la marca «objeto cromo»)_ _(o bien)_ **Bruno:** …y ni se ha dado cuenta. Mira: la foto del grupito. Qué monos todos. _[a Rubén · plano Inserto de Bruno · silencio 1.4 s]_
    - **Hugo:** …Bruno. Vámonos. _[a Bruno · plano PrimerPlano de Hugo · en la pausa: Suelo]_
    - _(si tienes la marca «ruben rival»)_ **Rubén:** Jejeje. Como lo de la mochila. Igualito. _[a Bruno · plano Reaccion de Rubén]_
    - _(si tienes la marca «ruben perdonado»)_ _(o bien)_ **Rubén:** Bruno… Que es suyo. Devuélveselo y ya está. _[a Bruno · plano Reaccion de Rubén · en la pausa: Suelo]_
    - **Tú:** ¡Eh! ¡Eso es mío! _[plano Hombro de Bruno → Tú · emoción Angry]_
    - **Bruno:** ¡Corred! _[plano Reaccion de Bruno · en la pausa: Point · emoción Fear · silencio 0.7 s]_
    - _Narrador:_ _¡Corre tras ellos! Mantén Shift para correr (y vigila tu estamina)._
- **Paso 10 · Ir a** el patio — «¡Síguelos! Corre (Shift) hacia el patio»
  - _Lugar:_ el patio · _En escena:_ Hugo, Bruno, Rubén
  - 🖐 _Al usar «Atajo por el aula de música»:_
    - _Narrador:_ _Te cuelas por el aula de música (¡perdón, piano!) y sales por la otra puerta, justo al lado del gimnasio._
- **Paso 11 · Escena**
  - _Lugar:_ Pasillo · _En escena:_ Hugo, Bruno, Rubén, Ramón
  - **Ramón:** ¿QUIÉN ESTÁ CORRIENDO POR MI PATIO?
  - _Narrador:_ _¡Ramón! Si te ve corriendo, te toca charla. Rápido, ¡escóndete detrás de las cajas!_
- **Paso 12 · Usar** — «¡Escóndete detrás de las cajas antes de que Ramón te vea!»
  - 🖐 _Al usar «Detrás de las cajas»:_
    - _Narrador:_ _Te agachas detrás de las cajas. Ramón pasa de largo, silbando._
    - **Ramón:** Hmm. Juraría que he oído a alguien. Serán los gatos.
- **Paso 13 · Escena** _(solo si tienes la marca «pillado corriendo»)_
  - **Ramón:** ¡Ajá! ¡Te pillé! ¿Tú corriendo? Esto no me lo esperaba.
  - **Tú:** ¡Es que me han quitado una cosa! ¡Se han ido por ahí!
  - **Ramón:** …Vale. Por esta vez. Hugo ha ido hacia el gimnasio. Andando, ¿eh? ANDANDO.
- **Paso 14 · Persecución** — «¡Alcanza a Hugo! Se ha ido hacia el gimnasio (atajo: el aula de música)»
  - _En escena:_ Hugo, Bruno, Rubén
  - 🖐 _Al usar «Atajo por el aula de música»:__(la misma conversación «Atajo» de arriba)_
- **Paso 15 · Escena**
  - _Lugar:_ Almacén del gimnasio · _En escena:_ Hugo
  - _Narrador:_ _Detrás del gimnasio, Hugo se ha quedado sin aire. No sigue corriendo. Se sienta en el bordillo._
  - **Hugo:** Vale… vale. Me rindo. No sé correr. Nunca he sabido.
  - **Tú:** ¿Por qué lo habéis hecho?
  - _(si tienes la marca «pista hugo»)_ **Tú:** Mateo te vio cogerlo. Dice que ponías cara de no querer.
  - **Hugo:** Yo no quería. Bruno dijo «cógelo tú, que a ti no te vigilan». Y yo… no sé decir que no. _[plano PrimerPlano de Hugo · gesto Ashamed · en la pausa: Baja]_
  - **Hugo:** Bruno no es tan malo. Su hermano mayor se ríe de él todo el rato.
  - **Hugo:** Y él… hace lo mismo con los demás. _[en la pausa: Piensa]_
  - _(si tienes la marca «sabe libro hugo»)_ **Tú:** El otro día vi tu libro de piratas en el almacén.
  - _(si tienes la marca «sabe libro hugo»)_ **Hugo:** ¿«La isla de las mil llaves»? ¿Lo has leído? …Nadie se fija en eso. Bruno dice que leer es de pringados.
- **Paso 16 · Escena** _(solo si tienes la marca «lleva cromo»)_
  - **Hugo:** Toma. Es tuyo. Lo siento. De verdad.
  - _Narrador:_ _Lo recuperas. (Vuelve a estar en tu mochila.)_
- **Paso 17 · Escena** _(solo si NO tienes la marca «lleva cromo»)_
  - _(la misma conversación «Devuelve» de arriba)_
- **Paso 18 · Escena**
  - **Hugo:** ¿Y ahora qué vas a hacer?
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Contárselo a Lucía. Esto tiene que parar.» _(efecto: Hugo -2; Profe Lucía +3; responsabilidad +2; decisión «malotes» = Lucia)_
      - **Hugo:** …Vale. Iré contigo. Si voy yo también, quizá no se enfade tanto conmigo.
    - ➤ «Hablar con Bruno. Cara a cara.» _(efecto: Hugo +5; valentia +2; decisión «malotes» = Hablar)_
      - **Hugo:** ¿Sin nadie más? Qué valor. …Me gusta.
    - ➤ «Pedir ayuda a mi grupo. Juntos.» _(efecto: Hugo +3; empatia +1; valentia +1; decisión «malotes» = Grupo)_
      - **Hugo:** Tenéis suerte. Un grupo de verdad. Yo tengo… a Bruno.
    - ➤ «Dejarlo estar. Ya tengo lo mío.» _(efecto: Hugo -3; decisión «malotes» = Ignorar)_
      - **Hugo:** Ya. Normal. …Bueno. Adiós.
- **Paso 19 · Hablar** con Profe Lucía — «Cuéntaselo a Lucía (en el aula)» _(solo si en «malotes» elegiste «Lucia»)_
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Hugo (te acompaña)
  - **Tú:** Lucía. Bruno, Rubén y Hugo me quitaron una cosa. Ya la tengo, pero…
  - **Hugo:** Es verdad. Yo la cogí. Bruno me lo dijo. Pero yo la cogí.
  - **Profe Lucía:** Gracias a los dos por decirlo. Hugo, eso ha sido muy valiente.
  - **Profe Lucía:** Hablaré con Bruno. Y con su familia. Esto no es una broma: es hacer daño. Y hay que pararlo.
- **Paso 20 · Hablar** con Bruno — «Busca a Bruno (en la puerta del cole)» _(solo si en «malotes» elegiste «Hablar»)_
  - _Lugar:_ Puerta del cole · _En escena:_ Bruno, Rubén
  - **Bruno:** ¿Qué quieres? ¿Vienes a chivarte? _[plano Hombro de Tú → Bruno · gesto ArmsCrossed]_
  - **Tú:** No. Vengo a hablar contigo. Hugo me lo ha contado todo. Lo de tu hermano también. _[plano Hombro de Bruno → Tú]_
  - **Bruno:** …Hugo habla demasiado. _[plano PrimerPlano de Bruno · en la pausa: Aparta]_
  - **Bruno:** Mi hermano me llama enano. Delante de sus amigos. Todos los días. _[plano PPP de Bruno · gesto Sad · en la pausa: Baja · silencio 1.0 s]_
  - **Bruno:** ¿Contento? _[gesto Angry · en la pausa: Mira]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Pues ya sabes lo que se siente. No se lo hagas a otros.» _(efecto: Bruno +6; empatia +2)_
      - **Bruno:** …Ya. Vale. Lo pillo. No te prometo nada. Pero lo pillo. _[plano PrimerPlano de Bruno · en la pausa: Piensa]_
    - ➤ «Eso no te da derecho a quitarme las cosas.» _(efecto: Bruno +2; valentia +1)_
      - **Bruno:** Ya lo sé. Ya lo SÉ. _[gesto Angry]_
      - **Bruno:** …Perdona. Ya está. No me hagas repetirlo. _[plano PPP de Bruno · gesto Ashamed · en la pausa: Aparta · silencio 0.8 s]_
  - **Rubén:** ¿Bruno pidiendo perdón? …Vale. Yo no he visto nada. _[plano Reaccion de Rubén · gesto Surprised]_
- **Paso 21 · Ir a** Banco junto al edificio — «Ve a buscar a tu grupo (el banco del patio)» _(solo si en «malotes» elegiste «Grupo»)_
  - _Lugar:_ Banco junto al edificio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 22 · Hablar** con Bruno — «Id juntos a hablar con Bruno (puerta del cole)» _(solo si en «malotes» elegiste «Grupo»)_
  - _Lugar:_ Puerta del cole · _En escena:_ Bruno, Rubén, Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Hugo (te acompaña)
  - **Nico:** Bruno. Somos [nombre de tu grupo]. Somos cinco. Y estamos hartos. _[a Bruno · plano DosPlanos de Nico → Bruno · gesto HandsOnHips]_
  - **Sara:** Tenemos pruebas: testigos, un dibujo de Omar y el horario. Si sigues, se lo contamos a Lucía.
  - **Omar:** El dibujo es muy bueno, por cierto. Sales tú con cara de culpable.
  - **Bruno:** …Vale, vale. Os dejamos en paz. Qué pesados. _[en la pausa: Aparta]_
  - **Bruno:** ¿Tú no vienes, Hugo? _[a Hugo · plano Hombro de Bruno → Hugo · silencio 0.6 s]_
  - **Hugo:** …No. Hoy no. _[a Bruno · plano PrimerPlano de Hugo · en la pausa: Respira · silencio 1.0 s]_
- **Paso 23 · Escena** _(solo si en «malotes» elegiste «Ignorar»)_
  - _Lugar:_ Almacén del gimnasio · _En escena:_ Hugo
  - _Narrador:_ _Te das la vuelta y te vas. Ya tienes lo tuyo._
  - _Narrador:_ _Al girar la esquina miras atrás. Hugo sigue sentado en el bordillo, solo._
- **Paso 24 · Escena**
  - _Lugar:_ el patio · _En escena:_ Hugo (si NO tienes la marca «hugo solo»)
  - _Narrador:_ _Ese día aprendiste algo: casi nadie es malo del todo. Y casi nadie es valiente del todo._
  - _(si NO tienes la marca «hugo solo»)_ **Hugo:** ¡[tu nombre]! …Gracias. _[plano Reaccion de Hugo · gesto WaveLite · silencio 0.6 s]_

**Al terminar (momento de la biografía):** «Recuperaste lo que era tuyo… y conociste de verdad a Hugo»

---

### Cole05_Venganza · «La venganza de la mochila»

**Resumen:** Alguien está gastando bromas por todo el colegio. Todos culpan a Bruno. ¿Seguro que es él?

_Tipo: Historia · Investigación · Edad: 8-8 años · Duración: 15-20 min_

**Requisitos:** has terminado «Los malotes» y has vivido el 24 % de la etapa

**Lo que puede cambiar:** Iker entra en el grupo · Iker pide perdón él mismo · Lucía habla con Iker · Acusaste a Bruno sin pruebas (o no)

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Un mes después…»
  - ⏳ _Pantalla de transición:_ «Un mes después…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 3 · Escena**
  - _Lugar:_ Pizarra · _En escena:_ Profe Lucía, Bruno
  - _Narrador:_ _Hoy el aula es un caos._
  - _Narrador:_ _A Vega le han cambiado sus pegatinas brillantes por pegatinas de calcetines sucios._
  - _Narrador:_ _A Álex le han escondido los guantes de portera. Y la taquilla de Nico está llena de papelitos._
  - **Bruno:** ¡YA ESTÁ BIEN! ¡Todos me miráis a mí! ¡Esta vez NO he sido yo!
  - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Tú lo sabes, ¿verdad? Tú hablaste conmigo. Sabes que no miento.
  - **Profe Lucía:** Silencio. [tu nombre], tú descubriste lo de la mochila. ¿Me ayudas a averiguar qué pasa? Sin acusar a nadie sin pruebas.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Habla con quienes sufrieron las bromas»
  - _Lugar:_ Comedor · _En escena:_ Vega, Álex, Nico
  - **Paso 4.1 · Hablar** con Vega — «Vega (en el comedor)»
    - **Vega:** Mis pegatinas de purpurina… y en su lugar, ¡calcetines sucios! Con una nota: «Nadie mira lo que brilla de verdad».
    - **Vega:** La letra era perfecta. Como de máquina. Bruno escribe como un pollo, eso lo sabe todo el mundo.
  - **Paso 4.2 · Hablar** con Álex — «Álex (en el gimnasio)»
    - **Álex:** Mis guantes de portera. Desaparecidos. Y luego aparecieron… ¡en la biblioteca! Bruno no ha pisado la biblioteca en su vida.
  - **Paso 4.3 · Hablar** con Nico — «Nico (en el pasillo)»
    - **Nico:** ¡Mi taquilla está llena de papelitos! Y cada uno tiene una pregunta: «¿Cuántos huesos tiene el cuerpo humano?»
    - **Nico:** ¿Quién hace una broma con PREGUNTAS DE CIENCIAS? Eso no es una broma, ¡eso es un examen!
- **Paso 5 · Varios objetivos (en cualquier orden)** — «Busca pistas»
  - _Lugar:_ Conserjería · _En escena:_ Ramón
  - **Paso 5.1 · Usar** — «Una nota en la taquilla de Nico»
    - 🖐 _Al usar «Nota en la taquilla de Nico»:_
      - _Narrador:_ _Una nota doblada en cuatro: «Doscientos seis. Pero nadie me lo ha preguntado nunca»._
      - _Narrador:_ _Doscientos seis: los huesos del cuerpo humano. Y la letra es perfecta, pequeñita, ordenada._
  - **Paso 5.2 · Usar** — «Los guantes aparecieron en la biblioteca»
    - 🖐 _Al usar «Los guantes de Álex»:_
      - _Narrador:_ _Los guantes estaban en la mesa del rincón de ciencias de la biblioteca. Al lado, un libro abierto: «Datos curiosos del universo»._
  - **Paso 5.3 · Usar** — «El registro de salidas de Lucía»
    - 🖐 _Al usar «Registro de salidas al baño»:_
      - _Narrador:_ _El registro de Lucía: quién sale al baño y a qué hora._
      - _Narrador:_ _Lunes, 11:05 — Iker. Martes, 11:10 — Iker. Miércoles, 11:04 — Iker. Justo a la hora de cada broma._
  - **Paso 5.4 · Hablar** con Ramón — «Las «cámaras» de Ramón (conserjería)»
    - **Ramón:** ¿Cámaras? En este colegio no hay cámaras, [tu nombre]. Hay algo mejor: Omar.
    - **Ramón:** Me regala sus dibujos del pasillo. Mira este: alguien con gafas junto a la taquilla de Nico. De espaldas.
- **Paso 6 · Escena**
  - _Narrador:_ _Repasas lo que sabes:_
  - _(si tienes la marca «pista letra»)_ _Narrador:_ _· La letra es perfecta, ordenada. Bruno escribe como un pollo._
  - _(si tienes la marca «pista biblioteca»)_ _Narrador:_ _· Los guantes aparecieron en la biblioteca, junto a un libro de datos curiosos._
  - _(si tienes la marca «pista preguntas»)_ _Narrador:_ _· Las «bromas» son preguntas de ciencias._
  - _(si tienes la marca «pista horario»)_ _Narrador:_ _· Cada broma coincide con una salida al baño de Iker._
  - _(si tienes la marca «pista gafas»)_ _Narrador:_ _· Omar dibujó a alguien con gafas junto a la taquilla._
  - **Tú:** Ya sé quién ha sido. Creo.
- **Paso 7 · Ir a** Pasillo — «Ve al pasillo: todos los sospechosos están allí»
  - _Lugar:_ Pasillo · _En escena:_ Bruno, Rubén, Omar, Iker
- **Paso 8 · Decisión** — «¿Quién hizo las bromas? Habla con quien acuses»
  - ➤ **Opción «Bruno»** (con Bruno) _(efecto: decisión «culpable» = Bruno; Bruno -6; marca «acusaste a bruno»)_
    - **Tú:** Has sido tú, Bruno.
    - **Bruno:** ¡¿VES?! ¡Todos igual! ¡Por una vez que no hago nada!
    - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Pensaba que tú eras diferente. Después de lo del otro día…
    - _Narrador:_ _Bruno se cruza de brazos. No, no encaja: su letra, la biblioteca, las preguntas… Piensa otra vez._
  - ➤ **Opción «Rubén»** (con Rubén) _(efecto: decisión «culpable» = Ruben; Rubén -4)_
    - **Rubén:** ¿Yo? Mis bromas son buenas. Esto de las preguntas de ciencias es… rarísimo. No es mi estilo.
    - _Narrador:_ _Tiene razón: Rubén esconde cosas, no deja preguntas. Piensa otra vez._
  - ➤ **Opción «Omar»** (con Omar) _(efecto: decisión «culpable» = Omar; Omar -2; humor +1)_
    - **Omar:** ¿Yo? Si yo dibujé al culpable. ¿Me dibujé a mí mismo de espaldas? Eso sería arte muy moderno.
    - _Narrador:_ _No. Omar no lleva gafas. Piensa otra vez._
  - ➤ **Opción «Iker»** (con Iker) _(efecto: decisión «culpable» = Iker; curiosidad +2)_
    - **Tú:** Iker. Fuiste tú.
    - **Iker:** …
    - **Iker:** ¿Cómo lo has sabido?
- **Paso 9 · Escena**
  - **Iker:** Vale. Fui yo. Pero no para hacer daño.
  - **Iker:** Me paso el día contando datos curiosos y nadie me escucha. «Ya está Iker con sus cosas».
  - **Iker:** Pensé que si ponía los datos en las bromas… por fin alguien los leería. Doscientos seis huesos. Nadie lo sabía.
  - **Iker:** Y fue más fácil que todos pensaran que era Bruno. Eso… eso estuvo mal.
  - **Bruno:** Pues sí. Muy mal.
  - ❓ **Pregunta al jugador:** ¿Qué haces con Iker?
    - ➤ «Vente con nosotros. A mí sí me gustan tus datos.» _(efecto: Iker +15; empatia +2; decisión «iker final» = Grupo; marca «iker en el grupo»)_
      - **Iker:** ¿En serio? …Dato curioso: es la primera vez que alguien me invita a algo.
    - ➤ «Tienes que pedir perdón tú mismo, a Vega, a Álex y a Nico.» _(efecto: Álex +3; Iker +6; Nico +3; Vega +3; responsabilidad +1; decisión «iker final» = Perdon)_
      - **Iker:** Tienes razón. Lo haré. Y a Bruno también.
    - ➤ «Esto se lo tiene que contar Lucía.» _(efecto: Iker -3; Profe Lucía +3; responsabilidad +2; decisión «iker final» = Lucia)_
      - **Iker:** …Vale. Es lo justo.
- **Paso 10 · Escena**
  - _En escena:_ Iker, Profe Lucía, Bruno
  - **Profe Lucía:** Bien hecho, [tu nombre]. Con pruebas y sin prisas. Así se hace.
  - **Profe Lucía:** Toma: una lupa de detective. Era mía cuando tenía tu edad. Estudié en este mismo colegio, ¿sabes?
  - _(si NO tienes la marca «acusaste a bruno»)_ **Bruno:** …Gracias por no culparme. Otra vez.
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Me acusaste sin pruebas. Que lo sepas: me acuerdo.
  - _(si tienes la marca «acusaste a bruno»)_ **Iker:** Dato curioso para terminar: un detective de verdad se equivoca muchas veces antes de acertar. Tú solo… algunas.

**Al terminar (momento de la biografía):** «Resolviste el misterio de las bromas»

---

### Cole06_Examen · «El examen imposible»

**Resumen:** Mañana hay examen de Matemáticas. «El más difícil del trimestre», dice Lucía. Tienes un día.

_Tipo: Historia · Estudios · Edad: 8-9 años · Duración: 20-25 min_

**Requisitos:** has terminado «La venganza de la mochila» y has vivido el 30 % de la etapa

**Lo que puede cambiar:** Aprobado con esfuerzo · Sobresaliente · Suspenso → Recuperación

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Al día siguiente…»
  - ⏳ _Pantalla de transición:_ «Al día siguiente…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 3 · Escena**
  - _En escena:_ Profe Lucía, Nico, Sara
  - **Profe Lucía:** Atención. Mañana hay examen de Matemáticas. Sumas, restas, multiplicaciones y problemas.
  - **Profe Lucía:** No os voy a mentir: es el examen más difícil del trimestre.
  - **Nico:** ¿MAÑANA? ¡Pero si mañana hay partido en la tele!
  - **Sara:** Yo ya he empezado a repasar. Hace tres semanas.
  - **Profe Lucía:** En la biblioteca hay apuntes. Marisa os los presta. Y estudiar con alguien ayuda más de lo que creéis.
- **Paso 4 · Ir a** Biblioteca del cole — «Ve a la biblioteca a por los apuntes»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Marisa, Sara, Iker, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 5 · Hablar** con Marisa — «Pregunta a Marisa, la bibliotecaria»
  - **Marisa:** (susurrando) Hola, cielo. ¿Vienes por los apuntes de Matemáticas? Todo el mundo viene hoy por lo mismo.
  - **Marisa:** Están en la mesa grande. Te los apunto a tu nombre. Me los devuelves después del examen, ¿trato?
  - **Marisa:** Y un consejo: no estudies con el estómago vacío. Los números se pegan mejor con un bocadillo.
- **Paso 6 · Usar** — «Coge los apuntes de la mesa»
  - 🖐 _Al usar «Apuntes de Matemáticas»:_
    - _Narrador:_ _Los apuntes están llenos de dibujitos en los márgenes. Alguien de otro curso los usó antes… y dibujaba fatal._
- **Paso 7 · Decisión** — «¿Con quién estudias? (habla con quien elijas o siéntate sin nadie)»
  - ➤ **Opción «Con Sara»** (con Sara) _(efecto: decisión «companero estudio» = Sara; Sara +5)_
    - **Sara:** ¡Genial! Tengo un plan: cuarenta minutos de ejercicios, cinco de descanso, y repetir. Sin excusas.
    - **Tú:** ¿Cuarenta minutos seguidos?
    - **Sara:** Vale, veinte. Pero concentración total.
  - ➤ **Opción «Con Iker»** (con Iker) _(efecto: decisión «companero estudio» = Iker; Iker +5)_
    - **Iker:** ¿Conmigo? ¡Nadie estudia nunca conmigo! Dato curioso: explicar algo a otro es la mejor forma de aprenderlo.
    - **Iker:** Bueno, ¿empezamos por las tablas? Tengo un truco para la del nueve con los dedos.
  - ➤ **Opción «Con Mateo»** (con Mateo) _(efecto: decisión «companero estudio» = Mateo; Mateo +5)_
    - **Mateo:** ¿Estudiamos juntos? Menos mal. Yo estoy… un poquito muy nervioso.
    - **Tú:** ¿Has estudiado?
    - **Mateo:** Más o menos.
    - **Tú:** Eso significa que no.
    - **Mateo:** Exacto. Por eso te necesito.
  - ➤ **Opción «Sin nadie»** _(efecto: decisión «companero estudio» = Solo; responsabilidad +1)_
    - _Narrador:_ _Te sientas en una mesa libre, junto a la ventana. Silencio. Solo tú y los números._
- **Paso 8 · Clase** — «Estudia en la biblioteca»
- **Paso 9 · Escena**
  - _(si en «companero estudio» elegiste «Sara»)_ **Sara:** Bien. Si mañana repasas otra vez en casa, el examen es tuyo.
  - _(si en «companero estudio» elegiste «Iker»)_ **Iker:** Oye… gracias. Ha sido la mejor tarde en la biblioteca. Y eso que vengo todas.
  - _(si en «companero estudio» elegiste «Mateo»)_ **Mateo:** ¡Ya me sé la del nueve! Mañana… a lo mejor no suspendo. A lo mejor.
  - _(si en «companero estudio» elegiste «Solo»)_ _Narrador:_ _Recoges tus cosas. La cabeza te echa un poco de humo, pero de humo bueno._
- **Paso 10 · Transición (pasa el tiempo)** — «Esa noche, en casa…»
  - ⏳ _Pantalla de transición:_ «Esa noche, en casa…»
- **Paso 11 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** Te veo con cara de examen. ¿Mañana es el gordo?
  - ❓ **Pregunta al jugador:** ¿Qué haces esta noche?
    - ➤ «Repasar un poco más antes de dormir» _(efecto: responsabilidad +1; marca «estudiaste mas»)_
      - **Mamá/Papá:** Así me gusta. Pero a las diez, a la cama, que un cerebro cansado no suma bien.
    - ➤ «Pedir ayuda a Abu» _(efecto: Abu +5; marca «estudiaste mas»)_
      - **Abu:** ¿Matemáticas? En mis tiempos contábamos con garbanzos. Trae, que te enseño un truco de cuando vendía fruta en el mercado.
    - ➤ «Ver el partido. Ya he estudiado bastante.» _(efecto: humor +1)_
      - **Mamá/Papá:** Bueno… tú sabrás. Pero mañana no me digas que no te avisé.
- **Paso 12 · Clase** — «Repasa un poco más» _(solo si tienes la marca «estudiaste mas»)_
- **Paso 13 · Transición (pasa el tiempo)** — «El día del examen…»
  - ⏳ _Pantalla de transición:_ «El día del examen…»
- **Paso 14 · Ir a** Aula de 1.º A — «Ve a clase: hoy es el examen»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 15 · Escena**
  - _Lugar:_ Pizarra
  - _Narrador:_ _Hoja en blanco. Lápiz afilado. El reloj de la pared hace un ruido que antes nunca habías oído._
  - **Profe Lucía:** Tenéis tiempo. Leed bien cada pregunta. Y respirad.
  - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _Anoche repasaste. Te sientes con más calma: tendrás un poco más de tiempo para pensar._
- **Paso 16 · Clase** — «El examen de Matemáticas»
  - _Lugar:_ Aula de 1.º A
- **Paso 17 · Cinemática** _(solo si tu última nota es 5 o más)_
  - _En escena:_ Profe Lucía, Sara (si en «companero estudio» elegiste «Sara»), Iker (si en «companero estudio» elegiste «Iker»), Mateo (si en «companero estudio» elegiste «Mateo»)
  - 🎬 **Cinemática «Cole06_LaNota»** _(música: → Resolucion)_
    - _En escena:_ Profe Lucía, Sara, Iker, Mateo
    - _Cámara:_ 1 planos (Hombro)
    - **Profe Lucía:** Ya tengo las notas. Silencio, que muerdo. _[plano Medio de Profe Lucía · silencio 1.2 s]_
    - **Profe Lucía:** [tu nombre]… _[plano PrimerPlano de Profe Lucía · en la pausa: Mirar · silencio 0.6 s]_
    - _(si NO se cumple: tu última nota es 9 o más)_ **Profe Lucía:** Aprobado. Y se nota el trabajo. _[plano Inserto de Tú · silencio 0.8 s]_
    - _(si tu última nota es 9 o más)_ _(o bien)_ **Profe Lucía:** Un sobresaliente. Estoy muy impresionada. De verdad. _[plano Inserto de Tú · silencio 0.8 s]_
    - _(si tienes la marca «estudiaste mas»)_ **Profe Lucía:** Y anoche repasaste, ¿a que sí? Se nota en los problemas. _[plano Reaccion de Profe Lucía · gesto Happy]_
    - _(si en «companero estudio» elegiste «Sara»)_ **Sara:** ¡Lo sabía! El plan de los veinte minutos funciona. _[plano PrimerPlano de Sara · en la pausa: Cheer]_
    - _(si en «companero estudio» elegiste «Mateo»)_ _(o bien)_ **Mateo:** ¡He aprobado yo también! ¡Por los pelos, pero aprobado! _[plano PrimerPlano de Mateo · en la pausa: Cheer]_
    - _(si en «companero estudio» elegiste «Iker»)_ _(o bien)_ **Iker:** Dato curioso: estudiar acompañado mejora la nota. Acabamos de demostrarlo. _[plano PrimerPlano de Iker]_
    - _(si en «companero estudio» elegiste «Solo»)_ _(o bien)_ **Tú:** Sin nadie. Solo yo y los números. Y esta vez… he ganado yo.
- **Paso 18 · Escena** _(solo si tu última nota es menor que 5)_
  - _Lugar:_ Pizarra · _En escena:_ Profe Lucía
  - **Profe Lucía:** [tu nombre], ven un momento. _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** Esta vez no ha salido. _[plano PrimerPlano de Profe Lucía · en la pausa: Suspira · silencio 0.8 s]_
  - **Profe Lucía:** Pero un examen no dice quién eres: dice lo que te falta por practicar.
  - _(si tienes la marca «estudiaste»)_ **Profe Lucía:** Y sé que estudiaste. Por eso me fastidia más que a ti. _[gesto Sad]_
  - **Profe Lucía:** Esta tarde hago clases de repaso. Si vienes, te doy otra oportunidad. ¿Trato? _[en la pausa: Sonrie]_
  - **Tú:** …Trato. _[plano Reaccion de Profe Lucía · silencio 1.0 s]_
- **Paso 19 · Ir a** Biblioteca del cole — «Devuelve los apuntes a Marisa»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Marisa
- **Paso 20 · Hablar** con Marisa — «Devuélvele los apuntes»
  - _Lugar:_ Mostrador de la biblioteca
  - **Marisa:** ¡Los apuntes! Enteros y sin manchas de chocolate. Te acabas de ganar un sitio en mi lista de favoritos. No se lo digas a nadie.

**Al terminar (momento de la biografía):** «Tu primer examen de verdad»

---

### Nino_Recados · «Recados por el barrio»

**Resumen:** Tu familia confía en ti: te pide que compres el material del cole y unas medicinas, y que vuelvas a casa.

**Requisitos:** has terminado «El examen imposible» y has vivido el 36 % de la etapa

**Pasos:**

- **Paso 1 · Acción del jugador** — «Compra el material del colegio en la librería»
  - _Lugar:_ la librería
- **Paso 2 · Acción del jugador** — «Tu familia necesita medicinas: cómpralas en la farmacia»
  - _Lugar:_ la farmacia
- **Paso 3 · Ir a** tu casa familiar — «Vuelve a tu casa familiar con todo»

**Al terminar (momento de la biografía):** «Has hecho tus primeros recados sin ayuda.»

---

### Cole07_Excursion · «La excursión»

**Resumen:** ¡Excursión a la Granja escuela de Villaverde! Autobús, animales, campo… y un susto.

_Tipo: Historia · Episodio especial · Edad: 9-9 años · Duración: 25-35 min_

**Requisitos:** has terminado «Recados por el barrio» y has vivido el 44 % de la etapa

**Lo que puede cambiar:** Te sientas con… · Encuentras a Mateo (u Omar) · Avisas a Lucía o le traes tú

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Semanas después, un día muy esperado…»
  - ⏳ _Pantalla de transición:_ «Semanas después, un día muy esperado…»
- **Paso 2 · Ir a** Autobús escolar — «Ve al autobús de la excursión (en la puerta del cole)»
  - _Lugar:_ Autobús escolar · _En escena:_ Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno
  - 💬 _Comentario al pasar cerca de Bruno:_ «¡Yo me pido la última fila!»
- **Paso 3 · Escena**
  - **Profe Lucía:** ¡Todos arriba! Contad cuántos sois en vuestra fila. Y nadie se deja nada en el autobús, ¿de acuerdo?
  - **Nico:** ¡[tu nombre]! ¡Aquí hay sitio!
  - **Sara:** Yo tengo la ventana. Puedo compartir la ventana. A ratos.
  - _Narrador:_ _Busca con quién sentarte._
- **Paso 4 · Decisión** — «¿Con quién te sientas en el autobús? (habla con quien elijas)»
  - ➤ **Opción «Con Nico»** (con Nico) _(efecto: decisión «asiento bus» = Nico; Nico +5)_
    - **Nico:** ¡Bien! Tengo un juego: el que vea más vacas gana. Yo llevo… una. Esa. ¡Dos!
  - ➤ **Opción «Con Sara»** (con Sara) _(efecto: decisión «asiento bus» = Sara; Sara +5)_
    - **Sara:** He traído una lista de todas las plantas que vamos a ver. Y una lupa. Bueno, la tuya no, la mía.
  - ➤ **Opción «Con Omar»** (con Omar) _(efecto: decisión «asiento bus» = Omar; Omar +5)_
    - **Omar:** Te guardé el sitio. Y te guardé medio bocadillo. Bueno… un cuarto. Tenía hambre.
  - ➤ **Opción «Con Mateo»** (con Mateo) _(efecto: decisión «asiento bus» = Mateo; Mateo +5)_
    - **Mateo:** Nunca he ido de excursión. En mi otro cole no íbamos. Estoy… contento. Y un poco nervioso.
  - ➤ **Opción «Con Hugo»** (con Hugo) _(efecto: decisión «asiento bus» = Hugo; Hugo +6)_
    - **Hugo:** ¿Conmigo? Antes siempre me sentaba donde decía Bruno. Esto está mejor. Mira, te leo un trozo del libro.
- **Paso 5 · Escena**
  - _Narrador:_ _El autobús sale de Valmar. Carreteras, campos, un tractor que os adelanta (¡os adelanta un tractor!)._
  - **Omar:** Ya me he comido el bocadillo. Estamos en el primer kilómetro.
  - **Sara:** Técnicamente, en el kilómetro cero coma ocho.
  - _(si en «asiento bus» elegiste «Nico»)_ **Nico:** ¡VACA! ¡Siete! ¡Voy ganando!
  - _(si en «asiento bus» elegiste «Mateo»)_ **Mateo:** … _[gesto Happy · en la pausa: Sonrie]_
  - **Profe Lucía:** ¡Ya llegamos! Villaverde, la Granja escuela. Recordad: los animales no son juguetes.
- **Paso 6 · Cinemática**
  - 🎬 **Cinemática «Cole07_Viaje»** _(vuelo de cámara, 9 s, 2 planos; música: TemaValmar)_
    - 🪧 _Rótulo:_ «Granja escuela de Villaverde» — ¡Día de excursión!
- **Paso 7 · Escena**
  - _Lugar:_ las granjas de Villaverde · _En escena:_ Paula, Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno
  - 💬 _Comentario al pasar cerca de Bruno:_ «Huele a vaca. Me encanta. No se lo digáis a nadie.»
  - **Paula:** ¡Bienvenidos a la Granja escuela! Soy Paula. Aquí tenemos gallinas, caballos, un huerto, un tractor…
  - **Paula:** …y una norma de oro: nadie se separa del grupo. El campo es muy grande y todo se parece.
  - **Paula:** Podéis ir a ver lo que queráis de la granja, pero siempre a la vista. ¡Adelante!
  - **Bruno:** Huele a caca de vaca.
  - **Paula:** Huele a campo, jovencito. Y son caballos.
- **Paso 8 · Varios objetivos (en cualquier orden)** — «Descubre la granja»
  - **Paso 8.1 · Usar** — «Dar de comer a las gallinas»
    - 🖐 _Al usar «Las gallinas»:_
      - **Paula:** Estas son Clotilde, Petra y la Señora Bigotes. No, no tiene bigotes. Se lo pusimos por fastidiar.
      - **Paula:** Toma grano. Échalo cerca, no encima. Las gallinas son muy educadas si tú lo eres.
  - **Paso 8.2 · Usar** — «Coger zanahorias en el huerto»
    - 🖐 _Al usar «El huerto»:_
      - _Narrador:_ _Tiras de una hoja verde… y sale una zanahoria ENORME. Toda la clase aplaude._
      - **Sara:** Técnicamente, es una raíz. Pero es una raíz impresionante.
  - **Paso 8.3 · Usar** — «Acariciar a los caballos»
    - 🖐 _Al usar «Los caballos»:_
      - _Narrador:_ _El caballo te mira con sus ojos grandes y te sopla en la mano. Hace cosquillas._
      - **Omar:** Lo voy a dibujar. Tiene cara de llamarse Galleta.
  - **Paso 8.4 · Usar** — «Subirte al tractor»
    - 🖐 _Al usar «El tractor»:_
      - **Julián:** ¿Quieres subir? Venga, arriba. Las manos en el volante. ¡Brrrrum! Sin arrancar, ¿eh?
      - **Nico:** ¡Hazme una foto! ¡Hazme una foto!
- **Paso 9 · Minijuego** — «Echa el grano a las gallinas»
  - 🎮 _Cómo se juega:_ Suelta el grano cuando la aguja esté en verde
- **Paso 10 · Escena**
  - _En escena:_ Paula, Profe Lucía, Julián, Nico (te acompaña), Sara (te acompaña), Omar (si tienes la marca «ayudaste a mateo») (te acompaña)
  - **Profe Lucía:** A ver… ¿estamos todos? Uno, dos, tres…
  - _(si tienes la marca «ayudaste a mateo»)_ **Profe Lucía:** Falta Mateo. ¿Alguien ha visto a Mateo?
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Profe Lucía:** Falta Omar. ¿Alguien ha visto a Omar?
  - **Paula:** Tranquilidad. Suele pasar: alguien ve algo bonito y se despista. Buscamos por la granja.
  - **Profe Lucía:** [tu nombre], tú y tus amigos, mirad por la zona del granero y del silo. Sin alejaros de la granja.
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Busca pistas por la granja»
  - **Paso 11.1 · Usar** — «Una mochila en la hierba»
    - 🖐 _Al usar «Una mochila en la hierba»:_
      - _(si tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Una mochila en la hierba. Llena de cromos. Es la de Mateo._
      - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Una mochila en la hierba. Dentro, un cuaderno de dibujo y migas de bocadillo. Es la de Omar._
  - **Paso 11.2 · Usar** — «Una botella junto al silo»
    - 🖐 _Al usar «Una botella de agua»:_
      - _Narrador:_ _Una botella medio vacía junto al silo. Y huellas pequeñas… y otras más pequeñas todavía, de pezuñas._
  - **Paso 11.3 · Usar** — «Un papel junto al granero»
    - 🖐 _Al usar «Un mapa dibujado»:_
      - _Narrador:_ _Un papel con un dibujo: el granero, una flecha y un animalito blanco. Pone: «¡Le sigo!»._
  - **Paso 11.4 · Hablar** con Julián — «Pregunta a Julián, el granjero (junto al silo)»
    - **Julián:** ¿Un chaval? Sí, hace un rato. Iba detrás de Copito, el corderito que siempre se escapa.
    - **Julián:** Copito siempre acaba detrás del granero, donde crece la hierba buena. Mirad allí.
- **Paso 12 · Ir a** Granero — «Busca detrás del granero»
  - _Lugar:_ Granero · _En escena:_ Paula, Profe Lucía, Nico (te acompaña), Sara (te acompaña), Mateo (si tienes la marca «ayudaste a mateo»), Omar (si NO tienes la marca «ayudaste a mateo»)
- **Paso 13 · Escena**
  - _En escena:_ Mateo (si tienes la marca «ayudaste a mateo»), Omar (si NO tienes la marca «ayudaste a mateo»), Nico (te acompaña), Sara (te acompaña)
  - _Narrador:_ _Detrás del granero, sentado en la hierba, con un corderito blanco en el regazo._
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** ¡[tu nombre]! Se había escapado y… y lo seguí. Y luego no sabía volver. Todo se parece.
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Omar:** ¡[tu nombre]! Lo estaba dibujando y se movió, y lo seguí para terminar el dibujo. Y luego… no sabía volver.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Le das la mano y volvéis juntos» _(efecto: Mateo +8; Omar +8; empatia +1; decisión «rescate» = Juntos)_
      - _Narrador:_ _Volvéis juntos. Copito os sigue un rato, como si quisiera ir de excursión también._
    - ➤ «Te quedas con él y mandas a Nico a avisar a Lucía» _(efecto: Profe Lucía +3; Mateo +5; Omar +5; responsabilidad +1; decisión «rescate» = Avisar)_
      - **Nico:** ¡Voy corriendo! ¡Soy el más rápido! ¡Bueno, casi!
- **Paso 14 · Escena**
  - _Lugar:_ las granjas de Villaverde · _En escena:_ Paula, Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno
  - **Profe Lucía:** ¡Aquí estáis! Menudo susto. Buen trabajo, equipo. Buen trabajo de verdad.
  - **Paula:** Y Copito, a su corral. Que eres un fugitivo profesional.
  - **Profe Lucía:** ¡Foto de grupo antes de volver! Todos delante del granero. Bruno, sin cuernos con los dedos.
- **Paso 15 · Cinemática**
  - 🎬 **Cinemática «Cole07_Foto»** _(vuelo de cámara, 7 s, 1 planos; música: efecto Momento)_
    - 🪧 _Rótulo:_ «📸 ¡Todos a decir «vaca»!» — La excursión a Villaverde
- **Paso 16 · Escena**
  - _Narrador:_ _En el autobús de vuelta, medio autobús se queda dormido. Omar ronca. Sara lo apunta._
  - **Andrés:** ¡Atención, deportistas! Cuando volvamos… ¡empieza el torneo del colegio! Fútbol, baloncesto y atletismo.
  - **Nico:** ¿TORNEO? ¡Estoy despierto! ¡ESTOY DESPIERTO!

**Al terminar (momento de la biografía):** «La excursión a la granja»

---

### Cole08_Torneo · «El torneo»

**Resumen:** Empieza el torneo del colegio. Elige tu deporte, entrena con tu equipo… y llega a la final.

_Tipo: Historia · Deporte · Edad: 9-9 años · Duración: 20-30 min_

**Requisitos:** has terminado «La excursión» y has vivido el 54 % de la etapa

**Lo que puede cambiar:** Fútbol, baloncesto o atletismo · Capitán o no · Oro o plata · Cómo ganas o pierdes

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «El lunes siguiente…»
  - ⏳ _Pantalla de transición:_ «El lunes siguiente…»
- **Paso 2 · Ir a** la pista de deporte — «Ve a la pista: Andrés reúne a toda la clase»
  - _Lugar:_ la pista de deporte · _En escena:_ Andrés, Nico, Álex, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén
  - 💬 _Comentario al pasar cerca de Nico:_ «¡Fútbol! ¡Aquí! ¡FÚTBOL!»
  - 💬 _Comentario al pasar cerca de Álex:_ «Baloncesto. Sin gritar. Con estilo.»
  - 💬 _Comentario al pasar cerca de Sara:_ «Atletismo: ciencia aplicada a correr.»
  - 💬 _Comentario al pasar cerca de Bruno:_ «Da igual el deporte. Os vamos a ganar en todos.»
- **Paso 3 · Escena**
  - **Andrés:** ¡Atención, deportistas! Empieza el torneo de primavera del colegio. Tres deportes: fútbol, baloncesto y atletismo.
  - **Andrés:** Cada uno elige UNO. Entrenamos esta semana, y el viernes: clasificación contra 4.º B y, si pasáis… la final.
  - **Bruno:** La final es nuestra. Siempre es nuestra.
  - **Andrés:** Bruno, la final es de quien juegue mejor. Y de quien juegue limpio. Venga: id con vuestro capitán de deporte.
  - **Omar:** Yo voy a donde vaya [tu nombre]. Soy malo en los tres deportes por igual. Es un talento.
- **Paso 4 · Decisión** — «¿A qué deporte te apuntas? (habla con quien elijas)»
  - ➤ **Opción «Fútbol, con Nico»** (con Nico) _(efecto: decisión «deporte» = Futbol; Nico +5)_
    - **Nico:** ¡SÍ! ¡Lo sabía! Tú y yo, en el mismo equipo. Otra vez. Como el primer partido.
    - **Nico:** Y esta vez vamos a entrenar. Bueno, esta vez vamos a entrenar MÁS.
  - ➤ **Opción «Baloncesto, con Álex»** (con Álex) _(efecto: decisión «deporte» = Baloncesto; Álex +5)_
    - **Álex:** Bien. Me acuerdo de tus canastas en el gimnasio. Tienes muñeca.
    - **Álex:** Regla número uno: no se tira desde el medio del campo. Regla número dos: a veces sí.
  - ➤ **Opción «Atletismo, con Sara»** (con Sara) _(efecto: decisión «deporte» = Atletismo; Sara +5)_
    - **Sara:** Excelente elección. He calculado que si movemos los brazos a la vez que las piernas, corremos un doce por ciento más.
    - **Sara:** Técnicamente todo el mundo lo hace ya. Pero ahora lo haremos A PROPÓSITO.
- **Paso 5 · Ir a** Campo de fútbol — «Ve al campo de fútbol a entrenar» _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 6 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - **Andrés:** Hoy: pases. El fútbol es de todos, no del que más corre. Nico, eso va por ti.
  - **Nico:** ¡Yo paso muchísimo! Cuando me acuerdo.
  - **Omar:** Yo me pongo de portero. Así corro menos y pienso más.
- **Paso 7 · Minijuego** — «Entrenamiento: pases al hueco» _(solo si en «deporte» elegiste «Futbol»)_
  - 🎮 _Cómo se juega:_ Pasa cuando la aguja esté en verde
- **Paso 8 · Ir a** Cancha de baloncesto — «Ve a la cancha a entrenar» _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
- **Paso 9 · Escena** _(solo si en «deporte» elegiste «Baloncesto»)_
  - **Álex:** Tiros libres. Respira, mira el aro, flexiona las rodillas y… suelta. Como si nada.
  - **Omar:** Como si nada. Vale. Lo mío es más bien «como si todo».
- **Paso 10 · Minijuego** — «Entrenamiento: tiros libres» _(solo si en «deporte» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Suelta cuando la aguja esté en verde
- **Paso 11 · Escena** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - **Sara:** El circuito: vallas, saltos, conos y un sprint final. Andrés lo cronometra.
  - **Andrés:** Y la carrera del viernes es un relevo. Así que hoy también aprendéis a pasaros el testigo sin tirarlo.
  - **Omar:** ¿Y si lo tiro?
  - **Sara:** Entonces lo recoges. Muy rápido. Y finges que era parte del plan.
- **Paso 12 · Clase** — «Entrena el circuito de la pista» _(solo si en «deporte» elegiste «Atletismo»)_
- **Paso 13 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol
  - **Andrés:** Buen entrenamiento, equipo. Antes del viernes necesitáis dos cosas: un capitán y un plan.
  - _(si en «deporte» elegiste «Futbol»)_ **Nico:** Yo creo que el capitán debería ser [tu nombre].
  - _(si en «deporte» elegiste «Baloncesto»)_ **Álex:** Yo votaría a [tu nombre]. Pero también me votaría a mí. Decidid.
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Propongo votar. Datos: [tu nombre] tiene buena cabeza. Yo tengo mejor cabeza. Pero [tu nombre] tiene más amigos.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Yo… no he estado nunca en un equipo donde se vota. Me gusta.
  - ❓ **Pregunta al jugador:** ¿Quién es el capitán?
    - ➤ «Yo. Me hace ilusión.» _(efecto: valentia +1; decisión «capitan» = Yo)_
      - **Omar:** ¡Capitán [tu nombre]! Te hago un brazalete con cinta de carrocero.
    - ➤ _(si en «deporte» elegiste «Futbol»)_ «Nico. Nadie tiene más ganas que él.» _(efecto: Nico +8; empatia +1; decisión «capitan» = Otro)_
      - **Nico:** ¿Yo? ¿YO? ¡No os voy a fallar! ¡Voy a llorar! ¡No voy a llorar!
    - ➤ _(si en «deporte» elegiste «Baloncesto»)_ «Álex. Sabe más que nadie.» _(efecto: Álex +8; empatia +1; decisión «capitan» = Otro)_
      - **Álex:** Vale. Primera orden de la capitana: nadie se agobia. Segunda: nadie se agobia.
    - ➤ _(si en «deporte» elegiste «Atletismo»)_ «Sara. Tiene un plan para todo.» _(efecto: Sara +8; empatia +1; decisión «capitan» = Otro)_
      - **Sara:** Acepto. He traído un cuaderno para anotar la estrategia. Lo traía por si acaso. Siempre lo traigo.
    - ➤ «Omar. Hace falta alguien tranquilo.» _(efecto: Omar +10; empatia +1; decisión «capitan» = Omar)_
      - **Omar:** ¿Yo? Nunca me han elegido para nada. Bueno, una vez para borrar la pizarra. Gracias. De verdad.
  - **Andrés:** Y el plan: ¿cómo vais a jugar?
  - ❓ **Pregunta al jugador:** ¿Qué estrategia proponéis?
    - ➤ «Ir a por todas desde el principio» _(efecto: valentia +1; decisión «estrategia» = Ataque)_
      - **Andrés:** Con valentía. Me gusta. Pero guardad aire para el final.
    - ➤ «Paciencia: cansarlos y rematar al final» _(efecto: responsabilidad +1; decisión «estrategia» = Paciencia)_
      - **Andrés:** Con cabeza. Los partidos se ganan en el último minuto.
    - ➤ «Que juegue todo el mundo, aunque perdamos» _(efecto: Hugo +3; Mateo +3; Omar +3; deportividad +1; decisión «estrategia» = Todos)_
      - **Andrés:** Eso, equipo, es lo que yo llamo un equipo. Así da gusto.
- **Paso 14 · Escena** _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
  - _(la misma conversación «Charla» de arriba)_
- **Paso 15 · Escena** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - _(la misma conversación «Charla» de arriba)_
- **Paso 16 · Transición (pasa el tiempo)** — «El día del torneo…»
  - ⏳ _Pantalla de transición:_ «El día del torneo…»
- **Paso 17 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Alumno, Alumna
  - 💬 _Comentario al pasar cerca de Alumno:_ «¡4.º B! ¡4.º B!»
  - **Andrés:** ¡Clasificación! 4.º A contra 4.º B. Los que ganen pasan directos a la final.
  - **Alumno:** ¡Somos más pequeños pero somos MÁS RÁPIDOS!
  - **Omar:** Son pequeñitos. Me dan un poco de miedo. Parecen muy motivados.
- **Paso 18 · Minijuego** — «Clasificación contra 4.º B» _(solo si en «deporte» elegiste «Futbol»)_
- **Paso 19 · Escena** _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
  - _(la misma conversación «Clasificacion» de arriba)_
- **Paso 20 · Minijuego** — «Clasificación contra 4.º B» _(solo si en «deporte» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Cada canasta cuenta. Necesitáis 3.
- **Paso 21 · Escena** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - _(la misma conversación «Clasificacion» de arriba)_
- **Paso 22 · Minijuego** — «Clasificación: ¡la salida!» _(solo si en «deporte» elegiste «Atletismo»)_
  - 🎮 _Cómo se juega:_ Sal justo cuando la aguja esté en verde
- **Paso 23 · Escena**
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés (si en «deporte» elegiste «Futbol»), Nico (si en «deporte» elegiste «Futbol»), Omar (si en «deporte» elegiste «Futbol»), Mateo (si en «deporte» elegiste «Futbol» y tienes la marca «ayudaste a mateo»), Hugo (si en «deporte» elegiste «Futbol» y tienes la marca «hugo con el grupo»), Alumno (si en «deporte» elegiste «Futbol»), Alumna (si en «deporte» elegiste «Futbol»), Andrés (si en «deporte» elegiste «Baloncesto»), Álex (si en «deporte» elegiste «Baloncesto»), Omar (si en «deporte» elegiste «Baloncesto»), Mateo (si en «deporte» elegiste «Baloncesto» y tienes la marca «ayudaste a mateo»), Hugo (si en «deporte» elegiste «Baloncesto» y tienes la marca «hugo con el grupo»), Alumno (si en «deporte» elegiste «Baloncesto»), Alumna (si en «deporte» elegiste «Baloncesto»), Andrés (si en «deporte» elegiste «Atletismo»), Sara (si en «deporte» elegiste «Atletismo»), Omar (si en «deporte» elegiste «Atletismo»), Mateo (si en «deporte» elegiste «Atletismo» y tienes la marca «ayudaste a mateo»), Hugo (si en «deporte» elegiste «Atletismo» y tienes la marca «hugo con el grupo»), Alumno (si en «deporte» elegiste «Atletismo»), Alumna (si en «deporte» elegiste «Atletismo»)
  - _(si tienes la marca «clasificacion ganada»)_ **Andrés:** ¡Ganáis la clasificación! Directos a la final.
  - _(si NO tienes la marca «clasificacion ganada»)_ **Andrés:** 4.º B gana… ¡pero pasáis como mejor segundo! Estáis en la final por los pelos.
  - _(si tienes la marca «clasificacion ganada»)_ **Alumno:** Buen partido. El año que viene os ganamos. Bueno, este también casi.
  - **Andrés:** Descanso de veinte minutos. Y la final es contra… cómo no: el equipo de Bruno.
- **Paso 24 · Ir a** la pista de deporte — «Descanso: ve a la grada de la pista»
  - _Lugar:_ la pista de deporte · _En escena:_ Mamá/Papá, Abu, Omar, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén
- **Paso 25 · Varios objetivos (en cualquier orden)** — «Aprovecha el descanso»
  - 🖐 _Al usar «La fuente de la pista»:_
    - _Narrador:_ _Agua fresquita. Respiras hondo. Desde aquí se oye a tu familia animando. Y a Omar, que anima más fuerte._
  - **Paso 25.1 · Hablar** con Mamá/Papá — «Saluda a mamá/papá en la grada»
    - **Mamá/Papá:** ¡[tu nombre]! ¡Hemos venido todos! Bueno, estamos Abu y yo, que es como todos.
    - **Mamá/Papá:** Ganes o pierdas, esta noche hay cena especial. Aunque si ganas, con postre doble.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Me tiemblan las piernas. ¿Y si fallo?» _(efecto: empatia +1)_
        - **Mamá/Papá:** Entonces fallas, y lo vuelves a intentar. Así se hace todo en la vida. Todo.
      - ➤ «¡Vamos a ganar!» _(efecto: valentia +1)_
        - **Mamá/Papá:** ¡Esa es la actitud! Yo gritaré tanto que me quedaré sin voz.
  - **Paso 25.2 · Hablar** con Abu — «Habla con Abu»
    - **Abu:** Yo jugué una final a tu edad. Perdimos por un gol. ¿Sabes qué recuerdo? El bocadillo de después con mis amigos.
    - **Abu:** Del resultado casi no me acuerdo. De los amigos, de todos. Disfrútalo, cariño.
  - **Paso 25.3 · Usar** — «Bebe agua en la fuente»
    - 🖐 _Al usar «La fuente de la pista»:__(la misma conversación «Beber» de arriba)_
- **Paso 26 · Hablar** con Bruno — «Bruno te está mirando. Habla con él»
  - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Oye. Lo del otro día… gracias por hablar conmigo en vez de ir contándolo por ahí.
  - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Pero hoy os gano igual. Que una cosa no quita la otra.
  - _(si tienes la marca «acusaste a bruno» y NO tienes la marca «bruno hablaste con el»)_ **Bruno:** Mira, el detective. Hoy no hay nada que investigar: solo vais a perder.
  - _(si NO tienes las marcas «bruno hablaste con el» y «acusaste a bruno»)_ **Bruno:** ¿Vosotros en la final? Qué valor.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Bruno. Juego con ellos. Y ya está. No pasa nada.
  - _(si tienes la marca «hugo con el grupo»)_ **Bruno:** …Ya. Ya lo sé. Pues suerte. Pero poca.
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Buena suerte. De verdad. _[en la pausa: Aparta]_
  - ❓ **Pregunta al jugador:** ¿Qué le contestas a Bruno?
    - ➤ «Que gane el mejor. Y que sea divertido.» _(efecto: Bruno +4; deportividad +2; decisión «pre final» = Deportivo)_
      - **Bruno:** …Vale. Que sea divertido. Pero que gane yo.
    - ➤ «Ya veremos en el campo.» _(efecto: valentia +1; decisión «pre final» = Reto)_
      - **Bruno:** Ya veremos. Eso digo yo.
    - ➤ «No le contestas. Vuelves con tu equipo.» _(efecto: decisión «pre final» = Nada)_
      - _Narrador:_ _Bruno se queda con la frase a medias. Tu equipo te está esperando._
- **Paso 27 · Cinemática** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén, Mamá/Papá, Abu
  - 🎬 **Cinemática «Cole08_Final»** _(música: → Tension)_
    - _En escena:_ Andrés, Mamá/Papá, Abu, Bruno, Rubén, Omar, Nico, Álex, Sara, Mateo, Hugo
    - _Cámara:_ 1 planos (General)
    - **Andrés:** ¡LA FINAL! 4.º A contra… 4.º A. El equipo de [tu nombre] contra el equipo de Bruno. _[plano Medio de Andrés · silencio 1.6 s]_
    - **Mamá/Papá:** ¡VAMOS, [tu nombre]! _[plano Reaccion de Mamá/Papá · en la pausa: Cheer]_
    - _(si en «pre final» elegiste «Deportivo»)_ **Bruno:** Que sea divertido, dijiste. Vale. Pero que gane yo. _[plano Hombro de Tú → Bruno]_
    - _(si en «pre final» elegiste «Reto»)_ _(o bien)_ **Bruno:** «Ya veremos en el campo». Pues ya estamos en el campo. _[plano Hombro de Tú → Bruno]_
    - _(si en «pre final» elegiste «Nada»)_ _(o bien)_ **Bruno:** ¿Tampoco me vas a contestar ahora? Vale. Ya hablará el marcador. _[plano Hombro de Tú → Bruno]_
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Delantero»)_ **Nico:** Tú arriba, de delantero, como en el primer partido. Yo te la paso. Esta vez sí. _[plano PrimerPlano de Nico]_
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Defensa»)_ _(o bien)_ **Nico:** Tú atrás, de defensa, como en el primer partido. Que no pase ni el aire. _[plano PrimerPlano de Nico]_
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Portero»)_ _(o bien)_ **Nico:** Tú en la portería, como en el primer partido. Eres un muro. Un muro con guantes. _[plano PrimerPlano de Nico]_
    - _(si en «capitan» elegiste «Yo»)_ **Omar:** Capitán, unas palabras. _[plano Reaccion de Omar]_
    - _(si en «capitan» elegiste «Omar»)_ _(o bien)_ **Omar:** Soy el capitán. Unas palabras: ¡a por ellos! Con cariño. _[plano PrimerPlano de Omar]_
    - _(si en «capitan» elegiste «Otro» y en «deporte» elegiste «Futbol»)_ _(o bien)_ **Nico:** ¡Equipo! ¡No os voy a fallar! ¡Voy a llorar! ¡No voy a llorar! _[plano PrimerPlano de Nico]_
    - _(si en «capitan» elegiste «Otro» y en «deporte» elegiste «Baloncesto»)_ _(o bien)_ **Álex:** Primera orden de la capitana: nadie se agobia. Segunda: nadie se agobia. _[plano PrimerPlano de Álex]_
    - _(si en «capitan» elegiste «Otro» y en «deporte» elegiste «Atletismo»)_ _(o bien)_ **Sara:** Plan: salir rápido, pasar el testigo y no tropezar. Técnicamente, fácil. _[plano PrimerPlano de Sara]_
    - _(si en «capitan» elegiste «Yo»)_ **Tú:** Jugad como sabemos. Y pasadlo bien. Lo demás… ya vendrá.
    - _(si tienes la marca «buen entreno»)_ **Andrés:** Habéis entrenado bien. Se va a notar. _[plano Medio de Andrés]_
    - _(si en «estrategia» elegiste «Ataque»)_ **Andrés:** Recordad el plan: a por todas… pero guardad aire para el final. _[plano Medio de Andrés]_
    - _(si en «estrategia» elegiste «Paciencia»)_ _(o bien)_ **Andrés:** Recordad el plan: paciencia. Los partidos se ganan en el último minuto. _[plano Medio de Andrés]_
    - _(si en «estrategia» elegiste «Todos»)_ _(o bien)_ **Andrés:** Recordad el plan: aquí juega todo el mundo. Así da gusto. _[plano Medio de Andrés]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Omar:** ¡Por Los Imparables! _[plano General de Omar · en la pausa: Cheer]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Omar:** ¡Por La Patrulla Valmar! _[plano General de Omar · en la pausa: Cheer]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Omar:** ¡Por Los del Banco Azul! _[plano General de Omar · en la pausa: Cheer]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Omar:** ¡Por Los Dinosaurios! _[plano General de Omar · en la pausa: Cheer]_
    - **Andrés:** ¡Y a disfrutar! _[plano General de Andrés · en la pausa: Point]_
- **Paso 28 · Minijuego** — «¡LA FINAL! Contra el equipo de Bruno» _(solo si en «deporte» elegiste «Futbol»)_
- **Paso 29 · Cinemática** _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
  - 🎬 **Cinemática «Cole08_Final»** _(la misma de antes, ver arriba)_
- **Paso 30 · Minijuego** — «¡LA FINAL! Contra el equipo de Bruno» _(solo si en «deporte» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Cada vez más difícil. Necesitáis 4 canastas.
- **Paso 31 · Cinemática** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - 🎬 **Cinemática «Cole08_Final»** _(la misma de antes, ver arriba)_
- **Paso 32 · Minijuego** — «¡LA FINAL! El relevo contra el equipo de Bruno» _(solo si en «deporte» elegiste «Atletismo»)_
  - 🎮 _Cómo se juega:_ Pasa el testigo en la zona verde. ¡No lo sueltes!
- **Paso 33 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol
  - _(si tienes la marca «torneo ganado»)_ **Andrés:** ¡Final! ¡Gana el equipo de [tu nombre]! ¡CAMPEONES DEL TORNEO! _[plano Medio de Andrés · gesto Cheer]_
  - _(si tienes la marca «torneo perdido»)_ **Andrés:** ¡Final! Gana el equipo de Bruno… ¡pero qué final! Subcampeones, y con la cabeza bien alta. _[plano Medio de Andrés]_
  - _(si tienes la marca «torneo ganado»)_ **Mamá/Papá:** ¡¡ESE ES MI [tu nombre]!! _[plano Reaccion de Mamá/Papá · gesto Cheer]_
  - _(si tienes la marca «torneo perdido»)_ **Mamá/Papá:** ¡Muy bien jugado, [tu nombre]! ¡Muy bien! _[plano Reaccion de Mamá/Papá · gesto Clap]_
  - _(si tienes la marca «torneo ganado»)_ **Bruno:** …Bien jugado. De verdad. Lo odio, pero bien jugado. _[plano PrimerPlano de Bruno · en la pausa: Aparta · silencio 0.6 s]_
  - _(si tienes la marca «torneo perdido»)_ **Bruno:** ¡Lo sabía! …Aunque ha estado muy cerca. Muy cerca. Casi me da algo. _[plano PrimerPlano de Bruno · gesto Cheer]_
  - ❓ **Pregunta al jugador:** ¿Qué haces ahora?
    - ➤ «Dar la mano a todo el equipo de Bruno» _(efecto: Bruno +5; Rubén +3; deportividad +2; decisión «tras final» = Mano)_
      - _(si tienes la marca «torneo ganado»)_ **Bruno:** ¿La mano? Vale. Toma. Pero no se lo cuentes a nadie. Es broma. Cuéntaselo.
      - _(si tienes la marca «torneo perdido»)_ **Bruno:** ¿Me das la mano después de perder? Tú eres de otro planeta. Vale. Toma. Buen partido.
    - ➤ «Celebrarlo (o consolaros) con tu equipo, todos juntos» _(efecto: Álex +2; Nico +2; Omar +3; Sara +2; empatia +1; decisión «tras final» = Equipo)_
      - **Omar:** ¡Abrazo de grupo! ¡Todos! ¡Tú también, Andrés!
      - **Andrés:** …Venga, vale. Un abrazo rápido.
    - ➤ «Irte a un rincón sin hablar con nadie» _(efecto: deportividad +-1; decisión «tras final» = Rincon)_
      - _(si tienes la marca «torneo perdido»)_ _Narrador:_ _Te sientas en un rincón un rato. Omar se sienta a tu lado sin decir nada. A veces eso es lo que hace falta._
      - _(si tienes la marca «torneo ganado»)_ _Narrador:_ _Te apartas un momento. Ha sido tanto que necesitas respirar. Omar te trae agua sin decir nada._
- **Paso 34 · Escena** _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
  - _(la misma conversación «Resultado» de arriba)_
- **Paso 35 · Escena** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - _(la misma conversación «Resultado» de arriba)_
- **Paso 36 · Ir a** la pista de deporte — «Ve a la pista: ¡entrega de medallas!»
  - _En escena:_ Andrés, Nico, Álex, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén
- **Paso 37 · Cinemática**
  - _En escena:_ Andrés, Nico, Álex, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén, Mamá/Papá, Abu
  - 🎬 **Cinemática «Cole08_Medallas»** _(música: → Resolucion)_
    - _En escena:_ Andrés, Mamá/Papá, Abu, Bruno, Rubén, Omar, Nico, Álex, Sara, Mateo, Hugo
    - _Cámara:_ 2 planos (General, Inserto)
    - **Andrés:** Y ahora… ¡las medallas! Primero, los subcampeones. _[plano Medio de Andrés · silencio 1.4 s]_
    - _(si tienes la marca «torneo perdido»)_ **Andrés:** Plata para el equipo de [tu nombre]. Y brilla más que muchas de oro, te lo digo yo. _[plano Hombro de Tú → Andrés · silencio 0.6 s]_
    - _(si tienes la marca «torneo ganado»)_ _(o bien)_ **Andrés:** Y el oro… para el equipo de [tu nombre]. Pesa, ¿eh? Es la emoción. _[plano Hombro de Tú → Andrés · silencio 0.6 s]_
    - **Mamá/Papá:** ¡Mirad! ¡Es [tu nombre]! ¡Es de mi familia! _[plano Reaccion de Mamá/Papá · en la pausa: Cheer]_
    - **Abu:** Ay… que se me ha metido algo en el ojo. En los dos. Qué cosas. _[plano PPP de Abu · ademán Clap · en la pausa: Respirar · silencio 0.8 s]_
    - _(si en «tras final» elegiste «Mano»)_ **Bruno:** Lo de darme la mano… ha estado bien. No te acostumbres. _[plano Reaccion de Bruno]_
    - _(si en «tras final» elegiste «Rincon»)_ _(o bien)_ **Omar:** ¿Estás mejor? Te he guardado agua. Y medio bocadillo, que es lo que más quiero. _[plano Reaccion de Omar]_
    - _(si en «tras final» elegiste «Equipo»)_ _(o bien)_ **Omar:** ¡Otra foto de equipo! ¡Esta para la nevera de cada uno! _[plano General de Omar · en la pausa: Cheer]_
    - _(si tu rasgo deportividad es 4 o más)_ **Andrés:** Un último premio: el de deportividad del torneo. Es para… [tu nombre]. Por cómo has jugado. Y por cómo has tratado a todos. _[plano Medio de Andrés]_
- **Paso 38 · Escena**
  - _En escena:_ Omar (te acompaña), Sara (te acompaña), Nico (te acompaña)
  - **Omar:** Oye… ¿habéis oído lo que dicen los de sexto?
  - **Sara:** ¿Lo de la puerta del fondo del pasillo? Esa que siempre está cerrada con un candado.
  - **Nico:** ¡Dicen que dentro hay un fantasma! O un tesoro. O un fantasma con un tesoro.
  - **Sara:** Los fantasmas no existen. Los tesoros… a veces.

**Al terminar (momento de la biografía):** «Tu primer torneo»

---

### Cole09_Misterio · «El misterio del colegio»

**Resumen:** Al fondo del pasillo hay una puerta que nunca se abre. Y en tu taquilla, una nota: «NO ENTRES».

_Tipo: Historia · Misterio · Edad: 9-9 años · Duración: 25-35 min_

**Requisitos:** has terminado «El torneo» y has vivido el 62 % de la etapa

**Lo que puede cambiar:** Permiso o a escondidas · Devolver la foto, enseñarla o guardar el secreto · Qué metes en la cápsula

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unos días después del torneo…»
  - ⏳ _Pantalla de transición:_ «Unos días después del torneo…»
- **Paso 2 · Ir a** el patio — «Sal al recreo: tus amigos no hablan de otra cosa»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Iker (si tienes la marca «iker en el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 3 · Escena**
  - **Nico:** Es un FANTASMA. Un fantasma de un niño que se quedó castigado para siempre. Por eso está cerrada.
  - **Sara:** Los fantasmas no existen. Es un laboratorio secreto. De química. Probablemente con explosiones.
  - **Omar:** Yo creo que es donde guardan los bocadillos que se deja la gente. Una sala entera de bocadillos.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Según mis datos, esa puerta lleva cerrada desde antes de que naciéramos. Nadie tiene la llave. Nadie.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** En mi otro cole también había una sala así. Era el cuarto de la fregona. Pero esta parece más misteriosa.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** En un libro que leí, detrás de una puerta así había un pasadizo al otro lado del mundo.
  - **Omar:** Bueno, voy a por mi almuerzo a la taquilla. Tanto misterio me da hambre. [tu nombre], ¿vienes?
- **Paso 4 · Usar** — «Vuelve a tu taquilla (en el pasillo) a por el almuerzo»
  - _En escena:_ Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - 🖐 _Al usar «Tu taquilla»:_
    - _Narrador:_ _Abres la taquilla. Tu almuerzo sigue ahí. Pero detrás, encajado en una rendija de la chapa, hay un papel amarillento._
    - _Narrador:_ _Está escrito con rotulador gordo, con letra de niño: «NO ENTRES EN LA SALA DEL FONDO. ES NUESTRA. — L.»_
    - _Narrador:_ _Y más abajo, más pequeño: «Si de verdad quieres entrar: el año en que 4.º A ganó… y la llave que nadie toca.»_
- **Paso 5 · Escena**
  - **Omar:** ¿«NO ENTRES»? Ahora TENGO que entrar. Es como cuando dicen «no mires». Miras.
  - **Sara:** El papel es viejísimo. Mira qué amarillo. Esto lleva ahí muchos años.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Tengo una libreta nueva. La he llamado «Caso: la sala del fondo».
  - **Sara:** Necesitamos pistas: el año, la llave… y saber quién es «L.». Vamos a investigar.
- **Paso 6 · Varios objetivos (en cualquier orden)** — «Investiga el misterio»
  - _Lugar:_ Mostrador de la biblioteca · _En escena:_ Marisa, Ramón, Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - **Paso 6.1 · Usar** — «El anuario viejo de la biblioteca»
    - 🖐 _Al usar «El anuario de 1998»:_
      - **Marisa:** ¿El anuario de 1998? Qué curioso: nadie lo ha pedido en años. Toma, con cuidado, que tiene más años que tú.
      - _Narrador:_ _Página de 4.º A, curso 1998. Hay una foto de toda la clase… pero la han arrancado. Solo queda la esquina._
      - _Narrador:_ _Debajo pone: «4.º A, ¡campeones del concurso de ciencias!». Y una lista de nombres. Uno está rodeado con un corazón: «Lucía»._
      - **Sara:** ¿Lucía? ¿Una Lucía de 1998? ¿Qué edad tendrá ahora Lucía? …No. No puede ser.
  - **Paso 6.2 · Usar** — «El tablero de llaves de la conserjería»
    - 🖐 _Al usar «El tablero de llaves»:_
      - **Ramón:** ¿Las llaves? Aquí están todas: gimnasio, comedor, biblioteca… Cada una con su número.
      - _Narrador:_ _Hay un gancho con una llave pequeñita y oxidada. El número 13. Tiene un lazo amarillo atado._
      - **Ramón:** Esa no se toca. La 13 no la he usado nunca. Me la dio una niña hace muchos años y me hizo prometer que la guardaría.
      - **Ramón:** Y yo las promesas las cumplo. Aunque las haga una niña de nueve años con un jersey amarillo.
  - **Paso 6.3 · Usar** — «Algo brilla en el almacén del gimnasio»
    - 🖐 _Al usar «Un trofeo viejo»:_
      - _Narrador:_ _Entre balones pinchados y conos, un trofeo lleno de polvo. Le soplas. ¡Achís!_
      - _Narrador:_ _La placa dice: «1.er premio Concurso de Ciencias · 4.º A · 1998». Tiene pegada una pegatina amarilla._
      - **Omar:** 4.º A ganó en 1998. Ese es el año, ¿no? ¡El año en que 4.º A ganó!
  - **Paso 6.4 · Usar** — «La puerta del fondo del pasillo»
    - 🖐 _Al usar «La puerta del fondo»:_
      - _Narrador:_ _La puerta del fondo del pasillo. Madera vieja, un candado de seis ruedas de números._
      - _Narrador:_ _Grabado en el marco, muy pequeñito: «Sala de 4.º A. Promoción 1998. ¡Prohibido a los mayores!»_
      - **Sara:** Seis números. El año tiene cuatro. Faltan dos… como el número de una llave.
- **Paso 7 · Escena**
  - _En escena:_ Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - **Sara:** A ver, recapitulemos. El año en que 4.º A ganó: 1998. La llave que nadie toca: la 13.
  - **Omar:** Y «L.» es una niña de jersey amarillo que le hizo prometer cosas a Ramón. Esto es mejor que una serie.
  - **Sara:** Ahora hay que abrir la puerta. Y hay dos formas: pedir permiso a Ramón… o entrar en el recreo, cuando no mira nadie.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Estadísticamente, a los que se cuelan los pillan el ochenta por ciento de las veces.
- **Paso 8 · Decisión** — «¿Pides permiso a Ramón (conserjería) o te cuelas en el recreo (la puerta)?»
  - _En escena:_ Marisa, Ramón, Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - ➤ **Opción «Pedir permiso a Ramón»** (con Ramón) _(efecto: decisión «entrar» = Permiso; Ramón +6; responsabilidad +1)_
    - **Ramón:** ¿Que queréis abrir la sala del fondo? Vaya, vaya. Por fin alguien.
    - **Ramón:** Os doy permiso con una condición: el candado lo abrís vosotros. Si sabéis el código, es que os lo habéis ganado.
    - **Ramón:** Y yo voy detrás, que la sala tiene muchos años y el suelo cruje.
  - ➤ **Opción «Colarte en el recreo»** _(efecto: decisión «entrar» = Colarse; valentia +1)_
    - _Narrador:_ _Recreo. El pasillo está vacío. Solo se oye el reloj y, a lo lejos, a Nico gritando «¡GOL!»._
    - **Omar:** (susurrando) Si nos pillan, yo solo pasaba por aquí. Buscando… un bocadillo.
- **Paso 9 · Ir a** La puerta del fondo del pasillo — «Ve a la puerta del fondo del pasillo»
  - _Lugar:_ La puerta del fondo del pasillo · _En escena:_ Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»), Ramón (si en «entrar» elegiste «Permiso»)
- **Paso 10 · Decisión** — «El candado tiene seis ruedas de números. ¿Qué código pruebas?»
  - ➤ **Opción «1 3 1 9 9 8»** _(efecto: decisión «candado» = 131998)_
    - _Narrador:_ _Clic… clac. Nada. El candado no se abre._
    - **Sara:** Espera. La nota decía primero el año y DESPUÉS la llave. Lo has puesto al revés.
  - ➤ **Opción «1 9 9 8 1 3»** _(efecto: decisión «candado» = 199813; curiosidad +2)_
    - _Narrador:_ _1… 9… 9… 8… 1… 3. ¡CLAC! El candado se abre. La puerta cruje muy despacio._
    - **Nico:** Si sale un fantasma, yo me quedo detrás de Omar.
    - **Omar:** Y yo detrás de [tu nombre].
  - ➤ **Opción «1 9 9 8 0 0»** _(efecto: decisión «candado» = 199800)_
    - _Narrador:_ _Clic… clac. Nada._
    - **Omar:** El año está bien, creo. Pero ¿y la llave que nadie toca? ¿Qué número tenía?
  - ➤ **Opción «1 2 3 4 5 6»** _(efecto: decisión «candado» = 123456; humor +1)_
    - **Nico:** ¡Pon uno, dos, tres, cuatro, cinco, seis! ¡Nadie cambia la contraseña que viene de fábrica!
    - _Narrador:_ _Clic… clac. Nada._
    - **Sara:** Nico. Por favor.
- **Paso 11 · Escena**
  - _Lugar:_ La sala cerrada
  - _Narrador:_ _Polvo, luz entrando por una ventana alta, y… pupitres. Pupitres viejos de madera, como de otra época._
  - _Narrador:_ _Hay dibujos en las paredes, una estantería con trofeos y una caja de lata en una mesa._
  - **Sara:** No es un laboratorio. Es… un aula. Un aula de hace muchísimos años.
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Esta era el aula de 4.º A antes de la reforma. Nadie la ha vuelto a usar. Bueno… casi nadie.
- **Paso 12 · Varios objetivos (en cualquier orden)** — «Explora la sala»
  - **Paso 12.1 · Usar** — «Un pupitre viejo»
    - 🖐 _Al usar «Un pupitre viejo»:_
      - _Narrador:_ _En la tapa del pupitre alguien grabó con mucho cuidado: «L. estuvo aquí. 1998. Seré profe.»_
      - **Omar:** «Seré profe». Qué niña más decidida.
  - **Paso 12.2 · Usar** — «Una caja de lata»
    - 🖐 _Al usar «Una caja de lata»:_
      - _Narrador:_ _Dentro de la caja hay cartas dobladas, un cromo, una cinta de pelo amarilla y un papel: «CÁPSULA DEL TIEMPO. Abrir en 2008»._
      - **Sara:** ¡2008! Se les olvidó abrirla. Lleva cerrada desde entonces.
  - **Paso 12.3 · Usar** — «La estantería de trofeos»
    - 🖐 _Al usar «Trofeos y medallas»:_
      - _Narrador:_ _Medallas de cartón, un trofeo de «mejor disfraz» y un diploma: «Al grupo más curioso del colegio»._
      - **Nico:** Nosotros tendríamos que tener uno de esos. «Al grupo más… algo».
- **Paso 13 · Usar** — «En la pared hay una foto enmarcada»
- **Paso 14 · Cinemática**
  - 🎬 **Cinemática «Cole09_LaFoto»** _(música: → Descubrimiento)_
    - _En escena:_ Sara, Omar, Nico, Iker, Ramón
    - _Cámara:_ 3 planos (Hombro)
    - **Sara:** Esperad. Esa foto… _[plano Reaccion de Sara · silencio 2.7 s]_
    - _Narrador:_ _4.º A, 1998. Delante de esta misma pizarra._
    - _Narrador:_ _En la primera fila, una niña con jersey amarillo y coletas…_
    - **Sara:** Es… ¡es LUCÍA! ¡Nuestra Lucía! ¡Fue a NUESTRO colegio! _[plano Reaccion de Sara · gesto Surprised]_
    - **Omar:** Lucía con coletas. Esto hay que dibujarlo. Ya. _[plano Reaccion de Omar]_
    - **Nico:** ¡«L.»! ¡L de Lucía! ¡Lo sabía! …Vale, no lo sabía. _[plano Reaccion de Nico · en la pausa: Cheer]_
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** Dato curioso: acabamos de resolver un caso de hace más de veinte años. _[plano Reaccion de Iker]_
- **Paso 15 · Escena**
  - _En escena:_ Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»), Ramón
  - **Sara:** Es la foto que falta en el anuario. Hay que enseñársela.
  - _(si en «entrar» elegiste «Colarse»)_ **Ramón:** ¡Ajá! ¡Os pillé! ¿Qué hacéis aquí dentro en el recreo? _[plano Reaccion de Ramón · gesto HandsOnHips]_
  - _(si en «entrar» elegiste «Colarse»)_ **Ramón:** …Ah. Habéis encontrado la foto. Bueno. Esta vez no digo nada. Pero la próxima, se pide permiso.
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Sí. La niña del jersey amarillo. La que me dio la llave 13. _[plano PrimerPlano de Ramón · en la pausa: Piensa]_
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Y ahora es vuestra profe. Qué rápido pasa todo. _[silencio 0.6 s]_
  - **Ramón:** Id a enseñársela. Creo que le va a hacer mucha ilusión. Aunque primero igual se pone roja.
- **Paso 16 · Ir a** Aula de 1.º A — «Busca a Lucía en clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»)
- **Paso 17 · Hablar** con Profe Lucía — «Enséñale la foto a Lucía»
  - **Profe Lucía:** ¿Qué traéis ahí, con esas caras? A ver… _[plano Hombro de Tú → Profe Lucía]_
  - **Profe Lucía:** … _[plano PPP de Profe Lucía · en la pausa: Silencio · silencio 0.6 s]_
  - **Profe Lucía:** ¿De dónde habéis sacado esto? ¡Esa soy yo! ¡Con nueve años! ¡Y esas coletas! _[plano PrimerPlano de Profe Lucía · gesto Surprised]_
  - _(si en «entrar» elegiste «Colarse»)_ **Profe Lucía:** ¿Y cómo habéis entrado? …No. No me lo digáis. Prefiero no saberlo. _[gesto Facepalm]_
  - _(si en «entrar» elegiste «Permiso»)_ **Profe Lucía:** ¿Ramón os ha abierto? Ese hombre guarda los secretos mejor que nadie. _[gesto Happy]_
  - **Profe Lucía:** La nota de la taquilla también era mía. Esa taquilla era mía, ¿sabéis? Escondimos la sala para que nadie encontrara nuestra cápsula.
  - **Profe Lucía:** Y nos olvidamos de abrirla. Nos hicimos mayores y… se nos olvidó. Qué tonta.
  - ❓ **Pregunta al jugador:** ¿Qué haces con la foto?
    - ➤ «Devolvérsela: «Es tuya. Te la hemos traído.»» _(efecto: Profe Lucía +10; empatia +1; decisión «foto lucia» = Devolver)_
      - **Profe Lucía:** Gracias. De verdad. Os voy a hacer una copia a cada uno. Esta la pongo en mi mesa.
    - ➤ «Enseñársela a toda la clase» _(efecto: Profe Lucía +5; Nico +3; humor +1; decisión «foto lucia» = Clase)_
      - **Nico:** ¡ATENCIÓN TODOS! ¡LUCÍA CON COLETAS!
      - **Profe Lucía:** ¡Nico! …Vale, vale. Sí. Era yo. Y era la mejor de la clase en ciencias, que conste.
    - ➤ «Guardar el secreto: «No se lo diremos a nadie»» _(efecto: Profe Lucía +8; responsabilidad +1; decisión «foto lucia» = Secreto; marca «secreto lucia»)_
      - **Profe Lucía:** ¿Un secreto entre nosotros? Me parece perfecto. Tomad una copia cada uno. Y ni una palabra de las coletas.
  - **Profe Lucía:** Tengo una idea. Mañana abrimos juntos la cápsula de mi clase… y vosotros dejáis la vuestra en la sala.
  - **Profe Lucía:** Y la abriremos el último día de colegio. El último de verdad. Os lo prometo. Esta vez no se me olvida.
- **Paso 18 · Decisión** — «¿Qué metes tú en la cápsula del tiempo de la clase?»
  - ➤ **Opción «Una carta para tu «yo» del último día de cole»** _(efecto: decisión «capsula» = Carta; responsabilidad +1)_
  - ➤ **Opción «Un dibujo de tu grupo»** _(efecto: decisión «capsula» = Dibujo; Omar +3; creatividad +1)_
  - ➤ **Opción «Una predicción: «Nico será futbolista»»** _(efecto: decisión «capsula» = Prediccion; Nico +3; humor +1)_
  - ➤ **Opción «Una pregunta para el futuro: «¿Seguimos siendo amigos?»»** _(efecto: decisión «capsula» = Pregunta; Nico +2; Omar +2; Sara +2; empatia +1)_
- **Paso 19 · Escena**
  - _Narrador:_ _Al día siguiente, toda la clase entra en la sala del fondo. Lucía lee en voz alta las cartas de su clase. Se ríe. Se emociona._
  - _Narrador:_ _Después, cada uno mete algo en una caja nueva. Ramón la cierra con el candado. Código nuevo. Secreto._
  - **Profe Lucía:** «Cápsula del tiempo de 4.º A. Abrir el último día de colegio». Hecho.
  - **Omar:** ¿Y si se nos olvida?
  - **Sara:** No se nos va a olvidar. Lo he apuntado en tres sitios.
  - _Narrador:_ _Lucía te da una copia de la foto de 1998. La guardas en la mochila._

**Al terminar (momento de la biografía):** «El secreto de la sala cerrada»

---

### Cole10_Festival · «El festival»

**Resumen:** El festival de primavera del colegio: cada uno tiene una tarea. Y el día del festival, nada sale como estaba previsto.

_Tipo: Historia · Evento del colegio · Edad: 10-10 años · Duración: 30-40 min_

**Requisitos:** has terminado «El misterio del colegio» y has vivido el 72 % de la etapa

**Lo que puede cambiar:** Tu tarea en el festival · Qué imprevistos resuelves · Subir al escenario o animar · Ayudar (o no) a Bruno

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Llega la primavera a Valmar…»
  - ⏳ _Pantalla de transición:_ «Llega la primavera a Valmar…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Marta, Vega, Omar, Sara, Nico, Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 3 · Escena**
  - **Profe Lucía:** ¡Noticia! El viernes que viene celebramos el festival de primavera. Vendrán las familias, habrá puestos, música, teatro…
  - **Marta:** ♪ …y un concurso de talentos ♪ …perdón, lo digo cantando sin querer.
  - **Profe Lucía:** Con lo que se recaude en los puestos compraremos libros nuevos para la biblioteca. Marisa está emocionadísima.
  - **Profe Lucía:** Cada uno elige una tarea. Hablad con quien la organiza: Vega, la decoración; Marta, la música; Omar, la comida; Sara, las fotos.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Y… yo he escrito una obra de teatro. De piratas. Si alguien quiere… no hace falta, ¿eh?
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Según mis datos, el año pasado se vendieron cuarenta y dos magdalenas. Este año podemos batirlo.
- **Paso 4 · Decisión** — «¿De qué te encargas en el festival? (habla con quien lo organiza)»
  - ➤ **Opción «Decoración, con Vega»** (con Vega) _(efecto: decisión «festival» = Decoracion; Vega +5)_
    - **Vega:** ¡Bien! Tengo un plan: banderines rojos, farolillos amarillos y un cartel ENORME. Con purpurina. Mucha purpurina.
  - ➤ **Opción «Música, con Marta»** (con Marta) _(efecto: decisión «festival» = Musica; Marta +5)_
    - **Marta:** ♪ Qué alegría ♪ Tocaremos la canción del festival. Tú llevarás el ritmo. ¿Tienes buen oído? Lo vamos a averiguar.
  - ➤ **Opción «Comida, con Omar»** (con Omar) _(efecto: decisión «festival» = Comida; Omar +5)_
    - **Omar:** SABÍA que vendrías. Magdalenas. Vamos a hacer las mejores magdalenas de la historia. Y a probar muchas. Por control de calidad.
  - ➤ **Opción «Fotos, con Sara»** (con Sara) _(efecto: decisión «festival» = Fotos; Sara +5)_
    - **Sara:** Documentaremos el festival científicamente. Es decir: fotos. Muchas fotos. Con buena luz.
  - ➤ _(si tienes la marca «hugo con el grupo»)_ **Opción «Teatro, con Hugo»** (con Hugo) _(efecto: decisión «festival» = Teatro; Hugo +6)_
    - **Hugo:** ¿De verdad? ¿Quieres hacer la obra conmigo? Se llama «La isla de las mil llaves». Como el libro. Nico hará de loro.
    - **Nico:** ¡Soy un loro con mucha personalidad!
- **Paso 5 · Ir a** el patio — «Ve al patio a decorar con Vega» _(solo si en «festival» elegiste «Decoracion»)_
  - _Lugar:_ el patio · _En escena:_ Vega
- **Paso 6 · Varios objetivos (en cualquier orden)** — «Decora el patio» _(solo si en «festival» elegiste «Decoracion»)_
  - _En escena:_ Vega (te acompaña)
  - **Paso 6.1 · Usar** — «Cuelga la guirnalda de banderines»
    - 🖐 _Al usar «Guirnalda de banderines»:_
      - **Vega:** ¡Más arriba! ¡Un poco a la izquierda! ¡Perfecto! Bueno, casi. Perfecto.
  - **Paso 6.2 · Usar** — «Cuelga los farolillos»
    - 🖐 _Al usar «Farolillos de papel»:_
      - _Narrador:_ _Los farolillos amarillos se balancean con el aire. Con el sol a través parecen de miel._
  - **Paso 6.3 · Usar** — «Pinta el cartel del festival»
    - 🖐 _Al usar «El cartel del festival»:_
      - _Narrador:_ _Pintas «FESTIVAL DE PRIMAVERA» con letras gordas. Vega añade purpurina. Y más purpurina. El patio brilla._
      - **Vega:** Somos un gran equipo. Mira, te has manchado la nariz de purpurina. Te queda bien.
- **Paso 7 · Ir a** el aula de música — «Ve al aula de música a ensayar» _(solo si en «festival» elegiste «Musica»)_
  - _Lugar:_ el aula de música · _En escena:_ Marta
- **Paso 8 · Escena** _(solo si en «festival» elegiste «Musica»)_
  - **Marta:** La canción tiene un ritmo sencillo: pom… pom… pom-pom. Tú llevas el tambor. Escucha y toca en el momento justo.
- **Paso 9 · Minijuego** — «Ensayo: toca a tiempo» _(solo si en «festival» elegiste «Musica»)_
  - 🎮 _Cómo se juega:_ Toca la nota cuando la aguja esté en verde
- **Paso 10 · Ir a** Comedor — «Ve al comedor: Omar te espera con el delantal puesto» _(solo si en «festival» elegiste «Comida»)_
  - _Lugar:_ Comedor · _En escena:_ Omar
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Reúne los ingredientes» _(solo si en «festival» elegiste «Comida»)_
  - **Paso 11.1 · Usar** — «Harina y azúcar»
    - 🖐 _Al usar «Harina y azúcar»:_
      - **Omar:** Harina, azúcar… y un poquito de harina en la cara, que es lo que hacen los cocineros de verdad.
  - **Paso 11.2 · Usar** — «Los huevos (con cuidado)»
    - 🖐 _Al usar «Una caja de huevos»:_
      - **Omar:** Con cuidado… con cuidado… ¡Ninguno roto! Somos unos profesionales.
- **Paso 12 · Minijuego** — «Decora las magdalenas» _(solo si en «festival» elegiste «Comida»)_
  - 🎮 _Cómo se juega:_ Pon la guinda cuando la aguja esté en verde
- **Paso 13 · Varios objetivos (en cualquier orden)** — «Haz las fotos para el mural del festival» _(solo si en «festival» elegiste «Fotos»)_
  - _En escena:_ Sara (te acompaña)
  - **Paso 13.1 · Usar** — «El escenario (patio)»
    - 🖐 _Al usar «El escenario»:_
      - **Sara:** El escenario vacío, antes de la fiesta. Es la foto del «antes». Luego haremos la del «después».
  - **Paso 13.2 · Usar** — «Los columpios (zona de juegos)»
    - 🖐 _Al usar «Los columpios»:_
      - _Narrador:_ _Clic. Un columpio se mueve solo con el viento. Sara dice que es tu mejor foto. Tú también lo crees._
  - **Paso 13.3 · Usar** — «La entrada del cole»
    - 🖐 _Al usar «La entrada del cole»:_
      - **Sara:** La puerta del cole. Por aquí entraste el primer día. Dentro de nada, todo el mundo entrará por aquí a la fiesta.
- **Paso 14 · Ir a** Gimnasio — «Ve al gimnasio a ensayar la obra» _(solo si en «festival» elegiste «Teatro»)_
  - _Lugar:_ Gimnasio · _En escena:_ Hugo, Nico
- **Paso 15 · Escena** _(solo si en «festival» elegiste «Teatro»)_
  - **Hugo:** Tu papel es el de capitán. Solo tienes una frase importante: «¡La llave número mil estaba en nuestro corazón!»
  - **Nico:** ¡Cruac! ¡Cruac! ¿Los loros dicen cruac? ¡Da igual! ¡CRUAC!
  - **Hugo:** Nunca nadie había querido hacer una obra mía. Gracias.
- **Paso 16 · Minijuego** — «Ensayo: di tu frase a tiempo» _(solo si en «festival» elegiste «Teatro»)_
  - 🎮 _Cómo se juega:_ Habla cuando la aguja esté en verde
- **Paso 17 · Transición (pasa el tiempo)** — «El viernes, el día del festival…»
  - ⏳ _Pantalla de transición:_ «El viernes, el día del festival…»
- **Paso 18 · Ir a** el patio — «Ve al patio: ¡empieza el festival!»
  - _Lugar:_ el patio · _En escena:_ Profe Lucía, Marta, Andrés, Mamá/Papá, Abu, Ramón, Nico, Sara, Omar, Vega, Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Alumna, Alumno
  - 💬 _Comentario al pasar cerca de Bruno:_ «¡Limonada! ¡La mejor limonada de Valmar! …¿Nadie?»
- **Paso 19 · Escena**
  - _Narrador:_ _El patio está lleno: puestos, globos, música, familias. Huele a magdalenas y a limonada._
  - **Mamá/Papá:** ¡[tu nombre]! ¡Qué bonito está todo! ¿Esto lo habéis hecho vosotros?
  - **Abu:** En mis tiempos el festival era una mesa con galletas. Esto es como una feria.
  - **Profe Lucía:** ¡Bienvenidos todos al festival de primavera!
  - _Narrador:_ _Y justo entonces… sopla un viento fuertísimo. Se oye un «¡Ay!» y un «¡Mis farolillos!». Y el altavoz hace «¡PFFFZZ!»._
  - **Profe Lucía:** ¡[tu nombre]! ¿Puedes echar una mano? Pasan cosas por todas partes.
- **Paso 20 · Varios objetivos (en cualquier orden)** — «¡Imprevistos! Resuelve al menos tres»
  - **Paso 20.1 · Usar** — «El viento se lleva los farolillos»
    - 🖐 _Al usar «¡Los farolillos se vuelan!»:_
      - _Narrador:_ _Saltas y agarras la cuerda justo a tiempo. Vega la ata a la farola con un nudo doble._
      - **Vega:** ¡Me has salvado los farolillos! Esto se merece purpurina extra.
  - **Paso 20.2 · Hablar** con Ramón — «El altavoz no suena: avisa a Ramón»
    - **Ramón:** ¿Que no suena? A ver… ¡claro! Alguien ha desenchufado el cable para cargar un móvil.
    - **Ramón:** Listo. Buen aviso. Treinta años de conserje y el problema siempre es un cable.
  - **Paso 20.3 · Hablar** con Alumna — «Una niña de 1.º llora junto a la valla»
    - **Alumna:** (llorando) No encuentro a mi mamá… Había mucha gente y… y ahora no la veo.
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Te agachas y le das la mano: «La buscamos juntos»» _(efecto: empatia +2; decisión «nina perdida» = Juntos)_
        - _Narrador:_ _Dais una vuelta por el patio. Enseguida aparece su madre, que la estaba buscando por la otra puerta._
        - **Alumna:** ¡Gracias! Cuando sea mayor quiero ser como tú.
      - ➤ «La llevas con Lucía, que sabe qué hacer» _(efecto: Profe Lucía +3; responsabilidad +2; decisión «nina perdida» = Lucia)_
        - **Profe Lucía:** Bien hecho. Lo anuncio por el altavoz… ¡que ya funciona! Y su madre llega corriendo en un minuto.
  - **Paso 20.4 · Hablar** con Bruno — «Al puesto de limonada de Bruno no va nadie»
    - **Bruno:** ¿Qué miras? Ya sé que no viene nadie. La limonada está buenísima. Pero nadie se acerca a mi puesto.
    - **Rubén:** Es que Bruno grita «¡COMPRAD!» y la gente se asusta. _[en la pausa: Aparta]_
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Le ayudas: «Déjame a mí, sonríe y ofrece probarla gratis»» _(efecto: Bruno +8; Rubén +4; empatia +1; decisión «festival bruno» = Ayudar)_
        - _Narrador:_ _Pruebas gratis, sonrisas… En cinco minutos hay cola en el puesto de Bruno._
        - **Bruno:** …Vale. Ha funcionado. No te lo voy a agradecer en voz alta. …Gracias. En voz baja.
      - ➤ «Le compras un vaso y le dices que está buena» _(efecto: Bruno +4; decisión «festival bruno» = Comprar)_
        - **Bruno:** ¿A que sí? ¡A que está buena! …Ya van dos vasos. Uno era mío, pero cuenta.
      - ➤ «Le dejas con su puesto: tienes otras cosas que hacer» _(efecto: decisión «festival bruno» = Nada)_
        - **Bruno:** Ya. Como todos.
- **Paso 21 · Escena**
  - _(si en «festival» elegiste «Decoracion»)_ **Mamá/Papá:** ¿Los banderines y el cartel los habéis hecho vosotros? ¡Hasta brillan!
  - _(si en «festival» elegiste «Musica»)_ _Narrador:_ _Suena la canción del festival. Tú llevas el tambor: pom… pom… pom-pom. Nadie se equivoca. Bueno, casi nadie._
  - _(si en «festival» elegiste «Comida»)_ **Omar:** ¡Las magdalenas se han acabado en veinte minutos! ¡Récord! Iker lo ha apuntado.
  - _(si en «festival» elegiste «Fotos»)_ **Sara:** Nuestro mural de fotos está lleno de gente mirándolo. Las del «antes» y las del «después»: ¡funciona!
  - _(si en «festival» elegiste «Teatro»)_ _Narrador:_ _La obra de Hugo arranca aplausos. Tú dices tu frase: «¡La llave número mil estaba en nuestro corazón!». Nico hace de loro con demasiada energía._
  - _(si tienes la marca «tarea brillante»)_ **Profe Lucía:** Lo habéis hecho de maravilla. Se nota que habéis ensayado.
  - _(si NO tienes la marca «tarea brillante»)_ **Profe Lucía:** No todo ha salido perfecto… pero así son las fiestas de verdad. ¡A todos les ha encantado!
- **Paso 22 · Escena**
  - **Marta:** ♪ Y ahora… ¡el concurso de talentos! ♪ ¿Quién se atreve a subir al escenario?
  - **Omar:** Yo no. Mi talento es comer magdalenas y ya lo he demostrado.
  - ❓ **Pregunta al jugador:** ¿Subes al escenario?
    - ➤ «Subo a cantar la canción del festival» _(efecto: decisión «talento» = Cantar; marca «subes al escenario»)_
      - **Marta:** ♪ ¡Qué valiente! ♪ Yo te acompaño con el piano.
    - ➤ «Subo a contar chistes con Nico» _(efecto: Nico +4; decisión «talento» = Chistes; marca «subes al escenario»)_
      - **Nico:** ¿Por qué el libro de mates está triste? ¡Porque tiene muchos problemas! …¡Ríete, [tu nombre], que es tu turno!
    - ➤ «Me quedo abajo animando a los demás» _(efecto: empatia +1; decisión «talento» = Animar)_
      - _(si tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Aplaudes más fuerte que nadie. Mateo sube a hacer un truco de magia y te busca con la mirada. Le sonríes. Le sale perfecto._
      - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Aplaudes más fuerte que nadie. Cada vez que alguien se pone nervioso en el escenario, te busca con la mirada y le sonríes._
- **Paso 23 · Minijuego** — «¡Tu número en el escenario!» _(solo si tienes la marca «subes al escenario»)_
  - 🎮 _Cómo se juega:_ Sigue el ritmo: pulsa en la zona verde
- **Paso 24 · Escena**
  - _(si tienes la marca «aplauso final»)_ _Narrador:_ _El público se pone en pie. Tu familia aplaude y Abu silba con dos dedos. Nadie sabía que sabía hacer eso._
  - _(si tienes la marca «subes al escenario» y NO tienes la marca «aplauso final»)_ _Narrador:_ _Te tiembla la voz a mitad de número… y el público aplaude más fuerte para ayudarte. Acabas riéndote. Todos se ríen contigo._
  - **Profe Lucía:** ¡Gracias a todos! Con lo recaudado, la biblioteca tendrá libros nuevos. Y creo que alguno será de piratas.
  - _(si en «festival bruno» elegiste «Ayudar»)_ **Bruno:** El puesto de limonada ha recaudado más que el de magdalenas. …Casi. Gracias a [tu nombre].
  - **Mamá/Papá:** Qué día tan bonito. Me he hecho una foto con todo tu grupo. Esta va a la nevera.
- **Paso 25 · Cinemática**
  - 🎬 **Cinemática «Cole10_Festival»** _(vuelo de cámara, 8 s, 2 planos; música: efecto Momento)_
    - 🪧 _Rótulo:_ «🎉 ¡Qué festival!» — El festival de primavera

**Al terminar (momento de la biografía):** «El festival de primavera»

---

### Cole11_Proyecto · «El proyecto final»

**Resumen:** El último proyecto de Ciencias de primaria: «Un invento para mejorar Valmar». Se presenta delante de las familias.

_Tipo: Historia · Estudios · Edad: 10-10 años · Duración: 25-35 min_

**Requisitos:** has terminado «El festival» y has vivido el 82 % de la etapa

**Lo que puede cambiar:** Compañero, tema y rol · Cómo resolvéis la discusión · Qué hacéis con el desastre · La nota (y el periódico)

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Las últimas semanas de primaria…»
  - ⏳ _Pantalla de transición:_ «Las últimas semanas de primaria…»
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Omar, Sara, Nico, Iker (si tienes la marca «iker en el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 3 · Clase** — «Clase de Ciencias»
- **Paso 4 · Escena**
  - **Profe Lucía:** Último proyecto de primaria. El tema: «Un invento para mejorar Valmar». Equipos de tres.
  - **Profe Lucía:** Tenéis que investigar, construir una maqueta y presentarla. Y lo presentaréis… delante de las familias.
  - **Nico:** ¿Delante de las FAMILIAS? ¿Con mi abuela? Mi abuela se ríe de TODO.
  - **Omar:** [tu nombre], tú y yo en el mismo equipo. No es una pregunta. Bueno, sí es una pregunta. ¿Vale?
  - **Profe Lucía:** Perfecto. Ahora os falta el tercero.
- **Paso 5 · Decisión** — «Omar ya está en tu equipo. ¿Quién es el tercero? (habla con quien elijas)»
  - ➤ **Opción «Sara»** (con Sara) _(efecto: decisión «companero» = Sara; Sara +5)_
    - **Sara:** Acepto. Tengo tres cuadernos de ideas. Uno se titula «Ideas que no le he contado a nadie». Hoy lo abrimos.
  - ➤ **Opción «Nico»** (con Nico) _(efecto: decisión «companero» = Nico; Nico +5)_
    - **Nico:** ¡Sí! ¡Vamos a hacer algo que explote! …De forma segura. Lucía me está mirando.
  - ➤ _(si tienes la marca «iker en el grupo»)_ **Opción «Iker»** (con Iker) _(efecto: decisión «companero» = Iker; Iker +5)_
    - **Iker:** Acepto. Yo me encargo de los datos. Los datos convencen a los jurados. Lo he leído.
  - ➤ _(si tienes la marca «ayudaste a mateo»)_ **Opción «Mateo»** (con Mateo) _(efecto: decisión «companero» = Mateo; Mateo +5)_
    - **Mateo:** ¿Yo? Vale. Se me dan bien los dibujos técnicos. Mi padre es fontanero y me enseña.
  - ➤ _(si tienes la marca «hugo con el grupo»)_ **Opción «Hugo»** (con Hugo) _(efecto: decisión «companero» = Hugo; Hugo +5)_
    - **Hugo:** ¡Sí! He leído muchos libros de inventores. La mitad eran de piratas inventores, pero cuenta.
- **Paso 6 · Escena**
  - _En escena:_ Omar, Sara (si en «companero» elegiste «Sara»), Nico (si en «companero» elegiste «Nico»), Iker (si en «companero» elegiste «Iker»), Mateo (si en «companero» elegiste «Mateo»), Hugo (si en «companero» elegiste «Hugo»)
  - **Omar:** Bueno, equipo. ¿Qué inventamos?
  - ❓ **Pregunta al jugador:** ¿Cuál es vuestro invento?
    - ➤ «Un huerto en el patio del cole» _(efecto: responsabilidad +1; decisión «tema» = Huerto)_
      - **Omar:** Tomates del cole. Lechugas del cole. Ensalada del cole. Me gusta todo de esta idea.
    - ➤ «Un robot que recoge basura del parque» _(efecto: curiosidad +1; decisión «tema» = Robot)_
      - **Omar:** Un robot. ¿Le podemos poner nombre? Se llama Bocadillo. No hay más que hablar.
    - ➤ «Un tablón para encontrar mascotas perdidas» _(efecto: empatia +1; decisión «tema» = Mascotas)_
      - **Omar:** Como Bigotes, el gato del cole. Seguro que Bigotes lo aprobaría. Con un maullido.
    - ➤ _(si tienes la marca «capsula del tiempo»)_ «Un museo del colegio con la sala cerrada» _(efecto: Profe Lucía +3; creatividad +1; decisión «tema» = Museo)_
      - **Omar:** ¡Con la foto de Lucía! Bueno… si Lucía quiere. Le preguntamos primero.
  - ❓ **Pregunta al jugador:** ¿Qué haces tú en el equipo?
    - ➤ «Organizo: alguien tiene que llevar el calendario» _(efecto: responsabilidad +1; decisión «rol» = Lider)_
      - **Omar:** Jefe o jefa de proyecto. Te hago una chapa. De cartón, que es lo que hay.
    - ➤ «Investigo: buscar datos es lo mío» _(efecto: curiosidad +1; decisión «rol» = Investigador)_
      - **Omar:** Tú buscas, yo te acompaño y traigo galletas. Es un sistema perfecto.
    - ➤ «Construyo la maqueta» _(efecto: creatividad +1; decisión «rol» = Constructor)_
      - **Omar:** Manos de artista. Yo te paso el pegamento. Sin comérmelo.
    - ➤ «Presento delante de todos» _(efecto: valentia +1; decisión «rol» = Presentador)_
      - **Omar:** ¿Delante de las familias? Qué valor. Yo me pongo al lado y sujeto la maqueta con cara seria.
- **Paso 7 · Varios objetivos (en cualquier orden)** — «Investiga para el proyecto (tres fuentes)»
  - _Lugar:_ Mostrador de la biblioteca · _En escena:_ Marisa, Ramón, Abu, Omar (te acompaña), Sara (si en «companero» elegiste «Sara») (te acompaña), Nico (si en «companero» elegiste «Nico») (te acompaña), Iker (si en «companero» elegiste «Iker») (te acompaña), Mateo (si en «companero» elegiste «Mateo») (te acompaña), Hugo (si en «companero» elegiste «Hugo») (te acompaña)
  - **Paso 7.1 · Usar** — «Libros de inventos (biblioteca)»
    - 🖐 _Al usar «Libros de inventos»:_
      - **Marisa:** ¿Inventos? Estantería azul, arriba. Y el de las ideas locas, abajo: es el que más se presta.
      - _(si en «tema» elegiste «Huerto»)_ _Narrador:_ _Un huerto escolar da comida para veinte familias al año. Hay colegios con gallinas. Omar lee eso dos veces._
      - _(si en «tema» elegiste «Robot»)_ _Narrador:_ _Hay robots de cartón que funcionan con un motor pequeño y una pinza. Solo hace falta paciencia._
      - _(si en «tema» elegiste «Mascotas»)_ _Narrador:_ _La mayoría de mascotas perdidas aparece a menos de tres calles de casa. Un buen tablón ayuda mucho._
      - _(si en «tema» elegiste «Museo»)_ _Narrador:_ _Un museo pequeño puede ser una vitrina y una historia bien contada. Marisa te enseña el anuario de 1998 otra vez._
  - **Paso 7.2 · Hablar** con Ramón — «Entrevista a Ramón (conserjería)»
    - **Ramón:** ¿Una entrevista? ¿A mí? Espera, que me peino.
    - _(si en «tema» elegiste «Huerto»)_ **Ramón:** En el patio hay un rincón con sol todo el día. Allí crecía un limonero cuando yo empecé. Buen sitio para un huerto.
    - _(si en «tema» elegiste «Robot»)_ **Ramón:** Cada lunes recojo del parque una bolsa entera de papeles. Si vuestro robot me ayuda, os invito a un zumo.
    - _(si en «tema» elegiste «Mascotas»)_ **Ramón:** Yo encontré a Bigotes en una caja, bajo la lluvia. Si hubiera tenido un tablón, habría encontrado a su familia.
    - _(si en «tema» elegiste «Museo»)_ **Ramón:** Tengo en la conserjería cosas de todas las épocas del cole. Un museo… me haría mucha ilusión.
  - **Paso 7.3 · Hablar** con Abu — «Entrevista a Abu (en casa)»
    - **Abu:** ¿Una entrevista para el colegio? ¡Qué importante! Pregunta, pregunta.
    - _(si en «tema» elegiste «Huerto»)_ **Abu:** Cuando tenía tu edad, en casa teníamos huerto. Lo más importante: regar temprano y tener paciencia.
    - _(si en «tema» elegiste «Robot»)_ **Abu:** ¿Un robot? En mis tiempos el robot era tu hermano mayor, y recogía cuando se lo mandaban. Me parece buena idea.
    - _(si en «tema» elegiste «Mascotas»)_ **Abu:** Una vez perdimos a un perro que se llamaba Chispa. Lo encontró la panadera. Los vecinos son el mejor tablón.
    - _(si en «tema» elegiste «Museo»)_ **Abu:** ¿Un museo del colegio? Yo fui a ese colegio, ¿lo sabías? Te puedo prestar la foto de mi clase.
  - **Paso 7.4 · Usar** — «Observa la fuente del parque»
    - 🖐 _Al usar «La fuente del parque»:_
      - _Narrador:_ _Mides cuánto tarda en llenarse un vaso en la fuente. Sara diría que es un experimento. Tú lo apuntas todo._
      - **Omar:** Doce segundos. Y yo me he bebido tres vasos. Por la ciencia.
- **Paso 8 · Usar** — «Coge cartón para reciclar (almacén del gimnasio)»
  - _En escena:_ Omar (te acompaña), Sara (si en «companero» elegiste «Sara») (te acompaña), Nico (si en «companero» elegiste «Nico») (te acompaña), Iker (si en «companero» elegiste «Iker») (te acompaña), Mateo (si en «companero» elegiste «Mateo») (te acompaña), Hugo (si en «companero» elegiste «Hugo») (te acompaña)
  - 🖐 _Al usar «Cajas de cartón para reciclar»:_
    - _Narrador:_ _Cajas de cartón de todos los tamaños. Andrés dice que podéis llevaros las que queráis «menos la de los conos»._
- **Paso 9 · Acción del jugador** — «Compra cartulinas en la librería»
  - _Lugar:_ la librería
  - ⏰ _Si tardas, Omar dice:_ «Yo pongo la mitad de las cartulinas. Bueno, un tercio. Tengo dos monedas.»
- **Paso 10 · Ir a** Aula de 1.º A — «Vuelve a clase a montar la maqueta»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Omar, Sara (si en «companero» elegiste «Sara»), Nico (si en «companero» elegiste «Nico»), Iker (si en «companero» elegiste «Iker»), Mateo (si en «companero» elegiste «Mateo»), Hugo (si en «companero» elegiste «Hugo»)
- **Paso 11 · Escena**
  - _Narrador:_ _Toca montar la maqueta. Y entonces empiezan los problemas._
  - _(si en «companero» elegiste «Sara»)_ **Sara:** Hay que hacerlo exacto: cada medida con regla. Si no, no es ciencia.
  - _(si en «companero» elegiste «Nico»)_ **Nico:** ¡Hay que hacerlo ENORME y con luces! ¡Que se vea desde la puerta!
  - _(si en «companero» elegiste «Iker»)_ **Iker:** Primero hay que hacer una tabla con todos los datos. Luego la maqueta. Luego otra tabla.
  - _(si en «companero» elegiste «Mateo»)_ **Mateo:** Yo… creo que mi dibujo no vale. Mejor hacedlo vosotros.
  - _(si en «companero» elegiste «Hugo»)_ **Hugo:** ¿Y si le añadimos una historia? Toda maqueta necesita una historia. Y un pirata.
  - **Omar:** Yo solo quiero que no nos enfademos. Y merendar. Pero sobre todo lo primero.
  - ❓ **Pregunta al jugador:** ¿Cómo lo resolvéis?
    - ➤ «Juntar las dos ideas: un poco de cada» _(efecto: Hugo +2; Iker +2; Mateo +2; Nico +2; Omar +3; Sara +2; empatia +1; decisión «discusion» = Juntar)_
      - **Omar:** ¡Eso! Exacto Y con luces. Con historia Y con datos. Somos unos genios de la diplomacia.
    - ➤ «Votar, y lo que salga» _(efecto: responsabilidad +1; decisión «discusion» = Votar)_
      - **Omar:** Votación. Dos contra uno. Bueno, uno contra uno contra uno. Otra vez. …Ya está: gana la mezcla.
    - ➤ «Decidir tú, que para algo lo has pensado» _(efecto: Hugo -2; Iker -2; Nico -2; Omar -1; Sara -2; valentia +1; decisión «discusion» = Decidir)_
      - **Omar:** Vale… lo hacemos como dices. Pero que conste que ha sido un poco de «porque sí».
  - _(si en «companero» elegiste «Mateo»)_ **Mateo:** ¿De verdad os gusta mi dibujo? Vale. Entonces lo hago bien grande.
- **Paso 12 · Minijuego** — «Monta la maqueta»
  - 🎮 _Cómo se juega:_ Pega cada pieza cuando la aguja esté en verde
- **Paso 13 · Transición (pasa el tiempo)** — «La noche antes de la presentación…»
  - ⏳ _Pantalla de transición:_ «La noche antes de la presentación…»
- **Paso 14 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** [tu nombre], teléfono. Es Omar. Dice que es una emergencia de maqueta.
  - **Omar:** (al teléfono) Mi hermano pequeño… se ha sentado encima. Encima de la maqueta. Está bien. El hermano. La maqueta no.
  - ❓ **Pregunta al jugador:** ¿Qué hacéis?
    - ➤ «Llamar al equipo y arreglarla juntos (en casa de Omar)» _(efecto: Omar +6; responsabilidad +1; marca «arreglo en equipo»)_
      - _Narrador:_ _Pasáis la tarde entre pegamento y cinta. Queda un poco torcida… pero es vuestra. Y lleva una tirita de cartón._
    - ➤ «Pedir ayuda a mamá/papá» _(efecto: Mamá/Papá +6; marca «ayuda familia»)_
      - **Mamá/Papá:** ¿Pegamento, tijeras y nervios? Tengo las tres cosas. Vamos.
      - **Abu:** Y yo sé hacer las esquinas rectas con una regla y un libro gordo. Truco de los de antes.
    - ➤ «Presentarla rota… y contar lo que pasó con humor» _(efecto: humor +2; marca «maqueta rota»)_
      - **Omar:** ¿Presentarla… así? Bueno. Diremos que ha sobrevivido a un terremoto. Un terremoto de cuatro años.
- **Paso 15 · Transición (pasa el tiempo)** — «El día de la presentación…»
  - ⏳ _Pantalla de transición:_ «El día de la presentación…»
- **Paso 16 · Ir a** Aula de 1.º A — «Ve a clase: las familias ya están llegando»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Mamá/Papá, Abu, Andrés, Bruno, Omar, Sara (si en «companero» elegiste «Sara»), Nico (si en «companero» elegiste «Nico»), Iker (si en «companero» elegiste «Iker»), Mateo (si en «companero» elegiste «Mateo»), Hugo (si en «companero» elegiste «Hugo»)
- **Paso 17 · Escena**
  - **Profe Lucía:** Bienvenidas, familias. Hoy cada equipo presenta su invento para Valmar. Después, el jurado hará algunas preguntas.
  - **Mamá/Papá:** (desde el fondo) ¡Ánimo, [tu nombre]!
  - **Omar:** Me tiemblan las rodillas. ¿A ti te tiemblan? A mí las dos.
  - **Bruno:** Suerte. Yo he hecho un volcán. Otra vez. Es un clásico. _[gesto Shrug]_
- **Paso 18 · Clase** — «Presenta el proyecto (las preguntas del jurado)»
- **Paso 19 · Escena**
  - _(si en «tema» elegiste «Huerto»)_ _Narrador:_ _Explicas vuestro huerto: dónde iría, qué plantaríais, quién lo regaría. Ramón levanta el pulgar desde la puerta._
  - _(si en «tema» elegiste «Robot»)_ _Narrador:_ _El robot «Bocadillo» abre y cierra la pinza. Todo el público hace «ooooh». Omar hace una reverencia._
  - _(si en «tema» elegiste «Mascotas»)_ _Narrador:_ _Enseñáis el tablón de mascotas con una foto de Bigotes. Media clase dice «ooooh»._
  - _(si en «tema» elegiste «Museo»)_ _Narrador:_ _Presentáis el museo del colegio con la foto de 1998. Lucía se tapa la cara… y luego aplaude la primera._
  - _(si tienes la marca «arreglo en equipo»)_ **Omar:** Y… esta es la tirita. Esta maqueta ha vivido mucho. Como nosotros.
  - _(si tienes la marca «maqueta rota»)_ _Narrador:_ _Cuentas lo del hermano de Omar. Las familias se ríen. Luego aplauden la idea más todavía._
  - _(si tu última nota es 8 o más)_ **Profe Lucía:** Buen trabajo, equipo. Una presentación clara, con datos y con ganas. Un sobresaliente.
  - _(si tu última nota es 8 o más)_ **Profe Lucía:** Y este proyecto… lo vamos a mandar al periódico de Valmar. Merece que lo conozca todo el barrio.
  - _(si tu última nota es menor que 8)_ **Profe Lucía:** Una idea muy bonita. La presentación se os ha hecho un poco cuesta arriba, pero el invento es bueno. Aprobado.
  - **Mamá/Papá:** Pase lo que pase, qué orgullo me das. Muchísimo. Ya no sé cómo decirlo más.
  - **Profe Lucía:** Queda una semana de colegio. La última. Aprovechadla.

**Al terminar (momento de la biografía):** «El proyecto final de primaria»

---

### Cole12_UltimoDia · «El último día»

**Resumen:** Último día de primaria. Un paseo por todos los sitios donde pasó tu historia… y una cápsula del tiempo por abrir.

_Tipo: Historia · Final de capítulo · Edad: 10-11 años · Duración: 20-30 min_

**Requisitos:** has terminado «El proyecto final» y has vivido el 94 % de la etapa

**Lo que puede cambiar:** Los recuerdos que visitas · Lo que había en tu cápsula · Cómo te despides de Bruno · Tu promesa al grupo

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «El último día de colegio…»
  - ⏳ _Pantalla de transición:_ «El último día de colegio…»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** Buenos días, [tu nombre]. Hoy es el último día. ¿Cómo puede pasar tan rápido? Ayer mismo te ponía la mochila por primera vez.
  - **Abu:** Disfruta cada rincón. Los últimos días se recuerdan tanto como los primeros.
  - **Mamá/Papá:** Esta tarde vamos todos a la ceremonia. Con la cámara. Y con pañuelos, por si acaso.
- **Paso 3 · Ir a** Vestíbulo — «Ve al colegio por última vez»
  - _Lugar:_ Vestíbulo · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»)
- **Paso 4 · Escena**
  - **Nico:** ¡[tu nombre]! ¿Te das cuenta? Es el último día. El último. Mañana ya no venimos. Qué raro.
  - **Sara:** Técnicamente venimos cinco años. Hoy termina un capítulo, no el libro.
  - **Omar:** Propongo una vuelta por todo el cole. Para despedirnos de cada sitio. Y del comedor, sobre todo.
  - _(si tienes el recuerdo «primer grupo»)_ _Narrador:_ _«[nombre de tu grupo]» recorre el colegio por última vez._
- **Paso 5 · Varios objetivos (en cualquier orden)** — «Despídete de los sitios del cole (al menos cuatro)»
  - _Lugar:_ Mostrador de la biblioteca · _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Marisa
  - **Paso 5.1 · Usar** — «Tu primer pupitre (clase)»
    - 🖐 _Al usar «Tu primer pupitre»:_
      - _Narrador:_ _✨ Tu primer día. La clase era enorme y no conocías a nadie._
      - _(si en «asiento» elegiste «Sara»)_ _Narrador:_ _✨ Te sentaste junto a Sara, y te habló de escarabajos durante media hora._
      - _(si en «asiento» elegiste «Nico»)_ _Narrador:_ _✨ Te sentaste junto a Nico, que te enseñó su balón firmado (por él mismo)._
      - _(si en «asiento» elegiste «Mateo»)_ _Narrador:_ _✨ Te sentaste junto a Mateo, el nuevo, que no se atrevía a hablar._
      - _(si tienes el recuerdo «primer amigo»)_ _Narrador:_ _✨ Y en el pasillo, a Mateo se le cayeron los libros. Tú le ayudaste a recogerlos. Tu primer amigo._
      - _(si tienes el recuerdo «segunda oportunidad»)_ _Narrador:_ _✨ Un día viste a Mateo comiendo solo… y te sentaste con él._
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo también me acuerdo. De todo. Gracias por aquel día.
  - **Paso 5.2 · Usar** — «Tu taquilla (pasillo)»
    - 🖐 _Al usar «Tu taquilla»:_
      - _(si tienes el recuerdo «mochila perdida»)_ _Narrador:_ _✨ El día que desapareció tu mochila. Rubén, el mensajero de Bruno, y todo el colegio buscándola._
      - _(si tienes la marca «dejaste mochila»)_ _Narrador:_ _✨ Aquel día te la dejaste en el banco. Desde entonces miras dos veces antes de irte._
      - _(si tienes el recuerdo «misterio colegio»)_ _Narrador:_ _✨ Y detrás de la chapa, una nota vieja: «NO ENTRES». La nota de una niña de 1998 que hoy es tu profe._
      - **Omar:** Esta taquilla ha visto más aventuras que cualquier otra. Deberían ponerle una placa.
  - **Paso 5.3 · Usar** — «El campo de fútbol»
    - 🖐 _Al usar «Un balón olvidado»:_
      - _(si tienes la marca «partido ganado»)_ _Narrador:_ _✨ Tu primer partido contra el equipo de Bruno. Ganasteis. Nico corrió por todo el campo gritando._
      - _(si tienes la marca «partido perdido»)_ _Narrador:_ _✨ Tu primer partido contra el equipo de Bruno. Perdisteis… pero Omar hizo una parada imposible._
      - _(si tienes la marca «partido empate»)_ _Narrador:_ _✨ Empatasteis tu primer partido. Nico dijo que un empate es una victoria compartida._
      - _(si tienes la marca «torneo ganado»)_ _Narrador:_ _✨ Y el torneo. La final. Medalla de oro, colgada al cuello delante de tu familia._
      - _(si tienes la marca «torneo perdido»)_ _Narrador:_ _✨ Y el torneo. La final. Medalla de plata… y Abu diciendo que del resultado casi no se acuerda._
      - _(si en «capitan» elegiste «Yo»)_ _Narrador:_ _✨ Te eligieron capitán. Omar te hizo el brazalete con cinta de carrocero. Todavía lo tienes._
      - **Nico:** Aquí he pasado la mitad de mi vida. La otra mitad, hablando de fútbol.
  - **Paso 5.4 · Usar** — «La biblioteca»
    - 🖐 _Al usar «La mesa donde estudiabas»:_
      - _(si tienes el recuerdo «primer examen»)_ _Narrador:_ _✨ El examen imposible. Los apuntes, Marisa, y estudiar hasta tarde._
      - _(si tienes el recuerdo «casi suspendo»)_ _Narrador:_ _✨ Aquel examen que casi suspendes. Y Lucía dándote otra oportunidad._
      - _(si en «companero estudio» elegiste «Sara»)_ _Narrador:_ _✨ Estudiaste con Sara. Te hizo un esquema con colores. Todavía lo tienes._
      - _(si en «companero estudio» elegiste «Iker»)_ _Narrador:_ _✨ Estudiaste con Iker. Tenía una tabla para todo. Hasta para los descansos._
      - _(si en «companero estudio» elegiste «Mateo»)_ _Narrador:_ _✨ Estudiaste con Mateo, que explicaba los problemas con dibujos._
      - _(si tienes la marca «suspendiste examen»)_ _Narrador:_ _✨ Y aquel suspenso. Y la clase de repaso de Lucía. Aprendiste que suspender no es el final de nada._
      - _(si tienes el recuerdo «proyecto final»)_ _Narrador:_ _✨ Tu proyecto de fin de curso, entre cartulinas y pegamento. Lo presentasteis aquí al lado._
      - **Marisa:** Venid a verme en el instituto. Los libros no se jubilan. Y yo tampoco. _[gesto WaveLite]_
  - **Paso 5.5 · Usar** — «El almacén del gimnasio»
    - 🖐 _Al usar «El almacén del gimnasio»:_
      - _(si tienes la marca «sabe libro hugo»)_ _Narrador:_ _✨ Aquí encontraste el libro de Hugo, «La isla de las mil llaves». Nadie sabía que era suyo._
      - _(si tienes el recuerdo «los malotes»)_ _Narrador:_ _✨ La persecución por el colegio. Esconderte de Ramón. Y Hugo diciendo «Yo no quería»._
      - _(si tienes el recuerdo «hugo amigo»)_ _Narrador:_ _✨ Y el día que Hugo dejó a Bruno y se vino con vosotros._
      - _(si tienes el recuerdo «detective»)_ _Narrador:_ _✨ Y el caso de las bromas del colegio, resuelto con una lupa._
      - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Aquí empezó todo, ¿verdad? Si no hubieras encontrado mi libro… Me alegro de que lo encontraras.
  - **Paso 5.6 · Usar** — «El banco del patio»
    - 🖐 _Al usar «El banco del patio»:_
      - _(si tienes el recuerdo «primer grupo»)_ _Narrador:_ _✨ En un banco como este os pusisteis nombre: «[nombre de tu grupo]»._
      - _(si en «sueno infancia» elegiste «Medicina»)_ _Narrador:_ _✨ La tarde en el parque. Querías trabajar en un hospital y salvar vidas._
      - _(si en «sueno infancia» elegiste «Ingenieria»)_ _Narrador:_ _✨ La tarde en el parque. Querías inventar cosas que no existen._
      - _(si en «sueno infancia» elegiste «Arte»)_ _Narrador:_ _✨ La tarde en el parque. Querías pintar cosas que la gente no olvidara._
      - _(si en «sueno infancia» elegiste «Deporte»)_ _Narrador:_ _✨ La tarde en el parque. Querías ser deportista de verdad._
      - _(si en «sueno infancia» elegiste «Derecho»)_ _Narrador:_ _✨ La tarde en el parque. Querías defender a la gente que no puede defenderse._
      - _(si en «sueno infancia» elegiste «Economia»)_ _Narrador:_ _✨ La tarde en el parque. Querías tener tu propio negocio._
      - _(si tienes el recuerdo «gato del cole»)_ _Narrador:_ _✨ Y Bigotes, el gato del cole, durmiendo al sol justo aquí._
      - _(si tienes el recuerdo «primera excursion»)_ _Narrador:_ _✨ Y la excursión a la granja. El autobús, el tractor que os adelantó… y volver todos juntos._
      - **Sara:** ¿Seguís queriendo ser lo que dijimos aquella tarde? Yo sí. Aunque ahora también quiero ser astronauta.
- **Paso 6 · Ir a** La sala cerrada — «Ve a la sala del fondo: hoy se abre la cápsula»
  - _Lugar:_ La sala cerrada · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Profe Lucía, Ramón
- **Paso 7 · Cinemática**
  - 🎬 **Cinemática «Cole12_Capsula»** _(música: → Intima)_
    - _En escena:_ Profe Lucía, Ramón, Nico, Sara, Omar, Mateo, Hugo, Iker
    - _Cámara:_ 1 planos
    - **Profe Lucía:** Lo prometí: la cápsula se abre el último día de colegio. Y esta vez no se me olvida. _[plano PrimerPlano de Profe Lucía · silencio 1.6 s]_
    - **Ramón:** Código secreto… _[plano Inserto de Caja]_
    - **Ramón:** Clac. Abierta. Treinta años guardando llaves y esta es la que más me ha gustado abrir. _[plano Reaccion de Ramón]_
    - **Omar:** ¿Y si se nos hubiera olvidado? _[plano Reaccion de Omar]_
    - **Sara:** Lo apunté en tres sitios. Cuatro, contando la mano. _[a Omar · plano Reaccion de Sara]_
    - **Profe Lucía:** A ver qué dejó aquí [tu nombre]… _[plano Hombro de Tú → Profe Lucía · silencio 0.6 s]_
    - _(si en «capsula» elegiste «Carta»)_ **Profe Lucía:** «Hola, yo del último día: ¿has sido valiente? ¿Sigues con tus amigos?» _[plano PrimerPlano de Profe Lucía]_
    - _(si en «capsula» elegiste «Dibujo»)_ _(o bien)_ **Omar:** ¡Tu dibujo del grupo! Salgo con un bocadillo. Es el retrato más realista de mi vida. _[plano Reaccion de Omar · en la pausa: Laugh]_
    - _(si en «capsula» elegiste «Prediccion»)_ _(o bien)_ **Profe Lucía:** «Nico será futbolista». Firmado: [tu nombre]. _[plano PrimerPlano de Profe Lucía]_
    - _(si en «capsula» elegiste «Pregunta»)_ _(o bien)_ **Profe Lucía:** «¿Seguimos siendo amigos?» _[plano PrimerPlano de Profe Lucía]_
    - _(si en «capsula» elegiste «Carta»)_ **Tú:** …Sí. A las dos cosas. _[silencio 0.8 s]_
    - _(si en «capsula» elegiste «Prediccion»)_ _(o bien)_ **Nico:** …Me lo guardo. Por si acaso. _[plano PPP de Nico · en la pausa: Suelo]_
    - _(si en «capsula» elegiste «Pregunta»)_ _(o bien)_ **Omar:** Qué pregunta más tonta. Ven aquí. _[plano Reaccion de Omar · silencio 1.0 s]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Nico:** Los Imparables. Desde aquel banco del parque. Y aquí seguimos. _[plano Reaccion de Nico]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Nico:** La Patrulla Valmar. Desde aquel banco del parque. Y aquí seguimos. _[plano Reaccion de Nico]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Nico:** Los del Banco Azul. Desde aquel banco del parque. Y aquí seguimos. _[plano Reaccion de Nico]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Nico:** Los Dinosaurios. Desde aquel banco del parque. Y aquí seguimos. _[plano Reaccion de Nico]_
    - **Profe Lucía:** Mi clase de 1998 hizo esto mismo. Y aquí estoy, en la misma sala. Las cosas importantes vuelven. _[plano PPP de Profe Lucía · en la pausa: Pensar · silencio 1.0 s]_
- **Paso 8 · Ir a** el patio — «Ve al patio: la ceremonia está a punto de empezar»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Profe Lucía, Andrés, Marta, Ramón, Marisa, Mamá/Papá, Abu, Bruno, Rubén, Vega, Álex
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Cole12_FotoClase»** _(música: → Resolucion efecto Momento)_
    - _En escena:_ Mamá/Papá, Abu, Profe Lucía, Nico, Sara, Omar, Mateo, Hugo, Iker, Vega, Álex
    - _Cámara:_ 2 planos (General, Hombro)
    - 🪧 _Rótulo:_ «📸 La última foto de clase» — Último día de primaria
    - **Mamá/Papá:** ¡Todos juntos, que no cabéis! Lucía, usted también. Nico, agáchate un poco. _[plano Medio de Mamá/Papá · silencio 2.2 s]_
    - **Nico:** ¡Si soy el más bajito! _[a Mamá/Papá · plano Reaccion de Nico]_
    - **Omar:** Yo me pongo detrás. Por razones de altura. Y de timidez. _[plano Reaccion de Omar]_
    - **Mamá/Papá:** Tres, dos, uno… ¡patata! _[plano Hombro de Mamá/Papá → Tú]_
    - **Abu:** Esa va a la nevera. Al lado de la del festival. Esa nevera ya es un museo. _[plano Reaccion de Abu]_
- **Paso 10 · Escena**
  - **Profe Lucía:** Familias, alumnos: hoy nuestra clase termina la primaria. _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** Os he visto llegar con mochilas más grandes que vosotros. Os he visto perder mochilas, encontrar amigos, resolver misterios…
  - **Profe Lucía:** …ganar torneos, perderlos, y aprender a dar la mano.
  - **Profe Lucía:** Estoy muy orgullosa de cada uno. _[plano PrimerPlano de Profe Lucía · en la pausa: Respira · silencio 0.8 s]_
  - _Narrador:_ _Uno a uno, subís a recoger el diploma. Cuando dicen tu nombre, tu familia aplaude tan fuerte que Marta se ríe._
  - _(si tu rasgo deportividad es 5 o más)_ **Andrés:** ¡Y el premio a la deportividad de todo el curso es para [tu nombre]!
  - _(si en «talento» elegiste «Cantar»)_ **Marta:** Y [tu nombre], que en el festival cantó delante de todo el colegio, empieza. Sin miedo.
  - _(si en «talento» elegiste «Chistes»)_ **Marta:** Y [tu nombre], que en el festival contó chistes: hoy, por favor, solo canciones. _[gesto Laugh]_
  - _(si en «talento» elegiste «Animar»)_ **Marta:** Y que nos anime [tu nombre], como en el festival. Palmas todos. _[gesto Clap]_
  - **Marta:** ♪ Y ahora, todos juntos, la canción del festival ♪
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Despídete»
  - **Paso 11.1 · Hablar** con Profe Lucía — «Lucía»
    - **Profe Lucía:** [tu nombre]. Ven aquí. Ha sido un placer ser tu profe. _[plano PrimerPlano de Profe Lucía · gesto Happy]_
    - _(si tienes el recuerdo «casi suspendo»)_ **Profe Lucía:** Y aquel examen… lo recuperaste. Nunca lo dudé.
    - _(si tienes la marca «secreto lucia»)_ **Profe Lucía:** Y gracias por guardar mi secreto. La foto sigue en mi mesa.
    - _(si en «foto lucia» elegiste «Devolver»)_ **Profe Lucía:** Y gracias por devolverme la foto. Ya no me da vergüenza. Casi.
    - _(si en «foto lucia» elegiste «Clase»)_ **Profe Lucía:** Toda la clase me llama ya «la de las coletas». Me encanta. No se lo digas.
    - **Profe Lucía:** Cuando seas mayor, vuelve a visitarme. Los profes queremos saber cómo acaba cada historia.
  - **Paso 11.2 · Hablar** con Bruno — «Bruno»
    - **Bruno:** Eh. Tú. _[plano Hombro de Tú → Bruno · gesto ArmsCrossed]_
    - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Cuando hablaste conmigo, cara a cara… nadie había hecho eso. Todos se chivaban o se callaban.
    - _(si en «festival bruno» elegiste «Ayudar»)_ **Bruno:** Lo de la limonada del festival… eso estuvo bien. Muy bien.
    - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Todavía me acuerdo de cuando me acusaste de lo de las bromas. No fui yo. Pero bueno. Ya pasó.
    - _(si tienes la marca «torneo ganado»)_ **Bruno:** Y el torneo. Me ganaste. Todavía me duele. Un poquito.
    - _(si tienes la marca «torneo perdido»)_ **Bruno:** Y el torneo. Te gané. Pero fue la final más difícil que he jugado.
    - ❓ **Pregunta al jugador:** ¿Qué le dices a Bruno?
      - ➤ «En el instituto, ¿empezamos de cero?» _(efecto: Bruno +10; empatia +1; decisión «adios bruno» = DeCero)_
        - **Bruno:** …De cero. Vale. Pero en fútbol no te voy a dejar ganar ni en el instituto.
      - ➤ «Suerte, Bruno. De verdad.» _(efecto: Bruno +5; decisión «adios bruno» = Suerte)_
        - **Bruno:** Suerte. …Tú también. Y lo digo de verdad. No te acostumbres.
      - ➤ «Ya nos veremos.» _(efecto: decisión «adios bruno» = Seco)_
        - **Bruno:** Ya nos veremos. Eso seguro.
    - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Adiós, [tu nombre]. Gracias por perdonarme lo de la mochila. _[en la pausa: Baja]_
    - _(si tienes la marca «ruben rival»)_ **Rubén:** Lo de la mochila… Bueno. Que te vaya bien. Más o menos. _[en la pausa: Aparta]_
  - **Paso 11.3 · Hablar** con Ramón — «Ramón»
    - **Ramón:** Otro curso que se va. Y yo aquí, con mis llaves.
    - **Ramón:** Toma, un recuerdo: un llavero con el número 13. Para que no se te olvide que las puertas cerradas a veces esconden cosas bonitas.
- **Paso 12 · Escena**
  - _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»)
  - **Omar:** Bueno. ¿Y ahora qué? En el instituto habrá cientos de personas. Y no conoceremos a nadie.
  - **Nico:** ¡Nos conoceremos a nosotros! Eso ya es algo.
  - **Sara:** Propongo una promesa. Formal. Con las manos juntas. _[plano Reaccion de Sara]_
  - _(si tienes el recuerdo «primer grupo»)_ **Nico:** Una promesa oficial de [nombre de tu grupo]. _[gesto HandsOnHips]_
  - **Sara:** [tu nombre], tú la dices.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo llegué sin conocer a nadie. Y ahora mirad. Así que el instituto… no me da miedo. Casi.
  - ❓ **Pregunta al jugador:** ¿Qué prometéis?
    - ➤ «Pase lo que pase, seguimos juntos.» _(efecto: Nico +5; Omar +5; Sara +5; empatia +1; decisión «promesa» = Juntos)_
      - **Omar:** Juntos. Hasta en el comedor del instituto, que dicen que es peor. Juntos contra el puré.
    - ➤ «Conocer a gente nueva… sin olvidarnos nunca.» _(efecto: Nico +3; Omar +3; Sara +3; valentia +1; decisión «promesa» = Nuevos)_
      - **Sara:** Me gusta. Crecer sin perder nada. Técnicamente, es lo más difícil. Y lo más bonito.
    - ➤ «Quedar en el banco del parque cada verano.» _(efecto: Nico +4; Omar +4; Sara +4; responsabilidad +1; decisión «promesa» = Banco)_
      - **Nico:** ¡Cada verano! ¡Y el que no venga, paga los helados!
- **Paso 13 · Cinemática**
  - _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Mamá/Papá, Abu
  - 🎬 **Cinemática «Cole12_Despedida»** _(música: → Intima)_
    - _En escena:_ Nico, Sara, Omar, Mateo, Hugo, Iker, Mamá/Papá, Abu
    - _Cámara:_ 1 planos (General)
    - **Nico:** Bueno. ¿Quién se va primero? _[plano Medio de Nico · silencio 2.2 s]_
    - **Sara:** Técnicamente, si no se va nadie, no se acaba. _[a Nico · plano Reaccion de Sara]_
    - **Omar:** Pues yo me quedo. Tengo bocadillo para tres horas. _[plano PrimerPlano de Omar]_
    - _(si tienes el recuerdo «primer amigo»)_ **Mateo:** El primer día se me cayeron los libros y tú te agachaste. No te lo he dicho bastante: gracias. _[plano PrimerPlano de Mateo · en la pausa: Suelo]_
    - _(si tienes el recuerdo «segunda oportunidad» y NO tienes el recuerdo «primer amigo»)_ **Mateo:** Aquel día que te sentaste conmigo en el comedor… lo cambió todo. Gracias. _[plano PrimerPlano de Mateo · en la pausa: Suelo]_
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Si en el instituto alguien me dice «cógelo tú, que a ti no te vigilan», diré que no. Lo he practicado. _[plano PrimerPlano de Hugo]_
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** Dato curioso: hemos pasado juntos unos mil recreos. No es suficiente. _[plano PrimerPlano de Iker]_
    - _(si en «promesa» elegiste «Juntos»)_ **Omar:** Oye… lo del puré iba en serio, ¿eh? Juntos. No se me olvida. _[plano Reaccion de Omar]_
    - _(si en «promesa» elegiste «Nuevos»)_ _(o bien)_ **Sara:** Gente nueva, sin olvidar a la de siempre. Hecho. Es un plan. _[plano Reaccion de Sara]_
    - _(si en «promesa» elegiste «Banco»)_ _(o bien)_ **Nico:** Primer verano, primer día: banco del parque. Yo llevo el balón. _[plano Reaccion de Nico]_
    - **Abu:** Los últimos días se recuerdan tanto como los primeros. Te lo dije esta mañana. _[plano Medio de Abu · silencio 1.0 s]_
    - **Mamá/Papá:** [tu nombre]… cuando quieras. Sin prisa. _[plano Reaccion de Mamá/Papá]_
- **Paso 14 · Cinemática**
  - 🎬 **Cinemática «Cole12_FinDeEpisodio»** _(música: → Intima → Tema)_
    - _En escena:_ Nico, Sara, Omar, Mateo, Hugo, Iker, Mamá/Papá, Abu
    - _Cámara:_ 3 planos (DosPlanos, General)
    - 🪧 _Rótulo:_ «Fin de primaria» — Así termina el colegio. Lo que empieza ahora… es otra historia.
    - **Nico:** Venga. A la de tres. Todos.
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Tú:** ¡LOS IMPARABLES!
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Tú:** ¡LA PATRULLA VALMAR!
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Tú:** ¡LOS DEL BANCO AZUL!
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Tú:** ¡LOS DINOSAURIOS!
- **Paso 15 · Transición (pasa el tiempo)** — «Pasan los años… y llega el instituto.»
  - ⏳ _Pantalla de transición:_ «Pasan los años… y llega el instituto.» _(pasas a la etapa Adolescente)_
  - 🎬 **Montaje / cinemática de transición «Nino_AInstituto»** _(música: → Intima → Descubrimiento PasanLosAnos; montaje de cambio de etapa Nino → Adolescente)_
    - _En escena:_ Ramón, Profe Lucía, Javier, Nico, Sara, Omar, Leire, Mateo, Dani, Hugo, Iker, Rubén, Andrés, Álex, Julián, Paula · _entran andando:_ Nico, Sara, Omar, Leire
    - _Cámara:_ 16 planos (Reaccion, DosPlanos)
    - 🪧 _Rótulo:_ «El colegio» — Fin del capítulo
    - 🪧 _Rótulo:_ «Campus Valmar: el instituto»
    - _(si tienes la marca «ayudaste a mateo»)_ 🪧 _Rótulo:_ «Mateo» — Le ayudaste a recoger sus libros. Fue tu primer amigo.
    - _(si tienes la marca «hugo con el grupo» y NO tienes la marca «ayudaste a mateo»)_ 🪧 _Rótulo:_ «Hugo» — Dejó a Bruno y se vino con vosotros
    - _(si tienes el recuerdo «detective» y NO tienes las marcas «ayudaste a mateo» y «hugo con el grupo»)_ 🪧 _Rótulo:_ «El caso de las bromas» — Descubriste quién era. Y no se lo contaste a todo el mundo.
    - _(si NO tienes las marcas «ayudaste a mateo» y «hugo con el grupo» y NO tienes el recuerdo «detective»)_ 🪧 _Rótulo:_ «Tu primer día de colegio» — «Pasad, pasad.» Y pasaste.
    - _(si tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ «Tu grupo» — Nico, Sara, Omar… y tu sitio en el banco
    - _(si en «nombre grupo» elegiste «Los Imparables» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los Imparables»» — Nico, Sara, Omar… y tu sitio en el banco
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««La Patrulla Valmar»» — Nico, Sara, Omar… y tu sitio en el banco
    - _(si en «nombre grupo» elegiste «Los del Banco Azul» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los del Banco Azul»» — Nico, Sara, Omar… y tu sitio en el banco
    - _(si en «nombre grupo» elegiste «Los Dinosaurios» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los Dinosaurios»» — Nico, Sara, Omar… y tu sitio en el banco
    - _(si NO tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ «Las tardes en el parque» — Nico, Sara y Omar
    - _(si tienes el recuerdo «primer torneo»)_ 🪧 _Rótulo:_ «El torneo del colegio» — Andrés todavía grita «¡defensa!» en sueños
    - _(si tienes el recuerdo «primera excursion» y NO tienes el recuerdo «primer torneo»)_ 🪧 _Rótulo:_ «La excursión a Villaverde» — Paula se sabía el nombre de cada gallina
    - _(si tienes el recuerdo «proyecto final» y NO tienes los recuerdos «primer torneo» y «primera excursion»)_ 🪧 _Rótulo:_ «El proyecto de Ciencias» — Delante de todas las familias
    - _(si NO tienes los recuerdos «primer torneo», «primera excursion» y «proyecto final»)_ 🪧 _Rótulo:_ «Has crecido mucho.» — Seis años en el colegio de Los Pinos
    - 🪧 _Rótulo:_ «Pasan los años… y llega el instituto.» — Septiembre. Primer día.
    - **Ramón:** Otro curso que se va. ¿Cierro ya, Lucía?
    - _(si tienes la marca «capsula del tiempo»)_ **Ramón:** La cápsula del tiempo, enterrada. Dentro de veinte años, a ver quién se acuerda.
    - _(si NO se cumple: tienes la marca «secreto lucia»)_ **Profe Lucía:** Un minuto más, Ramón. Estos… estos se me van a hacer difíciles de olvidar.
    - _(si tienes la marca «secreto lucia»)_ **Profe Lucía:** Un minuto más. Alguien de esa clase guardó mi secreto todo el curso. No se me va a olvidar.
    - **Nico:** ¡Es ENORME! ¿Esto tiene ascensor?
    - _(si en «promesa» elegiste «Juntos»)_ **Omar:** Juntos contra el puré, ¿os acordáis? Pues seguimos en pie.
    - _(si NO se cumple: en «promesa» elegiste «Juntos»)_ **Sara:** Tres edificios, dos pistas y un comedor que, según las estadísticas, es peor.

**Al terminar (momento de la biografía):** «Tu último día de primaria»

---

**Texto de cierre del capítulo:** «Has crecido mucho.»

# Saga de la Grieta · Acto I «La Grieta»

> Misiones canónicas de la saga (infancia: en paralelo al colegio (pilar dorado en el mapa)). Se ven siempre en el mapa hasta hacerlas.

### Loco_N1_Cosme · «El vecino del garaje»

**Resumen:** ¡BUM! Del garaje del vecino sale humo verde. Y una voz: «¡NADIE TOQUE NADA QUE BRILLE!»

_Tipo: Saga de la Grieta · Acto I (1/6) · Duración: 12-18 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «¡BUM! Humo verde en el garaje del vecino…»

**Requisitos:** etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Habla con el vecino (lleno de hollín)»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme
  - **Cosme:** ¡COF! ¡Cof! …Ah. Una criatura. Hola, criatura. _[plano Medio de Cosme · gesto Surprised]_
  - **Cosme:** No te asustes: el humo verde es normal. El humo morado, no. El humo morado, corre. _[ademán Point]_
  - **Cosme:** Soy Cosme. Inventor. Genio. Vecino. En ese orden. _[en la pausa: Sonrie]_
  - **Tú:** ¿Qué ha explotado?
  - **Cosme:** Mi microondas temporal. Calienta la comida… en el pasado. Así está caliente desde antes de tener hambre. Brillante. Revolucionario. Ha explotado. _[gesto Shrug]_
  - **Cosme:** Y han salido volando tres piezas: el tornillo cuántico, la bobina de gominola y el chip de mi abuela.
  - **Cosme:** No preguntes por el chip de mi abuela. _[en la pausa: Aparta · silencio 0.5 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Te ayudo a buscarlas!» _(efecto: Cosme +5; valentia +1)_
      - **Cosme:** ¿Ayudar? ¿Gratis? Qué concepto tan raro. Me gusta. Tú vales para esto.
    - ➤ «¿El chip de tu abuela?» _(efecto: Cosme +3; curiosidad +1)_
      - **Cosme:** Mi abuela era una calculadora. Larga historia. Muy triste. Muchos decimales.
  - **Cosme:** Una cosa, criatura: si alguna pieza te habla, no le hagas caso. Las piezas mienten.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Recupera las 3 piezas del microondas temporal»
  - **Paso 2.1 · Usar** — «El tornillo cuántico (cerca de la fuente del parque)»
    - 🖐 _Al usar «El tornillo cuántico»:_
      - _Narrador:_ _Junto a la fuente hay un tornillo que brilla. Al cogerlo, durante un segundo, ves el parque en blanco y negro, lleno de dinosaurios._
      - _Narrador:_ _Parpadeas. Ya no. Mejor no pensarlo mucho._
  - **Paso 2.2 · Usar** — «La bobina de gominola (en la heladería)»
    - 🖐 _Al usar «Una bobina… dentro de un helado»:_
      - _Narrador:_ _Un niño se está comiendo un helado de fresa con una bobina de metal dentro. Dice que sabe «a martes»._
      - ❓ **Pregunta al jugador:** ¿Cómo la consigues?
        - ➤ «Le cambias la bobina por tu merienda» _(efecto: empatia +1)_
          - _Narrador:_ _Trato hecho. El niño te mira muy serio y dice: «El martes vuelve». Vale._
        - ➤ «Le dices que es un helado del futuro y que ya ha caducado» _(efecto: humor +1)_
          - _Narrador:_ _Te la da con cara de asco. Técnicamente no mentías: viene del pasado. Casi._
  - **Paso 2.3 · Usar** — «El chip (lo tiene el gato del cole)»
    - 🖐 _Al usar «Bigotes (con un chip en el collar)»:_
      - _Narrador:_ _Bigotes, el gato del colegio, lleva el chip enganchado al collar. Te mira. Tú le miras. Él suspira._
      - **Bigotes XVII:** Cría humana. Coge tu chip y vete. Y no le digas a nadie que puedo hablar. Tengo una reputación.
      - **Tú:** ¡¿El gato habla?!
      - **Bigotes XVII:** Todos los gatos hablamos. Solo que no con vosotros. _[gesto ArmsCrossed]_
      - **Bigotes XVII:** …Este chip me ha soltado la lengua. Ya me callo. Miau. Ya está. Miau. _[en la pausa: Aparta]_
- **Paso 3 · Ir a** El garaje de Cosme — «Lleva las piezas al garaje de Cosme»
- **Paso 4 · Escena**
  - **Cosme:** ¡Tornillo, bobina, chip! ¡Y… ya! Vamos a calentar este bocadillo de chorizo al martes pasado. _[plano DosPlanos de Cosme → Tú · ademán Cheer]_
  - _Narrador:_ _El microondas zumba. Brilla. Hace «ding». Dentro hay un bocadillo… un poco mordido._ _[silencio 0.8 s]_
  - **Cosme:** ¿Quién ha mordido mi bocadillo en el pasado? _[plano PrimerPlano de Cosme · gesto Surprised]_
  - **Cosme:** …Fui yo. El martes pasado. Ya decía yo que el martes tenía hambre. _[en la pausa: Piensa]_
  - **Cosme:** Toma, criatura. Por las piezas. Iba a ser un desintegrador de materia, pero solo hace burbujas. _[gesto Point]_
  - **Cosme:** Burbujas cuánticas. Existen en tres dimensiones a la vez. _[gesto Happy]_
  - _Narrador:_ _Recibes la 🔵 Pistola de burbujas cuánticas (úsala desde tu mochila)._
  - ❓ **Pregunta al jugador:** Cosme te mira muy serio: «¿Se lo vas a contar a tu familia?»
    - ➤ «Será nuestro secreto de vecinos.» _(efecto: Cosme +5; marca «secreto cosme» y «grieta vista»)_
      - **Cosme:** Buena criatura. Pásate cuando quieras. Pero llama antes. Tres veces. Luego dos. Luego tararea algo.
      - 🎬 **Escena de cámara «Grieta_Rasguno»**
    - ➤ «Se lo voy a contar. Todo.» _(efecto: responsabilidad +1; marca «grieta vista»)_
      - **Cosme:** Cuéntaselo. No te va a creer nadie. Esa es la ventaja de ser un genio: la verdad suena a mentira.
      - _Narrador:_ _Esa noche se lo cuentas a mamá/papá. Te dice que qué imaginación. Y te pone más puré._
      - 🎬 **Escena de cámara «Grieta_Rasguno»** _(la misma de antes, ver arriba)_
  - _Narrador:_ _Al salir del garaje, Cosme se queda mirando el cielo. Encima de Los Pinos hay una raja de luz, finísima, como un rasguño en el aire._ _[plano General · silencio 0.8 s]_
  - **Cosme:** Criatura… ¿eso estaba ahí antes? _[plano PrimerPlano de Cosme · gesto Surprised · en la pausa: Piensa]_
  - **Cosme:** …No. No estaba. _[gesto Nervous · silencio 1.0 s]_
  - **Cosme:** Vete a casa. Mañana hablamos. Mañana… hablamos. _[en la pausa: Baja]_

**Al terminar (momento de la biografía):** «Conociste a Cosme, el inventor del garaje»

---

### Saga_02_Grieta · «La grieta en el cielo»

**Resumen:** La raja de luz del cielo ha crecido. Esta noche han caído cosas. Cosas que no son de aquí.

_Tipo: Saga de la Grieta · Acto I (2/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Cosme te espera en el garaje con un aparato que pita mucho»

**Requisitos:** has terminado «El vecino del garaje» y etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Cosme quiere enseñarte su medidor de rarezas»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip
  - _(si tienes la marca «amigo de cosme»)_ **Cosme:** ¡Mi vecino/a favorito/a! Ven, ven. Corre. Despacio. Pero corre. _[ademán Wave]_
  - **Cosme:** ¿Viste la raja del cielo? Ha crecido. Tres centímetros. En el cielo, tres centímetros son MUCHOS kilómetros. _[ademán Point]_
  - _(si tienes la marca «secreto cosme»)_ **Cosme:** Y como sabes guardar un secreto, eres la única persona a la que se lo puedo enseñar.
  - **Cosme:** Esto es un medidor de rarezas. Pita cuando algo no es de esta dimensión. _[plano Medio de Cosme]_
  - **Cosme:** Esta mañana ha pitado tanto que Pip se ha desmayado. _[a Pip]_
  - **Pip:** No me he desmayado. Me he reiniciado con elegancia. _[a Cosme · gesto ArmsCrossed]_
  - **Cosme:** Esta noche han caído cosas de la grieta. Hay que recogerlas antes de que las encuentre alguien. O algo. _[en la pausa: Respira]_
  - **Cosme:** Pip va contigo. Yo me quedo… calculando. Y un poco escondido. _[gesto Nervous]_
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Grieta_Caen»** _(música: efecto Momento)_
    - _En escena:_ Cosme, Pip, Chispa
    - _Cámara:_ 7 planos
    - 🪧 _Rótulo:_ «☄️ Han caído tres cosas del cielo» — Busca los cráteres humeantes
    - ⏸ _El jugador debe reaccionar:_ «¡Cúbrete!»
    - **Pip:** ¡Señor Cosme! ¡El medidor marca… TODO! ¡La raja del cielo se está encendiendo! _[emoción Fear]_
    - **Cosme:** ¡Mira arriba! ¡Algo sale de la grieta! _[emoción Surprise]_
    - _(si reaccionaste a tiempo («cubrirse»))_ **Pip:** ¡Buenos reflejos! Aunque eso cae a varios kilómetros, ¿eh?
    - _(si NO se cumple: reaccionaste a tiempo («cubrirse»))_ **Pip:** ¡Agáchate! …Vale, da igual. Cae lejos. Muy lejos. Creo.
    - _Narrador:_ _Tres estrellas verdes caen sobre Valmar: el parque, el patio del cole y el camino al colegio._
    - **Chispa:** ¡Bip! ¿Bip? ¡BIIIP! _[emoción Fear]_
    - **Pip:** Tres impactos. Mi sensor de miedo también ha tenido tres impactos.
    - **Cosme:** Hay que recogerlo antes de que lo encuentre alguien. O algo. ¡Rápido, criatura!
- **Paso 3 · Varios objetivos (en cualquier orden)** — «El medidor pita en tres sitios. Recoge lo que ha caído de la Grieta»
  - _En escena:_ Pip (te acompaña)
  - **Paso 3.1 · Usar** — «Un cráter humeante junto a la fuente del parque»
    - 🎬 **Escena al completarlo «Grieta_Recoger»**
    - 🖐 _Al usar «Un calcetín que brilla… y habla»:_
      - _Narrador:_ _Un calcetín verde. Cuando lo coges, dice con vocecita: «¿Has visto a mi pareja? Es igual que yo, pero del pie izquierdo»._
      - **Pip:** Calcetín de otra dimensión. Allí los calcetines hablan. Y se pierden igual. Algunas cosas son universales.
  - **Paso 3.2 · Usar** — «Un cráter humeante en la zona de juegos del cole»
    - 🎬 **Escena al completarlo «Grieta_Recoger»** _(la misma de antes, ver arriba)_
    - 🖐 _Al usar «Un paraguas que llueve hacia arriba»:_
      - _Narrador:_ _Un paraguas abierto. Debajo, la lluvia cae hacia ARRIBA. Tres niños de primero lo miran con la boca abierta._
      - _Narrador:_ _Lo cierras. Los niños aplauden._
  - **Paso 3.3 · Usar** — «Un cráter humeante en el camino al cole»
    - 🎬 **Escena al completarlo «Grieta_Recoger»** _(la misma de antes, ver arriba)_
    - 🖐 _Al usar «Una moneda caliente»:_
      - _Narrador:_ _Una moneda caliente, como recién salida de un horno. En una cara pone «66-B». En la otra hay una cara. Es la cara de Cosme._
      - _Narrador:_ _…Pero con perilla. Y una sonrisa que no es la de Cosme. Una sonrisa de anuncio de la tele._
      - **Pip:** …Oh, no. Oh, no, no, no. Mejor que esto lo vea el señor Cosme. _[plano PrimerPlano de Pip · gesto Nervous]_
      - **Pip:** Mejor que no lo vea. Mejor que lo vea. Tengo un conflicto de programación. _[en la pausa: Piensa]_
- **Paso 4 · Hablar** con Bigotes XVII — «Bigotes te espera en el tejado del cole… bueno, en el patio»
  - _Lugar:_ el patio · _En escena:_ Bigotes XVII
  - _(si tienes la marca «bigotes habla»)_ **Bigotes XVII:** Cría humana. Deja de hacer como que no me oyes hablar. Tengo información imperial.
  - _(si NO tienes la marca «bigotes habla»)_ **Bigotes XVII:** Miau. …Vale. Sé que sabes que hablamos. Escucha.
  - _(si tienes el recuerdo «emperador bigotes»)_ **Bigotes XVII:** Te habla Bigotes XVII. Emperador. Exiliado. Deudor tuyo, por lo de las cucarachas. No te acostumbres.
  - **Bigotes XVII:** Esa grieta del cielo ya la vi una vez. En Gatonia la llamamos «La Puerta Mal Cerrada». _[plano Medio de Bigotes XVII]_
  - **Bigotes XVII:** Por ahí entran los problemas. Las cucarachas. Los cobradores. Los que venden cosas. _[gesto ArmsCrossed]_
  - **Bigotes XVII:** Y esta noche he oído algo al otro lado. Una voz de hombre. Muy elegante. _[en la pausa: Aparta · silencio 0.6 s]_
  - **Bigotes XVII:** Decía tu nombre, humano. Varias veces. Como quien cuenta monedas. _[plano PrimerPlano de Bigotes XVII]_
- **Paso 5 · Ir a** El garaje de Cosme — «Lleva los restos al garaje de Cosme»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip
- **Paso 6 · Escena**
  - **Cosme:** Un calcetín parlante, un paraguas al revés… normal. Todo normal. Ciencia. ¿Qué más traes? ¿Una moneda? A ver… _[plano Medio de Cosme]_
  - **Cosme:** (Mira la moneda. Se queda muy quieto. Se le cae el batido de apio.) _[plano PrimerPlano de Cosme · gesto Surprised · silencio 0.5 s]_
  - **Pip:** (Lo recoge antes de que toque el suelo.) _[plano Reaccion de Pip]_
  - **Cosme:** …Cósimo. _[plano PPP de Cosme · silencio 1.2 s]_
  - **Tú:** ¿Quién es Cósimo?
  - **Cosme:** Nadie. Un viejo… conocido. Un socio. Hace años. _[gesto Sad · en la pausa: Aparta]_
  - **Cosme:** Muchos años. Tantos como tú tienes, más o menos. _[silencio 0.6 s]_
  - **Cosme:** No importa. No importa nada. Ciencia. Vete a cenar, criatura. _[gesto Sad · en la pausa: Baja]_
  - **Pip:** (Bajito) El señor Cosme no ha dormido desde que vio la línea del cielo. Cuide de él. _[plano PPP de Pip]_
  - **Pip:** Él lleva mucho tiempo cuidando de usted. Aunque usted no lo sepa. _[en la pausa: Mira]_
  - _Narrador:_ _Te quedas la moneda. Cosme no quiere tenerla cerca. Recibes 🪙 la Moneda de la 66-B._

**Al terminar (momento de la biografía):** «Viste la Grieta por primera vez»

---

### Saga_03_Pez · «El pez que sabía demasiado»

**Resumen:** En el estanque del parque hay un pez naranja que respira aire, lleva corbata y pide auxilio con mucha educación.

_Tipo: Saga de la Grieta · Acto I (3/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a Estanque del parque. «¡Psst! ¡Aquí! ¡En el estanque! ¡Un pez te está llamando!»

**Requisitos:** has terminado «La grieta en el cielo» y etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Don Escamas — «Habla con el pez del estanque»
  - _Lugar:_ Estanque del parque · _En escena:_ Don Escamas
  - **Don Escamas:** ¡Gracias a Neptuno! Un humano con cara de buena persona. _[plano Medio de Don Escamas · gesto Happy]_
  - **Don Escamas:** Me presento: Don Escamas. Contable. Pez. Refugiado dimensional.
  - **Don Escamas:** Me colé por esa grieta del cielo huyendo de mi antiguo jefe: el Consorcio MegaVerso Sociedad Anónima. _[ademán Point]_
  - **Don Escamas:** Venden vacaciones a otras dimensiones. Y cosas peores. Mucho peores. _[en la pausa: Respira]_
  - **Don Escamas:** Yo llevaba sus cuentas. Vi cosas en las cuentas. Cosas que un pez no debería ver. _[gesto Nervous]_
  - **Don Escamas:** Y ahora me buscan dos agentes de gris. Con gafas de sol. De noche. Eso nunca es buena señal. _[plano PrimerPlano de Don Escamas]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Te saco de aquí. Conozco a alguien.» _(efecto: Don Escamas +8; valentia +1)_
      - **Don Escamas:** ¡Un humano con contactos! Esto es lo que yo llamo un activo.
    - ➤ «¿Qué viste en las cuentas?» _(efecto: curiosidad +2)_
      - **Don Escamas:** Un pedido enorme. «Proyecto Fusión». Firmado por un tal doctor… no, aquí no. Las paredes tienen oídos. Y los árboles tienen agentes.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Prepara la huida de Don Escamas»
  - **Paso 2.1 · Usar** — «Un cubo para llevarle»
    - 🖐 _Al usar «Un cubo del parque»:_
      - _Narrador:_ _Un cubo con agua del estanque. Don Escamas salta dentro con un «¡hop!» muy digno y se ajusta la corbata._
  - **Paso 2.2 · Usar** — «Mira qué se les ha caído a los que le buscan»
    - 🖐 _Al usar «Una tarjeta de visita gris»:_
      - _Narrador:_ _Una tarjeta gris: «MegaVerso S.A. — Tu vida, en mil dimensiones. Delegación Valmar: PRÓXIMAMENTE»._
      - _Narrador:_ _Por detrás, escrito a mano: «Localizar al Ancla»._ _[silencio 0.6 s]_
      - _Narrador:_ _Dos hombres de traje gris aparecen entre los árboles. Sonríen a la vez. Exactamente a la vez._
      - **Agente de MegaVerso:** Buenos días. ¿Ha visto usted un pez? Contable. Traidor. Con corbata. _[gesto Happy]_
      - **Agente de MegaVerso:** Hay recompensa: un fin de semana en la dimensión de los helados.
- **Paso 3 · Huida** — «¡Los agentes grises! Lleva a Don Escamas al garaje de Cosme sin que te atrapen»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Don Escamas (te acompaña), Agente de MegaVerso
  - 🚨 _Si te atrapan:_ «¡Qué oferta tan irresistible! …Digo: ¡alto! (Te quitan el cubo, se les cae, lo recuperas en el estanque.)»
- **Paso 4 · Escena**
  - _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** ¿Un pez? ¿En mi garaje? ¿Contable? Siempre he querido un contable. _[gesto Happy]_
  - **Cosme:** Pip, la pecera buena. La que no explota. _[a Pip]_
  - **Don Escamas:** Doctor Cosme. Por fin. En el Consorcio su nombre sale mucho. Bueno, el de su socio. El de la perilla. _[a Cosme]_
  - _(si tienes la marca «sabe de cosimo»)_ **Tú:** ¿El de la moneda? ¿Cósimo?
  - **Cosme:** …No sé de qué me habla. Pez. _[a Don Escamas · en la pausa: Aparta]_
  - **Don Escamas:** Su socio, Cósimo, está en la dimensión 66-B. El Consorcio le paga el laboratorio. _[plano Medio de Don Escamas]_
  - **Don Escamas:** Y le buscan algo aquí: el Ancla. Por eso la grieta no se abre del todo. Por el Ancla.
  - **Tú:** ¿Qué es el Ancla?
  - **Don Escamas:** …Uy. He hablado de más. Es un tic de contable: lo cuento todo. Me callo. Me callo muy fuerte. Glu. _[gesto Ashamed]_
  - **Cosme:** (Cosme y Pip se miran. No te miran a ti. Te miran mucho, pero sin mirarte.) _[plano DosPlanos de Cosme → Pip · gesto Nervous · silencio 0.5 s]_
  - **Cosme:** Nadie ha dicho nada de anclas. Ni de barcos. El pez se queda aquí. Tú vete a casa. _[en la pausa: Respira]_
  - **Cosme:** Y, criatura… si ves a alguien de gris, corre. Siempre. _[plano PrimerPlano de Cosme]_
  - **Don Escamas:** Toma: una escama. Por si necesitas un contable. O un amigo. Soy las dos cosas. _[gesto Happy]_
  - _Narrador:_ _Recibes ✨ una Escama brillante._

**Al terminar (momento de la biografía):** «Rescataste a Don Escamas del Consorcio»

---

### Saga_04_Ventanilla · «La ventanilla 42»

**Resumen:** La Aduana del Tiempo ha multado a Cosme por tener «una grieta dimensional sin licencia». Para pagarla hay que rellenar un formulario. En tres ventanillas.

_Tipo: Saga de la Grieta · Acto I (4/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Hay un señor con traje y cuarenta formularios en la puerta del garaje de Cosme»

**Requisitos:** has terminado «El pez que sabía demasiado» y etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Agente Cronos, de Aduanas del Tiempo — «Habla con el señor de los formularios»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Agente Cronos, de Aduanas del Tiempo
  - **Agente Cronos, de Aduanas del Tiempo:** Agente Cronos, Aduana del Tiempo. El señor Cosme tiene en su barrio una grieta dimensional sin licencia. _[plano Medio de Agente Cronos, de Aduanas del Tiempo]_
  - **Agente Cronos, de Aduanas del Tiempo:** Multa. Formulario 42. Tres ventanillas.
  - **Cosme:** ¡Esa grieta no es mía! Bueno. Es un poco mía. Un cincuenta por ciento. _[a Agente Cronos, de Aduanas del Tiempo · gesto Angry]_
  - **Cosme:** El otro cincuenta es de un señor con perilla que no está. _[en la pausa: Aparta]_
  - **Agente Cronos, de Aduanas del Tiempo:** Ya. Todos dicen que la grieta es del de la perilla. Formulario 42. _[a Cosme]_
  - **Agente Cronos, de Aduanas del Tiempo:** El pequeño humano puede hacer el trámite; el señor Cosme tiene prohibidas las ventanillas desde 1994.
  - **Cosme:** ¡Fue un accidente! ¡La ventanilla estaba así cuando llegué! _[gesto Facepalm]_
  - **Cosme:** …Ve tú, criatura. Y no discutas con nadie que lleve un sello. Nunca. _[silencio 0.5 s]_
- **Paso 2 · Hablar** con Funcionaria de la ventanilla — «Ventanilla 1: Correos»
  - _Lugar:_ Correos · _En escena:_ Funcionaria de la ventanilla
  - **Funcionaria de la ventanilla:** Formulario 42. Muy bien. Le falta la fotocopia del formulario 42.
  - **Tú:** ¿Una fotocopia… del mismo formulario?
  - **Funcionaria de la ventanilla:** Claro. ¿Cómo voy a saber que es el formulario 42 si no tengo una copia del formulario 42? Hágala en el banco. Ventanilla 2.
- **Paso 3 · Hablar** con Funcionaria de la ventanilla — «Ventanilla 2: el banco (la misma señora… ¿cómo ha llegado antes que tú?)»
  - _Lugar:_ el Banco Valmar
  - **Funcionaria de la ventanilla:** Buenos días. Formulario 42 con fotocopia. Muy bien. ¿Y el sello de la policía que certifica que la fotocopia es una fotocopia?
  - **Tú:** ¿Usted no estaba en Correos?
  - **Funcionaria de la ventanilla:** Yo estoy en todas las ventanillas. Es mi trabajo. Nadie sabe cómo. Ni yo. Comisaría. Ventanilla 3. Y no se le olvide sonreír en la foto.
- **Paso 4 · Hablar** con Agente Inés — «Ventanilla 3: la comisaría (necesitas un sello de la policía)»
  - _Lugar:_ la comisaría · _En escena:_ Agente Inés, Funcionaria de la ventanilla
  - **Agente Inés:** ¿Un sello para certificar que una fotocopia es una fotocopia de un formulario del tiempo? …Llevo veinte años de policía y hoy es el día más raro.
  - ❓ **Pregunta al jugador:** ¿Cómo la convences?
    - ➤ «Por favor. Es para que no multen a mi vecino.» _(efecto: Agente Inés +4; empatia +1)_
      - **Agente Inés:** ¿El de las explosiones verdes? …Vale. Toma. Sello. Y dile que la próxima vez avise antes de explotar.
    - ➤ «Si no me lo pone, la señora de la ventanilla vendrá aquí.» _(efecto: humor +1)_
      - **Funcionaria de la ventanilla:** (Desde detrás de Inés, sin que nadie la haya visto llegar) Ya estoy aquí.
      - **Agente Inés:** ¡AH! ¡Toma el sello! ¡Toma diez sellos! ¡Fuera todos de mi comisaría!
- **Paso 5 · Hablar** con Agente Cronos, de Aduanas del Tiempo — «Vuelve al garaje con el formulario sellado»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Agente Cronos, de Aduanas del Tiempo
  - **Agente Cronos, de Aduanas del Tiempo:** Formulario 42, fotocopia, sello de la fotocopia. Perfecto. _[plano Medio de Agente Cronos, de Aduanas del Tiempo]_
  - **Agente Cronos, de Aduanas del Tiempo:** En cuatrocientos años, nadie lo había conseguido en el mismo día. Me ha impresionado. _[gesto Surprised]_
  - **Agente Cronos, de Aduanas del Tiempo:** Le daré un consejo, pequeño humano, gratis, que en la Aduana es rarísimo. _[en la pausa: Mira]_
  - **Agente Cronos, de Aduanas del Tiempo:** Esa grieta no es un accidente. Alguien del otro lado tira de ella. Tira fuerte. Hacia usted. _[plano PrimerPlano de Agente Cronos, de Aduanas del Tiempo · silencio 0.5 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Por qué hacia usted, no lo sé. No tengo el formulario de eso. _[en la pausa: Piensa]_
  - **Agente Cronos, de Aduanas del Tiempo:** Pero volveremos a vernos. Muchas veces. Lo pone en mi agenda. Mi agenda es del futuro.
  - **Cosme:** …Gracias, criatura. De verdad. Nunca nadie había hecho un trámite por mí. _[plano Reaccion de Cosme · gesto Happy]_
  - **Cosme:** Es lo más bonito que me han hecho desde que Pip me planchó los calcetines.
  - _Narrador:_ _Recibes 📄 el Sello de la Aduana del Tiempo. Cronos te lo regala: «Uno de repuesto. Nunca se sabe cuándo hay que sellar algo»._

**Al terminar (momento de la biografía):** «Sobreviviste a la burocracia del tiempo»

---

### Saga_05_Perdidas · «La noche de las cosas perdidas»

**Resumen:** Esta noche la Grieta ha absorbido todo lo que se ha perdido alguna vez en Valmar. Y lo ha escupido en el gimnasio del cole.

_Tipo: Saga de la Grieta · Acto I (5/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a el colegio. «El gimnasio del cole está lleno hasta el techo de cosas perdidas. Ramón, el conserje, no da crédito»

**Requisitos:** has terminado «La ventanilla 42» y entre las 19:00 y las 6:00 y etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Ramón — «Habla con Ramón en la entrada del cole»
  - _Lugar:_ el colegio · _En escena:_ Ramón, Pip
  - **Ramón:** Treinta años de conserje. Treinta. He visto de todo. _[plano Medio de Ramón]_
  - **Ramón:** Pero esto… El gimnasio está lleno de cosas perdidas. De todo Valmar. De todas las épocas. _[ademán Point · en la pausa: Respira]_
  - **Ramón:** Hay un bolso de 1950. Una dentadura de 1972. Y un pato de goma que no deja de mirarme. _[gesto Nervous]_
  - **Pip:** La Grieta absorbe todo lo que se pierde y lo devuelve donde le da la gana. _[a Ramón]_
  - **Pip:** El señor Cosme dice que es «un fallo de la papelera cósmica». Sugiere devolver lo importante primero.
  - 🎬 **Escena de cámara «Grieta_Grande»**
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Encuentra en el gimnasio las cosas más importantes y devuélvelas»
  - _En escena:_ Pip (te acompaña)
  - **Paso 2.1 · Usar** — «Unas llaves muy viejas»
    - 🖐 _Al usar «Un manojo de llaves antiguo»:_
      - _Narrador:_ _Un manojo de llaves oxidadas con una etiqueta: «Conserjería, 1994»._
      - _Narrador:_ _Ramón las lleva buscando treinta años. Siempre dijo que las tenía «en algún sitio»._
  - **Paso 2.2 · Usar** — «Un balón firmado»
    - 🖐 _Al usar «Un balón firmado»:_
      - _Narrador:_ _Un balón firmado por todo un equipo de fútbol. Con rotulador infantil: «De Nico. NO TOCAR». Es el que perdió en el torneo._
  - **Paso 2.3 · Usar** — «Un diario amarillo»
    - 🖐 _Al usar «Un diario con candado»:_
      - _Narrador:_ _Un diario amarillo con candado. En la portada: «Lucía, 3.º B, 1998. PRIVADO. Si lo lees, eres un cotilla»._
      - ❓ **Pregunta al jugador:** ¿Lo abres?
        - ➤ «No. Es de Lucía.» _(efecto: Profe Lucía +3; responsabilidad +1)_
        - ➤ «Solo la primera página…» _(efecto: curiosidad +1)_
          - _Narrador:_ _Primera página: «Hoy he decidido que de mayor seré profe. Y que no le leeré el diario a nadie. Ni a los cotillas»._
          - _Narrador:_ _…Cierras el diario muy despacio._ _[silencio 0.6 s]_
- **Paso 3 · Varios objetivos (en cualquier orden)** — «Devuelve cada cosa a su dueño»
  - _Lugar:_ el patio · _En escena:_ Ramón, Nico, Profe Lucía
  - **Paso 3.1 · Hablar** con Ramón — «Las llaves, a Ramón»
    - **Ramón:** ¡Mis llaves de 1994! ¡Con estas se abre la sala del reloj! Nadie ha entrado ahí desde entonces. _[gesto Surprised]_
    - **Ramón:** …Otro día te cuento. O no. Gracias, de verdad. _[en la pausa: Piensa]_
  - **Paso 3.2 · Hablar** con Nico — «El balón, a Nico»
    - **Nico:** ¡MI BALÓN! ¡El del torneo! ¡Lo busqué por todas partes! ¿Dónde estaba? ¿En el cielo? …¿Cómo que en el cielo?
  - **Paso 3.3 · Hablar** con Profe Lucía — «El diario, a Lucía»
    - **Profe Lucía:** Mi diario… de cuando tenía tu edad. Lo perdí en una excursión. ¿Lo has leído?
    - **Profe Lucía:** No me contestes. Tu cara ya me ha contestado. _[gesto ArmsCrossed · en la pausa: Mira]_
    - **Profe Lucía:** …Gracias. De verdad. Hay cosas que perdemos y no sabemos que las echábamos de menos. _[gesto Happy · silencio 0.6 s]_
    - _Narrador:_ _Del gimnasio sale un ruido enorme. Como si mil pies arrastraran calcetines a la vez._
- **Paso 4 · Pelea** — «¡Del montón sale el Monstruo de los Calcetines Desparejados! Empareja sus calcetines»
  - _Lugar:_ Gimnasio · _En escena:_ Pip
  - 🚨 _Si te atrapan:_ «¡ABRAZO DE CALCETÍN! (Hueles a pie durante una semana. Vuelves a la entrada.)»
- **Paso 5 · Escena**
  - **Pip:** Monstruo emparejado. El señor Cosme estará orgulloso. Bueno, dirá que es lo mínimo. Pero estará orgulloso. _[gesto Happy]_
  - **Pip:** Hay un problema: esta vez lo ha visto todo el barrio. Ramón, Lucía, Nico. Los vecinos hablan. _[en la pausa: Piensa]_
  - **Pip:** Y la Grieta crece. El señor Cosme dice que hay que coserla. Ya. _[plano PrimerPlano de Pip]_
  - _Narrador:_ _En el suelo queda un único calcetín. Verde. Sin pareja. Te mira. Te lo quedas. Recibes 🧦 el Calcetín solitario._

**Al terminar (momento de la biografía):** «Devolviste las cosas perdidas de Valmar»

---

### Saga_06_Coser · «Coser el cielo»

**Resumen:** Cosme ha terminado la aguja cuántica. Esta noche se cose la Grieta. Hacen falta tres anclajes, un pulso firme y alguien muy valiente.

_Tipo: Saga de la Grieta · Acto I (6/6) · Final del acto · Duración: 30-40 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Esta noche se cose el cielo. Cosme te espera»

**Requisitos:** has terminado «La noche de las cosas perdidas» y entre las 19:00 y las 6:00 y etapa desde Nino

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Cosme te explica el plan»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** La aguja cuántica. Mi obra maestra. _[plano Medio de Cosme · gesto Happy]_
  - **Cosme:** Bueno, la tercera: la primera fue el microondas y la segunda, un peine que peina hacia el pasado. No preguntes. _[gesto Shrug]_
  - **Cosme:** Plan: tres anclajes en tres sitios de Valmar. Forman un triángulo. _[ademán Point]_
  - **Cosme:** La aguja, en el centro, cose la grieta. Como un botón. Un botón del tamaño del cielo. _[en la pausa: Respira]_
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** Y el Consorcio lo sabe. Mis antiguos compañeros vigilan el parque y la plaza. _[plano Medio de Don Escamas]_
  - **Don Escamas:** Yo les he calculado la ruta: si no te ven, no te ven. Es contabilidad básica.
  - _(si tienes la marca «sabe de cosimo»)_ **Cosme:** Y sí. Sé que no se te ha olvidado la moneda. Ni el nombre. _[en la pausa: Baja]_
  - ❓ **Pregunta al jugador:** Antes de salir, le preguntas a Cosme:
    - ➤ «¿Quién es Cósimo de verdad?» _(efecto: curiosidad +1)_
      - **Cosme:** Mi mejor amigo. Hace mucho. Construimos juntos la máquina que abrió esto. _[gesto Sad · en la pausa: Aparta]_
      - **Cosme:** Una noche salió mal y él… se cayó. Al otro lado. _[silencio 0.6 s]_
      - **Cosme:** Por mi culpa. O por la suya. Llevo años sin saberlo. _[plano PrimerPlano de Cosme · gesto Sad]_
    - ➤ «¿Por qué la Grieta tira hacia mí?» _(efecto: valentia +1)_
      - **Cosme:** …Porque eres importante. Para mí, desde luego. Para el universo, un poquito también. _[en la pausa: Piensa]_
      - _(si tienes la marca «oyo ancla»)_ **Cosme:** Y no le hagas caso al pez cuando habla de anclas. Los peces exageran.
      - **Cosme:** Te lo contaré cuando seas mayor. Te lo juro por mi batido.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Clava los tres anclajes (cuidado: el Consorcio vigila)»
  - _Lugar:_ el parque · _En escena:_ Agente de MegaVerso
  - **Paso 2.1 · Usar** — «Anclaje del parque»
    - 🖐 _Al usar «Anclaje del parque»:_
      - _Narrador:_ _Clavas el cristal en el suelo. Suena como una campana muy lejos. En el cielo, la Grieta tiembla._
  - **Paso 2.2 · Usar** — «Anclaje del patio del cole»
    - 🖐 _Al usar «Anclaje del cole»:__(la misma conversación «Anclaje» de arriba)_
  - **Paso 2.3 · Usar** — «Anclaje de la plaza del centro»
    - 🖐 _Al usar «Anclaje de la plaza»:__(la misma conversación «Anclaje» de arriba)_
- **Paso 3 · Pelea** — «¡Los agentes grises quieren robar la aguja! Apágales el comunicador (0/2)»
  - _Lugar:_ el patio · _En escena:_ Cosme, Pip
  - 🚨 _Si te atrapan:_ «¡Oferta exclusiva! ¡Firme aquí! (Consigues no firmar. Vuelves junto a la aguja.)»
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Grieta_Coser»** _(música: → Tension → Descubrimiento → Tema efecto Momento)_
    - _En escena:_ Cosme, Pip
    - _Cámara:_ 7 planos (General, Inserto, Reaccion, DosPlanos, Dolly)
    - 🪧 _Rótulo:_ «🪡 El cielo está cosido» — Fin del Acto I · La Grieta
    - **Cosme:** Tres anclajes. Una aguja. Un cielo entero. _[plano Medio de Cosme · emoción Nervous]_
    - **Cosme:** …Allá vamos.
    - **Pip:** Puntada… puntada… puntada. Mis sensores lloran aceite.
    - **Cosme:** …Se ha cerrado. Pip. Pip, mira. Se ha cerrado. _[a Pip · emoción Surprise]_
    - 🔀 **Variante «Barrio»** (si tienes la marca «vecinos notan rarezas»): cambia Dialogue por:
      - **Cosme:** Tres anclajes. Una aguja. Un cielo entero. _[plano Medio de Cosme · emoción Nervous]_
      - **Cosme:** …Allá vamos.
      - **Pip:** Medio barrio está en la ventana. Ramón, con sus llaves de 1994.
      - **Cosme:** …Se ha cerrado. Pip. Pip, mira. Se ha cerrado. _[a Pip · emoción Surprise]_
- **Paso 5 · Escena**
  - **Cosme:** ¡LO HEMOS HECHO! ¡Cosido! ¡Como un calcetín! ¡Soy un genio! ¡Somos unos genios! _[plano Medio de Cosme · ademán Cheer]_
  - **Cosme:** ¡Tú eres un genio en miniatura, yo uno grande! _[gesto Laugh]_
  - _Narrador:_ _Entonces, del último punto de la costura sale una voz. Elegante. Tranquila. Como un presentador de concursos a medianoche._ _[silencio 1.0 s]_
  - **Doctor Cósimo:** Bravo, Cosme. Precioso trabajo de costura. Siempre fuiste el de las manualidades. _[plano Reaccion de Cosme]_
  - **Doctor Cósimo:** Y tú… hola. Por fin te veo la cara. Qué grande estás. _[plano Reaccion de Tú · silencio 0.6 s]_
  - **Doctor Cósimo:** La última vez eras así de chiquitín/chiquitina. Ya te he visto, Ancla. _[plano Reaccion de Tú]_
  - **Doctor Cósimo:** Nos veremos pronto. Las costuras… siempre se sueltan. _[plano Reaccion de Pip]_
  - **Cosme:** (Silencio. La costura brilla un momento y se apaga. Cosme se ha quedado blanco como su bata.) _[plano PrimerPlano de Cosme · gesto Surprised · silencio 1.2 s]_
  - **Pip:** Señor. Tiene que contárselo. Algún día. _[a Cosme · en la pausa: Mira]_
  - **Cosme:** Algún día, Pip. No hoy. Hoy hemos cosido el cielo. Hoy… a cenar. _[a Pip · en la pausa: Respira]_
  - **Cosme:** Criatura: te quedas la aguja. Tú la has hecho funcionar. Siempre has sido tú. _[plano DosPlanos de Cosme → Tú · gesto Happy]_
  - _Narrador:_ _Recibes 🪡 la Aguja cuántica. FIN DEL ACTO I. La Grieta está cosida… por ahora._

**Al terminar (momento de la biografía):** «Cosiste el cielo de Valmar (por ahora)»

---


# Capítulo «El instituto»

_Id: Adolescente_Instituto · Etapa: Adolescente · Música de fondo: TemaValmar_

**Texto de entrada del capítulo:** «Nuevo instituto, nuevos amigos y una gran pregunta: ¿qué harás de mayor?»

- 🎬 **Cabecera del capítulo (cinemática) «Ins_Entrada»** _(vuelo de cámara, 9 s, 2 planos; música: TemaValmar)_
  - 🪧 _Rótulo:_ «El instituto» — Nuevo instituto, nuevos amigos y una gran pregunta: ¿qué harás de mayor?

_Entre misión y misión se repite un «día normal» generado (Adol_Jornada): no se exporta, no es guion fijo._

### Ins01_NuevoInstituto · «El nuevo instituto»

**Resumen:** Septiembre. Un edificio enorme, gente mayor que tú, tu grupo repartido en clases distintas… y alguien nuevo que no conoce a nadie.

_Tipo: Historia · Nueva etapa · Edad: 12-13 años · Duración: 20-30 min_

**Lo que puede cambiar:** Dónde te sientas · El grupo en el recreo · Hablar con Leire o no

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Tres meses después. Septiembre.»
  - ⏳ _Pantalla de transición:_ «Tres meses después. Septiembre.»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡[tu nombre]! Primer día de instituto. ¿Estás bien? ¿Tienes de todo? ¿Quieres que te acompañe?
  - **Abu:** Déjale respirar, que ya es mayor. Bueno, un poco mayor. Lo justo.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Acompáñame hasta la puerta, porfa» _(efecto: Mamá/Papá +4; decisión «primer dia ins» = Acompanado)_
      - **Mamá/Papá:** ¡Hasta la puerta de casa! Ni un paso más, prometido. …Bueno, hasta la esquina.
    - ➤ «Puedo ir por mi cuenta. Pero gracias.» _(efecto: valentia +1; decisión «primer dia ins» = Solo)_
      - **Mamá/Papá:** Vale, vale. Qué rápido pasa todo. Ayer tenías la mochila más grande que tú.
  - **Abu:** Un consejo de los de antes: el primer día, sonríe a una persona que no conozcas. Solo a una. Ya verás.
- **Paso 3 · Ir a** la parada del autobús — «Ve a la parada del autobús: tus amigos te esperan»
  - _Lugar:_ la parada del autobús · _En escena:_ Nico, Omar, Sara, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
  - ⏰ _Si tardas, Omar dice:_ «(mensaje) ¿Dónde estás? El bus pasa en nada. Te guardo sitio. Y medio cruasán.»
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Ins01_Parada»** _(música: intensidad Nada)_
    - _En escena:_ Nico, Omar, Sara, Mateo, Hugo
    - _Cámara:_ 2 planos (General, Pan)
    - **Sara:** Omar. ¿Has crecido o te has subido a algo? _[a Omar · plano Hombro de Sara → Omar]_
    - **Omar:** Me he chocado dos veces con el marco de la puerta. Mi madre dice que es la edad. _[plano Medio de Omar · gesto Shrug]_
    - _(si tienes la marca «llegas tarde parada»)_ **Nico:** ¡[tu nombre]! ¡Por fin! El conductor no espera a nadie. _[plano PrimerPlano de Nico]_
    - _(si NO se cumple: tienes la marca «llegas tarde parada»)_ _(o bien)_ **Nico:** ¡[tu nombre]! Antes que el autobús. Eso es de cuarto, como mínimo. _[plano PrimerPlano de Nico · gesto Happy]_
    - **Sara:** Me han puesto en el bilingüe. No vamos a estar en la misma clase. Lo he comprobado tres veces. _[plano PrimerPlano de Sara · gesto Sad · en la pausa: Suelo]_
    - _(si en «promesa» elegiste «Juntos»)_ **Nico:** Pero en el recreo sí. ¡Lo prometimos! _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «promesa» elegiste «Nuevos»)_ _(o bien)_ **Nico:** Prometimos conocer gente nueva sin olvidarnos. Hoy empieza lo de «gente nueva». _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «promesa» elegiste «Banco»)_ _(o bien)_ **Nico:** Y el banco del parque en verano sigue en pie. Eso no lo cambia ningún instituto. _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Omar:** Los Imparables: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Omar:** La Patrulla Valmar: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Omar:** Los del Banco Azul: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Omar:** Los Dinosaurios: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** He traído un libro por si nadie me habla. Ojalá no tenga que leerlo. _[plano Reaccion de Hugo]_
    - _(si tienes la marca «ayudaste a mateo» y NO tienes la marca «hugo con el grupo»)_ _(o bien)_ **Mateo:** Me apunté el aula en la mano. Se me ha borrado con el sudor. _[plano Reaccion de Mateo · gesto Nervous]_
    - _(si NO tienes las marcas «hugo con el grupo» y «ayudaste a mateo»)_ _(o bien)_ **Sara:** Si alguien se pierde, tengo el plano del instituto. Impreso. Plastificado. _[plano Medio de Sara]_
    - **Omar:** ¡El autobús! Ese que pone «Campus Valmar». Vamos, que yo me mareo si voy de pie. _[plano Medio de Omar · en la pausa: Senalar]_
    - **Nico:** ¡El último en subir se sienta al lado del conductor! _[plano General · gesto Happy]_
- **Paso 5 · Acción del jugador** — «Coge el autobús al Campus Valmar»
- **Paso 6 · Ir a** el instituto — «Busca la entrada del instituto»
  - _Lugar:_ el instituto · _En escena:_ Alumno de 4.º, Delegada de 4.º, Iker (si tienes la marca «iker en el grupo»), Omar (te acompaña), Alumno, Alumna
- **Paso 7 · Escena**
  - _Narrador:_ _El instituto es tres veces el colegio. Pasillos, escaleras, gente que parece adulta. Nadie os mira. O eso parece._
  - **Alumno de 4.º:** ¿Los de primero? Uy, qué pequeños. El aula de primero está en el tercer piso. Coged el ascensor de alumnos, ahí a la izquierda.
  - **Omar:** ¿Hay ascensor de alumnos? Qué moderno. …¿Hay ascensor de alumnos?
- **Paso 8 · Decisión** — «¿Le haces caso al veterano (el «ascensor de alumnos») o buscas por tu cuenta?»
  - ➤ **Opción «Esperar el ascensor»** _(efecto: decisión «veterano» = Creer; humor +1)_
    - _Narrador:_ _Esperas delante de una puerta que pone «CUARTO DE LIMPIEZA». Pasa un minuto. Detrás, se oyen risas._
    - **Alumno de 4.º:** ¡Todos los años alguien cae! Tranqui, a mí me lo hicieron también. El aula de 1.º C está en la planta baja, al fondo.
    - **Omar:** Esto lo cuento en la cena y me río. Dentro de unos años.
    - 🖐 _Al usar ««Ascensor de alumnos»»:__(la misma conversación «Ascensor» de arriba)_
  - ➤ **Opción «Preguntar a la delegada»** (con Delegada de 4.º) _(efecto: decisión «veterano» = Dudar; curiosidad +1)_
    - **Delegada de 4.º:** ¿El ascensor de alumnos? No existe. Todos los años lo dicen. Ignóralo.
    - **Delegada de 4.º:** Los de primero estáis en la planta baja. Mira el tablón y busca tu nombre. Y si necesitas algo, soy la delegada de cuarto.
- **Paso 9 · Usar** — «Busca tu clase en el tablón»
  - 🖐 _Al usar «Tablón de clases»:_
    - _Narrador:_ _Listas y listas de nombres. 1.º A, 1.º B, bilingüe… 1.º C: ahí estás. Y Omar. Y Nico. Y… Bruno._
    - **Omar:** ¿Bruno? ¿Otra vez? Esto ya es el destino.
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** Yo también estoy en 1.º C. Me descargué el plano en julio: planta baja, tercera puerta, la de la ventana rota.
- **Paso 10 · Ir a** tu aula del instituto — «Ve al aula de 1.º C»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Nico, Leire, Bruno, Iker (si tienes la marca «iker en el grupo»), Alumno, Alumna
- **Paso 11 · Escena**
  - _(si NO tienes la marca «llegas tarde instituto»)_ **Javier:** Buenos días, 1.º C. Soy Javier, vuestro tutor. Os daré Historia. Y alguna charla que no me habéis pedido.
  - _(si tienes la marca «llegas tarde instituto»)_ **Javier:** Ah, llega [tu nombre]. El primer día, perdonado. Se pierde todo el mundo. Yo me perdí mi primer año de profe.
  - **Javier:** Aquí nadie os va a llevar de la mano. Pero si os perdéis, preguntad. Preguntar no es de pequeños: es de listos.
  - **Javier:** Tenemos una alumna nueva: Leire, que viene del norte. Leire, ¿quieres decir algo? _[a Leire · plano Medio de Javier]_
  - **Leire:** No. _[a Javier · plano PrimerPlano de Leire · gesto ArmsCrossed · en la pausa: Mira · silencio 1.0 s]_
  - **Javier:** Directa. Me gusta. _[plano Medio de Javier · en la pausa: Sonrie · silencio 0.8 s]_
  - **Javier:** Sentaos donde queráis. El sitio de hoy suele ser el de todo el año, así que pensadlo.
  - _(si en «adios bruno» elegiste «DeCero»)_ **Bruno:** (desde el fondo) Eh, [tu nombre]. Aquí hay sitio. Si quieres. De cero, ¿no?
- **Paso 12 · Decisión** — «¿Dónde te sientas? (habla con quien elijas)»
  - ➤ **Opción «Con Omar, como siempre»** (con Omar) _(efecto: decisión «sitio instituto» = Omar; Omar +5)_
    - **Omar:** Lo sabía. Te he guardado el sitio desde las ocho menos cuarto. Sabía que vendrías.
  - ➤ **Opción «Con la chica nueva»** (con Leire) _(efecto: decisión «sitio instituto» = Leire; Leire +8; empatia +1)_
    - **Leire:** …Vale. Siéntate. Pero no me preguntes por la cámara. Todo el mundo me pregunta por la cámara. _[plano PrimerPlano de Leire · en la pausa: Mira]_
    - **Leire:** …Es de mi abuelo. Es de carrete. Hace fotos de verdad. _[en la pausa: Baja · silencio 1.2 s]_
    - **Leire:** Bueno, ya te lo he contado. Qué rabia. _[gesto Facepalm · silencio 0.5 s]_
  - ➤ _(si en «adios bruno» elegiste «DeCero»)_ **Opción «Con Bruno (¿empezar de cero?)»** (con Bruno) _(efecto: decisión «sitio instituto» = Bruno; Bruno +8)_
    - **Bruno:** ¿En serio? Vale. Normas: no me copies en los exámenes. Y yo tampoco a ti. Eso lo añado ahora.
    - **Bruno:** …Oye, que aquí no conozco a nadie tampoco. Está bien tener a alguien conocido.
- **Paso 13 · Clase** — «Clase de Historia con Javier»
- **Paso 14 · Ir a** el patio — «Sal al recreo»
  - _Lugar:_ el patio · _En escena:_ Omar, Sara, Nico, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Leire, Alumno de 4.º, Alumna, Alumno
  - 💬 _Comentario al pasar cerca de Nico:_ «¡Pásala! ¡Aquí!»
- **Paso 15 · Escena**
  - _Narrador:_ _El patio del instituto es enorme y cada grupo tiene su rincón. El vuestro… todavía no existe._
  - **Sara:** ¡Os he encontrado! En mi clase hablan de cosas rarísimas. De series. Yo quería hablar de hongos.
  - _Narrador:_ _Nico juega al fútbol con los de segundo. Te saluda con la mano… y sigue jugando._
  - **Omar:** Nico ya tiene amigos nuevos. Está bien, ¿no? Está bien. Me lo digo a mí mismo.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Esto es nuestro rincón desde hoy.» Te sientas con Omar y Sara _(efecto: Omar +3; Sara +3; decisión «recreo ins» = Rincon)_
      - **Sara:** Declaramos este banco territorio del grupo. Con sus derechos y sus bocadillos.
    - ➤ «Vas a jugar con Nico y los de segundo» _(efecto: Nico +5; deportividad +1; decisión «recreo ins» = Nico)_
      - **Nico:** ¡[tu nombre]! ¡Menos mal! Estos de segundo son buenos, pero no se saben nuestras jugadas.
    - ➤ «Das una vuelta para conocer el instituto» _(efecto: curiosidad +1; decisión «recreo ins» = Explorar)_
      - _(si NO tienes la marca «conoces a leire»)_ _Narrador:_ _Laboratorios, un gimnasio con gradas, una biblioteca con sillones… y, en un banco apartado, Leire comiendo sola._
      - _(si tienes la marca «conoces a leire»)_ _Narrador:_ _Laboratorios, un gimnasio con gradas, una biblioteca con sillones. Leire te saluda desde lejos con la cámara._
- **Paso 16 · Hablar** con Leire — «Leire come sola en un banco. ¿Vas?» _(solo si NO tienes la marca «conoces a leire»)_
  - **Leire:** ¿Qué? Estoy bien sola. _[plano Medio de Leire · gesto ArmsCrossed · en la pausa: Aparta]_
  - **Leire:** …Vale, no mucho. _[plano PrimerPlano de Leire · gesto Ashamed · en la pausa: Baja · silencio 1.2 s]_
  - **Leire:** En mi otra ciudad tenía un grupo. Ahora tengo una cámara y un bocadillo de chorizo. _[plano Hombro de Tú → Leire · en la pausa: Mira]_
  - **Leire:** El bocadillo es buena compañía. Pero no habla. _[gesto Shrug · silencio 0.6 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Vente con nosotros. Omar trae comida para todos.» _(efecto: Leire +10; Omar +2; empatia +2; marca «conoces a leire»)_
      - **Omar:** (desde lejos) ¡Es verdad! ¡Traigo de todo! ¡Hasta aceitunas!
      - **Leire:** …Vale. Pero si son pesados, me vuelvo al banco.
    - ➤ «¿Me enseñas qué fotos haces?» _(efecto: Leire +8; curiosidad +1; marca «conoces a leire»)_
      - **Leire:** Nadie me pregunta por las fotos. Solo por la cámara. …Mira. Esta es mi antigua calle. Y esta, el mar.
- **Paso 17 · Clase** — «Clase de Matemáticas»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Nico, Leire, Bruno, Iker (si tienes la marca «iker en el grupo»), Alumno, Alumna
- **Paso 18 · Transición (pasa el tiempo)** — «Por la tarde…»
  - ⏳ _Pantalla de transición:_ «Por la tarde…»
- **Paso 19 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Cuéntalo todo! ¿Cómo es? ¿Es grande? ¿Te has perdido? ¿Has comido?
  - _(si en «veterano» elegiste «Creer»)_ **Mamá/Papá:** ¿El ascensor de alumnos? ¡A mí me lo hicieron también! Hay cosas que no cambian nunca.
  - _(si tienes la marca «conoces a leire»)_ **Mamá/Papá:** ¿Una compañera nueva que se llama Leire? Qué bien que te hayas acercado. Empezar en una ciudad nueva es muy difícil.
  - **Abu:** ¿Y a quién le sonreíste? …Ah, se nota. Se nota en la cara.
  - _Narrador:_ _Esa noche, antes de dormir, piensas que el instituto da un poco de miedo. Y que también tiene pinta de ser muy divertido._

**Al terminar (momento de la biografía):** «Tu primer día de instituto»

---

### Ins02_Clubes · «Los clubes»

**Resumen:** Feria de clubes en el instituto. Elige el tuyo… y descubre que cada club es un mundo.

_Tipo: Historia · Instituto · Edad: 13-13 años · Duración: 20-30 min_

**Requisitos:** has terminado «El nuevo instituto» y has vivido el 12 % de la etapa

**Lo que puede cambiar:** Tu club (cinco caminos) · Publicar o proteger un secreto · Club, cumpleaños o las dos cosas

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unas semanas después…»
  - ⏳ _Pantalla de transición:_ «Unas semanas después…»
- **Paso 2 · Ir a** el patio — «Ve al patio: hoy es la feria de clubes»
  - _Lugar:_ el patio · _En escena:_ Javier, Álex, Rubén, Sara, Hugo, Leire, Omar (te acompaña), Alumno
- **Paso 3 · Escena**
  - **Javier:** Feria de clubes. Uno por persona, que luego no dormís. Elegid algo que os guste, no lo que elijan vuestros amigos.
  - **Omar:** Yo me apunto al tuyo. Lo que ha dicho Javier no me afecta. Soy inmune.
  - _Narrador:_ _Cinco puestos, cinco mundos: baloncesto, teatro, robótica, el periódico del instituto y fotografía._
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Visita los puestos (al menos tres)»
  - **Paso 4.1 · Usar** — «Baloncesto»
    - 🖐 _Al usar «Puesto de baloncesto»:_
      - **Álex:** ¡[tu nombre]! Soy la capitana del equipo de primero. Hacemos prueba el martes. Sin favoritismos. Bueno, un poco.
  - **Paso 4.2 · Usar** — «Teatro»
    - 🖐 _Al usar «Puesto de teatro»:_
      - **Rubén:** ¿Teatro? Aquí se viene a hacer el ridículo con estilo. Yo empecé para no esconderme más. Funciona.
      - _(si en «mochila ruben» elegiste «Perdon»)_ **Rubén:** Y… me alegro de verte. De verdad. Lo de la mochila fue hace mil años.
  - **Paso 4.3 · Usar** — «Robótica»
    - 🖐 _Al usar «Puesto de robótica»:_
      - **Sara:** Robótica: construimos robots que hacen cosas. Bueno, que INTENTAN hacer cosas. Este año, uno que reparte bocadillos.
      - **Omar:** ¿Reparte bocadillos? Me apunto mentalmente.
  - **Paso 4.4 · Usar** — «Periódico»
    - 🖐 _Al usar «Puesto del periódico»:_
      - **Hugo:** El periódico «La Voz del Campus». Somos tres. Buscamos gente que haga preguntas incómodas. Educadamente.
      - **Hugo:** Mi primer reportaje: alguien pinta murales por la noche en el patio. Nadie sabe quién. Es un misterio de verdad.
  - **Paso 4.5 · Usar** — «Fotografía»
    - 🖐 _Al usar «Puesto de fotografía»:_
      - **Leire:** Fotografía. El club soy yo. Y mi tío Toni, que viene los viernes y sabe de vídeo. No es un club muy grande.
      - **Leire:** Pero si vienes, salimos por el campus a hacer fotos. Enseña mucho más que el aula.
- **Paso 5 · Decisión** — «¿A qué club te apuntas? (habla con quien lo lleva)»
  - ➤ **Opción «Baloncesto, con Álex»** (con Álex) _(efecto: decisión «club» = Baloncesto; Álex +5)_
    - **Álex:** ¡Bien! El martes, prueba. Ven con zapatillas. Y con ganas. Las zapatillas son opcionales. Las ganas no.
  - ➤ **Opción «Teatro, con Rubén»** (con Rubén) _(efecto: decisión «club» = Teatro; Rubén +5)_
    - **Rubén:** ¿De verdad? ¡Pasa al lado divertido! Audición mañana. Tranqui: suspende casi todo el mundo y luego entra igual.
  - ➤ **Opción «Robótica, con Sara»** (con Sara) _(efecto: decisión «club» = Robotica; Sara +5)_
    - **Sara:** ¡Sí! Tú, yo y un robot. Como en los viejos tiempos, pero con cables.
  - ➤ **Opción «Periódico, con Hugo»** (con Hugo) _(efecto: decisión «club» = Periodico; Hugo +5)_
    - **Hugo:** ¡Genial! Tu primer caso: los murales. Llévate libreta. Y paciencia. Los buenos reportajes son lentos.
  - ➤ **Opción «Fotografía, con Leire»** (con Leire) _(efecto: decisión «club» = Fotografia; Leire +6)_
    - **Leire:** ¿En serio? …Vale. Ya somos dos. Esto ya parece un club. Casi.
- **Paso 6 · Ir a** la pista de deporte — «Ve a la pista: prueba del equipo» _(solo si en «club» elegiste «Baloncesto»)_
  - _Lugar:_ la pista de deporte · _En escena:_ Álex (si en «club» elegiste «Baloncesto»), Omar (si en «club» elegiste «Baloncesto») (te acompaña)
- **Paso 7 · Escena** _(solo si en «club» elegiste «Baloncesto»)_
  - **Álex:** Tiros desde la línea. Ocho balones. Con cuatro, entras de titular. Con menos, entras igual, pero calientas banquillo.
  - **Omar:** Yo he venido de apoyo moral. Tengo hasta un cartel. Pone «ÁNIMO». Me he quedado sin cartulina para el nombre.
- **Paso 8 · Minijuego** — «Prueba: tiros desde la línea» _(solo si en «club» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Cada tiro, más difícil. Necesitas 4.
- **Paso 9 · Ir a** tu aula del instituto — «Ve a tu aula: hoy es la audición de teatro» _(solo si en «club» elegiste «Teatro»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Rubén (si en «club» elegiste «Teatro»), Omar (si en «club» elegiste «Teatro») (te acompaña)
- **Paso 10 · Escena** _(solo si en «club» elegiste «Teatro»)_
  - **Rubén:** La audición: un monólogo de treinta segundos. Es de un pirata que ha perdido su barco. Tienes que decirlo con ritmo.
  - **Rubén:** ¿Nervios? Yo el primer día me temblaban hasta las cejas. Respira y mira a un punto fijo.
- **Paso 11 · Minijuego** — «Audición: di el texto con ritmo» _(solo si en «club» elegiste «Teatro»)_
  - 🎮 _Cómo se juega:_ Habla en la zona verde
- **Paso 12 · Ir a** tu aula del instituto — «Ve al laboratorio de robótica (aula)» _(solo si en «club» elegiste «Robotica»)_
  - _En escena:_ Sara (si en «club» elegiste «Robotica»), Omar (si en «club» elegiste «Robotica») (te acompaña)
- **Paso 13 · Escena** _(solo si en «club» elegiste «Robotica»)_
  - **Sara:** Este es Tornillo. Tiene dos ruedas, un sensor y mala suerte. Hay que programarle para que siga una línea.
  - **Sara:** Tú metes las órdenes. Yo miro el sensor. Omar mira… lo que quiera.
- **Paso 14 · Minijuego** — «Programa al robot» _(solo si en «club» elegiste «Robotica»)_
  - 🎮 _Cómo se juega:_ Mete cada orden en la zona verde
- **Paso 15 · Usar** — «¡El robot se ha escapado! Atrápalo» _(solo si en «club» elegiste «Robotica»)_
  - _En escena:_ Sara (te acompaña)
  - 🖐 _Al usar «¡El robot!»:_
    - _Narrador:_ _¡Tornillo arranca solo y sale por la puerta! Casi lo tienes… ¡se escapa entre tus piernas!_
    - **Sara:** ¡Le he puesto la velocidad máxima sin querer! ¡O queriendo! ¡Ya no lo sé!
- **Paso 16 · Usar** — «¡Se ha ido al patio!» _(solo si en «club» elegiste «Robotica»)_
  - 🖐 _Al usar «¡El robot!»:_
    - _Narrador:_ _Tornillo cruza el patio. Unos de cuarto lo graban con el móvil. Uno le aplaude. Se escapa otra vez._
- **Paso 17 · Usar** — «¡Ahora va hacia la pista!» _(solo si en «club» elegiste «Robotica»)_
  - 🖐 _Al usar «¡El robot!»:_
    - _Narrador:_ _En la pista, Tornillo se choca con un cono, da una vuelta y se para. Lo coges. Está calentito. Parece contento._
    - **Sara:** ¡Lo tenemos! Técnicamente, ha seguido una línea: la de la pista. Lo apunto como éxito.
- **Paso 18 · Escena** _(solo si en «club» elegiste «Periodico»)_
  - _Lugar:_ el patio · _En escena:_ Hugo (si en «club» elegiste «Periodico»), Omar (si en «club» elegiste «Periodico») (te acompaña)
  - **Hugo:** Los murales aparecen los lunes por la mañana. Colores, pájaros, frases bonitas. El director está entre enfadado y encantado.
  - **Hugo:** Un buen periodista pregunta a varias personas y mira las pruebas. Nunca se fía de una sola.
- **Paso 19 · Varios objetivos (en cualquier orden)** — «Investiga quién pinta los murales por la noche» _(solo si en «club» elegiste «Periodico»)_
  - _En escena:_ Hugo (si en «club» elegiste «Periodico») (te acompaña), Alumno de 4.º (si en «club» elegiste «Periodico»), Delegada de 4.º (si en «club» elegiste «Periodico»)
  - **Paso 19.1 · Usar** — «Examina el mural nuevo»
    - 🖐 _Al usar «Un mural nuevo»:_
      - _Narrador:_ _Un pájaro enorme de colores, y debajo: «Aquí también se puede volar». Hay purpurina pegada en la pintura._
      - **Hugo:** ¿Purpurina? ¿Quién pinta un mural con purpurina?
      - _(si en «festival» elegiste «Decoracion»)_ _Narrador:_ _Tú conoces a alguien que lo pone todo con purpurina._
  - **Paso 19.2 · Hablar** con Alumno de 4.º — «Pregunta al veterano»
    - **Alumno de 4.º:** Yo vi a alguien el viernes con una mochila rosa llena de botes. Alguien de primero, fijo.
  - **Paso 19.3 · Hablar** con Delegada de 4.º — «Pregunta a la delegada»
    - **Delegada de 4.º:** La clave del gimnasio la tienen los clubes. El de arte usa el patio los viernes por la tarde. Solo una persona se queda hasta tarde.
- **Paso 20 · Hablar** con Vega — «Todas las pistas llevan a… Vega» _(solo si en «club» elegiste «Periodico»)_
  - _En escena:_ Hugo (te acompaña), Vega
  - **Vega:** …Vale. Soy yo. Lo hago porque el patio era gris y triste. Y porque nadie me ha pedido permiso para ser gris.
  - **Vega:** ¿Vais a publicarlo? Si sale mi nombre, el director me va a hacer limpiarlo todo.
  - ❓ **Pregunta al jugador:** ¿Qué hacéis con el reportaje?
    - ➤ «Publicarlo sin su nombre: «El artista misterioso»» _(efecto: Hugo +3; Vega +10; empatia +1; decisión «reportaje» = Anonimo)_
      - **Hugo:** Un buen periodista también protege a sus fuentes. Lo he leído. Y ahora lo entiendo.
    - ➤ «Convencerla para pedir permiso al director y pintar a la luz del día» _(efecto: Hugo +5; Vega +6; responsabilidad +2; decisión «reportaje» = Permiso)_
      - **Vega:** ¿Y si dice que no? …Vale. Si me acompañáis. Si dice que sí, el reportaje será mejor: «Una alumna pinta el instituto».
    - ➤ «Publicar su nombre: la verdad es la verdad» _(efecto: Hugo -2; Vega -8; valentia +1; decisión «reportaje» = Nombre)_
      - **Vega:** Genial. Gracias. De verdad, gracias por nada.
      - **Hugo:** …No sé si hemos hecho bien. A veces la verdad duele a alguien que no hacía daño.
- **Paso 21 · Escena** _(solo si en «club» elegiste «Fotografia»)_
  - _En escena:_ Leire (si en «club» elegiste «Fotografia»), Omar (si en «club» elegiste «Fotografia») (te acompaña)
  - **Leire:** Regla del club: no se hacen fotos de uno mismo. Se hacen fotos de lo que ves. Mi abuelo decía que así se aprende a mirar.
  - **Leire:** Vamos al campus: la universidad, la biblioteca y el estadio. Algún día estudiaremos ahí. O no. Pero quiero verlo.
- **Paso 22 · Varios objetivos (en cualquier orden)** — «Paseo fotográfico por el campus» _(solo si en «club» elegiste «Fotografia»)_
  - _En escena:_ Leire (te acompaña)
  - **Paso 22.1 · Usar** — «La universidad»
    - 🖐 _Al usar «La universidad»:_
      - _Narrador:_ _La facultad, enorme, con gente con carpetas corriendo. Clic. Parece un sitio donde pasan cosas importantes._
      - **Leire:** Mi madre estudió aquí. Dice que fueron los mejores años. Y los más cansados.
  - **Paso 22.2 · Usar** — «La biblioteca del campus»
    - 🖐 _Al usar «La biblioteca del campus»:_
      - _Narrador:_ _Una sala silenciosa llena de libros hasta el techo. Una estudiante dormida sobre un libro de anatomía. Clic. Leire se ríe bajito._
  - **Paso 22.3 · Usar** — «El estadio»
    - 🖐 _Al usar «El estadio»:_
      - _Narrador:_ _El estadio vacío al atardecer. Las gradas naranjas. Clic._
      - **Leire:** Esa es buena. Muy buena. …No se lo digas a nadie, pero eres mejor que yo encuadrando.
- **Paso 23 · Escena**
  - _En escena:_ Omar, Nico
  - **Nico:** ¡[tu nombre]! El sábado es mi cumpleaños. Trece. En el parque, a las cinco. Hay tarta. Y mi abuela hace croquetas.
  - **Omar:** …Y el sábado a las cinco es el primer evento de tu club. Lo he mirado. Lo siento. Soy el mensajero de las malas noticias.
  - ❓ **Pregunta al jugador:** ¿Qué haces el sábado?
    - ➤ «El club: es mi primer compromiso de verdad» _(efecto: Nico -4; responsabilidad +1; decisión «sabado» = Club; marca «solo club»)_
      - **Nico:** Ah. Vale. Lo entiendo. …Te guardo croquetas. Pocas.
    - ➤ «El cumpleaños de Nico: los amigos primero» _(efecto: Nico +8; decisión «sabado» = Cumple; marca «solo cumple»)_
      - **Nico:** ¡SÍ! Ya sabía yo. Te voy a dar la croqueta más grande.
    - ➤ «Intentar las dos cosas: el club y luego correr al parque» _(efecto: valentia +1; decisión «sabado» = Ambas; marca «intentas las dos»)_
      - **Omar:** Ambicioso. Me gusta. Te dejo mi bono de autobús por si acaso.
- **Paso 24 · Ir a** el patio — «El sábado: primer evento de tu club (patio del instituto)» _(solo si NO tienes la marca «solo cumple»)_
- **Paso 25 · Escena** _(solo si NO tienes la marca «solo cumple»)_
  - _En escena:_ Álex (si en «club» elegiste «Baloncesto»), Rubén (si en «club» elegiste «Teatro»), Sara (si en «club» elegiste «Robotica»), Hugo (si en «club» elegiste «Periodico»), Leire (si en «club» elegiste «Fotografia»)
  - _(si en «club» elegiste «Baloncesto»)_ _Narrador:_ _Primer partido del equipo de primero. Metes una canasta. Bueno, Álex dice que la mitad fue suya. Lo celebráis igual._
  - _(si en «club» elegiste «Teatro»)_ _Narrador:_ _El club de teatro hace una escena en el patio. Te toca decir: «¡Mi barco! ¡Mi precioso barco!». La gente se ríe. Rubén te choca la mano._
  - _(si en «club» elegiste «Robotica»)_ _Narrador:_ _Tornillo reparte su primer bocadillo. Solo uno. Luego se choca con una papelera. Pero el aplauso es enorme._
  - _(si en «club» elegiste «Periodico»)_ _Narrador:_ _Sale el primer número de «La Voz del Campus» con vuestro reportaje en portada. Hay gente leyéndolo en el patio. De verdad._
  - _(si en «club» elegiste «Fotografia»)_ _Narrador:_ _Leire y tú colgáis vuestras fotos en el pasillo. Una profesora se para delante de la del estadio más de un minuto._
  - _(si tienes la marca «intentas las dos»)_ _Narrador:_ _Miras el reloj. Las cinco y cuarto. Hay que correr al parque._
- **Paso 26 · Ir a** el parque — «¡Corre al cumpleaños de Nico en el parque!» _(solo si tienes la marca «intentas las dos»)_
- **Paso 27 · Ir a** el parque — «Ve al cumpleaños de Nico en el parque» _(solo si tienes la marca «solo cumple»)_
- **Paso 28 · Escena** _(solo si NO tienes la marca «solo club»)_
  - _En escena:_ Nico, Omar, Sara, Leire (si tienes la marca «conoces a leire»), Mamá/Papá
  - _(si NO tienes la marca «llegas tarde cumple»)_ **Nico:** ¡[tu nombre]! ¡Has venido! ¡Justo a tiempo para la tarta!
  - _(si tienes la marca «llegas tarde cumple»)_ **Nico:** ¡[tu nombre]! ¡Has llegado! Te hemos guardado la última porción de tarta. Omar ha tenido que defenderla con su vida.
  - **Omar:** La he defendido con mi vida. Y con un tenedor.
  - _(si tienes la marca «conoces a leire»)_ **Leire:** Nico me invitó ayer. Es imposible decirle que no a Nico. Lo he intentado.
  - **Nico:** Trece años. Ya soy casi mayor. ¿Me veis más alto? Decid que sí.
- **Paso 29 · Escena** _(solo si tienes la marca «solo club»)_
  - _Narrador:_ _Por la noche, Omar te manda una foto: Nico soplando las velas. Detrás, en una silla, un plato con croquetas y un papel: «Para [tu nombre]»._

**Al terminar (momento de la biografía):** «Te apuntaste a tu primer club»

---

### Ins03_QueQuieresSer · «¿Qué quieres ser?»

**Resumen:** La semana de las profesiones. Ocho sitios, ocho trabajos… y ninguna obligación de elegir. Solo de descubrir.

_Tipo: Historia · Orientación · Edad: 13-14 años · Duración: 25-35 min_

**Requisitos:** has terminado «Los clubes» y has vivido el 25 % de la etapa

**Lo que puede cambiar:** Qué sitios visitas (4 de 8) · Qué te interesa (marcas Interes_*) · Cómo sales de la orientación

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Antes de las vacaciones de invierno…»
  - ⏳ _Pantalla de transición:_ «Antes de las vacaciones de invierno…»
- **Paso 2 · Ir a** tu aula del instituto — «Ve a clase: hoy viene la orientadora»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
- **Paso 3 · Cinemática**
  - _En escena:_ Carmen, Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
  - 🎬 **Cinemática «Ins03_Carmen»** _(música: intensidad Nada → Descubrimiento)_
    - _En escena:_ Javier, Carmen, Omar, Nico, Bruno, Leire
    - _Cámara:_ 1 planos (General)
    - **Javier:** Hoy no os doy Historia. Os presento a alguien que sabe más de vuestro futuro que yo. Tampoco es difícil. _[plano Medio de Javier]_
    - **Carmen:** Hola, 1.º C. Soy Carmen, la orientadora. Esta semana no hay clase normal: es la semana de las profesiones. _[plano Medio de Carmen · silencio 0.5 s]_
    - **Nico:** ¿Sin clase? ¿Toda la semana? _[plano Reaccion de Nico · gesto Surprised]_
    - **Carmen:** Hay ocho sitios de Valmar que os abren las puertas. Visitad al menos cuatro. Preguntad, probad, meted las manos. _[a Nico · plano PrimerPlano de Carmen]_
    - _(si en «sitio instituto» elegiste «Omar»)_ **Omar:** Cuatro. Yo ya sé cuál es el primero. Huele a tortilla. _[plano Hombro de Tú → Omar]_
    - _(si en «sitio instituto» elegiste «Leire»)_ _(o bien)_ **Leire:** Si en la lista hay algo con cámaras, ya sé adónde voy. _[plano Hombro de Tú → Leire]_
    - _(si en «sitio instituto» elegiste «Bruno»)_ _(o bien)_ **Bruno:** Oye. ¿Vamos juntos a la comisaría? Para verla. Desde el lado bueno. _[plano Hombro de Tú → Bruno]_
    - **Carmen:** Y una cosa importante: nadie tiene que decidir su futuro esta semana. Ni este año. _[plano PrimerPlano de Carmen · en la pausa: Respirar · silencio 1.0 s]_
    - **Carmen:** Solo mirar. Mirar mucho. _[plano PPP de Carmen · silencio 0.6 s]_
    - **Bruno:** ¿Y si ya sé lo que quiero ser? _[plano Reaccion de Bruno · gesto ArmsCrossed]_
    - **Carmen:** Entonces visita también algo que no tenga nada que ver. A veces uno se sorprende. _[a Bruno · plano Hombro de Bruno → Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** ¿Hay algo de cine en la lista? _[plano Reaccion de Leire]_
    - _(si tienes la marca «conoces a leire»)_ **Carmen:** Hay un estudio audiovisual. Y me parece que allí te espera alguien de tu familia. _[a Leire · plano Medio de Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** …Mi tío. Claro. Qué vergüenza. _[plano PrimerPlano de Leire · gesto Ashamed · en la pausa: Suelo]_
    - **Omar:** Yo voy a visitar el restaurante primero. Por investigación. Y por la hora que es. _[plano Medio de Omar]_
    - _(si tienes el recuerdo «primer club»)_ **Carmen:** Y los que ya estáis en un club: eso también cuenta. Lo que hacéis por gusto dice mucho de vosotros. _[plano PrimerPlano de Carmen]_
    - **Carmen:** Os espero el viernes. Quiero saber qué habéis descubierto. _[plano DosPlanos de Carmen → Javier · gesto Happy · en la pausa: Saludar]_
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Visita al menos cuatro profesiones (en cualquier orden)»
  - _Lugar:_ el hospital · _En escena:_ Doctora Nuria, Tobías, Agente Inés, Marcos, Chef Lola, Sofía, Irene, Toni
  - **Paso 4.1 · Hablar** con Doctora Nuria — «Medicina: el hospital»
    - **Doctora Nuria:** ¡Bienvenida la cantera! Soy Nuria, médica de urgencias. Aquí nunca sabes qué va a entrar por esa puerta.
    - _(si en «sueno infancia» elegiste «Medicina»)_ _Narrador:_ _✨ Cuando tenías diez años, en un banco del parque, dijiste que querías salvar vidas. Aquí se hace cada día._
    - **Doctora Nuria:** Llega un niño con el brazo hinchado. Se ha caído de la bici. Está asustado. Tú eres parte del equipo.
    - ❓ **Pregunta al jugador:** ¿Qué haces primero?
      - ➤ «Tranquilizarle: le preguntas su nombre y le hablas» _(efecto: empatia +1)_
        - **Doctora Nuria:** Exacto. Un paciente tranquilo se deja ayudar. La mitad de la medicina es hablar bien.
      - ➤ «Mirar el brazo con cuidado sin moverlo» _(efecto: responsabilidad +1)_
        - **Doctora Nuria:** Bien: no mover, observar, avisar. Luego una radiografía. Tienes buen instinto.
    - **Doctora Nuria:** Es duro: turnos de noche, días malos. Pero cuando alguien sale por la puerta andando… no hay nada igual.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes medicina»)_
        - **Doctora Nuria:** Entonces estudia mucha biología. Y aprende a dormir en cualquier sitio. Te hará falta.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Doctora Nuria:** Muy bien. Saber lo que no quieres también es saber mucho.
  - **Paso 4.2 · Hablar** con Sofía — «Ingeniería: el laboratorio de la facultad»
    - **Sofía:** ¡Pasa, pasa! Esto es el laboratorio de ingeniería. Aquí se rompen cosas… para que luego no se rompan.
    - _(si en «sueno infancia» elegiste «Ingenieria»)_ _Narrador:_ _✨ De pequeño/a querías «inventar cosas que no existen». Este sitio huele a eso._
    - **Sofía:** Este puente de palillos tiene que aguantar dos kilos. Ahora mismo aguanta… uno y medio. ¿Qué harías tú?
    - ❓ **Pregunta al jugador:** ¿Cómo lo arreglas?
      - ➤ «Añadir triángulos: son más fuertes» _(efecto: curiosidad +1)_
        - **Sofía:** ¡Triángulos! ¿Quién te lo ha contado? Los puentes de verdad están llenos. Aguanta dos kilos y medio. Récord del día.
      - ➤ «Probar, romper y volver a probar» _(efecto: valentia +1)_
        - **Sofía:** El método de los ingenieros de verdad. Tres puentes rotos después: aguanta dos kilos. ¡Bien!
    - _(si en «club» elegiste «Robotica»)_ **Sara:** (Sara aparece por la puerta) ¡Sabía que acabarías aquí! Yo vengo todas las semanas. Sofía ya me conoce.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes ingenieria»)_
        - **Sofía:** Pues en unos años nos vemos por aquí. Te guardo una bata.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Sofía:** Vale. Pero si un día te aburres, aquí siempre hay algo roto.
  - **Paso 4.3 · Hablar** con Agente Inés — «Policía y leyes: la comisaría»
    - **Agente Inés:** Hola. Soy Inés, agente de barrio. Mucha gente cree que esto es persecuciones. Casi todo es escuchar y ayudar.
    - _(si en «sueno infancia» elegiste «Derecho»)_ _Narrador:_ _✨ En el parque dijiste que querías defender a quien no puede defenderse. Esto también es eso._
    - **Agente Inés:** Viene una señora: dice que el vecino le ha robado la maceta. El vecino dice que la maceta es suya. ¿Qué haces?
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Escuchar a los dos antes de decidir nada» _(efecto: responsabilidad +1)_
        - **Agente Inés:** Eso es. Al final la maceta era de los dos: la compraron juntos hace veinte años. Se habían olvidado.
      - ➤ «Buscar pruebas: tiques, fotos, testigos» _(efecto: curiosidad +1)_
        - **Agente Inés:** Muy bien. Una foto de hace años lo aclara: la compraron a medias. Se ríen. Caso cerrado.
    - **Agente Inés:** Si te gusta esto, también está el derecho: abogados, jueces, gente que se estudia las leyes para que sean justas.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes derecho»)_
        - **Agente Inés:** Te veo con toga o con placa. Cualquiera de las dos te queda bien.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Agente Inés:** Perfecto. Lo importante es que ahora sabes que esto existe.
  - **Paso 4.4 · Hablar** con Marcos — «Empresa: las oficinas del distrito financiero»
    - **Marcos:** ¡Hola, hola, pasa! Soy Marcos. Tengo una empresa de bicicletas. Bueno, la empresa me tiene a mí.
    - _(si en «sueno infancia» elegiste «Economia»)_ _Narrador:_ _✨ En el parque dijiste que querías tener tu propio negocio. Aquí tienes uno de verdad._
    - **Marcos:** Problema real: nos sobran cien bicis rojas y nadie las compra. ¿Qué harías?
    - ❓ **Pregunta al jugador:** ¿Tu idea?
      - ➤ «Alquilarlas por horas a turistas en la playa» _(efecto: creatividad +1)_
        - **Marcos:** ¡Anda! Eso no lo habíamos pensado. Lo apunto. Si funciona, te pago en helados.
      - ➤ «Preguntar a la gente por qué no las compra» _(efecto: curiosidad +1)_
        - **Marcos:** La pregunta más importante de cualquier negocio. Resulta que… el rojo no gusta. Las pintaremos de azul.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes economia»)_
        - **Marcos:** Estudia números y aprende a escuchar. Con eso se montan las mejores empresas.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Marcos:** Normal. Esto no es para todo el mundo. Yo tampoco sabía que era para mí.
  - **Paso 4.5 · Hablar** con Tobías — «Mecánica: el taller de la gasolinera»
    - **Tobías:** Pasa, que no muerdo. El coche sí, si le metes la mano donde no es. Soy Tobías. Cuarenta años arreglando motores.
    - **Tobías:** Este no arranca. Escucha: ¿oyes ese clic-clic? ¿Qué crees que es?
    - ❓ **Pregunta al jugador:** ¿Qué crees?
      - ➤ «La batería» _(efecto: curiosidad +1)_
        - **Tobías:** ¡La batería! Tienes oído. Muchos adultos no lo saben. Cambiamos y… ¡brum! Arrancado.
      - ➤ «No tengo ni idea, pero quiero verlo» _(efecto: humor +1)_
        - **Tobías:** Esa es la mejor respuesta que me han dado nunca. Era la batería. Ahora ya lo sabes.
    - **Tobías:** Aquí no hace falta universidad. Hace falta paciencia, manos y ganas de aprender toda la vida.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes oficio»)_
        - **Tobías:** Pues cuando quieras, vente un verano. Te enseño lo que sé. Que es bastante.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Tobías:** Bien. Pero si algún día se te estropea la bici, ya sabes dónde estoy.
  - **Paso 4.6 · Hablar** con Chef Lola — «Cocina: la cafetería del centro»
    - **Chef Lola:** ¡Delantal y manos limpias! Soy Lola. En mi cocina se grita, se corre… y se hace la mejor tortilla de Valmar.
    - **Omar:** (Omar ya está aquí, con delantal) He llegado primero. Era una cuestión de prioridades.
    - **Chef Lola:** Hay cuatro mesas esperando y solo hay tiempo para una cosa. ¿Qué haces?
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Organizar: primero lo que tarda más» _(efecto: responsabilidad +1)_
        - **Chef Lola:** ¡Cabeza de chef! Así se sale de un lío. Las cuatro mesas, servidas.
      - ➤ «Pedir ayuda a Omar: en equipo, más rápido» _(efecto: Omar +3; empatia +1)_
        - **Chef Lola:** Una cocina es un equipo o no es nada. Muy bien. Y tu amigo pela patatas como un campeón.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes cocina»)_
        - **Chef Lola:** Pues aprende a cocinar para tu familia. Ese es el primer restaurante de todo el mundo.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Chef Lola:** No pasa nada. Pero la tortilla, llévatela. Eso sí es obligatorio.
  - **Paso 4.7 · Hablar** con Irene — «Deporte: el estadio universitario»
    - **Irene:** ¡Al trote! Soy Irene: entrenadora y fisioterapeuta. Aquí se trabaja con el cuerpo y con la cabeza.
    - _(si en «sueno infancia» elegiste «Deporte»)_ _Narrador:_ _✨ En el parque dijiste que querías ser deportista. Aquí entrenan quienes lo consiguen… y quienes les ayudan._
    - **Irene:** Una atleta se ha torcido el tobillo. Quiere seguir corriendo la final. ¿Qué le dices?
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Hoy no. Si corres, te lesionas un año.» _(efecto: responsabilidad +1)_
        - **Irene:** Duro, pero correcto. Cuidar a alguien a veces es decirle que no.
      - ➤ «Vamos a ponerle hielo y luego decidimos.» _(efecto: empatia +1)_
        - **Irene:** Muy bien: primero cuidar, luego decidir. Al final no pudo correr, pero te lo agradeció.
    - _(si tienes el recuerdo «primer torneo»)_ **Irene:** Tu medalla del torneo del colegio… ¡qué recuerdo! Yo empecé igual.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes deporte»)_
        - **Irene:** Entrena, estudia y cuida tu cuerpo. Y ven a verme cuando quieras.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Irene:** Vale. Pero sigue moviéndote. El cuerpo lo agradece toda la vida.
  - **Paso 4.8 · Hablar** con Toni — «Audiovisual: el cine»
    - **Toni:** ¡Hola! Soy Toni, el tío de Leire. Hacemos documentales. Hoy grabamos una entrevista en la sala del cine.
    - _(si en «sueno infancia» elegiste «Arte»)_ _Narrador:_ _✨ De pequeño/a querías pintar cosas que la gente no olvidara. Aquí se pinta con luz._
    - **Toni:** Tú eres la cámara. ¿Dónde pones al entrevistado?
    - ❓ **Pregunta al jugador:** ¿Dónde le pones?
      - ➤ «Junto a la ventana, con luz natural» _(efecto: creatividad +1)_
        - **Toni:** ¡Primer plano, luz de ventana! Eso es lo que haría yo. Queda precioso.
      - ➤ «Delante de las butacas vacías: cuenta una historia» _(efecto: creatividad +1)_
        - **Toni:** Un plano que cuenta algo por sí solo. Eso no se enseña: se tiene.
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Te lo dije: mi tío habla en planos. Ya lo has comprobado.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes audiovisual»)_
        - **Toni:** Pues coge una cámara, aunque sea la del móvil, y no pares de mirar.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Toni:** Me parece bien. Pero ahora ya ves las películas de otra forma. No hay vuelta atrás.
- **Paso 5 · Ir a** tu aula del instituto — «Vuelve al instituto: Carmen quiere saber qué has descubierto»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
- **Paso 6 · Escena**
  - **Carmen:** Bueno, [tu nombre]. ¿Qué has descubierto esta semana? _[plano Medio de Carmen · en la pausa: Mira]_
  - _(si tienes la marca «interes medicina»)_ **Carmen:** Veo que el hospital te ha removido algo.
  - _(si tienes la marca «interes medicina»)_ **Nico:** ¿Médico? Te dejo mi rodilla. Está de prácticas. _[gesto Happy]_
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Sofía me ha dicho que tus puentes aguantan más que los suyos. Eso no lo dice nunca.
  - _(si tienes la marca «interes derecho»)_ **Carmen:** Inés dice que escuchas a las dos partes. Eso vale para la policía y para el derecho.
  - _(si tienes la marca «interes derecho»)_ **Bruno:** ¿Policía tú también? Ya veremos quién llega antes. _[gesto ArmsCrossed]_
  - _(si tienes la marca «interes economia»)_ **Carmen:** Marcos va a pintar las bicis de azul. Por tu culpa. Está encantado.
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Tobías pregunta si vas a volver al taller. Eso con Tobías es casi una oferta de trabajo.
  - _(si tienes la marca «interes cocina»)_ **Carmen:** Lola dice que tienes cabeza de cocina. No sé qué significa, pero suena a piropo.
  - _(si tienes la marca «interes cocina»)_ **Omar:** ¡Lo sabía! Socios. Tú cortas, yo pruebo. _[gesto Happy]_
  - _(si tienes la marca «interes deporte»)_ **Carmen:** Irene te ha visto cuidar a alguien antes que a una medalla. Eso es saber entrenar.
  - _(si tienes la marca «interes audiovisual»)_ **Carmen:** Toni ya te llama «la cámara». Viniendo de él, es un título.
  - _(si tienes las marcas «interes audiovisual» y «conoces a leire»)_ **Leire:** Mi tío no se lo dice a cualquiera. Bueno, sí. Pero esta vez lo dice en serio.
  - **Carmen:** Y ahora lo importante. _[plano PrimerPlano de Carmen · en la pausa: Respira · silencio 0.8 s]_
  - ❓ **Pregunta al jugador:** ¿Cómo te sientes con tu futuro?
    - ➤ «Creo que ya sé lo que me gusta» _(efecto: responsabilidad +1; decisión «orientacion» = Claro)_
      - **Carmen:** Qué bien. Aun así, déjate sorprender. Las mejores decisiones se toman sabiendo qué más había.
    - ➤ «Tengo más dudas que antes» _(efecto: curiosidad +1; decisión «orientacion» = Dudas)_
      - **Carmen:** Eso es buena señal. Significa que has mirado de verdad. Las dudas son el principio de cualquier decisión buena.
    - ➤ «Me gustan muchas cosas a la vez» _(efecto: creatividad +1; decisión «orientacion» = Muchas)_
      - **Carmen:** A mí también me pasaba. Y mírame: orientadora. Que es un poco de todo. Tranquilidad: hay tiempo.
  - **Omar:** Yo tengo clarísimo que quiero trabajar con Lola. O comer donde trabaje Lola. Una de las dos.
  - **Carmen:** Os doy un cuaderno para apuntar lo que habéis visto. Dentro de unos años lo leeréis y os reiréis. O no. Guardadlo.

**Al terminar (momento de la biografía):** «La semana de las profesiones»

---

### Pan1_MalasCompanias · «Las malas compañías»

**Resumen:** Rayo es el más popular de 4.º. Y hoy te ha elegido a ti. «¿Te vienes? Nadie se va a enterar.»

_Tipo: Historia · El camino (bien o mal) · Edad: 14-14 años · Duración: 20-25 min_

**Requisitos:** has terminado «¿Qué quieres ser?» y has vivido el 30 % de la etapa

**Lo que puede cambiar:** Hacer pellas, volver a clase o frenar a Nerea · Pintada o no · Mentir a tu familia o decir la verdad

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Segundo de la ESO. Un martes cualquiera.»
  - ⏳ _Pantalla de transición:_ «Segundo de la ESO. Un martes cualquiera.»
- **Paso 2 · Ir a** el patio — «Sal al recreo»
  - _Lugar:_ el patio · _En escena:_ Rayo, Nerea, Javier, Omar
- **Paso 3 · Escena**
  - _Narrador:_ _En el rincón del fondo del patio está la pandilla de Rayo. Los de 4.º. Todo el mundo los mira. Nadie se acerca._
  - **Rayo:** Eh, tú. Sí, tú. Te he visto. No eres como los demás pringados de segundo. Tienes pinta de saber divertirte.
  - **Rayo:** Después del recreo nos piramos a los recreativos. Javier ni se entera. ¿Te vienes? Nerea también viene.
  - **Nerea:** (sin levantar la vista de su cuaderno) Yo voy porque no tengo nada mejor que hacer. Tú verás.
  - **Omar:** (bajito) [tu nombre]… Esos se meten en líos. Todo el rato. Yo me vuelvo a clase. Tú haz lo que quieras, ¿eh?
- **Paso 4 · Decisión** — «¿Qué haces? (habla con quien elijas)»
  - ➤ **Opción «Irte con Rayo a los recreativos»** (con Rayo) _(efecto: decisión «pellas» = Ir; Rayo +6; rebeldia +1; marca «hiciste pellas»)_
    - **Rayo:** ¡Eso es! Sabía que tenías algo. Venga, que la puerta de atrás del gimnasio no la vigila nadie.
  - ➤ **Opción «Volver a clase»** (con Javier) _(efecto: decisión «pellas» = Clase; Rayo -3; responsabilidad +1; marca «rechazaste la pandilla»)_
    - **Javier:** ¿Volviendo a clase por su propio pie? Me alegra el día. No se lo digas a nadie, pero hoy toca la Revolución Francesa. Es la mejor.
    - **Rayo:** (desde lejos) ¡Pringado! …Tú te lo pierdes.
  - ➤ **Opción «Convencer a Nerea de que no vaya»** (con Nerea) _(efecto: decisión «pellas» = Nerea; Nerea +8; Rayo -5; empatia +1; marca «rechazaste la pandilla» y «amiga nerea»)_
    - **Nerea:** ¿Y a ti qué te importa si voy o no?
    - _Narrador:_ _Le dices que te ha gustado lo que dibuja. Que lo has visto de reojo. Que es bueno de verdad._
    - **Nerea:** …Nadie mira mis dibujos. Vale. Hoy no voy. Pero no te acostumbres a mandarme.
    - **Rayo:** ¿Nerea se queda? Tú. Me acuerdo de tu cara.
- **Paso 5 · Ir a** el cine y los recreativos — «Ve con Rayo y Nerea a los recreativos» _(solo si en «pellas» elegiste «Ir»)_
  - _Lugar:_ el cine y los recreativos · _En escena:_ Rayo (te acompaña), Nerea (te acompaña)
- **Paso 6 · Acción del jugador** — «Juega una partida en los recreativos» _(solo si en «pellas» elegiste «Ir»)_
- **Paso 7 · Escena** _(solo si en «pellas» elegiste «Ir»)_
  - _Narrador:_ _Luces, música, fichas. Rayo gana a todo. Es divertido, la verdad. Muy divertido._
  - **Rayo:** ¿Ves? Esto es vivir. En clase te hacen estar quieto seis horas. Aquí mandas tú.
  - **Nerea:** (bajito) La primera vez también me lo pareció. Luego llegan las notas. Y las llamadas a casa.
- **Paso 8 · Ir a** el parque — «Rayo quiere enseñarte «su» muro del parque» _(solo si en «pellas» elegiste «Ir»)_
  - _Lugar:_ el parque · _En escena:_ Rayo, Nerea
- **Paso 9 · Usar** — «El muro: Rayo te da un espray» _(solo si en «pellas» elegiste «Ir»)_
  - 🖐 _Al usar «El muro del parque»:_
    - **Rayo:** Este muro es nuestro. Cada uno pone su firma. Toma, el espray. Pon la tuya.
    - ❓ **Pregunta al jugador:** ¿Qué haces con el espray?
      - ➤ «Pintas tu firma, grande» _(efecto: Rayo +4; rebeldia +1; marca «pintada»)_
        - **Rayo:** ¡Eso! Ahora eres de los nuestros. Mañana lo verá todo el barrio.
      - ➤ «Pintas un dibujo bonito en vez de una firma» _(efecto: Nerea +4; creatividad +1; rebeldia +1; marca «pintada»)_
        - **Nerea:** …Eso está bien. Muy bien. Aunque sigue siendo pintar donde no se puede.
      - ➤ «Le devuelves el espray: «Esto no»» _(efecto: Nerea +3; Rayo -4; valentia +1)_
        - **Rayo:** Vale, vale. Qué miedo tenéis todos a todo. Ya te lo pensarás.
- **Paso 10 · Clase** — «Clase de Historia con Javier» _(solo si en «pellas» elegiste «Clase»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier
- **Paso 11 · Escena** _(solo si en «pellas» elegiste «Clase»)_
  - _Lugar:_ el patio · _En escena:_ Rayo, Nerea
  - _Narrador:_ _A la salida, Rayo y su pandilla están en la puerta. Vienen de los recreativos. Se ríen muy alto._
  - **Rayo:** Mira quién sale de clase. ¿Qué tal la Revolución Francesa? ¿Te has divertido mucho?
  - **Nerea:** (al pasar a tu lado, bajito) Javier ha llamado a sus casas. A la mía también. Hiciste bien.
- **Paso 12 · Escena** _(solo si en «pellas» elegiste «Nerea»)_
  - _En escena:_ Nerea
  - **Nerea:** Mira. Son cómics. Una chica que vuela por encima de Valmar y nadie la ve. No se los he enseñado a nadie.
  - **Nerea:** Rayo dice que dibujar es de críos. Pero Rayo dice muchas cosas.
- **Paso 13 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 14 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - _(si en «pellas» elegiste «Ir»)_ **Mamá/Papá:** Ha llamado Javier, tu tutor. Dice que esta tarde no estabas en clase. ¿Me lo explicas?
  - _(si en «pellas» elegiste «Ir»)_ ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Me encontraba mal y me fui a dar una vuelta» (mentira) _(efecto: Mamá/Papá -5; rebeldia +1; marca «mentiste familia»)_
      - **Mamá/Papá:** …Ya. Vale. Te creo. Esta vez.
      - **Abu:** (desde el sillón, sin mirarte) Las mentiras pesan más que la mochila, cariño. Lo digo por experiencia.
    - ➤ «Me fui con unos de 4.º. Me equivoqué.» _(efecto: Mamá/Papá +3; responsabilidad +1)_
      - **Mamá/Papá:** Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga, y lo hablamos.
  - _(si en «pellas» elegiste «Clase»)_ **Mamá/Papá:** ¿Qué tal el día? ¿Mucha Historia? Tienes cara de haber aprendido algo.
  - _(si en «pellas» elegiste «Nerea»)_ **Mamá/Papá:** Me ha dicho Omar que hoy has ayudado a una chica de 4.º. Qué bien.
- **Paso 15 · Hablar** con Bruno — «Un mensaje de Bruno: «¿Hablamos? Estoy en la puerta de tu casa»»
  - _Lugar:_ Aquí · _En escena:_ Bruno
  - **Bruno:** Oye. Me he enterado de lo de Rayo. En el instituto se entera todo el mundo de todo.
  - **Bruno:** Yo era el malo del colegio, ¿te acuerdas? Molaba. Hasta que dejó de molar. Rayo es eso, pero en mayor.
  - _(si tienes la marca «rechazaste la pandilla»)_ **Bruno:** Hiciste bien en volver. De verdad.
  - _(si en «pellas» elegiste «Ir»)_ **Bruno:** Solo… ten cuidado. Con Rayo, un día son los recreativos y otro día es otra cosa.

**Al terminar (momento de la biografía):** «El día que conociste a Rayo»

---

### Pan2_LaNoche · «La noche del supermercado»

**Resumen:** Rayo tiene un plan para el sábado por la noche. «Una puerta que no cierra bien. Unas latas. Nadie se va a enterar.»

_Tipo: Historia · El camino (bien o mal) · Edad: 14-15 años · Duración: 25-30 min_

**Requisitos:** has terminado «Las malas compañías» y has vivido el 36 % de la etapa

**Lo que puede cambiar:** Ir o no ir · Coger algo o marcharte · Que te pillen, escapar (y que te pillen después) o no estar allí

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Un sábado de primavera…»
  - ⏳ _Pantalla de transición:_ «Un sábado de primavera…»
- **Paso 2 · Ir a** el parque — «Rayo te ha escrito: «Parque. Ahora. Tengo un plan»»
  - _Lugar:_ el parque · _En escena:_ Rayo, Nerea
- **Paso 3 · Hablar** con Rayo — «Escucha el plan de Rayo»
  - **Rayo:** Escucha. El súper de Paco cierra a las diez. La puerta del almacén no cierra bien: se abre con un empujón.
  - **Rayo:** Entramos, cogemos unas latas, chuches, lo que sea, y nos vamos. Cinco minutos. No es robar: Paco tiene de sobra.
  - **Nerea:** (sin mirarte) Yo iré. Supongo. ¿Tú vas?
  - _(si tienes la marca «pintada»)_ **Rayo:** Tú ya eres de los nuestros. Lo del muro fue un primer paso. Esto es el segundo.
  - ❓ **Pregunta al jugador:** ¿Qué dices?
    - ➤ «Voy.» _(efecto: Rayo +5; rebeldia +1; decisión «plan» = Ir)_
      - **Rayo:** ¡Eso! A las diez y media, detrás del súper. Ropa oscura.
    - ➤ «Paso. Esto ya no es una tontería.» _(efecto: Rayo -4; responsabilidad +1; decisión «plan» = No; marca «rechazaste la pandilla»)_
      - **Rayo:** Tú sabrás. Luego no me vengas con que te aburres.
    - ➤ «No lo hagáis. Os van a pillar. Nerea, tú tampoco.» _(efecto: Nerea +6; Rayo -6; empatia +1; valentia +1; decisión «plan» = Frenar; marca «rechazaste la pandilla»)_
      - **Nerea:** …
      - **Rayo:** ¿Ahora eres su madre? Nerea hace lo que quiere. ¿Verdad, Nerea?
      - _(si tienes la marca «amiga nerea»)_ **Nerea:** …Esta vez me quedo en casa. Lo siento, Rayo.
- **Paso 4 · Transición (pasa el tiempo)** — «Esa noche, a las diez y media…» _(solo si en «plan» elegiste «Ir»)_
  - ⏳ _Pantalla de transición:_ «Esa noche, a las diez y media…»
- **Paso 5 · Ir a** el supermercado — «El súper de Paco ya ha cerrado. Rayo espera en la parte de atrás» _(solo si en «plan» elegiste «Ir»)_
  - _Lugar:_ el supermercado
- **Paso 6 · Usar** — «La puerta del almacén» _(solo si en «plan» elegiste «Ir»)_
  - 🖐 _Al usar «La puerta del almacén»:_
    - _Narrador:_ _La puerta se abre con un empujón, como dijo Rayo. Dentro, oscuro. Cajas. Estanterías. Huele a cartón._
    - **Rayo:** (susurrando) ¡Rápido! Coge lo que quieras y nos vamos.
    - _Narrador:_ _Tienes una caja de latas delante. Nadie te ve. Piensas en Paco, en su «Hmm», en sus cajas perfectamente apiladas._
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Coges unas latas y unas chuches» _(efecto: Rayo +4; rebeldia +2; marca «hurto»)_
        - **Rayo:** ¡Eso es! ¡Vámonos!
      - ➤ «Lo dejas todo en su sitio y te vas» _(efecto: Nerea +5; Rayo -5; valentia +1; marca «te fuiste»)_
        - _Narrador:_ _Das media vuelta y sales. Rayo te llama algo desde dentro. No lo oyes. No quieres oírlo._
        - **Nerea:** (te alcanza en la calle) Espera. Yo tampoco quería. Me voy contigo.
- **Paso 7 · Cinemática** _(solo si tienes la marca «hurto»)_
  - 🎬 **Cinemática «Pan2_Alarma»** _(música: intensidad Tension)_
    - _En escena:_ Rayo, Nerea
    - _Cámara:_ 3 planos (PPP, Reaccion, PrimerPlano)
    - 🪧 _Rótulo:_ «¡Corre!» — Llega al parque antes que la policía
    - _Narrador:_ _La alarma. Luces rojas. Un perro ladra en la calle de al lado._
    - **Nerea:** ¡Rayo! ¿«Nadie se va a enterar»? ¡¿Esto es nadie?! _[a Rayo · plano Medio de Nerea · gesto Angry]_
    - **Rayo:** ¡CORRED! ¡Cada uno por un lado! ¡Nos vemos en el parque! _[plano Medio de Rayo · en la pausa: Senalar]_
- **Paso 8 · Ir a** el parque — «¡CORRE! ¡Llega al parque antes de que llegue la policía!» _(solo si tienes la marca «hurto»)_
- **Paso 9 · Escena** _(solo si tienes la marca «hurto» y NO tienes la marca «pillado»)_
  - _En escena:_ Rayo
  - _Narrador:_ _Llegas al parque sin aliento. El corazón te va a salir por la boca. Nadie te ha seguido. Eso crees._
  - **Rayo:** ¡JA! ¿Has visto? ¡Nadie nos pilla! Mañana nos comemos las chuches a la salud de Paco.
  - _Narrador:_ _Tienes una lata en la mano. No sabe a nada._
- **Paso 10 · Escena** _(solo si tienes la marca «pillado»)_
  - _Lugar:_ la comisaría · _En escena:_ Agente Inés, Mamá/Papá, Paco, Rayo
  - _Narrador:_ _No llegas. Una patrulla te para a dos calles. Media hora después estás en la comisaría, sentado/a en un banco de plástico._ _[plano General]_
  - _(si tienes la marca «interes derecho»)_ **Agente Inés:** Hola otra vez. Nos conocimos en la semana de las profesiones. No pensé que volveríamos a vernos así.
  - **Agente Inés:** Soy la agente Inés. Tranquilidad: nadie va a ir a la cárcel por unas latas. _[plano Medio de Agente Inés]_
  - **Agente Inés:** Pero esto tiene consecuencias. _[plano PrimerPlano de Agente Inés · en la pausa: Mira · silencio 1.0 s]_
  - **Mamá/Papá:** (entra corriendo) ¿Estás bien? …Estás bien. Vale. _[plano Medio de Mamá/Papá · gesto Nervous]_
  - **Mamá/Papá:** Ahora sí: ¿EN QUÉ ESTABAS PENSANDO? _[plano PrimerPlano de Mamá/Papá · gesto Angry · en la pausa: Respira · silencio 1.2 s]_
  - _(si tienes la marca «mentiste familia»)_ **Mamá/Papá:** Y no es la primera vez que me mientes. Lo del día que «te encontrabas mal» tampoco me lo creí. _[gesto Sad]_
  - **Paco:** Hmm. _[plano PrimerPlano de Paco · en la pausa: Silencio · silencio 1.4 s]_
  - **Paco:** Treinta años con el súper abierto. Nunca me habían entrado. Y has sido tú. No me lo esperaba. _[gesto Sad]_
  - _(si tu relación con Rayo es de 5 o más)_ **Rayo:** (desde el banco, sin mirarte) Yo no he dicho nada. Que conste.
  - **Agente Inés:** Como sois menores y es la primera vez: servicio a la comunidad. Tres turnos limpiando en el Punto Limpio. Y pedir perdón a Paco. _[plano Medio de Agente Inés]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices a Paco?
    - ➤ «Lo siento. De verdad. Te devuelvo todo y te lo pago.» _(efecto: Mamá/Papá +3; Paco +3; responsabilidad +1; marca «perdon paco»)_
      - **Paco:** Hmm. Pedir perdón mirando a los ojos. Eso ya es algo. Ya veremos.
    - ➤ «No dices nada. Miras al suelo.» _(efecto: Paco -5; rebeldia +1)_
      - **Paco:** Ya. Hmm.
- **Paso 11 · Acción del jugador** — «Servicio a la comunidad: limpia en el Punto Limpio (0/3)» _(solo si tienes la marca «pillado»)_
  - _Lugar:_ el Punto Limpio · _En escena:_ Agente Inés
- **Paso 12 · Escena** _(solo si tienes la marca «pillado»)_
  - **Agente Inés:** Tres turnos. Bien hecho. ¿Sabes qué? La mayoría de los chavales que vienen aquí no vuelven nunca a la comisaría. Espero que tú seas de esos.
  - _Narrador:_ _Limpiando, encuentras una lata igual que la que te llevaste. La tiras al contenedor amarillo. Te sientes un poco mejor._
- **Paso 13 · Transición (pasa el tiempo)** — «Esa noche, en casa…» _(solo si en «plan» NO elegiste «Ir»)_
  - ⏳ _Pantalla de transición:_ «Esa noche, en casa…»
- **Paso 14 · Escena** _(solo si en «plan» NO elegiste «Ir»)_
  - _Narrador:_ _Medianoche. Tu móvil vibra._
  - _(si en «plan» elegiste «No»)_ **Nerea:** (mensaje) Al final han ido Rayo y dos más. Ha saltado la alarma. A Rayo le han pillado.
  - _(si en «plan» elegiste «Frenar»)_ **Nerea:** (mensaje) Me he quedado en casa. Rayo ha ido con dos más y le han pillado. Gracias por lo de esta tarde. En serio.
  - **Nerea:** (mensaje) Rayo dice que alguien se ha chivado. No has sido tú, ¿no? Dime que no.
- **Paso 15 · Escena**
  - _Lugar:_ Aquí · _En escena:_ Nerea
  - **Nerea:** Todo el instituto sabe lo del súper. Rayo está expulsado tres días.
  - _(si tienes la marca «pillado»)_ **Nerea:** Y tú… te pillaron. Lo siento. Rayo dice que eres «de los buenos» porque no dijiste nombres. No sé si eso es un piropo.
  - _(si tienes la marca «escapaste»)_ **Nerea:** Tú te libraste. Pero hay cámaras en la puerta del almacén. Lo sabe todo el mundo menos Rayo.
  - _(si tienes la marca «te fuiste»)_ **Nerea:** Te fuiste a tiempo. Yo también. Creo que es lo más valiente que he hecho nunca.
  - _(si en «plan» NO elegiste «Ir»)_ **Nerea:** Tú no estabas. Mejor. Rayo… Rayo no está bien. En su casa no hay nadie nunca. No sé qué va a pasar.

**Al terminar (momento de la biografía):** «La noche del supermercado»

---

### Ins04_PrimerEmpleo · «El primer empleo»

**Resumen:** Llega el verano y quieres algo que cuesta dinero. Toca buscar tu primer trabajo: perfil, ofertas, entrevista… y el primer sueldo.

_Tipo: Historia · Trabajo · Edad: 14-15 años · Duración: 20-30 min_

**Requisitos:** has terminado «La noche del supermercado» y has vivido el 44 % de la etapa

**Lo que puede cambiar:** Qué trabajo eliges · Verdad o mentira en la entrevista · Qué haces con tu primer sueldo

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Un año después. Llega el verano…»
  - ⏳ _Pantalla de transición:_ «Un año después. Llega el verano…»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¿Otra vez mirando eso en el móvil? A ver… Ya veo. Es precioso. Y caro.
  - ❓ **Pregunta al jugador:** ¿Qué quieres conseguir este verano?
    - ➤ «Una bici de verdad, para ir a todas partes» _(efecto: decisión «meta» = Bici)_
    - ➤ «Una cámara, como la de Leire» _(efecto: decisión «meta» = Camara)_
    - ➤ «Ayudar en casa: las cosas están caras» _(efecto: Mamá/Papá +4; responsabilidad +1; decisión «meta» = Casa)_
    - ➤ «Ahorrar para cuando vaya a la universidad» _(efecto: responsabilidad +1; decisión «meta» = Ahorro)_
  - **Mamá/Papá:** Pues ¿sabes qué hacía yo a tu edad? Trabajar en verano. Unas horas. Se aprende muchísimo.
  - **Abu:** Y el primer sueldo… ese no se olvida nunca. Yo me compré unos zapatos. Me duraron diez años.
- **Paso 3 · Ir a** tu aula del instituto — «Ve al instituto: taller de primer empleo con Carmen»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Omar
- **Paso 4 · Escena**
  - **Carmen:** Taller de primer empleo. Un perfil laboral es contar quién eres en pocas líneas. Sin mentir y sin esconderte.
  - **Omar:** Yo he puesto: «Soy muy bueno comiendo». Carmen dice que eso no es una habilidad. Discrepo.
  - ❓ **Pregunta al jugador:** ¿Qué pones como tu punto fuerte?
    - ➤ «Soy responsable: si digo que voy, voy» _(efecto: responsabilidad +1; decisión «perfil» = Responsable)_
      - **Carmen:** Es lo que más buscan. En serio: más que saber hacer cosas.
    - ➤ «Trato bien a la gente» _(efecto: empatia +1; decisión «perfil» = Gente)_
      - **Carmen:** Perfecto para trabajar de cara al público.
    - ➤ «Aprendo rápido» _(efecto: curiosidad +1; decisión «perfil» = Aprendo)_
      - **Carmen:** Muy bien. Y ponlo con un ejemplo: tu club, un proyecto…
  - _(si tienes el recuerdo «que quieres ser»)_ **Carmen:** Tu club también cuenta. Y lo que hiciste en la semana de las profesiones. Todo lo que has vivido es experiencia.
  - _(si NO tienes el recuerdo «que quieres ser»)_ **Carmen:** Tu club también cuenta. Todo lo que has vivido es experiencia.
  - **Carmen:** Ahora a buscar. Hay carteles de «Se busca» en la cafetería del centro, en el supermercado y en Correos.
- **Paso 5 · Varios objetivos (en cualquier orden)** — «Busca ofertas por la ciudad (al menos dos)»
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola, Paco, Ernesto
  - **Paso 5.1 · Usar** — «La Cafetería Central»
    - 🖐 _Al usar «Cartel: «Se busca ayudante»»:_
      - _Narrador:_ _«Se busca ayudante de verano. Mañanas. Buena sonrisa y pulso firme con las bandejas. Preguntar por Lola.»_
  - **Paso 5.2 · Usar** — «El supermercado»
    - 🖐 _Al usar «Cartel: «Se busca reponedor/a»»:_
      - _Narrador:_ _«Se busca reponedor/a. Fuerza, orden y paciencia. Paga semanal. Preguntar por Paco. NO preguntar por las cajas de arriba.»_
  - **Paso 5.3 · Usar** — «Correos»
    - 🖐 _Al usar «Cartel: «Repartidores de verano»»:_
      - _Narrador:_ _«Repartidores de verano. Se valora conocer la ciudad y no tener miedo a los perros. Mejor paga. Preguntar por Ernesto.»_
- **Paso 6 · Decisión** — «¿Dónde quieres trabajar? (habla con quien contrata)»
  - ➤ **Opción «Cafetería: servir cafés con Lola»** (con Chef Lola) _(efecto: decisión «empleo» = Barista)_
    - _(si tienes la marca «interes cocina»)_ **Chef Lola:** ¡Anda, si es mi visita de la semana de las profesiones! Siéntate. Entrevista rápida, que tengo cruasanes en el horno.
    - _(si NO tienes la marca «interes cocina»)_ **Chef Lola:** Siéntate. Entrevista rápida, que tengo cruasanes en el horno.
    - _(si en «perfil» elegiste «Gente»)_ **Chef Lola:** Carmen me ha mandado tu perfil. «Trato bien a la gente». Aquí eso vale más que saber hacer café. _[plano PrimerPlano de Chef Lola · en la pausa: Asiente]_
    - **Chef Lola:** Primera pregunta. _[plano Hombro de Tú → Chef Lola · en la pausa: Mira · silencio 0.6 s]_
    - ❓ **Pregunta al jugador:** «¿Has trabajado antes en una cafetería?»
      - ➤ «No, pero aprendo rápido y tengo ganas» _(efecto: responsabilidad +1)_
        - **Chef Lola:** La verdad. Me gusta. Aquí todos empezamos sin saber. Yo quemé tres cafeteras.
      - ➤ «Sí, mucho» (no es verdad) _(efecto: marca «mentiste entrevista»)_
        - **Chef Lola:** ¿Ah, sí? Estupendo. Entonces mañana no te explico nada.
    - **Chef Lola:** Última pregunta: un cliente te grita porque su café está frío. ¿Qué haces? _[plano PrimerPlano de Chef Lola · en la pausa: Piensa · silencio 0.8 s]_
    - ❓ **Pregunta al jugador:** ¿Qué contestas?
      - ➤ «Le pido perdón y le hago otro» _(efecto: empatia +1)_
        - **Chef Lola:** Correcto. Aunque tenga la culpa él. Luego, en la cocina, te quejas conmigo.
      - ➤ «Le explico con calma que acaba de salir» _(efecto: valentia +1)_
        - **Chef Lola:** Con calma, vale. Pero la próxima vez, hazle otro. Es más rápido.
    - **Chef Lola:** Contratado/a. _[plano PrimerPlano de Chef Lola · en la pausa: Sonrie · silencio 1.0 s]_
    - **Chef Lola:** Lunes, nueve en punto. Ni nueve y cinco. _[gesto HandsOnHips]_
  - ➤ **Opción «Supermercado: reponer con Paco»** (con Paco) _(efecto: decisión «empleo» = Reponedor)_
    - _(si NO tienes la marca «hurto»)_ **Paco:** Hmm. Joven. Siéntate. No, ahí no, que es una caja de tomates.
    - _(si tienes las marcas «hurto» y «perdon paco»)_ **Paco:** Hmm. Tú. Te conozco: lo del almacén. Me pediste perdón mirando a los ojos. Todo el mundo merece una segunda oportunidad. Una.
    - _(si tienes la marca «hurto» y NO tienes la marca «perdon paco»)_ **Paco:** Hmm. Tú. Te llevaste mis latas y ni pediste perdón. …Te contrato igual, porque no encuentro a nadie. Pero te vigilo. Mucho.
    - _(si en «perfil» elegiste «Responsable»)_ **Paco:** Hmm. Aquí pone «responsable». Eso lo dice todo el mundo. Ya veremos. _[plano PrimerPlano de Paco · en la pausa: Piensa]_
    - **Paco:** Hmm. _[plano Hombro de Tú → Paco · en la pausa: Mira · silencio 1.0 s]_
    - ❓ **Pregunta al jugador:** «¿Has trabajado antes?»
      - ➤ «No, pero soy de fiar» _(efecto: responsabilidad +1)_
        - **Paco:** Hmm. De fiar. Eso ya lo veremos. Pero me gusta que no me cuentes historias.
      - ➤ «Sí, en un supermercado enorme» (no es verdad) _(efecto: marca «mentiste entrevista»)_
        - **Paco:** ¿Enorme? Hmm. Ya veremos lo enorme que era.
    - **Paco:** Aquí la regla es una: lo pesado abajo, lo frágil arriba. Si lo haces al revés, lo pagan los huevos.
    - **Paco:** Lunes a las nueve. Con zapatillas cómodas. _[plano PrimerPlano de Paco · silencio 0.6 s]_
    - **Paco:** Hmm. _[en la pausa: Asiente · silencio 0.8 s]_
  - ➤ **Opción «Correos: repartir paquetes con Ernesto»** (con Ernesto) _(efecto: decisión «empleo» = Repartidor)_
    - _(si en «perfil» elegiste «Aprendo»)_ **Ernesto:** «Aprendo rápido», pone en tu perfil. Perfecto: hoy aprendes las calles. _[plano Medio de Ernesto]_
    - **Ernesto:** ¿Conoces Valmar? Te pongo a prueba: ¿dónde está la farmacia? _[plano Hombro de Tú → Ernesto · en la pausa: Mira · silencio 0.5 s]_
    - ❓ **Pregunta al jugador:** ¿Qué contestas?
      - ➤ «Al lado de la librería, donde hacía los recados de pequeño/a» _(efecto: curiosidad +1)_
        - **Ernesto:** ¡Exacto! Los recados de niño son la mejor escuela de repartidor.
      - ➤ «Ni idea, pero tengo mapa en el móvil» _(efecto: humor +1)_
        - **Ernesto:** Sincero. Y práctico. El móvil falla, eh. Los perros no.
    - ❓ **Pregunta al jugador:** «¿Has repartido antes?»
      - ➤ «No. Pero voy andando a todas partes» _(efecto: responsabilidad +1)_
        - **Ernesto:** Bien. Piernas y verdad. Con eso me vale.
      - ➤ «Sí, muchísimo» (no es verdad) _(efecto: marca «mentiste entrevista»)_
        - **Ernesto:** ¿Muchísimo? Qué bien. Entonces el lunes te doy la ruta difícil.
    - **Ernesto:** Lunes a las nueve. _[plano PrimerPlano de Ernesto · silencio 0.6 s]_
    - **Ernesto:** Y un consejo: el perro del número 12 ladra, pero no muerde. El del 14, al revés. _[en la pausa: Piensa · silencio 0.8 s]_
- **Paso 7 · Transición (pasa el tiempo)** — «El lunes, a las nueve en punto…»
  - ⏳ _Pantalla de transición:_ «El lunes, a las nueve en punto…»
- **Paso 8 · Ir a** la Cafetería Central — «Primer día: llega puntual a la cafetería» _(solo si en «empleo» elegiste «Barista»)_
  - _En escena:_ Chef Lola (si en «empleo» elegiste «Barista»), Paco (si en «empleo» elegiste «Reponedor»), Ernesto (si en «empleo» elegiste «Repartidor»)
- **Paso 9 · Ir a** el supermercado — «Primer día: llega puntual al supermercado» _(solo si en «empleo» elegiste «Reponedor»)_
  - _Lugar:_ el supermercado
- **Paso 10 · Ir a** Correos — «Primer día: llega puntual a Correos» _(solo si en «empleo» elegiste «Repartidor»)_
  - _Lugar:_ Correos
- **Paso 11 · Escena**
  - _Lugar:_ la Cafetería Central
  - _(si en «empleo» elegiste «Barista» y tienes la marca «llegas tarde trabajo»)_ **Chef Lola:** Llegas tarde el primer día. Hmm. Que no se repita. ¡Delantal!
  - _(si en «empleo» elegiste «Reponedor» y tienes la marca «llegas tarde trabajo»)_ **Paco:** Las nueve y cuarto. Hmm. En este súper, las nueve son las nueve.
  - _(si en «empleo» elegiste «Repartidor» y tienes la marca «llegas tarde trabajo»)_ **Ernesto:** Los paquetes no esperan, y tú has llegado tarde. Venga, que aún llegamos.
  - _(si en «empleo» elegiste «Barista» y NO tienes la marca «llegas tarde trabajo»)_ **Chef Lola:** ¡Puntual! Así me gusta. Mira: cafetera, bandeja, mesas. Café en la mesa que te marque. Sonrisa siempre.
  - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «llegas tarde trabajo»)_ **Paco:** Puntual. Hmm. Bien. Almacén, cajas, estanterías. Lo pesado abajo. Ya lo sabes.
  - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «llegas tarde trabajo»)_ **Ernesto:** ¡Puntual! Así da gusto. Recoge los paquetes aquí y llévalos al buzón que te marque el mapa.
  - _(si en «empleo» elegiste «Barista» y tienes la marca «mentiste entrevista»)_ **Chef Lola:** …Y como tienes TANTA experiencia, hoy te las apañas sin explicaciones. ¿No? ¿Seguro?
  - _(si en «empleo» elegiste «Reponedor» y tienes la marca «mentiste entrevista»)_ **Paco:** El que ha trabajado en un súper enorme sabe dónde van las cajas. Adelante. Hmm.
  - _(si en «empleo» elegiste «Repartidor» y tienes la marca «mentiste entrevista»)_ **Ernesto:** Ruta difícil para quien tiene muchísima experiencia. Suerte con el perro del 14.
  - _Narrador:_ _Busca el tablón de trabajo del sitio y empieza tu turno._
- **Paso 12 · Acción del jugador** — «Empieza el turno (tablón de trabajo) y sirve cafés (0/2)» _(solo si en «empleo» elegiste «Barista»)_
- **Paso 13 · Acción del jugador** — «Empieza el turno (tablón de trabajo) y repón cajas (0/2)» _(solo si en «empleo» elegiste «Reponedor»)_
  - _Lugar:_ el supermercado
- **Paso 14 · Acción del jugador** — «Empieza el turno (tablón de trabajo) y reparte paquetes (0/2)» _(solo si en «empleo» elegiste «Repartidor»)_
  - _Lugar:_ Correos
- **Paso 15 · Escena**
  - _Lugar:_ Aquí · _En escena:_ Chef Lola (si en «empleo» elegiste «Barista»), Paco (si en «empleo» elegiste «Reponedor»), Ernesto (si en «empleo» elegiste «Repartidor»), Bruno (si en «empleo» elegiste «Barista»), Leire (si en «empleo» elegiste «Repartidor»)
  - _(si en «empleo» elegiste «Barista»)_ _Narrador:_ _¡CRASH! Se te cae una bandeja entera. Y el cliente de la mesa es… Bruno._
  - _(si en «empleo» elegiste «Barista»)_ **Bruno:** ¿Tú? ¿Aquí? Jajaja. No, espera. No me río. Bueno, un poco. ¿Te ayudo a recoger?
  - _(si en «empleo» elegiste «Reponedor»)_ _Narrador:_ _Al colocar una caja, la torre de latas de arriba se tambalea… y cae. Treinta latas rodando por el pasillo._
  - _(si en «empleo» elegiste «Repartidor»)_ _Narrador:_ _Un paquete pone «Leire». Llamas al timbre. Abre Leire, en pijama._
  - _(si en «empleo» elegiste «Repartidor»)_ **Leire:** …No has visto nada. No me has visto en pijama. Dame el paquete. Es una lente nueva. Gracias. Adiós.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Lo cuentas tal cual a tu jefe y lo arreglas» _(efecto: responsabilidad +1; marca «buen trabajo»)_
      - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Se cae todo el mundo. Lo importante es que me lo digas. Recoge y sigue.
      - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Hmm. Treinta latas. Ninguna rota. Y me lo has dicho tú. Bien. Muy bien, incluso.
      - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** ¿Que la del paquete era una amiga? Pues entrega perfecta y discreta. Así se hace.
    - ➤ «Te lo tomas con humor y sigues» _(efecto: humor +1)_
      - _(si en «empleo» elegiste «Barista»)_ **Bruno:** Esto lo cuento en clase. Es broma. …O no. Te dejo propina. Por el espectáculo.
      - _(si en «empleo» elegiste «Reponedor»)_ _Narrador:_ _Haces una reverencia a los clientes que miran. Alguien aplaude. Paco no._
      - _(si en «empleo» elegiste «Repartidor»)_ _Narrador:_ _Le deseas a Leire un buen día «en su precioso pijama de nubes». Te cierra la puerta. Oyes cómo se ríe detrás._
- **Paso 16 · Acción del jugador** — «Termina el turno (0/2)» _(solo si en «empleo» elegiste «Barista»)_
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola (si en «empleo» elegiste «Barista»), Paco (si en «empleo» elegiste «Reponedor»), Ernesto (si en «empleo» elegiste «Repartidor»)
- **Paso 17 · Acción del jugador** — «Termina el turno (0/2)» _(solo si en «empleo» elegiste «Reponedor»)_
  - _Lugar:_ el supermercado
- **Paso 18 · Acción del jugador** — «Termina el turno (0/2)» _(solo si en «empleo» elegiste «Repartidor»)_
  - _Lugar:_ Correos
- **Paso 19 · Escena**
  - _Lugar:_ la Cafetería Central
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Toma. Tu primer sobre. Te lo has ganado. Bueno, casi todo: la bandeja la descuento en abrazos.
  - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Tu paga. Hmm. Has trabajado bien. Para ser la primera vez. No te acostumbres a que lo diga.
  - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** Tu primer sueldo de repartidor. Ni un paquete perdido. Y el perro del 14 te ha cogido cariño.
  - _Narrador:_ _Un sobre con tu nombre. Dentro, el primer dinero que has ganado tú. Pesa poco. Parece que pesa mucho._ _[plano PPP de Tú · silencio 1.0 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces con él?
    - ➤ «Guardarlo para lo que querías» _(efecto: responsabilidad +1; decisión «sueldo» = Meta)_
    - ➤ «Invitar a tu familia a cenar fuera» _(efecto: Abu +6; Mamá/Papá +8; empatia +1; decisión «sueldo» = Familia)_
    - ➤ «Una parte para ti, otra para ahorrar» _(efecto: responsabilidad +1; decisión «sueldo» = Mitad)_
- **Paso 20 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 21 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡[tu nombre], con sueldo! ¿Cómo ha sido? Cuéntalo todo.
  - _(si en «sueldo» elegiste «Familia»)_ **Mamá/Papá:** ¿Que nos invitas a cenar? No hacía falta… Pero ya que insistes, yo quiero postre.
  - **Abu:** ¿Ves? Ese sobre no se olvida. Dentro de cincuenta años te acordarás de hoy.
  - _(si tienes la marca «mentiste entrevista»)_ **Mamá/Papá:** Y oye: lo de la entrevista… ¿dijiste la verdad? Porque las mentiras en el trabajo tienen patas muy cortas.
  - _Narrador:_ _Esa noche guardas el sobre vacío en un cajón. No sabes por qué. Pero lo guardas._

**Al terminar (momento de la biografía):** «Tu primer sueldo»

---

### Pan3_Cruce · «El cruce de caminos»

**Resumen:** Rayo te ofrece dinero fácil. Nerea quiere salir. Hay decisiones que marcan quién vas a ser.

_Tipo: Historia · El camino (bien o mal) · Edad: 15-15 años · Duración: 20-30 min_

**Requisitos:** has terminado «El primer empleo» y has vivido el 52 % de la etapa

**Lo que puede cambiar:** Camino delincuente (con una última oportunidad) · Camino trabajador · Salvar a Rayo

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unos meses después. Tercero de la ESO.»
  - ⏳ _Pantalla de transición:_ «Unos meses después. Tercero de la ESO.»
- **Paso 2 · Ir a** el parque — «Rayo está en el parque, solo»
  - _Lugar:_ el parque · _En escena:_ Rayo
- **Paso 3 · Cinemática**
  - 🎬 **Cinemática «Pan3_Oferta»** _(música: intensidad Nada → Tension)_
    - _En escena:_ Rayo
    - _Cámara:_ 1 planos (General)
    - **Rayo:** Tres días de expulsión. Mi madre ni se ha enterado. _[plano Lateral de Rayo]_
    - **Rayo:** Trabaja de noche. Duerme de día. Somos compañeros de piso, más o menos. _[plano Lateral de Rayo · gesto Shrug]_
    - _(si tienes la marca «pillado»)_ **Rayo:** Por lo del súper. Y tú… tú no dijiste nada. Eso no se me olvida. _[plano PrimerPlano de Rayo · en la pausa: Mirar]_
    - _(si tienes la marca «escapaste»)_ _(o bien)_ **Rayo:** Tú corriste más que yo. Ahora ya sabes lo que es. Y no te ha ido tan mal, ¿no? _[plano PrimerPlano de Rayo · en la pausa: Mirar]_
    - _(si NO tienes la marca «hurto»)_ _(o bien)_ **Rayo:** Tú no viniste. Da igual. Te voy a dar otra oportunidad. Porque me caes bien. No sé por qué. _[plano PrimerPlano de Rayo · en la pausa: Mirar]_
    - _(si en «plan» elegiste «Frenar»)_ **Rayo:** Nerea dice que tú le dijiste que no fuera. Y no fue. A ti te hace caso. A mí ya no. _[plano Lateral de Rayo · gesto Sad · en la pausa: Apartar]_
    - **Rayo:** Tengo un negocio. _[plano PrimerPlano de Rayo · en la pausa: Mirar · silencio 1.0 s]_
    - **Rayo:** Camisetas del Altamar. Iguales que las de verdad, a una cuarta parte del precio. Las vendemos a la salida del estadio. _[plano Hombro de Tú → Rayo]_
    - **Rayo:** Cincuenta pavos por tarde. Nadie sale herido. El club tiene millones. _[plano Medio de Rayo · gesto Shrug]_
    - **Rayo:** ¿Qué me dices? _[plano Hombro de Rayo → Tú · silencio 0.8 s]_
    - _Narrador:_ _Cincuenta. Por una tarde. Piensas en todo lo que se puede hacer con cincuenta._ _[plano PPP de Tú · silencio 0.6 s]_
    - _(si tienes la marca «mentiste familia»)_ _Narrador:_ _Y te acuerdas de Abu: «las mentiras pesan más que la mochila»._ _[plano PPP de Tú]_
    - **Rayo:** Piénsatelo. Yo aquí estoy. Como siempre. _[plano DosPlanos de Rayo → Tú · en la pausa: Apartar]_
    - 🔀 **Variante «Distantes»** (si tu relación con Rayo es menor que 0): cambia Actors, Music por:
      - _En escena:_ Rayo
- **Paso 4 · Ir a** el patio — «Nerea quiere hablar contigo en el patio»
  - _Lugar:_ el patio · _En escena:_ Nerea
- **Paso 5 · Hablar** con Nerea — «Siéntate con Nerea»
  - **Nerea:** Me voy de la pandilla. Ya está. Estoy harta de correr, de mentir en casa y de que Rayo decida por mí. _[plano Medio de Nerea · gesto ArmsCrossed]_
  - _(si tienes la marca «hurto» y tienes el recuerdo «la noche»)_ **Nerea:** Desde la noche del súper no he vuelto a dormir bien. ¿Tú sí? _[en la pausa: Mira · silencio 0.8 s]_
  - **Nerea:** Pero me da miedo. _[plano PrimerPlano de Nerea · gesto Nervous · en la pausa: Baja · silencio 1.2 s]_
  - **Nerea:** Si me voy, no tengo a nadie. En mi clase soy «la de la pandilla de Rayo». Nadie se me acerca. _[gesto Sad]_
  - _(si tienes la marca «amiga nerea»)_ **Nerea:** Tú me dijiste que mis dibujos eran buenos. Nadie me había dicho eso. Nunca.
  - **Nerea:** Rayo te ha ofrecido lo de las camisetas, ¿no? A mí también. _[silencio 0.6 s]_
  - **Nerea:** ¿Qué vas a hacer? _[plano Hombro de Tú → Nerea · en la pausa: Mira · silencio 1.0 s]_
- **Paso 6 · Decisión** — «¿Qué camino eliges?»
  - ➤ **Opción «Entrar en el negocio de Rayo: dinero fácil»** _(efecto: decisión «camino» = Negocio; Nerea -6; Rayo +8; rebeldia +3; marca «camino delincuente»)_
  - ➤ **Opción «Alejarte de la pandilla y ayudar a Nerea a salir»** _(efecto: decisión «camino» = Alejarse; Nerea +10; Rayo -4; responsabilidad +2; marca «camino trabajador»)_
  - ➤ **Opción «Intentar que Rayo lo deje (y ofrecerle otra cosa)»** _(efecto: decisión «camino» = Salvar; Nerea +6; Rayo +4; empatia +2; valentia +1; marca «camino trabajador»)_
- **Paso 7 · Ir a** el Estadio Altamar — «Sábado: vende camisetas falsas del Altamar a la salida del estadio» _(solo si en «camino» elegiste «Negocio»)_
  - _Lugar:_ el Estadio Altamar · _En escena:_ Rayo
- **Paso 8 · Escena** _(solo si en «camino» elegiste «Negocio»)_
  - _En escena:_ Rayo, Nico
  - _Narrador:_ _A la salida del partido, cientos de personas. Rayo abre una bolsa: camisetas del Altamar. Iguales. Casi._
  - **Rayo:** Tú grita: «¡Camisetas, a diez!». Yo cobro. Si ves a un policía, silba.
  - _Narrador:_ _Vendes una. Dos. Cinco. Es fácil. Demasiado fácil._
  - _Narrador:_ _Y entonces, entre la gente, alguien se para delante de ti con la bolsa de deporte del juvenil del Altamar. Es Nico._
  - **Nico:** ¿[tu nombre]? _[plano PrimerPlano de Nico · gesto Surprised · silencio 0.6 s]_
  - **Nico:** ¿Qué haces con… esas camisetas? Son falsas. Son de MI equipo. ¿En serio? _[plano Hombro de Tú → Nico · gesto Angry · en la pausa: Niega · silencio 0.6 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Es solo un negocio. No te metas.» _(efecto: Nico -15; rebeldia +1)_
      - **Nico:** …Vale. No me meto. Pero no me hables en el recreo. No sé quién eres.
      - _Narrador:_ _Esa tarde ganas cincuenta. Te pesan en el bolsillo más que cualquier mochila._
    - ➤ «Dejas la bolsa en el suelo y te vas con Nico» _(efecto: Nico +6; Rayo -8; valentia +2; marca «camino trabajador» y «redimido»)_
      - **Rayo:** ¡Eh! ¿Adónde vas? ¡¿ADÓNDE VAS?!
      - **Nico:** Vámonos. Te invito a un bocadillo. Y no se lo cuento a nadie. Bueno, a Omar sí. A Omar se lo cuento todo.
- **Paso 9 · Ir a** tu aula del instituto — «Acompaña a Nerea a hablar con Carmen, la orientadora» _(solo si en «camino» elegiste «Alejarse»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Nerea (te acompaña)
- **Paso 10 · Escena** _(solo si en «camino» elegiste «Alejarse»)_
  - _En escena:_ Carmen, Nerea
  - **Carmen:** Nerea, ¿verdad? He visto tus dibujos. [tu nombre] me los ha enseñado. Con tu permiso, espero.
  - **Carmen:** Los jueves hay un taller de cómic en la biblioteca del campus. Lo lleva Toni, el tío de Leire. Creo que te encantaría.
  - **Nerea:** ¿Un taller de… cómic? ¿Con gente que dibuja? …Vale. Pero [tu nombre] viene conmigo el primer día.
  - **Carmen:** Salir de un sitio así cuesta mucho. Hacerlo acompañado, un poco menos. Bien hecho, los dos.
- **Paso 11 · Ir a** la gasolinera — «Ve al taller de Tobías (gasolinera): a Rayo le encantan los motores» _(solo si en «camino» elegiste «Salvar»)_
  - _Lugar:_ la gasolinera · _En escena:_ Tobías
- **Paso 12 · Hablar** con Tobías — «Habla con Tobías» _(solo si en «camino» elegiste «Salvar»)_
  - **Tobías:** ¿Un chaval que se pasa el día desmontando motos que no son suyas? Hmm. Eso es talento mal usado.
  - **Tobías:** Que venga mañana a las ocho. Si llega a las ocho y cinco, que no venga. Si llega a las ocho, le enseño todo lo que sé.
- **Paso 13 · Ir a** el parque — «Vuelve al parque: díselo a Rayo» _(solo si en «camino» elegiste «Salvar»)_
  - _Lugar:_ el parque · _En escena:_ Rayo
- **Paso 14 · Hablar** con Rayo — «Habla con Rayo» _(solo si en «camino» elegiste «Salvar»)_
  - **Rayo:** ¿Tú otra vez? ¿Vienes a comprarme una camiseta?
  - _Narrador:_ _Le cuentas lo de Tobías. Un taller de verdad. Motores de verdad. Mañana a las ocho._
  - _(si tu relación con Rayo es menor que 5)_ **Rayo:** ¿Por qué haces esto? Tú siempre me has dicho que no a todo. Eres la única persona que no me ha dejado tirado. Qué raro.
  - _(si tu relación con Rayo es de 5 o más)_ **Rayo:** ¿Por qué haces esto? Estabas en todo conmigo. Podrías seguir. Y vienes a sacarme a mí.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Porque te mereces algo mejor que correr delante de la policía.» _(efecto: Rayo +10; marca «rayo cambia»)_
      - **Rayo:** …A las ocho. Vale. Pero si el viejo es un pesado, me piro.
      - _Narrador:_ _No se pira. Al día siguiente llega a las ocho menos cuarto._
    - ➤ «Porque eres mi amigo. Aunque a veces no lo parezca.» _(efecto: Rayo +12; empatia +1; marca «rayo cambia»)_
      - **Rayo:** (se frota la cara) …Qué pesado/a. Vale. A las ocho. Y no se lo digas a nadie de la pandilla.
- **Paso 15 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 16 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - _Narrador:_ _Esa noche te miras en el espejo del baño. Quince años. Te preguntas quién estás siendo._
  - _(si tienes la marca «camino delincuente»)_ _Narrador:_ _Tienes cincuenta euros escondidos en un calcetín. Y un mensaje de Nico sin contestar._
  - _(si tienes la marca «camino delincuente»)_ **Mamá/Papá:** Te noto raro/a últimamente. Llegas tarde, no hablas… Sabes que puedes contarme lo que sea, ¿verdad? Lo que sea.
  - _(si tienes la marca «camino delincuente»)_ **Abu:** Yo también tuve malas compañías a tu edad. Lo difícil no es entrar. Es salir. Pero se sale. Siempre se sale.
  - _(si tienes la marca «camino trabajador» y tu rasgo rebeldia es 2 o más)_ _Narrador:_ _Hiciste cosas de las que no estás orgulloso/a. Pero hoy has elegido otra cosa. Y eso también cuenta. Mucho._
  - _(si tienes la marca «camino trabajador» y tu rasgo rebeldia es menor que 2)_ _Narrador:_ _Nunca te dejaste arrastrar. Y hoy, además, has tendido la mano a alguien. Así se construye una persona._
  - _(si en «camino» elegiste «Alejarse»)_ **Mamá/Papá:** Me ha llamado la madre de Nerea. Dice que su hija ha vuelto a dibujar. Que ha sido gracias a ti. …Ven aquí. Abrazo. No te escapes.
  - _(si en «camino» elegiste «Salvar»)_ **Mamá/Papá:** Me ha contado Tobías, el del taller, que le has llevado a un chaval. Que llegó a las ocho menos cuarto. Qué orgullo me das.

**Al terminar (momento de la biografía):** «El cruce de caminos»

---

### Ins05_ElRumor · «El rumor»

**Resumen:** Una foto trucada de Omar corre por el grupo de la clase. Omar no ha venido. Alguien la hizo, y alguien la compartió.

_Tipo: Historia · Conflicto · Edad: 15-16 años · Duración: 25-35 min_

**Requisitos:** has terminado «El cruce de caminos» y has vivido el 62 % de la etapa

**Lo que puede cambiar:** Reenviar o frenar la foto · Confiar en Bruno o no · Cómo hablas con Nico · Qué pasa con Darío · Cómo consuelas a Omar

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Un año después. Un martes cualquiera…»
  - ⏳ _Pantalla de transición:_ «Un año después. Un martes cualquiera…»
- **Paso 2 · Ir a** tu aula del instituto — «Ve a clase: todo el mundo está mirando el móvil»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Sara, Leire, Nico, Bruno, Alumno, Alumna
- **Paso 3 · Escena**
  - _Narrador:_ _Toda la clase mira el móvil. Risitas. Alguien dice «qué bueno» y otro «pobre»._
  - **Sara:** [tu nombre], mira. Está en el grupo de la clase desde anoche. _[plano Hombro de Tú → Sara · gesto Nervous]_
  - _Narrador:_ _Es una foto de Omar comiendo, trucada: la cabeza es un bocadillo gigante. Debajo pone «OMAR EL TRAGÓN». Tiene cuarenta reacciones._
  - **Sara:** Omar no ha venido hoy. _[plano PrimerPlano de Sara · en la pausa: Baja · silencio 1.0 s]_
  - **Sara:** Omar no falta nunca. Ni con fiebre. _[silencio 0.5 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces con la foto?
    - ➤ «Escribes en el grupo: «Borradla. No tiene gracia.»» _(efecto: Omar +5; Sara +3; valentia +2; decisión «foto» = Frenar)_
      - _Narrador:_ _Durante un minuto nadie contesta. Luego Leire escribe «+1». Luego Sara. Luego tres más. La foto deja de moverse._
    - ➤ «No haces nada en el grupo, pero no la reenvías» _(efecto: decisión «foto» = Nada)_
      - **Sara:** No reenviarla está bien. Pero no sé si basta.
    - ➤ «Se te escapa una sonrisa… y luego te sientes fatal» _(efecto: humor +-1; decisión «foto» = Reiste; marca «te reiste»)_
      - **Sara:** …¿En serio? Es Omar. NUESTRO Omar.
      - _Narrador:_ _Tiene razón. Se te borra la sonrisa. Esto hay que arreglarlo._
  - **Javier:** Móviles fuera, que empieza la clase. …Y si alguien tiene algo que contarme, mi puerta está abierta. Siempre.
  - **Sara:** En el recreo averiguamos quién la hizo. Y luego buscamos a Omar.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Averigua quién hizo la foto (en el recreo)»
  - _Lugar:_ el patio · _En escena:_ Sara (te acompaña), Leire, Bruno
  - **Paso 4.1 · Usar** — «Mira la captura con calma»
    - 🖐 _Al usar «La captura del grupo de clase»:_
      - _Narrador:_ _Miras la captura despacio. La primera persona que la subió al grupo de la clase… es Nico._
      - **Sara:** ¿Nico? No puede ser. Nico y Omar se conocen desde los seis años.
      - _Narrador:_ _Pero en una esquina de la foto hay algo más: una marca de agua pequeñita, «DR», como una firma._
  - **Paso 4.2 · Hablar** con Leire — «Pregunta a Leire: sabe de fotos»
    - **Leire:** Esa foto es un montaje malísimo. Pero la original es buena: está hecha desde arriba, con teleobjetivo.
    - **Leire:** Por la luz, de tarde. Por el fondo, la pista del instituto. Alguien estaba en la grada durante un entreno.
    - **Leire:** Y quien hace fotos así de otra persona sin preguntar… no me cae bien. Cuenta conmigo.
  - **Paso 4.3 · Hablar** con Bruno — «Todos dicen que ha sido Bruno. Habla con él»
    - **Bruno:** Ya. Ya sé lo que dicen. Que he sido yo. Siempre soy yo, ¿no?
    - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Como en el colegio, con lo de las bromas. Me acusaste sin pruebas. Y tampoco fui yo.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Te creo. Pero ayúdame: ¿sabes algo?» _(efecto: Bruno +8; empatia +1; decisión «bruno» = Confiar)_
        - **Bruno:** …¿Me crees? Vale. En el vestuario, los de segundo se reían con el móvil de Darío. Darío Ruiz. D. R.
        - **Bruno:** No me chivo. Te lo cuento. Que es distinto. Creo.
      - ➤ «Demuéstralo» _(efecto: Bruno -4; decisión «bruno» = Dudar)_
        - **Bruno:** ¿Que lo demuestre? Pues mira mi móvil. No hay nada. Y ahora, déjame en paz.
  - **Paso 4.4 · Usar** — «Busca en la pista desde dónde se hizo la foto»
    - 🖐 _Al usar «La grada de la pista»:_
      - _Narrador:_ _Subes a la grada. Desde aquí se ve exactamente el ángulo de la foto: el banquillo, la canasta, Omar merendando._
      - _Narrador:_ _En el asiento hay una pegatina del equipo de fútbol de segundo. Y alguien ha escrito con rotulador: «DR estuvo aquí»._
- **Paso 5 · Escena**
  - _En escena:_ Sara (te acompaña)
  - **Sara:** Recapitulemos. La foto se hizo desde la grada, en un entreno. Firmada «DR».
  - **Sara:** Darío Ruiz, de segundo. Del equipo de fútbol. El nuevo amigo de Nico.
  - **Sara:** Y Nico… Nico la compartió primero. Eso es lo que más me duele.
- **Paso 6 · Ir a** la pista de deporte — «Ve a la pista: Nico y Darío están en el entreno»
  - _Lugar:_ la pista de deporte · _En escena:_ Nico, Darío, Alumno, Sara (te acompaña)
- **Paso 7 · Hablar** con Nico — «Habla con Nico»
  - **Nico:** ¡[tu nombre]! ¿Vienes a ver el entreno? _[plano Medio de Nico · gesto Happy]_
  - **Nico:** …¿Por qué me miras así? _[plano PrimerPlano de Nico · gesto Nervous · en la pausa: Mira · silencio 1.2 s]_
  - ❓ **Pregunta al jugador:** ¿Cómo hablas con Nico?
    - ➤ «Te lo llevas aparte: «¿Por qué la compartiste?»» _(efecto: Nico +3; empatia +1; decisión «hablas nico» = Privado)_
      - **Nico:** Yo… Darío me la pasó y todos se reían. Quería que se rieran conmigo. Que me vieran como uno de ellos. _[plano PrimerPlano de Nico · gesto Ashamed · en la pausa: Baja]_
      - **Nico:** No pensé que Omar la vería. No pensé nada. Qué idiota. _[gesto Facepalm · silencio 0.8 s]_
      - **Nico:** Omar es… Omar. _[plano PPP de Nico · gesto Sad · en la pausa: Aparta · silencio 1.2 s]_
    - ➤ «Se lo dices delante de todo el equipo» _(efecto: Nico -6; valentia +1; decisión «hablas nico» = Publico)_
      - **Nico:** ¿Delante de todos? Vale, vale, me lo merezco. _[plano PrimerPlano de Nico · gesto Angry]_
      - **Nico:** Pero podías haberme dicho algo a mí primero. _[gesto Ashamed · en la pausa: Baja · silencio 0.8 s]_
      - _Narrador:_ _El equipo se queda en silencio. Nico mira al suelo._ _[silencio 0.6 s]_
  - **Nico:** Voy a hablar con Omar. Hoy. Te lo prometo. _[plano Hombro de Tú → Nico · en la pausa: Mira · silencio 1.0 s]_
- **Paso 8 · Hablar** con Darío — «Habla con Darío»
  - **Darío:** ¿Qué pasa? Era una broma. Se ha hecho viral, eso es bueno, ¿no? Omar es famoso.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Bórrala y pídele perdón. Tú no la estás viviendo; él sí.» _(efecto: empatia +1; valentia +1; decisión «dario» = Perdon)_
      - **Darío:** …No lo había visto así. Él no se reía, ¿no? Vale. La borro. Y… le escribo.
    - ➤ «Se lo cuentas a Javier, el tutor» _(efecto: Javier +4; responsabilidad +2; decisión «dario» = Javier)_
      - **Javier:** (más tarde) Gracias por contármelo. Esto no es una broma: es hacer daño en público. Me encargo. Y hablaré con toda la clase.
    - ➤ «Le devuelves la broma: un montaje suyo en el grupo» _(efecto: Omar -2; humor +1; decisión «dario» = Venganza; marca «montaje dario»)_
      - **Darío:** ¿Ah, sí? Pues ahora os vais a enterar.
      - _Narrador:_ _Durante dos días el grupo de clase es una guerra de montajes. Nadie se ríe ya. Y Omar sigue sin venir._
- **Paso 9 · Ir a** el parque — «Busca a Omar. Sara cree que sabe dónde está: en el banco del parque»
  - _Lugar:_ el parque · _En escena:_ Omar
- **Paso 10 · Hablar** con Omar — «Siéntate con Omar»
  - _Narrador:_ _Omar está en el banco del parque. El mismo banco de siempre. Con la capucha puesta._
  - _(si en «promesa» elegiste «Banco»)_ **Omar:** El banco del verano. Prometimos quedar aquí. No pensaba que lo usaría para esconderme.
  - **Omar:** Hola. Ya has visto la foto, ¿no? Todo el mundo la ha visto. «Omar el Tragón». Ja.
  - **Omar:** Lo peor no es la foto. Lo peor es que Nico la compartió. _[plano PrimerPlano de Omar · gesto Sad · en la pausa: Aparta]_
  - **Omar:** Nico. _[en la pausa: Baja · silencio 1.2 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Te sientas a su lado sin decir nada. Solo estar» _(efecto: Omar +8; empatia +2)_
      - _Narrador:_ _Os quedáis un rato largo en silencio. Al final, Omar te da la mitad de su bocadillo. «Toma. Tragones los dos.» Y se ríe. Un poco._
    - ➤ _(si en «foto» elegiste «Frenar»)_ «Borré la foto del grupo. Y no va a volver.» _(efecto: Omar +10)_
      - **Omar:** ¿Fuiste tú? Leire me dijo que alguien había plantado cara. No sabía que eras tú. Gracias.
    - ➤ «Nico está fatal. Quiere pedirte perdón.» _(efecto: Nico +3; Omar +5; responsabilidad +1)_
      - **Omar:** …Que venga él. Que me lo diga él. Si lo hace, a lo mejor le perdono. A lo mejor.
    - ➤ _(si tienes la marca «te reiste»)_ «Perdona. Yo también me reí al principio.» _(efecto: Omar +6; valentia +1)_
      - **Omar:** …Gracias por decírmelo. Duele. Pero prefiero saberlo de ti que enterarme por otro.
  - **Omar:** Mañana vuelvo a clase. Si vienes a buscarme. Por la mañana. A la parada.
- **Paso 11 · Transición (pasa el tiempo)** — «Al día siguiente…»
  - ⏳ _Pantalla de transición:_ «Al día siguiente…»
- **Paso 12 · Ir a** tu aula del instituto — «Ve a clase»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Nico, Sara, Leire, Bruno
- **Paso 13 · Cinemática**
  - _En escena:_ Javier, Nico, Sara, Leire, Bruno, Omar
  - 🎬 **Cinemática «Ins05_DiaDespues»** _(música: intensidad Nada → Intima → Resolucion)_
    - _En escena:_ Javier, Omar, Nico, Sara, Leire, Bruno, Darío · _entran andando:_ Darío · _salen:_ Darío
    - _Cámara:_ 2 planos (General, Seguir)
    - _Narrador:_ _Pasas a buscar a Omar a la parada. Entráis juntos en clase. Nadie dice nada._
    - **Bruno:** Eh, Omar. Choca. _[a Omar · plano Reaccion de Bruno · gesto WaveLite · silencio 0.6 s]_
    - **Omar:** …Hola. _[plano PrimerPlano de Omar · en la pausa: Suelo]_
    - _(si en «dario» elegiste «Javier»)_ **Javier:** Antes de empezar: el grupo de clase es de esta clase. Lo que no diríais a la cara, no se escribe ahí. _[plano Medio de Javier]_
    - **Javier:** Si alguna vez os pasa algo así, contadlo a un adulto. A mí, a vuestra familia. No es chivarse: es cuidarse. _[plano Medio de Javier]_
    - _(si en «dario» elegiste «Javier»)_ **Darío:** Omar… lo siento. De verdad. Era una tontería y no lo pensé. _[a Omar · plano PrimerPlano de Darío · en la pausa: Suelo]_
    - _(si en «dario» elegiste «Perdon»)_ **Omar:** Mira. Darío me escribió anoche: «Perdón. La he borrado. Fue una idiotez.» _[plano DosPlanos de Omar → Tú]_
    - _(si en «dario» elegiste «Venganza»)_ _Narrador:_ _La guerra de montajes ha terminado porque Javier ha borrado el grupo entero. Nadie sale bien parado. Tú tampoco._ _[plano Reaccion de Tú]_
    - **Nico:** Omar. Yo… lo siento. _[a Omar · plano PrimerPlano de Nico · en la pausa: Suelo · silencio 1.2 s]_
    - **Nico:** No hay excusa. Me pasé. Te echo de menos en el recreo. _[a Omar · plano Hombro de Omar → Nico · en la pausa: Mirar]_
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** [tu nombre] me lo dijo a la cara, sin nadie delante. Ahora te lo digo yo a ti. _[a Omar · plano PrimerPlano de Nico]_
    - _(si en «hablas nico» elegiste «Publico»)_ _(o bien)_ **Nico:** Me lo dijeron delante de todo el equipo. Me lo merecía. Ahora te lo digo yo delante de todos. _[a Omar · plano PrimerPlano de Nico]_
    - **Omar:** …Vale. _[plano PPP de Omar · en la pausa: Pensar · silencio 1.4 s]_
    - **Omar:** Pero me debes diez bocadillos. Y los eliges tú, que así sufres. _[a Nico · plano DosPlanos de Omar → Nico · gesto Happy]_
    - **Omar:** He hecho pulseras para todos. Del grupo. Por si se nos olvida quiénes somos. _[plano Medio de Omar · en la pausa: Mirar · silencio 0.6 s]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Sara:** Pone «Los Imparables». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Sara:** Pone «La Patrulla Valmar». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Sara:** Pone «Los del Banco Azul». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Sara:** Pone «Los Dinosaurios». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si tienes la marca «te reiste»)_ **Omar:** Y la primera es para ti. Te reíste, y me lo dijiste. Eso cuenta. _[plano Hombro de Tú → Omar]_
    - _(si en «foto» elegiste «Frenar» y NO tienes la marca «te reiste»)_ _(o bien)_ **Leire:** La foto dejó de moverse porque alguien escribió «Borradla». Yo solo puse el +1. _[plano Reaccion de Leire]_
    - _Narrador:_ _Esa mañana, en 1.º C, todos llevan la misma pulsera._ _[plano DosPlanos de Omar → Nico]_
    - 🔀 **Variante «NicoAvergonzado»** (si tu relación con Nico es menor que 0): cambia Actors por:
      - _En escena:_ Javier, Omar, Nico, Sara, Leire, Bruno, Darío · _entran andando:_ Darío · _salen:_ Darío

**Al terminar (momento de la biografía):** «Cuando defendiste a Omar»

---

### Ins06_LaGranDecision · «La gran decisión»

**Resumen:** Último curso. Selectividad, planes, dudas… y una pregunta que nadie puede contestar por ti: ¿y ahora qué?

_Tipo: Historia · Final de capítulo · Edad: 17-18 años · Duración: 25-35 min_

**Requisitos:** has terminado «El rumor» y has vivido el 90 % de la etapa

**Lo que puede cambiar:** Medicina, Ingeniería, Derecho, Economía o trabajar · Lo que te dice cada amigo · La nota de selectividad

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Dos años después. El último curso.»
  - ⏳ _Pantalla de transición:_ «Dos años después. El último curso.»
- **Paso 2 · Ir a** el patio — «Sal al patio: tus amigos hablan del futuro»
  - _Lugar:_ el patio · _En escena:_ Sara, Nico, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Iker (si tienes la marca «iker en el grupo»)
- **Paso 3 · Varios objetivos (en cualquier orden)** — «Pregunta a tus amigos qué van a hacer (al menos tres)»
  - **Paso 3.1 · Hablar** con Sara — «Sara»
    - **Sara:** Biología. Luego un doctorado. Luego descubrir una especie nueva de hongo y ponerle mi nombre. Lo tengo en una hoja de cálculo.
    - _(si tienes el recuerdo «primer dia instituto»)_ **Sara:** ¿Te acuerdas del primer día? Me había aprendido el plano entero y aun así me perdí. Ahora me pierdo menos.
    - **Sara:** ¿Y tú? No me digas «no sé». Bueno, si no lo sabes, dilo. Es un dato válido. _[en la pausa: Mira · silencio 0.6 s]_
  - **Paso 3.2 · Hablar** con Omar — «Omar»
    - **Omar:** Cocina. FP de cocina. Lola me ha dicho que si termino, me coge. Voy a hacer la mejor tortilla de Valmar. Lola dice que eso es imposible.
    - _(si tienes el recuerdo «el rumor»)_ **Omar:** Da un poco de miedo, ¿sabes? Que se acabe esto. Pero me llevo la pulsera.
  - **Paso 3.3 · Hablar** con Nico — «Nico»
    - **Nico:** Me han llamado de las pruebas del club de Altamar. Juvenil. Si no sale, estudio para ser entrenador. Como Andrés.
    - _(si en «sabado» elegiste «Cumple»)_ **Nico:** Y aquel sábado viniste a mi cumple en vez de ir al club. Eso tampoco se me olvida.
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** Oye… nunca te lo he dicho bien: gracias por lo de Omar. Por decírmelo a la cara, aparte. _[en la pausa: Baja · silencio 0.8 s]_
    - _(si en «camino» elegiste «Negocio» y tienes la marca «redimido» y tienes el recuerdo «el cruce»)_ **Nico:** Y aquel día en el estadio, cuando soltaste la bolsa de camisetas… Ese día supe que seguías siendo tú. _[en la pausa: Mira · silencio 0.6 s]_
  - **Paso 3.4 · Hablar** con Bruno — «Bruno»
    - **Bruno:** ¿Yo? Policía. No te rías. Inés, la de la comisaría, dice que se me da bien que la gente me haga caso.
    - **Bruno:** Y que ahora sé cuándo hay que usarlo y cuándo no. Eso lo aprendí con vosotros. No se lo digas a nadie.
    - _(si en «bruno» elegiste «Confiar»)_ **Bruno:** Me creíste cuando todos decían que la foto era mía. Eso no se me olvida.
    - _(si tienes la marca «camino delincuente»)_ **Bruno:** También por gente como Rayo. Y como tú, últimamente. No te lo tomes a mal. Quiero ser el policía que te habría gustado encontrarte.
  - **Paso 3.5 · Hablar** con Leire — «Leire» _(solo si tienes la marca «conoces a leire»)_
    - **Leire:** Comunicación audiovisual. En otra ciudad, probablemente. Mi tío dice que tengo que irme para volver con otra mirada.
    - **Leire:** Cuando llegué, pensé que aquí no tendría a nadie. Ahora me cuesta irme. Qué rabia.
  - **Paso 3.6 · Hablar** con Hugo — «Hugo» _(solo si tienes la marca «hugo con el grupo»)_
    - **Hugo:** Periodismo. O escribir novelas. O las dos cosas. Mi primera novela será de piratas. La segunda, también.
    - _(si en «reportaje» elegiste «Permiso»)_ **Hugo:** Mi primer reportaje de verdad fue el de los murales de Vega. Contigo. Lo tengo enmarcado.
    - _(si en «reportaje» elegiste «Anonimo»)_ **Hugo:** «El artista misterioso». Todavía nadie sabe que era Vega. Eso también es periodismo: saber callar.
    - _(si en «reportaje» elegiste «Nombre»)_ **Hugo:** Lo de publicar el nombre de Vega… Tenías razón en que era verdad. Pero aprendí que la verdad también duele.
  - **Paso 3.7 · Hablar** con Mateo — «Mateo» _(solo si tienes la marca «ayudaste a mateo»)_
    - **Mateo:** Ingeniería. Mi padre es fontanero y siempre dice que hay que entender cómo funcionan las cosas. Pues quiero entenderlas todas.
    - **Mateo:** Nunca te lo he dicho, pero el primer día, cuando me ayudaste con los libros… todo empezó ahí.
  - **Paso 3.8 · Hablar** con Iker — «Iker» _(solo si tienes la marca «iker en el grupo»)_
    - **Iker:** Estadística. Obviamente. Según mis cálculos, hay un noventa y dos por ciento de probabilidades de que me encante.
- **Paso 4 · Ir a** tu aula del instituto — «Carmen te espera en su despacho (aula)»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen
- **Paso 5 · Hablar** con Carmen — «Habla con Carmen»
  - _(si tienes el recuerdo «que quieres ser»)_ **Carmen:** Pasa, [tu nombre]. ¿Te acuerdas de la semana de las profesiones? Tengo tu cuaderno apuntado aquí.
  - _(si NO tienes el recuerdo «que quieres ser»)_ **Carmen:** Pasa, [tu nombre]. Último curso. Vamos a ver qué te ronda la cabeza.
  - _(si en «orientacion» elegiste «Dudas»)_ **Carmen:** En primero saliste de mi clase con más dudas que antes. ¿Te acuerdas? Te dije que era buena señal. _[silencio 0.6 s]_
  - _(si tienes la marca «interes medicina»)_ **Carmen:** Te vi con la doctora Nuria. Dijiste que te veías en un hospital.
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Sofía todavía habla de tu puente de palillos. Eso es ingeniería pura.
  - _(si tienes la marca «interes derecho»)_ **Carmen:** Inés dijo que escuchabas a las dos partes. Eso es derecho, o policía, o mediación.
  - _(si tienes la marca «interes economia»)_ **Carmen:** Marcos pintó las bicis de azul por tu idea. Economía, empresa… lo llevas dentro.
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Tobías, Lola, Irene, Toni… hay profesiones que se aprenden trabajando. No son menos: son otro camino.
  - _(si tienes el recuerdo «primer sueldo»)_ **Carmen:** Y tu primer trabajo de verano. Eso también dice mucho de ti.
  - _(si tienes la marca «camino delincuente»)_ **Carmen:** Sé lo del estadio y lo de Rayo. No te voy a sermonear. Solo te digo una cosa: todavía puedes elegir otro camino. Siempre se puede.
  - _(si tienes la marca «redimido»)_ **Carmen:** Y sé que saliste de algo difícil hace unos años. Eso dice más de ti que cualquier nota.
  - **Carmen:** Pero te voy a decir lo mismo que hace años: no tienes que acertar. Tienes que elegir. _[plano PrimerPlano de Carmen · en la pausa: Mira · silencio 0.8 s]_
  - **Carmen:** Y si te equivocas, se cambia. _[silencio 0.8 s]_
  - **Carmen:** Nadie se queda donde empieza. Ni siquiera yo: empecé estudiando química. Mírame.
- **Paso 6 · Ir a** la Universidad de Valmar — «Jornada de puertas abiertas: visita la universidad»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Sofía, Sara (te acompaña)
- **Paso 7 · Escena**
  - _(si tienes la marca «interes ingenieria»)_ **Sofía:** ¡Anda! ¡La persona de los triángulos! Bienvenido/a a la jornada de puertas abiertas.
  - _(si NO tienes la marca «interes ingenieria»)_ **Sofía:** ¡Bienvenidos a la jornada de puertas abiertas! Aquí están todas las facultades: Medicina, Ingeniería, Derecho, Economía.
  - _Narrador:_ _El campus es enorme. Gente con carpetas, bicicletas, un chico durmiendo en el césped con un libro en la cara._
  - **Sara:** Aquí vamos a estar el año que viene. O no. Pero da igual: hoy da gusto.
- **Paso 8 · Clase** — «Estudia para la selectividad en la biblioteca del campus»
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Sara
- **Paso 9 · Escena**
  - _Lugar:_ tu aula del instituto · _En escena:_ Omar, Javier
  - **Omar:** Me he aprendido todo. Y lo he olvidado todo en el pasillo. ¿Es normal?
  - **Javier:** Es normal. Respirad. Nadie es su nota. Pero hoy, por si acaso, haced buena letra.
- **Paso 10 · Clase** — «El examen de selectividad»
  - _En escena:_ Javier
- **Paso 11 · Transición (pasa el tiempo)** — «📬 Nota de selectividad: ¡SOBRESALIENTE! Puedes entrar en cualquier carrera (Medicina pide un 8).» _(solo si tu última nota es 8 o más)_
  - ⏳ _Pantalla de transición:_ «📬 Nota de selectividad: ¡SOBRESALIENTE! Puedes entrar en cualquier carrera (Medicina pide un 8).»
- **Paso 12 · Transición (pasa el tiempo)** — «📬 Nota de selectividad: notable alto. Ingeniería (7), Derecho (6) y Economía (5). Medicina pide un 8.» _(solo si tu última nota es 7 o más y tu última nota es menor que 8)_
  - ⏳ _Pantalla de transición:_ «📬 Nota de selectividad: notable alto. Ingeniería (7), Derecho (6) y Economía (5). Medicina pide un 8.»
- **Paso 13 · Transición (pasa el tiempo)** — «📬 Nota de selectividad: bien. Puedes entrar en Derecho (6) y Economía (5).» _(solo si tu última nota es 6 o más y tu última nota es menor que 7)_
  - ⏳ _Pantalla de transición:_ «📬 Nota de selectividad: bien. Puedes entrar en Derecho (6) y Economía (5).»
- **Paso 14 · Transición (pasa el tiempo)** — «📬 Nota de selectividad: aprobado justo. Puedes entrar en Economía (5).» _(solo si tu última nota es 5 o más y tu última nota es menor que 6)_
  - ⏳ _Pantalla de transición:_ «📬 Nota de selectividad: aprobado justo. Puedes entrar en Economía (5).»
- **Paso 15 · Transición (pasa el tiempo)** — «📬 Nota de selectividad: suspenso. Pero hay convocatoria extraordinaria en julio. Todavía no está todo perdido.» _(solo si tu última nota es menor que 5)_
  - ⏳ _Pantalla de transición:_ «📬 Nota de selectividad: suspenso. Pero hay convocatoria extraordinaria en julio. Todavía no está todo perdido.»
- **Paso 16 · Clase** — «Julio: estudia para la convocatoria extraordinaria» _(solo si tienes la marca «suspende selectividad» y NO tienes la marca «acceso 5»)_
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 17 · Clase** — «La selectividad de julio (segunda oportunidad)» _(solo si tienes la marca «suspende selectividad» y NO tienes la marca «acceso 5»)_
  - _Lugar:_ tu aula del instituto
- **Paso 18 · Transición (pasa el tiempo)** — «📬 Julio: ¡aprobado con un bien! Derecho (6) y Economía (5) te esperan.» _(solo si tienes la marca «suspende selectividad» y tu última nota es 6 o más y NO tienes la marca «acceso 5»)_
  - ⏳ _Pantalla de transición:_ «📬 Julio: ¡aprobado con un bien! Derecho (6) y Economía (5) te esperan.»
- **Paso 19 · Transición (pasa el tiempo)** — «📬 Julio: ¡aprobado! Puedes entrar en Economía (5).» _(solo si tienes la marca «suspende selectividad» y tu última nota es 5 o más y tu última nota es menor que 6 y NO tienes la marca «acceso 5»)_
  - ⏳ _Pantalla de transición:_ «📬 Julio: ¡aprobado! Puedes entrar en Economía (5).»
- **Paso 20 · Transición (pasa el tiempo)** — «📬 Julio: otra vez suspenso. Este año no podrás ir a la universidad… pero puedes trabajar. Y volver a intentarlo más adelante.» _(solo si tienes la marca «suspende selectividad» y tu última nota es menor que 5 y NO tienes la marca «acceso 5»)_
  - ⏳ _Pantalla de transición:_ «📬 Julio: otra vez suspenso. Este año no podrás ir a la universidad… pero puedes trabajar. Y volver a intentarlo más adelante.»
- **Paso 21 · Transición (pasa el tiempo)** — «La noche antes de entregar la solicitud…»
  - ⏳ _Pantalla de transición:_ «La noche antes de entregar la solicitud…»
- **Paso 22 · Cinemática**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - 🎬 **Cinemática «Ins06_Noche»** _(música: intensidad Intima)_
    - _En escena:_ Abu, Mamá/Papá
    - _Cámara:_ 2 planos (General, Seguir)
    - _Narrador:_ _En la estantería del salón, cosas de todas las épocas: la foto del grupo, el diploma de primaria, la insignia del club…_ _[plano Lateral de Tú]_
    - **Abu:** Tú tampoco duermes, ¿eh? A mi edad es normal. A la tuya es que algo pesa. _[plano PrimerPlano de Abu · silencio 0.6 s]_
    - **Mamá/Papá:** ¿No puedes dormir? Yo tampoco dormía la noche antes de decidir. Ven, que hay leche con cacao. _[plano Medio de Mamá/Papá]_
    - _(si en «primer dia ins» elegiste «Acompanado»)_ **Mamá/Papá:** El primer día de instituto me pediste que te acompañara hasta la puerta. Mañana no puedo acompañarte a ningún sitio. _[plano PrimerPlano de Mamá/Papá · en la pausa: Pensar]_
    - _(si en «primer dia ins» elegiste «Solo»)_ _(o bien)_ **Mamá/Papá:** El primer día de instituto te fuiste sin mirar atrás. Ya entonces supe que esta noche iba a llegar. _[plano PrimerPlano de Mamá/Papá · en la pausa: Pensar]_
    - _(si tienes la marca «pillado»)_ **Mamá/Papá:** La última vez que salí así de noche fue para ir a buscarte a una comisaría. Prefiero esta noche. Mucho. _[plano Hombro de Tú → Mamá/Papá · gesto Sad]_
    - _(si en «meta» elegiste «Ahorro»)_ **Mamá/Papá:** Y con el dinero que ahorraste en aquel verano, algo te ayudará. _[plano Medio de Mamá/Papá · gesto Happy]_
    - _(si en «sueldo» elegiste «Familia»)_ **Mamá/Papá:** Todavía me acuerdo de la cena que pagaste con tu primer sueldo. Postre incluido. _[plano Medio de Mamá/Papá · gesto Happy]_
    - _(si en «empleo» elegiste «Barista» y tienes la marca «buen trabajo»)_ **Mamá/Papá:** Lola me paró ayer en la calle. Dice que cuando quieras, tienes delantal. _[plano Medio de Mamá/Papá · gesto Happy]_
    - **Abu:** Mira, cariño. A tu edad yo quería enseñar en una escuela, y en casa dijeron que no. _[plano PrimerPlano de Abu · en la pausa: Pensar · silencio 1.0 s]_
    - **Abu:** Acabé en un taller de costura. Fui feliz. _[plano PrimerPlano de Abu]_
    - **Abu:** Pero me quedé con las ganas. _[plano PPP de Abu · gesto Sad · en la pausa: Suelo · silencio 1.0 s]_
    - **Abu:** Haz lo que te haga feliz. Y si no sale, vuelve a intentarlo. Aquí vamos a estar. _[plano Hombro de Tú → Abu · en la pausa: Mirar · silencio 0.8 s]_
    - _(si en «orientacion» elegiste «Claro»)_ **Mamá/Papá:** Siempre has sabido lo que te gustaba. Ahora solo te falta creértelo. _[plano DosPlanos de Mamá/Papá → Tú]_
    - _(si en «orientacion» elegiste «Dudas»)_ _(o bien)_ **Mamá/Papá:** Carmen nos dijo una vez que las dudas son buena señal. Pues esta casa está llenísima de buenas señales. _[plano DosPlanos de Mamá/Papá → Tú]_
    - _(si en «orientacion» elegiste «Muchas»)_ _(o bien)_ **Mamá/Papá:** Te gustan mil cosas. No tienes que elegir una para siempre. Solo la primera. _[plano DosPlanos de Mamá/Papá → Tú]_
    - _(si tienes la marca «camino delincuente»)_ **Abu:** Y lo de estos años, lo sé. Lo difícil no es entrar. Es salir. Todavía estás a tiempo. _[plano PrimerPlano de Abu · en la pausa: Mirar]_
    - _(si tienes la marca «redimido» y NO tienes la marca «camino delincuente»)_ _(o bien)_ **Abu:** Saliste de algo difícil, cariño. Eso no lo enseña ningún instituto. _[plano PrimerPlano de Abu · gesto Happy · en la pausa: Mirar]_
    - _Narrador:_ _Cuando tenías diez años, en un banco del parque, dijiste qué querías ser. Te acuerdas perfectamente._ _[plano PPP de Tú · silencio 1.0 s]_
    - _(si en «sueno infancia» elegiste «Medicina»)_ _Narrador:_ _«Salvar vidas en un hospital». Lo dijiste muy en serio._ _[plano PPP de Tú]_
    - _(si en «sueno infancia» elegiste «Ingenieria»)_ _(o bien)_ _Narrador:_ _«Inventar cosas que no existen». Lo dijiste muy en serio._ _[plano PPP de Tú]_
    - _(si en «sueno infancia» elegiste «Derecho»)_ _(o bien)_ _Narrador:_ _«Defender a la gente en los juzgados». Lo dijiste muy en serio._ _[plano PPP de Tú]_
    - _(si en «sueno infancia» elegiste «Economia»)_ _(o bien)_ _Narrador:_ _«Tener mi propia tienda». Lo dijiste muy en serio._ _[plano PPP de Tú]_
    - _(si en «sueno infancia» elegiste «Arte»)_ _(o bien)_ _Narrador:_ _«Ser artista». Lo dijiste muy en serio._ _[plano PPP de Tú]_
    - _(si en «sueno infancia» elegiste «Deporte»)_ _(o bien)_ _Narrador:_ _«Deportista profesional». Lo dijiste muy en serio._ _[plano PPP de Tú]_
- **Paso 23 · Decisión** — «Decide qué quieres hacer al terminar el instituto»
  - ❓ **Pregunta:** Tienes 18 años y todo el futuro por delante. ¿Qué quieres hacer?
  - ➤ _(si tienes la marca «acceso 5»)_ **Opción «Ir a la universidad (vivirás en la residencia del campus; la carrera se elige allí)»** _(efecto: decisión «futuro» = Universidad)_
  - ➤ **Opción «Empezar a trabajar ya»** _(efecto: decisión «futuro» = Trabajar; decisión «estudios» = Trabajar)_
- **Paso 24 · Escena**
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** ¡A la universidad! Y a vivir en la residencia del campus… Te voy a echar de menos. Y a tu ropa sucia, no tanto. _[plano Medio de Mamá/Papá · gesto Happy]_
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** Allí tendrás que hacerte la compra, la comida, la cama… Todo. Mañana te enseño a hacer una tortilla. Por si acaso. Por si acaso, dos.
  - _(si en «futuro» elegiste «Universidad» y tienes la marca «acceso 8»)_ **Mamá/Papá:** Con tu nota puedes elegir cualquier carrera. ¡Cualquiera! Piénsalo bien antes de matricularte.
  - _(si en «futuro» elegiste «Trabajar»)_ **Mamá/Papá:** ¿Trabajar ya? _[plano PrimerPlano de Mamá/Papá · gesto Surprised · en la pausa: Respira · silencio 0.8 s]_
  - _(si en «futuro» elegiste «Trabajar»)_ **Mamá/Papá:** Es una decisión valiente. Y si algún día quieres estudiar, siempre estás a tiempo. _[silencio 0.6 s]_
  - _(si tienes las marcas «empieza a trabajar» y «buen trabajo»)_ **Mamá/Papá:** Y quien te contrató aquel verano siempre dice que eres de fiar. Algo de eso habrá. _[gesto Happy]_
  - **Abu:** Sea lo que sea, lo has elegido tú. Eso es lo que importa. _[plano PrimerPlano de Abu · en la pausa: Mira · silencio 1.0 s]_
- **Paso 25 · Ir a** el patio — «Ve a la graduación del instituto»
  - _Lugar:_ el patio · _En escena:_ Javier, Carmen, Mamá/Papá, Abu, Sara, Nico, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Iker (si tienes la marca «iker en el grupo»)
- **Paso 26 · Cinemática**
  - 🎬 **Cinemática «Ins06_Graduacion»** _(música: intensidad Resolucion → Tema)_
    - _En escena:_ Javier, Carmen, Mamá/Papá, Abu, Sara, Nico, Omar, Bruno, Leire, Hugo, Mateo, Iker
    - _Cámara:_ 2 planos (General)
    - 🪧 _Rótulo:_ «Graduación» — Instituto del Campus Valmar
    - **Javier:** Promoción de este año: cuando llegasteis, no sabíais ni dónde estaba el aula. _[plano Medio de Javier]_
    - _(si en «veterano» elegiste «Creer»)_ **Javier:** Algunos esperasteis un ascensor que no existe. _[plano PrimerPlano de Javier]_
    - _(si NO se cumple: en «veterano» elegiste «Creer»)_ _(o bien)_ **Javier:** Otros preguntasteis a la delegada. Que es lo que hay que hacer: preguntar es de listos. _[plano PrimerPlano de Javier]_
    - **Javier:** Hoy os vais sabiendo algo más importante: quiénes sois. _[plano Medio de Javier · silencio 0.6 s]_
    - **Javier:** Más o menos. Que ya es mucho. _[plano PrimerPlano de Javier · gesto Shrug · en la pausa: Pensar · silencio 0.8 s]_
    - **Carmen:** Nadie tiene que tenerlo todo claro hoy. Solo hay que dar el primer paso. Y si os equivocáis, se cambia. _[plano Medio de Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Esta foto la hago yo. Con la cámara de mi abuelo. Nada de móviles. _[plano Medio de Leire]_
    - _(si NO se cumple: tienes la marca «conoces a leire»)_ _(o bien)_ **Javier:** Todos juntos para la orla. Omar, los ojos abiertos. Nico, en el suelo. _[plano Medio de Javier]_
    - _Narrador:_ _La foto de la orla: Omar con los ojos cerrados. Nico saltando. Sara en su sitio exacto. Tú, en medio._ _[plano General]_
    - _(si en «recreo ins» elegiste «Rincon»)_ **Sara:** Cuatro años después, el banco del rincón sigue siendo territorio del grupo. Lo he comprobado. _[plano Reaccion de Sara]_
    - _(si en «recreo ins» elegiste «Nico»)_ _(o bien)_ **Nico:** ¡Desde aquel primer recreo con los de segundo juegas en mi equipo! ¡Para siempre! _[plano Reaccion de Nico]_
    - _(si en «recreo ins» elegiste «Explorar»)_ _(o bien)_ **Sara:** El primer día te aprendiste el instituto entero. Ahora te lo sabes de memoria. Y nosotros a ti. _[plano Reaccion de Sara]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Omar:** Los Imparables. Promoción de este año. Que lo sepa todo el mundo. _[plano DosPlanos de Omar → Tú · gesto Happy]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Omar:** La Patrulla Valmar. Promoción de este año. Que lo sepa todo el mundo. _[plano DosPlanos de Omar → Tú · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Omar:** Los del Banco Azul. Promoción de este año. Que lo sepa todo el mundo. _[plano DosPlanos de Omar → Tú · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Omar:** Los Dinosaurios. Promoción de este año. Que lo sepa todo el mundo. _[plano DosPlanos de Omar → Tú · gesto Happy]_
    - _(si en «sitio instituto» elegiste «Bruno»)_ **Bruno:** Cuatro años en el mismo pupitre y nunca te copié. Bueno. Una vez. _[plano PrimerPlano de Bruno]_
    - _(si tienes la marca «conoces a leire» y llevas foto de leire (1))_ **Leire:** ¿Todavía tienes la foto del primer día? Yo también me quedé una tuya. No se lo digas a nadie. _[plano PrimerPlano de Leire]_
    - _(si tienes la marca «llegas tarde instituto»)_ **Javier:** Por cierto, [tu nombre]: lo de llegar tarde el primer día. Perdonado. Por fin. _[plano Medio de Javier]_
    - _(si tienes la marca «montaje dario»)_ **Javier:** Y que un grupo de clase no es un campo de batalla. Eso lo aprendimos todos por las malas. _[plano Medio de Javier]_
    - **Mamá/Papá:** ¡[tu nombre]! ¡Mírame! ¡Una más! ¡La última! ¡Bueno, otra! _[plano Medio de Mamá/Papá · en la pausa: Saludar]_
    - **Abu:** Mira cuánta gente te quiere, cariño. Eso no sale en la orla. Pero se nota. _[plano PrimerPlano de Abu]_
    - _Narrador:_ _El instituto se acaba. Empieza todo lo demás._ _[plano General]_
- **Paso 27 · Transición (pasa el tiempo)** — «…y llega el momento de elegir tu camino.»
  - ⏳ _Pantalla de transición:_ «…y llega el momento de elegir tu camino.» _(pasas a la etapa AdultoJoven)_
  - 🎬 **Montaje / cinemática de transición «Adol_Selectividad»** _(música: → Intima VidaAdulta PasanLosAnos; montaje de cambio de etapa Adolescente → AdultoJoven)_
    - _En escena:_ Abu, Mamá/Papá, Profesora Beltrán, Sara, Luca, Chef Lola, Ernesto, Omar, Rayo, Nerea, Paco, Agente Inés, Javier, Nico, Álex, Rubén, Hugo, Leire, Carmen, Mateo · _entran andando:_ Mamá/Papá, Sara, Luca, Ernesto, Omar
    - _Cámara:_ 16 planos (DosPlanos)
    - 🪧 _Rótulo:_ «El instituto» — Fin del capítulo
    - _(si tienes la marca «va a la universidad»)_ 🪧 _Rótulo:_ «Campus Valmar» — La universidad
    - _(si NO se cumple: tienes la marca «va a la universidad»)_ 🪧 _Rótulo:_ «Valmar Centro» — La ciudad que trabaja
    - _(si tienes la marca «rayo cambia»)_ 🪧 _Rótulo:_ «Rayo» — Cambió de camino. Un poco gracias a ti.
    - _(si tienes el recuerdo «la noche» y NO tienes la marca «rayo cambia»)_ 🪧 _Rótulo:_ «La noche del supermercado» — Hay noches que te cambian
    - _(si tienes el recuerdo «primer sueldo» y NO tienes la marca «rayo cambia» y NO tienes el recuerdo «la noche»)_ 🪧 _Rótulo:_ «Tu primer sueldo» — El verano en que aprendiste lo que cuesta ganarlo
    - _(si NO tienes la marca «rayo cambia» y NO tienes los recuerdos «la noche» y «primer sueldo»)_ 🪧 _Rótulo:_ «Tu primer día de instituto» — Y aquel «ascensor de alumnos»
    - _(si tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «Tu primer club» — Cada club era un mundo
    - _(si en «club» elegiste «Baloncesto» y tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «El club de baloncesto» — Álex apostaba por ti (sin dinero)
    - _(si en «club» elegiste «Teatro» y tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «El club de teatro» — Rubén, por fin, hacía reír a propósito
    - _(si en «club» elegiste «Robotica» y tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «El club de robótica» — Sara y sus palabras largas
    - _(si en «club» elegiste «Periodico» y tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «El periódico del instituto» — Hugo escribía bajito y muy bien
    - _(si en «club» elegiste «Fotografia» y tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «El club de fotografía» — La cámara vieja de Leire
    - _(si tienes la marca «conoces a leire» y NO tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «Leire» — Llegó del norte con una cámara vieja al cuello
    - _(si NO tienes la marca «conoces a leire» y NO tienes el recuerdo «primer club»)_ 🪧 _Rótulo:_ «La semana de las profesiones» — «No tienes que saberlo hoy.»
    - _(si tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ «La foto de Omar» — Y cómo lo arreglasteis
    - _(si NO tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ «Los de siempre» — El banco del parque se os quedó pequeño
    - _(si en «nombre grupo» elegiste «Los Imparables» y NO tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ ««Los Imparables»» — El banco del parque se os quedó pequeño
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar» y NO tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ ««La Patrulla Valmar»» — El banco del parque se os quedó pequeño
    - _(si en «nombre grupo» elegiste «Los del Banco Azul» y NO tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ ««Los del Banco Azul»» — El banco del parque se os quedó pequeño
    - _(si en «nombre grupo» elegiste «Los Dinosaurios» y NO tienes el recuerdo «el rumor»)_ 🪧 _Rótulo:_ ««Los Dinosaurios»» — El banco del parque se os quedó pequeño
    - 🪧 _Rótulo:_ «Dieciocho años» — …y llega el momento de elegir tu camino.
    - **Mamá/Papá:** Todavía hay luz en su cuarto.
    - **Abu:** Déjale pensar. Las decisiones grandes se toman de noche y se cuentan por la mañana.
    - _(si tienes la marca «va a la universidad»)_ **Mamá/Papá:** Ha dejado la solicitud en la mesa. Rellenada.
    - _(si tienes la marca «empieza a trabajar»)_ **Mamá/Papá:** Mañana empieza a trabajar. Qué rápido, ¿no?
    - _(si tienes la marca «va a la universidad»)_ **Sara:** Primer curso. Lo he dicho en voz alta y me he mareado un poco.
    - _(si NO se cumple: tienes la marca «va a la universidad»)_ **Ernesto:** ¡Buenos días! Aquí se madruga, ¿eh? Las cartas no se reparten solas.
    - _(si tienes la marca «va a la universidad»)_ **Luca:** Benvenuti! Bienvenidos. Primero, la cafetería. Luego, la vida.
    - _(si NO se cumple: tienes la marca «va a la universidad»)_ **Omar:** ¡Eh! ¡Que ahora somos gente que trabaja! Esto hay que celebrarlo con un bocadillo.

**Al terminar (momento de la biografía):** «Decidiste tu futuro»

---

**Texto de cierre del capítulo:** «El instituto queda atrás.»

# Saga de la Grieta · Acto II

> Misiones canónicas de la saga (adolescencia: en paralelo al instituto). Se ven siempre en el mapa hasta hacerlas.

### Saga_07_Costuras · «Las costuras se sueltan»

**Resumen:** Años después de coser el cielo, el medidor de rarezas vuelve a pitar. Cosme te espera con una credencial plastificada y cara de preocupación.

_Tipo: Saga de la Grieta · Acto II (1/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «El medidor de rarezas de Cosme pita como hace años. La costura del cielo…»

**Requisitos:** has terminado «Coser el cielo» y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Habla con Cosme en el garaje»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** Criatura. Ya no eres tan criatura. Pero te lo sigo llamando. _[plano Medio de Cosme]_
  - **Cosme:** Te he hecho esto. _[ademán Point · silencio 0.5 s]_
  - _Narrador:_ _Una credencial plastificada: «AYUDANTE OFICIAL DEL LABORATORIO COSME. Nivel: casi de confianza». Sales fatal en la foto._
  - **Cosme:** La costura del cielo se está soltando. Punto a punto. _[gesto Sad · en la pausa: Respira]_
  - **Cosme:** Lo dije: las costuras siempre se sueltan. Lo dijo… otro. Bah. _[en la pausa: Aparta]_
  - **Don Escamas:** Y hay más: MegaVerso ha pedido permiso para abrir una oficina en el Distrito Financiero. _[plano Medio de Don Escamas]_
  - **Don Escamas:** Lo sé porque todavía me llegan sus boletines. Soy de los que no se dan de baja.
  - **Pip:** El medidor marca tres puntos. El señor Cosme no puede ir: le duele la espalda. Y el orgullo. Sobre todo el orgullo.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Patrulla con el medidor de rarezas: tres sitios pitan»
  - **Paso 2.1 · Usar** — «El parque»
    - 🖐 _Al usar «Hilos verdes que caen del cielo»:_
      - _Narrador:_ _Del cielo caen hilos verdes, finísimos, como si alguien deshiciera un jersey allá arriba._
      - _Narrador:_ _Donde tocan el suelo, algo se mueve._ _[silencio 0.6 s]_
  - **Paso 2.2 · Usar** — «La plaza del centro»
    - 🖐 _Al usar «Una pantalla publicitaria que no estaba»:_
      - _Narrador:_ _Una pantalla nueva en la plaza: «MegaVerso S.A. — ¿Cansado de tu dimensión? ¡Prueba otra!»._
      - _Narrador:_ _«Próximamente, la GRAN FUSIÓN. Compra ya tu entrada»._
      - _Narrador:_ _Nadie más parece verla. La gente pasa por delante como si fuera una pared._
  - **Paso 2.3 · Usar** — «El patio del instituto»
    - 🖐 _Al usar «Un cristal que zumba»:_
      - _Narrador:_ _En el patio del instituto, un cristal clavado en el suelo zumba. Es uno de tus anclajes de hace años… agrietado._
      - _(si tienes el recuerdo «coser el cielo»)_ _Narrador:_ _Lo clavaste tú, la noche de la aguja. Todavía tienes el barro de aquella noche en la memoria._
- **Paso 3 · Pelea** — «¡Hilachas sueltas por el parque! Enróllalas antes de que lo enreden todo (0/2)»
  - _Lugar:_ el parque
  - 🚨 _Si te atrapan:_ «¡Cosquillas de hilo! (Te enredan los cordones. Te desenredas junto a la fuente.)»
- **Paso 4 · Escena**
  - _Lugar:_ El garaje de Cosme
  - **Cosme:** Hilachas. La costura se deshace y se escapan los hilos. _[plano Medio de Cosme]_
  - **Cosme:** Y un anuncio de MegaVerso que solo ven los que han visto la Grieta. Muy listos. Muy malvados. Muy de él. _[gesto Angry]_
  - **Tú:** ¿De Cósimo?
  - **Cosme:** …Sí. De Cósimo. _[en la pausa: Baja · silencio 0.8 s]_
  - _(si tienes la marca «cosimo te ha visto»)_ **Cosme:** Desde que te habló por la costura, duermo con un ojo abierto. El otro también.
  - **Cosme:** Te prometí contártelo cuando fueras mayor. Aún no eres tan mayor. Pero Pip tiene un archivo. Algún día. _[a Pip · en la pausa: Mira]_
  - _Narrador:_ _Recibes 💳 la Credencial de ayudante oficial. Es oficial: trabajas para un inventor loco. Sin sueldo._

**Al terminar (momento de la biografía):** «Te hiciste ayudante oficial de Cosme»

---

### Saga_08_MegaVerso · «MegaVerso S.A.»

**Resumen:** El Consorcio ha abierto oficina en el Distrito Financiero. Moqueta gris, plantas de plástico y una recepcionista que sonríe sin parpadear. Hay que entrar.

_Tipo: Saga de la Grieta · Acto II (2/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a las oficinas del Distrito Financiero. «La oficina de MegaVerso S.A. ya está abierta. Nadie más la ve. Tú sí»

**Requisitos:** has terminado «Las costuras se sueltan» y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Agente de MegaVerso — «Entra en la oficina. La recepcionista sonríe»
  - _Lugar:_ las oficinas del Distrito Financiero · _En escena:_ Agente de MegaVerso
  - **Agente de MegaVerso:** ¡Bienvenido/Bienvenida a MegaVerso S.A.! _[plano Medio de Agente de MegaVerso · gesto Happy]_
  - **Agente de MegaVerso:** ¿Viene por las vacaciones dimensionales? ¿Por la tarjeta de fidelización? ¿O por la Gran Fusión?
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Vengo a informarme. Soy de un colegio. Trabajo de clase.» _(efecto: humor +1)_
      - **Agente de MegaVerso:** ¡Qué adorable! Sírvase usted mismo. Las cámaras solo graban a los adultos. Es nuestra política de privacidad.
    - ➤ «Enseñas la credencial de ayudante de Cosme» _(efecto: valentia +1; marca «enseñaste credencial»)_
      - **Agente de MegaVerso:** ¿Laboratorio… Cosme? …Un momento, por favor. Voy a consultar con mi… con la máquina de café. Sírvase usted mismo.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Mientras nadie mira, busca información»
  - **Paso 2.1 · Usar** — «Los folletos»
    - 🖐 _Al usar «Folletos de colores»:_
      - _Narrador:_ _«¡Cambia de vida sin cambiar de casa! MegaVerso fusiona tu dimensión con otra mejor. Más luz, más ofertas, más perilla»._
      - _Narrador:_ _Letra pequeña: «La dimensión fusionada pasa a ser propiedad de MegaVerso S.A. y de su socio científico, el Dr. C.»._
  - **Paso 2.2 · Usar** — «El ordenador»
    - 🖐 _Al usar «Un ordenador encendido»:_
      - _Narrador:_ _Una hoja de cálculo: «PROYECTO FUSIÓN — Valmar (dim. principal) + Valmar (dim. 66-B)». Estado: «bloqueado». Motivo: «el Ancla»._
      - _Narrador:_ _Fecha prevista de desbloqueo: «Graduación del Ancla (instituto). La costura estará suficientemente débil»._
      - **Tú:** …Mi graduación. Hablan de MI graduación. _[silencio 0.8 s]_
  - **Paso 2.3 · Usar** — «El mapa de la pared»
    - 🖐 _Al usar «Un mapa de Valmar en la pared»:_
      - _Narrador:_ _Un mapa de Valmar con chinchetas rojas en tres sitios: el parque, el patio del cole y la plaza._
      - _Narrador:_ _Tus anclajes de hace años. Todos tachados._
      - _Narrador:_ _Y una chincheta dorada en una casa de Los Pinos. La tuya. Con una etiqueta: «ANCLA»._
      - **Robot de seguridad de MegaVerso:** Detectado visitante no autorizado. Tiene usted una llamada de ventas. Tiene usted una llamada de ventas.
- **Paso 3 · Huida** — «¡Te han visto! Sal de la oficina hasta la plaza del Distrito Financiero»
  - _Lugar:_ la Plaza Financiera · _En escena:_ Robot de seguridad de MegaVerso, Agente de MegaVerso
  - 🚨 _Si te atrapan:_ «Tiene usted una llamada de ventas. Tiene usted una llamada de ventas. (Te zafas y vuelves a intentarlo.)»
- **Paso 4 · Escena**
  - _Narrador:_ _Llegas a la plaza sin aliento. Detrás de ti, la puerta de MegaVerso se cierra sola._
  - _Narrador:_ _En el cristal, el reflejo de un hombre con perilla sonríe un segundo y desaparece._ _[silencio 0.8 s]_
  - _Narrador:_ _Recibes 📄 el Folleto de MegaVerso. Hay que contárselo a Cosme. Y saber qué es eso del Ancla. Ya._

**Al terminar (momento de la biografía):** «Descubriste el Proyecto Fusión»

---

### Saga_09_Archivo · «El archivo de Pip»

**Resumen:** Pip guarda un archivo secreto que Cosme le prohibió abrir. Esta noche, con Cosme dormido, Pip ha decidido que ya es hora.

_Tipo: Saga de la Grieta · Acto II (3/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Pip te espera en la puerta del garaje, de noche, con una caja y cara de estar desobedeciendo»

**Requisitos:** has terminado «MegaVerso S.A.» y entre las 20:00 y las 6:00 y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Pip — «Habla con Pip»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Pip, Don Escamas
  - **Pip:** Buenas noches. Estoy a punto de desobedecer una orden directa del señor Cosme. _[plano Medio de Pip · gesto Nervous]_
  - **Pip:** Es la primera vez en veintitrés años. Me tiemblan los tornillos. _[en la pausa: Baja]_
  - **Pip:** El señor Cosme cree que le protege no contándoselo. Yo creo que ya no le protege. _[en la pausa: Respira]_
  - **Pip:** Solo le deja a oscuras. Y a oscuras se tropieza.
  - _(si tienes la marca «oyo ancla»)_ **Pip:** Usted ya oyó una palabra que no debía. «Ancla». Esta noche sabrá qué significa. _[plano PrimerPlano de Pip]_
  - **Don Escamas:** Yo voto por contarlo todo. Aunque yo siempre voto por contarlo todo. Es mi problema. _[plano Medio de Don Escamas]_
- **Paso 2 · Usar** — «Abre el archivo»
  - _En escena:_ Pip
  - 🖐 _Al usar «El archivo de Pip»:_
    - _Narrador:_ _Dentro de la caja: planos del «Proyecto Costura», una bata chamuscada, una foto de dos jóvenes iguales delante de una máquina…_
    - _Narrador:_ _…y una cinta de vídeo con una etiqueta: «LA NOCHE»._ _[silencio 0.8 s]_
    - _(si tienes la marca «vio pabellon 0»)_ _Narrador:_ _Esa foto ya la has visto. Estaba en el suelo del Pabellón 0 de la universidad._
- **Paso 3 · Usar** — «Pon la cinta en el proyector»
  - 🖐 _Al usar «Un proyector antiguo»:_
    - _Narrador:_ _La cinta. Un laboratorio escondido en el campus. Dos jóvenes con bata, Cosme y Cósimo, delante de la Cosedora Dimensional._
    - _Narrador:_ _Ríen. Brindan con batido de apio._
    - **Cosme:** (En la cinta, joven) Prueba número uno. Vamos a coser dos dimensiones un milímetro. Solo un milímetro. Para ver qué pasa.
    - **Doctor Cósimo:** (En la cinta, joven, sin perilla) Un milímetro hoy. Un universo mañana. Imagínatelo, Cosme: dos Valmar en una. Todo lo mejor de las dos.
    - _Narrador:_ _La máquina se enciende. Algo sale mal: un chispazo verde abre una línea en el aire. La línea crece, tira de todo hacia ella._
    - _Narrador:_ _Cósimo resbala. Cosme le agarra de la mano. Se sueltan._ _[silencio 0.6 s]_
    - _Narrador:_ _Cósimo cae al otro lado. La línea se hace enorme… y de repente se frena. Algo la sujeta._ _[silencio 0.6 s]_
    - _Narrador:_ _Algo pequeño, a pocas calles, en una casa de Los Pinos. Acaba de nacer un bebé._
    - **Pip:** La Grieta se agarró a lo único que había cerca. A usted. _[plano PrimerPlano de Pip · silencio 1.0 s]_
    - **Cosme:** (En la cinta, solo, llorando) Mientras ese bebé esté en esta Valmar, la grieta no se abrirá del todo. Es… un ancla.
    - **Cosme:** (En la cinta) Le vigilaré. Toda la vida. Sin que lo sepa. Se lo debo. _[silencio 0.8 s]_
- **Paso 4 · Hablar** con Cosme — «Cosme se ha despertado. Te está mirando desde la puerta»
  - _En escena:_ Cosme, Pip
  - **Cosme:** …Pip. Te dije que nunca. _[a Pip · plano General · silencio 1.0 s]_
  - **Pip:** Lo sé, señor. Y usted me dijo que el día que tuviera que elegir entre obedecerle y cuidarle, le cuidara. _[a Cosme · en la pausa: Baja]_
  - **Pip:** También me lo dijo. _[silencio 0.5 s]_
  - ❓ **Pregunta al jugador:** Cosme te mira. ¿Qué le dices?
    - ➤ «Llevas toda mi vida cuidándome. Gracias.» _(efecto: Cosme +12; empatia +2; marca «perdona a cosme»)_
      - **Cosme:** No me des las gracias. La grieta es culpa mía. Tú… tú eres lo único bueno que salió de aquella noche. Aunque no fuera a propósito.
    - ➤ «¿Por qué no me lo dijiste antes?» _(efecto: Cosme +4; valentia +1; marca «enfado con cosme»)_
      - **Cosme:** Porque tenías seis años y te gustaban las burbujas. ¿Cómo le dices a alguien de seis años que sujeta el universo con una mano?
      - **Cosme:** …Tienes razón. Debí hacerlo antes. Perdón. No se me dan bien los perdones. Se me dan bien las explosiones.
  - _(si tienes la marca «sabe fusion»)_ **Cosme:** La Fusión que viste en su oficina. Eso es lo que quiere. _[en la pausa: Respira]_
  - _(si NO se cumple: tienes la marca «sabe fusion»)_ **Cosme:** Cósimo quiere la Fusión. Para eso necesita que sueltes el ancla. _[en la pausa: Respira]_
  - **Cosme:** Que te vayas de esta Valmar, o que la costura se rompa del todo. Y MegaVerso le paga el laboratorio. _[plano PrimerPlano de Cosme]_
  - **Pip:** Tome. Es suya. Es su historia. _[ademán Nod]_
  - _Narrador:_ _Recibes 📼 la Cinta de «La noche»._

**Al terminar (momento de la biografía):** «Supiste que eres el Ancla»

---

### Saga_10_Fiesta · «La fiesta del fin del mundo»

**Resumen:** MegaVerso organiza una fiesta en la plaza para vender entradas para la Gran Fusión. Música, confeti… y una cuenta atrás gigante.

_Tipo: Saga de la Grieta · Acto II (4/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a la Plaza Mayor. «Fiesta de MegaVerso en la plaza. Hay una cuenta atrás gigante en el cielo que solo tú ves»

**Requisitos:** has terminado «El archivo de Pip» y entre las 18:00 y las 2:00 y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Omar — «Tus amigos están en la fiesta. Habla con Omar»
  - _Lugar:_ la Plaza Mayor · _En escena:_ Omar, Nico, Sara
  - **Omar:** ¡Fiesta gratis! Confeti, refrescos, música… Y una pantalla que dice «Fusión: faltan 90 días». ¿Fusión de qué? ¿De sabores de helado?
  - **Omar:** Espera. …¿Tú ves algo en el cielo? Porque yo estoy viendo unos números enormes que antes no veía. _[ademán Point · en la pausa: Piensa]_
  - **Omar:** Desde que me contaste lo de la Grieta, veo cosas raras. Gracias, supongo. _[gesto Shrug]_
  - _(si tienes la marca «sabe fusion»)_ **Tú:** Es la Fusión de las dos Valmar. Lo vi en su oficina. No es de helado.
  - **Omar:** ¿Qué hacemos? ¿Plan? ¿Tienes un plan? Dime que tienes un plan. Yo te cubro.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Sabotea la fiesta sin que te vean»
  - _En escena:_ Agente de MegaVerso, Omar (te acompaña)
  - **Paso 2.1 · Usar** — «La cabina del DJ»
    - 🖐 _Al usar «La cabina del DJ de MegaVerso»:_
      - _Narrador:_ _Cambias la playlist de MegaVerso («Éxitos para fusionarse») por la música del camión de los helados._
      - _Narrador:_ _La gente deja de bailar como hipnotizada y empieza a bailar como personas normales._
  - **Paso 2.2 · Usar** — «La taquilla de entradas»
    - 🖐 _Al usar «La taquilla de entradas para la Fusión»:_
      - _Narrador:_ _Metes el folleto de MegaVerso por la ranura de las monedas. La máquina tose, pita…_
      - _Narrador:_ _…y empieza a imprimir entradas que ponen «NO». Cientos. Miles._
  - **Paso 2.3 · Usar** — «La cuenta atrás»
    - 🖐 _Al usar «La cuenta atrás»:_
      - _Narrador:_ _Desenchufas la cuenta atrás. La pantalla parpadea y, antes de apagarse, muestra un segundo una cara con perilla: «Qué maleducado»._
- **Paso 3 · Pelea** — «¡Te han descubierto! Deshazte de los de MegaVerso (0/3)»
  - _En escena:_ Omar
  - 🚨 _Si te atrapan:_ «¡Oferta de fin del mundo! ¡Firme aquí! (Omar te saca de ahí a empujones.)»
- **Paso 4 · Escena**
  - _En escena:_ Omar, Nico, Sara
  - **Nico:** ¿Qué ha pasado? La fiesta estaba genial y de repente… ¿por qué todo el mundo tiene una entrada que pone «NO»? _[plano General · gesto Surprised]_
  - **Sara:** Estadísticamente, hoy ha pasado algo muy raro. Y tú estabas en medio. Como siempre. Te lo apunto.
  - **Omar:** Hemos salvado una fiesta. O el mundo. No lo sé. Pero ha sido lo mejor del curso. _[gesto Happy]_
  - **Omar:** …Oye. Tu graduación es dentro de poco. ¿Eso tiene algo que ver con los números del cielo? _[plano PrimerPlano de Omar · en la pausa: Piensa]_
  - _Narrador:_ _No le contestas. En el cielo, antes de apagarse, los números marcaban exactamente el día de tu graduación._ _[silencio 1.0 s]_

**Al terminar (momento de la biografía):** «Saboteaste la fiesta de MegaVerso»

---

### Saga_11_Cronos · «Cronos cambia de bando»

**Resumen:** El agente Cronos, el de la Aduana del Tiempo, te busca. Esta vez no trae una multa. Trae un problema: alguien falsifica formularios.

_Tipo: Saga de la Grieta · Acto II (5/6) · Duración: 20-30 min_

**Cómo empieza:** al llegar a el patio. «Un señor con traje y cuarenta formularios te espera en el patio del instituto. Te suena»

**Requisitos:** has terminado «La fiesta del fin del mundo» y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Agente Cronos, de Aduanas del Tiempo — «Habla con el agente Cronos»
  - _Lugar:_ el patio · _En escena:_ Agente Cronos, de Aduanas del Tiempo
  - **Agente Cronos, de Aduanas del Tiempo:** Pequeño humano. Bueno, ya no tan pequeño. Mi agenda del futuro decía que hoy hablaríamos. _[plano Medio de Agente Cronos, de Aduanas del Tiempo]_
  - _(si tienes el recuerdo «ventanilla aduana»)_ **Agente Cronos, de Aduanas del Tiempo:** Usted sobrevivió a tres ventanillas en un solo día. Hoy le pido algo más difícil.
  - **Agente Cronos, de Aduanas del Tiempo:** Alguien está metiendo formularios falsos en la Aduana: permisos de Fusión dimensional, sellados con MI sello. _[gesto Angry · en la pausa: Respira]_
  - **Agente Cronos, de Aduanas del Tiempo:** Yo no los he sellado. Mi sello tiene un arañazo. Estos no.
  - **Agente Cronos, de Aduanas del Tiempo:** Si la Aduana aprueba esos permisos, la Fusión será legal. Y contra algo legal, ni yo puedo hacer nada. _[en la pausa: Piensa]_
  - **Agente Cronos, de Aduanas del Tiempo:** Necesito pruebas. Y alguien rápido. Yo corro poco.
- **Paso 2 · Hablar** con Funcionaria de la ventanilla — «La funcionaria de las ventanillas sabe quién entrega formularios (Correos)»
  - _Lugar:_ Correos · _En escena:_ Funcionaria de la ventanilla
  - **Funcionaria de la ventanilla:** ¿Formularios falsos? Hijo/Hija, llevo trescientos años en ventanillas. _[plano Medio de Funcionaria de la ventanilla]_
  - **Funcionaria de la ventanilla:** Los formularios falsos huelen diferente. Huelen a colonia cara. _[gesto ArmsCrossed]_
  - **Funcionaria de la ventanilla:** Esta mañana una señora de gris dejó una carpeta. Sonreía sin parpadear. Ahí la tienes. _[ademán Point]_
  - **Funcionaria de la ventanilla:** Y ahí está ella, en la puerta. Mírala qué tranquila. _[en la pausa: Mira]_
- **Paso 3 · Usar** — «Revisa los formularios del Consorcio»
  - 🖐 _Al usar «Una carpeta de formularios»:_
    - _Narrador:_ _Permisos de Fusión dimensional, todos sellados. Pero al sello le falta el arañazo. Y la firma pone «Crono». Sin s. Muy mal falsificado._
- **Paso 4 · Persecución** — «¡La agente gris que los entrega está ahí mismo! ¡Atrápala!»
  - _En escena:_ Agente de MegaVerso, Agente Cronos, de Aduanas del Tiempo (te acompaña)
- **Paso 5 · Escena**
  - _Lugar:_ el parque · _En escena:_ Agente de MegaVerso, Agente Cronos, de Aduanas del Tiempo
  - **Agente de MegaVerso:** ¡Vale! ¡Vale! ¡Me rindo! Solo soy de atención al cliente. El Dr. Cósimo me dijo que era un trámite normal. «Sonríe y entrega», dijo.
  - **Agente Cronos, de Aduanas del Tiempo:** Falsificación de formulario temporal. Treinta años de papeleo en la Aduana. Sin sello propio.
  - ❓ **Pregunta al jugador:** Cronos te mira: «¿Qué opinas tú?»
    - ➤ «Que ayude a pararlo todo. Una segunda oportunidad.» _(efecto: empatia +1; marca «cronos aliado» y «gris arrepentida»)_
      - **Agente de MegaVerso:** ¿Yo? ¿Ayudar? …Nunca nadie me había ofrecido algo sin letra pequeña. Acepto. De verdad. Sin sonreír.
    - ➤ «Que cumpla su castigo. Las normas son las normas.» _(efecto: responsabilidad +1; marca «cronos aliado»)_
      - **Agente Cronos, de Aduanas del Tiempo:** Las normas son las normas. Lo diré en el tribunal. Y lo pondré en un póster.
  - **Agente Cronos, de Aduanas del Tiempo:** Durante cuatrocientos años he perseguido a quien se salta el tiempo. _[plano Medio de Agente Cronos, de Aduanas del Tiempo · en la pausa: Respira]_
  - **Agente Cronos, de Aduanas del Tiempo:** Hoy me doy cuenta de que el que se salta todo es el Consorcio. _[silencio 0.5 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** A partir de hoy, estoy de tu lado. Oficialmente. Con formulario. _[ademán Nod]_
  - **Agente Cronos, de Aduanas del Tiempo:** Toma: un reloj de arena de la Aduana. Cuando la cosa se ponga fea, gíralo. Llegaré. Tarde, pero llegaré.
  - _Narrador:_ _Recibes ⏳ el Reloj de arena de Cronos._

**Al terminar (momento de la biografía):** «Cronos se unió a tu bando»

---

### Saga_12_Graduacion · «Graduación interdimensional»

**Resumen:** El día de tu graduación del instituto. La fecha que marcaba la cuenta atrás. Cosme ha venido «por casualidad». Con una aguja nueva en el bolsillo.

_Tipo: Saga de la Grieta · Acto II (6/6) · Final del acto · Duración: 30-40 min_

**Cómo empieza:** al llegar a el patio. «Día de graduación. En el cielo, sobre el instituto, la costura brilla más que nunca»

**Requisitos:** has terminado «Cronos cambia de bando» y etapa desde Adolescente

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Cosme ha venido a tu graduación. «Por casualidad»»
  - _Lugar:_ el patio · _En escena:_ Cosme, Omar, Sara, Nico
  - **Cosme:** ¡Qué casualidad! Pasaba por aquí. Con mi mejor bata. Y una aguja nueva. Y veinte chicles, por si acaso. Casualidad total.
  - **Cosme:** …Vale. He venido porque hoy es el día que marcaba la cuenta atrás. _[gesto Nervous · en la pausa: Baja]_
  - **Cosme:** Y porque es tu graduación. Por las dos cosas. Más por la segunda. _[gesto Happy]_
  - _(si tienes la marca «sabe que es ancla»)_ **Cosme:** Y como ya sabes lo que eres, sabrás por qué hoy no me separo de ti. _[plano PrimerPlano de Cosme]_
  - **Omar:** ¿Ese es el vecino? ¿El de la gallina gigante? ¡Qué honor! ¿Me firma la bata? _[a Cosme · plano DosPlanos de Omar → Cosme]_
  - _(si tienes la marca «fiesta saboteada»)_ **Omar:** Oye, ¿hoy no es el día de los números de la fiesta? Dime que no es el día de los números.
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Grieta_Rota»** _(música: → Descubrimiento → Tension efecto Momento)_
    - _En escena:_ Cosme, Omar, Sara, Nico, Doctor Cósimo
    - _Cámara:_ 6 planos (General, Pan, Tilt, Hombro, Reaccion)
    - 🪧 _Rótulo:_ «🌀 La costura se rompe» — Tu graduación del instituto
    - **Nico:** ¡Graduados! ¡GRA-DUA-DOS! ¡Que alguien me pellizque! _[emoción Joy]_
    - **Cosme:** No. Hoy no. Hoy es su día. _[plano Reaccion de Cosme · emoción Fear]_
    - _(si tienes el recuerdo «fiesta fin del mundo»)_ **Omar:** Los números del cielo de la fiesta… marcaban hoy. Marcaban ESTO. _[plano DosPlanos de Omar → Sara]_
    - _(si NO se cumple: tienes el recuerdo «fiesta fin del mundo»)_ **Sara:** Eso no es un fenómeno meteorológico. Eso es una cremallera. _[plano DosPlanos de Omar → Sara]_
- **Paso 3 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme
  - **Doctor Cósimo:** ¡Buenos días, Valmar! ¡Y enhorabuena a los graduados! _[plano Medio de Doctor Cósimo · ademán Wave]_
  - **Doctor Cósimo:** Qué emocionante. Me encantan las graduaciones. Hay tantos finales. _[gesto Happy]_
  - **Doctor Cósimo:** Hola, Cosme. Hola, Ancla. Qué grande estás. _[en la pausa: Mira]_
  - **Doctor Cósimo:** La última vez que te vi en persona eras un bebé que no sabía que sujetaba el universo. _[plano PrimerPlano de Doctor Cósimo]_
  - _(si tienes la marca «enseñaste credencial»)_ **Doctor Cósimo:** Y la última vez que te vi por cámara, enseñabas una credencial de ayudante en mi oficina. Qué mono.
  - **Cosme:** Cósimo. Vete. Esto no es tuyo. _[a Doctor Cósimo · plano Hombro de Tú → Cosme · gesto Angry]_
  - **Doctor Cósimo:** Todo es mío, Cosme. Lo será. Solo necesito que la costura ceda un poco más. _[a Cosme]_
  - **Doctor Cósimo:** Y tengo ayudantes. ¡Chicos! _[ademán Point]_
- **Paso 4 · Pelea** — «¡Los drones de Cósimo! Protege a tus amigos (0/3)»
  - _En escena:_ Cosme, Omar
  - 🚨 _Si te atrapan:_ «¡Aplausos para el concursante! (Te llevan en volandas y te sueltan en la otra punta del patio.)»
- **Paso 5 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme, Omar, Sara
  - **Doctor Cósimo:** Bravo. Bravísimo. Sabes pelear. Te lo enseñó él, ¿no? _[plano Medio de Doctor Cósimo · ademán Clap]_
  - **Doctor Cósimo:** Siempre fue un buen profesor. Por eso me lo llevo. _[a Cosme · silencio 0.6 s]_
  - _Narrador:_ _Un rayo dorado envuelve a Cosme. Intentas agarrarle de la mano. Como en la cinta. Como aquella noche._
  - _Narrador:_ _Se te escurre._ _[silencio 0.8 s]_
  - **Cosme:** ¡Criatura! ¡No sueltes el ancla! ¡Pase lo que pase, quédate en esta Valmar! _[plano PrimerPlano de Cosme · gesto Surprised]_
  - **Cosme:** ¡Pip sabe qué hacer! …¡Y aliméntale el pez!
  - _(si tienes la marca «va a la universidad»)_ **Doctor Cósimo:** Nos vemos en la universidad, Ancla. Estudia mucho. Los finales siempre son lo más difícil.
  - _(si NO tienes la marca «va a la universidad»)_ **Doctor Cósimo:** Nos vemos pronto, Ancla. Los finales siempre son lo más difícil.
  - _Narrador:_ _El agujero se cierra con otro sonido de cremallera. Silencio._ _[silencio 0.6 s]_
  - **Omar:** (Recoge del suelo la bata de Cosme, chamuscada. Os mira a todos.) _[plano General · gesto Sad · silencio 1.0 s]_
  - **Omar:** …Vale. Ahora sí que me lo tienes que contar todo. Todo. Desde el principio. _[plano PrimerPlano de Omar]_
  - _Narrador:_ _Recibes 🥼 la Bata chamuscada de Cosme. FIN DEL ACTO II. Cosme ha desaparecido._

**Al terminar (momento de la biografía):** «El día que Cósimo se llevó a Cosme»

---


# Capítulo «La universidad»

_Id: Joven_Universidad · Etapa: AdultoJoven–Adulto · Música de fondo: VidaAdulta_

> Solo si en el instituto eliges ir a la universidad; si eliges trabajar, se pasa directamente a «Volar del nido».

**Solo si:** tienes la marca «va a la universidad»

**Texto de entrada del capítulo:** «Nadie llega tarde a aprender.»

- 🎬 **Cabecera del capítulo (cinemática) «Uni_PrimerDia»** _(vuelo de cámara, 11 s, 2 planos; música: VidaAdulta)_
  - 🪧 _Rótulo:_ «La universidad» — Nadie llega tarde a aprender.
  - **Rectora:** Mi abuela decía: «Nadie llega tarde a aprender, solo a rendirse».

_Entre misión y misión se repite un «día normal» generado (Uni_Jornada): no se exporta, no es guion fijo._

### Uni01_PrimerDia · «Primer día en el campus»

**Resumen:** Septiembre. Un campus enorme, una facultad que es solo tuya y gente de todas partes. Empieza la universidad.

_Tipo: Historia · Nueva etapa · Edad: 18-18 años · Duración: 20-30 min_

**Lo que puede cambiar:** Con quién comes el primer día · Qué descubres del campus

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Septiembre. Tienes dieciocho años.»
  - ⏳ _Pantalla de transición:_ «Septiembre. Tienes dieciocho años.»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¿Llevas todo? ¿El carnet? ¿Agua? ¿El cargador? Perdona. Es la costumbre.
  - **Mamá/Papá:** ¡Universidad! ¡[tu nombre] en la universidad! Me acuerdo de cuando no llegabas al pomo de la puerta.
  - **Mamá/Papá:** Y a vivir en la residencia… Te he metido tápers en la maleta. Siete. Uno por día. Luego ya, a hacerte la compra tú.
  - **Abu:** Ven aquí. _[plano DosPlanos de Abu → Tú · silencio 0.6 s]_
  - **Abu:** Toma. Era mío. Lo llevé el día que empecé a trabajar. Ahora te toca a ti. _[plano PrimerPlano de Abu · en la pausa: Respira]_
  - _Narrador:_ _Abu te da un reloj viejo, con la correa gastada. Todavía funciona. Hace tic-tac muy bajito._ _[silencio 0.5 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Lo voy a cuidar. Prometido.» _(efecto: Abu +6)_
      - **Abu:** Ya lo sé. Por eso te lo doy.
    - ➤ «Le das un abrazo sin decir nada» _(efecto: Abu +8; empatia +1)_
      - **Abu:** (bajito) Ay… Venga, venga, que pierdes el autobús.
- **Paso 3 · Acción del jugador** — «Coge el autobús al Campus Valmar»
  - _Lugar:_ la parada del autobús
- **Paso 4 · Ir a** la Universidad de Valmar — «Llega a la entrada principal de la universidad»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Luca, Alumno, Alumna
- **Paso 5 · Cinemática**
  - 🎬 **Cinemática «Uni01_Campus»** _(música: → Descubrimiento)_
    - _En escena:_ Luca, Sara · _entran andando:_ Sara
    - _Cámara:_ 2 planos (Seguir)
    - _Narrador:_ _El campus es una ciudad dentro de la ciudad: facultades, jardines, bicis y gente hablando en cuatro idiomas._
    - **Luca:** Ciao! ¿Primer año? Se te nota: los de primero siempre miráis hacia arriba. _[plano Medio de Luca · en la pausa: Saludar]_
    - **Luca:** Soy Luca. Voluntario de bienvenida. De Bolonia. Un año aquí y ya casi no me pierdo. _[plano Hombro de Tú → Luca]_
    - **Tú:** ¿Tanto se nota? _[plano Reaccion de Tú]_
    - **Luca:** Un poquito. Primer paso: secretaría. Allí te matriculas en tu carrera, con la nota de selectividad. _[plano DosPlanos de Luca → Tú · en la pausa: Senalar]_
    - **Luca:** Sin matrícula no existes. Es como la pasta sin sal: técnicamente es comida, pero da pena. _[plano PrimerPlano de Luca]_
    - **Sara:** ¡[tu nombre]! ¡[tu nombre]! ¡Te he visto desde la facultad de Ciencias! _[plano Medio de Sara]_
    - **Sara:** ¡Mismo campus! Estadísticamente, nos vamos a cruzar unas cuatrocientas veces por curso. _[plano DosPlanos de Sara → Tú]_
    - _(si tienes el recuerdo «mochila perdida»)_ **Sara:** Y aquí tengo un laboratorio entero. La mochila de tercero la habría encontrado en diez minutos. _[plano PrimerPlano de Sara]_
    - _(si tienes el recuerdo «metro primer dia»)_ **Luca:** ¿Venís del mismo cole? Has venido en metro, ¿eh? Tienes cara de metro de las ocho. _[plano Medio de Luca]_
    - **Luca:** Amigos de antes. Perfetto: ya no me necesitas. La secretaría, sí. Avanti! _[plano DosPlanos de Luca → Sara · en la pausa: Senalar]_
- **Paso 6 · Decisión** — «Matrícula: ¿qué carrera quieres estudiar? (según tu nota de selectividad)»
  - _En escena:_ Luca, Sara, Alumno, Alumna
  - ➤ _(si tienes la marca «acceso 8»)_ **Opción «Medicina (nota de corte: 8)»** _(efecto: decisión «estudios» = Medicina)_
  - ➤ _(si tienes la marca «acceso 7»)_ **Opción «Ingeniería (nota de corte: 7)»** _(efecto: decisión «estudios» = Ingenieria)_
  - ➤ _(si tienes la marca «acceso 6»)_ **Opción «Derecho (nota de corte: 6)»** _(efecto: decisión «estudios» = Derecho)_
  - ➤ **Opción «Economía (nota de corte: 5)»** _(efecto: decisión «estudios» = Economia)_
- **Paso 7 · Usar** — «Recoge tu horario en secretaría»
  - 🖐 _Al usar «Secretaría de alumnos»:_
    - _Narrador:_ _Cola, sello, papel. Tu horario: lunes a las nueve, en la facultad. Y un plano del campus con tu edificio rodeado._
    - _(si en «estudios» elegiste «Medicina»)_ _Narrador:_ _Facultad de Medicina. Anatomía a primera hora del lunes. Empieza fuerte._
    - _(si en «estudios» elegiste «Ingenieria»)_ _Narrador:_ _Facultad de Ingeniería. Física el primer día. Sofía, la del laboratorio, da una asignatura en segundo._
    - _(si en «estudios» elegiste «Derecho»)_ _Narrador:_ _Facultad de Derecho. Derecho Civil el primer día. El edificio parece un juzgado. Probablemente a propósito._
    - _(si en «estudios» elegiste «Economia»)_ _Narrador:_ _Facultad de Economía. Microeconomía el primer día. Hay una pantalla con la bolsa en el vestíbulo._
- **Paso 8 · Ir a** [facultad de tu carrera] — «Encuentra tu facultad (sale en el horario)»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Julia, Adrián, Mateo (si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»)
  - ⏰ _Si tardas, Luca dice:_ «(mensaje) ¿Perdido? Todos los edificios son iguales el primer día. Busca el cartel con el nombre de tu facultad.»
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Uni01_Beltran»**
    - _En escena:_ Profesora Beltrán, Julia, Adrián, Mateo, Carla · _entran andando:_ Carla
    - _Cámara:_ 2 planos (General, Reaccion)
    - **Profesora Beltrán:** Buenos días. Soy la profesora Beltrán. Llevo treinta años aquí. _[plano Medio de Profesora Beltrán]_
    - **Profesora Beltrán:** He visto entrar a muchos. Y salir a casi todos. _[plano PrimerPlano de Profesora Beltrán · en la pausa: Pensar]_
    - **Profesora Beltrán:** Aquí nadie os va a perseguir para que estudiéis. La libertad es vuestra. La responsabilidad, también. _[plano Pan de Profesora Beltrán]_
    - **Julia:** He traído tres bolígrafos por si se me acaba la tinta. Y un cuarto por si acaso. ¿Quieres uno? _[plano DosPlanos de Julia → Tú]_
    - **Adrián:** Profesora, ¿habrá trabajos en grupo? Porque yo suelo coordinar. _[plano Medio de Adrián · en la pausa: Mirar]_
    - **Profesora Beltrán:** Habrá. Y coordinará quien el grupo decida. No quien lo pida primero. _[a Adrián · plano Hombro de Adrián → Profesora Beltrán]_
    - **Carla:** ¡Perdón! Perdón. Perdón… _[plano Seguir de Carla]_
    - **Profesora Beltrán:** Buenos días también a usted. Última fila, que es la que tiene más perspectiva. _[a Carla · plano Reaccion de Profesora Beltrán · silencio 0.5 s]_
    - **Carla:** …Sí. Gracias. Perdón. _[plano PrimerPlano de Carla · en la pausa: Suelo]_
    - **Julia:** Primer día y ya tarde. Yo me moriría. _[plano Reaccion de Julia]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»)_ **Mateo:** ¡[tu nombre]! ¡Lo sabía! Te dije que quería entender cómo funcionan las cosas. Pues aquí estamos. Otra vez juntos. _[plano Medio de Mateo · en la pausa: Saludar]_
    - **Profesora Beltrán:** Página uno. Empezamos. _[plano General de Profesora Beltrán]_
- **Paso 10 · Clase** — «Tu primera clase de universidad»
  - _En escena:_ Profesora Beltrán, Julia, Adrián, Carla, Mateo (si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»)
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Descubre el campus (al menos dos sitios)»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Luca (te acompaña), Sara, Julia, Adrián
  - **Paso 11.1 · Usar** — «La biblioteca»
    - 🖐 _Al usar «Mostrador de la biblioteca»:_
      - _(si en «club» elegiste «Fotografia»)_ _Narrador:_ _La misma biblioteca que fotografiaste con Leire hace años. Ahora tienes carnet. Y la estudiante dormida sobre el libro… sigue ahí. O es otra._
      - _Narrador:_ _Una biblioteca de tres plantas, silenciosa, con sillones junto a las ventanas. Te dan un carnet con tu foto. Sales fatal, como en todos._
      - **Sara:** Mi sitio es ese, el de la ventana. Si alguna vez estudias aquí, te guardo el de al lado.
  - **Paso 11.2 · Usar** — «La cafetería»
    - 🖐 _Al usar «Cafetería del campus»:_
      - _Narrador:_ _Un café de máquina que sabe a cartón y un bocadillo sorprendentemente bueno._
      - **Luca:** Consejo de veterano: el bocadillo, sí. El café, nunca. El café se toma en la ciudad, en la Cafetería Central.
      - _(si tienes el recuerdo «el rumor»)_ **Luca:** Allí trabaja Omar, ¿no? ¡Tu amigo! Lo conozco: me ha dado croquetas gratis dos veces.
  - **Paso 11.3 · Usar** — «La zona deportiva (estadio)»
    - 🖐 _Al usar «Oficina de deportes»:_
      - _Narrador:_ _Fútbol, baloncesto, atletismo, escalada, yoga… Una chica reparte folletos del equipo de baloncesto. Es Álex. Te reconoce._
      - **Álex:** ¡No me lo creo! ¡[tu nombre]! Estoy en el equipo de la universidad. Si quieres, hay pruebas el jueves. Como en el instituto.
- **Paso 12 · Decisión** — «Hora de comer. ¿Con quién? (habla con quien elijas o busca una mesa libre)»
  - _En escena:_ Luca, Sara, Julia, Adrián
  - ➤ **Opción «Con Luca»** (con Luca) _(efecto: decisión «comida uni» = Luca; Luca +8)_
    - **Luca:** ¡Bravo! Te enseño el truco del comedor: si llegas a las dos menos cinco, no hay cola y quedan croquetas.
    - **Luca:** Yo también llegué solo hace un año. No conocía a nadie. Por eso me hice voluntario: para que nadie coma solo el primer día.
  - ➤ **Opción «Con Sara, como siempre»** (con Sara) _(efecto: decisión «comida uni» = Sara; Sara +5)_
    - **Sara:** Como en el colegio. Pero con peor comida. Y yo con gafas nuevas. Por lo demás, igual.
    - **Sara:** ¿Te acuerdas de cuando éramos del tamaño de esta mesa? Técnicamente, más pequeños.
  - ➤ **Opción «Con la gente de tu clase»** (con Julia) _(efecto: decisión «comida uni» = Clase; Adrián +5; Julia +5)_
    - **Julia:** ¡Siéntate! Estamos comparando horarios. Adrián ya ha hecho una tabla de colores.
    - **Adrián:** Es para organizarnos. Alguien tiene que hacerlo. ¿Carla? Se ha ido corriendo otra vez. Qué rara.
  - ➤ **Opción «A tu aire»** _(efecto: decisión «comida uni» = Sola; curiosidad +1)_
    - _Narrador:_ _Comes a tu aire, mirando el campus. Por primera vez en tu vida, nadie sabe quién eres. Da miedo. Y también da una sensación de libertad enorme._
- **Paso 13 · Transición (pasa el tiempo)** — «Esa noche, en la residencia de estudiantes…»
  - ⏳ _Pantalla de transición:_ «Esa noche, en la residencia de estudiantes…»
- **Paso 14 · Cinemática**
  - 🎬 **Cinemática «Uni01_Mensajes»** _(música: → Intima)_
    - _Cámara:_ 5 planos (General, PrimerPlano, Lateral, PPP, Dolly)
    - _Narrador:_ _Tu móvil vibra. El grupo de siempre sigue vivo._
    - **Omar:** 📱 ¿QUÉ TAL EL PRIMER DÍA? Yo he pelado cuarenta kilos de patatas. Lola dice que tengo futuro.
    - **Nico:** 📱 Entreno con el juvenil de Altamar. Me llaman «el nuevo». Tengo diecinueve años de «nuevo» por delante.
    - _(si tienes la marca «conoces a leire»)_ **Leire:** 📱 Primer día en la escuela de cine. Aquí todos hablan en planos. Me siento en casa. Os echo de menos.
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** 📱 Periodismo tiene una redacción de verdad. Ya he escrito mi primer artículo. Era sobre piratas.
    - _(si en «comida uni» elegiste «Luca»)_ **Luca:** 📱 Mañana, comedor a las dos menos cinco. Croquetas. No me falles.
    - _(si en «comida uni» elegiste «Sara»)_ **Sara:** 📱 Me han dado taquilla en el laboratorio. Tiene ESTANTES. Es lo mejor que me ha pasado desde el microscopio.
    - _(si en «comida uni» elegiste «Clase»)_ **Julia:** 📱 Hola, soy Julia, la de los bolígrafos. Adrián ha hecho un grupo de clase. Tiene normas. Ya.
    - **Mamá/Papá:** 📱 ¿Qué tal ha ido? ¿Has comido? ¿Has hecho amigos? ¿Te has comido el táper del lunes? _[silencio 0.6 s]_
    - **Mamá/Papá:** 📱 Cuéntamelo todo. Bueno, lo que quieras. Bueno, todo.
    - _(si en «comida uni» elegiste «Sola»)_ **Tú:** 📱 He comido a mi aire. Y ha estado bien. Mañana os cuento. _[en la pausa: Respirar]_
    - _Narrador:_ _Dos camas más, todavía vacías: una maleta con pegatinas de grupos de música y una caja con etiquetas de colores._ _[silencio 0.8 s]_
    - _Narrador:_ _Antes de dormir, das cuerda al reloj viejo. Tic-tac. Empieza algo nuevo._ _[silencio 0.6 s]_

**Al terminar (momento de la biografía):** «Tu primer día de universidad»

---

### Uni01b_Residencia · «La residencia»

**Resumen:** Una habitación para tres, una cocina para cuarenta y una nevera que ya no es la de tu casa. Empieza la independencia.

_Tipo: Historia · Independencia · Edad: 18-18 años · Duración: 25-35 min_

**Requisitos:** has terminado «Primer día en el campus»

**Lo que puede cambiar:** Las normas del cuarto (y de la nevera) · Qué cocinas la primera noche

**Pasos:**

- **Paso 1 · Hablar** con Doña Pilar, la conserje de la residencia — «Doña Pilar, la conserje, te da las llaves»
  - _Lugar:_ Residencia de estudiantes · _En escena:_ Doña Pilar, la conserje de la residencia
  - **Doña Pilar, la conserje de la residencia:** ¿Primer año? Habitación 214. Tercer piso, al fondo, la de la puerta que chirría. Aquí tienes la llave.
  - **Doña Pilar, la conserje de la residencia:** Normas: nada de fuego en las habitaciones, nada de mascotas (hablo contigo, Iván, sé lo del gallo), y la cocina se deja limpia. Limpia de VERDAD.
  - **Doña Pilar, la conserje de la residencia:** Llevo cuarenta años aquí. He visto entrar a chavales que no sabían freír un huevo. Y salir… sin saber freír un huevo, la mayoría. Tú intenta ser la excepción.
- **Paso 2 · Escena**
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Iván:** ¡Hombre! ¡La persona de la cama de la ventana! Soy Iván. De Villaverde. Estamos en la misma clase, te vi en la matrícula. _[plano Medio de Iván]_
  - **Candela:** Candela. También de tu clase. Os he hecho un horario de limpieza plastificado. _[plano Medio de Candela]_
  - **Candela:** Tenéis colores. El tuyo es el verde. No se negocia. _[en la pausa: Mira]_
  - **Iván:** Aviso importante: en la nevera hay tres botellas de zumo de mora. Casero. De mi abuela. Son sagradas. _[plano DosPlanos de Iván → Tú]_
  - **Iván:** Podéis tocar todo menos eso. Todo. Menos. Eso. _[plano PrimerPlano de Iván]_
  - **Candela:** Y mis tápers llevan etiqueta con fecha. Si falta uno, lo sabré. Siempre lo sé. _[a Iván · plano Hombro de Iván → Candela]_
  - _Narrador:_ _Tienes la sensación de que este año va a ser muy largo. Y muy divertido._
- **Paso 3 · Usar** — «Deshaz la maleta»
  - 🖐 _Al usar «Tu cama (la de la ventana)»:_
    - _Narrador:_ _Ropa, el reloj de Abu, una foto del grupo de siempre… y siete tápers etiquetados por tu familia con la letra de siempre: «LUNES — COMER CALIENTE»._
    - _Narrador:_ _Pegas la foto encima de la cama. Ya parece un poco tu sitio._
- **Paso 4 · Decisión** — «Iván propone normas del cuarto. ¿Qué norma de la nevera votas?»
  - ➤ **Opción «Cada uno su balda, con etiquetas (Candela aplaude)»** _(efecto: decisión «normas» = Etiquetas; Candela +6; responsabilidad +1)_
  - ➤ **Opción «Nevera compartida: todo es de todos (Iván aplaude)»** _(efecto: decisión «normas» = Compartida; Iván +6; empatia +1)_
  - ➤ **Opción «Compra por turnos: una semana cada uno»** _(efecto: decisión «normas» = Turnos; Candela +3; Iván +3; responsabilidad +1)_
- **Paso 5 · Acción del jugador** — «Ve al supermercado y haz tu primera compra (0/2 bolsas)»
  - _Lugar:_ el supermercado
  - ⏰ _Si tardas, Candela dice:_ «(mensaje) Te recuerdo que los tápers de tu familia se acaban el domingo. Lo he calculado.»
- **Paso 6 · Usar** — «Guarda la compra en la nevera de la residencia»
  - _Lugar:_ La cocina compartida
  - 🖐 _Al usar «La nevera compartida»:_
    - _Narrador:_ _La nevera compartida de la cuarta planta. Cuarenta estudiantes, una nevera. Hay un yogur de 2019 que ya tiene nombre propio._
    - _(si en «normas» elegiste «Etiquetas»)_ _Narrador:_ _Guardas tu compra en la balda con tu etiqueta verde. Candela la ha hecho ella. Tiene un dibujito. Es un brócoli._
    - _(si en «normas» elegiste «Compartida»)_ _Narrador:_ _Guardas la compra donde cabe. Iván te choca la mano: «Ahora todo es de todos». Todo menos el zumo de mora. Eso lo dice con los ojos._
    - _(si en «normas» elegiste «Turnos»)_ _Narrador:_ _Esta semana te toca a ti la compra de los tres. Guardas todo y apuntas en la pizarra: «Semana 1: yo». Candela lo subraya._
    - _Narrador:_ _Ahora comer depende de ti: si no compras, no hay. Si no cocinas, no hay. Si Iván tiene hambre, tampoco hay._
- **Paso 7 · Acción del jugador** — «Tu primera cena de independiente: cómete algo (desde la mochila)»
- **Paso 8 · Escena**
  - **Iván:** ¡Primera cena de independientes! Yo he hecho… _[plano Medio de Iván]_
  - **Iván:** …cereales. Con zumo de mora. No me juzguéis. _[en la pausa: Aparta · silencio 0.6 s]_
  - **Candela:** Yo, arroz con verduras. Pesado en gramos. Hay para tres. _[plano Medio de Candela]_
  - **Candela:** …No me miréis así. Hay para tres. _[en la pausa: Baja · silencio 0.5 s]_
  - _(si en «normas» elegiste «Etiquetas»)_ **Candela:** Y la sal también está etiquetada. Por la norma de la balda. _[plano PrimerPlano de Candela]_
  - _(si en «normas» elegiste «Compartida»)_ **Iván:** Todo es de todos, ¿no? Por eso me he comido tu yogur. Por la norma. _[plano PrimerPlano de Iván]_
  - _(si en «normas» elegiste «Turnos»)_ **Candela:** Y como esta semana compras tú: has comprado bien. Lo digo poco. Apúntalo. _[plano PrimerPlano de Candela]_
  - ❓ **Pregunta al jugador:** ¿Qué aportas a la cena?
    - ➤ «La tortilla que te enseñó tu familia» _(efecto: Candela +4; Iván +4; marca «sabe cocinar»)_
      - **Iván:** …¿Esto lo has hecho TÚ? _[plano PrimerPlano de Iván · en la pausa: Piensa · silencio 1.0 s]_
      - **Iván:** Me caso con esta tortilla. Bueno, no. Pero casi.
    - ➤ «Tu último táper de casa, para compartir» _(efecto: Candela +3; Iván +3; empatia +1)_
      - **Candela:** Sabe a casa. _[plano PrimerPlano de Candela · silencio 0.8 s]_
      - **Candela:** …Perdón. Me he emocionado con unas lentejas. Es el primer día. _[en la pausa: Baja]_
    - ➤ «Pan con pan. Es lo que hay» _(efecto: humor +1)_
      - **Iván:** El famoso bocadillo de pan. Clásico de primero. El año que viene serás un chef. O no.
  - _Narrador:_ _Cenáis los tres en la cocina compartida, rodeados de estudiantes de todas partes. Alguien pone música. Alguien quema una sartén. Es perfecto._
- **Paso 9 · Acción del jugador** — «Duerme en tu cama de la residencia (de noche, te despiertas a las 8:30)»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván

**Al terminar (momento de la biografía):** «Tu primera semana en la residencia»

---

### Uni02_ElProyecto · «El proyecto»

**Resumen:** Un proyecto en grupo que cuenta la mitad de la nota. Tu grupo: una que lo hace todo, uno que no aparece, uno que quiere mandar y una que siempre llega tarde.

_Tipo: Historia · Trabajo en equipo · Edad: 18-19 años · Duración: 25-40 min_

**Requisitos:** has terminado «La residencia» y has vivido el 10 % de la etapa

**Lo que puede cambiar:** Cómo gestionas el grupo · Qué descubres de cada uno · Equipo unido o todo el trabajo para ti · La nota

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Octubre. Primeros trabajos de verdad.»
  - ⏳ _Pantalla de transición:_ «Octubre. Primeros trabajos de verdad.»
- **Paso 2 · Ir a** [facultad de tu carrera] — «Ve a tu facultad: clase con Beltrán»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Julia, Adrián, Carla
- **Paso 3 · Clase** — «Clase con la profesora Beltrán»
- **Paso 4 · Escena**
  - **Profesora Beltrán:** Proyecto en grupo. Cuenta la mitad de la nota. Los grupos los hago yo, que si no os juntáis siempre con los mismos.
  - _(si en «estudios» elegiste «Medicina»)_ **Profesora Beltrán:** El tema: un caso clínico completo, del síntoma al tratamiento.
  - _(si en «estudios» elegiste «Ingenieria»)_ **Profesora Beltrán:** El tema: diseñar un puente peatonal para el río de Valmar. Con cálculos, no con buenas intenciones.
  - _(si en «estudios» elegiste «Derecho»)_ **Profesora Beltrán:** El tema: un juicio simulado. Un caso real de un vecino contra su ayuntamiento.
  - _(si en «estudios» elegiste «Economia»)_ **Profesora Beltrán:** El tema: un plan de empresa para un negocio de Valmar. Con números que cuadren.
  - **Profesora Beltrán:** Grupo cuatro: [tu nombre], Julia, Pablo, Adrián y Carla.
  - **Adrián:** Perfecto. Yo coordino. Ya tengo un calendario.
  - **Julia:** Yo puedo hacer la introducción. Y el desarrollo. Y las conclusiones. Por si acaso.
  - **Profesora Beltrán:** ¿Pablo? ¿Alguien conoce a Pablo? …Lo que me temía.
- **Paso 5 · Ir a** la Biblioteca Universitaria — «Primera reunión del grupo en la biblioteca»
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Julia, Adrián
- **Paso 6 · Cinemática**
  - 🎬 **Cinemática «Uni02_Reunion»** _(música: → Nada → Tension)_
    - _En escena:_ Adrián, Julia, Carla · _entran andando:_ Carla
    - _Cámara:_ 2 planos (General, Seguir)
    - **Adrián:** Bien. Calendario plastificado. Cada color, una tarea. Cada tarea, un día. _[plano Medio de Adrián]_
    - **Julia:** Yo he traído tres carpetas: introducción, desarrollo y conclusiones. Por si acaso. _[plano Medio de Julia]_
    - **Tú:** ¿Y Pablo? _[plano Reaccion de Julia]_
    - **Adrián:** Pablo es una leyenda. Como el aparcamiento libre. _[plano DosPlanos de Adrián → Julia · en la pausa: Apartar]_
    - **Adrián:** Esto se hace a mi manera o no se hace. No puedo sacar menos de un siete. No puedo. _[plano PrimerPlano de Adrián]_
    - **Julia:** No os preocupéis. Si no llegáis, lo hago yo. Esta noche. Y mañana. Duermo poco, no pasa nada. _[plano PrimerPlano de Julia · en la pausa: Suelo]_
    - **Carla:** ¡Perdón, perdón! No he podido antes. De verdad. _[plano Medio de Carla]_
    - **Carla:** …¿Qué me he perdido? _[plano Reaccion de Carla · en la pausa: Respirar]_
    - **Adrián:** Todo. _[plano DosPlanos de Adrián → Julia]_
    - _(o bien)_ **Julia:** Nada.
    - _(si tienes la marca «llegas tarde reunion»)_ **Adrián:** Y tú tampoco has llegado puntual, [tu nombre]. Diez minutos. Lo he apuntado. _[plano Hombro de Tú → Adrián]_
    - _(si tienes la marca «llegas tarde reunion»)_ **Carla:** ¿Ves? No soy la única. _[plano PrimerPlano de Carla · en la pausa: Reir]_
    - _Narrador:_ _Tu móvil vibra. Es Pablo: «voy luego 👍»._ _[plano PrimerPlano de Tú · silencio 0.6 s]_
    - **Adrián:** «Voy luego». Con pulgar. Eso es un no con pulgar. _[plano Medio de Adrián · en la pausa: Pensar]_
    - **Julia:** …Vale. Lo hago yo. _[plano PrimerPlano de Julia · silencio 0.8 s]_
    - _Narrador:_ _Nadie dice nada. Carla mira el suelo. Adrián, su calendario. Y todos te miran a ti._ _[plano General de Adrián · silencio 0.5 s]_
- **Paso 7 · Decisión** — «El grupo es un desastre. ¿Qué haces?»
  - _En escena:_ Julia, Adrián, Carla
  - ➤ **Opción «Lo hago yo todo, así al menos sale bien»** _(efecto: decisión «gestion» = Todo; responsabilidad +1)_
  - ➤ **Opción «Repartir tareas y fechas en un documento»** _(efecto: decisión «gestion» = Repartir; responsabilidad +1)_
  - ➤ **Opción «Hablar con la profesora Beltrán»** _(efecto: decisión «gestion» = Profesora; Profesora Beltrán +4)_
    - **Profesora Beltrán:** ¿Problemas en el grupo? Qué sorpresa. Cada año, en cada grupo.
    - **Profesora Beltrán:** No voy a hacerlo por vosotros. Pero os voy a pedir un diario de grupo: quién hace qué, y cuándo. Lo leeré.
    - **Profesora Beltrán:** Y un consejo: antes de decidir que alguien es un vago, pregúntale qué le pasa.
  - ➤ **Opción «Pedir que me cambien de grupo»** _(efecto: decisión «gestion» = Cambiar)_
    - **Profesora Beltrán:** ¿Cambiarte de grupo? No.
    - **Profesora Beltrán:** En la vida no se eligen los compañeros de trabajo. Se aprende a trabajar con ellos. Piensa otra cosa.
  - ➤ **Opción «Hablar con cada uno: ¿qué le pasa?»** _(efecto: decisión «gestion» = Hablar; empatia +1)_
- **Paso 8 · Varios objetivos (en cualquier orden)** — «Habla con cada miembro del grupo por separado»
  - _Lugar:_ el parque · _En escena:_ Julia, Adrián, Carla, Alumno, Pablo
  - **Paso 8.1 · Hablar** con Julia — «Julia (biblioteca)»
    - **Julia:** Ya casi tengo la introducción. Y el índice. Y la bibliografía. Llevo dos noches sin dormir, pero está quedando bien.
    - **Julia:** Es que… si sale mal, es culpa mía. Siempre ha sido así. En el instituto siempre lo hacía yo todo.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «No tienes que cargar con todo. Confía un poco en los demás.» _(efecto: Julia +8; empatia +1; marca «julia delega»)_
        - **Julia:** ¿Y si no lo hacen bien? …Vale. Lo intento. Me quedo con la bibliografía. SOLO la bibliografía.
      - ➤ «Genial, así acabamos antes.» _(efecto: Julia -2)_
        - **Julia:** Sí… claro. Así acabamos antes. _[plano PrimerPlano de Julia · en la pausa: Baja]_
  - **Paso 8.2 · Hablar** con Adrián — «Adrián (en la facultad)»
    - **Adrián:** ¿Vienes a quejarte de que mando mucho? Todos lo hacen.
    - **Adrián:** Tengo una beca. Si bajo del siete, la pierdo. Y sin beca, no puedo estar aquí. Por eso lo quiero todo controlado.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Coordinar no es mandar: es escuchar y luego decidir. Te ayudamos.» _(efecto: Adrián +8; empatia +1; marca «adrian escucha»)_
        - **Adrián:** …Escuchar y luego decidir. Vale. Lo pruebo. Si sale mal, te echo la culpa. Es broma. Un poco.
      - ➤ «Pues coordina tú solo, a ver qué tal.» _(efecto: Adrián -3)_
        - **Adrián:** Muy bien. Ya lo hago yo. Como siempre.
  - **Paso 8.3 · Hablar** con Carla — «Carla (en el parque)»
    - _Narrador:_ _Carla está en el parque con un niño pequeño que se columpia. Te ve y se pone roja._
    - **Carla:** Es mi hermano. Mis padres trabajan por la tarde y yo lo recojo del colegio. Por eso llego tarde a todo.
    - **Carla:** No se lo he dicho a nadie. Me daba vergüenza que pensaran que pongo excusas.
    - ❓ **Pregunta al jugador:** ¿Qué le propones?
      - ➤ «Hacemos las reuniones por la mañana, o por videollamada.» _(efecto: Carla +10; empatia +1; marca «carla horario»)_
        - **Carla:** ¿De verdad? Nadie me había propuesto cambiar nada por mí. Gracias. Por la mañana puedo con todo.
      - ➤ «Tienes que organizarte mejor.» _(efecto: Carla -4)_
        - **Carla:** Ya. Organizarme mejor. Claro.
  - **Paso 8.4 · Hablar** con Pablo — «Pablo (dicen que está en la plaza del centro)»
    - _Narrador:_ _En la plaza del centro, un chico toca la guitarra rodeado de gente. Toca muy bien. Es Pablo._
    - **Pablo:** ¡Eh! ¿Eres del grupo? Perdona. No voy a clase casi nunca. Esa carrera la eligieron mis padres. Lo mío es esto.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «¿Y si haces la música y el vídeo de la presentación? Lo tuyo también sirve.» _(efecto: Pablo +10; creatividad +1; marca «pablo musica»)_
        - **Pablo:** ¿Una presentación con banda sonora? …Eso nunca lo ha hecho nadie. Vale. Cuenta conmigo. Esta vez, de verdad.
      - ➤ «Aparece o se lo digo a Beltrán.» _(efecto: Pablo -4; valentia +1)_
        - **Pablo:** Vale, vale. Iré. Pero no esperes mucho de mí.
- **Paso 9 · Ir a** la Biblioteca Universitaria — «Reúne al grupo en la biblioteca: esta vez, los cinco»
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Julia, Adrián, Carla, Pablo
- **Paso 10 · Escena**
  - _(si tienes la marca «carla horario»)_ _Narrador:_ _Esta vez estáis los cinco. Pablo ha venido. Carla ha llegado la primera. Increíble._
  - _(si NO tienes la marca «carla horario»)_ _Narrador:_ _Esta vez estáis los cinco. Carla llega tarde otra vez. Pablo mira el móvil todo el rato._
  - ❓ **Pregunta al jugador:** ¿Cómo os organizáis?
    - ➤ _(si tienes las marcas «adrian escucha», «carla horario» y «pablo musica»)_ «Cada uno en lo que se le da bien: Adrián coordina escuchando, Julia revisa, Carla por las mañanas, Pablo la música» _(efecto: Adrián +4; Carla +4; Julia +4; Pablo +4; marca «equipo unido»)_
      - **Adrián:** Voto a favor. Y lo digo sin calendario en la mano. Es un gran paso para mí.
      - **Pablo:** Ya tengo la canción de la intro. Se llama «Grupo cuatro». Es muy pegadiza.
    - ➤ «Repartir las partes a partes iguales y cada uno a lo suyo» _(efecto: decisión «organizacion» = Partes)_
      - **Julia:** Vale. Pero yo reviso lo de todos al final. No puedo evitarlo.
    - ➤ «Lo termino yo, que ya casi lo tengo» _(efecto: Adrián -2; Julia -2; marca «haces todo»)_
      - _Narrador:_ _Nadie discute. A nadie le importa demasiado. A ti sí: te espera otra noche larga._
- **Paso 11 · Clase** — «Trabajad en el proyecto»
- **Paso 12 · Clase** — «Otra noche de proyecto, a solas» _(solo si tienes la marca «haces todo»)_
- **Paso 13 · Minijuego** — «Ensayo de la presentación»
  - 🎮 _Cómo se juega:_ Pasa cada diapositiva a su tiempo
- **Paso 14 · Transición (pasa el tiempo)** — «El día de la presentación…»
  - ⏳ _Pantalla de transición:_ «El día de la presentación…»
- **Paso 15 · Ir a** [facultad de tu carrera] — «Ve a la facultad: os toca presentar»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Julia, Adrián, Carla, Pablo
- **Paso 16 · Clase** — «La presentación (preguntas de Beltrán)»
- **Paso 17 · Escena**
  - _(si tienes la marca «pablo musica»)_ _Narrador:_ _La presentación empieza con música de Pablo. Beltrán levanta una ceja. Al final, casi sonríe._
  - _(si tienes la marca «equipo unido» y tu última nota es 8 o más)_ **Profesora Beltrán:** Buen trabajo, grupo cuatro. Se nota un equipo detrás. Eso no se puede fingir. Un sobresaliente.
  - _(si tienes la marca «haces todo» y tu última nota es 6 o más)_ **Profesora Beltrán:** Buena nota. Aunque tengo la sensación de que aquí ha trabajado una persona más que las demás.
  - _(si tu última nota es menor que 8 y NO tienes la marca «haces todo»)_ **Profesora Beltrán:** Aprobado. El trabajo cumple. El equipo… está en construcción.
  - _(si en «gestion» elegiste «Profesora»)_ **Profesora Beltrán:** Y he leído vuestro diario de grupo. Entero. Hasta la página de las croquetas. _[en la pausa: Piensa]_
  - _(si tienes las marcas «ensayo bien» y «pablo musica»)_ **Pablo:** ¿Habéis visto? Ni una diapositiva fuera de tiempo. El ensayo sirvió. Lo apunto en la canción.
  - **Adrián:** ¡Mantengo la beca! Gracias. En serio. A todos. Hasta a Pablo. _[plano Medio de Adrián]_
  - _(si tienes la marca «julia delega»)_ **Julia:** He dormido ocho horas esta semana. Seguidas. Es la primera vez desde el instituto.
  - _(si tienes la marca «haces todo»)_ _Narrador:_ _Acabas sin fuerzas. Has sacado el proyecto adelante, pero casi a solas. La próxima vez, quizá, pedirás ayuda antes._
  - _(si tienes la marca «carla horario»)_ **Carla:** Y esta vez he llegado la primera. A la presentación. Que conste. _[plano PrimerPlano de Carla]_
  - **Carla:** ¿Una foto del grupo cuatro? Para el recuerdo. Pablo, deja la guitarra un segundo. _[plano DosPlanos de Carla → Pablo]_

**Al terminar (momento de la biografía):** «El proyecto del grupo imposible»

---

### UniEx1_Enero · «Los exámenes de enero»

**Resumen:** Primer cuatrimestre. La biblioteca abre 24 horas, la cafetería vende más café que nunca y Candela ha plastificado un calendario de exámenes.

_Tipo: Historia · Exámenes · Edad: 18-18 años · Duración: 25-35 min_

**Requisitos:** has terminado «El proyecto» y has vivido el 18 % de la etapa

**Lo que puede cambiar:** Cómo estudias · Examen teórico y prueba física · Recuperación si suspendes

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Enero. Época de exámenes.»
  - ⏳ _Pantalla de transición:_ «Enero. Época de exámenes.»
- **Paso 2 · Escena**
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Candela:** Quedan nueve días, cuatro horas y doce minutos para el primer examen. Lo he calculado. Os he hecho un horario a cada uno.
  - **Iván:** Yo tengo un método: mirar los apuntes muy fuerte la noche antes. Nunca ha funcionado. Pero tengo fe.
  - _Narrador:_ _En la universidad no hay deberes cada día. Nadie te persigue. Todo se juega en unas semanas. Y lo sabes._
- **Paso 3 · Decisión** — «¿Cómo vas a estudiar?»
  - ➤ **Opción «Con el horario plastificado de Candela»** _(efecto: decisión «metodo enero» = Candela; Candela +4; marca «estudio enero»)_
  - ➤ **Opción «A tu ritmo, en la biblioteca»** _(efecto: decisión «metodo enero» = Biblioteca; responsabilidad +1; marca «estudio enero»)_
  - ➤ **Opción «La noche antes, con Iván y mucho café»** _(efecto: decisión «metodo enero» = UltimaNoche; Iván +4; humor +1)_
- **Paso 4 · Clase** — «Estudia en la biblioteca» _(solo si tienes la marca «estudio enero»)_
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Candela (si en «metodo enero» elegiste «Candela»)
- **Paso 5 · Escena** _(solo si en «metodo enero» elegiste «UltimaNoche»)_
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Iván:** Son las tres de la mañana. Llevo cuatro cafés. Veo los apuntes en tres dimensiones. ¿Tú también ves a un señor con perilla en la página doce?
  - _Narrador:_ _No. Nadie ve a nadie con perilla. …¿Verdad? Mejor irse a dormir un par de horas._
- **Paso 6 · Clase** — «Examen teórico de enero (tu carrera)»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 7 · Transición (pasa el tiempo)** — «📋 Notas de enero: ¡APROBADO!» _(solo si tu última nota es 5 o más)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de enero: ¡APROBADO!»
- **Paso 8 · Transición (pasa el tiempo)** — «📋 Notas de enero: suspenso. Toca recuperación.» _(solo si tu última nota es menor que 5)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de enero: suspenso. Toca recuperación.»
- **Paso 9 · Escena**
  - _Lugar:_ el Estadio Universitario · _En escena:_ Iván, Candela
  - _Narrador:_ _En tu carrera no solo cuentan los exámenes: el cuerpo también se evalúa. La prueba física es un circuito por el estadio, contra el reloj._
  - _(si en «estudios» elegiste «Medicina»)_ _Narrador:_ _Medicina: el circuito de urgencias, llevando camillas y material de un box a otro._
  - _(si en «estudios» elegiste «Ingenieria»)_ _Narrador:_ _Ingeniería: la visita de obra, con casco y planos, de un punto de inspección a otro._
  - _(si en «estudios» elegiste «Derecho»)_ _Narrador:_ _Derecho: la carrera de los juzgados, entregando escritos antes de que cierren las ventanillas._
  - _(si en «estudios» elegiste «Economia»)_ _Narrador:_ _Economía: el cierre de la bolsa, llevando órdenes de compra antes de que suene la campana._
  - **Iván:** ¡Vamos, que tú puedes! ¡Yo lo hice ayer y casi me desmayo, así que tú seguro que mejor!
- **Paso 10 · Clase** — «Prueba física de tu carrera (circuito a tiempo)»
- **Paso 11 · Clase** — «Recuperación: vuelve a estudiar» _(solo si tienes la marca «enero suspenso»)_
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Candela
- **Paso 12 · Clase** — «Examen de recuperación» _(solo si tienes la marca «enero suspenso»)_
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 13 · Escena**
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - _(si en «metodo enero» elegiste «Candela» y tienes la marca «enero aprobado»)_ **Candela:** Aprobado. Te lo dije: el horario plastificado nunca falla.
  - _(si tienes la marca «enero aprobado»)_ **Iván:** ¡APROBADO! ¡Esto hay que celebrarlo! Con zumo de mora. …Con MI zumo de mora. Un vasito. Pequeño.
  - _(si tienes la marca «enero suspenso»)_ **Candela:** Suspender el primero le pasa a casi todo el mundo. Lo importante es que en la recuperación ya sabías cómo era.
  - _Narrador:_ _El primer cuatrimestre se acaba. Empieza el segundo. Y la residencia, sin que te des cuenta, ya es tu casa._

**Al terminar (momento de la biografía):** «Tus primeros exámenes de universidad»

---

### Uni03_PrimerTrabajo · «El primer trabajo»

**Resumen:** Los libros, el bus, la vida… Hace falta un trabajo que encaje con las clases. Y aprender a decir que no.

_Tipo: Historia · Trabajo · Edad: 19-19 años · Duración: 20-30 min_

**Requisitos:** has terminado «Los exámenes de enero» y has vivido el 27 % de la etapa

**Lo que puede cambiar:** Cafetería, reparto o clases particulares · Cubrir el turno o estudiar · Tu primera nómina

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Enero. La cuesta de enero.»
  - ⏳ _Pantalla de transición:_ «Enero. La cuesta de enero.»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá
  - **Mamá/Papá:** Los libros de este cuatrimestre… ¿cuánto? ¿Por un libro? ¿Está escrito en oro?
  - **Mamá/Papá:** Te ayudamos en lo que podamos, ya lo sabes. Pero quizá un trabajito de unas horas te vendría bien.
  - _(si en «meta» elegiste «Camara»)_ **Mamá/Papá:** Y lo de la cámara que querías desde el instituto… podrías acercarte por fin.
  - _(si en «meta» elegiste «Ahorro»)_ **Mamá/Papá:** Lo que ahorraste aquel verano te ha venido muy bien. Pero se va acabando.
- **Paso 3 · Usar** — «Crea tu perfil de empleo en la biblioteca del campus»
  - 🖐 _Al usar «Ordenadores de la biblioteca»:_
    - _Narrador:_ _Nombre, estudios, disponibilidad: tardes libres y fines de semana. Y la parte difícil: «¿Qué te hace especial?»_
    - _(si tienes la marca «tiene carta recomendacion»)_ _Narrador:_ _Adjuntas la carta de recomendación de tu primer verano. «Puntual, con palabra y con ganas de aprender.» Valía oro, sí._
    - _(si NO tienes la marca «tiene carta recomendacion»)_ _Narrador:_ _Pones tu primer trabajo de verano. Y el club del instituto. Todo cuenta._
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Mira las ofertas (al menos dos)»
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola, Omar, Ernesto, Rocío
  - **Paso 4.1 · Usar** — «Cafetería Central»
    - 🖐 _Al usar «Oferta: cafetería (tardes)»:_
      - _Narrador:_ _«Cafetería Central busca camarero/a de tardes. Horario flexible para estudiantes. Preguntar por Lola.»_
  - **Paso 4.2 · Usar** — «Correos»
    - 🖐 _Al usar «Oferta: reparto (fines de semana)»:_
      - _Narrador:_ _«Correos: repartidores de fin de semana. Buena paga. Imprescindible conocer Valmar (y no temer a los perros).»_
  - **Paso 4.3 · Usar** — «Tablón de la biblioteca»
    - 🖐 _Al usar «Anuncio: «Busco profe particular»»:_
      - _Narrador:_ _«Busco profe particular para mi hija Alba (9 años). Matemáticas. Mucha paciencia. Llamar a Rocío.» Hay dinosaurios dibujados en el papel._
- **Paso 5 · Decisión** — «¿Qué trabajo coges? (habla con quien contrata)»
  - ➤ **Opción «Cafetería, con Lola (y Omar en la cocina)»** (con Chef Lola) _(efecto: decisión «trabajo uni» = Cafeteria; Chef Lola +4; Omar +4)_
    - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** ¡[tu nombre]! ¡Mi mejor ayudante de verano! Bueno, la única persona que me ayudó aquel verano. ¿Buscas trabajo? Estás contratado/a. Esa es la entrevista.
    - _(si en «empleo» elegiste «Reponedor» y tienes la marca «tiene carta recomendacion»)_ **Chef Lola:** ¿Una carta de recomendación? A ver… ¡de Paco! Si Paco dice algo bueno de alguien, es que es un santo. Contratado/a.
    - **Chef Lola:** Siéntate. ¿Sabes llevar tres cafés a la vez? No. Nadie sabe. Aprenderás. Empiezas el lunes.
    - **Omar:** (desde la cocina) ¡Vamos a trabajar juntos! ¡Como en el festival! ¡Pero con sueldo!
  - ➤ **Opción «Reparto, con Ernesto»** (con Ernesto) _(efecto: decisión «trabajo uni» = Reparto; Ernesto +4)_
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** ¡Anda, el terror del perro del 14! ¿Vuelves? Te guardo la ruta de siempre.
    - **Ernesto:** Fines de semana, paquetes y piernas. ¿Te ves? Pues empiezas el sábado.
  - ➤ **Opción «Clases particulares a Alba»** (con Rocío) _(efecto: decisión «trabajo uni» = Clases; Rocío +4)_
    - **Rocío:** ¡Hola! Soy Rocío, la madre de Alba. Trabajo de noche en el hospital y no llego a ayudarla con los deberes.
    - **Rocío:** Alba odia las matemáticas. Pero adora los dinosaurios. Si consigues unir las dos cosas, eres un genio.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Las fracciones con dinosaurios. Tengo un plan.» _(efecto: creatividad +1)_
        - **Rocío:** ¡Me encanta! Estás contratado/a. Martes y jueves en la biblioteca del campus.
      - ➤ «Con paciencia. Yo también odiaba algo y alguien me ayudó.» _(efecto: empatia +1)_
        - **Rocío:** Eso es justo lo que necesita. Martes y jueves, en la biblioteca del campus.
- **Paso 6 · Ir a** la Cafetería Central — «Primer día en la cafetería» _(solo si en «trabajo uni» elegiste «Cafeteria»)_
  - _En escena:_ Chef Lola (si en «trabajo uni» elegiste «Cafeteria»), Omar (si en «trabajo uni» elegiste «Cafeteria»), Ernesto (si en «trabajo uni» elegiste «Reparto»), Alba (si en «trabajo uni» elegiste «Clases»), Rocío (si en «trabajo uni» elegiste «Clases»)
- **Paso 7 · Ir a** Correos — «Primer día en Correos» _(solo si en «trabajo uni» elegiste «Reparto»)_
  - _Lugar:_ Correos
- **Paso 8 · Ir a** la Biblioteca Universitaria — «Primera clase con Alba (biblioteca del campus)» _(solo si en «trabajo uni» elegiste «Clases»)_
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 9 · Escena**
  - _Lugar:_ la Cafetería Central
  - _(si en «trabajo uni» elegiste «Cafeteria»)_ **Chef Lola:** Delantal, sonrisa y ¡a la barra! Esta vez sin tirar bandejas, ¿eh?
  - _(si en «trabajo uni» elegiste «Reparto»)_ **Ernesto:** Mochila, mapa y paquetes. El perro del 14 ya no ladra. Ahora me ladra a mí.
  - _(si en «trabajo uni» elegiste «Clases»)_ **Alba:** ¿Tú eres la profe? ¿O el profe? Da igual. ¿Te gustan los dinosaurios? Porque si no, esto no va a funcionar.
  - _(si tienes la marca «llegas tarde trabajo uni»)_ _Narrador:_ _Llegas tarde al primer día. Nadie dice nada. Pero lo notas._
- **Paso 10 · Acción del jugador** — «Empieza el turno (tablón de trabajo) y sirve cafés (0/3)» _(solo si en «trabajo uni» elegiste «Cafeteria»)_
- **Paso 11 · Acción del jugador** — «Empieza el turno (tablón de trabajo) y reparte (0/3)» _(solo si en «trabajo uni» elegiste «Reparto»)_
  - _Lugar:_ Correos
- **Paso 12 · Hablar** con Alba — «Clase 1: las fracciones» _(solo si en «trabajo uni» elegiste «Clases»)_
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Alba
  - **Alba:** Las fracciones no sirven para nada. NADA.
  - _Narrador:_ _Dibujas un tiranosaurio que se come la mitad de una pizza. Luego un cuarto. Alba deja de protestar._
  - **Alba:** …¿Y si se come tres cuartos? ¿Le duele la tripa? ¿Y por qué? ¿Y por qué es un cuarto y no un cinco?
- **Paso 13 · Minijuego** — «Explica las fracciones con dinosaurios» _(solo si en «trabajo uni» elegiste «Clases»)_
  - 🎮 _Cómo se juega:_ Cada explicación, en su momento
- **Paso 14 · Hablar** con Alba — «Clase 2: el examen de Alba» _(solo si en «trabajo uni» elegiste «Clases»)_
  - _En escena:_ Alba, Rocío
  - _(si tienes la marca «alba entiende»)_ **Alba:** ¡He sacado un siete en el examen de fracciones! ¡UN SIETE! ¡El tiranosaurio y yo lo hemos conseguido!
  - _(si NO tienes la marca «alba entiende»)_ **Alba:** He sacado un cinco. Aprobado. Todavía no entiendo por qué el tiranosaurio no se come la pizza entera.
  - **Rocío:** No sabes lo que significa esto para nosotras. Gracias.
- **Paso 15 · Escena**
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola (si en «trabajo uni» elegiste «Cafeteria»), Omar (si en «trabajo uni» elegiste «Cafeteria»), Ernesto (si en «trabajo uni» elegiste «Reparto»), Alba (si en «trabajo uni» elegiste «Clases»), Rocío (si en «trabajo uni» elegiste «Clases»)
  - _(si en «trabajo uni» elegiste «Cafeteria»)_ **Chef Lola:** [tu nombre], emergencia: esta noche falta alguien. ¿Puedes cubrir el turno? Te lo pago doble.
  - _(si en «trabajo uni» elegiste «Reparto»)_ **Ernesto:** Tengo cuarenta paquetes y nadie para repartirlos esta tarde. ¿Me echas una mano? Pago extra.
  - _(si en «trabajo uni» elegiste «Clases»)_ **Rocío:** Mañana Alba tiene el examen final de matemáticas y está nerviosísima. ¿Podrías darle una clase extra esta tarde?
  - _Narrador:_ _El problema: mañana tienes examen. Y todavía no has repasado._
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Aceptar: el trabajo es el trabajo» _(efecto: Ernesto +4; Chef Lola +4; Rocío +4; marca «cubriste turno»)_
      - _Narrador:_ _Aceptas. Te llevarás el dinero extra… y llegarás al examen con menos repaso._
    - ➤ «Decir que no, con educación: «Mañana tengo examen»» _(efecto: Ernesto -1; Chef Lola -1; Rocío -1; responsabilidad +1)_
      - _(si en «trabajo uni» elegiste «Cafeteria»)_ **Chef Lola:** Claro, claro. Los estudios primero. Lo arreglo con otra persona. Suerte mañana.
      - _(si en «trabajo uni» elegiste «Reparto»)_ **Ernesto:** Entendido. Primero el examen. Ya me apaño con los perros.
      - _(si en «trabajo uni» elegiste «Clases»)_ **Rocío:** Lo entiendo perfectamente. Le diré a Alba que confíe en el tiranosaurio.
    - ➤ _(si en «trabajo uni» elegiste «Cafeteria»)_ «Proponer a Omar para cubrirlo» _(efecto: Chef Lola +2; Omar +3)_
      - **Omar:** ¿Turno doble? ¿Con croquetas gratis a las tres de la mañana? Hecho. Tú a estudiar.
- **Paso 16 · Clase** — «Estudia para el examen de mañana» _(solo si NO tienes la marca «cubriste turno»)_
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 17 · Acción del jugador** — «Cubre el turno de la noche (0/2)» _(solo si en «trabajo uni» elegiste «Cafeteria» y tienes la marca «cubriste turno»)_
  - _Lugar:_ la Cafetería Central
- **Paso 18 · Acción del jugador** — «Cubre el reparto de la tarde (0/2)» _(solo si en «trabajo uni» elegiste «Reparto» y tienes la marca «cubriste turno»)_
  - _Lugar:_ Correos
- **Paso 19 · Hablar** con Alba — «Clase extra con Alba» _(solo si en «trabajo uni» elegiste «Clases» y tienes la marca «cubriste turno»)_
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Alba
  - **Alba:** ¿Otra vez fracciones? …Vale. Pero hoy el dinosaurio es un triceratops.
  - _Narrador:_ _Una hora más de dinosaurios y pizzas. Alba sale sonriendo. Tú sales pensando en tu examen de mañana._
- **Paso 20 · Clase** — «El examen»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán
- **Paso 21 · Escena**
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola (si en «trabajo uni» elegiste «Cafeteria»), Omar (si en «trabajo uni» elegiste «Cafeteria»), Ernesto (si en «trabajo uni» elegiste «Reparto»), Alba (si en «trabajo uni» elegiste «Clases»), Rocío (si en «trabajo uni» elegiste «Clases»)
  - _Narrador:_ _Tu primera nómina de verdad. Con tu nombre, tus horas y hasta impuestos. Te sientes muy adulto/a. Un poco._
  - _(si tu última nota es 6 o más y NO tienes la marca «cubriste turno»)_ _Narrador:_ _El examen fue bien: habías repasado. Trabajar y estudiar a la vez se puede, si sabes decir que no a tiempo._
  - _(si tienes la marca «cubriste turno» y tu última nota es menor que 6)_ _Narrador:_ _El examen fue regular: llegaste sin repasar. El dinero extra está bien, pero la próxima vez quizá digas que no._
  - _(si en «trabajo uni» elegiste «Cafeteria»)_ **Omar:** ¡Primera nómina! Esto hay que celebrarlo. Invito yo a croquetas. Bueno, invita Lola. Pero se lo pido yo.
  - _(si en «trabajo uni» elegiste «Clases»)_ **Alba:** Te he hecho un dibujo. Eres tú. Con un tiranosaurio. Es para tu nevera.

**Al terminar (momento de la biografía):** «Tu primer trabajo de universitario»

---

### UniEx2_Junio · «Junio (y julio)»

**Resumen:** Fin de primer curso. El examen final de la asignatura más dura. Si sale mal, julio. Y en julio, el campus se queda vacío y hace un calor horrible.

_Tipo: Historia · Exámenes · Edad: 19-19 años · Duración: 25-35 min_

**Requisitos:** has terminado «El primer trabajo» y has vivido el 36 % de la etapa

**Lo que puede cambiar:** Estudiar en grupo o solo · El final de junio · Julio si suspendes

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Junio. El calor, las persianas bajadas y los apuntes por el suelo.»
  - ⏳ _Pantalla de transición:_ «Junio. El calor, las persianas bajadas y los apuntes por el suelo.»
- **Paso 2 · Escena**
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Candela:** Grupo de estudio. Reglas: móviles en la caja, descanso de cinco minutos cada cincuenta, y Iván no puede traer zumo de mora a la biblioteca.
  - **Iván:** Protesto. …Denegado. Vale. Lo traeré en un termo. Nadie sabrá nada.
- **Paso 3 · Clase** — «Grupo de estudio en la biblioteca»
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 4 · Clase** — «Examen final de junio»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 5 · Transición (pasa el tiempo)** — «📋 Notas de junio: ¡APROBADO!» _(solo si tu última nota es 5 o más)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de junio: ¡APROBADO!»
- **Paso 6 · Transición (pasa el tiempo)** — «📋 Notas de junio: suspenso. Toca recuperación.» _(solo si tu última nota es menor que 5)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de junio: suspenso. Toca recuperación.»
- **Paso 7 · Clase** — «Prueba física de final de curso»
  - _Lugar:_ el Estadio Universitario · _En escena:_ Iván, Candela
- **Paso 8 · Transición (pasa el tiempo)** — «Julio. El campus vacío. Solo quedan los que tienen que recuperar… y los ventiladores.» _(solo si tienes la marca «junio suspenso»)_
  - ⏳ _Pantalla de transición:_ «Julio. El campus vacío. Solo quedan los que tienen que recuperar… y los ventiladores.»
- **Paso 9 · Clase** — «Estudia para julio» _(solo si tienes la marca «junio suspenso»)_
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 10 · Clase** — «Convocatoria de julio» _(solo si tienes la marca «junio suspenso»)_
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 11 · Escena**
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Iván:** ¡PRIMERO DE CARRERA TERMINADO! ¡Soy oficialmente un estudiante de segundo! Casi un adulto. Casi.
  - **Candela:** Este verano vuelvo a casa. Pero el año que viene… ¿seguimos en la misma habitación? He hecho una lista de pros. No hay contras.
  - _Narrador:_ _Recoges la habitación para el verano. La foto del grupo de siempre ahora tiene al lado otra: los tres en la cocina, con una sartén quemada de fondo._

**Al terminar (momento de la biografía):** «Aprobaste primero de carrera»

---

### Uni04_Practicas · «Las prácticas»

**Resumen:** Por primera vez, lo que estudias pasa en el mundo real. Un tutor, un caso de verdad… y un error que nadie ha visto todavía.

_Tipo: Historia · Prácticas · Edad: 20-21 años · Duración: 30-40 min_

**Requisitos:** has terminado «Junio (y julio)» y has vivido el 45 % de la etapa

**Lo que puede cambiar:** Un caso distinto para cada carrera · Qué haces con tu error · Oferta de trabajo o no

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Tercer curso. Empiezan las prácticas.»
  - ⏳ _Pantalla de transición:_ «Tercer curso. Empiezan las prácticas.»
- **Paso 2 · Ir a** [lugarpracticas de tu carrera] — «Ve al sitio de tus prácticas»
  - _Lugar:_ [lugarpracticas de tu carrera] · _En escena:_ Doctora Nuria (si en «estudios» elegiste «Medicina»), Sofía (si en «estudios» elegiste «Ingenieria»), Montse (si en «estudios» elegiste «Derecho»), Ignacio (si en «estudios» elegiste «Economia»)
- **Paso 3 · Escena**
  - _(si en «estudios» elegiste «Medicina» y tienes la marca «interes medicina»)_ **Doctora Nuria:** ¡Anda! ¡La persona de la semana de las profesiones! Te dije que te guardaría el sitio. Bienvenido/Bienvenida a urgencias.
  - _(si en «estudios» elegiste «Medicina» y NO tienes la marca «interes medicina»)_ **Doctora Nuria:** Bienvenido/Bienvenida a urgencias. Soy Nuria. Aquí se aprende rápido o se aprende corriendo.
  - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «interes ingenieria»)_ **Sofía:** ¡La persona de los triángulos! Ahora trabajo para TecnoVal, y adivina: eres mi estudiante en prácticas.
  - _(si en «estudios» elegiste «Ingenieria» y NO tienes la marca «interes ingenieria»)_ **Sofía:** Soy Sofía, ingeniera de TecnoVal. Aquí rompemos cosas para que no se rompan. Bienvenido/Bienvenida.
  - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Soy Montse. En este bufete la regla es sencilla: primero se escucha, luego se lee, y al final se habla.
  - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Soy Ignacio, director de la oficina. Aquí los números cuentan historias. Tu trabajo es leerlas.
  - _(si tienes la marca «llegas tarde practicas»)_ _Narrador:_ _Llegas tarde el primer día. Te miran el reloj. Nadie dice nada._
- **Paso 4 · Clase** — «Primera jornada de prácticas»
- **Paso 5 · Escena**
  - _En escena:_ Doctora Nuria (si en «estudios» elegiste «Medicina»), Sofía (si en «estudios» elegiste «Ingenieria»), Montse (si en «estudios» elegiste «Derecho»), Ignacio (si en «estudios» elegiste «Economia»), Un paciente (si en «estudios» elegiste «Medicina»), Un vecino (si en «estudios» elegiste «Derecho»), Marcos (si en «estudios» elegiste «Economia»)
  - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** Tu primer caso: este señor llega con dolor en el pecho. Puede ser muchas cosas. No adivines: investiga.
  - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** Tu caso: la pasarela del río de Valmar vibra cuando pasa mucha gente. ¿Es peligroso? ¿Cómo se arregla?
  - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Tu caso: este vecino dice que el ayuntamiento le ha multado injustamente. Él dice que no aparcó allí. ¿Tiene razón?
  - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Tu caso: Marcos, el de las bicicletas, pide un préstamo para abrir otra tienda. ¿Se lo damos?
  - _(si en «estudios» elegiste «Economia» y tienes la marca «interes economia»)_ **Marcos:** ¡Anda, eres tú! ¡La persona de las bicis azules! Ahora sí que estoy en tus manos. Literalmente.
- **Paso 6 · Varios objetivos (en cualquier orden)** — «Trabaja en el caso»
  - **Paso 6.1 · Usar** — «Lee el historial» _(solo si en «estudios» elegiste «Medicina»)_
    - 🖐 _Al usar «Historial del paciente»:_
      - _Narrador:_ _Sesenta años, fumador hasta hace poco, sube tres pisos cada día. Y ayer comió muchísimo en una boda._
  - **Paso 6.2 · Usar** — «Explora al paciente (con Nuria)» _(solo si en «estudios» elegiste «Medicina»)_
    - 🖐 _Al usar «Camilla»:_
      - **Un paciente:** Me duele aquí, al tragar. Y cuando me tumbo, más.
      - **Doctora Nuria:** Buena pregunta la tuya: «¿cuándo le duele más?». Eso no lo pregunta todo el mundo.
  - **Paso 6.3 · Usar** — «Revisa los análisis» _(solo si en «estudios» elegiste «Medicina»)_
    - 🖐 _Al usar «Resultados del análisis»:_
      - _Narrador:_ _El corazón está perfecto. El estómago, no tanto: es ardor, de la comida de la boda. Nada grave. El señor suspira aliviado._
  - **Paso 6.4 · Usar** — «Inspecciona la pasarela» _(solo si en «estudios» elegiste «Ingenieria»)_
    - 🖐 _Al usar «La pasarela del río (maqueta)»:_
      - _Narrador:_ _La pasarela vibra al ritmo de los pasos. Si todos caminan igual, la vibración crece. Por eso hay carteles de «no correr»._
  - **Paso 6.5 · Usar** — «Compara materiales» _(solo si en «estudios» elegiste «Ingenieria»)_
    - 🖐 _Al usar «Muestras de materiales»:_
      - _Narrador:_ _Acero, madera laminada, fibra de carbono. El acero pesa, la fibra es cara. Hay que elegir con cabeza, no con el bolsillo._
  - **Paso 6.6 · Usar** — «Diseña la solución» _(solo si en «estudios» elegiste «Ingenieria»)_
    - 🖐 _Al usar «Mesa de planos»:_
      - _Narrador:_ _Dibujas unos amortiguadores debajo del tablero. Como los de una bici, pero gigantes._
      - **Sofía:** Amortiguadores de masa. Así se hizo con un puente famoso de Londres. Tienes buen ojo.
  - **Paso 6.7 · Usar** — «Lee el expediente» _(solo si en «estudios» elegiste «Derecho»)_
    - 🖐 _Al usar «El expediente del caso»:_
      - _Narrador:_ _La multa dice: calle Mayor, 10:15. La señal de prohibido se puso… a las 10:30, según el ayuntamiento._
  - **Paso 6.8 · Usar** — «Analiza la declaración» _(solo si en «estudios» elegiste «Derecho»)_
    - 🖐 _Al usar «Declaración del testigo»:_
      - **Un vecino:** Yo vi cómo ponían la señal. Mi coche ya estaba ahí desde las nueve. Tengo el tique de la panadería de las 9:05.
  - **Paso 6.9 · Usar** — «Busca la ley que se aplica» _(solo si en «estudios» elegiste «Derecho»)_
    - 🖐 _Al usar «Estantería de leyes»:_
      - _Narrador:_ _La ley es clara: una señal no puede multar algo que pasó antes de que existiera. El vecino tiene razón._
      - **Montse:** Muy bien. La mitad de este trabajo es mirar las horas. La otra mitad, explicarlo sin que nadie se enfade.
  - **Paso 6.10 · Usar** — «Revisa las cuentas» _(solo si en «estudios» elegiste «Economia»)_
    - 🖐 _Al usar «Las cuentas de la empresa»:_
      - _Narrador:_ _La tienda de Marcos vende más cada año. Poco, pero siempre más. Y no debe nada a nadie._
  - **Paso 6.11 · Usar** — «Analiza el mercado» _(solo si en «estudios» elegiste «Economia»)_
    - 🖐 _Al usar «Estudio de mercado»:_
      - _Narrador:_ _En Playa Dorada no hay ninguna tienda de bicis. Y cada verano llegan miles de turistas._
  - **Paso 6.12 · Usar** — «Calcula el riesgo» _(solo si en «estudios» elegiste «Economia»)_
    - 🖐 _Al usar «Informe de riesgos»:_
      - _Narrador:_ _Calculas el riesgo: bajo. La idea de alquilar bicis a turistas (¿te suena?) tiene sentido._
      - **Ignacio:** Bien razonado. Los buenos préstamos no se dan por simpatía, pero tampoco se niegan por miedo.
- **Paso 7 · Escena**
  - _En escena:_ Doctora Nuria (si en «estudios» elegiste «Medicina»), Sofía (si en «estudios» elegiste «Ingenieria»), Montse (si en «estudios» elegiste «Derecho»), Ignacio (si en «estudios» elegiste «Economia»)
  - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Buen análisis. El informe, en mi mesa. Mañana lo firmo y va al comité. _[plano Medio de Ignacio]_
  - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Bien. Deja el recurso en mi mesa. Mañana lo firmo y lo presentamos. _[plano Medio de Montse]_
  - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** Buen turno. Déjame el informe en la mesa y mañana lo firmo. Vete a dormir, que se te nota. _[plano Medio de Doctora Nuria]_
  - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** Buen trabajo. Déjame el informe en la mesa; mañana lo firmo y lo mandamos al ayuntamiento. _[plano Medio de Sofía]_
  - **Tú:** Un segundo, que lo repaso. _[plano PrimerPlano de Tú]_
  - _Narrador:_ _Un número mal copiado._ _[silencio 1.0 s]_
  - _(si en «estudios» elegiste «Medicina»)_ _Narrador:_ _Una dosis mal puesta en la hoja del paciente. Nadie la ha usado todavía. Pero podría pasar._
  - _(si en «estudios» elegiste «Ingenieria»)_ _Narrador:_ _Un cálculo de carga mal hecho. Con esos números, la pasarela vibraría el doble._
  - _(si en «estudios» elegiste «Derecho»)_ _Narrador:_ _Una hora mal copiada en el recurso. Con esa hora, el vecino perdería el caso._
  - _(si en «estudios» elegiste «Economia»)_ _Narrador:_ _Un cero de más. Con ese número, el préstamo de Marcos parece un riesgo enorme._
  - **Tú:** …No. No, no, no. _[en la pausa: Baja · silencio 0.6 s]_
  - ❓ **Pregunta al jugador:** Nadie lo ha visto todavía. ¿Qué haces?
    - ➤ «Decírselo ahora, antes de que lo firme» _(efecto: responsabilidad +2; valentia +1; decisión «error informe» = Decir)_
      - **Tú:** Espera. Antes de firmarlo… tengo que enseñarte algo. _[plano Medio de Tú · silencio 0.8 s]_
      - **Tú:** Me he equivocado. Aquí. Este número está mal. _[plano PrimerPlano de Tú · en la pausa: Baja]_
      - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** …A ver. Sí. Con este cero, el comité habría dicho que no. _[plano PrimerPlano de Ignacio · en la pausa: Piensa · silencio 1.2 s]_
      - _(si en «estudios» elegiste «Derecho»)_ **Montse:** …A ver. Sí. Con esta hora, el caso estaba perdido. _[plano PrimerPlano de Montse · en la pausa: Piensa · silencio 1.2 s]_
      - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** …A ver. Sí. Esto, en un paciente de verdad, habría sido un susto serio. _[plano PrimerPlano de Doctora Nuria · en la pausa: Piensa · silencio 1.2 s]_
      - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** …A ver. Sí. Con esto, la pasarela habría bailado. Literalmente. _[plano PrimerPlano de Sofía · en la pausa: Piensa · silencio 1.2 s]_
      - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Corrígelo ahora. Y gracias. En un banco, avisar a tiempo vale más que acertar. _[plano DosPlanos de Ignacio → Tú · en la pausa: Asiente]_
      - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Corrígelo ahora. Y gracias. Decirlo antes es lo que separa a un buen abogado de uno peligroso. _[plano DosPlanos de Montse → Tú · en la pausa: Asiente]_
      - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** Corrígelo delante de mí. Y gracias. Esto es lo más importante que vas a aprender aquí. _[plano DosPlanos de Doctora Nuria → Tú · en la pausa: Asiente]_
      - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** Corrígelo delante de mí. Y gracias: los puentes se caen por los errores que nadie dice. _[plano DosPlanos de Sofía → Tú · en la pausa: Asiente]_
    - ➤ «Corregirlo en silencio: nadie tiene por qué saberlo» _(efecto: responsabilidad +1; decisión «error informe» = Silencio)_
      - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** ¿Todo bien? _[plano Reaccion de Ignacio]_
      - _(si en «estudios» elegiste «Derecho»)_ **Montse:** ¿Todo bien? _[plano Reaccion de Montse]_
      - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** ¿Todo bien? _[plano Reaccion de Doctora Nuria]_
      - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** ¿Todo bien? _[plano Reaccion de Sofía]_
      - **Tú:** Sí, sí. Todo bien. Una tilde. _[plano PrimerPlano de Tú · en la pausa: Aparta]_
    - ➤ «Dejarlo. Seguramente nadie lo note» _(efecto: decisión «error informe» = Dejar)_
      - **Tú:** Aquí tienes. _[en la pausa: Baja]_
      - _Narrador:_ _El informe se queda en la mesa. El número, también._ _[silencio 0.8 s]_
- **Paso 8 · Clase** — «Segunda jornada: presenta tu informe»
- **Paso 9 · Escena**
  - _(si en «error informe» elegiste «Decir» y en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** Viniste a decirme tu propio error antes de que lo viera yo. ¿Sabes cuántos médicos no lo hacen? Esto vale más que acertar.
  - _(si en «error informe» elegiste «Decir» y en «estudios» elegiste «Ingenieria»)_ **Sofía:** Me contaste tu error sin que te lo pidiera. Así se construyen puentes que no se caen.
  - _(si en «error informe» elegiste «Decir» y en «estudios» elegiste «Derecho»)_ **Montse:** Reconocer un error ante tu tutora es lo más difícil de esta profesión. Lo has hecho el primer mes.
  - _(si en «error informe» elegiste «Decir» y en «estudios» elegiste «Economia»)_ **Ignacio:** Me avisaste del cero de más antes de que llegara al comité. Eso, en un banco, es oro.
  - _(si en «error informe» elegiste «Silencio»)_ _Narrador:_ _Revisan el informe. Está bien. Nadie sabe que hubo un error. Tú sí._
  - _(si en «error informe» elegiste «Dejar»)_ _Narrador:_ _En la revisión aparece el error. «Esto podría haber sido grave. La próxima vez, revisa y avisa.»_
  - _(si en «error informe» elegiste «Decir» y tu última nota es 6 o más)_ _Narrador:_ _Al final de las prácticas, te llaman al despacho. Hay una oferta: cuando termines la carrera, aquí tienes un sitio._
  - _Narrador:_ _Terminan las prácticas. Te llevas un informe firmado y la sensación de que esto va en serio._

**Al terminar (momento de la biografía):** «Tus primeras prácticas»

---

### UniEx3_Parcial · «El parcial imposible»

**Resumen:** Todos en la facultad hablan de él: el examen de la profesora Beltrán que nadie aprueba a la primera. Te toca.

_Tipo: Historia · Exámenes · Edad: 20-20 años · Duración: 25-35 min_

**Requisitos:** has terminado «Las prácticas» y has vivido el 54 % de la etapa

**Lo que puede cambiar:** La tutoría con Beltrán · El parcial · La prueba física más dura

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Tercer curso. El parcial imposible.»
  - ⏳ _Pantalla de transición:_ «Tercer curso. El parcial imposible.»
- **Paso 2 · Hablar** con Profesora Beltrán — «Ve a la tutoría de la profesora Beltrán»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán
  - **Profesora Beltrán:** Vienes a la tutoría antes del parcial. Eso solo lo hace uno de cada diez. Los otros nueve vienen después, a llorar.
  - **Profesora Beltrán:** Te diré un secreto: mi examen no es imposible. Solo pregunta lo que de verdad hay que saber para ejercer. Lo que no se puede copiar.
  - ❓ **Pregunta al jugador:** ¿Qué le preguntas?
    - ➤ «¿Qué es lo que más falla la gente?» _(efecto: Profesora Beltrán +5; marca «tutoria beltran»)_
      - **Profesora Beltrán:** Estudian para aprobar, no para entender. Entiende el tema cuatro y el resto sale solo. No se lo digas a nadie.
    - ➤ «¿Por qué es usted tan dura?» _(efecto: valentia +1; marca «tutoria beltran»)_
      - **Profesora Beltrán:** Porque dentro de unos años alguien va a confiar en ti. Un paciente, un cliente, un puente. Prefiero ser dura yo ahora que la vida después.
- **Paso 3 · Clase** — «Estudia lo que Beltrán te ha dicho que mires»
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 4 · Clase** — «Repaso final en la residencia (Iván hace de profe)»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván
- **Paso 5 · Clase** — «El parcial imposible»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 6 · Transición (pasa el tiempo)** — «📋 Notas de el parcial: ¡APROBADO!» _(solo si tu última nota es 5 o más)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de el parcial: ¡APROBADO!»
- **Paso 7 · Transición (pasa el tiempo)** — «📋 Notas de el parcial: suspenso. Toca recuperación.» _(solo si tu última nota es menor que 5)_
  - ⏳ _Pantalla de transición:_ «📋 Notas de el parcial: suspenso. Toca recuperación.»
- **Paso 8 · Clase** — «La prueba física de tercero (la más dura)»
  - _Lugar:_ el Estadio Universitario · _En escena:_ Iván, Candela
- **Paso 9 · Clase** — «Segunda oportunidad del parcial» _(solo si tienes la marca «parcial suspenso»)_
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 10 · Escena**
  - _En escena:_ Profesora Beltrán
  - _(si tienes la marca «parcial aprobado»)_ **Profesora Beltrán:** Has aprobado mi parcial. En treinta años lo he dicho pocas veces con esta cara. Enhorabuena.
  - _(si tienes la marca «parcial suspenso»)_ **Profesora Beltrán:** No aprobaste a la primera. Casi nadie lo hace. Pero volviste, y en la segunda lo entendiste. Eso es lo que quería ver.
  - _Narrador:_ _En el pasillo, alguien ha escrito en el tablón: «Superviviente del parcial de Beltrán». Añades tu nombre debajo de otros cuarenta._

**Al terminar (momento de la biografía):** «Aprobaste el parcial imposible»

---

### Uni05_PrimerPiso · «Tu primer piso»

**Resumen:** Llaves propias, cajas por todas partes y la nevera vacía. Te independizas.

_Tipo: Historia · Vida adulta · Edad: 21-21 años · Duración: 20-30 min_

**Requisitos:** has terminado «El parcial imposible» y has vivido el 63 % de la etapa

**Lo que puede cambiar:** Con quién vives · La caja misteriosa · Cómo resolvéis la convivencia

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Cuarto curso. Es hora de volar.»
  - ⏳ _Pantalla de transición:_ «Cuarto curso. Es hora de volar.»
- **Paso 2 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** Siéntate. Tenemos que hablar. No, no es nada malo. Es que… estás en cuarto. Tres años en la residencia, compartiendo cuarto y nevera.
  - **Mamá/Papá:** Hemos pensado que quizá es hora de que tengas tu propio piso. De verdad. Con tu nombre en el buzón. Te ayudamos a empezar.
  - _(si en «meta» elegiste «Ahorro»)_ **Mamá/Papá:** Y lo que llevas ahorrando desde aquel verano del instituto por fin va a servir para algo grande.
  - **Abu:** Yo me fui de casa con una maleta y un bocadillo. El bocadillo me duró dos horas. La maleta, cuarenta años.
  - ❓ **Pregunta al jugador:** ¿Qué sientes?
    - ➤ «¡Por fin! Tengo muchas ganas.» _(efecto: valentia +1)_
      - **Mamá/Papá:** Ya lo sé. Se te nota desde los catorce. Pero vendrás a comer los domingos, ¿eh? Eso no es negociable.
    - ➤ «Me da un poco de miedo.» _(efecto: Mamá/Papá +5; empatia +1)_
      - **Mamá/Papá:** A mí también me dio miedo. Y a Abu. El miedo es la señal de que estás creciendo. Aquí tienes siempre tu cuarto.
- **Paso 3 · Decisión** — «¿Con quién vas a vivir? (habla con quien elijas en el campus, o siéntate a pensarlo a tu aire)»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Sara, Luca, Candela, Iván
  - ➤ **Opción «Con Sara»** (con Sara) _(efecto: decisión «compi piso» = Sara; Sara +6)_
    - **Sara:** ¡Sí! Llevo dos años diseñando mentalmente la convivencia ideal. Tengo un cuadrante de limpieza. Con colores.
    - **Sara:** Y mis hongos del laboratorio vienen conmigo. Están en un tarro. Son muy tranquilos.
  - ➤ **Opción «Con Luca»** (con Luca) _(efecto: decisión «compi piso» = Luca; Luca +6)_
    - **Luca:** ¡Perfetto! Me quedo en Valmar para el máster. Yo cocino, tú friegas. Es el pacto italiano.
    - **Luca:** Y los domingos, pasta fresca. Con la receta de mi nonna. Es un secreto de Estado.
  - ➤ **Opción «Con Iván y Candela (los de la residencia)»** (con Candela) _(efecto: decisión «compi piso» = Resi; Candela +6; Iván +6)_
    - **Candela:** ¿Seguir juntos? ¿Fuera de la residencia? He hecho una lista de pros y contras. Contras: Iván. Pros: Iván. Se anulan. Sí.
    - **Iván:** ¡Piso propio! ¡Con nevera PROPIA! ¡Una balda entera para el zumo de mora! …Vale, media balda. Candela ya me está mirando.
  - ➤ **Opción «A tu aire»** _(efecto: decisión «compi piso» = Solo; valentia +1)_
    - _Narrador:_ _Te sientas a pensar. Nunca has vivido a tu aire. Nadie que te diga qué comer ni a qué hora dormir. Da vértigo. Y ganas._
- **Paso 4 · Acción del jugador** — «Busca una casa libre (cartel «Se vende») y quédatela»
  - _En escena:_ Sara (si en «compi piso» elegiste «Sara») (te acompaña), Luca (si en «compi piso» elegiste «Luca») (te acompaña), Iván (si en «compi piso» elegiste «Resi») (te acompaña), Candela (si en «compi piso» elegiste «Resi») (te acompaña)
- **Paso 5 · Escena**
  - _Narrador:_ _La llave gira. La puerta se abre. Huele a pintura y a casa vacía. Es tuya._
  - _(si en «compi piso» elegiste «Sara»)_ **Sara:** Técnicamente, las paredes son de un color llamado «hueso». Lo cambiaremos. Por el bien de todos.
  - _(si en «compi piso» elegiste «Luca»)_ **Luca:** ¡Mamma mia, qué luz! Aquí pongo la mesa grande. Para las cenas. Vendrá gente. Siempre viene gente.
  - _(si en «compi piso» elegiste «Solo»)_ _Narrador:_ _Dices «hola» en voz alta. El eco te contesta. Te ríes a solas. Qué raro. Qué bien._
- **Paso 6 · Varios objetivos (en cualquier orden)** — «Deshaz la mudanza»
  - **Paso 6.1 · Usar** — «La caja de la cocina»
    - 🖐 _Al usar «Caja: «COCINA»»:_
      - _Narrador:_ _Dos platos, dos vasos, una sartén y un tupper de croquetas con una nota: «Por si acaso. Te queremos»._
  - **Paso 6.2 · Usar** — «La caja de la ropa»
    - 🖐 _Al usar «Caja: «ROPA (y más ropa)»»:_
      - _Narrador:_ _Ropa, más ropa… y al fondo, la sudadera de dinosaurios de cuando tenías seis años. ¿Quién ha metido esto aquí?_
  - **Paso 6.3 · Usar** — «La caja que pone «NO ABRIR»»
    - 🖐 _Al usar «Caja: «NO ABRIR — de tu familia»»:_
      - _Narrador:_ _Dentro: tu primera mochila del cole, dibujos tuyos de pequeño/a, y una carta de tu familia._
      - _Narrador:_ _«Para cuando te vayas de casa. Aquí tienes todo lo que fuiste. Llévalo contigo a todo lo que vas a ser.»_
      - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Debajo de la carta, el cromo de la suerte del primer día de colegio._
- **Paso 7 · Acción del jugador** — «Primera cena en tu casa: compra algo y cómetelo»
  - ⏰ _Si tardas, Narrador dice:_ «La nevera sigue vacía. Hay sitios de comida por toda la ciudad.»
- **Paso 8 · Escena**
  - _(si en «compi piso» elegiste «Sara»)_ _Narrador:_ _Primera noche. Sara ha colgado el cuadrante de limpieza. Tú ya vas tarde con la primera tarea: fregar._
  - _(si en «compi piso» elegiste «Luca»)_ _Narrador:_ _Primera noche. Luca ha cocinado para ocho. Sois dos. La cocina parece un campo de batalla._
  - _(si en «compi piso» elegiste «Solo»)_ _Narrador:_ _Primera noche. Silencio. Solo el frigorífico hace ruido. Nunca te habías fijado en lo que suena un frigorífico._
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Friegas lo tuyo y lo de los demás sin decir nada» _(efecto: responsabilidad +1; decisión «convivencia» = Hacerlo)_
      - _Narrador:_ _La cocina queda reluciente. Mañana, ya veremos._
    - ➤ «Habláis y hacéis un reparto justo» _(efecto: Luca +3; Sara +3; empatia +1; decisión «convivencia» = Hablar)_
      - _(si en «compi piso» elegiste «Sara»)_ **Sara:** Propuesta aceptada. Añado una columna al cuadrante: «Quien cocina no friega». Es justo.
      - _(si en «compi piso» elegiste «Luca»)_ **Luca:** Vale, vale. Yo cocino para dos. No para ocho. Bueno, para cuatro. Por si viene alguien.
      - _(si en «compi piso» elegiste «Solo»)_ _Narrador:_ _Hablas contigo: «¿Quién friega hoy?» «Yo.» «Vale.» Te ríes. Es un buen reparto._
    - ➤ «Llamas a tu familia» _(efecto: Mamá/Papá +4; decisión «convivencia» = Llamar)_
      - **Tú:** ¿Hola? Soy yo. No, no pasa nada. Solo quería oíros. _[plano PrimerPlano de Tú]_
      - _Narrador:_ _Al otro lado: «¿Ya nos echas de menos? ¡Si te has ido esta mañana!». Una pausa. «…Nosotros también. Mucho.»_ _[silencio 0.6 s]_
- **Paso 9 · Cinemática** — «Llaman a la puerta: es Abu»
  - 🎬 **Cinemática «Uni05_Visita»** _(música: → Intima)_
    - _En escena:_ Abu, Sara, Luca, Iván, Candela · _entran andando:_ Abu
    - _Cámara:_ 1 planos (Seguir)
    - **Abu:** ¿Se puede? Traigo una planta. Toda casa necesita algo vivo. _[plano DosPlanos de Abu → Tú]_
    - **Abu:** Riégala los lunes. Si no, te la regaño yo. _[plano Medio de Abu · en la pausa: Senalar]_
    - **Tú:** Los lunes. Prometido. _[plano Reaccion de Tú]_
    - _(si en «compi piso» elegiste «Sara»)_ **Sara:** ¡Encantada! He incluido la planta en el cuadrante de riego. Tiene color propio: verde planta. _[plano Medio de Sara]_
    - _(si en «compi piso» elegiste «Luca»)_ **Luca:** Buonasera! ¿Se queda a cenar? He hecho pasta para ocho. Somos dos. Bueno, ahora tres. _[plano Medio de Luca]_
    - _(si en «compi piso» elegiste «Resi»)_ **Candela:** Hola. Le he hecho sitio a la planta. Está etiquetada. Iván, no la riegues con zumo. _[plano DosPlanos de Candela → Iván]_
    - _(si en «convivencia» elegiste «Hacerlo»)_ **Abu:** Mmm. Esto está muy recogido. Demasiado. ¿Quién ha fregado? _[plano PrimerPlano de Abu · en la pausa: Pensar]_
    - _(si en «convivencia» elegiste «Llamar»)_ **Abu:** Tu familia dice que ayer llamaste. Hicieron como que no lloraban. Lloraron. _[plano PrimerPlano de Abu]_
    - **Abu:** Has abierto la caja. …La carta la escribimos entre todos. La letra bonita es mía. _[plano PrimerPlano de Abu · en la pausa: Suelo · silencio 0.8 s]_
    - **Abu:** Tu primera mochila. Te llegaba por las rodillas. Y no la soltabas ni para dormir. _[plano Reaccion de Tú · en la pausa: Respirar]_
    - **Abu:** ¿Llevas el reloj? _[plano PPP de Abu · silencio 0.8 s]_
    - _(si llevas reloj abu (1))_ **Tú:** Siempre. _[plano Reaccion de Tú]_
    - _(si llevas reloj abu (1))_ **Abu:** Lo llevas. Ahora tienes tu casa y tu tiempo. Úsalos bien. _[plano DosPlanos de Abu → Tú · en la pausa: Mirar]_
    - _(si NO se cumple: llevas reloj abu (1))_ **Tú:** Yo… No lo llevo. _[plano Reaccion de Tú · en la pausa: Suelo]_
    - _(si NO se cumple: llevas reloj abu (1))_ **Abu:** Bueno. Los relojes se pierden. Lo que te enseñé, no. Eso no se pierde. _[plano DosPlanos de Abu → Tú · silencio 0.8 s]_
    - **Abu:** Y esto son croquetas. No son de Lola: son mías. Mejores. No se lo digas. _[plano Medio de Abu · silencio 0.5 s]_
    - _(si tienes la marca «sabe cocinar»)_ **Abu:** Aunque me han dicho que haces una tortilla que hace llorar a la gente. Algún domingo me la enseñas. _[plano PrimerPlano de Abu · en la pausa: Reir]_
- **Paso 10 · Acción del jugador** — «Duerme por primera vez en tu casa (tu cama)»
- **Paso 11 · Escena**
  - _Narrador:_ _Te despiertas con la luz que entra por una ventana que todavía no tiene cortinas. Es tu casa. Es tu vida._
  - _(si en «compi piso» elegiste «Sara»)_ **Sara:** Buenos días. He hecho café. Y he etiquetado tu taza. Por si la confundías con la mía.
  - _(si en «compi piso» elegiste «Luca»)_ **Luca:** ¡Buongiorno! Hay pasta de ayer. En Italia, la pasta de ayer es desayuno. Es la ley.

**Al terminar (momento de la biografía):** «Tu primer piso»

---

### UniEx4_TFG · «El trabajo de fin de grado»

**Resumen:** Cuarto curso. Lo último que te separa del título: tu TFG, defenderlo delante de un tribunal y la prueba física final de tu carrera.

_Tipo: Historia · Exámenes · Edad: 21-21 años · Duración: 30-40 min_

**Requisitos:** has terminado «Tu primer piso» y has vivido el 72 % de la etapa

**Lo que puede cambiar:** El tema del TFG · La defensa ante el tribunal · La última prueba física

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Cuarto curso. El último.»
  - ⏳ _Pantalla de transición:_ «Cuarto curso. El último.»
- **Paso 2 · Decisión** — «¿Sobre qué haces tu trabajo de fin de grado?»
  - ➤ **Opción «Sobre el caso de tus prácticas»** _(efecto: decisión «tema tfg» = Practicas; responsabilidad +1)_
  - ➤ **Opción «Sobre algo de Valmar (tu ciudad)»** _(efecto: decisión «tema tfg» = Valmar; curiosidad +1)_
  - ➤ **Opción «Sobre «fenómenos inexplicables en Los Pinos» (a Beltrán le va a dar algo)»** _(efecto: decisión «tema tfg» = Raro; humor +1; marca «tfg raro»)_
- **Paso 3 · Clase** — «Escribe tu TFG (biblioteca)»
  - _Lugar:_ la Biblioteca Universitaria
- **Paso 4 · Clase** — «Corrige tu TFG (otra vez; siempre hay otra vez)»
  - _En escena:_ Candela
- **Paso 5 · Escena**
  - _En escena:_ Iván, Candela
  - **Iván:** Yo hago de tribunal malvado. «Señor o señora estudiante: ¿y eso para qué sirve?» …¿Qué tal? Llevo cuatro años ensayando esa cara.
  - **Candela:** Yo cronometro. Tienes quince minutos. Si te pasas, suena mi alarma. Es una sirena de barco. Me la regalaron.
  - _Narrador:_ _Ensayas cinco veces. A la quinta, Iván aplaude y Candela no toca la sirena. Es un buen presagio._
- **Paso 6 · Clase** — «La defensa del TFG ante el tribunal»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
- **Paso 7 · Clase** — «La última prueba física de la carrera»
  - _Lugar:_ el Estadio Universitario · _En escena:_ Iván, Candela
- **Paso 8 · Escena**
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Candela, Iván
  - **Profesora Beltrán:** El tribunal ha deliberado. Trabajo sólido, defensa clara, y ha respondido bien a la pregunta trampa. Aprobado.
  - _(si tienes la marca «tfg raro»)_ **Profesora Beltrán:** «Fenómenos inexplicables en Los Pinos». Nunca había leído un TFG con un capítulo sobre una gallina gigante. Tiene bibliografía. Muy seria. …Aprobado.
  - **Iván:** (desde el público) ¡ESO ES! ¡ESA PERSONA ES MI COMPI DE CUARTO! ¡CUATRO AÑOS! ¡SIN TOCARME EL ZUMO!
  - _Narrador:_ _Recibes 📘 tu Trabajo de Fin de Grado, encuadernado. Solo falta la graduación._

**Al terminar (momento de la biografía):** «Defendiste tu trabajo de fin de grado»

---

### Uni06_Graduacion · «La graduación»

**Resumen:** Toga, birrete, tu nombre por el altavoz y todos los que importan en la sala. Terminas la universidad.

_Tipo: Historia · Final de capítulo · Edad: 22-22 años · Duración: 25-35 min_

**Requisitos:** has terminado «El trabajo de fin de grado» y has vivido el 90 % de la etapa

**Lo que puede cambiar:** Tu nota media · Qué te pones · El brindis: los recuerdos de toda tu vida

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Junio del último curso.»
  - ⏳ _Pantalla de transición:_ «Junio del último curso.»
- **Paso 2 · Clase** — «Último repaso en la biblioteca»
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Julia, Adrián
- **Paso 3 · Clase** — «El último examen de la carrera»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán
- **Paso 4 · Escena**
  - _(si tu última nota es 7 o más)_ **Profesora Beltrán:** Último examen corregido. Enhorabuena: con esto, terminas la carrera. Con buena nota, además.
  - _(si tu última nota es menor que 7)_ **Profesora Beltrán:** Último examen corregido. Aprobado. Lo importante es que terminas. Y que sabes más que cuando llegaste.
  - **Profesora Beltrán:** Treinta años viendo entrar y salir gente. Algunos se me olvidan. Tú no. Y no pienso decir por qué.
- **Paso 5 · Transición (pasa el tiempo)** — «El día de la graduación…»
  - ⏳ _Pantalla de transición:_ «El día de la graduación…»
- **Paso 6 · Escena**
  - _Lugar:_ Aquí · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Toga y birrete! A ver, date la vuelta. …Estás guapísimo/a. Perdón, es que me emociono.
  - ❓ **Pregunta al jugador:** ¿Qué llevas debajo de la toga?
    - ➤ «Tu mejor ropa: hoy es un día importante» _(efecto: decisión «look graduacion» = Elegante)_
      - **Mamá/Papá:** Impecable. Como para una foto que vas a enseñar el resto de tu vida.
    - ➤ «La sudadera de dinosaurios (si cabe)» _(efecto: humor +1; decisión «look graduacion» = Dinosaurios)_
      - **Mamá/Papá:** ¿La de los seis años? ¡No te puede caber! …Te cabe. Por los pelos. Esto es historia.
    - ➤ «Algo sencillo, que lo importante es el día» _(efecto: decisión «look graduacion» = Sencillo)_
      - **Abu:** Bien dicho. La ropa no se acuerda de nada. Las personas, sí.
  - **Abu:** ¿Llevas el reloj? …Lo llevas. Entonces vámonos, que no quiero llegar tarde a lo más importante de este año.
- **Paso 7 · Ir a** [facultad de tu carrera] — «Ve a tu facultad: la ceremonia empieza pronto»
  - _Lugar:_ [facultad de tu carrera] · _En escena:_ Profesora Beltrán, Luca, Mamá/Papá, Abu, Mateo (si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»), Leire (si tienes la marca «conoces a leire»), Julia, Adrián, Carla, Pablo
- **Paso 8 · Varios objetivos (en cualquier orden)** — «Saluda antes de la ceremonia (al menos tres)»
  - **Paso 8.1 · Hablar** con Julia — «Julia»
    - **Julia:** ¿Sabes qué? Ya no lo hago todo yo. Bueno, casi todo. Pero ahora duermo. Gracias por aquel proyecto.
  - **Paso 8.2 · Hablar** con Adrián — «Adrián»
    - **Adrián:** Mantuve la beca los cuatro años. Y aprendí a coordinar sin gritar. Casi. Si alguna vez necesitas un jefe que escuche, llámame.
  - **Paso 8.3 · Hablar** con Carla — «Carla»
    - **Carla:** Mi hermano ha venido a verme. Dice que de mayor quiere ser «como la gente del grupo cuatro». No sé qué le hemos hecho.
  - **Paso 8.4 · Hablar** con Pablo — «Pablo»
    - _(si tienes la marca «pablo musica»)_ **Pablo:** Me gradúo. Y en septiembre, conservatorio. Doble vida: de día, lo que querían mis padres; de noche, lo que quiero yo.
    - _(si NO tienes la marca «pablo musica»)_ **Pablo:** Me gradúo, ¿te lo puedes creer? Yo tampoco. Ni mis padres. Sobre todo mis padres.
  - **Paso 8.5 · Hablar** con Luca — «Luca»
    - **Luca:** Vine un año de Erasmus y me he quedado cinco. Es culpa de Valmar. Y de las croquetas. Y un poco tuya.
    - _(si en «compi piso» elegiste «Luca»)_ **Luca:** Y después de vivir juntos, sé todos tus secretos. Como que nunca friegas los domingos.
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Uni06_Ceremonia»** _(música: → Nada → Resolucion)_
    - _En escena:_ Profesora Beltrán, Mamá/Papá, Abu, Julia, Adrián, Carla, Pablo, Luca, Mateo, Leire
    - _Cámara:_ 2 planos (General, Seguir)
    - 🪧 _Rótulo:_ «🎓 Tu diploma» — Cuatro años en una hoja de papel. Pesa más de lo que parece.
    - ⏸ _El jugador debe reaccionar:_ «»
    - **Profesora Beltrán:** Autoridades, familias, graduados. Me han pedido que sea breve. _[plano Medio de Profesora Beltrán]_
    - **Profesora Beltrán:** Seré breve. Es mentira. Pero lo intentaré. _[plano Reaccion de Mamá/Papá · en la pausa: Pensar]_
    - _(si en «error informe» elegiste «Decir»)_ **Profesora Beltrán:** Hoy no os lleváis solo un título. Os lleváis los errores que tuvisteis el valor de confesar… _[plano PrimerPlano de Profesora Beltrán]_
    - _(si NO se cumple: en «error informe» elegiste «Decir»)_ **Profesora Beltrán:** Hoy no os lleváis solo un título. Os lleváis los errores, los que se ven y los que no… _[plano PrimerPlano de Profesora Beltrán]_
    - _(si tienes la marca «equipo unido»)_ **Profesora Beltrán:** …los grupos que sobrevivisteis. Alguno, hasta se convirtió en un equipo. _[plano Pan de Julia → Pablo]_
    - _(si tienes la marca «haces todo» y NO tienes la marca «equipo unido»)_ **Profesora Beltrán:** …los grupos que sobrevivisteis. Aunque en alguno trabajara una persona por cinco. _[plano Reaccion de Tú]_
    - _(si NO tienes las marcas «equipo unido» y «haces todo»)_ **Profesora Beltrán:** …los grupos que sobrevivisteis, como buenamente pudisteis. _[plano Pan de Julia → Pablo]_
    - **Profesora Beltrán:** Y lo que aprendisteis de gente muy distinta a vosotros. Eso no sale en el expediente. _[plano Medio de Profesora Beltrán]_
    - **Profesora Beltrán:** Y ahora, los nombres. _[plano General de Profesora Beltrán · silencio 0.6 s]_
    - **Profesora Beltrán:** [tu nombre]. _[plano PPP de Tú]_
    - **Mamá/Papá:** ¡Esa es mi…! ¡Ese es…! ¡ES DE MI FAMILIA! _[plano Medio de Mamá/Papá]_
    - **Profesora Beltrán:** Sabía que llegarías. No se lo digas a nadie: tengo una reputación. _[plano DosPlanos de Profesora Beltrán → Tú]_
    - _(si tienes la marca «oferta trabajo»)_ **Profesora Beltrán:** Y la empresa de tus prácticas ya me ha preguntado por ti. Tienes trabajo esperando. _[plano PrimerPlano de Profesora Beltrán]_
    - _(si tienes la marca «tfg raro»)_ **Profesora Beltrán:** Por cierto: he recomendado tu TFG a la biblioteca. Sección de misterio. Lo de la gallina gigante sigue sin parecerme normal. _[plano PrimerPlano de Profesora Beltrán]_
    - _(si en «tema tfg» elegiste «Valmar»)_ **Profesora Beltrán:** Tu TFG sobre Valmar ya está en la biblioteca municipal. Lo he comprobado. Dos veces. _[plano PrimerPlano de Profesora Beltrán]_
    - **Mamá/Papá:** ¡BRAVO, [tu nombre]! ¡BRAVOOO! _[plano Medio de Mamá/Papá · en la pausa: Celebrar]_
    - _(si en «look graduacion» elegiste «Dinosaurios»)_ **Abu:** Se le ve la sudadera de dinosaurios por debajo de la toga. Es lo más bonito que he visto en mi vida. _[plano PrimerPlano de Abu]_
    - _(si NO se cumple: en «look graduacion» elegiste «Dinosaurios»)_ **Abu:** Las cosas buenas tardan mucho. Y luego pasan rapidísimo. _[plano PrimerPlano de Abu · en la pausa: Respirar]_
- **Paso 10 · Cinemática**
  - 🎬 **Cinemática «Uni_Graduacion»** _(vuelo de cámara, 13 s, 2 planos; música: TemaValmar)_
    - 🪧 _Rótulo:_ «¡Te has graduado!» — Universidad de Valmar
    - **Rectora:** Hoy salís de aquí con un título. Pero lo que de verdad os lleváis es lo que habéis aprendido a hacer juntos.
- **Paso 11 · Escena**
  - _Narrador:_ _Birretes al aire. Todos a la vez. El grupo cuatro, Luca, tu familia._ _[plano General]_
  - _(si tienes la marca «conoces a leire»)_ **Leire:** ¡Quietos! Esta la hago yo, con la cámara de mi abuelo. Nada de móviles. Como en la orla del instituto. _[plano Medio de Leire]_
  - **Mamá/Papá:** ¿Salgo bien? No, espera. Ahora. ¡Ahora sí! _[plano Medio de Mamá/Papá · en la pausa: Sonrie]_
  - _Narrador:_ _Clic. Una foto que vas a enseñar muchas veces. Probablemente más de las necesarias._ _[silencio 0.6 s]_
- **Paso 12 · Ir a** la Cafetería Central — «Celebración en la Cafetería Central: Lola ha cerrado para vosotros»
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola, Omar, Sara, Nico, Leire (si tienes la marca «conoces a leire»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Mamá/Papá, Abu, Luca, Iván, Candela, Julia, Adrián, Carla
- **Paso 13 · Cinemática**
  - 🎬 **Cinemática «Uni06_Brindis»** _(música: → Intima)_
    - _En escena:_ Chef Lola, Omar, Sara, Nico, Bruno, Mamá/Papá, Abu, Luca, Iván, Candela, Julia, Adrián, Carla, Leire, Mateo
    - _Cámara:_ 1 planos (General)
    - **Chef Lola:** ¡Cerrado por graduación! Hoy invita la casa. Bueno, invita Omar. La casa supervisa. _[plano Medio de Chef Lola]_
    - **Omar:** Propongo un brindis. Cada uno dice algo que recuerde de [tu nombre]. Empiezo yo. _[plano Medio de Omar · en la pausa: Senalar]_
    - _(si tienes el recuerdo «el rumor»)_ **Omar:** La foto aquella del instituto. Tú plantaste cara. Por eso llevo todavía la pulsera. _[plano PrimerPlano de Omar]_
    - _(si tienes el recuerdo «primer dia cole» y NO tienes el recuerdo «el rumor»)_ **Omar:** El primer día de colegio. Tú no me conocías y ya me guardabas la mitad de todo. Bueno, eso era yo contigo. _[plano PrimerPlano de Omar]_
    - _(si tienes el recuerdo «el festival» y NO tienes los recuerdos «el rumor» y «primer dia cole»)_ **Omar:** El festival. Las magdalenas. La purpurina de Vega, que sigo encontrando en mi ropa. _[plano PrimerPlano de Omar]_
    - _(si tienes la marca «ayudaste a mateo» y tienes el recuerdo «primer amigo»)_ **Mateo:** Mis libros por el suelo del pasillo. Alguien se agachó a ayudarme. Todo empezó ahí. _[plano PrimerPlano de Mateo]_
    - _(si tienes el recuerdo «misterio colegio»; y NO si en «compi piso» elegiste «Sara»)_ **Sara:** La sala cerrada. La foto de Lucía con coletas. Todavía me escribe por Navidad. _[plano PrimerPlano de Sara]_
    - _(si tienes el recuerdo «mochila perdida» y NO tienes el recuerdo «misterio colegio»; y NO si en «compi piso» elegiste «Sara»)_ **Sara:** La mochila desaparecida. Nuestra primera investigación. Técnicamente, la primera de muchas. _[plano PrimerPlano de Sara]_
    - _(si en «compi piso» elegiste «Sara»)_ **Sara:** El piso. El cuadrante de limpieza sigue colgado. Nadie lo cumple. Lo dejo por nostalgia. _[plano PrimerPlano de Sara · en la pausa: Reir]_
    - _(si tienes la marca «torneo ganado»)_ **Nico:** ¡La final del torneo! Oro. Todavía tengo la medalla colgada. Bueno, la mía, no la tuya. _[plano Medio de Nico · en la pausa: Celebrar]_
    - _(si tienes la marca «torneo perdido» y NO tienes la marca «torneo ganado»)_ **Nico:** La final del torneo. Plata. Y aun así, el mejor día de mi vida. No se lo digáis a mi entrenador. _[plano Medio de Nico]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Un banco del instituto. Yo comía sola y apareció alguien. Nunca te lo agradecí bien. Gracias. _[plano PrimerPlano de Leire · en la pausa: Suelo]_
    - _(si en «adios bruno» elegiste «DeCero»)_ **Bruno:** Yo… que empezamos de cero. Y salió bien. Ahora soy policía. ¿Quién lo iba a decir? _[plano Medio de Bruno · en la pausa: Suelo]_
    - _(si NO se cumple: en «adios bruno» elegiste «DeCero»)_ **Bruno:** Que éramos rivales. Ya ni me acuerdo de por qué. Enhorabuena. De verdad. _[plano Medio de Bruno]_
    - _(si tienes el recuerdo «primer sueldo»)_ **Chef Lola:** Alguien tirando una bandeja entera en su primer turno. Mírate ahora. _[plano PrimerPlano de Chef Lola · en la pausa: Reir]_
    - _(si en «error informe» elegiste «Decir»)_ **Mamá/Papá:** Las prácticas: dijiste la verdad aunque te costara. Eso no lo enseña ninguna carrera. _[plano Medio de Mamá/Papá]_
    - _(si tienes el recuerdo «casi suspendo»; y NO si en «error informe» elegiste «Decir»)_ **Mamá/Papá:** Aquel examen que casi suspendiste. Y cómo lo arreglaste sin que nadie te obligara. _[plano Medio de Mamá/Papá]_
    - _(si en «comida uni» elegiste «Luca»; y NO si en «cita» elegiste «Luca»)_ **Luca:** Tu primer día. Comimos juntos a las dos menos cinco. Quedaban croquetas. _[plano PrimerPlano de Luca]_
    - _(si tienes la marca «sabe cocinar»)_ **Iván:** Una tortilla. Primera semana de residencia. He comido muchas desde entonces. Ninguna como esa. _[plano PrimerPlano de Iván]_
    - _(si tienes el recuerdo «zumo de mora» y NO tienes la marca «sabe cocinar»)_ **Iván:** La guerra del zumo de mora. Y quién la arregló. Mi abuela te manda una botella. _[plano PrimerPlano de Iván]_
    - _(si tienes la marca «tito descubierto»)_ **Candela:** Un compañero de cuarto que no existía. Sigue sin estar en mi Excel. Por algo será. _[plano PrimerPlano de Candela]_
    - _(si NO se cumple: tienes la marca «tito descubierto»)_ **Candela:** Tres años de horario de limpieza. Cumpliste el ochenta y siete por ciento. Es un récord. _[plano PrimerPlano de Candela]_
    - _(si tienes la marca «equipo unido»; y NO si en «cita» elegiste «Adrian»)_ **Adrián:** El grupo cuatro. Cinco desconocidos y, al final, un equipo. Mantuve la beca gracias a eso. _[plano PrimerPlano de Adrián]_
    - _(si tienes la marca «rey de la pista» y NO tienes la marca «equipo unido»; y NO si en «cita» elegiste «Adrian»)_ **Adrián:** La fiesta en mi casa. El rey de la pista. Mi vecino todavía pregunta por ti. _[plano Medio de Adrián]_
    - _(si tienes la marca «haces todo»; y NO si en «cita» elegiste «Julia»)_ **Julia:** Que sacaste aquel proyecto casi sin ayuda. Ahora sé lo que es eso. No lo vuelvas a hacer, ¿vale? _[plano PrimerPlano de Julia]_
    - _(si tienes la marca «llegas tarde reunion»; y NO si en «cita» elegiste «Carla»)_ **Carla:** Que una vez llegaste más tarde que yo a una reunión. Una. Pero la tengo apuntada. _[plano PrimerPlano de Carla · en la pausa: Reir]_
    - _(si en «cita» elegiste «Julia» y tienes la marca «tiene pareja»)_ **Julia:** Dos helados derritiéndose en Playa Dorada. …Y lo que me dijiste. _[plano PPP de Julia]_
    - _(si en «cita» elegiste «Adrian» y tienes la marca «tiene pareja»)_ **Adrián:** Un atardecer en el que, por una vez, no quise mandar en nada. _[plano PPP de Adrián]_
    - _(si en «cita» elegiste «Luca» y tienes la marca «tiene pareja»)_ **Luca:** Un gelato en Playa Dorada. Mejor que la pasta de mi nonna. No se lo contéis a ella. _[plano PPP de Luca]_
    - _(si en «cita» elegiste «Carla» y tienes la marca «tiene pareja»)_ **Carla:** La primera vez que llegué a tiempo a algo. Era un atardecer. Contigo. _[plano PPP de Carla]_
    - _(si en «cita» elegiste «Julia» y tienes la marca «amistad especial»)_ **Julia:** Una tarde de helado en la playa. De ahí salió una de las mejores amistades que tengo. _[plano PrimerPlano de Julia]_
    - _(si en «cita» elegiste «Adrian» y tienes la marca «amistad especial»)_ **Adrián:** Una tarde de helado en la playa. Me dijiste algo bonito. Lo tengo apuntado. No en el calendario. _[plano PrimerPlano de Adrián]_
    - _(si en «cita» elegiste «Luca» y tienes la marca «amistad especial»)_ **Luca:** El gelato en la playa. Amici per sempre. Eso no se traduce. _[plano PrimerPlano de Luca]_
    - _(si en «cita» elegiste «Carla» y tienes la marca «amistad especial»)_ **Carla:** El helado en la playa. Llegué a tiempo. Y me dijiste que era de lo mejor que tenías aquí. Igualmente. _[plano PrimerPlano de Carla]_
    - _(si tienes el recuerdo «primer piso»)_ **Abu:** Y yo me acuerdo del día que naciste. Eras así de pequeñito. Y mírate: con reloj, con casa y con una planta que sigue viva. _[plano PrimerPlano de Abu · en la pausa: Respirar · silencio 0.8 s]_
    - _(si NO se cumple: tienes el recuerdo «primer piso»)_ **Abu:** Y yo me acuerdo del día que naciste. Eras así de pequeñito. Y mírate. Con reloj y todo. _[plano PrimerPlano de Abu · en la pausa: Respirar · silencio 0.8 s]_
    - **Omar:** ¡Por [tu nombre]! ¡Y por todos los que vamos a seguir acordándonos! _[plano General de Omar · en la pausa: Celebrar]_
    - _Narrador:_ _Todos levantan el vaso. Omar llora. Dice que es por la cebolla de las croquetas. No hay cebolla._ _[plano PrimerPlano de Omar]_
- **Paso 14 · Cinemática**
  - _En escena:_ Chef Lola, Omar, Mamá/Papá, Abu
  - 🎬 **Cinemática «Uni06_Final»** _(música: → Intima → Tema)_
    - _En escena:_ Abu, Mamá/Papá, Chef Lola, Omar
    - _Cámara:_ 3 planos (General)
    - 🪧 _Rótulo:_ «🎓 Fin de la etapa universitaria» — Empieza la vida profesional
    - **Chef Lola:** Venga, que cierro. Los graduados también friegan. _[plano Medio de Chef Lola]_
    - **Omar:** Hoy no. Hoy friego yo. Vete, que me pongo sentimental con la fregona. _[plano DosPlanos de Omar → Chef Lola · en la pausa: Reir]_
    - **Abu:** Ven. Siéntate un momento. _[plano DosPlanos de Abu → Tú · silencio 0.6 s]_
    - **Abu:** ¿Qué hora es? _[plano PrimerPlano de Abu]_
    - _(si llevas reloj abu (1))_ **Tú:** Las once y diez. _[plano Reaccion de Tú · en la pausa: Suelo]_
    - _(si llevas reloj abu (1))_ **Abu:** Pues apúntala. Las once y diez del día que terminaste. Esas horas no vuelven. Pero se guardan. _[plano PrimerPlano de Abu]_
    - _(si NO se cumple: llevas reloj abu (1))_ **Tú:** No llevo reloj. _[plano Reaccion de Tú · en la pausa: Suelo]_
    - _(si NO se cumple: llevas reloj abu (1))_ **Abu:** Yo tampoco. Da igual: hoy es tarde y es pronto a la vez. Así se sabe que ha sido un buen día. _[plano PrimerPlano de Abu]_
    - **Mamá/Papá:** Vámonos a casa. Mañana empieza todo lo demás. _[plano Medio de Mamá/Papá · silencio 0.5 s]_
    - _Narrador:_ _Esa noche dejas el diploma encima de la mesa. Al lado, el reloj viejo. Y la foto de hoy._
    - _Narrador:_ _Te acuerdas de cómo empezó todo: una mochila más grande que tú, un pasillo lleno de gente, alguien que te sonrió._ _[silencio 0.6 s]_

**Al terminar (momento de la biografía):** «Te graduaste»

---

**Texto de cierre del capítulo:** «Tu etapa como estudiante ha terminado.»

- 🎬 **Final del capítulo (cinemática) «Uni_FinCapitulo»** _(vuelo de cámara, 8 s, 2 planos; música: TemaValmar)_
  - 🪧 _Rótulo:_ «La universidad» — Fin del capítulo
  - 🪧 _Rótulo:_ «Tu etapa como estudiante ha terminado.» — Próximamente: Volar del nido

# Capítulo «Volar del nido»

_Id: Adulto_VolarDelNido · Etapa: AdultoJoven · Música de fondo: VidaAdulta_

**Solo si:** has terminado «La gran decisión»

**Texto de entrada del capítulo:** «Tu vida adulta empieza de verdad: trabajo, facturas… y la gente que te importa.»

- 🎬 **Cabecera del capítulo (cinemática) «Nido_Entrada»** _(vuelo de cámara, 9 s, 2 planos; música: VidaAdulta)_
  - 🪧 _Rótulo:_ «Volar del nido» — Trabajo, facturas… y la gente que te importa

### Adu01_PrimerContrato · «Mi primer contrato»

**Resumen:** Un contrato de verdad, con tu nombre. Un primer día de adulto. Y las primeras facturas, que también llevan tu nombre.

_Tipo: Historia · Vida adulta · Edad: 22-23 años · Duración: 20-30 min_

**Lo que puede cambiar:** Trabajo de tu carrera o ascenso en tu trabajo · Qué haces con las facturas

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Septiembre. Un lunes cualquiera… que no es cualquiera.»
  - ⏳ _Pantalla de transición:_ «Septiembre. Un lunes cualquiera… que no es cualquiera.»
- **Paso 2 · Acción del jugador** — «Busca una casa libre (cartel «Se vende») y quédatela: vas a necesitar tu propio sitio» _(solo si NO tienes la marca «tiene hogar»)_
- **Paso 3 · Ir a** [lugarpracticas de tu carrera] — «Primer día de trabajo: ve donde hiciste las prácticas» _(solo si tienes la marca «graduado»)_
  - _Lugar:_ [lugarpracticas de tu carrera] · _En escena:_ Doctora Nuria (si en «estudios» elegiste «Medicina» y tienes la marca «graduado»), Sofía (si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»), Montse (si en «estudios» elegiste «Derecho» y tienes la marca «graduado»), Ignacio (si en «estudios» elegiste «Economia» y tienes la marca «graduado»), Chef Lola (si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»), Paco (si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»), Ernesto (si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)
- **Paso 4 · Ir a** la Cafetería Central — «Lola quiere hablar contigo en la cafetería» _(solo si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_
  - _Lugar:_ la Cafetería Central
- **Paso 5 · Ir a** el supermercado — «Paco quiere hablar contigo en el supermercado» _(solo si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_
  - _Lugar:_ el supermercado
- **Paso 6 · Ir a** Correos — «Ernesto quiere hablar contigo en Correos» _(solo si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_
  - _Lugar:_ Correos
- **Paso 7 · Cinemática**
  - _Lugar:_ [lugarpracticas de tu carrera]
  - 🎬 **Cinemática «Adu01_PrimerDia»** _(música: → Descubrimiento)_
    - _En escena:_ Doctora Nuria, Sofía, Montse, Ignacio, Chef Lola, Paco, Ernesto
    - _Cámara:_ 8 planos (General, Reaccion)
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado» y NO tienes la marca «llegas tarde contrato»)_ **Doctora Nuria:** ¡Mirad quién ha llegado! Y en hora. Eso aquí ya es medio diagnóstico. _[plano PrimerPlano de Doctora Nuria · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Medicina» y tienes las marcas «graduado» y «llegas tarde contrato»)_ **Doctora Nuria:** Las ocho y veinte. En urgencias, veinte minutos son una eternidad. Que no se repita, ¿vale? _[plano PrimerPlano de Doctora Nuria · gesto HandsOnHips · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Medicina» y tienes las marcas «graduado», «llegas tarde contrato» y «llegas tarde practicas»)_ **Doctora Nuria:** Llegaste tarde a las prácticas y llegas tarde al contrato. Empiezo a pensar que es una tradición. _[en la pausa: Pensar]_
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Doctora Nuria → Tú · en la pausa: Respirar]_
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Ven, que hay papeles. Muchos. Y café, si sobrevives a los papeles. _[plano DosPlanos de Doctora Nuria → Tú · ademán Point]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado» y NO tienes la marca «llegas tarde contrato»)_ **Sofía:** ¡Justo a tiempo! Como un engranaje recién engrasado. _[plano PrimerPlano de Sofía · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes las marcas «graduado» y «llegas tarde contrato»)_ **Sofía:** Veinte minutos tarde. En ingeniería lo llamamos «margen de error». No lo conviertas en costumbre. _[plano PrimerPlano de Sofía · gesto HandsOnHips · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes las marcas «graduado», «llegas tarde contrato» y «llegas tarde practicas»)_ **Sofía:** Tarde a las prácticas, tarde hoy. Si fueras un puente, ya te estaría revisando los cálculos. _[en la pausa: Pensar]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Sofía → Tú · en la pausa: Respirar]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Sofía:** Ven, ven. Hay algo encima de mi mesa que lleva tu nombre. _[plano DosPlanos de Sofía → Tú · ademán Point]_
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado» y NO tienes la marca «llegas tarde contrato»)_ **Montse:** Buenos días. Puntual. Me gusta. En este despacho, el tiempo se cobra por horas. _[plano PrimerPlano de Montse · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Derecho» y tienes las marcas «graduado» y «llegas tarde contrato»)_ **Montse:** Buenos días. …Las nueve y veinte. No voy a levantar la voz. Tampoco lo voy a olvidar. _[plano PrimerPlano de Montse · gesto HandsOnHips · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Derecho» y tienes las marcas «graduado», «llegas tarde contrato» y «llegas tarde practicas»)_ **Montse:** La primera vez fue en las prácticas. Esta es la segunda. Un tribunal no daría una tercera. _[en la pausa: Pensar]_
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Montse → Tú · en la pausa: Respirar]_
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Montse:** Siéntate, por favor. Hay un documento que quiero que leas despacio. _[plano DosPlanos de Montse → Tú · ademán Point]_
    - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado» y NO tienes la marca «llegas tarde contrato»)_ **Ignacio:** ¡Puntual al minuto! Los números y yo te damos la bienvenida. _[plano PrimerPlano de Ignacio · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Economia» y tienes las marcas «graduado» y «llegas tarde contrato»)_ **Ignacio:** Veinte minutos tarde. En intereses de demora, eso sale carísimo. Te lo perdono. Esta vez. _[plano PrimerPlano de Ignacio · gesto HandsOnHips · silencio 4.4 s]_
    - _(si en «estudios» elegiste «Economia» y tienes las marcas «graduado», «llegas tarde contrato» y «llegas tarde practicas»)_ **Ignacio:** Dos retrasos en dos primeros días. Si esto fuera una gráfica, me preocuparía la tendencia. _[en la pausa: Pensar]_
    - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Ignacio → Tú · en la pausa: Respirar]_
    - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Ignacio:** Ven a mi mesa. He traído un bolígrafo. Bueno, tres. Por si acaso. _[plano DosPlanos de Ignacio → Tú · ademán Point]_
    - _(si en «empleo» elegiste «Barista» y NO tienes las marcas «graduado» y «llegas tarde contrato»)_ **Chef Lola:** ¡Ahí estás! ¡Quita de la puerta, que entra el reparto! …Y luego ven, que tenemos que hablar. Sin delantal. _[plano PrimerPlano de Chef Lola · silencio 4.4 s]_
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Chef Lola → Tú · en la pausa: Respirar]_
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Chef Lola:** Siéntate. No, en esa silla no, que cojea. En esa. _[plano DosPlanos de Chef Lola → Tú · ademán Point]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes las marcas «graduado» y «llegas tarde contrato»)_ **Paco:** Hmm. Has venido. _[plano PrimerPlano de Paco · silencio 4.4 s]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Paco → Tú · en la pausa: Respirar]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Paco:** A mi despacho. Es como el almacén, pero con silla. _[plano DosPlanos de Paco → Tú · ademán Point]_
    - _(si en «empleo» elegiste «Repartidor» y NO tienes las marcas «graduado» y «llegas tarde contrato»)_ **Ernesto:** ¡Hombre! ¡Justo a tiempo! Acabo de clasificar tu calle. _[plano PrimerPlano de Ernesto · silencio 4.4 s]_
    - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Tú:** Buenos días. Vengo a… bueno, ya sabes a qué vengo. _[plano Hombro de Ernesto → Tú · en la pausa: Respirar]_
    - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Ernesto:** Hoy no repartes. Hoy te sientas un momento conmigo. _[plano DosPlanos de Ernesto → Tú · ademán Point]_
- **Paso 8 · Escena**
  - _(si en «estudios» elegiste «Medicina» y tienes las marcas «graduado» y «oferta trabajo»)_ **Doctora Nuria:** ¡Aquí está! Te esperábamos desde las prácticas. Bienvenido/a al equipo. Esta vez, con bata propia.
  - _(si en «estudios» elegiste «Ingenieria» y tienes las marcas «graduado» y «oferta trabajo»)_ **Sofía:** ¡Por fin! En TecnoVal nadie se ha olvidado de quién confesó su propio error. Tienes mesa, ordenador y un proyecto.
  - _(si en «estudios» elegiste «Derecho» y tienes las marcas «graduado» y «oferta trabajo»)_ **Montse:** Te guardamos el despacho pequeño. El de la ventana. Aquí la honestidad se paga… bueno, se paga con un contrato.
  - _(si en «estudios» elegiste «Economia» y tienes las marcas «graduado» y «oferta trabajo»)_ **Ignacio:** La oficina te esperaba. Firma aquí. Y aquí. Y aquí. Los bancos adoramos las firmas.
  - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado» y NO tienes la marca «oferta trabajo»)_ **Doctora Nuria:** Veinte currículums y vuelves aquí. Buena elección: en esta casa ya sabemos cómo trabajas.
  - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado» y NO tienes la marca «oferta trabajo»)_ **Sofía:** Veinte currículums enviados y te llamamos nosotros. Ya sabíamos cómo trabajabas en las prácticas.
  - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado» y NO tienes la marca «oferta trabajo»)_ **Montse:** De veinte sitios, solo uno te llamó. Este. Aquí no olvidamos a quien trabaja bien.
  - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado» y NO tienes la marca «oferta trabajo»)_ **Ignacio:** Veinte currículums. Una respuesta. Estadísticamente, un cinco por ciento. Personalmente, un cien.
  - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Chef Lola:** Siéntate. Me jubilo el año que viene y necesito a alguien que lleve esto. Encargado/a. ¿Te atreves?
  - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Paco:** Hmm. Siéntate. Llevas años aquí. Nunca una caja mal puesta. Quiero que seas encargado/a. No me hagas repetirlo.
  - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Ernesto:** Necesito a alguien que lleve la ruta de todo Valmar. Conoces cada calle y cada perro. Jefe/a de ruta. ¿Aceptas?
  - _(si en «empleo» elegiste «Barista» y tienes la marca «antecedentes» y NO tienes la marca «graduado»)_ **Chef Lola:** Sé lo del estadio. Y lo de la comisaría. Todo Valmar lo sabe. Aun así, confío en ti. No me hagas arrepentirme.
  - _(si en «estudios» elegiste «Medicina» y tienes las marcas «graduado» y «antecedentes»)_ **Doctora Nuria:** En la entrevista nos contaste lo de tu expediente de menores. Todo. Te contratamos por cómo lo contaste.
  - _(si en «estudios» elegiste «Ingenieria» y tienes las marcas «graduado» y «antecedentes»)_ **Sofía:** En la entrevista nos contaste lo de tu expediente de menores. Todo. Te contratamos por cómo lo contaste.
  - _(si en «estudios» elegiste «Derecho» y tienes las marcas «graduado» y «antecedentes»)_ **Montse:** En la entrevista nos contaste lo de tu expediente de menores. Todo. Te contratamos por cómo lo contaste.
  - _(si en «estudios» elegiste «Economia» y tienes las marcas «graduado» y «antecedentes»)_ **Ignacio:** En la entrevista nos contaste lo de tu expediente de menores. Todo. Te contratamos por cómo lo contaste.
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Adu01_Firma»** _(música: → Intima → Resolucion)_
    - _En escena:_ Doctora Nuria, Sofía, Montse, Ignacio, Chef Lola, Paco, Ernesto
    - _Cámara:_ 1 planos (Inserto)
    - 🪧 _Rótulo:_ «📝 Contrato indefinido» — Tu primer trabajo de verdad
    - **Tú:** [tu nombre]. Mi nombre. En un contrato de verdad. _[plano PrimerPlano de Tú · silencio 2.4 s]_
    - **Tú:** Sin «de prácticas». Sin «de verano». Mío. _[en la pausa: Respirar]_
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Firmado. Bienvenido/a al equipo. Ahora corre, que la sala tres no se cura sola. _[plano PrimerPlano de Doctora Nuria · ademán Point · silencio 0.6 s]_
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Sofía:** ¡Oficial! Te enseño tu mesa. Tiene un cajón que no cierra. Es tradición. _[plano PrimerPlano de Sofía · gesto Happy · silencio 0.6 s]_
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Montse:** Bienvenido/a al bufete. Despacio y bien: así se trabaja aquí. _[plano PrimerPlano de Montse · ademán Nod · silencio 0.6 s]_
    - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Ignacio:** Tres firmas, cero errores. Empiezas mejor que yo. _[plano PrimerPlano de Ignacio · ademán Clap · silencio 0.6 s]_
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Chef Lola:** ¡Encargado/a! ¡Ay, que me emociono! …¡A la barra, que hay cola! _[plano PrimerPlano de Chef Lola · gesto Happy · silencio 0.6 s]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Paco:** Encargado/a. …Bien. _[plano PrimerPlano de Paco · ademán Nod · silencio 0.6 s]_
    - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Ernesto:** Jefe/a de ruta. Ya te sabes las calles. Ahora te sabrás los nombres de los perros. _[plano PrimerPlano de Ernesto · ademán WaveLite · silencio 0.6 s]_
- **Paso 10 · Clase** — «Tu primer día como profesional» _(solo si tienes la marca «graduado»)_
- **Paso 11 · Escena** _(solo si tienes la marca «graduado»)_
  - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Tu primer paciente sin supervisión directa. Estaré en la sala de al lado. Confío en ti.
  - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Sofía:** La pasarela del río. ¿Te acuerdas? El ayuntamiento ha aprobado tu idea de los amortiguadores. Ahora hay que construirla.
  - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Montse:** Tu primer cliente propio: el vecino de la multa. Ha vuelto. Otra multa. Dice que solo confía en ti.
  - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Ignacio:** Marcos ha abierto la tienda de bicis de la playa. Va bien. Quiere otra. Tu primer cliente propio.
  - ❓ **Pregunta al jugador:** ¿Cómo lo afrontas?
    - ➤ «Pido consejo cuando dudo: preguntar no es de novatos» _(efecto: responsabilidad +1; decisión «primer caso» = Consejo)_
      - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Bien preguntado. …Y esa también, bien preguntada. Caso resuelto antes de comer.
      - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Sofía:** Bien preguntado. …Y esa también, bien preguntada. Caso resuelto antes de comer.
      - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Montse:** Bien preguntado. …Y esa también, bien preguntada. Caso resuelto antes de comer.
      - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Ignacio:** Bien preguntado. …Y esa también, bien preguntada. Caso resuelto antes de comer.
    - ➤ «Me lanzo: sé más de lo que creo» _(efecto: valentia +1; decisión «primer caso» = Lanzarse)_
      - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Casi todo bien. Lo que no, lo has arreglado por la tarde. Hoy has aprendido más que en un semestre.
      - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»)_ **Sofía:** Casi todo bien. Lo que no, lo has arreglado por la tarde. Hoy has aprendido más que en un semestre.
      - _(si en «estudios» elegiste «Derecho» y tienes la marca «graduado»)_ **Montse:** Casi todo bien. Lo que no, lo has arreglado por la tarde. Hoy has aprendido más que en un semestre.
      - _(si en «estudios» elegiste «Economia» y tienes la marca «graduado»)_ **Ignacio:** Casi todo bien. Lo que no, lo has arreglado por la tarde. Hoy has aprendido más que en un semestre.
- **Paso 12 · Acción del jugador** — «Primer turno de encargado/a (0/3)» _(solo si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_
  - _Lugar:_ la Cafetería Central
- **Paso 13 · Acción del jugador** — «Primer turno de encargado/a (0/3)» _(solo si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_
  - _Lugar:_ el supermercado
- **Paso 14 · Acción del jugador** — «Primer turno de jefe/a de ruta (0/3)» _(solo si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_
  - _Lugar:_ Correos
- **Paso 15 · Cinemática** _(solo si NO tienes la marca «graduado»)_
  - _Lugar:_ [lugarpracticas de tu carrera]
  - 🎬 **Cinemática «Adu01_PrimerTurno»** _(música: → Resolucion)_
    - _En escena:_ Chef Lola, Omar, Paco, Ernesto · _entran andando:_ Omar · _salen:_ Omar
    - _Cámara:_ 1 planos (General)
    - 🪧 _Rótulo:_ «Primer turno al mando» — Nadie ve lo difícil que es. Salvo tú.
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Omar:** ¡Encargado/a! ¡Ya puedo decir que mi jefe es mi amigo! …Espera. Eso no es bueno para mí. _[plano PrimerPlano de Omar · gesto Happy · silencio 3.0 s]_
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Omar:** Te he guardado la última croqueta. Bueno, media. La otra media era control de calidad. _[plano DosPlanos de Omar → Tú]_
    - _(si en «empleo» elegiste «Barista» y tienes la marca «buen trabajo» y NO tienes la marca «graduado»)_ **Chef Lola:** Aquel verano tiraste una bandeja entera y viniste a decírmelo. Por eso estás hoy aquí. _[plano PrimerPlano de Chef Lola]_
    - _(si en «empleo» elegiste «Barista» y tienes la marca «mentiste entrevista» y NO tienes la marca «graduado»)_ **Chef Lola:** Y hoy, sin inventarte experiencia. Que se note la diferencia, ¿eh? _[gesto HandsOnHips]_
    - _(si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_ **Chef Lola:** Turno cerrado. Ni un plato roto. …Bueno, uno. Pero era feo. _[plano PrimerPlano de Chef Lola · ademán Nod · en la pausa: Mirar]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Paco:** Hmm. Pasillo tres: perfecto. Pasillo cuatro: perfecto. _[plano PrimerPlano de Paco · silencio 3.0 s]_
    - _(si en «empleo» elegiste «Reponedor» y tienes la marca «buen trabajo» y NO tienes la marca «graduado»)_ **Paco:** Treinta latas por el suelo aquel verano, y me lo dijiste tú. Por eso firmé.
    - _(si en «empleo» elegiste «Reponedor» y tienes la marca «mentiste entrevista» y NO tienes la marca «graduado»)_ **Paco:** La próxima entrevista la haces tú. Sin mentir. Lo sé todo, ¿eh? _[gesto Angry]_
    - _(si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_ **Paco:** …Bien. Muy bien, incluso. _[plano PrimerPlano de Paco · ademán Nod · en la pausa: Mirar · silencio 1.2 s]_
    - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Ernesto:** Ruta completa. Ni una carta perdida. Y el perro del 14 te ha movido la cola. Eso no lo consigo ni yo. _[plano PrimerPlano de Ernesto · gesto Happy · silencio 3.0 s]_
    - _(si en «empleo» elegiste «Repartidor» y tienes la marca «buen trabajo» y NO tienes la marca «graduado»)_ **Ernesto:** Discreción, puntualidad y ni una queja. Lo de aquel verano no fue suerte.
    - _(si en «empleo» elegiste «Repartidor» y tienes la marca «mentiste entrevista» y NO tienes la marca «graduado»)_ **Ernesto:** Y esta vez sin decir que tenías «muchísima experiencia». Mejor así.
    - _(si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_ **Ernesto:** Mañana a las siete. Quien lleva la ruta no duerme. Bueno, duerme poco. _[plano DosPlanos de Ernesto → Tú · ademán Point]_
- **Paso 16 · Transición (pasa el tiempo)** — «Final de mes…»
  - ⏳ _Pantalla de transición:_ «Final de mes…»
- **Paso 17 · Cinemática**
  - 🎬 **Cinemática «Adu01_Buzon»** _(música: → Nada)_
    - _Cámara:_ 1 planos (Medio)
    - **Tú:** Primer sueldo completo. Entero. Mío. _[gesto Happy · silencio 2.2 s]_
    - _(si NO tienes la marca «graduado»)_ **Tú:** La casa todavía huele a pintura… y ya tiene correo.
    - **Tú:** …Tres sobres. Alquiler. Luz. Agua. _[plano Inserto de Tú · en la pausa: Suelo]_
    - **Tú:** Nadie me avisó de que ser adulto/a venía con buzón. _[plano PrimerPlano de Tú · ademán Shrug]_
- **Paso 18 · Escena**
  - ❓ **Pregunta al jugador:** ¿Qué haces con las facturas?
    - ➤ «Pagarlas ya, todas» _(efecto: responsabilidad +1; decisión «facturas» = Pagar)_
      - **Tú:** Pagado. El sueldo ha adelgazado bastante. Pero esta noche duermo tranquilo/a.
    - ➤ «Dejarlas para la semana que viene» _(efecto: decisión «facturas» = Luego; marca «factura pendiente»)_
      - **Tú:** Las dejo en la mesa. Encima, una planta. Así no se ven. Problema resuelto. Seguro.
    - ➤ «Hacer un presupuesto: ¿cuánto entra y cuánto sale?» _(efecto: curiosidad +1; decisión «facturas» = Presupuesto)_
      - **Tú:** Mejor pido ayuda. En el banco está Ignacio, el de los números.
- **Paso 19 · Ir a** el Banco Valmar — «Ve al banco: Ignacio te ayuda a hacer tu primer presupuesto» _(solo si en «facturas» elegiste «Presupuesto»)_
  - _Lugar:_ el Banco Valmar · _En escena:_ Ignacio
- **Paso 20 · Escena** _(solo si en «facturas» elegiste «Presupuesto»)_
  - **Ignacio:** ¡La persona de los números! Siéntate. Regla sencilla: la mitad para vivir, un tercio para lo que te guste y el resto, a ahorrar.
  - **Ignacio:** Las facturas, primero. Lo que queda, tuyo. Y un colchón para imprevistos, que siempre llegan.
  - **Ignacio:** Mira: una hoja de colores. Facturas pagadas y hasta sobra para ahorrar. Los números, cuando se ordenan, son preciosos.
- **Paso 21 · Escena**
  - **Mamá/Papá:** (al teléfono) ¿Qué tal el primer mes? ¿Has comido bien? ¿Has pagado las facturas? Perdona. No lo puedo evitar.
  - **Mamá/Papá:** Oye… Abu no está muy bien. Nada grave, creo. Pero te echa de menos. Pásate cuando puedas, ¿vale?

**Al terminar (momento de la biografía):** «Tu primer contrato»

---

### Adu02_Atardecer · «Un atardecer junto al mar»

**Resumen:** Tu abu se ha caído. No es grave, pero tiene un deseo: ver el mar otra vez. Contigo.

_Tipo: Historia · Familia · Edad: 23-24 años · Duración: 20-30 min_

**Requisitos:** has terminado «Mi primer contrato»

**Lo que puede cambiar:** Coche o autobús · Lo que le prometes a Abu

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Un sábado por la mañana, suena el teléfono.»
  - ⏳ _Pantalla de transición:_ «Un sábado por la mañana, suena el teléfono.»
- **Paso 2 · Escena**
  - **Mamá/Papá:** (al teléfono) No te asustes, ¿vale? Abu se ha caído en la escalera. Está bien. En el hospital, para que le miren.
  - **Mamá/Papá:** Pregunta por ti. Bueno, pregunta por ti y por si alguien le ha regado la planta.
- **Paso 3 · Ir a** el hospital — «Ve al hospital: Abu está allí»
  - _Lugar:_ el hospital · _En escena:_ Abu, Doctora Nuria, Mamá/Papá
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Adu02_Hospital»** _(música: → Intima)_
    - _En escena:_ Abu, Doctora Nuria, Mamá/Papá
    - _Cámara:_ 1 planos (General)
    - **Mamá/Papá:** ¡Aquí! Está bien. Está bien, ¿eh? Lo primero que ha preguntado al despertar es por la planta. _[plano PrimerPlano de Mamá/Papá · silencio 2.8 s]_
    - _(si tienes la marca «ascendido»)_ **Mamá/Papá:** Y por tu ascenso. Se lo ha contado a toda la planta. A la de las camas, no a la del salón.
    - _(si tienes la marca «despedido»)_ **Mamá/Papá:** No le he contado lo del trabajo. Hoy no. _[en la pausa: Apartar]_
    - **Doctora Nuria:** Un golpe y un buen susto. Ahora mismo está mejor que yo después de una guardia. _[plano Medio de Doctora Nuria · ademán Nod · en la pausa: Mirar]_
    - **Abu:** ¿Ya habéis terminado de hablar de mí como si no estuviera? Ven aquí, que de pie me mareas. _[plano PrimerPlano de Abu · silencio 0.8 s]_
- **Paso 5 · Hablar** con Abu — «Siéntate con Abu»
  - _(si NO tienes la marca «graduado»)_ **Doctora Nuria:** Tranquilidad: nada roto. Un golpe y un buen susto. Unos días de descanso y como nuevo.
  - _(si en «estudios» elegiste «Medicina» y tienes la marca «graduado»)_ **Doctora Nuria:** Tranquilidad, colega: nada roto. Ya lo sabías, ¿verdad? Has mirado la placa antes que yo.
  - _(si tienes la marca «graduado» y en «estudios» NO elegiste «Medicina»)_ **Doctora Nuria:** Tranquilidad: nada roto. Un golpe y un buen susto. Unos días de descanso y como nuevo.
  - **Abu:** Mírate. Con tu trabajo, tu casa… Y yo aquí, con una bata que no cierra por detrás. Qué vergüenza.
  - _(si tienes el recuerdo «primer dia uni»)_ **Abu:** ¿Llevas el reloj? …Lo llevas. Bien.
  - **Abu:** Oye, tengo que pedirte una cosa.
  - **Abu:** Cuando era joven, iba cada domingo a ver el mar a Playa Dorada. En autobús. Hace años que no voy. Me gustaría verlo otra vez. Contigo.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «En cuanto salgas de aquí, vamos. Te lo prometo.» _(efecto: Abu +8)_
      - **Abu:** Trato hecho. Y no me lleves corriendo, que ya no estoy para sustos.
    - ➤ «Le coges la mano sin decir nada» _(efecto: Abu +10; empatia +1)_
      - **Abu:** Ya. Ya lo sé. Tú siempre has dicho las cosas así. _[gesto Happy · en la pausa: Mira]_
- **Paso 6 · Decisión** — «¿Cómo vas a llevar a Abu a ver el mar?»
  - ➤ **Opción «Me saco el carnet y le llevo en coche»** _(efecto: decisión «viaje abu» = Coche; valentia +1)_
  - ➤ **Opción «En autobús, como hacía Abu de joven»** _(efecto: decisión «viaje abu» = Bus; empatia +1)_
- **Paso 7 · Acción del jugador** — «Sácate el carnet de coche en la autoescuela» _(solo si en «viaje abu» elegiste «Coche»)_
  - _Lugar:_ Autoescuela
  - ⏰ _Si tardas, Mamá/Papá dice:_ «(mensaje) Abu pregunta cada día si ya tienes el carnet. Dice que conduces seguro mejor que yo.»
- **Paso 8 · Escena** _(solo si en «viaje abu» elegiste «Coche»)_
  - _Lugar:_ Aquí · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Carnet nuevo! Toma las llaves del coche viejo. Tiene más años que tú. Trátalo con cariño, que hace ruidos raros.
  - **Abu:** Despacio, ¿eh? Y con las dos manos en el volante. Y sin música alta. Bueno, un poquito de música.
- **Paso 9 · Escena** _(solo si en «viaje abu» elegiste «Bus»)_
  - _Lugar:_ la parada del autobús · _En escena:_ Abu
  - **Abu:** El autobús de Playa Dorada. Hace cincuenta años lo cogía con mis amigos. Íbamos cantando. El conductor nos odiaba.
- **Paso 10 · Ir a** la parada del autobús — «Recoge a Abu en la parada del autobús» _(solo si en «viaje abu» elegiste «Bus»)_
- **Paso 11 · Acción del jugador** — «Coge el autobús a Playa Dorada con Abu» _(solo si en «viaje abu» elegiste «Bus»)_
  - _En escena:_ Abu (te acompaña)
- **Paso 12 · Ir a** Playa Dorada — «Llega a la playa con Abu»
  - _Lugar:_ Playa Dorada
- **Paso 13 · Cinemática**
  - _En escena:_ Abu
  - 🎬 **Cinemática «Adu02_Orilla»** _(música: → Intima)_
    - _En escena:_ Abu
    - _Cámara:_ 1 planos (Pan)
    - **Abu:** Huele igual. Cincuenta años y huele igual. _[plano Lateral de Abu · silencio 3.4 s]_
    - **Tú:** ¿Te ayudo con los zapatos? _[plano Hombro de Tú → Abu]_
    - **Abu:** Puedo yo. …No puedo. Ayúdame. Pero no se lo cuentes a nadie. _[plano PrimerPlano de Abu · en la pausa: Suelo · silencio 0.6 s]_
    - _(si con tiempo Lluvia, Tormenta)_ **Abu:** Llueve sobre el mar. Da igual: el mar con lluvia también es el mar. _[en la pausa: Apartar]_
    - _(si en Invierno)_ **Tú:** Toma mi chaqueta.
    - _(si en Invierno)_ **Abu:** No tengo frío. …Bueno, déjamela. Pero no tengo frío. _[gesto Happy]_
    - **Abu:** Cierra los ojos. Respira conmigo. ¿Lo oyes? Eso no lo venden en ningún sitio. _[plano PPP de Abu · en la pausa: Respirar · silencio 1.2 s]_
- **Paso 14 · Escena**
  - **Abu:** Aquí conocí a la persona más importante de mi vida. Y aquí vine el día que naciste, a contárselo al mar.
  - **Abu:** ¿Sabes qué le dije? «Hoy ha nacido alguien que va a hacer cosas bonitas». Y mira. No me equivoqué.
  - _(si tienes el recuerdo «primer dia cole»)_ **Abu:** Me acuerdo de tu primer día de colegio. Te agarrabas a mi mano como si te fueras a otro planeta.
  - _(si tienes el recuerdo «graduacion»)_ **Abu:** Y de tu graduación. Lloré tanto que se me empañaron las gafas y no vi el diploma. No se lo digas a nadie.
- **Paso 15 · Usar** — «Coge una concha para Abu»
  - 🖐 _Al usar «Una concha en la arena»:_
    - **Tú:** Mira, abu. Una concha blanca. Perfecta. Para ti.
    - **Abu:** No, no. Esta es para ti. Para que vuelvas aquí. Con quien tú quieras.
- **Paso 16 · Escena**
  - **Abu:** Prométeme una cosa, cariño.
  - ❓ **Pregunta al jugador:** ¿Qué le prometes?
    - ➤ «Volveré aquí cada año. Contigo o por ti.» _(efecto: Abu +6; decisión «promesa abu» = Volver)_
      - **Abu:** Cada año. Me vale. Y si un año no puedo venir, tráeme una foto.
    - ➤ «Haré cosas bonitas. Como dijiste.» _(efecto: valentia +1; decisión «promesa abu» = CosasBonitas)_
      - **Abu:** Ya las haces. Pero haz más. Muchas. Y que se note que eres feliz haciéndolas.
    - ➤ «Cuidaré de la familia como tú cuidaste de mí.» _(efecto: Mamá/Papá +5; responsabilidad +1; decisión «promesa abu» = Familia)_
      - **Abu:** Eso ya lo sé. Lo sé desde que me diste la mitad de tu bocadillo con cinco años.
- **Paso 17 · Cinemática**
  - 🎬 **Cinemática «Adu02_Atardecer»** _(vuelo de cámara, 11 s, 3 planos; música: TemaValmar efecto Momento)_
    - 🪧 _Rótulo:_ «🌅 El mar» — Con tu abu, como cuando era joven

**Al terminar (momento de la biografía):** «El atardecer con Abu»

---

### Adu03_Reencuentro · «El reencuentro»

**Resumen:** Lola se jubila y le deja la cafetería a Omar. Omar quiere a todo el grupo en la inauguración. A TODO el grupo.

_Tipo: Historia · Amistad · Edad: 24-25 años · Duración: 25-35 min_

**Requisitos:** has terminado «Un atardecer junto al mar»

**Lo que puede cambiar:** A quién invitas primero · Lo que le cuentas a Lucía · La promesa nueva del banco

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Unos meses después…»
  - ⏳ _Pantalla de transición:_ «Unos meses después…»
- **Paso 2 · Ir a** la Cafetería Central — «Omar te ha escrito: «VEN YA. NOTICIÓN.»»
  - _Lugar:_ la Cafetería Central · _En escena:_ Omar, Chef Lola
- **Paso 3 · Escena**
  - **Chef Lola:** Me jubilo. Cuarenta años detrás de esta barra. Ya está. Me voy a la playa a no hacer nada. Lo he decidido.
  - **Omar:** Y… me la deja a mí. ¡A MÍ! La cafetería. Se va a llamar «La Cafetería de Omar». Bueno, se llama igual, pero con mi nombre.
  - **Omar:** Reabro el sábado. Y quiero a todo el grupo. A TODO. Como en el colegio. Y tú te encargas de invitarles.
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Primero, la mejor ayuda de verano. Ahora, quien mejor me sucede. Qué bien lo he hecho todo.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Invita al grupo a la inauguración (al menos tres)»
  - _Lugar:_ el Estadio Altamar · _En escena:_ Nico, Sara, Bruno, Leire (si tienes la marca «conoces a leire»), Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 4.1 · Hablar** con Nico — «Nico (estadio de Altamar)»
    - **Nico:** ¡[tu nombre]! ¡Mira, uniforme del primer equipo! Firmé el mes pasado. Jugador de Altamar. Profesional. Todavía no me lo creo.
    - **Nico:** ¿Omar abre la cafetería? ¡Voy! Llevo diez bocadillos de deuda con él desde el instituto. Es el momento de pagar.
    - _(si en «capsula» elegiste «Prediccion»)_ **Nico:** Y oye… lo de tu predicción de la cápsula del tiempo. «Nico será futbolista». La tengo enmarcada.
  - **Paso 4.2 · Hablar** con Sara — «Sara (universidad)»
    - **Sara:** ¡[tu nombre]! Tengo una noticia científica. He descubierto una especie nueva de hongo. Le han puesto mi nombre. «Mycena sarae». Es diminuto. Es precioso.
    - **Sara:** ¿La inauguración de Omar? Iré. Llevaré a mi hongo. En un tarro. Es muy tranquilo.
  - **Paso 4.3 · Hablar** con Bruno — «Bruno (comisaría)»
    - **Bruno:** Agente Bruno, para servirle. …Sí, soy policía. Inés me enseñó todo. Me paso el día ayudando a gente mayor a cruzar y buscando gatos.
    - _(si tienes la marca «detenido»)_ **Bruno:** Hace un tiempo te puse las esposas. Y hoy me invitas a una fiesta. La vida es muy rara. Me alegro de que sea así.
    - _(si en «adios bruno» NO elegiste «DeCero»)_ **Bruno:** ¿Me invitas tú? ¿Después de todo lo del colegio? …Vale. Iré. Gracias. De verdad.
    - _(si en «adios bruno» elegiste «DeCero»)_ **Bruno:** ¿Una fiesta del grupo? Claro que voy. Empezamos de cero, ¿no? Pues esto es el diez.
  - **Paso 4.4 · Hablar** con Leire — «Leire (el cine)» _(solo si tienes la marca «conoces a leire»)_
    - **Leire:** Estreno mi primer documental el mes que viene. Es sobre Valmar. Salís todos. Sin permiso. Lo siento. Bueno, no lo siento.
    - **Leire:** ¿La cafetería de Omar? Allí estaré. Con la cámara de mi abuelo. Como siempre.
  - **Paso 4.5 · Hablar** con Hugo — «Hugo (biblioteca del campus)» _(solo si tienes la marca «hugo con el grupo»)_
    - **Hugo:** Mira: mi primera novela. «La isla de las mil llaves: la venganza». Es de piratas. Obviamente. Te la dedico en la primera página.
    - **Hugo:** «Para quien encontró mi libro en un almacén y me sacó de donde no quería estar.» …Ya. Me emociono yo solo.
  - **Paso 4.6 · Hablar** con Mateo — «Mateo (oficinas del distrito financiero)» _(solo si tienes la marca «ayudaste a mateo»)_
    - _(si en «estudios» elegiste «Ingenieria»)_ **Mateo:** Ingeniero en TecnoVal. Estoy en el proyecto de la pasarela del río. ¿Tu idea de los amortiguadores? Funciona. Ya no vibra.
    - _(si en «estudios» NO elegiste «Ingenieria»)_ **Mateo:** Ingeniero en TecnoVal. Diseño puentes. Mi padre dice que soy el fontanero más caro de la historia.
    - **Mateo:** La fiesta de Omar… Claro que voy. Aquel primer día me ayudaste con los libros. Todo empezó ahí.
- **Paso 5 · Ir a** el colegio — «Invita también a Lucía: ahora es la directora del colegio»
  - _Lugar:_ el colegio · _En escena:_ Profe Lucía
- **Paso 6 · Hablar** con Profe Lucía — «Habla con Lucía»
  - **Profe Lucía:** ¡[tu nombre]! Ahora soy la directora. Sí, la de las coletas. Tengo despacho y todo. Y la foto de 1998 en la pared.
  - **Profe Lucía:** Cuéntame: ¿qué ha sido de tu vida?
  - _(si en «estudios» elegiste «Medicina» y en «sueno infancia» elegiste «Medicina» y tienes la marca «graduado»)_ _Narrador:_ _Le cuentas que querías salvar vidas… y que ahora trabajas en el hospital. Lucía se queda callada un momento._
  - _(si en «estudios» elegiste «Ingenieria» y en «sueno infancia» elegiste «Ingenieria» y tienes la marca «graduado»)_ _Narrador:_ _Le cuentas que querías inventar cosas que no existen… y que ahora las diseñas en TecnoVal. Lucía sonríe._
  - _(si en «estudios» elegiste «Derecho» y en «sueno infancia» elegiste «Derecho» y tienes la marca «graduado»)_ _Narrador:_ _Le cuentas que querías defender a quien no puede defenderse… y que ahora eres abogado/a._
  - _(si en «estudios» elegiste «Economia» y en «sueno infancia» elegiste «Economia» y tienes la marca «graduado»)_ _Narrador:_ _Le cuentas que querías tener tu propio negocio… y que ahora ayudas a otros a abrir el suyo._
  - _(si tienes la marca «graduado»)_ **Profe Lucía:** Lo dijiste a los diez años en un banco del parque. Y lo has cumplido. Eso, [tu nombre], es lo más bonito que puede oír una profesora.
  - **Profe Lucía:** Lo importante no es si se cumple lo que dijiste con diez años. Es si eres feliz con lo que has hecho. Y se te ve feliz.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Gracias por aquel primer día. Y por todos los demás.» _(efecto: Profe Lucía +10)_
      - **Profe Lucía:** Venga, que me haces llorar en la puerta del colegio. Y aquí me ven los alumnos.
    - ➤ «¿Puedo venir a contarle a tus alumnos lo que hago?» _(efecto: Profe Lucía +8; marca «charla colegio»)_
      - **Profe Lucía:** ¡Me encantaría! El día de las profesiones. Como el que tuviste tú en el instituto, pero con niños que preguntan «¿y por qué?» cada minuto.
  - **Profe Lucía:** ¿Y la fiesta de Omar? Claro que voy. Ese niño se comía mi bocadillo de la mesa cuando no miraba.
- **Paso 7 · Ir a** la Cafetería Central — «Vuelve a la cafetería: Omar necesita ayuda en la cocina»
  - _Lugar:_ la Cafetería Central · _En escena:_ Omar, Chef Lola
- **Paso 8 · Minijuego** — «La tortilla perfecta»
  - 🎮 _Cómo se juega:_ Dale la vuelta en el momento justo
- **Paso 9 · Escena**
  - _En escena:_ Omar, Chef Lola, Nico, Sara, Bruno, Leire (si tienes la marca «conoces a leire»), Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Profe Lucía, Mamá/Papá
  - **Chef Lola:** Mirad esto. Llena. Todos. Como en el patio del colegio, pero más altos.
  - **Chef Lola:** Unas palabras, que me lo ha pedido Omar. Cuarenta años aquí. He visto crecer a medio Valmar. Y a este grupo, entero.
  - **Chef Lola:** Omar: cuida la cafetería. Y cuida a esta gente. Que la gente es lo único que no se puede comprar con la caja registradora.
  - _(si tienes la marca «tortilla perfecta»)_ **Omar:** La tortilla de hoy la ha hecho [tu nombre]. Perfecta. Bueno, casi. Perfecta según mis estándares, que son altísimos.
  - _(si NO tienes la marca «tortilla perfecta»)_ **Omar:** La tortilla de hoy la ha hecho [tu nombre]. Se le ha roto un poco. Nadie lo va a notar. Todos lo vais a notar.
  - **Omar:** Y yo quiero decir… que sin vosotros no habría abierto nada. Ni la cafetería ni el bocadillo del primer día. Gracias. Ya está. No lloro. Es la cebolla.
  - **Sara:** Técnicamente, hoy no hay cebolla en el menú.
- **Paso 10 · Cinemática**
  - 🎬 **Cinemática «Adu03_Foto»** _(vuelo de cámara, 7 s, 1 planos; música: efecto Momento)_
    - 🪧 _Rótulo:_ «📸 Todos otra vez» — La Cafetería de Omar
- **Paso 11 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 12 · Ir a** el parque — «Ve al banco del parque: el grupo te espera»
  - _Lugar:_ el parque · _En escena:_ Omar, Nico, Sara, Leire (si tienes la marca «conoces a leire»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 13 · Cinemática**
  - 🎬 **Cinemática «Adu03_Banco»** _(música: → Intima)_
    - _En escena:_ Omar, Nico, Sara, Leire, Mateo, Hugo
    - _Cámara:_ 1 planos (General)
    - **Nico:** ¡Por fin! Te hemos guardado sitio. Bueno, medio sitio. _[plano PrimerPlano de Nico · gesto Happy · silencio 3.2 s]_
    - **Omar:** Apretaos. A los diez años cabíamos todos y sobraba bocadillo. _[plano DosPlanos de Omar → Nico]_
    - **Sara:** Técnicamente, hemos crecido un cuarenta por ciento. El banco, un cero. _[plano Reaccion de Sara]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Quietos. No os mováis. Esta toma es buena. _[ademán Point]_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo me siento en el borde. Como el primer día. Ahí no se me caen las cosas.
    - _(si tienes la marca «despedido»)_ **Nico:** Y lo del trabajo… que te den. Bueno, que te den otro. Uno mejor. _[en la pausa: Mirar]_
    - _(si tienes la marca «ascendido» y NO tienes la marca «despedido»)_ **Omar:** ¡Y con ascenso! Hoy invitas tú. Mañana también. _[gesto Happy]_
    - _(si tienes el recuerdo «atardecer con abu»)_ **Sara:** ¿Y tu abu? ¿Fuisteis al final a ver el mar? _[plano PrimerPlano de Sara]_
    - _(si tienes el recuerdo «atardecer con abu»)_ **Tú:** Fuimos. Y le prometí volver. _[plano PrimerPlano de Tú · en la pausa: Apartar]_
- **Paso 14 · Escena**
  - _(si en «promesa» elegiste «Banco»)_ **Nico:** Prometimos quedar aquí cada verano. Y lo hemos cumplido. Casi siempre. Vale, algunos veranos no.
  - _(si en «promesa» elegiste «Juntos»)_ **Omar:** Prometimos seguir juntos pasara lo que pasara. Y aquí estamos. Con trabajos, con casas… y juntos.
  - _(si en «promesa» elegiste «Nuevos»)_ **Sara:** Prometimos conocer gente nueva sin olvidarnos. Técnicamente, lo hemos cumplido al cien por cien.
  - _(si tienes el recuerdo «primer grupo»)_ **Nico:** ¿Os acordáis del nombre del grupo? A la de tres. Una, dos… ¡«[nombre de tu grupo]»!
  - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Lo hemos dicho todos a la vez. Estadísticamente, eso es amistad.
  - ❓ **Pregunta al jugador:** ¿Qué promesa nueva hacéis?
    - ➤ «Cuando tengamos hijos, que sean amigos como nosotros.» _(efecto: decisión «promesa adulta» = Hijos)_
      - **Omar:** Y que se sienten en este banco. Y que tampoco quepan.
    - ➤ «Un viaje juntos, todos, antes de los treinta.» _(efecto: decisión «promesa adulta» = Viaje)_
      - **Sara:** Propongo Villaverde. La granja. Donde se perdió Mateo. Por nostalgia científica.
    - ➤ «Nada de promesas: esto ya es para siempre.» _(efecto: empatia +1; decisión «promesa adulta» = Siempre)_
      - **Nico:** …Eso ha sido muy bonito. Que nadie diga nada. Que nadie diga NADA.
- **Paso 15 · Transición (pasa el tiempo)** — «Os quedáis hasta tarde. Hablando de todo y de nada. Como siempre. Como nunca.»
  - ⏳ _Pantalla de transición:_ «Os quedáis hasta tarde. Hablando de todo y de nada. Como siempre. Como nunca.» _(pasas a la etapa Adulto)_
  - 🎬 **Montaje / cinemática de transición «Montaje_Joven_Adulto»** _(música: → Intima VidaAdulta PasanLosAnos; montaje de cambio de etapa AdultoJoven → Adulto)_
    - _En escena:_ Omar, Nico, Sara, Profe Lucía, Alba, Darío, Abu, Mamá/Papá, Profesora Beltrán, Julia, Iván, Ernesto, Chef Lola, Bruno, Leire, Mateo, Hugo · _entran andando:_ Alba, Darío
    - _Cámara:_ 11 planos (DosPlanos)
    - 🪧 _Rótulo:_ «Los Pinos, años después» — El colegio sigue abriendo cada septiembre
    - _(si en «promesa adulta» elegiste «Hijos»)_ 🪧 _Rótulo:_ «Los Pinos, años después» — Algún día, vuestros hijos entrarán por esa puerta
    - _(si tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El mar, con tu abu» — Como cuando era joven
    - _(si en «promesa abu» elegiste «Volver» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El mar, con tu abu» — Le prometiste volver cada año
    - _(si en «promesa abu» elegiste «CosasBonitas» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El mar, con tu abu» — Le prometiste hacer cosas bonitas
    - _(si en «promesa abu» elegiste «Familia» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El mar, con tu abu» — Le prometiste cuidar de la familia
    - _(si NO tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «Tu familia» — El nido sigue ahí cuando vuelves
    - _(si tienes el recuerdo «graduacion»)_ 🪧 _Rótulo:_ «Tu graduación» — Beltrán casi sonrió. Casi.
    - _(si tienes el recuerdo «primer contrato» y NO tienes el recuerdo «graduacion»)_ 🪧 _Rótulo:_ «Tu primer contrato» — Un lunes cualquiera… que no era cualquiera
    - _(si NO tienes los recuerdos «graduacion» y «primer contrato»)_ 🪧 _Rótulo:_ «Tus primeros trabajos» — Lola decía que eras «la mejor ayuda de verano»
    - 🪧 _Rótulo:_ «La Cafetería de Omar» — Todos otra vez
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ 🪧 _Rótulo:_ ««Los Imparables»» — Todos otra vez, en la Cafetería de Omar
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ 🪧 _Rótulo:_ ««La Patrulla Valmar»» — Todos otra vez, en la Cafetería de Omar
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ 🪧 _Rótulo:_ ««Los del Banco Azul»» — Todos otra vez, en la Cafetería de Omar
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ 🪧 _Rótulo:_ ««Los Dinosaurios»» — Todos otra vez, en la Cafetería de Omar
    - 🪧 _Rótulo:_ «Años después» — Tu vida es tuya
    - **Omar:** Diez años, y ya no cabíamos. Ahora ni con calzador.
    - _(si en «promesa adulta» elegiste «Hijos»)_ **Sara:** Hijos que sean amigos. Estadísticamente improbable. Lo vamos a conseguir.
    - _(si en «promesa adulta» elegiste «Siempre»)_ **Nico:** Para siempre. Lo has dicho tú. Ya no hay vuelta atrás.
    - _(si en «promesa adulta» elegiste «Viaje»)_ **Nico:** ¿Villaverde, entonces? Yo llevo el balón. Sara, la ciencia.
    - _(si NO se cumple: en «promesa adulta» elegiste «Hijos»)_ **Sara:** Esto, de mayores, también va a ser así. Lo sé. Tengo datos.
    - _(si en «promesa abu» elegiste «Volver» y tienes el recuerdo «atardecer con abu»)_ **Abu:** Cada año. Me vale.
    - **Profe Lucía:** ¡Buenos días! Pasad, pasad. …Hace años que digo lo mismo, y me sigue gustando.

**Al terminar (momento de la biografía):** «El reencuentro del grupo»

---

**Texto de cierre del capítulo:** «Has volado del nido. Y el nido sigue ahí cuando vuelves.»

- 🎬 **Final del capítulo (cinemática) «Nido_Fin»** _(vuelo de cámara, 7 s, 1 planos; música: TemaValmar)_
  - 🪧 _Rótulo:_ «Volar del nido» — Fin del capítulo
  - 🪧 _Rótulo:_ «Has volado del nido. Y el nido sigue ahí cuando vuelves.» — Próximamente: Tu vida

# Saga de la Grieta · Acto III

> Misiones canónicas de la saga (adulto joven: en paralelo a la universidad / «Volar del nido»). Se ven siempre en el mapa hasta hacerlas.

### Saga_13_SinCosme · «Sin Cosme»

**Resumen:** El garaje de Cosme lleva meses cerrado. Pip limpia el polvo cada día «por si vuelve». Don Escamas ha adelgazado. Hay que traerle de vuelta.

_Tipo: Saga de la Grieta · Acto III (1/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «El garaje de Cosme. Cerrado. Pip te abre la puerta: «Por fin. Tenemos que hablar»»

**Requisitos:** has terminado «Graduación interdimensional» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Hablar** con Pip — «Habla con Pip»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Pip, Don Escamas
  - **Pip:** Buenos días. Llevo cuatrocientos doce días limpiando el polvo del garaje. Por si vuelve. _[plano Medio de Pip · gesto Sad]_
  - **Pip:** Tiene que encontrarlo limpio. Si no, se queja. _[en la pausa: Baja]_
  - _(si tienes el recuerdo «graduacion interdimensional»)_ **Pip:** Desde su graduación, aquí no huele a batido de apio. Nunca pensé que lo echaría de menos.
  - **Don Escamas:** He calculado nuestras posibilidades de rescatarle sin ayuda: un 3 %. Con ayuda: un 4 %. _[plano Medio de Don Escamas]_
  - **Don Escamas:** Pero con amigos, las matemáticas cambian. _[silencio 0.6 s]_
  - _(si tienes el recuerdo «don escamas»)_ **Don Escamas:** Tú me sacaste de un estanque en un cubo. Ahora me toca a mí sacar a alguien. Aunque sea desde una pecera.
  - **Pip:** El señor dejó dicho que usted sabría qué hacer. Yo creo que lo dijo por decir. Pero aquí estamos.
  - _(si tienes la marca «ayudante oficial»)_ **Pip:** Además, usted es ayudante oficial. Lo pone la credencial. Eso le convierte en jefe en funciones. _[ademán Nod]_
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Busca en el garaje lo que dejó Cosme»
  - **Paso 2.1 · Usar** — «Su cuaderno»
    - 🖐 _Al usar «El cuaderno de Cosme»:_
      - _Narrador:_ _El cuaderno de Cosme, lleno de dibujos y coordenadas. En la última página, escrito deprisa: «Si me pasa algo:»._
      - _Narrador:_ _«1) G-4 (gatos): Bigotes sabe dónde está la 66-B. 2) La Capitana Ñoz tiene cámaras en todas las dimensiones»._
      - _Narrador:_ _«3) NO dejar que la criatura vaya sola»._ _[silencio 0.6 s]_
      - _Narrador:_ _Debajo, más pequeño: «Dile que estoy orgulloso. Por si acaso». Lo ha tachado. Pero se lee._ _[silencio 1.0 s]_
  - **Paso 2.2 · Usar** — «El mando del banco de trabajo»
    - 🖐 _Al usar «El prototipo de mando de rescate»:_
      - _Narrador:_ _Un mando de dimensiones a medio montar. Pip lo termina en diez minutos._
      - **Pip:** El señor lo dejó casi hecho. Siempre deja las cosas casi hechas. _[gesto Sad]_
- **Paso 3 · Hablar** con Candela — «Vuelve a la residencia: necesitas un equipo»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Candela:** Así que tu vecino inventor está secuestrado en otra dimensión por su gemelo malvado con perilla. _[plano Medio de Candela · gesto ThinkChin]_
  - **Candela:** Y hay que rescatarle. Vale. Lo apunto. _[silencio 0.6 s]_
  - **Iván:** ¿Otra dimensión? ¿Con portal y todo? ¡Voy! Llevo zumo. De mora. De día. _[a Candela · ademán Cheer]_
  - **Candela:** Iré. Pero con un plan plastificado. Nadie cruza un portal sin plan plastificado. Es la norma. _[a Iván]_
- **Paso 4 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Pip, Don Escamas, Iván, Candela
  - **Candela:** Plan: uno, la dimensión de los gatos. Dos, una capitana alienígena con cámaras. Tres, rescate. _[plano General · ademán Point]_
  - **Candela:** Cuatro, volver a tiempo para el examen de Beltrán. El punto cuatro no es negociable. _[a Iván · en la pausa: Mira]_
  - **Iván:** Yo me pido llevar el mando. …Vale, no. Yo me pido llevar la merienda. _[gesto Shrug]_
  - **Pip:** Iré con ustedes. El señor Cosme me dijo «no dejes a la criatura sola». _[plano Medio de Pip]_
  - **Pip:** Por una vez, voy a obedecer sin rechistar. _[ademán Nod · silencio 0.5 s]_
  - _Narrador:_ _Recibes 📓 el Cuaderno de Cosme. Es oficial: hay un equipo de rescate. Tres estudiantes, un robot y un pez en un cubo._

**Al terminar (momento de la biografía):** «Formaste el equipo de rescate»

---

### Saga_14_Bigotes · «El presidente Bigotes»

**Resumen:** Primera parada: la dimensión G-4, donde los gatos mandan. El presidente se llama Bigotes. Y dicen que te conoce.

_Tipo: Saga de la Grieta · Acto III (2/6) · Duración: 20-30 min_

**Cómo empieza:** al llegar a el parque. «Pip ha abierto un portal en el parque. Huele a pienso y a sofá. Es la dimensión de los gatos»

**Requisitos:** has terminado «Sin Cosme» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Cruzas el portal. En esta Valmar todo es igual… pero los gatos son del tamaño de personas y las personas llevan correa.»
  - ⏳ _Pantalla de transición:_ «Cruzas el portal. En esta Valmar todo es igual… pero los gatos son del tamaño de personas y las personas llevan correa.»
- **Paso 2 · Huida** — «¡La policía gatuna quiere ponerte correa! Llega al palacio presidencial (la plaza del centro)»
  - _Lugar:_ la Plaza Mayor · _En escena:_ Iván (te acompaña), Candela (te acompaña), Gato policía de Gatonia, Gata policía de Gatonia
  - 🚨 _Si te atrapan:_ «¡Correa reglamentaria! (Te la quitas mientras el gato se lame una pata. Vuelves al portal.)»
- **Paso 3 · Hablar** con Bigotes XVII — «Habla con el presidente Bigotes»
  - _En escena:_ Bigotes XVII, Iván, Candela
  - _(si has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Humano. Otra vez tú. Aquí soy presidente. En tu dimensión soy emperador exiliado. En todas soy el mejor. Es una constante universal.
  - _(si NO has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Humano. Tú eres del cole. Allí mi otro yo duerme en el patio y finge no hablar.
  - _(si NO has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Aquí soy presidente. En todas las dimensiones soy el mejor. Es una constante universal.
  - _(si tienes la marca «barriga bigotes»)_ **Bigotes XVII:** Me tocaste la barriga una vez. No lo he olvidado. Nunca lo olvidaré. _[gesto ArmsCrossed]_
  - _(si tienes la marca «duque de gatonia»)_ **Bigotes XVII:** Ah, el Duque/la Duquesa del Cojín. Siempre es un honor.
  - **Candela:** Señor presidente gato. Buscamos la dimensión 66-B. Tenemos un plan plastificado. _[a Bigotes XVII · plano Hombro de Candela → Bigotes XVII]_
  - **Bigotes XVII:** La 66-B. La dimensión de las perillas. _[en la pausa: Piensa]_
  - **Bigotes XVII:** Los gatos no vamos allí: allí nadie da de comer a los gatos. Es inhumano. Es ingatuno. _[gesto Angry]_
  - **Bigotes XVII:** Os daré sus coordenadas. Y un consejo: el doctor de la perilla tiene su laboratorio bajo vuestra universidad. _[plano Medio de Bigotes XVII]_
  - **Bigotes XVII:** Bajo tierra. Los malos siempre ponen el laboratorio debajo de algo. _[a Candela]_
  - **Iván:** Señor gato, ¿me puedo hacer una foto con usted?
  - **Bigotes XVII:** Una. Sin flash. De mi lado bueno. Todos mis lados son buenos.
  - **Bigotes XVII:** Y tomad: un collar diplomático. En cualquier dimensión con gatos, os abrirá puertas. Y latas.
  - _Narrador:_ _Recibes 🎀 el Collar diplomático de Gatonia. Primera pieza del rescate: las coordenadas._

**Al terminar (momento de la biografía):** «Pediste ayuda al presidente de los gatos»

---

### Saga_15_Reestreno · «Reestreno»

**Resumen:** Para entrar en la 66-B hace falta saber dónde está exactamente el laboratorio de Cósimo. Hay alguien que graba todas las dimensiones: la Capitana Ñoz. Y su nave vuelve esta noche al Monte del Silencio.

_Tipo: Saga de la Grieta · Acto III (3/6) · Duración: 20-30 min_

**Cómo empieza:** al llegar a El Monte del Silencio. «Una luz sobre el Monte del Silencio. La nave del reality ha vuelto»

**Requisitos:** has terminado «El presidente Bigotes» y entre las 21:00 y las 5:00 y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Hablar** con Capitana Ñoz — «La Capitana Ñoz baja de la nave»
  - _Lugar:_ El Monte del Silencio · _En escena:_ Capitana Ñoz, Blorp, Iván, Candela
  - _(si has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** ¡La estrella! ¡Mi terrícola favorito/a! Tu huida del monte fue nuestro episodio más visto. Trescientas galaxias lo repitieron. _[ademán Wave]_
  - _(si NO has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Terrícola. Me dicen que buscas algo. En mi nave hay cámaras en todas las dimensiones.
  - _(si NO has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Todo se graba. Todo. Hasta lo que no se debe.
  - **Capitana Ñoz:** ¿El laboratorio del de la perilla? Lo tengo. En alta definición. _[plano Medio de Capitana Ñoz · en la pausa: Sonrie]_
  - **Capitana Ñoz:** Pero en la tele nada es gratis, cariño. Quiero un episodio especial: «Terrícola rescata a su vecino loco». _[ademán Point]_
  - **Candela:** Nosotros también salimos. Y queremos ver el guion antes. Plastificado.
  - **Blorp:** ¡Blorp! ¡Yo hago de malo! ¡Siempre he querido hacer de malo! ¡Tengo una perilla de pega!
- **Paso 2 · Minijuego** — «Rodaje: ¡acción!»
  - _En escena:_ Capitana Ñoz, Zarg
  - 🎮 _Cómo se juega:_ Di tu frase justo cuando se enciende la luz roja
- **Paso 3 · Escena**
  - _En escena:_ Capitana Ñoz, Iván, Candela
  - _(si tienes la marca «buen rodaje»)_ **Capitana Ñoz:** ¡Corten! ¡Eres un talento natural! Bueno, natural no. Pero un talento. _[ademán Cheer]_
  - _(si NO se cumple: tienes la marca «buen rodaje»)_ **Capitana Ñoz:** ¡Corten! Se te ha trabado la frase cuatro veces. Da igual: la cámara te adora. _[gesto Laugh]_
  - **Capitana Ñoz:** Toma: la grabación del laboratorio del doctor Cósimo. _[silencio 0.5 s]_
  - _Narrador:_ _En la pantalla: un laboratorio enorme bajo la universidad de la Valmar malvada. Una cápsula de cristal._
  - _Narrador:_ _Dentro, dormido, Cosme. Todavía con sus zapatillas de estar por casa._ _[silencio 0.8 s]_
  - **Iván:** …Está vivo. Está bien. Lleva zapatillas. Eso es buena señal. _[plano Reaccion de Iván · gesto Nervous]_
  - **Iván:** Nadie secuestra a alguien con zapatillas para hacerle algo malo, ¿no? _[a Candela]_
  - **Capitana Ñoz:** Y un pase VIP. Cuando todo esto acabe, venid a la final de temporada. Traed al vecino. Que salga en el último episodio.
  - _Narrador:_ _Recibes 🎫 el Pase VIP del plató. Segunda pieza del rescate: la grabación._

**Al terminar (momento de la biografía):** «Protagonizaste un episodio especial de «Terrícolas en apuros»»

---

### Saga_16_66B · «Dimensión 66-B»

**Resumen:** La Valmar malvada. Todo es igual pero peor: las palomas roban, los semáforos mienten y todo el mundo lleva perilla. Incluso… tú.

_Tipo: Saga de la Grieta · Acto III (4/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Pip ha calibrado el mando con las coordenadas. El portal a la 66-B está abierto en el garaje»

**Requisitos:** has terminado «Reestreno» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Cruzas el portal. La Valmar 66-B: el cielo es morado, las farolas se burlan de ti y en todos los balcones hay un señor con perilla regando plantas carnívoras.»
  - ⏳ _Pantalla de transición:_ «Cruzas el portal. La Valmar 66-B: el cielo es morado, las farolas se burlan de ti y en todos los balcones hay un señor con perilla regando plantas carnívoras.»
- **Paso 2 · Usar** — «Mira a tu alrededor en la plaza»
  - _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🖐 _Al usar «Un cartel: «CÓSIMO ALCALDE PARA SIEMPRE»»:_
    - _Narrador:_ _«CÓSIMO ALCALDE PARA SIEMPRE. Votar es opcional. El resultado, no». Debajo, un grafiti pequeñito: «Cosme volverá»._
    - **Candela:** Alguien en esta dimensión todavía se acuerda de Cosme. Eso es un dato importante. Lo apunto en rojo.
- **Paso 3 · Hablar** con Tú (malvado, dimensión 66-B) — «Alguien con tu cara (y perilla) te mira desde un banco»
  - _Lugar:_ la Plaza Mayor · _En escena:_ Tú (malvado, dimensión 66-B), Iván, Candela
  - **Tú (malvado, dimensión 66-B):** Vaya. Tú. Mi yo bueno. Con tus amigos buenos. _[plano Medio de Tú (malvado, dimensión 66-B) · gesto ArmsCrossed]_
  - **Tú (malvado, dimensión 66-B):** Qué asco. Qué envidia. Mayormente asco. _[en la pausa: Aparta]_
  - **Tú (malvado, dimensión 66-B):** Aquí mi vida es un desastre: me echaron del trabajo por malvado y mi gato me dejó por un vecino menos malvado. _[gesto Sad]_
  - **Tú (malvado, dimensión 66-B):** Y mis compañeros de cuarto me odian. Los de la 66-B, digo. _[a Iván · en la pausa: Mira]_
  - **Iván:** (susurrando) ¿Yo soy su compañero de cuarto aquí? ¿Y tengo perilla? …Me pido no saberlo.
  - ❓ **Pregunta al jugador:** ¿Qué le dices a tu yo malvado?
    - ➤ «Ayúdanos a llegar al laboratorio. Te lo agradeceré.» _(efecto: empatia +1; marca «malvado ayudo»)_
      - **Tú (malvado, dimensión 66-B):** ¿Agradecer? ¿A mí? …Qué sensación tan rara. Me gusta. La entrada está en la rejilla de la universidad. Y no me des las gracias, que me sale urticaria.
    - ➤ «No me fío de ti. Ni de tu perilla.» _(efecto: valentia +1)_
      - **Tú (malvado, dimensión 66-B):** Haces bien. Yo tampoco me fío de mí. …Pero la rejilla de la universidad echa humo verde. Por si te interesa. No te lo he dicho.
  - **Tú (malvado, dimensión 66-B):** Algún día iré a tu Valmar a quedarme con tu vida. Te aviso ahora, para ser justo. Soy malvado, pero de palabra.
- **Paso 4 · Huida** — «¡Drones de Cósimo! Corre hasta la universidad (malvada) con tu equipo»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Iván (te acompaña), Candela (te acompaña), Dron de Cósimo
  - 🚨 _Si te atrapan:_ «¡Participante descalificado! (Te sueltan en la plaza. Candela te recoge.)»
- **Paso 5 · Usar** — «Busca la entrada al laboratorio subterráneo»
  - _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🖐 _Al usar «Una rejilla de ventilación con vapor verde»:_
    - _Narrador:_ _Por la rejilla sale vapor verde y música de concurso. Abajo se ve un pasillo enorme, iluminado con neones._
    - _Narrador:_ _«LABORATORIO DEL DR. CÓSIMO — PROHIBIDO EL PASO (excepto concursantes)»._
    - _(si tienes la marca «grabacion laboratorio»)_ **Candela:** Es el pasillo de la grabación de la Capitana. Con los mismos neones. Lo apunto. _[plano Medio de Candela]_
    - _(si tienes la marca «coordenadas cosimo»)_ **Pip:** (Por el comunicador) Coordenadas de Bigotes confirmadas. Descansen. Mañana, rescate.
    - _(si NO se cumple: tienes la marca «coordenadas cosimo»)_ **Pip:** (Por el comunicador) Coordenadas confirmadas. Descansen. Mañana, rescate.
    - **Pip:** (Por el comunicador) Y señor Iván: no se coma las plantas carnívoras. Otra vez.
    - _Narrador:_ _Recibes 🗺️ el Mapa de la Valmar malvada (dibujado por Candela, con leyenda de colores)._

**Al terminar (momento de la biografía):** «Entraste en la Valmar malvada»

---

### Saga_17_Rescate · «El rescate»

**Resumen:** Bajo la universidad de la Valmar malvada, en una cápsula de cristal, duerme Cosme. Entre él y tú: robots, drones y un pasillo con música de concurso.

_Tipo: Saga de la Grieta · Acto III (5/6) · Duración: 30-40 min_

**Cómo empieza:** al llegar a la Universidad de Valmar. «La rejilla del laboratorio de Cósimo. Tu equipo está listo»

**Requisitos:** has terminado «Dimensión 66-B» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Pelea** — «El pasillo del laboratorio: desconecta a los guardias (0/3)»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🚨 _Si te atrapan:_ «Tiene usted una llamada de ventas… (Candela tira de ti hacia atrás.)»
- **Paso 2 · Usar** — «Abre la cápsula de Cosme»
  - 🖐 _Al usar «La cápsula de cristal»:_
    - _Narrador:_ _La cápsula se abre con un silbido._
    - **Cosme:** (Abre los ojos. Te mira. Parpadea. Te mira otra vez.) _[plano PrimerPlano de Cosme · silencio 0.8 s]_
    - **Cosme:** …Hola. ¿Nos conocemos? Tienes cara de alguien que ha roto algo mío. Muchas veces. _[gesto Ask]_
    - _Narrador:_ _No te recuerda. En una pantalla de la pared pone: «Recuerdos extraídos: 87 %»._ _[silencio 0.8 s]_
    - **Candela:** Le ha estado sacando los recuerdos. Uno a uno. Para saber cómo soltar el ancla. _[plano Reaccion de Candela · gesto Angry]_
    - **Doctor Cósimo:** (Por los altavoces) ¡Qué momento más emocionante! ¡El reencuentro!
    - **Doctor Cósimo:** (Por los altavoces) Lástima que él no se acuerde de ti. Lo mejor de los recuerdos es que se pueden quitar.
    - _(si tienes la marca «malvado ayudo»)_ **Iván:** Tu yo con perilla no mentía: la rejilla llevaba justo aquí. Le debo un zumo.
    - **Candela:** Ya nos preocuparemos por su memoria. Primero, salir. ¡Ahora! _[ademán Point]_
- **Paso 3 · Huida** — «¡Cósimo ha activado la alarma! Vuelve al portal (el garaje) con Cosme»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme (te acompaña), Iván (te acompaña), Candela (te acompaña), Dron jefe de Cósimo
  - 🚨 _Si te atrapan:_ «¡Concursante atrapado! (Pip dispara confeti al dron y te suelta.)»
- **Paso 4 · Escena**
  - _En escena:_ Cosme, Pip, Don Escamas, Iván, Candela
  - **Pip:** Señor. Ha vuelto. _[a Cosme · plano Medio de Pip]_
  - **Pip:** …Ha vuelto. _[gesto Sad · silencio 1.0 s]_
  - **Cosme:** ¿Tú eres mi robot? Qué robot más educado. _[a Pip · gesto Ask]_
  - **Cosme:** ¿Y ese pez de la pecera me está mirando mal? _[a Don Escamas]_
  - **Don Escamas:** Te estoy mirando con cariño. Es mi cara. Los peces no tenemos otra. _[a Cosme]_
  - **Iván:** Bueno… lo hemos traído. Con zapatillas y todo. Eso es un diez. _[a Candela · gesto Shrug]_
  - _Narrador:_ _Cosme está en casa. Pero no sabe quién eres._
  - **Cosme:** (Medio dormido, bajo la manta que le pone Pip) …Criatura. _[plano PrimerPlano de Cosme · silencio 1.5 s]_
  - _Narrador:_ _Solo eso. Luego se duerme._ _[silencio 0.8 s]_

**Al terminar (momento de la biografía):** «Rescataste a Cosme»

---

### Saga_18_Precio · «Todo tiene un precio»

**Resumen:** Cosme está en casa, pero sin recuerdos. Y esta noche, en todas las pantallas de Valmar, aparece un hombre con perilla con un anuncio.

_Tipo: Saga de la Grieta · Acto III (6/6) · Final del acto · Duración: 20-30 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Pip te llama: «Venga. Todas las pantallas de Valmar se han encendido a la vez»»

**Requisitos:** has terminado «El rescate» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip
  - **Doctor Cósimo:** (En todas las pantallas) ¡Buenos días, Valmar! Tengo un anuncio. La Gran Fusión se celebrará en el Monte del Silencio.
  - **Doctor Cósimo:** (En todas las pantallas) Cuando el Ancla ya no sea una criatura, sino una persona adulta con trabajo y facturas. _[plano Reaccion de Pip]_
  - **Doctor Cósimo:** (En todas las pantallas) Porque los adultos, querido público, están tan cansados que sueltan cualquier cosa. Hasta un universo.
  - **Doctor Cósimo:** (En todas las pantallas) ¡No se lo pierdan! Entradas a la venta en MegaVerso. _[plano Reaccion de Cosme]_
  - **Pip:** Nos da tiempo. Años. _[plano Medio de Pip · silencio 1.0 s]_
  - **Pip:** Tiempo para que el señor recupere la memoria. Y para prepararnos. _[a Cosme · en la pausa: Mira]_
  - 🎬 **Escena de cámara «Grieta_Inminente»**
- **Paso 2 · Hablar** con Cosme — «Siéntate con Cosme»
  - _En escena:_ Cosme
  - **Cosme:** Mira. No sé quién eres. Pero cuando entras, este garaje huele distinto. Huele a… burbujas. ¿Tiene sentido? No tiene sentido.
  - **Cosme:** Tengo un hueco aquí dentro. Muy grande. Y cuando te miro, el hueco se hace más pequeño. Un poquito.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Le cuentas lo del microondas temporal y el bocadillo del martes» _(efecto: Cosme +6; humor +1)_
      - **Cosme:** ¿Un microondas que calienta en el pasado? Qué idea más estúpida. Y más genial. …¿Fue idea mía? Claro que fue idea mía.
    - ➤ «Le dices tu nombre y le das la mano» _(efecto: Cosme +8; empatia +2)_
      - **Cosme:** [tu nombre]… [tu nombre]. …Criatura. Tú eres la criatura. Eso sí lo sé. No sé nada más. Pero eso lo sé.
  - _Narrador:_ _Candela hace una foto: Cosme en la puerta del garaje, con cara de no entender nada, y tú a su lado._
  - _Narrador:_ _Iván sale en una esquina comiendo moras._
  - _Narrador:_ _Recibes 📸 la foto «Cosme sin memoria». FIN DEL ACTO III._
  - _Narrador:_ _Cosme está en casa. Faltan sus recuerdos. Y falta la Gran Fusión._ _[silencio 1.0 s]_

**Al terminar (momento de la biografía):** «Cosme recordó tu nombre»

---


# Saga de la Grieta · Acto IV y epílogo

> Misiones canónicas de la saga (vida adulta: en paralelo a «Tu vida», antes de «Mirar atrás»). Se ven siempre en el mapa hasta hacerlas.

### Saga_19_Recuerdos · «Recuerdos de tostadora»

**Resumen:** Cosme sigue sin recordar casi nada. Pip tiene una idea: llevarle a los sitios donde vivisteis cosas juntos. Los recuerdos, dice Pip, se quedan pegados a los sitios.

_Tipo: Saga de la Grieta · Acto IV (1/6) · Duración: 30-40 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Pip te espera con Cosme y una lista: «Sitios donde el señor fue feliz»»

**Requisitos:** has terminado «Todo tiene un precio» y etapa desde Adulto

**Pasos:**

- **Paso 1 · Hablar** con Pip — «Habla con Pip»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Pip:** He hecho una lista de sitios donde el señor fue feliz. Es corta. El señor no salía mucho.
  - **Pip:** Pero en casi todos estaba usted. _[en la pausa: Mira]_
  - **Cosme:** ¿Yo fui feliz? ¿En sitios? ¿Con esta cara? Qué raro. _[gesto Shrug]_
  - _(si tienes el recuerdo «tu nombre»)_ **Cosme:** Sé tu nombre. Es lo único que sé seguro. Lo demás… ya veremos.
  - **Cosme:** Vamos. Pero volvemos pronto: echo de menos una cosa que no sé cuál es. _[silencio 0.6 s]_
  - **Don Escamas:** Mirad también en los cacharros del garaje. Una mente se esconde donde menos te lo esperas… _[plano Medio de Don Escamas]_
  - **Don Escamas:** …en una tostadora, por ejemplo. Yo nunca tiro una copia de seguridad.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Lleva a Cosme a los sitios de vuestros recuerdos»
  - _Lugar:_ Nido de Petra (granero) · _En escena:_ Cosme (te acompaña), Julián
  - **Paso 2.1 · Usar** — «El garaje: el microondas temporal»
    - 🖐 _Al usar «El microondas temporal (reparado por Pip)»:_
      - _Narrador:_ _Metes un bocadillo en el microondas temporal. «Ding». Sale caliente… y mordido. Mordido por el Cosme de ayer._
      - **Cosme:** …El martes pasado. Tenía hambre el martes pasado. _[plano PrimerPlano de Cosme · en la pausa: Piensa]_
      - **Cosme:** ¡Me acuerdo del martes pasado! Y de un bocadillo de chorizo. Y de una criatura con las manos llenas de piezas. _[gesto Surprised]_
  - **Paso 2.2 · Usar** — «La granja de Villaverde: Petra»
    - 🖐 _Al usar «Petra, en su nido»:_
      - **Julián:** Hombre, Cosme. ¿Vienes a disculparte con Petra? Ya iba siendo hora. Solo han pasado… muchos años.
      - _Narrador:_ _Petra, la gallina, mira a Cosme. Cosme mira a Petra. Petra le da un picotazo en la rodilla._
      - **Cosme:** ¡AY! ¡La gallina! ¡La gallina de seis metros! ¡El rayo agrandador! _[gesto Surprised]_
      - **Cosme:** ¡Tú disparaste con los ojos cerrados! ¡Me acuerdo! _[ademán Point]_
      - _(si has terminado «La gallina de seis metros»)_ **Cosme:** Y me acuerdo de lo que le dije a la criatura en la furgoneta. Que no era nada. Que esperara al martes en que me convertí en perchero.
  - **Paso 2.3 · Usar** — «El parque: el anclaje del cielo»
    - 🖐 _Al usar «El viejo anclaje del parque»:_
      - _Narrador:_ _El viejo anclaje de cristal, el que clavaste hace años. Todavía brilla un poco. Cosme lo toca._
      - **Cosme:** La noche de la aguja. Coser el cielo. Tú subiste al tejado del cole… no, eso no. Tú clavaste esto. _[en la pausa: Piensa]_
      - **Cosme:** Y yo… yo me sentí tan orgulloso que no supe decírtelo. _[plano PrimerPlano de Cosme · gesto Sad · silencio 0.8 s]_
- **Paso 3 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** Criatura. _[plano PrimerPlano de Cosme · gesto Happy · silencio 1.0 s]_
  - **Cosme:** Me acuerdo. De todo. Del microondas, de las burbujas, del pez, de la cinta, de la cápsula. _[en la pausa: Respira]_
  - _(si tienes el recuerdo «los clones»)_ **Cosme:** De los cuatro como tú en clase. Uno se comió la plastilina. Era el más listo.
  - _(si tienes el recuerdo «tirachinas abu»)_ **Cosme:** De mis palomas robot. Y de la puntería de tu abu, que se hereda.
  - _(si tienes el recuerdo «cosas perdidas»)_ **Cosme:** De la noche de los calcetines desparejados. Aún huelo a pie.
  - _(si tienes el recuerdo «ayudante cosme»)_ **Cosme:** De la credencial plastificada. Salías fatal en la foto.
  - _(si tienes la marca «secreto cosme»)_ **Cosme:** Y de que guardaste mi secreto de vecinos. Nunca se lo contaste a nadie.
  - _(si tienes el recuerdo «rescate cosme»)_ **Cosme:** Me acuerdo de que viniste a por mí a otra dimensión. Con zumo de mora. _[silencio 0.5 s]_
  - **Pip:** Señor. Bienvenido. Otra vez. De verdad esta vez. _[plano Reaccion de Pip]_
  - **Cosme:** Y ahora me acuerdo de otra cosa, criatura: de lo que Cósimo me sacó. Cómo soltar el ancla. _[gesto Sad · en la pausa: Piensa]_
  - **Cosme:** Lo sabe todo. Viene a por ti. Necesitamos a todo el mundo. _[gesto Angry]_
  - _Narrador:_ _Pip os hace un álbum con fotos de cada sitio. Recibes 📔 el Álbum de recuerdos._

**Al terminar (momento de la biografía):** «Cosme recuperó sus recuerdos»

---

### Saga_20_Aliados · «Todos los aliados»

**Resumen:** Para la Gran Fusión hace falta todo el mundo. Todo el que te ha debido algo alguna vez. Y resulta que es mucha gente. Y muchos gatos. Y un velocirraptor.

_Tipo: Saga de la Grieta · Acto IV (2/6) · Duración: 30-45 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Cosme ha hecho una lista de aliados. Es larguísima. Y la mitad no son humanos»

**Requisitos:** has terminado «Recuerdos de tostadora» y etapa desde Adulto

**Pasos:**

- **Paso 1 · Hablar** con Cosme — «Cosme tiene la lista de aliados»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip
  - _(si tienes la marca «cosme recuerda»)_ **Cosme:** Lista de aliados. La he hecho con mis recuerdos nuevos. Bueno, viejos. Bueno, recuperados.
  - **Cosme:** Es larguísima. La mitad no son humanos. Me encanta. _[ademán Point]_
  - **Cosme:** No todos vendrán. Vendrán los que ayudaste. _[en la pausa: Piensa]_
  - **Cosme:** Así funciona el universo: lo que das, vuelve. A veces en forma de gato. _[gesto Happy]_
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Visita a tus aliados (vendrán los que ayudaste en tu vida)»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si has terminado «Bigotes, emperador de Gatonia»), Rex (si tienes la marca «rex se queda»), Ratón Pérez (si has terminado «La huelga del Ratón Pérez»), Gnomo Rigoberto (si has terminado «La noche de los gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «conoce tu malvado»)
  - **Paso 2.1 · Hablar** con Candela — «Iván y Candela (la residencia)»
    - **Candela:** ¿Batalla final contra un gemelo malvado para salvar la realidad? Tengo el sábado libre. Lo he comprobado en el calendario.
    - _(si tienes la marca «equipo rescate»)_ **Candela:** El equipo de rescate, reunido otra vez. Esta vez con plan plastificado desde el principio. _[a Iván]_
    - **Iván:** Y yo he hecho zumo de mora para cuarenta. Para el ejército. De día, tranquilos.
  - **Paso 2.2 · Hablar** con Agente Cronos, de Aduanas del Tiempo — «El agente Cronos (Correos)» _(solo si tienes la marca «cronos aliado»)_
    - **Agente Cronos, de Aduanas del Tiempo:** Mi agenda del futuro dice que el sábado hay una batalla en el Monte del Silencio. Y que yo estoy allí.
    - **Agente Cronos, de Aduanas del Tiempo:** Mi agenda nunca falla. Casi nunca. _[en la pausa: Piensa]_
    - _(si tienes el recuerdo «cronos aliado»)_ **Agente Cronos, de Aduanas del Tiempo:** Desde que cambié de bando, tu nombre sale en todas las páginas importantes.
    - _(si has terminado «El expediente de Cronos» y tienes la marca «cronos limpio»)_ **Agente Cronos, de Aduanas del Tiempo:** Y gracias a tu firma, mi expediente está limpio. Iré de uniforme. Con todos los sellos. Y esta vez, a la hora.
  - **Paso 2.3 · Hablar** con Bigotes XVII — «Bigotes (el cole)» _(solo si has terminado «Bigotes, emperador de Gatonia»)_
    - **Bigotes XVII:** ¿Una batalla por el destino del universo? Los gatos no participamos en batallas. Las supervisamos desde una caja. Estaré allí. En mi caja.
    - _(si has terminado «La visita de Estado» y tienes la marca «canciller gatonia»)_ **Bigotes XVII:** Y la Guardia Gatuna también, Canciller. Cuarenta gatos, cuarenta cajas. Ya ensayan el maullido de desprecio.
  - **Paso 2.4 · Hablar** con Rex — «Rex (Facultad de Derecho)» _(solo si tienes la marca «rex se queda»)_
    - **Rex:** Me defendiste ante la Aduana del Tiempo. Un velocirraptor no olvida. Y un abogado, menos. Iré. Con garras y con código civil.
    - _(si has terminado «Rex, abogado del Ancla» y tienes la marca «rex abogado»)_ **Rex:** Además, ya le ganamos un juicio al Consorcio. Si Cósimo protesta, le pongo una demanda. Y luego le muerdo. En ese orden.
  - **Paso 2.5 · Hablar** con Ratón Pérez — «El Ratón Pérez (el parque)» _(solo si has terminado «La huelga del Ratón Pérez»)_
    - _(si tienes la marca «rata contratada»)_ **Ratón Pérez:** ¿Una batalla? Tengo vacaciones gracias a ti. Mi ayudante, la rata, cubre el turno.
    - **Ratón Pérez:** Iré con la patrulla de ratones. Somos pequeños, pero mordemos cables.
    - _(si has terminado «La muela del juicio» y tienes la marca «patrulla ratones»)_ **Ratón Pérez:** Y el sindicato ya ha votado. La patrulla lleva una semana roendo cables de MegaVerso. Nos hemos guardado los mejores para el sábado.
  - **Paso 2.6 · Hablar** con Gnomo Rigoberto — «Rigoberto y los gnomos (tu jardín)» _(solo si has terminado «La noche de los gnomos»)_
    - **Gnomo Rigoberto:** ¡El tratado de paz nos obliga a defender el jardín! Y el universo es un jardín muy grande. ¡Los gnomos marchamos! Despacito.
    - _(si has terminado «El consejo de los jardines» y tienes la marca «gnomos en pie»)_ **Gnomo Rigoberto:** ¡Y el Consejo de los Jardines votó por unanimidad! Bueno, Fermina se abstuvo. Pero porque estaba boca abajo.
  - **Paso 2.7 · Hablar** con Tú (malvado, dimensión 66-B) — «Tu yo malvado (la plaza)» _(solo si tienes la marca «conoce tu malvado»)_
    - **Tú (malvado, dimensión 66-B):** ¿Ayudarte? ¿Contra Cósimo? …Él me prometió tu vida y nunca me la dio. Además, me ha subido el alquiler. _[gesto ArmsCrossed]_
    - _(si tienes la marca «malvado ayudo»)_ **Tú (malvado, dimensión 66-B):** Te enseñé la rejilla del laboratorio. Fue mi primera buena acción. Me gustó. Un poco.
    - **Tú (malvado, dimensión 66-B):** Iré. Por venganza. Y un poco por ti. Poco. _[en la pausa: Aparta]_
    - _(si has terminado «Clases de ser bueno» y tienes la marca «malvado aprende bondad»)_ **Tú (malvado, dimensión 66-B):** Además, ya sé pedir perdón y dar las gracias. Lo practico todos los días delante del espejo. Me da un asco… pero funciona.
- **Paso 3 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** ¡Mira cuánta gente! Y gatos. Y roedores. _[plano General · ademán Cheer]_
  - _(si tienes la marca «aliado rex»)_ **Cosme:** Y… ¿eso es un velocirraptor con corbata? Criatura, tienes una vida rarísima. Me encanta. _[gesto Laugh]_
  - _(si NO se cumple: tienes la marca «aliado rex»)_ **Cosme:** Criatura, tienes una vida rarísima. Me encanta. _[gesto Happy]_
  - **Don Escamas:** Y yo tengo lo más importante: las cuentas de MegaVerso. _[plano Medio de Don Escamas · silencio 0.5 s]_
  - **Don Escamas:** Para vencer a Cósimo, primero hay que dejarle sin dinero. Y yo sé dónde lo esconde.
  - _(si has terminado «Final de temporada» y tienes la marca «nave en el final»)_ _Narrador:_ _Sobre el garaje pasa una nave con un cartel luminoso: «FINAL DE TEMPORADA · EN DIRECTO». La Capitana Ñoz saluda con las cuatro manos._

**Al terminar (momento de la biografía):** «Reuniste a todos tus aliados»

---

### Saga_21_Consorcio · «La caída del Consorcio»

**Resumen:** Don Escamas ha encontrado el servidor central de MegaVerso: allí están todas las cuentas del Proyecto Fusión. Si cae el servidor, cae el Consorcio. Y Cósimo se queda sin dinero.

_Tipo: Saga de la Grieta · Acto IV (3/6) · Duración: 25-35 min_

**Cómo empieza:** al llegar a las oficinas del Distrito Financiero. «La sede de MegaVerso. Don Escamas, en su cubo, te da la señal: «Ahora»»

**Requisitos:** has terminado «Todos los aliados» y etapa desde Adulto

**Pasos:**

- **Paso 1 · Pelea** — «Asalto a la sede de MegaVerso: aparta a la seguridad (0/2)»
  - _Lugar:_ las oficinas del Distrito Financiero · _En escena:_ Candela, Agente de MegaVerso (si tienes la marca «gris arrepentida»)
  - 🚨 _Si te atrapan:_ «Tiene usted una llamada de ventas. (Candela te saca de ahí por la oreja.)»
- **Paso 2 · Usar** — «Enchufa el pendrive de Don Escamas en el servidor central»
  - _En escena:_ Iván, Candela
  - 🖐 _Al usar «El servidor central de MegaVerso»:_
    - _Narrador:_ _El pendrive de Don Escamas tiene forma de pez. Lo enchufas. Las cuentas del Consorcio llenan todas las pantallas de la oficina._
    - **Iván:** Facturas falsas. Planetas embargados. «Perillas postizas, 40.000 unidades»… _[plano DosPlanos de Iván → Candela · gesto Surprised]_
    - **Candela:** Y una transferencia enorme: «Laboratorio Dr. Cósimo — Proyecto Fusión». Lo apunto en rojo. _[a Iván]_
    - _(si tienes el recuerdo «proyecto fusion»)_ **Candela:** Es lo que viste en su ordenador de la oficina, ¿no? Ahora con importes.
- **Paso 3 · Escena**
  - _En escena:_ Agente Glub, Iván, Candela
  - **Agente Glub:** Agente Glub, Banco Galáctico. Hemos recibido un chivatazo contable impecable. _[plano General]_
  - **Agente Glub:** Firmado por un tal «D. Escamas». Muy buena caligrafía para ser un pez.
  - _(si has terminado «La deuda galáctica»)_ **Agente Glub:** ¿Nos conocemos? Usted es quien leyó la letra pequeña. O quien nos resistió. Me acuerdo. No es fácil olvidarle.
  - **Agente Glub:** MegaVerso S.A. queda intervenida. Cuentas congeladas. Sellado, sellado y sellado.
  - **Agente Glub:** El doctor Cósimo se queda sin financiación. _[silencio 0.6 s]_
  - **Iván:** ¡Hemos arruinado a una multinacional malvada! ¡Con un pendrive con forma de pez! _[plano Reaccion de Iván · ademán Cheer]_
  - **Iván:** ¡Esto hay que ponerlo en el currículum!
  - _(si tienes el recuerdo «equipo rescate»)_ **Candela:** El equipo de rescate, versión asalto. Funciona igual de bien. Lo apunto. _[a Iván]_
  - **Candela:** Sin dinero, Cósimo solo tiene una opción: hacer la Fusión él solo. Y rápido. Viene a por el Ancla. Ahora sí.

**Al terminar (momento de la biografía):** «Hiciste caer al Consorcio MegaVerso»

---

### Saga_22_Ancla · «El Ancla»

**Resumen:** Esta noche, en tu casa, alguien llama a la puerta. Un hombre de pelo blanco muy peinado. Con perilla. Trae flores. Y una oferta.

_Tipo: Saga de la Grieta · Acto IV (4/6) · Duración: 15-25 min_

**Cómo empieza:** al llegar a tu casa. «Llaman a la puerta de tu casa. A estas horas. Con música de concurso»

**Requisitos:** has terminado «La caída del Consorcio» y entre las 20:00 y las 6:00 y etapa desde Adulto

**Pasos:**

- **Paso 1 · Hablar** con Doctor Cósimo — «Abre la puerta»
  - _Lugar:_ tu casa · _En escena:_ Doctor Cósimo
  - **Doctor Cósimo:** Buenas noches. Perdona la hora. Traigo flores. De la 66-B: muerden un poco, no las toques. _[plano Medio de Doctor Cósimo · ademán WaveLite]_
  - _(si tienes el recuerdo «caida consorcio»)_ **Doctor Cósimo:** Me habéis arruinado el Consorcio. Muy bien hecho. Me impresionas.
  - **Doctor Cósimo:** Así que vengo a negociar, como la gente civilizada. Con perilla. _[gesto Happy]_
  - _(si tienes el recuerdo «eres el ancla»)_ **Doctor Cósimo:** Ya viste la cinta del archivo, ¿verdad? Entonces sabes lo que eres. Y por qué estoy en tu puerta.
  - **Doctor Cósimo:** En mi Valmar puedo darte la vida perfecta: el mejor trabajo, la casa más grande, un gato que te hace caso.
  - **Doctor Cósimo:** Solo tienes que venir conmigo. Soltar el ancla. Nada más. _[plano PrimerPlano de Doctor Cósimo · silencio 0.6 s]_
  - **Doctor Cósimo:** ¿Sabes lo que es quedarse al otro lado veinte años, solo, porque alguien te soltó la mano? _[gesto Sad · en la pausa: Baja]_
  - **Doctor Cósimo:** Yo solo quiero volver. A lo grande. Con las dos Valmar para mí. _[gesto Angry · en la pausa: Respira]_
  - **Doctor Cósimo:** (Se le cae la sonrisa de anuncio un segundo. Debajo hay un hombre muy cansado. Y muy solo.) _[plano PPP de Doctor Cósimo · gesto Sad · silencio 0.8 s]_
- **Paso 2 · Decisión** — «Cósimo te ofrece una vida perfecta en la 66-B a cambio de soltar el ancla. ¿Qué haces?»
  - ➤ **Opción «No.» Así de simple** _(efecto: decisión «trato» = No; valentia +2)_
  - ➤ **Opción «Fingir que aceptas… para tenderle una trampa en el monte»** _(efecto: decisión «trato» = Trampa; curiosidad +1; humor +1; marca «trampa cosimo»)_
- **Paso 3 · Escena**
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** ¿No? …Qué predecible. Como él. Os parecéis tanto que da rabia. _[gesto Angry]_
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** Nos veremos en el Monte del Silencio, Ancla. Traiga a quien quiera. Yo traeré el final. _[silencio 0.5 s]_
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** ¿Aceptas? ¡Maravilloso! Nos vemos en la cima del monte. Mañana a medianoche. Ven solo/sola. _[gesto Happy]_
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** …¿Por qué sonríes así? Bah. Será la emoción. _[en la pausa: Piensa]_
  - _Narrador:_ _Cósimo se va. Te quedas mirando las flores que muerden. Mañana es la Gran Fusión._
  - _Narrador:_ _Llamas a Cosme. Contesta al primer tono: estaba esperando la llamada._

**Al terminar (momento de la biografía):** «Le dijiste que no a Cósimo»

---

### Saga_23_Fusion · «La Gran Fusión»

**Resumen:** Medianoche en el Monte del Silencio. El cielo se abre como una cremallera. Dos Valmar a punto de convertirse en una. Todos tus aliados a tu espalda. Esto es el final.

_Tipo: Saga de la Grieta · Acto IV (5/6) · Batalla final · Duración: 35-50 min_

**Cómo empieza:** al llegar a La cima del monte. «Medianoche. La cima del Monte del Silencio. La Gran Fusión»

**Requisitos:** has terminado «El Ancla» y entre las 22:00 y las 4:00 y etapa desde Adulto

**Pasos:**

- **Paso 1 · Cinemática**
  - _Lugar:_ La cima del monte · _En escena:_ Cosme
  - 🎬 **Cinemática «Grieta_Fusion»** _(música: → Tension → Tema efecto Momento)_
    - _En escena:_ Cosme, Doctor Cósimo · _entran andando:_ Doctor Cósimo
    - _Cámara:_ 6 planos (Inserto, Seguir, Hombro)
    - 🪧 _Rótulo:_ «🌀 LA GRAN FUSIÓN» — Todas las dimensiones, a la vez
    - **Cosme:** Medianoche. En punto. Siempre fue puntual para lo malo. _[plano Reaccion de Cosme]_
    - _(si tienes el recuerdo «grieta en el cielo»)_ **Cosme:** La primera vez era un rasguño. Tenías que ponerte de puntillas para verlo. _[plano DosPlanos de Cosme → Tú]_
    - _(si NO se cumple: tienes el recuerdo «grieta en el cielo»)_ **Cosme:** Toda la vida sujetándola sin saberlo. Hoy no la sujetas sin ayuda. _[plano DosPlanos de Cosme → Tú]_
    - _(si tienes la marca «trampa cosimo»)_ **Cosme:** Ha picado. Viene sonriendo… Se ha creído que vienes a rendirte.
    - _(si NO se cumple: tienes la marca «trampa cosimo»)_ **Cosme:** Ahí está. Con perilla y todo. Quédate a mi lado.
    - 🔀 **Variante «Restos»** (si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …): cambia Fx por:
      - _(solo efectos de imagen y sonido, sin texto)_
- **Paso 2 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** ¡Bienvenidos a la GRAN FUSIÓN! ¡En directo desde el Monte del Silencio! ¡Y traes público! Qué detalle. _[plano Medio de Doctor Cósimo · ademán Wave]_
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** Habías aceptado… ¿Y traes un EJÉRCITO? ¿Gatos? ¿Un velocirraptor? _[plano Medio de Doctor Cósimo · gesto Surprised]_
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** …Me has engañado. Me has engañado MUY bien. Como él. _[a Cosme · en la pausa: Respira]_
  - _(si tienes la marca «consorcio caido»)_ **Doctor Cósimo:** Sin Consorcio, sin dinero, sin público de pago. Solo yo y mi máquina. Mejor: así el final es todo mío.
  - _(si tienes el recuerdo «el trato»)_ **Cosme:** Fue a tu casa con flores, ¿verdad? Siempre llevaba flores a las peleas.
  - **Cosme:** Cósimo. Todavía estás a tiempo. Deja la máquina. _[a Doctor Cósimo · plano Hombro de Tú → Cosme · en la pausa: Respira]_
  - **Cosme:** Ven a casa. Te hago un batido. _[a Doctor Cósimo · gesto Sad · silencio 0.5 s]_
  - **Doctor Cósimo:** ¿A casa? ¿A qué casa, Cosme? Tú tienes una vida. Un robot. Un pez. Una criatura. _[a Cosme · gesto Angry]_
  - **Doctor Cósimo:** Yo tengo una perilla y una dimensión que me odia. ¡Drones! _[plano PrimerPlano de Doctor Cósimo · ademán Point]_
- **Paso 3 · Huida** — «¡La Grieta tira de ti! Aguanta 25 segundos sin que los drones te empujen dentro»
  - _En escena:_ Dron de Cósimo, Cosme
  - 🚨 _Si te atrapan:_ «¡Casi! (Cosme te agarra de la mano. Esta vez no te suelta.)»
- **Paso 4 · Pelea** — «¡Oleada de drones y robots! Tus aliados te cubren (0/4)»
  - _En escena:_ Iván, Candela, Pip, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si tienes la marca «aliado bigotes»), Rex (si tienes la marca «aliado rex»), Ratón Pérez (si tienes la marca «aliado perez»), Gnomo Rigoberto (si tienes la marca «aliado gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»), Capitana Ñoz
  - 🚨 _Si te atrapan:_ «¡Te tengo! (Un aliado te rescata. Vuelves a la cima.)»
- **Paso 5 · Escena** _(solo si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - _En escena:_ Pip, Doctor Cósimo
  - **Pip:** ¡Ancla! ¡Los Restos de la Grieta! El sello, la bombilla, mi chapa… Todo lo que devolvió a su sitio. ¡Están brillando! _[plano Medio de Pip · ademán Point]_
  - _Narrador:_ _Las cosas raras que arreglaste por Valmar se encienden a la vez. La Grieta las reconoce: son tuyas._
  - **Pip:** ¡Y tiran de él hacia atrás! _[a Doctor Cósimo]_
  - **Doctor Cósimo:** ¿Una farola que canta? ¿Un tenedor? ¿Esto es un ejército o un mercadillo? …¿Por qué me pesan las piernas?
- **Paso 6 · Pelea** — «¡Cósimo en persona! Tus Restos de la Grieta brillan y le frenan: cóselo de vuelta a su dimensión» _(solo si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - _En escena:_ Iván, Candela, Pip, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si tienes la marca «aliado bigotes»), Rex (si tienes la marca «aliado rex»), Ratón Pérez (si tienes la marca «aliado perez»), Gnomo Rigoberto (si tienes la marca «aliado gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»), Capitana Ñoz
  - 🚨 _Si te atrapan:_ «¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)»
- **Paso 7 · Pelea** — «¡Cósimo en persona! Cóselo de vuelta a su dimensión» _(solo si tienes menos de 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - 🚨 _Si te atrapan:_ «¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)»
- **Paso 8 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme, Pip, Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»)
  - **Doctor Cósimo:** Veinte años preparando esto. _[plano Medio de Doctor Cósimo · gesto Sad · silencio 0.6 s]_
  - _(si tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Y me gana un Ancla con un ejército de gatos, gnomos y un pez contable. …Qué vergüenza. Qué episodio tan bueno. _[gesto Facepalm]_
  - _(si NO se cumple: tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Y me gana un Ancla con un pez contable y un robot. …Qué vergüenza. Qué episodio tan bueno. _[gesto Facepalm]_
  - _(si tienes la marca «enfado con cosme»)_ **Cosme:** Alguien me dijo una vez que debí contar las cosas antes. Tenía razón. Así que lo digo ahora.
  - _(si tienes la marca «perdona a cosme»)_ **Cosme:** Alguien me perdonó una noche, en mi garaje, sin que me lo mereciera. Ahora me toca a mí.
  - **Cosme:** Cósimo. Aquella noche te solté la mano. Llevo veinte años pensándolo. _[a Doctor Cósimo · plano DosPlanos de Cosme → Doctor Cósimo · en la pausa: Respira]_
  - **Cosme:** No fue a propósito. Fue miedo. Perdóname. _[a Doctor Cósimo · gesto Sad · silencio 0.8 s]_
  - **Doctor Cósimo:** …¿Veinte años y ahora me pides perdón? ¿Así? ¿En directo? _[a Cosme · en la pausa: Baja]_
  - **Doctor Cósimo:** …Eres insoportable, Cosme. _[gesto Sad · silencio 0.6 s]_
  - ❓ **Pregunta al jugador:** Cósimo te mira a ti. «¿Y tú qué harías conmigo, Ancla?»
    - ➤ «Que vuelva. Que empiece de cero. En esta Valmar.» _(efecto: empatia +2; marca «cosimo perdonado»)_
      - **Doctor Cósimo:** ¿Aquí? ¿Sin perilla? …Me afeitaré. Me sentará fatal. …Gracias.
    - ➤ «Que vuelva a la 66-B. Pero sin maldad: a arreglarla.» _(efecto: responsabilidad +2; marca «cosimo arregla 66b»)_
      - **Doctor Cósimo:** ¿Arreglar la 66-B? ¿Una dimensión entera de malvados? …Sería el reto más grande de mi vida. Me gustan los retos grandes. Acepto.
      - _(si tienes la marca «aliado malvado»)_ **Tú (malvado, dimensión 66-B):** Yo le ayudo. Ya sé cómo es ser bueno. Un poco. Tengo práctica. _[a Doctor Cósimo · plano Medio de Tú (malvado, dimensión 66-B)]_
  - _Narrador:_ _La máquina de la Fusión se apaga. Pero la Grieta sigue abierta en el cielo, enorme, temblando._
  - **Cosme:** Ya no tira nadie de ella. Solo falta cerrarla. Para siempre. _[plano Reaccion de Cosme]_

**Al terminar (momento de la biografía):** «Venciste en la Gran Fusión»

---

### Saga_24_Final · «Coser el cielo (de verdad)»

**Resumen:** La Grieta sigue abierta. Para cerrarla para siempre hay que coserla desde los dos lados a la vez. Cosme y Cósimo. Juntos. Como la primera noche. Y tú, en medio, sujetándolo todo.

_Tipo: Saga de la Grieta · Epílogo · Duración: 20-30 min_

**Cómo empieza:** al llegar a El garaje de Cosme. «Cosme y Cósimo te esperan en el garaje. Juntos. Discutiendo. Como antes»

**Requisitos:** has terminado «La Gran Fusión» y etapa desde Adulto

**Pasos:**

- **Paso 1 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Doctor Cósimo, Pip, Don Escamas
  - **Cosme:** ¡Esa pieza va al revés! _[a Doctor Cósimo · plano DosPlanos de Cosme → Doctor Cósimo · gesto Angry]_
  - **Doctor Cósimo:** ¡Va al revés porque la pusiste tú al revés en 2003! _[a Cosme · gesto HandsOnHips]_
  - _(si tienes la marca «cosimo perdonado»)_ **Doctor Cósimo:** Y no me mires la barbilla. Ya sé que sin perilla parezco un huevo. _[a Cosme]_
  - _(si tienes la marca «cosimo arregla 66b»)_ **Doctor Cósimo:** Date prisa, que mañana vuelvo a la 66-B. Tengo una dimensión entera que arreglar. _[a Cosme]_
  - **Pip:** Llevan así tres horas. Es precioso. Es como antes. Tengo el aceite de los ojos alterado. _[plano Medio de Pip]_
  - _(si tienes la marca «consorcio caido»)_ **Don Escamas:** Las cuentas del Consorcio, cerradas. Las de la Grieta, a punto. Me encanta cuadrar un balance.
  - _(si tienes la marca «fusion detenida»)_ **Pip:** Ha llegado correo. Mucho correo. _[ademán Nod]_
  - _(si tienes el recuerdo «guardia gatuna»)_ **Pip:** Telegrama de Gatonia: «La Guardia Gatuna supervisó la batalla. Desde sus cajas. Éxito total». Firma: una huella.
  - _(si tienes el recuerdo «abogado rex»)_ **Pip:** Rex manda su minuta: un jamón. Dice que es simbólico.
  - _(si tienes el recuerdo «muela del juicio»)_ **Pip:** El sindicato de roedores informa: ciento doce cables de MegaVerso mordidos. Récord.
  - _(si tienes el recuerdo «expediente cronos»)_ **Pip:** La Aduana del Tiempo felicita al agente Cronos: llegó a la hora. Por primera vez en cuatrocientos años.
  - _(si tienes el recuerdo «temporada final»)_ **Pip:** La Capitana Ñoz: récord de audiencia en trescientas galaxias. Le renuevan diez temporadas.
  - _(si tienes el recuerdo «consejo gnomos»)_ **Pip:** Los gnomos llegaron cuando ya había acabado todo. Dicen que era el plan.
  - _(si tienes el recuerdo «clases de bondad»)_ **Pip:** Y tu yo de la 66-B manda flores. Estas no muerden. Ha aprendido.
  - _(si tienes el recuerdo «gran fusion»)_ **Cosme:** Después de lo del monte, el garaje parece pequeño. Me gusta pequeño. _[en la pausa: Respira]_
  - **Cosme:** Criatura: la Cosedora versión 2. Hay que coser el cielo desde los dos lados a la vez. _[plano Medio de Cosme · ademán Point]_
  - **Cosme:** Yo desde aquí, él desde su lado. Y tú en el centro, que eres el ancla. _[en la pausa: Mira]_
  - **Cosme:** Donde empezó todo. _[gesto Happy · silencio 0.6 s]_
- **Paso 2 · Ir a** el patio — «Id al patio del cole: donde clavaste el primer anclaje, hace años»
  - _Lugar:_ el patio · _En escena:_ Cosme (te acompaña), Doctor Cósimo (te acompaña), Iván (te acompaña), Candela (te acompaña)
- **Paso 3 · Cinemática**
  - _En escena:_ Cosme, Doctor Cósimo, Iván, Candela, Pip
  - 🎬 **Cinemática «Grieta_Final»** _(música: → Intima → Descubrimiento → Tema efecto Momento)_
    - _En escena:_ Cosme, Doctor Cósimo, Iván, Candela, Pip
    - _Cámara:_ 9 planos (General, DosPlanos, Medio, Reaccion, Dolly)
    - 🪧 _Rótulo:_ «🌅 La Grieta se cierra» — Fin de la Saga de la Grieta
    - _(si tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí clavaste el primer anclaje. Tenías barro hasta las rodillas.
    - _(si NO se cumple: tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí empezó todo. Aquí lo cerramos.
    - **Doctor Cósimo:** Yo cojo mi lado. Como en 2003. Esta vez no me sueltes. _[a Cosme]_
    - **Cosme:** No te suelto. Esta vez, no. _[a Doctor Cósimo · silencio 0.5 s]_
    - **Candela:** Punto uno. Punto dos. Punto tres…
    - 🔀 **Variante «Perdonado»** (si tienes la marca «cosimo perdonado»): cambia Dialogue por:
      - _(si tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí clavaste el primer anclaje. Tenías barro hasta las rodillas.
      - _(si NO se cumple: tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí empezó todo. Aquí lo cerramos.
      - **Doctor Cósimo:** Me he afeitado la perilla. Ni una palabra. …Cojo mi lado. _[a Cosme]_
      - **Cosme:** No te suelto. Esta vez, no. _[a Doctor Cósimo · silencio 0.5 s]_
      - **Candela:** Punto uno. Punto dos. Punto tres…
    - 🔀 **Variante «Arregla66B»** (si tienes la marca «cosimo arregla 66b»): cambia Dialogue por:
      - _(si tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí clavaste el primer anclaje. Tenías barro hasta las rodillas.
      - _(si NO se cumple: tienes el recuerdo «coser el cielo»)_ **Cosme:** Aquí empezó todo. Aquí lo cerramos.
      - **Doctor Cósimo:** Mañana vuelvo a la 66-B a arreglarla. Hoy, una última costura juntos. _[a Cosme]_
      - **Cosme:** No te suelto. Esta vez, no. _[a Doctor Cósimo · silencio 0.5 s]_
      - **Candela:** Punto uno. Punto dos. Punto tres…
- **Paso 4 · Escena**
  - **Doctor Cósimo:** Ya está. Ya no eres un ancla. Eres… una persona. _[plano Medio de Doctor Cósimo]_
  - **Doctor Cósimo:** Qué aburrido. Qué bien. _[gesto Happy · silencio 0.7 s]_
  - **Cosme:** Criatura. _[plano PrimerPlano de Cosme · en la pausa: Respira]_
  - _(si tienes el recuerdo «cosme recuerda»)_ **Cosme:** …Te lo digo ahora, que tengo todos los recuerdos y ninguno pendiente: estoy orgulloso de ti. _[silencio 0.5 s]_
  - _(si NO se cumple: tienes el recuerdo «cosme recuerda»)_ **Cosme:** …Te lo digo ahora, que el cielo está limpio: estoy orgulloso de ti. _[silencio 0.5 s]_
  - _(si tienes el recuerdo «conoci cosme»)_ **Cosme:** Desde el microondas. Desde siempre. _[gesto Happy]_
  - _(si NO se cumple: tienes el recuerdo «conoci cosme»)_ **Cosme:** Desde siempre. _[gesto Happy]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices a Cosme?
    - ➤ «Gracias por cuidarme toda la vida.» _(efecto: Cosme +20)_
      - **Cosme:** No me des las gracias. Dame un abrazo. Rápido, que viene Cósimo y no quiero que se ría. …Vale, que se ría.
    - ➤ «¿Y ahora qué inventamos?» _(efecto: Cosme +15; curiosidad +2)_
      - **Cosme:** ¡Esa es mi criatura! Tengo una idea sobre un tostador que tuesta en el futuro. Así el pan ya está hecho mañana. ¡Cósimo, trae el destornillador!
  - **Iván:** ¿Ya está? ¿Hemos salvado el universo? …¡Zumo de mora para todos! ¡De día! _[plano DosPlanos de Iván → Candela · ademán Cheer]_
  - _(si tienes la marca «aliado compis»)_ **Iván:** Quedan treinta y nueve litros del zumo para el ejército. Nadie se va sin vaso. _[a Candela]_
  - _(si tienes la marca «aliados reunidos»)_ **Candela:** Tachado el último punto de la lista plastificada: «Reunir a todos». Es el mejor día de mi vida. Lo apunto. _[a Iván]_
  - _(si NO se cumple: tienes la marca «aliados reunidos»)_ **Candela:** Tachado el último punto de la lista plastificada. Es el mejor día de mi vida. Lo apunto. _[a Iván]_
  - _(si tienes la marca «aliado cronos»)_ **Doctor Cósimo:** Y el de los sellos llegó a la hora. Ahora sí que lo he visto todo.
  - _Narrador:_ _Recibes 🪡 la Aguja de oro. FIN DE LA SAGA DE LA GRIETA._
  - _Narrador:_ _…Pero en Valmar, las cosas raras nunca se acaban del todo._ _[silencio 1.0 s]_

**Al terminar (momento de la biografía):** «Cosiste el cielo para siempre»

---


# Capítulo «Tu vida»

_Id: Adulto_TuVida · Etapa: Adulto · Música de fondo: VidaAdulta_

**Texto de entrada del capítulo:** «Ahora tu vida es tuya: trabaja, compra una casa, conoce la región… Y Cosme sigue en su garaje: la Saga de la Grieta y las misiones locas te esperan en el mapa.»

- 🎬 **Cabecera del capítulo (cinemática) «TuVida_Entrada»** _(vuelo de cámara, 9 s, 2 planos; música: VidaAdulta)_
  - 🪧 _Rótulo:_ «Tu vida» — Ahora tu vida es tuya

_Entre misión y misión se repite un «día normal» generado (Adulto_Jornada): no se exporta, no es guion fijo._

### Adulto_MirarAtras · «Mirar atrás»

**Resumen:** Han pasado muchos años. Vuelve a la casa donde creciste y mira todo lo que has vivido.

**Requisitos:** has vivido el 95 % de la etapa

**Pasos:**

- **Paso 1 · Ir a** tu casa familiar — «Vuelve a la casa donde creciste»
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Vida_MirarAtras»** _(música: → Intima PasanLosAnos → Resolucion → Tema; montaje de cambio de etapa Adulto → nil)_
    - _En escena:_ Una madre, Alba, Un padre, Mamá/Papá, Omar, Nico, Sara, Profe Lucía, Mateo, Hugo, Leire, Bruno, Abu, Rayo, Nerea, Profesora Beltrán, Julia, Ernesto, Chef Lola · _entran andando:_ Una madre, Alba, Un padre, Mamá/Papá, Omar, Nico, Sara, Profe Lucía, Mateo, Hugo, Leire, Bruno
    - _Cámara:_ 22 planos (Reaccion, Medio, DosPlanos, PrimerPlano)
    - 🪧 _Rótulo:_ «Los Pinos, Valmar» — Muchos años después
    - 🪧 _Rótulo:_ «La gente que conociste» — Y la que se quedó
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ 🪧 _Rótulo:_ ««Los Imparables»» — Y la gente que se quedó
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ 🪧 _Rótulo:_ ««La Patrulla Valmar»» — Y la gente que se quedó
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ 🪧 _Rótulo:_ ««Los del Banco Azul»» — Y la gente que se quedó
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ 🪧 _Rótulo:_ ««Los Dinosaurios»» — Y la gente que se quedó
    - 🪧 _Rótulo:_ «Toda una vida en Valmar» — Y todavía queda mucho por vivir
    - 🪧 _Rótulo:_ «El día que naciste» — Tu abu dijo tu nombre en voz alta, para que lo oyera el barrio
    - _(si tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ «Tu grupo del colegio» — Diez años y un banco del parque
    - _(si en «nombre grupo» elegiste «Los Imparables» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los Imparables»» — Diez años y un banco del parque
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««La Patrulla Valmar»» — Diez años y un banco del parque
    - _(si en «nombre grupo» elegiste «Los del Banco Azul» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los del Banco Azul»» — Diez años y un banco del parque
    - _(si en «nombre grupo» elegiste «Los Dinosaurios» y tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ ««Los Dinosaurios»» — Diez años y un banco del parque
    - _(si tienes la marca «ayudaste a mateo» y NO tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ «Mateo» — Tu primer amigo empezó con unos libros por el suelo
    - _(si NO tienes la marca «ayudaste a mateo» y NO tienes el recuerdo «primer grupo»)_ 🪧 _Rótulo:_ «Tu primer día de colegio» — «Pasad, pasad.»
    - _(si tienes el recuerdo «el cruce»)_ 🪧 _Rótulo:_ «El cruce de caminos» — El día que elegiste quién ser
    - _(si tienes la marca «conoces a leire» y NO tienes el recuerdo «el cruce»)_ 🪧 _Rótulo:_ «Leire» — Te hizo la mejor foto de tu vida y no te la enseñó hasta años después
    - _(si tienes el recuerdo «primer club» y NO tienes la marca «conoces a leire» y NO tienes el recuerdo «el cruce»)_ 🪧 _Rótulo:_ «Tu primer club» — El instituto, por dentro
    - _(si NO tienes la marca «conoces a leire» y NO tienes los recuerdos «el cruce» y «primer club»)_ 🪧 _Rótulo:_ «El instituto» — Los de siempre, un poco más altos
    - _(si tienes el recuerdo «graduacion»)_ 🪧 _Rótulo:_ «Tu graduación» — Beltrán casi sonrió
    - _(si tienes el recuerdo «primer contrato» y NO tienes el recuerdo «graduacion»)_ 🪧 _Rótulo:_ «Tu primer contrato» — La primera nómina, enmarcada (un tiempo)
    - _(si NO tienes los recuerdos «graduacion» y «primer contrato»)_ 🪧 _Rótulo:_ «Tus primeros trabajos» — Lola gritaba en la cocina y abrazaba fuera
    - _(si tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El atardecer con tu abu» — Playa Dorada
    - _(si en «promesa abu» elegiste «Volver» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El atardecer con tu abu» — Volviste cada año. Contigo o por ti.
    - _(si en «promesa abu» elegiste «CosasBonitas» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El atardecer con tu abu» — Hiciste cosas bonitas. Muchas.
    - _(si en «promesa abu» elegiste «Familia» y tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El atardecer con tu abu» — Cuidaste de la familia, como te cuidó a ti
    - _(si tienes el recuerdo «el reencuentro» y NO tienes el recuerdo «atardecer con abu»)_ 🪧 _Rótulo:_ «El reencuentro» — La Cafetería de Omar
    - _(si NO tienes los recuerdos «atardecer con abu» y «el reencuentro»)_ 🪧 _Rótulo:_ «Tu familia» — Los que te enseñaron a andar
    - _Narrador:_ _La casa de Los Pinos. La puerta sigue chirriando igual._
    - _(si NO se cumple: en «promesa adulta» elegiste «Hijos»)_ _Narrador:_ _Dentro te espera el álbum. Alguien lo ha dejado abierto por el principio._
    - _(si en «promesa adulta» elegiste «Hijos»)_ _Narrador:_ _Tu hija te espera con el álbum. Tu nieta ya lo ha abierto por la mitad._
    - _Narrador:_ _Una foto por etapa. Una vida dentro de cada foto._
    - _(si en «promesa abu» elegiste «CosasBonitas» y tienes el recuerdo «atardecer con abu»)_ **Abu:** Y que se note que eres feliz haciéndolas.
    - **Nico:** ¿Qué? ¿Pensabas mirar el álbum sin nosotros?
    - **Omar:** He traído bocadillos. Por los viejos tiempos. Y por los nuevos.
    - _(si NO se cumple: tienes el recuerdo «primer grupo»)_ **Sara:** Todos aquí. Estadísticamente, un milagro. Emocionalmente, lo normal.
    - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Grupo completo. Que conste en acta.
    - **Profe Lucía:** Cuarenta cursos dando clase. Y de esa clase me acuerdo de todo. No se lo digáis a nadie.
    - _(si en «promesa abu» elegiste «CosasBonitas»)_ **Omar:** Cosas bonitas, dijo tu abu. Pues mira a tu alrededor.
    - _(si en «promesa abu» elegiste «Familia»)_ **Omar:** Has cuidado de todos. Como le prometiste a tu abu.
    - _(si en «promesa abu» elegiste «Volver»)_ **Omar:** Este año también has ido a la playa, ¿verdad? Claro que sí. Siempre vas.
    - _(si en «promesa adulta» elegiste «Viaje»)_ **Nico:** Y todavía me debes el viaje a Villaverde. Ya no tenemos treinta, pero el balón sí.
- **Paso 3 · Momento** — «Toda una vida en Valmar. Y todavía queda mucho por vivir.»

**Al terminar (momento de la biografía):** «Miraste atrás: toda una vida en Valmar»

---

**Texto de cierre del capítulo:** «Toda una vida en Valmar. Y la historia sigue: la ciudad no se para.»

# Capítulo «Una nueva vida en Valmar»

_Id: Adulto_NuevaVida · Etapa: AdultoJoven_

> Capítulo ALTERNATIVO: solo lo juega quien empezó la partida ya adulto (versiones antiguas, sin infancia jugada). Sustituye a todo lo anterior.

**Solo si:** NO has terminado «La gran decisión»

**Texto de entrada del capítulo:** «Valmar: donde el valle se encuentra con el mar. Aquí empieza tu historia.»

- 🎬 **Cabecera del capítulo (cinemática) «Adulto_Llegada»** _(vuelo de cámara, 11 s, 1 planos; música: VidaAdulta)_
  - 🪧 _Rótulo:_ «Una nueva vida en Valmar» — Valmar: donde el valle se encuentra con el mar. Aquí empieza tu historia.
  - _Narrador:_ _Aquí empieza tu vida adulta. ¿Qué harás con ella?_

### Adulto_LlegadaValmar · «Llegar a Valmar»

**Resumen:** Acabas de llegar a Valmar para empezar una vida nueva. Necesitas un sitio donde vivir y algo que comer.

**Pasos:**

- **Paso 1 · Ir a** la Plaza Mayor — «Ve a la Plaza Mayor»
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Adulto_Bienvenida»** _(música: → Descubrimiento)_
    - _En escena:_ Ernesto, Chef Lola · _entran andando:_ Ernesto, Chef Lola · _salen:_ Ernesto, Chef Lola
    - _Cámara:_ 1 planos (General)
    - **Ernesto:** ¡Eh! ¡Cara nueva! Yo conozco todas las caras de Valmar… y todos los perros. _[plano PrimerPlano de Ernesto · gesto Happy · silencio 4.4 s]_
    - **Ernesto:** ¿Recién llegado/a? Para recibir cartas hace falta buzón. Y para buzón, casa. Busca los carteles de «Se vende». _[plano DosPlanos de Ernesto → Tú · ademán Point]_
    - **Chef Lola:** ¡Ernesto, no le agobies, que acaba de llegar! _[plano Medio de Chef Lola · gesto HandsOnHips · silencio 0.8 s]_
    - **Chef Lola:** Soy Lola, la de la cafetería. Cuando tengas hambre, ven. La primera, invita la casa. _[plano PrimerPlano de Chef Lola]_
    - **Ernesto:** Y si buscas trabajo, Correos siempre necesita piernas. ¡Bienvenido/a a Valmar! _[plano DosPlanos de Ernesto → Chef Lola · ademán Wave]_
- **Paso 3 · Acción del jugador** — «Busca un cartel de SE VENDE y consigue tu casa» _(solo si NO tienes la marca «tiene hogar»)_
- **Paso 4 · Acción del jugador** — «Come algo: el viaje ha sido largo»
  - _Lugar:_ la Cafetería Central · _En escena:_ Chef Lola
  - ⏰ _Si tardas, Chef Lola dice:_ «(mensaje) La primera invita la casa. Cafetería de la plaza. No me hagas ir a buscarte.»

**Al terminar (momento de la biografía):** «Ya tienes un hogar en Valmar.»

---

### Adulto_PrimerSueldo · «Ganarte la vida»

**Resumen:** Para vivir en Valmar hace falta dinero. Busca un trabajo y gánate tu primer sueldo.

**Requisitos:** has terminado «Llegar a Valmar»

**Pasos:**

- **Paso 1 · Acción del jugador** — «Busca un cartel de SE BUSCA y trabaja (0/3)»
  - _Lugar:_ Correos · _En escena:_ Ernesto
  - ⏰ _Si tardas, Ernesto dice:_ «(mensaje) Correos siempre necesita piernas. El tablón «Trabajar» está en la puerta. Ernesto.»

**Al terminar (momento de la biografía):** «Has cobrado tu primer sueldo en Valmar.»

---

### Adulto_ConoceLaRegion · «Conoce la región»

**Resumen:** Valmar es mucho más que el centro. Elige a dónde ir de excursión y descubre la región.

**Requisitos:** has terminado «Ganarte la vida»

**Pasos:**

- **Paso 1 · Decisión** — «Decide adónde irás en tu primer día libre»
  - ❓ **Pregunta:** Tienes un día libre. ¿Qué te apetece descubrir?
  - ➤ **Opción «La universidad y el campus»** _(efecto: decisión «primera excursion» = Campus)_
  - ➤ **Opción «La playa y el paseo marítimo»** _(efecto: decisión «primera excursion» = Playa)_
  - ➤ **Opción «El campo y las granjas»** _(efecto: decisión «primera excursion» = Campo)_
- **Paso 2 · Ir a** la parada del autobús — «Ve a la parada del autobús»
- **Paso 3 · Ir a** la Universidad de Valmar — «Viaja en autobús y llega a la Universidad de Valmar» _(solo si en «primera excursion» elegiste «Campus»)_
- **Paso 4 · Ir a** Playa Dorada — «Viaja en autobús y llega a Playa Dorada» _(solo si en «primera excursion» elegiste «Playa»)_
- **Paso 5 · Ir a** las granjas de Villaverde — «Viaja en autobús y llega a las granjas de Villaverde» _(solo si en «primera excursion» elegiste «Campo»)_

**Al terminar (momento de la biografía):** «Hoy has descubierto un rincón nuevo de Valmar.»

---

**Texto de cierre del capítulo:** «Valmar ya es tu ciudad.»

- 🎬 **Final del capítulo (cinemática) «Adulto_TuCiudad»** _(vuelo de cámara, 9 s, 1 planos; música: TemaValmar)_
  - 🪧 _Rótulo:_ «Valmar ya es tu ciudad.»

## Comprobación

- Misiones principales exportadas: 68 (prólogo, capítulos y saga).
- Frases de diálogo en los datos de esas misiones: 2368; en sus 68 escenas de cámara: 547; total: 2915.
- Frases exportadas (cada una una vez): 2915. Sin exportar: 0.
- Preguntas al jugador: 127 exportadas de 127 en los datos. Comentarios sueltos y avisos: 40 exportados de 40.
