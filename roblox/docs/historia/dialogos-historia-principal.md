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
  - 🎬 **Cinemática «Prologo_G1»** _(música: → Descubrimiento)_
    - _En escena:_ Cosme
    - _Cámara:_ 13 planos (General, Hombro, Reaccion)
    - _Narrador:_ _Bienvenido/a a Valmar._
    - _Narrador:_ _Aquí vas a vivir una vida entera._
    - _Narrador:_ _Habrá días fáciles. Y otros que no lo serán tanto._
    - _Narrador:_ _Y hay algo que nadie debería haber visto._
    - _Narrador:_ _La Grieta._
    - **Cosme:** Otra vez no…
    - **Cosme:** Esta vez sí que la he liado. _[emoción Nervous]_
    - _Narrador:_ _Pero antes de que empiece tu vida…_
    - _Narrador:_ _alguien lleva tiempo esperándote._
  - 🎬 **Escena al completarlo «Prologo_G2_Entra»** _(música: → Descubrimiento)_
    - _Narrador:_ _No sabes dónde estás. Pero sabes que tienes que acercarte._
- **Paso 2 · Ir a** El círculo de luz — «Camina hasta el círculo de luz»
  - 🎬 **Escena al completarlo «Prologo_G3_Entra»** _(música: → Tension)_
    - _Narrador:_ _Algo te está esperando._
- **Paso 3 · Acción del jugador** — «¡Corre! Algo brilla al fondo»
- **Paso 4 · Ir a** Detrás de la valla de flores — «Salta la valla de flores»
  - 🎬 **Escena al completarlo «Prologo_G4_Fin»**
    - _En escena:_ Cosme
    - **Cosme:** Vaya. Has llegado.
- **Paso 5 · Hablar** con Cosme — «Habla con el señor de la bata»
  - **Cosme:** Llegas pronto. _[plano Medio de Cosme · gesto Thinking]_
    - 🎬 **Escena de cámara «Prologo_G5_Musica»** _(música: → Tension)_
  - **Cosme:** O tarde. _[plano Reaccion de Cosme · silencio 0.6 s]_
  - **Cosme:** En los sueños nunca se sabe. _[plano PrimerPlano de Cosme · gesto Happy]_
  - **Cosme:** Cosme. Inventor. Vecino. _[plano Medio de Cosme · ademán Point]_
  - **Cosme:** Y sí. Sé que todavía no nos conocemos. _[plano Reaccion de Cosme]_
  - **Cosme:** Pero nos vamos a conocer. _[plano Hombro de Cosme → Tú]_
  - **Cosme:** ¿La ves? _[plano General]_
  - **Cosme:** Esa cosa no debería estar ahí. _[plano General]_
  - **Cosme:** Se llama la Grieta. _[plano PrimerPlano de Cosme · gesto Sad]_
  - **Cosme:** (susurrando) Y creo que sé por qué está ahí. _[plano PPP de Cosme]_
  - **Cosme:** Por mi culpa. _[plano Reaccion de Cosme]_
  - **Cosme:** Bueno… En parte. _[plano Reaccion de Cosme · silencio 0.6 s]_
  - **Cosme:** Un poquito. _[plano Hombro de Cosme → Tú · gesto Shrug]_
  - **Cosme:** Bastante. _[plano PPP de Cosme]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Yo te ayudo a arreglarla!» _(efecto: valentia +1; decisión «prologo» = Ayudar)_
      - **Cosme:** ¿Tú quieres ayudarme? Eso sí que no me lo esperaba. _[plano PrimerPlano de Cosme]_
    - ➤ «¿Y eso es peligroso?» _(efecto: curiosidad +1; decisión «prologo» = Preguntar)_
      - **Cosme:** ¿Peligroso? Bueno… depende de cuánto te guste estar entero. _[plano PrimerPlano de Cosme]_
  - **Cosme:** Tranquilo/a. Todavía no tienes que preocuparte. _[plano Reaccion de Cosme · gesto Happy]_
  - **Cosme:** Antes de despertar, necesito que hagas una cosa. _[plano General]_
  - **Cosme:** Coge ese tornillo. _[plano General]_
  - **Cosme:** Y guárdalo. _[plano PrimerPlano de Cosme · gesto Thinking]_
  - **Cosme:** Es importante. _[plano Reaccion de Cosme · gesto Calm]_
  - **Cosme:** Creo. _[plano PPP de Cosme · silencio 0.6 s]_
  - **Cosme:** Cuando despiertes, probablemente no recordarás nada. _[plano Hombro de Cosme → Tú]_
  - **Cosme:** Bueno… Casi nada. _[plano Reaccion de Cosme · gesto Happy]_
- **Paso 6 · Usar** — «Recoge el tornillo que brilla»
  - 🎬 **Escena al completarlo «Prologo_G7_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Cosme
    - _Narrador:_ _El sueño empieza a desaparecer._
    - **Cosme:** Si alguna vez recuerdas esto…
    - **Cosme:** No.
    - **Cosme:** Mejor olvídalo.
    - **Cosme:** Nos veremos pronto.
  - 🖐 _Al usar «Un tornillo que brilla»:_
    - **Cosme:** Eso es. _[plano General]_
    - **Cosme:** Espera. _[plano Reaccion de Cosme · gesto Surprised]_
    - **Cosme:** No. Eso no estaba previsto. _[plano Reaccion de Cosme · gesto Surprised]_
    - _Narrador:_ _Durante un segundo, algo pareció cambiar._ _[plano General]_
    - _Narrador:_ _Después, todo volvió a la normalidad._
- **Paso 7 · Ir a** La puerta del garaje — «Sigue las flechas azules del suelo hasta la puerta del garaje»
  - 🎬 **Escena al completarlo «Prologo_G8_Entra»** _(música: → Intima)_
    - _Narrador:_ _Algo te dice que debes abrirla._
    - _Narrador:_ _Y aunque todavía no lo sabes…_
    - _Narrador:_ _acabas de dar tu primer paso._
- **Paso 8 · Acción del jugador** — «Abre el mapa de Valmar»
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Prologo_G9»** _(música: → Intima)_
    - _Cámara:_ 10 planos (Inserto, PrimerPlano)
    - 🪧 _Rótulo:_ «⭐ Tu vida» — La historia principal: crecer, estudiar, trabajar… y querer a los tuyos.
    - 🪧 _Rótulo:_ «🌀 Misiones locas» — Aventuras rarísimas con Cosme, tu vecino inventor.
    - 🪧 _Rótulo:_ «❗ La Saga de la Grieta» — Busca el ❗ dorado en el mapa: ahí sigue el misterio.
    - _Narrador:_ _Aquí empieza tu vida._
    - _Narrador:_ _Crecerás. Aprenderás. Te equivocarás._
    - _Narrador:_ _Y conocerás personas que cambiarán tu historia._
    - _Narrador:_ _Algunas cosas las recordarás. Otras no._
    - _Narrador:_ _Pero alguien recordará por ti._
    - _Narrador:_ _El sueño termina. Tu vida comienza._

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
  - 🎬 **Escena al completarlo «Bebe_Caminar_G1_2_Fin»** _(música: → Descubrimiento)_
    - _Narrador:_ _Y así empieza._
    - _Narrador:_ _Sin recuerdos. Sin planes._
    - _Narrador:_ _Sin saber todavía lo grande que puede ser el mundo._
    - _Narrador:_ _Solo una curiosidad. Saber qué hay ahí fuera._
    - _Narrador:_ _Aprende a moverte._
    - _Narrador:_ _No hace falta correr. Solo dar un paso._
- **Paso 2 · Acción del jugador** — «Da tus primeros pasos»
  - 🎬 **Escena al completarlo «Bebe_Caminar_G3_4_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _Narrador:_ _Uno._
    - _Narrador:_ _Dos._
    - _Narrador:_ _Y de repente…_
    - _Narrador:_ _el mundo está un poco más cerca._
    - _Narrador:_ _Descubrimiento número uno._
    - _Narrador:_ _Definitivamente merece otra prueba._
    - _Narrador:_ _Pero hay algo más interesante._
    - _Narrador:_ _Para alguien tan pequeño…_
    - _Narrador:_ _una casa puede parecer un mundo entero._
- **Paso 3 · Hablar** con Abu — «Llega hasta Abu»
  - _Lugar:_ Abu
  - 🎬 **Escena al completarlo «Bebe_Caminar_G5_6_Fin»**
    - _Narrador:_ _Todavía no sabes quiénes son._
    - _Narrador:_ _Pero un día recordarás esta imagen._
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Bebe_PrimerosPasosAbu»** _(música: → Intima → Descubrimiento efecto PrimerosPasos)_
    - _En escena:_ Mamá/Papá
    - _Cámara:_ 30 planos (General, Reaccion, Seguir, PrimerPlano, Hombro, Medio, Inserto, Dolly, PPP, Pan)
    - **Mamá/Papá:** ¡Pero bueno! _[emoción Joy]_
    - **Mamá/Papá:** ¿Cómo has llegado hasta aquí?
    - **Mamá/Papá:** ¿Ya estás caminando?
    - **Mamá/Papá:** No puede ser. _[emoción Joy]_
    - **Mamá/Papá:** Ven aquí.
    - **Mamá/Papá:** Vamos.
    - **Mamá/Papá:** Eso es. Un paso más. _[emoción Joy]_
    - **Mamá/Papá:** ¡Lo has hecho!
    - **Mamá/Papá:** Mi pequeño/a explorador/a. _[emoción Joy]_
    - **Mamá/Papá:** Parece que ayer no podías ni levantar la cabeza.
    - **Mamá/Papá:** Y ahora ya quieres conquistar la casa.
    - **Mamá/Papá:** Vas a crecer demasiado rápido.
    - **Mamá/Papá:** Prométeme una cosa. _[emoción Joy]_
    - **Mamá/Papá:** No tengas prisa.
    - **Mamá/Papá:** Disfruta cada paso.
    - _Narrador:_ _Todavía no lo sabes. Pero algún día recordarás estas palabras._
    - _Narrador:_ _Y mientras tú das tus primeros pasos…_
    - _Narrador:_ _el mundo sigue avanzando._
    - _Narrador:_ _Aunque algunas cosas…_
    - _Narrador:_ _ya te estaban esperando._

**Al terminar (momento de la biografía):** «Has dado tus primeros pasos.»

---

### Bebe_ExploraLaCasa · «Explora tu casa»

**Resumen:** Ya caminas. Tu casa está llena de cosas nuevas: la cocina, la tele, los juguetes… y tu familia quiere enseñártelas.

**Requisitos:** has terminado «Aprende a caminar»

**Pasos:**

- **Paso 1 · Varios objetivos (en cualquier orden)** — «Recorre la casa»
  - **Paso 1.1 · Ir a** la cocina — «Mira la cocina»
    - 🎬 **Escena al completarlo «Bebe_Casa_G1_1_1_Fin»** _(música: → Descubrimiento)_
      - _Narrador:_ _Ya sabes caminar._
      - _Narrador:_ _Ahora toca descubrir para qué sirve todo lo demás._
      - _Narrador:_ _Este lugar huele bien._
      - _Narrador:_ _Y parece que aquí ocurre algo importante._
      - _Narrador:_ _Primera lección de la vida:_
      - _Narrador:_ _no todo lo que puedes tocar es un juguete._
  - **Paso 1.2 · Acción del jugador** — «Mira la tele del salón»
    - 🎬 **Escena al completarlo «Bebe_Casa_G1_2_Fin»**
      - _Narrador:_ _Y esto… ¿para qué sirve?_
      - _Narrador:_ _Misterio resuelto. Probablemente._
  - **Paso 1.3 · Acción del jugador** — «Juega con tus bloques en tu habitación»
    - 🎬 **Escena al completarlo «Bebe_Casa_G1_3_Fin»**
      - _Narrador:_ _Buena decisión._
      - _Narrador:_ _Casi perfecta._
- **Paso 2 · Hablar** con Mamá/Papá — «Tienes hambre: pide el biberón a tu familia en la cocina»
  - _Lugar:_ tu familia
  - 🎬 **Escena al completarlo «Bebe_Casa_G2_Fin»** _(música: → Intima)_
    - _En escena:_ Mamá/Papá
    - _Cámara:_ 13 planos (General, Reaccion, Seguir, Hombro, Inserto, Medio, PrimerPlano)
    - **Mamá/Papá:** Vaya, vaya. ¿Otra vez de excursión?
    - **Mamá/Papá:** Ya has recorrido media casa.
    - **Mamá/Papá:** ¿Tienes hambre?
    - **Mamá/Papá:** Eso me parecía.
    - **Mamá/Papá:** Aquí tienes, pequeño/a explorador/a.
    - **Mamá/Papá:** Primero aprendiste a caminar.
    - **Mamá/Papá:** Ahora ya quieres conocer toda la casa.
    - **Mamá/Papá:** Como sigas así, mañana te vas a querer escapar por la puerta. _[emoción Joy]_
    - **Mamá/Papá:** No. Ni se te ocurra.
    - _Narrador:_ _La casa ya no parece tan grande._
    - _Narrador:_ _Pero fuera hay un mundo entero esperando._

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
  - **Mamá/Papá:** Buenos días, [tu nombre]. _[plano Seguir de Mamá/Papá]_
    - 🎬 **Escena de cámara «Cole01_G1_Musica»** _(música: → Descubrimiento)_
  - **Mamá/Papá:** Arriba. Hoy empieza el colegio. _[plano Reaccion de Tú]_
  - **Tú:** ¿Hoy? _[plano PrimerPlano de Tú]_
  - **Mamá/Papá:** Hoy.
  - **Mamá/Papá:** Mochila nueva. Profe nueva. Compañeros nuevos. _[plano Medio de Mamá/Papá · gesto Happy]_
  - **Mamá/Papá:** Y probablemente alguna aventura que no tenemos prevista.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Cinco minutitos más…» _(efecto: humor +1)_
      - **Mamá/Papá:** Cinco minutitos… Eso decía yo a tu edad.
      - **Mamá/Papá:** Y siempre llegaba tarde.
    - ➤ «¡Ya voy! ¡Ya voy!» _(efecto: responsabilidad +1)_
      - **Mamá/Papá:** Así me gusta.
    - ➤ «¿Y si no voy? Me duele… la tripa.» _(efecto: humor +1)_
      - **Mamá/Papá:** Qué casualidad. Justo hoy. Eso son nervios. _[plano PrimerPlano de Mamá/Papá]_
      - **Mamá/Papá:** Se pasan cuando llegas.
  - 🎬 **Escena al completarlo «Cole01_G2_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Mamá/Papá
    - _Narrador:_ _Los Pinos. Primera hora de la mañana._
    - _Narrador:_ _Hoy no es un día cualquiera._
    - _Narrador:_ _Prepárate para el colegio._
    - _Narrador:_ _Estiras la sábana. Colocas la almohada. No está perfecta._
    - _Narrador:_ _Pero es tu primera cama hecha._
    - **Mamá/Papá:** ¿La has hecho tú solo/a?
    - **Mamá/Papá:** Hoy es un día histórico.
    - _Narrador:_ _Antes de conocer a nadie…_
    - _Narrador:_ _tienes que decidir cómo quieres presentarte._
    - _Narrador:_ _Perfecto._
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
      - ❓ **Pregunta al jugador:** ¿Qué te pones?
        - ➤ «Camiseta de dinosaurios.» _(efecto: humor +1; decisión «ropa» = Dinosaurios)_
          - **Tú:** El T-Rex me da poderes.
          - **Tú:** Es un hecho científico. _[silencio 0.9 s]_
        - ➤ «Sudadera azul del colegio.» _(efecto: responsabilidad +1; decisión «ropa» = Sudadera)_
          - **Tú:** Con el escudo del cole.
          - **Tú:** Así ya parezco de allí.
        - ➤ «Camisa elegante.» _(efecto: decisión «ropa» = Camisa)_
          - **Tú:** Impecable. Aunque pica un poquito el cuello.
  - **Paso 2.2 · Usar** — «Prepara la mochila»
    - 🖐 _Al usar «Tu mochila nueva»:_
      - _Narrador:_ _Estuche. Cuaderno. Lápices._ _[plano General]_
      - _Narrador:_ _Y algo que llevas contigo desde hace tiempo._ _[plano General]_
      - ❓ **Pregunta al jugador:** ¿Te llevas el cromo?
        - ➤ «¡Claro! Me llevo el cromo.» _(efecto: marca «lleva cromo»; objeto cromo suerte)_
          - **Tú:** Al bolsillo pequeño. Para emergencias.
        - ➤ «Mejor no. No quiero perderlo.» _(efecto: responsabilidad +1)_
          - **Tú:** Se queda aquí. A salvo.
  - **Paso 2.3 · Usar** — «Desayuna en la cocina»
    - 🖐 _Al usar «Desayuno»:_
      - **Mamá/Papá:** Siéntate. Que se enfría. _[plano General]_
      - ❓ **Pregunta al jugador:** Para desayunar…
        - ➤ «Tostadas con tomate.»
          - **Mamá/Papá:** Como tu abu. Con su chorrito de aceite.
        - ➤ «Cereales con leche.»
          - **Tú:** Los del dinosaurio.
        - ➤ «Fruta… y un poquito de chocolate.» _(efecto: humor +1)_
          - **Mamá/Papá:** Un poquito. POQUITO. Y bebe algo.
          - **Mamá/Papá:** En el colegio se corre mucho.
- **Paso 3 · Hablar** con Mamá/Papá — «Dile a mamá/papá que ya lo tienes todo»
  - **Tú:** ¡Listo! _[plano Medio de Tú]_
    - 🎬 **Escena de cámara «Cole01_G3_Musica»** _(música: → Intima)_
  - **Tú:** Ropa. _[plano General]_
  - **Tú:** Mochila. _[plano General]_
  - **Tú:** Desayuno. Todo. _[plano General]_
  - **Mamá/Papá:** A ver.
  - _(si en «ropa» elegiste «Camisa»)_ **Mamá/Papá:** Qué elegancia.
  - _(si en «ropa» elegiste «Dinosaurios»)_ **Mamá/Papá:** Con los dinosaurios. Muy tú.
  - _(si en «ropa» elegiste «Sudadera»)_ **Mamá/Papá:** Con la sudadera del cole. Pareces de sexto.
  - _(si tienes la marca «llegas tarde»)_ **Mamá/Papá:** Aunque…
  - **Mamá/Papá:** Mira qué hora es. ¡Corre! _[plano PrimerPlano de Mamá/Papá]_
  - **Mamá/Papá:** El colegio está cerca.
  - **Mamá/Papá:** ¿Quieres que te acompañe?
  - ❓ **Pregunta al jugador:** ¿Vas por tu cuenta o con compañía?
    - ➤ «Sí, acompáñame, porfa.» _(efecto: Mamá/Papá +3; decisión «acompanante» = Familia)_
      - **Mamá/Papá:** Claro. Pero en la puerta me das un beso rapidito.
      - **Mamá/Papá:** Que ya sé que da vergüenza.
    - ➤ «¡Voy yo solo, que ya soy mayor!» _(efecto: valentia +1; decisión «acompanante» = Solo)_
      - **Mamá/Papá:** Vale. Que ya eres mayor. Ve por la acera. Y sigue la luz.
      - **Mamá/Papá:** Te miro desde la ventana.
  - 🎬 **Escena al completarlo «Cole01_G4_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Mamá/Papá
    - _Narrador:_ _Primer día. Primera mochila._
    - _Narrador:_ _Primer camino al colegio._
    - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** ¿Nervioso?
    - _(si en «acompanante» elegiste «Familia»)_ **Tú:** Un poco.
    - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** Normal.
- **Paso 4 · Ir a** Camino al cole — «Ve hacia el colegio (sigue la luz)»
  - _Lugar:_ Camino al cole · _En escena:_ Mamá/Papá (si en «acompanante» elegiste «Familia») (te acompaña), Dani
- **Paso 5 · Escena**
  - **Dani:** ¡Eh! ¡EH! _[plano Seguir de Dani]_
    - 🎬 **Escena de cámara «Cole01_G5_Musica»** _(música: → Descubrimiento)_
  - **Dani:** ¡Ese es mi balón! ¿Me lo pasas? ¡Porfa, porfa, porfa! _[plano Medio de Dani]_
  - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** Venga. Pásaselo. Pero con cuidado. Es pequeñito.
- **Paso 6 · Minijuego** — «Pásale el balón a Dani.»
  - 🎮 _Cómo se juega:_ Pulsa cuando la aguja esté en la zona verde
- **Paso 7 · Escena**
  - _(si tienes la marca «pase a dani»)_ **Dani:** ¡HALA!
    - 🎬 **Escena de cámara «Cole01_G7_Musica»** _(música: → Descubrimiento)_
  - _(si tienes la marca «pase a dani»)_ **Dani:** ¡Qué pase! ¡Eres como los de la tele! _[plano Reaccion de Tú]_
  - _(si tienes la marca «fallaste pase»)_ **Dani:** Jajaja. Se ha ido a la farola. No pasa nada. ¡Ya lo cojo yo! _[plano General]_
  - **Dani:** Me llamo Dani. Tengo cinco años y MEDIO. _[plano Medio de Dani]_
  - **Dani:** Mi hermano Mateo también empieza hoy en tu cole. Es un poco… vergonzoso. No habla casi. _[plano PrimerPlano de Dani]_
  - **Dani:** Si lo ves… dile que Dani dice que se ría más. _[plano Reaccion de Tú]_
  - **Dani:** ¡Adiós! _[plano Seguir de Dani]_
  - _Narrador:_ _Primer nombre nuevo. Primer encuentro._ _[plano Reaccion de Tú]_
  - _Narrador:_ _Y todavía no sabes que Mateo será importante._
  - 🎬 **Escena al completarlo «Cole01_G8_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Mamá/Papá
    - _Narrador:_ _Los Pinos. Tu colegio._
    - **Mamá/Papá:** Pórtate bien, ¿eh? ¡Y come la fruta!
- **Paso 8 · Ir a** el colegio — «Llega a la entrada del colegio»
  - _Lugar:_ el colegio · _En escena:_ Ramón, Alumno, Alumna, Alumno de 6.º, Una madre, Un padre, Mamá/Papá (si en «acompanante» elegiste «Familia») (te acompaña)
  - 💬 _Comentario al pasar cerca de Un padre:_ «Pórtate bien, ¿eh? ¡Y come la fruta!»
- **Paso 9 · Escena**
  - _Narrador:_ _Mochilas. Abrazos. Gritos._ _[plano General]_
    - 🎬 **Escena de cámara «Cole01_G9_Musica»** _(música: → Intima)_
  - _Narrador:_ _Y muchísimas caras que todavía no conoces._
  - **Ramón:** ¡Buenos días! ¡Los mayores por la izquierda! _[plano Medio de Ramón]_
  - **Ramón:** ¡Los de primero por la puerta grande!
  - **Ramón:** Uy. ¿Y tú? _[plano Reaccion de Ramón]_
  - **Ramón:** Cara nueva. Soy Ramón. El conserje. _[plano Medio de Ramón]_
  - **Ramón:** Si algo se rompe, se pierde o se atasca… Ramón.
  - _(si tienes la marca «llegas tarde»)_ **Ramón:** ¿Llegando tarde el primer día?
  - _(si tienes la marca «llegas tarde»)_ **Ramón:** Tranquilo/a. Lo apunto en mi libreta de secretos. Jejeje. _[plano PrimerPlano de Ramón]_
  - _(si en «acompanante» elegiste «Familia»)_ **Mamá/Papá:** Bueno… Aquí te dejo. Pásalo genial. Y me lo cuentas TODO. _[plano Hombro de Tú → Mamá/Papá]_
  - **Ramón:** Tu tutora es Lucía. Jersey amarillo. _[plano Reaccion de Tú]_
  - **Ramón:** Y una risa que se oye desde aquí.
- **Paso 10 · Hablar** con Profe Lucía — «Busca a tu tutora: lleva un jersey amarillo»
  - _Lugar:_ Pasillo · _En escena:_ Profe Lucía, Andrés, Marta, Ramón
  - **Profe Lucía:** Hola. _[plano Reaccion de Profe Lucía]_
    - 🎬 **Escena de cámara «Cole01_G10_Musica»** _(música: → Descubrimiento)_
  - **Profe Lucía:** Tú debes de ser [tu nombre]. Soy Lucía. Tu tutora de 1.º A. _[plano Medio de Profe Lucía]_
  - _(si NO tienes la marca «llegas tarde»)_ **Profe Lucía:** Ya estás aquí. Buena señal.
  - _(si tienes la marca «llegas tarde»)_ **Profe Lucía:** Un poquito tarde, ¿eh? Hoy te lo perdono. _[plano PrimerPlano de Profe Lucía]_
  - _(si tienes la marca «llegas tarde»)_ **Profe Lucía:** Mañana, un poco antes.
  - _(si tienes la marca «llegas tarde»)_ **Ramón:** Apuntado en mi libreta, Lucía.
  - **Profe Lucía:** Antes de empezar… _[plano Reaccion de Profe Lucía]_
  - **Profe Lucía:** Tengo una misión para ti. Conoce el colegio. _[plano Hombro de Tú → Profe Lucía]_
  - **Profe Lucía:** Biblioteca. Comedor. Patio. Gimnasio. Campo. Todo. _[plano General]_
  - **Profe Lucía:** Por el camino encontrarás gente. Y después…
  - **Profe Lucía:** Encuentra tu aula tú solo/a. 1.º A. _[plano PrimerPlano de Profe Lucía]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Hecho! Me encanta explorar.» _(efecto: Profe Lucía +3; valentia +1)_
      - **Profe Lucía:** Eso quiero ver. Suerte.
    - ➤ «¿Y si me pierdo?» _(efecto: Profe Lucía +3)_
      - **Profe Lucía:** Entonces preguntas. Preguntar no es de perdidos. Es de listos.
      - **Andrés:** ¿Yo, tu tutor? ¡Ojalá! Soy Andrés. Educación Física.
      - **Andrés:** Me reconocerás por el silbato.
      - **Andrés:** Y no corras por el pasillo. Todavía.
      - **Marta:** Hola, cielo. Soy Marta.
      - **Marta:** Ese piano del fondo es mío. ¿Buscas a Lucía? _[plano General]_
      - **Marta:** La del jersey amarillo. No tiene pérdida.
  - 🗨 _Charla opcional con Andrés (si te acercas a hablar):_
    - **Andrés:** ¿Yo, tu tutor? ¡Ojalá! Soy Andrés, el de Educación Física. Me verás con silbato.
    - **Andrés:** Lucía es la del jersey amarillo. Y no corras por el pasillo… todavía.
  - 🗨 _Charla opcional con Marta (si te acercas a hablar):_
    - **Marta:** Hola, cielo. Soy Marta, la profe de música. El piano del fondo es mío.
    - **Marta:** ¿Buscas a Lucía? Mira: la amarilla que se está riendo. No tiene pérdida.
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Conoce el colegio.»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Iker, Vega, Ramón
  - 🎬 **Escena al completarlo «Cole01_G12_Entra»** _(música: → Descubrimiento)_
    - _Narrador:_ _1.º A._
  - **Paso 11.1 · Ir a** Biblioteca del cole — «La biblioteca»
  - **Paso 11.2 · Ir a** Comedor — «El comedor»
  - **Paso 11.3 · Ir a** el patio — «El patio»
  - **Paso 11.4 · Ir a** Gimnasio — «El gimnasio»
  - **Paso 11.5 · Ir a** Campo de fútbol — «El campo de fútbol»
  - **Paso 11.6 · Hablar** con Iker — «Habla con el niño de las gafas (biblioteca)»
    - **Iker:** Shhh. Es la biblioteca. _[plano General]_
    - **Iker:** Soy Iker. Dato curioso. _[plano PrimerPlano de Iker]_
    - **Iker:** Aquí hay más de dos mil libros.
    - **Iker:** Me he leído cuarenta y siete. _[silencio 0.9 s]_
    - ❓ **Pregunta al jugador:** ¿Qué le contestas?
      - ➤ «¡Qué listo eres!» _(efecto: Iker +5)_
        - **Iker:** Ya lo sé. Digo… Gracias.
      - ➤ «¿Cuánto mide una pista de tenis?» _(efecto: Iker +3; curiosidad +1)_
        - **Iker:** ¡Veintitrés metros y setenta y siete centímetros!
        - **Iker:** Por fin alguien pregunta. _[plano Reaccion de Iker]_
  - **Paso 11.7 · Hablar** con Vega — «Habla con la niña de las pegatinas (comedor)»
    - **Vega:** ¿Te gustan las pegatinas?
    - **Vega:** Esta brilla en la oscuridad. _[plano General]_
    - **Vega:** Y esta huele a fresa. Consejo de experta. _[plano General]_
    - **Vega:** Los jueves hay macarrones.
    - **Vega:** Y nunca te sientes en la mesa de sexto. _[silencio 0.9 s]_
  - **Paso 11.8 · Hablar** con Ramón — «Habla con Ramón, el conserje (puerta del gimnasio)»
    - **Ramón:** ¡Anda! ¡La exploración oficial!
    - **Ramón:** Esto es el gimnasio. _[plano General]_
    - **Ramón:** Y al fondo está el almacén. _[plano General]_
    - **Ramón:** Ahí no se entra sin permiso. Balones. Colchonetas. _[plano General]_
    - **Ramón:** Y cosas que llevan años ahí dentro. Si pierdes algo…
    - **Ramón:** Pregúntame. Yo encuentro de todo. _[plano PrimerPlano de Ramón]_
- **Paso 12 · Ir a** Aula de 1.º A — «Encuentra el aula 1.º A.»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Vega, Omar, Álex, Bruno, Rubén, Mateo, Hugo, Nico
- **Paso 13 · Cinemática**
  - _Lugar:_ Tu pupitre
  - 🎬 **Cinemática «Cole01_Bienvenida»** _(música: → Descubrimiento)_
    - _En escena:_ Bruno, Profe Lucía, Nico, Sara
    - _Cámara:_ 11 planos (General, Hombro, Reaccion, Lateral, PrimerPlano, Medio, Pan)
    - _(si NO se cumple: tienes la marca «llegas tarde»)_ **Profe Lucía:** ¡Mirad quién ha encontrado el aula!
    - _(si tienes la marca «llegas tarde»)_ **Profe Lucía:** ¡Mirad quién ha encontrado el aula! Un poquito tarde…
    - _(si tienes la marca «llegas tarde»)_ **Profe Lucía:** Pero la ha encontrado.
    - **Profe Lucía:** Chicos, chicas. Hoy tenemos a alguien nuevo. Se llama [tu nombre].
    - **Nico:** ¿Juegas al fútbol? Necesitamos uno para el recreo.
    - **Sara:** Nico. Déjale llegar.
    - **Sara:** Hola. Soy Sara. Ya tengo hechos los deberes de mañana.
    - **Bruno:** Otro más. Como si no fuéramos ya muchos.
    - **Profe Lucía:** Bruno. Eso no se dice.
    - **Profe Lucía:** [tu nombre]. Busca sitio.
    - **Profe Lucía:** Elige bien. Es para todo el curso.
- **Paso 14 · Decisión** — «Elige dónde sentarte (las sillas brillantes)»
  - ➤ **Opción «Delante, junto a Sara»** _(efecto: decisión «asiento» = Sara; Sara +8; curiosidad +1)_
  - ➤ **Opción «Al fondo, junto a Nico»** _(efecto: decisión «asiento» = Nico; Nico +8; deportividad +1)_
  - ➤ **Opción «Junto al niño callado»** _(efecto: decisión «asiento» = Mateo; Mateo +8; empatia +1)_
- **Paso 15 · Escena** _(solo si en «asiento» elegiste «Sara»)_
  - _(si en «asiento» elegiste «Sara»)_ **Sara:** Has elegido bien. Aquí delante se entiende todo.
    - 🎬 **Escena de cámara «Cole01_G15_16_17_Musica»** _(música: → Descubrimiento)_
  - _(si en «asiento» elegiste «Sara»)_ **Sara:** Y la pizarra no tiene reflejos.
  - _(si en «asiento» elegiste «Nico»)_ **Nico:** ¡Bien! Desde aquí se ve la ventana y el campo. Si miras mucho… Lucía te pilla.
  - _(si en «asiento» elegiste «Mateo»)_ **Mateo:** …Hola. _[plano PrimerPlano de Mateo]_
  - _(si en «asiento» elegiste «Mateo»)_ **Rubén:** Psst. Te has sentado en la fila de los guays. Jejeje. _[plano Reaccion de Rubén]_
  - _(si en «asiento» elegiste «Mateo»)_ **Profe Lucía:** Vamos a presentarnos.
  - **Profe Lucía:** Cada uno dice su nombre y algo que le guste. _[plano General]_
  - **Profe Lucía:** [tu nombre]. Empiezas tú. _[plano PrimerPlano de Tú]_
  - ❓ **Pregunta al jugador:** Te toca. ¿Qué dices?
    - ➤ «Me encanta el fútbol.» _(efecto: decisión «gusto» = Futbol)_
      - **Nico:** ¡LO SABÍA! Recreo. Partido. Tú y yo.
    - ➤ «Me gusta dibujar.» _(efecto: decisión «gusto» = Dibujar)_
      - **Omar:** Mola.
    - ➤ «Me encantan los experimentos.» _(efecto: decisión «gusto» = Ciencia)_
      - **Sara:** ¿Experimentos de verdad? ¿Con volcanes? Tenemos que hablar.
    - ➤ «Me gusta… dormir cinco minutitos más.» _(efecto: humor +1; decisión «gusto» = Dormir)_
      - **Nico:** ¡Jajajaja!
      - **Profe Lucía:** Tomo nota para cuando llegues tarde. _[plano PrimerPlano de Profe Lucía]_
      - _(si tienes la marca «ensayo espejo»)_ **Profe Lucía:** Se nota que lo traías ensayado. Así da gusto. Muy bien. Y ahora…
      - **Profe Lucía:** Matemáticas. _[plano General]_
      - **Nico:** ¿Ya?
      - **Profe Lucía:** Ya.
  - _(si en «asiento» elegiste «Nico»)_ **Nico:** Luego te enseño el campo. _[plano Hombro de Tú → Nico]_
  - _(si en «asiento» elegiste «Nico»)_ **Profe Lucía:** Nico.
  - _(si en «asiento» elegiste «Nico»)_ **Nico:** Yo no he dicho nada.
  - _(si en «asiento» elegiste «Mateo»)_ **Mateo:** Si quieres… Luego te puedo enseñar dónde está el patio. _[plano Hombro de Tú → Mateo]_
  - _(si en «asiento» elegiste «Mateo»)_ **Mateo:** Dani dice que conoces el fútbol. _[plano PrimerPlano de Mateo]_
- **Paso 16 · Escena** _(solo si en «asiento» elegiste «Nico»)_
  - _(la misma conversación «Presentaciones» de arriba)_
- **Paso 17 · Escena** _(solo si en «asiento» elegiste «Mateo»)_
  - _(la misma conversación «Presentaciones» de arriba)_
  - 🎬 **Escena al completarlo «Cole01_G18_Entra»** _(música: → Descubrimiento)_
    - _Narrador:_ _Primeras clases. Primeras horas. Y poco a poco…_
    - _Narrador:_ _empiezas a descubrir quién es quién._
- **Paso 18 · Clase** — «Completa tu primera clase de Matemáticas.»
  - _Lugar:_ Aula de 1.º A
- **Paso 19 · Escena**
  - _Lugar:_ Tu pupitre
  - **Nico:** ¡Recreo! _[plano General]_
    - 🎬 **Escena de cámara «Cole01_G19_Musica»** _(música: → Descubrimiento)_
  - **Profe Lucía:** Quince minutos. Y nada de subirse a la valla, Nico. _[plano PrimerPlano de Profe Lucía]_
  - **Nico:** ¡Yo no he hecho nada! Todavía. _[plano Reaccion de Nico]_
  - 🎬 **Escena al completarlo «Cole01_G20_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Hugo, Álex, Iker, Vega, Rubén
    - **Rubén:** Jejeje. Nada, nada.
    - **Hugo:** …Hola.
    - **Álex:** Si Nico dice que me ha metido gol… Miente.
    - **Vega:** Todas sus nubes tienen forma de bocadillo.
    - **Iker:** Bueno. Lo he leído en algún sitio.
- **Paso 20 · Ir a** el patio — «Sal al patio.»
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
- **Paso 21 · Decisión** — «Decide con quién pasar tu primer recreo.»
  - ➤ **Opción «Los deportistas (la cancha)»** (con Nico) _(efecto: decisión «grupo recreo» = Deportistas; Álex +6; Nico +6; deportividad +1)_
    - **Nico:** ¡Has venido! Esta es Álex. Es portera. Nadie le mete gol.
    - **Álex:** Nadie.
    - **Nico:** Bueno… Yo a veces.
    - **Álex:** Nunca.
    - _(si en «gusto» elegiste «Futbol»)_ **Nico:** Tú dijiste que te gusta el fútbol.
    - _(si en «gusto» elegiste «Futbol»)_ **Nico:** Mañana juegas con nosotros.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «Te apuesto a que yo sí te marco, Álex.» _(efecto: Álex +5; valentia +1; marca «apuesta alex»)_
        - **Álex:** Apuesta aceptada. El que pierda lleva los balones una semana.
      - ➤ «Yo mejor de defensa, que corro mucho.» _(efecto: Nico +5)_
        - **Nico:** ¡Alguien en defensa! ¡Justo lo que nos faltaba!
  - ➤ **Opción «Los artistas (la zona de juegos)»** (con Omar) _(efecto: decisión «grupo recreo» = Artistas; Omar +6; Vega +6; creatividad +1)_
    - **Omar:** Espera. No te muevas. Te estoy dibujando.
    - **Vega:** Omar dibuja a todo el mundo.
    - **Vega:** Es su forma de decir hola.
    - **Omar:** Ya está. Te he puesto una capa. _[plano General]_
    - **Omar:** Quedas mejor con capa.
    - _(si en «gusto» elegiste «Dibujar»)_ **Omar:** ¿Tú también dibujas? Mañana te dejo mi rotulador dorado.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «¡Hala! ¿Me lo regalas?» _(efecto: Omar +6)_
        - **Omar:** Cuando lo termine. Los dibujos buenos se terminan despacio.
      - ➤ «¿Y a Vega qué le has puesto?» _(efecto: Vega +5; humor +1)_
        - **Vega:** Alas. De mariposa. Evidentemente.
  - ➤ **Opción «Los curiosos (junto al edificio)»** (con Sara) _(efecto: decisión «grupo recreo» = Estudiantes; Iker +6; Sara +6; curiosidad +1)_
    - **Sara:** Estamos discutiendo una cosa importantísima.
    - **Sara:** ¿Las hormigas duermen? _[plano PrimerPlano de Sara]_
    - **Iker:** Sí. Doscientas cincuenta siestas de un minuto al día.
    - **Sara:** Eso hay que comprobarlo.
    - **Sara:** Experimentalmente. _[plano Reaccion de Sara]_
    - _(si en «gusto» elegiste «Ciencia»)_ **Sara:** Tú dijiste que te gustan los experimentos. Estás dentro.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «Yo vigilo el hormiguero con vosotros.» _(efecto: Iker +4; Sara +6; curiosidad +1)_
        - **Sara:** ¡Equipo científico formado! Mañana traigo lupa.
      - ➤ «¿Y los peces? ¿Los peces duermen?» _(efecto: Iker +6)_
        - **Iker:** No lo sé. Por primera vez en mi vida… NO LO SÉ. _[silencio 0.9 s]_
- **Paso 22 · Cinemática**
  - _En escena:_ Nico, Álex, Omar, Vega, Sara, Iker, Bruno, Rubén, Hugo, Mateo
  - 🎬 **Cinemática «Cole01_LibrosCaen»** _(música: → Tension)_
    - _En escena:_ Rubén, Bruno, Mateo
    - _Cámara:_ 11 planos (General, Seguir, Reaccion, PPP, PrimerPlano)
    - **Rubén:** ¡Jajajaja!
    - **Rubén:** ¡Mirad al nuevo número dos!
    - _Narrador:_ _Hay momentos en los que puedes mirar hacia otro lado. O puedes acercarte._
    - _(si tienes las marcas «pase a dani» y «lleva cromo»)_ **Tú:** El hermano de Dani. Y su álbum de cromos. Como el mío.
    - _(si tienes la marca «pase a dani» y NO tienes la marca «lleva cromo»)_ **Tú:** Es Mateo. El hermano de Dani. El del balón.
    - _(si tienes la marca «lleva cromo» y NO tienes la marca «pase a dani»)_ **Tú:** Ese álbum… Es de cromos. Como el mío.
- **Paso 23 · Varios objetivos (en cualquier orden)** — «Ayuda a Mateo a recoger sus cosas.»
  - **Paso 23.1 · Usar** — «Libro rojo»
  - **Paso 23.2 · Usar** — «Libro azul»
  - **Paso 23.3 · Usar** — «Cuaderno verde»
  - **Paso 23.4 · Usar** — «Álbum de cromos»
- **Paso 24 · Escena** _(solo si tienes la marca «ayudaste a mateo»)_
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** G-gracias. Nadie… Bueno. Gracias. _[plano Medio de Mateo · gesto Happy]_
    - 🎬 **Escena de cámara «Cole01_G24_Musica»** _(música: → Intima)_
  - _(si tienes las marcas «pase a dani» y «ayudaste a mateo»)_ **Mateo:** ¿Fuiste tú quien le pasó el balón a mi hermano?
  - _(si tienes las marcas «pase a dani» y «ayudaste a mateo»)_ **Mateo:** No para de hablar de ti.
  - _(si tienes las marcas «fallaste pase» y «ayudaste a mateo»)_ **Mateo:** Dani dice que alguien casi le da a una farola con su balón. ¿Fuiste tú?
  - _(si tienes las marcas «fallaste pase» y «ayudaste a mateo»)_ **Mateo:** Me llamo Mateo. Colecciono cromos. _[plano Reaccion de Mateo · gesto Happy]_
  - _(si tienes las marcas «fallaste pase» y «ayudaste a mateo»)_ **Mateo:** Tengo repetido el portero legendario. Por si… Por si lo quieres. _[plano General]_
  - _(si tienes las marcas «lleva cromo» y «ayudaste a mateo»)_ **Tú:** ¡Yo tengo ese cromo! Es mi cromo de la suerte.
  - _(si tienes las marcas «lleva cromo» y «ayudaste a mateo»)_ **Mateo:** ¿En serio?
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Entonces… Somos del mismo equipo. _[plano PrimerPlano de Mateo]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¿Mañana te sientas conmigo?» _(efecto: Mateo +8)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Vale.
    - ➤ «Tu hermano dice que te rías más.» _(efecto: Mateo +5; humor +1)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Jajaja… Dani siempre dice eso. Es un pesado. Pero tiene razón.
- **Paso 25 · Escena** _(solo si tienes la marca «ignoraste a mateo»)_
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Rubén:** Jejeje. El nuevo número dos. _[plano Reaccion de Rubén]_
    - 🎬 **Escena de cámara «Cole01_G25_Musica»** _(música: → Tension)_
  - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Mateo no dice nada._ _[plano General]_
  - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _A veces no hacer nada también deja una huella._ _[plano Seguir de Mateo]_
- **Paso 26 · Escena**
  - _En escena:_ Profe Lucía, Ramón
  - _Narrador:_ _Más clases._ _[plano General]_
    - 🎬 **Escena de cámara «Cole01_G26_Musica»** _(música: → Descubrimiento)_
  - _Narrador:_ _Más nombres._ _[plano General]_
  - _Narrador:_ _Y más preguntas de las que tenías esta mañana._ _[plano General]_
  - **Profe Lucía:** ¡Hasta mañana! Y recordad… _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** Mañana, con la mochila. _[silencio 0.9 s]_
  - **Ramón:** ¡O que la pierde! Jejeje. _[plano Reaccion de Ramón]_
  - 🎬 **Escena al completarlo «Cole01_G27_Entra»** _(música: → Descubrimiento)_
    - _Narrador:_ _Esta mañana no conocías a nadie._
    - _Narrador:_ _Ahora ya tienes algunos nombres._
    - _Narrador:_ _Y mañana… volverás a verlos._
- **Paso 27 · Ir a** tu casa familiar — «Vuelve a casa.»
- **Paso 28 · Escena**
  - _Lugar:_ la cocina · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Por fin! Siéntate. He hecho macarrones. _[plano Reaccion de Mamá/Papá]_
    - 🎬 **Escena de cámara «Cole01_G28_Musica»** _(música: → Intima)_
  - **Mamá/Papá:** ¿Y bien? ¿Qué tal tu primer día? _[plano Hombro de Tú → Mamá/Papá]_
  - **Abu:** Cuéntanoslo todo. Con detalles. _[plano PrimerPlano de Abu]_
  - **Abu:** Que yo ya no me entero de nada. _[silencio 0.9 s]_
  - _(si tienes la marca «llegas tarde»)_ **Mamá/Papá:** Y lo de llegar tarde…
  - _(si tienes la marca «llegas tarde»)_ **Mamá/Papá:** Mañana salimos cinco minutos antes. Los cinco minutitos. _[plano Reaccion de Tú]_
  - _(si en «ropa» elegiste «Dinosaurios»)_ **Abu:** ¿Y los dinosaurios? ¿Han causado sensación? _[plano Reaccion de Abu · gesto Happy]_
  - ❓ **Pregunta al jugador:** ¿Qué cuentas primero?
    - ➤ _(si tienes la marca «ayudaste a mateo»)_ «¡He hecho un amigo! Se llama Mateo.» _(efecto: Mamá/Papá +3)_
      - **Abu:** ¿Ves? El que ayuda nunca está solo.
    - ➤ _(si en «asiento» elegiste «Sara»)_ «Me he sentado con Sara. ¡Sabe muchísimo!»
      - **Mamá/Papá:** Una buena compañera de pupitre vale oro.
      - **Mamá/Papá:** Ya lo verás en los exámenes.
    - ➤ _(si en «grupo recreo» elegiste «Deportistas»)_ «Nico dice que mañana juego al fútbol con ellos.»
      - **Mamá/Papá:** Pues habrá que lavar esas zapatillas.
    - ➤ _(si en «grupo recreo» elegiste «Artistas»)_ «Un niño que se llama Omar me ha dibujado con capa.»
      - **Abu:** ¡Un superhéroe en la familia! Ya era hora.
    - ➤ _(si en «grupo recreo» elegiste «Estudiantes»)_ «Hemos investigado si las hormigas duermen.»
      - **Abu:** ¿Y duermen? ¿No? ¿Todavía no lo sabéis? Qué emoción.
    - ➤ «Ha sido un rollo.» _(efecto: humor +1)_
      - **Tú:** Bueno… No tanto. _[silencio 0.9 s]_
      - **Mamá/Papá:** «No tanto» en idioma de niño significa «me lo he pasado genial».
      - _(si tienes la marca «ignoraste a mateo»)_ **Mamá/Papá:** ¿Y ese niño que estaba solo? _[plano Reaccion de Tú]_
      - **Mamá/Papá:** ¿Nadie le ayudó? Mañana, si lo ves solo… Ve con él. ¿Vale? Qué orgullo. Primer día. Superado. _[plano PrimerPlano de Tú]_
      - _Narrador:_ _Un día parece pequeño/a cuando lo estás viviendo. Pero algunos días…_ _[plano PrimerPlano de Tú]_
      - _Narrador:_ _empiezan cosas que tardan años en terminar._ _[silencio 0.9 s]_
      - _Narrador:_ _Primer día de colegio. Completado. Y esto…_ _[plano General]_
      - _Narrador:_ _no ha hecho más que empezar._ _[plano General]_
  - _Narrador:_ _Mañana volverás. Y algunas de las personas que has conocido hoy… todavía estarán ahí._ _[plano General]_

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
  - 🎬 **Escena al completarlo «Cole02_Mochila_G1_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _En escena:_ Rubén, Bruno
    - 🪧 _Rótulo:_ «Unos días después…»
    - _Narrador:_ _Han pasado unos días._
    - _Narrador:_ _Ya conoces los pasillos._
    - _Narrador:_ _Algunas caras ya empiezan a resultarte familiares._
    - _Narrador:_ _Y algunas personas… empiezan a mostrar quiénes son._
    - **Bruno:** Psst.
    - **Bruno:** Luego.
    - **Rubén:** Vale. _[emoción Joy]_
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase (1.º A)»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Vega, Omar, Álex, Hugo, Bruno, Mateo, Nico
- **Paso 3 · Escena**
  - _Lugar:_ Tu pupitre
  - **Profe Lucía:** ¡Buenos días! [tu nombre], ¿me haces un favor? _[plano General]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G3_Musica»** _(música: → Descubrimiento)_
  - **Profe Lucía:** Lleva esta lista a Ramón, a conserjería. _[plano Medio de Tú]_
  - **Profe Lucía:** Es muy fácil. Se la das y vuelves. _[plano General]_
  - **Profe Lucía:** Deja la mochila en tu silla. No tardarás nada. _[plano Hombro de Tú → Profe Lucía]_
  - _Narrador:_ _No le das importancia._ _[plano Reaccion de Rubén]_
- **Paso 4 · Hablar** con Ramón — «Lleva la lista de clase a Ramón (conserjería, en la entrada)»
  - _Lugar:_ Conserjería · _En escena:_ Ramón
  - **Ramón:** ¡La lista!
    - 🎬 **Escena de cámara «Cole02_Mochila_G4_Musica»** _(música: → Descubrimiento)_
  - **Ramón:** Gracias. _[plano General]_
  - **Ramón:** Veinte nombres. Veinte mochilas. Veinte bocadillos. Y un conserje. _[plano Medio de Ramón]_
  - **Ramón:** ¿Sabes cuántas cosas pierde un colegio en un año? Trescientas doce. _[plano Reaccion de Tú]_
  - **Ramón:** Las tengo apuntadas. _[plano PPP de Ramón]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¿Y dónde van todas esas cosas?» _(efecto: Ramón +3; curiosidad +1)_
      - **Ramón:** Algunas llegan a objetos perdidos.
      - **Ramón:** Otras aparecen en lugares imposibles. Y alguna… nunca vuelve.
    - ➤ «¡Me tengo que ir! ¡Me espera Lucía!» _(efecto: responsabilidad +1)_
      - **Ramón:** ¡Corre, corre! Qué responsabilidad tan grande para alguien tan pequeño/a.
      - _Narrador:_ _Mejor volver._ _[plano Reaccion de Tú]_
  - 🎬 **Escena al completarlo «Cole02_Mochila_G5_Entra»** _(música: → Tension)_
    - **Tú:** ¿Y mi mochila?
- **Paso 5 · Ir a** Aula de 1.º A — «Vuelve a clase»
  - _Lugar:_ Aula de 1.º A
- **Paso 6 · Escena**
  - _Narrador:_ _No está. Ni en la silla. Ni debajo._ _[plano General]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G6_Musica»** _(música: → Tension)_
  - **Tú:** No puede ser. _[plano PrimerPlano de Tú]_
  - _(si tienes la marca «lleva cromo»)_ **Tú:** Y el cromo de la suerte estaba dentro… _[plano Reaccion de Tú]_
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Tu mochila ya no está contigo. Busca._ _[silencio 0.9 s]_
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Quizá alguien la haya movido._
- **Paso 7 · Varios objetivos (en cualquier orden)** — «Busca tu mochila en el aula»
  - **Paso 7.1 · Usar** — «Tu pupitre»
    - 🖐 _Al usar «Tu sitio»:_
      - _Narrador:_ _Nada. Definitivamente no es tu mochila._ _[plano General]_
  - **Paso 7.2 · Usar** — «Tu taquilla del pasillo»
    - 🖐 _Al usar «Tu taquilla (la 3)»:_
      - _Narrador:_ _Aquí tampoco. La mochila ni siquiera cabría._ _[plano General]_
  - **Paso 7.3 · Usar** — «La papelera (por si acaso)»
    - 🖐 _Al usar «Papelera»:_
      - **Tú:** Vale. Esto ya no es un despiste. _[plano Reaccion de Tú]_
      - **Tú:** Alguien se la ha llevado. _[plano PrimerPlano de Tú]_
- **Paso 8 · Escena**
  - _En escena:_ Profe Lucía
  - **Profe Lucía:** ¿Qué pasa, [tu nombre]? _[plano Seguir de Profe Lucía]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G8_Musica»** _(música: → Tension)_
  - **Profe Lucía:** Tienes cara de haber visto un fantasma. _[plano PrimerPlano de Profe Lucía]_
  - **Tú:** Mi mochila. La dejé aquí y… ya no está. _[plano Reaccion de Tú]_
  - **Profe Lucía:** Vaya. _[plano Reaccion de Profe Lucía]_
  - **Profe Lucía:** Las mochilas no desaparecen solas. _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** Pregunta a tus compañeros. _[silencio 0.9 s]_
  - **Profe Lucía:** Alguien habrá visto algo.
  - **Profe Lucía:** Yo avisaré a Ramón. _[plano Seguir de Profe Lucía]_
  - **Profe Lucía:** Y no te preocupes. Vamos a encontrarla. _[plano Reaccion de Tú]_
- **Paso 9 · Varios objetivos (en cualquier orden)** — «Pregunta a tus compañeros»
  - _En escena:_ Sara, Omar, Iker, Mateo (si tienes la marca «ayudaste a mateo»), Nico
  - 🗨 _Charla opcional con Nico (si te acercas a hablar):_
    - **Nico:** ¿Tu mochila? ¡Qué fuerte! Si pillo al que ha sido, le reto a una carrera. Y le gano.
  - **Paso 9.1 · Hablar** con Mateo — «Mateo quiere decirte algo (zona de juegos)» _(solo si tienes la marca «ayudaste a mateo»)_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** [tu nombre]… _[plano General]_
      - 🎬 **Escena de cámara «Cole02_Mochila_G9_1_Musica»** _(música: → Tension)_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo lo vi. Fue Rubén. _[plano Reaccion de Mateo]_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Bruno le dijo que lo hiciera. _[plano PrimerPlano de Mateo]_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** No dije nada porque… me dio miedo. Perdona. _[plano Hombro de Tú → Mateo]_
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Gracias por contármelo. Has sido valiente.» _(efecto: Mateo +10; empatia +1; marca «pista mateo»)_
        - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** ¿Yo? ¿Valiente? Nadie me había dicho eso.
      - ➤ «¿Por qué no lo dijiste antes?» _(efecto: Mateo -3; marca «pista mateo»)_
        - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Ya… Lo siento. Es que Bruno da miedo.
  - **Paso 9.2 · Hablar** con Sara — «Sara (en el aula)»
    - **Sara:** ¿Una mochila azul? _[plano Medio de Sara]_
      - 🎬 **Escena de cámara «Cole02_Mochila_G9_2_Musica»** _(música: → Tension)_
    - **Sara:** Sí. Hace unos diez minutos. Salió por la ventana. _[plano PrimerPlano de Sara]_
    - **Sara:** Iba hacia el patio. La llevaba alguien con prisa. _[plano Hombro de Sara → Tú]_
    - **Sara:** Y llevaba una sudadera morada. Eso es importante. _[plano PPP de Sara]_
  - **Paso 9.3 · Hablar** con Omar — «Omar (en el pasillo)»
    - **Omar:** Espera. _[plano General]_
      - 🎬 **Escena de cámara «Cole02_Mochila_G9_3_Musica»** _(música: → Tension)_
    - **Omar:** Lo tengo dibujado. _[plano General]_
    - **Omar:** Dibujo casi todo lo que pasa aquí. _[plano Reaccion de Tú]_
    - **Omar:** Mira. Va hacia el gimnasio. No vi su cara. Iba demasiado rápido. _[plano General]_
    - **Omar:** Los dibujos rápidos salen borrosos.
  - **Paso 9.4 · Hablar** con Iker — «Iker (en la biblioteca)»
    - **Iker:** (susurrando) Oí algo. _[plano General]_
      - 🎬 **Escena de cámara «Cole02_Mochila_G9_4_Musica»** _(música: → Tension)_
    - **Iker:** «La mochila azul». «Al sitio de siempre». _[plano PrimerPlano de Iker]_
    - **Iker:** Y después se rieron. _[plano Reaccion de Tú]_
    - **Iker:** Dato curioso. El sitio de siempre suele ser donde nadie mira. _[plano PPP de Iker]_
    - **Nico:** ¡Qué fuerte! Si pillo al que ha sido… _[plano Reaccion de Nico]_
    - **Nico:** le reto a una carrera. Y le gano.
- **Paso 10 · Varios objetivos (en cualquier orden)** — «Busca pistas en el patio»
  - **Paso 10.1 · Usar** — «Un papel arrugado»
    - 🖐 _Al usar «Papel arrugado»:_
      - _Narrador:_ _Alguien ha dibujado una pequeña calavera. Debajo hay una letra._ _[plano General]_
      - _Narrador:_ _R._ _[plano General]_
  - **Paso 10.2 · Usar** — «Algo que brilla»
    - 🖐 _Al usar «Algo brillante»:_
      - _(si tienes la marca «lleva cromo»)_ **Tú:** Mi cromo. _[plano Reaccion de Tú]_
      - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Se cayó de la mochila._
      - _(si NO tienes la marca «lleva cromo»)_ _Narrador:_ _Es la pegatina que llevaba tu mochila._ _[plano General]_
      - **Tú:** Mi mochila ha pasado por aquí. _[plano Reaccion de Tú]_
  - **Paso 10.3 · Usar** — «Huellas de barro»
    - 🖐 _Al usar «Huellas de barro»:_
      - _Narrador:_ _Zapatillas pequeñas. Van hacia el gimnasio._ _[plano General]_
      - _Narrador:_ _Alguien iba corriendo._
  - **Paso 10.4 · Usar** — «Un llavero»
    - 🖐 _Al usar «Llavero»:_
      - **Tú:** B… Bruno. _[plano PrimerPlano de Tú]_
  - **Paso 10.5 · Usar** — «Un envoltorio»
    - 🖐 _Al usar «Envoltorio rosa»:_
      - _Narrador:_ _Chicle de fresa. Huele a fresa._ _[plano General]_
      - _Narrador:_ _Y no demuestra absolutamente nada. A veces una pista…_ _[silencio 0.9 s]_
      - _Narrador:_ _es simplemente basura._
- **Paso 11 · Escena**
  - _Narrador:_ _Una firma._ _[plano General]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G11_Musica»** _(música: → Tension)_
  - _Narrador:_ _Un llavero._ _[plano General]_
  - _Narrador:_ _Huellas hacia el gimnasio._ _[plano General]_
  - _Narrador:_ _Algo de tu mochila._ _[plano General]_
  - _(si tienes la marca «pista sara»)_ _Narrador:_ _Alguien con sudadera morada fue hacia el patio._
  - _(si tienes la marca «pista omar»)_ _Narrador:_ _Omar vio a alguien corriendo hacia el gimnasio._
  - _(si tienes la marca «pista iker»)_ _Narrador:_ _Alguien habló del «sitio de siempre»._
  - _(si tienes la marca «pista mateo»)_ _Narrador:_ _Mateo vio a Rubén. Y Bruno se lo pidió._
  - **Tú:** Todo apunta al gimnasio. _[plano PrimerPlano de Tú]_
  - **Tú:** Entonces allí es donde voy. _[silencio 0.9 s]_
  - 🎬 **Escena al completarlo «Cole02_Mochila_G12_Entra»** _(música: → Tension)_
    - _En escena:_ Alumna de 6.º, Alumno de 6.º
    - **Alumno de 6.º:** ¡Ni la toques! ¡Esa es nuestra canasta!
    - **Alumna de 6.º:** Álex siempre gana. Siempre.
- **Paso 12 · Ir a** Gimnasio — «Sigue las pistas hasta el gimnasio»
  - _Lugar:_ Gimnasio · _En escena:_ Álex, Alumno de 6.º, Alumna de 6.º
  - 💬 _Comentario al pasar cerca de Alumno de 6.º:_ «¡Ni la toques, que es nuestra canasta!»
  - 💬 _Comentario al pasar cerca de Alumna de 6.º:_ «Álex siempre gana. Siempre.»
- **Paso 13 · Hablar** con Álex — «Habla con Álex»
  - **Álex:** Hola. ¿Buscas algo? _[plano Medio de Álex]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G13_Musica»** _(música: → Descubrimiento)_
  - **Álex:** Tienes cara de buscar algo. _[plano PrimerPlano de Álex]_
  - **Tú:** Mi mochila. ¿Has visto a alguien con una mochila azul?
  - **Álex:** Puede. Puede que sí.
  - **Álex:** Pero la información es cara. _[plano PPP de Álex]_
  - **Álex:** Trato. Mete tres canastas. _[plano Reaccion de Tú]_
  - **Álex:** Si las metes, te lo cuento.
  - _(si tienes la marca «apuesta alex»)_ **Álex:** Y además me debes una por aquella apuesta. Me acuerdo.
- **Paso 14 · Minijuego** — «¡Mete 3 canastas!»
  - 🎮 _Cómo se juega:_ Suelta cuando la aguja esté en verde. Cada canasta, más difícil.
- **Paso 15 · Escena**
  - _(si tienes la marca «canastas alex»)_ **Álex:** Vale. Tres canastas.
    - 🎬 **Escena de cámara «Cole02_Mochila_G15_Musica»** _(música: → Tension)_
  - _(si tienes la marca «canastas alex»)_ **Álex:** Un trato es un trato. _[plano PrimerPlano de Álex]_
  - _(si tienes la marca «sin canastas»)_ **Álex:** Ni una. Uf.
  - **Álex:** Mira… Te lo voy a contar igual. _[plano Reaccion de Tú]_
  - **Álex:** Pero que no se entere nadie. _[silencio 0.9 s]_
  - **Álex:** Rubén pasó por aquí con una mochila azul. Hace un rato. _[plano Hombro de Álex → Tú]_
  - **Álex:** Se metió ahí. _[plano General]_
  - **Álex:** En el almacén. Y Rubén solo hace estas cosas cuando Bruno se lo pide. _[plano PrimerPlano de Álex]_
  - _(si tienes la marca «sabe del almacen»)_ **Tú:** Ramón dijo que nadie puede entrar ahí.
  - _(si tienes la marca «sabe del almacen»)_ **Álex:** Entonces ya sabes lo que toca.
  - 🎬 **Escena al completarlo «Cole02_Mochila_G16_Entra»** _(música: → Tension)_
    - _Narrador:_ _Nadie parece estar mirando._
- **Paso 16 · Ir a** Almacén del gimnasio — «Ve al almacén del gimnasio»
- **Paso 17 · Escena**
  - _Narrador:_ _Huele a goma. A polvo. Y a secretos._ _[plano General]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G17_Musica»** _(música: → Tension)_
  - **Tú:** Ahí. _[plano Reaccion de Tú]_
  - _Narrador:_ _Hay varias. Pero una de ellas…_ _[plano General]_
  - _Narrador:_ _es la tuya._ _[plano General]_
- **Paso 18 · Varios objetivos (en cualquier orden)** — «Revisa las mochilas del almacén»
  - **Paso 18.1 · Usar** — «La roja»
    - 🖐 _Al usar «Mochila roja»:_
      - _Narrador:_ _No es la tuya._ _[plano General]_
  - **Paso 18.2 · Usar** — «La verde»
    - 🖐 _Al usar «Mochila verde»:_
      - _Narrador:_ _No. Definitivamente no._ _[plano General]_
  - **Paso 18.3 · Usar** — «La amarilla»
    - 🖐 _Al usar «Mochila amarilla»:_
      - _Narrador:_ _Dentro hay un libro de piratas._ _[plano General]_
      - **Tú:** ¿Hugo? El amigo de Bruno… _[plano Reaccion de Tú]_
      - _Narrador:_ _Y resulta que también lee libros de piratas._
      - _Narrador:_ _Curioso._ _[plano Reaccion de Tú]_
- **Paso 19 · Escena**
  - _En escena:_ Rubén
  - **Rubén:** ¿Buscas esto? _[plano Reaccion de Tú]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G19_Musica»** _(música: → Tension)_
  - **Rubén:** Era una broma. Bruno dijo que a los nuevos había que darles la bienvenida. Es una tradición. _[plano General]_
  - _(si tienes la marca «pista mateo»)_ **Tú:** Mateo te vio. Bruno te dijo que lo hicieras. _[plano PrimerPlano de Tú]_
  - **Rubén:** Mateo es un chivato. Bueno. Da igual.
  - **Rubén:** Ahí la tienes. Está entera. _[plano General]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «¡No tiene ninguna gracia!» _(efecto: Bruno -5; Rubén -15; valentia +2; decisión «mochila ruben» = Enfado; marca «ruben rival»)_
      - **Tú:** ¡No tiene ninguna gracia!
      - **Tú:** ¡Me he pasado la mañana buscándola!
      - **Rubén:** Vale, vale. No grites. Era solo una broma. _[plano Reaccion de Rubén]_
    - ➤ «Vale. Pero no vuelvas a hacerlo.» _(efecto: Rubén +15; empatia +2; decisión «mochila ruben» = Perdon; marca «ruben perdonado»)_
      - **Tú:** Vale. Te perdono. Pero no vuelvas a hacerlo.
      - **Rubén:** ¿En serio? Vale. Gracias. _[plano Reaccion de Rubén]_
      - **Rubén:** Bruno no perdona nunca a nadie.
    - ➤ «Esto se lo tiene que saber Lucía.» _(efecto: Bruno -10; Profe Lucía +5; Rubén -5; responsabilidad +2; decisión «mochila ruben» = Profe; marca «avisaste a lucia»)_
      - **Tú:** Esto se lo tiene que saber Lucía.
      - **Rubén:** ¡No! ¡Espera! Bruno me va a… Bueno. Se va a enfadar. _[plano Reaccion de Rubén]_
    - ➤ «Devolverle la broma.» _(efecto: Rubén +5; humor +2; decisión «mochila ruben» = Broma; marca «broma de vuelta»)_
      - _Narrador:_ _Rubén deja la mochila en el suelo. Y una idea aparece. Una idea pequeña. Y bastante traviesa._ _[plano General]_
- **Paso 20 · Usar** — «Esconde la gorra de Rubén» _(solo si en «mochila ruben» elegiste «Broma»)_
  - 🖐 _Al usar «La gorra de Rubén (en una caja)»:_
    - _(si en «mochila ruben» elegiste «Broma»)_ **Rubén:** ¿Y mi gorra? ¿Dónde está mi gorra? _[plano Reaccion de Tú]_
    - _(si en «mochila ruben» elegiste «Broma»)_ **Rubén:** Ah. Ya. Ja. Ja. Muy gracioso. _[plano PrimerPlano de Rubén]_
    - _(si en «mochila ruben» elegiste «Broma»)_ **Rubén:** Vale. Ha tenido gracia. Un poco. _[plano Reaccion de Rubén]_
- **Paso 21 · Escena**
  - _En escena:_ Rubén, Profe Lucía
  - **Profe Lucía:** ¿Qué hacéis los dos aquí? _[plano Seguir de Profe Lucía]_
    - 🎬 **Escena de cámara «Cole02_Mochila_G21_Musica»** _(música: → Intima)_
  - **Profe Lucía:** ¿No os ha dicho Ramón que aquí no se entra? _[plano PrimerPlano de Profe Lucía]_
  - _(si en «mochila ruben» elegiste «Profe»)_ **Profe Lucía:** Rubén. Explícamelo.
  - _(si en «mochila ruben» elegiste «Profe»)_ **Rubén:** Fue… una broma. Bruno me dijo que lo hiciera.
  - **Bruno:** Yo solo… _[plano Reaccion de Bruno]_
  - **Profe Lucía:** Ya hablaremos después.
  - **Rubén:** Lo siento, [tu nombre]. De verdad. _[plano Medio de Rubén]_
  - **Profe Lucía:** Gracias por contármelo. Hablaré con los dos. _[plano PrimerPlano de Profe Lucía]_
  - **Profe Lucía:** Esto no es una tradición. Es una mala decisión. _[silencio 0.9 s]_
  - _(si en «mochila ruben» elegiste «Perdon»)_ **Rubén:** Nada, profe. Estábamos buscando un balón.
  - **Rubén:** Y lo hemos encontrado. _[plano General]_
  - **Profe Lucía:** Ya. Un balón azul con forma de mochila. Los dos a clase. Vamos. _[plano Reaccion de Profe Lucía]_
  - _(si en «mochila ruben» elegiste «Enfado»)_ **Rubén:** ¡Me ha gritado, profe!
  - **Profe Lucía:** Normal. Yo también me enfadaría si alguien escondiera mi mochila. _[plano Reaccion de Profe Lucía]_
  - **Profe Lucía:** Pero la próxima vez… respira. Y ven a buscarme. _[plano PrimerPlano de Profe Lucía]_
  - _(si en «mochila ruben» elegiste «Broma»)_ **Rubén:** ¡Profe! ¡Me ha escondido la gorra!
  - **Profe Lucía:** Y tú le has escondido la mochila. _[plano Reaccion de Profe Lucía]_
  - **Profe Lucía:** Empate técnico. Ahora os devolvéis las cosas. _[plano DosPlanos de Tú → Profe Lucía · silencio 0.9 s]_
  - **Profe Lucía:** Y se acabaron las bromas.
  - _Narrador:_ _Recuperas tus cosas. Todo sigue dentro._ _[plano General]_
  - _Narrador:_ _Hugo no dice nada. Pero parece incómodo._ _[plano Lateral de Hugo]_
  - _Narrador:_ _Quizá haya más en esta historia de lo que parece._ _[plano General]_
  - _Narrador:_ _Has recuperado tu mochila._ _[plano PrimerPlano de Tú]_
  - _Narrador:_ _Pero acabas de entrar en un problema mucho más grande._ _[silencio 0.9 s]_
  - _Narrador:_ _Algunas bromas duran cinco minutos. Algunas decisiones… mucho más._ _[plano General]_

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
  - 🎬 **Escena al completarlo «Cole03_G1_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _En escena:_ Profe Lucía
    - 🪧 _Rótulo:_ «Una semana después…»
    - _Narrador:_ _Una semana puede parecer poco._
    - _Narrador:_ _Pero a los siete años…_
    - _Narrador:_ _una semana es tiempo suficiente para empezar a sentir que un lugar es tuyo._
    - **Profe Lucía:** Muy bien. Hoy vamos a hablar de algo que estáis viendo todos los días.
    - **Profe Lucía:** Las plantas.
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Iker, Sara, Omar, Hugo, Bruno, Rubén, Mateo, Nico
  - 🎬 **Escena al completarlo «Cole03_G3_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Omar, Profe Lucía, Nico, Sara
    - **Profe Lucía:** ¿Por qué creéis que las plantas buscan la luz?
    - **Sara:** Porque realizan fotosíntesis.
    - **Sara:** Técnicamente utilizan la luz para producir energía.
    - **Nico:** Yo también lo sabía.
    - **Sara:** No lo sabías.
    - **Nico:** Lo estaba pensando.
    - **Omar:** Yo solo sé que esta tiene hambre.
    - **Profe Lucía:** Las plantas no comen bocadillos, Omar.
    - **Omar:** Todavía no lo sabemos.
- **Paso 3 · Clase** — «Clase de Ciencias»
- **Paso 4 · Escena**
  - _Lugar:_ Tu pupitre
  - **Profe Lucía:** Y por eso las plantas… _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G4_Musica»** _(música: → Descubrimiento)_
  - **Profe Lucía:** Nico. _[plano Reaccion de Profe Lucía]_
  - **Nico:** ¿Sí? _[plano Reaccion de Nico]_
  - **Profe Lucía:** El balón no se lanza dentro del aula.
  - **Nico:** ¡Si todavía no lo he sacado!
  - **Profe Lucía:** Exactamente. Y por eso sé que vas a intentarlo. _[plano PPP de Profe Lucía]_
  - **Nico:** ¡Vamos! _[plano Reaccion de Nico · gesto Happy]_
  - 🎬 **Escena al completarlo «Cole03_G5_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Nico, Omar, Sara
    - **Nico:** ¡[tu nombre]!
    - **Omar:** Ven aquí.
    - **Sara:** ¡Rápido!
    - _Narrador:_ _Tres amigos. Tres planes. Y solo un recreo._
- **Paso 5 · Ir a** el patio — «Sal al recreo»
  - _Lugar:_ el patio · _En escena:_ Nico, Omar, Sara
  - 🎬 **Escena al completarlo «Cole03_G6_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Nico, Omar, Sara
    - **Nico:** ¡Calienta! Hoy hay partido.
    - **Nico:** Jugamos contra los de Bruno.
    - **Nico:** Me falta alguien bueno.
    - **Nico:** Y tú eres gente buena. Eso creo.
    - **Nico:** Pero antes… Tres penaltis.
    - **Nico:** Si metes dos, eres titular.
    - _(si en «gusto» elegiste «Futbol»)_ **Nico:** Y encima dijiste que te gusta el fútbol. Me acuerdo de TODO.
    - **Omar:** Ven.
    - **Omar:** Lucía me deja pintar esta parte.
    - **Omar:** El cielo. El colegio. Y nosotros.
    - **Omar:** Tú dibujas una parte. Yo otra. Trabajo en equipo. Y luego merendamos. Tengo hambre.
    - **Sara:** ¡Rápido!
    - **Sara:** He visto un escarabajo rarísimo.
    - **Sara:** Verde. Brillante. Y no aparece en mi libro.
    - **Sara:** Puede ser una especie nueva.
    - **Sara:** Si lo descubrimos nosotros…
    - **Sara:** le ponemos nuestro nombre.
    - **Sara:** «Escarabajus Sara-y-[tu nombre]».
- **Paso 6 · Decisión** — «¿Con quién vas?»
  - _Lugar:_ Pista
  - 🎬 **Escena al completarlo «Cole03_G7_Entra»** _(música: → Tension)_
    - _En escena:_ Nico
    - _(si en «invitacion» elegiste «Nico»)_ **Nico:** Dos de tres. Si metes dos… titular.
    - _(si en «invitacion» elegiste «Nico» y tienes la marca «cole 03 p 7 gana»)_ **Nico:** ¡Lo sabía!
    - _(si en «invitacion» elegiste «Nico» y tienes la marca «cole 03 p 7 pierde»)_ **Nico:** Bueno. Has venido a jugar. Eso es lo importante.
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
      - **Omar:** El cielo. Azul. Pero no cualquier azul.
      - **Omar:** Azul de «hoy no hay deberes».
      - ❓ **Pregunta al jugador:** ¿Qué le añades?
        - ➤ «Un sol con gafas.» _(efecto: humor +1)_
          - **Omar:** Un sol que se protege del sol. Me gusta.
        - ➤ «Un cohete.» _(efecto: curiosidad +1)_
          - **Omar:** Rumbo a Marte. Sara lo va a aprobar.
  - **Paso 8.2 · Usar** — «El colegio»
    - 🖐 _Al usar «Mural: el colegio»:_
      - **Omar:** Ahora el colegio.
      - **Omar:** Y tiene que aparecer Ramón. _[plano General]_
      - **Omar:** Porque si no… no es nuestro colegio. _[plano Medio de Omar]_
      - **Omar:** Mira su cara. Le va a encantar. _[plano Reaccion de Omar]_
  - **Paso 8.3 · Usar** — «Nosotros»
    - 🖐 _Al usar «Mural: nosotros»:_
      - **Omar:** Y aquí… nosotros. _[plano General]_
      - **Omar:** Tú. Yo. Y los que vengan. Dejo espacio. _[plano General]_
      - **Omar:** Siempre hay que dejar espacio. _[plano PrimerPlano de Omar]_
      - **Omar:** No suelo dejar pintar a nadie en mis dibujos. _[silencio 0.9 s]_
      - **Omar:** Contigo es distinto. _[plano Reaccion de Tú]_
- **Paso 9 · Usar** — «Sigue al escarabajo» _(solo si en «invitacion» elegiste «Sara»)_
  - _En escena:_ Sara (te acompaña)
  - 🖐 _Al usar «Escarabajo brillante»:_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** ¡Ahí! _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** No respires. Seis patas. Caparazón verde. Y… _[plano PPP de Sara]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** ¡BRILLA! _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** ¡Síguelo! ¡La ciencia no espera! _[plano General]_
- **Paso 10 · Usar** — «¡Se ha ido volando hacia la cancha!» _(solo si en «invitacion» elegiste «Sara»)_
  - 🖐 _Al usar «Escarabajo brillante»:_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Ahí. _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Fíjate. Cuando le da el sol… _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** cambia de color. Es iridiscente. _[plano General]_
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «¿Iri-qué?» _(efecto: humor +1)_
        - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Iridiscente. Como las pompas de jabón. Te lo apunto.
      - ➤ «Como las pompas de jabón, ¿no?» _(efecto: Sara +3; curiosidad +1)_
        - _(si en «invitacion» elegiste «Sara»)_ **Sara:** ¡Exacto! ¡Por fin alguien de mi nivel!
- **Paso 11 · Usar** — «¡Ahora está junto al edificio!» _(solo si en «invitacion» elegiste «Sara»)_
  - 🖐 _Al usar «Escarabajo brillante»:_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Espera. _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Registro científico número uno. _[plano Medio de Sara]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Descubridores. Sara y [tu nombre]. Fecha… Hoy. _[plano General]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Oye… Ha sido el mejor recreo de mi vida. _[plano PrimerPlano de Sara]_
    - _(si en «invitacion» elegiste «Sara»)_ **Sara:** Gracias por venir. _[plano Reaccion de Tú]_
- **Paso 12 · Escena**
  - _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña)
  - **Nico:** ¡EH! _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G12_Musica»** _(música: → Intima)_
  - **Nico:** ¡Vosotros! _[plano Reaccion de Tú]_
  - **Nico:** Nos faltan jugadores. Bruno dice que si no somos cinco… perdemos sin jugar. _[plano Seguir de Nico]_
  - **Omar:** Yo no sé jugar. Pero puedo ponerme de portero.
  - **Omar:** Soy muy bueno no moviéndome.
  - **Sara:** Estadísticamente… Con cinco jugadores nuestras probabilidades suben.
  - **Nico:** ¿Eso significa que ganamos?
  - **Sara:** Significa que tenemos más posibilidades.
  - **Nico:** Me vale.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** ¿Yo… también puedo jugar? _[plano Reaccion de Mateo]_
  - **Nico:** ¡Claro! ¡Cuantos más, mejor! _[plano PrimerPlano de Nico]_
- **Paso 13 · Ir a** Campo de fútbol — «Ve al campo de fútbol»
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Hugo, Álex
  - 🎬 **Escena al completarlo «Cole03_G13_Fin»**
    - _En escena:_ Bruno
    - **Bruno:** Vaya. Habéis conseguido reunir gente.
- **Paso 14 · Escena**
  - **Andrés:** Partido amistoso. A-MIS-TO-SO. _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G14_Musica»** _(música: → Tension)_
  - **Andrés:** Sin empujones. _[plano Reaccion de Nico]_
  - **Andrés:** Sin trampas. _[plano Reaccion de Bruno]_
  - **Andrés:** Y dando la mano al final. ¿Entendido? _[plano General]_
  - _Narrador:_ _Todos: «Sí.»_
  - **Bruno:** Sí. Claro. _[plano PrimerPlano de Bruno]_
  - _(si tienes la marca «avisaste a lucia»)_ **Bruno:** Mirad quién viene. El que se chiva a los profes.
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Suerte. Pero no mucha. _[plano Reaccion de Rubén]_
  - _(si tienes la marca «broma de vuelta»)_ **Rubén:** Hoy me toca ganar. Por lo de la gorra.
  - **Bruno:** Esto va a ser muy fácil. _[plano PrimerPlano de Bruno]_
  - **Bruno:** Cinco minutos y os vais llorando.
  - **Hugo:** Bruno… Es solo un partido. _[plano Reaccion de Hugo]_
  - **Nico:** ¿Dónde juegas? _[plano PrimerPlano de Bruno]_
  - ❓ **Pregunta al jugador:** Elige tu posición
    - ➤ «Delante: ¡a marcar goles!» _(efecto: valentia +1; decisión «posicion» = Delantero)_
      - **Nico:** ¡Dúo de ataque! Tú y yo. Que tiemble Álex.
      - **Álex:** Estoy aquí.
      - **Nico:** Ya. Era una forma de hablar.
    - ➤ «Defensa: que no pase nadie.» _(efecto: responsabilidad +1; decisión «posicion» = Defensa)_
      - **Sara:** Un muro humano. Sólido. Me gusta.
    - ➤ «Portería: que Omar descanse.» _(efecto: Omar +4; decisión «posicion» = Portero)_
      - **Omar:** ¡Gracias! Yo defenderé el bocadillo.
      - **Sara:** Eso sí que parece una misión importante. _[plano Reaccion de Sara]_
      - **Andrés:** ¡Preparados…! ¡PRRRRIII!
  - 🎬 **Escena al completarlo «Cole03_G15_Entra»** _(música: → Tension)_
    - _En escena:_ Hugo, Bruno, Sara, Omar, Nico
    - _(si en «posicion» elegiste «Portero»)_ **Nico:** ¡Aquí!
    - **Sara:** ¡A la izquierda!
    - **Omar:** ¡Cuidado con mi bocadillo!
    - **Bruno:** ¡Vamos!
    - **Hugo:** Toma.
    - _(si tienes la marca «partido ganado»)_ **Nico:** ¡GOLAZO!
    - _(si tienes la marca «partido perdido»)_ _Narrador:_ _Un partido no se decide por una jugada. Sigue jugando._
- **Paso 15 · Minijuego** — «¡Partido contra el equipo de Bruno!»
- **Paso 16 · Escena**
  - **Andrés:** ¡Final! Y ahora… todos a dar la mano. _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G16_Musica»** _(música: → Intima)_
  - **Andrés:** Todos, Bruno. _[plano Reaccion de Bruno]_
  - **Bruno:** Vale.
  - _(si tienes la marca «partido ganado»)_ **Nico:** ¡HEMOS GANADO! ¡HEMOS GANADO A BRUNO! _[plano Reaccion de Nico · gesto Happy]_
  - _(si tienes la marca «partido ganado»)_ **Nico:** ¡Esto hay que contárselo a mis nietos!
  - _(si tienes la marca «partido empate»)_ **Nico:** Empate. Bueno. Un empate contra Bruno es como ganar. Casi.
  - _(si tienes la marca «partido perdido»)_ **Nico:** Hemos perdido. Pero…
  - **Nico:** ¿Habéis visto esa jugada? _[plano PrimerPlano de Nico]_
  - **Nico:** La próxima les ganamos.
  - **Sara:** He contado los pases. Veintitrés. _[plano Reaccion de Sara]_
  - **Sara:** Somos un equipo con futuro. Los datos no mienten.
  - **Omar:** Lo he dibujado todo. _[plano Reaccion de Omar]_
  - **Omar:** Toma. Sales tú marcando. Más o menos así fue. _[plano General]_
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo… he tocado el balón dos veces. _[plano PrimerPlano de Mateo]_
  - **Mateo:** Dos. Es mi récord. _[plano Reaccion de Mateo]_
  - **Hugo:** Buen partido. En serio. _[plano Reaccion de Hugo]_
  - ❓ **Pregunta al jugador:** ¿Qué dices al grupo?
    - ➤ «¡Somos un equipazo!» _(efecto: Nico +3; Omar +3; Sara +3; deportividad +1)_
    - ➤ «Omar, casi te comes el bocadillo en plena jugada.» _(efecto: Omar +4; humor +1)_
      - **Omar:** Estaba defendiéndolo. Es distinto.
    - ➤ «Lo mejor ha sido jugar juntos.» _(efecto: Mateo +3; Nico +3; Omar +3; Sara +3; empatia +1)_
      - **Nico:** Oye… Ahora somos un grupo, ¿no? _[plano General]_
      - **Nico:** Los grupos tienen nombre. Es la ley. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Vas?
    - ➤ «¡Sí! ¡Nos vemos allí!» _(efecto: decisión «permiso» = Directo)_
    - ➤ «Primero pido permiso en casa.» _(efecto: responsabilidad +1; decisión «permiso» = Casa)_
      - **Sara:** Muy responsable. Te esperamos en la puerta de tu casa.
- **Paso 17 · Transición (pasa el tiempo)** — «Por la tarde…»
  - ⏳ _Pantalla de transición:_ «Por la tarde…»
  - 🎬 **Escena al completarlo «Cole03_G17_Fin»** _(música: → Descubrimiento)_
    - _En escena:_ Omar, Nico
    - 🪧 _Rótulo:_ «Por la tarde…»
    - **Nico:** Hay un parque cerca. Canasta. Columpios. Y helados.
    - **Omar:** Has dicho la palabra mágica. Helados.
- **Paso 18 · Ir a** tu casa familiar — «Pide permiso en casa» _(solo si en «permiso» elegiste «Casa»)_
- **Paso 19 · Hablar** con Mamá/Papá — «Habla con mamá/papá» _(solo si en «permiso» elegiste «Casa»)_
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá
  - _(si en «permiso» elegiste «Casa»)_ **Tú:** ¿Puedo ir al parque con mis amigos? ¡Porfa!
    - 🎬 **Escena de cámara «Cole03_G19_Musica»** _(música: → Intima)_
  - _(si en «permiso» elegiste «Casa»)_ **Tú:** Volvemos antes de cenar.
  - _(si en «permiso» elegiste «Casa»)_ **Mamá/Papá:** ¿Amigos? _[plano Reaccion de Mamá/Papá]_
  - _(si en «permiso» elegiste «Casa»)_ **Mamá/Papá:** ¿Ya tienes amigos? Eso es maravilloso. _[plano PrimerPlano de Mamá/Papá · silencio 0.9 s]_
  - _(si en «permiso» elegiste «Casa»)_ **Mamá/Papá:** Claro que sí. Antes de cenar. _[plano Medio de Mamá/Papá]_
  - _(si en «permiso» elegiste «Casa»)_ **Mamá/Papá:** Y nada de subirse a los árboles. _[silencio 0.9 s]_
  - _(si en «permiso» elegiste «Casa»)_ **Tú:** Vale. _[plano Reaccion de Tú]_
  - _(si en «permiso» elegiste «Casa»)_ **Mamá/Papá:** Lo digo porque te conozco.
- **Paso 20 · Escena**
  - _Lugar:_ La puerta de casa · _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Mateo (si tienes la marca «ayudaste a mateo») (te acompaña)
  - **Nico:** ¡Estamos todos! _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G20_Musica»** _(música: → Descubrimiento)_
  - **Omar:** Yo me he traído merienda. Por si acaso.
  - **Sara:** Has traído merienda para cuatro horas.
  - **Omar:** Por si acaso.
  - **Nico:** ¡Al parque! _[plano Reaccion de Mateo]_
  - _Narrador:_ _Por primera vez… no vas solo._ _[plano General]_
  - 🎬 **Escena al completarlo «Cole03_G21_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Omar, Mateo, Nico, Sara
    - **Nico:** ¡Por aquí!
    - **Sara:** Esa no es la ruta más corta.
    - **Nico:** Es la más divertida.
    - **Omar:** Yo voto por la que tenga sombra.
    - **Mateo:** En mi otro cole había un parque así.
    - **Mateo:** Pero nunca íbamos todos.
- **Paso 21 · Ir a** el parque — «Ve al parque con tus amigos»
  - _Lugar:_ el parque
- **Paso 22 · Varios objetivos (en cualquier orden)** — «Pasa la tarde en el parque»
  - _Lugar:_ Parque · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 22.1 · Usar** — «Tirar a canasta con Nico»
    - 🖐 _Al usar «Canasta del parque»:_
      - **Nico:** Reto. El que meta desde más lejos…
      - **Nico:** elige el helado de todos. _[silencio 0.9 s]_
      - ❓ **Pregunta al jugador:** ¿Cómo tiras?
        - ➤ «Tiro lejano. A lo grande.» _(efecto: valentia +1)_
          - **Nico:** ¡NO! ¡Eso ha sido chiripa! _[plano Reaccion de Nico · silencio 0.9 s]_
        - ➤ «Bandeja, sin arriesgar.» _(efecto: responsabilidad +1)_
          - **Nico:** Ha sido… un fallo táctico. No digas nada. _[plano Reaccion de Nico]_
  - **Paso 22.2 · Usar** — «Columpios con Omar»
    - 🖐 _Al usar «Columpios»:_
      - **Omar:** Mira.
      - **Omar:** Cuando subes muy alto… _[plano General]_
      - **Omar:** las nubes parecen dibujos. _[plano General]_
      - **Omar:** Esa es un dragón. Comiéndose un bocadillo. _[plano General]_
      - **Tú:** Tú ves bocadillos en todas partes.
      - **Omar:** Y tú…
      - **Omar:** cuando te conozca más, también. _[plano PrimerPlano de Omar]_
  - **Paso 22.3 · Usar** — «Experimento con Sara en la fuente»
    - 🖐 _Al usar «Fuente»:_
      - **Sara:** Experimento.
      - **Sara:** ¿Qué flota? _[plano General]_
      - **Sara:** Una hoja. _[plano General]_
      - **Sara:** Una piedra. _[plano General]_
      - **Sara:** Una piña. _[plano General]_
      - ❓ **Pregunta al jugador:** ¿Qué flotará?
        - ➤ «La hoja y la piña.» _(efecto: Sara +4; curiosidad +1)_
          - **Sara:** ¡Correcto! La piña tiene aire dentro.
          - **Sara:** Serías un científico estupendo/una científica estupenda.
        - ➤ «La piedra, que es muy valiente.» _(efecto: Sara +2; humor +1)_
          - **Sara:** La piedra ha sido valiente. Pero poco eficiente. _[plano Reaccion de Sara · ademán Laugh]_
  - **Paso 22.4 · Usar** — «Helados en el quiosco»
    - 🖐 _Al usar «Quiosco de helados»:_
      - **Omar:** Helados. Por fin. _[plano General]_
      - ❓ **Pregunta al jugador:** ¿Qué haces?
        - ➤ «¡Invito yo a todos!» _(efecto: Mateo +3; Nico +3; Omar +3; Sara +3; objeto helado)_
          - _(si NO tienes la marca «sin dinero»)_ **Omar:** Eres la mejor persona que conozco. Después de mi abuela.
          - _(si tienes la marca «sin dinero»)_ _Narrador:_ _No te llega._ _[plano Reaccion de Tú]_
          - _(si tienes la marca «sin dinero»)_ **Mateo:** No pasa nada. Yo tengo mi paga. Invito yo.
          - _(si tienes la marca «sin dinero»)_ **Mateo:** Nunca había invitado a nadie. _[plano PrimerPlano de Mateo]_
        - ➤ «Uno para mí.» _(efecto: objeto helado)_
          - _(si NO tienes la marca «sin dinero»)_ **Omar:** ¿Me das un poquito? Solo la puntita.
          - _(si tienes la marca «sin dinero»)_ _Narrador:_ _Omar comparte el suyo contigo sin decir nada._ _[plano General]_
          - _Narrador:_ _Algunas amistades empiezan con cosas pequeñas._ _[plano Reaccion de Tú]_
- **Paso 23 · Usar** — «Siéntate con tus amigos»
- **Paso 24 · Escena**
  - **Sara:** Pregunta importante. _[plano General]_
    - 🎬 **Escena de cámara «Cole03_G24_Musica»** _(música: → Intima)_
  - **Sara:** ¿Qué queréis ser de mayores? _[plano General]_
  - **Nico:** Futbolista. Obvio. Luego entrenador.
  - **Nico:** Luego presidente del club.
  - **Omar:** Dibujante de cómics.
  - **Omar:** De los que salen en las tiendas. _[plano General]_
  - **Omar:** Con mi nombre en la portada.
  - **Sara:** Yo, astronauta. O científica. O las dos.
  - **Sara:** Científica en el espacio.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo… Veterinario.
  - **Mateo:** Para cuidar animales que nadie quiere. _[plano PrimerPlano de Mateo]_
  - **Sara:** Me gusta. _[plano Reaccion de Sara]_
  - **Sara:** ¿Y tú, [tu nombre]? _[plano Medio de Sara]_
  - ❓ **Pregunta al jugador:** ¿Qué quieres ser de mayor?
    - ➤ «Salvar vidas en un hospital.» _(efecto: empatia +1; decisión «sueno infancia» = Medicina)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Tú curas a las personas. Yo a los animales. Somos un equipo.
    - ➤ «Inventar cosas que no existen.» _(efecto: curiosidad +1; decisión «sueno infancia» = Ingenieria)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Sara:** ¡Me haces un cohete! ¡Y yo lo piloto!
    - ➤ «Defender a la gente en los juzgados.» _(efecto: valentia +1; decisión «sueno infancia» = Derecho)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Nico:** Pues ya puedes empezar.
      - _(si tienes la marca «ayudaste a mateo»)_ **Nico:** Defiéndeme de los deberes.
    - ➤ «Tener mi propia tienda o empresa.» _(efecto: responsabilidad +1; decisión «sueno infancia» = Economia)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Omar:** Que sea una tienda de bocadillos. Yo te hago el cartel.
    - ➤ «Ser artista.» _(efecto: creatividad +1; decisión «sueno infancia» = Arte)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Omar:** ¡Lo sabía! Haremos un cómic juntos.
    - ➤ «Deportista profesional.» _(efecto: deportividad +1; decisión «sueno infancia» = Deporte)_
      - _(si tienes la marca «ayudaste a mateo»)_ **Nico:** ¡En mi equipo! ¡Fichado!
      - _Narrador:_ _Ninguno de vosotros lo sabe todavía._ _[plano General]_
      - _Narrador:_ _Pero dentro de muchos años…_ _[silencio 0.9 s]_
      - _Narrador:_ _recordarás esta conversación._ _[plano PrimerPlano de Tú]_
- **Paso 25 · Escena**
  - **Omar:** Por cierto… ¿Sabéis que en el cole vive un gato?
    - 🎬 **Escena de cámara «Cole03_G25_Musica»** _(música: → Descubrimiento)_
  - **Omar:** Naranja. Duerme detrás del gimnasio. _[plano General]_
  - **Sara:** Nadie sabe de quién es. Ramón le deja agua.
  - **Omar:** Pero dice que no es suyo.
  - **Omar:** Esta semana no le he visto. _[plano Reaccion de Omar]_
  - **Omar:** A lo mejor tiene hambre. _[silencio 0.9 s]_
  - **Omar:** ¿Me ayudáis a buscarlo?
  - ❓ **Pregunta al jugador:** ¿Buscaréis al gato?
    - ➤ «¡Claro! Mañana lo buscamos.» _(efecto: Omar +4; empatia +1; decisión «gato colegio» = Buscar; más tarde empieza «El gato del colegio»)_
      - **Omar:** Sabía que dirías que sí. Le llamo Bigotes. En secreto.
    - ➤ «Seguro que está bien. Los gatos saben cuidarse.» _(efecto: decisión «gato colegio» = Nobuscar)_
      - **Omar:** Ya… Seguramente.
- **Paso 26 · Escena**
  - **Nico:** Oye. Ahora somos un grupo.
    - 🎬 **Escena de cámara «Cole03_G26_Musica»** _(música: → Intima)_
  - **Nico:** Y los grupos tienen nombre. Es la ley. _[plano General]_
  - ❓ **Pregunta al jugador:** ¿Cómo os llamáis?
    - ➤ «Los Imparables.» _(efecto: decisión «nombre grupo» = Los Imparables)_
    - ➤ «La Patrulla Valmar.» _(efecto: decisión «nombre grupo» = La Patrulla Valmar)_
    - ➤ «Los del Banco Azul.» _(efecto: decisión «nombre grupo» = Los del Banco Azul)_
    - ➤ _(si en «ropa» elegiste «Dinosaurios»)_ «Los Dinosaurios.» _(efecto: decisión «nombre grupo» = Los Dinosaurios)_
  - **Nico:** ¡[nombre de tu grupo]! ¡Me encanta! ¡Grito de guerra! _[plano PrimerPlano de Nico]_
  - **Omar:** Foto. Tenemos que hacernos una foto.
  - **Sara:** Todos juntos. Tres.
  - **Sara:** Dos. _[plano General]_
  - **Sara:** Uno… _[plano General]_
- **Paso 27 · Cinemática**
  - 🎬 **Cinemática «Cole03_G27»** _(música: → Intima efecto Momento)_
    - _En escena:_ Nico, Sara, Mateo, Omar
    - _Cámara:_ 17 planos (General, Medio, Reaccion, Hombro)
    - 🪧 _Rótulo:_ «📸 ¡Patata!»
    - 🪧 _Rótulo:_ «EL GRUPO — COMPLETADA»
    - **Nico:** ¡[nombre de tu grupo]!
    - _Narrador:_ _Un día normal. Un parque. Cinco niños. Y una fotografía._
    - _Narrador:_ _En ese momento… ninguno sabe lo importante que será esta imagen._
    - _Narrador:_ _Pero algún día… mirarás atrás._
    - **Nico:** ¿Te acuerdas de cuando éramos los Imparables?
    - **Omar:** Todavía tengo el dibujo.
    - **Sara:** Técnicamente seguimos siendo los Imparables.
    - _Narrador:_ _Algunas amistades duran un verano. Otras duran años. Y algunas…_
    - _Narrador:_ _aunque cambien… nunca desaparecen del todo._

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
  - 🎬 **Escena al completarlo «Cole04_G1_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _En escena:_ Nico, Mateo, Omar, Sara
    - 🪧 _Rótulo:_ «Unas semanas después…»
    - _Narrador:_ _Algunas cosas se convierten en importantes sin que te des cuenta._
    - _Narrador:_ _Y cuando alguien intenta quitártelas… lo notas._
    - **Nico:** ¡Por fin!
    - **Omar:** Pensaba que te habías perdido.
    - **Sara:** Han pasado treinta y cuatro segundos.
    - **Omar:** Eso para mí es mucho.
    - **Mateo:** Hola. _[emoción Joy]_
- **Paso 2 · Ir a** el patio — «Es la hora del recreo: busca a tu grupo»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 3 · Escena**
  - _Lugar:_ Banco junto al edificio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Hugo
  - **Nico:** No. _[plano Reaccion de Nico]_
    - 🎬 **Escena de cámara «Cole04_G3_Musica»** _(música: → Tension)_
  - **Sara:** Ya vienen. _[plano Reaccion de Sara]_
  - **Omar:** ¿Podemos fingir que no estamos? _[plano Reaccion de Omar]_
  - **Sara:** No funciona así.
  - **Bruno:** Mira, mira.
  - **Bruno:** El grupito del banco. ¿Qué pasa? ¿Os habéis perdido? _[plano Hombro de Tú → Bruno]_
  - **Bruno:** ¿Seguís con ese nombre? «[nombre de tu grupo]». _[silencio 0.9 s]_
  - **Bruno:** Suena a club de abuelos.
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Je… _[plano Reaccion de Rubén · gesto Happy]_
  - _(si tienes la marca «avisaste a lucia»)_ **Rubén:** Cuidado. Aquí hay quien se chiva. ¡Que viene Lucía! _[plano Reaccion de Rubén]_
  - _(si tienes la marca «partido ganado»)_ **Bruno:** El otro día ganasteis de chiripa.
  - **Bruno:** La próxima os vais a enterar. _[plano PrimerPlano de Bruno]_
  - **Hugo:** Bruno… Vámonos ya. _[plano Reaccion de Hugo]_
  - **Bruno:** ¿Qué prisa tienes? _[plano PrimerPlano de Bruno]_
  - **Hugo:** Ninguna. Vámonos.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Ignorarles y seguir hablando con los tuyos.» _(efecto: responsabilidad +1)_
      - **Sara:** Estadísticamente… el que busca pelea se aburre en treinta segundos. _[plano Medio de Tú]_
      - **Bruno:** Ya veremos. _[plano Reaccion de Bruno]_
    - ➤ «Por lo menos nosotros tenemos nombre, Bruno.» _(efecto: Bruno -3; Nico +3; humor +1)_
      - **Nico:** ¡JA!
      - **Bruno:** Muy gracioso. Ya te reirás menos. _[plano Reaccion de Bruno]_
    - ➤ «Levantarse.» _(efecto: Bruno -2; valentia +2)_
      - **Tú:** Déjanos en paz. _[plano Medio de Tú]_
      - **Bruno:** Uy. Qué valiente. Vale. Ya nos vamos. _[plano PrimerPlano de Bruno · gesto Happy · silencio 0.9 s]_
  - 🎬 **Escena al completarlo «Cole04_G4_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Profe Lucía
    - **Profe Lucía:** Vamos, vamos. Todos dentro.
- **Paso 4 · Ir a** Aula de 1.º A — «Vuelve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 5 · Escena** _(solo si tienes la marca «lleva cromo»)_
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _El bolsillo de las emergencias._ _[plano General]_
    - 🎬 **Escena de cámara «Cole04_G5_Musica»** _(música: → Tension)_
  - _(si tienes la marca «lleva cromo»)_ **Tú:** ¿Mi cromo? ¿Dónde está mi cromo de la suerte? _[plano PrimerPlano de Tú]_
  - _(si tienes la marca «lleva cromo»)_ **Tú:** No… No, no, no. _[plano PPP de Tú · silencio 0.9 s]_
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _El portero legendario ha desaparecido._
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Y sabes exactamente cuándo estaba ahí por última vez._ _[plano General]_
- **Paso 6 · Escena** _(solo si NO tienes la marca «lleva cromo»)_
  - _(si NO tienes la marca «lleva cromo»)_ _Narrador:_ _La foto._ _[plano General]_
    - 🎬 **Escena de cámara «Cole04_G6_Musica»** _(música: → Tension)_
  - _(si NO tienes la marca «lleva cromo»)_ **Tú:** ¿Y la foto? Estaba aquí. Estaba AQUÍ. _[plano General]_
  - _(si NO tienes la marca «lleva cromo»)_ _Narrador:_ _La fotografía del parque ha desaparecido._ _[plano PPP de Tú]_
- **Paso 7 · Varios objetivos (en cualquier orden)** — «Averigua qué ha pasado»
  - _Lugar:_ Pista · _En escena:_ Nico, Sara, Omar, Profe Lucía, Ramón, Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 7.1 · Hablar** con Mateo — «Mateo quiere decirte algo» _(solo si tienes la marca «ayudaste a mateo»)_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo lo vi. Cuando Bruno pasó junto a tu mochila… _[plano Medio de Mateo]_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Hugo se agachó. Cogió algo. _[plano PrimerPlano de Mateo]_
    - _(si tienes la marca «ayudaste a mateo»)_ **Tú:** ¿Hugo?
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Sí. Pero… tenía cara de no querer hacerlo.
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Como cuando alguien hace algo porque tiene miedo. _[plano Reaccion de Tú]_
  - **Paso 7.2 · Hablar** con Nico — «Nico (en la pista)»
    - **Nico:** ¡Sabía que Bruno tramaba algo! Al salir del recreo… iban los tres juntos. Bruno, Rubén y Hugo. _[plano Medio de Nico]_
    - **Nico:** Se fueron hacia el pasillo.
    - **Tú:** ¿Los viste?
    - **Nico:** Sí. Si quieres les reto a una carrera.
    - **Nico:** Y el que gane se queda… Vale. No funciona así. _[silencio 0.9 s]_
  - **Paso 7.3 · Hablar** con Sara — «Sara (en el aula)»
    - **Sara:** Tengo datos. _[plano General]_
    - **Sara:** Los tres salieron del recreo dos minutos antes que nadie. _[plano PrimerPlano de Sara]_
    - **Sara:** Suelen esconderse junto a las taquillas. Y otro dato.
    - **Sara:** Hugo no se reía. En ningún momento. _[plano PPP de Sara]_
    - **Tú:** ¿Te fijaste?
    - **Sara:** Me fijo en todo.
  - **Paso 7.4 · Hablar** con Omar — «Omar (en el pasillo)»
    - **Omar:** Tengo un dibujo. _[plano Medio de Omar]_
    - **Omar:** Bruno le enseñaba algo a Rubén. _[plano General]_
    - **Omar:** Y Hugo… miraba al suelo. _[plano General]_
    - **Tú:** ¿Tus dibujos no mienten?
    - **Omar:** Los dibujos no mienten. Bueno… a veces pongo capas. Pero en esto no.
  - **Paso 7.5 · Hablar** con Profe Lucía — «Lucía (en la pizarra)»
    - **Tú:** Lucía. Me han quitado algo. _[plano Medio de Profe Lucía]_
    - **Profe Lucía:** ¿Te han quitado algo? Uf. _[plano Reaccion de Profe Lucía]_
    - **Profe Lucía:** Sin pruebas no puedo acusar a nadie.
    - **Profe Lucía:** Pero te creo. Si lo encuentras… _[plano PrimerPlano de Profe Lucía]_
    - **Profe Lucía:** vienes y me lo cuentas.
    - **Profe Lucía:** Y nada de correr por los pasillos.
    - **Profe Lucía:** ¿Entendido? _[plano Reaccion de Tú]_
    - **Tú:** Sí.
  - **Paso 7.6 · Hablar** con Ramón — «Ramón (en conserjería)»
    - **Tú:** Ramón. ¿Has visto a Bruno? _[plano General]_
    - **Ramón:** ¿Bruno y compañía? Hace un rato estaban junto a las taquillas. Como siempre.
    - **Ramón:** Y cuando les pillan… salen corriendo hacia el gimnasio. _[plano PrimerPlano de Ramón]_
    - **Ramón:** Se creen que no lo sé. Lo sé todo.
- **Paso 8 · Ir a** Pasillo — «Ve al pasillo»
  - _Lugar:_ Pasillo · _En escena:_ Bruno, Rubén, Hugo
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Cole04_LosVes»** _(música: → Tension)_
    - _En escena:_ Hugo, Bruno, Rubén
    - _Cámara:_ 11 planos (Hombro, General, PrimerPlano, Reaccion, PPP, Seguir)
    - _(si tienes la marca «objeto cromo»)_ **Bruno:** …y ni se ha dado cuenta. Mira qué brillo.
    - _(si tienes la marca «objeto cromo»)_ **Bruno:** El portero legendario.
    - _(si NO tienes la marca «objeto cromo»)_ **Bruno:** …y ni se ha dado cuenta. Mira. La foto del grupito. Qué monos todos.
    - _(si NO tienes la marca «objeto cromo»)_ **Hugo:** Bruno… Vámonos.
    - _(si tienes la marca «ruben rival»)_ **Rubén:** Jejeje. Como lo de la mochila. Igualito.
    - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Bruno… Que es suyo. Devuélveselo y ya está.
    - **Tú:** ¡Eh! ¡Eso es mío!
    - **Bruno:** ¡Corred!
    - _Narrador:_ _No lo piensas. Corres._
  - 🎬 **Escena al completarlo «Cole04_G10_Entra»** _(música: → Tension)_
    - _Narrador:_ _Perdón, piano._
    - _Narrador:_ _El atajo lleva directamente junto al gimnasio._
- **Paso 10 · Ir a** el patio — «¡Síguelos! Corre hacia el patio»
  - _Lugar:_ el patio · _En escena:_ Hugo, Bruno, Rubén
  - 🖐 _Al usar «Atajo por el aula de música»:_
    - _Narrador:_ _Te cuelas por el aula de música (¡perdón, piano!) y sales por la otra puerta, justo al lado del gimnasio._
- **Paso 11 · Escena**
  - _Lugar:_ Pasillo · _En escena:_ Hugo, Bruno, Rubén, Ramón
  - _Narrador:_ _Ramón. El enemigo natural de cualquier niño que corre por el colegio._ _[plano Reaccion de Ramón]_
    - 🎬 **Escena de cámara «Cole04_G11_Musica»** _(música: → Tension)_
  - **Ramón:** ¡Eh! ¡Como te vea corriendo…!
- **Paso 12 · Usar** — «¡Escóndete detrás de las cajas!»
  - 🖐 _Al usar «Detrás de las cajas»:_
    - **Ramón:** Hmm. Juraría que he oído a alguien. _[plano General]_
    - **Ramón:** Serán los gatos. _[plano Reaccion de Ramón]_
    - _Narrador:_ _Esperas. Respiras._ _[plano Reaccion de Tú · silencio 0.9 s]_
- **Paso 13 · Escena** _(solo si tienes la marca «pillado corriendo»)_
  - _(si tienes la marca «pillado corriendo»)_ **Ramón:** ¡Ajá! _[plano Reaccion de Ramón]_
    - 🎬 **Escena de cámara «Cole04_G13_Musica»** _(música: → Tension)_
  - _(si tienes la marca «pillado corriendo»)_ **Ramón:** ¡Te pillé! ¿Tú corriendo? _[plano PrimerPlano de Ramón]_
  - _(si tienes la marca «pillado corriendo»)_ **Ramón:** Esto no me lo esperaba.
  - _(si tienes la marca «pillado corriendo»)_ **Tú:** ¡Es que me han quitado una cosa! ¡Se han ido por ahí!
  - _(si tienes la marca «pillado corriendo»)_ **Ramón:** Vale. Por esta vez. Hugo ha ido hacia el gimnasio.
  - _(si tienes la marca «pillado corriendo»)_ **Ramón:** Andando. ANDANDO. _[plano PrimerPlano de Ramón]_
  - _(si tienes la marca «pillado corriendo»)_ **Tú:** Sí.
  - 🎬 **Escena al completarlo «Cole04_G14_Entra»** _(música: → Tension)_
    - _(si tienes la marca «cole 04 hugo te saca»)_ _Narrador:_ _Lo alcanzas._
- **Paso 14 · Persecución** — «¡Alcanza a Hugo!»
  - _En escena:_ Hugo, Bruno, Rubén
  - 🖐 _Al usar «Atajo por el aula de música»:__(la misma conversación «Atajo» de arriba)_
- **Paso 15 · Escena**
  - _Lugar:_ Almacén del gimnasio · _En escena:_ Hugo
  - **Hugo:** Vale… Vale. _[plano Seguir de Tú]_
    - 🎬 **Escena de cámara «Cole04_G15_Musica»** _(música: → Intima)_
  - **Hugo:** Me rindo. No sé correr. _[plano Medio de Hugo]_
  - **Tú:** ¿Por qué lo habéis hecho?
  - **Hugo:** Yo no quería.
  - **Hugo:** Bruno dijo: Cógelo tú. A ti no te vigilan. Y yo… no sé decir que no. _[plano PrimerPlano de Hugo]_
  - **Hugo:** Bruno no es tan malo. Su hermano mayor se ríe de él todo el rato. _[plano PPP de Hugo]_
  - **Tú:** ¿De verdad?
  - **Hugo:** Delante de sus amigos. Todos los días.
  - **Hugo:** Y él hace lo mismo con los demás. _[plano PrimerPlano de Hugo]_
  - _(si tienes la marca «pista hugo»)_ **Tú:** Mateo te vio. Dice que parecías no querer hacerlo. _[silencio 0.9 s]_
  - _(si tienes la marca «pista hugo»)_ **Hugo:** Porque no quería.
  - _(si tienes la marca «sabe libro hugo»)_ **Tú:** También vi tu libro de piratas en el almacén. _[plano Reaccion de Hugo]_
  - _(si tienes la marca «sabe libro hugo»)_ **Hugo:** ¿La isla de las mil llaves?
  - _(si tienes la marca «sabe libro hugo»)_ **Tú:** Sí.
  - _(si tienes la marca «sabe libro hugo»)_ **Hugo:** ¿Lo has leído? Nadie se fija en eso.
  - **Hugo:** Bruno dice que leer es de pringados. _[plano PPP de Hugo]_
  - **Tú:** A mí me parece bueno.
  - **Hugo:** Gracias.
- **Paso 16 · Escena** _(solo si tienes la marca «lleva cromo»)_
  - _(si tienes la marca «lleva cromo»)_ **Hugo:** Toma. Es tuyo. Lo siento. _[plano General]_
    - 🎬 **Escena de cámara «Cole04_G16_17_Musica»** _(música: → Intima)_
  - _(si tienes la marca «lleva cromo»)_ **Hugo:** De verdad. _[plano PrimerPlano de Hugo]_
  - _(si tienes la marca «lleva cromo»)_ _Narrador:_ _Lo recuperas. Vuelve a tu mochila._ _[plano General]_
  - _(si NO tienes la marca «lleva cromo»)_ **Hugo:** Toma. Es vuestra. _[plano General]_
  - _(si NO tienes la marca «lleva cromo»)_ **Hugo:** No quería romperla. Ni siquiera quería cogerla. _[plano General]_
  - _(si NO tienes la marca «lleva cromo»)_ **Tú:** ¿Por qué no la devolviste?
  - _(si NO tienes la marca «lleva cromo»)_ **Hugo:** Porque… Bruno estaba mirando.
- **Paso 17 · Escena** _(solo si NO tienes la marca «lleva cromo»)_
  - _(la misma conversación «Devuelve» de arriba)_
- **Paso 18 · Escena**
  - **Hugo:** ¿Y ahora qué vas a hacer?
    - 🎬 **Escena de cámara «Cole04_G18_Musica»** _(música: → Tension)_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Contárselo a Lucía. Esto tiene que parar.» _(efecto: Hugo -2; Profe Lucía +3; responsabilidad +2; decisión «malotes» = Lucia)_
      - **Hugo:** Vale. Iré contigo. Si voy yo también…
      - **Hugo:** quizá no se enfade tanto conmigo. _[plano Reaccion de Hugo]_
    - ➤ «Hablar con Bruno. Cara a cara.» _(efecto: Hugo +5; valentia +2; decisión «malotes» = Hablar)_
      - **Hugo:** ¿Sin nadie más? Qué valor.
      - **Hugo:** Me gusta. _[plano Reaccion de Hugo · gesto Happy]_
    - ➤ «Pedir ayuda a mi grupo. Juntos.» _(efecto: Hugo +3; empatia +1; valentia +1; decisión «malotes» = Grupo)_
      - **Hugo:** Tenéis suerte. Un grupo de verdad. Yo tengo… a Bruno.
    - ➤ «Dejarlo estar. Ya tengo lo mío.» _(efecto: Hugo -3; decisión «malotes» = Ignorar)_
      - **Hugo:** Ya. Normal. Bueno. Adiós.
- **Paso 19 · Hablar** con Profe Lucía — «Cuéntaselo a Lucía (en el aula)» _(solo si en «malotes» elegiste «Lucia»)_
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Hugo (te acompaña)
  - _(si en «malotes» elegiste «Lucia»)_ **Tú:** Lucía. Bruno, Rubén y Hugo me quitaron una cosa. Ya la tengo. Pero…
    - 🎬 **Escena de cámara «Cole04_G19_Musica»** _(música: → Intima)_
  - _(si en «malotes» elegiste «Lucia»)_ **Hugo:** Es verdad.
  - _(si en «malotes» elegiste «Lucia»)_ **Hugo:** Yo la cogí. Bruno me lo dijo. Pero yo la cogí. _[plano PrimerPlano de Hugo]_
  - _(si en «malotes» elegiste «Lucia»)_ **Profe Lucía:** Gracias a los dos por decirlo. _[plano Reaccion de Profe Lucía · silencio 0.9 s]_
  - _(si en «malotes» elegiste «Lucia»)_ **Profe Lucía:** Hugo… eso ha sido muy valiente. Hablaré con Bruno. Y con su familia. _[plano PrimerPlano de Profe Lucía]_
  - _(si en «malotes» elegiste «Lucia»)_ **Profe Lucía:** Esto no es una broma. Es hacer daño. Y hay que pararlo. _[plano Medio de Profe Lucía]_
- **Paso 20 · Hablar** con Bruno — «Busca a Bruno (en la puerta del cole)» _(solo si en «malotes» elegiste «Hablar»)_
  - _Lugar:_ Puerta del cole · _En escena:_ Bruno, Rubén
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** ¿Qué quieres? ¿Vienes a chivarte? _[plano Hombro de Tú → Bruno]_
    - 🎬 **Escena de cámara «Cole04_G20_Musica»** _(música: → Intima)_
  - _(si en «malotes» elegiste «Hablar»)_ **Tú:** No. Vengo a hablar contigo.
  - _(si en «malotes» elegiste «Hablar»)_ **Tú:** Hugo me lo ha contado todo. _[plano Hombro de Bruno → Tú]_
  - _(si en «malotes» elegiste «Hablar»)_ **Tú:** Lo de tu hermano también. _[silencio 0.9 s]_
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Hugo habla demasiado.
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Mi hermano me llama enano. _[plano PPP de Bruno]_
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Delante de sus amigos. Todos los días. _[silencio 0.9 s]_
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** ¿Contento? _[plano PPP de Bruno · silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Pues ya sabes lo que se siente. No se lo hagas a otros.» _(efecto: Bruno +6; empatia +2)_
      - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Ya. Vale. Lo pillo. No te prometo nada. Pero lo pillo.
    - ➤ «Eso no te da derecho a quitarme las cosas.» _(efecto: Bruno +2; valentia +1)_
      - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Ya lo sé. Ya lo SÉ. Perdona. Ya está.
      - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** No me hagas repetirlo.
      - _(si en «malotes» elegiste «Hablar»)_ **Rubén:** ¿Bruno pidiendo perdón? Yo no he visto nada. _[plano Reaccion de Rubén]_
  - 🎬 **Escena al completarlo «Cole04_G21_Entra»** _(música: → Intima)_
    - _En escena:_ Omar, Nico, Sara
    - _(si en «malotes» elegiste «Grupo»)_ **Tú:** Necesito ayuda.
    - _(si en «malotes» elegiste «Grupo»)_ **Nico:** ¿Qué ha pasado?
    - _(si en «malotes» elegiste «Grupo»)_ **Tú:** Bruno.
    - _(si en «malotes» elegiste «Grupo»)_ **Sara:** Entendido.
    - _(si en «malotes» elegiste «Grupo»)_ **Omar:** ¿Plan?
    - _(si en «malotes» elegiste «Grupo»)_ **Nico:** Plan. Vamos juntos.
    - _(si en «malotes» elegiste «Grupo»)_ _Narrador:_ _Por primera vez… el grupo no se reúne para jugar._
    - _(si en «malotes» elegiste «Grupo»)_ _Narrador:_ _Se reúne para protegerse._
- **Paso 21 · Ir a** Banco junto al edificio — «Ve a buscar a tu grupo» _(solo si en «malotes» elegiste «Grupo»)_
  - _Lugar:_ Banco junto al edificio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 22 · Hablar** con Bruno — «Id juntos a hablar con Bruno (puerta del cole)» _(solo si en «malotes» elegiste «Grupo»)_
  - _Lugar:_ Puerta del cole · _En escena:_ Bruno, Rubén, Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Hugo (te acompaña)
  - _(si en «malotes» elegiste «Grupo»)_ **Nico:** Bruno. Somos [nombre de tu grupo]. Somos cinco. Y estamos hartos. _[plano DosPlanos de Nico → Bruno]_
    - 🎬 **Escena de cámara «Cole04_G22_Musica»** _(música: → Tension)_
  - _(si en «malotes» elegiste «Grupo»)_ **Sara:** Tenemos pruebas. Testigos. Un dibujo de Omar. Y el horario. _[plano Reaccion de Bruno]_
  - _(si en «malotes» elegiste «Grupo»)_ **Omar:** El dibujo es muy bueno. _[plano General]_
  - _(si en «malotes» elegiste «Grupo»)_ **Omar:** Sales tú con cara de culpable. _[silencio 0.9 s]_
  - _(si en «malotes» elegiste «Grupo»)_ **Bruno:** Vale. Vale. Os dejamos en paz.
  - _(si en «malotes» elegiste «Grupo»)_ **Bruno:** Qué pesados. _[plano Reaccion de Bruno]_
  - _(si en «malotes» elegiste «Grupo»)_ **Bruno:** ¿Tú no vienes, Hugo? _[plano Hombro de Bruno → Hugo]_
  - _(si en «malotes» elegiste «Grupo»)_ **Hugo:** No. Hoy no. _[silencio 0.9 s]_
- **Paso 23 · Escena** _(solo si en «malotes» elegiste «Ignorar»)_
  - _Lugar:_ Almacén del gimnasio · _En escena:_ Hugo
  - _(si en «malotes» elegiste «Ignorar»)_ _Narrador:_ _Ya tienes lo que era tuyo._ _[plano General]_
    - 🎬 **Escena de cámara «Cole04_G23_Musica»** _(música: → Intima)_
  - _(si en «malotes» elegiste «Ignorar»)_ _Narrador:_ _Podías haberte ido. Y te fuiste._ _[plano General · silencio 1.8 s]_
  - _(si en «malotes» elegiste «Ignorar»)_ _Narrador:_ _Pero viste algo que antes no habías visto._ _[plano PrimerPlano de Hugo]_
  - _(si en «malotes» elegiste «Ignorar»)_ _Narrador:_ _Que alguien puede estar haciendo algo mal…_ _[silencio 0.9 s]_
  - _(si en «malotes» elegiste «Ignorar»)_ _Narrador:_ _y aun así necesitar ayuda._
- **Paso 24 · Escena**
  - _Lugar:_ el patio · _En escena:_ Hugo (si NO tienes la marca «hugo solo»)
  - _(si en «malotes» NO elegiste «Ignorar»)_ **Hugo:** ¡[tu nombre]! _[plano Reaccion de Hugo]_
    - 🎬 **Escena de cámara «Cole04_G24_Musica»** _(música: → Intima)_
  - _(si en «malotes» NO elegiste «Ignorar»)_ **Hugo:** Gracias. _[silencio 0.9 s]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ **Hugo:** En serio. _[plano Reaccion de Tú]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ **Hugo:** Nos vemos mañana. _[plano Medio de Hugo]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _Ese día aprendiste algo._ _[plano General]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _Casi nadie es malo del todo._ _[silencio 0.9 s]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _Y casi nadie es valiente todo el tiempo._ _[silencio 0.9 s]_
  - _(si tienes la marca «objeto cromo» y en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _Recuperaste algo que era tuyo._ _[plano General]_
  - _(si en «malotes» NO elegiste «Ignorar» y NO tienes la marca «objeto cromo»)_ _Narrador:_ _Recuperaste una fotografía._ _[plano General]_
  - _(si en «malotes» NO elegiste «Ignorar» y NO tienes la marca «objeto cromo»)_ _Narrador:_ _Pero también recuperaste algo más._ _[silencio 0.9 s]_
  - _(si en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _La confianza en alguien que todavía no sabía cómo defenderse._ _[plano PrimerPlano de Tú]_
  - _(si en «malotes» elegiste «Ignorar» y en «malotes» NO elegiste «Ignorar»)_ **Hugo:** Aquella vez entendí que tenía que aprender a decir que no.
  - _(si en «malotes» NO elegiste «Ignorar»)_ _Narrador:_ _Crecer no consiste solo en aprender a defenderte._ _[plano General]_

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
  - 🎬 **Escena al completarlo «Cole05_G1_Fin»** _(música: → Descubrimiento → Tension)_
    - 🪧 _Rótulo:_ «Un mes después…»
    - _Narrador:_ _Después de lo ocurrido con Bruno…_
    - _Narrador:_ _las cosas estuvieron tranquilas._
    - _Narrador:_ _Durante un tiempo._
    - _Narrador:_ _Algo ha pasado._
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 3 · Escena**
  - _Lugar:_ Pizarra · _En escena:_ Profe Lucía, Bruno
  - **Vega:** ¡Mis pegatinas! ¡Eran brillantes! _[plano Reaccion de Vega]_
    - 🎬 **Escena de cámara «Cole05_G3_Musica»** _(música: → Tension)_
  - **Vega:** Y ahora tengo… esto. _[plano General]_
  - **Álex:** Mis guantes de portera han desaparecido. _[plano Reaccion de Álex]_
  - **Nico:** ¡Y MI TAQUILLA! _[plano General]_
  - **Nico:** ¿Qué es esto? ¿Cuántos huesos tiene el cuerpo humano? _[plano Reaccion de Nico]_
  - **Nico:** ¿QUIÉN HACE UNA BROMA CON PREGUNTAS DE CIENCIAS? ¡Eso no es una broma! ¡Eso es un examen! _[silencio 0.9 s]_
  - **Bruno:** ¡YA ESTÁ BIEN! ¡Todos me miráis a mí! _[plano Reaccion de Bruno]_
  - **Bruno:** ¡Esta vez NO he sido yo! _[plano PrimerPlano de Bruno]_
  - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Tú lo sabes, ¿verdad? Tú hablaste conmigo. Sabes que no miento. _[plano Reaccion de Tú]_
  - **Bruno:** Ya lo pillo. _[plano PrimerPlano de Tú]_
  - **Profe Lucía:** [tu nombre]. Tú descubriste lo de la mochila.
  - **Profe Lucía:** ¿Me ayudas a averiguar qué pasa? Pero hay una regla. _[plano PrimerPlano de Profe Lucía]_
  - **Profe Lucía:** No acuses a nadie sin pruebas. Exactamente. _[plano PPP de Profe Lucía]_
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Habla con quienes sufrieron las bromas»
  - _Lugar:_ Comedor · _En escena:_ Vega, Álex, Nico
  - **Paso 4.1 · Hablar** con Vega — «Vega (en el comedor)»
    - **Vega:** Mis pegatinas de purpurina… Y en su lugar… _[plano Medio de Vega]_
    - **Vega:** ¡Calcetines sucios! _[plano General]_
    - **Vega:** Había una nota. _[plano Reaccion de Vega]_
    - **Vega:** «Nadie mira lo que brilla de verdad». _[plano General]_
    - **Vega:** La letra era perfecta. Ordenadísima. _[plano PrimerPlano de Tú]_
    - **Vega:** Bruno escribe como un pollo. _[silencio 0.9 s]_
  - **Paso 4.2 · Hablar** con Álex — «Álex (en el gimnasio)»
    - **Álex:** Mis guantes de portera. Desaparecidos. _[plano General]_
    - **Álex:** Y después aparecieron… _[silencio 0.9 s]_
    - **Álex:** en la biblioteca. _[plano General]_
    - **Álex:** Bruno no ha pisado la biblioteca en su vida. _[plano Reaccion de Álex]_
  - **Paso 4.3 · Hablar** con Nico — «Nico (en el pasillo)»
    - **Nico:** ¡Mi taquilla está llena de papelitos! _[plano General]_
    - **Nico:** Y todos tienen una pregunta. _[plano General]_
    - **Nico:** ¿Cuántos huesos tiene el cuerpo humano?
    - **Nico:** ¡¿Quién hace eso?! ¿Quién? ¿Tú sabes cuántos? _[plano PrimerPlano de Nico]_
    - **Nico:** ¡No quiero saberlo! ¡Quiero que encuentren al culpable! _[plano Reaccion de Nico]_
- **Paso 5 · Varios objetivos (en cualquier orden)** — «Busca pistas»
  - _Lugar:_ Conserjería · _En escena:_ Ramón
  - **Paso 5.1 · Usar** — «Una nota en la taquilla de Nico»
    - 🖐 _Al usar «Nota en la taquilla de Nico»:_
      - _Narrador:_ _«Doscientos seis. Pero nadie me lo ha preguntado nunca.»_ _[plano General]_
      - _Narrador:_ _Doscientos seis. Los huesos del cuerpo humano._ _[plano PrimerPlano de Tú]_
      - _Narrador:_ _Y la letra… pequeña. Ordenada. Perfecta._ _[plano General]_
  - **Paso 5.2 · Usar** — «Examina dónde aparecieron los guantes»
    - 🖐 _Al usar «Los guantes de Álex»:_
      - _Narrador:_ _«Datos curiosos del universo»_ _[plano General]_
      - _Narrador:_ _Alguien dejó los guantes aquí._ _[plano PrimerPlano de Tú]_
      - _Narrador:_ _Y alguien estaba leyendo este libro._
  - **Paso 5.3 · Usar** — «El registro de salidas de Lucía»
    - 🖐 _Al usar «Registro de salidas al baño»:_
      - _Narrador:_ _Un registro de las salidas al baño._ _[plano General]_
      - _Narrador:_ _Lunes — 11:05 — Iker. Siempre cerca de la hora de las bromas._ _[plano General]_
  - **Paso 5.4 · Hablar** con Ramón — «Las «cámaras» de Ramón (conserjería)»
    - **Ramón:** ¿Buscando al culpable? _[plano General]_
    - **Tú:** Sí.
    - **Ramón:** ¿Y qué has descubierto? ¿Cámaras?
    - **Ramón:** En este colegio no hay cámaras. Hay algo mejor.
    - **Ramón:** Omar. _[plano Reaccion de Ramón]_
    - **Ramón:** Me regala dibujos del pasillo. _[plano General]_
    - **Ramón:** Mira. Alguien con gafas. _[plano General]_
    - _Narrador:_ _De espaldas._ _[plano PrimerPlano de Tú]_
- **Paso 6 · Escena**
  - _Narrador:_ _Letra perfecta._ _[plano General]_
    - 🎬 **Escena de cámara «Cole05_G6_Musica»** _(música: → Tension)_
  - _Narrador:_ _Guantes en la biblioteca._ _[plano General]_
  - _Narrador:_ _Un libro de datos curiosos._ _[plano General]_
  - _Narrador:_ _Bromas con preguntas de ciencias._ _[plano General]_
  - _Narrador:_ _Iker aparece justo a la hora._ _[plano General]_
  - _Narrador:_ _Alguien con gafas._ _[plano General]_
  - **Tú:** Ya sé quién ha sido. Creo. _[plano PrimerPlano de Tú]_
  - _Narrador:_ _Pero creer… no es saber._ _[plano General]_
  - 🎬 **Escena al completarlo «Cole05_G7_Entra»** _(música: → Tension)_
    - _Narrador:_ _Cuatro personas. Cuatro posibilidades._
    - _Narrador:_ _Pero solo una respuesta._
- **Paso 7 · Ir a** Pasillo — «Ve al pasillo: todos los sospechosos están allí»
  - _Lugar:_ Pasillo · _En escena:_ Bruno, Rubén, Omar, Iker
  - 🎬 **Escena al completarlo «Cole05_G8_Entra»** _(música: → Tension)_
    - _En escena:_ Iker, Omar, Rubén
    - **Tú:** Has sido tú, Rubén.
    - **Rubén:** ¿Yo?
    - **Rubén:** Mis bromas son buenas.
    - **Rubén:** Esto de las preguntas de ciencias… es rarísimo.
    - **Rubén:** No es mi estilo.
    - _Narrador:_ _Tiene razón. Rubén esconde cosas._
    - _Narrador:_ _No deja preguntas de ciencias._
    - **Tú:** Omar.
    - **Omar:** ¿Yo?
    - **Omar:** Si yo dibujé al culpable… _[emoción Surprise]_
    - **Omar:** ¿me dibujé a mí mismo de espaldas?
    - **Omar:** Eso sería arte muy moderno. Pero no.
    - _Narrador:_ _Omar no lleva gafas. Otra pista descartada._
    - **Tú:** Iker.
    - **Iker:** ¿Cómo lo has sabido?
    - **Iker:** Vale. Fui yo.
- **Paso 8 · Decisión** — «¿Quién hizo las bromas?»
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
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Vale. Fui yo. Pero no para hacer daño. _[plano Medio de Iker]_
    - 🎬 **Escena de cámara «Cole05_G9_10_11_12_13_14_15_16_17_18_19_20_Musica»** _(música: → Intima → Descubrimiento → Intima → Descubrimiento → Intima)_
  - _(si en «culpable» elegiste «Iker»)_ **Tú:** Entonces, ¿para qué? _[plano PrimerPlano de Tú]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Quería que alguien se diera cuenta.
  - _(si en «culpable» elegiste «Iker»)_ **Tú:** ¿De qué?
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** De las preguntas.
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Nadie pregunta cosas interesantes. Todos juegan. Todos corren. Todos gritan. _[plano General]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Y yo… quería hacer algo que obligara a pensar. _[plano PPP de Iker]_
  - _(si en «culpable» elegiste «Iker»)_ **Tú:** ¿Esconder los guantes de Álex? _[plano Reaccion de Tú]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Eso fue una mala idea. Lo admito.
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Pero quería ver si alguien seguía las pistas.
  - **Iker:** Me gusta descubrir cosas. Y aprender. Pero cuando hablo… nadie escucha.
  - **Iker:** Así que hice que me buscaran. _[plano PrimerPlano de Iker]_
  - **Tú:** Eso no está bien.
  - **Iker:** Ya. Lo sé.
  - **Tú:** Vega se enfadó.
  - **Iker:** Lo sé.
  - **Tú:** Álex pensó que había perdido sus guantes.
  - **Iker:** Lo sé. Por eso quiero arreglarlo.
  - ❓ **Pregunta al jugador:** ¿Qué haces con Iker?
    - ➤ «Tienes que pedirles perdón.» _(efecto: Iker +15; empatia +2; decisión «iker final» = Grupo; marca «iker en el grupo» y «iker debe perdon»)_
      - **Iker:** Vale. A todos.
      - **Tú:** A todos.
      - **Iker:** A todos.
    - ➤ «Puedes hacer bromas, pero no esconder cosas de los demás.» _(efecto: Álex +3; Iker +6; Nico +3; Vega +3; responsabilidad +1; decisión «iker final» = Perdon)_
      - **Iker:** Una broma sin hacer daño. Puedo aprender eso.
    - ➤ «Podrías hacer preguntas sin gastar bromas.» _(efecto: Iker -3; Profe Lucía +3; curiosidad +2; responsabilidad +2; decisión «iker final» = Lucia)_
      - **Iker:** ¿Crees que alguien respondería?
      - **Tú:** Yo sí.
      - **Iker:** Vale. _[plano PrimerPlano de Iker]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Fui yo. _[plano Reaccion de Iker]_
  - _(si en «culpable» elegiste «Iker»)_ **Vega:** ¿Tú? _[plano Reaccion de Vega · silencio 0.9 s]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Sí. Lo siento.
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** También por los guantes. Y por las pegatinas. Y por la taquilla. _[plano Reaccion de Álex]_
  - _(si en «culpable» elegiste «Iker»)_ **Nico:** Vale. Pero mis preguntas eran bastante buenas. _[silencio 0.9 s]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Eran muy buenas.
  - _(si en «culpable» elegiste «Iker»)_ **Nico:** Gracias.
  - _(si en «culpable» elegiste «Iker»)_ **Vega:** ¿Y mis pegatinas? _[plano Reaccion de Vega]_
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Te las devuelvo.
  - _(si en «culpable» elegiste «Iker»)_ **Vega:** Bien. Pero las limpias.
  - _(si en «culpable» elegiste «Iker»)_ **Iker:** Sí.
  - **Profe Lucía:** Iker. Has hecho algo mal.
  - **Profe Lucía:** Pero has hecho algo muy bien.
  - **Iker:** ¿Qué? _[plano PrimerPlano de Iker]_
  - **Profe Lucía:** Lo has reconocido. Ahora toca reparar el daño.
  - **Iker:** ¿Cómo?
  - **Profe Lucía:** Tú dime.
  - **Iker:** Puedo hacer… un concurso de preguntas. _[plano PPP de Iker]_
  - **Nico:** ¿Hay premio? _[plano Reaccion de Nico]_
  - **Iker:** Sí.
  - **Nico:** ¿Qué premio?
  - **Iker:** Saber cosas.
  - **Nico:** Eso no es un premio.
  - **Iker:** Para mí sí.
  - ❓ **Pregunta al jugador:** ¿Qué dices?
    - ➤ «Haz las preguntas fáciles primero.» _(efecto: responsabilidad +1)_
      - **Iker:** Vale. Luego las difíciles.
    - ➤ «Haz una pregunta para cada persona.» _(efecto: empatia +1)_
      - **Iker:** Así nadie se queda fuera.
    - ➤ «Haz una pregunta imposible.» _(efecto: curiosidad +1)_
      - **Iker:** Me gusta. Mucho.
  - **Iker:** Primera pregunta. _[plano General]_
  - **Iker:** ¿Cuántos huesos tiene el cuerpo humano? _[plano Reaccion de Nico]_
  - **Nico:** ¡DOSCIENTOS SEIS!
  - **Iker:** Correcto.
  - **Nico:** ¡JA!
  - **Sara:** Era fácil. _[plano Reaccion de Sara]_
  - **Nico:** Para mí no.
  - **Omar:** ¿Hay alguna pregunta sobre bocadillos? _[plano Reaccion de Omar]_
  - **Iker:** No.
  - **Omar:** Entonces no participo.
  - **Vega:** ¿Y sobre arte? _[plano Reaccion de Vega]_
  - **Iker:** Esa sí.
  - **Iker:** Siguiente pregunta. ¿Qué planeta… _[plano Reaccion de Bruno]_
  - **Bruno:** Marte. _[plano PrimerPlano de Bruno]_
  - **Iker:** Correcto.
  - _Narrador:_ _Por primera vez…_ _[plano Reaccion de Tú]_
  - _Narrador:_ _Iker no necesitaba hacer una broma para conseguir que todos le escucharan._ _[silencio 0.9 s]_
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Oye. _[plano PrimerPlano de Bruno]_
  - _(si tienes la marca «acusaste a bruno»)_ **Tú:** ¿Sí?
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Antes… me acusaste.
  - _(si tienes la marca «acusaste a bruno»)_ **Tú:** Sí. _[silencio 0.9 s]_
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Sin pruebas.
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Pero luego descubriste la verdad. Eso está bien. _[plano PPP de Bruno · silencio 0.9 s]_
  - _(si tienes la marca «acusaste a bruno»)_ **Tú:** Lo siento.
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Vale. Pero la próxima…
  - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** pregunta primero. _[plano Reaccion de Bruno]_
  - _(si tienes la marca «acusaste a bruno»)_ **Tú:** Trato hecho.
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** ¿De verdad pensaste que fui yo? _[plano PrimerPlano de Bruno]_
  - _(si en «culpable» elegiste «Bruno»)_ **Tú:** Sí.
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** Después de lo que hablamos…
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** Vale. Entonces ya sé lo que piensas de mí. _[plano Reaccion de Bruno]_
  - _(si en «culpable» elegiste «Bruno»)_ **Iker:** Bruno no fue. Fui yo. _[plano Reaccion de Tú]_
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** ¿Tú?
  - _(si en «culpable» elegiste «Bruno»)_ **Iker:** Sí.
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** ¿Por qué?
  - _(si en «culpable» elegiste «Bruno»)_ **Iker:** Porque quería que alguien me escuchara.
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** Pues… podrías haber preguntado.
  - _(si en «culpable» elegiste «Bruno»)_ **Iker:** Nadie me escuchaba.
  - _(si en «culpable» elegiste «Bruno»)_ **Bruno:** Yo sí. A veces.
  - _(si en «culpable» elegiste «Ruben»)_ **Rubén:** ¡Pero si yo dije que no era mi estilo! _[plano PrimerPlano de Rubén]_
  - _(si en «culpable» elegiste «Ruben»)_ **Iker:** Porque no eras tú.
  - _(si en «culpable» elegiste «Ruben»)_ **Rubén:** Gracias. Creo.
  - _(si en «culpable» elegiste «Ruben»)_ **Profe Lucía:** Entonces aprendimos algo.
  - _(si en «culpable» elegiste «Ruben»)_ **Profe Lucía:** Una sospecha no es una prueba. _[plano Medio de Profe Lucía]_
  - _(si en «culpable» elegiste «Ruben»)_ **Profe Lucía:** Y una broma deja de ser graciosa cuando alguien sale perjudicado. _[silencio 0.9 s]_
  - _(si en «culpable» elegiste «Omar»)_ **Omar:** ¿Veis? Yo sabía que no era.
  - _(si en «culpable» elegiste «Omar»)_ **Iker:** Tú no llevas gafas.
  - _(si en «culpable» elegiste «Omar»)_ **Omar:** Tengo gafas de sol. Técnicamente…
  - _(si en «culpable» elegiste «Omar»)_ **Iker:** No cuentan.
  - _(si en «culpable» elegiste «Omar»)_ **Omar:** Qué injusticia.
  - **Sara:** ¿Cuántas tienes? _[plano General]_
  - **Iker:** Muchas.
  - **Sara:** ¿Cuántas?
  - **Iker:** Ciento cuarenta y siete.
  - **Sara:** Interesante. Podemos compararlas.
  - **Iker:** ¿De verdad?
  - **Sara:** Sí.
  - **Iker:** Vale.
  - **Nico:** ¿Y mañana hay partido? _[plano Reaccion de Iker]_
  - **Iker:** No.
  - **Nico:** Entonces no sé si puedo venir.
  - **Omar:** Habrá comida.
  - **Nico:** Voy.
- **Paso 10 · Escena**
  - _En escena:_ Iker, Profe Lucía, Bruno
  - **Iker:** Oye. _[plano Seguir de Iker]_
    - 🎬 **Escena de cámara «Cole05_G21_22_23_24_Musica»** _(música: → Intima → Descubrimiento → Intima)_
  - **Tú:** ¿Qué?
  - **Iker:** Gracias.
  - **Iker:** No por descubrirme. Por hablar conmigo después. _[plano PrimerPlano de Iker]_
  - **Iker:** Pensaba que ibas a enfadarte. _[plano Reaccion de Tú]_
  - **Tú:** Lo hice.
  - **Iker:** Ya. Pero no te fuiste.
  - **Nico:** ¡[tu nombre]! _[plano General]_
  - **Sara:** ¡Ven!
  - **Omar:** ¡Hay merienda!
  - **Iker:** ¿Puedo ir? _[plano PrimerPlano de Iker]_
  - **Iker:** Supongo que eso significa que sí. _[plano Reaccion de Tú · silencio 0.9 s]_
  - **Iker:** ¿En serio?
  - **Nico:** Si sabes hacer preguntas raras… puedes venir.
  - **Iker:** Tengo muchas.
  - **Nico:** Entonces eres de los nuestros.
  - **Iker:** Vale. Te lo demostraré. Sí. Creo que sí.
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** Tengo una pregunta. _[plano General]_
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Dime.
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** ¿Sabes dibujar?
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** No.
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** Perfecto.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** ¿Por qué?
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** Porque ya tenemos demasiado talento.
  - _(si en «iker final» elegiste «Perdon»)_ _Narrador:_ _Todavía no forma parte del grupo. Pero ya no está solo._ _[plano PrimerPlano de Iker]_
  - _(si en «iker final» elegiste «Lucia»)_ _Narrador:_ _Algunas amistades necesitan tiempo._ _[plano General]_
  - _Narrador:_ _A veces quieres descubrir la verdad. Y a veces…_ _[plano PrimerPlano de Tú]_
  - _Narrador:_ _descubrirla cambia la forma en que miras a alguien._ _[plano General]_
  - _Narrador:_ _Hoy aprendiste otra cosa._ _[plano General]_
  - _Narrador:_ _Antes de señalar a alguien… busca las pistas._ _[silencio 0.9 s]_
  - _Narrador:_ _Todavía faltaban muchos años para que entendieras a las personas._ _[plano General]_

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
  - 🎬 **Escena al completarlo «Cole06_G1_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _En escena:_ Alumno, Nico, Profe Lucía
    - _Narrador:_ _Al día siguiente, todo parecía normal._
    - _Narrador:_ _Pero había una palabra que se repetía por todo el colegio._
    - **Alumno:** El examen.
    - _Narrador:_ _Y, por alguna razón, sonaba mucho más grande de lo que debería._
    - **Profe Lucía:** Buenos días.
    - **Tú:** Buenos días.
    - **Profe Lucía:** Hoy tengo un pequeño/a aviso.
    - **Nico:** Eso nunca es bueno.
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 3 · Escena**
  - _En escena:_ Profe Lucía, Nico, Sara
  - **Profe Lucía:** Atención. _[plano General]_
    - 🎬 **Escena de cámara «Cole06_G3_Musica»** _(música: → Tension → Descubrimiento)_
  - **Profe Lucía:** Mañana hay examen de Matemáticas. _[plano Medio de Profe Lucía]_
  - **Nico:** ¿Mañana? _[plano Reaccion de Nico]_
  - **Nico:** ¡Pero si mañana hay partido en la tele! _[plano DosPlanos de Nico → Tú]_
  - **Profe Lucía:** Precisamente por eso os aviso hoy.
  - **Sara:** Yo ya he empezado a repasar. _[plano PrimerPlano de Sara]_
  - **Nico:** ¿Desde cuándo?
  - **Sara:** Hace tres semanas.
  - **Nico:** Eso no es estudiar. Eso es prepararse para una guerra. _[plano Reaccion de Nico · silencio 0.9 s]_
  - **Profe Lucía:** Sumas, restas, multiplicaciones y problemas. Y no os voy a mentir. _[plano Medio de Profe Lucía]_
  - **Profe Lucía:** Será el examen más difícil del trimestre. _[plano PrimerPlano de Profe Lucía]_
  - **Profe Lucía:** En la biblioteca hay apuntes.
  - **Profe Lucía:** Marisa os los prestará.
  - **Profe Lucía:** Y recordad algo. _[plano General]_
  - **Profe Lucía:** Estudiar con alguien suele ser más fácil que intentar hacerlo todo solo. _[plano PrimerPlano de Profe Lucía]_
  - **Nico:** ¿Eso significa que puedo copiar?
  - **Nico:** Era una pregunta científica.
  - 🎬 **Escena al completarlo «Cole06_G4_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Marisa
    - **Marisa:** Déjame adivinar.
    - **Marisa:** Matemáticas.
    - **Tú:** ¿Cómo lo sabes?
    - **Marisa:** Hoy han venido diecisiete niños con exactamente la misma cara.
    - **Marisa:** La cara de «ojalá desaparezcan los números».
- **Paso 4 · Ir a** Biblioteca del cole — «Ve a la biblioteca a por los apuntes»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Marisa, Sara, Iker, Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 5 · Hablar** con Marisa — «Pregunta a Marisa, la bibliotecaria»
  - **Marisa:** Hola, cielo. ¿Vienes por los apuntes?
  - **Tú:** Sí.
  - **Marisa:** Todo el mundo viene hoy por lo mismo.
  - **Marisa:** Están ahí. Te los apunto a tu nombre.
  - **Marisa:** Después del examen me los devuelves. _[plano General]_
  - **Tú:** Trato hecho.
  - **Marisa:** Y un consejo. No estudies con el estómago vacío. _[plano PrimerPlano de Marisa]_
  - **Tú:** ¿Eso también es Matemáticas?
  - **Marisa:** No. Pero funciona.
- **Paso 6 · Usar** — «Coge los apuntes de la mesa»
  - 🖐 _Al usar «Apuntes de Matemáticas»:_
    - _Narrador:_ _Los apuntes están llenos de números, operaciones y pequeños dibujos en los márgenes._ _[plano General]_
    - _Narrador:_ _Alguien de otro curso los utilizó antes._ _[plano General]_
    - **Tú:** Este dibujo es horrible.
    - **Iker:** ¡Es un cohete!
    - **Tú:** Parece una patata.
    - **Iker:** Una patata espacial.
- **Paso 7 · Decisión** — «¿Con quién estudias?»
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
  - _(si en «companero estudio» elegiste «Sara»)_ **Sara:** Bien.
  - **Sara:** Si mañana repasas otra vez en casa, el examen es tuyo. _[plano PrimerPlano de Sara]_
  - **Tú:** ¿Y si no?
  - **Sara:** Entonces será más difícil. Mucho más.
  - _(si en «companero estudio» elegiste «Iker»)_ **Iker:** Oye…
  - **Iker:** Gracias. _[plano Medio de Iker]_
  - **Tú:** ¿Por qué?
  - **Iker:** Ha sido la mejor tarde que he pasado estudiando.
  - **Iker:** Y eso que vengo casi todas.
  - _(si en «companero estudio» elegiste «Mateo»)_ **Mateo:** ¡Ya me sé la del nueve!
  - _(si en «companero estudio» elegiste «Mateo»)_ **Tú:** ¿De verdad?
  - _(si en «companero estudio» elegiste «Mateo»)_ **Mateo:** De verdad. Mañana a lo mejor no suspendo. A lo mejor.
  - _(si en «companero estudio» elegiste «Solo»)_ _Narrador:_ _Recoges tus cosas._ _[plano General]_
  - _Narrador:_ _Tienes la cabeza llena de números._ _[plano PrimerPlano de Tú]_
  - _Narrador:_ _Pero es un cansancio bueno._ _[silencio 0.9 s]_
- **Paso 10 · Transición (pasa el tiempo)** — «Esa noche, en casa…»
  - ⏳ _Pantalla de transición:_ «Esa noche, en casa…»
- **Paso 11 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** Te veo con cara de examen. _[plano General]_
  - **Mamá/Papá:** ¿Mañana es el gordo? _[plano PrimerPlano de Tú]_
  - **Tú:** Sí.
  - **Mamá/Papá:** Entonces no pongas esa cara.
  - **Mamá/Papá:** Los números huelen el miedo. _[silencio 0.9 s]_
  - **Abu:** Eso te lo acabas de inventar.
  - **Mamá/Papá:** Sí.
  - ❓ **Pregunta al jugador:** ¿Qué haces esta noche?
    - ➤ «Repasar un poco más antes de dormir» _(efecto: responsabilidad +1; marca «estudiaste mas»)_
      - **Mamá/Papá:** Así me gusta. Pero a las diez, a la cama.
      - **Mamá/Papá:** Un cerebro cansado/a tampoco suma bien.
    - ➤ «Pedir ayuda a Abu» _(efecto: Abu +5; marca «estudiaste mas»)_
      - **Abu:** ¿Matemáticas? _[plano Medio de Abu]_
      - **Tú:** Sí.
      - **Abu:** En mis tiempos contábamos con garbanzos.
      - **Tú:** ¿Funcionaba?
      - **Abu:** Siempre que no te los comieras antes.
      - **Abu:** Ven. Te enseño un truco.
    - ➤ «Ver el partido. Ya he estudiado bastante.» _(efecto: humor +1)_
      - **Mamá/Papá:** Bueno… Tú sabrás. _[plano Medio de Mamá/Papá]_
      - **Tú:** ¿Eso es un sí?
      - **Mamá/Papá:** Eso es un «mañana no me digas que no te avisé».
  - 🎬 **Escena al completarlo «Cole06_G12_Entra»**
    - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _No sabes si estás preparado/a._
    - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _Pero al menos sabes que lo has intentado._
- **Paso 12 · Clase** — «Repasa un poco más» _(solo si tienes la marca «estudiaste mas»)_
- **Paso 13 · Transición (pasa el tiempo)** — «El día del examen…»
  - ⏳ _Pantalla de transición:_ «El día del examen…»
  - 🎬 **Escena al completarlo «Cole06_G13_Fin»** _(música: → Tension)_
    - 🪧 _Rótulo:_ «El día del examen…»
    - _Narrador:_ _El día del examen llegó._
- **Paso 14 · Ir a** Aula de 1.º A — «Ve a clase: hoy es el examen»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía
- **Paso 15 · Escena**
  - _Lugar:_ Pizarra
  - **Profe Lucía:** Tenéis tiempo. _[plano General]_
    - 🎬 **Escena de cámara «Cole06_G15_Musica»** _(música: → Tension)_
  - **Profe Lucía:** Leed bien cada pregunta. Y respirad. _[plano Medio de Profe Lucía]_
  - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _Anoche repasaste. No sabes si será suficiente._ _[plano PPP de Tú · silencio 0.9 s]_
  - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _Pero algo ha cambiado._
  - _(si tienes la marca «estudiaste mas»)_ _Narrador:_ _Estás más tranquilo/a._
  - 🎬 **Escena al completarlo «Cole06_G16_Entra»**
    - _(si tu última nota es menor que 5)_ _Narrador:_ _La respuesta no sale. No pasa nada._
    - _(si tu última nota es menor que 5)_ _Narrador:_ _Respiras y vuelves a intentarlo._
    - _(si tu última nota es 7 o más)_ _Narrador:_ _Una._
    - _Narrador:_ _Dos._
    - _Narrador:_ _Y empiezas a confiar en ti._
- **Paso 16 · Clase** — «El examen de Matemáticas»
  - _Lugar:_ Aula de 1.º A
- **Paso 17 · Cinemática** _(solo si tu última nota es 5 o más)_
  - _En escena:_ Profe Lucía, Sara (si en «companero estudio» elegiste «Sara»), Iker (si en «companero estudio» elegiste «Iker»), Mateo (si en «companero estudio» elegiste «Mateo»)
  - 🎬 **Cinemática «Cole06_LaNota»** _(música: → Intima)_
    - _En escena:_ Mateo, Profe Lucía, Iker, Sara
    - _Cámara:_ 9 planos (General, Medio, Hombro, PrimerPlano, PPP, Reaccion)
    - _(si tu última nota es 5 o más)_ **Profe Lucía:** Ya tengo las notas.
    - _(si tu última nota es 5 o más)_ **Profe Lucía:** Silencio, que muerdo.
    - _(si tu última nota es 5 o más)_ **Profe Lucía:** [tu nombre]…
    - _(si tu última nota es 5 o más y tu última nota es menor que 9)_ **Profe Lucía:** Aprobado. Y se nota el trabajo.
    - _(si tu última nota es 5 o más)_ **Profe Lucía:** Un sobresaliente. Estoy muy impresionada. De verdad.
    - _(si tienes la marca «estudiaste mas» y tu última nota es 5 o más)_ **Profe Lucía:** Y anoche repasaste, ¿a que sí?
    - _(si tienes la marca «estudiaste mas» y tu última nota es 5 o más)_ **Profe Lucía:** Se nota en los problemas.
    - _(si en «companero estudio» elegiste «Sara» y tu última nota es 5 o más)_ **Sara:** ¡Lo sabía!
    - _(si en «companero estudio» elegiste «Sara» y tu última nota es 5 o más)_ **Sara:** El plan de los veinte minutos funciona.
    - _(si en «companero estudio» elegiste «Mateo» y tu última nota es 5 o más)_ **Mateo:** ¡He aprobado yo también! ¡Por los pelos!
    - _(si en «companero estudio» elegiste «Iker» y tu última nota es 5 o más)_ **Iker:** Dato curioso. Estudiar acompañado mejora el aprendizaje.
    - _(si en «companero estudio» elegiste «Iker» y tu última nota es 5 o más)_ **Iker:** Acabamos de demostrarlo.
    - _(si en «companero estudio» elegiste «Solo» y tu última nota es 5 o más)_ **Tú:** Sin nadie. Solo yo y los números.
    - _(si en «companero estudio» elegiste «Solo» y tu última nota es 5 o más)_ **Tú:** Y esta vez… he ganado yo.
- **Paso 18 · Escena** _(solo si tu última nota es menor que 5)_
  - _Lugar:_ Pizarra · _En escena:_ Profe Lucía
  - _(si tu última nota es menor que 5)_ **Profe Lucía:** [tu nombre], ven un momento.
    - 🎬 **Escena de cámara «Cole06_G18_Musica»** _(música: → Intima → Descubrimiento)_
  - _(si tu última nota es menor que 5)_ **Profe Lucía:** Esta vez no ha salido. _[plano Medio de Profe Lucía]_
  - _(si tu última nota es menor que 5)_ **Profe Lucía:** Y sé que no es agradable. _[plano PrimerPlano de Profe Lucía · silencio 0.9 s]_
  - _(si tu última nota es menor que 5)_ **Profe Lucía:** Pero un examen no dice quién eres.
  - _(si tu última nota es menor que 5)_ **Profe Lucía:** Solo dice qué necesitas practicar. _[plano DosPlanos de Tú → Profe Lucía]_
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Profe Lucía:** Y sé que estudiaste. Por eso me fastidia más que a ti.
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Profe Lucía:** Esta tarde hago clases de repaso.
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Profe Lucía:** Si vienes, tendrás otra oportunidad.
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Tú:** ¿De verdad?
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Profe Lucía:** De verdad. ¿Trato?
  - _(si tienes la marca «estudiaste mas» y tu última nota es menor que 5)_ **Tú:** Trato.
  - _(si tu última nota es menor que 5 y NO tienes la marca «estudiaste mas»)_ **Profe Lucía:** Creo que ya sabes qué ha pasado.
  - _(si tu última nota es menor que 5 y NO tienes la marca «estudiaste mas»)_ **Tú:** Sí.
  - _(si tu última nota es menor que 5 y NO tienes la marca «estudiaste mas»)_ **Profe Lucía:** No pasa nada. Pero la próxima vez tendremos que prepararnos un poco mejor.
  - _(si tu última nota es menor que 5 y NO tienes la marca «estudiaste mas»)_ **Tú:** Vale.
  - _(si tu última nota es menor que 5 y NO tienes la marca «estudiaste mas»)_ **Profe Lucía:** Y yo te ayudaré.
  - 🎬 **Escena al completarlo «Cole06_G19_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Marisa
    - **Marisa:** Mira quién vuelve.
    - **Tú:** Aquí están.
- **Paso 19 · Ir a** Biblioteca del cole — «Devuelve los apuntes a Marisa»
  - _Lugar:_ Biblioteca del cole · _En escena:_ Marisa
- **Paso 20 · Hablar** con Marisa — «Devuélvele los apuntes»
  - _Lugar:_ Mostrador de la biblioteca
  - **Marisa:** Enteros. Y sin manchas de chocolate.
    - 🎬 **Escena de cámara «Cole06_G20_Musica»** _(música: → Intima)_
  - **Marisa:** Te acabas de ganar un sitio en mi lista de favoritos.
  - **Marisa:** No se lo digas a nadie. _[silencio 0.9 s]_
  - **Tú:** ¿Por qué?
  - **Marisa:** Porque tengo reputación que mantener.
  - _Narrador:_ _No fue solo un examen._ _[plano PrimerPlano de Tú]_
  - _Narrador:_ _Fue la primera vez que descubriste que prepararte también era una forma de creer en ti._
  - _(si tu última nota es 5 o más)_ _Narrador:_ _Y esta vez, los números perdieron._
  - _(si tu última nota es 9 o más)_ _Narrador:_ _Y descubriste que podías llegar mucho más lejos de lo que pensabas._
  - _(si tu última nota es menor que 5)_ _Narrador:_ _Y también descubriste algo importante._
  - _(si tu última nota es menor que 5)_ _Narrador:_ _Fallar una vez no significa haber perdido._ _[silencio 0.9 s]_
  - _Narrador:_ _Mañana habría otra cosa que aprender._ _[plano General]_

**Al terminar (momento de la biografía):** «Tu primer examen de verdad»

---

### Nino_Recados · «Recados por el barrio»

**Resumen:** Tu familia confía en ti: te pide que compres el material del cole y unas medicinas, y que vuelvas a casa.

**Requisitos:** has terminado «El examen imposible» y has vivido el 36 % de la etapa

**Pasos:**

- **Paso 1 · Acción del jugador** — «Compra el material del colegio en la librería»
  - _Lugar:_ la librería
  - 🎬 **Escena al completarlo «Nino_Recados_G1_Fin»** _(música: → Descubrimiento → Descubrimiento)_
    - _En escena:_ Mamá/Papá
    - **Mamá/Papá:** Necesitamos unas cosas para el cole.
    - **Mamá/Papá:** Te he preparado/a una lista. ¿Crees que puedes encargarte?
    - **Mamá/Papá:** Eso quería oír.
    - **Mamá/Papá:** Y guarda la lista.
    - **Tú:** Sí.
    - **Mamá/Papá:** La última vez la perdiste.
    - **Tú:** Fue una vez.
    - **Mamá/Papá:** Tres.
    - **Tú:** Dos y media.
    - **Mamá/Papá:** Venga. Dos y media.
    - _Narrador:_ _Dependiente/a: «¡Buenos días!»_
    - **Tú:** Buenos días.
    - _Narrador:_ _Dependiente/a: «¿Qué necesitas?»_
    - **Tú:** Dos cuadernos.
    - **Tú:** Un lápiz.
    - **Tú:** Y colores.
    - _Narrador:_ _Dependiente/a: «Creo que no te falta nada.»_
    - **Tú:** Creo que no.
    - _Narrador:_ _Dependiente/a: «¿Seguro?»_
    - **Tú:** Sí.
    - _Narrador:_ _Dependiente/a: «Buena costumbre.»_
    - _Narrador:_ _Vecino: «¡Uy!»_
    - _Narrador:_ _Farmacéutico/a: «Buenos días.»_
    - **Tú:** Hola.
    - **Tú:** Necesito esto.
    - _Narrador:_ _Farmacéutico/a: «Perfecto.»_
    - _Narrador:_ _Farmacéutico/a: «¿Es para alguien de casa?»_
    - **Tú:** Sí.
    - _Narrador:_ _Farmacéutico/a: «Entonces guárdalo bien y dáselo cuando llegues.»_
    - **Tú:** Vale.
    - _Narrador:_ _Farmacéutico/a: «Aquí tienes.»_
    - **Tú:** Gracias.
    - _Narrador:_ _Farmacéutico/a: «Buen viaje de vuelta.»_
    - **Tú:** Está cerca.
    - _Narrador:_ _Farmacéutico/a: «Entonces mejor todavía.»_
- **Paso 2 · Acción del jugador** — «Tu familia necesita medicinas: cómpralas en la farmacia»
  - _Lugar:_ la farmacia
  - 🎬 **Escena al completarlo «Nino_Recados_G3_Entra»** _(música: → Intima)_
    - _En escena:_ Mamá/Papá
    - **Mamá/Papá:** ¿Ya estás aquí?
    - **Tú:** Sí.
    - **Mamá/Papá:** Está todo.
    - **Tú:** Te dije que podía.
    - **Mamá/Papá:** Sí. Me lo dijiste. Y no te has olvidado de nada.
    - **Tú:** Lo comprobé dos veces.
    - **Mamá/Papá:** Eso también es aprender.
    - **Mamá/Papá:** Entonces has tardado justo lo que tenías que tardar.
    - **Tú:** ¡Lo sabía!
    - **Mamá/Papá:** ¿Lo sabías?
    - **Tú:** Bueno… Lo sospechaba.
    - _Narrador:_ _Hasta ese día, siempre había alguien que iba contigo._
    - _Narrador:_ _Esta vez habías ido tú._
    - _Narrador:_ _No parecía gran cosa. Pero crecer también era esto._
    - _Narrador:_ _Que poco a poco empezaran a confiar en ti._
    - _Narrador:_ _Vecino: «¡Eh! Tú eres quien me ayudó aquel día.»_
    - **Mamá/Papá:** Ya sé que tú no necesitas que te recuerde todo.
    - _Narrador:_ _«Ya no solo explorabas Valmar. Empezabas a formar parte de él.»_
- **Paso 3 · Ir a** tu casa familiar — «Vuelve a tu casa familiar con todo»

**Al terminar (momento de la biografía):** «Mis primeros recados»

---

### Cole07_Excursion · «La excursión»

**Resumen:** ¡Excursión a la Granja escuela de Villaverde! Autobús, animales, campo… y un susto.

_Tipo: Historia · Episodio especial · Edad: 9-9 años · Duración: 25-35 min_

**Requisitos:** has terminado «Recados por el barrio» y has vivido el 44 % de la etapa

**Lo que puede cambiar:** Te sientas con… · Encuentras a Mateo (u Omar) · Avisas a Lucía o le traes tú

**Pasos:**

- **Paso 1 · Transición (pasa el tiempo)** — «Semanas después, un día muy esperado…»
  - ⏳ _Pantalla de transición:_ «Semanas después, un día muy esperado…»
  - 🎬 **Escena al completarlo «Cole07_G1_Fin»** _(música: → Descubrimiento → Intima)_
    - _En escena:_ Rubén, Bruno
    - 🪧 _Rótulo:_ «Semanas después…»
    - _Narrador:_ _En el colegio había días normales._
    - _Narrador:_ _Y luego estaban los días de excursión._
    - _Narrador:_ _Este era de los segundos._
    - **Bruno:** ¡Yo me pido la última fila!
    - **Rubén:** ¡Yo voy contigo!
    - **Bruno:** No he dicho eso.
    - **Rubén:** Demasiado tarde.
- **Paso 2 · Ir a** Autobús escolar — «Ve al autobús de la excursión (en la puerta del cole)»
  - _Lugar:_ Autobús escolar · _En escena:_ Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno
  - 💬 _Comentario al pasar cerca de Bruno:_ «¡Yo me pido la última fila!»
- **Paso 3 · Escena**
  - **Profe Lucía:** ¡Todos arriba! Y contad cuántos sois en vuestra fila. _[plano General]_
    - 🎬 **Escena de cámara «Cole07_G3_Musica»** _(música: → Intima)_
  - **Profe Lucía:** Y nadie se deja nada en el autobús. ¿De acuerdo? _[plano Medio de Profe Lucía]_
  - _Narrador:_ _Todos: «¡Sí!»_
  - **Nico:** ¡[tu nombre]! ¡Aquí hay sitio! _[plano Reaccion de Nico]_
  - **Nico:** ¡Rápido antes de que alguien me lo quite! _[plano DosPlanos de Tú → Nico]_
  - **Sara:** Yo tengo la ventana. Puedo compartirla. A ratos.
  - **Nico:** Eso no es compartir.
  - **Sara:** Es compartir científicamente.
  - _Narrador:_ _Busca con quién sentarte._
- **Paso 4 · Decisión** — «¿Con quién te sientas en el autobús? (habla con quien elijas)»
  - ➤ **Opción «Con Nico»** (con Nico) _(efecto: decisión «asiento bus» = Nico; Nico +5)_
    - **Nico:** ¡Bien! Tengo un juego.
    - **Tú:** ¿Cuál?
    - **Nico:** El que vea más vacas gana. ¡Una! ¡Dos!
    - **Tú:** Llevamos diez segundos.
    - **Nico:** Por eso voy ganando.
  - ➤ **Opción «Con Sara»** (con Sara) _(efecto: decisión «asiento bus» = Sara; Sara +5)_
    - **Sara:** He preparado/a una lista de las plantas que podemos encontrar.
    - **Tú:** ¿Has traído una lupa?
    - **Sara:** Dos. Por si una falla.
  - ➤ **Opción «Con Omar»** (con Omar) _(efecto: decisión «asiento bus» = Omar; Omar +5)_
    - **Omar:** Te he guardado medio bocadillo. Bueno… Un cuarto.
    - **Tú:** ¿Qué ha pasado con el otro cuarto?
    - **Omar:** Ha sido una emergencia.
  - ➤ **Opción «Con Mateo»** (con Mateo) _(efecto: decisión «asiento bus» = Mateo; Mateo +5)_
    - **Mateo:** Nunca he ido de excursión.
    - **Mateo:** En mi otro cole no íbamos. Estoy contento. _[silencio 0.9 s]_
    - **Mateo:** Y un poco nervioso/a. _[silencio 0.9 s]_
    - **Tú:** Yo también.
  - ➤ **Opción «Con Hugo»** (con Hugo) _(efecto: decisión «asiento bus» = Hugo; Hugo +6)_
    - **Hugo:** ¿Conmigo?
    - **Tú:** Sí.
    - **Hugo:** Antes siempre me sentaba donde decía Bruno. Esto está mejor.
    - **Hugo:** ¿Quieres que te enseñe una parte?
- **Paso 5 · Escena**
  - _Narrador:_ _El autobús salió de Valmar._ _[plano General]_
    - 🎬 **Escena de cámara «Cole07_G5_Musica»** _(música: → Intima)_
  - **Omar:** Ya me he comido el bocadillo. _[plano General]_
  - **Omar:** Estamos en el primer kilómetro. _[silencio 0.9 s]_
  - **Sara:** Técnicamente, en el kilómetro cero coma ocho.
  - **Omar:** No me estropees la emoción.
  - **Nico:** ¡VACA! ¡Siete! ¡Voy ganando!
  - **Profe Lucía:** ¡Ya llegamos! Villaverde. La Granja Escuela. _[plano General]_
  - **Profe Lucía:** Recordad: los animales no son juguetes. _[silencio 0.9 s]_
- **Paso 6 · Cinemática**
  - 🎬 **Cinemática «Cole07_G6»** _(música: → Intima)_
    - _En escena:_ Nico, Omar, Sara
    - _Cámara:_ 4 planos (General, Dolly)
    - **Nico:** ¡CABALLOS!
    - **Omar:** Primero el bocadillo.
    - **Sara:** Primero las normas.
    - **Omar:** Tú eres el motivo por el que existen las normas.
- **Paso 7 · Escena**
  - _Lugar:_ las granjas de Villaverde · _En escena:_ Paula, Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno
  - 💬 _Comentario al pasar cerca de Bruno:_ «Huele a vaca. Me encanta. No se lo digáis a nadie.»
  - **Paula:** ¡Bienvenidos a la Granja Escuela!
    - 🎬 **Escena de cámara «Cole07_G7_Musica»** _(música: → Descubrimiento)_
  - **Paula:** Soy Paula. _[plano Medio de Paula]_
  - **Paula:** Aquí tenemos gallinas, caballos, un huerto y un tractor. Y una norma de oro. _[plano General]_
  - **Paula:** Nadie se separa del grupo.
  - **Paula:** El campo es grande y algunas zonas se parecen mucho. _[plano PrimerPlano de Paula]_
  - **Profe Lucía:** Así que siempre a la vista.
  - **Paula:** Exactamente. Podéis explorar. Pero juntos.
  - **Bruno:** Huele a caca de vaca.
  - **Paula:** Huele a campo, jovencito. Y son caballos.
  - **Bruno:** Eso explica muchas cosas. _[plano Reaccion de Bruno]_
- **Paso 8 · Varios objetivos (en cualquier orden)** — «Descubre la granja»
  - 🎬 **Escena al completarlo «Cole07_G9_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Omar, Nico, Paula
    - **Paula:** ¡Perfecto!
    - **Nico:** ¡Eso ha sido un lanzamiento profesional!
    - **Paula:** Bien hecho.
    - **Omar:** Creo que esa no confía en ti.
    - **Paula:** Dale tiempo.
  - **Paso 8.1 · Usar** — «Dar de comer a las gallinas»
    - 🖐 _Al usar «Las gallinas»:_
      - **Paula:** Estas son Clotilde, Remedios y la Señora Bigotes. _[plano General]_
      - **Tú:** ¿Tiene bigotes? _[silencio 0.9 s]_
      - **Paula:** No. Se lo pusimos por fastidiar. Échalo cerca. No encima.
      - **Tú:** ¡Eh! _[plano Reaccion de Tú]_
      - **Paula:** Te ha elegido.
  - **Paso 8.2 · Usar** — «Coger zanahorias en el huerto»
    - 🖐 _Al usar «El huerto»:_
      - **Nico:** ¡Eso es gigante! _[plano Reaccion de Tú · silencio 0.9 s]_
      - **Sara:** Técnicamente, es una raíz.
      - **Sara:** Pero es una raíz impresionante. _[silencio 0.9 s]_
      - **Omar:** Eso da para cuatro bocadillos.
  - **Paso 8.3 · Usar** — «Acariciar a los caballos»
    - 🖐 _Al usar «Los caballos»:_
      - **Tú:** ¡Hace cosquillas! _[plano General]_
      - **Omar:** Lo voy a dibujar. Tiene cara de llamarse Galleta.
      - **Tú:** ¿Por qué Galleta?
      - **Omar:** No sé. Pero míralo.
  - **Paso 8.4 · Usar** — «Subirte al tractor»
    - 🖐 _Al usar «El tractor»:_
      - **Julián:** ¿Quieres subir? _[plano General]_
      - **Tú:** Sí.
      - **Julián:** Arriba. Manos en el volante. ¡Brrrrum! Sin arrancar.
      - **Nico:** ¡Hazme una foto!
      - **Nico:** ¡Hazme una foto! _[plano Reaccion de Nico]_
- **Paso 9 · Minijuego** — «Echa el grano a las gallinas»
  - 🎮 _Cómo se juega:_ Suelta el grano cuando la aguja esté en verde
- **Paso 10 · Escena**
  - _En escena:_ Paula, Profe Lucía, Julián, Nico (te acompaña), Sara (te acompaña), Omar (si tienes la marca «ayudaste a mateo») (te acompaña)
  - **Profe Lucía:** A ver… Uno. Dos. _[plano General]_
    - 🎬 **Escena de cámara «Cole07_G10_Musica»** _(música: → Tension)_
  - **Profe Lucía:** Un momento. _[plano PrimerPlano de Profe Lucía · silencio 0.9 s]_
  - _(si tienes la marca «ayudaste a mateo»)_ **Profe Lucía:** Falta Mateo.
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Profe Lucía:** Falta Omar. _[plano Reaccion de Tú]_
  - **Paula:** Tranquilidad. Suele pasar. _[plano Reaccion de Tú]_
  - **Paula:** Alguien ve algo bonito y se despista.
  - **Profe Lucía:** [tu nombre].
  - **Profe Lucía:** Tú y tus amigos, mirad por la zona del granero y el silo. _[plano Hombro de Tú → Profe Lucía]_
  - **Profe Lucía:** Sin alejaros de la granja. _[silencio 0.9 s]_
  - **Tú:** Vale.
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Busca pistas por la granja»
  - 🎬 **Escena al completarlo «Cole07_G12_Entra»** _(música: → Tension)_
    - **Tú:** ¿Hola? ¿Mateo?
  - **Paso 11.1 · Usar** — «Una mochila en la hierba»
    - 🖐 _Al usar «Una mochila en la hierba»:_
      - _(si tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Una mochila llena de cromos. Es la de Mateo._ _[plano General]_
      - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Un cuaderno de dibujo._
      - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Y unas migas de bocadillo._
      - _(si NO tienes la marca «ayudaste a mateo»)_ _Narrador:_ _Es la mochila de Omar._
  - **Paso 11.2 · Usar** — «Una botella junto al silo»
    - 🖐 _Al usar «Una botella de agua»:_
      - _Narrador:_ _Una botella medio vacía._ _[plano General]_
      - _Narrador:_ _Huellas pequeñas. Y otras todavía más pequeñas. De pezuñas._ _[plano General]_
  - **Paso 11.3 · Usar** — «Un papel junto al granero»
    - 🖐 _Al usar «Un mapa dibujado»:_
      - _Narrador:_ _«¡Le sigo!»_ _[plano General]_
      - **Tú:** Creo que sé dónde ha ido. _[plano PrimerPlano de Tú]_
  - **Paso 11.4 · Hablar** con Julián — «Pregunta a Julián, el granjero (junto al silo)»
    - **Tú:** ¿Has visto a alguien?
    - **Julián:** ¿Un chaval? Sí. Iba detrás de Copito.
    - **Tú:** ¿Copito?
    - **Julián:** El corderito que siempre se escapa.
    - **Julián:** Siempre acaba detrás del granero.
    - **Julián:** Allí crece la hierba buena.
    - **Tú:** Gracias.
    - **Julián:** Y esta vez intentad que Copito no os lleve de excursión a vosotros.
- **Paso 12 · Ir a** Granero — «Busca detrás del granero»
  - _Lugar:_ Granero · _En escena:_ Paula, Profe Lucía, Nico (te acompaña), Sara (te acompaña), Mateo (si tienes la marca «ayudaste a mateo»), Omar (si NO tienes la marca «ayudaste a mateo»)
- **Paso 13 · Escena**
  - _En escena:_ Mateo (si tienes la marca «ayudaste a mateo»), Omar (si NO tienes la marca «ayudaste a mateo»), Nico (te acompaña), Sara (te acompaña)
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** ¡[tu nombre]! Se había escapado y… Lo seguí. _[plano General]_
    - 🎬 **Escena de cámara «Cole07_G13_Musica»** _(música: → Tension → Intima)_
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Y luego no sabía volver. Todo se parece. _[silencio 0.9 s]_
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Omar:** ¡[tu nombre]! Lo estaba dibujando. Se movió.
  - _(si NO tienes la marca «ayudaste a mateo»)_ **Omar:** Y lo seguí para terminar el dibujo. Y luego… No sabía volver. _[silencio 0.9 s]_
  - _Narrador:_ _El susto empieza a convertirse en alivio._ _[plano PrimerPlano de Tú]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Le das la mano y volvéis juntos» _(efecto: Mateo +8; Omar +8; empatia +1; decisión «rescate» = Juntos)_
      - **Tú:** Venga. Volvemos juntos. _[plano Medio de Tú]_
      - _Narrador:_ _Volvéis por el camino._
      - **Tú:** Creo que él también sabe volver. _[plano General]_
    - ➤ «Te quedas con él y mandas a Nico a avisar a Lucía» _(efecto: Profe Lucía +3; Mateo +5; Omar +5; responsabilidad +1; decisión «rescate» = Avisar)_
      - **Tú:** Quédate aquí. Nico, avisa a Lucía.
      - **Nico:** ¡Voy! ¡Soy el más rápido! ¡Bueno! ¡Casi!
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Gracias por quedarte. _[plano PrimerPlano de Mateo]_
      - _(si NO tienes la marca «ayudaste a mateo»)_ **Omar:** Gracias por quedarte.
      - **Tú:** No iba a dejarte solo.
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Gracias. _[silencio 0.9 s]_
      - _(si NO tienes la marca «ayudaste a mateo»)_ **Omar:** Gracias.
- **Paso 14 · Escena**
  - _Lugar:_ las granjas de Villaverde · _En escena:_ Paula, Profe Lucía, Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Bruno
  - **Profe Lucía:** ¡Aquí estáis! _[plano Seguir de Profe Lucía]_
    - 🎬 **Escena de cámara «Cole07_G14_Musica»** _(música: → Intima)_
  - **Profe Lucía:** Menudo susto. Pero estáis bien. Buen trabajo, equipo. _[plano PrimerPlano de Profe Lucía]_
  - **Profe Lucía:** Buen trabajo de verdad.
  - **Paula:** Y tú… A tu corral. Eres un fugitivo profesional.
  - **Nico:** Yo le contrataría. Como mascota. _[plano Reaccion de Nico]_
  - **Profe Lucía:** Antes de volver. Foto de grupo. Bruno.
  - **Profe Lucía:** Sin cuernos con los dedos.
  - **Bruno:** ¡Pero si todavía no los estaba haciendo!
  - **Profe Lucía:** Precisamente.
- **Paso 15 · Cinemática**
  - 🎬 **Cinemática «Cole07_G15»** _(música: → Intima efecto Momento)_
    - _En escena:_ Profe Lucía
    - _Cámara:_ 4 planos (General, Medio, PrimerPlano)
    - 🪧 _Rótulo:_ «La excursión a Villaverde»
    - **Profe Lucía:** ¡Todos juntos! ¡A la de tres!
    - **Profe Lucía:** ¡Una! ¡Dos! ¡Tres!
    - _Narrador:_ _Años después quizá no recordarías todas las cosas que viste aquel día._
    - _Narrador:_ _Pero sí recordarías cómo te sentías._
- **Paso 16 · Escena**
  - **Tú:** ¿Qué haces? _[plano Reaccion de Sara]_
    - 🎬 **Escena de cámara «Cole07_G16_Musica»** _(música: → Descubrimiento → Tema)_
  - **Sara:** Registro de observación.
  - **Tú:** ¿De qué?
  - **Sara:** Ronquido nivel tres.
  - **Andrés:** ¡Atención, deportistas!
  - **Nico:** ¿Qué?
  - **Andrés:** Cuando volvamos… ¡Empieza el torneo del colegio!
  - **Nico:** ¿TORNEO?
  - **Nico:** ¡ESTOY DESPIERTO! _[plano PrimerPlano de Nico]_
  - **Omar:** Yo también. Creo.
  - _Narrador:_ _Aquel día aprendiste que una excursión podía ser muchas cosas._ _[plano General]_
  - _Narrador:_ _Un viaje._ _[plano General]_
  - _Narrador:_ _Un susto._ _[plano General]_
  - _Narrador:_ _Y un recuerdo que se quedaría contigo mucho después de volver a casa._ _[plano General]_
  - **Nico:** ¡TORNEO!

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
  - 🎬 **Escena al completarlo «Cole08_G1_Fin»** _(música: → Intima → Intima)_
    - _En escena:_ Nico, Bruno, Álex, Sara
    - _Narrador:_ _El lunes siguiente, el colegio ya no hablaba de otra cosa._
    - _Narrador:_ _El torneo había llegado._
    - **Nico:** ¡Fútbol! ¡Aquí! ¡FÚTBOL!
    - **Álex:** Baloncesto. Sin gritar. Con estilo.
    - **Sara:** Atletismo: ciencia aplicada a correr.
    - **Bruno:** Da igual el deporte. Os vamos a ganar en todos.
- **Paso 2 · Ir a** la pista de deporte — «Ve a la pista: Andrés reúne a toda la clase»
  - _Lugar:_ la pista de deporte · _En escena:_ Andrés, Nico, Álex, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén
  - 💬 _Comentario al pasar cerca de Nico:_ «¡Fútbol! ¡Aquí! ¡FÚTBOL!»
  - 💬 _Comentario al pasar cerca de Álex:_ «Baloncesto. Sin gritar. Con estilo.»
  - 💬 _Comentario al pasar cerca de Sara:_ «Atletismo: ciencia aplicada a correr.»
  - 💬 _Comentario al pasar cerca de Bruno:_ «Da igual el deporte. Os vamos a ganar en todos.»
- **Paso 3 · Escena**
  - **Andrés:** ¡Atención, deportistas! _[plano General]_
    - 🎬 **Escena de cámara «Cole08_G3_Musica»** _(música: → Intima)_
  - **Andrés:** Empieza el torneo de primavera del colegio. _[plano Medio de Andrés · silencio 0.9 s]_
  - **Andrés:** Fútbol, baloncesto y atletismo. Cada uno elige uno. _[plano General]_
  - **Andrés:** Entrenamos esta semana. _[plano PrimerPlano de Andrés]_
  - **Andrés:** El viernes llega la clasificación contra 4.º B. Y si pasáis… _[silencio 0.9 s]_
  - **Andrés:** La final. _[plano PrimerPlano de Andrés]_
  - **Nico:** ¡Vamos!
  - **Bruno:** La final es nuestra.
  - **Andrés:** Bruno. La final es de quien juegue mejor.
  - **Andrés:** Y de quien juegue limpio. _[silencio 0.9 s]_
  - **Andrés:** Venga. Id con vuestro capitán de deporte.
  - **Omar:** Yo voy a donde vaya [tu nombre].
  - **Omar:** Soy malo en los tres deportes por igual. Es un talento. _[silencio 0.9 s]_
  - 🎬 **Escena al completarlo «Cole08_G4_Entra»** _(música: → Tension)_
    - _En escena:_ Nico, Álex, Sara
    - **Nico:** ¡SÍ! Lo sabía. Tú y yo, en el mismo equipo.
    - **Nico:** Como el primer partido.
    - **Tú:** Esta vez entrenamos.
    - **Nico:** Sí. Esta vez entrenamos MÁS.
    - **Álex:** Bien. Me acuerdo de tus canastas en el gimnasio. Tienes muñeca.
    - **Álex:** Regla número uno: no se tira desde el medio del campo. Regla número dos… A veces sí.
    - **Sara:** Excelente elección.
    - **Sara:** He calculado que si movemos los brazos correctamente mientras corremos, mejoramos nuestro rendimiento.
    - **Tú:** ¿Cuánto?
    - **Sara:** Lo suficiente para que lo intentemos.
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
- **Paso 5 · Ir a** Campo de fútbol — «llegar al área correspondiente.» _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 6 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _(si en «deporte» elegiste «Futbol»)_ **Andrés:** Hoy: pases. El fútbol es de todos. No del que más corre. _[plano General]_
    - 🎬 **Escena de cámara «Cole08_G6_Musica»** _(música: → Tension)_
  - _(si en «deporte» elegiste «Futbol»)_ **Nico:** ¿Eso va por mí?
  - _(si en «deporte» elegiste «Futbol»)_ **Andrés:** Muchísimo.
  - _(si en «deporte» elegiste «Futbol»)_ **Omar:** Yo me pongo aquí.
  - _(si en «deporte» elegiste «Futbol»)_ **Tú:** ¿Por qué?
  - _(si en «deporte» elegiste «Futbol»)_ **Omar:** Así corro menos y pienso más. Es mi estrategia.
  - 🎬 **Escena al completarlo «Cole08_G7_Entra»**
    - _En escena:_ Omar, Nico
    - _(si tienes la marca «buen entreno»)_ **Nico:** ¡Eso! ¡Otra vez!
    - _(si NO tienes la marca «buen entreno»)_ **Omar:** Ha sido un pase artístico.
    - _(si NO tienes la marca «buen entreno»)_ **Tú:** ¿Eso significa malo?
    - _(si NO tienes la marca «buen entreno»)_ **Omar:** Significa que no ha ido donde queríamos.
- **Paso 7 · Minijuego** — «Entrenamiento: pases al hueco» _(solo si en «deporte» elegiste «Futbol»)_
  - 🎮 _Cómo se juega:_ Pasa cuando la aguja esté en verde
  - 🎬 **Escena al completarlo «Cole08_G8_Entra»** _(música: → Tension)_
    - _En escena:_ Álex
    - _(si en «deporte» elegiste «Baloncesto»)_ **Álex:** Vamos. Ahora tú.
- **Paso 8 · Ir a** Cancha de baloncesto — «Ve a la cancha a entrenar» _(solo si en «deporte» elegiste «Baloncesto»)_
  - _Lugar:_ Cancha de baloncesto
- **Paso 9 · Escena** _(solo si en «deporte» elegiste «Baloncesto»)_
  - **Álex:** Respira. Mira el aro. _[plano Hombro de Álex → Tú]_
    - 🎬 **Escena de cámara «Cole08_G9_Musica»** _(música: → Tension)_
  - **Álex:** Flexiona las rodillas. _[plano General]_
  - **Álex:** Y suelta. Así. _[plano Medio de Álex]_
  - **Omar:** Como si nada. Vale. Como si todo.
  - 🎬 **Escena al completarlo «Cole08_G10_Entra»** _(música: → Tension)_
    - _En escena:_ Álex
    - **Álex:** Eso sí. No pasa nada. Otra vez.
- **Paso 10 · Minijuego** — «Entrenamiento: tiros libres» _(solo si en «deporte» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Suelta cuando la aguja esté en verde
- **Paso 11 · Escena** _(solo si en «deporte» elegiste «Atletismo»)_
  - _Lugar:_ la pista de deporte
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Vallas.
    - 🎬 **Escena de cámara «Cole08_G11_Musica»** _(música: → Tension)_
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Saltos. Conos. _[plano General]_
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Y sprint final. _[plano General]_
  - _(si en «deporte» elegiste «Atletismo»)_ **Andrés:** El viernes será un relevo.
  - _(si en «deporte» elegiste «Atletismo»)_ **Andrés:** Así que también aprenderéis a pasaros esto sin tirarlo.
  - _(si en «deporte» elegiste «Atletismo»)_ **Omar:** ¿Y si lo tiro?
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Entonces lo recoges. Muy rápido.
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Y finges que era parte del plan.
  - 🎬 **Escena al completarlo «Cole08_G12_Entra»** _(música: → Tension)_
    - _En escena:_ Andrés
    - _(si NO tienes la marca «buen entreno»)_ **Andrés:** No pasa nada. Mañana lo intentamos otra vez.
- **Paso 12 · Clase** — «Entrena el circuito de la pista» _(solo si en «deporte» elegiste «Atletismo»)_
- **Paso 13 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol
  - **Andrés:** Buen entrenamiento. Antes del viernes necesitáis dos cosas. Un capitán. Y un plan.
    - 🎬 **Escena de cámara «Cole08_G13_14_15_Musica»** _(música: → Intima)_
  - **Nico:** Yo creo que el capitán debería ser [tu nombre].
  - **Álex:** Yo votaría a [tu nombre].
  - **Álex:** Pero también me votaría a mí. _[silencio 0.9 s]_
  - **Sara:** Propongo votar. [tu nombre] tiene buena cabeza.
  - **Sara:** Yo tengo mejor cabeza. _[silencio 0.9 s]_
  - **Sara:** Pero [tu nombre] tiene más amigos.
  - **Hugo:** Yo… No he estado nunca en un equipo donde se vota. Me gusta.
  - ❓ **Pregunta al jugador:** ¿Quién es el capitán?
    - ➤ «Yo. Me hace ilusión.» _(efecto: valentia +1; decisión «capitan» = Yo)_
      - **Omar:** ¡Capitán [tu nombre]! Te hago un brazalete.
      - **Tú:** ¿Eso es cinta?
      - **Omar:** Cinta de capitán. Ahora es oficial.
    - ➤ _(si en «deporte» elegiste «Futbol»)_ «Nico. Nadie tiene más ganas que él.» _(efecto: Nico +8; empatia +1; decisión «capitan» = Otro)_
      - **Nico:** ¿Yo? ¿YO? No os voy a fallar. Voy a llorar. No voy a llorar.
    - ➤ _(si en «deporte» elegiste «Baloncesto»)_ «Álex. Sabe más que nadie.» _(efecto: Álex +8; empatia +1; decisión «capitan» = Otro)_
      - **Álex:** Vale. Primera orden de la capitana: nadie se agobia.
      - **Álex:** Segunda: nadie se agobia. _[silencio 0.9 s]_
    - ➤ _(si en «deporte» elegiste «Atletismo»)_ «Sara. Tiene un plan para todo.» _(efecto: Sara +8; empatia +1; decisión «capitan» = Otro)_
      - **Sara:** Acepto. He traído un cuaderno para anotar la estrategia.
      - **Tú:** ¿Lo traías por si acaso?
      - **Sara:** Siempre lo traigo.
    - ➤ «Omar. Hace falta alguien tranquilo.» _(efecto: Omar +10; empatia +1; decisión «capitan» = Omar)_
      - **Omar:** ¿Yo? Nunca me han elegido para nada. Bueno.
      - **Omar:** Una vez para borrar la pizarra. Gracias.
  - **Andrés:** Y el plan. ¿Cómo vais a jugar?
  - ❓ **Pregunta al jugador:** ¿Qué estrategia proponéis?
    - ➤ «Ir a por todas desde el principio» _(efecto: valentia +1; decisión «estrategia» = Ataque)_
      - **Andrés:** Con valentía. Pero guardad aire para el final.
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
  - 🎬 **Escena al completarlo «Cole08_G16_Fin»** _(música: → Tema)_
    - _Narrador:_ _La semana pasó rápido._
    - _Narrador:_ _Y entonces llegó el día que todos estaban esperando._
- **Paso 17 · Escena** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Alumno, Alumna
  - 💬 _Comentario al pasar cerca de Alumno:_ «¡4.º B! ¡4.º B!»
  - _(si en «deporte» elegiste «Futbol»)_ **Alumno:** ¡4.º B! _[plano General]_
    - 🎬 **Escena de cámara «Cole08_G17_19_21_Musica»** _(música: → Tension)_
  - _(si en «deporte» elegiste «Futbol»)_ **Alumna:** ¡4.º B!
  - _(si en «deporte» elegiste «Futbol»)_ **Andrés:** Clasificación. 4.º A contra 4.º B.
  - _(si en «deporte» elegiste «Futbol»)_ **Alumno:** ¡Somos más pequeños! ¡Pero somos MÁS RÁPIDOS! _[plano PrimerPlano de Tú]_
  - _(si en «deporte» elegiste «Futbol»)_ **Omar:** Son pequeñitos. Me dan un poco de miedo.
  - _(si en «deporte» elegiste «Futbol»)_ **Omar:** Parecen muy motivados.
  - _(si en «deporte» elegiste «Baloncesto»)_ **Andrés:** Clasificación. _[plano General]_
  - _(si en «deporte» elegiste «Baloncesto»)_ **Álex:** Tres canastas. Y estamos dentro.
  - _(si en «deporte» elegiste «Atletismo»)_ **Andrés:** Clasificación. _[plano General]_
  - _(si en «deporte» elegiste «Atletismo»)_ **Sara:** Respirad. Y no os adelantéis.
  - _(si en «deporte» elegiste «Atletismo»)_ **Omar:** Yo voy a intentar recordar cómo se corre.
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
  - _(si tienes la marca «clasificacion ganada»)_ **Andrés:** ¡Ganáis la clasificación! Directos a la final. _[plano General]_
    - 🎬 **Escena de cámara «Cole08_G23_Musica»** _(música: → Intima → Tension)_
  - _(si NO tienes la marca «clasificacion ganada»)_ **Andrés:** 4.º B gana… Pero pasáis como mejor segundo. Por los pelos.
  - _(si NO tienes la marca «clasificacion ganada»)_ **Alumno:** Buen partido. El año que viene os ganamos. Bueno… Este también casi.
  - _(si NO tienes la marca «clasificacion ganada»)_ **Andrés:** Descanso de veinte minutos. Y la final es contra… El equipo de Bruno.
- **Paso 24 · Ir a** la pista de deporte — «Descanso: ve a la grada de la pista»
  - _Lugar:_ la pista de deporte · _En escena:_ Mamá/Papá, Abu, Omar, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén
- **Paso 25 · Varios objetivos (en cualquier orden)** — «Aprovecha el descanso»
  - 🖐 _Al usar «La fuente de la pista»:_
    - _Narrador:_ _Quedan pocos minutos._ _[plano General]_
  - **Paso 25.1 · Hablar** con Mamá/Papá — «Saluda a mamá/papá en la grada»
    - **Mamá/Papá:** ¡[tu nombre]! Hemos venido todos. Bueno. Estamos Abu y yo. Que es como todos. _[plano Medio de Mamá/Papá]_
    - **Mamá/Papá:** Ganes o pierdas, esta noche hay cena especial. Aunque si ganas… Postre doble.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Me tiemblan las piernas. ¿Y si fallo?» _(efecto: empatia +1)_
        - **Mamá/Papá:** Entonces fallas. Y lo vuelves a intentar.
        - **Mamá/Papá:** Así se hace todo en la vida.
      - ➤ «¡Vamos a ganar!» _(efecto: valentia +1)_
        - **Mamá/Papá:** ¡Esa es la actitud! Yo gritaré tanto que me quedaré sin voz.
  - **Paso 25.2 · Hablar** con Abu — «Habla con Abu»
    - **Abu:** Yo jugué una final a tu edad. Perdimos por un gol. ¿Sabes qué recuerdo? _[plano PrimerPlano de Abu]_
    - **Abu:** El bocadillo de después con mis amigos. _[silencio 0.9 s]_
    - **Abu:** Del resultado casi no me acuerdo. _[plano PPP de Abu]_
    - **Abu:** De los amigos, de todos. Disfrútalo, cariño.
  - **Paso 25.3 · Usar** — «Bebe agua en la fuente»
    - 🖐 _Al usar «La fuente de la pista»:__(la misma conversación «Beber» de arriba)_
- **Paso 26 · Hablar** con Bruno — «Bruno te está mirando. Habla con él»
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Oye. Lo del otro día… Gracias por hablar conmigo en vez de ir contándolo por ahí.
    - 🎬 **Escena de cámara «Cole08_G26_Musica»** _(música: → Tension)_
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Pero hoy os gano igual.
  - _(si en «malotes» elegiste «Hablar»)_ **Bruno:** Que una cosa no quita la otra. _[silencio 0.9 s]_
  - **Bruno:** Mira, el detective. Hoy no hay nada que investigar. Solo vais a perder.
  - _(si en «malotes» NO elegiste «Hablar» y NO tienes la marca «acusaste a bruno»)_ **Bruno:** ¿Vosotros en la final? Qué valor.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Bruno. Juego con ellos. Y ya está.
  - _(si tienes la marca «hugo con el grupo»)_ **Bruno:** Ya. Ya lo sé. Pues suerte. Pero poca.
  - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Buena suerte. De verdad.
  - ❓ **Pregunta al jugador:** ¿Qué le contestas a Bruno?
    - ➤ «Que gane el mejor. Y que sea divertido.» _(efecto: Bruno +4; deportividad +2; decisión «pre final» = Deportivo)_
      - **Bruno:** Vale. Que sea divertido. Pero que gane yo.
    - ➤ «Ya veremos en el campo.» _(efecto: valentia +1; decisión «pre final» = Reto)_
      - **Bruno:** Ya veremos. Eso digo yo.
    - ➤ «No contestas. Vuelves con tu equipo.» _(efecto: decisión «pre final» = Nada)_
      - _Narrador:_ _Bruno se queda con la frase a medias._
      - _Narrador:_ _Tu equipo te está esperando._
- **Paso 27 · Cinemática** _(solo si en «deporte» elegiste «Futbol»)_
  - _Lugar:_ Campo de fútbol · _En escena:_ Andrés, Nico (si en «deporte» elegiste «Futbol»), Álex (si en «deporte» elegiste «Baloncesto»), Sara (si en «deporte» elegiste «Atletismo»), Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Bruno, Rubén, Mamá/Papá, Abu
  - 🎬 **Cinemática «Cole08_Final»** _(música: → Tema → Tension → Tema → Tension → Tema → Tension)_
    - _En escena:_ Álex, Bruno, Sara, Andrés, Omar, Nico
    - _Cámara:_ 13 planos (General, Inserto, PrimerPlano, Medio)
    - **Andrés:** ¡LA FINAL! El equipo de [tu nombre] contra el equipo de Bruno.
    - _(si en «pre final» elegiste «Deportivo»)_ **Bruno:** Que sea divertido, dijiste. Vale. Pero que gane yo.
    - _(si en «pre final» elegiste «Reto»)_ **Bruno:** «Ya veremos en el campo».
    - _(si en «pre final» elegiste «Reto»)_ **Bruno:** Pues ya estamos en el campo.
    - _(si en «pre final» elegiste «Nada»)_ **Bruno:** ¿Tampoco me vas a contestar ahora? Vale.
    - _(si en «pre final» elegiste «Nada»)_ **Bruno:** Ya hablará el marcador.
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Delantero»)_ **Nico:** Tú arriba. Yo te la paso. Esta vez sí.
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Defensa»)_ **Nico:** Tú atrás. Que no pase ni el aire.
    - _(si en «deporte» elegiste «Futbol» y en «posicion» elegiste «Portero»)_ **Nico:** Tú en la portería. Eres un muro. Un muro con guantes.
    - _(si en «capitan» elegiste «Yo»)_ **Omar:** Capitán. Unas palabras.
    - _(si en «capitan» elegiste «Omar»)_ **Omar:** Soy el capitán. ¡A por ellos! Con cariño.
    - _(si en «deporte» elegiste «Futbol»)_ **Nico:** ¡Equipo! ¡No os voy a fallar! ¡Voy a llorar! ¡No voy a llorar!
    - _(si en «deporte» elegiste «Baloncesto»)_ **Álex:** Primera orden: nadie se agobia.
    - _(si en «deporte» elegiste «Baloncesto»)_ **Álex:** Segunda: nadie se agobia.
    - _(si en «capitan» elegiste «Otro» y en «deporte» elegiste «Atletismo»)_ **Sara:** Plan. Salir rápido, pasar el testigo y no tropezar. Técnicamente, fácil.
    - _(si en «capitan» elegiste «Yo»)_ **Tú:** Jugad como sabemos. Y pasadlo bien. Lo demás… ya vendrá.
    - _(si en «estrategia» elegiste «Ataque»)_ **Andrés:** A por todas. Pero guardad aire para el final.
    - _(si en «estrategia» elegiste «Paciencia»)_ **Andrés:** Paciencia. Los partidos se ganan en el último minuto.
    - _(si en «estrategia» elegiste «Todos»)_ **Andrés:** Aquí juega todo el mundo. Así da gusto.
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Omar:** ¡Por Los Imparables!
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ **Omar:** ¡Por La Patrulla Valmar!
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ **Omar:** ¡Por Los del Banco Azul!
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ **Omar:** ¡Por Los Dinosaurios!
    - **Andrés:** ¡Y a disfrutar!
    - _(si en «deporte» elegiste «Atletismo»)_ **Andrés:** Preparados. A sus puestos.
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
  - _(si tienes la marca «torneo ganado»)_ **Andrés:** ¡FINAL! ¡Gana el equipo de [tu nombre]!
    - 🎬 **Escena de cámara «Cole08_G33_34_35_Musica»** _(música: → Intima)_
  - _(si tienes la marca «torneo ganado»)_ **Andrés:** ¡CAMPEONES DEL TORNEO!
  - _(si tienes la marca «torneo perdido»)_ **Andrés:** ¡FINAL! Gana el equipo de Bruno. Pero qué final. Subcampeones.
  - _(si tienes la marca «torneo perdido»)_ **Andrés:** Y con la cabeza bien alta.
  - _(si tienes la marca «torneo ganado»)_ **Mamá/Papá:** ¡Esa es mi estrella!
  - _(si tienes la marca «torneo perdido»)_ **Mamá/Papá:** ¡Muy bien jugado, [tu nombre]!
  - _(si tienes la marca «torneo ganado»)_ **Bruno:** Bien jugado. De verdad. Lo odio. Pero bien jugado. _[plano PrimerPlano de Bruno]_
  - _(si tienes la marca «torneo perdido»)_ **Bruno:** ¡Lo sabía! Aunque ha estado muy cerca. Muy cerca.
  - ❓ **Pregunta al jugador:** ¿Qué haces ahora?
    - ➤ «Dar la mano a todo el equipo de Bruno» _(efecto: Bruno +5; Rubén +3; deportividad +2; decisión «tras final» = Mano)_
      - _(si tienes la marca «torneo ganado»)_ **Bruno:** ¿La mano? Vale. Pero no se lo cuentes a nadie. Es broma. Cuéntaselo.
      - _(si tienes la marca «torneo perdido»)_ **Bruno:** ¿Me das la mano después de perder?
      - _(si tienes la marca «torneo perdido»)_ **Bruno:** Tú eres de otro planeta. Buen partido. _[silencio 0.9 s]_
    - ➤ «Celebrarlo / consolaros con tu equipo» _(efecto: Álex +2; Nico +2; Omar +3; Sara +2; empatia +1; decisión «tras final» = Equipo)_
      - **Omar:** ¡Abrazo de grupo! ¡Todos! ¡Tú también!
      - **Andrés:** Venga. Un abrazo rápido.
    - ➤ «Irte a un rincón sin hablar con nadie» _(efecto: deportividad +-1; decisión «tras final» = Rincon)_
      - _(si tienes la marca «torneo perdido»)_ _Narrador:_ _Te sientas en un rincón un rato._
      - _(si tienes la marca «torneo perdido»)_ **Omar:** ¿Quieres agua?
      - _(si tienes la marca «torneo perdido»)_ **Tú:** Sí.
      - _(si tienes la marca «torneo perdido»)_ _Narrador:_ _A veces eso es lo que hace falta._
      - _(si tienes la marca «torneo ganado»)_ _Narrador:_ _Te apartas un momento._
      - _(si tienes la marca «torneo ganado»)_ _Narrador:_ _Ha sido mucho de golpe._ _[silencio 0.9 s]_
      - _(si tienes la marca «torneo ganado»)_ **Omar:** Toma.
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
  - 🎬 **Cinemática «Cole08_Medallas»** _(música: → Intima)_
    - _En escena:_ Omar, Mamá/Papá, Bruno, Andrés, Abu
    - _Cámara:_ 6 planos (General, Reaccion, PPP, PrimerPlano)
    - **Andrés:** Y ahora… ¡Las medallas!
    - _(si tienes la marca «torneo perdido»)_ **Andrés:** Primero, los subcampeones.
    - _(si tienes la marca «torneo perdido»)_ **Andrés:** Plata para el equipo de [tu nombre].
    - _(si tienes la marca «torneo perdido»)_ **Andrés:** Y brilla más que muchas de oro. Te lo digo yo.
    - _(si tienes la marca «torneo ganado»)_ **Andrés:** Y el oro…
    - **Andrés:** Para el equipo de [tu nombre]. Pesa, ¿eh? Es la emoción.
    - **Mamá/Papá:** ¡Mirad!
    - **Mamá/Papá:** ¡Es [tu nombre]! ¡Es de mi familia!
    - **Abu:** Ay… Que se me ha metido algo en el ojo. En los dos.
    - _(si en «tras final» elegiste «Mano»)_ **Bruno:** Lo de darme la mano… Ha estado bien. No te acostumbres.
    - _(si en «tras final» elegiste «Rincon»)_ **Omar:** ¿Estás mejor? Te he guardado esto. Y medio bocadillo.
    - _(si en «tras final» elegiste «Rincon»)_ **Tú:** ¿Medio?
    - _(si en «tras final» elegiste «Rincon»)_ **Omar:** La otra mitad era importante.
    - _(si en «tras final» elegiste «Equipo»)_ **Omar:** ¡Otra foto de equipo! ¡Esta para la nevera de cada uno!
    - _(si tu rasgo deportividad es 4 o más)_ **Andrés:** Un último premio. El de deportividad del torneo. Es para… [tu nombre].
    - **Andrés:** Por cómo has jugado. Y por cómo has tratado a los demás.
- **Paso 38 · Escena**
  - _En escena:_ Omar (te acompaña), Sara (te acompaña), Nico (te acompaña)
  - **Omar:** Oye… ¿Habéis oído lo que dicen los de sexto?
    - 🎬 **Escena de cámara «Cole08_G38_Musica»** _(música: → Descubrimiento → Tension)_
  - **Nico:** ¿Qué?
  - **Sara:** Lo de la puerta.
  - **Sara:** La del fondo. _[plano General]_
  - **Nico:** Siempre está cerrada. Dicen que dentro hay un fantasma. O un tesoro.
  - **Nico:** O un fantasma con un tesoro. _[silencio 0.9 s]_
  - **Sara:** Los fantasmas no existen. Los tesoros… A veces.
  - **Nico:** ¿Habéis oído eso? _[plano PrimerPlano de Tú · silencio 0.9 s]_

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
  - 🎬 **Escena al completarlo «Cole09_G1_Fin»** _(música: → Descubrimiento → Tension)_
    - _Narrador:_ _Unos días después del torneo, el colegio volvió a parecer normal. Casi._
- **Paso 2 · Ir a** el patio — «Sal al recreo: tus amigos no hablan de otra cosa»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Iker (si tienes la marca «iker en el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 3 · Escena**
  - **Nico:** Es un fantasma.
    - 🎬 **Escena de cámara «Cole09_G3_Musica»** _(música: → Descubrimiento → Tension)_
  - **Tú:** ¿Qué?
  - **Nico:** El fantasma de un niño que se quedó castigado para siempre.
  - **Sara:** Eso es físicamente absurdo.
  - **Nico:** ¿Y cómo sabes que no?
  - **Sara:** Porque los fantasmas no existen.
  - **Nico:** ¿Bocadillos?
  - **Omar:** Muchos. Una sala entera.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** En mi otro cole había una sala parecida. _[silencio 0.9 s]_
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Pero esta da más miedo.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** En un libro que leí, detrás de una puerta así había un pasadizo.
  - _(si tienes la marca «hugo con el grupo»)_ **Nico:** ¿A dónde?
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Al otro lado del mundo.
  - _(si tienes la marca «hugo con el grupo»)_ **Omar:** Espero que haya bocadillos.
  - _(si tienes la marca «hugo con el grupo»)_ **Omar:** Voy a por mi almuerzo. Te mira. ¿Vienes?
- **Paso 4 · Usar** — «Vuelve a tu taquilla a por el almuerzo»
  - _En escena:_ Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - 🖐 _Al usar «Tu taquilla»:_
    - _Narrador:_ _«NO ENTRES EN LA SALA DEL FONDO. ES NUESTRA. — L.»_
    - _Narrador:_ _Debajo: «Si de verdad quieres entrar: el año en que 4.º A ganó… y la llave que nadie toca.»_
    - **Omar:** Vale. Ahora tenemos que entrar. _[silencio 0.9 s]_
- **Paso 5 · Escena**
  - **Iker:** He creado un expediente.
    - 🎬 **Escena de cámara «Cole09_G5_Musica»** _(música: → Tension)_
  - **Omar:** ¿Ya?
  - **Iker:** Ya.
  - **Sara:** Tenemos tres pistas. Segundo dedo. Tercer dedo.
  - **Sara:** Y la persona que firma con una L.
  - **Omar:** Entonces tenemos un misterio. Y somos detectives.
  - **Iker:** Técnicamente somos alumnos.
  - **Omar:** Detectives alumnos.
  - **Sara:** Me sirve.
- **Paso 6 · Varios objetivos (en cualquier orden)** — «Investiga el misterio»
  - _Lugar:_ Mostrador de la biblioteca · _En escena:_ Marisa, Ramón, Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - **Paso 6.1 · Usar** — «El anuario viejo de la biblioteca»
    - 🖐 _Al usar «El anuario de 1998»:_
      - **Marisa:** ¿El anuario de 1998? Lo limpia con cuidado.
      - _Narrador:_ _Debajo: «4.º A — Campeones del Concurso de Ciencias.»_
      - **Sara:** Espera.
  - **Paso 6.2 · Usar** — «El tablero de llaves de la conserjería»
    - 🖐 _Al usar «El tablero de llaves»:_
      - **Ramón:** Las llaves están todas aquí. Esa no.
      - **Ramón:** La número 13 no se toca.
      - **Ramón:** Me la dio una niña hace muchos años. _[silencio 0.9 s]_
      - **Ramón:** Y me hizo prometer que la guardaría.
      - **Ramón:** Y yo cumplo mis promesas.
  - **Paso 6.3 · Usar** — «Algo brilla en el almacén del gimnasio»
    - 🖐 _Al usar «Un trofeo viejo»:_
      - **Omar:** ¡1998! Ese es nuestro año.
  - **Paso 6.4 · Usar** — «La puerta del fondo del pasillo»
    - 🖐 _Al usar «La puerta del fondo»:_
      - _Narrador:_ _Grabado: «Sala de 4.º A. Promoción 1998.»_
      - _Narrador:_ _Debajo: «¡Prohibido a los mayores!»_
- **Paso 7 · Escena**
  - _En escena:_ Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - **Sara:** Llave 13. Y una niña llamada L. Solo falta una cosa.
    - 🎬 **Escena de cámara «Cole09_G7_Musica»** _(música: → Tension)_
  - **Omar:** Abrir.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Estadísticamente, colarse es una mala idea.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Pero tengo curiosidad.
  - 🎬 **Escena al completarlo «Cole09_G8_Entra»**
    - _En escena:_ Sara, Omar
    - **Omar:** Si nos pillan, yo solo venía a buscar mi almuerzo.
    - **Sara:** Llevas el almuerzo en la mano.
    - **Omar:** Entonces venía a buscar otro.
- **Paso 8 · Decisión** — «¿Pides permiso o te cuelas?»
  - _En escena:_ Marisa, Ramón, Sara (te acompaña), Omar (te acompaña), Iker (si tienes la marca «iker en el grupo») (te acompaña)
  - ➤ **Opción «Pedir permiso a Ramón»** (con Ramón) _(efecto: decisión «entrar» = Permiso; Ramón +6; responsabilidad +1)_
    - **Ramón:** Vaya. Por fin alguien pregunta. Os doy permiso.
    - **Ramón:** Pero el código lo descubrís vosotros.
  - ➤ **Opción «Colarte en el recreo»** _(efecto: decisión «entrar» = Colarse; valentia +1)_
    - _Narrador:_ _Recreo. El pasillo está vacío. Solo se oye el reloj y, a lo lejos, a Nico gritando «¡GOL!»._
    - **Omar:** (susurrando) Si nos pillan, yo solo pasaba por aquí. Buscando… un bocadillo.
- **Paso 9 · Ir a** La puerta del fondo del pasillo — «Ve a la puerta del fondo del pasillo»
  - _Lugar:_ La puerta del fondo del pasillo · _En escena:_ Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»), Ramón (si en «entrar» elegiste «Permiso»)
  - 🎬 **Escena al completarlo «Cole09_G10_Entra»**
    - _En escena:_ Omar, Nico, Sara
    - **Sara:** Espera. Primero decía el año.
    - **Nico:** Si sale un fantasma… Me pongo detrás de ti.
    - **Omar:** Yo me pongo detrás de [tu nombre].
    - **Sara:** Vamos.
    - **Omar:** El año está bien. ¿Qué número tenía la llave?
    - **Nico:** ¡Era una posibilidad!
    - **Sara:** No.
- **Paso 10 · Decisión** — «¿Qué código pruebas?»
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
  - **Sara:** No es un laboratorio. Es un aula.
    - 🎬 **Escena de cámara «Cole09_G11_Musica»** _(música: → Tension → Descubrimiento)_
  - **Sara:** Un aula de hace muchísimos años.
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Era el aula de 4.º A. Antes de la reforma.
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Aquí estudiaban los niños de 1998. _[silencio 0.9 s]_
- **Paso 12 · Varios objetivos (en cualquier orden)** — «Explora la sala»
  - **Paso 12.1 · Usar** — «Un pupitre viejo»
    - 🖐 _Al usar «Un pupitre viejo»:_
      - _Narrador:_ _Grabado en la madera: «L. estuvo aquí. 1998. Seré profe.»_
      - **Omar:** Lo tenía decidido. Con nueve años.
  - **Paso 12.2 · Usar** — «Una caja de lata»
    - 🖐 _Al usar «Una caja de lata»:_
      - _Narrador:_ _«CÁPSULA DEL TIEMPO. Abrir en 2008.»_
      - **Sara:** Se suponía que tenían que abrirla hace años.
      - **Omar:** Se olvidaron. Como adultos.
      - **Omar:** Eso es un poco triste.
  - **Paso 12.3 · Usar** — «La estantería de trofeos»
    - 🖐 _Al usar «Trofeos y medallas»:_
      - **Nico:** Este nos pega. Solo nos falta ganar algo.
- **Paso 13 · Usar** — «En la pared hay una foto enmarcada»
- **Paso 14 · Cinemática**
  - 🎬 **Cinemática «Cole09_LaFoto»** _(música: → Intima)_
    - _En escena:_ Sara, Omar, Nico, Iker, Ramón
    - _Cámara:_ 3 planos (Hombro)
    - **Sara:** Esperad. Esa es… ¡Es nuestra Lucía!
    - **Omar:** ¿Con coletas?
    - **Nico:** ¡L de Lucía! ¡Lo sabía! Bueno… No lo sabía.
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** Dato curioso.
- **Paso 15 · Escena**
  - _En escena:_ Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»), Ramón
  - _(si en «entrar» elegiste «Colarse»)_ **Ramón:** ¡Ajá! Ah. Así que la habéis encontrado. Sí.
  - _(si en «entrar» elegiste «Permiso»)_ **Ramón:** Sí. Esa era Lucía. _[silencio 0.9 s]_
- **Paso 16 · Ir a** Aula de 1.º A — «Busca a Lucía en clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Sara, Omar, Nico, Iker (si tienes la marca «iker en el grupo»)
- **Paso 17 · Hablar** con Profe Lucía — «Enséñale la foto a Lucía»
  - **Profe Lucía:** ¿Qué traéis ahí? ¿De dónde habéis sacado esto? Esa soy yo. Con nueve años. Y esas coletas…
    - 🎬 **Escena de cámara «Cole09_G17_Musica»** _(música: → Intima)_
  - _(si en «entrar» elegiste «Colarse»)_ **Profe Lucía:** Y ahora quiero saber cómo habéis entrado.
  - _(si en «entrar» elegiste «Permiso»)_ **Profe Lucía:** ¿Ramón os ha ayudado? Esa nota también la escribí yo. Esa taquilla era mía. _[silencio 0.9 s]_
  - _(si en «entrar» elegiste «Permiso»)_ **Profe Lucía:** Nosotros escondimos la sala para proteger nuestra cápsula del tiempo.
  - _(si en «entrar» elegiste «Permiso»)_ **Profe Lucía:** Supongo que algunas cosas esperan a que volvamos a encontrarlas. _[silencio 0.9 s]_
  - **Profe Lucía:** DECISIÓN · ¿QUÉ HACER CON LA FOTO?
  - **Profe Lucía:** Tengo una idea. Mañana abriremos la cápsula de mi clase.
  - **Profe Lucía:** Y vosotros dejaréis una nueva.
  - **Omar:** ¿De verdad?
  - **Profe Lucía:** De verdad. Esta vez no se me olvida.
  - ❓ **Pregunta al jugador:** ¿Qué haces con la foto?
    - ➤ «Devolvérsela: «Es tuya. Te la hemos traído.»» _(efecto: Profe Lucía +10; empatia +1; decisión «foto lucia» = Devolver)_
      - **Profe Lucía:** Gracias. De verdad. Os voy a hacer una copia a cada uno. Esta la pongo en mi mesa.
    - ➤ «Enseñársela a toda la clase» _(efecto: Profe Lucía +5; Nico +3; humor +1; decisión «foto lucia» = Clase)_
      - **Nico:** ¡ATENCIÓN TODOS! ¡LUCÍA CON COLETAS!
      - **Profe Lucía:** ¡Nico! …Vale, vale. Sí. Era yo. Y era la mejor de la clase en ciencias, que conste.
    - ➤ «Guardar el secreto: «No se lo diremos a nadie»» _(efecto: Profe Lucía +8; responsabilidad +1; decisión «foto lucia» = Secreto; marca «secreto lucia»)_
      - **Profe Lucía:** ¿Un secreto entre nosotros? Me parece perfecto. Tomad una copia cada uno. Y ni una palabra de las coletas.
  - 🎬 **Escena al completarlo «Cole09_G18_Entra»**
    - _En escena:_ Omar, Nico, Sara
    - **Omar:** Déjame firmar. Para que sepamos que estuvimos aquí.
    - **Nico:** ¿Lo has escrito de verdad?
    - **Nico:** Entonces tengo que conseguirlo.
    - **Sara:** Es una buena pregunta.
    - **Omar:** Yo espero que sí.
    - **Nico:** Pues claro. ¿Quién va a dejar de ser amigo?
- **Paso 18 · Decisión** — «¿Qué metes en la cápsula del tiempo?»
  - ➤ **Opción «Una carta para tu «yo» del último día de cole»** _(efecto: decisión «capsula» = Carta; responsabilidad +1)_
  - ➤ **Opción «Un dibujo de tu grupo»** _(efecto: decisión «capsula» = Dibujo; Omar +3; creatividad +1)_
  - ➤ **Opción «Una predicción: «Nico será futbolista»»** _(efecto: decisión «capsula» = Prediccion; Nico +3; humor +1)_
  - ➤ **Opción «Una pregunta para el futuro: «¿Seguimos siendo amigos?»»** _(efecto: decisión «capsula» = Pregunta; Nico +2; Omar +2; Sara +2; empatia +1)_
- **Paso 19 · Escena**
  - **Profe Lucía:** Cápsula del tiempo de 4.º A.
    - 🎬 **Escena de cámara «Cole09_G19_Musica»** _(música: → Intima → Descubrimiento)_
  - **Profe Lucía:** Abrir el último día de colegio.
  - **Sara:** Lo he apuntado tres veces.
  - **Omar:** Yo lo he apuntado en mi cabeza. Creo.
  - **Profe Lucía:** Guarda esto. Algún día mirarás esta foto y te parecerá que fue ayer.

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
  - 🎬 **Escena al completarlo «Cole10_G1_Fin»** _(música: → Descubrimiento)_
    - _Narrador:_ _El curso seguía avanzando._
- **Paso 2 · Ir a** Aula de 1.º A — «Ve a clase»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Marta, Vega, Omar, Sara, Nico, Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Mateo (si tienes la marca «ayudaste a mateo»)
- **Paso 3 · Escena**
  - **Profe Lucía:** Atención, clase. Gracias.
    - 🎬 **Escena de cámara «Cole10_G3_Musica»** _(música: → Descubrimiento → Intima)_
  - **Marta:** ¡Y música!
  - **Nico:** ¡Y comida!
  - **Omar:** ¡He oído comida!
  - **Profe Lucía:** Habrá puestos, música, teatro y concurso de talentos.
  - **Marisa:** ¡He oído «libros»! Cada uno elegirá una tarea. _[silencio 0.9 s]_
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Yo… He escrito una obra de teatro.
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Si alguien quiere participar.
  - _(si tienes la marca «hugo con el grupo»)_ **Nico:** ¡YO!
  - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Gracias.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Según mis datos, el año pasado se vendieron cuarenta y dos magdalenas.
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Podemos superar esa cifra. _[silencio 0.9 s]_
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** Ese es el espíritu.
  - 🎬 **Escena al completarlo «Cole10_G4_Entra»**
    - _En escena:_ Hugo, Sara, Vega, Marta, Omar, Nico
    - **Vega:** ¡Sabía que vendrías! Banderines, farolillos y un cartel enorme. Y purpurina.
    - **Marta:** ♪ Pom, pom, pom-pom. ♪
    - **Omar:** Magdalenas. Muchas.
    - **Sara:** Documentaremos todo. Antes, durante y después.
    - **Sara:** Quiero que podamos recordar cómo era este día.
    - **Hugo:** ¿De verdad?
    - **Nico:** ¡Yo soy el loro!
    - **Hugo:** Sí. Lo eres.
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
      - **Vega:** Un poco más arriba. Ahora a la izquierda. ¡Perfecto!
  - **Paso 6.2 · Usar** — «Cuelga los farolillos»
    - 🖐 _Al usar «Farolillos de papel»:_
      - **Vega:** Parece que el patio está sonriendo.
  - **Paso 6.3 · Usar** — «Pinta el cartel del festival»
    - 🖐 _Al usar «El cartel del festival»:_
      - **Vega:** Ahora formas parte de la decoración.
- **Paso 7 · Ir a** el aula de música — «Ve al aula de música a ensayar» _(solo si en «festival» elegiste «Musica»)_
  - _Lugar:_ el aula de música · _En escena:_ Marta
- **Paso 8 · Escena** _(solo si en «festival» elegiste «Musica»)_
  - **Marta:** No pienses demasiado. Ahí está. Ya suena a festival.
    - 🎬 **Escena de cámara «Cole10_G8_Musica»** _(música: → Descubrimiento)_
  - 🎬 **Escena al completarlo «Cole10_G9_Entra»**
    - _En escena:_ Marta
    - **Marta:** No fallaste ni una. Algunas se escaparon. Pero aprendiste.
- **Paso 9 · Minijuego** — «Ensayo: toca a tiempo» _(solo si en «festival» elegiste «Musica»)_
  - 🎮 _Cómo se juega:_ Toca la nota cuando la aguja esté en verde
  - 🎬 **Escena al completarlo «Cole10_G10_Entra»**
    - _En escena:_ Omar
    - **Omar:** Bienvenido/a a la cocina. No comas nada.
- **Paso 10 · Ir a** Comedor — «Ve al comedor: Omar te espera con el delantal puesto» _(solo si en «festival» elegiste «Comida»)_
  - _Lugar:_ Comedor · _En escena:_ Omar
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Reúne los ingredientes» _(solo si en «festival» elegiste «Comida»)_
  - 🎬 **Escena al completarlo «Cole10_G12_Entra»**
    - _En escena:_ Omar
    - **Omar:** Mira eso. Son demasiado bonitas para comerlas.
  - **Paso 11.1 · Usar** — «Harina y azúcar»
    - 🖐 _Al usar «Harina y azúcar»:_
      - **Omar:** Harina.
  - **Paso 11.2 · Usar** — «Los huevos (con cuidado)»
    - 🖐 _Al usar «Una caja de huevos»:_
      - _(si tienes la marca «tarea brillante»)_ **Omar:** ¡Ni uno roto!
- **Paso 12 · Minijuego** — «Decora las magdalenas» _(solo si en «festival» elegiste «Comida»)_
  - 🎮 _Cómo se juega:_ Pon la guinda cuando la aguja esté en verde
- **Paso 13 · Varios objetivos (en cualquier orden)** — «Haz las fotos para el mural del festival» _(solo si en «festival» elegiste «Fotos»)_
  - _En escena:_ Sara (te acompaña)
  - **Paso 13.1 · Usar** — «El escenario (patio)»
    - 🖐 _Al usar «El escenario»:_
      - **Sara:** Primera fotografía. Antes de que empiece todo.
  - **Paso 13.2 · Usar** — «Los columpios (zona de juegos)»
    - 🖐 _Al usar «Los columpios»:_
      - **Sara:** Esta es buena. No sé por qué. Pero lo es.
  - **Paso 13.3 · Usar** — «La entrada del cole»
    - 🖐 _Al usar «La entrada del cole»:_
      - **Sara:** Aquí empezó todo. ¿Te acuerdas?
- **Paso 14 · Ir a** Gimnasio — «Ve al gimnasio a ensayar la obra» _(solo si en «festival» elegiste «Teatro»)_
  - _Lugar:_ Gimnasio · _En escena:_ Hugo, Nico
- **Paso 15 · Escena** _(solo si en «festival» elegiste «Teatro»)_
  - **Hugo:** Tu frase llega al final. Es importante.
  - **Tú:** ¿Qué digo? ¡La llave número mil estaba en nuestro corazón!
  - **Nico:** ¡CRUAC!
  - **Hugo:** Y tú eres un loro.
  - **Nico:** ¡Un loro profesional!
  - **Hugo:** Nunca nadie había querido hacer una obra mía. Gracias.
  - 🎬 **Escena al completarlo «Cole10_G16_Entra»**
    - _En escena:_ Hugo
    - _(si tienes la marca «tarea brillante»)_ **Hugo:** Esa es.
    - _(si NO tienes la marca «tarea brillante»)_ **Hugo:** Bien. No pasa nada. A mí también me pasa.
- **Paso 16 · Minijuego** — «Ensayo: di tu frase a tiempo» _(solo si en «festival» elegiste «Teatro»)_
  - 🎮 _Cómo se juega:_ Habla cuando la aguja esté en verde
- **Paso 17 · Transición (pasa el tiempo)** — «El viernes, el día del festival…»
  - ⏳ _Pantalla de transición:_ «El viernes, el día del festival…»
  - 🎬 **Escena al completarlo «Cole10_G18_Entra»**
    - _En escena:_ Rubén, Bruno
    - **Bruno:** ¡Limonada! ¡La mejor de Valmar!
    - **Rubén:** Bruno, estás gritando.
    - **Bruno:** ¡Eso ayuda!
    - **Rubén:** No parece.
- **Paso 18 · Ir a** el patio — «Ve al patio: ¡empieza el festival!»
  - _Lugar:_ el patio · _En escena:_ Profe Lucía, Marta, Andrés, Mamá/Papá, Abu, Ramón, Nico, Sara, Omar, Vega, Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Bruno, Rubén, Alumna, Alumno
  - 💬 _Comentario al pasar cerca de Bruno:_ «¡Limonada! ¡La mejor limonada de Valmar! …¿Nadie?»
- **Paso 19 · Escena**
  - **Mamá/Papá:** ¡[tu nombre]! ¡Qué bonito está todo!
    - 🎬 **Escena de cámara «Cole10_G19_Musica»** _(música: → Intima)_
  - **Abu:** En mis tiempos teníamos una mesa y cuatro galletas.
  - **Abu:** Esto parece una feria. _[silencio 0.9 s]_
  - **Profe Lucía:** Bienvenidos al festival de primavera. Y entonces…
- **Paso 20 · Varios objetivos (en cualquier orden)** — «¡Imprevistos! Resuelve al menos tres»
  - **Paso 20.1 · Usar** — «El viento se lleva los farolillos»
    - 🖐 _Al usar «¡Los farolillos se vuelan!»:_
      - **Vega:** ¡Lo has conseguido! ¡No hemos perdido ni uno!
  - **Paso 20.2 · Hablar** con Ramón — «El altavoz no suena: avisa a Ramón»
    - **Ramón:** A ver… Aquí está. Desenchufado.
    - **Ramón:** Treinta años de conserje.
    - **Ramón:** Y siempre acaba siendo un cable.
  - **Paso 20.3 · Hablar** con Alumna — «Una niña de 1.º llora junto a la valla»
    - **Alumna:** No encuentro a mi mamá.
    - **Tú:** La buscamos juntos. Llevarla con Lucía.
    - **Profe Lucía:** Has hecho bien en traerla.
    - **Profe Lucía:** empatia +2 o responsabilidad +2.
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Te agachas y le das la mano: «La buscamos juntos»» _(efecto: empatia +2; decisión «nina perdida» = Juntos)_
        - _Narrador:_ _Dais una vuelta por el patio. Enseguida aparece su madre, que la estaba buscando por la otra puerta._
        - **Alumna:** ¡Gracias! Cuando sea mayor quiero ser como tú.
      - ➤ «La llevas con Lucía, que sabe qué hacer» _(efecto: Profe Lucía +3; responsabilidad +2; decisión «nina perdida» = Lucia)_
        - **Profe Lucía:** Bien hecho. Lo anuncio por el altavoz… ¡que ya funciona! Y su madre llega corriendo en un minuto.
  - **Paso 20.4 · Hablar** con Bruno — «Al puesto de limonada de Bruno no va nadie»
    - **Rubén:** Tenemos cero clientes.
    - **Bruno:** No son cero. Somos nosotros dos.
    - **Rubén:** Eso son dos. Por primera vez no está enfadado. Está decepcionado.
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Le ayudas: «Déjame a mí, sonríe y ofrece probarla gratis»» _(efecto: Bruno +8; Rubén +4; empatia +1; decisión «festival bruno» = Ayudar)_
        - _Narrador:_ _Pruebas gratis, sonrisas… En cinco minutos hay cola en el puesto de Bruno._
        - **Bruno:** …Vale. Ha funcionado. No te lo voy a agradecer en voz alta. …Gracias. En voz baja.
      - ➤ «Le compras un vaso y le dices que está buena» _(efecto: Bruno +4; decisión «festival bruno» = Comprar)_
        - **Bruno:** ¿A que sí? ¡A que está buena! …Ya van dos vasos. Uno era mío, pero cuenta.
      - ➤ «Le dejas con su puesto: tienes otras cosas que hacer» _(efecto: decisión «festival bruno» = Nada)_
        - **Bruno:** Ya. Como todos.
- **Paso 21 · Escena**
  - **Mamá/Papá:** ¿Vosotros habéis hecho todo esto?
  - **Vega:** ¡Todo!
  - **Omar:** ¡Se han acabado! ¡VEINTE MINUTOS!
  - _(si tienes la marca «iker en el grupo»)_ **Iker:** Exactamente diecinueve minutos y treinta y ocho segundos.
  - _(si tienes la marca «iker en el grupo»)_ **Omar:** ¡Eso!
  - **Sara:** Antes y después.
  - **Nico:** ¡CRUAC!
  - _(si tienes la marca «tarea brillante»)_ **Profe Lucía:** Lo habéis hecho de maravilla.
  - _(si NO tienes la marca «tarea brillante»)_ **Profe Lucía:** No todo ha salido perfecto.
  - _(si NO tienes la marca «tarea brillante»)_ **Profe Lucía:** Pero así son las fiestas de verdad.
  - _(si NO tienes la marca «tarea brillante»)_ **Profe Lucía:** Y ha sido un día precioso.
- **Paso 22 · Escena**
  - **Marta:** Y ahora… ¡Concurso de talentos!
    - 🎬 **Escena de cámara «Cole10_G22_Musica»** _(música: → Intima)_
  - **Marta:** Niños levantando las manos. Otros escondiéndose.
  - **Omar:** Yo no existo.
  - **Marta:** ¿Quién se atreve? Yo te acompaño.
  - **Nico:** Esto va a ser histórico. O vergonzoso.
  - **Nico:** Cuando otro niño duda…
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
  - _(si tienes la marca «aplauso final»)_ **Abu:** ¡Eso sí que no lo hacía cuando tenía tu edad!
    - 🎬 **Escena de cámara «Cole10_G24_Musica»** _(música: → Intima)_
  - _(si NO tienes la marca «aplauso final»)_ **Profe Lucía:** Eso también es valentía.
  - **Profe Lucía:** Gracias a todos.
  - **Marisa:** ¡LIBROS! _[silencio 0.9 s]_
  - _(si en «festival bruno» elegiste «Ayudar»)_ **Bruno:** El puesto ha funcionado.
  - _(si en «festival bruno» elegiste «Ayudar»)_ **Rubén:** Ya lo has dicho. _[silencio 0.9 s]_
  - _(si en «festival bruno» elegiste «Ayudar»)_ **Bruno:** Rubén.
- **Paso 25 · Cinemática**
  - 🎬 **Cinemática «Cole10_G25»** _(música: → Intima efecto Momento)_
    - _En escena:_ Hugo, Omar, Nico, Bruno, Vega, Profe Lucía, Sara
    - _Cámara:_ 10 planos (General, Medio, PrimerPlano, Reaccion, Dolly, Seguir)
    - **Omar:** Ha sido un buen día.
    - **Sara:** Técnicamente, muy buen día.
    - **Nico:** Y todavía queda mañana. ¿Hay magdalenas?
    - **Omar:** No. Me he comido la última.

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
  - 🎬 **Escena al completarlo «Cole11_G3_Entra»** _(música: → Descubrimiento)_
    - _En escena:_ Omar, Nico, Profe Lucía
    - **Profe Lucía:** Antes de terminar primaria, quiero que hagáis algo que pueda mejorar Valmar.
    - **Profe Lucía:** No quiero memorizar respuestas. Quiero que penséis.
    - **Profe Lucía:** «Un invento para mejorar Valmar».
    - _(si en «companero» elegiste «Nico»)_ **Nico:** ¿Puede explotar? Era una pregunta.
    - **Omar:** ¿Puede llevar comida?
    - **Profe Lucía:** Si ayuda a Valmar, puede llevar comida. Equipos de tres.
    - _(si en «companero» elegiste «Nico»)_ **Nico:** ¿Delante de las familias?
    - _(si en «companero» elegiste «Nico»)_ **Nico:** Mi abuela se ríe hasta cuando no pasa nada.
- **Paso 3 · Clase** — «Clase de Ciencias»
- **Paso 4 · Escena**
  - **Omar:** Tú y yo. Bueno… Si quieres.
  - 🎬 **Escena al completarlo «Cole11_G5_Entra»**
    - _En escena:_ Hugo, Nico, Sara, Iker, Mateo
    - _(si en «companero» elegiste «Sara»)_ **Sara:** Acepto. Tengo tres cuadernos de ideas.
    - _(si en «companero» elegiste «Sara»)_ **Sara:** Este es el de las que nunca le he contado a nadie. Hoy podemos abrirlo.
    - _(si en «companero» elegiste «Nico»)_ **Nico:** ¡Sí! Vamos a hacer algo enorme. Y seguro/a. Muy seguro/a.
    - _(si en «companero» elegiste «Iker» y tienes la marca «iker en el grupo»)_ **Iker:** Acepto.
    - _(si en «companero» elegiste «Mateo» y tienes la marca «ayudaste a mateo»)_ **Mateo:** ¿Yo? Vale. Mi padre me enseña.
    - _(si en «companero» elegiste «Hugo» y tienes la marca «hugo con el grupo»)_ **Hugo:** ¡Sí! He leído muchos libros de inventores.
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
  - **Omar:** Bueno. ¿Qué inventamos? Tomates. Lechugas.
  - **Omar:** Me gusta este invento. Robot. Como Bigotes. _[silencio 0.9 s]_
  - **Omar:** Tú buscas. Equipo perfecto. Manos de artista. Pero no te lo comas. _[silencio 1.8 s]_
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
      - **Marisa:** ¿Inventos? Azul arriba.
      - **Marisa:** Y abajo están las ideas locas. Son mis favoritas. _[silencio 0.9 s]_
  - **Paso 7.2 · Hablar** con Ramón — «Entrevista a Ramón (conserjería)»
    - **Ramón:** ¿Una entrevista?
  - **Paso 7.3 · Hablar** con Abu — «Entrevista a Abu (en casa)»
    - **Abu:** ¿Una entrevista para el colegio? ¡Qué importante! Pregunta, pregunta.
    - _(si en «tema» elegiste «Huerto»)_ **Abu:** Cuando tenía tu edad, en casa teníamos huerto. Lo más importante: regar temprano y tener paciencia.
    - _(si en «tema» elegiste «Robot»)_ **Abu:** ¿Un robot? En mis tiempos el robot era tu hermano mayor, y recogía cuando se lo mandaban. Me parece buena idea.
    - _(si en «tema» elegiste «Mascotas»)_ **Abu:** Una vez perdimos a un perro que se llamaba Chispa. Lo encontró la panadera. Los vecinos son el mejor tablón.
    - _(si en «tema» elegiste «Museo»)_ **Abu:** ¿Un museo del colegio? Yo fui a ese colegio, ¿lo sabías? Te puedo prestar la foto de mi clase.
  - **Paso 7.4 · Usar** — «Observa la fuente del parque»
    - 🖐 _Al usar «La fuente del parque»:_
      - **Omar:** Doce. Y yo llevo tres vasos. Por la ciencia.
- **Paso 8 · Usar** — «Coge cartón para reciclar (almacén del gimnasio)»
  - _En escena:_ Omar (te acompaña), Sara (si en «companero» elegiste «Sara») (te acompaña), Nico (si en «companero» elegiste «Nico») (te acompaña), Iker (si en «companero» elegiste «Iker») (te acompaña), Mateo (si en «companero» elegiste «Mateo») (te acompaña), Hugo (si en «companero» elegiste «Hugo») (te acompaña)
  - 🎬 **Escena al completarlo «Cole11_G9_Entra»**
    - _En escena:_ Omar
    - **Omar:** Tengo dos. Puedo poner la mitad.
  - 🖐 _Al usar «Cajas de cartón para reciclar»:_
    - **Andrés:** Coged lo que necesitéis. Menos esa. Esa tiene los conos.
    - _(si en «companero» elegiste «Nico»)_ **Nico:** ¿Y si necesitamos conos?
    - _(si en «companero» elegiste «Nico»)_ **Andrés:** No necesitáis conos.
    - _(si en «companero» elegiste «Nico»)_ **Nico:** Vale.
- **Paso 9 · Acción del jugador** — «Compra cartulinas en la librería»
  - _Lugar:_ la librería
  - ⏰ _Si tardas, Omar dice:_ «Yo pongo la mitad de las cartulinas. Bueno, un tercio. Tengo dos monedas.»
- **Paso 10 · Ir a** Aula de 1.º A — «Vuelve a clase a montar la maqueta»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Omar, Sara (si en «companero» elegiste «Sara»), Nico (si en «companero» elegiste «Nico»), Iker (si en «companero» elegiste «Iker»), Mateo (si en «companero» elegiste «Mateo»), Hugo (si en «companero» elegiste «Hugo»)
- **Paso 11 · Escena**
  - _(si en «companero» elegiste «Sara»)_ **Sara:** No podemos ponerlo ahí. Está descentrado.
    - 🎬 **Escena de cámara «Cole11_G11_Musica»** _(música: → Tension)_
  - **Omar:** Nadie va a notar dos centímetros.
  - _(si en «companero» elegiste «Sara»)_ **Sara:** Yo sí.
  - _(si en «companero» elegiste «Nico»)_ **Nico:** ¡Tiene que verse desde la puerta!
  - **Omar:** Pero ocupa media mesa.
  - _(si en «companero» elegiste «Nico»)_ **Nico:** Precisamente.
  - _(si en «companero» elegiste «Iker»)_ **Iker:** Antes de construir necesitamos una tabla.
  - **Omar:** Ya tenemos una mesa.
  - _(si en «companero» elegiste «Iker»)_ **Iker:** No.
  - _(si en «companero» elegiste «Mateo»)_ **Mateo:** He pensado que… Quizá no sea suficientemente bueno.
  - _(si en «companero» elegiste «Hugo»)_ **Hugo:** Necesita una historia.
  - _(si en «companero» elegiste «Hugo»)_ **Hugo:** Todo invento necesita una razón para existir. _[silencio 0.9 s]_
  - **Omar:** Vale. Estamos empezando a enfadarnos.
  - **Omar:** Y todavía no hemos construido nada. _[silencio 0.9 s]_
  - _(si en «companero» elegiste «Mateo»)_ **Mateo:** ¿De verdad os gusta?
  - ❓ **Pregunta al jugador:** ¿Cómo lo resolvéis?
    - ➤ «Juntar las dos ideas: un poco de cada» _(efecto: Hugo +2; Iker +2; Mateo +2; Nico +2; Omar +3; Sara +2; empatia +1; decisión «discusion» = Juntar)_
      - **Omar:** ¡Eso! Exacto Y con luces. Con historia Y con datos. Somos unos genios de la diplomacia.
    - ➤ «Votar, y lo que salga» _(efecto: responsabilidad +1; decisión «discusion» = Votar)_
      - **Omar:** Votación. Dos contra uno. Bueno, uno contra uno contra uno. Otra vez. …Ya está: gana la mezcla.
    - ➤ «Decidir tú, que para algo lo has pensado» _(efecto: Hugo -2; Iker -2; Nico -2; Omar -1; Sara -2; valentia +1; decisión «discusion» = Decidir)_
      - **Omar:** Vale… lo hacemos como dices. Pero que conste que ha sido un poco de «porque sí».
  - 🎬 **Escena al completarlo «Cole11_G12_Entra»**
    - _En escena:_ Omar
    - **Omar:** ¡Bocadillo funciona!
- **Paso 12 · Minijuego** — «Monta la maqueta»
  - 🎮 _Cómo se juega:_ Pega cada pieza cuando la aguja esté en verde
- **Paso 13 · Transición (pasa el tiempo)** — «La noche antes de la presentación…»
  - ⏳ _Pantalla de transición:_ «La noche antes de la presentación…»
- **Paso 14 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** [tu nombre], teléfono. Es Omar.
    - 🎬 **Escena de cámara «Cole11_G14_Musica»** _(música: → Intima)_
  - **Mamá/Papá:** Tenemos una emergencia.
  - **Mamá/Papá:** Mi hermano pequeño/a se ha sentado encima de la maqueta. _[silencio 0.9 s]_
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
  - 🎬 **Escena al completarlo «Cole11_G16_Entra»**
    - _En escena:_ Mamá/Papá, Omar, Bruno
    - **Mamá/Papá:** ¡Ánimo, [tu nombre]!
    - **Omar:** Me tiemblan las rodillas. ¿A ti también?
    - **Bruno:** Está junto a otra maqueta. Suerte. He hecho un volcán.
- **Paso 16 · Ir a** Aula de 1.º A — «Ve a clase: las familias ya están llegando»
  - _Lugar:_ Aula de 1.º A · _En escena:_ Profe Lucía, Mamá/Papá, Abu, Andrés, Bruno, Omar, Sara (si en «companero» elegiste «Sara»), Nico (si en «companero» elegiste «Nico»), Iker (si en «companero» elegiste «Iker»), Mateo (si en «companero» elegiste «Mateo»), Hugo (si en «companero» elegiste «Hugo»)
- **Paso 17 · Escena**
  - **Profe Lucía:** Bienvenidas, familias. Hoy cada equipo presenta su invento para Valmar. Después, el jurado hará algunas preguntas.
  - **Mamá/Papá:** (desde el fondo) ¡Ánimo, [tu nombre]!
  - **Omar:** Me tiemblan las rodillas. ¿A ti te tiemblan? A mí las dos.
  - **Bruno:** Suerte. Yo he hecho un volcán. Otra vez. Es un clásico. _[gesto Shrug]_
  - 🎬 **Escena al completarlo «Cole11_G18_Entra»** _(música: → Intima)_
    - _En escena:_ Omar
    - **Omar:** Y sobrevivió. Esta parte no estaba en el diseño.
    - **Omar:** Pero la hicimos juntos.
- **Paso 18 · Clase** — «Presenta el proyecto (las preguntas del jurado)»
- **Paso 19 · Escena**
  - _(si tu última nota es 8 o más)_ **Profe Lucía:** Buenos datos. Y, sobre todo, habéis sabido trabajar juntos. _[silencio 0.9 s]_
    - 🎬 **Escena de cámara «Cole11_G19_Musica»** _(música: → Intima → Descubrimiento)_
  - _(si tu última nota es menor que 8)_ **Profe Lucía:** Pero habéis aprendido algo importante. _[silencio 1.8 s]_
  - _(si tu última nota es 8 o más)_ **Profe Lucía:** Voy a enviarlo al periódico de Valmar.
  - _(si tu última nota es 8 o más)_ **Profe Lucía:** Creo que merece que lo conozca el barrio. _[silencio 0.9 s]_
  - **Mamá/Papá:** Pase lo que pase… Estoy orgulloso/a de ti. Abrazo.
  - **Abu:** ¿Sabes qué es lo mejor de un proyecto?
  - **Abu:** Que mañana ya sabes más que hoy.
  - **Profe Lucía:** Queda una semana.
  - **Omar:** ¿Ya? _[silencio 0.9 s]_
  - _(si en «companero» elegiste «Sara»)_ **Sara:** El tiempo pasa.
  - _(si en «companero» elegiste «Nico»)_ **Nico:** Pues yo todavía tengo que ganar un último partido.
  - _(si en «companero» elegiste «Sara»)_ **Sara:** Todavía tengo aquel esquema.
  - _(si en «companero» elegiste «Nico»)_ **Nico:** Nuestro proyecto casi podía verse desde la puerta.
  - _(si en «companero» elegiste «Iker»)_ **Iker:** Conservé los datos.
  - _(si en «companero» elegiste «Mateo»)_ **Mateo:** Todavía tengo los dibujos.
  - _(si en «companero» elegiste «Hugo»)_ **Hugo:** Le pusimos una historia.

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
  - **Mamá/Papá:** Buenos días, [tu nombre]. Hoy es el último día.
  - **Mamá/Papá:** Parece que fue ayer cuando te puse la mochila por primera vez.
  - **Abu:** Los primeros días pasan deprisa.
  - **Abu:** Por eso hay que mirarlos bien. _[silencio 0.9 s]_
  - **Mamá/Papá:** Esta tarde vamos todos a la ceremonia. Y traigo pañuelos.
  - **Abu:** Yo no necesito. Bueno.
- **Paso 3 · Ir a** Vestíbulo — «Ve al colegio por última vez»
  - _Lugar:_ Vestíbulo · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»)
- **Paso 4 · Escena**
  - **Nico:** ¡[tu nombre]! Es el último día.
    - 🎬 **Escena de cámara «Cole12_G4_Musica»** _(música: → Intima)_
  - **Sara:** Técnicamente empezaremos otra etapa.
  - **Nico:** Sara. Hoy no seas técnica.
  - **Omar:** Propongo una última vuelta. Por todo. Y por el comedor.
  - _(si tienes el recuerdo «primer grupo»)_ **Omar:** «[Nombre del grupo]» había vuelto a reunirse.
- **Paso 5 · Varios objetivos (en cualquier orden)** — «visitar al menos 4 de 6 lugares.»
  - _Lugar:_ Mostrador de la biblioteca · _En escena:_ Nico (te acompaña), Sara (te acompaña), Omar (te acompaña), Marisa
  - 🎬 **Escena al completarlo «Cole12_G6_Entra»**
    - _En escena:_ Omar, Ramón
    - **Ramón:** ¿Preparados?
    - **Omar:** No. Pero abre.
  - **Paso 5.1 · Usar** — «Tu primer pupitre (clase)»
    - 🖐 _Al usar «Tu primer pupitre»:_
      - _(si en «asiento» elegiste «Sara»)_ _Narrador:_ _✨ Te sentaste junto a Sara, y te habló de escarabajos durante media hora._
      - _(si en «asiento» elegiste «Nico»)_ _Narrador:_ _✨ Te sentaste junto a Nico, que te enseñó su balón firmado (por él mismo)._
      - _(si en «asiento» elegiste «Mateo»)_ _Narrador:_ _✨ Te sentaste junto a Mateo, el nuevo, que no se atrevía a hablar._
      - _(si tienes el recuerdo «primer amigo»)_ _Narrador:_ _✨ Y en el pasillo, a Mateo se le cayeron los libros. Tú le ayudaste a recogerlos. Tu primer amigo._
      - _(si tienes el recuerdo «segunda oportunidad»)_ _Narrador:_ _✨ Un día viste a Mateo comiendo solo… y te sentaste con él._
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo también me acuerdo. De todo. Gracias por aquel día.
      - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Me acuerdo.
  - **Paso 5.2 · Usar** — «Tu taquilla (pasillo)»
    - 🖐 _Al usar «Tu taquilla»:_
      - _(si tienes el recuerdo «mochila perdida»)_ _Narrador:_ _✨ El día que desapareció tu mochila. Rubén, el mensajero de Bruno, y todo el colegio buscándola._
      - _(si tienes la marca «dejaste mochila»)_ _Narrador:_ _✨ Aquel día te la dejaste en el banco. Desde entonces miras dos veces antes de irte._
      - _(si tienes el recuerdo «misterio colegio»)_ _Narrador:_ _✨ Y detrás de la chapa, una nota vieja: «NO ENTRES». La nota de una niña de 1998 que hoy es tu profe._
      - **Omar:** Esta taquilla ha visto demasiadas cosas.
      - **Omar:** Deberían ponerle una placa. _[silencio 0.9 s]_
  - **Paso 5.3 · Usar** — «El campo de fútbol»
    - 🖐 _Al usar «Un balón olvidado»:_
      - _(si tienes la marca «partido ganado»)_ _Narrador:_ _✨ Tu primer partido contra el equipo de Bruno. Ganasteis. Nico corrió por todo el campo gritando._
      - _(si tienes la marca «partido perdido»)_ _Narrador:_ _✨ Tu primer partido contra el equipo de Bruno. Perdisteis… pero Omar hizo una parada imposible._
      - _(si tienes la marca «partido empate»)_ _Narrador:_ _✨ Empatasteis tu primer partido. Nico dijo que un empate es una victoria compartida._
      - _(si tienes la marca «torneo ganado»)_ _Narrador:_ _✨ Y el torneo. La final. Medalla de oro, colgada al cuello delante de tu familia._
      - _(si tienes la marca «torneo perdido»)_ _Narrador:_ _✨ Y el torneo. La final. Medalla de plata… y Abu diciendo que del resultado casi no se acuerda._
      - _(si en «capitan» elegiste «Yo»)_ _Narrador:_ _✨ Te eligieron capitán. Omar te hizo el brazalete con cinta de carrocero. Todavía lo tienes._
      - **Nico:** Una victoria compartida. _[silencio 0.9 s]_
      - **Abu:** Lo importante es que lo diste todo.
      - **Nico:** Aquí he pasado la mitad de mi vida.
  - **Paso 5.4 · Usar** — «La biblioteca»
    - 🖐 _Al usar «La mesa donde estudiabas»:_
      - _(si tienes el recuerdo «primer examen»)_ _Narrador:_ _✨ El examen imposible. Los apuntes, Marisa, y estudiar hasta tarde._
      - _(si tienes el recuerdo «casi suspendo»)_ _Narrador:_ _✨ Aquel examen que casi suspendes. Y Lucía dándote otra oportunidad._
      - _(si en «companero estudio» elegiste «Sara»)_ _Narrador:_ _✨ Estudiaste con Sara. Te hizo un esquema con colores. Todavía lo tienes._
      - _(si en «companero estudio» elegiste «Iker»)_ _Narrador:_ _✨ Estudiaste con Iker. Tenía una tabla para todo. Hasta para los descansos._
      - _(si en «companero estudio» elegiste «Mateo»)_ _Narrador:_ _✨ Estudiaste con Mateo, que explicaba los problemas con dibujos._
      - _(si tienes la marca «suspendiste examen»)_ _Narrador:_ _✨ Y aquel suspenso. Y la clase de repaso de Lucía. Aprendiste que suspender no es el final de nada._
      - _(si tienes el recuerdo «proyecto final»)_ _Narrador:_ _✨ Tu proyecto de fin de curso, entre cartulinas y pegamento. Lo presentasteis aquí al lado._
      - **Marisa:** Ahí viene mi lector favorito. O uno de ellos.
      - _(si tienes la marca «suspendiste examen»)_ **Marisa:** Venid a verme en el instituto. Y yo tampoco. _[silencio 0.9 s]_
  - **Paso 5.5 · Usar** — «El almacén del gimnasio»
    - 🖐 _Al usar «El almacén del gimnasio»:_
      - _(si tienes la marca «sabe libro hugo»)_ _Narrador:_ _✨ Aquí encontraste el libro de Hugo, «La isla de las mil llaves». Nadie sabía que era suyo._
      - _(si tienes el recuerdo «los malotes»)_ _Narrador:_ _✨ La persecución por el colegio. Esconderte de Ramón. Y Hugo diciendo «Yo no quería»._
      - _(si tienes el recuerdo «hugo amigo»)_ _Narrador:_ _✨ Y el día que Hugo dejó a Bruno y se vino con vosotros._
      - _(si tienes el recuerdo «detective»)_ _Narrador:_ _✨ Y el caso de las bromas del colegio, resuelto con una lupa._
      - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Aquí empezó todo, ¿verdad? Si no hubieras encontrado mi libro… Me alegro de que lo encontraras.
      - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Aquí empezó todo. Si no hubieras encontrado mi libro…
      - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** No sé qué habría pasado.
      - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Me alegro de que lo encontraras. _[silencio 0.9 s]_
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
      - _(si tienes el recuerdo «primer grupo»)_ **Sara:** ¿Seguís queriendo ser lo que dijimos aquella tarde?
      - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Aunque ahora también quiero ser astronauta. _[silencio 0.9 s]_
      - _(si tienes el recuerdo «primer grupo»)_ **Nico:** Eso no estaba en el plan.
      - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Los planes cambian.
- **Paso 6 · Ir a** La sala cerrada — «Ve a la sala del fondo: hoy se abre la cápsula»
  - _Lugar:_ La sala cerrada · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Profe Lucía, Ramón
- **Paso 7 · Cinemática**
  - 🎬 **Cinemática «Cole12_Capsula»** _(música: → Intima)_
    - _En escena:_ Nico, Profe Lucía, Omar, Ramón
    - _Cámara:_ 5 planos (General, PrimerPlano, Hombro)
    - **Profe Lucía:** Lo prometí.
    - **Ramón:** Treinta años guardando llaves. Esta es mi favorita.
    - _(si en «capsula» elegiste «Carta»)_ **Profe Lucía:** Hola, yo del último día.
    - _(si en «capsula» elegiste «Carta»)_ **Profe Lucía:** ¿Has sido valiente? ¿Sigues con tus amigos?
    - _(si en «capsula» elegiste «Carta»)_ **Tú:** Sí. A las dos cosas.
    - _(si en «capsula» elegiste «Dibujo»)_ **Omar:** ¡Mira! ¡Salgo con un bocadillo!
    - _(si en «capsula» elegiste «Dibujo»)_ **Omar:** Es el retrato más realista de mi vida.
    - _(si en «capsula» elegiste «Prediccion»)_ **Profe Lucía:** Nico será futbolista.
    - _(si en «capsula» elegiste «Prediccion»)_ **Nico:** Me lo quedo. Por si acaso.
    - _(si en «capsula» elegiste «Pregunta»)_ **Profe Lucía:** ¿Seguimos siendo amigos?
    - _(si en «capsula» elegiste «Pregunta»)_ **Omar:** Qué pregunta más tonta. Claro que sí.
    - **Profe Lucía:** Mi clase de 1998 hizo exactamente lo mismo.
    - **Profe Lucía:** Y ahora estoy aquí con vosotros.
  - 🎬 **Escena al completarlo «Cole12_G8_Entra»**
    - _En escena:_ Ramón
    - **Ramón:** Hasta la próxima generación.
- **Paso 8 · Ir a** el patio — «Ve al patio: la ceremonia está a punto de empezar»
  - _Lugar:_ el patio · _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»), Profe Lucía, Andrés, Marta, Ramón, Marisa, Mamá/Papá, Abu, Bruno, Rubén, Vega, Álex
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Cole12_FotoClase»** _(música: → Intima efecto Momento)_
    - _En escena:_ Mamá/Papá, Abu, Profe Lucía, Nico, Sara, Omar, Mateo, Hugo, Iker, Vega, Álex
    - _Cámara:_ 2 planos (General, Hombro)
    - **Mamá/Papá:** ¡Todos juntos! No perfectamente.
    - **Nico:** ¡Si soy el más bajito!
    - **Omar:** Yo detrás. Por razones de altura.
    - **Abu:** Y de timidez.
    - **Mamá/Papá:** Tres… Dos… Uno…
- **Paso 10 · Escena**
  - **Profe Lucía:** Familias, alumnos… Hoy termina nuestra etapa de primaria.
    - 🎬 **Escena de cámara «Cole12_G10_Musica»** _(música: → Intima)_
  - **Profe Lucía:** Os vi llegar con mochilas más grandes que vosotros.
  - **Profe Lucía:** Os vi perder mochilas. Encontrar amigos. Resolver misterios. Ganar torneos. Perderlos. _[silencio 0.9 s]_
  - **Profe Lucía:** Aprender a pedir ayuda. Y aprender a darla.
  - **Mamá/Papá:** Aplausos. _[silencio 0.9 s]_
  - _(si tu rasgo deportividad es 5 o más)_ **Andrés:** Y el premio a la deportividad es para…
  - _(si en «talento» elegiste «Cantar»)_ **Marta:** Y ahora empieza [tu nombre]. _[silencio 0.9 s]_
  - _(si en «talento» elegiste «Chistes»)_ **Marta:** Y hoy prometemos que los chistes de matemáticas quedan fuera.
  - _(si en «talento» elegiste «Animar»)_ **Marta:** Y unas palmas para quien siempre estuvo animando a los demás.
- **Paso 11 · Varios objetivos (en cualquier orden)** — «Despídete»
  - **Paso 11.1 · Hablar** con Profe Lucía — «Lucía»
    - **Profe Lucía:** [tu nombre]. Ven.
    - _(si tienes la marca «suspendiste examen»)_ **Profe Lucía:** Aquel examen… Lo recuperaste.
    - _(si tienes la marca «secreto lucia»)_ **Profe Lucía:** Y gracias por guardar mi secreto.
    - _(si en «foto lucia» elegiste «Devolver»)_ **Profe Lucía:** Gracias por devolvérmela.
    - _(si en «foto lucia» elegiste «Devolver»)_ **Profe Lucía:** Ya no me da vergüenza. Casi.
    - _(si en «foto lucia» elegiste «Clase»)_ **Profe Lucía:** Toda la clase me llama «la de las coletas». Te odio un poquito.
    - _(si en «foto lucia» elegiste «Clase»)_ **Profe Lucía:** Cuando seas mayor, vuelve. No automático.
  - **Paso 11.2 · Hablar** con Bruno — «Bruno»
    - **Bruno:** Eh.
    - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Cuando hablaste conmigo… _[silencio 0.9 s]_
    - _(si tienes la marca «bruno hablaste con el»)_ **Bruno:** Nadie había hecho eso. _[silencio 0.9 s]_
    - _(si en «festival bruno» elegiste «Ayudar»)_ **Bruno:** Lo de la limonada estuvo bien. Muy bien.
    - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Todavía me acuerdo de cuando me acusaste. No fui yo. Pero ya pasó.
    - _(si tienes la marca «torneo ganado»)_ **Bruno:** Y el torneo… Me ganaste. Todavía me duele.
    - _(si tienes la marca «torneo perdido»)_ **Bruno:** Me ganaste. Fue la final más difícil que he jugado.
    - ❓ **Pregunta al jugador:** ¿Qué le dices a Bruno?
      - ➤ «En el instituto, ¿empezamos de cero?» _(efecto: Bruno +10; empatia +1; decisión «adios bruno» = DeCero)_
        - **Bruno:** …De cero. Vale. Pero en fútbol no te voy a dejar ganar ni en el instituto.
      - ➤ «Suerte, Bruno. De verdad.» _(efecto: Bruno +5; decisión «adios bruno» = Suerte)_
        - **Bruno:** Suerte. …Tú también. Y lo digo de verdad. No te acostumbres.
      - ➤ «Ya nos veremos.» _(efecto: decisión «adios bruno» = Seco)_
        - **Bruno:** Ya nos veremos. Eso seguro.
  - **Paso 11.3 · Hablar** con Ramón — «Ramón»
    - **Ramón:** Y yo aquí. Para que no olvides algo.
    - **Ramón:** A veces esconden recuerdos. _[silencio 0.9 s]_
- **Paso 12 · Escena**
  - _En escena:_ Nico, Sara, Omar, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Iker (si tienes la marca «iker en el grupo»)
  - **Omar:** Bueno. ¿Y ahora qué? Y no conoceremos a nadie.
  - **Nico:** ¡Nos conoceremos a nosotros! Eso ya es algo.
  - **Sara:** Propongo una promesa.
  - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo llegué sin conocer a nadie. Y ahora mirad. No me da miedo. Casi.
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
    - _En escena:_ Hugo, Mamá/Papá, Nico, Mateo, Sara, Omar, Iker, Abu
    - _Cámara:_ 3 planos (General, PrimerPlano)
    - **Sara:** Técnicamente…
    - **Nico:** Sara.
    - **Omar:** Pues yo me quedo. Tengo comida para tres horas.
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** El primer día se me cayeron los libros. Y tú te agachaste. Gracias.
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** Si en el instituto alguien me dice «hazlo tú»… Lo he practicado.
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** Dato curioso. Hemos pasado juntos unos mil recreos. No es suficiente.
    - **Omar:** Lo del puré iba en serio.
    - **Sara:** Gente nueva, sin olvidar a los de siempre.
    - **Nico:** Primer verano. Banco del parque.
    - **Abu:** Los últimos días se recuerdan tanto como los primeros.
    - **Abu:** Te lo dije esta mañana.
    - **Mamá/Papá:** [tu nombre]. Cuando quieras. Sin prisa.
- **Paso 14 · Cinemática**
  - 🎬 **Cinemática «Cole12_FinDeEpisodio»** _(música: → Intima → Descubrimiento)_
    - _En escena:_ Nico, Sara, Omar, Mateo, Hugo, Iker, Mamá/Papá, Abu
    - _Cámara:_ 3 planos (DosPlanos, General)
    - **Nico:** A la de tres.
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Nico:** ¡LOS IMPARABLES!
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ **Nico:** ¡LA PATRULLA VALMAR!
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ **Nico:** ¡LOS DEL BANCO AZUL!
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ **Nico:** ¡LOS DINOSAURIOS!
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
  - **Cosme:** ¡No! ¡No, no, no! ¡He dicho que no explotes!
    - 🎬 **Escena de cámara «Loco_N1_G1_Musica»** _(música: → Descubrimiento)_
  - **Cosme:** ¡Eso iba por ti, bobina! _[silencio 0.9 s]_
  - **Cosme:** Ah. Tú. Esto no es lo que parece. _[plano Medio de Cosme]_
  - **Cosme:** Bueno. Es exactamente lo que parece.
  - **Cosme:** ¡Cof! ¡Cof! Hola, criatura.
  - **Cosme:** No te asustes. El humo verde es normal. El morado no.
  - **Cosme:** Si alguna vez ves humo morado, te vas. Sin correr.
  - **Cosme:** Bueno. Corriendo también vale. _[silencio 0.9 s]_
  - **Cosme:** Soy Cosme. Inventor. Genio. Vecino. En ese orden. ¿Qué? Nada.
  - **Tú:** ¿Qué ha explotado?
  - **Cosme:** Mi microondas temporal.
  - **Cosme:** Calienta la comida en el pasado. _[silencio 0.9 s]_
  - **Cosme:** Así está caliente antes de que tengas hambre.
  - **Cosme:** Funcionaba perfectamente.
  - **Cosme:** Durante unos ocho segundos.
  - **Cosme:** Han salido volando tres piezas. El tornillo cuántico.
  - **Cosme:** La bobina de gominola.
  - **Cosme:** Y el chip de mi abuela.
  - **Cosme:** No preguntes por el chip. Es complicado.
  - **Cosme:** Y ligeramente ilegal en tres dimensiones.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «¡Te ayudo a buscarlas!» _(efecto: Cosme +5; valentia +1)_
      - **Cosme:** ¿Ayudar? ¿Sin pedir nada? Me caes bien.
      - **Cosme:** Tú buscas. Yo superviso.
      - **Cosme:** Desde una distancia prudente. _[silencio 0.9 s]_
    - ➤ «¿El chip de tu abuela?» _(efecto: Cosme +3; curiosidad +1)_
      - **Cosme:** Mi abuela era especial. Muy especial.
      - **Cosme:** Y tenía mejores cálculos que yo. No hablemos de eso. _[silencio 0.9 s]_
      - **Cosme:** Busca las piezas, criatura.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Recupera las 3 piezas del microondas temporal»
  - 🎬 **Escena al completarlo «Loco_N1_G3_Entra»**
    - _En escena:_ Cosme
    - **Cosme:** Si el tornillo ha vuelto a aparecer… No. ¡Criatura! ¡Perfecto! Justo a tiempo.
  - **Paso 2.1 · Usar** — «Busca el tornillo cerca de la fuente del parque.»
    - 🖐 _Al usar «El tornillo cuántico»:_
      - _Narrador:_ _Durante un segundo, Valmar parece otro lugar. Parpadeas._
      - _Narrador:_ _Y todo vuelve a ser normal._
  - **Paso 2.2 · Usar** — «Recupera la bobina en la heladería.»
    - 🖐 _Al usar «Una bobina… dentro de un helado»:_
      - _Narrador:_ _NIÑO: «Esta cosa estaba dentro.»_
      - _Narrador:_ _NIÑO: «Sabe a martes.»_
      - **Tú:** Te cambio la bobina por mi merienda.
      - _Narrador:_ _NIÑO: «Trato.» NIÑO: «Pero si vuelve el martes, me avisas.»_
      - **Tú:** Es una pieza del futuro.
      - _Narrador:_ _NIÑO: «Entonces no quiero tocarla.»_
      - _Narrador:_ _NIÑO: «¿Me das tu merienda?»_ _[silencio 0.9 s]_
      - _Narrador:_ _NIÑO: «Buena decisión.»_
      - ❓ **Pregunta al jugador:** ¿Cómo la consigues?
        - ➤ «Le cambias la bobina por tu merienda» _(efecto: empatia +1)_
          - _Narrador:_ _Trato hecho. El niño te mira muy serio y dice: «El martes vuelve». Vale._
        - ➤ «Le dices que es un helado del futuro y que ya ha caducado» _(efecto: humor +1)_
          - _Narrador:_ _Te la da con cara de asco. Técnicamente no mentías: viene del pasado. Casi._
  - **Paso 2.3 · Usar** — «Busca el chip. Bigotes lo tiene.»
    - 🖐 _Al usar «Bigotes (con un chip en el collar)»:_
      - **Bigotes XVII:** Cría humana. Tenemos un problema. Tú necesitas eso.
      - **Bigotes XVII:** Y yo necesito que no hagas preguntas.
      - **Tú:** ¿Hablas? _[silencio 0.9 s]_
      - **Bigotes XVII:** No. Tú tampoco has oído nada.
      - **Bigotes XVII:** Y esto nunca ha pasado.
      - **Bigotes XVII:** Y no se lo cuentes a nadie.
      - **Bigotes XVII:** Especialmente a los humanos. _[silencio 0.9 s]_
- **Paso 3 · Ir a** El garaje de Cosme — «Lleva las tres piezas a Cosme.»
- **Paso 4 · Escena**
  - **Cosme:** Tornillo. Bobina. Chip.
    - 🎬 **Escena de cámara «Loco_N1_G4_Musica»** _(música: → Descubrimiento → Tension)_
  - **Cosme:** Por favor, no seas el de mi abuela. ¡Ha funcionado! _[silencio 0.9 s]_
  - **Tú:** ¿Qué pasa?
  - **Cosme:** Alguien ha mordido mi bocadillo. En el pasado. Espera. Fui yo. El martes pasado.
  - **Cosme:** Ya decía yo que aquel día tenía hambre. Toma.
  - **Cosme:** Iba a ser un desintegrador de materia.
  - **Cosme:** Es una pistola de burbujas. _[silencio 0.9 s]_
  - **Cosme:** Técnicamente, son burbujas cuánticas. Creo. Una cosa.
  - **Cosme:** Lo que has visto aquí… _[silencio 0.9 s]_
  - **Cosme:** No se lo cuentes a nadie.
  - ❓ **Pregunta al jugador:** Cosme te mira seriamente. ¿Qué haces?
    - ➤ «Será nuestro secreto.» _(efecto: Cosme +5; marca «secreto cosme» y «grieta vista»)_
      - **Cosme:** Buena criatura. Los secretos son como los tornillos.
      - **Cosme:** Si pierdes uno, todo empieza a temblar. Qué frase tan buena. Me la apunto. _[silencio 0.9 s]_
      - 🎬 **Escena de cámara «Grieta_Rasguno»**
    - ➤ «Se lo voy a contar a mi familia. Todo.» _(efecto: responsabilidad +1; marca «grieta vista»)_
      - **Cosme:** Hazlo. No te creerán. Y eso es precisamente lo que me preocupa.
      - 🎬 **Escena de cámara «Grieta_Rasguno»** _(la misma de antes, ver arriba)_
  - **Cosme:** ¿Dónde has encontrado eso? _[silencio 1.5 s]_
  - **Tú:** Estaba junto a la fuente.
  - **Cosme:** No. Eso no puede estar aquí.
  - **Tú:** Lo tenía desde antes.
  - **Cosme:** ¿Desde cuándo? ¿Antes de conocerme? No lo pierdas. Y, pase lo que pase…
  - **Cosme:** No dejes que nadie te lo quite. No… Vete a casa. Mañana hablamos. Mañana… Hablamos.

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
  - **Pip:** Señor Cosme, considero que el aparato está intentando decirnos algo. _[silencio 0.9 s]_
    - 🎬 **Escena de cámara «Saga_02_G1_Musica»** _(música: → Descubrimiento → Tension)_
  - **Cosme:** ¡Sí! Que funciona.
  - **Pip:** Lleva pitando tres horas.
  - **Cosme:** Entonces funciona muchísimo. ¡Criatura!
  - _(si tienes las marcas «secreto cosme» y «amigo de cosme»)_ **Cosme:** Mi vecino/a favorito/a. Ven.
  - _(si tienes la marca «secreto cosme»)_ **Cosme:** Y cierra eso. La Grieta ha crecido.
  - _(si NO tienes la marca «secreto cosme»)_ **Cosme:** Tenemos que hablar de lo de ayer.
  - _(si NO tienes la marca «secreto cosme»)_ **Cosme:** Pero primero mira esto. _[silencio 0.9 s]_
  - **Cosme:** Mi medidor de rarezas.
  - **Tú:** ¿Qué mide?
  - **Cosme:** Rarezas. Técnicamente, cosas que no deberían existir aquí. Exacto.
  - **Pip:** Señor, el nivel ha aumentado otra vez.
  - **Cosme:** ¿Cuánto?
  - **Pip:** Demasiado.
  - **Cosme:** Esta mañana ha pitado tanto que Pip se ha reiniciado.
  - **Pip:** No me reinicié. Me tomé un descanso técnico.
  - **Cosme:** Se desmayó.
  - **Pip:** Con elegancia.
  - **Cosme:** Esta noche han caído cosas de la Grieta. Tres, como mínimo.
  - **Tú:** ¿Cosas?
  - **Cosme:** Cosas que no son de aquí.
  - **Cosme:** Tenemos que encontrarlas antes que alguien más. _[silencio 0.9 s]_
  - **Pip:** O algo más.
  - ❓ **Pregunta al jugador:** ¿Qué dices?
    - ➤ «¿Qué puede haber ahí fuera?» _(efecto: curiosidad +1)_
      - **Cosme:** Esa es una pregunta excelente.
      - **Cosme:** Y una pregunta peligrosa. _[silencio 0.9 s]_
    - ➤ «Yo voy a buscarlas.» _(efecto: valentia +1)_
      - **Cosme:** ¿Tú? Cada vez te pareces más a mí.
      - **Pip:** Señor, eso no es necesariamente bueno.
      - **Cosme:** Gracias, Pip.
  - **Cosme:** Pip irá contigo.
  - **Pip:** Será un honor. Aunque me gustaría dejar constancia de que nadie me ha preguntado.
  - **Cosme:** Porque sabía lo que ibas a decir.
  - **Pip:** Correcto.
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Grieta_Caen»** _(música: efecto Momento)_
    - _En escena:_ Cosme, Pip, Chispa
    - _Cámara:_ 7 planos
    - 🪧 _Rótulo:_ «☄️ Han caído tres cosas del cielo» — Busca los cráteres humeantes
    - ⏸ _El jugador debe reaccionar:_ «¡Cúbrete!»
    - **Pip:** Señor. …La Grieta está abierta. _[emoción Fear]_
    - **Cosme:** No… Lo estoy viendo. _[emoción Surprise]_
    - _(si reaccionaste a tiempo («cubrirse»))_ **Pip:** Buenos reflejos. Aunque ha caído bastante lejos.
    - _(si NO se cumple: reaccionaste a tiempo («cubrirse»))_ **Pip:** ¡Agáchate! …Bueno. Ya da igual.
    - _Narrador:_ _Tres cosas han caído sobre Valmar: el parque, el patio del cole y el camino al colegio. Y ninguna debería estar aquí._
    - **Chispa:** ¡Bip! ¿Bip? ¡BIIIP! _[emoción Fear]_
    - **Pip:** Tres impactos. Tres objetos.
    - **Cosme:** No. Tres mensajes. Hay que encontrarlos antes que nadie, criatura.
- **Paso 3 · Varios objetivos (en cualquier orden)** — «El medidor pita en tres sitios. Recoge lo que ha caído de la Grieta»
  - _En escena:_ Pip (te acompaña)
  - **Paso 3.1 · Usar** — «Investiga el cráter junto a la fuente.»
    - 🎬 **Escena al completarlo «Grieta_Recoger»**
    - 🖐 _Al usar «Un calcetín que brilla… y habla»:_
      - **Pip:** Lectura dimensional elevada. Y olor a calcetín.
      - **Pip:** Otro universo. Mismo problema. _[silencio 1.8 s]_
      - **Pip:** ¿Sabes cuánto tiempo llevo buscando? Prefiero no saberlo.
  - **Paso 3.2 · Usar** — «Investiga el cráter de la zona de juegos.»
    - 🎬 **Escena al completarlo «Grieta_Recoger»** _(la misma de antes, ver arriba)_
    - 🖐 _Al usar «Un paraguas que llueve hacia arriba»:_
      - **Pip:** Extraordinario. Y ligeramente húmedo.
  - **Paso 3.3 · Usar** — «Investiga el tercer cráter.»
    - 🎬 **Escena al completarlo «Grieta_Recoger»** _(la misma de antes, ver arriba)_
    - 🖐 _Al usar «Una moneda caliente»:_
      - **Tú:** ¿Qué pasa?
      - **Pip:** Esa cara… No debería estar aquí.
      - **Pip:** Llévesela al señor Cosme. Ahora.
- **Paso 4 · Hablar** con Bigotes XVII — «Bigotes te espera en el tejado del cole… bueno, en el patio»
  - _Lugar:_ el patio · _En escena:_ Bigotes XVII
  - **Bigotes XVII:** Has tardado. Los humanos sois lentos.
    - 🎬 **Escena de cámara «Saga_02_G4_Musica»** _(música: → Tension)_
  - _(si tienes la marca «bigotes habla»)_ **Bigotes XVII:** Y deja de fingir que no sabes que hablo.
  - _(si tienes el recuerdo «emperador bigotes»)_ **Bigotes XVII:** Te habla Bigotes XVII. Emperador. Exiliado. Deudor tuyo, por lo de las cucarachas. No te acostumbres.
  - _(si NO tienes la marca «bigotes habla»)_ **Bigotes XVII:** Miau. Bueno. Ya lo sabes.
  - **Bigotes XVII:** La Grieta no es nueva.
  - **Tú:** ¿La habías visto antes?
  - **Bigotes XVII:** Una vez. En Gatonia. Nosotros la llamamos «La Puerta Mal Cerrada».
  - **Tú:** ¿Qué hay al otro lado?
  - **Bigotes XVII:** Problemas. Cucarachas. Cobradores.
  - **Bigotes XVII:** Y gente que vende cosas. Mucha gente. Demasiada. _[silencio 0.9 s]_
  - **Bigotes XVII:** Pero esta vez he oído una voz.
  - **Tú:** ¿De quién?
  - **Bigotes XVII:** De un hombre. Muy elegante. Dijo tu nombre. Varias veces.
  - **Bigotes XVII:** Como quien cuenta monedas. Yo tendría cuidado. _[silencio 0.9 s]_
  - **Bigotes XVII:** Y no se lo digas a nadie.
  - **Bigotes XVII:** Especialmente al inventor. _[silencio 0.9 s]_
- **Paso 5 · Ir a** El garaje de Cosme — «Lleva los objetos al garaje de Cosme.»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip
- **Paso 6 · Escena**
  - **Cosme:** Bueno. Muy raro. PPP — Ojos de Cosme.
  - **Pip:** Señor. ¿Es él?
  - **Cosme:** Sí.
  - **Tú:** ¿Quién es?
  - **Cosme:** Cósimo.
  - **Tú:** ¿Quién es Cósimo? _[silencio 0.9 s]_
  - **Cosme:** Un antiguo socio. Hace mucho tiempo.
  - **Tú:** ¿Y qué tiene que ver con la Grieta?
  - **Cosme:** Demasiado.
  - _Narrador:_ _¿Seguro que quieres abrirla?_
  - **Tú:** ¿Qué habéis hecho?
  - **Cosme:** Un error. Uno muy grande.
  - **Pip:** Señor Cosme…
  - **Cosme:** Todavía no. Tú te la quedas.
  - **Tú:** ¿Por qué?
  - **Cosme:** Porque él ya sabe que existes.
  - **Tú:** ¿Quién? _[silencio 0.9 s]_
  - **Cosme:** Cósimo. Vete a casa.
  - **Tú:** ¿Por qué?
  - **Cosme:** Porque mañana volveremos a hablar. Y esta vez… Te contaré la verdad.
  - **Pip:** Señor. ¿Cree que él nos ha encontrado?
  - **Cosme:** No. Creo que nos encontró hace mucho tiempo. _[silencio 0.9 s]_

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
  - **Don Escamas:** ¡Tú! Sí, tú. La persona que está mirando alrededor como si no hubiera un pez hablando. _[silencio 0.9 s]_
    - 🎬 **Escena de cámara «Saga_03_G1_Musica»** _(música: → Descubrimiento → Tension)_
  - **Don Escamas:** Gracias a Neptuno. Un humano con cara de buena persona.
  - **Tú:** ¿Tú hablas?
  - **Don Escamas:** Normalmente sí. Cuando estoy nervioso/a, hablo más.
  - **Don Escamas:** Y ahora estoy MUY nervioso/a. Don Escamas. Contable. Pez. _[silencio 0.9 s]_
  - **Don Escamas:** Refugiado dimensional. En ese orden. Crucé por la Grieta. _[silencio 0.9 s]_
  - **Tú:** ¿Por qué?
  - **Don Escamas:** Huía. De mi antiguo jefe.
  - **Tú:** ¿Quién?
  - **Don Escamas:** El Consorcio MegaVerso. Sociedad Anónima.
  - **Don Escamas:** Venden viajes entre dimensiones. Vacaciones. Y otras cosas.
  - **Don Escamas:** Cosas que no deberían venderse. _[silencio 0.9 s]_
  - **Don Escamas:** Yo llevaba sus cuentas. Y vi demasiado.
  - **Tú:** ¿Qué viste?
  - **Don Escamas:** Números. Informes. Pedidos.
  - **Don Escamas:** Y algo llamado Proyecto Fusión. Ya están aquí. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Te saco de aquí. Conozco a alguien.» _(efecto: Don Escamas +8; valentia +1; marca «don escamas confia»)_
      - **Don Escamas:** ¡Un humano con contactos!
      - **Don Escamas:** Esto es lo que yo llamo un activo. _[silencio 0.9 s]_
      - **Don Escamas:** ¡Pero un activo con piernas!
    - ➤ «¿Qué viste en las cuentas?» _(efecto: curiosidad +2)_
      - **Don Escamas:** Un pedido enorme. Proyecto Fusión.
      - **Don Escamas:** Firmado por un doctor. No. Aquí no.
      - **Don Escamas:** Las paredes tienen oídos.
      - **Don Escamas:** Y los árboles tienen agentes.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Prepara la huida de Don Escamas.»
  - 🎬 **Escena al completarlo «Saga_03_G3_Entra»**
    - _En escena:_ Agente de MegaVerso, Don Escamas
    - **Agente de MegaVerso:** Buenos días. ¿Podemos revisar ese cubo?
    - **Don Escamas:** No. Quiero decir… ¡Agua!
  - **Paso 2.1 · Usar** — «Consigue algo donde Don Escamas pueda viajar.»
    - 🖐 _Al usar «Un cubo del parque»:_
      - **Don Escamas:** ¿Eso es un cubo? Humillante. Pero funcional. ¡Hop! Mucho mejor.
  - **Paso 2.2 · Usar** — «Busca algo que hayan dejado los agentes.»
    - 🖐 _Al usar «Una tarjeta de visita gris»:_
      - **Don Escamas:** Esa palabra… No me gusta. _[silencio 0.9 s]_
      - **Agente de MegaVerso:** Buenos días. ¿Ha visto usted un pez?
      - **Agente de MegaVerso:** Con corbata. _[silencio 1.8 s]_
      - **Don Escamas:** No respiréis. Ah, no. Tú tienes que respirar. No aceptes. Son muy convincentes. _[silencio 0.9 s]_
- **Paso 3 · Huida** — «Lleva a Don Escamas al garaje de Cosme sin que te atrapen.»
  - _Lugar:_ El garaje de Cosme · _En escena:_ Don Escamas (te acompaña), Agente de MegaVerso
  - 🚨 _Si te atrapan:_ «¡Qué oferta tan irresistible! …Digo: ¡alto! (Te quitan el cubo, se les cae, lo recuperas en el estanque.)»
- **Paso 4 · Escena**
  - _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** ¿Un pez? ¿En mi garaje? ¿Contable?
    - 🎬 **Escena de cámara «Saga_03_G4_Musica»** _(música: → Descubrimiento)_
  - **Cosme:** Siempre he querido un contable. Pip. _[silencio 0.9 s]_
  - **Pip:** Sí, señor.
  - **Cosme:** La pecera buena.
  - **Pip:** ¿La que explota o la que se incendia?
  - **Cosme:** La tercera.
  - **Pip:** No existe una tercera.
  - **Cosme:** Esa.
  - **Pip:** Ah. La nueva.
  - **Don Escamas:** Doctor Cosme.
  - **Cosme:** ¿Nos conocemos?
  - **Don Escamas:** No. Pero su nombre aparece en nuestros archivos. Bueno… El de su socio. El de la perilla.
  - _(si tienes la marca «sabe de cosimo»)_ **Tú:** ¿El de la moneda? ¿Cósimo?
  - _(si tienes la marca «sabe de cosimo»)_ **Cosme:** No sé de qué me habla. Pez.
  - _(si tienes la marca «sabe de cosimo»)_ **Don Escamas:** Ah. Entonces sí es él.
  - _(si tienes la marca «sabe de cosimo»)_ **Cosme:** No.
  - _(si tienes la marca «sabe de cosimo»)_ **Don Escamas:** No he dicho nada.
  - **Don Escamas:** Su socio está en la dimensión 66-B. Cósimo.
  - **Don Escamas:** El Consorcio le paga el laboratorio. _[silencio 0.9 s]_
  - **Don Escamas:** Y están buscando algo aquí. El Ancla.
  - **Tú:** ¿Qué es el Ancla? _[silencio 0.9 s]_
  - **Don Escamas:** Uy. He hablado de más. _[silencio 0.9 s]_
  - **Don Escamas:** Es un tic de contable. Lo cuento todo. Me callo. Me callo muy fuerte. Glu. _[silencio 0.9 s]_
  - **Cosme:** Nadie ha dicho nada de anclas. Ni de barcos. El pez se queda aquí. Tú te vas a casa. Y, criatura…
  - **Cosme:** Si ves a alguien de gris… Corre. Siempre. _[silencio 0.9 s]_
  - **Don Escamas:** Toma. Una escama. Por si algún día necesitas un contable. O un amigo. Soy las dos cosas.
  - **Cosme:** ¿Cuánto sabe?
  - **Pip:** Demasiado para su edad.
  - **Cosme:** Eso me preocupa.
  - **Pip:** ¿Por Cósimo?
  - **Cosme:** Por el Ancla.
  - _Narrador:_ _Solo una palabra: «…Ancla…»_ _[silencio 0.9 s]_

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
  - _Narrador:_ _NPC: «¿Eso ha sido… una campana?» NPC: «Creo que sí.»_ _[silencio 0.9 s]_
    - 🎬 **Escena de cámara «Saga_04_G1_2_Musica»** _(música: → Tension)_
  - _Narrador:_ _Debajo: «Porque cada problema merece otra dimensión.»_
  - **Funcionaria de la ventanilla:** Buenos días. Bienvenido/a al Consorcio MegaVerso.
  - **Tú:** ¿Qué es este sitio?
  - **Funcionaria de la ventanilla:** Una ventanilla. Técnicamente.
  - **Funcionaria de la ventanilla:** Una ventanilla entre dimensiones.
  - **Funcionaria de la ventanilla:** Pero ventanilla al fin y al cabo. _[silencio 0.9 s]_
  - **Funcionaria de la ventanilla:** Necesito que rellene esto.
  - **Tú:** ¿Para qué?
  - **Funcionaria de la ventanilla:** Para saber por qué está aquí.
  - **Tú:** Vivo aquí. _[silencio 0.9 s]_
  - **Funcionaria de la ventanilla:** Interesante. Sujeto cree vivir aquí. Disculpe.
  - **Funcionaria de la ventanilla:** Costumbre profesional. Ah. Cosme. ¿Moneda? ¿66-B?
  - **Funcionaria de la ventanilla:** Esa pregunta no estaba en el formulario. _[silencio 0.9 s]_
- **Paso 3 · Hablar** con Funcionaria de la ventanilla — «Ventanilla 2: el banco (la misma señora… ¿cómo ha llegado antes que tú?)»
  - _Lugar:_ el Banco Valmar
  - **Funcionaria de la ventanilla:** Qué extraño. Esto no debería estar pasando.
    - 🎬 **Escena de cámara «Saga_04_G3_4_5_6_Musica»** _(música: → Tension)_
  - **Funcionaria de la ventanilla:** Esta ventanilla solo aparece cuando alguien solicita asistencia dimensional. _[silencio 0.9 s]_
  - **Tú:** Yo no he solicitado nada.
  - **Funcionaria de la ventanilla:** Eso es lo extraño.
  - _Narrador:_ _«ORIGEN: VALMAR» «PATRÓN: HUMANO»_ _[silencio 0.9 s]_
  - **Tú:** ¿Qué has visto?
  - **Funcionaria de la ventanilla:** Nada.
  - **Tú:** Lo he visto.
  - **Funcionaria de la ventanilla:** Entonces ha visto algo que no era para usted.
  - **Tú:** ¿Por qué la máquina me estaba mirando? _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué dices?
    - ➤ «Dime la verdad.» _(efecto: valentia +1)_
      - **Funcionaria de la ventanilla:** No debería. Pero… La Grieta está siguiendo su posición.
    - ➤ «¿Me estáis buscando?» _(efecto: curiosidad +1)_
      - **Funcionaria de la ventanilla:** No exactamente. Eso sería mucho más sencillo. _[silencio 0.9 s]_
    - ➤ «Quiero irme.» _(efecto: responsabilidad +1)_
      - **Funcionaria de la ventanilla:** Comprensible. Yo también.
      - **Funcionaria de la ventanilla:** Llevo aquí siete años. Desde ayer.
  - **Funcionaria de la ventanilla:** ¡No! ¡No, no, no!
  - _Narrador:_ _«ANCLA: INESTABLE»_ _[silencio 0.9 s]_
  - **Funcionaria de la ventanilla:** No puede ser. Usted no debería estar aquí.
  - **Tú:** Vivo aquí.
  - **Funcionaria de la ventanilla:** Exactamente.
  - **Cosme:** ¡Apágala!
  - **Funcionaria de la ventanilla:** Doctor Cosme.
  - **Cosme:** No me llames doctor.
  - **Funcionaria de la ventanilla:** Disculpe. _[silencio 0.9 s]_
  - **Cosme:** ¿Has tocado algo?
  - **Tú:** No.
  - **Cosme:** ¿Has hablado con él?
  - **Tú:** Sí.
  - **Cosme:** Eso cuenta como tocar algo.
  - **Pip:** Técnicamente no.
  - **Cosme:** Pip.
  - **Pip:** Sí, señor.
  - **Cosme:** ¿Quién te envió?
  - **Funcionaria de la ventanilla:** No puedo revelarlo.
  - **Cosme:** ¿Cósimo?
  - **Funcionaria de la ventanilla:** No he dicho ese nombre. _[silencio 0.9 s]_
  - **Cosme:** Tampoco te lo he preguntado.
  - **Pip:** Creo que eso responde a la pregunta. _[silencio 0.9 s]_
  - _Narrador:_ _«VÍNCULO: DESCONOCIDO»_ _[silencio 0.9 s]_
  - **Cosme:** No lo mires.
  - **Tú:** ¿Por qué?
  - **Cosme:** Porque no quiero que lo recuerdes.
  - **Cosme:** Y sé que eso no tiene ningún sentido. _[silencio 0.9 s]_
  - **Pip:** ¡Bien! Creo. No.
  - **Cosme:** Otra vez no.
  - **Pip:** Señor…
  - **Cosme:** Ya lo sé.
  - **Funcionaria de la ventanilla:** Ese objeto… ¿De dónde lo ha sacado?
  - **Funcionaria de la ventanilla:** Ese no pertenece a 66-B.
  - **Funcionaria de la ventanilla:** Ni a ninguna de las dimensiones registradas. _[silencio 0.9 s]_
  - **Cosme:** Se acabó.
  - **Funcionaria de la ventanilla:** ¡Espere!
  - **Cosme:** No.
  - **Funcionaria de la ventanilla:** ¡No entiende lo que está pasando!
  - **Cosme:** Lo entiendo perfectamente.
  - **Funcionaria de la ventanilla:** Él ya sabe que estás aquí.
  - **Funcionaria de la ventanilla:** Y ahora sabe que tienes el tornillo. _[silencio 0.9 s]_
  - **Tú:** ¿Quién es él?
  - **Cosme:** Cósimo.
  - **Tú:** ¿Qué quiere?
  - **Cosme:** A ti.
  - **Cosme:** O algo que está dentro de ti. No. Olvida eso. _[silencio 1.8 s]_
  - **Pip:** Señor, ya lo ha dicho.
  - **Cosme:** Lo sé.
  - **Cosme:** Qué raro, ha aparecido una ventanilla de otra dimensión. _[silencio 0.9 s]_
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
  - **Ramón:** Treinta años de conserje. Treinta. He visto de todo. _[silencio 0.9 s]_
  - **Ramón:** El gimnasio está lleno de cosas perdidas. Hay un bolso de 1950.
  - **Pip:** Confirmado. ¿Y los devuelve aquí? Donde le parece. _[silencio 0.9 s]_
  - **Ramón:** Cosme ha dicho algo de una… ¿Papelera cósmica?
  - **Pip:** «Fallo de la papelera cósmica».
  - **Pip:** Es la explicación oficial del señor Cosme. Claro. _[silencio 0.9 s]_
  - 🎬 **Escena de cámara «Grieta_Grande»**
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Encuentra en el gimnasio las cosas más importantes y devuélvelas»
  - _En escena:_ Pip (te acompaña)
  - **Paso 2.1 · Usar** — «Unas llaves muy viejas»
    - 🖐 _Al usar «Un manojo de llaves antiguo»:_
      - **Pip:** Parece que alguien ha esperado mucho tiempo para recuperarlas. _[silencio 0.9 s]_
  - **Paso 2.2 · Usar** — «Un balón firmado»
    - 🖐 _Al usar «Un balón firmado»:_
      - _Narrador:_ _Un balón firmado por todo un equipo de fútbol. Con rotulador infantil: «De Nico. NO TOCAR». Es el que perdió en el torneo._
  - **Paso 2.3 · Usar** — «Un diario amarillo»
    - 🖐 _Al usar «Un diario con candado»:_
      - _Narrador:_ _En la portada: «Lucía · 3.º B · 1998»_
      - **Pip:** El objeto pertenece a otra persona. _[silencio 0.9 s]_
      - ❓ **Pregunta al jugador:** ¿Lo abres?
        - ➤ «No. Es de Lucía.» _(efecto: Profe Lucía +3; responsabilidad +1)_
          - **Pip:** Buena decisión.
        - ➤ «Solo la primera página…» _(efecto: curiosidad +1)_
          - _Narrador:_ _Debajo: «Y que no le leeré el diario a nadie.» «Ni a los cotillas.»_ _[silencio 0.9 s]_
          - **Pip:** Curiosidad satisfecha. Privacidad intacta.
- **Paso 3 · Varios objetivos (en cualquier orden)** — «Devuelve cada cosa a su dueño»
  - _Lugar:_ el patio · _En escena:_ Ramón, Nico, Profe Lucía
  - 🎬 **Escena al completarlo «Saga_05_G4_Entra»**
    - _En escena:_ Pip
    - **Pip:** Identificación. No disponible.
    - **Pip:** Solo queda un calcetín. Sin pareja. Monstruo emparejado. Bueno.
    - **Pip:** Pero estará orgulloso.
  - **Paso 3.1 · Hablar** con Ramón — «Las llaves, a Ramón»
    - **Ramón:** Mis llaves. O que alguien las había encontrado. No funciona. _[silencio 0.9 s]_
    - **Ramón:** Con estas se abre la sala del reloj.
    - **Ramón:** Nadie entra ahí desde entonces. Otro día te cuento. O no.
  - **Paso 3.2 · Hablar** con Nico — «El balón, a Nico»
    - **Nico:** ¡MI BALÓN! ¡El del torneo!
    - **Nico:** ¡Lo busqué por todas partes! ¿Dónde estaba? ¿En el gimnasio? ¿En el cielo? Vale. No voy a preguntar.
    - **Nico:** Bueno… sí voy a preguntar.
    - **Pip:** Recuperación completada.
    - **Nico:** Ese robot me cae bien.
  - **Paso 3.3 · Hablar** con Profe Lucía — «El diario, a Lucía»
    - **Profe Lucía:** Mi diario. De cuando tenía tu edad.
    - **Profe Lucía:** Lo perdí durante una excursión. ¿Lo has leído? No contestes. No está enfadada. Gracias. _[silencio 0.9 s]_
    - **Profe Lucía:** Hay cosas que perdemos… _[silencio 0.9 s]_
    - **Ramón:** Eso no lo hacía antes. _[silencio 0.9 s]_
    - **Pip:** Detecto movimiento. Mucho movimiento.
- **Paso 4 · Pelea** — «¡Del montón sale el Monstruo de los Calcetines Desparejados! Empareja sus calcetines»
  - _Lugar:_ Gimnasio · _En escena:_ Pip
  - 🚨 _Si te atrapan:_ «¡ABRAZO DE CALCETÍN! (Hueles a pie durante una semana. Vuelves a la entrada.)»
- **Paso 5 · Escena**
  - **Pip:** Hay un problema. Esta vez lo ha visto todo el barrio. Los vecinos.
  - **Pip:** El señor Cosme dice que hay que coserla. Ya. No llega a abrirse. Pero pulsa. _[silencio 1.8 s]_
  - _Narrador:_ _No parece peligroso._ _[silencio 0.9 s]_
  - _Narrador:_ _Pero después de esta noche ya no estás seguro/a de qué cosas pueden ser normales._ _[silencio 0.9 s]_

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
  - **Cosme:** Mi obra maestra. Bueno.
  - **Cosme:** La segunda fue un peine que peina hacia el pasado. No preguntes.
  - **Pip:** Funcionaba demasiado bien.
  - **Cosme:** Tres anclajes. Y esto…
  - **Tú:** ¿Como un botón?
  - **Cosme:** Exacto.
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** El Consorcio ya sabe lo que vas a hacer.
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** Tienen agentes vigilando el parque y la plaza.
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** He calculado sus rutas. _[silencio 0.9 s]_
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** Si no te ven, no te ven.
  - _(si tienes la marca «conoce consorcio»)_ **Don Escamas:** Es contabilidad básica. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** Antes de salir, le preguntas a Cosme:
    - ➤ «¿Quién es Cósimo de verdad?» _(efecto: curiosidad +1)_
      - **Cosme:** Mi mejor amigo. Construimos juntos la máquina que abrió esto.
      - **Cosme:** Y él cayó al otro lado. Por mi culpa. O por la suya. _[silencio 0.9 s]_
      - **Cosme:** Llevo años sin saberlo.
    - ➤ «¿Por qué la Grieta tira hacia mí?» _(efecto: valentia +1)_
      - **Cosme:** Porque eres importante. Para mí, desde luego. Para el universo… Un poquito también.
      - _(si tienes la marca «oyo ancla»)_ **Cosme:** Y no le hagas demasiado caso al pez cuando habla de anclas.
      - _(si tienes la marca «oyo ancla»)_ **Don Escamas:** ¡Soy un profesional!
      - _(si tienes la marca «oyo ancla»)_ **Cosme:** Eres un pez.
  - **Cosme:** Esta noche cerramos la Grieta.
  - **Cosme:** Y esta vez no voy a dejar que nadie salga herido. Ni tú.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «colocar los tres anclajes en Valmar.»
  - _Lugar:_ el parque · _En escena:_ Agente de MegaVerso
  - 🎬 **Escena al completarlo «Saga_06_G3_Entra»**
    - _En escena:_ Cosme, Pip
    - **Cosme:** Solo falta activarla.
    - **Pip:** Tenemos compañía. Dos agentes aparecen.
    - **Pip:** No quieren detenernos.
    - **Pip:** Quieren informar de nuestra posición.
    - **Pip:** Control rutinario. Gracias por colaborar.
    - **Tú:** No.
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
    - **Pip:** Puntada. Otra. Puntada… Mis sensores están llorando aceite.
    - **Cosme:** …Se ha cerrado. Lo hemos conseguido. _[a Pip · emoción Surprise]_
    - 🔀 **Variante «Barrio»** (si tienes la marca «vecinos notan rarezas»): cambia Dialogue por:
      - **Cosme:** Tres anclajes. Una aguja. Un cielo entero. _[plano Medio de Cosme · emoción Nervous]_
      - **Cosme:** …Allá vamos.
      - **Pip:** Medio barrio está en la ventana. Ramón, con sus llaves de 1994.
      - **Cosme:** …Se ha cerrado. Lo hemos conseguido. _[a Pip · emoción Surprise]_
- **Paso 5 · Escena**
  - **Cosme:** ¡LO HEMOS HECHO! ¡Cosido! ¡Como un calcetín!
  - **Pip:** Comparación técnicamente incorrecta.
  - **Cosme:** ¡Somos unos genios! Tú eres un genio en miniatura. Yo soy uno grande.
  - **Pip:** Señor Cosme… Tenemos una transmisión.
  - **Doctor Cósimo:** Bravo, Cosme. Precioso trabajo de costura. _[silencio 0.9 s]_
  - **Doctor Cósimo:** Siempre fuiste el de las manualidades. Y tú… Hola. _[silencio 0.9 s]_
  - **Doctor Cósimo:** Por fin puedo verte la cara. Qué grande estás.
  - **Doctor Cósimo:** La última vez eras así de pequeño/a. Ya te he encontrado. _[silencio 0.9 s]_
  - **Doctor Cósimo:** El tornillo luminoso también. Tres objetos. Nos veremos pronto. Las costuras… …siempre se sueltan. _[silencio 0.9 s]_
  - **Cosme:** Está completamente pálido.
  - **Pip:** Señor.
  - **Cosme:** Algún día, Pip. No hoy. _[silencio 0.9 s]_
  - **Cosme:** Hoy hemos cosido el cielo. Hoy… …a cenar. Te la quedas.
  - **Cosme:** Tú la has hecho funcionar. Siempre has sido tú. _[silencio 0.9 s]_

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
  - **Mamá/Papá:** ¡[tu nombre]! ¡Primer día de instituto! ¿Libros?
  - **Abu:** Lo único que falta es respirar. _[silencio 0.9 s]_
  - **Mamá/Papá:** Eso también.
  - **Tú:** Acompáñame hasta la puerta, porfa.
  - **Mamá/Papá:** Claro. Hasta la puerta. Ni un paso más. Bueno… Hasta la esquina.
  - **Tú:** Puedo ir por mi cuenta. Pero gracias.
  - **Mamá/Papá:** Vale. Qué rápido pasa todo.
  - **Mamá/Papá:** Ayer la mochila era más grande que tú.
  - **Abu:** El personaje se gira. El primer día, sonríe a alguien que no conozcas. Solo a una persona. Ya verás.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Acompáñame hasta la puerta, porfa» _(efecto: Mamá/Papá +4; decisión «primer dia ins» = Acompanado)_
      - **Mamá/Papá:** ¡Hasta la puerta de casa! Ni un paso más, prometido. …Bueno, hasta la esquina.
    - ➤ «Puedo ir por mi cuenta. Pero gracias.» _(efecto: valentia +1; decisión «primer dia ins» = Solo)_
      - **Mamá/Papá:** Vale, vale. Qué rápido pasa todo. Ayer tenías la mochila más grande que tú.
  - 🎬 **Escena al completarlo «Ins01_G3_Entra»**
    - _En escena:_ Mateo, Hugo
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Me he apuntado el aula.
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** He traído esto por si nadie me habla.
- **Paso 3 · Ir a** la parada del autobús — «Ve a la parada del autobús: tus amigos te esperan»
  - _Lugar:_ la parada del autobús · _En escena:_ Nico, Omar, Sara, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
  - ⏰ _Si tardas, Omar dice:_ «(mensaje) ¿Dónde estás? El bus pasa en nada. Te guardo sitio. Y medio cruasán.»
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Ins01_Parada»** _(música: intensidad Nada)_
    - _En escena:_ Nico, Omar, Sara, Mateo, Hugo
    - _Cámara:_ 2 planos (General, Pan)
    - **Sara:** Omar. ¿Has crecido? ¿O te has subido a algo? _[a Omar · plano Hombro de Sara → Omar]_
    - **Omar:** Me he chocado dos veces con el marco de la puerta. Mi madre dice que es la edad. _[plano Medio de Omar · gesto Shrug]_
    - _(si tienes la marca «llegas tarde parada»)_ **Nico:** ¡[tu nombre]! ¡Por fin! El conductor no espera a nadie. _[plano PrimerPlano de Nico]_
    - _(si NO se cumple: tienes la marca «llegas tarde parada»)_ _(o bien)_ **Nico:** ¡[tu nombre]! Antes que el autobús. Eso es de cuarto, como mínimo. _[plano PrimerPlano de Nico · gesto Happy]_
    - **Sara:** Me han puesto en el bilingüe. No vamos a estar en la misma clase. Lo he comprobado tres veces. _[plano PrimerPlano de Sara · gesto Sad · en la pausa: Suelo]_
    - _(si en «promesa» elegiste «Juntos»)_ **Nico:** Pero en el recreo sí. ¡Lo prometimos! _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «promesa» elegiste «Nuevos»)_ _(o bien)_ **Nico:** Lo prometimos: conocer gente nueva sin olvidarnos. _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «promesa» elegiste «Banco»)_ _(o bien)_ **Nico:** Lo prometimos. Y el banco del parque sigue en pie. _[a Sara · plano PrimerPlano de Nico · en la pausa: Mirar]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Omar:** Los Imparables: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Omar:** La Patrulla Valmar: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Omar:** Los del Banco Azul: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Omar:** Los Dinosaurios: eso no lo separa ningún horario. _[plano DosPlanos de Omar → Sara · gesto Nod]_
    - _(si tienes la marca «hugo con el grupo»)_ **Hugo:** He traído un libro por si nadie me habla. Pero prefiero que habléis vosotros. _[plano Reaccion de Hugo]_
    - _(si tienes la marca «ayudaste a mateo» y NO tienes la marca «hugo con el grupo»)_ _(o bien)_ **Mateo:** Creo que estoy en primero C. Creo. …Ya no estoy seguro. _[plano Reaccion de Mateo · gesto Nervous]_
    - _(si NO tienes las marcas «hugo con el grupo» y «ayudaste a mateo»)_ _(o bien)_ **Sara:** Si alguien se pierde, tengo el plano del instituto. Impreso. Plastificado. _[plano Medio de Sara]_
    - **Omar:** ¡Ese es! El grande. Este tiene cara de importante. _[plano Medio de Omar · en la pausa: Senalar]_
    - **Nico:** Todos son grandes. ¡El último en subir se sienta al lado del conductor! _[plano General · gesto Happy]_
- **Paso 5 · Acción del jugador** — «Coge el autobús al Campus Valmar»
- **Paso 6 · Ir a** el instituto — «Busca la entrada del instituto»
  - _Lugar:_ el instituto · _En escena:_ Alumno de 4.º, Delegada de 4.º, Iker (si tienes la marca «iker en el grupo»), Omar (te acompaña), Alumno, Alumna
- **Paso 7 · Escena**
  - **Alumno de 4.º:** ¿Los de primero? Aunque…
  - **Alumno de 4.º:** También podéis coger el ascensor de alumnos.
  - **Omar:** ¿Hay ascensor de alumnos?
  - 🎬 **Escena al completarlo «Ins01_G8_Entra»**
    - _En escena:_ Alumno de 4.º, Omar
    - **Omar:** Esto no parece un ascensor.
    - **Alumno de 4.º:** ¡Todos los años alguien cae! Tranquilos.
    - **Alumno de 4.º:** A mí me lo hicieron también. Primero C está abajo.
    - **Omar:** Esto lo cuento en la cena.
- **Paso 8 · Decisión** — «¿Le haces caso al veterano (el «ascensor de alumnos») o buscas por tu cuenta?»
  - ➤ **Opción «Esperar el ascensor»** _(efecto: decisión «veterano» = Creer; humor +1)_
    - _Narrador:_ _Esperas delante de una puerta que pone «CUARTO DE LIMPIEZA». Pasa un minuto. Detrás, se oyen risas._
    - **Alumno de 4.º:** ¡Todos los años alguien cae! Tranqui, a mí me lo hicieron también. El aula de 1.º C está en la planta baja, al fondo.
    - **Omar:** Esto lo cuento en la cena y me río. Dentro de unos años.
    - 🖐 _Al usar ««Ascensor de alumnos»»:__(la misma conversación «Ascensor» de arriba)_
  - ➤ **Opción «Preguntar a la delegada»** (con Delegada de 4.º) _(efecto: decisión «veterano» = Dudar; curiosidad +1)_
    - **Delegada de 4.º:** ¿El ascensor de alumnos? No existe. Primero C está abajo.
    - **Delegada de 4.º:** Y si necesitáis algo, buscadme.
- **Paso 9 · Usar** — «Busca tu clase en el tablón»
  - 🖐 _Al usar «Tablón de clases»:_
    - _Narrador:_ _1.º A._
    - **Omar:** ¿Bruno? Esto ya es el destino. _[silencio 0.9 s]_
    - _(si tienes la marca «iker en el grupo»)_ **Iker:** También estoy en primero C.
- **Paso 10 · Ir a** tu aula del instituto — «Ve al aula de 1.º C»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Nico, Leire, Bruno, Iker (si tienes la marca «iker en el grupo»), Alumno, Alumna
- **Paso 11 · Escena**
  - **Javier:** Buenos días, 1.º C. Soy Javier. Os daré Historia.
  - **Javier:** Y alguna charla que no me habéis pedido. Algunos alumnos ríen.
  - **Javier:** Aquí nadie os va a llevar de la mano. Pero si os perdéis…
  - **Javier:** Preguntar no es de pequeños. Es de listos.
  - **Javier:** Tenemos una alumna nueva. ¿Quieres decir algo?
  - **Leire:** No. _[silencio 0.9 s]_
  - **Javier:** Me gusta. _[silencio 1.8 s]_
  - _(si en «adios bruno» elegiste «DeCero»)_ **Bruno:** Eh. Aquí hay sitio. Si quieres. De cero, ¿no?
- **Paso 12 · Decisión** — «¿Dónde te sientas? (habla con quien elijas)»
  - 🎬 **Escena al completarlo «Ins01_G13_Entra»**
    - _En escena:_ Javier
    - **Javier:** [Nombre]. ¿Estás conmigo? Bien.
    - **Javier:** No afecta al resultado académico.
  - ➤ **Opción «Con Omar, como siempre»** (con Omar) _(efecto: decisión «sitio instituto» = Omar; Omar +5)_
    - **Omar:** Lo sabía. Te he guardado el sitio desde las ocho menos cuarto. Sabía que vendrías.
  - ➤ **Opción «Con la chica nueva»** (con Leire) _(efecto: decisión «sitio instituto» = Leire; Leire +8; empatia +1)_
    - **Leire:** Vale. Es de mi abuelo. Es de carrete. Bueno. Ya te lo he contado. Qué rabia.
  - ➤ _(si en «adios bruno» elegiste «DeCero»)_ **Opción «Con Bruno (¿empezar de cero?)»** (con Bruno) _(efecto: decisión «sitio instituto» = Bruno; Bruno +8)_
    - **Bruno:** ¿En serio? Vale. Normas.
    - **Bruno:** No me copies en los exámenes. Y yo tampoco a ti. Eso lo añado ahora. Oye.
    - **Bruno:** Yo tampoco conozco a nadie aquí. _[silencio 0.9 s]_
    - **Bruno:** Está bien tener a alguien conocido.
- **Paso 13 · Clase** — «Clase de Historia con Javier»
- **Paso 14 · Ir a** el patio — «Sal al recreo»
  - _Lugar:_ el patio · _En escena:_ Omar, Sara, Nico, Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»), Leire, Alumno de 4.º, Alumna, Alumno
  - 💬 _Comentario al pasar cerca de Nico:_ «¡Pásala! ¡Aquí!»
- **Paso 15 · Escena**
  - **Sara:** ¡Os he encontrado! En mi clase hablan de cosas rarísimas.
  - **Sara:** Yo quería hablar de hongos. _[silencio 0.9 s]_
  - **Nico:** ¡Eh!
  - **Omar:** Está bien. ¿No? _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Esto es nuestro rincón desde hoy.» Te sientas con Omar y Sara _(efecto: Omar +3; Sara +3; decisión «recreo ins» = Rincon)_
      - **Sara:** Declaramos este banco territorio del grupo. Con sus derechos y sus bocadillos.
    - ➤ «Vas a jugar con Nico y los de segundo» _(efecto: Nico +5; deportividad +1; decisión «recreo ins» = Nico)_
      - **Nico:** ¡[tu nombre]! ¡Menos mal! Estos de segundo son buenos, pero no se saben nuestras jugadas.
    - ➤ «Das una vuelta para conocer el instituto» _(efecto: curiosidad +1; decisión «recreo ins» = Explorar)_
      - _(si NO tienes la marca «conoces a leire»)_ _Narrador:_ _Laboratorios, un gimnasio con gradas, una biblioteca con sillones… y, en un banco apartado, Leire comiendo sola._
      - _(si tienes la marca «conoces a leire»)_ _Narrador:_ _Laboratorios, un gimnasio con gradas, una biblioteca con sillones. Leire te saluda desde lejos con la cámara._
- **Paso 16 · Hablar** con Leire — «Leire come sola en un banco. ¿Vas?» _(solo si NO tienes la marca «conoces a leire»)_
  - **Leire:** ¿Qué? Estoy bien sola. Vale. No mucho.
  - **Leire:** En mi otra ciudad tenía un grupo.
  - **Leire:** El bocadillo es buena compañía. Pero no habla. _[silencio 0.9 s]_
  - **Omar:** ¡Es verdad! ¡Traigo de todo! ¡Hasta aceitunas! _[silencio 0.9 s]_
  - **Leire:** Vale. Pero si son pesados, me vuelvo al banco. ¿Las fotos?
  - **Leire:** Nadie me pregunta por las fotos. _[silencio 0.9 s]_
  - **Leire:** Esta es mi antigua calle. Otra. Y esta… Es el mar.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Vente con nosotros. Omar trae comida para todos.» _(efecto: Leire +10; Omar +2; empatia +2; marca «conoces a leire»)_
      - **Omar:** (desde lejos) ¡Es verdad! ¡Traigo de todo! ¡Hasta aceitunas!
      - **Leire:** …Vale. Pero si son pesados, me vuelvo al banco.
    - ➤ «¿Me enseñas qué fotos haces?» _(efecto: Leire +8; curiosidad +1; marca «conoces a leire»)_
      - **Leire:** Nadie me pregunta por las fotos. Solo por la cámara. …Mira. Esta es mi antigua calle. Y esta, el mar.
  - 🎬 **Escena al completarlo «Ins01_G17_Entra»**
    - _En escena:_ Javier
    - **Javier:** No busquéis solamente el resultado.
    - **Javier:** Quiero saber cómo habéis llegado hasta él.
- **Paso 17 · Clase** — «Clase de Matemáticas»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Nico, Leire, Bruno, Iker (si tienes la marca «iker en el grupo»), Alumno, Alumna
- **Paso 18 · Transición (pasa el tiempo)** — «Por la tarde…»
  - ⏳ _Pantalla de transición:_ «Por la tarde…»
- **Paso 19 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - **Mamá/Papá:** ¡Cuéntalo todo! ¿Cómo es? Otra. ¿Es grande? Otra. ¿Te has perdido? Otra. ¿Has comido?
  - **Mamá/Papá:** ¡Eso es lo importante! _[silencio 0.9 s]_
  - _(si en «veterano» elegiste «Creer»)_ **Mamá/Papá:** ¿El ascensor de alumnos?
  - _(si en «veterano» elegiste «Creer»)_ **Mamá/Papá:** ¡A mí también me lo hicieron!
  - _(si en «veterano» elegiste «Creer»)_ **Mamá/Papá:** Hay cosas que no cambian nunca.
  - _(si en «veterano» elegiste «Creer»)_ **Abu:** Y algunas bromas duran más que las personas.
  - _(si tienes la marca «conoces a leire»)_ **Mamá/Papá:** ¿Una compañera nueva? ¿Leire?
  - _(si tienes la marca «conoces a leire»)_ **Mamá/Papá:** Qué bien que te hayas acercado.
  - _(si tienes la marca «conoces a leire»)_ **Mamá/Papá:** Empezar en una ciudad nueva es difícil. _[silencio 0.9 s]_
  - **Abu:** Y dime… ¿A quién le sonreíste? Ah.
  - **Abu:** La coloca junto a un libro nuevo del instituto. _[silencio 0.9 s]_
  - _Narrador:_ _El instituto da un poco de miedo._
  - _Narrador:_ _Pero también parece divertido._ _[silencio 0.9 s]_

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
  - 🎬 **Escena al completarlo «Ins02_G1_Fin»**
    - _En escena:_ Omar
    - **Omar:** Ya sabes moverte por aquí.
    - **Omar:** Eso es oficialmente preocupante.
- **Paso 2 · Ir a** el patio — «Ve al patio: hoy es la feria de clubes»
  - _Lugar:_ el patio · _En escena:_ Javier, Álex, Rubén, Sara, Hugo, Leire, Omar (te acompaña), Alumno
- **Paso 3 · Escena**
  - **Javier:** Uno por persona. Que luego no dormís. Algunos alumnos ríen.
  - **Javier:** Elegid algo que os guste.
  - **Javier:** No lo que elijan vuestros amigos. _[silencio 0.9 s]_
  - **Omar:** Yo me apunto al suyo.
  - **Javier:** ¿Al mío?
  - **Omar:** A cualquiera que elija él.
  - **Javier:** Eso no era exactamente el mensaje.
  - **Omar:** Lo he entendido a mi manera.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Visita los puestos (al menos tres)»
  - **Paso 4.1 · Usar** — «Baloncesto»
    - 🖐 _Al usar «Puesto de baloncesto»:_
      - **Álex:** ¡[tu nombre]! Soy la capitana del equipo de primero.
      - **Álex:** Hacemos pruebas el martes. Sin favoritismos. Bueno… Un poco. Nada mal. Tenemos trabajo. _[silencio 0.9 s]_
  - **Paso 4.2 · Usar** — «Teatro»
    - 🖐 _Al usar «Puesto de teatro»:_
      - **Rubén:** ¿Teatro? Aquí se viene a hacer el ridículo. Con estilo.
      - **Rubén:** Yo empecé para no esconderme más.
      - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Y… Me alegro de verte. _[silencio 0.9 s]_
      - _(si tienes la marca «ruben perdonado»)_ **Rubén:** Lo de la mochila fue hace mil años.
  - **Paso 4.3 · Usar** — «Robótica»
    - 🖐 _Al usar «Puesto de robótica»:_
      - **Sara:** Construimos cosas que hacen cosas. Bueno…
      - **Sara:** Que intentan hacer cosas. Tornillo pita.
      - **Sara:** Este año queremos hacer uno que reparta bocadillos.
      - **Omar:** ¿Bocadillos?
      - **Sara:** Sí.
      - **Omar:** Me apunto mentalmente.
  - **Paso 4.4 · Usar** — «Periódico»
    - 🖐 _Al usar «Puesto del periódico»:_
      - **Hugo:** El periódico se llama «La Voz del Campus». Somos tres.
      - **Hugo:** Buscamos gente que haga preguntas incómodas. Mi primer reportaje…
      - **Hugo:** Alguien pinta murales por la noche. Nadie sabe quién.
      - **Hugo:** Eso sí es un misterio.
  - **Paso 4.5 · Usar** — «Fotografía»
    - 🖐 _Al usar «Puesto de fotografía»:_
      - **Leire:** El club soy yo. _[silencio 0.9 s]_
      - **Omar:** ¿Solo tú?
      - **Leire:** Y mi tío Toni. No es un club muy grande.
      - **Leire:** Pero salimos por el campus. _[silencio 0.9 s]_
- **Paso 5 · Decisión** — «¿A qué club te apuntas? (habla con quien lo lleva)»
  - 🎬 **Escena al completarlo «Ins02_G5_Eleccion»**
    - _En escena:_ Álex, Rubén, Sara, Hugo, Leire
    - _(si en «club» elegiste «Baloncesto»)_ **Álex:** ¡Bien! El martes, prueba. Zapatillas. Y ganas.
    - _(si en «club» elegiste «Robotica»)_ **Sara:** ¡Sí! Tú, yo y un robot.
    - _(si en «club» elegiste «Teatro»)_ **Rubén:** ¿De verdad? Audición mañana. Y luego entra igual.
    - _(si en «club» elegiste «Periodico»)_ **Hugo:** ¡Genial! Tu primer caso: los murales. Y paciencia.
    - _(si en «club» elegiste «Fotografia»)_ **Leire:** ¿En serio? Vale. Ya somos dos.
    - _(si en «club» elegiste «Robotica»)_ **Sara:** Como en los viejos tiempos. Pero con cables.
    - _(si en «club» elegiste «Fotografia»)_ **Leire:** Esto ya parece un club. Casi.
    - _(si en «club» elegiste «Baloncesto»)_ **Álex:** Las zapatillas son opcionales. Las ganas no.
    - _(si en «club» elegiste «Periodico»)_ **Hugo:** Los buenos reportajes son lentos.
    - **Álex:** Ven.
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
  - **Álex:** Tiros desde la línea. Ocho balones.
  - **Álex:** Con cuatro, entras de titular. Con menos… Entras igual.
  - **Omar:** ¡Plan B!
  - **Álex:** Calientas banquillo.
  - **Omar:** Ah. Plan C.
  - 🎬 **Escena al completarlo «Ins02_G8_Entra»**
    - _En escena:_ Álex
    - **Álex:** Equipo de primero. No pasa nada.
    - **Álex:** Mejorar también cuenta.
- **Paso 8 · Minijuego** — «Prueba: tiros desde la línea» _(solo si en «club» elegiste «Baloncesto»)_
  - 🎮 _Cómo se juega:_ Cada tiro, más difícil. Necesitas 4.
- **Paso 9 · Ir a** tu aula del instituto — «Ve a tu aula: hoy es la audición de teatro» _(solo si en «club» elegiste «Teatro»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Rubén (si en «club» elegiste «Teatro»), Omar (si en «club» elegiste «Teatro») (te acompaña)
- **Paso 10 · Escena** _(solo si en «club» elegiste «Teatro»)_
  - **Rubén:** Treinta segundos. Es un pirata que ha perdido su barco. Dramático. Pero no demasiado. ¿Nervios?
  - **Rubén:** A mí el primer día me temblaban hasta las cejas.
  - 🎬 **Escena al completarlo «Ins02_G11_Entra»**
    - _En escena:_ Rubén
    - _(si tienes la marca «ins 02 p 11 gana»)_ **Rubén:** ¡Eso! Has actuado como si te importara.
    - **Rubén:** Perfecto. Ahora sabemos qué tenemos que practicar.
- **Paso 11 · Minijuego** — «Audición: di el texto con ritmo» _(solo si en «club» elegiste «Teatro»)_
  - 🎮 _Cómo se juega:_ Habla en la zona verde
- **Paso 12 · Ir a** tu aula del instituto — «Ve al laboratorio de robótica (aula)» _(solo si en «club» elegiste «Robotica»)_
  - _En escena:_ Sara (si en «club» elegiste «Robotica»), Omar (si en «club» elegiste «Robotica») (te acompaña)
- **Paso 13 · Escena** _(solo si en «club» elegiste «Robotica»)_
  - **Sara:** Este es Tornillo. Dos ruedas.
  - **Sara:** Y mala suerte. _[silencio 1.8 s]_
  - **Omar:** Me cae bien.
  - **Sara:** Tú introduces las órdenes.
  - **Sara:** Yo controlo el sensor. Omar mira…
  - **Omar:** Bocadillos.
  - **Sara:** Eso.
- **Paso 14 · Minijuego** — «Programa al robot» _(solo si en «club» elegiste «Robotica»)_
  - 🎮 _Cómo se juega:_ Mete cada orden en la zona verde
- **Paso 15 · Usar** — «¡El robot se ha escapado! Atrápalo» _(solo si en «club» elegiste «Robotica»)_
  - _En escena:_ Sara (te acompaña)
  - 🖐 _Al usar «¡El robot!»:_
    - **Sara:** ¡NO! Tornillo sale disparado.
    - **Sara:** ¡Le he puesto la velocidad máxima! Sin querer. Creo.
- **Paso 16 · Usar** — «¡Se ha ido al patio!» _(solo si en «club» elegiste «Robotica»)_
  - 🖐 _Al usar «¡El robot!»:_
    - **Omar:** ¡Va rápido!
    - **Sara:** ¡Eso ya lo sé!
- **Paso 17 · Usar** — «¡Ahora va hacia la pista!» _(solo si en «club» elegiste «Robotica»)_
  - 🖐 _Al usar «¡El robot!»:_
    - **Sara:** ¿Está bien? Tornillo pita. Está bien. Creo.
- **Paso 18 · Escena** _(solo si en «club» elegiste «Periodico»)_
  - _Lugar:_ el patio · _En escena:_ Hugo (si en «club» elegiste «Periodico»), Omar (si en «club» elegiste «Periodico») (te acompaña)
  - **Hugo:** Cada lunes aparece uno nuevo. Pájaros. Otra. Frases. Otra. Colores.
  - **Hugo:** El director está entre enfadado… …y encantado.
- **Paso 19 · Varios objetivos (en cualquier orden)** — «Investiga quién pinta los murales por la noche» _(solo si en «club» elegiste «Periodico»)_
  - _En escena:_ Hugo (si en «club» elegiste «Periodico») (te acompaña), Alumno de 4.º (si en «club» elegiste «Periodico»), Delegada de 4.º (si en «club» elegiste «Periodico»)
  - **Paso 19.1 · Usar** — «Examina el mural nuevo»
    - 🖐 _Al usar «Un mural nuevo»:_
      - _Narrador:_ _Debajo: «Aquí también se puede volar.»_
      - **Hugo:** Esto reduce bastante la lista de sospechosos. _[silencio 0.9 s]_
      - _(si tienes la marca «el recuerdo de vega decorando»)_ **Hugo:** Tú conoces a alguien.
  - **Paso 19.2 · Hablar** con Alumno de 4.º — «Pregunta al veterano»
    - **Alumno de 4.º:** Vi a alguien el viernes. Botes de pintura.
  - **Paso 19.3 · Hablar** con Delegada de 4.º — «Pregunta a la delegada»
    - **Delegada de 4.º:** La llave del gimnasio la tienen los clubes.
    - **Delegada de 4.º:** El club de arte usa el patio los viernes. _[silencio 0.9 s]_
    - **Delegada de 4.º:** Y solo una persona se queda hasta tarde. _[silencio 0.9 s]_
    - **Hugo:** Tenemos una pista.
- **Paso 20 · Hablar** con Vega — «Todas las pistas llevan a… Vega» _(solo si en «club» elegiste «Periodico»)_
  - _En escena:_ Hugo (te acompaña), Vega
  - **Vega:** Vale. Soy yo. Lo hago porque el patio era gris. _[silencio 0.9 s]_
  - **Vega:** Y porque nadie me ha pedido permiso para ser gris. _[silencio 0.9 s]_
  - **Vega:** Pero no estaba haciendo daño a nadie. ¿Vais a publicarlo? ¿Anónimo?
  - **Hugo:** Lo he leído. Ahora lo entiendo. _[silencio 0.9 s]_
  - **Vega:** ¿Y si dice que no? Vale. Si me acompañáis.
  - **Hugo:** El reportaje será mejor.
  - **Hugo:** «Una alumna pinta el instituto».
  - **Vega:** Ah. Vale. Gracias.
  - **Hugo:** No sé si hemos hecho bien. _[silencio 0.9 s]_
  - **Hugo:** A veces la verdad puede hacer daño a alguien que no estaba haciendo daño. _[silencio 0.9 s]_
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
  - **Leire:** No hacemos fotos de nosotros.
  - **Leire:** Hacemos fotos de lo que vemos. _[silencio 0.9 s]_
  - **Leire:** Mi abuelo decía que así se aprende a mirar. Vamos.
- **Paso 22 · Varios objetivos (en cualquier orden)** — «Paseo fotográfico por el campus» _(solo si en «club» elegiste «Fotografia»)_
  - _En escena:_ Leire (te acompaña)
  - **Paso 22.1 · Usar** — «La universidad»
    - 🖐 _Al usar «La universidad»:_
      - **Leire:** Mi madre estudió aquí. Y los más cansados.
  - **Paso 22.2 · Usar** — «La biblioteca del campus»
    - 🖐 _Al usar «La biblioteca del campus»:_
      - **Leire:** Esa foto se queda.
  - **Paso 22.3 · Usar** — «El estadio»
    - 🖐 _Al usar «El estadio»:_
      - **Leire:** Esa es buena. Muy buena.
      - **Leire:** No se lo digas a nadie.
      - **Leire:** Eres mejor encuadrando que yo.
- **Paso 23 · Escena**
  - _En escena:_ Omar, Nico
  - **Nico:** ¡[tu nombre]! El sábado cumplo trece. Bueno. Tres y diez.
  - **Omar:** Trece.
  - **Nico:** Eso. Cinco. Y mi abuela hace croquetas.
  - **Omar:** El sábado a las cinco tienes también tu primer evento del club.
  - **Nico:** Ah. Eso complica las cosas. _[silencio 0.9 s]_
  - **Tú:** El club. Es mi primer compromiso de verdad.
  - **Nico:** Ah. Vale. Otra. Te guardo croquetas. Pocas. ¡SÍ! Ya sabía yo.
  - **Nico:** Te voy a dar la croqueta más grande. _[silencio 0.9 s]_
  - **Omar:** Ambicioso. Me gusta. Te dejo mi bono de autobús. Por si acaso. _[silencio 0.9 s]_
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
  - **Álex:** ¡Vamos! Bueno. ¡Mi barco! ¡Mi precioso barco!
  - **Rubén:** ¡Eso! Lo has vendido.
  - **Sara:** Solo uno. Pero uno. _[silencio 0.9 s]_
  - **Hugo:** Hay gente leyéndolo. La observa durante más de un minuto.
  - **Leire:** Eso es bueno. Cuando alguien se queda mirando.
  - **Omar:** Tenemos quince minutos.
- **Paso 26 · Ir a** el parque — «¡Corre al cumpleaños de Nico en el parque!» _(solo si tienes la marca «intentas las dos»)_
- **Paso 27 · Ir a** el parque — «Ve al cumpleaños de Nico en el parque» _(solo si tienes la marca «solo cumple»)_
- **Paso 28 · Escena** _(solo si NO tienes la marca «solo club»)_
  - _En escena:_ Nico, Omar, Sara, Leire (si tienes la marca «conoces a leire»), Mamá/Papá
  - **Nico:** ¡[tu nombre]! ¡Justo a tiempo!
  - **Nico:** Has llegado antes de que Omar la terminara.
  - **Omar:** Yo estaba protegiéndola.
  - **Nico:** ¿De quién?
  - **Omar:** De mí.
  - **Nico:** ¡[tu nombre]! ¡Has llegado!
  - **Nico:** Te hemos guardado la última porción.
  - **Omar:** La he defendido con mi vida. Y con un tenedor.
  - _(si tienes la marca «conoces a leire»)_ **Leire:** Es imposible decirle que no. Lo he intentado. _[silencio 0.9 s]_
  - **Nico:** Trece años. Ya soy casi mayor. ¿Me veis más alto? Vale. Decid que sí.
- **Paso 29 · Escena** _(solo si tienes la marca «solo club»)_
  - _Narrador:_ _Un pequeño/a papel: «Para [tu nombre].»_
  - _Narrador:_ _A veces crecer también significa perderse algunas cosas._
  - _Narrador:_ _Pero eso no significa que dejen de importarte._ _[silencio 0.9 s]_
  - _Narrador:_ _Quizá crecer no consiste en saber quién quieres ser._
  - _Narrador:_ _Quizá empieza cuando descubres las cosas que quieres probar._ _[silencio 0.9 s]_

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
  - 🎬 **Escena al completarlo «Ins03_G2_Entra»**
    - _En escena:_ Nico
    - **Nico:** ¡[tu nombre]! Aquí.
- **Paso 2 · Ir a** tu aula del instituto — «Ve a clase: hoy viene la orientadora»
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
- **Paso 3 · Cinemática**
  - _En escena:_ Carmen, Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
  - 🎬 **Cinemática «Ins03_Carmen»** _(música: intensidad Nada → Descubrimiento)_
    - _En escena:_ Javier, Carmen, Omar, Nico, Bruno, Leire
    - _Cámara:_ 1 planos (General)
    - **Javier:** Hoy no os doy Historia. Os presento a alguien que sabe bastante de vuestro futuro. Y tampoco es difícil superarme. _[plano Medio de Javier]_
    - **Carmen:** Hola, 1.º C. Soy Carmen. Esta semana, dos preguntas: ¿qué te gusta? ¿Qué quieres probar? _[plano Medio de Carmen · silencio 0.5 s]_
    - **Nico:** ¿Eso significa que no hay clase? _[plano Reaccion de Nico · gesto Surprised]_
    - **Carmen:** Vais a conocer ocho trabajos. Podéis visitar los que queráis. Pero tenéis que conocer al menos cuatro. _[a Nico · plano PrimerPlano de Carmen]_
    - _(si en «sitio instituto» elegiste «Omar»)_ **Omar:** Cuatro. Yo ya sé cuál es el primero. Huele a tortilla. _[plano Hombro de Tú → Omar]_
    - _(si en «sitio instituto» elegiste «Leire»)_ _(o bien)_ **Leire:** Si en la lista hay algo con cámaras, ya sé adónde voy. _[plano Hombro de Tú → Leire]_
    - _(si en «sitio instituto» elegiste «Bruno»)_ _(o bien)_ **Bruno:** Oye. ¿Vamos juntos a la comisaría? Para verla. Desde el lado bueno. _[plano Hombro de Tú → Bruno]_
    - **Carmen:** Y escuchad esto. No tenéis que decidir vuestro futuro esta semana. Ni este año. _[plano PrimerPlano de Carmen · en la pausa: Respirar · silencio 1.0 s]_
    - **Carmen:** Solo tenéis que mirar. Mirar mucho. _[plano PPP de Carmen · silencio 0.6 s]_
    - **Bruno:** ¿Y si ya sé lo que quiero ser? _[plano Reaccion de Bruno · gesto ArmsCrossed]_
    - **Carmen:** Entonces visita algo que no tenga nada que ver. A veces uno se sorprende. _[a Bruno · plano Hombro de Bruno → Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** ¿Hay algo de cine? _[plano Reaccion de Leire]_
    - _(si tienes la marca «conoces a leire»)_ **Carmen:** Hay un estudio audiovisual. Y creo que allí te espera alguien. _[a Leire · plano Medio de Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** …Mi tío. Claro. Qué vergüenza. _[plano PrimerPlano de Leire · gesto Ashamed · en la pausa: Suelo]_
    - **Omar:** Yo ya tengo mi futuro decidido. …Comer. _[plano Medio de Omar]_
    - _(si tienes el recuerdo «primer club»)_ **Carmen:** Y recuerda algo: tu club también cuenta. Lo que haces por gusto también dice mucho de ti. _[plano PrimerPlano de Carmen]_
    - **Carmen:** Apuntad lo que descubráis. No lo que creáis que deberíais descubrir: lo que de verdad os sorprenda. _[plano DosPlanos de Carmen → Javier · gesto Happy · en la pausa: Saludar]_
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Visita al menos cuatro profesiones (en cualquier orden)»
  - _Lugar:_ el hospital · _En escena:_ Doctora Nuria, Tobías, Agente Inés, Marcos, Chef Lola, Sofía, Irene, Toni
  - **Paso 4.1 · Hablar** con Doctora Nuria — «Medicina: el hospital»
    - **Doctora Nuria:** ¡Bienvenida la cantera!
    - **Doctora Nuria:** Soy Nuria. Medicina de urgencias.
    - _(si en «sueno infancia» elegiste «Medicina»)_ **Tú:** Quiero salvar vidas. Volvemos al hospital.
    - **Doctora Nuria:** ¿Qué harías primero? A — Tranquilizarlo.
    - **Doctora Nuria:** B — Observar el brazo sin moverlo. Exacto.
    - **Doctora Nuria:** Antes de ayudar a alguien, tienes que conseguir que se sienta seguro/a. _[silencio 0.9 s]_
    - **Doctora Nuria:** ¿Te ves trabajando aquí? Perfecto.
    - **Doctora Nuria:** Saber lo que no quieres también es avanzar.
    - ❓ **Pregunta al jugador:** ¿Qué haces primero?
      - ➤ «Tranquilizarle: le preguntas su nombre y le hablas» _(efecto: empatia +1)_
        - **Doctora Nuria:** Exacto. Un paciente tranquilo se deja ayudar. La mitad de la medicina es hablar bien.
      - ➤ «Mirar el brazo con cuidado sin moverlo» _(efecto: responsabilidad +1)_
        - **Doctora Nuria:** Bien: no mover, observar, avisar. Luego una radiografía. Tienes buen instinto.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes medicina»)_
        - **Doctora Nuria:** Entonces estudia mucha biología. Y aprende a dormir en cualquier sitio. Te hará falta.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Doctora Nuria:** Muy bien. Saber lo que no quieres también es saber mucho.
  - **Paso 4.2 · Hablar** con Sofía — «Ingeniería: el laboratorio de la facultad»
    - **Sofía:** ¡Pasa! Aquí rompemos cosas para aprender por qué se rompen.
    - _(si en «sueno infancia» elegiste «Ingenieria»)_ **Tú:** Quiero inventar cosas que no existen.
    - _(si en «club» elegiste «Robotica»)_ **Sara:** Sabía que acabarías aquí.
    - _(si en «club» elegiste «Robotica»)_ **Sara:** Aunque yo habría puesto otra pieza.
    - _(si en «club» elegiste «Robotica»)_ **Sofía:** Por eso tú haces robots y él/ella hace puentes.
    - **Sofía:** ¿Te ves trabajando en esto?
    - ❓ **Pregunta al jugador:** ¿Cómo lo arreglas?
      - ➤ «Añadir triángulos: son más fuertes» _(efecto: curiosidad +1)_
        - **Sofía:** ¡Triángulos! ¿Quién te lo ha contado? Los puentes de verdad están llenos. Aguanta dos kilos y medio. Récord del día.
      - ➤ «Probar, romper y volver a probar» _(efecto: valentia +1)_
        - **Sofía:** El método de los ingenieros de verdad. Tres puentes rotos después: aguanta dos kilos. ¡Bien!
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes ingenieria»)_
        - **Sofía:** Pues en unos años nos vemos por aquí. Te guardo una bata.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Sofía:** Vale. Pero si un día te aburres, aquí siempre hay algo roto.
  - **Paso 4.3 · Hablar** con Agente Inés — «Policía y leyes: la comisaría»
    - **Agente Inés:** Mucha gente cree que este trabajo son persecuciones.
    - **Agente Inés:** Casi siempre es escuchar.
    - _(si en «sueno infancia» elegiste «Derecho»)_ **Tú:** Quiero defender a quien no pueda defenderse.
    - **Agente Inés:** Caso cerrado.
    - ❓ **Pregunta al jugador:** ¿Qué haces?
      - ➤ «Escuchar a los dos antes de decidir nada» _(efecto: responsabilidad +1)_
        - **Agente Inés:** Eso es. Al final la maceta era de los dos: la compraron juntos hace veinte años. Se habían olvidado.
      - ➤ «Buscar pruebas: tiques, fotos, testigos» _(efecto: curiosidad +1)_
        - **Agente Inés:** Muy bien. Una foto de hace años lo aclara: la compraron a medias. Se ríen. Caso cerrado.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes derecho»)_
        - **Agente Inés:** Te veo con toga o con placa. Cualquiera de las dos te queda bien.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Agente Inés:** Perfecto. Lo importante es que ahora sabes que esto existe.
  - **Paso 4.4 · Hablar** con Marcos — «Empresa: las oficinas del distrito financiero»
    - **Marcos:** Tengo una empresa. Bueno…
    - **Marcos:** La empresa me tiene a mí.
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
    - **Tobías:** Pasa. No muerdo. El coche sí, si metes la mano donde no debes.
    - **Tobías:** Aquí no hace falta saberlo todo.
    - **Tobías:** Hace falta querer aprender. _[silencio 0.9 s]_
    - ❓ **Pregunta al jugador:** ¿Qué crees?
      - ➤ «La batería» _(efecto: curiosidad +1)_
        - **Tobías:** ¡La batería! Tienes oído. Muchos adultos no lo saben. Cambiamos y… ¡brum! Arrancado.
      - ➤ «No tengo ni idea, pero quiero verlo» _(efecto: humor +1)_
        - **Tobías:** Esa es la mejor respuesta que me han dado nunca. Era la batería. Ahora ya lo sabes.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes oficio»)_
        - **Tobías:** Pues cuando quieras, vente un verano. Te enseño lo que sé. Que es bastante.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Tobías:** Bien. Pero si algún día se te estropea la bici, ya sabes dónde estoy.
  - **Paso 4.6 · Hablar** con Chef Lola — «Cocina: la cafetería del centro»
    - **Omar:** He llegado primero. Era una cuestión de prioridades.
    - **Chef Lola:** Que no quieras trabajar aquí no significa que no puedas aprender a cocinar.
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
    - **Irene:** ¡Al trote! Soy Irene. Entrenadora y fisioterapeuta.
    - _(si tienes el recuerdo «primer torneo»)_ **Irene:** Tu medalla del torneo del colegio… Yo empecé igual.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Hoy no. Si corres, te lesionas un año.» _(efecto: responsabilidad +1)_
        - **Irene:** Duro, pero correcto. Cuidar a alguien a veces es decirle que no.
      - ➤ «Vamos a ponerle hielo y luego decidimos.» _(efecto: empatia +1)_
        - **Irene:** Muy bien: primero cuidar, luego decidir. Al final no pudo correr, pero te lo agradeció.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes deporte»)_
        - **Irene:** Entrena, estudia y cuida tu cuerpo. Y ven a verme cuando quieras.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Irene:** Vale. Pero sigue moviéndote. El cuerpo lo agradece toda la vida.
  - **Paso 4.8 · Hablar** con Toni — «Audiovisual: el cine»
    - **Toni:** Hola. Tú debes de ser [tu nombre].
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Te dije que mi tío habla en planos.
    - _(si tienes la marca «conoces a leire»)_ **Toni:** Es una enfermedad.
    - _(si en «sueno infancia» elegiste «Arte»)_ **Tú:** Quiero hacer cosas que la gente no olvide. Volvemos al cine.
    - **Tú:** Junto a la ventana. Delante de las butacas vacías.
    - **Toni:** Cuenta algo. _[silencio 0.9 s]_
    - ❓ **Pregunta al jugador:** ¿Dónde le pones?
      - ➤ «Junto a la ventana, con luz natural» _(efecto: creatividad +1)_
        - **Toni:** ¡Primer plano, luz de ventana! Eso es lo que haría yo. Queda precioso.
      - ➤ «Delante de las butacas vacías: cuenta una historia» _(efecto: creatividad +1)_
        - **Toni:** Un plano que cuenta algo por sí solo. Eso no se enseña: se tiene.
    - ❓ **Pregunta al jugador:** ¿Te ves trabajando en esto?
      - ➤ «Sí. Me lo imagino perfectamente.» _(efecto: marca «interes audiovisual»)_
        - **Toni:** Pues coge una cámara, aunque sea la del móvil, y no pares de mirar.
      - ➤ «Es interesante, pero no es lo mío.»
        - **Toni:** Me parece bien. Pero ahora ya ves las películas de otra forma. No hay vuelta atrás.
- **Paso 5 · Ir a** tu aula del instituto — «Vuelve al instituto: Carmen quiere saber qué has descubierto»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Javier, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Nico
- **Paso 6 · Escena**
  - **Carmen:** Bueno, [tu nombre]. ¿Qué has descubierto?
    - 🎬 **Escena de cámara «Ins03_G6_Musica»** _(música: → Intima)_
  - _(si tienes la marca «interes medicina»)_ **Carmen:** El hospital te removió algo.
  - _(si tienes la marca «interes medicina»)_ **Nico:** ¿Médico? Te dejo practicar conmigo.
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Sofía me ha dicho que tus puentes aguantan más de lo esperado.
  - _(si tienes la marca «interes derecho»)_ **Carmen:** Inés dice que sabes escuchar a las dos partes.
  - _(si tienes la marca «interes economia»)_ **Carmen:** Marcos va a cambiar el color de sus bicicletas. Por tu culpa.
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Tobías pregunta si vas a volver al taller.
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Con Tobías, eso casi es una oferta de trabajo. _[silencio 0.9 s]_
  - _(si tienes la marca «interes cocina»)_ **Carmen:** Lola dice que tienes cabeza de cocina.
  - _(si tienes la marca «interes cocina»)_ **Omar:** Lo sabía. Socios.
  - _(si tienes la marca «interes deporte»)_ **Carmen:** Irene se fijó en que cuidaste primero a una persona y después pensaste en ganar.
  - _(si tienes la marca «interes audiovisual»)_ **Carmen:** Toni ya te llama “la cámara”.
  - _(si tienes la marca «interes audiovisual»)_ **Carmen:** Viniendo de él, es casi un título. _[silencio 0.9 s]_
  - _(si tienes la marca «conoces a leire»)_ **Leire:** Mi tío no se lo dice a cualquiera. Bueno… sí.
  - _(si tienes la marca «conoces a leire»)_ **Leire:** Pero esta vez lo dice en serio.
  - **Carmen:** Y ahora quiero preguntarte algo distinto. No qué quieres ser.
  - **Carmen:** ¿Cómo te sientes con tu futuro? _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Cómo te sientes con tu futuro?
    - ➤ «Creo que ya sé lo que me gusta.» _(efecto: responsabilidad +1; decisión «orientacion» = Claro)_
      - **Carmen:** Eso está bien. Pero no cierres ninguna puerta demasiado pronto.
    - ➤ «Tengo más dudas que antes.» _(efecto: curiosidad +1; decisión «orientacion» = Dudas)_
      - **Carmen:** Entonces has mirado de verdad.
      - **Carmen:** Las dudas también son una forma de avanzar. _[silencio 0.9 s]_
    - ➤ «Me gustan muchas cosas a la vez.» _(efecto: creatividad +1; decisión «orientacion» = Muchas)_
      - **Carmen:** A mí también me pasaba. Y mírame.
      - **Carmen:** Ahora ayudo a otros a descubrir lo suyo.
  - **Omar:** Yo ya lo tengo claro. Quiero trabajar con Lola.
  - **Omar:** O comer donde trabaje Lola. _[silencio 0.9 s]_
  - **Carmen:** Guárdalo. Dentro de unos años lo vas a volver a leer.
  - **Carmen:** Y probablemente te vas a reír. _[silencio 0.9 s]_
  - **Carmen:** O quizá descubras que ya lo sabías.
  - **Javier:** ¿Y?
  - **Carmen:** Todavía no lo saben. Y eso es exactamente como tiene que ser.
  - **Javier:** Entonces ha salido bien.

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
  - **Rayo:** Eh, tú. Sí. Tú. Te he visto.
  - **Rayo:** No eres como los demás.
  - **Rayo:** Tienes pinta de saber divertirte.
  - **Rayo:** Después del recreo nos vamos a los recreativos. Javier ni se entera.
  - **Nerea:** Ni siquiera levanta la cabeza. Eso dice siempre.
  - **Rayo:** Porque siempre funciona.
  - **Nerea:** Yo voy porque no tengo nada mejor que hacer. Tú verás.
  - **Omar:** [tu nombre]… Esos se meten en líos. Todo el rato. Yo me vuelvo a clase.
  - **Omar:** Tú haz lo que quieras.
  - 🎬 **Escena al completarlo «Pan1_G4_Entra»**
    - _En escena:_ Javier, Rayo, Nerea
    - **Rayo:** Sabía que tenías algo. Venga. No mires tanto.
    - **Rayo:** Si dudas, te arrepientes.
    - **Javier:** ¿Volviendo a clase por tu propio pie? Me alegra el día.
    - **Javier:** Hoy toca Revolución Francesa.
    - **Javier:** Y es bastante mejor de lo que suena.
    - **Rayo:** ¡Pringado! Tú te lo pierdes.
    - **Nerea:** ¿Y a ti qué te importa?
    - **Nerea:** ¿Has visto mis dibujos?
    - **Nerea:** Nadie mira mis dibujos. Vale. Hoy no voy.
    - **Nerea:** Pero no te acostumbres a mandarme.
    - **Rayo:** ¿Nerea se queda? Tú. Me acuerdo de tu cara.
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
  - **Rayo:** ¿Ves? Allí te hacen estar quieto seis horas. Aquí mandas tú.
  - **Nerea:** Más seria. La primera vez también me lo pareció.
  - **Nerea:** Luego llegan las notas.
  - **Nerea:** Y las llamadas a casa. _[silencio 0.9 s]_
  - **Rayo:** Siempre pensando en lo peor.
- **Paso 8 · Ir a** el parque — «Rayo quiere enseñarte «su» muro del parque» _(solo si en «pellas» elegiste «Ir»)_
  - _Lugar:_ el parque · _En escena:_ Rayo, Nerea
- **Paso 9 · Usar** — «El muro: Rayo te da un espray» _(solo si en «pellas» elegiste «Ir»)_
  - 🎬 **Escena al completarlo «Pan1_G10_Entra»**
    - _En escena:_ Javier
    - **Javier:** La Historia no trata solo de lo que pasó.
    - **Javier:** También trata de por qué la gente tomó determinadas decisiones.
  - 🖐 _Al usar «El muro del parque»:_
    - **Rayo:** Este muro es nuestro. Cada uno pone su firma. Pon la tuya.
    - ❓ **Pregunta al jugador:** ¿Qué haces con el espray?
      - ➤ «Pintas tu firma, grande» _(efecto: Rayo +4; rebeldia +1; marca «pintada»)_
        - **Rayo:** Eso. Ahora eres de los nuestros.
      - ➤ «Pintas un dibujo bonito» _(efecto: Nerea +4; creatividad +1; rebeldia +1; marca «pintada»)_
        - **Nerea:** Eso está bien. Muy bien. _[silencio 0.9 s]_
        - **Nerea:** Aunque sigue siendo pintar donde no se puede.
      - ➤ «Devuelves el espray» _(efecto: Nerea +3; Rayo -4; valentia +1)_
    - **Rayo:** Vale. Qué miedo tenéis todos a todo. Ya te lo pensarás. Pero su tono cambia.
    - **Rayo:** Ya no parece estar bromeando.
- **Paso 10 · Clase** — «Clase de Historia con Javier» _(solo si en «pellas» elegiste «Clase»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Javier
- **Paso 11 · Escena** _(solo si en «pellas» elegiste «Clase»)_
  - _Lugar:_ el patio · _En escena:_ Rayo, Nerea
  - **Rayo:** Mira quién sale de clase.
  - **Rayo:** ¿Qué tal la Revolución Francesa? _[silencio 0.9 s]_
  - **Rayo:** ¿Te has divertido mucho?
  - **Nerea:** Javier ha llamado a nuestras casas. Hiciste bien.
- **Paso 12 · Escena** _(solo si en «pellas» elegiste «Nerea»)_
  - _En escena:_ Nerea
  - **Nerea:** Mira. Son pequeños cómics.
  - **Nerea:** No se los he enseñado a nadie.
  - **Nerea:** Rayo dice que dibujar es de críos. _[silencio 0.9 s]_
  - **Nerea:** Pero Rayo dice muchas cosas.
- **Paso 13 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 14 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - _(si en «pellas» elegiste «Ir»)_ **Mamá/Papá:** Ha llamado Javier. Dice que esta tarde no estabas en clase. ¿Me lo explicas? Ya. Vale. Te creo.
  - _(si en «pellas» elegiste «Ir»)_ **Abu:** Las mentiras pesan más que la mochila, cariño.
  - _(si en «pellas» elegiste «Ir»)_ **Abu:** Lo digo por experiencia. _[silencio 0.9 s]_
  - _(si en «pellas» elegiste «Ir»)_ **Mamá/Papá:** Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga.
  - _(si en «pellas» elegiste «Ir»)_ **Mamá/Papá:** Y después lo hablamos.
  - _(si en «pellas» elegiste «Clase»)_ **Mamá/Papá:** ¿Qué tal el día? Tienes cara de haber aprendido algo.
  - _(si en «pellas» elegiste «Nerea»)_ **Mamá/Papá:** Omar me ha contado que hoy has ayudado a una chica de cuarto. Qué bien.
  - _(si en «pellas» elegiste «Nerea»)_ **Abu:** A veces ser valiente no significa hacer ruido.
  - _(si en «pellas» elegiste «Nerea»)_ **Abu:** A veces significa decir que no. _[silencio 0.9 s]_
  - _(si en «pellas» elegiste «Ir»)_ ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Me encontraba mal y me fui a dar una vuelta» (mentira) _(efecto: Mamá/Papá -5; rebeldia +1; marca «mentiste familia»)_
      - **Mamá/Papá:** …Ya. Vale. Te creo. Esta vez.
      - **Abu:** (desde el sillón, sin mirarte) Las mentiras pesan más que la mochila, cariño. Lo digo por experiencia.
    - ➤ «Me fui con unos de 4.º. Me equivoqué.» _(efecto: Mamá/Papá +3; responsabilidad +1)_
      - **Mamá/Papá:** Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga, y lo hablamos.
- **Paso 15 · Hablar** con Bruno — «Un mensaje de Bruno: «¿Hablamos? Estoy en la puerta de tu casa»»
  - _Lugar:_ Aquí · _En escena:_ Bruno
  - **Bruno:** Oye. Me he enterado de lo de Rayo.
    - 🎬 **Escena de cámara «Pan1_G15_Musica»** _(música: → Intima)_
  - **Bruno:** En el instituto se entera todo el mundo de todo.
  - **Bruno:** Yo era el malo del colegio. ¿Te acuerdas? Molaba.
  - **Bruno:** Hasta que dejó de molar. Rayo es eso. Pero en mayor.
  - _(si tienes la marca «rechazaste la pandilla»)_ **Bruno:** Hiciste bien en volver. De verdad.
  - _(si en «pellas» elegiste «Ir»)_ **Bruno:** Solo… Ten cuidado. Con Rayo, un día son los recreativos.
  - _(si en «pellas» elegiste «Ir»)_ **Bruno:** Y otro día es otra cosa. _[silencio 0.9 s]_
  - **Rayo:** Carismático. Popular. Y precisamente por eso peligroso.
  - **Rayo:** Entiendo por qué quiero seguirle.
  - **Nerea:** No es simplemente “la chica buena”.
  - **Bruno:** Ya no es el niño que intimidaba.
  - **Bruno:** Ahora reconoce algo de sí mismo en Rayo.
  - _Narrador:_ _Presentarla como: «El jugador está descubriendo quién es cuando sus amigos empiezan a tirar de él en direcciones diferentes.»_

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
    - **Rayo:** ¿Sabes qué es lo mejor de los sábados? Que no hay clase.
    - **Nerea:** Muy profundo.
    - **Rayo:** El súper de Paco cierra a las diez.
    - **Rayo:** La puerta del almacén no cierra bien. Entramos. Cogemos unas latas. Unas chuches. Y nos vamos. _[silencio 0.9 s]_
    - **Rayo:** Cinco minutos. _[silencio 0.9 s]_
    - **Nerea:** Eso es robar.
    - **Rayo:** No. Es coger unas cosas.
    - **Nerea:** Que tengan otro nombre no cambia lo que es.
    - **Rayo:** Paco tiene de sobra. Nadie se va a enterar. _[silencio 0.9 s]_
    - _(si tienes la marca «pintada»)_ **Rayo:** Tú ya eres de los nuestros.
    - _(si tienes la marca «pintada»)_ **Rayo:** Lo del muro fue el primer paso. Esto es el segundo. _[silencio 0.9 s]_
    - **Tú:** Voy.
    - **Rayo:** Eso quería oír. A las diez y media. Detrás del súper.
    - **Tú:** Paso. Esto ya no es una tontería.
    - **Rayo:** Tú sabrás. Luego no me vengas con que te aburres.
    - **Tú:** No lo hagáis. Os van a pillar. Nerea, tú tampoco.
    - **Rayo:** ¿Ahora eres su madre? Nerea hace lo que quiere. ¿Verdad?
    - _(si tienes la marca «amiga nerea»)_ **Nerea:** Esta vez me quedo en casa. Lo siento, Rayo.
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
  - 🎬 **Escena al completarlo «Pan2_G5_Entra»**
    - _En escena:_ Rayo
    - **Rayo:** Pensaba que no venías. Sabía que vendrías.
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
  - 🎬 **Escena al completarlo «Pan2_G6_Entra»**
    - _En escena:_ Rayo, Nerea
    - **Rayo:** Rápido. Coge lo que quieras. Y nos vamos.
    - **Rayo:** ¡Eso es! ¡Vámonos!
    - **Nerea:** Espera. Yo tampoco quería. Me voy contigo.
- **Paso 11 · Acción del jugador** — «Servicio a la comunidad: limpia en el Punto Limpio (0/3)» _(solo si tienes la marca «pillado»)_
  - _Lugar:_ el Punto Limpio · _En escena:_ Agente Inés
- **Paso 12 · Escena** _(solo si tienes la marca «pillado»)_
  - **Nerea:** Rayo… ¿“Nadie se va a enterar”? ¡¿Esto es nadie?! _[plano General · silencio 0.9 s]_
    - 🎬 **Escena de cámara «Pan2_G7_Musica»** _(música: → Tension)_
  - **Rayo:** ¡CORRED! ¡Cada uno por un lado!
  - **Rayo:** ¡Nos vemos en el parque! _[silencio 0.9 s]_
- **Paso 13 · Transición (pasa el tiempo)** — «Esa noche, en casa…» _(solo si en «plan» NO elegiste «Ir»)_
  - ⏳ _Pantalla de transición:_ «Esa noche, en casa…»
- **Paso 14 · Escena** _(solo si en «plan» NO elegiste «Ir»)_
  - **Rayo:** ¡JA! ¿Has visto? ¡Nadie nos pilla!
  - **Rayo:** Mañana nos comemos las chuches a la salud de Paco. _[silencio 0.9 s]_
- **Paso 15 · Escena**
  - _Lugar:_ Aquí · _En escena:_ Nerea
  - _(si tienes la marca «interes derecho»)_ **Agente Inés:** Hola otra vez. Nos conocimos durante la semana de las profesiones.
  - _(si tienes la marca «interes derecho»)_ **Agente Inés:** No pensaba que volveríamos a vernos así.
  - **Agente Inés:** Tranquilidad. Nadie va a ir a la cárcel por unas latas.
  - **Agente Inés:** Pero esto sí tiene consecuencias.
  - **Mamá/Papá:** ¿Estás bien? Vale. Ahora sí.
  - **Mamá/Papá:** ¿En qué estabas pensando?
  - _(si tienes la marca «mentiste familia»)_ **Mamá/Papá:** Y no es la primera vez que me mientes.
  - _(si tienes la marca «mentiste familia»)_ **Mamá/Papá:** Lo del día que estabas “enfermo” tampoco me lo creí. _[silencio 0.9 s]_
  - **Paco:** Hmm. Treinta años con el súper abierto.
  - **Paco:** Nunca me habían entrado. Y has sido tú. No me lo esperaba. _[silencio 0.9 s]_
  - _(si tu relación con Rayo es de 5 o más)_ **Rayo:** Yo no he dicho nada. Que conste.
  - **Agente Inés:** Sois menores. Y es la primera vez.
  - **Agente Inés:** Tres turnos de servicio a la comunidad.
  - **Agente Inés:** Y pedir perdón a Paco. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices a Paco?
    - ➤ «Lo siento. De verdad. Te devuelvo todo y te lo pago.» _(efecto: marca «perdon paco»)_
      - **Paco:** Hmm. Pedir perdón mirando a los ojos. Eso ya es algo.
    - ➤ «No dices nada. Miras al suelo.»
      - **Paco:** Ya. Hmm. No añade nada más.
  - **Agente Inés:** Tres turnos. Bien hecho. ¿Sabes qué?
  - **Agente Inés:** La mayoría de los chavales que vienen aquí no vuelven nunca a la comisaría.
  - **Agente Inés:** Espero que tú seas de esos.
  - _(si en «plan» elegiste «No»)_ **Nerea:** Al final han ido Rayo y dos más.
  - _(si en «plan» elegiste «Frenar»)_ **Nerea:** Me he quedado en casa. _[silencio 0.9 s]_
  - **Nerea:** Rayo dice que alguien se ha chivado. _[silencio 0.9 s]_
  - **Nerea:** Dime que no has sido tú.
  - _Narrador:_ _Se oyen fragmentos: «Lo del supermercado…»_
  - _Narrador:_ _«Dicen que saltó la alarma…»_
  - _Narrador:_ _«Rayo está expulsado…»_
  - **Nerea:** Todo el instituto sabe lo del súper.
  - **Nerea:** Rayo está expulsado tres días. _[silencio 0.9 s]_
  - _(si tienes la marca «pillado»)_ **Nerea:** Y tú… Te pillaron. Lo siento.
  - _(si tu relación con Rayo es de 5 o más)_ **Nerea:** Rayo dice que eres “de los buenos”.
  - _(si tu relación con Rayo es de 5 o más)_ **Nerea:** No sé si eso es un piropo. _[silencio 0.9 s]_
  - _(si tienes la marca «escapaste»)_ **Nerea:** Tú te libraste. Pero hay cámaras en la puerta del almacén.
  - _(si tienes la marca «escapaste»)_ **Nerea:** Lo sabe todo el mundo menos Rayo.
  - _(si tienes la marca «te fuiste»)_ **Nerea:** Te fuiste a tiempo. Yo también.
  - _(si tienes la marca «te fuiste»)_ **Nerea:** Creo que es lo más valiente que he hecho nunca.
  - _(si en «plan» NO elegiste «Ir»)_ **Nerea:** Tú no estabas. Mejor. Rayo…
  - **Nerea:** En su casa no hay nadie nunca. No sé qué va a pasar.
  - **Nerea:** Supongo que crecer es esto. Hacer cosas.
  - **Nerea:** Y descubrir cuáles no quieres volver a hacer. _[silencio 0.9 s]_
  - **Nerea:** con una interfaz moral.

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
  - **Carmen:** ¿Sigues buscando algo para este verano?
  - _Narrador:_ _Segundo mensaje: «Tobías / Lola / Marcos conocen algunos trabajos para estudiantes.»_
  - ❓ **Pregunta al jugador:** ¿Qué quieres conseguir este verano?
    - ➤ «Una bici de verdad, para ir a todas partes» _(efecto: decisión «meta» = Bici)_
    - ➤ «Una cámara, como la de Leire» _(efecto: decisión «meta» = Camara)_
    - ➤ «Ayudar en casa: las cosas están caras» _(efecto: Mamá/Papá +4; responsabilidad +1; decisión «meta» = Casa)_
    - ➤ «Ahorrar para cuando vaya a la universidad» _(efecto: responsabilidad +1; decisión «meta» = Ahorro)_
- **Paso 3 · Ir a** tu aula del instituto — «Ve al instituto: taller de primer empleo con Carmen»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Omar
- **Paso 4 · Escena**
  - **Carmen:** Pasa. ¿Trabajo?
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Tobías sigue preguntando por ti.
  - _(si tienes la marca «interes cocina»)_ **Carmen:** Lola necesita ayuda algunas tardes.
  - _(si tienes la marca «interes audiovisual»)_ **Carmen:** Toni busca alguien que le ayude con el material.
  - _(si tienes la marca «interes deporte»)_ **Carmen:** Irene necesita ayuda durante algunos entrenamientos infantiles.
  - _(si tienes la marca «interes economia»)_ **Carmen:** Marcos busca ayuda con inventario.
  - _(si tienes la marca «interes medicina»)_ **Carmen:** En el centro de salud no puedes trabajar todavía, pero hay un programa de apoyo para actividades comunitarias.
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Sofía puede enseñarte un pequeño/a proyecto de laboratorio.
  - _(si tienes la marca «interes derecho»)_ **Carmen:** Inés conoce un programa juvenil de apoyo comunitario.
  - **Carmen:** Pero hay una cosa. No quiero que elijas el trabajo que parezca más importante.
  - **Carmen:** Elige el que quieras probar.
  - ❓ **Pregunta al jugador:** ¿Qué pones como tu punto fuerte?
    - ➤ «Soy responsable: si digo que voy, voy» _(efecto: responsabilidad +1; decisión «perfil» = Responsable)_
      - **Carmen:** Es lo que más buscan. En serio: más que saber hacer cosas.
    - ➤ «Trato bien a la gente» _(efecto: empatia +1; decisión «perfil» = Gente)_
      - **Carmen:** Perfecto para trabajar de cara al público.
    - ➤ «Aprendo rápido» _(efecto: curiosidad +1; decisión «perfil» = Aprendo)_
      - **Carmen:** Muy bien. Y ponlo con un ejemplo: tu club, un proyecto…
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
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Platos. Pedidos. Hoy aprenderás una cosa. No corras. Organízate.
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** No pasa nada. Ahora corrígelo.
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
  - _Narrador:_ _Compañero: «¿Primer trabajo?» Compañero: «Se nota.»_
  - _Narrador:_ _Compañero: «Yo también era un desastre.»_ _[silencio 0.9 s]_
  - _(si has terminado «Las malas compañías»)_ **Nerea:** ¿Cómo va tu primer día?
  - _(si has terminado «Las malas compañías» y tienes la marca «amiga nerea»)_ **Nerea:** No te olvides de descansar.
  - _(si has terminado «Las malas compañías» y tienes la marca «rayo cambia»)_ **Nerea:** Rayo dice que Tobías le ha hecho limpiar media vida.
  - _(si has terminado «Las malas compañías» y tienes la marca «camino delincuente»)_ **Nerea:** ¿Sigues con Rayo?
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
  - ❓ **Pregunta al jugador:** ¿Qué haces con él?
    - ➤ «Guardarlo para lo que querías» _(efecto: responsabilidad +1; decisión «sueldo» = Meta)_
    - ➤ «Invitar a tu familia a cenar fuera» _(efecto: Abu +6; Mamá/Papá +8; empatia +1; decisión «sueldo» = Familia)_
    - ➤ «Una parte para ti, otra para ahorrar» _(efecto: responsabilidad +1; decisión «sueldo» = Mitad)_
- **Paso 20 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
- **Paso 21 · Escena**
  - _Lugar:_ el salón · _En escena:_ Mamá/Papá, Abu
  - _(si en «sueldo» elegiste «Familia»)_ **Mamá/Papá:** ¿Que nos invitas a cenar? No hacía falta… Pero ya que insistes, yo quiero postre.
  - _(si tienes la marca «mentiste entrevista»)_ **Mamá/Papá:** Y oye: lo de la entrevista… ¿dijiste la verdad? Porque las mentiras en el trabajo tienen patas muy cortas.
  - **Mamá/Papá:** ¿Eso es…? Tu primer sueldo. No pregunta cuánto.
    - 🎬 **Escena de cámara «Ins04_G13_14_15_16_Musica»** _(música: → Intima)_
  - **Abu:** Ahora ya sabes cuánto vale una hora.
  - **Abu:** Pero todavía te falta descubrir cuánto vale tu tiempo. _[silencio 0.9 s]_
  - **Tú:** Guardar el dinero. Comprar algo que llevas tiempo queriendo.
  - _(si has terminado «Las malas compañías» y tienes la marca «camino delincuente»)_ **Rayo:** Tengo otra oportunidad de ganar dinero.
  - _(si has terminado «Las malas compañías» y tienes la marca «camino trabajador»)_ **Nerea:** ¿Te ha gustado trabajar?
  - _(si has terminado «Las malas compañías» y tienes la marca «rayo cambia»)_ **Rayo:** Tobías me ha hecho desmontar un motor.
  - _(si tienes la marca «rayo cambia»)_ _Narrador:_ _Segundo mensaje: «Creo que me gusta.»_
  - _(si tienes las marcas «interes audiovisual» y «conoces a leire»)_ **Leire:** Toni dice que tienes buen ojo.
  - _(si en «empleo» elegiste «Barista»)_ **Mamá/Papá:** Quemaste tres tostadas el primer día. _[plano PPP de Tú]_
  - _(si en «empleo» elegiste «Barista»)_ **Mamá/Papá:** Estas referencias hacen que el mundo tenga memoria.

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
  - 🎬 **Escena al completarlo «Pan3_G2_Entra»**
    - _En escena:_ Rayo
    - **Rayo:** Mira quién viene. Pensaba que ya no te acordabas de mí.
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
    - **Rayo:** Camisetas del Altamar. Iguales que las de verdad. Pero a una cuarta parte del precio. Las vendemos a la salida del estadio. _[plano Hombro de Tú → Rayo]_
    - **Rayo:** Cincuenta pavos por tarde. Nadie sale herido. El club tiene millones. _[plano Medio de Rayo · gesto Shrug]_
    - **Rayo:** ¿Qué me dices? _[plano Hombro de Rayo → Tú · silencio 0.8 s]_
    - _Narrador:_ _Cincuenta. Por una tarde. Piensas en todo lo que se puede hacer con cincuenta._ _[plano PPP de Tú · silencio 0.6 s]_
    - _(si tienes la marca «mentiste familia»)_ _Narrador:_ _Y te acuerdas de Abu: «las mentiras pesan más que la mochila»._ _[plano PPP de Tú]_
    - **Rayo:** Piénsatelo. Yo aquí estoy. Como siempre. _[plano Medio de Rayo · en la pausa: Apartar]_
    - 🔀 **Variante «Distantes»** (si tu relación con Rayo es menor que 0): cambia Actors, Music por:
      - _En escena:_ Rayo
- **Paso 4 · Ir a** el patio — «Nerea quiere hablar contigo en el patio»
  - _Lugar:_ el patio · _En escena:_ Nerea
- **Paso 5 · Hablar** con Nerea — «Siéntate con Nerea»
  - **Nerea:** Me voy de la pandilla. Ya está.
  - **Nerea:** Estoy harta de correr. De mentir en casa.
  - **Nerea:** Y de que Rayo decida por mí. _[silencio 0.9 s]_
  - _(si tienes la marca «hurto» y tienes el recuerdo «la noche»)_ **Nerea:** Desde la noche del súper no he vuelto a dormir bien. ¿Tú sí?
  - **Nerea:** Pero me da miedo. Si me voy… No tengo a nadie. _[silencio 0.9 s]_
  - **Nerea:** En mi clase soy “la de la pandilla de Rayo”. Nadie se me acerca.
  - _(si tienes la marca «amiga nerea»)_ **Nerea:** Tú me dijiste que mis dibujos eran buenos.
  - _(si tienes la marca «amiga nerea»)_ **Nerea:** Nadie me había dicho eso. Nunca. _[silencio 0.9 s]_
  - **Nerea:** Rayo te ha ofrecido lo de las camisetas, ¿no? A mí también. ¿Qué vas a hacer?
  - 🎬 **Escena al completarlo «Pan3_G6_Entra»**
    - _En escena:_ Nerea
    - **Nerea:** Vale. Entonces ya sé qué vas a elegir. No discute. Eso duele más.
    - **Nerea:** Por primera vez sonríe. No exageradamente. ¿De verdad? Vale. Entonces no voy sola.
    - **Nerea:** ¿Quieres salvar a Rayo? Eso va a ser difícil. Pero…
    - **Nerea:** Gracias por intentarlo.
- **Paso 6 · Decisión** — «¿Qué camino eliges?»
  - ➤ **Opción «Entrar en el negocio de Rayo: dinero fácil»** _(efecto: decisión «camino» = Negocio; Nerea -6; Rayo +8; rebeldia +3; marca «camino delincuente»)_
  - ➤ **Opción «Alejarte de la pandilla y ayudar a Nerea a salir»** _(efecto: decisión «camino» = Alejarse; Nerea +10; Rayo -4; responsabilidad +2; marca «camino trabajador»)_
  - ➤ **Opción «Intentar que Rayo lo deje (y ofrecerle otra cosa)»** _(efecto: decisión «camino» = Salvar; Nerea +6; Rayo +4; empatia +2; valentia +1; marca «camino trabajador»)_
- **Paso 7 · Ir a** el Estadio Altamar — «Sábado: vende camisetas falsas del Altamar a la salida del estadio» _(solo si en «camino» elegiste «Negocio»)_
  - _Lugar:_ el Estadio Altamar · _En escena:_ Rayo
- **Paso 8 · Escena** _(solo si en «camino» elegiste «Negocio»)_
  - _En escena:_ Rayo, Nico
  - **Rayo:** Tú grita: ”¡Camisetas, a diez!” Yo cobro.
  - **Rayo:** Si ves a un policía, silba. _[silencio 0.9 s]_
  - **Nico:** ¿[tu nombre]? ¿Qué haces con esas camisetas? Son falsas. Son de MI equipo. ¿En serio?
  - **Nico:** Es solo un negocio. No te metas. Vale. No me meto.
  - **Nico:** Pero no me hables en el recreo. No sé quién eres.
  - **Rayo:** ¡Eh! ¡¿Adónde vas?!
  - **Nico:** Vámonos. Te invito a un bocadillo.
  - **Nico:** Y no se lo cuento a nadie. Bueno… A Omar sí.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Es solo un negocio. No te metas.» _(efecto: Nico -15; rebeldia +1)_
      - **Nico:** …Vale. No me meto. Pero no me hables en el recreo. No sé quién eres.
      - _Narrador:_ _Esa tarde ganas cincuenta. Te pesan en el bolsillo más que cualquier mochila._
    - ➤ «Dejas la bolsa en el suelo y te vas con Nico» _(efecto: Nico +6; Rayo -8; valentia +2; marca «camino trabajador» y «redimido»)_
      - **Rayo:** ¡Eh! ¿Adónde vas? ¡¿ADÓNDE VAS?!
      - **Nico:** Vámonos. Te invito a un bocadillo. Y no se lo cuento a nadie. Bueno, a Omar sí. A Omar se lo cuento todo.
  - 🎬 **Escena al completarlo «Pan3_G9_Entra»**
    - _En escena:_ Nerea
    - **Nerea:** No sé si puedo.
- **Paso 9 · Ir a** tu aula del instituto — «Acompaña a Nerea a hablar con Carmen, la orientadora» _(solo si en «camino» elegiste «Alejarse»)_
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen, Nerea (te acompaña)
- **Paso 10 · Escena** _(solo si en «camino» elegiste «Alejarse»)_
  - _En escena:_ Carmen, Nerea
  - **Carmen:** No la interroga. ¿Cómo estás? Puedes tardar.
  - **Nerea:** Quiero salir.
  - **Carmen:** Entonces vamos a buscar una puerta. ¿Estos son tuyos?
  - **Carmen:** Los jueves hay un taller de cómic en la biblioteca del campus.
  - **Carmen:** Lo lleva Toni, el tío de Leire. _[silencio 0.9 s]_
  - **Nerea:** ¿Con gente que dibuja?
  - **Carmen:** Con gente que dibuja.
  - **Nerea:** Vale. Pero vienes conmigo el primer día. _[silencio 0.9 s]_
  - **Carmen:** Salir de un sitio así cuesta mucho.
  - **Carmen:** Hacerlo acompañado, un poco menos. Bien hecho. _[silencio 0.9 s]_
- **Paso 11 · Ir a** la gasolinera — «Ve al taller de Tobías (gasolinera): a Rayo le encantan los motores» _(solo si en «camino» elegiste «Salvar»)_
  - _Lugar:_ la gasolinera · _En escena:_ Tobías
- **Paso 12 · Hablar** con Tobías — «Habla con Tobías» _(solo si en «camino» elegiste «Salvar»)_
  - **Tobías:** ¿Un chaval que se pasa el día desmontando motos que no son suyas? Hmm.
  - **Tobías:** Eso es talento mal usado.
  - **Tobías:** Que venga mañana a las ocho.
  - **Tobías:** Si llega a las ocho y cinco, que no venga. Si llega a las ocho… _[silencio 0.9 s]_
  - **Tobías:** Le enseño todo lo que sé.
- **Paso 13 · Ir a** el parque — «Vuelve al parque: díselo a Rayo» _(solo si en «camino» elegiste «Salvar»)_
  - _Lugar:_ el parque · _En escena:_ Rayo
- **Paso 14 · Hablar** con Rayo — «Habla con Rayo» _(solo si en «camino» elegiste «Salvar»)_
  - **Rayo:** ¿Tú otra vez? ¿Vienes a comprarme una camiseta? ¿Por qué haces esto?
  - _(si tu relación con Rayo es menor que 5)_ **Rayo:** Tú siempre me has dicho que no a todo. _[silencio 0.9 s]_
  - _(si tu relación con Rayo es menor que 5)_ **Rayo:** Eres la única persona que no me ha dejado tirado. Qué raro. _[silencio 0.9 s]_
  - _(si tu relación con Rayo es de 5 o más)_ **Rayo:** Estabas en todo conmigo. Podrías seguir.
  - _(si tu relación con Rayo es de 5 o más)_ **Rayo:** Y vienes a sacarme a mí.
  - **Rayo:** Porque te mereces algo mejor que correr delante de la policía. A las ocho. Vale.
  - **Rayo:** Pero si el viejo es un pesado, me piro. Qué pesado/a. Vale. A las ocho.
  - **Rayo:** Y no se lo digas a nadie de la pandilla. _[silencio 0.9 s]_
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
  - _(si tienes la marca «camino delincuente»)_ **Mamá/Papá:** Te noto raro/a últimamente. Llegas tarde. No hablas.
    - 🎬 **Escena de cámara «Pan3_G16_Musica»** _(música: → Intima)_
  - _(si tienes la marca «camino delincuente»)_ **Mamá/Papá:** Sabes que puedes contarme lo que sea, ¿verdad? Lo que sea.
  - _(si tienes la marca «camino delincuente»)_ **Abu:** Desde el sillón. Yo también tuve malas compañías a tu edad.
  - _(si tienes la marca «camino delincuente»)_ **Abu:** Lo difícil no es entrar. Es salir. Pero se sale. _[silencio 0.9 s]_
  - _(si en «camino» elegiste «Alejarse»)_ **Mamá/Papá:** Me ha llamado la madre de Nerea.
  - _(si en «camino» elegiste «Alejarse»)_ **Mamá/Papá:** Dice que su hija ha vuelto a dibujar. _[silencio 0.9 s]_
  - _(si en «camino» elegiste «Alejarse»)_ **Mamá/Papá:** Que ha sido gracias a ti. Ven aquí.
  - _(si en «camino» elegiste «Salvar»)_ **Mamá/Papá:** Me ha contado Tobías que le has llevado a un chaval.
  - _(si en «camino» elegiste «Salvar»)_ **Mamá/Papá:** Dice que llegó a las ocho menos cuarto. Qué orgullo me das. _[silencio 0.9 s]_

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
  - **Sara:** [tu nombre], mira. Está en el grupo desde anoche. Omar no ha venido. Omar no falta nunca.
    - 🎬 **Escena de cámara «Ins05_G3_Musica»** _(música: → Descubrimiento)_
  - **Sara:** Ni con fiebre. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces con la foto?
    - ➤ «Borradla. No tiene gracia.» _(efecto: Omar +5; Sara +3; valentia +2; decisión «foto» = Frenar)_
      - **Leire:** +1 _[silencio 1.8 s]_
      - **Sara:** +1 Tres alumnos más.
    - ➤ «No dices nada, pero no la reenvías.» _(efecto: decisión «foto» = Nada)_
      - **Sara:** No reenviarla está bien. Pero no sé si basta.
    - ➤ «Se te escapa una sonrisa… y luego te sientes fatal.» _(efecto: humor +-1; decisión «foto» = Reiste; marca «te reiste»)_
      - **Sara:** Es Omar. Nuestro Omar.
  - **Javier:** Móviles fuera. Y si alguien tiene algo que contarme…
  - **Javier:** Mi puerta está abierta.
  - **Sara:** En el recreo averiguamos quién la hizo. Y buscamos a Omar.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Averigua quién hizo la foto (en el recreo)»
  - _Lugar:_ el patio · _En escena:_ Sara (te acompaña), Leire, Bruno
  - **Paso 4.1 · Usar** — «Mira la captura con calma»
    - 🖐 _Al usar «La captura del grupo de clase»:_
      - _Narrador:_ _La primera persona que la compartió en el grupo fue Nico._
      - **Sara:** ¿Nico? Nico y Omar se conocen desde los seis años. _[silencio 0.9 s]_
  - **Paso 4.2 · Hablar** con Leire — «Pregunta a Leire: sabe de fotos»
    - **Leire:** El montaje es malísimo.
    - **Leire:** Pero la foto original está bien hecha. _[silencio 0.9 s]_
    - **Leire:** Está tomada desde arriba. Teleobjetivo. La luz es de tarde.
    - **Leire:** Y el fondo es la pista.
    - **Leire:** Alguien estaba en la grada durante un entrenamiento.
    - **Leire:** Y hacerle una foto así a alguien sin preguntarle… No me gusta. Cuenta conmigo. _[silencio 0.9 s]_
  - **Paso 4.3 · Hablar** con Bruno — «Todos dicen que ha sido Bruno. Habla con él»
    - **Bruno:** Ya. Sé lo que dicen. Que he sido yo. Siempre soy yo, ¿no?
    - _(si tienes la marca «acusaste a bruno»)_ **Bruno:** Como en el colegio. Me acusaste sin pruebas. Y tampoco fui yo.
    - ❓ **Pregunta al jugador:** ¿Qué le dices?
      - ➤ «Te creo. Pero ayúdame. ¿Sabes algo?» _(efecto: Bruno +8; empatia +1; decisión «bruno» = Confiar)_
        - **Bruno:** ¿Me crees? Vale. En el vestuario estaban enseñando el móvil de Darío. Darío Ruiz. D. R.
        - **Bruno:** No me estoy chivando. Te lo cuento. Que es distinto.
      - ➤ «Demuéstralo.» _(efecto: Bruno -4; decisión «bruno» = Dudar)_
        - **Bruno:** No hay nada. Ahora déjame en paz.
  - **Paso 4.4 · Usar** — «Busca en la pista desde dónde se hizo la foto»
    - 🖐 _Al usar «La grada de la pista»:_
      - _Narrador:_ _Subes a la grada. Desde aquí se ve exactamente el ángulo de la foto: el banquillo, la canasta, Omar merendando._
      - _Narrador:_ _En el asiento hay una pegatina del equipo de fútbol de segundo. Y alguien ha escrito con rotulador: «DR estuvo aquí»._
- **Paso 5 · Escena**
  - _En escena:_ Sara (te acompaña)
  - **Sara:** Vale. La foto se hizo aquí. DR. Darío Ruiz.
  - **Sara:** Segundo curso. Equipo de fútbol. _[silencio 0.9 s]_
  - **Sara:** El nuevo amigo de Nico. Y Nico…
  - **Sara:** Nico la compartió primero. _[silencio 0.9 s]_
  - **Sara:** Eso es lo que más me duele.
  - 🎬 **Escena al completarlo «Ins05_G6_Entra»**
    - _En escena:_ Nico
    - **Nico:** ¡[tu nombre]!
- **Paso 6 · Ir a** la pista de deporte — «Ve a la pista: Nico y Darío están en el entreno»
  - _Lugar:_ la pista de deporte · _En escena:_ Nico, Darío, Alumno, Sara (te acompaña)
- **Paso 7 · Hablar** con Nico — «Habla con Nico»
  - **Nico:** ¿Vienes a ver el entreno?
  - **Nico:** ¿Por qué me miras así?
  - ❓ **Pregunta al jugador:** ¿Cómo hablas con Nico?
    - ➤ «Hablar con Nico a solas» _(efecto: Nico +3; empatia +1; decisión «hablas nico» = Privado)_
      - **Nico:** Darío me la pasó. Todos se estaban riendo.
      - **Nico:** Quería que se rieran conmigo.
      - **Nico:** Que me vieran como uno de ellos. _[silencio 0.9 s]_
      - **Nico:** No pensé que Omar la vería. No pensé nada. Qué idiota. Omar es… Omar.
    - ➤ «Decírselo delante del equipo» _(efecto: Nico -6; valentia +1; decisión «hablas nico» = Publico)_
      - **Nico:** ¿Delante de todos? Vale. Me lo merezco. _[silencio 0.9 s]_
      - _(si en «hablas nico» elegiste «Publico»)_ **Nico:** Pero podías habérmelo dicho a mí primero.
  - _(si en «hablas nico» elegiste «Publico»)_ _Narrador:_ _Por primera vez desde que conoces a Nico, no intenta defenderse._ _[silencio 0.9 s]_
  - **Nico:** Voy a hablar con Omar. Hoy. Te lo prometo.
- **Paso 8 · Hablar** con Darío — «Habla con Darío»
  - **Darío:** ¿Qué pasa? Era una broma. Se ha hecho viral. Eso es bueno, ¿no? Omar es famoso.
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Bórrala y pídele perdón.» _(efecto: empatia +1; valentia +1; decisión «dario» = Perdon)_
      - **Tú:** Tú no la estás viviendo. Él sí.
      - **Darío:** No lo había visto así. Él no se reía. Vale. _[silencio 0.9 s]_
      - _Narrador:_ _Escribe: «Perdón. La he liado.»_
      - **Darío:** ¿Se lo mando?
    - ➤ «Se lo cuentas a Javier.» _(efecto: Javier +4; responsabilidad +2; decisión «dario» = Javier)_
      - **Javier:** Gracias por contármelo. Esto no es una broma.
      - **Javier:** Es hacer daño delante de todos. Me encargo.
      - **Javier:** Y hablaré con toda la clase. _[silencio 0.9 s]_
    - ➤ «Le devuelves la broma.» _(efecto: Omar -2; humor +1; decisión «dario» = Venganza; marca «montaje dario»)_
  - _(si en «dario» elegiste «Venganza»)_ _Narrador:_ _Lo que empezó como una broma se convierte en una competición._
  - 🎬 **Escena al completarlo «Ins05_G9_Entra»**
    - _Narrador:_ _Segundo mensaje: «El banco.»_
- **Paso 9 · Ir a** el parque — «Busca a Omar. Sara cree que sabe dónde está: en el banco del parque»
  - _Lugar:_ el parque · _En escena:_ Omar
- **Paso 10 · Hablar** con Omar — «Siéntate con Omar»
  - _(si en «promesa» elegiste «Banco»)_ **Omar:** El banco del verano. Prometimos quedar aquí.
    - 🎬 **Escena de cámara «Ins05_G10_Musica»** _(música: → Descubrimiento)_
  - _(si en «promesa» elegiste «Banco»)_ **Omar:** No pensaba que algún día lo usaría para esconderme.
  - **Omar:** Hola. Ya has visto la foto, ¿no?
  - **Omar:** Todo el mundo la ha visto. «Omar el Tragón». Ja.
  - **Omar:** Lo peor no es la foto. _[silencio 0.9 s]_
  - **Omar:** Lo peor es que Nico la compartió. Nico. _[silencio 1.5 s]_
  - ❓ **Pregunta al jugador:** ¿Qué haces?
    - ➤ «Te sientas a su lado sin decir nada.» _(efecto: Omar +8; empatia +2)_
      - **Omar:** Toma. Tragones los dos.
    - ➤ _(si en «foto» elegiste «Frenar»)_ «Borré la foto del grupo. Y no va a volver.» _(efecto: Omar +10)_
      - **Omar:** ¿Fuiste tú? Leire me dijo que alguien había plantado cara. No sabía que eras tú. Gracias.
    - ➤ «Nico está fatal. Quiere pedirte perdón.» _(efecto: Nico +3; Omar +5; responsabilidad +1)_
      - **Omar:** Que venga él. Que me lo diga él. Si lo hace…
      - **Omar:** A lo mejor le perdono.
    - ➤ _(si tienes la marca «te reiste»)_ «Perdona. Yo también me reí al principio.» _(efecto: Omar +6; valentia +1)_
      - **Omar:** Gracias por decírmelo. Duele.
      - **Omar:** Pero prefiero saberlo de ti. Mañana vuelvo.
      - **Omar:** Pero tienes que venir a buscarme. _[silencio 0.9 s]_
- **Paso 11 · Transición (pasa el tiempo)** — «Al día siguiente…»
  - ⏳ _Pantalla de transición:_ «Al día siguiente…»
  - 🎬 **Escena al completarlo «Ins05_G12_Entra»**
    - _En escena:_ Omar
    - **Omar:** ¿Listo/a? Vamos.
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
    - **Nico:** Omar. Yo… Lo siento. _[a Omar · plano PrimerPlano de Nico · en la pausa: Suelo · silencio 1.2 s]_
    - **Nico:** No hay excusa. Me pasé. Te echo de menos en el recreo. _[a Omar · plano Hombro de Omar → Nico · en la pausa: Mirar]_
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** [tu nombre] me lo dijo a la cara, sin nadie delante. Ahora te lo digo yo a ti. _[a Omar · plano PrimerPlano de Nico]_
    - _(si en «hablas nico» elegiste «Publico»)_ _(o bien)_ **Nico:** Me lo dijeron delante de todo el equipo. Me lo merecía. Ahora te lo digo yo delante de todos. _[a Omar · plano PrimerPlano de Nico]_
    - **Omar:** …Vale. _[plano PPP de Omar · en la pausa: Pensar · silencio 1.4 s]_
    - **Omar:** Pero me debes diez bocadillos. Y los eliges tú. Así sufres. _[a Nico · plano DosPlanos de Omar → Nico · gesto Happy]_
    - **Omar:** He hecho pulseras para todos. Del grupo. Por si se nos olvida quiénes somos. _[plano Medio de Omar · en la pausa: Mirar · silencio 0.6 s]_
    - _(si en «nombre grupo» elegiste «Los Imparables»)_ **Sara:** Pone «Los Imparables». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «La Patrulla Valmar»)_ _(o bien)_ **Sara:** Pone «La Patrulla Valmar». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los del Banco Azul»)_ _(o bien)_ **Sara:** Pone «Los del Banco Azul». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si en «nombre grupo» elegiste «Los Dinosaurios»)_ _(o bien)_ **Sara:** Pone «Los Dinosaurios». Con hilo de colores. Omar, son preciosas. _[plano Reaccion de Sara · gesto Happy]_
    - _(si tienes la marca «te reiste»)_ **Omar:** Esta es para ti. Te reíste, y me lo dijiste. Eso cuenta. _[plano Hombro de Tú → Omar]_
    - _(si en «foto» elegiste «Frenar» y NO tienes la marca «te reiste»)_ _(o bien)_ **Leire:** La foto dejó de moverse porque alguien escribió: «Borradla». Yo solo puse el +1. _[plano Reaccion de Leire]_
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
  - 🎬 **Escena al completarlo «Ins06_G2_Entra»**
    - _En escena:_ Sara
    - **Sara:** Ya estás aquí. Último curso. Qué raro.
- **Paso 2 · Ir a** el patio — «Sal al patio: tus amigos hablan del futuro»
  - _Lugar:_ el patio · _En escena:_ Sara, Nico, Omar, Leire (si tienes la marca «conoces a leire»), Bruno, Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Iker (si tienes la marca «iker en el grupo»)
- **Paso 3 · Varios objetivos (en cualquier orden)** — «Pregunta a tus amigos qué van a hacer (al menos tres)»
  - 🎬 **Escena al completarlo «Ins06_G4_Entra»**
    - _En escena:_ Carmen
    - **Carmen:** Pasa. Último curso. Qué rápido.
  - **Paso 3.1 · Hablar** con Sara — «Sara»
    - **Sara:** Biología. Después, doctorado.
    - **Sara:** Después, descubrir una especie nueva de hongo. Y ponerle mi nombre. Lo tengo calculado. _[silencio 0.9 s]_
    - _(si tienes el recuerdo «primer dia instituto»)_ **Sara:** ¿Te acuerdas del primer día? Mira alrededor. Y aun así me perdí.
    - **Sara:** ¿Y tú? No me digas «no sé». Bueno… Si no lo sabes, dilo. Es un dato válido.
  - **Paso 3.2 · Hablar** con Omar — «Omar»
    - **Omar:** Cocina. FP de cocina. Lola dice que si termino, me coge.
    - **Omar:** Voy a hacer la mejor tortilla de Valmar. _[silencio 0.9 s]_
    - **Omar:** Lola dice que eso es imposible. _[silencio 0.9 s]_
    - **Omar:** Da un poco de miedo, ¿sabes? Que se acabe esto.
    - **Omar:** Pero me llevo la pulsera.
  - **Paso 3.3 · Hablar** con Nico — «Nico»
    - **Nico:** Me han llamado para las pruebas del club de Altamar. Juvenil. Si no sale…
    - **Nico:** Estudio para ser entrenador.
    - _(si en «sabado» elegiste «Cumple»)_ **Nico:** Y aquel sábado viniste a mi cumple en vez de ir al club.
    - _(si en «sabado» elegiste «Cumple»)_ **Nico:** Eso tampoco se me olvida.
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** Oye… Nunca te lo he dicho bien.
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** Gracias por lo de Omar.
    - _(si en «hablas nico» elegiste «Privado»)_ **Nico:** Por decírmelo a la cara. _[silencio 0.9 s]_
    - _(si en «camino» elegiste «Negocio» y tienes la marca «redimido» y tienes el recuerdo «el cruce»)_ **Nico:** Y aquel día… Cuando soltaste la bolsa de camisetas.
    - _(si en «camino» elegiste «Negocio» y tienes la marca «redimido» y tienes el recuerdo «el cruce»)_ **Nico:** Ese día supe que seguías siendo tú.
  - **Paso 3.4 · Hablar** con Bruno — «Bruno»
    - **Bruno:** ¿Yo? Policía. No te rías.
    - **Bruno:** Inés dice que se me da bien conseguir que la gente me haga caso.
    - **Bruno:** Y que ahora sé cuándo usarlo. Y cuándo no. _[silencio 0.9 s]_
    - **Bruno:** Eso lo aprendí con vosotros.
    - **Bruno:** No se lo digas a nadie. _[silencio 0.9 s]_
    - _(si en «bruno» elegiste «Confiar»)_ **Bruno:** Me creíste cuando todos decían que la foto era mía. Eso no se me olvida.
    - _(si tienes la marca «camino delincuente»)_ **Bruno:** También por gente como Rayo.
    - _(si tienes la marca «camino delincuente»)_ **Bruno:** Y como tú últimamente. No te lo tomes a mal. _[silencio 0.9 s]_
    - _(si tienes la marca «camino delincuente»)_ **Bruno:** Quiero ser el policía que te habría gustado encontrarte. _[silencio 0.9 s]_
  - **Paso 3.5 · Hablar** con Leire — «Leire» _(solo si tienes la marca «conoces a leire»)_
    - **Leire:** Comunicación audiovisual.
    - **Leire:** En otra ciudad, probablemente. _[silencio 0.9 s]_
    - **Leire:** Mi tío dice que tengo que irme para volver con otra mirada.
    - **Leire:** Cuando llegué pensé que aquí no tendría a nadie. Ahora me cuesta irme. Qué rabia.
  - **Paso 3.6 · Hablar** con Hugo — «Hugo» _(solo si tienes la marca «hugo con el grupo»)_
    - **Hugo:** Periodismo. O escribir novelas. O las dos cosas.
    - **Hugo:** Mi primera novela será de piratas. La segunda, también.
    - _(si en «reportaje» elegiste «Permiso»)_ **Hugo:** Mi primer reportaje de verdad fue el de los murales de Vega. Contigo. Lo tengo enmarcado.
    - _(si en «reportaje» elegiste «Anonimo»)_ **Hugo:** «El artista misterioso».
    - _(si en «reportaje» elegiste «Anonimo»)_ **Hugo:** Todavía nadie sabe que era Vega. _[silencio 0.9 s]_
    - _(si en «reportaje» elegiste «Anonimo»)_ **Hugo:** Eso también es periodismo. Saber callar.
    - _(si en «reportaje» elegiste «Nombre»)_ **Hugo:** Lo de publicar el nombre de Vega…
    - _(si en «reportaje» elegiste «Nombre»)_ **Hugo:** Tenías razón en que era verdad. Pero aprendí algo. _[silencio 0.9 s]_
    - **Hugo:** La verdad también duele.
  - **Paso 3.7 · Hablar** con Mateo — «Mateo» _(solo si tienes la marca «ayudaste a mateo»)_
    - **Mateo:** Ingeniería. Mi padre es fontanero.
    - **Mateo:** Siempre dice que hay que entender cómo funcionan las cosas. _[silencio 0.9 s]_
    - **Mateo:** Pues quiero entenderlas todas. Nunca te lo he dicho…
    - **Mateo:** El primer día, cuando me ayudaste con los libros… Todo empezó ahí. _[silencio 0.9 s]_
  - **Paso 3.8 · Hablar** con Iker — «Iker» _(solo si tienes la marca «iker en el grupo»)_
    - **Iker:** Estadística. Obviamente. Según mis cálculos…
    - **Iker:** Hay un noventa y dos por ciento de probabilidades de que me encante.
- **Paso 4 · Ir a** tu aula del instituto — «Carmen te espera en su despacho (aula)»
  - _Lugar:_ tu aula del instituto · _En escena:_ Carmen
- **Paso 5 · Hablar** con Carmen — «Habla con Carmen»
  - **Carmen:** ¿Te acuerdas de la semana de las profesiones?
  - **Carmen:** Tengo tu cuaderno aquí.
  - _(si NO tienes el recuerdo «que quieres ser»)_ **Carmen:** Último curso. Vamos a ver qué te ronda la cabeza.
  - _(si en «orientacion» elegiste «Dudas»)_ **Carmen:** En primero saliste de mi despacho con más dudas que antes.
  - _(si en «orientacion» elegiste «Dudas»)_ **Carmen:** Te dije que era buena señal. _[silencio 0.9 s]_
  - _(si tienes la marca «interes medicina»)_ **Carmen:** Te vi con la doctora Nuria.
  - _(si tienes la marca «interes medicina»)_ **Carmen:** Dijiste que te veías en un hospital.
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Sofía todavía habla de tu puente de palillos.
  - _(si tienes la marca «interes ingenieria»)_ **Carmen:** Eso es ingeniería pura.
  - _(si tienes la marca «interes derecho»)_ **Carmen:** Inés dijo que escuchabas a las dos partes. Eso es derecho. O policía. O mediación.
  - _(si tienes la marca «interes economia»)_ **Carmen:** Marcos todavía habla de tu idea de las bicicletas. Economía, empresa… Lo llevas dentro.
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Tobías, Lola, Irene, Toni…
  - _(si tienes la marca «interes oficio»)_ **Carmen:** Hay profesiones que se aprenden trabajando. No son menos. Son otro camino. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «primer sueldo»)_ **Carmen:** Y tu primer trabajo de verano.
  - _(si tienes el recuerdo «primer sueldo»)_ **Carmen:** Eso también dice mucho de ti. _[silencio 0.9 s]_
  - _(si tienes la marca «camino delincuente»)_ **Carmen:** Sé lo del estadio. Y lo de Rayo.
  - _(si tienes la marca «camino delincuente»)_ **Carmen:** No te voy a sermonear.
  - _(si tienes la marca «camino delincuente»)_ **Carmen:** Solo te digo una cosa. _[silencio 0.9 s]_
  - **Carmen:** Todavía puedes elegir otro camino. Siempre se puede.
  - _(si tienes la marca «redimido»)_ **Carmen:** Y sé que saliste de algo difícil hace unos años.
  - _(si tienes la marca «redimido»)_ **Carmen:** Eso dice más de ti que cualquier nota. _[silencio 0.9 s]_
  - **Carmen:** Pero voy a decirte lo mismo que hace años.
  - **Carmen:** No tienes que acertar. Tienes que elegir. Y si te equivocas… Se cambia. _[silencio 0.9 s]_
  - **Carmen:** Nadie se queda donde empieza. Ni siquiera yo.
  - **Carmen:** Empecé estudiando química. Mírame.
- **Paso 6 · Ir a** la Universidad de Valmar — «Jornada de puertas abiertas: visita la universidad»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Sofía, Sara (te acompaña)
- **Paso 7 · Escena**
  - _(si tienes la marca «interes ingenieria»)_ **Sofía:** ¡Anda! ¡La persona de los triángulos!
  - _(si tienes la marca «interes ingenieria»)_ **Sofía:** Bienvenido/a a la jornada de puertas abiertas. _[silencio 0.9 s]_
  - _(si NO tienes la marca «interes ingenieria»)_ **Sofía:** ¡Bienvenidos! Aquí están las facultades de Medicina, Ingeniería, Derecho y Economía.
  - **Sara:** Aquí vamos a estar el año que viene. O no. Pero da igual. Hoy da gusto.
- **Paso 8 · Clase** — «Estudia para la selectividad en la biblioteca del campus»
  - _Lugar:_ la Biblioteca Universitaria · _En escena:_ Sara
- **Paso 9 · Escena**
  - _Lugar:_ tu aula del instituto · _En escena:_ Omar, Javier
  - **Omar:** Me lo he aprendido todo.
  - **Omar:** Y lo he olvidado todo en el pasillo. ¿Es normal? _[silencio 0.9 s]_
  - **Javier:** Es normal. Respirad. Nadie es su nota.
  - **Javier:** Pero hoy, por si acaso… Haced buena letra. _[silencio 0.9 s]_
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
  - 🎬 **Escena al completarlo «Ins06_G17_Entra»**
    - _En escena:_ Javier
    - **Javier:** Una segunda oportunidad no es volver al principio.
    - **Javier:** Es volver sabiendo más.
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
    - **Mamá/Papá:** ¿No puedes dormir? Yo tampoco dormía la noche antes de decidir. Ven. Hay leche con cacao. _[plano Medio de Mamá/Papá]_
    - _(si en «primer dia ins» elegiste «Acompanado»)_ **Mamá/Papá:** El primer día de instituto me pediste que te acompañara hasta la puerta. Mañana no puedo acompañarte a ningún sitio. _[plano PrimerPlano de Mamá/Papá · en la pausa: Pensar]_
    - _(si en «primer dia ins» elegiste «Solo»)_ _(o bien)_ **Mamá/Papá:** El primer día de instituto te fuiste sin mirar atrás. Ya entonces supe que esta noche iba a llegar. _[plano PrimerPlano de Mamá/Papá · en la pausa: Pensar]_
    - _(si tienes la marca «pillado»)_ **Mamá/Papá:** La última vez que salí así de noche fue para ir a buscarte a una comisaría. Prefiero esta noche. Mucho. _[plano Hombro de Tú → Mamá/Papá · gesto Sad]_
    - _(si en «meta» elegiste «Ahorro»)_ **Mamá/Papá:** Y con el dinero que ahorraste aquel verano… algo te ayudará. _[plano Medio de Mamá/Papá · gesto Happy]_
    - _(si en «sueldo» elegiste «Familia»)_ **Mamá/Papá:** Todavía me acuerdo de aquella cena que pagaste con tu primer sueldo. Postre incluido. _[plano Medio de Mamá/Papá · gesto Happy]_
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
  - 🎬 **Escena al completarlo «Ins06_G23_Entra»**
    - **Tú:** Ir a la universidad Empezar a trabajar ya
- **Paso 23 · Decisión** — «Decide qué quieres hacer al terminar el instituto»
  - ❓ **Pregunta:** Tienes 18 años y todo el futuro por delante. ¿Qué quieres hacer?
  - ➤ _(si tienes la marca «acceso 5»)_ **Opción «Ir a la universidad (vivirás en la residencia del campus; la carrera se elige allí)»** _(efecto: decisión «futuro» = Universidad)_
  - ➤ **Opción «Empezar a trabajar ya»** _(efecto: decisión «futuro» = Trabajar; decisión «estudios» = Trabajar)_
- **Paso 24 · Escena**
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** ¿A la universidad? Y a vivir en la residencia.
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** Te voy a echar de menos.
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** Y a tu ropa sucia, no tanto. _[silencio 0.9 s]_
  - **Mamá/Papá:** Allí tendrás que hacerte la compra. La comida. La cama. Todo.
  - **Mamá/Papá:** Mañana te enseño a hacer una tortilla. Por si acaso. Por si acaso, dos.
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** Con tu nota puedes elegir cualquier carrera. Cualquiera.
  - _(si en «futuro» elegiste «Universidad»)_ **Mamá/Papá:** Piénsalo bien antes de matricularte.
  - **Mamá/Papá:** ¿Trabajar ya? Es una decisión valiente.
  - **Mamá/Papá:** Y si algún día quieres estudiar… _[silencio 0.9 s]_
  - **Mamá/Papá:** Siempre estás a tiempo.
  - _(si tienes la marca «empieza a trabajar»)_ **Mamá/Papá:** Y quien te contrató aquel verano siempre dice que eres de fiar. Algo de eso habrá.
  - **Abu:** Sea lo que sea… Lo has elegido tú.
  - **Abu:** Eso es lo que importa.
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
    - **Carmen:** Nadie tiene que tenerlo todo claro hoy. Solo hay que dar el primer paso. Y si os equivocáis… se cambia. _[plano Medio de Carmen]_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Esta foto la hago yo. Con la cámara de mi abuelo. Sonríe. Nada de móviles. _[plano Medio de Leire]_
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
  - **Cosme:** Criatura. Ya no eres tan criatura.
  - **Cosme:** Pero te lo sigo llamando. _[silencio 0.9 s]_
  - **Pip:** Confirmo que la criatura ha crecido. Mucho.
  - **Cosme:** No ayudes. Te he hecho esto. No pongas esa cara. Es oficial.
  - **Pip:** No es oficial. Pero él cree que sí.
  - **Cosme:** Gracias, Pip. Por destruir el momento.
  - **Cosme:** Ahora viene la parte mala. _[silencio 0.9 s]_
  - **Cosme:** La costura del cielo se está soltando. Punto a punto. Lo dije. _[silencio 0.9 s]_
  - **Cosme:** Las costuras siempre se sueltan. Lo dijo… otro. _[silencio 0.9 s]_
  - **Pip:** El señor Cosme lleva exactamente seis años evitando decir quién. _[silencio 0.9 s]_
  - **Cosme:** Pip.
  - **Pip:** Sí, señor.
  - **Don Escamas:** Y hay más. MegaVerso ha pedido permiso para abrir una oficina en el Distrito Financiero.
  - **Cosme:** ¿MegaVerso?
  - **Don Escamas:** MegaVerso. Sigue siendo una empresa. Eso es lo peor.
  - **Don Escamas:** Todavía me llegan sus boletines.
  - **Don Escamas:** Soy de los que no se dan de baja. _[silencio 0.9 s]_
  - **Pip:** He intentado cancelar la suscripción.
  - **Pip:** Me han ofrecido un viaje a una dimensión tropical. _[silencio 0.9 s]_
  - **Cosme:** ¿Y?
  - **Pip:** He dicho que no.
  - **Cosme:** Tres sitios. Tres costuras. Necesito que vayas.
  - **Tú:** No existe una decisión de diálogo.
  - **Cosme:** Yo no puedo. Me duele. La espalda. Y el orgullo.
  - **Pip:** Sobre todo el orgullo.
  - **Cosme:** Tú llevas años viendo estas cosas.
  - **Cosme:** Ahora ya eres suficientemente mayor para reconocerlas. El medidor pita. Si encuentras algo… _[silencio 0.9 s]_
  - **Cosme:** No lo toques. Llámame. _[silencio 0.9 s]_
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Patrulla con el medidor de rarezas: tres sitios pitan»
  - 🎬 **Escena al completarlo «Saga_07_G3_Entra»**
    - _En escena:_ Pip
    - **Pip:** Consejo técnico. No deje que le hagan un jersey.
  - **Paso 2.1 · Usar** — «El parque»
    - 🖐 _Al usar «Hilos verdes que caen del cielo»:_
      - _Narrador:_ _Finísimos. Como si alguien estuviera deshaciendo un jersey allá arriba. Uno toca el suelo._ _[silencio 0.9 s]_
      - _Narrador:_ _Donde tocan el suelo…_
  - **Paso 2.2 · Usar** — «La plaza del centro»
    - 🖐 _Al usar «Una pantalla publicitaria que no estaba»:_
      - _Narrador:_ _Nadie parece verla._
  - **Paso 2.3 · Usar** — «El patio del instituto»
    - 🖐 _Al usar «Un cristal que zumba»:_
      - _Narrador:_ _Clavado en el suelo. Es uno de tus anclajes._ _[silencio 0.9 s]_
      - _(si tienes el recuerdo «coser el cielo»)_ _Narrador:_ _Lo clavaste tú._
      - _(si tienes el recuerdo «coser el cielo»)_ _Narrador:_ _Todavía tienes el barro de aquella noche en la memoria._ _[silencio 1.8 s]_
- **Paso 3 · Pelea** — «¡Hilachas sueltas por el parque! Enróllalas antes de que lo enreden todo (0/2)»
  - _Lugar:_ el parque
  - 🚨 _Si te atrapan:_ «¡Cosquillas de hilo! (Te enredan los cordones. Te desenredas junto a la fuente.)»
- **Paso 4 · Escena**
  - _Lugar:_ El garaje de Cosme
  - **Cosme:** Hilachas. La costura se deshace. Y cuando se deshace… Los hilos escapan.
  - **Don Escamas:** Como cuando se rompe un jersey.
  - **Cosme:** Sí. Pero imagina que el jersey es el universo.
  - **Don Escamas:** Entonces no quiero llevarlo puesto.
  - **Cosme:** Y has visto el anuncio. MegaVerso.
  - _(si tienes la marca «cosimo te ha visto»)_ **Cosme:** Desde que te habló a través de la costura…
  - _(si tienes la marca «cosimo te ha visto»)_ **Cosme:** Duermo con un ojo abierto. El otro también. _[silencio 0.9 s]_
  - _(si NO tienes la marca «cosimo te ha visto»)_ **Cosme:** Espero que no llegue a hablarte. Todavía no.
  - **Cosme:** Sí. De Cósimo. _[silencio 0.9 s]_
  - **Pip:** El señor Cosme acaba de admitir algo importante.
  - **Pip:** Voy a marcarlo en el calendario. _[silencio 0.9 s]_
  - **Cosme:** Pip.
  - **Pip:** Sí, señor.
  - **Cosme:** Te prometí contártelo cuando fueras mayor.
  - **Cosme:** Aún no eres tan mayor. _[silencio 0.9 s]_
  - **Cosme:** Pero Pip tiene un archivo. Algún día. _[silencio 0.9 s]_
  - **Cosme:** Ahora ya tienes permiso para estar aquí.
  - **Cosme:** Aunque técnicamente nunca te lo di. _[silencio 0.9 s]_

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
  - _Narrador:_ _El edificio no estaba aquí la última vez._
  - _Narrador:_ _Pero parece llevar años aquí._ _[silencio 0.9 s]_
  - **Agente de MegaVerso:** ¡Bienvenido/a a MegaVerso S.A.!
  - **Agente de MegaVerso:** ¿Viene por las vacaciones dimensionales? _[silencio 0.9 s]_
  - **Agente de MegaVerso:** ¿Por la tarjeta de fidelización? _[silencio 0.9 s]_
  - **Agente de MegaVerso:** ¿O por la Gran Fusión? ¡Qué adorable! Sírvase usted mismo. _[silencio 0.9 s]_
  - **Agente de MegaVerso:** Las cámaras solo graban a los adultos. _[silencio 0.9 s]_
  - **Agente de MegaVerso:** Es nuestra política de privacidad. Laboratorio… Cosme. _[silencio 0.9 s]_
  - **Agente de MegaVerso:** Un momento, por favor. _[silencio 0.9 s]_
  - **Agente de MegaVerso:** Voy a consultar con mi…
  - **Agente de MegaVerso:** …con la máquina de café. Sírvase usted mismo. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Vengo a informarme. Soy de un colegio. Trabajo de clase.» _(efecto: humor +1)_
      - **Agente de MegaVerso:** ¡Qué adorable! Sírvase usted mismo. Las cámaras solo graban a los adultos. Es nuestra política de privacidad.
    - ➤ «Enseñas la credencial de ayudante de Cosme» _(efecto: valentia +1; marca «enseñaste credencial»)_
      - **Agente de MegaVerso:** ¿Laboratorio… Cosme? …Un momento, por favor. Voy a consultar con mi… con la máquina de café. Sírvase usted mismo.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Mientras nadie mira, busca información»
  - 🎬 **Escena al completarlo «Saga_08_G3_Entra»**
    - _En escena:_ Agente de MegaVerso
    - **Agente de MegaVerso:** Que no salga. Dos segundos. Por favor.
  - **Paso 2.1 · Usar** — «Los folletos»
    - 🖐 _Al usar «Folletos de colores»:_
      - _Narrador:_ _El folleto parece una publicidad normal._
      - _Narrador:_ _Hasta que lees la letra pequeña._ _[silencio 0.9 s]_
      - _Narrador:_ _No es una empresa que quiera venderte una casa._
      - _Narrador:_ _Quiere quedarse con el lugar donde está tu casa._ _[silencio 0.9 s]_
  - **Paso 2.2 · Usar** — «El ordenador»
    - 🖐 _Al usar «Un ordenador encendido»:_
      - **Tú:** Mi graduación. Hablan de mi graduación. _[silencio 0.9 s]_
  - **Paso 2.3 · Usar** — «El mapa de la pared»
    - 🖐 _Al usar «Un mapa de Valmar en la pared»:_
      - _Narrador:_ _Tres lugares. Tus anclajes._
- **Paso 3 · Huida** — «¡Te han visto! Sal de la oficina hasta la plaza del Distrito Financiero»
  - _Lugar:_ la Plaza Financiera · _En escena:_ Robot de seguridad de MegaVerso, Agente de MegaVerso
  - 🚨 _Si te atrapan:_ «Tiene usted una llamada de ventas. Tiene usted una llamada de ventas. (Te zafas y vuelves a intentarlo.)»
- **Paso 4 · Escena**
  - _Narrador:_ _Has salido. Pero no has salido solo._
  - _Narrador:_ _Solo estuvo ahí un segundo._
  - _Narrador:_ _Pero sabía que estabas dentro._ _[silencio 0.9 s]_
  - _Narrador:_ _MegaVerso no está intentando encontrar la Grieta. Ya la encontró._
  - _Narrador:_ _Y parece saber exactamente dónde estás tú._
  - _Narrador:_ _Pero cuando escucha: «Cosme»_

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
  - **Pip:** Está nervioso/a. Buenas noches.
  - **Pip:** Estoy a punto de desobedecer una orden directa del señor Cosme. _[silencio 0.9 s]_
  - **Pip:** Es la primera vez en veintitrés años. _[silencio 0.9 s]_
  - **Pip:** Me tiemblan los tornillos.
  - **Pip:** El señor Cosme cree que le protege no contándoselo.
  - **Pip:** Yo creo que ya no le protege. _[silencio 0.9 s]_
  - **Pip:** Solo le deja a oscuras.
  - **Pip:** Y a oscuras se tropieza. _[silencio 0.9 s]_
  - _(si tienes la marca «oyo ancla»)_ **Pip:** Usted ya oyó una palabra que no debía.
  - **Pip:** «Ancla». Esta noche sabrá qué significa. _[silencio 0.9 s]_
  - **Don Escamas:** Yo voto por contarlo todo.
  - **Don Escamas:** Aunque yo siempre voto por contarlo todo. Es mi problema. _[silencio 0.9 s]_
  - **Pip:** Por una vez, estoy de acuerdo.
- **Paso 2 · Usar** — «Abre el archivo»
  - _En escena:_ Pip
  - 🖐 _Al usar «El archivo de Pip»:_
    - **Pip:** El señor Cosme escribió esas palabras. Yo añadí las últimas.
    - _Narrador:_ _Planos del Proyecto Costura._ _[silencio 0.9 s]_
    - _Narrador:_ _Antes de ser enemigos… Eran amigos._
    - _Narrador:_ _Ya has visto esta foto._
    - **Pip:** Esa es la parte que el señor Cosme nunca quiso que usted viera. Yo tampoco. Hasta hoy. _[silencio 1.8 s]_
- **Paso 3 · Usar** — «Pon la cinta en el proyector»
  - 🖐 _Al usar «Un proyector antiguo»:_
    - **Cosme:** Vamos a coser dos dimensiones un milímetro. Solo un milímetro. Para ver qué pasa.
    - **Doctor Cósimo:** Un universo mañana. Imagínatelo, Cosme. Dos Valmar en una. _[silencio 0.9 s]_
    - **Doctor Cósimo:** Todo lo mejor de las dos.
    - **Cosme:** Primero una. Luego ya veremos.
    - **Don Escamas:** Nunca entendí el batido de apio.
    - _Narrador:_ _Primero parecía una costura._
    - _Narrador:_ _Y la Grieta siguió creciendo._ _[silencio 1.8 s]_
    - **Cosme:** No.
    - _Narrador:_ _A pocas calles de allí…_
    - _Narrador:_ _alguien acababa de llegar al mundo._ _[silencio 0.9 s]_
    - **Cosme:** ¿Qué…?
    - _Narrador:_ _Algo pequeño/a. Algo nuevo._ _[silencio 0.9 s]_
    - _Narrador:_ _Algo que podía sujetarla._
    - **Pip:** La Grieta se agarró a lo único que había cerca. A usted.
    - **Cosme:** La Grieta no se abrirá del todo. Es… …un Ancla. Toda la vida. Sin que lo sepa. Se lo debo. _[silencio 1.8 s]_
- **Paso 4 · Hablar** con Cosme — «Cosme se ha despertado. Te está mirando desde la puerta»
  - _En escena:_ Cosme, Pip
  - **Cosme:** Pip. Te dije que nunca. _[silencio 0.9 s]_
  - **Pip:** Lo sé, señor. _[silencio 0.9 s]_
  - **Pip:** Y usted me dijo que el día que tuviera que elegir entre obedecerle y cuidarle… …le cuidara. _[silencio 0.9 s]_
  - **Pip:** También me lo dijo.
  - ❓ **Pregunta al jugador:** Cosme te mira. ¿Qué le dices?
    - ➤ «Llevas toda mi vida cuidándome. Gracias.» _(efecto: Cosme +12; empatia +2; marca «perdona a cosme» y «perdona cosme»)_
      - **Cosme:** No… No me des las gracias.
      - **Cosme:** La Grieta es culpa mía. Tú…
      - **Cosme:** Tú eres lo único bueno que salió de aquella noche.
      - **Cosme:** Aunque no fuera a propósito. _[silencio 0.9 s]_
    - ➤ «¿Por qué no me lo dijiste antes?» _(efecto: Cosme +4; valentia +1; marca «enfado con cosme»)_
      - **Cosme:** Porque tenías seis años.
      - **Cosme:** Y te gustaban las burbujas. _[silencio 0.9 s]_
      - **Cosme:** ¿Cómo le dices a alguien de seis años que sujeta el universo con una mano? Tienes razón.
      - **Cosme:** Debí hacerlo antes. Perdón.
      - **Cosme:** No se me dan bien los perdones.
      - **Cosme:** Se me dan bien las explosiones. _[silencio 0.9 s]_
  - **Cosme:** Lo que viste en MegaVerso…
  - _(si tienes la marca «sabe fusion»)_ **Cosme:** La Fusión que viste en su oficina. _[silencio 0.9 s]_
  - **Cosme:** Eso es lo que quiere. _[silencio 0.9 s]_
  - _(si NO tienes la marca «sabe fusion»)_ **Cosme:** Cósimo quiere la Fusión.
  - **Cosme:** Para eso necesita que sueltes el Ancla. _[silencio 0.9 s]_
  - **Cosme:** Mientras tú sigas aquí…
  - **Cosme:** La Grieta permanece cerrada. Si te vas… _[silencio 0.9 s]_
  - **Cosme:** La costura puede soltarse. _[silencio 0.9 s]_
  - **Cosme:** Y si la costura se rompe del todo…
  - **Cosme:** MegaVerso le paga el laboratorio.
  - **Cosme:** Cósimo necesita la Fusión. Y para conseguirla… …te necesita a ti. _[silencio 0.9 s]_
  - **Pip:** Tome. Es suya. Es su historia.
  - _Narrador:_ _«📼 CINTA: «LA NOCHE»»_
  - **Cosme:** Ahora ya sabes por qué siempre estaba cerca.
  - **Cosme:** Por qué aparecía cuando no me llamabas. _[silencio 0.9 s]_
  - **Cosme:** Por qué vigilaba tus cristales. _[silencio 0.9 s]_
  - **Cosme:** Y por qué nunca me fui. _[silencio 0.9 s]_
  - **Cosme:** No eras mi experimento.
  - **Cosme:** Eras mi responsabilidad. _[silencio 0.9 s]_
  - **Cosme:** Y acabaste siendo mi familia. _[silencio 0.9 s]_
  - _Narrador:_ _El protagonista ahora conoce: «Soy el Ancla.»_
  - _Narrador:_ _El momento: «A usted.»_

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
  - _Narrador:_ _Los números están ahí. Gigantes._ _[silencio 1.8 s]_
  - _Narrador:_ _Pero nadie parece verlos._ _[silencio 0.9 s]_
  - **Omar:** ¡Fiesta gratis! Confeti, refrescos, música…
  - **Omar:** Y una pantalla que dice «Fusión». ¿Fusión de qué?
  - **Omar:** ¿De sabores de helado? Espera.
  - **Omar:** ¿Tú ves algo en el cielo? _[silencio 0.9 s]_
  - **Omar:** Porque yo estoy viendo unos números enormes que antes no veía.
  - **Omar:** Desde que me contaste lo de la Grieta… Veo cosas raras. Gracias, supongo. _[silencio 0.9 s]_
  - _(si tienes la marca «sabe fusion»)_ **Tú:** Es la Fusión de las dos Valmar.
  - **Omar:** Ya no está bromeando. Entonces sí es verdad. ¿Y esos números? _[silencio 0.9 s]_
  - **Tú:** Es una cuenta atrás.
  - **Omar:** ¿Hasta cuándo?
  - **Tú:** Mi graduación. _[silencio 0.9 s]_
  - **Omar:** Vale. Entonces tenemos un problema.
  - **Nico:** ¿Qué problema?
  - **Omar:** Uno grande.
  - **Sara:** ¿Otra cosa de la Grieta?
  - **Omar:** Él/Ella dice que sí.
  - **Sara:** No puede verlo. No veo nada.
  - **Sara:** Eso no significa que no exista. _[silencio 0.9 s]_
  - **Sara:** Y eso es lo que me preocupa.
  - **Omar:** ¿Qué hacemos? ¿Plan? ¿Tienes un plan?
  - **Omar:** Dime que tienes un plan. Yo te cubro.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Sabotea la fiesta sin que te vean»
  - _En escena:_ Agente de MegaVerso, Omar (te acompaña)
  - 🎬 **Escena al completarlo «Saga_10_G3_Entra»**
    - _En escena:_ Omar
    - **Omar:** Corre. ¡Yo sabía que esto acabaría así! ¡NO FIRMES NADA! ¡Eh! ¡Por aquí! ¿Se han ido? ¡CORRE!
  - **Paso 2.1 · Usar** — «La cabina del DJ»
    - 🖐 _Al usar «La cabina del DJ de MegaVerso»:_
      - **Omar:** Esto es un poco raro. Y eso que yo bailo fatal. Mucho mejor.
      - **Omar:** Ahora parecen personas. _[silencio 0.9 s]_
      - _Narrador:_ _Durante unos segundos, la plaza vuelve a sentirse normal._
  - **Paso 2.2 · Usar** — «La taquilla de entradas»
    - 🖐 _Al usar «La taquilla de entradas para la Fusión»:_
      - **Omar:** ¿Noventa y nueve? Por fusionar universos.
      - **Omar:** Espero que al menos den comida.
      - **Omar:** Creo que la máquina ha tomado una decisión.
      - _Narrador:_ _Las entradas salen por toda la plaza._
  - **Paso 2.3 · Usar** — «La cuenta atrás»
    - 🖐 _Al usar «La cuenta atrás»:_
      - **Omar:** ¿Seguro que esto no explota? Vale. No preguntes.
      - _Narrador:_ _No era una fecha aproximada._
      - **Doctor Cósimo:** Qué maleducado. _[silencio 1.8 s]_
      - **Omar:** ¿Has visto eso?
      - **Tú:** Sí.
      - **Omar:** Vale. Definitivamente tenemos un problema.
- **Paso 3 · Pelea** — «¡Te han descubierto! Deshazte de los de MegaVerso (0/3)»
  - _En escena:_ Omar
  - 🚨 _Si te atrapan:_ «¡Oferta de fin del mundo! ¡Firme aquí! (Omar te saca de ahí a empujones.)»
- **Paso 4 · Escena**
  - _En escena:_ Omar, Nico, Sara
  - **Nico:** ¿Qué ha pasado?
  - **Sara:** Estadísticamente… Hoy han pasado demasiadas cosas raras. _[silencio 0.9 s]_
  - **Sara:** Y tú estabas en medio. Como siempre. Te lo apunto.
  - **Omar:** Está agotado. Hemos salvado una fiesta. O el mundo. No lo sé.
  - **Omar:** Pero ha sido lo mejor del curso. Oye.
  - **Omar:** Tu graduación es dentro de poco. _[silencio 0.9 s]_
  - **Omar:** ¿Eso tiene algo que ver con los números del cielo?
  - **Nico:** ¿Qué números? _[silencio 0.9 s]_
  - **Omar:** Los que tú no puedes ver.
  - **Nico:** Eso no me tranquiliza.
  - _Narrador:_ _No era una cuenta atrás para una fiesta. Ni para una venta._
  - _Narrador:_ _Ni siquiera para la Fusión._
  - _Narrador:_ _MegaVerso estaba contando los días hasta ti._ _[silencio 0.9 s]_

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
  - **Agente Cronos, de Aduanas del Tiempo:** Pequeño humano. Bueno… ya no tan pequeño/a. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Mi agenda del futuro decía que hoy hablaríamos.
  - _(si tienes el recuerdo «ventanilla aduana»)_ **Agente Cronos, de Aduanas del Tiempo:** Usted sobrevivió a tres ventanillas en un solo día.
  - _(si tienes el recuerdo «ventanilla aduana»)_ **Agente Cronos, de Aduanas del Tiempo:** Hoy le pido algo más difícil.
  - _(si tienes el recuerdo «ventanilla aduana»)_ **Tú:** ¿Qué?
  - **Agente Cronos, de Aduanas del Tiempo:** Alguien está metiendo formularios falsos en la Aduana.
  - **Agente Cronos, de Aduanas del Tiempo:** Permisos de Fusión dimensional. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Sellados con MI sello. Yo no los he sellado.
  - **Agente Cronos, de Aduanas del Tiempo:** Mi sello tiene un arañazo. Estos no.
  - **Agente Cronos, de Aduanas del Tiempo:** Si la Aduana aprueba esos permisos…
  - **Agente Cronos, de Aduanas del Tiempo:** Y contra algo legal… Ni yo puedo hacer nada. Necesito pruebas. Y alguien rápido. Confirmado. _[silencio 1.8 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Corro poco. _[silencio 0.9 s]_
- **Paso 2 · Hablar** con Funcionaria de la ventanilla — «La funcionaria de las ventanillas sabe quién entrega formularios (Correos)»
  - _Lugar:_ Correos · _En escena:_ Funcionaria de la ventanilla
  - **Funcionaria de la ventanilla:** Esa cola es para paquetes.
  - **Agente Cronos, de Aduanas del Tiempo:** Yo tengo formularios.
  - **Funcionaria de la ventanilla:** Entonces necesita la cola de formularios.
  - **Agente Cronos, de Aduanas del Tiempo:** ¿Cuál es? _[silencio 0.9 s]_
  - **Funcionaria de la ventanilla:** Esa.
  - **Agente Cronos, de Aduanas del Tiempo:** Cuando finalmente llegan a la ventanilla:
  - **Agente Cronos, de Aduanas del Tiempo:** Necesitamos información sobre unos formularios falsos.
  - **Funcionaria de la ventanilla:** ¿Formularios falsos? Hijo/a…
  - **Funcionaria de la ventanilla:** Llevo trescientos años en ventanillas.
  - **Funcionaria de la ventanilla:** Los formularios falsos huelen diferente.
  - **Funcionaria de la ventanilla:** Huelen a colonia cara. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Interesante.
  - **Funcionaria de la ventanilla:** Esta mañana una señora de gris dejó una carpeta. Ahí la tienes.
  - **Agente Cronos, de Aduanas del Tiempo:** Esa.
- **Paso 3 · Usar** — «Revisa los formularios del Consorcio»
  - 🎬 **Escena al completarlo «Saga_11_G4_Entra»**
    - _En escena:_ Agente Cronos, de Aduanas del Tiempo
    - **Agente Cronos, de Aduanas del Tiempo:** ¡Alto! ¡Recordad que yo corro poco!
    - _Narrador:_ _Otro NPC señala: «¡Van corriendo!»_
    - **Agente Cronos, de Aduanas del Tiempo:** No volveré a hacer eso. Nunca.
  - 🖐 _Al usar «Una carpeta de formularios»:_
    - **Agente Cronos, de Aduanas del Tiempo:** Ahí está. Sin S. Ni siquiera saben escribir mi nombre.
    - **Agente Cronos, de Aduanas del Tiempo:** Y aun así pretenden falsificar mi sello.
    - **Agente Cronos, de Aduanas del Tiempo:** Esto es peor de lo que pensaba.
- **Paso 4 · Persecución** — «¡La agente gris que los entrega está ahí mismo! ¡Atrápala!»
  - _En escena:_ Agente de MegaVerso, Agente Cronos, de Aduanas del Tiempo (te acompaña)
- **Paso 5 · Escena**
  - _Lugar:_ el parque · _En escena:_ Agente de MegaVerso, Agente Cronos, de Aduanas del Tiempo
  - **Agente de MegaVerso:** ¡Vale! ¡Vale! ¡Me rindo!
  - **Agente de MegaVerso:** Solo soy de atención al cliente.
  - **Agente Cronos, de Aduanas del Tiempo:** Falsificación de formulario temporal. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Treinta años de papeleo en la Aduana. Sin sello propio. _[silencio 0.9 s]_
  - **Tú:** Que ayude a pararlo todo.
  - **Agente de MegaVerso:** ¿Sin multa? _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** No he dicho eso. He dicho que tendrás una segunda oportunidad.
  - **Agente de MegaVerso:** Nadie me había ofrecido algo sin letra pequeña. Vale.
  - **Tú:** Que cumpla su castigo.
  - **Agente Cronos, de Aduanas del Tiempo:** Una respuesta perfectamente burocrática. Me gusta. _[silencio 0.9 s]_
  - **Agente de MegaVerso:** ¿Cuánto papeleo?
  - **Agente Cronos, de Aduanas del Tiempo:** Bastante. Durante cuatrocientos años he perseguido a quien se salta el tiempo. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Hoy me doy cuenta de algo. Es el Consorcio. A partir de hoy… Estoy de tu lado. Con formulario. _[silencio 0.9 s]_
  - **Agente Cronos, de Aduanas del Tiempo:** Cuando las cosas se pongan feas… Y llegaré. Pero llegaré.
  - ❓ **Pregunta al jugador:** Cronos te mira: «¿Qué opinas tú?»
    - ➤ «Que ayude a pararlo todo. Una segunda oportunidad.» _(efecto: empatia +1; marca «cronos aliado» y «gris arrepentida»)_
      - **Agente de MegaVerso:** ¿Yo? ¿Ayudar? …Nunca nadie me había ofrecido algo sin letra pequeña. Acepto. De verdad. Sin sonreír.
    - ➤ «Que cumpla su castigo. Las normas son las normas.» _(efecto: responsabilidad +1; marca «cronos aliado»)_
      - **Agente Cronos, de Aduanas del Tiempo:** Las normas son las normas. Lo diré en el tribunal. Y lo pondré en un póster.

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
  - **Cosme:** ¡Qué casualidad! Pasaba por aquí. Con mi mejor bata. Y una aguja nueva.
  - **Cosme:** Y veinte chicles, por si acaso. Casualidad total. …Vale. _[silencio 0.9 s]_
  - **Cosme:** He venido porque hoy es el día que marcaba la cuenta atrás.
  - **Cosme:** Y porque es tu graduación. Por las dos cosas. Más por la segunda. _[silencio 0.9 s]_
  - _(si tienes la marca «sabe que es ancla»)_ **Cosme:** Y como ya sabes lo que eres…
  - _(si tienes la marca «sabe que es ancla»)_ **Cosme:** Sabes por qué hoy no me separo de ti. _[silencio 0.9 s]_
  - **Omar:** ¿Ese es el vecino? ¿El de la gallina gigante? ¡Qué honor! ¿Me firma la bata?
  - **Cosme:** Me cae bien.
  - _(si tienes la marca «fiesta saboteada»)_ **Omar:** Oye… ¿Hoy no es el día de los números de la fiesta?
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Grieta_Rota»** _(música: → Descubrimiento → Tension efecto Momento)_
    - _En escena:_ Cosme, Omar, Sara, Nico, Doctor Cósimo
    - _Cámara:_ 6 planos (General, Pan, Dolly, Hombro, Reaccion)
    - 🪧 _Rótulo:_ «🌀 La costura se rompe» — Tu graduación del instituto
    - **Nico:** ¡Graduados! ¡GRA-DUA-DOS! ¡Que alguien me pellizque! _[emoción Joy]_
    - **Cosme:** No. Hoy no. Hoy es su día. _[plano Reaccion de Cosme · emoción Fear]_
    - _(si tienes el recuerdo «fiesta fin del mundo»)_ **Omar:** Los números del cielo de la fiesta… Marcaban hoy. Marcaban esto. _[plano DosPlanos de Omar → Sara]_
    - _(si NO se cumple: tienes el recuerdo «fiesta fin del mundo»)_ **Sara:** Eso no es un fenómeno meteorológico. …Es una cremallera. _[plano DosPlanos de Omar → Sara]_
- **Paso 3 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme
  - **Doctor Cósimo:** ¡Buenos días, Valmar! ¡Y enhorabuena a los graduados! Qué emocionante.
  - **Doctor Cósimo:** Me encantan las graduaciones. Hay tantos finales. Hola, Cosme. Hola, Ancla. Qué grande estás. _[silencio 0.9 s]_
  - **Doctor Cósimo:** La última vez que te vi en persona…
  - _(si tienes la marca «enseñaste credencial»)_ **Doctor Cósimo:** Y la última vez que te vi por cámara… _[silencio 1.8 s]_
  - _(si tienes la marca «enseñaste credencial»)_ **Doctor Cósimo:** Enseñabas una credencial de ayudante en mi oficina. Qué mono.
  - **Cosme:** Cósimo. Esto no es tuyo.
  - **Doctor Cósimo:** Todo es mío, Cosme. Lo será. Y tengo ayudantes. ¡Chicos!
  - 🎬 **Escena al completarlo «Saga_12_G4_Entra»**
    - _En escena:_ Nico, Cosme, Omar, Sara
    - **Omar:** Intenta ayudar aunque no sabe qué hacer. ¡Tengo un plan! ¡No tengo plan!
    - **Sara:** ¡Tienen un patrón! ¡No sé cuál es todavía!
    - **Nico:** ¡Por aquí!
    - **Cosme:** Pero uno de los drones lo separa. ¡Criatura!
- **Paso 4 · Pelea** — «¡Los drones de Cósimo! Protege a tus amigos (0/3)»
  - _En escena:_ Cosme, Omar
  - 🚨 _Si te atrapan:_ «¡Aplausos para el concursante! (Te llevan en volandas y te sueltan en la otra punta del patio.)»
- **Paso 5 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme, Omar, Sara
  - **Doctor Cósimo:** Bravo. Bravísimo. Sabes pelear. Te lo enseñó él, ¿no? _[silencio 0.9 s]_
  - **Doctor Cósimo:** Siempre fue un buen profesor. Por eso me lo llevo.
  - **Cosme:** No. ¡Criatura! ¡No sueltes el Ancla!
  - **Cosme:** ¡Pase lo que pase, quédate en esta Valmar! ¡Pip sabe qué hacer!
  - _(si tienes la marca «va a la universidad»)_ **Doctor Cósimo:** Nos vemos en la universidad, Ancla. _[silencio 0.9 s]_
  - _(si NO tienes la marca «va a la universidad»)_ **Doctor Cósimo:** Nos vemos pronto, Ancla. _[silencio 0.9 s]_
  - **Omar:** Vale. Ahora sí que me lo tienes que contar todo. Todo. _[silencio 0.9 s]_
  - _Narrador:_ _Añadir: «El día que Cósimo se llevó a Cosme»_
  - **Omar:** Ya no puede comportarse como si todo fuera una aventura divertida.
  - **Doctor Cósimo:** Seguro. Eso lo hace más inquietante.
  - **Omar:** Este es su primer gran cambio. Vamos a buscarlo.

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
  - 🎬 **Escena al completarlo «Uni01_G6_7»**
    - _En escena:_ Pip
    - _Cámara:_ 1 planos
    - **Pip:** Necesito hablar contigo. Segundo mensaje. Es sobre Cosme.
    - **Pip:** No quería hacerlo durante tu graduación.
    - **Pip:** Pero ya no puedo esperar.
    - **Pip:** Hola, criatura. Perdón.
    - **Pip:** ¿Cómo ha ido tu primer día?
    - **Pip:** Cosme estaría orgulloso.
    - **Pip:** He encontrado algo en el garaje.
    - **Pip:** Algo que dejó preparado antes de desaparecer.
    - **Tú:** ¿Qué?
    - **Pip:** No puedo decírtelo por teléfono. Ven cuando puedas. Y… Feliz primer día.

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
  - **Iván:** Ah. Soy Iván. No ronco.
  - **Iván:** ¿Tú has vivido siempre por aquí? ¿Quién es Cosme? Vale.
  - **Iván:** Cada uno tiene sus cosas. _[silencio 0.9 s]_
  - **Iván:** Tengo una pregunta importante.
  - **Iván:** ¿Qué comida de aquí es segura? Bueno. _[silencio 0.9 s]_
  - **Iván:** Ya es tarde para averiguarlo. _[silencio 0.9 s]_
  - **Iván:** Buenas noches. Supongo.
  - **Iván:** ¿Sabes qué es lo raro?
  - **Iván:** Hoy conocíamos a un montón de gente. Y aun así… Estamos aquí los dos. _[silencio 0.9 s]_
  - **Iván:** Supongo que esto es independizarse. Buenas noches. _[silencio 0.9 s]_
  - _Narrador:_ _Pip: «Perdona la hora.»_
  - _Narrador:_ _Pip: «Necesito que vengas al garaje.»_ _[silencio 0.9 s]_
  - _Narrador:_ _Pip: «He encontrado la caja de Cosme.»_
  - _Narrador:_ _Pip: «Y no estaba vacía.»_ _[silencio 0.9 s]_
  - _Narrador:_ _Pip: «No vengas solo/a si no quieres.» Pip: «Pero ven.»_ _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué aportas a la cena?
    - ➤ «La tortilla que te enseñó tu familia» _(efecto: Candela +4; Iván +4; marca «sabe cocinar»)_
      - **Iván:** …¿Esto lo has hecho TÚ? _[plano PrimerPlano de Iván · en la pausa: Piensa · silencio 1.0 s]_
      - **Iván:** Me caso con esta tortilla. Bueno, no. Pero casi.
    - ➤ «Tu último táper de casa, para compartir» _(efecto: Candela +3; Iván +3; empatia +1)_
      - **Candela:** Sabe a casa. _[plano PrimerPlano de Candela · silencio 0.8 s]_
      - **Candela:** …Perdón. Me he emocionado con unas lentejas. Es el primer día. _[en la pausa: Baja]_
    - ➤ «Pan con pan. Es lo que hay» _(efecto: humor +1)_
      - **Iván:** El famoso bocadillo de pan. Clásico de primero. El año que viene serás un chef. O no.
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
  - 🎬 **Escena al completarlo «Adu01_G2_Entra»**
    - **Tú:** No es la casa de mis padres. Ni la de mis abuelos.
    - **Tú:** Es la primera casa que es completamente mía.
- **Paso 2 · Acción del jugador** — «Busca una casa libre (cartel «Se vende») y quédatela: vas a necesitar tu propio sitio» _(solo si NO tienes la marca «tiene hogar»)_
- **Paso 3 · Ir a** [lugarpracticas de tu carrera] — «Primer día de trabajo: ve donde hiciste las prácticas» _(solo si tienes la marca «graduado»)_
  - _Lugar:_ [lugarpracticas de tu carrera] · _En escena:_ Doctora Nuria (si en «estudios» elegiste «Medicina» y tienes la marca «graduado»), Sofía (si en «estudios» elegiste «Ingenieria» y tienes la marca «graduado»), Montse (si en «estudios» elegiste «Derecho» y tienes la marca «graduado»), Ignacio (si en «estudios» elegiste «Economia» y tienes la marca «graduado»), Chef Lola (si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»), Paco (si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»), Ernesto (si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)
  - 🎬 **Escena al completarlo «Adu01_G4_Entra»**
    - _En escena:_ Chef Lola
    - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** ¡Ahí estás!
- **Paso 4 · Ir a** la Cafetería Central — «Lola quiere hablar contigo en la cafetería» _(solo si en «empleo» elegiste «Barista» y NO tienes la marca «graduado»)_
  - _Lugar:_ la Cafetería Central
  - 🎬 **Escena al completarlo «Adu01_G5_Entra»**
    - _En escena:_ Paco
    - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Hmm. Has venido. Bien.
- **Paso 5 · Ir a** el supermercado — «Paco quiere hablar contigo en el supermercado» _(solo si en «empleo» elegiste «Reponedor» y NO tienes la marca «graduado»)_
  - _Lugar:_ el supermercado
  - 🎬 **Escena al completarlo «Adu01_G6_Entra»**
    - _En escena:_ Ernesto
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** ¡Hombre! Justo a tiempo.
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** Acabo de clasificar tu calle.
- **Paso 6 · Ir a** Correos — «Ernesto quiere hablar contigo en Correos» _(solo si en «empleo» elegiste «Repartidor» y NO tienes la marca «graduado»)_
  - _Lugar:_ Correos
- **Paso 7 · Cinemática**
  - _Lugar:_ [lugarpracticas de tu carrera]
  - 🎬 **Cinemática «Adu01_PrimerDia»** _(música: → Descubrimiento)_
    - _En escena:_ Doctora Nuria, Sofía, Montse, Ignacio, Chef Lola, Paco, Ernesto
    - _Cámara:_ 8 planos (General, Reaccion)
    - _(si en «estudios» elegiste «Medicina»)_ **Doctora Nuria:** Hospital funcionando. Enfermeros y pacientes moviéndose. Ven. Hay papeles.
    - _(si en «estudios» elegiste «Medicina» y NO tienes la marca «llegas tarde contrato»)_ **Doctora Nuria:** ¡Mira quién ha llegado! Y en hora.
    - _(si en «estudios» elegiste «Medicina» y NO tienes la marca «llegas tarde contrato»)_ **Doctora Nuria:** Eso aquí ya es medio diagnóstico.
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «llegas tarde contrato»)_ **Doctora Nuria:** Las ocho y veinte.
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «llegas tarde practicas»)_ **Doctora Nuria:** Tarde a las prácticas. Tarde al contrato.
    - _(si en «estudios» elegiste «Medicina» y tienes la marca «llegas tarde practicas»)_ **Doctora Nuria:** Empiezo a pensar que es una tradición.
    - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** Justo a tiempo. Como un engranaje recién engrasado.
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «llegas tarde contrato»)_ **Sofía:** Veinte minutos tarde.
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «llegas tarde practicas»)_ **Sofía:** Tarde a las prácticas. Tarde hoy.
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «llegas tarde practicas»)_ **Sofía:** Si fueras un puente, ya estaría revisando tus cálculos.
    - _(si en «estudios» elegiste «Ingenieria»)_ **Sofía:** Hay un ordenador. Esto lleva tu nombre.
    - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Buenos días. Puntual. Me gusta.
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «llegas tarde contrato»)_ **Montse:** Las nueve y veinte. No voy a levantar la voz.
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «llegas tarde contrato»)_ **Montse:** Tampoco lo voy a olvidar.
    - _(si en «estudios» elegiste «Derecho» y tienes la marca «llegas tarde practicas»)_ **Montse:** Esta es la segunda.
    - _(si en «estudios» elegiste «Derecho»)_ **Montse:** Quiero que leas esto despacio.
    - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Puntual al minuto.
    - _(si en «estudios» elegiste «Economia» y tienes la marca «llegas tarde contrato»)_ **Ignacio:** Veinte minutos tarde.
    - _(si en «estudios» elegiste «Economia» y tienes la marca «llegas tarde practicas»)_ **Ignacio:** Dos retrasos en dos primeros días.
    - _(si en «estudios» elegiste «Economia» y tienes la marca «llegas tarde practicas»)_ **Ignacio:** Si esto fuera una gráfica…
    - _(si en «estudios» elegiste «Economia» y tienes la marca «llegas tarde practicas»)_ **Ignacio:** Me preocuparía la tendencia.
    - _(si en «estudios» elegiste «Economia»)_ **Ignacio:** Por si acaso.
    - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Primero ayudante.
    - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Pasillo tres. Perfecto. Pasillo cuatro. También. Eso me gusta.
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** Conoces Valmar. Ahora vas a conocerla calle por calle.
- **Paso 8 · Escena**
  - **Doctora Nuria:** Mándame veinte currículums.
  - **Doctora Nuria:** Y llámame cuando lo hayas hecho. _[silencio 0.9 s]_
- **Paso 9 · Cinemática**
  - 🎬 **Cinemática «Adu01_Firma»** _(música: → Intima)_
    - _En escena:_ Doctora Nuria, Sofía, Montse, Ignacio, Chef Lola, Paco, Ernesto
    - _Cámara:_ 1 planos (Inserto)
    - **Tú:** Mi nombre.
    - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Encargado/a. Bien.
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** Jefe/a de ruta. Ahora te aprenderás los nombres de los perros.
- **Paso 10 · Clase** — «Tu primer día como profesional» _(solo si tienes la marca «graduado»)_
- **Paso 11 · Escena** _(solo si tienes la marca «graduado»)_
  - ❓ **Pregunta al jugador:** ¿Cómo lo afrontas?
    - ➤ «Pido consejo cuando dudo.» _(efecto: responsabilidad +1; decisión «primer caso» = Consejo)_
    - ➤ «Me lanzo: sé más de lo que creo.» _(efecto: valentia +1; decisión «primer caso» = Lanzarse)_
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
    - _(si en «empleo» elegiste «Barista»)_ **Omar:** ¡Encargado/a! Ya puedo decir que mi jefe es mi amigo.
    - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Aquel verano tiraste una bandeja entera.
    - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Y viniste a decírmelo. Por eso estás aquí.
    - _(si en «empleo» elegiste «Reponedor»)_ **Paco:** Pasillo tres. Perfecto. Pasillo cuatro. Perfecto. Muy bien.
    - _(si en «empleo» elegiste «Repartidor»)_ **Ernesto:** Ni una carta perdida. Y el perro del catorce te ha movido la cola.
- **Paso 16 · Transición (pasa el tiempo)** — «Final de mes…»
  - ⏳ _Pantalla de transición:_ «Final de mes…»
- **Paso 17 · Cinemática**
  - 🎬 **Cinemática «Adu01_Buzon»** _(música: → Intima)_
    - _Cámara:_ 1 planos (Medio)
    - **Tú:** Primer sueldo completo. Entero.
    - **Tú:** Nadie me avisó de que ser adulto/a venía con buzón.
- **Paso 18 · Escena**
  - ❓ **Pregunta al jugador:** ¿Qué haces con las facturas?
    - ➤ «Pagarlas ya, todas» _(efecto: responsabilidad +1; decisión «facturas» = Pagar)_
      - **Tú:** Pagado. El sueldo ha adelgazado bastante. Pero esta noche duermo tranquilo/a.
    - ➤ «Dejarlas para la semana que viene» _(efecto: decisión «facturas» = Luego; marca «factura pendiente»)_
      - **Tú:** Las dejo en la mesa. Encima, una planta. Así no se ven. Problema resuelto. Seguro.
    - ➤ «Hacer un presupuesto: ¿cuánto entra y cuánto sale?» _(efecto: curiosidad +1; decisión «facturas» = Presupuesto)_
      - **Tú:** Mejor pido ayuda. En el banco está Ignacio, el de los números.
  - 🎬 **Escena al completarlo «Adu01_G19_Entra»**
    - _En escena:_ Ignacio
    - **Ignacio:** ¡La persona de los números!
- **Paso 19 · Ir a** el Banco Valmar — «Ve al banco: Ignacio te ayuda a hacer tu primer presupuesto» _(solo si en «facturas» elegiste «Presupuesto»)_
  - _Lugar:_ el Banco Valmar · _En escena:_ Ignacio
- **Paso 20 · Escena** _(solo si en «facturas» elegiste «Presupuesto»)_
  - **Ignacio:** Las facturas, primero.
  - **Ignacio:** Los imprevistos siempre llegan. Solo cambia cuándo. _[silencio 0.9 s]_
- **Paso 21 · Escena**
  - **Mamá/Papá:** ¿Qué tal el primer mes? ¿Has comido bien? No lo puedo evitar. Oye…
  - **Mamá/Papá:** Nada grave, creo. Pero te echa de menos. ¿Vale? Abu quiere verte. _[silencio 1.8 s]_

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
  - **Tú:** Sí. ¿Qué pasa? ¿Qué le ha pasado? ¿Dónde está? Voy para allá. ¿Su planta? Voy.
- **Paso 3 · Ir a** el hospital — «Ve al hospital: Abu está allí»
  - _Lugar:_ el hospital · _En escena:_ Abu, Doctora Nuria, Mamá/Papá
- **Paso 4 · Cinemática**
  - 🎬 **Cinemática «Adu02_Hospital»** _(música: → Intima)_
    - _En escena:_ Abu, Doctora Nuria, Mamá/Papá
    - _Cámara:_ 1 planos (General)
    - **Doctora Nuria:** Llegas rápido.
    - **Tú:** ¿Cómo está?
    - **Doctora Nuria:** Asustado/a. Pero entero.
    - **Doctora Nuria:** Y preocupado por una planta.
    - **Abu:** Mira quién ha venido.
    - **Tú:** ¿Estás bien?
    - **Abu:** Mejor que la planta. Ella sí que no sabe defenderse sola.
    - **Doctora Nuria:** No hay nada roto.
    - **Abu:** Te lo dije.
    - **Doctora Nuria:** Te has caído por las escaleras.
    - **Abu:** Las escaleras también tienen la culpa.
    - **Doctora Nuria:** Necesita descansar.
    - **Abu:** Eso llevo haciendo toda la mañana.
    - **Doctora Nuria:** Llevas intentando levantarte tres veces.
    - **Abu:** Bueno… descansaré mejor.
- **Paso 5 · Hablar** con Abu — «Siéntate con Abu»
  - **Abu:** Así que ya tienes trabajo.
  - **Tú:** Sí.
  - **Abu:** Y casa.
  - **Tú:** Más o menos.
  - **Abu:** Ya no eres un niño/una niña. Aunque para mí…
  - **Abu:** Siempre tendrás un poco de eso.
  - _(si en «estudios» elegiste «Medicina»)_ **Abu:** ¿Y tú querías acabar como Nuria?
  - _(si en «estudios» NO elegiste «Medicina»)_ **Abu:** ¿Así que finalmente encontraste tu camino?
  - _(si tienes el recuerdo «primer dia uni»)_ **Abu:** ¿Sigues llevando el reloj?
  - **Abu:** Hace mucho que no veo el mar. Quiero volver. Contigo.
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
  - **Tú:** ¿Son las del coche?
- **Paso 9 · Escena** _(solo si en «viaje abu» elegiste «Bus»)_
  - _Lugar:_ la parada del autobús · _En escena:_ Abu
  - **Abu:** Pensaba que llegarías tarde.
  - **Tú:** Llevo cinco minutos aquí.
  - **Abu:** Entonces has aprendido.
  - **Abu:** Yo cogía este cuando tenía tu edad.
  - **Tú:** ¿El mismo?
  - **Abu:** No creo. Pero espero que tenga los mismos recuerdos.
- **Paso 10 · Ir a** la parada del autobús — «Recoge a Abu en la parada del autobús» _(solo si en «viaje abu» elegiste «Bus»)_
  - 🎬 **Escena al completarlo «Adu02_G11_Entra»**
    - _En escena:_ Abu
    - **Abu:** Ahí conocí a tu mamá/papá.
    - **Abu:** Dependiendo de los datos de la historia.
    - **Abu:** Pero eso es otra historia.
- **Paso 11 · Acción del jugador** — «Coge el autobús a Playa Dorada con Abu» _(solo si en «viaje abu» elegiste «Bus»)_
  - _En escena:_ Abu (te acompaña)
- **Paso 12 · Ir a** Playa Dorada — «Llega a la playa con Abu»
  - _Lugar:_ Playa Dorada
- **Paso 13 · Cinemática**
  - _En escena:_ Abu
  - 🎬 **Cinemática «Adu02_Orilla»** _(música: → Intima)_
    - _En escena:_ Abu
    - _Cámara:_ 1 planos (Pan)
    - **Abu:** Huele igual. Aunque supongo que soy yo el que ha cambiado. Gracias.
    - **Abu:** Ahora eres tú quien me ayuda a mí.
- **Paso 14 · Escena**
  - **Abu:** Aquí conocí a la persona más importante de mi vida.
  - **Tú:** ¿mamá/papá?
  - **Abu:** No. Tú. Cuando naciste vine aquí. Necesitaba pensar.
  - **Abu:** Y pensé que algún día te traería. Mira. Ya has llegado. _[silencio 0.9 s]_
- **Paso 15 · Usar** — «Coge una concha para Abu»
  - 🖐 _Al usar «Una concha en la arena»:_
    - **Tú:** Toma.
    - **Abu:** No. Es para ti.
    - **Tú:** ¿Por qué?
    - **Abu:** Para que vuelvas. Siempre hace falta un motivo para volver.
- **Paso 16 · Escena**
  - **Abu:** Prométeme una cosa.
  - **Tú:** La que quieras.
  - **Abu:** No. Una que puedas cumplir.
  - **Abu:** Aparecen las tres opciones.
  - **Abu:** Entonces aquí te esperaré.
  - **Tú:** Hacer cosas bonitas con tu vida.
  - **Abu:** Eso es mucho más difícil. Por eso me gusta.
  - **Abu:** Eso nunca pasa de moda.
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
  - 🎬 **Escena al completarlo «Adu02_G17»** _(música: TemaValmar efecto Momento)_
    - _En escena:_ Abu
    - _Cámara:_ 1 planos
    - **Abu:** ¿Sabes qué es lo malo de hacerse mayor?
    - **Tú:** ¿Qué?
    - **Abu:** Que uno empieza a entender lo rápido que pasa todo.
    - **Abu:** Por eso hay que estar presente. Mientras estás.

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
  - 🎬 **Escena al completarlo «Adu03_G1_Fin»**
    - _En escena:_ Omar
    - **Omar:** Otro mensaje inmediatamente después:
    - **Omar:** ¿Dónde estás? Esto es importante.
    - **Omar:** Bueno, para mí es importante.
    - _Narrador:_ _«OMAR: VEN.»_
- **Paso 2 · Ir a** la Cafetería Central — «Omar te ha escrito: «VEN YA. NOTICIÓN.»»
  - _Lugar:_ la Cafetería Central · _En escena:_ Omar, Chef Lola
- **Paso 3 · Escena**
  - **Chef Lola:** Me jubilo.
  - **Tú:** ¿Qué? _[silencio 0.9 s]_
  - **Chef Lola:** Cuarenta años detrás de esta barra.
  - **Chef Lola:** Creo que ya me toca ver la playa sin tener que servirle una tortilla a nadie.
  - **Omar:** Y me la deja a mí. A mí. La cafetería.
  - **Chef Lola:** Sí, Omar.
  - **Omar:** Todavía no me acostumbro.
  - **Chef Lola:** Yo tampoco.
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Primero fuiste mi mejor ayuda de verano.
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Ahora él es quien se queda. _[silencio 0.9 s]_
  - _(si en «empleo» elegiste «Barista»)_ **Chef Lola:** Supongo que algo hice bien.
  - **Chef Lola:** ¿Te acuerdas?
  - _(si tienes el recuerdo «primer dia cole»)_ **Chef Lola:** Entonces erais niños. Ahora sois adultos. No sé cuándo ocurrió.
- **Paso 4 · Varios objetivos (en cualquier orden)** — «Invita al grupo a la inauguración (al menos tres)»
  - _Lugar:_ el Estadio Altamar · _En escena:_ Nico, Sara, Bruno, Leire (si tienes la marca «conoces a leire»), Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»)
  - **Paso 4.1 · Hablar** con Nico — «Nico (estadio de Altamar)»
    - **Nico:** ¡[tu nombre]! Mira esto. Primer equipo. Firmé el mes pasado.
    - _(si en «capsula» elegiste «Prediccion»)_ **Nico:** ¿Te acuerdas de la cápsula? La tengo enmarcada.
    - _(si en «capsula» elegiste «Prediccion»)_ **Tú:** ¿En serio?
    - _(si en «capsula» elegiste «Prediccion»)_ **Nico:** Decía que sería futbolista. Y mira. ¿Omar?
    - _(si en «capsula» elegiste «Prediccion»)_ **Nico:** Tengo como diez bocadillos pendientes. Voy.
  - **Paso 4.2 · Hablar** con Sara — «Sara (universidad)»
    - **Sara:** ¡[tu nombre]! Espera. No toques eso. Ahora sí.
    - **Sara:** He descubierto una especie nueva de hongo.
    - **Sara:** Le han puesto mi nombre. Es diminuto. Pero precioso. ¿Todos? _[silencio 0.9 s]_
    - **Tú:** Todos los que podamos reunir.
    - **Sara:** Entonces iré. Y él también.
  - **Paso 4.3 · Hablar** con Bruno — «Bruno (comisaría)»
    - **Bruno:** Agente Bruno. Para servirle.
    - **Tú:** Nunca pensé verte aquí. _[silencio 0.9 s]_
    - **Bruno:** Yo tampoco. Ahora paso el día ayudando a gente y buscando gatos.
    - _(si tienes la marca «detenido»)_ **Bruno:** Hace un tiempo te puse las esposas.
    - _(si tienes la marca «detenido»)_ **Bruno:** Y ahora me invitas a una fiesta. La vida es rara. _[silencio 0.9 s]_
    - _(si tienes la marca «detenido»)_ **Bruno:** Después de todo lo del colegio…
    - _(si tienes la marca «detenido»)_ **Bruno:** Gracias por invitarme. _[silencio 0.9 s]_
    - _(si en «adios bruno» elegiste «DeCero»)_ **Bruno:** Empezamos de cero, ¿no? Pues esto es el diez.
  - **Paso 4.4 · Hablar** con Leire — «Leire (el cine)» _(solo si tienes la marca «conoces a leire»)_
    - _(si tienes la marca «conoces a leire»)_ **Leire:** ¡Quietos! No puede ser. Tú.
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Mi primer documental se estrena el mes que viene. Estáis todos dentro.
    - **Tú:** ¿Sin permiso?
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Sí. Lo siento. Bueno… No lo siento.
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Entonces llevaré esto.
  - **Paso 4.5 · Hablar** con Hugo — «Hugo (biblioteca del campus)» _(solo si tienes la marca «hugo con el grupo»)_
    - **Hugo:** Mira. Mi primera novela. Piratas. Obviamente. Ya. Me emociono yo solo. Voy.
  - **Paso 4.6 · Hablar** con Mateo — «Mateo (oficinas del distrito financiero)» _(solo si tienes la marca «ayudaste a mateo»)_
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Hola. Me alegro de verte.
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»)_ **Mateo:** Estoy en el proyecto de la pasarela del río.
    - _(si en «estudios» elegiste «Ingenieria» y tienes la marca «ayudaste a mateo»)_ **Mateo:** ¿Te acuerdas de tu idea de los amortiguadores? Funciona.
    - _(si tienes la marca «ayudaste a mateo» y en «estudios» NO elegiste «Ingenieria»)_ **Mateo:** Diseño puentes. Mi padre dice que soy el fontanero más caro de la historia. La fiesta de Omar…
    - _(si tienes la marca «ayudaste a mateo» y en «estudios» NO elegiste «Ingenieria»)_ **Mateo:** Claro que voy. Todo empezó aquel primer día.
- **Paso 5 · Ir a** el colegio — «Invita también a Lucía: ahora es la directora del colegio»
  - _Lugar:_ el colegio · _En escena:_ Profe Lucía
- **Paso 6 · Hablar** con Profe Lucía — «Habla con Lucía»
  - **Profe Lucía:** ¡[tu nombre]! Madre mía. Ahora soy directora.
  - **Profe Lucía:** Tengo despacho y todo.
  - **Profe Lucía:** Hay una fotografía antigua. Cuéntame.
  - **Profe Lucía:** ¿Qué ha sido de tu vida? _[silencio 0.9 s]_
  - _(si en «estudios» elegiste «Medicina» y en «sueno infancia» elegiste «Medicina»)_ **Profe Lucía:** Querías salvar vidas. Y ahora trabajas en un hospital.
  - _(si en «estudios» elegiste «Ingenieria» y en «sueno infancia» elegiste «Ingenieria»)_ **Profe Lucía:** Querías inventar cosas que no existían. Y ahora las diseñas.
  - _(si en «estudios» elegiste «Derecho» y en «sueno infancia» elegiste «Derecho»)_ **Profe Lucía:** Querías defender a quien no podía hacerlo.
  - _(si en «estudios» elegiste «Economia» y en «sueno infancia» elegiste «Economia»)_ **Profe Lucía:** Querías tener tu propio negocio.
  - **Profe Lucía:** Pero te voy a decir una cosa.
  - **Profe Lucía:** No pasa nada si algún día cambias de idea.
  - **Profe Lucía:** Lo importante es que la vida que tengas sea tuya. _[silencio 0.9 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Gracias por aquel primer día. Y por todos los demás.» _(efecto: Profe Lucía +10)_
      - **Profe Lucía:** Venga. Que me haces llorar delante de los alumnos.
    - ➤ «¿Puedo venir a contarle a tus alumnos lo que hago?» _(efecto: Profe Lucía +8; marca «charla colegio»)_
      - **Profe Lucía:** Me encantaría. Aunque prepárate.
      - **Profe Lucía:** Los niños preguntan “¿por qué?” cada treinta segundos. Y la fiesta de Omar… No me la pierdo. _[silencio 0.9 s]_
  - 🎬 **Escena al completarlo «Adu03_G7_Entra»**
    - _En escena:_ Omar
    - **Omar:** ¡Has vuelto! Perfecto. No perfecto. Caos. Necesito ayuda.
- **Paso 7 · Ir a** la Cafetería Central — «Vuelve a la cafetería: Omar necesita ayuda en la cocina»
  - _Lugar:_ la Cafetería Central · _En escena:_ Omar, Chef Lola
  - 🎬 **Escena al completarlo «Adu03_G8_Entra»**
    - _En escena:_ Omar
    - **Omar:** Perfecta. Casi me haces sentir inútil. Está bien. Bueno. Está viva. No pasa nada.
    - **Omar:** Nadie tiene por qué saberlo.
- **Paso 8 · Minijuego** — «La tortilla perfecta»
  - 🎮 _Cómo se juega:_ Dale la vuelta en el momento justo
- **Paso 9 · Escena**
  - _En escena:_ Omar, Chef Lola, Nico, Sara, Bruno, Leire (si tienes la marca «conoces a leire»), Hugo (si tienes la marca «hugo con el grupo»), Mateo (si tienes la marca «ayudaste a mateo»), Profe Lucía, Mamá/Papá
  - **Chef Lola:** Mirad esto. Llena. Todos. Cuarenta años aquí.
  - **Chef Lola:** He visto crecer a medio Valmar. _[silencio 0.9 s]_
  - **Chef Lola:** Y a vosotros, enteros. Cuida la cafetería. Y cuida a esta gente.
  - **Chef Lola:** La gente es lo único que no se puede comprar con una caja registradora.
  - _(si tienes la marca «tortilla perfecta»)_ **Omar:** La tortilla de hoy la ha hecho [tu nombre]. Perfecta.
  - _(si NO tienes la marca «tortilla perfecta»)_ **Omar:** La tortilla de hoy la ha hecho [tu nombre].
  - _(si NO tienes la marca «tortilla perfecta»)_ **Omar:** Se le ha roto un poco. Nadie lo va a notar. Vale.
  - _(si NO tienes la marca «tortilla perfecta»)_ **Omar:** Todos lo vais a notar.
  - **Omar:** Y yo… Sin vosotros no habría abierto nada. Ni la cafetería.
  - **Omar:** Ni aquel bocadillo del primer día. Gracias. Ya está. No lloro.
  - **Sara:** No hay cebolla.
  - **Omar:** Sara.
- **Paso 10 · Cinemática**
  - 🎬 **Cinemática «Adu03_Foto»** _(vuelo de cámara, 7 s, 1 planos; música: efecto Momento)_
    - 🪧 _Rótulo:_ «📸 Todos otra vez» — La Cafetería de Omar
  - 🎬 **Escena al completarlo «Adu03_G10»** _(música: efecto Momento)_
    - _En escena:_ Leire
    - _Cámara:_ 1 planos
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Quietos. Flash.
- **Paso 11 · Transición (pasa el tiempo)** — «Esa noche…»
  - ⏳ _Pantalla de transición:_ «Esa noche…»
  - 🎬 **Escena al completarlo «Adu03_G11_Fin»**
    - _En escena:_ Nico, Omar, Sara
    - **Nico:** Parque.
    - **Omar:** Banco.
    - **Sara:** Ven.
    - **Nico:** ¡Por fin! Te hemos guardado sitio. Bueno. Medio sitio.
- **Paso 12 · Ir a** el parque — «Ve al banco del parque: el grupo te espera»
  - _Lugar:_ el parque · _En escena:_ Omar, Nico, Sara, Leire (si tienes la marca «conoces a leire»), Mateo (si tienes la marca «ayudaste a mateo»), Hugo (si tienes la marca «hugo con el grupo»)
- **Paso 13 · Cinemática**
  - 🎬 **Cinemática «Adu03_Banco»** _(música: → Intima)_
    - _En escena:_ Omar, Nico, Sara, Leire, Mateo, Hugo
    - _Cámara:_ 1 planos (General)
    - **Omar:** Apretaos. A los diez años cabíamos todos. Y sobraba bocadillo.
    - **Sara:** Técnicamente hemos crecido un cuarenta por ciento. El banco, cero.
    - _(si tienes la marca «conoces a leire»)_ **Leire:** Quietos. Esta toma es buena.
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Yo aquí. Como el primer día.
    - _(si tienes la marca «ayudaste a mateo»)_ **Mateo:** Así no se me caen las cosas.
- **Paso 14 · Escena**
  - _(si tienes la marca «despedido»)_ **Nico:** Y lo del trabajo… Que te den otro. Uno mejor.
  - _(si tienes la marca «ascendido»)_ **Omar:** Y con ascenso. Hoy invitas tú.
  - _(si tienes el recuerdo «atardecer con abu»)_ **Sara:** ¿Y tu abu? ¿Fuisteis al mar?
  - _(si tienes el recuerdo «atardecer con abu»)_ **Tú:** Sí. Le prometí volver.
  - _(si tienes el recuerdo «atardecer con abu»)_ **Nico:** Entonces volverás.
  - _(si tienes el recuerdo «primer grupo»)_ **Nico:** ¿Os acordáis del nombre que nos pusimos?
  - _(si tienes el recuerdo «primer grupo»)_ _Narrador:_ _TODOS: «¡[nombre del grupo]!»_
  - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Lo hemos dicho todos a la vez. Estadísticamente…
  - _(si tienes el recuerdo «primer grupo»)_ **Nico:** No.
  - _(si tienes el recuerdo «primer grupo»)_ **Sara:** Amistad.
  - **Omar:** Deberíamos prometer otra cosa.
  - **Nico:** ¿Otra?
  - **Omar:** Una última. Aparecen tres opciones.
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
  - **Pip:** Hola, criatura. No sabía cómo recibirte. Yo tampoco.
  - **Pip:** Cosme siempre decía que las malas noticias debían servirse con algo dulce. No dejó dulces.
  - _(si tienes el recuerdo «graduacion interdimensional»)_ **Pip:** Desde su graduación, aquí no huele a batido de apio. Nunca pensé que lo echaría de menos.
  - _(si tienes el recuerdo «don escamas»)_ **Don Escamas:** Tú me sacaste de un estanque en un cubo. Ahora me toca a mí sacar a alguien. Aunque sea desde una pecera.
  - _(si tienes la marca «ayudante oficial»)_ **Pip:** Además, usted es ayudante oficial. Lo pone la credencial. Eso le convierte en jefe en funciones. _[ademán Nod]_
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Busca en el garaje lo que dejó Cosme»
  - **Paso 2.1 · Usar** — «Su cuaderno»
    - 🖐 _Al usar «El cuaderno de Cosme»:_
      - **Pip:** Técnicamente… Ya no está. No tiene llave. Tú. _[silencio 0.9 s]_
      - **Pip:** Sabía que funcionaría.
      - **Pip:** Y esperaba equivocarme. _[silencio 0.9 s]_
  - **Paso 2.2 · Usar** — «El mando del banco de trabajo»
    - 🖐 _Al usar «El prototipo de mando de rescate»:_
      - **Pip:** ¿Quieres que la lea yo?
      - **Tú:** Léela. La leeré yo. No hay respuesta incorrecta.
      - **Pip:** No dejó instrucciones sobre cómo encontrarlo. _[silencio 0.9 s]_
      - **Pip:** Dejó instrucciones sobre cómo empezar. _[silencio 0.9 s]_
- **Paso 3 · Hablar** con Candela — «Vuelve a la residencia: necesitas un equipo»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela
  - **Candela:** Así que tu vecino inventor está secuestrado en otra dimensión por su gemelo malvado con perilla. _[plano Medio de Candela · gesto ThinkChin]_
  - **Candela:** Y hay que rescatarle. Vale. Lo apunto. _[silencio 0.6 s]_
  - **Iván:** ¿Otra dimensión? ¿Con portal y todo? ¡Voy! Llevo zumo. De mora. De día. _[a Candela · ademán Cheer]_
  - **Candela:** Iré. Pero con un plan plastificado. Nadie cruza un portal sin plan plastificado. Es la norma. _[a Iván]_
- **Paso 4 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Pip, Don Escamas, Iván, Candela
  - **Pip:** Cosme dijo que siguieras las costuras.
  - **Pip:** Creo que acabamos de encontrar una. _[silencio 0.9 s]_
  - **Pip:** Ese día…
  - **Pip:** Cosme sabía que volverías aquí. _[silencio 1.8 s]_

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
  - 🎬 **Escena al completarlo «Saga_14_G1_Fin»** _(música: → Descubrimiento)_
    - _En escena:_ Iván, Candela
    - **Iván:** ¿Seguro que esto es buena idea?
    - **Candela:** No.
    - **Iván:** Perfecto. Me quedo mucho más tranquilo/a.
    - **Iván:** Creo que aquí hay algo al revés.
    - **Candela:** No. Aquí todo está perfectamente al revés.
    - _Narrador:_ _Esta es la dimensión G-4._
    - _Narrador:_ _Aquí los gatos mandan._
    - _Narrador:_ _Y las personas llevan correa._
    - **Candela:** Es un plan.
    - **Iván:** ¡Yo no quiero llevar correa!
    - **Candela:** ¡No corras tan cerca de mí!
    - **Iván:** ¡Nos persiguen gatos!
    - **Candela:** ¡Por eso!
- **Paso 2 · Huida** — «¡La policía gatuna quiere ponerte correa! Llega al palacio presidencial (la plaza del centro)»
  - _Lugar:_ la Plaza Mayor · _En escena:_ Iván (te acompaña), Candela (te acompaña), Gato policía de Gatonia, Gata policía de Gatonia
  - 🚨 _Si te atrapan:_ «¡Correa reglamentaria! (Te la quitas mientras el gato se lame una pata. Vuelves al portal.)»
- **Paso 3 · Hablar** con Bigotes XVII — «Habla con el presidente Bigotes»
  - _En escena:_ Bigotes XVII, Iván, Candela
  - **Bigotes XVII:** Humano. Otra vez tú. _[plano Reaccion de Iván]_
    - 🎬 **Escena de cámara «Saga_14_G3_4_Musica»** _(música: → Descubrimiento → Tension)_
  - _(si has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Aquí soy presidente. En tu dimensión fui emperador exiliado.
  - _(si has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** En todas soy el mejor.
  - _(si has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Es una constante universal. _[silencio 0.9 s]_
  - _(si NO has terminado «Bigotes, emperador de Gatonia»)_ **Bigotes XVII:** Tú eres del colegio. Allí mi otro yo duerme en el patio y finge no hablar.
  - _(si NO has terminado «Bigotes, emperador de Gatonia»)_ **Iván:** ¿Siempre habla así?
  - _(si NO has terminado «Bigotes, emperador de Gatonia»)_ **Candela:** Espero que sí.
  - _(si tienes la marca «barriga bigotes»)_ **Bigotes XVII:** Tú. Me tocaste la barriga. No lo he olvidado. Nunca lo olvidaré.
  - _(si tienes la marca «duque de gatonia»)_ **Bigotes XVII:** Ah. El Duque/la Duquesa del Cojín. Siempre es un honor.
  - **Candela:** Señor presidente. Buscamos la dimensión 66-B.
  - **Candela:** Tenemos un plan plastificado.
  - **Bigotes XVII:** La 66-B. La dimensión de las perillas.
  - **Bigotes XVII:** Los gatos no vamos allí.
  - **Iván:** ¿Por qué?
  - **Bigotes XVII:** Allí nadie da de comer a los gatos. Es inhumano. Es ingatuno.
  - **Iván:** Eso sí lo entiendo.
  - **Bigotes XVII:** La 66-B existe. Y el doctor de la perilla tiene allí su laboratorio.
  - **Candela:** ¿Dónde?
  - **Bigotes XVII:** Debajo de vuestra universidad. Bajo tierra.
  - **Bigotes XVII:** Los malos siempre ponen el laboratorio debajo de algo.
  - **Candela:** Dato útil.
  - **Iván:** Señor presidente. ¿Me puedo hacer una foto con usted?
  - **Bigotes XVII:** Una. Sin flash. De mi lado bueno. _[silencio 0.9 s]_
  - **Bigotes XVII:** Todos mis lados son buenos. Tomad.
  - **Bigotes XVII:** Un collar diplomático de Gatonia.
  - **Bigotes XVII:** En cualquier dimensión con gatos, os abrirá puertas. Y latas.
  - **Iván:** ¿Latas de comida?
  - **Bigotes XVII:** Exactamente.
  - _Narrador:_ _Recibes 🎀 el Collar diplomático de Gatonia._
  - **Candela:** Tenemos una dimensión.
  - **Iván:** Tenemos un laboratorio.
  - **Candela:** Tenemos una ruta.
  - **Iván:** Y tenemos esto.
  - **Candela:** Eso es un collar. _[silencio 0.9 s]_
  - **Iván:** Un collar diplomático.
  - **Candela:** Sigue siendo un collar.
  - **Pip:** Confirmo las coordenadas. Pero hay un problema.
  - **Pip:** La dimensión 66-B está protegida.
  - **Candela:** ¿Con qué?
  - **Pip:** Con tecnología de Cósimo. _[silencio 0.9 s]_
  - **Pip:** Necesitaremos entrar sin que nos detecte.
  - **Iván:** Bueno. ¿Quién tiene un plan plastificado para esto? _[silencio 0.9 s]_
  - **Candela:** Yo.
  - _Narrador:_ _Texto de memoria: «Cruzaste una dimensión donde los gatos mandaban y conseguiste las coordenadas de la 66-B.»_

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
  - **Blorp:** ¡Blorp! ¡Otra vez aquí!
  - _(si has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** ¡La estrella! ¡Mi terrícola favorito/a! _[plano Reaccion de Iván]_
  - _(si has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Tu huida del monte fue nuestro episodio más visto. _[silencio 0.9 s]_
  - _(si has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Trescientas galaxias lo repitieron.
  - _(si has terminado «La luz del Monte del Silencio»)_ **Blorp:** ¡Blorp!
  - _(si has terminado «La luz del Monte del Silencio»)_ **Iván:** ¿Eso es bueno?
  - _(si has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Muchísimo. Aunque todavía tenemos una queja.
  - _(si NO has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** Terrícola. Me dicen que buscas algo.
  - _(si NO has terminado «La luz del Monte del Silencio»)_ **Capitana Ñoz:** En mi nave hay cámaras en todas las dimensiones. Todo se graba. Todo.
  - **Capitana Ñoz:** Ñoz cambia completamente su expresión. _[silencio 0.9 s]_
  - **Capitana Ñoz:** ¿Buscas el laboratorio del de la perilla? Ñoz sonríe. Lo tengo. En alta definición.
  - **Capitana Ñoz:** Pero en televisión nada es gratis, cariño.
  - **Capitana Ñoz:** Quiero un episodio especial.
  - **Capitana Ñoz:** «Terrícola rescata a su vecino loco».
  - **Iván:** ¿Tenemos que actuar?
  - **Capitana Ñoz:** No. Solo tenéis que ser vosotros mismos.
  - **Candela:** Eso me preocupa más. Ñoz sonríe.
  - **Candela:** Y queremos ver el guion antes. Plastificado.
  - **Candela:** Ñoz se queda mirándola.
  - **Capitana Ñoz:** Me caes bien.
  - **Candela:** Era la intención.
  - **Blorp:** ¡Blorp! ¡Yo hago de malo!
  - **Blorp:** ¡Siempre he querido hacer de malo!
  - **Blorp:** ¡Tengo una perilla de pega!
  - **Iván:** Está bastante bien.
  - **Candela:** No le digas eso.
  - 🎬 **Escena al completarlo «Saga_15_G2_Entra»**
    - _En escena:_ Capitana Ñoz, Blorp
    - **Blorp:** ¡Blorp!
    - **Capitana Ñoz:** Más malvado.
    - **Blorp:** ¡BLORP!
    - **Capitana Ñoz:** Perfecto. No tengo ni idea de qué está haciendo.
    - _(si tienes la marca «saga 15 p 2 gana»)_ **Capitana Ñoz:** ¡Corten! Eres un talento natural. Bueno. Natural no. Pero talento.
    - _(si tienes la marca «saga 15 p 2 gana»)_ **Blorp:** ¡Blorp!
    - **Capitana Ñoz:** ¡Corten! Se te ha trabado la frase cuatro veces. Da igual. Se guarda el guion. Tenemos episodio.
    - **Capitana Ñoz:** Pero la misión continúa exactamente igual.
- **Paso 2 · Minijuego** — «completar correctamente el rodaje.»
  - _En escena:_ Capitana Ñoz, Zarg
  - 🎮 _Cómo se juega:_ Di tu frase justo cuando se enciende la luz roja
- **Paso 3 · Escena**
  - _En escena:_ Capitana Ñoz, Iván, Candela
  - **Capitana Ñoz:** Toma. La grabación del laboratorio del doctor Cósimo.
    - 🎬 **Escena de cámara «Saga_15_G3_Musica»** _(música: → Tension)_
  - **Iván:** Está vivo. _[silencio 0.9 s]_
  - **Candela:** Está bien. Está dormido.
  - **Iván:** Lleva zapatillas. Eso es buena señal.
  - **Candela:** ¿En qué sentido?
  - **Iván:** No lo sé. Pero me tranquiliza.
  - **Capitana Ñoz:** La grabación es de esta noche.
  - **Capitana Ñoz:** Eso significa que sigue allí. Podéis llegar. _[silencio 0.9 s]_
  - **Candela:** ¿Y cómo? Ñoz señala la pantalla.
  - **Capitana Ñoz:** Tenéis las coordenadas.
  - **Capitana Ñoz:** Y ahora tenéis los ojos. Solo falta entrar.
  - **Cosme:** Criatura…
  - **Capitana Ñoz:** Pase VIP. Cuando todo esto acabe, venid a la final de temporada. Traed al vecino. _[silencio 0.9 s]_
  - **Capitana Ñoz:** Que salga en el último episodio.
  - _Narrador:_ _Recibes 🎫 Pase_VIP_Plató._
  - **Iván:** ¿Entonces vamos a entrar ahí?
  - **Candela:** Sí.
  - **Iván:** ¿Y tenemos un plan?
  - **Candela:** Siempre.
  - **Pip:** He recibido las imágenes.
  - **Pip:** He confirmado la ubicación. Mañana entramos. _[silencio 0.9 s]_
  - _Narrador:_ _«Viste a Cosme. Está vivo. Está atrapado bajo la universidad de la dimensión 66-B.»_ _[silencio 0.9 s]_

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
  - 🎬 **Escena al completarlo «Saga_16_G1_Fin»**
    - _En escena:_ Pip, Candela, Iván
    - **Iván:** He traído agua. Y zumo de mora.
    - **Candela:** ¿Para qué?
    - **Iván:** Por si el universo tiene sed.
    - **Pip:** Coordenadas confirmadas. Dimensión 66-B.
    - **Candela:** Entramos, encontramos el laboratorio y volvemos.
    - **Iván:** Plan sencillo. Eso siempre acaba bien.
    - **Iván:** No me gusta esta ciudad.
    - **Candela:** Llevamos aquí diez segundos.
    - **Iván:** Exactamente. Me ha robado.
    - **Candela:** Apúntalo.
    - **Iván:** ¿En serio?
    - **Candela:** Sí. Las palomas pueden ser importantes.
- **Paso 2 · Usar** — «investigar la Plaza Mayor.»
  - _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🖐 _Al usar «Un cartel: «CÓSIMO ALCALDE PARA SIEMPRE»»:_
    - **Candela:** Alguien sigue recordando a Cosme. Eso es importante. Lo apunto.
    - **Candela:** ¿Lo has visto?
    - **Iván:** Sí.
    - **Candela:** Bien. No estoy loca.
- **Paso 3 · Hablar** con Tú (malvado, dimensión 66-B) — «Alguien con tu cara (y perilla) te mira desde un banco»
  - _Lugar:_ la Plaza Mayor · _En escena:_ Tú (malvado, dimensión 66-B), Iván, Candela
  - **Iván:** Eso… tiene que doler. Muchísimo. ¿El gato? No. Entiendo. _[plano Reaccion de Candela · silencio 3.0 s]_
  - ❓ **Pregunta al jugador:** ¿Qué le dices a tu yo malvado?
    - ➤ «Ayúdanos a llegar al laboratorio. Te lo agradeceré.» _(efecto: empatia +1; marca «malvado ayudo»)_
    - ➤ «No me fío de ti. Ni de tu perilla.» _(efecto: valentia +1)_
  - 🎬 **Escena al completarlo «Saga_16_G4_Entra»**
    - _En escena:_ Iván, Candela
    - **Candela:** Nos han detectado.
    - **Iván:** ¿Quién? Ah. Eso.
    - **Candela:** Corred.
    - **Iván:** ¡No sé si esto cuenta como estudiar!
    - **Candela:** ¡Corre y luego lo discutimos! ¿Estás bien? Entonces otra vez.
- **Paso 4 · Huida** — «llegar a la universidad 66-B.»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Iván (te acompaña), Candela (te acompaña), Dron de Cósimo
  - 🚨 _Si te atrapan:_ «¡Participante descalificado! (Te sueltan en la plaza. Candela te recoge.)»
- **Paso 5 · Usar** — «Busca la entrada al laboratorio subterráneo»
  - _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🖐 _Al usar «Una rejilla de ventilación con vapor verde»:_
    - **Candela:** Es la misma. La de la grabación.
    - **Iván:** No quiero saber qué clase de concurso es este. _[silencio 0.9 s]_
    - _(si tienes la marca «grabacion laboratorio»)_ **Candela:** Es exactamente el de la grabación. Cosme está ahí abajo.
    - _(si tienes la marca «coordenadas cosimo»)_ **Pip:** Coordenadas de Bigotes confirmadas.
    - _(si tienes la marca «coordenadas cosimo»)_ **Pip:** La grabación de la Capitana Ñoz también coincide. _[silencio 0.9 s]_
    - _(si tienes la marca «coordenadas cosimo»)_ **Pip:** El laboratorio está debajo de ustedes.
    - _Narrador:_ _«COSME: VIVO» «RESCATE: MAÑANA»_
    - **Candela:** Hoy no entramos.
    - **Iván:** ¿Mañana?
    - **Candela:** Mañana entramos preparados.
    - **Pip:** Correcto. Y señor Iván.
    - **Iván:** ¿Sí?
    - **Pip:** No se coma las plantas carnívoras. Otra vez.
    - **Iván:** Fue una investigación científica.
    - **Doctor Cósimo:** ¿Quién anda ahí?
    - _Narrador:_ _«Entraste en la Valmar 66-B y encontraste la entrada al laboratorio donde Cósimo mantiene a Cosme.»_ _[silencio 0.9 s]_
    - _(si tienes la marca «malvado ayudo»)_ _Narrador:_ _«Incluso tu versión de 66-B decidió ayudarte.»_
    - **Candela:** No solamente acompaña.
    - **Pip:** Esta vez, volvemos con él. _[silencio 0.9 s]_

**Al terminar (momento de la biografía):** «Entraste en la Valmar malvada»

---

### Saga_17_Rescate · «El rescate»

**Resumen:** Bajo la universidad de la Valmar malvada, en una cápsula de cristal, duerme Cosme. Entre él y tú: robots, drones y un pasillo con música de concurso.

_Tipo: Saga de la Grieta · Acto III (5/6) · Duración: 30-40 min_

**Cómo empieza:** al llegar a la Universidad de Valmar. «La rejilla del laboratorio de Cósimo. Tu equipo está listo»

**Requisitos:** has terminado «Dimensión 66-B» y etapa desde AdultoJoven

**Pasos:**

- **Paso 1 · Pelea** — «llegar a la entrada del laboratorio.»
  - _Lugar:_ la Universidad de Valmar · _En escena:_ Iván (te acompaña), Candela (te acompaña)
  - 🚨 _Si te atrapan:_ «Tiene usted una llamada de ventas… (Candela tira de ti hacia atrás.)»
  - 🎬 **Escena al completarlo «Saga_17_G1_2_Fin»**
    - _En escena:_ Iván, Pip, Candela, Agente Cronos, de Aduanas del Tiempo
    - **Pip:** He calculado veintisiete rutas posibles.
    - **Iván:** ¿Y cuál es la buena?
    - **Pip:** La número diecinueve.
    - **Iván:** ¿Y las otras?
    - **Pip:** No me gustan las explosiones.
    - **Candela:** Entonces ruta diecinueve.
    - **Candela:** Tenemos una oportunidad.
    - **Candela:** No sabemos cuánto durará. Así que entramos.
    - **Iván:** Y salimos.
    - **Pip:** Exactamente.
    - **Pip:** ¿Listos? Por Cosme.
    - **Candela:** Por Cosme.
    - **Iván:** Y por las plantas. Me han dado pena.
    - **Pip:** No toque las plantas.
    - _(si tienes la marca «una camara detecta al jugador»)_ _Narrador:_ _«DETECCIÓN: 35%»_
    - **Candela:** Dame diez segundos.
    - **Iván:** ¿Exactos?
    - **Candela:** Más o menos.
    - **Iván:** Eso no me tranquiliza.
    - **Candela:** No era mi objetivo.
    - **Pip:** Entrada localizada. A partir de aquí… No hay vuelta atrás.
    - _(si tienes la marca «cronos aliado»)_ **Agente Cronos, de Aduanas del Tiempo:** Cinco segundos. Bueno. Cuatro. Tres. Dos. Uno.
    - _(si tienes la marca «cronos aliado»)_ **Agente Cronos, de Aduanas del Tiempo:** Todo vuelve a velocidad normal.
- **Paso 2 · Usar** — «Abre la cápsula de Cosme»
  - 🎬 **Escena al completarlo «Saga_17_G4_5_Entra»** _(música: → Intima)_
    - _En escena:_ Doctor Cósimo, Cosme, Pip, Iván
    - **Doctor Cósimo:** Qué conmovedor. De verdad. Casi me emociono. Has tardado mucho.
    - **Doctor Cósimo:** Aunque supongo que crecer lleva su tiempo. Hola, Ancla.
    - **Doctor Cósimo:** ¿Por qué no me dejaste en paz?
    - **Doctor Cósimo:** Porque tú no eres el problema. Eres la solución.
    - **Doctor Cósimo:** Él lo entendió demasiado tarde.
    - **Cosme:** No le escuches.
    - **Doctor Cósimo:** Siempre dices lo mismo.
    - **Doctor Cósimo:** Tú y yo empezamos esto juntos.
    - **Cosme:** Y yo lo terminé.
    - **Doctor Cósimo:** No. Tú huiste. Yo simplemente continué.
    - **Doctor Cósimo:** Qué predecible.
    - **Pip:** Tenemos aproximadamente… Muy poco tiempo.
    - **Iván:** ¿Eso es una medida oficial?
    - **Pip:** No.
    - **Iván:** Perfecto.
    - **Cosme:** Por aquí. No. Por ahí.
    - **Iván:** ¿No conoces tu propio laboratorio?
    - **Cosme:** Lo diseñó Cósimo. Yo solo tuve la mala idea de ayudarle. Pip.
    - **Cosme:** ¿Has cuidado de la criatura?
    - **Pip:** Todos estos años.
    - **Cosme:** Entonces hiciste bien tu trabajo.
    - **Doctor Cósimo:** Esto no ha terminado.
    - **Cosme:** Lo sé. Nunca terminó.
    - **Pip:** No todo.
    - **Cosme:** No. Gracias.
    - _Narrador:_ _«FUSIÓN: 87%» «ANCLA: LOCALIZADA» «CÓSIMO: ACTIVO»_
    - _Narrador:_ _Significa: «Hemos recuperado a Cosme, pero ahora todos están metidos en el problema.»_
  - 🖐 _Al usar «La cápsula de cristal»:_
    - _Narrador:_ _«ANCLA: ESTABLE»_ _[silencio 0.9 s]_
    - **Candela:** Lo están preparando.
    - **Pip:** No. Ya está preparado/a.
    - **Pip:** Él la hizo. Decía que parecía importante.
    - **Iván:** Es un pez de juguete.
    - **Pip:** Para usted. Señor. He tardado. Pero he venido.
    - **Pip:** No puede hablar todavía. Muy ligeramente.
    - **Cosme:** Criatura… Has crecido.
    - **Iván:** Sí. Un poco.
    - **Cosme:** ¿Y tú?
    - **Iván:** Yo sigo igual.
    - **Cosme:** Eso explica muchas cosas.
    - **Cosme:** No basta con pulsarlas.
    - **Pip:** Una.
    - **Candela:** Dos.
    - **Pip:** Tres.
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
  - **Cosme:** ¿Esto sirve para algo?
  - **Pip:** Sí, señor. Usted lo inventó.
  - **Cosme:** Eso explica por qué no entiendo nada.
  - **Pip:** No. Eso no debería estar ocurriendo.
  - **Pip:** Incluso una pequeña pantalla dentro de una máquina.
  - **Doctor Cósimo:** Está perfectamente iluminado. ¡Buenos días, Valmar! Tengo un anuncio.
  - **Doctor Cósimo:** La Gran Fusión se celebrará en el Monte del Silencio.
  - **Doctor Cósimo:** Cuando el Ancla ya no sea una criatura.
  - **Doctor Cósimo:** Cuando sea una persona adulta. Con trabajo. _[silencio 0.9 s]_
  - **Doctor Cósimo:** Con responsabilidades. Y con facturas. _[silencio 0.9 s]_
  - **Doctor Cósimo:** Porque los adultos, querido público…
  - **Doctor Cósimo:** …están tan cansados que sueltan cualquier cosa. Hasta un universo.
  - **Pip:** Nos ha dado tiempo. Años.
  - **Pip:** Tiempo para que el señor recupere la memoria.
  - **Pip:** Y tiempo para prepararnos.
  - **Doctor Cósimo:** No se lo pierdan. Entradas ya disponibles en MegaVerso.
  - **Doctor Cósimo:** Nos vemos cuando seas adulto. Ancla. _[silencio 0.9 s]_
  - **Cosme:** ¿Quién era ese?
  - **Pip:** Un viejo amigo suyo.
  - **Cosme:** No me gusta.
  - **Pip:** A mí tampoco.
  - 🎬 **Escena de cámara «Grieta_Inminente»**
- **Paso 2 · Hablar** con Cosme — «Siéntate con Cosme»
  - _En escena:_ Cosme
  - **Cosme:** Mira. No sé quién eres. Pero cuando entras… _[silencio 0.9 s]_
  - **Cosme:** Este garaje huele distinto. Huele a… Burbujas. ¿Tiene sentido? No tiene sentido. _[silencio 0.9 s]_
  - **Cosme:** Tengo un hueco aquí dentro. Muy grande. Y cuando te miro…
  - **Cosme:** El hueco se hace más pequeño/a. Un poquito.
  - ❓ **Pregunta al jugador:** ¿Qué le dices?
    - ➤ «Le cuentas lo del microondas temporal y el bocadillo del martes.» _(efecto: Cosme +6; humor +1; marca «recuerdo microondas compartido»)_
      - **Cosme:** ¿Un microondas que calienta en el pasado?
      - **Cosme:** Qué idea más estúpida. Y más genial. ¿Fue idea mía? Claro. Tenía que ser mía. _[silencio 0.9 s]_
    - ➤ «Le dices tu nombre y le das la mano.» _(efecto: Cosme +8; empatia +2; marca «cosme recuerda nombre»)_
      - **Cosme:** La música comienza muy suavemente. Criatura. Tú eres la criatura. No sé nada más. Pero eso sí lo sé. _[silencio 0.9 s]_
  - **Cosme:** Si existen suficientes recuerdos de Cosme, añadir pequeñas reacciones. Cuando hablas…
  - **Cosme:** Siento que ya he escuchado esa voz cientos de veces. _[silencio 0.9 s]_
  - **Cosme:** Y creo que siempre acababas rompiendo algo.
  - **Cosme:** Eso también me resulta familiar. _[silencio 0.9 s]_
  - **Cosme:** ¿Eso ha sido una foto?
  - **Candela:** Sí.
  - **Cosme:** ¿Salgo bien?
  - **Candela:** Más o menos.
  - **Cosme:** Entonces es auténtica. No sé cuánto tardaré. En recordarlo todo.
  - **Cosme:** Pero creo que tengo tiempo. ¿Verdad? Bien.
  - **Cosme:** Entonces mañana trabajamos. _[silencio 0.9 s]_
  - _Narrador:_ _Algunos comentan: «¿Has visto el anuncio?»_
  - _Narrador:_ _«Dicen que será enorme.»_
  - _Narrador:_ _«No sé qué es MegaVerso, pero tienen mucha publicidad.»_

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
  - **Pip:** He hecho una lista de sitios donde el señor fue feliz.
  - **Cosme:** ¿Yo fui feliz? ¿En sitios? ¿Con esta cara? Qué raro.
  - **Pip:** Es una lista corta. El señor no salía mucho.
  - **Don Escamas:** Eso explica muchas cosas.
  - **Pip:** Pero en casi todos estaba usted.
  - **Cosme:** Tú. Hay algo contigo.
  - _(si tienes el recuerdo «tu nombre»)_ **Cosme:** Sé tu nombre. Es lo único que sé seguro/a. Lo demás… ya veremos.
  - _(si NO tienes el recuerdo «tu nombre»)_ **Cosme:** No sé quién eres. Pero no me pareces un desconocido.
  - **Cosme:** Vamos. Pero volvemos pronto.
  - **Cosme:** Echo de menos una cosa que no sé cuál es. _[silencio 0.9 s]_
  - **Don Escamas:** Mirad también en los cacharros del garaje.
  - **Don Escamas:** Una mente se esconde donde menos te lo esperas. _[silencio 0.9 s]_
  - **Don Escamas:** En una tostadora, por ejemplo.
  - **Don Escamas:** Yo nunca tiro una copia de seguridad. _[silencio 0.9 s]_
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Lleva a Cosme a los sitios de vuestros recuerdos»
  - _Lugar:_ Nido de Petra (granero) · _En escena:_ Cosme (te acompaña), Julián
  - **Paso 2.1 · Usar** — «El garaje: el microondas temporal»
    - 🖐 _Al usar «El microondas temporal (reparado por Pip)»:_
      - **Pip:** Lo he reparado. Más o menos.
      - **Cosme:** Eso nunca es una frase tranquilizadora. …No. Martes. Era martes. Tú estabas aquí.
      - **Cosme:** Tenías las manos llenas de piezas.
      - **Cosme:** Yo te dije que no tocaras nada. Lo tocaste todo. _[silencio 0.9 s]_
  - **Paso 2.2 · Usar** — «La granja de Villaverde: Petra»
    - 🖐 _Al usar «Petra, en su nido»:_
      - **Julián:** Hombre, Cosme. ¿Vienes a disculparte con Petra? Ya iba siendo hora.
      - **Julián:** Solo han pasado… muchos años. _[silencio 0.9 s]_
      - **Cosme:** ¡AY! ¡La gallina! ¡La gallina de seis metros! ¡El rayo agrandador!
      - **Julián:** Sí. Ella tampoco lo ha olvidado.
      - _(si tienes la marca «gallina seis metros»)_ **Cosme:** No sé por qué confiaba en ti. _[silencio 0.9 s]_
      - _(si tienes la marca «gallina seis metros»)_ **Cosme:** Pero claramente lo hacía.
  - **Paso 2.3 · Usar** — «El parque: el anclaje del cielo»
    - 🖐 _Al usar «El viejo anclaje del parque»:_
      - **Cosme:** Eso. Yo conozco eso.
      - **Cosme:** Y yo… Yo me sentí orgulloso. No supe decírtelo. _[plano General]_
- **Paso 3 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Pip:** Señor.
  - **Cosme:** Criatura. Esta vez no hay duda. Me acuerdo. De todo. El microondas. Las burbujas. El pez. La cinta.
  - **Cosme:** La cápsula. Y tú.
  - _(si tienes el recuerdo «los clones»)_ **Cosme:** Los clones. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «tirachinas abu»)_ **Cosme:** El tirachinas de tu abu.
  - _(si tienes el recuerdo «cosas perdidas»)_ **Cosme:** Los calcetines. Nunca encontré el segundo.
  - _(si tienes el recuerdo «ayudante cosme»)_ **Cosme:** Mi credencial de ayudante.
  - _(si tienes la marca «secreto cosme»)_ **Cosme:** El vecino secreto.
  - _(si tienes el recuerdo «rescate cosme»)_ **Cosme:** Me acuerdo de que viniste a por mí. A otra dimensión. Con zumo de mora.
  - **Pip:** Señor. Bienvenido. Otra vez. De verdad esta vez.
  - **Cosme:** Gracias. Ahora lo recuerdo.
  - **Cosme:** Sé qué me quitó Cósimo.
  - **Cosme:** No quería mis recuerdos. _[silencio 0.9 s]_
  - **Cosme:** Quería lo que había dentro de ellos. _[silencio 0.9 s]_
  - **Cosme:** Sé cómo liberar el Ancla.
  - **Don Escamas:** Eso suena bastante importante. _[silencio 0.9 s]_
  - **Cosme:** Lo sabe todo. Y viene a por ti.
  - **Cosme:** Necesitamos a todo el mundo. _[silencio 0.9 s]_
  - _Narrador:_ _O: «Nunca entendí por qué aquel microondas funcionaba.»_
  - _Narrador:_ _O: «Creo que todavía tengo aquella pieza.»_

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
  - **Cosme:** Llegas justo a tiempo. He hecho una lista.
  - _(si tienes la marca «cosme recuerda»)_ **Cosme:** Lista de aliados. La he hecho con mis recuerdos nuevos. Bueno, viejos. Bueno, recuperados.
  - **Pip:** La lista es considerablemente larga.
  - **Pip:** Está llena de nombres.
  - **Cosme:** La mitad no son humanos. Y uno es un gato.
  - **Don Escamas:** Solo uno confirmado.
  - **Cosme:** No todos vendrán. Vendrán los que ayudaste.
  - **Cosme:** Así funciona el universo. Lo que das, vuelve.
  - **Don Escamas:** A veces en forma de gato.
  - **Cosme:** Exactamente.
- **Paso 2 · Varios objetivos (en cualquier orden)** — «Visita a tus aliados (vendrán los que ayudaste en tu vida)»
  - _Lugar:_ Tu habitación de la residencia · _En escena:_ Iván, Candela, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si has terminado «Bigotes, emperador de Gatonia»), Rex (si tienes la marca «rex se queda»), Ratón Pérez (si has terminado «La huelga del Ratón Pérez»), Gnomo Rigoberto (si has terminado «La noche de los gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «conoce tu malvado»)
  - **Paso 2.1 · Hablar** con Candela — «Iván y Candela (la residencia)»
    - **Iván:** Sabía que volverías.
    - **Candela:** No. Yo calculé que volvería.
    - **Iván:** Eso es lo mismo.
    - **Candela:** No.
    - **Cosme:** Necesitamos ayuda.
    - **Iván:** ¿Es peligroso?
    - **Cosme:** Bastante. _[silencio 0.9 s]_
    - **Iván:** Entonces supongo que vamos.
    - **Candela:** Ya estaba preparada.
    - _(si tienes la marca «equipo rescate»)_ **Candela:** El equipo de rescate, reunido otra vez. Esta vez con plan plastificado desde el principio. _[a Iván]_
  - **Paso 2.2 · Hablar** con Agente Cronos, de Aduanas del Tiempo — «El agente Cronos (Correos)» _(solo si tienes la marca «cronos aliado»)_
    - **Agente Cronos, de Aduanas del Tiempo:** El tiempo tiene una costumbre.
    - **Agente Cronos, de Aduanas del Tiempo:** Siempre vuelve a pedir cuentas.
    - **Agente Cronos, de Aduanas del Tiempo:** Entonces ha llegado la hora.
    - **Agente Cronos, de Aduanas del Tiempo:** No pienso dejar que Cósimo decida cuándo termina esta historia.
    - _(si tienes el recuerdo «cronos aliado»)_ **Agente Cronos, de Aduanas del Tiempo:** Desde que cambié de bando, tu nombre sale en todas las páginas importantes.
    - _(si has terminado «El expediente de Cronos» y tienes la marca «cronos limpio»)_ **Agente Cronos, de Aduanas del Tiempo:** Y gracias a tu firma, mi expediente está limpio. Iré de uniforme. Con todos los sellos. Y esta vez, a la hora.
  - **Paso 2.3 · Hablar** con Bigotes XVII — «Bigotes (el cole)» _(solo si has terminado «Bigotes, emperador de Gatonia»)_
    - **Bigotes XVII:** Has vuelto. Y tienes cara de necesitar un ejército. Un ejército no.
    - **Bigotes XVII:** Pero puedo darte gatos. Le debemos una. _[silencio 0.9 s]_
    - **Bigotes XVII:** Y en Gatonia pagamos nuestras deudas.
    - _(si has terminado «La visita de Estado» y tienes la marca «canciller gatonia»)_ **Bigotes XVII:** Y la Guardia Gatuna también, Canciller. Cuarenta gatos, cuarenta cajas. Ya ensayan el maullido de desprecio.
  - **Paso 2.4 · Hablar** con Rex — «Rex (Facultad de Derecho)» _(solo si tienes la marca «rex se queda»)_
    - **Rex:** ¿Otra aventura? Esta vez avisa antes de romper algo. Vale. ¿Cuándo salimos?
    - _(si has terminado «Rex, abogado del Ancla» y tienes la marca «rex abogado»)_ **Rex:** Además, ya le ganamos un juicio al Consorcio. Si Cósimo protesta, le pongo una demanda. Y luego le muerdo. En ese orden.
  - **Paso 2.5 · Hablar** con Ratón Pérez — «El Ratón Pérez (el parque)» _(solo si has terminado «La huelga del Ratón Pérez»)_
    - **Ratón Pérez:** Me dijeron que había problemas.
    - **Ratón Pérez:** Y los problemas tienen dientes. _[silencio 0.9 s]_
    - **Ratón Pérez:** Así que vine preparado/a.
    - _(si tienes la marca «rata contratada»)_ **Ratón Pérez:** ¿Una batalla? Tengo vacaciones gracias a ti. Mi ayudante, la rata, cubre el turno.
    - _(si has terminado «La muela del juicio» y tienes la marca «patrulla ratones»)_ **Ratón Pérez:** Y el sindicato ya ha votado. La patrulla lleva una semana roendo cables de MegaVerso. Nos hemos guardado los mejores para el sábado.
  - **Paso 2.6 · Hablar** con Gnomo Rigoberto — «Rigoberto y los gnomos (tu jardín)» _(solo si has terminado «La noche de los gnomos»)_
    - **Gnomo Rigoberto:** ¡El tratado de paz nos obliga a defender el jardín! Y el universo es un jardín muy grande. ¡Los gnomos marchamos! Despacito.
    - _(si has terminado «El consejo de los jardines» y tienes la marca «gnomos en pie»)_ **Gnomo Rigoberto:** ¡Y el Consejo de los Jardines votó por unanimidad! Bueno, Fermina se abstuvo. Pero porque estaba boca abajo.
  - **Paso 2.7 · Hablar** con Tú (malvado, dimensión 66-B) — «Tu yo malvado (la plaza)» _(solo si tienes la marca «conoce tu malvado»)_
    - **Tú (malvado, dimensión 66-B):** Sabía que vendrías. No sé por qué.
    - **Tú (malvado, dimensión 66-B):** Supongo que porque yo también habría venido.
    - ❓ **Pregunta al jugador:** ¿Qué dices?
      - ➤ «Entonces ven con nosotros.»
      - ➤ «No tienes que hacerlo.»
    - **Tú (malvado, dimensión 66-B):** Sí. Me apunto.
    - _(si tienes la marca «malvado ayudo»)_ **Tú (malvado, dimensión 66-B):** Te enseñé la rejilla del laboratorio. Fue mi primera buena acción. Me gustó. Un poco.
    - _(si has terminado «Clases de ser bueno» y tienes la marca «malvado aprende bondad»)_ **Tú (malvado, dimensión 66-B):** Además, ya sé pedir perdón y dar las gracias. Lo practico todos los días delante del espejo. Me da un asco… pero funciona.
- **Paso 3 · Escena**
  - _Lugar:_ El garaje de Cosme · _En escena:_ Cosme, Pip, Don Escamas
  - **Cosme:** Vaya. De verdad vinieron.
  - **Iván:** Te dijimos que sí.
  - **Candela:** Y además hemos llegado a tiempo.
  - **Cosme:** Los reuniste. A todos.
  - _(si has terminado «Final de temporada» y tienes la marca «nave en el final»)_ _Narrador:_ _Sobre el garaje pasa una nave con un cartel luminoso: «FINAL DE TEMPORADA · EN DIRECTO». La Capitana Ñoz saluda con las cuatro manos._
  - _(si tienes la marca «aliado bigotes»)_ **Bigotes XVII:** Me ayudaste cuando no tenías por qué.
  - _(si tienes la marca «aliado cronos»)_ **Agente Cronos, de Aduanas del Tiempo:** Las decisiones tienen memoria.
  - _(si tienes la marca «aliado rex»)_ **Rex:** Nunca olvidé lo que hiciste.
  - _(si tienes la marca «aliado malvado»)_ **Tú (malvado, dimensión 66-B):** Supongo que esto es lo que hacen los buenos.
  - **Don Escamas:** Yo también tengo información.
  - **Don Escamas:** Tengo cuentas del MegaVerso.
  - **Don Escamas:** Y sé dónde esconden el dinero. _[silencio 0.9 s]_
  - **Iván:** ¿Cómo sabes eso? _[silencio 0.9 s]_
  - **Don Escamas:** Soy un pez. La gente habla delante de los peces.
  - **Don Escamas:** También tengo algo más. El servidor central.
  - **Cosme:** ¿El servidor?
  - **Don Escamas:** Si cae, cae el Consorcio.
  - **Don Escamas:** Y Cósimo pierde gran parte de su poder. _[silencio 0.9 s]_
  - **Cosme:** Entonces ya tenemos nuestro primer objetivo. Entramos.

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
    - **Candela:** Tres entradas. Dos guardias.
    - **Candela:** Y una opción sencilla.
    - **Iván:** ¿Cuál?
    - **Candela:** No llamar la atención.
    - **Iván:** Creo que ya hemos fallado.
    - _(si tienes la marca «gris arrepentida»)_ **Candela:** ¿Y cómo sabes eso? Porque antes era parte del problema.
    - _(si tienes la marca «gris arrepentida»)_ **Candela:** Ahora quiero arreglarlo. _[silencio 0.9 s]_
    - **Candela:** Ya está.
    - **Iván:** ¿Ya está?
    - **Candela:** Ahora viene lo difícil.
    - **Don Escamas:** Servidor.
- **Paso 3 · Escena**
  - _En escena:_ Agente Glub, Iván, Candela
  - **Iván:** ¿Planta del servidor?
  - **Candela:** Subterráneo.
  - **Iván:** Claro. Porque siempre está debajo.
  - **Don Escamas:** Es donde guardan las cosas importantes. Trátalo con cuidado.
  - **Don Escamas:** Tiene información sensible. _[silencio 0.9 s]_
  - **Candela:** Aquí está. _[silencio 0.9 s]_
  - **Iván:** ¿Qué?
  - **Candela:** La financiación.
  - _(si tienes el recuerdo «proyecto fusion»)_ **Candela:** Es lo que viste en su ordenador de la oficina.
  - _(si tienes el recuerdo «proyecto fusion»)_ **Candela:** Ahora tenemos los importes. _[silencio 0.9 s]_
  - **Iván:** ¿Todo esto para abrir una Grieta?
  - **Candela:** Todo esto para controlar dos mundos.
  - **Iván:** Yo con este dinero habría comprado muchos zumos.
  - **Candela:** Iván.
  - **Iván:** Muchos.
  - **Don Escamas:** Ahora. Solo hay que dejar que hagan su trabajo.
  - **Agente Glub:** Agente Glub. Banco Galáctico.
  - **Agente Glub:** Hemos recibido un chivatazo contable impecable.
  - **Agente Glub:** Firmado por un tal D. Escamas.
  - **Agente Glub:** Muy buena caligrafía para ser un pez. _[silencio 0.9 s]_
  - _(si tienes la marca «deuda galactica»)_ **Agente Glub:** ¿Nos conocemos? Usted leyó la letra pequeña.
  - **Agente Glub:** MegaVerso S.A. queda intervenida. Cuentas congeladas. Otra. Activos bloqueados. Otra.
  - **Agente Glub:** Operaciones suspendidas. Sellado. Sellado. Y sellado.
  - **Iván:** ¡Hemos arruinado una multinacional malvada!
  - **Iván:** ¡Con un pendrive con forma de pez!
  - **Iván:** ¡Esto hay que ponerlo en el currículum!
  - _(si tienes el recuerdo «equipo rescate»)_ **Candela:** El equipo de rescate. Versión asalto.
  - _(si tienes el recuerdo «equipo rescate»)_ **Candela:** Funciona igual de bien.
  - **Candela:** Sin dinero, Cósimo solo tiene una opción.
  - **Candela:** Hacer la Fusión él solo. Y rápido. Viene a por el Ancla. Ahora sí. _[silencio 0.9 s]_
  - _Narrador:_ _Otro NPC: «Dicen que el proyecto del doctor Cósimo se ha quedado sin fondos.»_
  - _Narrador:_ _Otro: «¿Qué pasará ahora con la Fusión?»_

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
  - **Doctor Cósimo:** Buenas noches. Perdona la hora. Traigo flores. De la 66-B. Muerden un poco. No las toques. _[silencio 1.8 s]_
  - **Doctor Cósimo:** Son temperamentales. Bonita casa. Bonita vida. Te la has ganado.
  - _(si tienes el recuerdo «caida consorcio»)_ **Doctor Cósimo:** Me habéis arruinado el Consorcio. Muy bien hecho. Me impresionas.
  - **Doctor Cósimo:** Así que esta es tu vida.
  - **Doctor Cósimo:** Familia. Amigos. Trabajo. Recuerdos. Todo lo que yo perdí. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «eres el ancla»)_ **Doctor Cósimo:** Ya viste la cinta del archivo.
  - _(si tienes el recuerdo «eres el ancla»)_ **Doctor Cósimo:** Entonces sabes lo que eres. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «eres el ancla»)_ **Doctor Cósimo:** Y sabes por qué estoy aquí.
  - **Doctor Cósimo:** He venido a negociar. Como la gente civilizada. Con perilla.
  - **Doctor Cósimo:** En mi Valmar puedo darte la vida perfecta. El mejor trabajo. La casa más grande.
  - **Doctor Cósimo:** Un gato que te hace caso. _[silencio 0.9 s]_
  - **Doctor Cósimo:** Solo tienes que venir conmigo. Soltar el Ancla. Nada más.
  - **Doctor Cósimo:** No te estoy pidiendo que destruyas nada.
  - **Doctor Cósimo:** Solo que me dejes volver. _[silencio 0.9 s]_
  - **Doctor Cósimo:** ¿Sabes lo que es quedarse al otro lado veinte años? Solo.
  - **Doctor Cósimo:** Porque alguien te soltó la mano.
  - **Doctor Cósimo:** Yo solo quiero volver. A lo grande.
  - **Doctor Cósimo:** Con las dos Valmar para mí.
  - **Doctor Cósimo:** Y entonces nadie volverá a dejarme fuera.
- **Paso 2 · Decisión** — «Cósimo te ofrece una vida perfecta en la 66-B a cambio de soltar el ancla. ¿Qué haces?»
  - ➤ **Opción «No.» Así de simple** _(efecto: decisión «trato» = No; valentia +2)_
  - ➤ **Opción «Fingir que aceptas… para tenderle una trampa en el monte»** _(efecto: decisión «trato» = Trampa; curiosidad +1; humor +1; marca «trampa cosimo»)_
- **Paso 3 · Escena**
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** ¿No? Así de simple. Qué predecible. Como él. _[silencio 0.9 s]_
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** Os parecéis tanto que da rabia.
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** Nos veremos en el Monte del Silencio, Ancla. Trae a quien quieras. Yo traeré el final.
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** ¿Aceptas? ¡Maravilloso! _[silencio 0.9 s]_
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** Nos vemos en la cima del monte. Mañana a medianoche. Ven solo. O sola.
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** …¿Por qué sonríes así? Bah. Será la emoción.
  - _(si en «trato» elegiste «Trampa»)_ _Narrador:_ _Cósimo se va. Te quedas mirando las flores que muerden._ _[silencio 0.9 s]_
  - _(si en «trato» elegiste «Trampa»)_ _Narrador:_ _Mañana es la Gran Fusión._ _[silencio 0.9 s]_
  - _(si en «trato» elegiste «Trampa»)_ **Cosme:** Llamando… Estaba esperando la llamada. ¿Ha venido? Entonces ya empezó. No estás solo.
  - _(si en «trato» elegiste «Trampa» y tienes la marca «trampa cosimo»)_ _Narrador:_ _Entonces comprende: «Me has engañado.»_ _[silencio 0.9 s]_
  - _(si en «trato» elegiste «Trampa»)_ _Narrador:_ _No sabes si son un regalo, una amenaza o ambas cosas._
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** Segunda fase

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
    - _(si tienes el recuerdo «grieta en el cielo»)_ **Cosme:** La primera vez era un rasguño. Tenías que ponerte de puntillas para verlo. Y ahora míralo. _[plano Hombro de Tú → Cosme]_
    - _(si NO se cumple: tienes el recuerdo «grieta en el cielo»)_ **Cosme:** Toda la vida sujetándola sin saberlo. Hoy no la sujetas sin ayuda. Y eso cambia las cosas. _[plano Hombro de Tú → Cosme]_
    - _(si tienes la marca «trampa cosimo»)_ **Cosme:** Ha picado. Viene sonriendo… Se ha creído que vienes a rendirte.
    - _(si NO se cumple: tienes la marca «trampa cosimo»)_ **Cosme:** Ahí está. Con perilla y todo. Quédate a mi lado.
    - 🔀 **Variante «Restos»** (si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …): cambia Fx por:
      - _(solo efectos de imagen y sonido, sin texto)_
- **Paso 2 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** ¡Bienvenidos a la GRAN FUSIÓN!
    - 🎬 **Escena de cámara «Saga_23_G2_Musica»** _(música: → Intima)_
  - _(si en «trato» elegiste «No»)_ **Doctor Cósimo:** ¡En directo desde el Monte del Silencio! Y traes público. Qué detalle.
  - _(si en «trato» elegiste «Trampa»)_ **Doctor Cósimo:** Habías aceptado. ¿Y traes un ejército? _[silencio 0.9 s]_
  - _(si tienes la marca «consorcio caido»)_ **Doctor Cósimo:** Sin Consorcio. Sin dinero. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «el trato»)_ **Cosme:** Fue a tu casa con flores, ¿verdad?
  - _(si tienes el recuerdo «el trato»)_ **Cosme:** Siempre llevaba flores a las peleas.
  - **Cosme:** Cósimo. Todavía estás a tiempo. Ven a casa. Te hago un batido.
  - **Doctor Cósimo:** ¿A casa? ¿A qué casa, Cosme?
  - **Doctor Cósimo:** ¡Drones! _[silencio 1.8 s]_
  - 🎬 **Escena al completarlo «Saga_23_G3_Entra»**
    - _En escena:_ Cosme
    - **Cosme:** ¡Criatura! Esta vez no te suelto. Ahora sí. Tenemos compañía.
- **Paso 3 · Huida** — «¡La Grieta tira de ti! Aguanta 25 segundos sin que los drones te empujen dentro»
  - _En escena:_ Dron de Cósimo, Cosme
  - 🚨 _Si te atrapan:_ «¡Casi! (Cosme te agarra de la mano. Esta vez no te suelta.)»
  - 🎬 **Escena al completarlo «Saga_23_G4_Entra»**
    - _En escena:_ Ratón Pérez, Candela, Iván, Gnomo Rigoberto, Bigotes XVII, Pip, Agente Cronos, de Aduanas del Tiempo
    - **Iván:** ¡Yo cubro este lado!
    - **Candela:** Tres segundos. Ahora.
    - **Pip:** ¡He encontrado el botón que dice «NO TOCAR»!
    - **Pip:** Creo que deberíamos tocarlo.
    - **Agente Cronos, de Aduanas del Tiempo:** ¡El tiempo está de nuestra parte!
    - **Bigotes XVII:** ¡Por la República Gatuna!
    - **Ratón Pérez:** ¡Por los dientes!
    - **Gnomo Rigoberto:** ¿Ya ha empezado?
    - _(si tienes la marca «aliado malvado»)_ **Gnomo Rigoberto:** Tranquilo/a. Ya sé cómo se hace esto. Bueno. Más o menos.
- **Paso 4 · Pelea** — «¡Oleada de drones y robots! Tus aliados te cubren (0/4)»
  - _En escena:_ Iván, Candela, Pip, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si tienes la marca «aliado bigotes»), Rex (si tienes la marca «aliado rex»), Ratón Pérez (si tienes la marca «aliado perez»), Gnomo Rigoberto (si tienes la marca «aliado gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»), Capitana Ñoz
  - 🚨 _Si te atrapan:_ «¡Te tengo! (Un aliado te rescata. Vuelves a la cima.)»
- **Paso 5 · Escena** _(solo si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - _En escena:_ Pip, Doctor Cósimo
  - **Pip:** ¡Ancla! ¡Los Restos de la Grieta! ¡El sello!
  - _Narrador:_ _Las cosas raras que arreglaste por Valmar se encienden a la vez._ _[silencio 0.9 s]_
  - **Pip:** ¡Y tiran de él hacia atrás! No puede. _[silencio 0.9 s]_
  - **Doctor Cósimo:** ¿Una farola que canta? ¿Un tenedor? ¿Esto es un ejército…
  - **Doctor Cósimo:** ¿Por qué me pesan las piernas? _[silencio 0.9 s]_
  - 🎬 **Escena al completarlo «Saga_23_G6_Entra»**
    - _En escena:_ Doctor Cósimo, Cosme
    - **Doctor Cósimo:** ¡No! ¡No después de veinte años!
    - **Doctor Cósimo:** ¡No me vais a devolver!
    - **Cosme:** No te estamos devolviendo.
    - **Cosme:** Te estamos llevando a casa.
- **Paso 6 · Pelea** — «¡Cósimo en persona! Tus Restos de la Grieta brillan y le frenan: cóselo de vuelta a su dimensión» _(solo si tienes al menos 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - _En escena:_ Iván, Candela, Pip, Agente Cronos, de Aduanas del Tiempo (si tienes la marca «cronos aliado»), Bigotes XVII (si tienes la marca «aliado bigotes»), Rex (si tienes la marca «aliado rex»), Ratón Pérez (si tienes la marca «aliado perez»), Gnomo Rigoberto (si tienes la marca «aliado gnomos»), Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»), Capitana Ñoz
  - 🚨 _Si te atrapan:_ «¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)»
  - 🎬 **Escena al completarlo «Saga_23_G7_Entra»**
    - _En escena:_ Cosme, Doctor Cósimo
    - **Cosme:** ¡Ahora!
    - **Doctor Cósimo:** ¡Ja! ¡El público adora un giro!
    - **Doctor Cósimo:** Pero la Grieta permanece abierta.
- **Paso 7 · Pelea** — «¡Cósimo en persona! Cóselo de vuelta a su dimensión» _(solo si tienes menos de 4 de estos 24 recuerdos: buzon pasado, farola opera, perro binario, …)_
  - 🚨 _Si te atrapan:_ «¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)»
- **Paso 8 · Escena**
  - _En escena:_ Doctor Cósimo, Cosme, Pip, Tú (malvado, dimensión 66-B) (si tienes la marca «aliado malvado»)
  - **Doctor Cósimo:** Veinte años preparando esto. Veinte años. Y aquí estoy.
    - 🎬 **Escena de cámara «Saga_23_G8_Musica»** _(música: → Intima → Tema)_
  - _(si tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Y me gana un Ancla con un ejército de gatos, gnomos y un pez contable. Qué vergüenza.
  - _(si tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Qué episodio tan bueno.
  - _(si NO tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Y me gana un Ancla con un pez contable y un robot. Qué vergüenza.
  - _(si NO tienes el recuerdo «todos los aliados»)_ **Doctor Cósimo:** Qué episodio tan bueno.
  - _(si tienes la marca «enfado con cosme»)_ **Cosme:** Alguien me dijo una vez que debí contar las cosas antes.
  - _(si tienes la marca «enfado con cosme»)_ **Cosme:** Así que lo digo ahora. _[silencio 0.9 s]_
  - _(si tienes la marca «perdona a cosme»)_ **Cosme:** Alguien me perdonó una noche, en mi garaje.
  - _(si tienes la marca «perdona a cosme»)_ **Cosme:** Sin que me lo mereciera. Ahora me toca a mí. _[silencio 0.9 s]_
  - **Cosme:** Cósimo. Aquella noche te solté la mano.
  - **Cosme:** Llevo veinte años pensándolo. No fue a propósito.
  - **Doctor Cósimo:** …¿Veinte años? ¿Y ahora me pides perdón? ¿Así? ¿En directo? _[silencio 1.8 s]_
  - **Doctor Cósimo:** Eres insoportable, Cosme.
  - **Doctor Cósimo:** ¿Y tú qué harías conmigo, Ancla? _[silencio 0.9 s]_
  - **Tú:** Que vuelva. Que empiece de cero. En esta Valmar.
  - **Doctor Cósimo:** ¿Aquí? ¿Sin perilla? Me afeitaré. Me sentará fatal.
  - **Tú:** Que vuelva a la 66-B. Pero sin maldad: a arreglarla.
  - **Doctor Cósimo:** ¿Arreglar la 66-B? ¿Una dimensión entera de malvados?
  - **Doctor Cósimo:** Sería el reto más grande de mi vida.
  - **Doctor Cósimo:** Me gustan los retos grandes. _[silencio 0.9 s]_
  - **Cosme:** Ya no tira nadie de ella. Solo falta cerrarla. Para siempre. _[silencio 0.9 s]_
  - **Pip:** Creo que todavía no hemos terminado.
  - **Cosme:** No. Pero esta vez… Lo terminamos juntos.
  - ❓ **Pregunta al jugador:** Cósimo te mira a ti. «¿Y tú qué harías conmigo, Ancla?»
    - ➤ «Que vuelva. Que empiece de cero. En esta Valmar.» _(efecto: empatia +2; marca «cosimo perdonado»)_
      - **Doctor Cósimo:** ¿Aquí? ¿Sin perilla? …Me afeitaré. Me sentará fatal. …Gracias.
    - ➤ «Que vuelva a la 66-B. Pero sin maldad: a arreglarla.» _(efecto: responsabilidad +2; marca «cosimo arregla 66b»)_
      - **Doctor Cósimo:** ¿Arreglar la 66-B? ¿Una dimensión entera de malvados? …Sería el reto más grande de mi vida. Me gustan los retos grandes. Acepto.
      - _(si tienes la marca «aliado malvado»)_ **Tú (malvado, dimensión 66-B):** Yo le ayudo. Ya sé cómo es ser bueno. Un poco. Tengo práctica. _[a Doctor Cósimo · plano Medio de Tú (malvado, dimensión 66-B)]_

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
  - **Cosme:** ¡Esa pieza va al revés!
  - **Doctor Cósimo:** ¡Va al revés porque la pusiste tú al revés aquella noche!
  - **Cosme:** ¡Yo nunca pongo nada al revés!
  - _(si tienes la marca «cosimo perdonado»)_ **Doctor Cósimo:** Y no mires la barbilla. _[silencio 1.8 s]_
  - _(si tienes la marca «cosimo perdonado»)_ **Doctor Cósimo:** Ya sé que sin perilla parezco un huevo. No puede. _[silencio 0.9 s]_
  - _(si tienes la marca «cosimo arregla 66b»)_ **Doctor Cósimo:** Tengo una dimensión entera que arreglar. _[silencio 0.9 s]_
  - _(si tienes la marca «cosimo arregla 66b»)_ **Cosme:** Te vendrá bien.
  - _(si tienes la marca «cosimo arregla 66b»)_ **Doctor Cósimo:** No te emociones. Sigo siendo yo.
  - **Pip:** Llevan así tres horas. Es precioso. Es como antes.
  - **Pip:** Tengo el aceite de los ojos alterado. _[silencio 0.9 s]_
  - _(si tienes la marca «consorcio caido»)_ **Don Escamas:** Las cuentas del Consorcio, cerradas.
  - _(si tienes la marca «consorcio caido»)_ **Don Escamas:** Me encanta cuadrar un balance. _[silencio 0.9 s]_
  - _(si tienes la marca «fusion detenida»)_ **Pip:** Mucho correo. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «guardia gatuna»)_ **Pip:** La Guardia Gatuna supervisó la batalla. Desde sus cajas. Éxito total.
  - _(si tienes el recuerdo «abogado rex»)_ **Pip:** Rex manda su minuta: un jamón. Dice que es simbólico.
  - _(si tienes el recuerdo «muela del juicio»)_ **Pip:** Ciento doce cables de MegaVerso mordidos. Récord. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «expediente cronos»)_ **Pip:** La Aduana del Tiempo felicita al agente Cronos. Llegó a la hora.
  - _(si tienes el recuerdo «expediente cronos»)_ **Pip:** Por primera vez en cuatrocientos años. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «temporada final»)_ **Pip:** Récord de audiencia en trescientas galaxias.
  - _(si tienes el recuerdo «consejo gnomos»)_ **Pip:** Los gnomos llegaron cuando ya había acabado todo. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «consejo gnomos»)_ **Pip:** Dicen que era el plan. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «clases de bondad»)_ **Pip:** Tu yo de la 66-B manda flores. Estas no muerden.
  - _(si tienes el recuerdo «gran fusion»)_ **Cosme:** Después de lo del monte…
  - **Cosme:** Criatura. Hay que coser el cielo desde los dos lados a la vez. Yo desde aquí. Y tú en el centro. _[silencio 0.9 s]_
  - **Cosme:** Porque eres el Ancla. Donde empezó todo.
  - 🎬 **Escena al completarlo «Saga_24_G2_Entra»**
    - _En escena:_ Doctor Cósimo, Iván, Candela, Cosme
    - **Iván:** Entonces… ¿Esto es oficialmente el final?
    - **Candela:** Según mi lista, sí.
    - **Iván:** ¿Y si no?
    - **Candela:** Entonces hago otra lista.
    - **Iván:** Me tranquiliza muchísimo.
    - **Doctor Cósimo:** Has envejecido.
    - **Cosme:** Tú también.
    - **Doctor Cósimo:** Yo tengo estilo.
    - **Cosme:** Tienes una perilla.
    - **Doctor Cósimo:** Tenía una perilla.
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
    - **Doctor Cósimo:** Yo cojo mi lado. Como aquella noche. Esta vez no me sueltes. _[a Cosme]_
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
      - **Doctor Cósimo:** Mañana vuelvo a la 66-B a arreglarla. Hoy… una última costura juntos. _[a Cosme]_
      - **Cosme:** No te suelto. Esta vez, no. _[a Doctor Cósimo · silencio 0.5 s]_
      - **Candela:** Punto uno. Punto dos. Punto tres…
- **Paso 4 · Escena**
  - **Doctor Cósimo:** Ya está. Ya no eres un Ancla. Eres… …una persona. Qué aburrido. Qué bien.
  - **Cosme:** Criatura.
  - _(si tienes el recuerdo «cosme recuerda»)_ **Cosme:** Te lo digo ahora… Tengo todos los recuerdos. Y ninguno pendiente. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «cosme recuerda»)_ **Cosme:** Estoy orgulloso de ti. _[silencio 0.9 s]_
  - _(si NO tienes el recuerdo «cosme recuerda»)_ **Cosme:** Te lo digo ahora… El cielo está limpio.
  - _(si NO tienes el recuerdo «cosme recuerda»)_ **Cosme:** Estoy orgulloso de ti. _[silencio 0.9 s]_
  - _(si tienes el recuerdo «conoci cosme»)_ **Cosme:** Desde el microondas. Desde siempre.
  - _(si NO tienes el recuerdo «conoci cosme»)_ **Cosme:** Desde siempre.
  - ❓ **Pregunta al jugador:** ¿Qué le dices a Cosme?
    - ➤ «Gracias por cuidarme toda la vida.» _(efecto: Cosme +20)_
      - **Cosme:** No me des las gracias. Dame un abrazo. Rápido.
      - **Cosme:** Que viene Cósimo y no quiero que se ría. …Vale. Que se ría. _[silencio 0.9 s]_
    - ➤ «¿Y ahora qué inventamos?» _(efecto: Cosme +15; curiosidad +2)_
      - **Cosme:** ¡Esa es mi criatura! Tengo una idea.
      - **Cosme:** Así el pan ya está hecho mañana. _[silencio 0.9 s]_
      - **Doctor Cósimo:** No.
      - **Cosme:** ¡Cósimo, trae el destornillador!
      - **Doctor Cósimo:** No. ¿Dónde está?
  - **Iván:** Entonces… ¿Ya está? ¿Hemos salvado el universo?
  - **Iván:** ¡Zumo de mora para todos! ¡De día! _[silencio 0.9 s]_
  - _(si tienes la marca «aliado compis»)_ **Iván:** Quedan treinta y nueve litros del zumo para el ejército. Nadie se va sin vaso.
  - **Candela:** Reunir a todos. Terminado.
  - **Candela:** Es el mejor día de mi vida.
  - _(si tienes la marca «aliados reunidos»)_ **Candela:** Tachado el último punto. Reunir a todos.
  - _(si tienes la marca «aliados reunidos»)_ **Candela:** Es el mejor día de mi vida. _[silencio 0.9 s]_
  - _(si tienes la marca «aliado cronos»)_ **Doctor Cósimo:** Y el de los sellos llegó a la hora.
  - _(si tienes la marca «aliado cronos»)_ **Doctor Cósimo:** Ahora sí que lo he visto todo. _[silencio 0.9 s]_
  - _(si tienes la marca «aliado cronos»)_ **Agente Cronos, de Aduanas del Tiempo:** Estoy intentando disfrutarlo.
  - **Pip:** Tengo una cosa para ti.
  - _Narrador:_ _Recibes la Aguja de Oro. Pero en Valmar…_
  - _Narrador:_ _…las cosas raras nunca se acaban del todo._ _[silencio 0.9 s]_

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
  - 🎬 **Escena al completarlo «Vida_G3_Entra»** _(música: → Descubrimiento)_
    - _Narrador:_ _Toda una vida en Valmar. Y la historia sigue._
    - _Narrador:_ _Porque la ciudad no se para._
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
  - 🎬 **Escena al completarlo «Adulto_Llegada_G1_Fin»**
    - _Narrador:_ _Hay ciudades que visitas._
- **Paso 2 · Cinemática**
  - 🎬 **Cinemática «Adulto_Bienvenida»** _(música: → Descubrimiento)_
    - _En escena:_ Ernesto, Chef Lola · _entran andando:_ Ernesto, Chef Lola · _salen:_ Ernesto, Chef Lola
    - _Cámara:_ 1 planos (General)
    - **Ernesto:** ¡Eh! Tú no eres de aquí.
    - **Ernesto:** Conozco todas las caras de Valmar. Y todos los perros. A ese no lo conozco. Todavía.
    - **Ernesto:** Entonces bienvenido/a.
    - **Ernesto:** Para recibir cartas necesitas un buzón. Y para tener buzón… Una casa.
    - **Ernesto:** Busca los carteles de “SE VENDE”.
    - **Chef Lola:** ¡Ernesto! Déjale respirar. Acaba de llegar. Soy Lola.
    - **Chef Lola:** Tengo una cafetería aquí mismo.
    - **Chef Lola:** Si tienes hambre, ven.
    - **Chef Lola:** La primera invita la casa.
    - **Ernesto:** ¿La primera?
    - **Chef Lola:** La primera.
    - **Ernesto:** Eso es peligroso.
    - **Chef Lola:** Tú no eres cliente.
    - **Ernesto:** Precisamente.
  - 🎬 **Escena al completarlo «Adulto_Llegada_G3_Entra»**
    - _En escena:_ Un vecino
    - **Un vecino:** ¿Nuevo/a?
    - **Tú:** Sí.
    - **Un vecino:** Entonces todavía no sabes dónde está el supermercado. Eso cambiará pronto.
- **Paso 3 · Acción del jugador** — «Busca un cartel de SE VENDE y consigue tu casa» _(solo si NO tienes la marca «tiene hogar»)_
  - 🎬 **Escena al completarlo «Adulto_Llegada_G4_Entra»**
    - _En escena:_ Chef Lola, Ernesto
    - **Chef Lola:** ¡Ah! La cara nueva. Has tardado poco.
    - **Chef Lola:** ¿Vienes de lejos?
    - **Tú:** De otra ciudad.
    - **Chef Lola:** En esa dirección está el centro.
    - **Chef Lola:** El mercado está detrás de la plaza.
    - **Chef Lola:** Y si alguna vez te pierdes… Pregunta.
    - **Chef Lola:** Aquí todos creen saber dónde está todo.
    - **Ernesto:** Porque lo sé.
    - **Chef Lola:** Tú sabes dónde está el correo.
    - **Ernesto:** Es lo importante.
    - **Chef Lola:** ¿Otra vez aquí?
    - **Ernesto:** Esta carta tiene hambre.
    - **Chef Lola:** Eso no tiene sentido.
    - _Narrador:_ _No sabías cuánto tiempo te quedarías._
    - **Ernesto:** Si buscas trabajo, mira los tablones.
    - **Chef Lola:** Y come algo antes.
    - **Ernesto:** Eso también es importante.
    - **Chef Lola:** No tanto como el trabajo.
    - **Ernesto:** Depende del trabajo.
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
  - 🎬 **Escena al completarlo «Adulto_Sueldo_G1_Fin»**
    - _En escena:_ Chef Lola, Ernesto
    - **Ernesto:** Primer día. Muy bien. Mañana será más difícil.
    - **Ernesto:** Eso significa que vas bien.
    - **Chef Lola:** ¿Y esto?
    - **Tú:** Mi primer sueldo.
    - **Chef Lola:** Entonces hoy invito yo. Guárdalo.
    - **Chef Lola:** Los primeros sueldos se recuerdan.

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
- Frases de diálogo en los datos de esas misiones: 3904; en sus 315 escenas de cámara: 1212; total: 5116.
- Frases exportadas (cada una una vez): 5116. Sin exportar: 0.
- Preguntas al jugador: 132 exportadas de 132 en los datos. Comentarios sueltos y avisos: 40 exportados de 40.
