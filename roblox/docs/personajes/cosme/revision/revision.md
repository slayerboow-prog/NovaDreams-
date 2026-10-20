# Cosme · revisión a detalle (oct 2026)

Encargo del dueño: «La cara de Cosme está mal, tiene dos bocas; revisa a detalle bien a Cosme».

Todas las imágenes de esta carpeta son **VISTA PREVIA, NO ES ROBLOX**: el rasterizador del proyecto
(`scripts/cosme/render.py`) dibuja las piezas de verdad de `shared/CosmeLook` exportadas con
`scripts/cosme/export.luau`. Se rehacen con:

```
lune run scripts/cosme/export.luau
python3 scripts/cosme/revision.py
```

| Archivo | Qué enseña |
|---|---|
| `cosme-frente.jpg`, `cosme-tres-cuartos.jpg`, `cosme-lado.jpg` | el cuerpo entero |
| `cosme-primer-plano.jpg` | las 4 caras de emoción y la nueva de hablar (boca abierta) |
| `cosme-dos-bocas-antes-despues.jpg` | el bug, simulado, y cómo queda |

## Las dos bocas: la causa

Todos los sitios donde sale Cosme (su casa `World/CosmeHouse/NPC` → `Npc.create`; las misiones
`SceneService`; las escenas y la Cinemateca `LifeStory/StageActors`) crean el cuerpo con
`Players:CreateHumanoidModelFromDescription` y una `HumanoidDescription` **vacía**. Roblox da hoy por
defecto una **cabeza dinámica**: la cara —ojos, cejas y **boca**— va pintada en la textura de la malla de
la cabeza (`MeshPart.TextureID` / `SurfaceAppearance`) y se mueve con `FaceControls`; ya no trae Decal
`face`. `CosmeLook.setFace` creaba su Decal `face` (o, sin imágenes, la cara dibujada con marcos) **encima**
de esa cara: dos caras superpuestas = dos bocas. Y al hablar, `ActorLife` (fase 4 de las cinemáticas)
abría la mandíbula de la cabeza dinámica (`JawDrop`): la boca de debajo se movía sola.

No era un Decal repetido ni la textura de Cosme (las 4 PNG tienen una sola boca: comprobado).

## El arreglo (en la raíz)

* `shared/FaceKit.cleanHead`: antes de poner la cara de Cosme se quitan `FaceControls`, la cara pintada en
  la malla (`TextureID = ""`), los `SurfaceAppearance` y cualquier Decal que no sea el único `face`.
  Lo llama `CosmeLook.setFace` cada vez (vestir, cambiar de emoción, `refresh`, el cliente al hablar).
* Hablar: la boca se abre cambiando la imagen del **mismo** Decal (`cosme_face_talk`, nueva) o, sin
  imágenes, el marco `Talk` de la cara dibujada sustituye al de su emoción (`CosmeLook.flap`, desde
  `ActorLife`). Para los que tienen cara propia, `ActorLife` ya **nunca** toca `JawDrop`.
* `scripts/test-cosmelook.luau` lo comprueba con una cabeza dinámica de mentira (`FakeRig` con
  `DynamicHead`) y con la clásica, en los dos modos (dibujada / imágenes): 1 boca callado, en cada
  emoción, hablando con la boca abierta y cerrada, y al vestirlo otra vez.

Pendiente del dueño: subir la cara nueva (`bash scripts/upload-cosme.sh`, solo sube las que faltan). Hasta
entonces Cosme habla sin mover la boca, pero nunca con dos.

## Revisión del resto (de las vistas)

| Qué | Estado |
|---|---|
| Proporciones (R15 de bloques, cabeza clásica) | bien; el pelo de punta da la silueta de científico |
| Pelo plateado frío suave, cejas separadas | bien (test-cosmelook «reglas del dueño») |
| Gafas en la frente | bien; la cinta queda justo encima de las cejas, sin taparlas |
| Bata abierta, camiseta negra, colgante, bolis en el bolsillo izquierdo | bien |
| Manos | de piel, sin la bata encima (la plantilla deja la mano transparente) |
| Pistola de rayos con tubo morado, aparato de muñeca | bien, sin atravesar el cuerpo en reposo |
| Colores frente a la hoja de concepto (`docs/cosme/cosme-hoja.png`) | iguales (`CosmeLook.Colors`) |

Nada de esto se ha visto en Roblox: solo en las vistas previas y en las pruebas de Lune.
