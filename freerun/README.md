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

**Móvil (iPhone / Android) — Doble joystick (por defecto)**
- **Joystick izquierdo** (pulgar izquierdo): moverse de forma analógica en 8+ direcciones; cuanto más lo inclinas, más rápido; a fondo = sprint.
- **SALTO** (abajo a la derecha): pulsa para saltar.
- **Joystick derecho** (esquina inferior derecha): rotación del cuerpo.
  - Inclinarlo arranca la acrobacia: ↓ Backflip · ↑ Frontflip · ← → Sideflip (siempre encogido) · ↙ ↘ mortal atrás + tirabuzón (Cork) · ↗ mortal adelante + tirabuzón (Front Full) · ↖ adelante + giro lateral: Aerial (parado) o Butterfly Kick (con carrera). Con carrera ↓/↑ = Gainer / Webster.
  - Es analógico: cuanto más lo inclinas hacia el giro, más se agrupa el cuerpo y más rápido gira (poco a poco, no de golpe). Soltarlo abre el cuerpo; tirar en sentido contrario frena el giro y prepara el aterrizaje.
  - Mantenerlo inclinado no repite el truco. **Volver al centro e inclinar otra vez** = otra vuelta (Double Backflip, Double Cork). Llevarlo a un lado durante un mortal = tirabuzón (Cork 720, Back Full...).
  - Inclinarlo antes de saltar: el mortal sale en el despegue. **Tocarlo sin inclinar** = GIRO (360 Kick, o tirabuzón completo durante un mortal).
- **AGRUPAR** (pulgar izquierdo, encima del joystick): agrupado total mientras lo mantienes (rodillas al pecho, gira más rápido). Funciona a la vez que el joystick derecho.
- **RODAR**: pulsar justo antes de caer desde alto (Safety Roll). **↻**: reaparecer.
- Arrastrar fuera de los controles = cámara (en este modo nunca lanza trucos).
- También funcionan los gestos sobre SALTO: sin levantar el dedo, deslízalo en una dirección.
- Indicador en el aire: nombre del truco, grados y dial (zona verde = vertical para aterrizar).

**Otros modos (Ajustes → Controles de trucos)**: *Solo gestos*, *Solo cruceta* y *Gestos + cruceta*.
- Gestos: pulsa SALTO y, sin levantar el dedo, deslízalo (mismas direcciones que el joystick derecho). Deslizar dos veces igual = doble. En el aire, la zona derecha también acepta gestos.
- Cruceta TRUCOS: pulsar = truco, mantener = agruparse, tocar LATERAL durante un mortal = tirabuzón, centro = GIRO. Las direcciones principales tienen zonas más grandes que las diagonales.
- Volver a pulsar SALTO en el aire: sin mortal = patada giratoria (360 Kick / Tornado Kick, cada toque suma media vuelta: 540, 720 / Cheat 720, 900, 1080); durante un mortal = tirabuzón completo.
- Gesto justo antes de un vault: lateral = Reverse Vault; en caja de kong ↑ = Double Kong, ↓ = Kash Vault. Gesto durante el vault = mortal al salir (Kong Gainer, Dash Bomb, Kong Front...).

**Teclado**: WASD + Shift · Espacio salto (mantener: wall run; otra vez en el aire = giro) · Flechas = acrobacias (mantener = agruparse) · Ctrl rodar · R reaparecer.

Ajustes: ayuda de rotación (Alta / Media / Pro), controles de trucos (doble joystick / solo gestos / solo cruceta / gestos + cruceta), tamaño de controles, distancia de cámara, opacidad, sensibilidad de cámara y del joystick derecho / gestos, y modo zurdo.

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
  combo/     ComboSystem (multiplicador, variedad, repetición, velocidad, continuidad)
  modes/     GameModes: Freerun, Tricking, Water, Challenge (con ghost), Freestyle
  level/     LevelBuilder (escenario de pruebas) + shaders/world_grid
  ui/        GameUI (HUD, menús, ajustes), TouchControls
```
El `InputIntent` es la frontera entre dispositivos y personaje: replays, ghosts y un futuro multijugador pueden alimentar al mismo controlador.

## Exportar

- **Android**: Godot → Editor → Manage Export Templates; configura el SDK de Android y JDK 17 en Editor Settings; Project → Export → Android.
- **Web**: preset "Web" sin hilos (compatible con Safari/iOS y GitHub Pages). Se publica sola al subir cambios a `main`.
- **iOS**: requiere macOS con Xcode. Project → Export → iOS genera un proyecto Xcode que se firma y compila en el Mac.

## Trucos reconocidos

- **Mortales atrás**: Backflip, Gainer, Double Backflip/Gainer, Triple Backflip, Back Half, Cheat Gainer, Back Full, Gainer Full, Back 1.5, Double Full, Full In, Cork, Cork 540, Cork 720, Cork 1080, Double Cork, Triple Cork.
- **Mortales adelante**: Frontflip, Webster, Double/Triple Front, Arabian, Front Full, Rudi, Front Double Full, Double Arabian.
- **Laterales**: Sideflip (bola cerrada, con o sin carrera), Double Sideflip, Raiz, Aerial Twist, Aerial Double Twist.
- **Butterfly**: Butterfly Kick, Double Butterfly, Butterfly Twist, Butterfly Twist 720.
- **Patadas giratorias**: 360 Kick, Tornado Kick, 540 Kick, 720 Kick, Cheat 720, 900 Kick, 1080 Kick.
- **Desde pared y vault**: Wall Flip, Wall Gainer, Wall Front, Wall Full, Wall Half, Wall Sideflip, Kong Gainer, Dash Gainer, Vault Gainer, Dash Bomb, Kong Front, Ledge Backflip.
- **Parkour**: Speed, Kong, Double Kong, Kash, Dash, Lazy, Reverse, Step Vault, Step Up, Climb Up, Wall Run, Tic Tac, Wall Climb, Cat Leap, Mantle, Shimmy, Precision Jump, Drop Landing, Safety Roll.
