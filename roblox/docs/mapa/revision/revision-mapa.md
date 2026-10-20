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
| Después | **0** | 50 | 364 750 |

Antes, por distrito (críticos): Oeste 378, Este 202, Universitario 129, Sur 43, Norte 28, Centro 23,
Playa Dorada 4, sitios de ocio en el campo 3. Casi todo era `sin_acceso` (783 unidades): casas, tiendas
y aparcamientos mirando a un hueco sin calle. Además 33 pares de edificios metidos uno en otro y 13
manzanas al 84–96 % en el centro, 4 trozos de arena tapando la calle de Playa Dorada.

Peores sitios antes: (2384, −2126) Este, (2892, −1144) Este, (−1627, −380) Oeste, (−2129, −1127) Oeste,
(−1627, 2625) Oeste, (2903, −629) Este.

Avisos que quedan (a propósito):
- 13 `calle_doble`: la cuadrícula a 45 studs de la circunvalación del Distrito Financiero, de Los Pinos
  y de Playa Dorada. Quitar esos tramos deja sin acera la Protectora, los Jardines de la Plaza Mayor y
  la rampa de la estación de Cercanías de Los Pinos, y cambiaría las calles (y con ellas el azar y las
  claves de todos los edificios: ver abajo).
- 5 `calle_cortada` por la misma razón (las calles no se tocan).
- 25 `sin_acceso` de aviso: casas y villas a 23–28 studs de la acera (jardín delantero).
- 4 `zonificacion`: rascacielos de antes en manzanas del centro fuera de la franja norte (se quedan
  para no cambiar claves de edificios).
- Las casas familiares de Los Pinos (72 %, son de la historia), una residencia del campus y la boca de
  metro del parque del Distrito Financiero.

## Las causas y los arreglos (en el código que genera el mapa)

1. **Manzanas sin calle** (`Kit/Districts`). La rejilla de manzanas (`Districts.cells`) se hacía sin mirar
   las calles; luego `Kit/Grid` y `Kit/Connect` quitan los trozos de calle que no llegan a ningún cruce,
   y quedaban manzanas enteras en medio del campo. Además, fuera de la Ronda cada cuadra de 500 se parte
   en 4 manzanas con un hueco de 16 studs, y los edificios se ponían en los 4 lados: la mitad miraba al
   hueco. Ahora `Districts.lots` sabe qué manzanas dan a una calle y por qué lados (`Sides`), y
   `Districts.tidy` quita las manzanas sin calle y los edificios, casas, villas y aparcamientos que no
   miran a ningún lado con calle.
2. **Medias manzanas estrechas** junto a las avenidas del centro (80 studs): dos filas de 40 de fondo
   espalda con espalda, metidas una en otra, y rascacielos de 50–72 studs en ellas. Ahora se queda la
   fila que da a la avenida y ningún edificio se mete en otro.
3. **Aparcamientos sin entrada**: dentro del patio de las manzanas de tiendas (ahora plaza peatonal) y
   detrás de los locales de ocio y los talleres (fuera). El campo de deporte va junto a la calle, con la
   grada detrás; los hoteles que miraban a un hueco se rehacen mirando a la calle.
4. **Huecos entre manzanas y carreteras**: junto a la Ronda y las avenidas la cuadrícula se aparta 25–40
   studs; esa franja de hierba ahora es acera (`AceraManzana`), y los huecos de 16 studs entre manzanas,
   paseos peatonales (`Paseo`).
5. **Sitios de ocio como islas** (`Kit/ZonasVerdes/Accesos`, nuevo): mercadillo, vóley playa,
   polideportivo, karting y skatepark tienen un camino de baldosas hasta la acera más cercana.
6. **Arena sobre la calle** (`Civic.beach`): la arena de Playa Dorada pasaba 30 studs del borde de la
   manzana y tapaba la circunvalación.
7. **Lugares emblemáticos** con la fachada a un hueco sin calle (o en una manzana sin calle): se rehacen
   mirando a la calle (o en la manzana libre más cercana de su distrito).

## Las partidas guardadas: claves de los edificios

Las partidas guardan los edificios por su clave (`InteriorService`: `<Tipo>_<X>_<Z>`, el centro del
edificio): viviendas compradas, alquiladas e iniciales (`data.Properties`, `data.Housing.Home`) y
negocios (`BusinessService`: locales `L:<clave>`, hoteles `H:x_z`). Por eso:

- **Los edificios que se quedan conservan su clave.** `Districts.build` construye cada manzana
  exactamente como antes (mismo orden y mismo `math.random`) y después, sin azar, quita lo que sobra
  (`Districts.tidy`); lo que hay que volver a construir con azar (lugares emblemáticos, campos de
  deporte, hoteles, plazas) va al final de `TownBuilder` (`Districts.finish`), cuando ya no mueve nada
  más. Las calles no cambian. Resultado: de los 2042 edificios con clave del mapa publicado, 1270 siguen
  igual, 772 se han quitado y 13 son nuevos (lugares emblemáticos girados).
- **Mapa de claves** (`src/server/Migrations/BuildingKeyMap.luau`, GENERADO): para cada clave quitada
  (772 edificios y 185 negocios), hasta 6 sustitutos del mismo tipo (casa↔villa, piso en un portal o
  un local), del mismo distrito si se puede y el más cercano primero. Se rehace así:

  ```
  lune run scripts/map/building-keys.luau MAPA_PUBLICADO.rbxl antes.json
  lune run scripts/map/building-keys.luau MAPA_NUEVO.rbxl despues.json
  python3 scripts/map/key-map.py antes.json despues.json --version 1
  ```

  (`scripts/map/data/claves-v1.json`: todas las claves del mapa de antes; son las mismas que las del
  `RealLifeSimulator.rbxl` publicado.)
- **Migración al cargar** (`Migrations/BuildingKeyMigration`, funciones puras, y
  `HousingService.migrateKeys`): cada vivienda de un edificio quitado se muda al primer sustituto con
  sitio (`PropertyService.relocate`: la misma planta y letra si vale y está libre; si no, la primera
  libre), con su contrato, precio, alquiler y deuda; «Ir a casa» va detrás. Si no hay sitio: se devuelve
  lo pagado (compra), se perdona la deuda (alquiler) o le llega otra vivienda inicial. El sitio
  guardado (`data.Position`) donde había un edificio quitado se borra (aparece en la entrada o en su
  cama). Un aviso al jugador. Una sola vez (`Housing.KeyMigration`, que pasa a la vida nueva); si el
  DataStore falla, no se toca nada y se vuelve a intentar en la próxima carga.
- **Negocios** (`BusinessService.migratePremises`, al arrancar el servidor): el registro entero de un
  local u hotel quitado (tipo, nombre, caja, género, empleados) pasa al primer sustituto libre; si no
  hay, se da de baja y lo que costó se devuelve a su dueño cuando entra (`Reembolsos`, con aviso).
- **Prueba**: `lune run scripts/test-buildingkeys.luau [MAPA.rbxl]` (la migración con datos de mentira;
  con el mapa, que toda clave de antes sigue o está en el mapa con un sustituto que existe).

## Qué se ha movido

- No se mueve: casa familiar, Los Pinos, colegio de Los Pinos, garaje de Cosme, comisarías, bomberos,
  hospital, metro, Cercanías, aeropuerto, Valmar Centro, zonas verdes y de ocio, las calles, ni los
  edificios de los barrios.
- El Colegio del Distrito Sur y el Instituto de Levante ahora miran al norte (su fachada sur daba a un
  paseo sin calle): sus marcas de la historia (`StorySpot`, `StoryArea`, `StoryProp`) van con ellos.
- Supermercados Norte, Sur, Poniente y Campus giran hacia su calle (unos 30–60 studs); la Armería del
  Puerto pasa a otra manzana del Distrito Sur (993, 2163).
- Ya no están los 4 hoteles de la costa oeste que no tenían calle (quedan 4, rehechos mirando a la
  calle), ni las casas y villas que miraban a huecos sin calle: casas visitables 536 → 263, villas
  60 → 35, viviendas en total 1894 → 1170. Parques vivos: 25 (eran 30).
- Los vecinos de la historia (`PropertyService`: viviendas de vecinos por sorteo fijo) pueden vivir en
  otra vivienda: la lista de viviendas ha cambiado.
- `docs/mapa/lugares.json` rehecho con `scripts/map/export.luau`.

## Imágenes (en esta carpeta)

- `mapa-entero-antes.jpg`, `mapa-entero-despues.jpg`: la isla desde arriba con el mapa de calor de los
  problemas (rojo crítico, naranja aviso).
- `*-antes-despues.jpg`: las peores zonas, antes y después: `centro-avenida` (la zona más parecida a la
  captura: torres apretadas en medias manzanas, el aparcamiento del hospital, el parque con su pista y
  los trozos de calle entre las medias manzanas, hacia (60, 750); no se puede saber el punto exacto por
  la foto), `centro-oeste`, `financiero`,
  `este-comercio`, `oeste-casas`, `universitario`, `norte-super`, `playa-dorada`, `sur-puerto`.

## Mapa grande del menú

Los edificios han cambiado, así que el dibujo del mapa grande (`textures/mapa/isla_*`) se
ha vuelto a renderizar con `scripts/map/blender_render.py` (la proyección `MapProjection` no cambia: la
cámara es la misma). **En la próxima publicación hay que volver a subir los trozos con
`scripts/upload-map.sh --force`.**
