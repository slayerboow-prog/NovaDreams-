# Pruebas en los servidores de Roblox

Las pruebas de `scripts/test-*.luau` corren con Lune, fuera de Roblox, con piezas "de mentira".
Sirven para la lógica, pero no saben si un rayo choca con el suelo de verdad o si un personaje
puede llegar andando a una puerta.

Para eso están las **pruebas en la nube**: `scripts/cloud-test.sh` manda unos scripts a Roblox, que
los ejecuta en un **servidor de verdad** con la **última versión publicada** del juego, y enseña el
resultado en castellano. Usa la API de Open Cloud **Luau execution** (`luau-execution-session-tasks`).

## Qué hace falta

1. Publicar antes el juego (`scripts/publish.sh`): la prueba mira lo que está publicado, no lo que
   hay en tu carpeta.
2. La clave `ROBLOX_API_KEY` con este permiso añadido (en create.roblox.com → Open Cloud →
   API Keys → la clave → *Access Permissions*):
   - API System **luau-execution-sessions** → experiencia **Real Life Simulator** → operación
     **write** (en la documentación se llama `universe.place.luau-execution-session:write`).
   - Si la clave tiene *Accepted IP Addresses*, que incluya la IP de la máquina que lanza la prueba.
3. `curl` y `python3` (ya están en la ventana donde se publica). Si hay `lune`, el script comprueba
   antes que la prueba compila, para no gastar un viaje a Roblox.

La clave no se enseña nunca: va en un archivo temporal de cabeceras, como en `scripts/upload-audio.sh`.

## Cómo se lanza

Desde la carpeta `roblox/`, en la misma ventana donde se publica:

```bash
bash scripts/cloud-test.sh                 # todas (arranque, fisica, mundo, transporte)
bash scripts/cloud-test.sh mundo fisica    # solo esas
bash scripts/cloud-test.sh -v arranque     # y además todo lo que sale en la consola del servidor
bash scripts/cloud-test.sh --version 812   # contra una versión concreta del lugar
bash scripts/cloud-test.sh --list          # qué pruebas hay
```

Cada prueba tarda de 1 a 5 minutos (se hacen una detrás de otra). Por cada comprobación sale:

- ✅ bien · ❌ mal (la prueba falla) · ⚠️ aviso (comprobación aproximada: hay que mirarlo, pero
  no hace fallar) · ⏭️ no se ha podido comprobar (y por qué).
- Después, los errores y avisos de la consola del servidor. El registro completo queda en
  `/tmp/cloud-test/<prueba>.log`.

El script sale con **0** si todo va bien, **1** si alguna prueba falla y **2** si no se ha podido
probar (falta la clave, falta el permiso, no hay red…). Si falta el permiso, dice exactamente cuál
añadir.

## Qué prueba cada una

| Prueba | Qué mira |
|---|---|
| `arranque` | Hace lo mismo que `Main.server.luau`: terreno, ciudad, decoración, isla del sueño, datos del tráfico y los ~80 servicios en su orden. Dice cuáles fallan, cuáles tardan mucho, si quedan preparados los autobuses, el metro y el cercanías, y cuenta los errores y avisos de la consola. |
| `mundo` | Con rayos y cajas del motor: hay suelo andable debajo de cada `StorySpot`, de cada sitio con etiqueta que usa la historia (`LifeStory/Locations`) y de cada parada de bus; se llega de pie a las puertas y entradas y a los avisos (ProximityPrompt) del mapa; no hay piezas sueltas flotando cerca de donde aparece la gente; el mobiliario de la calle no está metido en una pared. |
| `fisica` | Sitios clave (plaza, puerta de casa, colegio, parada de bus; en el metro: arriba de la escalera de la boca, delante de los tornos, pasados los tornos y el andén): se puede estar de pie en ellos y **PathfindingService** encuentra camino andando entre ellos. En el metro, además, recorre paso a paso la bajada andando (`Shared/Metro.access(...).Route`) con rayos y la forma de verdad de las piezas. Los tornos no se cruzan andando a propósito (muro de cristal; el torno te pasa al otro lado): por eso hay un camino hasta los tornos y otro desde detrás de ellos al andén. |
| `transporte` | Arranca el servidor y sigue ~30 s a un autobús de cada línea y a un tren de cada línea de metro: que se muevan, que tengan suelo o vía debajo y que no den saltos raros. |

Las pruebas son archivos de `scripts/cloud/`. `_comun.luau` no es una prueba: son las ayudas que el
script pega delante de cada prueba (Roblox recibe un solo texto y no puede leer archivos de aquí).
Para añadir una prueba nueva basta con crear `scripts/cloud/<nombre>.luau` que termine con
`return Cloud.resultado()` (mira las que hay).

## Cómo es el servidor de una prueba (y lo que NO se puede probar)

Según la documentación de Roblox:

- **Los scripts del juego no arrancan solos** (ni los del servidor ni los del cliente) y **la física
  no corre**. Por eso las pruebas arrancan ellas el mundo y los servicios, igual que `Main.server.luau`
  (el orden de los servicios se copia de ahí cada vez). Como la física no corre, no se puede ver
  caer o andar a un personaje: se usan rayos, cajas y el cálculo de caminos. Los autobuses y trenes
  sí se pueden seguir porque los mueve el servidor, no la física.
- **No hay jugadores**: nada que dependa de un jugador conectado (guardar partida, misiones,
  oficios…) se prueba aquí.
- **No hay cliente**: no se prueba nada de lo que se ve o se oye. Ni la interfaz, ni los botones,
  ni la cámara, ni los efectos, ni los sonidos, ni cómo se ve el mapa. Eso hay que mirarlo jugando.
- Lo que la prueba cambia en el mapa **no se guarda**. Pero los **DataStores son los de verdad**: sin
  jugadores el juego no guarda nada, y `UpdateService` no se arranca a propósito (avisaría a los
  servidores del juego de verdad de que hay una versión nueva).
- Límites de Roblox: 5 minutos por prueba (las pruebas se cortan solas antes, hacia los 4 min), un
  script de hasta 4 MB, hasta 4 MB de resultado y 450 KB de registro; como mucho 10 pruebas sin
  terminar a la vez por lugar (si Roblox dice que hay demasiadas, el script espera y reintenta).

Las comprobaciones de "flotando" y "metido en una pared" son aproximadas: por eso salen como aviso
(⚠️) y no hacen fallar la prueba. Si una marca algo que está bien a propósito, se puede afinar en
`scripts/cloud/mundo.luau`. ("Flotando" ya no cuenta lo que está a 1.5 studs o menos del suelo ni lo
que sujeta un adorno de su modelo —las patas de los bancos son `Builder.decor`, que las consultas
del motor no ven—.)

Otras cosas que saber al leer el resultado:
- **Servicios aún no publicados**: si `Main.server.luau` de tu rama arranca un servicio que el juego
  publicado todavía no trae, `arranque` lo enseña como ⏭️ "aún no publicado", no como fallo.
- **Terreno**: en estos servidores la física no corre y los rayos pueden no ver el terreno que
  `TerrainBuilder` acaba de poner. Si un rayo no da con nada, las pruebas leen el terreno en vóxeles
  (`Terrain:ReadVoxels`); `mundo` dice en `rayos ven el terreno` si hizo falta.

## Cómo funciona por dentro (API)

1. `POST https://apis.roblox.com/cloud/v2/universes/{universo}/places/{lugar}/luau-execution-session-tasks`
   (o `…/places/{lugar}/versions/{versión}/luau-execution-session-tasks`) con `{"script": "…"}` y la
   cabecera `x-api-key`. Devuelve la tarea con su `path`.
2. `GET https://apis.roblox.com/cloud/v2/{path}` cada 3 s hasta que `state` sea `COMPLETE`,
   `FAILED` o `CANCELLED` (antes: `QUEUED` o `PROCESSING`). Si termina bien, lo que devuelve el
   script está en `output.results`; si no, en `error.code` (`SCRIPT_ERROR`, `DEADLINE_EXCEEDED`,
   `OUTPUT_SIZE_LIMIT_EXCEEDED`, `INTERNAL_ERROR`) y `error.message`.
3. `GET https://apis.roblox.com/cloud/v2/{path}/logs?view=STRUCTURED` para la consola (cada mensaje
   con su tipo: `OUTPUT`, `INFO`, `WARNING`, `ERROR`).

Como la prueba va detrás de `_comun.luau`, los números de línea de un error salen desplazados; el
script dice cuánto hay que restar.
