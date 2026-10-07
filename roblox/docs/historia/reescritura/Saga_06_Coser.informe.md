# Informe de la reescritura · Saga_06_Coser

Guion: `docs/historia/reescritura/Saga_06_Coser.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_06_Coser`.
Datos: `src/shared/LifeStory/Guiones/Saga_06_Coser.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el plan de Cosme en el garaje, los tres anclajes (parque, patio del cole y plaza), la pelea con los agentes grises por la aguja, la cinemática Grieta_Coser de siempre (con su música y la variante de Ramón en la ventana; el guion nuevo cuenta lo mismo) y la voz de Cósimo al final. Lo que Don Escamas dice del Consorcio sale con ConoceConsorcio (la tarjeta de los agentes, Saga_03) y lo de las anclas con OyoAncla (Saga_04): son las marcas que ya guarda la saga.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Plan» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Anclaje1) |
| 2.2 |  |  | 2.2 · Use (Anclaje2) |
| 2.3 |  |  | 2.3 · Use (Anclaje3) |
| 3 |  |  | 3 · Fight @ Patio |
| 4 | Cinematic |  | — |
| 5 | Scene |  | 5 · Scene «Voz» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Plan»): conversación «Plan» con 33 frases nuevas
- PASO 2 → paso 2 del juego (Group): objetivo «colocar los tres anclajes en Valmar.»
- PASO 3 → paso 3 del juego (Fight): 8 frases al empezar el paso (escena ligera «Saga_06_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «Voz»): conversación «Voz» con 34 frases nuevas
- Momento de la biografía: «Cosiste el cielo de Valmar.»

## Adaptado (y por qué)

- PASO 4 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 1: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 2.1 → paso 2.1 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.2 → paso 2.2 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.3 → paso 2.3 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 5 (línea 912) · Cosimo: «La última vez eras así de pequeño/a.» → «La última vez eras así de pequeñ{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · Objetivo: colocar los tres anclajes en Valmar.: El jugador debe recorrer la ciudad.
- PASO 3 · OBJETIVO: Desactiva los dos comunicadores.
- PASO 5 · MOMENTO DE BIOGRAFÍA: «Cosiste el cielo de Valmar.»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
