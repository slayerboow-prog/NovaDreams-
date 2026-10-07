# Informe de la reescritura · Saga_18_Precio

Guion: `docs/historia/reescritura/Saga_18_Precio.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_18_Precio`.
Datos: `src/shared/LifeStory/Guiones/Saga_18_Precio.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el anuncio de Cósimo (la Gran Fusión) y la conversación con Cosme, que no recuerda nada y acaba recordando tu nombre (el recuerdo TuNombre y la foto sin memoria). Encaja con Saga_17: Cosme pierde la memoria al cruzar la Grieta de vuelta.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Scene |  | 1 · Scene «Anuncio» |
| 2 |  |  | 2 · Talk «Nombre» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Scene «Anuncio»): conversación «Anuncio» con 21 frases nuevas
- PASO 2 → paso 2 del juego (Talk «Nombre»): conversación «Nombre» con 22 frases nuevas

## Adaptado (y por qué)

- PASO 2 · opción A: sin equivalente: «humor += 1»
- PASO 2 · opción A: marca nueva «RecuerdoMicroondasCompartido» (recuerdo_microondas_compartido = true)
- PASO 2 · opción B: sin equivalente: «empatia += 2»
- PASO 2 · opción B: marca nueva «CosmeRecuerdaNombre» (cosme_recuerda_nombre = true)
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: «saga_18_completada = true» no la lee ninguna misión: no se crea
- PASO 2: «saga_acto_iii_completado = true» no la lee ninguna misión: no se crea
- PASO 2: «gran_fusion_anunciada = true» no la lee ninguna misión: no se crea
- PASO 2: «gran_fusion_monte_silencio = true» no la lee ninguna misión: no se crea
- PASO 2: «cosme_vive_en_valmar = true» no la lee ninguna misión: no se crea
- PASO 2: «cosimo_esperara_al_ancla_adulta = true» no la lee ninguna misión: no se crea
- PASO 2: «megaverso_entradas_disponibles = true» no la lee ninguna misión: no se crea
- PASO 2: «acto_iv_desbloqueado = true» no la lee ninguna misión: no se crea
- PASO 2: «recuerdo_microondas_compartido = true» no la lee ninguna misión: no se crea
- PASO 2: «cosme_recuerda_nombre = true» no la lee ninguna misión: no se crea
- PASO 2: «Flags» del guion no se pone a toda la conversación «Nombre» (es de una rama o una nota; lo pone la mecánica)

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 546) · Cosme: «El hueco se hace más pequeño.» → «El hueco se hace más pequeñ{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Habla con Pip.
- PASO 2 · OBJETIVO: Siéntate con Cosme.
- PASO 2 · SISTEMA DE MEMORIA DE COSME: A partir de este punto, Cosme debe recuperar recuerdos progresivamente.
- PASO 2 · DIRECCIÓN CINEMATOGRÁFICA DEL FINAL: No terminar con una explosión.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
