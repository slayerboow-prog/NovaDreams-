# Informe de la reescritura · Saga_23_Fusion

Guion: `docs/historia/reescritura/Saga_23_Fusion.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_23_Fusion`.
Datos: `src/shared/LifeStory/Guiones/Saga_23_Fusion.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: la cinemática Grieta_Fusion (conserva su mecánica), la llegada a la cima, aguantar 25 segundos el tirón de la Grieta (la versión de siempre, con sus zonas seguras), la oleada de drones con tus aliados (los que vinieron: sus marcas Aliado*), los Restos si tienes 4 o más, Cósimo y la rendición con la decisión final (CosimoPerdonado / CosimoArregla66B, las marcas que lee Saga_24). Las variantes van con la decisión Trato de Saga_22 (No / Trampa), ConsorcioCaido, PerdonaACosme / EnfadoConCosme. Sin K.O. ni hospital: si te alcanzan, el paso te recoloca y sigues (las frases de «si te atrapan» no tienen cuándo salir). Los micro-recuerdos de los Restos son frases cortas de la escena, sin pausar el juego.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Cinematic |  | 1 · Cinematic «Grieta_Fusion» |
| 2 | Scene |  | 2 · Scene «Llegada» |
| 3 |  |  | 3 · Escape |
| 4 |  |  | 4 · Fight @ CimaMonte |
| 5 | Scene |  | 5 · Scene «Restos» |
| 6 |  |  | 6 · Fight @ CimaMonte |
| 7 |  |  | 7 · Fight @ CimaMonte |
| 8 | Scene |  | 8 · Scene «Rendicion» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Cinematic «Grieta_Fusion»): la escena «Grieta_Fusion» se cuenta con el guion nuevo (misma escena, 6 planos, 11 frases, 32.4 s, música Tension)
- PASO 2 → paso 2 del juego (Scene «Llegada»): conversación «Llegada» con 17 frases nuevas (música Intima)
- PASO 3 → paso 3 del juego (Escape): 4 frases al empezar el paso (escena ligera «Saga_23_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Fight): 16 frases al empezar el paso (escena ligera «Saga_23_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «Restos»): conversación «Restos» con 9 frases nuevas
- PASO 6 → paso 6 del juego (Fight): 5 frases al empezar el paso (escena ligera «Saga_23_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (Fight): 5 frases al empezar el paso (escena ligera «Saga_23_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8: efectos del guion sumados a la conversación «Rendicion»: cosimo_perdonado = true · cosimo_arregla_66b = true · saga_23_fusion_completada = true · venciste_gran_fusion = true · cosimo_derrotado = true · maquina_fusion_detenida = true · grieta_final_abierta = true · restos_grieta_utilizados = true · cosimo_perdonado = true · cosimo_arregla_66b = true
- PASO 8 → paso 8 del juego (Scene «Rendicion»): conversación «Rendicion» con 42 frases nuevas (música Intima→Tema)

## Adaptado (y por qué)

- PASO 1: el guion no trae planos para «Grieta_Fusion»: se conservan los de la escena de antes
- PASO 8: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 8: «saga_23_fusion_completada = true» no la lee ninguna misión: no se crea
- PASO 8: «venciste_gran_fusion = true» no la lee ninguna misión: no se crea
- PASO 8: «cosimo_derrotado = true» no la lee ninguna misión: no se crea
- PASO 8: «maquina_fusion_detenida = true» no la lee ninguna misión: no se crea
- PASO 8: «grieta_final_abierta = true» no la lee ninguna misión: no se crea
- PASO 8: «restos_grieta_utilizados = true» no la lee ninguna misión: no se crea

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 723) · Gnomo1: «Tranquilo.» → «Tranquil{o/a}.»

## Avisos

- PASO 8 (línea 1569): «Capas» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 8 · Al terminar:: «Venciste en la Gran Fusión»
- PASO 8 · DIRECCIÓN TÉCNICA AAA: Cámara

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
