# Marco común de los planetas

Tefra fue el primer planeta y se hizo «a mano». Para que los otros seis (Miasma, Siroco, Nivalis,
Umbría, Tálasa y Vértice) se puedan hacer rápido y bien, lo que Tefra tenía metido en su código ahora es
**común**: cada planeta nuevo se describe con **datos** y unos pocos módulos suyos.

## En palabras sencillas

- **Cada planeta tiene su sitio en el mundo.** Están muy lejos de Valmar (a 25 000 – 32 000 studs) y
  lejos unos de otros. Nadie de Valmar los ve. Solo se construyen la **primera vez que alguien se acerca**
  (el terreno, la plataforma, el barrio y todo lo demás), poco a poco, para que el servidor no se trabe.
- **Se llega igual que a Tefra.** En el espacio, cada planeta es una esfera. Vuelas hacia él, entras en la
  atmósfera (calor, nubes, temblor) y apareces sobre su superficie. Se posa la nave, bajas y andas.
- **Se puede ir ya.** Los planetas con superficie hecha se abren con la misma regla que Tefra: haber
  terminado la Saga 1 o ser tester (el dueño lo es). No hace falta terminar Tefra antes.
- **El mapa galáctico** dice de cada planeta si se puede ir y si tiene **misiones activas** para ti.
- **Cada planeta tiene su cielo, su luz y su sonido.** Nunca el de Valmar.
- **Cada planeta tiene su desventaja** con un medidor en pantalla (en Tefra, el calor; en Miasma, las
  toxinas; en Siroco, la sed…). Sube según dónde estés. Tiene tres fases: normal, aviso (vas más lento) y
  peligro (pierdes vida poco a poco). **Nunca te mata de golpe:** si se llena, te desmayas y despiertas en
  un refugio sin perder nada. Hay **equipo** que hace que suba menos, un **consumible** que lo baja de
  golpe y **refugios** que lo vacían.
- **Cada planeta tiene su barrio** de la capital: plaza, edificios (algunos se pueden visitar por dentro),
  un monumento, gente paseando, farolas y ventanas que se encienden de noche.
- **Cada planeta tiene sus oficios** con tablón «Trabajar»: cada encargo es ir a sitios, hacer un
  minijuego y entregar. Pagan en euros, con rangos (Aprendiz → Maestro) que suben la paga.
- **Cada planeta tiene su material** que se recoge con «Recoger» y su mineral que se extrae con «Extraer».
- Las claves de todo empiezan por el nombre del planeta (`Miasma_…`, `Siroco_…`): nunca se mezclan con
  las de Valmar ni con las de otros planetas.

## Qué hay ya (el marco)

| Pieza | Para qué |
|---|---|
| `shared/Cosmos/PlanetRegistry` | La lista de planetas con superficie y su hueco en el mundo (`Slots`). |
| `shared/Cosmos/PlanetSurface` | `PlanetSurface.new(def)`: la superficie con datos (terreno, mineral, flora, choques de la nave, aterrizar). Mismas funciones que `Tefra.luau`. |
| `shared/Cosmos/PlanetCity` | `PlanetCity.new(plan)`: el plano del barrio (suelos, huecos, edificios, refugios, sitios de la historia, farolas, gente, lo que se recoge). Mismas funciones que `TefraCity`. |
| `shared/Cosmos/PlanetHazard` | `PlanetHazard.new(cfg)`: el medidor de la desventaja. **El calor de Tefra es una configuración de esto** (`TefraHeat.Hazard`). |
| `shared/Cosmos/PlanetJobs` | Oficios con datos (fases de cada encargo, paga, rangos, antitrampas). |
| `server/World/PlanetWorld` | `ensure(id)`: construye el planeta la primera vez (terreno, plataforma, puntos, mineral, flora y barrio). |
| `server/World/PlanetCityBuilder` | Construye el barrio con el plano y el **kit** del planeta (sus formas y colores). |
| `server/Services/PlanetService` | Bajar, subir, bajarse, minar, puntos de interés, «Mirar», «Recoger», destino de cada estrella, misiones del mapa galáctico. |
| `server/Services/PlanetHazardService` | Lleva el medidor de cada jugador en los planetas nuevos, los derribos y el consumible. |
| `server/Services/PlanetJobService` | Lleva los turnos de los oficios con datos. |
| `client/Controllers/PlanetClient` | Entrar y salir, el agua, el tinte del terreno y lo que cae del cielo de cada planeta; rescate si caes a un hueco. |
| `client/Controllers/EnvDirector` | Cielo, luz y sonido según el planeta (perfil `S.Env`, momento `PlanetaModo`). |
| `client/Controllers/PlanetHazardHud` | El medidor en pantalla (el de Tefra sigue siendo `TefraHud`). |

Tefra pasa por el mismo registro y los mismos servicios, pero conserva su ciudad, su calor y sus oficios
hechos a mano (no se ha tocado lo que ya funcionaba: mismas claves, mismas piezas).

## Los dos primeros planetas hechos con el marco

### 🌫 Miasma · Anclaje Siete (unos 30 minutos)
- **Cómo es:** cinco discos de metal y cristal con un aro de luz turquesa, anclados a un pico por encima
  de un mar de niebla verde. Pasarelas con barandilla de cristal, globos de gas, casas de madera pintada
  colgadas de globos, la Gran Veleta, la torre de la Refinería con su llama, la batería antiaérea y los
  hangares. Fuera: picos violetas con musgo amarillo, cristales, medusas de gas, la Torre Silbadora, el
  Lago de Ácido Verde y una góndola caída.
- **Desventaja: ☣ Toxinas.** Suben cerca de la niebla, en Barrio Lastre y fuera de la ciudad; más con la
  marea de niebla y la lluvia ácida. Máscara de filtro y traje sellado (mochila), cápsula de aire limpio
  (se usa) y refugios con aire filtrado (la enfermería, la cantina…).
- **Oficio: Filtrador/a** (tablón en el taller de Lastre). **Material:** espora de filtro, plata de rayo.
- **Historia (5 misiones):** «Bajo el asedio», «Ración doble» (decisión), «Aire para el Lastre» (oficio),
  «El ataque» (huida, pelea y decisión), «La señal del Seis» (gancho: hay gente bajo la niebla).

### 🌞 Siroco · Puerto Calcina (unos 30 minutos)
- **Cómo es:** el fondo de un cañón rojo. Casas de adobe excavadas en la roca, toldos y telas de colores,
  antenas y bidones; La Recta, una calle-circuito con bordillos rojos y blancos, pasa bajo el Arco del
  Campeón. Deslizadores aparcados, veleros de arena, la fuente de Pozo Hondo, el Pozo del Silencio.
  Fuera: dunas, mesas, cactus, árboles de vidrio, el Cementerio de Deslizadores, la Esfinge Ciega y las
  Salinas Blancas.
- **Desventaja: 💧 Sed.** Sube siempre, más al sol de día y fuera; muchísimo en la hora roja (mediodía) y
  algo más con la tormenta de arena. Cantimplora y ropa de sol (mochila), agua fresca (se usa; también de
  los cactus) y la sombra de los refugios (los Túneles, la cantina…).
- **Oficio: Aguador/a** (tablón junto a la fuente). **Material:** sal de rocío, chatarra antigua, vidrio.
- **Historia (5 misiones):** «Tormenta de fuego», «Deudas» (huida y decisión), «El agua de Pozo Hondo»
  (oficio), «Chatarra» (Cementerio y pelea), «El nombre tachado» (gancho: la Gran Vuelta y las Arcas).

En el modo pruebas hay botones para aterrizar en cada uno o ir a su órbita.

---

## Para agentes: cómo añadir un planeta

1. **Superficie** — `src/shared/Cosmos/<Id>.luau`:
   ```lua
   local PlanetSurface = require(script.Parent.PlanetSurface)
   local PlanetCity = require(script.Parent.PlanetCity)
   local PlanetHazard = require(script.Parent.PlanetHazard)
   local PlanetJobs = require(script.Parent.PlanetJobs)
   local Registry = require(script.Parent.PlanetRegistry)
   local City = require(script.Parent.<Id>City)          -- el plano (PlanetCity.new)
   local S = PlanetSurface.new({
     Id = "<Id>", Name = "…", Origin = Registry.Slots.<Id>, Half = 1024, Seed = …,
     City = City, POIs = { { Id = "<Id>_Plataforma", Pad = true, X = 0, Z = 0, Flat = 40, Name = "…" }, … },
     rawHeight = function(lx, lz, S) … end,              -- (opcional) el relieve propio
     Materials = { … } o materialAt = function(lx, lz, y, slope, S) … end,
     TerrainColors = { [material] = Color3 },            -- se pintan SOLO en el cliente que está allí
     NodeCount, NodeOres, DecorCounts, WaterColor, …
   })
   S.Kit = "<Id>Kit"                                    -- server/World/<Id>Kit.luau (formas y colores)
   S.Env = { Sky = { "Cielo<Id>", "Original" }, Clouds = …, Mood = { … } }   -- su luz (nombres de DayGrade)
   S.Hazard = PlanetHazard.new({ Id = "…", Bands = …, Gear = …, Consumable = { Item = "…", … } })
   S.HazardHints, S.HazardTint, S.HazardToasts, S.KnockText, S.CounterText
   S.hazardContext = function(pos, info) return { Near = { … }, Zone = …, Exposed = … } end
   S.moment = function(clock, pos) return "Tormenta" or nil end   -- para el sonido (Soundscapes Modes)
   S.Fx = { { Color = …, Size = …, Rate = … } }           -- lo que cae del cielo
   S.CrowdLines = { "…" }                                -- lo que dice la gente
   PlanetJobs.register({ … })                            -- sus oficios (tablón en Board = { lx, lz })
   return S
   ```
2. **Plano del barrio** — `src/shared/Cosmos/<Id>City.luau` con `PlanetCity.new(plan)`. Todas las claves
   con `KeyPrefix = "<Id>_"`. La plataforma (`POIs` con `Pad = true`) va DENTRO de `Rect`. Los
   `StorySpots` son los lugares de la historia: `"<Id>_<Spot>"` en `LifeStory/Locations` (automático).
3. **Kit** — `src/server/World/<Id>Kit.luau` (opcional pero es lo que lo hace bonito y distinto):
   `Colors`, `Shapes[Forma](ctx, parent, b)`, `floor`, `pit`, `lamp`, `dressBox`, `gather`, `extras`,
   `decor(folder, d)` (flora), `poi(model, p, at)`, `world(folder, S)` (lo de fuera: niebla, dunas…). Las
   herramientas de dibujo están en `ctx` (`ctx.box`, `ctx.column`, `ctx.ball`, `ctx.W`, `ctx.CF`,
   `ctx.crowd`, `ctx.info`, `ctx.sign`). Estilos de edificio Box: `Kit/Palette.Styles.<Id>…`.
4. **Registro** — una línea en `PlanetRegistry.Modules` (`<Id> = "<Id>"`) y otra en
   `Planets.EarlyAccess` (`<Id> = true`) si se puede visitar ya.
5. **Historia** — misiones en `LifeStory/Misiones/<Id>_*.luau` con `Requires = { Planet = "<Id>" }` y
   lugares `"<Id>_…"`; escenas en `LifeStory/Happenings/<Id>.luau` (y su grupo en `HappeningIndex`); las
   frases reescritas en `docs/historia/reescritura/<Mision>.md` + `lune run
   scripts/audit/aplicar-reescritura.luau <Mision>` (nunca a mano en `Guiones/`). Gente nueva en
   `LifeStory/Cast` (y su voz en `CastVoices`). Objetos en `shared/Items`.
6. **Sonido** — su perfil ya está en `Soundscapes.Planets.<Id>`; añade `Modes` si tiene momentos
   (`S.moment` → atributo `PlanetaModo`; dentro de un refugio, `"Refugio"`).
7. **Pruebas** — `scripts/test-planetas.luau` comprueba solo cada planeta del registro (llegar, barrio sin
   pisarse, puertas y sitios a los que se llega andando, plataforma dentro, cielo y sonido propios, sus
   momentos, medidor y contramedida con dobles, oficio que paga una vez, mapa galáctico). Añade tus
   misiones a `EPISODES` (sección «La historia de cada planeta»): se juegan enteras con las dos ramas.
   `lune run scripts/test-planetas.luau rapido` se salta las misiones enteras.
8. **Kit de ejemplo** — `World/MiasmaKit` (plataformas en el vacío: `plan.Void`) y `World/SirocoKit`
   (barrio abierto: `OpenGround`, calle propia con `kit.floor`). Cópialos como punto de partida.

### Reglas que no se rompen
- Presupuesto del móvil: el barrio entre 1 500 y 4 000 piezas (Tefra entera ≈ 7 000). Nada de mallas
  nuevas alargadas y lisas (moderación): mejor piezas y terreno.
- Nada se guarda nuevo en la partida: todo va en lo que ya hay (`data.Careers`, `data.Items`,
  `data.Story`, `data.Space`).
- 13+: sin sangre; nadie muere en cámara.
