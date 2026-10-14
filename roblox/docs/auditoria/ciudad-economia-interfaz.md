# Auditoría de beta tester: ciudad, economía e interfaz

Revisión de la parte de «vida en la ciudad» de Heroes of History (versión publicada: v117), hecha como
un beta tester pero sin abrir Roblox: se construye el mapa de verdad (`rojo build` + `scripts/build-place.luau`),
se pasan todas las pruebas de esta zona y se lee el código buscando lo que un jugador real se encontraría
(errores, trampas con el dinero, cosas que se quedan colgadas, el móvil…). Cada fallo arreglado tiene una
prueba que lo reproduce.

Las otras dos auditorías (vuelo, espacio, mar e invasión; historia, misiones y cinemáticas) van aparte.

## Qué se ha revisado

- **Ciudad y mapa**: TownBuilder, distritos, coherencia del mapa, calles, choques, peatones, tráfico,
  vida en la calle, pelos de los personajes.
- **Economía**: dinero, trabajos, negocios, tiendas, súper, mercadillo e intercambio, viviendas (compra,
  alquiler, regla de los menores), mudanza de claves de edificios, Hacienda, pase de temporada.
- **Necesidades** (hambre, energía, diversión), **ocio y zonas verdes** (parques, mercadillo y feria,
  karts, skate, vóley, deportes), **vehículos de tierra** (coches, bicis, patinetes, barcos, metro,
  Cercanías, autobús), **mascotas y adopción**, **tiempo, día y noche, grieta del cielo, sirenas, sonido**.
- **Interfaz en el móvil** (HUD, ValPhone, ajustes, mochila, mapa) a 932x430, 844x390 y 640x360,
  **arranque y guardado** (Boot, pantalla de carga, DataService, vigilante), **panel de pruebas** y
  **rendimiento** (piezas, bucles del servidor, presupuesto del móvil).

## Fallos encontrados

| # | Gravedad | Fallo | Cómo se reproduce | Arreglo | Prueba | Commit |
|---|---|---|---|---|---|---|
| 1 | Media | **Skatepark: puntos, experiencia y premio sin patinar.** El servidor volvía a contar los puntos, pero aceptaba giros y kickflips sueltos sin salto. | Un cliente trucado manda `Ocio:FireServer("Combo", { Tricks = 40 × { Id = "Giro540" } })` cada 0,3 s: 124 800 puntos por combo, el reto de trucos (40 €) ganado al momento y hasta 3 de experiencia cada 0,3 s (600 por minuto). | `SkateTricks.sanitize`: un kickflip y un giro como mucho por salto, y solo detrás de un salto con tiempo de aire (que gasta el tiempo pasado desde el combo anterior). `SkateService`: experiencia con tope por minuto (`SkateTricks.XpPerMinute`). | `test-ocio` (2c) | `3068267` |
| 2 | Baja | **`test-gameplay` fallaba a veces en la pistola** (la «comprobación de cadencia»). | Con el ordenador cargado, entre dos `Fire` seguidos de la prueba pasaban más de 0,15 s (la cadencia de la pistola) y el segundo disparo salía: fallaban «no se puede disparar más rápido que la cadencia», «pasada la pausa, sí» y «recarga táctica». Pasó en la primera de las 5 vueltas. | La prueba para el reloj de los servicios (`frozenClock`, un `os` propio para los módulos cargados) durante esos disparos. El juego no cambia. | `test-gameplay` | `7677adf` |
| 2b | Baja | **`test-gameplay` fallaba a veces al bajar del Cercanías** («…y apareces en el andén»). | Con 3 vueltas a la vez, el salto al andén (`RailService`, con `task.defer`) no llegaba en el único `task.wait()` de la prueba. | La prueba espera hasta 3 s a que llegue. El juego no cambia. | `test-gameplay` | `7677adf` |
| 3 | Media | **Mudanza de viviendas a medias: vivienda fantasma.** Con dos o más viviendas en edificios quitados por la revisión del mapa, si el DataStore fallaba con la segunda, la primera ya se había quedado en el registro de dueños a su nombre, pero su partida seguía con la clave vieja. | Al volver a entrar se mudaba OTRA vez a otra vivienda; la primera quedaba a su nombre para siempre sin estar en su lista (nadie la podía comprar y él no podía entrar). | `HousingService.migrateKeys`: si la mudanza se aplaza (fallo del DataStore o se va a mitad), suelta las viviendas nuevas que ya había cogido. | `test-gameplay` («Revisión del mapa: una mudanza a medias…») | `7677adf` |
| 4 | Baja | **Dinero devuelto que no salía en el HUD.** Al devolver lo pagado por una vivienda sin sustituto (revisión del mapa) o a un menor con alquiler de antes, el dinero se sumaba directamente a la partida. | El HUD y la tabla de jugadores seguían enseñando el dinero de antes hasta el siguiente cobro o gasto. | Tras devolverlo, `DataService.addMoney(player, 0)` pone al día el atributo y la tabla. | `test-gameplay` («vivienda sin sustituto…») | `7677adf` |
| 5 | Media | **Negocio perdido o repetido en la mudanza de locales.** `BusinessService.migratePremises` apuntaba el local nuevo en el índice, escribía el negocio sin mirar si se había guardado y daba de baja el viejo. Con varios servidores arrancando a la vez (al publicar) cada uno podía mudarlo a un sustituto distinto o devolver el dinero de uno ya mudado. | Si el DataStore fallaba al escribir el negocio en el local nuevo, el índice apuntaba a un local vacío y el viejo quedaba dado de baja: el dueño perdía el negocio (y lo pagado). | El índice cambia del local viejo al nuevo en una sola escritura (solo un servidor lo consigue); si no se puede guardar el negocio, el índice vuelve atrás y se reintenta en el próximo arranque; un fallo del DataStore ya no lleva a «devolver el dinero». El negocio mudado es una copia (sin DataStore, en Studio, `read` devolvía la misma tabla y al dar de baja el viejo el mudado quedaba «Free»). | `test-gameplay` («negocio de un local quitado…») | `7677adf` |
| 6 | Media | **«🏠 Ir a casa» en mal momento.** El botón del ValPhone se podía pulsar conduciendo, en mitad de una escena, de una conversación, del prólogo o muerto. | Con un piso: conduciendo no pasaba nada y no decía nada. Con la parcela: te bajaba del coche en marcha y lo dejaba en la calle. En una escena o conversación te sacaba de ella y la historia se quedaba esperando. | `HouseService.goHome`: no deja ir con `Dead`, `Fallen`, `InScene`, `InDialogue` o `InPrologue` («Ahora no puedes ir a casa») y, sentado, pide que te bajes primero. | `test-gameplay` (««Ir a casa» conduciendo…») | `7677adf` |

## Lo que se ha mirado y está bien

- **Remotos con dinero o cosas** (intercambio y mercadillo, negocios, súper, cafetería, restaurante,
  hotel, granja, mochila, mascotas, vehículos, Hacienda, pase de temporada, recreativos, minijuegos,
  gimnasio, vóley, carreras, karts, feria): validan números (NaN, infinitos, enormes), cantidades, la
  distancia, la edad, el dinero de pruebas infinito y tienen límite de peticiones. Las compras devuelven
  el dinero si algo falla a mitad.
- **Guardado**: bloqueo de sesión, reintentos, valores que el DataStore rechaza, tamaño (4 MB) y la
  pantalla de carga que espera a la partida (`test-persistence`, `test-serverboot`).
- **Alquiler y menores**: el alquiler solo corre mientras juegas y los menores no tienen alquileres ni
  deudas (`HousingService.fixMinor`).
- **Mapa**: 0 problemas críticos en `test-mapcoherence` (quedan 50 avisos de diseño: calles dobles,
  unos pocos sitios sin acceso en el Distrito Oeste; son de la revisión del mapa, no fallos de juego).
- **HUD en el móvil**: `test-hud` comprueba 640x360, 667x375, 844x390, 932x430 y tabletas sin solapes.
- **Textos**: sin faltas de ortografía en los textos de la interfaz buscados (tildes de «también»,
  «día», «más», «teléfono», «vehículo»…).

## Pruebas pasadas

Todas en verde con el mapa construido (`rojo build` + `build-place.luau`, 364 750 piezas):

`test-compile` (797 archivos), `test-clientboot`, `test-serverboot`, `test-persistence`, `test-economy`,
`test-properties`, `test-buildingkeys`, `test-mapcoherence`, `test-streets`, `test-collisions`,
`test-hud`, `test-metro`, `test-rail`, `test-bus`, `test-boats`, `test-zonasverdes`, `test-ocio`,
`test-adoption`, `test-pelos`, `test-weather`, `test-daylight`, `test-skyrift`, `test-audiomix`,
`test-sfx`, `test-battlepass`, `test-battlepassui`, `test-tester`, `test-gps`, `test-streetlife`,
`test-onboarding`, `test-graphicsprefs`, y además `test-animals`, `test-atletismo`, `test-voley`,
`test-raqueta`, `test-gym`, `test-carbodies`, `test-sportscars`, `test-tyres`, `test-wheels`,
`test-vehicleparts`, `test-ride`, `test-swim`, `test-parkour`, `test-cityassets`, `test-familyhome`,
`test-institutions`, `test-colegio`, `test-instituto`, `test-interiorprops`, `test-streetlook`,
`test-underground`, `test-wanted`, `test-damage`, `test-punch`, `test-actors`, `test-react`,
`test-motion`, `test-agemotion`, `test-joints`, `test-workanim`, `test-outfits`, `test-commands`,
`test-worldmemory`, `test-assetloader`, `test-usermaterials`, `test-combat`, `test-breakables`,
`test-weapons`, `test-shooter`, `test-citydetail`, `test-buildings3d`, `test-houselook`,
`test-interiors`, `test-interiorlook`, `test-props`, `test-objects`, `test-nature`,
`test-nature-assets`, `test-lights`, `test-graphics`, `test-textures`, `test-meshlibrary`,
`test-baloncesto`, `test-futbol`.

`test-gameplay` (el grande): pasado 5 veces seguidas y 3 a la vez con el ordenador muy cargado. Fallos
que salieron y su causa:

- Vuelta 1 de 5: la cadencia de la pistola (fallo 2 de la tabla: tiempo real entre dos disparos de la
  prueba). Arreglado.
- 3 a la vez: «…y apareces en el andén» (fallo 2b: el salto al andén llega un momento después).
  Arreglado.
- 3 a la vez, una vez: «la ola arrastra a quien está en la playa» (catástrofes del mar). Es de la zona
  de la otra auditoría (vuelo, espacio, mar e invasión); se les deja apuntado.
- La «comprobación de gente» que fallaba a veces: en estas 9 vueltas no ha salido. Se han revisado las
  de `CrowdService` (biblioteca, gasolinera, salas, oficina, andén del metro): son deterministas salvo
  «en la oficina hay gente sentada tecleando», que depende del azar (cada uno de los 4 sentados elige
  entre teclear, teclear o el móvil: fallaba ~1 de cada 80 veces; ahora la prueba lo intenta con hasta 5 oficinas nuevas). Las que dependían del tiempo real
  (pistola, Cercanías) eran la causa de los fallos «de vez en cuando» vistos aquí.

## Lo que hay que mirar jugando (no se puede comprobar sin Roblox)

1. **Skatepark de la Ribera**: los combos de verdad siguen contando igual (salto + kickflip + giro,
   grind) y el reto de trucos se puede ganar patinando.
2. **«🏠 Ir a casa» en el móvil**: a pie te lleva; conduciendo dice «Bájate primero…»; en una
   conversación o escena dice «Ahora no puedes ir a casa».
3. **Después de publicar**: si tenías una vivienda o un negocio en un edificio quitado por la revisión
   del mapa, sale el aviso «🏙️ Valmar se ha reordenado…» y el dinero del HUD cambia en el momento si te
   devuelven algo.
4. **Con varios servidores a la vez** (al publicar una versión): ningún negocio sale repetido en el mapa
   ni en «Mis negocios».
5. **En Studio sin DataStore**: un negocio de un local quitado se muda y sigue abierto.
6. En el móvil del dueño (932x430): que el HUD, el ValPhone, la mochila y el mapa grande no se pisan en
   la versión publicada (las pruebas lo comprueban con las medidas, pero no con la pantalla real).

## Lo que no se ha arreglado

- **Avisos del mapa** (`test-mapcoherence`: calles dobles, sitios sin acceso en el Distrito Oeste,
  2 manzanas demasiado llenas): son de la revisión del mapa y cambiarlos mueve claves de edificios
  (y partidas). Quedan para la próxima revisión del mapa.
- **Testers por nombre** (`Config.TesterNames`): el número de usuario es más seguro (un nombre se puede
  cambiar y otro lo podría coger); ya está apuntado en `Config.luau`.
