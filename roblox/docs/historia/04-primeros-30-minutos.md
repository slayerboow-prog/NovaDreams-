# 04 — Los primeros 30 minutos: nacer, crecer y aprender a jugar

## 4.1 El objetivo

Los primeros minutos deciden si un jugador de Roblox se queda o se va. En 30 minutos el jugador debe:

1. **Sentir que su vida ha empezado** (nacimiento, familia, casa, nombre).
2. **Aprender los controles y los sistemas básicos sin darse cuenta** (moverse, interactuar, necesidades, la línea guía,
   el dinero, el teléfono, el autobús, los amigos).
3. **Conseguir algo cada 1–3 minutos** (un recuerdo, un objeto, un cumpleaños).
4. **Salir con un sueño** ("Quiero ser bombero/a") que se convierte en su primera meta larga.

### Reglas del tutorial

| Regla | Cómo se cumple |
|---|---|
| **Nada de muros de texto** | Máximo 2 líneas por globo. Siempre con icono. Se aprende haciendo |
| **Algo pasa cada 30–60 segundos** | Un sonido, un NPC que habla, un objeto nuevo, un premio |
| **No se puede fallar** | No hay derrotas. Si el jugador se atasca 20 s, Abu le da una pista; a los 40 s aparece la flecha |
| **Se puede saltar** | Cada escena se salta con un botón. Los jugadores veteranos (ya hicieron el tutorial en otra vida) tienen el **modo veterano**: mismas etapas, sin explicaciones |
| **Móvil primero** | Botones grandes, controles explicados con el icono de móvil o de teclado según el dispositivo |
| **Voz del tutorial** | Siempre **Abu** (Rosa o Tomás, lo elige el jugador). Una sola voz que acompaña hace de guía y de personaje con cariño |
| **Recompensa visible** | Cada paso da un **Recuerdo** (foto en el Álbum) o un objeto |

## 4.2 🔶 Propuesta de ajuste: la etapa de bebé en la primera vida

El diseño ([Fase 6.2](../diseno/06-edades-progresion.md)) da **15 minutos por año** al bebé (45 min en total).
Para los primeros 30 minutos proponemos un valor distinto **solo en la primera vida de cada cuenta**:

| | Valor del diseño | Propuesta primera vida |
|---|---|---|
| Minutos por año de bebé | 15 | **6** |
| Duración de la etapa de bebé | ~45 min | **~18 min** |
| A los 30 minutos el jugador… | Todavía es bebé (2 años) | **Ya es niño y ha ido al colegio** |

Motivo: un jugador nuevo necesita ver el colegio, el dinero y a su primer amigo antes de que termine su primera sesión.
En las vidas siguientes, o si nace en una **familia de jugadores** (que disfrutan cuidando al bebé), se usa el valor normal.
Es un solo número en la configuración (`FirstLifeBabyMinutesPerYear = 6`). **Pendiente de decidir**; si se aprueba,
se actualiza la Fase 6.

El resto de este documento usa la propuesta. Si no se aprueba, el mismo contenido sigue funcionando: simplemente
el colegio llega en la segunda sesión.

## 4.3 La línea de tiempo, minuto a minuto

```
0:00  Crear la vida ──► 1:30 Nacimiento ──► 2:30 BEBÉ (0 años): explorar la casa
                                              8:00 🎂 1 año
                                              8:30 Primeros pasos y primera palabra
                                             14:00 🎂 2 años
                                             14:30 Primera salida: el parque y el primer amigo
                                             20:00 🎂 3 años → ¡NIÑO!
                                             21:00 Primer día de colegio (autobús escolar)
                                             27:00 La paga y el primer helado
                                             29:00 Tu primer teléfono y tu sueño
                                             30:00 Resumen: "Tus primeros años"
```

### 0:00 – 1:30 · "Una nueva vida" (crear el personaje)

Pantalla superpuesta sobre una vista aérea de Valmar al amanecer (se ve la región entera: el mar, los montes, el faro apagado).

1. **Apariencia:** "Usar mi avatar de Roblox" (recomendado, un clic) o personalizar tono de piel, pelo y cara.
2. **Nombre y apellido:** sugerencias generadas + escribir el propio (filtrado con `TextService`). Botón 🎲 *Otro nombre* (sugiere otro, no es azar con premio).
3. **Tu Abu:** Abu Rosa o Abu Tomás (se ve una foto sonriendo y una frase de cada uno).
4. **Tu familia:** 4 tarjetas (Familia del Pinar, del Mercado, de la Cala, del Valle; ver [Personajes 2.4](02-personajes.md)).
   Cada tarjeta enseña la casa, la zona y el pequeño talento inicial.
5. **Tu mascota:** perro o gato, y su nombre.

Botón grande **"¡Empezar a vivir!"**. Todo se puede dejar por defecto: con 3 clics se empieza.

### 1:30 – 2:30 · El nacimiento (escena de 30 s, se puede saltar)

- Pantalla en blanco, sonido suave de latido. La imagen se enfoca poco a poco: caras de la familia inclinadas sobre la cuna.
- Abu: *"Bienvenido al mundo, {nombre}. Valmar te estaba esperando."* (`TUTO.NACER.01`)
- Radio Valmar suena bajito en la habitación: *"…y hoy damos la bienvenida a los nuevos vecinos de Valmar…"*
- Aparece el **Álbum** con la primera foto: **Recuerdo "Bienvenida al mundo"**.
- Fundido: *"Unas semanas después…"* → el bebé en la alfombra del salón de su casa.

> Si el jugador nace en una **familia de jugadores**, la escena es en su casa y sus padres jugadores aparecen en ella.
> Abu sigue siendo el guía (como NPC visitante), pero los padres pueden hacer las acciones de cuidado.

### 2:30 – 8:00 · Bebé (0 años): "La casa es un mundo"

El bebé **gatea**. La casa es el primer escenario: pequeña, segura y llena de cosas que tocar.

| Minuto | Objetivo (tarjeta) | Qué aprende | Recompensa |
|---|---|---|---|
| 2:30 | "Gatea hasta el sonajero" | **Moverse** (joystick o WASD) | Sonajero (se equipa) |
| 3:15 | "Mira el móvil de estrellas de la cuna" | **Cámara** (arrastrar para mirar) | — |
| 3:45 | "Toca el piano de juguete" | **Interactuar** (mantener **E** / tocar el botón) | Sonido divertido, Recuerdo "Primer concierto" |
| 4:30 | La barriguita suena 🍼: "Llama a tu familia" | **Necesidades**: aparece el anillo de hambre. Botón *Llamar* → un familiar da el biberón | El anillo se llena |
| 5:30 | "¡{mascota} quiere jugar! Síguele" | **La línea guía** (la misma línea azul que usarán los trabajos) | Recuerdo "Mejor amigo peludo" |
| 6:30 | "Busca el patito para el baño" | Explorar habitaciones. Pista si tarda | Baño con burbujas: sube la **higiene** |
| 7:15 | Bostezo 😴: "Ve a la cuna" | **Dormir** = pasar el tiempo (la noche pasa en 5 s) | Energía llena |
| 8:00 | 🎂 Aparece la tarta en la pantalla | **El cumpleaños con control** (se celebra pulsando; se puede posponer) | Ver abajo |

### 8:00 · 🎂 Primer cumpleaños

- Botón **"¡Celebrar mi cumpleaños!"**. Familia, Abu y la mascota alrededor de la tarta. Soplar la vela = pulsar.
- El bebé **crece un poco** (animación de escala).
- **Regalo:** el jugador **elige** entre 3 juguetes. Cada uno da un empujoncito de habilidad:
  - ⚽ Pelota → Deporte · 🎨 Ceras de colores → Creatividad · 🧱 Bloques → Lógica.
- Recuerdo "1 añito". Abu: *"¿Un año ya? ¡Si ayer eras así de pequeñito!"*

### 8:30 – 14:00 · Bebé (1 año): primeros pasos y primera palabra

| Minuto | Objetivo | Qué aprende | Recompensa |
|---|---|---|---|
| 8:30 | "Ponte de pie agarrándote al sofá" y "Da 5 pasos hasta Abu" | Pasa de gatear a **andar** (torpe, gracioso) | Recuerdo "Primeros pasos" (foto con Abu con los brazos abiertos) |
| 9:30 | "Sube al cojín gigante" | **Saltar** | — |
| 10:15 | "Di tu primera palabra" | **Elegir en un menú de diálogo**: *"¡Abu!"*, *"¡Mamá!"/"¡Papá!"* (según la familia), *"¡Agua!"*, *"¡{mascota}!"* | Recuerdo "Primera palabra" con la palabra elegida. La familia reacciona |
| 11:00 | "¡Al escondite! Encuentra a {mascota}" (3 escondites) | Explorar la casa y el **jardín/balcón** | Pegatina para el Álbum |
| 12:30 | "Ayuda a regar las plantas con Abu" | Primera "tarea" (preparación del sistema de tareas) | +Afinidad con Abu |
| 13:30 | Merienda y siesta | Recordatorio de necesidades (ya sin explicación) | — |

### 14:00 · 🎂 Segundo cumpleaños

- Tarta, crece un poco más. Regalo (a elegir): **correpasillos**, **patinete de 3 ruedas** o **cubo y pala de playa**
  (primer "vehículo" o juguete de exterior).
- Abu: *"¡Ya eres mayor para salir de paseo! ¿Vamos al parque?"*

### 14:30 – 20:00 · Bebé (2 años): la primera salida

**Primera vez fuera de casa.** El bebé va de la mano de Abu (no puede salir solo: límite de etapa).
La salida es al parque de su zona (Parque de los Pinos, plaza de San Roque, paseo marítimo o plaza del Pozo).

| Minuto | Objetivo | Qué aprende | Recompensa |
|---|---|---|---|
| 14:30 | "Sigue a Abu por la acera" | La ciudad: coches que frenan, peatones, **cruzar por el paso de cebra** (semáforo en verde) | Recuerdo "Mi barrio" |
| 16:00 | "¡Tobogán!", "Columpio" | Interacciones de ocio: sube la **diversión** | — |
| 17:00 | Aparece **Nico** en el arenero: "Saluda a Nico" | **Social**: botón *Saludar* (emote), **barra de amistad** | Recuerdo "Mi primer amigo". Nico entra en contactos |
| 18:00 | "Construid un castillo de arena juntos" | Actividad en pareja (preparación de las actividades de equipo) | Bonus de amistad |
| 19:00 | Abu compra 2 helados en la heladería | Se **ve** el dinero: Abu paga, aparece el precio | Helado (sube el ánimo) |
| 19:40 | Vuelta a casa | — | — |

> Si hay **niños jugadores** en el parque, el juego propone saludarles a ellos en lugar de a Nico (Nico se queda como amigo extra).

### 20:00 · 🎂 Tercer cumpleaños → ¡Eres un niño!

- Gran celebración: la familia, Abu, Nico y (si hay) amigos jugadores invitados. **Cambio de etapa**: animación
  especial, el personaje crece a la escala de niño, ropa nueva de niño.
- **Pantalla de etapa** (se verá en cada cambio de etapa): *"¡Ahora eres NIÑO!"* con 3 iconos de lo nuevo:
  🎒 colegio · 🚲 bici · 💰 paga semanal.
- Regalo: **bici con ruedines** (primer vehículo real, ver [Fase 10](../diseno/10-vehiculos-transporte.md)).
- Recuerdo "¡Ya soy mayor!".

### 21:00 – 27:00 · El primer día de colegio

| Minuto | Objetivo | Qué aprende | Recompensa |
|---|---|---|---|
| 21:00 | "Prepara la mochila" (coger 3 cosas del cuarto) | **Inventario** básico | Mochila equipada |
| 21:40 | "Ve a la parada con Abu y sube al autobús escolar" | **El autobús** (el mismo sistema de paradas que para viajar entre zonas) | — |
| 22:30 | Llegada al colegio de tu zona. **Lucía Ortega** te recibe | Presentación de la maestra (ver nota) | — |
| 23:00 | **Clase de 3 min: "Mates con manzanas"** — contar, sumar arrastrando manzanas a cestas | **Actividad de clase** (el mismo motor de actividades que los trabajos, [Fase 7](../diseno/07-profesiones.md)) | Primera nota ("¡Sobresaliente!" casi siempre: es el primer día) |
| 26:00 | **Recreo**: pilla-pilla con Nico, Sara y Omar | Correr, esquivar | Conoces a **Sara** y **Omar** |

> **Nota de producción:** la clase es una actividad instanciada por aula, así que Lucía puede dar la primera clase en el
> colegio de cualquier zona. Después de la primera semana, cada colegio tiene su propio profesor NPC (o un profesor
> jugador, [Fase 8](../diseno/08-educacion.md)) y Lucía queda como tutora del Colegio de Los Pinos.

### 27:00 – 29:00 · La paga y el primer helado

- Vuelta a casa en el autobús escolar (se cruza la ciudad: primer vistazo a otras zonas).
- En casa, la familia da la **primera paga**: **$10** (*"Por haber sido tan valiente en tu primer día"*).
  Aparece el **dinero** en el HUD por primera vez.
- Objetivo: **"Cómprate algo con tu paga"**. La línea guía lleva a la heladería o al quiosco más cercano.
  Se elige entre helado, cromos (álbum de cromos de Valmar: colección **fija**, se compran por número, no en sobres aleatorios)
  o un timbre para la bici.
- Se aprende a **comprar** (acercarse al mostrador → *Comprar* → confirmar).

### 29:00 – 30:00 · Tu primer teléfono y tu sueño

- En casa, Abu te da **tu primer teléfono (versión niño)**: *"Para que me llames cuando quieras. ¡Y para que no te pierdas!"*
- Se abren solas, una a una, las 3 apps de niño: **Mapa** (dónde estás y dónde está el colegio), **Álbum** (tus recuerdos) y
  **Tareas** (las 3 tareas del día).
- **La pregunta del sueño:** Abu: *"Oye, {nombre}… ¿y tú qué quieres ser de mayor?"*

  | Sueño | Profesión que activa como Meta de vida |
  |---|---|
  | 🚒 "¡Bombero/a!" | Bombero |
  | 🩺 "¡Médico/a!" | Médico |
  | 🚓 "¡Policía!" | Policía |
  | 👩‍🍳 "¡Cocinero/a!" | Cocinero / restaurante propio |
  | ⚽ "¡Futbolista!" | Deportista |
  | 🤖 "¡Inventor/a!" | Ingeniero / programador |
  | 🎨 "¡Artista!" | Creador / fotógrafo / músico |
  | 🌾 "¡Granjero/a!" | Agricultor |
  | 💼 "¡Jefe/a de mi empresa!" | Empresario |
  | 🤷 "¡Aún no lo sé!" | Sin meta fija: el juego propone probar varias cosas (misión "Explorador de oficios") |

  El sueño se guarda en la memoria de Abu y de Lucía Ortega, que preguntarán por él durante toda la vida.
  Se puede cambiar cuando se quiera (los sueños cambian).

### 30:00 · Resumen: "Tus primeros años"

Pantalla de celebración con las fotos del Álbum pasando rápido (bienvenida, primeros pasos, primera palabra, Nico, colegio)
y tres datos: **edad 3 años**, **1 amigo**, **8 recuerdos**. Debajo, **el gancho**:

> *"Mañana: clase de deporte y ¡carrera de bicis con Nico! 🚲"*
> *"Tu sueño: ser bombero/a. Primer paso → visitar el parque de bomberos de Los Pinos (excursión del colegio)."*

Logro: **"Una vida empieza"**. Recompensa: 5 **Estrellas de Valmar** y camiseta "Nací en Valmar".

## 4.4 Lo que el jugador ha aprendido sin leer un manual

| Sistema | Dónde lo aprendió |
|---|---|
| Moverse, cámara, saltar | Casa, bebé |
| Interactuar (E / tocar) | Piano de juguete |
| Necesidades (hambre, energía, higiene, diversión) | Biberón, baño, cuna, parque |
| La línea guía | Seguir a la mascota |
| Cumpleaños con control | Primer cumpleaños |
| Elegir en diálogos | Primera palabra |
| La ciudad y cruzar calles | Paseo con Abu |
| Amistad | Nico |
| Autobús | Autobús escolar |
| Actividades (motor de minijuegos) | Clase de mates |
| Dinero y comprar | Paga y heladería |
| Teléfono, mapa, álbum, tareas | Regalo de Abu |
| Metas largas | El sueño |

## 4.5 Qué pasa en la segunda sesión (minutos 30–60)

Para que la segunda sesión también enganche, está preparada:

- **Carrera de bicis con Nico** (se quitan los ruedines: logro "Sin ruedines").
- **Excursión del colegio** relacionada con el sueño elegido (parque de bomberos, hospital, comisaría, cocina de la
  Cafetería Central, Estadio Altamar, Facultad de Ingeniería, estudio de Media Sur, Cooperativa de Villaverde, Torre Altamar).
- Primera **tarea de casa** pagada (pasear al perro, poner la mesa) → la paga depende de las tareas.
- Primer día redondo (3 tareas del día).
- A partir de aquí la infancia continúa con el contenido del [documento 05](05-misiones-eventos.md).

## 4.6 Medir si funciona

Eventos de analítica (sistema S29) en cada paso para ver **dónde se van los jugadores** y arreglarlo:

| Evento | Paso |
|---|---|
| `ftue_create_done` | Terminó de crear el personaje |
| `ftue_birth_done` | Vio (o saltó) el nacimiento |
| `ftue_bday1` / `ftue_bday2` / `ftue_bday3` | Cada cumpleaños |
| `ftue_friend` | Saludó a Nico o a un jugador |
| `ftue_school_class` | Terminó la primera clase |
| `ftue_first_purchase` | Primera compra |
| `ftue_dream` | Eligió sueño |
| `ftue_complete` | Llegó al resumen |
| `d1_return` | Volvió al día siguiente |

**Objetivo inicial:** que al menos el 70% de los que crean personaje lleguen a `ftue_school_class` y el 50% a `ftue_complete`.
Si un paso pierde mucha gente, se acorta o se hace más divertido.
