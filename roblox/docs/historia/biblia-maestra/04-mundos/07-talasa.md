# Biblia Maestra · Volumen IV · 7. TÁLASA — «La fosa»

> Estado: **concepto preliminar** (nivel 1). Se desarrolla al nivel de Valmar y Tefra y lo aprueba el dueño antes de
> construir. **Sustituye al generador común** (`PlanetCity` + `TalasaKit`).

## 0. Concepto
**La idea.** Tálasa era el Ancla del Telar: en su fosa, el Nudo ata los Hilos. Allí se ejecutó el Gran Corte, y allí
acaba todo lo que se pierde (R5). Es un mundo de océano, con ciudades sobre pilotes y bajo cúpulas. El coral negro
que trepa por todo es el Coro creciendo bajo el agua. Allí morirá Kael.

**Imagen guía.**
> Cubiertas blancas sobre pilotes, a catorce metros del mar, unidas por pasarelas; en medio, solo agua. Un faro con un
> anillo de luz. Balsas de tablas y lona de refugiados. Bajo la superficie, la luz se filtra en columnas hasta una
> cúpula de cristal medio inundada, y más abajo, la oscuridad de la fosa, donde algo enorme se mueve. Coral negro
> trepando por los pilotes.

**Capas:**

| Capa | Regla de lectura |
|---|---|
| **El Nudo tejedor** | **Lo antiguo ata:** nácar, cabos de piedra trenzada, anillos que sujetan corrientes de luz |
| **Abisalia** (superficie) | **Lo vivo flota:** pilotes, pasarelas, blanco y lona |
| **Las cúpulas** (estaciones) | **Lo hundido resiste:** cristal, compuertas estancas, presión |
| *(ocupación)* El coral negro | **Lo negro trepa:** coral que corroe y crece hacia la luz |

## 1-10. Identidad

| Capa | Desarrollo |
|---|---|
| Arquitectura | Cubiertas blancas sobre pilotes, pasarelas, lonas tensadas como velas; bajo el agua, cúpulas de cristal con costillas de acero y compuertas redondas. Todo curvo para resistir el agua. |
| Asentamientos | **Abisalia** (Las Balsas y el Faro); **la Plaza de las Pecas**; **la Cúpula Honda** (hundida, la de Coria); **la Estación Abisal «Umbral»** (en la fosa); el Archipiélago Suspendido |
| Cultura | El **Consejo de Mareas** en el Faro; los buceadores son la élite; la cuerda de perlas en la puerta (Bruma: una perla por cada muerto); el cálculo «diez mil por mil» como ley no escrita; el Gran Corte como culpa de Tálasa, que lo ejecutó en el Nudo, y la gente que no quiere saberlo. |
| Vestimenta | Trajes de neopreno con marcas de brillo (las «pecas» que brillan), ropa blanca de lona arriba, el uniforme blanco y azul de Coria. |
| Tecnología y transporte | Submarinos pequeños, el Tubo (ascensor submarino), escafandras con presión y oxígeno, sónar; barcos de la flota. |
| Fauna y flora | Ballenas, el Leviatán (lomo lejano), jardines de algas, peces luminosos; **coral negro** (el Coro bajo el agua); **Velados de Tálasa:** buzos ahogados con coral negro en la escafandra. |
| Luz y clima | Sol blanco sobre el mar, tres lunas, columnas de luz bajo el agua, la oscuridad de la fosa; tormentas oceánicas. **Liberado:** la fosa azul (`Tal03` ya lo dice). |
| Música y sonido | Graves profundos, cantos de ballena procesados, crujidos de presión, el sónar; el silencio del agua tras la muerte de Kael. |

## Edificios emblemáticos
1. **El Nudo** (Sello). Una sala tejedora de **nácar** en el fondo de la fosa: anillos de piedra trenzada que sujetan
   corrientes de luz (los Hilos). La compuerta del Nudo (S11) es la **compuerta de Kael**. Es la mazmorra-jefe de
   Coria.
2. **La Estación Abisal «Umbral»** (`Talasa_Estacion`, `Talasa_EstacionDentro`, `Talasa_CompuertaFaro`). Cúpula del
   Consorcio construida sobre el punto donde volvió Irene. Las doce cápsulas.
3. **El Faro de Mareas** (`Talasa_Faro`). El Consejo, con su anillo de luz.
4. **La Cúpula Honda.** Ciudad sumergida que Coria selló con mil personas dentro. Mazmorra 1.
5. **Las Balsas y el Muelle** (`Talasa_Muelle`, `Talasa_Plaza`).
6. **La boya** que pide ayuda desde hace seis años.

**Paleta:** blanco de lona y cubierta (Fabric/SmoothPlastic, 236-240-240); nácar tejedor (Pearl/Glass, 230-225-240);
agua (Water); acero de cúpula (Metal, 150-160-170); coral negro (Basalt/SmoothPlastic, 20-20-30 con brillo
morado); pecas luminosas (Neon, cian). **Prohibido:** piedra seca, adobe, hielo y madera viva.

## Sometido frente a liberado

| Zona | Sometido | Liberado | Pleno |
|---|---|---|---|
| Abisalia | Coral negro en los pilotes, refugiados en las balsas | Coral que se desprende, mercado abierto | Fiesta de las perlas (una perla por cada vivo) |
| La fosa | Oscura | **Azul** | Corrientes de luz visibles |
| Cúpula Honda | Sellada | Abierta, con un memorial | Rescate de restos (R5) |

## Traducción a Roblox (resumen)
- **Gramática propia** (`World/Talasa/Layout`): superficie sobre pilotes y un mundo bajo el agua con cúpulas.
- **Se aprovecha y se audita:** el océano y el buceo (`OceanService`, `DivingService`) y lo que se hizo para Nácara y
  Tálasa (`NacaraBuilder`, `ReefZoneBuilder`).
- **Se conserva:** las anclas `Talasa_Plataforma`, `Talasa_Muelle`, `Talasa_Plaza`, `Talasa_Faro`, `Talasa_Estacion`,
  `Talasa_EstacionDentro` y `Talasa_CompuertaFaro`.
- **Se sustituye:** el barrio de `PlanetCity`.

## Aprobación preliminar del dueño
- TA1: concepto y capas.
- TA2: pilotes y cúpulas.
- TA3: los emblemas (el Nudo y la compuerta de Kael).
- TA4: la paleta.
