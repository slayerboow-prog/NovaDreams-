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

Publicada la **v112** (commit `205bc4b`) con la imagen de la isla para el mapa grande. Antes se subieron los
9 trozos (`textures/mapa/mapa_<fila>_<col>.png`) con `bash scripts/upload-map.sh`, y
`src/shared/MapTextureIds.luau` guarda los 9 ids. Son ids de **Decal** (Open Cloud no dio el id de la imagen):
el juego los convierte a imagen al arrancar (`shared/Images`). Comprobado en un servidor real con
`bash scripts/cloud-test.sh --version 112 -v …`:

- `diag-arranque-completo`: **todo bien** (176 s); 21 pasos de Main, 102 servicios, recuentos bien, historia
  sin errores (8 capítulos, 156 misiones), 0 errores y 0 avisos en la consola. Único aviso: servicio lento
  (`BusinessService` 5,0 s).
- `muebles-asientos`: **11 bien, 0 mal** (58 s).
- `deportes`: la primera vez, lanzada **a la vez que las otras tres**, se cortó al arrancar los servicios
  («Script timeout: exhausted allowed execution time», el mismo caso de la v106). Vuelta a lanzar sola:
  **11 bien, 0 mal** (57 s). No es un fallo del juego.
- `audio`: **99 bien, 0 mal** (71 s); música 17 bien, 0 mal.
- **Mapa grande** (prueba temporal, no guardada): los 9 Decal se convierten a imagen con
  `InsertService:LoadAsset` (como `Images.resolve`) y las 9 imágenes cargan con `ContentProvider:PreloadAsync`
  (`AssetFetchStatus.Success`). A la prueba le faltaba devolver la lista de comprobaciones y por eso salió «sin
  comprobaciones», pero todas las líneas de la consola están bien.
- Segunda pasada, desde otra ventana (la de la devolución de dinero): `diag-arranque-completo` **14 bien, 0 mal,
  1 aviso** (`BusinessService` 5,9 s; 178 s) y `muebles-asientos` **11 bien, 0 mal, 0 avisos** (50 s). Igual.
- No se ha escrito nada en el DataStore.

## Verificación v113

Publicada la **v113** (commit `53c9163`) con el mapa nuevo y las texturas de Cosme. Antes se subieron con
Open Cloud las **12 teselas** nuevas del mapa (`textures/mapa/isla_<fila>_<col>.png`, con
`bash scripts/upload-map.sh --force`) y las **6 texturas de Cosme** (sus 4 caras, la camisa y el pantalón, con
`bash scripts/upload-cosme.sh`). `src/shared/MapTextureIds.luau` guarda los 12 ids y
`src/shared/CosmeTextureIds.luau` los 6. Son ids de **Decal** (Open Cloud aún no daba el de la imagen): el juego
los convierte a imagen al arrancar (`shared/Images`). Comprobado en un servidor real con
`bash scripts/cloud-test.sh --version 113 -v …`:

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso, 1 sin comprobar** (181 s); 21 pasos de Main, 103
  servicios, recuentos bien, historia sin errores (8 capítulos, 156 misiones), 0 errores y 0 avisos en la
  consola. El aviso es el de siempre: servicio lento (`BusinessService` 5,0 s). Sin comprobar: «Empezar una
  historia con un jugador» (en un servidor de Open Cloud no hay jugadores).
- `muebles-asientos`: **11 bien, 0 mal** (57 s).
- `deportes`, lanzada **sola**: **11 bien, 0 mal** (58 s); 16 campos y 42 canastas.
- `audio`: **99 bien, 0 mal** (65 s); música 17 bien, 0 mal.
- **Imágenes y sirenas** (prueba temporal, no guardada; con el mundo preparado y todos los servicios
  arrancados): **11 bien, 0 mal, 0 avisos** (27 s).
  - Mapa: 12 de 12 ids; los 12 Decal se convierten a imagen con `Images.resolve` y las **12 cargan** con
    `ContentProvider:PreloadAsync` (`AssetFetchStatus.Success`).
  - Cosme: 6 de 6 ids; los 6 se convierten y las **6 cargan** con `ContentProvider:PreloadAsync`.
  - Sirenas: las **8 comisarías** (`PoliceStation`) y los **8 parques de bomberos** (`FireStation`) tienen su
    atributo `SirenAt` (lo ponen `PoliceService` y `FireService` con `SkyRift.publishSirenAnchor`).
  - 0 errores y 0 avisos en la consola.
- No se ha escrito nada en el DataStore.

## Verificación v114

Publicada la **v114** (commit `e3ae253`; el código es el mismo que `c043a5b`, solo añade una captura en
`docs/mapa/revision/`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":114}`. Antes de publicar
pasaron las pruebas rápidas: `test-compile` (736 archivos), `test-clientboot`, `test-serverboot`, `test-hud`,
`test-space`, `test-zonasverdes`, `test-ocio`, `test-voices-sim` y `test-futbol`. Un primer intento de subirla
a mano desde Studio no llegó al servidor (la última seguía siendo la v113).

Qué incluye:

- Voz de Cosme sin cortes.
- Saga 1 con tono 13+.
- Zonas verdes, fase 1: barra de Diversión, parques, huertos, acampada, mercadillo, feria, vóley, karts y skate.
- Combate aéreo para los probadores.
- Zona espacial: puerto, naves, estaciones, minería, misiones y 7 planetas-estrella.
- Los minijuegos de las misiones se cortan al empezar otra cosa y los avisos de arriba salen ordenados.
- El letrero «Hablar» a la altura de la cintura.
- Autobús escolar.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 114 …`:

- `diag-arranque-completo`: **14 bien, 0 mal, 1 aviso, 1 sin comprobar** (183 s); historia sin errores
  (8 capítulos, 156 misiones), 0 errores y 0 avisos en la consola. El aviso es el de siempre: servicio lento
  (`BusinessService` 5,3 s). Sin comprobar: «Empezar una historia con un jugador» (en Open Cloud no hay jugadores).
- `muebles-asientos`: **11 bien, 0 mal** (40 s).
- `audio`: **99 bien, 0 mal** (66 s); música 17 bien, 0 mal; `PlaceVersion: 114`.
- `deportes`, lanzada **sola**: **11 bien, 0 mal** (49 s); 17 campos y 71 canastas.
- No se ha escrito nada en el DataStore.

## Verificación v115

Publicada la **v115** (commit `ef95f6f`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":115}`.
Antes de publicar pasaron las pruebas rápidas: `test-compile` (754 archivos), `test-clientboot`,
`test-serverboot`, `test-hud`, `test-metro`, `test-flight`, `test-aircombat`, `test-space`, `test-planetas`,
`test-pelos`, `test-escena-al-entrar`, `test-buildingkeys` y `test-persistence`; con el lugar construido
(364 750 piezas), `test-mapcoherence` (0 críticos, 50 avisos) y `test-buildingkeys` (la mayoría de los edificios
conservan su clave).

Imágenes subidas con Open Cloud (ids de **Decal**: el juego los convierte a imagen al arrancar, `shared/Images`):

- **12 teselas del mapa grande** rehechas (`bash scripts/upload-map.sh --force`, `src/shared/MapTextureIds.luau`):
  isla_0_0 `97200277860370`, isla_0_1 `88259585607596`, isla_0_2 `107245378233449`, isla_0_3 `81610985402694`, isla_1_0 `85828265903409`, isla_1_1 `113242448307410`, isla_1_2 `72998359633622`, isla_1_3 `77324079335365`, isla_2_0 `101593579314582`, isla_2_1 `96050233506149`, isla_2_2 `129025166095109`, isla_2_3 `91236118470789`.
- **30 texturas del espacio y los planetas** (`bash scripts/upload-espacio.sh`,
  `src/shared/Cosmos/EspacioTextureIds.luau`): cielo_espacio_bk `133313351209224`, cielo_espacio_dn `140090294747118`, cielo_espacio_ft `91802526481314`, cielo_espacio_lf `109302928077622`, cielo_espacio_rt `91019505837043`, cielo_espacio_up `129099474685743`, cielo_lontana_bk `105310772691390`, cielo_lontana_dn `85720601412266`, cielo_lontana_ft `104620129405953`, cielo_lontana_lf `113636806257782`, cielo_lontana_rt `117269075187657`, cielo_lontana_up `121432658974463`, halo_atmosfera `111017305662730`, nave_casco_color `80844937877589`, nave_casco_metalness `121421086112589`, nave_casco_normal `71869261194901`, nave_casco_roughness `111097084491149`, nubes_fronda `107594682819155`, nubes_lontana `115886071240250`, nubes_marena `135069154548069`, planeta_fronda `72368015334012`, planeta_lontana `116313311350382`, planeta_marena `126185676042014`, planeta_mercadia `111380540732825`, planeta_ocrea `130367029486089`, planeta_velaria `138059202701744`, planeta_zefira `133673248412132`, roca_lontana_color `133562916624533`, roca_lontana_normal `84643508609549`, roca_lontana_roughness `100554397578050`.

Qué incluye:

- Mapa ordenado, sin manzanas amontonadas, y mudanza automática de las casas y negocios de los edificios quitados.
- Nave y arena nuevas, con palanca táctil.
- Avión con joystick que sube y baja.
- Lontana: bajada sin cortes desde el espacio.
- Pelos sueltos arreglados.
- Ninguna escena al entrar lejos de su sitio.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 115 …`:

- `diag-arranque-completo`: **13 bien, 0 mal, 2 avisos, 1 sin comprobar** (163 s); historia sin errores
  (8 capítulos, 156 misiones), 0 errores en la consola. Avisos: servicio lento (`BusinessService` 3,4 s, el de
  siempre) y dos avisos de `BodyPieceService` («416 + 4 piezas de pelo/ropa sueltas sin su personaje retiradas»):
  es el arreglo nuevo de los pelos sueltos haciendo su trabajo. Sin comprobar: «Empezar una historia con un
  jugador» (en Open Cloud no hay jugadores).
- `muebles-asientos`: **10 bien, 0 mal, 1 aviso** (30 s); el aviso es el mismo de `BodyPieceService` (4 piezas).
- `audio`: **99 bien, 0 mal** (48 s); música 17 bien, 0 mal; `PlaceVersion: 115`.
- **Imágenes** (prueba temporal, no guardada): **5 bien, 0 mal** (18 s).
  - Mapa: 12 de 12 ids se convierten a imagen con `Images.resolve` y las **12 cargan** con
    `ContentProvider:PreloadAsync` (`AssetFetchStatus.Success`).
  - Espacio: 30 de 30 ids se convierten y las **30 cargan**.
  - 0 errores en la consola.
- No se ha escrito nada en el DataStore.

## Verificación v116

Publicada la **v116** (commit `f608a29`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":116}`.
Antes de publicar pasaron las pruebas rápidas: `test-compile` (775 archivos), `test-clientboot`,
`test-serverboot`, `test-hud`, `test-metro`, `test-flight`, `test-aircombat`, `test-space`, `test-planetas`,
`test-espacio-aaa`, `test-persistence`, `test-swim`, `test-boats` y `test-mar`; con el lugar construido
(364 750 piezas), `test-airport` (la avioneta despega en los dos sentidos con flaps 0/1/2) y
`test-mapcoherence` (0 críticos, 50 avisos).

Imágenes: no había ninguna nueva sin subir. Las 31 texturas de `assets/espacio/` ya tenían id en
`src/shared/Cosmos/EspacioTextureIds.luau` y el mar no tiene imágenes propias todavía.

Qué incluye:

- Pantalla espacial AAA completa, como la imagen de referencia.
- Vuelo con esquiva, hipervelocidad y salto cuántico.
- Combate con misiles, bengalas, sobrecarga, camuflaje, modos y drones.
- Taller en las estaciones y eventos globales.
- Planetas renombrados: Tefra, Siroco, Tálasa, Nivalis, Umbría, Miasma y Vértice.
- Avión: tirar hacia abajo para subir, ayuda al despegar, tren retráctil y la misma pantalla que la nave.
- Mar, fases 1 a 4: mar hondo por zonas (terreno, luz y corrientes); exploración con aire, presión,
  recursos, cofres, sitios y misiones; criaturas; y la pantalla de buceo como la referencia.

Comprobado en un servidor real:

- **Imágenes** (`cloud-test.sh`, prueba temporal, no guardada): **5 bien, 0 mal** (28 s).
  - `PlaceVersion: 116`.
  - Mapa: 12 de 12 ids se convierten a imagen con `Images.resolve` y las **12 cargan** con
    `ContentProvider:PreloadAsync` (`AssetFetchStatus.Success`).
  - Espacio: 30 de 30 ids se convierten y las **30 cargan**.
- `diag-arranque-completo` (`--version 116`): **13 bien, 0 mal, 2 avisos, 1 sin comprobar** (171 s).
  Avisos: un servicio lento (≥ 2 s) y los de `BodyPieceService` (96 + 324 piezas de pelo/ropa sueltas
  retiradas, el arreglo de la v115 haciendo su trabajo). Sin comprobar: «Empezar una historia con un
  jugador» (en Open Cloud no hay jugadores).
- No se ha escrito nada en el DataStore.

## Verificación v117

Publicada la **v117** (commit `c443496`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":117}`.
Antes de publicar pasaron las pruebas rápidas: `test-compile` (797 archivos), `test-clientboot`,
`test-serverboot`, `test-hud`, `test-flight`, `test-aircombat`, `test-space`, `test-planetas`,
`test-espacio-aaa`, `test-mar`, `test-invasion`, `test-persistence` y `test-gameplay`; con el lugar construido
(364 750 piezas), `test-airport`, `test-avion-real` (0 errores del avión, su HUD o la palanca) y
`test-mapcoherence` (0 críticos, 50 avisos). Se repitieron todas con los ids nuevos.

Ids subidos (commit `f290d42`):

- Nave HX-7 Halcón (`scripts/upload-nave.sh`, `src/shared/AirCombat/NaveAssetIds.luau`): 10 piezas (Model) y
  13 texturas (Decal; el juego las pasa a imagen al arrancar). `Completa` queda vacía: la fase 3 no pudo
  descargar las piezas porque la clave no tiene permiso para leer assets (`403 Scope not authorized`), así
  que la nave se monta con las piezas sueltas.
- Dibujos del HUD (`scripts/upload-hud.sh`, `src/shared/HudTextureIds.luau`): 23 sprites (Decal).
- `test-espacio-aaa` exigía `NaveAssetIds` vacío: ahora comprueba que los ids son `rbxassetid` y prueba el
  caso «sin ids» con una tabla vacía (commit `c443496`).

Qué incluye:

- Avión arreglado: sentarse, motor, cámara en el hangar y reaparecer en vuelo.
- Nave HX-7 Halcón en 3D (malla hecha en Blender).
- Pantalla de vuelo con arcos brillantes, paneles e iconos.
- Mar completo.
- Invasión de la Grieta con 5 razas, reyes, transformaciones y misiones.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 117 …`:

- Prueba temporal (no guardada): **5 bien, 0 mal** (54 s). `PlaceVersion: 117`.
  - Dibujos del HUD: **23 de 23** pasan a imagen y cargan (`AssetFetchStatus.Success`).
  - Texturas de la nave: **13 de 13** pasan a imagen y cargan.
  - Nave HX-7: `NaveLoader.Status = "malla"` y la nave construida tiene `NaveVisual = "Malla"` (4,1 s).
  - `[OceanBuilder] mar hondo listo: 93084 rellenos de terreno, 338 piezas, 10.5 s`; memoria del servidor
    2307 MB (2061 MB antes del mar).
  - 0 errores en la consola.
- `arranque`: **5 bien, 0 mal, 2 avisos, 1 sin comprobar** (47 s): 114 servicios bien en 5,7 s, 0 errores.
  Avisos: `BusinessService` tarda 3,4 s y `BodyPieceService` retiró 4 piezas de pelo/ropa sueltas.
  Sin arrancar a propósito: `UpdateService`.
- No se ha escrito nada en el DataStore.

## Verificación v118

Publicada la **v118** (commit `e495cf6`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":118}`.
Antes de publicar pasaron las pruebas rápidas: `test-compile` (801 archivos), `test-clientboot`,
`test-serverboot`, `test-hud`, `test-flight`, `test-aircombat`, `test-space`, `test-planetas`,
`test-espacio-aaa`, `test-mar`, `test-invasion`, `test-persistence`, `test-gameplay`, `test-auditoria-vuelo`,
`test-reescritura` y `test-ocio`; con el lugar construido (374 132 piezas), `test-airport`, `test-avion-real`
y `test-mapcoherence` (0 críticos). Con los ids nuevos se repitieron `test-compile`, `test-clientboot`,
`test-serverboot`, `test-hud`, `test-paisaje`, `test-skyextras`, `test-daylight` y `test-gameplay`
(una vez fallaron por azar las comprobaciones del ascensor; al repetir, bien dos veces seguidas).

`test-gameplay` estaba anticuada: desde `128b52a` un «Touchdown» sin haber volado (o un rebote) ya no
suma aterrizajes, pero la prueba aterrizaba dos veces seguidas sin despegar. El juego estaba bien; la
prueba ahora simula un vuelo de verdad antes del segundo aterrizaje (commit `e495cf6`).

Ids subidos (commit `e495cf6`):

- Cielo de día (`scripts/upload-paisaje.sh`, `src/shared/PaisajeTextureIds.luau`): 6 caras `cielo_dia_*`
  (Decal; `World/SkyLoader` las pasa a imagen al arrancar).

Qué incluye:

- 21 arreglos de los beta testers: botones de la nave, pasajeros del avión, trampas, misiones e invasión.
- HUD de vuelo con dibujos que ahora sí cargan (como imagen, no como Decal) y mirilla.
- Avión estable con modo ACRO, LOOPING y TONEL, también en la nave.
- Paisaje: relieve natural fuera de la ciudad, bosques, luz de aire limpio y cielo de día propio.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 118 …`:

- Prueba temporal (no guardada): **11 bien, 0 mal** (37 s). `PlaceVersion: 118`.
  - Dibujos del HUD: **23 de 23** pasan a imagen y cargan (`AssetFetchStatus.Success`).
  - Texturas de la nave: **13 de 13** pasan a imagen y cargan.
  - Cielo de día: **6 de 6** pasan a imagen y cargan; `SkyLoader.start` sin errores.
  - Nave HX-7: `NaveLoader.Status = "malla"` (5,2 s) y la nave construida tiene `NaveVisual = "Malla"`.
  - `[OceanBuilder] mar hondo listo: 93084 rellenos de terreno, 338 piezas, 10.1 s`.
  - 0 errores en la consola.
- No se ha escrito nada en el DataStore.

## Verificación v119

Publicada la **v119** (commit `32c9a17`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":119}`.
Antes de publicar pasaron las pruebas rápidas: `test-compile` (812 archivos), `test-clientboot`,
`test-serverboot`, `test-hud`, `test-flight`, `test-aircombat`, `test-space`, `test-planetas`,
`test-espacio-aaa`, `test-invasion`, `test-shooter`, `test-weapons`, `test-combat`, `test-persistence`,
`test-reescritura`, `test-scenes`, `test-cinematic`, `test-daylight`, `test-weather` y `test-skyrift`
(`test-space` falló una vez por azar en tres comprobaciones de minería que dependen del tiempo, con la
máquina ocupada; al repetir, bien dos veces seguidas). Con el lugar construido (374 129 piezas),
`test-avion-real` (0 errores del avión, su HUD o la palanca) y `test-mapcoherence` (0 críticos, 50 avisos).
Con los ids nuevos se repitieron `test-compile`, `test-clientboot`, `test-serverboot`, `test-invasion`,
`test-espacio-aaa` y `test-hud`. No se pasó `test-cineplanos` completo.

Ids subidos (commit `32c9a17`):

- Alienígenas v2 (`scripts/upload-invasion.sh`, `src/shared/Invasion/AlienAssetIds.luau`): 50 modelos
  (Model: tropas, reyes, naves y criaturas de las 5 razas) y 40 texturas (Decal). `Completos` queda vacía:
  la fase 3 no pudo descargar los modelos (la clave no puede leer assets, como con la nave), así que cada
  alienígena se monta con las piezas del FBX y su textura de color.
- `World/AlienMeshLoader` no pasaba las texturas de Decal a imagen (no se habrían visto): ahora lo hace con
  `shared/Images` antes de ponerlas, como el cielo y los materiales.

Qué incluye:

- Cinemáticas sin paredes pegadas a la cámara ni personajes dentro de objetos; la cámara ve la decoración.
- Espacio negro con estrellas, cielo propio de Tefra, sin el HUD de Valmar ni Cosme en los planetas, y los
  avisos salen de uno en uno.
- Invasión con alienígenas y criaturas en 3D (mallas de Blender), animaciones y una nueva forma de
  disparar con ayuda para apuntar.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 119 …`:

- Prueba temporal (no guardada): **7 bien, 0 mal** (22 s). `PlaceVersion: 119`.
  - Dibujos del HUD: **23 de 23** pasan a imagen.
  - Nave HX-7: `NaveLoader.Status = "malla"` (2,9 s).
  - Alienígenas: `AlienMeshLoader.Status = "malla: 50 modelos (0 con el respaldo de piezas)"` (18,5 s);
    texturas **40 de 40** pasan a imagen; una tropa Vórtidos se monta con 12 MeshPart.
  - Respaldo: sin plantillas de malla, la misma tropa se monta con piezas (8).
  - 0 errores en la consola.
- `arranque`: **5 bien, 0 mal, 2 avisos, 1 sin comprobar** (40 s): 114 servicios bien en 7,9 s, 0 errores.
  Avisos: `BusinessService` tarda 5,2 s y `BodyPieceService` retiró 4 piezas de pelo/ropa sueltas.
  Sin arrancar a propósito: `UpdateService`.
- No se ha escrito nada en el DataStore.

## Verificación v120

Publicada la **v120** (commit `51c940e`) con `bash scripts/publish.sh`, que devolvió `{"versionNumber":120}`.
No hay assets nuevos. Cambios de código desde la v119 (commit `15aaf5b`): `Strings.contract` («a el» → «al»
sin comerse letras con tilde o eñe), `DialogueService.alive` + «Alive» desde `DialogueUI` (el servidor ya no
da la conversación por acabada ni elige la respuesta mientras sigue en pantalla) y los títulos de
`HappeningClient` en columna; además `docs/cine/auditoria-sistema.md`. Entre `bfae253` y `51c940e` solo
entraron imágenes de `docs/` (captura de los Lumínidos y fotogramas de referencia del mar).

Antes de publicar pasaron las pruebas rápidas (en `bfae253`, el mismo código): `test-compile` (812 archivos),
`test-clientboot`, `test-serverboot`, `test-hud`, `test-scenes`, `test-cinematic` (585 s), `test-stagedirector`,
`test-reescritura` (0 fallos), `test-invasion`, `test-espacio-aaa` y `test-flight`. La construcción de
`publish.sh` dio 374 129 piezas.

Comprobado en un servidor real con `bash scripts/cloud-test.sh --version 120 …`:

- Prueba temporal (no guardada): **8 bien, 0 mal** (2 s). `PlaceVersion: 120`.
  - `Strings.contract` existe y 4 frases salen bien: «sabía el», «sería el», «enseña el» intactos;
    «a el» → «al», «de el» → «del», «¡A el agua!» → «¡Al agua!».
  - `DialogueService.alive` existe, `Timeout = 180`, `AliveCap = 900`; sin conversación no hace nada ni da error.
  - `HappeningClient` y `DialogueUI` vienen en el juego publicado.
  - 0 errores en la consola.
- `arranque`: **5 bien, 0 mal, 2 avisos, 1 sin comprobar** (58 s): 114 servicios bien en 9,1 s, 0 errores.
  Avisos: `BusinessService` tarda 6,0 s y `BodyPieceService` retiró 4 piezas de pelo/ropa sueltas (como en la
  v119). Sin arrancar a propósito: `UpdateService`.
- No se ha probado en un móvil de verdad que la conversación larga siga en pantalla más de 3 minutos ni el
  rótulo en dos líneas: eso solo lo cubren `test-stagedirector` y `test-cinematic`.
- No se ha escrito nada en el DataStore.
