# Informe de la reescritura · Saga_24_Final

Guion: `docs/historia/reescritura/Saga_24_Final.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_24_Final`.
Datos: `src/shared/LifeStory/Guiones/Saga_24_Final.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el garaje, ir al patio del cole (donde clavaste el primer anclaje), la cinemática Grieta_Final (se cuenta con el guion nuevo) y el final con Cosme. «2003» pasa a «aquella noche»: la Grieta se abrió la noche en que naciste y el año depende de tu partida. Las variantes van con las marcas reales: CosimoPerdonado / CosimoArregla66B (Saga_23), ConsorcioCaido, el recuerdo CosmeRecuerda, AliadosReunidos y los mensajes de cada aliado con su marca Aliado* (Bigotes, Rex, Pérez, gnomos, Cronos, tu yo malvado, los compis); temporada_final (la Capitana Ñoz) no existe como aliado: no sale. Coser la Grieta es la cinemática de siempre (no hay una mecánica de mantener pulsado). La aguja dorada no va al inventario (no hay objeto) y la luz final en el cielo es parte de la escena, sin marcas nuevas.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Scene |  | 1 · Scene «Garaje» |
| 2 |  |  | 2 · Reach @ Patio |
| 3 | Cinematic |  | 3 · Cinematic «Grieta_Final» |
| 4 | Scene |  | 4 · Scene «Final» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Scene «Garaje»): conversación «Garaje» con 35 frases nuevas
- PASO 2 → paso 2 del juego (Reach): 9 frases al empezar el paso (escena ligera «Saga_24_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 3 del juego (Cinematic «Grieta_Final»): la escena «Grieta_Final» se cuenta con el guion nuevo (misma escena, 9 planos, 37 frases, 96.9 s)
- PASO 4 → paso 4 del juego (Scene «Final»): conversación «Final» con 33 frases nuevas

## Adaptado (y por qué)

- PASO 3: el guion no trae planos para «Grieta_Final»: se conservan los de la escena de antes
- PASO 4: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4: «saga_grieta_completada = true» no la lee ninguna misión: no se crea
- PASO 4: «grieta_cerrada = true» no la lee ninguna misión: no se crea
- PASO 4: «ancla_libre = true» no la lee ninguna misión: no se crea
- PASO 4: «jugador_es_persona = true» no la lee ninguna misión: no se crea
- PASO 4: «aguja_oro_obtenida = true» no la lee ninguna misión: no se crea
- PASO 4: «cosme_recuerda = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 2 (línea 494): «NPCs» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 3: la cinemática nueva dura 96 s (se puede saltar, pero es larga: el guion trae 9 planos)
- PASO 4 (línea 1341): «Silencio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 4 · DIRECCIÓN FINAL: La misión completa debe transmitir:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
