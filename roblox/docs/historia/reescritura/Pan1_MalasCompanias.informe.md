# Informe de la reescritura · Pan1_MalasCompanias

Guion: `docs/historia/reescritura/Pan1_MalasCompanias.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Pan1_MalasCompanias`.
Datos: `src/shared/LifeStory/Guiones/Pan1_MalasCompanias.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el recreo con Rayo y Nerea, la decisión Pellas (irte con ellos, volver a clase o convencer a Nerea) y su rama (recreativos y el muro con el espray, la clase de Historia, los cómics de Nerea), la noche en casa y Bruno en la puerta. La partida de los recreativos no guarda si ganas o pierdes: esas frases no salen. «rechazaste_pandilla» es la marca RechazasteLaPandilla que ya pone el juego.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ PatioInstituto |
| 3 | Scene |  | 3 · Scene «Rayo» |
| 4 |  |  | 4 · Choice |
| 5 |  |  | 5 · Reach @ Ocio |
| 6 |  |  | 6 · Event @ Ocio |
| 7 | Scene |  | 7 · Scene «Recreativos» |
| 8 |  |  | 8 · Reach @ Parque |
| 9 |  |  | 9 · Use (Muro) |
| 10 |  |  | 10 · Class @ AulaInstituto |
| 11 | Scene |  | 11 · Scene «Salida» |
| 12 | Scene |  | 12 · Scene «Comics» |
| 13 | Transition |  | 13 · Transition |
| 14 | Scene |  | 14 · Scene «Casa» |
| 15 |  |  | 15 · Talk «Bruno» |

## Errores

_Ninguno._


## Aplicado

- PASO 3 → paso 3 del juego (Scene «Rayo»): conversación «Rayo» con 17 frases nuevas
- PASO 4 → paso 4 del juego (Choice): 19 frases al empezar el paso (escena ligera «Pan1_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (Scene «Recreativos»): conversación «Recreativos» con 8 frases nuevas
- PASO 9 → paso 9 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Muro» (16 frases)
- PASO 10 → paso 10 del juego (Class): 2 frases al empezar el paso (escena ligera «Pan1_G10_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)
- PASO 11 → paso 11 del juego (Scene «Salida»): conversación «Salida» con 5 frases nuevas
- PASO 12 → paso 12 del juego (Scene «Comics»): conversación «Comics» con 5 frases nuevas
- PASO 14: efectos del guion sumados a la conversación «Casa»: mentiste_familia = true
- PASO 14 → paso 14 del juego (Scene «Casa»): conversación «Casa» con 19 frases nuevas
- PASO 15 → paso 15 del juego (Talk «Bruno»): conversación «Bruno» con 23 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2 → paso 2 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 5 → paso 5 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6 → paso 6 del juego (Event): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8 → paso 8 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 9: la elección tiene 1 opciones y solo 0 grupos de respuesta detrás: las demás ramas siguen sin respuesta propia
- PASO 9: la elección del juego tenía 3 opciones y el guion trae 1
- PASO 13 → paso 13 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 15: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 15 (línea 1423): «Patio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 15 (línea 1425): «Invitación de Rayo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 15 (línea 1427): «Recreativos» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 15 (línea 1429): «Muro» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 15 (línea 1433): «Advertencia de Bruno» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: Sal al recreo.
- PASO 4 · OPCIÓN A — RAYO: «Me voy contigo.»
- PASO 4 · OPCIÓN B — JAVIER: «Vuelvo a clase.»
- PASO 4 · OPCIÓN C — NEREA: «Tú tampoco deberías ir.» / RUTA A
- PASO 6 · MINIJUEGO: Arcade ficticio:
- PASO 6 · Objetivo:: * esquivar obstáculos / * conseguir puntos / * superar una puntuación mínima
- PASO 15 · DIRECCIÓN AAA: Nunca debe actuar como villano. / Debe ser divertido. / RAYO: Seguro.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
