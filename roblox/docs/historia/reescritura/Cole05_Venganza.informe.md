# Informe de la reescritura · Cole05_Venganza

Guion: `docs/historia/reescritura/Cole05_Venganza.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole05_Venganza`.
Datos: `src/shared/LifeStory/Guiones/Cole05_Venganza.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

El juego tiene 10 pasos y el guion 24: los PASO 9-20 (la confesión, el concurso de preguntas, lo que decidís con Iker) se cuentan en la conversación de la confesión (paso 9, la que sale al acusar) y los 21-24 en la del final (paso 10). El concurso de preguntas no es un minijuego en esta misión: sus preguntas quedan como elecciones de la conversación. «Musica: Investigación» del PASO 4 no es válida: se usa Calma en la exploración y Tension en las pistas. «bruno_hablaste_con_el» = Choices.Malotes == Hablar (Cole04). Si Iker entra en el grupo queda la marca que ya usa el juego, Flags.IkerEnElGrupo (Choices.IkerFinal = Grupo), para que pueda aparecer con el grupo después; «en prueba» del guion es la opción Perdon del juego y «distancia», la opción Lucia. El «FLASH VISUAL» (recuerdo de una frase de Bruno) es un plano corto con la frase; no hay un efecto de «recuerdo» en el motor, así que va como plano y frase.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar | 1 · Transition |
| 2 | Action | Aula de 1.º A | 2 · Reach @ AulaA |
| 3 | Cinematic | Aula de 1.º A | 3 · Scene «Revuelo» |
| 4 | Action | Colegio | 4 · Group |
| 4.1 |  |  | 4.1 · Talk «Victima_Vega» |
| 4.2 |  |  | 4.2 · Talk «Victima_Alex» |
| 4.3 |  |  | 4.3 · Talk «Victima_Nico» |
| 5 | Action | Colegio | 5 · Group |
| 5.1 |  |  | 5.1 · Use (Nota) |
| 5.2 |  |  | 5.2 · Use (Guantes) |
| 5.3 |  |  | 5.3 · Use (Horario) |
| 5.4 |  |  | 5.4 · Talk «Camaras» |
| 6 | Cinematic | Colegio | 6 · Scene «Deduccion» |
| 7 | Action | Pasillo | 7 · Reach @ PasilloColegio |
| 8 | Choice | Pasillo | 8 · Choice |
| 9 | Cinematic | Pasillo | 9 · Scene «Confesion» |
| 10 | Talk | Pasillo | 9 · Scene «Confesion» |
| 11 | Choice | Pasillo | 9 · Scene «Confesion» |
| 12 | Scene | Aula | 9 · Scene «Confesion» |
| 13 | Talk | Aula | 9 · Scene «Confesion» |
| 14 | Choice | Aula | 9 · Scene «Confesion» |
| 15 | Cinematic | Aula | 9 · Scene «Confesion» |
| 16 | Talk | Aula | 9 · Scene «Confesion» |
| 17 | Talk | Aula | 9 · Scene «Confesion» |
| 18 | Talk | Aula | 9 · Scene «Confesion» |
| 19 | Talk | Aula | 9 · Scene «Confesion» |
| 20 | Scene | Aula | 9 · Scene «Confesion» |
| 21 | Cinematic | Patio | 10 · Scene «Final» |
| 22 | Choice | Patio | 10 · Scene «Final» |
| 23 | Cinematic | Patio | 10 · Scene «Final» |
| 24 | Cinematic | Patio | 10 · Scene «Final» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 3 frases al cumplirlo (escena ligera «Cole05_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve a clase»
- PASO 2 → paso 2 del juego (Reach): 1 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole05_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Revuelo»): conversación «Revuelo» con 25 frases nuevas (música Tension)
- PASO 4 → paso 4 del juego (Group): objetivo «Habla con quienes sufrieron las bromas»
- PASO 4.1 → paso 4.1 del juego (Talk «Victima_Vega»): conversación «Victima_Vega» con 8 frases nuevas
- PASO 4.2 → paso 4.2 del juego (Talk «Victima_Alex»): conversación «Victima_Alex» con 5 frases nuevas
- PASO 4.3 → paso 4.3 del juego (Talk «Victima_Nico»): conversación «Victima_Nico» con 8 frases nuevas
- PASO 5 → paso 5 del juego (Group): objetivo «Busca pistas»
- PASO 5.1 → paso 5.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Nota» (7 frases)
- PASO 5.2 → paso 5.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Guantes» (3 frases)
- PASO 5.2 → paso 5.2 del juego (Use): objetivo «Examina dónde aparecieron los guantes»
- PASO 5.3 → paso 5.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Horario» (3 frases)
- PASO 5.4 → paso 5.4 del juego (Talk «Camaras»): conversación «Camaras» con 11 frases nuevas
- PASO 6 → paso 6 del juego (Scene «Deduccion»): conversación «Deduccion» con 10 frases nuevas (música Tension)
- PASO 7 → paso 7 del juego (Reach): objetivo «Ve al pasillo: todos los sospechosos están allí»
- PASO 7 → paso 7 del juego (Reach): 3 frases al empezar el paso (escena ligera «Cole05_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (Choice): objetivo «¿Quién hizo las bromas?»
- PASO 8 → paso 8 del juego (Choice): 23 frases al empezar el paso (escena ligera «Cole05_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9+10+11+12+13+14+15+16+17+18+19+20: efectos del guion sumados a la conversación «Confesion»: bruno_confianza += 3
- PASO 9+10+11+12+13+14+15+16+17+18+19+20 → paso 9 del juego (Scene «Confesion»): conversación «Confesion» con 156 frases nuevas (música Intima→Descubrimiento→Intima→Descubrimiento→Intima)
- PASO 21+22+23+24: efectos del guion sumados a la conversación «Final»: iker_en_grupo = true · Iker +6 · grupo_ampliado = true · iker_en_prueba = true · Responsabilidad +1 · iker_distancia = true · Empatía +1
- PASO 21+22+23+24 → paso 10 del juego (Scene «Final»): conversación «Final» con 40 frases nuevas (música Intima→Descubrimiento→Intima)
- Momento de la biografía: «Aprendiste que una sospecha no es una prueba.»

## Adaptado (y por qué)

- PASO 1: 3 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.1: «Flags» del guion no se pone a toda la conversación «Victima_Vega» (es de una rama o una nota; lo pone la mecánica)
- PASO 4.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 4.2: «Flags» del guion no se pone a toda la conversación «Victima_Alex» (es de una rama o una nota; lo pone la mecánica)
- PASO 4.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5.1: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5.2: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5.3: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5.4: «Flags» del guion no se pone a toda la conversación «Camaras» (es de una rama o una nota; lo pone la mecánica)
- PASO 6: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 7: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8: 7 PLANO de un paso jugable (Choice) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11 · opción A: marca nueva «IkerDebePerdon» (iker_debe_perdon = true)
- PASO 9: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 15: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 9+10+11+12+13+14+15+16+17+18+19+20: «Condición: culpable = Iker» — el paso del juego no tiene condición: el paso sigue saliendo siempre (su mecánica no cambia) y la condición se pone en sus frases
- PASO 9+10+11+12+13+14+15+16+17+18+19+20 · opción A: el guion pide Traits.Empatia = 1 y el juego ya da 2: se queda lo del juego
- PASO 9+10+11+12+13+14+15+16+17+18+19+20 · opción B: el guion pide Rel.Iker = 3 y el juego ya da 6: se queda lo del juego
- PASO 9+10+11+12+13+14+15+16+17+18+19+20 · opción C: el guion pide Rel.Iker = 4 y el juego ya da -3: se queda lo del juego
- PASO 21: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 22: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 23: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 24: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 21+22+23+24: «grupo_ampliado = true» no la lee ninguna misión: no se crea
- PASO 21+22+23+24: «iker_en_prueba = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 21+22+23+24: «iker_distancia = true» no se guarda aparte (el mapa la deja como condición o ya la da el juego)
- PASO 21+22+23+24: «Flags» del guion no se pone a toda la conversación «Final» (es de una rama o una nota; lo pone la mecánica)

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · SFX: CAMPANA DEL COLEGIO.: Narrador: Hasta hoy.
- PASO 2 · OBJETIVO: «Ve a clase»: Entra en el aula.
- PASO 4 · OBJETIVO: «Habla con quienes sufrieron las bromas»: Nota de implementación: Investigación no es una intensidad musical válida. Usar Calma durante exploración y Tension cuando aparezca una pista relevante.
- PASO 5 · OBJETIVO: «Busca pistas»: Se muestran diferentes zonas investigables.
- PASO 5.2 · OBJETIVO: «Examina dónde aparecieron los guantes»: Están sobre una mesa.
- PASO 7 · OBJETIVO: «Ve al pasillo: todos los sospechosos están allí»: Los cuatro posibles sospechosos se encuentran separados.
- PASO 8 · OBJETIVO: «¿Quién hizo las bromas?»: 
- PASO 12 · OBJETIVO: «Ayuda a Iker a reparar las bromas»: 
- PASO 22 · OBJETIVO: «Decide qué haces con Iker»: A) «Ven con nosotros.»
- PASO 24 · SISTEMA DE MEMORIA: Guardar:
- PASO 24 · MOMENTO DE BIOGRAFÍA: «Aprendiste que una sospecha no es una prueba.»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
