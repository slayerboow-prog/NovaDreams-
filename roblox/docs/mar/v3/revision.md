# Fondo marino v3: revisión plano a plano (vista previa frente a `docs/mar/v3-objetivo.md`)

Las vistas previas salen de `scripts/map/orillas-export.luau` (el MISMO código del juego: `shared/Sea/ShoreReef`,
`Ocean.sample`, `OceanBiomes.look`, la plaza de Nácara) dibujado en Blender por `scripts/map/orillas_preview.py`
con las mallas y texturas subidas. Cada ronda se mira entera y se apuntan TODOS los fallos; los arreglos van al
código del juego (no a la vista previa), salvo los marcados «(vista previa)».

## Ronda 0 (prueba del dibujo, planos 1 y 2)

- Peces de arrecife pegados a la cámara, enormes, tapando el plano → los bancos se apartan ≥ 16 studs de la
  cámara (en el juego SeaLife ya los aparta a 9 de ti).
- El buceador era una «T» negra → maniquí tumbado con los brazos delante (vista previa: el avatar de verdad es el
  del jugador).
- Esponjas amarillas grandes = piezas de Lego; cuerno de ciervo morado y grande = una mano → esponjas más
  pequeñas y de colores apagados, cuerno de ciervo en ocres y naranjas.
- **El suelo**: el grano agrietado del Salt de Roblox, a esta escala, parece baldosas o barro seco (es lo que se
  ve en la captura-1 del dueño) → la arena del fondo pasa a **Snow** teñido de dorado (grano fino y blando).
- **Server**: los «discos», «bolas» y «losas» de las capturas del dueño eran piezas del servidor:
  `OceanBuilder.coralGardens` (cúpulas de bola, mesas de cilindro, abanicos de disco), `jardinEscarlata` (troncos
  de cilindro, abanicos de lámina de 7×6×0,3, bolas), `arcoCoral` (11 bolas en fila) y `jardinLuz` (tubos de Neon).
  Fuera: arrecife compuesto, relieve del terreno y mallas del kit.

## Ronda 1 (los 6 planos)

1. Orilla: una cosa blanca y enorme en el medio (vista previa: una mota pegada a la cámara). Tiras marrones
   rectangulares en la arena = tablones: eran las ondas de arenisca del relieve → ondas del mismo material que el
   fondo (la onda la da la forma). La concha blanca suelta parece un cubo → menos conchas y más pequeñas. Lajas
   oscuras y planas = las «losas» de las capturas → sin lajas en lo poco hondo.
2. Arrecife: racimos pequeños y sueltos, mucha arena vacía; afloramientos de basalto = manchas negras →
   afloramientos más grandes y altos de caliza/roca, 9–14 corales más grandes por racimo, más arrecife
   (umbral 0,58 → 0,52).
3. Repisa: un campo de patatas (cantos y rocas porosas por todas partes) y ninguna caída → parcela nueva
   «Ledge» en el borde de la plataforma (murete de roca de 3 bolas grandes de pizarra/roca, repisa detrás) con
   abanicos, esponjas y corales fríos encima.
4. Kelp: el que mejor se ve. El suelo entre los tallos, vacío, y las cáusticas a 10 m parecían baldosas → más
   pradera, algas anchas y cantos; cáusticas más tenues cuanto más hondo (en el juego, ReefZoneFx).
5. Nácara: la ciudad se lee bien, pero el primer plano es arena plana con piedras sueltas y a 37 m está
   iluminado como a 2 m (vista previa) → dunas anchas (radio 14–22) en la arena, luz que baja con la
   profundidad en la vista previa.
6. Noche: la medusa y las anémonas brillan bien; el resto, igual que el 2 → mismos arreglos.

## Ronda 2 (los 6 planos)

1. Orilla: ya no hay tablones ni losas; la arena ondula (dunas). Sigue con el centro algo vacío entre la pradera
   cercana y los racimos lejanos → matas de pradera sueltas por la arena (1–3 por parcela de arena).
2. Arrecife: mucho mejor (racimos grandes y variados), pero un coral cerebro de ~8 studs morado parece un globo
   detrás del buceador → tope de alto por especie (cerebro 3,2, blando 3,6, cuerno 4,2). Manchas de roca con
   bordes de polígono (vista previa: un material por cara de 2 studs; en Roblox el terreno mezcla los materiales).
3. Repisa: se ve un parche de caliza clara y pizarra oscura que parece papel recortado, y NO se ve la caída (el
   talud de Ocean bajaba ~10° y no tenía borde) → escalón de hasta 10 studs justo después de ShelfEnd, a tramos
   (Ocean.LedgeDrop, con el mismo ruido que elige la parcela «Ledge»), y el murete de roca y pizarra de tono
   parecido, en el filo.
4. Kelp: un tallo tapa medio plano (la cámara estaba dentro del bosque) → el plano se toma desde un pasillo de
   arena (en el juego, el jugador elige dónde nadar). Cáusticas ya tenues a 10 m.
5. Nácara: dunas y un racimo de coral en el primer plano; la ciudad se lee. Los cerebros morados juntos
   parecen cojines → con el tope de alto y la mezcla de especies.
6. Noche: solo 3 anémonas brillan → setas de luz (1–2 por arrecife) que brillan de noche.

## Ronda 3 (los 6 planos)

1. Orilla: casi igual que la 2: las matas de pradera eran «pequeñas» (LOD de 48 studs en el móvil) y el plano
   medio seguía liso → la pradera pasa al LOD mediano, más pradera junto a la costa (umbral 0,52 → 0,42 a menos de
   140 studs de tierra) y más cantos/corales sueltos en la arena (45 % → 60 % de las parcelas).
2. Arrecife: ya no hay globo; se lee como arrecife. Casi todo morado y cian, y la roca oscura bajo los corales
   parece una sombra → corales cálidos hasta ~17 m (antes, fríos desde ~11 m) y afloramientos de caliza clara.
3. Repisa: ya hay borde y relieve, pero los corales del borde con la paleta fría pura (azul) parecen piedras
   azules → tonos apagados de agua honda (verdes, pardos, malvas) y abanicos rojos y violetas.
4. Kelp: desde el pasillo se ven las columnas de kelp y un racimo de coral delante: bien.
5. Nácara: primer plano todavía de arena y piedras → alrededor de Nácara (460 studs) también arrecife y kelp
   (umbrales 0,55 y 0,5).
6. Noche: sin cambios (las setas de luz entraron después de volcar esta ronda; van en la 4).
Presupuesto: con la pradera mediana el plano 3 llegaba a 719 mallas (tope del móvil: 700) → LOD mediano del
móvil de 80 a 68 studs y SeaBiome planta de cerca a lejos (si llega al tope, lo que falta es lo de lejos).
Fidelidad: en el juego el decorado y los peces no dan sombra (CastShadow = false): la vista previa ya no se la
pone (las rondas 1–3 sí la tenían).

## Ronda 4

Las seis vistas ya encajan con el objetivo salvo: el cuerno de ciervo grande y de cerca parece una mano (kelp,
arrecife) → menos y como mucho 3 studs. Plano 5 a 120 studs del centro no enseñaba la ciudad entera.

## Ronda 5 (Nácara, encargo nuevo: la ciudad tiene que leerse como una civilización)

- Antes (fase 1, `docs/mar/nacara-fase1-vista-previa.png`): suelo vacío y plano, cúpulas sueltas, pocas cosas.
- Ahora: jardines de coral densos hasta 180 studs del centro, un anillo de peñascos con agujas de roca de 16–38
  studs (235–330 studs), seis agujas de nácar con anillos de perlas que brillan detrás de los barrios
  (`NacaraDecor.skyline`), los corales de NacaraDecor sobre el relieve y con el grano Salt, y nada de juego
  pisado (`ShoreReef.cityBlocked`). Plano 5 desde 170 studs y algo por encima.
- Fallos que quedan: los peñascos de pizarra delante salen oscuros (vista previa: además, la veta de roca a
  esta escala parece baldosas); el basalto casi negro se quitó del anillo.
- Vista previa más fiel: el material del terreno es el que más se repite en 6×6 studs (Roblox mezcla los
  vóxeles; antes, bordes de polígono).

## Final: `docs/mar/v3/plano-1.jpg` … `plano-6.jpg`

Mismo código que se publica (decorado, relieve, LOD y tope del móvil). Hojas: `antes-despues.jpg` (antes = la v125
aproximada: Salt agrietado y plano, decorado suelto de SeaBiome en trozos de 14 studs hasta 56 de la cámara; sin
las piezas de bola del servidor) y `rondas.jpg` (cada plano en las 4 rondas).

### Presupuesto (cámara en 5 playas; `scripts/test-mar.luau` y `test-reefzone-camera`)

| | Móvil | Ordenador |
|---|---|---|
| Mallas a la vista (radio 120 / 170; LOD 48 · 68 · 120) | 431–587 (tope 700; en «Low»: 450 y 75 % de distancia) | 1189–1610 (tope 1500, de cerca a lejos) |
| Mallas del plan por 200×200 studs (densidad 1) | 928–1322 | |
| Relieve del terreno (servidor, una vez al arrancar) | 61 527 bolas + 18 850 bloques en ~67 000 parcelas | |
| Cáusticas | 9 láminas de 30 studs (4 rayos por segundo) | |
| Suelo liso en pantalla (rayos, 5 playas) | 21–32 % (tope 55 %) | |

### Lo que se verá PEOR en Roblox que en la vista previa

1. **La arena «Snow» de Roblox teñida no se ha visto nunca**: aquí es grano fino; el Snow 2022 de Roblox tiene su
   propio dibujo (grumos y brillo). Si en el móvil parece nieve o algodón, se vuelve a Salt cambiando el material
   en TerrainBuilder, OceanBiomes (Floor) y ShoreReef.
2. **El terreno de Roblox es de vóxeles de 4 studs**: las ondas de 2,2 studs pueden quedar en bultos blandos o
   desaparecer; las bolas pequeñas salen más redondas y bajas. Los bordes de material se mezclan (aquí, polígonos).
3. **Sin sombras**: el decorado y los peces no dan sombra (como aquí en la ronda 4), los corales «flotan» un poco.
4. **La bruma**: aquí es lineal hacia el color de la zona; Roblox mezcla su niebla del agua (WaterColor y
   transparencia) con Atmosphere: el azul puede ser más plano y lo lejano verse menos.
5. **Cáusticas**: 9 láminas planas a la altura del fondo; sobre bultos, partes flotan o quedan dentro de la arena,
   y la orientación del dibujo entre láminas no se ha comprobado en Roblox (puede haber costuras).
6. **Corales con material Salt**: llevan el grano agrietado encima del color; a poca profundidad y de día pueden
   verse como tiza.
7. **LOD**: las cosas aparecen al acercarse (48, 68 y 120 studs en el móvil); con agua muy clara se nota.
8. **Peces**: aquí, quietos y en formación; en el juego nadan en banco y se apartan de ti.
9. **El buceador** es un maniquí de bloques; el avatar del jugador será otro.
10. **Haces de sol y motas**: aquí, tiras y puntos; en Roblox, Beam y partículas (más suaves).

## v127.1 · lo que dijo el servidor de verdad (sonda `mar-v3-sonda` en la v127)

- **El «Snow» teñido dominaba el fondo** (el riesgo 1 de la lista de arriba): podía verse como nieve, y Snow
  es además el material de Nivalis y de la nieve del invierno. La arena del fondo vuelve a ser **Salt dorado**
  en TerrainBuilder, Ocean.planBand, OceanBiomes (Floor), ShoreReef (ondas, dunas y talud) y
  ShoreReliefBuilder; Snow ya no está en TerrainPalette.Sea ni en Reserved. test-mar lo vigila.
- **«0,0 studs» en el Jardín Escarlata y el Laberinto de Kelp**: la sonda medía con rayos, y en estas pruebas
  la física no corre y el terreno recién escrito no siempre se ve con `workspace:Raycast` (ya lo apuntaba
  `scripts/cloud/_comun.luau`). Ahora mide en vóxeles (`ReadVoxels`: el vóxel sólido más alto de cada columna
  y su ocupación) y cuenta el material de ARRIBA, el que se ve. Comprobado fuera de Roblox: el plan sí pone
  relieve en los dos sitios (8 y 5 rellenos en 40×40).
- **El kelp, más relieve**: cada parcela de kelp lleva su roca (pizarra o roca) y la mitad, una loma de arena;
  antes, solo la mitad tenía una roca pequeña.
- Sin cambiar: Playa Dorada no lleva relieve de ShoreReef porque cae en el Cañón de Dorada (su terreno es de
  World/ReefZoneBuilder); la sonda admite un sitio plano.
