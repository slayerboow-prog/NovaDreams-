# Plan · El sueño de ser guerrero espacial (16-11-2026)

Petición del dueño (16-11-2026): el juego deja de ser una vida en la ciudad y pasa a ser **la historia de alguien que
sueña con convertirse en guerrero espacial**. El combate es de MMO (cuerpo a cuerpo, armas blancas y habilidades;
las armas de fuego quedan en segundo plano). Cada fase se publica cuando el dueño dice «publica».

## Decisiones tomadas (sin preguntar, como pide el dueño)

1. **Un solo terreno**: el continente de caza (las 8 regiones de shared/Cosmos/ValmarRegions) se pega a la costa de la
   isla: de la ciudad se sale andando a las regiones, sin mar ni puentes de por medio. El mar queda por FUERA del
   continente (allí siguen los barcos y la pesca). La regla antigua «no tocar el mar de Valmar» queda anulada.
2. **Ciudad submarina → Tálasa**: Nácara y la civilización de los Hondarios (World/Nacara*, Services/SeaCivService,
   NacaraService, HondarioService, shared/Sea/Nacara y Civ) se mudan al fondo del planeta océano Tálasa.
3. **Ciudad más pequeña**: se queda lo que usa la historia (casa familiar, escuela, hospital, espaciopuerto y
   aeropuerto, comisaría, tiendas que salen en misiones, el laboratorio de Cosme). Lo demás se retira por fases.
4. **Escuela**: las asignaturas pasan a ser la formación de guerrero espacial: combate cuerpo a cuerpo, armas blancas,
   habilidades (las del arco del Atacar), espíritu, supervivencia en planetas, pilotaje y naves.
5. **Historia**: de bebé a adulto, siempre con el sueño: ver por primera vez una nave, la escuela, el examen de cadete,
   la primera caza en las regiones, el primer planeta y el juramento de guerrero espacial.

## Decisión del dueño sobre el mar (16-11-2026, pregunta respondida)

**Quitar el mar hondo de Valmar.** Nácara y los Hondarios se mudan a Tálasa; el resto del mar hondo de Valmar (buceo,
megalodón, Abismo Silente, ruinas de Valmar la Vieja, Cañón de las Catedrales, arrecifes, eventos de mar) se elimina.
El continente de caza queda pegado a la ciudad; los barcos y la pesca pasan al mar de fuera del continente.

## Fases

| Fase | Qué | Estado |
|---|---|---|
| A | Nácara y los Hondarios al fondo de Tálasa (fuera del mar de Valmar) | por hacer |
| B | Continente de caza pegado a la ciudad: un solo terreno; mar por fuera | por hacer |
| C | Ciudad más pequeña: inventario de barrios y edificios; quitar lo que la historia no usa | por hacer |
| D | Escuela: asignaturas de guerrero espacial (habilidades, armas blancas, espíritu, planetas, naves) | por hacer |
| E | Historia nueva: capítulos y misiones del sueño de ser guerrero espacial | por hacer |

Hecho ya (16-11-2026, publicado en v162): combate de MMO (objetivo automático, arco de habilidades, espíritu),
despliegue de barcos y aviones desde el teléfono donde está el personaje, todas las habilidades para el dueño.

## Pasos de la fase A (Nácara → Tálasa)

1. Tálasa: una FOSA hondonada (shared/Cosmos/Talasa rawHeight) en un sitio libre (p. ej. local 0, 1650: lejos de
   Abisalia y los islotes), suelo llano a la profundidad de la plaza (134 studs bajo el agua) y talud suave.
2. shared/Sea/Nacara y Civ: el centro pasa a Tálasa (mundo); lo que miraba el mar de Valmar (Ocean.floorY, Surface,
   meters, ShoreReefs, PoiById.Ruinas) pasa a la superficie de Tálasa (agua en Origin.Y + WaterY). La posada de La
   Burbuja y Bartolo pasan a coordenadas de la plaza (junto a la fosa). La ruta de buceo sale del borde de la fosa.
3. Construcción: NacaraService/SeaCivService construyen cuando el terreno de la fosa está hecho (PlanetWorld.chunk de
   esos trozos) y PlanetWorld, al terminar Tálasa, vuelve a poner el aire de las cúpulas (NacaraBuilder.terrain…).
4. Ir allí: la vida hondaria y el botón del modo pruebas entran en Tálasa con PlanetService (cielo, luz, atributo
   Planeta), no con un teletransporte suelto. Quitar el punto de Nácara del mapa de Valmar.
5. Nadar en Tálasa: comprobar Swimming/AgeMotion/SeaMotion (usan la superficie de Valmar, −2) y DivingService.
6. Pruebas: test-nacara, test-hondario, test-mar, test-swim (solo esas).

## Pasos de la fase B (un solo terreno)

1. shared/Cosmos/ValmarRegions.Frame y OuterLands: el borde de dentro del continente pasa a ser la costa de la isla
   (CityPlan.Coast) en lugar del rectángulo ±5800; el mar queda fuera del borde de fuera (Band).
2. Quitar el mar hondo: OceanBuilder, DeepReliefBuilder, ShoreReliefBuilder, ReefZoneBuilder, SeaBiome, SeaLife,
   SeaEvents, OceanService, DivingService (lo del mar de Valmar), megalodón (SeaBeastService), POIs del mar.
3. Barcos (shared/Boats.isSea) y pesca: al mar de fuera. Puentes y campamentos: ya no hacen falta puentes.
4. Pruebas: test-tierras, test-boats, test-bestias y las que dependan de lo quitado (se retiran con ello).

## Notas para retomar

- Mundo: CityPlan (Coast, Bounds ±5000/±4400), OuterLands + OuterLandsBuilder (marco X ±5800, Z −5200..5800,
  1800 de ancho), shared/Sea/OceanBiomes (el mar de Valmar), TerrainBuilder (agua de −14 a −2).
- Historia: shared/LifeStory (Chapters, Misiones/*, Guiones/*, SchoolLife, Subjects, QuestionBank, Locations).
- Pruebas ligeras: solo las de lo que se toca (scripts/test-*.luau).
