# Informe de la reescritura · Deriva_01_Misericordia

Guion: `docs/historia/reescritura/Deriva_01_Misericordia.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Deriva_01_Misericordia`.
Datos: `src/shared/LifeStory/Guiones/Deriva_01_Misericordia.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La Deriva, Acto I (expansión espacial). Dos cinemáticas propias (Happenings/Deriva) y tres registros que se escuchan andando; aquí, las frases por radio entre pasos. Tono para 13-15 años: hay muertos, fuera de plano.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Action | La Misericordia | 2 · Event (DerivaStep) |
| 2 | Action | La Misericordia | 5 · Event (DerivaStep) |
| 3 | Action | La Misericordia | 8 · Event (DerivaStep) |
| 4 | Action | La Misericordia | 9 · Event (DerivaStep) |
| 5 | Action | La Misericordia | 10 · Event (DerivaStep) |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 2 del juego (Event): 3 frases al empezar el paso (escena ligera «Deriva1_G1_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 2 → paso 5 del juego (Event): 2 frases al empezar el paso (escena ligera «Deriva1_G2_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 8 del juego (Event): 2 frases al empezar el paso (escena ligera «Deriva1_G3_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 9 del juego (Event): 2 frases al empezar el paso (escena ligera «Deriva1_G4_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 10 del juego (Event): 2 frases al empezar el paso (escena ligera «Deriva1_G5_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)

## Adaptado (y por qué)

_Nada: todo se aplicó tal cual._


## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

_Ninguna._


## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
