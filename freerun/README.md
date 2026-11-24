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

**Móvil (iPhone / Android) — Doble joystick (por defecto)**: joystick izquierdo, **rueda de SALTO/MORTALES**, **joystick GIRO** y VAULT, AGARRAR, RODAR.
- **Joystick izquierdo** (abajo a la izquierda): moverse de forma analógica; a fondo = sprint (se acumula corriendo recto).
- **Rueda de SALTO** (encima del joystick derecho): el **centro** es SALTO (mantener junto a una pared = Wall Run; en el aire junto a una pared = Tic Tac). Las cuatro zonas de alrededor saltan y hacen su mortal: **ATRÁS** (Backflip; corriendo, Gainer), **ADELANTE** (Frontflip; corriendo, Webster) y **LATERAL ← →** (Sideflip, siempre encogido; **corriendo, el atleta se pone de lado antes de despegar y avanza girando, mirando al lado**). Mantener el dedo en la zona = agruparse (gira más rápido); soltarlo = abrirse y preparar el aterrizaje. Pulsar otra zona igual en el aire = otra vuelta (doble). **La rueda solo hace saltos y mortales: nunca gira** (ni el centro pulsado otra vez en el aire ni la zona LATERAL durante un mortal); los tirabuzones y giros son exclusivamente del joystick GIRO.
- **Joystick GIRO** (derecho): controla el tirabuzón de **todos** los mortales. Inclinado a un lado gira (más inclinado = más rápido); al soltarlo termina en el cuarto de vuelta más cercano: **¼ = Híper** (aterriza de lado), **½** (Back Half, Árabe, Raiz…), **1** (Back Full, Front Full…), 1½, 2… Corriendo, **ATRÁS + una vuelta de GIRO = Cork**; dos vueltas = Cork 720. Sin mortal, en el aire = pirueta / patada giratoria; tocarlo sin inclinar = un giro completo.
  - **En el suelo** (sin saltar) el joystick derecho reconoce gestos y contexto (`scripts/input/gesture_interpreter.gd`):
    - **Inclinar y soltar** (flick): ← → **Rueda** · ↙ ↘ **Rondada** · ↓ **Flic-flac** · ↑ **Paloma** · ↗ 360 Kick / Tornado · ↖ Aerial (parado) / Butterfly (con carrera).
    - **Mantener** (0,5 s): ↓ **Back Walkover** · ↑ **Pino** (se sostiene mientras no sueltes; al soltar, **Front Walkover**; SALTO = **Handstand Push-off / snap down**) · ← → **Raiz** · ↖ ↗ **Touchdown Raiz** · ↙ ↘ **Macaco**.
    - **Arco** (girar el joystick ≥ 135°): por arriba = **Crescent** (de derecha a izquierda) o **Reverse Crescent** (de izquierda a derecha); por abajo = **Hook Kick**.
    - **Cambio de dirección** (← y enseguida →): **Scoot**.
    - **RODAR casi parado** con ↓ = **Back Extension Roll**; con ↙ ↘ = **Valdez**. **Tumbado tras una caída**: SALTO o ↑ = **Kip-up**.
  - **Enlaces**: cada habilidad abre una **ventana de enlace** al recibir con los pies (el HUD muestra «¡ENLAZA!»). Un gesto hecho durante la habilidad queda en cola y sale en la recepción; la rueda salta con el rebote. Ejemplos: Rondada → Flic-flac → Backflip / Double Backflip / Cork / Double Cork, Flic-flac → Flic-flac, Macaco → Flic-flac o Backflip, Hook → Cork, Raiz → Cork, TD Raiz → Butterfly Twist, Scoot → B-Twist, Aerial → Butterfly, Rueda → Backflip, Crescent → Swing Gainer. SALTO sin mortal en la recepción = *Rebound* (rebote vertical).
- **VAULT**: supera el obstáculo con la técnica viable según velocidad, ángulo y forma (Step, Speed, Lazy, Kong, Dash, Step Up). Con el joystick derecho inclinado elige variante: ← → Reverse Vault, ↑ Double Kong, ↓ Kash Vault, ↖ ↗ Thief Vault (obstáculo estrecho y con carrera), ↙ ↘ Turn Vault (cae frenado de cara al obstáculo). Si el obstáculo no permite la variante, hace la técnica normal. Ante una pared alta, trepa.
- **AGARRAR**: junto a una pared alta, trepar; en el aire, agarrar el borde (si ya estás casi vertical); colgado se convierte en **SOLTAR**.
- **RODAR**: Parkour Roll corriendo; justo antes de caer desde alto, Safety Roll.
- **En la pared** (wall run, wall climb o colgado): rueda ATRÁS = Wall Flip / Wall Gainer · ADELANTE = Wall Front · LATERAL = Wall Sideflip.
- **Cámara**: arrastra en cualquier zona libre de la pantalla (arriba, entre el centro y SALTO, donde pone CÁMARA, o la franja superior izquierda) para girarla mientras corres con el otro pulgar. **Doble toque** en esa zona = cámara detrás del atleta. Es híbrida: sigue al atleta y se alinea detrás del movimiento, pero respeta durante 2,5 s lo que hayas movido a mano; tras un tirabuzón vuelve sola detrás. Mando: stick derecho y clic del stick izquierdo para recentrar; teclado: Q/E y T.
- **FLOW** (barra arriba en el centro): sube con movimientos distintos, dificultad, uso del entorno (vaults, paredes, agarres, precisión), aterrizajes limpios y continuidad; baja al repetir el mismo truco, aterrizar forzado o duro, pararse o caerse. Por encima de 60 (EN FLOW) da un extra pequeño: velocidad punta +6 %, salto +4 % y recuperación más rápida.
- **Carrera acumulada**: el sprint completo se gana corriendo recto (~1 s); un giro cerrado, frenar o una mala recepción lo reducen. Desde parado hacia atrás, el atleta gira sobre sí mismo antes de acelerar.
- **Menú de pausa**: Reaparecer, **Movimientos** (biblioteca con más de 100 técnicas por categoría, su entrada y su estado) y **Tutorial de controles** (16 pasos que avanzan al hacer cada movimiento de verdad).

**Otros modos (Ajustes → Controles de trucos)**: *Solo gestos*, *Solo cruceta* y *Gestos + cruceta*.
- Gestos: pulsa SALTO y, sin levantar el dedo, deslízalo (mismas direcciones que el joystick derecho). Deslizar dos veces igual = doble. En el aire, la zona derecha también acepta gestos.
- Cruceta TRUCOS: pulsar = truco, mantener = agruparse, tocar LATERAL durante un mortal = tirabuzón, centro = GIRO. Las direcciones principales tienen zonas más grandes que las diagonales.
- Volver a pulsar SALTO en el aire: sin mortal = patada giratoria (360 Kick / Tornado Kick, cada toque suma media vuelta: 540, 720 / Cheat 720, 900, 1080); durante un mortal = tirabuzón completo.
- Gesto justo antes de un vault: lateral = Reverse Vault; en caja de kong ↑ = Double Kong, ↓ = Kash Vault. Gesto durante el vault = mortal al salir (Kong Gainer, Dash Bomb, Kong Front...).

**Teclado**: WASD + Shift · Espacio salto (mantener: wall run; otra vez en el aire = giro) · Flechas = mortales (mantener = agrupado; tricking de suelo si las mantienes sin saltar) · U / O = GIRO izquierda / derecha · V vault · G agarrar · Ctrl rodar · R reaparecer. Mando: gatillos = GIRO.

Ajustes: ayuda de rotación (Alta / Media / Pro), controles de trucos (doble joystick / solo gestos / solo cruceta / gestos + cruceta), tamaño de controles, cámara (híbrida / manual / automática), distancia y altura de cámara, opacidad, sensibilidad de cámara y del joystick derecho / gestos, y modo zurdo.

**Habilidades con apoyo** (`scripts/player/skill_library.gd`): rondada, flic-flac, paloma, rueda, macaco, walkovers, valdez, back extension roll, kip-up, pino y snap down, hook, crescents, raiz, touchdown raiz y scoot. Cada una tiene **fases con nombre**, la orientación del cuerpo, la altura del centro de masas, una forma corporal por fase y qué manos o pies apoyan. El rig **clava la mano en un punto del suelo** y resuelve brazo y pierna con **IK de dos huesos** mientras el cuerpo gira por encima. Ninguna mano ni pie puede quedar por debajo del suelo en ningún estado. El backflip no apoya las manos; el flic-flac sí.

**Potencia** (`SkillLibrary.power` + `scripts/player/chain_system.gd`). Cada técnica define estos parámetros:
- velocidad de desplazamiento: mínima/máxima y fracción conservada de la velocidad de entrada;
- impulso de piernas y bloqueo de brazos;
- conversión de velocidad horizontal en vertical;
- caída del centro de masas en la recepción (de ahí sale la velocidad de recepción);
- elasticidad (rebote disponible);
- estabilidad;
- giro de salida.

Al enlazar, el siguiente movimiento hereda:
- **rebote**: altura que sale de la recepción, no un multiplicador; tope de 3,2 m/s;
- **giro**: un hook, raiz o scoot acelera el tirabuzón con GIRO un 30 %;
- **barrido**: la pierna lanzada da la rotación de un butterfly o un gainer;
- **velocidad de salida**.

El timing cuenta: el rebote completo solo existe al principio de la ventana. Una transición incoherente (rondada → paloma) no hereda nada.

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
  input/     InputIntent + InputRouter: teclado, mando, táctil y bots → una intención por frame;
             GestureInterpreter (flick, mantener, arco, cambio de dirección, doble, soltar)
  player/    PlayerController (núcleo único de movimiento), MoveTuning, ObstacleSensor,
             TrickSystem (rotaciones aéreas), SkillLibrary (habilidades de suelo por fases),
             ChainSystem (ventanas de enlace y transferencia de potencia),
             BodyRig (personaje, animación procedural e IK de apoyos)
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

`scripts/core/move_library.gd` (en el juego: Pausa → Movimientos) cataloga 125 técnicas en 18 categorías: vaults, precision, paredes, escalada, barras, rolls, mortales, laterales, aerials y websters, gainers, corks, butterfly y patadas, tricking, handsprings, ruedas y rondadas, suelo, combos y avanzados.

- **Estado**: 90 hechas (impulso, trayectoria y postura propias, con prueba), 12 parciales (se reconocen y rotan bien, pero comparten postura con su familia) y 23 pendientes (Master Scoot incluido: no he podido verificar su técnica) (cada una con el motivo; las de barra necesitan barras en el mapa).
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
