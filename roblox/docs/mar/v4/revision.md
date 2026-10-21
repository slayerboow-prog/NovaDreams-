# Fondo marino v4 — revisión de los planos (vistas previas, NO es Roblox)

Objetivo: `docs/mar/v4-objetivo.md` (lo que dijo el dueño de la v3: «mucha mejor calidad y más de TODO,
muchísima más profundidad y muchísima más actividad»). Todo va detrás de `Config.Sea.V4` (apagado: el juego
publicado sigue con la v3 / v127.1 hasta que el dueño apruebe estos planos).

Las vistas previas salen del MISMO código del juego (`scripts/map/orillas-export.luau` con `MAR_V4=1` →
`scripts/map/orillas_preview.py`): el plan del fondo (ShoreReef y DeepReef), la roca del veril, lo que crece en
la pared (con el mismo «rayo hacia la pared» que SeaBiome), la vida con los números de SeaLife y la luz de
OceanBiomes. Las estelas de los peces son una PISTA de movimiento: no están en el juego.

## Rondas

| Ronda | Qué falló (crítica) | Qué se cambió |
|---|---|---|
| 0 | Plano 3: desde detrás del filo no se veía la pared; una cúpula de roca enorme en el centro. Plano 7: el fondo de la fosa, Salt agrietado = baldosas; ni rastro de pared. Plano 8: el pedestal de la torre, una bola con «puerta» (choza). Estelas blancas demasiado fuertes. | Cámaras nuevas de 3 y 7; fango claro en la fosa (zona «Gran Veril»); estelas tenues; rocas del veril como esferas lisas. |
| 1 | Plano 3: el voladizo hacía un iglú encima del filo. Pocas cosas que brillen al pie de la pared. | Voladizo con el centro a la altura del filo y hacia fuera; más setas y anémonas de luz abajo; lo que brilla, también de día a más de 24 m. |
| 2 | Plano 3: la cara de la pared era una lámina lisa con un solo bulto; casi desnuda. Plano 8: las bolas de los hitos, en el terreno de alturas, salían como silos. | 5–8 bultos por tramo de pared; el doble de cosas en la cara (44–68 por tramo, más arriba que abajo); las bolas de los hitos, como esferas. |
| 3 | Plano 3: de cerca, las gorgonias eran discos de frente; la pared, una mancha oscura. Plano 8: la roca del pedestal desnuda. | Plano general del veril (34 studs fuera); gorgonias algo menores; corales también por los lados del pedestal. |
| 4–5 | Los corales seguían siendo «de tiza» (Salt) y la arena de Salt dibujaba baldosas. | Corales con el material de lo que son (MarKit.V4Material) y el MaterialVariant «MarCoral» (pólipos); arena del fondo Sandstone dorada. |
| 6 | Casi ningún banco de peces salía en los planos (estaban detrás); plano 7 casi negro. | Cuatro bancos de 24 delante de la cámara (como al nadar hacia ellos), tiburón, delfines, raya en la arena; plano 7 mirando a la pared y hacia arriba. |
| 7–8 | Plano 3: el buceador tapaba el centro. Plano 7: poca luz propia. | Cámara del 3 a un lado; más cosas que brillan al pie (por debajo de 50 m). |

## Lo nuevo (todo con `Config.Sea.V4`)

- **Profundidad**: el Gran Veril (`Ocean.verilAt`): a tramos (~40 % del borde de la plataforma), una pared casi
  vertical de 50–65 m que cae a una fosa de 64–84 m, y la vuelta al talud. Lejos de los sitios, puertos, islas y
  del Cañón de Dorada. Zona nueva «Gran Veril» (luz que se apaga, sin megalodón). La roca (`DeepReef` →
  `World/DeepReliefBuilder`): respaldo, 5–8 bultos por tramo, voladizos, 150 cuevas, agujas de 20–40 m, arcos.
- **Más de todo**: burbuja de densidad (cosas pequeñas de más a < 34 studs en el móvil), corales gigantes,
  974 hitos en las orillas (torres de coral, ruinas, campos de almejas gigantes, pecios, arcos, peñascos,
  corros y círculos de kelp), y lo que crece en la cara del veril (gorgonias, esponjas, corales mesa, luz).
- **Actividad**: bancos de 24 (móvil) a 38 peces con boids que huyen de ti a 13 studs, el doble de bancos,
  bolas de cebo de vez en cuando, rayas pegadas a la arena, nubes de 6–10 medusas, tiburón de arrecife,
  delfines con malla, morenas asomadas en las rocas, nubecillas de arena al nadar pegado al fondo, burbujas de
  las grietas del veril, haces de luz que se mueven y cáusticas más fuertes.
- **Calidad**: corales con su material, «MarCoral», viñeta y color según la hondura (`SeaV4Fx`).
- **Mallas nuevas** (revisión de moderación en verde): AlmejaGigante, PecioBarca, Delfin, Tiburon,
  MorenaAsomada. Faltan por subir (`scripts/upload-mar.sh`); hasta entonces, su respaldo de piezas.

## Presupuestos (móvil)

| Qué | v3 | v4 |
|---|---|---|
| Mallas del fondo a la vista (la playa con menos / con más) | 431–587 | 490–669 (tope 700) |
| Piezas de vida (SeaLife) | 160 | 300 (son mallas, sin luces) |
| Rellenos de terreno al arrancar | 57 005 + relieve de orillas | 59 133 + relieve de orillas + 4 628 del veril |
| Haces de luz | 4 | 7 |
| Columnas de burbujas | 0 | 3 |

## Lo que se verá PEOR (o distinto) en Roblox que en estas vistas previas

1. **El Sandstone de Roblox no se ha visto nunca como fondo**: aquí es un grano blando; el de Roblox tiene vetas.
   Si no gusta, la arena vuelve a Salt cambiando `Ocean.SeaFloor` (y OceanBiomes, TerrainBuilder).
2. **La pared del veril en el juego son columnas de 16 studs** (el fondo de Ocean) con bolas de roca encima: de
   cerca se verán escalones rectos que aquí apenas se notan.
3. **Las cuevas no salen aquí** (solo una mancha oscura): en el juego son bocas de agua en la roca.
4. **El MaterialVariant «MarCoral» solo existe si se suben sus texturas** (`upload-mar.sh`) y se pasan a imagen
   (`scripts/textures/image-ids.sh`); sin él, los corales llevan Pebble, Limestone, Fabric, Concrete o
   SmoothPlastic (aquí no se han podido ver de verdad).
5. **La niebla de Roblox es por distancia**: el «azul que se oscurece hacia abajo» depende de la hondura de la
   cámara, no de cada punto; mirando a la fosa desde arriba se verá más plano que aquí.
6. **Las mallas nuevas no están subidas**: hasta que se suban, el delfín, el tiburón, la morena, la almeja y el
   barco son su respaldo de piezas.
7. **Sombras**: el decorado y los peces no dan sombra en el juego (aquí tampoco).
8. **LOD**: lo pequeño aparece al acercarse (34 studs la burbuja en el móvil); en la pared, la distancia cuenta
   también el alto.
9. **Peces**: aquí, quietos con estela; en el juego nadan en banco, huyen de ti y a veces giran en bola.
10. **El buceador** es un maniquí de bloques; el avatar del jugador será otro.
