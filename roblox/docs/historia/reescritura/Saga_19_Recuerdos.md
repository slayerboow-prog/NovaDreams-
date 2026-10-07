MISIÓN: Saga_19_Recuerdos — «Recuerdos de tostadora»

ID ORIGINAL: Saga_19_Recuerdos
ACTO: IV — 1/6
ETAPA: Adulto
DURACIÓN OBJETIVO: 30–40 minutos
REQUISITOS: Saga_18_Precio + Adulto

⸻

1. FUNCIÓN NARRATIVA

Esta misión abre el Acto IV.

Después de rescatar a Cosme y descubrir que ha perdido prácticamente todos sus recuerdos, el jugador deja de perseguir a Cósimo durante un momento.

Ahora la misión es más personal:

recuperar a Cosme.

La idea central es:

Los recuerdos no están solamente en la cabeza.
También están en los lugares, objetos y personas que los hicieron posibles.

La misión debe convertir partes antiguas de la aventura en contenido nuevo.

El jugador vuelve a lugares conocidos, pero ahora los observa desde otra perspectiva.

Cada lugar activa:

* recuerdos parciales;
* pequeños flashbacks jugables;
* cambios de iluminación;
* sonidos del pasado;
* objetos que Cosme reconoce;
* reacciones corporales;
* diálogos breves;
* pequeñas acciones del jugador.

La misión debe transmitir progresivamente:

confusión → reconocimiento → emoción → memoria completa → revelación.

⸻

2. ESTADO INICIAL

Al comenzar:

* Cosme está en el garaje.
* Pip está preparando una lista.
* Don Escamas está presente.
* Cosme sigue sin recordar prácticamente nada.
* El jugador ya ha recuperado cierta conexión emocional con él.
* El garaje funciona como punto de partida.

Crear estado:

cosme_memoria_progreso = valor_actual
cosme_recuerdos_completos = false
saga_19_iniciada = true

No reiniciar recuerdos previamente recuperados.

⸻

PASO 1 — HABLAR

Objetivo

Habla con Pip.

Localización

Garaje de Cosme.

Personajes

* Pip
* Cosme
* Don Escamas
* jugador

⸻

PRESENTACIÓN CINEMÁTICA

CÁMARA — General

Mostrar el garaje al amanecer.

El lugar debe sentirse diferente respecto a las misiones anteriores.

Hay actividad.

Pip organiza fotografías, pequeños objetos y papeles sobre una mesa.

Cosme está sentado mirando una pieza mecánica.

La gira lentamente entre sus dedos.

No sabe qué es.

Pero no puede dejar de mirarla.

SONIDO

* zumbido suave del garaje;
* pequeñas herramientas;
* ambiente exterior;
* sonido mecánico muy leve.

MÚSICA

Calma

⸻

CÁMARA — Medio

Pip coloca una hoja sobre la mesa.

Tiene varios lugares escritos.

Cosme mira la lista.

PIP

«He hecho una lista de sitios donde el señor fue feliz.»

Cosme

«¿Yo fui feliz?»

Pausa.

Mira alrededor.

«¿En sitios? ¿Con esta cara? Qué raro.»

Pip levanta ligeramente la cabeza.

PIP

«Es una lista corta.»

Pausa.

«El señor no salía mucho.»

Don Escamas gira lentamente dentro de su pecera.

DON ESCAMAS

«Eso explica muchas cosas.»

Pip continúa.

PIP

«Pero en casi todos estaba usted.»

CÁMARA — PrimerPlano

Cosme mira al jugador.

No dice nada durante unos segundos.

Su expresión cambia ligeramente.

No es reconocimiento.

Es una sensación.

Cosme

«Tú.»

Pausa.

«Hay algo contigo.»

⸻

RECONOCIMIENTO CONDICIONAL

Si existe el recuerdo:

cosme_recuerda_tu_nombre = true

Cosme dice:

«Sé tu nombre.»

Pausa.

«Es lo único que sé seguro.»

Mira al suelo.

«Lo demás… ya veremos.»

⸻

Si no existe:

Cosme observa al jugador.

«No sé quién eres.»

Pausa.

«Pero no me pareces un desconocido.»

⸻

CÁMARA — DosPlanos

Cosme y jugador.

Pip permanece al fondo preparando la lista.

Cosme

«Vamos.»

Se levanta.

«Pero volvemos pronto.»

Pausa.

«Echo de menos una cosa que no sé cuál es.»

Esta frase debe quedarse unos segundos en silencio.

⸻

DON ESCAMAS

Don Escamas se acerca a la parte delantera de la pecera.

CÁMARA — PrimerPlano

Don Escamas

«Mirad también en los cacharros del garaje.»

Pausa.

«Una mente se esconde donde menos te lo esperas.»

Mira una tostadora.

Don Escamas

«En una tostadora, por ejemplo.»

Pausa.

«Yo nunca tiro una copia de seguridad.»

Música

Comedia

Pequeña pausa musical.

⸻

NUEVO SISTEMA — LISTA DE RECUERDOS

Pip entrega al jugador:

Lista_Sitios_Felices

La lista se convierte en una interfaz de misión.

Los lugares pueden completarse en cualquier orden.

Mostrar:

RECUERDOS DE COSME
□ Garaje
□ Granja de Villaverde
□ Parque

Cada recuerdo completado muestra:

MEMORIA RECUPERADA

⸻

PASO 2 — VARIOS OBJETIVOS

Objetivo principal

Lleva a Cosme a los sitios de vuestros recuerdos.

Los objetivos pueden realizarse en cualquier orden.

⸻

PASO 2.1 — MICROONDAS TEMPORAL

Objetivo

Usa el microondas temporal.

Localización

Garaje.

El microondas temporal debe volver a convertirse en un objeto interactivo importante.

Pip lo ha reparado.

CÁMARA — Inserto

Primer plano del microondas.

Pip conecta un cable.

El aparato vibra.

PIP

«Lo he reparado.»

Pausa.

«Más o menos.»

Cosme mira el aparato.

Cosme

«Eso nunca es una frase tranquilizadora.»

⸻

GAMEPLAY

El jugador recibe un bocadillo.

Debe colocarlo dentro del microondas.

Interactuar:

USAR MICROONDAS TEMPORAL

El jugador activa la máquina.

SONIDO

La máquina comienza a vibrar.

El ambiente se distorsiona.

El reloj del microondas cambia rápidamente.

CÁMARA — Inserto

Temporizador:

00:03
00:02
00:01

SONIDO

DING

La puerta se abre.

El bocadillo aparece caliente.

Tiene una pequeña mordida.

Silencio.

Cosme lo mira.

Cosme

«…No.»

Se acerca.

CÁMARA — PrimerPlano

Cosme huele el bocadillo.

Su expresión cambia.

Cosme

«Martes.»

Pausa.

«Era martes.»

El jugador no interviene.

Cosme toca el bocadillo.

FLASHBACK

Durante unos segundos, el entorno se transforma.

El garaje adquiere su apariencia antigua.

Se escucha una versión lejana de las voces del pasado.

No mostrar una escena completa.

Mostrar fragmentos:

* una herramienta;
* una pieza cayendo;
* Cosme trabajando;
* el jugador entrando;
* un bocadillo;
* una risa.

CÁMARA — Lateral

Cosme observa el recuerdo como si estuviera dentro de él.

Cosme

«Tú estabas aquí.»

Mira al jugador.

«Tenías las manos llenas de piezas.»

Pausa.

«Yo te dije que no tocaras nada.»

Sonríe.

«Lo tocaste todo.»

Música

Emocion

El flashback desaparece.

El garaje vuelve a la normalidad.

ESTADO

recuerdo_microondas = true
cosme_memoria_progreso += 20

⸻

PASO 2.2 — GRANJA DE VILLAVERDE

Objetivo

Lleva a Cosme a la granja de Villaverde.

Localización

Nido de Petra / granero.

Personajes

* Cosme
* Petra
* Julián
* jugador

⸻

LLEGADA

Cosme camina lentamente.

No reconoce el lugar al principio.

CÁMARA — General

Mostrar la granja.

Animales moviéndose.

Julián trabajando.

Petra caminando por la zona.

Cosme observa.

Julián

«Hombre, Cosme.»

Pausa.

«¿Vienes a disculparte con Petra?»

Julián mira a Petra.

Julián

«Ya iba siendo hora.»

Pausa.

«Solo han pasado… muchos años.»

⸻

PETRA

Petra se acerca.

Cosme retrocede medio paso.

Petra le da un pequeño picotazo en la rodilla.

Cosme

«¡AY!»

CÁMARA — Reaccion

Cosme se agarra la rodilla.

Mira a Petra.

Silencio.

Cosme

«¡La gallina!»

Pausa.

«¡La gallina de seis metros!»

Otra pausa.

Cosme

«¡El rayo agrandador!»

Petra vuelve a picotear el suelo.

Julián

«Sí.»

Pausa.

«Ella tampoco lo ha olvidado.»

Música

Comedia

⸻

FLASHBACK

El jugador activa automáticamente un recuerdo corto.

La granja cambia visualmente.

La cámara muestra:

* la antigua camioneta;
* Cosme corriendo;
* la gallina gigante;
* el jugador intentando ayudar;
* Cosme señalando desesperado;
* una escena absurda de la aventura pasada.

No reproducir toda la misión original.

Solo fragmentos.

⸻

RECUERDO ADICIONAL

Si existe:

gallina_seis_metros = true

Cosme recuerda:

«La furgoneta.»

Pausa.

«Y el martes que terminé convertido en perchero.»

Mira al jugador.

Cosme

«No sé por qué confiaba en ti.»

Sonríe.

«Pero claramente lo hacía.»

ESTADO

recuerdo_granja = true
cosme_memoria_progreso += 20

⸻

PASO 2.3 — PARQUE / ANCLA

Objetivo

Lleva a Cosme al parque.

Este es el recuerdo emocional más importante de la misión.

⸻

LLEGADA

El ritmo cambia.

No utilizar humor inmediatamente.

CÁMARA — General

Atardecer.

El parque está tranquilo.

NPCs pasean.

Niños juegan.

Personas atraviesan el espacio con sus rutinas normales.

Cosme camina junto al jugador.

No habla.

⸻

EL ANCLA

En un punto del parque permanece el antiguo cristal/ancla que el jugador colocó años atrás.

Todavía emite una luz muy tenue.

CÁMARA — Inserto

La luz.

Pequeñas partículas.

El sonido del ambiente comienza a apagarse.

Cosme se detiene.

CÁMARA — PrimerPlano

Mira el cristal.

Cosme

«Eso.»

Pausa.

«Yo conozco eso.»

Se acerca.

⸻

INTERACCIÓN

Aparece:

TOCAR EL ANCLA

El jugador interactúa.

Cosme coloca la mano sobre el cristal.

SONIDO

Pulso suave.

El entorno cambia.

⸻

FLASHBACK INTERACTIVO — «LA NOCHE DE LA AGUJA»

No convertirlo en una cinemática pasiva.

El jugador controla durante unos segundos una recreación del recuerdo.

Debe:

1. caminar;
2. subir;
3. seguir la señal;
4. observar el punto donde se produjo la primera conexión.

No debe durar más de 60–90 segundos.

⸻

CÁMARA — Seguir

La cámara acompaña al jugador.

Música

Emocion

Fragmentos de sonidos antiguos aparecen alrededor.

No son diálogos completos.

Son recuerdos.

⸻

RECUERDO DE COSME

El jugador sube al lugar correspondiente.

Cosme aparece como recuerdo.

Lo observa desde cierta distancia.

Cosme del recuerdo

«Ten cuidado.»

El jugador continúa.

La escena termina.

⸻

REGRESO AL PRESENTE

El jugador vuelve al parque.

Cosme continúa tocando el cristal.

Una lágrima puede insinuarse mediante expresión facial y mirada, sin dramatización excesiva.

CÁMARA — PPP

Cosme mira al jugador.

Cosme

«Y yo…»

Pausa.

«Yo me sentí orgulloso.»

Baja la mirada.

«No supe decírtelo.»

Silencio.

El jugador puede acercarse.

No hace falta diálogo.

El jugador y Cosme permanecen juntos unos segundos.

Música

Emocion

⸻

ESTADO

recuerdo_ancla = true
cosme_memoria_progreso += 30

⸻

PASO 3 — ESCENA FINAL

Localización

Garaje.

Personajes

* Cosme
* Pip
* Don Escamas
* jugador

⸻

TRANSICIÓN

Regreso al garaje al anochecer.

No utilizar pantalla de carga si es posible.

La cámara acompaña al grupo entrando.

Cosme se queda quieto delante de su banco de trabajo.

Mira las herramientas.

Una por una.

⸻

CÁMARA — Medio

Pip observa.

PIP

«Señor.»

Cosme no responde.

Pip espera.

Cosme levanta lentamente la cabeza.

Cosme

«Criatura.»

Mira al jugador.

Sonríe.

Esta vez no hay duda.

Cosme

«Me acuerdo.»

Pausa.

CÁMARA — PrimerPlano

Cosme

«De todo.»

⸻

MONTAGE DE RECUERDOS

Crear un montaje rápido.

No mostrar todas las escenas completas.

Solo flashes:

* el microondas;
* las burbujas;
* Don Escamas;
* la cinta;
* el pez;
* la cápsula;
* la primera casa;
* la aguja;
* la granja;
* la gallina;
* la universidad;
* la graduación;
* el garaje;
* el rescate.

Cada recuerdo debe tener un sonido asociado.

Música

Emocion

⸻

COSME

«El microondas.»

Flash.

«Las burbujas.»

Flash.

«El pez.»

Don Escamas mueve los ojos.

«La cinta.»

Flash.

«La cápsula.»

Pausa.

Cosme mira al jugador.

Cosme

«Y tú.»

Silencio.

⸻

RECUERDOS CONDICIONALES

Si existen determinadas variables, insertar recuerdos breves.

Si:

clones_conocidos = true

Cosme:

«Los clones.»

Si:

tirachinas_abu = true

Cosme:

«El tirachinas de tu abu.»

Si:

calcetines_perdidos = true

Cosme:

«Los calcetines.»

Pausa.

«Nunca encontré el segundo.»

Si:

credencial_cosme = true

Cosme:

«Mi credencial de ayudante.»

Si:

vecino_secreto = true

Cosme:

«El vecino secreto.»

Si:

cosme_rescatado = true

Cosme mira al jugador.

Cosme

«Me acuerdo de que viniste a por mí.»

Pausa.

«A otra dimensión.»

Sonríe.

«Con zumo de mora.»

Iván no está presente, pero Cosme puede hacer una pequeña imitación del gesto de beber.

⸻

RECUERDO COMPLETO

Pip se acerca.

CÁMARA — DosPlanos

Cosme y Pip.

Pip

«Señor.»

Pausa.

«Bienvenido.»

Cosme lo mira.

Pip

«Otra vez.»

Pausa.

Pip

«De verdad esta vez.»

Cosme coloca una mano sobre Pip.

Cosme

«Gracias.»

⸻

LA REVELACIÓN

El tono cambia.

Cosme mira hacia el escritorio.

Coge una pieza pequeña relacionada con el Ancla.

CÁMARA — Inserto

La pieza.

Cosme

«Ahora lo recuerdo.»

El jugador se acerca.

Cosme

«Sé qué me quitó Cósimo.»

Pausa.

CÁMARA — PrimerPlano

Cosme

«No quería mis recuerdos.»

Pausa.

«Quería lo que había dentro de ellos.»

Pip se queda inmóvil.

Cosme

«Sé cómo liberar el Ancla.»

Silencio.

Don Escamas

«Eso suena bastante importante.»

Cosme asiente.

Cosme

«Lo sabe todo.»

Mira hacia la puerta del garaje.

Cosme

«Y viene a por ti.»

Pausa.

Cosme

«Necesitamos a todo el mundo.»

⸻

FINAL CINEMÁTICO

La cámara sale lentamente del garaje.

CÁMARA — Dolly

Desde dentro hacia fuera.

Cosme, Pip, Don Escamas y el jugador quedan reunidos alrededor de la mesa.

Sobre ella:

* mapa de Valmar;
* piezas del Ancla;
* fotografías;
* la lista de aliados;
* objetos recuperados;
* la nueva información sobre Cósimo.

La ciudad continúa funcionando alrededor.

NPCs regresando a casa.

Vehículos circulando.

Luces encendiéndose.

Valmar sigue viva.

Pero algo está a punto de cambiar.

Música

Tension

Corte a negro.

⸻

RECOMPENSA

Album_de_recuerdos

Objeto permanente.

Debe contener fotografías de los lugares visitados y poder ampliarse durante el juego.

No debe ser únicamente un objeto decorativo.

Debe convertirse en un archivo vivo de la historia del jugador.

Cada misión importante futura puede añadir:

* fotografía;
* personaje;
* lugar;
* fecha;
* recuerdo;
* frase especial.

⸻

ESTADOS Y VARIABLES

Al completar:

saga_19_completada = true
cosme_recuerdos_completos = true
cosme_memoria_progreso = 100
cosme_recuerda_todo = true
cosme_sabe_liberar_ancla = true
album_recuerdos_obtenido = true
equipo_rescate_activo = true

Según los objetivos:

recuerdo_microondas = true
recuerdo_granja = true
recuerdo_ancla = true

Conservar todas las variables históricas existentes.

No sobrescribir decisiones anteriores.

⸻

MEMORIA DEL JUGADOR

Añadir al sistema de memoria:

Título: Cosme recuperó sus recuerdos

Descripción:

Ayudaste a Cosme a recordar su vida, sus aventuras y el vínculo que tenía contigo.

Memoria especial:

cosme_revela_como_liberar_ancla = true

Esta variable será obligatoria para el desarrollo de las siguientes misiones.

⸻

CONSECUENCIA EN EL MUNDO

Después de completar la misión:

Garaje de Cosme

Cambiar ligeramente el comportamiento de Cosme.

Antes:

* confundido;
* pregunta por objetos;
* no reconoce recuerdos.

Después:

* reconoce al jugador;
* comenta recuerdos espontáneamente;
* utiliza herramientas correctamente;
* puede reparar objetos;
* puede mencionar acontecimientos anteriores.

Esto debe suceder también fuera de las misiones.

⸻

SISTEMA DE RECUERDOS ESPONTÁNEOS

Añadir conversaciones opcionales.

Ejemplo:

El jugador entra al garaje.

Cosme puede decir:

«¿Te acuerdas del día de la gallina?»

O:

«Nunca entendí por qué aquel microondas funcionaba.»

O:

«Creo que todavía tengo aquella pieza.»

Estas conversaciones no deben bloquear al jugador.

Deben aparecer como momentos orgánicos.

⸻

DIRECCIÓN DE ACTUACIÓN

Cosme

Inicio:

* confundido;
* inseguro;
* mira objetos buscando significado.

Mitad:

* empieza a reconocer sensaciones;
* ríe antes de comprender por qué;
* se sorprende de sus propios recuerdos.

Parque:

* baja el tono;
* movimientos lentos;
* contacto visual con el jugador;
* orgullo contenido.

Final:

* postura recuperada;
* mirada segura;
* vuelve a comportarse como el Cosme original.

La recuperación de memoria debe sentirse físicamente.

⸻

DIRECCIÓN DE CÁMARA

Usar exclusivamente:

* General
* Medio
* PrimerPlano
* PPP
* Hombro
* DosPlanos
* Lateral
* Reaccion
* Seguir
* Inserto
* Dolly
* Pan
* Tilt

No utilizar otros nombres de planos.

La cámara nunca debe moverse gratuitamente.

Cada movimiento debe tener intención narrativa.

⸻

DIRECCIÓN MUSICAL

Usar exclusivamente:

* Calma
* Tension
* Emocion
* Accion
* Epico
* Comedia

Progresión:

Inicio → Calma
Microondas → Comedia / Emocion
Granja → Comedia
Parque → Emocion
Revelación → Tension

⸻

REGLAS DE DIÁLOGO

Todos los diálogos deben:

* ser cortos;
* funcionar correctamente en móvil;
* tener pausas naturales;
* evitar párrafos enormes;
* permitir animaciones entre líneas;
* no parecer conversaciones de NPC genérico.

No mostrar grandes bloques de texto mientras los personajes permanecen inmóviles.

Cada frase importante debe poder acompañarse de:

* mirada;
* gesto;
* desplazamiento;
* interacción con objeto;
* cambio de postura;
* reacción del otro personaje.

⸻

CRITERIO AAA

Esta misión debe demostrar una idea fundamental del juego:

la historia del jugador importa.

El jugador no está visitando lugares aleatorios.

Está regresando a lugares donde anteriormente vivió acontecimientos.

Por eso, cada ubicación debe reconocer visualmente su propia historia:

* objetos antiguos;
* cambios físicos;
* NPCs que recuerdan al jugador;
* fotografías;
* pequeñas diferencias de iluminación;
* sonidos ambientales;
* recuerdos desbloqueables.

La misión debe provocar la sensación:

«He estado aquí antes, pero ahora significa algo diferente.»

⸻

QA OBLIGATORIO

Antes de marcar la misión como completada comprobar:

Narrativa

* Cosme empieza con memoria limitada.
* Los recuerdos aumentan progresivamente.
* El parque es el momento emocional principal.
* Cosme termina recuperando completamente sus recuerdos.
* Se revela que sabe cómo liberar el Ancla.
* Cósimo queda establecido como amenaza inmediata.

Gameplay

* Los tres recuerdos pueden realizarse en cualquier orden.
* No se puede bloquear la misión por visitar primero un objetivo.
* Cada recuerdo tiene interacción real.
* Los flashbacks no congelan permanentemente al jugador.
* Al terminar un flashback se restaura correctamente el control.

NPC

* Cosme camina con el jugador.
* Pip mantiene actividad durante las conversaciones.
* Don Escamas tiene pequeñas reacciones.
* Julián y Petra mantienen rutinas normales.
* Los NPC del parque no se congelan durante la cinemática.

Cámara

* Restaurar la cámara del jugador después de cada escena.
* Restaurar sensibilidad y control.
* Evitar clipping.
* Evitar cámaras dentro de paredes.
* Garantizar posiciones válidas en móvil.

Persistencia

Cerrar y volver a abrir el juego no debe eliminar:

saga_19_completada
cosme_recuerda_todo
cosme_sabe_liberar_ancla
album_recuerdos_obtenido
recuerdo_microondas
recuerdo_granja
recuerdo_ancla

⸻

RESULTADO EMOCIONAL BUSCADO

El jugador debe terminar esta misión sintiendo tres cosas:

1. Cosme ha vuelto.

2. Todo lo vivido anteriormente tenía importancia.

3. Ahora empieza la verdadera preparación para enfrentarse a Cósimo.

El Acto IV no debe sentirse como otra aventura independiente.

Debe sentirse como la consecuencia inevitable de toda la vida que el jugador ha vivido.
