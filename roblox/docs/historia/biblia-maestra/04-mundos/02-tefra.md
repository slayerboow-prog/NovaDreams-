# Biblia Maestra · Volumen IV · 2. TEFRA — «La Forja»

> HEROES OF HISTORY · Referencia oficial. Nivel de detalle: **construible**.
> Estado: **concepto para aprobación del dueño** (lista al final).
> Parte de lo que ya existe: **Bastión Ceniza**, hecha a mano (`TefraCityBuilder`, `shared/Cosmos/TefraCity`,
> `docs/planetas/tefra-ciudad.md`). Se conserva y se amplía, sin rehacerla.

---

## 0. Concepto en una página

**La idea.** Tefra era la Forja del Telar: un mundo de colinas suaves y ciudades redondas, donde «nada tenía esquinas».
- Hace unos cien años, las familias pobres se fueron a minar **Ovilla**, su luna.
- Hace **noventa años** empezó la guerra entre el **Dominio de Bastión** y Ovilla. La guerra se comió el planeta: las
  bombas despertaron los volcanes y la forja del Dominio perforó el Sello, la **Lanza**, que sujetaba la corteza.
- Ahora el Coro ha llegado por esa herida y ha convertido las fundiciones en **cadenas de montaje de Velados**.

**Tres capas, tres gramáticas:**

| Capa | Época | Gramática | Regla de lectura |
|---|---|---|---|
| **La Forja tejedora** | Hace 3.000 años | Basalto tallado en curvas, bandas de hilo de cobre con venas azules, salas-yunque bajo tierra | **Lo antiguo sostiene** |
| **Tefra Redonda** | Antes de la guerra | Cúpulas de yeso malva, ventanas redondas, la Gran Cúpula, calles curvas | **Lo de antes es redondo** |
| **El Dominio** | La guerra (90 años) | Búnkeres de basalto, esquinas duras, murallas con cañones, chimeneas, puentes de hierro | **Lo militar es de esquinas duras** |
| *(ocupación)* El Coro | 1.212-1.214 | Estructuras grises orgánicas que crecen sobre las fundiciones, como cera fundida | **Lo gris crece encima de todo** |

La regla «lo antiguo es redondo, lo militar es de esquinas duras» **ya está construida** en Bastión Ceniza. La Biblia
la conserva y le añade la capa de abajo (la Forja tejedora) y la de encima (la ocupación).

**Sensación buscada.** Un planeta entero convertido en máquina de guerra. Escala industrial, calor, ruido, y entre
bombardeo y bombardeo, gente que sigue haciendo pan.

**Imagen guía:**
> Cielo malva y naranja. Ovilla ocupa medio cielo, con fogonazos de artillería en su cara oscura. Abajo, la muralla
> negra de Bastión Ceniza con sus dieciséis torres, el foso de lava brillando y chimeneas que escupen brasas. Dentro,
> entre búnkeres, las cúpulas malva del Barrio del Ovillo, partidas por las bombas, y sobre ellas el esqueleto de la
> Gran Cúpula de Tefra Redonda, como la costilla de un animal enorme. En el centro, en los Pozos de Magma, una torre
> con una lente apunta al cielo: la Lanza de Corvo. Y debajo de ella, invisible todavía, la columna tejedora que
> sostiene el planeta.

---

## 1. Lenguaje arquitectónico

### 1.1 La Forja tejedora 🆕
- **Forma:** salas excavadas en basalto con bóvedas de nervios, columnas-yunque de sección circular, escalinatas en
  espiral descendente.
- **Ornamento:** **bandas de hilo de cobre** incrustadas en la piedra, como costuras que unen bloques; dentro, venas
  azules de Sello. Espirales de nudo en los umbrales.
- **Escala:** colosal y subterránea.
- **Dónde está:** bajo los Pozos de Magma (la Lanza) y bajo la Caldera Roja, en ciudades tejedoras tragadas por la lava
  («Bajo la Caldera hay ciudades del Tefra antiguo», diseño antiguo, conservado).

### 1.2 Tefra Redonda ✅ (se amplía)
- **Ya construido:** cúpulas de yeso malva y ventanas redondas en el Barrio del Ovillo.
- **Se añade** 🆕 **la Gran Cúpula:**
  - la cúpula que cubría el centro de la Tefra de antes, hoy un **esqueleto partido** de costillas malva sobre el
    Barrio del Ovillo y el Mirador de las Lunas;
  - es la «ciudad redonda bajo una cúpula agrietada» que ve el jugador al llegar (`Tef01`);
  - por los huecos cae la ceniza.
- **Detalles:** marcos de puerta con las rayas de alturas de los niños, hornos de pan en los bajos y bancos curvos.

### 1.3 El Dominio ✅
- **Ya construido:**
  - búnkeres de basalto;
  - **muralla de 16 torres** con cañones;
  - **4 puertas** con control de la policía militar;
  - **foso de lava** y **Canal de la Forja** con 5 puentes de hierro y barandillas;
  - chimeneas de las fundiciones;
  - farolas naranjas de sodio.
- **Se conserva todo.**

### 1.4 La ocupación del Coro 🆕
- **Forma:** masas grises lisas, como cera o ceniza fundida, que crecen sobre las fundiciones y bajan por las paredes.
  Dentro, **moldes con forma humana** en fila: la cadena de montaje de Velados.
- **Luz:** un gris perla sin sombra, el color del Coro, que se come el naranja de la lava.
- **Dónde:** las Fundiciones (Acto II, mazmorra 1 «la Fundición Negra») y la base de la Lanza (Acto V).

---

## 2. Ciudades, asentamientos y territorio

### 2.1 Bastión Ceniza (8 barrios ya construidos; se mantienen sus nombres y anclas)

| Barrio | Qué tiene (✅ ya existe) | Qué añade la historia (🆕) | Anclas de misión (se conservan) |
|---|---|---|---|
| **Barrio del Ovillo** | Cúpulas malva, la casa de la familia de Cosme, la Panadería del Ovillo | La **Calle del Horno** (el muro con la ventana redonda de `Tef01`); la Gran Cúpula encima; la base de la **Resistencia del Ovillo** (los desertores de Dalia) | `Tefra_RuinasOvillo` |
| **Mercado Espiral** | Puestos en espiral alrededor de un pozo de lava; los Bloques del Refugio | Mercado negro de núcleos de Sello (secundaria) | — |
| **Muelle Bastión** | Plataforma de aterrizaje, astillero, calabozos, armería | Naves de la Coalición tras la tregua | `Tefra_Plataforma` |
| **Mirador de las Lunas** | La estatua de **la abuela Nilda**, el lago templado, las tiendas de refugiados | La estatua cobra sentido: Nilda es la abuela de Cosme, que contaba que «el Silencio se comía las estrellas» | — |
| **Campus Nilda** | La academia de Nilda, hoy hospital de campaña; baños; sopa | La Doctora Fermina; el Velado encadenado (secundaria) | `Tefra_Refugio` |
| **Las Fundiciones** | Fundiciones Norte y Sur, la Forja, viviendas obreras, la estación del tren | **La cadena de montaje de Velados** (ocupación, Acto II) | — |
| **Los Pozos de Magma** | La central geotérmica, el pozo de magma, **la Lanza** (torre con lente), el refugio, el depósito de agua | Bajo la torre de Corvo, la **Lanza tejedora** (el Sello) y la grieta del fondo del pozo (`Tef03`) | `Tefra_PozoMagma`, `Tefra_Central` |
| **La Muralla** | 16 torres, 4 puertas, cuartel, explanada | El asedio de Bastión (Acto IV) | — |

**Fuera de la muralla** (biomas del diseño antiguo, conservados):

| Bioma | Uso en la historia |
|---|---|
| Llanura de Ceniza | Tierra de nadie (`Tefra_TierraDeNadie`) y la tregua (`Tef02`) |
| Campos de Coladas | Exploración y zona de farmeo |
| Bosque Petrificado | Escondites de desertores (secundaria) |
| Fumarolas de Azufre | Zona peligrosa |
| **La Caldera Roja** | Lago de lava; bajo ella, las salas tejedoras (mazmorra 2: los túneles de la Forja) |
| Trincheras del Este | El frente abandonado; Velados soldados |
| El Huerto de Nilda | El lugar donde se abrió el agujero en el cielo que se tragó a Cosme en 1.176: una marca quemada en forma de grieta |
| Órbita: el Frente de Ovilla | Combate espacial |

### 2.2 Tipos de asentamiento

| Tipo | Cómo es |
|---|---|
| Ciudad-fortaleza (Bastión Ceniza) | Muralla, puertas y barrios con funciones |
| Refugios del Ovillo | Cúpulas medio derruidas con túneles entre ellas |
| Campamentos de refugiados (Mirador) | Tiendas alrededor de la estatua |
| Puestos del frente | Búnkeres sueltos en las trincheras |
| Ovilla (la luna) | Ciudad minera en cráteres: cúpulas de cuarzo (decorado lejano; jugable en una expansión) |

---

## 3. Edificios emblemáticos

### E1 · La Lanza (el Sello y la torre de Corvo) 🆕 (amplía ✅)
- **Arriba (existe):** la torre de Corvo con su lente, en los Pozos de Magma.
- **Abajo (nuevo):**
  - la **Lanza tejedora**, una **columna-yunque de 120 studs** clavada en el volcán, de basalto con bandas de cobre;
  - la torre de Corvo está construida encima y le chupa la energía;
  - en la base, la grieta del fondo del pozo (`Tef03`).
- **Mazmorra-jefe** (Acto V):
  - bajada en espiral alrededor de la columna;
  - **fase 1:** en la plataforma de artillería;
  - **fase 2:** en un anillo de cobre a media altura;
  - **fase 3:** en la base, junto al corazón del Sello.
- **Estados:**
  - **sometido:** lente roja y cobre apagado;
  - **liberado:** las bandas de cobre se encienden en azul y **el resplandor se ve en el cielo nocturno sobre el
    volcán**.

### E2 · La Gran Cúpula de Tefra Redonda 🆕
- **Qué es:** el esqueleto de la cúpula que cubría la ciudad de antes de la guerra.
- **Medidas:** 220 studs de diámetro y 70 de alto, con **12 costillas** curvas de yeso malva, la mitad partidas, unidas
  arriba por un anillo roto.
- **Función:** es la silueta de Tefra desde cualquier punto de la ciudad y la imagen de lo que se perdió.
- **Pleno:** se tienden lonas entre las costillas, como primera reconstrucción del barrio.

### E3 · La Calle del Horno y la casa de Cosme ✅ (se ajusta)
- **Existe:** la casa de la familia de Cosme (el armazón y el marco de la puerta con las rayas de alturas) y la
  panadería.
- **Ajuste de continuidad** (pendiente P-8, necesita aprobación): el marco dice «Cosme 8 · Ada 6». La historia
  publicada llama **Lía** a su hermana. **Propuesta:** cambiar «Ada» por «Lía» en el marco, el texto de «Mirar», el
  recuerdo y los objetos (bufanda y candado).
- **Se añade** 🆕 el muro con la ventana redonda y la placa medio fundida «Calle del Horno» (`Tef01`).

### E4 · La cadena de montaje de Velados (la Fundición Negra) 🆕
- **Qué es:** la Fundición Norte, ocupada por el Coro. Es la mazmorra 1 de Tefra.
- **Diseño:**
  - una nave industrial de 160 × 60 studs;
  - **cintas transportadoras** con moldes humanos;
  - **calderos de ceniza gris** en vez de hierro;
  - las masas grises bajando por las paredes;
  - al fondo, una sala de «espera» con Velados recién hechos de pie, quietos.
- **Sonido:** los martillos de siempre, pero **a destiempo**, al ritmo del pulso de once segundos.
- **Liberado:** vuelve a ser fundición; los moldes humanos se funden y se convierten en una placa conmemorativa.

### E5 · El Puente de los Mil Candados ✅
- La Avenida del Muelle sobre el canal.
- En el Acto IV es el escenario de S5 (el regreso de Cosme y Lía).
- **Liberado:** candados nuevos, uno por cada Velado que despertó o descansó.

### E6 · La estatua de la abuela Nilda ✅
- En el Mirador de las Lunas.
- 🆕 **Placa nueva:**
  > «Nilda, maestra. Estudió el Silencio.»

  Es una pista: Nilda estudió los cuentos del Silencio y midió el agujero de 1.176 (secreto «Los cálculos de Nilda»,
  reinterpretado como prueba del Consorcio, pista del giro 4).

### E7 · Las salas tejedoras bajo la Caldera 🆕
- Ciudades de la Forja tragadas por la lava: salas de basalto con bandas de cobre, yunques de piedra y murales de los
  Tejedores forjando hilos.
- Es la mazmorra 2 (Acto IV).
- **Pista mitológica:** un mural muestra ocho mundos y uno más en el centro. Es el primero de los murales de Oren que
  culminan en Siroco.

---

## 4. Materiales y técnicas

### 4.1 Paleta cerrada de Tefra

| Uso | Material de Roblox | Color (RGB) |
|---|---|---|
| Basalto militar | Basalt / Slate | 34, 32, 34 · 52, 48, 50 |
| Yeso malva (Tefra Redonda) | Plaster / SmoothPlastic | 176, 140, 170 · 150, 116, 146 |
| Lava | CrackedLava / Neon | 255, 120, 30 · 255, 170, 60 |
| Hierro de puentes | Metal / DiamondPlate | 70, 66, 64 |
| Cobre tejedor | Metal (con variante) | 184, 115, 51 |
| Venas de Sello | Neon (con moderación) | 110, 210, 255 |
| Ceniza malva (cielo y suelo) | Sand / Ground | 150, 130, 140 |
| Gris del Coro (ocupación) | SmoothPlastic / Concrete | 196, 194, 190 (sin textura) |
| Tela de refugiados | Fabric | 150, 90, 60 · 90, 80, 100 |

**Prohibido en Tefra:** piedra perla (Valmar), cristal limpio (Vértice), madera viva (Umbría) y adobe (Siroco).

### 4.2 Técnicas

| Pueblo | Cómo construye | En el juego |
|---|---|---|
| Tejedores | Fundían la piedra y la cosían con hilo de cobre | Mallas con bandas de cobre incrustadas |
| Tefra Redonda | Yeso sobre armazón curvo | Cúpulas (existentes) |
| El Dominio | Bloques de basalto colado en moldes, con aristas vivas y remaches | Existente |
| El Coro | Hace crecer ceniza fundida | Mallas lisas sin aristas, con material liso gris |

---

## 5. Cultura, tradiciones y organización social
- **Quiénes son.** Tefranos: duros, irónicos, apegados a la familia y al pan. Noventa años de guerra les han enseñado a
  bromear entre bombardeos.
- **Quién manda:**
  - el **Dominio de Bastión** (General Corvo y su Ejército): orden, papeles, toque de queda;
  - contra él están los **Desertores del Ovillo**, la Resistencia del Ovillo de Dalia Renn: los que no quieren luchar
    en la guerra;
  - al otro lado, la **Milicia de Ovilla** (el capitán Tobi Renn);
  - el **Mercado Espiral** (Madre Hollín) y los **Refugiados del Mirador** (Fermina) son poderes menores.
- **Leyes y costumbres** (del diseño antiguo y del juego):
  - **La silla más alta es una declaración de guerra.** Literalmente, hay una ley (`Tef02`).
  - El **pan de sirena**, que se comparte después de cada bombardeo.
  - Los **candados** en el puente, con los nombres de los que no volvieron.
  - Nadie dice el nombre de Ovilla en voz alta en la Muralla.
  - Toque de queda de 22:00 a 6:00.
- **Religión y memoria:** los tefranos llaman a la Marea **«el Silencio»**. Sus abuelas cuentan que «el Silencio se
  comía las estrellas». Es el recuerdo deformado del Gran Corte (pista mitológica): Tefra votó a favor, y su culpa se
  convirtió en cuento de miedo.
- **Economía:** la Forja da de comer a cuarenta mil personas (`Tef02`). Escasean el agua limpia, la comida y las
  medicinas. Hay trabajo obligatorio en las fundiciones.

---

## 6. Vestimenta

| Grupo | Vestimenta | Colores |
|---|---|---|
| Soldados del Dominio | Uniforme de lona gruesa con galones naranjas, casco redondo, gafas anticeniza | Gris basalto y naranja |
| Corvo | Abrigo largo militar, sin medallas (solo una: la de sus hijos) | Negro |
| Desertores del Ovillo (Dalia) | Ropa civil, pañuelo malva al cuello, el uniforme viejo con los galones arrancados | Malva y pardo |
| Obreros | Mandil de cuero, guantes hasta el codo, gafas de soldador | Pardo y cuero |
| Cosme | Gafas de soldador, bufanda, bastón (estilo tefrano de su infancia) | Gris y ocre |
| Refugiados | Capas de manta, bufandas gastadas | Desteñidos |
| **Velados de Tefra** | Soldados y obreros grises con piezas de armadura **fundidas** al cuerpo; los Velados Mayores (Darío y Marco) conservan los galones naranjas apagados | Gris con restos de naranja |

---

## 7. Tecnología y transporte
- **Tecnología:**
  - geotérmica (la central de los Pozos);
  - artillería pesada;
  - fundición;
  - la **lente de la Lanza de Corvo**, un arma que no llega a dispararse;
  - armas de chapa gruesa;
  - tras la liberación, **«Acero de Bastión»** con núcleo de Sello.
- **Transporte:**
  - el **tren de cremallera blindado** (existe como decorado y vuelve a funcionar en el estado Liberado);
  - camiones militares;
  - motos de ceniza;
  - **barcazas térmicas** en la Caldera Roja;
  - naves del Muelle.
- **Comunicaciones:** sirenas con horario y radio militar.

---

## 8. Fauna, criaturas y vegetación
- **Fauna** (del diseño antiguo):
  - salamandra de ceniza;
  - escarabajo de escoria;
  - anguila de magma;
  - **cuervo de humo** (avisa de los bombardeos);
  - gusano brasero (jefe de mundo);
  - drones de Ovilla.
- **Bestias del Otro Lado:** cerca del Pozo de Magma, antes del cierre de `Tef03`.
- **Velados de Tefra:**
  - soldado velado;
  - obrero velado;
  - **Coloso de forja:** un tanque del Dominio fundido con un Velado dentro. Es la máquina de asedio de Bastión en el
    Acto IV.
  - Velados Mayores con nombre: **Darío y Marco Corvo** y, en el Acto IV, **Lía**.
- **Vegetación:**
  - setas de ceniza que brillan en naranja;
  - liquen térmico rojo;
  - el Bosque Petrificado;
  - **tras la liberación:** brotes verdes en la ceniza malva. Es la primera vez en noventa años.

---

## 9. Luz, clima y atmósfera

| Momento | Luz | Atmósfera |
|---|---|---|
| Día (40 min reales, existente) | Malva y naranja; Ovilla en medio cielo | Ceniza que cae siempre, humo recto sin viento |
| Noche | La lava como luz principal; fogonazos en Ovilla | Brasas en el aire |
| Bombardeo | Destellos blancos, sirenas 60 s antes (existente) | Polvo y temblor |
| Terremoto (cada 8-15 min, existente) | Temblor de cámara | Piedras en zonas marcadas |
| Ocupación (Fundiciones, Lanza) | Gris perla sin sombra que apaga el naranja | Silencio entre golpes |
| Liberado | La noche gana un resplandor **azul** sobre el volcán (la Lanza) y la lava sigue naranja: los dos colores juntos | Menos ceniza; a veces, cielo malva limpio |

---

## 10. Música y sonido
- **Tema de Tefra:** martillos de forja como percusión, metales graves y el **acordeón tefrano** (el de Cosme),
  desafinado y cálido.
- **Capas:**
  - **ambiente:** martillos lejanos, volcán y artillería de Ovilla;
  - **tensión:** sirena y tambores;
  - **combate:** metal contra metal y coros de obreros.
- **Sonidos firma:**
  - la sirena del bombardeo;
  - el silbido de los cuervos de humo;
  - el **martillo a destiempo** de la Fundición Negra (al ritmo del pulso);
  - el pan saliendo del horno: un sonido cálido que solo existe en el Ovillo.
- **La Lanza encendida:** un acorde grave y largo, como una campana de yunque.

---

## 11. Sometido frente a liberado

| Zona | Sometido | Liberado (tras Tefra V) | Pleno | Fases de reconstrucción |
|---|---|---|---|---|
| Barrio del Ovillo | Cúpulas partidas, la Resistencia escondida | La Panadería con cola de gente, niños entre las cúpulas | Lonas en la Gran Cúpula | 1 escombros · 2 andamios en las cúpulas · 3 cúpulas reparadas |
| Las Fundiciones | Cadena de montaje de Velados, gris | Fundición civil y placa a los Velados | «Acero de Bastión» en la Forja | 1 moldes rotos · 2 obreros vuelven · 3 producción civil |
| Los Pozos de Magma | Lente roja, cobre apagado | La Lanza con cobre azul y la central encendida | Resplandor azul fijo | — |
| Muralla y puertas | Controles, toque de queda | Puertas abiertas, sin toque de queda | Mercado en la explanada | — |
| Mirador de las Lunas | Campamento de refugiados | Los refugiados vuelven a sus barrios | Fiesta del pan de sirena sin sirena | — |
| Cielo | Ovilla con fogonazos | Ovilla sin fogonazos (tregua real, si la decisión lo permite) | — | — |

---

## 12. Traducción a Roblox

### 12.1 Qué se reutiliza (auditado; ver `docs/planetas/tefra-ciudad.md`)
- **Bastión Ceniza entera:**
  - `TefraCityBuilder` y `TefraCity`: unas 6.900 piezas, 22 edificios con planta baja, 8 barrios, foso, canal, 4 puertas
    y 16 torres;
  - el calor (`TefraHeat`) y los bombardeos con horario;
  - el cielo, la luz y el sonido de Tefra (`EnvDirector`).
- **Las anclas de misión:** `Tefra_Plataforma`, `Tefra_RuinasOvillo`, `Tefra_Central`, `Tefra_Refugio`,
  `Tefra_PozoMagma` y `Tefra_TierraDeNadie`.
- **El rendimiento actual es bueno** (unas 6.900 piezas). Margen hasta el presupuesto: unas 8.000 piezas más.

### 12.2 Qué se construye nuevo

| Módulo | Contenido | Piezas aproximadas |
|---|---|---|
| `World/Tefra/Forja` | Kit tejedor de Tefra: columna-yunque, banda de cobre, bóveda de nervios, escalinata en espiral, mural | 8 mallas a medida |
| `World/Tefra/Emblemas` | La Lanza tejedora (E1), la Gran Cúpula (E2), la Fundición Negra (E4), las salas bajo la Caldera (E7), la Calle del Horno (E3) | A medida (unas 3.000 piezas en total) |
| `World/Tefra/Coro` | Masas grises (4 mallas), moldes humanos y Velados de pie | 6 mallas |
| `World/Tefra/Estados` | Las capas del §11 con `StageSets` y `WorldState`; tren de cremallera en marcha en el estado Liberado | Datos + animación del tren |

### 12.3 Riesgos
- **La Gran Cúpula es enorme:** se hace con 12 mallas de costilla y un anillo, sin piezas pequeñas.
- **La Lanza se ve desde toda la ciudad:** malla con un nivel de detalle bajo de lejos.
- **La Fundición Negra y la Lanza son mazmorras:** necesitan el sistema de mazmorras instanciadas (Vol. VI, pendiente
  de auditoría). Mientras tanto, se construyen como zonas de misión abiertas.

### 12.4 Orden de construcción propuesto
1. La Gran Cúpula y la Calle del Horno (refuerzan el Acto I que ya existe).
2. La Fundición Negra (Acto II).
3. Las salas bajo la Caldera (Acto IV).
4. La Lanza tejedora (Acto V).
5. Los estados.

---

## 13. Lista de aprobación del dueño (antes de construir)

| # | Qué apruebas | Sí / cambios |
|---|---|---|
| T1 | El **concepto visual**: Forja tejedora, Tefra Redonda, el Dominio y la ocupación gris; la imagen guía | |
| T2 | La **arquitectura**: conservar Bastión Ceniza y añadir la Forja tejedora debajo y la ocupación encima | |
| T3 | Los **materiales**: la paleta cerrada del §4 | |
| T4 | La **distribución**: los 8 barrios existentes, los biomas exteriores y el Huerto de Nilda | |
| T5 | Los **edificios emblemáticos** E1-E7, sobre todo la Lanza tejedora de 120 studs, la Gran Cúpula y la Fundición Negra | |
| T6 | La **guerra contra Ovilla** como la guerra de noventa años del Dominio (RC-032) | |
| T7 | **Ada → Lía** en los textos del mundo de Tefra (P-8) | |
| T8 | Los **estados** sometido, liberado, pleno y las fases (§11) | |
