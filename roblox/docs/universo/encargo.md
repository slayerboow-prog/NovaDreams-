# Encargo del dueño · «UNIVERSO GALÁCTICO Y GAMEPLAY AAA»

> Resumen fiel del prompt maestro de Sebastián (el dueño). Lo que pide, en español sencillo. El estado real
> del juego está en [`auditoria.md`](auditoria.md) y el diseño en [`diseno-espacio.md`](diseno-espacio.md).

## Lo que escribió Sebastián arriba del todo

> «Recuerda hacer lo mismo que en los planetas: misiones principales… misiones secundarias… trabajos
> espaciales… recolectar minerales, repartidor, mercenario, cazarrecompensas… etc. La misión principal
> quizás sea salvar el universo de un malo maloso.»

Es decir: el espacio tiene que tener **lo mismo que un planeta**: historia principal, misiones
secundarias y **trabajos** (minero, repartidor, mercenario, cazarrecompensas y otros), y una historia
grande en la que **salvas el universo de un villano**.

## 1 · La idea

- Un universo de ciencia ficción **propio y coherente** para **explorar, vivir, pelear y cambiar**.
- Tiene: exploración galáctica, sistemas estelares, planetas únicos, lunas, estaciones, civilizaciones,
  ruinas antiguas, tecnología desconocida, misiones principales y secundarias, combate en el espacio y a
  pie, descubrimientos científicos, anomalías, personajes que se recuerdan, criaturas, recursos, mejoras
  de la nave, progresión, eventos que cambian, secretos, decisiones con consecuencias y una historia
  contada como en el cine.
- **Cada destino tiene un motivo para existir.** Nunca planetas de adorno ni botones que no hacen nada.
- No se dice que Roblox sea un motor AAA: se busca **el mejor resultado real** dentro de Roblox.

## 2 · Referencias visuales

- Mapa galáctico: `docs/espacio-aaa/referencia-mapa-galactico.png`.
- HUD de vuelo: `docs/espacio-aaa/referencia-espacio-v121.png`.
- Son **inspiración**: se adaptan con una identidad propia y sin llenar la pantalla.

## 3 · PRIMERA TAREA: auditoría

Revisar todo lo que ya hay (workspace, servicios, controladores del cliente, módulos, guardado,
misiones, combate, vehículos, interfaz, cámaras, navegación, planetas, estaciones, NPC, armas, efectos,
interacciones y rendimiento) y decir **qué funciona, qué está roto y qué no existe**. Buscar antes de
reemplazar, no duplicar módulos, no renombrar a lo loco y **no quitar nada que funcione**.

## 4 · Arquitectura del universo

UNIVERSO → REGIONES GALÁCTICAS → SISTEMAS ESTELARES (estrella, planetas, lunas, estaciones, campos de
asteroides, anomalías, rutas, eventos y misiones).

- Cada **sistema** como datos: id, nombre, descripción, región, coordenadas del mapa, estrella, planetas,
  visitado/desconocido, peligros, bandos, misiones, eventos, dificultad, recursos especiales, condiciones
  de acceso, estado de descubrimiento y requisitos de viaje.
- Cada **planeta** igual, con sus datos.
- Datos y plantillas compartidos, pero **cada sitio se ve distinto**.

## 5 · Mapa galáctico jugable

Abrir y cerrar, mover, acercar, elegir, panel de información, descubierto/desconocido, rutas, misiones,
eventos globales, requisitos y un **VIAJAR de verdad** que explica por qué no se puede si falla. Nunca
destinos que no existen.

## 6 · Cómo se viaja

Elegir → comprobar requisitos → preparar → sistemas de la nave → efecto de salto cuántico → transición →
preparar el destino → **aparecer en un sitio válido (nunca dentro de algo)** → actualizar radar, misión y
HUD → devolver el control. Si algo falla, **volver atrás sin romper nada**. Unido a las misiones y al
guardado. Si hace falta cambiar de lugar o de servidor, respetar los límites de Roblox.

## 7–10 · Planetas todos distintos

Biblioteca de tipos: rocoso, oceánico, desierto, hielo, volcánico, bosque, tóxico, cristal, artificial,
alienígena, desconocido y anómalo. Cada planeta con identidad visual, geografía, atmósfera, luz,
materiales, clima, vida, construcciones, historia, actividades, recursos y peligros. **Suelo de verdad**
para andar, con caminos y puntos de interés. Actividades reales, motivos para volver y que explorar
sirva para algo.

## 11 · Aterrizar y despegar de verdad

Zonas de aterrizaje, indicadores de altura y velocidad, obstáculos, secuencia, pasar el control al
personaje y volver a la nave.

## 12–14 · Vuelo, combate y naves

- **Vuelo** que se siente bien: acelerar, frenar, impulso, girar, alabeo, inercia ajustable, choques,
  estelas, radar, fijar blanco, escudos, casco y energía. Mandos de PC y de móvil, con sensibilidad.
- **Combate**: cada arma con su papel (cañones directos, láser continuo, misiles que persiguen y se
  esquivan, especiales, escudos), avisos que se entienden, y enemigos de varios tipos (interceptores,
  pesados, defensivos, de largo alcance, de apoyo y jefes espaciales), no solo perseguidores.
- **Progresión de la nave** con efectos reales en los números, clases y estilos de juego. La nave de
  inicio tiene que ser divertida.

## 15–16 · Estaciones, civilizaciones y NPC

Estaciones útiles (atraque, tiendas, talleres, mejoras, NPC, misiones, bandos, investigación, hangar,
zonas restringidas e interiores si se puede). Civilizaciones distintas. NPC y criaturas con
comportamiento y una IA que escale (menos cálculo cuanto más lejos).

## 17–18 · Historia y eventos

- Historia principal + historias secundarias, misiones variadas (exploración, ciencia, combate,
  investigación, rescate, infiltración, bandos). Cada misión dice: objetivo, contexto, condiciones de
  inicio, pasos, personajes, sitios, éxito/fallo, recompensas, consecuencias y qué se guarda.
- **Eventos galácticos** con inicio, duración, final y consecuencias; coordinados por el servidor si son
  de todos.

## 19–20 · Efectos e interfaz

Materiales, luz, profundidad, estelas, explosiones que crecen y se apagan, golpes en el escudo,
nebulosas y campos de asteroides, **solo con lo que Roblox tiene de verdad**. Interfaz para cada
momento (mapa, vuelo, superficie, combate, estaciones), cómoda en el móvil y **solo con datos reales**.

## 21–23 · Guardado, multijugador y rendimiento

- Guardar sistemas descubiertos, planetas visitados, misiones, naves, mejoras, inventario, recursos,
  descubrimientos, relaciones e historia, con una estrategia de DataStore correcta: reintentos, sin
  duplicar y comprobado por el servidor.
- Multijugador: qué es local, compartido, permanente o temporal; **el servidor manda**; nada se queda
  colgado si alguien se va.
- Rendimiento: carga por zonas, niveles de detalle, topes de partículas y de NPC, y **medir**.

## 24–25 · Arquitectura modular y generación

Servicios por tema (UniverseService, GalaxyMapService, StarSystemService, PlanetService,
SpaceFlightService, SpaceCombatService, ShipCustomizationService, LandingService, MissionService,
EventService, NPCService, FactionService, InventoryService, SaveService, UniverseUIController…): **los
nombres son orientativos y hay que REUTILIZAR lo que ya existe**. Generación procedural con identidad,
semillas que se repiten y reglas de validación.

## 26–31 · Progresión, pruebas, fases y reglas

- Progresión y premios **sin pagar para ganar**.
- Pruebas que separan: **Implementado / Revisado / Probado técnicamente / Probado visualmente /
  Pendiente**.
- Fases 1–16: auditoría → arquitectura → modelo de datos → mapa → viaje → vuelo → primer sistema →
  planeta de referencia → aterrizaje → misiones en el planeta → combate → estaciones/NPC/bandos → planetas
  nuevos → eventos → progresión/guardado → optimización.
- El primer planeta de referencia: **pequeño, detallado y lleno de posibilidades**.
- Reglas absolutas: no destruir ni duplicar, no hay botones falsos, no decir que algo está probado si no
  lo está, nada de dependencias de pago, recursos gratis compatibles con Roblox, documentarlo todo y
  mantener la historia coherente.

## 32 · Entregables

A diagnóstico · B sistemas reutilizables · C errores y límites confirmados · D lo que hay que investigar ·
E arquitectura propuesta · F plan por fases · G dependencias · H estrategia de optimización · I propuesta
del primer sistema estelar jugable · J propuesta del primer planeta de referencia · K pruebas por cada
cosa · L archivos que se tocan. **«EMPIEZA POR LA AUDITORÍA.»**

## Lo que se añade en esta tanda (pedido del dueño)

- **Trabajos espaciales** como en los planetas: minero de asteroides (ya existe en el Cinturón de
  Hierro), **repartidor/transportista**, **mercenario**, **cazarrecompensas** y otros que encajen
  (explorador-cartógrafo, chatarrero, científico de anomalías, contrabandista, piloto de carreras…),
  reutilizando el diseño de `docs/planetas/diseno-mundos.md` («La carrera es una sola para toda la
  galaxia»).
- **Historia principal del espacio**: salvar el universo de un villano memorable para la Saga 2
  «Ragnarock» (oscuro pero 13+, sin sangre), coherente con lo que ya hay.
- **Misiones secundarias en el espacio**: señales de socorro, convoyes, piratas, anomalías.
- Y **empezar a programar** por lo que más vale y menos choca: el marco de trabajos espaciales con
  **repartidor** y **cazarrecompensas**, con el servidor mandando y con pruebas.
