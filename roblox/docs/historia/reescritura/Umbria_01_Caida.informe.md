# Informe de la reescritura · Umbria_01_Caida

Guion: `docs/historia/reescritura/Umbria_01_Caida.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Umbria_01_Caida`.
Datos: `src/shared/LifeStory/Guiones/Umbria_01_Caida.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Saga 2 · Umbría (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Umbria_Llegada), bajar con Garza al Suelo Hondo, las esporas en aviso (HazardChanged), la mascarilla y el ungüento (efecto de la frase del juego), untarse (HazardCountered) y la charla en la plaza.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Dialogo | Claro del Ascensor | 2 · Talk «Llegada» |
| 2 | Dialogo | El Suelo Hondo | 5 · Talk «Mascarilla» |
| 3 | Dialogo | Plaza de las Raíces | 7 · Talk «Vuelta» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 2 del juego (Talk «Llegada»): conversación «Llegada» con 3 frases nuevas (música Descubrimiento)
- PASO 2 → paso 5 del juego (Talk «Mascarilla»): conversación «Mascarilla» con 4 frases nuevas (música Tension)
- PASO 3 → paso 7 del juego (Talk «Vuelta»): conversación «Vuelta» con 3 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1 (línea 11): la acotación «(brazos cruzados)» no tiene gesto en el juego: se queda solo la frase
- PASO 1: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: una frase del juego daba efectos (Items): se conservan al final de la conversación
- PASO 3 (línea 28): la acotación «(pausa)» no tiene gesto en el juego: se queda solo la frase
- PASO 3: el guion lo escribe como [Dialogo] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 20) · Garza: «Úntate el ungüento debajo de la nariz. Huele a miel. Mi madre me lo ponía de pequeño.» → «Úntate el ungüento debajo de la nariz. Huele a miel. Mi madre me lo ponía de pequeñ{o/a}.»

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
