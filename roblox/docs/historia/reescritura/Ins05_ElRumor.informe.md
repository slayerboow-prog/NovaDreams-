# Informe de la reescritura · Ins05_ElRumor

Guion: `docs/historia/reescritura/Ins05_ElRumor.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins05_ElRumor`.
Datos: `src/shared/LifeStory/Guiones/Ins05_ElRumor.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la foto que circula, las cuatro pistas del recreo, la deducción, Nico y Darío en la pista, Omar en el banco del parque y la cinemática del día después (Ins05_DiaDespues), que se cuenta con el guion nuevo y se puede saltar.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ AulaInstituto |
| 3 | Scene |  | 3 · Scene «LaFoto» |
| 4 |  |  | 4 · Group |
| 4.1 |  |  | 4.1 · Use (Captura) |
| 4.2 |  |  | 4.2 · Talk «Pista_Leire» |
| 4.3 |  |  | 4.3 · Talk «Pista_Bruno» |
| 4.4 |  |  | 4.4 · Use (Grada) |
| 5 | Scene |  | 5 · Scene «Deduccion» |
| 6 |  |  | 6 · Reach @ PistaInstituto |
| 7 |  |  | 7 · Talk «Nico» |
| 8 |  |  | 8 · Talk «Dario» |
| 9 |  |  | 9 · Reach @ Parque |
| 10 |  |  | 10 · Talk «Omar» |
| 11 | Transition |  | 11 · Transition |
| 12 |  |  | 12 · Reach @ AulaInstituto |
| 13 | Cinematic |  | 13 · Cinematic «Ins05_DiaDespues» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Reach): 3 frases al empezar el paso (escena ligera «Ins05_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3: efectos del guion sumados a la conversación «LaFoto»: te_reiste = true
- PASO 3 → paso 3 del juego (Scene «LaFoto»): conversación «LaFoto» con 20 frases nuevas (música Descubrimiento)
- PASO 4.1 → paso 4.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Captura» (3 frases)
- PASO 4.2 → paso 4.2 del juego (Talk «Pista_Leire»): conversación «Pista_Leire» con 10 frases nuevas
- PASO 4.3 → paso 4.3 del juego (Talk «Pista_Bruno»): conversación «Pista_Bruno» con 19 frases nuevas
- PASO 5 → paso 5 del juego (Scene «Deduccion»): conversación «Deduccion» con 9 frases nuevas
- PASO 6 → paso 6 del juego (Reach): 2 frases al empezar el paso (escena ligera «Ins05_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7: efectos del guion sumados a la conversación «Nico»: hablas_nico = Privado · hablas_nico = Publico
- PASO 7 → paso 7 del juego (Talk «Nico»): conversación «Nico» con 22 frases nuevas
- PASO 8: efectos del guion sumados a la conversación «Dario»: montaje_dario = true
- PASO 8 → paso 8 del juego (Talk «Dario»): conversación «Dario» con 21 frases nuevas
- PASO 9 → paso 9 del juego (Reach): 1 frases al empezar el paso (escena ligera «Ins05_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Talk «Omar»): conversación «Omar» con 32 frases nuevas (música Descubrimiento)
- PASO 12 → paso 12 del juego (Reach): 2 frases al empezar el paso (escena ligera «Ins05_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Cinematic «Ins05_DiaDespues»): la escena «Ins05_DiaDespues» se cuenta con el guion nuevo (misma escena, 2 planos, 64 frases, 177.3 s, música Descubrimiento)

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4 → paso 4 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.3: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.4 → paso 4.4 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 8: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 8: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 10: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 10: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 11 → paso 11 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 13: el guion no trae planos para «Ins05_DiaDespues»: se conservan los de la escena de antes

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 128) · Javier: «Nadie está preparado para empezar la clase.» → «Nadie está preparad{o/a} para empezar la clase.»
- PASO 13 (línea 1777) · Nico: «Está nervioso.» → «Está nervios{o/a}.»

## Avisos

- PASO 13 (línea 1561): «Cambio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 13 (línea 2252): «Descubrimiento de DR» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 13 (línea 2444): «Optimizar» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 13: la cinemática nueva dura 177 s (se puede saltar, pero es larga: el guion trae 2 planos)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 13 · DIRECCIÓN DE ACTUACIÓN: Esta misión necesita una actuación superior a las anteriores.
- PASO 13 · Al terminar:: Biografía desbloqueada: «Cuando defendiste a Omar»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
