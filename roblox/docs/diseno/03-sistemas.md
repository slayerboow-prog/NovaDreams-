# Fase 3 — Sistemas principales y dependencias

## 3.1 Catálogo de sistemas

| # | Sistema | Qué hace | Depende de |
|---|---|---|---|
| S1 | **Núcleo** | Carga de servicios, red segura, eventos, configuración, textos | — |
| S2 | **Datos** | Perfiles, bloqueo de sesión, migraciones, stores globales | S1 |
| S3 | **Reloj y calendario** | Hora, días, semanas, estaciones del juego | S1 |
| S4 | **Mundo** | Layout, casillas, parcelas, grafo de carreteras, zonas ("estás en San Roque") | S1 |
| S5 | **Interacciones** | Sistema único de "acciones" sobre objetos (sentarse, comprar, usar, trabajar) con requisitos | S1, S4 |
| S6 | **Vida** | Edad, etapa, envejecimiento, límites por etapa, muerte y legado | S2, S3 |
| S7 | **Necesidades y estado** | Hambre, energía, higiene, diversión, salud, estado de ánimo | S2, S3, S6 |
| S8 | **Habilidades y XP** | Habilidades (cocina, conducción, medicina…) que suben con el uso | S2 |
| S9 | **Economía** | Libro contable, banco, facturas, impuestos, préstamos | S2, S3 |
| S10 | **Inventario** | Objetos que llevas, en casa o en un vehículo | S2, Registros |
| S11 | **Motor de actividades** | Minijuegos reutilizables (rutas, atención al cliente, reparación, emergencias…) | S5, S8 |
| S12 | **Educación** | Cursos, sesiones, notas, titulaciones, licencias | S6, S9, S11 |
| S13 | **Profesiones** | Requisitos, contratación, turnos, rangos, sueldo, ascensos | S6, S8, S9, S11, S12 |
| S14 | **Propiedades** | Alquiler, compra, hipoteca, instanciado de casas | S4, S9 |
| S15 | **Construcción y decoración** | Construir sobre una parcela y colocar muebles | S10, S14 |
| S16 | **Vehículos** | Compra, garaje, conducción, combustible, seguro, mantenimiento | S4, S9, S12 (carnet) |
| S17 | **Transporte público** | Tren, autobús, taxi | S4, S16 |
| S18 | **Social** | Amistades, contactos, mensajería, reputación | S2 |
| S19 | **Hogares y familias** | Hogar compartido, roles familiares, hijos jugables, árbol genealógico | S6, S14, S18 |
| S20 | **Negocios** | Crear empresa, local, empleados, clientes, beneficios | S9, S13, S14 |
| S21 | **Mercado** | Compraventa y alquiler entre jugadores, bolsa | S9, S14, S20 |
| S22 | **Clima y eventos** | Lluvia, tormentas, festivales, obras, noticias | S3, S4 |
| S23 | **Población NPC** | Ciudadanos simulados, peatones, clientes | S3, S4 |
| S24 | **Tráfico** | Coches NPC por el grafo | S4, S23 |
| S25 | **Emergencias** | Incendios, accidentes, pacientes → policía, bomberos, sanitarios | S11, S13, S22, S23 |
| S26 | **Personalización** | Apariencia, ropa, pelo, escala según edad | S6, S10 |
| S27 | **Interfaz** | Teléfono, apps, HUD, notificaciones | todos (solo lectura) |
| S28 | **Monetización** | Pases, productos, suscripciones, servidores privados | S2, S9 |
| S29 | **Meta** | Analítica, moderación, panel de administrador, logros | S1, S2 |

## 3.2 Mapa de dependencias

```
                              ┌─────────┐
                              │ S1 NÚCLEO│
                              └────┬────┘
           ┌───────────┬──────────┼──────────┬──────────────┐
      S2 DATOS     S3 RELOJ    S4 MUNDO   S29 META     S27 UI (shell)
           │           │          │
     ┌─────┼─────┬─────┘     S5 INTERACCIONES
     │     │     │                │
  S6 VIDA  S9 ECONOMÍA  S8 HABILIDADES
     │     │     │                │
  S7 NECESIDADES │         S11 MOTOR DE ACTIVIDADES
     │           │                │
     │     ┌─────┴──────┬─────────┼───────────────┐
     │  S14 PROPIEDADES │   S12 EDUCACIÓN ──► S13 PROFESIONES
     │     │            │                         │
     │  S15 CONSTRUCCIÓN│   S16 VEHÍCULOS ──► S17 TRANSPORTE
     │     │            │         │
     │     └──► S21 MERCADO ◄── S20 NEGOCIOS ◄────┘
     │
  S18 SOCIAL ──► S19 FAMILIAS (necesita S6 + S14)

  S23 POBLACIÓN ──► S24 TRÁFICO
        └──────────► S25 EMERGENCIAS ◄── S22 CLIMA/EVENTOS + S13
```

## 3.3 Orden de construcción (para no rehacer nada)

Lo que obliga a rehacer trabajo son los **cimientos mal puestos**: el formato de los datos guardados, la red cliente-servidor, el layout del mundo y el modelo económico. Por eso van primero, aunque no se vean.

| Orden | Bloque | Por qué en este momento |
|---|---|---|
| 1 | S1 Núcleo + S2 Datos + S29 Admin | Todo lo demás guarda datos y se comunica. Cambiarlo después obliga a migrar a todos los jugadores |
| 2 | S3 Reloj + S4 Mundo (layout, grafo, parcelas) | Profesiones, NPCs, casas, vehículos y GPS cuelgan del layout |
| 3 | S5 Interacciones + S27 shell del teléfono | Es la forma única de interactuar. Si cada sistema inventa la suya, luego hay que unificarlas |
| 4 | S9 Economía (libro contable) | Todos los sistemas mueven dinero. Si no hay un único punto de paso, aparecen agujeros y duplicaciones |
| 5 | S6 Vida + S7 Necesidades + S8 Habilidades | Definen qué puede hacer cada personaje |
| 6 | S11 Motor de actividades → S13 Profesiones (primeras 5) | Es el bucle principal: trabajar y ganar |
| 7 | S14 Propiedades + S16 Vehículos básicos | Es en lo que se gasta. Cierra el bucle económico |
| 8 | **→ Rebanada vertical jugable (alfa)** | Vida adulta completa en pequeño |
| 9 | S12 Educación + infancia + adolescencia | Los requisitos ya existen en Profesiones. Ahora se pueden obtener jugando |
| 10 | S23–S25 Ciudad viva + S22 Clima | Llena el mapa, que ya es grande |
| 11 | S18–S19 Social y familias | Necesitan vida, casas y edades estables |
| 12 | S15 Construcción + S21 Mercado + S20 Negocios | Economía entre jugadores. Requiere que la economía base esté equilibrada |
| 13 | Expansión del mapa + generaciones + inversiones + viajes | Crecimiento continuo |

## 3.4 Partes técnicamente difíciles o limitadas en Roblox

| Área | Dificultad | Problema | Solución propuesta |
|---|---|---|---|
| **Mundo persistente compartido** | 🔴 Muy alta | Cada servidor es una copia independiente del mapa. Una parcela comprada en el servidor A no está "ocupada" en el servidor B | Propiedades **instanciadas**: tu casa aparece en una parcela libre de su tipo y distrito en el servidor donde entres (el modelo de Bloxburg y Brookhaven). Lo global (mercado, bolsa, noticias, rankings) se sincroniza entre servidores |
| **Miles de jugadores juntos** | 🔴 Imposible tal cual | Un servidor aguanta decenas de jugadores, no miles | Miles de jugadores repartidos en muchos servidores de la misma región, con economía, mercado y mensajería compartidos entre servidores (Fase 12) |
| **Familias y generaciones** | 🔴 Alta | Los miembros de una familia pueden estar en servidores distintos o desconectados | La familia es un registro global. "Unirse a mi familia" lleva al servidor del familiar. Los familiares desconectados aparecen como NPC "en casa" |
| **NPCs a gran escala** | 🔴 Alta | Los Humanoid son caros: cientos matan el rendimiento | Tres niveles: ciudadanos simulados en datos (miles), peatones visuales generados en el cliente (decenas) y NPC de servicio en el servidor (pocos) |
| **Tráfico** | 🟠 Media-alta | Cientos de coches con físicas no son viables | Coches NPC sin físicas, movidos por el grafo en el servidor y suavizados en el cliente. Número limitado y concentrado cerca de los jugadores |
| **Vehículos del jugador** | 🟠 Media | Físicas en móvil y trampas de velocidad | Chasis ligero propio, control de red del conductor y validación de velocidad en el servidor |
| **Tren con pasajeros** | 🟠 Media | Los jugadores de pie resbalan en plataformas que se mueven por código | Viajar sentado, con puertas cerradas en marcha |
| **Construcción libre** | 🟠 Media | Tamaño de los datos y validación | Colocación en rejilla, límite de objetos por parcela y guardado comprimido en un store propio |
| **Economía entre jugadores** | 🟠 Media | Estafas, duplicación de dinero en transferencias entre servidores | Operaciones atómicas con `UpdateAsync` (depósito de garantía), confirmaciones y límites diarios |
| **Arte del mapa** | 🟠 Media (por volumen) | Cientos de edificios de calidad | Mapa en gris primero y arte por código por fases (kits de calle, fachadas y viviendas), más mallas importadas |
| **Rendimiento en móvil** | 🟠 Media | Mapa grande y muchos sistemas | Streaming, presupuestos por casilla, mallas reutilizadas, NPCs en el cliente con niveles de detalle (Fase 15) |
| **Normas de Roblox** | 🟠 Media (riesgo) | Roblox prohíbe experiencias de citas o romance entre usuarios y regula alcohol, violencia y azar | Pareja y familia como **rol de hogar** sin mecánicas de "ligar". Discotecas sin alcohol. Nada de azar con Robux. Revisar la normativa vigente y el cuestionario de madurez antes de cada sistema sensible |
| **Límites de DataStore** | 🟡 Media | Máx. 4 MB por clave y cuotas de peticiones por minuto | Datos repartidos en varios stores, guardado por lotes, caché y MemoryStore para lo muy frecuente |
