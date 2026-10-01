# Escenarios pendientes · 2. Adolescencia (instituto, la pandilla, misiones locas de adolescente, Acto II, rarezas)

> Parte del análisis [`escenarios-pendientes.md`](escenarios-pendientes.md). Mismas etiquetas y escala que en
> [`escenarios-1-infancia.md`](escenarios-1-infancia.md).

Índice: [Instituto](#instituto-ins01ins06) · [La pandilla de Rayo](#la-pandilla-de-rayo-pan1pan3) ·
[Consecuencias](#consecuencias-del-instituto-y-de-la-pandilla) · [Misiones locas](#misiones-locas-de-adolescente-loco_adolescente) ·
[Saga, Acto II](#saga-de-la-grieta-acto-ii-saga_acto2) · [Rarezas](#rarezas-de-adolescente)

El instituto es «el colegio grande de Campus Valmar» (`Locations.Instituto = Model Colegio, Zone Campus Valmar`):
aulas, patio, pista y comedor existen. **Ojo**: no tiene las marcas `StoryArea/StorySpot` del colegio de Los Pinos
(los lugares del instituto usan `Classroom`/`RecessArea`/`PEArea` genéricos).

---

## Instituto (Ins01–Ins06)

### Ins01_NuevoInstituto · «El nuevo instituto» — Adolescente · Omar, Leire, Javier · C · S
- Existe: parada de bus, viaje (`Traveled`), entrada, aula de 1.º C, patio.
- Falta (detalles): «Tablón de clases» = marcador → tablón de corcho con listas (Decal) `[3D]`; «una puerta que pone
  «CUARTO DE LIMPIEZA»… detrás se oyen risas» (l. 160) → puerta con cartel y risas `[3D][SON]`; Leire «siempre con una
  cámara vieja al cuello» → accesorio cámara en su actor `[3D]`.

### Ins02_Clubes · «Los clubes» — Adolescente · Álex, Rubén, Sara, Hugo, Leire · **B · S** · Paquete 6
- Existe: 5 puestos (`Kiosco` de colores), minijuegos.
- Falta:
  - **El robot Tornillo que se escapa** (l. 226–233): hoy es una **caja gris girando** en tres sitios. Robot pequeño
    (2×2×2 studs, ruedas, antena, pinza) que **corre** del aula al patio y a la pista, se choca con un cono y se para;
    unos de cuarto lo graban con el móvil (actores). `[3D][ANIM][SON]`.
  - Mural nocturno: «Un pájaro enorme de colores… purpurina» (l. 242) → Decal del pájaro en la pared del patio que
    **se queda** `[3D][PERSIST]`.
  - Evento del sábado del club elegido (l. 299–303): canasta/escena de teatro/Tornillo repartiendo un bocadillo/
    periódico «La Voz del Campus» en manos de alumnos/fotos colgadas en el pasillo → cada final con su prop
    (periódico en mano de 3 alumnos; fotos en la pared que **quedan**) `[3D][PERSIST]`.

### Ins03_QueQuieresSer · «¿Qué quieres ser?» — Adolescente · Carmen + 8 profesionales · C · S
- Todo pasa en sitios que existen (hospital, laboratorio, comisaría, oficinas, taller, cafetería, estadio, cine).
  Falta solo vestuario: bata, casco, mono de taller… (accesorios en el actor de cada profesional) `[3D]`.

### Ins04_PrimerEmpleo · «El primer empleo» — Adolescente · Lola, Paco, Ernesto · **B · S** · Paquete 6
- Existe: carteles de ofertas (`Papel`), turnos de trabajo (`JobTaskDone`).
- Falta el **percance del primer día** (l. 226–229):
  - Cafetería: «¡CRASH! Se te cae una bandeja entera. Y el cliente de la mesa es… Bruno» → bandeja con tazas que cae
    y se rompe (piezas que saltan) `[FIS][DEST][SON]`.
  - Súper: «la torre de latas de arriba se tambalea… y cae. Treinta latas rodando por el pasillo» → pila de latas con
    física que se derrumba y rueda (luego se recogen solas) `[FIS][SON]`.
  - Correos: «Abre Leire, en pijama» (de nubes) → Leire en la puerta de una casa con pijama `[NPC]`.
- «Un sobre con tu nombre» (primer sueldo) → sobre en la mano `[3D]`.

### Ins05_ElRumor · «El rumor» — Adolescente · Sara, Leire, Nico, Darío · C · S
- Falta: la **foto trucada** («la cabeza es un bocadillo gigante… «OMAR EL TRAGÓN»», l. 108) como imagen en el móvil
  (`[UI]`, captura con `ViewportFrame` o Decal); en la grada, «una pegatina del equipo de fútbol… «DR estuvo aquí»»
  (l. 150) → pegatina + pintada en el asiento `[3D]`; Omar con la capucha puesta en el banco (`Sit`, accesorio) `[3D]`.

### Ins06_LaGranDecision · «La gran decisión» — Adolescente · Carmen, Sofía, amigos · C · S
- Falta: graduación del instituto (orla, l. 216): escenario pequeño en el patio, banderines, fotógrafo; «Omar con los
  ojos cerrados. Nico saltando» → foto de grupo con esas poses (cinemática `Adol_Selectividad` ya existe) `[3D][CAM]`.
- **Atención**: si el jugador hace la Saga, `Saga_12_Graduacion` pasa en este mismo patio y el mismo día: el escenario
  de la graduación debe ser **el mismo set** (ver Saga_12).

---

## La pandilla de Rayo (Pan1–Pan3)

### Pan1_MalasCompanias · «Las malas compañías» — Adolescente · Rayo, Nerea · **B · S** · Paquete 6
- Existe: recreativos (`ArcadeService`), patio, casa.
- Falta: **el muro del parque de Rayo** («su» muro) con espray: hoy `Mural` liso. Muro de ladrillo con grafitis de la
  pandilla (Decals del *Realistic Graffiti Decoration Pack*, `assets-usuario-3.md`, solo los limpios); si pintas, tu
  firma **se queda** en el muro (`[PERSIST]`; Eco posterior: la policía la reconoce). Los cómics de Nerea (cuaderno con
  dibujos) `[3D]`.

### Pan2_LaNoche · «La noche del supermercado» — Adolescente (noche) · Rayo, Nerea, Inés, Paco · **B · M** · Paquete 6
| Acontecimiento | Existe | Falta | Necesita |
|---|---|---|---|
| «La puerta se abre con un empujón… Dentro, oscuro. Cajas. Estanterías» (l. 107) | Prop `Marcador` junto al súper | Puerta trasera del almacén del súper y **almacén interior** (estanterías de las *склад* de `assets-usuario-2.md`, cajas, latas), a oscuras | `[3D][LUZ]` |
| «¡UUUUUUUUH! La alarma. Luces rojas. Un perro ladra» (l. 121) | No | Alarma sonora, rotativos rojos en la fachada del súper, ladrido | `[SON][LUZ][VFX]` |
| «Una patrulla te para a dos calles» (l. 130) | No (teleport a comisaría) | Coche patrulla (`PoliceUnits`) que llega con sirena y te corta el paso antes del teletransporte | `[3D][ANIM][SON][CAM]` |
| «sentado en un banco de plástico» en comisaría | Actores en `Policia` | Banco de plástico en la comisaría (`Kit/PoliceStation`) | `[3D]` |
| Servicio en el punto limpio (`JobTaskDone Basurero`) | Sí | — | — |

### Pan3_Cruce · «El cruce de caminos» — Adolescente · Rayo, Nerea, Tobías · C · S
- Falta: «Rayo abre una bolsa: camisetas del Altamar» (l. 96) → bolsa y puesto improvisado (manta en el suelo con
  camisetas) a la salida del estadio de Altamar, con gente saliendo del partido (actores `Wander`) `[3D][NPC]`.

---

## Consecuencias del instituto y de la pandilla

| Id · Título | Prio · Esf. | Falta |
|---|---|---|
| Eco_Leire · Leire | C · S | La foto en blanco y negro («tú, mirando el edificio…») en el diario `[UI]` |
| Eco_LeireSola · La chica nueva | C · S | Leire **sentada sola en un banco del patio** (hoy aparece «cerca de ti» allá donde estés) `[ANIM]` |
| Eco_Carta · Una carta | C · S | La carta de recomendación en `[UI]` |
| Eco_Nico · Nico | C · S | Nada físico |
| Eco_Camaras · Llaman a la puerta | C · S | Que llamen **a la puerta de tu casa** (timbre, Inés en el porche) aunque estés fuera: hoy aparecen donde estés `[SON][NPC]` |
| Eco_Redada · La redada | C · S | Puesto de camisetas desmontado y precintado (cinta policial) en el estadio `[3D]` |
| **Eco_RayoAdulto · Rayo** | **B · S** · P6 | «Lleva la furgoneta a San Roque» (l. 96): no hay furgoneta (se cumple viajando). Furgoneta (`Van` oficial) que conduces tú de verdad; «Un control de policía. El agente es… Bruno» → conos, coche patrulla y Bruno de uniforme en la carretera del oeste `[3D][NPC][INT]` |

---

## Misiones locas de adolescente (`Loco_Adolescente`)

Cosme sale en todas (no mientras está secuestrado: `NotFlags CosmeSecuestrado`).

### Loco_A1_Futuro · «Mensajes del futuro» — Adolescente · Tú del futuro, Cronos · **B · M** · Paquete 2
- **A1-E1 · El móvil que te avisa** (l. 50–52): mensajes en el móvil `[UI]` (existe la UI del móvil: `PhoneApps`).
- **A1-E2 · Alguien con tu cara te espera junto a la fuente**: hoy `TuFuturo` es un adulto genérico con chaqueta gris.
  Falta: **copia de tu avatar** con 10 años más (ropa del jugador, ojeras, cazadora «de otro siglo», brillo lila). `[NPC]`
- **A1-E3 · «Un hombre con traje y cuarenta formularios viene corriendo. Despacito»** (l. 67): Cronos con montón de
  papeles que se le caen (partículas de hojas) `[3D][PART]`.
- **A1-E4 · «¡FLASH! Tu yo del futuro desaparece»** (l. 75): destello blanco y partículas lilas (hoy el actor solo se
  borra) `[VFX][SON]`.

### Loco_A2_Lapices · «La Dimensión Examen» — Adolescente · lápices gigantes · **A · L** · Paquete 5
- **A2-E1 · El estuche brilla**: «de tu estuche sale una luz. Y un zumbido… un remolino amarillo que huele a goma de
  borrar… el remolino te traga» (l. 117–118). Hoy `Portal` (anillo neón de 7 studs) en el aula. Falta: estuche real
  en el pupitre que se abre, luz amarilla, **remolino que crece y te absorbe** (cámara que gira y cae) `[3D][VFX][CAM][SON]`.
- **A2-E2 · «aterrizas en un instituto igual que el tuyo. Pero todo es de papel cuadriculado»** (paso `Transition`,
  l. 104): hoy pantalla negra + teletransporte **al patio de siempre**. Falta la **dimensión**: copia del patio y la
  pista del instituto con todos los materiales cambiados a papel cuadriculado (textura blanca con cuadrícula azul,
  bordes de lápiz), cielo blanco con líneas de libreta, nubes con faltas de ortografía tachadas en rojo
  (Cast `Lapiz2`: «pone faltas de ortografía a las nubes»). Ver dimensiones de bolsillo (diseño, Paquete 5).
  `[ENTORNO][3D][LUZ][MUS]`.
- **A2-E3 · Lápices gigantes que te persiguen** (`Escape` con `Lapiz1-3`): hoy humanoides amarillos con brillo. Falta
  rig de lápiz (cuerpo hexagonal de 8 studs, punta afilada, goma rosa arriba, brazos de alambre), que deja **trazos de
  grafito** al moverse y tacha el suelo `[NPC][ANIM][VFX]`.
- **A2-E4 · Despiertas en clase con la cara pegada al cuaderno… un lápiz que brilla** (l. 135): plano de despertar en el
  pupitre del aula real `[CAM][ANIM]`.

### Loco_A3_Concierto · «El concierto hipnótico» — Adolescente · DJ Zumbido, Omar, Cosme · **A · M** · Paquete 6
- **A3-E1 · El concierto gratis en la plaza** (descripción): hoy el «altavoz de DJ Zumbido» es una `Maquina` rosa y
  hay 3 bailarines. Falta: **escenario** en la Plaza del Centro (12×2×8 studs) con mesa de DJ, dos torres de altavoces,
  focos de colores, pantalla con ondas, **público bailando sincronizado** (10–15 vecinos de `Residents`/genéricos con
  ojos en espiral), y la **canción pegadiza** sonando (pista nueva en `Config.Audio.Music`). `[3D][LUZ][MUS][NPC][ANIM]`.
- **A3-E2 · Los hipnotizados**: Nico y Sara «solo dicen el estribillo» → espirales rosas sobre sus cabezas `[VFX]`.
- **A3-E3 · Los cascos anti-hipnosis**: al «ponerle los cascos» a cada fan, los cascos aparecen en su cabeza y la espiral
  se rompe en chispas `[3D][VFX]`.
- **A3-E4 · DJ Zumbido** (alien verde con gafas, hoy humanoide con brillo): al vencerle, «¡Me vuelvo a mi planeta!» →
  despega en su **cabina-nave** (el escenario se pliega y sale volando) `[ANIM][VFX][SON]`.
- Consecuencia: la plaza vuelve a la normalidad; quedan confeti y un cartel caído `[PERSIST corto]`.

### Loco_A4_Pip · «La crisis de Pip» — Adolescente · Pip, Cosme · **B · S** · Paquete 2
- **Pip, robot mayordomo**, sale en ~30 misiones (rarezas, saga, aliados) como **humanoide gris con brillo azul**.
  Falta su rig: cuerpo de robot clásico (torso de lata, cabeza con pantalla de ojos, pajarita, bandeja), ruedas o
  piernas articuladas, gestos dramáticos. `[NPC][ANIM]`.
- La misión: «Pasáis media hora dando de comer a los patos. Pip calcula la trayectoria de cada miga» (l. 306) → los
  patos del estanque existen (`Wildlife`); falta Pip sentado lanzando migas con líneas de trayectoria `[VFX][ANIM]`.
- La nota «Hay tostadas en la nevera» y la nevera del garaje `[3D]`.

### Loco_A5_Zoltan · «Zoltán, la máquina de los deseos» — Adolescente · Zoltán · **B · S** · Paquete 6
- **A5-E1 · La máquina**: «Un mago de cartón con turbante. Un letrero: ZOLTÁN CONCEDE DESEOS» → hoy `Maquina`
  morada (caja con antena). Falta **cabina de feria** (4×8×4 studs) con el mago dentro tras un cristal, bola de
  cristal que se ilumina, ranura de fichas, papel que sale `[3D][ANIM][LUZ][SON]`.
- **A5-E2 · Los fans que te siguen** (`Escape` desde casa): existen; faltan móviles en alto y flashes de foto `[VFX]`.
- **A5-E3 · «Al día siguiente, la máquina ya no está. Solo queda una marca en el suelo con forma de turbante»** (l. 383)
  → Decal quemado en el suelo de los recreativos `[PERSIST]`.

---

## Saga de la Grieta, Acto II (`Saga_Acto2`)

Etapa Adolescente. Fases del cielo: `Hilachas` (costura que se suelta) y `Rota` al final del acto.

### Saga_07_Costuras · «Las costuras se sueltan» — Adolescente · Cosme, Pip, Don Escamas · **A · M** · Paquete 3
- **S07-E1 · La credencial plastificada** con tu foto «sales fatal» → `[UI]` con tu avatar.
- **S07-E2 · «Del cielo caen hilos verdes, finísimos, como si alguien deshiciera un jersey»** (l. 76): la fase
  `Hilachas` de `SkyRift` existe (la costura se ve deshilachada); falta que **caigan** hilos hasta el suelo del parque
  (Beams verdes ondulantes de 40–80 studs) y que donde tocan el suelo «algo se mueve» → aparecen las hilachas.
  Hoy el punto 1 es `Moco` (charco). `[VFX][PART][ENTORNO]`.
- **S07-E3 · La pantalla publicitaria que nadie ve** (l. 79–80): hoy `Pantalla` de 3×2 studs. Falta valla publicitaria
  de 12×7 studs en la plaza con el anuncio animado de MegaVerso («la GRAN FUSIÓN»), que los transeúntes ignoran
  `[3D][UI en mundo][ANIM]`.
- **S07-E4 · El anclaje agrietado del patio del instituto** (l. 83): el cristal clavado en `Saga_06`… pero ese estaba en
  el **patio del colegio**; aquí se pone en el patio del instituto. Coherencia: o se usa el anclaje persistente del
  cole, o se explica. Falta cristal con grietas que zumba (vibración + sonido) `[3D][SON]`.
- **S07-E5 · Las hilachas** (`Hilacha1-2`): hoy humanoides verdes. Falta rig: bicho de hilo enredado (bola de hilos
  con patitas y ojos), que al vencerlo **se enrolla en la aguja** y cae dormido como un ovillo `[NPC][ANIM][VFX]`.

### Saga_08_MegaVerso · «MegaVerso S.A.» — Adolescente · agentes grises, robot de seguridad · **A · L** · Paquete 4
- **S08-E1 · La oficina del Consorcio** (descripción): «Moqueta gris, plantas de plástico y una recepcionista que sonríe
  sin parpadear». Lugar: `OFICINA = "OficinasFinanciero"` → `Model "Torres"` del Distrito Financiero: los props y
  actores se colocan **en la calle, delante de las torres**. No hay oficina.
  Falta: **interior de MegaVerso S.A.** (planta de oficina en una de las torres; `Interiors.Oficina` como base):
  recepción con logo grande de MegaVerso (espiral gris), moqueta gris, plantas de plástico, mostrador, puertas de
  cristal, sala con el **mapa de Valmar con chinchetas** (3 rojas tachadas en tus anclajes y una dorada en tu casa
  «ANCLA»), un ordenador con la hoja de cálculo «PROYECTO FUSIÓN». Cartel en la fachada. Material: *Modular Building
  Kit – Modern City* / *House Furniture Pack* / *Realistic Factory Props* (`modelos-oficiales-2.md`,
  `assets-usuario-3.md`). `[3D][LUZ][UI en mundo]`.
- **S08-E2 · La recepcionista que no parpadea**: `AgenteGris2` con sonrisa fija y sin parpadeo (animación facial
  ausente a propósito; giro de cabeza que te sigue) `[ANIM]`.
- **S08-E3 · Huida** (`Escape` hasta la Plaza Financiera) del robot de seguridad (humanoide gris con brillo rojo →
  rig de robot alto con luz roja giratoria) `[NPC][ANIM][LUZ]`.
- **S08-E4 · «la puerta de MegaVerso se cierra sola. En el cristal, el reflejo de un hombre con perilla sonríe un
  segundo y desaparece»** (l. 163): susto en el reflejo (Decal/actor translúcido en el cristal 1 s) `[VFX][CAM][SON]`.
- Consecuencia: el cartel de MegaVerso en la torre se ve desde la calle hasta `Saga_21` (que lo derriba) `[PERSIST]`.

### Saga_09_Archivo · «El archivo de Pip» — Adolescente (noche) · Pip, Cosme · **A · L** · Paquete 4
- **S09-E1 · La caja del archivo**: «planos del «Proyecto Costura», una bata chamuscada, una foto… y una cinta de vídeo
  «LA NOCHE»» (l. 205) → caja metálica con esos objetos al abrirla (hoy `Caja` gris) `[3D]`.
- **S09-E2 · La cinta: el flashback de la noche en que naciste** (l. 209–214) — **el momento central de la saga**, hoy
  solo texto del narrador mientras miras un `Maquina` («proyector antiguo»):
  - Visual: el proyector proyecta en la pared del garaje (rectángulo de luz parpadeante) y la cámara **entra** en la
    imagen: laboratorio escondido en el campus (el futuro Pabellón 0, ver `UniS_Pabellon0`), dos jóvenes con bata
    (Cosme y Cósimo jóvenes: actores con pelo oscuro, uno peinado), la **Cosedora Dimensional** (máquina del tamaño
    de un coche, ver Pabellón 0); brindan con batido de apio; chispazo verde, **una línea se abre en el aire** y tira
    de todo; Cósimo resbala, Cosme le agarra, **se sueltan**; Cósimo cae; la línea se hace enorme y **se frena**;
    plano que sale volando del campus hasta una casa de Los Pinos donde se enciende una luz: acaba de nacer un bebé.
  - Guion de planos (≈30 s, en tono de vídeo viejo: grano, bordes redondeados, color desvaído):
    1) 0–3 s proyector encendiéndose, polvo en el haz; 2) 3–8 s laboratorio, plano medio de los dos brindando;
    3) 8–12 s la máquina arranca, luces verdes, `Shake` creciente; 4) 12–16 s chispazo, la línea se abre, objetos
    volando hacia ella; 5) 16–20 s primer plano de las manos que se sueltan (cámara lenta); 6) 20–24 s Cósimo cae
    dentro de la luz; 7) 24–28 s plano aéreo: la línea crece sobre Valmar y se frena de golpe; 8) 28–30 s la casa
    familiar, ventana que se ilumina, llanto de bebé; fundido a negro, de vuelta al garaje.
  - Necesita: set del laboratorio (el del Pabellón 0 «nuevo», versión limpia), actores jóvenes, filtro de vídeo viejo,
    la línea/Grieta naciendo (`SkyRift` en un plano local, no el cielo del jugador), sonido de proyector, música.
    `[3D][NPC][VFX][CAM][SON][MUS]`.
- **S09-E3 · Cosme en la puerta, mirándote** (l. 195): Cosme a contraluz en la puerta del garaje `[LUZ][CAM]`.

### Saga_10_Fiesta · «La fiesta del fin del mundo» — Adolescente (18–2 h) · Omar, Nico, Sara · **A · M** · Paquete 3
- **S10-E1 · La fiesta de MegaVerso en la plaza** (descripción: «Música, confeti… y una cuenta atrás gigante»): hoy hay
  tres props pequeños (cabina `Maquina`, taquilla `Kiosco`, cuenta atrás `Pantalla` de 3×2). Falta: escenario
  corporativo gris con logo, cabina de DJ, taquilla de entradas, cañones de confeti, globos grises, **gente bailando
  «como hipnotizada»** y la **cuenta atrás gigante proyectada en el cielo** (números de luz de 30 studs sobre la plaza:
  «el día de tu graduación», l. 310). `[3D][VFX][LUZ][MUS][NPC]`.
- **S10-E2 · Cambiar la música** (l. 298): al pulsar, la música cambia a la del camión de los helados y la gente pasa
  de bailar en sincronía a bailar normal (cambio de animación de todos) `[MUS][ANIM]`.
- **S10-E3 · Atascar la taquilla**: «empieza a imprimir entradas que ponen «NO». Cientos. Miles» (l. 301) → chorro de
  papeles saliendo de la taquilla y volando por la plaza `[PART][SON]`.
- **S10-E4 · Desenchufar la cuenta atrás**: «antes de apagarse, muestra un segundo una cara con perilla» (l. 304) → la
  cara de Cósimo en los números del cielo 1 s, y se apaga `[VFX][CAM]`.
- **S10-E5 · Robot de seguridad y agentes**: ver rigs (Paquete 2).
- Consecuencia: la plaza queda llena de entradas «NO» y confeti hasta el día siguiente `[PERSIST corto]`.

### Saga_11_Cronos · «Cronos cambia de bando» — Adolescente · Cronos, Funcionaria · C · S
- Falta: formularios con el sello falsificado («Crono» sin s) en `[UI]` al revisarlos; persecución de la agente gris
  hasta el parque (existe `Chase`). Reloj de arena de Cronos como objeto `[UI]`.

### Saga_12_Graduacion · «Graduación interdimensional» — Adolescente · Cosme, Cósimo, amigos · **A · L** · Paquete 3
Activación: tras `Saga_11`, en el patio del instituto, **el día de tu graduación**. Fase del cielo pasa a `Rota`.
- **S12-E1 · Cosme ha venido «por casualidad»** con una aguja nueva en el bolsillo → aguja asomando de la bata `[3D]`.
- **S12-E2 · «La costura del cielo se rompe con un sonido de cremallera gigante»** (l. 441):
  - Hoy: cinemática `Saga_Grieta2` (`Cinematics.luau:384`) que mira al cielo con temblor y rótulo; el cielo no cambia
    hasta que acaba la misión.
  - Falta: la costura de `SkyRift` **se abre como una cremallera** de un extremo al otro (puntadas que saltan una a una
    con chispas), sonido de cremallera gigante, viento que levanta los birretes y papeles de la graduación.
- **S12-E3 · «Del agujero baja, flotando en una plataforma dorada, un hombre de pelo blanco muy peinado. Con perilla»**:
  - Hoy: el actor `Cosimo` aparece de pie en el patio.
  - Falta: **plataforma dorada** (disco de 10 studs con barandilla y luces de plató) que baja desde la Grieta con un
    foco cenital, música de concurso; Cósimo saluda como presentador. `[3D][ANIM][LUZ][MUS]`.
- **S12-E4 · Los drones de Cósimo** (`DronCosimo1-3`, humanoides negros): rig de dron volador (esfera negra con
  perilla pintada, hélices, pajarita el jefe) que **vuela** alrededor `[NPC][ANIM]`.
- **S12-E5 · «Un rayo dorado envuelve a Cosme. Intentas agarrarle de la mano… Se te escurre»** (l. 449):
  - Falta: haz dorado desde la plataforma; Cosme flota hacia arriba con los brazos tendidos; **QTE**: el jugador
    pulsa para agarrarle la mano (siempre falla: es la historia), primer plano de las manos que se separan (eco del
    flashback de `Saga_09`); Cosme y la plataforma suben y **la cremallera se cierra** (l. 453).
- **S12-E6 · «Omar recoge del suelo la bata de Cosme, chamuscada»**: bata en el suelo humeando `[3D][PART]`.
- **Guion de planos (≈20 s)**: 1) 0–3 s ceremonia, aplausos, el jugador recoge el diploma; 2) 3–6 s sonido de
  cremallera, todos miran arriba, contrapicado del cielo abriéndose (`Shake` 0,8, `Roll` −4); 3) 6–10 s la plataforma
  baja entre luces de plató, `Orbit` lento; 4) 10–13 s Cósimo saluda, plano medio, sonrisa; 5) 13–16 s rayo dorado
  sobre Cosme, Cosme sube; control al jugador para el QTE; 6) 16–18 s primer plano de las manos; 7) 18–20 s la
  cremallera se cierra, silencio, Omar con la bata.
- Necesita: `[VFX][3D][NPC][ANIM][CAM][SON][MUS][INT][ENTORNO]`.
- Consecuencias: **el garaje de Cosme cerrado** a partir de aquí (persiana bajada, polvo, Pip limpiando) hasta
  `Saga_17` `[PERSIST]`; la Grieta en fase `Rota` (existe).

---

## Rarezas de adolescente

| Id · Título | Giver · Activación | Prio · Esf. | Qué cuenta la historia | Qué hay | Qué falta | Necesita |
|---|---|---|---|---|---|---|
| Rareza_Perro · El perro que ladra en binario | Pip · zona de juegos del parque | **B · S** | Un perro ladra «guau-guau, guau»; libro de 1987; caja enterrada junto al columpio con un hueso que hace «bip» | `Animal` marrón (bloque) | Perro real (modelo de `Wildlife`/`AnimalPose.Perro`) con ladridos largos/cortos y **globo con 1 y 0**; montoncito de tierra que se excava | `[NPC][SON][UI][3D]` |
| **Rareza_Espaguetis · Lluvia de espaguetis** | Pip · Plaza del Centro | **A · M** | «Sobre la plaza está lloviendo… espaguetis. Con tomate. Los paraguas no sirven»; un agujerito de la Grieta que gotea pasta; tenedor gigante clavado; «se enrolla como un ovillo… slurp» | `Portal` beige, 3 `Moco` amarillos (charcos), `Maquina` como tenedor | **Lluvia de espaguetis** sobre la plaza (partículas de fideos que caen y se quedan en el suelo), nube/agujero verde que gotea, montones de pasta con tomate en la fuente y en un banco, **tenedor de 10 studs** clavado; al usarlo, el agujero gira y se cierra con «slurp»; deja de llover | `[VFX][PART][3D][ANIM][SON][ENTORNO]` |
| Rareza_Espejo · El espejo que contesta | Pip · tu dormitorio | **B · S** | Tu reflejo opina con tu voz; si lo tapas, habla debajo de la toalla | `Espejo` (prop) | Que **el reflejo se mueva distinto a ti** (copia de tu avatar detrás del cristal, con brazos en jarra) y una toalla que cubre el espejo si eliges taparlo | `[NPC][VFX][3D]` |
| **Rareza_Palomas · Las palomas que hacen cola** | Pip · Correos | **A · M** | «Cuarenta palomas hacen cola en Correos. Con número»; la jefa da una carta con el pico; buzón de «Otras dimensiones»; al día siguiente cae una barra de pan con lacito | `Animal` gris (una) + `Kiosco` verde | **Fila de 40 palomas** (modelo `AnimalPose.Paloma`, existe) en orden, cada una con un papelito numerado, avanzando cuando avanza la cola; buzón verde que hace «plop»; aplauso con alas; **barra de pan** que cae del cielo en la plaza al día siguiente `[PERSIST]` | `[NPC][ANIM][3D][SON][PERSIST]` |
| Rareza_Cancion · La canción que no se acaba | Pip · patio del instituto | **B · S** | Por los altavoces suena una canción de otra dimensión; nadie puede dejar de cantarla; partituras en un árbol y en un libro | `Pantalla` verde | Altavoz del patio real (bocina en un poste) brillando, notas musicales verdes flotando, alumnos cantando (actores con `Dance`/bocas), **la canción** en bucle | `[MUS][VFX][NPC]` |
| Rareza_Taquilla · La taquilla que da a otra taquilla | Pip · instituto | **B · S** | Notas con tu letra pero más inclinada; en su Valmar el mar está arriba | `Armario` verde | Taquilla real del instituto con brillo verde por las rendijas y **una nota que aparece** al abrir; al final, por la rendija se ve un trozo de **mar en el cielo** (imagen) | `[3D][VFX]` |
