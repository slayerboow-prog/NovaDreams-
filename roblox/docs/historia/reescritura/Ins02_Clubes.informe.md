# Informe de la reescritura · Ins02_Clubes

Guion: `docs/historia/reescritura/Ins02_Clubes.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins02_Clubes`.
Datos: `src/shared/LifeStory/Guiones/Ins02_Clubes.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la feria (al menos tres puestos), el club que eliges y su rama (baloncesto, teatro, robótica con el robot que se escapa, periódico con los murales de Vega, fotografía), el dilema y el evento del club o el cumpleaños de Nico. Lo que Rubén dice si le perdonaste en primaria sale con Ruben_Perdonado. «Si lo hace bien» en la audición es ganar el minijuego del paso 11.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ PatioInstituto |
| 3 | Scene |  | 3 · Scene «Feria» |
| 4 |  |  | 4 · Group |
| 4.1 |  |  | 4.1 · Use (PuestoBaloncesto) |
| 4.2 |  |  | 4.2 · Use (PuestoTeatro) |
| 4.3 |  |  | 4.3 · Use (PuestoRobotica) |
| 4.4 |  |  | 4.4 · Use (PuestoPeriodico) |
| 4.5 |  |  | 4.5 · Use (PuestoFotografia) |
| 5 |  |  | 5 · Choice |
| 6 |  |  | 6 · Reach @ PistaInstituto |
| 7 | Scene |  | 7 · Scene «Prueba_Baloncesto» |
| 8 |  |  | 8 · MiniGame |
| 9 |  |  | 9 · Reach @ AulaInstituto |
| 10 | Scene |  | 10 · Scene «Audicion» |
| 11 |  |  | 11 · MiniGame |
| 12 |  |  | 12 · Reach @ AulaInstituto |
| 13 | Scene |  | 13 · Scene «Robotica» |
| 14 |  |  | 14 · MiniGame |
| 15 |  |  | 15 · Use (Robot1) |
| 16 |  |  | 16 · Use (Robot2) |
| 17 |  |  | 17 · Use (Robot3) |
| 18 | Scene |  | 18 · Scene «Periodico» |
| 19 |  |  | 19 · Group |
| 19.1 |  |  | 19.1 · Use (MuralNocturno) |
| 19.2 |  |  | 19.2 · Talk «Pregunta_Veterano» |
| 19.3 |  |  | 19.3 · Talk «Pregunta_Delegada» |
| 20 |  |  | 20 · Talk «Vega_Murales» |
| 21 | Scene |  | 21 · Scene «Fotografia» |
| 22 |  |  | 22 · Group |
| 22.1 |  |  | 22.1 · Use (FotoUni) |
| 22.2 |  |  | 22.2 · Use (FotoBiblio) |
| 22.3 |  |  | 22.3 · Use (FotoEstadio) |
| 23 | Scene |  | 23 · Scene «Dilema» |
| 24 |  |  | 24 · Reach @ PatioInstituto |
| 25 | Scene |  | 25 · Scene «EventoClub» |
| 26 |  |  | 26 · Reach @ Parque |
| 27 |  |  | 27 · Reach @ Parque |
| 28 | Scene |  | 28 · Scene «Cumple» |
| 29 | Scene |  | 29 · Scene «TrasElClub» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 2 frases al cumplirlo (escena ligera «Ins02_G1_Fin», sin quitar el control)
- PASO 3 → paso 3 del juego (Scene «Feria»): conversación «Feria» con 9 frases nuevas
- PASO 4.1 → paso 4.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Puesto_Baloncesto» (7 frases)
- PASO 4.2 → paso 4.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Puesto_Teatro» (6 frases)
- PASO 4.3 → paso 4.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Puesto_Robotica» (8 frases)
- PASO 4.4 → paso 4.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Puesto_Periodico» (7 frases)
- PASO 4.5 → paso 4.5 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Puesto_Fotografia» (5 frases)
- PASO 5 → paso 5 del juego (Choice): 20 frases al empezar el paso (escena ligera «Ins02_G5_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 6 del juego (Reach): 1 frases al empezar el paso (escena ligera «Ins02_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (Scene «Prueba_Baloncesto»): conversación «Prueba_Baloncesto» con 9 frases nuevas
- PASO 8 → paso 8 del juego (MiniGame): 3 frases al empezar el paso (escena ligera «Ins02_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Scene «Audicion»): conversación «Audicion» con 6 frases nuevas
- PASO 11 → paso 11 del juego (MiniGame): 4 frases al empezar el paso (escena ligera «Ins02_G11_Entra», la lanza el paso 10 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Scene «Robotica»): conversación «Robotica» con 7 frases nuevas
- PASO 15 → paso 15 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Robot1» (5 frases)
- PASO 16 → paso 16 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Robot2» (2 frases)
- PASO 17 → paso 17 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Robot3» (4 frases)
- PASO 18 → paso 18 del juego (Scene «Periodico»): conversación «Periodico» con 8 frases nuevas
- PASO 19.1 → paso 19.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mural» (2 frases)
- PASO 19.2 → paso 19.2 del juego (Talk «Pregunta_Veterano»): conversación «Pregunta_Veterano» con 2 frases nuevas
- PASO 19.3 → paso 19.3 del juego (Talk «Pregunta_Delegada»): conversación «Pregunta_Delegada» con 4 frases nuevas
- PASO 20 → paso 20 del juego (Talk «Vega_Murales»): conversación «Vega_Murales» con 20 frases nuevas
- PASO 21 → paso 21 del juego (Scene «Fotografia»): conversación «Fotografia» con 4 frases nuevas
- PASO 22.1 → paso 22.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Uni» (2 frases)
- PASO 22.2 → paso 22.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Biblio» (1 frases)
- PASO 22.3 → paso 22.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Estadio» (4 frases)
- PASO 23 → paso 23 del juego (Scene «Dilema»): conversación «Dilema» con 25 frases nuevas
- PASO 25 → paso 25 del juego (Scene «EventoClub»): conversación «EventoClub» con 12 frases nuevas
- PASO 28 → paso 28 del juego (Scene «Cumple»): conversación «Cumple» con 17 frases nuevas
- PASO 29 → paso 29 del juego (Scene «TrasElClub»): conversación «TrasElClub» con 5 frases nuevas

## Adaptado (y por qué)

- PASO 2 → paso 2 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4 → paso 4 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 9 → paso 9 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 12 → paso 12 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14 → paso 14 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 19 → paso 19 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 19.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 19.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 20: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 20: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 22 → paso 22 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 24 → paso 24 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 26 → paso 26 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 27 → paso 27 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 29 (línea 2138) · Narrador: «Un pequeño papel: «Para {nombre}.»» → «Un pequeñ{o/a} papel: «Para {nombre}.»»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 8 · Objetivo:: 4 aciertos.
- PASO 20 · OPCIÓN A · «Publicarlo sin su nombre»: 
- PASO 20 · OPCIÓN B · «Pedir permiso al director»: 
- PASO 20 · OPCIÓN C · «Publicar su nombre»: 
- PASO 23 · OPCIÓN A · «El club»: 
- PASO 23 · OPCIÓN B · «El cumpleaños de Nico»: 
- PASO 23 · OPCIÓN C · «Intentar las dos»: 
- PASO 29 · DIRECCIÓN AAA: 

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
