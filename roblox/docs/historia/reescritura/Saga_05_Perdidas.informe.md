# Informe de la reescritura · Saga_05_Perdidas

Guion: `docs/historia/reescritura/Saga_05_Perdidas.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_05_Perdidas`.
Datos: `src/shared/LifeStory/Guiones/Saga_05_Perdidas.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Ramon» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Llaves) |
| 2.2 |  |  | 2.2 · Use (Balon) |
| 2.3 |  |  | 2.3 · Use (Diario) |
| 3 |  |  | 3 · Group |
| 3.1 |  |  | 3.1 · Talk «DevolverLlaves» |
| 3.2 |  |  | 3.2 · Talk «DevolverBalon» |
| 3.3 |  |  | 3.3 · Talk «DevolverDiario» |
| 4 |  |  | 4 · Fight @ GimnasioColegio |
| 5 | Scene |  | 5 · Scene «Final» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Ramon»): conversación «Ramon» con 6 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Llaves» (1 frases)
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Diario» (6 frases)
- PASO 3.1 → paso 3.1 del juego (Talk «DevolverLlaves»): conversación «DevolverLlaves» con 3 frases nuevas
- PASO 3.2 → paso 3.2 del juego (Talk «DevolverBalon»): conversación «DevolverBalon» con 5 frases nuevas
- PASO 3.3 → paso 3.3 del juego (Talk «DevolverDiario»): conversación «DevolverDiario» con 5 frases nuevas
- PASO 4 → paso 4 del juego (Fight): 3 frases al empezar el paso (escena ligera «Saga_05_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «Final»): conversación «Final» con 4 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.2 → paso 2.2 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3 → paso 3 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- frase quitada (es una acotación, no se dice): «Lo agarra.»
- PASO 3.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- frase quitada (es una acotación, no se dice): «Lo guarda con cuidado.»
- PASO 3.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 5 (línea 833) · Narrador: «Pero después de esta noche ya no estás seguro de qué cosas pueden ser normales.» → «Pero después de esta noche ya no estás segur{o/a} de qué cosas pueden ser normales.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo: Hablar con Ramón en la entrada.: 
- PASO 2.1 · OBJETIVO: Encontrar:
- PASO 4 · OBJETIVO: Empareja los calcetines antes de que el montón vuelva a crecer.
- PASO 5 · DIRECCIÓN AAA: Esta misión no debe ejecutarse como una cadena de NPC -> diálogo -> NPC.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
