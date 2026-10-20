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
- Mar: el pilote (ahora octogonal con zunchos y placa) y la aguja de roca (ahora con lajas al pie) se
  rehicieron en `scripts/map/mar_kit_blender.py`; las mallas ya subidas siguen valiendo.

Siguiente paso del dueño (a mano, no lo hace ningún script): apelar las dos con los textos de abajo y,
si se quiere, **archivar** en el Creator Dashboard los 5 Model de tropas de la v124 de la lista de arriba
(y sus mallas), que ya no se usan. Después, subir los nuevos: `bash scripts/upload-invasion.sh --solo VortidosCristal2`.

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
