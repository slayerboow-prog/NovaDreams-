# Informe de la reescritura · Ins03_QueQuieresSer

Guion: `docs/historia/reescritura/Ins03_QueQuieresSer.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins03_QueQuieresSer`.
Datos: `src/shared/LifeStory/Guiones/Ins03_QueQuieresSer.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la charla de Carmen (cinemática Ins03_Carmen), visitar al menos cuatro profesiones (hospital, laboratorio, comisaría, oficinas, taller, cafetería, estadio y cine) y la reflexión final. Los recuerdos breves de cada profesión salen con tu sueño de primaria (Choices.SuenoInfancia, de Cole03): «Niño/a» es el protagonista de pequeño. Lo de Leire va con ConocesALeire; el primer club y el torneo, con sus recuerdos (PrimerClub, PrimerTorneo). El juego no guarda qué quiere ser Bruno: sus frases de la comisaría no salen.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ AulaInstituto |
| 3 | Cinematic |  | — |
| 4 |  |  | 4 · Group |
| 4.1 |  |  | 4.1 · Talk «Hospital» |
| 4.2 |  |  | 4.2 · Talk «Laboratorio» |
| 4.3 |  |  | 4.3 · Talk «Comisaria» |
| 4.4 |  |  | 4.4 · Talk «Empresa» |
| 4.5 |  |  | 4.5 · Talk «Taller» |
| 4.6 |  |  | 4.6 · Talk «Restaurante» |
| 4.7 |  |  | 4.7 · Talk «Estadio» |
| 4.8 |  |  | 4.8 · Talk «Estudio» |
| 5 |  |  | 5 · Reach @ AulaInstituto |
| 6 | Scene |  | 6 · Scene «Reflexion» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Reach): 1 frases al empezar el paso (escena ligera «Ins03_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 4.1 → paso 4.1 del juego (Talk «Hospital»): conversación «Hospital» con 8 frases nuevas
- PASO 4.2: efectos del guion sumados a la conversación «Laboratorio»: curiosidad +1 · valentia +1 · Interes_Ingenieria · continúa.
- PASO 4.2 → paso 4.2 del juego (Talk «Laboratorio»): conversación «Laboratorio» con 6 frases nuevas
- PASO 4.3: efectos del guion sumados a la conversación «Comisaria»: responsabilidad +1 · curiosidad +1 · Interes_Derecho · continúa.
- PASO 4.3 → paso 4.3 del juego (Talk «Comisaria»): conversación «Comisaria» con 4 frases nuevas
- PASO 4.4: efectos del guion sumados a la conversación «Empresa»: creatividad +1 · curiosidad +1 · Interes_Economia · continúa.
- PASO 4.4 → paso 4.4 del juego (Talk «Empresa»): conversación «Empresa» con 2 frases nuevas
- PASO 4.5: efectos del guion sumados a la conversación «Taller»: curiosidad +1 · humor +1 · Interes_Oficio · continúa.
- PASO 4.5 → paso 4.5 del juego (Talk «Taller»): conversación «Taller» con 3 frases nuevas
- PASO 4.6: efectos del guion sumados a la conversación «Restaurante»: responsabilidad +1 · Omar +3 · empatia +1 · Interes_Cocina · continúa.
- PASO 4.6 → paso 4.6 del juego (Talk «Restaurante»): conversación «Restaurante» con 2 frases nuevas
- PASO 4.7: efectos del guion sumados a la conversación «Estadio»: responsabilidad +1 · empatia +1 · Interes_Deporte · continúa.
- PASO 4.7 → paso 4.7 del juego (Talk «Estadio»): conversación «Estadio» con 2 frases nuevas
- PASO 4.8: efectos del guion sumados a la conversación «Estudio»: creatividad +1 · creatividad +1 · Interes_Audiovisual · continúa.
- PASO 4.8 → paso 4.8 del juego (Talk «Estudio»): conversación «Estudio» con 6 frases nuevas
- PASO 6 → paso 6 del juego (Scene «Reflexion»): conversación «Reflexion» con 31 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 3 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4 → paso 4 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: 1 PLANO de un paso jugable (Group) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 4.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.1: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.1: sin equivalente: «Interes_Medicina»
- PASO 4.1: sin equivalente: «No se registra interés.»
- PASO 4.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.2: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.2: sin equivalente: «Interes_Ingenieria»
- PASO 4.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.3: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.3: sin equivalente: «Interes_Derecho»
- PASO 4.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.4: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.4: sin equivalente: «Interes_Economia»
- PASO 4.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.5: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.5: sin equivalente: «Interes_Oficio»
- PASO 4.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.6: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.6: sin equivalente: «Interes_Cocina»
- PASO 4.7: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.7: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.7: sin equivalente: «Interes_Deporte»
- PASO 4.8: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.8: la conversación del juego tenía 2 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 4.8: sin equivalente: «Interes_Audiovisual»
- PASO 5 → paso 5 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4.1 (línea 460) · Nuria: «Antes de ayudar a alguien, tienes que conseguir que se sienta seguro.» → «Antes de ayudar a alguien, tienes que conseguir que se sienta segur{o/a}.»
- PASO 4.2 (línea 553) · Sofia: «Por eso tú haces robots y él/ella hace puentes.» → «Por eso tú haces robots y {él/ella} hace puentes.»

## Avisos

- PASO 6 (línea 1493): «Laboratorio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1494): «Comisaría» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1495): «Empresa» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1496): «Taller» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1497): «Cocina» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1498): «Estadio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6 (línea 1499): «Cine» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Mostrar que el tiempo ha pasado y que el protagonista está creciendo.
- PASO 2 · DIRECCIÓN: Al llegar, la clase debe estar viva.
- PASO 6 · Al terminar:: Ins03_QueQuieresSer = COMPLETADA
- PASO 6 · DIRECCIÓN AAA OBLIGATORIA: 

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
