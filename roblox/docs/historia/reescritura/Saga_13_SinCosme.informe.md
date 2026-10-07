# Informe de la reescritura · Saga_13_SinCosme

Guion: `docs/historia/reescritura/Saga_13_SinCosme.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_13_SinCosme`.
Datos: `src/shared/LifeStory/Guiones/Saga_13_SinCosme.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: Pip en el garaje, el cuaderno y el mando que dejó Cosme, el equipo de rescate con Candela en la residencia (CompisSabenGrieta, CuadernoCosme) y el plan. La caja de Cosme es el cuaderno (un objeto que ya existe) y su contenido sale al coger el mando; la primera costura y la costura van en la escena del plan. La conversación con Candela y el equipo (paso 3) no está en el guion y se queda como estaba.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Pip» |
| 2 |  |  | 2.1 · Use (Cuaderno) |
| 3 |  |  | 2.2 · Use (Mando) |
| 4 |  |  | 4 · Scene «Plan» |
| 5 |  |  | 4 · Scene «Plan» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Pip»): conversación «Pip» con 2 frases nuevas
- PASO 2 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Cuaderno» (3 frases)
- PASO 3 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mando» (4 frases)
- PASO 4+5 → paso 4 del juego (Scene «Plan»): conversación «Plan» con 4 frases nuevas
- Conversación «Pip»: se conservan al final 3 frases del juego que dependen de lo vivido

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4+5: «saga_13_completada = true» no la lee ninguna misión: no se crea
- PASO 4+5: «caja_cosme_abierta = true» no la lee ninguna misión: no se crea
- PASO 4+5: «carta_cosme_leida = true» no la lee ninguna misión: no se crea
- PASO 4+5: «aguja_cosme_obtenida = true» no la lee ninguna misión: no se crea
- PASO 4+5: «primera_costura_encontrada = true» no la lee ninguna misión: no se crea
- PASO 4+5: «investigo_casa_origen = true» no la lee ninguna misión: no se crea
- PASO 4+5: «foto_cosme_cosimo_encontrada = true» no la lee ninguna misión: no se crea
- PASO 4+5: «pip_leyo_carta = true» no la lee ninguna misión: no se crea
- PASO 4+5: «jugador_leyo_carta = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Entra en el garaje de Cosme.
- PASO 2 · OBJETIVO: Busca la caja que dejó Cosme.
- PASO 3 · OBJETIVO: Descubre qué dejó Cosme.
- PASO 4 · OBJETIVO: Investiga el lugar donde comenzó todo.
- PASO 5 · OBJETIVO: Encuentra la costura oculta.
- PASO 5 · FLAGS: Opcional:
- PASO 5 · DIRECCIÓN CINEMATOGRÁFICA: Esta misión debe tener un ritmo deliberadamente diferente.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
