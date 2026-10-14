# 06 — Profesiones jugables: qué se hace de verdad, minuto a minuto

## 6.1 Cómo se lee este documento

Cada profesión usa los **módulos del Motor de actividades** ([Fase 7.1](../diseno/07-profesiones.md)):
Ruta, Atención al cliente, Cocina/producción, Reparación, Diagnóstico, Emergencia, Construcción, Oficina/casos,
Creativo, Enseñanza, Cultivo y Deporte. Aquí se describe **cómo se siente** cada trabajo: qué hace el jugador
minuto a minuto, qué cuenta para el rendimiento y qué momentos especiales lo hacen memorable.

### Estructura común de un turno (10–12 minutos reales)

| Momento | Duración | Qué pasa |
|---|---|---|
| **Fichar** | 10 s | Llegas al lugar, *Fichar* → uniforme automático. Un NPC compañero o jefe te da la **consigna del día** ("Hoy hay partido: mucha gente") |
| **Calentamiento** | 1 min | Tareas sencillas para entrar en ritmo |
| **Núcleo** | 7–9 min | La actividad principal con dificultad creciente. Aparecen **2–3 momentos especiales** |
| **Cierre** | 1 min | Recoger, dejarlo todo listo |
| **Resumen** | 10 s | Rendimiento (0–100%), sueldo × rendimiento, propinas, XP de carrera y de habilidad, progreso al ascenso |

- Se puede **salir antes**: cobras la parte proporcional (sin penalización, pero sin el bonus de turno completo).
- **Turno de noche:** plus del 25% ([Fase 7.3](../diseno/07-profesiones.md)) y eventos distintos.
- **Trabajar en equipo:** si hay otro jugador en el mismo turno y lugar, ambos ganan un bonus de equipo del 10–20%.
- **Nunca se "suspende" un turno:** con rendimiento bajo se cobra menos, pero siempre se cobra algo y se aprende (XP).

### Qué mide el rendimiento (en todas)

**Velocidad** (tiempo por tarea) · **Precisión** (errores) · **Calidad** (hacerlo bien, no solo rápido) ·
**Trato** (clientes o pacientes contentos) · **Seguridad** (no romper, no chocar).
Cada profesión pesa estos factores de forma distinta.

---

## 6.2 Los 4 trabajos del prototipo (v0.1) y cómo evolucionan

Hoy estos trabajos son "coge y lleva siguiendo la línea azul". El plan es mantener esa base (funciona y se
entiende) y añadirle **decisiones y momentos** en M2.

### ☕ Barista — Cafetería Central (Valmar Centro) · Módulo: Atención al cliente + Cocina

- **Requisitos:** adolescente o mayor. **Jefe:** Don Ernesto. **Rangos:** Aprendiz → Barista → Barista jefe → Encargado/a → "El sucesor".

| Minuto | Qué hace el jugador |
|---|---|
| 0:00 | Ficha. Don Ernesto: *"Hoy la máquina tiene el día tonto. Trátala con cariño."* |
| 0:10–1:00 | Calentamiento: limpiar la barra, reponer tazas (coge y lleva) |
| 1:00 | Llega el primer cliente NPC. **Bocadillo con el pedido** (icono: ☕ café solo, 🥛 con leche, 🍫 chocolate, 🥐 cruasán) |
| 1:00–9:00 | **Bucle del pedido:** 1) Tocar la cafetera → minijuego de **tiempo** (parar la aguja en la zona verde para un café perfecto). 2) Si lleva leche: **espumar** (mantener pulsado sin pasarse: "¡la leche no se quema!"). 3) Coger la bollería de la vitrina. 4) Entregar al cliente correcto (cada uno tiene un color de ticket). 5) Cobrar (el TPV hace la cuenta; el jugador solo pulsa) |
| ~3:00 | **Momento: hora punta.** Cola de 4 clientes. Hay que priorizar (los que tienen el icono de prisa ⏱️ dan más propina si van primero) |
| ~6:00 | **Momento: cliente especial.** Un NPC con nombre (Leo Sanz, la alcaldesa, Bernardo…) pide "lo de siempre": hay que recordarlo (pista en la libreta de la barra) |
| ~8:00 | **Momento: Canela se sube a la barra.** Hay que bajarla con cuidado antes de que tire una taza (minijuego rápido) |
| 9:00–10:00 | Cierre: fregar tazas (pulsar al ritmo), apagar la máquina |
| 10:00 | Resumen: cafés perfectos, tiempo medio de espera, propinas |

- **Rendimiento:** Precisión del pedido 35% · Velocidad 30% · Calidad (café perfecto) 25% · Trato 10%.
- **Con jugadores:** si un jugador pide en la barra, el barista jugador recibe su pedido (el cliente jugador elige en un menú). Propina del jugador opcional.
- **Rango alto:** *latte art* (dibujar con el dedo un corazón, una hoja o el escudo de Valmar), crear una bebida de temporada, gestionar a otros baristas.

### 📦 Reponedor — Supermercado Solena · Módulo: Ruta (interior) + Atención al cliente

- **Requisitos:** adolescente. **Rangos:** Reponedor → Jefe/a de pasillo → Encargado/a → Gerente de tienda (Solena).

| Minuto | Qué hace el jugador |
|---|---|
| 0:00 | Ficha. Llega un **palé** al almacén con cajas de colores (frutas, lácteos, limpieza, panadería) |
| 0:10–7:00 | **Reponer:** coger una caja → llevarla al pasillo de su color → colocar en el hueco vacío que brilla. Los productos con fecha más cercana van **delante** (minijuego de ordenar: arrastrar el yogur que caduca antes hacia delante) |
| ~2:00 | **Momento: cliente perdido.** Un NPC pregunta "¿Dónde está la harina?". Hay que acompañarlo (línea guía al revés: tú le guías) |
| ~4:30 | **Momento: derrame.** Una botella rota en el pasillo 3: coger la fregona y el cartel de "suelo mojado" antes de que alguien resbale |
| ~7:00 | **Momento: llegan las ofertas.** Cambiar 5 etiquetas de precio (ir al producto correcto) |
| 7:00–9:00 | Revisar frescos: retirar la fruta pasada (identificar cuál está pocha) |
| 9:00 | Resumen: huecos repuestos, orden de fechas correcto, clientes ayudados |

- **Rendimiento:** Velocidad 35% · Precisión (pasillo y orden) 35% · Trato 15% · Seguridad (derrame) 15%.

### ♻️ Basurero — Servicio de limpieza (Punto Limpio de cada zona) · Módulo: Ruta

- **Requisitos:** adolescente (a pie, con el carrito) · adulto joven con carnet C para el camión. **Rangos:** Operario/a → Conductor/a de camión → Jefe/a de brigada → Responsable de zona.

| Minuto | Qué hace el jugador |
|---|---|
| 0:00 | Ficha en el Punto Limpio. Recibe una **ruta** de contenedores (marcados en el mapa) |
| 0:10–8:00 | **Recogida:** ir a cada contenedor → cogerlo → vaciarlo en el camión o carrito. **Reciclaje:** cada 3 contenedores aparece una bolsa mal separada; hay que arrastrar cada residuo (botella, periódico, piel de plátano, lata) a su contenedor de color (amarillo, azul, marrón, verde) |
| ~3:00 | **Momento: contenedor bloqueado** por un coche mal aparcado. Opción: avisar a la policía (llamada) o rodearlo (más lento) |
| ~5:30 | **Momento: objeto perdido en la basura.** Un NPC ha tirado sin querer algo valioso (unas llaves, un anillo de la abuela). Encontrarlo y devolverlo da gran propina y afinidad |
| 8:00–9:30 | Vuelta al Punto Limpio, descargar en las tolvas correctas |
| 9:30 | Resumen: contenedores, % de reciclaje correcto, tiempo |

- **Rendimiento:** Ruta completa 40% · Reciclaje correcto 35% · Velocidad 25%.
- **Bonus de ciudad:** tras festivales y partidos hay **rutas especiales** con paga doble ("¡Valmar necesita limpiarse!").

### 🚲 Repartidor — Correos y Logística Ruta · Módulo: Ruta

- **Requisitos:** adolescente (bici) · moto con carnet A1 · furgoneta con carnet B. **Rangos:** Repartidor/a → Repartidor/a exprés → Jefe/a de ruta → Coordinador/a de Logística Ruta.

| Minuto | Qué hace el jugador |
|---|---|
| 0:00 | Ficha en Correos. **Carga el vehículo**: arrastrar paquetes a la cesta/maletero (Tetris sencillo: que quepan los grandes) |
| 0:30 | La app de reparto marca 4–6 entregas. **El jugador decide el orden** (mejor ruta = más bonus) |
| 1:00–9:00 | **Repartir:** conducir o pedalear → llegar → llamar al timbre → entregar al NPC (o dejar al vecino si no está: minijuego de hablar con el vecino) |
| ~3:00 | **Momento: paquete frágil** 🥚. Durante esa entrega, los golpes y frenazos bajan su estado |
| ~5:00 | **Momento: entrega urgente** ⏱️. Un medicamento para un vecino mayor: tiempo límite, gran propina |
| ~7:00 | **Momento: perro guardián.** Un perro simpático no deja pasar: darle una galleta (de la cesta) |
| 9:00 | Vuelta a Correos. Resumen: entregas, puntualidad, estado de los paquetes, kilómetros |

- **Rendimiento:** Puntualidad 40% · Estado de los paquetes 30% · Ruta eficiente 20% · Trato 10%.
- **Con jugadores:** los jugadores que compran muebles u objetos grandes reciben **su** pedido de un repartidor jugador si hay.

---

## 6.3 Trabajos de medio tiempo (adolescentes)

Versiones cortas (6–8 min) y más sencillas de: **Repartidor en bici**, **Dependiente de tienda de barrio**,
**Camarero de terraza**, **Ayudante en el mercado de Paco** (pesar fruta, pregonar), **Monitor/a de campamento**
(juegos con niños NPC en el parque) y **Ayudante de socorrista** (vigilar la zona infantil de la playa).
Pagan menos, dan XP de habilidades básicas y no exigen horario.

---

## 6.4 Hostelería y comercio

### 🛍️ Dependiente — Tiendas de ropa, electrónica, zapatería… · Módulo: Atención al cliente

| Minuto | Qué hace |
|---|---|
| 0:00–1:00 | Doblar ropa y colocar en las mesas por talla (arrastrar) |
| 1:00–9:00 | **Clientes con peticiones:** "Busco una camiseta azul de talla M" → buscar en la tienda o en el almacén → probador (esperar) → cobrar. Algunos piden **consejo**: elegir entre 3 productos el que encaja con lo que dice ("Para correr por la playa") |
| ~4:00 | Momento: **devolución** (comprobar el ticket y el estado) |
| ~7:00 | Momento: **escaparate**: montar el escaparate con 3 prendas del tema del día (el encargado lo puntúa) |
| 9:00 | Cuadrar la caja (contar billetes: minijuego de sumar) |

**Rendimiento:** acierto en lo que pide el cliente, tiempo, ventas extra (recomendar un complemento que encaje).

### 🍽️ Camarero — Restaurantes, chiringuito La Ola, hoteles · Módulo: Atención al cliente

| Minuto | Qué hace |
|---|---|
| 0:00 | Montar mesas (cubiertos en su sitio: arrastrar a la silueta) |
| 1:00–9:00 | **Sala:** sentar a los clientes → tomar nota (el pedido aparece en la libreta) → llevarla a cocina → recoger los platos (bandeja: hasta 3, cuidado con el equilibrio al caminar deprisa) → servir en la mesa correcta → cobrar → limpiar |
| ~3:00 | Momento: **cliente con alergia** 🥜: avisar a cocina (si no, el plato vuelve) |
| ~5:00 | Momento: **grupo grande** (8 personas): juntar mesas |
| ~8:00 | Momento: **cumpleaños** en la mesa 4: llevar la tarta y la sala canta (los jugadores presentes pueden unirse) |

**Con jugadores:** si hay cocinero jugador, los pedidos van a él; si no, a un cocinero NPC. Es el mejor ejemplo de trabajo en equipo.
**Chiringuito La Ola** (Playa Dorada): versión de verano con bebidas frías, más prisa y propinas mejores al atardecer.

### 👩‍🍳 Cocinero — Restaurantes, Mega Burger, food truck de Omar · Módulo: Cocina/producción

- **Requisitos:** FP Cocina (Mega Burger y food truck aceptan sin título como ayudante). **Rangos:** Ayudante → Cocinero/a → Jefe/a de partida → Jefe/a de cocina → Chef con restaurante propio.

| Minuto | Qué hace |
|---|---|
| 0:00–1:00 | **Mise en place:** preparar ingredientes (cortar verduras: deslizar el dedo al ritmo) |
| 1:00–9:00 | **Comandas** en la pantalla. Cada plato es una **receta por pasos**: *cortar → cocinar (sartén: darle la vuelta en su momento; horno: sacar a tiempo) → emplatar (colocar en la silueta)*. Varios fuegos a la vez |
| ~3:00 | Momento: **se acaba un ingrediente** → pedirlo al almacén o cambiar el plato del día |
| ~6:00 | Momento: **crítico gastronómico** (NPC con boina): un plato que debe salir perfecto |
| ~8:00 | Momento: **fuego en la sartén** 🔥: taparla con la tapa (nunca agua). Enseña seguridad real |
| 9:00 | Limpiar la cocina |

**Rango alto:** crear recetas propias (combinar ingredientes de una lista y ponerle nombre, filtrado), menú de temporada con productos de Villaverde.

---

## 6.5 Oficios

### 🔧 Mecánico — Taller "El Pistón" (San Roque) y talleres · Módulo: Reparación

| Minuto | Qué hace |
|---|---|
| 0:00 | Entra un coche (de NPC o **de un jugador** que ha pedido cita) |
| 0:30–2:00 | **Diagnóstico:** escuchar el motor (elegir entre 3 sonidos cuál es el raro), mirar las luces del salpicadero, levantar con el elevador y revisar |
| 2:00–4:00 | **Elegir la pieza** correcta del almacén (bujía, pastillas de freno, batería, rueda…) |
| 4:00–6:00 | **Reparar:** minijuego según la pieza: tornillos en orden en estrella (rueda), conectar cables del color correcto (batería), girar hasta el clic (filtro) |
| ~5:00 | Momento: **el cliente pregunta** "¿Es grave?": explicar con 3 opciones (honesto, técnico o asustar). Lo honesto da más reputación |
| 6:00–8:00 | Segundo coche o **grúa**: acudir a un coche averiado en la carretera (Ruta + Reparación) |
| 9:00 | Prueba en el circuito del taller y entrega |

**Con jugadores:** los coches de jugadores con estado bajo ([Fase 10](../diseno/10-vehiculos-transporte.md)) llegan como citas. El mecánico jugador pone el precio dentro de una horquilla justa.

### ⚡ Electricista y 🚰 Fontanero — a domicilio · Módulo: Reparación + Ruta

- **Turno:** la app de avisos muestra averías en casas NPC y **de jugadores** (luz que parpadea, grifo que gotea, calentador).
- **En casa:** localizar la avería (seguir el cable o la tubería por la pared con el "detector"), cortar la luz o el agua **primero** (si no, pierdes puntos de seguridad), reparar (minijuego de empalmar cables o encajar tuberías), comprobar y cobrar.
- **Momento especial:** tras una tormenta, **apagón de barrio**: varios avisos a la vez con paga extra.

### 🏗️ Constructor — Obras y parcelas de jugadores · Módulo: Construcción

- **Requisitos:** adulto joven. **Rangos:** Peón → Oficial → Encargado/a de obra → Jefe/a de obra.
- **Turno:** se recibe un **plano** (de un jugador arquitecto, de un proyecto de ciudad o de una casa de jugador en obra, [Fase 9.4](../diseno/09-viviendas.md)). Fases: *cimientos* (colocar bloques en la rejilla marcada) → *estructura* (vigas, con grúa) → *paredes* → *tejado* → *acabados*. Cada fase es un minijuego de colocar piezas en su silueta, con casco obligatorio (si no, no se puede entrar).
- **Momento especial:** **proyecto de ciudad** (el faro): los turnos cuentan doble para el progreso global.
- **Con jugadores:** acelerar la obra de la casa de otro jugador y cobrar por ello.

---

## 6.6 Transporte

### 🚕 Taxista · Módulo: Ruta

- **Requisitos:** carnet B + licencia de taxi. **Turno:** llamadas de NPC (y jugadores) en la app → recoger → el pasajero da el destino ("Al Estadio Altamar, que llego tarde") → conducir → cobrar según distancia y trato.
- **Decisiones:** atajo por la autopista (más rápido, más caro) o ciudad; **conversación** con el pasajero (elegir respuestas: algunos quieren charla, otros silencio).
- **Momentos:** pasajera con prisa al hospital (sin saltarse semáforos: si corres demasiado, multa), turista perdido que quiere ver el faro, olvido de un paraguas en el asiento (devolverlo).
- **Rendimiento:** puntualidad, conducción suave, trato, sin multas.

### 🚌 Conductor de autobús · Módulo: Ruta

- **Requisitos:** carnet D. **Turno:** conducir la línea asignada entre zonas → parar en cada parada (frenar dentro de la marca), abrir puertas, esperar a los NPC y jugadores, cerrar, seguir. Horario: ir adelantado o retrasado baja el rendimiento.
- **Momentos:** línea especial de partido (autobús lleno de aficionados cantando), abuelo que tarda en subir (esperar = +trato), desvío por obras.
- **Con jugadores:** los jugadores que usan el bus viajan con un conductor jugador en vez de NPC.

---

## 6.7 Servicios públicos

### 🚓 Policía — Comisaría de Valmar Centro · Módulo: Emergencia + Ruta + Oficina

- **Requisitos:** Academia de Policía + forma física. **Rangos:** Agente → Cabo → Sargento → Inspector/a → Comisario/a.
- **Normas del juego:** la policía **no puede detener a jugadores** ([Fase 7.5](../diseno/07-profesiones.md)). Trabaja con NPC, tráfico e incidencias del sistema.

| Minuto | Qué hace |
|---|---|
| 0:00 | Briefing del comisario Ríos (y su refrán equivocado). Coge el coche patrulla |
| 0:30–3:00 | **Patrulla:** ruta por zonas marcadas. Los vecinos NPC saludan; algunos cuentan cosas (pistas de incidencias) |
| ~2:00 | **Aviso: objeto perdido** → buscar pistas y devolverlo al dueño |
| ~4:00 | **Control de velocidad** con radar: los coches NPC (y jugadores) que pasen del límite reciben multa automática; el policía decide si es aviso o multa (el sistema la pone) |
| ~6:00 | **Aviso: robo en una tienda NPC** → llegar → hablar con el dependiente (descripción) → **persecución a pie** del ladrón NPC (esquivar obstáculos) → alcanzarlo = detenido (se sienta en el coche, sin violencia) |
| ~8:00 | **Accidente de tráfico**: poner conos, desviar el tráfico con gestos (pulsar la dirección correcta), tomar declaración |
| 9:00 | **Informe:** rellenar el parte (elegir lo que pasó en 3 preguntas) |

### 🚒 Bombero — Parque de Los Pinos · Módulo: Emergencia

- **Requisitos:** Oposición de bombero + forma física. **Rangos:** Bombero/a → Cabo → Sargento → Jefe/a de parque.

| Minuto | Qué hace |
|---|---|
| 0:00–2:00 | En el parque: **revisar el equipo** (manguera, casco, botella), entrenar (circuito de obstáculos), lavar el camión. Mesa de ping-pong y cocina: los bomberos esperan juntos |
| ~2:00 | 🔔 **¡Aviso!** Deslizarse por la barra (animación divertida), subir al camión, sirena. Conduce un jugador o el NPC |
| Llegada | **Evaluar:** ¿de dónde sale el humo? Elegir entrada |
| Incendio | **Apagar:** apuntar la manguera a la base de las llamas (no al humo), con la presión justa. El fuego se extiende si se deja |
| Rescate | **Buscar a los NPC** atrapados con la cámara térmica (se ven en naranja) y sacarlos |
| Final | Ventilar, comprobar que no hay rescoldos, informe. Radio Valmar da la noticia |
| Sin fuegos | Rescate del gato en el árbol (escalera), inundación en un sótano (bomba de agua), árbol caído en tormenta (motosierra de juego, sin sangre ni riesgo) |

**En equipo:** una manguera necesita 2 personas para la presión máxima; los incendios grandes requieren coordinarse.

### 🩺 Enfermero y Médico — Hospital General (Valmar Norte) y centros de salud · Módulo: Diagnóstico + Emergencia

- **Requisitos:** Grado en Enfermería / Grado en Medicina + Residencia ([Fase 8.3](../diseno/08-educacion.md)).
- **Rangos médico:** MIR → Médico/a → Especialista → Jefe/a de servicio. **Enfermero:** Enfermero/a → Supervisor/a.

**Turno de médico en urgencias:**

| Minuto | Qué hace |
|---|---|
| 0:00 | El Dr. Bravo reparte los boxes: *"Respira. Empezamos."* |
| 0:30–9:00 | **Bucle del paciente:** 1) **Triaje** (el enfermero, o tú si no hay): colores según gravedad. 2) **Hablar** con el paciente: 3 preguntas a elegir ("¿Dónde le duele?", "¿Desde cuándo?", "¿Ha comido algo raro?") → aparecen síntomas. 3) **Pruebas** (termómetro, fonendo, radiografía, análisis): cada una tarda y cuesta tiempo del turno; hay que elegir las útiles. 4) **Diagnóstico** entre 3–4 opciones. 5) **Tratamiento**: receta, vendaje, escayola (minijuego de envolver), puntos (seguir la línea), o **quirófano** si es especialista |
| ~3:00 | Momento: **niño asustado** (calmarlo con diálogo antes de explorar: da más trato) |
| ~6:00 | Momento: **llega la ambulancia** con un paciente de una emergencia de la ciudad: prioridad |
| Especialista | **Minijuego de quirófano:** secuencia de pasos con precisión (sin imágenes explícitas: se ve la sábana, las manos, los monitores) |

**Enfermero:** triaje, tomar constantes (pulsar al ritmo del pulso), poner vías (apuntar en la vena marcada en el brazo de un maniquí estilizado), vendajes, **cuidado de pacientes ingresados** (ruta por las habitaciones: medicación a la hora, la comida, hablar con ellos).
**Con jugadores:** un jugador con la salud baja ([A1.2](../diseno/A1-negocios-servicios-mundo.md)) o accidentado llega a urgencias y le atiende un médico jugador si hay.
**Normas de Roblox:** nada de sangre explícita ni heridas gráficas; las enfermedades son genéricas ("dolor de tripa", "fiebre", "torcedura").

### 🏊 Socorrista — Playa Dorada · Módulo: Emergencia + Ruta · 🔶 Propuesta (no está en el catálogo del diseño)

- **Requisitos:** curso de socorrismo con Kai (habilidad Natación 3). Encaja con el módulo Emergencia sin trabajo extra.
- **Turno:** vigilar desde la torre (prismáticos: detectar al NPC que hace señas), poner la **bandera** según el mar (verde, amarilla, roja), **rescate** (correr, nadar o moto de agua, llevar el flotador, traer a la orilla), primeros auxilios leves (picadura de medusa: vinagre de juego), niños perdidos (llevarlos a la torre y anunciarlo por megafonía).

---

## 6.8 Oficina, educación y medios

### 👩‍🏫 Profesor — Colegios, instituto, universidad · Módulo: Enseñanza

- **Requisitos:** Grado + máster docente. **Turno:** dar **clases reales** a alumnos NPC y **jugadores** ([Fase 8.1](../diseno/08-educacion.md)).
  El profesor elige el **orden de las preguntas** del tema, lanza las actividades (quiz, práctica, trabajo en grupo), **ayuda** a los alumnos que se atascan (van levantando la mano) y **pone orden** (alumno NPC distraído: llamarle la atención con amabilidad).
- **Rendimiento:** nota media de la clase, alumnos atendidos, participación.
- **Por qué es especial:** los alumnos jugadores ganan un bonus si les da clase un jugador.

### 💻 Programador — Tecnoval, Óptima Soft · Módulo: Oficina/casos

- **Requisitos:** Grado en Informática o curso intensivo en la Academia de Código. **Rangos:** Junior → Sénior → Líder técnico → CTO.
- **Turno:** reunión de 30 s ("stand-up": elegir tu tarea del tablero) → **tareas** que son puzzles visuales: *ordenar bloques de código* para que el robot llegue a la meta, *encontrar el bug* (la pieza que no encaja), *conectar* módulos. Momentos: "¡Se ha caído la web!" (urgencia de 2 min), revisión de código de un compañero (elegir el error), lanzamiento de un videojuego de Tecnoval (evento de equipo con otros programadores jugadores).

### ⚖️ Abogado — Bufetes del Distrito Financiero · Módulo: Oficina/casos

- **Requisitos:** Grado en Derecho + máster. **Rangos:** Pasante → Asociado/a → Socio/a → Bufete propio.
- **Turno:** **casos civiles sencillos y aptos para todos** (la valla del vecino, un contrato de alquiler, una multa injusta, una tienda que no devuelve el dinero): leer el caso (3 líneas), **buscar pruebas** en documentos (encontrar la frase clave), **entrevistar** (elegir preguntas), **defender** ante el juez NPC eligiendo los 3 argumentos correctos en orden. Sin delitos violentos.
- **Con jugadores:** revisar contratos entre jugadores (compraventa de casas, [Fase 4.5](../diseno/04-datos.md)) por una comisión.

### 📰 Periodista y 📷 Fotógrafo — Media Sur / Radio Valmar · Módulos: Oficina + Creativo

- **Turno de periodista:** el jefe (Leo Sanz) asigna un tema → **ir al lugar** (evento, emergencia, inauguración) → **entrevistar** (elegir preguntas; los NPC responden; los jugadores pueden responder de verdad, texto filtrado) → **escribir** el titular (elegir y ordenar piezas de frase, o escribir libre filtrado) → publicar. **Los artículos aparecen en la app Noticias** de todos.
- **Fotógrafo:** modo cámara con encuadre y zoom. La foto se puntúa por *sujeto correcto en el centro*, *luz* y *momento* (gol, llamas apagándose, fuegos artificiales). Las mejores salen en Noticias.

### 🏠 Agente inmobiliario · Módulo: Oficina + Atención al cliente

- **Turno:** clientes NPC y jugadores buscan casa con requisitos ("3 habitaciones, cerca de un colegio, menos de $90.000") → buscar en la app → **enseñar la casa** (visita guiada: señalar lo bueno) → negociar dentro de una horquilla → contrato. Comisión por venta. Gestiona ventas de jugadores ([Fase 9.5](../diseno/09-viviendas.md)).

---

## 6.9 Campo y deporte

### 🌾 Agricultor — Villaverde · Módulo: Cultivo/cuidado

- **Requisitos:** terreno rural (o trabajar para la Cooperativa sin terreno propio). **Rangos:** Jornalero/a → Agricultor/a → Socio/a de la cooperativa → Presidente/a (título honorífico junto a Maribel).
- **No es un turno de 12 minutos, es un ciclo:** los cultivos crecen con el **tiempo jugado** (no real).

| Momento | Qué hace |
|---|---|
| Mañana | **Animales:** dar de comer a las gallinas (recoger huevos), ordeñar la vaca (pulsar al ritmo), sacar las ovejas |
| Siembra | Arar con el tractor (conducir en líneas rectas), sembrar (elegir cultivo según la **estación**: tomates en verano, calabazas en otoño) |
| Cuidado | **Regar** (no demasiado), quitar malas hierbas, **espantar cuervos**. En tormenta: tapar los cultivos |
| Cosecha | Recoger (minijuego rápido), clasificar por calidad |
| Venta | Cooperativa (precio fijo), **mercadillo del domingo** (vendes tú: más dinero) o **contrato** con un restaurante de jugador |

### 🐾 Veterinario — Clínica veterinaria de Villaverde · Módulo: Diagnóstico

- **Requisitos:** Grado en Veterinaria. Mismo bucle que el médico (hablar con el dueño, explorar, pruebas, diagnóstico,
  tratamiento) pero con **mascotas de jugadores y NPC** y **animales de granja** (visitas a domicilio en Villaverde).
- **Momentos:** vacunar a un perro nervioso (calmarlo primero), ayudar a nacer a un corderito en primavera (escena tierna, sin detalles),
  revisión de las mascotas de los niños del colegio.

### ⚽ Deportista — Valmar CF / Búhos · Módulo: Deporte

- **Requisitos:** habilidad física (entrenar en el gimnasio y en el campo). **Rangos:** Cantera → Amateur → Profesional → Titular → Capitán/a → Estrella.
- **Semana de un futbolista:** **entrenamientos** (turnos de 8 min: circuito de conos, pases a la diana, tiros a puerta: cada uno sube una estadística) y **partido del sábado** (5 contra 5 simplificado con NPC y jugadores; controles sencillos: pase, tiro, presión).
- **Momentos:** penalti decisivo (apuntar y medir la fuerza, depende de la habilidad, no del azar), firma de autógrafos a niños tras el partido, entrevista de Leo Sanz.
- **Entrenador personal** (variante): dar sesiones a jugadores en el gimnasio (módulo Enseñanza).

---

## 6.10 Empresario

- **No es un turno, es un estilo de vida** ([A1.1](../diseno/A1-negocios-servicios-mundo.md)). Un día típico de empresario:

| Momento | Qué hace |
|---|---|
| Llegar | Panel de la app **Empresa**: ventas de ayer, reseñas (NPC y jugadores), stock, empleados |
| Decidir | Precios (subirlos da más por venta pero menos clientes), **pedido de suministros** (a la cooperativa, a otros negocios de jugadores), horario |
| Trabajar | Puede trabajar en su propio negocio con el módulo del sector (barista en su cafetería) → el negocio gana más con el dueño presente |
| Personas | Contratar (publicar oferta en la app Empleo), dar el **"empleado del día"** (bonus a un empleado jugador) |
| Crecer | Mejoras del local (modo construcción), abrir en otra zona, patrocinar un evento (cartel en el festival) |

Momentos especiales: **inauguración** (Radio Valmar, clientes extra el primer día), **inspección de sanidad** (tener todo limpio y ordenado), **crítico gastronómico**, **temporada alta** (verano en Playa Dorada).

---

## 6.11 Resumen: módulo, lugar y hito de cada profesión

| Profesión | Módulo principal | Lugar | Hito |
|---|---|---|---|
| Barista | Atención al cliente | Cafetería Central (Centro) | v0.1 → M2 |
| Reponedor | Ruta interior | Supermercado Solena | v0.1 → M2 |
| Basurero | Ruta | Punto Limpio (todas) | v0.1 → M2 |
| Repartidor | Ruta | Correos, Logística Ruta | v0.1 → M2 |
| Dependiente | Atención al cliente | Tiendas (todas) | M2 |
| Camarero | Atención al cliente | Restaurantes, La Ola | M2 |
| Cocinero | Cocina | Restaurantes, Mega Burger | M2 |
| Mecánico | Reparación | Taller El Pistón (San Roque) | M2 |
| Taxista | Ruta | Toda la región | M2 |
| Enfermero, Médico | Diagnóstico | Hospital General (Valmar Norte), centros de salud | M3 |
| Profesor | Enseñanza | Colegios, Campus | M3 |
| Programador | Oficina | Tecnoval, Óptima Soft (Financiero) | M3 |
| Policía, Bombero | Emergencia | Comisaría (Centro), Parque (Los Pinos) | M4 |
| Socorrista 🔶 | Emergencia | Playa Dorada | M4 |
| Conductor de autobús | Ruta | Líneas entre zonas | M4 |
| Periodista, Fotógrafo | Oficina, Creativo | Media Sur (Financiero) | M4 |
| Deportista | Deporte | Estadios | M4 |
| Electricista, Fontanero | Reparación | A domicilio | M4 |
| Constructor, Agente inmobiliario, Arquitecto | Construcción, Oficina | Obras, inmobiliarias | M6 |
| Abogado | Oficina | Bufetes (Financiero) | M6 |
| Empresario | Todos | Su negocio | M7 |
| Agricultor, Veterinario | Cultivo | Villaverde | M8 |
