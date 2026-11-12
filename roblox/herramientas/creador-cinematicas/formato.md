# Formato del guion de una misión (lo que entiende el juego)

El juego convierte este texto en cinemáticas y conversaciones de forma automática
(scripts/audit/aplicar-reescritura.luau). Si se respeta este formato, no hace falta programar nada.

## Estructura

```
MISION: <IdMision> — <Título>

Resumen: <dos o tres frases de qué pasa en la misión>

PASO 1 [Cinematic] @ <Lugar>
Reparto: <Nombre1>, <Nombre2>
Musica: <Calma | Tension | Emocion | Accion | Epico | Comedia>
PLANO <TipoDePlano> -> <A quién o qué mira la cámara> | <Qué se ve>
<Nombre>: (<gesto>) <frase>
<Nombre>: <frase>

PASO 2 [Talk] @ <Lugar>
...
```

## Reglas

- **Un PASO del guion = un paso del juego.** Respeta el orden y el número de pasos de la misión
  (te los paso en «Pasos del juego»). La mecánica de cada paso (ir a un sitio, coger, beber…) NO cambia:
  el guion solo pone lo que se ve y lo que se dice. No inventes pasos jugables nuevos.
- Tipos de PASO: `Cinematic`, `Talk`, `Scene`, `Dialogo`, `Action`, `Transition`, `Choice`.
  Usa el tipo del paso del juego cuando lo sepas.
- **Tipos de PLANO** (solo estos): `General`, `Medio`, `PrimerPlano`, `PPP`, `Hombro`, `DosPlanos`,
  `Lateral`, `Reaccion`, `Seguir`, `Inserto`, `Dolly`, `Pan`, `Tilt`.
  Cada cambio de plano tiene que tener una razón (descubrimiento: General → Reaccion → PrimerPlano → Inserto → Reaccion).
- **Música** (solo estos valores): `Calma`, `Tension`, `Emocion`, `Accion`, `Epico`, `Comedia`.
- **Frases:** `Nombre: frase`. Máximo 140 caracteres por frase; si es más larga, pártela en dos frases.
  El jugador es `Yo`. El narrador es `Narrador`. Usa los mismos nombres de personaje que ya usa la misión.
- **Gestos:** entre paréntesis al principio de la frase. Los que el juego sabe animar:
  sonríe, ríe, asiente, niega, señala, saluda, aplaude, suspira, triste, enfadado, sorprendido,
  pensativo, mano en la barbilla, duda, serio, nervioso, avergonzado, cruza los brazos,
  brazos en jarra, se inclina, aparta la mirada, se lleva la mano a la frente, levanta una ceja, abraza.
  Otros gestos se aceptan, pero no se animan.
- **Pausas:** una línea `Pausa.` entre dos frases.
- **Género del jugador:** `{o/a}` en las palabras que cambian («Bienvenid{o/a}», «{un niño/una niña}»).
- **Elecciones:**

```
ELECCION — ¿Qué le dices?
A) «Texto de la opción»
-> Valentia +1
Abu: Lo que contesta si eliges A.
B) «Otra opción»
-> Empatia +1
Abu: Lo que contesta si eliges B.
```

  Rasgos que se pueden subir: Valentia, Empatia, Humor, Responsabilidad, Curiosidad, Creatividad,
  Deportividad, Rebeldia. Relación con un personaje: `-> Abu +5`.

## Cómo tiene que sentirse

Película interactiva, no chat: el personaje está haciendo algo, se gira, mira al jugador, habla con
gestos, hay silencios. Diálogos naturales, cortos, con personalidad. Nada de explicaciones robóticas.
Cada escena responde: ¿qué pasa?, ¿por qué?, ¿qué siente el personaje?, ¿qué ve y qué siente el jugador?

## Ejemplo corto

```
MISION: Siroco_01_HoraRoja — Tormenta de fuego

Resumen: El protagonista aterriza en Puerto Calcina justo al empezar la hora roja. Rafa le arrastra a su taller.

PASO 1 [Dialogo] @ Plataforma del Muelle de Velas
Reparto: RafaQuiroga
Musica: Tension
PLANO Medio -> RafaQuiroga | Rafa corre hacia la nave haciendo aspavientos.
RafaQuiroga: (sorprendido) ¡Eh! ¡Tú, el de la nave! ¿No ves la hora que es?
RafaQuiroga: (señala) Al taller. Por la sombra de los toldos.
```
