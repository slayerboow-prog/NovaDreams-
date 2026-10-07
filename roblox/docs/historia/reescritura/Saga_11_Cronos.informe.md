# Informe de la reescritura · Saga_11_Cronos

Guion: `docs/historia/reescritura/Saga_11_Cronos.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_11_Cronos`.
Datos: `src/shared/LifeStory/Guiones/Saga_11_Cronos.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el agente Cronos y su formulario, la funcionaria de las ventanillas, los formularios del Consorcio, la persecución de la agente gris (Chase) y la escena final en la que Cronos cambia de bando (CronosAliado, que leen las misiones de los aliados). Lo que Cronos recuerda de las tres ventanillas sale con el recuerdo VentanillaAduana (Saga_04). La agente que habla al final es la agente gris 2 del reparto; si la recuerdas arrepentida o no, lo guarda la marca que ya pone la escena.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Cronos» |
| 2 |  |  | 2 · Talk «Ventanilla» |
| 3 |  |  | 3 · Use (Formularios) |
| 4 |  |  | 4 · Chase |
| 5 |  |  | 5 · Scene «Pillada» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Cronos»): conversación «Cronos» con 18 frases nuevas
- PASO 2 → paso 2 del juego (Talk «Ventanilla»): conversación «Ventanilla» con 15 frases nuevas
- PASO 3 → paso 3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Formularios» (3 frases)
- PASO 4 → paso 4 del juego (Chase): 5 frases al empezar el paso (escena ligera «Saga_11_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5: efectos del guion sumados a la conversación «Pillada»: cronos_aliado = true · gris_arrepentida = true · cronos_aliado = true · cronos_aliado = true · descubrio_permisos_falsos = true · descubrio_sello_falso = true · consorcio_intenta_legalizar_fusion = true · reloj_cronos_obtenido = true · gris_arrepentida = true · cronos_confia_responsabilidad = true
- PASO 5 → paso 5 del juego (Scene «Pillada»): conversación «Pillada» con 25 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 5: «descubrio_permisos_falsos = true» no la lee ninguna misión: no se crea
- PASO 5: «descubrio_sello_falso = true» no la lee ninguna misión: no se crea
- PASO 5: «consorcio_intenta_legalizar_fusion = true» no la lee ninguna misión: no se crea
- PASO 5: «reloj_cronos_obtenido = true» no la lee ninguna misión: no se crea
- PASO 5: «cronos_confia_responsabilidad = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 105) · CazadorTiempo: «Bueno… ya no tan pequeño.» → «Bueno… ya no tan pequeñ{o/a}.»

## Avisos

- PASO 5 (línea 1092): «Tiene» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Habla con el extraño hombre del traje.
- PASO 2 · OBJETIVO: Habla con la funcionaria de la ventanilla.
- PASO 3 · OBJETIVO: Revisa los formularios del Consorcio.
- PASO 3 · FLAG: 
- PASO 4 · OBJETIVO: Atrapa al agente de MegaVerso.
- PASO 5 · OPCIÓN A — DARLE UNA SEGUNDA OPORTUNIDAD: 
- PASO 5 · OPCIÓN B — CUMPLIR LAS NORMAS: 
- PASO 5 · DIRECCIÓN CINEMATOGRÁFICA: 
- PASO 5 · Al terminar:: 

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
