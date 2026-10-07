# Informe de la reescritura · Uni01_PrimerDia

Guion: `docs/historia/reescritura/Uni01_PrimerDia.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Uni01_PrimerDia`.
Datos: `src/shared/LifeStory/Guiones/Uni01_PrimerDia.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre (los 14 pasos del primer día). El guion nuevo es sobre todo un documento de diseño (NPC del campus, orientación, el aula 204 con un acceso cerrado…): eso ya lo cuentan el campus, secretaría, la facultad, Beltrán y la comida del juego, y no se crean pasos nuevos. Lo que sí trae frases son los mensajes de Pip sobre Cosme (PASO 6-7): salen en una escena nueva justo después de los mensajes del grupo (Uni01_Mensajes, que no cambia). Pendiente para el autor: la orientación con NPC dinámicos y ayudar a otro estudiante (ayudo_nuevo_estudiante) necesitarían pasos nuevos.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | — |
| 2 |  |  | — |
| 3 |  |  | — |
| 4 |  |  | — |
| 5 |  |  | — |
| 6 |  |  | 14 · Cinematic «Uni01_Mensajes» |
| 7 |  |  | 14 · Cinematic «Uni01_Mensajes» |
| 8 |  |  | — |

## Errores

_Ninguno._


## Aplicado

- PASO 6+7 → paso 14 del juego (Cinematic «Uni01_Mensajes»): escena nueva «Uni01_G6_7» (1 planos, 10 frases, 39.1 s) justo después de «Uni01_Mensajes», que se queda como estaba

## Adaptado (y por qué)

- PASO 1 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 2 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 3 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 4 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 5 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 8 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 6: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 7: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 6+7: el guion no trae planos para la cinemática: un plano general lento del sitio

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 7 · OBJETIVO: Busca un lugar tranquilo para llamar a Pip.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
