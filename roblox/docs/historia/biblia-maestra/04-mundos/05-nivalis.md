# Biblia Maestra · Volumen IV · 5. NIVALIS — «La noche larga»

> Estado: **concepto preliminar** (nivel 1). Se desarrolla al nivel de Valmar y Tefra y lo aprueba el dueño antes de
> construir. **Sustituye al generador común** (`PlanetCity` + `NivalisKit`).

## 0. Concepto
**La idea.** Nivalis era el Faro del Telar: vigilaba el borde, y su faro era un sol artificial. Fue el único mundo que
votó contra el Gran Corte, y sus fareros vieron apagarse las luces de los refugiados. Hoy es una corte medieval de
piedra y hielo bajo siete años de noche, sostenida por un collar de faroles que mantiene fuera a lo que vive en la
oscuridad.

**Imagen guía.**
> Noche total con aurora verde y rosa. Una fortaleza de piedra gris con almenas nevadas y torres-farol en las
> esquinas. Dentro, casas de tejado empinado con un farol ámbar en la cumbrera, en círculos de luz uno cada diez
> metros. Fuera de la luz, negro absoluto, y algo que se retira con ruido de uñas sobre hielo. En lo alto de la
> montaña, un anillo metálico enorme y apagado: el sol.

**Capas:**

| Capa | Regla de lectura |
|---|---|
| **El Faro tejedor** (el sol y su montaña) | **Lo antiguo vigila:** hielo eterno tallado, anillos, lentes, rayos grabados |
| **Fortaleza Albor** (la corte) | **Lo noble se eleva:** piedra, agujas, arcos de hielo y estandartes |
| **Los círculos de faroles** | **Lo vivo está en la luz:** cada farol es una frontera |
| *(ocupación)* La regencia de Casimir | **Lo prohibido canta:** la oscuridad tiene voces |

## 1-10. Identidad

| Capa | Desarrollo |
|---|---|
| Arquitectura | Piedra gris con almenas, **tejados muy empinados** con nieve, agujas, arcos de hielo tallado, vidrieras. La tecnología avanzada se esconde dentro de lo medieval: faroles con mecanismo, calefacción en los muros. |
| Asentamientos | **Fortaleza Albor** (la capital, dentro de la Muralla Vieja); el **Palacio de Escarcha** (la corte de Casimir, en la ladera norte); **las Minas de cristal** (la resistencia de Ámbar); el **Monasterio de Hielo**; aldeas de faroleros en el Valle de Albor |
| Cultura | Casas Nobles en lucha por el cristal; el **gremio de faroleros**, que fundó Casimir; las **canciones prohibidas** de Madre Copo (el lamento de Oren, en otro idioma); la vela por los que no vuelven; la Estatua Rota de la Reina Liv. **El Gran Corte:** Nivalis votó en contra y lo guarda en canciones. |
| Vestimenta | Nobles con capas de lana bordada y armiño de lanudo, coronas finas de plata; faroleros con abrigo de lana, guantes y farol al cinto (Tila); guardia del Regente con armadura azul y estandartes; la resistencia con ropa de minero. |
| Tecnología y transporte | Trineos, faroles con manivela, el sol artificial (anillo-orbe), ascensores de mina; la Corona del Sol (los mandos del sol, en el palacio) |
| Fauna y flora | Lanudos (rebaños de lana), musgo de nieve, el Bosque de Escarcha; **las criaturas de la oscuridad:** mentes de Oren, sombras alargadas que cantan (giro 6); **Velados de Nivalis:** los «tocados», con escarcha gris en la piel. |
| Luz y clima | Noche eterna, luz de luna azul, aurora verde y rosa, círculos ámbar de los faroles, ventiscas dos veces al día. **Sol encendido** (Acto I): luz amarilla de reserva. **Sello encendido** (Acto V): luz azul-blanca. |
| Música y sonido | Coro femenino lejano y celesta; viento; el chasquido del farol al encenderse; las criaturas cantando en el idioma de Oren. |

## Edificios emblemáticos
1. **El sol artificial y el Faro** (Sello). Un anillo tejedor de **200 studs** de diámetro en la cumbre, con un orbe y
   lentes de hielo eterno. Dentro, el corazón del Sello. Es la mazmorra-jefe de Casimir (S7).
2. **El Palacio de Escarcha.** Agujas de piedra y hielo; el salón del banquete (Acto III); los **sótanos de los
   tocados**; la **torre de Osric**, la más alta, sin luz en siete años.
3. **La Plaza de los Faroles** (`Nivalis_Plaza`), con la Estatua Rota de la Reina Liv.
4. **La Torre del Farolero** (`Nivalis_TorreFarol`).
5. **La Biblioteca de los Ecos** (`Nivalis_Biblioteca`). De hielo, con agujas transparentes; Madre Copo y las
   canciones.
6. **Las Minas de cristal.** Galerías de cristal azul; el cuartel de Ámbar. Mazmorra 1.

**Paleta:** piedra gris (Slate, 130-134-140); nieve (Snow); hielo (Ice/Glacier, 180-220-240); ámbar de farol (Neon,
255-180-80); azul del Regente (Fabric, 40-60-120); aurora (Atmosphere y partículas verde y rosa); luz de Sello
(azul-blanca). **Prohibido:** adobe, lava, madera viva y latón.

## Sometido frente a liberado

| Zona | Sometido (la noche) | Liberado (Sello encendido) | Pleno |
|---|---|---|---|
| Fortaleza Albor | Círculos de faroles, toque de queda | Luz de día, faroles apagados («No sé qué hacer con las manos», Tila) | Festival de la primera aurora con sol |
| Palacio | Estandartes del Regente, sótanos | La corona de Ámbar, la torre de Osric iluminada | — |
| Valle de Albor | Negro absoluto | Nieve brillante y lanudos pastando | Deshielo en el valle bajo |

## Traducción a Roblox (resumen)
- **Gramática propia** (`World/Nivalis/Layout`): ciudad amurallada en ladera, con calles en pendiente y **círculos de
  luz como unidad de diseño**.
- **Se conserva:** las anclas `Nivalis_Plataforma`, `Nivalis_Plaza`, `Nivalis_TorreFarol`, `Nivalis_Biblioteca`,
  `Nivalis_Mirador` y `Nivalis_Pasadizo`; el frío (`PlanetHazard`).
- **Se sustituye:** el barrio de `PlanetCity`.
- **Clave técnica:** la oscuridad tiene que ser oscura de verdad en móvil, sin que se vea la nada: niebla negra
  cercana y luces locales.

## Aprobación preliminar del dueño
- N1: concepto y capas.
- N2: la ciudad en ladera y los círculos de luz.
- N3: los emblemas (sol, palacio, torre de Osric).
- N4: la paleta.
