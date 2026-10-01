# Escenarios pendientes · 4. Vida adulta (principales, misiones locas de adulto, Acto IV, aliados, rarezas)

> Parte del análisis [`escenarios-pendientes.md`](escenarios-pendientes.md). Mismas etiquetas y escala que en
> [`escenarios-1-infancia.md`](escenarios-1-infancia.md). Etapas `AdultoJoven`/`Adulto`.

Índice: [Principales](#misiones-principales-de-adulto) · [Misiones locas](#misiones-locas-de-adulto-loco_adulto) ·
[Saga, Acto IV](#saga-de-la-grieta-acto-iv-saga_acto4) · [Aliados](#misiones-de-aliados-aliados) · [Rarezas](#rarezas-de-adulto)

Nota común: las escenas de oficina usan `OFICINA = "OficinasFinanciero"` → `Model "Torres"`: los actores y props se
ponen **en la calle, delante de las torres** (no hay interior de oficina en la historia). Lo resuelve el set de oficina
del Paquete 4 (el mismo de MegaVerso, con otra decoración).

---

## Misiones principales de adulto

### Adu01_PrimerContrato · «Mi primer contrato» — Jefe/a según carrera o trabajo · C · S
- Existe: lugar de trabajo, banco, turnos.
- Falta: «en el buzón, tres sobres: alquiler, luz y agua» (l. 123) → **buzón de tu casa** con los sobres (prop en la
  entrada de tu vivienda, `HousingService`) `[3D]`; «Encima de ellas pones una planta» (si las dejas) → la planta encima
  de las facturas en tu mesa `[PERSIST]` (vuelven en `Eco_Factura`).

### Adu02_Atardecer · «Un atardecer junto al mar» — {abu}, Nuria, familia · **B · S** · Paquete 6
- Existe: hospital, autoescuela/bus, playa, concha (`Marcador`), cinemática `Adu02_Atardecer`.
- Falta:
  - {abu} en el hospital **en una cama/silla de ruedas** con vía (hoy `Sit` delante del modelo del hospital) `[3D][ANIM]`.
  - «{abu} se descalza y mete los pies en la arena despacito. Cierra los ojos» (l. 108) → animación y zapatos en la
    arena `[ANIM][3D]`.
  - La concha «blanca, perfecta» (hoy cubo marcador) → concha `[3D]`.
  - «El sol baja despacio» (l. 133): la cinemática debe **forzar el atardecer** para este jugador (hora local de
    `Lighting` 19:30 durante la escena, luego vuelve) y el mar con reflejo naranja `[LUZ][ENTORNO][CAM]`.
- Consecuencia: la concha en una estantería de tu casa `[PERSIST]`.

### Adu03_Reencuentro · «El reencuentro» — Omar, Lola, todo el grupo · **B · S** · Paquete 6
- Falta: «Lola se jubila y le deja la cafetería a Omar» → **cartel nuevo** de la Cafetería Central («Cafetería de Omar»
  o el nombre del grupo) que se queda `[3D][PERSIST]`; inauguración con globos y cinta; «La tortilla perfecta» (minijuego)
  con la sartén en la cocina; el banco del parque «El mismo» con todos apretados (`Sit` en el banco real).
- Recompensa `FotoReencuentro` → foto colgada dentro de la cafetería `[PERSIST]`.

### Eco_Factura · «Un aviso en el buzón» — Ignacio · C · S
- Falta: el aviso de recargo en el buzón (sobre rojo) `[3D]`.

---

## Misiones locas de adulto (`Loco_Adulto`)

### Loco_D1_Lunes · «El lunes eterno» — Montse, cafeteras · **A · M** · Paquete 2 (+ oficina del Paquete 4)
- **D1-E1 · El bucle**: «Montse… dice «¡qué lunes!» exactamente igual por cuarta vez»; «cuarenta y tres correos iguales»;
  caja de donuts que se rellena sola (l. 68–71). Falta: la oficina (ver nota común); ordenador con 43 correos (`[UI]` en
  la pantalla), **donut que reaparece** en la caja tras comerlo (`[ANIM][VFX]`); reloj de pared con «LUNES».
- **D1-E2 · La cafetera X-9000 «Fabricada en 2240»**: hoy `Maquina` oscura. Falta cafetera cromada futurista (2×3×2) con
  luces y vapor `[3D][PART]`.
- **D1-E3 · Las cafeteras villanas** (`Cafetera1-3`): hoy humanoides grises/rojos con brillo naranja. Falta rig
  «electrodoméstico con patas»: cuerpo = cafetera/cafetera de cápsulas/termo, bracitos y piernas de alambre, chorro de
  vapor al hablar; al vencerlas: «*clic*», «*glu-glu*», «*fsssss*» con vapor y se quedan quietas `[NPC][ANIM][PART][SON]`.
- **D1-E4 · «El reloj de la oficina tiembla. Las agujas giran solas. Pone: «MARTES». Toda la oficina aplaude»** (l. 79)
  → reloj animado + aplauso de todos los actores `[ANIM][SON]`.

### Loco_D2_Deuda · «La deuda galáctica» — Glub, Plof, Cosme · **B · S** · Paquete 2
- Glub y Plof «dos señores azules con sombrero» (humanoides azules con brillo: aceptable) → falta el **sombrero** y los
  sellos gigantes; la carta de embargo `[3D]`; «Romperle los sellos» → sellos que se parten `[VFX]`.
- El contrato de 3.000 páginas (tocho de papel sobre la mesa) `[3D]`.

### Loco_D3_Tostadora · «Cosme en una tostadora» — Pip, electrodomésticos · **A · M** · Paquete 2
- **D3-E1 · La tostadora con Cosme dentro** (hoy `Maquina` gris): tostadora real con una carita de Cosme en la ranura
  (Decal animado) que habla y echa humito al avergonzarse («Estoy tostando de la vergüenza»); el cuerpo de Cosme
  sentado inerte en una silla `[3D][VFX][ANIM]`.
- **D3-E2 · «salen una batidora, una aspiradora y un microondas. Con brazos. Con piernas. Con muy mala cara»** (l. 214):
  hoy humanoides blancos/grises con brillo rojo. Falta rig de electrodoméstico (ver `Loco_D1`): batidora que zumba,
  aspiradora que aspira (partículas hacia ella, tira de ti un poco), microondas que hace «¡DING!» y abre la puerta para
  morder. `[NPC][ANIM][PART][SON][FIS]`.
- **D3-E3 · El casco de transferencia mental**: casco con cables a la tostadora; «¡BZZZT! Huele a tostada quemada»
  (l. 217) → chispazo, humo, Cosme se despierta en su cuerpo `[3D][VFX][SON][ANIM]`.
- Consecuencia: la tostadora queda en el garaje (objeto `Tostadora de Cosme`) `[PERSIST]`.

### Loco_D4_Gnomos · «La noche de los gnomos» — Vecino, gnomos · **A · M** · Paquete 2
- **D4-E1 · «De madrugada se oyen pasitos en tu jardín. Y vocecitas»** (descripción): sonido de pasitos y voces al salir
  de casa de noche `[SON]`.
- **D4-E2 · Los gnomos** (`Gnomo1-3`): hoy niños con pelo rojo y brillo. Falta rig de **gnomo de jardín** de cerámica
  (1,8 studs; gorro rojo puntiagudo, barba blanca, nariz redonda, cuerpo brillante como cerámica), con «lanzas de caña de
  pescar»; el Gran Gnomo con corona y barba «de 1623». Al «darles la vuelta»: el gnomo **cae boca abajo** y se queda
  quieto como figura. `[NPC][ANIM][3D]`.
- **D4-E3 · El felpudo robado del vecino**, el vecino en pijama `[3D][NPC]`.
- Consecuencia: «tu vecino tiene su felpudo. Y un gnomo nuevo en su jardín» (l. 290) → Rigoberto (gnomo quieto) en
  **tu jardín** y uno en el del vecino `[PERSIST]`.

### Loco_D5_Malvado · «Tu yo malvado» — Tu yo malvado, familia, Cosme, Pip · **A · M** · Paquete 2
- **D5-E1 · «alguien con tu cara te abre la puerta. Lleva perilla»**: hoy `TuMalvado` es un adulto con ropa negra y
  pelo negro. Falta **copia de tu avatar** (cara, piel, peinado) con perilla postiza y ropa negra, sonrisa torcida, risa
  «Muahaha» `[NPC][ANIM][SON]`.
- **D5-E2 · Portal a la 66-B en el garaje** (rojo; existe `Portal`) con el cielo morado visible al otro lado `[VFX]`.
- **D5-E3 · «Arrancarle la perilla»**: la perilla sale volando (prop que cae) y él se sienta en el suelo «un yo triste»
  `[VFX][ANIM]`; «Cruza el portal… te dice adiós con la mano» `[ANIM][VFX]`.

---

## Saga de la Grieta, Acto IV (`Saga_Acto4`)

Etapa `Adulto`. Fases del cielo: `Inminente` → `Fusion` → `Ultima` → `Cerrada`. Lugar del clímax: `CimaMonte`.

### Saga_19_Recuerdos · «Recuerdos de tostadora» — Pip, Cosme, Julián · **B · S** · Paquete 1
- **S19-E1 · El microondas temporal reparado** → el microondas de `Loco_N1` en el banco del garaje (si existe el set
  persistente) `[3D][PERSIST]`.
- **S19-E2 · «Petra, la gallina, mira a Cosme… le da un picotazo en la rodilla»** (l. 93): hoy el prop `Gallinero` es un
  **`Huevo`** (bola) junto al granero. Falta: **Petra de tamaño normal** en su gallinero (del Paquete 1), que se acerca
  a Cosme y le pica (animación de picotazo, Cosme salta) `[NPC][ANIM][SON]`. Si el jugador no hizo `Loco_N3`, Petra está
  igual (es de la granja).
- **S19-E3 · El viejo anclaje del parque, «todavía brilla un poco»** → el cristal persistente de `Saga_06` `[PERSIST]`.
- **S19-E4 · Álbum de recuerdos** con fotos de cada sitio (`[UI]`).

### Saga_20_Aliados · «Todos los aliados» — Cosme y aliados · **B · S** · Paquete 3
- Visitas a cada aliado en su sitio (existen como actores). Falta: «Sobre el garaje pasa una nave con un cartel luminoso:
  «FINAL DE TEMPORADA · EN DIRECTO». La Capitana Ñoz saluda con las cuatro manos» (l. 190) → nave del reality pasando
  baja con un cartel luminoso colgando `[3D][ANIM][LUZ]`; Ñoz con **cuatro brazos** (rig alien) `[NPC]`.

### Saga_21_Consorcio · «La caída del Consorcio» — Candela, Iván, Glub · **A · M** · Paquete 4
- **S21-E1 · El servidor central de MegaVerso** (hoy `Maquina` de 3×3×2 en la calle de las torres): sala de servidores
  en la oficina de MegaVerso (el set de `Saga_08`): filas de racks con luces, un servidor central grande con logo, cables.
  Material: *Realistic Factory Props Pack* / estanterías *склад* (`assets-usuario-2/3.md`) `[3D][LUZ]`.
- **S21-E2 · «La pantalla se llena de números. Las cuentas… aparecen en las pantallas de toda la oficina»** (l. 236) →
  todas las pantallas del set encienden a la vez con números verdes que caen, y el pendrive con forma de pez `[UI en
  mundo][3D]`.
- **S21-E3 · Caída del Consorcio**: al final, el **cartel de MegaVerso** de la torre (de `Saga_08`) se apaga, chispea y se
  descuelga; Glub precinta la oficina con cinta azul galáctica `[DEST][VFX][PERSIST]`.

### Saga_22_Ancla · «El Ancla» — Cósimo · **B · S** · Paquete 2
- **S22-E1 · Cósimo en tu puerta, de noche, con flores**: hoy actor `Cosimo` (adulto de negro y rojo con brillo). Falta
  el ramo de **flores que muerden** (abren y cierran pétalos con dientes) `[3D][ANIM]`; Cósimo con perilla blanca y
  peinado perfecto (rig/accesorio) `[NPC]`.
- **S22-E2 · «detrás de la perilla… un hombre muy cansado. Y muy solo»** (l. 283) → gesto `Sad` y plano corto `[CAM][ANIM]`.
- Consecuencia: las flores que muerden en un jarrón de tu casa (si las aceptas) `[PERSIST]`.

### Saga_23_Fusion · «La Gran Fusión» — Cósimo, Cosme, Pip y todos los aliados · **A · L** · Paquete 3
Activación: tras `Saga_22`, de 22:00 a 4:00, en la **cima del Monte del Silencio**. Fase del cielo `Fusion`.
- **S23-E1 · «El cielo se abre como una cremallera. Dos Valmar a punto de convertirse en una»** (descripción):
  - Hoy: prop `Grieta` = `Kind = "Nave"` (¡un platillo volante!) a 26 studs sobre la cima, más la cinemática
    `Saga_Fusion` (`Cinematics.luau:400`) que gira alrededor de la cima con temblor.
  - Falta: la Grieta de `SkyRift` **abriéndose de verdad** encima del monte (se ensancha hasta ocupar medio cielo), y a
    través de ella **la Valmar 66-B al revés** (el cielo morado con la silueta de la ciudad colgando boca abajo, como un
    reflejo), rayos verdes entre las dos ciudades, viento que arrastra hojas hacia arriba.
  - `[VFX][ENTORNO][LUZ][SON][MUS]`.
- **S23-E2 · La máquina de la Fusión** (nombrada en l. 384: «La máquina de la Fusión se apaga»): **no existe ni como
  prop**. Falta: torre de 20 studs en la cima con brazos que apuntan a la Grieta, anillos que giran y un haz al cielo;
  plataforma de Cósimo (la dorada de `Saga_12`). `[3D][ANIM][VFX]`.
- **S23-E3 · Todos tus aliados a tu espalda** (`ALIADOS`, l. 34–43): existen como actores; faltan sus rigs (gatos, Rex,
  Pérez, gnomos, Ñoz…) — dependen del Paquete 2.
- **S23-E4 · «¡La Grieta tira de ti! Aguanta 25 segundos»** (`Escape` con `Seconds = 25`): falta la **fuerza** visible:
  partículas y objetos que vuelan hacia la Grieta, el jugador empujado (fuerza suave hacia el centro, `VectorForce`),
  drones que te empujan `[FIS][VFX][SON]`.
- **S23-E5 · Los Restos de la Grieta se encienden** (l. 368): «Las cosas raras que arreglaste por Valmar se encienden a la
  vez» — la farola que canta, el tenedor, el sello, la chapa de Pip… → **en toda la ciudad**, cada objeto de las
  rarezas que hiciste lanza un haz de luz verde hacia la cima (se ven desde allí como columnas en el horizonte), y los
  objetos de tu mochila brillan en `[UI]`. Requiere que las rarezas dejen su objeto **en el mundo** (`[PERSIST]`).
  `[VFX][PERSIST][CAM]`.
- **S23-E6 · Cósimo en persona** (pelea con `HP` 6 o 10): «¿Por qué me pesan las piernas?» → Cósimo frenado por hilos de
  luz que salen de los Restos; al rendirse «Se deja caer de rodillas. No desaparece» (hoy `Bye` lo hace desaparecer entre
  chispas: **contradice el texto**) → animación de rodillas y se queda `[ANIM]`.
- **S23-E7 · Perdón entre Cosme y Cósimo** (diálogo `Rendicion`): plano a dos con la Grieta detrás `[CAM]`.
- **Guion de planos de la apertura (≈15 s)**: 1) 0–3 s el jugador llegando a la cima con los aliados detrás (plano
  dorsal); 2) 3–6 s contrapicado: la Grieta se abre como cremallera con chispas, `Shake` 1,0; 3) 6–10 s `Orbit` alto
  mostrando la Valmar invertida a través de la Grieta; 4) 10–12 s la máquina de la Fusión se enciende (anillos); 5) 12–15 s
  la plataforma dorada baja con Cósimo, foco cenital, rótulo «LA GRAN FUSIÓN».
- Consecuencias: si `Saga_23` termina, la máquina queda **apagada y rota** en la cima `[PERSIST]` hasta `Saga_24`.

### Saga_24_Final · «Coser el cielo (de verdad)» — Cosme, Cósimo, Iván, Candela, Pip · **A · M** · Paquete 3
- **S24-E1 · La Cosedora Dimensional v2 en el garaje** (hoy `Maquina` de 3×3×2): máquina grande (≈8×6×5 studs), mezcla de
  la del Pabellón 0 y piezas nuevas; Cosme y Cósimo discutiendo una pieza «al revés» `[3D][ANIM]`.
- **S24-E2 · En el patio del cole, «donde clavaste el primer anclaje»**: el anclaje persistente de `Saga_06` `[PERSIST]`.
- **S24-E3 · «La aguja sube. Cosme cose desde un lado. Cósimo, desde el otro. Tú sujetas el hilo en el centro»** (l. 433):
  - Hoy: cinemática `Saga_Final` (orbita el patio) y la fase pasa a `Cerrada` al terminar.
  - Falta: la aguja (dorada) que sube; **dos hilos de luz** desde Cosme y Cósimo hasta la Grieta y uno desde el jugador
    (que sujeta: animación de tirar); la Grieta se cierra punto a punto **desde los dos extremos** hacia el centro; el
    último punto: «un sonido pequeño, como un botón que encaja»; el cielo **queda limpio** (sin costura) y amanece (luz
    dorada).
  - Guion (≈14 s): 1) plano de los tres en el patio con los hilos; 2) cámara sube por el hilo del jugador hasta el cielo;
    3) plano general: las dos costuras avanzando; 4) primer plano del último punto (clic); 5) el cielo limpio, `Orbit`
    lento con el amanecer; 6) rótulo «La Grieta se cierra».
  - `[VFX][CAM][LUZ][ENTORNO][SON][MUS]`.
- Consecuencias: cielo sin Grieta (fase `Cerrada`, existe); Cosme y Cósimo trabajando juntos en el garaje (dos actores
  con rutina) `[PERSIST][NPC]`; se limpia la mancha de hollín del garaje (`Loco_N1`).

---

## Misiones de aliados (`Aliados`)

Requisitos: etapa universidad o más (`UNI_O_MAS`) y su misión de origen. Todos vuelven en `Saga_23`.

| Id · Título | Giver · Activación | Prio · Esf. | Qué cuenta / qué falta | Necesita |
|---|---|---|---|---|
| **Aliado_Bigotes · La visita de Estado** | Bigotes · parque | **B · M** · P2 | «te espera al final de la alfombra» → falta **alfombra roja**, estrado y banderas de Gatonia en el parque, guardia de gatos policía (rig de gato), el **portal a Gatonia** abierto (existe anillo), la nave de cucarachas (ver `Loco_N2`); manguera con chorro de agua real (`[VFX]`); la Banda de Canciller | `[3D][NPC][VFX]` |
| **Aliado_Rex · Rex, abogado del Ancla** | Rex · Facultad de Derecho | **B · M** · P4 | Un juicio («En la sala, alguien aplaude flojito», l. 155) en la puerta de la facultad → **sala de juicio** (aula magna de Derecho: estrado, bancos, mazo); Rex con toga; agente gris en el banquillo; el folleto con letra pequeñísima (`[UI]` con zoom); la caja de fotos de bebé y la partida de nacimiento | `[3D][NPC][UI]` |
| Aliado_Perez · La muela del juicio | Ratón Pérez · casa (noche) | C · S | Igual que `Loco_N5` (rig del ratón); el saco de dientes; un brazo de traje gris que entra por la ventana (l. 203) `[ANIM]` | `[NPC][ANIM]` |
| Aliado_Cronos · El expediente de Cronos | Cronos · Correos | C · S | Ventanilla 42 (hoy `Kiosco` verde) → ventanilla real de Correos con cartel 42; «Suena una campana. Alguien llora de la emoción» (l. 274) `[SON]`; la Inspectora del Tiempo con lupa | `[3D][SON][NPC]` |
| **Aliado_Noz · Final de temporada** | Capitana Ñoz · Monte (21–5 h) | **B · S** · P4 | «una cámara alienígena flota a tu lado» (l. 344) → cámara flotante que te sigue (hoy `Pantalla` en el suelo); la nave del reality; tomas en la plaza y la playa; «La cámara hace zoom. Tanto zoom que se cae a la arena» | `[3D][ANIM]` |
| **Aliado_Gnomos · El consejo de los jardines** | Rigoberto · casa (22–5 h) | **B · S** · P2 | «gnomos de plástico con cámaras» → hoy `Trofeo` rojo (copa dorada). Falta gnomo de plástico (rig de gnomo quieto, brillo plástico) con lucecita roja en el gorro que parpadea y se apaga al quitar la cámara; el consejo de gnomos en tu jardín | `[3D][LUZ][NPC]` |
| **Aliado_Malvado · Clases de ser bueno** | Tu yo (ex)malvado · plaza | **B · S** · P6 | Cartera en el suelo (hoy `Llavero`), **gato en un árbol** (hoy gato en el suelo: subirlo a una rama de un árbol real del parque), banco con pintadas «CÓSIMO ALCALDE» y «MUAHAHA» (hoy `Banco` limpio) que se limpian frotando (Decal que se desvanece); tu yo sin perilla (copia del avatar) | `[3D][VFX][NPC]` |

---

## Rarezas de adulto

| Id · Título | Giver · Activación | Prio · Esf. | Qué cuenta | Qué hay | Qué falta | Necesita |
|---|---|---|---|---|---|---|
| Rareza_Semaforo · El semáforo con opiniones | Pip · Plaza Financiera | **B · S** | Un semáforo opina en voz alta y no se pone en verde; atasco | `Maquina` roja de 3×3 | Que hable **un semáforo real** del cruce (`TrafficSignals`): cara en el disco, coches parados en cola (tráfico local) que arrancan al ponerse verde; «Te guiña el ámbar» | `[VFX][ANIM][SON]` |
| **Rareza_Nube · La nube que te sigue** | Pip · casa | **A · S** | «Hay una nube pequeñita que te sigue a todas partes. Solo llueve sobre ti» | `Cristal` blanco **en la playa** (solo aparece al final) | Nube de 4 studs que flota sobre la cabeza del jugador **durante toda la misión** (va con él), lluvia solo encima, charquito a sus pies, `Wet` local; en la playa se une a un banco de nubes | `[VFX][PART][SCRIPT]` |
| Rareza_Contestador · El contestador de 1999 | Pip, familia · casa | C · S | Mensaje de voz de tu familia de cuando eras bebé | `Pantalla` | Móvil en `[UI]` con la nota de voz y la voz joven (TTS con otro pitch) | `[UI][SON]` |
| Rareza_GatoCaja · El gato que está y no está | Pip · supermercado | **B · S** | Un gato dentro de una caja y el mismo fuera, a la vez; al abrir, dos gatos se miran y queda uno | `Caja` + `Gato` | Gato fuera **y** gato dentro (la caja medio abierta), parpadeo translúcido entre los dos; al abrir: dos gatos, uno bosteza, el otro se ofende, uno se desvanece | `[NPC][VFX][ANIM]` |
| Rareza_Lavadora · La lavadora multiversal | Pip · cocina | C · S | Calcetines de otras dimensiones (uno con perilla, uno de gato, uno que canta); pinza verde | `Maquina` blanca | Lavadora real de tu cocina con brillo verde girando; calcetines raros en el cesto | `[3D][VFX]` |
| Rareza_Cajero · El cajero que da minutos | Pip · banco | C · S | Billetes de «10 minutos»; el reloj del banco se para; cola que da la vuelta a la manzana | `Pantalla` verde | Cajero real del banco con billete verde, reloj del banco parado; cola de vecinos fuera (actores `Wander` en fila) | `[3D][NPC]` |
