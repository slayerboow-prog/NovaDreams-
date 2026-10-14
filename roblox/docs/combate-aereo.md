# Combate aéreo y espacial (núcleo para la Saga 2)

Naves de combate arcade para la Saga 2: vuelo en atmósfera y en el espacio, láser, misiles con fijación,
escudos, oleadas de enemigos con IA y un panel compacto. Ahora se prueba en una **arena de pruebas** del
Modo pruebas; el juego normal de Valmar no cambia.

> **El espacio encima de Valmar** (puerto espacial, estaciones, asteroides, patrullas y los 7 planetas)
> usa este mismo núcleo con `World = "Cosmos"`: ver `docs/espacio.md`. La arena de pruebas sigue aquí,
> aparte.

## Cómo probarlo

1. Entra como tester (Studio, el dueño o `Config.Testers`) y escribe **`/pruebas`** en el chat.
2. Sección **COMBATE AÉREO** → **«🚀 Arena de combate aéreo»** (o «Empezar en el espacio», «Arena fácil»,
   «Arena difícil»). Apareces sentado en tu nave en el punto de control.
3. A los 5 s llega la primera oleada. Sube por los **anillos azules** del centro para pasar al espacio.
4. Para volver a Valmar: botón **Salir** (móvil), tecla **X**, botón **B** del mando o «🏠 Salir de la
   arena» en el panel. Vuelves exactamente a donde estabas.

### Mandos

| | Móvil | Ordenador | Mando |
|---|---|---|---|
| Dirigir | joystick izquierdo (arriba sube el morro) | ratón (apártalo del centro) o flechas | joystick izquierdo |
| Alabeo | automático (se inclina y nivela sola) | Q / E | joystick derecho |
| Motor | automático (crucero) | W / S | cruceta ↑ / ↓ |
| Láser | **FUEGO** (mantener) | clic izquierdo o Espacio | RT |
| Misil | **MISIL** (con blanco fijado) | F o clic derecho | RB |
| Turbo | **TURBO** (mantener) | Shift | LB |
| Freno / giro cerrado | **FRENO** (mantener) | Ctrl | LT |
| Salir | **Salir** | X | B |

Los botones del móvil van en la esquina de abajo a la derecha (HudLayout.Fly: `Fuego`, `Misil`, `Turbo`,
`FrenoNave`, `SalirNave`) y miden **≥ 44 pt** en el móvil del dueño; el FUEGO es el más grande.

- **Fijar:** mantén a un enemigo dentro del recuadro del centro; el recuadro se cierra, suenan pitidos y
  se pone **rojo** («FIJADO · MISIL»). Entonces el misil lo persigue.
- **Ayuda a apuntar:** el láser se desvía un poco hacia el enemigo más centrado (y se adelanta a su
  movimiento). En el móvil el cono es más ancho.
- **Turbo:** gasta energía; si la vacías entera tiene que enfriarse unos segundos («ENFRIANDO»).
- **Cañones:** disparar sin parar los recalienta; deja de disparar un momento.
- **Escudo y casco:** el escudo para los disparos y se recarga solo a los 3 s sin recibir; lo que pasa
  va al casco. Casco a 0 o chocar con el suelo, una roca o un asteroide: tu nave estalla y a los 3 s
  reapareces en el punto de control con todo lleno.
- **Enemigos:** drones en enjambre (te rodean y ametrallan), cazas que se baten contigo (persiguen,
  esquivan cuando les das o te les pones detrás) y torretas en las rocas y los asteroides. Cada
  oleada trae más y más duros (con tope: nunca más de 12 a la vez). Derribados, estallan de verdad:
  explosión, trozos, humo y restos en llamas que caen (sin sangre).

## Dónde está la arena y por qué

En el **mismo lugar** del juego, pero muy lejos: centro en X = Z = 24 000 (Valmar y el aeroclub acaban en
±5600) y por encima (la meseta a Y = 1200; el espacio desde Y = 3400 hasta 6400).

- El proyecto publica **un solo lugar** (`scripts/publish.sh` sube un `ROBLOX_PLACE_ID`), así que otro
  lugar exigiría crear y publicar otro place y teletransportar (TeleportService), cosa que aún no existe
  en el proyecto. La arena dentro del mismo lugar se puede probar ya, en Studio y en el juego publicado.
- **No afecta a nadie:** se construye la primera vez que alguien entra (nunca al arrancar el servidor),
  el servicio no tiene bucle mientras no hay nadie dentro y sus modelos son
  `ModelStreamingMode = PersistentPerPlayer`: solo se mandan a quien está en la arena. Solo pueden entrar
  los testers.
- Al entrar se guarda el atributo `AirArenaReturn`: PositionService guarda ese sitio de Valmar (no la
  arena) si te desconectas dentro.

## Cómo está hecho (para reutilizar)

Lo puro (sin Roblox, igual en cliente y servidor, probado con Lune) va en `src/shared/AirCombat/`:

| Módulo | Qué hace |
|---|---|
| `ShipFlight` | Modelo de vuelo arcade: motor, cabeceo/guiñada/alabeo con autonivelación, turbo con energía y enfriamiento, freno con giro cerrado, modos `Atmos` (gravedad, se hunde despacio) y `Space`, choques (`Crash`), límites y la comprobación del servidor (`plausible`). |
| `Shields` | Escudo + casco, perforación de los misiles, regeneración con retraso. |
| `ShipWeapons` | Láser (cadencia, calor), misiles (munición, recarga, guiado), segmento del proyectil, cono máximo del servidor. |
| `Lock` | Fijación (cono, alcance, tiempo, margen al salir), adelanto y ayuda a apuntar. |
| `EnemyAI` | Dron (enjambre en círculo), Caza (persigue / esquiva / se aleja), Torreta; elegir blanco. |
| `Waves` | Oleadas por sección y dificultad, escala por oleada, máquina de oleadas, anillo de salida, texto del objetivo. |
| `Arena` | La arena de pruebas: sitio, puntos de control, rocas y asteroides (repetibles), choques. |
| `FxBudget` | Topes de efectos por nivel gráfico (Bajo / Medio / Alto) y colores. |

Servidor: `src/server/Services/AirCombatService.luau` (sesiones, validación, disparos, daño, IA, oleadas)
y `src/server/World/AirArena.luau` (piezas de la arena, la nave y los enemigos).
Cliente: `src/client/Controllers/AirCombatClient.luau` (mandos, predicción del vuelo, cámara, fijación),
`AirCombatFx.luau` (efectos), `src/client/UI/AirCombatHud.luau` (panel, radar, flechas, recuadro) y
`ShipButtons.luau` (botones táctiles). Sonidos en `Config.Sounds` (`Nave*`, control 🔔 Efectos, 3D).

**Quién manda:** la nave la mueve el ordenador del piloto (dueño de red, predicción sin retraso); el
servidor comprueba cada vuelta que el salto sea posible, que siga en la arena y que no esté dentro de una
roca. Disparos, misiles, daño, escudos, munición, enemigos y oleadas son del servidor: el cliente solo
pide «disparo hacia aquí» (con cadencia, calor y un cono máximo) y «misil a este blanco» (tiene que estar
delante).

### Para un planeta de la Saga 2 (otro lugar)

1. Copia `src/shared/AirCombat/`, `AirCombatService`, `World/AirArena`, `AirCombatClient`, `AirCombatFx`,
   `AirCombatHud`, `ShipButtons`, las entradas `Nave*` de `Config.Sounds` y los huecos `Fuego…SalirNave`
   de `HudLayout.Fly` (o reutiliza todo el proyecto Rojo como base del nuevo place).
2. Sustituye `Arena` por la geometría del planeta: hace falta `checkpoint(sección)`, `center(sección)`,
   `modeAt(pos)`, `bounds(pos)`, `contains(pos, margen)`, `collide(pos, radio)`, `segmentBlocked(a, b)` y
   `turretSpots(sección)`. Para un terreno de verdad, `collide` puede consultar un mapa de alturas.
3. Desde la misión: `AirCombatService.enter(jugador, { Section = "Space", Difficulty = "Normal",
   MaxWaves = 5, Trusted = true })` y escucha `AirCombatService.onEvent(function(jugador, nombre, datos)
   … end)` con `"Kill"`, `"WaveCleared"`, `"Done"`, `"Down"` y `"Exit"`.
4. Nuevos enemigos: una entrada en `EnemyAI.Kinds` + `Shields.Specs` + su modelo en `AirArena.enemy`;
   nuevas oleadas en `Waves` (o pásale tus propios grupos).

## Límites conocidos

- Un piloto = una sesión con sus propios enemigos; varios testers a la vez ven los disparos de los
  demás, pero cada uno pelea su oleada (la IA ya admite varios pilotos para el cooperativo).
- Los enemigos los mueve el servidor (30 vueltas por segundo, piezas ancladas): se ven bien, pero no
  tan suaves como tu nave; los impactos los decide el servidor con su posición de tu nave (con mucho
  retraso de red, un disparo esquivado en tu pantalla puede darte).
- El espacio oscurece el cielo con una capa de DayLight y un campo de estrellas local; el cielo de fotos
  sigue siendo el de Valmar (no hay skybox espacial propio).
- Sonidos: sin ids nuevos sin comprobar; son los de Roblox retocados y nuestros `motor`/`choque_*`.
  Cuando haya audios de láser y explosión subidos y comprobados (`audio-biblioteca`), basta con cambiar
  las entradas `Nave*`.
- Solo hay un tipo de nave (`Caza`) y la arena es de pruebas: sin recompensas, ni guardado de puntos.

## Pruebas

```
lune run scripts/test-aircombat.luau      # vuelo, daño, escudos, armas, fijación, IA, oleadas, arena, botones, panel y servidor
lune run scripts/test-compile.luau
lune run scripts/test-clientboot.luau     # ordenador y móvil
```
