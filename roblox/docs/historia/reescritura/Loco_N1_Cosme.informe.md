# Informe de la reescritura · Loco_N1_Cosme

Guion: `docs/historia/reescritura/Loco_N1_Cosme.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Loco_N1_Cosme`.
Datos: `src/shared/LifeStory/Guiones/Loco_N1_Cosme.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre (hablar con Cosme, las tres piezas con su objeto, volver al garaje y la prueba). Las marcas del guion se guardan con las que ya usa la historia: marca_secreto_cosme/secreto_cosme → SecretoCosme, marca_grieta_vista → GrietaVista, bigotes_habla → BigotesHabla (la da la conversación del chip, como antes). decision_cosme, confianza_cosme, relacion_cosme_desde_infancia y grieta_resonancia_01 no las lee ninguna misión: no se crean (la diferencia ya la dan la relación con Cosme y el rasgo de cada opción). Las dos respuestas posibles a «¿Dónde has encontrado eso?» se dicen las dos, una detrás de otra (el guion las da como «OPCIÓN» sin efectos). Los SFX (golpe, zumbido, explosión) y el humo de colores no tienen pista propia: pendiente de sonido/efectos.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Presentacion» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Tornillo) |
| 2.2 |  |  | 2.2 · Use (Bobina) |
| 2.3 |  |  | 2.3 · Use (Gato) |
| 3 |  |  | 3 · Reach @ GarajeCosme |
| 4 | Scene |  | 4 · Scene «Prueba» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Presentacion»): conversación «Presentacion» con 27 frases nuevas (música Descubrimiento)
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Tornillo» (2 frases)
- PASO 2.1 → paso 2.1 del juego (Use): objetivo «Busca el tornillo cerca de la fuente del parque.»
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Bobina» (8 frases)
- PASO 2.2 → paso 2.2 del juego (Use): objetivo «Recupera la bobina en la heladería.»
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Chip» (7 frases)
- PASO 2.3 → paso 2.3 del juego (Use): objetivo «Busca el chip. Bigotes lo tiene.»
- PASO 3 → paso 3 del juego (Reach): objetivo «Lleva las tres piezas a Cosme.»
- PASO 3 → paso 3 del juego (Reach): 1 frases al empezar el paso (escena ligera «Loco_N1_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Scene «Prueba»): conversación «Prueba» con 20 frases nuevas (música Descubrimiento→Tension)

## Adaptado (y por qué)

- frase quitada (es una acotación, no se dice): «Segundo golpe.»
- PASO 1 · opción A: «decision_cosme = ayudar» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 1 · opción B: «decision_cosme = preguntar» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2.2: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- frase quitada (es una acotación, no se dice): «Lo conecta.»
- frase quitada (es una acotación, no se dice): «SFX: zumbido.»
- frase quitada (es una acotación, no se dice): «…»
- frase quitada (es una acotación, no se dice): «Pequeño beat cómico.»
- frase quitada (es una acotación, no se dice): «…»
- PASO 4: «confianza_cosme = responsable» no se guarda aparte (el mapa la deja como condición o ya la da el juego)

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo mostrado:: Lugar: Garaje de Cosme.
- PASO 1 · SFX:: * Golpe metálico. / * Zumbido eléctrico. / * Pequeña explosión. / * Algo rueda por el suelo.
- PASO 1 · OBJETIVO: 
- PASO 2.1 · Objetivo:: Llegada
- PASO 2.2 · Objetivo:: El jugador encuentra una bobina metálica dentro de un helado.
- PASO 2.3 · Objetivo:: El jugador encuentra a Bigotes en el colegio.
- PASO 3 · Objetivo:: Al acercarse al garaje, el jugador escucha a Cosme hablando solo.
- PASO 4 · DIRECCIÓN DE ACTUACIÓN: Cosme debe tener dos capas. / Cosme: Capa exterior
- PASO 4 · DIRECCIÓN DE SONIDO: Garaje
- PASO 4 · DIRECCIÓN DE ILUMINACIÓN: Durante la vida normal:
- PASO 4 · DIRECCIÓN DE CÁMARA: La cámara debe contar la historia.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
