# Nave realista «HX-7 Halcón» (malla 3D hecha en Blender)

La nave del jugador deja de ser un montón de piezas básicas de Roblox: ahora es una **malla 3D** hecha
en Blender con Python, con texturas PBR horneadas, como pidió el dueño con su referencia
(`referencia-nave.png`). Es un **diseño propio** inspirado en esa imagen (nada copiado de ninguna saga ni
marca); la designación es nuestra: **HX-7 «Halcón»** (va pintada en el ala izquierda y en el morro).

| Referencia del dueño | HX-7 Halcón |
| --- | --- |
| Blindaje blanco/gris claro en capas sobre paneles gris grafito con «greebles» | Placas blancas en relieve (losas que siguen el casco) sobre casco grafito, rejillas, tubos, antenas, cajitas |
| Alas en flecha anchas, puntas rojas que brillan, franjas azules en el borde de ataque | Alas en delta con placas, alerones, puntas rojas y tiras azules (mallas `BrilloRojo` / `BrilloAzul`, Neon) |
| Lomo elevado y cabina con cristal oscuro | Lomo con derivas inclinadas de punta roja; cabina de cristal tintado con marco, salpicadero y pantallas dentro |
| Tomas de aire laterales | Dos tomas laterales con la boca oscura |
| DOS motores redondos grandes con brillo azul intenso | Dos motores con tobera de pétalos, anillos y cono interior; brillo «Escape» + llama «Llama» + estela |
| Cañones bajo el casco («ARMAS») | Dos cañones largos con bobinas azules bajo los costados |
| VELOCIDAD 1.250 km/h · ESCUDOS 100% · ESTRUCTURA 100% · CARGA 12.000 kg | La misma ficha en el puerto espacial y en el hangar de las estaciones (`shared/AirCombat/ShipInfo`) |

Imágenes (todas hechas con Blender/Cycles a partir de las mallas y texturas exportadas):

* `nave-realista-hoja.jpg` – hoja como la de la referencia (héroe, vistas frontal/trasera/lateral/superior,
  detalles de cabina, motores y armas, tres cuartos y la ficha).
* `nave-realista-comparacion.jpg` – la referencia del dueño al lado de la hoja nuestra.
* `nave-realista-heroe.jpg`, `-tresquartos`, `-frontal`, `-trasera`, `-lateral`, `-superior`, `-motores`,
  `-cabina`, `-armas`.

## Cómo está hecha

```
python3 scripts/nave/nave_blender.py            # (pip install bpy==4.2.0) ≈ 10 min en CPU, con las imágenes
python3 scripts/nave/nave_blender.py --no-render  # solo mallas y texturas (≈ 1 min)
```

* `scripts/nave/geo.py` – geometría de superficie dura **reutilizable**: lofts de secciones, tornos,
  cajas orientadas, cilindros, «losas» que siguen una superficie (el blindaje en capas) y espejo en X.
* `scripts/nave/diseno.py` – el diseño **por parámetros** (`PRESETS`): secciones del fuselaje, lomo,
  cabina, alas, motores, cañones, derivas, tren, paleta y semilla de los greebles. `PRESETS["hx7"]` es la
  nave del jugador; `PRESETS["ejemplo_alien"]` enseña cómo sacar otra (las naves de la grieta pueden usar el
  mismo generador: `--preset <nombre> --out <carpeta> --no-luau`).
* `scripts/nave/nave_blender.py` – el proceso: materiales procedurales (paneles en triplanar con dos
  escalas, suciedad, relieve de las juntas, calcomanías «HX-7», «HALCÓN», «NO PISAR», «PELIGRO · ESCAPE»
  y franjas rojas/naranjas), bisel de 2 segmentos y sombreado por ángulo, triangulado, UV automáticas
  (las piezas de un mismo juego comparten la imagen), **horneado** con Cycles de color, normal (tangente,
  OpenGL como Roblox), rugosidad y metal, exportación por piezas (FBX para subir + OBJ para las pruebas),
  `assets/nave/manifest.json` y `src/shared/AirCombat/NaveMalla.luau`, y las imágenes.

### Piezas y triángulos (presupuesto de Roblox: ≤ 20.000 por MeshPart)

| Pieza (MeshPart) | Triángulos | Texturas | Material en Roblox |
| --- | ---: | --- | --- |
| Fuselaje (casco, lomo, tomas, derivas, placas, greebles, antenas) | 18.228 | casco | Metal + SurfaceAppearance |
| CabinaFrente (marco, salpicadero, pantallas, consolas, reposacabezas) | 2.408 | casco | Metal + SurfaceAppearance |
| Cabina (cristal) | 778 | — | Glass tintado |
| Alas (con placas, alerones y puntas) | 5.652 | alas | Metal + SurfaceAppearance |
| Armas (dos cañones) | 2.368 | alas | Metal + SurfaceAppearance |
| Motores (dos, con toberas) | 12.340 | motores | Metal + SurfaceAppearance |
| TrenPata (tren retráctil: escondido en vuelo) | 528 | motores | Metal + SurfaceAppearance |
| BrilloAzul / BrilloRojo (tiras que brillan) | 568 / 104 | — | Neon |
| **Total de la nave buena** | **42.974** | | |
| NaveLOD (versión lejana, una sola malla) | 3.178 | lod (512 px, color) | Metal |

Texturas: `assets/nave/tex/{casco,alas,motores}_{color,normal,rugosidad,metal}.png` (1024 px) y
`lod_color.png` (512 px). El brillo de las toberas y la llama son piezas Neon (`Escape`/`Llama`, como
siempre) que anima `Controllers/AirCombatFx`; las tiras de las alas son mallas Neon.

## En el juego

* `src/server/World/NaveLoader.luau` (al arrancar el servidor, en un hilo aparte) lee
  `shared/AirCombat/NaveAssetIds` y carga los assets con `World/AssetLoader.download`
  (**AssetService:LoadAssetAsync** y, si falla, **InsertService:LoadAsset**, con reintentos y cola).
  * **Por qué esta API**: en un juego publicado un script no puede crear una MeshPart desde un archivo, y
    `AssetService:CreateMeshPartAsync` necesita el id de la *malla*, que Open Cloud no devuelve al subir un
    FBX (devuelve el id del *Model* que crea). En cambio, un servidor sí puede cargar con
    `LoadAssetAsync`/`InsertService:LoadAsset` los Model de **su mismo dueño** (el usuario o grupo dueño del
    juego): por eso cada pieza se sube como Model y de ahí se saca su MeshPart.
  * **SurfaceAppearance**: los scripts de un juego publicado no pueden poner sus mapas (ColorMap,
    NormalMap…). Por eso la fase 3 de la subida monta un Model con todas las MeshPart **con su
    SurfaceAppearance ya dentro** (`scripts/nave/compose.luau`, con Lune) y el juego solo la clona. Si ese
    Model no está, se usan las piezas sueltas: se intenta crear la SurfaceAppearance y, si Roblox no deja,
    `MeshPart.TextureID` = el mapa de color (eso sí se puede siempre).
  * Si no hay ids, falla la descarga o falta una pieza imprescindible (Fuselaje, Alas, Motores, Cabina),
    **no se cambia nada**: sigue la nave de piezas (respaldo). Nunca lanza error.
  * Si carga después de que ya hubiera naves hechas (la de exposición del puerto…), `ShipModel.upgrade`
    las cambia por la de malla sin tocar el Root ni el asiento (el piloto sigue sentado).
* `src/shared/AirCombat/ShipModel.luau` – `build("Caza")` hace la de malla si hay plantilla
  (`setMeshTemplate`) y si no la de piezas. **La API no cambia**: Root (caja de choque y selección,
  anclado), asiento `ShipSeat`, `Escape`/`Llama` en cada tobera, `LuzNavIzq`/`LuzNavDer`/`LuzCola`,
  `TrenPata` (escondido, lo saca el cliente cerca del suelo), estelas y luces. Atributo `NaveVisual`:
  `"Malla"` o `"Piezas"`.
* **LOD**: la nave de malla lleva dentro la `NaveLOD` escondida. Cada cliente (`Controllers/NaveLod`) enseña
  la lejana en las naves de los demás a partir de `ShipModel.LodDistance` (Low 70, Medium 150, High 260
  studs, según el nivel gráfico); la tuya, siempre la buena. Además Roblox reduce el detalle de cada
  MeshPart con la distancia (`RenderFidelity = Automatic`).
* La nave de piezas (respaldo) también se ha puesto como la referencia: blanca, puntas rojas, franjas azules
  y **dos** motores.
* Ficha (`shared/AirCombat/ShipInfo`): en el puerto espacial (al lado de la nave de exposición) y en el
  hangar de cada estación. Escudos y estructura salen de `Shields` (100 % llenos); la carga es la bodega
  de verdad (`Mining.CargoMax` 40 unidades × 300 kg = 12.000 kg); la velocidad máxima es la de la ficha
  (1.250 km/h).

## Subirla en la próxima publicación (solo en la sesión que publica)

```
cd roblox
export ROBLOX_API_KEY=…          # Open Cloud, permiso «asset: read, write» (y «universe: read» si no das el dueño)
export ROBLOX_CREATOR_USER_ID=…  # (o ROBLOX_CREATOR_GROUP_ID): el MISMO dueño que el juego
bash scripts/upload-nave.sh
git add src/shared/AirCombat/NaveAssetIds.luau && git commit -m "…" && git push
bash scripts/publish.sh
```

1. Texturas → Decal (y su imagen); 2. cada FBX → Model; 3. con Lune: descarga esos Model, monta el
completo con SurfaceAppearance (`compose.luau`) y lo sube. Escribe `NaveAssetIds.luau`. Se puede volver a
lanzar: solo sube lo que falta (`--force` lo sube todo otra vez; `--sin-fase3` se salta el paso 3). La
clave va a un archivo de cabeceras temporal (chmod 600) y nunca se enseña.

**Plan B (Studio)**: importar los FBX con el importador 3D de Studio (con las texturas: crea la
SurfaceAppearance), publicar el Model con las piezas con estos nombres y poner su id en `Completa`.

## Límites y avisos

* La primera vez que se sube, Roblox puede tardar en procesar las mallas; si un servidor arranca antes,
  usa la nave de piezas y cambia a la de malla cuando la cargue.
* El importador de Roblox centra cada malla en su caja: por eso `NaveMalla` guarda el centro y el tamaño
  de cada pieza y el juego las coloca respecto al Root. Si alguna sale girada en Roblox, revisar los ejes
  del FBX (se exporta con `axis_forward=-Z`, `axis_up=Y`: las coordenadas del archivo son las de Roblox).
* Sin la fase 3 (sin Lune), las piezas sueltas solo llevan el mapa de color (TextureID): se ven bien, pero
  sin normal/rugosidad/metal.
* Total ≈ 43 mil triángulos la nave buena (solo la tuya y las cercanas); ≈ 3 mil la lejana.
* La cabina en primera persona (salpicadero con pantallas holográficas) está modelada dentro de
  `CabinaFrente` y se ve por el cristal; una cámara de cabina para la nave queda para otra fase.
* No se ha subido nada: los ids están vacíos hasta que se lance el script al publicar.
