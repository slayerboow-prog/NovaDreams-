# Informe de la reescritura · Saga_14_Bigotes

Guion: `docs/historia/reescritura/Saga_14_Bigotes.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_14_Bigotes`.
Datos: `src/shared/LifeStory/Guiones/Saga_14_Bigotes.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: cruzar el portal a Gatonia, huir de la policía gatuna hasta el palacio (Escape) y hablar con el presidente Bigotes XVII (el collar diplomático y las coordenadas de Cósimo, que leen las misiones siguientes). El cierre del guion va al final de esa conversación (no se añade un paso).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Escape @ PlazaCentro |
| 3 |  |  | 3 · Talk «Presidente» |
| 4 |  |  | 3 · Talk «Presidente» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 9 frases al cumplirlo (escena ligera «Saga_14_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Escape): 5 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Saga_14_G1_Fin»)
- PASO 3+4 → paso 3 del juego (Talk «Presidente»): conversación «Presidente» con 67 frases nuevas (música Descubrimiento→Tension)

## Adaptado (y por qué)

- PASO 1: 6 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3+4: «saga_14_completada = true» no la lee ninguna misión: no se crea
- PASO 3+4: «bigotes_ayudo = true» no la lee ninguna misión: no se crea
- PASO 3+4: «coordenadas_66B_obtenidas = true» no la lee ninguna misión: no se crea
- PASO 3+4: «collar_gatonia_obtenido = true» no la lee ninguna misión: no se crea
- PASO 3+4: «equipo_rescate_activo = true» no la lee ninguna misión: no se crea
- PASO 3+4: «bigotes_reconoce_jugador = true» no la lee ninguna misión: no se crea
- PASO 3+4: «Flags» del guion no se pone a toda la conversación «Presidente» (es de una rama o una nota; lo pone la mecánica)

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 72) · Ivan: «Perfecto. Me quedo mucho más tranquilo.» → «Perfecto. Me quedo mucho más tranquil{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Entrar en la dimensión G-4.
- PASO 1 · Objetivo desbloqueado:: Llega al palacio presidencial de Gatonia.
- PASO 3 · OBJETIVO: Bigotes XVII: Hablar con Bigotes sobre la dimensión 66-B.
- PASO 4 · DIRECCIÓN DE ACTUACIÓN: Los NPC nunca deben quedarse completamente inmóviles mientras hablan.
- PASO 4 · Al terminar (momento de la biografía):: «Pediste ayuda al presidente de los gatos»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
