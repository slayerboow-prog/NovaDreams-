# Informe de la reescritura · Mar_00_Arrecife

Guion: `docs/historia/reescritura/Mar_00_Arrecife.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Mar_00_Arrecife`.
Datos: `src/shared/LifeStory/Guiones/Mar_00_Arrecife.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Prólogo del mar (fase 1, docs/mar/civilizacion-marina.md). Ilun no es actor de la escena: vive en el agua con su cola (Services/SeaCivService) y se acerca a la red mientras te toca hablar con él. Las frases de los pasos de nadar son del narrador.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Action | Jardín de coral del sur | 1 · Reach @ Mar_Arrecife |
| 2 | Action | Jardín de coral del sur | 2 · Group |
| 3 | Talk | Jardín de coral del sur | 3 · Talk «Concha» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Reach): objetivo «Bucea en el jardín de coral del sur»
- PASO 2 → paso 2 del juego (Group): objetivo «Suelta los tres nudos de la red»
- PASO 2 → paso 2 del juego (Group): 1 frases al empezar el paso (escena ligera «Mar00_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 3 del juego (Talk «Concha»): conversación «Concha» con 8 frases nuevas (música Intima)

## Adaptado (y por qué)

_Nada: todo se aplicó tal cual._


## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 3 (línea 37) · Ilun: «Tranquilo, «seco» no es un insulto. Así llamamos a los que vivís arriba, donde no hay agua.» → «Tranquil{o/a}, «seco» no es un insulto. Así llamamos a los que vivís arriba, donde no hay agua.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: «Bucea en el jardín de coral del sur»: Narrador: Entre los corales, algo brilla. No es un pez. Los peces no tiran de una red.
- PASO 2 · OBJETIVO: «Suelta los tres nudos de la red»: Narrador: Una red vieja, llena de algas. Dentro se mueve alguien con una cola de escamas azules.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
