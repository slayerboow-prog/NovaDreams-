# Encargo de Sebastián: historia cinematográfica

Papel: director de juego, director de cine, guionista, diseñador narrativo, animador y jefe de QA.

**Objetivo:** que gran parte de la experiencia se sienta como estar dentro de una **película interactiva**. No se trata de «añadir algunas cinemáticas».

Etapas de la vida: **BEBÉ → NIÑO → ADOLESCENTE → UNIVERSIDAD → PROFESIÓN → VIDA ADULTA.**

## Orden de prioridad

1. Corregir los bugs existentes.
2. Que toda la historia funcione.
3. Que las misiones funcionen.
4. Un sistema cinematográfico robusto.
5. Cinematizar los diálogos importantes.
6. Actuación de los NPC.
7. Cámaras.
8. Animaciones.
9. Audio.
10. Transiciones.
11. Test completo.
12. Regresión final.

## Antes de programar

**Primero hay que AUDITAR. No se da nada por bueno.** El resultado es un documento «NARRATIVE & CINEMATIC AUDIT» que diga:
- qué está mal;
- qué funciona;
- qué hay que modificar;
- qué hay que reconstruir;
- qué hay que mantener.

Hay que buscar todo esto:

- **Misiones:**
  - bugs;
  - misiones rotas, que no se activan o que se activan mal;
  - softlocks y misiones que pueden quedar bloqueadas;
  - objetivos que no se actualizan;
  - eventos fuera de orden;
  - problemas al abandonar una misión o al volver a ella.
- **NPC:**
  - aparecen o desaparecen mal, o salen en sitios incorrectos;
  - atraviesan objetos o flotan;
  - teletransportes bruscos;
  - inmóviles mientras hablan;
  - hablan mirando a otro lado;
  - no reaccionan.
- **Diálogos:**
  - se cortan;
  - salen demasiado rápido o demasiado tarde;
  - se repiten cuando no deben;
  - conversaciones estáticas.
- **Escena y cámara:**
  - cámaras incorrectas;
  - transiciones pobres;
  - cinemáticas que parecen prototipos;
  - escenas sin emoción;
  - momentos que deberían ser cinemática y son juego normal;
  - animaciones incorrectas;
  - fallos de continuidad.
- **Sistemas:**
  - guardar y cargar partida;
  - multijugador y sincronización;
  - morir, reiniciar o cambiar de zona.

## Reglas

**No romper lo que ya funciona.** Antes de tocar un sistema:
1. analizarlo;
2. entender cómo funciona;
3. ver de qué depende;
4. ver qué misiones o sistemas dependen de él;
5. cambiar solo lo necesario;
6. volver a probar.

Nada de reescribirlo todo, borrar contenido o simplificar. El objetivo es **mejorar, corregir y profesionalizar**.

## Cómo tienen que ser las escenas

**Conversaciones escenificadas.** Nada de chatbox con personajes quietos. Una conversación normal va así:

1. El NPC está haciendo algo y oye al jugador.
2. Deja lo que hace, se gira y le mira a los ojos.
3. Cambia la cámara y hay una pausa.
4. Habla, con expresión, gestos de manos y miradas.
5. El jugador responde.
6. Puede entrar otro personaje.
7. Al terminar, la cámara vuelve al juego poco a poco.

Toda conversación importante debe tener **contexto + actuación + cámara + animación + reacción + transición**.

**Qué hay que cinematizar:**
- introducciones y primeros encuentros con personajes;
- momentos familiares y escolares;
- conflictos y discusiones;
- amistades;
- logros y fracasos;
- exámenes;
- decisiones;
- graduaciones;
- entrada a la universidad;
- primer trabajo, entrevistas, ascensos y despidos;
- problemas personales;
- descubrimientos;
- misiones principales;
- finales de capítulo.

Solo donde aumente la emoción, la narrativa o la inmersión.

**Sistema cinematográfico reutilizable, guiado por datos.** Una escena (CINEMATIC_SCENE) se define con:
- cámara;
- actores;
- diálogo;
- animaciones;
- audio;
- iluminación;
- eventos;
- tiempos;
- condición de final.

El sistema controla todo eso, más la mirada, las expresiones, los subtítulos, la música, las transiciones, las entradas y salidas de personajes, los objetos que se activan y los eventos de juego.

**Cámara con intención:**
- Planos:
  - general;
  - medio;
  - primer plano y primerísimo primer plano;
  - sobre el hombro;
  - de dos personajes;
  - lateral;
  - de reacción;
  - siguiendo al personaje.
- Movimientos: travelling, dolly, pan y tilt.
- Sin abusar: cada cambio de plano tiene que tener una razón narrativa.
- Ejemplo de un descubrimiento: plano general → reacción → primer plano → mirada → plano del objeto → reacción.

**Movimiento natural.** Los NPC no aparecen de golpe en su sitio:
- caminan;
- se sientan y se levantan;
- se giran;
- cogen y dejan objetos;
- abren y cierran puertas;
- señalan;
- se acercan y se alejan.

Ejemplo: el profesor está trabajando, oye al jugador, levanta la cabeza, se gira, se acerca unos pasos y empieza a hablar.

**Mirada contextual.** Los personajes miran:
- al que habla;
- al objeto importante;
- hacia donde señalan;
- a la puerta cuando alguien entra;
- al suelo cuando están incómodos;
- a otro lado cuando piensan.

**Animación por emoción**, natural y sin exagerar:

| Emoción | Cómo se ve |
|---|---|
| Alegría | Sonrisa, postura abierta, movimientos rápidos |
| Tristeza | Cabeza baja, movimientos lentos, postura cerrada |
| Enfado | Movimientos bruscos, postura rígida, gestos fuertes |
| Sorpresa | Retrocede y se para |
| Nervios | Mira alrededor, se toca las manos, cambia el peso de pierna |
| Vergüenza | Evita la mirada, baja la cabeza |

**Diálogos de guionista profesional:**
- Nada de frases robóticas, repeticiones, explicaciones artificiales ni parrafadas sin acción.
- Cada personaje tiene personalidad, forma de hablar, vocabulario, ritmo, emociones, relaciones, motivaciones y evolución.
- **Recuerdan lo que ha pasado antes.**

**Silencios y pausas naturales.** Ejemplo:

> «Yo... no sé si esto es buena idea.»
> *(pausa, mira al jugador, respira)*
> «Pero tenemos que hacerlo.»

**Sonido ambiental** en cada escena:

| Sitio | Sonidos |
|---|---|
| Escuela | Alumnos, pasos, puertas, campana |
| Casa | Electrodomésticos, tele, reloj |
| Universidad | Estudiantes, máquinas expendedoras |
| Hospital | Pitidos, ruedas |
| Calle | Coches, pájaros, viento, gente |

Nunca silencio absoluto.

**Música por intensidad**, con transiciones suaves:

| Momento | Música |
|---|---|
| Normal | Poca o ninguna |
| Descubrimiento | Ligera |
| Momento emocional | Íntima |
| Peligro | Tensión |
| Éxito | Resolución |
| Final de capítulo | Tema memorable |

**Iluminación cinematográfica** cuando haga falta, pero sin romper la identidad visual del juego.

**Transiciones invisibles** entre juego → cinemática → juego:
1. el personaje se coloca;
2. la cámara toma el control poco a poco;
3. la escena;
4. la cámara devuelve el control.

Nada de cortes bruscos ni de teletransportar al jugador.

**Control del jugador:**
- Bloquearlo cuando haga falta.
- Que no pueda romper la escena: saltar, mover la cámara o abrir menús no la estropea.
- Que no molesten los otros jugadores.
- **Al terminar, los controles se restauran SIEMPRE.**

**Multijugador.** Pensar qué pasa cuando:
- otro jugador entra en la escena o la atraviesa;
- varios jugadores hacen la misma misión;
- alguien abandona, muere, se desconecta o vuelve a entrar.

Una escena de la historia personal no debe estropear la experiencia de los demás.

**Misiones.** Cada una sigue la cadena:

START → OBJECTIVE → PLAYER ACTION → NPC RESPONSE → NEXT OBJECTIVE → REWARD → NEXT STORY EVENT

Ninguna se puede quedar muerta. Todas necesitan inicio y objetivo claros, aviso al jugador, progreso, final, recompensa y conexión con la historia.

**Continuidad absoluta.** Nada de memoria de pez: lo que pasa tiene consecuencias. Por ejemplo, si un personaje:
- conoció al jugador;
- discutió con él;
- recibió un objeto;
- cambió de trabajo;
- se graduó;
- se mudó.

**Finales de capítulo memorables**, como finales de episodio de una serie, para cada etapa.

**Transiciones entre etapas de la vida.** Que sean un acontecimiento, no «edad actualizada»:
- el mundo y los personajes evolucionan;
- cambia la música;
- se muestran lugares conocidos;
- montajes cortos.

**Cinemáticas dinámicas** según lo que haya hecho el jugador:
- si llegó tarde;
- si tiene buena relación con el personaje;
- si discutió con él;
- si tiene cierto objeto.

**Calidad de juego comercial:**
- movimientos suaves;
- buen timing;
- cámaras bien puestas;
- luz coherente;
- animaciones naturales;
- sonido de ambiente;
- buenos diálogos;
- transiciones profesionales;
- continuidad.

Nada de demo, prototipo, NPC pegados al suelo, personajes robóticos, cámaras al azar ni texto flotante sin intención.

**Prohibido:**
- teletransportes innecesarios;
- NPC congelados;
- texto sin actuación;
- cámaras estáticas;
- animaciones genéricas;
- sonidos al azar;
- fundidos constantes;
- escenas demasiado largas;
- scripts duplicados;
- parches que rompan otras misiones.

**Regla de oro.** Cada escena tiene que responder:
- ¿Qué está pasando?
- ¿Por qué?
- ¿Qué siente el personaje?
- ¿Qué ve el jugador?
- ¿Qué quiero que sienta el jugador?

## Pruebas y revisiones

**Pruebas obligatorias:**
- jugador nuevo y jugador con progreso;
- abandonar, volver, reiniciar, morir y desconectarse;
- varios jugadores;
- escenas seguidas y repetidas;
- guardar y cargar.

No puede haber:
- softlocks ni misiones imposibles;
- teletransportes;
- NPC desaparecidos;
- cámaras o controles bloqueados;
- diálogos duplicados;
- animaciones atascadas;
- sonido o música que sigue después de la escena;
- eventos que se ejecutan dos veces.

**Revisiones antes de terminar:**
1. Primera implementación.
2. Segunda auditoría completa:
   - historia;
   - misiones;
   - NPC y diálogos;
   - animaciones y cámaras;
   - sonido y música;
   - transiciones;
   - guardado;
   - multijugador;
   - cambios de etapa;
   - interacciones y eventos;
   - errores.
3. Tercera revisión, solo con esta pregunta: «¿Esto realmente parece una película?». Si no, se mejora.

**Resultado:** que el jugador sienta «estoy viviendo una película dentro de este mundo», no «estoy haciendo una misión de Roblox».
