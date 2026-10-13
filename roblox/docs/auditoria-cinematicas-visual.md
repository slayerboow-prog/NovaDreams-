# Auditoría visual de las cinemáticas

Comprobación «desde diferentes ángulos y perspectivas» de todas las cinemáticas y conversaciones
escenificadas de Heroes of History, sin abrir Roblox: se construye el mapa real (TownBuilder con
`scripts/build-place.luau`), se pone en escena cada paso de cada misión como lo haría el juego y se
revisa cada plano de cámara con rayos contra las ~411 000 piezas del mapa.

## Herramientas

| Archivo | Qué hace |
|---|---|
| `scripts/lib/CineGeo.luau` | El mapa como cajas, bolas y cuñas en una rejilla 3D: rayos (como `workspace:Raycast`, la pieza donde empieza el rayo no cuenta), «¿este punto está dentro de algo?» y el suelo bajo un punto (como `SceneService.groundAt`). |
| `scripts/lib/CinePlanos.luau` | La puesta en escena: dónde está el jugador (Teleport, Offer.Place, el borde del sitio al que llega, el personaje con quien habla), dónde salen los actores (LocationService + SceneService: lugar, Index, Offset, Look, suelo, separación, quien está lejos se acerca), los planos (StageDirector para las conversaciones; Sequencer + CameraShots para las escenas del motor, con Use/Spawn/Enter/Move y las miradas a quien habla) y el ajuste real de la cámara (`CameraShots.fit`, el mismo código que los clientes). |
| `scripts/audit/cine-planos.luau` | El informe (`informe.txt`) y los datos para dibujar (`escenas.json`). `--antes` imita el código de cámara de antes para comparar. |
| `scripts/audit/cine-render.py` | Tres vistas por plano (arriba, corte lateral por la cámara y la vista aproximada de la cámara con cajas) para las escenas con fallos y una muestra de 10 buenas. Las imágenes van a la carpeta que se le diga, no al repositorio. |
| `scripts/test-cineplanos.luau` | La prueba: las cuentas de la cámara con un mundo de mentira (segundos, `--solo-cuentas`) y la auditoría entera contra el mapa (~2,5 min más construir el mapa); falla si aparece un plano malo nuevo. |

Uso:

```
rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
lune run scripts/audit/cine-planos.luau X.rbxl --out /tmp/cine
python3 scripts/audit/cine-render.py /tmp/cine/escenas.json /tmp/cine/img
lune run scripts/test-cineplanos.luau X.rbxl
```

## Qué se comprueba en cada plano

- **CamaraDentro / CamaraEnPersonaje**: la cámara dentro de una pieza que se ve (pared, suelo, techo,
  mueble, coche) o dentro del cuerpo de alguien.
- **BajoTierra**: por debajo del suelo donde están los personajes. **Lejos / Pegada**: a más de 70 studs
  del sujeto o a menos de 1 de su cara.
- **FueraDeCuadro**: quien tiene que salir (quien habla, quien reacciona, los dos de un plano de dos) no
  sale en pantalla (campo de visión del plano, 16:9).
- **Tapado / TapadoPorPersona**: sale, pero hay una pieza del mapa u otro personaje entre la cámara y su cara.
- **Atraviesa**: un dolly, travelling, pan u órbita cruza una pared a mitad de recorrido.
- **Salta180**: dos planos seguidos de la misma pareja (hombro, contraplano, dos) a cada lado de la línea.
- **Solapados**: dos personas (actores o tú) metidas la una en la otra (a menos de
  `ActorStaging.BodyGap` = 2 studs, a su escala).
- **Actor**: flotando, hundido o metido en algo. **Terreno** (aviso): sin piezas debajo; el monte y la
  playa son terreno, que Lune no puede leer.

## Resultado

597 escenas (todas las conversaciones de pasos Scene, Talk y Choice y las 58 escenas del motor de las
misiones). Planos revisados: 3052 con el código de antes, 3300 ahora (salen más porque los personajes
que antes quedaban lejos ahora están en la escena).

| | Antes (código original) | Después |
|---|---|---|
| Escenas con algún fallo | 233 | 20 |
| Planos con fallo | 400 de 3052 | 26 de 3300 |
| Cámara dentro de pared/objeto | 57 | 2 |
| Cámara dentro de alguien | 102 | 1 |
| Pegada a la cara (< 1 stud) | 49 | 0 |
| Movimiento que atraviesa paredes | 55 | 4 |
| Sujeto tapado por el mapa | 30 | 9 |
| Sujeto tapado por otro personaje | 215 | 3 |
| Sujeto fuera de cuadro | 12 | 7 |
| Salto de eje (180°) | 48 | 1 |
| Lejos (> 70 studs) | 10 | 0 |
| Bajo tierra | 2 | 2 |
| Actores mal puestos | 119 | 3 |

(La primera columna es la primera pasada de la auditoría sobre el código original. Con las
comprobaciones ya afinadas, `--antes` da 236 planos malos de 3098 sin contar los saltos de eje, que el
modo `--antes` ya no puede imitar.)

Se miraron las imágenes de las tres vistas de los fallos y de la muestra de escenas buenas (aula de
Cole01, casa familiar, patio, campus, residencia, garaje, granja…) para confirmar que los fallos eran de
verdad y que las buenas lo son.

## Fallos encontrados y arreglos (generales)

1. **La cámara se metía en la cabeza del jugador** (el más frecuente). Quien habla contigo está a
   5 studs y te mira; el primer plano y el de reacción ponen la cámara a 4,2-4,6 studs delante de su
   cara: justo dentro de tu cabeza. Y el plano de hombro de un adulto mirando a un niño dejaba la cara
   del niño detrás del hombro.
   → **`CameraShots.fit`** (shared): ajusta cada plano para que la cámara no esté dentro de una pared,
   de un mueble ni de nadie y la cara del sujeto (y la del otro en un plano de dos) se vea: primero se
   acerca por la misma línea (como mínimo a 1,8 studs de la cara), si no basta gira el plano alrededor
   del foco (±20°, más alto, ±40°…) sin cruzar la línea de la pareja, y si nada vale se queda lo más
   lejos posible sin meterse en nada. Mira lo que **se ve** (también lo que no choca: copas, cristales
   opacos) y los cuerpos de la escena. Lo usan `DialogueUI` y, por primera vez, `HappeningClient`
   (las escenas del motor no se ajustaban nada: 40 cámaras dentro de paredes). `CineCamera.fit/probe`
   dan los rayos y los cuerpos en Roblox. El giro elegido al empezar un plano se mantiene (sin saltos).
2. **Regla de los 180°**: el plano de hombro iba siempre por el hombro derecho, así que plano y
   contraplano quedaban a cada lado de la línea. → ancla **`Over:A>B`**: el hombro del lado de la
   pareja (el lado desde donde mira el jugador o, si es uno de los dos, uno fijo por nombre), el mismo
   que usa `DosPlanos` cuando los dos se miran.
3. **Dollies que atravesaban farolas, tabiques y personas** → `CameraShots.clearPath`: si el recorrido
   cruza algo, el plano se queda quieto.
4. **Plano de dos con los dos lejos** (no cabían) → ancla **`Wide:A|B`** en `DosPlanos` y `Pan`: se aleja
   lo justo para que quepan.
5. **Escenas a 80-120 studs de ti**: un paso Reach a un sitio grande (parque, playa, campus) se cumple
   en su borde, pero la escena que viene detrás está en su centro (cita en la playa, Rayo en el parque,
   Luca en la explanada…). → `LifeStoryService.gatherForStep` + `ActorStaging.lead/gatherSpot`: si quien
   lleva la escena está a más de 60 studs (conversación) o 30 (escena del motor), te acerca a unos pasos
   con un fundido.
6. **Actores de pie encima de pupitres y mesas, flotando o metidos en un banco** → `SceneService.feetAt`
   (el suelo bajo el punto sin subirse a nada de más de 1,6 studs) y `standingSpot` (tras separar a los
   actores se vuelven a apoyar en el suelo y, si no caben de pie, van al hueco libre más cercano).
7. **Saltos (Teleport) que dejaban al jugador encima de la mesa** de la cocina → `SceneService.floorNear`.
8. **Datos**: actores dentro de las fuentes de Plaza Centro y Plaza Financiera (Loco_Adolescente,
   Uni_Consecuencias, Rarezas, Aliados) movidos fuera.

## Llegando de otra forma (octubre 2026)

Vídeo de la Plaza Mayor (Adulto_Bienvenida): llegabas en bici, la escena empezaba contigo montado,
Ernesto y Lola se metían el uno en el otro y en la bici, y la espalda de Ernesto llenaba la pantalla.
Ahora la auditoría pone cada escena del motor también llegando **desde la derecha, desde atrás, desde
la izquierda, en coche y en bici** (el vehículo aparcado a tu lado: `CinePlanos.Arrivals`) y falla si
dos personas se solapan. Arreglos generales (valen para todas las escenas):

1. **Te bajas del vehículo** antes de cualquier escena con cámara o conversación de la historia
   (`CinematicService.leaveVehicle`, desde `HappeningService.play`, `CinematicService.play` y
   `LifeStoryService.startInteractive`; `InVehicle = true` lo evita). Viendo una escena no se puede
   sacar un vehículo (`InScene` en `VehicleService.canSpawn`).
2. **Marcas validadas** (`ActorStaging.freeMark` / `clearFacing`): las marcas que van contigo se giran a
   tu alrededor si caen dentro de algo (tu coche aparcado, una farola) y ningún actor queda a menos de
   2 studs de otro ni de ti (`HappeningService.settle`; en las conversaciones, `SceneService.applySet`
   y quien se acerca a hablar, que antes iban al MISMO hueco libre).
3. **Cámara**: `CameraShots.fit` cambia de giro a mitad de plano si alguien se pone delante de la cara
   (antes seguía detrás de su espalda), prueba planos por encima de las cabezas y, si no se ven todas
   las caras, al menos la de quien habla. Un travelling de escena que atravesaría algo se queda quieto
   en su final (`CameraShots.travelBlocked`, como ya hacía DialogueUI).

Resultado: 873 escenas (603 + 270 llegadas distintas), 7089 planos. Al activar las comprobaciones
nuevas salían 945 planos con fallo en 63 escenas (819 de personas solapadas, en 40 escenas); con los
arreglos, 0 nuevos y 13 de los que estaban pendientes ya no fallan. Con los guiones reescritos: 885
escenas y 8676 planos, 0 fallos nuevos; quedan 10 casos sueltos de llegadas raras en `PENDIENTES`.

## Fallos vistos en la v104 (octubre 2026)

Capturas del juego: Papá en el tejado, salas vacías, el mismo plano aéreo repetido, carteles «!» y
ProximityPrompts encima de la conversación, el protagonista dentro de la pared, la cámara de
conversación demasiado lejos y el título «Por la tarde…» repetido encima del diálogo.

- **Tejado / fuera de la sala**: `deps.ground` lanzaba el rayo desde +10 y daba en el tejado; además
  la búsqueda en anillo de `freeMark` sacaba a la gente al otro lado de la pared. Ahora el rayo sale
  de +4 (y +10 solo si no hay suelo), y `freeMark` solo acepta un sitio libre (`blocked`), al que se
  llega andando sin cruzar paredes (`reachable`) y de la misma sala (`sameRoom`); si no hay ninguno,
  la marca original. Al protagonista se le saca de la pared (`HappeningService.unstick`).
- **Salas vacías**: quien te habla viene a tu sala (`nearYou`, a `TalkGap`), y los planos generales
  bajo techo cuentan cuántas caras del grupo se ven y prueban esquinas de la sala hasta ver a más
  (`CameraShots.fit`, `Crowd`). En conversación el grupo es Yo + quien habla + a quien habla.
- **Plano repetido**: `Sequencer.vary` junta planos iguales seguidos y gira los que se repiten.
- **Conversación**: DialogueUI no ponía el campo de visión del plano (se quedaba el del juego, 70) y su
  plano de hombro de repuesto (frases sin plano escrito) no tenía límite de cerca. Ahora todas las
  frases usan los planos con nombre con su campo de visión, y el de hombro (como el del aula) va a
  ~4 studs de tu cabeza, de lado (SHOULDER 3,2) y con campo de visión 55: quien habla un poco a un
  lado del centro y tu hombro en el otro; tu cabeza ocupa ~22 % del alto (niño) o ~34 % (adulto).
  Si el ajuste deja la cámara a menos de 3,2 de tu cabeza o a menos de 3,5 de la cara de quien habla,
  plano medio de quien habla; y un plano medio o primer plano con la cabeza de otro pegada a la
  cámara se hace por encima de su hombro (`CameraShots.nearIntruder`).
- **Encima de la escena**: durante diálogos, escenas y minijuegos se esconden los ProximityPrompts,
  la barra de objetos (también en las escenas: `InventoryUI.setBusy`), los nombres y los «!» de la
  gente de la ciudad (etiqueta `NpcIcon`, `CineCamera.quietLabels("Ocupado")`), «¿Qué hago?», los
  botones de acción y los bocadillos; los avisos esperan a que acabe (los errores no).
  El título de la hora no se repite si ya está en pantalla.
- **Vehículos**: antes de cualquier escena se baja al jugador del coche/bici (salvo `InVehicle`).

- **Paredes (nacimiento, v106)**: los padres salían aplastados contra la pared del cuarto, la cámara en
  la esquina y, al acabar, andaban contra la pared. Ahora, sin medidas fijas de sala:
  - ninguna marca a menos de `ActorStaging.WallGap` (1,5) de una pared (rayos en 8 direcciones a 2,2
    —solo lo alto, para la pared de debajo de una ventana— y a 3,4 sobre los pies);
  - la cámara nunca a menos de `CameraShots.CAM_CLEAR` (0,7) de nada (`CameraShots.clearOff`, también
    en cada fotograma de los travellings de las conversaciones);
  - al irse (Exit) el destino es un sitio libre de su sala, se va por el camino (PathfindingService) y
    si no avanza en 1,5 s para o se va; en SceneService avanzar es acercarse al punto, y Wander solo
    elige puntos de su sala, libres y sin pared.
  - `test-cineplanos` lo exige en todas las escenas (fallos `PegadoAPared`, `CamaraContraPared`,
    `SalidaBloqueada`) e incluye las escenas de capítulo del motor (el nacimiento). Las otras nueve
    escenas de capítulo (Cole01_Amanecer, Ins_Entrada…) son del sistema de cinemáticas de antes y la
    auditoría no las pone en escena.

- **El bebé y Mamá (v107, casa de 64 × 64)**: Mamá le hablaba al bebé desde la cocina, a través del
  hueco de la puerta (su marca quedaba a más de 40 studs y `nearYou` no la traía; además en una casa
  abierta «misma sala» es solo que no haya pared en medio); planos desde su nuca a quemarropa (el ajuste
  giraba la cámara detrás de la cara si la pared estaba delante); Abu en su sillón tapando media pantalla
  (la familia de casa no contaba como cuerpos); todo muy oscuro; el bebé fuera de cuadro (los planos con
  nombre son para un adulto). Arreglos generales:
  - quien te habla viene a tu lado si está a más de `ActorStaging.TalkFar` (10) o en otra sala, hasta 90;
    también el actor prestado de la misión;
  - `CameraShots.fit`: nunca detrás de la cara de quien sale (`Front`), no más cerca de su cara de lo
    que deja el campo de visión (`minDistance`: la cara ≤ 40 % del alto) y nadie más ocupando más del
    60 % del alto delante de la cámara (`Fov`); la gente fija cercana cuenta como cuerpos;
  - los planos con nombre a la medida de quien sale (`CameraShots.scaleShot`);
  - luz de relleno con la cámara en conversaciones y escenas (`CineCamera.keyLight`) e `InteriorCalido`
    más claro: caras iluminadas, sin siluetas contra las ventanas;
  - sin bocadillo encima de la cabeza en las escenas con subtítulo, y en las conversaciones solo si cabe
    en pantalla; «»» en vez de «▸»/«▼» (en el móvil salían como cajas).
  - auditoría: entran las escenas que lanza un paso (`Effects.Scene`, casi todas las de los guiones), la
    etapa sale del capítulo (el bebé ya no es un adulto), la familia de casa sale como personas y vas
    delante de quien te habla. Fallos nuevos: `DeEspaldas`, `CaraEnorme`, `TapadoCerca`,
    `RepartoSeparado`, `CamaraFueraDeSala`. La luz no se puede medir en Lune: la pone la luz de relleno.
  Hojas `antes_v107_*` / `despues_v107_*`.

Hojas de contacto (16 planos por hoja) en `docs/auditoria-cinematicas-visual/`: `antes_*` y
`despues_*` de Bebé (VentanalFamilia), Cole01, Cole03 (planos de hombro en el patio) y Loco_N1 (el
garaje de Cosme, estrecho y con protagonista adulto).

## Qué queda

Los 26 planos que quedan están en `PENDIENTES` de `scripts/test-cineplanos.luau`, cada uno con su
motivo: montaje de recuerdos con planos a mano por dentro de la casa (Adulto_MirarAtras), una órbita a
mano dentro de la casa (Uni06_Final), sitios estrechos donde no cabe un plano de dos (garaje de Cosme,
cafetería, torre), tabiques o columnas entre dos personajes, Ramón metido en el marco de una puerta
(Cole09), un escalón entre Ernesto y tú y planos sobre terreno (monte, playa).

Límites de la auditoría (no se ven fuera de Roblox):
- **Terreno**: el monte y la playa son terreno; ahí no hay suelo ni paredes que mirar (aviso «Terreno»).
- **Interiores que se crean al jugar** (salas en el cielo, Y > 3000) y las mallas que sustituyen a los
  bloques: se revisa la versión de bloques del mapa.
- **Dónde está el jugador** es aproximado (el borde del sitio al que llega, a 5 studs de quien le habla,
  el Offer de la misión).
- Los objetos de las misiones (Props) dentro de las fuentes de las plazas no se han movido (no son
  cinemáticas); algunos «planos sucios» (alguien en primer término sin taparle la cara) cuentan como buenos.
