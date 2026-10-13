# Diagnóstico de la versión 95 (servidor real de Roblox)

Fecha: 2026-10-06. Hecho con Open Cloud *Luau execution* contra la **versión 95** publicada del lugar
(`game.PlaceVersion = 95`, universo 10767975237, lugar 113359543879512, dueño `User 11714575032`).
No se ha tocado código del juego.

Pruebas lanzadas (todas con `bash scripts/cloud-test.sh --version 95 -v <prueba>`):

| Prueba | Qué hace | Tiempo | Resultado |
|---|---|---|---|
| `arranque` | Mundo + los 95 servicios en el orden de `Main.server.luau` | 50 s | ✅ 0 errores, 0 avisos |
| `diag-modulos` | Módulos de assets a la vez (como en v89) | 244 s | ✅ 4 avisos de reintento |
| `diag-carga` | Descarga a pelo de 29 ids, grieta, casa de Cosme | 32 s | ✅ (13 errores `rbxtemp://`, solo de la prueba) |
| `audio` | Los 40 audios con id | 38 s | ✅ 40 de 40 |
| **`diag-arranque-completo`** (nuevo) | **Todo** `Main.server.luau` a la vez: mundo, 18 hilos de assets, 96 servicios, casa de Cosme; guarda todo lo que sale en la consola (con traza de `ScriptContext.Error`) y valida la historia | 176 s | ❌ **1 error** (`MaterialLook`), 7 avisos de reintento |

> `arranque` no arranca los assets y `diag-modulos` no arranca los servicios. Ninguna de las dos
> hacía lo mismo que `Main.server.luau` entero, y por eso no veían el error de `MaterialLook`.
> Por eso se ha añadido `scripts/cloud/diag-arranque-completo.luau`.

## Resumen

| # | Gravedad | Qué | Dónde |
|---|---|---|---|
| 1 | **Error** | `The current thread cannot write 'BaseMaterial' (lacking capability Plugin)` | `src/server/World/Kit/MaterialLook.luau:40` (desde `:155`, `Main.server.luau:52`) |
| 2 | Aviso | `[Assets] <id> cargó al reintento 1` (4 en una prueba, 7 en otra; ids distintos cada vez) | `src/server/World/AssetLoader.luau:117` |
| 3 | Aviso (lento) | `BusinessService` tarda 4,1–4,2 s en `init` | `src/server/Services/BusinessService.luau:1916` |
| 4 | Solo en la prueba | 13 errores `MaterialVariant.*MapContent has invalid texture 'rbxtemp://…'` | lo da Roblox al cargar el pack 15221806045 (original) en `diag-carga` |
| 5 | Solo en la prueba | `CityAssets.start: no terminó a tiempo` en `diag-modulos` | `src/server/World/CityAssets.luau:1610` |

Todo lo demás arranca bien: 96 servicios sin errores, la ciudad viene en el archivo (467 056 piezas),
autobuses, tráfico, metro y cercanías listos, la historia valida sin errores y los 40 audios cargan.

---

## 1. Error: `MaterialLook` no puede crear sus `MaterialVariant`

**Mensaje exacto** (en el `pcall` de `Main.server.luau:51-57`, que lo escribe como
`[MaterialLook] …` con `warn`):

```
The current thread cannot write 'BaseMaterial' (lacking capability Plugin)
```

**Dónde:** `src/server/World/Kit/MaterialLook.luau:40`

```lua
variant.BaseMaterial = (Enum.Material :: any)[def.Base]
```

Llamado desde `MaterialLook.start` → `MaterialLook.setup(nil, Images.map(TextureIds))` (línea 155),
que se llama desde `Main.server.luau:52`. Pasa tras 10,2 s, justo después de
`[MaterialLook] 54 texturas pasadas de Decal a imagen` (es decir, `Images.resolve` sí funciona).

**Causa probable:** en un servidor de verdad, un `Script` no tiene la capacidad *Plugin*, y Roblox no
deja escribir `MaterialVariant.BaseMaterial` en un variant creado en tiempo de ejecución. Falla en el
**primer** variant, así que `start` se corta ahí y además:

- no se crea **ninguno** de nuestros variants de `shared/Textures` (Asfalto, AceraBaldosa, Bordillo,
  Hormigon, Ladrillo, Estuco, Teja, MetalPintado, Madera, Marmol, CespedSuelo, Arena, Azulejo,
  PinturaCoche, PinturaVial, MetalCepillado, MaderaVeta);
- no se hace `SetBaseMaterialOverride` de los que no cubre `UserMaterials`: en MaterialService
  quedan `Granite=Granite`, `Plaster=Plaster`, `ClayRoofTiles=ClayRoofTiles` y `Metal=Metal`, sin
  Bordillo, Estuco, Teja ni MetalPintado;
- no se llega a `MaterialLook.assign(town)` (línea 157): la pintura vial, la laca y el cristal no se
  repasan;
- **no se conecta** `workspace.DescendantAdded` (línea 160): los coches que salen después no reciben
  la laca (`PinturaCoche`) ni el reflejo del cristal (`tuneGlass`).

`UserMaterials` ya lo sabía: en `src/server/World/UserMaterials.luau:142-148` la misma escritura va
dentro de un `pcall` y, si falla, se salta ese variant. Por eso `UserMaterials` funciona (9 de 9 packs,
19 materiales sustituidos) y `MaterialLook` no.

> Nota: la prueba corre como Open Cloud *Luau execution*, no como el `Script` del juego. El mensaje
> es de capacidades, y un `Script` normal tampoco tiene *Plugin*, así que lo más probable es que en el
> juego pase igual. Para confirmarlo: en una partida, F9 → *Server*, buscar `[MaterialLook]`.

**Arreglo sugerido:**

1. En `MaterialLook.setup`, poner `BaseMaterial` solo si cambia y dentro de un `pcall`, como en
   `UserMaterials.tryPick`. Si no se puede, saltar ese variant (`continue`) en vez de cortar todo el
   bucle.
2. Mejor todavía: crear los variants al construir el lugar. `scripts/build-place.luau` corre con
   permisos de plugin. Si llama a `MaterialLook.setup()`, los variants ya vienen en el `.rbxl` y en el
   servidor solo se actualizan los mapas (`ColorMap…`, que sí se pueden escribir). Así no hace falta
   tocar `BaseMaterial` en tiempo de ejecución.
3. En `MaterialLook.start`, envolver `setup` en un `pcall` para que `assign` y el
   `DescendantAdded` de la línea 160 se hagan siempre, aunque falle `setup`. Si no, los coches nuevos
   se quedan sin laca ni reflejo.
4. Añadir a `scripts/test-textures.luau` (o a una prueba en la nube) que `MaterialLook.start` no lance
   errores en un servidor real. `diag-arranque-completo` ya lo detecta.

## 2. Aviso: `[Assets] <id> cargó al reintento 1`

**Dónde:** `src/server/World/AssetLoader.luau:117` (`say`, que por defecto es `warn`, línea 54).

**Ids en `diag-modulos`:** 11365590395, 11392874817, 100792423689137 y 96924659951632.
**Ids en `diag-arranque-completo`:** 11552439884, 8136205160, 113264079562085, 14527172541,
16879341926, 78033796632460 y 9432856072.

**Causa probable:** es el límite de Roblox cuando muchos módulos piden assets a la vez (ya visto en v89,
§1b). Roblox contesta «User is not authorized» a ids que sí cargan solos. El reintento de `AssetLoader`
(2, 4 y 8 s) **lo arregla**: en v89 se perdían ArbolesViento, Césped y Fuego, y ahora cargan
**18 de 18** packs de naturaleza y **9 de 9** de materiales. Los ids cambian en cada arranque, así que
no hay ningún id roto.

**Arreglo sugerido:** ninguno obligatorio. Para que la consola quede limpia:
- usar `print` en vez de `warn` cuando carga al reintento, y dejar `warn` solo cuando falla del todo;
- o bajar `AssetLoader.MaxConcurrent` (línea 29) de 5 a 3–4 para que haya menos rechazos (tardaría
  algo más en cargar todo).

## 3. Aviso: `BusinessService` lento al arrancar

`init` tarda 4,1–4,2 s (todos los demás servicios juntos tardan unos 2,4 s). Imprime
`[Negocios] 508 locales, 7 gasolineras y 8 hoteles`. Bloquea el bucle de servicios de
`Main.server.luau` (líneas 286-293), así que los servicios que vienen después (MetroService, …,
LifeStoryService) arrancan 4 s más tarde.

**Causa probable:** recorre la ciudad entera buscando locales (`src/server/Services/BusinessService.luau:1916`
y siguientes) de forma síncrona.

**Arreglo sugerido:** hacer la búsqueda de locales en `task.spawn` (o `task.defer`) dentro de `init`.
O cachear la lista de locales en la ciudad al construirla (`build-place`), como atributo o etiqueta.

## 4. Solo en la prueba: errores `rbxtemp://` (no pasan en el juego)

```
MaterialVariant.ColorMapContent has invalid texture 'rbxtemp://42'. TexturePack only supports rbxassetid.
Circuitry.NormalMapContent has invalid texture 'rbxtemp://213'. …   (13 en total)
```

Salen solo en `diag-carga`, al cargar con `LoadAssetAsync` el pack Mega **original** (15221806045).
En el juego no salen (0 en `diag-modulos` y 0 en `diag-arranque-completo`), porque `UserMaterials` usa
la copia limpia del dueño (124901321113776). **No hace falta hacer nada.**

## 5. Solo en la prueba: `CityAssets.start` «no terminó a tiempo» en `diag-modulos`

`diag-modulos` no arranca `InteriorService`, y `CityAssets.start` espera `workspace.Interiores` hasta
300 s (`src/server/World/CityAssets.luau:1610`). Con todo arrancado (`diag-arranque-completo`) termina
en **32,4 s** y `workspace.Interiores` tiene 2038 salas. **No es un fallo del juego.**

---

## Carga de assets (con todo arrancado, como en el juego)

| Qué | v89 | **v95** |
|---|---|---|
| Carrocerías (`CarBodies`) | 15, estado `ready` | **32**, estado `ready`, ningún id falla |
| Naturaleza (`NatureAssets`) | 67 plantillas, 17 de 18 packs | **71 plantillas, 18 de 18 packs**: Boulder=10 Bush=7 Campfire=1 Conifer=11 Fish=6 Guardian=1 Lantern=1 Palm=10 Park=7 Pebble=9 Sakura=2 Shark=6. Colocado: 90 rocas, 160 piedrecitas, 4 rincones japoneses, 8 hogueras, 4 tiburones |
| Vegetación oficial (`MeshLibrary`) | 23 plantillas | 23 plantillas (Bush=5 Flower=9 Street=3 Tree=4 Young=2) |
| Ciudad (`CityAssets`) | 24 785 piezas colocadas | **24 785** colocadas; `Town.ActivosCiudad`: 9 carpetas, 6749 piezas; 40 tipos de plantilla; los 20 packs `ok` |
| Edificios 3D (`Buildings3D`) | — | 100 prefabs, 75 bloques cambiados, 8 materiales (2,4 s) |
| Talleres (`WorkshopProps`) | — | 18 tipos de objeto |
| Muebles (`InteriorProps`) | 27 de 41 reglas, 59 en la ciudad | 27 de 41 reglas, 59 en la ciudad |
| Interiores (`InteriorService`) | — | 2031 edificios visitables; `workspace.Interiores`: 2038 hijos, 3365 piezas |
| Materiales (`UserMaterials`) | 8 de 9 packs, 19 sustituidos | **9 de 9 packs**, 19 sustituidos, 103 993 piezas aclaradas |
| MaterialService | 208 `MaterialVariant` | 216 (208 + 8 de Buildings3D). **Faltan los 17 de MaterialLook** (§1) |
| Armas (`UserArsenal`) | 23 armas, 8 props | 23 armas, 8 props, 5 pliegues, 2 criaturas |
| Cielos (`SkyAssets`) | 4 cielos, sin fuego 11365590395 | 4 cielos; el fuego **sí** carga (al reintento) |
| Zonas de misión | 261 piezas, 217 con variant | 261 piezas, 217 con variant |
| Grieta (`Images.resolve`) | 15 de 15 | 15 de 15 (1,0 s) |

**Casa de Cosme** (`CosmeHouse.Start.start`, sin errores):

- 1 modelo con la etiqueta `CosmeHouse`: `Workspace.Town.Region.Los Pinos.Viviendas.CasaCosme`, en
  (388, 22, −2210), con 8928 descendientes y 6286 piezas (en v89 eran 8091 descendientes).
- Hijos: Cosme (293), Exterior (1964), GarajeCosme (450), GarajeSotano (373), HabitacionSecreta (407),
  Interior (2672), Laboratorio (461), MarcasHistoria (44), Sotano (1041), Tejado (1213).
- 166 `ProximityPrompt`, 72 luces, 12 `StorySpot_*`.
- El NPC Cosme está: `…CasaCosme.Cosme`.
- **Marcador del mapa: arreglado.** `MapInfo` y `MapLegend` ya tienen `CasaCosme` (en v89 había 0).

## Historia

No se puede empezar una historia de verdad: en un servidor de Open Cloud no hay jugadores, y
`LifeStoryService` lo hace todo con un `Player` y sus datos cargados. Lo que sí se ha hecho en el
servidor real es lo mismo que hace `LifeStoryService.init`, es decir, `LifeStory/Validate.report()`:

- **8 capítulos y 156 misiones: 0 errores, 0 avisos, 0 misiones bloqueadas.**
- `LifeStoryService` arranca sin errores (dentro de los 96 servicios).

Para simular una vida completa están `scripts/test-lifestory.luau` y `scripts/test-playthrough.luau`
(con Lune, fuera de Roblox). En esta sesión no había `lune` instalado, así que no se han lanzado.

## Audio

`bash scripts/cloud-test.sh --version 95 -v audio`: **40 de 40 bien.** Son 12 temas de música y stings
y 28 efectos y ambientes. Todos son del dueño (`TheSibuastian`), de tipo Audio (`AssetTypeId=3`), con
`PreloadAsync=Success` e `IsLoaded=true`. No hay errores ni avisos.

## Qué arreglar, por orden

1. **`MaterialLook`** (§1): un `pcall` en `BaseMaterial` y que `start` no se corte, o crear los
   variants en `build-place`. Es el único error real. Arreglarlo recupera las texturas propias de
   bordillos, estuco, tejas y metal, y la laca y el cristal de los coches.
2. `BusinessService.init` en segundo plano (§3), para ganar 4 s de arranque.
3. Opcional: el aviso de reintento como `print` (§2).

---

## Verificación tras publicar

Publicada la **versión 96** (commit `49ca0cb`, con `bash scripts/publish.sh`). Probada en el servidor real con
`bash scripts/cloud-test.sh --version 96 -v diag-arranque-completo`: **12 bien, 0 mal, 2 avisos**, y
arranque completo en 31,4 s.

- ✅ Ya **no** sale `The current thread cannot write 'BaseMaterial'`. `MaterialService` tiene **233**
  `MaterialVariant` (en v95 eran 216): los 17 de MaterialLook vienen ya creados en el archivo.
- ❌ **No** se imprime `[MaterialLook] N materiales con textura`. Ahora sale otro aviso:
  `[MaterialLook] The current thread cannot write 'ColorMap' (lacking capability Plugin)`. Escribir los
  mapas (`ColorMap`, `NormalMap`…) también pide la capacidad Plugin. La línea
  `variant[prop] = maps[prop] or ""` de `MaterialLook.setup` no tiene `pcall`, así que `setup` se corta,
  `start` lo recoge y `made` queda vacío. Además, `build-place.luau` solo pone `BaseMaterial` y
  `StudsPerTile`, así que **los 17 variants están en el archivo pero sin texturas**, y tampoco se aplica
  `SetBaseMaterialOverride`.
- Siguiente paso: que `scripts/build-place.luau` escriba en el archivo los mapas (con los ids de imagen
  ya convertidos, como `Images.map`), los atributos y el override. Y que `MaterialLook.setup` solo
  escriba los mapas si cambian, dentro de un `pcall`.

## Verificación v97

Generado `src/shared/TextureImageIds.luau` en un servidor real (`bash scripts/textures/image-ids.sh`, que lanza
`scripts/cloud/imagenes-texturas.luau`): **54 de 54** Decals de `shared/TextureIds` dan su id de imagen.
Publicada la **versión 97** (commit `609cc3e`, con `bash scripts/publish.sh`; `test-compile` y `test-textures`
pasan en local). Probada con `bash scripts/cloud-test.sh --version 97 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 4,2 s), arranque completo en 162,8 s.

- ✅ **0 errores y 0 avisos** en la consola. Ya no sale ningún `lacking capability Plugin` de MaterialLook.
- ✅ Se imprime `[MaterialLook] 17 materiales con textura: AceraBaldosa, Arena, Asfalto, Azulejo, Bordillo,
  CespedSuelo, Estuco, Hormigon, Ladrillo, Madera, MaderaVeta, Marmol, MetalCepillado, MetalPintado,
  PinturaCoche, PinturaVial, Teja`. `MaterialService` tiene 233 `MaterialVariant`.
- ✅ El variant **«Asfalto»** tiene `BaseMaterial=Asphalt` y su textura: un Script del servidor tampoco puede
  **leer** `ColorMap`/`ColorMapContent`/`NormalMap` (`cannot read 'ColorMap' (lacking capability Plugin)`), así
  que se comprobó serializándolo con `SerializationService:SerializeInstancesAsync` en el servidor de la
  versión 97 y leyendo el resultado: `ColorMap = rbxassetid://132300826230680` (la imagen del Decal
  `Asfalto_color` 103492487753097, igual que en `TextureImageIds`), `NormalMap = rbxassetid://90463016255606`
  y `RoughnessMap = rbxassetid://79269159699824`.
- ℹ️ El override de `Asphalt` es `U_Real_Asphalt`: el pack de materiales del dueño (World/UserMaterials) gana,
  como está previsto; «Asfalto» se usa en las piezas a las que MaterialLook se lo asigna.
- `diag-arranque-completo` ahora enseña también el «Recuento Asfalto» (BaseMaterial, mapas si se pueden leer
  y el override del asfalto).

## Verificación v98

Publicada la **versión 98** (commit `869abfc`, con `bash scripts/publish.sh`; `test-compile` pasa: 573 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 98 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 6,5 s), 1 sin comprobar (empezar una historia necesita un
jugador), arranque completo en 168,6 s.

- ✅ **Servicios (97): todos bien**, incluidos los que han cambiado: `DamageService`, `CombatService`,
  `SceneService` y `LifeStoryService` arrancan sin error (ninguno aparece en la consola ni entre los lentos).
- ✅ **0 errores y 0 avisos** distintos en la consola.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Lo de v97 sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- No hizo falta ningún arreglo.

## Verificación v99

Publicada la **versión 99** (commit `ebb4327`, con `bash scripts/publish.sh`; `test-compile` pasa: 573 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 99 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 6,2 s), 1 sin comprobar (empezar una historia necesita un
jugador), arranque completo en 168,4 s.

- ✅ **Pasos de Main (21) y servicios (97): todos bien**, incluidos los cambios de combate de este commit
  (ningún servicio aparece en la consola con error).
- ✅ **0 errores y 0 avisos** distintos en la consola.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- No hizo falta ningún arreglo.

## Verificación v100

Publicada la **versión 100** (commit `c8203be`, con `bash scripts/publish.sh`; `test-compile` pasa: 573 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 100 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 5,7 s), 1 sin comprobar (empezar una historia necesita un
jugador), arranque completo en 165,3 s.

- ✅ **Pasos de Main (21) y servicios (97): todos bien**, incluidos los cambios de LifeStoryService,
  SceneService, CombatService, WeaponService y CameraShots (ninguno aparece en la consola con error).
- ✅ **0 errores y 0 avisos** distintos en la consola.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- No hizo falta ningún arreglo.

## Verificación v101

Publicada la **versión 101** (commit `f16e964`, con `bash scripts/publish.sh`; `test-compile` pasa: 572 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 101 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 3,4 s), 1 sin comprobar (empezar una historia necesita un
jugador), arranque completo en 162,1 s.

- ✅ **Pasos de Main (21) y servicios (97): todos bien**, incluidos los cambios de armas y cámara de este
  commit (sin ayuda de apuntado, cámara nativa con arma; ningún servicio aparece en la consola con error).
- ✅ **0 errores y 0 avisos** distintos en la consola.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- No hizo falta ningún arreglo.

## Verificación v102

Publicada la **versión 102** (commit `3cc7cb5`, con `bash scripts/publish.sh`; `test-compile` pasa: 573 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 102 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 3,4 s), 1 sin comprobar (empezar una historia necesita un
jugador).

- ✅ **Pasos de Main (21) y servicios (97): todos bien**, incluidos los cambios de DataService,
  LifeStoryService, VehicleService, MetroService, RailService, BusService, CrashService, TradeService,
  BusinessService, FridgeService, WeaponService, ProgressionService y la UI (ninguno aparece en la consola
  con error).
- ✅ **0 errores y 0 avisos** distintos en la consola.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- No hizo falta ningún arreglo.

## Verificación v103

Publicada la **versión 103** (commit `21d37fa`, con `bash scripts/publish.sh`; `test-compile` pasa: 633 archivos).
Probada en el servidor real con `bash scripts/cloud-test.sh --version 103 -v diag-arranque-completo`:
**14 bien, 0 mal, 1 aviso** (BusinessService tarda 3,6 s), 1 sin comprobar (empezar una historia necesita un
jugador). Para el mapa nuevo se añadió la prueba `scripts/cloud/muebles-asientos.luau`
(`bash scripts/cloud-test.sh --version 103 -v muebles-asientos`).

- ✅ **Pasos de Main (21) y servicios (97): todos bien**; **0 errores y 0 avisos** en la consola del arranque.
- ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
  `Asphalt` = `U_Real_Asphalt`.
- ✅ **Muebles sólidos**: en 6 casas amuebladas con los assets de verdad (27 tipos), los 5 muebles grandes
  de pie llevan su caja invisible «Choque» (las puertas se atraviesan a propósito); el burro de ropa y
  las mesas altas del pub chocan (10 piezas sólidas); la cocina de Cosme (impresora, nevera, cafetera,
  microondas y mesa) choca.
- ✅ **Frutería**: 8 cajas, cada una con su producto (manzana, naranja, plátano, uvas, tomate, zanahoria,
  lechuga y sandía), su forma, su cartel de precio y su «Comprar»; 20 fruterías en el mapa.
- ✅ **Asientos con guardia**: 2044 asientos en el mapa, 0 con `CanTouch` (ninguno sienta al rozarlo),
  562 con el cartel «Sentarse»; uno creado después también queda con guardia.
- ❌ → arreglado: al amueblar salas salían avisos **«GetPartBoundsInBox: Clamping out-of-bounds extents»**
  (10 en 6 casas). `InteriorProps.free` restaba 0,1 a la talla de la caja y con un asset plano quedaba
  negativa. Ahora nunca baja de 0,05 (commit `48ab89c`; `test-compile`, `test-interiorprops` y
  `test-cosmehouse` pasan).

Republicada como **versión 104** (commit `48ab89c`) y probada otra vez:
- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 3,8 s), 1 sin comprobar; 0 errores
  y 0 avisos en la consola; historia sin errores (8 capítulos, 156 misiones).
- `muebles-asientos`: **11 bien, 0 mal**; 0 cajas fuera de rango, 0 errores y 0 avisos en la consola.

## Verificación v106

Publicada con `bash scripts/publish.sh` desde el commit `dd7191c` (`test-compile` pasa: 649 archivos). Se pidió
como 105, pero Roblox le dio el número **106** (otra ventana publicó la 105 entre medias). Probada en el
servidor real con `bash scripts/cloud-test.sh --version 106 -v …`. Para los deportes se añadió la prueba
`scripts/cloud/deportes.luau` (`bash scripts/cloud-test.sh --version 106 -v deportes`).

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 3,5 s), 1 sin comprobar (empezar una
  historia necesita un jugador).
  - ✅ **Pasos de Main (21) y servicios (99): todos bien**, incluidos los nuevos FootballService y
    BasketService; **0 errores y 0 avisos** en la consola del arranque.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
  - ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
    `Asphalt` = `U_Real_Asphalt`.
- `muebles-asientos`: **11 bien, 0 mal**; 0 cajas fuera de rango, 0 errores y 0 avisos en la consola.
- `deportes` (nueva): **8 bien, 0 mal**.
  - ✅ FootballService y BasketService arrancan sin error.
  - ✅ **Campos**: 16 piezas «Pitch» de césped, las 16 salen como campo (`Pitch.fromPart`).
  - ✅ **Canastas**: 42 aros «Rim» (`Court.isRim`), los 42 con tablero y su pista (`Court.fromParts`).
  - ✅ Una tanda de **penaltis sin jugador** (2 tiros, nadie chuta) en un campo de verdad acaba sola
    (64 s de juego) y la historia recibe «no ganada»; igual una tanda de tiros a canasta (53 s).
  - ✅ Tras la búsqueda de campos y canastas de los servicios (a los 25 s): 0 errores y 0 avisos.
- Nota: lanzando las tres pruebas a la vez, `diag-arranque-completo` y `muebles-asientos` agotaron el tiempo
  de CPU al arrancar los servicios («Script timeout»); una a una pasan. No es un fallo del juego.
- No hizo falta ningún arreglo.

## Verificación v107

Publicada la **versión 107** con `bash scripts/publish.sh` desde el commit `148f845` (`test-compile` pasa:
663 archivos; ciudad construida con 414 644 piezas). Probada en el servidor real con
`bash scripts/cloud-test.sh --version 107 -v …` (esta vez las tres pruebas a la vez, sin «Script timeout»).

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 6,6 s), 1 sin comprobar (empezar una
  historia necesita un jugador).
  - ✅ **Pasos de Main (21) y servicios (102): todos bien**; **0 errores y 0 avisos** en la consola del arranque.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
  - ✅ Lo que necesita un jugador al entrar está en pie: `MissionZones.start` ok (217 piezas de zona), casa de
    Cosme con su NPC, 167 prompts de interacción y 12 `StorySpot`; 566 asientos con «Sentarse».
  - ⏭️ Que un jugador concreto entre **con misiones e interacción** no se puede comprobar aquí: en un servidor
    de Open Cloud no hay jugadores. Nada en la consola apunta al aviso de la v106 (jugadores sin misiones), así
    que sigue pareciendo transitorio, pero hay que confirmarlo entrando en el juego de verdad.
  - ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
    `Asphalt` = `U_Real_Asphalt`.
- `muebles-asientos`: **11 bien, 0 mal**; 0 cajas fuera de rango, 27 tipos de mueble en 6 casas, 14 fruterías,
  2069 asientos (0 con `CanTouch`), 0 errores y 0 avisos en la consola.
- `deportes`: **8 bien, 0 mal**; 16 campos, 42 canastas con tablero y pista; penaltis (64 s) y tiros a canasta
  (53 s) sin jugador acaban solos; 0 errores y 0 avisos.
- No hizo falta ningún arreglo.

## Verificación v108

Publicada la **versión 108** con `bash scripts/publish.sh` desde el commit `caaa44d` (incluye `43c2243`, `c8118f6`,
`8b677cf`, `5444c4c`, `a739113`, `3839a3b` y, encima, los efectos de sonido de `d3321f0`). `test-compile` pasa
(670 archivos); ciudad construida con 414 644 piezas. El primer intento se paró solo porque en GitHub había
commits nuevos; tras traerlos (avance rápido) publicó bien. Probada en el servidor real con
`bash scripts/cloud-test.sh --version 108 -v …`, una prueba tras otra.

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 3,9 s), 1 sin comprobar (empezar una
  historia necesita un jugador).
  - ✅ **Pasos de Main (21) y servicios (102): todos bien**; **0 errores y 0 avisos** en la consola del arranque.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
  - ✅ En la consola no aparece ningún `[MISSION]`, «al cargar la historia», «pide su historia» ni «no había
    arrancado», ni ningún error de LifeStoryService, Speech, SkyRift, RainVeil, ScreenRain, Shelter o GameSfx.
  - ✅ Lo que necesita un jugador al entrar está en pie: `MissionZones.start` ok (217 piezas de zona), casa de
    Cosme con su NPC, 167 prompts y 12 `StorySpot`.
  - ⏭️ Que un jugador concreto entre con su historia y sus misiones no se puede comprobar aquí: en un servidor
    de Open Cloud no hay jugadores. Hay que confirmarlo entrando en el juego.
  - ✅ Sigue igual: `[MaterialLook] 17 materiales con textura`, 233 `MaterialVariant`, override de
    `Asphalt` = `U_Real_Asphalt`.
- `muebles-asientos`: **11 bien, 0 mal**; 0 cajas fuera de rango, 27 tipos de mueble en 6 casas, 14 fruterías,
  2069 asientos (0 con `CanTouch`, 566 con «Sentarse»), 0 errores y 0 avisos en la consola.
- `deportes`: **8 bien, 0 mal**; 16 campos, 42 canastas con tablero y pista; penaltis (64 s) y tiros a canasta
  (53 s) sin jugador acaban solos; 0 errores y 0 avisos.
- No hizo falta ningún arreglo.

## Verificación v110

Publicada la **versión 110** con `bash scripts/publish.sh` desde el commit `f0bd17b` (23 commits nuevos desde la
v108, entre ellos las voces de los NPC con proximidad y el horario de verano). `test-compile` pasa (679 archivos);
ciudad construida con 414 654 piezas. Probada en el servidor real con
`bash scripts/cloud-test.sh --version 110 -v …`, una prueba tras otra.

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 4,2 s), 1 sin comprobar (empezar una
  historia necesita un jugador). Terminó en 174 s (162,6 s de prueba; espera del arranque 152 s, «siguen en
  marcha: nada»).
  - ✅ **Pasos de Main (21) y servicios (102): todos bien**; **0 errores y 0 avisos** en la consola. Ningún
    «sigue sin terminar» ni «Error iniciando».
  - Tiempos de los pasos (segundos desde el arranque): TerrainBuilder.build 3,7 · Ciudad, Decor, Polish,
    MaterialLook, removeGroundPart, DreamIsland, CosmeHouse 0,0 · Ambient.publish 0,1 · SkyLoader 7,5 ·
    Images.resolve 15,1 · MissionZones 16,1 · WorkshopProps 17,3 · SkyAssets 21,9 · Buildings3D 28,9 ·
    UserArsenal 29,6 · NatureAssets 32,2 · InteriorProps 34,1 · MeshLibrary 42,1 · CityAssets 46,7 ·
    UserMaterials (+StreetDress) 49,7.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
  - ✅ Casa de Cosme con su NPC, 167 prompts, 72 luces y 12 `StorySpot`; 233 `MaterialVariant`; override de
    `Asphalt` = `U_Real_Asphalt`; 32 carrocerías listas.
  - ⏭️ Que un jugador entre con su historia no se puede comprobar aquí: en Open Cloud no hay jugadores.
- `muebles-asientos`: **11 bien, 0 mal** (44 s); 0 cajas fuera de rango, 27 tipos de mueble en 6 casas,
  14 fruterías, 2069 asientos (0 con `CanTouch`, 566 con «Sentarse»), 0 errores y 0 avisos.
- `deportes`: **11 bien, 0 mal** (51 s); 16 campos, 42 canastas con tablero y pista (30 pistas, todas con
  suelo), 42 carteles de baloncesto y 48 de fútbol; penaltis (64 s) y tiros a canasta (53 s) sin jugador
  acaban solos; 0 errores y 0 avisos.
- `audio`: **todo correcto**; todos los sonidos y la música (12 bien, 0 mal) son del dueño o de la biblioteca
  pública y cargan (`PreloadAsync=Success`).
- No se ha escrito nada en el DataStore. No hizo falta ningún arreglo.

## Partida de Sibuastian: el dinero a 0 € (13-10-2026, sobre la v108)

No se ha publicado ninguna versión nueva: el permiso de la sesión bloqueó `bash scripts/publish.sh`
(«despliegue a producción»), así que no hay «Verificación v109» ni pruebas sobre ella. Lo de abajo es solo
lectura (`bash scripts/cloud-test.sh -v diag-partida`, con `GetAsync`, `ListVersionsAsync` y
`GetVersionAsync`; no se ha escrito ni restaurado nada). La prueba ahora enseña también, en cada versión,
lo que puede quitar dinero (modo pruebas, Hacienda, multas, alquiler y deuda, vida, viviendas).

- El dueño del juego (`User 11714575032`, TheSibuastian) **no tiene partida**; la de «Sibuastian» es la del
  usuario **8103097978** (está en `Config.TesterNames`: es tester, con «Sin requisitos» encendido y el dinero
  infinito **apagado**, `RealMoney=0`).
- Estado ahora (13:12 UTC, conectado hace segundos, sin `SessionLock`): **Money=0**, Nivel 3 (81 XP), Día 3,
  niño de 6 años (familia de NPC.MAMA, casa LosPinos_480_-2260_2), historia con 1 capítulo y 3 misiones hechas,
  2748 s jugados, `MoneyEarned=0`, 2 objetos y 4 vehículos. Nada se ha perdido aparte del dinero.

| Versión (UTC) | Money | Nv. | Día | Jugado | `Housing.Debt` | Alquiler 1.º D |
|---|---|---|---|---|---|---|
| 10-10 20:59 | 500 | – | 1 | 192 s | 0 | – |
| 10-10 21:19 | 465 | – | 2 | 770 s | 0 | 35 €/día |
| 12-10 20:43 | 360 | 1 | 2 | 846 s | 0 | sin deuda |
| 13-10 08:16 | 325 | 2 | 2 | 1148 s | 0 | sin deuda |
| 13-10 10:58 | **330** | 3 | 3 | 1496 s | **0** | sin deuda |
| 13-10 11:31 | **0** | 3 | 3 | 2267 s | **480** | sin deuda |
| 13-10 12:28 | 0 | 3 | 3 | 2692 s | 475 | debe 35 (1 impago) |
| 13-10 13:12 | 0 | 3 | 3 | 2748 s | 470 | debe 35 (1 impago) |

- **Cuándo**: entre la versión de las 10:58 (330 €) y la de las 11:31 (0 €). Roblox no guardó ninguna versión
  intermedia, así que el momento exacto no se ve.
- **Por qué**: no es un robo, una multa, Hacienda ni el modo pruebas (`Record` vacío, sin `Jail`,
  `Tax.Pending=0`, dinero infinito apagado en todas las versiones, y la vida no ha cambiado: el mismo niño de 6
  años). En ese tramo aparece una **deuda de alquiler** (`Housing.Debt`) de **810 €** y
  `HousingService.collectRent` la cobra «con lo que tengas»: se lleva los 330 € de golpe y quedan 480 €. Desde
  entonces, cada paga de 5 € (`Conduct.PaidAt`) se va también a la deuda (480 → 475 → 470), por eso sigue a 0 €.
- **De dónde sale la deuda**: solo se escribe en dos sitios: perder un alquiler tras 3 impagos
  (`HousingService.collectRent`) o dejar un piso alquilado con deuda (`PropertyService`, al dejarlo). Los 810 €
  (por ejemplo 3 × 270 €) apuntan a un piso alquilado caro que no sale en ninguna versión guardada (el de
  35 €/día no tenía deuda). Cuál de los dos fue no se puede saber con lo guardado.
- **¿Es normal?**: según el código, sí (la deuda se cobra entera en cuanto hay dinero), pero es un fallo de
  diseño para esta partida: es un **niño de 6 años** con un piso de alquiler (1.º D, 35 €/día, asignado de bebé,
  antes del arreglo de `Properties.MinStage`) que paga deudas de alquiler. Además se le sigue cobrando el
  alquiler del 1.º D (ya debe 35 €, 1 impago de 3): sin dinero lo perderá y la deuda crecerá.
- Propuesta (sin hacer): no cobrar alquiler ni deudas antes de `Properties.MinStage` y quitar los alquileres
  asignados a menores. Devolverle los 330 € exige restaurar o editar la partida: lo decide el dueño.

### Arreglo (sin publicar)

- **De dónde sale el alquiler del niño**: el 1.º D no se lo «asignó» nada (la vivienda al llegar es
  `Contract = "Inicial"`, gratis). Es un `Alquiler` hecho con el cartel «Alquilar vivienda» (tecla R, 1 s):
  la partida es de tester con «Sin requisitos» encendido, y con eso `JobPrompts` le enseñaba el cartel
  aunque tenga 6 años y `PropertyService.buy` se saltaba la edad (`TesterService.bypass`). 500 → 465 € es
  justo el primer día (35 €).
- **Los 810 €**: solo encajan con perder un alquiler de **270 €/día** (un chalet de unos 10 800 €) tras 3
  impagos (3 × 270). Dejarlo con 1 o 2 impagos no da 810 (el alquiler más caro del mapa ronda 345 €/día).
  Tres impagos en los 33 minutos entre las dos versiones son imposibles con días de 20 minutos… salvo por
  otro fallo: un alquiler **sin `RentDue`** (alquilado y fuera antes del primer cobro, que llega a los 20 s)
  no se corría al cargar; `collectRent` tomaba `Since` (de hace días) y, como `RentDue += día` seguía en el
  pasado, **cobraba un día cada 20 s**: 3 impagos y desahucio en un minuto. Con lo guardado no se ve qué
  piso fue: el chalet no sale en ninguna versión.
- Arreglado:
  - Menores (por debajo de `Properties.MinStage`): `collectRent` no les cobra alquiler ni deuda (la paga ya
    no se va a ella), ni hay avisos ni desahucio. Dejar un alquiler no les pasa deuda. No pueden comprar ni
    alquilar, **tampoco en modo pruebas** (el tester se cambia de etapa en el panel). Hacienda no les pone
    cuota ni recargos y los inspectores no les cobran.
  - Como mucho un cobro de alquiler por vez (si el siguiente ya ha pasado, pasa a ser dentro de un día), y al
    cargar, un alquiler sin `RentDue` toma el próximo cobro desde ahora.
  - Al cargar (`HousingService.fixMinor`, idempotente): a los menores se les quitan los alquileres (y salen
    del registro de dueños), la deuda y los impagos. Se quedan la vivienda «Inicial» y la casa de la familia;
    «Ir a casa» deja de apuntar al piso alquilado. Lo borrado queda en `Housing.MinorFix` y sale una vez en
    la consola. La deuda que traía de adulto con «Vida nueva» (`Housing.AdultDebt`) se queda, sin cobrar
    hasta la mayoría de edad.
  - **El dinero no se devuelve solo**: la partida no apunta cuánto se pagó de la deuda (no hay contador), así
    que no se inventa nada. Solo si una partida trae `Housing.MinorDebtPaid` se devuelve eso.
- **Para devolverle el dinero a mano** (lo decide el dueño):
  1. Antes, **publicar este arreglo**. Con el código de ahora, el dinero devuelto se iría otra vez a la deuda
     de 470 € en el siguiente cobro (20 s).
  2. Que el jugador entre una vez con la versión nueva (la limpieza le quita el 1.º D y la deuda) y salga.
  3. Con el jugador **fuera** (sin `SessionLock`), en la partida del usuario 8103097978 (no la del dueño),
     con `UpdateAsync` sobre la versión actual: `Money += 330`. Con los dos 5 € de paga que también se
     fueron a la deuda (480 → 470) serían 340. Si además se le quiere devolver el alquiler del 1.º D que pagó
     de niño (500 → 465 → 360 → 325: 5 días × 35 €), 175 más. No hace falta tocar nada más.
  - Restaurar la versión de las 10:58 también da 330 €, pero pierde lo jugado después (1496 → 2748 s, XP y
    misiones) y vuelve a traer el 1.º D; no compensa.

## Verificación v111

Publicada la **versión 111** con `bash scripts/publish.sh` desde el commit `e7480ea` (el arreglo del alquiler de
los menores de `b85ff8a` y la música, fusionados). `test-compile` pasa (679 archivos); ciudad construida con
414 654 piezas. Probada en el servidor real con `bash scripts/cloud-test.sh --version 111 -v …`, una prueba
tras otra.

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso** (BusinessService 4,6 s), 1 sin comprobar (empezar una
  historia necesita un jugador). Terminó en 173 s (162,9 s de prueba; espera del arranque 150 s, «siguen en
  marcha: nada»).
  - ✅ **Pasos de Main (21) y servicios (102): todos bien**; **0 errores y 0 avisos** en la consola.
  - Tiempos de los pasos (segundos desde el arranque): TerrainBuilder.build 4,1 · Ciudad, Decor, Polish,
    MaterialLook, removeGroundPart, DreamIsland, CosmeHouse 0,0 · Ambient.publish 0,2 · SkyLoader 8,7 ·
    Images.resolve 17,1 · WorkshopProps 19,7 · MissionZones 24,3 · SkyAssets 27,2 · Buildings3D 30,9 ·
    UserArsenal 31,9 · NatureAssets 33,8 · InteriorProps 37,0 · MeshLibrary 45,5 · CityAssets 50,7 ·
    UserMaterials (+StreetDress) 54,0.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
  - ✅ Casa de Cosme con su NPC, 167 prompts, 72 luces y 12 `StorySpot`; 233 `MaterialVariant`; override de
    `Asphalt` = `U_Real_Asphalt`; 32 carrocerías listas; 2049 interiores.
  - ⏭️ Que un jugador entre con su historia (y que `HousingService.fixMinor` limpie la partida de un menor) no
    se puede comprobar aquí: en Open Cloud no hay jugadores. Hay que confirmarlo entrando en el juego.
- `muebles-asientos`: **11 bien, 0 mal** (41 s); 0 cajas fuera de rango, 27 tipos de mueble en 6 casas,
  14 fruterías, 2069 asientos (0 con `CanTouch`, 566 con «Sentarse»), 0 errores y 0 avisos.
- `deportes`: **11 bien, 0 mal** (52 s); 16 campos, 42 canastas con tablero y pista (30 pistas, todas con
  suelo), 42 carteles de baloncesto y 48 de fútbol; penaltis (64 s) y tiros a canasta (53 s) sin jugador
  acaban solos; 0 errores y 0 avisos.
- `audio`: **99 bien, 0 mal** (64 s); todos los sonidos y la música (17 bien, 0 mal) son del dueño o de la
  biblioteca pública y cargan (`PreloadAsync=Success`).
- No se ha escrito nada en el DataStore: la devolución del dinero a la partida 8103097978 (pasos 2 y 3 de
  «Para devolverle el dinero a mano») queda pendiente, aparte. No hizo falta ningún arreglo.

## Devolución de 330 € (13-10-2026, sobre la v111)

(Al final se devolvieron 515 €: ver la última parte de esta sección.)

Con la confirmación del dueño se le han devuelto a «Sibuastian» (usuario **8103097978**) los 330 € que le quitó la
deuda de alquiler (ver «Partida de Sibuastian: el dinero a 0 €»). No se ha publicado nada.

- **Antes** (`diag-partida`, solo lectura): sin `SessionLock` (desconectado), la limpieza de la v111 hecha
  (`Housing.MinorFix` existe, `Housing.Debt=0`, sin pisos de «Alquiler»: solo el 3ºD «Inicial»). **Money=5**
  (una paga que ya no se fue a la deuda). En las versiones viejas se ve de dónde salían los 810 €: una
  **Villa en «Alquiler», 270 €/día, `Debt=540`, `Unpaid=2`**, alquilada ya de bebé (versión del 12-10).
- **Escritura**: `bash scripts/cloud-test.sh -v devolver-dinero` (`scripts/cloud/devolver-dinero.luau`), con
  `UpdateAsync` sobre `Player_8103097978` en `Config.DataStoreName` (nunca `SetAsync`). Dentro de la
  transformación no escribe (devuelve `nil`) si hay `SessionLock` reciente (la regla de DataService:
  `AutosaveSeconds * 3`), si falta `Housing.MinorFix` o si `Housing.MinorFix.Refund` ya es 330. Si no, solo hace
  `Money += 330` y `Housing.MinorFix.Refund = 330`.
  - La primera vez al script le faltaba `return Cloud.resultado()` y la prueba salió «sin comprobaciones»,
    pero la escritura sí se hizo. Corregido el final, se volvió a correr: «no se ha escrito nada: ya devuelto
    antes (Housing.MinorFix.Refund = 330) (Money=335)». Es idempotente: correrlo otra vez no devuelve nada más.
- **Después** (`diag-partida`): **Money=335**, sin `SessionLock`, `Housing.MinorFix` con la marca `Refund`.
- **Segunda parte, a petición del dueño («devuélvemelo todo»)**: también los 10 € de paga que se fueron a la
  deuda (480 → 470) y los 175 € del alquiler del 1.º D que pagó de niño (5 días × 35 €). El script ahora tiene
  un total `REFUND = 515` (330 + 10 + 175) y suma solo lo que falte respecto a `Housing.MinorFix.Refund`
  (sigue siendo idempotente). Ejecutado: **Money 335 → 520**, `Refund = 515`. Vuelto a correr: «ya devuelto
  antes (Housing.MinorFix.Refund = 515) (Money=520)», sin escribir.
- `diag-partida` justo después: **Money=520**. El jugador entró en el juego después de la escritura (`SessionLock`
  de hace 12 s), así que su servidor cargó ya los 520 €.
- **Total devuelto: 515 €** (de 5 € a 520 €).

## Verificación v112

Publicada la **versión 112** con `bash scripts/publish.sh` desde el commit `205bc4b`: la v111 más el mapa grande
nuevo (`d1bf5b2`) y sus 9 teselas (`205bc4b`), de otras ventanas. La devolución de dinero no toca el juego (solo
documentación y `scripts/cloud/`). `test-compile` pasa (681 archivos); ciudad construida con 414 654 piezas. El
primer intento se paró por el candado («faltan cambios de otras ventanas»): se fusionó `205bc4b` y se publicó.

- `diag-arranque-completo` (`--version 112`): **14 bien, 0 mal, 1 aviso** (BusinessService 5,9 s), 1 sin comprobar
  (empezar una historia necesita un jugador). 178 s.
  - ✅ Pasos de Main (21) y servicios (102): todos bien; **0 errores y 0 avisos** en la consola.
  - ✅ Historia: `Validate.report()` sin errores (8 capítulos, 156 misiones, ninguna que no se active).
- `muebles-asientos` (`--version 112`): **11 bien, 0 mal, 0 avisos** (50 s).
