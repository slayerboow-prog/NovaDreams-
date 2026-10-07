# Informe de la reescritura · Adu03_Reencuentro

Guion: `docs/historia/reescritura/Adu03_Reencuentro.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Adu03_Reencuentro`.
Datos: `src/shared/LifeStory/Guiones/Adu03_Reencuentro.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el notición de Omar en la cafetería, invitar al grupo (al menos tres; Leire, Hugo y Mateo solo si están en tu vida), Lucía (directora del colegio, como ya era en el juego), ayudar en la cocina (el minijuego de siempre: fallar no bloquea), la inauguración, la foto (Adu03_Foto), el banco del parque (Adu03_Banco) y el montaje de cambio de etapa, que no se cambia.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ CafeteriaCentral |
| 3 |  |  | 3 · Scene «Noticia» |
| 4 |  |  | 4 · Group |
| 4.1 |  |  | 4.1 · Talk «Nico» |
| 4.2 |  |  | 4.2 · Talk «Sara» |
| 4.3 |  |  | 4.3 · Talk «Bruno» |
| 4.4 |  |  | 4.4 · Talk «Leire» |
| 4.5 |  |  | 4.5 · Talk «Hugo» |
| 4.6 |  |  | 4.6 · Talk «Mateo» |
| 5 |  |  | 5 · Reach @ EntradaColegio |
| 6 |  |  | 6 · Talk «Lucia» |
| 7 |  |  | 7 · Reach @ CafeteriaCentral |
| 8 |  |  | 8 · MiniGame |
| 9 |  |  | 9 · Scene «Inauguracion» |
| 10 |  |  | 10 · Cinematic «Adu03_Foto» |
| 11 |  |  | 11 · Transition |
| 12 |  |  | 12 · Reach @ Parque |
| 13 |  |  | 13 · Cinematic «Adu03_Banco» |
| 14 |  |  | 14 · Scene «Banco» |
| 15 |  |  | — |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 1 frases al cumplirlo (escena ligera «Adu03_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): 3 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Adu03_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Noticia»): conversación «Noticia» con 13 frases nuevas
- PASO 4.1 → paso 4.1 del juego (Talk «Nico»): conversación «Nico» con 5 frases nuevas
- PASO 4.2 → paso 4.2 del juego (Talk «Sara»): conversación «Sara» con 5 frases nuevas
- PASO 4.3 → paso 4.3 del juego (Talk «Bruno»): conversación «Bruno» con 8 frases nuevas
- PASO 4.4 → paso 4.4 del juego (Talk «Leire»): conversación «Leire» con 5 frases nuevas
- PASO 4.5 → paso 4.5 del juego (Talk «Hugo»): conversación «Hugo» con 1 frases nuevas
- PASO 4.6 → paso 4.6 del juego (Talk «Mateo»): conversación «Mateo» con 5 frases nuevas
- PASO 6 → paso 6 del juego (Talk «Lucia»): conversación «Lucia» con 15 frases nuevas
- PASO 7 → paso 7 del juego (Reach): 1 frases al empezar el paso (escena ligera «Adu03_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (MiniGame): 2 frases al empezar el paso (escena ligera «Adu03_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Scene «Inauguracion»): conversación «Inauguracion» con 12 frases nuevas
- PASO 10 → paso 10 del juego (Cinematic «Adu03_Foto»): escena nueva «Adu03_G10» (1 planos, 1 frases, 3.1 s) justo después de «Adu03_Foto», que se queda como estaba
- PASO 11 → paso 11 del juego (Transition): 3 frases al cumplirlo (escena ligera «Adu03_G11_Fin», sin quitar el control)
- PASO 12 → paso 12 del juego (Reach): 1 frases al empezar el paso (van detrás de las del final del paso 11, en su escena «Adu03_G11_Fin»)
- PASO 13 → paso 13 del juego (Cinematic «Adu03_Banco»): la escena «Adu03_Banco» se cuenta con el guion nuevo (misma escena, 1 planos, 5 frases, 18.5 s)
- PASO 14 → paso 14 del juego (Scene «Banco»): conversación «Banco» con 13 frases nuevas

## Adaptado (y por qué)

- PASO 15 [] @ : no corresponde a ningún paso del juego: no se aplica
- frase quitada (es una acotación, no se dice): «Música»
- PASO 1: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4 → paso 4 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.1: «nico_invitado = true» no la lee ninguna misión: no se crea
- PASO 4.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.2: «sara_invitada = true» no la lee ninguna misión: no se crea
- PASO 4.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.3: «bruno_invitado = true» no la lee ninguna misión: no se crea
- PASO 4.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.4: «leire_invitada = true» no la lee ninguna misión: no se crea
- PASO 4.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.5: «hugo_invitado = true» no la lee ninguna misión: no se crea
- PASO 4.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.6: «mateo_invitado = true» no la lee ninguna misión: no se crea
- PASO 5 → paso 5 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 9: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 10: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 10: el guion no trae planos para la cinemática: un plano general lento del sitio
- PASO 11: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 13: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 13: el guion no trae planos para «Adu03_Banco»: se conservan los de la escena de antes
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 4 (línea 239): «Mínimo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 4 (línea 241): «Máximo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 10 (línea 1221): «General» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 10 (línea 1223): «DosPlanos» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 10 (línea 1225): «Reaccion» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 10 (línea 1233): «Inserto» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 13 (línea 1344): «Lateral» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 14 · OPCIÓN A — HIJOS: “Cuando tengamos hijos, que sean amigos como nosotros.” / OMAR: Y que se sienten en este banco. / Mira el espacio. / OMAR: Y que tampoco quepan.
- PASO 14 · OPCIÓN B — VIAJE: “Un viaje juntos, todos, antes de los treinta.” / SARA: Propongo Villaverde. /  / SARA: La granja. / NICO: ¿Donde se perdió Mateo? / MATEO: No me perdí. / Todos lo miran. / MATEO: Bueno. /  / MATEO: Un poco. / Risas.
- PASO 14 · OPCIÓN C — SIEMPRE: “Nada de promesas. Esto ya es para siempre.” / Nico se queda callado. / Por primera vez, no hace una broma. / NICO: Eso ha sido muy bonito. /  / NICO: Que nadie diga nada. / Mira a todos. / NICO: Nadie. /  / El grupo sonríe.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
