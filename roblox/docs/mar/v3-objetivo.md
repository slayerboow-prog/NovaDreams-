# Fondo marino v3: objetivo de arte (6 planos)

Encargo del dueño (4.ª vez, v125.5): «Hazlo bien… el fondo marino decente como un juego triple A». Las tres
rondas anteriores se dieron por buenas mirando números de Lune y vistas previas sueltas, no **cómo se ve**. Este
documento dice primero qué tiene que ver el jugador; el código (shared/Sea/ShoreReef, World/ShoreReliefBuilder,
Controllers/SeaBiome, ReefZoneFx, SeaLife) se cambia para llegar aquí y las vistas previas de `docs/mar/v3/` se
comparan con estos seis planos, uno a uno.

Reglas comunes a los seis planos:

- **Cámara**: la del móvil. Tercera persona detrás del buceador (≈ 11 studs detrás, 3 por encima), campo de visión
  **70° vertical**, apaisado **16:9**. El HUD tapa la franja de arriba (≈ 12 % del alto) y las dos esquinas de
  abajo (palanca y botones, ≈ 22 % del ancho cada una): lo importante del plano va en el centro y el tercio de abajo.
- **Geografía real** (ajustada tras la ronda 1): los jardines de coral de las playas están a 3–4 m (el fondo junto
  a la costa es −14); el arrecife más hondo, en el Arrecife Escarlata (~10 m); el borde de la plataforma, a
  ~13 m, con un escalón nuevo de hasta 10 studs (Ocean.LedgeDrop).
- **Escala**: 1 m = 3,57 studs. Superficie Y = −2. El personaje mide ≈ 5 studs.
- **Estilo**: estilizado, no realista: formas claras y legibles a 30 studs, colores vivos en lo cercano que se
  apagan con la bruma, nada de plástico liso (los corales con textura porosa, la arena con grano y ondas, la roca
  con su textura). **Ningún bloque, disco o bola sola** en el fondo.
- **Capas**: primer plano (0–15 studs, detalle y vida pequeña), plano medio (15–60, racimos y rocas que dan la
  forma), fondo (60–180, siluetas y bruma). El suelo **nunca** es un plano liso y vacío: entre parche y parche hay
  arena con ondas, nunca más de 12 studs seguidos sin nada.
- **Presupuesto del móvil**: ≤ 600 MeshPart de decorado alrededor (radio 96 studs), lo pequeño solo a < 48 studs,
  ≤ 160 piezas de vida (SeaLife), 2 luces de bioluminiscencia, 9 láminas de cáusticas.

Densidad (piezas del kit por 10×10 studs, media del parche):

| Parche | Densidad | Qué |
|---|---|---|
| Arrecife (Reef) | 3–4 | corales de 6 especies, anémonas, roca porosa, praderas en el borde |
| Borde (Rubble) | 0,8 | lajas y cantos pequeños, un coral joven |
| Pradera (Meadow) | 2–2,5 | matas de posidonia y alga ancha |
| Kelp | 0,6 kelp + 0,5 pradera | tallos de 10–34 studs |
| Rocas (Boulders) | 0,9 | cantos, roca porosa, lajas, esponjas |
| Arena (Sand) | 0,2 | estrellas, conchas, erizos, cangrejos + ondas del terreno |

---

## Plano 1 · Orilla de arena, 2 m (Playa del Sur, Y ≈ −9)

- **Composición**: el buceador en el centro, un poco por debajo de la mitad. El suelo ocupa la mitad de abajo y
  sube hacia la playa a la izquierda; a la derecha se abre el azul. Una pradera de posidonia en el plano medio
  marca la diagonal hacia el fondo; un parche de arrecife pequeño a 30–40 studs da el punto de interés.
- **Capas**: primer plano: arena con ondas de arenisca, una estrella y conchas; medio: matas de pradera (7–12 por
  parcela de 24 studs) y un racimo de coral sobre roca caliza; fondo: siluetas de rocas y la bruma turquesa.
- **Paleta**: arena (204,186,146) dorada, ondas (190,166,122); pradera (78,150,92)/(104,164,76); corales cálidos
  (238,98,128), (248,146,74); bruma (34,150,176); superficie vista desde abajo, brillante (160,222,232).
- **Luz**: cáusticas muy marcadas en la arena (de día, transparencia 0,55), rayos de sol finos inclinados desde
  la superficie, bruma que empieza a 40 studs y cierra a ≈ 180.
- **Se mueve**: las cáusticas se deslizan, la pradera se mece, un banco de peces de banco (8–10) pasa, el
  cangrejo anda de lado.
- **Wow**: 1) la luz ondulando en la arena; 2) la superficie plateada arriba; 3) el banco de peces cruzando.

## Plano 2 · Arrecife a ~10 m (Jardín Escarlata, el de las capturas del dueño, Y ≈ −37)

- **Composición**: un afloramiento de roca caliza cubierto de corales llena el tercio de abajo a la izquierda; a
  la derecha, otro racimo más lejos cierra el plano. El buceador entre los dos, mirando hacia el centro del arrecife.
- **Capas**: primer plano: anémonas rosas y un abanico; medio: 6–9 corales por racimo de 6 especies (cerebro,
  cuerno, mesa, abanico, esponjas, blando) y un pilar de vez en cuando; fondo: más racimos difuminados.
- **Paleta**: corales (238,98,128), (248,146,74), (250,204,92), (150,98,214), (92,200,196); mesas pardas
  (150,130,92); esponjas (230,160,70)/(176,82,160); roca (132,124,112); bruma (28,142,178).
- **Luz**: cáusticas en lo alto de las rocas y en la arena, rayos de sol, bruma desde 50 studs, cierra a ≈ 200.
- **Se mueve**: abanicos, coral blando y anémonas se mecen; 2–3 bancos de peces de arrecife (cirujano, ángel,
  loro) dando vueltas alrededor de los racimos; una tortuga pasa a lo lejos.
- **Wow**: 1) la densidad y variedad de color del arrecife; 2) los peces de colores dando vueltas al coral;
  3) la tortuga en silueta al fondo.

## Plano 3 · Repisa y caída de roca a ~10–13 m (el borde de la plataforma frente a Levante, Y ≈ −34)

- **Composición**: el borde del talud: una repisa de roca (pizarra y basalto) en el primer plano que se corta y
  deja ver la caída hacia el azul oscuro abajo a la derecha. Rocas grandes (cantos, roca porosa, lajas) en el
  medio.
- **Capas**: primer plano: lajas y cantos con erizos y esponjas; medio: rocas de 2–5 studs y un racimo de coral
  frío; fondo: la caída, que se pierde en la bruma azul marino.
- **Paleta**: roca (104,108,112)/(118,116,110), basalto (46,52,66); corales fríos (118,140,232), (196,110,220);
  bruma (18,86,148) arriba → (4,32,72) abajo.
- **Luz**: rayos de sol largos y tenues; sin cáusticas (demasiado hondo); bruma desde 30 studs.
- **Se mueve**: una manta pasa planeando por encima de la caída; motas en suspensión cerca de la cámara.
- **Wow**: 1) la sensación de borde y profundidad; 2) la manta en silueta; 3) el degradado de azul.

## Plano 4 · Bosque de kelp a 10 m (Laberinto de Kelp, Y ≈ −38)

- **Composición**: tallos verticales de kelp gigante a ambos lados, más juntos lejos, que hacen de columnas; un
  pasillo de arena en el centro hacia donde mira el buceador.
- **Capas**: primer plano: un tallo grande a un lado (corta el encuadre), cantos de basalto y pradera baja;
  medio: 2–3 kelp por parcela; fondo: tallos en silueta verdosa.
- **Paleta**: kelp (118,132,52)/(96,118,44)/(140,128,54); arena con fango (204,186,146)→(74,70,58); bruma verde
  (36,118,104).
- **Luz**: haces de sol que se cuelan entre los tallos, bruma verde desde 30 studs y cierra a ≈ 140.
- **Se mueve**: todo el kelp se mece despacio, peces de banco entre los tallos.
- **Wow**: 1) las columnas de kelp contra la luz; 2) los haces de sol entre los tallos; 3) el pasillo.

## Plano 5 · Llegada a Nácara, 37 m (Llanura Sumergida, Y ≈ −128)

- **Composición**: la plaza de Nácara en el centro del plano, a 90–120 studs, con sus torres de colores
  iluminadas; la llanura de arena y rocas sueltas (con kelp y corales fríos) en el primer plano lleva la mirada.
- **Capas**: primer plano: rocas de basalto y un racimo de coral frío; medio: la ruta de la llanura; fondo: la
  ciudad, las agujas del Cañón de las Catedrales detrás.
- **Paleta**: bruma (26,118,170) → más oscura; torres (rosa, violeta, cian, coral) que brillan; basalto
  (46,52,66), fango (74,70,58).
- **Luz**: la de la ciudad (perlas y coral que brillan), rayos de sol muy tenues; bruma desde 30 studs.
- **Se mueve**: la gente de Nácara, peces, partículas que brillan.
- **Wow**: 1) la silueta de la ciudad que brilla en el azul; 2) las torres de colores; 3) el contraste
  oscuro-luz.

## Plano 6 · El arrecife de noche (Jardín Escarlata, Y ≈ −37, a las 23:00)

- **Composición**: la misma que el plano 2.
- **Paleta**: bruma azul de luna (20,56,118), agua (22,66,132), ambiente (48,82,140); las anémonas y las setas de
  luz brillan en cian (90,245,255) y rosa (255,130,230).
- **Luz**: sin cáusticas; luz de luna azul; las anémonas brillan (Neon) y 2 luces de verdad; plancton que brilla.
- **Se mueve**: plancton, anémonas, una medusa que brilla.
- **Wow**: 1) la bioluminiscencia del arrecife; 2) la medusa que brilla; 3) el azul de luna.

---

## Cómo se comprueba

1. `lune run scripts/map/orillas-export.luau` vuelca, con el MISMO código del juego (ShoreReef.plan/relief/
   decor, Ocean.sample, OceanBiomes.look y la plaza de Nácara), el terreno con su relieve, cada malla del kit
   que se planta y los peces, en los seis sitios de arriba.
2. `python3 scripts/map/orillas_preview.py` lo dibuja en Blender con las mallas y texturas que hay subidas
   (assets/mar), la niebla y el color del agua de la zona y la cámara del móvil. Salen `docs/mar/v3/plano-N.jpg`
   (con «VISTA PREVIA, NO ES ROBLOX») y la hoja de antes y después.
3. Revisión a mano de cada plano frente a este documento (`docs/mar/v3/revision.md`), con todos los fallos, y
   otra vuelta hasta que encajen.
4. En un servidor de verdad: `bash scripts/cloud-test.sh mar-v125-sonda` (materiales del terreno por zona,
   piezas por zona con el plan, cáusticas y haces).
