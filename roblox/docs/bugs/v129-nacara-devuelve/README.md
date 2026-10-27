# Bug (dueño, v129): al acercarse a este barrio oscuro bajo el mar le devuelve a Nácara

Captura: captura.png (Llanura Sumergida, 35 m, Hondario con branquias). Cada vez que se acerca a las casas oscuras con ventanas amarillas, aparece otra vez en la ciudad del mar.

Pista: HondarioService.goHome se llama tras morir (watch → Died). Comprobar si algo le mata o le saca al acercarse (zona prohibida, presión, colisión, CityBounds/rescate, teletransporte de distrito de Nácara, StreamingEnabled), y por qué el barrio se ve negro (sin texturas/luz). Pendiente para el lunes.

## Resuelto (v130, commit ade7a7f)

- **No morías:** el vigilante anti-enterrados (`PositionService.checkBuried`) daba por «caído por debajo del
  mapa» a quien bajara de y = −150 (`SafeGround.SafeMinY`), sin esperar, y `SafeSpot.rescue` te llevaba a tu
  cama: la concha de Nácara. El barrio de la captura es **Valmar Hundida** (el barrio de los faroles del Cañón de
  las Catedrales, `World/OceanBuilder`), con el suelo a −174 (48 m): al bajar hacia sus casas pasabas de −150.
  Lo mismo pasaba en la fosa del Veril (−232) y en la Sima del Kraken (−560).
  Arreglo: en el mar, «por debajo del mapa» es por debajo de SU fondo (`SafeGround.minYAt`, `SafeSpot.belowMap`).
- **Negro:** sus casas, tejados y torre eran de Slate (y la calle Cobblestone, la fuente Marble, las puertas
  Wood). `World/UserMaterials` cambia esos materiales en todo el juego por las fotos oscuras de los packs y solo
  las aclara en la ciudad: bajo el mar, pizarra casi negra × luz azul tenue = negro sin textura. Ahora es
  Sandstone claro y SmoothPlastic, como Nácara.
- Prueba: `scripts/test-valmar-hundida.luau`.
