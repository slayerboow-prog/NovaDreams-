# Estilo bloque «premium» del reparto (oct 2026)

Encargo del dueño (tras descartar el piloto de humanos lisos): el avatar de bloques de Roblox de siempre,
con **accesorios 3D propios** hechos en Blender, **ropa con textura** y **caras dibujadas a mano**.
Referencias del dueño (hechas con IA: estilo e inspiración, no diseños exactos) en
`docs/personajes/referencia/`.

Todas las imágenes de esta carpeta son **VISTA PREVIA, NO ES ROBLOX** (Blender/Cycles). No se ha subido
nada.

| Archivo | Qué enseña |
|---|---|
| `cosme-bloque.jpg` | Cosme: pose, espalda, lado, 5 caras y el despiece de accesorios |
| `cosme-comparacion-referencia.jpg` | la hoja del dueño encima y la nuestra debajo |
| `familia_mama-bloque.jpg`, `familia_papa-bloque.jpg`, `abu_rosa-bloque.jpg`, `abu_tomas-bloque.jpg` | la familia del jugador |
| `pip-bloque.jpg`, `lucia-bloque.jpg`, `nico-bloque.jpg` | el resto del piloto |
| `reparto-bloque-antes-despues.jpg` | todos: antes (CastLook) y después |
| `revision-gris/` | cada malla sola, gris y sin textura desde 6 lados, y el informe de la revisión |

## Cómo está hecho

- **Cuerpo**: el R15 de bloques de Roblox (como hoy). Sus articulaciones, el Humanoid, el nombre, los
  bocadillos, las marcas y gestos de las escenas, AgeMotion… no cambian.
- **Accesorios** (`assets/bloque/Bloque_<Clave>.fbx`, una MeshPart por accesorio): rígidos y soldados a
  UNA parte del R15 cada uno, como un sombrero: pelo, gafas y cabeza de bloque en la cabeza; bata,
  rebeca o chaqueta en el tronco; mangas en brazos y antebrazos; faldón por mitades en cada pierna; botas
  y zapatos en los pies; objetos en la mano. Las piezas de luz (cristales de las gafas, pantallas,
  depósito de la pistola) van en Neon. Los grandes llevan versión lejana (`…LOD`). ≤ 10.000 triángulos
  de accesorios por personaje; atlas de 1024 (héroes) o 512.
- **Ropa**: plantillas clásicas Shirt/Pants de 585x559 (`assets/bloque/ropa/`) con pliegues, costuras,
  manchas y sombreado.
- **Cara**: una imagen por expresión (`assets/bloque/caras/`, 512) en el ÚNICO Decal de la cabeza de
  bloque (la Head del R15 queda invisible). Una sola boca siempre (`shared/FaceKit`).
- **Arte original**: Cosme es el arquetipo de inventor (pelo de punta, gafas, bata) con detalles propios:
  gafas cian, mochila de circuitos, aparato de muñeca, colgante azul y el anillo morado de su pistola.
  Sin babas ni rasgos de ningún personaje conocido; sin marcas reales.
- **Familia del jugador** (no es familia de Cosme): cada uno con su pelo propio (moño castaño de Mamá,
  pelo oscuro peinado de Papá, moño de rizos blanco de Abu Rosa, gorra y pelo blanco a los lados de Abu
  Tomás) y la ropa de la hoja del dueño (rebeca rosa y delantal con taza; chaqueta negra y gafas de sol;
  rebeca lila, perlas, gafas redondas y bolso de mano; chaleco verde, camisa de cuadros, bigote y
  periódico: los bastones se quitaron porque un palo largo y redondo es lo que marca la revisión).
  No hay hermano/a en el reparto (`Cast`): no se ha hecho.

## Oficios y gente de la calle (`npcs-dueno.png`)

- **13 oficios con nombre** (`scripts/personajes/bloque_oficios.py`, `oficios-bloque.jpg`), con los nombres
  que el juego ya usa (CityErrands) o uno nuevo que no repite a nadie (no hay otra Lucía): Frutero Ramón
  (tienda), Barista Dani (cafetería), Policía Sergio, Mecánico Pedro, Enfermera Carmen, Bombero Nacho,
  Barman Raúl, Pescador Chema, Repartidor Kevin, Ejecutivo Borja (concesionario, oficinas), Farmacéutico
  Julio (farmacia y consulta), Paco de la obra y Dependienta Vero. Cada uno se monta por el NOMBRE del NPC
  (`Oficios` en `EstiloBloque`: «Policía», «Agente», «Npc_Barista», «Médico», «Obrero»…). Textos de los
  uniformes genéricos y en español («POLICÍA / VALMAR», «BOMBEROS», «REPARTO»); sin marcas.
- **Gente de la calle**: 24 personas (`Multitud_01..24`) con UN solo Model compartido
  (`Bloque_Multitud`: cabeza, 10 pelos, gorra, 3 gafas, mochila, bolso, auriculares, bufanda, zapatillas),
  sin textura y teñido por persona; cada una con su ropa y su cara (normal y hablando). Como mucho 3
  accesorios además de la cabeza y los zapatos. Clientes, viajeros, espectadores, pacientes, huéspedes,
  vecinos…: la persona sale del nombre y de `look.Seed`/`NpcId` (si no, del orden), siempre la misma.
- Lejos, `Controllers/EstiloBloqueLOD` esconde las piezas pequeñas y pone la versión sencilla de las grandes.

## En el juego

`World/EstiloBloqueLoader` carga las plantillas al arrancar y `Npc.dress` lo monta en el actor. Sin ids,
si falta un accesorio, si la moderación retira una malla (`World/MallasRetiradas`) o si no hay cara
subida, ese personaje sigue con CastLook. `Controllers/EstiloBloqueLOD` pone la versión lejana de lejos.

## Rehacer, revisar, subir

```
python3.13 scripts/personajes/bloque_blender.py            # todo (--solo Oficios, --solo Multitud, --no-render)
python3.13 scripts/audit/moderacion-mallas.py --kits bloque --out docs/personajes/estilo-bloque/revision-gris --vista-gris docs/personajes/estilo-bloque/revision-gris
lune run scripts/test-estilo-bloque.luau
bash scripts/upload-estilo-bloque.sh        # SOLO la sesión que publica, tras aprobar el estilo
```
