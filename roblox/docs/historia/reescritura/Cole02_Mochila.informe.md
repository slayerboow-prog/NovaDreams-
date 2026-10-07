# Informe de la reescritura · Cole02_Mochila

Guion: `docs/historia/reescritura/Cole02_Mochila.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole02_Mochila`.
Datos: `src/shared/LifeStory/Guiones/Cole02_Mochila.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Los Pinos | 1 · Transition |
| 2 | Action | Aula de 1.º A | 2 · Reach @ AulaA |
| 3 | Talk | Aula de 1.º A | 3 · Scene «Encargo» |
| 4 | Talk | Conserjería | 4 · Talk «Ramon_Lista» |
| 5 | Action | Aula de 1.º A | 5 · Reach @ AulaA |
| 6 | Cinematic | Aula de 1.º A | 6 · Scene «NoEsta» |
| 7 | Action | Aula de 1.º A / Pasillo | 7 · Group |
| 7.1 | Action | Aula de 1.º A / Pasillo | 7.1 · Use (Pupitre) |
| 7.2 | Action | Aula de 1.º A / Pasillo | 7.2 · Use (Taquilla) |
| 7.3 | Action | Aula de 1.º A / Pasillo | 7.3 · Use (Papelera) |
| 8 | Talk | Aula de 1.º A | 8 · Scene «Lucia_Pregunta» |
| 9 | Action | Colegio | 9 · Group |
| 9.1 | Action | Colegio | 9.1 · Talk «Testigo_Mateo» |
| 9.2 | Action | Colegio | 9.2 · Talk «Testigo_Sara» |
| 9.3 | Action | Colegio | 9.3 · Talk «Testigo_Omar» |
| 9.4 | Action | Colegio | 9.4 · Talk «Testigo_Iker» |
| 10 | Action | Patio | 10 · Group |
| 10.1 | Action | Patio | 10.1 · Use (Papel) |
| 10.2 | Action | Patio | 10.2 · Use (Pegatina) |
| 10.3 | Action | Patio | 10.3 · Use (Huella) |
| 10.4 | Action | Patio | 10.4 · Use (Llavero) |
| 10.5 | Action | Patio | 10.5 · Use (Envoltorio) |
| 11 | Cinematic | Patio | 11 · Scene «Deduccion» |
| 12 | Action | Gimnasio | 12 · Reach @ GimnasioColegio |
| 13 | Talk | Gimnasio | 13 · Talk «Alex_Reto» |
| 14 | Action | Gimnasio | 14 · MiniGame |
| 15 | Talk | Gimnasio | 15 · Scene «Alex_Pista» |
| 16 | Action | Gimnasio | 16 · Reach @ AlmacenColegio |
| 17 | Cinematic | Almacén del gimnasio | 17 · Scene «Almacen_Entra» |
| 18 | Action | Almacén | 18 · Group |
| 18.1 | Action | Almacén | 18.1 · Use (MochilaRoja) |
| 18.2 | Action | Almacén | 18.2 · Use (MochilaVerde) |
| 18.3 | Action | Almacén | 18.3 · Use (MochilaGris) |
| 19 | Talk | Almacén | 19 · Scene «Ruben_Aparece» |
| 20 | Action | Almacén | 20 · Use (GorraRuben) |
| 21 | Cinematic | Almacén del gimnasio | 21 · Scene «Lucia_Final» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 5 frases al cumplirlo (escena ligera «Cole02_Mochila_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve a clase (1.º A)»
- PASO 2 → paso 2 del juego (Reach): 3 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole02_Mochila_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Encargo»): conversación «Encargo» con 8 frases nuevas (música Descubrimiento)
- PASO 4 → paso 4 del juego (Talk «Ramon_Lista»): conversación «Ramon_Lista» con 17 frases nuevas (música Descubrimiento)
- PASO 5 → paso 5 del juego (Reach): objetivo «Vuelve a clase»
- PASO 5 → paso 5 del juego (Reach): 1 frases al empezar el paso (escena ligera «Cole02_Mochila_G5_Entra», la lanza el paso 4 al cumplirse; el jugador no pierde el control)
- PASO 6 → paso 6 del juego (Scene «NoEsta»): conversación «NoEsta» con 8 frases nuevas (música Tension)
- PASO 7 → paso 7 del juego (Group): objetivo «Busca tu mochila en el aula»
- PASO 7.1 → paso 7.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Buscar_Pupitre» (2 frases)
- PASO 7.2 → paso 7.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Buscar_Taquilla» (2 frases)
- PASO 7.3 → paso 7.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Buscar_Papelera» (3 frases)
- PASO 8 → paso 8 del juego (Scene «Lucia_Pregunta»): conversación «Lucia_Pregunta» con 12 frases nuevas (música Tension)
- PASO 9 → paso 9 del juego (Group): objetivo «Pregunta a tus compañeros»
- PASO 9.1 → paso 9.1 del juego (Talk «Testigo_Mateo»): conversación «Testigo_Mateo» con 14 frases nuevas (música Tension)
- PASO 9.2 → paso 9.2 del juego (Talk «Testigo_Sara»): conversación «Testigo_Sara» con 8 frases nuevas (música Tension)
- PASO 9.3 → paso 9.3 del juego (Talk «Testigo_Omar»): conversación «Testigo_Omar» con 8 frases nuevas (música Tension)
- PASO 9.4 → paso 9.4 del juego (Talk «Testigo_Iker»): conversación «Testigo_Iker» con 10 frases nuevas (música Tension)
- PASO 10 → paso 10 del juego (Group): objetivo «Busca pistas en el patio»
- PASO 10.1 → paso 10.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Papel» (3 frases)
- PASO 10.2 → paso 10.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Pegatina» (4 frases)
- PASO 10.3 → paso 10.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Huella» (3 frases)
- PASO 10.4 → paso 10.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Llavero» (2 frases)
- PASO 10.5 → paso 10.5 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Envoltorio» (5 frases)
- PASO 11 → paso 11 del juego (Scene «Deduccion»): conversación «Deduccion» con 11 frases nuevas (música Tension)
- PASO 12 → paso 12 del juego (Reach): objetivo «Sigue las pistas hasta el gimnasio»
- PASO 12 → paso 12 del juego (Reach): 4 frases al empezar el paso (escena ligera «Cole02_Mochila_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Talk «Alex_Reto»): conversación «Alex_Reto» con 13 frases nuevas (música Descubrimiento)
- PASO 14 → paso 14 del juego (MiniGame): objetivo «¡Mete 3 canastas!»
- PASO 15 → paso 15 del juego (Scene «Alex_Pista»): conversación «Alex_Pista» con 15 frases nuevas (música Tension)
- PASO 16 → paso 16 del juego (Reach): objetivo «Ve al almacén del gimnasio»
- PASO 16 → paso 16 del juego (Reach): 1 frases al empezar el paso (escena ligera «Cole02_Mochila_G16_Entra», la lanza el paso 15 al cumplirse; el jugador no pierde el control)
- PASO 17 → paso 17 del juego (Scene «Almacen_Entra»): conversación «Almacen_Entra» con 7 frases nuevas (música Tension)
- PASO 18 → paso 18 del juego (Group): objetivo «Revisa las mochilas del almacén»
- PASO 18.1 → paso 18.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Almacen_Roja» (1 frases)
- PASO 18.2 → paso 18.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Almacen_Verde» (2 frases)
- PASO 18.3 → paso 18.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Almacen_Gris» (5 frases)
- PASO 19 → paso 19 del juego (Scene «Ruben_Aparece»): conversación «Ruben_Aparece» con 35 frases nuevas (música Tension)
- PASO 20 → paso 20 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Broma_Gorra» (11 frases)
- PASO 20 → paso 20 del juego (Use): objetivo «Esconde la gorra de Rubén»
- PASO 21 → paso 21 del juego (Scene «Lucia_Final»): conversación «Lucia_Final» con 47 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1: 4 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 5 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 5: 5 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 7.1: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7.2: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7.3: 3 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 9.1: el guion lo escribe como [Action] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 9.2: el guion lo escribe como [Action] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 9.3: el guion lo escribe como [Action] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 9.4: el guion lo escribe como [Action] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 10.1: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10.2: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10.3: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10.4: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10.5: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 12: 2 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 14: 4 PLANO de un paso jugable (MiniGame) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 16: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 17: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 18.1: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 18.2: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 18.3: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 20: 6 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 21: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 4 (línea 161) · Ramon: «Qué responsabilidad tan grande para alguien tan pequeño.» → «Qué responsabilidad tan grande para alguien tan pequeñ{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: «Ve a clase (1.º A)»: Los alumnos ocupan sus sitios.
- PASO 4 · OBJETIVO: «Lleva la lista de clase a Ramón»: Ramón trabaja entre llaves, papeles y objetos perdidos.
- PASO 5 · OBJETIVO: «Vuelve a clase»: El protagonista entra al aula.
- PASO 7 · OBJETIVO: «Busca tu mochila en el aula»: 
- PASO 9 · OBJETIVO: «Pregunta a tus compañeros»: 
- PASO 9.4 · Charla opcional — Nico: Nico: ¿Tu mochila?
- PASO 10 · OBJETIVO: «Busca pistas en el patio»: 
- PASO 12 · OBJETIVO: «Sigue las pistas hasta el gimnasio»: Alumnos mayores entrenan.
- PASO 14 · OBJETIVO: «¡Mete 3 canastas!»: 
- PASO 14 · MINIJUEGO:: * Tres lanzamientos. / * La zona de acierto cambia en cada lanzamiento. / * Cada canasta aumenta ligeramente la dificultad. / * El jugador puede fallar.
- PASO 16 · OBJETIVO: «Ve al almacén del gimnasio»: El jugador se acerca a la puerta.
- PASO 18 · OBJETIVO: «Revisa las mochilas del almacén»: 
- PASO 20 · OBJETIVO: «Esconde la gorra de Rubén»: Rubén se agacha para atarse una zapatilla.
- PASO 21 · SISTEMA DE MEMORIA AL TERMINAR: Registrar:
- PASO 21 · CONSECUENCIAS FUTURAS: Rubén
- PASO 21 · MOMENTO DE BIOGRAFÍA: «Recuperaste tu mochila»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
