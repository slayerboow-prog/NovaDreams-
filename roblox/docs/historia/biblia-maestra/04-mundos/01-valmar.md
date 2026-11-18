# Biblia Maestra · Volumen IV · 1. VALMAR — «El Jardín Caído»

> HEROES OF HISTORY · Referencia oficial. Nivel de detalle: **construible**.
> Estado: **concepto para aprobación del dueño** (lista al final). No se construye nada hasta su sí.

---

## 0. Concepto en una página

**La idea.** Valmar fue el corazón del Telar: el **Jardín** de los Tejedores, donde hace 1.214 años se votó el Gran
Corte. Encima de ese jardín de piedra viva se levantó, siglos después, una ciudad moderna, la Valmar del simulador de
antes. La Caída (1.212) rompió la ciudad moderna, y entre sus grietas asoma el jardín antiguo. Sobre las ruinas, los
supervivientes han atado con cable y chapa la última ciudad libre.

**Cómo se lee de un vistazo:** tres capas, tres gramáticas.

| Capa | Época | Gramática | Regla de lectura |
|---|---|---|---|
| **El Jardín** | Hace 3.000 años, Tejedores | Curvas, terrazas escalonadas, arcos ojivales orgánicos, columnas-tronco, venas azules | **Lo antiguo crece** |
| **La Valmar moderna** | Antes de 1.212 | Avenidas, torres de cristal, metro, el urbanismo del simulador | **Lo moderno se cae** |
| **El asentamiento** | 1.212-1.214 | Contenedores, chapa de ascensor, andamios, lonas, cable | **Lo nuevo se ata con cuerda** |

**Sensación buscada.** Una civilización que tuvo un pasado glorioso, que ni siquiera recuerda, y que ahora intenta
sobrevivir. Melancolía, resistencia y una belleza antigua que la gente pisa sin verla.

**Imagen guía** (la que se le enseñaría a un artista):
> Atardecer naranja sucio. En primer plano, la empalizada de contenedores del Distrito Central con un vigía y un foco.
> Detrás, torres de cristal partidas con árboles creciendo en sus pisos. Bajo ellas, una raíz enorme de piedra perla
> con una vena azul débil sale del asfalto y pasa por debajo de la muralla. Al fondo, sobre el horizonte, los arcos
> de un acueducto antiguo cruzan hacia un bosque azulado donde se adivina la copa de un árbol colosal.

---

## 1. Lenguaje arquitectónico

### 1.1 El Jardín (Tejedores)
- **Forma:** terrazas circulares escalonadas, arcos ojivales que parecen ramas al unirse, columnas que se abren arriba
  como un tronco en copa, escalinatas anchas y bajas.
- **Ornamento:** espirales y nudos tallados en relieve. Runas-espiral con venas de luz azul. El símbolo de «puerta» (una
  línea vertical) en los umbrales.
- **Escala:** monumental. Una columna mide de 25 a 30 studs; un arco, 40. La figura humana parece pequeña.
- **Estado:** cubierto de musgo, roto en parte y abrazado por raíces. Las venas azules solo brillan cerca del Árbol.
- **Ya en el juego:** el **Santuario del Bosque** (`Kit/ForestSanctuary`) habla este idioma: plaza circular, runas,
  escalinata, columnas y guardianes. **Es la referencia de estilo de toda la capa.**

### 1.2 La Valmar moderna (en ruinas)
- La ciudad que ya existe (`TownBuilder` y los `Kit` de la ciudad): calles, torres, metro, comercios.
- **Capa de ruina de la Caída** (nueva, superpuesta sin destruir la ciudad, que vuelve en el epílogo):
  - fachadas con huecos;
  - pisos derrumbados en torres altas;
  - árboles creciendo dentro de los edificios;
  - coches abandonados cubiertos de ceniza;
  - marquesinas caídas;
  - semáforos apagados;
  - hierba en el asfalto.
  - Grafitis del Sur: listas de nombres y «VOLVED».

### 1.3 El asentamiento (supervivientes)
- **Muros:** contenedores apilados (dos alturas) y chapa de ascensor remachada («acero de chapa de ascensor, templado en
  la vieja fundición», dice Vossa en `Acad`).
- **Torres de vigía:** andamios con plataforma, foco y lona.
- **Interiores:** edificios modernos reocupados, con las ventanas tapiadas con tablones y lonas.
- **Detalle:** cables colgando entre fachadas, bombillas desnudas, bidones, generadores, depósitos de agua sobre
  azoteas y huertos en balcones.
- **Lectura:** lo que construyen los supervivientes siempre está **atado, remachado o apilado**. Nunca nada liso ni
  nuevo.

---

## 2. Ciudades, asentamientos y territorio

### 2.1 Mapa de Valmar (sobre el mundo que ya existe)
Valmar ya tiene la ciudad con su laguna y cuatro pasos de tierra hacia las Tierras Exteriores (8 regiones en anillo).
La Biblia **ordena** ese territorio así:

| Zona | Qué es en la historia | Estado en 1.214 | Anclas de misión existentes (se conservan) |
|---|---|---|---|
| **Distrito Central** (el asentamiento) | La última ciudad libre, dentro de la muralla | Habitado, racionado y vigilado | `SalaConsejo`, `TallerMaren`, `PuertoEspacial`, `Pista`, `EntradaColegio`, `Vestibulo` |
| **El Sur muerto** | Los barrios que Varn dejó morir: la calle del mercado, la torre del reloj | Gris, Velados, territorio de Tomás (Actos IV-V) | `GuaridaSur` (el paso del Sur) |
| **El Oeste** | La torre de radio y la Caza del Oeste | Manadas | `GuaridaOeste` |
| **El Este y las playas** | El campus abandonado, las playas | Manadas grandes | `GuaridaEste`, `GuaridaCampus` |
| **El paso del pantano** | Hacia las Tierras Exteriores | Lo baja el Pantano Maldito | `GuaridaPantano` |
| **Tierras Exteriores** (8 regiones existentes) | El Valmar salvaje, con ruinas tejedoras | Zonas de farmeo y mazmorras | `GuaridaBosque`, `GuaridaCercana` y las regiones |
| **Bosque Etéreo y Santuario** | El **Árbol Ancestral**, el Sello de Valmar | Apagado hasta Valmar V | Santuario existente (Eldran, runas, núcleo) |

### 2.2 La Raíz Mayor (la revelación de Valmar IV)
- El Árbol Ancestral es colosal y **su raíz principal, la Raíz Mayor, recorre el subsuelo** desde el Bosque Etéreo
  hasta el corazón de la ciudad.
- La ciudad moderna se fundó, sin saberlo, sobre los puntos donde la raíz aflora. El **Distrito Central** coincide con
  la zona de raíz más densa.
- **Por eso aguantó la muralla:** la luz débil del Sello frena a la Marea (R1). Valmar IV lo revela al bajar a las
  cloacas del Consejo (mazmorra 1).
- **Cómo se ve:** raíces de piedra perla, de 6 a 12 studs de grosor, que asoman del asfalto en la plaza del Consejo,
  pasan bajo la muralla y se hunden en el Sur. Llevan una vena azul que **late con el pulso de once segundos**.

### 2.3 Tipos de asentamiento

| Tipo | Dónde | Cómo es | Gente |
|---|---|---|---|
| **El asentamiento** (Distrito Central) | Dentro de la muralla | Calles modernas cerradas con barricadas, plaza del Consejo, mercado del puerto, la Academia | ~6.000 personas (dato del juego: «esa máquina mantiene vivas a seis mil personas») |
| **Refugios de fuera** | Campus, túneles del metro, granjas aisladas | Grupos de 10 a 40 personas fortificados en un edificio | Lena y los que salieron del campus |
| **Campamentos de los Hijos de la Ceniza** | Bordes del Sur (Acto IV) | Telas grises, ceniza en la cara, hogueras sin humo | Seguidores de Varn |
| **Ruinas tejedoras habitadas** | Regiones exteriores (Refugio del Bosque) | Zonas seguras con taller (`RegionGuide`, tipo «Santuario») | Exploradores, el guardián Eldran |

---

## 3. Edificios emblemáticos

Las medidas son orientativas, en studs. Las piezas «🆕» son nuevas y las «✅» ya existen.

### E1 · El Árbol Ancestral y su Santuario ✅ (se amplía)
- **Qué es:** el Sello de Valmar. Esqueje del Árbol Primero de Oren.
- **Existe:** `Kit/AncientTree` (el árbol de mallas) y `Kit/ForestSanctuary`:
  - plaza circular de runas;
  - escalinata de tres tramos hacia la ciudad;
  - puerta antigua;
  - columnas;
  - dos guardianes de piedra;
  - tres altares;
  - el altar del núcleo;
  - una cascada.
- **Se añade:**
  - 🆕 **venas azules en las raíces y el tronco**, con tres estados:
    - **apagado:** gris, sin luz;
    - **despierto:** pulso débil, desde el Acto IV;
    - **encendido:** azul intenso, desde el Acto V, y visible desde la ciudad como un resplandor en el cielo nocturno
      del norte.
  - 🆕 El inicio de la **Raíz Mayor**, que sale del santuario hacia la ciudad: una malla de raíz por tramos.
- **Silueta:** la copa del árbol tiene que verse desde la muralla del Distrito Central, como una mancha oscura en el
  horizonte norte. Si la distancia de dibujado no llega, se usa un **impostor**: un plano con su silueta.

### E2 · La Sala del Corte (bajo el edificio del Consejo) 🆕
- **Qué es:** el salón tejedor donde los ocho gobernadores votaron el Gran Corte. Encima, sin saberlo, se construyó el
  edificio del Consejo. En su centro está **el generador del Umbral**: el anillo negro con luz blanca (`Gri06`),
  construido sobre la Raíz Mayor. Accionarlo es tocar el Sello (RC-022).
- **Planta:** circular, de 60 studs de diámetro y 30 de alto, con cúpula de nervios como ramas.
- **Elementos:**
  - **ocho tronos de piedra** en círculo (3 × 3 × 7 studs); **el de Nivalis está partido** (votó en contra);
  - un mural del Telar en la pared: nueve círculos unidos por hilos, uno tachado;
  - el generador ocupa el centro, entre las raíces.
- **Luz:** el blanco del generador. Cuando se cierra la Grieta, solo queda la vena azul de la raíz.
- **Misiones:** `Gri06` (el sótano del generador, ya existe como sitio) y Valmar IV (mazmorra 1: las cloacas que llegan
  aquí).

### E3 · El edificio del Consejo ✅ (se viste)
- **Qué es:** el poder político del asentamiento. Edificio institucional moderno en la plaza, con el archivo en la planta
  baja (`Gri03`) y el sótano del generador.
- **Se añade:**
  - 🆕 barricada de sacos y garita en la entrada;
  - 🆕 los carteles de Varn, arrancados después de `GriVerdad`.
  - Con la variante **UmbralPublico:** la orden de las 23:40 pegada en la puerta.
- **Contraste buscado:** es el único edificio **limpio** del asentamiento. Eso dice todo del Consejo.

### E4 · La Academia de Guerreros ✅ (se viste)
- **Qué es:** un antiguo colegio con las ventanas tapiadas, refundado por Kael en 1.213.
- **Zonas existentes:** `EntradaColegio`, `Vestibulo`, `Pista`.
- **Se añade:**
  - 🆕 **La pared de nombres:** el muro de la entrada, con chapas colgadas y nombres pintados a mano. Es una pieza
    emocional clave: aquí va la chapa de Ander Vey (`ChapaAnderPared`), aquí acaba el nombre de Kael y aquí termina el
    juego.
  - 🆕 La armería de Vossa: el libro de salidas y entradas sobre el mostrador.
  - 🆕 Patio de entrenamiento con dianas de chapa y sacos.
  - 🆕 Mástil con la primera bandera (`Rec05`).
  - **Tras la muerte de Kael:** un **monumento** en el patio (visible para todos, RC-016): su abrigo sobre una estaca y
    flores.

### E5 · La Muralla del Distrito Central 🆕
- **Qué es:** el anillo defensivo del asentamiento.
- **Construcción:** contenedores en dos alturas (8 × 8 × 20 studs cada uno), reforzados con chapa de ascensor. Torres de
  andamio cada 60 studs, con foco y lona. Cuatro puertas de chapa corredera.
- **Detalle de la revelación:** en tres puntos de la base, **la Raíz Mayor pasa por debajo** con su vena azul. Desde el
  Acto IV, los vigías dicen que «la muralla aguanta donde brilla».
- **Estados:**
  - **Asedio** (Valmar IV): fuego, una puerta abierta, Velados.
  - **Tras Valmar V:** puertas abiertas de día y mercado junto a la puerta sur.
  - **Epílogo:** se desmonta; los contenedores pasan a ser puestos.

### E6 · El Sur muerto y la torre del reloj 🆕
- **Qué es:** el territorio de Tomás y la mazmorra-jefe de Valmar V.
- **La calle del mercado** (la de Sorel):
  - puestos con toldos podridos y la persiana de su casa;
  - la foto familiar del mercado (eco de `Acad04`).
- **La torre del reloj:** torre municipal moderna de 50 studs, con el reloj parado a las **23:52**. Dentro, la escalera
  de caracol hasta la sala de la maquinaria: es la arena final de Tomás (fase 3).
- **La cabina:** una cabina telefónica en la plaza, desde donde llamó Tomás. Es una pieza de recuerdo (S1).
- **Estados:**
  - **Sometido:** niebla gris, ceniza y Velados quietos.
  - **Liberado** (tras Tomás): la ceniza se asienta, crecen flores en el asfalto y se pone un memorial de la noche del
    Sur con los nombres, que el jugador puede completar (secundaria «La pared de nombres»).

### E7 · Los Arcos del Jardín 🆕
- **Qué es:** un acueducto tejedor que cruzaba de las montañas al Jardín. Hoy son arcos sueltos que atraviesan la
  ciudad moderna y las Tierras Exteriores.
- **Medidas:** arcos de 40 studs de alto y 30 de luz, con un canal arriba por el que ya no corre agua.
- **Función visual:** une las tres capas en una sola imagen (los arcos antiguos pasan por encima de las torres modernas
  rotas) y guía la vista hacia el Bosque Etéreo y el Árbol.
- **Estado Pleno:** vuelve a correr agua con brillo azul por el canal.

### E8 · El puerto espacial y la nave de Ilen ✅
- **Existe** (`PuertoEspacial`).
- **Se añade** 🆕 la foto «Ilen. Tefra. Vuelve» junto al panel de la nave (`Guerrero` ya la describe).
- **Tras la fundación de la Coalición:** naves de los mundos liberados aparcadas, una por planeta.

### E9 · La torre de radio del Oeste ✅
- La baliza de `Rec01` y la voz de Halden de las 3:12 (`Gri01`).

---

## 4. Materiales y técnicas

### 4.1 Paleta cerrada de Valmar

| Uso | Material de Roblox | Color (RGB) |
|---|---|---|
| Piedra tejedora | Marble / Limestone | 200, 198, 190 · 186, 182, 172 |
| Musgo y raíz | Grass / Slate | 78, 128, 70 · 150, 146, 136 |
| Venas de Sello | Neon (con moderación) | 110, 210, 255 |
| Hormigón moderno | Concrete / Asphalt | 150, 150, 150 · 70, 70, 74 |
| Cristal roto | Glass (transparencia 0,4) | 140, 170, 190 |
| Chapa y contenedor | CorrodedMetal / DiamondPlate | 120, 125, 130 · 140, 80, 50 (óxido) · 60, 90, 110 (contenedor azul) |
| Lona y tela | Fabric | 170, 140, 90 · 90, 100, 80 |
| Madera de tapiado | WoodPlanks | 120, 90, 60 |
| Ceniza (Sur muerto) | Sand / Slate | 120, 118, 116 |

**Prohibido en Valmar:** basalto negro (Tefra), metal dorado (Vértice), hielo (Nivalis) y adobe (Siroco).

### 4.2 Técnicas
- **Los Tejedores** guiaban la piedra para que creciera. **En el juego:** mallas curvas sin aristas, con las juntas
  escondidas bajo musgo.
- **Los modernos** construían con hormigón y cristal. **En el juego:** la ciudad existente.
- **Los supervivientes** apilan, remachan y atan. **En el juego:** contenedores (piezas por código), chapas con remaches
  (textura) y cables (`Beam` o cuerdas).

---

## 5. Cultura, tradiciones y organización social

- **Quiénes son.** Valmareses: prácticos, cívicos, orgullosos de «la ciudad», ignorantes del Jardín que pisan. Tras la
  Caída, comunidad de racionamiento y desconfianza.
- **Quién manda:**
  - **el Consejo** (Varn hasta `Gri04`), con la guardia del Consejo;
  - **la Academia** (Kael), la fuerza que sale fuera;
  - tensión constante entre los dos.
- **Tradiciones de antes de la Caída:**
  - la Fiesta de la Cosecha, un recuerdo inconsciente del Jardín, granero del Telar;
  - el dicho «lo que plantas en Valmar, crece».
- **Tradiciones de después:**
  - **«Volver a la hora»:** quien sale de la muralla tiene una hora de regreso. Si no vuelve, su nombre va a la pared.
  - **El parte:** en la puerta se cuenta a los que salen y a los que vuelven. Kael cuenta en voz baja.
  - **La pared de nombres.**
  - **La radio de la plaza:** cada tarde, Ortal se sienta con una radio apagada.
- **Economía:** racionamiento (agua y baterías), con la decisión `RecAgua`. Mercado negro del puerto (Kerr) y trueque.
- **El Gran Corte en Valmar:** borrado. Nadie lo recuerda. Es el mundo que lo propuso y es el que más ha olvidado.
  Ironía buscada.
- **Cómo hablan:** frases cortas, humor seco, «criatura» como apelativo de los mayores. Las expresiones de la Academia
  («cadete», «promoción», «a la hora») se convierten en señas de identidad.

---

## 6. Vestimenta

| Grupo | Vestimenta | Colores |
|---|---|---|
| Cadetes de la Academia | Chaqueta acolchada gris con el parche de la promoción, protecciones de chapa atadas con correas, bufanda | Gris pizarra, azul apagado y óxido |
| Kael | Abrigo militar viejo, largo, cuello alto que tapa la cicatriz | Azul marino gastado |
| Sorel | Chaqueta remendada con un parche de cada mundo (pierde parches en Vértice) | Azul con parches de color |
| Brenn | Camiseta oscura, nudillos vendados, espada «B. y T.» | Rojo oscuro y negro |
| El Consejo | Trajes limpios, abrigos sin manchas | Negro y gris claro |
| Guardia del Consejo | Chaleco antibalas, porra | Azul acero |
| Civiles | Capas de ropa moderna remendada, mascarillas de tela | Desteñidos |
| Hijos de la Ceniza | Telas grises, ceniza en la cara | Gris ceniza |
| **Velados de Valmar** | Siluetas de vecinos con ropa moderna cubierta de ceniza; la cara, lisa y gris; se mueven a la vez | Gris |

---

## 7. Tecnología y transporte
- **Tecnología:**
  - la de una ciudad moderna, rota: radios, generadores, el hospital;
  - **el generador del Umbral**, la tecnología del Consorcio construida sobre el Sello;
  - armas de chapa hechas por Vossa;
  - desde la Coalición, armas con núcleo de Sello.
- **Transporte:**
  - a pie;
  - quads y motos de chatarra (para la Reconquista);
  - la nave de Ilen (puerto espacial);
  - el metro muerto, cuyos túneles son refugio y mazmorra;
  - el vuelo espacial del juego, que ya existe.
- **Comunicaciones:** la radio es la cultura del asentamiento. La baliza del Oeste capta las 3:12.

---

## 8. Fauna, criaturas y vegetación
- **Bestias del Otro Lado** (el bestiario existente): manadas refugiadas en las regiones y guaridas. **Dato narrativo:**
  huyen hacia la luz, no atacan por odio. Las guaridas cercanas a la Raíz Mayor tienen bestias más tranquilas.
- **Velados de Valmar:** vecinos del Sur, guiados por Tomás.
  - Velado común.
  - Velado Mayor: los «vecinos con nombre», como el hijo de Ortal.
  - Coloso: un camión de bomberos fundido con ceniza, que es el ariete del asedio.
- **Vegetación:**
  - hierba y arbustos que rompen el asfalto;
  - árboles dentro de las torres;
  - en las Tierras Exteriores, los biomas existentes;
  - **cerca de la Raíz Mayor, plantas con nervaduras azuladas** (pista visual del Sello).

---

## 9. Luz, clima y atmósfera

| Momento | Luz | Atmósfera |
|---|---|---|
| Día en el asentamiento | Sol blanco y frío, sombras duras | Polvo en suspensión, ropa tendida |
| Atardecer (la hora de Valmar) | Naranja sucio, contraluces largos entre torres rotas | La imagen guía |
| Noche | Focos de la muralla, bombillas, fuego en bidones | **Con la Grieta abierta:** el resplandor de la Grieta en el cielo (`SkyRift`). **Cerrada** (`GrietaCerrada`): estrellas y oscuridad («por primera vez en dos años se ven las estrellas»). |
| El Sur muerto | Gris sin sombras (`Light = Ceniza`) | Niebla gris baja, ceniza que cae despacio |
| Tras encender el Árbol | Un resplandor azul suave en el horizonte norte de noche; las venas de la Raíz Mayor encendidas | La niebla del Sur se retira |

**Clima:** días despejados y fríos, lluvia fina ocasional y ceniza del Sur cuando sopla del sur.

---

## 10. Música y sonido
- **Tema de Valmar:** piano gastado (con alguna tecla desafinada) y cuerdas bajas. Melancólico, no triste.
- **Capas:**
  - **ambiente:** viento entre edificios vacíos, perros lejanos, estática de radio, generadores;
  - **tensión:** percusión metálica sobre chapa;
  - **combate:** cuerdas rápidas y golpes de contenedor.
- **Sonidos firma:**
  - el **pulso de once segundos** en todas las radios (desde `Mar01`);
  - la sirena de «volver a la hora»;
  - el tic del reloj del Sur (parado: un tic que no llega).
- **El Árbol encendido:** un acorde sostenido muy suave, cerca del santuario.

---

## 11. Sometido frente a liberado

| Zona | Sometido | Liberado (tras Valmar V) | Pleno (Sello de Valmar Pleno) | Epílogo (UniversoRecuperado) |
|---|---|---|---|---|
| Distrito Central | Muralla cerrada, racionamiento, focos | Puertas abiertas de día, mercado junto a la puerta sur, naves de la Coalición | Fiesta de la Cosecha recuperada en la plaza | **Vuelve la ciudad de antes**, con sus trabajos y su tráfico |
| El Sur muerto | Gris, niebla, Velados | Ceniza asentada, flores, memorial | Vecinos que vuelven a la calle del mercado (fase 3) | Barrio reconstruido |
| La Raíz Mayor | Vena apagada o débil | Vena encendida | Plantas azules en la plaza | Visible y protegida, como monumento |
| Árbol Ancestral | Gris | Azul | Copa con brillo | Santuario abierto a todos |
| Arcos del Jardín | Secos | Secos | Agua azul por el canal | Agua azul |

---

## 12. Traducción a Roblox

### 12.1 Qué se reutiliza (auditado)
- **La ciudad moderna** (`TownBuilder` y la ciudad existente). No se toca: es la ciudad de antes y vuelve en el epílogo.
- **`Kit/Settlement`** (el asentamiento existente). Auditoría pendiente antes de ampliarlo.
- **`Kit/ForestSanctuary`, `Kit/AncientTree` y `SanctuaryService`.**
- **`OuterLandsBuilder`, `ValmarRegions`, `RegionLandmarks` y `RegionGuide`.**
- **Las anclas de misión:** `SalaConsejo`, `TallerMaren`, `PuertoEspacial`, `Pista`, `EntradaColegio`, `Vestibulo` y
  las guaridas.

### 12.2 Qué se construye nuevo (piezas propias de Valmar)

| Módulo nuevo | Contenido | Piezas aproximadas |
|---|---|---|
| `World/Valmar/Jardin` | Kit tejedor: columna-tronco, arco ojival, tramo de terraza, losa con runa, trono, nervio de cúpula, tramo de Raíz Mayor (malla, 4 variantes) | 12 mallas a medida |
| `World/Valmar/Ruina` | La capa de la Caída sobre la ciudad moderna: fachada con hueco, piso derrumbado, coche con ceniza, árbol en torre, marquesina caída, grafiti de nombres. **Se dibuja solo mientras no esté el flag UniversoRecuperado.** | 10 mallas + calcomanías |
| `World/Valmar/Asentamiento` | Muralla de contenedores, torre de andamio, puerta corredera, barricada, lonas y cables | Piezas por código + 4 mallas |
| `World/Valmar/Emblemas` | Sala del Corte (E2), torre del reloj y calle del mercado (E6), pared de nombres y monumento de Kael (E4), Arcos del Jardín (E7) | A medida |
| `World/Valmar/Estados` | Las capas por estado (§11) con `StageSets` y `WorldState` | Datos |

### 12.3 Presupuesto y riesgos
- **La capa de ruina** puede subir mucho el número de piezas sobre una ciudad que ya es grande. **Solución:** ruina por
  calcomanías y unas pocas mallas grandes por manzana, nunca escombros pieza a pieza.
- **La Raíz Mayor** atraviesa la ciudad: se hace por tramos con carga por cercanía.
- **Vista lejana del Árbol:** un impostor (plano con la silueta) si la distancia de dibujado no llega. **Nunca** se
  fuerza el streaming de la ciudad (regla del proyecto).

### 12.4 Orden de construcción propuesto
1. El asentamiento y su muralla, con la Raíz Mayor bajo la muralla.
2. El Sur muerto con la torre del reloj.
3. La Sala del Corte.
4. La capa de ruina.
5. Los Arcos del Jardín.
6. Los estados.

Este orden sigue al de las misiones nuevas de Valmar IV y V.

---

## 13. Lista de aprobación del dueño (antes de construir)

| # | Qué apruebas | Sí / cambios |
|---|---|---|
| A1 | El **concepto visual**: tres capas (Jardín, Valmar moderna en ruinas, asentamiento) y la imagen guía | |
| A2 | La **arquitectura** de cada capa (§1) y su regla: «lo antiguo crece, lo moderno se cae, lo nuevo se ata» | |
| A3 | Los **materiales**: la paleta cerrada del §4 y lo prohibido | |
| A4 | La **distribución**: Distrito Central, Sur muerto, Oeste, Este, pantano, Tierras Exteriores y Bosque Etéreo; la Raíz Mayor bajo la muralla | |
| A5 | Los **edificios emblemáticos** E1-E9, sobre todo la Sala del Corte, la torre del reloj de las 23:52, la pared de nombres y los Arcos del Jardín | |
| A6 | Los **estados** sometido, liberado, pleno y epílogo (§11) | |
