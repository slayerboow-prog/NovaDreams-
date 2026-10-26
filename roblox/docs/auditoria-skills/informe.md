# Auditoría con las skills de Roblox (seguridad, rendimiento en el móvil y guardado)

Fecha: 26-10-2026. Rama `claude/roblox-game-d98vy8`, sobre la v130 publicada. Herramientas: lune 0.10.5 y
rojo 7.7.0. **No se ha publicado nada ni se ha escrito en el DataStore.** No se ha tocado Nácara, Hondario
ni el aspecto de los personajes (CastLook, CosmeLook, `scripts/personajes`).

Listas usadas: `.claude/skills/roblox-security`, `roblox-networking`, `roblox-performance`, `roblox-data`,
`roblox-server-data`, `roblox-gui` y `roblox-publish-checklist`. Solo como guía: no se instaló nada ni se
cambió ningún ajuste por ellas.

## Resumen

El juego ya estaba bien protegido: casi todos los remotos comprueban tipos, NaN, distancia, dueño y
ritmo, y el dinero, la experiencia y el daño los calcula el servidor. Se han arreglado **3 cosas** (2 de
seguridad y 1 de rendimiento en el móvil), con pruebas. El resto queda apuntado abajo con su motivo.

| # | Hallazgo | Gravedad | Estado |
|---|---|---|---|
| S1 | La linterna se podía encender y apagar sin límite: cada cambio se manda a todos los jugadores | Media | ✅ Arreglado (`a546715`) |
| S2 | Salto de parkour con duración NaN o infinita: pasaba la comprobación y llegaba a todos | Baja | ✅ Arreglado (`a546715`) |
| P1 | 1.365 luces de techo siempre encendidas, sin presupuesto (solo lo tenían las farolas) | Media (móvil) | ✅ Arreglado (`447dc48`) |
| S3 | El Game Pass del pase de temporada se da al terminar la compra sin volver a comprobarlo | Baja | ⏳ Pendiente |
| S4 | «Ir a casa» no tiene espera entre usos | Info | Se deja (es del juego) |
| S5 | `Config.TesterNames` (testers por nombre de usuario) | Info | Se deja (está vacío) |
| P2 | Streaming: `ModelStreamingBehavior = Default` y radio 768 | Baja | ⏳ Pendiente (hace falta un móvil) |
| P3 | Haces de luz del Cañón de Dorada: se pone la transparencia en cada fotograma | Muy baja | Se deja |
| D1 | En Studio con «API Services» activado se escribe en la partida real | Media | ⏳ Pendiente (decide el dueño) |
| D2 | Al cerrar el servidor cada partida se guarda dos veces | Baja | Se deja (no pierde nada) |
| D3 | No se mira el presupuesto del DataStore antes de guardar | Baja | Se deja (hay margen de sobra) |
| D4 | Si el guardado al salir falla 3 veces, se pierde lo de esa sesión | Baja | Se deja (es el diseño) |
| D5 | Al cargar no se corrige el dinero `-inf` (solo NaN y `+inf`) | Muy baja | Se deja (no puede pasar) |

## 1. Seguridad (autoridad del servidor)

Revisados los **80 manejadores `OnServerEvent`** de `src/server` (no hay ningún `RemoteFunction`). Se buscó
lo siguiente: tipos, rangos y NaN/infinito, límites de ritmo, dueño y distancia, dinero, experiencia y
daño que mande el cliente, teletransportes y los comandos de prueba.

Lo que ya estaba bien (comprobado leyendo el código):
- **Dinero**: `DataService.addMoney` y `spend` rechazan NaN, infinito y cantidades enormes. Todos los
  `addMoney` con cantidades de remotos usan precios y premios del servidor (negocios, mercadillo,
  tarifas, recompensas). Mercadillo e intercambio son atómicos y tienen límite de ritmo (`TradeService`).
- **Daño**: `WeaponService.fire` hace el rayo en el servidor y comprueba cadencia, cargador, recarga y
  zonas seguras. El cliente solo dice hacia dónde apunta. `DamageService` no escucha al cliente.
- **Récords y premios**: los recreativos (`plausibleScore`, tope por tiempo y tickets por hora), el skate
  (trucos con tope por tiempo de aire) y los choques y atropellos (`Knock.plausible`, velocidad máxima,
  ráfagas) están limitados.
- **Teletransportes**: ascensores (distancia y tiempo desde que se abrió), portales de escenas (junto al
  portal y con espera), «ir a casa» (bloqueado si eres buscado, estás KO, en la cárcel, en una escena, en
  un vehículo o en otro planeta).
- **Comandos de prueba**: `TesterService.isTester` lo decide siempre el servidor (Studio, `Config.Testers`
  por UserId, el creador o el dueño del grupo). Los demás ni siquiera pasan el límite de ritmo.
  `/debug` (`DebugService.allowed`) y `/escena` hacen lo mismo. El atributo `Tester` solo lo pone el servidor.

**S1 — Linterna sin límite (media, arreglado en `a546715`).** `ActionService` aceptaba «Flashlight»
sin espera. Cada cambio replica `Enabled` en dos luces y el atributo `Flashlight` a **todos** los
jugadores. Un tramposo que mandara cientos por segundo saturaba la red de todos los móviles del servidor.
Ahora el límite es de un cambio cada 0,25 s (`ActionService.FLASHLIGHT_GAP`).

**S2 — Salto de parkour con NaN (baja, arreglado en `a546715`).** `ActionService.vault` comprobaba
`Duration < 0.2 or Duration > 2.5`. Con NaN eso da falso, así que «Speed|…|nan» (o «inf») llegaba al
atributo `Vault` que leen los demás clientes. Ahora la duración y el inicio tienen que ser números finitos.
Prueba nueva: `scripts/test-remotes.luau`. Con el código de antes fallan 3 comprobaciones (NaN); con el
nuevo pasan todas.

**S3 — Pase de temporada (baja, pendiente).** `BattlePassService.onPurchaseFinished` (y el aviso de
`MonetizationService`) da el Premium con el `purchased` de `PromptGamePassPurchaseFinished` sin llamar a
`UserOwnsGamePassAsync`. Hoy ese evento solo lo lanza Roblox en el servidor, pero su documentación
recomienda comprobar la propiedad. Arreglarlo es poco código, pero toca compras con Robux: hay que
probarlo con una compra de verdad en un servidor publicado. Queda para una versión con esa prueba.

**S4 / S5 (info).** «Ir a casa» sin espera: es una función del juego y ya está bloqueada en los casos de
escapar. `Config.TesterNames` permite testers por nombre (un nombre se puede cambiar y otro lo puede
coger). Está vacío: **mejor dejarlo vacío** y usar siempre `Config.Testers` (UserId).

Nácara y Hondario: `HondarioService` tiene su remoto y su comprobación de tester. No se auditó a fondo
porque es de otra ventana.

## 2. Rendimiento en el móvil

Medido en el lugar construido (`rojo build` + `scripts/build-place.luau`: 375.250 piezas), con un
contador hecho para esta auditoría:
- 366.769 `Part`, 19.771 `Model`, 168.833 piezas con `CastShadow` (en el nivel Bajo las sombras del sol
  van apagadas).
- **Luces: 3.032** (1.647 SpotLight de farolas, 896 SurfaceLight, 489 PointLight). Ninguna con sombra en
  el lugar. **Encendidas de serie: 1.365**: techos de edificios (`CeilingLamp` 762), túneles del metro
  (141), anuncios (154), tiras, escaleras, pozos…
- 8.115 `SurfaceGui`, todas con `MaxDistance` (70–220 studs). 100 `ParticleEmitter` (133 partículas/s
  en total). 75 `ProximityPrompt`.
- No hay `while true` sin espera. Los bucles por fotograma del servidor (reloj, farolas, autobuses,
  trenes) ya van limitados (4 veces por segundo, cada segundo…). Los de la interfaz también (`BusUI` 5
  veces por segundo…). No se han encontrado tablas por jugador sin limpiar al salir.

**P1 — Luces de techo sin presupuesto (media en el móvil, arreglado en `447dc48`).** `NearShadows` ya
limitaba las farolas (Bajo 8, Medio 18, Alto 40), pero las 1.365 luces de techo estaban siempre
encendidas. Ahora solo dan luz las más cercanas a la cámara: **Bajo 24 (hasta 140 studs), Medio 60
(hasta 260); en Alto todas, como antes** (`Graphics.Tiers.*.RoomLights / RoomLightRange`). En el móvil se
empieza en Medio. Solo se tocan las luces de piezas de techo conocidas (`NearShadows.ROOM_PARTS`) que
llegan encendidas: la linterna, los faros y las luces apagadas no se tocan. Medido en `test-graphics`:
con 400 luces de techo alrededor quedan 24 (Bajo), 60 (Medio) y 400 (Alto).

**P2 — Streaming (pendiente).** `ModelStreamingBehavior = Default` y `StreamingTargetRadius = 768`. Bajar
el radio o pasar a `Improved` puede ahorrar memoria en el móvil, pero cambia lo que se ve a lo lejos y lo
que encuentran los scripts. Hay que probarlo en un teléfono de verdad.

**P3 (muy baja).** `ReefZoneFx` pone la transparencia de los haces de luz en cada fotograma dentro de
la zona, aunque no cambie. Cuesta poco: se deja.

## 3. Guardado (DataService)

Revisado `src/server/Services/DataService.luau` (sin cambios):
- ✅ **Bloqueo de sesión** en `UpdateAsync` (JobId + hora, caduca a los 3 autoguardados = 6 min). Al
  guardar, si otro servidor tiene el bloqueo no se pisa. Un autoguardado que acaba después de salir no
  vuelve a bloquear.
- ✅ **Reintentos**: 5 al cargar (si no carga, se le saca con un aviso en vez de jugar sin partida), 3 al
  salir y 2 en el autoguardado. Espera si su guardado de salida en este servidor aún no ha acabado.
- ✅ **BindToClose** guarda a todos (hasta 25 s). `ProcessReceipt` es idempotente (recibos guardados y
  guardado antes de dar `PurchaseGranted`).
- ✅ `SaveCheck` quita NaN, Vector3, etc. y recorta los historiales antes de guardar (un solo valor malo
  hacía fallar todo el guardado).
- **D1 (media, pendiente: lo decide el dueño).** En Studio, con «Enable Studio Access to API Services»
  activado, se usa el mismo `Config.DataStoreName` que el juego publicado. Probar en Studio escribe en
  las partidas de verdad. No se ha cambiado (no se toca `DataStoreName`). Lo más seguro es **dejar ese
  ajuste apagado en Studio** o, si hace falta, usar un nombre aparte solo en Studio.
- **D2 (baja).** Al cerrar el servidor se guardan las partidas en `BindToClose` y otra vez en
  `PlayerRemoving`. Son dos escrituras iguales: no se pierde nada, solo gasta presupuesto.
- **D3 (baja).** No se llama a `GetRequestBudgetForRequestType`. El autoguardado (cada 120 s) usa medio
  `UpdateAsync` por jugador y minuto, muy por debajo del límite (60 + 10 por jugador cada minuto).
- **D4 (baja).** Si el guardado al salir falla 3 veces, el perfil se suelta y se pierde lo de esa sesión.
  El bloqueo caduca a los 6 minutos. Es lo normal sin cola de reintentos externa.
- **D5 (muy baja).** Al cargar se corrige el dinero NaN o `+inf`, pero no `-inf`. No puede llegar a pasar:
  `addMoney` y `spend` no lo permiten.

## 4. Lista antes de publicar (adaptada a este repositorio)

Resultado: `LISTO`, `NO LISTO` o `LISTO CON RIESGO ACEPTADO`. Cada ✅ tiene que tener su prueba (salida
de la prueba, registro o captura). Sin prueba = «sin comprobar». Si falla algo de lo que bloquea, el
resultado es NO LISTO.

**1. Qué sale.** El commit exacto y la rama `publicar-vNNN` (sale de un commit probado, como en
`diagnostico-v95.md`), qué sistemas cambian, qué recursos se suben (`upload-*.sh`) y cómo volver atrás
(volver a publicar la rama anterior con `PUBLISH_BRANCH=… bash scripts/publish.sh`).

**2. Siempre (desde `roblox/`, con lune 0.10.5 y rojo 7.7.0):**
- `lune run scripts/test-compile.luau`
- `lune run scripts/test-clientboot.luau` (ordenador y móvil)
- `lune run scripts/test-serverboot.luau`
- `lune run scripts/test-hud.luau`
- `lune run scripts/test-persistence.luau`

**3. Según lo que cambie (bloquean si fallan):**
- Guardado o datos nuevos en la partida: `test-persistence` y `test-lifestory` (unos 30 min: ninguna
  partida que el DataStore rechace). Nunca cambiar `Config.DataStoreName` ni `Config.DayLengthMinutes`.
- Remotos, dinero o permisos: `test-remotes`, `test-commands`, `test-tester`, `test-economy` y la prueba
  del sistema tocado. Revisar tipos, NaN/infinito, distancia, dueño y ritmo.
- Compras (Game Pass, productos): `test-battlepass`. Probar una compra real en el juego publicado.
- Gráficos, luces o efectos: `test-graphics`, `test-graphicsprefs`, `test-lights`, `test-vfx`.
- Mapa: construir el lugar (`rojo build default.project.json -o RealLifeSimulator.rbxl` y
  `lune run scripts/build-place.luau RealLifeSimulator.rbxl`) y luego `test-mapcoherence` (**0
  críticos**) y `test-buildingkeys`.
- Mallas nuevas: `scripts/audit/moderacion-mallas.py` antes de subirlas (sin `MODERACION_PERMITIR`).

**4. Publicar.** `PUBLISH_BRANCH=publicar-vNNN bash scripts/publish.sh`. El script comprueba que la rama
coincide con GitHub, compila, construye y publica. Apuntar el `versionNumber` que devuelve.

**5. En un servidor de verdad (después de publicar):**
- `bash scripts/cloud-test.sh --version NNN arranque`: 0 errores y todos los servicios bien (el aviso de
  `BodyPieceService` es el de siempre).
- Las sondas del sistema cambiado (por ejemplo `mar-v3-sonda`, `audio`).
- **En el móvil de Sebastián**: entrar, mover la cámara, abrir el menú y los paneles, jugar un rato de
  noche (luces) y mirar que va fluido. Esto no lo hace ninguna prueba automática: si no se hace, queda
  como «sin comprobar».

**6. Apuntarlo** en `docs/diagnostico-v95.md` («Verificación vNNN»): commit, versión, pruebas que
pasaron, las que no se hicieron y por qué, y que no se escribió en el DataStore.

## Commits de esta auditoría

- `a546715` Seguridad: la linterna con límite y los saltos de parkour sin NaN ni infinito
  (`ActionService`, prueba nueva `scripts/test-remotes.luau`).
- `447dc48` Móvil: solo las luces de techo cercanas dan luz (`Graphics`, `NearShadows`, `test-graphics`).

Pruebas que pasaron antes de subir: `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`,
`test-persistence`, `test-remotes`, `test-graphics`, `test-graphicsprefs` y `test-lights`.
