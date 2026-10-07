# Informe de la reescritura · Ins06_LaGranDecision

Guion: `docs/historia/reescritura/Ins06_LaGranDecision.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Ins06_LaGranDecision`.
Datos: `src/shared/LifeStory/Guiones/Ins06_LaGranDecision.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

Es la transición de etapa (Adolescente → Adulto): la estructura es la de siempre (los planes de los amigos, Carmen, las puertas abiertas, la selectividad y sus notas, la convocatoria de julio, la noche de la decisión, la decisión Futuro, la graduación y la transición Adol_Selectividad, que no se cambia: el montaje de cambio de etapa tiene un diseño fijo comprobado por test-etapas). Las variantes van con lo que ya guarda el juego: los recuerdos PrimerDiaInstituto, QueQuieresSer y PrimerSueldo, ConocesALeire, las decisiones de la etapa (Veterano, RecreoIns, SitioInstituto, Camino, Reportaje, Orientacion, Empleo, Meta, Futuro…) y el nombre del grupo (Choices.NombreGrupo). No se crean marcas nuevas: si el guion pide una que nada pone, la frase no sale. «Si el jugador se distrae» en la biblioteca no es una mecánica: esas frases no salen.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Transition |  | 1 · Transition |
| 2 |  |  | 2 · Reach @ PatioInstituto |
| 3 |  |  | 3 · Group |
| 3.1 |  |  | 3.1 · Talk «Plan_Sara» |
| 3.2 |  |  | 3.2 · Talk «Plan_Omar» |
| 3.3 |  |  | 3.3 · Talk «Plan_Nico» |
| 3.4 |  |  | 3.4 · Talk «Plan_Bruno» |
| 3.5 |  |  | 3.5 · Talk «Plan_Leire» |
| 3.6 |  |  | 3.6 · Talk «Plan_Hugo» |
| 3.7 |  |  | 3.7 · Talk «Plan_Mateo» |
| 3.8 |  |  | 3.8 · Talk «Plan_Iker» |
| 4 |  |  | 4 · Reach @ AulaInstituto |
| 5 |  |  | 5 · Talk «Carmen» |
| 6 |  |  | 6 · Reach @ Universidad |
| 7 | Scene |  | 7 · Scene «PuertasAbiertas» |
| 8 |  |  | 8 · Class @ Biblioteca |
| 9 | Scene |  | 9 · Scene «Nervios» |
| 10 |  |  | 10 · Class @ AulaInstituto |
| 11 |  |  | 11 · Transition |
| 12 |  |  | 12 · Transition |
| 13 |  |  | 13 · Transition |
| 14 |  |  | 14 · Transition |
| 15 |  |  | 15 · Transition |
| 16 |  |  | 16 · Class @ Biblioteca |
| 17 |  |  | 17 · Class @ AulaInstituto |
| 18 |  |  | 18 · Transition |
| 19 |  |  | 19 · Transition |
| 20 |  |  | 20 · Transition |
| 21 | Transition |  | 21 · Transition |
| 22 | Cinematic |  | — |
| 23 |  |  | 23 · Choice |
| 24 | Scene |  | 24 · Scene «Decidido» |
| 25 |  |  | 25 · Reach @ PatioInstituto |
| 26 | Cinematic |  | — |
| 27 | Transition |  | — |

## Errores

_Ninguno._


## Aplicado

- PASO 2 → paso 2 del juego (Reach): 3 frases al empezar el paso (escena ligera «Ins06_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3.1 → paso 3.1 del juego (Talk «Plan_Sara»): conversación «Plan_Sara» con 13 frases nuevas
- PASO 3.2 → paso 3.2 del juego (Talk «Plan_Omar»): conversación «Plan_Omar» con 8 frases nuevas
- PASO 3.3 → paso 3.3 del juego (Talk «Plan_Nico»): conversación «Plan_Nico» con 13 frases nuevas
- PASO 3.4 → paso 3.4 del juego (Talk «Plan_Bruno»): conversación «Plan_Bruno» con 14 frases nuevas
- PASO 3.5 → paso 3.5 del juego (Talk «Plan_Leire»): conversación «Plan_Leire» con 6 frases nuevas
- PASO 3.6 → paso 3.6 del juego (Talk «Plan_Hugo»): conversación «Plan_Hugo» con 16 frases nuevas
- PASO 3.7 → paso 3.7 del juego (Talk «Plan_Mateo»): conversación «Plan_Mateo» con 7 frases nuevas
- PASO 3.8 → paso 3.8 del juego (Talk «Plan_Iker»): conversación «Plan_Iker» con 4 frases nuevas
- PASO 4 → paso 4 del juego (Reach): 3 frases al empezar el paso (escena ligera «Ins06_G4_Entra», la lanza el paso 3 al cumplirse; el jugador no pierde el control)
- PASO 5 → paso 5 del juego (Talk «Carmen»): conversación «Carmen» con 40 frases nuevas
- PASO 7 → paso 7 del juego (Scene «PuertasAbiertas»): conversación «PuertasAbiertas» con 9 frases nuevas
- PASO 9 → paso 9 del juego (Scene «Nervios»): conversación «Nervios» con 8 frases nuevas
- PASO 17 → paso 17 del juego (Class): 2 frases al empezar el paso (escena ligera «Ins06_G17_Entra», la lanza el paso 16 al cumplirse; el jugador no pierde el control)
- PASO 23 → paso 23 del juego (Choice): 3 frases al empezar el paso (escena ligera «Ins06_G23_Entra», la lanza el paso 22 al cumplirse; el jugador no pierde el control)
- PASO 24 → paso 24 del juego (Scene «Decidido»): conversación «Decidido» con 23 frases nuevas

## Adaptado (y por qué)

- PASO 22 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 26 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 27 [Transition] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 1 → paso 1 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3 → paso 3 del juego (Group): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 3.1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.2: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.3: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.4: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.6: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.7: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 3.8: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 5: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica
- PASO 6 → paso 6 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 8 → paso 8 del juego (Class): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 10 → paso 10 del juego (Class): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 11: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 11 → paso 11 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 12: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 12 → paso 12 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 13: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 13 → paso 13 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 14: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 14 → paso 14 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 15: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 15 → paso 15 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 16 → paso 16 del juego (Class): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 18: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 18 → paso 18 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 19: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 19 → paso 19 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 20: el guion lo escribe como [] y en el juego es transición (Transition): se conserva el tipo del juego y su mecánica
- PASO 20 → paso 20 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 21 → paso 21 del juego (Transition): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican
- PASO 25 → paso 25 del juego (Reach): solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican

## Género ({o/a}) corregido en frases dirigidas al jugador

- PASO 7 (línea 1231) · Sofia: «Bienvenido/a a la jornada de puertas abiertas.» → «Bienvenid{o/a} a la jornada de puertas abiertas.»

## Avisos

- PASO 11 (línea 1447): «Medicina» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 12 (línea 1471): «Ingeniería» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 12 (línea 1472): «Derecho» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 12 (línea 1473): «Economía» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)
- PASO 23 (línea 2152): «Disponible únicamente si» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)

## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 12 · NOTABLE ALTO: 

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
