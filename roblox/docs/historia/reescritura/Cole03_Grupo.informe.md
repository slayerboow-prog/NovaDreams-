# Informe de la reescritura · Cole03_Grupo

Guion: `docs/historia/reescritura/Cole03_Grupo.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole03_Grupo`.
Datos: `src/shared/LifeStory/Guiones/Cole03_Grupo.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

nombre_grupo y sueno_infancia ya se guardan como decisiones consultables (Choices.NombreGrupo, Choices.SuenoInfancia); el resto de la historia escribe el nombre con {grupo} (LifeStoryService lo rellena con el nombre elegido) y la profesión de adulto puede compararse con Choices.SuenoInfancia. La foto del grupo es la cinemática del paso 27 y el recuerdo «PrimerGrupo» de la misión (Memories): no hay un álbum de fotos aparte, así que «Foto_Grupo_Infancia» queda como ese recuerdo. Los nombres de grupo del guion se escriben igual que en el juego («Los Imparables»…). El minijuego del partido (Futbol) y el reto de canastas (Timing) ya existen y se usan tal cual; para las frases de «si marcas dos o más» se añade una marca al ganar/perder el reto (Cole03_P7_Gana / Cole03_P7_Pierde).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar | 1 · Transition |
| 2 | Action | Aula de 1.º A | 2 · Reach @ AulaA |
| 3 | Talk | Aula de 1.º A | 3 · Class @ AulaA |
| 4 | Scene | Aula de 1.º A | 4 · Scene «Timbre» |
| 5 | Action | Patio | 5 · Reach @ Patio |
| 6 | Choice | Patio | 6 · Choice |
| 7 | Action | Pista | 7 · MiniGame |
| 8 | Action | Patio | 8 · Group |
| 8.1 |  |  | 8.1 · Use (Mural1) |
| 8.2 |  |  | 8.2 · Use (Mural2) |
| 8.3 |  |  | 8.3 · Use (Mural3) |
| 9 | Action | Zona de juegos | 9 · Use (Escarabajo1) |
| 10 | Action | Cancha | 10 · Use (Escarabajo2) |
| 11 | Action | Edificio del colegio | 11 · Use (Escarabajo3) |
| 12 | Cinematic | Patio | 12 · Scene «FaltanJugadores» |
| 13 | Action | Campo de fútbol | 13 · Reach @ CampoColegio |
| 14 | Talk | Campo de fútbol | 14 · Scene «PrePartido» |
| 15 | Action | Campo de fútbol | 15 · MiniGame |
| 16 | Cinematic | Campo de fútbol | 16 · Scene «Banquillo» |
| 17 | Transition | Valmar | 17 · Transition |
| 18 | Action | Casa familiar | 18 · Reach @ CasaFamiliar |
| 19 | Talk | Salón | 19 · Talk «Permiso» |
| 20 | Scene | Puerta de casa | 20 · Scene «Quedada» |
| 21 | Action | Camino al parque | 21 · Reach @ Parque |
| 22 | Action | Parque | 22 · Group |
| 22.1 | Action | Parque | 22.1 · Use (CanastaParque) |
| 22.2 | Action | Parque | 22.2 · Use (Columpio) |
| 22.3 | Action | Parque | 22.3 · Use (Estanque) |
| 22.4 | Action | Parque | 22.4 · Use (Kiosco) |
| 23 | Action | Parque | 23 · Use (Banco) |
| 24 | Talk | Banco del parque | 24 · Scene «Suenos» |
| 25 | Choice | Banco del parque | 25 · Scene «ElGato» |
| 26 | Choice | Banco del parque | 26 · Scene «NombreGrupo» |
| 27 | Cinematic | Parque | 27 · Cinematic «Cole03_Foto» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 3 frases al cumplirlo (escena ligera «Cole03_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve a clase»
- PASO 2 → paso 2 del juego (Reach): 2 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole03_G1_Fin»)
- PASO 3 → paso 3 del juego (Class): 9 frases al empezar el paso (escena ligera «Cole03_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Scene «Timbre»): conversación «Timbre» con 7 frases nuevas (música Descubrimiento)
- PASO 5 → paso 5 del juego (Reach): objetivo «Sal al recreo»
- PASO 5 → paso 5 del juego (Reach): 4 frases al empezar el paso (escena ligera «Cole03_G5_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 6 del juego (Choice): objetivo «¿Con quién vas?»
- PASO 6 → paso 6 del juego (Choice): 18 frases al empezar el paso (escena ligera «Cole03_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (MiniGame): objetivo «Calienta: tres penaltis»
- PASO 7 → paso 7 del juego (MiniGame): 3 frases al empezar el paso (escena ligera «Cole03_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (Group): objetivo «Pinta el mural con Omar»
- PASO 8.1 → paso 8.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mural_Cielo» (5 frases)
- PASO 8.2 → paso 8.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mural_Colegio» (4 frases)
- PASO 8.3 → paso 8.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mural_Nosotros» (5 frases)
- PASO 9 → paso 9 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Bicho1» (4 frases)
- PASO 9 → paso 9 del juego (Use): objetivo «Sigue al escarabajo»
- PASO 10 → paso 10 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Bicho2» (6 frases)
- PASO 10 → paso 10 del juego (Use): objetivo «¡Se ha ido volando hacia la cancha!»
- PASO 11 → paso 11 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Bicho3» (5 frases)
- PASO 11 → paso 11 del juego (Use): objetivo «¡Ahora está junto al edificio!»
- PASO 12 → paso 12 del juego (Scene «FaltanJugadores»): conversación «FaltanJugadores» con 11 frases nuevas (música Intima)
- PASO 13 → paso 13 del juego (Reach): objetivo «Ve al campo de fútbol»
- PASO 13 → paso 13 del juego (Reach): 1 frases al cumplirlo (escena ligera «Cole03_G13_Fin», sin quitar el control)
- PASO 14 → paso 14 del juego (Scene «PrePartido»): conversación «PrePartido» con 21 frases nuevas (música Tension)
- PASO 15 → paso 15 del juego (MiniGame): objetivo «¡Partido contra el equipo de Bruno!»
- PASO 15 → paso 15 del juego (MiniGame): 7 frases al empezar el paso (escena ligera «Cole03_G15_Entra», la lanza el paso 14 al cumplirse; el jugador no pierde el control)
- PASO 16 → paso 16 del juego (Scene «Banquillo»): conversación «Banquillo» con 20 frases nuevas (música Intima)
- PASO 17 → paso 17 del juego (Transition): 2 frases al cumplirlo (escena ligera «Cole03_G17_Fin», sin quitar el control)
- PASO 18 → paso 18 del juego (Reach): objetivo «Pide permiso en casa»
- PASO 19 → paso 19 del juego (Talk «Permiso»): conversación «Permiso» con 8 frases nuevas (música Intima)
- PASO 20 → paso 20 del juego (Scene «Quedada»): conversación «Quedada» con 6 frases nuevas (música Descubrimiento)
- PASO 21 → paso 21 del juego (Reach): objetivo «Ve al parque con tus amigos»
- PASO 21 → paso 21 del juego (Reach): 6 frases al empezar el paso (escena ligera «Cole03_G21_Entra», la lanza el paso 20 al cumplirse; el jugador no pierde el control)
- PASO 22 → paso 22 del juego (Group): objetivo «Pasa la tarde en el parque»
- PASO 22.1 → paso 22.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Parque_Canasta» (5 frases)
- PASO 22.2 → paso 22.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Parque_Columpio» (7 frases)
- PASO 22.3 → paso 22.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Parque_Estanque» (9 frases)
- PASO 22.4 → paso 22.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Parque_Kiosco» (9 frases)
- PASO 23 → paso 23 del juego (Use): objetivo «Siéntate con tus amigos»
- PASO 24 → paso 24 del juego (Scene «Suenos»): conversación «Suenos» con 24 frases nuevas (música Intima)
- PASO 25 → paso 25 del juego (Scene «ElGato»): conversación «ElGato» con 10 frases nuevas (música Descubrimiento)
- PASO 26 → paso 26 del juego (Scene «NombreGrupo»): conversación «NombreGrupo» con 8 frases nuevas (música Intima)
- PASO 27 → paso 27 del juego (Cinematic «Cole03_Foto»): cinemática nueva «Cole03_G27» (17 planos, 9 frases, 64.0 s, música Intima) en lugar de «Cole03_Foto»
- Momento de la biografía: «Ya tienes tu grupo de amigos.»

## Adaptado (y por qué)

- PASO 1: 2 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [Talk] y en el juego es paso jugable (Class): se conserva el tipo del juego y su mecánica
- PASO 3: 6 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5: 8 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6: 9 PLANO de un paso jugable (Choice) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7: 3 PLANO de un paso jugable (MiniGame) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8.2: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8.3: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 9: 5 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11: 5 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 12: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 13: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 15: 9 PLANO de un paso jugable (MiniGame) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 16: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 16: la conversación del juego tenía 2 preguntas y el guion 1: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 17: 2 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 18: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 21: 2 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 22.2: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 22.3: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 22.4 · opción A: sin equivalente: «Objeto: Helado»
- PASO 22.4 · opción B: sin equivalente: «Objeto: Helado»
- PASO 22.4: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 23: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 25: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 26: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 26 · opción A: el guion pide Choice.NombreGrupo = LosImparables y el juego ya da Los Imparables: se queda lo del juego
- PASO 26 · opción B: el guion pide Choice.NombreGrupo = LaPatrullaValmar y el juego ya da La Patrulla Valmar: se queda lo del juego
- PASO 26 · opción C: el guion pide Choice.NombreGrupo = LosDelBancoAzul y el juego ya da Los del Banco Azul: se queda lo del juego
- PASO 26 · opción D: el guion pide Choice.NombreGrupo = LosDinosaurios y el juego ya da Los Dinosaurios: se queda lo del juego
- PASO 27: el plano General de «Banco azul» no se encuentra en la escena: plano General del lugar
- PASO 27: el plano Inserto de «Cámara» no se encuentra en la escena: plano General del lugar
- PASO 27: el plano Inserto de «Fotografía» no se encuentra en la escena: plano General del lugar
- PASO 27: el plano Dolly de «Fotografía» no se encuentra en la escena: plano General del lugar
- PASO 27: el plano Inserto de «Fotografía» no se encuentra en la escena: plano General del lugar
- PASO 27: el plano Inserto de «Fotografía» no se encuentra en la escena: plano General del lugar

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 22.3 (línea 1285) · Sara: «Serías un científico o una científica estupendo/a.» → «Serías {un científico estupendo/una científica estupenda}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: «Ve a clase»: Los alumnos hablan entre ellos mientras Lucía prepara la clase.
- PASO 4 · SFX: RIIIIING.: Profe Lucía: Recreo.
- PASO 5 · OBJETIVO: «Sal al recreo»: Sale al patio.
- PASO 6 · OBJETIVO: «¿Con quién vas?»: Los tres esperan una respuesta.
- PASO 7 · OBJETIVO: «Calienta: tres penaltis»: Nico coloca el balón.
- PASO 7 · MINIJUEGO:: * Tres lanzamientos. / * La dificultad aumenta progresivamente. / * Cada lanzamiento tiene una animación distinta. / * El último lanzamiento debe tener cámara dinámica.
- PASO 8 · OBJETIVO: «Pinta el mural con Omar»: El mural está dividido en tres partes.
- PASO 9 · OBJETIVO: «Sigue al escarabajo»: Sara se agacha.
- PASO 10 · OBJETIVO: «¡Se ha ido volando hacia la cancha!»: El insecto aterriza.
- PASO 11 · OBJETIVO: «¡Ahora está junto al edificio!»: El escarabajo se queda quieto.
- PASO 13 · OBJETIVO: «Ve al campo de fútbol»: Los dos grupos se preparan.
- PASO 15 · OBJETIVO: «¡Partido contra el equipo de Bruno!»: 
- PASO 15 · MINIJUEGO:: El partido debe sentirse como un auténtico recuerdo de infancia.
- PASO 18 · OBJETIVO: «Pide permiso en casa»: El protagonista entra.
- PASO 21 · OBJETIVO: «Ve al parque con tus amigos»: Los niños caminan juntos.
- PASO 22 · OBJETIVO: «Pasa la tarde en el parque»: Los objetivos pueden completarse en cualquier orden.
- PASO 22.3 · SFX: PLOP.: 
- PASO 23 · OBJETIVO: «Siéntate con tus amigos»: El grupo se acerca.
- PASO 27 · SISTEMA DE MEMORIA AL TERMINAR: Registrar:
- PASO 27 · MOMENTO DE BIOGRAFÍA: «Ya tienes tu grupo de amigos.»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
