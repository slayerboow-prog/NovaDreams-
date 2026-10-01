# Contenido de los modelos de la Tienda (volcado real en un servidor de Roblox)

Fecha: 2026-10-01. Hecho con `bash scripts/cloud-test.sh -v modelos` (script `scripts/cloud/modelos.luau`):
Luau en la nube (Open Cloud *Luau execution*) en un servidor de la última versión publicada de *Real Life Simulator*.
Para cada id: `pcall(InsertService.LoadAsset, InsertService, id)`; si falla, `GetLatestAssetVersionAsync` + `LoadAssetVersion`.

## Resumen

- **Cargan (4)**: los packs oficiales de Roblox → 6432306802, 6370681139, 10840661513, 6432233485.
- **No cargan (13)**: todos los de la comunidad. Error exacto en los dos métodos: `User is not authorized to access Asset.`
  En un servidor, `LoadAsset` solo deja cargar modelos del dueño del juego o de Roblox; `AllowInsertFreeAssets` no lo cambia aquí.
  Para usarlos: abrirlos en Studio (Toolbox), revisarlos, y **volver a publicarlos con la cuenta/grupo dueño del juego** (o meterlos en el `.rbxl`).

## Notas para usarlos desde código

- `LoadAsset(id)` devuelve un `Model` contenedor; dentro hay **un Folder** con el nombre del pack (`Forest Pack`, `City Props Pack`, `Landscaping Pack`, `City Road Pack`) y dentro los modelos sueltos. Ejemplo: `raiz["Forest Pack"].BeechwoodTree_Var01:Clone()`.
- Ojo con **nombres repetidos** (`BeechwoodTree_Var03` ×2 en Forest; `Planter_Round_01_A` ×2 en City Props; varios `RobloxBillboard`): buscar por nombre devuelve el primero.
- Casi todo es **MeshPart + SurfaceAppearance** (PBR). El material de la MeshPart es `Plastic` (la textura la pone la SurfaceAppearance).
- **Scripts** (todos `Script` con `Enabled=true`):
  - Forest Pack (13): uno en cada animal animado (`Butterfly_*`, `Dragonfly_*`, `Fish_*`, `Hawk_*`). Los árboles, rocas y plantas no tienen.
  - City Props Pack (2): `LightStateChanger` en `Traffic_Light_01` y `Traffic_Light_02`.
  - City Road Pack (10): uno por cada semáforo `Traffic_Light_01` dentro de los cruces `Road_Intersection_*` (las rectas, curvas y aceras no tienen).
  - Landscaping Pack (4): en las rocas/ladrillos `*_floating` de la carpeta `Rocks|Bricks` (piezas que flotan, probablemente animadas).
  - Recomendación: al clonar, borrar los `LuaSourceContainer` salvo que se quieran esos efectos.
- `RobloxBillboard` (en Forest, City Road y Landscaping) es un cartel publicitario del pack: no usarlo.
- Las tallas son en studs y tal como vienen (sin escalar). Algunos árboles son enormes (`RedwoodTreeLarge-Var01` 263 de alto, `BeechwoodTreeLarge_Var01` 125): usar `Model:ScaleTo()`.

Leyenda de cada línea del árbol: `ruta [Clase] talla=X×Y×Z (studs)` + resumen de todo lo que cuelga de ese nodo:
`piezas` = BaseParts, `MeshPart`, `SpecialMesh`, `SurfaceAppearance`, `Decal/Texture`, `⚠SCRIPTS` (Script/LocalScript/ModuleScript).
En las MeshPart sale también `mat` (Material) y `MeshId`. Los hijos tipo SurfaceAppearance, Decal, Weld o Attachment no se listan como nodo (salen en el resumen y en «además»).
Talla de un Model = `GetExtentsSize()`; de un Folder = caja de todas sus piezas; de una pieza = `Size`.

| ID | Nombre | ¿Carga? | Piezas | MeshPart | SurfaceAppearance | Decal/Texture | Scripts |
|---|---|---|---|---|---|---|---|
| 185280084 | Generic Park Bench (Carollicious) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 404475960 | Street light (Simoon68) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 471214939 | Realistic Palm Tree (Narrakin) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 3256343670 | Realistic Trees (Chr1sDevv) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 5295646823 | Terracotta Pot (PSY0PZ) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 6370681139 | City Props Pack (Roblox) | ✅ LoadAsset | 100 | 94 | 67 | 0 | 2 |
| 6432233485 | City Road Pack (Roblox) | ✅ LoadAsset | 230 | 196 | 104 | 4 | 10 |
| 6432306802 | Forest Pack (Roblox) | ✅ LoadAsset | 85 | 83 | 73 | 0 | 13 |
| 8916801819 | Realistic Street Lamp (SparkTehDog) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 8975295794 | Flower Pot (Noobbreaking) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 9271152246 | Realistic Tree (Nafica08) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 10131972958 | Realistic Tree (Mrwalter87) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 10562894034 | Palm Tree (Realistic) (Natalie_Clabo) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 10840661513 | Landscaping Pack – Duvall Drive (Roblox) | ✅ LoadAsset | 1814 | 1803 | 1541 | 58 | 4 |
| 11508587471 | Trash Can (RTopix) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 12169860688 | Large Terracotta Pot (PSY0PZ) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |
| 12637929826 | Cypress tree (Letaij) | ❌ `User is not authorized to access Asset.` | – | – | – | – | – |


## 185280084 — Generic Park Bench (Carollicious)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 404475960 — Street light (Simoon68)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 471214939 — Realistic Palm Tree (Narrakin)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 3256343670 — Realistic Trees (Chr1sDevv)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 5295646823 — Terracotta Pot (PSY0PZ)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 6370681139 — City Props Pack (Roblox)

Carga con `LoadAsset`. Estructura: `Model` (contenedor de LoadAsset) → `Folder` del pack → modelos sueltos.

### Modelos de primer y segundo nivel

| Ruta (dentro del contenedor) | Clase | Talla (studs) | Contenido |
|---|---|---|---|
| `City Props Pack` | Folder | 234.2×162.2×98.2 | piezas=100 MeshPart=94 SurfaceAppearance=67 ⚠SCRIPTS=2 |
| `City Props Pack/AC_Unit_01_A` | Model | 12.0×6.5×7.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Bus_Stop_01_A` | Model | 7.3×14.0×22.5 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/Crosswalk_Indicator_01_A` | Model | 5.3×14.1×5.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/FireHydrant_01_A` | Model | 1.5×3.3×1.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/FireHydrant_01_B` | Model | 1.5×3.3×1.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Garbage_Bin_01` | Model | 13.2×13.1×8.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Kiosk_01_A` | Model | 5.9×10.8×2.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Mailbox_01_A` | Model | 2.7×5.4×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/MetalBench_01_A` | Model | 2.9×4.8×8.1 | piezas=1 |
| `City Props Pack/Newspaper_Stand_01_A` | Model | 2.5×4.7×2.7 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/Newspaper_Stand_01_B` | Model | 2.5×4.7×2.7 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/Newspaper_Stand_01_C` | Model | 2.5×4.7×2.7 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/Newspaper_Stand_01_D` | Model | 2.5×4.7×2.7 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/Pedestal_01_A` | Model | 12.3×19.6×12.3 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `City Props Pack/PlanterBase_01` | Model | 3.8×3.6×3.7 | piezas=10 MeshPart=10 SurfaceAppearance=10 |
| `City Props Pack/Planter_Rectangle_01_A` | Model | 9.9×3.4×4.2 | piezas=10 MeshPart=10 SurfaceAppearance=10 |
| `City Props Pack/Planter_Round_01_A` | Model | 9.7×5.4×9.7 | piezas=10 MeshPart=10 SurfaceAppearance=10 |
| `City Props Pack/Planter_Round_01_A` | Model | 3.8×3.3×3.8 | piezas=6 MeshPart=6 SurfaceAppearance=6 |
| `City Props Pack/Planter_Square_01_A` | Model | 9.0×3.6×6.9 | piezas=10 MeshPart=10 SurfaceAppearance=10 |
| `City Props Pack/Powerline_01_A` | Model | 64.0×161.7×62.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Railing_01_A` | Model | 1.1×5.7×22.9 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Props Pack/StreeBarrel_01_A` | Model | 3.4×3.8×3.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/StreetLamp_Small_Var01` | Model | 1.1×5.0×1.1 | piezas=2 MeshPart=2 |
| `City Props Pack/StreetLightPole_01_A` | Model | 9.9×35.3×1.8 | piezas=6 MeshPart=6 |
| `City Props Pack/Telephone_Pole_01_A` | Model | 12.8×34.9×3.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Props Pack/Traffic_Light_01` | Model | 36.1×22.8×6.8 | piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `City Props Pack/Traffic_Light_02` | Model | 5.1×22.6×3.9 | piezas=7 MeshPart=5 SurfaceAppearance=1 ⚠SCRIPTS=1 |

<details><summary>Árbol completo (3 niveles)</summary>

```text
Model [Model] talla=234.2x162.2x98.2 piezas=100 MeshPart=94 SurfaceAppearance=67 ⚠SCRIPTS=2
  City Props Pack [Folder] talla=234.2x162.2x98.2 piezas=100 MeshPart=94 SurfaceAppearance=67 ⚠SCRIPTS=2
    City Props Pack/AC_Unit_01_A [Model] talla=12.0x6.5x7.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/AC_Unit_01_A/AC_Unit_01_A [MeshPart] talla=12.0x6.5x7.1 mat=Plastic MeshId=rbxassetid://5849668048 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Bus_Stop_01_A [Model] talla=7.3x14.0x22.5 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Bus_Stop_01_A/Bus_Stop_01_A [MeshPart] talla=7.3x14.0x22.5 mat=Plastic MeshId=rbxassetid://5946954074 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Bus_Stop_01_A/Glass [MeshPart] talla=6.8x9.5x21.9 mat=Glass MeshId=rbxassetid://5946954123 piezas=1 MeshPart=1
    City Props Pack/Crosswalk_Indicator_01_A [Model] talla=5.3x14.1x5.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Crosswalk_Indicator_01_A/Crosswalk_Indicator_01_A [MeshPart] talla=5.3x14.1x5.1 mat=Plastic MeshId=rbxassetid://5825775490 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/FireHydrant_01_A [Model] talla=1.5x3.3x1.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/FireHydrant_01_A/FireHydrantYellow [MeshPart] talla=1.5x3.3x1.7 mat=Plastic MeshId=rbxassetid://6432534338 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/FireHydrant_01_B [Model] talla=1.5x3.3x1.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/FireHydrant_01_B/FireHydrantRed [MeshPart] talla=1.5x3.3x1.7 mat=Plastic MeshId=rbxassetid://6432534338 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Garbage_Bin_01 [Model] talla=13.2x13.1x8.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Garbage_Bin_01/Garbage_Bin_01 [MeshPart] talla=13.2x13.1x8.6 mat=Plastic MeshId=rbxassetid://5678029902 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Kiosk_01_A [Model] talla=5.9x10.8x2.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Kiosk_01_A/Kiosk_01_A [MeshPart] talla=5.9x10.8x2.6 mat=Plastic MeshId=rbxassetid://5809534045 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Mailbox_01_A [Model] talla=2.7x5.4x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Mailbox_01_A/Mailbox_01_A [MeshPart] talla=2.7x5.4x2.5 mat=Plastic MeshId=rbxassetid://5951701717 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/MetalBench_01_A [Model] talla=2.9x4.8x8.1 piezas=1
      City Props Pack/MetalBench_01_A/Bench [UnionOperation] talla=2.9x4.8x8.1 mat=Metal piezas=1
    City Props Pack/Newspaper_Stand_01_A [Model] talla=2.5x4.7x2.7 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Newspaper_Stand_01_A/glass [MeshPart] talla=0.1x1.3x1.6 mat=Glass MeshId=rbxassetid://5951809925 piezas=1 MeshPart=1
      City Props Pack/Newspaper_Stand_01_A/Newspaper_Stand_01_A [MeshPart] talla=2.5x4.7x2.7 mat=Plastic MeshId=rbxassetid://5951810126 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Newspaper_Stand_01_B [Model] talla=2.5x4.7x2.7 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Newspaper_Stand_01_B/glass [MeshPart] talla=0.1x1.3x1.6 mat=Glass MeshId=rbxassetid://5951809925 piezas=1 MeshPart=1
      City Props Pack/Newspaper_Stand_01_B/Newspaper_Stand_01_A [MeshPart] talla=2.5x4.7x2.7 mat=Plastic MeshId=rbxassetid://5951810126 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Newspaper_Stand_01_C [Model] talla=2.5x4.7x2.7 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Newspaper_Stand_01_C/glass [MeshPart] talla=0.1x1.3x1.6 mat=Glass MeshId=rbxassetid://5951809925 piezas=1 MeshPart=1
      City Props Pack/Newspaper_Stand_01_C/Newspaper_Stand_01_A [MeshPart] talla=2.5x4.7x2.7 mat=Plastic MeshId=rbxassetid://5951810126 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Newspaper_Stand_01_D [Model] talla=2.5x4.7x2.7 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Newspaper_Stand_01_D/glass [MeshPart] talla=0.1x1.3x1.6 mat=Glass MeshId=rbxassetid://5951809925 piezas=1 MeshPart=1
      City Props Pack/Newspaper_Stand_01_D/Newspaper_Stand_01_A [MeshPart] talla=2.5x4.7x2.7 mat=Plastic MeshId=rbxassetid://5951810126 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Pedestal_01_A [Model] talla=12.3x19.6x12.3 piezas=2 MeshPart=2 SurfaceAppearance=1
      City Props Pack/Pedestal_01_A/Pedestal_01_A [MeshPart] talla=12.3x12.8x12.3 mat=Plastic MeshId=rbxassetid://5850377817 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Pedestal_01_A/Tilt_01 [MeshPart] talla=7.3x7.3x2.7 mat=Concrete MeshId=rbxassetid://5947504421 piezas=1 MeshPart=1
    City Props Pack/PlanterBase_01 [Model] talla=3.8x3.6x3.7 piezas=10 MeshPart=10 SurfaceAppearance=10
      City Props Pack/PlanterBase_01/PlanterBase [MeshPart] talla=3.1x2.6x3.1 mat=Plastic MeshId=rbxassetid://5644748500 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/PlanterBase_01/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Planter_Rectangle_01_A [Model] talla=9.9x3.4x4.2 piezas=10 MeshPart=10 SurfaceAppearance=10
      City Props Pack/Planter_Rectangle_01_A/Planter_Rectangle_01_A [MeshPart] talla=9.0x2.6x3.0 mat=Plastic MeshId=rbxassetid://5795981297 piezas=10 MeshPart=10 SurfaceAppearance=10
    City Props Pack/Planter_Round_01_A [Model] talla=9.7x5.4x9.7 piezas=10 MeshPart=10 SurfaceAppearance=10
      City Props Pack/Planter_Round_01_A/Planter_Round_01_A [MeshPart] talla=9.7x4.5x9.7 mat=Plastic MeshId=rbxassetid://5790566532 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Round_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Planter_Round_01_A [Model] talla=3.8x3.3x3.8 piezas=6 MeshPart=6 SurfaceAppearance=6
      City Props Pack/Planter_Round_01_A/Planter_Round [MeshPart] talla=3.7x2.5x3.7 mat=Plastic MeshId=rbxassetid://5790566532 piezas=6 MeshPart=6 SurfaceAppearance=6
    City Props Pack/Planter_Square_01_A [Model] talla=9.0x3.6x6.9 piezas=10 MeshPart=10 SurfaceAppearance=10
      City Props Pack/Planter_Square_01_A/Planter_Square_01_A [MeshPart] talla=9.0x2.6x6.8 mat=Plastic MeshId=rbxassetid://5849819675 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=0.7x1.5x0.7 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Planter_Square_01_A/Flower [MeshPart] talla=1.7x1.0x2.0 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Powerline_01_A [Model] talla=64.0x161.7x62.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Powerline_01_A/Powerline_01_A [MeshPart] talla=64.0x161.7x62.5 mat=Plastic MeshId=rbxassetid://6309370861 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Railing_01_A [Model] talla=1.1x5.7x22.9 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Props Pack/Railing_01_A/Railing_Post_01_A [MeshPart] talla=1.1x5.7x1.1 mat=Plastic MeshId=rbxassetid://5894211246 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Railing_01_A/Railing_Post_01_A [MeshPart] talla=1.1x5.7x1.1 mat=Plastic MeshId=rbxassetid://5894211246 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Railing_01_A/Railing_Bars_01_A [MeshPart] talla=0.3x3.4x21.7 mat=Plastic MeshId=rbxassetid://5894145676 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/StreeBarrel_01_A [Model] talla=3.4x3.8x3.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/StreeBarrel_01_A/Street Barrel [MeshPart] talla=3.4x3.8x3.4 mat=Plastic MeshId=rbxassetid://5644650517 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/StreetLamp_Small_Var01 [Model] talla=1.1x5.0x1.1 piezas=2 MeshPart=2
      City Props Pack/StreetLamp_Small_Var01/Pole [MeshPart] talla=1.1x5.0x1.1 mat=Metal MeshId=rbxassetid://5263095549 piezas=1 MeshPart=1
      City Props Pack/StreetLamp_Small_Var01/Light [MeshPart] talla=0.8x0.6x0.8 mat=Metal MeshId=rbxassetid://5263095385 piezas=1 MeshPart=1
    City Props Pack/StreetLightPole_01_A [Model] talla=9.9x35.3x1.8 piezas=6 MeshPart=6
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Cylinder035 [MeshPart] talla=0.1x1.0x0.1 mat=Metal MeshId=rbxassetid://5356592944 piezas=1 MeshPart=1
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Line001 [MeshPart] talla=8.6x2.0x0.2 mat=Metal MeshId=rbxassetid://5356592795 piezas=1 MeshPart=1
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Object092 [MeshPart] talla=1.3x1.1x1.3 mat=Metal MeshId=rbxassetid://5356593007 piezas=1 MeshPart=1
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Sphere001 [MeshPart] talla=1.2x2.0x1.2 mat=Glass MeshId=rbxassetid://5356593073 piezas=1 MeshPart=1
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Street_Light_Tall004 [MeshPart] talla=1.8x34.6x1.8 mat=Metal MeshId=rbxassetid://5356592521 piezas=1 MeshPart=1
      City Props Pack/StreetLightPole_01_A/Meshes/Traffic_Light_Frame_Street_Light_Tall007 [MeshPart] talla=0.6x0.9x0.6 mat=Neon MeshId=rbxassetid://5356592878 piezas=1 MeshPart=1
    City Props Pack/Telephone_Pole_01_A [Model] talla=12.8x34.9x3.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Telephone_Pole_01_A/Telephone_Pole_01_A [MeshPart] talla=12.8x34.9x3.5 mat=Plastic MeshId=rbxassetid://5820968209 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Props Pack/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Props Pack/Traffic_Light_01/Backing [MeshPart] talla=1.0x4.8x18.8 mat=Plastic MeshId=rbxassetid://6313622362 piezas=1 MeshPart=1
      City Props Pack/Traffic_Light_01/Support [MeshPart] talla=0.4x3.8x17.3 mat=Plastic MeshId=rbxassetid://6313622585 piezas=1 MeshPart=1
      City Props Pack/Traffic_Light_01/Frame [MeshPart] talla=6.8x22.3x36.1 mat=Plastic MeshId=rbxassetid://6313622789 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Traffic_Light_01/Brackets [MeshPart] talla=1.3x1.1x17.6 mat=Plastic MeshId=rbxassetid://6313622903 piezas=1 MeshPart=1
      City Props Pack/Traffic_Light_01/Lights [Model] talla=0.1x4.2x18.0 piezas=6 MeshPart=6
      City Props Pack/Traffic_Light_01/BASE [Part] talla=2.0x2.0x2.0 mat=Plastic piezas=1
      City Props Pack/Traffic_Light_01/LightStateChanger [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
      City Props Pack/Traffic_Light_01/Signage [Model] talla=4.1x2.0x4.1 piezas=2
    City Props Pack/Traffic_Light_02 [Model] talla=5.1x22.6x3.9 piezas=7 MeshPart=5 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Props Pack/Traffic_Light_02/Backing [MeshPart] talla=1.8x4.8x1.0 mat=Plastic MeshId=rbxassetid://6313602333 piezas=1 MeshPart=1
      City Props Pack/Traffic_Light_02/Base [MeshPart] talla=4.9x22.1x3.5 mat=Plastic MeshId=rbxassetid://6313602449 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Props Pack/Traffic_Light_02/Lights [Model] talla=1.0x4.2x0.1 piezas=3 MeshPart=3
      City Props Pack/Traffic_Light_02/BASE [Part] talla=2.0x2.0x2.0 mat=Plastic piezas=1
      City Props Pack/Traffic_Light_02/Signage [Model] talla=2.0x2.0x0.4 piezas=1
      City Props Pack/Traffic_Light_02/LightStateChanger [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
```

</details>

## 6432233485 — City Road Pack (Roblox)

Carga con `LoadAsset`. Estructura: `Model` (contenedor de LoadAsset) → `Folder` del pack → modelos sueltos.

### Modelos de primer y segundo nivel

| Ruta (dentro del contenedor) | Clase | Talla (studs) | Contenido |
|---|---|---|---|
| `City Road Pack` | Folder | 661.7×90.1×526.9 | piezas=230 MeshPart=196 SurfaceAppearance=104 Decal/Texture=4 ⚠SCRIPTS=10 |
| `City Road Pack/Crosswalk_01_B` | Model | 13.0×0.0×19.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Manhole_Roblox_01_A` | Model | 7.5×0.0×7.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_DL_Turn_01_A` | Model | 120.0×1.7×120.0 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `City Road Pack/Road_DL_Turn_02_A` | Model | 160.0×1.7×160.0 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `City Road Pack/Road_Intersection_01_A` | Model | 123.3×23.8×124.1 | piezas=65 MeshPart=53 SurfaceAppearance=17 ⚠SCRIPTS=4 |
| `City Road Pack/Road_Intersection_02_A` | Model | 121.6×23.8×61.7 | piezas=33 MeshPart=27 SurfaceAppearance=9 ⚠SCRIPTS=2 |
| `City Road Pack/Road_Intersection_03_A` | Model | 60.0×23.8×61.6 | piezas=17 MeshPart=14 SurfaceAppearance=5 ⚠SCRIPTS=1 |
| `City Road Pack/Road_Intersection_FourWay_01_A` | Model | 81.8×23.8×81.7 | piezas=35 MeshPart=29 SurfaceAppearance=11 ⚠SCRIPTS=2 |
| `City Road Pack/Road_Intersection_T_01_A` | Model | 60.0×23.8×81.8 | piezas=19 MeshPart=16 SurfaceAppearance=7 ⚠SCRIPTS=1 |
| `City Road Pack/Road_Patch_02_A` | Model | 29.3×0.0×9.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_Patch_03_A` | Model | 7.9×0.1×12.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_Patch_04_A` | Model | 9.2×0.1×12.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_Turn_01_A` | Model | 80.0×1.7×80.0 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Road Pack/Road_Turn_02_A` | Model | 120.0×1.7×120.0 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Road Pack/Road_Turn_03_A` | Model | 160.0×1.7×160.0 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Road Pack/Road_Turn_45_01_A` | Model | 56.6×1.2×80.0 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Road Pack/Road_Turn_45_02_A` | Model | 91.7×1.2×84.9 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `City Road Pack/Road_Turn_45_03_A` | Model | 120.0×1.2×84.9 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `City Road Pack/RobloxBillboard` | Model | 129.1×89.3×47.0 | piezas=2 MeshPart=2 |
| `City Road Pack/StreetWear_01` | Model | 35.6×0.1×16.7 | piezas=1 Decal/Texture=1 |
| `City Road Pack/StreetWear_02` | Model | 25.3×0.1×25.8 | piezas=1 Decal/Texture=1 |
| `City Road Pack/StreetWear_03` | Model | 20.2×0.1×23.0 | piezas=1 Decal/Texture=1 |
| `City Road Pack/StreetWear_04` | Model | 15.5×0.1×11.4 | piezas=1 Decal/Texture=1 |
| `City Road Pack/Utility_Cover_01` | Model | 9.9×0.1×6.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Utility_Cover_02` | Model | 3.3×0.1×4.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Utility_Cover_03` | Model | 2.8×0.1×3.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Utility_Cover_04` | Model | 2.4×0.1×2.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Utility_Cover_05` | Model | 20.1×0.0×10.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_01_A` | MeshPart | 40.0×1.0×40.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_02_A` | MeshPart | 40.0×1.0×40.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_03_A` | MeshPart | 40.0×1.0×40.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_03_B` | MeshPart | 40.0×1.0×40.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Road_03_C` | MeshPart | 40.0×1.0×40.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_01_A` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_01_B` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_01_C` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_02_A` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_02_B` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_02_C` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_03_A` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_03_B` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_03_C` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_04_A` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_04_B` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_04_C` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `City Road Pack/Sidewalk_Corner_01_A` | MeshPart | 20.0×0.7×20.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |

<details><summary>Árbol completo (3 niveles)</summary>

```text
Model [Model] talla=526.9x90.1x661.7 piezas=230 MeshPart=196 SurfaceAppearance=104 Decal/Texture=4 ⚠SCRIPTS=10
  City Road Pack [Folder] talla=661.7x90.1x526.9 piezas=230 MeshPart=196 SurfaceAppearance=104 Decal/Texture=4 ⚠SCRIPTS=10
    City Road Pack/Crosswalk_01_B [Model] talla=13.0x0.0x19.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Crosswalk_01_B/Crosswalk_01_B [MeshPart] talla=13.0x0.1x19.9 mat=Plastic MeshId=rbxassetid://5828776391 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Manhole_Roblox_01_A [Model] talla=7.5x0.0x7.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Manhole_Roblox_01_A/Manhole_Roblox_01_A [MeshPart] talla=7.5x0.1x7.5 mat=Plastic MeshId=rbxassetid://5727367977 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_DL_Turn_01_A [Model] talla=120.0x1.7x120.0 piezas=4 MeshPart=4 SurfaceAppearance=4
      City Road Pack/Road_DL_Turn_01_A/Road_Turn_01_B [MeshPart] talla=100.0x1.0x100.0 mat=Plastic MeshId=rbxassetid://6333528681 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_01_A/Sidewalk_Turn_01_A [MeshPart] talla=120.0x0.7x120.0 mat=Plastic MeshId=rbxassetid://6364061864 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_01_A/Road_Turn_01_A [MeshPart] talla=60.0x1.0x60.0 mat=Plastic MeshId=rbxassetid://6331962977 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_DL_Turn_02_A [Model] talla=160.0x1.7x160.0 piezas=4 MeshPart=4 SurfaceAppearance=4
      City Road Pack/Road_DL_Turn_02_A/Road_02_A [MeshPart] talla=100.0x1.0x100.0 mat=Plastic MeshId=rbxassetid://6375600418 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_02_A/Sidewalk_Turn_02_A [MeshPart] talla=60.0x0.7x60.0 mat=Plastic MeshId=rbxassetid://6364039435 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_02_A/Road_02_B [MeshPart] talla=140.0x1.0x140.0 mat=Plastic MeshId=rbxassetid://6375492646 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_DL_Turn_02_A/Sidewalk_Turn_02_B [MeshPart] talla=160.0x0.7x160.0 mat=Plastic MeshId=rbxassetid://6375377375 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Intersection_01_A [Model] talla=123.3x23.8x124.1 piezas=65 MeshPart=53 SurfaceAppearance=17 ⚠SCRIPTS=4
      City Road Pack/Road_Intersection_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_01_A/Road_01_A [MeshPart] talla=120.0x1.0x120.0 mat=Plastic MeshId=rbxassetid://6312443153 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_01_A/Crosswalks [Folder] talla=118.8x0.1x118.6 piezas=8 MeshPart=8 SurfaceAppearance=8
      City Road Pack/Road_Intersection_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
    City Road Pack/Road_Intersection_02_A [Model] talla=121.6x23.8x61.7 piezas=33 MeshPart=27 SurfaceAppearance=9 ⚠SCRIPTS=2
      City Road Pack/Road_Intersection_02_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Road_01_A [MeshPart] talla=120.0x1.0x60.0 mat=Plastic MeshId=rbxassetid://6312564242 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_02_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_02_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
    City Road Pack/Road_Intersection_03_A [Model] talla=60.0x23.8x61.6 piezas=17 MeshPart=14 SurfaceAppearance=5 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_03_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_03_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_03_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_03_A/Road_01_A [MeshPart] talla=60.0x1.0x60.0 mat=Plastic MeshId=rbxassetid://6312985985 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_03_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
    City Road Pack/Road_Intersection_FourWay_01_A [Model] talla=81.8x23.8x81.7 piezas=35 MeshPart=29 SurfaceAppearance=11 ⚠SCRIPTS=2
      City Road Pack/Road_Intersection_FourWay_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Road_02_A [MeshPart] talla=80.0x1.0x80.0 mat=Plastic MeshId=rbxassetid://6317381940 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_FourWay_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_FourWay_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
    City Road Pack/Road_Intersection_T_01_A [Model] talla=60.0x23.8x81.8 piezas=19 MeshPart=16 SurfaceAppearance=7 ⚠SCRIPTS=1
      City Road Pack/Road_Intersection_T_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Road_02_A [MeshPart] talla=60.0x1.0x80.0 mat=Plastic MeshId=rbxassetid://6332360877 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Crosswalk_01_A [MeshPart] talla=13.3x0.1x38.4 mat=Plastic MeshId=rbxassetid://5828509126 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Intersection_T_01_A/Traffic_Light_01 [Model] talla=36.1x22.8x6.8 piezas=13 MeshPart=10 SurfaceAppearance=1 ⚠SCRIPTS=1
    City Road Pack/Road_Patch_02_A [Model] talla=29.3x0.0x9.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Patch_02_A/Road_Patch_02_A [MeshPart] talla=29.3x0.1x9.9 mat=Plastic MeshId=rbxassetid://5727368770 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Patch_03_A [Model] talla=7.9x0.1x12.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Patch_03_A/Road_Patch_03_A [MeshPart] talla=7.9x0.1x12.9 mat=Plastic MeshId=rbxassetid://5727369121 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Patch_04_A [Model] talla=9.2x0.1x12.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Patch_04_A/Road_Patch_04_A [MeshPart] talla=9.2x0.1x12.9 mat=Plastic MeshId=rbxassetid://5727369620 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_01_A [Model] talla=80.0x1.7x80.0 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Road Pack/Road_Turn_01_A/Road_Turn_01_A [MeshPart] talla=60.0x1.0x60.0 mat=Plastic MeshId=rbxassetid://6331962977 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_01_A/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_01_A/Sidewalk_Turn_01_A [MeshPart] talla=80.0x0.7x80.0 mat=Plastic MeshId=rbxassetid://6346885945 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_02_A [Model] talla=120.0x1.7x120.0 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Road Pack/Road_Turn_02_A/Road_02_A [MeshPart] talla=100.0x1.0x100.0 mat=Plastic MeshId=rbxassetid://6333528681 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_02_A/Sidewalk_Turn_02_B [MeshPart] talla=120.0x0.7x120.0 mat=Plastic MeshId=rbxassetid://6364061864 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_02_A/Sidewalk_Turn_02_A [MeshPart] talla=60.0x0.7x60.0 mat=Plastic MeshId=rbxassetid://6364039435 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_03_A [Model] talla=160.0x1.7x160.0 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Road Pack/Road_Turn_03_A/Sidewalk_Turn_03_A [MeshPart] talla=100.0x0.7x100.0 mat=Plastic MeshId=rbxassetid://6375377000 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_03_A/Road_03_A [MeshPart] talla=140.0x1.0x140.0 mat=Plastic MeshId=rbxassetid://6375492646 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_03_A/Sidewalk_Turn_03_B [MeshPart] talla=160.0x0.7x160.0 mat=Plastic MeshId=rbxassetid://6375377375 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_45_01_A [Model] talla=56.6x1.2x80.0 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Road Pack/Road_Turn_45_01_A/Sidewalk_Turn_45_01_B [MeshPart] talla=56.6x0.7x37.6 mat=Plastic MeshId=rbxassetid://6364465919 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_01_A/Road_Turn_45_01_A [MeshPart] talla=45.9x0.5x42.5 mat=Plastic MeshId=rbxassetid://6346695363 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_01_A/Sidewalk_Turn_45_01_A [MeshPart] talla=20.0x0.7x14.1 mat=Plastic MeshId=rbxassetid://6364406113 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_45_02_A [Model] talla=91.7x1.2x84.9 piezas=3 MeshPart=3 SurfaceAppearance=3
      City Road Pack/Road_Turn_45_02_A/Sidewalk_Turn_45_02_B [MeshPart] talla=49.2x0.7x84.9 mat=Plastic MeshId=rbxassetid://6364419945 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_02_A/Road_Turn_45_02_A [MeshPart] talla=57.6x0.5x70.8 mat=Plastic MeshId=rbxassetid://6346728772 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_02_A/Sidewalk_Turn_45_02_A [MeshPart] talla=31.7x0.7x42.5 mat=Plastic MeshId=rbxassetid://6364392896 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_Turn_45_03_A [Model] talla=120.0x1.2x84.9 piezas=4 MeshPart=4 SurfaceAppearance=4
      City Road Pack/Road_Turn_45_03_A/Sidewalk_Turn_45_02_B [MeshPart] talla=49.2x0.7x84.9 mat=Plastic MeshId=rbxassetid://6364419945 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_03_A/Sidewalk_Turn_45_01_A [MeshPart] talla=20.0x0.7x14.1 mat=Plastic MeshId=rbxassetid://6364406113 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_03_A/Road_Turn_45_02_A [MeshPart] talla=57.6x0.5x70.8 mat=Plastic MeshId=rbxassetid://6346374528 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Road_Turn_45_03_A/Road_Turn_45_01_A [MeshPart] talla=45.9x0.5x42.5 mat=Plastic MeshId=rbxassetid://6346374460 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/RobloxBillboard [Model] talla=129.1x89.3x47.0 piezas=2 MeshPart=2
      City Road Pack/RobloxBillboard/SM_Prop_Billboard_Sign_05 [MeshPart] talla=122.2x59.1x3.4 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
      City Road Pack/RobloxBillboard/SM_Prop_Billboard_Roof_01 [MeshPart] talla=129.1x89.3x47.0 mat=Plastic MeshId=rbxassetid://2530844063 piezas=1 MeshPart=1
    City Road Pack/StreetWear_01 [Model] talla=35.6x0.1x16.7 piezas=1 Decal/Texture=1
      City Road Pack/StreetWear_01/Part [Part] talla=35.6x0.1x16.7 mat=Concrete piezas=1 Decal/Texture=1
    City Road Pack/StreetWear_02 [Model] talla=25.3x0.1x25.8 piezas=1 Decal/Texture=1
      City Road Pack/StreetWear_02/Part [Part] talla=25.3x0.1x25.8 mat=Concrete piezas=1 Decal/Texture=1
    City Road Pack/StreetWear_03 [Model] talla=20.2x0.1x23.0 piezas=1 Decal/Texture=1
      City Road Pack/StreetWear_03/Part [Part] talla=20.2x0.1x23.0 mat=Concrete piezas=1 Decal/Texture=1
    City Road Pack/StreetWear_04 [Model] talla=15.5x0.1x11.4 piezas=1 Decal/Texture=1
      City Road Pack/StreetWear_04/Part [Part] talla=15.5x0.1x11.4 mat=Concrete piezas=1 Decal/Texture=1
    City Road Pack/Utility_Cover_01 [Model] talla=9.9x0.1x6.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Utility_Cover_01/Meshes/sidewalk_utilitycover_01 [MeshPart] talla=9.9x0.1x6.3 mat=Plastic MeshId=rbxassetid://5726538765 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Utility_Cover_02 [Model] talla=3.3x0.1x4.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Utility_Cover_02/Meshes/sidewalk_utilitycover_02 [MeshPart] talla=3.3x0.1x4.7 mat=Plastic MeshId=rbxassetid://5726538331 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Utility_Cover_03 [Model] talla=2.8x0.1x3.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Utility_Cover_03/Meshes/sidewalk_utilitycover_03 [MeshPart] talla=2.8x0.1x3.6 mat=Plastic MeshId=rbxassetid://5726537843 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Utility_Cover_04 [Model] talla=2.4x0.1x2.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Utility_Cover_04/Meshes/sidewalk_utilitycover_04 [MeshPart] talla=2.4x0.1x2.4 mat=Plastic MeshId=rbxassetid://5726537446 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Utility_Cover_05 [Model] talla=20.1x0.0x10.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      City Road Pack/Utility_Cover_05/Meshes/sidewalk_utilitycover_05 [MeshPart] talla=20.1x0.1x10.1 mat=Plastic MeshId=rbxassetid://5726612832 piezas=1 MeshPart=1 SurfaceAppearance=1
    City Road Pack/Road_01_A [MeshPart] talla=40.0x1.0x40.0 mat=Plastic MeshId=rbxassetid://6282826785 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Road_02_A [MeshPart] talla=40.0x1.0x40.0 mat=Plastic MeshId=rbxassetid://6282826785 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Road_03_A [MeshPart] talla=40.0x1.0x40.0 mat=Plastic MeshId=rbxassetid://6282826785 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Road_03_B [MeshPart] talla=40.0x1.0x40.0 mat=Plastic MeshId=rbxassetid://6282826785 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Road_03_C [MeshPart] talla=40.0x1.0x40.0 mat=Plastic MeshId=rbxassetid://6282826785 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_01_B [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_01_C [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_02_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_02_B [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_02_C [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_03_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_03_B [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_03_C [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_04_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_04_B [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_04_C [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307820093 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    City Road Pack/Sidewalk_Corner_01_A [MeshPart] talla=20.0x0.7x20.0 mat=Plastic MeshId=rbxassetid://6307819654 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
```

</details>

## 6432306802 — Forest Pack (Roblox)

Carga con `LoadAsset`. Estructura: `Model` (contenedor de LoadAsset) → `Folder` del pack → modelos sueltos.

### Modelos de primer y segundo nivel

| Ruta (dentro del contenedor) | Clase | Talla (studs) | Contenido |
|---|---|---|---|
| `Forest Pack` | Folder | 413.9×299.8×351.2 | piezas=85 MeshPart=83 SurfaceAppearance=73 ⚠SCRIPTS=13 |
| `Forest Pack/BeechwoodSapling_Var01` | Model | 7.2×12.5×7.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/BeechwoodTreeLarge_Var01` | Model | 104.3×124.6×79.0 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Forest Pack/BeechwoodTree_Var01` | Model | 74.2×88.6×56.2 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Forest Pack/BeechwoodTree_Var02` | Model | 13.3×25.3×18.1 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/BeechwoodTree_Var03` | Model | 38.7×46.3×29.3 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Forest Pack/BeechwoodTree_Var03` | Model | 7.7×25.6×14.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/BranchVar01` | Model | 11.0×1.6×5.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/BroadLeafTree_Var01` | Model | 28.1×36.0×34.7 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/Butterfly_FlightPath01` | Model | 1.1×0.2×0.7 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Butterfly_FlightPath02` | Model | 1.1×0.2×0.7 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Butterfly_Idle01` | Model | 1.1×0.2×0.7 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/DenseLeafPatch` | Model | 12.6×0.5×15.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/DogwoodTree_Var01` | Model | 31.9×26.5×31.5 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/Dragonfly_Flight01` | Model | 1.3×0.4×0.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Forest Pack/Dragonfly_IdleFlight01` | Model | 1.3×0.4×0.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Forest Pack/Dragonfly_IdleFlight02` | Model | 1.3×0.4×0.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Forest Pack/DyingFern01` | Model | 6.2×3.1×6.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/FallenTree` | Model | 48.1×9.7×11.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/FallenTreeMossyVar01` | Model | 80.7×14.8×15.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/FernTallVar01` | Model | 23.6×14.7×23.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/Fern_Var01` | Model | 15.7×6.7×16.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/Fish_IdleSwim01` | Model | 0.4×0.9×2.4 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Fish_IdleSwim02` | Model | 0.4×0.9×2.4 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Fish_IdleSwim03` | Model | 0.4×0.9×2.4 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Fish_Jump01` | Model | 0.4×0.9×2.4 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Fish_Jump02` | Model | 0.4×0.9×2.4 | piezas=1 MeshPart=1 ⚠SCRIPTS=1 |
| `Forest Pack/Hawk_FlightPath01` | Model | 11.0×1.7×3.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Forest Pack/Hawk_FlightPath02` | Model | 11.0×1.7×3.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Forest Pack/LargeBoulder_Var01` | Model | 22.1×34.2×22.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/LargeBoulder_Var02` | Model | 37.8×58.4×37.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/MapleLeafTreeVar01` | Model | 47.0×32.4×44.7 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/MediumBoulderVar01` | Model | 28.5×19.7×14.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/MediumMossBoulder01` | Model | 9.8×9.1×7.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/MountainLaurelBush_Var01` | Model | 6.7×5.3×6.7 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/ParticleEffect-LeavesFalling01` | Model | 30.0×30.0×30.0 | piezas=1 |
| `Forest Pack/RedwoodTree-Var01` | Model | 54.2×128.9×52.8 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Forest Pack/RedwoodTreeLarge-Var01` | Model | 110.8×263.2×107.9 | piezas=8 MeshPart=8 SurfaceAppearance=8 |
| `Forest Pack/Redwood_Snowy01` | Model | 114.3×271.8×111.3 | piezas=3 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/Redwoodtree-LowLOD-Var01` | Model | 81.6×193.9×79.4 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Forest Pack/RhododendronVar01` | Model | 10.0×5.8×12.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/RhododendronVar02` | Model | 10.0×5.3×12.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Forest Pack/RobloxBillboard` | Model | 129.1×89.3×47.0 | piezas=2 MeshPart=2 |
| `Forest Pack/SmallRock01` | Model | 1.5×1.5×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/SmallRockGroupVar02` | Model | 3.7×0.6×4.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/SmallRockGroupVar03` | Model | 3.8×0.6×5.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/SmallRockVar04` | Model | 2.7×1.8×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/StickVar01` | Model | 0.7×0.3×4.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/StickVar03` | Model | 0.8×0.3×4.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/StickVar04` | Model | 0.5×0.2×3.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/StickVar05` | Model | 1.6×0.3×4.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/StickVar06` | Model | 0.8×0.4×3.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/TreeStump` | Model | 23.4×13.1×22.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/WildFlower01` | Model | 4.4×2.7×5.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/WildFlower03` | Model | 1.4×3.2×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/WildFlower04` | Model | 1.2×2.6×1.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/Wildflower02` | Model | 3.5×2.6×2.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Forest Pack/CloverPatch` | Model | 5.1×1.2×6.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |

<details><summary>Árbol completo (3 niveles)</summary>

```text
Model [Model] talla=414.0x295.0x347.4 piezas=85 MeshPart=83 SurfaceAppearance=73 ⚠SCRIPTS=13
  Forest Pack [Folder] talla=413.9x299.8x351.2 piezas=85 MeshPart=83 SurfaceAppearance=73 ⚠SCRIPTS=13
    Forest Pack/BeechwoodSapling_Var01 [Model] talla=7.2x12.5x7.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/BeechwoodSapling_Var01/Leaves [MeshPart] talla=7.2x7.9x7.3 mat=Plastic MeshId=rbxassetid://5547038810 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodSapling_Var01/Trunk [MeshPart] talla=4.6x12.1x3.7 mat=Plastic MeshId=rbxassetid://5547038847 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BeechwoodTreeLarge_Var01 [Model] talla=104.3x124.6x79.0 piezas=3 MeshPart=3 SurfaceAppearance=3
      Forest Pack/BeechwoodTreeLarge_Var01/Trunk [MeshPart] talla=72.2x116.8x59.5 mat=Plastic MeshId=rbxassetid://5547037961 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTreeLarge_Var01/Leaf [MeshPart] talla=104.3x88.9x79.0 mat=Plastic MeshId=rbxassetid://5547037928 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTreeLarge_Var01/Soil [MeshPart] talla=33.1x6.6x31.6 mat=Plastic MeshId=rbxassetid://5547037970 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BeechwoodTree_Var01 [Model] talla=74.2x88.6x56.2 piezas=3 MeshPart=3 SurfaceAppearance=3
      Forest Pack/BeechwoodTree_Var01/Trunk [MeshPart] talla=51.3x83.0x42.3 mat=Plastic MeshId=rbxassetid://5547037961 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var01/Leaf [MeshPart] talla=74.2x63.2x56.2 mat=Plastic MeshId=rbxassetid://5547037928 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var01/Soil [MeshPart] talla=23.5x4.7x22.5 mat=Plastic MeshId=rbxassetid://5547037970 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BeechwoodTree_Var02 [Model] talla=13.3x25.3x18.1 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/BeechwoodTree_Var02/Leaves [MeshPart] talla=13.3x18.5x18.1 mat=Plastic MeshId=rbxassetid://5547039418 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var02/Trunk [MeshPart] talla=6.5x21.6x12.3 mat=Plastic MeshId=rbxassetid://5547038724 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BeechwoodTree_Var03 [Model] talla=38.7x46.3x29.3 piezas=3 MeshPart=3 SurfaceAppearance=3
      Forest Pack/BeechwoodTree_Var03/Trunk [MeshPart] talla=26.8x43.4x22.1 mat=Plastic MeshId=rbxassetid://5547037961 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var03/Leaf [MeshPart] talla=38.7x33.0x29.3 mat=Plastic MeshId=rbxassetid://5547037928 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var03/Soil [MeshPart] talla=12.3x2.5x11.7 mat=Plastic MeshId=rbxassetid://5547037970 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BeechwoodTree_Var03 [Model] talla=7.7x25.6x14.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BeechwoodTree_Var03/Trunk [MeshPart] talla=7.7x25.6x14.6 mat=Plastic MeshId=rbxassetid://5547038724 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BranchVar01 [Model] talla=11.0x1.6x5.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BranchVar01/Branch [MeshPart] talla=11.0x1.6x5.2 mat=Plastic MeshId=rbxassetid://5547038642 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/BroadLeafTree_Var01 [Model] talla=28.1x36.0x34.7 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/BroadLeafTree_Var01/Leaf [MeshPart] talla=28.1x31.5x34.7 mat=Plastic MeshId=rbxassetid://5547038538 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/BroadLeafTree_Var01/Trunk [MeshPart] talla=23.1x33.8x28.7 mat=Plastic MeshId=rbxassetid://5547038547 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/Butterfly_FlightPath01 [Model] talla=1.1x0.2x0.7 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Butterfly_FlightPath01/InitialPoses [Folder] piezas=0
      Forest Pack/Butterfly_FlightPath01/GEO_Butterfly_01 [MeshPart] talla=1.1x0.2x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355549438 piezas=1 MeshPart=1
      Forest Pack/Butterfly_FlightPath01/AnimationController [AnimationController] piezas=0
      Forest Pack/Butterfly_FlightPath01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Butterfly_FlightPath02 [Model] talla=1.1x0.2x0.7 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Butterfly_FlightPath02/InitialPoses [Folder] piezas=0
      Forest Pack/Butterfly_FlightPath02/GEO_Butterfly_01 [MeshPart] talla=1.1x0.2x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355549438 piezas=1 MeshPart=1
      Forest Pack/Butterfly_FlightPath02/AnimationController [AnimationController] piezas=0
      Forest Pack/Butterfly_FlightPath02/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Butterfly_Idle01 [Model] talla=1.1x0.2x0.7 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Butterfly_Idle01/InitialPoses [Folder] piezas=0
      Forest Pack/Butterfly_Idle01/GEO_Butterfly_01 [MeshPart] talla=1.1x0.2x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355549438 piezas=1 MeshPart=1
      Forest Pack/Butterfly_Idle01/AnimationController [AnimationController] piezas=0
      Forest Pack/Butterfly_Idle01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/DenseLeafPatch [Model] talla=12.6x0.5x15.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/DenseLeafPatch/Dense Leaf patch [MeshPart] talla=12.6x0.5x15.6 mat=Plastic MeshId=rbxassetid://5000421150 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/DogwoodTree_Var01 [Model] talla=31.9x26.5x31.5 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/DogwoodTree_Var01/Meshes/Dogwood Trees 01_Leaf [MeshPart] talla=31.9x21.5x31.5 mat=Plastic MeshId=rbxassetid://5547038790 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/DogwoodTree_Var01/Meshes/Dogwood Trees 01_Trunk [MeshPart] talla=23.4x25.5x25.2 mat=Plastic MeshId=rbxassetid://5547038983 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/Dragonfly_Flight01 [Model] talla=1.3x0.4x0.7 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Forest Pack/Dragonfly_Flight01/InitialPoses [Folder] piezas=0
      Forest Pack/Dragonfly_Flight01/GEO_Dragonfly_01 [MeshPart] talla=1.3x0.4x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355653163 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Dragonfly_Flight01/AnimationController [AnimationController] piezas=0
      Forest Pack/Dragonfly_Flight01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Dragonfly_IdleFlight01 [Model] talla=1.3x0.4x0.7 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Forest Pack/Dragonfly_IdleFlight01/InitialPoses [Folder] piezas=0
      Forest Pack/Dragonfly_IdleFlight01/GEO_Dragonfly_01 [MeshPart] talla=1.3x0.4x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355653163 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Dragonfly_IdleFlight01/AnimationController [AnimationController] piezas=0
      Forest Pack/Dragonfly_IdleFlight01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Dragonfly_IdleFlight02 [Model] talla=1.3x0.4x0.7 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Forest Pack/Dragonfly_IdleFlight02/InitialPoses [Folder] piezas=0
      Forest Pack/Dragonfly_IdleFlight02/GEO_Dragonfly_01 [MeshPart] talla=1.3x0.4x0.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355653163 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Dragonfly_IdleFlight02/AnimationController [AnimationController] piezas=0
      Forest Pack/Dragonfly_IdleFlight02/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/DyingFern01 [Model] talla=6.2x3.1x6.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/DyingFern01/Leaves [MeshPart] talla=6.2x3.1x6.9 mat=Plastic MeshId=rbxassetid://5547038987 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/FallenTree [Model] talla=48.1x9.7x11.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/FallenTree/FallenTree [MeshPart] talla=48.1x9.7x11.2 mat=Plastic MeshId=rbxassetid://5547038757 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/FallenTreeMossyVar01 [Model] talla=80.7x14.8x15.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/FallenTreeMossyVar01/FallenTree [MeshPart] talla=80.7x14.8x15.6 mat=Plastic MeshId=rbxassetid://5547039339 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/FernTallVar01 [Model] talla=23.6x14.7x23.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/FernTallVar01/Fern_OuterLeaves [MeshPart] talla=23.6x14.7x23.4 mat=Plastic MeshId=rbxassetid://5548709970 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/Fern_Var01 [Model] talla=15.7x6.7x16.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Fern_Var01/FernLeavesOuter [MeshPart] talla=15.7x6.7x16.4 mat=Plastic MeshId=rbxassetid://5548364402 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/Fish_IdleSwim01 [Model] talla=0.4x0.9x2.4 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Fish_IdleSwim01/InitialPoses [Folder] piezas=0
      Forest Pack/Fish_IdleSwim01/GEO_Fish_01 [MeshPart] talla=0.4x0.9x2.4 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5383026959 piezas=1 MeshPart=1
      Forest Pack/Fish_IdleSwim01/AnimationController [AnimationController] piezas=0
      Forest Pack/Fish_IdleSwim01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Fish_IdleSwim02 [Model] talla=0.4x0.9x2.4 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Fish_IdleSwim02/InitialPoses [Folder] piezas=0
      Forest Pack/Fish_IdleSwim02/GEO_Fish_01 [MeshPart] talla=0.4x0.9x2.4 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5383026959 piezas=1 MeshPart=1
      Forest Pack/Fish_IdleSwim02/AnimationController [AnimationController] piezas=0
      Forest Pack/Fish_IdleSwim02/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Fish_IdleSwim03 [Model] talla=0.4x0.9x2.4 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Fish_IdleSwim03/InitialPoses [Folder] piezas=0
      Forest Pack/Fish_IdleSwim03/GEO_Fish_01 [MeshPart] talla=0.4x0.9x2.4 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5383026959 piezas=1 MeshPart=1
      Forest Pack/Fish_IdleSwim03/AnimationController [AnimationController] piezas=0
      Forest Pack/Fish_IdleSwim03/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Fish_Jump01 [Model] talla=0.4x0.9x2.4 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Fish_Jump01/InitialPoses [Folder] piezas=0
      Forest Pack/Fish_Jump01/GEO_Fish_01 [MeshPart] talla=0.4x0.9x2.4 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5383026959 piezas=1 MeshPart=1
      Forest Pack/Fish_Jump01/AnimationController [AnimationController] piezas=0
      Forest Pack/Fish_Jump01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Fish_Jump02 [Model] talla=0.4x0.9x2.4 piezas=1 MeshPart=1 ⚠SCRIPTS=1
      Forest Pack/Fish_Jump02/InitialPoses [Folder] piezas=0
      Forest Pack/Fish_Jump02/GEO_Fish_01 [MeshPart] talla=0.4x0.9x2.4 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5383026959 piezas=1 MeshPart=1
      Forest Pack/Fish_Jump02/AnimationController [AnimationController] piezas=0
      Forest Pack/Fish_Jump02/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Hawk_FlightPath01 [Model] talla=11.0x1.7x3.7 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Forest Pack/Hawk_FlightPath01/InitialPoses [Folder] piezas=0
      Forest Pack/Hawk_FlightPath01/GEO_RedtailHawk_01 [MeshPart] talla=11.0x1.7x3.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355675841 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Hawk_FlightPath01/AnimationController [AnimationController] piezas=0
      Forest Pack/Hawk_FlightPath01/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/Hawk_FlightPath02 [Model] talla=11.0x1.7x3.7 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Forest Pack/Hawk_FlightPath02/InitialPoses [Folder] piezas=0
      Forest Pack/Hawk_FlightPath02/GEO_RedtailHawk_01 [MeshPart] talla=11.0x1.7x3.7 mat=Plastic MeshId=https://assetdelivery.roblox.com/v1/asset/?id=5355675841 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Hawk_FlightPath02/AnimationController [AnimationController] piezas=0
      Forest Pack/Hawk_FlightPath02/Script [Script] Enabled=true piezas=0 ⚠SCRIPTS=1
    Forest Pack/LargeBoulder_Var01 [Model] talla=22.1x34.2x22.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/LargeBoulder_Var01/LargeBoulder01 [MeshPart] talla=22.1x34.2x22.2 mat=Plastic MeshId=rbxassetid://5547037547 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/LargeBoulder_Var02 [Model] talla=37.8x58.4x37.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/LargeBoulder_Var02/LargeBoulder01 [MeshPart] talla=37.8x58.4x37.9 mat=Plastic MeshId=rbxassetid://5547037547 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/MapleLeafTreeVar01 [Model] talla=47.0x32.4x44.7 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/MapleLeafTreeVar01/OuterLeaves [MeshPart] talla=47.0x26.4x44.7 mat=Plastic MeshId=rbxassetid://6375188276 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/MapleLeafTreeVar01/Trunk [MeshPart] talla=38.5x31.8x35.7 mat=Plastic MeshId=rbxassetid://5553094293 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/MediumBoulderVar01 [Model] talla=28.5x19.7x14.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/MediumBoulderVar01/Meshes/Medium Boulder 01 [MeshPart] talla=28.5x19.7x14.7 mat=Plastic MeshId=rbxassetid://5547038797 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/MediumMossBoulder01 [Model] talla=9.8x9.1x7.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/MediumMossBoulder01/Medium Moss Boulder 01 [MeshPart] talla=9.8x9.1x7.6 mat=Plastic MeshId=rbxassetid://5547037341 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/MountainLaurelBush_Var01 [Model] talla=6.7x5.3x6.7 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/MountainLaurelBush_Var01/Trunk [MeshPart] talla=3.9x5.2x4.4 mat=Plastic MeshId=rbxassetid://5547038502 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/MountainLaurelBush_Var01/Leaf [MeshPart] talla=6.7x5.3x6.7 mat=Plastic MeshId=rbxassetid://5547038659 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/ParticleEffect-LeavesFalling01 [Model] talla=30.0x30.0x30.0 piezas=1
      Forest Pack/ParticleEffect-LeavesFalling01/ParticlFX-BeechwoodLeaves [Part] talla=30.0x30.0x30.0 mat=Plastic piezas=1
    Forest Pack/RedwoodTree-Var01 [Model] talla=54.2x128.9x52.8 piezas=3 MeshPart=3 SurfaceAppearance=3
      Forest Pack/RedwoodTree-Var01/OuterLeaves [MeshPart] talla=54.2x102.2x52.8 mat=Plastic MeshId=rbxassetid://5804646885 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTree-Var01/Soil [MeshPart] talla=22.3x3.7x22.3 mat=Plastic MeshId=rbxassetid://5804646490 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTree-Var01/Trunk [MeshPart] talla=54.2x119.5x48.9 mat=Plastic MeshId=rbxassetid://5804648905 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/RedwoodTreeLarge-Var01 [Model] talla=110.8x263.2x107.9 piezas=8 MeshPart=8 SurfaceAppearance=8
      Forest Pack/RedwoodTreeLarge-Var01/OuterLeaves [MeshPart] talla=110.8x208.7x107.9 mat=Plastic MeshId=rbxassetid://5804654625 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/Soil [MeshPart] talla=45.5x7.5x45.5 mat=Plastic MeshId=rbxassetid://5804654312 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/Trunk [MeshPart] talla=110.6x244.0x99.8 mat=Plastic MeshId=rbxassetid://5804654124 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/Fern_Var01 [Model] talla=15.7x6.7x16.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/Fern_Var01 [Model] talla=15.7x6.7x16.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/Fern_Var01 [Model] talla=15.7x6.7x16.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RedwoodTreeLarge-Var01/DogwoodTree_Var01 [Model] talla=31.9x26.5x31.5 piezas=2 MeshPart=2 SurfaceAppearance=2
    Forest Pack/Redwood_Snowy01 [Model] talla=114.3x271.8x111.3 piezas=3 MeshPart=2 SurfaceAppearance=2
      Forest Pack/Redwood_Snowy01/Redwood_Trees_Snowy01_Leaf [MeshPart] talla=114.3x215.4x111.3 mat=Plastic MeshId=rbxassetid://6033771527 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Redwood_Snowy01/Redwood_Trees_Snowy01_Trunk [MeshPart] talla=114.1x251.7x103.0 mat=Plastic MeshId=rbxassetid://6375186312 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Redwood_Snowy01/Anchor [Part] talla=5.4x1.4x2.7 mat=Plastic piezas=1
    Forest Pack/Redwoodtree-LowLOD-Var01 [Model] talla=81.6x193.9x79.4 piezas=3 MeshPart=3 SurfaceAppearance=3
      Forest Pack/Redwoodtree-LowLOD-Var01/InnerLeaves [MeshPart] talla=81.6x153.7x79.4 mat=Plastic MeshId=rbxassetid://6375186915 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Redwoodtree-LowLOD-Var01/OuterLeaves [MeshPart] talla=81.6x153.7x79.4 mat=Plastic MeshId=rbxassetid://6375186760 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Redwoodtree-LowLOD-Var01/Trunk [MeshPart] talla=81.5x179.7x73.5 mat=Plastic MeshId=rbxassetid://5553565544 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/RhododendronVar01 [Model] talla=10.0x5.8x12.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/RhododendronVar01/Trunk [MeshPart] talla=5.6x5.2x6.1 mat=Plastic MeshId=rbxassetid://5547038308 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RhododendronVar01/Leaves [MeshPart] talla=10.0x5.7x12.3 mat=Plastic MeshId=rbxassetid://5547038744 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/RhododendronVar02 [Model] talla=10.0x5.3x12.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Forest Pack/RhododendronVar02/Leaves [MeshPart] talla=10.0x5.1x12.3 mat=Plastic MeshId=rbxassetid://5547038674 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/RhododendronVar02/Trunk [MeshPart] talla=5.6x5.2x6.1 mat=Plastic MeshId=rbxassetid://5547038630 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/RobloxBillboard [Model] talla=129.1x89.3x47.0 piezas=2 MeshPart=2
      Forest Pack/RobloxBillboard/SM_Prop_Billboard_Roof_01 [MeshPart] talla=129.1x89.3x47.0 mat=Plastic MeshId=rbxassetid://2530844063 piezas=1 MeshPart=1
      Forest Pack/RobloxBillboard/SM_Prop_Billboard_Sign_05 [MeshPart] talla=122.2x59.1x3.4 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Forest Pack/SmallRock01 [Model] talla=1.5x1.5x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/SmallRock01/Small Rock 01 [MeshPart] talla=1.5x1.5x1.4 mat=Plastic MeshId=rbxassetid://5547038722 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/SmallRockGroupVar02 [Model] talla=3.7x0.6x4.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/SmallRockGroupVar02/SmallRockGrp02 [MeshPart] talla=3.7x0.6x4.8 mat=Plastic MeshId=rbxassetid://5547039064 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/SmallRockGroupVar03 [Model] talla=3.8x0.6x5.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/SmallRockGroupVar03/SmallRockGrp03 [MeshPart] talla=3.8x0.6x5.9 mat=Plastic MeshId=rbxassetid://5547039044 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/SmallRockVar04 [Model] talla=2.7x1.8x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/SmallRockVar04/Rock01 [MeshPart] talla=2.7x1.8x2.5 mat=Plastic MeshId=rbxassetid://5547038709 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/StickVar01 [Model] talla=0.7x0.3x4.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/StickVar01/Stick01 [MeshPart] talla=0.7x0.3x4.3 mat=Plastic MeshId=rbxassetid://5547038811 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/StickVar03 [Model] talla=0.8x0.3x4.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/StickVar03/Stick03 [MeshPart] talla=0.8x0.3x4.2 mat=Plastic MeshId=rbxassetid://5547038802 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/StickVar04 [Model] talla=0.5x0.2x3.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/StickVar04/Stick04 [MeshPart] talla=0.5x0.2x3.4 mat=Plastic MeshId=rbxassetid://5547038991 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/StickVar05 [Model] talla=1.6x0.3x4.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/StickVar05/Stick05 [MeshPart] talla=1.6x0.3x4.2 mat=Plastic MeshId=rbxassetid://5547038818 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/StickVar06 [Model] talla=0.8x0.4x3.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/StickVar06/Stick06 [MeshPart] talla=0.8x0.4x3.4 mat=Plastic MeshId=rbxassetid://5547038817 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/TreeStump [Model] talla=23.4x13.1x22.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/TreeStump/Stump [MeshPart] talla=23.4x13.1x22.5 mat=Plastic MeshId=rbxassetid://5547038687 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/WildFlower01 [Model] talla=4.4x2.7x5.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/WildFlower01/Flower [MeshPart] talla=4.4x2.7x5.3 mat=Plastic MeshId=rbxassetid://5547038806 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/WildFlower03 [Model] talla=1.4x3.2x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/WildFlower03/Flower [MeshPart] talla=1.4x3.2x1.4 mat=Plastic MeshId=rbxassetid://5547038995 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/WildFlower04 [Model] talla=1.2x2.6x1.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/WildFlower04/Flower [MeshPart] talla=1.2x2.6x1.2 mat=Plastic MeshId=rbxassetid://5547038838 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/Wildflower02 [Model] talla=3.5x2.6x2.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/Wildflower02/Flower [MeshPart] talla=3.5x2.6x2.9 mat=Plastic MeshId=rbxassetid://5547039023 piezas=1 MeshPart=1 SurfaceAppearance=1
    Forest Pack/CloverPatch [Model] talla=5.1x1.2x6.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      Forest Pack/CloverPatch/Clover Patch [MeshPart] talla=5.1x1.2x6.1 mat=Plastic MeshId=rbxassetid://5547037708 piezas=1 MeshPart=1 SurfaceAppearance=1
```

</details>

## 8916801819 — Realistic Street Lamp (SparkTehDog)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 8975295794 — Flower Pot (Noobbreaking)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 9271152246 — Realistic Tree (Nafica08)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 10131972958 — Realistic Tree (Mrwalter87)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 10562894034 — Palm Tree (Realistic) (Natalie_Clabo)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 10840661513 — Landscaping Pack – Duvall Drive (Roblox)

Carga con `LoadAsset`. Estructura: `Model` (contenedor de LoadAsset) → `Folder` del pack → modelos sueltos.

### Modelos de primer y segundo nivel (y lo que hay dentro de cada carpeta)

| Ruta (dentro del contenedor) | Clase | Talla (studs) | Contenido |
|---|---|---|---|
| `Landscaping Pack` | Folder | 246.9×48.2×229.1 | piezas=1814 MeshPart=1803 SurfaceAppearance=1541 Decal/Texture=58 ⚠SCRIPTS=4 |
| `Landscaping Pack/Bushes` | Folder | 124.2×10.9×20.8 | piezas=19 MeshPart=19 SurfaceAppearance=19 |
| `Landscaping Pack/Bushes/Snake Plant` | MeshPart | 2.5×4.4×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Bananna` | Model | 4.9×5.4×5.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Rubber_Plant_Red` | Model | 2.9×4.9×2.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Fern_Var01_Wet` | Model | 10.9×4.7×11.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/RhododendronVar02_Wet` | Model | 9.4×5.0×11.6 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Bushes/RhododendronVar01_Wet` | Model | 6.3×3.6×7.8 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Bushes/Garden_Herb_B` | Model | 2.2×1.8×2.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Rubber_Plant` | Model | 2.8×4.9×2.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Chinese_Evergreen` | Model | 3.8×3.2×3.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Philodendron` | Model | 3.8×3.4×3.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Garden_Herb_A` | Model | 1.9×1.1×2.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Bushes/Hedge_Bush_Long` | Model | 4.2×10.6×18.8 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Bushes/Hedge_Bush_Short` | Model | 4.3×10.5×9.4 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Bushes/MountainLaurelBush_Var01_Wet` | Model | 6.7×5.2×6.7 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Flowers` | Folder | 66.6×3.7×3.3 | piezas=15 MeshPart=15 SurfaceAppearance=15 |
| `Landscaping Pack/Flowers/Flowering_Shrub_05` | Model | 3.0×3.2×2.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flower_Plant_A_Med` | Model | 3.4×2.8×2.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flowering_Shrub_04` | Model | 3.8×3.6×3.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flowering_Shrub_03` | Model | 2.9×3.0×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flower_Plant_A_Lg` | Model | 3.9×2.5×2.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flower_Plant_A_Sm` | Model | 1.5×1.9×1.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/May_Night_Plant02` | Model | 1.5×2.7×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flowering_Shrub_02` | Model | 2.2×2.3×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flowering_Shrub_01` | Model | 1.3×1.8×1.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flowering_Shrub_06` | Model | 1.6×2.4×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/May_Night_Plant01` | Model | 1.2×2.2×1.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Marigold_A` | Model | 1.2×1.6×1.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Marigold_B` | Model | 1.1×1.6×1.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Garden_Herb_C` | Model | 1.2×2.7×1.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Flowers/Flower_Plant_C` | Model | 2.1×1.6×1.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks` | Folder | 63.7×10.6×31.1 | piezas=14 MeshPart=14 SurfaceAppearance=15 ⚠SCRIPTS=4 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_TriangleLarge_Floating` | Model | 7.5×1.6×6.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_large_floating` | Model | 3.0×7.1×3.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_Medium_floating` | Model | 1.9×5.2×2.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Angled` | Model | 2.6×1.4×1.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Rectangle` | Model | 4.3×1.4×1.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Rectangle` | Model | 2.8×1.4×1.9 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_AngledSlight` | Model | 3.9×1.5×1.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_AngledLarge` | Model | 7.5×1.5×3.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/HerbGardenBrick_TriangleLarge` | Model | 7.5×1.6×6.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_Small` | Model | 1.5×3.2×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_Medium` | Model | 1.9×5.2×2.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_large` | Model | 3.0×7.1×3.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Rocks|Bricks/Rock_Pillars_Small_floating` | Model | 1.5×3.2×1.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1 |
| `Landscaping Pack/Rocks|Bricks/Stone_EyeGarden_Shader_Geo` | MeshPart | 5.5×2.5×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens` | Folder | 186.8×8.8×78.7 | piezas=927 MeshPart=927 SurfaceAppearance=923 |
| `Landscaping Pack/Gardens/Circle_Brick` | Model | 27.1×1.8×26.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/Eye_Brick` | Model | 22.9×1.7×17.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/Pond_Foliage` | Model | 45.1×6.1×39.5 | piezas=221 MeshPart=221 SurfaceAppearance=221 |
| `Landscaping Pack/Gardens/Pupil_Brick` | Model | 5.6×1.4×5.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/HerbGardenBricks` | Model | 46.9×1.9×47.0 | piezas=92 MeshPart=92 SurfaceAppearance=92 |
| `Landscaping Pack/Gardens/Herb_garden` | Model | 35.6×3.7×35.3 | piezas=464 MeshPart=464 SurfaceAppearance=464 |
| `Landscaping Pack/Gardens/FlowerBedRight` | Model | 9.4×5.2×7.8 | piezas=6 MeshPart=6 SurfaceAppearance=6 |
| `Landscaping Pack/Gardens/GardenBedRounded` | Model | 8.0×2.6×9.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/GardenBedsSide` | Model | 6.7×2.5×9.3 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/FlowerBedLeft` | Model | 9.5×5.2×11.2 | piezas=12 MeshPart=12 SurfaceAppearance=12 |
| `Landscaping Pack/Gardens/GardenBedsSide` | Model | 6.7×2.5×9.3 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/GardenBedRounded` | Model | 8.0×2.6×9.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/FlowerBedSide2` | Model | 8.1×7.0×9.6 | piezas=16 MeshPart=16 SurfaceAppearance=16 |
| `Landscaping Pack/Gardens/FlowerBedSide1` | Model | 7.8×6.4×10.6 | piezas=12 MeshPart=12 SurfaceAppearance=12 |
| `Landscaping Pack/Gardens/GardenBedsSpiral` | Model | 22.2×5.9×23.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Gardens/FlowersSpiral` | Model | 22.6×6.4×18.8 | piezas=92 MeshPart=92 SurfaceAppearance=92 |
| `Landscaping Pack/Plants` | Folder | 45.9×2.6×6.5 | piezas=25 MeshPart=25 SurfaceAppearance=25 |
| `Landscaping Pack/Plants/WeedBunch_4` | MeshPart | 0.7×1.1×0.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/WeedBunch_3` | MeshPart | 0.4×1.6×0.3 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/WeedBunch_7` | MeshPart | 1.2×1.7×1.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/GrassBunch_2` | Model | 2.3×1.8×1.9 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `Landscaping Pack/Plants/CloverPatch` | Model | 4.2×1.0×5.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/Flower_Plant_B` | Model | 3.1×1.6×3.5 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Landscaping Pack/Plants/WeedsBunch_1` | MeshPart | 1.1×1.6×1.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/GrassBunch_3` | Model | 1.6×1.6×1.9 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `Landscaping Pack/Plants/GrassBunch_1` | Model | 1.6×1.6×2.2 | piezas=6 MeshPart=6 SurfaceAppearance=6 |
| `Landscaping Pack/Plants/WeedBunch_5` | MeshPart | 0.8×1.4×0.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/WeedBunch_6` | MeshPart | 1.2×1.6×1.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Plants/WeedBunch_2` | MeshPart | 1.3×1.1×1.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy` | Folder | 91.1×41.1×8.8 | piezas=14 MeshPart=14 SurfaceAppearance=14 |
| `Landscaping Pack/Ivy/Cards` | Folder |  | piezas=0 |
| `Landscaping Pack/Ivy/Ivy_C_Dead` | Model | 6.6×10.9×3.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_D_Dead` | Model | 2.4×8.1×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_E_Dead` | Model | 3.7×14.0×2.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_F_Dead` | Model | 3.8×6.4×1.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_G_Dead` | Model | 15.8×9.1×8.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_A_Dead` | Model | 12.9×20.1×3.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_B_Dead` | Model | 8.1×13.8×3.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_A` | Model | 12.9×20.1×3.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_C` | Model | 6.6×10.9×3.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_D` | Model | 2.4×8.1×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_E` | Model | 3.7×14.0×2.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_F` | Model | 3.8×6.4×1.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_G` | Model | 15.8×9.1×8.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Ivy/Ivy_B` | Model | 8.1×13.8×3.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Dried_Herbs` | Folder | 18.2×5.1×3.0 | piezas=38 MeshPart=38 SurfaceAppearance=30 |
| `Landscaping Pack/Dried_Herbs/HerbBunch2` | Model | 1.6×2.1×1.5 | piezas=7 MeshPart=7 SurfaceAppearance=7 |
| `Landscaping Pack/Dried_Herbs/HerbBunch3` | Model | 1.1×2.7×0.8 | piezas=7 MeshPart=7 SurfaceAppearance=7 |
| `Landscaping Pack/Dried_Herbs/HerbBunch4` | Model | 1.2×2.0×0.8 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `Landscaping Pack/Dried_Herbs/HerbDryingString` | Model | 8.4×4.9×1.9 | piezas=9 MeshPart=9 SurfaceAppearance=1 |
| `Landscaping Pack/Dried_Herbs/HerbBunch1` | Model | 1.8×3.9×4.1 | piezas=11 MeshPart=11 SurfaceAppearance=11 |
| `Landscaping Pack/GardeningTools` | Folder | 35.6×5.2×2.2 | piezas=14 MeshPart=14 SurfaceAppearance=7 |
| `Landscaping Pack/GardeningTools/Tool_Rake` | Model | 1.5×5.2×0.5 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/Tool_Garden` | Model | 0.9×5.2×0.8 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/Tool_Shovel` | Model | 1.0×5.2×0.5 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/BurlapBag` | Model | 2.1×2.3×1.3 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/BurlapBag_Side` | Model | 2.8×0.9×2.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/BurlapBag_Open` | Model | 1.9×1.6×1.4 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardeningTools/HandTrowel` | Model | 0.3×0.2×1.1 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers` | Folder | 57.0×9.9×17.1 | piezas=31 MeshPart=31 SurfaceAppearance=19 |
| `Landscaping Pack/Planters|Hangers/Planter_V1` | Model | 3.0×3.0×3.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Planter_V2` | Model | 3.0×2.7×3.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Planter_V3` | Model | 1.7×1.5×1.7 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Planter_Large` | Model | 0.9×0.8×0.9 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Planter_Med` | Model | 0.8×0.7×0.8 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Planter_XSm` | Model | 0.5×0.4×0.5 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/HangingPlanter_Lg` | Model | 2.4×5.5×2.4 | piezas=5 MeshPart=5 SurfaceAppearance=3 |
| `Landscaping Pack/Planters|Hangers/HangingPlanter_Sm` | Model | 2.2×5.1×2.2 | piezas=5 MeshPart=5 SurfaceAppearance=3 |
| `Landscaping Pack/Planters|Hangers/DryingRack` | Model | 2.7×8.0×2.8 | piezas=2 MeshPart=2 |
| `Landscaping Pack/Planters|Hangers/PlantMount_Holder` | Model | 0.2×2.2×2.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Tripod_Trellis` | Model | 4.5×8.1×3.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Planters|Hangers/Tripod_Trellis_Vines` | Model | 4.7×8.9×4.3 | piezas=5 MeshPart=5 SurfaceAppearance=5 |
| `Landscaping Pack/PottedPlants` | Folder | 70.1×18.3×28.7 | piezas=116 MeshPart=115 SurfaceAppearance=88 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_F` | Model | 14.4×17.9×12.9 | piezas=5 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_A` | Model | 8.7×12.1×8.6 | piezas=4 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_F` | Model | 8.5×12.9×7.8 | piezas=4 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/PottedPlant_RubberPlant` | Model | 2.8×6.5×2.8 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_G` | Model | 3.9×6.9×3.9 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_C` | Model | 3.8×5.1×3.3 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_Chinese_Evergreen` | Model | 3.7×4.9×3.8 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/FrontDoorPottedPlant` | Model | 3.8×5.3×3.3 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/PottedPlant_Bananna` | Model | 5.6×6.8×4.9 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_Snake` | Model | 2.5×6.0×2.5 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/PlanterHanging_Var2` | Model | 2.9×5.1×2.7 | piezas=10 MeshPart=10 SurfaceAppearance=8 |
| `Landscaping Pack/PottedPlants/PlanterHanging_Var1` | Model | 3.7×5.5×3.9 | piezas=10 MeshPart=10 SurfaceAppearance=8 |
| `Landscaping Pack/PottedPlants/Vase_A` | Model | 2.1×3.3×2.2 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_E` | Model | 1.7×3.9×1.7 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/PottedPlant_Dracaena` | Model | 3.8×7.5×3.1 | piezas=4 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_D` | Model | 3.0×2.3×3.7 | piezas=5 MeshPart=5 SurfaceAppearance=4 |
| `Landscaping Pack/PottedPlants/Planter_Ivy` | Model | 2.7×7.1×2.1 | piezas=11 MeshPart=11 SurfaceAppearance=10 |
| `Landscaping Pack/PottedPlants/Vase_w_Flowers_LG` | Model | 2.8×2.7×2.9 | piezas=3 MeshPart=3 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/Vase_w_Flowers` | Model | 2.0×3.0×1.8 | piezas=4 MeshPart=4 SurfaceAppearance=4 |
| `Landscaping Pack/PottedPlants/Planter_LargeV1` | Model | 0.9×1.7×0.9 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/SolariumPottedPlant_B` | Model | 2.9×4.4×2.5 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_LargeV2` | Model | 1.1×1.9×1.1 | piezas=4 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/Planter_Fern` | Model | 6.0×6.1×6.0 | piezas=4 MeshPart=4 SurfaceAppearance=3 |
| `Landscaping Pack/PottedPlants/Planter_MedV1` | Model | 0.8×1.2×0.8 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_MedV2` | Model | 0.8×1.5×0.8 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_Sm_V2` | Model | 0.6×1.1×0.6 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_XSm_V2` | Model | 0.5×0.6×0.5 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/PottedPlants/Planter_Sm_V1` | Model | 0.7×1.1×0.7 | piezas=3 MeshPart=3 SurfaceAppearance=2 |
| `Landscaping Pack/GardenBeds|Shelves` | Folder | 35.2×10.2×53.3 | piezas=435 MeshPart=435 SurfaceAppearance=253 |
| `Landscaping Pack/GardenBeds|Shelves/GardenBedRounded` | Model | 8.0×2.6×9.0 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardenBeds|Shelves/GardenBedsSide` | Model | 6.7×2.5×9.3 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/GardenBeds|Shelves/PottingBench` | Model | 8.6×7.3×6.2 | piezas=87 MeshPart=87 SurfaceAppearance=45 |
| `Landscaping Pack/GardenBeds|Shelves/PlantShelf2` | Model | 6.1×10.2×3.5 | piezas=163 MeshPart=163 SurfaceAppearance=100 |
| `Landscaping Pack/GardenBeds|Shelves/PlantShelf` | Model | 6.1×10.2×3.5 | piezas=181 MeshPart=181 SurfaceAppearance=106 |
| `Landscaping Pack/Outdoor_Statues` | Folder | 49.2×27.5×105.0 | piezas=52 MeshPart=49 SurfaceAppearance=44 Decal/Texture=25 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statue B` | Model | 8.7×18.1×4.1 | piezas=2 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_E` | Model | 15.0×10.1×3.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_C` | Model | 4.8×10.0×3.7 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_A` | Model | 10.7×13.8×11.1 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_D` | Model | 5.2×8.8×5.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_F` | Model | 17.2×12.9×4.0 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Outdoor_Statues/Occult_002` | MeshPart | 2.7×11.8×2.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Outdoor_Statues/Occult_Statues_G` | Model | 9.1×11.5×5.9 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Outdoor_Statues/Armillary_Small` | Model | 6.6×7.9×7.4 | piezas=12 MeshPart=12 SurfaceAppearance=11 |
| `Landscaping Pack/Outdoor_Statues/Armillary_Exterior` | Model | 26.2×27.5×26.2 | piezas=27 MeshPart=25 SurfaceAppearance=21 Decal/Texture=25 |
| `Landscaping Pack/Shed` | Folder | 17.5×16.7×29.8 | piezas=20 MeshPart=20 SurfaceAppearance=19 |
| `Landscaping Pack/Shed/Furniture_Backyard_DogHouse` | Model | 4.8×5.4×5.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Shed/Furniture_Backyard_Shed` | Model | 17.5×16.7×22.3 | piezas=18 MeshPart=18 SurfaceAppearance=17 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 44.1×21.3×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/Prop_FirewoodLogHolderShelf` | Model | 4.8×3.3×2.6 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Prop_FirewoodLogHolder` | Model | 2.4×2.0×2.3 | piezas=2 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Prop_FirewoodGrate` | Model | 3.3×2.9×2.2 | piezas=5 MeshPart=2 SurfaceAppearance=2 |
| `Landscaping Pack/Surfaces` | Folder | 48.8×0.5×57.1 | piezas=13 MeshPart=10 SurfaceAppearance=10 Decal/Texture=3 |
| `Landscaping Pack/Surfaces/DirtScattered_Large` | Model | 9.2×0.1×9.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/DirtScattered_Small` | Model | 4.4×0.1×4.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/LeafOverlay_Large_B` | Model | 9.0×0.1×6.8 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/PuddleLarge` | Model | 11.0×0.1×11.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/PuddleMedium` | Model | 8.0×0.1×8.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/PuddleSmall` | Model | 6.0×0.1×6.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/SaltScattered_Large` | Model | 9.2×0.1×9.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/SaltScattered_Small` | Model | 4.4×0.1×4.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/Leaves_Decal` | MeshPart | 5.0×0.1×5.0 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/LeafOverlay_Small_A` | Model | 4.7×0.1×4.6 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Surfaces/Decal_Scuff_01` | Model | 13.5×14.8×0.5 | piezas=1 Decal/Texture=1 |
| `Landscaping Pack/Surfaces/Decal_Scuff_01` | Model | 13.5×14.8×0.5 | piezas=1 Decal/Texture=1 |
| `Landscaping Pack/Surfaces/Decal_Scuff_01` | Model | 13.5×14.8×0.5 | piezas=1 Decal/Texture=1 |
| `Landscaping Pack/FirePit` | Model | 4.4×27.6×27.4 | piezas=47 MeshPart=46 SurfaceAppearance=43 |
| `Landscaping Pack/Fence_Porch` | Folder | 61.9×18.7×44.9 | piezas=16 MeshPart=16 SurfaceAppearance=11 Decal/Texture=30 |
| `Landscaping Pack/Fence_Porch/Driveway_Gate_Column` | Model | 3.1×14.8×3.1 | piezas=2 MeshPart=2 SurfaceAppearance=1 Decal/Texture=10 |
| `Landscaping Pack/Fence_Porch/Fence_A` | Model | 20.2×10.5×0.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Fence_A_Post` | Model | 0.4×10.5×0.4 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Yard_Wall` | Model | 20.1×12.8×2.5 | piezas=2 MeshPart=2 SurfaceAppearance=1 Decal/Texture=10 |
| `Landscaping Pack/Fence_Porch/Driveway_Gate` | Model | 20.3×16.4×3.1 | piezas=4 MeshPart=4 SurfaceAppearance=2 Decal/Texture=10 |
| `Landscaping Pack/Fence_Porch/Porch_Rail_Steps` | Model | 0.6×8.0×8.2 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Side_Steps_Dry` | Model | 17.6×10.3×36.4 | piezas=2 MeshPart=2 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Porch_Rail` | Model | 0.6×4.1×13.1 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Stone_Walkway_Shader_Wet_Geo` | MeshPart | 5.5×2.5×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/Fence_Porch/Brick_K_Wet_Shader_Geo` | MeshPart | 5.5×2.5×2.5 | piezas=1 MeshPart=1 SurfaceAppearance=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 16.5×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×3.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×2.0×0.0 | piezas=1 MeshPart=1 |
| `Landscaping Pack/RobloxBillboard` | Model | 15.7×2.0×0.0 | piezas=1 MeshPart=1 |

<details><summary>Árbol completo (3 niveles)</summary>

```text
Model [Model] talla=246.9x48.2x229.1 piezas=1814 MeshPart=1803 SurfaceAppearance=1541 Decal/Texture=58 ⚠SCRIPTS=4
  Landscaping Pack [Folder] talla=246.9x48.2x229.1 piezas=1814 MeshPart=1803 SurfaceAppearance=1541 Decal/Texture=58 ⚠SCRIPTS=4
    Landscaping Pack/Bushes [Folder] talla=124.2x10.9x20.8 piezas=19 MeshPart=19 SurfaceAppearance=19
      Landscaping Pack/Bushes/Snake Plant [MeshPart] talla=2.5x4.4x2.5 mat=Plastic MeshId=rbxassetid://9922370524 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Bananna [Model] talla=4.9x5.4x5.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Rubber_Plant_Red [Model] talla=2.9x4.9x2.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Fern_Var01_Wet [Model] talla=10.9x4.7x11.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/RhododendronVar02_Wet [Model] talla=9.4x5.0x11.6 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Bushes/RhododendronVar01_Wet [Model] talla=6.3x3.6x7.8 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Bushes/Garden_Herb_B [Model] talla=2.2x1.8x2.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Rubber_Plant [Model] talla=2.8x4.9x2.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Chinese_Evergreen [Model] talla=3.8x3.2x3.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Philodendron [Model] talla=3.8x3.4x3.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Garden_Herb_A [Model] talla=1.9x1.1x2.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Bushes/Hedge_Bush_Long [Model] talla=4.2x10.6x18.8 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Bushes/Hedge_Bush_Short [Model] talla=4.3x10.5x9.4 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Bushes/MountainLaurelBush_Var01_Wet [Model] talla=6.7x5.2x6.7 piezas=2 MeshPart=2 SurfaceAppearance=2
    Landscaping Pack/Flowers [Folder] talla=66.6x3.7x3.3 piezas=15 MeshPart=15 SurfaceAppearance=15
      Landscaping Pack/Flowers/Flowering_Shrub_05 [Model] talla=3.0x3.2x2.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flower_Plant_A_Med [Model] talla=3.4x2.8x2.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flowering_Shrub_04 [Model] talla=3.8x3.6x3.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flowering_Shrub_03 [Model] talla=2.9x3.0x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flower_Plant_A_Lg [Model] talla=3.9x2.5x2.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flower_Plant_A_Sm [Model] talla=1.5x1.9x1.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/May_Night_Plant02 [Model] talla=1.5x2.7x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flowering_Shrub_02 [Model] talla=2.2x2.3x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flowering_Shrub_01 [Model] talla=1.3x1.8x1.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flowering_Shrub_06 [Model] talla=1.6x2.4x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/May_Night_Plant01 [Model] talla=1.2x2.2x1.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Marigold_A [Model] talla=1.2x1.6x1.3 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Marigold_B [Model] talla=1.1x1.6x1.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Garden_Herb_C [Model] talla=1.2x2.7x1.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Flowers/Flower_Plant_C [Model] talla=2.1x1.6x1.8 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Rocks|Bricks [Folder] talla=63.7x10.6x31.1 piezas=14 MeshPart=14 SurfaceAppearance=15 ⚠SCRIPTS=4
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_TriangleLarge_Floating [Model] talla=7.5x1.6x6.4 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_large_floating [Model] talla=3.0x7.1x3.0 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_Medium_floating [Model] talla=1.9x5.2x2.0 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Angled [Model] talla=2.6x1.4x1.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Rectangle [Model] talla=4.3x1.4x1.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_Rectangle [Model] talla=2.8x1.4x1.9 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_AngledSlight [Model] talla=3.9x1.5x1.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_AngledLarge [Model] talla=7.5x1.5x3.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/HerbGardenBrick_TriangleLarge [Model] talla=7.5x1.6x6.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_Small [Model] talla=1.5x3.2x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_Medium [Model] talla=1.9x5.2x2.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_large [Model] talla=3.0x7.1x3.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Rocks|Bricks/Rock_Pillars_Small_floating [Model] talla=1.5x3.2x1.4 piezas=1 MeshPart=1 SurfaceAppearance=1 ⚠SCRIPTS=1
      Landscaping Pack/Rocks|Bricks/Stone_EyeGarden_Shader_Geo [MeshPart] talla=5.5x2.5x2.5 mat=Plastic MeshId=rbxassetid://8641990574 piezas=1 MeshPart=1 SurfaceAppearance=1
      (además: SurfaceAppearance×1)
    Landscaping Pack/Gardens [Folder] talla=186.8x8.8x78.7 piezas=927 MeshPart=927 SurfaceAppearance=923
      Landscaping Pack/Gardens/Circle_Brick [Model] talla=27.1x1.8x26.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Gardens/Eye_Brick [Model] talla=22.9x1.7x17.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Gardens/Pond_Foliage [Model] talla=45.1x6.1x39.5 piezas=221 MeshPart=221 SurfaceAppearance=221
      Landscaping Pack/Gardens/Pupil_Brick [Model] talla=5.6x1.4x5.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Gardens/HerbGardenBricks [Model] talla=46.9x1.9x47.0 piezas=92 MeshPart=92 SurfaceAppearance=92
      Landscaping Pack/Gardens/Herb_garden [Model] talla=35.6x3.7x35.3 piezas=464 MeshPart=464 SurfaceAppearance=464
      Landscaping Pack/Gardens/FlowerBedRight [Model] talla=9.4x5.2x7.8 piezas=6 MeshPart=6 SurfaceAppearance=6
      Landscaping Pack/Gardens/GardenBedRounded [Model] talla=8.0x2.6x9.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Gardens/GardenBedsSide [Model] talla=6.7x2.5x9.3 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Gardens/FlowerBedLeft [Model] talla=9.5x5.2x11.2 piezas=12 MeshPart=12 SurfaceAppearance=12
      Landscaping Pack/Gardens/GardenBedsSide [Model] talla=6.7x2.5x9.3 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Gardens/GardenBedRounded [Model] talla=8.0x2.6x9.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Gardens/FlowerBedSide2 [Model] talla=8.1x7.0x9.6 piezas=16 MeshPart=16 SurfaceAppearance=16
      Landscaping Pack/Gardens/FlowerBedSide1 [Model] talla=7.8x6.4x10.6 piezas=12 MeshPart=12 SurfaceAppearance=12
      Landscaping Pack/Gardens/GardenBedsSpiral [Model] talla=22.2x5.9x23.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Gardens/FlowersSpiral [Model] talla=22.6x6.4x18.8 piezas=92 MeshPart=92 SurfaceAppearance=92
    Landscaping Pack/Plants [Folder] talla=45.9x2.6x6.5 piezas=25 MeshPart=25 SurfaceAppearance=25
      Landscaping Pack/Plants/WeedBunch_4 [MeshPart] talla=0.7x1.1x0.7 mat=Plastic MeshId=rbxassetid://9424103477 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/WeedBunch_3 [MeshPart] talla=0.4x1.6x0.3 mat=Plastic MeshId=rbxassetid://9424103466 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/WeedBunch_7 [MeshPart] talla=1.2x1.7x1.1 mat=Plastic MeshId=rbxassetid://9424103465 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/GrassBunch_2 [Model] talla=2.3x1.8x1.9 piezas=4 MeshPart=4 SurfaceAppearance=4
      Landscaping Pack/Plants/CloverPatch [Model] talla=4.2x1.0x5.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/Flower_Plant_B [Model] talla=3.1x1.6x3.5 piezas=3 MeshPart=3 SurfaceAppearance=3
      Landscaping Pack/Plants/WeedsBunch_1 [MeshPart] talla=1.1x1.6x1.1 mat=Plastic MeshId=rbxassetid://9424103462 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/GrassBunch_3 [Model] talla=1.6x1.6x1.9 piezas=4 MeshPart=4 SurfaceAppearance=4
      Landscaping Pack/Plants/GrassBunch_1 [Model] talla=1.6x1.6x2.2 piezas=6 MeshPart=6 SurfaceAppearance=6
      Landscaping Pack/Plants/WeedBunch_5 [MeshPart] talla=0.8x1.4x0.8 mat=Plastic MeshId=rbxassetid://9424103473 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/WeedBunch_6 [MeshPart] talla=1.2x1.6x1.2 mat=Plastic MeshId=rbxassetid://9424103470 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Plants/WeedBunch_2 [MeshPart] talla=1.3x1.1x1.2 mat=Plastic MeshId=rbxassetid://9424103472 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Ivy [Folder] talla=91.1x41.1x8.8 piezas=14 MeshPart=14 SurfaceAppearance=14
      Landscaping Pack/Ivy/Cards [Folder] piezas=0
      Landscaping Pack/Ivy/Ivy_C_Dead [Model] talla=6.6x10.9x3.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_D_Dead [Model] talla=2.4x8.1x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_E_Dead [Model] talla=3.7x14.0x2.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_F_Dead [Model] talla=3.8x6.4x1.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_G_Dead [Model] talla=15.8x9.1x8.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_A_Dead [Model] talla=12.9x20.1x3.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_B_Dead [Model] talla=8.1x13.8x3.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_A [Model] talla=12.9x20.1x3.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_C [Model] talla=6.6x10.9x3.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_D [Model] talla=2.4x8.1x2.5 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_E [Model] talla=3.7x14.0x2.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_F [Model] talla=3.8x6.4x1.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_G [Model] talla=15.8x9.1x8.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Ivy/Ivy_B [Model] talla=8.1x13.8x3.1 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Dried_Herbs [Folder] talla=18.2x5.1x3.0 piezas=38 MeshPart=38 SurfaceAppearance=30
      Landscaping Pack/Dried_Herbs/HerbBunch2 [Model] talla=1.6x2.1x1.5 piezas=7 MeshPart=7 SurfaceAppearance=7
      Landscaping Pack/Dried_Herbs/HerbBunch3 [Model] talla=1.1x2.7x0.8 piezas=7 MeshPart=7 SurfaceAppearance=7
      Landscaping Pack/Dried_Herbs/HerbBunch4 [Model] talla=1.2x2.0x0.8 piezas=4 MeshPart=4 SurfaceAppearance=4
      Landscaping Pack/Dried_Herbs/HerbDryingString [Model] talla=8.4x4.9x1.9 piezas=9 MeshPart=9 SurfaceAppearance=1
      Landscaping Pack/Dried_Herbs/HerbBunch1 [Model] talla=1.8x3.9x4.1 piezas=11 MeshPart=11 SurfaceAppearance=11
    Landscaping Pack/GardeningTools [Folder] talla=35.6x5.2x2.2 piezas=14 MeshPart=14 SurfaceAppearance=7
      Landscaping Pack/GardeningTools/Tool_Rake [Model] talla=1.5x5.2x0.5 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/Tool_Garden [Model] talla=0.9x5.2x0.8 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/Tool_Shovel [Model] talla=1.0x5.2x0.5 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/BurlapBag [Model] talla=2.1x2.3x1.3 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/BurlapBag_Side [Model] talla=2.8x0.9x2.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/BurlapBag_Open [Model] talla=1.9x1.6x1.4 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardeningTools/HandTrowel [Model] talla=0.3x0.2x1.1 piezas=2 MeshPart=2 SurfaceAppearance=1
    Landscaping Pack/Planters|Hangers [Folder] talla=57.0x9.9x17.1 piezas=31 MeshPart=31 SurfaceAppearance=19
      Landscaping Pack/Planters|Hangers/Planter_V1 [Model] talla=3.0x3.0x3.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Planter_V2 [Model] talla=3.0x2.7x3.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Planter_V3 [Model] talla=1.7x1.5x1.7 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Planter_Large [Model] talla=0.9x0.8x0.9 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Planter_Med [Model] talla=0.8x0.7x0.8 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Planter_XSm [Model] talla=0.5x0.4x0.5 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/HangingPlanter_Lg [Model] talla=2.4x5.5x2.4 piezas=5 MeshPart=5 SurfaceAppearance=3
      Landscaping Pack/Planters|Hangers/HangingPlanter_Sm [Model] talla=2.2x5.1x2.2 piezas=5 MeshPart=5 SurfaceAppearance=3
      Landscaping Pack/Planters|Hangers/DryingRack [Model] talla=2.7x8.0x2.8 piezas=2 MeshPart=2
      Landscaping Pack/Planters|Hangers/PlantMount_Holder [Model] talla=0.2x2.2x2.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Tripod_Trellis [Model] talla=4.5x8.1x3.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Planters|Hangers/Tripod_Trellis_Vines [Model] talla=4.7x8.9x4.3 piezas=5 MeshPart=5 SurfaceAppearance=5
    Landscaping Pack/PottedPlants [Folder] talla=70.1x18.3x28.7 piezas=116 MeshPart=115 SurfaceAppearance=88
      Landscaping Pack/PottedPlants/SolariumPottedPlant_F [Model] talla=14.4x17.9x12.9 piezas=5 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/SolariumPottedPlant_A [Model] talla=8.7x12.1x8.6 piezas=4 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/SolariumPottedPlant_F [Model] talla=8.5x12.9x7.8 piezas=4 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/PottedPlant_RubberPlant [Model] talla=2.8x6.5x2.8 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/SolariumPottedPlant_G [Model] talla=3.9x6.9x3.9 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/SolariumPottedPlant_C [Model] talla=3.8x5.1x3.3 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_Chinese_Evergreen [Model] talla=3.7x4.9x3.8 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/FrontDoorPottedPlant [Model] talla=3.8x5.3x3.3 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/PottedPlant_Bananna [Model] talla=5.6x6.8x4.9 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_Snake [Model] talla=2.5x6.0x2.5 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/PlanterHanging_Var2 [Model] talla=2.9x5.1x2.7 piezas=10 MeshPart=10 SurfaceAppearance=8
      Landscaping Pack/PottedPlants/PlanterHanging_Var1 [Model] talla=3.7x5.5x3.9 piezas=10 MeshPart=10 SurfaceAppearance=8
      Landscaping Pack/PottedPlants/Vase_A [Model] talla=2.1x3.3x2.2 piezas=3 MeshPart=3 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/SolariumPottedPlant_E [Model] talla=1.7x3.9x1.7 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/PottedPlant_Dracaena [Model] talla=3.8x7.5x3.1 piezas=4 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/SolariumPottedPlant_D [Model] talla=3.0x2.3x3.7 piezas=5 MeshPart=5 SurfaceAppearance=4
      Landscaping Pack/PottedPlants/Planter_Ivy [Model] talla=2.7x7.1x2.1 piezas=11 MeshPart=11 SurfaceAppearance=10
      Landscaping Pack/PottedPlants/Vase_w_Flowers_LG [Model] talla=2.8x2.7x2.9 piezas=3 MeshPart=3 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/Vase_w_Flowers [Model] talla=2.0x3.0x1.8 piezas=4 MeshPart=4 SurfaceAppearance=4
      Landscaping Pack/PottedPlants/Planter_LargeV1 [Model] talla=0.9x1.7x0.9 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/SolariumPottedPlant_B [Model] talla=2.9x4.4x2.5 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_LargeV2 [Model] talla=1.1x1.9x1.1 piezas=4 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/Planter_Fern [Model] talla=6.0x6.1x6.0 piezas=4 MeshPart=4 SurfaceAppearance=3
      Landscaping Pack/PottedPlants/Planter_MedV1 [Model] talla=0.8x1.2x0.8 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_MedV2 [Model] talla=0.8x1.5x0.8 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_Sm_V2 [Model] talla=0.6x1.1x0.6 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_XSm_V2 [Model] talla=0.5x0.6x0.5 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/PottedPlants/Planter_Sm_V1 [Model] talla=0.7x1.1x0.7 piezas=3 MeshPart=3 SurfaceAppearance=2
    Landscaping Pack/GardenBeds|Shelves [Folder] talla=35.2x10.2x53.3 piezas=435 MeshPart=435 SurfaceAppearance=253
      Landscaping Pack/GardenBeds|Shelves/GardenBedRounded [Model] talla=8.0x2.6x9.0 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardenBeds|Shelves/GardenBedsSide [Model] talla=6.7x2.5x9.3 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/GardenBeds|Shelves/PottingBench [Model] talla=8.6x7.3x6.2 piezas=87 MeshPart=87 SurfaceAppearance=45
      Landscaping Pack/GardenBeds|Shelves/PlantShelf2 [Model] talla=6.1x10.2x3.5 piezas=163 MeshPart=163 SurfaceAppearance=100
      Landscaping Pack/GardenBeds|Shelves/PlantShelf [Model] talla=6.1x10.2x3.5 piezas=181 MeshPart=181 SurfaceAppearance=106
    Landscaping Pack/Outdoor_Statues [Folder] talla=49.2x27.5x105.0 piezas=52 MeshPart=49 SurfaceAppearance=44 Decal/Texture=25
      Landscaping Pack/Outdoor_Statues/Occult_Statue B [Model] talla=8.7x18.1x4.1 piezas=2 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Outdoor_Statues/Occult_Statues_E [Model] talla=15.0x10.1x3.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Outdoor_Statues/Occult_Statues_C [Model] talla=4.8x10.0x3.7 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Outdoor_Statues/Occult_Statues_A [Model] talla=10.7x13.8x11.1 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Outdoor_Statues/Occult_Statues_D [Model] talla=5.2x8.8x5.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Outdoor_Statues/Occult_Statues_F [Model] talla=17.2x12.9x4.0 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Outdoor_Statues/Occult_002 [MeshPart] talla=2.7x11.8x2.8 mat=Plastic MeshId=rbxassetid://10368423745 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Outdoor_Statues/Occult_Statues_G [Model] talla=9.1x11.5x5.9 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Outdoor_Statues/Armillary_Small [Model] talla=6.6x7.9x7.4 piezas=12 MeshPart=12 SurfaceAppearance=11
      Landscaping Pack/Outdoor_Statues/Armillary_Exterior [Model] talla=26.2x27.5x26.2 piezas=27 MeshPart=25 SurfaceAppearance=21 Decal/Texture=25
    Landscaping Pack/Shed [Folder] talla=17.5x16.7x29.8 piezas=20 MeshPart=20 SurfaceAppearance=19
      Landscaping Pack/Shed/Furniture_Backyard_DogHouse [Model] talla=4.8x5.4x5.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Shed/Furniture_Backyard_Shed [Model] talla=17.5x16.7x22.3 piezas=18 MeshPart=18 SurfaceAppearance=17
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=44.1x21.3x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=44.1x21.3x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/Prop_FirewoodLogHolderShelf [Model] talla=4.8x3.3x2.6 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Prop_FirewoodLogHolderShelf/Prop_FirewoodLogHolderShelf [MeshPart] talla=4.8x3.3x2.0 mat=Plastic MeshId=rbxassetid://10131496396 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Prop_FirewoodLogHolderShelf/Prop_FirewoodLogHolderShelfLogs [MeshPart] talla=4.6x2.6x2.6 mat=Plastic MeshId=rbxassetid://10131496415 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Prop_FirewoodLogHolder [Model] talla=2.4x2.0x2.3 piezas=2 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Prop_FirewoodLogHolder/Prop_FirewoodLogHolder [MeshPart] talla=2.0x1.8x2.3 mat=Plastic MeshId=rbxassetid://10131496397 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Prop_FirewoodLogHolder/Prop_FirewoodHolderLogs [MeshPart] talla=2.4x1.4x2.1 mat=Plastic MeshId=rbxassetid://10131496395 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Prop_FirewoodGrate [Model] talla=3.3x2.9x2.2 piezas=5 MeshPart=2 SurfaceAppearance=2
      Landscaping Pack/Prop_FirewoodGrate/Prop_FirewoodGrate [MeshPart] talla=3.3x1.0x2.2 mat=Plastic MeshId=rbxassetid://10131496393 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Prop_FirewoodGrate/Prop_FirewoodGrateLogs [MeshPart] talla=2.7x1.2x1.7 mat=Plastic MeshId=rbxassetid://10131496399 piezas=4 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/Surfaces [Folder] talla=48.8x0.5x57.1 piezas=13 MeshPart=10 SurfaceAppearance=10 Decal/Texture=3
      Landscaping Pack/Surfaces/DirtScattered_Large [Model] talla=9.2x0.1x9.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/DirtScattered_Small [Model] talla=4.4x0.1x4.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/LeafOverlay_Large_B [Model] talla=9.0x0.1x6.8 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/PuddleLarge [Model] talla=11.0x0.1x11.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/PuddleMedium [Model] talla=8.0x0.1x8.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/PuddleSmall [Model] talla=6.0x0.1x6.0 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/SaltScattered_Large [Model] talla=9.2x0.1x9.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/SaltScattered_Small [Model] talla=4.4x0.1x4.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/Leaves_Decal [MeshPart] talla=5.0x0.1x5.0 mat=Plastic MeshId=rbxassetid://8769061628 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/LeafOverlay_Small_A [Model] talla=4.7x0.1x4.6 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Surfaces/Decal_Scuff_01 [Model] talla=13.5x14.8x0.5 piezas=1 Decal/Texture=1
      Landscaping Pack/Surfaces/Decal_Scuff_01 [Model] talla=13.5x14.8x0.5 piezas=1 Decal/Texture=1
      Landscaping Pack/Surfaces/Decal_Scuff_01 [Model] talla=13.5x14.8x0.5 piezas=1 Decal/Texture=1
    Landscaping Pack/FirePit [Model] talla=4.4x27.6x27.4 piezas=47 MeshPart=46 SurfaceAppearance=43
      Landscaping Pack/FirePit/Circle_Brick_FirePit [Model] talla=22.6x1.5x22.4 piezas=3 MeshPart=3 SurfaceAppearance=2
      Landscaping Pack/FirePit/Campfire [Model] talla=5.6x5.8x5.5 piezas=41 MeshPart=41 SurfaceAppearance=41
      Landscaping Pack/FirePit/Prop_BurnedFirewood_Fire [Model] talla=3.2x2.3x2.4 piezas=3 MeshPart=2
    Landscaping Pack/Fence_Porch [Folder] talla=61.9x18.7x44.9 piezas=16 MeshPart=16 SurfaceAppearance=11 Decal/Texture=30
      Landscaping Pack/Fence_Porch/Driveway_Gate_Column [Model] talla=3.1x14.8x3.1 piezas=2 MeshPart=2 SurfaceAppearance=1 Decal/Texture=10
      Landscaping Pack/Fence_Porch/Fence_A [Model] talla=20.2x10.5x0.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Fence_A_Post [Model] talla=0.4x10.5x0.4 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Yard_Wall [Model] talla=20.1x12.8x2.5 piezas=2 MeshPart=2 SurfaceAppearance=1 Decal/Texture=10
      Landscaping Pack/Fence_Porch/Driveway_Gate [Model] talla=20.3x16.4x3.1 piezas=4 MeshPart=4 SurfaceAppearance=2 Decal/Texture=10
      Landscaping Pack/Fence_Porch/Porch_Rail_Steps [Model] talla=0.6x8.0x8.2 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Side_Steps_Dry [Model] talla=17.6x10.3x36.4 piezas=2 MeshPart=2 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Porch_Rail [Model] talla=0.6x4.1x13.1 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Stone_Walkway_Shader_Wet_Geo [MeshPart] talla=5.5x2.5x2.5 mat=Plastic MeshId=rbxassetid://8641990574 piezas=1 MeshPart=1 SurfaceAppearance=1
      Landscaping Pack/Fence_Porch/Brick_K_Wet_Shader_Geo [MeshPart] talla=5.5x2.5x2.5 mat=Plastic MeshId=rbxassetid://8641990574 piezas=1 MeshPart=1 SurfaceAppearance=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=16.5x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=16.5x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x3.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x3.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x2.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x2.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
    Landscaping Pack/RobloxBillboard [Model] talla=15.7x2.0x0.0 piezas=1 MeshPart=1
      Landscaping Pack/RobloxBillboard/Pack_Info [MeshPart] talla=15.7x2.0x0.0 mat=Plastic MeshId=rbxassetid://2530844336 piezas=1 MeshPart=1
```

</details>

## 11508587471 — Trash Can (RTopix)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 12169860688 — Large Terracotta Pot (PSY0PZ)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

## 12637929826 — Cypress tree (Letaij)

❌ No carga. `LoadAsset`: `User is not authorized to access Asset.` · `LoadAssetVersion` (última versión): `User is not authorized to access Asset.`

