# Revisión del mapa: que todo tenga sentido

El dueño vio zonas amontonadas (captura `captura-dueno-amontonado.jpg`): trozos de calle, negocios,
casas, torres, aparcamientos y pistas todo junto y sin calles. Esta revisión mide el mapa entero con
una prueba automática, arregla las causas en el código que genera la ciudad y deja la prueba para que
no vuelva a pasar.

## La prueba: `scripts/test-mapcoherence.luau`

```
rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
lune run scripts/test-mapcoherence.luau X.rbxl [--json salida.json] [--list] [--top N]
```

Lee la ciudad construida (`Workspace.Town`) y busca en toda la isla:

| Tipo | Qué es | Gravedad |
|---|---|---|
| `calle_suelta` | trozo de calzada que no se une a la red (componentes conexos del asfalto de `Streets` y `MainRoads`) | crítico (en una isla sin coches: info) |
| `calle_cortada` | un trozo de calle que solo sigue por un lado (calle que no va a ninguna parte) | crítico si acaba dentro de una manzana; si no, aviso |
| `calle_doble` | dos calles paralelas a 30–60 studs, con las aceras pegadas | aviso |
| `sin_acceso` | edificio, casa, negocio, aparcamiento, pista o sitio de ocio sin acera ni calzada cerca (cuenta su parcela, su aparcamiento o su plaza y el camino de acceso de los sitios de ocio) | crítico a más de 30 studs; aviso a más de 22 |
| `solape_edificios` | edificios metidos uno en otro (celdas de 2 studs dentro de paredes de los dos) | crítico desde 120 studs² o el 15 % del más pequeño; aviso desde 30 |
| `solape_usos` | suelo de un uso bajo el edificio o encima del suelo de otro (parque sobre aparcamiento…) | crítico desde 600 studs²; aviso desde 150 |
| `sobre_calzada` | edificio o suelo que tapa la calzada | crítico desde 48 studs² |
| `manzana_llena` | parte de la manzana construida | crítico por encima del 72 %; aviso si pasa del 45 % y del doble de lo normal en su distrito |
| `manzana_mezclada` | 4 usos fuertes o choques (casas + torres, casas + industria…) | crítico en una manzana pequeña |
| `zonificacion` | rascacielos sueltos en el centro fuera de la franja norte, manzanas enteras de aparcamiento | aviso |
| `sitio_en_manzana` / `sitio_en_calle` | zonas verdes y de ocio (parques vivos, Jardines, huertos, lago, camping, mercadillo, vóley playa, polideportivo, karting, skatepark), puerto espacial del islote y portal de la playa dentro de manzanas ajenas o sobre calles y aceras | crítico |

Falla si hay **algún crítico**. Imprime los problemas por distrito y los peores sitios (celdas de 250
studs; crítico 3 puntos, aviso 1). Con `--json` se pueden dibujar:

```
lune run scripts/map/export.luau X.rbxl DIR
python3 scripts/map/vista_cenital.py DIR/parts.tsv salida.jpg --issues coherencia.json --heat [--box x0,z0,x1,z1 --scale 1]
```

## Resultado

| | Críticos | Avisos | Piezas |
|---|---|---|---|
| Antes | **810** | 74 | 416 757 |
| Después | **0** | 18 | 365 332 |

Antes, por distrito (críticos): Oeste 378, Este 202, Universitario 129, Sur 43, Norte 28, Centro 23,
Playa Dorada 4, sitios de ocio en el campo 3. Casi todo era `sin_acceso` (783 unidades): casas, tiendas
y aparcamientos mirando a un hueco sin calle. Además 33 pares de edificios metidos uno en otro y 13
manzanas al 84–96 % en el centro, 4 trozos de arena tapando la calle de Playa Dorada.

Peores sitios antes: (2384, −2126) Este, (2892, −1144) Este, (−1627, −380) Oeste, (−2129, −1127) Oeste,
(−1627, 2625) Oeste, (2903, −629) Este.

Avisos que quedan (a propósito): 13 `calle_doble` (la cuadrícula a 45 studs de la circunvalación del
Distrito Financiero, de Los Pinos y de Playa Dorada: quitar esos tramos deja sin acera la Protectora, los
Jardines de la Plaza Mayor y la rampa de la estación de Cercanías de Los Pinos), las casas familiares
de Los Pinos (72 %, son de la historia), una residencia del campus, la boca de metro del parque del
Distrito Financiero y un cruce del final de la Calle del Puerto.

## Las causas y los arreglos (en el código que genera el mapa)

1. **Manzanas sin calle** (`Kit/Districts`). La rejilla de manzanas (`Districts.cells`) se hacía sin mirar
   las calles; luego `Kit/Grid` y `Kit/Connect` quitan los trozos de calle que no llegan a ningún cruce,
   y quedaban manzanas enteras en medio del campo. Además, fuera de la Ronda cada cuadra de 500 se parte
   en 4 manzanas con un hueco de 16 studs, y los edificios se ponían en los 4 lados: la mitad miraba al
   hueco. Ahora `Districts.lots` solo construye las manzanas que dan a una calle de verdad y anota sus
   lados con calle (`Sides`): casas, pisos, tiendas, villas, hoteles, facultades… solo miran a esos lados.
   Los lugares emblemáticos se eligen entre esas manzanas y su fachada da a una calle.
2. **Medias manzanas estrechas** junto a las avenidas del centro (80 studs): dos filas de 40 de fondo y
   hasta 16 plantas espalda con espalda, metidas una en otra, y rascacielos de 50–72 studs en ellas.
   Ahora el fondo de cada fila se recorta, las esquinas son de los lados largos, las filas son más bajas
   (5–9 plantas) y los rascacielos solo van en manzanas anchas.
3. **Zonificación del centro**: rascacielos sorteados en cualquier manzana y manzanas enteras de
   aparcamiento. Ahora los rascacielos quedan en la franja norte (junto al Distrito Financiero) y el
   resto son bloques de pisos con tiendas y parques (sin cambiar el sorteo: el resto del mapa no se mueve).
4. **Aparcamientos sin entrada**: dentro del patio de las manzanas de tiendas (ahora plaza peatonal) y
   detrás de los locales de ocio y los talleres (ahora al lado, los dos mirando a la calle). El campo de
   deporte va junto a la calle, con la grada detrás.
5. **Huecos entre manzanas y carreteras**: junto a la Ronda y las avenidas la cuadrícula se aparta 25–40
   studs; esa franja de hierba ahora es acera (`AceraManzana`), y los huecos de 16 studs entre manzanas,
   paseos peatonales (`Paseo`).
6. **Calles cortadas** (`Region.roads`): calles que cruzan una carretera en ángulo muy cerrado quedaban
   cortadas a unos studs de ella. Ahora se alargan hasta tocarla o se recortan hasta su último cruce.
7. **Sitios de ocio como islas** (`Kit/ZonasVerdes/Accesos`, nuevo): mercadillo, vóley playa,
   polideportivo, karting y skatepark tienen un camino de baldosas hasta la acera más cercana.
8. **Arena sobre la calle** (`Civic.beach`): la arena de Playa Dorada pasaba 30 studs del borde de la
   manzana y tapaba la circunvalación.

## Qué se ha movido

- No se mueve: casa familiar, Los Pinos, colegio de Los Pinos, garaje de Cosme, comisarías, bomberos,
  hospital, metro, Cercanías, aeropuerto, Valmar Centro, zonas verdes y de ocio, ni las calles de los barrios.
- El Colegio del Distrito Sur y el Instituto de Levante ahora miran al norte (su fachada sur daba a un
  paseo sin calle): sus marcas de la historia (`StorySpot`, `StoryArea`, `StoryProp`) van con ellos.
- Supermercados Norte, Sur, Poniente y Campus giran hacia su calle (unos 30–60 studs); la Armería del
  Puerto pasa a otra manzana del Distrito Sur (993, 2163); el cuartel del ejército (la nave más al este)
  pasa a (1044, 1504).
- Ya no están los 4 hoteles de la costa oeste que no tenían calle (quedan 4), ni las casas y villas que
  miraban a huecos sin calle: casas visitables 536 → 266, villas 60 → 28, viviendas en total
  1894 → 1202 (siguen sobrando para jugar). Parques vivos: 25 (eran 30).
- `docs/mapa/lugares.json` rehecho con `scripts/map/export.luau`.

## Imágenes (en esta carpeta)

- `mapa-entero-antes.jpg`, `mapa-entero-despues.jpg`: la isla desde arriba con el mapa de calor de los
  problemas (rojo crítico, naranja aviso).
- `*-antes-despues.jpg`: las peores zonas, antes y después: `centro-avenida` (la zona más parecida a la
  captura: torres apretadas en medias manzanas, el aparcamiento del hospital, el parque con su pista y
  los trozos de calle entre las medias manzanas, hacia (60, 750)), `centro-oeste`, `financiero`,
  `este-comercio`, `oeste-casas`, `universitario`, `norte-super`, `playa-dorada`, `sur-puerto`.

## Mapa grande del menú

Las calles y los edificios han cambiado, así que el dibujo del mapa grande (`textures/mapa/isla_*`) se
ha vuelto a renderizar con `scripts/map/blender_render.py` (la proyección `MapProjection` no cambia: la
cámara es la misma). **En la próxima publicación hay que volver a subir los trozos con
`scripts/upload-map.sh --force`.**
