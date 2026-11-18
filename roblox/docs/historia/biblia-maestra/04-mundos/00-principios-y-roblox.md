# Biblia Maestra · Volumen IV — Los mundos · 0. Principios y traducción a Roblox

> HEROES OF HISTORY · Referencia oficial.
> Este archivo fija las reglas comunes de la dirección de arte de los ocho mundos y cómo se construyen en Roblox.
> Cada planeta tiene su propio archivo (`01-valmar.md` … `08-vertice.md`).
> **Decisión del dueño (innegociable):** ningún planeta usa el mismo generador de barrios que otro cambiando colores,
> materiales o decoración. **Antes de construir un planeta, el dueño aprueba** su concepto visual, arquitectura,
> materiales, distribución de asentamientos y edificios emblemáticos (lista de aprobación al final de cada archivo).

---

## 1. Auditoría de cómo se construyen hoy los mundos

Revisado el 18-11-2026: `server/World/*`, `shared/Cosmos/*` y `docs/planetas/*`.

| Mundo | Cómo está hecho hoy | Veredicto |
|---|---|---|
| **Valmar** | **Ciudad moderna:** la del simulador de vida antiguo, con barrios, metro y calles (`TownBuilder`, `Kit/*`). **Asentamiento:** `Kit/Settlement`. **Tierras Exteriores:** 8 regiones (`OuterLandsBuilder`, `ValmarRegions`, `RegionLandmarks`). **Santuario del Bosque** con el **Árbol Ancestral** (`Kit/ForestSanctuary`, `Kit/AncientTree`, `SanctuaryService`). | Base aprovechable. Falta la capa antigua de los Tejedores y la capa de ruina de la Caída sobre la ciudad moderna. |
| **Tefra** | **Bastión Ceniza hecha a mano** (`TefraCityBuilder`, `shared/Cosmos/TefraCity`): 8 barrios, foso y canal de lava, 4 puertas, cúpulas malva frente a basalto militar | **Única y con identidad.** Se conserva y se amplía. |
| **Miasma, Siroco, Nivalis, Umbría, Tálasa y Vértice** | **El mismo generador** (`PlanetCity` + `PlanetCityBuilder`) con un «kit» por planeta (`MiasmaKit`, `SirocoKit`…) que cambia formas, colores y las mallas «Casa» y «Bloque» de cada planeta (`PlanetCityMeshes`, `docs/planetas/edificios/*Casa.jpg`, `*Bloque.jpg`) | **Es justo lo que el dueño prohíbe.** Hay que sustituirlo, planeta a planeta. |
| **Infraestructura común** | `PlanetWorld` (construir al acercarse), `PlanetSurface` (terreno y aterrizaje), `PlanetHazard` (desventaja), `PlanetJobs` (oficios), `EnvDirector` (cielo, luz y sonido por planeta), `PlanetService` | **Se conserva.** Es infraestructura, no arquitectura. |

### Qué se comparte y qué no
- **Se comparte (infraestructura):**
  - la carga por cercanía;
  - el aterrizaje;
  - el sistema de desventaja;
  - los oficios;
  - los servicios de PNJ;
  - el motor de escenas;
  - el sistema de estados del planeta (§4).
- **No se comparte nunca (arquitectura e identidad):**
  - la gramática de distribución (cómo se ordena una ciudad);
  - las piezas de construcción;
  - los materiales y paletas;
  - los edificios emblemáticos;
  - la vegetación;
  - los enemigos;
  - la vestimenta;
  - la luz;
  - la música.

---

## 2. Las diez capas de identidad de cada mundo (obligatorias)

Cada archivo de planeta las desarrolla todas, más dos secciones finales: la traducción a Roblox y la lista de
aprobación.

| # | Capa | Pregunta que responde |
|---|---|---|
| 1 | Lenguaje arquitectónico | ¿Cómo se reconoce un edificio de este mundo en una foto de 1 segundo? |
| 2 | Ciudades, aldeas y asentamientos | ¿Cómo se ordena la gente en el territorio? |
| 3 | Edificios emblemáticos | ¿Qué cinco o seis siluetas recordará el jugador? |
| 4 | Materiales y técnicas | ¿Con qué y cómo construyen? |
| 5 | Cultura, tradiciones, organización social | ¿Cómo viven, en qué creen, quién manda, cómo recuerdan el Gran Corte? |
| 6 | Vestimenta | ¿Cómo se viste cada grupo social? |
| 7 | Tecnología y transporte | ¿Qué máquinas usan y cómo se mueven? |
| 8 | Fauna, criaturas, vegetación | ¿Qué vive aquí, incluidos sus Velados propios? |
| 9 | Luz, clima, atmósfera | ¿Cuál es su luz, a cada hora y en cada estado? |
| 10 | Música y sonido | ¿Cómo suena? |
| 11 | Sometido frente a liberado | ¿Qué cambia, y cómo se ve, cuando se libera? |

**Prueba de identidad.** Se ponen ocho capturas sin interfaz, una por mundo, y se mezclan. Una persona que no conoce
el juego tiene que poder agruparlas por planeta solo por la forma de los edificios, sin mirar los colores. Si no
puede, el planeta no está aprobado.

---

## 3. La capa de los Tejedores (el hilo común, que tampoco se repite)

Los ocho mundos fueron sembrados por los Tejedores y guardan un Sello. Para que el jugador sienta que comparten
historia **sin que se parezcan entre sí**, la arquitectura tejedora de cada mundo es **una variación de la misma
idea**, adaptada a su función:

| Constante tejedora (en todos) | Variación por mundo |
|---|---|
| Piedra viva que crece guiada: curvas, nunca ángulos rectos | El material de esa piedra cambia con el mundo: perla en Valmar, basalto tallado en Tefra, bronce en Miasma, vidrio fundido en Siroco, hielo eterno en Nivalis, madera viva en Umbría, nácar en Tálasa, aleación negra en Vértice |
| Venas de luz azul de Sello | La forma de las venas: raíces, hilos de cobre, tubos que respiran, letras de arena, rayos de un sol, savia, corrientes, circuitos |
| El símbolo de «puerta» (una línea vertical) y el de «Hilo cortado» (una grieta atravesada por una línea) | Grabado según la técnica local |
| Espirales y nudos | Su escala: en Valmar, terrazas; en Vértice, una torre |

Así, cuando el jugador encuentra una ruina tejedora en Siroco, reconoce el parentesco con Valmar, pero nunca confunde
un mundo con otro.

---

## 4. Estados del mundo: sometido, liberado y pleno (sistema común)

La directiva exige que la liberación **se vea**. Cada planeta, y cada zona dentro de él, tiene un estado. Este es un
**sistema común**, y lo que cambia en cada estado es propio de cada planeta.

| Estado | Cuándo | Qué cambia (en general) |
|---|---|---|
| **Sometido** | Hasta el Acto V del planeta | Paleta apagada; Velados y la presencia del Heraldo; asentamientos cerrados; la música del planeta con su capa de tensión |
| **Liberado** | Tras el Acto V | La luz propia del planeta con el azul del Sello; asentamientos que se reconstruyen por fases; los PNJ salvados en su sitio; rutas y servicios abiertos |
| **Pleno** | Sello en estado Pleno (Vol. III §5.3) | Detalles finales: fiestas, flores, monumento al Heraldo vencido o a los caídos |

**Reconstrucción por fases.** La liberación no es instantánea. Cada asentamiento tiene tres fases visibles, que avanzan
con las secundarias del planeta y con el tiempo:
1. **Escombros retirados.**
2. **Andamios y mercados.**
3. **Reconstruido.**

**Cómo se hace en Roblox** (auditoría previa del §7.6 del Vol. V):
- El estado se guarda por jugador en la memoria del mundo (`WorldState`, claves `<Planeta>.Estado` y
  `<Planeta>.<Zona>.Fase`).
- **Lo personal** se pinta en el cliente de cada jugador, ampliando `StageSets` (decorados condicionales):
  - las capas «sometido» y «liberado» de cada zona;
  - los PNJ salvados;
  - la luz y el cielo (`EnvDirector` con su perfil por estado).
- **Lo compartido:** los servidores muestran el estado canónico de cada planeta.
  - Mientras un jugador no ha liberado un planeta, ve su propia versión sometida en las zonas de historia (en su
    cliente).
  - Las zonas sociales (puertos, mercados) son comunes y siguen el estado mayoritario o el canónico: se decide en la
    auditoría técnica.

---

## 5. Traducción a Roblox: método de construcción

### 5.1 Un constructor propio por planeta
Cada planeta tiene **su propio módulo de construcción**, como ya tiene Tefra con `TefraCityBuilder`:
- `World/<Planeta>/Layout`: **la gramática de distribución propia**. Por ejemplo, Miasma son discos colgados y
  pasarelas, no manzanas con calles.
- `World/<Planeta>/Kit`: **piezas propias** (mallas y piezas), con nombres del planeta.
- `World/<Planeta>/Emblemas`: cada edificio emblemático construido a medida.
- `World/<Planeta>/Estados`: las capas sometido, liberado y fases de reconstrucción.
- `shared/Cosmos/<Planeta>City`: los **datos** (sitios de la historia «<Planeta>_…», refugios y anclas de escena)
  conservan sus nombres actuales. **Las misiones existentes no se rompen:** los sitios «Tefra_…», «Miasma_…» y demás
  siguen existiendo con el mismo nombre, en su nueva arquitectura.

### 5.2 De dónde salen las piezas
1. **Mallas a medida** (`MeshPart`) para las siluetas únicas: edificios emblemáticos, piezas tejedoras y vegetación
   propia. Se modelan en Blender (hay conexión con Blender en este proyecto) y se suben como mallas. Las imágenes y
   mallas nuevas las sube el dueño o la clave de Open Cloud, según el flujo de publicación del proyecto.
2. **Piezas paramétricas** (`Part` y `WedgePart` por código) para lo repetitivo: muros, pasarelas, tejados simples.
   Siempre con la gramática propia del planeta.
3. **Materiales de Roblox** (más `MaterialVariant` propios cuando haga falta): cada planeta tiene su paleta cerrada de
   materiales (ver cada archivo).
4. **Biblioteca de Roblox (Creator Store):** solo si encaja con la identidad y tras revisión: buscar, previsualizar e
   insertar con cuidado. Nunca como sustituto de los emblemas.

### 5.3 Presupuesto técnico (móvil primero)

| Concepto | Límite por planeta (zona de ciudad cargada) |
|---|---|
| Piezas (`Part` + `MeshPart`) visibles | ≤ 15.000 en la zona de streaming del jugador |
| Triángulos por malla | ≤ 10.000 (emblemas ≤ 20.000, divididos en piezas) |
| Texturas | 1024 px máximo; ≤ 40 texturas únicas por planeta |
| Luces dinámicas | ≤ 30 activas a la vez cerca del jugador; el resto, `Neon` y `SurfaceLight` desactivadas por distancia |
| Partículas | ≤ 12 emisores visibles a la vez |
| Carga | Por cercanía (`PlanetWorld`, ya existe) y `StreamingEnabled`. **Nunca** forzar la ciudad bajo la nave ni aclarar la bruma de vuelo (regla del proyecto). |

### 5.4 Orden de construcción (decisión del dueño)
1. **Valmar** y **Tefra:** desarrollo completo en este paso y construcción tras la aprobación del dueño.
2. Después, uno a uno, en el orden de la campaña: Miasma, Siroco, Nivalis, Umbría, Tálasa y Vértice. Cada uno con su
   archivo desarrollado al nivel de Valmar y Tefra y aprobado antes de construir.
3. **Oren:** anexo propio antes de la producción de «La puerta».

---

## 6. Material antiguo que se reutiliza (y lo que no)

`docs/planetas/diseno-mundos.md` (el diseño «Ragnarock» de los siete mundos) contiene buena geografía, nombres de
ciudades y barrios, fauna y oficios. **Se reutiliza lo que encaja con la Biblia Maestra** y se anota en el registro
(RC-032 a RC-036).

| Se conserva | Se descarta o se reinterpreta |
|---|---|
| Nombres de ciudades: Bastión Ceniza, Anclaje Siete, Puerto Calcina, Fortaleza Albor, Raíz Honda, Abisalia, Distrito Cero | La «clasificación 13+»: el público es 17+ |
| Barrios, biomas, fauna, oficios y desventajas | Las ventajas de pago (multiplicadores del pase premium): chocan con «sin pay-to-win», y se revisan en el Vol. VI |
| La guerra de Tefra contra su luna **Ovilla** (encaja con «los que no quieren luchar en su guerra») | La «invasión del Dominio Talar» de Miasma: la sustituye la Calma |
| El Enjambre de Umbría (máquinas de la Compañía Torca) y el coral negro de Tálasa, reinterpretados como señales de la Marea | Cosme como inventor que experimenta: ahora es el niño que cayó por una prueba del Consorcio |
