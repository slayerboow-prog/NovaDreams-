# Escenarios pendientes · 5. Diseño de implementación y plan por fases

> Parte del análisis [`escenarios-pendientes.md`](escenarios-pendientes.md). Es la propuesta técnica para que **todo lo
> que pasa en la historia se vea, se oiga y se viva**, reutilizando lo que ya hay. No cambia código: es el plano.

Índice: [1. Qué hay ya y sirve](#1-qué-hay-ya-y-sirve) · [2. Qué falta (sistemas)](#2-qué-falta-sistemas-nuevos) ·
[3. Arquitectura](#3-arquitectura-propuesta) · [4. Formato de datos](#4-formato-de-datos) ·
[5. Cómo se conectan las misiones](#5-cómo-se-conectan-las-misiones-existentes) · [6. Rendimiento y pruebas](#6-rendimiento-móvil-y-pruebas) ·
[7. Plan por fases](#7-plan-por-fases-paquetes) · [8. Inventario de piezas](#8-inventario-de-piezas-a-construir)

---

## 1. Qué hay ya y sirve

| Sistema | Dónde | Qué aporta | Límite actual |
|---|---|---|---|
| Motor de misiones por datos | `server/Services/LifeStoryService.luau`, `shared/LifeStory/Misiones/*` | Pasos (`Scene`, `Talk`, `Use`, `Reach`, `Escape`, `Chase`, `Fight`, `Cinematic`, `Transition`…), efectos, consecuencias diferidas (`Story.Later`) | No tiene un paso «pasa algo en el mundo» con tiempos |
| Escenas por jugador | `server/Services/SceneService.luau` + `client/Controllers/SceneClient.luau` | Actores (andar, seguir, huir, cazar, sentarse, gestos), objetos con botón, peleas con haz de color, persecuciones; cada jugador ve solo su historia (`workspace.StoryScenes.Scene_<id>`) | Objetos = 30 primitivas de 1–3 studs (`BUILDERS`, l. 749–990); criaturas = personas R15 pintadas (`buildModel`, l. 297); al vencer, siempre «sube y desaparece entre chispas verdes» (`defeat`, l. 1574) |
| Cinemáticas | `shared/LifeStory/Cinematics.luau`, `server/Services/CinematicService.luau`, `client/Controllers/Cinematics.luau`, `CineCamera` | Planos (viaje, órbita), temblor, zoom, *roll*, fundidos, subtítulos con voz, rótulos, música, gestos, «Saltar» | Solo cámara: no puede **disparar** efectos, mover objetos ni cambiar el entorno a mitad de plano |
| Diálogos y voces | `DialogueService` + `DialogueUI`, `Config.Audio.Voices` (TTS) | Conversaciones con cámara al que habla, respuestas, voz sintetizada por perfil | — |
| Cuerpo vivo de los actores | `client/Controllers/ActorLife.luau`, `shared/LifeStory/Emotion.luau` | Respiración, miradas, gestos por emoción (sorpresa, enfado, tristeza, asentir…) | Solo para cuerpos humanos |
| La Grieta del cielo | `shared/SkyRift.luau` + `client/Controllers/SkyRift.luau` | Grieta con capas, ramas, chispas; fases por jugador (`phaseFor`) según la saga; nivel gráfico | Cambia de fase **al completar** la misión, de golpe; no hay animaciones (coser, cremallera, abrirse) |
| Isla del sueño | `server/World/Kit/DreamIsland.luau` | Ejemplo de **set aparte** construido lejos de la ciudad con sus propias marcas | — (es el patrón para las dimensiones) |
| Marcas del mapa | `World/Kit/StoryMarks.luau` (`StoryProp`/`StoryArea`/`StorySpot`) + `Locations.luau` | Lugares de la historia sin tocar el código de la misión; `Fallback` | Faltan marcas: habitación/cocina de la residencia, granero por dentro, laboratorios… |
| Animales | `client/Controllers/Wildlife.luau` + `AnimalPose.luau` | Gallinas, vacas, ovejas, perros, gatos, palomas, patos con poses y sustos | Solo en el cliente, decorativos (no actores de la historia) |
| Clima y luz | `WeatherService` + `client/Controllers/Weather.luau`, `DayLight.luau`, `Graphics.luau` | Lluvia, tormenta, niebla, estaciones, presupuestos por nivel gráfico | Es global (igual para todos); no hay clima/luz **por jugador** |
| Catástrofes marinas | `SeaEventService` + `client/Controllers/SeaEventsUI.luau`, `SeaFx` | Ejemplo hecho de efectos grandes en el cliente (ola, rayos, remolino) | — (es el patrón para los VFX) |
| Temblor y golpes | `client/Controllers/CameraShake.luau`, `KnockService`/`Knock.luau`, `BreakService`/`Breakables.luau` | Temblor de cámara, objetos que salen despedidos y vuelven, cristales que se rompen y se arreglan | — |
| Interiores | `InteriorService` + `World/Interiors.luau`, `World/Tower.luau`, `Furniture.luau` | Todos los edificios se visitan por dentro; plantas y ascensor; residencias | Los interiores son genéricos; la historia no puede pedir «la sala X de la historia» |
| Vecinos | `shared/Residents.luau` | Vecinos con nombre y rutina | Útiles como público (concierto, cola del cajero) |
| Marcas canónicas | `client/Controllers/CanonMarkers.luau` | Pilar dorado y marca en el mapa de las misiones de la saga | — |
| Memoria de la historia | `DataService` → `data.Story` (`DataService.luau:87-107`): `Completed`, `Flags`, `Choices`, `Memories`, `Later`… | Persistencia por jugador | No hay **estado del mundo** («Petra vive en el gallinero», «el garaje está cerrado») |

---

## 2. Qué falta (sistemas nuevos)

1. **Secuenciador de acontecimientos** (cámara + efectos + actores + sonido sincronizados en una línea de tiempo).
2. **Catálogo de VFX de la historia** (explosión, impacto/cráter, portal, grieta en el suelo, luz misteriosa, energía,
   tormenta local, encoger/agrandar, «pop», cremallera del cielo, hilos de luz, apagón, filtros de color…).
3. **Rigs de criaturas** (no humanoides) con el mismo motor de movimiento que los actores.
4. **Copias del avatar del jugador** (clones, tu yo del futuro, tu yo malvado, tu sombra, tu reflejo, Candelas de papel).
5. **Decorados de la historia** («sets»): construcciones grandes por código o con modelos de la Tienda, con fases.
6. **Memoria del mundo por jugador** (persistente) y su réplica al cliente.
7. **Dimensiones de bolsillo** (copias reskineadas de trozos de Valmar + luz/cielo por jugador).
8. **Animaciones de la Grieta** en `SkyRift` (abrirse, coserse, cremallera, hilos que caen, apagón).

---

## 3. Arquitectura propuesta

```
 Misiones/*.luau (datos)                    shared/LifeStory/Happenings/*.luau  shared/LifeStory/Sets.luau  shared/LifeStory/Creatures.luau
        │  paso { Type = "Happening", Id }          (líneas de tiempo)               (decorados + fases)        (rigs por personaje)
        ▼                                                │                               │                          │
 LifeStoryService ──► HappeningService (servidor) ◄──────┘                               │                          │
        │                 │  resuelve anclas, crea sets/actores, programa pistas          │                          │
        │                 ├──► SetService ◄──────────────────────────────────────────────┘                          │
        │                 ├──► SceneService (actores; buildModel elige rig) ◄────────────────────────────────────────┘
        │                 ├──► WorldMemoryService (data.Story.World) ──► atributo "WorldState" (JSON) del jugador
        │                 └──► Remote "Happening" ──► client/Controllers/HappeningClient
        │                                                   ├──► Cinematics (planos de cámara, ya existe)
        │                                                   ├──► StoryFx (catálogo de VFX: shared/StoryFxCatalog.luau)
        │                                                   ├──► SkyRift (animaciones de la Grieta)
        │                                                   ├──► LocalLighting (luz/cielo/filtros por jugador)
        │                                                   └──► SoundFx / StoryAudio (sonidos y música)
        ▼
 Conditions.check (fases: Completed / Active / Flags / Stage / Hours / World)
```

### 3.1 Módulos nuevos

| Módulo | Lado | Responsabilidad | API principal |
|---|---|---|---|
| `shared/LifeStory/Happenings/<Grupo>.luau` + índice `HappeningIndex.luau` | compartido | **Datos** de los acontecimientos (líneas de tiempo con pistas) | tabla `{ [id]: Happening }` |
| `server/Services/HappeningService.luau` | servidor | Lanzar un acontecimiento a un jugador: resolver anclas (`CinematicService.resolveAnchors` ya lo hace), pre-cargar zonas (streaming), crear sets y actores de las pistas, programar efectos de servidor (actores, sets, memoria), enviar el resto al cliente, esperar el final (o «Saltar») y devolver el control | `play(player, id, ctx?) -> number` (duración) · `waitFor(player, id, onDone)` · `skip(player)` |
| `client/Controllers/HappeningClient.luau` | cliente | Reproducir las pistas de cliente sincronizadas con el reloj del servidor (`workspace:GetServerTimeNow()`): cámara (delegando en `Cinematics`), VFX, luz, sonido, UI | `play(payload)` · `stop()` |
| `shared/StoryFxCatalog.luau` | compartido | **Recetas** de VFX como datos (colores, tamaños, duraciones, partículas, presupuesto por nivel gráfico); puras y testeables | `StoryFxCatalog.get(name) -> Recipe` |
| `client/Controllers/StoryFx.luau` | cliente | Ejecutar una receta en una posición (crea partes/`ParticleEmitter`/`Beam`/luces locales, las limpia) | `StoryFx.play(name, cframe, params) -> handle` · `handle:stop()` |
| `client/Controllers/LocalLighting.luau` | cliente | Luz y cielo **por jugador** con pila de capas (prioridad): `ColorCorrection`, `Atmosphere`, `Sky`, hora forzada, estrellas, apagón; se mezcla con `DayLight`/`Weather` y se restaura al quitar la capa | `push(layerId, spec, fade)` · `pop(layerId, fade)` |
| `shared/LifeStory/Sets.luau` | compartido | **Catálogo de decorados**: qué es, dónde va (lugar de `Locations` + offset o marca propia), quién lo ve (todos / por jugador), en qué fases aparece y en qué **estado** | tabla `{ [id]: SetDef }` |
| `server/Services/SetService.luau` + `server/World/StorySets/<Set>.luau` | servidor | Construir los sets (por código, con `Builder`/`Building`, o cargando modelos de la Tienda con `AssetLoader`); los globales al arrancar, los de jugador bajo su `StoryScenes`; cambiar de estado | `ensure(player, setId)` · `setState(player, setId, state)` · `remove(player, setId)` |
| `shared/LifeStory/Creatures.luau` | compartido | Qué rig usa cada personaje de `Cast` y con qué parámetros (escala, colores, accesorios, sonidos, forma de andar) | `Creatures.rigFor(npcId) -> RigSpec?` |
| `server/World/CreatureRigs/<Rig>.luau` | servidor | Construir la «piel» de cada rig (piezas soldadas) y sus *Motor6D*; un humanoide **invisible** dentro hace de esqueleto de movimiento para reutilizar `Hunt`/`Flee`/`Follow`/caminos | `build(spec) -> Model` |
| `client/Controllers/CreaturePose.luau` | cliente | Animación procedural de los rigs (como `AnimalPose`): andar, picotear, aletear, cola, antenas, encoger | se engancha por etiqueta `StoryCreature` |
| `server/Services/WorldMemoryService.luau` | servidor | Estado del mundo por jugador (`data.Story.World`), réplica al cliente, consultas para condiciones | `get(player, key)` · `set(player, key, value)` · `snapshot(player)` |
| `shared/LifeStory/Dimensions.luau` + `server/World/Kit/PocketDimensions.luau` | ambos | Dimensiones de bolsillo: qué trozo de Valmar copian, qué reskin aplican, qué luz/cielo, dónde se construyen (lejos, como `DreamIsland`) | `Dimensions.get(id)`; servidor `PocketDimensions.build()` al arrancar |
| `client/Controllers/AvatarCopy.luau` + servidor `AvatarCopyService` | ambos | Copias del avatar del jugador con variaciones (`Older`, `Evil`, `Shadow`, `Paper`, `Clone`, `Mirror`) | `AvatarCopyService.make(player, variant) -> Model` |

### 3.2 Reglas de visibilidad

- **De todos (globales)**: lo que es parte normal de la ciudad aunque no hagas la misión: granero grande, gallinero,
  cuadra, tractor, Pabellón 0 por fuera, oficina de MegaVerso por fuera (cartel apagado), residencia por dentro,
  escenario del patio del instituto (plegado)… Se construyen al arrancar el servidor (como `DreamIsland`).
- **De tu historia (por jugador)**: lo que solo existe en tu vida: Petra gigante, el huevo, las plumas, la nave de las
  cucarachas, las dimensiones abiertas, las pantallas con Cósimo, el anclaje que clavaste… Se crean bajo
  `workspace.StoryScenes.Scene_<userId>` y `SceneClient` ya los oculta a los demás.
- **Persistente por jugador**: lo que queda después (Petra en el gallinero, el anclaje, el grafiti, Rex en tu casa, el
  garaje cerrado). Lo decide `WorldMemoryService`; lo dibuja `SetService` según el estado al entrar y al cambiar.
- **Global, pero con estado por jugador**: si un set global tiene estado que depende de tu historia (el garaje de Cosme
  abierto o cerrado; el cartel de MegaVerso encendido o caído), el servidor construye el set una vez con todas sus
  variantes en carpetas, y el cliente **muestra solo la variante** de tu `WorldState` (mismo truco que `SceneClient`:
  `LocalTransparencyModifier` + `CanCollide` local). Así no hay un garaje por jugador.

### 3.3 Rigs de criaturas: «mismo motor, otra piel»

`SceneService.buildModel` (l. 297) crea un R15 con los colores de `Cast`. Propuesta: si `Creatures.rigFor(npc)` devuelve
un rig, se sigue creando el humanoide (para caminos, `Hunt`, `Flee`, `Follow`, `Sit`, botones) pero **transparente y sin
colisión**, y se suelda encima la piel del rig. Ventajas: no se toca la lógica de escenas, persecuciones ni peleas.

- Altura y escala: la piel se construye a la escala pedida (`Scale` del actor o del rig): Petra 21 studs, Don Pinzas
  10×4×7, Ratón Pérez 1,2 studs. El humanoide escondido se escala para que la velocidad y el radio de captura cuadren
  (`Catch`).
- Animación: `CreaturePose` (cliente) anima la piel con *Motor6D* según la velocidad del humanoide (andar/correr/quieto)
  y según atributos que pone el servidor: `CreatureAction = "Peck" | "Flap" | "Cluck" | "Shrink"…`.
- Emociones: `Emotion.luau` traduce las emociones de cada línea a gestos de rig (gallina: «Surprised» = cuello estirado
  y plumas erizadas; gato: «Angry» = lomo arqueado; robot: pantalla de ojos con la cara).
- Golpes y derrota: `SceneService.hit/defeat` llaman a `Creatures.onHit/onDefeat` del rig (por defecto lo de ahora). Para
  Petra: `onHit` = encoger un escalón; `onDefeat` = «poof» de plumas y sustituir por la gallina normal que corre al
  gallinero (en vez de desaparecer).
- Rigs base reutilizables: `Bird` (gallina, paloma, paloma robot), `Quadruped` (gato, perro, ratón, rata, Rex a cuatro
  patas), `Biped` (gato policía, Rex de pie, cucaracha, lápiz, gnomo, electrodoméstico con patas), `Crab`, `Fish`,
  `Floater` (drones, Evaluador, nube, hilacha), `Robot` (Pip, robot de seguridad).

### 3.4 Dimensiones de bolsillo

Hoy las visitas a otras dimensiones son un `Transition` (pantalla negra con texto) que te devuelve al mismo sitio.
Propuesta (patrón `DreamIsland`):

- Al arrancar, `PocketDimensions.build()` construye **lejos de la ciudad** (p. ej. a 20 000 studs) unas pocas
  «maquetas» reutilizables: **Plaza** (Plaza del Centro + 2 calles), **Parque** (parque + estanque), **Patio** (patio y
  pista del instituto), **Biblioteca** (una planta), **Playa** (un tramo). Son copias simplificadas (geometría propia
  con `Builder`, no clonado del mapa entero).
- Cada dimensión (`Dimensions.luau`) = maqueta + **reskin** (materiales/colores/Decals: papel cuadriculado, todo gris,
  todo morado…) + **pobladores** (actores/rigs: gatos de tamaño persona, señores con perilla) + **capa de luz** de
  `LocalLighting` (cielo morado, sepia, blanco libreta, desaturado) + música.
- Como las maquetas son de todos, cada jugador ve **su** reskin: el servidor pone los pobladores en su escena y el
  cliente aplica el reskin a las piezas de la maqueta con `MaterialVariant`/colores **locales** (el cliente puede
  cambiar el color de una pieza solo para sí). Si dos jugadores están en dimensiones distintas a la vez, cada uno ve la
  suya.
- Entrada/salida: el `Transition` actual sigue sirviendo, pero el `Teleport` apunta a la marca de la maqueta y se añade
  la animación del portal (remolino que te absorbe) antes del negro.
- Dimensiones previstas: `G4_Gatos` (Parque+Plaza), `B66_Malvada` (Plaza+camino a la universidad), `Examen_Papel`
  (Patio), `A0_Gris` (Playa), `V9_Alcaldia` (Plaza), `Pasado_Sepia` (Parque), `Piso13` (Biblioteca),
  `Invertida` (solo cielo, para la Fusión).

### 3.5 Memoria del mundo

- Datos: `data.Story.World = { [clave] = valor }` (añadir a `DataService` con `Version` y migración: tabla vacía).
  Claves con prefijo del set: `Granja.Petra = "Normal"`, `Garaje.Estado = "Cerrado"`, `Garaje.Hollin = true`,
  `Anclajes = { Parque = true, Patio = true, Plaza = true }`, `Muro.Firma = true`, `Rex.Vive = true`…
- Escritura: nuevo efecto de misión `World = { ["Granja.Petra"] = "Normal" }` (en `Effects`, igual que `Flags`), y pistas
  `World` dentro de un acontecimiento.
- Lectura: nueva condición `World = { ["Garaje.Estado"] = "Cerrado" }` en `Conditions.check` (sirve para `If` de líneas,
  pasos, requisitos y fases de sets).
- Réplica: atributo `WorldState` (JSON, como `CanonMarks`) en el jugador; el cliente lo lee para elegir variantes.
- Valores por defecto deducibles: muchas cosas se derivan de `Completed`/`Flags` (como hace `SkyRift.phaseFor`), así que
  las misiones ya hechas por jugadores veteranos **no necesitan migración**: `Sets.luau` puede declarar
  `ShowIf = { Completed = { "Loco_N3_Pollo" } }` además de claves `World`.

### 3.6 Animaciones de la Grieta

Ampliar `SkyRift` (sin romper `phaseFor`): además de la fase, un **evento** puntual que el cliente reproduce y que acaba
en la fase nueva: `Open(from, to, seconds)`, `Stitch(seconds, fromEnd?)` (aguja recorriendo la raja con puntadas),
`Zip(open|close, seconds)` (cremallera), `Threads(count, area)` (hilos que caen), `Pulse(intensity)` (sincronizado con
una voz), `Invert(on)` (la Valmar invertida a través). Lo dispara una pista `Sky` del acontecimiento.

---

## 4. Formato de datos

### 4.1 Un acontecimiento (`Happening`)

```lua
-- shared/LifeStory/Happenings/Granja.luau
return {
	Petra_Aparece = {
		Duration = 10,
		Skippable = true,
		Anchors = { Huevo = "Set:GraneroPetra.Nido", Puerta = "Set:GraneroPetra.Porton", Silo = "Place:GranjaSilo", Yo = "Player" },
		Tracks = {
			-- cámara (se delega en Cinematics: mismo formato de planos)
			Camera = {
				{ At = 0, From = { "Huevo", V(3, 2, 4) }, To = { "Huevo", V(2, 1.5, 3) }, Look = { "Huevo", V(0, 2, 0) }, Duration = 2 },
				{ At = 2, Shake = 0.6, Duration = 2 },
				{ At = 4, From = { "Puerta", V(0, 1, 6) }, To = { "Puerta", V(0, 3, 4) }, Look = { "Puerta", V(0, 0, 0) }, LookTo = { "Puerta", V(0, 20, 0) }, Fov = { 70, 50 }, Duration = 3 },
				{ At = 7, Shake = 1.0, Duration = 2 },
				{ At = 9, From = { "Silo", V(-6, 4, 6) }, Look = { "Puerta", V(0, 8, 0) }, Duration = 1, Dip = true },
			},
			-- actores (servidor: SceneService)
			Actors = {
				{ At = 3.5, Spawn = { Npc = "PolloGigante", Anchor = "Puerta", Offset = V(0, 0, -4), Scale = 1 } },
				{ At = 7, Do = { Npc = "PolloGigante", Action = "Cluck" } },
			},
			-- efectos (cliente: StoryFx)
			Fx = {
				{ At = 2, Play = "DustFall", Anchor = "Huevo", Offset = V(0, 18, 0), Seconds = 3 },
				{ At = 4, Play = "BigShadow", Anchor = "Yo", Seconds = 3 },
				{ At = 7, Play = "FeatherBurst", Anchor = "Puerta", Offset = V(0, 16, 0) },
			},
			Sound = {
				{ At = 2, Play = "PisadaGigante" }, { At = 3, Play = "PisadaGigante" },
				{ At = 7, Play = "ClocGrave", Volume = 1 },
			},
			Titles = { { At = 9, TextKey = "¡CORRE HACIA EL SILO!", Duration = 1.5 } },
			-- cambios del mundo (servidor: WorldMemory / SetService)
			World = { { At = 0, Set = "GraneroPetra", State = "Desastre" } },
		},
	},
}
```

Pistas posibles: `Camera` (planos de `Cinematics`), `Actors` (`Spawn`, `Move`, `Do` = gesto/acción de rig, `Despawn`),
`Fx` (receta de `StoryFxCatalog`), `Sky` (evento de `SkyRift`), `Light` (`push`/`pop` de `LocalLighting`), `Sound`,
`Music`, `Lines` (subtítulos con voz, como en `Cinematics`), `Titles`, `World` (estado de sets y memoria), `Input`
(QTE corto: «¡Agárrale la mano!», con resultado como efecto), `Physics` (fuerza sobre el jugador, objetos que caen).

### 4.2 Un decorado (`Sets.luau`)

```lua
GraneroPetra = {
	Scope = "Global",                       -- "Global" (todos) | "Player" (solo su historia)
	Place = "GranjaGranero",                -- lugar de Locations (o Mark = "StoryArea GranjaJulian")
	Builder = "StorySets/Granero",          -- módulo de server/World/StorySets
	States = {                              -- variantes; el cliente enseña la de tu WorldState
		Normal = {},
		Desastre = { Player = true },       -- plumas, huellas, puertas abombadas: solo para ese jugador
	},
	StateFor = {                            -- qué estado toca según la historia (primera que se cumple)
		{ If = { Active = { "Loco_N3_Pollo" } }, State = "Desastre" },
		{ State = "Normal" },
	},
	Marks = { "Nido", "Porton", "Pajar", "Comedero" }, -- StorySpots que deja dentro
},
```

### 4.3 Un rig (`Creatures.luau`)

```lua
PolloGigante = { Rig = "Bird", Species = "Gallina", Scale = 16, Colors = { Body = rgb(250,250,245), Comb = rgb(220,40,40), Legs = rgb(245,190,50) },
	Sounds = { Idle = "ClocGrave", Hurt = "ClocAgudo" },
	OnHit = { Shrink = { 16, 12, 8, 5, 3 } }, OnDefeat = { Replace = "PetraNormal", RunTo = "Set:Gallinero.Nido" } },
PetraNormal = { Rig = "Bird", Species = "Gallina", Scale = 1, Accessories = { "LazoRojo" } },
Bigotes = { Rig = "Quadruped", Species = "Gato", Scale = 1, Colors = { Body = rgb(236,142,52) }, Accessories = { "Corona", If = { Completed = { "Loco_N2_Bigotes" } } } },
```

### 4.4 Una dimensión (`Dimensions.luau`)

```lua
B66_Malvada = { Base = "Plaza", Reskin = "Malvada", Light = { Sky = "Morado", Tint = rgb(170,120,200), Fog = rgb(90,40,110) },
	Populate = { { Npc = "Perilla", Count = 8, Mode = "Wander" }, { Rig = "PalomaAntifaz", Count = 6 } },
	Props = { "CartelCosimoAlcalde", "FarolaBurlona", "PlantaCarnivora" }, Music = "Malvada" },
```

---

## 5. Cómo se conectan las misiones existentes

Sin reescribir las misiones: se añaden campos opcionales y un tipo de paso.

| Cambio | Ejemplo | Qué toca |
|---|---|---|
| Paso nuevo `Happening` | `{ Type = "Happening", Id = "Petra_Aparece" }` entre el `Use Huevo` y el `Escape` de `Loco_N3_Pollo` | `LifeStoryService` (preparar paso: llamar a `HappeningService.play` y esperar `waitFor`, como hoy con `Cinematic`) y `Validate.luau` (comprobar que el id existe) |
| `Happening` dentro de un paso o un diálogo | `Cinematic = "Saga_Coser"` → `Happening = "Saga_Coser"` (la cinemática pasa a ser la pista `Camera` del acontecimiento) | Mismo motor; las cinemáticas actuales se migran a acontecimientos cuando se les añaden efectos |
| Props que apuntan a sets | `Huevo = { Set = "GraneroPetra", Mark = "Nido", Prompt = "Mirar el huevo", Dialogue = "Huevo" }` | `SceneService.makeProp`: si hay `Set`, no construye primitiva: pone el botón en la pieza del set (como hoy con los `StoryProp` del mapa, `isMapObject`) |
| Kinds nuevos de prop | `Kind = "Tractor"`, `Kind = "Tienda"`, `Kind = "Hoguera"`… | Más constructores en `SceneService.BUILDERS` (o cargar modelos con `AssetLoader`) |
| Actores con rig | Nada en las misiones: `Creatures.luau` decide por `Npc` | `SceneService.buildModel` |
| Efecto `World` y condición `World` | `Effects = { World = { ["Granja.Petra"] = "Normal" } }`; `If = { World = { ["Garaje.Estado"] = "Cerrado" } }` | `LifeStoryService` (aplicar efectos), `Conditions.check` |
| `Transition` con dimensión | `{ Type = "Transition", Text = "…", Seconds = 4, Dimension = "B66_Malvada", Teleport = "Dim:B66_Malvada.Entrada" }` | `LifeStoryService` (empujar la capa de luz y la dimensión en el cliente; al salir, `pop`) |
| `Fight`/`Escape` con efectos | `Bye`/`Hurt` ya existen; añadir `OnHitFx`, `OnDefeatFx` opcionales | `SceneService.hit/defeat` |
| Fases de los sets | `Sets.StateFor` con `Conditions` | `SetService` revisa al entrar el jugador y en cada `Completed`/`World` |

Ejemplo completo (Loco_N3_Pollo, solo lo que cambiaría):

```lua
Props = {
	Huevo = { Set = "GraneroPetra", Mark = "Nido", Name = "Un huevo enorme", Prompt = "Mirar el huevo", Dialogue = "Huevo", Once = true },
},
Steps = {
	{ Type = "Talk", Npc = "Cosme", Dialogue = "Culpa", … },
	{ Type = "Happening", Id = "Furgoneta_Vuela", Effects = { Teleport = "Granja" } },      -- antes: Transition negra
	{ Type = "Talk", Npc = "Julian", Dialogue = "Granjero", … },                              -- el set ya está en estado «Desastre»
	{ Type = "Use", Prop = "Huevo", … },
	{ Type = "Happening", Id = "Petra_Aparece" },                                             -- nuevo
	{ Type = "Escape", Place = "GranjaSilo", … },                                             -- PolloGigante ya es una gallina (Creatures)
	{ Type = "Talk", Npc = "Cosme", Dialogue = "Rayo", … },
	{ Type = "Fight", … },                                                                    -- OnHit encoge, OnDefeat la deja normal
	{ Type = "Happening", Id = "Petra_VuelveAlGallinero", Effects = { World = { ["Granja.Petra"] = "Normal" } } },
	{ Type = "Talk", Npc = "Julian", Dialogue = "Gracias", … },
},
```

---

## 6. Rendimiento (móvil) y pruebas

- **Presupuestos por nivel gráfico** (`Graphics.luau`): cada receta de `StoryFxCatalog` declara partículas/luces por
  nivel (Bajo: sin halo, la mitad de partículas, sin sombras de luces locales). `StoryFx` respeta un tope global de
  partículas activas.
- **Streaming**: `HappeningService` pide las zonas de las anclas antes de empezar (como `CinematicService`); los sets
  globales grandes van como `Model` con `ModelStreamingMode = Atomic` solo si son pequeños; el granero, por partes.
- **Dimensiones**: maquetas pequeñas y lejos; se construyen una vez; sin terreno.
- **Rigs**: piezas simples (bolas y cajas, como `AnimalPose`), < 40 piezas por rig; los gigantes no llevan más piezas,
  solo más escala.
- **Pruebas sin Roblox** (como `scripts/test-lifestory.luau`, `test-animals.luau`, `test-graphics.luau`):
  - `scripts/test-happenings.luau`: todos los acontecimientos tienen pistas ordenadas, anclas conocidas, recetas que
    existen, duración ≥ última pista.
  - `scripts/test-sets.luau`: cada set tiene `StateFor` que siempre devuelve un estado, marcas únicas, lugares que existen
    en `Locations`.
  - `scripts/test-creatures.luau`: cada `Npc` no humano de `Cast` tiene rig; escalas y `Catch` coherentes.
  - `Validate.luau`: un prop con `Set` apunta a un set y a una marca existentes; un paso `Happening` existe.
  - Prueba en Studio/nube (`scripts/cloud-test.sh`): `playthrough` de `Loco_N3_Pollo` con capturas de cada plano.

---

## 7. Plan por fases (paquetes)

Orden por impacto: primero lo que el dueño ya busca y no encuentra (la granja), y a la vez el **motor mínimo**, para que
cada paquete siguiente sea casi solo contenido.

### Paquete 1 · La granja de Villaverde y Petra (+ motor mínimo) — **primero**
- **Misiones**: `Loco_N3_Pollo` (A), `Cole07_Excursion` (B), `Saga_19_Recuerdos` (B).
- **Motor (v1)**: `HappeningService` + `HappeningClient` (pistas `Camera`, `Actors`, `Fx`, `Sound`, `Titles`, `World`),
  `StoryFx` con las 8 primeras recetas (`DustFall`, `BigShadow`, `FeatherBurst`, `Footquake`, `ShrinkBeam`, `Poof`,
  `HeatHaze`, `GreenSparks`), `Sets.luau` + `SetService`, `WorldMemoryService` (+ `data.Story.World`), `Creatures.luau`
  con el rig `Bird` (gallina gigante y normal) y la sustitución en `buildModel`/`hit`/`defeat`.
- **Decorados (Villaverde, granja «de Julián»: la de la Carretera de Villaverde; fijarla con una marca
  `StoryArea GranjaJulian` para que la historia use siempre la misma y no «la más cercana»)**:
  - **Granero grande con interior** (sustituye al de 26×20×10 de `Civic.farm`): planta 44×32 studs (≈12×9 m), 30 studs
    a la cumbrera (≈8,4 m), portón doble corredero de 18×22 studs, interior diáfano de 26 studs de alto libre, pajar en
    altillo a 12 studs en un lateral, pacas de heno (4×2,5×2,5), comederos, **nido de paja de 14 studs** al fondo.
    Mantener el nombre `Granero` y la cara delantera (FarmService pone delante la **cooperativa**,
    `FarmService.luau:1060/1132`). Por código (`Building`/`Builder`) con madera (`WoodPlanks`) roja y blanca.
  - **Gallinero** pequeño (10×8 studs) con rampa, nidales, y corral vallado (24×20) con 8–10 gallinas (rig `Bird`
    normal, o las de `Wildlife` ancladas al corral); **Petra** con lazo cuando corresponda.
  - **Cuadra** (16×12) con 2 caballos, **tractor** rojo (8×7×12), **huerto** con zanahorias arrancables, silo (existe).
    Material de apoyo: *Forest Pack* y *Landscaping Pack* (vallas, arbustos, rocas: `modelos-tienda*.md`), *House
    Props Pack* (cubos, herramientas).
  - Estados del set por jugador: `Normal` · `Desastre` (plumas gigantes, huellas de 3 dedos de 4 studs, gallinero
    reventado, puertas abombadas, temblores) · `PetraNormal` (Petra en el gallinero, pluma gigante clavada en la puerta,
    gallinero con tablones nuevos).
- **Acontecimientos**: `Furgoneta_Vuela`, `Petra_Aparece` (guion de 10 s del doc de infancia), `Petra_Encoge` (por
  golpe), `Petra_VuelveAlGallinero`, `Excursion_Viaje` (autobús y tractor), `Zanahoria_Gigante`.
- **Hecho cuando**: en la granja se entra al granero; con la misión activa se ve el desastre, el huevo de 6,5 studs en el
  nido, y aparece una gallina de 21 studs que te persigue, encoge con cada disparo y acaba en el gallinero, donde sigue
  al volver otro día; la excursión muestra gallinas, caballos y tractor de verdad.
- Esfuerzo: **L** (≈2 semanas: 1 de motor, 1 de contenido).

### Paquete 2 · Criaturas y dobles (rigs)
- **Misiones**: `Loco_N2`, `Loco_N4`, `Loco_N5`, `Loco_N6`, `Saga_03`, `UniS_Playa`, `Loco_U2`, `Loco_D1`, `Loco_D3`,
  `Loco_D4`, `Loco_D5`, `Rareza_Fotocopiadora` (A); `Side_GatoDelCole`, `Loco_A1`, `Loco_A4`, `Rareza_Perro`,
  `Loco_D2`, `Saga_22`, `Aliado_Bigotes`, `Aliado_Gnomos`, `Rareza_GatoCaja` (B); y todos los actos de la saga.
- **Rigs**: `Quadruped/Gato` (Bigotes, gatitos, gatos), `Biped/GatoPolicia`, `Fish` (Don Escamas), `Crab` (Don Pinzas),
  `Raptor` (Rex), `Biped/Cucaracha`, `Bird/PalomaRobot`, `Quadruped/Raton` (Ratón Pérez) y `Rata`, `Robot` (Pip, robot de
  seguridad), `Biped/Lapiz`, `Biped/Electrodomestico` (cafeteras, termo, batidora, aspiradora, microondas),
  `Biped/Gnomo` (vivos y de plástico), `Floater/Dron`, `Floater/Hilacha`, `Blob/Calcetines` (monstruo), alien con
  4 brazos (Ñoz), `Blob/Gelatina` (impostores al derretirse).
- **Dobles del jugador** (`AvatarCopy`): `Clone` (×3), `Older` (tu futuro), `Evil` (perilla), `Shadow` (sombra plana),
  `Mirror` (reflejo), `Paper` (Candelas de papel, versión de cualquier actor).
- **Efectos ligados**: `Pop` (clones), `Splash` (globos, cubos), `WaterBalloon` (proyectil), `Acorn` (tirachinas),
  `NaveAterriza`/`NaveDespega` (nave pequeña de las cucarachas, 10×5×7).
- Esfuerzo: **L** (rigs base 1 semana + 1 semana de especies y dobles).

### Paquete 3 · El cielo de la Grieta y la saga en la ciudad
- **Misiones**: `Loco_N1`, `Saga_05`, `Saga_06`, `Saga_07`, `Saga_10`, `Saga_12`, `Saga_18`, `Saga_23`, `Saga_24` (A);
  `Saga_02`, `Saga_20` (B); `Prologo_Sueno` (C).
- **Sistemas**: animaciones de `SkyRift` (§3.6), `LocalLighting` (apagón, hora forzada, estrellas), pista `Sky`, pista
  `Input` (QTE de la mano), `Physics` (tirón hacia la Grieta).
- **Recetas VFX**: `GreenSmokeBlast` (garaje), `Meteor` + `ImpactCrater` (cosas que caen), `LostThingsVortex`
  (remolino de objetos), `AnchorBeam` (hilo de luz del anclaje al cielo), `NeedleStitch`, `CityBlackout`, `SkyThreads`,
  `SkyZipper`, `GoldenPlatform`, `GoldenBeam`, `SkyCountdown` (números de luz), `ScreensTakeover` (todas las pantallas),
  `FusionMachine`, `InvertedCity` (silueta invertida a través de la Grieta), `RemnantBeams` (Restos que se encienden).
- **Decorados**: microondas temporal y estados del garaje de Cosme (hollín, cerrado con polvo, Cosedora v2, vitrina de
  **Restos de la Grieta** que se ilumina), montaña de cosas perdidas en el gimnasio, anclajes persistentes (parque, patio,
  plaza), valla publicitaria de MegaVerso en la plaza, escenario de la fiesta de MegaVerso, escenario de graduación del
  instituto, plataforma dorada, máquina de la Fusión en la cima.
- **Requisito de las rarezas**: que cada rareza deje su objeto en el mundo (`World`) para el clímax de `Saga_23`.
- Esfuerzo: **L** (≈2 semanas).

### Paquete 4 · Interiores y decorados de la historia
- **Misiones**: `Uni01b_Residencia`, `UniS_Pabellon0`, `Loco_U1_Monte`, `Saga_08`, `Saga_09`, `Saga_15`, `Saga_17`,
  `Saga_21` (A); `UniS_Zumo`, `UniS_Fiesta`, `UniS_Acampada`, `UniS_Tito`, `Saga_13`, `Aliado_Rex`, `Aliado_Noz` (B); y
  de rebote `UniEx1–4`, `UniS_Cita`, `Rareza_Reloj`, `Rareza_Wifi`, `Loco_D1` (oficina).
- **Decorados**: planta de la historia en la residencia (habitación 214 + cocina compartida + conserjería, con las marcas
  `HabitacionResidencia`/`CocinaResidencia`), **oficina de MegaVerso** en una torre (recepción, sala del mapa, sala de
  servidores; también «tu oficina» de `Loco_D1` con otra decoración), **laboratorio del flashback** (Cosme y Cósimo
  jóvenes) y el **Pabellón 0** (el mismo edificio, viejo), **laboratorio bajo la universidad 66-B** (pasillo de neones,
  cápsula), **Monte del Silencio**: nave grande con escalerilla, campamento (tienda, hoguera, zarzal), plató alienígena,
  círculo quemado; **piso de Adrián**; **sala de juicio** en Derecho.
- Material: *Modular Building Kit – Modern City*, *House Furniture Pack* y *House Props Pack – Duvall Drive*
  (`modelos-oficiales-2.md`), *Realistic Factory Props Pack* y estanterías *склад* (`assets-usuario-2/3.md`),
  *Forest Pack*/*Landscaping Pack* para el monte, *Bingus Particle Pack* para humo/chispas (`assets-usuario-4.md`).
  **No usar** los marcados ⛔ (p. ej. la *Realistic Campfire* de Warpzaor68: hacer la hoguera por código).
- Acontecimientos: `Flashback_LaNoche` (≈30 s, filtro de vídeo viejo), `Capsula_Abre`, `Nave_Llega`/`Abduccion`,
  `Servidor_Cae`.
- Esfuerzo: **L** (≈2–3 semanas; es el paquete con más construcción).

### Paquete 5 · Dimensiones de bolsillo
- **Misiones**: `Loco_A2_Lapices`, `Loco_U3_Multiverso`, `Loco_U5_Examen`, `Saga_14_Bigotes`, `Saga_16_66B`,
  `Rareza_Piso13` (A); `Rareza_Columpio` (B).
- **Sistemas**: `PocketDimensions` + `Dimensions.luau`, reskin local, `Transition` con `Dimension`, capa de luz,
  efecto `PortalSwallow` (remolino que te traga), `TimeFreeze` (congelar actores y partículas, desaturar).
- **Dimensiones**: G-4 (gatos), 66-B (malvada), Examen (papel), A-0 (gris), V-9 (alcaldía), Pasado (sepia), Piso 13.
- Esfuerzo: **M/L** (≈1,5 semanas; depende de los rigs del Paquete 2 para poblar G-4 y 66-B).

### Paquete 6 · Vida cotidiana, fiestas y rarezas
- **Misiones**: `Loco_A3_Concierto`, `Rareza_Espaguetis`, `Rareza_Palomas`, `Rareza_Sombra`, `Rareza_Nube` (A);
  `Cole10_Festival`, `Cole11_Proyecto`, `Cole12_UltimoDia`, `Ins02_Clubes`, `Ins04_PrimerEmpleo`, `Pan1`, `Pan2`,
  `Loco_A5_Zoltan`, `Loco_U4_Fiesta`, `Uni06_Graduacion`, `Adu02_Atardecer`, `Adu03_Reencuentro`, `Aliado_Malvado`,
  `Eco_RayoAdulto`, y las rarezas B (`Farola`, `Charco`, `Espejo`, `Cancion`, `Taquilla`, `Reloj`, `Semaforo`) (B); y
  todos los detalles C de los documentos de etapa.
- **Kit de escenarios reutilizable**: tarima/escenario plegable (patio del cole, patio del instituto, plaza, estadio,
  facultad), atril, sillas en filas, guirnaldas, farolillos, focos, torres de altavoces, puestos de feria, confeti,
  globos; con «modos» (festival, graduación, concierto DJ, fiesta MegaVerso, fiesta del estadio).
- **Recetas VFX**: `WindGust`, `SpaghettiRain`, `PersonalRaincloud`, `Hypnosis`, `MusicNotes`, `AlarmLights`,
  `PaperBurst`, `Confetti`, `SepiaFlash`.
- Esfuerzo: **M/L** (≈1,5 semanas, muy repartible: cada misión es independiente).

**Orden y dependencias**: P1 (motor + granja) → P2 (rigs: lo necesitan P3–P5) → P3 (saga en la ciudad) → P4 (interiores)
→ P5 (dimensiones) → P6 (en paralelo desde P1 si hay más gente: casi no depende del motor salvo `StoryFx`).

---

## 8. Inventario de piezas a construir

Resumen de lo que sale de los documentos de etapa (cada pieza sirve a varias misiones).

| Tipo | Cantidad aprox. | Piezas |
|---|---|---|
| Sistemas | 8 | Secuenciador de acontecimientos, catálogo VFX + `StoryFx`, `LocalLighting`, rigs de criaturas, copias del avatar, sets con estados, memoria del mundo, dimensiones de bolsillo (+ eventos de `SkyRift`) |
| Decorados grandes (sets) | ≈ 22 | Granero con interior, gallinero + corral, cuadra, garaje de Cosme (estados), gimnasio de cosas perdidas, anclajes, valla MegaVerso, escenario MegaVerso, escenarios (kit), plataforma dorada, máquina de la Fusión, residencia (214 + cocina), oficina MegaVerso (+ servidores), laboratorio del flashback / Pabellón 0, laboratorio 66-B, nave grande + plató, campamento, piso de Adrián, sala de juicio, cabina de Zoltán, almacén del súper, 7 maquetas de dimensiones |
| Objetos de misión mejorados (props) | ≈ 60 | Microondas, tractor, zanahoria gigante, huevo gigante, nido, baúl, latas, maquetas del proyecto, tienda, hoguera, zarzal, cápsula, tostadora, cafetera X-9000, tenedor gigante, buzón, farola tenor, nube, flores que muerden, Cosedoras (prototipo y v2), aguja dorada, pecera, medidor de rarezas… |
| Rigs de criaturas | ≈ 22 | Gallina (gigante/normal), gato (andante y policía), gatitos, pez, cangrejo, velocirraptor, cucaracha, paloma robot, ratón, rata, Pip, robot de seguridad, lápiz, electrodomésticos (5 variantes), gnomo (vivo/plástico), dron, hilacha, monstruo de calcetines, alien de 4 brazos, gelatina, Evaluador |
| Dobles del jugador | 6 variantes | Clon, futuro, malvado, sombra, reflejo, papel |
| Recetas VFX | ≈ 40 | Las listadas en los paquetes 1, 2, 3, 5 y 6 |
| Acontecimientos con guion de planos | ≈ 25 | Los marcados con «Guion de planos» en los documentos de etapa (Petra, coser el cielo, cremallera, flashback, Fusión, final, abducción, cápsula…) |
| Estados persistentes (`World`) | ≈ 35 | Petra en el gallinero, hollín del garaje, garaje cerrado/abierto, anclajes, murales/grafitis, Bigotes con corona, gatitos, pecera, Rex en casa, gnomos en el jardín, cartel MegaVerso, Pabellón 0 abierto, círculo quemado del monte, objetos de las rarezas, cartel de la cafetería de Omar, concha, foto del reencuentro… |
