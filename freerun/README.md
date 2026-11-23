# Project Freerun

Juego móvil de parkour, freerunning, tricking y water tricks. Motor: **Godot 4.4** (renderer Compatibility / OpenGL ES 3, Android e iOS).

## Ejecutar

1. Instala [Godot 4.4.x](https://godotengine.org/download) (estándar, no hace falta .NET).
2. Abre `freerun/project.godot` y pulsa F5.

Atajos: `godot --path freerun -- --mode=freerun` salta el menú (`tricking`, `water`, `challenge`, `freestyle`); `-- --touch` fuerza los controles táctiles en escritorio.

## Controles

| Acción | Móvil | Teclado / ratón | Mando |
|---|---|---|---|
| Mover | Joystick izquierdo (aparece donde apoyas el pulgar; a fondo = sprint) | WASD (+Shift sprint) | Stick izq. |
| Saltar / vault / trepar | SALTO | Espacio | A |
| Wall run | Mantener SALTO junto a una pared corriendo | Mantener Espacio | Mantener A |
| Tic tac / wall climb | SALTO otra vez en el aire contra la pared | Espacio | A |
| Acrobacia | Deslizar rápido en el lado derecho: ↓ backflip, ↑ frontflip, ←→ lateral, diagonal = con tirabuzón | Flechas | X / Y / LB / RB |
| Agruparse (girar más rápido) | Mantener el dedo tras el gesto | Mantener la flecha | Mantener |
| Rodar / soltarse del borde | Botón contextual | Ctrl / C | B |
| Cámara | Arrastrar despacio en el lado derecho | Ratón (clic para capturar) / Q E | Stick der. |
| Reaparecer | ↺ | R | Back |

Ayuda de rotación (Ajustes): **Alta** calibra el giro para aterrizar, **Pro** gira a velocidad fija y tú decides cuándo abrirte.

## Pruebas

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
- **iOS**: requiere macOS con Xcode. Project → Export → iOS genera un proyecto Xcode que se firma y compila en el Mac.
