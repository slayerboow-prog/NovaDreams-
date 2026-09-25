# 11 — Misiones episódicas: la campaña del colegio, el instituto y la universidad

> Objetivo: que al terminar el colegio el jugador diga *"me acuerdo de cuando me robaron la mochila"*,
> no *"he completado 47 quests"*. Cada misión principal es un **episodio jugable de 15–25 minutos**
> con escenas, personajes con personalidad, exploración, diálogos con respuestas, minijuegos,
> decisiones y consecuencias que aparecen **horas después**.

Este documento sigue la instrucción del encargo: **primero el análisis y el diseño, luego la
implementación**. Las misiones 01, 02 y 03 están implementadas y probadas (ver 11.9).

---

## 11.1 Análisis: qué había y qué faltaba

| Pieza | Antes | Qué faltaba para misiones largas |
|---|---|---|
| Motor de misiones (`LifeStoryService`) | Pasos por datos: ir a un sitio, evento, hablar, decisión, grupo, clase, cinemática | Escenas con personajes, objetos que se examinan, minijuegos, temporizadores ("¡vas a llegar tarde!"), consecuencias |
| NPC | Fijos: familia en casa, Nico/Sara/Omar en el patio | **Actores de escena**: aparecen, se mueven, te siguen, se sientan, pasean |
| Diálogos | Una frase suelta en un globo | **Conversaciones** con varios personajes, cámara, y respuestas del jugador que cambian cosas |
| Relaciones | Afinidad 0–5 por NPC | **Relación −100…100**, **rasgos** del jugador (humor, empatía…), **recuerdos** |
| Consecuencias | Marcas y decisiones guardadas | **Consecuencias diferidas**: "10 horas de juego después pasa otra cosa" |
| Minijuegos | Preguntas de clase y circuito de Educación Física | **Pase, canastas, partido de fútbol** (y más adelante persecución) |

## 11.2 Arquitectura (sistemas que pedía el encargo → dónde viven)

No hay un script gigante: cada sistema tiene su módulo y **todas las misiones son datos**.

| Sistema pedido | Módulo | Qué hace |
|---|---|---|
| QuestSystem / QuestManager | `server/Services/LifeStoryService` | Motor: capítulos, misiones, pasos, recompensas, secundarias |
| QuestDefinitions | `shared/LifeStory/Misiones/*.luau` + `MissionIndex` | **Un archivo por misión** con pasos, diálogos, objetos, actores y consecuencias |
| QuestObjectiveSystem | Tipos de paso (11.3) dentro del motor | Cada tipo sabe cuándo se cumple |
| DialogueSystem | `server/Services/DialogueService` + cliente `DialogueUI` | Conversaciones por turnos, respuestas, cámara al que habla, voz |
| ChoiceSystem | Preguntas dentro de los diálogos (`Ask`) y decisiones "en el mundo" (hablar con alguien o tocar un objeto **es** elegir) | Sin ventanas de "elige A/B" siempre que se pueda |
| RelationshipSystem | `LifeStoryService.addRel / trait` | Relación con cada NPC y rasgos del jugador |
| NPCMemorySystem | `Story.NpcMemory` + `Story.Memories` | Qué recuerda cada NPC y los grandes recuerdos (PrimerDiaCole, MochilaPerdida…) |
| SchoolSystem | `ClassService` (clases), `SchoolService` (compañeros en el patio), lugares del colegio | Ya existía; las misiones lo usan |
| UniversitySystem | Carreras en `Subjects.lua` + capítulo `Joven_Universidad` | Ya existía; las misiones universitarias se añadirán como archivos de misión |
| EventSystem | `StoryEvents` + **consecuencias diferidas** (`Story.Later`) | Lo que pasa en otros sistemas avanza misiones; lo que decides vuelve horas después |
| ScheduleSystem | `GameClock` + `StageProgress` + temporizadores de paso (`Late`, `Nudge`, `Timeout`) | Cuándo pasa cada misión y qué pasa si tardas |
| Escenas | `server/Services/SceneService` + cliente `SceneClient` | Actores y objetos de cada misión, solo visibles para su jugador |
| Minijuegos | `server/Services/MiniGameService` + cliente `MiniGameUI` | Pase, Canasta, Fútbol |
| Reparto | `shared/LifeStory/Cast.luau` | Todos los personajes: nombre, voz, aspecto, personalidad |

```
            StoryEvents (trabajar, comprar, hablar, usar un objeto…)
                               │
 Misiones/*.luau ──► LifeStoryService (motor) ──► SceneService ──► actores y objetos en el mundo
   (datos)              │        │                                  (solo para ese jugador)
                        │        ├──► DialogueService ──► DialogueUI (conversación + cámara + voz)
                        │        ├──► MiniGameService ──► MiniGameUI (pase, canasta, fútbol)
                        │        └──► ClassService    ──► ClassUI    (clases con preguntas)
                        ▼
   data.Story: Completed · Flags · Choices · NpcMemory(Rel) · Traits · Memories · Later
```

**Multijugador:** los actores y objetos de una misión son **de tu historia**: los demás jugadores no
los ven ni pueden tocarlos (cada uno vive su primer día). Los compañeros fijos del patio
(`SchoolService`) sí son de todos; cuando tu escena tiene a "Nico", el Nico fijo se oculta para ti.

## 11.3 Formato de una misión (lo que pedía el punto 29)

Cada misión es un archivo `shared/LifeStory/Misiones/<Id>.luau`:

| Campo | Para qué |
|---|---|
| `Id`, `Title`, `Description` | Identidad y texto de la tarjeta |
| `Chapter`, `AgeRange`, `Duration = {min, max}`, `Difficulty`, `Type` | Metadatos (documentación y validación) |
| `Npcs`, `Locations` | Reparto y lugares que usa (el validador comprueba que existan) |
| `Requires` | Prerrequisitos (misiones hechas, marcas, progreso de la etapa, relación…) |
| `Next`, `Outcomes` | A qué conduce y finales posibles (documentación) |
| `Steps` | Los objetivos encadenados (tipos abajo) |
| `Props` | Objetos de la misión: dónde están, qué dicen al examinarlos, qué dan |
| `Dialogues` | Conversaciones: líneas, preguntas al jugador, efectos |
| `Moment`, `Memory`, `Rewards` | Cómo se recuerda y qué da al terminar |

**Tipos de paso**

| Tipo | Se cumple cuando… |
|---|---|
| `Scene { Dialogue }` | Termina una conversación que empieza sola (con cámara) |
| `Talk { Npc, Dialogue? }` | Hablas con ese personaje (y termina la conversación) |
| `Use { Prop }` | Usas/examinas ese objeto |
| `Group { Steps, Need? }` | Haces `Need` de las cosas de la lista, en cualquier orden |
| `Choice { Key, Options }` | Eliges: si las opciones tienen `Npc` o `Prop`, se elige **en el mundo** (hablar con un grupo = unirte a él) |
| `MiniGame { Game, … }` | Terminas el minijuego (ganes o no: **nunca bloquea**; `Win`/`Lose` son efectos distintos) |
| `Reach`, `Event`, `Class`, `Wait`, `Moment`, `Transition`, `Cinematic` | Como antes |

**Campos comunes de cualquier paso:** `Actors` (quién está en escena y qué hace: quieto, pasear,
seguirte, sentado, saludar), `Props`, `Teleport`, `Effects` (al cumplirse), `If` (el paso solo existe
si…), `Nudge` (alguien te mete prisa si tardas), `Late` (si tardas más de X, queda marcado: *llegaste
tarde*), `Timeout` (si no haces nada en X, la historia sigue por otro camino: *ignoraste a Mateo*).

**Efectos** (en respuestas, objetos, pasos y finales): `Flags`, `Rel = { Mateo = 15 }`,
`Traits = { Empatia = 1 }`, `Memory`, `Remember`, `Items`/`Take` (mochila), `Needs`, `Money`,
`Later = { { AfterHours = 10, Flag = …, Start = "Eco_Ruben" } }`.

**Condiciones nuevas** (en `If` de líneas, pasos y requisitos): `Rel = { Mateo = 10 }` (mínimo),
`Traits`, `Memories`, `NotMemories`, `Flags`, `Choices`.

## 11.4 Diálogos (punto 25)

```lua
Despertar = { Lines = {
  { S = "Familia", T = "¡Arriba, {nombre}! Hoy es tu primer día de cole." },
  { Ask = "¿Qué le dices?", Options = {
      { T = "Cinco minutitos más…", Effects = { Traits = { Humor = 1 } },
        Then = { { S = "Familia", T = "Cinco minutitos dice… ¡Ni uno!" } } },
      { T = "¡Ya estoy despierto!", Effects = { Traits = { Responsabilidad = 1 } } },
  } },
  { S = "Familia", T = "Hoy te toca el jersey del cole.", If = { Flags = { "…" } } },
} }
```

- `S` = quién habla (`Cast.luau`), `Yo` = el jugador, `Narrador` = texto en cursiva.
- La cámara se acerca al que habla si está en la escena; la voz sintetizada usa su perfil.
- Las líneas con `If` hacen que los personajes **recuerden**: *"¿Tú eres quien le pasó el balón a mi
  hermano?"* solo aparece si lo hiciste.

## 11.5 Relaciones, rasgos, recuerdos y consecuencias diferidas (puntos 26–27)

- **Relación** con cada NPC: −100…100 (`Story.NpcMemory[npc].Rel`). Ayudar a Mateo +15, ignorarlo −5…
- **Rasgos** del jugador (`Story.Traits`): `Humor`, `Empatia`, `Valentia`, `Responsabilidad`,
  `Curiosidad`, `Deportividad`, `Creatividad`. Suben con lo que eliges y cambian cómo te hablan.
- **Recuerdos** (`Story.Memories`): `PrimerDiaCole`, `PrimerAmigo`, `MochilaPerdida`, `PrimerGrupo`,
  `PrimerPartido`… Los NPC los citan ("¿Te acuerdas del partido?") y la misión del último día hará
  flashbacks con ellos.
- **Consecuencias diferidas** (`Story.Later`): una decisión programa algo para dentro de X horas de
  juego (el reloj es el tiempo jugado, `Story.Clock`). Ejemplo real implementado:
  *te quitan la mochila → investigas → descubres a Rubén → decides → **10 horas de juego después**
  (ya en el instituto) Rubén vuelve a aparecer y la conversación depende de lo que hiciste.*

## 11.6 Reparto del colegio (`Cast.luau`)

| Personaje | Quién es | Arco |
|---|---|---|
| **Lucía** | Tutora de 1.º A. Cariñosa y exigente. | Estudió en este colegio (la foto de la misión 09) |
| **Ramón** | Conserje bromista; sabe todo del colegio | Guarda las llaves del almacén y de la sala cerrada |
| **Andrés** | Profe de Educación Física, árbitro | Entrenador del torneo (misión 08) |
| **Nico** | Deportista, impulsivo, generoso | Rival amistoso en el torneo |
| **Sara** | Curiosa, científica, habla rapidísimo | Compañera de estudio (examen imposible) |
| **Omar** | Artista tranquilo, siempre con hambre | Dibuja todo lo que pasa (sus dibujos son pistas) |
| **Mateo** | Tímido, nuevo en el barrio, colecciona cromos | Tu primer amigo… o el niño al que ignoraste |
| **Dani** | Hermano pequeño de Mateo (5 años) | El del balón del primer día |
| **Bruno** | Líder de "los malotes"; fanfarrón e inseguro | Antagonista con motivos (misión 04) |
| **Rubén** | El bromista de Bruno | Escondió tu mochila; puede acabar siendo aliado |
| **Hugo** | Va con Bruno pero no quiere; le encanta leer | El malote que no lo es (misión 04) |
| **Álex, Vega, Iker** | Deportista, artista y "empollón" | Los tres grupos del recreo |

---

## 11.7 Misión 01 — «El primer día» (implementada)

1. **Objetivo narrativo:** presentar la casa, el colegio, los controles (andar, hablar, examinar,
   la mochila, la guía), la hora y a los personajes. Primeras relaciones.
2. **Duración:** 15–20 min.
3. **NPC:** Familia, Dani, Ramón, Andrés, Lucía, toda la clase (Nico, Sara, Omar, Mateo, Bruno, Rubén,
   Hugo, Álex, Vega, Iker), alumnos y padres de la entrada.
4. **Lugares:** dormitorio, cocina, la calle (punto a mitad de camino, en la acera), entrada del
   colegio, vestíbulo, patio, cancha, campo de fútbol, gimnasio, aula 1.º A, casa.
5. **Objetivos:** despertar → prepararse (armario, mochila, desayuno; cama y espejo opcionales) →
   salir (sola/o o con la familia) → el balón de Dani → la entrada (con gente) → encontrar a tu tutora
   entre tres profes → recorrer el colegio (3 informantes) → encontrar tu aula → elegir sitio →
   presentarte → clase de Matemáticas → recreo con uno de los tres grupos → los libros de Mateo →
   volver a casa y contarlo en la cena.
6. **Diálogos principales:** despertar, desayuno, salida, Dani, Ramón, tres profes, Lucía, informantes,
   presentación en clase, cada grupo del recreo, Mateo, la cena.
7. **Mecánicas:** examinar objetos, ropa elegida, la mochila del inventario (se guarda la **Mochila del
   cole**), guía de camino, temporizador (si tardas: *"¡vas a llegar tarde!"* y Lucía lo comenta),
   actores que te siguen.
8. **Minijuegos:** pase del balón (barra de precisión); clase de preguntas.
9. **Decisiones:** respuesta al despertar, ropa, qué llevar (el cromo de la suerte), desayuno,
   ir con la familia o solo, sitio en clase (junto a Sara, Nico o Mateo), qué te gusta, grupo del
   recreo, ayudar a Mateo o no, qué cuentas en la cena.
10. **Consecuencias:** relaciones (+ con quien te sientas, con el grupo elegido, Mateo ±), rasgos,
    marca *LlegasteTarde*, *AyudasteAMateo* / *IgnorasteAMateo*. **Diferida:** si ayudaste a Mateo,
    ~1 h de juego después Mateo te busca y te regala un dibujo (objeto de la mochila). Si le
    ignoraste, ~1 h después lo ves comiendo solo y tienes una segunda oportunidad.
11. **Recompensas:** recuerdo *PrimerDiaCole*, *Mochila del cole* y *Cromo de la suerte* en la mochila,
    10 $ de paga.
12. **Conexión:** la mochila y el cromo son la base de la misión 02; Rubén, Bruno y Hugo ya se han
    presentado; Ramón ha mencionado el almacén "donde nadie debe entrar".

## 11.8 Misión 02 — «La mochila desaparecida» (implementada)

1. **Objetivo narrativo:** primera aventura: investigar, preguntar, deducir. Presentar a Rubén y a la
   pandilla de Bruno como personas, no como enemigos.
2. **Duración:** 15–25 min.
3. **NPC:** Lucía, Ramón, Sara, Omar, Iker, Mateo (si le ayudaste), Álex y dos mayores, Rubén.
4. **Lugares:** aula, entrada (conserjería), patio, cancha, zona de juegos, gimnasio, almacén.
5. **Objetivos:** llegar a clase → Lucía te manda con Ramón → vuelves: **la mochila no está** (se va de
   tu inventario) → buscar en pupitre, perchero y papelera → preguntar a tres compañeros (pistas
   distintas; Mateo añade una si le ayudaste) → buscar 4 de 5 pistas en el patio (papel con una "R",
   tu cromo o una pegatina, huella de barro, llavero con una "B", envoltorio de chicle que no lleva
   a nada) → la cancha: Álex solo habla si metes 3 canastas → el almacén del gimnasio: tres
   mochilas que no son la tuya (una es de Hugo, con un libro de piratas) → aparece Rubén: *"¿Buscas
   esto?"* → **decisión** → Lucía interviene → recuperas la mochila.
6. **Diálogos principales:** Lucía, Ramón, tres compañeros, Álex, Rubén, las cuatro ramas, Lucía final.
7. **Mecánicas:** inventario (te quitan y te devuelven la mochila), examinar pistas, deducción guiada.
8. **Minijuegos:** 3 canastas (barra de precisión con zona que se estrecha).
9. **Decisión:** A) Enfadarte · B) Perdonar · C) Contárselo a Lucía · D) Gastarle una broma de vuelta
   (le escondes la gorra). No hay opción correcta.
10. **Consecuencias:** relación con Rubén y Bruno, rasgos (Valentía, Empatía, Responsabilidad,
    Humor), marcas `Ruben_Rival` / `Ruben_Perdonado` / `AvisasteALucia` / `BromaDeVuelta`.
    **Diferida (10 h de juego):** Rubén reaparece ya en el instituto y la escena cambia según lo que
    hiciste (te pide perdón de verdad, te devuelve la broma, te cuenta por qué lo hizo…).
11. **Recompensas:** recuerdo *MochilaPerdida*, la mochila vuelve a tu inventario.
12. **Conexión:** Bruno (el que mandó a Rubén) y Hugo (el del libro) son el centro de la misión 04.

## 11.9 Misión 03 — «El grupo» (implementada)

1. **Objetivo narrativo:** formar tu grupo de amigos con personalidades claras; primer partido.
2. **Duración:** 20–25 min.
3. **NPC:** Nico, Sara, Omar, Mateo (si es tu amigo), Andrés (árbitro), Bruno, Rubén, Hugo, Álex.
4. **Lugares:** aula, patio, valla del mural, campo de fútbol, casa (si pides permiso), parque:
   canasta, columpios, estanque, quiosco, banco.
5. **Objetivos:** clase de Ciencias → en el recreo te invitan **tres** compañeros (Nico: partido; Omar:
   pintar el mural; Sara: seguir a un escarabajo rarísimo) → la actividad elegida → todo acaba en el
   partido contra el equipo de Bruno → elegir posición → **partido** → charla en el banquillo →
   *"después de clase, ¡al parque!"* (aceptar o pedir permiso en casa primero) → ir al parque con
   ellos (te siguen) → 3 de 5 actividades (canastas con Nico, columpios con Omar, experimento en el
   estanque con Sara, helados con Mateo, charla en el banco: **¿qué quieres ser de mayor?**) → Omar
   cuenta lo del **gato del colegio** (secundaria) → poner **nombre al grupo** → foto.
6. **Diálogos principales:** invitaciones, cada actividad, charla de equipo, banquillo, parque, banco.
7. **Mecánicas:** amigos que te siguen, elegir actividad por el mundo, compra de helados.
8. **Minijuegos:** partido de fútbol (pases, regates, tiros y paradas), canastas.
9. **Decisiones:** a quién acompañar, posición, cómo reaccionar al resultado, permiso en casa, sueño
   de mayor (se guarda y **vuelve en el instituto** en «¿Qué quieres ser?»), nombre del grupo.
10. **Consecuencias:** relaciones con el grupo, rasgo según actividad, marcas `PartidoGanado` /
    `PartidoPerdido`, `SuenoInfancia`, nombre del grupo (lo usarán los NPC).
11. **Recompensas:** recuerdos *PrimerGrupo* y *PrimerPartido*, **Foto del grupo** en la mochila.
12. **Conexión:** el grupo acompaña en todas las misiones siguientes; Bruno pierde o gana el partido y
    eso alimenta la rivalidad (misión 04); la secundaria del gato.

---

## 11.10 Hoja de ruta del colegio (siguientes episodios)

| # | Misión | Duración | Núcleo jugable | Consecuencia clave |
|---|---|---|---|---|
| 04 | Los malotes | 20–30 | Burlas → te quitan tu objeto favorito → investigación → **persecución** por aula, pasillo, patio, gimnasio y calle (correr, esconderse, atajos) → Hugo no quería participar | Relación con Hugo; Bruno como personaje |
| 05 | La venganza de la mochila | 15–20 | Bromas a varios alumnos: notas, horarios, "cámaras", testigos → un compañero que quería atención | Solución social; nuevo amigo o no |
| 06 | El examen imposible | 20–25 | Conseguir apuntes, compañero de estudio, biblioteca, ejercicios, examen | Nota por esfuerzo; si suspendes, «Recuperación» |
| 07 | La excursión | 25–35 | Autobús (con quién te sientas), viaje, destino explorable, un compañero se pierde, pistas, foto | Recuerdo *PrimeraExcursion* |
| 08 | El torneo | 20–30 | Elegir deporte, entrenar, clasificar, final, rivalidad con Nico o Bruno | Reputación y habilidad |
| 09 | El misterio del colegio | 25–35 | La sala cerrada, nota "NO ENTRES", pistas en biblioteca/oficina/almacén → foto de Lucía de niña | Arco de Lucía |
| 10 | El festival | 30–40 | Elegir responsabilidad (decoración, música, deporte, comida, teatro, foto) y resolver imprevistos | Fotos y recuerdos; misión cooperativa con jugadores |
| 11 | El proyecto final | 25–35 | Formar equipo con roles, investigar, materiales, ensayo, presentación | Resultado según decisiones |
| 12 | El último día | 20–30 | Visitar lugares, **flashbacks** con tus recuerdos reales, foto de clase, ceremonia | Paso al instituto |

Instituto: «¿Qué quieres ser?» (visitar hospital, taller, comisaría, empresa, restaurante, universidad,
gimnasio, estudio y laboratorio; **tu sueño de la infancia aparece**), clubes, primer empleo,
orientación. Universidad: «Primer día» (campus grande), «El proyecto» (gestionar un grupo con
personalidades), «El primer trabajo», «Las prácticas» (según la carrera), «La graduación».

## 11.11 Secundarias y misiones aleatorias (puntos 22–23)

**Plantillas procedurales** (`NPC × Problema × Lugar × Objetivo × Recompensa`): cada combinación crea
una secundaria distinta. Tipos previstos (50+): objeto perdido (bocadillo, balón, libro, cámara,
cartera, llaves, estuche, gorra, cromo, pulsera…), mascota escapada (gato, perro, hámster, loro,
**robot de tecnología**), persona perdida (hermano pequeño, compañero nuevo, abuelo), recado (material,
medicinas, pan, flores, fotocopias), ayuda (biblioteca, decorar el aula, regar el huerto, montar el
escenario), social (organizar un partido, una sorpresa, una fiesta, hacer las paces), misterio
(notas anónimas, lugar secreto, objeto escondido, quién dejó las notas), concurso (dibujo, ortografía,
ciencia, cocina), rescate (balón en el tejado, cometa en el árbol).

Implementadas ahora: *El gato del colegio* (desde la misión 03) y las consecuencias diferidas de
Mateo y Rubén.

## 11.12 Regla de diseño

Una misión solo existe si cuenta algo, enseña algo, hace avanzar una relación, descubre una zona,
introduce una mecánica, crea un recuerdo o cambia algo en la vida del jugador. Antes de escribir una
misión nueva se rellena la ficha de 12 puntos de 11.7.

---

## 11.13 Estado, pruebas y lo que falta

**Hecho y probado** (prueba automática `scripts/test-lifestory.luau`, 161 comprobaciones en verde):

- Misiones 04, 05 y 06 (ver 11.14–11.16): persecución con personajes que huyen, escondite y atajo;
  investigación con acusación que puede fallar; examen con estudio, bonus de tiempo y recuperación si
  suspendes. Consecuencias nuevas: Hugo (2 h después) y la «Recuperación».

- Misiones 01, 02 y 03 completas, jugadas de principio a fin por un "jugador automático" que habla, usa
  objetos, elige y juega los minijuegos, por **dos caminos distintos** (ayudar o ignorar a Mateo,
  acertar o fallar el pase, diferentes asientos, grupos y respuestas).
- Consecuencias diferidas: Mateo (1 h de juego después, dos versiones), el gato del colegio (secundaria
  que nace de una conversación) y Rubén (10 h de juego después, cuatro versiones según tu decisión).
- El validador revisa cada misión: diálogos, objetos, actores, lugares, efectos, recuerdos y objetos de
  mochila que existan. Un error de datos se ve al arrancar el servidor (Output) y en la prueba.

**Duración:** la estimada por diseño (15–25 min por misión) sale de contar escenas, trayectos y
minijuegos; **hay que medirla jugando en Roblox Studio** y ajustar (más pistas, más trayectos o menos).

**Lo que no se puede probar fuera de Roblox:** la colocación exacta de actores y objetos en el mapa
(se apoyan en el suelo con un rayo, pero un desplazamiento puede caer dentro de una pared), las
animaciones de los NPC, la cámara de los diálogos y el tacto de los minijuegos.

**Conexión con el mapa:** la sesión del mapa dejó marcas para estas tres misiones
(`StoryProp` / `StoryArea` / `StorySpot`, ver `docs/mapa/ETIQUETAS.md`) y las misiones ya las usan
(lugares `Casa*`, `Spot*`, `*Colegio`, `*Parque`, `MochilaAlmacen*`, `TaquillaColegio` en `Locations.luau`):
- Un `StoryProp` es el objeto de verdad (el armario de tu casa, tu taquilla, las mochilas del almacén):
  la misión lo marca con un contorno dorado y le pone el botón, **sin crear otro encima**.
- Un `StorySpot` dice dónde se pone cada personaje y hacia dónde mira (grupos del recreo, informantes,
  pistas, el gimnasio, el almacén, el campo de fútbol, el parque).
- Cada lugar tiene un plan B (`Fallback`) con posiciones aproximadas: el colegio del Campus, que no tiene
  gimnasio ni comedor, funciona igual.
- Los personajes de las escenas se visten con `Npc.dress` (el mismo aspecto que el resto del juego), y cada
  uno lleva siempre la misma ropa, pelo y mochila (`Cast.luau`).

**Siguiente:** 07 «La excursión», 08 «El torneo», 09 «El misterio del colegio» (la foto de Lucía: ya se
insinúa en la misión 05), con la misma ficha de 12 puntos.

---

## 11.14 Misión 04 — «Los malotes» (implementada)

1. **Objetivo narrativo:** el primer conflicto de verdad, sin violencia. Bruno deja de ser "el malo" y
   Hugo se revela: va con ellos porque no sabe cómo dejarlo.
2. **Duración:** 20–30 min.
3. **NPC:** Bruno, Rubén, Hugo, Nico, Sara, Omar, Mateo (si es tu amigo), Lucía, Ramón.
4. **Lugares:** patio, aula, pasillo, comedor, gimnasio, puerta del gimnasio, aula de música (atajo).
5. **Objetivos:** recreo con tu grupo → burlas de Bruno (respondes como quieras) → vuelves a clase: **tu
   objeto favorito ha desaparecido** (el cromo de la suerte si lo llevabas; si no, la foto del grupo) →
   investigar (3 de 5: Nico, Sara, Omar, Lucía, Ramón; Mateo añade una pista) → los ves en el pasillo y
   **salen corriendo** → **persecución** pasillo → patio → (¡viene Ramón, escóndete!) → gimnasio →
   fuera; atajo opcional por el aula de música → alcanzas a Hugo (el más lento: hay que correr con
   Shift) → Hugo te lo devuelve y te cuenta por qué → **decisión** → consecuencia.
6. **Diálogos principales:** burlas, cada testigo, Ramón pillándote corriendo, Hugo, las cuatro ramas.
7. **Mecánicas nuevas:** personajes que **huyen** por una ruta (`Mode = "Flee"`), paso `Chase`
   (alcanzar a alguien), esconderse a tiempo (`Timeout` con marca), atajo (efecto `Teleport`).
8. **Minijuegos:** la persecución misma (correr, gestionar la estamina, atajo, esconderse).
9. **Decisión:** A) Contárselo a Lucía · B) Hablar con ellos (Bruno te cuenta lo de su hermano) ·
   C) Pedir ayuda a tu grupo (plantaros juntos) · D) Dejarlo estar.
10. **Consecuencias:** relación con Hugo, Bruno y Rubén; rasgos; marcas `Hugo_*`, `Bruno_*`.
    Cambia cómo empieza M05 y los diálogos de M06. **Diferida (2 h):** Hugo vuelve (te regala su libro
    de piratas, se une al grupo… o sigue solo, según lo que hiciste).
11. **Recompensas:** recuerdo *LosMalotes*, tu objeto vuelve a la mochila.
12. **Conexión:** «La venganza de la mochila» empieza con alguien haciendo bromas… y todos miran a Bruno.

## 11.15 Misión 05 — «La venganza de la mochila» (implementada)

1. **Objetivo narrativo:** una investigación con pistas de verdad y un culpable inesperado; la
   solución es social. Enseña a no juzgar por la fama.
2. **Duración:** 15–20 min.
3. **NPC:** Lucía, Ramón, Vega, Álex, Nico, Sara, Omar, Bruno, Iker (el culpable), Hugo (si es tu amigo).
4. **Lugares:** aula, pasillo (taquillas), comedor, biblioteca, conserjería (las "cámaras").
5. **Objetivos:** bromas a tres alumnos (a Vega le cambian las pegatinas, a Álex le esconden los guantes, a
   Nico le llenan la taquilla de papelitos) → todos culpan a Bruno → Lucía te pide ayuda → pistas: notas
   (letra muy ordenada), el horario (las bromas pasan cuando Iker sale "al baño"), la "cámara" de
   Ramón (un dibujo de Omar del pasillo), testigos → **acusar** a alguien (si te equivocas, hay
   consecuencias y vuelves a pensar) → Iker confiesa: quería que alguien le hiciera caso → **decisión
   social** (invitarle al grupo, pedirle que se disculpe él mismo, contárselo a Lucía).
6. **Diálogos:** cada víctima, Bruno defendiéndose ("¡esta vez no he sido yo!"), Ramón, Iker.
7. **Mecánicas nuevas:** acusar (opción que **no avanza** si fallas: `Stay = true`), notas con pistas.
8. **Minijuegos:** deducción (elegir sospechoso con las pistas que tienes).
9. **Decisiones:** a quién acusas; qué haces con Iker.
10. **Consecuencias:** si acusas a Bruno sin pruebas, Bruno lo recuerda; relación con Iker; marca
    `IkerEnElGrupo`. Bruno reconoce que "esta vez" lo trataste justo (o no).
11. **Recompensas:** recuerdo *Detective*.
12. **Conexión:** Lucía anuncia el examen de mañana.

## 11.16 Misión 06 — «El examen imposible» (implementada)

1. **Objetivo narrativo:** la primera presión de verdad; el esfuerzo importa más que la nota.
2. **Duración:** 20–25 min.
3. **NPC:** Lucía, Sara, Iker, Mateo, Nico, la bibliotecaria Marisa, la familia.
4. **Lugares:** aula, biblioteca (apuntes), casa (estudiar por la noche), aula (examen).
5. **Objetivos:** Lucía anuncia el examen → **conseguir apuntes** (en la biblioteca; Marisa pide que
   los devuelvas) → **compañero de estudio** (Sara, Iker, Mateo o sin nadie) → **biblioteca**: sesión de
   estudio (preguntas) → ejercicios en casa (opcional: más estudio = más tiempo en el examen) → dormir →
   **examen** (10 preguntas) → la nota.
6. **Diálogos:** anuncio, bibliotecaria, cada compañero de estudio (Sara exigente, Iker sabelotodo,
   Mateo nervioso como tú), la familia la noche antes, el resultado.
7. **Mecánicas:** la nota depende de tus respuestas; **estudiar da segundos extra** en el examen
   (`Bonus`); condiciones por nota (`LastGradeBelow`, `LastGradeAtLeast`).
8. **Minijuegos:** sesión de estudio y examen (preguntas).
9. **Decisiones:** con quién estudias; estudiar más en casa o ver la tele.
10. **Consecuencias:** si suspendes, empieza **«Recuperación»** (Lucía te da otra oportunidad con
    clases de repaso); si apruebas con esfuerzo, recuerdo distinto. Relación con tu compañero de estudio.
11. **Recompensas:** recuerdo *PrimerExamen* (o *CasiSuspendo*), 10 $.
12. **Conexión:** después vienen los recados, la excursión y el resto del curso.

