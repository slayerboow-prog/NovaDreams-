# Nácara v2 · la ciudad del mapa del dueño (diseño para aprobar, versión 2)

> Petición de Sebastián: «debemos recrearlo igual» con su mapa `docs/mar/referencia/ciudad-marina-dueno.png`.
> La primera versión era «beta» (masas de bloques). En esta, **los 16 barrios están diseñados y construidos en el
> código** (`World/NacaraV2Builder`), cada uno en su isla de roca y coral, y las imágenes salen de ese código.
> **Nada de esto está encendido en el juego** (`Config.Sea.NacaraV2 = false`). Al encenderlo solo se construiría la
> fase 1 (Palacio Real y Plaza Central); el resto, cuando lo apruebes.

## Lo que tienes que mirar

| Imagen | Qué es |
|---|---|
| `comparacion.jpg` | Tu mapa a la izquierda y Nácara v2 a la derecha, con el mismo ángulo |
| `vista-general.jpg` | Toda la ciudad desde el sur, de noche, con el nombre de cada barrio |
| `vista-1.jpg` | El Palacio Real desde la salida norte de la Plaza Central (altura del jugador, cámara del móvil) |
| `vista-2.jpg` | El Mercado Submarino |
| `vista-3.jpg` | El Acuario Gigante |
| `vista-4.jpg` | El Templo de los Sirenos |
| `vista-5.jpg` | El Puerto de Sirenas y los Jardines de Coral |

Todas dicen **«VISTA PREVIA, NO ES ROBLOX»**: son Blender (`scripts/map/nacara_v2_preview.py`). Lo que **sale del
juego**: todas las piezas, las mallas del kit del mar y el terreno de las islas. Lo que **no** (ambiente para leer la
escena): los bancos de peces, medusas y mantas, los haces de luz y las motas. Mira «Lo que se verá distinto» abajo.

**La pregunta para ti:** ¿así sí? Si dices que sí, enciendo la fase 1 (palacio y plaza) y te pido capturas en tu móvil.

## 1 · Lo que ya existe y cómo encaja

| Lo que existe | Dónde (plaza: X al este, Z al sur) | En Nácara v2 |
|---|---|---|
| Plaza de la Corriente (fase 0): fuente, 4 torres de coral, Lonja Honda, Ilun y Oriana | (0, 0) | **Plaza Central** (no se mueve; se le pone el anillo de peñascos, el borde de luz y cuatro pares de obeliscos) |
| Faro de Nácara (`NacaraDecor`) | centro de la plaza | La **fuente de luz** de la Plaza Central |
| Concha del Consejo (Maresa, el juicio) | (−78, −152) | **Ala oeste del Palacio Real** (no se mueve: las escenas tienen sus anclas allí) |
| Barrio de las Conchas (`MarCasa_Nacara_1…6`) | (−168, 14) | Se muda a **Residencias de Sirenas** (fase 2, mismas llaves) |
| Jardines de Cultivo (bancales, Tomé) | (162, −18) | Se mudan a **Jardines de Coral** (fase 2) |
| Paseo de perlas-farola (Lía), kelp del norte y la persecución | alrededor | Se quedan; el palacio y su coral no los tapan (lo comprueba `test-nacara-v2`) |
| La Burbuja, Valmar Hundida y la Catedral Abisal | fuera | Sin cambios; al Cañón se va en submarino desde el **Puerto de Sirenas** |
| La historia del mar (Prólogo y Acto I) | — | Igual; los barrios nuevos sirven a los actos II y III |

## 2 · El plano

Tu mapa con el norte arriba, a 0,72 studs por píxel: unos 900 studs de lado a lado. Islas de basalto que suben
8 studs sobre la llanura (la Plaza Central se queda a 0, rodeada de peñascos), con acantilado de peñascos, coral
al borde, kelp gigante alrededor y plantas que brillan. Datos: `shared/Sea/NacaraV2.luau`.

| Barrio | Centro | Radio | Enlaces |
|---|---|---|---|
| Palacio Real | (5, −152) | 46 | tubo a la Plaza, tubos a Residencias y Universidad, pasarelas a Hospital y Comercios |
| Plaza Central | (0, 0) | 60 | tubos al Palacio, Acuario y Torre; pasarela a la Biblioteca |
| Residencias de Sirenas | (−125, −325) | 56 | Palacio |
| Universidad Marina | (171, −318) | 62 | Palacio |
| Hospital Marino | (−175, −217) | 50 | Palacio, Mercado, Cueva |
| Mercado Submarino | (−326, −138) | 56 | Hospital, Biblioteca |
| Comercios y Tiendas | (214, −159) | 56 | Palacio, Santuario, Templo |
| Biblioteca de las Profundidades | (−218, −44) | 56 | Plaza, Mercado, Entrenamiento |
| Cueva de las Perlas | (−355, −253) | 56 | Hospital |
| Templo de los Sirenos | (444, −87) | 62 | Comercios |
| Santuario del Océano | (430, −238) | 62 | Comercios |
| Torre de Observación | (199, 14) | 44 | Plaza, Puerto, Jardines |
| Zona de Entrenamiento | (−312, 86) | 60 | Biblioteca |
| Acuario Gigante | (−117, 158) | 70 | Plaza |
| Puerto de Sirenas | (329, 114) | 54 | Torre, Jardines |
| Jardines de Coral | (271, 215) | 56 | Torre, Puerto |

**Enlaces:** 6 **tubos de cristal curvos** (se levantan 12 studs en medio y se tuercen de lado, con una franja
cian arriba) y 11 **pasarelas** curvas con barandilla de luz (cian a un lado, oro al otro). En la dirección de cada
enlace la isla deja una entrada libre (sin peñascos ni coral). Nada pasa de `Nacara.MaxTop` (64 studs sobre la
plaza), salvo el **Palacio**, el hito, que llega a **92** (aún 42 studs bajo la superficie: los barcos pasan por
encima; `NacaraV2.PalaceMaxTop`). Nada pasa del borde del Cañón (Z < 280).

## 3 · Cada barrio (silueta, materiales, luces, decorado y para qué sirve)

Materiales de todas las piezas: **SmoothPlastic** (nácar, perla), **Glass** (cúpulas y tubos), **Neon** (ventanas
cálidas, franjas cian y oro, perlas) y **Fabric** (toldos). Nunca pizarra, mármol, adoquín ni madera: los packs del
dueño los cambian por fotos oscuras y bajo el mar se ven negros (el bug de Valmar Hundida, v129). El coral, las
rocas, el kelp y las plantas que brillan son **mallas del kit del mar** (`MarKit`, una pieza cada una).
Iconos de tu leyenda: ❗ principal · ❕ secundaria · 👤 NPC · 🛍 tienda · 💼 trabajo · 🏠 vivienda · 🔱 transporte ·
🐚 ambiental · 🎣 pesca · ⭐ evento · 📷 foto.

| Barrio | Silueta y decorado | Luz | Función (iconos) | Usa |
|---|---|---|---|---|
| **Palacio Real** | Terraza de nácar con borde cian; tambor alto con 20 ventanas cálidas y 4 puertas de oro; **gran cúpula de cristal** (radio 26, alto 30) con 8 costillas de luz y el corazón de luz dentro; **aguja mayor** hasta 92 studs (lo más alto de la ciudad), 4 agujas en los hombros y 12 alrededor (32–46) con perlas cian y oro | 1 (el corazón) | ❗👤⭐: actos II–III, el juicio, el Día del Pacto; guardia del palacio | Concha del Consejo, Maresa |
| **Plaza Central** | La plaza de la fase 0 + anillo de peñascos y coral fuera, borde de luz, 4 pares de obeliscos en las entradas, cartel | (la del faro) | ❗👤⭐📷: Ilun, la Lonja Honda, eventos | Plaza fase 0, faro |
| **Residencias de Sirenas** | 8 conchas-casa en arco (tambor, tapa de cristal violeta o azul, puerta de oro, ventanas); 2 **torres de pisos** con balcones, ventanas cálidas y aguja | 1 (perla-farola) | 🏠👤: conchas de alquiler y pisos de coral `MarPiso_` | `MarCasa_Nacara_*`, `HousingService` |
| **Universidad Marina** | Escalinata, sala redonda con 18 ventanas altas, **columnata de 16**, cúpula de cristal, linterna y campanario; dos alas con cúpula | 1 (faro) | ❗💼👤: acto II «El pacto del faro» | clases como el Instituto |
| **Hospital Marino** | Pabellón blanco con dos pisos de ventanas y cúpula verde agua; torre con el **signo de la concha verde** (no la cruz roja, que es un emblema protegido) | 1 (el signo) | 💼👤: sanador/a; el hondario se despierta aquí | `HospitalService` |
| **Mercado Submarino** | 14 puestos con **toldos de colores** y farolillo; nave redonda con cúpula ámbar; 6 **guirnaldas de farolillos** | 1 (lámpara) | 🛍💼👤: puestos, casa de comidas, locales `MarLocal_` | Lonja Honda, `BusinessService` |
| **Comercios y Tiendas** | Galería redonda rosa con 10 **escaparates de luz** y letreros de color, cúpula violeta, 5 quioscos | 1 | 🛍💼: ropa hondaria, muebles de coral, equipo | `ShopService` |
| **Biblioteca de las Profundidades** | Tres pisos escalonados con franjas de oro y ventanas, cúpula y 6 torres-estante con libros de luz | 1 | ❕👤🐚: archivero/a, secundarias | `LifeStory` |
| **Cueva de las Perlas** | **Cueva de roca** (terreno, boca al este) con la **almeja gigante** del kit y la **perla que brilla**, 10 cristales violeta, anémonas de luz, arco violeta | 1 (la perla, violeta) | 🎣💼🐚: pescador/a de perlas | `FishingService`, Oriana |
| **Templo de los Sirenos** | Nave alta con ventanas largas, **tejado escalonado en aguja** con franjas de oro, 6 agujas de oro, puerta ojival y rosetón | 1 (oro) | ❗⭐: el ritual del don | `Mar_12_Don` |
| **Santuario del Océano** | Anillo de 10 columnas con perlas, estanque de luz, **columna de luz con tres puntas**, dos **lunas** de nácar | 1 (la columna) | ❕🐚📷: los Grandes | `MarFauna`, `SeaBeasts` |
| **Torre de Observación** | Base con ventanas, fuste alto con **rampa de luz en espiral**, mirador de cristal con fanal; anexo con cúpula | 1 (fanal) | 📷🔱: fotos, parada central de corrientes | `Civ.PhotoSpots` |
| **Zona de Entrenamiento** | 3 estanques con borde de luz, 4 **aros** para nadar, gradas, dianas | 1 | 💼❕: Guardia de la Corriente (sin armas con punta) | `CombatService`, `Swimming` |
| **Acuario Gigante** | **La cúpula más grande** (radio 42) con 6 costillas de luz, zócalo con ventanas cian, coral y kelp dentro | 1 | 🐚⭐📷: cuidador/a, eventos de fauna | `MarFauna` |
| **Puerto de Sirenas** | 4 muelles con luces, **2 submarinos** (ámbar y azul) con ojos de buey, capitanía con cúpula y aguja | 1 (fanal) | 🔱💼🛍: viajes a Valmar Hundida y la Catedral Abisal | `BoatService`/`BusService` |
| **Jardines de Coral** | 3 terrazas con borde verde, **coral denso** (≈ 120 mallas), invernadero de cristal, sendas de luz | 1 | 🎣💼🐚: cultivador/a (se muda aquí), «Redes cortadas» | `Civ.Beds`, Tomé |

## 4 · Cómo encaja (técnica)

- `shared/Sea/NacaraV2.luau`: barrios, enlaces, medidas, presupuestos. `World/NacaraV2Builder.plan(opts)` devuelve
  piezas, mallas del kit y rellenos de terreno (cuentas puras); `build()` construye un **modelo Atomic por barrio**
  y pone el kit con `ReefZoneBuilder.makePiece` cuando `MarMeshes` lo tiene (si no, su respaldo de piezas).
- Con el interruptor encendido, `Civ` añade la isla del Palacio a sus zonas: el relieve y el decorado del fondo
  (`ShoreReef.cityBlocked`) la dejan libre. El coral del palacio no tapa ni la Concha del Consejo, ni las
  perlas-farola, ni los carteles, ni la plaza.
- Viviendas con las llaves `MarCasa_` de siempre; las anclas de las escenas no se mueven; los barrios son `Safe`
  para el hondario; las cúpulas con aire usan `SeaAirPocket` como hoy.

## 5 · Presupuesto en el móvil (roblox-performance)

| Qué | Ciudad entera (16 barrios) | Fase 1 (palacio y plaza) |
|---|---|---|
| Piezas del servidor | **1552** (barrios 1108 + enlaces 444) | 240 |
| Mallas del kit (una pieza cada una) | **1014** (≤ 1150) | 102 |
| Rellenos de terreno (una vez, al arrancar) | ≈ 500 | 47 |
| Luces de verdad (sin sombras) | 15 (como mucho 2 por barrio) | 1 |
| Cúpulas de cristal | 1–3 por barrio | 1 grande |

- Con StreamingEnabled y modelos Atomic, el móvil solo carga los barrios cercanos: desde cualquier sitio se ven
  2–4 islas (≈ 300–600 piezas y mallas), menos que la plaza de la fase 0 sola (782).
- El brillo es **Neon** (gratis); el cristal es lo más caro de pintar: una cúpula grande por barrio como mucho.
- Objetivo: 45 FPS en tu móvil (mirar si baja de 30). En cada fase, capturas con `/console`.

## 6 · Lo que se verá distinto en Roblox (sincero)

- **El agua y la niebla:** en Roblox la bruma azul tapa antes (≈ 200 studs de noche). Desde una isla verás bien 2–3
  barrios; la vista general de la imagen (desde 560 studs de alto) **no existe** en el juego: es para ver el plano.
- **El brillo:** Roblox tiene Bloom, pero más suave que Blender: el Neon brilla, pero sin tanto halo.
- **El cristal:** en Roblox es transparente y plano (sin refracción ni reflejos de verdad).
- **Las luces:** pocas luces de verdad (1 por barrio): las paredes lejos de la lámpara se ven más oscuras que aquí;
  las ventanas y franjas Neon sí brillan igual.
- **La fauna:** los peces, medusas y mantas de la imagen los pondría `SeaLife`/`NacaraLife` con las mallas de
  `MarFauna`; hoy no están colocados así alrededor de cada isla.
- **Los haces de luz:** en el juego son Beams (`ReefZoneFx`), más tenues de noche.
- **El tamaño:** tu mapa aprieta las islas; aquí hay agua entre ellas (6 studs como poco) para nadar por debajo de
  los tubos, y los edificios son más bajos que en tu imagen: nada pasa de 64 studs, salvo el palacio (92), para que
  los barcos pasen por encima.
- **Las formas:** todo son piezas de Roblox (cilindros, bolas, bloques): las cúpulas y agujas son redondas y
  limpias, no tan talladas como en tu imagen hecha con IA.

## 7 · Fases

| Fase | Qué |
|---|---|
| **0 (ahora)** | Este diseño, las vistas previas y todo el código apagado |
| **1** | Encender el Palacio Real y la Plaza Central; tus capturas de día y de noche, FPS |
| **2** | Mudar Residencias y Jardines; Mercado, Comercios y Hospital (tiendas, locales, despertar en el hospital) |
| **3** | Universidad, Biblioteca, Cueva, Templo, Santuario, Torre, Entrenamiento, Acuario y Puerto, de 3 en 3 |
| **4** | Corriente rápida en los tubos, la Ballena Lenta y los submarinos del puerto |

Para encender una fase: `NacaraV2.BuildPhase`. Cada fase: pruebas con Lune (`test-nacara-v2` y las del mar), revisión de
mallas si hay mallas nuevas (`scripts/audit/moderacion-mallas.py`, 0 avisos), vistas previas y tus capturas.

## 8 · Rehacer las vistas previas

```
lune run scripts/map/nacara-export.luau /tmp/nacara.json fase1 x v2
python3 scripts/map/nacara_v2_preview.py /tmp/nacara.json docs/mar/nacara-v2 --muestras 48 --ancho 1920
```
(`bpy` 4.2 con Python 3.11.)
