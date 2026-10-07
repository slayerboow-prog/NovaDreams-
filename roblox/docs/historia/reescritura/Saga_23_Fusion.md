MISIÓN: Saga_23_Fusion — «LA GRAN FUSIÓN»

Reescritura narrativa AAA — Batalla final del Acto IV

ID: Saga_23_Fusion
Etapa: Adulto
Acto: IV — 5/6
Tipo: Batalla final / Cinemática / Acción / Decisión narrativa
Duración objetivo: 35–50 min
Inicio: Cima del Monte del Silencio
Horario: 22:00–04:00
Requisitos: Saga_22_Ancla completada

⸻

INTENCIÓN DE LA MISIÓN

Esta misión debe sentirse como el resultado de toda la vida del jugador.

No debe parecer simplemente otra misión de combate.

El jugador debe sentir:

* que ha llegado al final de una historia que empezó siendo un bebé;
* que cada relación construida importa;
* que las pequeñas cosas aparentemente absurdas de Valmar pueden tener un significado;
* que Cosme y Cósimo están cerrando una herida de veinte años;
* que el jugador no es simplemente “el héroe”: es el Ancla que ha mantenido unida la historia;
* que sus decisiones anteriores cambian escenas, aliados, diálogos, efectos y dificultad;
* que el mundo recuerda lo que hizo.

La batalla debe combinar:

CINEMÁTICA → EXPLORACIÓN → TENSIÓN → SUPERVIVENCIA → ACCIÓN → RECUERDOS → DECISIÓN → CLÍMAX.

No convertir toda la misión en combate.

⸻

VARIABLES QUE DEBEN CONSULTARSE

Antes de iniciar:

decision_trato_cosimo
trampa_cosimo
cosimo_perdonado
cosimo_arregla_66b
consorcio_caido
cosme_recuerda
enfado_con_cosme
perdona_a_cosme
cronos_aliado
aliado_bigotes
aliado_rex
aliado_perez
aliado_gnomos
aliado_malvado
aliados_reunidos
recuerdos_grieta_total

Y especialmente:

restos_grieta_count

Si:

restos_grieta_count >= 4

se activa la variante completa de Los Restos de la Grieta.

⸻

PASO 1 · CINEMÁTICA

Grieta_Fusion

Lugar: Cima del Monte del Silencio
En escena: Jugador, Cosme, Doctor Cósimo

Objetivo

Abrir la misión con una secuencia que haga sentir que el jugador está presenciando algo imposible.

No comenzar con enemigos.

Primero:

silencio.

⸻

Entrada del jugador

El jugador llega caminando a la cima.

La cámara sigue desde atrás.

Cámara

Plano 1 — General

Monte del Silencio completamente oscuro.

La ciudad de Valmar se ve muy abajo.

No hay música durante aproximadamente 2 segundos.

Solo viento.

⸻

Plano 2 — Seguir

La cámara sigue al jugador mientras avanza.

A lo lejos se ve Cosme.

No habla.

Está mirando al cielo.

⸻

Plano 3 — Inserto

La mano de Cosme.

Tiene una pequeña herramienta.

Está temblando ligeramente.

Cosme la aprieta.

⸻

Plano 4 — PrimerPlano

Cosme mira al jugador.

Cosme:

Medianoche.

Pausa.

En punto.

Mira el cielo.

Siempre fue puntual para lo malo.

Música: Tension

⸻

Plano 5 — General

El cielo comienza a abrirse.

No como una explosión.

Como si una enorme costura invisible estuviera separando el cielo.

La luz de la Grieta ilumina las nubes.

La ciudad completa queda bañada durante un instante.

⸻

Plano 6 — DosPlanos

Cosme y jugador.

Si grieta_en_el_cielo

Cosme:

La primera vez era un rasguño.

Mira al cielo.

Tenías que ponerte de puntillas para verlo.

Mira al jugador.

Y ahora míralo.

⸻

Si NO grieta_en_el_cielo

Cosme:

Toda la vida sujetándola sin saberlo.

Pausa.

Hoy no la sujetas solo.

Mira al jugador.

Y eso cambia las cosas.

⸻

Entrada de Cósimo

Se escucha un pequeño aplauso.

La cámara gira lentamente.

Cósimo aparece caminando desde detrás de una roca.

Perfectamente vestido.

Pelo blanco impecable.

Perilla.

Sonrisa.

No corre.

No necesita hacerlo.

⸻

Si trampa_cosimo

Cosme observa a Cósimo.

Cosme:

Ha picado.

Mira al jugador.

Viene sonriendo.

Pausa.

Se ha creído que vienes a rendirte.

⸻

Si NO trampa_cosimo

Cosme mira a Cósimo.

Cosme:

Ahí está.

Pausa.

Con perilla y todo.

Cosme se coloca junto al jugador.

Quédate a mi lado.

⸻

VARIANTE RESTOS_GRIETA

Si restos_grieta_count >= 4:

No añadir diálogo.

En su lugar:

* la Grieta parpadea;
* pequeños objetos aparecen durante décimas de segundo dentro de ella;
* se escuchan sonidos familiares;
* una bombilla;
* una chapa;
* una aguja;
* una carta;
* un objeto del jugador;
* elementos relacionados con recuerdos anteriores.

La cámara hace pequeños cambios de enfoque.

El jugador todavía no entiende qué significa.

Música: Tension

⸻

PASO 2 · ESCENA

El último enfrentamiento verbal

Cósimo baja lentamente por la pendiente.

No saca ningún arma.

Esto debe dejar claro que todavía considera la situación un espectáculo.

⸻

Si decision_trato_cosimo = No

Cósimo:

¡Bienvenidos a la GRAN FUSIÓN!

Abre los brazos.

¡En directo desde el Monte del Silencio!

Mira alrededor.

Y traes público.

Sonríe.

Qué detalle.

⸻

Si decision_trato_cosimo = Trampa

Cósimo observa a todos los aliados.

Pausa.

Mira al jugador.

Vuelve a mirar al grupo.

Cósimo:

Habías aceptado.

Pausa.

¿Y traes un ejército?

Mira a un lado.

¿Gatos?

Mira al otro.

¿Un velocirraptor?

Pausa.

…Me has engañado.

Primer plano.

Me has engañado MUY bien.

Mira a Cosme.

Como él.

⸻

Si consorcio_caido

Cósimo observa el cielo.

Cósimo:

Sin Consorcio.

Pausa.

Sin dinero.

Otra pausa.

Sin público de pago.

Mira su máquina.

Solo yo y mi máquina.

Sonríe ligeramente.

Mejor.

Primer plano.

Así el final es todo mío.

⸻

Si el_trato

Cosme mira al jugador.

Cosme:

Fue a tu casa con flores, ¿verdad?

Mira a Cósimo.

Siempre llevaba flores a las peleas.

Cósimo levanta una ceja.

⸻

Momento emocional

Cosme da un paso adelante.

La música baja.

Música: Emocion

Cosme:

Cósimo.

Pausa.

Todavía estás a tiempo.

Mira la máquina.

Deja la máquina.

Silencio.

Ven a casa.

Cosme sonríe ligeramente.

Te hago un batido.

Cósimo no responde inmediatamente.

⸻

PrimerPlano — Cósimo

Su sonrisa desaparece.

Cósimo:

¿A casa?

Mira a Cosme.

¿A qué casa, Cosme?

Mira al jugador.

Tú tienes una vida.

Señala alrededor.

Un robot.

Pausa.

Un pez.

Mira al jugador.

Una criatura.

Vuelve a mirar a Cosme.

Yo tengo una perilla…

Silencio.

…y una dimensión que me odia.

Cósimo respira.

Levanta una mano.

Cósimo:

¡Drones!

⸻

PASO 3 · HUIDA

«¡La Grieta tira de ti!»

Gameplay

La máquina comienza a generar una fuerza gravitatoria.

El jugador empieza a deslizarse hacia la Grieta.

No es un combate tradicional.

Es una secuencia de supervivencia.

Objetivo

Resiste durante 25 segundos.

El jugador debe:

* agarrarse a estructuras;
* esquivar drones;
* desplazarse entre zonas seguras;
* aprovechar objetos del escenario;
* ayudar a Cosme cuando esté cerca;
* evitar quedar directamente expuesto al campo de la Grieta.

⸻

Cámara

Durante gameplay:

* Seguir;
* General;
* Hombro.

Cuando el jugador esté cerca del borde:

Reaccion.

La cámara debe mostrar la profundidad debajo.

⸻

Evento dinámico

A mitad de la secuencia, Cosme pierde el equilibrio.

El jugador puede acercarse.

Cosme extiende la mano.

Cosme:

¡Criatura!

El jugador lo agarra.

La fuerza aumenta.

Cosme mira al jugador.

Cosme:

Esta vez no te suelto.

⸻

Si el jugador es atrapado

No reiniciar inmediatamente.

Cosme lo agarra.

Animación de mano.

La cámara hace un:

PrimerPlano

de las manos.

Cosme tira del jugador hacia arriba.

Cosme:

¡Casi!

Pausa.

Vamos.

⸻

Transición

Cosme mira hacia arriba.

Una enorme cantidad de drones desciende.

Cosme:

Ahora sí.

Pausa.

Tenemos compañía.

⸻

PASO 4 · PELEA

«Tus aliados te cubren»

Objetivo

Derrota/neutraliza 4 oleadas de drones y robots.

No utilizar violencia gráfica.

Los enemigos se desmontan, se apagan o son expulsados de la zona.

⸻

SISTEMA DE ALIADOS DINÁMICO

Los aliados disponibles dependen de las decisiones anteriores.

Siempre estarán presentes:

* Iván
* Candela
* Pip
* Capitana Ñoz

Y pueden aparecer:

* Agente Cronos;
* Bigotes XVII;
* Rex;
* Ratón Pérez;
* Gnomo Rigoberto;
* Yo malvado de la 66-B.

⸻

Oleada 1

Drones pequeños.

Iván protege al jugador.

Iván:

¡Yo cubro este lado!

⸻

Oleada 2

Robots terrestres.

Candela observa patrones.

Candela:

Tres segundos.

Pausa.

Ahora.

Los robots quedan vulnerables.

⸻

Oleada 3

Drones pesados.

Pip se desplaza hacia una consola.

Pip:

¡He encontrado el botón que dice «NO TOCAR»!

Pausa.

Creo que deberíamos tocarlo.

Lo pulsa.

Los drones pierden estabilidad.

⸻

Oleada 4

Enemigos simultáneos.

Aquí aparecen los aliados opcionales.

Cada uno debe tener una intervención breve y reconocible.

Cronos

¡El tiempo está de nuestra parte!

Activa una pequeña distorsión temporal.

Bigotes XVII

Entra corriendo.

¡Por la República Gatuna!

Rex

Factura pendiente.

Se lanza hacia un robot.

Ratón Pérez

¡Por los dientes!

Gnomo Rigoberto

Llega tarde.

¿Ya ha empezado?

Yo malvado

Si aliado_malvado:

Tranquilo.

Mira al jugador.

Ya sé cómo se hace esto.

Pausa.

Bueno.

Más o menos.

⸻

Si el jugador es alcanzado

Un aliado lo rescata.

No aparece un “game over” frío.

La acción continúa.

Aliado:

¡Te tengo!

El jugador vuelve a la cima.

⸻

PASO 5 · ESCENA

Los Restos de la Grieta

Solo si restos_grieta_count >= 4.

La batalla se detiene durante unos segundos.

Todo queda casi completamente en silencio.

⸻

Pip mira hacia el valle.

Algo brilla.

Pip:

¡Ancla!

Señala.

Pip:

¡Los Restos de la Grieta!

PrimerPlano de Pip.

¡El sello!

Otro destello.

¡La bombilla!

Otro.

¡Mi chapa!

Pausa.

¡Todo lo que devolviste a su sitio!

⸻

General

Por todo Valmar empiezan a aparecer pequeñas luces.

No son explosiones.

Son recuerdos.

Cada objeto que el jugador reparó o devolvió durante su vida produce un pequeño pulso.

La ciudad responde.

⸻

Narrador

Las cosas raras que arreglaste por Valmar se encienden a la vez.

Pausa.

La Grieta las reconoce.

Otra pausa.

Son tuyas.

⸻

Pip

Mira a Cósimo.

Pip:

¡Y tiran de él hacia atrás!

Cósimo intenta avanzar.

No puede.

⸻

Cósimo

Mira sus piernas.

Luego los objetos.

Cósimo:

¿Una farola que canta?

Mira otra luz.

¿Un tenedor?

Mira alrededor.

¿Esto es un ejército…

Pausa.

…o un mercadillo?

Intenta avanzar.

No puede.

PrimerPlano.

Cósimo:

¿Por qué me pesan las piernas?

⸻

PASO 6 · PELEA

«Cósimo en persona — Los Restos»

Solo si restos_grieta_count >= 4.

Esta no debe ser una pelea de daño tradicional.

Es una lucha de resistencia contra la Grieta.

⸻

Objetivo

Mantén a Cósimo dentro del área de los Restos mientras la máquina pierde energía.

Los objetos del pasado generan zonas de estabilidad.

El jugador debe:

1. desplazarse entre los Restos;
2. activar objetos;
3. protegerlos de drones;
4. mantener a Cósimo dentro del campo;
5. permitir que la propia Grieta lo devuelva progresivamente.

⸻

Mecánica especial

Cada objeto activado reproduce durante menos de un segundo un recuerdo asociado.

Ejemplo:

Una farola.

Destello.

Se escucha una pequeña melodía.

Otro objeto.

Una chapa.

Pip riendo.

Otro.

Un buzón.

Una voz del pasado.

No detener el gameplay.

Son micro-recuerdos.

⸻

Cósimo

Mientras retrocede:

¡No!

Pausa.

¡No después de veinte años!

El jugador continúa activando objetos.

Cósimo mira a Cosme.

¡No me vais a devolver!

Cosme responde:

No te estamos devolviendo.

Pausa.

Te estamos llevando a casa.

⸻

Si el jugador es alcanzado

Cósimo:

¡Ja!

Lo lanza hacia atrás.

Un aliado lo ayuda a levantarse.

Aliado:

¡Arriba!

El combate continúa.

⸻

PASO 7 · PELEA

«Cósimo en persona»

Solo si restos_grieta_count < 4.

Esta variante mantiene la dificultad.

Como el jugador no reunió suficientes Restos, debe enfrentarse a Cósimo con ayuda directa de sus aliados.

⸻

Objetivo

Resiste y debilita la máquina de Fusión.

No matar a Cósimo.

La meta es destruir/desactivar el sistema de control.

⸻

Fases

Fase 1

Cósimo activa drones.

Los aliados cubren al jugador.

Fase 2

Cósimo se mueve por la cima.

El jugador debe perseguirlo.

Fase 3

La máquina entra en sobrecarga.

El jugador debe interactuar con tres controles.

Fase 4

Cosme abre una ventana.

Cosme:

¡Ahora!

El jugador activa el último control.

La máquina comienza a apagarse.

⸻

Cósimo

Cósimo:

¡Ja!

Pausa.

¡El público adora un giro!

Lo lanza hacia atrás.

Los aliados levantan al jugador.

⸻

Resultado

La máquina se apaga.

Pero la Grieta permanece abierta.

Silencio.

⸻

PASO 8 · ESCENA FINAL

El verdadero final de la batalla

La montaña queda en silencio.

Cósimo está de pie.

Sin máquina.

Sin ejército.

Sin Consorcio.

Solo él.

⸻

PrimerPlano

Cósimo.

Cósimo:

Veinte años preparando esto.

Mira el cielo.

Veinte años.

Pausa.

Y aquí estoy.

Mira al jugador.

⸻

Si todos_los_aliados

Cósimo mira alrededor.

Cósimo:

Y me gana un Ancla con un ejército de gatos, gnomos y un pez contable.

Pausa.

Qué vergüenza.

Sonríe ligeramente.

Qué episodio tan bueno.

⸻

Si NO todos_los_aliados

Cósimo:

Y me gana un Ancla con un pez contable y un robot.

Pausa.

Qué vergüenza.

Sonríe.

Qué episodio tan bueno.

⸻

Momento Cosme

Cosme da un paso adelante.

La música baja.

Música: Emocion

Si enfado_con_cosme

Cosme:

Alguien me dijo una vez que debí contar las cosas antes.

Mira al jugador.

Tenía razón.

Pausa.

Así que lo digo ahora.

⸻

Si perdona_a_cosme

Cosme:

Alguien me perdonó una noche, en mi garaje.

Pausa.

Sin que me lo mereciera.

Mira a Cósimo.

Ahora me toca a mí.

⸻

Revelación

Cosme mira directamente a Cósimo.

Cosme:

Cósimo.

Pausa.

Aquella noche te solté la mano.

PrimerPlano.

Llevo veinte años pensándolo.

Respira.

No fue a propósito.

Silencio.

Fue miedo.

Pausa.

Perdóname.

⸻

Reacción de Cósimo

PrimerPlano.

Cósimo no responde inmediatamente.

La música desaparece durante un instante.

Cósimo:

…¿Veinte años?

Mira a Cosme.

¿Y ahora me pides perdón?

Pausa.

¿Así?

Mira alrededor.

¿En directo?

Cósimo baja la mirada.

Sonríe tristemente.

Cósimo:

Eres insoportable, Cosme.

Silencio.

⸻

DECISIÓN FINAL DEL JUGADOR

Cósimo mira al jugador.

Por primera vez no está actuando.

No hay espectáculo.

No hay público.

Solo una pregunta.

Cósimo:

¿Y tú qué harías conmigo, Ancla?

La cámara se coloca detrás del hombro de Cósimo.

El jugador tiene el control de la elección.

⸻

OPCIÓN A

«Que vuelva. Que empiece de cero. En esta Valmar.»

Efectos:

empatia +2
cosimo_perdonado = true

Cósimo procesa la respuesta.

Cósimo:

¿Aquí?

Pausa.

¿Sin perilla?

Se toca la barbilla.

Me afeitaré.

Pausa.

Me sentará fatal.

Mira al jugador.

…Gracias.

⸻

OPCIÓN B

«Que vuelva a la 66-B. Pero sin maldad: a arreglarla.»

Efectos:

responsabilidad +2
cosimo_arregla_66b = true

Cósimo mira hacia la Grieta.

Cósimo:

¿Arreglar la 66-B?

Pausa.

¿Una dimensión entera de malvados?

Sonríe.

Sería el reto más grande de mi vida.

Pausa.

Me gustan los retos grandes.

Mira al jugador.

Acepto.

⸻

Si aliado_malvado

El otro yo del jugador da un paso adelante.

Yo malvado:

Yo le ayudo.

Mira al jugador.

Ya sé cómo es ser bueno.

Pausa.

Un poco.

Sonríe.

Tengo práctica.

⸻

CLÍMAX

La máquina empieza a apagarse.

Uno por uno:

Drones → OFF

Robots → OFF

Luces → OFF

Pantallas → OFF

La montaña queda en silencio.

⸻

General

La Grieta sigue abierta.

Pero ahora nadie está intentando controlarla.

Cosme mira al cielo.

⸻

Cosme

Cosme:

Ya no tira nadie de ella.

Pausa.

Solo falta cerrarla.

Mira al jugador.

Para siempre.

⸻

ÚLTIMO PLANO

La cámara asciende lentamente.

La Grieta ocupa prácticamente todo el cielo.

Debajo:

* el jugador;
* Cosme;
* Cósimo;
* Pip;
* Iván;
* Candela;
* aliados.

Pequeños frente a algo gigantesco.

Pero juntos.

Música: Epico

Corte a negro.

⸻

RESULTADO DE MISIÓN

saga_23_fusion_completada = true
venciste_gran_fusion = true
cosimo_derrotado = true
maquina_fusion_detenida = true
grieta_final_abierta = true

Si se utilizó la variante de Restos:

restos_grieta_utilizados = true

Si el jugador perdonó a Cósimo:

cosimo_perdonado = true

Si eligió la 66-B:

cosimo_arregla_66b = true

⸻

BIOGRAFÍA

Al terminar:

«Venciste en la Gran Fusión»

⸻

TRANSICIÓN A Saga_24_Final

No iniciar inmediatamente la siguiente misión.

El jugador debe recuperar el control durante unos segundos.

La ciudad de Valmar se ve a lo lejos.

La Grieta continúa abierta.

Una pequeña vibración recorre el suelo.

Pip mira al cielo.

Pip:

Creo que todavía no hemos terminado.

Cosme:

No.

Mira al jugador.

Pero esta vez…

Sonríe.

Lo terminamos juntos.

CORTE.

La siguiente misión será:

Saga_24_Final — Coser el cielo (de verdad)

⸻

DIRECCIÓN TÉCNICA AAA

Cámara

No usar cámara estática durante conversaciones.

Cada línea importante debe tener intención visual.

Prioridad:

* General para escala;
* Medio para conversación;
* PrimerPlano para decisiones;
* PPP para emociones importantes;
* Hombro para confrontaciones;
* DosPlanos para Cosme/Cósimo;
* Reaccion para respuestas emocionales;
* Seguir para movimiento;
* Inserto para objetos/recuerdos;
* Dolly para revelaciones;
* Pan para revelar personajes;
* Tilt para mostrar la Grieta.

⸻

Animación de personajes

Cosme

Nunca debe permanecer quieto.

Durante conversaciones:

* mira al cielo;
* mira al jugador;
* manipula herramientas;
* aprieta objetos;
* respira;
* cambia el peso de una pierna;
* se acerca cuando habla de Cósimo;
* baja la mirada al recordar aquella noche.

Cósimo

Debe comenzar exageradamente teatral.

A medida que pierde el control:

Actor → persona.

La interpretación debe cambiar progresivamente.

Al principio:

* brazos abiertos;
* sonrisa;
* gestos amplios.

Después:

* menos movimiento;
* respiración;
* mirada perdida;
* hombros ligeramente bajos;
* silencios.

En su disculpa:

cero teatralidad.

⸻

DISEÑO DE SONIDO

La montaña debe sentirse enorme.

Capas:

1. viento;
2. ambiente nocturno;
3. vibración dimensional;
4. drones;
5. maquinaria;
6. respiración;
7. silencios narrativos.

Nunca llenar todos los silencios con música.

Los momentos emocionales más importantes deben poder funcionar casi sin música.

⸻

REGLA CRÍTICA

Esta misión NO debe parecer un boss fight genérico de Roblox.

Debe sentirse como el final de una historia que comenzó con:

un bebé aprendiendo a caminar.

El jugador debe reconocer, aunque sea visualmente, que las pequeñas decisiones de toda su vida han terminado teniendo importancia.

El verdadero enemigo nunca fue únicamente Cósimo.

Fue:

la separación.

Cosme perdió a Cósimo.

Cósimo perdió su mundo.

El jugador descubrió que era el Ancla.

Y ahora todos tienen que decidir qué hacer con aquello que los separó.

La batalla termina cuando el jugador comprende eso.

No cuando baja una barra de vida a cero.
