# Mar de Valmar: auditoría y diseño (v117)

Encargo: `encargo.md`. Referencia: `referencia-submarina.png`. Antes: `captura-dueno-fondo-actual.png`.

## 1. Auditoría (lo que había)

| Pieza | Dónde | Estado |
|---|---|---|
| Terreno del mar | `World/TerrainBuilder` paso 1 | Una losa plana: arena de Y −24 a −14 y agua de −14 a −2 en todo el rectángulo del mapa (+800 studs). **12 studs ≈ 3,4 m de fondo** en todas partes. Sin desniveles, sin rocas de terreno. |
| Nadar | `Shared/Swim`, `Controllers/Swimming`, `SeaMotion` | Bien hecho (flotar, bucear, flotabilidad neutra, cámara). Los rayos del fondo solo miraban 60 studs: con fondo profundo no sabía dónde estaba el suelo. Sin nado rápido vertical. |
| Aire | `DivingService` + `DivingUI` | 20 s sin nada, 45 s gafas, 150 s botella (`Fishing.Dive.Oxygen`). El «Aire: 10 s» de la captura era lo que quedaba. Solo se recupera fuera del agua. Sin presión ni límites de profundidad. |
| Pesca submarina | `DivingService` | Peces de piezas alrededor del buceador con fusil; se sujetaban a Y −13…−3,5 (el mar viejo). |
| Fondo «decorado» | `Controllers/SeaBiome` | Por trozos alrededor de ti y solo en tu pantalla: posidonia, algas que se mecen, rocas, corales, erizos, ánforas; bancos de pececillos que dan vueltas; medusas. Rayos 40 studs: nada en aguas hondas. |
| Luz bajo el agua | `DayLight.setUnderwater` | Una sola bruma verde azulada fija, sin cambio por profundidad ni por zona. |
| Efectos | `SeaFx` | Gafas, botella, burbujas, estela, salpicadura (bien). |
| Pesca | `Shared/Fishing`, `FishingService` | Megalodón y Kraken solo en «alta mar» (400 studs del barco de pesca, al sur del puerto) y solo con varios pescadores expertos tirando a la vez. Se mantiene igual. |
| Barcos | `Shared/Boats`, `BoatService` | Navegan por cálculo (`Boats.isSea`, fuera de la isla, islas y aeropuerto, hasta 700 studs del borde); no dependen de la profundidad. Calado 1,5 studs. |
| Tiburones decorativos | `NatureAssets.sharkSpots` | Modelos que dan vueltas frente a las playas del este a Y −9. |
| Catástrofes | `SeaEvents` | Tsunami, temporal, remolino, marea negra, tiburón, medusas (no cambian). |

Conclusión: la natación y la pesca están bien; lo que falla es **el mundo**: un fondo plano de 3,4 m sin zonas, sin luz por profundidad y sin vida grande.

## 2. Escala

Avatar de Roblox ≈ 5 studs ≈ 1,8 m → **1 m = 3,57 studs** (`Shared/Sea/Ocean.StudsPerMeter`). La superficie sigue en Y = −2 (como `Swim.Surface`, `Boats.SeaLevel` y `Fishing.Dive.Surface`).

## 3. Perfil de profundidad (`Shared/Sea/Ocean`)

El fondo es una función pura `Ocean.floorY(x, z)` según la distancia a tierra (isla, islas pequeñas y aeropuerto):

| Tramo | Distancia a tierra | Fondo (Y) | Profundidad |
|---|---|---|---|
| Orilla (no se toca: playas, muelles y pantalanes como siempre) | < 60 | −14 | 3,4 m |
| Plataforma (arrecife, kelp, pradera) | 60–360 | −14 → −48 | hasta 13 m |
| Talud | 360–820 | −48 → −132 | hasta 36 m |
| Llanura profunda | > 820 | −132 ± 8 | ~37 m |
| **Abismo Silente** (cuenca del sureste) | elipse 2650×960 studs | −242 ± 10 | **≥ 50 m en todo su centro, ~67 m** |
| **Sima del Kraken** (fosa dentro del abismo) | corredor de 4 tramos | hasta **−560** | **~156 m** |
| Garganta Negra (cañón del este) | corredor | −95 → −240 | hasta 67 m |

El mapa del mar se alarga 700 studs al sur (hasta Z = 5800) para que el abismo no toque el borde.

## 4. Zonas («Vida marina» del HUD)

Nombres del dueño: **Arrecife Escarlata**, **Laberinto de Kelp**, **Llanura Sumergida**, **Talud del Naufragio**, **Garganta Negra**, **Abismo Silente**, **Sima del Kraken** (más «Aguas de la orilla» junto a la costa). Cada una tiene en `Shared/Sea/OceanBiomes` su paleta, materiales del terreno, flora, fauna, niebla y luz, temperatura, corrientes y peligros. La luz se mezcla además con la profundidad (más oscura y azul abajo; rayos de sol solo cerca de la superficie; bioluminiscencia abajo).

## 5. Construcción

* **Terreno** (`World/OceanBuilder`, paso de arranque propio, en su hilo): columnas de 16 studs (8 en la fosa y el cañón) con el fondo de `Ocean.floorY`; se juntan las columnas iguales en bloques largos. Solo toca el agua fuera de tierra (≥ 60 studs de la costa): ciudad, playas, puertos, marina, aeropuerto, islote del puerto espacial y portal de la playa quedan igual. Después: crestas y rocas, arcos, cuevas (la Guarida del Kraken excavada dentro de una mole de roca), el pecio, las ruinas y los cofres.
* **Piezas del servidor** (POI): modelos con `ModelStreamingMode = Atomic` (llegan enteros o no llegan). Presupuesto: ≤ 900 piezas en total (`OceanBuilder.Budget`, probado).
* **Decorado del cliente** (`SeaBiome`): flora por zona en trozos alrededor de la cámara, con LOD (se mece solo lo cercano; móvil con menos radio y menos piezas).
* **Vida** (`SeaLife`, cliente): bancos de peces con boids, rayas, tortugas, medusas que brillan, delfines cerca de la superficie, criaturas abisales con luz. Presupuesto móvil ≤ 160 piezas animadas.

## 6. Exploración

* **Aire** (`Shared/Sea/Diving`): 30 s sin nada, 60 s gafas y tubo, 240 s equipo de buceo, 480 s **traje abisal** (nuevo en la tienda de pesca). Se recupera en la superficie, en el barco de pesca y en las **bolsas de aire** de las cuevas.
* **Presión**: sin nada hasta 12 m, gafas 25 m, botella 75 m, traje abisal 180 m. Al pasarte: aviso claro («con gafas puedes bajar hasta 25 m…»), el aire se gasta el triple y luego hace daño. Lo decide el servidor.
* **Recursos** (servidor, con distancia, ritmo y equipo comprobados): conchas, perlas, muestras de coral, muestras bioluminiscentes, doblones antiguos y cofres de tesoro (uno por persona y día). Van a la mochila y se venden en la lonja (pescadería).
* **Lugares** (POI) que se descubren al acercarte y se guardan (`data.Sea.Found`).
* **Misiones del mar** (`data.Sea.Done`): Explora el arrecife, Encuentra el pecio, Recolector de conchas, Fotografía al megalodón, La guarida del Kraken.

## 7. Criaturas grandes (servidor manda)

* **Megalodón** patrulla el Abismo Silente. Si bajas a su territorio, ronda, embiste y muerde: daño, empujón y pierdes aire (sin sangre). Un golpe en el morro (Atacar) lo espanta. No ataca a bebés ni niños, ni a quien va en barco.
* **Kraken** vive en la Sima del Kraken. Emboscada: aviso (temblor y tinta) y un tentáculo golpea donde estabas; si te apartas a tiempo, falla.
* **Pesca**: las reglas de `Fishing.Bosses` no cambian (alta mar, varios expertos). Son el mismo animal: mientras dura la pelea, el megalodón o el kraken de verdad queda «enganchado» en su sitio (se revuelve y no ataca: buen momento para la foto); si lo sacáis, su sitio queda vacío 8 min y luego vuelve «otro ejemplar»; si se suelta, vuelve a lo suyo (`FishingService.onBoss` → `SeaBeastService`).

## 8. HUD (`Controllers/DiveHud`)

Panel izquierdo bajo tu estado: profundidad, vida marina (zona), temperatura, oxígeno con barra y límite de tu equipo. Cápsula de objetivo bajo la hora (misión del mar o el sitio sin descubrir más cerca: nombre, distancia y flecha). Mientras buceas se esconden el GPS y las notas (`UI/DiveFocus`). Botones táctiles: joystick, Bucear/Subir, Correr (nado rápido), Atacar, Linterna, Interactuar y Cambiar (mano / arpón / cámara). Huecos en `HudLayout` (`DivePanel`, `DiveObjective`), probados en 932x430, 844x390, 640x360 y 1920x1080.

## 9. Planetas: puntos de extensión

`OceanBiomes.Worlds` es una tabla por mundo: `Liquid` (agua, lava, hielo, ácido), `Surface`, `StudsPerMeter`, zonas con paleta, materiales, flora, fauna, luz, temperatura, peligros y corrientes. `Ocean` lee el perfil de profundidad de `OceanBiomes.Worlds[nombre].Profile`. Para un planeta basta con:

1. Añadir su mundo a `OceanBiomes.Worlds` (perfil y zonas).
2. Llamar a `OceanBuilder.build(worldId, origin)` en su sitio (lo haría `PlanetWorld`).
3. Sus peligros propios en `Hazards` (calor, frío, ácido: el mismo bucle de `OceanService` que hoy hace la presión).

Hoy `OceanBiomes` (perfil, zonas, luz, flora, fauna, recursos) ya es por mundo; la geografía concreta de Valmar
(puertos que no se tocan, cuenca del abismo, fosa, cañón, arrecifes, sitios) está en `Ocean` y
`OceanBuilder.build` solo construye «Valmar». El primer planeta con mar tendrá que mover esa geografía a su
entrada de `OceanBiomes.Worlds` y pasar el mundo a `Ocean.sample`/`planBand`.

Mundos previstos (no se construyen ahora): **Tálasa** (océano y ciudad submarina Abisalia), **Tefra** (lagos de lava: el «aire» es refrigeración del traje), **Nivalis** (mares helados bajo hielo, agujeros para respirar), **Miasma** (lagos ácidos: el traje se gasta), **Umbría** (ríos de selva), **Siroco** (oasis), **Vértice** (canales urbanos).

## 10. Imágenes y pruebas

* `mar-profundidad.png` y `mar-zonas.png`: el mar visto desde arriba (profundidad en metros y zonas), hechas
  con `scripts/map/mar-export.luau` + `scripts/map/mar_render.py` desde `shared/Sea/Ocean`.
* `vista-arrecife.png`, `vista-pecio.png`, `vista-abismo.png`, `vista-sima.png`: vistas submarinas
  aproximadas con Blender (`scripts/map/mar_blender.py`): el fondo es el de verdad; corales, pecio y
  criaturas son formas sencillas para ver el ambiente y la luz de cada zona (no son capturas del juego).
* `scripts/test-mar.luau`: perfil de profundidad, nada inundado, barcos, zonas, plan del terreno sin huecos,
  presupuestos, aire y presión, recursos y cofres del servidor, misiones, criaturas y HUD.
* Falta comprobar en Roblox de verdad: lo que tarda `OceanBuilder` en el servidor (el registro dice
  «[OceanBuilder] mar hondo listo: … rellenos, … s»), la niebla y el color de cada zona, los modelos del
  megalodón y del kraken, y el HUD de buceo en un móvil.

## 11. Mar enorme (referencia vídeo, v120)

El dueño mandó un trozo de vídeo de otro juego de móvil (`referencia-video/marco_1..6.jpg`). Solo lo
usamos para el **ambiente y la escala**: no copiamos personajes, edificios, interfaz ni nombres. Lo que
le gusta: un mar muy grande y hondo, bruma azul que deja ver lejos, cañones altos, mucha luz de colores
(medusas, coral que brilla), animales gigantes y un pueblo con farolillos cálidos.

**Qué hay nuevo**

| Cosa | Dónde | Cómo es |
|---|---|---|
| **Cañón de las Catedrales** (zona nueva) | `Ocean.Cathedrals` | Cañón ancho (120 studs de suelo) con paredes casi verticales y repisas, de la llanura al borde del abismo: de **43 a 70 m**. Con botella se llega a todo. |
| **Valmar Hundida** | `OceanBuilder` (sitio con cofre) | Barrio de Valmar la Vieja en el fondo del cañón: 20 casas de piedra con ventanas cálidas, farolas, guirnaldas de farolillos, arco de entrada, plaza con fuente y la torre del faro hundido (se ve de lejos). A 47 m. |
| **Catedral Abisal** | `OceanBuilder.cathedralCave` | Cueva enorme excavada en una mole de basalto que tapa el cañón (se entra por los dos lados), con columnas que brillan, altar con un orbe, estatua guardiana y **haces de luz** que bajan por tres claraboyas. A 64 m. |
| Misión **«Valmar Hundida»** | `Diving.Missions` | Descubrir el barrio y la catedral y abrir el cofre (1200). Punto de buceo en el mapa. |
| **Agujas de roca** | `Ocean.spires()` | 32 columnas de basalto de 30 a 150 studs en el borde del abismo y en lo alto del cañón: siluetas una detrás de otra entre la bruma. Nunca en el territorio del megalodón ni encima de los barcos. |
| Dos **arcos** gigantes | `OceanBuilder` | De pared a pared en el cañón. |
| **Coral de luz** | `SeaBiome` («LightTree») | Árboles de coral blancos, cian, rosas y violetas que brillan (cañón, abismo, garganta y algo en el arrecife). |
| **Campos de medusas** | `Ocean.JellyFields`, `SeaAmbient` | 5 sitios con muchas medusas rosas, cian y violetas subiendo y bajando. |
| **Gigantes a lo lejos** | `Shared/Sea/Ambient`, `SeaAmbient` | Ballenas, mantas gigantes y, rara vez en lo hondo, el leviatán. Pasan de largo a 60–260 studs, sin chocar y sin atacar. |
| **Plancton que brilla** | `SeaBiome` | Motas cian, violetas y rosas cuando abajo manda la bioluminiscencia. |
| **Rayos de sol** | `SeaBiome` | Más largos (hasta 40 studs) y anchos; se apagan hacia los 32 m. |

**La luz bajo el agua** ahora es una **zona** más del sistema de zonas (`EnvZones`, zona «Submarino»):
SeaBiome le cuenta a `EnvDirector` cuánto está la cámara bajo el agua y la luz de la zona; EnvDirector es
el único dueño y DayLight solo la pinta. Bajo el agua no llueve. Las nieblas de todas las zonas son más
suaves y azules (se ve a 130–230 studs; antes 45–180); abajo es más oscuro pero **azul, no negro**, y la
bioluminiscencia brilla más (Bloom). El desenfoque de lo lejano es la mitad.

**Profundidades** (lo que pidió el dueño: ≥ 50 m para los monstruos): el megalodón patrulla siempre sobre
**65 m o más**; el kraken vive a **139 m** (la sima llega a 156 m); el cañón nuevo baja a **70 m**.

**Móvil**

* Arranque **más barato**: el fondo se construye con rectángulos grandes (`Ocean.planBand`) en vez de
  fila a fila. Rellenos de terreno: **92 644 → 53 662** (−42 %), con el cañón, las agujas, los arcos y
  la catedral ya incluidos.
* La vida nueva es solo de tu pantalla, sin choques, movida con `BulkMoveTo`. Topes: móvil 20 medusas +
  1 gigante (≤ 70 piezas), ordenador 44 + 2 (≤ 150). Con SeaLife, ≤ 240 piezas que se mueven en el móvil.
* Piezas del servidor en los sitios: 338 → 585 (tope 900), en modelos Atomic (StreamingEnabled).
* No hace falta subir texturas ni mallas: todo son piezas, terreno y efectos de Roblox.

**Imágenes**: `antes-mar-profundidad.png` / `mar-profundidad.png`, `antes-mar-zonas.png` /
`mar-zonas.png`, `antes-vista-abismo.png` / `vista-abismo.png` y `vista-catedrales.png` (Blender, vista
aproximada: no es una captura del juego).

**Falta mirar en Roblox de verdad**: si la niebla propia del agua de Roblox deja ver tan lejos como
pedimos a `Atmosphere`, los fps de un móvil en el cañón y lo que tarda OceanBuilder en el servidor.

## 12. La orilla (v122)

Captura del dueño (`captura-dueno-v121-orilla.png`): de noche, a 2 m junto a la playa. Fondo marrón y
plano, bruma marrón, «rocas» que eran cubos negros, cuadrados rosas, cuatro briznas, una franja azul
enorme por el suelo, el personaje como andando por la arena, y el arrecife a 2,6 km.

**Causas encontradas en el código**

| Lo que se veía | Causa |
|---|---|
| Fondo y bruma marrones | El fondo del mar era terreno **Sand**, y `World/UserMaterials` pone en Sand la «realistic sand texture» de la playa (MaterialVariant con su propio color, tostado). Bajo el agua, con luz de luna, eso es barro. Los píxeles de la captura lo confirman: la arena sale (67, 55, 43), con más rojo que azul aunque el etalonaje submarino ya era azul verdoso. |
| De noche nada azul | `EnvZones.underwaterKey` cambiaba la bruma y el etalonaje, pero NO la luz que rellena (Lighting.Ambient / OutdoorAmbient): de noche se quedaba la de la calle, gris, sobre esa arena. La bruma de la zona tampoco cambiaba con la hora. |
| Cubos negros | `SeaBiome.rock`: un bloque de Basalt/Slate gris oscuro (Basalt sin textura de la tienda: casi negro de noche). |
| Cuadrados rosas | `SeaBiome.critter` (conchas): bloques planos de 0,4 × 0,5. |
| Franja azul | `TaskMarker`: la línea al objetivo de la historia (0,6 studs de ancho, brillante, de los pies al objetivo); bajo el agua se veía por el fondo. |
| Andar por el fondo | `Swim.FloorClear` = 2,4: buceando, la cadera podía quedar a 2,4 studs de la arena; de pie el Humanoid llega al suelo a ~3, así que podía «tocar» la arena y andar. (No se ha podido ver en Roblox: es la causa más probable.) |
| Arrecife a 2,6 km | Los arrecifes estaban en tres sitios de la isla y la misión mandaba siempre al Arco de Coral. |

**Qué se ha cambiado**

* Fondo: terreno **Salt** (grano blanco, sin textura de la tienda) en todo el mar (`TerrainBuilder` y zonas
  Orilla, Coral, Arrecife y Llanura); manchas de arena de playa junto a la orilla, caliza clara, dunas
  bajas y rocas (`OceanBuilder.shore`, ~1600 rellenos; nada sube más de 2,6 studs).
* Fondo de la orilla nuevo (`shared/Sea/ShoreDecor`, lo planta SeaBiome): corales cerebro, de ramas y
  mesa, abanicos, anémonas (las puntas brillan de noche), praderas altas, rocas irregulares (la malla de
  asteroide de Blender si está cargada; si no, bolas) con musgo, conchas, estrellas, cangrejos que andan
  de lado y erizos. Sin bloques, sin basalto, sin marrones. Tope de piezas: 1400 en el móvil.
* Luz: de día turquesa (agua 36, 160, 178); de noche luna azul: bruma, agua, etalonaje y la luz que
  rellena azules, algo más de exposición, haces de luna, plancton y puntas que brillan.
* **23 jardines de coral** (zona «Jardín de coral») a ~110 studs de las playas: 9 con nombre y piezas del
  servidor (cúpulas, mesas, ramas, abanico) y arco de roca; el resto repartidos cada ~520 studs de playa.
  Desde cualquier playa hay uno a menos de ~630 studs (176 m). «Explora el arrecife»: dos arrecifes
  cualesquiera y el HUD lleva al más cercano. Salen como «Punto de buceo» en el mapa.
* Línea de guía en el agua: 0,16 → 0,05 studs, casi transparente y de 22 studs como mucho.
* Nadar: `FloorClear` 3,6; quieto bajo el agua el cuerpo va más tumbado. Los recursos se posan en el
  terreno de verdad cuando acaba OceanBuilder (no quedan enterrados en una duna).

`orilla-recetas.png`: hoja de muestras de las recetas (matplotlib, `scripts/map/orilla-export.luau` +
`orilla_preview.py`). Es una vista previa aproximada de formas y colores, **no** el render de Roblox
(no hay Blender en este equipo).

**Lo que hay que mirar en Roblox (capturas)**

1. Orilla de día a 1-2 m y a ~3 m junto a un jardín de coral: ¿arena blanca y agua turquesa clara?
2. Orilla de noche (2-4 h): ¿azul de luna, se ve el fondo, brillan las anémonas y el plancton?
3. A 10 m (Llanura, más lejos): azul más hondo, sin marrón.
4. Que la arena de la playa (fuera del agua) sigue igual, y el borde con el agua.
5. Las rocas: si salen como bolas, la carpeta `ReplicatedStorage.AsteroideMallas` no está cargada.
6. Buceando quieto junto al fondo: que el personaje nade y no ande.
7. La línea al objetivo bajo el agua: fina y corta.
8. FPS en el móvil con la orilla llena (consola F9: piezas en `workspace.SeaBiome`).
9. Roblox pinta su propia niebla bajo el agua con el color del agua del terreno: si de noche se ve
   demasiado oscuro, subir `OceanBiomes.Night.Exposure` u `Outdoor`; si de día se ve lechoso, bajar
   `Orilla.Look.Density`.
