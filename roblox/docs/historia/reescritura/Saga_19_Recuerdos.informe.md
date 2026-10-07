# Informe de la reescritura · Saga_19_Recuerdos

Guion: `docs/historia/reescritura/Saga_19_Recuerdos.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_19_Recuerdos`.
Datos: `src/shared/LifeStory/Guiones/Saga_19_Recuerdos.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la lista de Pip, llevar a Cosme al microondas del garaje, a la granja de Villaverde y al anclaje del cielo, y la escena en la que vuelve. Cada recuerdo de Cosme sale solo si lo viviste: su nombre (el recuerdo TuNombre de Saga_18), los clones (LosClones), el tirachinas de Abu (TirachinasAbu), los calcetines (CosasPerdidas, Saga_05), la credencial (AyudanteOficial, Saga_07), el vecino secreto (SecretoCosme, Loco_N1) y el rescate (CosmeRescatado, Saga_17). No se crean marcas nuevas.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Lista» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Microondas) |
| 2.2 |  |  | 2.2 · Use (Gallinero) |
| 2.3 |  |  | 2.3 · Use (Cielo) |
| 3 | Scene |  | 3 · Scene «Vuelve» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Lista»): conversación «Lista» con 14 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Microondas» (4 frases)
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Gallina» (6 frases)
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Anclaje» (2 frases)
- PASO 3 → paso 3 del juego (Scene «Vuelve»): conversación «Vuelve» con 20 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 1: «cosme_recuerda_tu_nombre = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.3: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: «saga_19_completada = true» no la lee ninguna misión: no se crea
- PASO 3: «cosme_recuerdos_completos = true» no la lee ninguna misión: no se crea
- PASO 3: «cosme_memoria_progreso = 100» no la lee ninguna misión: no se crea
- PASO 3: «cosme_recuerda_todo = true» no la lee ninguna misión: no se crea
- PASO 3: «cosme_sabe_liberar_ancla = true» no la lee ninguna misión: no se crea
- PASO 3: «album_recuerdos_obtenido = true» no la lee ninguna misión: no se crea
- PASO 3: «equipo_rescate_activo = true» no la lee ninguna misión: no se crea
- PASO 3: «recuerdo_microondas = true» no la lee ninguna misión: no se crea
- PASO 3: «recuerdo_granja = true» no la lee ninguna misión: no se crea
- PASO 3: «recuerdo_ancla = true» no la lee ninguna misión: no se crea
- PASO 3: «cosme_revela_como_liberar_ancla = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 198) · Cosme: «Es lo único que sé seguro.» → «Es lo único que sé segur{o/a}.»

## Avisos

- PASO 2.2 (línea 609): condición «gallina_seis_metros = true» con una variable que el juego aún no guarda (GallinaSeisMetros)
- PASO 2.2 (línea 613): condición «gallina_seis_metros = true» con una variable que el juego aún no guarda (GallinaSeisMetros)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 3 · DIRECCIÓN DE ACTUACIÓN: Inicio: / * confundido; / * inseguro; / * mira objetos buscando significado. / * empieza a reconocer sensaciones; / * ríe antes de comprender por qué; / * se sorprende de sus propios recuerdos. / * baja el tono; / * movimientos lentos; / * contacto visual con el jugador; / * orgullo contenido. / Parque: Final:
- PASO 3 · DIRECCIÓN DE CÁMARA: Usar exclusivamente:
- PASO 3 · DIRECCIÓN MUSICAL: Usar exclusivamente:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
