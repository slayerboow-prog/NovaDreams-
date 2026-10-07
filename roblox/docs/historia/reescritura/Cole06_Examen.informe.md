# Informe de la reescritura · Cole06_Examen

Guion: `docs/historia/reescritura/Cole06_Examen.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole06_Examen`.
Datos: `src/shared/LifeStory/Guiones/Cole06_Examen.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

El estudio y el examen son las clases de siempre (ClassService: preguntas y nota) y la recuperación sigue igual (paso 18 con nota < 5). La nota del guion («nota ≥ 9», «entre 5 y 8», «< 5») se mira con las condiciones de nota del juego (LastGradeAtLeast / LastGradeBelow). Lo que el guion cuenta pregunta a pregunta («si cometes varios errores», «si encadenas respuestas correctas») no lo guarda la clase: se resume con la nota final. Marisa, la bibliotecaria, ya está en el reparto. Con quién estudias = Choices.CompaneroEstudio (Sara/Iker/Mateo/Solo). La marca Estudiaste se sigue guardando, pero el guion nuevo solo lee EstudiasteMas.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar / Colegio | 1 · Transition |
| 2 | Ir a | Aula de 1.º A | 2 · Reach @ AulaA |
| 3 | Cinematic | Aula de 1.º A | 3 · Scene «Anuncio» |
| 4 | Ir a | Biblioteca del colegio | 4 · Reach @ BibliotecaColegio |
| 5 | Hablar | Mostrador de la biblioteca | 5 · Talk «Marisa» |
| 6 | Usar | Biblioteca | 6 · Use (Apuntes) |
| 7 | Choice | Biblioteca | 7 · Choice |
| 8 | Gameplay | Biblioteca | 8 · Class @ BibliotecaColegio |
| 9 | Scene | Biblioteca | 9 · Scene «TrasEstudiar» |
| 10 | Transition | Casa | 10 · Transition |
| 11 | Choice | Salón | 11 · Scene «Noche» |
| 12 | Clase / Gameplay | Casa | 12 · Class @ HomeSalon |
| 13 | Transition | Colegio | 13 · Transition |
| 14 | Ir a | Aula de 1.º A | 14 · Reach @ AulaA |
| 15 | Cinematic | Aula de 1.º A | 15 · Scene «Nervios» |
| 16 | Gameplay | Aula de 1.º A | 16 · Class @ AulaA |
| 17 | Cinematic | Aula de 1.º A | 17 · Cinematic «Cole06_LaNota» |
| 18 | Scene | Aula de 1.º A | 18 · Scene «Suspenso» |
| 19 | Ir a | Biblioteca del colegio | 19 · Reach @ BibliotecaColegio |
| 20 | Hablar | Mostrador de la biblioteca | 20 · Talk «Devolver» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): objetivo «Al día siguiente…»
- PASO 1 → paso 1 del juego (Transition): 4 frases al cumplirlo (escena ligera «Cole06_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Ve a clase»
- PASO 2 → paso 2 del juego (Reach): 4 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole06_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Anuncio»): conversación «Anuncio» con 19 frases nuevas (música Tension→Descubrimiento)
- PASO 4 → paso 4 del juego (Reach): objetivo «Ve a la biblioteca a por los apuntes»
- PASO 4 → paso 4 del juego (Reach): 5 frases al empezar el paso (escena ligera «Cole06_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Talk «Marisa»): conversación «Marisa» con 11 frases nuevas
- PASO 6 → paso 6 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «CogerApuntes» (6 frases)
- PASO 6 → paso 6 del juego (Use): objetivo «Coge los apuntes de la mesa»
- PASO 7 → paso 7 del juego (Choice): objetivo «¿Con quién estudias?»
- PASO 8 → paso 8 del juego (Class): objetivo «Estudia en la biblioteca»
- PASO 9 → paso 9 del juego (Scene «TrasEstudiar»): conversación «TrasEstudiar» con 18 frases nuevas
- PASO 10 → paso 10 del juego (Transition): objetivo «Esa noche, en casa…»
- PASO 11 → paso 11 del juego (Scene «Noche»): conversación «Noche» con 21 frases nuevas
- PASO 12 → paso 12 del juego (Class): objetivo «Repasa un poco más»
- PASO 12 → paso 12 del juego (Class): 2 frases al empezar el paso (escena ligera «Cole06_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Transition): objetivo «El día del examen…»
- PASO 13 → paso 13 del juego (Transition): 1 frases al cumplirlo (escena ligera «Cole06_G13_Fin», sin quitar el control)
- PASO 14 → paso 14 del juego (Reach): objetivo «Ve a clase: hoy es el examen»
- PASO 15 → paso 15 del juego (Scene «Nervios»): conversación «Nervios» con 7 frases nuevas (música Tension)
- PASO 16 → paso 16 del juego (Class): objetivo «El examen de Matemáticas»
- PASO 16 → paso 16 del juego (Class): 6 frases al empezar el paso (escena ligera «Cole06_G16_Entra», la lanza el paso 15 al cumplirse; el jugador no pierde el control)
- PASO 17 → paso 17 del juego (Cinematic «Cole06_LaNota»): la escena «Cole06_LaNota» se cuenta con el guion nuevo (misma escena, 9 planos, 19 frases, 56.0 s, música Intima)
- PASO 18 → paso 18 del juego (Scene «Suspenso»): conversación «Suspenso» con 19 frases nuevas (música Intima→Descubrimiento)
- PASO 19 → paso 19 del juego (Reach): objetivo «Devuelve los apuntes a Marisa»
- PASO 19 → paso 19 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole06_G19_Entra», la lanza el paso 18 al cumplirse; el jugador no pierde el control)
- PASO 20 → paso 20 del juego (Talk «Devolver»): conversación «Devolver» con 13 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 1: 4 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 4: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8: 3 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 10: 2 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 11: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 12: 2 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 13: 3 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 14: 2 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 15: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 16: 6 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 17: el plano Inserto de «Hoja» no se encuentra en la escena: plano General del lugar
- PASO 19: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 71) · Lucia: «Hoy tengo un pequeño aviso.» → «Hoy tengo un pequeñ{o/a} aviso.»
- PASO 11 (línea 649) · Familia: «Un cerebro cansado tampoco suma bien.» → «Un cerebro cansad{o/a} tampoco suma bien.»
- PASO 12 (línea 728) · Narrador: «No sabes si estás preparado.» → «No sabes si estás preparad{o/a}.»
- PASO 15 (línea 845) · Narrador: «Estás más tranquilo.» → «Estás más tranquil{o/a}.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo: «Al día siguiente…»: La ciudad despierta. Niños entrando al colegio, bicicletas, padres despidiéndose y la campana sonando a lo lejos.
- PASO 2 · Objetivo: «Ve a clase»: Caminas por el pasillo entre otros alumnos.
- PASO 4 · Objetivo: «Ve a la biblioteca a por los apuntes»: Entras en la biblioteca.
- PASO 5 · Objetivo: «Pregunta a Marisa»: 
- PASO 6 · Objetivo: «Coge los apuntes de la mesa»: Te acercas a la mesa.
- PASO 7 · Objetivo: «¿Con quién estudias?»: 
- PASO 8 · Objetivo: «Estudia en la biblioteca»: Aquí comienza un pequeño minijuego de estudio.
- PASO 10 · Objetivo: «Esa noche, en casa…»: 
- PASO 12 · Objetivo: «Repasa un poco más»: 
- PASO 13 · Objetivo: «El día del examen…»: 
- PASO 14 · Objetivo: «Ve a clase: hoy es el examen»: 
- PASO 16 · Objetivo: «El examen de Matemáticas»: Comienza el examen.
- PASO 19 · Objetivo: «Devuelve los apuntes a Marisa»: 
- PASO 20 · Objetivo: «Devuélvele los apuntes»: 
- PASO 20 · MOMENTO DE BIOGRAFÍA: «Tu primer examen de verdad»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
