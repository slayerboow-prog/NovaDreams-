# Fase 6 — Edades y progresión

## 6.1 El problema a resolver

En Roblox la mayoría de jugadores juegan sesiones cortas y quieren hacer "cosas de mayores" pronto. Si ser bebé y niño dura demasiado, se van. Si todo es instantáneo, la vida no tiene peso. Además, la edad no puede avanzar con el tiempo real: quien juega 2 horas a la semana nunca llegaría a adulto, y quien lleva 3 meses sin entrar volvería a viejo.

## 6.2 Solución: edad por tiempo jugado + cumpleaños con control

- La edad **solo avanza mientras juegas.**
- Cada etapa tiene un ritmo distinto (las primeras son rápidas):

| Etapa | Edades | Tiempo jugado por año | Duración total aprox. |
|---|---|---|---|
| **Bebé** | 0–3 | 15 min | 45 min |
| **Niño** | 4–12 | 30 min | 4,5 h |
| **Adolescente** | 13–17 | 1 h | 5 h |
| **Adulto joven** | 18–29 | 1,5 h | 18 h |
| **Adulto** | 30–64 | 1,5 h | 52 h |
| **Adulto mayor** | 65+ | 1 h | 25 h o más |

Una vida completa dura unas **100 horas jugadas** (valores de configuración ajustables).

- **Cumpleaños con control:** cuando se completa un año se desbloquea el cumpleaños y el jugador lo "celebra" desde el teléfono. Puede posponerlo para terminar algo (por ejemplo, un curso).
- **Pausar la edad:** a partir de adulto joven el jugador puede pausar el envejecimiento en los ajustes. Así quien quiera vivir siempre a los 30 puede hacerlo.
- **Muerte opcional:** en modo normal nadie muere de viejo por sorpresa. Al llegar a mayor, el jugador **elige** cuándo cerrar su vida y pasar el legado (ver Fase 12, familias y legado). Habrá un "modo realista" opcional con muerte natural por edad y salud.

## 6.3 Cómo empezar una vida

**Decisión:** todos los personajes **nacen como bebé** y viven todas las etapas: escuela, instituto, universidad o FP, empleo y más allá.

| Forma de nacer | Detalle |
|---|---|
| En una **familia de jugadores** | Un hogar invita y el nuevo jugador nace como su hijo (ver Fase 12) |
| En una **familia NPC** | Si no hay familia de jugadores, se nace en un hogar NPC con padres que cuidan de lo básico |
| Como **heredero** de tu personaje anterior | Generaciones: continúas el linaje (ver Fase 12) |

Para que los primeros minutos enganchen (es cuando más jugadores se pierden):
- **Bebé e infancia son cortos y muy jugables** (ver la tabla de 6.2: ~45 min de bebé y ~4,5 h de niño). Nada de "esperar a crecer".
- **Tutorial integrado en la infancia:** los primeros pasos, el colegio y los recados enseñan a moverse, usar el teléfono y el dinero.
- **Objetivos cortos desde el minuto 1:** primer amigo, primera bici, primer cumpleaños con recompensa.

## 6.4 Qué desbloquea cada etapa

| Etapa | Puede | No puede | Sistemas |
|---|---|---|---|
| **Bebé** | Gatear y andar torpe, explorar la casa familiar, interactuar con juguetes, ser cuidado (comer, dormir, bañarse con ayuda de un adulto o un NPC) | Salir solo de casa, conducir, trabajar, tener dinero | Necesidades (dependientes), habilidades iniciales (motricidad, comunicación) |
| **Niño** | Colegio (primaria), parque, actividades extraescolares (deporte, música), paga semanal de los padres, bici | Trabajar, conducir, vivir solo | Educación primaria, habilidades, amistades |
| **Adolescente** | Instituto, deportes de equipo, primeros trabajos a tiempo parcial (repartidor en bici, dependiente, camarero), móvil propio completo, moto pequeña (16+), elegir itinerario | Profesiones con título, comprar casa, préstamos | Instituto, primeros trabajos, decisión de futuro |
| **Adulto joven** | Universidad, FP, cursos, carnet de conducir, todas las profesiones de acceso, alquilar, comprar coche, independizarse, crear negocio, formar un hogar | — | Casi todos los sistemas |
| **Adulto** | Todo: carrera avanzada, hipotecas, inversiones, negocios grandes, familia | — | Todos |
| **Adulto mayor** | Jubilación con pensión, patrimonio, viajes, actividades (golf, jardinería, voluntariado), mentor de jugadores jóvenes, **legado** | Algunas profesiones físicas (bombero en activo) | Pensiones, herencia |

## 6.5 La edad se ve y se nota

- **Escala del personaje** con `Model:ScaleTo()`: bebé ~0,45, niño ~0,65, adolescente ~0,85 y adulto 1,0. Los accesorios del avatar se escalan con él.
- Velocidad, salto y animaciones distintas por etapa (bebé gatea, mayor camina más despacio).
- Ropa y peinados disponibles por etapa.
- **Límites reales:** el servidor comprueba la etapa en cada interacción (una puerta, un trabajo o un coche no se pueden usar si tu etapa no lo permite).

## 6.6 Progresión (para que no sea "dinero infinito")

La progresión no es solo dinero. Hay varios ejes a la vez:

| Eje | Ejemplo |
|---|---|
| **Etapa vital** | Bebé → mayor |
| **Educación** | Primaria → instituto → grado → máster o especialidad |
| **Carrera** | Becario → junior → senior → jefe → director |
| **Habilidades** | Cocina 1–10, conducción 1–10, medicina 1–10… |
| **Patrimonio** | Habitación → apartamento → casa → mansión y propiedades |
| **Social** | Amigos, hogar, familia, reputación |
| **Logros y legado** | Hitos de vida ("Primera casa", "Jefe de cirugía", "Tres generaciones") |

Cada día de juego el jugador debe tener un objetivo claro a corto plazo (terminar el turno, aprobar el examen) y otro a largo plazo (ascender, la casa del barrio de lujo).
