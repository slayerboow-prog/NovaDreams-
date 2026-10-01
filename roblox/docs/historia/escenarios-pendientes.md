# Escenarios pendientes: que la historia se vea

> Fecha: 2026-10-01. Análisis (sin cambios de código) pedido por el dueño:
> «Me encantan los diálogos, pero todo es ficticio: no hay nada gráfico que se vea de la historia. Por ejemplo, la
> gallina gigante que pone huevos de 6 metros: el granero es enano, no se puede entrar, no se ve ninguna gallina gigante
> ni ningún huevo gigante. Todas las misiones del juego hay que crearlas y representarlas gráficamente.»
> Regla ampliada: **si sucede en la historia, el jugador tiene que poder verlo, escucharlo o experimentarlo.**

## Documentos

| Documento | Qué contiene |
|---|---|
| **Este** | Diagnóstico, tabla resumen de las 137 misiones ordenada por prioridad, recuento y paquetes |
| [`escenarios-1-infancia.md`](escenarios-1-infancia.md) | Prólogo, colegio, consecuencias del cole, misiones locas de niño (incluida **la gallina de seis metros**, ficha completa), Saga Acto I, rarezas de niño |
| [`escenarios-2-adolescencia.md`](escenarios-2-adolescencia.md) | Instituto, la pandilla de Rayo, misiones locas de adolescente, Saga Acto II, rarezas |
| [`escenarios-3-universidad.md`](escenarios-3-universidad.md) | Residencia, universidad, secundarias, misiones locas, Saga Acto III, rarezas, metro |
| [`escenarios-4-adulto.md`](escenarios-4-adulto.md) | Vida adulta, misiones locas de adulto, Saga Acto IV, aliados, rarezas |
| [`escenarios-5-diseno-implementacion.md`](escenarios-5-diseno-implementacion.md) | Sistemas que ya hay, arquitectura en Luau (secuenciador de acontecimientos, VFX, rigs, sets, memoria del mundo, dimensiones), formato de datos, conexión con las misiones, rendimiento, **plan por fases** e inventario |

Cada acontecimiento importante tiene una **ficha**: historia (cita y línea del código) → evento y fase → visual →
objetos/NPC (y si existen) → animaciones (con emociones) → efectos → sonido/música → cinemática (guion de planos en los
grandes) → interacción → consecuencias persistentes → qué necesita (`[3D]`, `[NPC]`, `[ANIM]`, `[PART]`, `[LUZ]`,
`[SON]`, `[MUS]`, `[VFX]`, `[CAM]`, `[UI]`, `[FIS]`, `[DEST]`, `[ENTORNO]`, `[INT]`, `[PERSIST]`, `[SCRIPT]`).
Los detalles menores van en tablas compactas.

**Prioridad**: **A** = la misión no tiene sentido sin eso o el jugador lo busca y no está · **B** = se nota · **C** = detalle.
**Esfuerzo** (con el motor del Paquete 1 hecho): **S** < 1 día · **M** 2–4 días · **L** ≥ 1 semana.

---

## Diagnóstico (lo que se repite en todas las misiones)

Fuentes revisadas: las 47 `Misiones/*.luau` (**137 misiones**), `Locations`, `Cast`, `Cinematics`, `StoryContext`,
`Memories`, `SchoolLife`, `Quests`, `docs/historia/*.md`, `LifeStoryService`, `SceneService`, `CinematicService`,
`InteriorService`, `FarmService`, `World/Kit/*` (`Civic`, `Home`, `Wilds`, `DreamIsland`, `StoryMarks`), `SkyRift`,
`Wildlife`/`AnimalPose` y los documentos de assets (`modelos-tienda*.md`, `modelos-oficiales-2.md`, `assets-usuario*.md`).

1. **Los objetos de las misiones son 30 primitivas pequeñas** (`SceneService.BUILDERS`, `SceneService.luau:749-990`):
   el huevo gigante es una bola de 2,4×3,2 studs (≈0,9 m); una «máquina» es una caja de 3×3×2 con antena (sirve de
   microondas, tostadora, farola que canta, semáforo, servidor, Cosedora Dimensional, máquina de Zoltán…); el tractor es
   un cubo rojo de 2×2×2; las guirnaldas, la concha y las latas son un cubo-marcador amarillo; la hoguera y la nube son
   un `Cristal`; las Candelas de papel son una hoja en el suelo; **«La Grieta abierta» de la Gran Fusión es un platillo
   volante** (`Kind = "Nave"`).
2. **Todas las criaturas son personas R15 pintadas** (`SceneService.buildModel`, l. 297): Petra la gallina, Bigotes
   el gato, Don Escamas el pez, Don Pinzas el cangrejo, Rex el velocirraptor, las cucarachas, las palomas robot, el
   Ratón Pérez, los lápices gigantes, las cafeteras, los gnomos, los drones, Pip el robot… solo cambian colores, escala y
   un brillo. Y al vencerlos siempre «suben y desaparecen entre chispas» (`defeat`, l. 1574), aunque el texto diga que
   Petra encoge y vuelve al gallinero o que Cósimo se queda de rodillas.
3. **Las otras dimensiones son una pantalla negra con texto** (`Transition`) que te devuelve **al mismo sitio** de
   siempre: la Dimensión Examen de papel, la G-4 de los gatos, la 66-B morada, el columpio al pasado, el piso 13. En
   `Las tres Valmar` ni siquiera te mueves: lo cuenta el narrador.
4. **Las cinemáticas de la saga miran al cielo, pero en el cielo no pasa nada**: `Saga_Coser`, `Saga_Grieta2`,
   `Saga_Fusion`, `Saga_Final` (`Cinematics.luau:365-430`) mueven la cámara con temblor y un rótulo; no hay aguja que
   cosa, cremallera que se abra, plataforma dorada, rayo que se lleve a Cosme ni apagón. La Grieta (`SkyRift`) sí existe
   y cambia de fase por jugador, pero **de golpe al completar** la misión.
5. **Faltan lugares con interior que la historia da por hechos**: el **granero** (26×20×10 studs, `Interior = false`,
   `Civic.luau:786-791`), la **habitación 214 y la cocina compartida de la residencia** (sus marcas no existen y la
   historia cae en la acera: 12 misiones), la **oficina de MegaVerso** (las escenas pasan en la calle de las torres), el
   **laboratorio bajo la universidad**, el **Pabellón 0**, el **piso de Adrián**, la **sala de juicio**.
6. **Nada queda en el mundo después**: ni Petra en el gallinero, ni los anclajes que clavaste, ni el garaje cerrado
   cuando secuestran a Cosme, ni Rex viviendo en tu casa, ni los objetos de las rarezas (que la Gran Fusión dice que
   «se encienden a la vez» por toda la ciudad). Lo único persistente visible es la fase de la Grieta.
7. **Lo que sí está bien y sirve**: el motor de escenas por jugador, las persecuciones y peleas, las cinemáticas con
   planos/temblor/zoom/voz, los diálogos con voz sintetizada y gestos por emoción (`ActorLife`/`Emotion`), la Grieta
   procedural, la isla del sueño (patrón para dimensiones), el colegio y la casa con marcas de historia, la granja con
   fincas, los animales del cliente (hay una gallina de verdad en `AnimalPose`), los efectos marinos (patrón para VFX),
   temblor de cámara, interiores de todos los edificios, el metro. Ver §1 del documento de diseño.

> **Trabajo en curso detectado al cerrar este análisis** (cambios de otro agente aún sin commit en la rama):
> `World/Kit/GranjaJulian.luau` (la granja de Julián: granero grande en el que se entra, silo, gallinero), la granja
> de la historia fijada con el atributo `Julian` en `Locations` (`Granja`, `GranjaGranero`, `GranjaSilo`, y nuevas
> marcas `GranjaPatio`, `GranjaNido`, `GranjaComedero`), un traje de gallina para Petra (`Kit/GallinaGigante`,
> `Cast.Body = "GallinaGigante"` en `SceneService.buildModel`) y un prop `HuevoGigante` de 7,2 studs con «NO TOCAR».
> Es justo el **Paquete 1**: este documento describe el estado **antes** de esos cambios; al integrarlos, revisar la
> ficha de `Loco_N3_Pollo` (infancia) para tachar lo hecho y seguir con lo que quede (encoger por golpes, Petra normal
> persistente, desastre de la granja, furgoneta, excursión, `Saga_19`).

---

## Recuento

| Prioridad | Misiones | Elementos que faltan (aprox.) |
|---|---|---|
| **A** | **41** | ≈ 150 (acontecimientos con ficha completa, rigs de los protagonistas no humanos, decorados sin los que la misión no se entiende) |
| **B** | **42** | ≈ 110 (objetos que hoy son un cubo, fiestas y ceremonias sin escenario, pequeños sucesos que se cuentan pero no se ven) |
| **C** | **54** | ≈ 70 (detalles: sonidos, accesorios, carteles, objetos en la mochila) |
| **Total** | **137** | ≈ 330 elementos, que se reducen a **8 sistemas, ≈ 22 decorados, ≈ 60 objetos, ≈ 22 rigs, 6 dobles, ≈ 40 recetas VFX y ≈ 35 estados persistentes** (inventario en el doc 5, §8) |

Por etapa: infancia 37 misiones (A 10 · B 9 · C 18), adolescencia 33 (A 9 · B 12 · C 12), universidad 39
(A 14 · B 8 · C 17), adulto 28 (A 8 · B 13 · C 7).

---

## Tabla resumen (ordenada por prioridad)

Etapa: N = niño · Ad = adolescente · U = universidad (adulto joven) · A = adulto. «Paq.» = paquete de trabajo (abajo).

### Prioridad A (41)

| Misión | Etapa | Qué falta (resumen) | Prio | Esf. | Paq. |
|---|---|---|---|---|---|
| `Loco_N3_Pollo` · La gallina de seis metros | N | Granero grande con interior (44×32×30 studs) y nido; huevo de 6,5 studs dentro; **Petra = gallina de 21 studs** (hoy persona escalada ×2,4); desastre en la granja (plumas, huellas, gallinero roto); furgoneta que vuela; encoger por golpes; Petra normal en el gallinero después | A | L | 1 |
| `Loco_N1_Cosme` · El vecino del garaje | N | Explosión con humo verde y Cosme con hollín; microondas reconocible que hace «ding»; destello de dinosaurios; **el momento** en que se ve la raja del cielo | A | M | 3 |
| `Saga_05_Perdidas` · La noche de las cosas perdidas | N | Remolino de objetos de toda la ciudad hacia la Grieta y cascada en el gimnasio; montaña de cosas perdidas; Monstruo de calcetines de verdad | A | L | 3 |
| `Saga_06_Coser` · Coser el cielo | N | Anclajes que lanzan hilos de luz al cielo; **la aguja que cose la Grieta**; apagón de Valmar; voz desde la costura; anclajes persistentes | A | L | 3 |
| `Saga_07_Costuras` · Las costuras se sueltan | Ad | Hilos verdes que caen al suelo; valla publicitaria de MegaVerso; anclaje agrietado; hilachas con forma de hilo | A | M | 3 |
| `Saga_10_Fiesta` · La fiesta del fin del mundo | Ad | Fiesta corporativa en la plaza (escenario, DJ, taquilla); **cuenta atrás gigante en el cielo**; entradas «NO» volando; cara de Cósimo | A | M | 3 |
| `Saga_12_Graduacion` · Graduación interdimensional | Ad | Graduación con escenario; **la costura se abre como cremallera**; plataforma dorada con Cósimo; rayo que se lleva a Cosme (QTE de la mano); bata en el suelo; garaje cerrado después | A | L | 3 |
| `Saga_18_Precio` · Todo tiene un precio | U | El anuncio de Cósimo **en todas las pantallas** de Valmar a la vez | A | M | 3 |
| `Saga_23_Fusion` · La Gran Fusión | A | La Grieta abriéndose sobre la cima (hoy es un platillo volante); Valmar invertida al otro lado; **máquina de la Fusión** (no existe ni como prop); tirón hacia la Grieta; Restos de la Grieta encendiéndose por la ciudad; Cósimo de rodillas (no desaparece) | A | L | 3 |
| `Saga_24_Final` · Coser el cielo (de verdad) | A | Cosedora v2; dos costuras de luz desde los extremos y el jugador sujetando el hilo; último punto; cielo limpio y amanecer | A | M | 3 |
| `Loco_N2_Bigotes` · Bigotes, emperador de Gatonia | N | La nave **aterriza** (furgoneta, no platillo de 22 studs); cucarachas espaciales de verdad; globos de agua con arco y salpicadura | A | M | 2 |
| `Loco_N4_Clones` · Deberes clónicos | N | Tres clones **con tu cara y tu ropa** que aparecen con «¡PLOP!» en tu cuarto; duermen en tu cama; «*pop*» al deshacer | A | M | 2 |
| `Loco_N5_Perez` · La huelga del Ratón Pérez | N | Ratón de 1,2 studs que sale de debajo de la cama a la luz de la linterna; rata con antifaz que entra y sale por la ventana | A | M | 2 |
| `Loco_N6_Tirachinas` · El tirachinas del campeón | N | Palomas robot que **vuelan** y roban bocadillos (hoy niños grises); baúl que se abre; latas que caen | A | M | 2 |
| `Saga_03_Pez` · El pez que sabía demasiado | N | Pez con corbata que asoma del estanque y viaja en un cubo (hoy niño naranja ×0,35); agentes que aparecen sonriendo a la vez; pecera persistente | A | M | 2 |
| `UniS_Playa` · Día de playa | U | **Cangrejo del tamaño de un coche** que sale del mar con corbata y maletín (hoy persona roja ×2); castillos de arena | A | M | 2 |
| `Loco_U2_Rex` · Mi compañero de piso es un dinosaurio | U | **Velocirraptor** con camisa (hoy persona verde); zarpazos en tu sofá; Rex viviendo en tu casa | A | M | 2 |
| `Rareza_Fotocopiadora` · La fotocopiadora que copia personas | U | Candelas **de papel** (copias planas que leen y hacen un Excel) que se doblan al cogerlas | A | M | 2 |
| `Loco_D1_Lunes` · El lunes eterno | A | Cafeteras villanas con patas; donut que reaparece; reloj que pasa a «MARTES»; oficina de verdad | A | M | 2 |
| `Loco_D3_Tostadora` · Cosme en una tostadora | A | Tostadora con la cara de Cosme; batidora, aspiradora y microondas con brazos y piernas; casco con chispazo | A | M | 2 |
| `Loco_D4_Gnomos` · La noche de los gnomos | A | Gnomos de jardín de cerámica (hoy niños pelirrojos) con lanzas de caña; caen boca abajo; Rigoberto en tu jardín | A | M | 2 |
| `Loco_D5_Malvado` · Tu yo malvado | A | Tu yo malvado **con tu cara** y perilla; perilla que sale volando; portal con cielo morado | A | M | 2 |
| `Uni01b_Residencia` · La residencia | U | **Habitación 214 y cocina compartida** (hoy no existen: todo pasa en la acera de la residencia); afecta a 12 misiones | A | M | 4 |
| `UniS_Pabellon0` · El pabellón que no sale en los mapas | U | **El Pabellón 0** (edificio abandonado entre árboles con puerta tapiada) y dentro la Cosedora Dimensional bajo una sábana, la pizarra, la foto (hoy todo al aire libre) | A | L | 4 |
| `Loco_U1_Monte` · La luz del Monte del Silencio | U | Estrellas que se apagan; la nave que llega con escalerilla; abducidos en pijama bajando por el haz; despegue «piuuu»; círculo quemado | A | M | 4 |
| `Saga_08_MegaVerso` · MegaVerso S.A. | Ad | **Interior de la oficina** del Consorcio (recepción, moqueta gris, mapa con chinchetas, ordenador); robot de seguridad; reflejo de Cósimo en el cristal | A | L | 4 |
| `Saga_09_Archivo` · El archivo de Pip | Ad | **Flashback de «La noche»** (≈30 s): laboratorio, Cosme y Cósimo jóvenes, la Cosedora, la línea que se abre, las manos que se sueltan, tu nacimiento | A | L | 4 |
| `Saga_15_Reestreno` · Reestreno | U | Plató alienígena junto a la nave; pantalla que muestra el laboratorio con Cosme en la cápsula | A | M | 4 |
| `Saga_17_Rescate` · El rescate | U | **Laboratorio subterráneo** de Cósimo (pasillo de neones, pantallas «87 %», cápsula de cristal que se abre con vapor) | A | L | 4 |
| `Saga_21_Consorcio` · La caída del Consorcio | A | Sala de servidores de MegaVerso; todas las pantallas con las cuentas; cartel de MegaVerso que cae | A | M | 4 |
| `Loco_A2_Lapices` · La Dimensión Examen | Ad | Remolino que sale del estuche; **instituto de papel cuadriculado** (hoy vuelves al patio normal); lápices gigantes que tachan | A | L | 5 |
| `Loco_U3_Multiverso` · Las tres Valmar | U | Visitar de verdad la Valmar de los gatos, la de tus estatuas y la gris con el Cosme normal (hoy solo texto); dos Cosmes en el garaje | A | L | 5 |
| `Loco_U5_Examen` · El examen del universo | U | **El tiempo se congela** en la biblioteca (todos quietos, café en el aire); el Evaluador; estrellas fugaces en el techo | A | M | 5 |
| `Saga_14_Bigotes` · El presidente Bigotes | U | **Dimensión G-4**: gatos de tamaño persona, humanos con correa, presidente en su trono-cojín (hoy vuelves al parque de siempre) | A | L | 5 |
| `Saga_16_66B` · Dimensión 66-B | U | **Valmar malvada**: cielo morado, farolas que se burlan, perillas en los balcones, plantas carnívoras, carteles de Cósimo; rejilla con vapor verde | A | L | 5 |
| `Rareza_Piso13` · El piso 13 | U | Botón 13 en el ascensor real; planta 13 silenciosa e idéntica (hoy vuelves a la misma biblioteca) | A | M | 5 |
| `Loco_A3_Concierto` · El concierto hipnótico | Ad | **Escenario de DJ** en la plaza con público hipnotizado y la canción; cascos que aparecen; cabina-nave que despega | A | M | 6 |
| `Rareza_Espaguetis` · Lluvia de espaguetis | Ad | **Lluvia de espaguetis** sobre la plaza, montones con tomate, tenedor gigante que enrolla el agujero | A | M | 6 |
| `Rareza_Palomas` · Las palomas que hacen cola | Ad | **Cuarenta palomas en fila con número** en Correos (hoy un bloque gris); barra de pan que cae al día siguiente | A | M | 6 |
| `Rareza_Sombra` · La sombra que se escapa | N | **No hay nada**: falta tu sombra como silueta que corre y que tu personaje deje de hacer sombra | A | M | 6 |
| `Rareza_Nube` · La nube que te sigue | A | Nube que te sigue toda la misión y solo llueve sobre ti (hoy aparece al final en la playa) | A | S | 6 |

### Prioridad B (42)

| Misión | Etapa | Qué falta (resumen) | Prio | Esf. | Paq. |
|---|---|---|---|---|---|
| `Cole07_Excursion` · La excursión | N | Gallinas, caballos, tractor y huerto de verdad (hoy bloques y un cubo rojo); zanahoria gigante; corderito que os sigue; autobús en la carretera | B | M | 1 |
| `Saga_19_Recuerdos` · Recuerdos de tostadora | A | Petra normal en el gallinero que pica a Cosme (hoy el «gallinero» es una bola); microondas y anclaje persistentes | B | S | 1 |
| `Side_GatoDelCole` · El gato del colegio | N | Los **tres gatitos**; rastro de huellas y pelito en la valla | B | S | 2 |
| `Loco_A1_Futuro` · Mensajes del futuro | Ad | Tu yo del futuro **con tu cara** y 10 años más; formularios que se le caen a Cronos; ¡FLASH! al desaparecer | B | M | 2 |
| `Loco_A4_Pip` · La crisis de Pip | Ad | **Pip con forma de robot** (sale en ~30 misiones); trayectorias de migas a los patos | B | S | 2 |
| `Rareza_Perro` · El perro que ladra en binario | Ad | Perro real con ladridos largos/cortos y 1/0 en un globo; caja enterrada | B | S | 2 |
| `Loco_D2_Deuda` · La deuda galáctica | A | Sombreros de los cobradores, sellos gigantes que se rompen, contrato de 3.000 páginas | B | S | 2 |
| `Saga_22_Ancla` · El Ancla | A | Flores que muerden; Cósimo con su perilla y peinado; plano de hombre cansado | B | S | 2 |
| `Aliado_Bigotes` · La visita de Estado | A | Alfombra roja, estrado y banderas de Gatonia, guardia de gatos, manguera con chorro | B | M | 2 |
| `Aliado_Gnomos` · El consejo de los jardines | A | Gnomos de plástico con cámara y lucecita roja (hoy copas doradas); consejo en tu jardín | B | S | 2 |
| `Rareza_GatoCaja` · El gato que está y no está | A | Dos gatos a la vez que parpadean; uno se desvanece al abrir | B | S | 2 |
| `Saga_02_Grieta` · La grieta en el cielo | N | Cosas que **caen** de la Grieta con cráter humeante; calcetín que habla, paraguas con lluvia hacia arriba, moneda humeante | B | M | 3 |
| `Saga_20_Aliados` · Todos los aliados | A | Nave del reality pasando con cartel luminoso; Ñoz con cuatro brazos | B | S | 3 |
| `UniS_Zumo` · La guerra del zumo de mora | U | Cocina y habitación; cinta aislante en el suelo; huellas moradas en zigzag | B | S | 4 |
| `UniS_Fiesta` · Fiesta en casa de Adrián | U | **El piso de Adrián** (hoy la fiesta es en la puerta de la cafetería); twist del vecino | B | M | 4 |
| `UniS_Acampada` · Acampada en el monte | U | Tienda que se monta, hoguera real, zarzal con moras brillantes, Blorp flotando bajo la luz | B | M | 4 |
| `UniS_Tito` · El compañero que no existe | U | Corcho de fotos con Tito en todas; gafas de sol bajo las gafas | B | S | 4 |
| `Saga_13_SinCosme` · Sin Cosme | U | Garaje **cerrado y con polvo**, Pip con plumero, inventos tapados | B | S | 4 |
| `Aliado_Rex` · Rex, abogado del Ancla | A | **Sala de juicio** en Derecho; Rex con toga; folleto con letra pequeñísima | B | M | 4 |
| `Aliado_Noz` · Final de temporada | A | Cámara alienígena flotante que te sigue y se cae a la arena | B | S | 4 |
| `Rareza_Columpio` · El columpio que va al pasado | N | Parque que se vuelve **sepia** al subir; coches antiguos; tu abu de niño grabando el banco | B | M | 5 |
| `Cole10_Festival` · El festival | N | Patio decorado (guirnaldas y farolillos hoy son cubos); escenario y puestos; **ráfaga de viento**; tú en el escenario | B | M | 6 |
| `Cole11_Proyecto` · El proyecto final | N | **La maqueta** del proyecto (4 variantes; robot con pinza; versión rota) | B | S | 6 |
| `Cole12_UltimoDia` · El último día | N | Ceremonia con escenario y diplomas; cápsula del tiempo con lo que metiste | B | M | 6 |
| `Rareza_Farola` · La farola que canta ópera | N | Que cante **una farola real** (hoy una caja), con notas, ventanas encendidas y vecinos asomados | B | S | 6 |
| `Rareza_Charco` · El charco sin fondo | N | Charco que refleja **otro cielo** con dos lunas; patito que cae hacia arriba y flota | B | S | 6 |
| `Ins02_Clubes` · Los clubes | Ad | Robot Tornillo de verdad corriendo (hoy caja girando); mural del pájaro; final de cada club | B | S | 6 |
| `Ins04_PrimerEmpleo` · El primer empleo | Ad | Bandeja que se rompe; **treinta latas rodando** por el pasillo; Leire en pijama | B | S | 6 |
| `Pan1_MalasCompanias` · Las malas compañías | Ad | Muro del parque con grafitis y tu firma persistente | B | S | 6 |
| `Pan2_LaNoche` · La noche del supermercado | Ad | Almacén trasero a oscuras; **alarma con luces rojas**; patrulla que te corta el paso | B | M | 6 |
| `Loco_A5_Zoltan` · Zoltán | Ad | Cabina de feria con el mago y bola de cristal; marca de turbante en el suelo | B | S | 6 |
| `Rareza_Espejo` · El espejo que contesta | Ad | Reflejo que se mueve distinto a ti; toalla | B | S | 6 |
| `Rareza_Cancion` · La canción que no se acaba | Ad | Altavoz real brillando, notas verdes, alumnos cantando, la canción | B | S | 6 |
| `Rareza_Taquilla` · La taquilla que da a otra taquilla | Ad | Brillo por las rendijas, nota que aparece, mar en el cielo por la rendija | B | S | 6 |
| `Eco_RayoAdulto` · Rayo | Ad→A | Furgoneta que conduces de verdad; control de policía con Bruno | B | S | 6 |
| `Loco_U4_Fiesta` · La fiesta de los cambiaformas | U | Fiesta montada en el estadio; párpados de persiana y tercera pierna; impostores que se derriten en gelatina | B | M | 6 |
| `Uni06_Graduacion` · La graduación | U | Acto con atril, **togas y birretes al aire**; cafetería cerrada para vosotros | B | M | 6 |
| `Rareza_Reloj` · El reloj que va hacia atrás | U | Reloj de la entrada girando al revés; engranajes verdes | B | S | 6 |
| `Adu02_Atardecer` · Un atardecer junto al mar | A | Abu en el hospital; pies en la arena; concha; **atardecer forzado** en la cinemática | B | S | 6 |
| `Adu03_Reencuentro` · El reencuentro | A | Cartel nuevo de la cafetería de Omar; inauguración; foto colgada | B | S | 6 |
| `Aliado_Malvado` · Clases de ser bueno | A | Gato en un árbol de verdad; banco con pintadas que se limpian | B | S | 6 |
| `Rareza_Semaforo` · El semáforo con opiniones | A | Un semáforo real con cara; atasco que arranca al ponerse verde | B | S | 6 |

### Prioridad C (54)

| Misión | Etapa | Qué falta (resumen) | Esf. | Paq. |
|---|---|---|---|---|
| `Prologo_Sueno` · Prólogo: el sueño | N | Destello verde del cielo al coger el tornillo | S | 3 |
| `Cole01_PrimerDia` · El primer día | N | Autobús amarillo en la puerta; timbre; libros que salen volando | S | 6 |
| `Cole02_Mochila` · La mochila desaparecida | N | Rastro de huellas; colchonetas y balones en el almacén | S | 6 |
| `Cole03_Grupo` · El grupo | N | Murales pintados que se quedan; escarabajo que vuela; salpicadura | S | 6 |
| `Cole04_Malotes` · Los malotes | N | Nota de piano; Hugo sentado en el bordillo | S | 6 |
| `Cole05_Venganza` · La venganza de la mochila | N | Papelitos saliendo de la taquilla de Nico; pegatinas de calcetines | S | 6 |
| `Cole06_Examen` · El examen imposible | N | Tic-tac del reloj del aula | S | 6 |
| `Cole08_Torneo` · El torneo | N | Podio y medalla al cuello | S | 6 |
| `Cole09_Misterio` · El misterio del colegio | N | Puerta que cruje; rayo de luz con polvo en la sala cerrada; caja nueva persistente | S | 6 |
| `Eco_MateoDibujo` · Un regalo de Mateo | N | El dibujo en el diario | S | 6 |
| `Eco_MateoSolo` · Mateo come solo | N | Mateo sentado en el rincón del patio | S | 6 |
| `Eco_Ruben` · Rubén | N→Ad | — (conversación) | S | — |
| `Eco_Hugo` · Hugo | N | — (conversación) | S | — |
| `Cole06b_Recuperacion` · Recuperación | N | — | S | — |
| `Eco_Periodico` · El periódico de Valmar | N | Periódico en la mano y en el diario | S | 6 |
| `Saga_04_Ventanilla` · La ventanilla 42 | N | La funcionaria que se teletransporta; sello «¡PUM!» | S | 3 |
| `Rareza_Buzon` · El buzón que escribe al pasado | N | Buzón real que escupe la carta; sello que brilla | S | 6 |
| `Rareza_Helado` · El helado que sabe a recuerdos | N | Cubeta verde; flashback de 3 s | S | 6 |
| `Ins01_NuevoInstituto` · El nuevo instituto | Ad | Tablón con listas; puerta «cuarto de limpieza» con risas; cámara de Leire | S | 6 |
| `Ins03_QueQuieresSer` · ¿Qué quieres ser? | Ad | Vestuario de cada profesión | S | 6 |
| `Ins05_ElRumor` · El rumor | Ad | La foto trucada en el móvil; pegatina «DR» en la grada; Omar con capucha | S | 6 |
| `Ins06_LaGranDecision` · La gran decisión | Ad | Escenario de graduación del instituto (el mismo set que `Saga_12`) | S | 6 |
| `Eco_Leire` · Leire | Ad | La foto en el diario | S | 6 |
| `Eco_LeireSola` · La chica nueva | Ad | Leire sentada sola en un banco del patio | S | 6 |
| `Eco_Carta` · Una carta | Ad | La carta en el diario | S | 6 |
| `Eco_Nico` · Nico | Ad | — | S | — |
| `Pan3_Cruce` · El cruce de caminos | Ad | Puesto de camisetas a la salida del estadio | S | 6 |
| `Eco_Camaras` · Llaman a la puerta | Ad | Que llamen a la puerta de tu casa | S | 6 |
| `Eco_Redada` · La redada | Ad | Puesto precintado | S | 6 |
| `Saga_11_Cronos` · Cronos cambia de bando | Ad | Formularios falsificados en el diario; reloj de arena | S | 3 |
| `Uni01_PrimerDia` · Primer día en el campus | U | Secretaría con cola; reloj de abu; habitación (Paq. 4) | S | 4 |
| `UniEx1_Enero` · Los exámenes de enero | U | Calendario plastificado; biblioteca de noche | S | 4 |
| `UniEx2_Junio` · Junio (y julio) | U | Campus vacío en julio | S | 6 |
| `UniEx3_Parcial` · El parcial imposible | U | Tablón de supervivientes | S | 6 |
| `UniEx4_TFG` · El trabajo de fin de grado | U | Tribunal; sirena de Candela | S | 6 |
| `Uni02_ElProyecto` · El proyecto | U | Pablo con la guitarra en la plaza | S | 6 |
| `Uni03_PrimerTrabajo` · El primer trabajo | U | Cuaderno de Alba con dinosaurios | S | 6 |
| `Uni04_Practicas` · Las prácticas | U | Pasarela que vibra (Ingeniería) | S | 6 |
| `Uni05_PrimerPiso` · Tu primer piso | U | Cajas de mudanza en tu piso nuevo (no «cerca de ti») | S | 6 |
| `UniS_Cita` · Una cita (o algo así) | U | Atardecer; helado que cae | S | 6 |
| `Eco_Concierto` · El concierto de Pablo | U | Tarima, foco y amplificador en la plaza | S | 6 |
| `Rareza_Cafe` · La máquina de café que da consejos | U | Máquina de vending con papelitos | S | 6 |
| `Rareza_Eco` · El eco del estadio | U | Eco con tu voz cambiada; silbato | S | 6 |
| `Rareza_Wifi` · El wifi que se conecta a 1987 | U | Módem y monitor verde con el chat | S | 6 |
| `MetroS_PrimerDiaUni` · Primer día de universidad (en metro) | U | — (el metro existe) | S | — |
| `MetroS_Cartera` · He perdido la cartera | U→A | Objetos debajo del banco del andén | S | 6 |
| `MetroS_PrimerTrabajo` · Primer trabajo, en transporte público | U→A | — | S | — |
| `Adu01_PrimerContrato` · Mi primer contrato | A | Buzón con tres sobres; planta encima de las facturas | S | 6 |
| `Eco_Factura` · Un aviso en el buzón | A | Sobre rojo en el buzón | S | 6 |
| `Aliado_Perez` · La muela del juicio | A | Rig del ratón (Paq. 2); brazo gris por la ventana | S | 2 |
| `Aliado_Cronos` · El expediente de Cronos | A | Ventanilla 42 real; campana | S | 6 |
| `Rareza_Contestador` · El contestador de 1999 | A | Nota de voz con la voz joven | S | 6 |
| `Rareza_Lavadora` · La lavadora multiversal | A | Tu lavadora con brillo verde; calcetines raros | S | 6 |
| `Rareza_Cajero` · El cajero que da minutos | A | Cajero real; reloj parado; cola de vecinos | S | 6 |

Las misiones de capítulo de `Quests.luau` (bebé, recados, días de cole/instituto/universidad, barrio, sueldo, región…) son
rutinas sobre sitios que ya existen: no tienen acontecimientos que construir.

---

## Paquetes de trabajo (orden propuesto)

Detalle técnico, módulos, criterios de «hecho» y dependencias en
[`escenarios-5-diseno-implementacion.md` §7](escenarios-5-diseno-implementacion.md#7-plan-por-fases-paquetes).

| # | Paquete | Misiones (A/B) | Qué se construye | Esf. |
|---|---|---|---|---|
| **1** | **La granja de Villaverde y Petra** (+ motor mínimo) | `Loco_N3_Pollo`, `Cole07_Excursion`, `Saga_19_Recuerdos` | Secuenciador de acontecimientos v1, `StoryFx` (8 recetas), sets con estados, memoria del mundo, rig de ave. Granero grande con interior y nido, huevo gigante, gallinero y corral, cuadra, tractor, huerto; Petra de 21 studs que encoge; Petra normal persistente | L |
| 2 | Criaturas y dobles | 12 A + 9 B (Bigotes, Don Escamas, Don Pinzas, Rex, cucarachas, palomas robot, Ratón Pérez, Pip, lápices, electrodomésticos, gnomos, drones…; clones, tu yo futuro/malvado, sombra, Candelas de papel) | ≈ 22 rigs con el mismo motor de movimiento («mismo motor, otra piel») + 6 variantes de copia del avatar | L |
| 3 | El cielo de la Grieta y la saga en la ciudad | 9 A + 2 B | Eventos animados de `SkyRift` (coser, cremallera, hilos, abrirse), luz por jugador (apagón, atardecer, estrellas), garaje de Cosme con estados, anclajes persistentes, plataforma dorada, máquina de la Fusión, pantallas tomadas por Cósimo | L |
| 4 | Interiores y decorados de la historia | 8 A + 7 B (+ 12 misiones de la residencia de rebote) | Residencia (habitación 214 y cocina), oficina de MegaVerso con servidores, laboratorio del flashback / Pabellón 0, laboratorio 66-B, Monte del Silencio (nave, plató, campamento), piso de Adrián, sala de juicio | L |
| 5 | Dimensiones de bolsillo | 6 A + 1 B | Maquetas de plaza/parque/patio/biblioteca/playa lejos de la ciudad con reskin y luz por jugador: G-4, 66-B, Examen, A-0, V-9, pasado sepia, piso 13; tiempo congelado | M/L |
| 6 | Vida cotidiana, fiestas y rarezas | 5 A + 21 B + los C | Kit de escenarios (festival, graduaciones, conciertos, fiestas), rarezas con su efecto (espaguetis, palomas en cola, sombra, nube, farola, charco…), detalles de colegio, instituto y universidad | M/L |

Orden: **1 → 2 → 3 → 4 → 5**, con el **6** en paralelo desde el principio si hay más gente (casi no depende del motor).
