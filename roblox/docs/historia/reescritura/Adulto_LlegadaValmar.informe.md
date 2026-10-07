# Informe de la reescritura · Adulto_LlegadaValmar

Guion: `docs/historia/reescritura/Adulto_LlegadaValmar.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Adulto_LlegadaValmar`.
Datos: `src/shared/LifeStory/Guiones/Adulto_LlegadaValmar.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: llegar a la plaza, la cinemática Adulto_Bienvenida, quedarte una casa (el sistema de casas de siempre; el paso sigue con su condición TieneHogar) y comer algo (el menú de la cafetería de siempre). Las cinemáticas «antes del paso 1» y de cierre del guion van dentro de los pasos que ya existen (no se añaden pasos). Elegir entre tres casas filtradas sería un sistema nuevo: se queda la versión del juego (pendiente). actitud_llegada, tipo_hogar_inicial y primera_comida_valmar no se crean (nada las lee). A «¿Vienes de lejos?» solo sale la primera respuesta (en un paso de comer no hay elección). La ruta no menciona la infancia. Los recordatorios de Lola y Ernesto son las frases de este paso: salen una vez, no se repiten.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Reach @ PlazaCentro |
| 2 |  |  | 2 · Cinematic «Adulto_Bienvenida» |
| 3 |  |  | 3 · Event (HomeClaimed) |
| 4 |  |  | 4 · Event (Ate) |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Reach): 1 frases al cumplirlo (escena ligera «Adulto_Llegada_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Cinematic «Adulto_Bienvenida»): la escena «Adulto_Bienvenida» se cuenta con el guion nuevo (misma escena, 1 planos, 14 frases, 42.9 s)
- PASO 3 → paso 3 del juego (Event): 3 frases al empezar el paso (escena ligera «Adulto_Llegada_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Event): 19 frases al empezar el paso (escena ligera «Adulto_Llegada_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)

## Adaptado (y por qué)

- PASO 1: no hay paso de antes que pueda lanzar las 1 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1
- PASO 2 · opción C: decisión nueva «ActitudLlegada» (actitud_llegada = Reinicio)
- PASO 2: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 2: hay una ELECCION dentro de una cinemática (el motor de escenas no tiene preguntas): sus frases van seguidas, sin elegir
- PASO 2: el guion no trae planos para «Adulto_Bienvenida»: se conservan los de la escena de antes
- PASO 4: ELECCION en un paso jugable del juego (Event): no hay conversación donde preguntarla; sus respuestas se dicen como frases

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 281) · Ernesto: «Entonces bienvenido/a.» → «Entonces bienvenid{o/a}.»
- PASO 3 (línea 627) · Vecino: «¿Nuevo/a?» → «¿Nuev{o/a}?»

## Avisos

- PASO 1 (línea 93): «Inserto» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 3 (línea 546): «General» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 3 (línea 548): «Seguir» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 3 (línea 552): «Medio» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 4 (línea 1108): «Comprobar» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo:: Plaza Mayor
- PASO 3 · OPCIÓN A — Económica: Pequeña. / Barata. / Lejos del centro.
- PASO 3 · OPCIÓN B — Equilibrada: Precio medio. / Zona residencial. / Buena conexión.
- PASO 3 · OPCIÓN C — Premium inicial: Más cara. / Mejor ubicación. / Menos dinero disponible posteriormente.
- PASO 4 · MOMENTO DE BIOGRAFÍA: Cuando el jugador termina de comer:
- PASO 4 · Al terminar:: Desbloquea:
- PASO 4 · DIRECCIÓN DE ACTUACIÓN: Debe transmitir: / * energía; / * curiosidad; / * experiencia; / * humor; / * rapidez. / Nunca quedarse mirando al jugador sin hacer nada. / Debe transmitir: / * calidez; / * seguridad; / * experiencia; / * sentido comunitario. / Lola: Cuando habla, continúa realizando tareas.
- PASO 4 · DIRECCIÓN CINEMATOGRÁFICA: No utilizar: / * cámara volando sin propósito; / * texto explicativo durante minutos; / * NPCs congelados; / * zooms constantes; / * música épica para una llegada cotidiana. / Utilizar: / * planos generales para descubrir ciudad; / * primeros planos solo cuando una reacción importe; / * insertos para objetos; / * Dolly para momentos de transición; / * sonido ambiental; / * pausas; / * iluminación de hora del día.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
