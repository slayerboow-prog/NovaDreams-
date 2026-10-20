# Diagnóstico de la versión 89 (servidor real de Roblox)

Fecha: 2026-10-05. Hecho con Open Cloud *Luau execution* contra la **versión 89** publicada del lugar
(`game.PlaceVersion = 89`, universo 10767975237, lugar 113359543879512, dueño `User 11714575032`).

Scripts (nuevos, no tocan el juego):

- `scripts/cloud/diag-carga.luau`: descarga directa de ids, grieta y casa de Cosme.
  Se lanza con `bash scripts/cloud-test.sh --version 89 -v diag-carga` (21 s).
- `scripts/cloud/diag-modulos.luau`: arranca a la vez los módulos de assets, igual que `Main.server.luau`,
  y cuenta lo que cargan y colocan.
  Se lanza con `bash scripts/cloud-test.sh --version 89 -v diag-modulos` (226 s).

Qué dijo el dueño, tras jugar la v89 en el móvil:

1. «Todo se ve igual».
2. No ve la grieta del cielo de noche, aunque su HUD pone «Día 4 · La grieta en el cielo».
3. La casa de Cosme no sale en el mapa.

## Resumen

| Queja | ¿Qué pasa de verdad? | Causa |
|---|---|---|
| «Todo se ve igual» | El servidor **sí** carga y coloca los assets nuevos. | No está en la carga. Lo más probable es el **nivel gráfico Bajo** del móvil: esconde justo lo nuevo. Ver §1. |
| No hay grieta | Las 15 texturas de la grieta **sí** se pasan de decal a imagen (15/15, en 0,7 s). | No son las texturas. La grieta está fija **al norte y alta**; en el móvil casi no se mira hacia ahí. También puede que la fase no sea «Crece». Ver §2. |
| Cosme no sale en el mapa | La casa **sí** está en el mundo. | Al mapa **le falta el marcador**: `MapInfo.Kinds` y `MapLegend` no conocen el modelo `CasaCosme`. Ver §3. |

**Respuesta a la pregunta clave:** sí, los assets de la comunidad cargan en un servidor de verdad, pero
**solo con `AssetService:LoadAssetAsync`**. Con `InsertService:LoadAsset` fallan casi todos y dan
`User is not authorized to access Asset.`

---

## 1. ¿Cargan los assets? (pregunta clave)

### 1a. Descarga directa (`diag-carga`)

- `AssetService.AllowInsertFreeAssets` no se puede leer desde un script:
  `The current thread cannot read 'AllowInsertFreeAssets' (lacking capability RobloxScript)`.
  En `default.project.json` está a `true`. Lo que de verdad importa es el resultado de abajo.
- **`LoadAssetAsync`: cargan 29 de 29.** Son de la comunidad 26, y cargan los 26.
- **`InsertService:LoadAsset`: cargan 9 de 29.** De la comunidad cargan solo 6 de 26. El error exacto es
  siempre `User is not authorized to access Asset.`
  Los 6 de la comunidad que sí cargan son 5411055653, 124901321113776 (copia del dueño), 3778526307,
  12152263865, 9700798278 y 266515007.

| Módulo | Id | Creador | LoadAssetAsync | InsertService:LoadAsset |
|---|---|---|---|---|
| MeshLibrary | 6432306802 | Roblox | OK (789 desc., 0,3 s) | OK |
| MeshLibrary | 10840661513 | Roblox | OK (4522 desc.) | OK |
| NatureAssets | 96924659951632 | Stridity_1234 | OK (119) | ❌ not authorized |
| NatureAssets | 8553512581 | RedWood Roleplay (grupo) | OK (928) | ❌ not authorized |
| NatureAssets | 16879341926 | m00nyx26 | OK (35) | ❌ not authorized |
| NatureAssets | 9262569938 | Necta Developments (grupo) | OK (12) | ❌ not authorized |
| CityAssets | 5411055653 | MissingFeature | OK (243) | OK |
| CityAssets | 113264079562085 | NyrexBLX | OK (876) | ❌ not authorized |
| CityAssets | 99479110531330 | Slowgamer1233 | OK (3689, 2,4 s) | ❌ not authorized |
| InteriorProps | 8236576991 | SpaceProX (grupo) | OK (1) | ❌ not authorized |
| InteriorProps | 13395313510 | RobloxHouse30008 | OK (1226) | ❌ not authorized |
| InteriorProps | 5674029686 | xJavisDonasx | OK (90) | ❌ not authorized |
| UserMaterials | 11392874817 | AndiArbeitlol | OK (1) | ❌ not authorized |
| UserMaterials | 15221806045 | seG1as | OK (525) | ❌ not authorized |
| UserMaterials | 124901321113776 | TheSibuastian (dueño) | OK (519) | OK |
| UserMaterials | 92927007790601 | Mono_Rblx45 | OK (69) | ❌ not authorized |
| MaterialExtras | 12433695725 | Richo_boiii | OK (1676) | ❌ not authorized |
| MaterialExtras | 3778526307 | SomeLoverForRoblox | OK (346) | OK |
| MaterialExtras | 12152263865 | SulkyRap | OK (16) | OK |
| CarBodies | 6418239833 | Roblox | OK (1866) | OK |
| CarBodies | 9432856072 | SubXero_X | OK (17352, 0,9 s) | ❌ not authorized |
| CarBodies | 97902046131324 | Teddy_FV | OK (205) | ❌ not authorized |
| CarBodies | 16358361587 | 2races | OK (7) | ❌ not authorized |
| SkyAssets | 102765136165948 | lun42386 | OK (20) | ❌ not authorized |
| SkyAssets | 8159177542 | Carcat62 | OK (6) | ❌ not authorized |
| SkyAssets | 11365590395 | agentphilip07 | OK (3) | ❌ not authorized |
| UserArsenal | 117850698505269 | captain545745V2 | OK (6731) | ❌ not authorized |
| UserArsenal | 9700798278 | MrMcGillMan789 | OK (193) | OK |
| UserArsenal | 266515007 | MrMcGillMan789 | OK (149) | OK |

Todos los módulos prueban primero `LoadAssetAsync`, menos dos:

- `MeshLibrary.load` solo usa `InsertService`. No pasa nada, porque solo carga packs oficiales de Roblox.
- `Images.resolve` también usa solo `InsertService`, pero con decals del dueño, así que funciona.

### 1b. Los módulos arrancados a la vez (`diag-modulos`, como en el juego)

| Módulo | Tiempo | Resultado |
|---|---|---|
| `MeshLibrary.load` | 0,4 s | 23 plantillas: Bush=5 Flower=9 Street=3 Tree=4 Young=2 |
| `NatureAssets.load` | 11,1 s | **67 plantillas**: Boulder=10 Bush=7 Campfire=1 Conifer=10 Fish=6 Guardian=1 Lantern=1 Palm=10 Park=4 Pebble=9 Sakura=2 Shark=6. Cargan 17 de 18 packs; **no carga ArbolesViento 96924659951632** («User is not authorized», con los dos métodos) |
| `CityAssets.start` | plantillas en ~1 min; colocación hecha antes de 226 s | 40 tipos de plantilla. **Colocado: 24 785 piezas** (en `Town.ActivosCiudad`: 9 carpetas, 6747 piezas, más lo que va dentro de las manzanas): AC=407, Hidrante=180, Cono=164, Parche=400, Jardinera=75, Buzon=70, Quiosco=50, Skyline=38, Pale=38… (su `start` no vuelve: se queda esperando `workspace.Interiores` para las oficinas, que es lo normal) |
| `InteriorProps.start` | 10,1 s | **27 de 41 reglas** con muebles de la Tienda; 59 objetos puestos en la ciudad (carpetas `MueblesValmar`; el resto va en las salas al entrar) |
| `UserMaterials.start` (+StreetDress, HouseDress, InteriorDress, MaterialExtras) | 32,0 s | **8 de 9 packs**; **no carga Césped 11392874817** («not authorized»). **19 materiales sustituidos** (19 `SetBaseMaterialOverride` propios): Grass, LeafyGrass, Asphalt, Pavement, Concrete, Brick, Cobblestone, Limestone, Slate, Marble, Sand, Rock, Ground, WoodPlanks, Wood, CeramicTiles, Pebble, Mud, DiamondPlate. Biblioteca: Real(9) RealMad(2) Mega(490) Gen(7) Tyler(52) PBR(19) Todos(0) Arena(0) RPacks(26) Duvall(17) MCity(16). 103 596 piezas aclaradas |
| MaterialService al final | — | **208 `MaterialVariant`**; **40 materiales con override** (los 19 de arriba + 21 que se llaman igual que su material, como Plastic=Plastic o Basalt=Basalt, y que no vienen de UserMaterials) |
| StreetDress / HouseDress / InteriorDress | (dentro de lo anterior) | Calles con asfaltos y aceras de los packs (p. ej. AceraCentro=U_Tyler_Pavement2 en 2277 piezas). Edificios: Estuco 22 973, Hormigón 15 542, Teja 8885… Interiores: Parquet 407, Yeso 403… |
| `MaterialExtras` | (dentro de UserMaterials) | 6 de 6 packs de texturas; **29 láminas** puestas (Moqueta 2, Papel 4, Techo 23), arena de playa 4, **bronce 2** (6 mallas) |
| `CarBodies.start` | 4,8 s | estado `ready`, **15 carrocerías** (Aurea Berlina, Kestrel Sierra, Toro Faena, Brisa Carga, Valmar Patrulla, Kestrel Ranchera, Toro Campo, Brisa Sprint, Valmar Clásico, Toro Familia, Valmar Patrulla Clásica, Aurea Lumen, Valmar Urbano, Toro Ruta, Kestrel Reparto). **Ids que fallan: ninguno** |
| `SkyAssets.start` | 1,2 s | 4 cielos (Asteroides, Isla, Arcoiris, Verde); FxLibrary: Fuego, Luna3D, NubeTormenta y 18 atributos. **No carga el fuego 11365590395** (el fuego se hace igual, con el respaldo) |
| `UserArsenal.load` | 7,9 s | **23 armas**: Escopeta=1 Escudo=1 Francotirador=3 Fusil=9 Pistola=4 Subfusil=4 Taser=1, y **8 props** (Bate, Camarografo, CarroCombate, CascoMilitar, Explosivo, MazoGoma, MiraPuntoRojo, PistolaGato). No carga 101748452 (PistolaDorada, «not authorized» con los dos métodos). 117850698505269 y 546753609 cargan pero dan 0 mallas |
| `MissionZones.start` | 3,2 s | 261 piezas, **217 con MaterialVariant** (81 variants del Mega Pack) |

**Fallos que van y vienen.** Estos tres ids **cargan bien solos** (en `diag-carga`), pero **fallan** con
«User is not authorized to access Asset.» cuando todo carga a la vez (en `diag-modulos`):

- 96924659951632 (ArbolesViento);
- 11392874817 (Césped);
- 11365590395 (Fuego).

Parece un límite de Roblox cuando se piden muchos assets a la vez, y entonces el error que sale es el de
permisos. Cada módulo lo prueba una sola vez y, si falla, se queda sin ese pack para todo el servidor.

Errores `rbxtemp://`: cuando se carga el pack Mega **original** (15221806045) o el Césped con
`LoadAssetAsync`, salen 13 errores así:
`MaterialVariant.NormalMapContent has invalid texture 'rbxtemp://…'. TexturePack only supports rbxassetid.`
En el juego no pasa: `UserMaterials` carga primero la copia limpia del dueño (124901321113776), que no da
estos errores (0 en `diag-modulos`).

### Conclusión de «todo se ve igual»

El servidor descarga y coloca casi todo en el primer minuto: vegetación, rocas, coches, materiales, calle,
muebles, armas y cielos. **No es un problema de permisos.**

La explicación más probable está en el cliente del móvil:

- `UI/Perf`: en el móvil se empieza en «Medio» y, en «Auto», baja a **«Bajo»** si va a menos de 27 fps
  durante 6 s. Eso es fácil en un móvil con 25 000 piezas nuevas.
- En «Bajo», `Controllers/MaterialDetail` **esconde justo lo nuevo**:
  - las mallas de `CityAssets` y de `Buildings3D` (etiquetas `CityDetail` y `BuildingMesh`; se vuelve a
    ver la caja de antes, `BuildingShell`);
  - el relieve (normal map) de los materiales;
  - el césped 3D;
  - los adornos de la ciudad.

  Su propio comentario lo dice: «queda la ciudad lisa de antes».
- Además, en el móvil `Perf.lite` borra los objetos `LiteDetail` de la acera.

No se puede comprobar desde aquí: Luau en la nube solo corre el servidor. Pero encaja con «todo se ve igual».

## 2. Grieta del cielo

`src/shared/RiftTextureIds.luau` tiene 15 ids. Los 15 son **Decal** (`AssetTypeId=13`), del dueño
(TheSibuastian).

En el servidor, `Images.resolve(RiftTextureIds)` → **15 convertidos en 0,7 s**. `ReplicatedStorage.ImageIds`
queda con 15 atributos:

| Nombre | Decal | → Imagen |
|---|---|---|
| bolt_1 | 81654026338245 | 124671806300791 |
| bolt_2 | 87062526114803 | 98602666575010 |
| bolt_3 | 81507510862551 | 119405810288691 |
| bolt_4 | 99107342482841 | 83279749421899 |
| rift_galaxy | 96082065890822 | 90019060486436 |
| rift_glow | 103438813506981 | 90866218479020 |
| rift_interior | 135267051123240 | 135348732950574 |
| rift_rays | 112544730117139 | 120946330179566 |
| rift_s2 | 122438814831966 | 105361728510827 |
| **rift_s3** (la de «Crece») | 110672400346993 | **102463672126433** |
| rift_s4 | 94949033598735 | 111792654098208 |
| rift_s6 | 89147938919386 | 126239661148723 |
| rift_s6_galaxy | 99172097554793 | 106494725461894 |
| rift_s7 | 104563521521546 | 112358332323127 |
| rift_s7_galaxy | 115602459610431 | 84928225835485 |

**El paso de decal a imagen funciona.** Ningún id se queda como decal, así que las ImageLabel no salen en
blanco por esto. El cliente (`Controllers/SkyRift`, `build()`) llama a `Images.of` al construir la etapa.
Como `resolve` tarda menos de 1 s al arrancar el servidor, el jugador ya entra con los ids buenos.

### Conclusión de «no hay grieta»

No son las texturas. Hay tres posibilidades, de más a menos probable:

1. **No se mira hacia donde está.** La grieta está siempre en la misma dirección del cielo:
   `SkyRift.Placement.Sky.Direction = {0.25, 0.78, -1}`. Eso es **hacia el norte (−Z) y unos 37° por
   encima del horizonte**, a 650 studs de la cámara. En la etapa 3 mide 600 studs de ancho. En el móvil,
   la cámara suele mirar al frente o hacia abajo, así que si no mira al norte y hacia arriba no la ve nunca.
2. **La fase no es «Crece».** El HUD enseña el título de la misión seguida («La grieta en el cielo» =
   `Saga_02_Grieta`). Con esa misión activa, `SkyRift.phaseFor` da «Crece»… salvo que siga activo el
   prólogo del sueño. Entonces da «Sueno», y la grieta se dibuja en la isla del sueño, no sobre Valmar.
   Hay que mirar el atributo `SkyRift` del jugador (con `/debug`).
3. En «Bajo» la grieta se dibuja igual (sin rocas y con menos rayos), así que no es por el nivel gráfico.

## 3. Casa de Cosme y el mapa

- **Está en el mundo:**
  - `CollectionService:GetTagged("CosmeHouse")` da 1 modelo:
    `Workspace.Town.Region.Los Pinos.Viviendas.CasaCosme`, en **(390, 33, −2210)**, con 8091 descendientes
    (dentro está `GarajeCosme`).
  - `Region.cosmeSite()` da Los Pinos, celda 1,1, centro (390, 0, −2210). Es la manzana de al lado de la
    casa familiar.
- **No sale en el mapa:** hay **0** entradas con «cosme» en `MapInfo.Kinds` y **0** en
  `MapLegend.Categories`.
  - `WorldService.publishLandmarks` solo publica los modelos de `Town` cuyo **nombre** está en
    `MapInfo.KindByModel`.
  - `CasaCosme` no está ahí, así que no hay `Configuration` en `ReplicatedStorage.MapLandmarks` y
    `Controllers/MapUI` no pinta nada.

**Conclusión:** la casa existe; lo que falta es el marcador en el mapa.

---

## Arreglos recomendados (para la otra sesión)

1. **Mapa – Cosme** (fácil):
   - En `shared/MapInfo.luau`, añadir a `MapInfo.Kinds`:
     `{ Model = "CasaCosme", Icon = "🔭", Name = "Casa de Cosme", Important = true }`.
   - En `shared/MapLegend.luau`, meter `"CasaCosme"` en una categoría, por ejemplo `Ciudad`. O crear una
     categoría «Historia» con `Icon = "🔭"`.
   - `WorldService.publishLandmarks` ya lo recoge por el nombre del modelo, sin tocar nada más.
   - Comprobarlo con una prueba de `MapLegend` (que todo tipo de `MapInfo` tenga categoría).
2. **Gráficos en el móvil – «todo se ve igual»:**
   - Que «Bajo» **no esconda** las mallas de `CityAssets` pequeñas y baratas (hidrantes, buzones,
     jardineras, conos, palés…). Hoy salen con `Detail`/`Mesh` y se esconden todas.
   - Dejar `CityDetail`/`BuildingMesh` solo para lo pesado (Skyline, edificios 3D).
   - Que el «Auto» del móvil no baje a «Bajo» tan pronto: por ejemplo, `DownSeconds` más largo, o un
     suelo de «Medio» si el móvil aguanta más de 20 fps.
   - Que el menú «✨ Gráficos» diga claramente en qué nivel está, para que el dueño pueda forzar «Alto»
     al probar.
   - Pedir al dueño que, en la v siguiente, mire el nivel en el menú y pruebe con «Alto».
3. **Cargas que fallan cuando se pide todo a la vez:**
   - Poner **reintentos** en la descarga: 2–3 intentos con espera de 2, 4 y 8 s, también cuando el error
     es «not authorized». Mejor en un único cargador compartido (`AssetLoader.download`).
   - Que todos los módulos lo usen: `NatureAssets`, `UserMaterials`, `SkyAssets`, `CarBodies`,
     `Buildings3D` y `WorkshopProps` tienen cada uno su propio `download` sin reintento.
   - Opcional: una **cola** con pocas descargas a la vez (4–6) en lugar de ~10 módulos pidiendo a la vez.
4. **Grieta:**
   - Que se vea sin buscarla. Por ejemplo, en «Crece» o más, la primera vez que se hace de noche, que la
     cámara (o una flecha o un aviso «¡Mira al cielo, al norte!») la señale.
   - O que su dirección siga al jugador: elegir el lado del cielo donde mira la cámara al empezar la fase
     y dejarlo fijo después.
   - Comprobar con `/debug` el atributo `SkyRift` del jugador del dueño. Si dice «Sueno», el prólogo no se
     cerró: es un fallo de la historia, no de la grieta.
5. **Ids que no cargan nunca** (quitarlos o cambiarlos por otros):
   - 101748452 (PistolaDorada): «not authorized» con los dos métodos.
   - Los dos de `UserArsenal` que cargan pero dan 0 mallas: 117850698505269 y 546753609.
6. **Comprobar en un servidor en vivo:** que el dueño abra la consola del servidor (F9 → Server, o
   `/debug`) y busque estas líneas, que dicen si `Main.server.luau` llegó a arrancar cada módulo en vivo:
   - `[CityAssets] colocado (… piezas)`
   - `[NatureAssets] Plantillas: …`
   - `[CarBodies] 15 carrocerías`
   - `[UserMaterials] 8/9 packs`
