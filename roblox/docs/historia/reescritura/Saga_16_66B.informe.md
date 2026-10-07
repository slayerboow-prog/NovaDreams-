# Informe de la reescritura · Saga_16_66B

Guion: `docs/historia/reescritura/Saga_16_66B.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_16_66B`.
Datos: `src/shared/LifeStory/Guiones/Saga_16_66B.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: cruzar a la Valmar 66-B, mirar la plaza, hablar con tu yo malvado (el mapa y ConoceTuMalvado), huir de los drones hasta la universidad malvada (Escape) y la entrada al laboratorio subterráneo. Lo que dice Pip de las coordenadas sale con CoordenadasCosimo (Saga_14) y lo de la grabación con GrabacionLaboratorio (Saga_15).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Use (Cartel) |
| 3 |  |  | 3 · Talk «Malvado» |
| 4 |  |  | 4 · Escape @ Universidad |
| 5 |  |  | 5 · Use (Rejilla) |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 12 frases al cumplirlo (escena ligera «Saga_16_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Cartel» (4 frases)
- PASO 2 → paso 2 del juego (Use): objetivo «investigar la Plaza Mayor.»
- PASO 3 → paso 3 del juego (Talk «Malvado»): conversación «Malvado» con 2 frases nuevas
- PASO 4 → paso 4 del juego (Escape): objetivo «llegar a la universidad 66-B.»
- PASO 4 → paso 4 del juego (Escape): 5 frases al empezar el paso (escena ligera «Saga_16_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rejilla» (19 frases)

## Adaptado (y por qué)

- PASO 1: 7 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Cruzar el portal hacia la dimensión 66-B.
- PASO 2 · Objetivo: investigar la Plaza Mayor.: El jugador debe localizar tres elementos, no simplemente pulsar un único cartel.
- PASO 2 · Flag:: 
- PASO 4 · Objetivo: llegar a la universidad 66-B.: Lugar: Plaza -> calles -> Universidad de Valmar 66-B
- PASO 5 · DIRECCIÓN DE ACTUACIÓN: Tú 66-B
- PASO 5 · Objetivo:: Vuelve al garaje de Cosme. / Al llegar: / Pip estará preparando el equipo. / Sobre una mesa habrá: / * el mapa de 66-B; / * la grabación de Ñoz; / * el mando dimensional; / * el cuaderno de Cosme; / * el collar de Gatonia. / La cámara hará un breve Inserto sobre cada objeto. / Después, Pip: / Pip: Mañana vamos a por el señor.
- PASO 5 · MOMENTO DE BIOGRAFÍA: Pip: Entraste en la Valmar malvada

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
