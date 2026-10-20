# Auditoría del mar (fase 1 del encargo v2)

Encargo: `encargo-v2-reconstruccion.md`. Captura que lo motiva: `captura-dueno-v123-orilla.png`.
Esta auditoría es de lo que había **antes** de la v124 (el código de la rama a 20-10-2026).

## Cómo se construye hoy el mar

| Pieza | Dónde | Qué hace |
|---|---|---|
| Losa del mar | `World/TerrainBuilder` | Alrededor de toda la isla: fondo de `Salt` de -24 a -14 y agua de -14 a -2. `Salt` teñido casi blanco (236, 232, 214). |
| Fondo hondo | `shared/Sea/Ocean.sample` + `World/OceanBuilder.terrain` | Heightfield por distancia a la costa: -14 hasta 60 studs de la arena, plataforma hasta -48 a 360 studs, talud hasta -132 a 820 studs; ruido de 3-7 studs. Abismo, Sima, Garganta Negra y Cañón de las Catedrales por fórmulas. Se rellena en bloques de 16×16 studs (~53 000 `FillBlock`). |
| Relieve | `OceanBuilder.relief` | Agujas de basalto, arcos, la Catedral Abisal, la Guarida del Kraken, la Bolsa de Aire: **todo a 2-5 km de las playas**. |
| Orilla (v122) | `OceanBuilder.shore` | Manchas de arena/caliza, dunas de `Salt` y rocas de 1-3 studs cada ~26 studs a lo largo de la costa. Arco pequeño y montículos en cada jardín de coral. |
| Sitios (POI) | `OceanBuilder.sites` | Pecio, ruinas, batiscafo, ballena, jardines… con ≤ 900 piezas en total. Los jardines de coral de la orilla (`Ocean.ShoreReefs`): bolas de colores. |
| Decorado del fondo | `Controllers/SeaBiome` (cliente) | Trozos de 14 studs alrededor de la cámara (56 studs en el móvil). En cada trozo, 0-5 cosas elegidas con un hash **repartidas por igual**: recetas de `shared/Sea/ShoreDecor` (bolas, elipsoides y cilindros de 1-5 studs). Tope 1400/3000 piezas. |
| Luz bajo el agua | `SeaBiome` → `Controllers/EnvDirector` (zona `Submarino` de `shared/Cosmos/EnvZones`) → `DayLight` | La de la zona (`OceanBiomes.Zones[].Look`) mezclada con la profundidad. La orilla: bruma cian claro (64, 186, 200), tinte casi blanco (170, 236, 240), exposición +0,08, densidad 0,30. |
| Vida | `Controllers/SeaLife` | Bancos de peces (boids), rayas, tortugas, medusas… repartidos al azar alrededor. |
| Nácara | `shared/Sea/Nacara`, `World/NacaraBuilder` | La plaza de prueba a 37,5 m en (-2650, 5000), lejos de las playas. |
| Nadar | `Controllers/Swimming`, `shared/Swim`, `Controllers/SeaMotion`, `Controllers/AgeMotion` | Flotación propia y postura con código. |

## Por qué se ve plano (medido, no opinado)

`scripts/test-reefzone-camera.luau` lanza 880 rayos de pantalla desde la cámara de tercera persona. En la
orilla tal como estaba (solo el fondo; el decorado de SeaBiome mide 1-5 studs y no tapa nada):

| Vista (antes) | Suelo en pantalla | Formaciones | Horizonte con algo |
|---|---|---|---|
| Llegada al jardín de Playa Dorada | **57 %** | 0 % | **0 %** |
| Jardín del Faro, mirando al mar | **53 %** | 0 % | **0 %** |

Causas:
1. **No hay altura que ver.** Junto a las playas el agua tiene 12 studs (fondo -14, superficie -2) y la
   cámara va 4-10 studs por encima del fondo: el suelo llena media pantalla y el resto es agua o la
   superficie. Nada en 200 studs pasa de 5 studs de alto → el horizonte es una línea vacía.
2. **Lo grande está lejos.** Cañones, arcos y cuevas existen, pero a 2-5 km; casi todos los jugadores
   solo nadan a 100 studs de la arena.
3. **Repartido por igual.** Cada trozo de 14 studs recibe lo mismo con un hash: sin racimos, sin sendas,
   sin puntos de interés → «objetos de colores sobre un suelo».
4. **Nieve en vez de arena.** `Salt` casi blanco bajo una bruma cian clara y poco densa: sin contraste,
   sin profundidad (captura v123).
5. **Piezas sueltas.** Corales = bolas lisas; hierbas = tablas; rocas = racimos de bolas (v122).
6. **Bug de la postura** (aparte): el estado Swimming del Humanoid tumba el HumanoidRootPart y la postura
   de SeaMotion se sumaba encima → cabeza abajo («nada al revés»). Arreglado en `9f93af5`.

## Qué se conserva

Todo lo que funciona sigue: el heightfield y sus zonas, oxígeno/profundidad/equipo (`shared/Sea/Diving`),
misiones y cofres (`OceanService`), Nácara, criaturas, HUD, barcos. Nada se borra; la zona nueva se
**añade** encima (fase 3) y solo cambia lo que estaba mal en todas partes (color de la arena, luz de la
orilla, racimos en SeaBiome).
