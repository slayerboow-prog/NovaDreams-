# Informe de la reescritura · Saga_15_Reestreno

Guion: `docs/historia/reescritura/Saga_15_Reestreno.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_15_Reestreno`.
Datos: `src/shared/LifeStory/Guiones/Saga_15_Reestreno.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la Capitana Ñoz baja de la nave, el minijuego de la grabación (Timing) y la escena final (el pase VIP).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Capitana» |
| 2 |  |  | 2 · MiniGame |
| 3 | Scene |  | 3 · Scene «Grabacion» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Capitana»): conversación «Capitana» con 41 frases nuevas
- PASO 2 → paso 2 del juego (MiniGame): objetivo «completar correctamente el rodaje.»
- PASO 2 → paso 2 del juego (MiniGame): 17 frases al empezar el paso (escena ligera «Saga_15_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3: efectos del guion sumados a la conversación «Grabacion»: saga_15_completada = true · grabacion_laboratorio = true · laboratorio_cosimo_confirmado = true · cosme_vivo_confirmado = true · pase_vip_plato = true · buen_rodaje = true · buen_rodaje = false · coordenadas_66B_obtenidas = true · collar_gatonia_obtenido = true · equipo_rescate_activo = true
- PASO 3 → paso 3 del juego (Scene «Grabacion»): conversación «Grabacion» con 34 frases nuevas (música Tension)

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3: «saga_15_completada = true» no la lee ninguna misión: no se crea
- PASO 3: «laboratorio_cosimo_confirmado = true» no la lee ninguna misión: no se crea
- PASO 3: «cosme_vivo_confirmado = true» no la lee ninguna misión: no se crea
- PASO 3: «pase_vip_plato = true» no la lee ninguna misión: no se crea
- PASO 3: «coordenadas_66B_obtenidas = true» no la lee ninguna misión: no se crea
- PASO 3: «collar_gatonia_obtenido = true» no la lee ninguna misión: no se crea
- PASO 3: «equipo_rescate_activo = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 1 (línea 126) · CapitanNoz: «¡Mi terrícola favorito/a!» → «¡Mi terrícola favorit{o/a}!»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · OBJETIVO: Habla con la Capitana Ñoz.
- PASO 2 · Objetivo: completar correctamente el rodaje.: 
- PASO 3 · MOMENTO DE BIOGRAFÍA: «Protagonizaste un episodio especial de «Terrícolas en apuros»»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
