# 05 — Misiones y eventos

## 5.1 Tipos de misión

| Tipo | Qué es | Cuántas a la vez | Ejemplo |
|---|---|---|---|
| **Capítulo de vida** | La "historia principal" de cada etapa. Cadena de 4–8 misiones que acompaña al jugador y termina en un hito | 1 | "El instituto", "Independizarse" |
| **Misión de barrio** | Encargos de NPC con nombre. Suben la afinidad y cuentan su historia | Hasta 3 | "El gato de Don Ernesto", "La red de Bernardo" |
| **Misión de carrera** | Retos de la profesión que desbloquean ascensos, uniformes y títulos | 1 por profesión | "Tu primera cirugía" |
| **Tareas diarias y metas semanales** | Ver [Bucle 3.3 y 3.4](03-bucle-de-juego.md) | 3 + 5 | "Haz un turno al 80%" |
| **Evento de ciudad** | Festival, partido, emergencia, proyecto. Aparecen solos | Los que haya | "Incendio en San Roque" |
| **Leyenda** | Misiones secretas que se descubren explorando o por pistas de NPC | Sin límite | "El reloj que se paró" |

### Formato de una misión (datos)

Coherente con el principio "todo el contenido son datos" ([Fase 1](../diseno/01-arquitectura.md)):

```lua
Quests.Nino_Bici = {
	Type = "Capitulo",                 -- Capitulo | Barrio | Carrera | Evento | Leyenda
	Chapter = "Infancia",
	Stage = { Min = "Nino", Max = "Nino" },
	Giver = "Npc_Nico",                -- quién la da (o nil si sale sola)
	TitleKey = "QUEST.NINO_BICI.TITLE",  -- los textos son claves, nunca frases en el código
	Steps = {
		{ Kind = "Talk",     Target = "Npc_Nico",  TextKey = "QUEST.NINO_BICI.S1" },
		{ Kind = "Activity", Activity = "Ruta_Bici", MinScore = 50, TextKey = "QUEST.NINO_BICI.S2" },
		{ Kind = "Reach",    Place = "LosPinos_Parque", TextKey = "QUEST.NINO_BICI.S3" },
	},
	Rewards = { Money = 20, SkillXP = { Deporte = 150 }, Memory = "Recuerdo_SinRuedines", Achievement = "SinRuedines" },
	Next = "Nino_Excursion",
}
```

Los pasos usan un número pequeño de tipos (`Talk`, `Reach`, `Activity`, `Buy`, `Use`, `Collect`, `Wait`, `Choice`),
así que añadir misiones es escribir datos y textos.

## 5.2 Misiones por etapa de vida

### 👶 Bebé (0–3) — Capítulo "La casa es un mundo"

Descrito minuto a minuto en [04 — Primeros 30 minutos](04-primeros-30-minutos.md). Resumen:
explorar la casa → primeros pasos → primera palabra → primera salida → primer amigo → 3.er cumpleaños.

Extras de bebé (si hay familia de jugadores, dan misiones a los padres también):
- **"Mi primer baño de mar"** (Familia de la Cala) · **"Los patitos del estanque"** (Los Pinos) ·
  **"Dar de comer a las gallinas"** (Villaverde) · **"El pregón de Paco"** (San Roque: el bebé aplaude y Paco le regala una fruta).

### 🧒 Niño (4–12) — Capítulo "Grandes aventuras pequeñas"

| # | Misión | Qué se hace | Hito / recompensa |
|---|---|---|---|
| 1 | **Sin ruedines** | Carrera de bicis con Nico por el parque | Logro "Sin ruedines", la bici pasa a normal |
| 2 | **La excursión de mi sueño** | Visita guiada al lugar de la profesión soñada (el NPC de esa profesión deja probar una versión infantil del trabajo: manguera de agua en el patio, fonendo en un peluche, cocinar un bocadillo) | Recuerdo y pista de lo que hay que estudiar |
| 3 | **Educación vial** | Con el comisario Ríos: circuito de bici con semáforos y pasos de cebra | Carnet de bici (de broma), casco nuevo |
| 4 | **El simulacro** | Simulacro de incendio en el colegio con la jefa Nuria Castro: salir en orden, encontrar a los compañeros | Logro "Sé qué hacer" |
| 5 | **La Casa del Árbol** | Construir con otros niños una tabla nueva para la Casa del Árbol de Valmar Norte y escribir el nombre | Tu nombre queda en la Casa del Árbol |
| 6 | **Feria de Ciencias** | Proyecto con Sara (volcán, circuito, planta) → presentarlo | Concurso (ganan todos los que completan; el mejor, trofeo) |
| 7 | **Primer partido** | Escuela de fútbol del Míster Olmedo: entrenamiento y partidillo | Camiseta de la escuela |
| 8 | **Cocinar con Omar** | Receta sencilla en casa de Omar (tostadas, macedonia) | Habilidad Cocina +1 |
| 9 | **Graduación de primaria** | Fin de curso con discurso de Lucía y foto de clase | Cambio a adolescente en el siguiente cumpleaños |

**Misiones de barrio de niño:** *"El gato Canela se ha escapado"* (Don Ernesto), *"Recoger conchas para Bernardo"*,
*"Ayuda a Paco a montar el puesto"*, *"El perro perdido"* (comisario Ríos: objetos y animales perdidos),
*"La colección de cromos de Valmar"* (colección fija de 60 cromos, se compran por número).

**Paga semanal:** $10–30 según las tareas de casa hechas. El niño aprende a ahorrar para algo concreto
(misión *"La bici de mis sueños"*: ahorrar $150 → bici mejor).

### 🧑 Adolescente (13–17) — Capítulo "Quién quiero ser"

| # | Misión | Qué se hace | Hito / recompensa |
|---|---|---|---|
| 1 | **Nuevo instituto** | Primer día en el instituto de Campus Valmar, horario, taquilla | Móvil completo (más apps) |
| 2 | **Mi primera cuenta** | Con Ignacio Prieto en el Banco Valmar: abrir cuenta joven, tarjeta, meta de ahorro | App Banco |
| 3 | **Primer trabajo** | Trabajo de medio tiempo: repartidor en bici, dependiente, camarero de terraza (ver [06](06-profesiones-jugables.md)) | Primer sueldo real |
| 4 | **Pruebas de la cantera** | Opcional: pruebas del Valmar CF o de los Búhos (minijuego de deporte) | Entrar en el equipo juvenil |
| 5 | **Primeros auxilios** | Taller con el Dr. Bravo: posición de seguridad, llamar al 112 | Logro "Salvavidas", útil en emergencias como civil |
| 6 | **La moto (16+)** | Autoescuela con Pilar: carnet A1 | Primer vehículo a motor |
| 7 | **El gran examen** | Exámenes finales (actividad de clase más larga) | Nota media → becas |
| 8 | **Elegir itinerario** | Bachillerato de Ciencias, Letras o Artes, o FP ([Fase 8](../diseno/08-educacion.md)) | Abre caminos |
| 9 | **La decisión** | A los 18: reunión con la rectora Amaia Soler: universidad, FP, trabajar, emprender o año sabático | Pasa a adulto joven |

**Misiones de barrio de adolescente:** *"Limpieza de playa con Kai"*, *"El mural de San Roque"* (bocetos para el proyecto
de ciudad), *"Entrevista para Radio Valmar"* (Leo Sanz busca opiniones jóvenes), *"Cuidar el huerto de Maribel"*.

### 🧑‍🎓 Adulto joven (18–29) — Capítulo "Volar del nido"

| # | Misión | Qué se hace | Hito |
|---|---|---|---|
| 1 | **Buscar piso** | Con Paco: visitar 3 pisos (habitación en San Roque, residencia en Campus, estudio en Centro) y elegir | Primera vivienda propia |
| 2 | **La mudanza** | Llevar cajas (actividad de ruta), colocar los primeros muebles | Logro "Independiente". Los padres NPC se despiden con un regalo |
| 3 | **Mi primera factura** | Pagar la primera semana de alquiler y luz; ver el extracto | Entiende el ciclo de facturas |
| 4 | **Carnet B** | Autoescuela: clases teóricas (quiz) y prácticas (circuito y ciudad) | Carnet de coche |
| 5 | **Primer coche** | Concesionario: probar, comparar, comprar o financiar | Coche |
| 6 | **Graduación / título** | Si estudia: la ceremonia de graduación en el Campus (evento social con otros jugadores) | Título |
| 7 | **Mi primer contrato** | Conseguir un trabajo de su carrera (no de medio tiempo) | Carrera de verdad |
| 8 | **Mi hogar** | Opcional: crear un hogar con amigos (compañeros de piso) o familia ([Fase 12](../diseno/12-multijugador-social.md)) | Hogar |

### 🧑‍💼 Adulto (30–64) — Capítulo "Construir"

| # | Misión | Qué se hace | Hito |
|---|---|---|---|
| 1 | **La casa de verdad** | Hipoteca con Ignacio Prieto, comprar casa, primera reforma | Propietario/a |
| 2 | **Jefe/a** | Llegar al rango 4 de una profesión | Título profesional |
| 3 | **Emprender** | Con Victoria Altamar: plan de negocio, licencia en el ayuntamiento, local, apertura | Negocio abierto |
| 4 | **Familia** | Opcional: hijos (jugadores o NPC), primer día de colegio de tu hijo (tú haces de acompañante, como Abu hizo contigo) | Rol de "Abu" invertido |
| 5 | **Dejar huella** | Aportar 10 h a proyectos de ciudad | Placa en el muro de honor |
| 6 | **Maestro/a** | Tener 3 aprendices (jugadores novatos en tu profesión a los que ayudas en sus turnos) | Logro "Mentor" |
| 7 | **Promesa cumplida** | Volver al colegio y contarle a Lucía Ortega que has cumplido tu sueño (si lo has cumplido) | Logro emotivo |

### 👴 Mayor (65+) — Capítulo "Lo que dejo"

| # | Misión | Qué se hace | Hito |
|---|---|---|---|
| 1 | **Jubilación** | Fiesta de despedida en el trabajo (compañeros jugadores y NPC) | Pensión según la carrera |
| 2 | **El banco del faro** | Visitar a Bernardo: pescar juntos, escuchar sus historias | Bernardo te pasa su silbato de barco (reliquia) |
| 3 | **Cuentacuentos** | Contar leyendas de Valmar a niños (jugadores o NPC) en la biblioteca | Afinidad con Elvira |
| 4 | **Mi jardín** | Cultivar un jardín o huerto (con el olivo de reliquia si se tiene) | — |
| 5 | **Mentor de la ciudad** | Ayudar a jugadores nuevos (sistema de mentores: los mayores reciben avisos de novatos cercanos) | Logro "Sabio/a de Valmar" |
| 6 | **Mi capítulo** | Con Elvira Castell: repasar la vida y elegir los 5 recuerdos que irán en el Libro de Valmar | Prepara el legado ([07](07-progresion-logros-legado.md)) |
| 7 | **Pasar el testigo** | (Cuando el jugador quiera) elegir heredero y celebrar la despedida | Legado y nueva generación |

## 5.3 Misiones por profesión

Cada profesión tiene una **cadena de carrera** de 5 misiones que acompaña los ascensos
(los detalles del turno están en [06](06-profesiones-jugables.md)). Ejemplos:

| Profesión | Misiones de carrera |
|---|---|
| **Barista** | 1. "La leche no se quema" (Don Ernesto) · 2. "La hora punta" (atender 20 clientes sin fallos) · 3. "Latte art" (dibujar un corazón y una hoja) · 4. "La receta secreta" (el café de la casa) · 5. "El sucesor" (gestionar la cafetería un día entero) |
| **Repartidor** | 1. "Primer reparto" · 2. "Lluvia y prisas" (reparto bajo tormenta) · 3. "El paquete frágil" (sin golpes) · 4. "Las 8 zonas en un día" · 5. "Jefe de ruta" (organizar rutas de otros) |
| **Bombero** | 1. "El gato de siempre" (rescate en árbol) · 2. "Fuego en la cocina" · 3. "Tormenta en Villaverde" (árboles caídos) · 4. "El gran incendio" (edificio de varias plantas con otros bomberos) · 5. "Jefe/a de parque" |
| **Médico** | 1. "Prácticas con el Dr. Bravo" · 2. "Urgencias un sábado" (día de partido) · 3. "Diagnóstico difícil" · 4. "Primera cirugía" · 5. "Jefe/a de servicio" |
| **Policía** | 1. "Objetos perdidos" · 2. "Control de velocidad" · 3. "El ladrón de la heladería" (NPC que huye: persecución a pie) · 4. "Seguridad del Derbi" · 5. "Comisario/a" |
| **Cocinero** | 1. "Pinche de Omar" · 2. "El menú del día" · 3. "Producto de Villaverde" (cocinar con lo del agricultor) · 4. "Crítico gastronómico" (NPC exigente) · 5. "Restaurante propio" |
| **Agricultor** | 1. "Primera siembra" con Maribel · 2. "Salvar la cosecha" (tormenta) · 3. "Vender en el mercadillo" · 4. "Contrato con un restaurante" · 5. "La semilla del primer olivo" (reliquia) |
| **Periodista** | 1. "Titular en 5 minutos" · 2. "Entrevista a la alcaldesa" · 3. "Cubrir un incendio" (sin molestar a los bomberos) · 4. "El reportaje del Derbi" · 5. "Director/a de Radio Valmar" |
| **Deportista** | 1. "Pretemporada" · 2. "Debut en liga" · 3. "Gol en el último minuto" · 4. "Capitán/a" · 5. "Ganar el Gran Derbi" |
| **Empresario** | 1. "Plan de negocio" · 2. "Inauguración" (Radio Valmar anuncia la apertura) · 3. "Primer empleado" · 4. "Segunda tienda" · 5. "Toque de campana en la Bolsa de Valmar" |

## 5.4 Eventos de la ciudad

El **Director de eventos** ([Fase 11.6](../diseno/11-npcs-poblacion.md)) lanza los eventos. Aquí se define qué vive el jugador.
Principio: **todo evento tiene un papel para todos**, trabajen o no en ello.

### 🚨 Emergencias

| Emergencia | Qué pasa | Profesionales | Civiles (cualquier jugador) | Si nadie responde |
|---|---|---|---|---|
| **Incendio en un edificio** | Humo por la ventana, alarma, NPC en la calle | Bomberos apagan y rescatan; sanitarios atienden; policía corta la calle | Llamar al 112 desde el teléfono (primera llamada da recompensa), alejar a los NPC curiosos, dar agua a los rescatados | Bomberos NPC llegan en 3–5 min |
| **Accidente de tráfico** (sin heridos graves, sin sangre) | Dos coches abollados, atasco | Policía regula el tráfico; mecánico/grúa retira; sanitarios revisan | Avisar, señalizar con triángulo, dar tu testimonio (mini-diálogo) | Servicios NPC |
| **Paciente en la calle** | NPC mareado en el parque | Ambulancia → urgencias | Si tienes el logro "Salvavidas": posición de seguridad hasta que llegue la ambulancia | Ambulancia NPC |
| **Robo en una tienda NPC** | Alarma, ladrón NPC huye a pie | Policía: persecución y detención (del NPC) | Dar la descripción ("¿Llevaba gorra roja o azul?") | Policía NPC |
| **Tormenta** | Lluvia, rayos, cortes de luz, árboles caídos | Bomberos, electricistas, Energía Costa | Ayudar a recoger ramas, llevar linternas a vecinos NPC | Se resuelve solo al acabar la tormenta |
| **Rescate en el mar** | Bañista NPC arrastrado por la corriente | Socorristas (moto de agua, flotador) | Avisar a la torre de socorrismo | Socorrista NPC |
| **Apagón de barrio** | Una zona sin luz de noche | Electricistas, técnicos de Energía Costa | Repartir velas en el mercado (solo luz, sin fuego peligroso: son de LED) | Vuelve la luz en 5 min |
| **Mascota perdida** | Cartel en una farola | Policía (objetos perdidos) | Encontrarla siguiendo pistas | El dueño la encuentra |

Reglas: sin sangre, sin armas, sin muertes. Los incendios **nunca** destruyen para siempre la casa de un jugador
(solo "hay que reparar", cubierto por el seguro, [A1.2](../diseno/A1-negocios-servicios-mundo.md)).
Cada emergencia resuelta sale en Radio Valmar y suma al proyecto de ciudad activo.

### ⚽ Partidos en los estadios

Valmar tiene **dos estadios**: el **Estadio Altamar** (Distrito Financiero, casa del **Valmar CF**, "los Marineros",
colores azul y blanco) y el **Estadio Universitario** (Campus Valmar, casa del **Deportivo Universitario**,
"los Búhos", colores verde y dorado). Juegan una pequeña **Liga de la Costa** contra equipos NPC de fuera
(Puerto Alto, Real Sierra, Unión Costera…) y dos veces por temporada se enfrentan en el **Derbi de Valmar**.

**Cada sábado de juego hay partido** (alternando estadio). Estructura (~12 minutos reales):

| Fase | Duración | Qué pasa |
|---|---|---|
| **Previa** | 3 min | La calle se llena de NPC con bufandas. Puestos de comida, tienda del club. Radio Valmar hace la previa |
| **Primera parte** | 3 min | El partido se juega (simulado con NPC o con jugadores deportistas). En la grada: minijuegos de afición |
| **Descanso** | 1 min | **Reto del descanso**: tanda de penaltis de un aficionado (jugador) al portero mascota. Depende de tu puntería, no del azar. Premio fijo: bufanda firmada |
| **Segunda parte** | 3 min | Más minijuegos, el momento de "la ola" |
| **Final** | 2 min | Celebración o consuelo, entrevista de Leo Sanz al mejor jugador (NPC o jugador), salida ordenada |

**Papeles para todos:**

| Quién | Qué hace |
|---|---|
| **Aficionado** | Comprar entrada ($), animar: **coreografía de grada** (pulsar al ritmo), **la ola** (coordinarse con los de al lado), cantar el himno. Cuanto mejor anima la grada, más "empuje" recibe el equipo (pequeño bonus al equipo simulado) |
| **Deportista** | Jugar el partido (módulo Deporte, [Fase 7](../diseno/07-profesiones.md)): posiciones sencillas, pases, tiros |
| **Camarero / dependiente** | Puestos de comida y tienda del club: muchos clientes, propinas altas |
| **Policía** | Controlar la entrada, dirigir el tráfico a la salida |
| **Sanitario** | Puesto médico: aficionados con calor o una torcedura |
| **Periodista / fotógrafo** | Crónica y fotos. La mejor foto sale en Noticias |
| **Conductor de autobús / taxista** | Líneas especiales de ida y vuelta al estadio |
| **Empresario** | Patrocinar al equipo (cartel en el estadio) |

**Prohibido:** apuestas, quinielas, porras con dinero o cualquier premio por acertar un resultado. El partido se
disfruta; no se apuesta.

### 🎉 Festivales (calendario completo en [Mundo 1.7](01-mundo-trasfondo.md))

Cada festival tiene **4 elementos fijos** para que sea fácil de producir: *un lugar decorado*, *3 actividades*,
*un concurso* y *una recompensa conmemorativa*.

| Festival | Actividades | Concurso | Recompensa |
|---|---|---|---|
| **Carnaval de San Roque** | Desfile, tienda de disfraces, taller de máscaras | Mejor disfraz (votan los jugadores, 1 voto por persona) | Máscara del Carnaval |
| **Semana de la Ciencia** | Talleres de las 4 facultades, planetario, robots | Feria de proyectos | Bata de científico |
| **Fiesta de la Flor** | Plantar en la plaza, mercado de flores, pintar macetas | Mejor jardín | Corona de flores |
| **Día de Valmar** | Desfile por la avenida, discurso de la alcaldesa, fuegos artificiales | Llaves de la Ciudad (a los jugadores con más aportación del año) | Pañuelo con el escudo |
| **Noche de San Juan** | Hogueras vigiladas por bomberos, farolillos al mar, baile | Mejor farolillo | Farolillo de papel |
| **Festival de Verano** | Conciertos, vóley playa, heladería gratis a mediodía | Castillos de arena | Toalla del festival |
| **Fiesta de la Cosecha** | Vendimia, recogida de aceituna, tractor de feria | Mejor producto (agricultores) | Sombrero de paja |
| **Noche de los Faroles** | Ruta de leyendas, disfraces, calabazas en los portales | Mejor portal decorado | Farol de otoño |
| **Maratón de Valmar** | Carrera de 5 zonas (a pie o en silla/andador para mayores, todos pueden) | Tiempos por categoría | Medalla de finalista para todos |
| **Luces de Valmar** | Pista de hielo, mercado de invierno, coro | Mejor casa iluminada | Gorro de invierno |

### 🏗️ Proyectos de ciudad

Ver [Mundo 1.6](01-mundo-trasfondo.md). Cada proyecto tiene tres momentos jugables:

1. **Presentación:** la alcaldesa lo anuncia en la Plaza Mayor (evento en todos los servidores).
2. **Obra:** durante días reales, andamios en el lugar, NPC trabajando, progreso en la app Noticias. Misiones
   especiales para aportar más (por ejemplo, llevar materiales al faro en barca).
3. **Inauguración:** ceremonia, recompensa para todos los que aportaron, noticia, y el lugar queda cambiado para siempre.

### 🌦️ Clima y estaciones

| Clima | Qué cambia en el juego | Misiones que genera |
|---|---|---|
| Ola de calor (verano) | Más gente en la playa, más helados y agua | Repartir agua a NPC mayores, socorristas ocupados |
| Lluvia | Menos peatones, más taxis, coches con menos agarre | Repartos bajo la lluvia (+propina) |
| Tormenta | Emergencias, cortes de luz | Ver emergencias |
| Niebla (otoño) | El faro importa: si está encendido, los barcos llegan a puerto | Evento del faro |
| Nieve en los montes (invierno) | Paisaje, ropa de invierno | Excursión a la nieve (futuro) |

## 5.5 Leyendas de Valmar (misiones secretas)

No aparecen en la lista de misiones hasta que se descubre la primera pista. Premian explorar y hablar con los NPC.
Completarlas todas da el título **"Cronista de Valmar"**.

| Leyenda | Pista inicial | Qué se descubre |
|---|---|---|
| **El reloj que se paró** | Placa del ayuntamiento | El reloj se paró el día que nació la fundadora de la universidad. Premio: réplica de reloj de bolsillo |
| **La carta de fundación** | Elvira menciona que falta una página | La página está escondida en la Cafetería Central (Don Ernesto la usaba de posavasos sin saberlo) |
| **Las ballenas del faro** | Bernardo | Solo tras el proyecto del faro: noche de niebla, avistamiento de ballenas |
| **El pino de los deseos** | Niños del parque | Contarle tu sueño al pino (hecho en la infancia) y volver de mayor |
| **La semilla del primer olivo** | Maribel | Cadena de agricultura; reliquia heredable |
| **El jardín de la azotea** | Rumor de oficinistas | Invitación de Victoria Altamar o llegar a directivo |
| **El vagón perdido** | Viejo letrero de la conservera | Un vagón del antiguo tren en un túnel cerca de San Roque. Se convierte en un pequeño museo |
| **La Casa del Árbol** | Parque del Mirador | Tu tabla con tu nombre; de mayor puedes enseñársela a tus hijos |

## 5.6 Reglas del Director de eventos (ritmo)

| Regla | Valor inicial (ajustable) |
|---|---|
| Emergencia pequeña (mascota, objeto perdido) | Cada ~5 min de juego por servidor |
| Emergencia media (accidente, robo en tienda) | Cada ~15 min |
| Emergencia grande (incendio de edificio, tormenta) | Cada ~45 min, y solo si hay jugadores conectados que puedan responder o disfrutarlo |
| Partido | Cada sábado de juego (el reloj del servidor: ~cada 2 h 48 min reales) |
| Mercadillo | Cada domingo de juego |
| Grandes eventos | Por calendario real (fines de semana) |
| **Máximo simultáneo** | 1 emergencia grande + 2 pequeñas por servidor, para no saturar |
| **Adaptación** | Más emergencias de un tipo si hay muchos jugadores de esa profesión conectados, para que tengan trabajo |
