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
