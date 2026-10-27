# Nácara v2 · la ciudad del mapa del dueño (diseño para aprobar)

> Petición de Sebastián: «debemos recrearlo igual» con su mapa `docs/mar/referencia/ciudad-marina-dueno.png`.
> **Nada de esto está encendido en el juego.** Solo hay un prototipo del **Palacio Real** y la **Plaza
> Central** detrás de `Config.Sea.NacaraV2 = false`. El resto de la ciudad se construye cuando apruebes las
> vistas previas.

## Lo que tienes que mirar (en este orden)

| Imagen | Qué es |
|---|---|
| `comparacion.jpg` | Tu mapa a la izquierda y la vista general de Nácara v2 a la derecha |
| `vista-general.jpg` | Toda la ciudad desde el sur, con el nombre de cada barrio |
| `vista-1.jpg` | Desde la Plaza Central, a la altura del jugador: el tubo de cristal y el Palacio Real al fondo |
| `vista-2.jpg` | Llegando nadando desde el sur |
| `vista-3.jpg` | Desde el Mercado Submarino hacia el Palacio |
| `vista-4.jpg` | Desde el Puerto de Sirenas y los Jardines de Coral hacia el centro |

Todas dicen **«VISTA PREVIA, NO ES ROBLOX»**: están hechas en Blender (`scripts/map/nacara_v2_preview.py`). La
plaza, los barrios de la fase 1, el decorado y el prototipo del palacio son las **piezas de verdad** del juego;
los otros 14 barrios son una **masa aproximada** (se marcan «aprox.»): todavía no existen. La niebla del agua de
Roblox no se puede copiar del todo: en tu móvil se verá algo más azul y con menos alcance.

**Una pregunta para ti:** ¿te vale este plano (dónde va cada barrio y para qué sirve)? Si dices que sí, empiezo
la fase 1 (encender el palacio y la plaza) y te pido capturas. Si algo no te gusta, dime cuál y lo cambio antes.

## 1 · Lo que ya existe y cómo encaja (auditoría)

Nácara está en la Llanura Sumergida (centro X −2650, Z 5000; suelo a 37,5 m). Hoy tiene:

| Lo que existe | Dónde (plaza: X al este, Z al sur) | En el mapa nuevo |
|---|---|---|
| Plaza de la Corriente (fase 0, `World/NacaraBuilder`): fuente, 4 torres de coral, conchas, terrazas, Lonja Honda (cúpula de aire, tienda de Oriana), Ilun | (0, 0), radio 60 | **Plaza Central** (no se mueve) |
| Faro de Nácara (`World/NacaraDecor`): columna de luz hasta casi la superficie | centro de la plaza | La **fuente de luz** de la Plaza Central |
| Concha del Consejo (Maresa, el juicio de «Un seco en Nácara») | (−78, −152) | **Ala oeste del Palacio Real** (no se mueve: las escenas tienen sus anclas allí) |
| Barrio de las Conchas (6 conchas con aire, `MarCasa_Nacara_1…6`) | (−168, 14) | Se muda a **Residencias de Sirenas** (fase 2, con las mismas llaves) |
| Jardines de Cultivo (6 bancales, Tomé, oficio de cultivador/a) | (162, −18) | Se mudan a **Jardines de Coral** (fase 2) |
| Paseo de las perlas-farola (Lía, oficio de farolero/a) | anillo de 96–118 alrededor | Se queda: une la plaza con el palacio y los barrios de dentro |
| Kelp del norte y la persecución de «Redes cortadas» | (150, −190)… | Se queda: pasa entre las islas del norte |
| La Burbuja (posada de los secos) | Talud, lejos | Sin cambios (fuera de la ciudad) |
| Valmar Hundida (Barrio Viejo) y la Catedral Abisal | Cañón de las Catedrales, al sur | Se llega en submarino desde el **Puerto de Sirenas** |
| Historia «La canción de lo hondo» (Prólogo y Acto I, ~1 h) y las dos secundarias | — | Igual; los sitios nuevos sirven a los actos II y III |

Todo lo de la fase 1 sigue funcionando igual mientras v2 esté apagado. Nada se duplica: el palacio **usa** la
Concha del Consejo, la plaza **es** la Plaza Central, el mercado **amplía** la Lonja Honda, y las viviendas y el
cultivo **se mudan** (no se hacen otras).

## 2 · El plano

Tu mapa con el norte arriba, a escala 0,72 studs por píxel: la ciudad mide unos 900 studs de lado a lado (el
radio ≈ 450 que ya decía `civilizacion-marina.md` §3.1). El Palacio queda justo al norte de la plaza, como en
tu mapa. Los números salen de `shared/Sea/NacaraV2.luau` (coordenadas de la plaza, en studs).

| Barrio | Dónde | Isla (radio) | Junto a |
|---|---|---|---|
| Palacio Real | (5, −152) | 46 | Plaza (tubo), Residencias y Universidad (tubos), Hospital y Comercios |
| Plaza Central | (0, 0) | 60 | Palacio, Biblioteca, Acuario y Torre |
| Residencias de Sirenas | (−125, −325) | 58 | Palacio |
| Universidad Marina | (171, −318) | 54 | Palacio |
| Hospital Marino | (−175, −217) | 40 | Palacio, Mercado, Cueva |
| Mercado Submarino | (−326, −138) | 56 | Hospital, Biblioteca |
| Comercios y Tiendas | (214, −159) | 46 | Palacio, Santuario, Templo |
| Biblioteca de las Profundidades | (−218, −44) | 46 | Plaza, Mercado, Zona de Entrenamiento |
| Cueva de las Perlas | (−355, −253) | 50 | Hospital |
| Templo de los Sirenos | (444, −87) | 50 | Comercios |
| Santuario del Océano | (430, −238) | 50 | Comercios |
| Torre de Observación | (199, 14) | 34 | Plaza, Puerto, Jardines |
| Zona de Entrenamiento | (−312, 86) | 50 | Biblioteca |
| Acuario Gigante | (−117, 158) | 58 | Plaza |
| Puerto de Sirenas | (329, 114) | 48 | Torre, Jardines |
| Jardines de Coral | (271, 215) | 56 | Torre, Puerto |

- **Islas:** roca de basalto con la cara de arriba de grano claro y coral por el borde, 4 studs por encima del
  fondo. Entre isla e isla queda agua (como poco 6 studs): se puede nadar por debajo de las pasarelas.
- **Pasarelas y tubos de cristal** (`NacaraV2.Links`): pasarelas de piedra para andar dentro de las cúpulas de
  aire y tubos de cristal (con corriente rápida en la fase 4) desde el palacio y la plaza hacia fuera.
- **Lo que limita:** al sur está el borde del Cañón de las Catedrales (~280 studs): nada pasa de Z = 271. Las
  Ruinas de Valmar la Vieja quedan a ~180 studs de la Universidad. Ningún barrio toca los puertos, playas,
  barcos ni el territorio del megalodón. Nada es más alto que `Nacara.MaxTop` (los barcos pasan por encima).
- **Dos cosas no son exactamente tu mapa:** (1) la Biblioteca y la Torre caen donde hoy están el Barrio de las
  Conchas y los Jardines de Cultivo, por eso esos dos se mudan antes (fase 2) de construir la Biblioteca y la
  Torre (fase 3); (2) el Hospital lleva una concha verde, no una cruz roja (la cruz roja es un emblema protegido).

## 3 · Para qué sirve cada barrio

Los iconos son los de tu leyenda: ❗ misión principal · ❕ secundaria · 👤 NPC · 🛍 tienda · 💼 trabajo ·
🏠 vivienda · 🔱 transporte · 🐚 ambiental · 🎣 pesca/recolección · ⭐ evento · 📷 foto.

| Barrio | Iconos | Trabajos | Tiendas | Misiones | Viviendas | Usa lo que ya hay |
|---|---|---|---|---|---|---|
| **Palacio Real** | ❗👤⭐ | Guardia del Palacio | — | Actos II–III, el juicio, el Día del Pacto | — | Concha del Consejo, Maresa, `LifeStory` |
| **Plaza Central** | ❗👤⭐📷 | Farolero/a (el paseo empieza aquí) | Lonja Honda (Oriana) | Prólogo y Acto I (Ilun), eventos | — | Plaza de la fase 0, faro, `SeaEventService` |
| **Residencias de Sirenas** | 🏠👤 | — | — | «La primera concha» (secundaria) | Conchas (alquiler) y **pisos de coral** `MarPiso_` | `MarCasa_Nacara_1…6`, `HousingService`, `SleepService` |
| **Universidad Marina** | ❗💼👤 | Ayudante de laboratorio | — | Acto II «El pacto del faro» (etapa universidad) | — | `SchoolService`/clases como el Instituto |
| **Hospital Marino** | 💼👤 | Sanador/a | — | — | — | `HospitalService`: un hondario se despierta aquí (no en su concha) |
| **Mercado Submarino** | 🛍💼👤 | Puesto de algas, casa de comidas | Precios del mar | Trueque con Bartolo | **Locales** `MarLocal_` | Lonja Honda, `BusinessService` |
| **Comercios y Tiendas** | 🛍💼 | Dependiente/a | Ropa hondaria, muebles de coral, equipo de buceo | — | Locales | `ShopService`, `InventoryService` |
| **Biblioteca de las Profundidades** | ❕👤🐚 | Archivero/a | — | Secundarias de la historia del mar | — | `LifeStory` (cadenas), `docs/historia` |
| **Cueva de las Perlas** | 🎣💼🐚 | **Pescador/a de perlas** | Perlas a Oriana | «Las perlas de Oriana» | — | `FishingService`, `MarJobs` |
| **Templo de los Sirenos** | ❗⭐ | — | — | El ritual del don (`Mar_12_Don`) | — | `TesterService`/vida hondaria |
| **Santuario del Océano** | ❕🐚📷 | Guarda de los Grandes | — | Los Grandes (criaturas) | — | `MarFauna`, `SeaBeasts` |
| **Torre de Observación** | 📷🔱 | — | — | Fotos (puntos de foto) | — | `Civ.PhotoSpots`, parada central de corrientes |
| **Zona de Entrenamiento** | 💼❕ | Guardia de la Corriente (sin armas con punta) | — | Pruebas de nado | — | `CombatService`, `Swimming` |
| **Acuario Gigante** | 🐚⭐📷 | Cuidador/a | Entradas | Eventos de fauna | — | `MarFauna` (los peces del kit) |
| **Puerto de Sirenas** | 🔱💼🛍 | Piloto de submarino | Billetes | Viajes a Valmar Hundida y la Catedral Abisal | — | `BoatService`/`BusService` (paradas y horario) |
| **Jardines de Coral** | 🎣💼🐚 | **Cultivador/a de algas** (se muda aquí) | — | «Redes cortadas» empieza aquí | — | `Civ.Beds`, Tomé, `MarJobs` |

**En el mapa del juego:** cada barrio sale con su icono de la leyenda (como hoy 🐚 Nácara, 🏠, 🌿, ⚖); los NPC y
tablones usan los mismos iconos encima de la cabeza.

## 4 · Cómo encaja con lo que hay (técnica)

- **Datos:** `shared/Sea/NacaraV2.luau` (barrios, enlaces, medidas del palacio). Los barrios de juego se siguen
  apuntando en `shared/Sea/Civ` (zonas, llaves, tablones, gente): así el relieve y el decorado del fondo
  (`ShoreReef.cityBlocked`) los dejan libres solos. Con el interruptor encendido, Civ ya añade la isla del Palacio.
- **Construir:** un constructor por fase (`World/NacaraV2Builder` hoy: palacio y plaza), llamado desde
  `SeaCivService.setup` después de `NacaraCityBuilder`, solo con `Config.Sea.NacaraV2`.
- **Materiales:** solo SmoothPlastic, Glass, Neon y Fabric (y Sandstone para piedra). **Nunca** Slate, Marble,
  Cobblestone, Wood, Concrete… porque `World/UserMaterials` los cambia por las fotos de los packs y bajo el mar se
  ven negros (es lo que le pasaba a Valmar Hundida en la v129).
- **Viviendas:** las mismas llaves `MarCasa_` (`Civ.HomePrefix`); al mudarlas, la cama de reaparición se vuelve a
  calcular de la llave (`Civ.bedPosition`), sin tocar el guardado de Valmar.
- **Historia:** las anclas de las escenas (Consejo, plaza, arrecife) no se mueven; las nuevas van en
  `Civ.StorySpots`.
- **Respiración:** los barrios son `Safe` (sin presión para el hondario); las cúpulas con aire usan
  `SeaAirPocket` como hoy.

## 5 · Presupuesto en el móvil

| Qué | Límite | Por qué |
|---|---|---|
| Piezas del servidor por barrio | 150–260 (`NacaraV2.Districts[].Budget`; la ciudad entera ≤ 3300) | Hoy la plaza son 782 y la fase 1 ≈ 506: con StreamingEnabled el móvil solo carga lo de alrededor |
| Modelos | uno por barrio, `Atomic` | Llega entero o no llega (nada de medio palacio) |
| Luces de verdad | 2 por barrio como mucho, sin sombras | El brillo lo da el Neon (gratis) |
| Cristal (Glass transparente) | 1–2 cúpulas grandes por barrio | El cristal es lo más caro de pintar en el móvil |
| Partículas | 1 columna de burbujas por isla, poca cantidad | Como `NacaraDecor` hoy |
| Mallas del kit | corales y rocas del kit del mar (`MarKit`), con su respaldo de piezas | Ya subidas y revisadas |
| Objetivo | 45 FPS en tu móvil (mirar si baja de 30) | Capturas con `/console` en cada fase |

El prototipo del palacio y la plaza: **145 piezas, 2 luces** (`scripts/test-nacara-v2.luau` lo comprueba).

## 6 · Fases

| Fase | Qué | Cuándo |
|---|---|---|
| **0 (ahora)** | Este diseño, las vistas previas y el prototipo apagado | Hecho |
| **1** | Encender el Palacio Real y la Plaza Central; tus capturas de día y de noche, FPS | Cuando apruebes |
| **2** | Mudar Residencias y Jardines; Mercado, Comercios y Hospital (tiendas, locales, despertar en el hospital) | Tras la fase 1 |
| **3** | Universidad, Biblioteca, Cueva de las Perlas, Templo, Santuario, Torre, Zona de Entrenamiento, Acuario y Puerto (oficios y misiones de los actos II–III) | Por grupos de 3 |
| **4** | Tubos de cristal con corriente rápida, la Ballena Lenta y los submarinos del puerto | Al final |

Cada fase: pruebas con Lune, la revisión de mallas (`scripts/audit/moderacion-mallas.py`, 0 avisos) si hay mallas
nuevas, vistas previas y tus capturas antes de seguir.

## 7 · Rehacer las vistas previas

```
lune run scripts/map/nacara-export.luau /tmp/nacara.json fase1 x v2
python3 scripts/map/nacara_v2_preview.py /tmp/nacara.json docs/mar/nacara-v2 --muestras 24 --ancho 1280
```
(`bpy` 4.2 con Python 3.11).
