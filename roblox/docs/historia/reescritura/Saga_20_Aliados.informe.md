# Informe de la reescritura · Saga_20_Aliados

Guion: `docs/historia/reescritura/Saga_20_Aliados.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_20_Aliados`.
Datos: `src/shared/LifeStory/Guiones/Saga_20_Aliados.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la lista de Cosme, visitar a los aliados (vienen los que ayudaste: el If de cada subpaso usa las marcas reales —CronosAliado, AliadoBigotes/Rex/Perez/Gnomos/Malvado al visitarlos, las misiones de aliados completadas— y no se toca) y la reunión en el garaje. No hay una lista nueva «AliadosActivos»: cada aliado ya guarda su marca Aliado* al visitarle (y AliadosReunidos al final), que es lo que leen Saga_23 y Saga_24. La escena del garaje coloca a los aliados con su If (solo los que vienen). La Capitana Ñoz no es una visita del juego (pendiente: su nave en la reunión si noz_aliada). El álbum de fotos y el garaje como base de operaciones con rutinas de los aliados son sistemas nuevos: no se hacen (pendiente).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Lista» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Talk «Compis» |
| 2.2 |  |  | 2.2 · Talk «Cronos» |
| 2.3 |  |  | 2.3 · Talk «Bigotes» |
| 2.4 |  |  | 2.4 · Talk «Rex» |
| 2.5 |  |  | 2.5 · Talk «Perez» |
| 2.6 |  |  | 2.6 · Talk «Gnomos» |
| 2.7 |  |  | 2.7 · Talk «Malvado» |
| 3 |  |  | 3 · Scene «Reunion» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Lista»): conversación «Lista» con 2 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Talk «Compis»): conversación «Compis» con 3 frases nuevas
- PASO 2.2 → paso 2.2 del juego (Talk «Cronos»): conversación «Cronos» con 2 frases nuevas
- PASO 2.3 → paso 2.3 del juego (Talk «Bigotes»): conversación «Bigotes» con 2 frases nuevas
- PASO 2.4 → paso 2.4 del juego (Talk «Rex»): conversación «Rex» con 1 frases nuevas
- PASO 2.5 → paso 2.5 del juego (Talk «Perez»): conversación «Perez» con 1 frases nuevas
- PASO 2.6 → paso 2.6 del juego (Talk «Gnomos»): conversación «Gnomos» con 1 frases nuevas
- PASO 3 → paso 3 del juego (Scene «Reunion»): conversación «Reunion» con 5 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.7: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica

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
