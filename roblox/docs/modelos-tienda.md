# Modelos gratuitos de la Tienda de creadores para sustituir props procedurales

Investigación del 2026-10-01 para *Real Life Simulator* (pueblo mediterráneo). Datos sacados de la API pública del toolbox de Roblox (sin login). **Nada de esto se ha probado aún en Studio.**

## Cómo leer la tabla

- **Insignia verificada**: `hasVerifiedBadge` real del usuario/grupo (users.roblox.com / groups.roblox.com). Ojo: el campo `isVerifiedCreator` del toolbox sale `true` en casi todos (es verificación de ID para publicar), así que NO sirve como filtro.
- **⭐Avalado**: `isEndorsed` (Roblox lo recomienda en la Tienda).
- **Scripts / MeshParts / Decals / Triángulos**: `modelTechnicalDetails` del toolbox (conteo de instancias y triángulos totales del modelo, o del pack entero si es un pack).
- **SurfaceAppearance**: la API no da ese conteo y no se pudo descargar el `.rbxm` para mirarlo (ver *Endpoints*). Se marca *Sí* solo cuando lo dice la descripción oficial y *Probable* si el nombre dice PBR. El resto hay que comprobarlo en Studio.
- Scripts ⚠️ = el modelo trae scripts. En los de **Roblox oficial** son de confianza (luces, semáforos, viento), pero igualmente conviene borrarlos o revisarlos al clonar. En modelos de la comunidad: **evitar o borrar todos los scripts** antes de usarlos.
- Votos de 0 = modelo poco usado; puede ser bueno, pero hay que revisarlo a mano.

## Árboles

| ID | Nombre | Creador | Insignia verificada | Votos (👍/total) | Gratis | Scripts | MeshParts | Decals/Texturas | SurfaceAppearance | Triángulos | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6432306802 | Forest Pack ⭐Avalado | Roblox (Roblox oficial) | ✅ | 1940/2000 (97%) | Sí | ⚠️ 13 (oficial) | 83 | 0 | Sí (descripción) | 153 252 | Pack oficial: árboles/arbustos/flores con SurfaceAppearance (lo dice la descripción). Cargar 1 vez y clonar piezas. |
| 3256343670 | Realistic Trees | Chr1sDevv | — | 3680/4000 (92%) | Sí | 0 | 7 | 0 | ? | 11 550 | El árbol realista más votado de la tienda; MeshParts. |
| 9271152246 | Realistic Tree | Nafica08 | — | 1880/2000 (94%) | Sí | 0 | 1 | 0 | ? | 1 319 | Muy votado y ligerísimo (≈1,3k tris); ideal para repetir en calles. |
| 10131972958 | Realistic Tree | Mrwalter87 | — | 970/1000 (97%) | Sí | 0 | 1 | 0 | ? | 1 147 | Muy votado y ligero (≈1,1k tris). |
| 6020696518 | Realistic Tree | Adrijan0830 | — | 970/1000 (97%) | Sí | 0 | 2 | 0 | ? | 15 468 | Muy votado; algo pesado (15k tris) → solo para plazas. |
| 15799943463 | old oak tree | Grant_2003 | — | 768/800 (96%) | Sí | 0 | 0 | 3 | ? | 6 782 | Roble viejo muy votado; usa decals (texturas), no MeshPart. |
| 11672970103 | Oak Tree | Dankattsu | — | 430/500 (86%) | Sí | 0 | 3 | 0 | ? | 469 | Roble ligerísimo (469 tris), estilo semi-realista. |
| 98950444096614 | (PBR) Realistic Oak Trees Pack Free | Letaij | — | 0 | Sí | 0 | 15 | 0 | Probable (nombre PBR) | 21 184 | Pack de robles PBR (15 MeshParts). Sin votos aún; Letaij publica mucho PBR gratis. |
| 5392132809 | Realistic Pine Tree | GabeQZ | — | 97/100 (97%) | Sí | 0 | 3 | 0 | ? | 10 048 | Pino realista bien votado. |
| 11664016667 | PBR Pine Trees | EnvirobIox | — | 56/60 (94%) | Sí | 0 | 4 | 0 | Probable (nombre PBR) | 14 238 | Pinos PBR (SurfaceAppearance por el nombre). |
| 96983263473828 | Realistic Stone Pine Tree Pack | Letaij | — | 0 | Sí | 0 | 10 | 0 | ? | 44 282 | Pino piñonero (muy mediterráneo). Sin votos. |
| 104437096952591 | Mediterannean Stone Pines Pack🌲 | -Andrulelo Games- (grupo) | — | 0 | Sí | 0 | 14 | 0 | ? | 103 424 | Pinos piñoneros 'Mediterranean'; pesado (103k tris el pack). Sin votos. |
| 12637929826 | Cypress tree | Letaij | — | 0 | Sí | 0 | 6 | 0 | ? | 3 999 | Ciprés ligero (≈4k tris, 6 MeshParts). Sin votos: revisar en Studio. |
| 8847636685 | Cypress | Benoxity | — | 0 | Sí | 0 | 1 | 0 | ? | 10 027 | Ciprés (1 MeshPart, 10k tris). Sin votos: revisar. |
| 10562894034 | Palm Tree (Realistic) | Natalie_Clabo | ✅ | 279/300 (93%) | Sí | 0 | 3 | 0 | ? | 316 | Palmera realista, creador con insignia verificada, ligerísima (316 tris). |
| 471214939 | Realistic Palm Tree | Narrakin | — | 186/200 (93%) | Sí | 0 | 1 | 0 | ? | 1 032 | Palmera realista bien votada (≈1k tris). |
| 13834448670 | Urban Tree | progameralexrock | — | 0 | Sí | 0 | 3 | 2 | ? | 2 305 | 'Urban Tree' ligero (2,3k tris), útil para alcorques. Sin votos. |
| 14636162882 | road tree | Pizzatoast0 | — | 9/10 (93%) | Sí | 0 | 2 | 0 | ? | 8 277 | 'road tree' de calle (8k tris). |
| 10088225842 | PBR - Nature Pack | RoCreative Development (grupo) | — | 98/100 (98%) | Sí | 0 | 131 | 4 | Probable (nombre PBR) | 208 609 | Pack PBR de naturaleza (grupo), bien votado; 208k tris en total. |
| 13536410655 | PBR foliage and nature pack | moviroon | — | 196/200 (98%) | Sí | 0 | 225 | 0 | Probable (nombre PBR) | 883 938 | Pack PBR muy votado pero MUY pesado (≈884k tris en total): usar piezas sueltas. |
| 6933438443 | Synty Nature Pack ⭐Avalado | Roblox (Roblox oficial) | ✅ | 768/800 (96%) | Sí | 0 | 200 | 0 | ? | 108 816 | Pack oficial Synty (low-poly, licenciado). Alternativa estilizada si lo realista desentona. |
| 7990107300 | Foliage Pack (Realistic) - Tree Bush Grass | Qalus | — | 198/200 (99%) | Sí | ¿? (sin datos) | ? | ? | ? | ? | Muy votado pero la API NO da datos técnicos (scripts desconocidos): revisar antes. |

## Arbustos y setos

| ID | Nombre | Creador | Insignia verificada | Votos (👍/total) | Gratis | Scripts | MeshParts | Decals/Texturas | SurfaceAppearance | Triángulos | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 10840661513 | Landscaping Pack - Duvall Drive ⭐Avalado | Roblox (Roblox oficial) | ✅ | 198/200 (99%) | Sí | ⚠️ 4 (oficial) | 1803 | 3 | Probable (pack 'realista' Duvall Drive) | 912 716 | Pack oficial Duvall Drive: setos que encajan entre sí, arbustos, flores, macetas. Calidad 'realista' de Roblox. |
| 9522573337 | PBR Bush | EnvirobIox | — | 80/100 (80%) | Sí | 0 | 3 | 0 | Probable (nombre PBR) | 13 821 | Arbusto PBR bien votado (13,8k tris). |
| 8647777369 | Bush | Seespotbyte | — | 1860/2000 (93%) | Sí | 0 | 0 | 0 | ? | 576 | Arbusto muy votado y ligero (576 tris); más estilizado. |
| 8174229353 | Pink Flower Bush | Unlimitens | — | 388/400 (97%) | Sí | 0 | 2 | 0 | ? | 2 645 | Arbusto con flores rosas (parecido a adelfa/buganvilla), muy votado, 2,6k tris. |
| 8344171779 | Flower Bush | Woof_HDPlay | — | 285/300 (95%) | Sí | 0 | 2 | 0 | ? | 2 497 | Arbusto con flores, muy votado. |
| 9187138703 | Realistic bush flowers mesh | omarllollo | — | 94/100 (94%) | Sí | 0 | 2 | 0 | ? | 2 645 | Arbusto con flores realista, 2,6k tris. |
| 14161520172 | Realistic Bush | strikelife947 | — | 19/20 (96%) | Sí | 0 | 2 | 0 | ? | 1 368 | Arbusto realista ligero (1,4k tris). |
| 12728953454 | Realistic Bush | EvilSwrd | — | 25/30 (85%) | Sí | 0 | 2 | 0 | ? | 9 950 | Arbusto realista (≈10k tris). |
| 11459010005 | square bush (pbr))))) | 4w4qz | — | 77/80 (97%) | Sí | 0 | 2 | 0 | Probable (nombre PBR) | 40 000 | Seto cuadrado PBR muy votado, pero 40k tris → pocos o solo cerca. |
| 16324445883 | Bush Leaves Grass | 21stnv | ✅ | 55/60 (93%) | Sí | 0 | 9 | 0 | ? | 43 911 | Arbustos/hojas, creador con insignia verificada; 44k tris el conjunto. |
| 14899059537 | Bush Boxwood-Wall | helsin12345u27aa | — | 0 | Sí | 0 | 301 | 0 | ? | 8 144 | Muro de boj (seto) — 301 MeshParts, revisar rendimiento. |

## Calle

| ID | Nombre | Creador | Insignia verificada | Votos (👍/total) | Gratis | Scripts | MeshParts | Decals/Texturas | SurfaceAppearance | Triángulos | Notas |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6370681139 | City Props Pack ⭐Avalado | Roblox (Roblox oficial) | ✅ | 576/600 (96%) | Sí | ⚠️ 2 (oficial) | 94 | 0 | Sí (descripción) | 66 318 | Pack oficial: farola, banco, papelera, buzón, boca de incendios, jardineras… con SurfaceAppearance. 2 scripts oficiales (luces). |
| 6432233485 | City Road Pack ⭐Avalado | Roblox (Roblox oficial) | ✅ | 846/900 (94%) | Sí | ⚠️ 10 (oficial) | 196 | 4 | Sí (descripción) | 69 002 | Pack oficial de calles/aceras PBR + stop y semáforos animados (10 scripts oficiales). |
| 404475960 | Street light | Simoon68 | ✅ | 3640/4000 (91%) | Sí | 0 | 0 | 0 | ? | 8 106 | Farola clásica muy votada; creador con insignia verificada. 8k tris. |
| 15472204631 | Street Lamp Light | BryanROBLOXgamer10 | — | 182/200 (91%) | Sí | 0 | 1 | 0 | ? | 768 | Farola ligera (768 tris) bien votada. |
| 8916801819 | Realistic Street Lamp | SparkTehDog | — | 36/40 (92%) | Sí | 0 | 1 | 0 | ? | 768 | Farola realista ligera (768 tris). |
| 5036801877 | medieval lamp post | DeadzoneRemadeLEVEL | — | 76/80 (95%) | Sí | 0 | 0 | 0 | ? | 11 978 | Farola de estilo antiguo (casco histórico), bien votada; 12k tris. |
| 4832491624 | Garden Lamp Post | Hisuteria | — | 42/50 (85%) | Sí | 0 | 0 | 0 | ? | 3 356 | Farola de jardín, 3,4k tris. |
| 185280084 | Generic Park Bench ⭐Avalado | Carollicious | — | 1820/2000 (91%) | Sí | 0 | 0 | 0 | ? | 5 644 | Banco de parque AVALADO (Endorsed) por Roblox y muy votado. |
| 741384218 | The Generic Park Bench with Seats | FoxyTheSaphradite | — | 282/300 (94%) | Sí | 0 | 0 | 0 | ? | 5 644 | Variante del banco anterior, bien votada. |
| 11508587471 | Trash Can | RTopix | — | 37/40 (94%) | Sí | 0 | 3 | 0 | ? | 4 284 | Papelera de parque con MeshParts (4,3k tris). |
| 8351110369 | Trash Bin | herobrinehung | — | 45/50 (90%) | Sí | 0 | 1 | 0 | ? | 20 000 | Papelera; 20k tris (pesada). |
| 18684226685 | Classic Trash Can | EpicBL0P | — | 47/50 (94%) | Sí | 0 | 0 | 0 | ? | 252 | Papelera clásica muy ligera (252 tris), poco detalle. |
| 11452670349 | PBR Fire Hydrant | bayern10 | — | 0 | Sí | 0 | 4 | 0 | Probable (nombre PBR) | 13 812 | Boca de incendios PBR (13,8k tris). Sin votos. |
| 128747015 | Fire Hydrant | blobbyblob | — | 10/10 (100%) | Sí | 0 | 0 | 0 | ? | 2 064 | Boca de incendios clásica (2k tris). |
| 9146797320 | Bollard Kit | thedriftking_9 | — | 0 | Sí | 0 | 0 | 0 | ? | 1 460 | Kit de bolardos (1,5k tris). |
| 10591362816 | British road bollard | 1_DZN | — | 0 | Sí | 0 | 0 | 0 | ? | 768 | Bolardo de calle (768 tris). |
| 6735092557 | Road Sign pack | 1king293 | — | 850/1000 (85%) | Sí | 0 | 0 | 386 | ? | 17 952 | Pack de señales muy votado (usa decals; revisar que no lleven logos). |
| 256177949 | Traffic Sign Pack | My_Comment | — | 29/30 (97%) | Sí | 0 | 0 | 59 | ? | 482 | Pack de señales bien votado y ligero. |
| 2989085739 | Flower Pot | ShugaFoot | — | 37/40 (93%) | Sí | 0 | 0 | 0 | ? | 14 972 | Maceta con flores bien votada (15k tris). |
| 8975295794 | Flower Pot | Noobbreaking | — | 65/70 (94%) | Sí | 0 | 2 | 0 | ? | 2 929 | Maceta con flores bien votada (2,9k tris). |
| 5295646823 | Terracotta Pot | PSY0PZ | — | 0 | Sí | 0 | 1 | 0 | ? | 3 216 | Maceta de terracota (muy mediterránea), 3,2k tris. Sin votos. |
| 12169860688 | Large Terracotta Pot | PSY0PZ | — | 0 | Sí | 0 | 1 | 0 | ? | 2 624 | Maceta grande de terracota, 2,6k tris. Sin votos. |
| 14925057298 | Planter_LargeV1 | Milliankah | — | 0 | Sí | 0 | 3 | 0 | ? | 300 | Jardinera grande, ligera (300 tris). |
| 56449011 | Mailbox | Roblox (Roblox oficial) | ✅ | 34/40 (85%) | Sí | 0 | 0 | 0 | ? | 80 | Buzón oficial Roblox (antiguo y muy simple). |

## Descartados (no usar)

| ID | Motivo |
|---|---|
| 18498913487 | 'Synty City Props [RETEXTURED]': resubida de un pack comercial (posible infracción). |
| 9528430690 | 'Fallout 4 prop pack': modelos extraídos de un videojuego (copyright). |
| 96924659951632 | 'Realistic Trees Pack [MOVING]': 14 scripts. |
| 5324013703 | '(Animated) Realistic tree': 2 scripts. |
| 7061369950 | 'olive tree': 530k tris, inviable. |
| 1479128280 | Hidrantes de marcas reales de EE.UU. (morinabinks) y muy pesados. |

## Consejos para cargarlos

- `InsertService:LoadAsset(id)` devuelve un `Model` contenedor; los packs traen decenas de piezas. Cargar **una vez** en el servidor, guardar en `ServerStorage` y **clonar** las piezas que se necesiten (no llamar a `LoadAsset` por cada árbol).
- Al cargar, recorrer `GetDescendants()` y **destruir** cualquier `Script`/`LocalScript`/`ModuleScript` salvo que se haya revisado (sobre todo en modelos de la comunidad).
- Envolver `LoadAsset` en `pcall` y mantener el prop procedural actual como *fallback* si falla la carga.
- Para móvil: preferir modelos < 5–10k tris para lo que se repite mucho (árboles de calle, arbustos, papeleras) y usar `RenderFidelity = Automatic` en los MeshParts; reservar lo pesado para plazas o puntos focales.
- Packs como *Forest Pack* o *Landscaping Pack* suman cientos de miles de tris en total, pero cada pieza suelta es razonable: se usan piezas, no el pack entero.

## Endpoints probados

| Endpoint | Resultado |
|---|---|
| `GET apis.roblox.com/toolbox-service/v1/marketplace/10?keyword=…&num=30&sortType=Relevance` | ✅ 200, sin login. Admite `creatorTargetId=1&creatorType=1` para filtrar por Roblox. |
| `GET apis.roblox.com/toolbox-service/v1/items/details?assetIds=…` | ✅ 200, sin login. Da `hasScripts`, conteo de instancias, triángulos, votos, `isEndorsed`, `isFree`. |
| `GET economy.roblox.com/v2/assets/{id}/details` | ✅ 200 (incluye `Creator.HasVerifiedBadge`). |
| `POST users.roblox.com/v1/users` / `GET groups.roblox.com/v1/groups/{id}` | ✅ 200, `hasVerifiedBadge` real. |
| `GET apis.roblox.com/assets/v1/assets/{id}` (Open Cloud, `x-api-key`) | ✅ 200, pero solo metadatos (nombre, creador, moderación), no el contenido. |
| `GET assetdelivery.roblox.com/v1/asset/?id=…` | ❌ 401 `Authentication required to access Asset.` |
| `GET apis.roblox.com/asset-delivery-api/v1/assetId/{id}` (`x-api-key`) | ❌ 403 `Forbidden` (la clave no tiene permiso de *legacy asset delivery*). Por eso no se pudo contar SurfaceAppearance dentro de los modelos. |
