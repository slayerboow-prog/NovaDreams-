# Informe de la reescritura · Bebe_HoraDeSalir

Guion: `docs/historia/reescritura/Bebe_HoraDeSalir.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau Bebe_HoraDeSalir`.
Datos: `src/shared/LifeStory/Guiones/Bebe_HoraDeSalir.luau` (no se edita a mano: se regenera con la herramienta).

La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.

PASO 1 (el ventanal) reescribe la escena Bebe_VentanalFamilia, la que pone BabyService cuando te asomas (el paso 1 de la misión se cumple igual: asomarte). PASO 2-6 (los años que pasan, Los Pinos, la Profe Lucía en la puerta, el aula) son el montaje de cambio de etapa Montaje_Bebe_Nino, que NO se cambia: el montaje tiene un diseño fijo que comprueba test-etapas (25-40 s, «fotos vivas» de los recuerdos que de verdad viviste, el jugador solo aparece en la llegada, la música de «Pasan los años»…) y el guion lo convierte en una película de casi 4 minutos con planos del niño creciendo. Queda pendiente decidir si se acorta el guion a ese formato o se cambia el diseño del montaje; mientras, el montaje de siempre sigue. La llegada a Los Pinos con la Profe Lucía ya la cuenta el principio de Cole01 (también reescrito). FLAG DE MEMORIA: la etapa (Nino), la misión completada y que se desbloquee Cole01 ya los hace el juego; los recuerdos «ElPrimerColegio» y «LaVistaDesdeElVentanal» no existen en Memories y no se inventan.

## Correspondencia de pasos

| PASO del guion | Tipo | Lugar | Paso del juego |
|---|---|---|---|
| 1 | Action | Salón | @Bebe_VentanalFamilia · ? |
| 2 | Transition | Ventanal | — |
| 3 | Cinematic | Valmar | — |
| 4 | Cinematic | Entrada de Los Pinos | — |
| 5 | Transition | Los Pinos | — |
| 6 | Transition | Los Pinos | — |

## Errores

_Ninguno._


## Aplicado

- PASO 1 → paso @Bebe_VentanalFamilia del juego (Cinematic «Bebe_VentanalFamilia»): la escena «Bebe_VentanalFamilia» se cuenta con el guion nuevo (misma escena, 11 planos, 6 frases, 33.6 s, música Descubrimiento)

## Adaptado (y por qué)

- PASO 2 [Transition] @ Ventanal: no corresponde a ningún paso del juego: no se aplica
- PASO 3 [Cinematic] @ Valmar: no corresponde a ningún paso del juego: no se aplica
- PASO 4 [Cinematic] @ Entrada de Los Pinos: no corresponde a ningún paso del juego: no se aplica
- PASO 5 [Transition] @ Los Pinos: no corresponde a ningún paso del juego: no se aplica
- PASO 6 [Transition] @ Los Pinos: no corresponde a ningún paso del juego: no se aplica
- PASO 1: el guion lo escribe como [Action] y en el juego es cinemática (Cinematic): se conserva el tipo del juego y su mecánica

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
