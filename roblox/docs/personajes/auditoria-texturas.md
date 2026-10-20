# Auditoría de texturas del reparto (pase «AAA», oct 2026)

Encargo del dueño: «TODOS los personajes de la historia deben tener texturas para que se vea juego triple
AAA». Antes, la cara de Cosme («tiene dos bocas»): `docs/personajes/cosme/revision/revision.md`.

**Nada de esto se ha visto en Roblox.** Las imágenes son vistas previas del rasterizador del proyecto
(marca «VISTA PREVIA, NO ES ROBLOX») y lo demás está comprobado con pruebas de Lune. Las texturas NO están
subidas: hasta que el dueño ejecute `scripts/upload-personajes.sh`, el juego se ve exactamente como antes.

## Cómo se construye hoy cada personaje

* **Todas las personas del reparto** (escenas `LifeStory/StageActors`, misiones `SceneService`, el cole
  `SchoolService`, la familia al nacer `BabyService`, Nácara `NacaraService`/`SeaCivService`): un R15 de
  `Players:CreateHumanoidModelFromDescription` con una `HumanoidDescription` vacía (solo colores) y
  `World/Npc.dress`: piezas pintadas de color liso (camiseta, pantalón, zapatos), un «cuello» y un pelo de
  bloques (`Hair`, `HairBack`, `Fringe`) y, a los niños del cole, una mochila. **Ninguna textura.** La cara
  es la de la cabeza por defecto de Roblox (hoy, una cabeza dinámica con la cara pintada en la malla),
  igual para todos.
* **Cosme**: su módulo propio (`shared/CosmeLook`), el único con textura: 4 caras y bata/pantalón
  (Shirt/Pants) subidas. Tenía dos bocas (arreglado; ver arriba).
* **Hondarios de Nácara**: `Npc.create` + piezas de `NacaraService.dressHondario` (túnica de kelp, peto de
  nácar, escamas, cresta, cola). Cara por defecto.
* **Criaturas** (46 entradas: gnomos, cucarachas, gallina gigante, robots-paloma, electrodomésticos,
  alienígenas, clones…): cuerpos de piezas o brillo (`StoryCreatures`, kits). No son personas: fuera de
  este pase.
* No hay ropa de catálogo ni ids de avatar en ninguno (todo es de colores).

## Qué se ha hecho (implementado, sin subir)

| Qué | Cómo | Dónde |
|---|---|---|
| Una sola cara y una sola boca, siempre | `FaceKit.cleanHead` quita la cara de la cabeza dinámica (FaceControls, TextureID, SurfaceAppearance, Decals de más) antes de poner la propia; hablar cambia la imagen del MISMO Decal (`Talk`) | `src/shared/FaceKit.luau`, `Controllers/ActorLife` |
| Caras con textura para cada persona | 129 juegos de caras (519 PNG): ojos con iris en degradado, pupila y dos brillos, párpados y pestañas, cejas con pelos, nariz y boca con sombras, mejillas; gafas, barbas, pecas y arrugas según la Bio. 6 expresiones (Neutral, Happy, Talk, Sad, Angry, Scared) para el reparto principal y los de peso de cada saga; 3 (Neutral, Happy, Talk) para el resto; los papeles sin nombre comparten 8 arquetipos | `assets/personajes/caras/`, `scripts/personajes/gen.py` |
| Expresiones con el sistema de emociones | `CastLook.faceFor`: la emoción de la frase (`Emotion`) y el `Mood` de la escena (`ActorMoods`) eligen la cara; `ActorLife.speak` y el atributo `Mood` la cambian | `src/shared/LifeStory/CastLook.luau` |
| Ropa con textura | 9 camisetas y 5 pantalones, plantillas clásicas (Shirt/Pants, lo nativo que va bien en móvil) **compartidas** y casi blancas: cada personaje las tiñe con su color (`Clothing.Color3`). Grano de tela (punto, sarga, felpa), costuras, pliegues, botones, bolsillos, cremalleras; sin logos ni marcas | `assets/personajes/ropa/` |
| Pelo | mechones (`Texture` de 256 px que se repite, teñida un poco más oscura que el pelo) en las piezas de pelo | `assets/personajes/pelo/pj_pelo.png` |
| Piel | solo color (sin texturas de piel: ninguna imagen de cuerpo sin ropa) | — |
| Ids y vuelta atrás | `shared/PersonajesTextureIds` (vacío); `CastLook` solo pone lo que esté subido: sin ids, el aspecto de antes | `src/shared/PersonajesTextureIds.luau` |
| Subida | `bash scripts/upload-personajes.sh --grupo Ropa,Saga1` (luego `Saga2`, `Nacara`, `Otros`); `--lista` dice qué subiría sin pedir clave. Como Decal, escribe los ids y el servidor los pasa a imagen al arrancar | `scripts/upload-personajes.sh` |
| Vistas previas | antes/después de Saga 1 y Saga 2, hojas de expresiones, Nácara y caras especiales | `docs/personajes/*.jpg` (`scripts/personajes/render.py`) |

Móvil: caras de 512 px (reparto principal) y 256 px (resto) en PNG de paleta (unos 13 KB cada una), ropa
585x559 (el tamaño de Roblox) compartida por estilo, pelo 256 px: 6,8 MB en total para ~190 personajes.
Moderación: **ninguna malla nueva** (solo imágenes de caras y ropa, 13+, todo vestido); si algún día hay
mallas en `assets/personajes`, el script las pasa por `scripts/audit/moderacion-mallas.py` y no sube las
marcadas.

Pendiente (honesto):
* Subir (el dueño) y **verlo en Roblox**: que `Clothing.Color3` tiña como en la vista previa, cómo cae la
  manga corta en el brazo R15 y que la cara se lea bien de lejos en el móvil.
* Las criaturas (46) siguen sin textura.
* Los mechones del pelo no salen en las vistas previas (el rasterizador no dibuja `Texture`).
* Los NPC de la ciudad que no son del reparto (clientes, viajeros…) no entran en este pase.

## Vistas previas

* `docs/personajes/reparto-saga1-antes.jpg` / `reparto-saga1-despues.jpg`
* `docs/personajes/reparto-saga2-antes.jpg` / `reparto-saga2-despues.jpg`
* `docs/personajes/caras-expresiones.jpg`, `docs/personajes/caras-nacara-y-especiales.jpg`
* Cosme: `docs/personajes/cosme/revision/`

Se rehacen con:

```
lune run scripts/personajes/export.luau
lune run scripts/personajes/export-cuerpos.luau
python3 scripts/personajes/gen.py
python3 scripts/personajes/render.py
```

## Personaje por personaje

«Hoy» es como se construye ahora; «Plan» lo que pone este pase en cuanto se suba (caras · camiseta +
pantalón). Las claves `Arq_*` son los arquetipos compartidos.

### Saga 1 (Valmar)

| Personaje | Clave | Tipo | Hoy | Plan (este pase) |
|---|---|---|---|---|
| Abu Rosa | `Abu_Rosa` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Rebeca + Pantalon |
| Abu Tomás | `Abu_Tomas` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (bigote) · Rebeca + Pantalon |
| Alba | `Alba` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Álex | `Alex` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Chandal |
| Andrés | `Andres` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Sudadera + Chandal |
| Alumna | `Arq_Kid_F` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Camiseta + Chandal |
| Alumno | `Arq_Kid_M` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Camiseta + Vaqueros |
| Delegada de 4.º | `Arq_Teen_F` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Camiseta + Vaqueros |
| Alumno de 6.º | `Arq_Teen_M` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Camiseta + Vaqueros |
| Profesora Beltrán | `Beltran` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Chaqueta + Pantalon |
| Bruno | `Bruno` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Chandal |
| Candela | `Candela` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Camisa + Pantalon |
| Carmen | `Carmen` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Chaqueta + Pantalon |
| Cosme | `Cosme` | Own | **con textura**: 4 caras + bata y pantalón (CosmeLook) | arreglo de las dos bocas + cara de hablar (cosme_face_talk) |
| Dani | `Dani` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (pecas) · Camiseta + Chandal |
| Darío | `Dario` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Mamá | `Familia_Mama` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camisa + Vaqueros |
| Papá | `Familia_Papa` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (barba de 3 días) · Camisa + Vaqueros |
| Hugo | `Hugo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Chandal |
| Iker | `Iker` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Camiseta + Vaqueros |
| Iván | `Ivan` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Sudadera + Vaqueros |
| Javier | `Javier` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas, barba de 3 días) · Chaqueta + Pantalon |
| Julián | `Julian` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (barba) · Camisa + Vaqueros |
| Leire | `Leire` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Chaqueta + Vaqueros |
| Profe Lucía | `Lucia` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Rebeca + Pantalon |
| Marisa | `Marisa` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Rebeca + Pantalon |
| Marta | `Marta` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camisa + Pantalon |
| Mateo | `Mateo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (pecas) · Camiseta + Vaqueros |
| Nerea | `Nerea` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Vaqueros |
| Nico | `Nico` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Chandal |
| Omar | `Omar` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Sudadera + Vaqueros |
| Paula | `Paula` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (pecas) · Camisa + Cargo |
| Pip | `Pip` | Robot | colores lisos + brillo · cara por defecto | 6 caras (pantalla con LEDs) · Chaqueta + Pantalon |
| Doña Pilar, la conserje de la residencia | `Portero` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (gafas) · Rebeca + Pantalon |
| Ramón | `Ramon` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (bigote) · Mono + Mono |
| Rayo | `Rayo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Chaqueta + Vaqueros |
| Rocío | `Rocio` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Rubén | `Ruben` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Camiseta + Vaqueros |
| Sara | `Sara` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Camiseta + Vaqueros |
| Tito | `Tito` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Vega | `Vega` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (pecas) · Camiseta + Vaqueros |

### Saga 2 (Tefra, el espacio, la Grieta)

| Personaje | Clave | Tipo | Hoy | Plan (este pase) |
|---|---|---|---|---|
| Abuela Niebla | `AbuelaNiebla` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Rebeca + Pantalon |
| Abuelo Tornillo | `AbueloTornillo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camisa + Pantalon |
| Policía militar | `Arq_Adult_F` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Uniforme + Cargo |
| Capataz de Bastión | `Arq_Adult_M` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (barba de 3 días, arquetipo compartido) · Mono + Mono |
| Refugiado del Mirador | `Arq_Old_M` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (arquetipo compartido) · Camisa + Pantalon |
| Brasa | `Brasa` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (pecas) · Sudadera + Cargo |
| Brisa, la de la sopa | `BrisaSopa` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Pantalon |
| La vieja Bruma | `BrumaTaller` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camisa + Pantalon |
| Capitana Ferra | `CapitanaFerra` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Uniforme + Cargo |
| Cobrador de Hierro | `CobradorHierro1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Cobradora de Hierro | `CobradorHierro2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Comandante Andrés | `ComandanteAndres` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Doctor Cósimo | `Cosimo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (perilla) · Chaqueta + Pantalon |
| Dalia Renn | `DaliaRenn` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Uniforme + Cargo |
| Doctora Fermina | `DoctoraFermina` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Bata + Pantalon |
| Ernesto, el panadero del Ovillo | `ErnestoPanadero` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (bigote) · Delantal + Pantalon |
| Escribano Lumo | `EscribanoLumo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas, perilla) · Rebeca + Pantalon |
| Galo | `GaloPadre` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (barba) · Chaqueta + Cargo |
| General Bastián Corvo | `GeneralCorvo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (barba de 3 días) · Uniforme + Cargo |
| Guardia del Regente | `GuardiaRegente1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Guardia del Regente | `GuardiaRegente2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Ingeniero Orsi | `IngenieroOrsi` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (gafas) · Mono + Mono |
| Leo Solís | `LeoSolis` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Chandal |
| Luz | `LuzPozo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camisa + Pantalon |
| Madre Copo | `MadreCopo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Rebeca + Pantalon |
| Madre Hollín | `MadreHollin` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Rebeca + Pantalon |
| Maestro Olmo | `MaestroOlmo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Vaqueros |
| Mara Solís | `MaraSolis` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camisa + Pantalon |
| Marisa Duna | `MarisaDuna` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Rebeca + Pantalon |
| NILDA | `NILDA` | Holo | colores lisos + brillo · cara por defecto | 3 caras (holograma) · Camiseta + Pantalon |
| Nina Quiroga | `NinaQuiroga` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Niña de la ventana | `NinaVentana` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Ilse | `PrincesaIlse` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Pantalon |
| Pía, la racionadora | `RacionadoraPia` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Rafa «el Zorro» Quiroga | `RafaQuiroga` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Sargento Murria | `SargentoMurria` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras (barba de 3 días) · Uniforme + Cargo |
| Señora Garúa | `SenoraGarua` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Rebeca + Pantalon |
| Soldado del Dominio | `SoldadoDominio1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Soldada del Dominio | `SoldadoDominio2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Tavo | `TavoAguador` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| La Tía Cifra | `TiaCifra` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Tila, la farolera | `Tila` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Sudadera + Vaqueros |
| Capitán Tobi Renn | `TobiRenn` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 6 caras · Uniforme + Cargo |
| Tú, dentro de 10 años | `TuFuturo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (barba de 3 días) · Chaqueta + Vaqueros |
| Tú (malvado, dimensión 66-B) | `TuMalvado` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (perilla) · Chaqueta + Pantalon |
| Varkun, el Deshilador | `Varkun` | Mask | colores lisos + brillo · cara por defecto | 3 caras (máscara de hilo) · Bata + Pantalon |
| Señor Carámbano | `VecinoCarambano` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camisa + Pantalon |

### Nácara (Hondarios)

| Personaje | Clave | Tipo | Hoy | Plan (este pase) |
|---|---|---|---|---|
| Bartolo | `Nacara_Bartolo` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Cantora del Coro | `Nacara_Cantora` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Cultivador de algas | `Nacara_Cultivador` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Farolera | `Nacara_Farolera` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Guardia del Consejo | `Nacara_GuardiaConsejo` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Guardia de la Corriente | `Nacara_GuardiaEste` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Guardia de la Corriente | `Nacara_GuardiaNorte` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Ilun | `Nacara_Ilun` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Lía | `Nacara_Lia` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Maresa | `Nacara_Maresa` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Oriana | `Nacara_Oriana` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Tomé | `Nacara_Tome` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |
| Viajera de las corrientes | `Nacara_Viajera` | Hondario | piezas (túnica, escamas, cresta) · cara por defecto | 3 caras (escamas en las sienes) · su ropa de piezas |

### Otros (secundarios, misiones locas, criaturas)

| Personaje | Clave | Tipo | Hoy | Plan (este pase) |
|---|---|---|---|---|
| Adrián | `Adrian` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Agente de MegaVerso | `AgenteGris1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Agente de MegaVerso | `AgenteGris2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Aspiradora rebelde | `Aspiradora` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Batidora rebelde | `Batidora` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Bigotes XVII | `Bigotes` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Blorp | `Blorp` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Cafetera X-9000 | `Cafetera1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Cafetera de cápsulas | `Cafetera2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Termo rebelde | `Cafetera3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| El Monstruo de los Calcetines Desparejados | `CalcetinMonstruo` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Capitana Ñoz | `CapitanNoz` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Carla | `Carla` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Agente Cronos, de Aduanas del Tiempo | `CazadorTiempo` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Tu clon (el hambriento) | `Clon1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Tu clon (el cantante) | `Clon2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Tu clon (el mandón) | `Clon3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Crujo | `Cucaracha1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Antenas | `Cucaracha2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Sargento Patitas | `Cucaracha3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| DJ Zumbido | `DJZumbido` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Don Escamas | `DonEscamas` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Don Pinzas, cangrejo abogado | `DonPinzas` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Dron de Cósimo | `DronCosimo1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Dron de Cósimo | `DronCosimo2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Dron jefe de Cósimo | `DronCosimo3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Ernesto | `Ernesto` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| El Evaluador | `Evaluador` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Fan hipnotizado | `Fan1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Fan hipnotizada | `Fan2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Fan muy hipnotizado | `Fan3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Fermín, el senderista | `Fermin` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Funcionaria de la ventanilla | `Funcionaria` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Pantalon |
| Gato policía de Gatonia | `GatoPolicia1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Gata policía de Gatonia | `GatoPolicia2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Agente Glub | `Glub` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Gnomo Rigoberto | `Gnomo1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Gnoma Fermina | `Gnomo2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| El Gran Gnomo | `Gnomo3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Hilacha | `Hilacha1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Hilacha grande | `Hilacha2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Ignacio | `Ignacio` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Pantalon |
| Invitado sospechoso | `Impostor1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Invitada sospechosa | `Impostor2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Agente Inés | `Ines` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Uniforme + Cargo |
| Irene | `Irene` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Sudadera + Chandal |
| Julia | `Julia` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Profe Lápiz | `Lapiz1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Lápiz Corrector | `Lapiz2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Jefa de Estudios Grafito | `Lapiz3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Chef Lola | `Lola` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Delantal + Pantalon |
| Luca | `Luca` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Marcos | `Marcos` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Microondas rebelde | `Microondas` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Montse | `Montse` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Chaqueta + Pantalon |
| Doctora Nuria | `Nuria` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Bata + Pantalon |
| Pablo | `Pablo` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Paco | `Paco` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Paloma robot | `PalomaRobot1` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Paloma robot | `PalomaRobot2` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Paloma robot jefa | `PalomaRobot3` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Agente Plof | `Plof` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Gallina Petra (6 metros) | `PolloGigante` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Rata Ladrona | `RataLadrona` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Chandal |
| Ratón Pérez | `RatonPerez` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Rex | `Rex` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Robot de seguridad de MegaVerso | `RobotSeguridad` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Fan número 1 | `Seguidor1` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Chandal |
| Fan número 2 | `Seguidor2` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Vaqueros |
| Fan número 3 | `Seguidor3` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras · Camiseta + Pantalon |
| Sofía | `Sofia` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (gafas) · Bata + Pantalon |
| Tobías | `Tomas` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (barba de 3 días) · Mono + Mono |
| Toni | `Toni` | Human | colores lisos (piezas pintadas, pelo de bloque) · cara por defecto | 3 caras (perilla) · Sudadera + Vaqueros |
| Zarg | `Zarg` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
| Zoltán, la máquina de los deseos | `Zoltan` | Creature | criatura de piezas / brillo (StoryCreatures, kits) | sin textura en este pase (no es una persona: su cuerpo de piezas/brillo se queda) |
