# Auditoría de las cinemáticas (v119)

Encargo del dueño: «Revisa todo tipo de bugs; las cinemáticas tienen un montón de bugs: aparecen
paredes, están mal encuadrados los planos, etc.»

Resumen: la auditoría de planos (`scripts/test-cineplanos.luau`) decía que casi todo estaba bien, pero
**no miraba lo mismo que el juego**. La cámara del juego busca paredes con `workspace:Raycast`, que no
ve las piezas con `CanQuery = false`, y casi toda la decoración del mapa se construye así (copas de los
árboles, tejas, hastiales, molduras, toldos, balcones, contraventanas, muebles): en el juego la cámara
se metía en un toldo, en una copa o detrás de un armario. Los actores se colocaban con
`GetPartsInPart`, que tampoco las ve: acababan dentro del respaldo de un banco o encima de un
parterre. La auditoría usaba todas las piezas y por eso no lo veía. Además tardaba unas 2 horas, no
revisaba el prólogo (la isla del sueño se monta al arrancar), ni el terreno, ni la universidad con
cada carrera, ni el encuadre.

## 1. La auditoría: rápida y fiel al juego

| | Antes | Ahora |
|---|---|---|
| Auditoría entera | ~2 h (no acababa) | **~6-7 min** (2439 escenas, 9656 planos) |
| Construir el mapa | ~3 min cada vez | ~3 min la primera vez; luego **en caché** mientras no cambien `src/server/World`, `src/shared`, `assets`, el proyecto ni los scripts de construcción |
| Prueba completa (`test-cineplanos`, con mapa nuevo) | — | **~10-11 min** |

Por qué tardaba: cada rayo hacía ~1800 operaciones con `Vector3`/`CFrame` de Lune (cada una crea un
objeto). `scripts/lib/CineGeo.luau` hace ahora las cuentas con números sueltos y calcula los filtros
(se ve, choca, suelo, tapa…) una sola vez al cargar cada pieza: **~30 veces más rápido** (un rayo,
~3 µs). La caché del mapa está en `$TMPDIR/cineplanos-cache/` (`CINEPLANOS_SIN_CACHE=1` para
construirlo siempre).

Lo que el mapa de la auditoría tiene ahora:

- **La isla del sueño del prólogo** (`scripts/audit/cine-extras.luau` la añade a la copia del mapa;
  nunca a `RealLifeSimulator.rbxl`). Antes las 9 escenas del prólogo se revisaban sin sus sitios.
- **El terreno** (la isla a Y = −1, el relieve horneado de `ServerStorage.ReliefMap` y las montañas)
  como función de altura: cuenta en los rayos, en el suelo y en la comprobación «cámara bajo el
  terreno». Lo excavado (metro, alcantarillas) no cuenta.
- **Las cuatro carreras** en las misiones con `"$Carrera.X"` (facultades, prácticas) y las condiciones
  `If` de carrera de actores y frases. Antes los cuatro tutores de las prácticas salían a la vez en el
  mismo sitio y la universidad no se revisaba con su sitio.
- **El juego tal cual**: la cámara ve lo que ve `CineCamera` (las piezas con `CanQuery` y la decoración
  que tapa, ver §3) y los actores se ponen con la regla de `SafeSpot.freeForActor`. Las comprobaciones
  miran lo que se ve.

Comprobaciones nuevas (además de las de siempre: cámara dentro, tapado, fuera de cuadro, 180°…):

| Tipo | Qué |
|---|---|
| `CamaraBajoTerreno` | la cámara dentro de una colina, una ladera o la playa |
| `ParedDelante` | una pared, un canto o una copa pegada a la cámara tapa más del 40 % del cuadro (aunque no tape ninguna cara): lo de «aparecen paredes» |
| `HablaFueraDeCuadro` | el plano de situación de una frase no enseña a quien la dice (o lo deja detrás de algo) |
| `CaraCortada` | la cara de quien sale cortada por el borde (barbilla, media cara; la coronilla en planos medios) |
| `SinAire` | los ojos de quien sale en la parte de abajo del cuadro (regla de los tercios al revés) |
| `Horizonte` | un plano general mirando casi en vertical |
| `SinLugar` | un actor cuyo sitio no está en el mapa (no saldría) |
| `Actor`, `Escena` | ahora vigiladas: actor flotando, hundido o dentro de algo; escena que no se puede montar |

También: `scripts/audit/cine-vista.luau` dibuja la vista de la cámara de cualquier plano con rayos
contra el mapa construido, y `scripts/audit/cine-hoja.py` hace las hojas de contactos antes/después.

## 2. Resultado

Mismo mapa (v119, con el paisaje y la isla del sueño), mismas comprobaciones; «antes» es el código del
juego de `78c6941`, «después» el de ahora (`lune run scripts/audit/cine-planos.luau`).

| | Antes | Después |
|---|---|---|
| Escenas revisadas | 2469 | 2439 (sin llegadas en coche o bici en el sueño ni de bebé) |
| Escenas con algún fallo o aviso | 456 | 344 |
| Planos con algún fallo o aviso (de 9788 / 9656) | 1180 | 868 |
| **Cámara dentro de algo** (`CamaraDentro`) | 58 | 9 |
| **Cámara rozando una pared** (`CamaraContraPared`) | 81 | 0 |
| **Pared pegada a la cámara** (`ParedDelante`) | 62 | 0 |
| **Sujeto tapado por el mapa** (`Tapado`) | 104 | 29 |
| **Movimiento que atraviesa algo** (`Atraviesa`) | 11 | 0 |
| **Actor metido en algo** (`DentroDeAlgo`) | 94 | 6 |
| Actor flotando, hundido o dentro (`Actor`) | 14 | 0 |
| Cámara en otra sala (`CamaraOtraSala` / `CamaraFueraDeSala`) | 10 / 144 | 0 / 101 |
| Quien habla fuera del plano de situación (`HablaFueraDeCuadro`) | 36 | 8 |
| Sujeto fuera de cuadro (`FueraDeCuadro`) | 45 | 30 |
| Ojos abajo del cuadro (`SinAire`) | 24 | 13 |
| Plano repetido (`PlanRepetido`) | 8 | 1 |
| Grupo cortado en el borde (`CortadoEnBorde`) | 84 | 93 |
| Dos personas metidas la una en la otra (`Solapados`) | 54 | 54 |
| Cenital / cara enorme / a quemarropa / salto de eje | 14 / 8 / 13 / 15 | 15 / 7 / 14 / 14 |

(«Contraluz» —una ventana detrás de quien sale— es un aviso: 577 → 539. «CamaraFueraDeSala» tampoco
lo vigila la prueba: en las aulas y la casa la cámara pasa por encima de los pupitres y la cuenta de
salas se confunde.) `CortadoEnBorde` sube un poco porque el plano de situación ahora enseña al grupo
entero y alguien del corrillo queda en el borde; `Solapados` son casi todos llegadas en bici (§4).

`test-cineplanos` (completo, con el mapa construido de nuevo): **0 fallos nuevos**, 10 min 11 s en
total (3 min de construir el mapa y 7 de auditoría, con otras pruebas a la vez en la misma máquina).

Las 12 peores (por gravedad de lo arreglado, una por misión), en `docs/auditoria/cinematicas/`
(`hoja-1.jpg` … `hoja-3.jpg` y `plano-01.jpg` … `plano-12.jpg`). Personas: en naranja quien tiene que
salir, en verde tú, en azul los demás; cuadrícula de tercios; a rayas, la cámara está dentro de una pieza
(en el juego se ve la pieza cortada); la vista es la del final del plano.

1. **Uni04_Practicas · el caso (Economía)**: la cámara dentro de la pared del banco y dentro de Marcos
   (Marcos metido en la pared por su marca). → marca de Marcos fuera de la pared.
2. **Loco_D2_Deuda · embargo**: cámara dentro de la puerta de la tienda (sin `CanQuery`). → `CineOccluders`.
3. **Eco_Factura · recargo**: cámara dentro del tirador de la puerta; Ignacio tapado. → `CineOccluders`.
4. **Uni06_Graduacion · foto (Derecho)**: plano general desde dentro de la copa de un árbol. → `CineOccluders`.
5. **Cole07_Excursion · encontrado**: plano general dentro de la esquina del granero; quien habla fuera. → plano de situación de lado al grupo + `Keep` en cuadro.
6. **Cole01_PrimerDia · grupo de estudiantes**: Iker metido en el respaldo de un banco. → `SafeSpot.decorAt`.
7. **Charla en la librería**: la cámara dentro de la puerta. → `CineOccluders`.
8. **Loco_N6_Tirachinas · final**: Cosme de pie encima de un parterre, entre las flores. → `SafeSpot.decorAt` (decoración pequeña).
9. **Aliado_Noz · contrato**: Zarg tapado por el cartel del sendero. → `CineOccluders`.
10. **Rareza_Columpio · Abu**: Abu tapado por la moldura de la casa. → `CineOccluders`.
11. **Ins05_ElRumor · el día después**: plano de dos con Nico fuera de cuadro. → `Keep` en cuadro.
12. **Rareza_Cajero · Pip**: la puerta del cajero pegada a la cámara tapando el 69 % del cuadro. → `CameraShots.clutter`.

## 3. Arreglos (en el juego)

1. **La cámara ve la decoración** (`Controllers/CineOccluders`, nuevo): índice ligero (rejilla de
   32 studs con referencias) de las piezas sin `CanQuery` que tapan (`CameraShots.occluder`: se ven,
   no son cajas de choque, ni hilos ni motas), hecho poco a poco al arrancar y al llegar piezas con el
   streaming. Mientras hay una escena, las de alrededor de donde se lanzan los rayos de la cámara se
   ponen `CanQuery = true` **solo en ese cliente** (no se replica) y vuelven a su valor a los 3 s sin
   rayos de escena. Tope de 9000 piezas. Lo usan `CineCamera.castVisible/castGlass`, así que valen
   para `DialogueUI`, `HappeningClient` y `Cinematics`.
2. **Actores fuera de bancos, setos, parterres y muebles** (`SafeSpot.decorAt/freeForActor/
   findForActor`): el mismo índice en el servidor (con decoración más pequeña: una flor no tapa la
   cámara, pero nadie se pone encima). Lo usan `SceneService.standingSpot` y los huecos de
   `freeMark`, y `HappeningService.blocked`.
3. **La cima del Monte del Silencio** estaba enterrada 11 studs por el relieve nuevo (la marca está
   a ~200 studs y el horneado no contaba lo de más de 160). `ReliefBake.footprints` cuenta siempre las
   marcas `StorySpot`: la cima queda llana a su altura.
4. **El plano de situación de las conversaciones** (`StageDirector.camera`, «General»): de lado al eje
   tú → quien habla y centrado en el grupo (antes, referido solo a ti: a 26 studs delante de ti), sin
   acortarse bajo techo (`Wide`), y quien habla en `Keep`.
5. **`CameraShots.fit`**:
   - las caras de `Keep` tienen que salir **en cuadro** (antes solo sin nada delante);
   - descarta los giros con algo pegado a la cámara tapando más de un tercio (`CameraShots.clutter`);
   - en un plano de una cara prueba antes los giros a la altura de la cara (subir enseñaba la coronilla
     de los niños);
   - tras apartar la cámara de una mesa o del techo (`clearOff`) la gira lo justo para que el foco siga
     en su sitio (`CameraShots.keepAim`: la cara de los niños quedaba abajo);
   - planos al cielo (la Grieta): si hay pared entre la persona de referencia y la cámara, se acerca a
     ella (prólogo: llegando de espaldas al garaje, la cámara estaba dentro del garaje), y si alguien
     queda a quemarropa, gira alrededor.
6. **Planos a la medida de quien sale** también en las conversaciones (`Scales`: altura de cada uno) y
   en los planos de hombro de las escenas (`Aim` también se escala con un bebé enfrente).
7. **Guiones generados** (`scripts/lib/Reescritura.luau`): dos planos al cielo seguidos ya no van al
   mismo sitio (el segundo, más alto y al otro hombro). Regenerados `Prologo_Sueno` y
   `Bebe_AprendeACaminar` (`aplicar-reescritura.luau`).
8. **Datos**: Marcos (prácticas de Economía) fuera de la pared del banco.

## 4. Pendientes

`test-cineplanos` pasa con la lista `PENDIENTES` del propio test. Se quitaron **37** que ya no
fallan. Quedan los de antes que siguen y **44** nuevos, que salen por las comprobaciones y la
cobertura nuevas (encuadre, pared delante, las cuatro carreras, la isla del sueño). Por qué siguen:

- **Grupo apretado** (`CortadoEnBorde`, la mayoría): alguien del corrillo cortado en el borde (8-20 %
  de la pantalla) desde todos los giros; el ajuste elige el que menos corta.
- **Plano de situación en un sitio estrecho** (`HablaFueraDeCuadro`): quien habla queda detrás de algo
  desde todos los giros; el plano siguiente es el suyo.
- **Llegadas en coche o en bici** (`Solapados`, `CamaraDentro` de `Eco_Despido#10`): el vehículo de
  mentira de la auditoría queda en el camino de alguien o empuja a un actor a 1,8 studs de otro; en el
  juego se rodea andando.
- Sueltos (un plano de dos junto a una puerta o un coche aparcado, la explanada del campus con el sitio
  del jugador aproximado, un niño y un adulto en el mismo plano de dos): ver el motivo en cada línea.

## 5. Alrededor de las cinemáticas (revisado)

- **HUD y franjas**: las franjas y los subtítulos de las escenas van en `DisplayOrder` 52 (el HUD, ≤ 10)
  y `Hud.setBusy` esconde tu estado, la misión, los avisos (se guardan para después) y los botones del
  móvil durante conversaciones y escenas. Sin cambios.
- **Botón «Saltar»**: en la franja de arriba, `ZIndex` 20, deja hechas las consecuencias (servidor). Sin
  cambios.
- **Invasión**: en una conversación, escena o el prólogo no eres blanco ni te hacen daño
  (`InvasionService.storyBusy`). Sin cambios.
- **Interiores oscuros**: la luz de cine `InteriorCalido` ya sube el ambiente; sin cambios.
- **Actores que aparecen de golpe**: siguen apareciendo con fundido (`SceneService`); lo nuevo es que ya
  no aparecen dentro de un banco o un parterre.

## Cómo repetirlo

```
lune run scripts/test-cineplanos.luau                       # prueba (construye el mapa o usa la caché)
lune run scripts/audit/cine-planos.luau [mapa.rbxl] --out DIR          # informe completo
lune run scripts/audit/cine-planos.luau mapa.rbxl --solo-consultables  # la cámara de antes (sin CineOccluders)
lune run scripts/audit/cine-vista.luau mapa.rbxl planos.json DIR [--antes]
python3 scripts/audit/cine-hoja.py ANTES_DIR DESPUES_DIR docs/auditoria/cinematicas
```
