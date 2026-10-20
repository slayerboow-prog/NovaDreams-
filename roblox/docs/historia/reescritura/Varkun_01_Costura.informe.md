# Informe de la reescritura · Varkun_01_Costura

Guion: `docs/historia/reescritura/Varkun_01_Costura.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Varkun_01_Costura`.
Datos: `src/shared/LifeStory/Guiones/Varkun_01_Costura.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Prólogo del espacio de la Saga 2 (villano aprobado por el dueño). Sin cinemáticas: la nave sigue volando y las frases suenan por radio al cumplir cada paso.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Action | Ruta de los Saqueadores | 1 · Event (VarkunStep) |
| 2 | Action | Ruta de los Saqueadores | 2 · Event (VarkunStep) |
| 3 | Action | Ruta de los Saqueadores | 3 · Event (VarkunStep) |
| 4 | Action | Estación Cénit | 4 · Event (VarkunStep) |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Event): 4 frases al cumplirlo (escena ligera «Varkun1_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Event): 3 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Varkun1_G1_Fin»)
- PASO 3 → paso 3 del juego (Event): 3 frases al empezar el paso (escena ligera «Varkun1_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Event): 5 frases al empezar el paso (escena ligera «Varkun1_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)

## Adaptado (y por qué)

- PASO 1: no hay paso de antes que pueda lanzar las 4 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1

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
