# Assets elegidos por Sebastián (2ª tanda): qué hay dentro

Igual que en `docs/assets-usuario.md`: volcado hecho en un servidor de Roblox con
`AssetService:LoadAssetAsync(id)` (con `pcall`).
Script: `scripts/cloud/assets-usuario-2.luau` → `bash scripts/cloud-test.sh -v assets-usuario-2`.
Datos públicos de cada asset: `https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=…`.
Fecha: 2026-10-01.

Notas generales:

- Los 7 ids **cargan** con `LoadAssetAsync`. Todos llegan dentro de un `Model` raíz llamado `Model`.
- Todos son **gratis** (precio 0 USD) y de creadores con insignia de verificado.
- **Triángulos por malla**: no se pueden leer desde el servidor. `AssetService:CreateEditableMeshAsync`
  responde «no permission to load asset» con mallas de otros creadores. Los triángulos que salen aquí son
  los del toolbox (el total del asset). El toolbox tampoco da triángulos de una malla suelta (404).
- Las texturas de `SurfaceAppearance` y `MaterialVariant` (ColorMap…) no se pueden leer desde el servidor.
- El `Source` de los scripts sí se puede leer. Se ha buscado en todos: `require(número)`, `getfenv`,
  `setfenv`, `loadstring`, `HttpService`, `MarketplaceService`, `TeleportService`, `InsertService`,
  `LoadAsset`, `string.char`/`string.reverse`, `Kick`, `PlayerAdded`, `RemoteEvent`. **Ninguna puerta
  trasera**: solo hay `require` de módulos del propio pack (SmartBone).
- ⚠ = script: hay que borrarlo o revisarlo al usar el asset.

## Resumen

| id | Qué es | ¿Carga? | Piezas / tris (toolbox) | Scripts | Valoración |
|---|---|---|---|---|---|
| 13395313510 | «склад» (almacén): 5 estanterías iguales | ✅ | 680 Part (+520 Weld) / 8 160 tris | 0 | **útil** — estanterías de almacén de 10×27,8×100,8 studs, solo Parts. Muchas piezas: mejor usar 1–2 estanterías, no las 5. |
| 15666503758 | «Whiskas»: bolsa de comida de gato (Tool) | ✅ | 1 Part con SpecialMesh / 696 tris | 0 | **útil con cuidado** — el logo de Whiskas (marca real) va pintado en la única textura (`TextureId` del SpecialMesh, una foto de 2011). No se puede separar: hay que cambiar esa textura por una nuestra sin marca. |
| 12433695725 | Texture pack (realistic): muestrario de texturas | ✅ | 241 Part + 1 MeshPart, 1 433 `Texture` / 8 658 tris | 0 | **útil con cuidado** — son `Texture` antiguas (no PBR, no MaterialVariant), pegadas cara a cara. Sirve para copiar ids de textura (techo, cristal, suelo, pared…); no para meter el muestrario en el mapa. |
| 12527638598 | Roads: carreteras con líneas pintadas | ✅ | 560 Part / 6 720 tris | 0 | **útil** — recta, aparcamientos, adelantamiento y una rotonda de 94×94; todo planos de 0,1 de alto. Revisar escala (carril de ~13 studs). |
| 7105428424 | «Dead guy»: cadáver tumbado | ✅ | 14 Part / 1 498 tris | 0 | **no usar** — 11 Decals de sangre (`Blood`, `blood`), 2 de cicatriz (`Scar`) y cara de muerto; charco de sangre de 6,7×6,5 en el suelo. La sangre realista obliga a una clasificación de contenido «Moderate» (13+) en Roblox. |
| 96924659951632 | Realistic Trees Pack [MOVING]: 4 árboles que se mueven con el viento | ✅ | 17 piezas (8 MeshPart con SurfaceAppearance) / 46 654 tris | ⚠ 14 Script/LocalScript + 9 ModuleScript | **útil con cuidado** — árboles bonitos y PBR, pero cada uno trae un `Script` con `while wait()` en el servidor y sonidos en bucle; SmartBone corre en el cliente. Usar las mallas y quitar los scripts, o meter SmartBone a propósito. |
| 99479110531330 | Realistic city pack («PBR Copiclation»): ciudad entera | ✅ | 1 619 piezas (1 561 MeshPart, 1 273 SurfaceAppearance), 108 MaterialVariant / el toolbox no da tris | ⚠ 20 Script | **útil con cuidado** — muchísimo material bueno (carreteras, aceras, semáforos, edificios, árboles, rocas, 108 materiales). Pero es una recopilación: hay mallas sacadas de otros juegos (`bms_…` = Black Mesa, `c1a2c_…` = Half-Life) y de Quixel Megascans (`…_LOD3_Aset_…`), y una máquina `OnlyFantasVendingMachine` (parodia de una web para adultos). Coger piezas una a una, no el pack entero. |

### Datos del toolbox

| id | Nombre | Creador | Votos 👍/👎 | Tris | Vértices | MeshParts | Scripts | Decals | Audios | Precio | Creado |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 13395313510 | склад | RobloxHouse30008 ✔ | 0 / 0 | 8 160 | 16 320 | 0 | 0 | 0 | 0 | gratis | 2023-05-09 |
| 15666503758 | Whiskas | RobloxHouse30008 ✔ | 8 / 2 | 696 | 168 | 0 | 0 (1 Tool) | 0 | 0 | gratis | 2023-12-17 |
| 12433695725 | Texture pack (realistic) | Richo_boiii ✔ | 95 / 5 | 8 658 | 14 880 | 1 | 0 | 0 | 0 | gratis | 2023-02-09 |
| 12527638598 | Roads | Richo_boiii ✔ | 0 / 0 | 6 720 | 13 440 | 0 | 0 | 0 | 0 | gratis | 2023-02-18 |
| 7105428424 | \*Dead guy\* | Richo_boiii ✔ | 0 / 0 | 1 498 | 1 021 | 0 | 0 | 16 | 18 | gratis | 2021-07-16 |
| 96924659951632 | Realistic Trees Pack [MOVING] | Stridity_1234 ✔ | 38 / 2 | 46 654 | 53 899 | 8 | 14 | 1 | 7 | gratis | 2025-09-01 |
| 99479110531330 | Realistic city pack | Slowgamer1233 ✔ | 40 / 0 | (no lo da) | (no lo da) | (no lo da) | — | — | — | gratis | 2025-05-25 |

(✔ = creador verificado. El toolbox cuenta como «scripts» solo Script y LocalScript, no los ModuleScript.)

## 13395313510 — «склад» (estanterías de almacén)

Carga: ✅. Clases: `Model` 26, `Part` 680, `Weld` 520. Sin MeshPart, SurfaceAppearance, Texture ni scripts.

```
Model [Model]                       112.6 x 27.8 x 100.8
└─ склад [Model]                    112.6 x 27.8 x 100.8   680 piezas
   ├─ Model [Model] ×5              10.0 x 27.8 x 100.8    136 piezas cada una
```

- Son 5 estanterías iguales (`Model`), cada una de 136 Parts unidas con Weld.
- 27,8 studs de alto (≈ 7,8 m con 1 stud = 0,28 m): estantería industrial de almacén alta.
- Para el juego: copiar 1 estantería y anclarla; los Weld sobran si se ancla todo.

## 15666503758 — «Whiskas» (comida de gato)

Carga: ✅. Clases: `Tool` 1, `Part` 1, `SpecialMesh` 1, `Accessory` 1.

```
Model [Model]
└─ Whiskas [Tool]                      1.1 x 1.7 x 0.9
   └─ Handle [Part]                    1.1 x 1.7 x 0.9
      ├─ Mesh [SpecialMesh]  MeshId=19106014  TextureId=52081598  Scale=1.06,1.06,0.93
      └─ Accessory [Accessory]  (vacío; sobra)
```

- **Logo**: no hay Decal, Texture ni SurfaceAppearance. El dibujo entero (con la marca Whiskas) es la
  textura `52081598` del SpecialMesh: una imagen subida en 2011 («RobloxScreenShot05182011_195001218»,
  de Gedda206). **No se puede separar el logo**: o se deja la textura entera o se cambia.
- La malla `19106014` es «Coal for brains» (un sombrero de Roblox de 2009) usada como bolsa.
- Para el juego: cambiar `TextureId` por una textura nuestra («Comida de gato» sin marca) o usar otra
  malla. No usar la textura original: es una marca real sin permiso.
- Es una `Tool`: se puede coger con la mano. El `Accessory` vacío dentro del Handle sobra.

## 12433695725 — Texture pack (realistic)

Carga: ✅. Clases: `Model` 1, `Part` 241, `MeshPart` 1, `Texture` 1 433. Sin MaterialVariant ni scripts.

```
Model [Model]                                70.1 x 86.9 x 11.0
└─ Texture pack (realistic) [Model]          242 piezas, 1 433 Texture
   ├─ Ceiling A…L [Part] ×12   4 x 4 x 1     6 Texture cada una (una por cara)
   ├─ Floor A…L   [Part] ×12   4 x 4 x 1
   ├─ Glass A…L   [Part] ×12   4 x 4 x 1
   ├─ Roof A…L    [Part] ×12   4 x 4 x 1
   ├─ Terrain A…L [Part] ×12   4 x 4 x 1
   ├─ Wall A…L    [Part] ×12   4 x 10 x 1
   ├─ Texture     [Part] ×168  4 x 1 x 2     (muestras pequeñas)
   └─ Big [MeshPart]           0.3 x 0.1 x 0.3  MeshId=5727187033
```

- Es un **muestrario**: cada Part lleva la misma imagen en sus 6 caras con `Texture` (el sistema
  antiguo, sin relieve ni PBR). No hay MaterialVariant.
- Las imágenes son ids de muchos creadores distintos (p. ej. `2875933`, `6738995`, `92574443`, `7480438284`).
- Para el juego: mejor los MaterialVariant de la 1ª tanda o de la ciudad. Si gusta una textura concreta,
  copiar su id a una `Texture` nuestra.

## 12527638598 — Roads

Carga: ✅. Clases: `Model` 68, `Part` 560. Sin scripts ni texturas: las líneas son Parts finas.

```
Model [Model]                                    202.1 x 0.2 x 293.7
└─ Model [Model]                                 560 piezas
   ├─ Part ×~20                 0.7 x 0.1 x 12.9 / 23.6 / 13.1 x 0.1 x 35.9   (líneas y asfalto sueltos)
   ├─ Straight overtake [Model] ×5              13.1 x 0.1 x 35.9   (1 pieza) / 31.7 x 0.1 x 28.2 (7)
   ├─ Straight [Model]                          31.7 x 0.1 x 29.6   5 piezas
   ├─ Yellow Straight [Model]                   31.7 x 0.1 x 29.6   5 piezas
   ├─ Yellow Straight overtake [Model]          31.7 x 0.1 x 28.2   7 piezas
   ├─ Straight Parking [Model]                  45.7 x 0.1 x 139.7  73 piezas
   ├─ Yellow Straight Parking [Model]           45.7 x 0.1 x 139.7  73 piezas
   ├─ Straight Overtake Parking [Model]         45.7 x 0.1 x 139.7  85 piezas
   ├─ Yellow Straight Overtake Parking [Model]  45.7 x 0.1 x 139.7  85 piezas
   └─ Roundabout [Model]                        94.0 x 0.1 x 94.4   196 piezas
```

- Todo plano (0,1–0,2 de alto). Las «Yellow» llevan líneas amarillas.
- La rotonda tiene 196 piezas: si se usa, unirlas o simplificar.

## 7105428424 — «Dead guy» ⛔

Carga: ✅. Clases: `Part` 14, `Decal` 16, `Sound` 18, `Humanoid`, `Shirt`, `BodyColors`, `Glue` 4, `Weld` 5…
Sin scripts (los 18 Sound son los sonidos por defecto del Humanoid: saltar, caer, nadar…).

```
Model [Model]
└─ *Dead guy* [Model]                    7.0 x 6.9 x 1.1   (personaje R6 tumbado)
   ├─ Head (Decal «Dead face» 1078549100, 18 Sound), Torso, brazos, piernas
   ├─ Part 6.7 x 0.1 x 6.5   ← charco: 8 Decal «Blood»/«blood»/«Scar»
   ├─ Part 2.0 x 0.1 x 1.9   ← 1 Decal
   └─ 5 Part 1 x 1 x 1 (4 con Decals «Blood», 6 en total)
```

Decals: `Blood` (469953941, 3081197662, 303980911), `blood` (1927066320), `Scar` (631849221),
`Decal` (247766282), `Dead face` (1078549100).

- **Sí tiene sangre**: charco de sangre y manchas por el cuerpo, más cara de muerto.
- Según las normas de Roblox, la sangre realista exige la clasificación de contenido «Moderate» (13+).
  Para un juego de vida para todos los públicos no vale. **No usar.** (Si hace falta un herido, mejor un muñeco
  tumbado sin sangre en un hospital.)

## 96924659951632 — Realistic Trees Pack [MOVING]

Carga: ✅. Clases: `MeshPart` 8, `SurfaceAppearance` 8, `Part` 9, `Bone` 34, `Motor6D` 8, `Sound` 7,
`Script` 12, `LocalScript` 2, `ModuleScript` 9, `ParticleEmitter` 3, `PointLight` 1, `Decal` 1…

```
Model [Model]                                 39.6 x 33.5 x 47.7
└─ Realistic Trees Pack [Folder]
   ├─ Trees [Folder]
   │  ├─ OakTree    [Model]  23.9 x 33.5 x 23.6   4 piezas (2 MeshPart + SA), 2 Sound, ⚠ 3 Script
   │  ├─ CherryTree [Model]  17.5 x 20.6 x 17.4   4 piezas (2 MeshPart + SA), 2 Sound, ⚠ 3 Script
   │  ├─ PineTree   [Model]  13.3 x 27.7 x 15.1   4 piezas (2 MeshPart + SA), 1 Sound, ⚠ 2 Script
   │  └─ OldTree    [Model]  17.8 x 23.1 x 21.4   4 piezas (2 MeshPart + SA), 2 Sound, ⚠ 3 Script
   ├─ DELETE ME [Part] 3.4 x 3.4 x 0.2  (Decal 124033376071692: cartel del autor; borrar)
   ├─ ⚠ READ ME [Script, desactivado]
   ├─ ⚠ SmartBoneRuntime [LocalScript]
   └─ ⚠ SmartBone [ModuleScript] + 8 módulos
```

Cada árbol tiene 2 MeshPart con SurfaceAppearance (y huesos `Bone` para moverse):

| Árbol | Malla | Talla | MeshId | Tris |
|---|---|---|---|---|
| OakTree | leaves | 23.9 x 18.7 x 23.6 | 108486354680348 | ? |
| OakTree | tree | 20.7 x 23.4 x 19.8 | 139127650559409 | ? |
| CherryTree | leaves | 17.5 x 13.4 x 17.4 | 73643469907589 | ? |
| CherryTree | tree | 14.3 x 16.8 x 14.0 | 137183436299234 | ? |
| PineTree | leaves | 13.3 x 21.4 x 15.1 | 137715546691530 | ? |
| PineTree | tree | 10.6 x 25.5 x 12.1 | 122774569559257 | ? |
| OldTree | leaves | 17.8 x 13.4 x 21.4 | 79468290899137 | ? |
| OldTree | tree | 13.0 x 20.1 x 16.2 | 83480080793608 | ? |

Tris por malla: no se pueden leer (ver notas generales). Total del pack según el toolbox: **46 654 tris**
→ unos **11 700 por árbol** de media. Es bastante: no plantar cientos.

Los 14 scripts que cuenta el toolbox (12 Script + 2 LocalScript) más los 9 ModuleScript:

| # | Script | Clase | Dónde corre | Qué hace |
|---|---|---|---|---|
| 1–4 | `Trees/<árbol>/tree/Creak/RandomSoundPlayer` (×4) | Script | servidor | Bucle infinito: cada 3–10 s, 3 de cada 4 veces, toca el crujido del tronco con volumen y velocidad al azar. |
| 5–7 | `Trees/<árbol>/leaves/Attachment/Wind/RandomSoundPlayer` (×3: Oak, Cherry, Old) | Script | servidor | Igual, con el sonido de viento en las hojas. |
| 8–11 | `Trees/<árbol>/MainPart/ModifyCustomAttributes` (×4) | Script | servidor | `while wait() do` (cada frame, para siempre): copia `workspace.GlobalWind` a 3 atributos del árbol. Caro con muchos árboles. |
| 12 | `READ ME` | Script (desactivado) | — | Solo instrucciones: poner `workspace.GlobalWind` ≥ (3,0,3), `Trees` en Workspace, `SmartBoneRuntime` en ReplicatedFirst y `SmartBone` en ReplicatedStorage. |
| 13 | `SmartBoneRuntime` | LocalScript | cliente | `require(ReplicatedStorage.SmartBone).Start()`. |
| 14 | `SmartBone/Dependencies/ActorScript` | LocalScript (desactivado; se clona en Actors) | cliente | Simula los huesos en paralelo. |
| — | `SmartBone` (18 576 caracteres) + `UnitConversion`, `Utilities`, `DefaultSettings`, `CameraUtil`, `Config`, `SettingsMath`, `Particle`, `ParticleTree` | ModuleScript | cliente | SmartBone 0.1.2 (de Celnak): física de huesos para que se muevan ramas y hojas. Sin red ni `require` de ids. |

Sonidos: `Wind` 9116258071 (×3), `Creak` 9120262025 / 9120261928 (×4), todos en bucle.

Recomendación: para árboles quietos, quitar los 3 scripts de cada árbol y los sonidos; para árboles
que se muevan, usar SmartBone en el cliente pero cambiar `ModifyCustomAttributes` por algo que lo haga
una sola vez (o al cambiar el viento), nunca con `while wait()`.

## 99479110531330 — Realistic city pack («PBR Copiclation»)

Carga: ✅. Talla total 737.7 x 171.1 x 1600.8 (las piezas están repartidas, no montadas como ciudad).
Clases: `MeshPart` 1 561, `SurfaceAppearance` 1 273, `Model` 301, `Part` 57, `UnionOperation` 1,
`MaterialVariant` 108, `Folder` 41, `CFrameValue` 135, `Bone` 39, `SurfaceGui` 23, `TextLabel` 46,
`SurfaceLight` 14, `SpotLight` 4, `BindableEvent` 12, `AnimationController` 7, `Script` 20, `Sound` 2,
`Decal` 4, `Texture` 1, `ProximityPrompt` 1.

```
Model [Model]
└─ PBR Copiclation [Folder]
   ├─ ---Props---      [Folder]  628 piezas (614 MeshPart, 525 SA), 2 Sound, ⚠ 1 Script
   ├─ ---Natural---    [Folder]  619 piezas (615 MeshPart, 577 SA), 1 Texture, ⚠ 7 Script
   ├─ ---Building---   [Folder]   44 piezas (44 MeshPart, sin SA)
   ├─ ---City props--- [Folder]  328 piezas (288 MeshPart, 171 SA), 4 Decal, ⚠ 12 Script
   └─ ---textures---   [Folder]  108 MaterialVariant (Indoor / Outdoor / Building / Other)
```

Ojo con el origen (no es un problema técnico, sí de derechos):

- `bms_metalcrate…`, `bms_vent…`: mallas de **Black Mesa**. `c1a2c_foodcrate…`: de **Half-Life**.
- `…_LOD3_Aset_…`, `Aset_rock_granite_…`, `3DRock004_16K`: mallas de **Quixel Megascans** / ambientCG.
- `Coke` (lata, ×2, sin SurfaceAppearance): el nombre apunta a Coca-Cola (marca real); mirar en Studio si lleva logo antes de usarla.
- `OnlyFantasVendingMachine`: máquina expendedora con nombre de parodia de una web para adultos. **No usar.**
- `City props` (carreteras `Road_…_01_A`, aceras `Sidewalk_…`, semáforos, `Manhole_Roblox_01_A`,
  `Bus_Stop_01_A`…) parecen del pack de ciudad gratuito de Roblox: lo más seguro de usar.

### Scripts (20, todos ⚠)

| Script | Cuántos | Qué hace |
|---|---|---|
| `City props/…/Traffic_Light_01(02)/LightStateChanger` | 12 (2 sueltos + 10 dentro de cruces) | Ciclo verde → amarillo → rojo con atributo `interval` (30 s por defecto) y `BindableEvent` `LightChanged`. Limpio. |
| `Props/Proximity Door/Script` | 1 | Puerta con ProximityPrompt: abre/cierra con Tween y sonido 212709232. Limpio. |
| `Natural/Tree/Redwood_Trees_Snowy01_Leaf/Moving Leaves` | 1 | `while true … wait()` moviendo el CFrame de las hojas en el servidor cada frame. Quitar. |
| `Natural/Butterfly_Idle01`, `Butterfly_FlightPath01/02`, `Dragonfly_Flight01`, `Dragonfly_IdleFlight01/02` → `Script` | 6 | Cargan y reproducen una animación (p. ej. 6409149474) en bucle. Limpios. |

Ninguno usa red, `require` de ids, `loadstring`, `getfenv` ni toca jugadores.

Textos (`TextLabel`): solo «WALK» / «DON'T WALK» de los semáforos. Decals: 4 manchas de suelo
`StreetWear_01…04` (5324968916, 5324990492, 5324937432).

### Todo lo que trae (agrupado por nombre)

Objetos de primer nivel dentro de cada carpeta (un `Model` o una pieza suelta). «Cuántos» = copias con
el mismo nombre (se quita el número final); si las tallas cambian se da la menor … la mayor.
SA = nº de SurfaceAppearance. 780 objetos en total. Los `MeshPart`/`Model` llamados `MeshPart`,
`meshPart`, `Model` no tienen nombre útil (119 + 45 + 29 en Props; 46 + 15 en Natural).

#### Props

| Objeto | Clase | Cuántos | Talla (studs) | Piezas | SA | Notas |
|---|---|---|---|---|---|---|
| `Gascan` | MeshPart | 1 | 0.5x1.7x1.3 | 1 | 1 |  |
| `acunit` | MeshPart | 2 | 6.7x11.9x9.0 … 6.6x11.9x11.9 | 2 | 0 |  |
| `MeshPart` | MeshPart | 119 | 1.5x0.0x1.1 … 7.2x9.1x19.9 | 119 | 114 |  |
| `model_Plane` | MeshPart | 1 | 2.1x3.3x2.5 | 1 | 1 |  |
| `Telephone Poles Fixed_polySurface` | MeshPart | 2 | 2.8x4.0x2.3 … 9.4x38.6x1.9 | 2 | 2 |  |
| `MeleePipe` | MeshPart | 1 | 1.1x3.6x0.5 | 1 | 1 |  |
| `bms_metalcrate_64x` | MeshPart | 1 | 5.9x9.0x5.9 | 1 | 0 |  |
| `Model` | Model | 29 | 1.2x1.2x0.6 … 11.9x3.0x6.7 | 147 | 122 |  |
| `Bus` | Model | 1 | 43.0x12.4x10.8 | 16 | 16 |  |
| `meshPart` | MeshPart | 45 | 2.2x0.5x0.8 … 15.1x5.3x13.3 | 45 | 45 |  |
| `wcckeezdw_LOD3_Aset_industrial_mining_L_wcckeezdw_01_LOD` | MeshPart | 2 | 13.6x5.1x3.9 … 27.1x20.9x28.3 | 2 | 2 |  |
| `wcckeezdw_LOD3_Aset_industrial_mining_L_wcckeezdw_00_LOD` | MeshPart | 1 | 24.8x20.9x33.6 | 1 | 1 |  |
| `OnlyFantasVendingMachine` | Model | 1 | 4.1x7.5x3.6 | 15 | 1 |  |
| `c1a2c_foodcrate` | Model | 3 | 4.2x2.6x4.2 … 4.2x4.6x4.2 | 16 | 0 |  |
| `Plate` | Model | 2 | 1.4x0.1x1.4 | 2 | 0 |  |
| `Bowl` | Model | 2 | 1.0x0.3x1.0 | 2 | 0 |  |
| `Coffee_Cup_Print` | Model | 2 | 0.3x0.3x0.4 | 2 | 2 |  |
| `Glass_Empty` | Model | 2 | 0.4x0.6x0.4 | 2 | 0 |  |
| `Egg` | MeshPart | 1 | 0.8x0.1x0.8 | 1 | 1 |  |
| `Bread` | MeshPart | 3 | 1.0x0.1x0.9 … 0.7x0.6x0.4 | 3 | 3 |  |
| `Egg Sandwich` | MeshPart | 2 | 1.4x0.4x1.2 | 2 | 0 |  |
| `Red Apple` | MeshPart | 2 | 0.5x0.4x0.4 | 2 | 2 |  |
| `pancake` | Model | 2 | 1.8x0.9x1.9 | 10 | 10 |  |
| `Pizza` | Model | 2 | 0.8x1.0x0.2 | 2 | 2 |  |
| `braed` | MeshPart | 2 | 1.1x0.7x1.1 | 2 | 2 |  |
| `Donut` | Model | 2 | 0.9x1.0x0.3 | 2 | 2 |  |
| `Coke` | MeshPart | 2 | 0.7x1.3x0.7 | 2 | 0 |  |
| `wdpnchtdw_LOD` | MeshPart | 12 | 0.8x6.2x0.6 … 41.2x31.0x50.0 | 12 | 12 |  |
| `vimrdhl_LOD` | MeshPart | 12 | 3.5x0.2x2.6 … 5.8x8.4x7.3 | 12 | 12 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_02_LOD` | MeshPart | 2 | 3.5x1.2x2.6 | 2 | 2 |  |
| `tkwmdexva_LOD3_Aset_paper_cardboard_S_tkwmdexva_03_LOD` | MeshPart | 2 | 2.3x1.0x1.6 | 2 | 2 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_00_LOD` | MeshPart | 1 | 1.3x2.3x0.7 | 1 | 1 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_01_LOD` | MeshPart | 1 | 2.0x2.6x0.9 | 1 | 1 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_02_LOD` | MeshPart | 1 | 1.1x2.6x0.7 | 1 | 1 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_03_LOD` | MeshPart | 1 | 1.4x2.9x0.7 | 1 | 1 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_04_LOD` | MeshPart | 1 | 1.7x2.6x1.3 | 1 | 1 |  |
| `tlzkdilva_LOD3_Aset_plastic__S_tlzkdilva_05_LOD` | MeshPart | 1 | 1.8x2.6x0.9 | 1 | 1 |  |
| `ubjhdfgva_LOD3_Aset_metal_rusty_S_ubjhdfgva_00_LOD` | MeshPart | 1 | 5.6x1.9x3.5 | 1 | 1 |  |
| `ubjhdfgva_LOD3_Aset_metal_rusty_S_ubjhdfgva_01_LOD` | MeshPart | 1 | 3.3x1.6x2.6 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_00_LOD` | MeshPart | 1 | 5.0x3.0x4.1 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_01_LOD` | MeshPart | 1 | 5.4x5.5x5.4 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_02_LOD` | MeshPart | 1 | 4.9x1.3x3.1 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_03_LOD` | MeshPart | 1 | 3.7x2.6x3.6 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_04_LOD` | MeshPart | 1 | 2.4x2.4x2.3 | 1 | 1 |  |
| `uewlfg2va_LOD3_Aset_container_box_S_uewlfg2va_05_LOD` | MeshPart | 1 | 3.4x2.5x2.8 | 1 | 1 |  |
| `vkgrchzga_LOD3_Aset_props_storage_M_vkgrchzga_01_LOD` | MeshPart | 1 | 4.9x0.6x2.7 | 1 | 1 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_06_LOD` | MeshPart | 1 | 2.8x1.1x1.2 | 1 | 1 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_05_LOD` | MeshPart | 1 | 1.3x1.0x1.2 | 1 | 1 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_04_LOD` | MeshPart | 1 | 3.5x2.6x4.9 | 1 | 1 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_03_LOD` | MeshPart | 1 | 3.7x2.8x5.2 | 1 | 1 |  |
| `tlbjdbova_LOD3_Aset_paper_cardboard_S_tlbjdbova_01_LOD` | MeshPart | 1 | 2.9x0.5x1.8 | 1 | 1 |  |
| `tkwmdexva_LOD3_Aset_paper_cardboard_S_tkwmdexva_04_LOD` | MeshPart | 1 | 3.7x2.0x2.3 | 1 | 1 |  |
| `tkwmdexva_LOD3_Aset_paper_cardboard_S_tkwmdexva_01_LOD` | MeshPart | 8 | 3.2x1.9x2.3 … 7.3x16.1x7.4 | 8 | 8 |  |
| `tkwmdexva_LOD3_Aset_paper_cardboard_S_tkwmdexva_00_LOD` | MeshPart | 1 | 3.1x1.6x2.0 | 1 | 1 |  |
| `ubjhdfgva_LOD3_Aset_metal_rusty_S_ubjhdfgva_04_LOD` | MeshPart | 1 | 2.3x4.1x2.3 | 1 | 1 |  |
| `ubjhdfgva_LOD3_Aset_metal_rusty_S_ubjhdfgva_02_LOD` | MeshPart | 1 | 4.8x2.1x5.2 | 1 | 1 |  |
| `vkgrchzga_LOD3_Aset_props_storage_M_vkgrchzga_00_LOD` | MeshPart | 1 | 4.9x2.9x2.8 | 1 | 1 |  |
| `ud4nfhofa_LOD2_Aset_container_box_S_ud4nfhofa_01_LOD` | MeshPart | 1 | 7.2x3.0x5.7 | 1 | 1 |  |
| `ud4oai0fa_LOD2` | MeshPart | 1 | 4.8x2.0x4.1 | 1 | 1 |  |
| `udqjbg1qx_LOD` | MeshPart | 5 | 1.2x2.2x0.7 … 4.9x5.0x5.1 | 5 | 5 |  |
| `GasTank` | MeshPart | 1 | 1.6x2.5x1.6 | 1 | 1 |  |
| `Cash Register` | Model | 1 | 3.1x3.2x2.6 | 2 | 2 |  |
| `Proximity Door` | Model | 1 | 3.7x7.6x3.5 | 4 | 2 | ⚠ 1 scripts, 2 Sound |
| `Aset_industrial_storage_M_vizqehw_LOD` | MeshPart | 1 | 1.2x1.8x1.2 | 1 | 1 |  |
| `BaseballBat` | MeshPart | 1 | 0.3x3.5x0.3 | 1 | 1 |  |
| `barrier` | MeshPart | 1 | 5.7x2.4x1.6 | 1 | 1 |  |
| `PipeWrench` | MeshPart | 1 | 0.5x2.5x0.2 | 1 | 1 |  |
| `Crowbar` | MeshPart | 1 | 0.2x3.5x1.0 | 1 | 1 |  |
| `SledgeHammer` | MeshPart | 1 | 0.4x3.9x1.0 | 1 | 1 |  |
| `CementBarrier` | MeshPart | 1 | 4.9x2.3x1.3 | 1 | 1 |  |
| `Hammer` | MeshPart | 1 | 0.8x1.8x0.2 | 1 | 1 |  |
| `Barrel` | MeshPart | 1 | 2.9x4.6x2.9 | 1 | 1 |  |
| `Doors_Windows_SetUp_Bollard_low` | MeshPart | 2 | 1.2x4.9x1.2 | 2 | 2 |  |
| `bms_vent_break` | MeshPart | 1 | 0.4x3.5x3.5 | 1 | 0 |  |
| `bms_vent` | MeshPart | 1 | 0.3x3.5x3.5 | 1 | 0 |  |
| `Doors_Windows_SetUp_DoorSection_Bottom_low` | MeshPart | 1 | 28.8x2.7x0.2 | 1 | 1 |  |
| `Doors_Windows_SetUp_DoorSection_Plain_low` | MeshPart | 7 | 28.8x2.6x0.2 | 7 | 7 |  |
| `Doors_Windows_SetUp_DoorSection_Windowed_low` | MeshPart | 2 | 28.8x2.6x0.3 | 2 | 2 |  |
| `Doors_Windows_SetUp_Door_low` | MeshPart | 1 | 3.9x6.7x0.5 | 1 | 1 |  |
| `Doors_Windows_SetUp_GarageDoorFrame_low` | MeshPart | 1 | 30.4x26.1x0.7 | 1 | 1 |  |
| `Doors_Windows_SetUp_WindowBars_low` | MeshPart | 1 | 5.4x3.5x0.1 | 1 | 1 |  |
| `Doors_Windows_SetUp_Window_low` | MeshPart | 2 | 5.5x4.2x0.3 | 2 | 2 |  |
| `Barrier` | MeshPart | 1 | 18.0x17.5x3.1 | 1 | 1 |  |
| `Security Camera` | Model | 1 | 1.2x2.4x3.7 | 4 | 4 |  |
| `model_Plane.` | MeshPart | 2 | 2.4x2.6x2.4 … 3.1x2.9x2.1 | 2 | 2 |  |
| `model_BezierCircle` | MeshPart | 1 | 2.9x3.7x2.9 | 1 | 1 |  |
| `model_Cylinder` | MeshPart | 1 | 3.3x3.6x3.3 | 1 | 1 |  |
| `ModularPipeLong` | MeshPart | 1 | 0.5x2.4x0.5 | 1 | 1 |  |
| `ModularPipeValve` | MeshPart | 1 | 0.6x0.9x0.8 | 1 | 1 |  |
| `ModularPipeShort` | MeshPart | 1 | 0.5x1.1x0.5 | 1 | 1 |  |
| `ModularPipeCross` | MeshPart | 1 | 0.9x0.9x0.5 | 1 | 1 |  |
| `ModularPipeT` | MeshPart | 1 | 0.7x0.9x0.5 | 1 | 1 |  |
| `ModularPipeElbow` | MeshPart | 1 | 1.1x1.2x0.5 | 1 | 1 |  |
| `Low_Case` | MeshPart | 3 | 12.2x3.4x3.4 | 3 | 3 |  |
| `bms_metalcrate_tarp` | Model | 1 | 5.0x9.7x4.8 | 2 | 0 |  |
| `tarp_crate` | Model | 1 | 4.8x9.5x5.0 | 2 | 0 |  |
| `bms_metalcrate_48x` | MeshPart | 1 | 4.4x4.3x4.4 | 1 | 0 |  |
| `Train Cart` | Model | 1 | 42.2x12.4x9.6 | 14 | 13 |  |
| `Telephone Poles Fixed_pSphere` | MeshPart | 1 | 19.0x1.6x1.1 | 1 | 1 |  |
| `Telephone Poles Fixed_pSphere17.` | MeshPart | 1 | 19.0x1.6x1.1 | 1 | 1 |  |
| `Telephone Poles Fixed_polySurface105.` | MeshPart | 1 | 20.0x49.0x1.8 | 1 | 1 |  |
| `Telephone Poles Fixed_polySurface107.` | MeshPart | 1 | 9.4x38.6x0.8 | 1 | 1 |  |
| `Telephone Poles Fixed_pCylinder36.` | MeshPart | 1 | 1.3x0.3x1.9 | 1 | 1 |  |
| `Telephone Poles Fixed_pCylinder60.001` | MeshPart | 1 | 1.3x0.3x1.9 | 1 | 1 |  |
| `Telephone Poles Fixed_pCylinder59` | MeshPart | 1 | 28.9x2.1x0.3 | 1 | 1 |  |
| `Telephone Poles Fixed_pCylinder` | MeshPart | 2 | 17.8x5.8x3.2 … 20.0x49.0x1.8 | 2 | 2 |  |
| `calculator` | MeshPart | 1 | 0.4x0.1x0.8 | 1 | 0 |  |
| `file_box_lid` | MeshPart | 1 | 1.1x0.2x1.5 | 1 | 0 |  |
| `file_box_bottom` | MeshPart | 1 | 1.1x0.8x1.5 | 1 | 0 |  |
| `paper_box` | MeshPart | 1 | 0.8x1.1x0.9 | 1 | 0 |  |
| `books` | Model | 3 | 1.0x0.8x1.1 … 0.8x1.2x2.7 | 10 | 0 |  |
| `WF_Material_Plane.` | MeshPart | 1 | 16.7x0.0x16.7 | 1 | 1 |  |
| `folder` | Model | 1 | 0.1x0.9x1.1 | 3 | 0 |  |
| `Variant` | MeshPart | 2 | 4.6x4.0x10.5 | 2 | 2 |  |
| `wcusdaudw_LOD4_Aset_interior__M_wcusdaudw_01_LOD` | MeshPart | 1 | 15.6x15.6x2.3 | 1 | 1 |  |
| `wk5odbadw_LOD4_Aset_interior_railing_M_wk5odbadw_00_LOD` | MeshPart | 6 | 10.7x5.8x0.2 … 10.6x10.5x0.9 | 6 | 6 |  |
| `wcusdaudw_LOD4_Aset_interior__M_wcusdaudw_02_LOD` | MeshPart | 1 | 4.3x15.6x4.3 | 1 | 1 |  |
| `wcusdaudw_LOD4_Aset_interior__M_wcusdaudw_00_LOD` | MeshPart | 1 | 3.5x15.6x2.3 | 1 | 1 |  |
| `ug1xbhjdw_LOD` | MeshPart | 1 | 5.9x10.8x0.7 | 1 | 1 |  |
| `wcusdb0dw_LOD3_Aset_interior__M_wcusdb0dw_00_LOD` | MeshPart | 1 | 2.1x5.1x2.1 | 1 | 1 |  |
| `wcusdb0dw_LOD3_Aset_interior__M_wcusdb0dw_03_LOD` | MeshPart | 1 | 1.7x5.1x1.2 | 1 | 1 |  |
| `wcusdaudw_LOD4_Aset_interior__M_wcusdaudw_04_LOD` | MeshPart | 1 | 1.8x15.6x2.3 | 1 | 1 |  |
| `wcusdaudw_LOD4_Aset_interior__M_wcusdaudw_03_LOD` | MeshPart | 1 | 3.1x15.6x3.1 | 1 | 1 |  |
| `wcusdb0dw_LOD3_Aset_interior__M_wcusdb0dw_01_LOD` | MeshPart | 1 | 2.5x5.1x2.5 | 1 | 1 |  |
| `wcusdb0dw_LOD3_Aset_interior__M_wcusdb0dw_02_LOD` | MeshPart | 1 | 10.1x5.1x1.2 | 1 | 1 |  |
| `ufzueazdw_LOD4_Aset_modular__M_ufzueazdw_00_LOD` | MeshPart | 1 | 2.2x3.2x2.2 | 1 | 1 |  |
| `ugztddbdw_LOD` | MeshPart | 1 | 3.6x10.5x3.6 | 1 | 1 |  |
| `ufzueazdw_LOD4_Aset_modular__M_ufzueazdw_01_LOD` | MeshPart | 1 | 4.5x3.2x2.1 | 1 | 1 |  |
| `ufbpacwdw_LOD5_Aset_other__S_ufbpacwdw_03_LOD` | MeshPart | 1 | 0.9x0.9x1.1 | 1 | 1 |  |
| `ufbpacwdw_LOD5_Aset_other__S_ufbpacwdw_00_LOD` | MeshPart | 1 | 8.7x4.9x0.7 | 1 | 1 |  |
| `ugynedpdw_LOD5_Aset_modular__M_ugynedpdw_01_LOD` | MeshPart | 2 | 7.6x1.9x1.1 … 13.4x2.8x3.6 | 2 | 2 |  |
| `ugyrfh1dw_LOD` | MeshPart | 1 | 9.8x0.9x7.6 | 1 | 1 |  |
| `ufbpacwdw_LOD5_Aset_other__S_ufbpacwdw_01_LOD` | MeshPart | 1 | 0.6x4.9x0.7 | 1 | 1 |  |
| `ug1xbdfdw_LOD` | MeshPart | 6 | 5.1x3.4x5.1 … 8.2x17.9x12.3 | 6 | 6 |  |
| `ufbpacwdw_LOD5_Aset_other__S_ufbpacwdw_02_LOD` | MeshPart | 1 | 8.6x0.9x1.1 | 1 | 1 |  |
| `ugyqcitdw_LOD` | MeshPart | 1 | 9.9x0.7x7.7 | 1 | 1 |  |
| `ugynedpdw_LOD5_Aset_modular__M_ugynedpdw_00_LOD` | MeshPart | 1 | 1.9x1.9x1.0 | 1 | 1 |  |
| `ugynedpdw_LOD5_Aset_modular__M_ugynedpdw_02_LOD` | MeshPart | 1 | 0.9x1.9x1.0 | 1 | 1 |  |
| `ugynedpdw_LOD5_Aset_modular__M_ugynedpdw_03_LOD` | MeshPart | 1 | 1.9x1.9x1.9 | 1 | 1 |  |
| `ugynedpdw_LOD5_Aset_modular__M_ugynedpdw_04_LOD` | MeshPart | 1 | 3.0x1.9x3.0 | 1 | 1 |  |
| `ugywcjzdw_LOD` | MeshPart | 1 | 8.8x11.6x2.3 | 1 | 1 |  |
| `wbpveaydw_LOD4_Aset_interior_wall_M_wbpveaydw_01_LOD` | MeshPart | 1 | 4.4x8.9x0.6 | 1 | 1 |  |
| `wbpveaydw_LOD4_Aset_interior_wall_M_wbpveaydw_02_LOD` | MeshPart | 2 | 7.3x8.2x0.4 … 7.6x9.9x0.8 | 2 | 2 |  |
| `wk5odbadw_LOD4_Aset_interior_railing_M_wk5odbadw_01_LOD` | MeshPart | 1 | 1.6x3.3x1.4 | 1 | 1 |  |
| `Stool` | MeshPart | 1 | 2.1x3.5x2.0 | 1 | 0 |  |
| `wbpveaydw_LOD4_Aset_interior_wall_M_wbpveaydw_00_LOD` | MeshPart | 1 | 7.4x8.2x2.1 | 1 | 1 |  |
| `wbpveaydw_LOD4_Aset_interior_wall_M_wbpveaydw_03_LOD` | MeshPart | 1 | 7.3x8.2x0.4 | 1 | 1 |  |
| `uifnae2dw_LOD5_Aset_modular__M_uifnae2dw_00_LOD` | MeshPart | 1 | 9.0x4.4x1.3 | 1 | 1 |  |
| `uifnae2dw_LOD5_Aset_modular__M_uifnae2dw_01_LOD` | MeshPart | 1 | 1.2x4.4x1.3 | 1 | 1 |  |
| `wcskfaidw_LOD4_Aset_industrial_railway_M_wcskfaidw_00_LOD` | MeshPart | 1 | 13.3x1.7x8.0 | 1 | 1 |  |
| `wcskfaidw_LOD4_Aset_industrial_railway_M_wcskfaidw_01_LOD` | MeshPart | 1 | 13.3x1.3x8.0 | 1 | 1 |  |
| `udrffjjqx_LOD` | MeshPart | 4 | 6.4x0.6x0.9 … 5.4x2.3x2.3 | 4 | 4 |  |
| `wcskfaidw_LOD4_Aset_industrial_railway_M_wcskfaidw_02_LOD` | MeshPart | 1 | 13.3x1.3x8.0 | 1 | 1 |  |
| `vi5gch1ga_LOD3_Aset_props__S_vi5gch1ga_00_LOD` | MeshPart | 1 | 9.4x1.4x2.9 | 1 | 0 |  |
| `vi5gch1ga_LOD3_Aset_props__S_vi5gch1ga_01_LOD` | MeshPart | 1 | 9.4x0.9x2.9 | 1 | 0 |  |

#### Natural

| Objeto | Clase | Cuántos | Talla (studs) | Piezas | SA | Notas |
|---|---|---|---|---|---|---|
| `MeshPart` | MeshPart | 46 | 2.5x1.9x2.3 … 161.6x25.4x60.5 | 46 | 46 |  |
| `tkkodbhfa_LOD` | MeshPart | 1 | 50.0x6.6x36.0 | 1 | 1 |  |
| `DeadRedwoodTreeVar` | Model | 3 | 34.1x75.2x30.7 … 69.6x153.5x62.8 | 9 | 9 |  |
| `JapanwoodTreeVar` | Model | 2 | 34.3x28.5x33.9 | 4 | 4 |  |
| `Terrain piece` | MeshPart | 9 | 45.9x4.1x19.4 … 66.2x28.7x21.5 | 9 | 9 |  |
| `Terrain Piece` | MeshPart | 3 | 42.6x8.7x28.6 … 50.0x8.5x50.0 | 3 | 3 |  |
| `PlateauStatue` | MeshPart | 1 | 53.0x14.0x45.0 | 1 | 1 |  |
| `PlateauGround` | MeshPart | 2 | 41.0x4.0x33.0 … 25.0x7.0x43.0 | 2 | 2 |  |
| `Model` | Model | 15 | 6.8x3.6x6.0 … 44.3x22.8x44.1 | 246 | 245 |  |
| `PlateauRock` | MeshPart | 2 | 9.0x5.0x7.0 … 13.0x7.0x9.0 | 2 | 2 |  |
| `vijmaacqx_LOD2` | MeshPart | 1 | 50.0x35.0x33.1 | 1 | 1 |  |
| `PBR fireplace` | Model | 1 | 9.3x2.3x9.4 | 1 | 1 |  |
| `tjrsfbdda_LOD` | MeshPart | 2 | 50.0x4.4x32.5 | 2 | 2 |  |
| `SnowPile` | Model | 1 | 33.3x5.5x33.3 | 1 | 1 |  |
| `MediumIcebergVar` | Model | 1 | 68.9x34.0x67.7 | 1 | 1 |  |
| `LargeRiverBoulder` | Model | 1 | 32.7x30.4x25.5 | 1 | 1 |  |
| `LargeBoulder_Var` | Model | 1 | 32.5x50.1x32.5 | 1 | 1 |  |
| `Nordic Cliff` | MeshPart | 3 | 12.0x7.7x7.3 … 17.5x11.3x10.7 | 3 | 3 |  |
| `LargeMossBoulderVar` | Model | 2 | 25.9x20.7x24.9 … 65.0x52.1x62.7 | 2 | 2 |  |
| `Rock` | MeshPart | 4 | 7.5x5.0x7.0 … 50.0x26.9x43.0 | 4 | 4 |  |
| `Boulder` | MeshPart | 4 | 9.3x5.1x5.7 … 27.1x15.0x16.5 | 4 | 4 |  |
| `MediumBoulderVar` | Model | 2 | 28.5x19.7x14.7 | 2 | 2 |  |
| `Ground` | MeshPart | 1 | 53.0x3.6x52.2 | 1 | 1 |  |
| `LargeBoulderVar` | Model | 3 | 28.5x19.7x14.7 … 37.8x58.4x37.9 | 3 | 3 |  |
| `Aset_rock_volcanic_M_qjmvT_LOD` | MeshPart | 2 | 10.9x5.5x12.4 … 43.9x22.1x50.0 | 2 | 2 |  |
| `PBR Textured Rock` | MeshPart | 1 | 50.0x16.9x16.6 | 1 | 1 |  |
| `Granit` | MeshPart | 2 | 12.4x7.9x10.4 … 50.0x31.8x41.9 | 2 | 2 |  |
| `Aset_rock_granite_M_radaD_LOD` | MeshPart | 2 | 9.2x6.9x7.6 … 50.0x37.5x41.0 | 2 | 2 |  |
| `Aset_rock_granite_M_rkiwf_LOD` | Model | 1 | 10.4x5.3x7.9 | 1 | 1 |  |
| `Aset_rock_granite_M_qkEgh_LOD1` | MeshPart | 1 | 50.0x8.8x38.9 | 1 | 1 |  |
| `Aset_rock_granite_M_rcoxL_LOD` | Model | 1 | 7.5x5.8x9.7 | 1 | 1 |  |
| `Aset_rock_granite_M_pkjsG_LOD` | Model | 1 | 7.4x3.8x6.1 | 1 | 1 |  |
| `Aset_rock_granite_M_pkjsK_LOD` | Model | 1 | 11.6x6.3x7.4 | 1 | 1 |  |
| `Aset_rock_granite_M_rcwwx_LOD` | Model | 1 | 7.1x6.3x6.1 | 1 | 1 |  |
| `Aset_rock_granite_M_phyhg_LOD` | Model | 1 | 8.6x7.0x8.6 | 1 | 1 |  |
| `Small Rock` | MeshPart | 1 | 4.9x5.2x4.6 | 1 | 1 |  |
| `Aset_rock_granite_M_pjAxm_LOD` | Model | 1 | 7.2x4.6x4.9 | 1 | 1 |  |
| `3DRock004_16K` | MeshPart | 2 | 7.2x4.5x7.1 … 15.7x9.9x15.5 | 2 | 2 |  |
| `Aset_rock_granite_M_rkksB_LOD` | Model | 1 | 9.8x2.8x7.0 | 1 | 1 |  |
| `Medium Boulder` | MeshPart | 1 | 11.2x7.7x5.7 | 1 | 1 |  |
| `Aset_rock_granite_M_piprw_LOD` | Model | 1 | 9.6x6.7x3.3 | 1 | 1 |  |
| `Aset_rock_granite_M_pkeeM_LOD` | Model | 1 | 7.7x5.0x6.3 | 1 | 1 |  |
| `LargeBoulder` | MeshPart | 1 | 5.5x8.6x5.6 | 1 | 1 |  |
| `Medium Moss Boulder` | MeshPart | 1 | 9.0x8.4x7.0 | 1 | 1 |  |
| `Aset_rock_granite_M_rjznD_LOD` | Model | 1 | 5.8x4.0x6.9 | 1 | 1 |  |
| `ROCK` | MeshPart | 13 | 16.7x10.5x16.5 | 13 | 14 |  |
| `Main` | MeshPart | 1 | 50.0x3.3x35.4 | 1 | 1 |  |
| `MediumMossBoulderSnowyVar` | Model | 1 | 9.8x9.1x7.6 | 1 | 1 |  |
| `RockBridge` | MeshPart | 1 | 50.0x7.9x40.4 | 1 | 1 |  |
| `Meshpart` | MeshPart | 2 | 50.0x4.2x19.7 … 50.0x15.2x42.0 | 2 | 2 |  |
| `ti1lejbfa_LOD` | MeshPart | 1 | 50.0x3.1x27.5 | 1 | 1 |  |
| `untitled` | MeshPart | 1 | 50.0x7.9x48.3 | 1 | 1 |  |
| `tkhhdhefa_LOD` | MeshPart | 1 | 50.0x4.0x24.8 | 1 | 1 |  |
| `tlnvecpfa_LOD` | MeshPart | 2 | 50.0x12.0x28.5 | 2 | 2 |  |
| `ForestGround` | MeshPart | 1 | 50.0x1.0x50.0 | 1 | 1 |  |
| `ti1fbiifa_LOD` | MeshPart | 1 | 50.0x4.1x28.3 | 1 | 1 |  |
| `tkqvabmfa_LOD` | MeshPart | 1 | 50.0x4.2x34.9 | 1 | 1 |  |
| `tletcalfa_LOD` | MeshPart | 1 | 32.7x3.5x50.0 | 1 | 1 |  |
| `tkwvec1fa_LOD` | MeshPart | 1 | 62.2x4.1x31.2 | 1 | 1 |  |
| `tkvsei1fa_LOD` | MeshPart | 1 | 50.0x8.9x39.2 | 1 | 1 |  |
| `tksucdtda_LOD` | MeshPart | 1 | 50.0x19.7x26.6 | 1 | 1 |  |
| `tkwqbbofa_LOD` | MeshPart | 1 | 48.5x4.8x49.0 | 1 | 1 |  |
| `tkhtchufa_LOD` | MeshPart | 1 | 50.0x5.1x26.8 | 1 | 1 |  |
| `tkjpfjlfa_LOD` | MeshPart | 1 | 50.0x3.4x22.7 | 1 | 1 |  |
| `PBR Volcano Mount` | MeshPart | 1 | 37.2x9.2x50.0 | 1 | 1 |  |
| `PBR Rock Pile` | MeshPart | 1 | 24.5x3.0x24.5 | 1 | 1 |  |
| `tkehde2da_LOD` | MeshPart | 1 | 50.0x5.2x32.8 | 1 | 1 |  |
| `tjjxbgoda_LOD` | MeshPart | 1 | 47.9x36.8x50.0 | 1 | 1 |  |
| `PBR Gold` | MeshPart | 1 | 5.5x4.3x13.0 | 1 | 1 |  |
| `tkknaeyfa_LOD` | MeshPart | 1 | 50.0x5.7x19.3 | 1 | 1 |  |
| `tkvtbebfa_LOD` | MeshPart | 1 | 50.0x8.1x17.2 | 1 | 1 |  |
| `DeadBeechwoodTreeVar` | Model | 6 | 4.1x13.6x7.8 … 45.4x73.5x37.4 | 9 | 9 |  |
| `Trunk` | MeshPart | 4 | 4.6x12.1x3.7 … 17.1x14.1x15.8 | 4 | 4 |  |
| `TreeStump001_LowPoly` | MeshPart | 1 | 15.9x11.9x14.3 | 1 | 1 |  |
| `FallenTreeSnowyVar` | Model | 1 | 80.7x14.8x15.6 | 1 | 1 |  |
| `DeadMapleLeafTreeVar` | Model | 1 | 24.2x20.0x22.5 | 1 | 1 |  |
| `DeadJapanwoodTreeVar` | Model | 2 | 15.8x17.3x17.0 | 2 | 2 |  |
| `DeadBeechwoodSapplingVar` | Model | 1 | 4.6x12.1x3.7 | 1 | 1 |  |
| `TreeStumpVar` | Model | 1 | 23.4x13.1x22.5 | 1 | 1 |  |
| `FallenTreeVar` | Model | 2 | 48.1x9.7x11.2 … 80.7x14.8x15.6 | 2 | 2 |  |
| `tjsicjffa_LOD` | MeshPart | 1 | 36.1x6.3x6.3 | 1 | 1 |  |
| `Fallen Tree` | MeshPart | 1 | 50.0x13.2x15.4 | 1 | 0 |  |
| `tlhveh0fa_LOD` | MeshPart | 1 | 50.0x44.7x26.2 | 1 | 1 |  |
| `DeadRedwoodTreeSnowyVar` | Model | 1 | 71.8x158.6x64.8 | 2 | 1 |  |
| `tk3tbeida_LOD` | MeshPart | 1 | 24.2x50.0x20.4 | 1 | 1 |  |
| `DeadBroadLeafTreeVar` | Model | 1 | 14.6x21.3x18.0 | 1 | 1 |  |
| `TreeDead` | MeshPart | 1 | 16.0x31.0x18.0 | 1 | 1 |  |
| `DeadDogWoodTreeVar` | Model | 1 | 14.7x16.0x15.8 | 1 | 1 |  |
| `RedwoodTreeVar` | Model | 3 | 34.1x81.1x33.2 … 69.7x165.6x67.9 | 14 | 14 |  |
| `BeechwoodTreeVar` | Model | 6 | 13.8x16.5x10.5 … 65.6x78.4x49.7 | 12 | 12 |  |
| `BeechwoodSapplingVar` | Model | 1 | 7.2x12.5x7.3 | 2 | 2 |  |
| `Tree` | Model | 2 | 11.2x24.0x11.6 … 39.2x93.2x38.2 | 5 | 4 | ⚠ 1 scripts |
| `ElmTree-01-0Lod` | Model | 1 | 17.8x17.8x21.0 | 30 | 15 |  |
| `MapleTree-01-0Lod` | Model | 1 | 19.6x18.1x14.4 | 14 | 7 |  |
| `PalmtreeVar` | Model | 2 | 24.2x36.9x24.2 | 38 | 38 |  |
| `DogWoodTreeVar` | Model | 1 | 31.9x26.5x31.5 | 2 | 2 |  |
| `BroadLeafTreeVar` | Model | 1 | 28.1x36.0x34.7 | 2 | 2 |  |
| `Palm_tree_002_v` | Model | 1 | 11.9x23.3x10.6 | 5 | 5 |  |
| `MapleLeafTreeVar` | Model | 1 | 47.0x32.4x44.7 | 2 | 2 |  |
| `PineTreeVar` | Model | 2 | 37.6x81.0x36.6 … 59.8x133.0x58.2 | 16 | 16 |  |
| `Butterfly_Idle` | Model | 1 | 1.1x0.2x0.7 | 1 | 0 | ⚠ 1 scripts |
| `Dragonfly_Flight` | Model | 1 | 1.3x0.4x0.7 | 1 | 1 | ⚠ 1 scripts |
| `Dragonfly_IdleFlight` | Model | 2 | 1.3x0.4x0.7 | 2 | 2 | ⚠ 2 scripts |
| `Butterfly_FlightPath` | Model | 2 | 1.1x0.2x0.7 | 2 | 0 | ⚠ 2 scripts |
| `RedwoodTreeSnowyVar` | Model | 1 | 71.9x171.0x70.0 | 3 | 2 |  |
| `DouglasFir-02-0Lod` | Model | 1 | 30.8x84.9x31.5 | 12 | 6 |  |
| `DouglasFIr-01-0Lod` | Model | 1 | 50.5x89.1x48.7 | 10 | 3 |  |

#### Building

| Objeto | Clase | Cuántos | Talla (studs) | Piezas | SA | Notas |
|---|---|---|---|---|---|---|
| `City House` | MeshPart | 23 | 19.6x33.7x27.7 … 40.7x58.7x40.7 | 23 | 0 |  |
| `Prefab Highrise` | MeshPart | 2 | 43.8x112.4x52.1 … 50.1x139.7x63.7 | 2 | 0 |  |
| `Factory Booth` | MeshPart | 1 | 12.6x11.4x7.7 | 1 | 0 |  |
| `Prefab Complex` | MeshPart | 2 | 24.1x61.3x24.7 … 24.8x64.1x48.0 | 2 | 0 |  |
| `Factory` | MeshPart | 2 | 43.7x30.8x23.8 … 32.4x53.3x44.9 | 2 | 0 |  |
| `City House` | Model | 2 | 47.6x34.4x43.4 … 34.4x58.5x47.6 | 6 | 0 |  |
| `lowres City Housing` | MeshPart | 2 | 19.8x50.3x190.6 … 41.3x59.8x141.2 | 2 | 0 |  |
| `Prefab Highrise` | Model | 1 | 72.1x112.3x71.8 | 4 | 0 |  |
| `Warehouse` | MeshPart | 1 | 50.3x34.6x29.4 | 1 | 0 |  |
| `Factory Chimney` | MeshPart | 1 | 8.9x88.1x8.9 | 1 | 0 |  |

#### City props

| Objeto | Clase | Cuántos | Talla (studs) | Piezas | SA | Notas |
|---|---|---|---|---|---|---|
| `AC_Unit_01_A` | Model | 1 | 12.0x6.5x7.1 | 1 | 1 |  |
| `Bus_Stop_01_A` | Model | 1 | 7.3x14.0x22.5 | 2 | 1 |  |
| `Crosswalk_Indicator_01_A` | Model | 1 | 5.3x14.1x5.1 | 1 | 1 |  |
| `FireHydrant_01_A` | Model | 1 | 1.5x3.3x1.7 | 1 | 1 |  |
| `FireHydrant_01_B` | Model | 1 | 1.5x3.3x1.7 | 1 | 1 |  |
| `Garbage_Bin` | Model | 1 | 13.2x13.1x8.6 | 1 | 1 |  |
| `Kiosk_01_A` | Model | 1 | 5.9x10.8x2.6 | 1 | 1 |  |
| `Mailbox_01_A` | Model | 1 | 2.7x5.4x2.5 | 1 | 1 |  |
| `MetalBench_01_A` | Model | 1 | 2.9x4.8x8.1 | 1 | 0 |  |
| `Newspaper_Stand_01_A` | Model | 1 | 2.5x4.7x2.7 | 2 | 1 |  |
| `Newspaper_Stand_01_B` | Model | 1 | 2.5x4.7x2.7 | 2 | 1 |  |
| `Newspaper_Stand_01_C` | Model | 1 | 2.5x4.7x2.7 | 2 | 1 |  |
| `Newspaper_Stand_01_D` | Model | 1 | 2.5x4.7x2.7 | 2 | 1 |  |
| `Pedestal_01_A` | Model | 1 | 12.3x19.6x12.3 | 2 | 1 |  |
| `PlanterBase` | Model | 1 | 3.8x3.6x3.7 | 10 | 10 |  |
| `Planter_Rectangle_01_A` | Model | 1 | 9.9x3.4x4.2 | 10 | 10 |  |
| `Planter_Round_01_A` | Model | 2 | 3.8x3.3x3.8 … 9.7x5.4x9.7 | 16 | 16 |  |
| `Planter_Square_01_A` | Model | 1 | 9.0x3.6x6.9 | 10 | 10 |  |
| `Powerline_01_A` | Model | 1 | 64.0x161.7x62.5 | 1 | 1 |  |
| `Railing_01_A` | Model | 1 | 1.1x5.7x22.9 | 3 | 3 |  |
| `StreeBarrel_01_A` | Model | 1 | 3.4x3.8x3.4 | 1 | 1 |  |
| `StreetLamp_Small_Var` | Model | 1 | 1.1x5.0x1.1 | 2 | 0 |  |
| `StreetLightPole_01_A` | Model | 1 | 9.9x35.3x1.8 | 6 | 0 |  |
| `Telephone_Pole_01_A` | Model | 1 | 12.8x34.9x3.5 | 1 | 1 |  |
| `Traffic_Light` | Model | 2 | 5.1x22.6x3.9 … 36.1x22.8x6.8 | 20 | 2 | ⚠ 2 scripts |
| `Road_Intersection_03_A` | Model | 1 | 60.0x23.8x61.6 | 17 | 5 | ⚠ 1 scripts |
| `Road_Turn_45_02_A` | Model | 1 | 91.7x1.2x84.9 | 3 | 3 |  |
| `Road_Turn_45_03_A` | Model | 1 | 120.0x1.2x84.9 | 4 | 4 |  |
| `Road_Intersection_01_A` | Model | 1 | 123.3x23.8x124.1 | 65 | 17 | ⚠ 4 scripts |
| `Road_Intersection_01_A.Crosswalks.Crosswalk_01_A` | Model | 8 | 13.3x0.0x38.4 | 8 | 8 |  |
| `Road_Intersection_FourWay_01_A` | Model | 1 | 81.8x23.8x81.7 | 35 | 11 | ⚠ 2 scripts |
| `Road_Intersection_T_01_A` | Model | 1 | 60.0x23.8x81.8 | 19 | 7 | ⚠ 1 scripts |
| `Road_Turn_03_A` | Model | 1 | 160.0x1.7x160.0 | 3 | 3 |  |
| `Road_Turn_45_01_A` | Model | 1 | 56.6x1.2x80.0 | 3 | 3 |  |
| `Road_03_A` | MeshPart | 1 | 40.0x1.0x40.0 | 1 | 1 |  |
| `Road_03_B` | MeshPart | 1 | 40.0x1.0x40.0 | 1 | 1 |  |
| `Road_03_C` | MeshPart | 1 | 40.0x1.0x40.0 | 1 | 1 |  |
| `Road_Turn_01_A` | Model | 1 | 80.0x1.7x80.0 | 3 | 3 |  |
| `Road_Turn_02_A` | Model | 1 | 120.0x1.7x120.0 | 3 | 3 |  |
| `Road_02_A` | MeshPart | 1 | 40.0x1.0x40.0 | 1 | 1 |  |
| `Road_01_A` | MeshPart | 1 | 40.0x1.0x40.0 | 1 | 1 |  |
| `Sidewalk_04_C` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_01_A` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_01_B` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_01_C` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_02_A` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_02_B` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_02_C` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_03_A` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_03_B` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_03_C` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_04_A` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Sidewalk_04_B` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Crosswalk_01_B` | Model | 1 | 13.0x0.0x19.9 | 1 | 1 |  |
| `Manhole_Roblox_01_A` | Model | 1 | 7.5x0.0x7.5 | 1 | 1 |  |
| `Road_Patch_02_A` | Model | 1 | 29.3x0.0x9.9 | 1 | 1 |  |
| `Road_Patch_03_A` | Model | 1 | 7.9x0.1x12.9 | 1 | 1 |  |
| `Road_Patch_04_A` | Model | 1 | 9.2x0.1x12.9 | 1 | 1 |  |
| `StreetWear` | Model | 4 | 15.5x0.1x11.4 … 25.3x0.1x25.8 | 4 | 0 | 4 Decal |
| `Utility_Cover` | Model | 5 | 20.1x0.0x10.1 … 9.9x0.1x6.3 | 5 | 5 |  |
| `Sidewalk_Corner_01_A` | MeshPart | 1 | 20.0x0.7x20.0 | 1 | 1 |  |
| `Road_DL_Turn_01_A` | Model | 1 | 120.0x1.7x120.0 | 4 | 4 |  |
| `Road_DL_Turn_02_A` | Model | 1 | 160.0x1.7x160.0 | 4 | 4 |  |
| `Road_Intersection_02_A` | Model | 1 | 121.6x23.8x61.7 | 33 | 9 | ⚠ 2 scripts |

### MaterialVariant (108)

Por BaseMaterial: Concrete 16, Pavement 16, Brick 13, Wood 11, Grass 9, Metal 8, Asphalt 5, WoodPlanks 4, Cobblestone 4, Sand 3, Ground 3, Pebble 3, Mud 2, Ice 2, Fabric 2, Plastic 2, SmoothPlastic 2, Slate 1, Marble 1, Foil 1.
Todos tienen nombre propio (`Tile 1`, `Pavement 3`…), así que no chocan con los materiales de Roblox. Ojo: `Pavement  7` lleva dos espacios, `Cobblestone 5` es Concrete y `Old cobblestone` es Plastic.

| Carpeta | Name | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|---|
| Indoor / Tile | Tile 7 | Concrete | 6 | Regular |
| Indoor / Tile | Tile 6 | Concrete | 8 | Regular |
| Indoor / Tile | Tile 5 | Concrete | 10 | Regular |
| Indoor / Tile | Tile 2 | Concrete | 8 | Regular |
| Indoor / Tile | Tile 3 | Concrete | 10 | Regular |
| Indoor / Tile | Tile 1 | Concrete | 7 | Regular |
| Indoor / Tile | Tile 4 | Concrete | 8 | Regular |
| Indoor / Wood | Wood 3 | Wood | 8 | Organic |
| Indoor / Wood | Wood 1 | Wood | 5 | Regular |
| Indoor / Wood | Wood 4 | WoodPlanks | 11.74 | Regular |
| Indoor / Wood | Wood 5 | WoodPlanks | 12 | Regular |
| Indoor / Wood | Wood 6 | Wood | 10 | Regular |
| Indoor / Wood | Wood 7 | WoodPlanks | 10 | Regular |
| Indoor / Wood | Wood 8 | Wood | 10 | Regular |
| Indoor / Wood | Wood 9 | Wood | 10 | Regular |
| Indoor / Wood | Wood 11 | Wood | 10 | Regular |
| Indoor / Wood | Wood 10 | Wood | 10 | Regular |
| Indoor / Wood | Wood 12 | Wood | 10 | Regular |
| Indoor / Wood | Wood 13 | Wood | 10 | Regular |
| Indoor / Wood | Wood 14 | Wood | 10 | Regular |
| Indoor / Marble | Marble | Marble | 10 | Regular |
| Outdoor / Sand | Sand 1 | Sand | 10 | Organic |
| Outdoor / Sand | Sand 2 | Sand | 20 | Regular |
| Outdoor / Grass | Grass 2 | Grass | 10 | Regular |
| Outdoor / Grass | Grass 1 | Grass | 30 | Regular |
| Outdoor / Grass | Grass 3 | Grass | 5 | Regular |
| Outdoor / Grass | Grass 4 | Grass | 10 | Regular |
| Outdoor / Grass | Grass 5 | Grass | 20 | Regular |
| Outdoor / Grass | Grass 6 | Grass | 20 | Regular |
| Outdoor / Grass | Grass 7 | Grass | 30 | Regular |
| Outdoor / Grass | Grass 8 | Grass | 100 | Regular |
| Outdoor / Gravel | Gravel 2 | Pebble | 10 | Regular |
| Outdoor / Gravel | Gravel 1 | Pebble | 10 | Regular |
| Outdoor / Gravel | Gravel 3 | Pebble | 10 | Regular |
| Outdoor / Pavement | Pavement 2 | Pavement | 8 | Regular |
| Outdoor / Pavement | Pavement 3 | Pavement | 6 | Regular |
| Outdoor / Pavement | Pavement 1 | Pavement | 5 | Regular |
| Outdoor / Pavement | Pavement 4 | Pavement | 4 | Regular |
| Outdoor / Pavement | Pavement 5 | Pavement | 4 | Regular |
| Outdoor / Pavement | Pavement 6 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement  7 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 8 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 9 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 10 | Pavement | 12.5 | Regular |
| Outdoor / Pavement | Pavement 11 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 12 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 13 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 14 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 15 | Pavement | 10 | Regular |
| Outdoor / Pavement | Pavement 16 | Pavement | 10 | Regular |
| Outdoor / Ground | Ground 1 | Ground | 15 | Organic |
| Outdoor / Ground | Ground 2 | Ground | 10 | Organic |
| Outdoor / Mud | Mud 1 | Mud | 10 | Organic |
| Outdoor / Mud | Mud 2 | Mud | 10 | Organic |
| Outdoor / Slate | Slate 1 | Slate | 10 | Regular |
| Outdoor / Ice | Ice 1 | Ice | 10 | Regular |
| Outdoor / Dirt | Dirt 1 | Ground | 10 | Organic |
| Outdoor / Asphalt | Asphalt 1 | Asphalt | 10 | Regular |
| Outdoor / Asphalt | Asphalt 2 | Asphalt | 10 | Regular |
| Outdoor / Asphalt | Asphalt 3 | Asphalt | 2 | Regular |
| Outdoor / Asphalt | Asphalt 4 | Asphalt | 30 | Regular |
| Outdoor / Marking | Marking 1 | Asphalt | 2 | Regular |
| Outdoor / Plaster | Plaster 1 | Concrete | 10 | Regular |
| Outdoor / Plaster | Plaster 2 | Concrete | 10 | Regular |
| Outdoor / Sidewalk liner | Sidewalk liner 1 | Plastic | 10 | Regular |
| Outdoor / Container | Container 1 | Concrete | 2 | Regular |
| Building / Metal | Metal 1 | Metal | 10 | Regular |
| Building / Metal | Metal 2 | Metal | 10 | Regular |
| Building / Metal | Metal 3 | Metal | 10 | Regular |
| Building / Metal | Metal 4 | Metal | 6 | Organic |
| Building / Metal | Metal 5 | Metal | 10.5 | Regular |
| Building / Metal | Metal 6 | Metal | 10 | Regular |
| Building / Metal | Metal 7 | Metal | 10 | Organic |
| Building / Metal | Metal 8 | Metal | 6 | Organic |
| Building / Concrete | Concrete 4 | Concrete | 6 | Organic |
| Building / Concrete | Concrete 2 | Concrete | 10 | Regular |
| Building / Concrete | Concrete 1 | Concrete | 10 | Regular |
| Building / Concrete | Concrete 3 | Concrete | 8 | Regular |
| Building / Cobblestone | Cobblestone 1 | Cobblestone | 15 | Regular |
| Building / Cobblestone | Cobblestone 2 | Cobblestone | 6 | Organic |
| Building / Cobblestone | Cobblestone 3 | Cobblestone | 10 | Regular |
| Building / Cobblestone | Cobblestone 4 | Cobblestone | 25 | Regular |
| Building / Cobblestone | Cobblestone 5 | Concrete | 20 | Regular |
| Building / Brick | Brick 1 | Brick | 20 | Regular |
| Building / Brick | Brick 9 | Brick | 10 | Regular |
| Building / Brick | Brick 8 | Brick | 8 | Regular |
| Building / Brick | Brick 7 | Brick | 4 | Regular |
| Building / Brick | Brick 6 | Brick | 10 | Regular |
| Building / Brick | Brick 5 | Brick | 6 | Regular |
| Building / Brick | Brick 4 | Brick | 8 | Regular |
| Building / Brick | Brick 3 | Brick | 9 | Regular |
| Building / Brick | Brick 2 | Brick | 9 | Regular |
| Building / Brick | Brick 12 | Brick | 10 | Regular |
| Building / Brick | Brick 11 | Brick | 11 | Regular |
| Building / Brick | Brick 10 | Brick | 5 | Regular |
| Other / Leather | Leather 1 | SmoothPlastic | 1.5 | Regular |
| Other / Leather | Leather 2 | SmoothPlastic | 2 | Regular |
| Other / Old Textures | Old Brick | Brick | 5 | Regular |
| Other / Old Textures | Old Concrete | Concrete | 10 | Regular |
| Other / Old Textures | Old Fabric | Fabric | 5 | Regular |
| Other / Old Textures | Old Foil | Foil | 5 | Regular |
| Other / Old Textures | Old Grass | Grass | 5 | Regular |
| Other / Old Textures | Old Ice | Ice | 5 | Regular |
| Other / Old Textures | Old Sand | Sand | 5 | Regular |
| Other / Old Textures | Old Wood | Wood | 5 | Regular |
| Other / Old Textures | Old WoodPlanks | WoodPlanks | 5 | Regular |
| Other / Old Textures | Old cobblestone | Plastic | 10 | Regular |
| Other / Cushion | Cushion 1 | Fabric | 8 | Regular |
