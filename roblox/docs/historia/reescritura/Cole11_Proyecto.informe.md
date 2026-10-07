# Informe de la reescritura · Cole11_Proyecto

Guion: `docs/historia/reescritura/Cole11_Proyecto.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole11_Proyecto`.
Datos: `src/shared/LifeStory/Guiones/Cole11_Proyecto.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Se conservan el compañero (Choices.Companero), el tema (Huerto/Robot/Mascotas/Museo: Choices.Tema), el rol (Choices.Rol) y la discusión (Choices.Discusion), con sus minijuegos y la presentación con preguntas del jurado. «Estoy orgulloso/a de ti» y «Jefe o jefa de proyecto» van con {o/a}. La maqueta en 3 fases que evoluciona a la vista no se hace: el minijuego actual (Timing) es de una fase y no hay maqueta física que cambie (pendiente). Las listas de «Resultado según tema» del guion (Huerto: …, Robot: …) son notas de diseño, no frases: van al informe. test-reescritura recorre todas las combinaciones compañero × tema × rol y comprueba que ninguna frase la dice alguien que no está en tu equipo y que toda marca que se lee la pone alguien.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ AulaA |
| 3 |  |  | 3 · Class @ AulaA |
| 4 |  |  | 4 · Scene «Anuncio» |
| 5 |  |  | 5 · Choice |
| 6 |  |  | 6 · Scene «TemaYRol» |
| 7 |  |  | 7 · Group |
| 7.1 |  |  | 7.1 · Use (LibroCiencias) |
| 7.2 |  |  | 7.2 · Talk «Inv_Ramon» |
| 7.3 |  |  | 7.3 · Talk «Inv_Abu» |
| 7.4 |  |  | 7.4 · Use (Fuente) |
| 8 |  |  | 8 · Use (Carton) |
| 9 |  |  | 9 · Event @ Libreria |
| 10 |  |  | 10 · Reach @ AulaA |
| 11 |  |  | 11 · Scene «Discusion» |
| 12 |  |  | 12 · MiniGame |
| 13 | Transition |  | 13 · Transition |
| 14 |  |  | 14 · Scene «Desastre» |
| 15 | Transition |  | 15 · Transition |
| 16 |  |  | 16 · Reach @ AulaA |
| 17 |  |  | 17 · Scene «Nervios» |
| 18 |  |  | 18 · Class @ AulaA |
| 19 |  |  | 19 · Scene «Resultado» |

## Errores

_Ninguno._


## Aplicado

- PASO 3 → paso 3 del juego (Class): 11 frases al empezar el paso (escena ligera «Cole11_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Scene «Anuncio»): conversación «Anuncio» con 3 frases nuevas
- PASO 5 → paso 5 del juego (Choice): 14 frases al empezar el paso (escena ligera «Cole11_G5_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 6 del juego (Scene «TemaYRol»): conversación «TemaYRol» con 11 frases nuevas
- PASO 7.1 → paso 7.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Inv_Biblioteca» (4 frases)
- PASO 7.2 → paso 7.2 del juego (Talk «Inv_Ramon»): conversación «Inv_Ramon» con 1 frases nuevas
- PASO 7.4 → paso 7.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Inv_Fuente» (3 frases)
- PASO 8 → paso 8 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mat_Carton» (6 frases)
- PASO 9 → paso 9 del juego (Event): 2 frases al empezar el paso (escena ligera «Cole11_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 11 → paso 11 del juego (Scene «Discusion»): conversación «Discusion» con 18 frases nuevas (música Tension)
- PASO 12 → paso 12 del juego (MiniGame): 1 frases al empezar el paso (escena ligera «Cole11_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 14 → paso 14 del juego (Scene «Desastre»): conversación «Desastre» con 4 frases nuevas (música Intima)
- PASO 16 → paso 16 del juego (Reach): 6 frases al empezar el paso (escena ligera «Cole11_G16_Entra», la lanza el paso 15 al cumplirse; el jugador no pierde el control)
- PASO 18 → paso 18 del juego (Class): 3 frases al empezar el paso (escena ligera «Cole11_G18_Entra», la lanza el paso 17 al cumplirse; el jugador no pierde el control)
- PASO 19 → paso 19 del juego (Scene «Resultado»): conversación «Resultado» con 19 frases nuevas (música Intima→Descubrimiento)

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2 → paso 2 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 6: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 6: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 7 → paso 7 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 10 → paso 10 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 13 → paso 13 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 15 → paso 15 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 17: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 18: 6 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 19: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 19: una frase del juego daba efectos (Flags): se conservan al final de la conversación
- PASO 19: «cole11_publicado = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 5 (línea 290) · Nico: «Y seguro.» → «Y segur{o/a}.»
- PASO 5 (línea 296) · Nico: «Muy seguro.» → «Muy segur{o/a}.»
- PASO 11 (línea 1107) · Mateo: «Es un pequeño momento de crecimiento personal.» → «Es un pequeñ{o/a} momento de crecimiento personal.»
- PASO 14 (línea 1267) · Familia: «Mi hermano pequeño se ha sentado encima de la maqueta.» → «Mi hermano pequeñ{o/a} se ha sentado encima de la maqueta.»
- PASO 19 (línea 1757) · Familia: «Estoy orgulloso/a de ti.» → «Estoy orgullos{o/a} de ti.»

## Avisos

- PASO 7.1 (línea 609): «Huerto» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 7.1 (línea 611): «Robot» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 7.1 (línea 613): «Mascotas» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 7.1 (línea 615): «Museo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 11 · OPCIÓN A · JUNTAR LAS IDEAS: «Podemos hacer un poco de cada idea.» / Efectos: / * Omar +3 / * compañeros +2 / * empatía +1 / * discusion = Juntar / Cinemática / El jugador mueve los diseños. / Sara adapta medidas. / Nico reduce el tamaño. / Iker simplifica los datos. / Hugo conserva la historia. / Mateo vuelve a dibujar. / Omar sonríe. / Omar: Vale. / Mira el proyecto. / Omar: Esto sí parece nuestro.
- PASO 11 · OPCIÓN B · VOTAR: Omar: Votamos y aceptamos el resultado. / Responsabilidad +1 / Omar: Cada uno levanta la mano. / Se produce un empate. / Omar mira al jugador. / Omar: Tenemos un pequeño problema. /  / Omar: Hay tres personas y tres ideas. / El jugador propone combinar. / Omar: Votación… / Sonríe. / Omar: Que termina en mezcla.
- PASO 11 · OPCIÓN C · DECIDIR TÚ: Omar: Yo decido. Para eso hemos empezado. / Valentía +1 / Los demás guardan silencio. / Importante / No presentar esto como una opción «mala». / Pero sí como una elección con coste social. / El compañero seleccionado pierde relación: / * Hugo -2 / * Iker -2 / * Nico -2 / * Sara -2 / * Omar -1 / La maqueta continúa. / Pero la atmósfera queda algo más fría.
- PASO 14 · OPCIÓN A · ARREGLARLA EN EQUIPO: «Llamar al equipo y arreglarla juntos.» / Cinemática Cole11_Reparacion / El jugador llega a casa de Omar. / Todos están alrededor de la maqueta. / No se limitan a mirar. / * Sara mide. / * Iker clasifica piezas. / * Nico corta cartón. / * Mateo dibuja sustituciones. / * Hugo escribe nuevas etiquetas. / * Omar pega. / Omar: No va a quedar igual. /  / Omar: Pero será nuestra. / La maqueta queda ligeramente torcida. / Una pequeña pieza queda sujeta con una tirita de cartón. / Efectos: / * Omar +6 / * responsabilidad +1 / * arreglo en equipo = true
- PASO 14 · OPCIÓN B · AYUDA DE FAMILIA: En casa. / Mamá/Papá aparece con: / * cinta; / * pegamento; / * tijeras. / Mamá/Papá: Pegamento, tijeras y nervios. /  / Mamá/Papá: Tengo las tres cosas. / Abu se acerca. / Abu: Para las esquinas. / Coloca un libro sobre el cartón. / Regla y peso. / Sonríe. / Abu: Truco antiguo. / Efecto: / * Mamá/Papá +6 / * ayuda familia = true
- PASO 14 · OPCIÓN C · PRESENTARLA ROTA: El jugador observa la maqueta. / Omar respira profundamente. / Omar: Podemos contar la verdad. /  / Se rompió. / El jugador acepta. / Omar sonríe. / Entonces diremos que sobrevivió a un terremoto. /  / Un terremoto de cuatro años. / Efectos: / * humor +2 / * maqueta rota = true
- PASO 19 · NOTA ALTA: Lucía: Un trabajo excelente.
- PASO 19 · NOTA NORMAL: Lucía: La idea es muy buena.
- PASO 19 · SISTEMA DE MEMORIA: Guardar:
- PASO 19 · DIRECCIÓN DE ACTUACIÓN: La misión debe tener especial cuidado con el lenguaje corporal.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
