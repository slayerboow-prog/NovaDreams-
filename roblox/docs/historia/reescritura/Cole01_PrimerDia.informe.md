# Informe de la reescritura · Cole01_PrimerDia

Guion: `docs/historia/reescritura/Cole01_PrimerDia.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole01_PrimerDia`.
Datos: `src/shared/LifeStory/Guiones/Cole01_PrimerDia.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Variables del guion → marcas que ya guarda Cole01: ropa = Choices.Ropa, asiento = Choices.Asiento, grupo_recreo = Choices.GrupoRecreo (los «Curiosos» del guion son la opción Estudiantes del juego), gusto = Choices.Gusto, acompañante = Choices.Acompanante, ayudaste_a_mateo = Flags.AyudasteAMateo (IgnorasteAMateo si no), lleva_cromo = Flags.LlevaCromo, pase_a_dani = Flags.PaseADani (FallastePase si fallas), llegó tarde = Flags.LlegasTarde, sabe_del_almacen = Flags.SabeDelAlmacen (hablar con Ramón en el gimnasio), apuesta_alex = Flags.ApuestaAlex, ensayo_espejo = Flags.EnsayoEspejo. Cole02 y siguientes las leen con esos mismos nombres.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Cinematic | Habitación | 1 · Scene «Despertar» |
| 2 | Scene | Casa | 2 · Group |
| 2.1 | Action | Dormitorio | 2.1 · Use (Armario) |
| 2.2 | Action | Dormitorio | 2.2 · Use (Mochila) |
| 2.3 | Action | Cocina | 2.3 · Use (Desayuno) |
| 3 | Talk | Cocina | 3 · Talk «Salida» |
| 4 | Action | Camino al colegio | 4 · Reach @ CaminoAlCole |
| 5 | Scene | Camino al colegio | 5 · Scene «DaniBalon» |
| 6 | Action | Camino al colegio | 6 · MiniGame |
| 7 | Scene | Camino al colegio | 7 · Scene «DaniGracias» |
| 8 | Action | Entrada de Los Pinos | 8 · Reach @ EntradaColegio |
| 9 | Cinematic | Entrada de Los Pinos | 9 · Scene «Entrada» |
| 10 | Talk | Pasillo | 10 · Talk «ConoceLucia» |
| 11 | Action | Colegio | 11 · Group |
| 11.6 | Talk | Biblioteca | 11.6 · Talk «Info_Iker» |
| 11.7 | Talk | Comedor | 11.7 · Talk «Info_Vega» |
| 11.8 | Talk | Gimnasio | 11.8 · Talk «Info_Ramon» |
| 12 | Action | Edificio principal | 12 · Reach @ AulaA |
| 13 | Cinematic | Aula 1.º A | 13 · Cinematic «Cole01_Bienvenida» |
| 14 | Choice | Aula 1.º A | 14 · Choice |
| 15 | Scene | Aula 1.º A | 15 · Scene «Presentaciones» |
| 16 | Scene | Aula 1.º A | 16 · Scene «Presentaciones» |
| 17 | Scene | Aula 1.º A | 17 · Scene «Presentaciones» |
| 18 | Action | Aula 1.º A | 18 · Class @ AulaA |
| 19 | Transition | Aula 1.º A | 19 · Scene «Timbre» |
| 20 | Action | Patio | 20 · Reach @ Patio |
| 21 | Choice | Patio | 21 · Choice |
| 22 | Cinematic | Patio | 22 · Cinematic «Cole01_LibrosCaen» |
| 23 | Action | Patio | 23 · Group |
| 23.1 | Action | Patio | 23.1 · Use (Libro1) |
| 23.2 | Action | Patio | 23.2 · Use (Libro2) |
| 23.3 | Action | Patio | 23.3 · Use (Libro3) |
| 23.4 | Action | Patio | 23.4 · Use (Libro4) |
| 24 | Talk | Patio | 24 · Scene «MateoGracias» |
| 25 | Scene | Patio | 25 · Scene «MateoSolo» |
| 26 | Transition | Colegio | 26 · Scene «FinDeClases» |
| 27 | Action | Camino a casa | 27 · Reach @ CasaFamiliar |
| 28 | Cinematic | Cocina | 28 · Scene «Cena» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Scene «Despertar»): conversación «Despertar» con 16 frases nuevas (música Descubrimiento)
- PASO 2 → paso 2 del juego (Group): 12 frases al empezar el paso (escena ligera «Cole01_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 2.1 → paso 2.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Armario» (7 frases)
- PASO 2.2 → paso 2.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Mochila» (9 frases)
- PASO 2.3 → paso 2.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Desayuno» (10 frases)
- PASO 3 → paso 3 del juego (Talk «Salida»): conversación «Salida» con 25 frases nuevas (música Intima)
- PASO 4 → paso 4 del juego (Reach): 6 frases al empezar el paso (escena ligera «Cole01_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «DaniBalon»): conversación «DaniBalon» con 9 frases nuevas (música Descubrimiento)
- PASO 6 → paso 6 del juego (MiniGame): objetivo «Pásale el balón a Dani.»
- PASO 7 → paso 7 del juego (Scene «DaniGracias»): conversación «DaniGracias» con 19 frases nuevas (música Descubrimiento)
- PASO 8 → paso 8 del juego (Reach): 4 frases al empezar el paso (escena ligera «Cole01_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Scene «Entrada»): conversación «Entrada» con 25 frases nuevas (música Intima)
- PASO 10 → paso 10 del juego (Talk «ConoceLucia»): conversación «ConoceLucia» con 43 frases nuevas (música Descubrimiento)
- PASO 11 → paso 11 del juego (Group): objetivo «Conoce el colegio.»
- PASO 11.6 → paso 11.6 del juego (Talk «Info_Iker»): conversación «Info_Iker» con 12 frases nuevas
- PASO 11.7 → paso 11.7 del juego (Talk «Info_Vega»): conversación «Info_Vega» con 6 frases nuevas
- PASO 11.8 → paso 11.8 del juego (Talk «Info_Ramon»): conversación «Info_Ramon» con 11 frases nuevas
- PASO 12 → paso 12 del juego (Reach): objetivo «Encuentra el aula 1.º A.»
- PASO 12 → paso 12 del juego (Reach): 1 frases al empezar el paso (escena ligera «Cole01_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13 → paso 13 del juego (Cinematic «Cole01_Bienvenida»): la escena «Cole01_Bienvenida» se cuenta con el guion nuevo (misma escena, 11 planos, 22 frases, 59.1 s, música Descubrimiento)
- PASO 15+16+17 → paso 15 del juego (Scene «Presentaciones»): conversación «Presentaciones» con 39 frases nuevas (música Descubrimiento)
- PASO 18 → paso 18 del juego (Class): objetivo «Completa tu primera clase de Matemáticas.»
- PASO 18 → paso 18 del juego (Class): 4 frases al empezar el paso (escena ligera «Cole01_G18_Entra», la lanza el paso 17 al cumplirse; el jugador no pierde el control)
- PASO 19 → paso 19 del juego (Scene «Timbre»): conversación «Timbre» con 5 frases nuevas (música Descubrimiento)
- PASO 20 → paso 20 del juego (Reach): objetivo «Sal al patio.»
- PASO 20 → paso 20 del juego (Reach): 8 frases al empezar el paso (escena ligera «Cole01_G20_Entra», la lanza el paso 19 al cumplirse; el jugador no pierde el control)
- PASO 21 → paso 21 del juego (Choice): «OPCIÓN A — LOS DEPORTISTAS» es la conversación de la opción Deportistas («Grupo_Deportistas», 11 frases)
- PASO 21 → paso 21 del juego (Choice): «OPCIÓN B — LOS ARTISTAS» es la conversación de la opción Artistas («Grupo_Artistas», 11 frases)
- PASO 21 → paso 21 del juego (Choice): «OPCIÓN C — LOS CURIOSOS» es la conversación de la opción Estudiantes («Grupo_Estudiantes», 9 frases)
- PASO 21 → paso 21 del juego (Choice): objetivo «Decide con quién pasar tu primer recreo.»
- PASO 22 → paso 22 del juego (Cinematic «Cole01_LibrosCaen»): la escena «Cole01_LibrosCaen» se cuenta con el guion nuevo (misma escena, 11 planos, 13 frases, 45.9 s, música Tension)
- PASO 23 → paso 23 del juego (Group): objetivo «Ayuda a Mateo a recoger sus cosas.»
- PASO 24 → paso 24 del juego (Scene «MateoGracias»): conversación «MateoGracias» con 24 frases nuevas (música Intima)
- PASO 25 → paso 25 del juego (Scene «MateoSolo»): conversación «MateoSolo» con 4 frases nuevas (música Tension)
- PASO 26 → paso 26 del juego (Scene «FinDeClases»): conversación «FinDeClases» con 8 frases nuevas (música Descubrimiento)
- PASO 27 → paso 27 del juego (Reach): objetivo «Vuelve a casa.»
- PASO 27 → paso 27 del juego (Reach): 4 frases al empezar el paso (escena ligera «Cole01_G27_Entra», la lanza el paso 26 al cumplirse; el jugador no pierde el control)
- PASO 28 → paso 28 del juego (Scene «Cena»): conversación «Cena» con 46 frases nuevas (música Intima)

## Adaptado (y por qué)

- PASO 16: el paso 16 del juego usa la misma conversación «Presentaciones» que el paso 15: sus frases van en ella (con su condición: asiento = Nico)
- PASO 17: el paso 17 del juego usa la misma conversación «Presentaciones» que el paso 15: sus frases van en ella (con su condición: asiento = Mateo)
- PASO 1 · opción A: sin equivalente: «Mamá/Papá recuerda que al protagonista le cuesta levantarse.»
- PASO 1: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 2: la elección tiene 3 opciones y solo 2 grupos de respuesta detrás: las demás ramas siguen sin respuesta propia
- PASO 2: el guion lo escribe como [Scene] y en el juego es paso jugable (Group): se conserva el tipo del juego y su mecánica
- PASO 2: ELECCION en un paso jugable del juego (Group): no hay conversación donde preguntarla; sus respuestas se dicen como frases
- PASO 2: 4 PLANO de un paso jugable (Group) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2.1: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2.2 · opción A: sin equivalente: «Objeto: Cromo de la suerte.»
- PASO 2.2: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2.3: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 4: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6: 1 PLANO de un paso jugable (MiniGame) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 8: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 9: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 12: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 14: la elección tiene 3 opciones y solo 0 grupos de respuesta detrás: las demás ramas siguen sin respuesta propia
- PASO 14: la ELECCION del guion se toma en el mundo (paso Choice «Asiento»): se conservan las opciones del juego y sus efectos
- PASO 18: 6 PLANO de un paso jugable (Class) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 19: el guion lo escribe como [Transition] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 20: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 22: el plano Inserto de «Libros» no se encuentra en la escena: plano General del lugar
- PASO 22: el plano Inserto de «Álbum de cromos» no se encuentra en la escena: plano General del lugar
- PASO 23.1 → paso 23.1 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23.2 → paso 23.2 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23.3 → paso 23.3 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23.4 → paso 23.4 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23.4: 2 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 26: el guion lo escribe como [Transition] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 27: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 28: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 2 (línea 111) · Familia: «¿La has hecho tú solo?» → «¿La has hecho tú sol{o/a}?»
- PASO 9 (línea 545) · Ramon: «Tranquilo.» → «Tranquil{o/a}.»
- PASO 10 (línea 643) · Lucia: «Encuentra tu aula tú solo.» → «Encuentra tu aula tú sol{o/a}.»
- PASO 28 (línea 1779) · Narrador: «Un día parece pequeño cuando lo estás viviendo.» → «Un día parece pequeñ{o/a} cuando lo estás viviendo.»

## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVOS:: * Hacer la cama. / * Mirarte en el espejo. / * Elegir ropa. / * Preparar mochila. / * Desayunar.
- PASO 6 · OBJETIVO: Pásale el balón a Dani.: Aparece el indicador del minijuego.
- PASO 6 · MINIJUEGO:: La aguja se mueve.
- PASO 10 · CHARLA OPCIONAL — Andrés: 
- PASO 10 · CHARLA OPCIONAL — Marta: 
- PASO 11 · OBJETIVO: Conoce el colegio.: Los cinco objetivos pueden completarse en cualquier orden:
- PASO 12 · OBJETIVO: Encuentra el aula 1.º A.: El jugador recorre el edificio.
- PASO 18 · OBJETIVO: Completa tu primera clase de Matemáticas.: La clase avanza.
- PASO 19 · SFX: RIIIIING.: Se levanta inmediatamente.
- PASO 20 · OBJETIVO: Sal al patio.: Los grupos se forman de manera natural.
- PASO 20 · Comentarios al pasar:: Bruno: ¿Y tú qué miras?
- PASO 20 · CHARLA OPCIONAL — Álex: Álex: Soy la portera.
- PASO 20 · CHARLA OPCIONAL — Vega: Vega: Omar está dibujando una nube con forma de bocadillo.
- PASO 20 · CHARLA OPCIONAL — Iker: Iker: ¿Sabías que el recreo se inventó para que los cerebros descansen?
- PASO 21 · OBJETIVO: Decide con quién pasar tu primer recreo.: 
- PASO 21 · OPCIÓN A — LOS DEPORTISTAS: Nico: ¡Has venido! / Nico: Esta es Álex. / Nico: Es portera. / Nico: Nadie le mete gol. / Álex: Nadie. / Nico: Bueno… / Nico: Yo a veces. / Álex: Nunca. / Nico: Tú dijiste que te gusta el fútbol. / Nico: Mañana juegas con nosotros. / 
- PASO 21 · OPCIÓN B — LOS ARTISTAS: Omar: Espera. / Omar: No te muevas. / Omar: Te estoy dibujando. / Vega: Omar dibuja a todo el mundo. / Vega: Es su forma de decir hola. / Aparece el dibujo del protagonista. / Omar: Ya está. / Omar: Te he puesto una capa. / Omar: Quedas mejor con capa. / Omar: ¿Tú también dibujas? / Omar: Mañana te dejo mi rotulador dorado. / 
- PASO 21 · OPCIÓN C — LOS CURIOSOS: Sara: Estamos discutiendo una cosa importantísima. /  / Sara: ¿Las hormigas duermen? / Iker: Sí. / Iker: Doscientas cincuenta siestas de un minuto al día. / Sara: Eso hay que comprobarlo. /  / Sara: Experimentalmente. / Sara: Tú dijiste que te gustan los experimentos. / Sara: Estás dentro. / 
- PASO 23 · OBJETIVO: Ayuda a Mateo a recoger sus cosas.: Los objetos pueden recogerse en cualquier orden:
- PASO 25 · FLAG:: mateo_recuerda_que_no_ayudaste = true
- PASO 27 · OBJETIVO: Vuelve a casa.: El protagonista camina hacia casa.
- PASO 28 · SISTEMA DE MEMORIA AL TERMINAR: Registrar:
- PASO 28 · CONSECUENCIAS FUTURAS: Las decisiones de esta misión NO deben quedarse únicamente en estadísticas.
- PASO 28 · MOMENTO DE BIOGRAFÍA: «Tu primer día de colegio»
- PASO 28 · CIERRE DEL CAPÍTULO: EL COLEGIO

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
