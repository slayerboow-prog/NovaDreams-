# Real Life Simulator — Historia y jugabilidad

> *"Valmar: donde el valle se encuentra con el mar… y tu vida empieza."*

El [documento de diseño](../diseno/README.md) explica **cómo está construido** el juego (sistemas, datos, economía).
Esta carpeta explica **qué vive el jugador**: el mundo y su historia, las personas que lo habitan, qué hace
en cada sesión, las misiones, los trabajos minuto a minuto, los logros y lo que deja al final de su vida.

Todo lo que hay aquí usa los sistemas del diseño. Cuando algo propone un cambio o una ampliación,
se marca con **🔶 Propuesta** para que se decida y, si se aprueba, se actualice el documento de diseño.

## Índice

| # | Documento | Qué contiene |
|---|---|---|
| 01 | [Mundo y trasfondo](01-mundo-trasfondo.md) | Historia de Valmar, las 8 zonas, el calendario de la ciudad y el hilo conductor (el Bicentenario) |
| 02 | [Personajes](02-personajes.md) | Los NPC importantes: quiénes son, dónde están, cómo hablan y para qué sirven en el juego |
| 03 | [Bucle de juego](03-bucle-de-juego.md) | Qué hace el jugador en 15 minutos, en una semana y a largo plazo. Objetivos y recompensas |
| 04 | [Los primeros 30 minutos](04-primeros-30-minutos.md) | Nacimiento, bebé, infancia y tutorial integrado, minuto a minuto |
| 05 | [Misiones y eventos](05-misiones-eventos.md) | Misiones por etapa de vida, por profesión y de la ciudad (festivales, emergencias, partidos) |
| 06 | [Profesiones jugables](06-profesiones-jugables.md) | Qué se hace de verdad en cada trabajo, minuto a minuto |
| 07 | [Progresión, logros y legado](07-progresion-logros-legado.md) | Hitos de vida, logros, títulos, recuerdos y legado |
| 08 | [Diálogos de ejemplo](08-dialogos.md) | Diálogos de los NPC principales, con clave de traducción |
| 09 | [Textos y traducción](09-textos-traduccion.md) | Reglas para que todo se pueda traducir al inglés, y la tabla de textos lista para Roblox |
| 10 | [LifeStorySystem (técnico)](10-life-story-system.md) | La vida como campaña: arquitectura, datos, misiones, NPC, tiempo, educación, profesiones jugador/NPC y plan por fases. **Fase 1 programada** |

## Los cinco principios de la historia

1. **La historia es tu vida.** No hay un "héroe elegido" ni un villano. El protagonista es el jugador, y la trama
   son sus decisiones: qué estudia, dónde vive, a qué se dedica, qué deja a los suyos.
2. **La ciudad te conoce.** Los NPC recuerdan lo que has hecho (el panadero te llama por tu nombre, la maestra
   pregunta por tu sueño). Poca memoria, pero bien elegida, hace que el mundo parezca vivo.
3. **Siempre hay algo que hacer en los próximos 5 minutos** y algo que desear para los próximos 5 días.
4. **Cooperar, no competir con daño.** Nadie puede perjudicar a otro jugador. Se compite en rankings, partidos y
   concursos; se colabora en emergencias, festivales y proyectos de ciudad.
5. **Para todos los públicos de Roblox.** Sin romance entre jugadores (la pareja es solo un rol de hogar, D6),
   sin alcohol, sin violencia entre jugadores, **sin azar con Robux** (ni cajas sorpresa, ni sorteos, ni apuestas
   en los partidos). Todas las recompensas son fijas y se ganan jugando.

## Cómo encaja con el roadmap

No todo lo de esta carpeta se construye a la vez. Cada misión, evento o profesión indica el hito en que
puede entrar (M2 = alfa, M3 = infancia y educación, M4 = ciudad viva, etc., ver [roadmap](../diseno/16-roadmap.md)).
El orden recomendado para escribir contenido es:

| Hito | Contenido narrativo que necesita |
|---|---|
| M2 (alfa) | Tutorial de los primeros 30 min (versión simple), 6 profesiones, misiones diarias, primeros logros, NPC de Valmar Centro y San Roque |
| M3 | Infancia y adolescencia completas, misiones del colegio y del instituto, Campus Valmar, profesiones con título |
| M4 (beta) | Director de eventos: emergencias, festivales, partidos, noticias con la voz de Radio Valmar |
| M5 | Misiones familiares, cuidado de bebés jugadores |
| M6–M7 | Misiones de casa, construcción y negocio. Proyectos de ciudad |
| M8 | Vejez, legado, el Libro de Valmar, logros de linaje |
