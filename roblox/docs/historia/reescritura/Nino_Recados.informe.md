# Informe de la reescritura · Nino_Recados

Guion: `docs/historia/reescritura/Nino_Recados.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Nino_Recados`.
Datos: `src/shared/LifeStory/Guiones/Nino_Recados.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre (comprar en la librería y en la farmacia con BoughtItem, volver a casa); sin marcas ni medicinas reales. La librería y la farmacia no tienen dependiente en el reparto del juego: lo que dicen sale como frase del narrador («Dependiente: «…»»). El favor opcional al vecino no tiene mecánica en esta misión: sus frases («si ayuda») quedan sin salir (pendiente: un paso opcional). «recado_se_oriento_solo» (volver sin activar el GPS) no se marca: el paso Reach no sabe si el GPS estuvo encendido y añadirlo sería tocar LifeStoryService/Gps (pendiente); sus frases quedan sin salir. «recado_recordo_todo» siempre es verdad (no se puede terminar sin comprar las dos cosas).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Acción del jugador | Librería del barrio | 1 · Event @ Libreria |
| 2 | Acción del jugador | Farmacia del barrio | 2 · Event @ Farmacia |
| 3 | Ir a | Casa familiar | 3 · Reach @ CasaFamiliar |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Event): 21 frases al cumplirlo (escena ligera «Nino_Recados_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Event): 14 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Nino_Recados_G1_Fin»)
- PASO 3 → paso 3 del juego (Reach): 22 frases al empezar el paso (escena ligera «Nino_Recados_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- Momento de la biografía: «Mis primeros recados» (texto nuevo de MOMENT.PRIMEROS_RECADOS; antes «Has hecho tus primeros recados sin ayuda.»)

## Adaptado (y por qué)

- PASO 1 · opción A: rasgo nuevo «Confianza» (confianza +1)
- PASO 1: ELECCION en un paso jugable del juego (Event): no hay conversación donde preguntarla; sus respuestas se dicen como frases
- PASO 1: no hay paso de antes que pueda lanzar las 21 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1
- PASO 1: 12 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 7 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: 13 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 39) · Familia: «Te he preparado una lista. ¿Crees que puedes encargarte?» → «Te he preparad{o/a} una lista. ¿Crees que puedes encargarte?»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 3 · MOMENTO DE BIOGRAFÍA: «Mis primeros recados»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
