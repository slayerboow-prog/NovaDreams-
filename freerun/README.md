# Project Freerun

Juego móvil de parkour, freerunning, tricking y water tricks. Motor: **Godot 4.4** (renderer Compatibility / OpenGL ES 3, Android e iOS).

## Jugar en el móvil

- **Web (iPhone y Android)**: https://slayerboow-prog.github.io/NovaDreams-/ — gira el móvil en horizontal. En iPhone: Compartir → *Añadir a pantalla de inicio* para jugar a pantalla completa como una app.
- **Android (APK)**: Actions → última ejecución de "Freerun" → Artifacts → `ProjectFreerun-android`.

## Ejecutar en PC

1. Instala [Godot 4.4.x](https://godotengine.org/download) (estándar, no hace falta .NET).
2. Abre `freerun/project.godot` y pulsa F5.

Atajos: `godot --path freerun -- --mode=freerun` salta el menú (`tricking`, `water`, `challenge`, `freestyle`); `-- --touch` fuerza los controles táctiles en escritorio.

## Controles

**Móvil (iPhone / Android) — Doble joystick (por defecto)**: dos joysticks y solo cuatro botones (SALTO, VAULT, AGARRAR, RODAR). No hay un botón por truco: los trucos salen del joystick derecho según el contexto.
- **Joystick izquierdo** (abajo a la izquierda): moverse de forma analógica; cuanto más lo inclinas, más rápido; a fondo = sprint.
- **SALTO** (grande, encima del joystick derecho): saltar e impulsarse. Mantenerlo junto a una pared = Wall Run; en el aire junto a una pared = Tic Tac.
- **VAULT**: supera el obstáculo con la técnica viable según velocidad, ángulo y forma (Step, Speed, Lazy, Kong, Dash, Step Up). Con el joystick derecho inclinado elige variante: ← → Reverse Vault, ↑ Double Kong, ↓ Kash Vault, ↖ ↗ Thief Vault (paso de ladrón: obstáculo estrecho y con carrera, piernas primero), ↙ ↘ Turn Vault (paso con giro: media vuelta sobre las manos, cae frenado de cara al obstáculo). Si el obstáculo no permite la variante (p. ej. Thief en una caja profunda), hace la técnica normal. Ante una pared alta, trepa.
- **AGARRAR**: junto a una pared alta, trepar; en el aire, agarrar el borde (aunque vengas de un giro, si ya estás casi vertical); colgado se convierte en **SOLTAR**.
- **RODAR**: Parkour Roll corriendo; justo antes de caer desde alto, Safety Roll.
- **Joystick derecho** (abajo, a la derecha del centro):
  - **En el aire** (tras SALTO): ↓ Backflip · ↑ Frontflip · ← → Sideflip (siempre encogido) · ↙ ↘ Cork · ↗ Front Full · ↖ Aerial (parado) o Butterfly Kick (con carrera). Con carrera ↓/↑ = Gainer / Webster. Es analógico: más inclinado hacia el giro = más agrupado y más rápido; soltarlo abre el cuerpo; en contra frena. Volver al centro e inclinar otra vez = otra vuelta; a un lado durante un mortal = tirabuzón; tocarlo sin inclinar = GIRO.
  - **En el suelo** (sin SALTO, mantenlo inclinado un instante): ← → **Cartwheel** · ↙ ↘ **Round-off** (cae mirando atrás y deja un rebote: el siguiente salto sale un 15 % más alto, ideal para Round-off → Backflip) · ↓ **Back Handspring** (también rebota) · ↑ **Front Handspring** · ↗ 360 Kick / Tornado · ↖ Aerial / Butterfly Kick.
  - **Ante un obstáculo** el joystick elige la variante del vault en vez de hacer un movimiento de suelo.
  - **En la pared** (wall run, wall climb o colgado): ↓ Wall Flip / Wall Gainer · ↑ Wall Front · lateral = con giro.
- **Tras una caída**: SALTO = **Kip-up** (te levantas al momento).
- **Cámara**: arrastra en cualquier zona libre de la pantalla (arriba, entre el centro y SALTO, donde pone CÁMARA, o la franja superior izquierda) para girarla mientras corres con el otro pulgar. **Doble toque** en esa zona = cámara detrás del atleta. Es híbrida: sigue al atleta y se alinea detrás del movimiento, pero respeta durante 2,5 s lo que hayas movido a mano; tras un tirabuzón vuelve sola detrás. Mando: stick derecho y clic del stick izquierdo para recentrar; teclado: Q/E y T.
- **FLOW** (barra arriba en el centro): sube con movimientos distintos, dificultad, uso del entorno (vaults, paredes, agarres, precisión), aterrizajes limpios y continuidad; baja al repetir el mismo truco, aterrizar forzado o duro, pararse o caerse. Por encima de 60 (EN FLOW) da un extra pequeño: velocidad punta +6 %, salto +4 % y recuperación más rápida.
- **Carrera acumulada**: el sprint completo se gana corriendo recto (~1 s); un giro cerrado, frenar o una mala recepción lo reducen. Desde parado hacia atrás, el atleta gira sobre sí mismo antes de acelerar.
- **Menú de pausa**: Reaparecer, **Movimientos** (biblioteca con más de 100 técnicas por categoría, su entrada y su estado) y **Tutorial de controles** (10 pasos que avanzan al hacer cada movimiento de verdad).

**Otros modos (Ajustes → Controles de trucos)**: *Solo gestos*, *Solo cruceta* y *Gestos + cruceta*.
- Gestos: pulsa SALTO y, sin levantar el dedo, deslízalo (mismas direcciones que el joystick derecho). Deslizar dos veces igual = doble. En el aire, la zona derecha también acepta gestos.
- Cruceta TRUCOS: pulsar = truco, mantener = agruparse, tocar LATERAL durante un mortal = tirabuzón, centro = GIRO. Las direcciones principales tienen zonas más grandes que las diagonales.
- Volver a pulsar SALTO en el aire: sin mortal = patada giratoria (360 Kick / Tornado Kick, cada toque suma media vuelta: 540, 720 / Cheat 720, 900, 1080); durante un mortal = tirabuzón completo.
- Gesto justo antes de un vault: lateral = Reverse Vault; en caja de kong ↑ = Double Kong, ↓ = Kash Vault. Gesto durante el vault = mortal al salir (Kong Gainer, Dash Bomb, Kong Front...).

**Teclado**: WASD + Shift · Espacio salto (mantener: wall run; otra vez en el aire = giro) · Flechas = joystick derecho (acrobacias en el aire, tricking de suelo si las mantienes sin saltar) · V vault · G agarrar · Ctrl rodar · R reaparecer.

Ajustes: ayuda de rotación (Alta / Media / Pro), controles de trucos (doble joystick / solo gestos / solo cruceta / gestos + cruceta), tamaño de controles, cámara (híbrida / manual / automática), distancia y altura de cámara, opacidad, sensibilidad de cámara y del joystick derecho / gestos, y modo zurdo.

Cada acrobacia tiene su propio ritmo de giro (backflip explosivo; aerial y butterfly más amplios), el doble mortal gira más rápido que el simple, y se anima por fases a partir del giro real: preparación (flexión antes de despegar), impulso, agrupación, rotación, apertura y recepción, con una forma corporal propia para Backflip, Frontflip, Sideflip, Gainer, Webster, Butterfly Kick, Cork y tirabuzones.

## Pruebas

Aceptación de acrobacias por la ruta táctil real (gestos sobre SALTO y doble joystick, multitáctil), criterio a criterio (`-- --only=joystick` para una parte, `-- --capture=dir` para grabar):
```
godot --headless --fixed-fps 60 --path freerun res://tests/acceptance_tricks.tscn
```

```
godot --headless --fixed-fps 60 --path freerun res://tests/test_runner.tscn
```
Un bot conduce al personaje con el mismo `InputIntent` que los controles reales y valida carrera, salto, mortales, sobre-rotación, vaults, wall run, bordes, caídas con y sin rodar, precisión, agua, gestos táctiles, combos, reaparición y modos.

Capturas (necesita pantalla o Xvfb): `xvfb-run godot --rendering-driver opengl3 --path freerun res://tests/screenshots.tscn -- --out=/tmp/shots`

## Arquitectura

```
scripts/
  core/      game.gd (orquestador), settings.gd y save_data.gd (autoloads)
  input/     InputIntent + InputRouter: teclado, mando, táctil y bots → una intención por frame
  player/    PlayerController (núcleo único de movimiento), MoveTuning, ObstacleSensor,
             TrickSystem (rotaciones aéreas), BodyRig (personaje y animación procedural)
  camera/    CameraRig
  combo/     ComboSystem (puntuación: multiplicador, variedad, repetición, velocidad, continuidad)
             FlowSystem (medidor FLOW 0-100 y su pequeño extra al atleta)
  modes/     GameModes: Freerun, Tricking, Water, Challenge (con ghost), Freestyle
  level/     LevelBuilder (escenario de pruebas) + shaders/world_grid
  ui/        GameUI (HUD, menús, ajustes), TouchControls
```
El `InputIntent` es la frontera entre dispositivos y personaje: replays, ghosts y un futuro multijugador pueden alimentar al mismo controlador.

## Exportar

- **Android**: Godot → Editor → Manage Export Templates; configura el SDK de Android y JDK 17 en Editor Settings; Project → Export → Android.
- **Web**: preset "Web" sin hilos (compatible con Safari/iOS y GitHub Pages). Se publica sola al subir cambios a `main`.
- **iOS**: requiere macOS con Xcode. Project → Export → iOS genera un proyecto Xcode que se firma y compila en el Mac.

## Biblioteca de movimientos

En el juego los nombres se muestran en español (Mortal atrás, Rondada, Flic-flac, Salto de gato…); `scripts/core/move_names.gd` guarda la traducción y por dentro se usa el nombre original.

`scripts/core/move_library.gd` (en el juego: Pausa → Movimientos) cataloga 102 técnicas en 17 categorías: vaults, precision, paredes, escalada, barras, rolls, mortales, laterales, aerials y websters, gainers, corks, butterfly y patadas, handsprings, ruedas y rondadas, suelo, combos y avanzados.

- **Estado**: 63 hechas (impulso, trayectoria y postura propias, con prueba), 14 parciales (se reconocen y rotan bien, pero comparten postura con su familia) y 25 pendientes (cada una con el motivo; las de barra necesitan barras en el mapa).
- **Validación en 5 niveles** (no se confunden): 1 documentado · 2 implementado · 3 probado técnicamente · 4 inspeccionado visualmente · 5 validado en móvil. Ninguno está en 5 hasta que se confirme en un iPhone.
- **Fuentes**: nombres, variantes y niveles de [pkfr.world/tutorials](https://pkfr.world/tutorials/) y [trickipedia.app](https://www.trickipedia.app/). Ninguna describe la técnica en texto y sus vídeos no se han podido ver, así que la biomecánica del juego se basa en la técnica deportiva estándar.

## Referencia de diseño: STORROR Parkour PRO

Se usa como referencia de filosofía (control del cuerpo, timing, continuidad, flow), no de código ni recursos.
- **Comprobado públicamente**: la página de Steam (capturas de movimiento combinadas con movimiento por físicas, libertad para elegir qué y cuándo) y las notas de parche visibles en Steam (existe un estado *flow*, dive roll, detección de bordes, retícula de escalada/dyno, físicas del balanceo). Esas notas no explican cómo se construye el flow, la cámara ni los controles en detalle.
- **No comprobado**: los vídeos de YouTube y las notas de parche más antiguas no se han podido ver desde este entorno. Lo que aquí se implementa (flow, cámara híbrida, carrera acumulada) es diseño propio inspirado en esos principios.

## Trucos reconocidos

- **Mortales atrás**: Backflip, Gainer, Double Backflip/Gainer, Triple Backflip, Back Half, Cheat Gainer, Back Full, Gainer Full, Back 1.5, Double Full, Full In, Cork, Cork 540, Cork 720, Cork 1080, Double Cork, Triple Cork.
- **Mortales adelante**: Frontflip, Webster, Double/Triple Front, Arabian, Front Full, Rudi, Front Double Full, Double Arabian.
- **Laterales**: Sideflip (bola cerrada, con o sin carrera), Double Sideflip, Raiz, Aerial Twist, Aerial Double Twist.
- **Butterfly**: Butterfly Kick, Double Butterfly, Butterfly Twist, Butterfly Twist 720.
- **Patadas giratorias**: 360 Kick, Tornado Kick, 540 Kick, 720 Kick, Cheat 720, 900 Kick, 1080 Kick.
- **Desde pared y vault**: Wall Flip, Wall Gainer, Wall Front, Wall Full, Wall Half, Wall Sideflip, Kong Gainer, Dash Gainer, Vault Gainer, Dash Bomb, Kong Front, Ledge Backflip.
- **Parkour**: Speed, Kong, Double Kong, Kash, Dash, Lazy, Reverse, Step Vault, Step Up, Climb Up, Wall Run, Tic Tac, Wall Climb, Cat Leap, Mantle, Shimmy, Precision Jump, Drop Landing, Safety Roll.
