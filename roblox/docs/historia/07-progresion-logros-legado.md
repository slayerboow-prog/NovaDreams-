# 07 — Progresión, logros y legado

## 7.1 Tres formas de guardar lo que has vivido

| Elemento | Qué es | Dónde se ve | Ejemplo |
|---|---|---|---|
| **Recuerdos** | Momentos de **tu vida** (fotos automáticas). Cuentan tu historia | App **Álbum** | "Primera palabra: ¡Abu!", "Graduación en Medicina" |
| **Logros** | Retos cumplidos, con nombre y medalla. Se comparten con otros jugadores | App **Perfil → Logros** | "Sin ruedines", "Cien cafés perfectos" |
| **Legado** | Lo que queda cuando la vida termina: el capítulo en el Libro de Valmar, la herencia y el linaje | App **Familia** y la Biblioteca | "Capítulo 1 de la familia García" |

Ninguno se puede comprar con Robux ([Fase 14.4](../diseno/14-monetizacion.md)).

## 7.2 Hitos de vida (los Recuerdos)

Cada hito crea una foto en el Álbum con fecha del juego, lugar y quién estaba contigo. Un hito vale **Puntos de Legado** (PL).

| Etapa | Hitos | PL |
|---|---|---|
| **Bebé** | Bienvenida al mundo · Primer juguete · Primeros pasos · Primera palabra · Mejor amigo peludo · Mi primer amigo · Cada cumpleaños | 5 c/u |
| **Niño** | Primer día de colegio · Sin ruedines · Mi sueño · La excursión · Tabla en la Casa del Árbol · Graduación de primaria | 10 c/u |
| **Adolescente** | Primer móvil · Primera cuenta del banco · Primer sueldo · Carnet de moto · Entrar en el equipo · Fin del instituto · La decisión de los 18 | 15 c/u |
| **Adulto joven** | Independizarse · Primera factura · Carnet de coche · Primer coche · Graduación · Primer contrato · Formar un hogar | 20 c/u |
| **Adulto** | Primera casa en propiedad · Ascenso a jefe/a · Abrir un negocio · Hijos (cada uno) · Promesa cumplida · Muro de honor | 30 c/u |
| **Mayor** | Jubilación · Primer nieto · Mentor de la ciudad · Mi capítulo | 30 c/u |
| **Especiales** | Estar en un incendio como bombero y salvar a alguien · Gol en el Derbi · Inaugurar un proyecto de ciudad · Salir en Radio Valmar | 25 c/u |

## 7.3 Logros

### Reglas

- Cada logro tiene **ID**, clave de nombre, clave de descripción, **categoría** y **nivel** (🥉 bronce, 🥈 plata, 🥇 oro, 💎 leyenda).
- Recompensa **fija**: Estrellas de Valmar (moneda cosmética gratuita), a veces un objeto o un título.
- Los logros de **leyenda** son raros y dan títulos visibles.
- Algunos son **secretos** (se ve "???" hasta conseguirlos).
- Dan PL: bronce 5 · plata 15 · oro 40 · leyenda 100.

### Catálogo inicial (≈70)

#### 🌱 Vida

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `VIDA_EMPIEZA` | Una vida empieza | Terminar el tutorial | 🥉 |
| `VIDA_SIN_RUEDINES` | Sin ruedines | Carrera de bici con Nico | 🥉 |
| `VIDA_CUMPLE_10` | Dos cifras | Cumplir 10 años | 🥉 |
| `VIDA_MAYOR_EDAD` | ¡Dieciocho! | Llegar a adulto joven | 🥈 |
| `VIDA_INDEPENDIENTE` | Independiente | Vivir en tu propia vivienda | 🥈 |
| `VIDA_CUARENTA` | Cuarenta y tantos | Cumplir 40 | 🥈 |
| `VIDA_JUBILADO` | Merecido descanso | Jubilarse | 🥇 |
| `VIDA_COMPLETA` | Una vida plena | Llegar a mayor con al menos 40 recuerdos | 💎 |
| `VIDA_PROMESA` | Promesa cumplida | Cumplir tu sueño de infancia y contárselo a Lucía | 💎 |

#### 🎓 Estudios

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `EST_PRIMERA_NOTA` | ¡Sobresaliente! | Primera clase aprobada | 🥉 |
| `EST_CIENCIA` | Pequeño genio | Completar la Feria de Ciencias | 🥉 |
| `EST_BECA` | Becado/a | Conseguir una beca | 🥈 |
| `EST_GRADUADO` | Birrete al aire | Graduarse en la universidad o en FP | 🥇 |
| `EST_DOS_TITULOS` | Estudiante eterno/a | Tener dos títulos | 🥇 |
| `EST_CARNETS` | Todoterreno | Tener los carnets B, A, C y D | 🥇 |
| `EST_BUHO` | El búho de bronce | Frotar el pico del búho antes de 10 exámenes | 🥉 (secreto) |
| `EST_NUNCA_TARDE` | Nunca es tarde | Graduarse siendo adulto (30+) | 🥇 |

#### 💼 Carrera

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `CAR_PRIMER_SUELDO` | Mi primer sueldo | Completar el primer turno | 🥉 |
| `CAR_PERFECTO` | Turno perfecto | Un turno con 100% de rendimiento | 🥈 |
| `CAR_100_TURNOS` | Currante | 100 turnos | 🥈 |
| `CAR_ASCENSO` | ¡Ascenso! | Primer ascenso | 🥉 |
| `CAR_JEFE` | Jefe/a | Rango 4 en una profesión | 🥇 |
| `CAR_CIMA` | En lo más alto | Rango máximo en una profesión | 💎 |
| `CAR_TRES_OFICIOS` | Mil oficios | Rango 2 en tres profesiones | 🥈 |
| `CAR_NOCHE` | Búho nocturno | 20 turnos de noche | 🥉 |
| `CAR_BARISTA_100` | Cien cafés perfectos | 100 cafés perfectos | 🥈 |
| `CAR_LATTE` | Artista del café | Latte art con el escudo de Valmar | 🥈 |
| `CAR_BOMBERO_RESCATE` | Héroe del barrio | Rescatar a 10 NPC en incendios | 🥇 |
| `CAR_GATO` | El gato de siempre | Rescatar 5 gatos de árboles | 🥉 (divertido) |
| `CAR_MEDICO_100` | Cien pacientes | Atender a 100 pacientes | 🥇 |
| `CAR_RECICLA` | Planeta limpio | Separar bien 1.000 residuos | 🥈 |
| `CAR_REPARTO_8` | Vuelta a Valmar | Entregas en las 8 zonas en un turno | 🥈 |
| `CAR_GOL_DERBI` | Gol en el Derbi | Marcar en el Gran Derbi | 💎 |
| `CAR_PORTADA` | Primera plana | Un artículo tuyo, el más leído del día | 🥇 |
| `CAR_MENTOR` | Mentor | Ayudar a 3 aprendices en su primer turno | 🥈 |

#### 🏠 Hogar y patrimonio

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `HOG_PRIMER_MUEBLE` | Mi rinconcito | Comprar el primer mueble | 🥉 |
| `HOG_PROPIETARIO` | Las llaves de casa | Comprar tu primera vivienda | 🥇 |
| `HOG_HIPOTECA_FIN` | ¡Pagada! | Terminar de pagar una hipoteca | 🥇 |
| `HOG_MANSION` | Vida de lujo | Tener una mansión | 💎 |
| `HOG_GRANJA` | Vuelta al campo | Tener una granja en Villaverde | 🥇 |
| `HOG_OCHO_ZONAS` | Casa en cada rincón | Haber vivido en las 8 zonas | 🥇 |
| `HOG_AHORRADOR` | Hormiguita | Tener $10.000 en la cuenta de ahorro | 🥈 |
| `HOG_CASERO` | Casero/a | Alquilar una propiedad a otro jugador | 🥈 |
| `HOG_TOUR` | Casa de revista | Ganar el concurso de casas de un festival | 🥇 |

#### 🏙️ Ciudad

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `CIU_TURISTA` | Turista en casa | Visitar las 8 zonas | 🥉 |
| `CIU_MIRADORES` | Ojo de halcón | Visitar los 8 miradores | 🥈 |
| `CIU_FARO` | Luz en la Punta | Aportar al proyecto del faro | 🥈 |
| `CIU_MURO` | En el muro | Aparecer en un muro de honor | 🥇 |
| `CIU_OCHO_MUROS` | Constructor/a de Valmar | Aparecer en los 8 muros de honor del Bicentenario | 💎 |
| `CIU_LLAVES` | Llaves de la Ciudad | Recibirlas el Día de Valmar | 💎 |
| `CIU_112` | Buen vecino | Llamar al 112 en una emergencia | 🥉 |
| `CIU_SALVAVIDAS` | Salvavidas | Ayudar en una emergencia como civil con primeros auxilios | 🥈 |
| `CIU_FESTIVALES` | De fiesta en fiesta | Participar en 8 festivales distintos | 🥇 |
| `CIU_DERBI` | Afición de hierro | Ir a 10 partidos | 🥈 |
| `CIU_OLA` | ¡La ola! | Iniciar una ola que dé la vuelta al estadio | 🥉 (secreto) |
| `CIU_MARATON` | Finalista | Terminar el Maratón de Valmar | 🥈 |

#### 🤝 Social y familia

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `SOC_AMIGO` | Mi primer amigo | Primer amigo (NPC o jugador) | 🥉 |
| `SOC_DIEZ_AMIGOS` | Popular | 10 amigos jugadores | 🥈 |
| `SOC_EQUIPO` | Trabajo en equipo | 25 turnos con otro jugador | 🥈 |
| `SOC_HOGAR` | Hogar, dulce hogar | Formar un hogar | 🥈 |
| `SOC_HIJO` | La familia crece | Primer hijo (jugador o NPC) | 🥇 |
| `SOC_ABU` | Ahora el Abu soy yo | Acompañar a un nieto en su primer día de colegio | 💎 |
| `SOC_AFINIDAD` | Querido/a por todos | Afinidad 5 con 5 NPC | 🥇 |
| `SOC_DON_ERNESTO` | El sucesor | Completar la cadena de Don Ernesto | 💎 |
| `SOC_AMIGOS_INFANCIA` | Amigos para siempre | Ayudar a Nico, Sara y Omar a cumplir sus sueños | 🥇 |

#### 🔎 Leyendas y secretos

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `LEY_RELOJ` | El reloj que se paró | Leyenda del reloj | 🥈 |
| `LEY_CARTA` | La página perdida | Encontrar la página de la carta de fundación | 🥈 |
| `LEY_BALLENAS` | Vuelven las ballenas | Ver las ballenas desde el faro | 🥇 |
| `LEY_VAGON` | El vagón perdido | Descubrir el vagón | 🥈 |
| `LEY_OLIVO` | La semilla del primer olivo | Plantar el olivo de reliquia | 🥇 |
| `LEY_AZOTEA` | El jardín de las alturas | Entrar al jardín de la azotea | 🥇 |
| `LEY_CRONISTA` | Cronista de Valmar | Todas las leyendas | 💎 |
| `LEY_CANELA` | Amigo de Canela | Acariciar a la gata Canela 50 veces | 🥉 (secreto, divertido) |

#### 🌳 Linaje (se cumplen a lo largo de varias vidas)

| ID | Nombre | Cómo se consigue | Nivel |
|---|---|---|---|
| `LIN_DOS_GEN` | Segunda generación | Jugar con un heredero | 🥇 |
| `LIN_TRES_GEN` | Tres generaciones | Tercera generación en el linaje | 💎 |
| `LIN_CINCO_GEN` | Dinastía | Cinco generaciones | 💎 |
| `LIN_TRES_MEDICOS` | Familia de batas blancas | Tres médicos en el linaje | 🥇 |
| `LIN_NEGOCIO_FAMILIAR` | Negocio familiar | Un negocio heredado que sigue abierto 2 generaciones | 💎 |
| `LIN_CASA_FAMILIAR` | La casa de siempre | La misma casa en 3 generaciones | 🥇 |
| `LIN_OCHO_OFICIOS` | Familia polifacética | 8 profesiones distintas en el linaje | 🥇 |

## 7.4 Títulos visibles

Se muestran bajo el nombre del personaje (uno a la vez, el jugador elige):

- **De carrera** (el rango actual): *"Dra. García · Cirujana"*, *"Cabo López · Bomberos de Los Pinos"*.
- **De logro**: *"Cronista de Valmar"*, *"Vecino/a de Honor"*, *"Llaves de la Ciudad"*, *"El sucesor de la Cafetería Central"*.
- **De evento** (temporales): *"Rey/Reina del Carnaval"*, *"Campeón/a de castillos de arena"*.

Los títulos con género se escriben en dos formas (femenina y masculina) y el jugador elige, o se usa una forma neutra
(ver [09](09-textos-traduccion.md)).

## 7.5 El legado

### Qué es

Cuando un personaje llega a mayor, **el jugador decide cuándo cerrar su vida** ([Fase 6.2](../diseno/06-edades-progresion.md)).
No hay muertes por sorpresa en el modo normal. El cierre se presenta como **"pasar el testigo"**: el personaje se retira
a vivir tranquilo en Villaverde (o donde elija) y su historia se escribe en el **Libro de Valmar**.
En el modo realista opcional, la vida puede terminar por edad; se presenta igual, con respeto y sin escenas tristes explícitas.

### Paso 1 — "Mi capítulo" con Elvira Castell

En la Biblioteca Universitaria, Elvira abre el Libro de Valmar y ayuda a escribir el capítulo:

1. **Elegir 5 recuerdos** del Álbum que irán en la página.
2. **Elegir un sobrenombre** de una lista generada según la vida: *"La bombera que encendió el faro"*,
   *"El chef de San Roque"*, *"La profesora de las mil preguntas"*. (Se construye con piezas traducibles: ver [09](09-textos-traduccion.md).)
3. **Una frase propia** (opcional, filtrada con `TextService`): *"Lo mejor fueron los domingos en el mercado."*
4. Se calculan los **Puntos de Legado** de la vida (suma de recuerdos + logros de esa vida).

El Libro de Valmar se puede **visitar**: cualquier jugador puede leer las páginas de sus amigos y de su familia
(y, si el dueño lo permite, aparecer en la estantería pública de "vidas destacadas").

### Paso 2 — La despedida

Pequeña ceremonia opcional en un lugar que elija el jugador (el faro, el parque de su infancia, su restaurante):
familiares y amigos jugadores reciben invitación; Radio Valmar dedica unas palabras; el personaje entrega sus
**reliquias** al heredero. Tono: agradecido y luminoso, como una fiesta de jubilación.

### Paso 3 — El heredero

Según la [Fase 12.6](../diseno/12-multijugador-social.md), el jugador elige:

| Heredero | Cómo empieza |
|---|---|
| Un **hijo NPC** que ha crecido en la familia | El jugador toma el control con su edad actual |
| Un **hijo jugador** | Recibe la herencia (su personaje sigue siendo suyo) |
| Un **nuevo nacimiento** en el linaje | Nace bebé en la casa familiar. **El viejo personaje puede aparecer como el "Abu" de su tutorial** (NPC con su apariencia) |

> Esta última opción cierra el círculo: el jugador que fue guiado por Abu en su primera vida, **se convierte en el Abu**
> de su propio heredero.

### Qué se hereda

| Se hereda | Detalle |
|---|---|
| **Dinero** | Con impuesto de sucesiones (sumidero de la economía, [Fase 5](../diseno/05-economia.md)) |
| **Propiedades y negocios** | Pasan al heredero (o a su hogar si es menor) |
| **Reliquias** | Objetos especiales de misiones (silbato de Bernardo, olivo del valle, réplica del reloj, bufanda firmada del Derbi, taza de la Cafetería Central). Nunca se venden |
| **Talento familiar** | +1 nivel inicial en la habilidad más alta del padre o madre (máximo +3 acumulado en el linaje) |
| **Apellido conocido** | Los NPC con afinidad alta con el antepasado saludan al heredero ("¡Tú eres nieto/a de {nombre}! Tu abuela me salvó la cafetería…") y empiezan con afinidad 1 |
| **Escudo familiar** | Diseñado por el jugador con piezas (colores, símbolo). Aparece en la puerta de la casa familiar y en la página del Libro |

### Puntos de Legado (PL): para qué sirven

- Suman al **Legado del linaje** (ranking de familias, `Ranking_*` en [Fase 4](../diseno/04-datos.md)).
- Desbloquean **mejoras cosméticas del linaje**: marcos para el Álbum, colores del escudo, decoración de la casa familiar,
  "retrato de familia" en el salón con todos los antepasados.
- **No** dan dinero ni ventajas económicas: el heredero debe estudiar y trabajar como todos. El legado es orgullo,
  no un atajo.

## 7.6 Rankings (competición sana)

| Ranking | Periodo | Ejemplo |
|---|---|---|
| Mejor profesional de la semana | Semanal por profesión | "Barista con más cafés perfectos" |
| Más aportación a la ciudad | Por proyecto | Muro de honor |
| Familias con más legado | Permanente | "Dinastía García: 4 generaciones, 3.420 PL" |
| Mejor casa / escaparate | Por festival | Votación de jugadores |

🔶 **Propuesta:** la [Fase 4](../diseno/04-datos.md) menciona un ranking de "el más rico". Proponemos no mostrarlo por defecto,
porque empuja a acaparar y a comprar dinero con Robux. Si se mantiene, que cuente solo el dinero ganado jugando, sin compras.
