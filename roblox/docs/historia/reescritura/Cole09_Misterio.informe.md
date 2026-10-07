# Informe de la reescritura · Cole09_Misterio

Guion: `docs/historia/reescritura/Cole09_Misterio.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Cole09_Misterio`.
Datos: `src/shared/LifeStory/Guiones/Cole09_Misterio.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Se conservan las marcas de siempre: entrar = Choices.Entrar (Permiso/Colarse), el candado (Choices.Candado; 199813 es la buena, las otras tres te dejan probar otra vez), foto de Lucía = Choices.FotoLucia (Devolver/Clase/Secreto), Flags.SecretoLucia y la cápsula = Choices.Capsula (Carta/Dibujo/Prediccion/Pregunta), que lee Cole12; Flags.CapsulaDelTiempo sigue igual. Las marcas nuevas que propone el guion (cole09_sala_descubierta, cole09_foto_lucia, cole09_capsula_creada…) no se añaden: lo mismo ya se sabe con la misión completada y las decisiones anteriores. Vestir la sala (polvo, rayos de luz, partículas) no se hace: la sala vieja no tiene un decorado propio donde ponerlo barato (pendiente). El destello verde del tornillo al final solo tendría sentido para quien soñó el prólogo (Memories.SuenoGrieta); no hay un efecto del tornillo fuera del sueño, así que queda pendiente. Las direcciones del guion («DIRECCIÓN AAA», NPC que no se quedan congelados) son notas para quien monte la escena: los NPC ya tienen su vida (ActorLife).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ Patio |
| 3 | Scene |  | 3 · Scene «Rumores» |
| 4 |  |  | 4 · Use (Nota) |
| 5 | Scene |  | 5 · Scene «TrasNota» |
| 6 |  |  | 6 · Group |
| 6.1 |  |  | 6.1 · Use (Anuario) |
| 6.2 |  |  | 6.2 · Use (Llaves) |
| 6.3 |  |  | 6.3 · Use (TrofeoViejo) |
| 6.4 |  |  | 6.4 · Use (Puerta) |
| 7 |  |  | 7 · Scene «Codigo» |
| 8 |  |  | 8 · Choice |
| 9 |  |  | 9 · Reach @ SalaCerradaPuerta |
| 10 |  |  | 10 · Choice |
| 11 |  |  | 11 · Scene «Dentro» |
| 12 |  |  | 12 · Group |
| 12.1 |  |  | 12.1 · Use (Pupitre) |
| 12.2 |  |  | 12.2 · Use (Caja) |
| 12.3 |  |  | 12.3 · Use (Estanteria) |
| 13 |  |  | 13 · Use (Foto) |
| 14 | Cinematic |  | 14 · Cinematic «Cole09_LaFoto» |
| 15 | Scene |  | 15 · Scene «LaFoto» |
| 16 |  |  | 16 · Reach @ AulaA |
| 17 |  |  | 17 · Talk «Lucia_Foto» |
| 18 |  |  | 18 · Choice |
| 19 |  |  | 19 · Scene «Capsula» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Transition): objetivo «Unos días después del torneo…»
- PASO 1 → paso 1 del juego (Transition): 1 frases al cumplirlo (escena ligera «Cole09_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Reach): objetivo «Sal al recreo: tus amigos no hablan de otra cosa»
- PASO 3 → paso 3 del juego (Scene «Rumores»): conversación «Rumores» con 15 frases nuevas (música Descubrimiento→Tension)
- PASO 4 → paso 4 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Nota» (1 frases)
- PASO 4 → paso 4 del juego (Use): objetivo «Vuelve a tu taquilla a por el almuerzo»
- PASO 5 → paso 5 del juego (Scene «TrasNota»): conversación «TrasNota» con 6 frases nuevas (música Tension)
- PASO 6 → paso 6 del juego (Group): objetivo «Investiga el misterio»
- PASO 6.1 → paso 6.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Anuario» (3 frases)
- PASO 6.2 → paso 6.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Llaves» (5 frases)
- PASO 6.3 → paso 6.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Pista_Trofeo» (2 frases)
- PASO 7 → paso 7 del juego (Scene «Codigo»): conversación «Codigo» con 3 frases nuevas (música Tension)
- PASO 8 → paso 8 del juego (Choice): «OPCIÓN A · PEDIR PERMISO» es la conversación de la opción Permiso («Permiso_Ramon», 3 frases)
- PASO 8 → paso 8 del juego (Choice): objetivo «¿Pides permiso o te cuelas?»
- PASO 8 → paso 8 del juego (Choice): 3 frases al empezar el paso (escena ligera «Cole09_G8_Entra», la lanza el paso 7 al cumplirse; el jugador no pierde el control)
- PASO 9 → paso 9 del juego (Reach): objetivo «Ve a la puerta del fondo del pasillo»
- PASO 9 → paso 9 del juego (Reach): 2 frases al empezar el paso (escena ligera «Cole09_G9_Entra», la lanza el paso 8 al cumplirse; el jugador no pierde el control)
- PASO 10 → paso 10 del juego (Choice): objetivo «¿Qué código pruebas?»
- PASO 10 → paso 10 del juego (Choice): 8 frases al empezar el paso (escena ligera «Cole09_G10_Entra», la lanza el paso 9 al cumplirse; el jugador no pierde el control)
- PASO 11 → paso 11 del juego (Scene «Dentro»): conversación «Dentro» con 4 frases nuevas (música Tension→Descubrimiento)
- PASO 12 → paso 12 del juego (Group): objetivo «Explora la sala»
- PASO 12.1 → paso 12.1 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Dentro_Pupitre» (1 frases)
- PASO 12.2 → paso 12.2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Dentro_Caja» (1 frases)
- PASO 12.3 → paso 12.3 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Dentro_Trofeos» (2 frases)
- PASO 13 → paso 13 del juego (Use): objetivo «En la pared hay una foto enmarcada»
- PASO 14 → paso 14 del juego (Cinematic «Cole09_LaFoto»): la escena «Cole09_LaFoto» se cuenta con el guion nuevo (misma escena, 3 planos, 10 frases, 23.9 s, música Intima)
- PASO 15 → paso 15 del juego (Scene «LaFoto»): conversación «LaFoto» con 4 frases nuevas
- PASO 16 → paso 16 del juego (Reach): objetivo «Busca a Lucía en clase»
- PASO 17 → paso 17 del juego (Talk «Lucia_Foto»): conversación «Lucia_Foto» con 16 frases nuevas (música Intima)
- PASO 18 → paso 18 del juego (Choice): objetivo «¿Qué metes en la cápsula del tiempo?»
- PASO 18 → paso 18 del juego (Choice): 7 frases al empezar el paso (escena ligera «Cole09_G18_Entra», la lanza el paso 17 al cumplirse; el jugador no pierde el control)
- PASO 19 → paso 19 del juego (Scene «Capsula»): conversación «Capsula» con 5 frases nuevas (música Intima→Descubrimiento)

## Adaptado (y por qué)

- PASO 1: 6 PLANO de un paso jugable (Transition) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta
- PASO 6.4 → paso 6.4 del juego (Use): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 7: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 11: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica
- PASO 14: el guion no trae planos para «Cole09_LaFoto»: se conservan los de la escena de antes
- PASO 15: una frase del juego daba efectos (Rel): se conservan al final de la conversación
- PASO 17: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 17: la conversación del juego tenía 1 preguntas y el guion 0: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)
- PASO 19: el guion lo escribe como [] y en el juego es conversación (Scene): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

- PASO 1 (línea 57): «Duración» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 4 (línea 277): «Debajo» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6.1 (línea 409): «Página» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6.2 (línea 457): «Número» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 6.4 (línea 535): «Grabado» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 12.2 (línea 935): «Dentro» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 12.3 (línea 967): «Uno» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 1 · Objetivo: «Unos días después del torneo…»: Cinemática Cole09_Transicion
- PASO 2 · Objetivo: «Sal al recreo: tus amigos no hablan de otra cosa»: Lugar
- PASO 4 · Objetivo: «Vuelve a tu taquilla a por el almuerzo»: Acción del jugador
- PASO 6 · Objetivo: «Investiga el misterio»: Los objetivos pueden completarse en cualquier orden.
- PASO 8 · Objetivo: «¿Pides permiso o te cuelas?»: 
- PASO 8 · OPCIÓN A · PEDIR PERMISO: Efectos: / * entrar = Permiso / * Ramón +6 / * responsabilidad +1 / * cole09_entrada_responsable = true / Cinemática / Ramón escucha la petición. / Primero parece sorprendido. / Después sonríe. / Vaya. /  / Ramón: Por fin alguien pregunta. / Saca lentamente la llave 13. / Ramón: Os doy permiso. / Mira a todos. / Ramón: Pero el código lo descubrís vosotros. / Guarda la llave en su bolsillo. / Yo solo abriré cuando sepáis qué estáis buscando.
- PASO 8 · OPCIÓN B · COLARSE: Efectos: / * entrar = Colarse / * valentía +1 / * cole09_entrada_secreta = true / Cinemática / Recreo. / El pasillo está vacío. / Se oye un reloj.
- PASO 9 · Objetivo: «Ve a la puerta del fondo del pasillo»: El jugador camina con sus compañeros.
- PASO 10 · Objetivo: «¿Qué código pruebas?»: Mantener exactamente las cuatro opciones originales.
- PASO 12 · Objetivo: «Explora la sala»: La sala debe poder explorarse libremente.
- PASO 13 · Objetivo: «En la pared hay una foto enmarcada»: El jugador se acerca.
- PASO 16 · Objetivo: «Busca a Lucía en clase»: Transición
- PASO 17 · OPCIÓN A · DEVOLVERLA: Efectos: / * Lucía +10 / * empatía +1 / * foto lucia = Devolver / Tú: Es tuya. Te la hemos traído. / Lucía la recibe con ambas manos. / Lucía: Gracias. /  / De verdad. / Mira la foto. / Creo que necesitaba volver a verla.
- PASO 17 · OPCIÓN B · ENSEÑARLA A LA CLASE: Efectos: / * Lucía +5 / * Nico +3 / * humor +1 / * foto lucia = Clase / Nico levanta la fotografía. / Nico: ¡ATENCIÓN! ¡LUCÍA CON COLETAS! / Lucía: ¡Nico! /  / Lucía termina riéndose. / Lucía: Vale. / Lucía: Era yo.
- PASO 17 · OPCIÓN C · GUARDAR EL SECRETO: Efectos: / * Lucía +8 / * responsabilidad +1 / * foto lucia = Secreto / * secreto lucia = true / Tú: No se lo diremos a nadie. / Lucía sonríe. / Lucía: Entonces queda entre nosotros. /  / Y ni una palabra sobre las coletas.
- PASO 18 · Objetivo: «¿Qué metes en la cápsula del tiempo?»: Esta decisión debe sentirse importante.
- PASO 19 · DIRECCIÓN AAA OBLIGATORIA: 1. La sala debe sentirse real
- PASO 19 · DIRECCIÓN DE CÁMARA: Sara: No utilizar una única cámara estática durante los diálogos.
- PASO 19 · DIRECCIÓN MUSICAL: Usar exclusivamente estas intensidades: / * Calma / * Tension / * Emocion / * Accion / * Epico / * Comedia / Usar: No utilizar nombres de géneros como intensidad musical.

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
