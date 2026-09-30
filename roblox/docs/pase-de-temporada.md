# Pase de temporada

Diseño, reglas y contrato del **pase de temporada** de Real Life Simulator. La temporada 1 se llama **«Luces de Valmar»**.

> **Interruptor general:** `BattlePassConfig.Enabled` (en `src/shared/BattlePass/Config.luau`) viene **apagado** (`false`). Apagado, el pase no hace nada: no se crea el remoto, no se escuchan eventos, no se entregan recompensas, no hay ganchos en vehículos, ropa ni vivienda, y la interfaz no aparece. En los datos guardados solo quedan los valores por defecto, que no hacen nada. Se enciende cuando la interfaz esté lista.

## 1. Idea en pocas palabras

- **50 niveles** en **9 semanas**. Cada nivel tiene una recompensa **gratis** para todos y otra **premium**.
- El premium es un **Game Pass** de Roblox, de pago único **por temporada**. Da **valor, no poder**: cosméticos, estilo, comodidad y prestigio. No da daño, vida, sueldo, velocidad ni ventajas contra otros jugadores.
- La XP del pase se gana **jugando normal**: trabajar, estudiar, la historia de vida, los encargos, el transporte, conducir, explorar barrios y el ocio. Además hay misiones diarias, semanales, de temporada y una historia de temporada.
- Hay **topes diarios**, así que no hace falta "farmear". Un jugador normal (45–60 min al día) llega al 50 en unas **7–8 semanas**.
- Nada de lo conseguido se pierde nunca: al acabar la temporada, el progreso **se archiva** y lo conseguido sigue siendo tuyo.

## 2. Qué se reutiliza (no se duplica nada)

| Sistema de siempre | Para qué lo usa el pase |
|---|---|
| `DataService` (guardado con bloqueo de sesión) | Tres secciones nuevas en la misma partida: `BattlePass`, `Cosmetics` y `SeasonArchive`. Se añaden en `DEFAULT_DATA`, así que `reconcile` las crea en las partidas viejas. No hay ningún DataStore nuevo. «Vida nueva» también las conserva. |
| `StoryEvents` (tablón de avisos) | Toda la XP y las misiones salen de los avisos que ya mandan los sistemas: `JobTaskDone`, `LessonCompleted`, `RodeMetro`, `BusRide`, `Flew`, `CaughtFish`, `GymSet`… |
| `LifeStoryService.observe` | Misiones de la historia de vida completadas (`QuestDone`). |
| `MarketplaceService` + la forma de `MonetizationService` | Game Pass: `UserOwnsGamePassAsync` y `PromptGamePassPurchaseFinished`. |
| `VehicleService.grant` + `Rides.build(…, color)` | Vehículos del juego y su acabado exclusivo (el mismo modelo con otro color). |
| `ArcadeService` (gafas, gorra, tickets) | Accesorios y tickets. Se han añadido `grantPrize` y `addTickets`. |
| `AvatarService` (aspecto de Valmar) | Conjuntos de ropa: son colores que cambian los del aspecto de Valmar. |
| `PropertyService` (interiores de las viviendas) | Tema de vivienda (opción B de la especificación) y decoración, en tu vivienda de siempre. |
| `ProgressionService.addXp` | Recompensas de XP de personaje. |
| `LocationService.resolve` + `TaskMarker` | GPS de las misiones: la misión que sigues pone el atributo `SeasonTarget`. |
| `TesterService` (`/pruebas`) | Premium simulado, sumar XP, poner nivel y adelantar el reloj. |
| Aviso `Notify` | Avisos discretos («¡nivel 12!», «misión completada») aunque todavía no haya interfaz. |

**Lo que no existía** (y cómo se ha resuelto sin inventar un sistema incompatible):

- **Barcos propios:** no hay. Solo existen el barco de pesca y el ferry, y no son de nadie. La recompensa «Lancha Gaviota» se guarda como tuya y pasa por `BoatAdapter` (en `BattlePassRewardService`). El día que exista `Services/BoatService` con `grant(player, kind, def)`, se entregará sola. Mientras tanto, la interfaz enseña «Llega con el puerto deportivo» (`Usable = false`).
- **Títulos, placas y temas del teléfono y del HUD:** no había. Se guardan en la colección y se publican como atributos del jugador (`BP_Title`, `BP_Nameplate`, `BP_PhoneTheme`, `BP_HudSkin`…) para que la interfaz los pinte. `BP_Title` y `BP_TitleColor` también los ven los demás jugadores.
- **Gestos nuevos:** `Actions` tiene una lista fija. Los gestos del pase van en `BP_Emotes`, que es una lista de Ids con su `AnimationId`. La interfaz los añade al menú de gestos. Ahora usan animaciones públicas de Roblox, algunas con otra velocidad; el dueño puede cambiarlas por animaciones propias en `Season1.luau`.
- **Analítica:** no había. `server/BattlePass/Telemetry.luau` guarda contadores en memoria y, si se activa `Telemetry.UseAnalyticsService`, los manda a AnalyticsService.

## 3. Módulos nuevos

| Archivo | Qué hace |
|---|---|
| `src/shared/BattlePass/Config.luau` | Interruptor general, topes de XP, fuentes de XP, XP por oficio, fichas, límites del remoto, rarezas y lista de temporadas. **Solo datos.** |
| `src/shared/BattlePass/Season1.luau` | La temporada 1: fechas, curva de XP, `GamePassId`, las 100 recompensas, misiones, historia, eventos y tienda de fichas. **Solo datos.** |
| `src/shared/BattlePass/Types.luau` | Nombres fijos: pistas, estados, tipos de recompensa y de misión. |
| `src/shared/BattlePass/Catalog.luau` | Índice por Id de todo lo que el pase puede dar, de todas las temporadas. |
| `src/server/BattlePass/SeasonMath.luau` | Cuentas puras: curva de XP, días y semanas UTC, hash estable. |
| `src/server/BattlePass/Telemetry.luau` | Contadores. |
| `Services/BattlePassSeasonService.luau` | Temporada actual y su estado, forma de los datos, cambio de temporada y archivo (lo que la especificación llama *SeasonArchiveService*). |
| `Services/BattlePassRewardService.luau` | Entrega cada tipo de recompensa con su sistema, equipa y engancha vehículos, ropa y vivienda. |
| `Services/SeasonMissionService.luau` | Misiones diarias, semanales, de temporada, de evento e historia por fases. GPS y cambio de diaria. |
| `Services/BattlePassService.luau` | Núcleo: niveles, reclamar, premium, remoto con límite, estado para la interfaz, modo pruebas y vistas previas 3D. |
| `Services/BattlePassXPService.luau` | XP por jugar, con topes y anti-spam. Reenvía cada evento a las misiones. |
| `src/client/Controllers/BattlePassClient.luau` | Envoltorio del remoto para la interfaz. No pinta nada. |
| `scripts/test-battlepass.luau` | Prueba con Lune (126 comprobaciones). |

Los servicios se arrancan en `Main.server.luau` justo después de `CityErrandService`.

### Cambios en sistemas existentes (todos inofensivos con el pase apagado)

| Archivo | Cambio | Por qué | Riesgo |
|---|---|---|---|
| `DataService` | Añade `BattlePass`, `Cosmetics` y `SeasonArchive` a `DEFAULT_DATA`. `newLife` las conserva. | Guardar el pase en la misma partida. Lo conseguido no se pierde con una vida nueva. | Solo campos nuevos. `reconcile` ya los crea en las partidas viejas. |
| `VehicleService` | Gancho `PaintFor` en `mount` (el color del acabado equipado). Cuenta la distancia de cada viaje (`ride.Driven`) y emite `VehicleTrip` al bajarse, solo si el pase está encendido. | Acabados exclusivos y misiones de km. | Sin gancho, el color sigue saliendo al azar. Los saltos de más de 200 studs (teletransportes) no cuentan. |
| `AvatarService` | Gancho `OutfitFor`, mezclado con `Config.DefaultLook` dentro de `dress`. | Conjuntos de ropa. | Sin gancho, el aspecto no cambia. La piel no se toca. |
| `PropertyService` | Gancho `DecorateOwned` en `decorate` (solo viviendas con dueño), con `pcall`. | Tema de vivienda y decoración. | Solo cambia colores y añade piezas decorativas sin colisión. No toca el registro de dueños. |
| `ArcadeService` | Nuevas `grantPrize` y `addTickets`. | Entregar accesorios y tickets. | Funciones nuevas: no cambian nada de lo que ya había. |
| `LifeStoryService` | `discoverZone` emite `ZoneEntered` al cambiar de barrio, solo con el pase encendido. | Misiones de barrios y explorar. | El descubrimiento de siempre no cambia. |
| `CityErrandService` | `finish` emite `ErrandDone`, solo con el pase encendido. | Misiones de encargos. | Nada más. |
| `TesterService` | Acción `"BattlePass"` y `state().BattlePass`. | Probar el pase desde el panel. | Con el pase apagado devuelven `false` / `nil`. |
| `TaskMarker` (cliente) | También sigue `SeasonTarget`, después de `StoryTarget`. | GPS de las misiones del pase. | Sin ese atributo, nada cambia. |

## 4. Recompensas de la temporada 1 «Luces de Valmar»

Hay un hito cada 5 niveles (en negrita). El nivel 50 premium es el conjunto **legendario «Faro de Valmar»**: el descapotable «Faro de Valmar» (blanco perla y oro), el título «Leyenda de Valmar», su placa y un faro en miniatura para tu casa.

| Nivel | Gratis | Premium |
|---|---|---|
| 1 | 🏙️ Vecino/a de Valmar (Título) | 🧥 Chaqueta Luces de Valmar (Ropa, Rara) |
| 2 | 💶 150 € (Dinero) | 🗼 Saludo del faro (Gesto, Rara) |
| 3 | 🪴 Planta de Villaverde (Decoración) | 📱 Neón del Centro (Tema teléfono, Rara) |
| 4 | 🎟️ 40 tickets (Tickets) | 💶 200 € (Dinero) |
| **5** | 🕶️ Gafas de sol (Accesorio, Rara) | 🛴 Patinete Brisa Marina (Vehículo exclusivo, Épica) |
| 6 | ⭐ +150 XP de personaje (XP personaje) | 💡 Lámpara de pie Altamar (Decoración, Rara) |
| 7 | 👏 Aplauso de la plaza (Gesto) | 🌅 Placa Atardecer (Placa, Rara) |
| 8 | 💶 200 € (Dinero) | 🌃 HUD Noche de Valmar (Estilo HUD, Rara) |
| 9 | 🖼️ Póster del Estadio Altamar (Decoración) | 🏘️ Alma de San Roque (Título, Rara) |
| **10** | 🏷️ Placa Valmar Clásica (Placa, Rara) | ⚓ Loft del Puerto (Tema vivienda, Épica) |
| 11 | 🎟️ 60 tickets (Tickets) | 💃 Baile de verbena (Gesto, Rara) |
| 12 | 🌄 Madrugador/a (Título) | 🏮 Farol del muelle (Decoración, Rara) |
| 13 | 💶 250 € (Dinero) | 🩳 Conjunto Playa Dorada (Ropa, Épica) |
| 14 | 🛋️ Cojines de Los Pinos (Decoración) | 🌅 Atardecer en Playa Dorada (Tema teléfono, Rara) |
| **15** | 🚲 Bici Verde Villaverde (Vehículo exclusivo, Rara) | 🛵 Moto Brisa de Playa Dorada (Vehículo exclusivo, Épica) |
| 16 | ⭐ +200 XP de personaje (XP personaje) | 💶 250 € (Dinero) |
| 17 | 🧘 Estiramiento del parque (Gesto) | 🐠 Acuario de la Isla de las Gaviotas (Decoración, Épica) |
| 18 | 💶 250 € (Dinero) | 🚇 Ruta del Metro (Título, Rara) |
| 19 | 📱 Clásico de Valmar (Tema teléfono) | ✨ HUD Faro Dorado (Estilo HUD, Épica) |
| **20** | 🧢 Gorra (Accesorio, Rara) | 🌆 Colección Noche en el Centro (Conjunto, Épica) |
| 21 | 🎟️ 80 tickets (Tickets) | 🕺 Paso del Distrito (Gesto, Rara) |
| 22 | 🕰️ Reloj de la estación (Decoración) | 💜 Placa Neón (Placa, Épica) |
| 23 | 🧭 Explorador/a de distritos (Título) | ☕ Mesa de terraza (Decoración, Rara) |
| 24 | 💶 300 € (Dinero) | ⭐ +300 XP de personaje (XP personaje) |
| **25** | 🏠 Piso luminoso de Valmar Norte (Tema vivienda, Rara) | 🏙️ Ático Distrito Financiero (Tema vivienda, Épica) |
| 26 | ⭐ +250 XP de personaje (XP personaje) | 🤵 Traje de gala de Altamar (Ropa, Épica) |
| 27 | 📸 Foto de turista (Gesto) | 🚆 Maqueta del Cercanías (Decoración, Rara) |
| 28 | 📚 Estantería del Campus (Decoración) | 💶 300 € (Dinero) |
| 29 | 🎟️ 100 tickets (Tickets) | 🌊 Mar de Valmar (Tema teléfono, Rara) |
| **30** | 🏷️ Placa Temporada 1 (Placa, Rara) | 🔄 Cambio de misión diaria (Comodidad, Épica) |
| 31 | 💶 300 € (Dinero) | 🏟️ Celebración del estadio (Gesto, Épica) |
| 32 | 🛠️ Currante de Valmar (Título) | 🏮 Farola antigua (Decoración, Rara) |
| 33 | 🏖️ Alfombra de playa (Decoración) | 🌙 Noctámbulo/a (Título, Rara) |
| 34 | ⭐ +300 XP de personaje (XP personaje) | 🌌 HUD Aurora (Estilo HUD, Épica) |
| **35** | 👕 Sudadera Temporada 1 (Ropa, Rara) | 🚤 Lancha «Gaviota» (Barco, Épica) |
| 36 | 🎟️ 120 tickets (Tickets) | ⛵ Barco en botella (Decoración, Rara) |
| 37 | ⚓ Saludo marinero (Gesto) | 🌊 Placa Marina (Placa, Épica) |
| 38 | 💶 350 € (Dinero) | 🧥 Cortavientos del puerto (Ropa, Épica) |
| 39 | 🗺️ Mapa de Valmar (Tema teléfono, Rara) | 💶 350 € (Dinero) |
| **40** | ❤️ Corazón de Valmar (Título, Rara) | 🗼 Terraza del Faro (Conjunto, Épica) |
| 41 | 🪑 Banco del parque (Decoración) | 💫 Baile del faro (Gesto, Épica) |
| 42 | 💶 350 € (Dinero) | 🔭 Telescopio del Monte (Decoración, Épica) |
| 43 | 🎟️ 150 tickets (Tickets) | ⛰️ Leyenda del Monte (Título, Épica) |
| 44 | ⭐ +350 XP de personaje (XP personaje) | 📱 Oro de Valmar (Tema teléfono, Épica) |
| **45** | 🥈 Placa Plata (Placa, Épica) | 🗼 Conjunto Faro de Valmar (Ropa, Épica) |
| 46 | 🙇 Reverencia (Gesto) | 💌 Postal: la noche del faro (Recuerdo, Rara) |
| 47 | 💶 400 € (Dinero) | 🏆 HUD Leyenda (Estilo HUD, Épica) |
| 48 | 🏆 Trofeo de la temporada (Decoración) | 🥇 Placa Oro (Placa, Épica) |
| 49 | 🪙 3 fichas de temporada (Fichas) | 💶 400 € (Dinero) |
| **50** | 🎖️ Recuerdo de la Temporada 1 (Conjunto, Épica) | 🗼 Faro de Valmar (Conjunto, Legendaria) |

**Dinero:** 2.550 € en toda la pista gratis y 1.500 € en la premium. Es poco: un coche cuesta 9.000 €. Casi todo lo demás son cosméticos.
**Vehículos:** los acabados exclusivos (patinete del 5, bici del 15, moto del 15 premium, coche del 50 premium) son el **mismo vehículo del juego** con otro color. Tienen la misma velocidad y el mismo manejo: se diferencian en el diseño y el prestigio (§9). Con `GrantsBase = true` también dan el vehículo normal si no lo tenías. Para conducir siguen haciendo falta la edad y el carnet de siempre.
**Accesorios repetidos:** si ya tienes las gafas o la gorra, recibes tickets en su lugar (`Fallback`).

## 5. XP: curva, fuentes y topes

- XP para pasar del nivel *n* al *n+1* = **1100 + 20·(n−1)**. En total, **77.420 XP** hasta el 50.
- **Actividad** (`BattlePassConfig.Sources`), con tope diario por fuente:

| Fuente | Eventos (XP por evento) | Tope al día | Hueco mínimo |
|---|---|---|---|
| Trabajo | `JobTaskDone`: según el oficio, de 8 a 40 (`JobXp`: bombero 40, policía 30, repartidor 20, cajero 8…) | 600 | 3 s |
| Estudio | clase 40, examen 60, estudio 25, práctica 40 | 300 | 20 s |
| Historia | misión de la historia de vida completada: 120 | 480 | 5 s |
| Encargos | encargo de un vecino: 60 | 300 | 20 s |
| Transporte | metro 15, tren 20, bus 15, avión 40, viaje 10 (no cuenta si es `NoXp`) | 200 | 30 s |
| Conducir | 25 por km (`VehicleTrip`) | 150 | 10 s |
| Explorar | primera vez en cada barrio **en esta temporada**: 100 | 400 | — |
| Ocio | cine 30, recreativos 8, pesca 8, gimnasio 5, cosecha 10, tocar en la calle 10 | 200 | 8 s |
| Compras | 5–10 | 60 | 10 s |
| Hitos | ascenso 150, carnet 150, casa 100, abrir negocio 100 | 400 | — |

- **Tope total de actividad: 1.400 XP al día.** Las misiones van aparte, porque ya están limitadas por sí mismas.
- **Misiones:** 3 diarias de 100–150 XP, 5 semanales de 450–600 XP, 8 de temporada (≈ 10.400 XP en total), la historia (2.250 XP) y 1 misión por evento (200 XP).
- **Eventos** («Verbena de Playa Dorada» del 17 al 19 de octubre y «Noche de las Luces» del 20 al 23 de noviembre): multiplican ×1,25 la XP de actividad. El tope de seguridad es ×1,5.
- **Ritmo esperado** (lo comprueba `test-battlepass`):
  - **Jugador normal** (45–60 min al día, hace la mayoría de las diarias y algunas semanales): ≈ 1.300–1.500 XP al día, así que llega al **50 en ~7–8 semanas**.
  - **Jugador que da el máximo cada día:** unas 4,5 semanas como pronto.
  - **Jugador casual** (15–20 min al día): nivel 30–40. Tiene casi toda la pista gratis y no se siente bloqueado.
- **Fichas de temporada (SeasonTokens):** sí, porque aportan algo de verdad. Pasado el 50, la XP de más no se pierde: cada 4.000 XP da 1 ficha, con un **máximo de 10 por temporada**. También dan fichas algunas misiones de temporada, la historia y el nivel 49 gratis. Solo sirven para una tienda pequeña de **cosméticos** (títulos, placas, decoración y temas, de 2 a 4 fichas), y cada artículo se compra una vez. No se venden con Robux ni dan dinero.

## 6. Misiones

- **Diarias (3)** y **semanales (5):** se eligen de una lista con un hash de la fecha UTC y la temporada, así que son **iguales en todos los servidores**. Solo tocan las que valen para tu edad: a un niño no le tocan las de trabajo ni las de gimnasio. Se renuevan a las 00:00 UTC y el lunes. Al completarse **dan su XP solas**, sin reclamar.
- **De temporada (8):** recorrer los 8 barrios, 150 tareas de trabajo, 25 viajes, volar a la Isla de las Gaviotas, 10 misiones de la historia, 25 peces, 40 km y 15 encargos.
- **Historia «Se apaga el faro»** (7 fases con sistemas de verdad): ir a la Plaza del Centro → hablar con alguien → coger el metro → 5 tareas de trabajo (o encargos) → ir a Playa Dorada → subir hacia el Monte, Los Pinos o Villaverde → **decidir** «Arreglarlo» o «Modernizarlo». Al terminar, título «Guardián/a del faro» y 1 ficha. Las fases con sitio tienen GPS («Seguir»).
- **Comodidad premium «Cambio de misión diaria»** (nivel 30): una vez al día cambias una diaria sin hacer por otra. No da más XP.

## 7. Seguridad

- **El servidor lo decide todo.** El cliente solo pide: `Claim`, `ClaimAll`, `Buy`, `Equip`, `Track`, `Reroll`, `StoryChoice`, `BuyToken` y `Get`. Nivel, XP, premium, dinero y recompensas nunca salen del cliente. Los niveles se comprueban (número entero de 1 a `MaxLevel`), las pistas solo pueden ser `Free` o `Premium`, y todo lo demás se ignora.
- **Límite de peticiones:** como mucho 8 cada 4 s, con al menos 0,15 s entre dos. Lo que pase del límite se ignora en silencio.
- **Doble reclamo:** el nivel se apunta como reclamado **antes** de entregar, así que una segunda petición a la vez ve «Ya reclamada». Si la entrega falla, se deshace y se puede volver a intentar. El bloqueo de sesión de `DataService` impide que dos servidores tengan la misma partida, así que tampoco se puede duplicar saltando de servidor.
- **XP:** solo sale de eventos que emite el servidor. Tiene hueco mínimo por fuente, topes diarios guardados con el día (salir y volver a entrar no los reinicia) y un tope por km.
- **Compra:** se verifica con Roblox (`UserOwnsGamePassAsync` con 3 reintentos y caché, y el aviso de Roblox en el servidor). Es idempotente y se guarda enseguida. El premium simulado del modo pruebas **solo vive en memoria**: lo que reclama el tester con él queda marcado `"T"`, no `true`.

## 8. Casos límite (§40)

| Caso | Respuesta |
|---|---|
| Compra estando desconectado (web, otro dispositivo) | Al entrar se consulta `UserOwnsGamePassAsync` y se activa el premium, con las premium ya alcanzadas. |
| DataStore lento | `DataService` espera y reintenta. Sin datos no se da ni se reclama nada (`NoData`). La compra espera hasta 20 s a los datos y, si no llegan, se activará en la siguiente entrada. |
| Dos servidores con la misma recompensa | Imposible: el bloqueo de sesión deja la partida en un solo servidor, y los reclamos están en la partida. |
| Subir varios niveles a la vez | El nivel se calcula de la XP total. Llega un solo aviso con todas las recompensas nuevas y se puede «Reclamar todo». |
| Reclamar con error de conexión | Reclamar es idempotente: si no llegó la respuesta, se vuelve a pedir y contesta «ya reclamada». El estado completo se reenvía. |
| La temporada acaba mientras juegas | Ya no se gana XP, pero durante 7 días (`ClaimGraceDays`) se puede reclamar lo alcanzado. |
| Actualización durante una compra | La compra la guarda Roblox. Al volver a entrar se consulta y se activa. |
| Cambio de temporada | Al entrar: lo alcanzado y sin reclamar se entrega solo, el progreso se archiva en `SeasonArchive[Id]` y se empieza de cero. Lo conseguido está en `Cosmetics` y en los sistemas de siempre, así que no se borra. El premium era de la temporada anterior: la nueva tiene su propio Game Pass. |
| Una recompensa deja de existir | Se reclama igual y se da la compensación (`MissingRewardFallback`: 250 €). Lo guardado que ya no está en el catálogo se ignora sin errores. |
| Se cambia un vehículo de una temporada vieja | El acabado es solo color sobre el vehículo del juego: si el modelo cambia, el acabado se aplica al nuevo. Si un tipo de vehículo desaparece, se compensa. |

## 9. Plan de pruebas (§39)

Lo que ya comprueba **`lune run scripts/test-battlepass.luau`**: pase apagado inerte, progreso gratis, varios niveles de golpe, reclamar una vez y no dos, comprar en el nivel 30 (entrega 1–30 y no la 31), compra repetida sin duplicar, otro pase o compra cancelada, compra hecha fuera del juego con fallos de Roblox, `GamePassId = 0` («Próximamente»), valores falsos del cliente, límite de peticiones, topes diarios y hueco mínimo, misiones (misma rotación en todos los servidores, edad, barrios distintos, temporada y renovación semanal), historia con GPS y decisión, eventos y su tope, equipar, recompensa que ya no existe, datos rotos, guardar y cargar en JSON, premium simulado que no se guarda, fichas y su tope, tienda, cambio de diaria, legendaria, periodo para reclamar, cambio de temporada con archivo sin perder nada.

**A mano en Roblox** (servidor real, con el pase encendido):

1. Comprar y no comprar (con un Game Pass de prueba barato), y comprar estando en el nivel 30.
2. Reclamar y reclamar dos veces rápido.
3. Reiniciar el servidor, salir durante una recompensa y entrar en otro servidor.
4. Cambiar de dispositivo, y probar en móvil y PC.
5. Dos o tres jugadores a la vez, con latencia alta (Studio: *Network Simulation*).
6. Intentar abusar de la XP (repetir el metro, entrar y salir) y mandar muchas peticiones seguidas (con un script en Studio).
7. Fallo de DataStore (Studio sin acceso a la API).
8. Temporada acabada y temporada nueva, con el reloj adelantado desde `/pruebas`.
9. Una partida vieja (ya tenía barrios descubiertos) y una partida nueva.

## 10. Lo que NO se ha hecho como pedía la especificación (y la alternativa)

1. **«PremiumOwned» para siempre con un único Game Pass:** un Game Pass es permanente. Con un solo pase, quien lo comprara en la temporada 1 tendría premium gratis en todas. **Alternativa:** cada temporada tiene su propio `GamePassId`, y en `SeasonArchive` queda qué premium tuvo cada uno. (Otra opción para el futuro: un Developer Product por temporada con `ProcessReceipt`, que ya existe en `MonetizationService`).
2. **Barco premium sin sistema de barcos:** crear barcos jugables ahora sería un sistema aparte y a medias. **Alternativa:** `BoatAdapter` guarda la lancha como tuya y la interfaz dice «Llega con el puerto deportivo». *Recomendación:* si el puerto deportivo no va a llegar en estas 9 semanas, cambiar el nivel 35 premium por otro acabado de vehículo, para no vender algo que aún no se puede usar.
3. **Casa o ático premium nuevo** (opción A): rompería el registro de viviendas y la economía inmobiliaria. **Se ha hecho la opción B:** temas que se aplican a tu vivienda de siempre, más decoración.
4. **Más huecos en la mochila** como comodidad: `Items.Slots` es fijo y lo usa todo el inventario, y cambiarlo tiene riesgo. **Alternativa:** la comodidad «Cambio de misión diaria», que no toca la economía.
5. **Reclamar las premium a mano tras comprar:** se ha elegido entregarlas **solas** (`AutoClaimRetroactiveOnPurchase = true`), porque al pagar se espera recibir. Se puede cambiar a mano en la configuración.
6. **Aviso sobre algo que ya existe (no se ha tocado):** el VIP actual (`Config.GamePasses.VIP`) cobra ×2 el sueldo, y eso es *pay-to-win* según los principios de esta misma especificación y de `docs/diseno/14-monetizacion.md` (que propone +25 %). No se ha cambiado; lo decide el dueño.

## 11. Pasos para el dueño

1. **Crear el Game Pass:** create.roblox.com → tu experiencia → *Monetización* → *Pases* → *Crear un pase*.
   - Nombre: «Pase Premium · Temporada 1: Luces de Valmar». Descripción: las 50 recompensas premium, **sin presión** («Consigue el conjunto legendario Faro de Valmar y 50 recompensas premium»). Icono 512×512.
   - Ponlo **a la venta** y elige el precio. Para unos 4,99 € de valor, entre **399 y 499 Robux** (se puede cambiar cuando quieras sin tocar el código).
2. **Copiar su ID** (el número de la URL del pase) en `src/shared/BattlePass/Season1.luau` → `GamePassId = …`. Con 0, la compra está desactivada y la interfaz enseña «Próximamente».
3. **Encender el pase** cuando esté la interfaz: `BattlePassConfig.Enabled = true` en `src/shared/BattlePass/Config.luau`.
4. **Probar en Studio** con `/pruebas` → Pase de temporada: *Premium simulado*, *+XP*, *Nivel* y *Día siguiente*. Todo eso es solo para ti y no cuenta como compra.
5. **Temporada 2:** copia `Season1.luau` como `Season2.luau`, cambia Id, fechas, `GamePassId` (un pase **nuevo**), recompensas (Ids nuevos, **nunca** reutilizar) y misiones, y añádela a `BattlePassConfig.Seasons`.

## 12. Contrato de la interfaz (para el agente de UI)

Remoto: `ReplicatedStorage.Remotes.BattlePass` (RemoteEvent). El servidor lo crea solo si `Enabled = true`. En el cliente, usa `src/client/Controllers/BattlePassClient.luau`: `start()`, `onState(fn)`, `on(kind, fn)`, `refresh()`, `claim(track, level)`, `claimAll()`, `buy()`, `equip(slot, id, kind?)`, `track(missionId | nil)`, `reroll(missionId)`, `choose(storyId, optionId)` y `buyToken(itemId)`. `start()` no hace nada si el pase está apagado, y `Main.client` todavía no lo carga.

### Cliente → servidor (`FireServer(action, a, b, c)`)

| action | a | b | c |
|---|---|---|---|
| `"Get"` | — | — | — |
| `"Claim"` | `"Free"` / `"Premium"` | nivel (número entero) | — |
| `"ClaimAll"` | — | — | — |
| `"Buy"` | — | — | — |
| `"Equip"` | hueco: `Title`, `Nameplate`, `PhoneTheme`, `HudSkin`, `HomeTheme`, `Outfit`, `VehicleSkin` o `Decor` | Id (o `nil` para quitar; en `Decor` pone o quita ese objeto, máx. 6) | tipo de vehículo (solo `VehicleSkin` con Id `nil`) |
| `"Track"` | Id de misión o de historia (o `nil`) | — | — |
| `"Reroll"` | Id de misión diaria | — | — |
| `"StoryChoice"` | Id de la historia (`"H_Faro"`) | Id de la opción | — |
| `"BuyToken"` | Id del artículo | — | — |

### Servidor → cliente (`OnClientEvent(kind, payload)`)

- `"State"`: estado completo (abajo). Llega tras `Get` y, agrupado cada 0,5 s como máximo, tras cualquier cambio.
- `"Result"`: `{ Action, Ok, Code?, Message?, … }`. Códigos: `Locked`, `PremiumLocked`, `AlreadyClaimed`, `SeasonClosed`, `NotStarted`, `RetryLater`, `ComingSoon`, `AlreadyPremium`, `BadRequest`, `NotOwned`, `DecorFull`, `NotEnoughTokens`, `NoPerk`, `AlreadyRerolled`, `NoData`, `Compensated`, `NoPlace`. `Message` es el texto en español. Con `Claim` también llega `Reward = { Id, Name, Icon, Rarity }`; con `ClaimAll`, `Given = { {Level, Track, Id, Name, Icon} }`.
- `"Unlocked"`: `{ From, Level, Rewards = { {Level, Track, Id, Name, Icon, Rarity, Premium, State} } }`. Sirve para el aviso discreto «RECOMPENSA DESBLOQUEADA».
- `"MissionDone"`: `{ Id, Kind, Title, Xp, Tokens }`.
- `"Premium"`: `{ Owned = true, Given = {…} }`, justo después de la compra.
- Además, el servidor manda sus avisos por `Notify` («Success» / «Info» / «Error»), así que funciona aunque no haya panel.

### Forma de `State`

```
{
  Season = { Id, Number, Name, Subtitle, Theme, StartsAt, EndsAt, ClaimUntil, Now, Status ("Upcoming"|"Active"|"Grace"|"Ended"), MaxLevel, Colors = { Primary, Accent, Text } },
  Premium = { Owned, Purchased, Simulated, PurchaseEnabled, ComingSoon, GamePassId, PriceRobux?, RewardCount },
  Progress = { Level, Xp, XpForNext, TotalXp, IsMax, Available, Tokens, DailyXp, DailyCap, EventMultiplier },
  Rewards = { -- 100, ordenadas por nivel (gratis antes que premium)
    { Id, Level, Track ("Free"|"Premium"), Type, TypeName, Name, Description, Icon, Rarity, RarityName, RarityColor,
      Amount?, Kind?, State ("LOCKED"|"AVAILABLE"|"CLAIMED"|"PREMIUM_LOCKED"), Milestone (cada 5), Owned,
      Preview? = { Kind ("Vehicle"|"Decor"|"Outfit"|"Emote"|"HomeTheme"|"Boat"|<Type>), Model? ("BattlePassPreviews/<Id>"), Vehicle?, Color?, Colors?, Material?, AnimationId?, Speed?, Loop? },
      Items? (Bundle: { {Id, Type, TypeName, Name, Icon, Preview} }), Usable?/UsableText? (Boat) } },
  Missions = {
    Daily = { ResetsAt, List = { Mission } }, Weekly = { ResetsAt, List }, Season = { List }, Event = { List (+ EventName, EndsAt) },
    Story = { { Id, Title, Icon, Intro, Phase, Phases, Done, Choice?, Tracked, Reward = {Id, Name, Icon},
                Current? = { Id, Title, Text, Progress, Goal, Xp, Place?, Choices? = { {Id, Text} } } } },
    Tracked, CanReroll },
  -- Mission = { Id, Kind, Title, Description, Icon, Progress, Goal, Unit? ("km"), Xp, Tokens?, Done, Place?, Tracked }
  Events = { { Id, Name, Icon, EndsAt, XpMultiplier } },
  Equipped = { Title?, Nameplate?, PhoneTheme?, HudSkin?, HomeTheme?, Outfit?, VehicleSkin = { [kind] = Id }, Decor = { Id } },
  Collection = { { Id, Type, Name, Icon, Rarity, Season, Kind? } },
  TokenShop = { { Id, Type, TypeName, Name, Icon, Rarity, Cost, Description, Owned, Preview } },
  History = { { SeasonId, Name, Level, PremiumOwned, ArchivedAt } },
  Tester? = { SimulatedPremium, RealPremium, Level, ClockShift },  -- solo para testers
}
```

**Vista previa 3D:** con el pase encendido, el servidor monta en `ReplicatedStorage.BattlePassPreviews` un modelo por cada acabado de vehículo y cada decoración, con el nombre del Id de la recompensa. Clónalo en un `ViewportFrame` y gíralo. En los conjuntos, `Preview.Model` apunta al vehículo o la decoración de dentro. Para la ropa (`Preview.Colors`, con claves `Hoodie`, `HoodLining`, `Tee`, `Pants`, `Shoes`) y los gestos (`AnimationId`), usa un clon del personaje local. Los temas de vivienda (`Floor`, `Wall`, materiales) y los barcos no tienen modelo: pinta una muestra de colores y el icono.

**Datos de los cosméticos equipados** (para el HUD, el teléfono y los nombres): la definición completa está en `require(ReplicatedStorage.Shared.BattlePass.Catalog).get(id)`: `Colors` de placas y temas, `Text` y `Color` de los títulos, `AnimationId` de los gestos.

**Atributos del jugador:** `BP_Season`, `BP_Level`, `BP_Premium`, `BP_PremiumSimulated`, `BP_Title`, `BP_TitleColor`, `BP_Nameplate`, `BP_PhoneTheme`, `BP_HudSkin`, `BP_Outfit`, `BP_HomeTheme`, `BP_Emotes` (Ids separados por comas), `BP_Tokens`, `SeasonTarget` (Vector3), `SeasonTargetName`.

**Modo pruebas:** remoto `Tester` → `FireServer("Action", "BattlePass", { Op = "Premium" | "AddXp" | "SetLevel" | "NextDay" | "NextWeek" | "ResetClock" | "Reset", Value = n })`. `TesterService.state(player).BattlePass` trae el estado para el panel.

**UX (§23–29):** panel compacto (no a pantalla completa), con título, «TEMPORADA 01», barra de XP, «NIVEL x/50», pestañas GRATIS / PREMIUM, la recompensa actual con [RECLAMAR], una fila de niveles y una misión destacada. La compra se presenta sin presión: «PASE PREMIUM · Temporada 1 · 50 recompensas · [Vista previa] [Comprar]». Si `ComingSoon`, «Próximamente». En móvil, botones grandes y desplazamiento táctil; en PC, hover, tooltips y una tecla rápida.
