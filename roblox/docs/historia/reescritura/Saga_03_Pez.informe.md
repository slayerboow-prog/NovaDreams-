# Informe de la reescritura · Saga_03_Pez

Guion: `docs/historia/reescritura/Saga_03_Pez.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_03_Pez`.
Datos: `src/shared/LifeStory/Guiones/Saga_03_Pez.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: hablar con Don Escamas en el estanque, el cubo y la tarjeta que se les cae a los agentes, la huida al garaje (Escape) y la escena de la pecera. La huida no sabe si te escondes, si los agentes pasan cerca o si te alcanzan (si te pillan, el paso te devuelve al principio, como antes): esas frases del guion no salen (pendiente: frases según la distancia a los agentes en EscapeService). Los agentes que hablan son los agentes grises del reparto (AgenteGris1).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Auxilio» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Cubo) |
| 2.2 |  |  | 2.2 · Use (Tarjeta) |
| 3 |  |  | 3 · Escape @ GarajeCosme |
| 4 |  |  | 4 · Scene «Pecera» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Auxilio»): conversación «Auxilio» con 43 frases nuevas (música Descubrimiento→Tension)
- PASO 2 → paso 2 del juego (Group): objetivo «Prepara la huida de Don Escamas.»
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Cubo» (5 frases)
- PASO 2.1 → paso 2.1 del juego (Use): objetivo «Consigue algo donde Don Escamas pueda viajar.»
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Tarjeta» (10 frases)
- PASO 2.2 → paso 2.2 del juego (Use): objetivo «Busca algo que hayan dejado los agentes.»
- PASO 3 → paso 3 del juego (Escape): objetivo «Lleva a Don Escamas al garaje de Cosme sin que te atrapen.»
- PASO 3 → paso 3 del juego (Escape): 5 frases al empezar el paso (escena ligera «Saga_03_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Scene «Pecera»): conversación «Pecera» con 62 frases nuevas (música Descubrimiento)

## Adaptado (y por qué)

- PASO 1 · opción A: marca nueva «DonEscamasConfia» (don_escamas_confia = true)
- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4: «don_escamas_aliado = true» no la lee ninguna misión: no se crea
- PASO 4: «saga_03_pez_completada = true» no la lee ninguna misión: no se crea
- PASO 4: «don_escamas_conocido = true» no la lee ninguna misión: no se crea
- PASO 4: «don_escamas_aliado = true» no la lee ninguna misión: no se crea
- PASO 4: «megaverso_conocido = true» no la lee ninguna misión: no se crea
- PASO 4: «proyecto_fusion_mencionado = true» no la lee ninguna misión: no se crea
- PASO 4: «ancla_mencionada = true» no la lee ninguna misión: no se crea
- PASO 4: «dimension_66B_confirmada = true» no la lee ninguna misión: no se crea
- PASO 4: «cosimo_vinculado_megaverso = true» no la lee ninguna misión: no se crea
- PASO 4: «escama_brillante = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 133) · DonEscamas: «Cuando estoy nervioso, hablo más.» → «Cuando estoy nervios{o/a}, hablo más.»
- PASO 1 (línea 139) · DonEscamas: «Y ahora estoy MUY nervioso.» → «Y ahora estoy MUY nervios{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo:: Lugar: Estanque del parque.
- PASO 2 · Objetivo:: El jugador debe completar los objetivos en cualquier orden.
- PASO 2.1 · Objetivo:: El jugador encuentra un cubo del parque.
- PASO 2.2 · Objetivo:: El jugador explora la zona.
- PASO 3 · Objetivo:: 
- PASO 4 · Objetivo:: * Cosme / * Pip / * Don Escamas
- PASO 4 · SFX: Zumbido.
- PASO 4 · DIRECCIÓN DE LOS AGENTES: Los agentes grises no deben actuar como villanos caricaturescos. / Su comportamiento debe ser demasiado coordinado. / * caminan sincronizados / * giran la cabeza simultáneamente / * sonríen al mismo tiempo / * nunca levantan la voz / * nunca corren innecesariamente / * hablan con educación excesiva / Cósimo: Eso los hará más inquietantes.
- PASO 4 · DIRECCIÓN DE DON ESCAMAS: Don Escamas debe convertirse en un personaje recurrente.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
