# Informe de la reescritura · Siroco_01_HoraRoja

Guion: `docs/historia/reescritura/Siroco_01_HoraRoja.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Siroco_01_HoraRoja`.
Datos: `src/shared/LifeStory/Guiones/Siroco_01_HoraRoja.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Saga 2 · Siroco (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Siroco_Llegada), correr detrás de Rafa al taller, la cantimplora y el agua (efecto de la frase del juego), beber (HazardCountered) y la charla con Nina.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Dialogo | Plataforma del Muelle de Velas | 2 · Talk «Llegada» |
| 2 | Dialogo | Dentro del taller de Rafa | 4 · Scene «Taller» |
| 3 | Dialogo | Dentro del taller de Rafa | 6 · Talk «Nina» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 2 del juego (Talk «Llegada»): conversación «Llegada» con 3 frases nuevas (música Tension)
- PASO 2 → paso 4 del juego (Scene «Taller»): conversación «Taller» con 4 frases nuevas (música Descubrimiento)
- PASO 3 → paso 6 del juego (Talk «Nina»): conversación «Nina» con 4 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 (línea 17): la acotación «(brazos cruzados)» no tiene gesto en el juego: se queda solo la frase
- PASO 2: el guion lo escribe como [Dialogo] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 2: una frase del juego daba efectos (Items): se conservan al final de la conversación
- PASO 3: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 10) · RafaQuiroga: «Rafa Quiroga. El Zorro. Campeón de la Gran Vuelta. Bueno, lo fui. ¡Corre, que se te derriten las botas!» → «Rafa Quiroga. El Zorro. Campe{ón/ona} de la Gran Vuelta. Bueno, lo fui. ¡Corre, que se te derriten las botas!»

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
