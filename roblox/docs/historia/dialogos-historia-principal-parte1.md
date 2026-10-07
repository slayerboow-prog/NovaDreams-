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

**Este guion va en varias partes porque es muy largo.** Esta es la PARTE 1 de 5. Analiza ya esta parte con las instrucciones de arriba (empieza por sus mejoras más importantes). Después te pasaré las siguientes: analiza cada una igual, recordando lo anterior para la coherencia. En la última parte, termina con un resumen global de las 10 mejoras más importantes de todo el juego.

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
