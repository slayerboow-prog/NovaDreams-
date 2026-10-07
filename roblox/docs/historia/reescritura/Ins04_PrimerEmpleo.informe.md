# Informe de la reescritura · Ins04_PrimerEmpleo

Guion: `docs/historia/reescritura/Ins04_PrimerEmpleo.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins04_PrimerEmpleo`.
Datos: `src/shared/LifeStory/Guiones/Ins04_PrimerEmpleo.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el deseo del verano, el taller de Carmen, buscar ofertas, elegir trabajo (cafetería, súper o Correos) y su entrevista, llegar puntual, las tareas del tablón de trabajo, el imprevisto, el sueldo (por la economía de siempre) y la cena. El guion propone ocho rutas de primer trabajo; el juego tiene tres trabajos y solo la cocina coincide (la cafetería de Lola): esa ruta sale con Empleo = Barista y las demás (taller, audiovisual, deporte, empresa, comunidad, laboratorio, jurídico) no salen (pendiente: más trabajos de verano). Las conversaciones de cada trabajo (primer día, imprevisto, sueldo y cena) conservan delante sus frases propias de Paco y Ernesto. Los mensajes de Rayo y Nerea solo llegan si hiciste Pan1 (los conociste); el de Leire, con ConocesALeire.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Scene «Deseo» |
| 3 |  |  | 4 · Scene «Perfil» |
| 4 |  |  | — |
| 5 |  |  | 7 · Transition |
| 6 |  |  | 11 · Scene «PrimerDia» |
| 7 |  |  | 15 · Scene «Imprevisto» |
| 8 | Scene |  | 15 · Scene «Imprevisto» |
| 9 |  |  | 15 · Scene «Imprevisto» |
| 10 |  |  | 19 · Scene «Sueldo» |
| 11 |  |  | 19 · Scene «Sueldo» |
| 12 |  |  | 20 · Transition |
| 13 | Scene |  | 21 · Scene «Cena» |
| 14 |  |  | 21 · Scene «Cena» |
| 15 | Scene |  | 21 · Scene «Cena» |
| 16 | Cinematic |  | 21 · Scene «Cena» |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Scene «Deseo»): conversación «Deseo» con 2 frases nuevas
- PASO 3 → paso 4 del juego (Scene «Perfil»): conversación «Perfil» con 13 frases nuevas
- PASO 6 → paso 11 del juego (Scene «PrimerDia»): conversación «PrimerDia» con 7 frases nuevas
- PASO 7+8+9 → paso 15 del juego (Scene «Imprevisto»): conversación «Imprevisto» con 7 frases nuevas
- PASO 10+11 → paso 19 del juego (Scene «Sueldo»): conversación «Sueldo» con 0 frases nuevas
- PASO 13+14+15+16 → paso 21 del juego (Scene «Cena»): conversación «Cena» con 16 frases nuevas (música Intima)
- Conversación «PrimerDia»: se conservan delante 9 frases del juego que dependen de lo vivido
- Conversación «Imprevisto»: se conservan delante 5 frases del juego que dependen de lo vivido
- Conversación «Sueldo»: se conservan delante 3 frases del juego que dependen de lo vivido
- Conversación «Cena»: se conservan delante 2 frases del juego que dependen de lo vivido

## Adaptado (y por qué)

- PASO 4 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 2: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 3: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 5: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 5 → paso 7 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 7: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 9: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 7+8+9: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 10: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 10+11: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 12: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 12 → paso 20 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 16: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 3 (línea 169) · Carmen: «Sofía puede enseñarte un pequeño proyecto de laboratorio.» → «Sofía puede enseñarte un pequeñ{o/a} proyecto de laboratorio.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 6 · MINIJUEGO: Lola: Preparar tres pedidos.
- PASO 6 · OBJETIVO: Preparar:
- PASO 6 · MINIJUEGO: Irene: Organizar conos.
- PASO 6 · MINIJUEGO: Marcos: Encontrar productos.
- PASO 6 · MINIJUEGO: Sofía: Clasificar materiales.
- PASO 16 · DIRECCIÓN AAA: El trabajo debe tener:
- PASO 16 · Dirección:: Primer día:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
