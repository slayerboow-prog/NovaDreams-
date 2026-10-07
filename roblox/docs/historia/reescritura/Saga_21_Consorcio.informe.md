# Informe de la reescritura · Saga_21_Consorcio

Guion: `docs/historia/reescritura/Saga_21_Consorcio.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_21_Consorcio`.
Datos: `src/shared/LifeStory/Guiones/Saga_21_Consorcio.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el asalto a la oficina de MegaVerso (la de Saga_08; no hay sótano ni sala de servidores nueva: el servidor es el objeto de siempre), apartar a la seguridad sin violencia, enchufar el pendrive con forma de pez y la quiebra con el agente Glub del Banco Galáctico (ConsorcioCaido y el recuerdo CaidaConsorcio). Las variantes van con las marcas reales: GrisArrepentida (Saga_11), DeudaGalactica, SabeFusion (Saga_08) y el recuerdo EquipoRescate. Si te detectan, la pelea ya te devuelve al punto seguro; lo que dice Candela en ese momento no tiene cuándo salir (pendiente). Las pantallas apagadas y las noticias por la ciudad serían un sistema de frases de ambiente nuevo (pendiente); cosimo_sin_financiacion no se crea (nada la lee).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 2 · Use (Servidor) |
| 1 |  |  | 2 · Use (Servidor) |
| 2 |  |  | 3 · Scene «Quiebra» |
| 3 | Scene |  | 3 · Scene «Quiebra» |

## Errores

_Ninguno._


## Aplicado

- PASO 1+1 → paso 2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Servidor» (18 frases)
- PASO 2+3: efectos del guion sumados a la conversación «Quiebra»: saga_21_completada = true · consorcio_caido = true · megaverso_intervenido = true · cuentas_megaverso_congeladas = true · financiacion_fusion_bloqueada = true · cosimo_sin_financiacion = true · cosimo_presionado = true · cosimo_ejecuta_fusion_solo = true
- PASO 2+3 → paso 3 del juego (Scene «Quiebra»): conversación «Quiebra» con 48 frases nuevas

## Adaptado (y por qué)

- PASO 2: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 2+3: «saga_21_completada = true» no la lee ninguna misión: no se crea
- PASO 2+3: «megaverso_intervenido = true» no la lee ninguna misión: no se crea
- PASO 2+3: «cuentas_megaverso_congeladas = true» no la lee ninguna misión: no se crea
- PASO 2+3: «financiacion_fusion_bloqueada = true» no la lee ninguna misión: no se crea
- PASO 2+3: «cosimo_sin_financiacion = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 2+3: «cosimo_presionado = true» no la lee ninguna misión: no se crea
- PASO 2+3: «cosimo_ejecuta_fusion_solo = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Cuando el jugador llega a la zona restringida:
- PASO 1 · FLAG: Esto permite una ruta más sencilla.
- PASO 3 · DIRECCIÓN DE ACTUACIÓN: Debe sentirse como el cerebro de la operación. / * analiza; / * observa; / * anticipa; / * no celebra demasiado; / * entiende inmediatamente la gravedad. / Iván / Candela: Es el contraste emocional.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
