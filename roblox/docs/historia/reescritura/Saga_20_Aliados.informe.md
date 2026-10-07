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

- PASO 1 → paso 1 del juego (Talk «Lista»): conversación «Lista» con 14 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Talk «Compis»): conversación «Compis» con 10 frases nuevas
- PASO 2.2: efectos del guion sumados a la conversación «Cronos»: cronos_aliado = true · cronos_aliado_confirmado = true
- PASO 2.2 → paso 2.2 del juego (Talk «Cronos»): conversación «Cronos» con 4 frases nuevas
- PASO 2.3: efectos del guion sumados a la conversación «Bigotes»: duque_de_gatonia = true · bigotes_aliado_confirmado = true · gatos_de_gatonia_activados = true
- PASO 2.3 → paso 2.3 del juego (Talk «Bigotes»): conversación «Bigotes» con 6 frases nuevas
- PASO 2.4: efectos del guion sumados a la conversación «Rex»: rex_se_queda = true · rex_aliado_confirmado = true
- PASO 2.4 → paso 2.4 del juego (Talk «Rex»): conversación «Rex» con 4 frases nuevas
- PASO 2.5 → paso 2.5 del juego (Talk «Perez»): conversación «Perez» con 3 frases nuevas
- PASO 2.7: efectos del guion sumados a la conversación «Malvado»: conoce_tu_malvado = true · malvado_66b_aliado = true · malvado_66b_aliado = true
- PASO 2.7 → paso 2.7 del juego (Talk «Malvado»): conversación «Malvado» con 6 frases nuevas
- PASO 3 → paso 3 del juego (Scene «Reunion»): conversación «Reunion» con 26 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.1: «ivan_aliado_confirmado = true» no la lee ninguna misión: no se crea
- PASO 2.1: «candela_aliada_confirmada = true» no la lee ninguna misión: no se crea
- PASO 2.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.2: «cronos_aliado_confirmado = true» no la lee ninguna misión: no se crea
- PASO 2.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.3: «bigotes_aliado_confirmado = true» no la lee ninguna misión: no se crea
- PASO 2.3: «gatos_de_gatonia_activados = true» no la lee ninguna misión: no se crea
- PASO 2.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.4: «rex_aliado_confirmado = true» no la lee ninguna misión: no se crea
- PASO 2.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.5: «huelga_raton_perez = true» no la lee ninguna misión: no se crea
- PASO 2.5: «raton_perez_aliado = true» no la lee ninguna misión: no se crea
- PASO 2.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.7: la elección tiene 2 opciones y solo 0 grupos de respuesta detrás: las demás ramas siguen sin respuesta propia
- PASO 2.7: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2.7: «malvado_66b_aliado = true» no la lee ninguna misión: no se crea
- PASO 2.7: «malvado_66b_aliado = true» no la lee ninguna misión: no se crea
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 3: «saga_20_completada = true» no la lee ninguna misión: no se crea
- PASO 3: «equipo_aliados_reunido = true» no la lee ninguna misión: no se crea
- PASO 3: «servidor_megaverso_localizado = true» no la lee ninguna misión: no se crea
- PASO 3: «alianzas_activas_registradas = true» no la lee ninguna misión: no se crea
- PASO 3: «servidor_megaverso_localizado = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2.5 (línea 488) · RatonPerez: «Así que vine preparado.» → «Así que vine preparad{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2.1 · OBJETIVO: Explicar la situación sin convertir la escena en una exposición larga.
- PASO 2.1 · FLAG: 
- PASO 2.2 · FLAG: 
- PASO 2.3 · FLAG: 
- PASO 2.4 · OBJETIVO: Busca a Rex.
- PASO 2.4 · FLAG: 
- PASO 2.5 · FLAG: 
- PASO 2.6 · FLAG: 
- PASO 3 · OBJETIVO DESBLOQUEADO: 
- PASO 3 · DIRECCIÓN DE ACTUACIÓN: Los aliados no deben formar una fila inmóvil.
- PASO 3 · DIRECCIÓN DE CÁMARA: Utilizar exclusivamente:
- PASO 3 · DIRECCIÓN MUSICAL: Utilizar exclusivamente:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
