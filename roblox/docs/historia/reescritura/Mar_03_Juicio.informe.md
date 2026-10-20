# Informe de la reescritura · Mar_03_Juicio

Guion: `docs/historia/reescritura/Mar_03_Juicio.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Mar_03_Juicio`.
Datos: `src/shared/LifeStory/Guiones/Mar_03_Juicio.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Acto I del mar (3/4). El juicio (PASO 2) es la escena del motor Mar_Juicio (shared/LifeStory/Happenings/Mar), con estas mismas frases, planos fijos en la Concha del Consejo y sin actores de la escena: Maresa e Ilun viven en el agua con su cola y la escena no puede crear gente con piernas debajo del agua. Las demás conversaciones son de la misión.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Talk | Concha del Consejo | 1 · Talk «Guardia» |
| 2 | Cinematic | Concha del Consejo | 2 · Cinematic «Mar_Juicio» |
| 3 | Choice | Concha del Consejo | 3 · Choice |
| 4 | Action | Nácara | 4 · Event (MarJobDone) |
| 5 | Talk | Concha del Consejo | 5 · Talk «Veredicto» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Guardia»): conversación «Guardia» con 3 frases nuevas (música Tension)
- PASO 2 → paso 2 del juego (Cinematic «Mar_Juicio»): cinemática nueva «Mar03_G2» (4 planos, 7 frases, 42.7 s, música Tema) en lugar de «Mar_Juicio»
- PASO 3 → paso 3 del juego (Choice): objetivo «¿Por qué ha bajado un seco a Nácara?»
- PASO 4 → paso 4 del juego (Event): objetivo «Primera prueba: haz un turno para una Corriente»
- PASO 5 → paso 5 del juego (Talk «Veredicto»): conversación «Veredicto» con 4 frases nuevas (música Intima)

## Adaptado (y por qué)

_Nada: todo se aplicó tal cual._


## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 3 · OBJETIVO: «¿Por qué ha bajado un seco a Nácara?»: 
- PASO 4 · OBJETIVO: «Primera prueba: haz un turno para una Corriente»: Narrador: Los tablones de «Trabajar» están junto a los bancales de algas y en el paseo de las perlas-farola.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
