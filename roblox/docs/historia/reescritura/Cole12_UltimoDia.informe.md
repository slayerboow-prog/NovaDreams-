# Informe de la reescritura · Cole12_UltimoDia

Guion: `docs/historia/reescritura/Cole12_UltimoDia.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole12_UltimoDia`.
Datos: `src/shared/LifeStory/Guiones/Cole12_UltimoDia.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Se mantienen las variables de siempre: los recuerdos visitados (el Group del paso 5, al menos cuatro), la cápsula (Choices.Capsula de Cole09: Carta/Dibujo/Prediccion/Pregunta), el adiós a Bruno (Choices.AdiosBruno, con el llavero 13 de Ramón como hasta ahora) y la promesa (Choices.Promesa). Cada frase que recuerda algo va condicionada a la marca que lo guarda (AyudasteAMateo, HugoConElGrupo, IkerEnElGrupo, TorneoGanado/Perdido, SuspendisteExamen, SecretoLucia, AcusasteABruno, Bruno_HablasteConEl, Ruben_Perdonado/Rival, FotoLucia, NombreGrupo…); el grito final solo sale con el nombre de grupo que elegiste. El PASO 15 (la transición al instituto, Nino_AInstituto = el montaje Montaje_Nino_Adolescente) no se cambia: el montaje de etapa tiene un diseño fijo comprobado por test-etapas (duración, fotos vivas de lo vivido…). Los «recuerdos superpuestos» (el pasado sobre el presente) se quedan como plano + frase: el motor no tiene un filtro de recuerdo (pendiente). test-reescritura recorre combinaciones (Mateo sí/no, Hugo, Iker, torneo ganado/perdido, cada cápsula y cada nombre de grupo) y comprueba que no sale ningún recuerdo no vivido.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Scene «Manana» |
| 3 |  |  | 3 · Reach @ Vestibulo |
| 4 |  |  | 4 · Scene «Llegada» |
| 5 |  |  | 5 · Group |
| 5.1 |  |  | 5.1 · Use (RecPupitre) |
| 5.2 |  |  | 5.2 · Use (RecTaquilla) |
| 5.3 |  |  | 5.3 · Use (RecCampo) |
| 5.4 |  |  | 5.4 · Use (RecBiblioteca) |
| 5.5 |  |  | 5.5 · Use (RecAlmacen) |
| 5.6 |  |  | 5.6 · Use (RecBanco) |
| 6 |  |  | 6 · Reach @ SalaCerrada |
| 7 | Cinematic |  | 7 · Cinematic «Cole12_Capsula» |
| 8 |  |  | 8 · Reach @ Patio |
| 9 |  |  | 9 · Cinematic «Cole12_FotoClase» |
| 10 |  |  | 10 · Scene «Ceremonia» |
| 11 |  |  | 11 · Group |
| 11.1 |  |  | 11.1 · Talk «Adios_Lucia» |
| 11.2 |  |  | 11.2 · Talk «Adios_Bruno» |
| 11.3 |  |  | 11.3 · Talk «Adios_Ramon» |
| 12 |  |  | 12 · Scene «Promesa» |
| 13 |  |  | 13 · Cinematic «Cole12_Despedida» |
| 14 | Cinematic |  | 14 · Cinematic «Cole12_FinDeEpisodio» |
| 15 | Transition |  | — |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Scene «Manana»): conversación «Manana» con 6 frases nuevas
- PASO 4 → paso 4 del juego (Scene «Llegada»): conversación «Llegada» con 5 frases nuevas (música Intima)
- PASO 5 → paso 5 del juego (Group): objetivo «visitar al menos 4 de 6 lugares.»
- PASO 5.1 → paso 5.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Pupitre» (1 frases)
- PASO 5.2 → paso 5.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Taquilla» (2 frases)
- PASO 5.3 → paso 5.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Campo» (3 frases)
- PASO 5.4 → paso 5.4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Biblioteca» (2 frases)
- PASO 5.5 → paso 5.5 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Almacen» (3 frases)
- PASO 5.6 → paso 5.6 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Rec_Banco» (4 frases)
- PASO 6 → paso 6 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole12_G6_Entra», la lanza el paso 5 al cumplirse; el jugador no pierde el control)
- PASO 7 → paso 7 del juego (Cinematic «Cole12_Capsula»): la escena «Cole12_Capsula» se cuenta con el guion nuevo (misma escena, 5 planos, 13 frases, 54.7 s, música Intima)
- PASO 8 → paso 8 del juego (Reach): 1 frases al empezar el paso (escena ligera «Cole12_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Cinematic «Cole12_FotoClase»): la escena «Cole12_FotoClase» se cuenta con el guion nuevo (misma escena, 2 planos, 5 frases, 19.9 s, música Intima)
- PASO 10 → paso 10 del juego (Scene «Ceremonia»): conversación «Ceremonia» con 9 frases nuevas (música Intima)
- PASO 11.1 → paso 11.1 del juego (Talk «Adios_Lucia»): conversación «Adios_Lucia» con 7 frases nuevas
- PASO 11.2 → paso 11.2 del juego (Talk «Adios_Bruno»): conversación «Adios_Bruno» con 7 frases nuevas
- PASO 11.3 → paso 11.3 del juego (Talk «Adios_Ramon»): conversación «Adios_Ramon» con 2 frases nuevas
- PASO 12 → paso 12 del juego (Scene «Promesa»): conversación «Promesa» con 4 frases nuevas
- PASO 13 → paso 13 del juego (Cinematic «Cole12_Despedida»): la escena «Cole12_Despedida» se cuenta con el guion nuevo (misma escena, 3 planos, 12 frases, 51.8 s, música Intima)
- PASO 14 → paso 14 del juego (Cinematic «Cole12_FinDeEpisodio»): la escena «Cole12_FinDeEpisodio» se cuenta con el guion nuevo (misma escena, 3 planos, 5 frases, 14.8 s, música Intima→Descubrimiento)
- Conversación «Rec_Pupitre»: se conservan delante 6 frases del juego que dependen de lo vivido
- Conversación «Rec_Taquilla»: se conservan delante 3 frases del juego que dependen de lo vivido
- Conversación «Rec_Campo»: se conservan delante 6 frases del juego que dependen de lo vivido
- Conversación «Rec_Biblioteca»: se conservan delante 7 frases del juego que dependen de lo vivido
- Conversación «Rec_Almacen»: se conservan delante 5 frases del juego que dependen de lo vivido
- Conversación «Rec_Banco»: se conservan delante 9 frases del juego que dependen de lo vivido

## Adaptado (y por qué)

- PASO 15 [Transition] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 2: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 3 → paso 3 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 4: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 7: el plano General de «Todos entran en la antigua aula.» no se encuentra en la escena: plano General del lugar
- PASO 7: el plano Inserto de «La cápsula sobre la mesa.» no se encuentra en la escena: plano General del lugar
- PASO 7: el plano PPP de «La caja se abre.» no se encuentra en la escena: plano General del lugar
- PASO 9: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 9: el guion no trae planos para «Cole12_FotoClase»: se conservan los de la escena de antes
- PASO 10: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11 → paso 11 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 11.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 11.2: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- frase quitada (es una acotación, no se dice): «Lo entrega.»
- PASO 11.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 11.3: «recuerdo_llave_13 = true» no la lee ninguna misión: no se crea
- PASO 12: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 12: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 13: el guion lo escribe como [] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica
- PASO 13: el plano Medio de «El grupo sentado.» no se encuentra en la escena: plano General del lugar
- PASO 14: el guion no trae planos para «Cole12_FinDeEpisodio»: se conservan los de la escena de antes

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 5 · Objetivo: visitar al menos 4 de 6 lugares.: Pero no debe ser simplemente:
- PASO 11.2 · OPCIÓN A · «En el instituto, ¿empezamos de cero?»: Bruno +10 / Bruno tarda en responder. / PrimerPlano. / De cero. /  / Vale. / Sonríe. / Pero en fútbol no te voy a dejar ganar. / Extiende la mano. / El jugador puede estrecharla. / adios bruno = DeCero
- PASO 11.2 · OPCIÓN B · «Suerte, Bruno. De verdad.»: Bruno +5 / Bruno: Suerte. /  / Tú también. / Bruno: Y lo digo de verdad.
- PASO 11.2 · OPCIÓN C · «Ya nos veremos.»: Bruno asiente. / Bruno: Ya nos veremos. /  / Bruno: Eso seguro. / No convertir esta opción en «mala». / Es simplemente una relación menos cercana. / RUBÉN: Gracias por perdonarme lo de la mochila. / RUBÉN: Lo de la mochila… /  / RUBÉN: Que te vaya bien.
- PASO 12 · OPCIÓN A · «Pase lo que pase, seguimos juntos.»: Nico +5 / Omar +5 / Sara +5 / Omar: Juntos. /  / Omar: Hasta en el comedor. / Omar: Juntos contra el puré.
- PASO 12 · OPCIÓN B · «Conocer a gente nueva sin olvidarnos nunca.»: Nico +3 / Omar +3 / Sara +3 / Sara: Crecer sin perder lo importante. /  / Sara: Me gusta.
- PASO 12 · OPCIÓN C · «Quedar en el banco del parque cada verano.»: Nico +4 / Omar +4 / Sara +4 / Nico: ¡Cada verano! / Levanta la mano. / Nico: Y el que no venga paga los helados.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
