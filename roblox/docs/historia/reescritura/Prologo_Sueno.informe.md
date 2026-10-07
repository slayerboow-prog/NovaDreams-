# Informe de la reescritura · Prologo_Sueno

Guion: `docs/historia/reescritura/Prologo_Sueno.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Prologo_Sueno`.
Datos: `src/shared/LifeStory/Guiones/Prologo_Sueno.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Nota: en el juego el paso 8 del prólogo es «Abre el mapa de Valmar» (enseña la tecla M); el guion lo escribió como «abrir la puerta del garaje». Se conserva el paso del mapa (es el tutorial del control) y las frases del PASO 8 suenan al llegar a la puerta (al cumplir el paso 7).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Cinematic | El sueño | 1 · Cinematic «Prologo_Apertura» |
| 2 | Talk | El círculo de luz | 2 · Reach @ PrologoCamino |
| 3 | Action | El sueño | 3 · Event (Sprinted) |
| 4 | Action | Detrás de la valla de flores | 4 · Reach @ PrologoSalto |
| 5 | Cinematic | Garaje de Cosme | 5 · Talk «Sueno» |
| 6 | Action | Garaje de Cosme | 6 · Use (Tornillo) |
| 7 | Action | Camino al garaje | 7 · Reach @ PrologoPuerta |
| 8 | Action | Puerta del garaje | 8 · Event (MapOpened) |
| 9 | Cinematic | El sueño | 9 · Cinematic «Prologo_Cierre» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Cinematic «Prologo_Apertura»): cinemática nueva «Prologo_G1» (13 planos, 10 frases, 39.7 s, música Descubrimiento) en lugar de «Prologo_Apertura»
- PASO 2 → paso 2 del juego (Reach): 2 frases al empezar el paso (escena ligera «Prologo_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 3 del juego (Event): 1 frases al empezar el paso (escena ligera «Prologo_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)
- PASO 4 → paso 4 del juego (Reach): 2 frases al cumplirlo (escena ligera «Prologo_G4_Fin», sin quitar el control)
- PASO 5 → paso 5 del juego (Talk «Sueno»): conversación «Sueno» con 32 frases nuevas (música Tension)
- PASO 6 → paso 6 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Tornillo» (6 frases)
- PASO 7 → paso 7 del juego (Reach): 5 frases al empezar el paso (escena ligera «Prologo_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (Event): 3 frases al empezar el paso (escena ligera «Prologo_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9: se conservan los rótulos de «Prologo_Cierre» (explican el juego)
- PASO 9 → paso 9 del juego (Cinematic «Prologo_Cierre»): cinemática nueva «Prologo_G9» (10 planos, 10 frases, 45.5 s, música Intima) en lugar de «Prologo_Cierre»

## Adaptado (y por qué)

- PASO 2: el guion lo escribe como [Talk] y en el juego es paso jugable (Reach): se conserva el tipo del juego y su mecánica
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: 4 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 4: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5: el guion lo escribe como [Cinematic] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 6: 9 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7: 6 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8: 4 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

_Ninguna._


## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
