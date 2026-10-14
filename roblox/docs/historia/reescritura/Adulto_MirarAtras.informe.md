# Informe de la reescritura · Adulto_MirarAtras

Guion: `docs/historia/reescritura/Adulto_MirarAtras.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Adulto_MirarAtras`.
Datos: `src/shared/LifeStory/Guiones/Adulto_MirarAtras.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: volver a la casa familiar, la cinemática Vida_MirarAtras y el momento final. La cinemática NO se cambia: la de siempre ya enseña cada recuerdo solo si lo viviste (sus marcas reales), y el guion nuevo es un documento de dirección (el álbum con una foto por etapa, microflashbacks de 1-3 s, «si existe…», Pip y la Grieta solo con SagaCompleta) que hay que montar a mano para no enseñar nunca un recuerdo no vivido. La línea de tiempo «MI VIDA» y el álbum persistente son un sistema nuevo (pendiente).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | — |
| 2 | Cinematic |  | — |
| 3 |  |  | 3 · Moment |

## Errores

_Ninguno._


## Aplicado

- PASO 3 → paso 3 del juego (Moment): 2 frases al empezar el paso (escena ligera «Vida_G3_Entra», la lanza el paso 2 al cumplirse; el jugador no pierde el control)

## Adaptado (y por qué)

- PASO 1 [] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 2 [Cinematic] @ : no corresponde a ningún paso del juego: no se aplica
- PASO 3: el guion lo escribe como [] y en el juego es transición (Moment): se conserva el tipo del juego y su mecánica

## Género ({o/a}) corregido en frases dirigidas al jugador

_Ninguna corrección._


## Avisos

_Ninguno._


## Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)

- PASO 3 · SISTEMA DE MEMORIA FINAL: Al interactuar con el álbum aparece:

## Cómo se traduce el formato

- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.
- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.
- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).
- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.
- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.
