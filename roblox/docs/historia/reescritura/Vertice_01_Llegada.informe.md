# Informe de la reescritura · Vertice_01_Llegada

Guion: `docs/historia/reescritura/Vertice_01_Llegada.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Vertice_01_Llegada`.
Datos: `src/shared/LifeStory/Guiones/Vertice_01_Llegada.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Saga 2 · Vértice (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Vertice_Llegada), Cosme, la plaza, Gil (la gorra y los inhibidores son la recompensa) y el medidor de vigilancia en aviso y de vuelta a la normalidad.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Dialogo | Plataforma de Distrito Cero | 2 · Talk «Llegada» |
| 2 | Dialogo | Estatua del Primer Cliente | 4 · Talk «Bienvenida» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 2 del juego (Talk «Llegada»): conversación «Llegada» con 3 frases nuevas (música Descubrimiento)
- PASO 2 → paso 4 del juego (Talk «Bienvenida»): conversación «Bienvenida» con 6 frases nuevas (música Descubrimiento)

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

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
