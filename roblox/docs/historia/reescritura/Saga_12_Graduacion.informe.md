# Informe de la reescritura · Saga_12_Graduacion

Guion: `docs/historia/reescritura/Saga_12_Graduacion.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_12_Graduacion`.
Datos: `src/shared/LifeStory/Guiones/Saga_12_Graduacion.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: Cosme viene a tu graduación «por casualidad», la cinemática Grieta_Rota (se cuenta con el guion nuevo y conserva su mecánica), Cósimo aparece, la pelea con sus drones en el patio del instituto y el secuestro de Cosme (CosmeSecuestrado, que lee Saga_13).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Casualidad» |
| 2 | Cinematic |  | 2 · Cinematic «Grieta_Rota» |
| 3 |  |  | 3 · Scene «Cosimo» |
| 4 |  |  | 4 · Fight @ PatioInstituto |
| 5 |  |  | 5 · Scene «Secuestro» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Casualidad»): conversación «Casualidad» con 14 frases nuevas
- PASO 2 → paso 2 del juego (Cinematic «Grieta_Rota»): la escena «Grieta_Rota» se cuenta con el guion nuevo (misma escena, 6 planos, 9 frases, 24.4 s)
- PASO 3 → paso 3 del juego (Scene «Cosimo»): conversación «Cosimo» con 18 frases nuevas
- PASO 4 → paso 4 del juego (Fight): 8 frases al empezar el paso (escena ligera «Saga_12_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «Secuestro»): conversación «Secuestro» con 23 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion no trae planos para «Grieta_Rota»: se conservan los de la escena de antes
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5: «graduacion_completada = true» no la lee ninguna misión: no se crea
- PASO 5: «saga_acto_ii_completado = true» no la lee ninguna misión: no se crea
- PASO 5: «cosimo_se_llevo_cosme = true» no la lee ninguna misión: no se crea
- PASO 5: «cosme_desaparecido = true» no la lee ninguna misión: no se crea
- PASO 5: «grieta_reabierta = true» no la lee ninguna misión: no se crea
- PASO 5: «defendiste_amigos_graduacion = true» no la lee ninguna misión: no se crea
- PASO 5: «bata_cosme_obtenida = true» no la lee ninguna misión: no se crea
- PASO 5: «omar_exige_la_verdad = true» no la lee ninguna misión: no se crea
- PASO 5: «cosimo_te_espera_en_universidad = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Habla con Cosme.
- PASO 2 · OBJETIVO: Asiste a la ceremonia de graduación.
- PASO 3 · OBJETIVO: Protege la graduación.
- PASO 4 · OBJETIVO: Protege a tus amigos.
- PASO 5 · FLAGS: 
- PASO 5 · DIRECCIÓN DE ACTUACIÓN: COSME / Durante el comienzo: / * Nervioso. / * Intentando fingir normalidad. / * Feliz por la graduación. / Cuando aparece la grieta: / * Miedo real. / * Protección. / * Determinación. / Durante el secuestro: / * No debe parecer derrotado. / * Debe intentar proteger al protagonista hasta el último segundo. / La frase: / Sara: No sueltes el Ancla
- PASO 5 · OBJETIVO:: Habla con Pip.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
