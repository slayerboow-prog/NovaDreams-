# Informe de la reescritura · Mar_02_Burbuja

Guion: `docs/historia/reescritura/Mar_02_Burbuja.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Mar_02_Burbuja`.
Datos: `src/shared/LifeStory/Guiones/Mar_02_Burbuja.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Acto I del mar (2/4). Oriana y Bartolo viven en el agua (NacaraService y SeaCivService): no son actores de la escena. La brújula de Bartolo es parte del guion, no un objeto de la mochila (fase 1).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Talk | Lonja Honda | 1 · Talk «Oriana» |
| 2 | Action | La Burbuja | 2 · Reach @ Mar_Burbuja |
| 3 | Talk | La Burbuja | 3 · Talk «Bartolo» |
| 4 | Action | La Burbuja | 4 · Group |
| 5 | Talk | La Burbuja | 5 · Talk «Trueque» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Oriana»): conversación «Oriana» con 4 frases nuevas (música Descubrimiento)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve a La Burbuja, la posada de los secos»
- PASO 3 → paso 3 del juego (Talk «Bartolo»): conversación «Bartolo» con 4 frases nuevas (música Descubrimiento)
- PASO 4 → paso 4 del juego (Group): objetivo «Busca tres conchas bonitas cerca de la posada»
- PASO 5 → paso 5 del juego (Talk «Trueque»): conversación «Trueque» con 4 frases nuevas (música Descubrimiento)

## Adaptado (y por qué)

_Nada: todo se aplicó tal cual._


## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: «Ve a La Burbuja, la posada de los secos»: Narrador: Una cúpula transparente en mitad del talud. Dentro hay luz cálida, dos camas de kelp y aire de verdad.
- PASO 4 · OBJETIVO: «Busca tres conchas bonitas cerca de la posada»: Narrador: Nácar, rosa y una de espiral. El fondo del talud está lleno de cosas que alguien perdió.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
