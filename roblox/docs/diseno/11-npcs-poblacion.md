# Fase 11 — NPCs y población: la ciudad viva

## 11.1 El límite

Un NPC con `Humanoid` completo cuesta mucho (físicas, animación, red). Un servidor normal aguanta unas pocas decenas moviéndose sin que baje el rendimiento, sobre todo en móvil. Para que la ciudad parezca habitada por miles de personas, la población se divide en **cuatro niveles**.

## 11.2 Los cuatro niveles

| Nivel | Qué es | Dónde se simula | Cantidad | Coste |
|---|---|---|---|---|
| **D. Ciudadanos virtuales** | Población en datos: nombre, casa, trabajo, horario, dinero. No tienen cuerpo | Servidor (tablas) | ~2.000–5.000 por servidor | Casi nulo |
| **C. Peatones de ambiente** | Personas que caminan por las aceras, esperan el bus, se sientan en el parque | **Cliente** de cada jugador, alrededor de él | 20–40 visibles por jugador | Bajo (rigs con `AnimationController`, sin Humanoid, y niveles de detalle) |
| **B. Tráfico** | Coches NPC circulando | Servidor (movimiento cinemático por el grafo, sin físicas), suavizado en el cliente | 30–80 por servidor, concentrados cerca de los jugadores | Medio |
| **A. NPC de servicio** | Dependientes, médicos, profesores, recepcionistas y clientes de negocios: con los que **interactúas** | Servidor | 20–60 activos, solo en las zonas con jugadores cerca | Medio-alto |

## 11.3 Cómo se conectan (la ilusión de sociedad)

1. **Los ciudadanos virtuales (D) tienen horarios:** a las 8:00 del juego "van" a trabajar o al colegio, a las 14:00 comen, por la tarde compran y el fin de semana van a la playa o al estadio.
2. Ese horario genera un **mapa de densidad** por distrito y hora: por la mañana el Centro está lleno, de noche la zona de discotecas de Playa Nova.
3. Cada cliente genera **peatones (C)** según esa densidad alrededor del jugador. La ciudad "cambia" durante el día sin coste de red.
4. Cuando un ciudadano virtual "entra" en un negocio (la cafetería de un jugador, el súper), se convierte en un **cliente real (A)** que camina hasta el mostrador y hace un pedido. Esto genera la **actividad económica** de los negocios aunque no haya jugadores comprando.
5. Los ciudadanos virtuales también **enferman, tienen accidentes o sufren incendios en casa.** Eso alimenta el director de emergencias (policía, bomberos, hospital).

## 11.4 Qué hacen los NPC (según el concepto)

| Comportamiento | Cómo se implementa |
|---|---|
| Ir al trabajo o al colegio, volver a casa | Horario de D. Peatones de C en las rutas a esas horas |
| Comprar, comer, usar servicios | D → A en las tiendas (clientes que consumen y pagan de verdad a los negocios) |
| Usar transporte | Peatones esperando en paradas. Pasajeros NPC que suben al autobús o al tren (visual) |
| Ir al hospital | Pacientes NPC generados por el sistema de salud de D |
| Conducir | Tráfico B por el grafo, con semáforos, prioridades y velocidad por vía |
| Vivir en casas | Luces encendidas de noche en casas NPC y coches aparcados. Algunos entran y salen |
| Generar economía | Consumo de D en negocios de jugadores y del sistema, más el índice de demanda del mercado |

## 11.5 Técnica

- **Navegación:** grafo de aceras y carreteras precalculado (derivado del layout, Fase 2). No se usa `PathfindingService` en tiempo real salvo para NPC de servicio en interiores, porque es caro.
- **Movimiento de tráfico:** posición y dirección por tramo, sincronizadas en lotes a 5–10 veces por segundo con `UnreliableRemoteEvent`. El cliente interpola.
- **Niveles de detalle (LOD):** a más de X studs el peatón se simplifica y desaparece. Las animaciones se pausan fuera de la cámara.
- **Apariencia variada:** combinaciones de ropa, pelo y color de piel desde un catálogo interno (sin depender de cargar avatares de usuarios).
- **Presupuesto dinámico:** si baja el rendimiento del cliente, reduce los peatones. Si el servidor va cargado, reduce el tráfico.

## 11.6 Director de eventos y emergencias

Un sistema central decide cada pocos minutos qué pasa en el mundo, según la hora, el clima, los jugadores conectados y sus profesiones:

| Evento | Qué provoca | Quién responde |
|---|---|---|
| Incendio en un edificio | Humo, fuego y NPCs atrapados | Bomberos (jugadores o NPC tras X min), sanitarios |
| Accidente de tráfico | Atasco, coches dañados, heridos | Policía, ambulancia, grúa (mecánico) |
| Robo en una tienda NPC | Alarma, ladrón NPC que huye | Policía |
| Paciente grave | Llamada al 112 | Ambulancia → urgencias (médicos) |
| Avería en una casa NPC | Aviso de trabajo | Electricista, fontanero |
| Tormenta | Cortes de luz, árboles caídos | Bomberos, electricistas |
| Festival / concierto / partido | Mucha gente NPC en una zona y ventas extra para los negocios cercanos | Todos (ocio, hostelería, policía) |

Regla: **si nadie responde, el mundo se resuelve solo** (los servicios NPC llegan tarde). La ausencia de jugadores nunca bloquea nada.
