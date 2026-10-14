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
* **Pesca**: las reglas de `Fishing.Bosses` no cambian (alta mar, varios expertos). Cuando empieza la pelea, el animal sube bajo el barco; si lo sacáis, su sitio queda vacío un rato y luego vuelve «otro ejemplar».

## 8. HUD (`Controllers/DiveHud`)

Panel izquierdo bajo tu estado: profundidad, vida marina (zona), temperatura, oxígeno con barra y límite de tu equipo. Cápsula de objetivo bajo la hora (misión del mar o el sitio sin descubrir más cerca: nombre, distancia y flecha). Mientras buceas se esconden el GPS y las notas (`UI/DiveFocus`). Botones táctiles: joystick, Bucear/Subir, Correr (nado rápido), Atacar, Linterna, Interactuar y Cambiar (mano / arpón / cámara). Huecos en `HudLayout` (`DivePanel`, `DiveObjective`), probados en 932x430, 844x390, 640x360 y 1920x1080.

## 9. Planetas: puntos de extensión

`OceanBiomes.Worlds` es una tabla por mundo: `Liquid` (agua, lava, hielo, ácido), `Surface`, `StudsPerMeter`, zonas con paleta, materiales, flora, fauna, luz, temperatura, peligros y corrientes. `Ocean` lee el perfil de profundidad de `OceanBiomes.Worlds[nombre].Profile`. Para un planeta basta con:

1. Añadir su mundo a `OceanBiomes.Worlds` (perfil y zonas).
2. Llamar a `OceanBuilder.build(worldId, origin)` en su sitio (lo haría `PlanetWorld`).
3. Sus peligros propios en `Hazards` (calor, frío, ácido: el mismo bucle de `OceanService` que hoy hace la presión).

Mundos previstos (no se construyen ahora): **Tálasa** (océano y ciudad submarina Abisalia), **Tefra** (lagos de lava: el «aire» es refrigeración del traje), **Nivalis** (mares helados bajo hielo, agujeros para respirar), **Miasma** (lagos ácidos: el traje se gasta), **Umbría** (ríos de selva), **Siroco** (oasis), **Vértice** (canales urbanos).
