# Informe de la reescritura · Saga_02_Grieta

Guion: `docs/historia/reescritura/Saga_02_Grieta.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_02_Grieta`.
Datos: `src/shared/LifeStory/Guiones/Saga_02_Grieta.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el medidor de Cosme, la cinemática Grieta_Caen (se queda su cámara, los meteoritos, los cráteres que se encienden y la espera «¡Cúbrete!»: las frases de Pip según te cubras o no van con esa espera), los tres cráteres con su objeto (calcetín, paraguas, moneda 66-B, que ya se guardan como hasta ahora), Bigotes, el garaje y la escena de la perilla. La migración por fecha de esta misión no se toca. Las marcas nuevas del guion (grieta_creciendo, cosimo_introducido, voz_desconocida, moneda_66b_obtenida, bigotes_advirtio…) no las lee ninguna misión: no se crean. Lo que Pip dice si te paras o le preguntas en el camino al garaje no tiene mecánica (un paso Reach no sabe si te paras): esas frases no salen (pendiente: una charla opcional con Pip).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Medidor» |
| 2 | Cinematic |  | — |
| 3 |  |  | 3 · Group |
| 3.1 |  |  | 3.1 · Use (Calcetin) |
| 3.2 |  |  | 3.2 · Use (Paraguas) |
| 3.3 |  |  | 3.3 · Use (Moneda) |
| 4 |  |  | 4 · Talk «Bigotes» |
| 5 |  |  | 5 · Reach @ GarajeCosme |
| 6 | Scene |  | 6 · Scene «Perilla» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Medidor»): conversación «Medidor» con 9 frases nuevas (música Tension)
- PASO 3.1 → paso 3.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Calcetin» (3 frases)
- PASO 3.2 → paso 3.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Paraguas» (4 frases)
- PASO 3.3 → paso 3.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Moneda» (3 frases)
- PASO 4 → paso 4 del juego (Talk «Bigotes»): conversación «Bigotes» con 6 frases nuevas
- PASO 5 → paso 5 del juego (Reach): objetivo «Lleva los restos al garaje de Cosme»
- PASO 6 → paso 6 del juego (Scene «Perilla»): conversación «Perilla» con 7 frases nuevas (música Tension)

## Adaptado (y por qué)

- PASO 2 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3 → paso 3 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- frase quitada (es una acotación, no se dice): «…»
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- frase quitada (es una acotación, no se dice): «…»

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 171) · Bigotes: «Esta noche he oído una voz al otro lado. Un hombre. Tranquilo. Educado.» → «Esta noche he oído una voz al otro lado. Un hombre. Tranquil{o/a}. Educado.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo:: Lugar: Garaje de Cosme.
- PASO 5 · Objetivo:: 

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
