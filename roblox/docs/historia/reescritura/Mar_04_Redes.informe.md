# Informe de la reescritura · Mar_04_Redes

Guion: `docs/historia/reescritura/Mar_04_Redes.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Mar_04_Redes`.
Datos: `src/shared/LifeStory/Guiones/Mar_04_Redes.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Acto I del mar (4/4 de la fase 1). Tomé vive en los Jardines y Sargo aparece en el kelp solo para quien juega la persecución (Services/SeaCivService: huye por un camino fijo, espera si te quedas atrás y vuelve a empezar si tardas más de 150 s). La decisión no lleva frases propias: el resultado se ve en la próxima fase (cadena «El joven de la Marea Callada»).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Talk | Jardines de Cultivo | 1 · Talk «Tome» |
| 2 | Action | El bosque de kelp del norte | 2 · Reach @ Mar_KelpNorte |
| 3 | Action | El bosque de kelp del norte | 3 · Event (MarChase) |
| 4 | Talk | Barrio de las Conchas | 4 · Talk «Sargo» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Tome»): conversación «Tome» con 4 frases nuevas (música Tension)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve al bosque de kelp del norte»
- PASO 3 → paso 3 del juego (Event): objetivo «¡Persíguele por el kelp y alcánzale!»
- PASO 4 → paso 4 del juego (Talk «Sargo»): conversación «Sargo» con 4 frases nuevas (música Intima)

## Adaptado (y por qué)

_Nada: todo se aplicó tal cual._


## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: «Ve al bosque de kelp del norte»: Narrador: Tallos de kelp más altos que una casa. Entre ellos, el brillo de un cuchillo de concha.
- PASO 3 · OBJETIVO: «¡Persíguele por el kelp y alcánzale!»: Narrador: Una cola gris sale disparada entre las algas.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
