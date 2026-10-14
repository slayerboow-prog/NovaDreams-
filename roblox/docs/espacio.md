# El espacio encima de Valmar

Valmar sigue siendo el juego entero: **quien quiera quedarse a vivir en Valmar puede hacerlo**; nada de
la ciudad pide ir al espacio. El espacio es opcional y está **encima de la ciudad**, en el mismo lugar
del juego (el proyecto publica un solo place; no hay teletransporte entre places todavía).

Para subir a la nave hay que haber **terminado la Saga 1** («History of Valmar», misión
`Saga_24_Final`). Los testers no lo necesitan. A los demás, el puerto les deja mirar y les dice, con un
aviso amable, que la nave abre al terminar la Saga 1.

## Capas de altura

| Altura (studs) | Capa | Qué hay |
|---|---|---|
| 0 – 1400 | **Cielo de los aviones** | Aeroclub, avionetas y combate aéreo con aviones sobre la ciudad (`Flight.Bounds.Ceiling` = 1400; AviationService corta en 1700). |
| 1400 – 1800 | Reserva | Sigue siendo de los aviones: nada del espacio. |
| 1800 – 3400 | **Transición** | El cielo se oscurece poco a poco y salen las estrellas. A los **2800** la nave pasa a modo espacio (sin gravedad). |
| 3400 – 9000 | **Espacio** | Negro con estrellas: estaciones, asteroides, patrullas enemigas (solo desde **3700**) y los 7 planetas al fondo. A los 9000, techo: la nave vuelve sola. |

- En planta, el espacio es la columna de **±7000 studs** alrededor de Valmar (14 000 de lado; la ciudad
  y el aeroclub acaban en ±5600).
- Las naves **cruzan** el cielo de los aviones, pero ahí no sale ningún enemigo ni hay nada del espacio
  que estorbe. Los aviones no pueden subir al espacio (su techo es 1400).
- Lejos del puerto espacial, la nave no baja de **260 studs** (vuelve a subir sola); junto al puerto
  se puede bajar para despegar y aterrizar.
- Todos los números están en `src/shared/Cosmos/Layers.luau`.
- La arena de pruebas del combate aéreo (`docs/combate-aereo.md`) sigue aparte, en X = Z = 24 000, con
  sus botones del Modo pruebas de siempre.

## Cómo conseguir una nave

1. Ve al **portal de la playa** del Distrito Oeste (en el mapa: 🌀 «Portal al puerto espacial»), en la
   costa que mira al islote, y toca «Ir al puerto espacial». (El servidor busca, al arrancar, el primer
   sitio libre de verdad de la playa: suelo de arena o hierba y nada encima.)
2. Llegas al **Puerto espacial de Valmar** (🚀 en el mapa), en el **islote** de la costa oeste: pista
   redonda, torre de control y una nave de exposición.
3. En la nave: **«Subir a la nave»**. Despegas hacia arriba y hacia el mar; sube y sube libremente.

## Volver a Valmar (siempre)

- **VALMAR** en la nave (botón del móvil, tecla **V**, mando **Y**): pregunta «¿Volver a Valmar?» y, con
  un fundido rápido, apareces en el puerto espacial. Funciona en cualquier sitio y a cualquier altura.
- **Aterrizar** (el botón Salir de la nave, tecla **B**, mando **B**): por debajo de **900 studs**
  (unos 250 m) te bajas en el suelo de debajo (si hay sitio libre en tierra) o, junto al puerto, en el
  puerto. Más alto, te avisa de que bajes o uses VALMAR.
- **Portal «Volver a Valmar»** dentro de cada estación.
- **Desconectarse en el espacio:** al volver apareces en el puerto espacial (PositionService: atributos
  `AirArenaReturn` en la nave y `SpaceReturn` en las estaciones, y por si acaso cualquier sitio en lo
  alto del cielo de Valmar).

## Portales

| Dónde | A dónde |
|---|---|
| Playa del Distrito Oeste | Puerto espacial (todo el mundo) |
| Puerto espacial | Playa de Valmar (todo el mundo) |
| Puerto espacial | Estación Alba (con la Saga 1 terminada) |
| Cada estación | Puerto espacial («Volver a Valmar») |

## Lo que hay en el espacio

### Estaciones (zonas seguras)

- **Estación Alba** (encima del oeste, a 4300) y **Estación Cénit** (encima del este, a 5600).
- Alrededor de cada una, **zona segura** (520 studs): no se dispara, los enemigos no te atacan ni
  entran, y no recibes daño.
- **Atracar:** acércate al **muelle** (el aro verde) y pulsa **ATRACAR** (tecla **F** o **G**, mando **X**, o
  Salir). Te bajas en el vestíbulo (suelo, paredes y techo de cristal).
- Dentro: **Tienda** (vender el mineral por dinero de Valmar, reparar el casco a $2 por punto,
  recargar misiles a $15 cada uno), **Tablón de misiones**, **Hangar** («Subir a la nave», sales por el
  muelle) y el **portal «Volver a Valmar»**.

### Asteroides y minería

- Tres campos: el **Cinturón de Hierro** (tranquilo, junto a Alba), el **Campo Brasa** y la **Nube
  Escarcha** (más cobalto y cristal… y patrullas).
- Dispara a un asteroide con el láser: cada **4 impactos** suelta una unidad de mineral a la **bodega**
  (máximo 40). Un asteroide grande da hasta 8; vacío se apaga y se rellena a los 2 minutos.
- Minerales: **Hierro estelar** ($12), **Cobalto azul** ($30, veta azul) y **Cristal solar** ($80 y
  ✨ 1 Chispa de estrella, veta dorada; raro).
- Lo decide el servidor: solo cuenta el láser del servidor que da en el asteroide; como mucho una
  unidad cada 0,5 s y 90 cada 10 minutos, desde menos de 1100 studs, con la bodega con sitio y fuera de
  las zonas seguras.

### Combate

- Patrullas enemigas (drones y cazas) solo en sus sectores: **Sector Brasa** (nivel 1, solo drones),
  **Ruta de los Saqueadores** (nivel 2) y **Sector Escarcha** (nivel 3). Fuera de ellos no sale nadie.
- Cada ~22 s, si cabe, llega una patrulla; con más nivel (y cuantos más derribos llevas, hasta +4),
  más enemigos y más duros. Si te alejas, desaparecen.
- Derribos: dron $15; caza $40 y ✨ 1 Chispa (como mucho 40 chispas por hora con derribos).
- Derribado: estallas y reapareces en el muelle de la estación más cercana con la nave nueva.

### Misiones secundarias (tablón de las estaciones)

Se repiten todas; como mucho 2 a la vez.

| Misión | Qué hay que hacer | Premio |
|---|---|---|
| Limpieza de drones | Derribar 6 drones | $300 · ✨ 3 |
| Duelo de cazas | Derribar 3 cazas | $500 · ✨ 5 |
| Pedido de mineral | Extraer 12 de mineral | $250 · ✨ 2 |
| Cristales solares | Extraer 3 cristales solares | $400 · ✨ 4 |
| Carga para Cénit | Llevar una carga de Alba a Cénit (atracando) | $450 · ✨ 4 |
| Carga para Alba | Llevar una carga de Cénit a Alba (atracando) | $450 · ✨ 4 |

Si te derriban con una carga, se pierde (vuelve al tablón). Una entrega no vale antes de 15 s
(no se puede llegar tan rápido).

### El cielo

- Con la altura, el cielo pasa del de Valmar al negro con estrellas (capa `SpaceSky` de DayLight).
- **Valmar desde arriba:** muy alto se ve la isla dibujada en grande (costa, mar y el centro gris).
  De cerca, la ciudad de verdad.

## Los 7 planetas: estrellas al fondo… y planetas de cerca

> **Ahora son planetas de verdad** (esferas enormes con su textura, nubes y atmósfera, fuera de la
> columna del espacio) y a **Lontana** se baja volando sin pantalla de carga: ver `docs/planetas.md`.
> De muy lejos (desde Valmar, de noche) siguen siendo estas estrellas, y la estrella se apaga cuando
> crece la esfera.

Al fondo del espacio brillan los **7 planetas de «Ragnarock»** (Saga 2), cada uno con su color y su
forma de brillar:

| Planeta | Color | Brillo |
|---|---|---|
| Lontana | ámbar | 4 rayos, titileo lento |
| Ocrea | naranja rojizo | 6 rayos que giran despacio, halo que late |
| Marena | turquesa | 8 rayos, destellos rápidos |
| Velaria | blanco hielo | 4 rayos en aspa, destellos fuertes |
| Fronda | esmeralda | 6 rayos, brillo suave |
| Zéfira | violeta | 8 rayos que giran rápido |
| Mercadia | dorado | 12 rayos y parpadeo doble (como un anuncio) |

- **Mira una estrella con el morro** un momento (o tócala): sale su nombre y el botón **VIAJAR**
  (tecla **F**). Lontana: VIAJAR te lleva a su órbita. Los demás: «Planeta X — próximamente (episodio N
  de «Ragnarock»)»; sin la Saga 1, el cerrojo.
- Desde Valmar, **de noche**, también se ven, pequeñitas y flojas.
- **Para los episodios futuros** (registro en `src/shared/Cosmos/Planets.luau`): el servidor del
  episodio llama a `SpaceService.registerPlanet("Lontana", { Travel = function(jugador) … end,
  Available = function(jugador) return true end })`. Con eso, VIAJAR hace un fundido y llama a
  `Travel`. Orden de la saga: Lontana primero; Ocrea, Marena, Velaria, Fronda y Zéfira tras Lontana (en
  el orden que se quiera); Mercadia la última. Los episodios terminados se apuntan en
  `data.Space.Planets` (`{ Lontana = os.time() }`).

## Moneda y guardado

- **Dinero de Valmar** (vender mineral, derribos, misiones) y **✨ Chispas de estrella**
  (`data.Space.Chispas`: cristales, cazas y misiones; para mejorar la nave en la Saga 2).
- `data.Space` (DataService, con valores por defecto: las partidas viejas lo reciben solas): `Chispas`,
  `Ore` (bodega), `Missions`, `Mined`, `Kills`, `Done`, `Planets`.
- El casco y los misiles de la nave se acuerdan entre atracar y despegar (en memoria del servidor).

## Mandos

| | Móvil | Ordenador | Mando |
|---|---|---|---|
| Volar, disparar, misil, turbo, freno | como en `docs/combate-aereo.md` | | |
| Volver a Valmar | **VALMAR** | V | Y |
| Atracar / Viajar | **ATRACAR** / **VIAJAR** (sale solo cuando sirve) | F (o G) | X |
| Aterrizar | **Aterrizar** (el Salir de la nave) | B | B |
| Salto cuántico / hipervelocidad | ranuras 6 / 7 de la barra | X / 7 | Select / R3 |

> Espacio AAA (HUD por zonas, esquiva, hipervelocidad, salto cuántico, energía): ver
> `docs/espacio-aaa/diseno.md`.

En el móvil, VALMAR y ATRACAR/VIAJAR van encima de Aterrizar (`HudLayout.Fly`: `ValmarNave`,
`AccionNave`), miden ≥ 44 pt en 932x430 y 844x390 y no pisan nada (`scripts/test-space.luau`).

La nave es la **misma** que la de la arena (`shared/AirCombat/ShipModel`, «Caza»: cabina de cristal con el
piloto dentro, alas en delta, dos motores que brillan, luces de navegación y estelas) y la de exposición
del puerto espacial también. Se dirige igual: en el móvil, con la **palanca táctil** de la nave
(`UI/FlightStick`, arrastrar en la mitad izquierda) y, al volar, el HUD de Valmar que no sirve se esconde
(`UI/FlightFocus`). La nave va anclada y la mueve el cliente por CFrame; el servidor comprueba cada «Pose»
(ver `docs/combate-aereo.md`).

## Cómo probarlo

1. Entra como tester (Studio, el dueño o `Config.Testers`) y escribe **`/pruebas`**.
2. Sección **ESPACIO**:
   - **🚀 Ir al puerto espacial**: andando a la pista del islote («Subir a la nave», portales).
   - **🌌 Ir al espacio**: directamente en la nave, en el muelle de la Estación Alba.
   - **🛰️ A la Estación Alba**: andando al vestíbulo (tienda, tablón, hangar, portal).
   - **🏠 Volver a Valmar**: al puerto espacial, desde la nave o la estación.
   - **🪐 Ir a Lontana (órbita)** y **🛬 Aterrizar en Lontana**: los planetas (`docs/planetas.md`).
3. Para probar como jugador normal: un personaje sin la Saga 1 ve el aviso «La nave abre cuando
   termines la Saga 1…».

## Cómo está hecho

| Archivo | Qué hace |
|---|---|
| `src/shared/Cosmos/Layers.luau` | Las capas de altura y sus cuentas. |
| `src/shared/Cosmos/Access.luau` | El puerto espacial, los sitios de la playa y quién puede volar. |
| `src/shared/Cosmos/Zone.luau` | La geometría para la nave (misma forma que `AirCombat/Arena`): asteroides, sectores, choques, límites, zonas seguras. |
| `src/shared/Cosmos/Stations.luau` | Las estaciones, sus muelles y la tienda. |
| `src/shared/Cosmos/Mining.luau` | Minar y las comprobaciones contra trampas. |
| `src/shared/Cosmos/Missions.luau` | Las misiones secundarias. |
| `src/shared/Cosmos/Planets.luau` | Los 7 planetas (aspecto, estado, orden) y el registro de destinos. |
| `src/server/Services/SpaceService.luau` | Subir/bajar, portales, atracar, minar, patrullas, misiones, tienda, planetas. |
| `src/server/World/SpaceWorld.luau` | Las piezas: puerto, portales, estaciones y asteroides. |
| `src/server/Services/AirCombatService.luau` | La nave (opción `World = "Cosmos"`: vuelo libre, zonas seguras, evento `Rock`, `spawnEnemy`…). |
| `src/client/Controllers/SpaceClient.luau` | Cielo por altura, estrellas, Valmar desde arriba, los planetas, botones y menús. |
| `src/client/Controllers/AirCombatClient.luau` | La nave en el cliente (predicción con `Zone`). |

**Carga por zonas:** el puerto y el portal de la playa se hacen al arrancar (son pequeños); las
estaciones y los asteroides, la primera vez que alguien sube. Todo se carga por distancia
(StreamingTargetRadius 768): desde la ciudad nadie recibe nada del espacio (está a más de 3400 studs).
El bucle de patrullas solo va mientras alguien vuela encima de Valmar.

**Sonido:** los `Nave*` de `Config.Sounds` (control 🔔 Efectos, 3D). Ningún id nuevo.

## Límites conocidos

- Un solo jugador por sesión de nave (cada piloto, sus patrullas); varios jugadores pueden volar a la
  vez, pero no hay cooperativo todavía.
- Las naves no chocan con los edificios de Valmar (solo con el suelo, el mar y los asteroides); por eso
  lejos del puerto no bajan de 260 studs.
- Las estaciones apartan la nave, pero no son sólidas para ella.
- Los planetas aún no tienen episodio. A **Lontana** ya se puede bajar volando y explorar su superficie (`docs/planetas.md`); los otros seis dicen «próximamente».
- Las Chispas de estrella se ganan y se guardan, pero todavía no hay taller de mejoras de la nave.
- La isla vista desde arriba es un dibujo sencillo (costa, mar y centro), no la ciudad de verdad.

## Pruebas

```
lune run scripts/test-space.luau      # capas, despegue, acceso, zona, minar, misiones, estaciones, planetas, servidor y botones
lune run scripts/test-aircombat.luau
lune run scripts/test-compile.luau
lune run scripts/test-clientboot.luau
```
