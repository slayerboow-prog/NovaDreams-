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

**Hecho y probado** (prueba automática `scripts/test-lifestory.luau`, 319 comprobaciones en verde):

- Personajes vivos y cinemáticas (ver `docs/diseno/personajes-vivos-cinematicas.md`): los personajes
  respiran, te miran, gesticulan al hablar según la emoción de la frase (`A = "Cheer"` o se adivina
  por el texto), charlan entre ellos (modo `Chat`) y los del mapa ya andan con animación. Cámara de
  conversación con planos de cine; cinemáticas con cámara en mano, zoom, enfoque, cortes a negro,
  primeros planos de personajes (`Actor:Abu`) y gestos de todos (`Anims`).

- Instituto 01–06 (ver 11.23–11.29): primer día, clubes, profesiones, primer empleo con el sistema de
  trabajos de verdad, el rumor en el grupo de clase y la gran decisión (con la selectividad y el paso a
  la universidad o al trabajo). Consecuencias: Leire (2 h), la carta de recomendación (3 h, si no
  mentiste en la entrevista) y Nico (3 h).

- Misiones 10, 11 y 12 (ver 11.20–11.22): el festival (cinco tareas distintas, imprevistos y
  escenario), el proyecto final (tema, rol, investigación, compra real en la librería, desastre y
  presentación con bonus de tiempo; si sale premiado, 1 h después sale en el periódico: `Eco_Periodico`)
  y el último día (recuerdos que salen de lo que de verdad jugaste, la cápsula del tiempo, despedidas y
  paso al instituto).

- Misiones 07, 08 y 09 (ver 11.17–11.19): la excursión a la granja (sustituye a la antigua
  «Excursión al parque de bomberos»), el torneo con tres caminos según el deporte y el misterio de la
  sala cerrada con el candado de código. La prueba juega el camino "difícil": atletismo, clasificación
  y final perdidas (medalla de plata), código equivocado antes del bueno, colarse en el recreo.

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

**Marcas de mapa opcionales para 07–09** (si no existen, se usa el plan B): `StorySpot` «Autobus» (puerta
del colegio), `StoryArea` «SalaCerrada» y `StorySpot` «SalaCerrada_Puerta» (la puerta del fondo del
pasillo). La granja usa el modelo `Granja` (y su hijo `Granero`) que ya existe en Villaverde.

**Capítulo del colegio completo (01–12).** Las misiones 10–12 (ver 11.20–11.22) sustituyen a las
antiguas «El segundo trimestre» y «Fin de primaria»: el paso al instituto lo hace ahora «El último día».
**Capítulo del instituto completo (01–06, ver 11.23–11.29).** Sustituye a las antiguas
`Adol_NuevoInstituto`, `Adol_PrimerTrabajo` y `Adol_ElFuturo`.

**Capítulo de la universidad completo (01–06, ver 11.30–11.36).** Sustituye a todas las misiones
antiguas de la universidad. Con esto, **la campaña escolar y universitaria del encargo está terminada**:
colegio (12), instituto (6) y universidad (6), con sus consecuencias diferidas.

**Vida adulta (en marcha, ver 11.37–11.40):** capítulo nuevo `Adulto_VolarDelNido` (01–03) para quien
ha vivido el instituto, con carrera o trabajando. `Adulto_NuevaVida` queda solo para los veteranos (quien ya
jugaba antes de la historia de vida). **Siguiente:** el capítulo «Construir» (30–64 años, ver
[05](05-misiones-eventos.md)): la casa de verdad, llegar a jefe, emprender, familia, dejar huella, mentor.

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

## 11.17 Misión 07 — «La excursión» (implementada)

1. **Objetivo narrativo:** el primer episodio "especial": salir de la ciudad con la clase, un lugar
   nuevo que explorar y un susto que se resuelve en equipo.
2. **Duración:** 25–35 min.
3. **NPC:** Lucía, Andrés, Paula (monitora de la granja), Julián (el granjero), tu grupo, Mateo (el que
   se pierde; si no es tu amigo, se pierde Omar), Bruno, Hugo.
4. **Lugares:** entrada del colegio (autobús), **la Granja escuela de Villaverde** (granero, silo, corrales).
5. **Objetivos:** subir al autobús y **elegir con quién te sientas** → viaje (conversaciones y un
   imprevisto: Omar se come el bocadillo en el primer kilómetro) → llegada (escena aérea de Villaverde) →
   Paula presenta la granja → 3 de 4 actividades (dar de comer a las gallinas, el huerto, los caballos,
   subirte al tractor) → **¡falta Mateo!** → buscarle siguiendo pistas (su mochila, su botella, un mapa
   dibujado, lo que dice Julián) → le encuentras siguiendo a un corderito → vuelta al autobús → **foto de
   la clase**.
6. **Diálogos:** asiento (cada compañero habla de algo distinto), viaje, Paula, cada actividad, la
   búsqueda, Mateo encontrado, la foto.
7. **Mecánicas:** viaje con cambio de ciudad (efecto `Teleport`), actividades en cualquier orden.
8. **Minijuegos:** dar de comer a las gallinas (precisión: echar el grano en su sitio).
9. **Decisiones:** con quién te sientas; qué haces al encontrar a Mateo (avisar a Lucía o traerle tú).
10. **Consecuencias:** relaciones; Mateo (u Omar) te lo agradece siempre; marca de quién se sentó contigo.
11. **Recompensas:** recuerdo *PrimeraExcursion*, **foto de la excursión** en la mochila.
12. **Conexión:** en el autobús de vuelta, Andrés anuncia el torneo.

## 11.18 Misión 08 — «El torneo» (implementada)

1. **Objetivo narrativo:** esfuerzo, equipo y saber ganar y perder. La rivalidad con Bruno cambia según
   todo lo que ha pasado.
2. **Duración:** 20–30 min.
3. **NPC:** Andrés, Nico, Sara, Omar, Álex, Mateo, Hugo (si está en tu grupo), Bruno, Rubén, alumnos de
   otras clases, familia (grada).
4. **Lugares:** campo de fútbol, gimnasio (canasta), pista.
5. **Objetivos:** Andrés presenta el torneo → **eliges deporte** (fútbol, baloncesto o atletismo) →
   entrenamiento (distinto en cada deporte) → preparación (charla del equipo: capitán y estrategia) →
   **clasificación** (partido contra 1.º B) → descanso (tu familia en la grada) → **final contra el equipo
   de Bruno** → entrega de medallas.
6. **Diálogos:** Andrés, equipo, familia, Bruno antes y después de la final (según vuestra historia).
7. **Mecánicas:** tres caminos distintos según el deporte.
8. **Minijuegos:** fútbol (partido por jugadas), baloncesto (canastas), atletismo (circuito en la pista +
   salida y zancadas).
9. **Decisiones:** deporte, capitán (tú u otro), estrategia, cómo celebras o encajas el resultado.
10. **Consecuencias:** reputación (Deportividad), relación con el equipo y con Bruno; marca
    `TorneoGanado` / `TorneoPerdido`.
11. **Recompensas:** recuerdo *PrimerTorneo*, **medalla** (oro o plata) en la mochila.
12. **Conexión:** tras el torneo corre un rumor por el colegio: la sala del fondo del pasillo.

## 11.19 Misión 09 — «El misterio del colegio» (implementada)

1. **Objetivo narrativo:** un misterio que acaba en ternura: la profe Lucía también fue niña aquí.
2. **Duración:** 25–35 min.
3. **NPC:** tu grupo, Iker (si está en el grupo), Marisa, Ramón, Lucía.
4. **Lugares:** pasillo (la puerta cerrada del fondo), biblioteca (el anuario de 1998), conserjería (el
   tablero de llaves), almacén (el trofeo viejo), la sala cerrada.
5. **Objetivos:** rumores del recreo → una nota en tu taquilla: **«NO ENTRES»** → investigar (anuario,
   llaves, trofeo, inscripción de la puerta) → **el código del candado** (año + número de la llave:
   si fallas, piensas otra vez) → pedir permiso a Ramón **o** colarte en el recreo → dentro: pupitres
   viejos, trofeos… y **una foto de la clase de 1998 con una niña de jersey amarillo** → hablar con
   Lucía.
6. **Diálogos:** rumores (cada amigo tiene su teoría), Marisa, Ramón, la puerta, Lucía.
7. **Mecánicas:** pistas que se combinan en un código (opciones que no avanzan si fallas).
8. **Minijuegos:** el candado de números.
9. **Decisiones:** permiso o a escondidas; qué hacer con la foto (devolvérsela a Lucía, enseñarla a la
   clase o guardar el secreto).
10. **Consecuencias:** relación con Lucía y Ramón; marca `CapsulaDelTiempo`: Lucía propone que la clase
    deje su propia cápsula del tiempo en la sala, **que se abrirá el último día de colegio**.
11. **Recompensas:** recuerdo *MisterioColegio*, **copia de la foto** en la mochila.
12. **Conexión:** la cápsula del tiempo volverá en «El último día».

## 11.20 Misión 10 — «El festival» (implementada)

1. **Objetivo narrativo:** trabajar para los demás. Cada uno tiene una tarea y el día señalado todo se tuerce un poco.
2. **Duración:** 30–40 min.
3. **NPC:** Lucía, Marta (música), Andrés, Vega, Omar, Sara, Nico, Hugo, Iker, Mateo, Bruno, Rubén, Ramón,
   una niña de 1.º, tu familia y {abu}.
4. **Lugares:** aula, patio, aula de música, comedor, gimnasio, zona de juegos, vestíbulo.
5. **Objetivos:** anuncio → **eliges tarea** (decoración con Vega, música con Marta, comida con Omar,
   fotos con Sara o **teatro con Hugo**, solo si Hugo está en tu grupo) → la preparas (cada tarea tiene
   su recorrido y su minijuego) → el día del festival: **imprevistos** (3 de 4: los farolillos, el
   altavoz, una niña perdida, el puesto de limonada de Bruno) → tu tarea luce → concurso de talentos.
6. **Diálogos:** cada organizador, cada imprevisto, la familia, Bruno.
7. **Mecánicas:** cinco caminos de preparación; imprevistos en cualquier orden. El modo cooperativo con
   otros jugadores que pedía la tabla de 11.2 **queda pendiente**: hoy cada jugador vive su propio festival.
8. **Minijuegos:** tocar a tiempo, decorar magdalenas, decir tu frase, tu número en el escenario.
9. **Decisiones:** tarea; cómo ayudas a la niña; **ayudar o no a Bruno**; subir al escenario o animar.
10. **Consecuencias:** relaciones (Bruno mejora mucho si le ayudas: lo recuerda en «El último día»);
    rasgos; marcas `TareaBrillante`, `SubesAlEscenario`, `Choices.FestivalBruno`.
11. **Recompensas:** recuerdo *ElFestival*, **foto del festival** en la mochila, 10 $.
12. **Conexión:** Lucía anuncia el último proyecto de primaria.

## 11.21 Misión 11 — «El proyecto final» (implementada)

1. **Objetivo narrativo:** trabajar en equipo de verdad: repartir, discutir y arreglar lo que se rompe.
2. **Duración:** 25–35 min.
3. **NPC:** Lucía, Omar (siempre en tu equipo), tu compañero elegido, Marisa, Ramón, {abu}, tu familia, Bruno.
4. **Lugares:** aula, biblioteca, conserjería, casa, fuente del parque, almacén, **librería** (compra real).
5. **Objetivos:** anuncio → compañero → **tema** (huerto, robot, mascotas o **museo del colegio**, este
   solo si abriste la sala cerrada) y **rol** (organizar, investigar, construir, presentar) → investigar
   (3 de 4 fuentes, cada una dice algo distinto según el tema) → materiales (cartón y cartulinas
   compradas en la librería) → discusión del equipo → montar la maqueta → **la noche antes, el hermano
   de Omar se sienta encima** → presentación delante de las familias → nota.
6. **Diálogos:** cada compañero, cada fuente según el tema, la discusión, el desastre, el resultado.
7. **Mecánicas:** paso `Event` de compra real; la maqueta bonita da 5 s más por pregunta (`Bonus`).
8. **Minijuegos:** montar la maqueta; la presentación son las preguntas del jurado (examen de Ciencias).
9. **Decisiones:** compañero, tema, rol, cómo resolver la discusión, qué hacer con la maqueta rota.
10. **Consecuencias:** con un 8 o más, `ProyectoPremiado` y **1 h de juego después sale en el periódico
    de Valmar** (`Eco_Periodico`, con una noticia distinta para cada tema).
11. **Recompensas:** recuerdo *ProyectoFinal*, **la maqueta** en la mochila, 10 $.
12. **Conexión:** «Queda una semana de colegio. La última.»

## 11.22 Misión 12 — «El último día» (implementada)

1. **Objetivo narrativo:** cerrar la infancia mirando atrás con lo que el jugador vivió de verdad.
2. **Duración:** 20–30 min.
3. **NPC:** todo el reparto del colegio y tu familia.
4. **Lugares:** casa, vestíbulo, tu pupitre, tu taquilla, el campo, la biblioteca, el almacén, el banco
   del patio, la sala cerrada.
5. **Objetivos:** mañana en casa → el cole por última vez → **despedirte de 4 de 6 sitios**: cada uno
   trae **flashbacks** que salen de tus decisiones y recuerdos (dónde te sentaste el primer día, Mateo,
   la mochila, la nota de Lucía, el partido, el torneo, el examen, Hugo, el nombre del grupo, tu sueño,
   Bigotes) → **se abre la cápsula del tiempo** (lo que metiste en la misión 09) → foto con tu grupo →
   ceremonia y diplomas → despedidas (Lucía, **Bruno según toda vuestra historia**, Ramón) → promesa
   del grupo → fin de primaria → instituto.
6. **Diálogos:** casi todas las líneas dependen de condiciones (`Memories`, `Flags`, `Choices`).
7. **Mecánicas:** los recuerdos como condiciones: lo que no viviste no aparece.
8. **Minijuegos:** ninguno: es un capítulo para sentir, no para superar.
9. **Decisiones:** qué sitios visitas; cómo te despides de Bruno (empezar de cero, suerte, seco);
   la promesa del grupo (`Choices.Promesa`, para el instituto).
10. **Consecuencias:** relaciones finales; `Choices.AdiosBruno` y `Choices.Promesa` las leerá el instituto.
11. **Recompensas:** recuerdo *UltimoDiaCole*, **diploma de primaria** y **llavero 13** de Ramón, 30 $.
12. **Conexión:** cinemáticas de fin de primaria y paso al instituto (etapa Adolescente).

## 11.23 El capítulo del instituto (diseño general)

**Qué cambia respecto al colegio:** las misiones maduran. Menos «encuentra el objeto», más decisiones
con dos lados buenos (club o cumpleaños, publicar o proteger), relaciones que se estiran (el grupo se
reparte en clases distintas) y el futuro asomando (profesiones, campus, primer dinero).

- **Reparto:** el grupo del colegio sigue (ahora adolescentes: `SceneService` hace crecer a los
  compañeros `Kid` según tu etapa) y llegan Javier (tutor), Carmen (orientadora), Leire (la nueva, con
  su cámara), un veterano, la delegada y ocho profesionales de Valmar.
- **Continuidad:** `Choices.Promesa` y `Choices.AdiosBruno` del último día cambian el primer día;
  `Choices.SuenoInfancia` (misión 03) aparece en la semana de las profesiones; el torneo, el festival o
  la sala cerrada se citan cuando toca.

| # | Misión | Duración | Núcleo | Estado |
|---|---|---|---|---|
| 01 | El nuevo instituto | 20–30 | Parada con tus amigos, bus al Campus, la broma del veterano, tu aula, dónde te sientas, Leire sola | Hecha |
| 02 | Los clubes | 20–30 | Feria, cinco clubes con prueba distinta, el sábado: club, cumpleaños o las dos cosas | Hecha |
| 03 | ¿Qué quieres ser? | 25–35 | Ocho profesiones por la ciudad, 4 visitas, marcas `Interes_*`, orientación | Hecha |
| 04 | El primer empleo | 20–30 | Perfil, ofertas, entrevista (verdad o no), primera jornada con el sistema de trabajos, el primer sueldo | Hecha |
| 05 | El rumor | 25–35 | Una foto trucada de Omar en el grupo de clase: frenarla, investigar, Nico y Darío, consolar a Omar | Hecha |
| 06 | La gran decisión | 25–35 | Planes de los amigos, Carmen y tus `Interes_*`, puertas abiertas, selectividad, elegir estudios o trabajo, graduación | Hecha |

## 11.24 Instituto 01 — «El nuevo instituto» (implementada)

1. **Objetivo narrativo:** empezar de nuevo sin empezar de cero: los amigos siguen, pero ya no está todo junto.
2. **Duración:** 20–30 min.
3. **NPC:** familia y {abu}, Nico, Omar, Sara, Mateo, Hugo, Iker, el veterano, la delegada, Javier, Leire, Bruno.
4. **Lugares:** casa, parada del bus, el instituto (Campus Valmar), aula de 1.º C, patio del instituto.
5. **Objetivos:** mañana en casa → la parada (qué habéis crecido; la promesa del último día) → **viaje en
   bus de verdad** (evento `Traveled`) → la broma del «ascensor de alumnos» (creer o preguntar a la
   delegada) → buscar tu clase en el tablón → Javier y la clase → **dónde te sientas** (Omar, Leire o
   Bruno si os despedisteis «de cero») → Historia → recreo: el grupo se reparte → **Leire come sola**
   (si no te acercas en 60 s, no pasa nada… hasta dentro de 2 h) → Matemáticas → cena.
6. **Diálogos:** familia, la parada, el veterano, Javier, cada asiento, el recreo, Leire, la cena.
7. **Mecánicas:** viaje entre ciudades, retraso (`Late`: llegas tarde al aula), `Timeout` en Leire.
8. **Minijuegos:** ninguno nuevo (las dos clases del día).
9. **Decisiones:** ir con tu familia o por tu cuenta; creer al veterano; sitio; qué hacer en el recreo; Leire.
10. **Consecuencias:** 2 h después, `Eco_Leire` (te regala una foto) o `Eco_LeireSola` (segunda oportunidad).
11. **Recompensas:** recuerdo *PrimerDiaInstituto*, **carnet del instituto**.
12. **Conexión:** la feria de clubes.

## 11.25 Instituto 02 — «Los clubes» (implementada)

1. **Objetivo narrativo:** elegir algo tuyo, no lo de tus amigos, y aprender que comprometerse cuesta.
2. **Duración:** 20–30 min.
3. **NPC:** Javier, Álex (baloncesto), Rubén (teatro), Sara (robótica), Hugo (periódico), Leire (fotografía),
   Vega, el veterano, la delegada, Omar, Nico.
4. **Lugares:** patio y pista del instituto, aula, el campus (universidad, biblioteca, estadio), el parque.
5. **Objetivos:** feria (3 de 5 puestos) → **eliges club** → prueba distinta en cada uno: tiros (titular o
   suplente), audición, **el robot Tornillo se escapa** y lo persigues, **¿quién pinta los murales?**
   (pistas y un dilema periodístico), paseo fotográfico por el campus → **el sábado**: el primer evento
   del club coincide con el cumpleaños de Nico.
6. **Diálogos:** cada puesto, cada prueba, Vega, el dilema, el evento del club, el cumpleaños.
7. **Mecánicas:** cinco caminos; el camino «las dos cosas» tiene un límite de tiempo (`Late`: llegas tarde a la tarta).
8. **Minijuegos:** tiros, audición, programar el robot.
9. **Decisiones:** club; publicar el nombre de Vega, protegerla o convencerla para pedir permiso; el sábado.
10. **Consecuencias:** relaciones (Vega, Hugo, Nico), marcas `ClubTitular`/`ClubSuplente`, `Choices.Club`,
    `Choices.Reportaje`, `Choices.Sabado`.
11. **Recompensas:** recuerdo *PrimerClub*, **insignia del club**.
12. **Conexión:** la orientadora anuncia la semana de las profesiones.

## 11.26 Instituto 03 — «¿Qué quieres ser?» (implementada)

1. **Objetivo narrativo:** descubrir posibilidades sin obligar a elegir (lo pedía el encargo).
2. **Duración:** 25–35 min (cuatro trayectos por la ciudad, algunos en bus).
3. **NPC:** Carmen, Javier, Omar, Leire, Bruno, Nico y ocho profesionales: Nuria (hospital), Sofía
   (laboratorio de ingeniería), Inés (comisaría), Marcos (empresa), Tomás (taller), Lola (cocina),
   Irene (estadio) y Toni (audiovisual).
4. **Lugares:** hospital, facultad de ingeniería, comisaría, oficinas del distrito financiero,
   gasolinera, cafetería del centro, estadio universitario, cine.
5. **Objetivos:** Carmen explica la semana → **visitar 4 de 8** → en cada uno, una situación real del
   trabajo (un niño asustado, un puente de palillos, dos vecinos y una maceta, cien bicis rojas, un
   motor que no arranca, cuatro mesas a la vez, una atleta lesionada, dónde poner la cámara) → **¿te ves
   haciendo esto?** → vuelta con Carmen.
6. **Diálogos:** cada profesional tiene su voz; si tu **sueño de la infancia** coincide, aparece un recuerdo.
7. **Mecánicas:** exploración de la ciudad; marcas `Interes_*` (Medicina, Ingenieria, Derecho,
   Economia, Oficio, Cocina, Deporte, Audiovisual).
8. **Minijuegos:** ninguno: aquí las decisiones son el juego.
9. **Decisiones:** qué visitas; qué haces en cada situación; cómo sales (`Choices.Orientacion`).
10. **Consecuencias:** Carmen repasa lo que te gustó; las `Interes_*` las leerá «La gran decisión».
11. **Recompensas:** recuerdo *QueQuieresSer*, **cuaderno de profesiones**.
12. **Conexión:** el primer empleo del verano.

## 11.27 Instituto 04 — «El primer empleo» (implementada)

1. **Objetivo narrativo:** el primer dinero ganado por ti; la honestidad en el trabajo.
2. **Duración:** 20–30 min.
3. **NPC:** familia y {abu}, Carmen, Omar, Lola (cafetería), Paco (supermercado), Ernesto (Correos), Bruno, Leire.
4. **Lugares:** casa, instituto, Cafetería Central, supermercado, Correos.
5. **Objetivos:** qué quieres conseguir (bici, cámara, ayudar en casa, ahorrar) → **perfil laboral** con
   Carmen → **buscar ofertas** (2 de 3 carteles) → elegir → **entrevista** (decir la verdad o adornarla)
   → primer día (llegar puntual: `Late`) → **la jornada con el sistema de trabajos real** (`JobTaskDone`,
   2 + 2 tareas) con un **imprevisto** a mitad (la bandeja delante de Bruno, las latas, Leire en pijama)
   → el primer sueldo y qué haces con él.
6. **Diálogos:** cada jefe tiene su personalidad; si mentiste, el primer día te lo recuerdan.
7. **Mecánicas:** conecta con `JobService` (tablones de trabajo) y la economía (50 $ de sueldo).
8. **Minijuegos:** el propio trabajo (recoger y entregar).
9. **Decisiones:** meta, perfil, empleo, verdad o mentira, cómo encajas el error, qué haces con el dinero.
10. **Consecuencias:** si no mentiste, 3 h después llega una **carta de recomendación** (`Eco_Carta`).
11. **Recompensas:** recuerdo *PrimerSueldo*, **el sobre del primer sueldo**, 50 $.
12. **Conexión:** un año después, el grupo de clase se incendia.

## 11.28 Instituto 05 — «El rumor» (implementada)

1. **Objetivo narrativo:** el acoso en redes sin dramatizarlo: quien lo hace, quien lo comparte y quien
   lo frena. Y que pedir ayuda a un adulto no es chivarse.
2. **Duración:** 25–35 min.
3. **NPC:** Javier, Sara, Leire, Nico, Bruno, Darío (de segundo), Omar.
4. **Lugares:** aula, patio, pista del instituto, el banco del parque.
5. **Objetivos:** la foto trucada de Omar en el grupo de clase (**frenarla, callar o reírte**) →
   investigar (3 de 4: la captura —la compartió Nico—, Leire y el ángulo, **Bruno, a quien todos culpan**,
   la grada) → Darío y Nico en la pista → Omar en el banco → el día después.
6. **Diálogos:** Bruno recuerda si le acusaste sin pruebas en el colegio; Omar, si en el grupo diste la cara.
7. **Mecánicas:** investigación; opciones de diálogo que solo aparecen si hiciste algo antes.
8. **Minijuegos:** ninguno: es una misión de personajes.
9. **Decisiones:** qué haces con la foto; confiar en Bruno; hablar con Nico en privado o en público;
   Darío (pedirle que la borre, contarlo a Javier o devolvérsela: esto último sale mal).
10. **Consecuencias:** relaciones; 3 h después, `Eco_Nico` (distinto según cómo le hablaste).
11. **Recompensas:** recuerdo *ElRumor*, **la pulsera del grupo** de Omar.
12. **Conexión:** dos años después, el último curso.

## 11.29 Instituto 06 — «La gran decisión» (implementada)

1. **Objetivo narrativo:** elegir tu camino sabiendo que nadie se queda donde empieza.
2. **Duración:** 25–35 min.
3. **NPC:** todo el grupo (cada uno con su plan), Carmen, Sofía, Javier, familia y {abu}.
4. **Lugares:** patio del instituto, aula, universidad, biblioteca del campus, casa.
5. **Objetivos:** los planes de tus amigos (3 de hasta 8) → Carmen repasa **tus `Interes_*`** y tu
   primer trabajo → puertas abiertas → estudiar → **selectividad** (5 s más por pregunta si estudiaste)
   → la noche en casa ({abu} cuenta lo que no pudo ser) → **LA DECISIÓN** (`Choices.Estudios`: Medicina,
   Ingeniería, Derecho, Economía o trabajar) → graduación y orla → etapa AdultoJoven.
6. **Diálogos:** casi todo depende de lo vivido en el instituto (rumor, clubes, profesiones, sueldo).
7. **Mecánicas:** examen con `Bonus`; la decisión es la misma que usa la universidad (`Subjects`).
8. **Minijuegos:** el examen de selectividad.
9. **Decisiones:** los estudios o trabajar.
10. **Consecuencias:** marca `VaALaUniversidad` o `EmpiezaATrabajar`; la universidad usa tu carrera.
11. **Recompensas:** recuerdo *LaGranDecision*, **la orla del instituto**.
12. **Conexión:** cinemática de selectividad y primer día de universidad (o de vida adulta).

## 11.30 El capítulo de la universidad (diseño general)

Todo gira alrededor de **tu carrera** (`Choices.Estudios`): los lugares y asignaturas se escriben como
`"$Carrera.Facultad"`, `"$Carrera.Asignatura1"`… y el motor los cambia por los de tu carrera, **también
para los personajes y objetos de las escenas**. Reparto nuevo: la profesora Beltrán, Luca (Erasmus),
el grupo cuatro (Julia, Pablo, Adrián, Carla), Rocío y Alba. Los amigos de siempre siguen apareciendo
(Sara en el campus, Omar en la cafetería con Lola, Mateo si estudia Ingeniería contigo, mensajes de Nico,
Leire y Hugo).

| # | Misión | Duración | Núcleo | Estado |
|---|---|---|---|---|
| 01 | Primer día en el campus | 20–30 | El reloj de {abu}, bus, Luca, secretaría, tu facultad, Beltrán, 1.ª clase, descubrir el campus, con quién comes | Hecha |
| 02 | El proyecto | 25–40 | Un grupo con personalidades: gestionar, descubrir qué le pasa a cada uno, reorganizar, presentar | Hecha |
| 03 | El primer trabajo | 20–30 | Perfil (la carta de recomendación sirve), ofertas, cafetería / reparto / clases a Alba, decir que no a tiempo | Hecha |
| 04 | Las prácticas | 30–40 | Según la carrera: hospital, TecnoVal, bufete, banco; un caso propio y un error en tu informe | Hecha |
| 05 | Tu primer piso | 20–30 | Independizarte con el sistema de casas real, la mudanza, la convivencia, {abu} de visita | Hecha |
| 06 | La graduación | 25–35 | Examen final, prepararte, ceremonia, diploma, foto y un brindis con los recuerdos de toda tu vida | Hecha |

## 11.31 Universidad 01 — «Primer día en el campus» (implementada)

1. **Objetivo:** aprender a moverse por un campus grande y sentir que empieza otra vida.
2. **Duración:** 20–30 min. 3. **NPC:** familia, {abu}, Luca, Sara, Beltrán, Julia, Adrián, Carla, Mateo (si estudia contigo), Álex.
4. **Lugares:** casa, bus, universidad, **tu facultad**, biblioteca, cafetería, estadio.
5. **Objetivos:** despedida ({abu} te da su **reloj**) → bus → Luca → **horario** en secretaría → encontrar tu
   facultad → Beltrán y la clase → **1.ª clase** → descubrir 2 de 3 (biblioteca, cafetería, deportes) →
   con quién comes (Luca, Sara, la clase o a tu aire) → mensajes del grupo de siempre.
6–9. Diálogos según tu carrera y tu pasado (club, rumor, Mateo); decisiones: el abrazo, con quién comes.
10. **Consecuencias:** relaciones con el reparto nuevo. 11. **Recompensas:** *PrimerDiaUni*, carnet universitario, el reloj.
12. **Conexión:** Beltrán ya avisó de los trabajos en grupo.

## 11.32 Universidad 02 — «El proyecto» (implementada)

1. **Objetivo:** gestionar un grupo real: detrás de cada «vago» o «mandón» hay una razón.
2. **Duración:** 25–40 min. 3. **NPC:** Beltrán, Julia (lo hace todo), Pablo (no aparece), Adrián (quiere mandar), Carla (llega tarde).
4. **Lugares:** tu facultad, biblioteca, parque, plaza del centro.
5. **Objetivos:** el encargo (tema según tu carrera) → primera reunión desastrosa → **cómo lo gestionas**:
   hacerlo todo, repartir, hablar con la profesora, **pedir cambiar de grupo (no se puede: vuelves a
   elegir)** o hablar con cada uno → **conocer a cada uno**: Julia tiene miedo a fallar, Adrián una beca,
   Carla cuida de su hermano, Pablo quiere hacer música → **reorganizar** (la opción «cada uno en lo suyo»
   solo aparece si ayudaste a Adrián, Carla y Pablo) → trabajar (una noche más si lo haces todo: menos
   energía) → ensayo → presentación.
7. **Mecánicas:** opción `Stay`, opción de diálogo que exige tres marcas, `Bonus` si `EquipoUnido`.
10. **Consecuencias:** relaciones; `HacesTodo` o `EquipoUnido`; si animaste a Pablo, **3 h después su primer concierto** (`Eco_Concierto`).
11. **Recompensas:** *ElProyectoUni*, foto del grupo cuatro. 12. **Conexión:** la cuesta de enero.

## 11.33 Universidad 03 — «El primer trabajo» (implementada)

1. **Objetivo:** trabajar y estudiar a la vez; aprender a decir que no.
2. **Duración:** 20–30 min. 3. **NPC:** familia, Lola y Omar, Ernesto, Rocío y Alba (9 años), Beltrán.
4. **Lugares:** casa, biblioteca del campus, Cafetería Central, Correos, tu facultad.
5. **Objetivos:** las cuentas → **perfil de empleo** (la carta de recomendación del instituto «valía oro»)
   → ofertas (2 de 3) → elegir (**cafetería**, **reparto** con el sistema de trabajos de verdad, o **clases
   particulares a Alba**: fracciones con dinosaurios) → primer día (puntual) → la jornada → **el conflicto**:
   te piden cubrir un turno la víspera de un examen → examen (5 s más si no cubriste) → primera nómina.
9. **Decisiones:** trabajo, cómo enseñas, cubrir / decir que no / (en la cafetería) proponer a Omar.
10. **Consecuencias:** dinero extra o mejor examen; relaciones con jefes y con Alba.
11. **Recompensas:** *PrimerTrabajoUni*, tu primer contrato, 120 $. 12. **Conexión:** las prácticas de tu carrera.

## 11.34 Universidad 04 — «Las prácticas» (implementada)

1. **Objetivo:** lo que estudias, en el mundo real; y la honestidad profesional.
2. **Duración:** 30–40 min. 3. **NPC (según carrera):** Nuria (Medicina, hospital), Sofía (Ingeniería,
   TecnoVal), Montse (Derecho, bufete), Ignacio (Economía, banco); un paciente, un vecino o Marcos.
4. **Lugares:** `"$Carrera.LugarPracticas"`.
5. **Objetivos:** primer día (puntual) → primera jornada (clase de prácticas) → **el caso** (tres tareas propias
   de cada carrera: un dolor en el pecho que es ardor, una pasarela que vibra, una multa injusta, un préstamo
   para las bicis de Marcos) → **un error tuyo en el informe** → segunda jornada → evaluación.
7. **Mecánicas:** objetos con `If` por carrera; `Bonus` si confiesas el error.
9. **Decisiones:** decirlo, corregirlo en silencio o dejarlo.
10. **Consecuencias:** si lo dices y trabajas bien, `OfertaTrabajo` (Beltrán lo menciona en la graduación).
11. **Recompensas:** *Practicas*, informe de prácticas, 150 $. 12. **Conexión:** es hora de independizarse.

## 11.35 Universidad 05 — «Tu primer piso» (implementada)

1. **Objetivo:** irse de casa sin irse del todo. 2. **Duración:** 20–30 min.
3. **NPC:** familia, {abu}, Sara o Luca (o a tu aire). 4. **Lugares:** casa familiar, campus, **tu casa nueva**.
5. **Objetivos:** la conversación en casa → con quién vives → **quedarte una casa de verdad** (`HomeClaimed`)
   → la mudanza (la caja «NO ABRIR» con tu primera mochila y una carta) → **primera cena** (`Ate`) → la
   primera noche (convivencia o silencio) → {abu} trae una planta → **dormir en tu cama** (`Slept`).
7. **Mecánicas:** conecta con el sistema de casas, la comida y el sueño. Deja `TieneHogar`: la vida adulta
   ya no te pide buscar casa (`Adulto_LlegadaValmar` se salta ese paso).
11. **Recompensas:** *PrimerPiso*, las llaves. 12. **Conexión:** llega junio del último curso.

## 11.36 Universidad 06 — «La graduación» (implementada)

1. **Objetivo:** el cierre de toda la campaña: «me acuerdo de cómo empezó mi vida».
2. **Duración:** 25–35 min. 3. **NPC:** Beltrán, el grupo cuatro, Luca, familia, {abu}, Lola, Omar, Sara,
   Nico, Leire, Mateo, Hugo, Bruno. 4. **Lugares:** biblioteca, tu facultad, Cafetería Central.
5. **Objetivos:** último repaso y examen → la nota → **qué te pones** (hasta la sudadera de dinosaurios) →
   saludar a 3 de 5 → **ceremonia y diploma** → cinemática → foto → **el brindis**: cada amigo recuerda algo
   que viviste de verdad (primer día, Mateo, la mochila, el torneo, la sala cerrada, el festival, el examen,
   Leire, el rumor, Bruno, el primer sueldo, {abu}) → «Has terminado tu etapa universitaria».
10. **Consecuencias:** título de tu carrera con tu nota media (`Degree`), marca `Graduado`.
11. **Recompensas:** *Graduacion*, orla de la universidad, 500 $. 12. **Conexión:** la vida adulta.

## 11.37 El capítulo «Volar del nido» (diseño general)

Continúa la vida del jugador después del instituto, por los dos caminos: con carrera (`Graduado`) o
trabajando (`EmpiezaATrabajar`). Tono: adulto pero cálido; lo importante sigue siendo la gente. Recoge lo
que el encargo pedía para esta edad ([05](05-misiones-eventos.md): primer contrato, facturas, carnet) y
cierra los arcos de {abu} y del grupo.

| # | Misión | Duración | Núcleo | Estado |
|---|---|---|---|---|
| 01 | Mi primer contrato | 20–30 | Trabajo de tu carrera (o ascenso en tu trabajo del instituto), primer caso o turno de responsable, primeras facturas | Hecha |
| 02 | Un atardecer junto al mar | 20–30 | {abu} en el hospital, el carnet de coche (o el bus), la playa, una promesa | Hecha |
| 03 | El reencuentro | 25–35 | Lola se jubila y Omar reabre la cafetería: invitar al grupo, Lucía directora, la tortilla, el banco del parque | Hecha |

## 11.38 Vida adulta 01 — «Mi primer contrato» (implementada)

1. **Objetivo:** el primer trabajo de verdad y el primer contacto con las facturas.
2. **Duración:** 20–30 min. 3. **NPC:** tu tutor de prácticas (Nuria, Sofía, Montse, Ignacio) o tu jefe del primer verano (Lola, Paco, Ernesto), Omar, Ignacio, familia.
4. **Lugares:** `$Carrera.LugarPracticas` o la cafetería / supermercado / Correos; el banco.
5. **Objetivos:** (sin carrera y sin casa: buscar casa) → primer día → **con carrera**: primer caso propio
   (pedir consejo o lanzarte) / **sin carrera**: te ascienden a encargado/a y haces el turno (JobService) →
   final de mes: **las facturas** (pagar, dejarlo para luego o hacer un presupuesto con Ignacio) → llamada:
   {abu} no está bien.
10. **Consecuencias:** si dejas las facturas, **2 h después llega un aviso con recargo** (`Eco_Factura`).
11. **Recompensas:** *PrimerContrato*, la primera nómina, 200 $, `TieneHogar`.

## 11.39 Vida adulta 02 — «Un atardecer junto al mar» (implementada)

1. **Objetivo:** devolver a {abu} lo que te dio; un capítulo tranquilo y emotivo (sin dramas: una caída sin gravedad).
2. **Duración:** 20–30 min. 3. **NPC:** {abu}, Nuria, familia. 4. **Lugares:** hospital, autoescuela o parada de bus, Playa Dorada.
5. **Objetivos:** la llamada → el hospital → **cómo le llevas al mar**: sacarte el carnet (`LicenseEarned`) y
   que tu familia te preste el coche, o en autobús como hacía {abu} (`Traveled`) → la playa ({abu} recuerda
   tu vida; si llueve o es invierno, lo dice) → una concha → **la promesa** → cinemática del atardecer.
7. **Mecánicas:** conecta con la autoescuela o el autobús; líneas según el tiempo y la estación.
11. **Recompensas:** *AtardecerConAbu*, la concha. 12. **Conexión:** Omar tiene una noticia.

## 11.40 Vida adulta 03 — «El reencuentro» (implementada)

1. **Objetivo:** ver en qué se ha convertido cada uno y cerrar la promesa del último día de colegio.
2. **Duración:** 25–35 min. 3. **NPC:** Omar, Lola, Nico (futbolista), Sara (bióloga), Bruno (policía), Leire (cineasta), Hugo (escritor), Mateo (ingeniero), Lucía (directora), familia.
4. **Lugares:** Cafetería Central, estadio de Altamar, universidad, comisaría, cine, biblioteca, distrito financiero, colegio, parque.
5. **Objetivos:** Lola se jubila y le deja la cafetería a Omar → **invitar al grupo** (3 de hasta 6, cada uno
   en su sitio de la ciudad) → **Lucía**: si tu carrera coincide con tu sueño de niño, se lo cuentas → la
   tortilla perfecta (minijuego) → inauguración y discurso de Lola → foto → **el banco del parque** (la
   promesa del último día, cumplida) → una promesa nueva.
10. **Consecuencias:** `PromesaAdulta`, `CharlaColegio` (para una misión futura en el colegio).
11. **Recompensas:** *ElReencuentro*, la foto del reencuentro.

## 11.41 El arco «La pandilla»: el bien o el mal (adolescencia)

**Por qué:** el jugador tiene que poder elegir quién quiere ser, también «el malo», y que eso tenga
consecuencias durante toda su vida. Tres misiones insertadas en el instituto (entre «¿Qué quieres ser?» y
«El rumor»), tres consecuencias diferidas y reacciones en misiones posteriores.

**Reglas de contenido (Roblox):** delitos menores y sin violencia (hacer pellas, pintadas, un hurto en un
súper, vender camisetas falsas, llevar una furgoneta con mercancía robada). Nunca se glorifica: el mal
camino da dinero rápido y popularidad, pero siempre trae consecuencias (policía, familia, amigos) y
**siempre hay salida** (redención en cualquier momento, también de adulto).

**Sistema:**
- Rasgo nuevo **`Rebeldia`** (se suma con las malas decisiones) + marcas `Camino_Delincuente`,
  `Camino_Trabajador`, `Redimido`, `Hurto`, `AvisoPolicia`, `Antecedentes`, `Detenido`, `RayoCambia`.
- **Reputación** (`LifeStoryService.updateCamino`): atributo del jugador `Camino` = `Responsable`,
  `Gamberro` (Rebeldía ≥ 3) o `Delincuente`, con un aviso en pantalla cuando cambia.
- Condiciones nuevas: `TraitsBelow`, `NotChoices`.

| # | Misión | Qué pasa | Decisiones |
|---|---|---|---|
| P1 | Las malas compañías | Rayo (el popular de 4.º) y Nerea te invitan a hacer pellas | Ir (recreativos, pintada en el muro, mentir en casa) · volver a clase · convencer a Nerea |
| P2 | La noche del supermercado | El plan de colarse en el almacén del súper de Paco | Ir (coger o no; si coges, alarma y **huida con tiempo límite**: si te pillan, comisaría y **servicio a la comunidad en el Punto Limpio** con el sistema de trabajos) · no ir · intentar frenarles |
| P3 | El cruce de caminos | Rayo ofrece vender camisetas falsas; Nerea quiere salir | **Negocio** (Camino_Delincuente; en el estadio te ve Nico: aún puedes echarte atrás) · **alejarte** y llevar a Nerea a un taller de cómic · **salvar a Rayo** (Tomás le da una oportunidad en su taller) |

**Consecuencias diferidas:** `Eco_Camaras` (2 h, si robaste y escapaste: la policía en tu puerta),
`Eco_Redada` (3 h, si entraste en el negocio: multa y expediente), `Eco_RayoAdulto` (ya de adulto):
Rayo con su propio taller si le salvaste · «un último trabajo» si seguiste en el mal camino (aceptar →
**en el control de policía está Bruno**; colaborar te redime) · una disculpa si solo le acompañaste.

**Reacciones en otras misiones:** Paco en la entrevista del primer empleo, Carmen y Bruno en «La gran
decisión», Lola y tu primer contrato (expediente), Bruno en «El reencuentro» si te detuvo.
