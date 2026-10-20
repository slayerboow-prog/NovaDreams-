# Mallas retiradas por la moderación de Roblox (v124) — qué eran y textos de apelación

El 20 oct 2026 Roblox retiró dos mallas subidas para la v124, las dos por «Contenido sexual»:

| Id de la malla | Avisos | Qué era (identificación) | Confianza |
|---|---|---|---|
| **136955064198663** | `correo-136955064198663.png`, `malla-136955064198663.png` | **Antebrazo** (`ForeArmL`/`ForeArmR`: tubo con la tapa del codo arriba y la bola de la muñeca abajo) de un Vórtido de cristal, subido suelto dentro de `VortidosCristal_<Tipo>.fbx` | Alta en la pieza (la silueta coincide vista a vista); no se puede saber de qué tropa: Esquirla, Monolito, Custodio y Kael-Ithra comparten esa pieza a distinta escala |
| **138746120321894** | `malla-138746120321894.png` | **Pierna** (`LowerLegL`/`LowerLegR`: espinilla larga algo curvada con la tapa de la rodilla arriba) de un Vórtido de cristal, subida suelta igual | Alta en la pieza; misma duda de la tropa (también el Prisma) |

`identificacion.png`: a la izquierda la miniatura de Roblox; a la derecha esas piezas solas, grises y sin
textura, desde el mismo ángulo. Las dos venían de `scripts/upload-invasion.sh --solo VortidosCristal`
(cada FBX de los Vórtidos de cristal llevaba **una malla por segmento**: cuerpo, cabeza, brazo, antebrazo,
muslo, pierna… y su cristal y su brillo). Sola, gris y sin la armadura alrededor, una pieza de brazo o de
pierna (tubo liso con la punta redondeada) es lo que la revisión automática confundió.

Los ids de Model de la v124 que contienen esas piezas (en la rama `publicar-v124`, `AlienAssetIds`):
`VortidosCristal_Grunt` 127461923601982, `_Heavy` 136021321416617, `_Elite` 73310648066914,
`_Ranged` 120901769500194, `_King` 82588191440555 (y las naves `_Fighter` 70632853226038, `_Drone`
126877994619482, `_Dropship` 124637131948835, que no tienen brazos ni piernas). Cada uno de los cinco
primeros lleva otros antebrazos, brazos y piernas sueltos con la misma forma: **pueden llegar más
avisos**. El juego ya no los usa (ver abajo).

## Lo que se ha cambiado para que no vuelva a pasar

- **Los Vórtidos de cristal se suben como UNA malla con esqueleto por personaje** (`VortidosCristal2_*`:
  `Cuerpo`, `CuerpoCristal`, `CuerpoBrillo` con un hueso por segmento, y su LOD), nunca un segmento
  suelto. El cliente los anima moviendo los huesos (`Controllers/AlienAnim`). El faldón en punta de la
  cadera (que, gris, se leía mal) es ahora un faldón de placas anchas, y el pecho va sin pectorales.
- **Revisión antes de subir**: `scripts/audit/moderacion-mallas.py` mira cada malla que se subiría
  (alargamiento, sección redonda, tubo, puntas redondeadas, lisa) y dibuja las marcadas solas y grises en
  `revision/` (`revision/informe.md`). Los cinco scripts que suben mallas (`upload-mar`, `-puerto`,
  `-invasion`, `-asteroides`, `-nave`) la pasan antes de subir nada y **no suben** si hay alguna marcada,
  salvo que se permita cada archivo por su nombre tras mirarlo (`MODERACION_PERMITIR="Pilote"`).
- **El juego aguanta una malla retirada**: `World/MallasRetiradas` lista estos ids (y en el servidor prueba
  de verdad las mallas nuevas); si una pieza principal usa una malla retirada, ese alienígena, esa pieza
  del mar o ese objeto del puerto sale con su versión de piezas de siempre, sin errores (pruebas en
  `test-invasion`, `test-reefzone` y `test-puerto`).
- Mar: el pilote (ahora un grupo de tres pilotes atados) y la aguja de roca (ahora con lajas al pie) se
  rehicieron en `scripts/map/mar_kit_blender.py`; hay que subirlos de nuevo (ver abajo).

## Todo lo demás, rehecho (encargo «Rehacerlos todos»)

- **Las otras razas** (Brumáridos, Ferrocéfalos, Lumínidos, Mórfagos y las criaturas de los Vórtidos:
  caminante de cristal y ciervo de cuarzo) se exportan igual que los Vórtidos de cristal: UNA malla con
  esqueleto por modelo (`Cuerpo` + `CuerpoBrillo`, un hueso por segmento) y su LOD, con el prefijo nuevo
  `<Raza>2_*` y texturas `<Raza>2_tropas/naves` (`scripts/invasion/alien_blender.py`). Mismo aspecto,
  mismas animaciones (por huesos), caja de la cabeza, barras y respaldo de piezas.
- **Nave HX-7**: el fuselaje lleva ahora la chapa del ala (las placas, alerones y puntas siguen en `Alas`)
  y la cabina es facetada con el marco en la misma malla. Se suben como `Fuselaje2`, `Alas2`, `Armas2`,
  `Cabina2`, `CabinaFrente2` (texturas `casco2` y `alas2`); motores, tren, brillos y LOD no cambian.
- **Mar**: el pilote es un grupo de tres pilotes atados; la aguja de roca, con lajas al pie.
- `scripts/audit/moderacion-mallas.py` sobre todo lo que hay en `assets/` (mar, puerto, invasión,
  asteroides, nave): **ninguna malla marcada** (`revision/informe.md`).
- Hasta que se suban, el juego usa las versiones de piezas de los alienígenas, de la nave y de esas dos
  piezas del mar (los ids viejos ya no están en `AlienAssetIds`, `NaveAssetIds` ni `MarAssetIds`).

Subir (la sesión que publica, nunca un script solo):
`bash scripts/upload-invasion.sh --solo VortidosCristal2,Brumaridos2,Ferrocefalos2,Luminidos2,Morfagos2,Vortidos2`,
`bash scripts/upload-nave.sh` y `bash scripts/upload-mar.sh` (los tres pasan la revisión antes de subir).

### Ids VIEJOS para archivar en Roblox cuando los nuevos ya estén en el juego

(Creator Dashboard → el asset → Archivar. Son Model de un segmento por malla —o piezas lisas— que el
juego ya no usa; dentro de cada uno van sus mallas.)

| Qué | Model (id) |
|---|---|
| Brumaridos | `Drone` 90420723800713, `Dropship` 131902629421790, `Elite` 76788154497579, `Fighter` 90076756054126, `Grunt` 102329235218879, `Heavy` 130582584724954, `King` 132286584938156, `PezCaminante` 73743826419050, `RanaNiebla` 117952371661019, `Ranged` 135380421549963 |
| Ferrocefalos | `AutomataChatarra` 77479954277591, `Drone` 90321455358818, `Dropship` 124076266960782, `Elite` 93643730341480, `Fighter` 116345745702704, `Grunt` 119166506300269, `Heavy` 131395666086421, `King` 104991494730483, `PerroTostadora` 99680820083204, `Ranged` 129042065043954 |
| Luminidos | `BuhoEstelar` 137218522502618, `Drone` 96352425944565, `Dropship` 112917153073507, `Elite` 117317481512804, `Fighter` 123934287199965, `Grunt` 82339393710558, `Heavy` 101109039346341, `King` 103981832621289, `Ranged` 124574576228186, `ZorroLuz` 139213058969155 |
| Morfagos | `BabosaBrillante` 82905922136948, `BichoTentacular` 83101652671945, `Drone` 121821752638882, `Dropship` 99385439695748, `Elite` 77826156442495, `Fighter` 75899674558636, `Grunt` 89989577309880, `Heavy` 129995368851290, `King` 136057714633601, `Ranged` 74884630470693 |
| Vortidos | `CaminanteCristal` 97944857781146, `CiervoCuarzo` 132108907810093, `Drone` 113318782399786, `Dropship` 98557786836262, `Elite` 118739897128469, `Fighter` 118366214602180, `Grunt` 102972293087569, `Heavy` 95325353481185, `King` 96281272235939, `Ranged` 119549383592021 |
| Vórtidos de cristal v124 | `Grunt` 127461923601982, `Heavy` 136021321416617, `Elite` 73310648066914, `Ranged` 120901769500194, `King` 82588191440555, `Fighter` 70632853226038, `Drone` 126877994619482, `Dropship` 124637131948835 |
| Nave HX-7 | `Fuselaje` 87215694459571, `Cabina` 93560000555486, `CabinaFrente` 125673720524758, `Alas` 70523914018548, `Armas` 128875574211630 |
| Mar | `Pilote` 109373523641603, `RocaAguja` 138472961747001 |

(Las texturas viejas —Decal de `<Raza>_tropas/naves`, `casco`, `alas`, `pilote`, `rocaaguja`— no son
mallas: se pueden dejar.)

Siguiente paso del dueño (a mano, no lo hace ningún script): apelar las dos con los textos de abajo,
subir los nuevos (arriba) y, cuando ya estén en el juego, **archivar** los ids viejos de la tabla.

---

## Texto de apelación — malla 136955064198663

**Español**

> Hola. Esta malla (136955064198663) es el antebrazo de un personaje alienígena de cristal con armadura
> («Vórtido») de mi juego de Roblox «Heroes of History». Se subió como una pieza más del modelo del
> personaje (cuerpo, cabeza, brazos, piernas), que se monta y se anima en el juego; vista sola, gris y sin
> textura, es un tubo con la articulación del codo y la de la muñeca. No tiene ningún contenido sexual ni
> pretende parecerse a nada así. Ya he cambiado el modelo para subir cada personaje entero en una sola
> malla. Pido que se revise y se restaure. Gracias.

**English**

> Hello. This mesh (136955064198663) is the forearm of an armoured crystal alien character ("Vórtido") in
> my Roblox experience "Heroes of History". It was uploaded as one part of the character model (body,
> head, arms, legs), which is assembled and animated in-game; seen alone, grey and untextured, it is a tube
> with the elbow and wrist joints. It contains no sexual content and is not meant to resemble anything of
> the kind. I have already changed the pipeline so each character is uploaded whole as a single mesh.
> Please review and restore it. Thank you.

## Texto de apelación — malla 138746120321894

**Español**

> Hola. Esta malla (138746120321894) es la pierna (de la rodilla al tobillo) de un personaje alienígena de
> cristal con armadura («Vórtido») de mi juego de Roblox «Heroes of History». Se subió como una pieza más
> del modelo del personaje, que se monta y se anima en el juego; vista sola, gris y sin textura, es la
> espinilla con la rodillera. No tiene ningún contenido sexual. Ya he cambiado el modelo para subir cada
> personaje entero en una sola malla. Pido que se revise y se restaure. Gracias.

**English**

> Hello. This mesh (138746120321894) is the lower leg (knee to ankle) of an armoured crystal alien
> character ("Vórtido") in my Roblox experience "Heroes of History". It was uploaded as one part of the
> character model, which is assembled and animated in-game; seen alone, grey and untextured, it is the
> shin with its knee guard. It contains no sexual content. I have already changed the pipeline so each
> character is uploaded whole as a single mesh. Please review and restore it. Thank you.
