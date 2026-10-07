# Informe de la reescritura · Bebe_ExploraLaCasa

Guion: `docs/historia/reescritura/Bebe_ExploraLaCasa.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Bebe_ExploraLaCasa`.
Datos: `src/shared/LifeStory/Guiones/Bebe_ExploraLaCasa.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

FLAG DE MEMORIA: «Bebe_ExploraLaCasa_Completada» ya lo guarda el juego (misión completada); los lugares descubiertos y el vínculo familiar no tienen un sistema propio (la relación con la familia ya sube al hablar con ella); el recuerdo «LaCasa» no existe en Memories y no se inventa.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Action | Casa | 1.1 · Reach @ HomeCocina |
| 1.1 | Action | Cocina | 1.1 · Reach @ HomeCocina |
| 1.2 | Action | Salón | 1.2 · Event (BabyInteract) |
| 1.3 | Action | Habitación del protagonista | 1.3 · Event (BabyInteract) |
| 2 | Talk | Cocina | 2 · Talk @ FamiliaPadre |

## Errores

_Ninguno._


## Aplicado

- PASO 1+1.1 → paso 1.1 del juego (Reach): 6 frases al cumplirlo (escena ligera «Bebe_Casa_G1_1_1_Fin», sin quitar el control)
- PASO 1.2 → paso 1.2 del juego (Event): 4 frases al cumplirlo (escena ligera «Bebe_Casa_G1_2_Fin», sin quitar el control)
- PASO 1.3 → paso 1.3 del juego (Event): 2 frases al cumplirlo (escena ligera «Bebe_Casa_G1_3_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Talk): hablar con Familia_Padre no tiene conversación propia en el juego: sus frases son una escena con cámara al terminar de hablar (13 planos)
- PASO 2 → paso 2 del juego (Talk): 13 frases al cumplirlo (escena con cámara «Bebe_Casa_G2_Fin», sin quitar el control)

## Adaptado (y por qué)

- PASO 1+1.1: no hay paso de antes que pueda lanzar las 6 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1.1
- PASO 1+1.1: 9 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 1.2: no hay paso de antes que pueda lanzar las 4 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1.2
- PASO 1.2: 6 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 1.3: 10 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: el guion lo escribe como [Talk] y en el juego es paso jugable (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: 13 PLANO de un paso jugable (Talk) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 119) · Familia: «Aquí tienes, pequeño explorador.» → «Aquí tienes, pequeñ{o/a} explorador{/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · Al terminar (momento de la biografía):: «Has conocido a tu familia.»
- PASO 2 · FLAG DE MEMORIA:: * Bebe_ExploraLaCasa_Completada = true / * Registrar recuerdo: LaCasa / * Registrar lugares descubiertos: Cocina, Salon, Habitacion / * Registrar vínculo familiar correspondiente.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
