# Pase de temporada

Diseño, reglas y contrato del **pase de temporada** de Real Life Simulator. La temporada 1 se llama **«Luces de Valmar»**.

> **Interruptor general:** `BattlePassConfig.Enabled` (en `src/shared/BattlePass/Config.luau`) está **encendido** (`true`) desde el 1-oct-2026 (la Temporada 1 empieza el 5-oct-2026). Apagado (`false`), el pase no hace nada: no se crea el remoto, no se escuchan eventos, no se entregan recompensas, no hay ganchos en vehículos, ropa ni vivienda, y la interfaz no aparece. En los datos guardados solo quedan los valores por defecto, que no hacen nada. Con `false` se apaga del todo.

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
| `VehicleService.grant` + `Rides.build(…, color, style)` | Vehículos del juego y su acabado exclusivo (el mismo modelo con otro color); los 13 premium, con su propio modelo (`style.Model`). |
| `ArcadeService` (gafas, gorra, tickets) | Accesorios y tickets. Se han añadido `grantPrize` y `addTickets`. |
| `AvatarService` (aspecto de Valmar) | Conjuntos de ropa: son colores que cambian los del aspecto de Valmar. |
| `PropertyService` (interiores de las viviendas) | Tema de vivienda (opción B de la especificación) y decoración, en tu vivienda de siempre. |
| `ProgressionService.addXp` | Recompensas de XP de personaje. |
| `LocationService.resolve` + `TaskMarker` | GPS de las misiones: la misión que sigues pone el atributo `SeasonTarget`. |
| `TesterService` (`/pruebas`) | Premium simulado, sumar XP, poner nivel y adelantar el reloj. |
| Aviso `Notify` | Avisos discretos («¡nivel 12!», «misión completada») aunque todavía no haya interfaz. |

**Lo que no existía** (y cómo se ha resuelto sin inventar un sistema incompatible):

- **Barcos propios:** ya existen (`Services/BoatService`, `shared/Boats`). La recompensa «Lancha Gaviota» (`Boat = "Gaviota"`) pasa por `BoatAdapter` (en `BattlePassRewardService`) a `BoatService.grant(player, kind, def)`: se guarda en `data.Boats` (y en la colección, así vuelve sola después de «Vida nueva») y sale en el menú de la oficina «⚓ Barcos» del **puerto deportivo** (costa oeste). Allí se saca a un amarre del pantalán y se pilota con los mismos mandos que el coche; solo navega por el mar. La interfaz recibe `Usable = true` y `UsableText = "⚓ Se saca en el puerto deportivo"`. En el puerto deportivo también se compra la lancha normal (7.500 €), con las mismas prestaciones.
- **Títulos, placas y temas del teléfono y del HUD:** no había. Se guardan en la colección y se publican como atributos del jugador (`BP_Title`, `BP_Nameplate`, `BP_PhoneTheme`, `BP_HudSkin`…) para que la interfaz los pinte. `BP_Title` y `BP_TitleColor` también los ven los demás jugadores. Solo el servidor los pone y solo con lo que tienes **y** llevas equipado. Se pintan así: título y placa en el cartel de nombre de siempre (`Controllers/NameTags`, sobre los demás jugadores); tema del HUD = color del filo de los paneles (`Theme.setAccent("Hud")`); tema del teléfono = fondo de pantalla del ValPhone (`Theme.setAccent("Phone")`, `UI/Phone`). Lo lee `UI/BattlePassCosmetics`; con el pase apagado no se pinta nada.
- **Gestos nuevos:** `Actions` tiene una lista fija. Los gestos del pase van en `BP_Emotes`, que es una lista de Ids con su `AnimationId`. `Controllers/Actions` los suma a sus gestos y salen en la app «Gestos pase» del ValPhone. Ahora usan animaciones públicas de Roblox, algunas con otra velocidad; el dueño puede cambiarlas por animaciones propias en `Season1.luau`.
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
| `src/client/Controllers/BattlePassClient.luau` | Envoltorio del remoto para la interfaz. No pinta nada. Al conectar pide el primer estado (`Get`). |
| `src/client/UI/BattlePassUI.luau` | La ventana del pase y sus entradas (app «Pase» del ValPhone, tecla N, aviso «RECOMPENSA DESBLOQUEADA»). Con el pase apagado no hace nada. |
| `src/client/UI/BattlePassLayout.luau` | Medidas de la ventana en el ordenador y en el móvil (puro: lo prueba `test-battlepassui`). |
| `src/client/UI/BattlePassView.luau` | Textos y cuentas de la interfaz (estados, días, siguiente recompensa, misión destacada…). |
| `src/client/UI/BattlePassRewardCard.luau` | La tarjeta de cada recompensa de la fila 01…50. |
| `src/client/UI/BattlePassPages.luau` | Las secciones MISIONES y FICHAS. |
| `src/client/UI/BattlePassPreview.luau` | Vista previa 3D que se gira (ViewportFrame) o, si no hay modelo, icono y muestra de colores. |
| `scripts/test-battlepassui.luau` | Prueba de la interfaz con Lune: estados, peticiones y que nada se pise en 10 tamaños de pantalla. |
| `scripts/test-battlepass.luau` | Prueba con Lune (126 comprobaciones). |

Los servicios se arrancan en `Main.server.luau` justo después de `CityErrandService`.

### Cambios en sistemas existentes (todos inofensivos con el pase apagado)

| Archivo | Cambio | Por qué | Riesgo |
|---|---|---|---|
| `DataService` | Añade `BattlePass`, `Cosmetics` y `SeasonArchive` a `DEFAULT_DATA`. `newLife` las conserva. | Guardar el pase en la misma partida. Lo conseguido no se pierde con una vida nueva. | Solo campos nuevos. `reconcile` ya los crea en las partidas viejas. |
| `VehicleService` | Ganchos `PaintFor` (el color del acabado equipado) y `ModelFor` (el vehículo premium equipado) en `mount`. Cuenta la distancia de cada viaje (`ride.Driven`) y emite `VehicleTrip` al bajarse, solo si el pase está encendido. | Acabados exclusivos y misiones de km. | Sin gancho, el color sigue saliendo al azar. Los saltos de más de 200 studs (teletransportes) no cuentan. |
| `AvatarService` | Gancho `OutfitFor` (devuelve la definición del conjunto). Los 30 de la hoja (`Outfit` = clave de `shared/Outfits`) los viste `shared/OutfitBuilder`; los de solo `Colors` se mezclan con `Config.DefaultLook`. | Conjuntos de ropa (ver «Conjuntos de ropa»). | Sin gancho, el aspecto no cambia. La piel no se toca. Bebé: pelele. De servicio con uniforme o en prisión: se guarda. |
| `PropertyService` | Gancho `DecorateOwned` en `decorate` (solo viviendas con dueño), con `pcall`. | Tema de vivienda y decoración. | Solo cambia colores y añade piezas decorativas sin colisión. No toca el registro de dueños. |
| `ArcadeService` | Nuevas `grantPrize` y `addTickets`. | Entregar accesorios y tickets. | Funciones nuevas: no cambian nada de lo que ya había. |
| `LifeStoryService` | `discoverZone` emite `ZoneEntered` al cambiar de barrio, solo con el pase encendido. | Misiones de barrios y explorar. | El descubrimiento de siempre no cambia. |
| `CityErrandService` | `finish` emite `ErrandDone`, solo con el pase encendido. | Misiones de encargos. | Nada más. |
| `TesterService` | Acción `"BattlePass"` y `state().BattlePass`. | Probar el pase desde el panel. | Con el pase apagado devuelven `false` / `nil`. |
| `TaskMarker` (cliente) | También sigue `SeasonTarget`, después de `StoryTarget` (y escucha sus cambios). | GPS de las misiones del pase. | Sin ese atributo, nada cambia. |
| `Gps` y `MapUI` (cliente) | `SeasonTarget` como último objetivo (ruta por las calles y marca en el mapa). | GPS de las misiones del pase. | Sin ese atributo, nada cambia. |
| `Main.client` | Arranca `UI/BattlePassUI` con `safeInit`. La interfaz pide el estado con `Get` + `"Ui"` y entonces el servidor ya no manda el `Notify` «¡nivel n!» (sale solo «RECOMPENSA DESBLOQUEADA»; `Unlocked.Notified` dice si el servidor avisó). | Interfaz del pase. | Con el pase apagado, `init` vuelve enseguida. |
| `TesterPanel` (cliente) | Sección «PASE DE TEMPORADA» (premium simulado, +XP, nivel, reloj, reiniciar, abrir el pase). Solo sale si el servidor manda `BattlePass`. | Probar el pase. | Con el pase apagado no sale. |

## 4. Recompensas de la temporada 1 «Luces de Valmar»

Hay un hito cada 5 niveles (en negrita). El nivel 50 premium es el conjunto **legendario «Faro de Valmar»**: el superdeportivo **Aurora X «Faro de Valmar»** (blanco perla con negro y detalles en oro), el título «Leyenda de Valmar», su placa y un faro en miniatura para tu casa.

| Nivel | Gratis | Premium |
|---|---|---|
| 1 | 🏙️ Vecino/a de Valmar (Título) | 🧥 Chaqueta Luces de Valmar (Ropa, Rara) |
| 2 | 💶 150 € (Dinero) | 🗼 Saludo del faro (Gesto, Rara) |
| 3 | 🪴 Planta de Villaverde (Decoración) | 📱 Neón del Centro (Tema teléfono, Rara) |
| 4 | 🎟️ 40 tickets (Tickets) | 🏎️ Voltex GT-R (Deportivo premium, Rara) |
| **5** | 🕶️ Gafas de sol (Accesorio, Rara) | 🛴 Patinete Brisa Marina (Vehículo exclusivo, Épica) |
| 6 | ⭐ +150 XP de personaje (XP personaje) | 💡 Lámpara de pie Altamar (Decoración, Rara) |
| 7 | 👏 Aplauso de la plaza (Gesto) | 🌅 Placa Atardecer (Placa, Rara) |
| 8 | 💶 200 € (Dinero) | 🌃 HUD Noche de Valmar (Estilo HUD, Rara) |
| 9 | 🖼️ Póster del Estadio Altamar (Decoración) | 🏘️ Alma de San Roque (Título, Rara) |
| **10** | 🏷️ Placa Valmar Clásica (Placa, Rara) | ⚓ Loft del Puerto (Tema vivienda, Épica) |
| 11 | 🎟️ 60 tickets (Tickets) | 💃 Baile de verbena (Gesto, Rara) |
| 12 | 🌄 Madrugador/a (Título) | 🏍️ Nexus R (Moto premium, Rara) |
| 13 | 💶 250 € (Dinero) | 🩳 Conjunto Playa Dorada (Ropa, Épica) |
| 14 | 🛋️ Cojines de Los Pinos (Decoración) | 🌅 Atardecer en Playa Dorada (Tema teléfono, Rara) |
| **15** | 🚲 Bici Verde Villaverde (Vehículo exclusivo, Rara) | 🛵 Moto Brisa de Playa Dorada (Vehículo exclusivo, Épica) |
| 16 | ⭐ +200 XP de personaje (XP personaje) | 🏎️ Zenith (Deportivo premium, Rara) |
| 17 | 🧘 Estiramiento del parque (Gesto) | 🐠 Acuario de la Isla de las Gaviotas (Decoración, Épica) |
| 18 | 💶 250 € (Dinero) | 🚇 Ruta del Metro (Título, Rara) |
| 19 | 📱 Clásico de Valmar (Tema teléfono) | ✨ HUD Faro Dorado (Estilo HUD, Épica) |
| **20** | 🧢 Gorra (Accesorio, Rara) | 🌆 Colección Noche en el Centro (Conjunto, Épica) |
| 21 | 🎟️ 80 tickets (Tickets) | 🕺 Paso del Distrito (Gesto, Rara) |
| 22 | 🕰️ Reloj de la estación (Decoración) | 💜 Placa Neón (Placa, Épica) |
| 23 | 🧭 Explorador/a de distritos (Título) | ☕ Mesa de terraza (Decoración, Rara) |
| 24 | 🏠 Piso luminoso de Valmar Norte (Tema vivienda, Rara) | 🏎️ Strato RS (Deportivo premium, Épica) |
| **25** | 🏎️ **Kairo S (Deportivo, Rara: ¡gratis para todos!)** | 🏙️ Ático Distrito Financiero (Tema vivienda, Épica) |
| 26 | ⭐ +250 XP de personaje (XP personaje) | 🤵 Traje de gala de Altamar (Ropa, Épica) |
| 27 | 📸 Foto de turista (Gesto) | 🚆 Maqueta del Cercanías (Decoración, Rara) |
| 28 | 📚 Estantería del Campus (Decoración) | 🏍️ Blaze 1000 (Moto premium, Épica) |
| 29 | 🎟️ 100 tickets (Tickets) | 🌊 Mar de Valmar (Tema teléfono, Rara) |
| **30** | 🏷️ Placa Temporada 1 (Placa, Rara) | 🔄 Cambio de misión diaria (Comodidad, Épica) |
| 31 | 💶 300 € (Dinero) | 🏟️ Celebración del estadio (Gesto, Épica) |
| 32 | 🛠️ Currante de Valmar (Título) | 🏎️ Raven T7 (Deportivo premium, Épica) |
| 33 | 🏖️ Alfombra de playa (Decoración) | 🌙 Noctámbulo/a (Título, Rara) |
| 34 | ⭐ +300 XP de personaje (XP personaje) | 🌌 HUD Aurora (Estilo HUD, Épica) |
| **35** | 👕 Sudadera Temporada 1 (Ropa, Rara) | 🚤 Lancha «Gaviota» (Barco, Épica) |
| 36 | 🎟️ 120 tickets (Tickets) | 🏎️ Inferno (Superdeportivo premium, Épica) |
| 37 | ⚓ Saludo marinero (Gesto) | 🌊 Placa Marina (Placa, Épica) |
| 38 | 💶 350 € (Dinero) | 🧥 Cortavientos del puerto (Ropa, Épica) |
| 39 | 🗺️ Mapa de Valmar (Tema teléfono, Rara) | 🏎️ Obsidian (Superdeportivo premium, Épica) |
| **40** | ❤️ Corazón de Valmar (Título, Rara) | 🗼 Terraza del Faro (Conjunto, Épica) |
| 41 | 🪑 Banco del parque (Decoración) | 💫 Baile del faro (Gesto, Épica) |
| 42 | 💶 350 € (Dinero) | 🏍️ Storm (Moto premium, Legendaria) |
| 43 | 🎟️ 150 tickets (Tickets) | ⛰️ Leyenda del Monte (Título, Épica) |
| 44 | ⭐ +350 XP de personaje (XP personaje) | 🏎️ Víbora GT (Superdeportivo premium, Legendaria) |
| **45** | 🥈 Placa Plata (Placa, Épica) | 🗼 Conjunto Faro de Valmar (Ropa, Épica) |
| 46 | 🙇 Reverencia (Gesto) | 💌 Postal: la noche del faro (Recuerdo, Rara) |
| 47 | 💶 400 € (Dinero) | 🏆 HUD Leyenda (Estilo HUD, Épica) |
| 48 | 🏆 Trofeo de la temporada (Decoración) | 🥇 Placa Oro (Placa, Épica) |
| 49 | 🪙 3 fichas de temporada (Fichas) | 🏎️ Shadow F1 (Superdeportivo premium, Legendaria) |
| **50** | 🎖️ Recuerdo de la Temporada 1 (Conjunto, Épica) | 🗼 Faro de Valmar (Conjunto, Legendaria) |

**Dinero:** 2.250 € en toda la pista gratis y nada en la premium (donde había dinero ahora hay vehículos). Es poco: un coche cuesta 9.000 €. Casi todo lo demás son cosméticos.
**Vehículos:** los acabados exclusivos (patinete del 5, bici del 15, moto del 15 premium) son el **mismo vehículo del juego** con otro color. Tienen la misma velocidad y el mismo manejo: se diferencian en el diseño y el prestigio (§9). Con `GrantsBase = true` también dan el vehículo normal si no lo tenías. Para conducir siguen haciendo falta la edad y el carnet de siempre.

### 4.1 Los 13 vehículos premium

La hoja del dueño trae 5 deportivos, 5 superdeportivos y 3 motos. Son las recompensas que se pagan, así que son **los vehículos con más detalle del juego** (hasta 220 piezas cada coche y 140 cada moto, solo primitivas). Los datos están en `src/shared/PremiumVehicles.luau` y los construye `src/server/World/Kit/SportsCars.luau` (lo llama `Rides.build(kind, …, { Model = id })`). En la recompensa van como `VehicleSkin` con `Model = id` (y `Color`, `Stats`, `Premium = true`, `GrantsBase = true`).

- **Sin pagar para ganar (regla del dueño):** cada uno es un **«Coche» o una «Moto» del juego** con otro diseño. Corre, acelera, frena y gira **exactamente igual** que el coche (o la moto) que se compra con dinero del juego, que ya es el más rápido de los que se ganan jugando. Las barras de la interfaz lo dicen: Velocidad y Manejo iguales a las del coche / la moto de siempre; la **Estética** es donde brillan (4 raros, 5 épicos y legendarios). Las diferencias: diseño, firma de luces, tono del motor (`EnginePitch`) y prestigio.
- **Premium = true** (en la ficha y como atributo del modelo): no se pinchan y gastan menos (`shared/Tyres`, `Gameplay.Fuel.PremiumFactor`). Lo decidió el dueño.
- **Sin marcas:** ningún logo ni insignia (las matrículas dicen VALMAR y la zaga lleva el nombre del modelo en letras cromadas). Dos nombres de la hoja coincidían con modelos de verdad y se han cambiado: **Strato RS** y **Víbora GT**. El muscle car tiene silueta propia y la parrilla no lleva emblema. El logo de la hoja no es del juego y no aparece en ningún sitio.
- **Cómo se sacan:** el que tengas equipado en el hueco `VehicleSkin` de su tipo (`Coche` o `Moto`) sale al sacar ese vehículo (`VehicleService.ModelFor` ← `BattlePassRewardService.modelFor`). El primero se equipa solo, y uno con modelo propio sustituye a un acabado que es solo color. Se cambia desde el pase («Equipar»).
- **Taller:** admiten pintura (también la secundaria: franjas y techo negro), acabado, llantas y su color, neumáticos, lunas tintadas, neón y matrícula, con sus propias anclas y ruedas (`VehicleParts.anchorsFor / wheelsFor / zonesFor / referenceFor`). Alerones y parachoques del taller no: ya traen los suyos.
- **Vistas previas 3D:** `BattlePassService` monta cada uno en `ReplicatedStorage.BattlePassPreviews` con su modelo.

| Nº | Vehículo | Tipo | Rareza | Nivel | Firma |
|---|---|---|---|---|---|
| 01 | Voltex GT-R (azul) | Deportivo 2+2 | Rara | 4 premium | Faros afilados con luz diurna en bumerán, 4 pilotos redondos, alerón GT, 2 rejillas en el capó, aletines, llantas de 10 radios, pinzas rojas, escape cuádruple. 4 plazas. |
| 02 | Strato RS (rojo) | Deportivo | Épica | 24 premium | Morro bajo y redondo, luces diurnas en colmillo, cola de pato, pilotos partidos, branquias laterales, escape doble central, pinzas amarillas. |
| 03 | Kairo S (plata) | Deportivo | Rara | **25 gratis** | Dos franjas negras de punta a punta, faros redondos con aro de luz, piloto de lado a lado, labio trasero, llantas bronce en Y. |
| 04 | Raven T7 (amarillo) | Muscle car | Épica | 32 premium | Silueta propia: frontal recto, faros dentro de la parrilla con barra de luz, toma de aire en el capó, franjas y techo negros, cola de pato, molduras cromadas, escape cuádruple, motor grave. 4 plazas. |
| 05 | Zenith (turquesa) | Deportivo | Rara | 16 premium | Barra de luz de lado a lado delante y detrás, branquias, labio trasero, llantas de malla color cobre, motor agudo. |
| 06 | Shadow F1 (negro mate) | Superdeportivo | Legendaria | 49 premium | Líneas de luz cian (taloneras, hombros, splitter, difusor, tomas), neón cian debajo, flechas de luz diurna, toma de aire de monoplaza en el techo con aleta de tiburón, alerón de cuello de cisne, escape central y luz de lluvia. |
| 07 | Inferno (rojo) | Superdeportivo | Épica | 36 premium | Luces en Y delante y detrás, rejillas negras en el capó, tomas laterales, aletines, alerón GT, escapes altos. |
| 08 | Aurora X (blanco) | Superdeportivo | Legendaria | 50 premium (conjunto «Faro de Valmar») | Capó con franja negra, techo y bajos negros, firma de luz en X delante y detrás, alerón activo. En el conjunto: blanco perla con pinzas y detalles en oro. |
| 09 | Obsidian (negro morado) | Superdeportivo | Épica | 39 premium | Líneas de luz violeta, neón violeta debajo, cristales tintados en violeta, 6 lamas en la tapa del motor, flechas de luz diurna. |
| 10 | Víbora GT (verde) | Superdeportivo | Legendaria | 44 premium | Colmillos de luz, techo de doble burbuja, rejillas enormes en el capó, alerón de cuello de cisne, aletines, pinzas amarillas. |
| 11 | Nexus R (azul noche) | Moto naked | Rara | 12 premium | Chasis multitubular a la vista, faro desnudo con luz diurna, manillar ancho, horquilla dorada, retrovisores, escape bajo el motor. |
| 12 | Blaze 1000 (roja) | Moto deportiva | Épica | 28 premium | Carenado completo con rejillas y franja, doble faro, cúpula ahumada, semimanillares, colín afilado con LED en V. |
| 13 | Storm (blanca y morada) | Moto deportiva | Legendaria | 42 premium | Alerones en el carenado, líneas de luz violeta, llantas moradas, colín con LED. |

Todos los coches llevan: carrocería por perfiles con los pasos de rueda abiertos, splitter, taloneras, tomas de aire, difusor con 4 aletas, escapes, retrovisores con espejo, cristales con montantes, interior (asientos baquet con costura de color, volante, salpicadero con brillo, pantalla y cuadro), matrículas VALMAR, nombre en la zaga, intermitentes, marcha atrás, freno central y ruedas de perfil bajo con llanta de radios, disco y pinza de color (las pinzas giran con el volante, no ruedan). Las motos llevan horquilla invertida, discos y pinzas, basculante, amortiguador con muelle de color, motor, radiador, escape, depósito, asiento y asiento de pasajero, colín, estriberas, cadena y pata de cabra.

**¿Por qué el «Faro de Valmar» sigue en el 50?** La temporada entera cuenta la historia del faro: el 50 tenía que seguir siendo ese conjunto. Antes su coche era una berlina pintada; ahora es el superdeportivo legendario Aurora X con el acabado «Faro de Valmar» (mismo Id `S1_P50_Car`, así que la pintura «Perla Faro» y las llantas «Faro dorada» del taller siguen desbloqueándose con él).
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
2. **Barco premium:** resuelto. El puerto deportivo ya tiene barcos propios (`BoatService`): la «Gaviota» se saca, se pilota con pasajeros y se guarda. Es solo estética: misma velocidad que la lancha que se compra con dinero del juego.
3. **Casa o ático premium nuevo** (opción A): rompería el registro de viviendas y la economía inmobiliaria. **Se ha hecho la opción B:** temas que se aplican a tu vivienda de siempre, más decoración.
4. **Más huecos en la mochila** como comodidad: `Items.Slots` es fijo y lo usa todo el inventario, y cambiarlo tiene riesgo. **Alternativa:** la comodidad «Cambio de misión diaria», que no toca la economía.
5. **Reclamar las premium a mano tras comprar:** se ha elegido entregarlas **solas** (`AutoClaimRetroactiveOnPurchase = true`), porque al pagar se espera recibir. Se puede cambiar a mano en la configuración.
6. **Aviso sobre algo que ya existe (no se ha tocado):** el VIP actual (`Config.GamePasses.VIP`) cobra ×2 el sueldo, y eso es *pay-to-win* según los principios de esta misma especificación y de `docs/diseno/14-monetizacion.md` (que propone +25 %). No se ha cambiado; lo decide el dueño.

## 11. Pasos para el dueño

1. **Crear el Game Pass** ✅ *Hecho (1-oct-2026): «Pase Premium · Temporada 1», id **2002430944**, **449 Robux**, a la venta, icono `assets/icons/pase-premium.png`. Creado con Open Cloud (`POST https://apis.roblox.com/game-passes/v1/universes/{universeId}/game-passes`; la clave necesita el sistema **game-passes** con `game-pass:read` y `game-pass:write`).* A mano: create.roblox.com → tu experiencia → *Monetización* → *Pases* → *Crear un pase*.
   - Nombre: «Pase Premium · Temporada 1: Luces de Valmar». Descripción: las 50 recompensas premium, **sin presión** («Consigue el conjunto legendario Faro de Valmar y 50 recompensas premium»). Icono 512×512.
   - Ponlo **a la venta** y elige el precio. Para unos 4,99 € de valor, entre **399 y 499 Robux** (se puede cambiar cuando quieras sin tocar el código).
2. ✅ *Hecho: `GamePassId = 2002430944`.* **Copiar su ID** (el número de la URL del pase) en `src/shared/BattlePass/Season1.luau` → `GamePassId = …`. Con 0, la compra está desactivada y la interfaz enseña «Próximamente».
3. ✅ *Hecho.* **Encender el pase**: `BattlePassConfig.Enabled = true` en `src/shared/BattlePass/Config.luau`.
4. **Probar en Studio** con `/pruebas` → Pase de temporada: *Premium simulado*, *+XP*, *Nivel* y *Día siguiente*. Todo eso es solo para ti y no cuenta como compra.
5. **Temporada 2:** copia `Season1.luau` como `Season2.luau`, cambia Id, fechas, `GamePassId` (un pase **nuevo**), recompensas (Ids nuevos, **nunca** reutilizar) y misiones, y añádela a `BattlePassConfig.Seasons`.

## 12. Contrato de la interfaz (para el agente de UI)

Remoto: `ReplicatedStorage.Remotes.BattlePass` (RemoteEvent). El servidor lo crea solo si `Enabled = true`. En el cliente, usa `src/client/Controllers/BattlePassClient.luau`: `start()`, `onState(fn)`, `on(kind, fn)`, `refresh()`, `claim(track, level)`, `claimAll()`, `buy()`, `equip(slot, id, kind?)`, `track(missionId | nil)`, `reroll(missionId)`, `choose(storyId, optionId)` y `buyToken(itemId)`. `start()` no hace nada si el pase está apagado. Lo arranca `UI/BattlePassUI` (desde `Main.client`), solo con el pase encendido.

### Cliente → servidor (`FireServer(action, a, b, c)`)

| action | a | b | c |
|---|---|---|---|
| `"Get"` | `"Ui"` (opcional: la interfaz enseña el aviso de nivel; el servidor no manda su `Notify`) | — | — |
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
      Preview? = { Kind ("Vehicle"|"Decor"|"Outfit"|"Emote"|"HomeTheme"|"Boat"|<Type>), Model? ("BattlePassPreviews/<Id>"), Outfit? (clave de shared/Outfits), Vehicle?, Color?, Colors?, Material?, AnimationId?, Speed?, Loop? },
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

**Vista previa 3D:** con el pase encendido, el servidor monta en `ReplicatedStorage.BattlePassPreviews` un modelo por cada acabado de vehículo, cada barco y cada decoración, con el nombre del Id de la recompensa. Clónalo en un `ViewportFrame` y gíralo. En los conjuntos, `Preview.Model` apunta al vehículo o la decoración de dentro. Para la ropa (`Preview.Colors`, con claves `Hoodie`, `HoodLining`, `Tee`, `Pants`, `Shoes`) y los gestos (`AnimationId`), usa un clon del personaje local. Los temas de vivienda (`Floor`, `Wall`, materiales) no tienen modelo: pinta una muestra de colores y el icono.

**Datos de los cosméticos equipados** (para el HUD, el teléfono y los nombres): la definición completa está en `require(ReplicatedStorage.Shared.BattlePass.Catalog).get(id)`: `Colors` de placas y temas, `Text` y `Color` de los títulos, `AnimationId` de los gestos.

**Atributos del jugador:** `BP_Season`, `BP_Level`, `BP_Premium`, `BP_PremiumSimulated`, `BP_Title`, `BP_TitleColor`, `BP_Nameplate`, `BP_PhoneTheme`, `BP_HudSkin`, `BP_Outfit`, `BP_HomeTheme`, `BP_Emotes` (Ids separados por comas), `BP_Tokens`, `SeasonTarget` (Vector3), `SeasonTargetName`.

**Modo pruebas:** remoto `Tester` → `FireServer("Action", "BattlePass", { Op = "Premium" | "AddXp" | "SetLevel" | "NextDay" | "NextWeek" | "ResetClock" | "Reset", Value = n })`. `TesterService.state(player).BattlePass` trae el estado para el panel.

**Interfaz hecha (`UI/BattlePassUI`):** ventana compacta del estilo del HUD. Arriba «🏆 TEMPORADA 1 · LUCES DE VALMAR», los días que quedan, «NIVEL x / 50» con su barra de XP y tres secciones: **RECOMPENSAS** (la elegida en grande con vista previa 3D, rareza, tipo, nivel, pista, estado y RECLAMAR / EQUIPAR / PROBAR; carriles GRATIS y ⭐ PREMIUM; «RECLAMAR TODO»; la franja con la oferta sin presión o la siguiente recompensa; la fila 01…50 y, en el ordenador, la misión destacada), **MISIONES** (historia con su decisión, diarias con «CAMBIAR» si tienes la comodidad, evento, semanales y de temporada, con «📍 SEGUIR») y **FICHAS** (la tienda). Se entra por la fila «🏆 Pase de temporada» de COMANDOS (sale con la temporada en marcha o en el periodo para reclamar, con punto rojo si hay algo que reclamar; las «apps del teléfono» son esas filas, así que no hay otra ventana), con la tecla **N** en el ordenador (B es la piedra) y desde el panel de pruebas. En el móvil es una hoja de todo el alto, con botones y textos más grandes y sin la misión destacada. Solo se repinta al llegar un estado del servidor.

**UX (§23–29):** panel compacto (no a pantalla completa), con título, «TEMPORADA 01», barra de XP, «NIVEL x/50», pestañas GRATIS / PREMIUM, la recompensa actual con [RECLAMAR], una fila de niveles y una misión destacada. La compra se presenta sin presión: «PASE PREMIUM · Temporada 1 · 50 recompensas · [Vista previa] [Comprar]». Si `ComingSoon`, «Próximamente». En móvil, botones grandes y desplazamiento táctil; en PC, hover, tooltips y una tecla rápida.


## Conjuntos de ropa (los 30 de la hoja)

- Datos: `src/shared/Outfits.luau` (clave `O01`…`O30`, rareza de la hoja, prendas, zapatos, peinado y
  accesorios). En el pase: Id `S1_Oxx`; 24 sueltos en la pista premium, Neon dentro del conjunto del 20,
  Ángel dentro del legendario del 50 y 4 raros en la gratis (niveles 9, 22, 35 y 41).
- Vestir: `src/shared/OutfitBuilder.luau` (servidor y vista previa). Accesorios 3D con piezas soldadas
  (R15 y R6). Con plantillas subidas (`src/shared/OutfitIds.luau`) pone `Shirt`/`Pants`; si no, colores
  y piezas finas (nada se rompe).
- Plantillas: `python3 scripts/outfits/gen.py` → `assets/outfits/oNN_shirt.png` / `oNN_pants.png`
  (585×559). Subirlas: `bash scripts/upload-outfits.sh` (con `ROBLOX_API_KEY`; escribe `OutfitIds.luau`).
- Edades: bebé con pelele; niño en «talla de niño» (sin ombligo al aire, sin tacones ni rejilla).
- Oficios: «Estilo Bombero / Sanitaria / Policía» son solo ropa (sin rótulos oficiales, colores
  distintos del uniforme). No tocan `Job`. De servicio en un oficio con uniforme
  (`Outfits.SuspendJobs`) o en prisión, el conjunto se guarda y vuelve al acabar.
- Prueba: `lune run scripts/test-outfits.luau`.
