# Informe de la reescritura · Pan2_LaNoche

Guion: `docs/historia/reescritura/Pan2_LaNoche.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Pan2_LaNoche`.
Datos: `src/shared/LifeStory/Guiones/Pan2_LaNoche.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el plan de Rayo en el parque y la decisión Plan (ir, frenarle o no ir), la noche del súper de Paco con la alarma (Pan2_Alarma), la huida al parque o la comisaría, el servicio a la comunidad en el Punto Limpio, los mensajes y el lunes. Lo que depende de tu relación con Rayo («Rayo >= 5») va con la relación de verdad (Conditions: Rel).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ Parque |
| 3 |  |  | 6 · Use (PuertaAlmacen) |
| 3 |  |  | 6 · Use (PuertaAlmacen) |
| 4 | Transition |  | 7 · Cinematic «Pan2_Alarma» |
| 5 |  |  | 8 · Reach @ Parque |
| 6 |  |  | 11 · Event @ PuntoLimpio |
| 7 | Cinematic |  | 12 · Scene «Servicio» |
| 8 |  |  | 13 · Transition |
| 9 | Scene |  | 14 · Scene «Mensajes» |
| 10 | Scene |  | 15 · Scene «Lunes» |
| 11 |  |  | 15 · Scene «Lunes» |
| 12 | Scene |  | 15 · Scene «Lunes» |
| 13 | Transition |  | 15 · Scene «Lunes» |
| 14 |  |  | 15 · Scene «Lunes» |
| 15 | Scene |  | 15 · Scene «Lunes» |

## Errores

_Ninguno._


## Aplicado

- PASO 3+3 → paso 6 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Almacen» (18 frases)
- PASO 5 → paso 8 del juego (Reach): 1 frases al empezar el paso (escena ligera «Pan2_G5_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 11 del juego (Event): 3 frases al empezar el paso (escena ligera «Pan2_G6_Entra», la lanza el paso 10 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 12 del juego (Scene «Servicio»): conversación «Servicio» con 3 frases nuevas (música Tension)
- PASO 9 → paso 14 del juego (Scene «Mensajes»): conversación «Mensajes» con 2 frases nuevas
- PASO 10+11+12+13+14+15 → paso 15 del juego (Scene «Lunes»): conversación «Lunes» con 41 frases nuevas

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2 → paso 2 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3+3: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 6: ELECCION en un paso jugable del juego (Event): no hay conversación donde preguntarla; sus respuestas se dicen como frases
- PASO 7: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 8: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 8 → paso 13 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 13: el guion lo escribe como [Transition] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 10+11+12+13+14+15: «Flags» del guion no se pone a toda la conversación «Lunes» (es de una rama o una nota; lo pone la mecánica)

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 14 (línea 1253): «Simplemente» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 15 (línea 1766): «Trata de descubrir» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · DIRECCIÓN: No deben estar esperando quietos.
- PASO 8 · Objetivo:: Llega al parque antes de que llegue la policía.
- PASO 11 · Objetivo:: Completa 3 turnos.
- PASO 15 · DIRECCIÓN DE RAYO: Esta misión debe demostrar algo importante:
- PASO 15 · DIRECCIÓN DE NEREA: Nerea debe convertirse progresivamente en uno de los personajes emocionalmente más importantes de esta etapa.
- PASO 15 · DIRECCIÓN DE PACO: Paco no debe ser un NPC genérico.
- PASO 15 · DIRECCIÓN DE LA FAMILIA: La familia debe reaccionar de forma proporcional.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
