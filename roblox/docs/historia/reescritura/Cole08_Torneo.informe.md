# Informe de la reescritura · Cole08_Torneo

Guion: `docs/historia/reescritura/Cole08_Torneo.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole08_Torneo`.
Datos: `src/shared/LifeStory/Guiones/Cole08_Torneo.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Los minijuegos de cada deporte (Futbol / Timing / circuito de la pista) se juegan igual. El grito del grupo: de las cuatro variantes escritas solo sale la del nombre que elegiste en Cole03 (Choices.NombreGrupo). «¡Ese es mi [tu nombre]!» pasa a «¡Esa es mi estrella!» (neutro). hugo_con_el_grupo = Flags.HugoConElGrupo; bruno_hablaste_con_el = Choices.Malotes == Hablar; ganaste/perdiste = Flags.TorneoGanado / TorneoPerdido. La marca nueva Flags.PuertaPasilloVista queda guardada para Cole09.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar | 1 · Transition |
| 2 | Ir a | Pista de deporte | 2 · Reach @ Pista |
| 3 | Cinematic | Pista de deporte | 3 · Scene «Presentacion» |
| 4 | Choice | Pista de deporte | 4 · Choice |
| 5 | Ir a | Zona de entrenamiento | 5 · Reach @ CampoColegio |
| 6 | Cinematic | Campo de fútbol | 6 · Scene «Entreno_Futbol» |
| 7 | Gameplay | Campo de fútbol | 7 · MiniGame |
| 8 | Ir a | Cancha de baloncesto | 8 · Reach @ CanchaColegio |
| 9 | Cinematic | Cancha de baloncesto | 9 · Scene «Entreno_Baloncesto» |
| 10 | Gameplay | Cancha de baloncesto | 10 · MiniGame |
| 11 | Cinematic | Pista de atletismo | 11 · Scene «Entreno_Atletismo» |
| 12 | Gameplay | Pista de atletismo | 12 · Class @ Pista |
| 13 | Cinematic | Zona de entrenamiento | 13 · Scene «Charla» |
| 14 | Scene | Cancha de baloncesto | 14 · Scene «Charla» |
| 15 | Scene | Pista de atletismo | 15 · Scene «Charla» |
| 16 | Transition | Colegio | 16 · Transition |
| 17 | Cinematic | Zona de competición | 17 · Scene «Clasificacion» |
| 18 | Gameplay | Campo de fútbol | 18 · MiniGame |
| 19 | Cinematic | Cancha de baloncesto | 19 · Scene «Clasificacion» |
| 20 | Gameplay | Cancha de baloncesto | 20 · MiniGame |
| 21 | Cinematic | Pista de atletismo | 21 · Scene «Clasificacion» |
| 22 | Gameplay | Pista | 22 · MiniGame |
| 23 | Cinematic | Pista de deporte | 23 · Scene «TrasClasificacion» |
| 24 | Ir a | Grada de la pista | 24 · Reach @ Pista |
| 25 | Varios objetivos | Grada / pista | 25 · Group |
| 25.1 | Hablar | — Mamá/Papá | 25.1 · Talk «Grada_Familia» |
| 25.2 | Hablar | — Abu | 25.2 · Talk «Grada_Abu» |
| 25.3 | Usar | — Fuente | 25.3 · Use (Botella) |
| 26 | Choice | Grada | 26 · Talk «Bruno_PreFinal» |
| 27 | Cinematic | Zona de la final | 27 · Cinematic «Cole08_Final» |
| 28 | Gameplay | Campo de fútbol | 28 · MiniGame |
| 29 | Cinematic | Cancha de baloncesto | 29 · Cinematic «Cole08_Final» |
| 30 | Gameplay | Cancha de baloncesto | 30 · MiniGame |
| 31 | Cinematic | Pista | 31 · Cinematic «Cole08_Final» |
| 32 | Gameplay | Pista | 32 · MiniGame |
| 33 | Cinematic | Zona de competición | 33 · Scene «Resultado» |
| 34 | Scene | Cancha de baloncesto | 34 · Scene «Resultado» |
| 35 | Scene | Pista de atletismo | 35 · Scene «Resultado» |
| 36 | Ir a | Pista de deporte | 36 · Reach @ Pista |
| 37 | Cinematic | Pista de deporte | 37 · Cinematic «Cole08_Medallas» |
| 38 | Scene | Pasillo del colegio | 38 · Scene «Rumor» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 2 frases al cumplirlo (escena ligera «Cole08_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): 4 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole08_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Presentacion»): conversación «Presentacion» con 17 frases nuevas (música Intima)
- PASO 4 → paso 4 del juego (Choice): 17 frases al empezar el paso (escena ligera «Cole08_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Reach): objetivo «llegar al área correspondiente.»
- PASO 6 → paso 6 del juego (Scene «Entreno_Futbol»): conversación «Entreno_Futbol» con 9 frases nuevas (música Tension)
- PASO 7 → paso 7 del juego (MiniGame): 5 frases al empezar el paso (escena ligera «Cole08_G7_Entra», la lanza el paso 6 al cumplirse; el jugador no pierde el control)
- PASO 8 → paso 8 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole08_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Scene «Entreno_Baloncesto»): conversación «Entreno_Baloncesto» con 8 frases nuevas (música Tension)
- PASO 10 → paso 10 del juego (MiniGame): 3 frases al empezar el paso (escena ligera «Cole08_G10_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)
- PASO 11 → paso 11 del juego (Scene «Entreno_Atletismo»): conversación «Entreno_Atletismo» con 10 frases nuevas (música Tension)
- PASO 12 → paso 12 del juego (Class): 2 frases al empezar el paso (escena ligera «Cole08_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13+14+15 → paso 13 del juego (Scene «Charla»): conversación «Charla» con 46 frases nuevas (música Intima)
- PASO 16 → paso 16 del juego (Transition): 2 frases al cumplirlo (escena ligera «Cole08_G16_Fin», sin quitar el control)
- PASO 17+19+21 → paso 17 del juego (Scene «Clasificacion»): conversación «Clasificacion» con 16 frases nuevas (música Tension)
- PASO 23 → paso 23 del juego (Scene «TrasClasificacion»): conversación «TrasClasificacion» con 12 frases nuevas (música Intima→Tension)
- PASO 25.1 → paso 25.1 del juego (Talk «Grada_Familia»): conversación «Grada_Familia» con 14 frases nuevas
- PASO 25.2 → paso 25.2 del juego (Talk «Grada_Abu»): conversación «Grada_Abu» con 7 frases nuevas
- PASO 25.3 → paso 25.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Beber» (1 frases)
- PASO 26 → paso 26 del juego (Talk «Bruno_PreFinal»): conversación «Bruno_PreFinal» con 27 frases nuevas (música Tension)
- PASO 27+29+31 → paso 27 del juego (Cinematic «Cole08_Final»): la escena «Cole08_Final» se cuenta con el guion nuevo (misma escena, 13 planos, 48 frases, 145.4 s, música Tema→Tension→Tema→Tension→Tema→Tension)
- PASO 33+34+35 → paso 33 del juego (Scene «Resultado»): conversación «Resultado» con 38 frases nuevas (música Intima)
- PASO 37 → paso 37 del juego (Cinematic «Cole08_Medallas»): la escena «Cole08_Medallas» se cuenta con el guion nuevo (misma escena, 6 planos, 32 frases, 86.1 s, música Intima)
- PASO 38 → paso 38 del juego (Scene «Rumor»): conversación «Rumor» con 13 frases nuevas (música Descubrimiento→Tension)
- Momento de la biografía: «🏆 «Tu primer torneo»»

## Adaptado (y por qué)

- PASO 14: el paso 14 del juego usa la misma conversación «Charla» que el paso 13: sus frases van en ella (con su condición: deporte = Baloncesto)
- PASO 15: el paso 15 del juego usa la misma conversación «Charla» que el paso 13: sus frases van en ella (con su condición: deporte = Atletismo)
- PASO 19: el paso 19 del juego usa la misma conversación «Clasificacion» que el paso 17: sus frases van en ella (con su condición: deporte = Baloncesto)
- PASO 21: el paso 21 del juego usa la misma conversación «Clasificacion» que el paso 17: sus frases van en ella (con su condición: deporte = Atletismo)
- PASO 29: el paso 29 del juego usa la misma conversación «Cole08_Final» que el paso 27: sus frases van en ella (con su condición: deporte = Baloncesto)
- PASO 31: el paso 31 del juego usa la misma conversación «Cole08_Final» que el paso 27: sus frases van en ella (con su condición: deporte = Atletismo)
- PASO 34: el paso 34 del juego usa la misma conversación «Resultado» que el paso 33: sus frases van en ella (con su condición: deporte = Baloncesto)
- PASO 35: el paso 35 del juego usa la misma conversación «Resultado» que el paso 33: sus frases van en ella (con su condición: deporte = Atletismo)
- PASO 1: 4 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 2 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 3: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 8: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 9: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 13: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 16: 5 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 17: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 19: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 21: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 18 → paso 18 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 20 → paso 20 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 22 → paso 22 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 23: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 24 → paso 24 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 24: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 25 → paso 25 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 25.3: 1 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 26: el guion lo escribe como [Choice] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 27+29+31: el plano Inserto de «Zapatillas» no se encuentra en la escena: plano General del lugar
- PASO 27+29+31: el plano Inserto de «Testigo» no se encuentra en la escena: plano General del lugar
- PASO 28 → paso 28 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 30 → paso 30 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 32 → paso 32 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 33: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 36 → paso 36 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 37: el plano Inserto de «Medallas» no se encuentra en la escena: plano General del lugar
- PASO 37: el plano Inserto de «Medalla» no se encuentra en la escena: plano General del lugar

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 27+29+31: la cinemática nueva dura 145 s (se puede saltar, pero es larga: el guion trae 13 planos)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 5 · Objetivo: llegar al área correspondiente.: 
- PASO 7 · Minijuego:: La aguja se desplaza.
- PASO 10 · Minijuego:: El jugador debe soltar cuando la aguja esté en verde.
- PASO 12 · Minijuego:: El jugador debe:
- PASO 22 · Minijuego:: El jugador debe iniciar el relevo cuando la aguja esté en verde.
- PASO 38 · MOMENTO DE BIOGRAFÍA: 🏆 «Tu primer torneo»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
