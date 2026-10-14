# Heroes of History: Ragnarock · Diseño de los 7 mundos

> **Documento de diseño (solo diseño).** No se ha tocado nada del juego: ni código, ni misiones, ni marcas.
> Es la propuesta completa para que el dueño la lea, tache y cambie, y para que los desarrolladores sepan
> qué construir. Resumen en una tabla: [`resumen.md`](resumen.md).
>
> **Se basa en:** `docs/espacio-aaa/encargo.md` (sobre todo «Tercer encargo» y «Decisiones del dueño»),
> `docs/espacio-aaa/referencia-planetas.png`, `docs/historia/saga-2-siete-planetas.md`,
> `docs/historia/cosme-otro-universo-y-saga-2.md`, `docs/planetas.md`, `docs/espacio.md`,
> `docs/espacio-aaa/diseno.md`, `docs/mar/encargo.md`, `docs/zonas-verdes/*`, `docs/pase-de-temporada.md`,
> `docs/historia/10-life-story-system.md` y el código que ya existe (trabajos, economía, vehículos, pesca,
> granja, minería espacial, pase de temporada y motor de misiones LifeStory).
>
> **Decisiones del dueño recogidas aquí:**
> - Las misiones tienen que ser **de calidad, de juego grande («AAA»)**: con trasfondo, personajes que se
>   recuerdan, giros, decisiones con consecuencias y momentos espectaculares. Nada de «ve y trae 10».
> - Cada planeta tiene **desventajas** propias (calor, sed, presión, frío, esporas, veneno, deudas) como
>   parte de su identidad.
> - El **pase premium sí ayuda**: acelera de forma moderada todo el progreso, y **la ventaja crece cuantas
>   más horas se juega**. Quien no paga puede llegar a todo, solo que más despacio. Ver apartado 2.8.

## Índice

0. [Cómo leer este documento](#0--cómo-leer-este-documento)
1. [Reglas que lo mandan todo](#1--reglas-que-lo-mandan-todo)
2. [La galaxia: lo que comparten los 7 planetas](#2--la-galaxia-lo-que-comparten-los-7-planetas) (incluye
   [2.8 Monetización y pase de batalla](#28--monetización-y-pase-de-batalla))
3. [Los 7 planetas](#3--los-7-planetas): Tefra · Siroco · Tálasa · Nivalis · Umbría · Miasma · Vértice
4. [Cómo se hace una misión «de calidad»](#4--cómo-se-hace-una-misión-de-calidad)
5. [Plan de producción y límites de Roblox](#5--plan-de-producción-y-límites-de-roblox)
6. [Preguntas para el dueño](#6--preguntas-para-el-dueño)

---

## 0 · Cómo leer este documento

- **Si eres el dueño:** lee el apartado 1, el 2.8 (dinero y pase), y de cada planeta «La idea en una
  frase», «Biblia narrativa», «Desventajas» y «Misión principal». Al final están las preguntas (apartado 6).
- **Si eres desarrollador:** el apartado 2 son los sistemas que hay que hacer **primero** (los usan los 7
  planetas). El apartado 4 dice cómo se escriben las misiones con el motor LifeStory y qué hay que
  añadirle. El apartado 5 es el orden de trabajo y los límites técnicos.
- **Palabras que se repiten:**
  - **Ragnarock:** el «fin de todo» de cada planeta (guerra, sol que muere, plaga, tirano, máquinas,
    invasión, quiebra).
  - **Desventaja:** lo que hace la vida difícil en ese planeta. Siempre tiene **contramedidas** que se
    fabrican o se compran.
  - **Cadena:** una misión larga hecha de varias fases.
  - **Rep:** la reputación con cada bando de un planeta (de −100 a +100).
  - **Chispas:** las Chispas de estrella (✨), la moneda de la nave.
  - **Potencia:** un número que resume lo fuerte que es tu nave o tu equipo.

---

## 1 · Reglas que lo mandan todo

### 1.1 · Nombres (los nuevos sustituyen a los viejos)

El documento de la Saga 2 usa los nombres viejos. **En el juego solo salen los nuevos.** Los personajes,
los barrios y la historia de cada episodio se mantienen y se adaptan al mundo nuevo.

| # | Antes (planeta / ciudad) | **Ahora: planeta** | **Ahora: ciudad** | Tipo de mundo | Estilo de ciudad | Ragnarock | Protagonista |
|---|---|---|---|---|---|---|---|
| 1 | Lontana / Redonda | **Tefra** | **Bastión Ceniza** | Volcánico, ceniza | Fortaleza industrial y militar entre lava | Guerra contra su luna | Dalia Renn |
| 2 | Ocrea / Rampa Mayor | **Siroco** | **Puerto Calcina** | Desierto, tormentas, ruinas | Adobe y chatarra, circuitos de carreras | El sol se muere | Rafa Quiroga |
| 3 | Marena / Pleamar | **Tálasa** | **Abisalia** | Océano, islas flotantes | Futurista, en parte submarina | Plaga de coral negro | Dra. Noa Ferrán |
| 4 | Velaria / Nevalumbre | **Nivalis** | **Fortaleza Albor** | Helado, glaciares, auroras | Antigua, de piedra y hielo | Un tirano | Princesa Ilse |
| 5 | Fronda / Copalta | **Umbría** | **Raíz Honda** | Selva, cascadas | Orgánica, en árboles gigantes | Plaga de máquinas | Garza |
| 6 | Zéfira / Volandera | **Miasma** | **Anclaje Siete** | Tóxico, nubes venenosas | Plataformas sobre la niebla | Invasión | Mara Solís |
| 7 | Mercadia / Ciudad Saldo | **Vértice** | **Distrito Cero** | Urbano | Megaciudad con tráfico aéreo | Quiebra y revuelta | Abril Cruz |

- **Nota para desarrolladores:** en el código ya existen identificadores con los nombres viejos
  (`shared/Cosmos/Lontana.luau`, `PlanetBodies`, `Planets`, misiones del espacio). **Propuesta:** los
  identificadores internos se quedan (así no se rompen partidas guardadas como `data.Space.Planets`) y
  **solo cambia lo que se ve** (nombres en pantalla, textos, mapa). Si se prefieren renombrar, hay que
  migrar los datos guardados con una tabla «viejo → nuevo» en `DataService` (pregunta 1).
- **Tefra es el mundo de Cosme** (antes Lontana): ahí nació y ahí está la estatua de la abuela Nilda.
- La superficie que ya existe de Lontana (`docs/planetas.md`: colinas, Lago de las Lunas, cuarzo malva)
  **pasa a ser la primera región de Tefra**: se mantiene el sistema (terreno por semilla, entrada sin
  pantalla de carga) y se cambia el aspecto a volcánico (ceniza, basalto, coladas).
- El tipo **«espacial»** de la imagen de referencia (asteroides, anillos, estaciones mineras) no es un
  planeta aparte: es la **capa de órbita** de cada planeta (2.6) más el espacio de Valmar que ya existe
  (estaciones Alba y Cénit, cinturones de asteroides).
- Los episodios mantienen el orden de la Saga 2: **Tefra el 1.º y Vértice el 7.º**; del 2 al 6, el
  jugador elige.

### 1.2 · Clasificación 13+ (Moderado)

Se aplican **todas** las reglas del apartado 0 de `saga-2-siete-planetas.md`. Resumen:

- **Sí:** guerra, armas de ciencia ficción, explosiones, muertes **fuera de cámara o sin sangre**, traición,
  duelo, dilemas morales, miedo, humor negro suave.
- **Nunca:** sangre, heridas, trozos de cuerpo, tortura que se vea, nada sexual, palabrotas fuertes (lista
  de palabras permitidas en ese documento), drogas o alcohol presentados como algo bueno, odio del mundo
  real, religiones reales.
- **Cómo cae un enemigo:** cae y desaparece; los robots explotan en chispas; las naves revientan.
- **Cuidado especial en este documento:**
  - En Miasma el aire es venenoso: **no** hay nada que se parezca a drogas (nada de «colocarse» con el gas).
  - En Vértice hay deudas y crimen: el crimen **no se premia** como algo guay; tiene consecuencias.
  - Las criaturas son animales inventados: se las puede ahuyentar, dormir o vencer; nada de crueldad que se
    vea.

### 1.3 · Dinero real (resumen; el detalle está en 2.8)

- **Decisión del dueño:** el **pase premium ayuda a avanzar más rápido** (más experiencia, más recursos,
  fabricar y viajar más rápido, más misiones). La ayuda es **moderada al principio** y **crece cuantas más
  horas se juega** con el pase.
- **Límites que no se cruzan nunca:**
  - **Todo el contenido se puede conseguir gratis**, solo que tarda más. No hay pieza, arma, planeta ni
    misión de la historia que solo se consiga pagando.
  - **Modos competitivos justos:** en carreras clasificatorias, arenas y cualquier modo jugador contra
    jugador, las estadísticas se **igualan** o se empareja por **Potencia**.
  - **Nada de cajas sorpresa de pago.** Si algún día hay algo con azar, se muestran las probabilidades
    (normas de Roblox).
  - **Todo se explica claro** antes de comprar: qué da y cuánto, con números.
  - Todo respeta la clasificación 13+.

### 1.4 · No se rompe nada

- Primero se audita lo que hay y se **amplía**; no se duplica ni se simplifica.
- No se borra progresión, naves, dinero, misiones ni inventario.
- **Quien quiera quedarse en Valmar puede hacerlo:** nada de Valmar exige ir al espacio.
- La Saga 2 solo se abre al **terminar la Saga 1** (como ya hace el juego).

---

## 2 · La galaxia: lo que comparten los 7 planetas

La regla del dueño: **todo lo que hay en Valmar existe en cada planeta, pero de forma distinta**. Para no
hacer siete veces lo mismo, se hace **una base común** (este apartado) y cada planeta le pone su piel, sus
reglas y sus misiones (apartado 3).

### 2.0 · Qué tiene cada planeta (la lista de Valmar)

| En Valmar | En cada planeta |
|---|---|
| Ciudad con barrios, gente con rutina y tiendas | Ciudad propia con 6–8 barrios, gente con rutina de crisis y tiendas locales |
| Trabajos y carreras con rangos | **11 trabajos comunes** (2.1) con su toque local + **4 trabajos propios** |
| Negocios (`BusinessService`) | Negocios locales que se compran y se llevan (al menos 2 por planeta) |
| Vivienda (`HousingService`, `PropertyService`) | Vivienda en el planeta (2.5) |
| Coches, bus, metro, tren | Transporte local (2.6) |
| Mar, barcos, pesca, buceo | **El «mar» del planeta**: lava, dunas, océano, hielo, ríos, niebla tóxica, canales |
| Granja | Cultivo o cría local (setas de ceniza, algas, lanudos, escarabajos…) |
| Ocio: feria, karting, skate, deportes, playa | Ocio local (cada planeta tiene su fiesta, su carrera y su deporte) |
| Policía, justicia y cárcel | Las leyes del planeta y quién las hace cumplir |
| Hospital | Médicos de campo y enfermería local |
| Minería espacial (asteroides) | Minería a pie y en nave, con recursos únicos |
| Historia (LifeStory) | Episodio de la Saga 2 + cadenas secundarias + eventos + línea premium |

### 2.1 · Los 11 trabajos comunes de la galaxia

**Cómo funcionan todos** (una sola base para no duplicar):

- Se apuntan en el **Tablón de la Galaxia**, que está en el puerto de cada planeta y en las estaciones
  Alba y Cénit. Se reutiliza `JobService` (encargos de recoger y entregar), `CareerService` +
  `Institutions` (rangos) y `StaffService` (puestos con NPC cuando no hay jugadores).
- **La carrera es una sola para toda la galaxia** (un minero sigue siendo el mismo minero en Tefra y en
  Nivalis), pero **cada planeta lleva su experiencia local**: hace falta un mínimo de experiencia local
  para los encargos difíciles de ese planeta. Así cada planeta tiene algo que aprender.
- **5 rangos:** Aprendiz → Oficial → Veterano → Experto → Maestro (unas 2, 6, 15 y 30 horas de ese
  trabajo para pasar de uno a otro, sin pase).
- **Paga:** dinero de Valmar (€) por encargo, multiplicada por el rango: ×1,0 / ×1,2 / ×1,45 / ×1,75 /
  ×2,1. Algunos encargos peligrosos dan además **1–3 Chispas** (con tope por hora: como mucho 40 por hora
  entre todo, como los derribos del espacio).
- **Lo que cambia por planeta:** el tipo de encargo, el peligro (la desventaja) y la paga base (más alta
  donde es más difícil). Ver la tabla «toque local».
- **Cada trabajo tiene «encargos con historia»:** de cada 5 encargos, 1 trae un pequeño suceso (un cliente
  que miente, una carga que no es lo que dice, un herido en el camino) con una decisión. Así el trabajo no
  es solo repetir.

| # | Trabajo | Qué hace | El bucle de juego (lo que haces una y otra vez) | Qué se gana al subir de rango | Paga base (rango 1) |
|---|---|---|---|---|---|
| 1 | **Piloto de carga** | Lleva mercancía y pasajeros entre puertos, estaciones y planetas. | Coger encargo → cargar la bodega → volar (ruta segura o rápida y peligrosa) → atracar → entregar a tiempo. Puede salir un ataque o una tormenta. | Más bodega en los encargos, rutas entre planetas, pasajeros VIP, contratos que se repiten. | 60–200 € por viaje |
| 2 | **Minero/a** | Saca mineral a pie (pico y taladro) y en nave (láser). | Escanear con el VISOR → elegir veta → extraer (minijuego de ritmo: si vas demasiado rápido se calienta) → llevar al refinador. | Taladros mejores, vetas raras, permisos de zonas peligrosas. | 8–25 € por unidad |
| 3 | **Mecánico/a de naves** | Repara y mejora naves de jugadores y NPC en el astillero. | Diagnosticar (encontrar la pieza rota con el escáner) → desmontar → reparar (minijuego de soldar o cablear) → probar en la pista. | Piezas raras, naves grandes, taller propio (negocio). | 40–120 € por reparación |
| 4 | **Comerciante** | Compra barato en un planeta y vende caro en otro. | Mirar precios en el Tablón → comprar → transportar (tú o un piloto contratado) → vender antes de que baje el precio. | Más bodega comercial, contratos de suministro, puesto en el mercado. | Lo que ganes con la diferencia |
| 5 | **Médico/a de campo** | Cura a NPC y jugadores en la enfermería y en el terreno. | Llamada → llegar → diagnóstico (síntomas, como `MedicalService`) → tratar con lo que llevas (consumibles fabricados) → evacuar si hace falta. | Casos graves, enfermería propia, recetas médicas avanzadas. | 50–150 € por paciente |
| 6 | **Seguridad** | Patrulla, escolta y protege. | Turno → patrulla con sucesos (robo, pelea, criaturas) → decidir (detener, avisar, dejar ir) → informe. | Escoltas de convoyes, mando de patrulla, armas de servicio mejores (solo de turno). | 45–140 € por turno |
| 7 | **Explorador/a-cartógrafo** | Descubre sitios y hace mapas. | Elegir zona sin mapa → explorar (a pie o en nave) → marcar puntos con el VISOR → volver vivo para cobrar el mapa. | Zonas peligrosas, puntos ocultos, venta de mapas a otros jugadores (como objeto). | 30 € por punto + 150 € por mapa completo |
| 8 | **Recolector/a (xenobiología)** | Recoge plantas, muestras y bichos (sin hacerles daño) para laboratorios. | Pedido del laboratorio → encontrar la especie (pistas: hora, clima, bioma) → recoger con la herramienta correcta → conservar (se estropea con el tiempo). | Especies raras, cultivo propio, recetas de consumibles. | 15–60 € por muestra |
| 9 | **Ingeniero/a de obras** | Construye y repara estructuras: muros, tuberías, puentes, refugios. | Plano → reunir material → montar piezas en su sitio → prueba de carga. | Obras grandes que **cambian el mapa** (un puente nuevo, un refugio). | 70–180 € por obra |
| 10 | **Rescatista** | Salva gente en peligro por la desventaja del planeta. | Alarma → llegar rápido → sacar a la persona (llevarla, guiarla, cortar, escalar) → enfermería. Con tiempo límite. | Rescates extremos, mejor equipo, mando de equipo. | 60–160 € por rescate |
| 11 | **Cazarrecompensas** | Atrapa a quien busca la ley local. | Contrato con ficha (pistas, zona) → investigar (hablar, seguir huellas) → encontrar → atrapar vivo (más paga) o vencer. | Objetivos de más nivel, contratos en nave, fama. | 100–400 € por contrato |

**Toque local de cada trabajo** (el mismo trabajo se juega distinto en cada planeta):

| Trabajo | Tefra | Siroco | Tálasa | Nivalis | Umbría | Miasma | Vértice |
|---|---|---|---|---|---|---|---|
| Piloto de carga | Vuelos bajo fuego antiaéreo; carga militar o de refugiados | Rutas con tormentas de arena (los motores se ahogan) | Rutas que acaban bajo el agua (modo submarino) | Volar sin luces bajo los radares del Regente | Volar entre troncos; aterrizar en ramas | Volar sobre la niebla; si caes, el casco se corroe | Tráfico aéreo con normas: carriles, semáforos y multas |
| Minero/a | Vetas junto a la lava; el calor sube al picar | Minas en ruinas antiguas, con trampas | Minar en el fondo, con presión | Minas de Cristal (puedes liberar presos) | Poco mineral: savia ámbar y madera de hierro | Minas en los picos, con rayos | Minería de chatarra: chips y metales de la basura |
| Mecánico/a | Blindar vehículos militares | Deslizadores de carrera (boxes) | Submarinos y domos | Trineos y motores que se congelan | Planeadores y escarabajos de carga | Globos, filtros y cazas | Lanzaderas y robots de reparto |
| Comerciante | Mercado negro: la policía militar requisa | El agua es lo más caro | Algas y perlas | Contrabando de canciones prohibidas (cristales) | Trueque con los pueblos del suelo | Contrabando a través del bloqueo | Precios que cambian cada hora |
| Médico/a | Hospital de campaña (Campus Nilda) | Golpes de calor y sed | Enfermedad de presión | Congelación | Picaduras y esporas | Intoxicación por gas | Clínica de barrio sin dinero |
| Seguridad | Defensa de la Muralla | Proteger los pozos | Control de cuarentena | **Eliges bando:** guardia del Regente o resistencia | Barricadas contra el Enjambre | Defensa antiaérea | Seguridad privada o vecinos del Rastro |
| Explorador/a | Campos de lava que cambian cada día | Ruinas de la Ciudad Primera | Fosas abisales | Cuevas de cristal | Suelo de selva sin luz | Bajar a la niebla con traje | Niveles abandonados de la ciudad |
| Recolector/a | Setas de ceniza, hongos térmicos | Cactus de agua, escarabajos | Algas, peces brillantes | Musgo de nieve | Flores, insectos, savias | Medusas de gas | Plantas de plástico mutadas |
| Ingeniero/a | Reparar la Muralla tras los bombardeos | Cisternas y tuberías | Domos submarinos | Muros contra ventiscas | Pasarelas entre árboles | Anclajes y cables | Lo que la empresa abandonó |
| Rescatista | Atrapados en escombros | Perdidos en tormentas | Atrapados en domos | Perdidos en la ventisca, hielo roto | Caídos al suelo de la selva | Caídos a la niebla | Atrapados en ascensores y desalojos |
| Cazarrecompensas | Desertores (muchos son buena gente: dilema) | Deudores de Doña Hierro | Saqueadores de la cuarentena | Te contrata la guardia o la resistencia | Mercenarios de Vesna | Espías del Dominio | Fugitivos por deudas (dilema) |

**Antiabuso de los trabajos:** el servidor comprueba distancias y tiempos mínimos (no se puede entregar
antes de lo posible, como ya hace el tablón del espacio con sus 15 s), hay tope de encargos por hora y la
paga baja un poco si se repite el mismo encargo muchas veces seguidas (para animar a variar).

### 2.2 · Fabricación (crear objetos)

**La idea:** todo lo que hace falta para sobrevivir en un planeta se puede **fabricar** con lo que
recoges. Así recoger, minar y explorar tienen sentido.

**Bancos de trabajo** (cada uno es un objeto del mundo que se usa con «Fabricar»):

| Banco | Dónde | Qué hace |
|---|---|---|
| **Mesa de campo** | Portátil (se lleva en la mochila y se monta en el suelo) | Recetas de nivel 1: vendas, filtros simples, bengalas, cuerdas. |
| **Taller** | Casa del jugador, puertos y talleres de la ciudad | Herramientas, equipo, consumibles, muebles. |
| **Forja / Refinería** | Una por planeta (cada una con su estilo) | Convierte mineral en lingotes y material refinado. |
| **Laboratorio** | Hospital o laboratorio de cada ciudad | Medicinas, antídotos, consumibles contra la desventaja. |
| **Astillero** | Puerto de cada planeta y estaciones | Piezas de nave y naves (2.3). |
| **Banco de reliquias** | Uno por planeta, escondido (se abre en una cadena secundaria) | Recetas de nivel 5. |

**Los 5 niveles de los objetos:**

| Nivel | Nombre | Color | De qué se hacen | Ejemplo |
|---|---|---|---|---|
| 1 | Chatarra | Gris | Lo que encuentras tirado | Filtro de trapo (dura 2 min) |
| 2 | Común | Blanco | Materiales normales (hierro, tela, cristal) | Filtro de carbón (8 min) |
| 3 | Refinado | Verde | Material refinado en la forja | Mascarilla con válvula (20 min) |
| 4 | Planetario | Azul | Material único de **un** planeta | Respirador de Miasma (60 min) |
| 5 | Reliquia | Dorado | Material único + pieza de una misión o jefe | Traje sellado de Anclaje Siete (se recarga, sin límite) |

**Materiales:**

- **Comunes a toda la galaxia:** hierro estelar, cobalto azul y cristal solar (ya existen en la minería del
  espacio), chatarra, tela, polímero, cable, vidrio, carbón, agua, fibra vegetal.
- **Únicos de cada planeta** (los de su forja dan el nivel 4):

| Planeta | Materiales únicos | Para qué sirven sobre todo |
|---|---|---|
| Tefra | **Obsidiana ígnea**, **azufre negro**, **cuarzo malva** (ya existe) | Blindaje, resistencia al calor, láseres |
| Siroco | **Vidrio de tormenta**, **sal de rocío**, **chatarra antigua** | Motores que no se ahogan, recoger agua, piezas de carrera |
| Tálasa | **Nácar abisal**, **perla de presión**, **coral vivo limpio** | Cascos de presión, sónar, modo submarino |
| Nivalis | **Hielo eterno**, **cristal de eco**, **lana de lanudo** | Abrigo, silenciadores, camuflaje |
| Umbría | **Savia ámbar**, **madera de hierro**, **seda de liana** | Ganchos, cuerdas, estructuras ligeras, drones de apoyo |
| Miasma | **Gas pesado**, **espora de filtro**, **plata de rayo** | Filtros, combustible, armas eléctricas |
| Vértice | **Chips usados**, **luz embotellada**, **aleación de anuncio** | Electrónica, energía, hackeo |

- **Así el comercio entre planetas tiene sentido:** cada objeto de nivel 4–5 lleva **un material de otro
  planeta** (por ejemplo, el respirador de Miasma necesita savia ámbar de Umbría como sellador).

**Cómo funciona una receta:**

1. Se aprende la receta (al empezar, en una misión, comprándola o desmontando un objeto encontrado).
2. En el banco correcto, eliges la receta, ves lo que falta y pulsas **Fabricar**.
3. Las recetas de nivel 3+ tienen un **minijuego corto** (3–8 s: ritmo, temperatura o encajar). Si sale
   **perfecto**, el objeto sale con **calidad alta** (dura un 25 % más). Si sale mal, sale normal: **nunca**
   se pierde el material.
4. Tiempo: instantáneo (nivel 1–2), 5–30 s (nivel 3–4) o una espera real de 10–60 min para las reliquias
   (se puede seguir jugando mientras tanto).

**Tipos de objetos:** equipo contra la desventaja (trajes, filtros, botas, abrigos, cascos);
consumibles (comida, agua, medicinas, antídotos, bengalas, oxígeno, gel térmico); herramientas (pico,
taladro, red, gancho, cuchillo de lianas, escáner, linterna, sonda); armas a pie y sus mejoras; piezas de
nave; muebles y decoración de estilo local; cosméticos (pintura de nave, ropa local).

**Reglas técnicas:**

- Las recetas son **datos** (`shared/Crafting/Recipes.luau`, una tabla por planeta). El servidor comprueba
  materiales, banco cercano y receta aprendida. El cliente nunca dice «he fabricado».
- Se amplía `InventoryService` con una **mochila de materiales** separada (no ocupa la barra rápida), tope
  por material (99) y **almacén en casa**.
- Evento nuevo para las misiones: `ItemCrafted { Recipe, Tier, Planet, Quality }`.

### 2.3 · Astillero: construir naves

**La idea:** el jugador **diseña su propia nave** con piezas, con reglas claras para que siempre vuele
bien, no se pueda hacer trampa y no tumbe el móvil.

**Dónde:** en el **Astillero** de cada planeta y en el Hangar del Garaje Volante. Cada astillero vende y
fabrica las piezas de su planeta.

**Cómo se construye (por ranuras, no pieza a pieza libre).** Una nave = **un casco** + piezas en sus
**ranuras**. El casco decide cuántas ranuras hay.

| Tipo de pieza | Qué decide | Ejemplos |
|---|---|---|
| **Casco** (la forma) | Clase, vida, peso, ranuras, aspecto | Caza ligero, Interceptor, Explorador, Carguero, Corbeta |
| **Motor** | Velocidad, aceleración, impulso | Motor de ceniza (Tefra: potente y caliente), Motor de vela (Siroco: no se ahoga) |
| **Alas / estabilizadores** | Giro y manejo en atmósfera | Alas de seda (Umbría), Aletas de presión (Tálasa) |
| **Arma principal** | Cañones o láser | Láser de cuarzo, Cañón de plata de rayo |
| **Arma secundaria** | Misiles, torpedos, minas | Torpedo de presión (Tálasa) |
| **Escudo** | Escudo y su recarga | Escudo de obsidiana (Tefra) |
| **Módulos** (1–4) | Habilidades y utilidades | Bodega extra, modo submarino, camuflaje, rayo tractor, dron, filtro de atmósfera, sónar, gancho, rompehielos |
| **Pintura y calcas** | Solo aspecto | Colores, dibujos, estelas del motor |

**Las 5 clases de casco:**

| Clase | Ranuras de módulo | Vida | Velocidad | Bodega | Para qué |
|---|---|---|---|---|---|
| Caza ligero | 1 | Baja | Muy alta | 10 | Combate rápido, carreras |
| Interceptor | 2 | Media | Alta | 20 | Combate equilibrado (el Cometa) |
| Explorador | 3 | Media | Media | 30 | Exploración, minería ligera |
| Carguero | 2 | Alta | Baja | 120 | Comercio y transporte |
| Corbeta | 4 | Muy alta | Baja | 60 | Defensa, misiones duras (se abre tarde) |

**Cuentas que hacen que la nave sea justa (todo lo calcula el servidor):**

- **Energía:** cada pieza gasta energía; el motor da un máximo. Si te pasas, la nave no se puede guardar
  («Te faltan 12 de energía»).
- **Peso:** más peso = menos aceleración y giro. Una nave llena de armas es lenta.
- **Nivel de piezas** (1 a 5). La suma da la **Potencia de la nave**, que se ve en el HUD y que las
  misiones usan para recomendar («Potencia recomendada: 18»).
- **Nada se acumula sin límite:** dos escudos no se suman y cada módulo va una sola vez.
- **Chispas de estrella:** sirven para **mejorar** cada pieza del 1 al 5 (como ya dice la Saga 2).

**Planos (cómo se guarda una nave):**

- Una nave **no se guarda como piezas de Roblox**, sino como un **plano**: una lista corta de datos
  (`{ Hull = "Interceptor", Engine = "MotorCeniza", Levels = {...}, Modules = {...}, Paint = {...} }`).
  Ocupa muy poco en el guardado (`data.Ships`).
- El servidor **dibuja la nave** a partir del plano con el constructor que ya existe (`ShipModel`,
  ampliado con piezas por ranura). **Tope: 150 partes por nave** (5.3).
- **Ranuras de planos:** 3 de inicio; se ganan más jugando (misiones del astillero) y el pase premium da
  más (2.8).
- **Hangar:** guarda las naves construidas (tope 10). Al pedir una nave en un puerto, el servidor la dibuja
  junto al jugador y la aparca al bajar (como hoy en Tefra). **Una nave en el mundo por jugador a la vez.**
- Los planos se pueden **compartir** con amigos como «copia del diseño»: el otro ve la lista de piezas que
  le faltan y las tiene que conseguir él.

**Antiabuso:**

- El cliente solo manda «quiero esta pieza en esta ranura». El servidor comprueba que tienes la pieza, que
  cabe, la energía y el peso, y recalcula todo.
- Las estadísticas **nunca** salen del cliente: el vuelo (`ShipFlight`) recibe los números del servidor y
  el servidor sigue validando cada «Pose» con esos números (como ya hace `plausible`).
- Si un plano se queda inválido tras una actualización de equilibrio, la nave sale con las piezas que sí
  valen y avisa; nunca se pierde nada.
- En **modos competitivos** (carreras clasificatorias, arenas) se usa la **nave igualada** (2.8).

**13+:** las naves revientan con bola de fuego y restos; los pilotos enemigos nunca se ven morir.

**Naves y módulos de la historia:** el Cometa (de inicio), el **Aguijón** (Siroco), la **Tortuga**
(Miasma) y los módulos de cada episodio (escudo de Tefra, turbo doble de Siroco, modo submarino y rayo
tractor de Tálasa, camuflaje de Nivalis, drones de Umbría, llamada de escolta de Miasma) pasan a ser
**piezas del astillero** que se desbloquean al terminar cada episodio.

### 2.4 · Economía y rutas de comercio

**Dos monedas, y nada más:**

| Moneda | Para qué | De dónde sale |
|---|---|---|
| **Dinero de Valmar (€)** | Tiendas, viviendas, comida, pasajes, piezas básicas, negocios, materiales comunes | Trabajos, comercio, misiones, vender recursos |
| **Chispas de estrella (✨)** | Mejorar piezas de nave del 1 al 5 y algunas recetas de reliquia | Combate, cajas, misiones duras, encargos peligrosos (con tope por hora) |

- **No hay moneda nueva por planeta.** Lo que hay por planeta es **reputación** con sus bandos (de −100 a
  +100), que abre tiendas, precios, misiones y finales distintos.
- Las Chispas **no se venden sueltas** por Robux; el pase premium sí hace que se ganen más rápido (2.8).

**Precios distintos en cada planeta.** Cada planeta **produce** unas cosas (baratas allí) y **necesita**
otras (caras allí). El Tablón de la Galaxia enseña los precios de los planetas que has visitado.

| Mercancía | Tefra | Siroco | Tálasa | Nivalis | Umbría | Miasma | Vértice |
|---|---|---|---|---|---|---|---|
| Agua | Media | **Muy cara** | **Muy barata** | Barata (hielo) | Barata | Cara | Media |
| Comida | **Cara** (guerra) | Cara | Barata (algas) | Media | **Barata** | Cara | Media |
| Medicinas | **Muy cara** | Media | Cara (plaga) | Media | Media | Cara | Barata |
| Metal y mineral | **Barata** | Media | Cara | Barata (minas) | Cara | Media | Media |
| Madera y fibra | Cara | Cara | Media | Cara | **Muy barata** | Cara | Cara |
| Combustible y gas | Media | Media | Media | Cara (frío) | Media | **Muy barato** | Cara |
| Electrónica | Media | Cara | Barata | Cara | Cara | Media | **Muy barata** |
| Ropa de abrigo | Barata | Barata | Media | **Muy cara** | Barata | Media | Media |

**Rutas de comercio** (ejemplos para el tutorial del Comerciante):

- **La ruta del agua:** hielo de Nivalis o agua de Tálasa → Siroco. La más rentable; las tormentas y los
  Clanes de la Duna asaltan los cargueros.
- **La ruta de la madera:** madera de hierro de Umbría → Tefra (para reconstruir) y Vértice.
- **La ruta del gas:** gas pesado de Miasma → Nivalis (calefacción). Hay que cruzar el bloqueo del Dominio.
- **La ruta de los chips:** electrónica de Vértice → todos.

**Reglas para que el comercio no se rompa:**

- **El precio baja cuando vendes mucho de lo mismo** en el mismo sitio (saturación) y se recupera solo con
  las horas.
- **Topes:** como mucho X unidades vendidas por mercancía y por hora en cada mercado (en `Config`).
- **Riesgo real:** si te derriban con carga, pierdes el **30 %**; el resto queda en la «caja negra» y se
  recupera volviendo al sitio antes de 10 minutos.
- **Todo lo cuenta el servidor** (precios, ventas, bodega). Comercio entre jugadores solo por
  `TradeService`, con sus límites.
- **Sucesos que mueven precios:** un bombardeo en Tefra sube las medicinas un 40 % durante una hora; una
  tormenta en Siroco sube el agua. Salen en el Tablón como noticias.

### 2.5 · Vivienda en los planetas

- En cada ciudad hay **3 tipos**: **alquiler barato** (una habitación), **piso** (con taller y almacén) y
  **casa singular** (de lujo local: vaina colgante en Umbría, cúpula bajo el agua en Tálasa, torreón de
  piedra en Nivalis…).
- Se reutiliza `HousingService` / `PropertyService` (interiores, decoración, dueño). Cada vivienda es un
  **interior** que se carga solo cuando entras (5.3), así no suma piezas al planeta.
- **Para qué sirve:** reaparecer allí, guardar materiales, taller propio, dormir (recupera energía y quita
  efectos de la desventaja) y decorar con muebles del planeta.
- **El Garaje Volante** sigue siendo la casa principal de la Saga 2.
- **Mejoras contra la desventaja:** aislante (Tefra), cisterna (Siroco), compuerta de presión (Tálasa),
  chimenea (Nivalis), barandilla y red (Umbría), filtro de aire (Miasma), caja fuerte contra embargos
  (Vértice).

### 2.6 · Transporte y viajes

**Entre planetas:**

- **Volando de verdad:** desde el espacio de Valmar, con hipervelocidad y salto cuántico (ya existen),
  hasta la **órbita** del planeta y luego **entrada en la atmósfera sin pantalla de carga** (como hoy en
  Tefra).
- **Coste del viaje:** el salto cuántico a otro planeta gasta energía de la nave y una **tasa de puerto**
  pequeña al aterrizar (20–60 €). Sin nave, el **Transbordador** del puerto cobra un billete (150–400 €
  según la distancia) y te deja en el puerto del planeta.
- **La Aguja de oro mejorada** (recompensa del episodio de Vértice) permite volver a cualquier planeta ya
  visitado desde el Garaje Volante, gratis.

**La capa de órbita de cada planeta** (el tipo «espacial»): el campo de batalla con la luna Ovilla
(Tefra), los anillos de polvo de vidrio (Siroco), las tres lunas y una estación científica (Tálasa),
satélites espía del Regente (Nivalis), semillas gigantes flotando (Umbría), la flota del Dominio (Miasma)
y los astilleros orbitales (Vértice). Ahí hay minería de asteroides y combate.

**Dentro del planeta:** cada ciudad tiene **su transporte público** y **sus vehículos** (ver cada
planeta). Se reutiliza `VehicleBuild`, `BusService`, `RailService`, `MetroService` y `BoatService` con
otros modelos. Fuera de la ciudad hay **balizas de viaje rápido** que se abren al descubrirlas (coste
pequeño).

### 2.7 · La desventaja de cada planeta (sistema común de «Entorno»)

Todas las desventajas usan **un mismo sistema** (`EnvironmentService`, nuevo):

- **Un medidor en el HUD** (solo en ese planeta): Calor, Sed, Presión/Oxígeno, Frío, Esporas, Toxinas o
  Deuda. Se llena según dónde estés, la hora y el clima.
- **Tres fases:** normal → aviso (efectos de pantalla, el personaje tose o tiembla, va más lento) →
  peligro (pierde vida poco a poco). **Nunca muerte de golpe.**
- **Contramedidas:** equipo (reduce lo que sube), consumibles (lo bajan de golpe) y refugios (lo vacían).
- **Si caes:** «Derribado» y vuelves al último punto de control o refugio; pierdes una parte del material
  que llevabas (no el equipo).
- **Ayuda para quien empieza:** las primeras 2 horas de cada planeta el medidor sube más despacio, y la
  misión principal te da el primer equipo.
- Las misiones lo pueden usar como **condición de fallo** (apartado 4).

### 2.8 · Monetización y pase de batalla

**Decisión del dueño:** el pase premium **ayuda de verdad**: quien paga termina, recoge, fabrica, explora y
compra más rápido, y por eso sube de nivel más rápido en todo (personaje, nave, armas, habilidades). La
ayuda es **moderada** y se nota con las semanas, no de golpe. **Y cuantas más horas se juega con el
pase, más grande es la diferencia.** Quien no paga puede llegar a todo, más despacio.

Esto **sustituye** la regla anterior de `docs/pase-de-temporada.md` («valor, no poder»). El pase de la
Temporada 1 «Luces de Valmar» ya está publicado con esa regla: los cambios entran **desde la siguiente
temporada** (pregunta 2), para no cambiar lo prometido a quien ya lo compró.

#### 2.8.1 · Qué da el premium (todo son multiplicadores sobre lo que ganas jugando)

| Ayuda | Gratis | Premium | Notas |
|---|---|---|---|
| Experiencia (personaje, trabajos, nave, armas, habilidades) | ×1,00 | **×1,15** | Sobre todo lo que da XP. |
| **Bonificación de constancia** | — | **+1 % de XP por cada 10 h jugadas en la temporada, hasta +15 %** (a las 150 h) | Es lo que hace que la diferencia **crezca con las horas**. |
| Recolectar y minar (cantidad por acción) | ×1,00 | **×1,20** | El tope por hora del servidor también sube un 20 %. |
| Dinero de trabajos y misiones | ×1,00 | **×1,10** | No afecta a lo que pagan otros jugadores. |
| Chispas de estrella | ×1,00 | **×1,15** | Tope por hora: 40 → 46. |
| Tiempo de fabricación | 100 % | **70 %** | Las reliquias de 60 min tardan 42. |
| Recargas de habilidades a pie y de nave **fuera de modos competitivos** | 100 % | **85 %** | |
| Coste de viajes (tasas, transbordador, balizas) | 100 % | **75 %** | |
| «Descanso»: horas al día a ritmo completo | 2 h | **3 h** | Después, la XP baja al 60 % (gratis) o al 85 % (premium) hasta el día siguiente. |
| Misiones a la vez | 3 secundarias | **4** | |
| Ranuras de planos de nave | 3 (+ las que ganes) | **+3** | |
| **Misiones premium diarias y semanales** | — | **2 diarias + 1 semanal premium**, que **se acumulan** hasta 7 días si no se juegan | Dan XP, materiales y Chispas. |
| **Línea premium de cada planeta** | Solo el capítulo 1 | **Completa** (5 capítulos con historia) | Ver cada planeta. Dan mejores premios (materiales de reliquia, recetas, Chispas). |
| Cosméticos del pase | Algunos | Todos | Como ahora. |

**Lo que el premium nunca da:** ni piezas, armas o recetas **exclusivas** que no se puedan conseguir
gratis (las de la línea premium también salen gratis por otro camino más largo: tienda de reputación o
jefes), ni ventaja en **modos competitivos** (2.8.3), ni cajas sorpresa de pago.

#### 2.8.2 · Las curvas: gratis contra premium según las horas

Cuentas con un jugador que juega **2,5 horas al día** (el ritmo de un jugador constante). «Puntos» =
experiencia total (100 puntos por hora a ritmo normal). Gratis: 2 h a ritmo completo y 0,5 h al 60 % =
**92 puntos por hora** de media. Premium: ×1,15, sin bajar (tiene 3 h de descanso), más la constancia,
más sus misiones diarias (40 al día) y semanal (200).

| Horas jugadas en la temporada | Gratis (puntos) | Premium (puntos) | Premium / gratis | Diferencia | En horas de juego gratis |
|---|---|---|---|---|---|
| 10 h | 920 | 1.430 | ×1,55 | 510 | ≈ 5,5 h |
| 50 h | 4.600 | 7.250 | ×1,58 | 2.650 | ≈ 29 h |
| 100 h | 9.200 | 14.760 | ×1,60 | 5.560 | ≈ 60 h |
| 200 h | 18.400 | 30.640 | ×1,67 | 12.240 | ≈ 133 h |

- Con **poco juego** (1 h al día) la diferencia es menor en total (las misiones premium pesan más, pero no
  hay «descanso» que gastar): ×1,4–1,5.
- Con **mucho juego** (5 h al día) la diferencia crece más: el gratis pasa más tiempo al 60 % y el premium
  al 85 %, y la constancia sube antes: ×1,9–2,0 a las 200 h.
- **Recolectar y fabricar** siguen la misma idea: a las 100 h, un premium ha juntado ≈ 1,35 veces más
  material y ha fabricado ≈ 1,6 veces más objetos (por el tiempo de fabricación).

**Qué significa en metas reales** (estimación con 2,5 h al día):

| Meta | Gratis | Premium |
|---|---|---|
| Rango Maestro en un trabajo | ≈ 55 h | ≈ 36 h |
| Nave de Potencia 25 (todas las piezas de nivel 4) | ≈ 70 h | ≈ 45 h |
| Equipo de reliquia de un planeta | ≈ 25 h | ≈ 16 h |
| Todo el contenido de un planeta (100 %) | ≈ 14 h | ≈ 10 h |
| Nivel 50 del pase | ≈ 8 semanas | ≈ 5 semanas |

**Topes para que nadie se quede atrás para siempre:**

- **Nivel máximo blando por temporada** (para todos): cada temporada sube el nivel máximo de piezas y de
  personaje. Quien llega antes se queda en el techo; quien llega tarde lo alcanza. Así la diferencia de
  **poder** entre gratis y premium se **cierra** al final de cada temporada aunque la de **tiempo**
  exista.
- **Ayuda de alcance** (gratis): si estás muy por debajo del nivel recomendado de tu planeta, ganas un
  +25 % de XP hasta alcanzarlo.
- Los multiplicadores **no se suman entre sí sin límite**: el máximo total de XP por hora de un premium es
  ×1,32 sobre el ritmo normal (×1,15 × constancia ×1,15 como mucho), más sus misiones.

#### 2.8.3 · Juego justo en lo competitivo

- **Modos igualados:** carreras clasificatorias (Gran Vuelta de Siroco, regatas, carreras de planeadores),
  arenas de combate y cualquier jugador contra jugador futuro usan **naves y armas igualadas** (mismas
  estadísticas para todos; solo cambia el aspecto) o emparejan por **Potencia**.
- Las **clasificaciones** (récords) solo cuentan en modos igualados.
- En modos de grupo (hasta 4, más adelante) la recompensa se calcula **para cada uno** con sus
  multiplicadores; nadie gana menos por jugar con alguien sin pase.

#### 2.8.4 · Normas de Roblox y transparencia

- El premium es un **Game Pass por temporada** (como ahora). Precio en el Creator Dashboard.
- Antes de comprar, una ventana enseña **la tabla 2.8.1 con números**, sin letra pequeña.
- **Sin cajas sorpresa de pago.** Si se añade algo con azar, se muestran las probabilidades.
- Nada de «compra ya o lo pierdes» engañoso; el contenido del pase pasado se archiva como ahora.
- Se rellena el cuestionario de madurez de Roblox con el contenido real (13+) y se revisan las normas de
  monetización de Roblox antes de cada temporada.

#### 2.8.5 · Cómo se programa (resumen)

- `BattlePass/Config.luau`: tabla `PremiumBoosts` con todos los números de 2.8.1 (solo datos).
- Un único sitio que aplica los multiplicadores: `BoostService.mult(player, "Xp" | "Gather" | "Money" |
  "Chispas" | "Craft" | "Cooldown" | "Travel")`, que leen `ProgressionService`, la minería, la
  fabricación, `ShipSystems`, los viajes y los trabajos. Así no hay números repartidos.
- `BoostService` devuelve 1 en modos igualados (`player:GetAttribute("Ranked")`).
- Las misiones premium diarias/semanales van en `SeasonMissionService` (ya existe), con su acumulación.
- Las líneas premium de cada planeta van en el motor LifeStory con un requisito `Premium = true`
  (apartado 4) y su capítulo 1 sin requisito.

---

## 3 · Los 7 planetas

Cada planeta sigue el mismo guion de apartados:

1. La idea en una frase · 2. Identidad y tono · 3. Geografía, biomas y puntos de interés · 4. Clima y
día/noche · 5. Flora y fauna · 6. Recursos · 7. La ciudad · 8. Forma de vida, leyes y bandos ·
9. Trabajos propios · 10. Mecánica única · 11. Desventajas y contramedidas · 12. Su «mar» · 13. Ocio ·
14. Equivalencias con Valmar · 15. **Biblia narrativa** · 16. Misión principal (episodio) ·
17. Cadenas secundarias · 18. Eventos dinámicos · 19. Línea premium · 20. Horas de juego.

**Cómo leer una cadena secundaria:** cada una tiene *personajes y motivos*, *trasfondo*, *gancho*,
*fases* (con el tipo de juego de cada una y cómo sube lo que está en juego), *giro*, *decisión y
consecuencias*, *momento estrella*, *final* y *lazo con el Ragnarock*.

---

### 3.1 · TEFRA · Bastión Ceniza

> **Episodio 1 · «Ceniza en Bastión».** Volcánico, ceniza. Fortaleza industrial y militar entre lava.
> Ragnarock: **la guerra contra su propia luna, Ovilla.** Protagonista: **Dalia Renn**.

#### 1. La idea en una frase

Un planeta de volcanes donde una ciudad-fortaleza forja armas sobre ríos de lava mientras la luna de
enfrente le dispara, y donde Cosme vuelve a casa para descubrir que ya no existe.

#### 2. Identidad y tono

- **Fantasía del jugador:** soldado de fortuna en una guerra que no es tuya; caminar entre fundiciones al
  rojo, sobrevivir a bombardeos con horario y pilotar bajo fuego antiaéreo.
- **Tono:** drama de guerra con humor negro de trinchera. Ceniza, sirenas, fuego y gente que sigue
  haciendo pan entre bombardeo y bombardeo.
- **Colores:** negro basalto, naranja de lava, malva del cielo (lo único que queda del Tefra de antes),
  gris de ceniza.
- **Sonido:** martillos de forja, sirenas, el retumbar de los volcanes, la artillería lejana de Ovilla.
- **Cómo se ve la gente** (traje Camaleón): redondeada, tipo plastilina, con bufandas gastadas y gafas de
  soldador.

#### 3. Geografía, biomas y puntos de interés

| Bioma | Cómo es | Qué se hace |
|---|---|---|
| **Llanura de Ceniza** (la región que ya existe de Lontana, convertida) | Colinas suaves cubiertas de ceniza malva, cráteres de bombas, restos de naves. | Primera región: tutorial, minería de cuarzo malva, restos de la Escuadrilla de Ovilla. |
| **Campos de Coladas** | Ríos de lava que cambian de camino cada día (el servidor elige el trazado del día). | Exploración con calor extremo, obsidiana ígnea. |
| **Bosque Petrificado** | Árboles quemados convertidos en piedra, setas de ceniza que brillan. | Recolección, criaturas, escondites de desertores. |
| **Fumarolas de Azufre** | Valle de vapor amarillo, aire irrespirable a ratos. | Azufre negro; hace falta filtro. |
| **La Caldera Roja** | El gran lago de lava junto a la ciudad («el mar» de Tefra). | Barcazas térmicas, pesca térmica, jefe. |
| **Trincheras del Este** | Frente de guerra abandonado: búnkeres, minas sin explotar. | Desactivar munición, chatarra militar. |
| **Órbita: el Frente de Ovilla** | Espacio entre Tefra y su luna, lleno de restos y baterías. | Combate espacial, minería de restos. |

**Puntos de interés** (cada uno con su pequeña historia):

- **Baliza de señal** (ya existe): «…aquí Redonda… el Muelle está tomado…». Ahora dice «Bastión».
- **El Pecio de la Escuadrilla** (ya existe como «Restos de una nave»): falta la caja negra. Se encuentra
  en la cadena «La caja negra».
- **La Forja Muerta:** una fundición abandonada tras una explosión; dentro, un banco de reliquias.
- **El Puente de los Mil Candados:** un puente sobre la lava donde las familias cuelgan candados con los
  nombres de los que no volvieron.
- **Observatorio de Ovilla:** una cúpula con un telescopio que apunta a la luna. Desde allí se ven los
  fogonazos.
- **El Huerto de Nilda:** el sitio donde Cosme hizo su experimento antes de caer a Valmar. Hay una marca
  quemada en forma de grieta.

#### 4. Clima y día/noche

- **Día de 40 minutos reales** (más corto que el de Valmar): luz malva y naranja; la luna Ovilla ocupa
  medio cielo.
- **Noche:** los fogonazos de la guerra en Ovilla iluminan el cielo; los ríos de lava son la luz principal.
- **Lluvia de ceniza y pelusa** (como ya existe): baja la visibilidad.
- **Terremotos:** cada 8–15 minutos, un temblor de 10 s (la cámara tiembla, caen piedras en zonas
  marcadas).
- **Bombardeo con horario:** dos veces por día de juego, la artillería de Ovilla dispara sobre zonas
  marcadas; suenan sirenas 60 s antes.

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Seta de ceniza** | Seta gris que brilla en naranja | Se recolecta: comida y medicina. |
| **Liquen térmico** | Manto rojo sobre la roca caliente | Ingrediente de gel térmico. |
| **Salamandra de ceniza** | Lagarto del tamaño de un perro, piel de brasa | Pacífica; si la molestas, escupe chispas. Se puede domesticar como mascota (`PetService`). |
| **Escarabajo de escoria** | Escarabajo con caparazón de metal fundido | Come chatarra: si lo sigues, te lleva a vetas. |
| **Anguila de magma** | Pez largo que nada en la lava | Se «pesca» con caña térmica (pesca térmica). |
| **Cuervo de humo** | Pájaro negro que vuela en bandadas | Avisa de bombardeos (vuelan todos antes de que empiece). |
| **Gusano Brasero** (peligroso) | Gusano gigante que sale de la lava | Embosca en las coladas. **Jefe** de la cadena «Fuego que camina». |
| **Drones de Ovilla** (enemigos) | Drones de reconocimiento y ataque | Patrullan las Trincheras. |

#### 6. Recursos

- **Únicos:** obsidiana ígnea (en las coladas), azufre negro (fumarolas), cuarzo malva (ya existe).
- **Comunes abundantes:** hierro, carbón, chatarra militar.
- **Escasos:** agua limpia, comida, medicinas (por eso son caros aquí).

#### 7. La ciudad: Bastión Ceniza

**Estilo:** fortaleza industrial y militar levantada sobre una meseta de basalto rodeada de lava. Murallas
negras con bocas de cañón, chimeneas de fundición, puentes de hierro sobre canales de lava, cúpulas
partidas del Tefra «redondo» de antes (lo antiguo es redondo; lo militar, de esquinas duras: la ciudad
cuenta su historia con su forma).

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Barrio del Ovillo** | Casco viejo de cúpulas, la casa de la familia de Cosme, la panadería. | Bombardeado. La casa de Cosme es un esqueleto. |
| **Mercado Espiral** | Calle-mercado en espiral que baja hacia la lava. | Mercado negro: comida, medicinas y armas. |
| **Muelle Bastión** | Puerto espacial y astillero. | Base militar. Nadie sale sin permiso. |
| **Campus Nilda** | La academia de la abuela. | Hospital de campaña y refugio. |
| **Los Pozos de Magma** | Central geotérmica que daba luz a la ciudad. | El General Corvo la convierte en un arma: **la Lanza**. |
| **Mirador de las Lunas** | Plaza con lago templado y la estatua de la abuela Nilda. | Campamento de refugiados. La estatua sigue en pie. |
| **Las Fundiciones** | Fábricas de armas y blindaje. | Trabajan día y noche; trabajo obligatorio para refugiados. |
| **La Muralla** | Anillo defensivo con torres de artillería. | Primera línea contra los bombardeos. |

- **Transporte:** tren de cremallera blindado (sustituye al metro; funciona a ratos), camiones militares,
  motos de ceniza, **barcazas térmicas** en la Caldera.
- **Tiendas:** el mercado negro (todo caro), el puesto de sopa del Campus, la armería del Muelle (solo con
  rep militar), la forja de Bastión.
- **Negocios que se pueden comprar:** puesto en el Mercado Espiral, taller de blindaje en las Fundiciones.

#### 8. Forma de vida, leyes y bandos

- **Vida:** colas para el agua, toques de queda con sirena, patrullas, niños jugando entre escombros,
  refugiados que llegan cada día, pan que se reparte al amanecer.
- **Leyes:**
  - **Toque de queda** de 22:00 a 6:00: en la calle sin permiso, te para la policía militar (multa o
    calabozo, que reutiliza `PoliceService` y `PrisonService`).
  - **Requisa:** la policía militar puede quitarte armas y medicinas si no tienes papeles (la cadena
    «Papeles» te los consigue).
  - **Desertar es delito:** ayudar a desertores baja tu rep con el Ejército.
- **Costumbres:** colgar candados en el Puente de los Mil Candados; el «pan de sirena» (se comparte después
  de cada bombardeo); nadie dice el nombre de Ovilla en voz alta en la Muralla.
- **Bandos (rep):**
  - **El Ejército de Bastión** (General Corvo): orden, papeles, armería. Duro pero protege.
  - **Los Desertores del Ovillo** (Dalia): túneles, información, la verdad.
  - **El Mercado Espiral** (la contrabandista **Madre Hollín**): precios, contrabando.
  - **Los Refugiados del Mirador** (portavoz **Fermina**): gratitud, ayuda en las misiones de rescate.

#### 9. Trabajos propios de Tefra

| Trabajo | Qué haces | Bucle | Desventaja que se juega |
|---|---|---|---|
| **Fundidor/a** | Funde mineral en las Fundiciones. | Cargar el crisol → controlar la temperatura (minijuego de aguja) → colar en moldes. | Calor: el medidor sube junto al crisol. |
| **Desactivador/a de munición** | Limpia bombas sin explotar de calles y trincheras. | Localizar con detector → cortar cables en el orden correcto (puzle con pista) → retirar. | Si fallas, explosión (Derribado, sin sangre). |
| **Bombero/a de coladas** | Desvía ríos de lava que amenazan barrios. | Llegar → colocar barreras de basalto → enfriar con agua a presión. | Calor y tiempo límite. |
| **Correo de túnel** | Lleva mensajes por los túneles bajo la ciudad en toque de queda. | Ruta con patrullas que esquivar (sigilo ligero). | Toque de queda y policía militar. |

#### 10. Mecánica única: **la guerra con horario y el calor**

- **Bombardeos con horario:** la ciudad cambia según el reloj: antes del bombardeo todo el mundo corre a
  los refugios; después, hay escombros que retirar (trabajos), heridos (médico), incendios (bombero) y
  saqueos (seguridad). **La ciudad tiene un antes y un después cada día.**
- **El frente se mueve:** según las misiones que hagas (y la decisión final), unas zonas se abren o se
  cierran (`WorldMemoryService`).
- **Tiros a pie con coberturas:** Tefra es el planeta del combate a pie (tutorial de armas de la Saga 2).

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Calor** (medidor) | Cerca de la lava y en las Fundiciones sube rápido: vas más lento, la pantalla ondula, pierdes vida. | Traje refrigerado (nivel 2–5), **gel térmico** (consumible), botas de basalto (andar sobre roca caliente), refugios frescos. |
| **Aire con ceniza y azufre** | Visibilidad baja y tos en las Fumarolas y con lluvia de ceniza. | Filtros, mascarilla, gafas de soldador. |
| **Bombardeos** | Zonas marcadas reciben fuego. | Refugios, sirenas, los cuervos de humo; casco reforzado. |
| **Terremotos** | Caen piedras, se rompen puentes. | Escuchar el aviso (el suelo vibra antes), casco. |
| **Escasez** | Agua, comida y medicinas carísimas. | Comprar fuera (comercio), cultivar setas de ceniza, cadena «El pan de sirena». |
| **Ley militar** | Toque de queda y requisas. | Papeles (cadena), sigilo, rep con el Ejército. |

#### 12. Su «mar»: la Caldera Roja

- Lago de lava de 1 km con islas de basalto. Se navega en **barcaza térmica** (`BoatService` con otro
  modelo; el casco se calienta: hay que volver a la orilla antes de que llegue al máximo).
- **Pesca térmica:** caña de cadena; se pescan anguilas de magma y «perlas de lava» (se reutiliza la base
  de `FishingService` con otra tabla de capturas).
- **Buceo:** no se bucea en lava. El equivalente es **bajar a los Tubos de Lava**: cuevas vacías bajo la
  Caldera, con la lava pasando por encima (se ve por grietas). Ahí está el jefe Gusano Brasero.

#### 13. Ocio

| En Valmar | En Tefra |
|---|---|
| Feria del sábado | **La Fiesta del Último Fuego**: cada 7 días de juego, en el Mirador: farolillos, tiro con dianas de chatarra, puesto de pan de sirena, música de forja. |
| Karting | **Vagonetas de mina**: carrera en las vías de las Fundiciones (3 vueltas, con saltos sobre canales de lava). |
| Fútbol / deportes | **Pelota de ceniza**: 3 contra 3 en una explanada de la Muralla con una pelota pesada que deja estela. |
| Playa | Los baños termales del Campus (de antes de la guerra; ahora refugio, pero se puede descansar: quita Calor y da diversión). |
| Skate | Rampas de chatarra en las Trincheras (en manos de los críos del Mirador). |

#### 14. Equivalencias con Valmar

| Valmar | Tefra |
|---|---|
| Coche propio | Moto de ceniza (ruedas anchas, aguanta calor) |
| Bus / metro | Tren de cremallera blindado |
| Barco | Barcaza térmica |
| Granja | Cultivo de setas de ceniza en invernaderos de las Fundiciones |
| Pesca | Pesca térmica en la Caldera |
| Hospital | Campus Nilda (hospital de campaña) |
| Policía / cárcel | Policía militar / calabozos del Muelle |
| Supermercado | Reparto de raciones + mercado negro |

#### 15. Biblia narrativa de Tefra

- **Historia del planeta:** Tefra y su luna **Ovilla** fueron un solo pueblo. Hace 80 años, las familias
  más pobres se fueron a minar Ovilla. Ovilla se hizo rica con el cuarzo y quiso ser libre; Tefra le cobró
  impuestos por el aire y el agua que mandaba. Hace 6 años empezó la guerra. Nadie recuerda bien quién
  disparó primero: cada bando enseña a sus niños una versión.
- **Por qué es volcánico ahora:** antes de la guerra Tefra era de colinas suaves («nada tiene esquinas»).
  Las bombas de Ovilla rompieron la corteza en el Este y despertaron los volcanes dormidos. **El planeta se
  está rompiendo por dentro** a causa de la guerra: si sigue, los volcanes se tragarán el resto.
- **Cosme:** nació aquí. Su familia vivía en el Barrio del Ovillo. Su abuela Nilda fundó la academia que
  ahora es hospital. Cosme se fue (cayó a Valmar) hace 38 años, antes de la guerra. Su hermana **Ada**
  murió hace dos años en un bombardeo (se descubre en el episodio).
- **Bandos:** el Ejército de Bastión (Corvo), los Desertores del Ovillo (Dalia), el Mercado Espiral
  (Madre Hollín), los Refugiados (Fermina) y, al otro lado, la **Milicia de Ovilla** (capitán Tobi Renn).
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Dalia Renn** (34) | Sargento desertora | Que acabe la guerra y que Tobi vuelva vivo | La primera vez, cumplió la orden de disparar sobre refugiados |
| **General Bastián Corvo** | Jefe del Ejército | Ganar la guerra «para que no haya otra» | Sabe que la Lanza agrietará el planeta y le da igual |
| **Tobi Renn** | Hermano de Dalia, capitán en Ovilla | Proteger su ciudad lunar | Fue él quien pidió los bombardeos sobre el Muelle |
| **Fermina** | Médica del Campus | Salvar a quien pueda | Fue una de las heridas del disparo de Dalia |
| **Madre Hollín** | Reina del mercado negro | Ganar dinero y que su barrio coma | Vende a los dos bandos |
| **Brasa** (12) | Niña refugiada que hace recados | Encontrar a su padre | Su padre es un desertor buscado |
| **Ingeniero Orsi** | Constructor de la Lanza | Que su obra funcione | Ha preparado un fallo secreto, pero no se atreve a usarlo |

- **Secretos del planeta** (para cadenas y exploración):
  1. **El primer disparo** de la guerra fue un accidente en una mina de Ovilla que los dos gobiernos
     taparon (cadena «La caja negra»).
  2. **La Forja Muerta** no explotó por un accidente: alguien la saboteó para que el Ejército construyera
     la Lanza en los Pozos.
  3. **El Huerto de Nilda** guarda los cálculos de la abuela: el primer viaje entre universos.
  4. Bajo la Caldera hay **ciudades del Tefra antiguo** tragadas por la lava.

#### 16. Misión principal: «Ceniza en Bastión» (episodio 1, ≈ 2,5 h)

Adaptación del episodio 1 de la Saga 2 (Lontana/Redonda → Tefra/Bastión Ceniza; los Molinos de Luz → los
Pozos de Magma). **Cada misión tiene varias fases, juego variado y al menos una decisión.**

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Caída sobre Bastión** | (a) Cruzas el ojal en mitad de una batalla aérea sobre la ciudad (vuelo, tutorial); (b) te derriban: caída controlada entre chimeneas (secuencia de vuelo con daños); (c) aterrizaje forzoso en la Llanura de Ceniza; (d) primer contacto con el calor (tutorial del medidor) y con la ceniza. | — (tutorial) |
| 2 | **La casa de Cosme** | (a) Cruzar la Llanura hasta la ciudad esquivando drones (sigilo corto); (b) ruinas del Ovillo: Cosme busca su casa (exploración con diálogo); (c) emboscada de la policía militar: Dalia os salva (primer tiroteo a pie, coberturas); (d) huida por los túneles. | **¿Ayudas a Brasa** (la niña que os ve escapar) a esconderse o la dejas? Si la ayudas, después te avisa de una emboscada (misión 5) y abre la cadena «El padre de Brasa». |
| 3 | **La lista** | (a) Conseguir uniformes en las Fundiciones (trabajo de fundidor como disfraz); (b) infiltración en el Muelle con el traje Camaleón; (c) robar las órdenes del despacho de Corvo (sigilo); (d) la alarma salta: escapar por los tejados. Descubrís el plan de la Lanza. | **¿Te llevas también los papeles de los desertores?** Sí: Dalia confía más (rep Desertores +20) pero Corvo pone precio a tu cabeza (más patrullas). |
| 4 | **Los Pozos** | (a) Bajar a los Pozos de Magma con calor extremo (gestión del medidor, gel térmico); (b) poner cargas en 3 conductos (objetivos en cualquier orden) bajo fuego de artillería; (c) el **Ingeniero Orsi** os descubre: os ofrece su fallo secreto si le sacáis vivo. | **Orsi:** sacarle (escolta lenta, la misión es más dura; él sabotea la Lanza desde dentro y se acorta la misión 6) o dejarle (más rápido; Orsi muere fuera de cámara y Dalia lo ve). |
| 5 | **Al otro lado** | (a) Vuelo a Ovilla entre baterías antiaéreas (combate espacial); (b) aterrizaje en la luna y combate a pie con poca gravedad; (c) encontráis a Tobi. **Momento fuerte:** «Tú también nos disparabas». | **¿Le cuentas a Tobi lo de la Lanza?** Sí: Ovilla evacua sus ciudades (menos muertos al final; Tobi manda carta). No: Tobi no se fía de nadie y el final es más duro. |
| 6 | **La Lanza** | (a) Corvo dispara: la primera descarga agrieta el Este (los volcanes se despiertan en toda la región; el mapa cambia); (b) gran batalla espacial para romper la lente antes del segundo disparo (jefe: **la Lanza**, 3 fases: escudos, torretas, núcleo); (c) huida del núcleo que revienta. | — |
| 7 | **Alto el fuego** | (a) Escoltar a Dalia por la ciudad, con los dos bandos buscándola (tiroteo urbano); (b) en el Mirador, ante las cámaras: Dalia cuenta **la verdad, también la suya** (escena con decisiones de apoyo); (c) **momento de silencio:** Cosme ante la estatua de Nilda. | **¿Apoyas a Dalia en público o te quedas atrás?** Cambia la frase final de Dalia y si Fermina la perdona. |

- **Giro:** la culpa de Dalia (cumplió la orden la primera vez; Fermina fue una de las heridas).
- **Final (agridulce):** la Lanza cae, alto el fuego. Tobi no vuelve, manda una carta (o no, según la
  misión 5). Dalia se entrega. Cosme se entera de que su hermana Ada murió. «Vámonos. Aquí ya no puedo
  ayudar.»
- **Consecuencias en el mundo:** tras el episodio, Bastión pasa a «tregua»: se acaban los bombardeos con
  horario (salvo en eventos), se abren las Trincheras del Este y el Mercado Espiral vuelve a vender comida.
  La Sala de recuerdos recibe la **bufanda de Ada**.
- **Recompensa:** rifle de Dalia, **escudo de nave** (pieza del astillero), receta de traje refrigerado
  nivel 3.

#### 17. Cadenas secundarias de Tefra

**A. «La caja negra»** (4 fases, ≈ 50 min)
- **Personajes y motivos:** **Teniente Ivo Caran**, piloto de Ovilla derribado hace un año que vive
  escondido en el Bosque Petrificado; quiere volver a casa. **Agente Sorna**, de la inteligencia de
  Bastión, quiere la caja negra para destruirla.
- **Trasfondo:** la caja negra del Pecio de la Escuadrilla grabó el **primer disparo de la guerra**.
- **Gancho:** en el Pecio (que ya existe en el mapa) falta la caja; alguien ha dejado huellas recientes.
- **Fases:** (1) seguir las huellas por el Bosque Petrificado (rastreo con el VISOR, salamandras que
  molestan); (2) encontrar a Ivo, que te apunta con un arma: diálogo tenso para que baje el arma; (3)
  recuperar el lector de cajas negras en la Forja Muerta (exploración con calor y trampas de vapor);
  (4) escuchar la grabación mientras Sorna y su escuadra rodean el sitio (defensa por oleadas).
- **Giro:** la grabación dice que el primer disparo fue **un accidente minero** que los dos gobiernos
  taparon para tener una excusa.
- **Decisión:** dar la grabación a **Sorna** (rep Ejército +25, dinero, la verdad se pierde), a **Ivo**
  (vuelve a Ovilla con ella; en el epílogo del episodio, la grabación ayuda al alto el fuego) o **emitirla
  tú** desde el Observatorio (rep con todos −10 al principio, +30 Refugiados; se abre un final especial en
  el episodio).
- **Momento estrella:** escuchar la grabación de la cabina mientras cae ceniza dentro de la Forja y las
  linternas de Sorna aparecen por las ventanas.
- **Final:** Ivo se despide con su insignia (objeto de la Sala de recuerdos).
- **Lazo con el Ragnarock:** la guerra que rompe el planeta empezó con una mentira.

**B. «El padre de Brasa»** (5 fases, ≈ 45 min; se abre si ayudaste a Brasa)
- **Personajes:** **Brasa** (12), lista y deslenguada; su padre **Galo**, desertor buscado; **Sargento
  Murria**, cazador de desertores que perdió a su hijo en Ovilla.
- **Trasfondo:** Galo desertó para no dejar sola a Brasa tras morir su madre.
- **Gancho:** Brasa te paga con un dibujo para que busques a su padre.
- **Fases:** (1) preguntar por los barrios (diálogos con pistas, el jugador elige a quién creer); (2)
  colarte en los calabozos del Muelle para mirar el registro (sigilo); (3) seguir a Murria hasta las
  Trincheras (seguimiento sin ser visto); (4) Galo está atrapado en un campo de minas: desactivarlas (el
  trabajo de desactivador como juego); (5) Murria llega.
- **Giro:** Murria no quiere detener a Galo: quiere que le cuente cómo murió su hijo (Galo estaba allí).
- **Decisión:** dejar que hablen (escena larga; Murria deja ir a Galo y abandona la caza: los desertores
  ya no te persiguen tanto) o sacar a Galo por la fuerza (combate con la escuadra de Murria; Galo libre
  pero Murria sigue cazando).
- **Momento estrella:** Brasa corriendo hacia su padre entre la ceniza, con las sirenas de fondo.
- **Final:** Brasa se convierte en vendedora del Mercado (te hace descuentos el resto del juego).
- **Lazo:** la guerra separa familias; a veces el enemigo también ha perdido a alguien.

**C. «Fuego que camina»** (4 fases, ≈ 40 min)
- **Personajes:** **Abuela Tizna**, vieja pescadora térmica que conoce la Caldera; **Hollín Joven**, el
  sobrino de Madre Hollín, que quiere cazar al Gusano para vender su escama.
- **Trasfondo:** el Gusano Brasero salió de los Tubos de Lava cuando las bombas rompieron la corteza;
  antes dormía.
- **Gancho:** barcazas que no vuelven y una red de pesca quemada.
- **Fases:** (1) pesca térmica con Tizna para aprender la Caldera (juego de pesca); (2) bajar a los Tubos
  de Lava (exploración, calor, ciudad antigua tragada); (3) Hollín Joven provoca al Gusano y queda
  atrapado: rescate con tiempo límite; (4) jefe: **Gusano Brasero** (3 fases: en la lava, en los tubos,
  en la superficie con la Caldera hirviendo).
- **Giro:** el Gusano protege un nido: cada temblor fuerte lo despierta, no es malo.
- **Decisión:** matarlo (escama para un arma de reliquia) o **dormirlo** con azufre y sellar el tubo (más
  difícil; Tizna te regala la caña de reliquia y la Caldera se vuelve más segura para pescar).
- **Momento estrella:** el Gusano saliendo de la lava junto a tu barcaza al anochecer, con Ovilla detrás.
- **Lazo:** los monstruos de Tefra los despertó la guerra.

**D. «Papeles»** (3 fases, ≈ 30 min)
- **Personajes:** **Escribano Lumo**, falsificador anciano y vanidoso; **Capitana Ferra**, policía militar
  honrada.
- **Trasfondo:** sin papeles no se puede trabajar en el Muelle ni pasar controles.
- **Gancho:** te requisan el equipo en un control.
- **Fases:** (1) conseguir los materiales del falsificador (tinta de azufre, sello robado: recolección y
  un pequeño robo); (2) hacer de modelo para la foto mientras la policía registra la tienda (minijuego de
  quedarse quieto y responder bien); (3) pasar el control de la Capitana Ferra con preguntas trampa.
- **Giro:** Ferra sabe que son falsos y te deja pasar a cambio de un favor (abre la cadena E).
- **Decisión:** aceptar el favor o delatar a Lumo para ganar papeles legales (Lumo va al calabozo).
- **Momento estrella:** el interrogatorio en el control, con la cola de refugiados mirando.
- **Final:** papeles: no hay requisas y abre la armería del Muelle.
- **Lazo:** la ley militar decide quién existe.

**E. «La Capitana Ferra»** (4 fases, ≈ 40 min)
- **Personajes:** **Capitana Ferra**; **Teniente Grajo**, su segundo, que roba medicinas del hospital.
- **Trasfondo:** las medicinas del Campus desaparecen y los heridos mueren.
- **Gancho:** el favor de Ferra: averiguar quién roba.
- **Fases:** (1) vigilar el almacén del Campus de noche (sigilo y espera); (2) seguir el camión hasta el
  Mercado Espiral; (3) descubrir que Grajo vende a Madre Hollín; (4) tender una trampa con Ferra (tiroteo
  en el mercado).
- **Giro:** Grajo vende para pagar el rescate de su familia, atrapada en Ovilla.
- **Decisión:** entregar a Grajo (justicia; rep Ejército +), ayudarle a sacar a su familia (misión
  extra de vuelo a Ovilla; rep Ejército −, Refugiados +) o chantajear a Madre Hollín (dinero, rep
  Mercado −).
- **Momento estrella:** el tiroteo entre puestos de comida que caen en espiral hacia la lava.
- **Lazo:** en la guerra todos roban a alguien para salvar a otro.

**F. «La Forja Muerta»** (4 fases, ≈ 45 min)
- **Personajes:** **Maestra Ascua**, la jefa de la Forja que sobrevivió a la explosión; el **Ingeniero
  Orsi** (si vive).
- **Trasfondo:** la explosión de la Forja hizo que el Ejército trasladara su producción a los Pozos.
- **Gancho:** Ascua te pide que recuperes el libro de recetas de la Forja.
- **Fases:** (1) entrar en la Forja (calor, derrumbes, terremoto en medio); (2) reactivar los hornos
  (puzle de conductos de lava); (3) encontrar el **banco de reliquias**; (4) pruebas del sabotaje.
- **Giro:** quien saboteó la Forja fue un hombre de Corvo, y Ascua lo sabía.
- **Decisión:** reabrir la Forja para la ciudad (la ciudad gana una forja: precios de refinado −20 %) o
  para el mercado de Hollín (mejor pago para ti).
- **Momento estrella:** los hornos encendiéndose uno a uno en la oscuridad.
- **Final:** abres el banco de reliquias de Tefra (recetas de nivel 5).
- **Lazo:** Corvo quemó lo suyo para tener la Lanza.

**G. «Candados»** (3 fases, ≈ 30 min; tranquila, emotiva)
- **Personajes:** **Cosme**; **Ernesto**, el panadero del Ovillo, que conoció a Ada.
- **Trasfondo:** la hermana de Cosme, Ada, tenía un candado en el puente.
- **Gancho:** tras el episodio, Cosme no habla de Ada. Ernesto te busca.
- **Fases:** (1) hornear el pan de sirena con Ernesto (minijuego de cocina); (2) buscar el candado de Ada
  entre miles (exploración y pistas de lo que contaba Ernesto); (3) llevar a Cosme al puente.
- **Giro:** el candado tiene grabado el nombre de Cosme: Ada nunca dejó de esperarle.
- **Decisión:** ninguna: es la cadena sin decisiones (un momento de silencio).
- **Final:** Cosme cuelga su propio candado. Objeto en la Sala de recuerdos.
- **Lazo:** lo que queda de un mundo que se acaba son las personas que lo recuerdan.

#### 18. Eventos dinámicos de Tefra

| Evento | Cuándo | Qué pasa | Qué puedes hacer |
|---|---|---|---|
| **Bombardeo** | 2 veces por día de juego (antes del alto el fuego; luego, raro) | Sirenas, zonas marcadas reciben fuego | Refugio; después, trabajos de rescate, bombero y médico con paga extra |
| **Colada desbordada** | Al azar, en los Campos | Un río de lava cambia de cauce hacia un camino o un campamento | Bombero de coladas: barreras y enfriar |
| **Terremoto mayor** | Cada 1–2 h | Se rompe un puente o se abre una cueva nueva por un tiempo | Reparar el puente (ingeniero) o explorar la cueva (botín) |
| **Convoy de refugiados** | Por la mañana | Una caravana llega de las Trincheras con drones detrás | Escoltar (seguridad) |
| **Lluvia de restos** | De noche | Restos de la batalla orbital caen ardiendo | Recoger chatarra rara antes que los saqueadores |

#### 19. Línea premium: «Las cartas de Ovilla» (5 capítulos)

- **Idea:** un cartero de guerra, **Pardal**, lleva cartas entre las familias de Tefra y Ovilla
  saltándose el frente. Le han derribado y te pide que termines su ruta.
- **Capítulos:** (1, gratis) recoger las cartas del pecio de Pardal; (2) entregar cartas en Bastión
  (cada carta es una pequeña historia y una decisión: ¿entregas la carta que dice que el hijo murió?);
  (3) vuelo a Ovilla con la saca, bajo baterías; (4) una de las cartas es un mensaje cifrado de espías:
  ¿la entregas?; (5) Pardal no sobrevivió a su caída; su última carta es para ti.
- **Premios:** materiales de reliquia de Tefra, receta de un traje refrigerado de reliquia (también se
  consigue gratis con rep 80 en el Ejército), Chispas, la moto de ceniza «Mensajera» (aspecto) y el título
  «Cartero del Frente».

#### 20. Horas de juego en Tefra (≈ 12 h)

| Actividad | Horas |
|---|---|
| Misión principal (7 misiones) | 2,5 |
| Cadenas secundarias (7) | 4,5 |
| Trabajos comunes y propios (hasta rango Veterano local) | 1,5 |
| Exploración, recolección, minería, puntos de interés | 1,5 |
| Fabricación y astillero (equipo de calor, escudo de nave) | 1 |
| Ocio (fiesta, vagonetas, pelota de ceniza, pesca térmica) | 0,5 |
| Eventos dinámicos | 0,5 |
| Línea premium | (+1 h) |

---

### 3.2 · SIROCO · Puerto Calcina

> **Episodio 2 · «El último Gran Premio».** Desierto, tormentas y ruinas. Ciudad de adobe y chatarra con
> circuitos de carreras. Ragnarock: **el sol se está muriendo** (crece y lo quema todo) y no hay sitio para
> todos en las naves de evacuación. Protagonista: **Rafa Quiroga «el Zorro»**.

#### 1. La idea en una frase

Un desierto bajo un sol rojo que crece cada año, donde el agua vale más que el dinero y la gente apuesta su
última plaza en las naves de evacuación a una carrera armada.

#### 2. Identidad y tono

- **Fantasía:** piloto de carreras con deudas y orgullo; correr y disparar entre arcos de piedra;
  sobrevivir a la sed en ruinas antiguas.
- **Tono:** película de carreras con el fin del mundo de fondo. Motores, polvo, apuestas, fiestas «por si
  es la última» y un final que duele.
- **Colores:** rojo y ocre, blanco solar, azul de la noche (el único alivio).
- **Sonido:** viento silbando entre arcos, motores, el zoco, la arena contra el metal.
- **La gente:** alta y delgada, estilo papel recortado, con gafas de carreras y pintura en la cara.

#### 3. Geografía, biomas y puntos de interés

| Bioma | Cómo es | Qué se hace |
|---|---|---|
| **Cañones de Calcina** | Cañones rojos donde está la ciudad, mesetas y arcos gigantes. | Ciudad, circuito de la Gran Vuelta. |
| **El Mar de Dunas** | Dunas enormes que se mueven («el mar» de Siroco). | Veleros de arena, pesca de rayas de arena, naufragios. |
| **La Ciudad Primera** | Ruinas de una civilización antigua medio enterradas. | Exploración, trampas, chatarra antigua, secretos. |
| **Salinas Blancas** | Llanura de sal que deslumbra de día y cruje de noche. | Sal de rocío, carreras de velocidad pura. |
| **Bosque de Vidrio** | Rayos de las tormentas convirtieron la arena en árboles de vidrio. | Vidrio de tormenta; peligroso con tormenta (rayos). |
| **La Cisterna Antigua** | Acuífero subterráneo bajo las ruinas: el agua de verdad. | Secreto clave del planeta; exploración subterránea. |
| **Órbita: los Anillos de Polvo** | Anillos de polvo de vidrio que brillan con el sol. | Minería y carreras orbitales. |

**Puntos de interés:** el **Arco del Campeón** (con los nombres de los ganadores tallados; el de Rafa
tachado), el **Cementerio de Deslizadores** (miles de vehículos rotos), el **Pozo del Silencio** (un pozo
seco donde se oye agua muy abajo), la **Esfinge Ciega** (estatua gigante de la Ciudad Primera que mira al
sol), **las Arcas** (las naves de evacuación en el Mirador).

#### 4. Clima y día/noche

- **Día de 30 min:** el sol rojo enorme ocupa un cuarto del cielo; el calor tiembla en el aire.
- **«Hora roja»** (mediodía, 5 min): tormenta de fuego solar. **Fuera, el medidor de Calor se dispara**:
  todo el mundo baja a los túneles (siesta obligatoria; la ciudad cambia).
- **Noche de 15 min:** fresca, azul, con los anillos brillando; la ciudad sale a la calle y hay carreras.
- **Tormentas de arena:** cada 20–40 min, de 2–4 min: visibilidad casi nula, los motores se ahogan, la
  brújula falla.

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Cactus de agua** | Cactus hinchado | Da agua si lo cortas bien (minijuego); si lo cortas mal, se pierde. |
| **Flor de noche** | Flor que solo abre de noche | Medicina contra el golpe de calor. |
| **Raya de arena** | Raya que «nada» bajo la arena | Se pesca desde los veleros. |
| **Escarabajo aguador** | Escarabajo que guarda agua en el caparazón | Se cría (la «granja» de Siroco). |
| **Chacal de chatarra** | Perro salvaje que vive en el Cementerio | En manada; roba objetos de tu mochila. |
| **Serpiente de cristal** | Serpiente translúcida en el Bosque de Vidrio | Casi invisible; muerde (veneno leve). |
| **El Leviatán de Arena** (peligroso) | Gusano-ballena de 200 m que se mueve bajo las dunas | Se le ve saltar a lo lejos; si te acercas con vehículo ruidoso, ataca. **Jefe** de la cadena «La ballena del Mar de Dunas». |
| **Drones de carrera** (enemigos) | Drones armados de las escuderías ricas | En las carreras y en el Mirador. |

#### 6. Recursos

- **Únicos:** vidrio de tormenta, sal de rocío (recoge humedad de la noche: base para fabricar agua),
  chatarra antigua (de la Ciudad Primera: piezas de motor de otra época).
- **Abundantes:** chatarra, arena (vidrio común), metal.
- **Escasísimo:** **agua**. Todo gira alrededor del agua.

#### 7. La ciudad: Puerto Calcina

**Estilo:** ciudad de **adobe y chatarra** encajada en un cañón: casas de barro rojo excavadas en la roca,
remendadas con chapas, toldos de colores y antenas. Por el fondo del cañón pasa **La Recta**, y la ciudad
entera está cruzada por **circuitos de carreras** (calles con curvas peraltadas). Se llama «Puerto» porque
fue un puerto cuando había mar; ahora es puerto de los **veleros de arena**.

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Las Gradas** | Casas en la roca con balcones sobre el circuito. | Medio vacías: quien puede, se va. |
| **Los Boxes** | Garajes de los equipos. | Los ricos tienen de todo; los pobres, chatarra. |
| **Zoco del Viento** | Mercado de piezas, comida y agua. | Apuestas, deudas y cobradores. |
| **La Recta** | Estadio y recta principal. | Lleno cada noche: es lo único que queda. |
| **Pozo Hondo** | El barrio pobre del fondo del cañón. | Se queda sin agua. |
| **Mirador de los Arcos** | Barrio rico en las mesetas. | Aquí están **las Arcas**: las naves de evacuación. |
| **Muelle de Velas** | Puerto de los veleros de arena. | Pescadores de rayas y contrabandistas de agua. |
| **Los Túneles** | Ciudad bajo tierra para la hora roja. | Llenos a mediodía; de noche, refugio de deudores. |

- **Transporte:** deslizadores (coches que flotan), góndolas de cable entre mesetas, ascensores de roca,
  **veleros de arena**.
- **Tiendas:** aguador del Zoco (el agua más cara de la galaxia), piezas de carreras, ropa de sol, la
  cantina de La Recta (zumos de cactus y comida; nada de alcohol presentado como bueno).
- **Negocios:** taller de boxes, puesto de agua (con licencia o sin ella), velero de pesca.

#### 8. Forma de vida, leyes y bandos

- **Vida:** colas para la **lotería de las Arcas**, siesta bajo tierra en la hora roja, fiesta en La
  Recta cada noche, apuestas en todo.
- **Leyes:**
  - **El agua tiene dueño:** Doña Hierro controla los pozos legales. Vender agua sin licencia es delito
    (multas, `PoliceService` con la «Guardia de Hierro»).
  - **Las deudas se cobran:** si debes a un cobrador, te persigue (ver Mecánica).
  - **En la carrera vale todo** salvo disparar al público.
- **Costumbres:** «brindar» con agua (tirar un poco a la arena por los que se fueron); pintarse la cara
  antes de una carrera; los ganadores tallan su nombre en el Arco del Campeón.
- **Bandos (rep):**
  - **Escudería Hierro** (Doña Hierro): dueña de la carrera, de los pozos y de medio planeta.
  - **Pozo Hondo** (Luz, la exmujer de Rafa): los pobres del fondo.
  - **Los Clanes de la Duna** (la jefa **Sahra Vientoalto**): nómadas armados del Mar de Dunas; asaltan
    cargueros de agua de los ricos.
  - **Los Aguadores** (cártel del agua; jefe **Tavo**, el amigo de Rafa).

#### 9. Trabajos propios de Siroco

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Aguador/a** | Reparte agua a domicilio (o la vende sin licencia). | Llenar barriles → ruta por las Gradas → no derramar (cuestas y saltos). | La sed y la Guardia de Hierro (si vendes sin licencia). |
| **Zahorí** | Busca agua bajo tierra. | Varilla y sónar (minijuego de «frío/caliente») → perforar → instalar bomba. | Calor en zonas abiertas. |
| **Chatarrero/a** | Saca piezas del Cementerio de Deslizadores. | Buscar → desmontar (minijuego) → vender en los Boxes. Chacales roban. | Chacales y calor. |
| **Piloto de carreras** | Corre en las carreras de la ciudad. | Elegir carrera → correr (armada o limpia) → premios y apuestas. | Las carreras armadas son peligrosas. |
| **Guía de dunas** | Lleva viajeros en velero por el Mar de Dunas. | Ruta → leer el viento → evitar al Leviatán y a los Clanes. | Tormentas. |

#### 10. Mecánica única: **carreras armadas y deudas**

- **Carreras armadas:** deslizadores y naves con armas en carrera (se reutiliza `RaceService` y
  `KartService` para el cronómetro, las puertas y la clasificación; las armas, de `ShipWeapons`). Hay
  **carreras limpias** (sin armas, para quien quiera) y **armadas**. Las clasificatorias son **igualadas**
  (2.8.3).
- **El sistema de deudas de Siroco:** puedes pedir prestado al Zoco (para piezas o apuestas). Si no pagas
  a tiempo, **un cobrador te busca** (persecución en la ciudad) y te quita dinero o piezas. Es opcional,
  y enseña la idea de la deuda como desventaja (Vértice la lleva más lejos).
- **El agua como recurso de supervivencia:** fuera de la ciudad, la Sed baja siempre. Hay que llevar agua
  (cantimplora, barriles en el vehículo) o fabricarla (sal de rocío + condensador).

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Sed** (medidor) | Baja con el tiempo y más rápido al sol; sin agua, vas más lento y pierdes vida. | Cantimplora (nivel 1–5: más capacidad), condensador de sal de rocío, cactus de agua, pozos. |
| **Calor y hora roja** | Al sol directo sube el Calor; en la hora roja, fuera es casi mortal. | Ropa de sol, sombrilla de chatarra, túneles, refugios en ruinas. |
| **Tormentas de arena** | Visibilidad nula, brújula loca, motores ahogados. | Gafas de tormenta, filtro de motor (módulo de nave «Motor de vela»), balizas. |
| **Deudas** | Cobradores que te persiguen si pides prestado. | No pedir, pagar, o negociar (rep con los Aguadores). |
| **Gravedad un poco más fuerte** | Saltas menos y caes antes. | Botas de muelle (fabricadas). |

#### 12. Su «mar»: el Mar de Dunas

- Un océano de arena que se mueve: **veleros de arena** (`BoatService` con modelo de velero sobre
  ruedas-patín; el viento empuja según su dirección).
- **Pesca de rayas de arena** con arpón de cuerda (la base de `FishingService`, con otra tabla).
- **Naufragios:** barcos de cuando había mar, medio enterrados. «Bucear» aquí es **excavar** en la arena
  (minijuego de pala).
- **Lo que hay debajo:** la Cisterna Antigua, el «mar» de verdad que nadie conoce.

#### 13. Ocio

| En Valmar | En Siroco |
|---|---|
| Karting | **La Recta**: carreras de deslizadores cada noche (limpias y armadas), con apuestas y récords. |
| Feria del sábado | **La Noche Larga**: fiesta en La Recta con farolillos, música, juegos de puntería y el desfile de pilotos. |
| Deportes | **Polo de escarabajos** en las Salinas (montado en escarabajos aguadores, con mazos). |
| Skate | **Surf de duna** con tabla (se reutilizan los trucos de `SkateService`). |
| Playa | **Los Baños del Pozo** (solo si devuelves el agua a Pozo Hondo en la cadena «El agua de todos»). |

#### 14. Equivalencias con Valmar

| Valmar | Siroco |
|---|---|
| Coche | Deslizador |
| Bus / metro | Góndolas de cable y ascensores de roca |
| Barco | Velero de arena |
| Granja | Cría de escarabajos aguadores y huerto de cactus |
| Pesca | Pesca de rayas de arena |
| Hospital | La clínica de los Túneles |
| Policía | La Guardia de Hierro (privada) |
| Supermercado | Zoco del Viento |

#### 15. Biblia narrativa de Siroco

- **Historia del planeta:** hace mil años Siroco tenía mar. La **Ciudad Primera** sabía que el sol crecería
  y construyó la Cisterna Antigua para guardar agua mil años. Su pueblo se fue en naves y nunca volvió. Hoy
  el sol rojo crece de verdad: en pocos años el planeta será inhabitable.
- **Las Arcas:** tres naves de evacuación que pagó el planeta entero con impuestos de agua. Oficialmente,
  las plazas se dan por lotería; en realidad, Doña Hierro ya las ha vendido.
- **La Gran Vuelta:** la carrera más antigua del planeta. Este año, el gobierno promete plazas en las Arcas
  al barrio del equipo ganador.
- **Bandos y personajes:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Rafa Quiroga** (47) | Excampeón caído, mecánico con deudas | Plazas en las Arcas para su hija | Su copiloto murió porque él forzó la máquina |
| **Nina** (17) | Su hija, mecánica brillante | Salvar a Pozo Hondo, no a su padre | Ya ha construido medio deslizador en secreto |
| **Luz** | La exmujer, líder de Pozo Hondo | Agua para su barrio | Sigue queriendo a Rafa y no se lo perdona |
| **Doña Hierro** | Directora de la carrera y dueña de los pozos | Salir del planeta con su fortuna | Sabe dónde está la Cisterna Antigua y la ha tapado |
| **Tavo** | El mejor amigo de Rafa, jefe de los Aguadores | Una plaza en las Arcas | Vende a Rafa a cambio de la plaza |
| **Sahra Vientoalto** | Jefa de los Clanes de la Duna | Que los nómadas no sean olvidados | Su clan desciende de los guardianes de la Ciudad Primera |
| **La Profesora Ocre** | Arqueóloga loca de las ruinas | Leer la Ciudad Primera | Tiene el mapa de la Cisterna, pero no sabe leerlo entero |

- **Secretos:**
  1. **La Cisterna Antigua** tiene agua para que Pozo Hondo aguante muchos años (no salva el planeta, pero
     da tiempo).
  2. Las **Arcas** solo tienen motor para dos de las tres naves: la tercera es un decorado.
  3. La Esfinge Ciega es un **faro**: apunta hacia el planeta adonde se fue la Ciudad Primera.

#### 16. Misión principal: «El último Gran Premio» (episodio 2, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Tormenta de fuego** | (a) Llegas en plena hora roja: vuelo con el calor subiendo y tormenta solar; (b) aterrizaje entre arcos; (c) Rafa te arrastra a su taller (huida a pie bajo el sol, tutorial de la Sed). | — |
| 2 | **Deudas** | (a) Los cobradores de Doña Hierro rodean el taller; (b) tiroteo por el Zoco; (c) persecución en deslizador por las Gradas; (d) Rafa negocia con un cobrador colgado de una góndola. | **¿Pagas tú parte de la deuda de Rafa?** Sí: menos persecuciones después y Rafa te debe una (frase en el final). |
| 3 | **Chatarra** | (a) Robar piezas en el Cementerio con chacales; (b) carrera contra la Guardia con las piezas; (c) **fabricar el deslizador** con Nina (tutorial de fabricación y astillero). Nina ayuda sin decir por qué. | **Pieza clave:** robarla a la Escudería Hierro (más rápida, rep Hierro −30) o sacarla de la Ciudad Primera (misión extra de exploración; la pieza es antigua y abre el secreto de la Esfinge). |
| 4 | **La clasificación** | (a) Primera carrera armada (tutorial); (b) sabotaje: alguien ha aflojado un tornillo (reparar en carrera, minijuego); (c) clasificáis por los pelos. | — |
| 5 | **La Gran Vuelta** | (a) Salida en el cañón; (b) arcos y cielo con drones de los equipos ricos; (c) tormenta de arena en la última vuelta; (d) el duelo final contra **Doña Hierro en su deslizador blindado** (jefe). Ganáis. | **En la última curva, un rival se estrella:** pararse a sacarlo (pierdes ventaja; la carrera es más dura, pero el rival te ayuda en la misión 6) o seguir. |
| 6 | **Despegue** | (a) Descubrís que la carrera es mentira: las Arcas despegan esa noche, solo con los ricos; (b) **Tavo os vende**: emboscada en los Túneles; (c) asalto al puerto del Mirador (tiroteo y escalada). | **¿Qué haces con Tavo?** Dejarle subir a un Arca, entregarle a Pozo Hondo o dejarle en el desierto (cambia su escena en el final). |
| 7 | **La puerta** | (a) Abrir la compuerta del Arca con Nina (puzle bajo fuego); (b) **Rafa se queda** manteniéndola abierta mientras sube Pozo Hondo; (c) defender la compuerta (oleadas); (d) despegue: escolta del Arca en el aire contra la escudería. | — |

- **Giro:** la carrera fue siempre un espectáculo para tener tranquilos a los pobres. Tavo lo sabía.
- **Final (agridulce):** media Pozo Hondo sube a un Arca. Nina también. Rafa no. Nina te da su casco.
- **Si encontraste la Cisterna** (cadena «El agua de todos»), en el epílogo los que se quedan tienen agua:
  el final es un poco menos amargo.
- **Recompensa:** nave **Aguijón**, **turbo doble** (piezas del astillero), receta de cantimplora nivel 3.

#### 17. Cadenas secundarias de Siroco

**A. «El agua de todos»** (5 fases, ≈ 60 min)
- **Personajes:** **Profesora Ocre** (arqueóloga, entusiasta, despistada); **Sahra Vientoalto** (jefa
  nómada, desconfiada); **Doña Hierro** (en la sombra).
- **Trasfondo:** la Ciudad Primera construyó la Cisterna para el día en que el sol creciera.
- **Gancho:** Ocre te pide ayuda para leer una inscripción; dice «agua para mil años».
- **Fases:** (1) excavar la Esfinge Ciega (excavación, trampas de arena); (2) convencer a Sahra de que te
  deje entrar en tierra de los Clanes (diálogo y una prueba: cruzar las Salinas a pie en la noche);
  (3) bajar a la Cisterna (exploración subterránea, oscuridad, puzles de compuertas antiguas); (4)
  encontrar las tuberías tapadas con hormigón nuevo: **Doña Hierro lo sabía**; (5) volver con la prueba
  mientras la Guardia de Hierro os persigue por el Mar de Dunas (persecución en velero).
- **Giro:** Sahra no quería impedir el paso a la Cisterna: su clan la ha guardado mil años para cuando
  hiciera falta. Es ahora.
- **Decisión:** abrir la Cisterna para **todo el mundo** (Pozo Hondo y Clanes; el agua baja de precio en
  todo Siroco), **solo para Pozo Hondo** (rep Pozo Hondo +, Clanes −) o **vender el mapa** a Doña Hierro
  (mucho dinero; la peor consecuencia: el agua sube de precio y Pozo Hondo se vacía).
- **Momento estrella:** el agua bajando por los canales antiguos de la Ciudad Primera, que se iluminan
  después de mil años.
- **Final:** se abren los Baños del Pozo (ocio).
- **Lazo:** el planeta se muere, pero alguien ya lo sabía hace mil años y dejó una salida.

**B. «El copiloto»** (4 fases, ≈ 40 min)
- **Personajes:** **Rafa**; **Marisa Duna**, la madre de su copiloto muerto, **Cholo**.
- **Trasfondo:** hace diez años, Rafa forzó el motor en la Gran Vuelta. Cholo murió.
- **Gancho:** en el Arco del Campeón hay flores frescas bajo el nombre tachado de Rafa.
- **Fases:** (1) seguir a quien deja las flores (Marisa); (2) recuperar el deslizador del accidente en el
  Cementerio (chatarrero, chacales); (3) reparar la caja negra del deslizador (fabricación); (4) ver la
  grabación con Rafa.
- **Giro:** el motor estaba saboteado por la Escudería Hierro; Rafa forzó, pero no lo sabía.
- **Decisión:** contárselo a Rafa (se quita la culpa, pero se vuelve rabioso: misión 6 más agresiva) o
  callarlo y dárselo a Marisa (ella lo hace público tras el episodio).
- **Momento estrella:** Rafa sentado en el deslizador destrozado, en silencio.
- **Lazo:** los ricos llevan mucho tiempo jugando con la vida de los pobres.

**C. «La ballena del Mar de Dunas»** (4 fases, ≈ 45 min)
- **Personajes:** **Capitán Rumbo**, un viejo pescador obsesionado con el Leviatán; su nieta **Brisa**.
- **Trasfondo:** el Leviatán hundió el velero de Rumbo hace 20 años.
- **Gancho:** Rumbo busca tripulación.
- **Fases:** (1) aprender a navegar el velero (tutorial del mar); (2) pesca de rayas como cebo; (3)
  tormenta de arena en alta duna; (4) el Leviatán (jefe: saltos, embestidas, arpones).
- **Giro:** el Leviatán es viejo y está ciego; ataca a los barcos por el ruido de los motores. Rumbo
  quiere venganza; Brisa quiere que lo dejen.
- **Decisión:** ayudar a Rumbo a cazarlo (material de reliquia) o enseñarle a Rumbo los **veleros sin
  motor** (el Leviatán deja de atacar; los guías de duna van más seguros).
- **Momento estrella:** el Leviatán saltando por encima del velero contra el sol rojo.
- **Lazo:** todo lo vivo de Siroco lucha por lo mismo: sobrevivir al sol.

**D. «Doble o nada»** (4 fases, ≈ 35 min)
- **Personajes:** **Fito**, chaval de las Gradas que apuesta todo; **la Tía Cifra**, corredora de
  apuestas que sabe más de lo que dice.
- **Trasfondo:** Fito ha apostado la plaza de lotería de su familia en una carrera amañada.
- **Gancho:** Fito llorando en el Zoco.
- **Fases:** (1) investigar el amaño (escuchar conversaciones en el Zoco); (2) carrera nocturna en la que
  hay que perder **a propósito** sin que se note (juego al revés); (3) robar el libro de apuestas de la
  Tía Cifra (sigilo); (4) la Tía te descubre.
- **Giro:** la Tía Cifra amaña carreras para ganar plazas y dárselas a niños de Pozo Hondo.
- **Decisión:** delatarla (Fito recupera su plaza; los niños de la Tía la pierden) o callarte y ayudarla
  a amañar una más (Fito y su familia se quedan sin plaza: tú le das parte de tu dinero).
- **Lazo:** cuando no hay sitio para todos, hasta la gente buena hace trampas.

**E. «Los Clanes»** (5 fases, ≈ 50 min)
- **Personajes:** **Sahra Vientoalto**; su hijo **Idris**, que quiere atacar las Arcas.
- **Trasfondo:** los Clanes no entran en la lotería: para el gobierno no existen.
- **Gancho:** tu carguero de agua es asaltado por los Clanes.
- **Fases:** (1) perseguir a los asaltantes en deslizador; (2) caer prisionero (te quitan el equipo:
  escapar o hablar); (3) vivir un día con el clan (trabajos de guía de dunas, recoger sal de rocío); (4)
  Idris prepara un ataque a las Arcas; (5) detenerlo o ayudarle.
- **Giro:** Idris ha pactado con Tavo, que le traicionará.
- **Decisión:** avisar a Sahra (salvas a Idris; los Clanes se suman al asalto final del episodio),
  avisar a Doña Hierro (rep Hierro +; los Clanes te odian) o dejarlo correr (Idris cae en la trampa;
  escena dura fuera de cámara).
- **Momento estrella:** la caravana de los Clanes cruzando las Salinas de noche con los anillos encima.
- **Lazo:** el fin del mundo también decide quién cuenta como «gente».

**F. «Los cuatro motores»** (4 fases, ≈ 40 min; cadena de fabricación)
- **Personajes:** **Nina**; **Abuelo Tornillo**, el mecánico más viejo de los Boxes.
- **Trasfondo:** Tornillo construyó el motor con el que Rafa ganó su primera Gran Vuelta.
- **Gancho:** Nina quiere un motor que aguante tormentas.
- **Fases:** (1) recoger vidrio de tormenta en el Bosque de Vidrio con tormenta (rayos); (2) chatarra
  antigua de la Ciudad Primera; (3) fabricar 3 prototipos en el banco (cada uno con un fallo: probarlos
  en las Salinas); (4) el cuarto funciona.
- **Giro:** Tornillo copió el diseño de la Ciudad Primera: el motor de vela es tecnología de los que se
  fueron.
- **Final:** pieza **Motor de vela** para el astillero (no se ahoga en tormentas).
- **Lazo:** la solución del pasado podría salvar el futuro.

**G. «Lotería»** (3 fases, ≈ 30 min; dilema moral)
- **Personajes:** la familia **Ardiles** (cinco hermanos); el funcionario **Señor Ninguno**.
- **Trasfondo:** en la lotería de las Arcas, cada familia tiene **una** plaza.
- **Gancho:** la familia Ardiles gana una plaza y te pide que les ayudes a conseguir más.
- **Fases:** (1) falsificar papeles de la lotería (fabricación + sigilo en la oficina); (2) el Señor
  Ninguno te descubre y te propone un trato; (3) elegir.
- **Decisión:** las plazas extra salen de otra familia (dices cuál) o no (los hermanos eligen quién va:
  escena breve y dura).
- **Lazo:** el Ragnarock de Siroco convierte a la gente en números.

#### 18. Eventos dinámicos de Siroco

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Tormenta de arena** | Visibilidad nula, motores ahogados | Rescatar perdidos, recoger vidrio de tormenta |
| **Hora roja** | Fuera es casi mortal | Bajar a los Túneles (ahí hay un mercado especial de la hora roja) |
| **Asalto a un carguero de agua** | Los Clanes atacan | Defender (seguridad) o ayudarles (rep Clanes) |
| **Carrera relámpago** | Una carrera sale de golpe por la ciudad | Apuntarse en 60 s |
| **Lluvia** (rarísima, una vez cada muchas horas) | Llueve 2 minutos: toda la ciudad sale a la calle | Recoger agua; logro especial |

#### 19. Línea premium: «La Escudería Fantasma» (5 capítulos)

- **Idea:** un equipo de carreras desaparecido hace 30 años vuelve a aparecer en las carreras nocturnas
  con deslizadores sin piloto. Su dueña era **Madame Volta**, que desapareció con ellos.
- **Capítulos:** (1, gratis) ver la carrera fantasma y perseguirla; (2) investigar los boxes abandonados
  de Volta; (3) carrera contra un fantasma (igualada); (4) descubrir que Volta vive en la Ciudad Primera
  y pilota a distancia; (5) la última carrera de Volta, que quiere su nombre de vuelta en el Arco.
- **Premios:** piezas de motor de nivel 4 (también en la tienda de rep de Pozo Hondo), Chispas, el
  deslizador «Fantasma» (aspecto), el título «Piloto Fantasma».

#### 20. Horas de juego en Siroco (≈ 11 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 4,5 |
| Carreras (limpias, armadas, récords) | 1,5 |
| Trabajos | 1 |
| Exploración (Ciudad Primera, Mar de Dunas) y recolección | 1 |
| Fabricación y astillero (motor de vela, cantimploras) | 0,5 |
| Ocio y eventos | 0,5 |
| Línea premium | (+1 h) |

---

### 3.3 · TÁLASA · Abisalia

> **Episodio 3 · «Marea negra».** Océano con islas flotantes. Ciudad futurista y muy tecnológica, en parte
> submarina. Ragnarock: **una plaga de coral negro** que se come el metal. Protagonista: **Dra. Noa
> Ferrán**.

#### 1. La idea en una frase

El planeta más avanzado de la galaxia, con una ciudad de cristal bajo el mar y islas que flotan en el
cielo, se está pudriendo desde el fondo por un coral que inventó su mejor científica.

#### 2. Identidad y tono

- **Fantasía:** buzo de élite con tecnología punta; bajar donde nadie baja; terror en la oscuridad.
- **Tono:** terror bajo el agua y culpa. Silencio, crujidos, luces que se apagan.
- **Colores:** turquesa, blanco de laboratorio, el azul profundo y el **negro del coral** que late.
- **Sonido:** burbujas, el sónar, cantos de criaturas enormes, metal que cruje bajo presión.
- **La gente:** colores de acuarela y pecas que brillan según cómo se sienten. Con miedo, se apagan.

#### 3. Geografía, biomas y puntos de interés

Tálasa se juega **en capas de altura**: el cielo (islas flotantes), la superficie (olas y balsas) y el
fondo (por profundidades). Se reutilizan las ideas del mar de Valmar (`docs/mar/encargo.md`: zonas por
profundidad, oxígeno, criaturas grandes) con el doble de profundidad.

| Capa / bioma | Profundidad o altura | Qué se hace |
|---|---|---|
| **Archipiélago Suspendido** | +200 a +600 m | Islas que flotan por un mineral antigravedad; cascadas que caen al mar; saltos y planeo. |
| **La Superficie** | 0 m | Olas, balsas, mareas gigantes que suben y bajan varios pisos. |
| **Praderas de Luz** | 0 a −40 m | Arrecifes de colores, algas, granjas; seguro. |
| **El Bosque de Columnas** | −40 a −120 m | Columnas de coral gigantes; el coral negro empieza aquí. |
| **La Cúpula Honda** | −150 m | Barrio bajo el agua en cuarentena. |
| **Las Fosas** | −200 a −500 m | Oscuridad total, bioluminiscencia, criaturas abisales, presión extrema. |
| **El Corazón** | −600 m | El «cerebro» del coral negro. Final del episodio. |
| **Órbita: las Tres Lunas** | Espacio | Estación científica abandonada, hielo de agua. |

**Puntos de interés:** la **Estación Meridiana** (laboratorio abandonado de Noa), el **Cementerio de
Submarinos**, la **Ballena Dormida** (esqueleto gigante donde vive un pueblo de pescadores), el **Faro de
Mareas**, la **Isla Reloj** (isla flotante con un mecanismo antiguo que controla las mareas), el **Jardín
de Medusas**.

#### 4. Clima y día/noche

- **Día de 35 min:** cielo verde azulado con tres lunas pequeñas.
- **Mareas gigantes:** cada 12 min la marea sube o baja **varios pisos**: barrios enteros quedan bajo el
  agua o al aire (la ciudad tiene compuertas que se abren y cierran). Cambia los caminos.
- **Tormentas eléctricas** sobre el mar (rayos que caen en el agua: peligro en superficie).
- **Abajo no hay día:** por debajo de −120 m, la luz es la que tú llevas.

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Alga de luz** | Alga que brilla | Comida y luz (se cultiva: la «granja» de Tálasa). |
| **Pez farol** | Pez con su propia linterna | Se pesca; sirve para fabricar linternas. |
| **Tortuga isla** | Tortuga del tamaño de una casa | Pacífica; se puede subir encima. |
| **Medusa de cristal** | Medusa transparente | Pica (veneno leve); su gel es medicina. |
| **Criaturas de coral negro** (enemigas) | Peces, cangrejos y «tiburones» hechos de coral negro | Atacan, se pegan al metal y lo corroen. |
| **El Tejedor** (peligroso) | Ser abisal de patas largas que teje redes de coral | Embosca en las Fosas. **Jefe** de la cadena «Las redes». |
| **Leviatán de las mareas** | Criatura gigante que mueve las mareas al nadar | Se ve de lejos; no es enemigo. Clave de un secreto. |
| **Patrulla del Consejo** (enemigos humanos) | Lanchas y buzos armados | Hacen cumplir la cuarentena. |

#### 6. Recursos

- **Únicos:** nácar abisal (fosas), perla de presión (solo a más de −200 m), coral vivo limpio (del que no
  se ha vuelto negro; muy raro).
- **Abundantes:** agua (la más barata de la galaxia), algas, electrónica.
- **Escasos:** metal (el coral se lo come) y comida desde que murieron los Jardines de Algas.

#### 7. La ciudad: Abisalia

**Estilo:** **futurista y muy tecnológica**. Torres de cristal blanco que suben del mar y bajan bajo él,
unidas por tubos transparentes; hologramas, luz suave, robots de limpieza y domos submarinos. Arriba, en
el cielo, algunas mansiones en islas flotantes. Es la ciudad más bonita de la galaxia… y el coral negro
trepa por sus columnas.

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Las Balsas** | Plataformas flotantes de vivienda barata. | Llenas de gente que huye de abajo. |
| **Mercado del Arrecife** | Mercado de cristal sobre el coral, a −10 m. | Cerrado: el coral negro ha llegado. |
| **Cúpula Honda** | Domo de investigación a −150 m. | **En cuarentena.** Nadie entra ni sale. |
| **Faro de Mareas** | La torre central (Consejo). | Cuartel del Consejo. |
| **Astilleros** | Submarinos y barcos. | Todos quieren un barco para irse. |
| **Jardines de Algas** | Granjas submarinas. | Muertas. Hay hambre. |
| **Corona** | Barrio rico en las islas flotantes. | Cerrado a los de abajo con escudos. |
| **El Tubo** | El metro de cristal entre barrios. | Funciona; algunos tramos, cerrados por el coral. |

- **Transporte:** el Tubo (metro submarino, `MetroService` con otro modelo), taxis acuáticos, submarinos,
  ascensores de presión, toboganes entre pisos, planeadores en el Archipiélago.
- **Tiendas:** equipo de buceo de alta gama, laboratorios, algas, la tienda de la Corona (solo con rep).
- **Negocios:** granja de algas, taller de submarinos.

#### 8. Forma de vida, leyes y bandos

- **Vida:** controles de cuarentena (escáner al pasar entre barrios), carteles de desaparecidos, peleas
  por un barco, pecas apagadas.
- **Leyes:**
  - **Cuarentena:** prohibido bajar de −120 m sin permiso; los escáneres buscan coral negro en tu equipo
    (si lo llevas pegado, te «limpian» y pierdes la pieza).
  - **El Consejo decide** por votación: puedes votar en las asambleas (decisiones de mundo).
- **Costumbres:** la gente cuenta sus emociones con las pecas (los NPC te enseñan las suyas en el
  diálogo); se tira una perla al mar por cada desaparecido.
- **Bandos (rep):**
  - **El Consejo de Mareas** (Almirante **Coria**): orden y cuarentena.
  - **Las Balsas** (líder **Bruma**, buceadora que quiere vengarse de Noa).
  - **Los Científicos de Meridiana** (los antiguos compañeros de Noa).
  - **La Corona** (los ricos de las islas, portavoz **Lord Escama**).

#### 9. Trabajos propios de Tálasa

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Buceador/a de rescate** | Saca gente y objetos de zonas inundadas. | Bajar → buscar (sónar) → cortar o abrir → subir con el rescatado (oxígeno compartido). | Oxígeno y presión. |
| **Mecánico/a de submarinos** | Repara submarinos y domos. | Diagnosticar fugas (sonido) → soldar bajo el agua. | Presión y coral. |
| **Granjero/a de algas** | Cultiva y replanta los Jardines. | Sembrar → limpiar coral negro → cosechar. | Coral negro que vuelve. |
| **Técnico/a de presión** | Mantiene compuertas y ascensores con las mareas. | Ajustar presión a tiempo cuando cambia la marea (minijuego de válvulas). | Mareas. |
| **Cartógrafo/a abisal** | Mapea las Fosas. | Bajar con sonda → marcar → volver. | Oscuridad y criaturas. |

#### 10. Mecánica única: **buceo con presión y oxígeno**

- **Buceo libre** en todas las direcciones (se amplía `DivingService` y `Swim`).
- **Dos medidores:** **Oxígeno** (cuánto aguantas) y **Presión** (cuánto puedes bajar). El traje decide la
  profundidad máxima: nivel 1 = −40 m, 2 = −120 m, 3 = −200 m, 4 = −400 m, 5 = −600 m.
- **Bajar más de lo que aguanta el traje:** el cristal del casco se agrieta (aviso), y si sigues, pierdes
  vida. **Subir demasiado rápido** desde muy hondo da «mal de presión» (pantalla borrosa, más lento; se cura
  con paradas o en la cámara de la enfermería).
- **Luz:** abajo solo ves lo que alumbras. Las criaturas reaccionan a la luz (unas huyen, otras vienen).
- **Submarinos y modo submarino de la nave** (recompensa del episodio): la nave entra en el agua.
- **Terror:** sonido direccional, criaturas que se ven de reojo, luces que fallan. **Sin sustos baratos
  continuos** y sin nada sangriento.

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Oxígeno** | Bajo el agua se gasta. | Botellas (nivel 1–5), cargas de oxígeno, burbujas de aire en cuevas, algas de oxígeno. |
| **Presión** | Más hondo que tu traje = daño. | Traje de presión (nácar abisal), paradas de descompresión. |
| **Coral negro** | Se pega al metal y lo corroe (tu equipo y tu nave pierden durabilidad). | Recubrimiento de nácar, raspador, «limpieza» en el Consejo. |
| **Oscuridad** | Abajo no ves nada. | Linternas, bengalas, sónar, peces farol. |
| **Mareas** | Los caminos cambian cada 12 min. | Tabla de mareas (en el teléfono), técnicos de presión. |
| **Cuarentena** | No se puede bajar sin permiso. | Permiso (cadena), sigilo. |

#### 12. Su «mar»

Tálasa **es** el mar. Tiene todo lo del mar de Valmar a lo grande: buceo profundo, pesca (en barca, desde
las islas y submarina con arpón), barcos, submarinos, pecios, criaturas enormes, y las islas flotantes
como su «tierra».

#### 13. Ocio

| En Valmar | En Tálasa |
|---|---|
| Karting | **Carreras de motos de ola** por los canales entre torres, con las mareas cambiando el circuito. |
| Feria | **La Noche de las Pecas**: la ciudad apaga las luces y la gente brilla; farolillos en el agua, concurso de clavados desde las islas. |
| Playa | Las playas de las islas flotantes (cuando la Corona deja pasar). |
| Deportes | **Pelota de burbuja**: deporte submarino 3 contra 3. |
| Acuario / cine | El **Acuario de Meridiana** y su cúpula de cine bajo el mar. |

#### 14. Equivalencias con Valmar

| Valmar | Tálasa |
|---|---|
| Coche | Moto de ola y submarino pequeño |
| Bus / metro | El Tubo (metro de cristal submarino) |
| Barco | Lancha de cristal, submarino |
| Granja | Granja de algas |
| Pesca | Pesca en barca, desde las islas y con arpón |
| Hospital | Enfermería con cámara de presión |
| Policía | Patrulla del Consejo |
| Supermercado | Mercado del Arrecife (cuando se reabre) |

#### 15. Biblia narrativa de Tálasa

- **Historia:** Tálasa siempre fue rica: su agua y su tecnología se vendían a toda la galaxia. Sus islas
  flotan por un mineral antiguo que los primeros colonos encontraron. Hace 15 años el arrecife empezó a
  morir por el calor del mar. La Dra. Noa Ferrán inventó el **coral vivo** (coral con máquinas pequeñas)
  para salvarlo. Funcionó, hasta que el Consejo le quitó el dinero.
- **El coral negro:** Noa soltó el coral sin permiso para demostrar que funcionaba. Se descontroló: se
  volvió negro y empezó a comerse el metal.
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Dra. Noa Ferrán** (52) | Bióloga, creadora del coral vivo | Arreglarlo antes de que nadie lo sepa | Lo soltó a propósito |
| **Elio** (20) | Su hijo, atrapado en la Cúpula Honda | Salir y salvar a sus compañeros | Ya sospechaba de su madre |
| **Almirante Coria** | Jefa del Consejo | Salvar a diez mil aunque pierda a mil | Votó quitarle el dinero a Noa |
| **Bruma** | Buceadora que lo perdió todo | Vengarse de Noa | Fue compañera de Noa en la universidad |
| **Lord Escama** | Portavoz de la Corona | Que los de abajo no suban | Ha comprado todos los barcos para huir |
| **Doctor Pez** | Científico de Meridiana, antiguo ayudante de Noa | Una cura | Ha estado vendiendo coral negro a otro planeta como arma |
| **Abuela Marisma** | Matriarca del pueblo de la Ballena Dormida | Que el mar vuelva a ser mar | Su pueblo sabe que el Leviatán de las mareas puede comerse el coral |

- **Secretos:**
  1. El coral negro tiene un **corazón** (un nodo central): si se apaga, todo el coral muere.
  2. El **Leviatán de las mareas** come coral negro, pero el Consejo lo espantó con sónar.
  3. La **Isla Reloj** controla las mareas; si se para, el mar se queda quieto (y el coral crece más
     despacio, pero la ciudad sufre).
  4. El Doctor Pez ha vendido coral negro **fuera de Tálasa** (gancho para el futuro, sin conexión con
     los otros episodios: lo detienes aquí).

#### 16. Misión principal: «Marea negra» (episodio 3, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Bloqueo** | (a) Romper el bloqueo naval del Consejo a ras de las olas (combate de nave); (b) caer al mar; (c) primer buceo (tutorial de oxígeno y presión). | — |
| 2 | **La ciudad cerrada** | (a) Disturbios en Las Balsas (escoltar a una familia, pelea); (b) conocer a Noa, que se hace pasar por voluntaria; (c) el control de cuarentena (pasar el escáner con el traje Camaleón). | **¿Ayudas a Bruma** a robar un barco o a la patrulla a detenerla? Bruma, ayudada, te debe un favor (y en la misión 5 duda antes de traicionar a Noa). |
| 3 | **Muestras** | (a) Buceo en la zona infectada del Bosque de Columnas; (b) las criaturas de coral negro **atacan** (combate submarino); (c) recoger 3 muestras con el coral latiendo; (d) subida de emergencia (mal de presión). | — |
| 4 | **La Cúpula** | (a) Entrar en la cuarentena por un conducto (sigilo bajo el agua); (b) la Cúpula cruje: puzle de presión para abrir sectores; (c) encontrar a Elio; (d) evacuar a los supervivientes (oxígeno compartido, tiempo límite). | **Solo cabe un grupo en el ascensor:** el de Elio o el de unos niños. Si eliges a los niños, Elio sale por otro camino más tarde (escena de tensión); si eliges a Elio, los niños no salen (fuera de cámara; pecas apagadas en la ciudad). |
| 5 | **Confesión** | (a) El Consejo descubre quién es Noa (escena pública); (b) huida por los Astilleros con media ciudad detrás (persecución a pie y en lancha); (c) refugio en la Ballena Dormida. | **¿Defiendes a Noa en público?** Sí: rep Consejo −, pero Noa confiesa antes (la escena final es menos amarga para Elio). |
| 6 | **El corazón** | (a) Bajar a −600 m (el traje de reliquia o el modo submarino); (b) combate en la oscuridad contra el **corazón del coral** (jefe en 3 fases: tentáculos, criaturas, núcleo); (c) el corazón se defiende apagando tus luces. | **Llamar al Leviatán** (si hiciste la cadena «El canto del Leviatán»): ayuda en el combate y el coral muere más rápido. |
| 7 | **La última inmersión** | (a) Noa se queda abajo para apagar el corazón; (b) tú subes con Elio (ascenso largo, con todo derrumbándose); (c) en la superficie, las pecas de la ciudad se encienden. | — |

- **Giro:** Noa soltó el coral a propósito.
- **Final (agridulce):** el coral negro muere. Abisalia se salva; la Cúpula Honda y medio arrecife se
  pierden. Noa no sube. Elio se queda su cuaderno «para que nadie lo vuelva a hacer».
- **Recompensa:** **modo submarino** y **rayo tractor** (piezas del astillero), receta de traje de presión
  nivel 3.

#### 17. Cadenas secundarias de Tálasa

**A. «El canto del Leviatán»** (5 fases, ≈ 55 min)
- **Personajes:** **Abuela Marisma** (sabia, tozuda); **Capitán Sonar**, oficial del Consejo que manejó
  los cañones de sónar.
- **Trasfondo:** el Consejo espantó al Leviatán con sónar porque volcaba barcos.
- **Gancho:** los niños de la Ballena Dormida cantan una canción que «llama a la gran madre».
- **Fases:** (1) aprender la canción (minijuego de ritmo con sonidos submarinos); (2) apagar los cañones
  de sónar (sigilo en una base del Consejo); (3) convencer a Sonar de que no los vuelva a encender
  (diálogo; o sabotaje si falla); (4) buscar al Leviatán en las Fosas; (5) cantar mientras las
  criaturas de coral atacan (defensa).
- **Giro:** el Leviatán está enfermo de tanto comer coral negro.
- **Decisión:** curarlo con coral vivo limpio (gastas tu material más raro; te ayuda en el episodio) o
  dejarle seguir comiendo (ayuda igual, pero muere tras el episodio: escena triste en la superficie).
- **Momento estrella:** el Leviatán pasando bajo tu barca, más grande que la ciudad.
- **Lazo:** el planeta tenía su cura; los humanos la espantaron.

**B. «La Corona»** (4 fases, ≈ 45 min)
- **Personajes:** **Lord Escama** (amable, frío); su hija **Perla**, que esconde a gente de abajo en la
  mansión.
- **Trasfondo:** la Corona ha comprado todos los barcos para huir.
- **Gancho:** una lancha de la Corona dispara a una balsa.
- **Fases:** (1) colarse en el Archipiélago (planeo desde una isla); (2) fiesta en la mansión con el traje
  Camaleón (conversaciones, robar la lista de barcos); (3) Perla te descubre y te enseña a los escondidos;
  (4) sacarlos por las cascadas que caen al mar.
- **Giro:** Lord Escama sabe que su hija los esconde y lo permite en secreto: no puede decirlo en público.
- **Decisión:** hacer pública la lista de barcos (la Corona pierde los barcos; Escama cae) o usarla para
  negociar en secreto con Escama (barcos para Las Balsas sin escándalo).
- **Momento estrella:** saltar con los refugiados desde una isla flotante a una cascada.
- **Lazo:** en el fin del mundo, los ricos compran la salida.

**C. «Las redes»** (4 fases, ≈ 40 min; terror)
- **Personajes:** **Rodo**, cartógrafo abisal desaparecido; su pareja **Lía**, que no se rinde.
- **Trasfondo:** en las Fosas desaparecen buceadores.
- **Gancho:** una boya de Rodo emite una señal.
- **Fases:** (1) bajar a las Fosas siguiendo la señal (oscuridad, sonidos); (2) encontrar redes de coral
  con equipo atrapado; (3) **el Tejedor** te caza: esconderse, apagar la luz, moverse en silencio; (4)
  combate contra el Tejedor en su nido.
- **Giro:** Rodo está vivo, atrapado en una burbuja de aire; lleva semanas allí.
- **Decisión:** sacar a Rodo (subida lenta, el Tejedor te persigue) o recoger sus mapas primero (más
  dinero; Rodo te dice dónde están, pero el rescate es más arriesgado).
- **Momento estrella:** la linterna que parpadea y, en el siguiente destello, las patas del Tejedor.
- **Lazo:** el coral negro ha cambiado hasta a los animales del fondo.

**D. «El ayudante»** (5 fases, ≈ 50 min)
- **Personajes:** **Doctor Pez** (encantador, mentiroso); **Inspectora Yara**, de la policía del Consejo.
- **Trasfondo:** el Doctor Pez vende coral negro fuera del planeta.
- **Gancho:** encuentras un contenedor de coral negro en el puerto con destino «fuera del sistema».
- **Fases:** (1) seguir el contenedor (investigación en el puerto); (2) infiltración en Meridiana (sigilo
  en el laboratorio); (3) encontrar las pruebas (hackeo); (4) persecución de submarinos; (5) detener la
  nave del comprador en órbita (combate espacial).
- **Giro:** la Inspectora Yara es la socia del Doctor Pez.
- **Decisión:** entregar a los dos al Consejo, dejar que Yara se escape a cambio de los nombres de los
  compradores, o destruir todo el coral y no decir nada (nadie sabe nunca lo que pasó).
- **Lazo:** de un desastre, siempre hay alguien que quiere sacar negocio.

**E. «Pecas apagadas»** (3 fases, ≈ 30 min; emotiva)
- **Personajes:** **Tomi** (8), niño que ha perdido el brillo de sus pecas; su abuelo **Mero**.
- **Trasfondo:** cuando alguien pierde la esperanza, sus pecas se apagan.
- **Gancho:** Tomi no sale de casa.
- **Fases:** (1) descubrir qué le pasa (su madre está en la Cúpula); (2) llevarle un mensaje de su madre
  desde la Cúpula (buceo); (3) la Noche de las Pecas.
- **Giro:** la madre no puede salir; el mensaje es de despedida.
- **Decisión:** dárselo tal cual o pedir a Mero que se lo lea él (cambia la escena).
- **Lazo:** el miedo apaga a la gente antes que la plaga.

**F. «La Isla Reloj»** (4 fases, ≈ 45 min; puzles)
- **Personajes:** **Relojera Anís**, la última que sabe cuidar el mecanismo.
- **Trasfondo:** la Isla Reloj controla las mareas; está fallando.
- **Fases:** (1) llegar a la isla (planeo y escalada); (2) reparar 3 engranajes (puzles, piezas que hay que
  fabricar); (3) el coral sube por la isla (defensa); (4) elegir el ritmo de las mareas.
- **Decisión:** mareas **lentas** (el coral crece más despacio, pero la ciudad pierde energía de las
  olas: apagones en algunos barrios) o **normales** (todo sigue igual).
- **Final:** abre el **banco de reliquias** de Tálasa.
- **Lazo:** cada solución tiene un precio.

**G. «Jardines»** (4 fases, ≈ 40 min; granja y recolección)
- **Personajes:** **Oleaje**, granjera que perdió sus jardines.
- **Fases:** (1) limpiar coral negro de un jardín; (2) encontrar semillas de alga limpia en las Praderas;
  (3) replantar y proteger de criaturas (defensa ligera); (4) primera cosecha.
- **Giro:** las algas limpias frenan el coral: los jardines son una barrera natural.
- **Final:** se abre el negocio de granja de algas y bajan los precios de la comida.
- **Lazo:** cuidar es la otra forma de luchar.

#### 18. Eventos dinámicos de Tálasa

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Marea viva** | La marea sube más que nunca | Rescates, compuertas |
| **Brote de coral** | El coral negro aparece en un barrio | Limpiarlo (trabajo), defender |
| **Tormenta eléctrica** | Rayos en la superficie | Bajar o ponerse a cubierto |
| **Banco de peces farol** | Miles de peces suben a la superficie de noche | Pesca abundante |
| **El Leviatán pasa** | Una ola enorme cruza la ciudad | Surf de ola (logro), salvar barcas |

#### 19. Línea premium: «La expedición Meridiana» (5 capítulos)

- **Idea:** hace 20 años, una expedición bajó a la Fosa más honda y no volvió. Su capitana, **Ondina
  Vela**, era la maestra de Noa. Tú sigues sus diarios.
- **Capítulos:** (1, gratis) encontrar el primer diario en el Cementerio de Submarinos; (2) bajar a la
  base de la expedición; (3) el diario cuenta un motín; (4) la Fosa más honda (nuevo bioma pequeño, a
  −700 m); (5) Ondina dejó una señal para el futuro: el primer coral vivo, limpio.
- **Premios:** materiales de reliquia de Tálasa, receta de un traje de presión de reliquia (gratis también
  con rep 80 con Meridiana), Chispas, el submarino «Ondina» (aspecto), título «Abisal».

#### 20. Horas de juego en Tálasa (≈ 11,5 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 5 |
| Buceo y exploración por profundidades | 1,5 |
| Trabajos | 1 |
| Pesca, granja y fabricación (trajes, botellas) | 1 |
| Ocio y eventos | 1 |
| Línea premium | (+1 h) |

---

### 3.4 · NIVALIS · Fortaleza Albor

> **Episodio 4 · «La noche del Regente».** Helado: glaciares y auroras. Ciudad antigua de piedra y hielo.
> Ragnarock: **un tirano** que controla la luz y el calor. Protagonista: **Princesa Ilse**.

#### 1. La idea en una frase

Un planeta de noche eterna donde un Regente decide qué barrios reciben la luz de las auroras y cuáles se
mueren de frío, y donde hasta un susurro puede delatarte.

#### 2. Identidad y tono

- **Fantasía:** espía y rebelde; moverse entre sombras y nieve, escuchar, robar secretos, colarse en un
  baile de palacio.
- **Tono:** thriller de resistencia bajo una dictadura. Susurros, miedo a los vecinos, traición.
- **Colores:** azul hielo, negro de la noche, verde y rosa de aurora, ámbar de los faroles.
- **Sonido:** viento, nieve que cruje (¡cuidado: se oye!), campanas del palacio, canciones prohibidas.
- **La gente:** peluda, de fieltro, con ojos grandes y abrigos de lana.

#### 3. Geografía, biomas y puntos de interés

| Bioma | Cómo es | Qué se hace |
|---|---|---|
| **Valle de Albor** | Valle entre glaciares donde está la ciudad. | Ciudad, Patinódromo. |
| **El Glaciar Azul** | Río de hielo gigante con grietas. | Escalada en hielo, cuevas, hielo eterno. |
| **Cuevas de Cristal** | Cuevas que cantan cuando pasa el viento. | Cristal de eco; minas (trabajos forzados). |
| **Mar Helado** | Mar congelado («el mar» de Nivalis). | Pesca en agujeros, rompehielos, buceo bajo hielo. |
| **Bosque de Escarcha** | Árboles blancos cargados de nieve. | Lanudos salvajes, caza de pistas, refugios rebeldes. |
| **Los Picos del Silencio** | Montañas donde está la antena que controla las auroras. | Final del episodio, ventiscas. |
| **Órbita: los Ojos del Regente** | Satélites espía en órbita. | Combate y sigilo espacial (camuflaje). |

**Puntos de interés:** la **Antena de las Auroras**, el **Lago de los Ahogados** (hielo fino, leyenda),
la **Cabaña del Ermitaño**, la **Estatua Rota de la Reina**, el **Monasterio de Hielo** (abandonado; con
banco de reliquias), las **Fuentes Calientes** (único sitio cálido de fuera).

#### 4. Clima y día/noche

- **Noche eterna:** no hay día. La luz la dan las **auroras** (verdes y rosas) y los faroles.
- **El Regente controla las auroras:** las enciende sobre los barrios «obedientes» y las apaga sobre los
  rebeldes. **Esto es una mecánica:** sin aurora, el Frío sube más rápido y está más oscuro (mejor para
  esconderse, peor para sobrevivir).
- **Ventiscas** cada 15–25 min: visibilidad nula, frío extremo; borran tus huellas (útil para huir).
- **El sonido viaja lejísimos:** de ahí los susurros y la mecánica de ruido.

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Musgo de nieve** | Musgo que da calor al quemarlo | Combustible; medicina. |
| **Baya de escarcha** | Bayas azules | Comida. |
| **Lanudo** | Animal grande y peludo, como un buey de lana | Se cría (la «granja» de Nivalis); tira de trineos; da lana. |
| **Zorro de aurora** | Zorro que brilla con los colores de la aurora | Raro; si lo sigues, te lleva a sitios secretos. |
| **Lechuza campana** | Lechuza que «suena» al ver a alguien | **Peligrosa para el sigilo:** si te ve, avisa a la guardia. |
| **Oso de glaciar** (peligroso) | Oso enorme de piel azul | Territorial; se le puede espantar con fuego. |
| **El Rey del Hielo** (peligroso) | Ser antiguo de hielo vivo que duerme bajo el Glaciar | **Jefe** de la cadena «Lo que duerme en el hielo». |
| **Guardia del Regente** (enemigos) | Soldados con faroles y perros de nieve | Patrullan; investigan ruidos. |

#### 6. Recursos

- **Únicos:** hielo eterno (no se derrite: blindaje y frío), cristal de eco (guarda sonidos: grabaciones,
  silenciadores), lana de lanudo (el mejor abrigo).
- **Abundantes:** agua (hielo), piedra, cristal común.
- **Escasos:** combustible y calor (el gas viene de fuera: caro).

#### 7. La ciudad: Fortaleza Albor

**Estilo:** **antigua, de piedra y hielo**. Murallas de piedra gris de mil años, torres con tejados-farol,
puentes de hielo tallado, calles estrechas y empinadas, chimeneas por todas partes. El Palacio de Escarcha
es un alcázar con torres de hielo transparente. La ciudad parece un castillo enorme que se come la nieve.

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Barrio de los Faroles** | Casas con tejados-farol. | Los faroles se apagan si el barrio «se porta mal». |
| **Mercado de Hielo** | Sopa, mantas, guantes. | Lleno de espías. |
| **Biblioteca de los Ecos** | Canciones guardadas en cristales. | Cerrada. Las canciones están prohibidas. |
| **Patinódromo** | Calles heladas para patinar. | Controles de la guardia en cada cruce. |
| **Minas de Cristal** | Cuevas de trabajo. | **Trabajos forzados** para los presos. |
| **Palacio de Escarcha** | La sede del Regente. | Fiestas dentro, silencio fuera. |
| **La Muralla Vieja** | Murallas con pasadizos. | Los rebeldes usan sus pasadizos. |
| **Barrio de las Termas** | Baños calientes. | Solo para quien tiene «carné de lealtad». |

- **Transporte:** patines (por las calles heladas), trineos tirados por lanudos, teleférico entre
  barrios, **rompehielos** en el Mar Helado.
- **Tiendas:** ropa de abrigo, sopa caliente, el mercado negro de canciones (cristales), la armería de la
  guardia (solo si te unes a ella).
- **Negocios:** puesto de sopa, cría de lanudos.

#### 8. Forma de vida, leyes y bandos

- **Vida:** toque de queda, la «hora del silencio» obligatoria (nadie habla en la calle), gente que
  desaparece de noche, auroras que se apagan sobre un barrio como castigo.
- **Leyes:**
  - **Hora del silencio:** hacer ruido en la calle (correr, disparar, hablar alto) sube tu **Sospecha**.
  - **Carné de lealtad:** sin él, no entras en las Termas ni en el Palacio.
  - **Canciones prohibidas:** llevar un cristal de eco con canciones es delito.
  - **Delación:** los vecinos pueden denunciarte (NPC que te ven hacer algo raro).
- **Costumbres:** hablar en susurros; dejar una vela en la ventana por los desaparecidos (está prohibido,
  y lo hacen igual); el saludo con dos dedos en el pecho (señal secreta de la resistencia).
- **Bandos (rep):** **la Corona del Regente** (Morvan), **la Resistencia de las Minas** (Ilse), **los
  Faroleros** (gremio neutral que sabe todo lo que pasa) y **el Monasterio** (monjes de hielo que se
  niegan a elegir bando).
- **Puedes trabajar para la guardia** (seguridad del Regente): da dinero y acceso, pero baja la rep con
  la resistencia; algunas misiones te piden ser **agente doble**.

#### 9. Trabajos propios de Nivalis

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Farolero/a** | Enciende y apaga faroles (y pasa mensajes). | Ruta → encender → entregar mensajes escondidos sin que te vean. | Frío y Sospecha. |
| **Patinador/a mensajero** | Lleva paquetes patinando. | Ruta por el Patinódromo con controles: velocidad y sigilo. | Hielo y controles. |
| **Cocinero/a de sopa** | Cocina en el Mercado de Hielo. | Recetas (minijuego) → servir → escuchar conversaciones (información para la resistencia). | Espías. |
| **Picador/a de hielo** | Corta bloques de hielo eterno. | Picar con ritmo → transportar en trineo. | Frío y grietas. |
| **Pastor/a de lanudos** | Cuida y saca a pastar lanudos. | Guiar el rebaño → protegerlo de osos → esquilar. | Ventiscas. |

#### 10. Mecánica única: **sigilo con ruido y luz**

- **Medidor de Sospecha** (nuevo; se reutiliza la idea de `WantedService`): sube si te ven en sitios
  prohibidos, haces ruido o rompes una ley. Con mucha sospecha, la guardia te busca.
- **Ruido:** correr sobre nieve crujiente, romper hielo o disparar se oye lejos (círculo de ruido en el
  mapa). Andar agachado, sobre piedra o durante una ventisca hace menos ruido.
- **Luz:** las auroras y los faroles te hacen visible; la oscuridad te esconde (pero el Frío sube).
  **Elegir entre esconderse o calentarse** es la tensión de Nivalis.
- **Huellas** en la nieve: la guardia las sigue. Las ventiscas las borran.
- **Traje Camaleón:** te deja pasar por ciudadano; si te dan un golpe fuerte, parpadea y te delata.
- Recompensa del episodio: **camuflaje** para la nave y para ti, y **silenciador**.

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Frío** (medidor) | Sube siempre fuera; más rápido sin aurora, de noche cerrada y con ventisca. | Abrigo de lana de lanudo (nivel 1–5), hogueras de musgo, sopa caliente, Fuentes Calientes, chimenea en casa. |
| **Sospecha** | Te busca la guardia; te pueden detener (calabozo). | Carné de lealtad (falso o real), traje Camaleón, silenciador, sigilo. |
| **Hielo fino** | En el Mar Helado y en lagos, el hielo se rompe. | Sonda de hielo, crampones, no correr. |
| **Oscuridad y ventiscas** | No ves; te pierdes. | Farol (pero te ven), cuerda guía, brújula de cristal. |
| **Escasez de calor** | El combustible es caro. | Comercio (gas de Miasma), musgo de nieve. |

#### 12. Su «mar»: el Mar Helado

- **Pesca en agujero:** hacer un agujero en el hielo y pescar (base de `FishingService`).
- **Rompehielos:** barco que abre camino (`BoatService`); rutas que cambian cuando el hielo se cierra.
- **Buceo bajo el hielo:** muy frío (el Frío sube el doble), con poco tiempo; hay barcos atrapados desde
  hace siglos.
- **Patinaje sobre el mar:** cuando el hielo es grueso, se cruza patinando (rápido y peligroso).

#### 13. Ocio

| En Valmar | En Nivalis |
|---|---|
| Karting | **Carreras de trineos** de lanudos por el Bosque de Escarcha. |
| Skate | **Patinaje** en el Patinódromo: trucos y carreras (trucos de `SkateService`). |
| Deportes | **Piedra de hielo**: deslizar piedras pesadas hacia una diana (2 contra 2). |
| Feria | **El Festival de la Aurora** (prohibido: se hace a escondidas en las Cuevas de Cristal; si lo descubre la guardia, hay que huir). Tras el episodio, se hace en la plaza. |
| Playa | **Las Fuentes Calientes** y las Termas. |

#### 14. Equivalencias con Valmar

| Valmar | Nivalis |
|---|---|
| Coche | Trineo de lanudos, moto de nieve |
| Bus / metro | Teleférico |
| Barco | Rompehielos |
| Granja | Cría de lanudos e invernadero de musgo |
| Pesca | Pesca en agujero |
| Hospital | La enfermería del Monasterio |
| Policía / cárcel | Guardia del Regente / Minas de Cristal |
| Supermercado | Mercado de Hielo |

#### 15. Biblia narrativa de Nivalis

- **Historia:** Nivalis siempre fue frío; su gente sobrevivió gracias a una antena antigua que **atrae las
  auroras** sobre el valle y las convierte en luz y calor. La familia real cuidaba la antena para todos.
  Hace seis años murió la reina en prisión y su hermano **Morvan** se hizo Regente. Descubrió que quien
  controla la antena controla quién vive.
- **La princesa muerta:** oficialmente, la heredera Ilse murió en un «accidente» en el Glaciar. En
  realidad, escapó y vive en las Minas.
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Princesa Ilse** (23) | Heredera, jefa de la resistencia | Liberar Albor sin convertirse en su tío | Está dispuesta a sacrificar a otros |
| **Regente Morvan** | Tío de Ilse | Orden y obediencia | Dejó morir a la reina y lo grabó un cristal de eco |
| **Bram** | Lugarteniente y mejor amigo de Ilse | Salvar a su familia | El Regente tiene presa a su familia: va a traicionar a Ilse |
| **Madre Copo** | Vieja bibliotecaria | Que las canciones no se pierdan | Guarda la grabación de la muerte de la reina |
| **Capitán Escarcha** | Jefe de la guardia | Servir al trono, no al hombre | Duda de Morvan |
| **Hermano Nevada** | Monje del Monasterio | No elegir bando | Fue el maestro de Ilse |
| **Tila** | Farolera adolescente | Saber dónde está su hermano desaparecido | Es la mejor espía de la ciudad y nadie lo sabe |

- **Secretos:**
  1. La **grabación** de la reina está en un cristal de eco en la Biblioteca.
  2. Bajo el Glaciar duerme el **Rey del Hielo**, un ser antiguo al que la antena mantiene dormido.
  3. Las **Minas de Cristal** tienen un pasadizo al Palacio.
  4. El Monasterio guarda la **canción de la reina**, que puede encender las auroras sin la antena (un
     ratito).

#### 16. Misión principal: «La noche del Regente» (episodio 4, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Aterrizaje a oscuras** | (a) Vuelo bajo los radares del Palacio por un cañón de hielo (sigilo en nave); (b) aterrizaje en el Bosque de Escarcha; (c) tutorial del Frío y del ruido. | — |
| 2 | **El silencio** | (a) Entrar en la ciudad en plena hora del silencio (sigilo); (b) primer contacto con la resistencia (Tila, la farolera); (c) una delación: un vecino te denuncia y hay que esconderse. | **¿Castigas al vecino que te denunció** (tiene miedo y una familia) o lo dejas? Si lo dejas, más tarde te ayuda; si no, el barrio te tiene miedo (más sospecha). |
| 3 | **Las Minas** | (a) Colarte en las Minas de Cristal como preso (traje Camaleón); (b) trabajar de picador sin levantar sospechas; (c) liberar a un grupo de presos (sigilo + pelea); (d) conocer a Ilse. | **¿Liberas a todos o solo a los de la resistencia?** Todos: más difícil (más guardias), pero más rep en la ciudad. |
| 4 | **La grabación** | (a) Entrar en la Biblioteca cerrada por los tejados; (b) puzle de cristales de eco (escuchar canciones para encontrar el correcto); (c) Madre Copo te encuentra; (d) huida con la guardia en la nieve (borrar huellas con la ventisca). | — |
| 5 | **El baile** | (a) Infiltración en la fiesta del Palacio con el traje Camaleón (conversaciones, bailar sin fallar); (b) robar el código de la antena; (c) Morvan te habla en persona (escena tensa: no puedes fallar las respuestas). | **Tienes ocasión de envenenar la copa de Morvan** (Ilse te lo pidió). Si lo haces, Ilse pierde lo que la diferenciaba de su tío (la escena final cambia: ella misma se da cuenta y renuncia aún más dolida). Si no, Ilse se enfada contigo y luego lo entiende. *(13+: no se ve; la opción se corta antes y siempre falla — Morvan cambia de copa — pero la decisión cuenta.)* |
| 6 | **Traición** | (a) Bram os vende: emboscada en las Minas; (b) huida por el Patinódromo patinando bajo fuego; (c) huida en nave **dentro de la aurora**, con cazas nocturnos detrás. | **¿Qué haces con Bram** cuando le alcanzas? Dejarle ir, entregarle a Ilse o rescatar a su familia (misión extra en las mazmorras). |
| 7 | **El trono** | (a) Asalto al Palacio por el pasadizo de las Minas; (b) la grabación suena por toda la ciudad (defender la antena); (c) **Ilse frente a Morvan**. | **Ilse decide** (no tú), pero tus decisiones anteriores cambian lo que dice. |

- **Giro:** Bram traicionó porque el Regente tenía presa a su familia.
- **Final (agridulce):** el Regente cae; las auroras vuelven a todos los barrios; Ilse entrega el trono a un
  consejo de vecinos. Bram se va de Albor.
- **Recompensa:** **camuflaje** (pieza de nave y equipo a pie), **silenciador**, receta de abrigo nivel 3.

#### 17. Cadenas secundarias de Nivalis

**A. «El hermano de Tila»** (5 fases, ≈ 50 min)
- **Personajes:** **Tila**, farolera; su hermano **Nilo**, desaparecido; **Capitán Escarcha**.
- **Trasfondo:** la guardia se lleva a gente de noche y nadie sabe adónde.
- **Gancho:** Tila te deja un mensaje en un farol.
- **Fases:** (1) aprender el oficio de farolero con ella (los faroles son el código secreto); (2) seguir
  un carro de presos (sigilo); (3) entrar en los archivos de la guardia (puzle de cerraduras); (4) Nilo
  está en las Minas, pero ha sido «reeducado» y ahora es guardia; (5) hablar con él.
- **Giro:** Nilo se hizo guardia para proteger a Tila: si deserta, ella será la siguiente.
- **Decisión:** sacarle (huida difícil, Escarcha os persigue) o dejarle dentro como espía (te pasa
  información en el episodio; Tila no te lo perdona hasta el final).
- **Momento estrella:** Tila y Nilo hablándose en código con los faroles a través de la plaza.
- **Lazo:** el tirano no solo encierra cuerpos, también cambia a las personas.

**B. «Lo que duerme en el hielo»** (4 fases, ≈ 50 min)
- **Personajes:** **Hermano Nevada** (el monje); **Ingeniera Frima**, que trabaja en la antena.
- **Trasfondo:** la antena mantiene dormido al Rey del Hielo; Morvan la sobrecarga para castigar barrios.
- **Gancho:** grietas nuevas en el Glaciar y un temblor que no es un terremoto.
- **Fases:** (1) escalar el Glaciar Azul (escalada en hielo); (2) bajar a las cuevas del Rey (exploración,
  cristales que cantan); (3) el Rey despierta: huida; (4) combate en el Glaciar (jefe con fases de hielo
  que se rompe).
- **Giro:** el Rey del Hielo es lo que da frío al planeta; si muere, Nivalis se calienta… y se derrite el
  Glaciar sobre la ciudad.
- **Decisión:** volver a dormirle (con la canción del Monasterio) o vencerle (el valle se vuelve menos frío
  pero el Glaciar se agrieta: un barrio de la ciudad queda inundado tras el episodio).
- **Momento estrella:** el Rey levantándose del glaciar bajo la aurora.
- **Lazo:** el poder sobre la luz era también poder sobre algo mucho más antiguo.

**C. «Canciones prohibidas»** (4 fases, ≈ 40 min)
- **Personajes:** **Madre Copo**; **Lino**, joven contrabandista de canciones.
- **Trasfondo:** las canciones guardadas en cristales son la memoria del pueblo.
- **Gancho:** Lino te ofrece una canción a cambio de un favor.
- **Fases:** (1) recoger cristales de eco en las Cuevas; (2) grabar canciones de la gente mayor (diálogos
  que son pequeñas historias); (3) repartirlas por la ciudad (entregas con sigilo); (4) el Festival de la
  Aurora secreto, con la guardia llegando.
- **Giro:** Lino trabaja para la guardia: el festival es una trampa.
- **Decisión:** avisar a todos (el festival se suspende; Lino es descubierto) o usar la trampa al revés
  (cerrar las cuevas con la guardia dentro: más difícil, gran victoria de la resistencia).
- **Lazo:** sin canciones, un pueblo no recuerda quién era.

**D. «Agente doble»** (5 fases, ≈ 55 min)
- **Personajes:** **Capitán Escarcha**; **Ilse**.
- **Trasfondo:** Escarcha duda del Regente.
- **Gancho:** Escarcha te ofrece entrar en la guardia.
- **Fases:** (1) aceptar y hacer turnos de guardia (seguridad del Regente; eliges cómo tratar a la gente);
  (2) pasar información a la resistencia; (3) una prueba de lealtad: detener a alguien de la resistencia;
  (4) Escarcha te descubre; (5) decide.
- **Giro:** Escarcha quería que le descubrieras: busca una salida para él y para sus hombres.
- **Decisión:** convencerle de cambiar de bando (en el episodio, la guardia se divide y el asalto es más
  fácil) o denunciarle a la resistencia (Ilse lo encierra).
- **Lazo:** detrás de cada uniforme hay alguien que también tiene frío.

**E. «El ermitaño»** (3 fases, ≈ 30 min; tranquila)
- **Personajes:** **Viejo Abeto**, ermitaño que vive en el Bosque de Escarcha con sus lanudos.
- **Fases:** (1) perderte en una ventisca y que te rescate él; (2) un día con sus lanudos (pastoreo, oso de
  glaciar); (3) llevarle a la ciudad para ver a su hija.
- **Giro:** Abeto fue el arquitecto de la antena. Se fue cuando vio lo que Morvan hacía con ella.
- **Final:** te da el plano secreto de la antena (útil en el episodio) y la receta del trineo.
- **Lazo:** quien crea algo no siempre decide para qué se usa.

**F. «Hielo fino»** (4 fases, ≈ 40 min)
- **Personajes:** **Capitana Brea**, del rompehielos «Tozudo»; su tripulación.
- **Trasfondo:** un barco atrapado en el Mar Helado lleva comida para los barrios castigados.
- **Fases:** (1) navegar el rompehielos (el hielo se cierra); (2) buceo bajo el hielo para soltar el timón
  helado; (3) la guardia aborda el barco; (4) cruzar el último tramo patinando con la carga en trineos.
- **Decisión:** dar la comida a los barrios rebeldes o a los castigados por error (vecinos que no hicieron
  nada): eliges quién come.
- **Lazo:** el Regente usa el hambre como el frío.

**G. «El Monasterio»** (4 fases, ≈ 40 min)
- **Personajes:** **Hermano Nevada**; los monjes.
- **Fases:** (1) subir al Monasterio (escalada con ventisca); (2) ganarte la confianza de los monjes
  (ayudar en sus tareas: picar hielo, cuidar la enfermería); (3) aprender la canción de la reina; (4)
  defender el Monasterio de la guardia.
- **Final:** abre el **banco de reliquias** de Nivalis.
- **Lazo:** no elegir bando también es elegir.

#### 18. Eventos dinámicos de Nivalis

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Castigo de aurora** | Se apaga la aurora en un barrio | Llevar combustible y mantas (rescate), o aprovechar la oscuridad |
| **Redada** | La guardia registra un barrio | Esconder a vecinos o ayudar a la guardia |
| **Ventisca** | No se ve nada | Rescates; huellas borradas |
| **Hielo que se rompe** | Se abre el Mar Helado | Rescate en el agua helada |
| **Zorro de aurora** | Aparece un zorro de aurora | Seguirle hasta un secreto |

#### 19. Línea premium: «La reina que cantaba» (5 capítulos)

- **Idea:** la madre de Ilse, la **Reina Alva**, dejó en vida cinco cristales con su voz, escondidos para
  su hija. Cada uno cuenta una parte de lo que pasó con Morvan desde que eran niños.
- **Capítulos:** (1, gratis) el primer cristal en la Estatua Rota; (2) el segundo en el Lago de los
  Ahogados (buceo bajo hielo); (3) en el Palacio (sigilo puro); (4) en los Ojos del Regente, en órbita
  (camuflaje de nave); (5) el último: la reina perdona a su hermano. ¿Se lo das a Ilse o a Morvan
  encerrado?
- **Premios:** materiales de reliquia, receta de abrigo de reliquia (gratis también con rep 80 con la
  Resistencia), Chispas, trineo «Real» (aspecto), título «Voz de la Reina».

#### 20. Horas de juego en Nivalis (≈ 11 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 4,5 |
| Trabajos (incluido agente doble de guardia) | 1,5 |
| Exploración (Glaciar, Cuevas, Mar Helado) y recolección | 1 |
| Fabricación y astillero (abrigos, camuflaje) | 0,5 |
| Ocio (trineos, patinaje, festival) | 1 |
| Eventos | 0,5 |
| Línea premium | (+1 h) |

---

### 3.5 · UMBRÍA · Raíz Honda

> **Episodio 5 · «El Enjambre».** Selva con cascadas. Ciudad orgánica en los árboles gigantes. Ragnarock:
> **una plaga de máquinas** que se copian solas y se comen la madera. Protagonista: **Garza**.

#### 1. La idea en una frase

Una selva de árboles de kilómetros de alto, con una ciudad viva tallada en sus troncos, que se defiende
de un enjambre de máquinas traídas por los mercenarios que querían venderla a trozos.

#### 2. Identidad y tono

- **Fantasía:** mercenario que vuelve a casa; escalar troncos gigantes, saltar con poca gravedad, planear
  entre cascadas y defender barricadas contra oleadas de máquinas.
- **Tono:** película de asedio. Calor húmedo, sirenas de cuerno, velas por los que no vuelven.
- **Colores:** verde y dorado entre las hojas, rojo del fuego, plata fría del Enjambre.
- **Sonido:** cascadas, insectos, cuernos de alarma, el **zumbido** del Enjambre (se oye antes de verlo).
- **La gente:** delgada, de madera tallada y pintada, con pelo de hojas.

#### 3. Geografía, biomas y puntos de interés

Umbría se juega **en vertical**: suelo, troncos, copas.

| Capa / bioma | Altura | Qué se hace |
|---|---|---|
| **El Suelo Hondo** | 0 m | Oscuridad, setas como sombrillas, ríos, ruinas del pueblo antiguo; peligroso. |
| **Las Raíces** | 0–80 m | Barrio más antiguo de la ciudad; invadido por el Enjambre. |
| **Los Troncos** | 80–600 m | Escalada, nidos, cuevas en la corteza, ascensores de liana. |
| **Las Copas** | 600–900 m | Ciudad alta, planeadores, flores gigantes, cielo dorado. |
| **Las Cascadas Colgantes** | Varias | Ríos que caen de los árboles (agua que se acumula en las copas). |
| **El Claro Muerto** | Suelo | Zona pelada por el Enjambre: tocones, máquinas, la baliza de la compañía. |
| **Órbita: el Vivero de Semillas** | Espacio | Semillas gigantes flotando en órbita (el modo en que los árboles se reproducen). |

**Puntos de interés:** el **Árbol Madre** (el más antiguo; su savia es dorada), la **Baliza de la
Compañía**, el **Lago Espejo** (al pie de una cascada), el **Templo de Raíz** (ruinas del primer pueblo),
el **Nido del Gran Escarabajo**, la **Vaina de la madre de Garza**.

#### 4. Clima y día/noche

- **Día de 40 min:** luz dorada filtrada por las hojas; abajo, siempre penumbra.
- **Lluvias torrenciales** (cada 15–20 min, 3 min): las ramas resbalan, las cascadas crecen.
- **Lluvia de esporas brillantes** al anochecer: preciosa y molesta (medidor de Esporas).
- **Poca gravedad:** saltas muy alto y caes despacio (todo el planeta).
- **Noche:** bioluminiscencia en el Suelo Hondo; el Enjambre ataca más de noche (sus ojos ven mejor).

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Seta sombrilla** | Seta enorme | Se puede usar para frenar caídas (rebota). |
| **Flor de néctar** | Flor gigante | Comida y medicina. |
| **Liana viva** | Liana que se mueve hacia el calor | Sirve para balancearse; si te quedas quieto, te enrolla. |
| **Escarabajo de carga** | Escarabajo gigante | Montura y transporte (la «granja» de Umbría: cría de escarabajos). |
| **Mono planeador** | Mono con membranas | Roba objetos brillantes. |
| **Mantis de corteza** (peligrosa) | Mantis camuflada en los troncos | Embosca en la escalada. |
| **Sapo cascada** | Sapo grande en el Lago Espejo | Se «pesca». |
| **Bichos-máquina del Enjambre** (enemigos) | Arañas, avispas y escarabajos de metal | Se copian solos con madera; atacan en oleadas. |
| **La Reina del Enjambre** (jefe) | Máquina madre del tamaño de un edificio | Jefe final del episodio (con Vesna dentro). |

#### 6. Recursos

- **Únicos:** savia ámbar (pegamento y medicina), madera de hierro (madera dura como el metal), seda de
  liana (cuerda ligerísima).
- **Abundantes:** madera, fibra, comida, agua.
- **Escasos:** metal (aquí casi no hay), electrónica.
- **Nota:** el **Enjambre** suelta piezas de metal al caer: en Umbría el metal se «mina» derrotando
  máquinas.

#### 7. La ciudad: Raíz Honda

**Estilo:** **orgánica en los árboles gigantes**. Casas talladas dentro de los troncos, vainas colgantes,
puentes de liana, plazas en flores gigantes, ascensores de cuerda y polea. Nada está construido «encima»
del árbol: todo crece con él. Sin metal a la vista (lo poco que hay viene de fuera).

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Las Raíces** | Mercados y talleres, abajo del todo. | Invadidas por el Enjambre. |
| **Tronco Mayor** | Ayuntamiento y ascensor de liana. | Cuartel de la defensa. |
| **Ramas Altas** | Casas en vainas colgadas. | Refugio de los que huyen de abajo. |
| **El Vivero** | Granjas y semilleros. | Primera línea del frente. |
| **Flor del Mirador** | Plaza en una flor gigante. | Hospital y último refugio. |
| **Nido de Planeadores** | Estación de planeadores. | Evacuación. |
| **Cascada Mayor** | Barrio-baño junto a una cascada colgante. | Agua para toda la ciudad (si cae, no hay agua). |

- **Transporte:** planeadores, lianas, telecabinas de cesta, escarabajos de carga, ascensores de polea.
- **Tiendas:** herbolario de savias, cuerdas y ganchos, la tienda del gremio de planeadores.
- **Negocios:** cría de escarabajos, taller de planeadores.

#### 8. Forma de vida, leyes y bandos

- **Vida:** turnos de guardia, cuernos de alarma, evacuaciones, velas por los que no han vuelto.
- **Leyes:**
  - **No se corta un árbol vivo.** Nunca. (Quemar Las Raíces es el gran dilema del episodio.)
  - **Todo el mundo hace turno de guardia** (también tú, si vives aquí).
  - **Metal fuera de los talleres:** lo controla el ayuntamiento (el Enjambre se atrae con metal).
- **Costumbres:** cada nacimiento planta una semilla; los muertos vuelven al árbol (se plantan sus
  semillas); saludar tocando la corteza.
- **Bandos (rep):** **la Alcaldía** (Alcaldesa Savia), **el Gremio de Planeadores**, **los Pueblos del
  Suelo** (gente que nunca subió a los árboles) y **la Compañía Torca** (los mercenarios de Vesna; enemigos,
  pero se puede negociar).

#### 9. Trabajos propios de Umbría

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Repartidor/a en planeador** | Reparte entre vainas planeando. | Ruta con corrientes de aire y puntos de aterrizaje en ramas. | Caídas y lluvia. |
| **Barricadero/a** | Levanta barricadas contra el Enjambre. | Talar madera muerta → montar defensas (construcción por piezas) → aguantar oleadas. | Oleadas. |
| **Cuidador/a de escarabajos** | Cría y entrena escarabajos de carga. | Alimentar → entrenar → carreras. | Escarabajos con mal genio. |
| **Podador/a** | Cura árboles y quita ramas muertas. | Escalar → cortar lo muerto → savia en las heridas. | Altura y mantis. |
| **Vigía de copa** | Avisa de ataques desde lo alto. | Turno en la copa → detectar el Enjambre (prismáticos) → tocar el cuerno. | Esporas y frío de noche. |

#### 10. Mecánica única: **escalar, planear y defender**

- **Escalada libre** en los troncos (se pueden agarrar donde hay corteza rugosa; barra de **agarre** que
  baja con la lluvia).
- **Gancho** (recompensa del episodio, pero hay uno básico antes) y **planeador** (se fabrica).
- **Poca gravedad:** saltos largos, caídas lentas. Pero caer desde muy alto sigue haciendo daño.
- **Defensa por oleadas:** el Enjambre ataca puntos de la ciudad. Construyes barricadas, trampas (redes
  de seda, savia pegajosa), torretas de semillas y llamas a defensores NPC. **Las defensas que construyas
  se quedan** en el mapa hasta que se rompen (el jugador siente que la ciudad es suya).
- Recompensa del episodio: **gancho de escalada** y **drones de apoyo**.

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Esporas** (medidor) | Al anochecer y en el Suelo Hondo: picor, visión borrosa, estornudos (que hacen ruido). | Mascarilla de hojas, ungüento de savia, refugios. |
| **Caídas** | Una caída grande hace daño. | Planeador, gancho, setas sombrilla, red de seda. |
| **El Enjambre** | Ataques a cualquier hora (más de noche); se come lo que construyes. | Barricadas, trampas, drones, armas de pulso (apagan robots). |
| **Lluvia** | Ramas resbaladizas, agarre baja. | Guantes de escalada, botas de corteza. |
| **Escasez de metal** | Las piezas de metal son caras. | Derrotar máquinas (chatarra del Enjambre), comercio. |
| **Fauna** | Mantis, monos ladrones, lianas. | Linterna (las lianas se apartan del frío), atención. |

#### 12. Su «mar»: ríos, cascadas y el Lago Espejo

- **Canoas** por los ríos del Suelo Hondo y el Lago Espejo (`BoatService`).
- **Pesca** de sapos cascada y peces de río; **pesca en cascada** (desde una rama, con caña larga).
- **Buceo** en el Lago Espejo: abajo están las ruinas del Templo de Raíz.
- **Descenso de cascadas** en barca (atracción y ruta rápida).

#### 13. Ocio

| En Valmar | En Umbría |
|---|---|
| Karting | **Carreras de planeadores** entre troncos con aros. |
| Deportes | **Carrera de escarabajos** en el Vivero (montados). |
| Skate | **Escalada libre** con récords (subir el Árbol Madre). |
| Feria | **La Fiesta de la Floración**: cuando abre una flor gigante; farolillos de esporas, música de tambor de tronco. |
| Playa | **El Lago Espejo** y sus pozas. |

#### 14. Equivalencias con Valmar

| Valmar | Umbría |
|---|---|
| Coche | Escarabajo de carga |
| Bus / metro | Telecabinas de cesta y ascensores de polea |
| Barco | Canoa |
| Granja | Semilleros del Vivero y cría de escarabajos |
| Pesca | Pesca de río y de cascada |
| Hospital | Flor del Mirador |
| Policía | Guardia de turno (todos los vecinos) |
| Supermercado | Mercado de las Raíces (antes) / mercado de las Ramas (ahora) |

#### 15. Biblia narrativa de Umbría

- **Historia:** los árboles de Umbría son tan viejos como el planeta. El primer pueblo vivió en el suelo
  y subió a los árboles cuando el suelo se inundó; algunos se quedaron abajo (los Pueblos del Suelo). Raíz
  Honda empezó en las raíces y fue creciendo hacia arriba. La madera de hierro de Umbría es la más cara de
  la galaxia.
- **El Enjambre:** la **Compañía Torca**, de mercenarios y madereros, trajo máquinas que se copian solas
  comiendo madera, para pelar el planeta y vender la madera. Garza trabajó para Torca años atrás y vio el
  Enjambre en otro planeta.
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Garza** (39) | Mercenario nacido en Raíz Honda | Cobrar un último trabajo y no volver | Ya conocía el Enjambre y miró hacia otro lado |
| **Vesna** | Su antigua socia, jefa de Torca en Umbría | Dinero y no perder | Está atrapada: la Reina ya no la obedece del todo |
| **Alcaldesa Savia** | La alcaldesa | Salvar la ciudad | Firmó un permiso de tala con Torca hace años |
| **Madre de Garza (Enea)** | Vive en una vaina de las Ramas Altas | Que su hijo vuelva de verdad | Guardó todas sus cartas sin abrir |
| **Ceibo** | Jefe de los Pueblos del Suelo | Que la gente de arriba les respete | Su pueblo sabe apagar las máquinas con un hongo |
| **Dron 7** | Una máquina del Enjambre que se «estropeó» | Nadie lo sabe | Ha empezado a pensar por sí misma |
| **Ala** | Jefa del Gremio de Planeadores | Evacuar a todos | Odia a Garza: él dejó tirado a su padre |

- **Secretos:**
  1. Los **hongos del Suelo** oxidan las máquinas: un arma natural.
  2. El **Árbol Madre** está conectado por las raíces a todos los árboles: si cae, caen todos.
  3. La alcaldesa firmó el permiso que dejó entrar a Torca.
  4. **Dron 7** puede comunicarse con la Reina.

#### 16. Misión principal: «El Enjambre» (episodio 5, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Caída lenta** | (a) Combate aéreo entre los troncos contra drones; (b) caída con poca gravedad; (c) tutorial de escalada y planeador. | — |
| 2 | **El contrato** | (a) Garza negocia su precio con la alcaldesa (diálogo); (b) primera defensa del Vivero (tutorial de barricadas y oleadas). | **¿Pides tú también paga?** Sí: dinero, pero Garza te mira distinto (cambia una frase clave en la misión 4). |
| 3 | **Las Raíces** | (a) Bajar al barrio invadido (escalada hacia abajo, sigilo entre máquinas); (b) encontrar la baliza de la compañía en el Claro Muerto; (c) defenderla mientras Garza la lee. | **¿Rescatas a los vecinos atrapados en Las Raíces** (misión más larga) o vas directo a la baliza? Si los rescatas, en la misión 6 hay menos gente que evacuar. |
| 4 | **Viejos socios** | (a) Vesna aparece; (b) la oferta: la mitad del negocio si Garza se va; (c) Garza duda. | **Tú decides qué le dices a Garza** (quedarse, irse, «haz lo que quieras»). Cambia su escena en la misión 7, pero él se queda igual. |
| 5 | **El Tronco Mayor** | (a) Escalada mientras el Enjambre sube por el tronco (escalada con persecución); (b) la alcaldesa no sale a tiempo de su despacho (escena dura fuera de cámara); (c) defender el ascensor. | — |
| 6 | **Fuego** | (a) La única forma de frenar al Enjambre es **quemar Las Raíces**; (b) evacuar a la gente (rescate con tiempo); (c) encender el fuego (escena de silencio); (d) huida entre las llamas. | **Alternativa** si hiciste la cadena «Lo que sabe el suelo»: usar los hongos en vez del fuego en una parte; se salva una parte de Las Raíces. |
| 7 | **La Reina** | (a) Combate aéreo y a pie contra la Reina del Enjambre (3 fases: armadura, enjambre, núcleo con Vesna); (b) Vesna atrapada en el núcleo. | **¿Sacas a Vesna?** Si la sacas, la llevas a juicio en la ciudad; si no, muere con la Reina (fuera de cámara). Garza respeta las dos. |

- **Giro:** Garza ya conocía el Enjambre.
- **Final (agridulce):** el Enjambre se apaga; Las Raíces (o parte) se pierden. Garza se queda y vende su
  nave para reconstruir.
- **Recompensa:** **gancho de escalada** y **drones de apoyo** (piezas), receta de planeador nivel 3.

#### 17. Cadenas secundarias de Umbría

**A. «Lo que sabe el suelo»** (5 fases, ≈ 55 min)
- **Personajes:** **Ceibo** (jefe del Suelo, orgulloso); **Ala** (jefa de planeadores, desconfiada).
- **Trasfondo:** los de arriba desprecian a los del Suelo desde hace siglos.
- **Gancho:** una máquina del Enjambre aparece oxidada y rota en el Suelo Hondo.
- **Fases:** (1) bajar al Suelo (oscuridad, bioluminiscencia, fauna); (2) ganarte a los del Suelo (una
  prueba: cazar al sapo cascada más grande); (3) aprender a cultivar los hongos oxidantes (granja); (4)
  subir los hongos a la ciudad (escolta de canoas y escalada con carga); (5) convencer a la ciudad
  (asamblea con Ala en contra).
- **Giro:** los del Suelo sabían lo de los hongos desde el principio y no lo dijeron: querían que los de
  arriba bajaran a pedírselo.
- **Decisión:** obligar a Ceibo a darlos (rápido; los del Suelo se cierran para siempre) o negociar un
  sitio para ellos en el consejo de la ciudad (más lento; cambia la ciudad tras el episodio: hay un barrio
  del Suelo arriba).
- **Momento estrella:** cientos de hongos brillando mientras el Enjambre se oxida al tocarlos.
- **Lazo:** el planeta tenía su defensa; hacía falta escuchar a los olvidados.

**B. «Dron 7»** (4 fases, ≈ 45 min)
- **Personajes:** **Dron 7**, una máquina que ha empezado a pensar; **Nía**, niña que la ha escondido.
- **Trasfondo:** el Enjambre se copia sin control; alguna copia sale «distinta».
- **Gancho:** Nía da de comer madera muerta a una máquina en su vaina.
- **Fases:** (1) esconder a Dron 7 de los guardias (sigilo); (2) Dron 7 se comunica con la Reina (puzle de
  señales); (3) la Compañía la busca para destruirla; (4) defender la vaina.
- **Giro:** Dron 7 puede mandar a todas las máquinas apagarse… pero ella se apagaría también.
- **Decisión:** pedírselo (el combate final del episodio es más fácil; escena triste con Nía) o no (Nía se
  queda con su amiga; en el epílogo, Dron 7 ayuda a reconstruir).
- **Momento estrella:** Nía enseñando a Dron 7 a planear.
- **Lazo:** hasta lo que te destruye puede cambiar.

**C. «Las cartas»** (3 fases, ≈ 30 min; emotiva)
- **Personajes:** **Enea**, la madre de Garza; **Garza**.
- **Trasfondo:** Garza mandaba cartas a su madre cada año; ella nunca las abrió.
- **Fases:** (1) ayudar a Enea con su vaina (reparaciones); (2) encontrar las cartas; (3) leerlas con ella
  (una carta por decisión: ¿cuál lees?).
- **Giro:** Enea no las abrió porque no sabía leer; le daba vergüenza decírselo a su hijo.
- **Final:** Garza le lee la última él mismo (si haces esta cadena antes de la misión 7, cambia su
  despedida).
- **Lazo:** la gente que se va también deja algo atrás.

**D. «La deuda de Ala»** (4 fases, ≈ 40 min)
- **Personajes:** **Ala**; su padre muerto, **Remo**; Garza.
- **Trasfondo:** Garza dejó tirado a Remo en una misión hace 20 años.
- **Fases:** (1) trabajar con el gremio de planeadores; (2) carrera de planeadores contra Ala; (3)
  recuperar el planeador de Remo de un nido de mantis; (4) Ala y Garza frente a frente.
- **Giro:** Remo le pidió a Garza que se fuera para salvar a otros; Garza nunca se defendió.
- **Decisión:** contárselo a Ala (se reconcilian; el gremio ayuda en el episodio) o no (Garza no quiere).
- **Lazo:** los mercenarios también cargan con lo que no cuentan.

**E. «Semillas al cielo»** (4 fases, ≈ 45 min; espacial)
- **Personajes:** **Doctora Pétalo**, botánica.
- **Trasfondo:** los árboles lanzan semillas a la órbita y vuelven a caer en el planeta años después.
- **Fases:** (1) subir a la órbita al Vivero de Semillas; (2) recoger semillas sanas entre máquinas del
  Enjambre que las comen (combate espacial); (3) proteger la cápsula de vuelta; (4) plantarlas en el Claro
  Muerto.
- **Decisión:** plantar en el Claro (bosque nuevo dentro de muchos años) o guardarlas para replantar
  Las Raíces quemadas.
- **Final:** abre el **banco de reliquias** de Umbría (en el Templo de Raíz).
- **Lazo:** el bosque se salva a sí mismo si se le deja.

**F. «Madereros»** (4 fases, ≈ 40 min; dilema)
- **Personajes:** **Bruno Corteza**, maderero de Torca que quiere desertar; su cuadrilla.
- **Fases:** (1) capturar a un maderero en el Claro Muerto; (2) interrogarle (diálogo; 13+: solo
  preguntas); (3) te ofrece información a cambio de sacar a su cuadrilla; (4) sacarlos a escondidas.
- **Giro:** la cuadrilla son chavales del propio planeta contratados por hambre.
- **Decisión:** juzgarles en la ciudad, dejarles irse o darles trabajo de barricaderos.
- **Lazo:** quien tala no siempre es quien se lleva la madera.

**G. «El Gran Escarabajo»** (3 fases, ≈ 30 min; ligera)
- **Personajes:** **Tío Musgo**, criador de escarabajos.
- **Fases:** (1) recuperar huevos de escarabajo del Nido (sigilo); (2) criar uno (cuidados en días de
  juego); (3) carrera de escarabajos.
- **Final:** montura propia (vehículo) y negocio de cría.

#### 18. Eventos dinámicos de Umbría

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Oleada** | El Enjambre ataca un barrio | Defender (barricadas, trampas) |
| **Tormenta** | Lluvia torrencial | Rescatar caídos, reparar puentes |
| **Floración** | Se abre una flor gigante | Fiesta, néctar raro |
| **Incendio** | Un rayo prende una rama | Apagar (bombero con agua de cascada) |
| **Paso de monos** | Una manada roba objetos brillantes | Perseguir y recuperar |

#### 19. Línea premium: «El primer pueblo» (5 capítulos)

- **Idea:** el Templo de Raíz guarda la historia del primer pueblo de Umbría, que hablaba con los árboles.
  Una arqueóloga, **Yedra**, te pide ayuda para leer sus marcas.
- **Capítulos:** (1, gratis) bajar al Templo bajo el Lago Espejo; (2) marcas en lo alto del Árbol Madre
  (escalada extrema); (3) una aldea antigua en el Suelo (con fauna peligrosa); (4) el primer pueblo no se
  fue: se convirtió en los Pueblos del Suelo; (5) devolver la historia a Ceibo.
- **Premios:** materiales de reliquia, receta de planeador de reliquia (gratis también con rep 80 con el
  Gremio), Chispas, escarabajo «Ancestral» (aspecto), título «Voz de la Raíz».

#### 20. Horas de juego en Umbría (≈ 11 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 4,5 |
| Defensa por oleadas (eventos y trabajo) | 1 |
| Trabajos | 1 |
| Escalada, exploración y recolección | 1,5 |
| Fabricación y astillero (planeador, drones) | 0,5 |
| Ocio | 0,5 |
| Línea premium | (+1 h) |

---

### 3.6 · MIASMA · Anclaje Siete

> **Episodio 6 · «Guerra en el cielo».** Tóxico, nubes venenosas. Plataformas tecnológicas por encima de la
> niebla. Ragnarock: **una invasión** (el Dominio Talar quiere su gas). Protagonista: **Mara Solís**.

#### 1. La idea en una frase

Un planeta cubierto por un mar de niebla venenosa donde la gente vive en plataformas ancladas a los picos,
y donde un imperio de fuera viene a llevarse el gas que les da de vivir.

#### 2. Identidad y tono

- **Fantasía:** contrabandista y as del aire; batallas aéreas gigantes sobre un mar de niebla; bajar a lo
  venenoso con traje sellado.
- **Tono:** película de guerra aérea con una contrabandista que no quiere ser heroína.
- **Colores:** verde ácido y amarillo de la niebla, morado del cielo alto, blanco eléctrico de los rayos.
- **Sonido:** viento, cables que cantan, motores de globo, sirenas antiaéreas, el burbujeo de la niebla.
- **La gente:** estilo cómic con contorno grueso, capas y pañuelos al viento, siempre con filtro al cuello.

#### 3. Geografía, biomas y puntos de interés

Miasma se juega **por capas de aire**:

| Capa / bioma | Altura | Qué se hace |
|---|---|---|
| **Cielo Alto** | +800 m | Aire limpio, ríos de viento visibles, batallas aéreas. |
| **Los Picos** | +300 a +800 m | Montañas que salen de la niebla; las plataformas se anclan a ellos; minas de plata de rayo. |
| **El Borde** | +200 a +300 m | Superficie de la niebla: olas de gas, «pesca» de medusas, lagos de ácido en los picos. |
| **La Niebla** | 0 a +200 m | Aire venenoso; sin traje no se aguanta. Pecios de plataformas caídas, ciudades antiguas. |
| **El Fondo** | 0 m | El suelo real del planeta: bosques de cristal, el origen del gas pesado. |
| **Órbita: la Flota del Dominio** | Espacio | Acorazados, cazas, el bloqueo. |

**Puntos de interés:** los **Anclajes Caídos** (Uno a Seis: las ciudades que cayeron a la niebla), la
**Refinería**, el **Ojo de la Tormenta** (tormenta eterna con un hueco en el centro), la **Torre
Silbadora** (antena antigua que canta con el viento), el **Lago de Ácido Verde** (en un pico).

#### 4. Clima y día/noche

- **Día de 30 min:** cielo morado arriba, niebla naranja-verdosa abajo.
- **Ríos de viento:** corrientes visibles (cintas de color) que empujan naves y planeadores. Se usan para
  ir más rápido.
- **Tormentas eléctricas:** rayos que caen en los picos y en las naves (peligro y recurso: plata de rayo).
- **Lluvia ácida:** cada 20 min, 2 min; daña el equipo y las naves al descubierto.
- **Marea de niebla:** la niebla sube y baja; cuando sube, tapa plataformas bajas (alarma).

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Medusa de gas** | Medusa enorme que flota en el Borde | Pacífica; se «pesca» con redes para sacar su gas (se suelta luego). |
| **Musgo filtro** | Musgo de los picos que limpia el aire | Ingrediente de filtros. |
| **Mantarraya de nube** | Raya gigante que planea en el Cielo Alto | Se puede seguir para encontrar ríos de viento. |
| **Lagartija de pico** | Lagartija que come rayos | Da plata de rayo si la encuentras tras una tormenta. |
| **Gusano de niebla** (peligroso) | Gusano que nada en la niebla y sube a atrapar lo que se acerca | Embosca a quien baja; **jefe** de la cadena «Lo que hay abajo». |
| **Cazas y bombarderos del Dominio** (enemigos) | Naves del invasor | Atacan la ciudad y los convoyes. |
| **El acorazado de la Almirante Kar** (jefe) | Nave gigante | Jefe del episodio. |

#### 6. Recursos

- **Únicos:** gas pesado (combustible y energía; lo que quiere el Dominio), espora de filtro (base de
  todos los filtros), plata de rayo (armas eléctricas, cables).
- **Abundantes:** gas, metal de los pecios.
- **Escasos:** comida, agua y madera (todo viene de fuera o de los pecios).

#### 7. La ciudad: Anclaje Siete

**Estilo:** **plataformas tecnológicas por encima de la niebla**. Discos de metal y cristal anclados con
cables gigantes a los picos, unidos por puentes colgantes y góndolas; globos de gas que las sostienen;
hangares, antenas y cañones antiaéreos. Debajo, la niebla verde. La ciudad se mueve un poco con el viento
(se nota el balanceo).

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Muelle de Vientos** | Puerto y hangares. | Última base de la defensa. |
| **Las Góndolas** | Casas colgadas de globos. | Muchas, cortadas y perdidas en las nubes. |
| **Plaza de las Veletas** | Mercado y veleta gigante. | Racionamiento. |
| **La Refinería** | Saca el gas pesado de la niebla. | Lo que el invasor quiere. |
| **Arena del Cielo** | Estadio aéreo. | Hangar de cazas. |
| **Barrio Lastre** | El barrio bajo de talleres, el más cerca de la niebla. | Escondite de contrabandistas. |
| **El Ancla** | El gran cable y su maquinaria. | Si se corta, la ciudad cae. |

- **Transporte:** góndolas, tablas de viento, dirigibles, ascensores de cable.
- **Tiendas:** filtros y trajes, piezas de globo, el mercado de Lastre (contrabando), racionamiento de la
  Plaza.
- **Negocios:** taller de filtros, carguero de contrabando.

#### 8. Forma de vida, leyes y bandos

- **Vida:** alarmas aéreas, refugios, pilotos jóvenes que se apuntan a la defensa, racionamiento.
- **Leyes:**
  - **Filtro obligatorio** en las zonas bajas.
  - **Racionamiento:** cada uno tiene su ración; acaparar es delito.
  - **Prohibido salir sin permiso de vuelo** durante el asedio (control del Muelle).
  - **Pena por espionaje:** muy dura (gran tema del episodio).
- **Costumbres:** atar un pañuelo a la barandilla por cada nave que no vuelve; «la última copa de aire»
  (respirar aire limpio embotellado en las celebraciones).
- **Bandos (rep):** **la Defensa** (comandante Andrés), **los Contrabandistas de Lastre** (Mara), **los
  Refineros** (los que sacan el gas; neutrales, poderosos), **el Dominio Talar** (enemigo; algunos
  desertores).

#### 9. Trabajos propios de Miasma

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Mecánico/a de globos** | Repara globos y cables. | Escalar el globo → parchear (minijuego) → comprobar presión. | Viento y altura. |
| **Cargador/a de munición** | Recarga las baterías antiaéreas en los ataques. | Llevar munición bajo fuego → cargar a tiempo. | Ataques. |
| **Filtrador/a** | Mantiene los filtros de la ciudad. | Revisar → cambiar → limpiar con esporas. | Toxinas. |
| **Buzo de niebla** | Baja a la niebla a recuperar cosas de los pecios. | Bajar con traje → buscar → subir antes de que se acabe el filtro. | Toxinas y gusanos. |
| **Vigía meteorológico** | Avisa de tormentas y mareas de niebla. | Instrumentos → predecir (minijuego) → avisar. | Rayos. |

#### 10. Mecánica única: **combate aéreo y el mar de niebla**

- **El episodio de las grandes batallas aéreas** (se apoya en todo el vuelo «AAA» que ya existe): defensa
  de la ciudad, convoyes, acorazados, persecuciones entre cables.
- **Ríos de viento:** volar dentro de uno da velocidad; contra él, gasta más energía.
- **La niebla como suelo:** si caes, no hay suelo: hay **niebla venenosa**. Caer sin traje es perder
  (Derribado); con traje, puedes volver a subir con el gancho o el planeador.
- **Tablas de viento:** vuelo a pie (como planear, pero más rápido) con el traje.
- Recompensa del episodio: nave **Tortuga** y **llamada de escolta**.

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Toxinas** (medidor) | En la niebla y el Borde, y con lluvia ácida: tos, visión verde, daño. | Filtros (nivel 1–5: más duración), respirador, traje sellado, cápsulas de aire limpio. |
| **Lluvia ácida** | Daña equipo y naves. | Capa impermeable, recubrimiento de casco. |
| **Caídas a la niebla** | Sin suelo. | Planeador, gancho, cuerda de seguridad. |
| **Rayos** | Golpean lo metálico en alto. | Pararrayos portátil, refugio. |
| **Asedio** | Ataques aéreos, racionamiento, control de vuelos. | Permisos, contrabando, defensa. |

#### 12. Su «mar»: el Mar de Niebla

- **Navegar** sobre la niebla en **barcazas-globo** (`BoatService` con modelo flotante sobre la niebla).
- **Pesca de medusas de gas** con redes (se sacan su gas y se sueltan; nada de crueldad).
- **Buceo en la niebla:** bajar con traje sellado a los Anclajes Caídos (como el buceo, pero con
  Toxinas en vez de oxígeno; las mismas reglas de profundidad por nivel de traje).
- **Lagos de ácido** en los picos: no se nada; se recoge cristal ácido en las orillas.

#### 13. Ocio

| En Valmar | En Miasma |
|---|---|
| Karting | **Carreras de tablas de viento** por los ríos de viento. |
| Deportes | **Duelos amistosos** en la Arena del Cielo (antes del asedio; igualados). |
| Feria | **La Copa de Globos**: carrera de globos y fiesta en la Plaza de las Veletas. |
| Skate | **Trucos en tabla de viento** (`SkateService` en el aire). |
| Playa | **El Mirador del Ocaso**: terraza con aire limpio embotellado y vistas a la niebla. |

#### 14. Equivalencias con Valmar

| Valmar | Miasma |
|---|---|
| Coche | Tabla de viento, minidirigible |
| Bus / metro | Góndolas y ascensores de cable |
| Barco | Barcaza-globo |
| Granja | Invernaderos colgantes de musgo filtro |
| Pesca | Pesca de medusas de gas |
| Hospital | Enfermería del Muelle (intoxicaciones) |
| Policía | Policía del Muelle (espionaje y racionamiento) |
| Supermercado | Racionamiento de la Plaza |

#### 15. Biblia narrativa de Miasma

- **Historia:** Miasma era un planeta verde. Hace 300 años, un volcán de gas lo cubrió de niebla
  venenosa. La gente se refugió en los picos y construyó los **Anclajes** (siete ciudades). Uno a uno
  fueron cayendo (por tormentas, cables rotos, guerras entre ellos). Solo queda el **Siete**. Viven de
  sacar el gas pesado y venderlo.
- **La invasión:** el **Dominio Talar**, un imperio de otro sistema, necesita gas pesado para su flota y
  ha puesto un bloqueo en órbita. Anclaje Siete aguanta un asedio.
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Mara Solís** (41) | Contrabandista | Sacar a su hijo del planeta | Vendió los códigos de defensa al Dominio |
| **Andrés** | Su exmarido, comandante de la defensa | Aguantar | Sabe que no pueden ganar |
| **Leo** (15) | Su hijo, quiere ser piloto | Defender su ciudad | Se ha apuntado a la defensa con papeles falsos |
| **Almirante Ysolde Kar** | Jefa de la flota del Dominio | El gas, sin destruir la ciudad si puede | Le han ordenado destruirla si no se rinde |
| **Maestro Refinero Olmo** | Jefe de la Refinería | Que la Refinería sobreviva, gane quien gane | Negocia en secreto con el Dominio |
| **Teniente Cobalto** | Desertor del Dominio | Que su familia no sepa que desertó | Conoce el punto débil del acorazado |
| **Abuela Niebla** | Superviviente del Anclaje Seis | Que alguien baje a buscar a los suyos | Su Anclaje no cayó del todo: hay gente viviendo abajo |

- **Secretos:**
  1. En el **Anclaje Seis**, caído en la niebla, vive gente con trajes, en una burbuja de aire.
  2. El **Ojo de la Tormenta** es la única salida que el bloqueo no vigila.
  3. El gas pesado se acabará en 30 años: el Dominio llega a llevarse lo último.
  4. El fondo del planeta **se está limpiando** solo (el bosque de cristal filtra el gas).

#### 16. Misión principal: «Guerra en el cielo» (episodio 6, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Bajo el asedio** | (a) Atravesar el bloqueo con Mara (combate espacial y esquiva); (b) entrada en la atmósfera entre cazas; (c) aterrizaje en Lastre; tutorial de Toxinas. | — |
| 2 | **Mercancía** | (a) Un viaje de contrabando con Mara; (b) sale mal: emboscada en las nubes; (c) caída al Borde: recuperar la carga con traje antes de que se hunda. | **¿Le cuentas a la Defensa lo que llevabais?** Rep Defensa + / Contrabandistas −. |
| 3 | **El ataque** | (a) Gran ataque aéreo del Dominio; (b) defender las góndolas (combate aéreo + cargar munición a pie); (c) rescatar una góndola cortada antes de que caiga a la niebla. | **Dos góndolas caen a la vez:** eliges cuál salvar (la de un hospital o la de un barrio). La otra cae (fuera de cámara; pañuelos en la barandilla). |
| 4 | **El traidor** | (a) Andrés busca al espía; (b) investigar (pistas, interrogatorios; 13+: preguntas); (c) las pistas apuntan a Mara. | **¿Encubres a Mara?** Sí: ella confiesa luego por sí misma (escena mejor). No: la detienen y la sacas para la misión 7. |
| 5 | **Leo** | (a) El primer vuelo de combate de Leo; (b) le derriban sobre la niebla; (c) bajar con traje a por él (buceo en niebla, gusano de niebla); (d) subida. | — |
| 6 | **El Ojo de la Tormenta** | (a) Gran batalla aérea para abrir un hueco en el bloqueo; (b) volar dentro de la tormenta eterna (rayos, ríos de viento); (c) jefe: **el acorazado de Kar** (fases: torretas, hangares, puente). | **Kar te ofrece rendirse** si dejas que se lleve el gas. Si aceptas, nadie muere en la batalla final, pero el gas se acaba antes (epílogo distinto). Si no, la batalla sigue. |
| 7 | **El último convoy** | (a) Escoltar la evacuación por las rutas de Mara mientras la ciudad cae; (b) Andrés cubre la retirada; (c) el Ancla se rompe: la ciudad cae a la niebla (secuencia final). | — |

- **Giro:** Mara vendió los códigos al principio del asedio para que la dejaran pasar.
- **Final (agridulce):** Anclaje Siete cae; casi toda su gente escapa. Andrés no vuelve. Mara le cuenta lo
  de los códigos a Leo en la última escena.
- **Tras el episodio** (para que el planeta se pueda seguir jugando): la gente se reasienta en el
  **Anclaje Ocho**, una plataforma nueva más pequeña sobre otro pico (la ciudad jugable «después»). Las
  ruinas del Siete quedan en la niebla, como zona de buceo.
- **Recompensa:** nave **Tortuga**, **llamada de escolta** (piezas), receta de filtro nivel 3.

#### 17. Cadenas secundarias de Miasma

**A. «El Anclaje Seis»** (5 fases, ≈ 60 min)
- **Personajes:** **Abuela Niebla**; **Cardo**, joven del Seis que vive abajo; **Maestro Olmo**.
- **Trasfondo:** el Seis cayó hace 40 años; todos lo dieron por muerto.
- **Gancho:** una señal de radio débil desde la niebla con una canción infantil del Seis.
- **Fases:** (1) bajar a la niebla siguiendo la señal (buceo en niebla); (2) encontrar la burbuja de aire
  del Seis (una ciudad abajo, viva); (3) ganarte a los de abajo (desconfían de los de arriba); (4) están
  quedándose sin filtros: fabricar y bajar filtros (fabricación y transporte en el Borde); (5) Olmo quiere
  usar el Seis como mina.
- **Giro:** la Abuela Niebla dejó atrás a su propia familia cuando cayó el Seis. Cardo es su nieto.
- **Decisión:** subir a los del Seis (rescate masivo, la ciudad de arriba tiene que compartir raciones) o
  ayudarles a quedarse abajo (les das los filtros y una ruta; Olmo no puede minarlo).
- **Momento estrella:** la burbuja del Seis iluminada en mitad de la niebla, con gente cultivando dentro.
- **Lazo:** los que «cayeron» al fin del mundo aprendieron a vivir en él.

**B. «El desertor»** (4 fases, ≈ 45 min)
- **Personajes:** **Teniente Cobalto**, desertor del Dominio; **Leo**, que quiere entregarlo.
- **Trasfondo:** Cobalto desertó al ver la orden de destruir la ciudad.
- **Gancho:** un caza del Dominio aterriza sin disparar en un pico.
- **Fases:** (1) llegar antes que la Defensa; (2) esconderle en Lastre; (3) le buscan los dos bandos
  (sigilo y huida en tabla de viento); (4) te cuenta el punto débil del acorazado.
- **Giro:** Cobalto tiene un hermano en el acorazado de Kar.
- **Decisión:** usar el punto débil (la batalla del episodio es más corta pero el hermano muere en ella,
  fuera de cámara) o ayudar a Cobalto a avisar a su hermano (la batalla es más larga; el hermano deserta).
- **Lazo:** los soldados del imperio también son gente con familia.

**C. «Lo que hay abajo»** (4 fases, ≈ 45 min)
- **Personajes:** **Doctora Liquen**, bióloga que cree que el fondo se está limpiando; **Capitán Rizo**,
  buzo de niebla veterano.
- **Fases:** (1) bajar hasta el Fondo (la inmersión más honda, traje nivel 4); (2) el bosque de cristal
  (bioma nuevo, precioso); (3) el gusano de niebla (jefe) os persigue; (4) subir con las muestras.
- **Giro:** el aire del fondo está casi limpio: en 50 años, Miasma podría volver a ser verde.
- **Decisión:** contárselo a todos (esperanza; también se lo cuentas al Dominio) o guardarlo (el Dominio
  no lo sabe y no viene a quedarse).
- **Lazo:** el fin del mundo podría tener un después.

**D. «Ración doble»** (3 fases, ≈ 30 min; dilema)
- **Personajes:** **Señora Garúa**, vecina que acapara; sus nietos.
- **Fases:** (1) investigar quién acapara raciones (Policía del Muelle); (2) descubrir que Garúa guarda para
  sus nietos enfermos; (3) decidir.
- **Decisión:** denunciarla, callar o conseguir medicinas para los nietos (misión extra en el mercado de
  Lastre).
- **Lazo:** en un asedio, todo el mundo es un poco ladrón.

**E. «La Torre Silbadora»** (4 fases, ≈ 40 min; puzles)
- **Personajes:** **Silbo**, ingeniero ciego que oye el viento.
- **Fases:** (1) escalar la Torre con tormenta; (2) afinar sus tubos (puzle de sonido); (3) la Torre canta:
  dibuja los ríos de viento en el mapa; (4) cazas del Dominio quieren destruirla (defensa).
- **Final:** mapa de ríos de viento (viajes más rápidos) y abre el **banco de reliquias** de Miasma.
- **Lazo:** el planeta habla, si alguien escucha.

**F. «Copa de Globos»** (3 fases, ≈ 30 min; ligera)
- **Personajes:** **Las hermanas Brisa y Ráfaga**, pilotos de globo rivales.
- **Fases:** (1) construir un globo (fabricación); (2) carrera; (3) una tormenta durante la carrera: rescatar
  a la rival o ganar.
- **Final:** globo propio (vehículo) y título.

**G. «Contrabando de esperanza»** (4 fases, ≈ 45 min)
- **Personajes:** **Mara**; **Pico**, su antiguo socio.
- **Fases:** (1) planear una ruta por el Ojo de la Tormenta; (2) cargar medicinas en una estación del
  Dominio (infiltración en nave); (3) huida por el Ojo; (4) reparto en la ciudad.
- **Giro:** Pico ha vendido la ruta al Dominio.
- **Decisión:** perseguir a Pico o salvar la carga.
- **Lazo:** contrabandear también puede ser salvar vidas.

#### 18. Eventos dinámicos de Miasma

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Ataque aéreo** | Oleada del Dominio | Defender, cargar munición |
| **Marea de niebla** | La niebla sube y tapa plataformas bajas | Evacuar, filtros |
| **Tormenta eléctrica** | Rayos | Recoger plata de rayo, reparar |
| **Góndola a la deriva** | Una góndola se suelta | Rescate en el aire |
| **Banco de medusas** | Muchas medusas en el Borde | Pesca de gas |

#### 19. Línea premium: «Las cajas del Anclaje Uno» (5 capítulos)

- **Idea:** el Anclaje Uno, la primera ciudad, cayó hace 280 años con su archivo. Una cartógrafa,
  **Estela Vane**, busca sus cajas de registros, que cuentan cómo empezó todo.
- **Capítulos:** (1, gratis) la primera caja en un pecio del Borde; (2) bajar al Uno (buceo en niebla,
  ruinas antiguas); (3) un río de viento lleva una caja a la órbita (persecución espacial); (4) el Dominio
  también las busca; (5) la última caja: los fundadores provocaron el volcán de gas al minar.
- **Premios:** materiales de reliquia, receta de traje sellado de reliquia (gratis también con rep 80 con
  los Refineros), Chispas, tabla de viento «Fundadora» (aspecto), título «Archivo del Aire».

#### 20. Horas de juego en Miasma (≈ 11 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 5 |
| Combate aéreo (eventos, defensa, convoyes) | 1 |
| Trabajos | 1 |
| Buceo en niebla, exploración y recolección | 1 |
| Fabricación y astillero (filtros, Tortuga) | 0,5 |
| Ocio | 0,5 |
| Línea premium | (+1 h) |

---

### 3.7 · VÉRTICE · Distrito Cero

> **Episodio 7 · «Liquidación total».** Urbano. Megaciudad futurista con tráfico aéreo. Ragnarock: **la
> quiebra de la empresa que lo posee todo, y la revuelta.** Protagonista: **Abril Cruz**.

#### 1. La idea en una frase

Un planeta que es una sola ciudad, propiedad de una empresa en quiebra, donde todo tiene precio, todo te
multa, y el cielo de anuncios esconde que su estrella lleva años muerta.

#### 2. Identidad y tono

- **Fantasía:** atracador elegante y rebelde urbano; tráfico aéreo entre rascacielos, infiltración en
  oficinas, hackeo, asalto a una torre.
- **Tono:** sátira negra de empresa que acaba en revuelta. Los anuncios siguen sonando mientras la ciudad
  arde.
- **Colores:** blanco frío, neones de anuncio (rosa, cian, amarillo), y el negro de abajo.
- **Sonido:** jingles de anuncios, tráfico aéreo, sirenas privadas, voces automáticas («Gracias por su
  compra»).
- **La gente:** los empleados, lisos y brillantes, «de anuncio»; los de abajo, de mil planetas distintos.

#### 3. Geografía, biomas y puntos de interés

Vértice es **una ciudad entera**, por niveles:

| Nivel / bioma | Qué hay | Qué se hace |
|---|---|---|
| **La Cúpula** (arriba) | Pantalla gigante que hace de cielo con anuncios. | Mantenimiento, el gran secreto. |
| **Nivel Alto** | Torres de oficinas, áticos, tráfico aéreo de lujo. | Infiltración, robos, carreras aéreas. |
| **Nivel Medio** | Tiendas, barrios de empleados, el metro. | Vida, trabajos, tiendas. |
| **Nivel Bajo** | Fábricas, almacenes, puertos de carga. | Trabajo duro, contrabando. |
| **El Rastro de Abajo** | Mercado secreto en niveles abandonados. | Resistencia, mercado negro. |
| **Los Aliviaderos** | Niveles inundados del fondo: barrios antiguos bajo el agua. | «El mar» de Vértice. |
| **Órbita: los Astilleros Orbitales** | Astilleros gigantes de MegaVerso. | Las mejores piezas de nave; combate. |

**Puntos de interés:** la **Torre de Ventas** de MegaVerso, el **Museo de la Luz** (cuenta la «historia
oficial»), la **Plaza del Primer Cliente** (estatua de un señor sonriente), el **Vertedero Infinito**, la
**Central de Luz Embotellada**, el **Cementerio de Marcas** (carteles de empresas quebradas).

#### 4. Clima y día/noche

- **El «día» lo pone la Cúpula:** un cielo azul falso con anuncios; se «apaga» a las 23:00 y se
  «enciende» a las 7:00.
- **No hay clima de verdad**, salvo **lluvia de mantenimiento** (la Cúpula riega la ciudad) y la **«Hora
  Punta»** (las aceras-cinta te llevan donde quieren y el tráfico aéreo se colapsa).
- **Apagones** cuando falla la luz embotellada (más frecuentes según avanza la quiebra).

#### 5. Flora y fauna

| Ser | Cómo es | Comportamiento |
|---|---|---|
| **Árbol de plástico** | Árbol decorativo | Algunos han «mutado» con la luz: dan frutos raros (recolección). |
| **Rata de cable** | Rata que come cables | Plaga; causa apagones. |
| **Paloma de anuncio** | Paloma robótica con pantalla | Te sigue enseñando anuncios; se puede hackear. |
| **Pez de aliviadero** | Pez pálido de los niveles inundados | Se pesca. |
| **Gato de azotea** | Gatos callejeros | Mascotas (`PetService`). |
| **Drones y robots de seguridad** (enemigos) | Seguridad privada de MegaVerso | Multan, persiguen, disparan. |
| **El Recaudador** (peligroso) | Robot de cobro gigante | **Jefe** de la cadena «El Recaudador». |
| **La nave de Ofelia** (jefe) | Yate armado de la directora | Jefe final del episodio. |

#### 6. Recursos

- **Únicos:** chips usados (electrónica), luz embotellada (energía), aleación de anuncio (metal ligero de
  pantallas).
- **Abundantes:** electrónica, plástico, basura.
- **Escasos:** comida natural, aire limpio en el Nivel Bajo, **luz** (cada vez más).

#### 7. La ciudad: Distrito Cero

**Estilo:** **megaciudad futurista con tráfico aéreo**. Rascacielos de cristal y neón, autopistas en el
aire con carriles de colores, pantallas gigantes, aceras-cinta. **Distrito Cero** es el centro, el
primer barrio que construyó MegaVerso (el «kilómetro cero» de la ciudad), y el que tiene todos los
niveles uno encima de otro.

| Barrio | Qué hay | Cómo está ahora |
|---|---|---|
| **Avenida Rebajas** | Tiendas enormes. | Escaparates rotos y saqueos. |
| **Barrio Plantilla** | Casas iguales de los empleados. | Despidos masivos y desalojos. |
| **Puerto de Carga** | Almacenes de luz embotellada. | Vigilado por la seguridad privada. |
| **Distrito Oficinas** | La **Torre de Ventas** de MegaVerso. | Búnker. |
| **El Rastro de Abajo** | Mercado secreto bajo la ciudad. | Cuartel de la resistencia. |
| **Parque Patrocinado** | Parque de plástico. | Campamento de despedidos. |
| **Nivel Celeste** | Áticos de los directivos. | Fiestas mientras la ciudad cae. |
| **Los Aliviaderos** | Barrios antiguos inundados. | Escondites, contrabando, buceo. |

- **Transporte:** aceras-cinta, metro de anuncios (`MetroService`), lanzaderas aéreas por carriles, taxis
  aéreos, ascensores entre niveles.
- **Tiendas:** todas (es el planeta de las tiendas), con precios que **cambian cada hora**; las del Rastro
  (baratas, sin garantía).
- **Negocios:** tienda en la Avenida, taller de chips en el Rastro.

#### 8. Forma de vida, leyes y bandos

- **Vida:** anuncios de ofertas mientras desalojan casas; guardias de seguridad privada; asambleas en el
  Rastro; gente que trabaja tres empleos.
- **Leyes (la desventaja de Vértice):**
  - **Todo es de la empresa**: la ley la pone MegaVerso y la cumple su seguridad privada.
  - **Multas automáticas**: correr en la acera, cruzar mal, volar fuera de carril, sentarse en un banco
    «sin consumir»… Las cámaras te multan solas.
  - **Puntuación de cliente**: cuanto más compras y menos multas tienes, más puertas se abren (y al revés).
  - **Deuda**: las multas sin pagar se convierten en deuda; con mucha deuda, **embargan** cosas.
- **Costumbres:** decir «gracias por su compra» como saludo (irónico abajo), canjear puntos por todo, las
  asambleas del Rastro con votación a mano alzada.
- **Bandos (rep):** **MegaVerso** (Ofelia Brum), **la Resistencia del Rastro** (Abril), **los
  Empleados** (que tienen miedo a perderlo todo; portavoz **Gil**), **los Chatarreros del Vertedero**
  (neutrales, saben todo de la basura).

#### 9. Trabajos propios de Vértice

| Trabajo | Qué haces | Bucle | Desventaja |
|---|---|---|---|
| **Reponedor/a** | Repone en tiendas gigantes (como en Valmar, a lo bestia). | Cajas → estanterías → cumplir el ritmo («productividad») o te descuentan. | Puntuación y multas. |
| **Técnico/a de cúpula** | Arregla la Cúpula y las farolas. | Subir → reparar paneles (minijuego) → volver antes del apagón. | Altura y apagones. |
| **Mensajero/a aéreo** | Entrega en lanzadera por carriles aéreos. | Ruta → respetar (o no) los carriles → entregar a tiempo. | Multas de tráfico. |
| **Abogado/a de barrio** | Ayuda a vecinos con sus multas y deudas. | Caso → buscar pruebas (cámaras, testigos) → juicio rápido (minijuego de argumentos). | Ninguna, pero te hace enemigo de MegaVerso. |
| **Chatarrero/a de vertedero** | Rebusca en el Vertedero Infinito. | Buscar → desmontar → vender chips. | Ratas de cable y desprendimientos. |

#### 10. Mecánica única: **ley, deuda y crimen**

- **Puntuación de cliente** (0 a 1000): sube con compras, trabajos y buen comportamiento; baja con multas
  y deudas. Abre puertas físicas (torniquetes del Nivel Alto, tiendas, ascensores).
- **Multas automáticas** (se reutiliza `WantedService`, `ConductService` y `JusticeService`): las cámaras
  detectan infracciones; te llega la multa al teléfono.
- **Deuda:** las multas que no pagas en un día de juego se convierten en deuda con intereses. Con mucha
  deuda, la seguridad **embarga** objetos (solo de los que llevas encima en Vértice, nunca de tu nave ni
  de lo que tengas en otros planetas; siempre recuperables pagando).
- **Crimen:** puedes robar, hackear y saltarte normas. Da dinero rápido, pero sube tu nivel de búsqueda,
  baja tu puntuación y la resistencia **no** respeta al ladrón que roba a los vecinos (rep). El crimen
  contra MegaVerso es otra cosa (misiones).
- **Hackeo:** minijuego para abrir puertas, apagar cámaras y cambiar carteles.
- **Tráfico aéreo con carriles:** volar fuera de carril es más rápido pero multa.

#### 11. Desventajas y contramedidas

| Desventaja | Qué pasa | Contramedidas |
|---|---|---|
| **Deuda** (medidor) | Multas que crecen; embargos. | Pagar, el abogado de barrio, la cadena «Borrón y cuenta nueva». |
| **Vigilancia** | Cámaras y drones por todas partes. | Hackeo, gorra antirreconocimiento (fabricada), traje Camaleón (como empleado), rutas del Rastro. |
| **Precios que cambian** | Lo que compras puede valer el doble mañana. | Mirar el tablón, comprar en el Rastro, comerciar desde otros planetas. |
| **Hora Punta** | Aceras-cinta y tráfico te arrastran. | Rutas alternativas, horario. |
| **Apagones** | Sin luz, la seguridad se vuelve loca y salen los saqueadores. | Linterna, generador de luz embotellada. |
| **Aire malo en el Nivel Bajo** | Toxinas suaves. | Filtro de Miasma (comercio). |

#### 12. Su «mar»: los Aliviaderos

- Niveles inundados del fondo de la ciudad: calles, tiendas y metro bajo el agua.
- **Barcas de basura** y lanchas de contrabando (`BoatService`).
- **Pesca** de peces de aliviadero y **pesca de basura** (reciclaje: sacas chips y objetos).
- **Buceo** por las calles antiguas: los primeros barrios de Vértice, de antes de MegaVerso.

#### 13. Ocio

| En Valmar | En Vértice |
|---|---|
| Karting | **Carreras callejeras de lanzaderas** (ilegales: multa si te pillan) y la **Liga Aérea** oficial (legal, igualada). |
| Feria | **La Gran Rebaja**: festival de MegaVerso con concursos absurdos (comer anuncios, carrera de carritos). |
| Deportes | **Hoverbol** en el estadio patrocinado (3 contra 3 con tablas flotantes). |
| Recreativos / cine | **Arcade de neón** del Rastro y el cine del Nivel Medio. |
| Playa | **La Playa Artificial** del Nivel Celeste (solo con puntuación alta) y el Parque Patrocinado. |

#### 14. Equivalencias con Valmar

| Valmar | Vértice |
|---|---|
| Coche | Lanzadera aérea |
| Bus / metro | Metro de anuncios y aceras-cinta |
| Barco | Barca de los Aliviaderos |
| Granja | Huertos ilegales en azoteas (fruta mutada) |
| Pesca | Pesca en los Aliviaderos |
| Hospital | Clínica de pago / clínica gratis del Rastro |
| Policía / cárcel | Seguridad privada / «Centro de Reeducación Laboral» |
| Supermercado | Hipermercados de la Avenida |

#### 15. Biblia narrativa de Vértice

- **Historia:** Vértice fue un planeta normal hasta que **MegaVerso** compró el planeta entero hace 150
  años. Lo cubrió de ciudad y vendió de todo a toda la galaxia. Hace 40 años, su estrella **se apagó**. La
  empresa tapó el cielo con la **Cúpula** y empezó a fabricar **luz embotellada** para que nadie lo
  supiera. Ahora la empresa está en quiebra.
- **La Liquidación Total:** la directora, **Ofelia Brum**, prepara vender la deuda de los trabajadores a
  otros planetas, como mano de obra. El primer barrio de la lista es Barrio Plantilla.
- **Personajes clave:**

| Personaje | Quién es | Qué quiere | Su secreto |
|---|---|---|---|
| **Abril Cruz** (36) | Técnica de cúpula, líder de la resistencia | Que Vértice sea de quien vive en él | Sospecha lo de la estrella y no se atreve a comprobarlo |
| **Simón Cruz** | Su hermano, jefe de seguridad | Proteger a su familia | Ha visto la lista entera y sabe que su madre está en ella |
| **Ofelia Brum** | Directora de MegaVerso | Salir con el dinero | Sabe lo de la estrella desde siempre |
| **Gil** | Empleado con 40 años fichando | No perderlo todo | Es quien avisa a Ofelia de los planes de Abril |
| **La Contable** | Inteligencia artificial de MegaVerso | Que las cuentas cuadren | Empieza a dudar de las órdenes de Ofelia |
| **Mamá Cruz (Rosa)** | Madre de Abril y Simón | Que sus hijos se hablen | Está en la lista |
| **Tuercas** | Jefe de los Chatarreros | Que le dejen en paz | Tiene en el Vertedero los primeros planos de la Cúpula |

- **Secretos:**
  1. **La estrella está muerta**; toda la luz es embotellada.
  2. La **Contable** puede borrar todas las deudas de un golpe.
  3. En los Aliviaderos están los **barrios de antes**, con la historia que MegaVerso borró.
  4. Ofelia tiene una nave preparada con la caja fuerte.

#### 16. Misión principal: «Liquidación total» (episodio 7, ≈ 2 h)

| # | Misión | Fases y juego | Decisión y consecuencia |
|---|---|---|---|
| 1 | **Llegada en plena revuelta** | (a) Entrar en el tráfico aéreo (tutorial de carriles y multas); (b) aterrizas en un tiroteo entre la resistencia y la seguridad privada; (c) huida por los Aliviaderos. | — |
| 2 | **Empleado nuevo** | (a) Te cuelas en la Torre con el traje Camaleón como empleado; (b) **comedia negra de oficina**: reuniones absurdas, productividad, el jefe que te vigila (minijuegos de oficina); (c) robar datos sin que te pillen. | **En la Torre puedes quedarte con dinero de una cuenta** (mucho) o no. Si te lo quedas, más tarde la Contable te delata (persecución extra). |
| 3 | **El Rastro** | (a) Asamblea de la resistencia; (b) Abril y su plan; (c) votación (el jugador vota entre dos planes: asalto o huelga). | **Asalto** (más combate en la misión 5) o **huelga** (más sigilo y apagón de la ciudad en la misión 5). |
| 4 | **Simón** | (a) Abril queda con su hermano a escondidas; (b) alguien les ha seguido: emboscada; (c) huida por las aceras-cinta en hora punta. | **¿A quién cubres primero?** A Abril o a Simón: el otro queda herido (sin sangre) y cambia su confianza en ti. |
| 5 | **El Puerto de Carga** | (a) Asalto o huelga (según la votación); (b) liberar los almacenes de luz embotellada; (c) repartir la luz en el Barrio Plantilla. | — |
| 6 | **La Cúpula** | (a) Subir a la Cúpula por mantenimiento (escalada en altura, drones); (b) lo que hay detrás: **la estrella muerta**; (c) bajar con la verdad. | **¿Se lo cuentas a la ciudad ya** o esperas a tener a Ofelia? Ya: revuelta total en la misión 7 (más enemigos, más aliados). Esperar: misión 7 más sigilosa. |
| 7 | **Liquidación** | (a) Asalto a la Torre de Ventas; (b) la Contable (puzle de hackeo: convencerla con datos); (c) **batalla contra la nave de Ofelia** entre rascacielos (jefe). | **La Contable te ofrece borrar todas las deudas** (todo el mundo libre, pero MegaVerso se hunde del todo y la luz embotellada se acaba antes) o **solo las de la lista** (más prudente). |

- **Giro:** quien avisaba a Ofelia no era Simón, sino **Gil**, a cambio de no estar en la lista. Simón, al
  final, abre las puertas de la Torre.
- **Final (agridulce):** la Cúpula se apaga; la gente ve por primera vez su cielo de verdad: negro, sin
  sol. Ofelia **se escapa** con la caja fuerte. Abril se queda: «Al menos ahora sabemos dónde estamos».
- **Tras el episodio:** Distrito Cero pasa a ser **la ciudad de los vecinos** (las multas automáticas se
  apagan; el reto pasa a ser la luz: la economía cambia).
- **Recompensa:** la **Aguja de oro mejorada** (volver a cualquier planeta cuando quieras), receta de
  generador de luz embotellada.

#### 17. Cadenas secundarias de Vértice

**A. «Borrón y cuenta nueva»** (5 fases, ≈ 55 min)
- **Personajes:** **Marta Saldo**, abogada de barrio que perdió su licencia; **Julián**, cobrador de
  MegaVerso.
- **Trasfondo:** las deudas de Vértice se heredan de padres a hijos.
- **Gancho:** un niño en el Parque Patrocinado con una deuda a su nombre de 40.000.
- **Fases:** (1) trabajar de abogado de barrio (3 casos pequeños, minijuego de argumentos); (2) investigar
  el origen de la deuda del niño (archivos); (3) colarse en el Archivo de Deudas (sigilo + hackeo); (4)
  Julián os pilla y propone un trato; (5) juicio en el tribunal de la empresa.
- **Giro:** Julián tiene la misma deuda heredada; trabaja de cobrador para pagarla.
- **Decisión:** ganar el juicio con una prueba falsa (ganas seguro; Marta no vuelve a confiar en ti) o con
  la verdad (más difícil; si ganas, abre el «perdón de deudas heredadas» para todo el barrio).
- **Momento estrella:** el discurso final en un tribunal de plástico lleno de anuncios.
- **Lazo:** en Vértice se nace debiendo.

**B. «El Recaudador»** (4 fases, ≈ 45 min)
- **Personajes:** **Tuercas** (jefe de los Chatarreros); **El Recaudador** (robot gigante de cobro).
- **Trasfondo:** el Recaudador se ha estropeado y embarga casas enteras.
- **Fases:** (1) seguir su rastro de embargos (investigación); (2) los Chatarreros saben cómo pararlo,
  pero piden algo a cambio (recolección en el Vertedero); (3) trampa en el Vertedero; (4) jefe: **El
  Recaudador** (fases: escudo, brazos de embargo, núcleo).
- **Giro:** el Recaudador obedece a la Contable, que lo usa para avisar de que algo va mal (embarga los
  áticos de los directivos, no solo a los pobres).
- **Decisión:** destruirlo (piezas de reliquia) o reprogramarlo (devuelve lo embargado al barrio).
- **Lazo:** las máquinas de la empresa también están cansadas de sus reglas.

**C. «Gil»** (4 fases, ≈ 40 min; dilema)
- **Personajes:** **Gil**; su mujer **Amparo**, enferma.
- **Trasfondo:** Gil lleva 40 años fichando; si le despiden, Amparo pierde su tratamiento.
- **Fases:** (1) ayudar a Gil en su trabajo (comedia de oficina); (2) descubrir su secreto; (3) Ofelia le
  pide que te entregue; (4) él decide, y tú decides qué hacer con él.
- **Decisión:** perdonarle (le sacas del planeta con Amparo), entregarle a la resistencia (juicio) o
  usarle de agente doble contra Ofelia (peligroso para él).
- **Lazo:** el miedo hace traidores a los buenos.

**D. «Los barrios de antes»** (5 fases, ≈ 50 min; buceo y exploración)
- **Personajes:** **Profesor Nácar**, historiador clandestino; **Paz**, buceadora del Rastro.
- **Trasfondo:** antes de MegaVerso había pueblos; la empresa borró su historia.
- **Fases:** (1) bajar a los Aliviaderos (buceo urbano); (2) el primer pueblo bajo el agua; (3) la
  biblioteca inundada (puzle para secar libros); (4) robots de seguridad que vigilan la zona (sigilo
  submarino); (5) exponerlo en el Museo de la Luz (cambiar los carteles con hackeo).
- **Giro:** el señor sonriente de la Plaza del Primer Cliente fue el alcalde que vendió el planeta.
- **Final:** abre el **banco de reliquias** de Vértice.
- **Lazo:** un mundo sin memoria se vende fácil.

**E. «Carrera sin carril»** (4 fases, ≈ 40 min)
- **Personajes:** **Neón**, piloto de carreras ilegales; **Agente Línea**, de tráfico.
- **Fases:** (1) carreras ilegales por los carriles (con multas); (2) Neón te pide un favor: ganar a su
  rival; (3) la Agente os persigue en la gran carrera; (4) final entre rascacielos.
- **Giro:** la Agente era la antigua compañera de Neón.
- **Decisión:** dejar que Línea detenga a Neón (rep con la ley) o despistarla (Neón te da su lanzadera).
- **Final:** lanzadera propia y récord.

**F. «Huerto en la azotea»** (3 fases, ≈ 30 min; tranquila)
- **Personajes:** **Doña Clorofila**, jubilada que cultiva en secreto.
- **Fases:** (1) llevar tierra de otros planetas (comercio); (2) defender el huerto de una inspección
  (esconderlo); (3) cosecha y comida para el Parque Patrocinado.
- **Final:** negocio de huerto y receta de comida.
- **Lazo:** cultivar algo vivo en un planeta muerto.

**G. «La madre»** (4 fases, ≈ 40 min; emotiva)
- **Personajes:** **Rosa Cruz**, la madre; **Abril** y **Simón**.
- **Fases:** (1) Rosa te pide que juntes a sus hijos; (2) llevar mensajes entre ellos (cada uno con su
  orgullo); (3) una cena a escondidas en el Barrio Plantilla; (4) la seguridad llega a desalojar.
- **Decisión:** proteger la casa (combate) o sacar a Rosa por los tejados (huida).
- **Lazo:** antes de la revuelta, hay una familia.

#### 18. Eventos dinámicos de Vértice

| Evento | Qué pasa | Qué puedes hacer |
|---|---|---|
| **Oferta relámpago** | Un producto a mitad de precio 5 min | Comprar (y revender en otro planeta) |
| **Apagón** | Un barrio sin luz | Reparar (técnico) o proteger tiendas de saqueos |
| **Desalojo** | La seguridad desaloja una casa | Defender a la familia o mediar (abogado) |
| **Hora Punta** | Tráfico colapsado | Rutas alternativas, encargos con prisa (más paga) |
| **Huelga** | Un sector para | Unirte (rep resistencia) o trabajar (más paga, rep −) |

#### 19. Línea premium: «El último anuncio» (5 capítulos)

- **Idea:** el creador de los anuncios de MegaVerso, **Teo Jingle**, desapareció hace 10 años. Desde
  entonces, en algunos anuncios aparecen mensajes ocultos para quien los sepa leer.
- **Capítulos:** (1, gratis) descifrar el primer mensaje en un anuncio de la Avenida; (2) un mensaje lleva
  a los Aliviaderos; (3) otro a los Astilleros Orbitales; (4) Teo vive escondido en la Cúpula; (5) su
  último anuncio: la verdad de la estrella contada en un jingle.
- **Premios:** materiales de reliquia, receta de hackeo de reliquia (gratis también con rep 80 con la
  Resistencia), Chispas, lanzadera «Jingle» (aspecto), título «Contraanuncio».

#### 20. Horas de juego en Vértice (≈ 11 h)

| Actividad | Horas |
|---|---|
| Misión principal | 2 |
| Cadenas secundarias (7) | 5 |
| Trabajos | 1 |
| Comercio y economía (precios que cambian) | 1 |
| Exploración (niveles, Aliviaderos) y recolección | 1 |
| Fabricación y astillero (Astilleros Orbitales) | 0,5 |
| Ocio y eventos | 0,5 |
| Línea premium | (+1 h) |

---

## 4 · Cómo se hace una misión «de calidad»

El dueño quiere misiones **de juego grande**: con trasfondo, una historia muy entretenida, personajes que se
recuerdan y momentos que se cuentan a los amigos. Nada de «ve y trae 10 cosas». Este apartado es la
**norma** para todo el que escriba o programe misiones de la Saga 2.

### 4.1 · La lista de calidad (toda cadena la cumple antes de darse por buena)

| # | Requisito | Cómo se comprueba |
|---|---|---|
| 1 | **Personajes con motivo:** al menos 2 personajes con nombre, que quieren algo y esconden algo. | Ficha de personaje en la Biblia del planeta. |
| 2 | **Trasfondo:** la cadena cuenta algo del pasado del planeta o de sus personajes. | Una línea «Trasfondo» que no se pueda quitar sin que la cadena pierda sentido. |
| 3 | **Gancho en menos de 1 minuto:** algo raro, una persona en apuros o una pregunta. | Se mide jugando: del primer contacto a la primera pregunta, < 60 s. |
| 4 | **Lo que está en juego sube** en cada fase (de personal a todo el barrio, o del dinero a una vida). | Cada fase dice qué se pierde si fallas. |
| 5 | **Al menos 3 tipos de juego distintos** en la cadena (p. ej. investigar, sigilo y combate). | Tabla de fases con el tipo de cada una. |
| 6 | **Un giro** que cambie cómo ves a alguien. | Se puede escribir en una frase. |
| 7 | **Una decisión difícil**, sin respuesta «buena»: las dos opciones cuestan algo. | Cada opción tiene una consecuencia **visible** (en la cadena, en el episodio o en el mundo). |
| 8 | **Un momento estrella** (escena, vista, jefe, persecución) que se vea en un vídeo de 15 s. | Se puede describir como una imagen. |
| 9 | **Final que paga:** el jugador ve el resultado de lo que hizo (la ciudad cambia, alguien le espera, un objeto en la Sala de recuerdos). | Cambio en el mundo o en la Sala de recuerdos. |
| 10 | **Lazo con el Ragnarock** del planeta. | Una línea que lo diga. |
| 11 | **13+:** sin sangre, palabras de la lista permitida, muertes fuera de cámara. | Revisión con el apartado 0 de la Saga 2. |
| 12 | **Se puede fallar y seguir:** hay puntos de control y los fallos no hacen perder material. | Prueba de fallo en cada fase. |

### 4.2 · Plantillas de estructura

**A. Episodio (misión principal, 7 misiones, ≈ 2 h):** como una película corta.

| Misiones | Parte | Qué pasa |
|---|---|---|
| 1–2 | **Llegada** | Empieza en mitad del problema. Tutorial de la mecánica única y de la desventaja. Conoces al protagonista. |
| 3–4 | **Subida** | Descubres el plan del villano. Primeras decisiones. El peligro crece. |
| 5 | **El momento que duele** | El giro personal (traición, confesión, pérdida). |
| 6 | **Lo peor** | El villano actúa. Gran batalla o gran huida. |
| 7 | **Final** | Jefe, decisión del protagonista, **momento de silencio**, final agridulce, cambio del mundo. |

**B. Cadena secundaria (3–5 fases, 30–60 min):** gancho → investigación → complicación → giro → decisión
→ momento estrella → final. Cada fase dura 5–15 min.

**C. Encargo con historia (trabajos, 3–8 min):** un encargo normal de trabajo con un suceso y una pequeña
decisión (1 de cada 5 encargos).

**D. Evento dinámico (2–10 min):** aparece en el mundo, se avisa en el HUD (zona E), se puede ignorar; da
dinero, materiales o rep. No tiene historia larga pero sí una frase de contexto.

**E. Línea premium (5 capítulos, ≈ 1 h en total):** un misterio de la historia antigua del planeta, con un
personaje propio, un capítulo gratis y cuatro más; cada capítulo con su ubicación nueva y su tipo de juego.

### 4.3 · Variedad de objetivos (lo que se puede pedir al jugador)

| Tipo | Ejemplos | Sistema que se usa o se amplía |
|---|---|---|
| Combate a pie | Tiroteo con coberturas, defensa de un punto, jefe | `WeaponService`, `CombatAI`, `FighterService` (ampliados) |
| Combate en nave | Escolta, derribos, jefe naval, romper un bloqueo | `AirCombatService`, `EnemyAI`, `Waves` |
| Sigilo | Infiltración, seguir sin ser visto, robar | Nuevo: Sospecha, ruido, luz |
| Exploración | Llegar a un sitio difícil, encontrar algo con pistas | VISOR, `NavInfo`, puntos de interés |
| Escalada y planeo | Subir un tronco, bajar un glaciar | Nuevo: escalada; planeador |
| Buceo | Bajar a una profundidad, rescatar bajo el agua | `DivingService`, `Swim` (ampliados) |
| Carrera | Carrera armada, persecución, contrarreloj | `RaceService`, `KartService` |
| Defensa | Oleadas contra el Enjambre o naves | Nuevo: construcción de defensas + `Waves` |
| Diálogo e investigación | Interrogar (solo preguntas), convencer, descubrir al traidor | `DialogueService`, `Choice` |
| Puzle | Conductos de lava, compuertas, cristales de eco, engranajes | Nuevos minijuegos (`MiniGameService`) |
| Fabricación | Construir el deslizador, fabricar filtros para un pueblo | Fabricación (2.2), astillero (2.3) |
| Oficio | Trabajar de fundidor, farolero o abogado como disfraz | `JobService` |
| Rescate y escolta | Sacar a alguien con tiempo y peligro | Nuevo paso `Escort` |
| Supervivencia | Aguantar la hora roja, la ventisca o la niebla | Sistema de Entorno (2.7) |

**Regla de oro:** **nunca dos fases seguidas del mismo tipo** dentro de una cadena.

### 4.4 · Decisiones y consecuencias

- **Cuatro niveles de consecuencia** (cada decisión importante toca al menos dos):
  1. **Inmediata:** cambia la siguiente fase (más guardias, un aliado, un atajo).
  2. **En la cadena o el episodio:** cambia una misión posterior o el final (escena distinta).
  3. **En el mundo:** cambia el planeta (un barrio inundado, precios, una tienda nueva, un barrio nuevo)
     con `WorldMemoryService`.
  4. **En la reputación:** sube o baja la rep con un bando (tiendas, precios, misiones).
- **Sin respuesta correcta:** ninguna opción es «la buena»; las dos cuestan algo.
- **Se avisa:** las decisiones con consecuencias salen con un icono y el texto «Esto tendrá consecuencias».
- **Se recuerda:** las decisiones se guardan (`Choice` + `Flags`) y salen en un **diario del planeta**
  (la biografía de LifeStory ya existe: se le añade un apartado por planeta).
- **Los grandes finales son fijos** (el protagonista decide, no tú), pero **cómo** se llega y **lo que
  queda después** depende de ti (pregunta 5).

### 4.5 · Fallar sin frustrar

- **Puntos de control** al principio de cada fase.
- **Condiciones de fallo** claras (tiempo, te descubren, muere el escoltado, el medidor de la desventaja
  llega al máximo, la nave cae). Siempre se ve **por qué** fallaste.
- **Reintentar** desde el punto de control sin perder material ni dinero.
- **Fallos que siguen:** en algunas fases, fallar no reinicia sino que **cambia el camino** (si te
  descubren en el baile, la misión pasa a huida en vez de repetirse). Se marca en el diseño como
  «fallo con rama».
- **Ayudas:** tras 3 fallos seguidos, se ofrece bajar la dificultad de esa fase (más tiempo, menos
  enemigos) sin castigo.

### 4.6 · Recompensas

| Tipo de misión | Premio |
|---|---|
| Misión principal | Pieza de nave o habilidad de la historia, recetas, dinero, objeto de la Sala de recuerdos |
| Cadena secundaria | Dinero, materiales, una receta o un banco (reliquias), rep, a veces un vehículo o negocio |
| Encargo con historia | Paga del trabajo + un extra |
| Evento | Dinero, materiales, Chispas (con tope) |
| Línea premium | Materiales de reliquia, receta de reliquia, Chispas, aspecto y título |

**Nunca** «+100 XP» a secas: al acabar sale un **momento** (como ya hace LifeStory con `MomentKey`) y se
guarda en el diario del planeta.

### 4.7 · Cómo se escribe

- **Diálogos cortos** (una o dos frases por línea), con réplica rápida (Cosme y Pip por radio).
- **Escenas cortas** de 10–30 s entre fases (`Cinematics`, `CineCamera`, `SceneTiming`); las largas, al
  principio y al final del episodio.
- **Un momento de silencio por episodio** y por cadena emotiva: sin música ni chistes.
- **El protagonista es el del planeta;** tú ayudas. Tus decisiones y tus caras hablan.
- **Lista de palabras** del apartado 0.4 de la Saga 2. Los textos se escriben ya limpios.
- Todos los textos con claves (`Strings`), para traducirlos.

### 4.8 · Cómo se programa con el motor LifeStory (y qué hay que añadirle)

**Lo que ya existe y sirve tal cual** (`shared/LifeStory/Validate.luau`): misiones `Main` y `Side`,
pasos `Reach`, `Event`, `Talk`, `Choice`, `Scene`, `Use`, `MiniGame`, `Chase`, `Fight`, `Escape`, `Wait`,
`Group`, `Moment`, `Transition`, `Cinematic`; requisitos `If`; efectos `Flags`, `Rel`, `Items`, `Money`,
`World` (memoria del mundo), `Scene`, `Teleport`; ofertas de secundarias por sitio o evento (`Offer`);
`Cast` para los personajes; `Locations` para los sitios; `EventCatalog` para los avisos.

**Lo que hay que añadir:**

| Qué | Para qué | Dónde |
|---|---|---|
| Campo `Planet` en cada misión | Que la misión solo se ofrezca y avance en su planeta | `Quests`, `Validate` |
| Campo `Phases` (nombre de cada fase) y `Checkpoint = true` en pasos | Puntos de control y la tarjeta «Fase 2/4» en el HUD | `Sequencer`, `Validate`, HUD |
| Bloque `Fail = { Timer, Detected, EscortDown, Hazard, ShipDown }` y `OnFail = "Retry" \| { Goto = paso }` | Condiciones de fallo y fallos con rama | `Sequencer`, `Validate` |
| Pasos nuevos: `Fly` (llegar en nave), `ShipFight`, `Defend` (oleadas), `Stealth` (llegar sin pasar de X de Sospecha), `Dive` (llegar a una profundidad), `Climb`, `Race`, `Escort`, `Survive` (aguantar X min con la desventaja), `Craft` (fabricar algo concreto) | Los tipos de juego de 4.3 | `STEP_TYPES` de `Validate` y sus manejadores en el servidor |
| Minijuegos nuevos: `Soldar`, `Hackeo`, `Cerradura`, `Valvulas`, `Cables`, `Argumentos`, `Cocina`, `Ritmo` | Puzles y oficios | `MINIGAMES` + `MiniGameService` |
| Efectos nuevos: `Rep = { Bando = n }`, `Recipe`, `ShipPart`, `Unlock` (banco, barrio, negocio) | Consecuencias y premios | `EFFECTS` |
| Requisito `Premium = true` | Líneas premium (capítulo 1 sin él) | `Conditions` |
| Sitios con prefijo de planeta (`Tefra.Mirador`, `Siroco.Recta`…) y zonas por planeta | Ofertas y pasos `Reach` | `Locations` |
| Personajes de cada planeta con su aspecto «normal» | Diálogos y escenas | `Cast`, `ActorStaging` |
| Capítulos de la Saga 2 (`Saga2_Tefra`…) | Orden de los episodios (Tefra 1.º, Vértice 7.º) | `Chapters`, `MissionIndex` |
| Diario del planeta | Recordar decisiones | `Memories` / biografía |

**Eventos nuevos** para `EventCatalog` (cada uno con quien lo emite de verdad, como exige la prueba
`test-playthrough`): `PlanetLanded`, `ResourceGathered`, `ItemCrafted`, `ShipBuilt`, `ShipPartInstalled`,
`CargoDelivered`, `TradeSold`, `EnemyShipDowned`, `WaveSurvived`, `StealthSpotted`, `DepthReached`,
`HazardSurvived`, `RaceFinished`, `RescueDone`, `BountyCaught`, `RepChanged`, `PoiDiscovered`.

**Límites que se mantienen:** 3 secundarias a la vez (4 con premium, 2.8), una principal a la vez, las
ofertas se pueden rechazar sin castigo.

**Pruebas:** cada misión pasa `Validate` y la prueba de recorrido (`test-playthrough`) con los pasos
nuevos simulados; cada cadena tiene una prueba que recorre **todas sus ramas**.

---

## 5 · Plan de producción y límites de Roblox

### 5.1 · Orden de trabajo

**Primero lo común** (lo usan los 7 planetas), **luego planeta a planeta**. El juego tiene que seguir
jugable en cada paso.

| Fase | Qué | Esfuerzo aproximado |
|---|---|---|
| **A1** | **Marco de planetas:** convertir `Lontana.luau` en un sistema por datos (`PlanetSurface` + un archivo de datos por planeta), carga y descarga de regiones (5.3), capas (cielo, superficie, subsuelo, agua) | 4–5 semanas |
| **A2** | **Sistema de Entorno** (desventajas, medidor, contramedidas) | 2–3 semanas |
| **A3** | **Fabricación** (mochila de materiales, bancos, recetas, minijuegos, almacén) | 4–5 semanas |
| **A4** | **Astillero** (planos, ranuras, estadísticas en el servidor, `ShipModel` por piezas, hangar) | 6–8 semanas |
| **A5** | **Trabajos comunes** (Tablón de la Galaxia, 11 trabajos con su base, experiencia local) | 4 semanas |
| **A6** | **Economía** (precios por planeta, saturación, rutas, caja negra, noticias) | 2–3 semanas |
| **A7** | **Ampliaciones de LifeStory** (4.8) + diario del planeta | 4 semanas |
| **A8** | **Combate a pie a distancia** (enemigos que disparan, se cubren y caen; ya pedido en la Fase 0 de la Saga 2) | 5–6 semanas |
| **A9** | **Pase con ayudas** (`BoostService`, misiones premium, ventana de números) | 2 semanas |
| **B1** | **Tefra** (episodio 1, primera ciudad fuera de Valmar) | 12–14 semanas |
| **B2** | **Miasma** (aprovecha todo el combate aéreo) | 9–10 semanas |
| **B3** | **Siroco** (carreras armadas, Mar de Dunas) | 9–10 semanas |
| **B4** | **Nivalis** (sigilo) | 9–10 semanas |
| **B5** | **Umbría** (escalada, defensa por oleadas) | 10–11 semanas |
| **B6** | **Tálasa** (buceo profundo, terror; lo más nuevo, por eso tarde) | 11–12 semanas |
| **B7** | **Vértice** (ley, deuda, ciudad por niveles) | 10–11 semanas |

- Muchas fases A se pueden hacer a la vez si hay más de una persona. Con una sola sesión de trabajo cada
  vez, la parte común son unas **35–40 semanas** y los planetas **70–78 semanas**.
- **Recomendación:** publicar por partes: primero A1–A7 + Tefra (el juego ya tiene un planeta completo),
  luego un planeta cada 2–3 meses.
- Del 2 al 6 el jugador elige el orden; el orden de **producción** propuesto (Miasma, Siroco, Nivalis,
  Umbría, Tálasa) sigue la recomendación de la Saga 2 (empezar por el que aprovecha el combate aéreo y dejar
  el agua para el final del grupo).

### 5.2 · Tamaño de cada planeta (lo que hay que hacer)

| Contenido | Por planeta |
|---|---|
| Regiones (biomas) | 6 + la ciudad + la órbita |
| Barrios de la ciudad | 7–8 |
| Misiones principales | 7 (≈ 25–30 fases) |
| Cadenas secundarias | 7 (≈ 28 fases) |
| Línea premium | 5 capítulos |
| Eventos dinámicos | 5 |
| Trabajos propios | 4–5 (+ los 11 comunes con su toque) |
| Personajes con nombre | 20–30 |
| Criaturas y enemigos | 8 (2 jefes de cadena + 1 jefe de episodio) |
| Recetas nuevas | 20–30 |
| Piezas de nave nuevas | 5–8 |
| Vehículos locales | 3–4 |
| Ocio | 4–5 actividades |

### 5.3 · Los límites de Roblox y cómo no pasarse

**La decisión técnica de base** (`docs/planetas.md`): el juego publica **un solo place** y los planetas son
**zonas lejanas del mismo mundo**, con entrada sin pantalla de carga. Este documento lo mantiene, con estas
reglas para que quepa:

1. **Cada planeta se construye solo cuando hace falta y se borra cuando nadie lo usa.** Al acercarse el
   primer jugador (desde la órbita), el servidor construye la región poco a poco (como hoy Lontana); cuando
   se va el último, espera 5 minutos y la **desmonta** (terreno incluido: `Terrain:Clear` de esa región /
   `FillBlock` con aire). Lo que el jugador cambió (defensas, decisiones) está en los **datos**, no en las
   piezas: al volver a construir, sale igual.
2. **Presupuesto por planeta** (encima de Valmar, que ya tiene ≈ 415.000 piezas):

| Parte | Presupuesto |
|---|---|
| Ciudad (sin interiores) | 25.000–40.000 piezas |
| Regiones salvajes (piezas sobre el terreno) | 8.000–15.000 |
| Interiores (viviendas, tiendas, sitios de misión) | Se cargan **solo al entrar**, 300–1.500 cada uno |
| NPC con vida a la vez | 40–60 cerca de jugadores (con nivel de detalle, como `CrowdService`) |
| Enemigos a la vez | 20 a pie / 12 naves por jugador en combate |
| Efectos | Los topes de `FxBudget` (300–500 trozos en móvil) |
| Naves de jugadores | 150 piezas cada una, 1 por jugador |

3. **Streaming:** todo el planeta va por streaming (cada jugador solo recibe lo que tiene cerca). Los
   edificios grandes usan `MeshPart` y nivel de detalle para verse de lejos sin mandar todas sus piezas.
4. **Sitio en el mapa:** las superficies van en una cuadrícula lejos de Valmar (Lontana/Tefra ya está en
   X = −25.000, Z = 25.000; la arena de pruebas en 24.000, 24.000). Propuesta: los 7 entre 20.000 y
   40.000 studs del centro (más lejos, la física empieza a temblar). Cada una de **4 × 4 km** (hoy 3 × 3).
5. **Alturas y profundidades:** las alturas del documento (árboles de 900 m, fosas de −600 m) son de
   **ficción**: en el juego se comprimen (1 m de historia ≈ 1 stud o menos), y cada superficie se coloca a
   una altura base que deje sitio para bajar sin llegar al límite donde Roblox destruye lo que cae
   (`FallenPartsDestroyHeight`).
6. **Terreno:** los materiales de terreno se comparten con Valmar; cada planeta usa los que Valmar no usa
   o `MaterialVariant` propios (como «LontanaRoca»), para no cambiar el aspecto de la ciudad.
7. **Memoria del servidor:** el peor caso es que haya jugadores en los 7 planetas a la vez en el mismo
   servidor. Con la carga y descarga, lo normal será 2–3 planetas construidos. **Se mide** con la consola
   de desarrollador en cada planeta nuevo. **Plan B** si la memoria pasa del 70 %: un **place por planeta**,
   con el viaje disfrazado de entrada en la atmósfera (pantalla de carga propia con las nubes,
   `TeleportService:SetTeleportGui`) y los datos compartidos (misma experiencia). Ver pregunta 3.
8. **Guardado:** lo nuevo (materiales, planos de nave, rep por planeta, progreso de planetas y misiones,
   diario) ocupa unos pocos KB por jugador; muy por debajo del límite de los DataStore. Todo con valores
   por defecto para que las partidas viejas no pierdan nada.
9. **Red:** remotos con límite de frecuencia (como los que ya hay); el servidor decide todo lo que da
   dinero, materiales, daño o progreso.

### 5.4 · Riesgos

| Riesgo | Qué puede pasar | Cómo se evita |
|---|---|---|
| **Memoria del servidor** | Con muchos planetas abiertos, el servidor va lento o se cae. | Carga/descarga, presupuestos, medir; plan B de un place por planeta. |
| **Móviles** | Bajadas de rendimiento en ciudades grandes. | Streaming, nivel de detalle, presupuestos, probar en un móvil normal cada planeta. |
| **Demasiado contenido** | 7 planetas × 11 h es mucho trabajo. | Publicar por partes; la base común primero; cada planeta completo antes de empezar otro. |
| **Equilibrio del pase** | Que la ayuda premium se sienta injusta. | Números claros (2.8), modos igualados, topes por temporada, revisar datos de juego (telemetría del pase). |
| **Normas de Roblox** | Cambios en las reglas de monetización o de madurez. | Revisar antes de cada temporada; cuestionario de madurez real. |
| **Explotar la economía** | Duplicar dinero o materiales con el comercio. | Todo en el servidor, saturación, topes, registro de transacciones. |
| **Astillero** | Naves imposibles o que rompen el vuelo. | Ranuras, energía y peso en el servidor; `plausible` con los números del servidor. |
| **Calidad de las misiones** | Misiones aburridas por prisa. | La lista de 4.1 obligatoria; pruebas de cada rama. |
| **Nombres viejos** | Que salgan «Lontana» o «Redonda» en pantalla. | Búsqueda automática en los textos (prueba). |
| **Clasificación** | Toda la experiencia pasa a 13+. | Decisión del dueño (pregunta 8). |

### 5.5 · Cómo se prueba

- Con Lune (sin Studio), como el resto del proyecto: una prueba por sistema común
  (`test-crafting`, `test-shipyard`, `test-economy`, `test-environment`, `test-boosts`) y una por planeta
  (`test-planeta-<nombre>`: terreno, ciudad dentro del presupuesto, misiones válidas, todas las ramas).
- **A mano en Roblox** (Lune no dibuja): entrada en la atmósfera de cada planeta, rendimiento en el móvil,
  cada medidor de desventaja, cada jefe y cada evento.

---

## 6 · Preguntas para el dueño

1. **Nombres en el código:** ¿dejamos los nombres viejos por dentro (Lontana, Ocrea…) y solo cambia lo que
   se ve (recomendado: no se rompe nada), o lo renombramos todo?
2. **Pase con ayudas:** ¿empieza en la **Temporada 2** (recomendado: la Temporada 1 se vendió como «solo
   estética») o cambiamos ya la Temporada 1?
3. **Un solo place o uno por planeta:** ¿seguimos con un solo place (sin pantallas de carga, pero con riesgo
   de memoria) y pasamos a uno por planeta solo si hace falta?
4. **Líneas premium:** ¿te vale que el capítulo 1 de cada línea sea gratis y los otros 4 solo con pase?
5. **Decisiones:** ¿te vale que las decisiones del jugador cambien escenas, el mundo y los epílogos, pero que
   el gran final de cada episodio sea fijo?
6. **Compras sueltas:** además del pase, ¿quieres vender algo suelto con Robux (por ejemplo, ranuras de
   planos de nave o pinturas), o todo va en el pase?
7. **Orden de producción:** ¿te vale Tefra → Miasma → Siroco → Nivalis → Umbría → Tálasa → Vértice?
8. **Clasificación 13+:** si los planetas van en la misma experiencia que Valmar, **todo el juego** pasa a
   13+. ¿Lo aceptas?
9. **Embargos en Vértice:** ¿te parece bien que, con muchas multas sin pagar, la seguridad te quite objetos
   (que siempre se recuperan pagando)?
10. **Jugar en grupo:** ¿los planetas se hacen primero para un jugador (como dice la Saga 2) y los grupos de
    hasta 4 después?
