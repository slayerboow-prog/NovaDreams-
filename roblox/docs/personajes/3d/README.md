# Personajes 3D propios (piloto, oct 2026)

Encargo del dueño: «Modelos 3D propios». El pase de texturas (CastLook) seguía pareciendo un avatar de
bloques; ahora cada personaje de la historia es **una malla con esqueleto R15** hecha en Blender, con la
ropa, el pelo y los complementos modelados encima y una cara modelada que se mueve con huesos.

Todas las imágenes de esta carpeta son **VISTA PREVIA, NO ES ROBLOX** (Blender/Cycles con las texturas
horneadas que se subirían). Nada de esto se ha visto en Roblox: no se ha subido nada.

## Piloto

| Personaje | Clave (CastLook) | Hoja |
|---|---|---|
| Cosme | `Cosme` | `cosme-3d.jpg` |
| Mamá / Papá | `Familia_Mama` / `Familia_Papa` | `familia_mama-3d.jpg`, `familia_papa-3d.jpg` |
| Pip | `Pip` | `pip-3d.jpg` |
| Abu Rosa / Abu Tomás | `Abu_Rosa` / `Abu_Tomas` | `abu_rosa-3d.jpg`, `abu_tomas-3d.jpg` |
| Profe Lucía | `Lucia` | `lucia-3d.jpg` |
| Nico | `Nico` | `nico-3d.jpg` |

`reparto-3d-antes-despues.jpg`: el piloto entero, antes (CastLook) y después. Cada hoja enseña frente, 3/4,
lado, espalda, la cara con sus expresiones, la versión lejana (LOD) y la malla animada con el esqueleto
R15 (andar, quieto, saludar, señalar, pensar, encogerse de hombros).

«Chispa» (de la lista del encargo, con interrogación) no está en el reparto (`shared/LifeStory/Cast`):
no se ha hecho.

## Cómo es cada malla

- `assets/personajes3d/Personaje3D_<Clave>.fbx`: esqueleto con los nombres del R15 (`Root` →
  `HumanoidRootPart` → `LowerTorso` → `UpperTorso` → `Head`, brazos y piernas, cada hueso en la
  articulación del R15 de Roblox) más 7 huesos de la cara (`FaceJaw`, `FaceMouthL/R`, `FaceBrowL/R`,
  `FaceLidL/R`). Dos mallas: `Cuerpo` (héroes ≤ 12.000 triángulos; los demás ≤ 8.000) y `CuerpoLOD`
  (≤ 3.000 / 2.000). Como mucho 4 huesos por vértice.
- Texturas horneadas (`assets/personajes3d/tex/`): color (con oclusión), normal y rugosidad; 1024 los
  héroes, 512 los demás.
- La cara: ojos con iris y brillo, párpados, cejas, nariz, orejas y **una sola boca** (un hueco que abren
  `FaceJaw` y las comisuras). Las expresiones (`Neutral`, `Happy`, `Sad`, `Angry`, `Scared`, `Talk` y las
  de Cosme `Grin`, `Skeptic`, `Laugh`) son posturas de esos huesos: `shared/Personajes3DMallas.Expressions`.

## Moderación (docs/bugs/moderacion/)

- Nunca una pieza del cuerpo suelta: cada FBX lleva solo `Cuerpo` y `CuerpoLOD` (el personaje entero).
- Todos vestidos del todo: manga larga, pantalón largo hasta el zapato, zapatos; bajo la ropa el cuerpo es
  neutro (sin ninguna forma anatómica). Solo se ve piel en la cara, el cuello y las manos.
- `python3 scripts/audit/moderacion-mallas.py --kits personajes3d --out docs/personajes/3d/revision-gris --vista-gris docs/personajes/3d/revision-gris`
  revisa cada malla (informe en `revision-gris/informe.md`) y dibuja cada una sola, gris y sin textura
  desde 6 lados (`revision-gris/Personaje3D_<Clave>__Cuerpo.jpg`). `scripts/upload-personajes3d.sh` la
  pasa otra vez antes de pedir la clave y no sube nada si hay alguna marcada.

## En el juego

- `World/CharacterMeshLoader` (servidor) carga las plantillas al arrancar y `Npc.dress` monta la malla en
  el actor (Cosme y los del reparto con modelo): el R15 sigue ahí (Humanoid, nombre, bocadillos,
  interacciones, marcas y gestos de StageDirector, ActorLife, AgeMotion, SeaMotion, Cinemateca) con sus
  piezas invisibles, y la malla va soldada a la raíz. Sin ids, si no carga o si la moderación la retira
  (`World/MallasRetiradas`), el actor sigue con CastLook.
- `Controllers/Personaje3DAnim` (cliente) pone cada hueso donde está su pieza en cada fotograma, la cara
  según la expresión (`Cara3DExpresion`) y la boca abierta al hablar (`Cara3DHabla`, desde `FaceKit.flap`);
  de lejos se ve `CuerpoLOD`.
- `shared/FaceKit`: con `Cara3D` no pone ningún Decal (una sola boca: la de la malla).

## Rehacer, revisar, subir

```
python3 scripts/personajes/personajes3d_blender.py            # mallas, texturas, LOD, Luau y hojas
python3 scripts/audit/moderacion-mallas.py --kits personajes3d --out docs/personajes/3d/revision-gris --vista-gris docs/personajes/3d/revision-gris
lune run scripts/test-personajes3d.luau
bash scripts/upload-personajes3d.sh                            # SOLO la sesión que publica, tras aprobar el estilo
```
