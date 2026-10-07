# Informe de la reescritura · Cole10_Festival

Guion: `docs/historia/reescritura/Cole10_Festival.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole10_Festival`.
Datos: `src/shared/LifeStory/Guiones/Cole10_Festival.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Se conservan las 5 tareas (Decoración/Música/Comida/Fotos/Teatro) con sus minijuegos, los imprevistos (farolillos, altavoz, la niña perdida, el puesto de Bruno) y los talentos. Marcas para el montaje del instituto: Choices.FestivalBruno (Ayudar = cole10_bruno_ayudado), Flags.SubesAlEscenario, Flags.AplausoFinal, Flags.TareaBrillante; «Hugo actuó» es Flags.HugoConElGrupo (si está en el grupo actúa con vosotros). La foto del festival es la cinemática final y el recuerdo de la misión: no hay álbum de fotos aparte. Lo que el guion pide de dirección (NPC con rutinas por el festival, luz de atardecer, ambiente sonoro) no se añade: el festival no tiene un decorado propio donde ponerlo barato (pendiente); la música y el ambiente de cada paso son los de las escenas.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ AulaA |
| 3 |  |  | 3 · Scene «Anuncio» |
| 4 |  |  | 4 · Choice |
| 5 |  |  | 5 · Reach @ Patio |
| 6 |  |  | 6 · Group |
| 6.1 |  |  | 6.1 · Use (Guirnalda1) |
| 6.2 |  |  | 6.2 · Use (Guirnalda2) |
| 6.3 |  |  | 6.3 · Use (Cartel) |
| 7 |  |  | 7 · Reach @ AulaMusica |
| 8 |  |  | 8 · Scene «Ensayo_Musica» |
| 9 |  |  | 9 · MiniGame |
| 10 |  |  | 10 · Reach @ ComedorColegio |
| 11 |  |  | 11 · Group |
| 11.1 |  |  | 11.1 · Use (Harina) |
| 11.2 |  |  | 11.2 · Use (Huevos) |
| 12 |  |  | 12 · MiniGame |
| 13 |  |  | 13 · Group |
| 13.1 |  |  | 13.1 · Use (Foto1) |
| 13.2 |  |  | 13.2 · Use (Foto2) |
| 13.3 |  |  | 13.3 · Use (Foto3) |
| 14 |  |  | 14 · Reach @ GimnasioColegio |
| 15 |  |  | 15 · Scene «Ensayo_Teatro» |
| 16 |  |  | 16 · MiniGame |
| 17 | Transition |  | 17 · Transition |
| 18 |  |  | 18 · Reach @ Patio |
| 19 |  |  | 19 · Scene «Apertura» |
| 20 |  |  | 20 · Group |
| 20.1 |  |  | 20.1 · Use (Farolillos) |
| 20.2 |  |  | 20.2 · Talk «Imp_Altavoz» |
| 20.3 |  |  | 20.3 · Talk «Imp_Perdida» |
| 20.4 |  |  | 20.4 · Talk «Imp_Bruno» |
| 21 |  |  | 21 · Scene «TuParte» |
| 22 |  |  | 22 · Scene «Talentos» |
| 23 |  |  | 23 · MiniGame |
| 24 |  |  | 24 · Scene «Cierre» |
| 25 | Cinematic |  | 25 · Cinematic «Cole10_Festival» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): 1 frases al cumplirlo (escena ligera «Cole10_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): 1 frases al empezar el paso (van detrás de las del final del paso 1, en su escena «Cole10_G1_Fin»)
- PASO 3 → paso 3 del juego (Scene «Anuncio»): conversación «Anuncio» con 13 frases nuevas (música Descubrimiento→Intima)
- PASO 4 → paso 4 del juego (Choice): 8 frases al empezar el paso (escena ligera «Cole10_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 6.1 → paso 6.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Deco_Guirnalda» (1 frases)
- PASO 6.3 → paso 6.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Deco_Cartel» (1 frases)
- PASO 8 → paso 8 del juego (Scene «Ensayo_Musica»): conversación «Ensayo_Musica» con 2 frases nuevas (música Descubrimiento)
- PASO 9 → paso 9 del juego (MiniGame): 2 frases al empezar el paso (escena ligera «Cole10_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Reach): 1 frases al empezar el paso (escena ligera «Cole10_G10_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)
- PASO 11.1 → paso 11.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Comida_Harina» (2 frases)
- PASO 11.2 → paso 11.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Comida_Huevos» (1 frases)
- PASO 12 → paso 12 del juego (MiniGame): 2 frases al empezar el paso (escena ligera «Cole10_G12_Entra», la lanza el paso 11 al cumplirse; el jugador no pierde el control)
- PASO 13.1 → paso 13.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Escenario» (1 frases)
- PASO 13.2 → paso 13.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Columpios» (1 frases)
- PASO 13.3 → paso 13.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Foto_Entrada» (2 frases)
- PASO 15 → paso 15 del juego (Scene «Ensayo_Teatro»): conversación «Ensayo_Teatro» con 8 frases nuevas
- PASO 16 → paso 16 del juego (MiniGame): 4 frases al empezar el paso (escena ligera «Cole10_G16_Entra», la lanza el paso 15 al cumplirse; el jugador no pierde el control)
- PASO 18 → paso 18 del juego (Reach): 4 frases al empezar el paso (escena ligera «Cole10_G18_Entra», la lanza el paso 17 al cumplirse; el jugador no pierde el control)
- PASO 19 → paso 19 del juego (Scene «Apertura»): conversación «Apertura» con 5 frases nuevas (música Intima)
- PASO 20 → paso 20 del juego (Group): 1 frases al empezar el paso (escena ligera «Cole10_G20_Entra», la lanza el paso 19 al cumplirse; el jugador no pierde el control)
- PASO 20.1 → paso 20.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Imp_Farolillos» (2 frases)
- PASO 20.2 → paso 20.2 del juego (Talk «Imp_Altavoz»): conversación «Imp_Altavoz» con 3 frases nuevas
- PASO 20.3 → paso 20.3 del juego (Talk «Imp_Perdida»): conversación «Imp_Perdida» con 3 frases nuevas
- PASO 20.4 → paso 20.4 del juego (Talk «Imp_Bruno»): conversación «Imp_Bruno» con 3 frases nuevas
- PASO 21 → paso 21 del juego (Scene «TuParte»): conversación «TuParte» con 10 frases nuevas
- PASO 22 → paso 22 del juego (Scene «Talentos»): conversación «Talentos» con 4 frases nuevas (música Intima)
- PASO 24 → paso 24 del juego (Scene «Cierre»): conversación «Cierre» con 7 frases nuevas (música Intima)
- PASO 25 → paso 25 del juego (Cinematic «Cole10_Festival»): cinemática nueva «Cole10_G25» (10 planos, 4 frases, 28.9 s, música Intima) en lugar de «Cole10_Festival»

## Adaptado (y por qué)

- PASO 3: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 5 → paso 5 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6 → paso 6 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 6.2 → paso 6.2 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7 → paso 7 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11 → paso 11 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 13 → paso 13 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14 → paso 14 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 15: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 17 → paso 17 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 19: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 20.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 20.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 20.3: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 20.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 20.4: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 21: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 22: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 22: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 23 → paso 23 del juego (MiniGame): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 24: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 25: el plano General de «El festival al atardecer.» no se encuentra en la escena: plano General del lugar
- PASO 25: el plano Inserto de «Una fotografía del grupo.» no se encuentra en la escena: plano General del lugar

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 10 (línea 544) · Omar: «Bienvenido a la cocina.» → «Bienvenid{o/a} a la cocina.»

## Avisos

- PASO 1 (línea 72): «Añadir» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 8 (línea 469): «Toca» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 18 (línea 856): «Profesores» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 21 (línea 1276): condición «NO» con una variable que el juego aún no guarda (No)
- PASO 23 (línea 1391): «Debe» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1511): «Duración» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1605): «Debajo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1743): «Algunos NPCs deben» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1747): «Recuerdo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1759): «Datos» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 25 (línea 1851): «No» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 20.4 · Opción A · AYUDAR: Sonríe. / Bruno: ¿Qué? / Tú: Y deja que la gente pruebe. / El jugador empieza a ofrecer pequeñas muestras. / Rubén se une. / Poco a poco llegan clientes. / Cinemática / Dolly sobre la cola. / Bruno mira al jugador. / Ha funcionado. /  / Bruno: Gracias. / Baja la voz. / De verdad. / Bruno +8 / Rubén +4 / cole10_bruno_ayudado = true
- PASO 20.4 · OPCIÓN B · COMPRAR: El jugador compra un vaso. / Bruno: Está buena. /  / ¿Verdad? / Sonríe.
- PASO 20.4 · OPCIÓN C · NO AYUDAR: Tú: Tengo otras cosas que hacer. / Bruno baja la mirada. / Bruno: Ya. / No enfadado. / Solo decepcionado. / Esto debe quedar guardado.
- PASO 22 · OPCIÓN A · CANTAR: Marta: Yo te acompaño. / La cámara muestra al público. / El jugador respira.
- PASO 22 · OPCIÓN B · CHISTES CON NICO: Nico sube. / Nico: Esto va a ser histórico. /  / O vergonzoso.
- PASO 22 · OPCIÓN C · ANIMAR DESDE ABAJO: El jugador se queda entre el público. / Aplaude. / Cuando otro niño duda… / El jugador lo anima. / Esto es importante: / No subir al escenario también debe ser una decisión válida.
- PASO 25 · DIRECCIÓN VISUAL DEL EVENTO: El festival debe tener una identidad visual completamente distinta al colegio normal.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
