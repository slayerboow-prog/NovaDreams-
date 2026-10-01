# Escenarios pendientes · 1. Infancia (colegio, misiones locas de niño, Acto I de la saga, rarezas de niño)

> Parte del análisis [`escenarios-pendientes.md`](escenarios-pendientes.md). Regla del dueño:
> **si pasa en la historia, el jugador tiene que poder verlo, oírlo o vivirlo.**
> Etiquetas de lo que hace falta: `[3D]` modelo · `[NPC]` personaje/rig · `[ANIM]` animación · `[PART]` partículas ·
> `[LUZ]` iluminación · `[SON]` sonido · `[MUS]` música · `[VFX]` efecto visual · `[CAM]` cámara/cinemática ·
> `[UI]` interfaz · `[FIS]` físicas · `[DEST]` destrucción · `[ENTORNO]` cambio de entorno · `[INT]` interacción ·
> `[PERSIST]` queda en el mundo · `[SCRIPT]` lógica nueva.
> **Escala**: 1 stud ≈ 0,28 m. Un niño del juego mide ≈ 3,5 studs (escala 0,65); un adulto ≈ 5,5 studs.

Índice: [Prólogo](#prólogo) · [Colegio 01–12](#colegio-misiones-principales) · [Consecuencias del cole](#consecuencias-y-secundarias-del-cole) ·
[Misiones locas de niño](#misiones-locas-de-niño-loco_nino) · [Saga, Acto I](#saga-de-la-grieta-acto-i-saga_acto1) · [Rarezas de niño](#rarezas-de-niño)

---

## Prólogo

### Prologo_Sueno · «Prólogo: el sueño» — Bebé (sueño) · Cosme · Prioridad C · S
Activación: lo lanza `LifeStoryService` al nacer (fase de SkyRift `Sueno`).
- **Existe**: la isla del sueño entera (`World/Kit/DreamIsland.luau`), los StorySpots `Prologo_*`, el tornillo
  (`Kind = "Cristal"`), las cinemáticas `Prologo_Apertura`/`Prologo_Cierre` y la Grieta dibujada en el cielo
  (`Controllers/SkyRift`, fase `Sueno`).
- **Falta**: «Por un segundo, el cielo parpadea en verde» al coger el tornillo (`Prologo_Sueno.luau:70`).
  → Destello verde de 0,4 s: `ColorCorrection` verde + pulso de brillo de la Grieta (`SkyRift` ya tiene intensidad).
  Necesita `[VFX][LUZ][SON]` (zumbido de «moscardón feliz»). Esfuerzo S.

---

## Colegio (misiones principales)

Las misiones del colegio son realistas y **casi todo existe**: casa familiar con StoryProps (`Kit/Home`), colegio con
aulas, pasillo, biblioteca, comedor, gimnasio, almacén, sala cerrada y marcas (`Kit/Civic.school`, `StoryMarks`),
parque con canasta, fuente, columpios y quiosco. Lo que falta son **objetos que hoy son un cubo o un marcador** y
**momentos que solo se cuentan**.

### Cole01_PrimerDia · «El primer día» — Niño · Familia, Lucía, Ramón · C · S
Activación: `Nino_PrimerDia` (capítulo), primera misión del cole.
| Acontecimiento (texto) | ¿Existe? | Falta | Necesita |
|---|---|---|---|
| «La puerta del colegio es un hervidero: mochilas, abrazos, **un autobús amarillo**» (l. 362) | Alumnos y padres sí (actores). Autobús: hay `StorySpot Autobus` (`Civic.luau:268`) y el constructor `Autobus` de `SceneService`, pero esta misión no lo pone | Autobús escolar aparcado en el spot `Autobus` durante el paso de llegada | `[3D]` (reutilizar `BUILDERS.Autobus` o un bus de `BusService`) |
| «¡RIIIING!» (l. 448) | No hay timbre | Sonido de timbre del cole al acabar la clase | `[SON]` |
| «¡PLAF! … libros, un cuaderno y un álbum de cromos salen volando» (l. 506) | Los libros aparecen ya en el suelo | Animación de tropiezo de Mateo + libros que salen despedidos (física corta, luego se anclan donde están los props) | `[ANIM][FIS]` |

### Cole02_Mochila · «La mochila desaparecida» — Niño · Lucía, Rubén, Bruno · C · S
- Existe: aula, taquilla 3, papelera, pistas (papel, pegatina, huellas, llavero, envoltorio), almacén con 4 mochilas.
- Falta: «Colchonetas, balones deshinchados… y varias mochilas amontonadas» (l. 274): comprobar que el almacén del
  gimnasio (`Civic.schoolGym`) tiene colchonetas y balones; si no, 3 colchonetas (6×0,6×4 studs) y una caja de balones.
  «Huellas de barro … van hacia el gimnasio» (l. 235): hoy es **una** huella; poner un rastro de 6–8 huellas
  desde el patio hasta la puerta del gimnasio. `[3D]` S.

### Cole03_Grupo · «El grupo» — Niño · Nico, Omar, Sara · C · S
- Existe: murales (`Mural`, panel liso 6×4), escarabajos (`Escarabajo` neón), canasta, columpios, quiosco, banco.
- Falta: el mural que **se pinta** (hoy es un panel de un color): 3 imágenes (Decal) que aparecen al pintar
  (cielo, colegio, «nosotros» con Ramón y sus llaves, l. 201) y **quedan pintadas** en el patio `[3D][PERSIST]`.
  «El escarabajo abre las alas y sale volando hacia la cancha» (l. 210): vuelo corto del prop `[ANIM]`.
  «¡PLOP! La piedra se hunde» (l. 316): salpicadura en el estanque `[PART][SON]`.

### Cole04_Malotes · «Los malotes» — Niño · Bruno, Hugo, Ramón · C · S
- Existe: pasillo, persecución (`Chase`), cajas del escondite, atajo por el aula de música.
- Falta: «¡perdón, piano!» (l. 231): nota de piano al cruzar el aula de música `[SON]`; Hugo «se sienta en el bordillo»
  (l. 235) → modo `Sit` en el bordillo detrás del gimnasio (hoy queda de pie si no hay asiento) `[ANIM]`.

### Cole05_Venganza · «La venganza de la mochila» — Niño · Iker · C · S
- Falta: «A Vega le han cambiado sus pegatinas brillantes por pegatinas de calcetines sucios… la taquilla de Nico está
  llena de papelitos» (l. 92–93): papelitos saliendo de la taquilla de Nico (prop `Papel` ×6 alrededor de
  `TaquillaNico`) y una hoja de pegatinas en el pupitre de Vega `[3D]`.

### Cole06_Examen · «El examen imposible» — Niño · Lucía, Marisa · C · S
- Falta: «El reloj de la pared hace un ruido que antes nunca habías oído» (l. 153): tic-tac fuerte durante el examen
  `[SON]`. Nada más (biblioteca y aula existen).

### Cole07_Excursion · «La excursión» — Niño · Paula, Julián · **B · M** · Paquete 1
Activación: tras el capítulo `Nino_Recados`, progreso de etapa 0,44. Lugares: `AutobusCole`, `Granja`,
`GranjaGranero`, `GranjaSilo` (granja **más cercana** de Villaverde: `Locations.luau:218-220`).
| Acontecimiento | ¿Existe? | Falta | Necesita |
|---|---|---|---|
| Viaje: «un tractor que os adelanta (¡os adelanta un tractor!)» (l. 149), cinemática `Cole07_Viaje` | Cinemática de cámara sí; autobús en carretera no | Autobús escolar recorriendo la Carretera de Villaverde con un tractor adelantándolo (solo para la cinemática) | `[3D][ANIM][CAM]` |
| «Aquí tenemos gallinas, caballos, un huerto, un tractor…» (l. 157) | Gallinas: `Kind = "Animal"` (bloque de 1,6×1,2×2,6 con patas). Caballos: el mismo bloque marrón. Tractor: **una caja roja de 2×2×2** (`Kind = "Caja"`). Huerto: marcador amarillo | Corral con 6–8 gallinas de verdad (el modelo de `AnimalPose.Gallina` ya existe en el cliente), cuadra con 2 caballos, tractor modelado (≈8×7×12 studs), huerto con zanahorias que se arrancan | `[3D][NPC][ANIM]` |
| «sale una zanahoria ENORME. Toda la clase aplaude» (l. 168) | No | Zanahoria gigante (1,5 m) que sale de la tierra + aplauso (`Anims Cheer` de los actores) | `[3D][ANIM][SON]` |
| «Una botella… huellas pequeñas… y otras más pequeñas todavía, de pezuñas» (l. 192) | Botella = marcador | Rastro de huellas niño + pezuñas desde el silo hasta detrás del granero | `[3D]` |
| «Detrás del granero… con un corderito blanco en el regazo» (l. 202) | Corderito = bloque `Animal` | Cordero (oveja pequeña de `AnimalPose.Oveja` a escala 0,6) en brazos de Mateo/Omar (`Sit`) que luego **os sigue** (l. 207) | `[NPC][ANIM]` |
| Foto de toda la clase «delante del granero» (`Cole07_Foto`, objeto `FotoExcursion`: «Hay una gallina en primer plano») | La foto es una cinemática genérica | Una gallina real en primer plano en el plano de la foto | `[NPC][CAM]` |
- **Si ya hiciste `Loco_N3_Pollo`**: Petra (tamaño normal, con lazo) en el gallinero y Julián guiñando un ojo `[PERSIST]`.

### Cole08_Torneo · «El torneo» — Niño · Andrés · C · S
- Falta: «Andrés te cuelga una medalla de ORO/PLATA» (l. 373): medalla visible en el cuello del jugador durante la
  escena final (accesorio temporal) y podio de 3 alturas en la pista `[3D][ANIM]`. Grada con familia existe (actores).

### Cole09_Misterio · «El misterio del colegio» — Niño · Lucía, Ramón · C · S
- Existe: sala cerrada (`StoryArea SalaCerrada`, `Civic.luau:397`), candado con código, anuario, llavero 13, trofeo.
- Falta: «La puerta cruje muy despacio» (l. 237) → animación de puerta + crujido; «Polvo, luz entrando por una ventana
  alta» (l. 242) → rayo de luz con motas de polvo dentro de la sala `[ANIM][SON][PART][LUZ]`.
- Consecuencia: «Lucía lee en voz alta las cartas… cada uno mete algo en una caja nueva» (l. 290–291): la caja nueva
  queda en la sala `[PERSIST]` (se abre en `Cole12`).

### Cole10_Festival · «El festival» — Niño · Vega, Marta, Omar, Sara, Hugo · **B · M** · Paquete 6
| Acontecimiento | ¿Existe? | Falta | Necesita |
|---|---|---|---|
| Decorar: guirnaldas, farolillos, cartel «FESTIVAL DE PRIMAVERA» con purpurina (l. 205–207) | Guirnaldas y farolillos son **marcadores** (cubo amarillo de 0,8). Cartel = panel liso | Guirnaldas de banderines entre farolas, farolillos de papel colgando, cartel pintado que brilla (purpurina) | `[3D][PART]` |
| «El patio está lleno: puestos, globos, música, familias» (l. 225) | Solo actores | Escenario (8×1×6) con altavoces, 4 puestos (limonada de Bruno, magdalenas, fotos, juegos), globos; música de feria | `[3D][MUS]` |
| «sopla un viento fuertísimo… ¡Mis farolillos!… el altavoz hace ¡PFFFZZ!» (l. 229) | No | Ráfaga de viento (hojas/confeti volando), farolillos que tiran de la cuerda y se balancean, chisporroteo del altavoz | `[VFX][FIS][SON]` |
| Número en el escenario, «El público se pone en pie… {abu} silba con dos dedos» (l. 295) | Minijuego `Timing` | Que el jugador esté **en el escenario** durante el minijuego; público aplaudiendo; silbido | `[CAM][ANIM][SON]` |
- Consecuencia: el patio queda decorado el resto del día del festival `[PERSIST corto]`.

### Cole11_Proyecto · «El proyecto final» — Niño · Omar y compañero elegido · **B · S** · Paquete 6
- Falta la **maqueta**, que es el centro de la misión: según la idea elegida (huerto, robot «Bocadillo» con pinza,
  tablón de mascotas con foto de Bigotes, museo con la foto de 1998, l. 277–280). Hoy no hay nada en la mesa.
  → 4 maquetas pequeñas (≈3×2×3 studs) sobre una mesa del aula; la del robot abre y cierra la pinza; la versión
  «rota» con tirita de cartón si pasó el desastre (`MaquetaRota`). `[3D][ANIM]`.
- «Las familias se ríen… aplauden» → actores existentes con `Cheer`.

### Cole12_UltimoDia · «El último día» — Niño · todos · **B · M** · Paquete 6
- Existe: recorrido de recuerdos (props `Asiento`, `Balon`, `Libro`, `Caja`, `Banco`), sala cerrada, cinemáticas
  `Cole12_Foto`, `Nino_FinPrimaria`, `Nino_AInstituto`.
- Falta: **la ceremonia** (l. 212: «Uno a uno, subís a recoger el diploma»): escenario con atril y diplomas, sillas para
  las familias, guirnalda «¡Adiós, 6.º!». La cápsula del tiempo «Dentro está todo lo que metió la clase» (l. 201) →
  caja de lata abierta con el objeto que elegiste en `Cole09` (carta, dibujo, predicción, pregunta). `[3D][ANIM]`.

---

## Consecuencias y secundarias del cole

| Id · Título | Prio · Esf. | Falta |
|---|---|---|
| Eco_MateoDibujo · Un regalo de Mateo | C · S | El dibujo («tú, recogiendo sus libros», l. 28) como imagen en la mochila/diario (`[UI]`) |
| Eco_MateoSolo · Mateo come solo | C · S | Que Mateo esté **sentado** comiendo en el rincón del patio (hoy aparece «cerca de ti», donde estés) `[ANIM]` |
| Eco_Ruben · Rubén | C · S | Nada físico (conversación) |
| Eco_Hugo · Hugo | C · S | Nada físico |
| Cole06b_Recuperacion · Recuperación | C · S | Nada físico |
| Eco_Periodico · El periódico de Valmar | C · S | El periódico con la foto del proyecto en la mano de la familia (prop) y en `[UI]` |
| **Side_GatoDelCole · El gato del colegio** (Omar, Ramón) | **B · S** · P2 | «¡tres gatitos diminutos!» (l. 168): hoy solo está Bigotes (`Kind = "Gato"`). Tres gatitos (el mismo constructor a escala 0,45) que maúllan, y que **se quedan** en el almacén unos días con una cesta de Ramón `[3D][ANIM][SON][PERSIST]`. Huellas: hoy 3 huellas sueltas; hacer un rastro y «un pelito naranja enganchado en la valla» |

---

## Misiones locas de niño (`Loco_Nino`)

Todas empiezan en el **garaje de Cosme** (`Kit/Home.cosmeGarage`, `StorySpot GarajeCosme`): existe un garaje de
14×16×9 studs con banco de trabajo, estanterías, chatarra y un cartel «TALLER DE COSME». Problema común:
**todas las criaturas son personas R15 pintadas** (`SceneService.buildModel`, l. 297–371: `HumanoidDescription`
con los colores de `Cast` y, si es «de otro mundo», un `Highlight` de color). Ver Paquete 2.

### Loco_N1_Cosme · «El vecino del garaje» — Niño · Cosme · **A · M** · Paquete 3 (canónica: abre la saga)
Activación: `Stage ≥ Niño`, marca dorada siempre visible (`Canon = true`, `CanonMarkers`).

**N1-E1 · ¡BUM! Humo verde del garaje**
- Historia: Descripción: «¡BUM! Del garaje del vecino sale humo verde. Y una voz: «¡NADIE TOQUE NADA QUE BRILLE!»»;
  Cosme «lleno de hollín» (paso 1, l. 49).
- Evento: al entrar el jugador en un radio de 40 studs del garaje mientras la misión está ofrecida/activa (antes de hablar).
- Visual: explosión sorda dentro del garaje, columna de humo verde que sale por la puerta enrollable y sube 20 studs;
  Cosme sale tosiendo, con la cara y la bata manchadas de hollín.
- Objetos/NPC: Cosme existe (humanoide). Hollín: no existe (textura/Decal de manchas en cara y bata).
- Animaciones: Cosme sale de espaldas tosiendo, se sacude, `Surprised` → `Point` al jugador.
- Efectos: `ParticleEmitter` humo verde (60 partículas, 3 s) + destello verde; chispas.
- Sonido: «BUM» apagado + tos + grito de la descripción (TTS).
- Cinemática: 3 planos (0–1 s plano general del garaje desde la acera; 1–3 s humo saliendo, cámara Shake 0,4; 3–5 s
  Cosme sale del humo, zoom Fov 60→45).
- Interacción: «Hablar» con Cosme cuando el humo se disipa.
- Consecuencia: mancha de hollín en la fachada del garaje `[PERSIST por jugador]` (se limpia en `Saga_24`).
- Necesita: `[VFX][PART][SON][CAM][ANIM][PERSIST]`.

**N1-E2 · Las tres piezas** (tornillo en la fuente, bobina en un helado, chip en el collar de Bigotes)
- «Cuando lo coges, durante un segundo ves el parque en blanco y negro, lleno de dinosaurios» (l. 79): destello del
  pasado: filtro blanco y negro 1 s + 2 siluetas de dinosaurio (planas, translúcidas) entre los árboles. `[VFX][ENTORNO]`.
- Bobina: un **niño con un helado rosa** con una bobina dentro (hoy es una `Maquina` rosa: caja con antena) → actor
  niño `Alumno1` con cucurucho + bobina metálica asomando. `[3D][NPC]`.
- Bigotes con chip en el collar: gato existe (`Gato`); añadir collar con chip que parpadea. `[3D]`.

**N1-E3 · La prueba del microondas temporal**
- Historia: «El microondas zumba. Brilla. Hace «ding». Dentro hay un bocadillo… un poco mordido» (l. 101).
- Existe: `Kind = "Maquina"` (caja gris de 3×3×2 con antena y 3 luces) — no parece un microondas.
- Falta: microondas reconocible (puerta de cristal, plato giratorio, display), con las 3 piezas acopladas; al usarlo:
  zumbido creciente, luz verde intermitente, temblor pequeño, «ding», la puerta se abre y sale el bocadillo mordido.
- Necesita `[3D][ANIM][LUZ][SON][CAM]` (plano corto: 4 s, cámara a la altura del microondas).
- Consecuencia: el microondas queda en el banco de trabajo **para siempre** (vuelve en `Saga_19`) `[PERSIST]`.

**N1-E4 · La raja de luz en el cielo**
- Historia: «Al salir del garaje, Cosme se queda mirando el cielo. Encima de Los Pinos hay una raja de luz, finísima,
  como un rasguño en el aire» (l. 114).
- Existe: la Grieta (`Controllers/SkyRift`) pasa a fase `Rasguno` al completar la misión (`SkyRift.phaseFor`).
- Falta: **el momento**: hoy la grieta aparece sin que nadie la mire. Cinemática corta (6 s): Cosme sale, mira arriba
  (`LookAt` al cielo), la cámara sigue su mirada hasta la grieta, que **se abre** de 0 a `Rasguno` delante del
  jugador con un destello y un sonido de cristal rajándose. `[CAM][VFX][SON]`.

### Loco_N2_Bigotes · «Bigotes, emperador de Gatonia» — Niño · Bigotes · **A · M** · Paquete 2
Activación: tras `Loco_N1_Cosme`, etapa Niño; se ofrece en el patio.
- **N2-E1 · La nota con la pata**: «te ha dejado una nota en la mochila. Con la pata. Pone «SOCORRO»» → objeto
  de inventario con huella dibujada `[UI]`.
- **N2-E2 · La nave aterriza en el patio**: «Una nave del tamaño de una furgoneta aterriza en medio del patio. Nadie más
  la ve» (l. 166). Existe `Kind = "Nave"`: platillo de 22 studs de diámetro **ya colocado** flotando a 14 studs, con
  haz. Falta: **la llegada** (baja desde 80 studs con bamboleo, haz que se enciende, tren de aterrizaje, rampa que
  se abre y de la que bajan las cucarachas), y que tenga tamaño de furgoneta (≈10×5×7 studs, no 22 de diámetro).
  Cámara: plano picado desde el tejado del cole, Shake 0,3. `[3D][ANIM][VFX][SON][CAM]`.
- **N2-E3 · Las cucarachas cazarrecompensas**: hoy `Cucaracha1-3` son **niños marrones** con brillo. Falta rig de
  cucaracha bípeda (cuerpo ovalado con caparazón brillante, 6 patas —2 para andar, 4 que gesticulan—, antenas
  animadas, casco/medallas para el Sargento Patitas). Al recibir un globo: antenas caídas y goteando; al irse
  («¡Antenaaas!»): suben corriendo a la nave, que despega. `[NPC][ANIM][PART]`.
- **N2-E4 · Globos de agua**: el rayo (`BeamColor`) hoy es un haz recto. Falta proyectil-globo que hace arco y revienta
  en salpicadura. `[VFX][SON]`.
- Consecuencia: Bigotes con corona (`Corona del emperador`) en el patio a partir de entonces `[PERSIST]`.

### Loco_N3_Pollo · «La gallina de seis metros» — Niño · Cosme, Julián · **A · L** · Paquete 1 (el primero)
Activación: tras `Loco_N1_Cosme`, etapa Niño, se ofrece en el garaje de Cosme. Lugares: `Granja`, `GranjaGranero`
(`Model Granja` → hijo `Granero`), `GranjaSilo`.

**Estado actual en el mundo (por qué el dueño no ve nada)**
- Granero: `Civic.farm` (`Kit/Civic.luau:786-791`) construye un `Building` estilo casa de **26×20 studs y una planta
  de 10 studs** (≈7×5,6×2,8 m), rojo, con `Interior = false`: **no se puede entrar** y no cabe una gallina de 6 m
  (≈21 studs).
- Huevo: `Kind = "Huevo"` = una bola de 2,4×3,2 studs (≈0,9 m) **fuera** del granero, a 4 studs de su esquina
  (`Offset = V(4,0,4)`), con contorno dorado.
- Petra: actor `PolloGigante` = **una persona R15 vestida de blanco y amarillo** con el pelo rojo, a escala 2,4
  (≈12 studs) (`Cast.luau:276`, `SceneService.buildModel`). No es una gallina.
- Al vencerla (`SceneService.defeat`) se eleva, se vuelve transparente entre chispas verdes y **desaparece**: no se ve
  cómo encoge ni vuelve al gallinero (que tampoco existe).
- Gallinas normales: existen en el cliente (`Controllers/Wildlife`, 5 gallinas sueltas en Villaverde, modelo de
  `AnimalPose.Gallina`), pero no hay gallinero.

**N3-E1 · El viaje en la furgoneta (que vuela un poquito)**
- Historia: «Cosme conduce su furgoneta. Que vuela. Un poquito. Solo en las curvas» (paso 2, `Transition`, l. 211).
- Hoy: pantalla negra con el texto 4 s y teletransporte a la granja.
- Visual: cinemática de 5 s: furgoneta destartalada de Cosme (blanca con manchas verdes, antena) por la Carretera de
  Villaverde; en una curva se despega 3 studs del suelo con chispas verdes y vuelve a caer; llega frenando a la
  granja con una nube de polvo.
- Objetos: furgoneta → reutilizar el modelo `Van` oficial (`modelos-oficiales-2.md`, id 6433316269) repintado, o
  `VehicleBuild`. `[3D][ANIM][VFX][CAM][SON]`.

**N3-E2 · Llegada a la granja: el desastre**
- Historia: Julián: «Esta mañana tenía doce gallinas. Ahora tengo once… y un edificio con plumas» (l. 240); «Petra
  está en el granero… Es muy, muy grande» (l. 241).
- Visual (solo para este jugador, mientras la misión está activa): plumas blancas gigantes (1,5–3 studs) por el
  camino y enganchadas en la valla; **huellas de tres dedos de 4 studs** desde el gallinero hasta el granero; el
  gallinero normal (pequeño) **reventado** (tablones por el suelo); las puertas del granero abombadas, con
  arañazos; de vez en cuando el granero **tiembla** y suena un «cloc» grave desde dentro; 11 gallinas normales
  escondidas detrás del tractor.
- Necesita: `[3D][PART][SON][ANIM][PERSIST corto]`.

**N3-E3 · El huevo gigante**
- Historia: «Un huevo gigante, calentito. Encima, alguien ha escrito con barro: «NO TOCAR». Con una pata de gallina»
  (l. 245). Nombre del prop: «Un huevo del tamaño de una lavadora».
- Visual: **dentro del granero**, en un nido de paja de 14 studs de diámetro, un huevo de 5×6,5 studs
  (≈1,4×1,8 m: más alto que tú de niño; la «lavadora» del texto se queda corta para un huevo de una gallina de
  6 m —propuesta: cambiar el texto a «del tamaño de una nevera»), crema con motas, letras «NO TOCAR» en barro
  (Decal) y vaho de calor (partículas suaves).
- Interacción: «Mirar el huevo» (ya existe el prop; cambiar `Kind` por el set nuevo).
- Necesita: `[3D][PART]`.

**N3-E4 · Petra aparece**
- Historia: «Detrás de ti, el suelo tiembla. Una sombra enorme. Un «CLOC» que hace vibrar las ventanas» (l. 246).
- Evento: al terminar el diálogo del huevo, antes del paso `Escape` (paso 5).
- Visual: Petra, **gallina de verdad de 21 studs** (≈6 m) de alto, blanca, cresta y barbillas rojas, pico y patas
  amarillas, de pie en el portón del granero, tapando la luz.
- NPC: rig nuevo `Gallina` a escala gigante (ver diseño, Paquete 2/1): cuerpo, cuello que se estira, cabeza con
  cresta, alas que se abren, cola, patas con dedos; mismo «motor» de movimiento que los actores (humanoide invisible
  dentro para `Hunt`).
- Animaciones: respiración, cabeza que se ladea (curiosa → enfadada), picoteo al suelo, aleteo amenazante, «cloc»
  con todo el cuerpo.
- Efectos: sombra que cubre al jugador, polvo que cae del techo del granero, plumas que caen, temblor por pisada
  (`CameraShake` a menos de 40 studs).
- Sonido: cacareo grave (sonido de gallina con el tono bajado al 40 %), pisadas «bum», crujido de madera.
- **Guion de planos (10 s)**:
  1. 0–2 s · Primer plano del huevo, cámara baja; se lee «NO TOCAR».
  2. 2–4 s · El huevo vibra; cae polvo del techo; `Shake` 0,6; sonido de pisada.
  3. 4–7 s · La sombra cubre al jugador. Cámara gira 180° y **sube** desde las patas de Petra hasta su cabeza
     (contrapicado, `Fov` 70→50).
  4. 7–9 s · Petra ladea la cabeza y hace «¡CLOC!» (`Shake` 1,0, plumas).
  5. 9–10 s · Plano general desde el silo: el jugador pequeñito y Petra enorme. Rótulo «¡CORRE HACIA EL SILO!».
     Vuelve el control (`Escape`).
- Necesita: `[NPC][ANIM][VFX][PART][SON][CAM]`.

**N3-E5 · La huida hasta el silo**
- Hoy: el humanoide escalado persigue (`Mode = "Hunt"`, `Speed = 12`, `Catch = 5`).
- Falta: Petra corre como gallina (cabeceo, alas medio abiertas), cada pisada levanta polvo y hace temblar; si te
  pilla, picotazo que te tumba (ragdoll corto) y vuelves al granero (`Respawn`); Cosme huye gritando por su lado.
- Necesita: `[NPC][ANIM][PART][SON][FIS]`.

**N3-E6 · El rayo encogedor**
- Historia: Cosme «está en el silo con algo en la mano»; disparar varias veces; `Hurt`: «Ha bajado un poco. Del tamaño
  de un camión a una furgoneta»; `Bye`: «Petra vuelve a medir lo que mide una gallina. Se va corriendo al gallinero,
  ofendidísima» (l. 226).
- Hoy: haz morado recto; Petra no cambia de tamaño; al final desaparece entre chispas.
- Falta: el rayo con espiral morada; **cada impacto encoge a Petra** (21 → 16 → 11 → 7 → 4 studs) con un «bloop»
  y un destello; el último impacto: «¡Pío!», nube de plumas y **una gallina normal** (≈1 stud) sale corriendo hasta
  el gallinero.
- Cámara: tras el último disparo, 3 s siguiendo a la gallina pequeñita hasta el gallinero (`CAM` seguimiento bajo).
- Necesita: `[VFX][ANIM][SON][CAM]`.

**N3-E7 · Consecuencias en el mundo**
- Julián: «Petra ya mide lo que tiene que medir. Y está en el gallinero, sentada encima de su huevo. Que ahora es
  normal» (l. 255).
- Persistente **por jugador** a partir de aquí: Petra (gallina normal con un lazo rojo y el nombre al acercarte) en el
  gallinero, sentada en un nido con un huevo normal; gallinero arreglado con tablones nuevos; una pluma gigante
  clavada en la puerta del granero como recuerdo; Julián con rutina (da de comer a las gallinas por la mañana).
  Recuerdo `GallinaGigante` ya existe (`Memories.luau:118`).
- Para **todos**: el granero grande y el gallinero existen siempre (son parte de la granja); la escena del desastre
  solo la ve quien tiene la misión activa.
- Necesita: `[PERSIST][NPC][3D]`.

### Loco_N4_Clones · «Deberes clónicos» — Niño · Cosme, Lucía · **A · M** · Paquete 2
- **N4-E1 · ¡PLOP! Tres clones en tu cuarto** (l. 316–318): hoy no aparece nadie en el cuarto (la escena es solo texto).
  Falta: al pulsar la clonadora (hoy `Maquina` caja), destello y **un clon idéntico al jugador** (copia de su
  `HumanoidDescription`/ropa, con brillo verde) que se come el cuaderno; otro que canta; otro subido a la silla.
  `Clon1-3` hoy son niños con camiseta azul genérica. `[NPC][VFX][ANIM][SON]`.
- **N4-E2 · Los clones duermen en tu cama, roncan** (l. 319): plano nocturno de la cama con tres clones y el jugador en
  la alfombra `[CAM][ANIM][SON]`.
- **N4-E3 · En el cole: uno baila detrás de Lucía, dos vienen a abrazarte** → ya hay actores (`Dance`, `Hunt`); faltan
  las caras/ropa del jugador. Al pulsar «deshacer»: «*pop*» con burbuja que estalla `[VFX][SON]`.
- **N4-E4 · La foto de los cuatro** (l. 338): foto (imagen generada con `ViewportFrame`) en el diario `[UI]`.

### Loco_N5_Perez · «La huelga del Ratón Pérez» — Niño (noche) · Ratón Pérez · **A · M** · Paquete 2
- **N5-E1 · Alguien refunfuña debajo de tu cama; enciendes la linterna** (l. 373): hoy el Ratón Pérez es un niño gris
  de 3,5 studs con brillo dorado, de pie junto a la cama. Falta: ratón de 1,2 studs con gafas, chaleco, saco de
  dientes y pancarta «HUELGA», que **sale de debajo de la cama** iluminado por un cono de linterna. `[NPC][ANIM][LUZ]`.
- **N5-E2 · «por la ventana entra una sombra. Una rata con antifaz agarra la bolsa… y salta afuera»** (l. 384):
  rata (1,5 studs, antifaz, capa) que entra por la ventana del dormitorio y sale por ella → hoy aparece en la puerta de
  la casa (`CasaFamiliar`, offset). `[NPC][ANIM][CAM]`.
- **N5-E3 · Persecución nocturna por el barrio hasta la fuente** (`Chase`): existe; falta el rastro de dientes que se le
  caen del saco (destellos blancos) `[PART]`.

### Loco_N6_Tirachinas · «El tirachinas del campeón» — Niño · {abu}, Cosme · **A · M** · Paquete 2
- **N6-E1 · El baúl**: «Fotos viejas, una medalla oxidada «1962», un cromo… y un tirachinas» (l. 468). Hoy `Caja`
  marrón de 2×2×2. Falta baúl con tapa que se abre y los objetos dentro. `[3D][ANIM]`.
- **N6-E2 · Latas en fila**: hoy un **marcador** (cubo neón). Falta fila de 5 latas sobre un tronco que caen al
  acertar (física) `[3D][FIS][SON]`.
- **N6-E3 · «¡CUCURRÚ-BIP! Tres palomas metálicas bajan en picado y se llevan los bocadillos»** (l. 471): hoy
  `PalomaRobot1-3` son **niños grises**. Falta paloma robot (cuerpo metálico, ojo rojo de la jefa, hélice o alas
  mecánicas) que **vuela** en picado, roba un bocadillo de un niño del parque y se posa; al acertar: chispa,
  «modo ahorro», se duerme en el suelo. `[NPC][ANIM][VFX][SON]`.
- Bellotas que hacen «¡plof!»: proyectil visible `[VFX]`.

---

## Saga de la Grieta, Acto I (`Saga_Acto1`)

La Grieta del cielo es **el único elemento de la saga que ya se ve siempre**: `shared/SkyRift.luau` +
`Controllers/SkyRift` la dibujan por jugador con fases (`Rasguno` → `Crece` → `Grande` → `Abierta` → `Cosida`…).
Lo que falta son los **acontecimientos**: que pase algo en el cielo y en el suelo cuando la historia lo dice.

### Saga_02_Grieta · «La grieta en el cielo» — Niño · Cosme, Pip, Bigotes · **B · M** · Paquete 3
Activación: tras `Loco_N1_Cosme` (fase del cielo `Crece`).
- **S02-E1 · «Esta noche han caído cosas. Cosas que no son de aquí»** (descripción): hoy los objetos están ya en el
  suelo. Falta: la **noche anterior** (o al aceptar la misión) tres estrellas fugaces verdes salen de la Grieta y caen
  en el parque, el patio y el camino al cole; en cada sitio queda un **cráter pequeño** (1,5 studs) humeante con
  brillo verde donde está el objeto. `[VFX][PART][SON][PERSIST corto]`.
- **S02-E2 · El calcetín que brilla y habla** (l. 68): hoy es `Moco` (charco neón). Falta calcetín verde
  (0,8 studs) que salta y habla. `[3D][ANIM]`.
- **S02-E3 · El paraguas que llueve hacia arriba** (l. 72): hoy `Cristal`. Falta paraguas abierto con gotas que
  **suben** debajo, y tres niños de primero mirando (actores) que aplauden al cerrarlo. `[3D][PART][ANIM]`.
- **S02-E4 · La moneda caliente con la cara de Cosme con perilla** (l. 75): hoy `Pegatina` dorada. Falta moneda
  humeante (vapor) y, al cogerla, primer plano de la cara grabada `[3D][PART][UI]`.
- **S02-E5 · Bigotes en el tejado del cole… bueno, en el patio**: Bigotes actor a escala 0,35 (persona naranja).
  Ver rig de gato (Paquete 2).
- **S02-E6 · «Se le cae el batido de apio. Pip lo recoge antes de que toque el suelo»** (l. 87): vaso que cae y Pip que
  lo atrapa `[ANIM][3D]`.
- Medidor de rarezas en el garaje (`Maquina`): aguja que se mueve y pita al acercar los restos `[3D][ANIM][SON]`.

### Saga_03_Pez · «El pez que sabía demasiado» — Niño · Don Escamas · **A · M** · Paquete 2
- **S03-E1 · Un pez naranja que respira aire, lleva corbata y pide auxilio** (descripción): hoy `DonEscamas` es un
  **niño naranja a escala 0,35** junto al estanque. Falta pez de 1,2 studs con corbata y monóculo que asoma del
  agua del estanque, salta y habla. `[NPC][ANIM][PART]` (salpicaduras).
- **S03-E2 · El cubo** (`Papelera` verde) → cubo de playa con agua; Don Escamas salta dentro «¡hop!» y viaja en él
  (el jugador lo lleva: accesorio en la mano) `[3D][ANIM][INT]`.
- **S03-E3 · «Dos hombres de traje gris aparecen entre los árboles. Sonríen a la vez»** (l. 159): existen (actores
  grises); falta la aparición (salen de detrás de árboles con un parpadeo gris) y la sonrisa sincronizada
  (animación facial/gesto a la vez) `[ANIM][VFX]`.
- **S03-E4 · La pecera nueva de Cosme** (`Caja` azul) → pecera de cristal con agua, castillo y burbujas, con Don
  Escamas dentro **para siempre** `[3D][PERSIST]`.

### Saga_04_Ventanilla · «La ventanilla 42» — Niño · Cronos, Funcionaria · C · S
- Todo pasa en sitios existentes (garaje, Correos, banco, comisaría). Falta: «la misma señora… ¿cómo ha llegado antes
  que tú?» → que la funcionaria **desaparezca** con un parpadeo al irte y ya esté en la siguiente ventanilla `[VFX]`;
  sello que se estampa con «¡PUM!» `[SON][ANIM]`.

### Saga_05_Perdidas · «La noche de las cosas perdidas» — Niño · Ramón, Pip, Nico, Lucía · **A · L** · Paquete 3
Activación: tras `Saga_04`, de noche (`Requires` con horas), fase del cielo `Grande`.
- **S05-E1 · La Grieta absorbe lo perdido y lo escupe en el gimnasio** (descripción). Visual: desde el patio, un
  remolino de objetos (llaves, calcetines, paraguas, balones, gafas) que sube de toda la ciudad hacia la Grieta y
  luego **cae como lluvia** por el techo del gimnasio (columna de luz verde sobre el cole). Cinemática de 8 s:
  1) plano de la ciudad con puntos de luz que suben; 2) cámara sigue un calcetín hasta la Grieta; 3) corte al tejado
  del gimnasio con la cascada de objetos; 4) dentro: montaña de cosas. `[VFX][PART][CAM][SON]`.
- **S05-E2 · El gimnasio lleno**: dentro (`StoryArea Gimnasio`) una **montaña de cosas perdidas** (≈20×6×14 studs) con
  calcetines, llaves, juguetes, un balón firmado, un diario amarillo — hoy solo hay 3 props sueltos. `[3D]`.
- **S05-E3 · «Del gimnasio sale un ruido enorme. Como si mil pies arrastraran calcetines»** (l. 336) → sonido + la
  montaña se mueve. `[SON][ANIM]`.
- **S05-E4 · El Monstruo de los Calcetines Desparejados**: hoy humanoide rosa/azul/amarillo a escala 1,6. Falta
  monstruo **hecho de calcetines** (≈9 studs, cuerpo de bolas de calcetines cosidas, brazos-calcetín largos, ojos de
  botón), que al «emparejar» pierde calcetines (salen volando de dos en dos) y encoge hasta dejar **un calcetín
  verde** en el suelo (l. 341). `[NPC][ANIM][PART]`.
- Consecuencia: el gimnasio vuelve a estar limpio a la mañana siguiente; Ramón con sus llaves de 1994 colgadas en
  conserjería `[PERSIST]`.

### Saga_06_Coser · «Coser el cielo» — Niño (noche) · Cosme, Pip · **A · L** · Paquete 3
Activación: tras `Saga_05`, entre las 19:00 y las 6:00; fase del cielo `Abierta` (la más amenazante).
- **S06-E1 · Clavar los tres anclajes** (parque, patio, plaza): hoy `Cristal` (dos prismas neón de 3 studs).
  «Suena como una campana muy lejos. En el cielo, la Grieta tiembla» (l. 412). Falta: cristal de 4 studs que se clava
  con golpe, anillo de luz en el suelo, **un hilo de luz verde que sube del anclaje a la Grieta**, campanada lejana y
  temblor de la Grieta (pulso de `SkyRift`). Los tres hilos se ven desde toda la ciudad. `[3D][VFX][SON][ENTORNO]`.
- **S06-E2 · Agentes grises vigilando** (Wander) y pelea en el patio → existen (humanoides grises). Falta el
  comunicador visible y que se rompa `[3D][VFX]`.
- **S06-E3 · La aguja cuántica cose el cielo** (l. 415): «La aguja sube como un cohete y cose el cielo, punto a punto,
  con hilo de luz. La grieta se cierra. Valmar entera se queda a oscuras un segundo… y vuelve la luz».
  - Hoy: prop `Cohete` (cilindro blanco de 10 studs) quieto en el patio + cinemática `Saga_Coser`
    (`Cinematics.luau:365`) que **mueve la cámara al cielo donde no pasa nada**; la fase pasa a `Cosida` al acabar.
  - Falta: la aguja despega (estela de chispas), sube hasta la Grieta, **recorre la raja de punta a punta** dejando
    puntadas de luz en zigzag; la Grieta se estrecha mientras tanto; **apagón** de 1 s de todas las luces de la
    ciudad (para el jugador: `Lighting` a negro, farolas apagadas) y vuelven.
  - **Guion de planos (12 s)**: 1) 0–2 s el jugador con la aguja, contrapicado; 2) 2–4 s despegue, cámara sigue la
    aguja hacia arriba, `Shake` 0,5; 3) 4–8 s plano largo del cielo: la aguja cose de izquierda a derecha (la cámara
    acompaña en `Orbit` lento); 4) 8–9 s apagón total (negro con estrellas); 5) 9–10 s vuelven las luces, barrio
    desde arriba; 6) 10–12 s costura brillando en el cielo + rótulo «El cielo está cosido».
  - Necesita: `[VFX][CAM][LUZ][ENTORNO][SON][MUS]`.
- **S06-E4 · La voz desde la costura** (l. 417–420): «del último punto de la costura sale una voz… Silencio. La costura
  brilla un momento y se apaga. Cosme está blanco como su bata» → pulso de luz en la costura sincronizado con cada
  frase de la voz (Cósimo, TTS grave con eco), y Cosme pálido (`Sad`/`Surprised`) `[VFX][SON][ANIM]`.
- Consecuencia: costura visible en el cielo (fase `Cosida`, existe) + **los tres anclajes quedan clavados** en el
  parque, el patio y la plaza, con un brillo débil `[PERSIST por jugador]` (vuelven en `Saga_07` agrietados y en
  `Saga_19`).

---

## Rarezas de niño

Requieren `Saga_02_Grieta` hecha. Casi todas las pide **Pip** (humanoide gris; ver rig de robot, Paquete 2).

| Id · Título | Giver · Activación | Prio · Esf. | Qué cuenta la historia | Qué hay | Qué falta | Necesita |
|---|---|---|---|---|---|---|
| Rareza_Buzon · El buzón que escribe al pasado | Pip · Correos | C · S | El buzón amarillo devuelve cartas con fecha de ayer; papel mojado en la fuente; un sello que brilla verde | `Kiosco` amarillo (caseta de 5×4×3) | Buzón de correos real (columna amarilla 1,5×3,5 studs) que **escupe** la carta; sello con brillo | `[3D][ANIM][PART]` |
| Rareza_Farola · La farola que canta ópera | Pip · parque, 19–23 h | **B · S** | «¡FÍÍÍGAROOO!», vecinos que no duermen, aplauden desde las ventanas | `Maquina` (caja con antena) | Que cante **una farola real del parque** (marcarla): bombilla que late con la voz, notas musicales flotando, ventanas de las casas que se encienden y vecinos asomados | `[VFX][SON][MUS][LUZ]` |
| Rareza_Columpio · El columpio que va al pasado | — · columpios | **B · M** | Cuanto más alto, más atrás: el parque se vuelve sepia, coches redondos, un niño con gorra (tu abu) graba un banco | `Transition` negra con texto y teleport al mismo sitio | Filtro sepia progresivo con la altura del columpio, 2 coches antiguos y el niño-abu (actor) grabando el banco; al bajar, el color vuelve; las iniciales quedan en el banco `[PERSIST]` | `[VFX][ENTORNO][NPC][3D]` (Paquete 5) |
| **Rareza_Sombra · La sombra que se escapa** | — · patio, 9–19 h | **A · M** | Tu sombra se despega y se va a jugar; sin ella no haces sombra; Pip la acorrala; vuelve arrastrando los pies | **Nada**: dos pasos `Reach` y una charla | Silueta negra plana con tu forma (copia del avatar en negro, sin volumen) que corre por el patio y el parque; mientras, tu personaje **no proyecta sombra** (`CastShadow = false`); al final se «pega» a tus pies con animación | `[NPC][VFX][ANIM][SCRIPT]` |
| Rareza_Helado · El helado que sabe a recuerdos | Pip · heladería | C · S | Sabor verde Grieta; flashback al primer día de cole | `Kiosco` verde | Cubeta verde brillante en el mostrador; flashback de 3 s (filtro + imagen del primer día) | `[VFX][CAM]` |
| Rareza_Charco · El charco sin fondo | Pip · parque | **B · S** | Charco que refleja un cielo morado con dos lunas; un patito de goma cae hacia arriba; luego flota sobre el estanque | `Moco` azul (disco) | Charco con superficie que muestra **otro cielo** (textura animada morada con dos lunas), patito que sale del charco hacia arriba; patito flotando en el aire sobre el estanque `[PERSIST]` | `[VFX][3D][ANIM][PERSIST]` |
