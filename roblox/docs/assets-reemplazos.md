# Reemplazos limpios para los assets descartados

Buscados en la Tienda de Roblox para cambiar los assets marcados **No** en `docs/assets-implementados.md`
(puertas traseras, cosas de otros juegos, marcas reales, sangre o demasiado pesados).
Fecha: 2026-10-05. Aquí solo se elige; otra sesión los mete en el juego.

Cómo se hizo (igual que `docs/assets-usuario-4.md` y `-5.md`):

- Búsqueda: `apis.roblox.com/toolbox-service/v1/marketplace/10?keyword=…` y datos de cada uno con
  `toolbox-service/v1/items/details` (creador, fecha, votos, triángulos, si es gratis).
- Volcado en un servidor de Roblox con `AssetService:LoadAssetAsync`:
  `scripts/cloud/assets-reemplazos.luau` → `bash scripts/cloud-test.sh -v assets-reemplazos`
  (5 ejecuciones de unos 10 ids). Clases, mallas, `SurfaceAppearance`, sonidos (y si son públicos),
  imágenes, atributos y cada script entero si sale algo grave.
- Además de lo de la 5ª tanda, el script busca las señales de las **5 familias** de puertas traseras:
  `require(número)`, `GetObjects`, `HttpEnabled`, «CoreValidation», «SkyLink», «PoseLink»,
  «Texture Streaming», «TextureConfiguration», `NumberPose`, `PlaneConstraint`, `string.char`,
  `getfenv`, `loadstring`, `setclipboard`…
- Creador de cada malla con `economy.roblox.com/v2/assets/<id>/details`.
- Logos: miniaturas del modelo y de sus texturas con `thumbnails.roblox.com`.

**Resultado general: ninguno de los 48 volcados tiene puerta trasera** (5511084119 se descartó por su
descripción y su volcado se cortó). Ni un `require(número)`, ni
`GetObjects`, ni `HttpEnabled`, ni `NumberPose`, ni atributos raros (solo `WindSpeed`/`WindPower` en una
palmera). Los únicos `require(` son los de módulos hijos del chasis A-Chassis (normal).

Roblox (creador id 1) casi no publica modelos sueltos: lo suyo son packs (Forest Pack, Landscaping Pack,
City Road Pack, City Building Pack…). Esos packs **ya están revisados** en `docs/modelos-tienda-contenido.md`
y `docs/modelos-oficiales-2.md` y salen como primera opción donde sirven.

⚠ = trae scripts o algo que hay que quitar al usarlo. Triángulos: los totales del toolbox.

## Resumen: qué usar

| # | Hace falta | Elegido | Segunda opción | Qué quitar |
|---|---|---|---|---|
| 1 | Palmeras / plantas tropicales | **10562894034** (3 mallas, 316 tris) | 7862261626 (palmera PBR, 15 518 tris) · 9501994254 (pack tropical PBR, por piezas) | nada / atributos de viento |
| 2 | Cerezo (sakura) | **10586979345** (11 785 tris, 980 👍) | 15343255788 (6 416 tris) · 10964163041 (1 437 tris) | `StringValue`, emisor de pétalos si se quiere |
| 3 | Arbustos | **Landscaping Pack 10840661513** (Roblox: carpeta `Bushes`, 19 PBR) | 9522573337 (PBR Bush) · Forest Pack 6432306802 (`MountainLaurelBush`) | scripts de los packs |
| 4 | Hoguera | **Landscaping Pack 10840661513 → `FirePit`** (Roblox, PBR) | 8839325037 (12 732 tris) · 9769594863 (1 218 tris) | sonido privado ⚠ en 9769594863 |
| 5 | Farol de piedra japonés | **9854052347** (1 malla con textura, 9 171 tris) | 12521854808 (3 334 tris, PBR en parte) · 5242410723 | sonido privado ⚠ en 12521854808 |
| 6 | Estatua / cabeza de piedra | **4698399766** (perro-león de piedra, 1 998 tris) | 98862949352791 (estatua antigua de piedra) · 16920341663 (moái sencillo) | nada |
| 7 | Autobús urbano | **16358361587** (5 mallas, 9 062 tris, sin logos) | 4128266372 (malla ligera; trae 50 scripts ⚠) | rótulo «CENTURY LINE 7701» si se quiere otro |
| 8 | Autocar interurbano | **95641562400547** (19 mallas, 30 649 tris, sin logos) | 1743965400 (43 090 tris; A-Chassis ⚠) | `Decal`/`Texture` de suciedad, `BoolValue` |
| 9 | Camión caja | **4128265113** (3 mallas, 8 771 tris, blanco sin logos) | 7170735914 (1 malla, 5 035 tris) | piezas sueltas de 7170735914 |
| 10 | Rueda / neumático | **8448337398** (1 malla PBR, 7 200 tris) | 17601139281 (rueda con llanta, 4 392 tris) · 5250689014 (492 tris) | nada |
| 11 | Skyline lejano (mallas) | **16524471626** (1 malla PBR de 617×259×545, 6 076 tris) | City Building Pack 6418277837 (Roblox) · 14664172946 | nada |
| 12 | Colegio | **76558120171446** (colegio de ladrillo 414×79×108, 44 318 tris) | 10905662931 (más pesado) | `Camera` |
| 13 | Estadio de fútbol | **15569059562** (17 mallas, 102 317 tris) | 112163108303427 (kit modular de 8 mallas) · 79597956338483 | nada |
| 14 | Carreteras y marcas (PBR) | **City Road Pack 6432233485** (Roblox, PBR + mallas de marcas) | 12790045445 (`MaterialVariant` asfalto) · 11135057011 | scripts del pack |
| 15 | Paisaje tropical / bosque | **Forest Pack 6432306802** (Roblox) + **9501994254** (tropical PBR) | 17531535054 (vegetación PBR) · 8011666557 | scripts de animales del Forest Pack; el maniquí «Scale» de 9501994254 |

## Detalle por necesidad

### 1. Palmeras realistas / vegetación tropical

Reemplaza a 114397068371248 y 72475149726020 (familia 1).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 10562894034 «Palm Tree (Realistic)» | Natalie_Clabo, 2022, 279 👍 / 21 👎 | 3 `MeshPart` (2 con `SurfaceAppearance`), 36×52×36, 316 tris. Mallas del propio autor. 0 scripts. | ✅ **usar**. Muy ligera: sirve para poner muchas. |
| 7862261626 «RTX Palm Tree» | mrtrolldos, 2021, 96 👍 | 3 `MeshPart` PBR, 49×77×68, 15 518 tris. Mallas del autor y de Some_Swan (2019). Atributos `WindSpeed=12`, `WindPower=0.6` en las hojas (para un script de viento que no viene). | ✅ **usar** para palmeras «de primer plano». Quitar los atributos o dejarlos (no hacen nada). |
| 88842453042625 «PBR Palm Tree's (Optimized)» | Simpli Studios (grupo), 2025 | 44 `MeshPart` PBR en 3 tamaños, 77 258 tris, 23 `Motor6D`, 3 `ModuleScript` «MeshIds» (solo listas de ids, nada peligroso). Mallas de H0L0HKDOFiH. | ⚠ útil con cuidado: borrar los 3 `ModuleScript` y los `Motor6D`. |
| 9501994254 «Tropical PBR Plants» | EnvirobIox, 2022, 198 👍 | 112 `MeshPart` / 108 PBR: 7 palmeras (Large/Curved/Straight/Dark/Thick/Small/Stump Palm), bananeros, helechos, `TropicalBush`… 441 310 tris en total. 0 scripts. Mallas recopiladas de otros (el autor lo dice); 6 de 12 de la muestra son de la cuenta **THEQuixel**. | ⚠ útil por piezas (no entero: pesa mucho). Quitar el maniquí «Scale» (`Humanoid` + `Decal`) y la `Camera`. |
| 17531535054 «PBR Miami Vegetation» | H0L0HKDOFiH, 2024 | 39 `MeshPart` / 35 PBR, 70 116 tris, 0 scripts. Mallas de varios creadores (2017-2021). | útil con cuidado, por piezas. |

Ya en el juego (limpias): palmeras de 8553512581 y 13388285234.

### 2. Cerezo (sakura)

Reemplaza a 109211499509239 (familia 1). Ya hay otro cerezo limpio en 96924659951632.

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 10586979345 «Cherry Blossom Tree» | TheLunar_Mothz, 2022, **980 👍 / 20 👎** | 2 `MeshPart` (tronco PBR), 67×73×51, 11 785 tris, 2 `ParticleEmitter` de pétalos (imagen 243160943, 6/s), 2 `StringValue` («classic»). 0 scripts. Es el **original** que copió el virus 109211499509239 (mismos tris). | ✅ **usar**. Quitar los `StringValue`. |
| 15343255788 «Sakura Park Tree» | VonStarBlack, 2023, 97 👍 | 2 `MeshPart`, 45×48×34, 6 416 tris, 1 emisor de pétalos. 0 scripts. | ✅ usar (más pequeño, para parques). |
| 10964163041 «PBR Sakura Tree with Falling Leaves» | EnvirobIox, 2022 | 2 `MeshPart` PBR, 17×20×20, 1 437 tris, hojas que caen. 0 scripts. | ✅ usar (cerezo pequeño y muy ligero). |
| 16014247305 «Japanese Sakura Tree v1» | kedyhizm, 2024 | **Copia exacta** de 10586979345. | no hace falta (usar el original). |

### 3. Arbustos realistas

Reemplaza a 126164979250031 (familia 1).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 10840661513 Landscaping Pack – Duvall Drive | **Roblox** | Carpeta `Bushes`: 19 `MeshPart` PBR (setos largo/corto, rododendros, laurel, helecho, plantas). Revisado en `docs/modelos-tienda-contenido.md`. | ✅ **usar**: lo mejor (oficial y PBR). Coger solo `Bushes`. |
| 9522573337 «PBR Bush» | EnvirobIox, 2022, 80 👍 | 3 `MeshPart` PBR, 7.5×6.1×7.8, 13 821 tris. 0 scripts. La hoja es la malla del Forest Pack de Roblox. | ✅ usar. |
| 6432306802 Forest Pack | **Roblox** | `MountainLaurelBush_Var01` (2 mallas PBR). (9187138703 es una copia de este mismo arbusto.) | ✅ usar el original. |
| 10907214341 «Realistic Tree & Bush Pack» | luckycowboy44, 2022 | 85 `MeshPart` sin PBR, 52 `Texture` + 21 `Decal` viejos, 168 000 tris. Limpio. | no usar: viejo y pesado. |

### 4. Hoguera

Reemplaza a 116641210728889 (familia 5).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 10840661513 Landscaping Pack → `FirePit` | **Roblox** | Pozo de fuego de ladrillo PBR (46 `MeshPart`, 43 PBR). También `Prop_FirewoodGrate` y leñeros. | ✅ **usar**. Añadir fuego con nuestro VFX (o el `ParticleEmitter` de 11365590395, ya revisado). |
| 8839325037 «Campfire» | SergoUral_2, 2022 | 9 `MeshPart` (piedras, leña, hierba) con textura, 6.3×1.5×6.4, 12 732 tris, `ParticleEmitter` de fuego (imagen de Roblox), `Smoke`, `PointLight`. 0 scripts. Mallas de Some_Swan (2019). | ✅ usar (hoguera de campamento). |
| 9769594863 «Campfire» | randomonen, 2022 | 13 `MeshPart` (una piedra repetida), 1 218 tris, 2 emisores, `PointLight`. ⚠ `Sound` «Fire Noise» **no público** (no suena en nuestro juego). | útil con cuidado: borrar el `Sound`. |
| 4141615992 «Realistic Campfire (Mesh)» | bearduckmonkey, 2019 | Las mismas mallas que 8839325037. ⚠ 1 script que hace parpadear la luz (`while true … wait(.001)`, inofensivo pero gasta). | no hace falta (8839325037 es igual sin script). |

### 5. Farol de piedra japonés (tōrō)

Reemplaza a 78188971759943 (familias 3 y 5).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 9854052347 «Realistic Japan Lantern» | OKION12345, 2022 | 1 `MeshPart` con textura de piedra con musgo, 3.8×7×3.8, 9 171 tris. Malla del autor. 0 scripts. | ✅ **usar**. Añadir una `PointLight` dentro si se quiere de noche. |
| 12521854808 «japanese lantern» | cybidal, 2023, 58 👍 | 4 `MeshPart` (2 PBR), 3×6.9×3, 3 334 tris, `PointLight` de vela. ⚠ `Sound` «SouffleBougie» **no público**. | ✅ usar: borrar el `Sound`. |
| 5242410723 «Japanese Toro Stone Lantern Slamo» | Bnobington, 2020 | Mismas mallas (de ExecutiveKrab) sin textura, 3 532 tris, `PointLight`, 1 `Union`. 0 scripts. | útil (versión lisa). |
| 9366198884 «Japanese Sakura Stone Toro Lantern» | grannyfrous, 2022, 88 👍 | Mismas mallas + enredadera rosa (17 `Part`), 12 964 tris. 0 scripts. | útil con cuidado (rosa, solo para jardín japonés). |

### 6. Estatua grande de piedra / monumento

Reemplaza a 11330013072 (malla de *Splatoon 3*).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 4698399766 «Lion Dog Statue» | Suizei, 2020 | 1 `MeshPart` de 16×24×22 (perro-león guardián, *komainu*), 1 998 tris, material piedra (`Slate`). Malla de BL00MIE (2019). 0 scripts. | ✅ **usar** para plazas, templo o museo. Genérico. |
| 98862949352791 «Ancient Statue» | IAmASwedishMale, 2025 | 1 `MeshPart` con textura: figura de piedra antigua (estilo moái con cuerpo). 20 000 tris. Viene **diminuta** (0.2×0.4): hay que escalarla. 0 scripts. | ✅ usar (escalar a 15-25 studs). |
| 16920341663 «Moai» | IamKikin (grupo), 2024 | 1 `MeshPart` con textura, 16×26×16, 612 tris. Moái sencillo de pocas caras. 0 scripts. | útil (si se quiere justo una cabeza tipo moái). |
| 102795561208384 «Moai Statue» | maikl12345jo, 2025 | 1 malla «12329_Statue_v1_l3» (nombre de un modelo de una web 3D externa) de 168×163×258; en la miniatura parece una losa. | **no usar**: origen dudoso y no se reconoce. |

Opción oficial: Landscaping Pack tiene `Outdoor_Statues` (estatuas PBR y armilares), pero las estatuas se
llaman «Occult_…»: mirar antes cuál encaja.

### 7. Autobús urbano realista (sin logo real, < 60 000 tris)

Reemplaza a 18912826861 (255 000 tris, logo real).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 16358361587 «City Bus» | 2races, 2024 | 5 `MeshPart` (Body PBR, Glass, Glass2, Lights, Decals), 14×14×55, **9 062 tris**. Mallas del autor. 0 scripts. Texturas revisadas: carrocería blanca con franjas azules, **sin logos**. El rótulo dice «CENTURY LINE» y el número «7701» (inventados). | ✅ **usar**. Solo carrocería: nuestras puertas, asientos y `BusService` van aparte. Se puede cambiar la textura del rótulo. |
| 4128266372 «City Bus (Mesh)» | bearduckmonkey, 2019 | 6 `MeshPart` (de TMM16, 2016), 4 468 tris, pero ⚠ 50 scripts (chasis viejo, luces, radio con `MarketplaceService:GetProductInfo` para el nombre de la canción: no es virus) y sonidos privados. | útil con cuidado: quedarse solo con las 6 mallas. |
| 17430288419 «Coach Bus Prop» | Qinggg77 | Textura con el galgo y «Americruiser» de **Greyhound** (marca real). | **no usar**. |

### 8. Autocar interurbano

Reemplaza a 16893586720 (bloques).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 95641562400547 «Tour Bus» | yiypoo1024, 2026 | 19 `MeshPart` (pintura, cromados, cristales, interior, luces, ruedas), 11×13×46, 30 649 tris. Mallas de RealgrumpyKitten1 (2022). 0 scripts. Texturas sin logos. Trae 14 `Decal` y 24 `Texture` de **suciedad** («Tour Bus Abandonned») y un `BoolValue`. | ✅ **usar**: borrar los `Decal`/`Texture` de suciedad para que parezca nuevo. |
| 1743965400 «Coach bus» | PrestigiousJay, 2018 | 73 `MeshPart` (de ZonedMoled), 43 090 tris, 32 asientos, ⚠ 30 scripts (A-Chassis + puertas con `ClickDetector`), 15 sonidos (la mayoría privados). Sin virus. | útil con cuidado: quedarse con las mallas. |

### 9. Camión caja / de reparto

Reemplaza a 130974691456028 (familia 3).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 4128265113 «box truck mesh» | bearduckmonkey, 2019, 93 👍 | 3 `MeshPart` (cabina, caja, cristal), 28×12×9, 8 771 tris. Mallas de crabbyninja (2018). 0 scripts. Texturas blancas **sin logos**. | ✅ **usar**. |
| 7170735914 «Mesh Van / Truck / Box Truck (closed back)» | alosks, 2021, 50 👍 | 1 `MeshPart` (la misma malla de TCtully que usaba el virus, pero esta subida está limpia), 5 035 tris, + 2 `Part`, 1 `WedgePart` y un `Decal` de persiana para cerrar la caja. 0 scripts. Sin logos. | ✅ usar. Quitar la `Camera`. |
| 116752155328441 «Box Truck» | yiypoo1024, 2025 | 4 camiones PBR. Uno lleva «Post… Express» y otro un logo de heladería; el nombre dice «ATS Ultimaster Aeromaster» (modelo real). | **no usar** (rótulos de marcas). |

### 10. Rueda / neumático de coche

Reemplaza a 131247677717086 (4 neumáticos pegados, familias 3 y 4).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 8448337398 «Realistic Tire» | SubXero_X, 2022 | 1 `MeshPart` PBR, 1.1×3.1×3.1, 7 200 tris. Malla de TTerukai (2021). 0 scripts. Solo el neumático (sin llanta). | ✅ **usar**. (No es el pack de coches de SubXero_X con trampa: este es solo una malla.) |
| 17601139281 «Realistic Car Wheel» | DREDD_465, 2024 | 6 `MeshPart` (4 PBR): neumático + llanta, 1.5×2.7×2.7, 4 392 tris. 0 scripts. | ✅ usar (rueda completa). |
| 5250689014 «Car Wheel» | diberek, 2020 | 1 `MeshPart` con textura, 492 tris. «Not made by me» (malla de Uncle_Venti, 2018). | útil (muy ligera, para lejos). |
| 6975741757 «Car Wheel» | flanbows, 2021 | 1 `MeshPart`, 2 061 tris. Limpio. | útil. |

### 11. Skyline lejano (mallas, no foto)

Reemplaza a 139484418601989 (familia 4, foto de Tokio). Ojo: el skyline actual usa 79665094662717 (familias
3 y 4, ya se le quita el virus al cargar); estas son alternativas limpias.

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 16524471626 «City Background Night» | FBIpewpewpew, 2024 | **1 sola `MeshPart` PBR** de 617×259×545 con ~15 rascacielos, 6 076 tris. Ventanas que brillan de noche. 0 scripts. | ✅ **usar**: perfecto como fondo lejano y muy ligero. |
| 6418277837 City Building Pack | **Roblox**, 637 👍 | 12 edificios grandes PBR (682 mallas, 517 932 tris). Revisado en `docs/modelos-oficiales-2.md`. | ✅ usar unos pocos, escalados, para el horizonte. |
| 14664172946 «citymeshpack» | Reset49592848, 2023 | 21 `MeshPart` (15 PBR) de rascacielos, 20 889 tris. Mallas de varios creadores. 0 scripts. | útil con cuidado. |
| 72733628132945 «Skyscraper» | totothetortilla, 2024 | 4 mallas + 922 `Part`. | no usar (muchas piezas para un solo edificio). |
| 5511084119 «Low-Poly Buildings Pack» | Killercloudz | La descripción dice que las mallas se **compraron en la tienda de Unity** y se suben gratis. | **no usar** (licencia). |

### 12. Colegio realista

Reemplaza a 1119962617 (copia de *Roblox High School*).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 76558120171446 «Modern Brick School Building» | ROKE0, 2025 | Colegio de ladrillo de 414×79×108: 6 `MeshPart` (de tlllik) + 3 122 `Part` (ventanas), 44 318 tris. 0 scripts, 0 sonidos, 0 imágenes. Solo fachada. | ✅ **usar** (por fuera). Quitar la `Camera`. Mirar si las 3 122 piezas se pueden juntar. |
| 10905662931 «High School» | CoolEthan127319, 2022 | 6 771 piezas (BlockMesh, uniones, 89 asientos), 176 378 tris, con interior. 0 scripts. 1 sonido público. | útil con cuidado: muy pesado. |

### 13. Estadio de fútbol (mallas)

Reemplaza a 70353066 (2012, NPCs con sangre).

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 15569059562 «Mini Football stadium» | Evexnio, 2023 | 17 `MeshPart` (1 PBR) de 228×39×129: campo, porterías con red, gradas bajas. 102 317 tris. 0 scripts. Sin logos. | ✅ **usar**. |
| 112163108303427 «Modular Soccer Stadium Kit» | Irchris5, 2026 | 8 `MeshPart` con nombre (grada recta y de esquina, túnel, torre de focos, portería, trozo de césped, tejado, trofeo), 144 000 tris. 0 scripts. | ✅ usar para montar un estadio a medida. |
| 79597956338483 «Football Stadium» | Dom's Workshop (grupo), 2024 | 300 `MeshPart` + 427 `Part` + **1 200 `Seat`**, 606×170×677, 97 064 tris. Sin texturas. 0 scripts. | útil con cuidado: grande y gris. Borrar casi todos los `Seat`. |
| 3098736664 «Large Stadium» | Mattk1612, 2019 | 1 810 piezas, 273 `Decal`: 210 usan la imagen 1539341292, que Roblox tiene **bloqueada** (moderada). | **no usar**. |

### 14. Carreteras y marcas viales (PBR)

Reemplaza a 12527638598, 16088161488 y 11347783499.

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 6432233485 City Road Pack | **Roblox** | Tramos de calle, cruces, curvas, aceras y pasos de cebra PBR, con mallas de marcas para poner encima. Revisado en `docs/modelos-tienda-contenido.md`. | ✅ **usar** sus texturas/marcas. Quitar sus 10 scripts (señales). |
| 12790045445 «Asphalt Material Variant» | TheECOMaster, 2023 | 1 `MaterialVariant` «Asphalt2» (base Asphalt, 15 studs/tile, patrón Organic). Limpio. | ✅ usar como asfalto PBR. |
| 11135057011 «Asphalt PBR» | TheRobloxGamer15782, 2022 | 1 `MaterialVariant`. Limpio. | útil. |
| 121476408957815 «Road [materials]» | enzojet777, 2025 | 1 `MaterialVariant` «Road» con base **Grass** (raro). | no usar. |

Los mapas de los `MaterialVariant` no se pueden ver desde el servidor (`¿?`): mirarlos en Studio.

### 15. Paisaje tropical y de bosque

| id | Creador | Contenido | Veredicto |
|---|---|---|---|
| 6432306802 Forest Pack | **Roblox** | Hayas, cornejo, arce, helechos, troncos caídos, rocas PBR. Revisado. | ✅ **usar**. Quitar los 13 scripts (mariposas, peces, halcones). |
| 9501994254 «Tropical PBR Plants» | EnvirobIox | Ver punto 1. | ✅ usar por piezas. |
| 17531535054 «PBR Miami Vegetation» | H0L0HKDOFiH | Ver punto 1. | útil por piezas. |
| 8011666557 «Mega Tropical Pack» | PriorMentation, 2022 | 45 `MeshPart` PBR + 17 `Union`, 54 `Texture` y 48 `Decal` (flores de cícada), 120 217 tris. 0 scripts. | útil con cuidado: quitar `Decal`/`Texture`. |

## Para quien los meta en el juego

- Copiar solo `MeshPart` + `SurfaceAppearance` (como ya hace NatureAssets/CityAssets) y borrar scripts,
  sonidos privados, `Camera`, `Humanoid`, `StringValue`, `BoolValue` y `Motor6D`.
- Ninguno de estos lleva `NumberPose`, `PlaneConstraint` con atributos, ni nada de las 5 familias. Si al
  cargar aparece algo así, es que el autor lo ha cambiado: no usarlo.
- Datos crudos: `${TMPDIR:-/tmp}/cloud-test/assets-reemplazos.log` al relanzar el script.
