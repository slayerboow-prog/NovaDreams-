# Informe de la reescritura · Saga_08_MegaVerso

Guion: `docs/historia/reescritura/Saga_08_MegaVerso.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_08_MegaVerso`.
Datos: `src/shared/LifeStory/Guiones/Saga_08_MegaVerso.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la recepción de la oficina de MegaVerso, buscar información mientras nadie mira (folletos, ordenador y el mapa de la pared, que da SabeFusion como antes), la huida hasta la plaza del Distrito Financiero (Escape) y la escena de fuera. La recepcionista es la agente gris 2 del reparto. No se construye un edificio nuevo: es la oficina de siempre.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Recepcion» |
| 2 |  |  | 2 · Group |
| 2.1 |  |  | 2.1 · Use (Folletos) |
| 2.2 |  |  | 2.2 · Use (Ordenador) |
| 2.3 |  |  | 2.3 · Use (Mapa) |
| 3 |  |  | 3 · Escape @ PlazaFinanciera |
| 4 | Scene |  | 4 · Scene «Fuera» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Recepcion»): conversación «Recepcion» con 16 frases nuevas
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Folleto» (4 frases)
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Ordenador» (3 frases)
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mapa» (2 frases)
- PASO 3 → paso 3 del juego (Escape): 3 frases al empezar el paso (escena ligera «Saga_08_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4: efectos del guion sumados a la conversación «Fuera»: megaverso_infiltrado = true · descubrio_proyecto_fusion = true · folio_megaverso = true · sabe_fusion = true · fecha_fusion_descubierta = true
- PASO 4 → paso 4 del juego (Scene «Fuera»): conversación «Fuera» con 8 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 1: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 2 → paso 2 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: «megaverso_infiltrado = true» no la lee ninguna misión: no se crea
- PASO 4: «descubrio_proyecto_fusion = true» no la lee ninguna misión: no se crea
- PASO 4: «folio_megaverso = true» no la lee ninguna misión: no se crea
- PASO 4: «fecha_fusion_descubierta = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 150) · AgenteGris2: «¡Bienvenido/Bienvenida a MegaVerso S.A.!» → «¡Bienvenid{o/a} a MegaVerso S.A.!»

## Avisos

- PASO 3 (línea 769): «Destino» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 4 · DIRECCIÓN DE MEGAVERSO: MegaVerso no debe parecer una empresa malvada típica.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
