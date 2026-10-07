# Informe de la reescritura · Saga_17_Rescate

Guion: `docs/historia/reescritura/Saga_17_Rescate.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_17_Rescate`.
Datos: `src/shared/LifeStory/Guiones/Saga_17_Rescate.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el pasillo del laboratorio (desconectar a los guardias), abrir la cápsula, la huida al portal del garaje con Cosme y la escena en casa. Para que encaje con Saga_18 (Cosme ha perdido la memoria), Cosme está lúcido un momento en el laboratorio y en la huida («Criatura…», «Has crecido», «¿Has cuidado de la criatura?») y al cruzar la Grieta la pierde: la vuelta al garaje es la escena de siempre (no reconoce a Pip; antes de dormirse murmura «…Criatura»). Las frases del guion en el garaje en las que lo recuerda todo («Has mantenido todo igual», «Gracias por venir a buscarme») no salen. La pantalla final (FUSIÓN 87 %, ANCLA LOCALIZADA, CÓSIMO ACTIVO) queda como nota: sería un plano nuevo en la escena de casa (pendiente).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Fight @ Universidad |
| 2 |  |  | 1 · Fight @ Universidad |
| 3 |  |  | 2 · Use (Capsula) |
| 4 |  |  | 3 · Escape @ GarajeCosme |
| 5 |  |  | 3 · Escape @ GarajeCosme |

## Errores

_Ninguno._


## Aplicado

- PASO 1+2 → paso 1 del juego (Fight): objetivo «llegar a la entrada del laboratorio.»
- PASO 1+2 → paso 1 del juego (Fight): 37 frases al cumplirlo (escena ligera «Saga_17_G1_2_Fin», sin quitar el control)
- PASO 3 → paso 2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Capsula» (25 frases)
- PASO 4+5 → paso 3 del juego (Escape): 48 frases al empezar el paso (escena ligera «Saga_17_G4_5_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- Momento de la biografía: «Rescataste a Cosme de la dimensión 66-B»

## Adaptado (y por qué)

- PASO 1+2: no hay paso de antes que pueda lanzar las 37 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 3 (línea 543) · Pip: «Ya está preparado.» → «Ya está preparad{o/a}.»

## Avisos

- PASO 2 (línea 329): condición «una cámara detecta al jugador» con una variable que el juego aún no guarda (UnaCamaraDetectaAlJugador)
- PASO 5 (línea 1364): «Noche» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Prepara el equipo de rescate.
- PASO 1 · Al terminar:: Pip: Equipo preparado.
- PASO 2 · Objetivo: llegar a la entrada del laboratorio.: 
- PASO 3 · OBJETIVO: Encuentra a Cosme.
- PASO 3 · OBJETIVO: Libera a Cosme.
- PASO 5 · MOMENTO DE BIOGRAFÍA: «Rescataste a Cosme de la dimensión 66-B»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
