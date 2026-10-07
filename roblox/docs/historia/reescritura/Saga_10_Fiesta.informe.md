# Informe de la reescritura · Saga_10_Fiesta

Guion: `docs/historia/reescritura/Saga_10_Fiesta.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_10_Fiesta`.
Datos: `src/shared/LifeStory/Guiones/Saga_10_Fiesta.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: tus amigos en la fiesta de MegaVerso (Omar), el sabotaje sin que te vean (cabina del DJ, taquilla y cuenta atrás), la pelea con los de MegaVerso en la plaza y la escena final (FiestaSaboteada).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Amigos» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Cabina) |
| 2.2 |  |  | 2.2 · Use (Taquilla) |
| 2.3 |  |  | 2.3 · Use (Cuenta) |
| 3 |  |  | 3 · Fight @ PlazaCentro |
| 4 | Scene |  | 4 · Scene «Final» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Amigos»): conversación «Amigos» con 37 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Cabina» (5 frases)
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Taquilla» (5 frases)
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Cuenta» (9 frases)
- PASO 3 → paso 3 del juego (Fight): 8 frases al empezar el paso (escena ligera «Saga_10_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4: efectos del guion sumados a la conversación «Final»: fiesta_saboteada = true · fiesta_musica = sabotaje · fiesta_entradas = sabotaje · fiesta_cuenta_atras = sabotaje · omar_conoce_grieta = true · omar_sabe_fusion = true · ancla_revelada = true · sabe_que_es_ancla = true
- PASO 4 → paso 4 del juego (Scene «Final»): conversación «Final» con 26 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: «fiesta_musica = sabotaje» no la lee ninguna misión: no se crea
- PASO 4: «fiesta_entradas = sabotaje» no la lee ninguna misión: no se crea
- PASO 4: «fiesta_cuenta_atras = sabotaje» no la lee ninguna misión: no se crea
- PASO 4: «omar_conoce_grieta = true» no la lee ninguna misión: no se crea
- PASO 4: «omar_sabe_fusion = true» no la lee ninguna misión: no se crea
- PASO 4: «ancla_revelada = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 398) · Omar: «Él/Ella dice que sí.» → «{Él/Ella} dice que sí.»

## Avisos

- PASO 4 (línea 1624): «Descubrimiento de Cósimo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Aparece:
- PASO 1 · OBJETIVO: Averigua qué está preparando MegaVerso.
- PASO 3 · Objetivo:: 
- PASO 4 · DIRECCIÓN DE LA FIESTA: La primera mitad debe ser luminosa y divertida.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
