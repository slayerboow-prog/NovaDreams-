# Mar v2: diseño, zona de referencia y evidencias

Encargo: `encargo-v2-reconstruccion.md` · Auditoría: `auditoria-v2.md` · Código: `shared/Sea/ReefZone`,
`shared/Sea/MarKit`, `World/ReefZoneBuilder`, `World/MarMeshes`, `Controllers/ReefZoneFx`.

> Todas las imágenes `v2-*.jpg` son **VISTA PREVIA, NO ES ROBLOX** (Blender con la misma geometría y las
> mismas cámaras que el juego, luz aproximada). La prueba de verdad es el móvil del dueño (abajo, §8).

## 1. Dirección de arte

- **Grande primero.** Lo que se lee desde la cámara son siluetas: paredes de 19 a 83 studs (el jugador
  mide 5), un arco que enmarca, columnas, agujas. Los corales y plantas visten esas formas, no las
  sustituyen.
- **Racimos y sendas.** La vida va en parches densos (bommies, repisas, el bosque de kelp, el jardín de la
  cueva) con arena limpia entre ellos: el ojo descansa y sigue el camino.
- **Un punto focal por tramo.** El labio del jardín (cascada de coral) → el kelp → la boca de la cueva →
  el arco → la Pirámide Hundida (luz cian) → las agujas del abismo.
- **Luz con jerarquía.** Arriba turquesa con haces de sol; según se baja, más azul y oscuro; abajo, los
  puntos de luz (pirámide, cueva, setas) son lo que brilla. Pocas luces de verdad (3); lo demás es Neon.
- **Sin copiar nada.** Las referencias son de ambiente; formas y nombres son nuestros.

## 2. Paleta por región

| Región | Agua (bruma) | Fondo | Vida |
|---|---|---|---|
| B Jardín coralino (3-4 m) | turquesa (28, 142, 178) | arena dorada clara (204, 186, 146) con ondas de arenisca | corales cálidos: rosa, naranja, amarillo |
| A Arrecife exterior (cima de la pared norte y repisas) | turquesa → azul | roca gris cálida y caliza clara | cálidos arriba, abanicos y mesas |
| C Caverna (Cueva de la Luz) | azul oscuro | roca | setas y anémonas que brillan: cian, verde, rosa, lila |
| E Ruinas (Pirámide Hundida, ~20 m) | azul (18, 108, 146) | arena y fango | piedra azul pizarra con vetas cian; corales fríos (morado, azul, turquesa) |
| D Borde del abismo (~33-37 m) | azul marino casi negro | fango y tierra | esponjas altas, luces sueltas, nieve marina |

Regla: ningún coral marrón; los cálidos nunca por debajo de los fríos (lo prueba `test-reefzone`).

## 3. Escala

| Cosa | Studs | Metros |
|---|---|---|
| Jugador | 5 | 1,8 |
| Corales | 2-7 | 0,5-2 |
| Kelp gigante | 15-34 | 4-10 |
| Columnas de piedra | 40-50 | 11-14 |
| Pirámide | 30 de alto, 26 de base | 8 |
| Paredes del cañón | 19 (entrada) a 83 (final) | 5-23 |
| Agujas lejanas | 60-90 | 17-25 |

## 4. Composición y los 5 planos

Cada cámara de la revisión tiene algo en primer plano (corales, kelp, la pared), la zona jugable (el
lecho y sus rocas), distancia media (paredes, arco, columnas), fondo lejano (agujas, la otra pared) y el
ambiente (bruma con haces). La revisión por rayos mide cerca / medio / lejos (§7).

## 5. La zona de referencia: el Cañón de Dorada

Delante de **Playa Dorada** (la playa del este). Plano: `v2-mapa-canon.jpg`.

1. **B · Jardín de coral** (x 4260-4360, 3-4 m): ocho bommies (montículos de roca) a distintas alturas con
   racimos de coral, sendas de arena dorada entre ellos, praderas en manchas, estrellas, conchas, erizos y
   cangrejos.
2. **El labio** (x ≈ 4365): el fondo cae; una cascada de coral marca el borde. Lo primero que ves al
   asomarte es el cañón abriéndose.
3. **Kelp gigante** (pie de la pared norte, x 4400-4490, 10-12 m): 22 tallos de 15-34 studs que se mecen
   cada uno a su ritmo.
4. **C · Cueva de la Luz** (pared sur, x 4495-4545): boca al cañón, dos salas y dos claraboyas por las que
   baja la luz; jardín de setas y anémonas que brillan, esporas, 2 luces.
5. **El arco** (x 4538): cruza el cañón de pared a pared y **enmarca la pirámide** desde dentro.
6. **E · Pirámide Hundida** (x 4660, ~20 m): seis escalones de piedra con vetas cian, punta de cristal,
   puerta hacia la entrada, ocho columnas rotas, una fumarola con burbujas y la luz más fuerte de la zona.
   Cuatro columnas de piedra (hoodoos) alrededor.
7. **D · Borde del abismo** (x 4720-4880, 26-37 m): el cañón se abre, las paredes bajan y aparecen seis
   agujas lejanas en la bruma; nieve marina.

Profundidad y equipo (`shared/Sea/Diving`): la entrada y el kelp **sin equipo** (≤ 12 m); la cueva y la
pirámide con **gafas y tubo** (≤ 25 m); el borde del abismo con **botella**. Tres sitios nuevos para
descubrir (`Ocean.Pois`): Cañón de Dorada, Cueva de la Luz, Pirámide Hundida. El HUD dice «Cañón de
Dorada» dentro (zona nueva `Canon` de `OceanBiomes`). Recursos del mar (conchas, perlas, coral) también
dentro del cañón, posados en su suelo de verdad.

## 6. Biblioteca (el kit del mar)

23 piezas en Blender (`scripts/map/mar_kit_blender.py`, vista `v2-kit-vista-previa.jpg`): 7 corales
(cuerno de ciervo, cerebro con surcos, mesa, abanico de red, esponjas de tubo huecas, blando, pilar),
4 rocas (porosa con agujeros, canto, laja, aguja), kelp gigante, pradera y alga ancha (hojas con grosor,
de dos caras), seta y anémona de luz, estrella, concha, erizo, cangrejo, pilote redondo con percebes,
pirámide y columna rota. 100-2400 triángulos cada una (`MarKit.Pieces[].Tri`), `RenderFidelity`
automático (LOD de Roblox). Corales, plantas y luz van con el color de la paleta (cambian con la
profundidad); rocas, vida pequeña, pilote y ruinas llevan textura horneada de color y normales (512 px).
Mientras no se suba (`scripts/upload-mar.sh`), cada pieza tiene un **respaldo de piezas** pensado para que
se lea qué es (`MarKit.fallback`): ramas que se bifurcan, plato del coral mesa, red del abanico, tubos con
boca oscura, tallo de kelp con hojas y flotadores… Con el kit subido, el resto de la orilla también lo usa
(`SeaBiome`), y SeaBiome planta en **racimos** (parches y sendas), no por igual.

## 7. Técnica y rendimiento

- Terreno: 919 rellenos (`FillBall`/`FillBlock`/`FillCylinder`) en orden; los huecos (cueva, arco,
  claraboyas) son **agua**. Nada sólido por encima de -9 (2 m bajo la superficie): los barcos pasan.
- Piezas: anclado, `CanCollide`/`CanTouch`/`CanQuery` = false, sin sombra; 7 modelos `Atomic`
  (StreamingEnabled los manda por trozos). Respaldo: 2350 piezas como mucho (tope 2400, el del móvil;
  dentro del cañón SeaBiome no planta nada). Con mallas: ~330 MeshPart.
- Luz: 3 `PointLight`, 4 haces (Neon al 92 % transparente, más tenues de noche), 5 emisores de partículas
  con fuente (plancton, motas, burbujas de una fumarola, esporas, nieve marina).
- Movimiento (`ReefZoneFx`): solo lo cercano (48 cosas, 16 en el móvil), cada una a su ritmo, con
  `BulkMoveTo`. Cáusticas en el fondo llano cuando la textura esté subida.
- Arena del fondo `Salt` → dorada clara (204, 186, 146); ondas de `Sandstone`; caliza más oscura; bruma
  de la orilla turquesa más honda con más densidad (más profundidad, menos «nieve»).

## 8. Evidencias (§19 del encargo)

**Cambios**: `shared/Sea/ReefZone.luau` (zona: geometría, piezas, luz, cámaras), `shared/Sea/MarKit.luau`
(kit y respaldos), `shared/Sea/MarAssetIds.luau` (vacío hasta subir), `World/ReefZoneBuilder.luau`,
`World/MarMeshes.luau`, `Controllers/ReefZoneFx.luau`; retoques en `Ocean` (lecho, zona `Canon`, sitios),
`OceanBiomes` (zona y luz de la orilla), `OceanBuilder` (llama al constructor), `OceanService` (recursos en
el cañón), `SeaBiome` (no planta en el cañón, racimos, mallas del kit), `SeaLife` (bancos junto a los
corales), `TerrainBuilder.Colors` (arena dorada, arenisca, caliza), `Main.client` (ReefZoneFx).

**Modelos y recursos**: `assets/mar/*.fbx` (23), `assets/mar/tex/*.png` (texturas 512 px y cáusticas),
`assets/mar/manifest.json`. **Scripts**: `scripts/map/mar_kit_blender.py`, `scripts/map/canon-export.luau`,
`scripts/map/canon_mapa.py`, `scripts/upload-mar.sh`.

**Pruebas hechas aquí** (Lune): `test-reefzone` (costa intacta, barcos, recorrido, profundidades y equipo,
geografía, kit y respaldo, malla cuando hay ids, paleta, móvil), `test-reefzone-camera` (la revisión desde
la cámara), `test-mar`, `test-swim`, `test-seamotion`, `test-agemotion`, `test-compile`,
`test-clientboot`, `test-serverboot` y los demás de la lista.

**Revisión desde la cámara (fase 4, por rayos, 11 vistas)** — `scripts/test-reefzone-camera.luau`:

| | Suelo | Formaciones | Vida | Horizonte con formaciones o vida |
|---|---|---|---|---|
| Antes (orilla v123) | 53-57 % | 0 % | 0 % | 0 % |
| Ahora (peor vista) | 36 % (llegada) | 10-82 % | 1-48 % | 49 % (llegada) |

**Pendiente (depende de otros pasos)**:
1. **Subir el kit**: `bash scripts/upload-mar.sh` (sesión que publica) → `MarAssetIds.luau` → publicar.
   Sin eso se ven los respaldos de piezas (mejores que antes, peores que las mallas) y no hay cáusticas.
2. **Verlo en el móvil.** Ni las vistas previas ni los rayos son Roblox: el terreno de Roblox es más
   liso (vóxeles de 4 studs), la bruma y la luz las pone el motor.
3. **Fase 8** (otras zonas y planetas): esperando las capturas del dueño de esta zona.
4. **Los pilotes negros cuadrados** de la captura v123 no son del decorado del mar (ni `Ocean`, ni
   `SeaBiome`, ni `ShoreDecor`, ni los pantalanes de pesca, que están en lagos y río): son de una
   construcción de la costa o del puerto, que está rehaciendo otro trabajo. El kit trae el `Pilote`
   redondo con percebes para cuando se quiera usar.

## 9. Lista para el dueño (qué mirar en el móvil)

Ve a **Playa Dorada** (la playa del este de la isla). Métete en el agua y nada recto **hacia el este**
(mar adentro).

1. **A ~80 studs de la arena (3-4 m)**: el jardín de coral con montículos y sendas de arena dorada.
   ¿La arena es dorada clara y no blanca? ¿Se ven racimos con caminos entre ellos? (vista 1)
2. **Sigue al este**: el fondo cae. Asómate al labio con la cámara un poco hacia abajo. ¿Se ve el cañón
   abriéndose entre dos paredes? (vista 2)
3. **Baja a 10-11 m** (sin equipo llegas): el kelp gigante a tu izquierda (norte), meciéndose. (vistas 3 y 4)
4. **Con gafas y tubo**, la boca de la Cueva de la Luz en la pared de la derecha (sur): entra, mira
   arriba a las claraboyas y al jardín que brilla. (vistas 5 y 6)
5. **Mira por el arco**: al fondo debe brillar la pirámide. (vista 7)
6. **La Pirámide Hundida** (~20 m): rodéala; columnas rotas, burbujas, luz cian. (vista 8)
7. **El borde del abismo** (con botella, 30+ m): agujas en la bruma. (vista 9)
8. **Date la vuelta** hacia la playa desde las ruinas. (vista 10)
9. **Nada por encima de la pared norte** a 2-3 m: corales y abanicos en la cima. (vista 11)
10. Haz lo mismo **de noche** (las 23:00 del juego): la cueva, la pirámide y las setas deben ser lo que
    brilla; los haces de luz casi no se ven.
11. **Nadar**: bucea, quédate quieto, sube, nada pegado al fondo: el personaje nunca cabeza abajo.

Mándame una captura en cada número (las vistas previas `v2-vista-NN.jpg` son las mismas cámaras).

## 10. Los 16 criterios de aceptación

| # | Criterio | Estado |
|---|---|---|
| 1 | No es un suelo plano | ✅ por rayos (suelo ≤ 36 % de la pantalla; antes 57 %) · 📱 falta verlo |
| 2 | Varios planos de profundidad | ✅ por rayos (cerca/medio/lejos en todas las vistas) · 📱 |
| 3 | Grandes formaciones | ✅ en el plan (paredes 19-83 studs, arco, columnas, agujas, cueva) · 📱 |
| 4 | Vegetación variada | ✅ 7 corales, kelp, praderas, algas, luz (kit y respaldos) · 📱 cómo se mecen |
| 5 | Puntos de interés a varias distancias | ✅ labio, kelp, cueva, arco, pirámide, agujas; 3 sitios en el HUD |
| 6 | Atmósfera submarina | 🟡 luz de zona, haces, partículas: aproximado en Blender; 📱 imprescindible |
| 7 | Buena composición desde la cámara | 🟡 por rayos y vistas previas; 📱 la de verdad |
| 8 | Regiones distintas (A-E) | ✅ las cinco en la zona, con su paleta y luz |
| 9 | Detalle sin saturar | ✅ racimos y sendas; tope de piezas · 📱 |
| 10 | Recorrible | ✅ agua de la entrada al abismo, bajo el arco y en la cueva (prueba) |
| 11 | Sistemas intactos | ✅ test-mar, test-swim, test-nacara, test-boats…; costa y puertos sin tocar |
| 12 | Rendimiento | 🟡 topes (piezas, luces, emisores, lo que se mece) probados; 📱 FPS en el móvil |
| 13 | No depende solo de niebla/partículas | ✅ la geometría manda (rayos sin niebla) |
| 14 | Funciona en el juego, no solo en imagen | 🟡 construido por el servidor; 📱 falta verlo |
| 15 | Identidad propia | ✅ formas y nombres propios (Cañón de Dorada, Cueva de la Luz, Pirámide Hundida) |
| 16 | Arquitectura reutilizable | ✅ ReefZone (datos) + MarKit + ReefZoneBuilder: otra zona = otros datos |
