# Espacio «AAA»: auditoría y diseño técnico (fases 1 a 6)

Encargo: `encargo.md`. Referencia visual: `referencia-hud.png` (en el juego **nunca** sale «Nova» ni el
nombre de la imagen: el sistema es el **Sistema Valmar**, con los planetas Lontana, Ocrea, Marena, Velaria,
Fronda, Zéfira y Mercadia y las estaciones Alba y Cénit).

Esta tanda hace las fases **1 a 6** (auditoría, vuelo, HUD y mandos, impulso/freno/esquiva,
hipervelocidad y salto cuántico). Las fases 7 a 11 (más combate, camuflaje, drones, integración y pulido)
van en la siguiente: sus huecos ya salen en el HUD, **bloqueados** («Próximamente»), nunca como botones
que no hacen nada.

## 1. Lo que ya existía (auditoría)

| Pieza | Qué hace | Estado |
|---|---|---|
| `shared/AirCombat/ShipFlight` | Modelo de vuelo arcade: motor, cabeceo/guiñada/alabeo con autonivelación, turbo con su energía y enfriamiento, freno con giro cerrado, modos Atmos/Space, choques, límites y `plausible` (servidor). | Funciona. Faltaba: lateral, vertical, freno de emergencia, modos combate/crucero, asistencia apagable, inercia, choques «suaves» y recuperación, choques barridos (a mucha velocidad se podía saltar un asteroide entre dos fotogramas). |
| `shared/AirCombat/Shields` | Escudo + casco, regeneración. | Funciona (sin cambios). |
| `shared/AirCombat/ShipWeapons` | Láser (cadencia, calor), misiles (munición, recarga, guiado). | Funciona. Faltaba: segundo modo (láser de precisión) y recargar a mano. |
| `shared/AirCombat/Lock`, `EnemyAI`, `Waves`, `Arena`, `FxBudget` | Fijación, IA, oleadas, arena, topes de efectos. | Funcionan (sin cambios de fondo). |
| `shared/AirCombat/ShipModel` | Caza de ala en delta, 2 motores, cabina con el piloto dentro. | Funciona; silueta distinta de la referencia → se rehace (ver §6). |
| `shared/Cosmos/*` | Capas de altura, zona (asteroides, sectores, estaciones), estaciones, misiones, minería, planetas (cuerpos y registro), entrada en la atmósfera, Lontana. | Funcionan. Las estaciones no eran sólidas (solo apartaban). |
| `AirCombatService` | Sesión de la nave: «Pose» validada (CFrame anclado), disparos, misiles, daño, enemigos, `relocate` (pasar de sitio sin cortar el vuelo). | Funciona. Sin recurso de energía ni habilidades. |
| `SpaceService` / `PlanetService` | Subir/bajar, estaciones, minería, patrullas, misiones, tienda, planetas (Lontana). | Funcionan. Las Chispas y las misiones no llegaban al cliente (solo en la línea del objetivo). |
| `AirCombatClient` | Mandos, predicción, cámara, fijación. | Funciona. Teclas: X salía (choca con «X salto» del encargo), F misil (choca con «F interactuar»), Espacio disparaba (choca con «Espacio acelerar/subir»), 1-8 equipaban la barra rápida aunque estuviera escondida. |
| `AirCombatHud` | Panel VEL/TURBO/ESCUDO/CASCO/MISILES + radar (solo enemigos) + mira y fijación. | **Solo visual en parte**: el radar no enseñaba estaciones, planetas ni objetivos; no había brújula, perfil, misiones ni barra de habilidades. |
| `ShipButtons` | FUEGO, MISIL, TURBO, FRENO, Salir (móvil). | Funcionan; faltaban ESQUIVA y los de habilidades. |
| `UI/FlightStick`, `UI/FlightFocus`, `UI/TopStack`, `HudLayout` | Palanca táctil propia, HUD de Valmar apartado al volar, letreros de arriba, colocación. | Funcionan (se amplían, no se sustituyen). |
| Datos | `data.Space`: Chispas, Ore, Missions, Mined, Kills, Done, Planets. | Se añade `data.Space.Found` (puntos de interés descubiertos); con valor por defecto, las partidas viejas no pierden nada. |
| Sonidos | `Config.Sounds` `Nave*` (sonidos de Roblox y nuestros `motor`/`choque_*`). | Se reutilizan: ningún id nuevo. |

**Arquitectura que se mantiene:** un solo controlador mueve la nave (el cliente, por CFrame, anclada,
`ShipFlight`), y el servidor valida cada «Pose» (`ShipFlight.plausible` + geometría). Nada de física ni de
dueño de red. Disparos, daño, munición, energía, recargas, habilidades y saltos los decide el servidor.

## 2. Diseño por fases

### Fase 2 · Vuelo (`ShipFlight`, ampliado y compatible)

- Entradas nuevas: `Strafe` (lateral), `Lift` (vertical), `EBrake` (freno de emergencia).
- Estado nuevo: `Drift` (velocidad aparte del morro: lateral, vertical, esquiva e inercia), `FlightMode`
  (`"Combat"` | `"Cruise"`), `Assist` (asistencia de vuelo), `RecoverUntil`.
- **Combate**: velocidad normal, gira mejor, lateral entero. **Crucero**: +45 % de velocidad máxima, gira
  peor, poco lateral.
- **Asistencia** encendida: la deriva se frena sola y la nave se nivela. Apagada: **inercia controlada**
  (al girar, parte de la velocidad sigue en la dirección de antes y se pierde despacio).
- **Freno de emergencia**: en el espacio la nave se puede quedar quieta (flotando); en la atmósfera, a la
  velocidad mínima (se hunde, como antes).
- **Choques barridos**: cada paso se comprueba el segmento entero (muestras cada radio de la nave), así
  que a la velocidad de la hipervelocidad tampoco se atraviesa nada.
- **Choques suaves y recuperación**: despacio contra algo (estaciones, ahora sólidas; asteroides; suelo),
  la nave rebota, pierde velocidad y durante un momento la asistencia la endereza («Bump»); deprisa,
  estalla como siempre («Crash»).
- Servidor: `plausible` admite un margen extra (esquiva, hipervelocidad) solo cuando el servidor ha
  aprobado esa habilidad.

### Fase 3 · HUD por zonas y mandos

Un HUD nuevo para la nave (`UI/AirCombatHud`, mismo nombre y API; las cuentas puras en
`UI/ShipHudLayout`), colocado sin pisarse en 1920x1080, 932x430, 844x390 y 640x360:

| Zona | Qué | De dónde salen los datos |
|---|---|---|
| A | Perfil: foto del avatar (miniatura de Roblox), nombre, nivel, dinero, ✨ Chispas | atributos `Level`/`Money` y «Nav» del servidor |
| B | Brújula que gira con el rumbo de la nave, sistema/zona/planeta, distancia al destino, estado del salto | rumbo del Root; zona y destino del servidor |
| C | Velocidad, impulso, energía, escudo, casco, misiles, recarga del arma, alertas | simulación local + «State» del servidor (10/s) |
| D | Radar con icono y color por tipo, solo lo que está dentro del alcance (combate 1400, crucero 4000) | enemigos, estaciones, planetas, campos, balizas, objetivo de misión, otros pilotos |
| E | Misiones: principal (historia), secundarias del tablón con progreso y distancia, eventos | `Hud.objective()` + «Nav» |
| F | Mira, fijación, distancia y amenaza del blanco, marcas de impacto, flechas en el borde | como antes, ampliado |
| G | Palanca táctil (solo táctil); en el ordenador, una tarjeta pequeña de teclas; con mando, sus botones | `UI/FlightStick` |
| H | Barra de 8 ranuras: cañones, misiles, láser, escudo especial 🔒, camuflaje 🔒, salto cuántico, hipervelocidad, dron 🔒 | estado del servidor |
| I | Botones grandes (táctil): DISPARO (el mayor), MISIL, IMPULSO, FRENO, ESQUIVA | `UI/ShipButtons` en `HudLayout.Fly` |
| J | Avisos solo cuando hacen falta: modo combate, daño, proximidad, motor, hipervelocidad, salto | eventos |

- Panel oscuro semitransparente azul/negro con bordes cian, impulso en naranja y lo hostil en rojo.
- El HUD se actualiza por eventos y a ritmo limitado (panel 10/s, radar 10/s, brújula 30/s), no cada
  etiqueta en cada fotograma.
- En el móvil, versión compacta (sin listas de teclas); en el ordenador, teclas; con mando, sus botones.

**Teclas** (tabla reasignable `shared/AirCombat/ShipKeys`; con el chat o un cuadro de texto escribiendo,
la nave no coge ninguna tecla):

| Acción | Ordenador | Mando | Móvil |
|---|---|---|---|
| Dirigir | ratón / flechas | stick izq. | palanca izquierda + arrastrar a la derecha (sensibilidad en ⚙️) |
| Motor + / − | W / S | cruceta ↑ / ↓ | crucero automático |
| Lateral | A / D | stick der. X | — |
| Subir / bajar | Espacio / Alt izq. | stick der. Y | — |
| Alabeo | Q / E | LB+stick / RS | automático |
| Disparar | clic izq. | RT | DISPARO |
| Precisión (mira fina y zoom) | clic der. | L3 | — |
| Misil | 2 (o clic central) | RB | MISIL |
| Impulso | Shift (mantener) | LB | IMPULSO |
| Hipervelocidad | 7, o mantener Shift fuera de combate | R3 | ranura 7 |
| Freno / freno de emergencia | Ctrl / doble Ctrl | LT / LT a fondo | FRENO / mantenerlo |
| Esquiva | C (con A/D/Espacio/Alt) | A (según el stick) | ESQUIVA |
| Salto cuántico | X (abre el selector) | Select | ranura 6 |
| Camuflaje | Z (🔒 próximamente) | — | ranura 5 🔒 |
| Recargar | R | cruceta ← | ranura del arma |
| Cañones / láser | 1 / 3 | cruceta → | ranuras 1 / 3 |
| Modo combate/crucero | T | — | chip del HUD |
| Asistencia de vuelo | Y | — | chip del HUD |
| Interactuar (atracar, viajar) | F (o G) | X | ATRACAR/VIAJAR |
| Volver a Valmar | V | Y | VALMAR |
| Bajarse / aterrizar | B | B | Salir |

Cambios respecto a antes (conflictos resueltos): Espacio ya no dispara (sube), F ya no lanza misiles
(interactúa), X ya no sale (salto cuántico; salir pasa a B, como en la referencia). Mientras pilotas, la
nave se queda 1-8 (no equipan la barra rápida, que está escondida).

### Fase 4 · Impulso, freno y esquiva

- **Energía** de la nave (nueva, del servidor): 100, se recarga sola tras 1,5 s sin gastar. La gastan la
  esquiva, la hipervelocidad y el salto. El impulso sigue con su medidor de calor (como antes).
- **Esquiva** (`shared/AirCombat/ShipAbilities`): izquierda, derecha, arriba o abajo según la entrada;
  desplazamiento real de ~38 studs en 0,28 s (estela), recuperación corta, recarga 1,6 s, 18 de energía.
  El servidor la aprueba (recarga, energía, estado), da **0,18 s de invulnerabilidad** y un margen en la
  comprobación del movimiento. Como la nave se aparta de verdad, los disparos que iban a su sitio fallan.
  Si no se puede: aviso visual (la ranura tiembla en rojo) y sonido seco, sin gastar nada.
- **Freno** y **freno de emergencia** (ver fase 2). **Impulso** con su color naranja en el HUD.

### Fase 5 · Hipervelocidad (`shared/AirCombat/Hyperspeed`)

1. **Preparación** (1 s): el cliente la pide; el servidor comprueba energía, estado, combate, estaciones,
   tráfico, atmósfera y obstáculos delante. El brillo de los motores sube. Si no, explica el motivo.
2. **Activación** (1 s): la velocidad sube poco a poco hasta 1500 studs/s, estelas, temblor suave,
   el campo de visión se abre, distorsión y HUD especial.
3. **Viaje**: gasta energía (la cuenta el servidor), avisa de obstáculos y se corta con Ctrl, 7 o la
   ranura; se corta sola sin energía, con un obstáculo delante, al llegar al borde del espacio, a una
   estación o a la atmósfera de un planeta.
4. **Desaceleración** (1,2 s): baja poco a poco, la cámara vuelve, efecto de salida.

Bloqueada: en combate (daño hace < 6 s o enemigos a < 1500), cerca de estaciones (< 830), con tráfico
(otro piloto a < 250), en la atmósfera (de Valmar o de un planeta, y en la superficie), sin energía (< 30)
o en recarga. Los choques se miran **barridos y por adelantado** (2,5 s de recorrido delante): nunca
atraviesa un asteroide, una estación ni un planeta. Distinta del impulso (otra tecla, otra velocidad,
gasta energía y tiene fases).

### Fase 6 · Salto cuántico (`shared/Cosmos/QuantumJump`)

- **Destinos** (del registro de navegación de verdad): baliza de Valmar, estaciones Alba y Cénit, órbita
  de los 7 planetas (`PlanetBodies`; los que aún no tienen episodio, solo órbita), campos de asteroides y
  sectores **descubiertos** (`data.Space.Found`, se descubren al entrar volando) y el punto de las
  misiones activas (carga → estación; drones → Sector Brasa…).
- **Selector** (X o la ranura 6): lista con distancia, coste y estado; los que no se pueden, con el motivo.
- **Validación (servidor)**: estado (no derribado, no en hipervelocidad ni otro salto), mundo (espacio de
  Valmar), combate, energía, alcance (máx. 60 000), distancia mínima (1500), recarga (12 s) y llegada
  segura (`safeArrival`: se busca un sitio libre de geometría alrededor del destino).
- **Secuencia**: carga (3 s: anillos y distorsión, el motor sube) → portal → `AirCombatService.relocate`
  al sitio seguro (el servidor, no el cliente) → salida con destello. La energía **solo se gasta al
  saltar**: si falla (te dan durante la carga, cancelas, el sitio deja de ser seguro…), explica el motivo,
  no gasta nada y la nave sigue volando. Un salto a la vez (`Charging`), y se puede reintentar.

### Nave (silueta de la referencia)

`ShipModel` «Caza» rehecho con piezas: fuselaje largo central, dos cascos laterales (multicasco), alas
afiladas hacia atrás y **tres motores** con brillo azul intenso. Misma API (`build`, `specs`, `Root`,
`ShipSeat`, `Escape`, `Llama`, tren de aterrizaje, luces de navegación).

## 3. Archivos

| Nuevo | Para qué |
|---|---|
| `src/shared/AirCombat/ShipKeys.luau` | Tabla de teclas reasignable (teclado, mando) y textos de las pistas. |
| `src/shared/AirCombat/ShipAbilities.luau` | Energía, recargas, esquiva y las 8 ranuras (puro). |
| `src/shared/AirCombat/Hyperspeed.luau` | Fases, comprobaciones y barrido (puro). |
| `src/shared/Cosmos/QuantumJump.luau` | Destinos, validación, coste y llegada segura (puro). |
| `src/client/UI/ShipHudLayout.luau` | Zonas del HUD, brújula y radar (puro, probado en 4 pantallas). |
| `src/client/UI/AimDrag.luau` | Zona de arrastre para apuntar con el pulgar derecho (móvil). |
| `src/server/Services/ShipSystems.luau` | Energía, esquiva, hipervelocidad y salto en el servidor (ayudante de AirCombatService). |
| `scripts/test-espacio-aaa.luau` | Pruebas de las fases 2 a 6. |

Se cambian: `ShipFlight`, `ShipWeapons`, `ShipModel`, `Zone`, `AirCombatService`, `SpaceService`,
`AirCombatClient`, `AirCombatFx`, `AirCombatHud`, `ShipButtons`, `HudLayout` (`Fly`), `Hud`
(`setShipFocus`), `SpaceClient` (F interactúa), docs.

## 4. Riesgos

- **Red**: la hipervelocidad y la esquiva mueven mucho en poco tiempo; el servidor solo da margen cuando
  las ha aprobado (si no, «Reset» al último sitio bueno, como siempre).
- **Teclas**: cambian X, F y Espacio. Se documentan y se enseñan en el HUD; la tabla es reasignable.
- **Móvil**: muchos elementos; el HUD compacto se comprueba con pruebas de solape en las 4 pantallas.
- **Rendimiento**: efectos dentro de `FxBudget`; el HUD a ritmo limitado.
- **Sin probar en Roblox de verdad** (Lune no dibuja): ver la lista de comprobación a mano.

## 5. Orden

1. Este documento. 2. Vuelo. 3. HUD y mandos (y la nave nueva). 4. Impulso, freno y esquiva.
5. Hipervelocidad. 6. Salto cuántico. Un commit por fase; el juego sigue jugable en cada una.
