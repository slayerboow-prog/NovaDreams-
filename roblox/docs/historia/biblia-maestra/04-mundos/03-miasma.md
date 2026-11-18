# Biblia Maestra · Volumen IV · 3. MIASMA — «La Calma»

> Estado: **concepto preliminar** (nivel 1). Antes de construir, este archivo se desarrolla al nivel de Valmar y Tefra
> y lo aprueba el dueño. **Sustituye al generador común** (`PlanetCity` + `MiasmaKit`) por una gramática propia.

## 0. Concepto
**La idea.** Miasma era el Filtro del Telar: su niebla limpiaba el aire de los ocho mundos. Hoy, la niebla es veneno.
La gente vive en ciudades **colgadas de cables** sobre un mar verde, sin tocar nunca el suelo. Debajo, olvidado, el
Anclaje Seis. Más abajo, el Fondo: una máquina tejedora que respira. Cuando llega la Calma, la niebla se vuelve
dulce, la gente sonríe demasiado y nadie tiene miedo.

**Imagen guía.**
> Cinco discos de metal y cristal, unidos por pasarelas transparentes, cuelgan de un pico violeta con cables gruesos
> como troncos. Globos de gas tiran de casas de madera pintada. Debajo, un mar de niebla verde con relámpagos dentro.
> Por un hueco de la niebla se adivina una ciudad oxidada e inclinada, con hogueras: el Seis. Todo es hermoso y nadie
> mira hacia abajo.

**Capas:**

| Capa | Regla de lectura |
|---|---|
| **El Fondo tejedor** | **Lo antiguo respira:** órganos de bronce, fuelles, tubos como bronquios |
| **Anclaje Siete** (arriba) | **Lo de arriba cuelga:** discos, cables, globos y cristal; nada apoya en el suelo |
| **Anclaje Seis** (abajo) | **Lo caído se inclina:** todo está torcido 12°, oxidado y remendado con máscaras |
| *(ocupación)* La Calma | **Lo calmado sonríe:** niebla lila dulce, pantallas con caras amables, cero ruido |

## 1-10. Identidad

| Capa | Desarrollo |
|---|---|
| Arquitectura | **Discos** (plataformas circulares de 80-140 studs) con aro de luz turquesa, colgados de cables. Pasarelas de cristal con barandilla. Casas ligeras de madera pintada (verde agua, amarillo, coral) colgadas de globos. Nada de piedra. |
| Asentamientos | **Anclaje Siete** (la capital, los discos de arriba); **Barrio Lastre** (el disco pobre y más bajo, el de los filtros); el **Anclaje Seis** (la ciudad caída hace once años, inclinada, con hogueras, que respira con filtros caseros); granjas de globo sueltas |
| Cultura | Una sociedad que vive de **no mirar abajo**: el Seis no se nombra. El oficio de filtrador es sagrado. Racionamiento de aire limpio (Pía). Culto a la **Gran Veleta**: si gira, hay que cerrar ventanas. El Gran Corte se recuerda como «el año en que el aire se cerró». |
| Vestimenta | Máscaras de filtro de latón con cristales redondos (cada familia decora la suya); arriba, ropa ligera de colores; abajo, en el Seis, capas de tela y máscaras remendadas. Los de la Calma, sin máscara y sonrientes. |
| Tecnología y transporte | **Góndolas de cable**; cazas remendados (la Defensa, Mara); globos de gas; la Refinería; filtros caseros. Ascensores de cable entre discos. |
| Fauna y flora | Medusas de gas que flotan entre los discos; musgo amarillo en los picos violetas; bestias de la niebla; **Velados de Miasma:** siluetas sin máscara que respiran la niebla, con el pecho lleno de niebla luminosa. |
| Luz y clima | Luz verdosa difusa de día, relámpagos verdes dentro de la niebla, la marea de niebla que sube con el pulso, lluvia ácida. **La Calma:** luz lila suave y sin sombras. |
| Música y sonido | Cristal frotado, pads que respiran (el ritmo de una respiración), viento en los cables y el chirrido de las góndolas. **La Calma:** música de ascensor dulce, sin percusión. |

## Edificios emblemáticos
1. **El Fondo** (Sello). Máquina tejedora de bronce bajo la niebla: una sala del tamaño de una catedral con fuelles de
   40 studs que respiran y tubos que suben hacia la niebla. Es la mazmorra-jefe de Andrés.
2. **La Gran Veleta.** Una veleta de 60 studs en lo alto del disco central: el símbolo de Anclaje Siete.
3. **El Anclaje Seis.** Ciudad inclinada 12°, con la antena (`Miasma_Antena`) y la tumba de Solis.
4. **La góndola de la niebla** (`Miasma_GondolaNiebla`). Cabina de latón que baja por un cable entre relámpagos.
5. **La Refinería.** Una torre con una llama permanente.
6. **El Disco de la Calma** (ocupación). La plaza central, cubierta de pantallas con caras sonrientes.

**Paleta:** latón y bronce (Metal, 181-140-80); cristal (Glass, 160-220-210); madera pintada (WoodPlanks, verde agua,
amarillo, coral); niebla verde (Atmosphere, 120-170-110); la Calma en lila (200-180-230); el aro turquesa en Neon
(60-220-200). **Prohibido:** piedra, basalto, adobe y hielo.

## Sometido frente a liberado

| Zona | Sometido (la Calma) | Liberado | Pleno |
|---|---|---|---|
| Anclaje Siete | Sonrisas, pantallas, niebla lila sobre los discos | Pantallas apagadas, gente con miedo y viva, máscaras de nuevo | Fiesta de las veletas |
| Anclaje Seis | Hogueras, aislamiento | Góndolas regulares arriba y abajo | Nuevos cables y el Seis reconstruido recto |
| La niebla | Verde y tóxica | **Blanca y respirable por zonas** cerca del Fondo | El cielo se ve por primera vez |

## Traducción a Roblox (resumen)
- **Gramática propia** (`World/Miasma/Layout`): discos colgados unidos por pasarelas y cables, en altura. **No hay
  manzanas ni calles.**
- **Se conserva:** las anclas `Miasma_Plataforma`, `Miasma_Taller`, `Miasma_Torre`, `Miasma_Gondolas`,
  `Miasma_GondolaNiebla`, `Miasma_BordeLastre` y `Miasma_Antena`; las toxinas (`PlanetHazard`).
- **Se sustituye:** el barrio de `PlanetCity`.
- **Riesgo:** la caída al vacío. Se mantiene el rescate existente («si caes a un hueco»).

## Aprobación preliminar del dueño
- M1: concepto y capas.
- M2: los discos colgados como gramática.
- M3: los emblemas.
- M4: la paleta.
