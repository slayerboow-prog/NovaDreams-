# Fondo marino v4: «más de todo» (8 planos)

Lo que dijo el dueño de la v3: «Mucha mejor calidad y más de TODO, muchísima más profundidad y muchísima más
actividad y todo». La v4 va detrás de `Config.Sea.V4` (apagado hasta que el dueño apruebe los planos) y se
compara, plano a plano, con estos ocho. Mismas reglas que la v3 (docs/mar/v3-objetivo.md): FOV 70, 16:9, el
centro y el tercio de abajo libres del HUD, capas de primer plano / medio / fondo, nada de suelo liso y vacío.

## Las cuatro ideas

1. **Profundidad**: el mar tiene que parecer hondo y enorme. Plataforma poco honda → **el Gran Veril** (una
   pared de arrecife casi vertical de 30–60 m justo después del borde de la plataforma, con contrafuertes,
   repisas, cuevas y arcos) → **el azul hondo** (fosa al pie del veril de 60–90 m, y los cañones que bajan
   hacia el Abismo Silente y la Sima, de 70–140 m). Con la profundidad, menos luz, color más oscuro y más
   azul, y bioluminiscencia. El relieve es GRANDE (agujas de 20–40 m, arcos, voladizos), no bultos.
2. **Más de todo**: 2–3× decorado cerca de la cámara (una «burbuja» de densidad alrededor del jugador, lo
   diminuto solo muy cerca, grupos estáticos de lejos en una sola malla), hitos grandes cada ~100 studs
   (torres de coral gigantes, pecio, ruinas, esqueleto de ballena, campo de almejas gigantes, catedral de
   kelp) y especies de coral de 3–6× el tamaño de ahora.
3. **Mucha más actividad**: bancos de decenas de peces con boids que se apartan de ti, animales grandes que
   pasan (tortugas, mantas, tiburones tranquilos, delfines junto a la superficie, ballenas a lo lejos),
   cangrejos que andan, rayas sobre la arena, morenas asomando de las rocas, nubes de medusas, burbujas de
   las fumarolas, nubecillas de arena al nadar pegado al fondo, plancton, haces de luz que se mueven,
   cáusticas, todo meciéndose; peces y hondarios nadando en Nácara; y de vez en cuando algo que pasa (un
   banco que gira en bola, una ballena).
4. **Calidad**: nada de corales «de tiza» (Salt): MaterialVariant o mallas con textura y acentos que
   brillan; cáusticas más fuertes, haces de luz con volumen, color según la profundidad, viñeta bajo el
   agua y un tinte suave cerca de la superficie.

## Los planos

1. **Orilla, 2 m (Playa del Sur)**: arena con ondas, rocas y corales jóvenes; cangrejos, una raya sobre la
   arena, un banco de peces pequeños, nubecillas de arena, cáusticas fuertes.
2. **Arrecife, 10 m (Jardín Escarlata)**: torres de coral gigantes (3–6×), un banco grande en movimiento, una
   tortuga que pasa, haces de luz.
3. **El Gran Veril, 13 m**: el filo de la plataforma con la pared que cae al azul hondo; la mitad de abajo
   del plano es vacío azul oscuro con una manta pasando y la pared con corales y cuevas.
4. **Catedral de kelp, 10 m**: kelp gigante muy denso, haces de luz entre los tallos, una morena en una roca.
5. **Nácara, 37 m**: la ciudad con peces alrededor y hondarios nadando; jardines; agujas de nácar.
6. **El arrecife de noche**: bioluminiscencia y una nube de medusas.
7. **El borde del abismo, 60–90 m** (nuevo): el pie del veril, poca luz, setas y anémonas que brillan, la
   fosa que se pierde en lo oscuro.
8. **Un hito** (nuevo): el pecio o el esqueleto de ballena con su campo de almejas gigantes y peces.

## Cómo se comprueba

- Vistas previas de Blender con el MISMO plan del juego (scripts/map/orillas-export.luau y
  orillas_preview.py), con pistas de movimiento (estelas de los bancos y de los animales).
- Rondas de crítica en docs/mar/v4/revision.md, hojas de antes/después y de las rondas.
- Pruebas fuera de Roblox (test-mar, test-reefzone, test-reefzone-camera, con V4 encendido y apagado) y la
  sonda de la nube.
- Presupuestos: los del móvil de la v3 (700 mallas del fondo, tope de vida) más lo nuevo, contado.
