# Informe de la reescritura · Saga_22_Ancla

Guion: `docs/historia/reescritura/Saga_22_Ancla.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_22_Ancla`.
Datos: `src/shared/LifeStory/Guiones/Saga_22_Ancla.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: Cósimo llama a la puerta de tu casa (la que tengas; la escena es en la puerta, con su horario de 20:00 a 06:00), su oferta, la decisión Trato (No / Trampa, los valores que ya lee Saga_23; trampa_cosimo es la marca TrampaCosimo que ya pone el juego) y el cierre. Las variantes van con el recuerdo CaidaConsorcio (Saga_21) y el recuerdo EresElAncla (la cinta del archivo, Saga_09). «Ven solo… o sola» va con su {solo/sola}. Las flores que muerden son un objeto de atrezo sin daño: no hay sistema para guardarlas en casa o en el álbum (pendiente). La llamada a Cosme por el teléfono de siempre queda como frase.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Talk «Oferta» |
| 2 |  |  | 2 · Choice |
| 3 | Scene |  | 3 · Scene «Respuesta» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Talk «Oferta»): conversación «Oferta» con 9 frases nuevas
- PASO 2 → paso 2 del juego (Choice): 1 frases al empezar el paso (escena ligera «Saga_22_G2_Entra», la lanza el paso 1 al cumplirse; el jugador no pierde el control)
- PASO 3 → paso 3 del juego (Scene «Respuesta»): conversación «Respuesta» con 5 frases nuevas

## Adaptado (y por qué)

- PASO 1: el guion lo escribe como [] y en el juego es conversación (Talk): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

_Ninguna._


## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
