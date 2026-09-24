# 10 — LifeStorySystem: la vida como campaña (documento técnico)

> **La ciudad es la historia.** La campaña principal no es una lista de misiones pegada encima del juego:
> es la vida del personaje (nacer, crecer, estudiar, graduarse, empezar a trabajar), contada con los mismos
> sistemas con los que se juega: el reloj, los lugares, los trabajos, las personas y las decisiones.

Este documento analiza el proyecto actual, define la arquitectura del sistema y el plan por fases.
Las **fases 1 y 2 ya están programadas** (ver 10.13 y 10.16). Complementa a [04 — Primeros 30 minutos](04-primeros-30-minutos.md),
[05 — Misiones y eventos](05-misiones-eventos.md) y a la [Fase 8 — Educación](../diseno/08-educacion.md) del diseño.

> **Nombre.** El encargo habla de *NovaLife*; en el código y en los documentos el juego se llama *Real Life Simulator*
> (región de Valmar). Es el mismo proyecto: si se cambia el nombre, basta con cambiar `Config.GameName` y los textos.

## 10.1 Sistemas existentes que se reutilizan

Estado real del código (v0.1) comparado con los sistemas que pide la campaña:

| Sistema pedido | Qué hay hoy | Cómo lo usa la historia |
|---|---|---|
| **DataSystem** | ✅ `DataService`: guardado con bloqueo de sesión, autoguardado, plantilla que se completa sola | Guarda `Life` y `Story` (nuevos campos, se añaden solos a los jugadores antiguos) |
| **TimeSystem** | ✅ `WorldService` mueve el reloj (1 día = `Config.DayLengthMinutes`) y cuenta días · 🆕 `GameClock` | Hora, día de la semana, mes y año para horarios y esperas |
| **EconomySystem** | 🟡 `DataService.addMoney/spend` (el libro contable de la Fase 5 aún no existe) | Recompensas de dinero |
| **ProfessionSystem** | 🟡 `JobService`: 4 trabajos de ruta · 🆕 `RoleService` | Los trabajos avisan a la historia y marcan quién está de servicio |
| **LocationSystem** | 🆕 `LocationService`: encuentra colegios, parques, estadios… en el mapa **sin modificarlo** | Objetivos "ve a…", descubrimiento de zonas |
| **HouseService / NeedsService / FoodService / TravelService** | ✅ Casa, hambre y energía, comer, autobús entre zonas | Emiten eventos (`HomeClaimed`, `Ate`, `Slept`, `Traveled`) |
| **Interfaz** | ✅ HUD, línea guía (`TaskMarker`) | La línea guía también lleva al siguiente paso de tu vida |
| **NPCSystem** | ❌ Solo peatones decorativos en el cliente (`Ambient`) | Fase 2+: NPC con nombre, diálogo y memoria |
| **EducationSystem** | ❌ Hay edificios (colegio, facultades), pero no clases | Fases 5, 8, 10, 12 |
| **RelationshipSystem** | ❌ · 🆕 base: memoria de NPC en `Story.NpcMemory` | Fase 7 |
| **InventorySystem** | ❌ | Fase 4+ (material escolar, objetos de misiones) |

## 10.2 Sistemas que hay que crear

| Sistema | Qué hace | Fase |
|---|---|---|
| **LifeStoryService** 🆕 | Capa narrativa: capítulos, misiones principales y secundarias, decisiones, momentos, biografía | 1 ✅ |
| **StoryEvents** 🆕 | Tablón de avisos: cualquier sistema informa de lo que hace el jugador | 1 ✅ |
| **GameClock** 🆕 | Calendario (hora, día, semana, mes, año) | 1 ✅ |
| **LocationService** 🆕 | Lugares de la ciudad y zonas | 1 ✅ |
| **RoleService** 🆕 | Quién cubre cada puesto: jugador de servicio o NPC | 1 ✅ (base) |
| **LifeService** (edad) | Edad por tiempo jugado, cumpleaños, escala del personaje por etapa, límites por etapa | 2–3 |
| **NPCService + DialogueService** | NPC con nombre, horarios, diálogos con condiciones y memoria | 2 |
| **SchoolService / EducationService** | Horario escolar, clases como actividades, notas, asistencia, exámenes | 4–5, 8 |
| **ActivityEngine** | Minijuegos de clase (quiz, música, deporte…) reutilizables también en trabajos ([Fase 7](../diseno/07-profesiones.md)) | 5 |
| **RelationshipService** | Amistad, confianza, reputación entre jugadores y con NPC | 7 |
| **EventDirector** | Eventos aleatorios de colegio y ciudad (excursión, clase cancelada, competición) | 7+ |
| **LifeHistoryService** | La biografía en el teléfono (lee `Story.Events`) | 9+ |

## 10.3 Dependencias

```
            DataService ─────────────┐
            WorldService → GameClock ┤
  JobService ─┬─ RoleService ────────┤
  Food/House/Travel ─┐               │
                     ▼               ▼
                 StoryEvents ──► LifeStoryService ◄── LocationService (lee el mapa)
                                     │   ▲
                         Remote "LifeStory" (estado, momentos, decisiones)
                                     ▼   │
                         Cliente: LifeStory (tarjeta, pantallas) + TaskMarker (línea guía)

  Próximas fases que se enchufan igual (emiten eventos y leen el estado):
  LifeService · NPCService/DialogueService · SchoolService · RelationshipService · EventDirector
```

Regla: **LifeStoryService no duplica sistemas.** No paga sueldos, no mueve el reloj, no da clases:
escucha lo que pasa (`StoryEvents`) y decide si eso es un momento de tu vida.

## 10.4 Arquitectura

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| Definiciones (datos) | `src/shared/LifeStory/Chapters.luau`, `Quests.luau`, `Locations.luau`, `Strings.luau`, `src/shared/Roles.luau` | Todo el contenido: capítulos, misiones, lugares, textos, puestos |
| Reglas puras | `src/shared/LifeStory/Conditions.luau`, `Stages.luau`, `src/shared/GameClock.luau` | Requisitos, etapas y calendario (se prueban fuera de Roblox) |
| Validador | `src/shared/LifeStory/Validate.luau` | Al arrancar avisa en Output de textos, lugares o misiones mal escritos |
| Motor | `src/server/Services/LifeStoryService.luau` | Elige capítulo, arranca misiones, avanza pasos, recompensa, guarda biografía |
| Eventos | `src/server/LifeStory/StoryEvents.luau` | Avisos de los demás sistemas |
| Lugares | `src/server/Services/LocationService.luau` | Resuelve "el colegio más cercano a tu casa" y "¿en qué zona estás?" |
| Puestos | `src/server/Services/RoleService.luau` | Jugador de servicio o NPC |
| Cliente | `src/client/Controllers/LifeStory.luau`, `TaskMarker.luau` | Dibuja lo que manda el servidor; envía decisiones (validadas) |
| Pruebas | `scripts/test-lifestory.luau` | Simula vidas completas con Lune |

Las definiciones pedidas se reparten así: *QuestDefinitions* → `Quests.luau`; *ChapterDefinitions* → `Chapters.luau`;
*DialogueDefinitions* → `Strings.luau` hoy y `Dialogues.luau` en la fase 2; *NPCDefinitions*, *SchoolDefinitions*,
*EducationDefinitions* y *EventDefinitions* → nuevos archivos en `src/shared/LifeStory/` en sus fases (formato en 10.8–10.11).

**Seguridad:** el cliente solo puede pedir "Sync", "Choose" (una opción que el servidor comprueba que existe en el paso
actual), "Offer" (aceptar o rechazar lo que se le ofreció) y "Track" (qué misión ver). Con límite de frecuencia.

## 10.5 Estructura de datos (lo que se guarda)

```lua
Life = { Stage = "Adulto", AgeYears = 22 }     -- la edad de verdad llegará con LifeService
Story = {
	Version = 1,
	Chapter = "Adulto_NuevaVida",               -- capítulo actual
	Chapters = { [chapterId] = os.time() },      -- capítulos terminados
	Active = { [questId] = { Step, Count, Sub, WaitUntil, Started, Kind } },
	Completed = { [questId] = os.time() },       -- misiones terminadas (la última vez, si se repiten)
	Declined = { [questId] = os.time() },        -- secundarias rechazadas (se vuelven a ofrecer más tarde)
	Choices = { [clave] = { V = "Medicina", D = díaDelJuego } },   -- grandes decisiones
	Flags = { TieneHogar = true },               -- marcas que abren contenido
	Discovered = { Colegio = true, ["Zone:San Roque"] = true },   -- lugares y zonas conocidos
	NpcMemory = { [npcId] = { Affinity = 0..5, Facts = { [hecho] = día } } },
	Events = { { K = claveDeTexto, A = variables, Y = "Moment"|"Choice"|"Chapter"|"Stage"|"Place", S = etapa, D = día, T = os.time() } },
	Tracked = questId,                           -- la que se ve en la tarjeta
}
```

`Story.Events` es la **biografía**: con ella LifeHistoryService podrá escribir "Infancia: primer amigo, Nico.
Adolescencia: equipo de fútbol, primer trabajo. Universidad: Ingeniería…". Se guarda como claves de texto, así la
biografía también se traduce. Tamaño limitado (`Config.LifeStory.MaxLifeEvents`).

Campos que añadirán las próximas fases (en la misma lógica): `Education = { Subjects = { [asignatura] = { Level,
Grade, Attendance, Knowledge, XP } }, Courses, Degrees }`, `Relationships = { [personaId] = { Friendship, Trust } }`,
`CareerHistory` (ya previsto en el esquema de la [Fase 4](../diseno/04-datos.md)).

## 10.6 Flujo de la campaña

| Capítulo (Id) | Etapa | Contenido | Fase |
|---|---|---|---|
| `Bebe_PrimerosPasos` | Bebé | Aprende a caminar → explora tu casa → conoce a tu familia → asómate a la ventana → *"Han pasado varios años…"* | 2–3 (datos listos) |
| `Nino_ElColegio` | Niño | Primer día de colegio → clases → recreo → amigos → primer examen | 4–8 (primer día listo en datos) |
| `Nino_Aventuras` | Niño | Excursiones, deporte, música, recados por el barrio (material escolar, farmacia, parque) | 7–8 |
| `Adolescente_Instituto` | Adolescente | Nuevo instituto, compañeros, equipo, primer examen importante, torneo | 9–10 |
| `Adolescente_Futuro` | Adolescente | Primer trabajo de verano, visita a la universidad, carnet, **decidir qué estudiar** | 9–11 |
| `Joven_Universidad` / `Joven_FP` | Adulto joven | Facultad, asignaturas, biblioteca, clubes, residencia, exámenes, proyectos | 12 |
| `Joven_Practicas` | Adulto joven | Prácticas según la carrera: hospital, empresa, despacho… | 13 |
| `Joven_Graduacion` | Adulto joven | Ceremonia con compañeros, profesores, familia, fotos, diploma, música | 14 |
| `Adulto_QueHarasAhora` | Adulto joven | *"¿Qué harás ahora?"*: buscar trabajo, seguir estudiando, emprender, viajar, mudarse | 15 |
| `Nino_Puente` | Niño | **Puente temporal, jugable ya**: salir al parque, ver tu futuro colegio y salto en el tiempo hasta la vida adulta ("Pasan los años…") | 2 ✅ (se retira al llegar la fase 4) |
| `Adulto_NuevaVida` | Adulto joven | **Capítulo puente, jugable ya**: llegar a Valmar, conseguir casa, primer sueldo, elegir excursión | 1 ✅ |

Desde la fase 2, **todo personaje nuevo nace bebé** (`Config.LifeStory.NewCharacterStage`). Quien ya jugaba antes de la
historia de vida (tiene tiempo jugado guardado) sigue de adulto (`VeteranStage`). Mientras no exista la infancia
completa, la vida jugable hoy es: **bebé → un vistazo de niño → salto en el tiempo → vida adulta**.

**Nada bloquea para siempre:** las decisiones abren caminos pero no cierran otros (se puede volver a estudiar de adulto,
[Fase 8.2](../diseno/08-educacion.md)); si una misión necesita a otra persona y no hay jugadores, lo cubre un NPC.

## 10.7 Sistema de misiones

**Principales** (`Kind = "Main"`): una a la vez, en el orden del capítulo. Si solo falta que sea la hora
(p. ej. el colegio abre a las 7:00), la tarjeta dice *"Podrás seguir entre las 7:00 y las 15:00"* en lugar de bloquearse.

**Secundarias** (`Kind = "Side"`): hasta 3 a la vez. Aparecen solas según **dónde estás** (`Offer = { Place }`),
**lo que haces** (`Offer = { Event, Match }`), la **hora**, la **etapa**, las **marcas** y las **decisiones** anteriores.
Se ofrecen como una petición de alguien ("¿Me ayudas a buscar mi mochila?"); se pueden rechazar sin castigo.

**Pasos** (cada uno con su texto en la tarjeta):

| Tipo | Para qué | Ejemplo |
|---|---|---|
| `Reach` | Ir a un lugar real del mapa (con línea guía) | "Ve andando al colegio" |
| `Event` | Que pase algo en otro sistema, con contador | "Trabaja (2/3)", "Completa tu primera clase" |
| `Talk` | Hablar con alguien (NPC o jugador en un rol) | "Conoce a tu profesor" |
| `Group` | Varios objetivos en cualquier orden | "Explora la casa: salón ✓, cocina, habitación" |
| `Choice` | Una decisión que se guarda y abre ramas | "¿Qué quieres estudiar?" |
| `Wait` | Dejar pasar tiempo de juego | "Disfruta del atardecer" |
| `Moment` | Un momento narrativo a mitad de misión | — |
| `Transition` | Pantalla de paso del tiempo y cambio de etapa | "Han pasado varios años…" |

Cualquier paso admite `If = { requisitos }` para ramas ("si elegiste Medicina, ve al hospital"). Al terminar una misión
no sale "+100 XP": sale un **momento de vida** (`MomentKey`) que además se guarda en la biografía.

**Eventos aleatorios** (fase 7+): un `EventDirector` elegirá cada cierto tiempo, según la hora, la etapa y dónde hay
jugadores, eventos de `EventDefinitions` (compañero que pierde algo, clase cancelada, excursión, competición, fiesta
escolar, festival). Cada evento es una secundaria con `Offer` especial. Son sorpresas de juego: **nunca** azar con Robux.

**Contenido creado por jugadores:** un jugador profesor que programa un examen, o un entrenador que convoca
entrenamiento, emitirá un evento (`ExamScheduled`, `TrainingCalled`) y el sistema creará para sus alumnos o su equipo
una misión con hora y lugar ("Examen de matemáticas — mañana 9:00"). Si ese jugador se desconecta, la sustituye un NPC.

## 10.8 Sistema de diálogos (fase 2)

Los diálogos serán datos con condiciones y efectos, y los textos siempre claves traducibles
(ver [09 — Textos](09-textos-traduccion.md) y los diálogos de [08](08-dialogos.md)):

```lua
Dialogues.Abu_Primeros = {
	Npc = "Familia_Abu",
	Nodes = {
		{ Id = "Hola", TextKey = "DLG.ABU.PASOS.01", If = { NotFlags = { "YaCamina" } } },
		{ Id = "Recuerdo", TextKey = "DLG.ABU.MEM.SUENO", If = { Flags = { "TieneSueno" } } },
		{ Id = "Pregunta", TextKey = "DLG.ABU.SUENO.01",
			Options = { { TextKey = "DLG.ABU.SUENO.R1", Set = { Choice = { Sueno = "Bombero" } } }, ... } },
	},
	OnEnd = { Emit = "Talk" },   -- hablar con Abu cuenta para los pasos Talk
}
```

## 10.9 Sistema de NPC (fase 2)

Tres niveles de memoria, como pediste:

| Nivel | Ejemplos | Qué recuerda | Dónde se guarda |
|---|---|---|---|
| **NPC normal** | Peatones, clientes, alumnos de relleno | Nada, o la conversación en curso | En memoria del servidor |
| **NPC importante** | Profesores NPC, vecinos con nombre, compañeros de clase | Hechos puntuales ("me ayudaste con los deberes") | `Story.NpcMemory[npc].Facts` |
| **Personaje principal** | Abu, Lucía, Nico, Sara, Omar, Don Ernesto… ([02](02-personajes.md)) | Hechos + afinidad 0–5 + decisiones tuyas (tu sueño, tus estudios) | `Story.NpcMemory` + `Choices` |

La base ya funciona: una recompensa `Remember = { { Npc = "Lucia", Fact = "DevolvioMochila" } }` hace que Lucía lo
recuerde para siempre, y `LifeStoryService.recall(player, "Lucia", "DevolvioMochila")` permite que un diálogo diga
*"Me ayudaste aquel día"*.

*NPCDefinitions* dirá de cada NPC con nombre: modelo y ropa, lugar y horario (con GameClock), nivel de memoria,
diálogos y el **rol** que cubre (`Profesor`, `Medico`…) para ser el respaldo de RoleService.

## 10.10 Sistema de tiempo y compresión

- **Reloj del mundo:** 1 día de juego = `Config.DayLengthMinutes` (hoy 20 min reales; el diseño proponía 24).
  Semana de 7 días, mes de 28 días, año de 12 meses (`Config.Calendar`). El reloj es de cada servidor: por eso las
  esperas guardadas se reinician al entrar en otro servidor.
- **Horarios:** colegio 8:00–14:00 de lunes a viernes, actividades 16:00, tiempo libre 17:00, casa 19:00. Se expresan
  como requisitos (`Hours`, `Weekdays`) y sirven igual para tiendas, trabajos, transporte y NPC.
- **La jornada escolar no dura lo que marca el reloj.** Con 1 día = 20 min, de 8:00 a 14:00 pasan solo 5 minutos
  reales, y pediste jornadas de 10–20 min. Decisión: el reloj **abre la puerta** (el día de colegio debe *empezar* en
  horario escolar) y después la jornada es una **secuencia de actividades** (entrada → matemáticas → lengua → recreo →
  ciencias → música → educación física → salida) que dura lo que duran sus actividades (10–20 min). Así nadie espera
  a una hora concreta y nadie se queda a mitad de clase porque el reloj siga corriendo (coherente con la
  [Fase 8.1](../diseno/08-educacion.md): "no a horas fijas reales").
- **Compresión por etapas:**

| Etapa | Duración objetivo | Cómo |
|---|---|---|
| Bebé | **5–10 min** (decidido; sustituye la propuesta de 18 min de [04](04-primeros-30-minutos.md)) | Capítulo corto de 3 misiones + transición |
| Niño | 3–5 sesiones | ~2 jornadas escolares por sesión, cursos resumidos con "Han pasado los meses…" |
| Adolescente | 3–5 sesiones | Instituto + primer trabajo + decisión |
| Universidad / FP | 4–6 sesiones | Semestres de pocas clases, exámenes, prácticas, graduación |

La edad avanza con los capítulos (transiciones), no con horas de espera: coherente con la regla del diseño de que la
edad solo avanza jugando ([Fase 6.2](../diseno/06-edades-progresion.md)), pero más rápida en la campaña inicial.

## 10.11 Integración con la educación

- **Asignaturas:** Matemáticas, Lengua, Ciencias, Historia, Música, Arte, Educación Física y Tecnología.
  Cada una con `Skill` (nivel 1–5), `Grade` (0–10), `Attendance` (%), `Knowledge` y `XP`.
- **Clase = actividad** del motor de actividades (quiz, ejercicio, práctica musical, carrera…). Resultado 0–100 %
  → sube conocimiento, XP y nota. Cada clase emite `LessonCompleted { Subject, Score }` para la historia.
- **Exámenes:** misión con día y hora (lo pone el profesor jugador o el NPC). Emiten `ExamGraded { Subject, Grade }`.
- **Asistencia:** faltar da avisos y misiones de "recuperar clase", y baja un poco la nota; nunca expulsa ni bloquea.
- **Consecuencias:** las notas abren becas y mejores ofertas y dan ventaja en habilidades; **no cierran caminos**
  ([Fase 8.4](../diseno/08-educacion.md)). La decisión de estudios se guarda en `Choices.Estudios` y cambia misiones,
  lugares (facultad), NPC (tus profesores) y profesiones disponibles.
- **Prácticas** (fase 13): Medicina → hospital; Ingeniería → empresa del Distrito Financiero (Tecnoval, Energía Costa);
  Derecho → despacho con caso simulado. Son turnos reales de la profesión con rango "estudiante".

## 10.12 Integración con las profesiones (jugadores + NPC)

`RoleService` es la pieza de arquitectura para **cualquier** puesto:

```
Alumno necesita clase de Matemáticas
      └─► RoleService.assign("Profesor", { Subject = "Matematicas" })
             ├─ Hay un profesor jugador de servicio con hueco → da él la clase (cobra, gana XP)
             └─ No hay ninguno → NPC profesor cualificado (la clase empieza igual, sin esperar)
```

- Hoy ya lo usan los trabajos de la v0.1: fichar marca `Duty_Barista`, etc., y dejar el trabajo lo quita.
- El profesor jugador (fase 6) tendrá su propio turno: preparar clase (elegir actividades), entrar al aula, impartir,
  poner examen, corregir y poner notas. Su rendimiento se mide por la participación y las notas de sus alumnos.
- El mismo patrón sirve para médico ↔ paciente, policía ↔ ciudadano, bombero ↔ emergencia, entrenador ↔ equipo y
  profesor de universidad ↔ estudiante. **El juego nunca depende de que haya un jugador conectado.**

## 10.13 Plan por fases

| Fase | Contenido | Estado |
|---|---|---|
| **1** | **LifeStorySystem base**: motor de capítulos y misiones por datos, secundarias, decisiones con ramas, momentos, biografía, memoria de NPC, GameClock, LocationService, RoleService, tarjeta "Tu vida", pantallas, línea guía, validador y pruebas. Capítulo puente jugable | ✅ **Hecho** |
| **2** | **Tutorial de bebé (5–10 min)**: nacer en una casa familiar de Los Pinos, gatear, levantarse, primeros pasos, Abu y la familia (NPC con diálogos), explorar la casa, primera necesidad (el biberón), mirar la ciudad por el ventanal y "Han pasado varios años…" | ✅ **Hecho** (ver 10.16) |
| 3 | Transición a niño: ~~escala del personaje~~ ✅ (LifeService), ropa por etapa, edad por tiempo jugado y cumpleaños | Escala, velocidad y límites por edad ya hechos |
| 4 | Primer día de colegio (aula, profesor, compañero) | Datos listos |
| 5 | Sistema de clases (actividades por asignatura) | — |
| 6 | Profesores jugadores + NPC de respaldo | RoleService listo |
| 7 | Recreo y relaciones (secundarias sociales, RelationshipService, EventDirector) | — |
| 8 | Exámenes y calificaciones | — |
| 9–11 | Adolescencia, instituto, elección educativa | — |
| 12–14 | Universidad, prácticas, graduación | — |
| 15 | Transición a la vida profesional ("¿Qué harás ahora?") | — |

## 10.14 Normas de Roblox que afectan a la campaña

- **Relaciones:** el encargo menciona "relaciones" y "tener pareja" en la universidad. Roblox prohíbe experiencias de
  citas o romance entre usuarios, así que las relaciones de la campaña son **amistad, compañerismo, familia y
  confianza**. La pareja solo existe como rol de hogar aceptado por dos jugadores (decisión D6 del diseño,
  [Fase 12.4](../diseno/12-multijugador-social.md)), sin misiones románticas.
- **Salir** (vida universitaria) = cine, conciertos, deporte, cafeterías; sin alcohol.
- **Eventos aleatorios**, sí; **azar con Robux**, nunca.
- Conflictos en el colegio ("problemas con otro alumno") se tratan como misiones de resolver y hacer las paces, sin
  acoso ni violencia.

## 10.15 Cómo probarlo

- **Prueba automática** (programador): `lune run scripts/test-lifestory.luau` desde `roblox/`. Simula el capítulo
  puente, una secundaria, una decisión con ramas, el tutorial de bebé completo (nacer → niño → adulto) y la espera al
  horario del colegio. Resultado actual: todas las comprobaciones en verde.
- **En Roblox Studio:** el archivo `RealLifeSimulator.rbxl` hay que regenerarlo con los scripts nuevos
  (`rojo build` + `build-place`, ver el README). Esta sesión no lo toca porque el mapa y ese archivo los lleva otra
  sesión. Al pulsar Play en Studio (sin guardado activado, cada prueba es un personaje nuevo) naces bebé junto a la
  cuna: pantalla *"Primeros pasos"*, botón *¡Levántate!* y la tarjeta *Tu vida* arriba a la derecha.

## 10.16 Fase 2 hecha: el tutorial de bebé

**Dónde:** una de las 8 casas familiares de Los Pinos que ha preparado el mapa (`CasaFamiliar`, ver
[`docs/mapa/ETIQUETAS.md`](../mapa/ETIQUETAS.md)). Si hay más bebés que casas, comparten casa.

**Cómo se juega (5–10 minutos):**

| # | Qué pasa | Qué enseña |
|---|---|---|
| 1 | Pantalla *"Primeros pasos — Acabas de llegar al mundo"*. Apareces junto a la cuna, **gateando** (pequeñito y lento) | — |
| 2 | Abu: *"Vamos, tesoro. Intenta levantarte."* Botón grande **¡Levántate!** (o la barra espaciadora) | Botones e interfaz |
| 3 | "Da tus primeros pasos (0/5)": cada pocos pasos andados suma uno | Moverse |
| 4 | "Llega hasta Abu": la **línea azul** lleva hasta Abu, en el salón. *Hablar* con él o ella | Línea guía, interactuar |
| 5 | Momento: *"Has dado tus primeros pasos."* La barriguita empieza a sonar (baja el hambre) | Necesidades |
| 6 | "Explora tu casa", en cualquier orden: la cocina, la tele del salón, tus bloques | Explorar, objetos |
| 7 | "Tienes hambre: pide el biberón a tu familia en la cocina" → el hambre se llena | Cuidar las necesidades |
| 8 | Momento: *"Has conocido a tu familia."* | — |
| 9 | "Asómate al ventanal": la cámara sale por la ventana y enseña Valmar. Abu: *"Algún día lo recorrerás entero."* | Presentar la ciudad |
| 10 | *"Han pasado varios años…"* → **ya eres niño** (el personaje crece) | — |

Un bebé no puede salir solo de casa (si se aleja, vuelve junto a la cuna), ni trabajar, ni coger el autobús
(`Config.StageLimits`). Todos los números están en `Config.Baby` y `Config.StageBody`.

**Piezas nuevas:** `BabyService` (casa, familia NPC, eventos del bebé), `LifeService` (tamaño, velocidad y límites por
etapa), `client/Controllers/Baby.luau` (botón, globos de diálogo, vista de la ciudad), lugares de la casa en
`Locations.luau` ("estar dentro" de una habitación), y la línea guía también para pasos de hablar o mirar.

## 10.17 Cinemáticas, voces y música

Los momentos clave de la vida tienen **escena de cámara, subtítulos con voz y música**. Todo son datos
(`src/shared/LifeStory/Cinematics.luau` y `Config.Audio`), así que añadir una escena nueva no requiere programar.

| Momento | Cinemática | Música | Voz |
|---|---|---|---|
| Nacer | `Bebe_Nacimiento`: Los Pinos desde el cielo → tu casa → la cuna. Rótulo "Valmar · Un día de primavera" | Nana (`nacimiento`) | Abu: *"Te damos la bienvenida al mundo, {nombre}…"* |
| Mientras eres bebé | — | La nana, bajita, de fondo en casa | Abu y tu familia en cada conversación |
| Primeros pasos | `Bebe_PrimerosPasos`: la cámara da una vuelta alrededor del bebé | Efecto *primeros pasos* | Abu: *"¡Has llegado hasta aquí sin ayuda!"* |
| Mirar por el ventanal | `Bebe_Ventanal`: la cámara sale por la ventana y sube sobre Valmar. Rótulo "Valmar · Donde el valle se encuentra con el mar" | Tema de Valmar | Abu: *"Algún día lo recorrerás entero."* |
| Han pasado varios años | `Bebe_AnosDespues`: la cámara sube desde la casa hasta el cielo | *Pasan los años* | Rótulos |
| De niño a adulto | `Nino_Creces`: vuelo por Los Pinos, Campus Valmar, Distrito Financiero y el Centro ("El colegio…", "El instituto…", "…ya has crecido") | *Pasan los años* | Rótulos |
| Llegar a Valmar de adulto | `Adulto_Llegada`: vuelta sobre la Plaza Mayor | *Vida adulta* | Narrador: *"Aquí empieza tu vida adulta. ¿Qué harás con ella?"* |
| Valmar ya es tu ciudad | `Adulto_TuCiudad`: la cámara se aleja de ti hacia el centro | Tema de Valmar | Rótulo |
| Cada momento de vida | — | Efecto *momento* | — |

**Cómo se ven:** bandas negras de cine, se ocultan los menús, el personaje se queda quieto y hay un botón **Saltar**.
La historia sigue igual aunque se salte. Si una ancla (tu casa, tu ventanal…) no existe en el mapa, la cámara usa al
jugador, así nunca queda mirando al vacío. El servidor pide al mapa que cargue las zonas que va a enseñar la cámara.

**Música:** original, compuesta por código (`scripts/audio/compose.py` → `roblox/audio/`). Hay que subirla a Roblox una
vez y pegar sus IDs en `Config.Audio` (instrucciones en [`roblox/audio/README.md`](../../audio/README.md)). Con `Id = 0`
no suena y todo lo demás funciona.

**Voces:** siempre hay subtítulos. Además:
- **Voces grabadas** (opcional): `Config.Audio.Voices.Lines["DLG.ABU.NACER.01"] = <ID del audio>` y esa frase suena
  con la grabación.
- **Voz sintetizada de Roblox** (`AudioTextToSpeech`): si el motor la tiene, los personajes leen sus frases con el
  tono de cada uno (`Config.Audio.Voices.Speakers`: Abu, Familia, Narrador). Es una función reciente de Roblox: puede
  que no esté disponible en todas las cuentas o que lea el español con acento. Si falla, se desactiva sola y quedan los
  subtítulos. Se puede apagar con `Voices.TextToSpeech = false`.

**Silenciar:** botón 🔊/🔇 junto al dinero.

**Piezas:** `CinematicService` (servidor: anclas y carga del mapa), `Controllers/Cinematics.luau` (cámara, bandas,
rótulos, subtítulos, saltar), `Controllers/StoryAudio.luau` (música con fundidos, efectos, voces y silencio). En los
datos: `Transition.Cinematic`, el paso `Cinematic`, `Chapter.IntroCinematic/OutroCinematic/Music` y
`Quest.MomentSting`.
