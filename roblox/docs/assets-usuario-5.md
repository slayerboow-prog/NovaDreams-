# Assets elegidos por Sebastián (5ª tanda): qué hay dentro

Igual que en `docs/assets-usuario-4.md`: volcado hecho en un servidor de Roblox con
`AssetService:LoadAssetAsync(id)` (con `pcall`).
Script: `scripts/cloud/assets-usuario-5.luau` → `bash scripts/cloud-test.sh -v assets-usuario-5`.
Se lanzó en 7 ejecuciones (cambiando `IDS`). Ninguna se cortó por tiempo.
Datos públicos de cada asset: `https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=…`.
Creador de cada malla e imagen con `economy.roblox.com/v2/assets/<id>/details`; miniaturas con
`thumbnails.roblox.com`.
Fecha: 2026-10-01.

Nuevo en esta tanda:

- De cada `Sky` se mira si sus **6 caras** (y sol y luna) cargan, con `ContentProvider:PreloadAsync`.
- De cada `Decal`, `Texture` y `ParticleEmitter` se mira si su imagen carga (como mucho 40 por asset).
- En nombres, textos e imágenes se buscan palabras de **odio** (esvástica, nazi, hitler, reich, 卐…) y de
  **sangre** (blood, gore…).
- De los `MaterialVariant` se intentan leer sus mapas (`ColorMap`, `NormalMap`…).

Notas generales:

- Cargan **los 51**. Todos son **gratis** y de creadores con insignia de verificado.
- **Ninguna puerta trasera.** No sale ninguna de las 5 familias de la 4ª tanda: ni `require(número)`,
  ni `NumberPose`, ni `GetObjects`, ni `HttpEnabled`, ni atributos raros, ni «CoreValidation». Los
  `require(` que salen son de módulos hijos (A-Chassis, kit de armas). Los `Kick` son de `ClutchKick`
  (embrague) o del retroceso de un arma. Los `string.char` del kit de armas son teclas (W, A, S, D).
- Muchos assets son **viejos** (2010-2017): bloques, `Decal` y `SpecialMesh`, sin PBR.
- Las texturas de `SurfaceAppearance` y los mapas de `MaterialVariant` no se pueden leer desde el
  servidor (sale `¿?`). Las imágenes de otros creadores tampoco se pueden ver por dentro
  (`CreateEditableImageAsync` da «no permission»).
- Triángulos: los totales del toolbox; por malla no se pueden contar.
- ⚠ = tiene scripts: hay que borrarlos o revisarlos al usar el asset.

## Resumen

| id | Qué es | ¿Carga? | Piezas / tris (toolbox) | Scripts | Valoración |
|---|---|---|---|---|---|
| 295604372 | Asteroid space skybox: cielo de espacio con asteroides | ✅ 6/6 caras | 1 `Sky` | 0 | **útil con cuidado** — limpio y carga entero, pero es **espacio** (no sirve de cielo de ciudad). La descripción dice que puede ser del juego *Space Engineers*. |
| 195181959 | Caldari Space Skybox | ✅ 6/6 caras | 1 `Sky` | 0 | **no usar** — sacado de **EVE Online** (lo dice la descripción). |
| 136402262 | Realistic Space Skybox: la Vía Láctea | ✅ 6/6 caras | 1 `Sky` | 0 | **útil con cuidado** — limpio, 192 👍. Solo para una escena de espacio (cohete, planetario), no de día. |
| 6430696462 | Tunel: túnel de carretera | ✅ | 74 piezas / 1 068 tris | 0 | **útil con cuidado** — túnel de 97×40×40 (1 `Union`) con 42 focos `SurfaceLight`. Limpio y ligero, pero de bloques. |
| 223224044 | Realistic Animated water (2015) | ✅ | 3 Part, 6 `Texture` | ⚠ 2 | **no usar** — agua vieja que se mueve cambiando la escala cada 0.1 s. Mejor el agua de Terrain. |
| 8159177542 | Most Realistic Moon in PBR | ✅ | 1 MeshPart PBR / 9 814 tris | 0 | **útil** — luna 3D de 11.9 con `SurfaceAppearance` y un fondo negro (`Decal`). Limpia. Para un observatorio o una escena. |
| 12737479807 | Realistic Moon/Sun Graphics | ✅ | 0 piezas | ⚠ 1 | **útil con cuidado** — un script que crea `Sky` con luna grande (`MoonTextureId` 9013498676, tamaño 14), nubes, Bloom, Blur 3 y SunRays. Limpio. Copiar los valores, no el script (el Blur emborrona). |
| 11365590395 | Realistic Fire With Smoke | ✅ | 1 Part | 0 | **útil** — 1 `ParticleEmitter` (imagen 160041569, 75/s) + `Smoke`. Limpio, 900 👍. Para chimeneas, hogueras, incendios. |
| 11552439884 | Realistic Rain | ✅ | 1 Part 18×10 | ⚠ 1 | **útil con cuidado** — 3 `ParticleEmitter` (imagen 3806148993) y sonido de lluvia **público**. Limpio, pero echa **40 000 gotas por segundo**: en móvil irá muy lento. Bajar mucho el `Rate`. |
| 5033818552 | Realistic Footstep Sounds (Elg0n) | ✅ | 25 `Sound` | ⚠ 1 | **no usar** — 20 de 25 audios **no son públicos** (no suenan en nuestro juego) y son de **Garry's Mod** y **Black Mesa**. |
| 979423743 | lightning & thunder cloud | ✅ | 3 Part / 854 tris | 0 | **no usar** — no hay partículas ni rayos: una nube de malla y una `PointLight` apagada. Sin script no hace nada. |
| 1076538396 | Best Gun Meshes: ~60 armas | ✅ | 179 piezas / 390 412 tris | ⚠ 1 (readme) | **no usar** — armas de **Counter-Strike** («Credit to VALVe»). |
| 546753609 | TurboFusion Gun Kit (P90) | ✅ | 0 piezas | ⚠ 3 | **no usar** — kit de arma. Sin virus (`string.char` = teclas), pero es un arma. |
| 1305075170 | stash: 17 fajos de billetes | ✅ | 34 piezas / 7 888 tris | 0 | **útil con cuidado** — fajos «$10,000» (`TextBox` en `SurfaceGui`). Limpio. Para un banco o una caja fuerte. |
| 991205683 | Pillow | ✅ | 1 Union 1.6×1.0×1.7 | 0 | **útil con cuidado** — una almohada pequeña (una sola `Union`, 304 tris). |
| 4927992927 | Meteors! | ✅ | 0 piezas | ⚠ 1 | **no usar** — lluvia de meteoritos que **hace daño** (50) a los jugadores. |
| 994161570 | Shading V.2 | ✅ | 0 piezas | ⚠ 2 | **útil con cuidado** — crea Bloom, SunRays, ColorCorrection y Blur 1 según la hora. Limpio. Copiar valores; el juego ya tiene su iluminación. |
| 480927087 | Red Dot Sight | ✅ | 6 piezas | 0 | **no usar** — mira de arma. |
| 5674029686 | Mueble (xJavisDonasx) | ✅ | 82 Part / 7 536 tris | 0 | **útil con cuidado** — mueble de 8.8×3.2×2.9 de bloques. Limpio. |
| 9876129164 | «basuraaaa…»: cubo de basura | ✅ | 1 MeshPart 3.6×3.6×7.3 / 172 tris | 0 | **útil** — contenedor ligero con textura (malla del propio autor, 2022). Limpio. |
| 5677783820 | MuebleComputadora | ✅ | 40 Part / 2 664 tris | 0 | **útil con cuidado** — mesa de ordenador de bloques. Limpia. |
| 8136205160 | «t»: retrete | ✅ | 3 MeshPart + `Seat` / 15 044 tris | 0 | **útil con cuidado** — váter de 3.2×8.4×3.7 (mallas del autor, sin textura). Limpio. |
| 9342982592 | climb animation NOT R15 | ✅ | 0 piezas | ⚠ 1 | **no usar** — solo R6, y la animación 9261232372 es **de otro creador** (PizzaConPapitas, no pública): no se reproduce. |
| 9879827254 | Howler / Bacteria: monstruo | ✅ | 8 piezas / 20 548 tris | ⚠ 3 | **no usar** — monstruo de las *Backrooms* que persigue y ataca. Sus animaciones son de otros (no públicas). |
| 12061946559 | R15 Punching Animations | ✅ | 2 maniquíes R15 + 3 `KeyframeSequence` | ⚠ 1 (nota) | **útil** — golpes R15 como `KeyframeSequence` (no hay ids de otros). Hay que **publicarlos con nuestra cuenta** (lo dice la nota). Limpio. |
| 9766849655 | Cupcake | ✅ | 13 piezas / 10 236 tris | 0 | **útil con cuidado** — magdalena de bloques (0.8). Limpia, pero muchos tris para lo pequeña que es. |
| 132859014 | «For Adi - 3rd Point» (2013) | ✅ | 16 piezas | ⚠ 1 | **no usar** — trozo de mapa viejo sin uso claro (bandera, cartel). |
| 80741429 | New Hps: campo de fútbol (2012) | ✅ | 69 piezas | 0 | **útil con cuidado** — campo de 608×470 con porterías y gradas (60 `Decal`). Limpio, pero muy viejo. |
| 898778590 | RS Tennis Court | ✅ | 103 piezas | 0 | **útil** — pista de tenis de 100×115 con valla, 2 bancos y 11 asientos (`Seat`). Limpia. |
| 70353066 | The Best Soccer Stadium (2012) | ✅ | 3 644 piezas, 1 812 `Decal` | ⚠ 50 | **no usar** — muy pesado y con NPCs que dejan **sangre** al morir (`BloodScript`). |
| 75541553 | Modern goal for bola: portería | ✅ | 155 piezas | 0 | **útil con cuidado** — portería de 47×15 hecha de 142 `SpecialMesh` (red). Limpia. |
| 891244647 | Cameraman: NPC con cámara | ✅ | 32 piezas | 0 | **útil con cuidado** — personaje R6 con cámara «Nikon» (nombre, sin logo). Limpio. Para un plató o una boda. |
| 26972564 | bunker build (2010) | ✅ | 12 Part | 0 | **no usar** — 12 bloques, nada útil. |
| 5411055653 | Construction Asset Pack | ✅ | 173 piezas (45 MeshPart) / 100 738 tris | 0 | **útil** — obra: contenedores, bidones, vallas, conos, palés, andamios… Limpio. Mallas del propio autor. Los bidones ponen «Roblox General Technologies» (inventado). |
| 12152263865 | Bronze PBR Pack | ✅ | 6 MeshPart PBR | 0 | **útil** — 3 tipos de bronce (limpio, de estatua, gastado) en esfera y bloque. **No es MaterialVariant**: son `SurfaceAppearance`. Para estatuas. |
| 11330013072 | PBR Moai | ✅ | 1 MeshPart PBR / 846 tris | 0 | **útil con cuidado** — estatua de 2.8×6.1. Limpia, pero sacada de **Splatoon 3** (lo dice la descripción). |
| 11156149162 | PBR C4 | ✅ | 1 MeshPart PBR / 3 353 tris | 0 | **no usar** — explosivo (y su nombre es «Cee Four» para esquivar filtros). |
| 11444948273 | PBR Wooden Door | ✅ | 1 MeshPart PBR / 350 tris | 0 | **útil con cuidado** — puerta de madera PBR de 3.6×7.5, muy ligera. Sacada de **Resident Evil 7**. |
| 11329271645 | PBR Clipboard | ✅ | 1 MeshPart PBR / 318 tris | 0 | **útil con cuidado** — portapapeles de 1.1×1.6. Sacado de **Predator: Hunting Grounds**. |
| 9408271791 | PBR_Textures: 20 MaterialVariant | ✅ | 41 Part de muestra | ⚠ 1 (readme) | **útil** — 20 `MaterialVariant` limpios (ver detalle), uno por material de Roblox. 0 👍 / 10 👎. |
| 9763579280 | Baseball_Bat | ✅ | 3 MeshPart PBR / 6 652 tris | 0 | **útil con cuidado** — bate de 4.4. Limpio (para una tienda de deportes, no como arma). |
| 10396819700 | pallete: palé | ✅ | 1 MeshPart PBR 11.9×1.1×11.2 / 190 tris | 0 | **útil** — palé de madera PBR muy ligero. Limpio. Para almacenes y la obra. |
| 6795368713 | Air Conditioner, Ceiling Fan House: casa con aires y ventiladores | ✅ | 5 491 piezas / 530 485 tris | ⚠ 59 | **útil con cuidado** — sin virus, los aires se encienden con mando. Pero **muy pesado**, con **marcas reales** (Daikin, Panasonic, Mitsubishi, Saijo Denki) y sonidos de compresor **no públicos**. |
| 13465440856 | Funiki air conditioner | ✅ | 134 piezas / 57 154 tris | ⚠ 4 | **útil con cuidado** — aire acondicionado con mando. Limpio, pero marca real (**Funiki**) y sus sonidos («Carrier») **no son públicos**. |
| 15418880736 | 2013 Hyundai Elantra | ✅ | 133 piezas (123 MeshPart) / 280 265 tris | ⚠ 26 | **no usar** — coche real (**Hyundai**) importado («Importer: KIM_angels7»), A-Chassis y 13 sonidos **no públicos**. |
| 16893586720 | 2009-2015 Thaco Mobihome 45 Seats: autocar | ✅ | 1 804 piezas / 75 933 tris | ⚠ 68 | **útil con cuidado** — autocar vietnamita de 47 de largo, 45 `Seat`. Sin virus, pero marca real (**Thaco**, motor con logo **Hyundai**), matrícula de **Vietnam**, 32 sonidos **casi todos no públicos** y A-Chassis. |
| 1119962617 | skool: Roblox High School v1 (2017) | ✅ | 2 981 Part | 0 | **no usar** — copia del mapa del juego **Roblox High School**. |
| 266515007 | [FBF] Panzer IV (2015): tanque alemán | ✅ | 79 piezas / 12 499 tris | ⚠ 6 | **no usar** — tanque de la **Alemania nazi** (2ª Guerra Mundial) que dispara. Sus 2 imágenes **no se pueden ver** (ver detalle): no se puede descartar un símbolo nazi. |
| 9700798278 | (RCM) M16 Pack | ✅ | 49 piezas / 39 079 tris | ⚠ 10 | **no usar** — fusiles con sonidos de **Escape from Tarkov** (no públicos). |
| 10491752124 | SCP-087-B Hallway | ✅ | 4 Part, 24 `Texture` | 0 | **no usar** — pasillo de terror (SCP) y «Please do not reupload». |
| 3778526307 | Custom Material Pack 1 | ✅ | 41 piezas, 232 `Texture` | ⚠ 60 | **útil con cuidado** — 8 materiales hechos con `Texture` (moqueta, baldosa oscura, lava, goma, esponja, porexpán, bambú, agua animada con 60 scripts). **No son MaterialVariant.** Limpio. Solo para copiar ids. |

### Datos del toolbox

| id | Nombre | Creador | 👍/👎 | Tris | Vértices | MeshParts | Scripts | Decals | Audios | Tools | Precio | Creado |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 295604372 | Asteroid space skybox | Hydrablox ✔ | 34 / 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2015-09-11 |
| 195181959 | Caldari Space Skybox | Hydrablox ✔ | 19 / 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2014-12-22 |
| 136402262 | Realistic Space Skybox | Hydrablox ✔ | 192 / 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2013-11-24 |
| 6430696462 | Tunel | Arthurzin210412 ✔ | 0 / 0 | 1 068 | 1 960 | 0 | 0 | 0 | 0 | 0 | gratis | 2021-02-22 |
| 223224044 | Realistic Animated water(INF) | ItsLino_FTW ✔ | 71 / 29 | 48 | 96 | 0 | 2 | 0 | 0 | 0 | gratis | 2015-03-05 |
| 8159177542 | Most Realistic Moon in  P B R | Carcat62 ✔ | 0 / 0 | 9 814 | 9 585 | 1 | 0 | 1 | 0 | 0 | gratis | 2021-12-02 |
| 12737479807 | Realistic Moon/Sun Graphics | AlexioDay2137 ✔ | 15 / 5 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | gratis | 2023-03-10 |
| 11365590395 | Realistic Fire With Smoke | agentphilip07 ✔ | 900 / 100 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | gratis | 2022-10-24 |
| 11552439884 | Realistic Rain | Bxt2i ✔ | 276 / 24 | 0 | 0 | 0 | 1 | 0 | 1 | 0 | gratis | 2022-11-13 |
| 5033818552 | Realistic Footstep Sounds! | Elg0n ✔ | 3 850 / 1 150 | 0 | 0 | 0 | 1 | 0 | 25 | 0 | gratis | 2020-05-15 |
| 979423743 | lightning & thunder cloud | Elg0n ✔ | 0 / 0 | 854 | 429 | 0 | 0 | 0 | 0 | 0 | gratis | 2017-08-14 |
| 1076538396 | Best Gun Meshes | Elg0n ✔ | 67 / 3 | 390 412 | 373 762 | 138 | 1 | 0 | 0 | 0 | gratis | 2017-09-30 |
| 546753609 | TurboFusion Gun Kit | Elg0n ✔ | 0 / 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | gratis | 2016-11-15 |
| 1305075170 | stash | Elg0n ✔ | 0 / 0 | 7 888 | 11 900 | 0 | 0 | 0 | 0 | 0 | gratis | 2018-01-06 |
| 991205683 | Pillow | Elg0n ✔ | 0 / 0 | 304 | 280 | 0 | 0 | 0 | 0 | 0 | gratis | 2017-08-19 |
| 4927992927 | Meteors! | Elg0n ✔ | 0 / 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | gratis | 2020-04-21 |
| 994161570 | Shading V.2 | Elg0n ✔ | 0 / 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | gratis | 2017-08-21 |
| 480927087 | Red Dot Sight | Elg0n ✔ | 0 / 0 | 317 | 435 | 0 | 0 | 1 | 0 | 0 | gratis | 2016-08-15 |
| 5674029686 | Mueble | xJavisDonasx ✔ | 0 / 0 | 7 536 | 6 828 | 0 | 0 | 0 | 0 | 0 | gratis | 2020-09-10 |
| 9876129164 | basuraaaa… | xJavisDonasx ✔ | 0 / 0 | 172 | 276 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-06-11 |
| 5677783820 | MuebleCom######## | xJavisDonasx ✔ | 0 / 0 | 2 664 | 2 580 | 0 | 0 | 0 | 0 | 0 | gratis | 2020-09-10 |
| 8136205160 | t | xJavisDonasx ✔ | 0 / 0 | 15 044 | 30 178 | 3 | 0 | 0 | 0 | 0 | gratis | 2021-11-29 |
| 9342982592 | climb animation NOT R15 | PizzaConPapitas ✔ | 0 / 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | gratis | 2022-04-11 |
| 9879827254 | Howler / Bacteria entity NPC | PizzaConPapitas ✔ | 0 / 0 | 20 548 | 11 641 | 1 | 3 | 0 | 1 | 0 | gratis | 2022-06-11 |
| 12061946559 | R15 Punching Animations | Auevi ✔ | 77 / 23 | 5 524 | 6 650 | 28 | 1 | 3 | 0 | 0 | gratis | 2023-01-05 |
| 9766849655 | Cupcake | Auevi ✔ | 6 / 4 | 10 236 | 12 461 | 0 | 0 | 0 | 0 | 0 | gratis | 2022-05-30 |
| 132859014 | For Adi - 3rd Point | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2013-10-18 |
| 80741429 | New Hps | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2012-05-13 |
| 898778590 | RS Tennis Court | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2017-07-04 |
| 70353066 | The Best Soccer Stadium | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2012-01-18 |
| 75541553 | Modern goal for bola | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2012-03-23 |
| 891244647 | Cameraman | vitormehugo ✔ | 0 / 0 | (no lo da) | (no lo da) | — | — | — | — | — | gratis | 2017-06-30 |
| 26972564 | bunker build! | coolman265 ✔ | 0 / 0 | 2 230 | 1 540 | 0 | 0 | 0 | 0 | 0 | gratis | 2010-05-11 |
| 5411055653 | [600 SALES!] Construction Asset Pack | MissingFeature ✔ | 10 / 0 | 100 738 | 97 973 | 45 | 0 | 0 | 0 | 0 | gratis | 2020-07-23 |
| 12152263865 | Bronze PBR Pack | SulkyRap ✔ | 0 / 0 | 1 332 | 2 268 | 6 | 0 | 0 | 0 | 0 | gratis | 2023-01-14 |
| 11330013072 | PBR Moai | SulkyRap ✔ | 60 / 0 | 846 | 488 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-10-20 |
| 11156149162 | PBR C4 | SulkyRap ✔ | 0 / 0 | 3 353 | 6 585 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-10-03 |
| 11444948273 | PBR Wooden Door | SulkyRap ✔ | 8 / 2 | 350 | 830 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-11-01 |
| 11329271645 | PBR Clipboard | SulkyRap ✔ | 9 / 1 | 318 | 751 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-10-20 |
| 9408271791 | PBR_Textures | IAmAGreenStickMan ✔ | 0 / 10 | 492 | 984 | 0 | 1 | 0 | 0 | 0 | gratis | 2022-04-19 |
| 9763579280 | Baseball_Bat | IAmAGreenStickMan ✔ | 0 / 0 | 6 652 | 5 834 | 3 | 0 | 0 | 0 | 0 | gratis | 2022-05-29 |
| 10396819700 | pallete | IAmAGreenStickMan ✔ | 0 / 0 | 190 | 380 | 1 | 0 | 0 | 0 | 0 | gratis | 2022-07-29 |
| 6795368713 | Air Conditioner, Ceiling Fan House | dinhtrung3 ✔ | 0 / 0 | 530 485 | 845 875 | 51 | 59 | 295 | 21 | 0 | gratis | 2021-05-10 |
| 13465440856 | Funiki air conditioner (unknown model) | dinhtrung3 ✔ | 0 / 0 | 57 154 | 72 487 | 2 | 4 | 4 | 4 | 0 | gratis | 2023-05-17 |
| 15418880736 | 2013 Hyundai Elantra (Base Model) | dinhtrung3 ✔ | 0 / 0 | 280 265 | 416 134 | 123 | 23 | 0 | 13 | 0 | gratis | 2023-11-21 |
| 16893586720 | 2009-2015 Thaco Mobihome 45 Seats | dinhtrung3 ✔ | 0 / 0 | 75 933 | 105 856 | 54 | 64 | 47 | 32 | 0 | gratis | 2024-03-27 |
| 1119962617 | skool | MrMcGillMan789 ✔ | 0 / 0 | 35 356 | 70 712 | 0 | 0 | 0 | 0 | 0 | gratis | 2017-10-21 |
| 266515007 | [FBF] Panzerkampwagen IV Ausf G (Mouse Controlled) | MrMcGillMan789 ✔ | 0 / 0 | 12 499 | 20 533 | 0 | 6 | 6 | 2 | 0 | gratis | 2015-07-06 |
| 9700798278 | (RCM) M16 Pack | MrMcGillMan789 ✔ | 0 / 0 | 39 079 | 49 104 | 38 | 0 | 0 | 70 | 5 | gratis | 2022-05-22 |
| 10491752124 | SCP-087-B Hallway | Sheny_Berry ✔ | 10 / 0 | 96 | 192 | 0 | 0 | 0 | 0 | 0 | gratis | 2022-08-05 |
| 3778526307 | Custom Material Pack 1 | SomeLoverForRoblox ✔ | 5 / 5 | 8 992 | 7 616 | 0 | 60 | 1 | 0 | 0 | gratis | 2019-09-01 |

(✔ = creador verificado. El toolbox cuenta como «scripts» solo Script y LocalScript. Para los assets de
vitormehugo no da tris ni contadores.)

## Detalle por id

### Cielos, luna y sol

Los 3 cielos son de **Hydrablox** y solo traen un `Sky`. Las **6 caras cargan** en los 3
(`PreloadAsync` → `Success`), y también el sol y la luna (los de Roblox, `rbxasset://sky/sun.jpg` y
`moon.jpg`). Los 3 tienen `CelestialBodiesShown=false` (sin sol ni luna) y `StarCount=0`.

| id | Caras (Bk, Dn, Ft, Lf, Rt, Up) | Origen |
|---|---|---|
| 295604372 Asteroid | 198433424, 198442292, 198433337, 198437520, 198437454, 198433823 | «Might be from Space Engineers» |
| 195181959 Caldari | 195172655, 195181441, 195172600, 195172868, 195172794, 195178542 | «From **EVE Online**» ⛔ |
| 136402262 Realistic Space | 155441936, 155441802, 155441818, 155441777, 155441874, 155441905 | Vía Láctea, 900×900 por cara |

Son cielos de **espacio**: para una ciudad de día no sirven. El juego ya tiene su cielo
(`shared/SkyChoice`, `World/SkyLoader`).

#### 8159177542 — Most Realistic Moon in PBR (Carcat62)

`Moon` (MeshPart 11.9×11.9×11.9, malla 6723918305, `SurfaceAppearance`) y `Background` (Part
0×52.8×66.5 con un `Decal` 7795740122, fondo negro). Sin scripts. La miniatura pública del fondo no se
ve, pero la imagen carga en el servidor.

#### 12737479807 — Realistic Moon/Sun Graphics (AlexioDay2137)

Un `Script` («MoonSettings», 1 164 letras, limpio) que crea al arrancar:
`Sky` con `MoonAngularSize=14`, `MoonTextureId=rbxassetid://9013498676`, `StarCount=100`;
`Lighting.Ambient` 38,38,38, `Brightness=2`, `OutdoorAmbient` 17,17,17; `Clouds` (Cover 0.672,
Density 0.5); `BloomEffect` (1, 24, 2); `BlurEffect` 3; `SunRaysEffect` (0.224, 0.534). Es para la
noche. Si se quiere la luna grande, copiar solo `MoonTextureId` y `MoonAngularSize`.

### Fuego, lluvia y rayos

#### 11365590395 — Realistic Fire With Smoke (agentphilip07)

Una Part 4×1×2 con `ParticleEmitter` «Fire» (imagen **160041569**, carga; `Rate=75`, `Lifetime=1`) y
`Smoke` (Size 0.1, Opacity 1). Sin scripts. 900 👍.

#### 11552439884 — Realistic Rain (Bxt2i)

Part «Rain» de 18.1×0.1×10.1 con 4 `ParticleEmitter` (imagen **3806148993**, carga): `Rain1` 15 000/s,
`Rain2` 10 000/s, `Rain3` 15 000/s y uno apagado. Sonido «Rain Sound Effect» (9064263922, AisarRedux)
**público**, en bucle. Script «Settings» (882 letras, limpio): velocidad y cantidad de gotas.
40 000 partículas por segundo es demasiado para móvil: si se usa, dejar ~2 000.

#### 979423743 — lightning & thunder cloud (Elg0n)

3 Part: una nube (`SpecialMesh`), un «Lightning» con `PointLight` (Brightness 0, Range 0, morada) y
otra pieza. **No hay `ParticleEmitter` ni scripts**: no hace rayos.

### Sonidos y animaciones

#### 5033818552 — Realistic Footstep Sounds (Elg0n)

`LocalScript` «LocalFootsteps» (limpio) con 25 `Sound`, uno por material. Solo 5 son **públicos**:

| Material | Audio | Creador | ¿Público? |
|---|---|---|---|
| Brick, Cobblestone, Foil, Glass, Ice, Marble, Pebble, SmoothPlastic | 178190837 «GMod Walking Sound Tile» | Zoidberg656 | ❌ |
| Concrete | 277067660 «Black Mesa Walking Sound Concrete» | Zoidberg656 | ❌ |
| CorrodedMetal, DiamondPlate, Metal, Neon, Plastic | 177940974 «GMod Walking Sound Metal» | Zoidberg656 | ❌ |
| Granite, Slate | 178054124 «GMod … Gravel» | Zoidberg656 | ❌ |
| Grass | 177940963 «GMod … Grass» | Zoidberg656 | ❌ |
| Sand | 212011266 «GMod … Sand» | Zoidberg656 | ❌ |
| Wood | 177940988 «GMod … Wood» | Zoidberg656 | ❌ |
| WoodPlanks | 211987063 «GMod … Wooden Plank» | Zoidberg656 | ❌ |
| Snow | 1664205910 | ZnowyOreo | ❌ |
| Fabric | 133705377 «Carpet Footstep» | bloberous | ✅ |
| Climb | 145180175 «ladder4» | Elmuowo | ✅ |
| Air, ForceField | 329997777 «Air Conditioner Sound» | Siamosaurus | ✅ |

Además los sonidos son de **Garry's Mod** y **Black Mesa**. Para pasos, mejor los de SCP:CB de la 4ª
tanda (131772048424194, todos públicos).

#### 9342982592 — climb animation NOT R15 (PizzaConPapitas)

Script de 312 letras: en `PlayerAdded` cambia `Animate.climb.ClimbAnim.AnimationId` a **9261232372**
(«Untitled Animation Clip 24», de PizzaConPapitas, **no pública**). En nuestro juego no se reproduciría.
Y es solo para R6.

#### 12061946559 — R15 Punching Animations (Auevi)

Una carpeta con 2 maniquíes R15 (28 MeshPart de Roblox) y **3 `KeyframeSequence`** (27 fotogramas).
**No hay `Animation` con id de otro creador**: las animaciones están «en crudo» y hay que publicarlas
con nuestra cuenta (lo dice la nota: «make sure to publish the animation yourself»). Sin virus.

#### 9879827254 — Howler / Bacteria (PizzaConPapitas)

Monstruo de las *Backrooms* con «Basic Monster» de ArceusInator (persigue y ataca), sonido de
persecución público y 11 `Animation`: las suyas («Bacteria Idle», «Bacteria Walk», «kill») y una de
peepsmanuk, **ninguna pública**.

### Materiales

#### 9408271791 — PBR_Textures (IAmAGreenStickMan)

20 `MaterialVariant` dentro de `placeinmaterialservice` (hay que moverlos a `MaterialService`) y 41
losetas de muestra. README limpio. Los mapas (`ColorMap`, `NormalMap`…) no se pueden leer desde el
servidor.

| Name | BaseMaterial | StudsPerTile | MaterialPattern |
|---|---|---|---|
| Brick_PBR | Brick | 15.8 | Regular |
| Cobblestone_PBR | Cobblestone | 15.8 | Organic |
| Concrete_PBR | Concrete | 20 | Organic |
| Granite_PBR | Granite | 5.9 | Organic |
| CorrodedMetal_PBR | CorrodedMetal | 5.9 | Organic |
| Diamondplate_PBR | DiamondPlate | 3.0 | Regular |
| Fabric_PBR | Fabric | 17.9 | Regular |
| Foil_PBR | Foil | 16.3 | Regular |
| Glass_PBR | **Ice** (no Glass) | 10 | Regular |
| Wood_PBR | Wood | 8.4 | Regular |
| WoodPlanks_PBR | WoodPlanks | 8.4 | Regular |
| Sand_PBR | Sand | 8.4 | Regular |
| Slate_PBR | Slate | 3.0 | Regular |
| Metal_PBR | Metal | 3.0 | Regular |
| Marble_PBR | Marble | 5.9 | Organic |
| Grass_PBR | Grass | 3.0 | Regular |
| Plastic_PBR | Plastic | 10 | Regular |
| Pebble_PBR | Pebble | 17.9 | Regular |
| SmoothPlastic_PBR | SmoothPlastic | 3 | Regular |
| Ice_PBR | Ice | 8.4 | Regular |

Ojo: tiene 10 👎 y ningún 👍; no se ha podido ver cómo quedan. Si se usan, probarlos antes en una pared.
El juego ya tiene sus materiales (`shared/UserMaterialChoice`).

#### 12152263865 — Bronze PBR Pack (SulkyRap)

**No trae `MaterialVariant`.** Son 6 MeshPart con `SurfaceAppearance`: «Bare Bronze», «Statue
Bronze» y «Clean Bronze», cada uno como esfera y como bloque (carpetas `Spheres` y `Blocks`). Para usar
el bronce hay que copiar el `SurfaceAppearance` a otra malla.

#### 3778526307 — Custom Material Pack 1 (SomeLoverForRoblox)

**No trae `MaterialVariant`.** 8 losetas con 6 `Texture` cada una (232 en total): Water (357078195,
animada con 60 scripts `TextureAnim`), Sponge (3730599210), Rubber (3730679083), Carpet (3730714552),
Tight Bamboo (3730811074), Styrofoam (3730842142), Dark Tiles (3730859747) y Lava. Todas las imágenes
cargan. Scripts limpios (solo mueven la textura del agua).

### Props PBR (SulkyRap e IAmAGreenStickMan)

Una sola MeshPart con `SurfaceAppearance` cada uno, sin scripts. Mallas subidas por el propio autor,
pero **sacadas de videojuegos** (lo dicen sus descripciones):

| id | Objeto | Talla | Tris | De dónde |
|---|---|---|---|---|
| 11330013072 | Moai | 2.8×6.1×2.9 | 846 | **Splatoon 3** |
| 11156149162 | C4 («Cee Four») | 1.7×0.5×0.8 | 3 353 | (explosivo) |
| 11444948273 | Wood Door | 3.6×7.5×0.6 | 350 | **Resident Evil 7** |
| 11329271645 | Clipboard | 1.1×0.2×1.6 | 318 | **Predator: Hunting Grounds** |
| 9763579280 | Baseball_Bat (3 mallas) | 4.4×0.3×0.3 | 6 652 | — |
| 10396819700 | pallete | 11.9×1.1×11.2 | 190 | — |

### Obra, casa y muebles

#### 5411055653 — Construction Asset Pack (MissingFeature)

173 piezas (45 MeshPart, 24 Union), 54.7×6.6×18.9. Contenedores, bidones de 55 galones, vallas,
andamio, palés, conos… Mallas del propio autor (2020). Sin scripts. Los bidones llevan textos
inventados («Roblox General Technologies», «55 GALLONS»). La descripción dice que hay una versión nueva
(6398806309, «Construction Set 2.0»).

#### 6795368713 — Air Conditioner, Ceiling Fan House (dinhtrung3)

Una casa entera (104.6×48.8×154.4, **5 491 piezas**, 9 872 `ManualWeld`) con muebles, ordenador,
chimenea, ventiladores de techo y 6 aires acondicionados que funcionan con un mando (`ClickDetector`):
«Saijo Denki», «Luxiar», «Eminent», «Luxiar Split ASC-002» (por dentro: «Mitsubishi Kirigamine Zen» y
«Mitsubishi Electric»), «Daikin» (con «Daikin Logo») y «Panasonic» (con «Panasonic Logo»). 59 scripts,
todos limpios (abrir tapa, girar aspas, subir y bajar temperatura). Sonidos: el del aire
(1330849332, KaviRegime) y el pitido (138081500) son **públicos**; el compresor y el condensador
(DiamondDoesStuff) **no**. Mallas de DiamondDoesStuff (2018).

#### 13465440856 — Funiki air conditioner (dinhtrung3)

134 piezas (2 MeshPart de DiamondDoesStuff), 6.2×8.0×2.8, con mando y 4 scripts limpios. Sonidos
«Carrier running/startup» (Lazy_Pleco) **no públicos**. Marca real **Funiki** (Vietnam).

#### 5674029686 / 5677783820 / 9876129164 / 8136205160 (xJavisDonasx)

Mueble de 82 bloques (8.8×3.2×2.9), mesa de ordenador de 40 bloques, cubo de basura de una malla con
textura (3.6×3.6×7.3, 172 tris) y retrete de 3 mallas sin textura con `Seat` (3.2×8.4×3.7). Todo
limpio; mallas del propio autor.

#### 1305075170 — stash / 991205683 — Pillow / 9766849655 — Cupcake

17 fajos «bandz» con un `TextBox` «$10,000» cada uno (sin scripts); una almohada (`Union`); una
magdalena de 13 piezas con cereza. Todo limpio.

### Deporte

- **898778590 — RS Tennis Court**: pista de 56.5×70.5 con red, valla con `Texture` (27149256), 2
  «Billionare Bench» y 11 `Seat`. Limpia, 103 piezas.
- **80741429 — New Hps**: campo de fútbol de 608×470 con porterías, 2 gradas y 60 `Decal`. Sin scripts.
- **75541553 — Modern goal for bola**: portería de 14.8×47.2×47.2 (155 Part, red de `SpecialMesh`).
- **70353066 — The Best Soccer Stadium**: estadio de 569×149×488, 3 644 piezas, 1 812 `Decal` (2 no
  cargan), marcador, máquina de Bloxy Cola, puertas y NPCs con `AimScript` y **`BloodScript`** (crean
  charcos rojos «Blood» al morir). 50 scripts, ninguno peligroso. Demasiado viejo y pesado.
- **891244647 — Cameraman**: R6 con 3 accesorios, camisa, pantalón y una cámara («Nikon» solo de
  nombre). Sonidos de Roblox.

### Vehículos

#### 16893586720 — 2009-2015 Thaco Mobihome 45 Seats (dinhtrung3)

Autocar de 15.7×13.7×47.3, 1 804 piezas (54 MeshPart de **mlritc01**, 2020; 1 166 Part y 507 Wedge),
**45 `Seat`** + `VehicleSeat`, TV, motor detallado («3IMZ-EIT»). Hecho por «Really312». A-Chassis con
plugins (luces, limpiaparabrisas, ruido de turbo). 68 scripts **sin virus** (los `require(` son de
módulos hijos; `Kick` es `ClutchKick`). Marcas: el nombre **Thaco**, un `Decal` llamado «hyundai» en
el motor (135513876) y matrícula «vintage license plate vietnam». De 32 sonidos casi todos **no son
públicos** (motor de mlritc01, puertas de Floppa98, uno «[ Content Deleted ]»).

#### 15418880736 — 2013 Hyundai Elantra (dinhtrung3)

Coche de 8.8×6.2×19.4, 123 MeshPart (malla de **KIM_angels7**, 2022; su GUI dice «Importer :
KIM_angels7»: modelo real importado). A-Chassis con 26 scripts limpios. 13 sonidos **no públicos**
(«Hyundai Chime», «Toyota Corolla Cut», «AE86 Ignition», de Motive y FreeRoam Studios). Marca y modelo
reales.

#### 266515007 — [FBF] Panzer IV Ausf G (MrMcGillMan789, 2015)

Tanque de 16.9×29.1×60: 79 piezas (32 Union, sin MeshPart), `VehicleSeat`, cañón que dispara (AP/HE),
ametralladora, GUI «Fire MG: C / Switch Ammo Type: E». 6 scripts viejos, **sin virus**. Sonidos
públicos (disparo de Worthe, cañón de GregTame).

**Búsqueda de símbolos de odio**: ningún nombre, texto ni id tiene «swastika», «nazi», «hitler»,
«reich», «卐»… Las 2 partes rojas son los aros de la torreta (196,40,28). Pero lleva **6 `Decal` en la
torreta** que **no se pueden ver**:

- 161612792 «RA» (armyboy465, 2014) ×4
- 257258497 (MrMcGillMan789, 2015) ×2 — **Roblox ha tapado su nombre con «##### ### ###### #######»**
  (su filtro de palabras).

Las dos cargan en el servidor, pero su miniatura pública sale **vacía** (la imagen de «no disponible»,
cuando otras imágenes del mismo año sí salen) y no se pueden leer por dentro (`EditableImage`: «no
permission»). Es un Panzer IV de la Wehrmacht: lo normal sería una cruz de hierro, pero **no se puede
descartar una esvástica**. Y aunque no la tenga, es un tanque nazi que dispara. **No usar.**

### Armas y otros (no usar)

- **1076538396 — Best Gun Meshes**: ~60 armas (Glock 18, M4A1-S, AWP…) de **Counter-Strike**
  («Credit to VALVe»), mallas de PrimeFIRE94 (2016).
- **546753609 — TurboFusion Gun Kit**: GUI y scripts de un P90 (112 260 letras). `string.char` son
  teclas (17-20 = flechas, 48 = «0»); sin virus.
- **9700798278 — (RCM) M16 Pack**: 5 fusiles, 70 sonidos de **Escape from Tarkov** (no públicos).
- **480927087 — Red Dot Sight**, **11156149162 — C4**, **4927992927 — Meteors!** (hace 50 de daño).
- **1119962617 — skool**: «Roblox High School v1», 2 981 bloques de varios constructores.
- **10491752124 — SCP-087-B Hallway**: pasillo de terror de 40×9.5×6 con 24 `Texture`.
- **132859014**, **26972564**: trozos de mapas viejos sin uso.
- **223224044**: agua de 2015 hecha con bloques que cambian de tamaño.

## Lo mejor de esta tanda

Esta tanda está **limpia** (ningún virus), pero casi todo es viejo o de bloques. Lo aprovechable:

1. **5411055653 — Construction Asset Pack.** La obra: contenedores, bidones, vallas, conos, palés y
   andamio en malla, sin scripts. Junto con el **palé 10396819700** (PBR, 190 tris).
2. **11365590395 — fuego con humo.** Un `ParticleEmitter` limpio y ligero: copiar la imagen
   **160041569** y sus valores para chimeneas, barbacoas e incendios.
3. **11552439884 — lluvia.** Imagen de gota **3806148993** y sonido de lluvia **9064263922** (público).
   Bajar el `Rate` de 40 000 a ~2 000 por segundo.
4. **12061946559 — golpes R15.** 3 animaciones de puñetazo en `KeyframeSequence`, sin ids de otros:
   publicarlas con nuestra cuenta y usarlas en peleas.
5. **8159177542 — luna PBR.** Para un observatorio o un planetario. Y de **12737479807** copiar la luna
   grande para la noche (`MoonTextureId` 9013498676, `MoonAngularSize` 14).
6. **9408271791 — 20 MaterialVariant.** Uno por cada material de Roblox (ver tabla). Probar antes cómo
   quedan (tiene 10 👎) y cambiar `Glass_PBR`, que usa `Ice`.
7. **898778590 — pista de tenis.** Limpia, con bancos y asientos.
8. **9876129164 / 8136205160** — cubo de basura y retrete de malla, ligeros, para calles y baños.
9. **12152263865 — bronce PBR** para estatuas de la plaza (copiar el `SurfaceAppearance`).
10. **6795368713 — aires acondicionados (solo uno).** Sacar un solo aparato, quitar logos y nombres
    (Daikin, Panasonic, Mitsubishi…) y los sonidos no públicos (dejar 1330849332 y 138081500).

**Con cuidado**: la puerta (RE7), el Moai (Splatoon 3) y el portapapeles (Predator) son bonitos y
ligeros, pero vienen de videojuegos. El autocar Thaco sirve de base para un autocar, quitando la marca,
el logo «hyundai», la matrícula y los sonidos.

**No hay cielos para la ciudad**: los 3 son de espacio (y uno de EVE Online).

## Nunca usar

- **Armas y explosivos**: 1076538396 (Counter-Strike), 546753609, 480927087, 9700798278 (Tarkov),
  11156149162 (C4), 4927992927 (meteoritos que hacen daño).
- **Símbolos o temas de odio**: **266515007** (tanque nazi con imágenes que no se pueden revisar).
- **Sacados de otros juegos**: 195181959 (EVE Online), 1119962617 (Roblox High School), 5033818552
  (sonidos de Garry's Mod y Black Mesa, casi todos privados).
- **Terror**: 9879827254 (Backrooms), 10491752124 (SCP).
- **Marca real importada**: 15418880736 (Hyundai Elantra).
- **Sangre**: 70353066 (`BloodScript` en sus NPCs).
- **No sirven**: 979423743 (no hace rayos), 9342982592 (animación ajena, R6), 223224044, 132859014,
  26972564.
