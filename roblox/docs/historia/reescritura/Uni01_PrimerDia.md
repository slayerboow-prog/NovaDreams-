MISIÓN: Uni01_PrimerDia — «EL PRIMER DÍA»

Tipo: Historia · Universidad · Nueva etapa
Edad: 18 años
Duración objetivo: 30–40 min
Requisitos: Saga_12_Graduacion
Pasos originales: mantener exactamente los pasos del documento original.
Objetivo narrativo: convertir el primer día universitario en una experiencia jugable completa y establecer el conflicto entre la nueva vida del protagonista y la desaparición de Cosme.

⸻

FUNCIÓN NARRATIVA AAA

Esta misión NO debe sentirse como:

«Llegas a la universidad → hablas con tres personas → termina.»

Debe sentirse como:

«Por primera vez estás construyendo una vida que no depende de tus padres, del instituto ni de tu antiguo barrio.»

El jugador debe experimentar:

* Llegada al campus.
* Orientación.
* Nuevos compañeros.
* Primera decisión académica.
* Exploración.
* Primer pequeño problema.
* Primer momento de independencia.
* Contacto con la vida universitaria.
* Recuerdo de Cosme.
* Preparación para la residencia.

La Grieta no debe dominar toda la misión.

Eso es importante.

El jugador acaba de graduarse.

Tiene que poder vivir el momento.

Pero debe existir una presencia constante:

Cosme no está.

⸻

PASO 1 — LLEGADA AL CAMPUS

LOCALIZACIÓN

Campus universitario.

OBJETIVO

Encuentra la entrada principal de la universidad.

⸻

ENTRADA

No comenzar con una cinemática larga.

El jugador debe aparecer con control.

Tiene una mochila.

Ropa de estudiante.

Teléfono.

Dinero inicial.

⸻

GAMEPLAY

El jugador debe caminar hasta la entrada.

Durante el trayecto:

* Estudiantes corriendo.
* Grupos hablando.
* Alguien buscando un aula.
* Personas haciendo fotografías.
* Bicicletas.
* Personal universitario.
* Carteles.
* Cafetería.
* Biblioteca.
* Laboratorios.
* Pabellón deportivo.

La universidad debe parecer una ciudad pequeña dentro de Valmar.

⸻

NPCs DINÁMICOS

Un estudiante pregunta:

¿Sabes dónde está el edificio B?

Otro:

¿Esto es la facultad de ingeniería?

Otro:

Creo que me he equivocado de campus.

El jugador puede ayudar o continuar.

Si ayuda:

ayudo_nuevo_estudiante = true

Si continúa:

No penalizar.

Esto es vida cotidiana.

⸻

CINEMÁTICA DE ENTRADA

Cuando el jugador llega a la entrada:

General

La cámara muestra todo el campus.

Después:

Dolly

Avanza lentamente hacia el protagonista.

Se escuchan conversaciones.

Campanas.

Puertas.

Pasos.

Un profesor pasa rápidamente con una carpeta.

Una estudiante corre para llegar a clase.

La cámara termina detrás del protagonista.

VOZ / TEXTO

Primer día.

Pausa.

Nadie sabe quién eres.

Pausa.

Y por primera vez… eso puede ser bueno.

Control al jugador.

⸻

PASO 2 — LA ORIENTACIÓN

OBJETIVO

Asiste a la sesión de orientación.

El jugador debe encontrar el edificio correspondiente.

⸻

GAMEPLAY

No colocar un marcador que lleve automáticamente hasta allí.

Utilizar:

* Mapa.
* Señales.
* Carteles.
* NPCs.

El jugador puede preguntar.

Esto hace que la universidad se sienta más real.

⸻

SALÓN

Hay estudiantes sentados.

El orientador explica:

* Horarios.
* Créditos.
* Biblioteca.
* Exámenes.
* Tutorías.
* Actividades.
* Clubes.
* Normas.

No convertir esto en una conferencia larga.

Debe haber interacción.

⸻

MOMENTO INTERACTIVO

Aparecen tres opciones:

1. Tomar apuntes.

responsabilidad +1

2. Mirar alrededor.

curiosidad +1

3. Hablar con el estudiante de al lado.

social +1

No existe una respuesta incorrecta.

La universidad debe permitir construir personalidad.

⸻

PASO 3 — PRIMEROS COMPAÑEROS

OBJETIVO

Conoce a otros estudiantes.

Aquí introducir la vida social universitaria.

No presentar diez personajes de golpe.

Presentar pocos y hacerlos memorables.

⸻

PRIMER COMPAÑERO

El protagonista se encuentra con otro estudiante.

La conversación comienza de manera natural.

Estudiante:

¿También estás buscando el aula?

Jugador:

Sí.

Estudiante:

Perfecto.

Pausa.

Entonces estamos igual de perdidos.

Pequeña sonrisa.

⸻

GAMEPLAY SOCIAL

El jugador puede elegir cómo responder.

Opción A

«Podemos buscarla juntos.»

social +1

Opción B

«Prefiero encontrarla por mi cuenta.»

independencia +1

Opción C

«No tengo ni idea de dónde está.»

humor +1

Las relaciones deben empezar a construirse desde acciones pequeñas.

⸻

PASO 4 — EL PRIMER PROBLEMA

OBJETIVO

Encuentra tu aula antes de que empiece la clase.

⸻

El jugador recibe una notificación.

Clase: Edificio B — Aula 204

El mapa muestra el edificio.

Pero el edificio B tiene dos accesos.

Uno está cerrado.

El otro lleva a un patio interior.

⸻

GAMEPLAY

El jugador debe:

1. Encontrar el acceso correcto.
2. Subir las escaleras o utilizar el ascensor.
3. Encontrar el aula.
4. Llegar antes de que termine el tiempo.

No debe ser difícil.

La función es enseñar:

* Mapa universitario.
* Horarios.
* Navegación.
* Sistema de clases.

⸻

SI LLEGA A TIEMPO

El profesor abre la puerta.

Profesor:

Adelante.

El jugador entra.

primer_dia_clase = true

⸻

SI LLEGA TARDE

La puerta está entreabierta.

El profesor mira al protagonista.

Pausa.

Profesor:

Primer día.

Pausa.

Te lo pasaré por esta vez.

No existe Game Over.

Pero:

llegaste_tarde_uni = true

Esto puede aparecer en futuras conversaciones.

⸻

PASO 5 — LA PRIMERA CLASE

OBJETIVO

Participa en tu primera clase.

La clase debe ser interactiva.

No simplemente sentarse.

⸻

MECÁNICA

El profesor plantea una pregunta.

El jugador puede:

* Responder.
* Levantar la mano pero equivocarse.
* No participar.
* Pedir aclaración.

La respuesta no debe definir toda la carrera.

Es simplemente una primera impresión.

⸻

EJEMPLO

Profesor:

¿Alguien quiere intentarlo?

Silencio.

El jugador puede levantar la mano.

SI RESPONDE

Profesor:

Exacto.

confianza +1

SI SE EQUIVOCA

Profesor:

No exactamente.

Pausa.

Pero buen intento.

valentia +1

SI NO RESPONDE

El profesor continúa.

Sin penalización.

⸻

PASO 6 — EL MENSAJE

Después de la clase, el teléfono vibra.

No hay una cinemática.

El jugador puede abrirlo.

Mensaje de Pip.

⸻

MENSAJE

Pip: Necesito hablar contigo.

Segundo mensaje.

Pip: Es sobre Cosme.

El jugador se queda quieto.

El sonido ambiente continúa.

Estudiantes pasan alrededor.

La cámara no corta.

⸻

SEGUNDO MENSAJE

Pip: No quería hacerlo durante tu graduación.

Pausa.

Pip: Pero ya no puedo esperar.

⸻

CAMBIO DE MÚSICA

El sonido de la universidad se amortigua ligeramente.

Tension

El jugador puede cerrar el teléfono.

No hacer que Pip explique todo por mensaje.

⸻

PASO 7 — PRIMER MOMENTO A SOLAS

OBJETIVO

Busca un lugar tranquilo para llamar a Pip.

Esto es importante.

El jugador no recibe una cinemática automática.

Debe caminar.

Puede elegir:

* Patio.
* Biblioteca.
* Cafetería.
* Zona verde.

La conversación cambia ligeramente dependiendo del lugar.

⸻

LLAMADA

Cuando el jugador llama:

Pip:

Hola, criatura.

Pausa.

Perdón.

Pip corrige.

Hola.

Silencio.

¿Cómo ha ido tu primer día?

El jugador responde.

Pip deja pasar unos segundos.

Pip:

Cosme estaría orgulloso.

Silencio.

⸻

PIP HABLA DEL PROBLEMA

Pip:

He encontrado algo en el garaje.

Pausa.

Algo que dejó preparado antes de desaparecer.

Jugador:

¿Qué?

Pip:

No puedo decírtelo por teléfono.

Pausa.

Ven cuando puedas.

⸻

MOMENTO EMOCIONAL

Pip no dramatiza.

No llora.

Su voz cambia ligeramente.

Pip:

Y…

Pausa.

Feliz primer día.

Silencio.

La llamada termina.

⸻

PASO 8 — FIN DEL PRIMER DÍA

OBJETIVO

Explora el campus antes de volver a casa.

Ahora el jugador tiene libertad.

Puede visitar:

* Biblioteca.
* Cafetería.
* Gimnasio.
* Zona deportiva.
* Clubes.
* Tiendas.
* Jardines.
* Residencias.

Esto introduce la universidad como espacio persistente.

⸻

EVENTO OPCIONAL — BIBLIOTECA

Si el jugador entra:

Puede encontrar un libro relacionado con dimensiones, física o historia de Valmar.

No revelar demasiado.

Simplemente:

«Las grietas entre dimensiones aparecen cuando dos realidades ocupan el mismo espacio.»

El jugador puede cerrar el libro.

FLAG

libro_grietas_encontrado = true

Esto funciona como foreshadowing.

⸻

EVENTO OPCIONAL — CAFETERÍA

Un estudiante pregunta:

¿Eres nuevo?

Si el jugador responde afirmativamente:

Yo también.

Esto puede crear relaciones futuras.

⸻

EVENTO OPCIONAL — ZONA DEPORTIVA

El jugador puede participar en una actividad corta.

Esto conecta la nueva vida universitaria con el sistema de actividades del juego.

⸻

ESCENA FINAL

Cuando el jugador decide abandonar el campus:

General

Atardecer.

Los estudiantes salen.

Las luces del campus comienzan a encenderse.

La cámara sigue al protagonista.

Seguir

El teléfono vibra.

No es Pip.

Es un mensaje de un compañero:

¿Mañana vienes?

El jugador puede responder:

«Sí.»

primer_amigo_uni = true

«Ya veremos.»

independencia +1

«Claro.»

social +1

⸻

ÚLTIMO PLANO

El protagonista se aleja.

La cámara se queda atrás.

El campus continúa vivo.

Un estudiante corre.

Una profesora cierra una puerta.

Una pareja habla.

Un grupo ríe.

El mundo no se detiene porque el jugador se marche.

⸻

VOZ INTERIOR / NARRADOR

El instituto había terminado.

Pausa.

La universidad acababa de empezar.

Pausa.

Pero Cosme seguía desaparecido.

Corte a negro.

⸻

TRANSICIÓN

Texto:

SEMANA 1

Después:

UNIVERSIDAD

Y comienza Uni01b_Residencia.

⸻

FLAGS PRINCIPALES

universidad_iniciada = true
uni_primer_dia_completado = true
primer_dia_clase = true
hablo_con_pip = true
pip_mensaje_cosme = true

Opcionales:

ayudo_nuevo_estudiante = true
llegaste_tarde_uni = true
libro_grietas_encontrado = true
primer_amigo_uni = true

⸻

SISTEMA DE MEMORIA

Registrar:

Primer día de universidad.

El personaje recuerda:

* Su primera clase.
* Su primer compañero.
* Si llegó tarde.
* Si participó.
* El mensaje de Pip.
* La desaparición de Cosme.

Estos datos pueden reaparecer años después.

Ejemplo:

Un NPC podría preguntar:

¿Recuerdas tu primer día aquí?

Y el diálogo debe responder según la memoria guardada.

⸻

DIRECCIÓN CINEMATOGRÁFICA

La universidad debe utilizar un lenguaje visual diferente al instituto.

Instituto

* Cámara más cercana.
* Ritmo rápido.
* Mucha energía.
* Sensación de grupo.

Universidad

* Planos más amplios.
* Más movimiento de NPCs.
* Espacios grandes.
* Mayor sensación de libertad.
* Menos guía.
* Más exploración.

El jugador debe sentir visualmente:

«Ahora estoy solo.»

Pero no:

«Estoy abandonado.»

⸻

MÚSICA

Utilizar exclusivamente:

Calma

* Exploración del campus.

Emocion

* Entrada.
* Primera clase.
* Recuerdo de Cosme.

Comedia

* Primeros encuentros con estudiantes.

Tension

* Mensaje de Pip.

⸻

QA

Comprobar:

* El jugador puede recorrer el campus sin quedarse atrapado.
* Los NPCs tienen rutinas.
* Los edificios principales tienen accesos funcionales.
* La navegación no obliga al jugador a seguir un único camino.
* Las clases funcionan independientemente de la posición inicial.
* Llegar tarde no bloquea la misión.
* Las decisiones sociales guardan correctamente las relaciones.
* El mensaje de Pip aparece una sola vez.
* La llamada no puede quedarse bloqueada.
* El jugador recupera el control después de cada conversación.
* El campus sigue funcionando después de terminar la misión.
* Los eventos opcionales no son obligatorios.
* uni_primer_dia_completado se guarda correctamente.
* La transición a Uni01b_Residencia funciona.
* La desaparición de Cosme sigue registrada.
* Ningún diálogo futuro debe comportarse como si Cosme hubiera regresado.

⸻

OBJETIVO EMOCIONAL

El jugador debe terminar pensando:

«Tengo una vida nueva.»

Y, casi inmediatamente:

«Pero todavía tengo que encontrar a Cosme.»

Ese contraste debe convertirse en el corazón del Acto III.
