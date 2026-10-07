# Informe de la reescritura · Saga_09_Archivo

Guion: `docs/historia/reescritura/Saga_09_Archivo.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_09_Archivo`.
Datos: `src/shared/LifeStory/Guiones/Saga_09_Archivo.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: Pip, la caja del archivo, la cinta en el proyector (eres el Ancla: SabeQueEsAncla) y Cosme en la puerta con la decisión de perdonarle o enfadarte (PerdonaACosme / EnfadoConCosme, que leen las misiones siguientes). Lo que Cosme dice de la Fusión depende de SabeFusion (Saga_08).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Pip» |
| 2 |  |  | 2 · Use (Caja) |
| 3 |  |  | 3 · Use (Proyector) |
| 4 |  |  | 4 · Talk «Cosme» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Pip»): conversación «Pip» con 16 frases nuevas
- PASO 2 → paso 2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Caja» (9 frases)
- PASO 3 → paso 3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Proyector» (28 frases)
- PASO 4 → paso 4 del juego (Talk «Cosme»): conversación «Cosme» con 50 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4 · opción A: sin equivalente: «cosme_relationship +12»
- PASO 4 · opción A: marca nueva «PerdonaCosme» (perdona_cosme = true)
- PASO 4 · opción B: sin equivalente: «cosme_relationship +4»
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: «ancla_revelada = true» no la lee ninguna misión: no se crea
- PASO 4: «vio_la_noche = true» no la lee ninguna misión: no se crea
- PASO 4: «archivo_pip_abierto = true» no la lee ninguna misión: no se crea
- PASO 4: «cosme_secret_revealed = true» no la lee ninguna misión: no se crea
- PASO 4: «Flags» del guion no se pone a toda la conversación «Cosme» (es de una rama o una nota; lo pone la mecánica)

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 110) · Pip: «Está nervioso.» → «Está nervios{o/a}.»
- PASO 3 (línea 908) · Narrador: «Algo pequeño.» → «Algo pequeñ{o/a}.»

## Avisos

- PASO 3 (línea 450): «Objeto» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 4 (línea 1885): «Nacimiento / estabilización» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 4 (línea 1891): «Revelación del Ancla» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 4 · DIRECCIÓN DE LA CINEMÁTICA «LA NOCHE»: No mostrar la cinta como una simple pantalla rectangular flotante.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
