# Informe de la reescritura · Ins01_NuevoInstituto

Guion: `docs/historia/reescritura/Ins01_NuevoInstituto.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins01_NuevoInstituto`.
Datos: `src/shared/LifeStory/Guiones/Ins01_NuevoInstituto.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre (transición, parada, autobús, entrada, la broma del veterano, el tablón, el tutor, dónde te sientas, clases, recreo con Leire y la cena). Las variantes van con las marcas de primaria: AyudasteAMateo (Mateo en el grupo), HugoConElGrupo, IkerEnElGrupo, la promesa del último día (Choices.Promesa: Nuevos/Banco/Juntos) y AdiosBruno = DeCero. A quién miras en clase de Historia no es una decisión del juego: lo que dice Javier sale siempre.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 | Scene |  | 2 · Scene «Manana» |
| 3 |  |  | 3 · Reach @ ParadaBus |
| 4 | Cinematic |  | 4 · Cinematic «Ins01_Parada» |
| 5 |  |  | 5 · Event @ ParadaBus |
| 6 |  |  | 6 · Reach @ Instituto |
| 7 | Scene |  | 7 · Scene «Entrada» |
| 8 |  |  | 8 · Choice |
| 9 |  |  | 9 · Use (Tablon) |
| 10 |  |  | 10 · Reach @ AulaInstituto |
| 11 | Scene |  | 11 · Scene «Tutor» |
| 12 |  |  | 12 · Choice |
| 13 |  |  | 13 · Class @ AulaInstituto |
| 14 |  |  | 14 · Reach @ PatioInstituto |
| 15 | Scene |  | 15 · Scene «Recreo» |
| 16 |  |  | 16 · Talk «Leire_Recreo» |
| 17 |  |  | 17 · Class @ AulaInstituto |
| 18 | Transition |  | 18 · Transition |
| 19 | Scene |  | 19 · Scene «Cena» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Scene «Manana»): conversación «Manana» con 19 frases nuevas
- PASO 3 → paso 3 del juego (Reach): 2 frases al empezar el paso (escena ligera «Ins01_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Cinematic «Ins01_Parada»): la escena «Ins01_Parada» se cuenta con el guion nuevo (misma escena, 2 planos, 22 frases, 65.4 s)
- PASO 7 → paso 7 del juego (Scene «Entrada»): conversación «Entrada» con 4 frases nuevas
- PASO 8 → paso 8 del juego (Choice): «OPCIÓN B · «Preguntar a la delegada»» es la conversación de la opción Dudar («Delegada», 4 frases)
- PASO 8 → paso 8 del juego (Choice): 6 frases al empezar el paso (escena ligera «Ins01_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Tablon» (4 frases)
- PASO 11 → paso 11 del juego (Scene «Tutor»): conversación «Tutor» con 17 frases nuevas
- PASO 12 → paso 12 del juego (Choice): «OPCIÓN A · OMAR» es la conversación de la opción Omar («Sit_Omar», 3 frases)
- PASO 12 → paso 12 del juego (Choice): «OPCIÓN B · LEIRE» es la conversación de la opción Leire («Sit_Leire», 6 frases)
- PASO 12 → paso 12 del juego (Choice): «OPCIÓN C · BRUNO» es la conversación de la opción Bruno («Sit_Bruno», 8 frases)
- PASO 13 → paso 13 del juego (Class): 4 frases al empezar el paso (escena ligera «Ins01_G13_Entra», la lanza el paso 12 al cumplirse; el jugador no pierde el control)
- PASO 15 → paso 15 del juego (Scene «Recreo»): conversación «Recreo» con 5 frases nuevas
- PASO 16 → paso 16 del juego (Talk «Leire_Recreo»): conversación «Leire_Recreo» con 19 frases nuevas
- PASO 17 → paso 17 del juego (Class): 2 frases al empezar el paso (escena ligera «Ins01_G17_Entra», la lanza el paso 16 al cumplirse; el jugador no pierde el control)
- PASO 19 → paso 19 del juego (Scene «Cena»): conversación «Cena» con 25 frases nuevas

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4: el guion no trae planos para «Ins01_Parada»: se conservan los de la escena de antes
- PASO 5 → paso 5 del juego (Event): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6 → paso 6 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 10 → paso 10 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 12 → paso 12 del juego (Choice): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14 → paso 14 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 15: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 16: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 16: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 18 → paso 18 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 507) · Mateo: «Ya no estoy seguro.» → «Ya no estoy segur{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 8 · OPCIÓN A · «Esperar el ascensor»: El jugador y Omar llegan a una puerta. / Cartel:
- PASO 8 · OPCIÓN B · «Preguntar a la delegada»: La delegada se acerca. / DELEGADA: ¿El ascensor de alumnos? /  / DELEGADA: No existe. / Mira hacia donde está el alumno. / Todos los años lo dicen. / Sonríe. / DELEGADA / DELEGADA: Primero C está abajo. / Señala el tablón. / DELEGADA: Y si necesitáis algo, buscadme. / Conservar: veterano = Dudar / Efecto: curiosidad +1
- PASO 12 · OPCIÓN A · OMAR: El jugador se sienta junto a Omar. / Omar ya había dejado sitio. / OMAR: Lo sabía. /  / OMAR: Te he guardado el sitio desde las ocho menos cuarto. / Sonríe. / Sabía que vendrías. / OMAR: Conservar: sitio instituto = Omar / Omar +5
- PASO 12 · OPCIÓN B · LEIRE: El jugador se sienta junto a Leire. / Leire aparta ligeramente la mochila. / LEIRE: Vale. /  / Pero no me preguntes por la cámara. / Mira al jugador. / LEIRE / Todo el mundo me pregunta por la cámara. / La mira. / LEIRE / LEIRE: Es de mi abuelo. /  / LEIRE: Es de carrete. / Leire observa al jugador. / Hace fotos de verdad. / Pequeña pausa. / LEIRE / LEIRE: Bueno. / Mira hacia delante. / LEIRE: Ya te lo he contado. / Sonríe ligeramente. / LEIRE: Qué rabia. / Conservar: sitio instituto = Leire / Leire +8 / empatía +1
- PASO 12 · OPCIÓN C · BRUNO: Solo si existe la decisión correspondiente. / Bruno deja espacio. / BRUNO: ¿En serio? / El jugador se sienta. / BRUNO: Vale. /  / BRUNO: Normas. / Levanta un dedo. / BRUNO: No me copies en los exámenes. / Levanta otro. / BRUNO: Y yo tampoco a ti. /  / BRUNO: Eso lo añado ahora. / Ambos sonríen ligeramente. / Después Bruno baja la voz. / BRUNO: Oye. /  / Yo tampoco conozco a nadie aquí. / Mira alrededor. / BRUNO / BRUNO: Está bien tener a alguien conocido. / Conservar: sitio instituto = Bruno / Bruno +8
- PASO 15 · OPCIÓN A · «Este es nuestro rincón»: El jugador se sienta con Omar y Sara. / Sara señala el banco. / SARA: Declaramos este banco territorio del grupo. /  / SARA: Con derechos. / Mira a Omar. / SARA: Y bocadillos. / Omar levanta su bocadillo. / OMAR: Eso sí lo puedo defender. / Omar +3 / Sara +3 / recreo ins = Rincon
- PASO 15 · OPCIÓN B · «Jugar con Nico»: El jugador se acerca al campo. / Nico recibe el balón. / NICO: ¡[Tu nombre]! / Le pasa el balón. / NICO: ¡Menos mal! / Corre. / NICO: Estos de segundo son buenos. /  / NICO: Pero no se saben nuestras jugadas. / Nico +5 / deportividad +1 / recreo ins = Nico
- PASO 15 · OPCIÓN C · «Explorar»: El jugador recorre el instituto. / Debe descubrir: / * laboratorios; / * gimnasio; / * biblioteca; / * pasillos superiores. / La cámara puede mostrar brevemente zonas que posteriormente serán importantes. / NARRADOR: Laboratorios. / Un gimnasio con gradas. / Una biblioteca con sillones. / Y, en un banco apartado… / La cámara encuentra a Leire. / Está sola.
- PASO 16 · OPCIÓN A · «Vente con nosotros»: 
- PASO 16 · OPCIÓN B · «¿Me enseñas tus fotos?»: 
- PASO 19 · Al terminar:: «Tu primer día de instituto»
- PASO 19 · DIRECCIÓN DE ACTUACIÓN AAA: El instituto debe convertirse desde esta misión en un espacio socialmente vivo.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
