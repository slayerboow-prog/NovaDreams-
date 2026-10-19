# Asteroides «AAA»: rocas de verdad que se rompen

Queja de Sebastián (capturas `docs/bugs/espacio-asteroides.png`): «los meteoritos se ven horribles
(bolas grises lisas); mejóralos mucho y que se rompan con física».

Imagen antes / después: `docs/espacio-aaa/asteroides-antes-despues.jpg`.

## Cómo se ven ahora

- **Nada de bolas.** Cada asteroide es una roca irregular hecha con 3-6 bloques girados que se pisan y
  cuñas encima (silueta facetada). Hay 6 siluetas: patata, losa, bloque, doble, astilla y piña.
- **Detalle:** cráteres (disco oscuro con borde claro), piedrecitas alrededor de los grandes (de chinas
  a rocas), materiales de roca (pizarra, basalto, roca, hielo en Escarcha) con colores por campo.
- **Vetas de mineral que brillan poco:** el Hierro estelar con un brillo metálico cálido, el Cobalto
  azul y el Cristal solar dorado (con cristales que asoman). Un asteroide vacío apaga sus vetas.
- **Polvo** fino flotando alrededor de los grandes.
- **Giran despacio** los cercanos.
- La misma roca en el servidor, en todos los móviles y en las pruebas (sale del id: `Asteroids.shape`).
- **Mallas de Blender (opcional):** `scripts/espacio/asteroides_blender.py` hace 6 rocas de malla
  (relieve, cráteres, textura de color y de normales, 2.400 triángulos). Hay que subirlas
  (`bash scripts/upload-asteroides.sh`, lo hace el dueño). Sin subirlas, el juego usa las de piezas,
  que ya se ven bien.

## Cómo se rompen

1. **Daño poco a poco:** el láser (1 impacto), un misil (4 impactos) o chocar con la nave lo dañan.
   Salen grietas naranjas que brillan (3 niveles) y, en el último, una luz cálida. Cada unidad de
   mineral que sale hace saltar lascas.
2. **Se parte:** al gastarse, el grande se parte en **3 medianos**, cada mediano en **2-3 pequeños**, y
   el pequeño se hace **polvo**. Los trozos salen hacia fuera con su impulso, su giro y algo de la
   velocidad del disparo o de la nave, y se frenan solos.
3. **Efectos:** fogonazo, nube de polvo, chispas, pedazos de roca que salen volando, un temblor de
   cámara pequeño si estás cerca y el ruido de la explosión.
4. **Los trozos se minan otra vez** (la mitad de mineral que un asteroide de su tamaño). Si nadie los
   toca, se van solos a los 75 s.
5. **Vuelve entero** a los 120 s (si hay una nave justo en su sitio, espera un poco). El campo siempre
   está lleno.

## Chocar con un asteroide

Ya no estalla la nave de golpe: **rebota** y el golpe se lo lleva el **escudo**, según la velocidad
(despacio, nada; a tope, mucho; a hipervelocidad te destruye). Lo que sobra va al casco. La velocidad
la mide el servidor (el cliente no puede rebajarla ni inventarla). El choque también agrieta la roca
(sin dar mineral).

## Contra trampas

- El servidor decide la vida de cada roca, el mineral (una sola vez por unidad, con las reglas de
  siempre: ritmo, bodega, distancia, zona segura) y los trozos.
- Con la bodega llena la roca se rompe igual, pero el mineral no cabe.
- El estado (qué está roto y dónde van los trozos) viaja como un texto corto en
  `ReplicatedStorage.AsteroidesEstado`; los pedazos de adorno, el polvo y las chispas los hace cada
  móvil (no gastan red).
- La misión «Pedido de mineral», la bodega y la venta siguen igual.

## Para el móvil

| Tope | Valor |
|---|---|
| Pedazos de adorno vivos a la vez (cada móvil) | 60 (los más viejos se quitan) |
| Trozos vivos en el servidor | 48 (si no, polvo) |
| Asteroides que giran | los 14 más cercanos, a 30 veces por segundo |
| Detalles (vetas, cráteres, piedrecitas) | solo a menos de 650 studs |
| Piezas por asteroide | 30 como mucho (unas 1.800 en total, y se cargan por zonas) |
| Servidor | sin bucles por fotograma: los trozos se mueven con una fórmula (posición según el tiempo) y la vuelta se mira una vez por segundo |
| Fuera del espacio | no corre nada |

## Archivos

- `src/shared/Cosmos/Asteroids.luau` — forma, daño, rotura, registro, topes (cuentas puras).
- `src/shared/Cosmos/AsteroidBuild.luau` — monta la roca en piezas (o con la malla).
- `src/server/World/SpaceWorld.luau` — los asteroides del campo.
- `src/server/Services/SpaceService.luau` — vida, mineral, rotura, vuelta y estado.
- `src/server/Services/AirCombatService.luau` — misiles contra rocas y choques de la nave.
- `src/client/Controllers/AsteroidFx.luau` — trozos, polvo, chispas, lascas, giro y LOD.
- `src/server/World/AsteroidMeshes.luau`, `src/shared/Cosmos/AsteroidAssetIds.luau`,
  `src/shared/Cosmos/AsteroidMalla.luau`, `assets/asteroides/`, `scripts/espacio/asteroides_blender.py`,
  `scripts/espacio/asteroides-dump.luau`, `scripts/upload-asteroides.sh` — las mallas de Blender.
- Pruebas: `lune run scripts/test-space.luau` y `lune run scripts/test-espacio-aaa.luau`.
