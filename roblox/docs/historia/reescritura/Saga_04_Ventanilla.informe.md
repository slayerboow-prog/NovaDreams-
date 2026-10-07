# Informe de la reescritura · Saga_04_Ventanilla

Guion: `docs/historia/reescritura/Saga_04_Ventanilla.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_04_Ventanilla`.
Datos: `src/shared/LifeStory/Guiones/Saga_04_Ventanilla.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La estructura es la de siempre (5 conversaciones: la multa del agente Cronos, Correos, el banco, la comisaría y el garaje). El guion cuenta una sola ventanilla dimensional con un empleado: el empleado es la funcionaria del juego (la que «está en todas las ventanillas»), sus PASO 1-2 van a la ventanilla de Correos, y los PASO 3-6 (el problema, la ventanilla que se descontrola, llegan Cosme y Pip y se cierra) a la del banco. La multa de Cronos (paso 1), la comisaría de Inés (paso 4, con su decisión) y la vuelta al garaje con Cronos (paso 5: «alguien del otro lado tira de la Grieta hacia ti», la pista del Ancla que usa la saga) no están en el guion y se quedan como estaban. Pendiente para el autor: que el guion encaje con el agente Cronos y las tres ventanillas, o cambiar la misión (eso ya no es solo texto).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 2 · Talk «Ventanilla1» |
| 2 |  |  | 2 · Talk «Ventanilla1» |
| 3 |  |  | 3 · Talk «Ventanilla2» |
| 4 |  |  | 3 · Talk «Ventanilla2» |
| 5 |  |  | 3 · Talk «Ventanilla2» |
| 6 |  |  | 3 · Talk «Ventanilla2» |

## Errores

_Ninguno._


## Aplicado

- PASO 1+2 → paso 2 del juego (Talk «Ventanilla1»): conversación «Ventanilla1» con 23 frases nuevas (música Tension)
- PASO 3+4+5+6 → paso 3 del juego (Talk «Ventanilla2»): conversación «Ventanilla2» con 79 frases nuevas (música Tension)

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 1+2: «grieta_admitida = true» no la lee ninguna misión: no se crea
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3+4+5+6: «saga_04_ventanilla_completada = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «megaverso_contacto_directo = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «jugador_detectado_dimensionalmente = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «convergencia_jugador = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «ancla_inestable = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «cosimo_sabe_tornillo = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «ventanilla_megaverso_cerrada = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «cosme_revelo_que_cosisimo_busca_jugador = true» no la lee ninguna misión: no se crea
- PASO 3+4+5+6: «jugador_intenta_evitar_grieta = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 155) · Funcionaria: «Bienvenido/a al Consorcio MegaVerso.» → «Bienvenid{o/a} al Consorcio MegaVerso.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo:: Lugar: Calle cercana al barrio.
- PASO 2 · Objetivo:: El jugador puede acercarse.
- PASO 3 · Objetivo:: El empleado intenta cerrar la ventanilla.
- PASO 6 · Objetivo:: El jugador debe interactuar con tres puntos:
- PASO 6 · DIRECCIÓN MUSICAL: Usar únicamente: / * Comedia — ventanilla y empleado. / * Tension — anomalía, máquina, tornillo y revelación. / * Accion — llegada de Cosme y cierre de la ventanilla. / * Calma — exploración inicial.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
