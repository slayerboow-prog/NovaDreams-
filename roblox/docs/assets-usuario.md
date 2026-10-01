# Assets elegidos por Sebastián: qué hay dentro

Volcado hecho en un servidor de Roblox con `AssetService:LoadAssetAsync(id)` (con `pcall`).
Script: `scripts/cloud/assets-usuario.luau` → `bash scripts/cloud-test.sh -v assets-usuario`.
Fecha: 2026-10-01. Árbol mirado hasta 4 niveles (la raíz es el nivel 0).

Notas generales:

- Los 9 ids **cargan** con `LoadAssetAsync`. Todos llegan dentro de un `Model` raíz llamado `Model`.
- Las texturas de los MaterialVariant (`ColorMap`, `NormalMap`…) no se pueden leer desde el servidor (falta la capacidad *Plugin*): no se han mirado.
- Ningún MaterialVariant trae `CustomPhysicalProperties`.
- El `Source` de los scripts **sí se puede leer** desde el servidor (con `LoadAssetAsync`).
- ⚠ = script: hay que borrarlo al usar el asset.

## Resumen

| id | Qué es | ¿Carga? | MaterialVariants por BaseMaterial | Scripts |
|---|---|---|---|---|
| 11392874817 | Césped 2k PBR | ✅ | 1: Grass 1 | 0 |
| 13277933714 | Realistic Materials (piedras) | ✅ | 20: Asphalt 1, Brick 1, Cobblestone 1, Concrete 1, CorrodedMetal 1, DiamondPlate 1, Fabric 1, Grass 1, Ground 1, LeafyGrass 1, Marble 1, Metal 1, Mud 1, Rock 1, Sand 1, Sandstone 1, Slate 1, Snow 1, Wood 1, WoodPlanks 1 | 0 |
| 14527172541 | Realistic Materials (madera) | ✅ | 6: Brick 1, CorrodedMetal 1, DiamondPlate 1, Snow 1, Wood 1, WoodPlanks 1 | 0 |
| 15221806045 | PBR Realistic Material Mega Pack | ✅ (13 errores de textura en consola) | 524: Asphalt 20, Brick 44, Cobblestone 21, Concrete 30, CorrodedMetal 26, CrackedLava 7, Fabric 40, Glacier 2, Granite 11, Grass 7, Ground 22, Ice 4, LeafyGrass 3, Limestone 8, Marble 7, Metal 93, Mud 8, Pavement 17, Pebble 6, Plastic 31, Rock 62, Sand 7, Sandstone 8, Slate 2, SmoothPlastic 2, Snow 4, Wood 21, WoodPlanks 11 | 0 |
| 15446413305 | Realistic Materials MADE WITH MATERIAL GENERATOR | ✅ | 8: Brick 1, Cobblestone 1, Concrete 1, CorrodedMetal 1, Grass 1, Ground 1, Sand 1, Wood 1 | 0 |
| 92927007790601 | Tylers Realistic Materials (asfaltos) | ✅ | 68: Brick 9, CeramicTiles 7, Cobblestone 2, Concrete 20, Fabric 2, Grass 1, Ground 3, LeafyGrass 1, Metal 6, Mud 3, Rock 4, Slate 3, Wood 7 | 0 |
| 8236576991 | Realistic TV Mesh | ✅ | — | 0 |
| 101748452 | Golden Desert Eagle Ban Gun (Tool) | ✅ | — | ⚠ 2 (`GunScript`, `GunScript/Bullet`) |
| 5849304432 | '68 Hat Giver | ✅ | — | ⚠ 1 (`HatHelperGuideGiverScript`) |

## 11392874817 — Césped 2k PBR

Carga: ✅. Árbol:

```
Model [Model]
└─ MaterialVariant 3 [MaterialVariant]
```

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| MaterialVariant 3 | Grass | 10 | Regular |

Ojo: se llama `MaterialVariant 3` (nombre genérico). Hay que renombrarlo al usarlo.

## 13277933714 — Realistic Materials (piedras)

Carga: ✅. Árbol: `Model [Model]` → `RealisticMaterials [Folder]` → 20 MaterialVariant. Nombres = nombre del material base
(chocan con los materiales de Roblox; mejor renombrar si se mezcla con otros packs). Todos `Organic`, 10 studs.

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Asphalt | Asphalt | 10 | Organic |
| Brick | Brick | 10 | Organic |
| Cobblestone | Cobblestone | 10 | Organic |
| Concrete | Concrete | 10 | Organic |
| CorrodedMetal | CorrodedMetal | 10 | Organic |
| DiamondPlate | DiamondPlate | 10 | Organic |
| Fabric | Fabric | 10 | Organic |
| Grass | Grass | 10 | Organic |
| Ground | Ground | 10 | Organic |
| LeafyGrass | LeafyGrass | 10 | Organic |
| Marble | Marble | 10 | Organic |
| Metal | Metal | 10 | Organic |
| Mud | Mud | 10 | Organic |
| Rock | Rock | 10 | Organic |
| Sand | Sand | 10 | Organic |
| Sandstone | Sandstone | 10 | Organic |
| Slate | Slate | 10 | Organic |
| Snow | Snow | 10 | Organic |
| Wood | Wood | 10 | Organic |
| WoodPlanks | WoodPlanks | 10 | Organic |

## 14527172541 — Realistic Materials (madera)

Carga: ✅. Árbol: `Model [Model]` → `Realistic Materials [Model]` → 6 MaterialVariant. Todos `Regular`, 10 studs.

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Realistic Bricks | Brick | 10 | Regular |
| Realistic Rusted Steel | CorrodedMetal | 10 | Regular |
| Realistic Metal Plate | DiamondPlate | 10 | Regular |
| Realistic Snow | Snow | 10 | Regular |
| Realistic Wood | Wood | 10 | Regular |
| Realistic Wood Planks | WoodPlanks | 10 | Regular |

## 15221806045 — PBR Realistic Material Mega Pack

Carga: ✅, pero en la consola salen 13 errores `TexturePack only supports rbxassetid` (texturas `rbxtemp://`) en estos
MaterialVariant: `Circuitry`, `Lava`, `Microchip`, `Obsidian`, `Skulls In Ground` (NormalMap y RoughnessMap),
`WeatheredWood AgedRusticTexturedMaterial` (RoughnessMap) y uno llamado `MaterialVariant` (ColorMap y MetalnessMap).
Esos 7 se verán mal o sin textura: no usarlos.

Árbol: `Model [Model]` → `MEGA PACK REALISTIC MATERIASL PBR [Folder]` (sic) → 524 MaterialVariant. Sin scripts.

<details><summary>Los 524 MaterialVariant (ordenados por BaseMaterial)</summary>

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Blue Lab | Asphalt | 3 | Organic |
| Brown Lab | Asphalt | 3 | Organic |
| Camp Lab | Asphalt | 3 | Organic |
| Clown Lab | Asphalt | 3 | Organic |
| Cracked Painted Asphalt | Asphalt | 10 | Regular |
| Cyan Lab | Asphalt | 3 | Organic |
| Funhouse Lab | Asphalt | 3 | Organic |
| Green Lab | Asphalt | 3 | Organic |
| Orange Lab | Asphalt | 3 | Organic |
| Painted Worn Asphalt | Asphalt | 10 | Organic |
| Pebbled Asphalt | Asphalt | 10 | Regular |
| Pink Lab | Asphalt | 3 | Organic |
| Pizza Lab | Asphalt | 3 | Organic |
| Purple Lab | Asphalt | 3 | Organic |
| Red Lab | Asphalt | 3 | Organic |
| Rocky Asphalt | Asphalt | 10 | Regular |
| Stone | Asphalt | 15.199999809265137 | Organic |
| TrashMaterial | Asphalt | 10 | Regular |
| White Lab | Asphalt | 3 | Organic |
| Yellow Lab | Asphalt | 3 | Organic |
| Brick | Brick | 6.599999904632568 | Regular |
| Brick 2 | Brick | 9 | Regular |
| Brick 3 | Brick | 9 | Regular |
| Brick 4 | Brick | 8 | Regular |
| Brick 5 | Brick | 6 | Regular |
| BrickWall SturdyTexturedUrbanMaterial | Brick | 10 | Organic |
| Building | Brick | 50 | Regular |
| Building 2 | Brick | 50 | Regular |
| Building 3 | Brick | 50 | Regular |
| Building 4 | Brick | 50 | Regular |
| Building 5 | Brick | 50 | Regular |
| Building 6 | Brick | 50 | Regular |
| Clay Shingles | Brick | 10 | Regular |
| Dirty Bricks | Brick | 10 | Regular |
| Dirty Tile | Brick | 10 | Regular |
| Dungeon Stone | Brick | 10 | Regular |
| Gray Bricks | Brick | 10 | Regular |
| Grime Alley Bricks | Brick | 10 | Regular |
| Grime Alley Bricks 2 | Brick | 10 | Regular |
| Harsh Bricks | Brick | 10 | Regular |
| Industrial Narrow Bricks | Brick | 10 | Regular |
| Line | Brick | 4.199999809265137 | Regular |
| Metal | Brick | 4.599999904632568 | Regular |
| Modern Brick | Brick | 10 | Regular |
| Mossy Bricks | Brick | 10 | Regular |
| Narrow Bricks | Brick | 10 | Regular |
| Painted Brick | Brick | 10 | Regular |
| Red Bricks | Brick | 10 | Regular |
| Rock Slab Wall | Brick | 10 | Regular |
| Rough Brick | Brick | 10 | Regular |
| Rounded Brick | Brick | 10 | Regular |
| Sewer Brick | Brick | 10 | Regular |
| Sloppy Mortar Bricks | Brick | 10 | Regular |
| Square Block Vegetation | Brick | 10 | Regular |
| Stone Block Wall | Brick | 10 | Regular |
| Stone Brick | Brick | 10 | Regular |
| Stone Wall | Brick | 10 | Regular |
| Stonework Wall | Brick | 10 | Regular |
| Tiled Stone | Brick | 10 | Regular |
| Variable Blocks Vegetation | Brick | 10 | Regular |
| Wall Stonework Sheen | Brick | 10 | Regular |
| Wallpaper | Brick | 10 | Regular |
| Worn Stonework | Brick | 10 | Regular |
| Woven Brick | Brick | 11 | Regular |
| Broken Down Stonework | Cobblestone | 10 | Regular |
| Chipped Stonework | Cobblestone | 10 | Regular |
| Chisled Cobble | Cobblestone | 10 | Organic |
| Cobble Stylized | Cobblestone | 10 | Regular |
| Cobblestone Curved | Cobblestone | 10 | Regular |
| Cobblestone Curved 2 | Cobblestone | 10 | Regular |
| CobblestoneRoad RoughBumpyRockyMaterial | Cobblestone | 10 | Regular |
| Curved Wet Cobble | Cobblestone | 10 | Regular |
| Damp Dungeon Floor | Cobblestone | 10 | Regular |
| Dusty Cobble | Cobblestone | 10 | Regular |
| Flat Cobble Moss | Cobblestone | 10 | Regular |
| Glossy Stylized Blocks | Cobblestone | 10 | Regular |
| Hexagon Pavers | Cobblestone | 10 | Regular |
| MossyStone DampOrganicWeatheredMaterial | Cobblestone | 10 | Organic |
| OctoStone | Cobblestone | 10 | Regular |
| Rough Wet Cobble | Cobblestone | 10 | Regular |
| Sludge Covered Stonework | Cobblestone | 10 | Regular |
| Snow Covered Path | Cobblestone | 10 | Regular |
| Wet Cobble | Cobblestone | 10 | Regular |
| Worn Down Stone Path | Cobblestone | 10 | Regular |
| Worn Wet Cobblestone | Cobblestone | 10 | Regular |
| Broken Down Concrete | Concrete | 10 | Regular |
| Broken Down Concrete 2 | Concrete | 10 | Regular |
| Cement Arching Pattern | Concrete | 10 | Regular |
| CeramicTiles GlossyPatternedDurableMaterial | Concrete | 10 | Regular |
| Chipping Painted Wall | Concrete | 10 | Regular |
| Concrete 1 | Concrete | 10 | Regular |
| Concrete 2 | Concrete | 10 | Regular |
| Concrete 2 | Concrete | 10 | Regular |
| Concrete 3 | Concrete | 10 | Regular |
| Concrete IndustrialGrittySturdyMaterial | Concrete | 9 | Organic |
| Concrete Tile (Studded) | Concrete | 6 | Regular |
| Concrete Tile 1 | Concrete | 10 | Regular |
| Concrete Tile 2 | Concrete | 10 | Regular |
| Degraded Concrete | Concrete | 10 | Regular |
| Fibrous Plaster | Concrete | 10 | Regular |
| Fine Particles Concrete | Concrete | 10 | Regular |
| Floral Embossed Wallpaper | Concrete | 10 | Regular |
| Grainy Stucco | Concrete | 10 | Regular |
| Lined Cement | Concrete | 10 | Regular |
| Lumpy Wet Concrete | Concrete | 10 | Regular |
| Paint Peeling | Concrete | 10 | Regular |
| Patchy Cement | Concrete | 10 | Regular |
| Pocked Concrete | Concrete | 10 | Regular |
| Roof | Concrete | 4 | Regular |
| Round Pattern Wallpaper | Concrete | 10 | Regular |
| Smooth Stucco | Concrete | 10 | Regular |
| Sprayed Wall Texture | Concrete | 10 | Regular |
| Stucco | Concrete | 10 | Regular |
| Stucco TexturedRoughPlasteredMaterial | Concrete | 10 | Organic |
| Worn Painted Cement | Concrete | 10 | Regular |
| Chipped Paint Metal | CorrodedMetal | 10 | Regular |
| Dash Lined Metal | CorrodedMetal | 10 | Regular |
| Greasy Metal | CorrodedMetal | 10 | Regular |
| Greasy Pan | CorrodedMetal | 10 | Regular |
| Grimy Metal | CorrodedMetal | 10 | Regular |
| Grip Rusted Steel | CorrodedMetal | 10 | Regular |
| Old Metal Slats | CorrodedMetal | 5 | Regular |
| Old Sheet Metal | CorrodedMetal | 10 | Regular |
| Oxidized Copper | CorrodedMetal | 10 | Regular |
| Pitted Rusted Metal | CorrodedMetal | 10 | Regular |
| Ribbed Chipped Metal | CorrodedMetal | 10 | Regular |
| Rust Coated | CorrodedMetal | 10 | Regular |
| Rust CorrodedWeatheredDecayedMaterial | CorrodedMetal | 10 | Organic |
| Rust Covered Metal | CorrodedMetal | 10 | Regular |
| Rust Panel | CorrodedMetal | 10 | Regular |
| Rust Panel 2 | CorrodedMetal | 10 | Regular |
| Rusted Grate | CorrodedMetal | 10 | Regular |
| Rusted Iron | CorrodedMetal | 10 | Regular |
| Rusted Iron 2 | CorrodedMetal | 10 | Regular |
| Rusted Iron Streaks | CorrodedMetal | 10 | Regular |
| Rusted Lined Metal 2 | CorrodedMetal | 10 | Regular |
| Rusted Ribbed Metal | CorrodedMetal | 10 | Regular |
| Rusted Steel | CorrodedMetal | 10 | Regular |
| Rusting Textured Metal | CorrodedMetal | 10 | Regular |
| Waffle Chipped Metal | CorrodedMetal | 10 | Regular |
| Worn Painted Metal | CorrodedMetal | 10 | Regular |
| Blood | CrackedLava | 17.899999618530273 | Regular |
| Columned Lava Rock | CrackedLava | 10 | Organic |
| Flowing Lava | CrackedLava | 10 | Regular |
| Hot Lava | CrackedLava | 10 | Regular |
| Lava | CrackedLava | 7 | Regular |
| Lava And Rock | CrackedLava | 10 | Regular |
| Leaves | CrackedLava | 3.5 | Regular |
| Brown Leather | Fabric | 2 | Organic |
| Brown Suede | Fabric | 10 | Regular |
| Burlap Stained | Fabric | 10 | Regular |
| Cardboard RoughRecyclableLightweightMaterial | Fabric | 10 | Regular |
| Carpet | Fabric | 10 | Regular |
| Carpet | Fabric | 2 | Organic |
| Carpet 1 | Fabric | 2 | Regular |
| Carpet SoftPlushPatternedMaterial | Fabric | 10 | Organic |
| Carpet SoftPlushPatternedMaterial 2 | Fabric | 10 | Regular |
| Cloth | Fabric | 7 | Regular |
| Coarse Loose Fabric | Fabric | 10 | Regular |
| Coarse Old Fabric | Fabric | 10 | Regular |
| Cushion | Fabric | 8 | Regular |
| Diagnal Stripe Weave | Fabric | 10 | Regular |
| Dirty Office Fabric | Fabric | 10 | Regular |
| Dirty Padded Leather | Fabric | 10 | Regular |
| Dirty Wicker Weave | Fabric | 10 | Regular |
| Felt | Fabric | 10 | Regular |
| Houndstooth Fabric Weave | Fabric | 10 | Regular |
| Leather SuppleTexturedRichMaterial | Fabric | 10 | Organic |
| Loose Tablecloth | Fabric | 10 | Regular |
| Matted Old Shaggy Rug | Fabric | 10 | Regular |
| Nylon Tent Fabric | Fabric | 10 | Regular |
| Office Carpet Fabric | Fabric | 10 | Regular |
| Office Fabric | Fabric | 10 | Regular |
| Old Motel Carpet | Fabric | 10 | Regular |
| Old Padded Leather | Fabric | 10 | Regular |
| Old Soiled Cloth | Fabric | 10 | Regular |
| Old Textured Fabric | Fabric | 10 | Regular |
| Rough Fabric | Fabric | 10 | Organic |
| Simple Basket Weave | Fabric | 10 | Regular |
| Soft Blanket | Fabric | 10 | Regular |
| Tight Weave Carpet | Fabric | 10 | Regular |
| Twill Fabric | Fabric | 10 | Regular |
| Vinyl Tablecloth | Fabric | 10 | Regular |
| White Quilted Diamond | Fabric | 10 | Regular |
| White Quilted Fabric | Fabric | 10 | Regular |
| Worn Blue Burlap | Fabric | 10 | Regular |
| Worn Braided Carpet | Fabric | 10 | Regular |
| Wrinkled Paper | Fabric | 10 | Regular |
| flesh | Glacier | 10 | Organic |
| Water | Glacier | 20 | Regular |
| Granite | Granite | 10 | Regular |
| Granite Rockface | Granite | 10 | Regular |
| Gray Granite | Granite | 10 | Regular |
| Gray Granite 2 | Granite | 10 | Regular |
| Gray Granite Flecks | Granite | 10 | Regular |
| Smooth Granite | Granite | 10 | Regular |
| Smooth Granite 2 | Granite | 10 | Regular |
| Smooth Granite 3 | Granite | 10 | Regular |
| Smooth Granite 4 | Granite | 10 | Regular |
| Speckled Countertop | Granite | 10 | Regular |
| Speckled Granite | Granite | 10 | Regular |
| Grass | Grass | 10 | Regular |
| Grassy Meadow | Grass | 10 | Regular |
| Hay | Grass | 10 | Regular |
| Mixed Moss | Grass | 10 | Organic |
| Patchy Meadow | Grass | 10 | Regular |
| Stylized Grass | Grass | 10 | Regular |
| Whispy Grass | Grass | 10 | Regular |
| Bones In Dirt | Ground | 10 | Organic |
| Bumpy Worn Ground | Ground | 10 | Regular |
| Damp Rocky Ground | Ground | 10 | Regular |
| Dirt With Rocks | Ground | 10 | Regular |
| Dry Dirt | Ground | 10 | Regular |
| Dry Dirt 2 | Ground | 10 | Regular |
| Dry Rocky Ground | Ground | 10 | Regular |
| Dusty Ground Gravel | Ground | 10 | Regular |
| Gravel Path | Ground | 10 | Regular |
| Jagged Rocky Ground | Ground | 10 | Regular |
| Leafy Grass | Ground | 10 | Regular |
| Lily Pads | Ground | 10 | Regular |
| Pine Needles | Ground | 10 | Regular |
| Planet Surface | Ground | 10 | Regular |
| Rocky Dirt | Ground | 10 | Regular |
| Rocky Worn Ground | Ground | 10 | Regular |
| Sandy Ground | Ground | 10 | Regular |
| Sandy Rocks | Ground | 10 | Regular |
| Skulls In Ground | Ground | 10 | Regular |
| Twisted Branches | Ground | 10 | Organic |
| Vines | Ground | 10 | Regular |
| Windswept Wasteland | Ground | 10 | Regular |
| Glass - fractalized | Ice | 10 | Organic |
| Ice Field | Ice | 10 | Organic |
| Iced Over Ground | Ice | 10 | Regular |
| Stylized Ice Cave Walls | Ice | 10 | Regular |
| Fallen Leaves | LeafyGrass | 10 | Organic |
| Forest Floor | LeafyGrass | 10 | Organic |
| Forest Trail | LeafyGrass | 10 | Regular |
| Carved Limestone | Limestone | 10 | Regular |
| Flaking Limestone | Limestone | 10 | Regular |
| Flat Textured Limestone | Limestone | 10 | Regular |
| Limestone 2 | Limestone | 10 | Regular |
| Limestone 3 | Limestone | 10 | Regular |
| Limestone 4 | Limestone | 10 | Regular |
| Limestone Cliffs | Limestone | 10 | Regular |
| Limestone Marked | Limestone | 10 | Regular |
| Marble | Marble | 4.199999809265137 | Regular |
| Marble SmoothPolishedElegantMaterial | Marble | 10 | Organic |
| Marble Speckled | Marble | 10 | Regular |
| Marble Tile 1 | Marble | 8 | Regular |
| Pool Material | Marble | 10 | Regular |
| Streaked Marble | Marble | 10 | Regular |
| Stringy Marble | Marble | 10 | Regular |
| Brushed Metal | Metal | 10 | Regular |
| Ceiling Tiles | Metal | 20 | Regular |
| Checkered Tile | Metal | 8 | Regular |
| Circle Textured Metal | Metal | 10 | Regular |
| Circuitry | Metal | 10 | Regular |
| Cloudy Metal | Metal | 6 | Regular |
| Cog Patterned Metal | Metal | 10 | Regular |
| Copper Scuffed | Metal | 10 | Regular |
| Copper Scuffed 2 | Metal | 10 | Regular |
| Corroded | Metal | 10 | Regular |
| Corroded Metal 2 | Metal | 5 | Regular |
| Dented Metal | Metal | 10 | Regular |
| Diamond Metal Siding | Metal | 10 | Regular |
| Dirty Tile | Metal | 6 | Regular |
| Dull Brass | Metal | 10 | Regular |
| Dull Copper | Metal | 10 | Regular |
| Fancy Brass Pattern | Metal | 10 | Regular |
| Fancy Diamond Metal | Metal | 10 | Regular |
| Fancy Metal | Metal | 10 | Regular |
| Filthy Space Panels | Metal | 10 | Regular |
| Floor Tile 1 | Metal | 10 | Regular |
| Floor Tile 2 | Metal | 15 | Regular |
| Framed Square Metal | Metal | 10 | Regular |
| Futurism Metal | Metal | 10 | Regular |
| Futuristic Panels | Metal | 10 | Regular |
| Gold Scuffed | Metal | 10 | Regular |
| Gold Scuffed 2 | Metal | 10 | Regular |
| Industrial Walls | Metal | 10 | Regular |
| Mesh Covered Metal | Metal | 10 | Regular |
| Metal Grate | Metal | 10 | Regular |
| Metal Grid | Metal | 10 | Regular |
| Metal Grid 2 | Metal | 10 | Regular |
| Metal Grid 3 | Metal | 10 | Regular |
| Metal Grid 4 | Metal | 10 | Regular |
| Metal ShinyReflectiveMetallicMaterial | Metal | 10 | Organic |
| Metal Splotchy | Metal | 10 | Regular |
| Metal Ventilation | Metal | 10 | Regular |
| Metal Weave 1 | Metal | 10 | Regular |
| Metal Weave 2 | Metal | 10 | Regular |
| Metal With Leaks | Metal | 10 | Organic |
| Microchip | Metal | 10 | Regular |
| Microchip 2 | Metal | 10 | Regular |
| Military Panels | Metal | 10 | Regular |
| Modern Metal Wall | Metal | 10 | Regular |
| Mosiac | Metal | 8 | Regular |
| Oily Metal | Metal | 5 | Regular |
| Old Painted Vent | Metal | 2 | Regular |
| Ornate Brass 2 | Metal | 10 | Regular |
| Ornate Brass 3 | Metal | 10 | Regular |
| Ornate Celtic Gold | Metal | 10 | Regular |
| Painted Metal Shed | Metal | 10 | Regular |
| Pirate Gold | Metal | 10 | Regular |
| Pitted Metal | Metal | 10 | Regular |
| Polished Metal | Metal | 10 | Regular |
| Red Sci-fi Metal | Metal | 10 | Regular |
| Reinforced Metal | Metal | 10 | Regular |
| Ribbed Metal | Metal | 10 | Regular |
| Rigid Metal Siding | Metal | 10 | Regular |
| Roof | Metal | 10 | Regular |
| Rusted Lined Metal | Metal | 10 | Regular |
| Sci-fi Panel | Metal | 10 | Regular |
| Scratched Scuffed Metal | Metal | 10 | Regular |
| Scuffed Iron | Metal | 10 | Regular |
| Scuffed Metal | Metal | 10 | Regular |
| Shiny Tile | Metal | 8 | Regular |
| Ship Corridor | Metal | 10 | Regular |
| Smooth Square Textured Metal | Metal | 10 | Regular |
| Solar Panels | Metal | 10 | Regular |
| Space Crate | Metal | 10 | Regular |
| Space Cruiser Panels | Metal | 10 | Regular |
| Space Cruiser Panels 2 | Metal | 10 | Regular |
| Spaceship Panels | Metal | 10 | Regular |
| Steel Plate | Metal | 10 | Regular |
| Storage Container | Metal | 10 | Regular |
| Streaked Metal | Metal | 10 | Regular |
| Streaked Metal 2 | Metal | 10 | Regular |
| Streaky Metal | Metal | 10 | Regular |
| Studded Metal | Metal | 8 | Regular |
| Studded Metal | Metal | 10 | Regular |
| Tabbed Metal | Metal | 10 | Regular |
| Titanium Scuffed | Metal | 10 | Regular |
| Used Stainless Steel | Metal | 10 | Regular |
| Used Stainless Steel 2 | Metal | 10 | Regular |
| Vented Metal Panel | Metal | 10 | Regular |
| Vertical Lined Metal | Metal | 10 | Regular |
| Warped Sheet Metal | Metal | 10 | Regular |
| Worn Factory Siding | Metal | 10 | Regular |
| Worn metal | Metal | 10 | Regular |
| Worn Military Siding | Metal | 10 | Regular |
| Worn Modern Panels | Metal | 10 | Regular |
| Worn Modern Panels 2 | Metal | 10 | Regular |
| Worn Shiny Metal | Metal | 10 | Regular |
| Worn Walkway Metal | Metal | 10 | Regular |
| Bog | Mud | 10 | Regular |
| Mossy Mud | Mud | 10 | Organic |
| Mud With Vegetation | Mud | 10 | Organic |
| Muddy Scattered Brickwork | Mud | 10 | Regular |
| Paints | Mud | 5.199999809265137 | Regular |
| Rainbow | Mud | 12.800000190734863 | Regular |
| Tidal Pool | Mud | 10 | Regular |
| Tidal Pool 2 | Mud | 10 | Organic |
| Cheap Old Linoleum | Pavement | 10 | Regular |
| Damp Tiles | Pavement | 10 | Regular |
| Dark Tiles | Pavement | 10 | Regular |
| Diamond Inlay Tiles | Pavement | 10 | Regular |
| Green Ceramic Tiles | Pavement | 10 | Regular |
| Green Shower Tiles | Pavement | 10 | Regular |
| Gross Dirty Tiles | Pavement | 10 | Regular |
| Industrial Tiles | Pavement | 10 | Regular |
| Mini Gross Tiling | Pavement | 10 | Regular |
| Modern Tiles | Pavement | 10 | Regular |
| Rich Brown Tile | Pavement | 10 | Regular |
| Rich Brown Tile 2 | Pavement | 10 | Regular |
| Shades Tile | Pavement | 10 | Regular |
| Spaced Tiles | Pavement | 10 | Regular |
| Stone Tiles | Pavement | 10 | Regular |
| Tile | Pavement | 10 | Regular |
| Vintage Tile | Pavement | 10 | Regular |
| Cloth | Pebble | 6.300000190734863 | Regular |
| Grid | Pebble | 6.300000190734863 | Regular |
| Pebbled Counter | Pebble | 10 | Regular |
| River Rock | Pebble | 10 | Regular |
| Rocky Shoreline | Pebble | 10 | Regular |
| Wet Rocks With Sand | Pebble | 10 | Regular |
| Crisscross Foam | Plastic | 10 | Regular |
| Dashboard | Plastic | 10 | Regular |
| DevelopmentGrid | Plastic | 8 | Regular |
| Dragon Scales | Plastic | 10 | Regular |
| Feathers | Plastic | 10 | Regular |
| Garbage Bag | Plastic | 10 | Organic |
| Grippy Foam | Plastic | 10 | Regular |
| Honeycomb | Plastic | 10 | Regular |
| Human Skin | Plastic | 10 | Regular |
| Human Skin 2 | Plastic | 10 | Regular |
| Human Skin 3 | Plastic | 10 | Regular |
| Human Skin 4 | Plastic | 10 | Regular |
| Human Skin 5 | Plastic | 10 | Regular |
| Human Skin 6 | Plastic | 10 | Regular |
| Human Skin Freckled | Plastic | 10 | Regular |
| Layered Fungus | Plastic | 10 | Regular |
| Lined Grip Foam | Plastic | 10 | Regular |
| Meat | Plastic | 10 | Regular |
| Melted Wax | Plastic | 5 | Regular |
| Office Ceiling Tiles | Plastic | 30 | Regular |
| Orbed Plastic | Plastic | 10 | Regular |
| Patterned BW Vinyl | Plastic | 10 | Regular |
| Plastic 2 | Plastic | 10 | Regular |
| Red Plastic | Plastic | 10 | Regular |
| Rigid Foam | Plastic | 10 | Regular |
| Studded Plastic | Plastic | 10 | Regular |
| Stylized Animal Fur | Plastic | 10 | Regular |
| Stylized Beast Fur | Plastic | 10 | Organic |
| Synthetic Rubber | Plastic | 10 | Regular |
| Vehicle Interior | Plastic | 10 | Regular |
| Yoga Mat | Plastic | 10 | Regular |
| Blocky Rockface | Rock | 10 | Regular |
| Bumpy Rockface | Rock | 10 | Regular |
| Cavefloor | Rock | 10 | Regular |
| Cavefloor Rock | Rock | 10 | Regular |
| Cavern Deposits | Rock | 10 | Regular |
| Cavern Walls | Rock | 10 | Regular |
| Cliff Rockface | Rock | 10 | Regular |
| Coral | Rock | 10 | Regular |
| Cratered Rock | Rock | 10 | Regular |
| Dark Rough Rock | Rock | 10 | Regular |
| Desert Cliff | Rock | 10 | Regular |
| Eroded Layered Rockface | Rock | 10 | Regular |
| Eroded Smooth Rockface | Rock | 10 | Regular |
| Faux Rock Stucco | Rock | 10 | Regular |
| Fibrous Textured Wall | Rock | 10 | Regular |
| Flaking Plaster Wall | Rock | 10 | Regular |
| Geyser Rock | Rock | 10 | Regular |
| Holey Rock | Rock | 10 | Regular |
| Jagged Cliff | Rock | 10 | Regular |
| Jagged Rockface | Rock | 10 | Regular |
| Lava Rock | Rock | 10 | Regular |
| Layered Cliff | Rock | 10 | Regular |
| Layered Planetary | Rock | 10 | Regular |
| Layered Rock | Rock | 10 | Regular |
| Layered Rock 2 | Rock | 10 | Regular |
| Light Bumped Rock | Rock | 10 | Regular |
| Lunar Rock | Rock | 10 | Regular |
| Lunar Rock 2 | Rock | 10 | Regular |
| Obsidian | Rock | 10 | Organic |
| Ocean Rock | Rock | 10 | Regular |
| Ore | Rock | 10 | Organic |
| Peacock Ore | Rock | 10 | Regular |
| Pocked Stone | Rock | 10 | Regular |
| Ravine Rock | Rock | 10 | Regular |
| Red Clay Wall | Rock | 10 | Regular |
| Red Coral | Rock | 10 | Organic |
| Rock Sliced | Rock | 10 | Regular |
| Rock Vstreaks | Rock | 10 | Regular |
| Rough Igneous  Rock | Rock | 10 | Regular |
| Rough Plaster | Rock | 10 | Regular |
| Rough Rock | Rock | 10 | Regular |
| Rough Rockface | Rock | 10 | Regular |
| Rough Rockface 2 | Rock | 10 | Regular |
| Sharp Rockface | Rock | 10 | Regular |
| Sharp Rockface 2 | Rock | 10 | Regular |
| Sharp Volcanic Rock | Rock | 10 | Regular |
| Slimy Slippery Rock | Rock | 10 | Regular |
| Slippery Stonework | Rock | 10 | Regular |
| Stacked Rock Cliff | Rock | 10 | Regular |
| Strata Rock | Rock | 10 | Regular |
| Strata Rock 2 | Rock | 10 | Regular |
| Streaked Stone | Rock | 10 | Regular |
| Stylized Cave Wall | Rock | 10 | Regular |
| Stylized Cliff | Rock | 10 | Regular |
| Stylized Cliff 2 | Rock | 10 | Regular |
| Stylized Columned Cliff | Rock | 10 | Regular |
| Sulfuric Rock | Rock | 10 | Regular |
| Vertical Streak Cliff | Rock | 10 | Regular |
| Volcanic Rock | Rock | 10 | Regular |
| Waterworn Stone | Rock | 10 | Regular |
| Wet Cave Wall | Rock | 10 | Regular |
| Worn Bumpy Rock | Rock | 10 | Regular |
| Desert Rocks | Sand | 10 | Regular |
| Rocky Dunes | Sand | 10 | Organic |
| Sand 1 | Sand | 10 | Regular |
| Sand Dunes | Sand | 10 | Regular |
| Sand FineGranularLooseMaterial | Sand | 10 | Organic |
| Sandy Dry Soil | Sand | 10 | Regular |
| Wavy Sand | Sand | 10 | Organic |
| Dirty Middle Eastern Wall | Sandstone | 10 | Organic |
| Middle Eastern Wall | Sandstone | 10 | Organic |
| Old Middle Eastern Wall | Sandstone | 10 | Organic |
| Sandstone Blocks | Sandstone | 10 | Regular |
| Sandstone Cliff | Sandstone | 10 | Regular |
| Stone | Sandstone | 15.899999618530273 | Organic |
| Stone | Sandstone | 7.599999904632568 | Regular |
| Winding Desert Rock | Sandstone | 10 | Regular |
| Slate Cliff Rock | Slate | 10 | Regular |
| Slate Tiled | Slate | 10 | Regular |
| Leather (New) | SmoothPlastic | 1.5 | Regular |
| Leather (Rough) | SmoothPlastic | 2 | Regular |
| Packed Snow | Snow | 10 | Organic |
| Rock Snow | Snow | 10 | Regular |
| Slime | Snow | 6 | Regular |
| Snow Drift | Snow | 10 | Regular |
| Bookshelf | Wood | 4 | Regular |
| Cactus | Wood | 10 | Regular |
| Charcoal | Wood | 10 | Regular |
| Cheap Plywood | Wood | 10 | Regular |
| Cherry Wood | Wood | 10 | Regular |
| Corkboard | Wood | 10 | Regular |
| Cracks | Wood | 6.599999904632568 | Regular |
| Knotty Plywood | Wood | 10 | Regular |
| Light Bark | Wood | 10 | Regular |
| Mature Oak | Wood | 10 | Regular |
| Oak | Wood | 10 | Regular |
| Old Plywood | Wood | 10 | Regular |
| Pine | Wood | 10 | Regular |
| Plywood | Wood | 10 | Regular |
| Rough Wood | Wood | 10 | Regular |
| Streaky Plywood | Wood | 10 | Regular |
| Veneer Wood | Wood | 10 | Regular |
| WeatheredWood AgedRusticTexturedMaterial | Wood | 10 | Organic |
| White Spruce | Wood | 10 | Regular |
| Wicker  | Wood | 10 | Organic |
| Wood 2 | Wood | 10 | Regular |
| Mahogany Floor | WoodPlanks | 10 | Regular |
| Oak Floor | WoodPlanks | 10 | Regular |
| Old Plank Flooring | WoodPlanks | 10 | Regular |
| Old Plank Flooring 2 | WoodPlanks | 10 | Regular |
| Old Plank Flooring 3 | WoodPlanks | 10 | Regular |
| Old Plank Flooring 4 | WoodPlanks | 10 | Regular |
| Old Planks | WoodPlanks | 10 | Regular |
| Old Wood Flooring | WoodPlanks | 10 | Regular |
| Saloon Wood Floor | WoodPlanks | 10 | Regular |
| Saloon Wood Floor 2 | WoodPlanks | 10 | Regular |
| Worn Painted Wood Siding | WoodPlanks | 10 | Regular |

</details>

## 15446413305 — Realistic Materials MADE WITH MATERIAL GENERATOR

Carga: ✅. Árbol: `Model [Model]` → `Folder [Folder]` → 8 MaterialVariant. Todos `Regular`, 10 studs.
Ojo: `RealisticGold` va sobre `Sand`, `RealisticStone` sobre `Ground` y `RealisticPattern` sobre `CorrodedMetal`.

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| RealisticBricks | Brick | 10 | Regular |
| RealisticCobbleStone | Cobblestone | 10 | Regular |
| RealisticConcrete | Concrete | 10 | Regular |
| RealisticPattern | CorrodedMetal | 10 | Regular |
| RealisticGrass | Grass | 10 | Regular |
| RealisticStone | Ground | 10 | Regular |
| RealisticGold | Sand | 10 | Regular |
| RealisticWood | Wood | 10 | Regular |

## 92927007790601 — Tylers Realistic Materials (asfaltos)

Carga: ✅. Árbol: `Model [Model]` → `Tyler's Realistic Materials [Folder]` → 68 MaterialVariant.
Ojo: `Asphalt2` y los `Pavement*` van sobre `Concrete` (no hay ninguno sobre `Asphalt`); `BrickWall3` y `Stone` sobre `Slate`.
StudsPerTile variados (5 a 25).

| Nombre | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Brick2 | Brick | 13 | Regular |
| Brick3 | Brick | 10 | Regular |
| Brick4 | Brick | 15 | Regular |
| Brickwall1 | Brick | 15 | Regular |
| BrickWall2 | Brick | 25 | Regular |
| Wall1 | Brick | 10 | Organic |
| Wall2 | Brick | 20 | Regular |
| Wall3 | Brick | 15 | Organic |
| Wall4 | Brick | 13 | Organic |
| CeramicTiles1 | CeramicTiles | 13 | Regular |
| CeramicTiles2 | CeramicTiles | 15 | Regular |
| Ceramictiles3 | CeramicTiles | 15 | Regular |
| CeramicTiles4 | CeramicTiles | 15 | Regular |
| CeramicTiles5 | CeramicTiles | 10 | Regular |
| Roof1 | CeramicTiles | 15 | Regular |
| Roof2 | CeramicTiles | 15 | Regular |
| Cobblestone2 | Cobblestone | 10 | Regular |
| Cobblestone3 | Cobblestone | 10 | Regular |
| Asphalt2 | Concrete | 17 | Organic |
| Concrete10 | Concrete | 15 | Organic |
| Concrete11 | Concrete | 15 | Organic |
| Concrete12 | Concrete | 7 | Organic |
| Concrete2 | Concrete | 15 | Organic |
| Concrete3 | Concrete | 8 | Organic |
| Concrete4 | Concrete | 15 | Organic |
| Concrete5 | Concrete | 15 | Organic |
| Concrete6 | Concrete | 8 | Organic |
| Concrete7 | Concrete | 8 | Organic |
| Concrete8 | Concrete | 8 | Organic |
| Concrete9 | Concrete | 15 | Organic |
| Pavement2 | Concrete | 10 | Regular |
| Pavement3 | Concrete | 13 | Regular |
| Pavement4 | Concrete | 15 | Regular |
| Pavement5 | Concrete | 15 | Regular |
| Pavement6 | Concrete | 10 | Regular |
| Pavement7 | Concrete | 15 | Regular |
| Pavement8 | Concrete | 15 | Regular |
| Pavement9 | Concrete | 13 | Regular |
| Carpet2 | Fabric | 13 | Organic |
| TableCloth | Fabric | 5 | Regular |
| Grass2 | Grass | 10 | Organic |
| Ground2 | Ground | 10 | Organic |
| Ground3 | Ground | 10 | Organic |
| Ground4 | Ground | 15 | Organic |
| LeaftGrass2 | LeafyGrass | 10 | Organic |
| ContainerSide | Metal | 15 | Regular |
| MetalGate | Metal | 14 | Regular |
| RustedDiamondMetal | Metal | 6 | Regular |
| RustedMetal | Metal | 7 | Organic |
| RustedMetal2 | Metal | 10 | Organic |
| RustedMetalGate | Metal | 15 | Regular |
| Mud2 | Mud | 10 | Organic |
| Mud3 | Mud | 15 | Organic |
| Mud4 | Mud | 10 | Organic |
| Pebble2 | Rock | 15 | Organic |
| Stone 2 | Rock | 15 | Organic |
| Stone 4 | Rock | 20 | Organic |
| Stone3 | Rock | 15 | Regular |
| BrickWall3 | Slate | 7 | Regular |
| Stone | Slate | 20 | Organic |
| Stonetiles | Slate | 15 | Regular |
| Wood2 | Wood | 13 | Organic |
| Wood3 | Wood | 15 | Organic |
| Woodplanks1 | Wood | 10 | Regular |
| Woodplanks2 | Wood | 15 | Regular |
| Woodplanks3 | Wood | 15 | Regular |
| Woodplanks4 | Wood | 15 | Regular |
| Woodplanks5 | Wood | 6 | Regular |

## 8236576991 — Realistic TV Mesh

Carga: ✅. Árbol:

```
Model [Model] talla 50.0x38.1x39.2
└─ realistic mesh [MeshPart] talla 50.0x38.1x39.2, Material Plastic
     MeshId = rbxassetid://8236552303 (se puede leer)
     TextureID = sí (rbxassetid://8236552761)
     SurfaceAppearance = no
```

Es enorme (50 studs de ancho): hay que escalarlo mucho para una tele normal. Sin scripts.

## 101748452 — Golden Desert Eagle Ban Gun

Carga: ✅. Es un **Tool** (talla 2.8x2.0x1.3). Clases: Tool 1, Part 72, Weld 231, BlockMesh 37, SpecialMesh 34,
CylinderMesh 3, Sound 3, IntValue 1, Script 2.

```
Model [Model]
└─ Desert Eagle [Tool]  RequiresHandle=true, TextureId vacío (sin icono)
   ├─ Handle [Part] 1x1x1 Plastic, sin SurfaceAppearance
   │  ├─ Mesh [BlockMesh]
   │  ├─ Grip [Sound]  ├─ Fire [Sound]  └─ Reload [Sound]
   ├─ Part ×71 [Part] (60 de 1x1x1 y 11 de 1x0.4x1), Plastic, sin SurfaceAppearance ni MeshPart;
   │    cada una con un Mesh [BlockMesh / CylinderMesh / SpecialMesh sin MeshId, solo Scale] y Welds
   ├─ Mesh [SpecialMesh]   (ojo: el script usa Tool.BulletMesh, que no existe → fallaría al disparar)
   ├─ Ammo [IntValue] = 2147483647
   └─ ⚠ GunScript [Script] Enabled=true — Source legible (6769 caracteres)
      └─ ⚠ Bullet [Script] Enabled=true — Source legible (398 caracteres)
```

Qué hacen los scripts (leídos desde el servidor):

- ⚠ `Desert Eagle/GunScript`: código antiguo (`wait`, `:connect`, `formFactor`): crea `Motor` falsos en los hombros, dispara balas `Part` con
  `BodyVelocity` y clona `Bullet` en cada bala.
- ⚠ `Desert Eagle/GunScript/Bullet`: al tocar a un jugador hace `place:remove()` sobre el **Player** → lo **echa del
  juego** (por eso "Ban Gun"). **Peligroso: borrar sí o sí.**

Solo vale como modelo de pistola hecho de piezas (72 Parts): nada de mallas modernas.

## 5849304432 — '68 Hat Giver

Carga: ✅. **No es un Accessory**: es una pieza "dadora" de sombrero.

```
Model [Model]
└─ SSH68 [Part] talla 1.2x0.8x1.4, Material Metal, sin SurfaceAppearance
   ├─ Mesh [SpecialMesh] MeshId=rbxassetid://5723748040, TextureId=rbxassetid://5723901932, Scale=0.971 (×3)
   ├─ Decal [Decal] Texture vacía
   └─ ⚠ HatHelperGuideGiverScript [Script] Enabled=true — Source legible (3423 caracteres)
```

- ⚠ `SSH68/HatHelperGuideGiverScript`: según sus comentarios, "hat giver" clásico: al tocar la pieza
  da un sombrero colocado con `AttachmentPos`. Borrarlo. Para usar el sombrero, lo útil es la malla y la textura del `SpecialMesh` (meterlas en un
  `Accessory` propio).
