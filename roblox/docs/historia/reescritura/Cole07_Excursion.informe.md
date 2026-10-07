# Informe de la reescritura · Cole07_Excursion

Guion: `docs/historia/reescritura/Cole07_Excursion.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole07_Excursion`.
Datos: `src/shared/LifeStory/Guiones/Cole07_Excursion.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Quien se pierde en la granja es Mateo si es tu amigo (Flags.AyudasteAMateo) y Omar si no, como en el juego: las frases del «Compañero» del guion salen dos veces, una con cada uno y su condición. La gallina «Petra» del guion se llama Remedios (Petra es la gallina gigante de la Saga de la Grieta). Las actividades de la granja (gallinas, huerto, caballos, tractor), el minijuego del grano (Timing), las pistas y la foto de grupo se juegan igual; el torneo al volver lo abre la misión siguiente como siempre.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar | 1 · Transition |
| 2 | Ir a | Autobús escolar | 2 · Reach @ AutobusCole |
| 3 | Cinematic | Autobús escolar | 3 · Scene «Salida» |
| 4 | Choice | Autobús escolar | 4 · Choice |
| 5 | Cinematic | Autobús | 5 · Scene «Viaje» |
| 6 | Cinematic | Carretera / Villaverde | 6 · Cinematic «Cole07_Viaje» |
| 7 | Cinematic | Granja Escuela | 7 · Scene «Llegada» |
| 8 | Varios objetivos | Granja Escuela | 8 · Group |
| 8.1 | Usar | — Gallinas | 8.1 · Use (Gallinas) |
| 8.2 | Usar | — Huerto | 8.2 · Use (Huerto) |
| 8.3 | Usar | — Caballos | 8.3 · Use (Caballos) |
| 8.4 | Usar | — Tractor | 8.4 · Use (Tractor) |
| 9 | Minijuego | Gallinero | 9 · MiniGame |
| 10 | Cinematic | Granja Escuela | 10 · Scene «Falta» |
| 11 | Varios objetivos | Granja Escuela | 11 · Group |
| 11.1 | Usar | — Mochila | 11.1 · Use (PistaMochila) |
| 11.2 | Usar | — Botella | 11.2 · Use (PistaBotella) |
| 11.3 | Usar | — Papel | 11.3 · Use (PistaMapa) |
| 11.4 | Hablar | — Julián | 11.4 · Talk «Julian» |
| 12 | Ir a | Granero | 12 · Reach @ GranjaGranero |
| 13 | Cinematic | Detrás del granero | 13 · Scene «Encontrado» |
| 14 | Cinematic | Granja Escuela | 14 · Scene «Reunion» |
| 15 | Cinematic | Granja Escuela | 15 · Cinematic «Cole07_Foto» |
| 16 | Scene | Autobús de vuelta | 16 · Scene «Vuelta» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 3 frases al cumplirlo (escena ligera «Cole07_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): 4 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole07_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Salida»): conversación «Salida» con 13 frases nuevas (música Intima)
- PASO 4 → paso 4 del juego (Choice): «Opción A — Nico» es la conversación de la opción Nico («Bus_Nico», 8 frases)
- PASO 4 → paso 4 del juego (Choice): «Opción B — Sara» es la conversación de la opción Sara («Bus_Sara», 4 frases)
- PASO 4 → paso 4 del juego (Choice): «Opción C — Omar» es la conversación de la opción Omar («Bus_Omar», 5 frases)
- PASO 4 → paso 4 del juego (Choice): «Opción D — Mateo» es la conversación de la opción Mateo («Bus_Mateo», 5 frases)
- PASO 4 → paso 4 del juego (Choice): «Opción E — Hugo» es la conversación de la opción Hugo («Bus_Hugo», 5 frases)
- PASO 5 → paso 5 del juego (Scene «Viaje»): conversación «Viaje» con 11 frases nuevas (música Intima)
- PASO 6 → paso 6 del juego (Cinematic «Cole07_Viaje»): cinemática nueva «Cole07_G6» (4 planos, 4 frases, 17.3 s, música Intima) en lugar de «Cole07_Viaje»
- PASO 7 → paso 7 del juego (Scene «Llegada»): conversación «Llegada» con 14 frases nuevas (música Descubrimiento)
- PASO 8.1 → paso 8.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Act_Gallinas» (8 frases)
- PASO 8.2 → paso 8.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Act_Huerto» (4 frases)
- PASO 8.3 → paso 8.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Act_Caballos» (6 frases)
- PASO 8.4 → paso 8.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Act_Tractor» (8 frases)
- PASO 9 → paso 9 del juego (MiniGame): 5 frases al empezar el paso (escena ligera «Cole07_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Scene «Falta»): conversación «Falta» con 13 frases nuevas (música Tension)
- PASO 11.1 → paso 11.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Mochila» (5 frases)
- PASO 11.2 → paso 11.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Botella» (4 frases)
- PASO 11.3 → paso 11.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Mapa» (1 frases)
- PASO 11.4 → paso 11.4 del juego (Talk «Julian»): conversación «Julian» con 10 frases nuevas
- PASO 12 → paso 12 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole07_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Scene «Encontrado»): conversación «Encontrado» con 27 frases nuevas (música Tension→Intima)
- PASO 14 → paso 14 del juego (Scene «Reunion»): conversación «Reunion» con 16 frases nuevas (música Intima)
- PASO 15 → paso 15 del juego (Cinematic «Cole07_Foto»): cinemática nueva «Cole07_G15» (4 planos, 7 frases, 28.6 s, música Intima) en lugar de «Cole07_Foto»
- PASO 16 → paso 16 del juego (Scene «Vuelta»): conversación «Vuelta» con 16 frases nuevas (música Descubrimiento→Tema)

## Adaptado (y por qué)

- PASO 1: 5 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4 → paso 4 del juego (Choice): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 5: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 6: el plano Inserto de «Cartel» no se encuentra en la escena: plano General del lugar
- PASO 7: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 8 → paso 8 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8.1: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8.2: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8.3: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8.4: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11 → paso 11 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11.1: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11.2: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11.3: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 12: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 13 · opción A: sin equivalente: «* Mateo +8 / Omar +8»
- PASO 13 · opción A: sin equivalente: «* rescate = Juntos»
- PASO 13 · opción B: sin equivalente: «* Mateo/Omar +5»
- PASO 13 · opción B: sin equivalente: «* rescate = Avisar»
- PASO 13: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 15: el plano General de «Grupo» no se encuentra en la escena: plano General del lugar
- PASO 15: el plano Inserto de «Cámara» no se encuentra en la escena: plano General del lugar

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 224) · Sara: «He preparado una lista de las plantas que podemos encontrar.» → «He preparad{o/a} una lista de las plantas que podemos encontrar.»
- PASO 4 (línea 290) · Mateo: «Y un poco nervioso.» → «Y un poco nervios{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 4 · Opción A — Nico: Efecto: asiento_bus = Nico · Nico +5 / Nico: ¡Bien! / Se sienta. / Nico: Tengo un juego. / Tú: ¿Cuál? / Nico: El que vea más vacas gana. / Mira por la ventana. / Nico: ¡Una! /  / Nico: ¡Dos! / Tú: Llevamos diez segundos. / Nico: Por eso voy ganando.
- PASO 4 · Opción B — Sara: Efecto: asiento_bus = Sara · Sara +5 / Sara aparta cuidadosamente su mochila. / Sara: He preparado una lista de las plantas que podemos encontrar. / Saca una lupa. / Tú: ¿Has traído una lupa? / Sara: Dos. /  / Sara: Por si una falla.
- PASO 4 · Opción C — Omar: Efecto: asiento_bus = Omar · Omar +5 / Omar levanta una bolsa. / Omar: Te he guardado medio bocadillo. /  / Omar: Bueno… / Mira la bolsa. / Omar: Un cuarto. / Tú: ¿Qué ha pasado con el otro cuarto? / Omar: Ha sido una emergencia.
- PASO 4 · Opción D — Mateo: Efecto: asiento_bus = Mateo · Mateo +5 / Mateo mueve su mochila para hacerte sitio. / Mateo: Nunca he ido de excursión. /  / Mateo: En mi otro cole no íbamos. / Mira por la ventana. / Mateo: Estoy contento. /  / Mateo: Y un poco nervioso. / Tú: Yo también. / Mateo sonríe.
- PASO 4 · Opción E — Hugo: Efecto: asiento_bus = Hugo · Hugo +6 / Hugo parece sorprendido. / Hugo: ¿Conmigo? / Tú: Sí. / Hugo sonríe. / Hugo: Antes siempre me sentaba donde decía Bruno. / Mira hacia la última fila. / Hugo: Esto está mejor. / Saca su libro. / Hugo: ¿Quieres que te enseñe una parte?

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
