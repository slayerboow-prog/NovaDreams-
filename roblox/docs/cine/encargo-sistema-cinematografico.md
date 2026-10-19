# Encargo del dueño: sistema cinematográfico profesional

Este documento resume fielmente el encargo de Sebastián.

## Qué quiere

Que el jugador **sienta que vive la historia**, con calidad AAA dentro de Roblox.

No quiere:

- escenas genéricas;
- personajes inmóviles que solo hablan;
- cámaras mal colocadas;
- animaciones desincronizadas;
- diálogos que desaparecen;
- personajes que atraviesan objetos;
- acontecimientos resueltos solo con un mensaje en pantalla.

Regla general: **no destruir lo que ya existe**. Primero se estudia la arquitectura y después se mejora paso a paso.

## 1. Analizar antes de programar

Revisar:

- los scripts de cinemáticas;
- los sistemas de diálogos y de cámaras;
- los personajes y sus modelos;
- las animaciones disponibles;
- las misiones y los acontecimientos narrativos;
- los efectos visuales y sonoros;
- las interfaces de la historia;
- las dependencias y conflictos;
- los errores de sincronización y estado;
- qué funciona y debe conservarse.

No inventar archivos, módulos, animaciones ni funciones. No decir que se ha inspeccionado algo que no se ha visto. Primero un diagnóstico priorizado y después las soluciones.

## 2. Dirección cinematográfica

Usar el recurso que pida cada momento:

- plano general, plano medio, primer plano y contraplano;
- seguimiento de personajes y movimientos de cámara suaves;
- pausas dramáticas y silencios;
- reacciones de los personajes secundarios;
- iluminación, efectos dentro del mundo, música y sonido;
- transiciones entre planos.

Cada plano tiene que tener una función. Las conversaciones normales deben ser naturales y los acontecimientos extraordinarios, espectaculares. Siempre hay que mantener la coherencia de espacio y de tiempo.

## 3. Cámara cinematográfica reutilizable

Debe poder:

- controlar la cámara: posiciones, objetivos, seguimiento y duración de cada toma;
- hacer transiciones suaves sin giros bruscos;
- no atravesar paredes ni personajes;
- mantener encuadres correctos, comprobando la geometría;
- devolver siempre la cámara del jugador, también si la escena se interrumpe o falla;
- no bloquear nunca la cámara.

Usar puntos de cámara colocados en el escenario cuando sea posible, y TweenService, RunService o raycasts según convenga.

## 4. Diálogos naturales

Contenido:

- **Personajes:** cada uno con su propia personalidad.
- **Ingredientes:** humor, conflictos, emociones, interrupciones, silencios e información opcional.
- **Decisiones:** con consecuencias reales.
- **Continuidad:** referencias coherentes a lo que ha pasado antes.
- **Ritmo:** frases cortas que aporten algo.

Parte técnica:

- **Quién habla:** nombre y retrato.
- **Texto:** aparece poco a poco, con velocidad ajustable y opción de mostrarlo entero; se avanza a mano.
- **Respuestas:** opciones de respuesta con sus consecuencias.
- **Acompañamiento:** sonido discreto al escribir y animación de quien habla.
- **Pantalla:** subtítulos legibles, que se adaptan a la resolución y gestionan bien los textos largos.
- **Seguridad:** sin conversaciones duplicadas ni bloqueadas, e interrupciones controladas.

Reglas:

- El texto nunca se sale del recuadro.
- Una frase no desaparece antes de poder leerla.
- Si hay que elegir, se espera la respuesta y no se avanza solo.

## 5. Actuación y animaciones

Los personajes deben actuar:

- cabeza, manos y postura;
- miradas;
- sorpresa, preocupación, enfado y risa;
- caminar y pararse;
- usar objetos;
- animaciones propias de cada acontecimiento.

Reglas:

- Comprobar que cada animación es compatible con el rig.
- No inventar ids.
- Respetar las prioridades y no mezclar animaciones incompatibles.
- Restaurar al personaje al final.
- Si falta una animación, decirlo y usar una alternativa realista.
- No decir que hay sincronización labial si no la hay.

## 6. Acontecimientos dentro del mundo

Ejemplos: meteoritos, la grieta, destrucción, llegadas, alienígenas, descubrimientos, máquinas, persecuciones, explosiones y transformaciones.

Se cuentan con lo que se ve en el mundo, no con un mensaje. El ejemplo del meteorito:

1. se acerca por el cielo;
2. sigue una trayectoria coherente;
3. los efectos crecen;
4. los personajes reaccionan;
5. impacta en un punto concreto;
6. salen polvo, luz y partículas;
7. quedan consecuencias visibles;
8. hay un silencio;
9. los personajes reaccionan otra vez;
10. empieza una misión nueva.

Hay que decidir qué cambios se quedan en el mundo después de la escena.

## 7. Continuidad

Antes de cada escena hay que comprobar:

- dónde está cada personaje, qué hacía, qué sabe y qué objetos lleva;
- qué misiones están activas y qué decisiones ha tomado el jugador;
- cómo está el escenario.

Reglas:

- Nadie se teletransporta entre planos sin una transición.
- No se reinicia nada por comodidad.
- Hay que distinguir los cambios temporales de los permanentes.
- Las misiones tienen que recibir bien los cambios.

## 8. Arquitectura modular

Responsabilidades, sin duplicar módulos que ya existan. Los nombres son una propuesta:

- CinematicService
- CameraDirector
- DialogueService
- DialogueUIController
- CharacterAnimationController
- NarrativeEventService
- CinematicRegistry
- CinematicDebugTools

Cada escena es una secuencia de pasos:

1. esperar una condición;
2. preparar el escenario;
3. iniciar la escena;
4. quitar los controles;
5. mostrar el plano;
6. reproducir la animación;
7. lanzar el efecto;
8. mostrar el diálogo;
9. esperar la respuesta;
10. cambiar de cámara;
11. lanzar el siguiente acontecimiento;
12. actualizar la misión;
13. devolver los controles;
14. terminar.

Cada paso tiene una condición clara de final. Nada de esperas arbitrarias: se usan señales, eventos y comprobaciones de estado.

## 9. Multijugador

Cada escena es individual, de grupo o global. No se bloquea a todos cuando la escena es solo para uno.

- La cámara y la interfaz van en el cliente.
- Los cambios del mundo los coordina el servidor.
- Las recompensas y las misiones se validan en el servidor.
- Una escena no se puede repetir por accidente.

Hay que gestionar las salidas, las muertes, las desconexiones, las interrupciones y los errores.

## 10. Recuperación de errores

Una finalización segura siempre, termine bien o mal la escena:

- detener la secuencia;
- restaurar la cámara, los controles y la interfaz;
- parar los sonidos;
- limpiar las conexiones y tareas pendientes;
- restaurar las animaciones;
- registrar el error.

Nunca dejar al jugador atrapado ni ocultar errores en silencio.

## 11. Pruebas obligatorias

Fases:

1. inspección;
2. diseño (guion y storyboard);
3. implementación;
4. validación del código;
5. prueba en Studio;
6. validación visual;
7. interrupciones;
8. multijugador;
9. regresión;
10. informe.

Nunca se dice que una prueba ha pasado si no se ha hecho. Hay que distinguir:

- código revisado;
- validado estáticamente;
- pruebas automáticas;
- pruebas en Studio;
- comprobación visual;
- pruebas pendientes.

## 12. Proteger el proyecto

- Mantener las dependencias y las funciones públicas.
- No quitar funciones.
- No sustituir scripts enteros sin justificarlo.
- No duplicar ni renombrar sin revisar las referencias.
- Hacer cambios por pasos y documentarlos.

## 13. Rendimiento

Que funcione en PC y en móvil:

- sin exceso de partículas;
- sin bucles ni conexiones colgando;
- sin efectos duplicados ni cargas masivas;
- sin interfaces activas después de la escena.

Usar recursos gratuitos respetando su licencia.

## 14. Qué entregar por cada cinemática

- A. Objetivo narrativo.
- B. Contexto.
- C. Personajes.
- D. Guion.
- E. Guion técnico plano a plano.
- F. Diálogos.
- G. Animaciones.
- H. Efectos visuales.
- I. Sonido y música.
- J. Cambios en el mundo.
- K. Cambios en las misiones.
- L. Archivos.
- M. Implementación.
- N. Pruebas.
- O. Errores pendientes.
- P. Cómo validarla.

## 15. Primera misión: auditar todo el sistema actual

Antes de crear nada nuevo, averiguar:

- por qué fallan las cinemáticas;
- por qué se desincronizan los diálogos;
- qué falla en la cámara;
- qué animaciones son incompatibles;
- qué referencias están mal;
- qué conflictos hay entre scripts;
- qué escenas se bloquean;
- qué errores tiene la interfaz;
- qué misiones avanzan a destiempo;
- qué falla en el multijugador;
- qué limpieza falta;
- qué recursos faltan.

Después:

1. presentar un diagnóstico por gravedad, separando lo confirmado de las hipótesis;
2. proponer una arquitectura;
3. implementar por fases;
4. comprobar que no se rompe nada;
5. documentar.
