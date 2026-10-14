# Traspaso: mundo y sistemas

Ventana «mundo y sistemas», cerrada el 28-09-2026 para ahorrar créditos. Aquí va lo que se arregló,
lo que quedó pendiente y lo que quedó a medias. Todo lo de abajo está en `claude/roblox-game-d98vy8`.

## Arreglado (con pruebas en verde; NO verificado jugando en Roblox)

### Revisión general de fallos
- **Guardado y economía.** Dinero NaN desde remotos (negocios); `DataService.spend`/`addMoney` validan.
  Bloqueo de sesión liberado si sales mientras carga; sin volver a bloquear tras salir; reintentos al
  salir; `save` devuelve si de verdad escribió. «Vida nueva» conserva las viviendas. Vivienda vendida
  dos veces (`PropertyService.claim`). Invitados que se llevaban la comida de la nevera. Objetos
  perdidos al llenarse la mochila en negocios. NaN en inventario.
- **Interiores.** El ascensor tiraba al vacío a otros jugadores; el remoto del ascensor se podía usar
  desde cualquier sitio (y con NaN); azotea de la Torre sin bajada. Peatones, animales y ruido de la
  plaza dentro de edificios (lag en móvil). Minimapa en la sala del cielo. `SceneService.teleportTo`
  limpia `InteriorKey` al ir a la calle. Servicios que no preparaban a los primeros jugadores.
- **Crimen y justicia.** Patrulla fantasma tras detener. Salir antes de la condena. Morir buscado ya no
  borra las estrellas (al reaparecer te detienen). Juicio que dejaba anclado. Delitos tardíos en la
  cárcel. Buscados de servicio como policía. Robos en la cárcel. Aislamiento que se reiniciaba. NaN en
  veredictos. Absoluciones pagadas.
- **Trabajos y locales.** Personal que se pedía a sí mismo para cobrar (charcutería, café, cine).
  Recreativos NaN. Caña prestada duplicable. Cajas del súper, habitaciones del hotel y platos del
  camarero bloqueados. Barco de pesca, ruta de basura vacía, pedidos de noche, paciente en la camilla.
- **Vehículos.** Bus que echaba a sus pasajeros. Sacar vehículo en la cárcel, metido en paredes o
  repetido sin límite. Bajarse dentro de paredes o del coche. Coches teletransportados o volando.
  Viajes, metro y aseos sin levantar del asiento. Subidas sin querer. Coches abandonados.
- **Historia (fallos técnicos).** Elecciones perdidas; muerte y cárcel durante escenas; actores
  fantasma; efectos de diálogo repetidos al volver a entrar; cinemáticas debajo de diálogos; clases
  que se pisaban; errores que bloqueaban la historia.
- **Muerte.** Se puede morir (rematar a alguien K.O. = homicidio, 3 estrellas); pantalla HAS MUERTO;
  reaparecer en el hospital más cercano con factura; los presos reaparecen en su celda.
- **Personajes de las misiones.** Pathfinding con fundido si no llegan, giros suaves, sin deslizarse,
  velocidad de andar según escala, reintento si cargan tarde, gestos nuevos, reposo con variedad,
  sentarse con `UsePose`.
- **Cámara y cinemáticas.** Controles contados (`Controls.luau`), cámara que vuelve a su sitio
  (`CineCamera.luau`), sin atravesar paredes, mapa cargado antes de empezar, una sola voz, textos del
  móvil, sin nombres flotando, CoreGui restaurado uno a uno.
- **Móvil.** Los carteles de acción se activaban solos al arrastrar la cámara o el joystick
  (`Prompts.luau`: ahora solo cuenta un toque corto sin arrastrar).
- **Mundo.** Peatones que atravesaban el mobiliario (`shared/Sidewalk.luau`, `World/Ambient.obstacles`,
  `Ambient.updatePeds`). Horarios coherentes (`shared/OpeningHours.luau`: tiendas, gasolinera 24 h,
  hospital 24/7, lugares y parques). Dependientes y pasajeros del metro flotando (`Npc.feetAt`).
  Mercadillo que saturaba a todos. Personal de `StaffService` que desaparecía de golpe (ahora se
  despide y se va). Peatones que desaparecían a la vista. Órdenes de andar que se pisaban. Pasajeros
  del metro que suben al tren. Fugas de memoria por jugador.

### Último bloque (hecho por un ayudante detenido para el traspaso; compila, test-gameplay y test-clientboot en verde)
1. **(MEDIO) Cajeros de café, cine, restaurante y súper que desaparecían de golpe al cerrar** —
   `StaffService` (retirada reutilizable), `CafeService`, `CinemaService`, `RestaurantService`,
   `SupermarketService`, con comprobaciones nuevas en `scripts/test-gameplay.luau`. **Revisar:** el
   ayudante se detuvo antes de dar su informe; conviene comprobar que ningún pedido, cola o sesión se
   queda colgado cuando el personal se retira.
2. **(BAJO) Sirenas de policía y bomberos sin límite** — `PoliceService`, `FireService`.
3. **(BAJO) Bocadillos mandados a todos los jugadores** — `Npc.say` solo manda a quien está a menos
   de `Npc.SPEECH_RANGE` (120), y el «ya no habla» también a quien oyó la frase anterior.
4. **(ALTO) Dependiente de la armería flotando** — `WeaponService` (una línea, con `Npc.feetAt`).

## Pendiente
- **(MEDIO) Peatones a altura fija (1.0).** En los puentes elevados no siguen el tablero. Idea: guardar
  la altura por tramo de acera al arrancar el servidor (`World/Ambient`) y usarla en
  `Ambient.updatePeds`, sin rayos por fotograma en el móvil. Sin empezar.
- **DialogueUI por conectar** (lo rehace la ventana principal): ver
  `docs/diseno/integrar-dialogo-camara.md` (cierre al morir, cámara que vuelve, paredes, tocar para
  seguir en móvil, gestos por frase, `DialogueService.cancel` al morir en el servidor).
- **Tiempo de cinemática:** `CinematicService.play` devuelve un tope (hasta 2,5 s de control libre al
  acabar); lo exacto sería un aviso del cliente al empezar y acabar. Nada impide dos cinemáticas a la vez.
- **Bocadillos de la calle durante cinemáticas:** haría falta un gancho para silenciarlos en
  `UI/SpeechBubbles.luau`.
- **test-lifestory:** 8 fallos en misiones de la sesión de historia (Gatonia/cucarachas, Deberes
  clónicos, Tirachinas, Saga 5 y 6, «la aguja cose el cielo»); ya fallaban sin los cambios de esta
  ventana. «Hecha una, su marca desaparece…» y «deuda galáctica» fallan a veces (dependen de tiempos).

## Pedido por el dueño y aún no hecho
- Confirmar con el dueño los horarios cambiados: Farmacia 9–22, Heladería 11–23:30, Panadería
  7:30–21, Frutería 8:30–21, Supermercado 9–22, Dependientes del centro comercial 10–22.
- **NO PUEDO VERIFICAR (hace falta jugar en Roblox):** cómo se ven esquives, despedidas del personal y
  pasajeros del metro; que los dependientes quedan en el suelo real; el tiempo de arranque del
  servidor con la lista de obstáculos de las aceras; los carteles del móvil que ya no se activan solos;
  la cámara y los gestos nuevos de los personajes.
