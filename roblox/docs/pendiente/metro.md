# Traspaso: metro funcional (ventana "Publicar versión (misiones locas + saga II-IV)")

## Qué pidió el dueño en esta ventana
1. Publicar el juego (hecho al principio: versiones 55 y 57).
2. Subir a GitHub lo más reciente y unir las ramas pendientes: `claude/novadreans-payment-system-fkfs76` (unida, carpeta `pagos/`), `main` (los sofás ya estaban, unión registrada) y `claude/hud-touchlayout-alternativa` (**no** unida: pisaba el HUD táctil nuevo).
3. Revisar si el "PROMPT MAESTRO — SISTEMA DE METRO SUBTERRÁNEO FUNCIONAL" estaba implementado y, como solo lo estaba a medias, **implementar lo que faltaba** y mandarlo a publicar.

## Qué se hizo (commit `0352803` y merges posteriores, ya en `claude/roblox-game-d98vy8`)
- **`src/shared/Metro.luau`**: `Metro.travelled` / `Metro.positionAt` (movimiento compartido servidor/cliente), `Metro.dwellAt` y `Metro.eta` con parada y descanso en cabecera por horario y velocidad del tren, `Metro.Schedule` / `Metro.scheduleAt` (punta, normal, reducida, nocturna), `Metro.Incidents`, `Metro.Passes` / `Metro.FreeJobs`, `Metro.route` (planificador con transbordos), `Metro.nearestStation`, `Metro.entrance`, `Metro.meters` / `Metro.duration`, textos de megafonía y `Metro.StationInfo` (distrito y lugares de cada estación; cubre los 6 distritos).
- **`src/server/Services/MetroService.luau`**:
  - Publica el estado de cada tren en `ReplicatedStorage.MetroState.<línea>` (`publish`).
  - Se viaja de pie: ya no sienta a la fuerza. Se puede cambiar de coche y se baja andando por la puerta (`carAt`, `checkPassengers` emite `RodeMetro`).
  - Viajeros NPC sentados (`spawnRider` / `refreshRiders`; los mueve el cliente con `MetroOffset`).
  - Horario según la hora del juego (`updateSchedule`), incidencias (`MetroService.startIncident`, `incidentTick`) y megafonía (`announce`, eventos `Announce` / `Doors`).
  - Abonos (`onBuyPass`, `MetroService.passOf`, en `data.Metro`), gratis de servicio y evento `MetroGate`. Los planos (`MetroMapSign`) abren el mapa.
- **`src/client/Controllers/MetroTrains.luau`** (nuevo): mueve los coches en cada pantalla desde `MetroState`, te lleva si vas de pie, mueve los NPC con su coche, megafonía con voz y subtítulo, sonidos y luces de noche (tag `MetroLamp`).
- **`src/client/Controllers/MetroMapUI.luau`** (nuevo) y **`MetroUI.luau`**:
  - Plano de la red con trenes en vivo, estación más cercana y "Cómo llegar" (GPS), y planificador por distrito y estación. Se abre desde la app 🚇 Metro, los planos de las estaciones y el botón "🗺️ Plano" del tren.
  - Panel del viaje con ✓ ● ○ y marcador que avanza, aviso de incidencias y abonos en la máquina de billetes.
- **`src/server/World/Kit/MetroKit.luau`**: pasos entre coches (fuelle y suelo), pantallas, publicidad, cámara, papeleras y SOS en el tren; salidas de emergencia en los andenes; planos con toda la red; lámparas con tag `MetroLamp`.
- **Historia**: `Misiones/Metro_Secundarias.luau` (`MetroS_PrimerDiaUni`, `MetroS_Cartera`, `MetroS_PrimerTrabajo`), lugares `MetroBoca` / `MetroCampus` / `MetroAndenLevante` / `MetroObjetosPerdidos`, evento `MetroGate` y 3 recuerdos.
- **Otros**: `Config.Sounds` (`MetroGong`, `MetroPuertas`, y `MetroTren` / `MetroFreno` / `MetroAnden` con ID 0) y `DataService` (`Metro = { PassKind, PassUntil }`).
- **Pruebas nuevas** en `scripts/test-gameplay.luau`: planificador, horarios, movimiento, ir de pie, bajar andando, incidencias, abonos, gratis de servicio y NPC.
- **Pasan:** `test-compile`, `test-gameplay`, `test-clientboot`, `test-hud`, `test-metro`, `test-lifestory` y `test-playthrough`.

## Qué quedó a medias
- **Sin publicar.** Se abrió la ventana `session_01CcywfroPWg9advw9pSd7gR` ("Publicar versión (metro funcional)") y se interrumpió al llegar este traspaso. Hay que archivarla o ignorarla; publica la ventana principal.
- **Sin probar en Roblox de verdad** (solo Lune). A revisar en Studio y en el móvil:
  - Que el coche lleve bien a quien va de pie (`MetroTrains.update`: raycast + delta del coche en PreRender y PreSimulation).
  - Que no haya tirones entre la posición que replica el servidor y la del cliente.
  - Que los NPC sentados vayan con su coche.
  - Que el plano (`MetroMapUI`) quepa en el móvil.

## Hecho después (segunda tanda)
- **Taquilla con persona** (`MetroAccess.hall`, tag `MetroTicketBooth` con `StaffSpot`): mostrador con cristal en el vestíbulo de cada boca. `MetroService.ambientTick` pone al taquillero/a (nombre con `NamedActor`) cuando hay alguien cerca y nunca a menos de 5 studs de un jugador; "Comprar billete" abre la misma compra que la máquina (`openTickets`, `nearTicketSeller` vale para máquinas y taquillas).
- **Policía en las incidencias de seguridad** (`spawnPolice` / `retirePolice` en `MetroService`): 1 o 2 agentes con el uniforme de la Policía bajan al andén por los tornos (o por las puntas si hay alguien allí), van a las puertas del coche de en medio, avisan y vigilan; al acabar la incidencia se vuelven andando y se van sin nadie delante (`StaffService.retireNpc`).
- **NPC del andén en los bancos**: algunos aparecen sentados y, de vez en cuando, uno que espera de pie se va a sentar a un banco libre (`freeBench`, `sitOnBench`); al llegar el tren se levantan antes de subir (`leaveBench`). Los viajeros del andén tampoco aparecen ya a menos de 5 studs de un jugador.
- **Viajeros que cambian de vagón** (`changeCar`): con el tren parado y tiempo de sobra, alguno se levanta, va por el pasillo y el paso entre coches al de al lado y se sienta (mientras anda no lo mueve el coche: `ChangingCar`).
- **Estaciones con personalidad** (`MetroKit.Themes` / `mural`): cada estación de calle tiene su azulejo, un mural en lo alto de la pared de enfrente (lema y dibujos del barrio), cartel en el vestíbulo con lo que hay cerca y el nombre con su letra y colores. Plaza Mayor sigue como estaba.
- **Pruebas**: `test-gameplay` (taquilla, bancos, cambio de vagón, policía) y `test-metro` (una taquilla por estación, murales y azulejos distintos).

## Qué falta del prompt
- **Más trenes por línea, una 3.ª línea y "cambio de andén":** cada línea tiene **una sola vía** (`MetroKit.station` / `tunnel`), así que con más trenes chocarían. Hace falta construir una segunda vía (andén central o dos andenes con paso) antes.
- **Ascensor real:** sigue teletransportando (`onEntrance` / `onExit`). No se hizo: el ascensor de la boca (en la calle) y el del vestíbulo de andenes no están uno encima del otro (hay decenas de studs de distancia en horizontal y 45–70 de alto), así que haría falta un pozo nuevo que atraviese la calle, el vestíbulo y el terreno, más su lógica (`World/Lift` + `LiftRide`). Mejor hacerlo aparte.
- **Sonidos:** poner IDs reales en `Config.Sounds.MetroTren`, `MetroFreno` y `MetroAnden`. La voz depende de `AudioTextToSpeech`; si no está, solo salen subtítulos.
- **Precios:** los abonos no dependen de ningún índice de la economía (no existe todavía).
- **A revisar en Studio:** que el taquillero/a quede bien detrás del mostrador en todas las bocas, que los sentados en los bancos no floten y que el paseo por el pasillo al cambiar de vagón se vea bien.
