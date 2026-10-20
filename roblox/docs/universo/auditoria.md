# Auditoría del universo galáctico (entregables A–L)

> Hecha sobre la rama `claude/roblox-game-d98vy8` (commit de partida `9d2eae4`, v121). Encargo:
> [`encargo.md`](encargo.md). Diseño de lo nuevo: [`diseno-espacio.md`](diseno-espacio.md).
>
> **Cómo leer este documento.** Cada cosa lleva una etiqueta:
>
> - ✅ **Confirmado**: lo he visto en el código (con su `archivo:línea`) y/o lo comprueban las pruebas de
>   Lune que he pasado hoy.
> - 🔎 **Por investigar**: no lo puedo asegurar sin jugar en Roblox (Lune no dibuja, no tiene red ni
>   física de verdad) o lo está tocando ahora otro agente.
>
> Pruebas pasadas antes de tocar nada (todas en verde): `test-compile` (830 archivos), `test-clientboot`,
> `test-serverboot`, `test-hud`, `test-space`, `test-espacio-aaa`, `test-aircombat`, `test-planetas`.

---

## A · Diagnóstico (en pocas palabras)

El juego **ya tiene una base espacial seria**, mucho más de lo que parece desde fuera: un único sistema
estelar jugable (el **Sistema Valmar**, encima de la ciudad) con vuelo de nave, combate, minería con
asteroides que se rompen, dos estaciones con tienda/tablón/taller, eventos globales sincronizados por
la hora del servidor, salto cuántico, hipervelocidad, 7 planetas visibles y **un planeta al que se baja
volando sin pantalla de carga (Tefra)** con su ciudad (Bastión Ceniza). El guardado es sólido (bloqueo
de sesión, reintentos, comprobación de tamaño).

Lo que **falta** para el «universo» que pide el dueño:

1. **No hay modelo de datos de universo** (regiones → sistemas → cuerpos). Todo está cosido a mano
   alrededor de un solo sistema (`NavInfo.System = "Sistema Valmar"`, `src/shared/Cosmos/NavInfo.luau:23`).
2. **No hay trabajos espaciales**: solo 6 misiones fijas del tablón (`src/shared/Cosmos/Missions.luau:31-38`).
   No hay carrera, rangos, reputación ni contratos que cambien.
3. **No hay historia principal del espacio** ni villano (la Saga 2 v3 decía «sin villano común»; el dueño
   ahora pide uno: ver C-7).
4. **Enemigos de pocos tipos**: Dron, Caza y Torreta (`src/shared/AirCombat/EnemyAI.luau:29-32`). Sin
   pesados, apoyo, largo alcance ni jefes espaciales.
5. **Estaciones sin gente**: solo quioscos con avisos (`src/server/World/SpaceWorld.luau:235-248`).
6. **Un solo planeta con superficie** (`src/server/Services/PlanetService.luau:43`); los otros 6 son
   esferas que dicen «próximamente».

---

## B · Sistemas que ya existen y se REUTILIZAN (no se duplican)

| Tema | Qué hay | Dónde | Estado |
|---|---|---|---|
| Capas de altura del espacio | Aviones / transición / espacio, techo, suelo de naves | `src/shared/Cosmos/Layers.luau` | ✅ (test-space) |
| Vuelo de nave | Física arcade, modos Combate/Crucero/Exploración, impulso, freno, esquiva | `src/shared/AirCombat/ShipFlight.luau:66-106`, `Services/ShipSystems.luau` | ✅ (test-espacio-aaa) |
| Hipervelocidad y salto cuántico | Validación en servidor, carga, llegada segura, sin gasto si falla | `src/shared/AirCombat/Hyperspeed.luau`, `src/shared/Cosmos/QuantumJump.luau:22-60` | ✅ |
| Combate de nave | Láser, láser preciso, misiles, escudos con retardo, fijar blanco, bengalas | `src/shared/AirCombat/ShipWeapons.luau:12-60`, `Shields.luau:27-30`, `Lock.luau` | ✅ |
| IA enemiga | Dron (enjambre), Caza (duelo), Torreta (fija) | `src/shared/AirCombat/EnemyAI.luau:29-32` | ✅ |
| Sesión de nave en servidor | `enter/exit/relocate/spawnEnemy/enemyList/dropEnemy/status/onEvent` | `src/server/Services/AirCombatService.luau:1038-1377` | ✅ |
| Espacio de Valmar | Subir/bajar, estaciones, minar, patrullas, tienda, taller, tablón, planetas | `src/server/Services/SpaceService.luau` (1444 líneas) | ✅ |
| Estaciones | Alba y Cénit, zona segura 520, muelle, cascos sólidos | `src/shared/Cosmos/Stations.luau:23-25, 28-47, 101-125` | ✅ |
| Misiones del tablón | Kill / Mine / Deliver, máx. 2, tiempo mínimo de entrega, carga perdida al caer | `src/shared/Cosmos/Missions.luau:29-117` | ✅ |
| Minería y asteroides | Ritmo, bodega 40, alcance, rotura en trozos, mineral una vez por unidad | `src/shared/Cosmos/Mining.luau`, `Asteroids.luau` | ✅ |
| Eventos globales | Tormenta de asteroides / Incursión pirata, ciclo de 15 min por hora de servidor | `src/shared/Cosmos/SpaceEvents.luau:16-26` | ✅ |
| Navegación | Dónde estás, puntos de interés descubribles, objetivos de misión para el HUD | `src/shared/Cosmos/NavInfo.luau:23, 117-140` | ✅ |
| Mejoras de nave | Blindaje, Baterías, Bengalas y drones de apoyo con dinero + Chispas | `src/shared/AirCombat/ShipCombat.luau:211-252`, `SpaceService.luau:831-912` | ✅ |
| Planetas | 7 planetas (aspecto, estado, orden de la saga, registro de destinos) | `src/shared/Cosmos/Planets.luau:45-52, 125` | ✅ |
| Entrar/salir de planeta sin carga | Fases Space → Entry → Descending → superficie | `src/shared/Cosmos/PlanetEntry.luau`, `Services/PlanetService.luau` | ✅ (test-planetas) |
| Aterrizar/despegar | Flying → Landing → Landed → TakeOff, sin botón (móvil) | `src/shared/Cosmos/Landing.luau` | ✅ (lógica) · 🔎 (sensación) |
| Superficie de Tefra | Terreno por semilla (reproducible), POI, mineral a pie, ciudad Bastión Ceniza | `src/shared/Cosmos/Tefra.luau`, `TefraCity.luau`, `World/TefraCityBuilder.luau` | ✅ |
| Cielo/luz por zona | Un solo dueño del cielo (Valmar/Transición/Espacio/Entrada/Planeta) | `src/shared/Cosmos/EnvZones.luau`, `Controllers/EnvDirector.luau` | ✅ (otro agente lo está tocando) |
| Guardado | Bloqueo de sesión, reintentos, autoguardado, limpieza y tope de tamaño | `src/server/Services/DataService.luau:1-8, 298-332, 409-490` | ✅ |
| Volver a casa al desconectar | `AirArenaReturn` / `SpaceReturn` | `Services/PositionService.luau`, `SpaceService.luau:1318-1340` | ✅ |
| Menús de servidor con ficha | Menú con token (contra trampas) que pinta el cliente | `SpaceService.luau:752-764, 970-981`, `Controllers/SpaceClient.luau:605-613` | ✅ |
| Trabajos a pie (Valmar) | Recoger → entregar con proveedores; carreras con rangos | `Services/JobService.luau:1-60`, `CareerService.luau`, `shared/Institutions.luau` | ✅ (no sirven tal cual para la nave: usan piezas del suelo) |
| Invasión de la Grieta | 5 razas con su rey/dios, oleadas, jefe con puntos débiles | `docs/invasion.md`, `src/shared/Invasion/Races.luau:45-175`, `King.luau` | ✅ |
| Historia (motor LifeStory) | Pasos, guiones, cinemáticas | `src/server/Services/LifeStoryService.luau`, `src/shared/LifeStory/` | ✅ |

**Trabajo reciente que ya está (v121) y no se toca:** cielo negro de verdad, planetas a la vista,
marcadores, Valmar redonda desde el espacio (`ValmarGlobe`), asteroides de malla con destrucción,
ciudad de Tefra.

**En curso ahora mismo por otros agentes (🔎, no lo reviso para no pisarlo):** el **mapa galáctico**
(pantallas nuevas), el **aspecto del espacio y el HUD de vuelo** como la referencia (`ShipHudClient`,
`ShipHudLayout`, `SpaceMarkers`, `EnvDirector`, `DayLight`, `PlanetWorld`, `EspacioLook`, cielo y
planetas) y las **misiones y oficios de Tefra**.

---

## C · Errores y límites CONFIRMADOS

| # | Qué | Prueba | Gravedad |
|---|---|---|---|
| C-1 | El suceso «Kill» de la nave **no dice qué enemigo cayó**, solo su tipo: no se puede pagar una recompensa por un objetivo concreto. | `src/server/Services/AirCombatService.luau:403` (`emit(..., "Kill", { Kind, Score })`) | Bloquea cazarrecompensas → **arreglado en esta tanda** (se añade `Id`). |
| C-2 | El tablón tiene **6 misiones fijas**, siempre las mismas; no hay rotación, rango, reputación ni topes por hora. | `src/shared/Cosmos/Missions.luau:31-38` | Falta contenido (no es un fallo). |
| C-3 | `Missions.summary` escribe a mano «Alba»/«Cénit»: con una tercera estación saldría mal. | `src/shared/Cosmos/Missions.luau:126` | Leve. |
| C-4 | Desconectarse justo antes de ser derribado **salva la carga** de una entrega (no hay «Down» si sales). | `SpaceService.luau:1318-1340` (solo `Exit`), `Missions.luau:103` | Leve (abuso pequeño). Los contratos nuevos lo tienen en cuenta (ver diseño §1.6). |
| C-5 | Solo 3 tipos de enemigo en el espacio y ningún jefe espacial. | `src/shared/AirCombat/EnemyAI.luau:29-32`; sin `Boss`/`Jefe` en `shared/AirCombat` | Falta contenido. |
| C-6 | Un solo sistema estelar y nombre fijo. | `src/shared/Cosmos/NavInfo.luau:23` | Límite de arquitectura (ver E). |
| C-7 | **Choque de canon**: la Saga 2 v3 dice «planetas sin conexión, no hay villano de toda la saga» y el dueño ahora pide «salvar el universo de un malo maloso». | `docs/historia/saga-2-siete-planetas.md:13-36` (tabla de decisiones) | Necesita la decisión del dueño. La propuesta (diseño §2) lo hace compatible: cada episodio sigue siendo suelto y el villano vive **en el espacio**. |
| C-8 | Los títulos de los episodios en `saga-2-siete-planetas.md` usan los nombres viejos (LONTANA, OCREA, MARENA…) y el resto del proyecto los nuevos (Tefra, Siroco, Tálasa…). | `docs/historia/saga-2-siete-planetas.md:197, 282, 360…`; `src/shared/Cosmos/Planets.luau:46-52`; regla en `docs/planetas/diseno-mundos.md:56` | Solo documentación; el código migra los ids viejos (`Planets.migrate`). |
| C-9 | Las estaciones no tienen NPC: son quioscos con avisos. | `src/server/World/SpaceWorld.luau:235-248` | Falta contenido. |
| C-10 | Un piloto por sesión: las patrullas son de cada jugador; no hay cooperativo en el espacio. | `docs/espacio.md` («Límites conocidos») | Límite conocido. |
| C-11 | El juego publica **un solo place**: todos los planetas tienen que caber en el mismo mundo (zonas de terreno lejos de Valmar, como Tefra en X = −25 000). | `src/shared/Cosmos/Tefra.luau:6-9`, `docs/planetas.md:62-83` | Límite de diseño (ver H). |

---

## D · Por INVESTIGAR (no se puede asegurar sin jugar)

| # | Qué | Por qué no está claro | Cómo se comprueba |
|---|---|---|---|
| D-1 | Si el vuelo «se siente bien» en el móvil (palanca, sensibilidad, inercia). | Lune no tiene dedos ni pantalla. | Partida en un teléfono real (lista en `docs/espacio-aaa/diseno.md` §9). |
| D-2 | Rendimiento con 2 estaciones + 104 asteroides + patrullas en un móvil modesto. | No hay medidas en dispositivo. | Microprofiler / `UI/Perf.luau` en un móvil; topes de `FxBudget`. |
| D-3 | Si el salto cuántico deja la nave siempre fuera de objetos en un servidor con lag. | La comprobación es geométrica; falta probar con latencia. | Saltos repetidos con «Network → Incoming Replication Lag» en Studio. |
| D-4 | Cómo se verá el **mapa galáctico** nuevo y cómo encaja con `QuantumJump.list`. | Lo está haciendo otro agente. | Revisar su entrega antes de unirlo a los contratos. |
| D-5 | El aspecto final del HUD de vuelo (filas de misiones). | Lo está haciendo otro agente. | Ver que las filas de contratos (`infoFor().Missions`) salen bien. |
| D-6 | Cuántas piezas aguanta añadir NPC a las estaciones con `StreamingTargetRadius = 768`. | Sin medir. | Medir piezas por estación (meta: < 1500). |
| D-7 | Si la entrada a Tefra se ve bien con todas las texturas (dependen de subir imágenes). | `docs/planetas.md:84-128`. | Partida tras la próxima publicación. |
| D-8 | Encaje con las misiones y oficios de Tefra que se están haciendo ahora. | Otro agente. | Revisar su registro de oficios antes de unir la carrera de la galaxia. |

---

## E · Arquitectura propuesta del universo

**Regla:** se **amplía** lo que hay. Nada de servicios nuevos con el mismo trabajo que uno viejo.

```
UNIVERSO (datos puros, shared/Cosmos/Universe.luau · propuesta)
 └─ REGIÓN «Brazo de Valmar» (y más adelante: «Cinturón Ragnarock», «Lindes»)
     └─ SISTEMA ESTELAR (id, nombre, estrella, coordenadas del mapa, peligro, bandos, recursos,
        acceso, descubrimiento, requisitos de viaje)
         ├─ Sistema Valmar  → hoy: Stations, Zone (campos y sectores), PlanetBodies
         └─ (futuro) cada planeta de la Saga 2 como su propio sistema con su órbita (diseno-mundos §2.6)
```

| Nombre del encargo | Lo que ya hace ese papel (se reutiliza) | Qué falta |
|---|---|---|
| UniverseService / StarSystemService | `shared/Cosmos/NavInfo` + `Stations` + `Zone` + `PlanetBodies` | Una tabla de datos `Universe` que los agrupe por sistema (sin mover nada). |
| GalaxyMapService | (otro agente, en curso) + `QuantumJump.list` | Leer los datos de `Universe`. |
| PlanetService / PlanetEnvironmentService / PlanetGenerationService | `Services/PlanetService`, `shared/Cosmos/Tefra` (semilla), `EnvZones` | Plantilla de planeta por tipo (diseño de `diseno-mundos.md` §2.7 «Entorno»). |
| SpaceFlightService | `shared/AirCombat/ShipFlight` + `Services/ShipSystems` | — |
| SpaceCombatService | `Services/AirCombatService` + `EnemyAI` + `Waves` | Arquetipos nuevos y jefes. |
| ShipCustomizationService | `ShipCombat.Upgrades` + taller de `SpaceService` | Astillero por ranuras (`diseno-mundos.md` §2.3). |
| LandingService | `shared/Cosmos/Landing` + `PlanetService` | — |
| MissionService | `shared/Cosmos/Missions` (tablón) + `LifeStoryService` (historia) | Contratos: **`shared/Cosmos/SpaceJobs` + `Services/SpaceJobService` (hecho en esta tanda)**. |
| EventService | `shared/Cosmos/SpaceEvents` (hora del servidor) | Más tipos de evento y consecuencias. |
| FactionService | — | Reputación por bando: **empezada en `SpaceJobs` (hecho en esta tanda)**. |
| InventoryService | `Services/InventoryService` + bodega `data.Space.Ore` | Mochila de materiales (`diseno-mundos.md` §2.2). |
| SaveService | `Services/DataService` (bloqueo de sesión, reintentos) | Nada: todo lo nuevo vive en `data.Space`. |
| UniverseUIController | `Controllers/SpaceClient` (menús) + HUD de la nave | — |

---

## F · Plan por fases (el del encargo, con lo que ya hay)

| Fase | Contenido | Estado |
|---|---|---|
| 1 Auditoría | Este documento | ✅ hecho |
| 2 Arquitectura | Apartado E | ✅ propuesta |
| 3 Modelo de datos | `Universe.luau` con el Sistema Valmar como primer sistema (agrupa lo que existe) | Pendiente |
| 4 Mapa | Otro agente | 🔎 en curso |
| 5 Viaje | `QuantumJump` ya valida y vuelve atrás; falta viajar **entre sistemas** | Parcial |
| 6 Vuelo | Hecho en Espacio AAA | ✅ |
| 7 Primer sistema | Sistema Valmar (ver I) + **trabajos espaciales** | **En marcha (esta tanda: repartidor y cazarrecompensas)** |
| 8 Planeta de referencia | Tefra (ver J) | Parcial (ciudad hecha; misiones en curso por otro agente) |
| 9 Aterrizaje | `Landing` | ✅ lógica · 🔎 sensación |
| 10 Misiones en el planeta | Otro agente (Tefra) | 🔎 en curso |
| 11 Combate | Arquetipos nuevos (pesado, apoyo, largo alcance) y primer jefe espacial | Pendiente |
| 12 Estaciones/NPC/bandos | NPC en Alba y Cénit, reputación visible, zonas restringidas | Pendiente (reputación empezada) |
| 13 Planetas nuevos | Siguiente: Miasma (orden de producción de `diseno-mundos.md`) | Pendiente |
| 14 Eventos | Señales de socorro, convoyes, anomalías (diseño §4) | Pendiente |
| 15 Progresión/guardado | Rangos de la galaxia (hecho para 2 trabajos), astillero | Parcial |
| 16 Optimización | Medir en móvil (D-2) | Pendiente |

---

## G · Dependencias

- **Trabajos espaciales** dependen de: `SpaceService` (estaciones, atraque, menús, recompensa, tope de
  Chispas), `AirCombatService` (sucesos `Kill`/`Down`/`Exit`, `spawnEnemy`, `enemyList`), `DataService`
  (`data.Space`). No dependen del mapa ni del HUD nuevo (el HUD solo lee la lista `Missions` de `infoFor`).
- **Historia del villano** depende de: LifeStory (pasos `Fly`, `Dogfight`, `Board`, `Defend` propuestos en
  `docs/historia/cosme-otro-universo-y-saga-2.md` §4), jefes espaciales (fase 11) y episodios de planeta.
- **Mapa galáctico** depende de: el modelo `Universe` (fase 3) y `QuantumJump.list`.
- **Planetas nuevos** dependen de: plantilla de superficie como `Tefra.luau` y la zona libre en el place.
- **Nada** depende de pagos, de paquetes de pago ni de subir assets nuevos.

---

## H · Estrategia de optimización

1. **Un solo place, zonas lejanas** (como Tefra): `StreamingEnabled` con radio 768
   (`default.project.json:297-298`). Los planetas nuevos van a más de 20 000 studs de todo.
2. **Construir cuando alguien se acerca** (ya lo hace el espacio: estaciones y asteroides se hacen la
   primera vez que alguien sube; PlanetService con «Near»).
3. **Bucles que se apagan solos** (el de patrullas se desconecta si nadie vuela: `SpaceService.luau:1140-1170`).
   Los contratos usan **ese mismo bucle**, no uno nuevo.
4. **Topes**: enemigos por sector (`Zone.Sectors[*].Max`), trozos de asteroide (60), efectos
   (`AirCombat/FxBudget`). Los objetivos de recompensa cuentan dentro del tope del sector.
5. **IA por distancia**: los enemigos lejanos se quitan (`SpaceService.DespawnDistance = 2600`).
6. **Medir antes de añadir** NPC a estaciones (D-6).

---

## I · Primer sistema estelar jugable: el **Sistema Valmar**

Ya existe y es el sitio correcto para empezar (no hay que inventar otro):

| Sitio | Razón de existir | Qué se hace allí (con esta tanda) |
|---|---|---|
| Estación Alba (4300) | Puerto civil, junto al Cinturón de Hierro (tranquilo) | Tienda, taller, tablón, **Oficina de Fletes** (repartidor) |
| Estación Cénit (5600) | Puesto de vigilancia, cerca de las rutas peligrosas | Tienda, taller, tablón, **Oficina de Recompensas** (cazarrecompensas) |
| Cinturón de Hierro | Minería tranquila | Minero |
| Campo Brasa / Sector Brasa | Minería con drones | Minero, mercenario (futuro) |
| Ruta de los Saqueadores | Piratas | **Recompensas nivel 2**, cargas peligrosas |
| Nube Escarcha / Sector Escarcha | Lo más difícil | **Recompensas nivel 3** |
| Baliza de Valmar | Volver a casa | — |
| 7 órbitas | Puertas a los episodios | Tefra: bajar; resto «próximamente» |

## J · Primer planeta de referencia: **Tefra**

Es el que ya tiene superficie, ciudad (8 barrios), minería a pie, POI y aterrizaje. Cumple «pequeño,
detallado y lleno de posibilidades» (3 × 3 km). Propuesta: **no** hacer otro planeta hasta que Tefra
tenga sus misiones y oficios (otro agente, en curso) y **un contrato de reparto Alba → Tefra** (fase
siguiente de los trabajos: entregar en el Muelle Bastión).

## K · Pruebas por cada cosa

| Cosa | Prueba técnica (Lune) | Prueba visual (Roblox, a mano) |
|---|---|---|
| Contratos (aceptar, topes, rango) | `scripts/test-spacejobs.luau` | Tablón de Alba/Cénit en el móvil |
| Entrega validada por el servidor | `test-spacejobs` (antes de tiempo, otra estación, carga frágil, caer) | Volar Alba → Cénit |
| Recompensa: aparece, se derriba, paga una sola vez | `test-spacejobs` | Ir al sector y derribarlo |
| Salir a mitad | `test-spacejobs` (el objetivo se quita, el contrato sigue o caduca) | Salir del juego con un contrato |
| Lo que ya había | `test-space`, `test-aircombat`, `test-espacio-aaa`, `test-planetas`, `test-hud`, `test-compile`, `test-clientboot`, `test-serverboot` | — |

## L · Archivos que se tocan en esta tanda

| Archivo | Cambio |
|---|---|
| `roblox/docs/universo/encargo.md` | Nuevo (resumen del encargo) |
| `roblox/docs/universo/auditoria.md` | Nuevo (este documento) |
| `roblox/docs/universo/diseno-espacio.md` | Nuevo (trabajos, villano, misiones, eventos, bandos, estaciones) |
| `roblox/src/shared/Cosmos/SpaceJobs.luau` | Nuevo: cuentas puras de los trabajos espaciales |
| `roblox/src/server/Services/SpaceJobService.luau` | Nuevo: el servidor de los trabajos |
| `roblox/src/server/Services/SpaceService.luau` | Mínimo: avisar de los sucesos, botón del tablón, filas del HUD, tope de Chispas compartido |
| `roblox/src/server/Services/AirCombatService.luau` | Una línea: `Id` en el suceso `Kill` |
| `roblox/src/server/Main.server.luau` | Arrancar `SpaceJobService` |
| `roblox/scripts/test-spacejobs.luau` | Nueva prueba |
| `roblox/docs/espacio.md` | Una sección corta que apunta a los trabajos |

**No se tocan** (otros agentes): `ShipHudClient`, `ShipHudLayout`, `SpaceMarkers`, `EnvDirector`,
`DayLight`, `PlanetWorld`, `EspacioLook`, cielo y planetas, pantallas del mapa galáctico, historia y
oficios de Tefra.
