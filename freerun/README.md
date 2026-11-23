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

**Móvil (iPhone / Android)**
- **Joystick izquierdo**: moverse (a fondo = sprint).
- **SALTO**: pulsa para saltar. **Sin levantar el dedo, deslízalo** para hacer una acrobacia:
  ↓ Backflip · ↑ Frontflip · ← → Sideflip/Aerial · ↙ ↘ Cork · ↖ ↗ Butterfly Kick.
  Con carrera: Gainer, Webster y Aerial.
- **Mantén el dedo** = agruparse y girar más rápido (dobles). **Suelta** = abrirse y preparar el aterrizaje.
- Durante el mortal, **otro deslizamiento lateral** añade tirabuzón (Backflip → Cheat Gainer, Cork → Cork 720).
- **Cruceta TRUCOS**: lo mismo con botones (pulsar = truco, mantener = agruparse, arrastrar a un lado = tirabuzón).
- **Zona derecha**: en el suelo mueve la cámara; en el aire controla el cuerpo.
- **RODAR**: pulsar justo antes de caer desde alto (Safety Roll). **↻**: reaparecer.
- Indicador en el aire: nombre del truco, grados y dial (zona verde = vertical para aterrizar).

**Teclado**: WASD + Shift · Espacio salto (mantener: wall run) · Flechas = acrobacias (mantener = agruparse) · Ctrl rodar · R reaparecer.

Ajustes: ayuda de rotación (Alta / Media / Pro), controles de trucos (gestos + cruceta / solo gestos / solo cruceta), tamaño de controles, distancia de cámara, opacidad, sensibilidad de cámara y de gestos, y modo zurdo.

Cada acrobacia se anima por fases a partir del giro real: preparación (flexión antes de despegar), impulso, agrupación, rotación, apertura y recepción, con una forma corporal propia para Backflip, Frontflip, Sideflip, Aerial, Gainer, Webster, Butterfly Kick, Cork y tirabuzones.

## Pruebas

Aceptación de acrobacias por la ruta táctil real (joystick + SALTO deslizando), criterio a criterio:
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
