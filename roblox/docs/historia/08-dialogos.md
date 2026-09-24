# 08 — Diálogos de ejemplo

## Cómo leer este documento

- Cada línea tiene una **clave** (`DLG.<NPC>.<ESCENA>.<NN>`) que será su identificador en la tabla de traducción.
  El código nunca escribe frases: pide la clave ([Fase 13.1](../diseno/13-interfaz.md), decisión D1).
- `>` en la columna *Quién* marca una **respuesta que elige el jugador**.
- Las palabras entre llaves son **variables**: `{nombre}` (nombre del jugador), `{mascota}`, `{sueno}` (su sueño de infancia),
  `{profesion}`, `{zona}`, `{dinero}`, `{abu}` (Abu Rosa o Abu Tomás), `{familiar}` (mamá, papá o el rol elegido).
- Se evitan los adjetivos con género referidos al jugador (ver [09 — Textos y traducción](09-textos-traduccion.md)).
- Máximo **2 líneas por globo** en pantalla. Si una frase es más larga, se parte en dos claves.
- La tabla lista para Roblox se genera a partir de este archivo: [`textos/dialogos.csv`](textos/dialogos.csv).

---

## 1. Abu (Rosa o Tomás) — el tutorial

### 1.1 Nacimiento y bebé

| Clave | Quién | Texto |
|---|---|---|
| DLG.ABU.NACER.01 | Abu | Te damos la bienvenida al mundo, {nombre}. Valmar te estaba esperando. |
| DLG.ABU.NACER.02 | Abu | Mira qué manitas tan pequeñas… ¡y qué ganas de explorar! |
| DLG.ABU.BEBE.01 | Abu | ¿Oyes eso? ¡Es tu sonajero! Gatea hasta él. |
| DLG.ABU.BEBE.02 | Abu | Si arrastras la pantalla, puedes mirar a tu alrededor. |
| DLG.ABU.BEBE.03 | Abu | ¡Toca el piano! Mantén pulsado para usar las cosas. |
| DLG.ABU.BEBE.04 | Abu | Uy, esa barriguita… Llama a tu familia y te darán el biberón. |
| DLG.ABU.BEBE.05 | Abu | Ese circulito es tu hambre. Cuando baje, ¡a comer! |
| DLG.ABU.BEBE.06 | Abu | ¡{mascota} quiere jugar! Sigue la línea azul. |
| DLG.ABU.BEBE.07 | Abu | ¿Dónde se habrá escondido el patito? Busca por la casa. |
| DLG.ABU.BEBE.08 | Abu | Qué bostezo más grande… A la cuna, que se hace de noche. |
| DLG.ABU.PISTA.01 | Abu | ¿Te ayudo? Mira hacia donde brilla. |
| DLG.ABU.PISTA.02 | Abu | Sigue la flecha, tesoro. Sin prisa. |

### 1.2 Primer cumpleaños y primera palabra

| Clave | Quién | Texto |
|---|---|---|
| DLG.ABU.CUMPLE1.01 | Abu | ¿Un año ya? ¡Si ayer cabías en una mano! |
| DLG.ABU.CUMPLE1.02 | Abu | Sopla la vela. ¡Fuerte! |
| DLG.ABU.CUMPLE1.03 | Abu | Tenemos tres regalos. Elige el que más te guste. |
| DLG.ABU.PASOS.01 | Abu | Agárrate al sofá… ¡eso es! Ahora, ven con Abu. |
| DLG.ABU.PASOS.02 | Abu | ¡Cinco pasos! ¡Esto hay que celebrarlo con una foto! |
| DLG.ABU.PALABRA.01 | Abu | ¿Vas a decir algo? Todos te escuchamos… |
| DLG.ABU.PALABRA.R1 | > Jugador | ¡Abu! |
| DLG.ABU.PALABRA.R2 | > Jugador | ¡{familiar}! |
| DLG.ABU.PALABRA.R3 | > Jugador | ¡Agua! |
| DLG.ABU.PALABRA.R4 | > Jugador | ¡{mascota}! |
| DLG.ABU.PALABRA.02 | Abu | ¡Lo ha dicho! ¡Lo ha dicho! Esta la guardo en el álbum. |

### 1.3 Primera salida

| Clave | Quién | Texto |
|---|---|---|
| DLG.ABU.SALIDA.01 | Abu | ¡Ya eres mayor para salir de paseo! ¿Vamos al parque? |
| DLG.ABU.SALIDA.02 | Abu | Por la acera, siempre de mi mano. |
| DLG.ABU.SALIDA.03 | Abu | Paso de cebra y muñequito verde: ahora sí podemos cruzar. |
| DLG.ABU.SALIDA.04 | Abu | ¿Ves a ese peque del arenero? Se llama Nico. ¡Salúdale! |
| DLG.ABU.SALIDA.05 | Abu | Dos helados, por favor. Mira: se paga aquí, con la tarjeta. |
| DLG.ABU.SALIDA.06 | Abu | Hoy has hecho tu primer amigo. Qué día más bonito. |

### 1.4 Tercer cumpleaños, colegio, paga y sueño

| Clave | Quién | Texto |
|---|---|---|
| DLG.ABU.CUMPLE3.01 | Abu | ¡Tres años! Ya no eres un bebé… ¡ahora empieza lo bueno! |
| DLG.ABU.CUMPLE3.02 | Abu | Este regalo tiene dos ruedas… y dos ruedines, por si acaso. |
| DLG.ABU.COLE.01 | Abu | Mochila lista. ¿Llevas el estuche? ¿Y el almuerzo? |
| DLG.ABU.COLE.02 | Abu | El autobús para aquí. Cuando llegue, sube y busca asiento. |
| DLG.ABU.COLE.03 | Abu | Pásalo muy bien. A la salida te espera tu paga. |
| DLG.ABU.PAGA.01 | {familiar} | Por haber sido tan valiente en tu primer día: ¡tu primera paga! |
| DLG.ABU.PAGA.02 | Abu | Diez dólares de Valmar. Úsalos bien… o, por lo menos, disfrútalos. |
| DLG.ABU.MOVIL.01 | Abu | Toma: tu primer teléfono. Para que me llames cuando quieras. |
| DLG.ABU.MOVIL.02 | Abu | Aquí tienes el mapa, tus fotos y tus tareas. ¡Nada de perderse! |
| DLG.ABU.SUENO.01 | Abu | Oye, {nombre}… ¿y tú qué quieres ser de mayor? |
| DLG.ABU.SUENO.R1 | > Jugador | ¡Bombero! ¡Apagar fuegos! |
| DLG.ABU.SUENO.R2 | > Jugador | ¡Médico! ¡Curar a la gente! |
| DLG.ABU.SUENO.R3 | > Jugador | ¡Cocinero! ¡Hacer comida rica! |
| DLG.ABU.SUENO.R4 | > Jugador | ¡Futbolista! ¡Marcar en el estadio! |
| DLG.ABU.SUENO.R5 | > Jugador | ¡Inventor! ¡Hacer robots! |
| DLG.ABU.SUENO.R6 | > Jugador | ¡Aún no lo sé! |
| DLG.ABU.SUENO.02 | Abu | {sueno}… Me parece un sueño precioso. Y los sueños se construyen poco a poco. |
| DLG.ABU.SUENO.03 | Abu | ¿No lo sabes todavía? ¡Mejor! Así puedes probarlo todo. |
| DLG.ABU.FIN.01 | Abu | Mañana hay carrera de bicis con Nico. ¡Descansa, campeón del día! |

> Las respuestas del sueño se muestran con la forma que elija el jugador para su personaje (bombero/bombera, médico/médica…).
> Aquí solo se lista una forma por brevedad; la tabla CSV incluye ambas (sufijos `_F` y `_M`, ver [09](09-textos-traduccion.md)).
> En `DLG.ABU.FIN.01`, "campeón del día" es un apodo cariñoso fijo de Abu; en la versión femenina se usa `DLG.ABU.FIN.01_F`.

### 1.5 Abu durante el resto de la vida (saludos según la memoria)

| Clave | Cuándo | Texto |
|---|---|---|
| DLG.ABU.MEM.SUENO | Niño, visita | ¿Sigues queriendo ser {sueno}? ¡Yo ya te veo! |
| DLG.ABU.MEM.PRIMER_TRABAJO | Primer sueldo | ¡Tu primer sueldo! ¿Me invitas a un café en la Cafetería Central? |
| DLG.ABU.MEM.INDEPENDIENTE | Tras mudarse | Esta casa está muy silenciosa sin ti. Ven a comer el domingo, ¿vale? |
| DLG.ABU.MEM.SUENO_CUMPLIDO | Sueño cumplido | {profesion}. Lo sabía desde que tenías tres años. |

---

## 2. Don Ernesto — Cafetería Central

### 2.1 Primer turno de barista

| Clave | Quién | Texto |
|---|---|---|
| DLG.ERNESTO.TURNO1.01 | Don Ernesto | ¿Tú eres la criatura nueva? Llegas justo. La hora punta no espera. |
| DLG.ERNESTO.TURNO1.02 | Don Ernesto | Regla número uno: la leche no se quema. Nunca. |
| DLG.ERNESTO.TURNO1.03 | Don Ernesto | Para la aguja en la zona verde. Ni antes ni después. |
| DLG.ERNESTO.TURNO1.04 | Don Ernesto | ¿Ves el color del ticket? Cada café, a su dueño. |
| DLG.ERNESTO.TURNO1.05 | Don Ernesto | Hmm. No está mal. No está bien. Pero no está mal. |
| DLG.ERNESTO.TURNO1.06 | Don Ernesto | ¡Ese café tiene alma! Así se hace, criatura. |
| DLG.ERNESTO.TURNO1.07 | Don Ernesto | Mañana vuelves. Y trae ganas, que café ya tengo yo. |
| DLG.ERNESTO.CANELA.01 | Don Ernesto | ¡Canela! ¡Fuera de la barra, que ahí no se duerme! |
| DLG.ERNESTO.FALLO.01 | Don Ernesto | Tranquilidad. Un café mal hecho se tira y se hace otro. Un cliente enfadado cuesta más. |

### 2.2 Afinidad: historias de la ciudad

| Clave | Afinidad | Texto |
|---|---|---|
| DLG.ERNESTO.HIST.01 | 1 | Esta cafetería la abrió mi abuelo cuando la plaza era de tierra. Aquí se firmaban tratos con un apretón de manos. |
| DLG.ERNESTO.HIST.02 | 2 | Por esa ventana vi pasar el último tren de la conservera. Iba lleno de gente diciendo adiós. |
| DLG.ERNESTO.HIST.03 | 3 | La alcaldesa venía aquí a estudiar cuando era estudiante. Siempre pedía chocolate. Que no se entere nadie. |
| DLG.ERNESTO.HIST.04 | 4 | ¿Sabes qué me preocupa? Que cuando yo me retire, esto se convierta en otra tienda de móviles. |
| DLG.ERNESTO.HIST.05 | 5 | Llevo tiempo mirándote. Tienes buena mano y mejor corazón. ¿Te atreverías a llevar esto tú? |

---

## 3. Paco Almansa — Mercado de San Roque

| Clave | Quién | Texto |
|---|---|---|
| DLG.PACO.PREGON.01 | Paco | ¡Mira qué tomates, mira qué tomates! ¡Rojos como el atardecer de Playa Dorada! |
| DLG.PACO.PREGON.02 | Paco | ¡Naranjas de Villaverde, dulces como la abuela! |
| DLG.PACO.SALUDO.01 | Paco | ¡Anda, mira quién está aquí! ¿Qué se cuenta el barrio? |
| DLG.PACO.PISO.01 | Paco | ¿Buscas piso? Aquí en San Roque son pequeños, pero con alma. Y baratos, que es lo importante. |
| DLG.PACO.PISO.02 | Paco | Te enseño tres. Uno aquí, uno en el Campus y uno en el Centro. Tú decides. |
| DLG.PACO.PISO.R1 | > Jugador | Quiero lo más barato posible. |
| DLG.PACO.PISO.R2 | > Jugador | Prefiero estar cerca del trabajo. |
| DLG.PACO.PISO.R3 | > Jugador | Quiero algo bonito, aunque cueste más. |
| DLG.PACO.PISO.03 | Paco | Barato, ¿eh? Entonces la habitación de la calle Conservera. Tiene vistas… al mural. |
| DLG.PACO.PISO.04 | Paco | Cerca del curro, bien pensado. Lo que ahorras en autobús lo gastas en churros. |
| DLG.PACO.PISO.05 | Paco | ¿Bonito? El estudio del Centro tiene un balcón que parece de película. Pero vas a tener que trabajar, ¿eh? |
| DLG.PACO.CHISME.01 | Paco | Dicen que el viejo Bernardo vuelve a mirar el faro cada noche. Algo trama ese hombre… |
| DLG.PACO.CHISME.02 | Paco | Me han contado que en el túnel viejo, junto a las vías, hay algo escondido. Yo no he dicho nada. |
| DLG.PACO.CONSEJO.01 | Paco | Consejo de Paco: la fruta del domingo, a última hora, está a mitad de precio. |

---

## 4. Lucía Ortega — Colegio de Los Pinos

| Clave | Quién | Texto |
|---|---|---|
| DLG.LUCIA.COLE1.01 | Lucía | ¡Hola, {nombre}! Soy Lucía, tu maestra. Hoy vamos a aprender jugando. |
| DLG.LUCIA.COLE1.02 | Lucía | Tenemos manzanas y tenemos cestas. ¿Cuántas manzanas hay en total? |
| DLG.LUCIA.COLE1.03 | Lucía | ¡Muy bien! ¿Ves? Las matemáticas también se pueden comer. |
| DLG.LUCIA.COLE1.04 | Lucía | ¿Te has equivocado? ¡Genial! Así se aprende. Prueba otra vez. |
| DLG.LUCIA.COLE1.05 | Lucía | ¡Al recreo! Y nada de empujones, que nos conocemos. |
| DLG.LUCIA.EXCURSION.01 | Lucía | Mañana vamos de excursión. Como alguien quiere ser {sueno}, ¡iremos a verlo de cerca! |
| DLG.LUCIA.GRADUA.01 | Lucía | Habéis crecido tanto… Prometedme una cosa: no dejéis nunca de hacer preguntas. |
| DLG.LUCIA.REENCUENTRO.01 | Lucía | ¿{nombre}? ¡No me lo puedo creer! ¿Cumpliste tu sueño? |
| DLG.LUCIA.REENCUENTRO.R1 | > Jugador | Sí. Ahora soy {profesion}. |
| DLG.LUCIA.REENCUENTRO.R2 | > Jugador | Todavía no, pero estoy en ello. |
| DLG.LUCIA.REENCUENTRO.R3 | > Jugador | Encontré otro sueño por el camino. |
| DLG.LUCIA.REENCUENTRO.02 | Lucía | Lo sabía. Desde el primer día con las manzanas, lo sabía. Gracias por venir a contármelo. |
| DLG.LUCIA.REENCUENTRO.03 | Lucía | Los sueños grandes tardan. Sigue, que lo tienes cerca. |
| DLG.LUCIA.REENCUENTRO.04 | Lucía | ¡Eso es lo mejor que me podías decir! Crecer es también cambiar de sueño. |

---

## 5. Ignacio Prieto — Banco Valmar

| Clave | Quién | Texto |
|---|---|---|
| DLG.IGNACIO.CUENTA.01 | Ignacio | Te doy la bienvenida al Banco Valmar. Vamos a abrir tu primera cuenta. ¡Qué emoción! |
| DLG.IGNACIO.CUENTA.02 | Ignacio | Esta es tu tarjeta. Con ella pagas en las tiendas, y el dinero sale de tu cuenta. |
| DLG.IGNACIO.CUENTA.03 | Ignacio | ¿Para qué quieres ahorrar? Ponle nombre a tu meta y te enseño cuánto te falta. |
| DLG.IGNACIO.CUENTA.04 | Ignacio | Ahorrar no es guardar dinero: es comprarle tiempo a tu yo del futuro. |
| DLG.IGNACIO.HIPOTECA.01 | Ignacio | Una hipoteca: pones una parte ahora y el resto cada semana. Si pagas a tiempo, tu historial mejora. |
| DLG.IGNACIO.HIPOTECA.02 | Ignacio | Mi consejo: que la cuota no pase de un tercio de lo que ganas. Así duermes sin preocupaciones. |
| DLG.IGNACIO.ALERTA.01 | Ignacio | Te escribo porque tu cuenta está un poco baja. ¿Revisamos juntos tus gastos? |

---

## 6. Pilar Gómez — Autoescuela

| Clave | Quién | Texto |
|---|---|---|
| DLG.PILAR.CLASE1.01 | Pilar | Buenas. Soy Pilar. Primera regla: yo también tengo freno. Segunda: no me obligues a usarlo. |
| DLG.PILAR.CLASE1.02 | Pilar | Intermitente, espejo, y luego ya si quieres rezas. |
| DLG.PILAR.CLASE1.03 | Pilar | Ese stop no era una sugerencia. |
| DLG.PILAR.CLASE1.04 | Pilar | Mira, eso ha estado bien. No lo repitas mucho que me acostumbro. |
| DLG.PILAR.EXAMEN.01 | Pilar | ¡Aprobado! Te lo digo en serio: conduce como si todos los demás estuvieran despistados. |

---

## 7. Dr. Samuel Bravo — Hospital General

| Clave | Quién | Texto |
|---|---|---|
| DLG.BRAVO.MIR.01 | Dr. Bravo | Respira. El paciente necesita que tú mantengas la calma antes que él. |
| DLG.BRAVO.MIR.02 | Dr. Bravo | Primero escucha. La mitad del diagnóstico te lo cuenta el propio paciente. |
| DLG.BRAVO.MIR.03 | Dr. Bravo | ¿Tres pruebas para un catarro? El tiempo de urgencias también es un paciente. |
| DLG.BRAVO.MIR.04 | Dr. Bravo | Buen diagnóstico. Ahora explícaselo sin palabras raras. |
| DLG.BRAVO.MIR.05 | Dr. Bravo | ¿Y qué harías tú? No me mires a mí. Decide. |
| DLG.BRAVO.AUXILIOS.01 | Dr. Bravo | Si ves a alguien mareado: lo tumbas de lado, llamas al 112 y te quedas a su lado. Con eso ya ayudas muchísimo. |
| DLG.BRAVO.FIN.01 | Dr. Bravo | Buen turno. Vete a casa, duerme y come algo que no sea de la máquina. |

---

## 8. Nuria Castro — Bomberos

| Clave | Quién | Texto |
|---|---|---|
| DLG.NURIA.SIMULACRO.01 | Nuria | ¡Atención, peques! Si suena la alarma: en fila, sin correr y sin volver a por la mochila. |
| DLG.NURIA.SIMULACRO.02 | Nuria | ¡Perfecto! Habéis salido en un minuto y medio. ¡Récord del colegio! |
| DLG.NURIA.AVISO.01 | Nuria | ¡Aviso! Humo en un edificio de {zona}. ¡Todos al camión! |
| DLG.NURIA.FUEGO.01 | Nuria | Apunta a la base de las llamas, no al humo. |
| DLG.NURIA.FUEGO.02 | Nuria | Cámara térmica: busca manchas naranjas. Primero las personas, luego las cosas. |
| DLG.NURIA.FIN.01 | Nuria | Buen trabajo, equipo. Nadie herido, todo apagado. Así me gusta. |
| DLG.NURIA.GATO.01 | Nuria | Otra vez el gato de la señora Pilar. Ese gato tiene más rescates que yo. |

---

## 9. Julián Ríos — Policía

| Clave | Quién | Texto |
|---|---|---|
| DLG.JULIAN.BRIEF.01 | Julián | Buenos días. Hoy patrulla por {zona}. Recordad: a quien madruga… le entra sueño. |
| DLG.JULIAN.BRIEF.02 | Julián | En Valmar la mejor detención es la que no hace falta. Ayudad primero. |
| DLG.JULIAN.VIAL.01 | Julián | Semáforo rojo: paramos. Verde: miramos a los dos lados, y entonces cruzamos. |
| DLG.JULIAN.PERDIDO.01 | Julián | Una señora ha perdido su perro, Tofu. Pequeño, blanco y con un pañuelo azul. |
| DLG.JULIAN.FIN.01 | Julián | Turno tranquilo. Como decía mi abuelo: más vale pájaro en mano… que un turno movido. |

---

## 10. Amaia Soler — Rectora (la decisión de los 18)

| Clave | Quién | Texto |
|---|---|---|
| DLG.AMAIA.DECISION.01 | Amaia | Siéntate, {nombre}. Tienes dieciocho años y un mundo delante. Hablemos. |
| DLG.AMAIA.DECISION.02 | Amaia | No hay un camino correcto. Hay el tuyo. |
| DLG.AMAIA.DECISION.R1 | > Jugador | Quiero ir a la universidad. |
| DLG.AMAIA.DECISION.R2 | > Jugador | Prefiero aprender un oficio en la FP. |
| DLG.AMAIA.DECISION.R3 | > Jugador | Quiero empezar a trabajar ya. |
| DLG.AMAIA.DECISION.R4 | > Jugador | Tengo una idea de negocio. |
| DLG.AMAIA.DECISION.R5 | > Jugador | Necesito tiempo para pensarlo. |
| DLG.AMAIA.DECISION.03 | Amaia | Con tu nota puedes pedir una beca. Mi abuela fundó esta casa para que nadie se quedara fuera por dinero. |
| DLG.AMAIA.DECISION.04 | Amaia | Los oficios sostienen la ciudad. Sin mecánicos, sin cocineros y sin electricistas, Valmar no se enciende por la mañana. |
| DLG.AMAIA.DECISION.05 | Amaia | Trabajar también enseña. Y recuerda: esta puerta estará abierta si algún día quieres volver. |
| DLG.AMAIA.DECISION.06 | Amaia | ¿Una empresa? Ve a ver a Victoria Altamar. Es dura, pero sabe reconocer el talento. |
| DLG.AMAIA.DECISION.07 | Amaia | Pensar no es perder el tiempo. Viaja, prueba trabajos, descubre qué te hace feliz. |
| DLG.AMAIA.CITA.01 | Amaia | Mi abuela decía: "Nadie llega tarde a aprender, solo a rendirse". |
| DLG.AMAIA.GRADUA.01 | Amaia | Hoy salís de aquí con un título. Pero lo que de verdad os lleváis es lo que habéis aprendido a hacer juntos. |

---

## 11. Elvira Castell — El Libro de Valmar

| Clave | Quién | Texto |
|---|---|---|
| DLG.ELVIRA.LIBRO.01 | Elvira | Déjame que te cuente… Este libro tiene todas las vidas de Valmar. Todas caben, y ninguna se parece a otra. |
| DLG.ELVIRA.CAPITULO.01 | Elvira | Así que ha llegado el momento de escribir tu capítulo. Tómate tu tiempo. |
| DLG.ELVIRA.CAPITULO.02 | Elvira | Elige cinco recuerdos. No los más grandes: los que más te importen. |
| DLG.ELVIRA.CAPITULO.03 | Elvira | Y ahora, un nombre para tu historia. ¿Cómo te recordará Valmar? |
| DLG.ELVIRA.CAPITULO.04 | Elvira | Qué vida tan bonita. Gracias por dejarme escribirla. |
| DLG.ELVIRA.LEYENDA.01 | Elvira | ¿Sabías que a la carta de fundación le falta una página? Alguien la usó para algo… muy poco importante. |
| DLG.ELVIRA.HEREDERO.01 | Elvira | Tú debes de ser de la familia {apellido}. Tu antepasado tiene aquí un capítulo precioso. ¿Quieres leerlo? |

---

## 12. Kai Moreno — Playa Dorada

| Clave | Quién | Texto |
|---|---|---|
| DLG.KAI.SALUDO.01 | Kai | ¡Eh, qué pasa! ¿Vienes a por olas o a por helado? |
| DLG.KAI.NADAR.01 | Kai | Tranqui. Primero flotar, luego nadar, luego surf. El mar no tiene prisa. |
| DLG.KAI.BANDERA.01 | Kai | Bandera amarilla: al agua, pero cerquita. Bandera roja: hoy el mar manda. |
| DLG.KAI.LIMPIEZA.01 | Kai | ¿Me ayudas a limpiar la playa? Cada botella que recogemos es una tortuga más feliz. |
| DLG.KAI.RESCATE.01 | Kai | ¡Alguien pide ayuda en la boya! ¡Coge el flotador, rápido! |

---

## 13. Bernardo — El faro

| Clave | Quién | Texto |
|---|---|---|
| DLG.BERNARDO.SALUDO.01 | Bernardo | ¡Por todos los percebes! Un visitante. Siéntate, que el banco es grande. |
| DLG.BERNARDO.FARO.01 | Bernardo | Cuarenta años encendí esa luz. Cada noche. Y una noche me dijeron que ya no hacía falta. |
| DLG.BERNARDO.FARO.02 | Bernardo | Un faro no mueve los barcos, criatura. Solo les dice dónde está la casa. |
| DLG.BERNARDO.FARO.03 | Bernardo | Si toda la ciudad arrimara el hombro… yo creo que volvería a brillar. |
| DLG.BERNARDO.FARO.04 | Bernardo | Dicen que cuando el faro se encienda volverán las ballenas. Yo no lo digo. Pero lo pienso. |
| DLG.BERNARDO.ENCENDIDO.01 | Bernardo | Mira… ¡Mira! Está encendido. Gracias. A ti y a todos. |
| DLG.BERNARDO.RELIQUIA.01 | Bernardo | Toma mi silbato. Me acompañó cuarenta años. Ahora te toca a ti cuidar de alguien. |

---

## 14. Maribel Ruiz — Cooperativa de Villaverde

| Clave | Quién | Texto |
|---|---|---|
| DLG.MARIBEL.SALUDO.01 | Maribel | Qué alegría verte por el valle. Aquí se madruga, pero se vive a gusto. |
| DLG.MARIBEL.SIEMBRA.01 | Maribel | Cada cosa a su tiempo: tomates en verano, calabazas en otoño. La tierra no tiene prisa. |
| DLG.MARIBEL.RIEGO.01 | Maribel | Riega, pero no ahogues. A las plantas les pasa como a las personas. |
| DLG.MARIBEL.TORMENTA.01 | Maribel | ¡Viene tormenta! Tapa los cultivos, que el granizo no perdona. |
| DLG.MARIBEL.OLIVO.01 | Maribel | Esta semilla viene del primer olivo del valle. Doscientos años esperando a alguien paciente. |

---

## 15. Victoria Altamar — Grupo Altamar

| Clave | Quién | Texto |
|---|---|---|
| DLG.VICTORIA.CITA.01 | Victoria | Tienes cinco minutos. Convénceme. |
| DLG.VICTORIA.CITA.02 | Victoria | Todos tienen ideas. Yo busco a quien las termina. |
| DLG.VICTORIA.PLAN.R1 | > Jugador | Una cafetería con productos de Villaverde. |
| DLG.VICTORIA.PLAN.R2 | > Jugador | Una tienda de bicis en el Campus. |
| DLG.VICTORIA.PLAN.R3 | > Jugador | Un estudio de videojuegos. |
| DLG.VICTORIA.PLAN.01 | Victoria | Mmm. Pequeño, pero con los números claros. Me gusta más que muchas ideas grandes. |
| DLG.VICTORIA.PLAN.02 | Victoria | Te ayudo con el primer local. Si en un mes sigue abierto, hablamos de algo más grande. |
| DLG.VICTORIA.EXITO.01 | Victoria | Tu negocio ha salido en Radio Valmar. Bien jugado, emprendedor. Ahora no te relajes. |

> `DLG.VICTORIA.EXITO.01` tiene versión `_F` ("emprendedora").

---

## 16. Leo Sanz — Radio Valmar

| Clave | Cuándo | Texto |
|---|---|---|
| DLG.RADIO.MANANA.01 | Por la mañana | ¡Buenos días, Valmar! Hoy hace sol, el café está caliente y tenemos noticias frescas. |
| DLG.RADIO.LLUVIA.01 | Lluvia | ¡Buenos días, Valmar! Coged el paraguas, que hoy llueve más que en un lavado de coche. |
| DLG.RADIO.PARTIDO.01 | Día de partido | ¡Hoy hay partido en el {estadio}! Los autobuses especiales salen desde el Centro. |
| DLG.RADIO.INCENDIO.01 | Emergencia resuelta | Última hora: los bomberos de {zona} han apagado un incendio en tiempo récord. ¡Sin heridos! |
| DLG.RADIO.GRADUA.01 | Logro de jugador | Enhorabuena a {nombre}, que hoy se gradúa en {titulo}. ¡Valmar tiene talento! |
| DLG.RADIO.NEGOCIO.01 | Apertura | Nuevo en {zona}: abre sus puertas {negocio}. ¡Pasad a saludar! |
| DLG.RADIO.PROYECTO.01 | Proyecto de ciudad | El proyecto {proyecto} va por el {porcentaje} por ciento. ¡Entre todos lo conseguimos! |
| DLG.RADIO.NOCHE.01 | Por la noche | Buenas noches, Valmar. Mañana más, y mejor. |

---

## 17. Inés Valcárcel — La alcaldesa

| Clave | Quién | Texto |
|---|---|---|
| DLG.INES.PROYECTO.01 | Inés | ¡Vecinos y vecinas! Valmar cumple doscientos años, y quiero que lo celebremos creciendo. |
| DLG.INES.PROYECTO.02 | Inés | El primer proyecto: volver a encender el Faro de la Punta. Cada turno, cada clase, cada ayuda cuenta. |
| DLG.INES.PROYECTO.03 | Inés | ¡Lo hemos conseguido! Hoy Valmar es un poco mejor que ayer… y mañana lo será todavía más. |
| DLG.INES.LLAVES.01 | Inés | Por su trabajo por esta ciudad, entrego las Llaves de Valmar a… ¡{nombre}! |
| DLG.INES.SALUDO.01 | Inés | ¡Anda! Si es {nombre}. Cuando necesito a alguien de confianza, siempre pienso en ti. |

---

## 18. Míster Olmedo e Irene Vidal — Fútbol

| Clave | Quién | Texto |
|---|---|---|
| DLG.OLMEDO.CANTERA.01 | Olmedo | El talento gana partidos. El equipo gana ligas. ¿Tú qué quieres ganar? |
| DLG.OLMEDO.ENTRENO.01 | Olmedo | ¡Esa pierna izquierda! No es de adorno. |
| DLG.OLMEDO.DERBI.01 | Olmedo | Partido a partido… pero este partido es EL partido. |
| DLG.IRENE.CANTERA.01 | Irene | Los Búhos no corren más. Piensan antes. |
| DLG.IRENE.DERBI.01 | Irene | Olmedo trae su bufanda de la suerte. Nosotros traemos un plan. |

---

## 19. Tu generación: Nico, Sara y Omar

| Clave | Quién | Texto |
|---|---|---|
| DLG.NICO.PARQUE.01 | Nico | ¡Hola! ¿Hacemos un castillo? El mío siempre se cae, pero mola igual. |
| DLG.NICO.BICI.01 | Nico | ¡Te echo una carrera hasta el pino gigante! ¡El último es un huevo pasado! |
| DLG.NICO.SUENO.01 | Nico | Yo de mayor seré bombero. Como la jefa Nuria. ¡Nino, nino! |
| DLG.SARA.COLE.01 | Sara | Hola. Soy Sara. He contado las manzanas antes que tú. Pero bien hecho. |
| DLG.SARA.CIENCIA.01 | Sara | Si hacemos juntos el volcán, ganamos seguro. Tú pones la pintura, yo la química. |
| DLG.OMAR.COCINA.01 | Omar | ¿Tienes hambre? Te enseño mi tostada secreta. El secreto es… ¡más tomate! |
| DLG.OMAR.ADULTO.01 | Omar | ¡Mira! Mi food truck. Si algún día necesitas trabajo, aquí siempre hay sitio para ti. |

---

## 20. Frases de ambiente (NPC anónimos)

Frases cortas que dicen los peatones y clientes al pasar cerca. Se eligen según la hora, el clima y la zona.

| Clave | Situación | Texto |
|---|---|---|
| DLG.AMB.MANANA.01 | Mañana | ¡Llego tarde, llego tarde! |
| DLG.AMB.MANANA.02 | Mañana | Un café primero, luego el mundo. |
| DLG.AMB.LLUVIA.01 | Lluvia | ¡Y yo sin paraguas! |
| DLG.AMB.PLAYA.01 | Playa Dorada | ¿Nos damos un chapuzón? |
| DLG.AMB.PARTIDO.01 | Día de partido | ¡Hoy ganamos, lo presiento! |
| DLG.AMB.MERCADO.01 | San Roque | ¿Has visto qué precio tienen hoy las fresas? |
| DLG.AMB.VALLE.01 | Villaverde | Huele a tierra mojada. Qué gusto. |
| DLG.AMB.CAMPUS.01 | Campus Valmar | ¡Mañana tengo examen y no he abierto el libro! |
| DLG.AMB.FINANCIERO.01 | Distrito Financiero | La reunión se ha alargado otra vez… |
| DLG.AMB.FARO.01 | Tras encender el faro | ¿Has visto el faro? ¡Qué bonito está de noche! |
