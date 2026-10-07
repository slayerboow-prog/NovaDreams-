# Informe de la reescritura · Cole04_Malotes

Guion: `docs/historia/reescritura/Cole04_Malotes.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole04_Malotes`.
Datos: `src/shared/LifeStory/Guiones/Cole04_Malotes.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

El objeto robado es el mismo del inventario: el cromo (Flags.ObjetoCromo, que el juego pone al quitarte el CromoSuerte de Cole01) o, si no lo llevabas, la foto del grupo de Cole03; las frases del guion «si objeto = cromo/fotografía» miran esa marca y el juego lo devuelve con sus Effects de siempre (no se duplica). sabe_libro_hugo = Flags.SabeLibroHugo de Cole02. La marca PistaHugo (lo que te cuenta Mateo) se sigue guardando, pero el guion nuevo no la lee. La persecución de Hugo (Chase, con el atajo del aula de música) y esconderse de Ramón (Use Escondite) se juegan igual. «Si el jugador tarda» en alcanzar a Hugo: la persecución no guarda ese dato, así que esas frases solo saldrían con una marca que hoy no pone nadie (pendiente: que el paso Chase marque si se tardó).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition | Valmar | 1 · Transition |
| 2 | Action | Patio | 2 · Reach @ Patio |
| 3 | Scene | Banco junto al edificio | 3 · Scene «Burlas» |
| 4 | Action | Aula de 1.º A | 4 · Reach @ AulaA |
| 5 | Scene | Aula de 1.º A | 5 · Scene «SinCromo» |
| 6 | Scene | Aula de 1.º A | 6 · Scene «SinFoto» |
| 7 | Action | Colegio | 7 · Group |
| 7.1 |  |  | 7.1 · Talk «Pista_Mateo» |
| 7.2 |  |  | 7.2 · Talk «Pista_Nico» |
| 7.3 |  |  | 7.3 · Talk «Pista_Sara» |
| 7.4 |  |  | 7.4 · Talk «Pista_Omar» |
| 7.5 |  |  | 7.5 · Talk «Pista_Lucia» |
| 7.6 |  |  | 7.6 · Talk «Pista_Ramon» |
| 8 | Action | Pasillo | 8 · Reach @ PasilloColegio |
| 9 | Cinematic | Pasillo | 9 · Cinematic «Cole04_LosVes» |
| 10 | Action | Patio | 10 · Reach @ Patio |
| 11 | Scene | Pasillo | 11 · Scene «RamonAparece» |
| 12 | Action | Detrás de las cajas | 12 · Use (Escondite) |
| 13 | Scene | Pasillo | 13 · Scene «Pillado» |
| 14 | Action | Camino al gimnasio | 14 · Chase |
| 15 | Cinematic | Almacén del gimnasio | 15 · Scene «Hugo» |
| 16 | Scene | Almacén del gimnasio | 16 · Scene «Devuelve» |
| 17 | Scene | Almacén del gimnasio | 17 · Scene «Devuelve» |
| 18 | Choice | Almacén del gimnasio | 18 · Scene «Decision» |
| 19 | Talk | Aula de 1.º A | 19 · Talk «Rama_Lucia» |
| 20 | Talk | Puerta del colegio | 20 · Talk «Rama_Hablar» |
| 21 | Action | Banco junto al edificio | 21 · Reach @ SpotGrupoEstudiantes |
| 22 | Talk | Puerta del colegio | 22 · Talk «Rama_Grupo» |
| 23 | Scene | Almacén del gimnasio | 23 · Scene «Rama_Ignorar» |
| 24 | Cinematic | Patio | 24 · Scene «Cierre» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 3 frases al cumplirlo (escena ligera «Cole04_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Es la hora del recreo: busca a tu grupo»
- PASO 2 → paso 2 del juego (Reach): 5 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole04_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Burlas»): conversación «Burlas» con 34 frases nuevas (música Tension)
- PASO 4 → paso 4 del juego (Reach): objetivo «Vuelve a clase»
- PASO 4 → paso 4 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole04_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Scene «SinCromo»): conversación «SinCromo» con 7 frases nuevas (música Tension)
- PASO 6 → paso 6 del juego (Scene «SinFoto»): conversación «SinFoto» con 5 frases nuevas (música Tension)
- PASO 7 → paso 7 del juego (Group): objetivo «Averigua qué ha pasado»
- PASO 7.1 → paso 7.1 del juego (Talk «Pista_Mateo»): conversación «Pista_Mateo» con 9 frases nuevas
- PASO 7.2 → paso 7.2 del juego (Talk «Pista_Nico»): conversación «Pista_Nico» con 11 frases nuevas
- PASO 7.3: efectos del guion sumados a la conversación «Pista_Sara»: pista_hugo = true
- PASO 7.3 → paso 7.3 del juego (Talk «Pista_Sara»): conversación «Pista_Sara» con 8 frases nuevas
- PASO 7.4 → paso 7.4 del juego (Talk «Pista_Omar»): conversación «Pista_Omar» con 9 frases nuevas
- PASO 7.5 → paso 7.5 del juego (Talk «Pista_Lucia»): conversación «Pista_Lucia» con 11 frases nuevas
- PASO 7.6 → paso 7.6 del juego (Talk «Pista_Ramon»): conversación «Pista_Ramon» con 9 frases nuevas
- PASO 8 → paso 8 del juego (Reach): objetivo «Ve al pasillo»
- PASO 8 → paso 8 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole04_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Cinematic «Cole04_LosVes»): la escena «Cole04_LosVes» se cuenta con el guion nuevo (misma escena, 11 planos, 21 frases, 53.7 s, música Tension)
- PASO 10 → paso 10 del juego (Reach): objetivo «¡Síguelos! Corre hacia el patio»
- PASO 10 → paso 10 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole04_G10_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)
- PASO 11 → paso 11 del juego (Scene «RamonAparece»): conversación «RamonAparece» con 4 frases nuevas (música Tension)
- PASO 12 → paso 12 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Escondido» (5 frases)
- PASO 12 → paso 12 del juego (Use): objetivo «¡Escóndete detrás de las cajas!»
- PASO 13 → paso 13 del juego (Scene «Pillado»): conversación «Pillado» con 13 frases nuevas (música Tension)
- PASO 14 → paso 14 del juego (Chase): objetivo «¡Alcanza a Hugo!»
- PASO 14 → paso 14 del juego (Chase): 1 frases al empezar el paso (escena ligera «Cole04_G14_Entra», la lanza el paso 13 al cumplirse; el jugador no pierde el control)
- PASO 15 → paso 15 del juego (Scene «Hugo»): conversación «Hugo» con 28 frases nuevas (música Intima)
- PASO 16+17 → paso 16 del juego (Scene «Devuelve»): conversación «Devuelve» con 13 frases nuevas (música Intima)
- PASO 18 → paso 18 del juego (Scene «Decision»): conversación «Decision» con 18 frases nuevas (música Tension)
- PASO 19 → paso 19 del juego (Talk «Rama_Lucia»): conversación «Rama_Lucia» con 16 frases nuevas (música Intima)
- PASO 20 → paso 20 del juego (Talk «Rama_Hablar»): conversación «Rama_Hablar» con 27 frases nuevas (música Intima)
- PASO 21 → paso 21 del juego (Reach): objetivo «Ve a buscar a tu grupo»
- PASO 21 → paso 21 del juego (Reach): 10 frases al empezar el paso (escena ligera «Cole04_G21_Entra», la lanza el paso 20 al cumplirse; el jugador no pierde el control)
- PASO 22 → paso 22 del juego (Talk «Rama_Grupo»): conversación «Rama_Grupo» con 19 frases nuevas (música Tension)
- PASO 23 → paso 23 del juego (Scene «Rama_Ignorar»): conversación «Rama_Ignorar» con 6 frases nuevas (música Intima)
- PASO 24 → paso 24 del juego (Scene «Cierre»): conversación «Cierre» con 14 frases nuevas (música Intima)
- Momento de la biografía: «Recuperaste lo que era tuyo… y conociste de verdad a Hugo.»

## Adaptado (y por qué)

- PASO 17: el paso 17 del juego usa la misma conversación «Devuelve» que el paso 16: sus frases van en ella (con su condición: lleva_cromo = false)
- PASO 1: 4 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 2: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 4: 2 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 7.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.2: «pista_pasillo = true» no la lee ninguna misión: no se crea
- PASO 7.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.4: «pista_dibujo = true» no la lee ninguna misión: no se crea
- PASO 7.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 7.6: «pista_gimnasio = true» no la lee ninguna misión: no se crea
- PASO 8: 1 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 9: el plano Inserto de «Cromo» no se encuentra en la escena: plano General del lugar
- PASO 9: el plano Inserto de «Fotografía» no se encuentra en la escena: plano General del lugar
- PASO 10: 4 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 12: 4 PLANO de un paso jugable (Use) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 14: 2 PLANO de un paso jugable (Chase) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 15: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 18: el guion lo escribe como [Choice] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 21: 3 PLANO de un paso jugable (Reach) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 24: el guion lo escribe como [Cinematic] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 24: «Condición: malotes != Ignorar» — el paso del juego no tiene condición: el paso sigue saliendo siempre (su mecánica no cambia) y la condición se pone en sus frases

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 2 · OBJETIVO: «Es la hora del recreo: busca a tu grupo»: Los niños juegan, corren y hablan.
- PASO 3 · SFX: PASOS.: Los tres aparecen al fondo.
- PASO 4 · OBJETIVO: «Vuelve a clase»: Entra en el aula.
- PASO 7 · OBJETIVO: «Averigua qué ha pasado»: El protagonista comienza a investigar.
- PASO 8 · OBJETIVO: «Ve al pasillo»: Avanza lentamente por el pasillo.
- PASO 8 · SFX: VOCES LEJANAS.: Escucha.
- PASO 9 · OBJETIVO:: 
- PASO 10 · OBJETIVO: «¡Síguelos! Corre hacia el patio»: Corre detrás de ellos.
- PASO 10 · SFX: PASOS.: Bruno dobla una esquina.
- PASO 10 · SFX: NOTA DE PIANO.: 
- PASO 11 · SFX: PASOS.: Ramón: ¡¿QUIÉN ESTÁ CORRIENDO POR MI PATIO?!
- PASO 12 · OBJETIVO: «¡Escóndete detrás de las cajas!»: Se agacha.
- PASO 14 · OBJETIVO: «¡Alcanza a Hugo!»: Avanza hacia el gimnasio.
- PASO 19 · OBJETIVO: «Cuéntaselo a Lucía»: Lucía está ordenando materiales.
- PASO 20 · OBJETIVO: «Habla con Bruno»: Bruno espera junto a Rubén.
- PASO 21 · OBJETIVO: «Ve a buscar a tu grupo»: Corre hacia el banco.
- PASO 24 · SISTEMA DE MEMORIA: Guardar obligatoriamente:
- PASO 24 · CONSECUENCIAS FUTURAS: Hugo recordará que el protagonista tuvo el valor de acudir a un adulto.
- PASO 24 · MOMENTO DE BIOGRAFÍA: «Recuperaste lo que era tuyo… y conociste de verdad a Hugo.»

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
