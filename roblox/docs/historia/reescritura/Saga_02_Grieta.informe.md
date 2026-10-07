# Informe de la reescritura · Saga_02_Grieta

Guion: `docs/historia/reescritura/Saga_02_Grieta.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_02_Grieta`.
Datos: `src/shared/LifeStory/Guiones/Saga_02_Grieta.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el medidor de Cosme, la cinemática Grieta_Caen (se queda su cámara, los meteoritos, los cráteres que se encienden y la espera «¡Cúbrete!»: las frases de Pip según te cubras o no van con esa espera), los tres cráteres con su objeto (calcetín, paraguas, moneda 66-B, que ya se guardan como hasta ahora), Bigotes, el garaje y la escena de la perilla. La migración por fecha de esta misión no se toca. Las marcas nuevas del guion (grieta_creciendo, cosimo_introducido, voz_desconocida, moneda_66b_obtenida, bigotes_advirtio…) no las lee ninguna misión: no se crean. Lo que Pip dice si te paras o le preguntas en el camino al garaje no tiene mecánica (un paso Reach no sabe si te paras): esas frases no salen (pendiente: una charla opcional con Pip).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Medidor» |
| 2 | Cinematic |  | 2 · Cinematic «Grieta_Caen» |
| 3 |  |  | 3 · Group |
| 3.1 |  |  | 3.1 · Use (Calcetin) |
| 3.2 |  |  | 3.2 · Use (Paraguas) |
| 3.3 |  |  | 3.3 · Use (Moneda) |
| 4 |  |  | 4 · Talk «Bigotes» |
| 5 |  |  | 5 · Reach @ GarajeCosme |
| 6 | Scene |  | 6 · Scene «Perilla» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Medidor»): conversación «Medidor» con 43 frases nuevas (música Descubrimiento→Tension)
- PASO 2 → paso 2 del juego (Cinematic «Grieta_Caen»): la escena «Grieta_Caen» se cuenta con el guion nuevo (misma escena, 7 planos, 16 frases, 41.2 s, música Tension)
- PASO 3.1 → paso 3.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Calcetin» (6 frases)
- PASO 3.1 → paso 3.1 del juego (Use): objetivo «Investiga el cráter junto a la fuente.»
- PASO 3.2 → paso 3.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Paraguas» (2 frases)
- PASO 3.2 → paso 3.2 del juego (Use): objetivo «Investiga el cráter de la zona de juegos.»
- PASO 3.3 → paso 3.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Moneda» (6 frases)
- PASO 3.3 → paso 3.3 del juego (Use): objetivo «Investiga el tercer cráter.»
- PASO 4 → paso 4 del juego (Talk «Bigotes»): conversación «Bigotes» con 28 frases nuevas (música Tension)
- PASO 5 → paso 5 del juego (Reach): objetivo «Lleva los objetos al garaje de Cosme.»
- PASO 6 → paso 6 del juego (Scene «Perilla»): conversación «Perilla» con 35 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion no trae planos para «Grieta_Caen»: se conservan los de la escena de antes
- PASO 3 → paso 3 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: «bigotes_grieta_advertencia = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 4: «voz_desconocida = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «grieta_acto1_02_completada = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «grieta_creciendo = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «cosimo_introducido = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «cosimo_referencia_01 = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «voz_desconocida = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «moneda_66b_obtenida = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «bigotes_advirtio = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 6: «pip_confia_jugador = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 101) · Cosme: «Mi vecino/a favorito/a. Ven.» → «Mi vecin{o/a} favorit{o/a}. Ven.»
- PASO 5 (línea 998) · Pip: «Señor/a, deberíamos continuar.» → «Señor{/a}, deberíamos continuar.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo:: Lugar: Garaje de Cosme.
- PASO 1 · OBJETIVO: 
- PASO 2 · OBJETIVO: 
- PASO 3.1 · Objetivo:: El jugador encuentra un pequeño cráter.
- PASO 3.2 · Objetivo:: El cráter está junto al patio.
- PASO 3.3 · Objetivo:: Esta vez no hay humor inmediato.
- PASO 4 · Objetivo:: Lugar: Patio del colegio.
- PASO 5 · Objetivo:: El jugador regresa con Pip.
- PASO 6 · DIRECCIÓN DE ACTUACIÓN: Primera mitad: / * energía / * humor / * movimientos rápidos / * gestos grandes / Después de la moneda: / * hombros ligeramente caídos / * habla más despacio / * evita mirar al jugador / * manos quietas / * silencios más largos / El jugador debe poder entender que Cósimo le da miedo a Cosme sin que nadie tenga que decirlo. / Pip / Primero: / * mayordomo elegante / * humor seco / Después de la moneda: / * postura más rígida / * menos bromas / * mirada hacia Cosme / * preocupación / Bigotes / Debe parecer gracioso hasta que menciona la voz. / En ese momento: / * deja de moverse / * mira directamente al jugador / * baja ligeramente la cabeza / * habla más despacio / Esto hará que el jugador entienda: / Cosme: Vale. Hasta el gato sabe que algo va mal.
- PASO 6 · DIRECCIÓN MUSICAL: Utilizar exclusivamente:
- PASO 6 · DIRECCIÓN VISUAL: La Grieta nunca debe parecer una simple textura colocada en el cielo.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
