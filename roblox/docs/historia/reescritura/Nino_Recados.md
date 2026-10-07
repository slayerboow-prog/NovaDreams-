MISIÓN: Nino_Recados — «Recados por el barrio»

Resumen:
Por primera vez, tu familia confía en ti para hacer unos recados importantes por el barrio. Lo que parece una tarea sencilla se convierte en una pequeña aventura por Valmar: recordar lo que necesitas, orientarte, tomar decisiones y volver a casa con todo.

Tipo: Historia · Vida cotidiana · Independencia
Edad: 8-9 años
Duración objetivo: 10-15 min
Requisitos: Cole06_Examen completada y 36 % de la etapa infantil.

Objetivo emocional:
Que el jugador sienta por primera vez que su familia empieza a confiar en él/ella como alguien capaz de hacer cosas por su cuenta.

Variables nuevas:

* recado_material_completo
* recado_medicinas_completo
* recado_volvio_a_casa
* recado_recordo_todo
* recado_ayudo_a_alguien
* recado_se_oriento_solo

⸻

PASO 1 [Acción del jugador] @ Librería del barrio

«Compra el material del colegio en la librería»

PLANO General -> Calle del barrio | El protagonista sale de casa con una pequeña lista doblada en la mano.

Musica: Calma

Antes de comenzar el jugador recibe el objetivo.

Mamá/Papá:
—Necesitamos unas cosas para el cole.

Mamá/Papá:
—Te he preparado una lista. ¿Crees que puedes encargarte?

PLANO PrimerPlano -> Tú

El jugador puede responder:

ELECCIÓN OPCIONAL

A) «Sí. Puedo hacerlo.»

Efecto: confianza +1

Mamá/Papá:
—Eso quería oír.

⸻

B) «¿Y si se me olvida algo?»

Mamá/Papá:
—Entonces vuelves y lo arreglamos.

Pausa.

Mamá/Papá:
—No tienes que hacerlo perfecto.

Mamá/Papá:
—Solo tienes que intentarlo.

⸻

PLANO Inserto -> Lista

La lista contiene:

* 2 cuadernos.
* 1 lápiz.
* 1 goma.
* 1 caja de colores.

Mamá/Papá:
—Y guarda la lista.

Tú:
—Sí.

Mamá/Papá:
—La última vez la perdiste.

PLANO Reaccion -> Tú

Tú:
—Fue una vez.

Mamá/Papá:
—Tres.

Tú:
—Dos y media.

Pequeña pausa.

Mamá/Papá:
—Venga. Dos y media.

⸻

Gameplay: recorrido hasta la librería

El jugador debe orientarse por el barrio.

No se coloca una flecha gigante directamente hasta la puerta.

Se muestra una guía discreta para que el jugador pueda aprender a moverse por Valmar.

PLANO Seguir -> Tú | Caminas por la calle.

NPCs realizan rutinas normales:

* Una persona abre una tienda.
* Un vecino pasea.
* Dos niños juegan.
* Un repartidor descarga cajas.
* Una persona cruza la calle.

Esto hace que el barrio se sienta vivo.

⸻

Entrada en la librería

PLANO General -> Librería

Campanilla de la puerta.

SONIDO: clin.

PLANO Medio -> Dependiente/a

Dependiente/a:
—¡Buenos días!

Tú:
—Buenos días.

Dependiente/a:
—¿Qué necesitas?

El jugador abre la lista.

PLANO Inserto -> Lista

Minijuego de compra

El jugador debe localizar los objetos correctamente.

Cada objeto produce una pequeña reacción.

PLANO Inserto -> Cuaderno

Tú:
—Dos cuadernos.

Los coloca en el mostrador.

PLANO Inserto -> Lápiz

Tú:
—Un lápiz.

PLANO Inserto -> Caja de colores

Tú:
—Y colores.

Cuando completa todo:

Dependiente/a:
—Creo que no te falta nada.

Tú:
—Creo que no.

El jugador revisa la lista una última vez.

PLANO PrimerPlano -> Tú

Tachas mentalmente cada cosa.

FLAG: recado_material_completo = true

⸻

PEQUEÑA OPORTUNIDAD DE ELECCIÓN

Si el jugador revisa de nuevo la lista:

Dependiente/a:
—¿Seguro?

Tú:
—Sí.

Dependiente/a:
—Buena costumbre.

FLAG: recado_recordo_todo = true

Si sale sin revisar:

La misión continúa normalmente.

⸻

PASO 2 [Acción del jugador] @ Farmacia del barrio

«Tu familia necesita medicinas: cómpralas en la farmacia»

Transición corta

El protagonista sale de la librería con una bolsa.

PLANO Seguir -> Tú

La farmacia está a unas calles.

Musica: Calma

En el camino ocurre un pequeño momento opcional.

EVENTO OPCIONAL — «Un pequeño favor»

Un vecino deja caer varias cosas al suelo.

PLANO General -> Calle

Vecino:
—¡Uy!

Los objetos caen.

El jugador puede ayudar o continuar.

Si ayuda:

PLANO Medio -> Tú / Vecino

El protagonista recoge una de las cosas.

Vecino:
—Gracias.

Tú:
—De nada.

Vecino:
—Tu familia puede estar orgullosa.

FLAG: recado_ayudo_a_alguien = true

Efecto: amabilidad +1

Si no ayuda:

La escena continúa sin penalización.

IMPORTANTE:
No convertir esto en una decisión moral con castigo. El jugador simplemente está aprendiendo que el mundo tiene pequeñas oportunidades de interacción.

⸻

Entrada en la farmacia

PLANO General -> Farmacia

El protagonista entra.

SONIDO: campanilla.

PLANO Medio -> Farmacéutico/a

Farmacéutico/a:
—Buenos días.

Tú:
—Hola.

El jugador saca la segunda parte de la lista.

PLANO Inserto -> Lista

Tú:
—Necesito esto.

El farmacéutico/a comprueba la nota.

Farmacéutico/a:
—Perfecto.

Pausa.

Farmacéutico/a:
—¿Es para alguien de casa?

Tú:
—Sí.

Farmacéutico/a:
—Entonces guárdalo bien y dáselo cuando llegues.

Tú:
—Vale.

⸻

Gameplay: localizar el producto

El jugador debe escoger correctamente el artículo indicado en la lista.

No se muestran medicamentos reales ni marcas.

Se utiliza un objeto ficticio apropiado para el juego.

PLANO Inserto -> Producto

FLAG: recado_medicinas_completo = true

El farmacéutico/a entrega la bolsa.

Farmacéutico/a:
—Aquí tienes.

Tú:
—Gracias.

Farmacéutico/a:
—Buen viaje de vuelta.

Tú:
—Está cerca.

Farmacéutico/a:
—Entonces mejor todavía.

⸻

PASO 3 [Ir a] @ Casa familiar

«Vuelve a tu casa familiar con todo»

Musica: Emocion

El jugador debe regresar por sus propios medios.

Esta vez se elimina la guía automática si:

recado_se_oriento_solo = true

El jugador puede recordar el camino gracias a las calles que acaba de recorrer.

⸻

SISTEMA DE ORIENTACIÓN

Durante el regreso:

PLANO General -> Calle

El jugador puede reconocer:

* La plaza.
* La fuente.
* La librería.
* La farmacia.
* La calle de casa.

Si vuelve correctamente sin activar navegación:

FLAG: recado_se_oriento_solo = true

Narrador:
Quizá Valmar ya no parecía tan grande.

⸻

LLEGADA A CASA

PLANO Seguir -> Tú

Abres la puerta.

SONIDO: puerta.

PLANO General -> Salón

Mamá/Papá está esperando.

Mamá/Papá:
—¿Ya estás aquí?

Tú:
—Sí.

El protagonista deja las bolsas sobre la mesa.

PLANO Inserto -> Bolsas

Mamá/Papá las revisa.

Primero el material.

Después la bolsa de la farmacia.

Pausa.

PLANO PrimerPlano -> Mamá/Papá

Sonríe.

Mamá/Papá:
—Está todo.

Tú:
—Te dije que podía.

Mamá/Papá:
—Sí.

Pausa.

Mamá/Papá:
—Me lo dijiste.

⸻

SI recado_recordo_todo = true

Mamá/Papá:
—Y no te has olvidado de nada.

Tú:
—Lo comprobé dos veces.

Mamá/Papá:
—Eso también es aprender.

⸻

SI recado_ayudo_a_alguien = true

Mamá/Papá:
—¿Y por qué has tardado un poquito más?

Tú:
—Ayudé a un vecino.

PLANO PrimerPlano -> Mamá/Papá

Pequeña sonrisa.

Mamá/Papá:
—Entonces has tardado justo lo que tenías que tardar.

⸻

SI FALTÓ ALGÚN OBJETO

Si el jugador olvidó algo durante el recorrido:

Mamá/Papá:
—Espera…

Mira la lista.

Mamá/Papá:
—Falta una cosa.

PLANO Reaccion -> Tú

Tú:
—¡Lo sabía!

Mamá/Papá:
—¿Lo sabías?

Tú:
—Bueno…

Pausa.

Tú:
—Lo sospechaba.

Pequeña risa.

El juego permite realizar un mini-recado adicional opcional para conseguir el objeto.

No se considera un fracaso.

La intención es enseñar:

equivocarse → detectarlo → solucionarlo.

⸻

CINEMÁTICA DE CIERRE

Condición: todos los objetos entregados.

Musica: Emocion

CINEMÁTICA «Un poco más mayor»

PLANO General -> Salón

Mamá/Papá guarda el material.

El protagonista observa desde un lado.

PLANO Inserto -> La lista

La lista está llena de pequeñas marcas.

PLANO PrimerPlano -> Tú

Miras tus manos.

Después miras hacia la puerta.

Narrador:
Hasta ese día, siempre había alguien que iba contigo.

PLANO Dolly -> Tú

Narrador:
Esta vez habías ido tú.

PLANO General -> Ventana

Valmar aparece al fondo.

Narrador:
No parecía gran cosa.

Pausa.

Narrador:
Pero crecer también era esto.

PLANO PrimerPlano -> Tú

Narrador:
Que poco a poco empezaran a confiar en ti.

⸻

MOMENTO DE BIOGRAFÍA

«Mis primeros recados»

Texto base:

«Por primera vez, tu familia confió en ti para hacer unos recados sin compañía.»

Si volvió sin ayuda:

«Aprendiste a moverte solo/a por Valmar.»

Si ayudó al vecino:

«Descubriste que llegar un poco tarde también puede significar haber hecho algo bueno.»

Si olvidó algo y volvió:

«Aprendiste que equivocarse no significa rendirse. Significa buscar una solución.»

⸻

CONSECUENCIAS PARA EL FUTURO

Esta misión debe dejar una pequeña huella, aunque sea cotidiana.

recado_se_oriento_solo

Más adelante, durante Cole07_Excursion, el juego puede reconocer que el jugador ya conoce ciertas calles de Valmar.

recado_ayudo_a_alguien

En una futura misión de barrio, ese NPC puede reconocer al protagonista:

Vecino:
—¡Eh! Tú eres quien me ayudó aquel día.

Esto crea la sensación de que Valmar recuerda al jugador.

recado_recordo_todo

Durante futuras tareas:

Mamá/Papá:
—Ya sé que tú no necesitas que te recuerde todo.

recado_volvio_a_casa

Marca de independencia infantil que puede aumentar ligeramente en escenas posteriores la confianza que los padres depositan en el protagonista.

⸻

CIERRE DE MISIÓN

Biografía desbloqueada:

🏠 «Mis primeros recados»

Texto:
«Ya no solo explorabas Valmar. Empezabas a formar parte de él.»
