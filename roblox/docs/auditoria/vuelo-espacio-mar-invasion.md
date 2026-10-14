# Auditoría de beta tester: aviones, espacio, mar hondo e invasión

Fecha: octubre de 2026 · versión de partida: v117 (commit `eb11d60`).

Zona revisada: los sistemas más nuevos y menos probados.

- **Aviones:** `Shared/Flight`, `Controllers/Flying`, `Services/AviationService`, `PlaneHudClient`.
- **Nave y espacio:** `AirCombat*`, `Cosmos/*`, `SpaceService`, `ShipSystems`, el HUD de la nave, `HudArt`, la nave HX-7, el planeta Tefra, el salto cuántico, la hipervelocidad, los drones y el taller.
- **Mar hondo:** `OceanBuilder`, `OceanService`, `DivingService`, el HUD de buceo, el megalodón y el kraken.
- **Invasión de la Grieta:** `Shared/Invasion/*`, `InvasionService`, `InvasionClient` e `InvasionHud`.

## Cómo se ha probado

1. Se construyó el mapa (`rojo build` + `scripts/build-place.luau`). Después se pasaron todas las pruebas de la zona: test-flight, test-airport, test-avion-real, test-aircombat, test-space, test-planetas, test-espacio-aaa, test-mar, test-swim, test-seamotion, test-boats, test-invasion, test-hud, test-clientboot, test-serverboot y test-persistence.
   - **Todas pasaban** antes de los arreglos.
   - Las que pueden ser inestables (test-mar, test-swim, test-seamotion, test-boats, test-invasion, test-avion-real, test-clientboot y test-aircombat) se pasaron dos veces o más. **Ninguna ha fallado ni una vez.**
2. Se revisó el código como un probador de QA. Se buscaron fallos que Lune no ve:
   - remotos sin validar;
   - estados que se quedan puestos;
   - cambios de un sistema a otro (avión ↔ nave ↔ planeta ↔ Valmar, invasión en mitad de una conversación);
   - lo que pasa al morir o al salir del juego en cada sitio.
3. Para cada fallo se escribió primero una prueba que lo reproduce (falla con el código de antes). Después se arregló la causa: `scripts/test-auditoria-vuelo.luau` (nueva) .

## Fallos encontrados y arreglados

| # | Gravedad | Fallo | Cómo se reproducía | Arreglo | Commit |
|---|---|---|---|---|---|
| 1 | **Alta** | En la nave, los botones **SOBRECARGA (escudo), CAMUFLAJE, BENGALAS y DRON**, el **modo de vuelo** (T: combate / crucero / exploración) y el **escáner** no hacían nada en el juego de verdad. | El cliente los manda por el remoto `AirCombat`, pero el servidor solo dejaba pasar las acciones de las fases 4 a 6 (esquivar, hipervelocidad, salto cuántico, arma y recarga). Las pruebas llamaban a `ShipSystems.request` por dentro y nunca por el remoto. En el modo exploración, el servidor seguía en «combate» (misiles y cadencia entera). | Una lista única de acciones (`SYSTEM_ACTIONS`) con todo lo que manda `AirCombatClient`. | `128b52a` |
| 2 | **Alta** | Si el **piloto de una avioneta con pasajeros se iba del juego, moría o se lo llevaban en pleno vuelo**, los pasajeros **caían desde el cielo** (o al mar). | `returnHome` bajaba a los pasajeros «junto a la puerta» ANTES de llevar el avión al hangar, así que se quedaban a 300 studs de altura. | Primero se lleva el avión al hangar y después se pone a los pasajeros a su lado, en el suelo. | `128b52a` |
| 3 | Media | Si **otro sistema se llevaba al piloto de la nave** (la historia con `SceneService.teleportTo`, un interior…), el servidor **le volvía a sentar en la nave**. Se quedaba «volando» o con la nave arrastrada en mitad de Valmar. En un planeta se quedaban `Planeta` y `SpaceReturn` puestos. | El asiento de la nave siempre volvía a sentar a quien se levantaba. | Si lleva `Teleporting` o ya está lejos del asiento (las señales diferidas de Roblox pueden llegar tarde), el vuelo se acaba con el motivo `teleport`, sin devolverle a ningún sitio. Después, `SpaceService` limpia el planeta y la estación. | `128b52a` |
| 4 | Media | **Morir, reiniciarse o ir a Valmar sin el portal** desde una estación espacial dejaba `SpaceStation` y `SpaceReturn` puestos. Al salir del juego más tarde, se volvía a entrar **en el puerto espacial** en vez de donde estabas. | Solo se quitaba al usar el portal. | El bucle de `SpaceService` comprueba que quien está «en la estación» siga en el espacio. Si no, lo quita. El bucle se pone en marcha al entrar en una estación. | `128b52a` |
| 5 | Baja (trampa) | Con un cliente trucado se podía conseguir la **habilitación de reactor sin despegar**: mandando «Touchdown» una y otra vez con la avioneta parada en la pista. Un rebote en la pista también contaba como otro aterrizaje. | `onTouchdown` no miraba si el avión había volado. | Solo cuenta si ha ido al menos 5 s en el aire y el servidor le ha visto subir 25 studs (unos 7 m) sobre la pista. | `128b52a` |
| 6 | Baja (trampa) | Un cliente trucado podía mandar cientos de «Pose» de la nave por segundo. Con cada una, el servidor comprueba choques por todo el camino (hasta 200 por «Pose»), lo que hace ir lento a todo el servidor. | Sin tope. | Como mucho 45 posiciones por segundo (el cliente manda 20). | `128b52a` |

Todos los arreglos están en el commit `128b52a` («Auditoría de vuelo, espacio e invasión: arregla 6 fallos»).

También se vio que, durante la **invasión**, los alienígenas te mataban hablando con un NPC o viendo una escena. Ese fallo ya lo había arreglado a la vez la auditoría de la historia (commits `dc7c493` y `c603b6d`: `InvasionService.storyBusy`). No se ha duplicado.

### Pruebas nuevas

- `scripts/test-auditoria-vuelo.luau`: 18 comprobaciones.
  - **Botones de la nave:** cada botón llega por el remoto, el modo exploración cuenta en el servidor, una acción inventada no hace nada y hay un tope de posiciones por segundo.
  - **Piloto de la nave llevado a otro sitio:** se acaba el vuelo y no le devuelve; también si el aviso llega tarde; saltar del asiento sigue igual.
  - **Estación espacial:** quien vuelve a Valmar sin el portal ya no está en la estación.
  - **Pasajeros:** bajan en el hangar cuando el piloto se va en pleno vuelo.
  - **Aterrizajes:** «Touchdown» sin volar no cuenta y uno de verdad sí.
  - Con el código de antes, fallan 11 comprobaciones.

## Revisado y sin fallos

- **Remotos:**
  - **Aviación:** el estado está limitado a unos 12 por segundo; los menús y el teórico llevan su ficha.
  - **Espacio:** hay un ritmo mínimo entre acciones; tienda y tablón con ficha.
  - **Planeta:** hay un ritmo mínimo; minar, comprobado en el servidor (lejos, bodega, ritmo).
  - **Invasión:** hay un ritmo mínimo; el cañón de la avioneta tiene enfriamiento y calor.
  - **Buceo:** el fusil tiene enfriamiento y distancia.
  - **Mar:** la foto se hace con la criatura cerca; los cofres, una vez al día.
- **Datos guardados:** `data.Space`, `data.Sea`, `data.Invasion` y `data.Aviation` se rellenan con lo que falte antes de usarse.
- **Morir o salir del juego en cada sitio:**
  - **En el avión:** el piloto deja de pilotar y el avión vuelve solo.
  - **En la nave:** el vuelo se acaba al reaparecer.
  - **A pie en Tefra:** `PlanetService` lo limpia al reaparecer.
  - **Buceando:** el aire se recupera fuera del agua.
- **Bucles del servidor:** todos esperan (`task.wait`), o bien van en Heartbeat con contador y se apagan cuando no hay nada que hacer.
- **La invasión siempre acaba:** `Rules.MaxSeconds` y el botón de pruebas. Al acabar se recogen las naves, las tropas, la baliza y la evacuación.
- **El megalodón y el kraken:** «enganchados» por la pesca, siempre se sueltan, porque la pesca del monstruo tiene tiempo máximo.
- **Los disparos alienígenas no llegan a los buceadores** (se apagan por debajo de y = 2).

## Pendiente de mirar a mano en Roblox (Lune no lo puede ver)

1. **Nave, los botones del fallo 1, en el móvil:** SOBRECARGA, CAMUFLAJE, BENGALAS, DRON (con un dron comprado en el taller) y la T / MODO.
   - Deben salir su efecto y su recarga.
   - En EXPLORACIÓN no se pueden lanzar misiles.
2. **Avioneta con un amigo de pasajero:** el piloto sale del juego en pleno vuelo. El pasajero debe aparecer de pie junto al hangar del aeroclub.
3. **Una misión de la historia que te lleve a otro sitio mientras vuelas la nave** (o la tecla de reinicio en una estación). Hay que salir de la nave sin quedarse «flotando».
   - Al salir del juego y volver, debes aparecer donde estabas, no en el puerto espacial.
4. **Invasión mientras hablas con un NPC o ves una escena:** no te deben hacer daño. Al acabar la conversación, sí.
5. **Señales diferidas** (`Workspace.SignalBehavior`): el arreglo 3 cuenta con que el aviso del asiento puede llegar tarde. Hay que probar en un servidor de verdad que **saltar** dentro de la nave te vuelve a sentar (no te debe sacar).
6. **Cliente de la nave que no arranca:** si `AirCombatClient` fallase en un móvil, el jugador se quedaría sentado en la nave sin botones. La única salida sería reiniciar el personaje desde el menú de Roblox.
   - No se ha cambiado: sacarle solo, sin posiciones del cliente, también sacaría a quien deja el móvil en segundo plano.
   - Mirar en la consola (F9) si sale «no llegan posiciones del cliente».
7. **Rendimiento en el móvil:**
   - las naves alienígenas, los disparos y las explosiones de la invasión con 4 o más jugadores;
   - el mar hondo (OceanBuilder) con el kraken a la vista.
8. **HUD:** las pruebas miden 932x430, 844x390, 640x360 y 1920x1080. Hay que mirar en un móvil de verdad que el panel de la invasión y el botón CAÑÓN no tapan el HUD del avión con la muesca de la cámara.
