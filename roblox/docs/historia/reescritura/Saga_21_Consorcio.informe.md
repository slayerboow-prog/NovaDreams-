# Informe de la reescritura · Saga_21_Consorcio

Guion: `docs/historia/reescritura/Saga_21_Consorcio.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Saga_21_Consorcio`.
Datos: `src/shared/LifeStory/Guiones/Saga_21_Consorcio.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

La mecánica es la de siempre: el asalto a la oficina de MegaVerso (la de Saga_08; no hay sótano ni sala de servidores nueva: el servidor es el objeto de siempre), apartar a la seguridad sin violencia, enchufar el pendrive con forma de pez y la quiebra con el agente Glub del Banco Galáctico (ConsorcioCaido y el recuerdo CaidaConsorcio). Las variantes van con las marcas reales: GrisArrepentida (Saga_11), DeudaGalactica, SabeFusion (Saga_08) y el recuerdo EquipoRescate. Si te detectan, la pelea ya te devuelve al punto seguro; lo que dice Candela en ese momento no tiene cuándo salir (pendiente). Las pantallas apagadas y las noticias por la ciudad serían un sistema de frases de ambiente nuevo (pendiente); cosimo_sin_financiacion no se crea (nada la lee).

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 |  |  | 1 · Fight @ OficinasFinanciero |
| 2 |  |  | 2 · Use (Servidor) |
| 3 | Scene |  | 3 · Scene «Quiebra» |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso 1 del juego (Fight): 2 frases al cumplirlo (escena ligera «Saga_21_G1_Fin», sin quitar el control)
- PASO 2 → paso 2 del juego (Use): lo que pasa al usarlo va en la conversación del objeto «Servidor» (4 frases)
- PASO 3 → paso 3 del juego (Scene «Quiebra»): conversación «Quiebra» con 8 frases nuevas

## Adaptado (y por qué)

- PASO 1: no hay paso de antes que pueda lanzar las 2 frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso 1

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
