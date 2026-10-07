# Informe de la reescritura · Adu02_Atardecer

Guion: `docs/historia/reescritura/Adu02_Atardecer.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Adu02_Atardecer`.
Datos: `src/shared/LifeStory/Guiones/Adu02_Atardecer.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la llamada, el hospital (Adu02_Hospital), sentarte con Abu, la decisión ViajeAbu (el carnet en la autoescuela, que ya existe, o el autobús), recoger a Abu, la playa (Adu02_Orilla), la concha (el objeto de siempre), la promesa (PromesaAbu) y el atardecer. Abu camina despacio con la mecánica de acompañar de siempre.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Transition |
| 2 |  |  | 2 · Scene «Llamada» |
| 3 |  |  | 3 · Reach @ Hospital |
| 4 |  |  | 4 · Cinematic «Adu02_Hospital» |
| 5 |  |  | 5 · Talk «Hospital» |
| 6 |  |  | 6 · Choice |
| 7 |  |  | 7 · Event @ Autoescuela |
| 8 |  |  | 8 · Scene «Coche» |
| 9 |  |  | 9 · Scene «Autobus» |
| 10 |  |  | 10 · Reach @ ParadaBus |
| 11 |  |  | 11 · Event @ ParadaBus |
| 12 |  |  | 12 · Reach @ Playa |
| 13 |  |  | 13 · Cinematic «Adu02_Orilla» |
| 14 |  |  | 14 · Scene «Mar» |
| 15 |  |  | 15 · Use (Concha) |
| 16 |  |  | 16 · Scene «Promesa» |
| 17 |  |  | 17 · Cinematic «Adu02_Atardecer» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Scene «Llamada»): conversación «Llamada» con 7 frases nuevas
- PASO 4 → paso 4 del juego (Cinematic «Adu02_Hospital»): la escena «Adu02_Hospital» se cuenta con el guion nuevo (misma escena, 1 planos, 16 frases, 43.2 s)
- PASO 5 → paso 5 del juego (Talk «Hospital»): conversación «Hospital» con 13 frases nuevas
- PASO 8 → paso 8 del juego (Scene «Coche»): conversación «Coche» con 1 frases nuevas
- PASO 9 → paso 9 del juego (Scene «Autobus»): conversación «Autobus» con 7 frases nuevas
- PASO 11 → paso 11 del juego (Event): 3 frases al empezar el paso (escena ligera «Adu02_G11_Entra», la lanza el paso 10 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Cinematic «Adu02_Orilla»): la escena «Adu02_Orilla» se cuenta con el guion nuevo (misma escena, 1 planos, 4 frases, 12.7 s)
- PASO 14 → paso 14 del juego (Scene «Mar»): conversación «Mar» con 9 frases nuevas
- PASO 15 → paso 15 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Concha» (6 frases)
- PASO 16: efectos del guion sumados a la conversación «Promesa»: promesa_abu = Volver · promesa_abu = CosasBonitas · promesa_abu = Familia
- PASO 16 → paso 16 del juego (Scene «Promesa»): conversación «Promesa» con 12 frases nuevas
- PASO 17 → paso 17 del juego (Cinematic «Adu02_Atardecer»): cinemática nueva «Adu02_G17» (1 planos, 5 frases, 18.0 s) en lugar de «Adu02_Atardecer»

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 3 → paso 3 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 4: el guion no trae planos para «Adu02_Hospital»: se conservan los de la escena de antes
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 6: «OPCIÓN A — COCHE» — la opción Coche del juego no tiene conversación propia: sus frases no se aplican
- PASO 6: «OPCIÓN B — AUTOBÚS» — la opción Bus del juego no tiene conversación propia: sus frases no se aplican
- PASO 6 → paso 6 del juego (Choice): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7 → paso 7 del juego (Event): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 9: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 10 → paso 10 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 12 → paso 12 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 13: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 13: el guion no trae planos para «Adu02_Orilla»: se conservan los de la escena de antes
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: «recuerdo_abu_playa = true» no la lee ninguna misión: no se crea
- PASO 16: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 16: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 17: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 17: el guion no trae planos para la cinemática: un plano general lento del sitio

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 259) · Nuria: «Asustado. Pero entero.» → «Asustad{o/a}. Pero entero.»

## Avisos

- PASO 1 (línea 69): «General» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 1 (línea 71): «Inserto» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 1 (línea 73): «PrimerPlano» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 1 (línea 77): «Medio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 2 (línea 178): «Reaccion» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 3 (línea 218): «Destino» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 8 (línea 581): «Dolly» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 11 (línea 721): «DosPlanos» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 11 (línea 723): «Lateral» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 13 (línea 805): «Acción» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 6 · OPCIÓN A — COCHE: Texto: / Conseguir el permiso de conducir y llevar a Abu en coche. / Estado: / Atributo: / valentia +1 / La elección representa: / “Ahora me toca cuidar de ti.”
- PASO 6 · OPCIÓN B — AUTOBÚS: Texto: / Ir en autobús, como hacía Abu cuando era joven. / Estado: / Atributo: / empatia +1 / La elección representa: / “Quiero conocer una parte de tu vida.”
- PASO 15 · Objetivo:: Busca una concha blanca.
- PASO 17 · SISTEMA DE MEMORIA: Al finalizar:
- PASO 17 · CONSECUENCIAS FUTURAS: La misión debe dejar información persistente.
- PASO 17 · DIRECCIÓN DE ACTUACIÓN: Esta misión depende más de la actuación que de la cantidad de diálogo.
- PASO 17 · DIRECCIÓN CINEMATOGRÁFICA: Evitar:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
