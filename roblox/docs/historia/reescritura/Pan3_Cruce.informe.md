# Informe de la reescritura · Pan3_Cruce

Guion: `docs/historia/reescritura/Pan3_Cruce.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Pan3_Cruce`.
Datos: `src/shared/LifeStory/Guiones/Pan3_Cruce.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: Rayo solo en el parque y su oferta (Pan3_Oferta), Nerea en el patio, la decisión Camino y su rama (el negocio de camisetas falsas en el estadio, ir con Nerea a hablar con Carmen, o llevar a Rayo al taller de Tobías y volver a decírselo), la noche y el espejo. Las variantes van con lo que guarda el juego: la marca Hurto de Pan2, el recuerdo LaNoche, la relación con Rayo (Rel) y los caminos Camino_Delincuente / Camino_Trabajador con la Rebeldía.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ Parque |
| 3 | Cinematic |  | 3 · Cinematic «Pan3_Oferta» |
| 4 |  |  | 4 · Reach @ PatioInstituto |
| 5 |  |  | 5 · Talk «Nerea» |
| 6 |  |  | 6 · Choice |
| 7 |  |  | 7 · Reach @ EstadioAltamar |
| 8 | Scene |  | 8 · Scene «Estadio» |
| 9 |  |  | 9 · Reach @ AulaInstituto |
| 10 | Scene |  | 10 · Scene «Carmen» |
| 11 |  |  | 11 · Reach @ Gasolinera |
| 12 |  |  | 12 · Talk «Tomas» |
| 13 |  |  | 13 · Reach @ Parque |
| 14 |  |  | 14 · Talk «Salvar» |
| 15 | Transition |  | 15 · Transition |
| 16 | Scene |  | 16 · Scene «Espejo» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Reach): 3 frases al empezar el paso (escena ligera «Pan3_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 3 del juego (Cinematic «Pan3_Oferta»): la escena «Pan3_Oferta» se cuenta con el guion nuevo (misma escena, 1 planos, 38 frases, 105.6 s, música Descubrimiento→Tension)
- PASO 5 → paso 5 del juego (Talk «Nerea»): conversación «Nerea» con 18 frases nuevas
- PASO 6 → paso 6 del juego (Choice): 16 frases al empezar el paso (escena ligera «Pan3_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (Scene «Estadio»): conversación «Estadio» con 21 frases nuevas
- PASO 9 → paso 9 del juego (Reach): 1 frases al empezar el paso (escena ligera «Pan3_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Scene «Carmen»): conversación «Carmen» con 15 frases nuevas
- PASO 12 → paso 12 del juego (Talk «Tomas»): conversación «Tomas» con 7 frases nuevas
- PASO 14: efectos del guion sumados a la conversación «Salvar»: rayo_cambia = true · rayo_cambia = true
- PASO 14 → paso 14 del juego (Talk «Salvar»): conversación «Salvar» con 18 frases nuevas
- PASO 16 → paso 16 del juego (Scene «Espejo»): conversación «Espejo» con 18 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3: el guion no trae planos para «Pan3_Oferta»: se conservan los de la escena de antes
- PASO 4 → paso 4 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7 → paso 7 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 11 → paso 11 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 12: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 13 → paso 13 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 14: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 15 → paso 15 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 16: una frase del juego daba efectos (Flags): se conservan al final de la conversación

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 14 (línea 1291) · Rayo: «Qué pesado/a.» → «Qué pesad{o/a}.»
- PASO 16 (línea 1369) · Familia: «Te noto raro/a últimamente.» → «Te noto rar{o/a} últimamente.»

## Avisos

- PASO 3: la cinemática nueva dura 105 s (se puede saltar, pero es larga: el guion trae 1 planos)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 16 · DIRECCIÓN DE RAYO: La escena final debe dejar claro que Rayo no es un monstruo. / Es un adolescente que: / * busca reconocimiento / * tiene problemas familiares / * quiere dinero / * quiere pertenecer a algo / * no sabe qué hacer con su vida / * ha aprendido a sobrevivir mediante la rebeldía / Por eso la opción de salvarlo debe sentirse difícil pero posible.
- PASO 16 · DIRECCIÓN DE NEREA: Nerea representa: / la valentía de marcharse. / Rayo: No necesita ser salvada por el protagonista.
- PASO 16 · DIRECCIÓN DE NICO: Nico funciona aquí como espejo.
- PASO 16 · DIRECCIÓN DE ABU: La frase:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
