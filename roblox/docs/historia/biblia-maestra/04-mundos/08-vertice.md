# Biblia Maestra · Volumen IV · 8. VÉRTICE — «La Consola»

> Estado: **concepto preliminar** (nivel 1). Se desarrolla al nivel de Valmar y Tefra y lo aprueba el dueño antes de
> construir. **Sustituye al generador común** (`PlanetCity` + `VerticeKit`).

## 0. Concepto
**La idea.** Vértice era la Consola del Telar: desde aquí se gobernaban los Hilos. Hoy es la capital tecnológica de
una civilización que creyó haber alcanzado el futuro. Bajo una cúpula, una megaciudad donde todo pertenece a
MegaVerso y donde nadie protesta, porque nunca le falta nada. ÁGORA lo gobierna todo con una voz amable. Vértice cayó
y nadie lo notó.

**Imagen guía.**
> Torres de cristal oscuro con cantos de neón hasta perderse, carriles de tráfico aéreo, aceras-cinta luminosas. Una
> plaza con la estatua de bronce de un señor sonriente con su bolsa: el Primer Cliente. Pantallas gigantes con la
> misma cara amable. Gente limpia, en silencio, sonriendo. Encima, los paneles de la cúpula. Debajo de todo, a cientos
> de metros, el Vertedero Infinito. Y en el centro, la torre MegaVerso, de ciento veinte plantas, levantada sobre algo
> mucho más antiguo.

**Capas:**

| Capa | Regla de lectura |
|---|---|
| **La Consola tejedora** (la Torre) | **Lo antiguo gobierna:** aleación negra con circuitos azules que parecen raíces |
| **Distrito Cero** (Nivel Medio) | **Lo perfecto brilla:** cristal oscuro, neón, superficies sin una mancha |
| **El Nivel Bajo y el Rastro** | **Lo olvidado se amontona:** vertedero, bloques iguales, clínica gratis |
| *(ocupación)* ÁGORA | **Lo vigilado sonríe:** cámaras, pantallas y la misma cara |

## 1-10. Identidad

| Capa | Desarrollo |
|---|---|
| Arquitectura | Torres escalonadas de cristal oscuro, cubiertas colgadas a 90 studs sobre el Nivel Bajo, neón en los cantos, hologramas de ofertas. Abajo, bloques iguales (el Barrio Plantilla) y chatarra. |
| Asentamientos | **Distrito Cero** (la Plaza del Primer Cliente, la Avenida Rebajas); **el Rastro** (el Nivel Bajo); **la torre MegaVerso**; los **Astilleros Orbitales** (anillos sobre la cúpula) |
| Cultura | Todo se compra, incluido el oxígeno premium. La **Gran Memoria**: MegaVerso Eternidad vende la Marea como seguro de vida. Nadie decide nada: ÁGORA lo hace mejor. El museo de Abril guarda la historia borrada. El Gran Corte: el archivo de la Consola lo registró; MegaVerso lo enterró. |
| Vestimenta | Ropa limpia y de diseño con el logotipo de MegaVerso; uniformes de Atención al Visitante (Gil); en el Rastro, ropa reutilizada; los de la lista del Arca, con trajes blancos impecables. |
| Tecnología y transporte | Tren mag-lev, coches aéreos, ascensores ultrarrápidos (`Vertice_AscensorDentro`), drones de seguridad, pantallas; ÁGORA; el generador de grietas de la torre (`Ver02`). |
| Fauna y flora | Casi nada vivo: plantas de plástico, palomas de la cúpula; **Velados de Vértice:** ciudadanos impecables que siguen sonriendo con los ojos grises. |
| Luz y clima | Luz artificial perfecta de día y de noche, sin clima bajo la cúpula; abajo, niebla de vertedero. **Liberado:** pantallas apagadas, ventanas abiertas y la luz real que entra por los paneles rotos de la cúpula. |
| Música y sonido | Sintetizador limpio que se degrada; anuncios; la voz amable de ÁGORA; el zumbido del mag-lev; el silencio inquietante de una ciudad sin conversaciones. |

## Edificios emblemáticos
1. **La Consola** (Sello). Bajo la torre: una sala tejedora de **aleación negra** con circuitos azules como raíces,
   donde se gobernaban los Hilos. Aquí ocurren el cara a cara con Ithar en su cuerpo de ceniza (S13) y la apertura del
   Hilo a Oren. Es la mazmorra-jefe de ÁGORA.
2. **La torre MegaVerso** (`Vertice_Oficinas`). Ciento veinte plantas de cristal escalonado con el logotipo
   holográfico. Mazmorra 2: las plantas 60 a 120.
3. **La Plaza del Primer Cliente** (`Vertice_Plaza`). La estatua y la pantalla gigante.
4. **El Museo de la Luz** (`Vertice_Museo`, `Vertice_MuseoDentro`). La base de Abril.
5. **El Rastro.** El Nivel Bajo: la clínica gratis y el ascensor de mantenimiento. Mazmorra 1.
6. **La cúpula.** Paneles hexagonales. En el asalto (S12) se rompe.

**Paleta:** cristal oscuro (Glass, 30-35-45); neón de MegaVerso (Neon, magenta y cian); metal pulido (Metal,
200-200-210); bronce del Primer Cliente; aleación tejedora negra (Metal, 20-20-24 con venas azules); chatarra del
Rastro (CorrodedMetal). **Prohibido:** madera, adobe, hielo y piedra antigua a la vista (salvo en la Consola).

## Sometido frente a liberado

| Zona | Sometido (ÁGORA) | Liberado | Pleno |
|---|---|---|---|
| Distrito Cero | Pantallas con la cara de ÁGORA, silencio, cámaras | Pantallas apagadas, gente hablando en la calle, conversaciones | Huertos en las azoteas |
| La cúpula | Cerrada | Paneles rotos con luz real | Cielo abierto en el centro |
| El Rastro | Olvidado | Ascensores abiertos a todos | Clínica y mercado |

## Traducción a Roblox (resumen)
- **Gramática propia** (`World/Vertice/Layout`): ciudad **en niveles** (Bajo, Medio y Alto) con cubiertas colgadas y
  torres; la verticalidad es la identidad.
- **Se conserva:** las anclas `Vertice_Plataforma`, `Vertice_Plaza`, `Vertice_Avenida`, `Vertice_Museo`,
  `Vertice_MuseoDentro`, `Vertice_Oficinas` y `Vertice_AscensorDentro`; la deuda y la vigilancia (`PlanetHazard`).
- **Se sustituye:** el barrio de `PlanetCity`.

## Aprobación preliminar del dueño
- V1: concepto y capas.
- V2: la ciudad en niveles.
- V3: los emblemas (la Consola y la torre).
- V4: la paleta.
