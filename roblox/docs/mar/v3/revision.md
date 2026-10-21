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
