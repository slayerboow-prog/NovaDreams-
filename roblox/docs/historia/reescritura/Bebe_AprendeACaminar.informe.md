# Informe de la reescritura · Bebe_AprendeACaminar

Guion: `docs/historia/reescritura/Bebe_AprendeACaminar.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Bebe_AprendeACaminar`.
Datos: `src/shared/LifeStory/Guiones/Bebe_AprendeACaminar.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

El guion cuenta que es MAMÁ quien te descubre andando; en el juego el paso 3 es llegar hasta Abu (su sitio en la casa) y la escena era con Abu. Se conserva la mecánica (ir hasta Abu) y la escena nueva es la del guion con «Familia» (Mamá o Papá según tu casa: el juego tiene Papá+Abu Rosa o Mamá+Abu Tomás). «Madre» del guion = Familia.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Cinematic | Habitación del bebé | 1 · Event (BabyStood) |
| 2 | Action | Habitación del bebé | 1 · Event (BabyStood) |
| 3 | Action | Habitación del bebé | 2 · Event (BabySteps) |
| 4 | Action | Habitación del bebé | 2 · Event (BabySteps) |
| 5 | Action | Pasillo | 3 · Talk @ FamiliaAbu |
| 6 | Action | Salón | 3 · Talk @ FamiliaAbu |
| 7 | Talk | Salón | 4 · Cinematic «Bebe_PrimerosPasosAbu» |
| 8 | Cinematic | Salón | 4 · Cinematic «Bebe_PrimerosPasosAbu» |
| 9 | Transition | Salón | 4 · Cinematic «Bebe_PrimerosPasosAbu» |

## Errores

_Ninguno._


## Aplicado

- PASO 1+2 → paso 1 del juego (Event): 9 frases al cumplirlo (escena ligera «Bebe_Caminar_G1_2_Fin», sin quitar el control)
- PASO 3+4 → paso 2 del juego (Event): 6 frases al cumplirlo (escena ligera «Bebe_Caminar_G3_4_Fin», sin quitar el control)
- PASO 5+6 → paso 3 del juego (Talk): 2 frases al cumplirlo (escena ligera «Bebe_Caminar_G5_6_Fin», sin quitar el control)
- PASO 5+6 → paso 3 del juego (Talk): 3 frases al empezar el paso (van detrás de las del final del paso 2, en su escena «Bebe_Caminar_G3_4_Fin»)
- PASO 7+8+9 → paso 4 del juego (Cinematic «Bebe_PrimerosPasosAbu»): la escena «Bebe_PrimerosPasosAbu» se cuenta con el guion nuevo (misma escena, 30 planos, 22 frases, 76.7 s, música Intima→Descubrimiento)

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [Cinematic] y en el juego es paso jugable (Event): se conserva el tipo del juego y su mecánica
- PASO 1+2: 14 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3+4: 15 PLANO de un paso jugable (Event) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5+6: 12 PLANO de un paso jugable (Talk) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7: el guion lo escribe como [Talk] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 7 (línea 115) · Familia: «Mi pequeño explorador.» → «Mi pequeñ{o/a} explorador{/a}.»

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
