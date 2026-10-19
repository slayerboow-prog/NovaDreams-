# Repaso total de beta tester (octubre de 2026, sobre la v119)

Sebastián pidió «un repaso de TODO». Este repaso mira todo el juego como un beta tester, **menos** lo que otros
agentes están arreglando ahora mismo (diálogos y cinemáticas, la ciudad de Tefra, el aspecto de los alienígenas
y su panel de evento global, y disparar a pie). De esas zonas solo se apuntan cosas para su agente.

Antes de empezar se leyeron las auditorías anteriores (`ciudad-economia-interfaz.md`,
`vuelo-espacio-mar-invasion.md`, `historia-misiones.md`, `cinematicas.md`) y `docs/diagnostico-v95.md`, para no
repetir lo que ya estaba arreglado y para mirar si lo que dejaron pendiente sigue pendiente.

## Cómo se ha hecho

1. **Pruebas con Lune.** Se pasaron las 126 pruebas de `scripts/` que no necesitan el mapa construido, y después,
   con el mapa construido (`rojo build` + `scripts/build-place.luau`, 374 129 piezas), las que lo necesitan:
   `test-airport`, `test-rail`, `test-streets`, `test-mapcoherence`, `test-metro`, `test-bus`, `test-collisions`,
   `test-zonasverdes`, `test-flight`, `test-avion-real` y `test-boats`. También `test-gameplay` (la grande). No se
   pasaron `test-playthrough`, `test-lifestory` ni la auditoría entera de `test-cineplanos` (tardan mucho y son de
   la historia y las cinemáticas, que lleva otro agente).
2. **Búsquedas automáticas en el código** (en una copia, sin tocar el juego):
   - variables que no existen (con `selene` y la librería de Luau): salió **`saddleWeld`** (fallo 1 de la tabla);
   - nombres de remotos: los 54 de `default.project.json` los usan el servidor y el cliente; ningún
     `WaitForChild` del cliente espera algo que nadie crea;
   - acciones que manda el cliente (`FireServer("Algo")`) y que el servidor no conoce: ninguna;
   - funciones de otro módulo que no existen (`Modulo.funcion(` sin definir): ninguna real;
   - tablas por jugador que no se vacían al salir (fugas de memoria): ninguna real;
   - remotos sin límite de peticiones: solo `GoHome` y `QuitJob` (baratos; ver la tabla);
   - llamadas de red sin `pcall` (filtro de texto, cargar assets, miniaturas): todas protegidas.
3. **Lectura del código** de lo cambiado desde las auditorías anteriores y de cada zona de la lista.
4. **Las capturas del dueño** en `docs/bugs/` (la del evento global de los Lumínidos y la de Chef Lola).

Cada fallo arreglado tiene una prueba que falla con el código de antes y pasa con el de ahora.

## Resumen

| Gravedad | Total | Arreglados | Pendientes | Para otro agente |
|---|---|---|---|---|
| Crítico | 0 | 0 | 0 | 0 |
| Alto | 4 | 2 | 0 | 2 |
| Medio | 9 | 3 | 4 | 2 |
| Bajo | 10 | 4 | 5 | 1 |
| **Total** | **23** | **9** | **9** | **5** |

No se ha encontrado nada «crítico» (que rompa la partida, pierda dinero o el guardado, o deje hacer trampas con
dinero de verdad). Lo más grave era el fallo de la moto (un error de verdad en el servidor) y el doble panel del
evento global que vio el dueño.

## Tabla de fallos (por gravedad)

«Confirmado» = visto en el código (archivo:línea) o con una prueba. «Hipótesis» = probable, pero hay que verlo
en Roblox. Las líneas son las de **antes** del arreglo.

### Alto

| # | Zona | Qué le pasa al jugador | Confirmado / hipótesis | Estado |
|---|---|---|---|---|
| A1 | Vehículos (moto, bici, caballo) | **Subir de paquete detrás de alguien en una moto, una bici o un caballo no funcionaba**: el servidor daba un error y no te sentaba (y ya te había movido encima del asiento). | **Confirmado**: `VehicleService.luau:991` llama a `saddleWeld`, pero la función se define más abajo (`:1136`), así que en ese punto vale `nil` → «attempt to call a nil value». Lo encontró `selene` y lo reproduce `test-boats` («de paquete en una moto…»). | **Arreglado** (la función va antes de `VehicleService.board`). |
| A2 | Casa / espacio | **«🏠 Ir a casa» desde Tefra (a pie), una estación espacial o el espacio** te llevaba a Valmar con el estado del planeta puesto: cielo negro, sin la tarjeta de misión, sin el GPS de Valmar, y la nave aparcada allí. | **Confirmado**: `HouseService.goHome` (`HouseService.luau:331-375`) no miraba `Planeta`, `SpaceStation` ni `AirCombatWorld`, y `PlanetService` solo limpia el planeta al reaparecer (`PlanetService.luau:604-611`). | **Arreglado**: avisa «🏠 Desde aquí no: vuelve antes a Valmar con tu nave (o el portal)». Prueba en `test-gameplay`. |
| A3 | Invasión / HUD (captura del dueño) | **Dos paneles «EVENTO GLOBAL» fijos a la vez** arriba: el de la invasión (centro) y la tarjeta de misión (derecha) diciendo lo mismo («Oleada 1 de 4»). Tapan media pantalla del móvil. | **Confirmado**: `Hud.luau:819-836` (`paintMission`) pone la invasión en la tarjeta de misión mientras `UI/InvasionHud` enseña su panel. Captura `docs/bugs/invasion-luminidos-banner.png`. | **Para el agente del panel del evento global**. Idea: mientras se ve el panel de la invasión, la tarjeta de misión enseña tu misión normal (o se esconde). Ojo: este repaso ha tocado `Hud.luau` en otras partes (avisos y nivel), no en `paintMission`. |
| A4 | Armas (disparar a pie) | `test-cucarachas` **falla**: el arma alienígena «Remachadora» usa el mismo icono ⚙️ que el «Subfusil 9 mm»; en la barra rápida no se distinguen. | **Confirmado**: `Weapons.luau:405` (`XenoRemache`, «⚙️») y `Weapons.luau:275` (`Subfusil`, «⚙️»). | **Para el agente de disparar a pie** (cambiar el icono de la Remachadora, por ejemplo a 🔩). |

### Medio

| # | Zona | Qué le pasa al jugador | Confirmado / hipótesis | Estado |
|---|---|---|---|---|
| M1 | Mar | **Un tsunami (y el remolino, el tiburón, las medusas, el megalodón o el kraken) te podía matar en mitad de una conversación** de la historia o de una escena, sin poder moverte. La auditoría de historia lo dejó pendiente. | **Confirmado**: `SeaEventService.luau:82` y `SeaBeastService.luau:98` quitaban vida sin mirar `InDialogue`, `InPrologue` ni las escenas del servidor (la invasión sí lo mira: `InvasionService.storyBusy`). | **Arreglado** (el mismo criterio que la invasión). Prueba en `test-gameplay` («…en una conversación de la historia en la playa no sufre nada»). |
| M2 | HUD en el móvil | **Los avisos largos se salían de la pantalla por los dos lados** (no se podían leer). Hay 45 avisos de más de 70 letras; el de Tefra tiene unas 150. | **Confirmado**: el texto del aviso iba en una sola línea sin ancho máximo (`Hud.luau`, `Hud.toast`). | **Arreglado**: como mucho 560 de ancho y el resto baja a otra línea. Prueba en `test-hud`. |
| M3 | Tienda | **«🛒 Tienda» era una ventana sin nada que hacer** y decía «Pronto llegará el pase de temporada», con el pase ya en el juego. | **Confirmado**: `Store.luau:137`, con `BattlePass/Config.luau:18` `Enabled = true`. | **Arreglado**: dice que el pase solo tiene cosméticos de premium y trae el botón «🏆 Abrir el pase de temporada». Prueba en `test-clientboot`. |
| M4 | Seguridad (modo pruebas) | El modo pruebas (dinero infinito, todas las armas, teletransporte) se da también **por nombre de usuario** («Sibuastian»). Si ese nombre se cambia y otra persona lo coge, tendría el modo pruebas en el juego publicado. | **Confirmado** el código (`Config.luau:102`, `TesterService.luau:101`); el riesgo es una **hipótesis** (hace falta que alguien coja el nombre). Ya lo apuntó la auditoría de la ciudad. | **Pendiente**: el dueño tiene que dar el número de usuario (UserId) de esa cuenta para ponerlo en `Config.Testers` y vaciar `TesterNames`. |
| M5 | Historia / aviones | «Alas sobre Valmar» (`Invasion_Alas`) se ofrece aunque no tengas licencia de piloto ni nave. | **Confirmado**: las condiciones de la historia no saben nada de licencias (sigue como lo dejó la auditoría de historia). | **Pendiente** (decisión de diseño: esconderla o explicar dónde sacarse la licencia). |
| M6 | Rendimiento en el móvil | 374 129 piezas en el mapa y **113 conexiones que corren en cada fotograma** en el cliente (RenderStepped / Heartbeat). Puede ir a tirones en móviles flojos. | **Hipótesis**: las cuentas están en el código; si va lento o no solo se ve con el MicroProfiler en un móvil de verdad. | **Pendiente**: medir en el móvil del dueño (Ctrl+F6 / MicroProfiler) andando por el centro y durante una invasión. |
| M7 | Invasión (captura) | Rótulos flotantes de zonas de la invasión («El camping» con una barra verde) en medio de la pantalla, a la izquierda, junto a más barras verdes sueltas. | **Confirmado** que el rótulo es de las zonas de aterrizaje (`shared/Invasion/Landing.luau:36`); su tamaño y su sitio, solo en la captura. | **Para el agente de la invasión** (visuales y barras de vida). |
| M8 | HUD en el móvil (captura) | El botón «❓ ¿Qué hago?» queda pegado al borde del panel de la invasión. | **Confirmado** en la captura; el sitio lo deciden `HudLayout` (hueco «Ayuda») y `TopStack`. | **Para el agente del panel del evento global** (al decidir A3, que el panel deje sitio al botón). |
| M9 | Nave (de la auditoría de vuelo) | Si `AirCombatClient` falla al arrancar en un móvil, te quedas sentado en la nave sin botones. | **Hipótesis** (no se ha visto nunca). | **Pendiente**, como lo dejó la auditoría de vuelo: mirar la consola (F9). |

### Bajo

| # | Zona | Qué le pasa al jugador | Confirmado / hipótesis | Estado |
|---|---|---|---|---|
| B1 | HUD en el móvil | Con puntos por repartir salía «Nv. 4 +» justo al lado del dinero: se leía «**Nv. 4 +535 €**», como si te estuvieran dando dinero (se ve en la captura). | **Confirmado**: `Hud.luau:505`. | **Arreglado**: «Nv. 4 ⬆». Prueba en `test-hud`. |
| B2 | Gimnasio | La tele del gimnasio («¡TÚ PUEDES! 💪») salía sin su fondo azul. | **Confirmado**: `GymKit.luau:450` recibía el color de fondo y no lo pasaba a `Builder.sign` (lo vio `selene`). | **Arreglado** (en el commit pone «pierde su fondo azul»; quiere decir que ya **no** lo pierde). |
| B3 | Pruebas | `test-audiomix` y `test-graphicsprefs` se cortaban al cargar `SettingsService` (ahora también usa `ShooterPrefs`). | **Confirmado** (error «converting Lua table to userdata» / «require inesperado»). | **Arreglado** (solo las pruebas). |
| B4 | Pruebas | `test-underground` se cortaba al cargar `SafeSpot` (ahora usa `CameraShots`). | **Confirmado**. | **Arreglado** (solo la prueba). |
| B5 | Seguridad | Los remotos `GoHome` y `QuitJob` no tienen límite de peticiones. Son baratos, pero «Ir a casa» teletransporta. | **Confirmado** (`HouseService.luau:410`, `JobService.luau:286`); que alguien lo use para cargar el servidor es **hipótesis**. | **Pendiente** (un tope de 1 por segundo bastaría). |
| B6 | Pantalla de carga | Si «Volver a entrar» no consigue teletransportar, el botón se queda diciendo «Entrando…» para siempre. | **Confirmado**: `LoadingGate.luau` (el `pcall` del `Teleport` no devuelve el texto). | **Pendiente**. |
| B7 | Aviones y nave | En el avión «ABAJO = SUBIR» y en la nave «ARRIBA = sube el morro», por defecto. Se puede cambiar en Ajustes, pero al pasar de uno a otro confunde. | **Confirmado** (`Flying.luau:15`, `FlightStick.luau:47`). | **Pendiente** (decisión del dueño, que pidió «abajo = subir» para el avión). |
| B8 | Invasión | El servidor mira `TesterGod` (invencible en la invasión) pero nadie lo pone nunca: es un interruptor que no existe. | **Confirmado**: `InvasionService.luau:1299`; ningún `SetAttribute("TesterGod")` en todo el código. | **Para el agente de la invasión** (quitarlo o añadirlo al panel de pruebas). |
| B9 | Mapa | 50 avisos de diseño en `test-mapcoherence` (calles dobles, sitios sin acceso en el Distrito Oeste), 0 críticos. | **Confirmado** (igual que en la auditoría de la ciudad). | **Pendiente** para la próxima revisión del mapa (cambiarlo mueve claves de edificios y partidas). |
| B10 | Cinemáticas | La auditoría entera de `test-cineplanos` sigue sin pasarse completa. | **Confirmado** (no se ha lanzado aquí: es lenta y de otro agente). | **Pendiente** (con una máquina libre). |

## Lo que se ha mirado y está bien

- **Primera entrada y carga**: `LoadingGate` espera a la ciudad, a tu partida y a tu historia (como mucho 30 s),
  y a los 75 s ofrece «Volver a entrar» (salvo B6). `test-onboarding`, `test-clientboot` y `test-serverboot`, bien.
- **HUD en el móvil**: `test-hud` mide 640x360, 667x375, 844x390, 932x430 y tabletas sin solapes. Los avisos van por
  encima de las ventanas y, con un arma, son como mucho dos y más pequeños.
- **ValPhone, mochila y barra rápida, minimapa y GPS, reloj y tiempo**: sus pruebas pasan (`test-gps`,
  `test-weather`, `test-daylight`, `test-skyrift`…). Todas las apps del ValPhone tienen su acción.
- **Trabajos y economía, viviendas, negocios**: el dinero lo decide siempre el servidor; las compras validan
  números raros, distancia y edad (como dijo la auditoría de la ciudad). `test-economy`, `test-properties`,
  `test-gameplay`, bien.
- **Pase de temporada y tienda**: sin cajas de premio al azar (no hace falta enseñar probabilidades: las
  recompensas son fijas por nivel). El premium solo da cosméticos; los vehículos premium conducen igual que los
  mejores que se ganan jugando (`PremiumVehicles.luau`). No se vende dinero (`Config.DevProducts` vacío); los
  recibos de compra no se duplican (`MonetizationService`).
- **Vehículos, tren, metro, autobús, barcos**: `test-metro`, `test-rail`, `test-bus`, `test-boats`, `test-ride`,
  `test-carbodies`, `test-tyres`, bien (salvo A1, ya arreglado).
- **Aviones**: palanca «abajo = subir», tren de aterrizaje, LOOPING y TONEL: `test-flight` y `test-avion-real` con el
  mapa, bien.
- **Mar, buceo, kraken y megalodón**: `test-mar`, `test-swim`, `test-seamotion`, bien (salvo M1, ya arreglado).
- **Zonas verdes, deportes y minijuegos**: `test-zonasverdes`, `test-ocio`, `test-futbol`, `test-baloncesto`,
  `test-voley`, `test-raqueta`, `test-atletismo`, `test-gym`, bien.
- **Sonido y volumen**: `test-audiomix`, `test-sfx`, `test-storyaudio`, bien (tras B3).
- **Guardado** (solo lectura): bloqueo de sesión, reintentos y tamaño, como estaba (`test-persistence`).
- **Errores y red**: filtro de texto, carga de assets y miniaturas siempre dentro de `pcall`; cada servicio arranca
  protegido (`safeInit` en el cliente).

## Pruebas pasadas

**Antes de los arreglos** (126 pruebas sin el mapa): 119 en verde. Fallaban `test-audiomix`, `test-graphicsprefs`
y `test-underground` (pruebas desactualizadas: B3, B4), `test-cucarachas` (A4, para otro agente) y
`test-airport`, `test-rail` y `test-streets` (piden el mapa construido).

**Después de los arreglos**:

- Sin el mapa: todas en verde menos `test-cucarachas` (A4).
- Con el mapa construido (374 129 piezas): `test-airport`, `test-rail`, `test-streets`, `test-mapcoherence`
  (0 críticos, 50 avisos), `test-metro`, `test-bus`, `test-collisions`, `test-zonasverdes`, `test-flight`,
  `test-avion-real` y `test-boats`, en verde.
- `test-gameplay`: en verde (con las comprobaciones nuevas de «Ir a casa» y del tsunami).
- Repetidas tras los arreglos: `test-hud`, `test-clientboot`, `test-boats`, `test-audiomix`,
  `test-graphicsprefs`, `test-underground`.

## Para mirar a mano en Roblox (en el móvil)

1. **Moto con un amigo**: uno conduce y el otro pulsa el asiento de atrás. Tiene que sentarse en el sillín.
2. **Tefra a pie**: abrir el ValPhone → «🏠 Ir a casa». Tiene que decir «Desde aquí no…» y no moverte.
3. **Un aviso largo** (por ejemplo al llegar a Tefra con la nave): se lee entero en dos líneas.
4. **🛒 Tienda** → «🏆 Abrir el pase de temporada»: se cierra la tienda y se abre el pase.
5. **Con puntos de personaje por repartir**: arriba a la izquierda sale «Nv. N ⬆».
