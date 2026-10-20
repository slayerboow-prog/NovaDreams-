# Escenarios pendientes · 3. Universidad (campus, residencia, secundarias, misiones locas, Acto III, rarezas, metro)

> Parte del análisis [`escenarios-pendientes.md`](escenarios-pendientes.md). Mismas etiquetas y escala que en
> [`escenarios-1-infancia.md`](escenarios-1-infancia.md). Etapa `AdultoJoven`.

Índice: [El problema de la residencia](#el-problema-de-la-residencia-afecta-a-12-misiones) · [Principales](#misiones-principales-de-la-universidad) ·
[Secundarias](#secundarias-de-la-universidad-uni_secundarias) · [Misiones locas](#misiones-locas-de-la-universidad-loco_uni) ·
[Saga, Acto III](#saga-de-la-grieta-acto-iii-saga_acto3) · [Rarezas](#rarezas-de-la-universidad) · [Metro](#metro-metro_secundarias)

---

## El problema de la residencia (afecta a 12 misiones)

`Locations.luau:154-157` define tres lugares:
- `Residencia` → `StorySpot SpotId = "Residencia"`: **existe**, lo pone `InteriorService.hostResidences`
  (`InteriorService.luau:1415-1444`) **delante de la puerta** de un bloque del campus convertido en residencia (por dentro
  tiene habitaciones de verdad, `Floors` «Dorm»).
- `HabitacionResidencia` y `CocinaResidencia` → `StorySpot` que **ningún código del mapa crea** (búsqueda: solo aparecen
  en `Locations.luau`). Caen a su `Fallback = "Residencia"`: **la acera de la puerta**.

Resultado: «tu habitación de la residencia» (la 214, con tres camas, el corcho de fotos, la maleta con pegatinas) y «la
cocina compartida de la cuarta planta» (la nevera de cuarenta estudiantes, la sartén quemada, la pizarra de turnos)
**no existen**: Iván, Candela, la nevera y tu cama aparecen en la calle. Lo usan: `Uni01_PrimerDia`, `Uni01b_Residencia`,
`UniEx1`–`UniEx4`, `UniS_Zumo`, `UniS_Acampada`, `UniS_Cita`, `UniS_Tito`, `UniS_Pabellon0`, `Saga_13`, `Saga_20`,
`Rareza_Reloj`, `Rareza_Wifi`.

**Qué construir** (Paquete 4): en la residencia de verdad, una planta «de la historia» con:
- **Habitación 214** (≈18×14 studs): tres camas (la tuya junto a la ventana, la de Iván deshecha con pegatinas de
  grupos, la de Candela con etiquetas de colores), tres escritorios, **corcho de fotos** (fotos que se van añadiendo
  según las misiones hechas: primera cena, fiesta de Adrián, día de playa, Tito «en todas»), la cinta aislante en el suelo
  de la «guerra del zumo», ventana al campus. Marca `StorySpot HabitacionResidencia`.
- **Cocina compartida** (≈24×16): nevera grande con baldas etiquetadas («el yogur de 2019»), fogones, mesa larga,
  pizarra de turnos, sartén quemada colgada, el reloj de pared (para `Rareza_Reloj`), el módem viejo (`Rareza_Wifi`).
  Marca `StorySpot CocinaResidencia`.
- **Entrada/conserjería de Doña Pilar** con el reloj de la entrada (que va al revés en la rareza).
- Material: *House Furniture Pack – Duvall Drive* y *House Props Pack* (`modelos-oficiales-2.md`), muebles de
  `World/Furniture`. Es por jugador solo en lo que cambia (fotos del corcho, cinta del suelo); la planta es de todos.

---

## Misiones principales de la universidad

| Id · Título | Giver · Activación | Prio · Esf. | Lo que cuenta / lo que falta | Necesita |
|---|---|---|---|---|
| Uni01_PrimerDia · Primer día en el campus | Familia, Luca, Beltrán · tras el instituto | C · S | Campus, facultades, biblioteca y estadio existen. Falta: secretaría (marcador) → mostrador con cola; «un chico durmiendo en el césped con un libro en la cara»; el **reloj de {abu}** (objeto que te da y que reaparece en la graduación) `[3D][UI]`; la habitación (ver arriba) | `[3D][NPC]` |
| **Uni01b_Residencia · La residencia** | Doña Pilar, Iván, Candela | **A · M** · P4 | Toda la misión pasa en la habitación y la cocina: sin ellas, se juega en la acera. Falta todo lo descrito arriba + las llaves que te da Pilar + la cama que se puede usar para dormir (`Bed = true` ya existe en el prop) | `[3D][INT][PERSIST]` |
| UniEx1_Enero · Los exámenes de enero | Candela, Iván | C · S | Pánico en la habitación (sin habitación); biblioteca 24 h; prueba física «circuito» en el estadio (existe). Falta: calendario plastificado en la pared; la biblioteca de noche con estudiantes dormidos `[3D][NPC]` | `[3D]` |
| UniEx2_Junio · Junio (y julio) | Iván, Candela | C · S | «El campus se queda vacío y hace un calor horrible» → menos gente en julio, calima | `[ENTORNO]` |
| UniEx3_Parcial · El parcial imposible | Beltrán | C · S | Tablón «Superviviente del parcial de Beltrán» con 40 nombres y el tuyo añadido `[3D][PERSIST]` | `[3D]` |
| UniEx4_TFG · El trabajo de fin de grado | Beltrán, Iván, Candela | C · S | Tribunal: mesa con tres profesores en un aula; Candela con una sirena (l. 369) `[3D][SON]` | `[3D][NPC]` |
| Uni02_ElProyecto · El proyecto | Beltrán, Julia, Adrián, Carla, Pablo | C · S | Pablo toca la guitarra en la plaza «rodeado de gente» (l. 186) → guitarra y corrillo `[3D][NPC][MUS]`; Carla con su hermano en los columpios (existe) | `[3D][MUS]` |
| Uni03_PrimerTrabajo · El primer trabajo | Lola, Ernesto, Rocío/Alba | C · S | Clases a Alba: dibujos de dinosaurios comiendo pizza (cuaderno) `[UI]` | `[UI]` |
| Uni04_Practicas · Las prácticas | Nuria/Sofía/Montse/Ignacio | C · S | Lugar de prácticas por carrera (hospital, laboratorio, bufete, banco). Ingeniería: «La pasarela vibra al ritmo de los pasos» → maqueta o pasarela que vibra `[3D][ANIM]` | `[3D]` |
| Uni05_PrimerPiso · Tu primer piso | Familia, compañeros | C · S | Cajas de mudanza (existen: `Caja`) en «CercaDeTi»: deberían estar **en tu piso nuevo** (`HousingService`), con la nevera vacía y sin cortinas `[3D][PERSIST]` | `[3D]` |
| **Uni06_Graduacion · La graduación** | Beltrán, familia, todos | **B · M** · P6 | «Toga, birrete, tu nombre por el altavoz… Birretes al aire» (l. 145): falta el acto: escenario con atril y banderas en la facultad, sillas, **togas y birretes** en los actores y el jugador, birretes volando en la cinemática `Uni_Graduacion`; celebración en la Cafetería Central «cerrada para vosotros» (cartel «Cerrado por fiesta», guirnaldas) | `[3D][ANIM][CAM][FIS]` |
| Eco_Concierto · El concierto de Pablo | Pablo | C · S | Pablo toca en la plaza de noche: tarima pequeña, foco, amplificador, gente | `[3D][LUZ][MUS]` |

---

## Secundarias de la universidad (`Uni_Secundarias`)

### UniS_Zumo · «La guerra del zumo de mora» — Iván, Candela, Pilar · **B · S** · Paquete 4
- Falta (además de la cocina): «Iván pega cinta aislante en el suelo. Candela pega cinta… encima, más recta» (l. 80) →
  líneas de cinta en el suelo de la habitación `[PERSIST]`; «Huellas moradas de pies descalzos… en zigzag» (l. 86) →
  rastro de huellas moradas de la cocina a la 214; el pijama de dinosaurios manchado en la papelera; la botella con la
  etiqueta escrita a mano. Vídeo de Candela: Iván sonámbulo bailando una jota (`[UI]` o mini-cinemática). `[3D][CAM]`.

### UniS_Fiesta · «Fiesta en casa de Adrián» — Adrián, Julia, Pablo, Iván, Candela, vecino · **B · M** · Paquete 4
- «Adrián vive encima de la cafetería del centro»: la fiesta se juega **delante de la Cafetería Central** (actores con
  `Place = "CafeteriaCentral"`). Falta: **el piso de Adrián** (interior de una vivienda encima de la cafetería:
  `Interiors.Piso` amueblado + luces de fiesta, música, comida), el timbre y el vecino de abajo en la puerta; «os enseña
  a bailar twist» → baile de todos. `[3D][LUZ][MUS][ANIM]`.

### UniS_Acampada · «Acampada en el monte» — Iván, Candela, Julia, Luca · **B · M** · Paquete 4
Lugar: `MonteSilencio` (`StorySpot` al pie del sendero, `Kit/Wilds.luau:226`; existe cartel «MONTE DEL SILENCIO ↑ Cima»).
| Acontecimiento | Existe | Falta | Necesita |
|---|---|---|---|
| Montar la tienda «al revés. Dos veces» (l. 228) | `Caja` verde | Tienda de campaña que se monta en 2 fases (y la versión al revés) | `[3D][ANIM]` |
| La hoguera «prende a la tercera»; nubes de azúcar (l. 234) | `Cristal` naranja | Hoguera con troncos, `Fire`, humo, luz cálida, chisporroteo; palos con nubes | `[3D][PART][LUZ][SON]` |
| Zarzal con moras que brillan en la oscuridad (l. 231) | `Escarabajo` morado | Zarzal (arbusto del *Forest Pack*/*Landscaping Pack*) con bayas neón moradas | `[3D][LUZ]` |
| «A las tres de la mañana, una luz se enciende sobre el monte… baja flotando una figura verde con antenas» (l. 252) | `Nave` sin haz a 30 studs | La luz se enciende de golpe (antes no hay nada), haz que baja, Blorp **flotando** hasta el zarzal, coge moras, saluda y sube | `[VFX][LUZ][ANIM]` |
| «Candela ha grabado todo. Al día siguiente, el vídeo solo se ve borroso» | No | Vídeo borroso en `[UI]` | `[UI]` |

### UniS_Playa · «Día de playa» — Julia, Adrián, Iván, Candela, Carla · **A · M** · Paquete 2
- **P-E1 · Castillos de arena** (l. 315): «una réplica exacta de la facultad», «un dragón», tu castillo «con foso y una
  bandera de patata frita» → hoy `Caja` beige. Tres esculturas de arena `[3D]`.
- **P-E2 · «la arena tiembla. Del mar sale un cangrejo enorme, con corbata y un maletín»** (l. 316, descripción: «del
  tamaño de un coche»): hoy `DonPinzas` es un **humanoide rojo a escala 2** que aparece en la arena.
  - Falta: rig de **cangrejo** (caparazón de 10×4×7 studs, dos pinzas grandes, ocho patas, ojos en antenas, corbata,
    gafas, maletín en una pinza) que **sale del mar** (agua que chorrea, temblor, olas), anda de lado.
  - Combate: «echarle un cubo de agua dulce» → cubo y salpicadura; al final se va al mar y «donde estaba Don Pinzas
    hay una pinza dorada» (`[PERSIST corto]`).
  - Cámara: plano desde el agua con el cangrejo emergiendo, `Shake` 0,4.
  - Necesita `[NPC][ANIM][VFX][PART][SON][CAM]`.

### UniS_Pabellon0 · «El pabellón que no sale en los mapas» — Candela, Iván · **A · L** · Paquete 4
Lugar: `ResidenciaCampus` + offsets (18–26, 0, 6–14): **puntos sueltos al aire libre** detrás de la residencia.
- **P0-E1 · El mapa antiguo del campus** con el «Pabellón 0» (l. 377) → mapa en `[UI]` con el edificio marcado.
- **P0-E2 · «Entre los árboles, una puerta tapiada con tablones viejos… ceden al primer empujón»** (l. 382): hoy
  `Armario` (armario marrón de pie en el césped). Falta **el Pabellón 0**: edificio pequeño abandonado (≈30×20×12 studs)
  de ladrillo con hiedra, ventanas rotas, escondido entre árboles detrás de la residencia, puerta tapiada con tablones
  que **caen** al empujar. `[3D][DEST][ANIM]`.
- **P0-E3 · Dentro**: pizarra con fórmulas y el dibujo de la aguja (hoy `Mural` verde oscuro de pie en el césped);
  **la Cosedora Dimensional, prototipo 1** «del tamaño de un coche, llena de cables y agujas… la parte de delante quemada»
  bajo una sábana (hoy `Maquina` de 3×3×2); la foto en el suelo. Polvo, rayos de luz por las ventanas, cables colgando.
  Al levantar la sábana: la sábana se desliza (animación) y se ve la máquina. `[3D][PART][LUZ][ANIM]`.
- **P0-E4 · «Alguien con traje gris mira por la ventana. Sonríe»** (l. 396) → cara del agente en la ventana rota, susto
  con golpe de música, luego persecución (`Escape`, existe) `[NPC][CAM][SON]`.
- Consecuencia: el Pabellón 0 queda en el mapa **para todos** (escondido, sin marca) y por dentro: abierto para quien
  hizo la misión `[PERSIST]`. Es el mismo laboratorio del flashback de `Saga_09` (versión vieja/quemada).

### UniS_Cita · «Una cita (o algo así)» — Julia/Adrián/Luca/Carla · C · S
- Atardecer en Playa Dorada con dos helados (heladería existe). Falta: forzar el cielo de atardecer en el momento (o
  esperar a la franja horaria, ya se pide `Hours 18–22`); el helado que cae en la zapatilla (prop) `[3D]`.

### UniS_Tito · «El compañero que no existe» — Tito, Pilar, Candela · **B · S** · Paquete 4
- Falta (además de la habitación): **el corcho de fotos** con Tito «siempre en el borde… mirando a cámara» y la foto de la
  sartén con su oreja detrás (l. 521–522) → fotos (imágenes) en el corcho y ampliables en `[UI]`; Tito se quita las gafas
  y debajo tiene gafas de sol (accesorio doble); al vencerle «Chispas grises. Fuera» `[3D][UI][VFX]`.

---

## Misiones locas de la universidad (`Loco_Uni`)

### Loco_U1_Monte · «La luz del Monte del Silencio» — Luca, Blorp, Zarg, Capitana Ñoz, Fermín, Inés · **A · M** · Paquete 4
Lugares: `MonteSilencio` (pie del sendero) y `CimaMonte` (`StorySpot MonteSilencio_Cima`, `Kit/Wilds.luau:241`).
- **U1-E1 · El cartel de SE BUSCA** con tres letras distintas debajo (l. 91–92) → cartel en el poste del sendero
  `[3D]`.
- **U1-E2 · «El aire zumba. Se te erizan los pelos de los brazos. Arriba, las estrellas… se apagan una a una»** (l. 96):
  - Falta: zumbido grave creciente, estrellas del cielo apagándose una a una (por jugador: `Lighting`/`Sky`
    `StarCount` bajando), viento que se para, un punto de luz que crece.
- **U1-E3 · La nave** (cinemática `Loco_Abduccion` + prop `Nave` a 22 studs): existe el platillo. Falta: la llegada
  (descenso con luces giratorias), **escalerilla que baja**, los tres aliens bajando por ella «con cara de estar MUY
  hartas», Blorp tropieza y la pistola rueda hasta tus pies (l. 106). `[3D][ANIM][LUZ][CAM]`.
- **U1-E4 · Abducidos en pijama** (l. 115): «De la luz bajan flotando tres personas en pijama. La última lleva botas de
  montaña y un bocadillo» → tres actores (Fermín y dos vecinos) bajando despacio por el haz `[NPC][ANIM][VFX]`.
- **U1-E5 · «La nave sube, sube… y desaparece con un «piuuu» ridículo. En el cielo vuelven a salir las estrellas»**
  (l. 118) → despegue rápido con estela, sonido, estrellas que se encienden `[VFX][SON][ENTORNO]`.
- Consecuencia: marca de **hierba quemada en círculo** en la cima (12 studs) `[PERSIST]`; el cartel de SE BUSCA tachado.

### Loco_U2_Rex · «Mi compañero de piso es un dinosaurio» — Rex, Cronos, Cosme · **A · M** · Paquete 2
- **U2-E1 · Rex**: «Es un velocirraptor de una línea temporal donde los dinosaurios no se extinguieron» (Cast). Hoy:
  **humanoide verde con camisa blanca**. Falta rig de velocirraptor bípedo con ropa (camisa, gafas, Código Civil bajo
  el brazo), cola que se balancea, garras, cabeza que ladea; voz educada. `[NPC][ANIM]`.
- **U2-E2 · La casa**: nevera vacía con pósit, **sofá con tres zarpazos** (l. 201–204) → hoy `Caja` y `Banco` genéricos
  en tu salón. Falta: zarpazos en el sofá real de tu casa (Decal) `[PERSIST]`, pósit en la nevera real `[3D]`.
- **U2-E3 · Cronos llama al timbre** «Todo él brilla un poquito» → existe (actor con brillo); falta el timbre `[SON]`.
- **U2-E4 · Huida a la Facultad de Derecho** con Rex (`Escape`): Rex corre a cuatro patas cuando huye `[ANIM]`.
- Consecuencia (si `RexSeQueda`): Rex en tu casa con rutina (lee en el sofá, ve la tele) `[PERSIST][NPC]`.

### Loco_U3_Multiverso · «Las tres Valmar» — Cosme, Pip · **A · L** · Paquete 5
Hoy: tres `Portal` (anillos de 7 studs) en el parque, la plaza y la playa; al usarlos, **solo diálogo del narrador**
describiendo lo que hay al otro lado; el jugador no se mueve.
- **U3-E1 · Dimensión G-4 (gatos)**: «todo el mundo es un gato. Los coches son gatos. Las farolas son gatos. Hay un gato
  conduciendo un autobús lleno de gatos» (l. 290) → dimensión de bolsillo: copia del parque y su calle con **gatos de
  tamaño persona** paseando (rig de gato andante), coches con orejas y cola, farolas con cara de gato, un autobús con
  gatos en las ventanas. Sales «antes de que te pongan un collar».
- **U3-E2 · Dimensión V-9 (tú mandas)**: «estatuas de ti en todas las esquinas. Carteles con tu cara… todo el mundo
  lleva tu peinado» (l. 295) → copia de la plaza con estatuas (tu avatar en piedra/bronce), carteles con tu cara,
  vecinos con tu peinado, un señor arrodillado.
- **U3-E3 · Dimensión A-0 (aburrida)**: «Esta Valmar es gris… En la playa, un señor de pelo blanco muy bien peinado lee
  el periódico. Es Cosme… normal» (l. 300) → copia de la playa desaturada (filtro gris), sin colores, gente quieta, y el
  **Cosme con corbata** en una tumbona leyendo.
- **U3-E4 · Volver o quedarte con dos Cosmes**: si `DosCosmes`, **dos Cosmes en el garaje** discutiendo y «dos
  microondas explotados» (l. 312) `[PERSIST][NPC]`.
- Necesita: sistema de dimensiones de bolsillo (diseño, §5), `[ENTORNO][3D][NPC][LUZ][CAM]`.

### Loco_U4_Fiesta · «La fiesta de los cambiaformas» — Julia, Adrián, Luca, impostores · **B · M** · Paquete 6
- **U4-E1 · Fiesta en el estadio universitario**: «Música, pizza…» → hoy actores en el estadio vacío. Falta: escenario,
  luces, mesa de pizza, música `[3D][LUZ][MUS]`.
- **U4-E2 · Pistas de los impostores**: «párpados de lado a lado. Como una persiana» (l. 407), «una tercera pierna»
  debajo de la mesa (l. 411) → animación de parpadeo raro en `Impostor1-2` (cara: Decal animado) y una pierna que asoma
  bajo la mesa `[ANIM][3D]`.
- **U4-E3 · «Se convierte en un charco de gelatina azul que sale reptando hacia su nave»** → al vencerlos: el actor se
  derrite en un charco azul brillante que repta y desaparece; luz de una nave que se va `[VFX][ANIM]`.

### Loco_U5_Examen · «El examen del universo» — El Evaluador · **A · M** · Paquete 5
- **U5-E1 · «En la biblioteca el tiempo se congela. Todos quietos. Todos menos tú»** (descripción): hoy no se congela
  nada. Falta: al empezar, **todo se para** para el jugador: actores y estudiantes de la biblioteca congelados a media
  acción (animación pausada), partículas suspendidas (polvo, una taza volcada con el café en el aire), color azulado y
  desaturado, sonido ambiente cortado. `[VFX][ANIM][LUZ][SON][ENTORNO]`.
- **U5-E2 · El Evaluador** (ser que brilla con carpeta): hoy humanoide lila con brillo. Falta: figura alta (8 studs)
  translúcida con estrellas dentro, carpeta luminosa; flota `[NPC][VFX]`.
- **U5-E3 · Prueba 1: estrellas fugaces** en el techo de la biblioteca (el minijuego `Timing` con estrellas cruzando el
  techo de verdad) `[VFX]`; **Prueba 3**: lápices gigantes (rig de `Loco_A2`).
- **U5-E4 · «El tiempo vuelve a moverse… Sobre tu mesa hay un pergamino que brilla»** (l. 490) → descongelado con un
  «ding» y pergamino en la mesa `[3D][VFX]`.

---

## Saga de la Grieta, Acto III (`Saga_Acto3`)

Etapa `AdultoJoven`. Cosme ha desaparecido (`CosmeSecuestrado`). Fase del cielo `Rota`.

### Saga_13_SinCosme · «Sin Cosme» — Pip, Don Escamas, Iván, Candela · **B · S** · Paquete 4
- «El garaje de Cosme lleva meses cerrado. Pip limpia el polvo cada día… Don Escamas ha adelgazado» (descripción) →
  **estado del garaje**: persiana medio bajada, polvo en el banco (partículas al tocar), sábanas sobre los inventos,
  la bata no está, Pip con plumero; pecera con Don Escamas más delgado. `[3D][PART][PERSIST]`.
- El cuaderno de Cosme con la última página tachada (`[UI]` con la letra). El mando a medio montar que Pip termina
  (`Maquina` → mando con botones) `[3D]`.

### Saga_14_Bigotes · «El presidente Bigotes» — Bigotes, gatos policía, Iván, Candela · **A · L** · Paquete 5
- **S14-E1 · El portal a G-4 en el parque** (`Portal` existe, sin animación de apertura) → apertura en remolino verde
  `[VFX]`.
- **S14-E2 · «En esta Valmar todo es igual… pero los gatos son del tamaño de personas y las personas llevan correa»**
  (`Transition`, l. 111): hoy pantalla negra y **vuelves al mismo parque** de siempre. Falta la dimensión G-4 (la misma
  que `Loco_U3`): parque y plaza con gatos de tamaño persona, humanos con correa paseados por gatos, banderas de
  Gatonia, latas como papeleras. `[ENTORNO][NPC][3D]`.
- **S14-E3 · Gatos policía** (`GatoPolicia1-2`, humanoides marrones con uniforme) → rig de gato bípedo con uniforme y
  gorra, que acecha y salta (la sargento «Nunca persigue: acecha. Luego salta») `[NPC][ANIM]`.
- **S14-E4 · El presidente Bigotes en la plaza**: Bigotes de tamaño persona en un **cojín-trono** en un estrado con
  banderas; foto con Iván «sin flash» `[3D][NPC][VFX]`.

### Saga_15_Reestreno · «Reestreno» — Capitana Ñoz, Blorp, Zarg · **A · M** · Paquete 4
- **S15-E1 · La nave del reality vuelve al Monte** (21–5 h): ver `Loco_U1` (llegada, escalerilla).
- **S15-E2 · El plató**: «Rodaje: ¡acción!» con luz roja (minijuego) → hoy no hay plató. Falta: cámaras alienígenas
  flotantes, focos, claqueta, una luz roja de «grabando», un set de cartón de «Terrícola rescata a su vecino loco»
  delante de la nave `[3D][LUZ][ANIM]`.
- **S15-E3 · «En la pantalla: un laboratorio enorme bajo la universidad de la Valmar malvada. Una cápsula de cristal.
  Dentro, dormido, Cosme»** (l. 200) → pantalla grande en la nave que **muestra** el laboratorio de `Saga_17` (cámara
  en vivo: `ViewportFrame` del set o vídeo pregrabado) `[UI en mundo][CAM]`.

### Saga_16_66B · «Dimensión 66-B» — Tu yo malvado, Iván, Candela · **A · L** · Paquete 5
- **S16-E1 · El portal a la 66-B en el garaje** (`Portal` rojo) `[VFX]`.
- **S16-E2 · «La Valmar 66-B: el cielo es morado, las farolas se burlan de ti y en todos los balcones hay un señor con
  perilla regando plantas carnívoras»** (`Transition`, l. 232): hoy pantalla negra y teletransporte a **la plaza
  normal**. Falta la dimensión 66-B: copia de la plaza y el camino a la universidad con cielo morado (Sky + niebla
  morada), farolas con caras que se ríen (sonido de risitas al pasar), balcones con figuras con perilla y macetas con
  plantas carnívoras que muerden, palomas que roban (palomas con antifaz), semáforos que mienten (rojo y verde a la
  vez), carteles «CÓSIMO ALCALDE PARA SIEMPRE» en todas partes (hoy un `Mural` granate), grafiti «Cosme volverá».
  `[ENTORNO][3D][NPC][LUZ][SON]`.
- **S16-E3 · Tu yo malvado en un banco** (`TuMalvado`: hoy humanoide negro con brillo) → copia de tu avatar con
  perilla, ropa negra, sonrisa torcida `[NPC]`.
- **S16-E4 · La rejilla con vapor verde y música de concurso** (l. 271): hoy `Maquina`. Falta rejilla en el suelo de la
  universidad 66-B con vapor verde saliendo y, al mirar, cámara que baja por la rejilla y muestra el pasillo con neones
  «LABORATORIO DEL DR. CÓSIMO» `[3D][PART][CAM][SON]`.
- **S16-E5 · Drones de Cósimo** persiguiéndote (rig de dron, ver Acto II).

### Saga_17_Rescate · «El rescate» — Cosme, Iván, Candela, drones, robot · **A · L** · Paquete 4
- **S17-E1 · El laboratorio bajo la universidad de la Valmar malvada** (descripción: «robots, drones y un pasillo con
  música de concurso»): hoy todo pasa **en la puerta de la Facultad** (`Place = "Universidad"`). Falta: **set
  subterráneo** (acceso por la rejilla o un ascensor): pasillo con neones y aplausos enlatados, sala grande con
  máquinas, pantallas «Recuerdos extraídos: 87 %» (l. 331), cables hacia **la cápsula de cristal** con Cosme dormido
  dentro (hoy `Huevo` azul de 2,4×3,2 a 10 studs de la facultad). `[3D][LUZ][SON][MUS]`.
- **S17-E2 · La cápsula se abre con un silbido; Cosme abre los ojos y no te recuerda** (l. 329–331): vapor, cristal que
  se levanta, Cosme en zapatillas de estar por casa que se incorpora (`ANIM`), mirada perdida. Guion: 1) primer plano del
  cristal empañado; 2) silbido y vapor; 3) Cosme abre los ojos (primer plano); 4) contraplano tuyo; 5) Cosme: «¿Quién
  eres?» `[CAM][VFX][ANIM][SON]`.
- **S17-E3 · Huida con Cosme hasta el garaje** perseguidos por el dron jefe (existe `Escape`); falta salir del
  laboratorio por el portal de vuelta (`VFX`).
- Consecuencia: el garaje se **reabre** (persiana subida) y Cosme vive en él sin memoria hasta `Saga_19` `[PERSIST]`.

### Saga_18_Precio · «Todo tiene un precio» — Cosme, Pip, Cósimo (en pantallas) · **A · M** · Paquete 3
- **S18-E1 · «esta noche, en todas las pantallas de Valmar, aparece un hombre con perilla con un anuncio»**: hoy solo la
  `Pantalla` roja de 3×2 en el garaje. Falta: el anuncio de Cósimo **en todas las pantallas** del mundo visibles para el
  jugador (tele del garaje, valla de la plaza, pantallas de la bolsa en el Distrito Financiero, la del cine, las del
  metro) a la vez, con su voz por los altavoces de la calle (eco). `[UI en mundo][SON][VFX]`.
- **S18-E2 · Cosme sin memoria, sentado; «cuando te miro, el hueco se hace más pequeño»** → Cosme con gesto perdido,
  manta de Pip; foto de Candela (flash) `[ANIM][VFX]`.

---

## Rarezas de la universidad

| Id · Título | Giver · Activación | Prio · Esf. | Qué cuenta la historia | Qué hay | Qué falta | Necesita |
|---|---|---|---|---|---|---|
| **Rareza_Piso13 · El piso 13** | Candela · biblioteca | **A · M** · P5 | Botón nuevo «13» en el ascensor de una biblioteca de 3 plantas; «El ascensor sube. Y sube… música de ascensor al revés… una planta idéntica a la biblioteca, pero todo está en silencio»; mesa con exámenes del futuro; Cronos junto a la ventana | `Maquina` verde como botón; `Transition` negra que te deja **en la misma biblioteca** | Botón en el panel del ascensor real de la biblioteca (`Lift`), subida larga con música invertida, **planta 13**: copia de una planta de la biblioteca sin nadie, luz fría, sin sonido, ventanas con el cielo fijo; mesa con exámenes | `[3D][ENTORNO][SON][LUZ]` |
| Rareza_Reloj · El reloj que va hacia atrás | Pilar, Iván · residencia | **B · S** | Reloj de la entrada al revés; engranajes verdes que giran solos en la cocina y en tu cuarto | `Maquina` marrón | Reloj de pared grande en la entrada con agujas girando al revés; engranajes verdes girando; campanada normal al arreglarlo | `[3D][ANIM][SON]` |
| Rareza_Cafe · La máquina de café que da consejos | Candela, Iván · biblioteca | C · S | Papelitos con consejos; café humeante | `Maquina` marrón | Máquina de vending de café con pantalla y papelitos que salen | `[3D][PART]` |
| Rareza_Eco · El eco del estadio | Iván · estadio | C · S | El eco contesta con tu voz un año mayor; aparece un silbato | `Asiento` | Eco con retardo y tono distinto (TTS con pitch) y el silbato en la grada | `[SON][3D]` |
| **Rareza_Fotocopiadora · La fotocopiadora que copia personas** | Candela · Facultad de Ingeniería | **A · M** · P2 | «Ahora hay tres Candelas. Dos son de papel. Y se han escapado»: una lee un libro de 400 páginas, otra hace un Excel de las nubes; al doblarlas dicen «gracias» con un crujido | Las Candelas de papel son **una hoja `Papel` en el suelo** | **Candelas de papel**: copia del actor Candela en plano (grosor 0,1, textura de papel, un poco translúcida, bordes que ondean), sentada leyendo/en un portátil; al doblar: animación de plegado; fotocopiadora real con luz verde que escupe tóner | `[NPC][ANIM][VFX][3D]` |
| Rareza_Wifi · El wifi que se conecta a 1987 | Iván · residencia | C · S | Módem que pita «piiii-krrrr», pantalla verde con cursor; Marisa de 15 años escribe | `Maquina` | Módem y monitor de fósforo verde en la cocina con el chat (`[UI]` en mundo) y el sonido de módem | `[3D][UI][SON]` |

---

## Metro (`Metro_Secundarias`)

| Id · Título | Prio · Esf. | Falta |
|---|---|---|
| MetroS_PrimerDiaUni · Primer día de universidad (en metro) | C · S | Nada: el metro existe entero (`MetroKit`, `MetroService`, app del móvil) |
| MetroS_Cartera · He perdido la cartera | C · S | Debajo del banco del andén: «un billete usado, una pinza del pelo y… la marca de algo rectangular en el polvo» (l. 94) → props pequeños; ventanilla de Objetos Perdidos existe (`MetroLostOffice`) |
| MetroS_PrimerTrabajo · Primer trabajo, en transporte público | C · S | Nada |
