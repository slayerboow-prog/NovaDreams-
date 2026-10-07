# Informe de la reescritura · Adu01_PrimerContrato

Guion: `docs/historia/reescritura/Adu01_PrimerContrato.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Adu01_PrimerContrato`.
Datos: `src/shared/LifeStory/Guiones/Adu01_PrimerContrato.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: quedarte una casa libre (el sistema de casas de siempre: cartel «Se vende»), el primer día (en tu sitio de prácticas o con Lola, Paco o Ernesto), las cinemáticas Adu01_PrimerDia, Adu01_Firma, Adu01_PrimerTurno y Adu01_Buzon, el contrato, el primer caso o el turno de encargado/a, las facturas, el presupuesto con Ignacio en el banco y la llamada de casa. El sueldo y las facturas van por la economía de siempre (sin cambiar cantidades). Elegir entre tres casas o una pantalla de presupuesto nueva serían sistemas nuevos: se queda la versión del juego (pendiente).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Event (HomeClaimed) |
| 3 |  |  | 3 · Reach @ $Carrera.LugarPracticas |
| 4 |  |  | 4 · Reach @ CafeteriaCentral |
| 5 |  |  | 5 · Reach @ Supermercado |
| 6 |  |  | 6 · Reach @ Correos |
| 7 | Cinematic |  | 7 · Cinematic «Adu01_PrimerDia» |
| 8 |  |  | 8 · Scene «Contrato» |
| 9 |  |  | 9 · Cinematic «Adu01_Firma» |
| 10 |  |  | 10 · Class @ $Carrera.LugarPracticas |
| 11 |  |  | 11 · Scene «PrimerCaso» |
| 15 | Cinematic |  | 15 · Cinematic «Adu01_PrimerTurno» |
| 16 |  |  | 16 · Transition |
| 17 |  |  | 17 · Cinematic «Adu01_Buzon» |
| 18 |  |  | 18 · Scene «Facturas» |
| 19 |  |  | 19 · Reach @ Banco |
| 20 |  |  | 20 · Scene «Presupuesto» |
| 21 |  |  | 21 · Scene «Llamada» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Event): 3 frases al empezar el paso (escena ligera «Adu01_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Reach): 1 frases al empezar el paso (escena ligera «Adu01_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Reach): 3 frases al empezar el paso (escena ligera «Adu01_G5_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 6 del juego (Reach): 3 frases al empezar el paso (escena ligera «Adu01_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (Cinematic «Adu01_PrimerDia»): la escena «Adu01_PrimerDia» se cuenta con el guion nuevo (misma escena, 8 planos, 42 frases, 117.5 s)
- PASO 8 → paso 8 del juego (Scene «Contrato»): conversación «Contrato» con 1 frases nuevas
- PASO 9 → paso 9 del juego (Cinematic «Adu01_Firma»): la escena «Adu01_Firma» se cuenta con el guion nuevo (misma escena, 1 planos, 5 frases, 17.5 s, música Intima)
- PASO 11: efectos del guion sumados a la conversación «PrimerCaso»: primer_caso = Consejo · primer_caso = Lanzarse
- PASO 11 → paso 11 del juego (Scene «PrimerCaso»): conversación «PrimerCaso» con 0 frases nuevas
- PASO 15 → paso 15 del juego (Cinematic «Adu01_PrimerTurno»): la escena «Adu01_PrimerTurno» se cuenta con el guion nuevo (misma escena, 1 planos, 12 frases, 34.9 s)
- PASO 17 → paso 17 del juego (Cinematic «Adu01_Buzon»): la escena «Adu01_Buzon» se cuenta con el guion nuevo (misma escena, 1 planos, 3 frases, 10.5 s, música Intima)
- PASO 18: efectos del guion sumados a la conversación «Facturas»: factura_pendiente = true
- PASO 18 → paso 18 del juego (Scene «Facturas»): conversación «Facturas» con 7 frases nuevas
- PASO 19 → paso 19 del juego (Reach): 1 frases al empezar el paso (escena ligera «Adu01_G19_Entra», la lanza el paso 18 al cumplirse; el jugador no pierde el control)
- PASO 20 → paso 20 del juego (Scene «Presupuesto»): conversación «Presupuesto» con 3 frases nuevas
- PASO 21: efectos del guion sumados a la conversación «Llamada»: primer_contrato_completado = true · primer_sueldo = true · adulto_joven_trabajando = true · facturas_pagadas = true · factura_pendiente = true · primer_presupuesto = true
- PASO 21 → paso 21 del juego (Scene «Llamada»): conversación «Llamada» con 13 frases nuevas

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3 → paso 3 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7: el guion no trae planos para «Adu01_PrimerDia»: se conservan los de la escena de antes
- PASO 8: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 9: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 9: el guion no trae planos para «Adu01_Firma»: se conservan los de la escena de antes
- PASO 10 → paso 10 del juego (Class): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 15: el guion no trae planos para «Adu01_PrimerTurno»: se conservan los de la escena de antes
- PASO 16: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 16 → paso 16 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 17: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 17: el guion no trae planos para «Adu01_Buzon»: se conservan los de la escena de antes
- PASO 18: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 18: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 20: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 20: «primer_presupuesto = Exitoso» no la lee ninguna misión: no se crea
- PASO 20: «primer_presupuesto = Ajustado» no la lee ninguna misión: no se crea
- PASO 21: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 21: «primer_contrato_completado = true» no la lee ninguna misión: no se crea
- PASO 21: «primer_sueldo = true» no la lee ninguna misión: no se crea
- PASO 21: «adulto_joven_trabajando = true» no la lee ninguna misión: no se crea
- PASO 21: «facturas_pagadas = true» no la lee ninguna misión: no se crea
- PASO 21: «primer_presupuesto = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 9 (línea 880) · Paco: «Encargado/a.» → «Encargad{o/a}.»
- PASO 9 (línea 892) · Ernesto: «Jefe/a de ruta.» → «Jef{e/a} de ruta.»
- PASO 15 (línea 1060) · Omar: «¡Encargado/a!» → «¡Encargad{o/a}!»
- PASO 17 (línea 1207) · Yo: «Nadie me avisó de que ser adulto/a venía con buzón.» → «Nadie me avisó de que ser adult{o/a} venía con buzón.»
- PASO 18 (línea 1234) · Yo: «Pero esta noche duermo tranquilo/a.» → «Pero esta noche duermo tranquil{o/a}.»

## Avisos

- PASO 7: la cinemática nueva dura 117 s (se puede saltar, pero es larga: el guion trae 8 planos)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: Encuentra tu primer hogar.
- PASO 4 · Objetivo:: Ve a hablar con Lola.
- PASO 21 · DIRECCIÓN AAA DE LA MISIÓN: La clave visual

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
