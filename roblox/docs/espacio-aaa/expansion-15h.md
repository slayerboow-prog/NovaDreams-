# Heroes of History · Expansión espacial «El Mar de Retales» (15 horas)

Documento de diseño para que el dueño lo apruebe **antes de programar nada**. Encargo: el «súper prompt» del
14-11-2026 (expansión espacial AAA de 15 horas, sin repetir lo de los planetas).

Se apoya en lo que **ya existe** y está aprobado: el vuelo, el combate y el HUD del Espacio AAA
(`docs/espacio-aaa/diseno.md`), los trabajos, bandos, eventos y la historia de Varkun
(`docs/universo/diseno-espacio.md`). Nada de esto se sustituye: se amplía.

> **Aviso honesto sobre las horas.** Hoy cada planeta tiene 6 misiones (Tefra, 10), unos **30-40 minutos** de
> historia, no 15 horas. Las 15 horas del espacio de este documento son el objetivo de diseño. Para
> llegar de verdad hacen falta varias tandas de trabajo (§17). Cada tanda deja algo jugable y publicable.

---

## 0 · Qué existe ya (auditoría corta)

| Sistema | Dónde | Estado | Uso en la expansión |
|---|---|---|---|
| Vuelo (combate / crucero / exploración, esquiva, inercia, choques) | `shared/AirCombat/ShipFlight` | Funciona | Base de todas las clases de nave (§7) |
| Armas: cañones, láser, misiles, bengalas, sobrecarga, camuflaje, drones | `ShipWeapons`, `ShipCombat`, `ShipSystems` | Funciona | Se convierten en **módulos** con ranuras (§7) |
| Energía, hipervelocidad, salto cuántico | `ShipAbilities`, `Hyperspeed`, `QuantumJump` | Funciona | El salto abre los **sectores lejanos** (§3) |
| Escáner del modo exploración (descubre puntos → `data.Space.Found`) | `ShipSystems`, `NavInfo` | Funciona | Base de la **exploración** (§4.A) |
| Estaciones Alba y Cénit (tienda, taller, tablón, hangar, portal) | `Stations`, `SpaceService` | Funciona | Se hacen **estaciones vivas** (§10) |
| 3 campos de asteroides, 3 sectores con patrullas | `Zone`, `Asteroids`, `Mining` | Funciona | Sector «Cercanías» (§3) |
| Trabajos: transportista, cazarrecompensas, mercenario; rangos y reputación | `SpaceJobs`, `Mercenary`, `SpaceJobService` | Funciona | Se amplían (contrabando, ciencia, rescate) |
| Eventos globales por hora del servidor | `SpaceEvents` | Funciona (2 tipos) | Se amplía a **eventos dinámicos** (§11) |
| Mapa galáctico | `GalaxyMap`, `GalaxyMapUI` | Funciona | Enseña sectores, misterios y eventos |
| Historia: prólogo de Varkun (2 misiones) | `Varkun`, `VarkunService`, motor de historia | Funciona | Es el **inicio** de las 15 h (§12) |
| Actos I, II y III de Varkun, Estación Vigía, Puesto Saqueador, bandos Saqueadores / Instituto Nilda | `diseno-espacio.md` | Solo diseño, aprobado | Se integran en el plan de horas |
| Planos de naves alienígenas de la Invasión (`data.Space.Blueprints`) | `InvasionService` | Funciona | Se gastan en el **astillero** (§7) |
| Guardado: `data.Space` (Chispas, Ore, Missions, Found, Upgrades, Drones, Blueprints) y `Jobs` | `DataService` | Funciona | Se añaden campos con valor por defecto: nadie pierde nada |

**Límite técnico importante (descubierto el 14-11-2026):** Roblox dibuja una versión simplificada del terreno de
Valmar **a cualquier distancia**. Los sectores nuevos no pueden estar «al lado» de Valmar sin verse la isla
plana: van lejos (§16).

---

## 1 · Concepto general

**El espacio es la segunda gran aventura del juego.** Los planetas son historias de **personas en un mundo
que se acaba** (a pie, en ciudades). El espacio es la aventura del **piloto**: tu nave es tu casa, tu arma y
tu personaje. Lo que haces aquí no lo haces en los planetas:

| En los planetas | En el espacio (solo aquí) |
|---|---|
| Caminar, hablar, trabajos de ciudad, peligros del terreno | Pilotar, combatir naves, abordar pecios gigantes |
| Una crisis por planeta | Un **misterio que une el universo** (Varkun y los retales) |
| Progresas tú (nivel, dinero) | Progresa **tu nave** (clase, módulos, aspecto) |
| Mapas fijos | **Sectores que cambian** (anomalías, mareas de retales, eventos) |

**La idea central: los retales.** Varkun deshila universos que se acaban y sus restos (los **retales**)
quedan flotando cosidos al borde del Sistema Valmar. Cada retal es un **trozo de otro universo** con su luz,
su física y sus ruinas. Esto justifica dentro de la historia lo que pide el encargo:

- Que cada sector tenga **identidad visual propia**: cada uno es un mundo distinto.
- Que haya **naves y civilizaciones desaparecidas** para explorar, porque son sus restos.
- Que haya **anomalías**, porque las costuras entre retales están mal cosidas.
- Que la historia sea un **misterio**: ¿de dónde vienen? ¿Quién los cose? ¿Valmar es el siguiente?

---

## 2 · Nombre e identidad

- **Nombre:** **El Mar de Retales** (en el juego: «Más allá de Valmar · El Mar de Retales»).
- **Lema:** «Cada estrella que ves es un mundo que alguien deshiló.»
- **Identidad:** costura y luz. Los hilos de luz son el idioma visual de toda la expansión: rutas de salto
  como **puntadas** en el mapa, anomalías como **descosidos**, la nave de Varkun como **rueca**. Es el mismo
  tema que la Saga 1 (coser la Grieta), así todo el juego cuenta una sola historia.
- **Tono:** aventura luminosa con misterio (13+, sin sangre). Los enemigos de Varkun son **telas animadas**
  (Hilanderos): se pueden derribar sin que «muera nadie», como ya está aprobado.

---

## 3 · Mapa conceptual de sectores

Siete sectores en anillos. Se llega por **salto cuántico** a balizas que primero hay que **descubrir**.

| # | Sector | Anillo | Identidad visual | Qué se hace | Se abre |
|---|---|---|---|---|---|
| 1 | **Cercanías de Valmar** (lo que ya hay) | 0 | Valmar redonda, estaciones Alba y Cénit, Cinturón de Hierro | Aprender, minar, primeros contratos | Al terminar la Saga 1 |
| 2 | **La Ruta de los Saqueadores** (se amplía) | 1 | Chatarra, luces rojas, naves partidas | Piratas, contrabando, **Puesto Saqueador** oculto | Hora 1 |
| 3 | **Nube Escarcha** (se amplía) | 1 | Niebla azul de cristal, auroras | Ciencia, anomalías, **Estación Vigía** | Hora 2 |
| 4 | **El Cementerio de Ovilla** | 2 | Luna rota, restos de la guerra de Tefra flotando, polvo naranja | **Pecios gigantes** que se abordan | Hora 4 |
| 5 | **Los Bajíos de Luz** | 2 | Mar de nebulosa dorada; «peces» de luz que se mueven en bancos | La **Ballena de Hilo** (criatura gigante), carreras, rescates | Hora 6 |
| 6 | **El Retal Invertido** | 3 | Colores al revés, gravedad que cambia, el tiempo que va a saltos | Anomalías con reglas propias, puzles de vuelo | Hora 8 |
| 7 | **El Telar** (la base de Varkun) | 4 | Hilos negros tensos, oscuridad con una luz violeta en el centro | Batallas de flota, abordaje final | Hora 12 |

Además hay **sitios secretos** sin baliza: solo se encuentran con el escáner mejorado, siguiendo coordenadas
de registros o resolviendo un puzle (§4.A, §14).

---

## 4 · Actividades y mecánicas

Cada mecánica explica **qué aporta, cómo funciona, cómo se desbloquea y por qué es divertida**.

### A · Exploración (escáner y descubrimientos)

| Mecánica | Cómo funciona | Se desbloquea | Por qué es divertida |
|---|---|---|---|
| **Pulso del escáner** (existe) | Modo exploración: el pulso enseña señales en el radar | Ya está | Convertir el «¿qué hay ahí?» en una búsqueda |
| **Triangular señales** | Una señal débil sale como un arco en el HUD; al escanear desde 3 sitios, el arco se cierra en un punto | Hora 1 (sensor nivel 1) | Pequeño puzle espacial, nada de iconos regalados |
| **Fenómenos** | Púlsares, cometas, tormentas de iones y nubes de polvo con efectos reales (ver menos, recargar más escudo, ir más rápido en la cola del cometa) | Por sector | Cada viaje cambia según lo que encuentres |
| **Registros** (diario) | Cajas negras, grabaciones y cartas: cada uno cuenta un trozo del misterio y da **coordenadas** | Hora 2 | La historia se descubre explorando, no leyendo menús |
| **Sitios ocultos** | Necesitan equipo: escáner profundo (ver dentro del polvo), blindaje térmico (cerca de una estrella) y ancla gravitatoria (no ser arrastrado) | Horas 6-10 | Volver a un sitio con equipo nuevo y entrar donde antes no podías |
| **Cartografía** | Cada sector tiene un % explorado; al completarlo, el Instituto Nilda paga y da una pintura | Siempre | Meta clara para los exploradores |

### B · Combate

| Mecánica | Cómo funciona | Por qué es divertida |
|---|---|---|
| **Familias de enemigos** (ver §8) | Cada familia **se comporta distinto**: los piratas rodean, los Hilanderos tejen redes, los drones de Ovilla van en enjambre | Cada pelea pide otra forma de volar |
| **Naves grandes con puntos débiles** | Corbetas y fragatas con torretas y motores que se rompen por partes (como los reyes de la Invasión) | Elegir qué romper primero |
| **Persecuciones** | El objetivo huye por un campo de asteroides o una nebulosa; si lo pierdes del radar, hay que triangularlo | Tensión y uso del escenario |
| **Emboscadas** | Señal de socorro falsa: al llegar, salen piratas del polvo | Desconfiar de las señales |
| **Jefes gigantes** | La Devanadera, el Huso, la Ballena de Hilo herida, el Acorazado Saqueador y la Rueca | Momentos que se recuerdan (§8) |
| **Batallas de flota** | Tu escuadrón de aliados NPC contra una flota: proteger la nave capital aliada, romper la enemiga | Escala épica, sentirse parte de algo grande |

### C · Pecios (naves abandonadas) — **sistema estrella 1**

Naves gigantes de otros universos flotando en los retales. **Se entra a pie** (como los interiores que ya usa
el juego).

- **Cómo funciona:** atracas la nave en una compuerta y te bajas con tu traje. Dentro hay pasillos con
  gravedad o sin ella, salas a oscuras (linterna) y puertas que se abren con energía. Tienes que **restaurar
  la corriente**, sortear peligros (fugas de aire, chispas, criaturas de hilo inofensivas que apagan las
  luces), leer registros y llegar al **núcleo** para coger su tecnología única.
- **Cada pecio es distinto:** un crucero de lujo hundido en polvo, un arca de semillas con un jardín vivo, una
  nave prisión, una nave de Hilanderos (sigilo), etc. Son **6 pecios de historia** hechos a mano, más **pecios
  generados** para después (§14), con salas montadas como piezas de Lego.
- **Recompensa:** cada pecio da un **módulo único** para la nave (§7), un registro clave y el aspecto de esa
  civilización como pintura.
- **Por qué es divertido:** cambia el ritmo (de pilotar a explorar a pie), da miedo suave y misterio y deja
  cosas que no se consiguen de otra forma.

### D · Batallas masivas — **sistema estrella 2**

- **Eventos de flota** cada hora en el Telar o en la Ruta: una flota enemiga ataca y todos los pilotos del
  servidor pueden unirse. Hay fases: romper la pantalla de cazas, desactivar los generadores de escudo de la
  nave capital y destruir su puente.
- **Contribución justa:** cada piloto suma puntos por lo que hace (derribos, escudos rotos, aliados
  reparados, cargueros salvados), no solo por dar el último golpe.
- **Jugable solo:** si estás solo, vienen **escoltas NPC** y la flota enemiga es más pequeña.

### E · Estaciones vivas — **sistema estrella 3** (§10)

### F · Anomalías — **sistema estrella 4**

Los **descosidos** entre retales. Cada anomalía cambia las reglas un rato:

| Anomalía | Qué cambia | Cómo se juega |
|---|---|---|
| **Bucle** | El tiempo se repite 30 s: tu «yo» de hace 30 s vuela a tu lado como un fantasma | Puzle: abrir dos puertas a la vez contigo mismo |
| **Espejo** | Los mandos se invierten y los enemigos son reflejos de tu nave | Combate raro y divertido |
| **Pozo** | Gravedad hacia un punto; la nave gira alrededor | Recoger restos en órbita sin caer |
| **Ventana** | Se ve un trozo de otro universo; si entras, sales en un sitio secreto | Atajos y secretos |
| **Marea de retales** (evento) | Un sector entero cambia de color y de física durante 10 min | El mapa no es siempre igual |

### G · Progresión de nave — **sistema estrella 5** (§7)

### H · Economía y fabricación (§9)

---

## 5 · Sistema de progresión

Cuatro barras que crecen a la vez y se cruzan (ninguna es solo «más números»):

1. **Rango de piloto** (1-30): sube con todo lo que haces en el espacio. Abre clases de nave, sectores y
   contratos. (Se apoya en los rangos de trabajos que ya existen.)
2. **Nave**: clase, módulos y nivel de cada módulo (§7). Abre sitios (escáner profundo, blindaje térmico,
   ancla).
3. **Reputación con los bandos** (§10): abre tiendas, pintura, misiones y aliados para la batalla final.
4. **Archivo de Nilda** (el misterio): registros encontrados. Abre coordenadas secretas y el final «coser».

**Regla de oro:** cada hora abre **algo nuevo que se ve**: un sector, una clase de nave, un sistema o un jefe.
Nunca «lo mismo pero con más vida».

---

## 6 · Planificación de las 15 horas

Historia principal = **actos de Varkun** (ya aprobados), con el jugador libre para desviarse siempre. Las
horas son de juego real contando desvíos.

| Hora | Bloque | Qué hace el jugador | Desbloquea | Enemigos | Recompensas | Momento especial |
|---|---|---|---|---|---|---|
| **1** | Prólogo (existe) | «La costura negra» y «Ruido en la Escarcha»; primer contrato | Escáner nivel 1, triangular señales | Agujas, piratas de nivel 1 | Primeras Chispas, sensor | La Rueca aparece al fondo y Varkun habla |
| **2** | Ciencia | Abrir la **Estación Vigía** con «La anomalía que canta»; primeros registros | Registros, cartografía | Drones de la Escarcha | Módulo «Lente de cristal» (radar en niebla) | La anomalía apaga tu HUD mientras canta |
| **3** | La Ruta | Cadena «Piratas de la Ruta» (5 misiones): seguir, infiltrarse y asaltar | **Puesto Saqueador**, contrabando, reputación cruzada | Saqueadores (rodean, emboscan) | **Clase Interceptor** | Persecución por el campo Brasa |
| **4** | Acto I · Ovilla | Viajar al **Cementerio de Ovilla**; **primer pecio** a pie («La nave hospital») | Pecios, traje, linterna | Drones-enjambre de Ovilla | Módulo único «Bisturí de plasma» | Restaurar la luz del pecio y ver la sala entera |
| **5** | Acto I · Convoy | «Convoy de Bastión»: escoltar refugiados de Tefra | Escuadrón de 1 aliado NPC | Saqueadores y Hilanderos | **Fabricador** en Alba (§9) | Llega el convoy y Alba se llena de NPC nuevos |
| **6** | Acto I · Jefe | **La Devanadera** (jefe) y «El mensaje» | **Clase Carguero pesado**, minería profunda | Devanadera + drones | Primer «hilo» del mapa de Nilda | Varkun habla por la radio de NILDA |
| **7** | Bajíos de Luz | Seguir a la **Ballena de Hilo**; rescates; carreras de aros | Ancla gravitatoria | Cazadores furtivos de ballenas | **Clase Explorador** | La ballena pasa por debajo, gigante |
| **8** | Acto II · Retal Invertido | Puzles de anomalías (Bucle, Espejo, Pozo) | Escáner profundo | Reflejos | Módulo «Paso de fase» (atravesar escudos 1 s) | Volar junto a tu propio fantasma |
| **9** | Acto II · Infiltración | **Telar Hilandero** a pie con sigilo: rescatar presos **o** robar el mapa (decisión) | Decisiones con consecuencias | Hilanderos guardia | Según la decisión: aliados o coordenadas | La decisión cambia la estación (§12) |
| **10** | Acto II · Alianza | **El Rey Engranaje** (OZ-0): alianza o pelea; segundo y tercer pecio | Clase de **nave alienígena** con los planos de la Invasión | Engranajes de OZ-0 | Astillero, pintura de raza | Tu primera nave alienígena |
| **11** | Acto II · Duelo | **Duelo en el Huso**: Varkun en persona; se retira al 50 % | Blindaje térmico | El Huso (fases de esquivar hilos) | Retal de su mundo (pista del final) | Varkun se quita la máscara un instante |
| **12** | Acto III · El Telar | Abrir el sector **El Telar**; batallas de flota | Flotas, contribución, escuadrón de 3 | Flota hilandera, corbetas | **Clase Fragata** (nave grande con torreta para un amigo) | La primera batalla de flota |
| **13** | Acto III · Aliados | «Llamada a los aliados»: misiones rápidas en cada sector para reunir apoyo | Aliados según reputación y decisiones | Mixtos | Aliados en la batalla final | Ver llegar a las naves de los planetas |
| **14** | Acto III · La Rueca | **Batalla de la Rueca** (3 fases) sobre Valmar | — | La Rueca | Pintura «Tejedor» | El cielo de Valmar lleno de naves |
| **15** | Final | **Abordaje** a pie y **cortar o coser** | Endgame (§14) | Varkun con armadura de dedales | Nave final «Aguja» (según el final) | El final cambia el cielo de Valmar para siempre |

Entre hora y hora siempre hay desvíos: contratos, minería, carreras, cartografía, pecios menores y eventos.

---

## 7 · Naves y mejoras

### Clases (cada una se pilota distinto, no son pinturas)

| Clase | Papel | Cómo se siente | Habilidad propia | Se consigue |
|---|---|---|---|---|
| **Caza** (la actual) | Todo terreno | Equilibrado | Esquiva doble | Al empezar |
| **Interceptor** | Velocidad y caza | Muy rápido, poco casco | Postcombustión: estela que daña | Hora 3 (Puesto Saqueador) |
| **Carguero pesado** | Comercio y minería | Lento, bodega enorme, mucho escudo | Rayo tractor (recoger restos y cargas) | Hora 6 |
| **Explorador** | Exploración | Ágil, sensores lejanos, poco ataque | Salto corto sin carga (dentro del sector) | Hora 7 |
| **Nave alienígena** (de los planos) | Especial | Según la raza (OZ-0 metálica, Ilyra de luz…) | Una por raza | Hora 10 (astillero) |
| **Fragata** | Cooperativo | Grande; un amigo maneja la torreta | Escudo de grupo | Hora 12 |
| **Aguja** | Final | La mejor en todo, con estela de hilo | Coser: repara aliados con un hilo de luz | Hora 15 |

### Módulos (ranuras y energía)

Cada clase tiene **ranuras** (arma principal, arma secundaria, defensa, motor, sensor y especial) y una
**potencia** máxima: no cabe todo, hay que elegir. Esto convierte las mejoras actuales (blindaje, baterías y
bengalas del taller, drones) en módulos, **sin perder lo comprado** (se convierte solo).

- **Armas:** cañones (existe), láser (existe), misiles (existe), escopeta de iones (de cerca), lanza de
  plasma (cargada) y minas.
- **Defensa:** blindaje (existe), escudo de burbuja, escudo frontal (aguanta mucho pero solo por delante),
  bengalas (existe).
- **Motor:** impulsor, motor de crucero y propulsor de esquiva.
- **Sensores:** radar, escáner profundo y lente de cristal.
- **Especial:** camuflaje (existe), dron (existe), rayo tractor, ancla gravitatoria, paso de fase y los
  **módulos únicos** de los pecios.

Cada módulo tiene 5 niveles. Se mejora en el **taller** (existe) con dinero, Chispas y **materiales** (§9).
**Nada se vende por Robux que dé ventaja:** solo pinturas y estelas, como ya está decidido.

### Aspecto

Pinturas, calcomanías, color de estela y de motores, luces del casco y el emblema del bando. Muchas se
consiguen **solo jugando** (cartografía, pecios, jefes).

---

## 8 · Combate

### Familias de enemigos (cada una con su forma de pelear)

| Familia | Dónde | Comportamiento | Cómo se gana |
|---|---|---|---|
| **Piratas Saqueadores** | Ruta | Rodean, huyen al estar dañados y llaman refuerzos | Cortarles la huida, priorizar al que llama |
| **Agujas Hilanderas** (existen) | Por todas partes | Pinchan y pasan de largo, en línea recta | Esquivar a tiempo y disparar al pasar |
| **Tejedoras** | Telar | Tienden **redes de hilo** que frenan tu nave | Romper los nudos antes de entrar |
| **Enjambre de Ovilla** | Cementerio | Muchos drones pequeños | Armas de área (escopeta de iones, minas) |
| **Reflejos** | Retal Invertido | Copian tu nave y tus armas | Usar el escenario: no se pueden copiar las anomalías |
| **Corbetas y fragatas** | Telar, Ruta | Torretas que se rompen y motores con punto débil | Romper por partes |

### Jefes

| Jefe | Fases | Lo memorable |
|---|---|---|
| **La Devanadera** | Romper 3 bobinas → núcleo al descubierto → oleada final | Hilos que tiran de tu nave hacia ella |
| **El Acorazado Saqueador** | Escudos → hangares → puente | Un asalto en grupo con piratas lanzándose de los hangares |
| **La Ballena de Hilo herida** (no se mata: se **salva**) | Cortar los arpones de los furtivos → coserle las heridas con el rayo → guiarla fuera | Un jefe que se gana sin destruir |
| **El Huso** (Varkun) | Esquivar telarañas → duelo → se retira al 50 % | Varkun en persona |
| **La Rueca** (final) | Cortar los hilos del anillo → corazón con oleadas → a pie contra Varkun | La batalla más grande del juego |

**La dificultad sube con el rango y el sector, no con más vida:** enemigos con más tácticas, más tipos mezclados
y menos tiempo para reaccionar.

---

## 9 · Economía y fabricación

**Problema que se evita:** acumular monedas sin uso. Cada recurso tiene **un destino claro**.

| Recurso | Cómo se consigue | Para qué sirve |
|---|---|---|
| **Dinero de Valmar** (existe) | Contratos, vender minerales | Comprar, reparar, combustible del salto |
| **Chispas** ✨ (existe) | Combate, eventos | Mejoras y desbloqueos del taller |
| **Minerales** (existen: hierro, cobalto, cristal…) | Minería | Fabricar módulos |
| **Hilo negro** (nuevo, raro) | Hilanderos, el Telar | Módulos de hilo y el final |
| **Componentes** (nuevo) | Pecios, chatarra | Fabricar y mejorar módulos de nivel 3 a 5 |
| **Datos** (nuevo) | Escanear, registros y cartografía | Investigar en la Vigía (desbloquear recetas) |
| **Planos** (existen: los de la Invasión) | Invasiones de la Grieta | Naves alienígenas en el astillero |

- **Fabricador** (Alba, hora 5): recetas = módulos y consumibles (munición especial, kits de reparación).
- **Investigación** (Vigía): gastar Datos para aprender recetas, en un árbol pequeño de 3 ramas (combate,
  exploración y comercio).
- **Mercado con precios vivos:** cada estación compra caro lo que le falta. Los eventos cambian los precios
  (el convoy que llega abarata Alba y el bloqueo pirata encarece Cénit). Comerciar entre estaciones es un
  juego en sí, pero con topes por hora para evitar granjas (como los contratos de ahora).
- **Sumideros:** reparaciones, combustible del salto lejano, mejoras caras de nivel 5, pinturas y comisión
  del mercado.

---

## 10 · Estaciones y bandos

| Estación | Bando | Qué tiene (nuevo en **negrita**) |
|---|---|---|
| **Alba** (existe) | Gremio Libre de Cargueros | Tienda, taller, tablón, hangar, portal · **Fabricador**, **mercado**, **NPC con historias** |
| **Cénit** (existe) | Vigilancia | Lo mismo · **armería de nave**, **celdas** (Varkun preso en el final «coser») |
| **Estación Vigía** | Instituto Nilda | **Investigación**, **cartografía**, **museo de registros** |
| **Puesto Saqueador** (oculto) | Saqueadores | **Mercado negro**, **contrabando**, **carreras ilegales** |
| **Faro de Ovilla** | Refugiados de Tefra | **Puerta de los pecios**, **astillero de chatarra** |
| **Campamento del Bajío** | Pescadores de luz | **Rescates**, **carreras**, **la ballena** |

**Estaciones vivas:**

- NPC que van y vienen, y pilotos NPC que atracan y despegan de verdad.
- Pantallas con los eventos del sector.
- Una sala de descanso donde los jugadores se ven a pie.
- Cada estación **cambia con la historia**: tras el convoy, Alba se llena de refugiados; tras el final
  «coser», Varkun está en Cénit.

**Reputación:** subir con un bando puede bajar con otro (contrabando sube Saqueadores y baja Vigilancia). La
reputación abre tiendas, pinturas, misiones y **quién viene a la batalla final**.

---

## 11 · Misiones y eventos dinámicos

**Tipos de misión:**

- Exploración, investigación, rescate y combate.
- Recolección, transporte e infiltración (a pie, en pecios y en el Telar).
- Caza de objetivos (existe), descubrimiento de tecnología, historia y operaciones especiales (en grupo).

**Eventos dinámicos** (amplían `SpaceEvents`; salen de la hora del servidor, todos ven lo mismo):

| Evento | Qué pasa | Si se gana | Si se pierde |
|---|---|---|---|
| **Invasión de flota** | Una flota ataca un sector | Botín y reputación para todos | El sector queda «ocupado» 1 h (precios y patrullas peores) |
| **Estación pide ayuda** | Una estación sufre un asalto | La estación da descuento 1 h | Tienda cerrada 15 min |
| **Anomalía desconocida** | Aparece un descosido con reglas raras | Datos y una pieza rara | — |
| **Señal antigua** | Registro de una civilización perdida en un sitio aleatorio | Un registro raro | — |
| **Paso de la Ballena** | La ballena cruza un sector con furtivos detrás | Pintura «Bajío» | — |
| **Convoy atacado** | Piratas contra cargueros NPC | Dinero por carguero salvado | — |
| **Marea de retales** | Un sector cambia de física y de color | Recursos únicos | — |
| **Tormenta solar** | Escudos a la mitad en todo el sistema | — | — |

También hay **eventos pequeños cerca de ti** (cápsulas a la deriva, emboscadas o un cometa) para que siempre
pase algo al volar.

---

## 12 · Historia y misterios

Base aprobada: **Varkun, el Deshilador**, y su nave-luna **la Rueca** (`diseno-espacio.md` §2). La expansión
añade el **misterio de los retales**, que se descubre jugando:

1. **¿Qué son los retales?** Los registros de los pecios cuentan cómo acabó cada mundo… y que en todos apareció
   «una luz en el cielo» antes del final (la lucecita de la Saga 1).
2. **¿Quién los cose?** Los retales no están sueltos: alguien los cose al borde de Valmar. No es Varkun. Es
   **la abuela Nilda**, hace años, con sus cálculos: así **escondía** mundos para que Varkun no los terminara.
3. **La gran revelación:** **Valmar es un retal**. Nilda cosió Valmar aquí para salvarla. Por eso no está
   registrada y por eso Varkun la busca («VALMAR · ORIGEN», el gancho que ya existe).

**Decisiones con consecuencias:**

- **Presos o mapa** (hora 9): con los presos, aliados en la batalla final; con el mapa, un sitio secreto y una
  ruta más corta al Telar.
- **OZ-0: alianza o pelea** (hora 10): con la alianza, nave alienígena y contramedidas; con la pelea, sus piezas
  y un jefe extra.
- **Cortar o coser** (hora 15; «coser» solo con la carta de Nilda, que está en un pecio secreto). Cambia el
  cielo de Valmar, las estaciones y el endgame.

Los **personajes** ya existen y se reutilizan: Cosme, Pip, NILDA y Varkun. Se añaden pocos: **Capitana Brea**
(Saqueadores, ambigua), **Doctora Ivo** (Vigía, científica) y **Moro** (refugiado de Tefra en el Faro).

---

## 13 · Multijugador

**En grupo (hasta 4):**

- Escuadrón: mismo grupo, radar compartido y recompensas compartidas.
- Fragata con torreta para un amigo.
- Pecios cooperativos (dos interruptores a la vez y uno vigila mientras el otro abre).
- Jefes y batallas de flota con contribución justa.
- Transporte en convoy (uno lleva la carga y los demás escoltan).

**Todo el servidor:** eventos de flota, defensa de estaciones, la ballena y las mareas de retales.

**Solo:** todo el contenido de historia se puede jugar solo. Vienen escoltas NPC y los jefes se ajustan al
número de pilotos. Nada obligatorio necesita a otra persona.

**Social sin presión:** clasificaciones (carreras, cartografía, contribución en flotas) y emblemas de bando.

---

## 14 · Endgame y rejugabilidad

- **Expediciones:** misiones generadas uniendo piezas (un sitio, un objetivo, una complicación y una
  recompensa). Por ejemplo: «pecio en el Bajío + recuperar núcleo + furtivos + módulo raro».
- **Sectores de dificultad alta** («Retal profundo»): los mismos sectores con modificadores semanales (sin
  escudo que se recargue, enemigos que se curan…).
- **Jefes especiales** semanales (versiones «furiosas»).
- **Pecios generados** con salas montadas como piezas: siempre hay uno nuevo.
- **Desafíos semanales** y **eventos de temporada** conectados al Pase de temporada que ya existe.
- **Coleccionables:** registros, pinturas de civilizaciones y mapas completos.
- **Secretos difíciles:** la carta de Nilda, el pecio que solo sale en la marea, la nave fantasma que se ve
  una vez por noche.
- **Final «coser»:** Varkun da **misiones de cartógrafo** para salvar mundos (contenido sin final).

Para que nada sea una obligación: recompensas semanales con tope pequeño, sin castigo por no entrar.

---

## 15 · Dirección artística y sonora

- **Cada sector, su paleta:**
  - Cercanías azul y blanco; la Ruta rojo y óxido; Escarcha cian.
  - Ovilla naranja y polvo; Bajíos dorado; Invertido magenta con verde; el Telar negro con violeta.
- **Cielo por sector:** skybox propio con nebulosa pintada, más capas de partículas cerca de la cámara (polvo,
  chispas, copos de cristal). Así parece volumétrico, como ya hacen los asteroides con `FxBudget`.
- **Planetas a varias distancias:** los 7 cuerpos de `PlanetBodies` (con su truco de tamaño en pantalla) y
  Valmar redonda.
- **Luz de cine:** cada sector con su `Lighting`/`Atmosphere`/color (ya lo hace `EnvZones` por zonas) y una
  estrella principal que marca las sombras.
- **Efectos:**
  - Motores con estela por clase, escudos que se iluminan donde reciben el golpe, explosiones en tres capas
    (destello, fuego y restos).
  - Hilos de luz para todo lo de Varkun y distorsión de imagen en anomalías y saltos (ya existe).
- **Naves:** cada clase con su silueta (como se hizo con el caza realista), mallas con LOD y un solo material
  por pieza grande.
- **Estaciones:** cada bando con su arquitectura (Gremio práctico y con grúas, Vigilancia blanca y militar,
  Saqueadores de chatarra, Vigía de cristal).
- **Sonido:**
  - Ambiente propio por sector (`Soundscapes` ya existe): zumbido de cristal en la Escarcha, metal que cruje
    en Ovilla, canto de ballena en el Bajío.
  - Música que sube en combate y radio con voces de NPC.
- **Móvil primero:** todo con niveles gráficos (Bajo, Medio y Alto, que ya existen) y topes de efectos.

### Imágenes de referencia del dueño

`referencia-expansion-1.png` y `referencia-expansion-2.png` (miniaturas del encargo). Lo que pide cada una:

| Sistema | Lo que se ve en la imagen | Cómo se lleva a Roblox |
|---|---|---|
| Pecios | Nave gigante, alargada y oscura, con una nave pequeña delante para dar escala | Pecio de 1-2 km hecho con pocas mallas grandes, luces de posición sueltas y nuestra nave al lado (la escala es lo que impresiona) |
| Batallas masivas | Nave capital en el centro, muchos disparos de colores cruzados, explosiones, nebulosa violeta | Estelas y rayos por `Beam`, explosiones en 3 capas, nebulosa en el cielo del sector; topes por `FxBudget` |
| Estaciones vivas | Hangar interior grande, iluminado, con pasarelas y naves aparcadas | Interior de estación con hangar visitable a pie, naves NPC aparcadas y luces cálidas |
| Anomalías | Remolino de luz (rosa, naranja y azul) en el espacio | Anillos de partículas que giran y distorsión de imagen al acercarse (como la del salto) |
| Progresión de naves | Hangar con muchas naves distintas en fila | El **astillero**: todas tus clases aparcadas y la que eliges en el centro |

---

## 16 · Arquitectura técnica para Roblox

**Principio:** igual que ahora. Un solo controlador mueve la nave (el cliente, anclada, `ShipFlight`) y el
**servidor decide** todo lo que cuenta (daño, botín, misiones). Cuentas puras en `shared/`, probadas con
lune fuera de Roblox.

| Pieza nueva | Tipo | Reutiliza |
|---|---|---|
| `shared/Cosmos/Sectors` | Cuentas: sectores, balizas, paleta, física y reglas | `Zone`, `EnvZones`, `NavInfo` |
| `shared/Cosmos/Anomalies` | Cuentas: reglas de cada anomalía | `ShipFlight` (modificadores) |
| `shared/AirCombat/ShipClasses` + `Modules` | Cuentas: clases, ranuras, potencia, niveles | `ShipCombat.Upgrades` (se convierten) |
| `shared/Cosmos/Crafting`, `Market` | Cuentas: recetas, precios vivos y topes | `SpaceJobs` (topes y semillas) |
| `shared/Cosmos/Derelicts` | Cuentas: pecios (salas como piezas, puertas, energía y núcleos) | Interiores del juego (`InteriorKey`) |
| `shared/Cosmos/Fleet` | Cuentas: batallas de flota, fases y contribución | `Waves`, `EnemyAI`, `Mercenary` |
| `SectorService`, `DerelictService`, `FleetService`, `CraftService` | Servidor | `AirCombatService.relocate`, `SpaceService` |
| Misiones de historia | Motor de historia (`LifeStory`), guiones desde `docs/historia/reescritura` | Como el prólogo de Varkun |
| Datos | `data.Space.Ship` (clase, módulos), `Mats`, `Logs`, `Rep` y `Choices`, con valores por defecto | `DataService` |

**Dónde van los sectores:** lejos de Valmar, en **bolsillos** del mismo servidor (como la arena de pruebas en
X = 24 000), con su cielo propio, y se viaja con el salto cuántico (`relocate`, sin cortar el vuelo). Los
pecios grandes pueden ir en salas flotantes como los interiores. Los **servidores reservados** quedan para
más adelante, si un contenido (por ejemplo el abordaje final) lo necesita.

---

## 17 · Plan de desarrollo por fases

Cada fase deja algo **jugable y publicable** y no empieza la siguiente sin que el dueño la vea.

| Fase | Contenido | Horas de juego que añade |
|---|---|---|
| **1 · Cimientos** | `Sectors` y bolsillos, salto a sectores, clases y módulos (con las mejoras de ahora convertidas), materiales | — (base) |
| **2 · Ciencia y Ruta** | Estación Vigía, registros, triangular, cadena de piratas, Puesto Saqueador, Interceptor | Horas 2-3 |
| **3 · Pecios** | Sistema de pecios a pie, Cementerio de Ovilla, Faro, 2 pecios de historia | Hora 4 |
| **4 · Acto I** | Convoy, Fabricador, Devanadera, Carguero | Horas 5-6 |
| **5 · Bajíos y anomalías** | Bajíos de Luz, ballena, Explorador, Retal Invertido, anomalías | Horas 7-8 |
| **6 · Acto II** | Infiltración, OZ-0, astillero alienígena, duelo del Huso | Horas 9-11 |
| **7 · Flotas** | El Telar, batallas de flota, Fragata, aliados | Horas 12-13 |
| **8 · Final** | La Rueca, abordaje, cortar o coser, la Aguja | Horas 14-15 |
| **9 · Endgame** | Expediciones, pecios generados, semanales y clasificaciones | Sin final |

---

## 18 · Riesgos técnicos y optimización

| Riesgo | Cómo se evita |
|---|---|
| **El terreno de Valmar se ve a cualquier distancia** (comprobado) | Bolsillos muy lejos y por encima; la Valmar grande tapa lo que quede a la vista |
| Muchas piezas en sectores (móvil) | Mallas con LOD, piezas solo del cliente para decorado, `FxBudget`, streaming por zonas |
| Pecios con miles de piezas | Salas como piezas que se cargan al entrar y se quitan al salir |
| Batallas de flota con muchos enemigos | Topes de enemigos vivos por servidor; las naves capitales son pocas piezas grandes; los disparos se calculan en el servidor por lotes |
| Red (replicación) | Los enemigos se mueven en el servidor con pocos datos; los efectos solo en el cliente |
| Trampas (dinero, botín) | Todo lo decide el servidor, con topes por hora y semillas como los contratos de ahora |
| Romper lo que ya funciona | Pruebas lune de cada sistema nuevo, solo las de los archivos tocados, y partidas viejas con valores por defecto |
| Tamaño del proyecto | Fases cortas, cada una aprobada antes de la siguiente |

---

## Lo que necesito que el dueño decida

1. **Nombre:** ¿«El Mar de Retales» te gusta?
2. **La revelación** «Valmar es un retal que cosió la abuela Nilda»: ¿sí? Encaja con «VALMAR · ORIGEN».
3. **Pecios a pie:** ¿sí? (es lo más trabajoso y lo más diferente).
4. **Orden:** ¿empezamos por la **Fase 1 (cimientos)** y luego la **Fase 3 (pecios)**, o prefieres otro orden?
