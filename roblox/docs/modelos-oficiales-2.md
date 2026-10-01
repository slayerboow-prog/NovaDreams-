# Modelos oficiales de Roblox (segunda tanda): edificios, casas, coches, cielo y calle

Fecha: 2026-10-01. Sigue a `docs/modelos-tienda.md` y `docs/modelos-tienda-contenido.md`.

Regla ya sabida: un servidor del juego **solo** puede cargar con `InsertService:LoadAsset` modelos de Roblox
(o del dueño del juego). Los de la comunidad dan `User is not authorized to access Asset.`

## Cómo se ha hecho

1. **Búsqueda** con la API pública del toolbox, filtrando por el usuario Roblox (id 1):
   `https://apis.roblox.com/toolbox-service/v1/marketplace/10?num=100&creatorTargetId=1&creatorType=1[&keyword=…]`.
   - Sin palabra clave la API da como mucho **300** resultados (3 páginas). Con ~55 palabras clave más
     (building, house, car, vehicle, sky, city, town, suburban, mansion, racing, modular, furniture, road…)
     salen **371 modelos distintos** de Roblox.
   - Detalles (votos, triángulos, MeshParts, scripts) con `/toolbox-service/v1/items/details?assetIds=…`.
   - De esos 371, casi todos son modelos viejos (2007–2016, piezas simples) o armas/personajes.
     Los útiles para un pueblo realista son **los packs de 2021–2023** (tabla de abajo).
   - También se ha mirado el grupo oficial **Roblox Resources** (id 3529469, 26 modelos): sale en la Tienda
     como "Roblox Resources", pero **no carga** (ver tabla).
   - No hay ningún modelo de Roblox llamado "Mansion", "Racing", "Suburban", "Downtown" ni "Town" útil:
     solo "Haunted Mansion for Sale" (2007). Las plantillas de Studio (Racing, Suburban, Modern City…)
     son *lugares*, no modelos: no se pueden cargar con `LoadAsset`. Lo que sí está publicado como modelo
     es su contenido (el *Modular Building Kit – Modern City* y los packs *Duvall Drive*).
2. **Carga real** en un servidor del juego con `bash scripts/cloud-test.sh -v modelos`
   (`scripts/cloud/modelos.luau`, ahora con la lista de esta tanda y también: conteo de `MaterialVariant`,
   `VehicleSeat` y `Light`, y las propiedades de los `Sky`). El registro de la consola de la nube **se corta**
   si sale demasiado texto: para volcarlo entero se lanzó en 8 lotes (una copia temporal del script con
   menos ids; no se ha guardado).

Columnas: **Piezas** = BaseParts que trae (todo el pack). **Tris** = triángulos según el toolbox.
**SA** = SurfaceAppearance (PBR). **Scripts** = Script/LocalScript/ModuleScript dentro.

## Tabla de candidatos

| ID | Nombre | Para qué | ¿Carga? | Piezas | MeshPart | SA | Tris | Scripts | Votos |
|---|---|---|---|---|---|---|---|---|---|
| 13168370735 | Modular Building Kit – Modern City ⭐ | Edificios (kit + 11 prefabricados) | ✅ | 3360 | 3025 | 2165 | 796 055 | 8 (solo en el prefab `H`) | 95 % de 500 |
| 6418277837 | City Building Pack ⭐ | Edificios grandes de ciudad (12) | ✅ | 682 | 682 | 0 | 517 932 | 0 | 91 % de 700 |
| 6933556508 | Synty City Pack ⭐ | Edificios/tiendas *low-poly* (piezas) | ✅ | 332 | 332 | 0 | 256 709 | 0 | 96 % de 1000 |
| 13168345645 | Modern City Materials Pack ⭐ | 8 MaterialVariant (yeso, ladrillo pintado, acera, hormigón, pintura de coche) | ✅ | 0 | – | – | 0 | 0 | 96 % de 100 |
| 10841357434 | Realistic Material Variants – Duvall Drive ⭐ | 17 MaterialVariant (suelos de madera, papel pintado, losas, grava, charcos…) | ✅ | 0 | – | – | 0 | 0 | 95 % de 1000 |
| 10840642581 | House Props Pack – Duvall Drive ⭐ | Objetos de casa (cocina, libros, cuadros…) | ✅ | 575 | 514 | 299 | 243 941 | 1 | 97 % de 400 |
| 10847897579 | House Furniture Pack – Duvall Drive ⭐ | Muebles, lámparas, alfombras, puertas y ventanas de casa | ✅ | 1153 | 833 | 518 | 345 162 | 101 | 96 % de 1000 |
| 6418239833 | Sedan ⭐ | Coche (5 colores) | ✅ | 360 | 210 | 0 | 75 644 | 70 (14 por coche) | 92 % de 100 |
| 6433323089 | Sports Car ⭐ | Deportivo (3 colores) | ✅ | 176 | 92 | 0 | 54 816 | 42 | 95 % de 700 |
| 6418225759 | Pickup Truck ⭐ | Pick-up (3 colores) | ✅ | 213 | 123 | 0 | 50 516 | 42 | 93 % de 200 |
| 6418234850 | SUV ⭐ | Todoterreno (3 colores) | ✅ | 228 | 138 | 0 | 42 960 | 42 | 96 % de 200 |
| 6418221666 | Light Utility Vehicle ⭐ | Vehículo militar ligero (4 acabados) | ✅ | 276 | 156 | 0 | 41 647 | 56 | 97 % de 300 |
| 6433330180 | Supercar ⭐ | Superdeportivo (3 colores) | ✅ | 183 | 99 | 0 | 33 728 | 42 | 97 % de 100 |
| 6433316269 | Van ⭐ | Furgoneta (1970, pro, blanca) | ✅ | 163 | 79 | 0 | 30 544 | 42 | 96 % de 200 |
| 6418230807 | Police Car ⭐ | Coche de policía (1) | ✅ | 82 | 52 | 0 | 18 969 | 14 | 92 % de 2000 |
| 6433272094 | Dune Buggy ⭐ | Buggy (3 colores) | ✅ | 153 | 69 | 0 | 43 753 | 42 | 97 % de 200 |
| 12931234517 | Storefront Portal Template | Fachada de tienda pequeña (decorado + portal) | ✅ | 76 | 63 | 45 | 8 776 | 3 | 83 % de 40 |
| 12930997548 | City Portal Template | Portal con decorado urbano | ✅ | 18 | 5 | 3 | 1 048 | 3 | 95 % de 40 |
| 311580 | Winterness | Cielo (Sky) | ✅ | 0 | – | – | – | 0 | 95 % de 200 |
| 47339 | Broken Sky | Cielo (Sky) | ✅ | 0 | – | – | – | 0 | 95 % de 500 |
| 47344 | Starry Night | Cielo (Sky) | ✅ | 0 | – | – | – | 0 | 91 % de 200 |
| 47410 | Alien Red | Cielo (Sky) | ✅ | 0 | – | – | – | 0 | 98 % de 300 |
| 14215126016 | Car (grupo Roblox Resources) | Coche de tutorial | ❌ `User is not authorized to access Asset.` | – | – | – | – | – | 88 % de 10 000 |
| 14447738661 | Environment Art Asset Library (grupo Roblox Resources) | Piezas de entorno | ❌ `User is not authorized to access Asset.` | – | – | – | 73 371 | – | 10/10 |
| 3703494811 | Battle Royale Props (grupo Roblox Resources) | Props | ❌ `User is not authorized to access Asset.` | – | – | – | 31 236 | – | 0 |

⭐ = avalado (`isEndorsed`). Ya conocidos de la primera tanda (también cargan): City Road Pack 6432233485,
City Props Pack 6370681139, Forest Pack 6432306802, Landscaping Pack – Duvall Drive 10840661513.

**Conclusión de la carga:** todo lo del **usuario Roblox (id 1)** carga; lo del **grupo Roblox Resources no**
(aunque sea oficial). Ningún otro "Roblox…" de la Tienda es de Roblox de verdad.

## Qué hay dentro (lo importante)

### Modular Building Kit – Modern City (13168370735)
`Model` → `Folder "Modular Building Kit - Modern City"` →
- `PrefabBuildings` (Folder): **11 edificios ya montados**, `A`–`K` y `Model`. Tallas (studs):
  A 34×94×49, B 34×94×57, C 55×69×70, E 64×86×64, F 50×94×58, G 39×104×44, I 109×164×84,
  J 53×183×119, K 87×247×57, H 88×209×61 (este trae los 8 scripts), `Model` 35×78×32.
  Cada uno 100–500 piezas, casi todas MeshPart con SurfaceAppearance; algunos con luces (`Light`).
- `Modular Building Kit/Modular Building Kit` (213 MeshPart): muros bajos, muros altos y cornisas de **4 estilos**
  para montar edificios a medida. `Building Addons` (21: toldos, balcones, escaleras de incendios, aparatos de aire),
  `Set Dressing` (56), `Materials` (11).
- `Information Placards/Bldg_Addon_Billboard_A`: cartel del pack, no usar.

### City Building Pack (6418277837)
`Folder "City Building Pack"` → `building_01` … `building_12` (Model, ya montados) y `building_XX_sections`
(los mismos partidos en `ground_floor` / `top_floors` / `roof` para apilar plantas). Solo MeshPart con
`Material` de Roblox (Concrete, Metal, Marble, Glass…), **sin SurfaceAppearance**. Son **enormes**
(110–290 studs de ancho, hasta 290 de alto): rascacielos de gran ciudad, hay que escalar mucho.
Trae `RobloxBillboard` (no usar).

### Synty City Pack (6933556508)
332 MeshPart sueltos en `Model/Meshes/…` (`PolygonCity_Buildings_SM_Bld_Apartment_*`, `…Shop_*`,
`…OfficeOld_*`, `…CityHall_01`, paradas de bus, señales, papeleras…). Estilo **low-poly de colores planos**:
no encaja con el aspecto realista. Solo como relleno lejano.

### Packs Duvall Drive (casa)
- **House Furniture Pack** (`Folder "House Furnishing Pack"`): `Lights` (44 luces; lámparas de mesa, apliques,
  lámparas de techo, farolillo de porche, velas…; los `_On` llevan un script), `Rugs` (19 alfombras),
  `Architecture` (`Windows`, `Doors`, `Beams|Panels`, `Walls|Ceilings|Floors`), `Furniture` (`Shelves`, `Chairs`,
  `Kitchen`, `Console|Credenza`, `Bedroom`, `Tables|Desks`, `Couches`, `Pillows`, `Misc`; 78 scripts).
  Varios `RobloxBillboard` repetidos: no usar.
- **House Props Pack**: `Fashion`, `Kitchen` (vajilla, cafetera, sartenes…), `Books|Games|Misc`, `Art Frames`,
  `Statues`, `Taxidermy`, `Antiques`, `Cobwebs`.
- Estilo "casa victoriana de EE. UU." (es el decorado de un juego de miedo): muy realista, pero algunos objetos
  son de miedo (taxidermia, telarañas, maniquí "corrupto", velas rituales): elegirlos a mano.

### Coches (Sedan, Sports Car, Pickup, SUV, LUV, Supercar, Van, Police Car, Dune Buggy)
Todos con la **misma estructura** (es el chasis oficial "Roblox vehicle" de 2021):
`Model` → un `Model` por color, p. ej. `Sedan (aqua)` → `Chassis` (≈30 piezas + `VehicleSeat`), `Body`
(26–52 MeshPart, carrocería), `Constraints`, `Scripts` (**14 scripts**: conducción, cámara, luces…),
`Remotes`, `BindableEvents`, `Animations`, `Effects`. Carrocería con MeshPart y `Material` de Roblox
(**sin SurfaceAppearance**), algunos con Decal (pegatinas, matrícula).
Tallas (ancho×alto×largo): Sedan 8,6×6,2×20,6 · Sports Car 11×5,6×19,5 · Pickup 10,6×9,6×26,6 ·
SUV 9,8×8,1×20,9 · Supercar 10×5,3×20,7 · Van 11,6×9,7×26,2 · Police Car 9,4×6,5×21,1 · Buggy 9,4×7×16,7.

### Cielos (Winterness, Broken Sky, Starry Night, Alien Red)
Cada uno es `Model` → `Sky`. Los cuatro: `SunTextureId=rbxasset://sky/sun.jpg`, `MoonTextureId=rbxasset://sky/moon.jpg`,
`SunAngularSize=21`, `CelestialBodiesShown=true`, `StarCount=3000`. Texturas (todas de 2007, baja resolución):

| ID | Nombre | Bk | Dn | Ft | Lf | Rt | Up |
|---|---|---|---|---|---|---|---|
| 311580 | Winterness | 1327358 | 1327359 | 1327355 | 1327357 | 1327356 | 1327360 |
| 47339 | Broken Sky | 1010388 | 1010389 | 1010386 | 1010387 | 1010385 | 1010390 |
| 47344 | Starry Night | 1014342 | 1014343 | 1014340 | 1014341 | 1014339 | 1014344 |
| 47410 | Alien Red | 1012890 | 1012891 | 1012887 | 1012889 | 1012888 | 1014449 |

(en el modelo salen como `http://www.roblox.com/asset/?version=1&id=…`). **Ninguno es realista**: son
cielos de fantasía/invierno de 2007. Roblox no tiene publicado ningún modelo `Sky` moderno.

## Recomendación

- **Casas y edificios → Modular Building Kit – Modern City (13168370735).** Es lo único oficial, realista
  (PBR con SurfaceAppearance) y a escala de calle. Usar los 11 `PrefabBuildings` como bloques de pisos y tiendas
  en planta baja, y el kit (4 estilos de muro bajo/alto + cornisa, toldos, balcones) para fachadas a medida.
  Borrar los 8 scripts del prefab `H` y el cartel `Bldg_Addon_Billboard_A`. Para el toque mediterráneo,
  aplicar los **MaterialVariant** de *Modern City Materials Pack* (`Plaster_A`, `PaintedBrick`, `Sidewalk_A`) y
  de *Realistic Material Variants – Duvall Drive* (`Flagstone`, `Wood Floor`, `Wallpaper`…): hay que meterlos
  en `MaterialService` al cargar.
  - *City Building Pack* (6418277837): solo para el centro/skyline si se quiere algún rascacielos; escalado a la baja.
  - *Synty City Pack*: no (low-poly, desentona).
  - Casa unifamiliar completa oficial **no hay**: se monta con el kit modular + puertas/ventanas de
    `House Furniture Pack/Architecture`.
- **Interiores y mobiliario → House Furniture Pack (10847897579) + House Props Pack (10840642581)**
  (Duvall Drive). Elegir a mano (fuera lo de miedo), borrar scripts (salvo, si se quiere, el de encender lámparas)
  y los `RobloxBillboard`.
- **Coches → Sedan, SUV, Pickup Truck, Van, Police Car y Sports Car** (los "de calle"). Supercar y Dune Buggy
  como extras; LUV (militar) no. Uso recomendado: **coger solo `Body`** (la carrocería, MeshPart) y montarla
  sobre el chasis propio del juego, borrando `Scripts`, `Remotes`, `BindableEvents` y `Chassis`; así no se
  mezclan 14 scripts por coche con el sistema de vehículos del juego. Calidad: buena forma, pero sin PBR
  (materiales de Roblox); mejoran con `CarPaint_A` (MaterialVariant de Modern City Materials Pack).
- **Cielo → no usar ningún modelo.** Los `Sky` oficiales son de 2007 y no son realistas. Lo realista hoy en
  Roblox es el cielo por defecto + `Atmosphere` (Density ≈0,3, Haze, Glare, color) + `Clouds` (en `Terrain`,
  Cover ≈0,5) + `Lighting.Technology = Future` + `SunRays`/`Bloom`, todo creado por código sin cargar nada.
  Si se quiere un skybox de fotos, solo vale uno publicado por la cuenta/grupo dueño del juego (las imágenes de
  la comunidad no se pueden cargar como modelo; habría que subir las 6 texturas con `scripts/upload-textures.sh`).
- **Calle → City Road Pack (6432233485)** (carreteras, cruces, aceras) + **City Props Pack (6370681139)**
  (farolas, semáforos, bancos, papeleras), ya conocidos; más `Sidewalk_A` como MaterialVariant de acera.
  De paso, `Building Addons` y `Set Dressing` del kit modular añaden detalle de fachada.
- **Lo que no carga:** todo lo del grupo *Roblox Resources* (3529469). Si se quiere algo de ahí (p. ej. el
  *Environment Art Asset Library*), abrirlo en Studio y volver a publicarlo con la cuenta del juego.
