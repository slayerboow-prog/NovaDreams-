MISIÓN: Adulto_PrimerSueldo — GANARTE LA VIDA

Tipo: Historia / Vida adulta / Trabajo
Etapa: Adulto joven
Duración objetivo: 15–25 min
Requisito: Adulto_LlegadaValmar
Ruta: Capítulo alternativo Una nueva vida en Valmar

⸻

FUNCIÓN DE LA MISIÓN

Esta es la primera misión laboral del jugador que comenzó directamente como adulto.

No debe sentirse como un tutorial de empleo.

Debe transmitir:

“Ya tengo una casa. Ahora tengo que conseguir que esta vida funcione.”

La misión debe enseñar de manera natural:

* cómo buscar trabajo;
* cómo aceptar un empleo;
* cómo desplazarse al trabajo;
* cómo funciona un turno;
* cómo cobrar;
* cómo funciona el sueldo;
* que los trabajos tienen horarios;
* que los NPCs tienen relaciones laborales;
* que el trabajo puede mejorar con experiencia.

El jugador debe terminar pensando:

“Este sueldo me lo he ganado yo.”

⸻

PASO 1 — ACCIÓN DEL JUGADOR

Objetivo original conservado

Busca un cartel de SE BUSCA y trabaja (0/3)

Lugar principal: Correos
NPC: Ernesto

Este paso debe conservar exactamente su función, pero convertirse en una pequeña experiencia laboral.

⸻

NUEVO — ANTES DE BUSCAR TRABAJO

Antes de activar el objetivo, el jugador recibe control dentro de su casa.

La vivienda todavía debe sentirse nueva.

Sobre una mesa:

* llave;
* móvil;
* pequeña cantidad de dinero;
* una factura;
* mochila/maletín.

El jugador puede interactuar con la mesa.

Inserto

Dinero disponible.

No mostrar una cantidad ridículamente alta.

Debe quedar claro:

Dinero: limitado

El jugador mira el móvil.

No tiene mensajes nuevos.

Silencio.

Entonces aparece el objetivo:

BUSCA UN TRABAJO

⸻

NUEVO — DESCUBRIR EL TABLÓN

El jugador debe salir de casa.

No colocar un waypoint directo hasta Correos.

En la ciudad existen varios carteles:

* SE BUSCA
* SE ALQUILA
* SE VENDE
* TRABAJO TEMPORAL

El jugador debe localizar uno.

Si interactúa con un cartel incorrecto

No penalizar.

Por ejemplo:

SE ALQUILA

“No es lo que buscas ahora.”

Esto enseña al jugador a leer el mundo.

⸻

NUEVO — PRIMERA OFERTA

El tablón de empleo muestra:

CORREOS

Puesto:

Reparto local

Horario:

08:00–14:00

Experiencia:

No necesaria

Pago:

Semanal

Descripción:

“Buscamos una persona responsable para reparto y clasificación.”

⸻

NUEVO SISTEMA

No aceptar automáticamente.

Mostrar:

¿Quieres solicitar este trabajo?

Opciones:

* Solicitar
* Seguir buscando

Si selecciona Seguir buscando, puede explorar otros puestos disponibles.

Pero para esta misión, el puesto de Correos debe seguir siendo el camino narrativo recomendado.

⸻

NUEVO — PRIMERA ENTREVISTA

Al seleccionar Correos:

Objetivo:

Habla con Ernesto.

El jugador entra en Correos.

Ernesto está trabajando.

No está detrás del mostrador esperando.

Está:

* clasificando cartas;
* comprobando direcciones;
* hablando con otro empleado;
* moviendo paquetes.

Al terminar una tarea, ve al jugador.

Ernesto

ERNESTO:
—¡La cara nueva!

Se acerca.

ERNESTO:
—¿Vienes por el trabajo?

Jugador

Opciones:

Sí. Necesito empezar a trabajar.

Sí. Quiero conocer la ciudad.

Necesito pagar mis facturas.

Las tres respuestas funcionan, pero guardan una variable:

motivo_primer_trabajo

⸻

ENTREVISTA

Ernesto se apoya en el mostrador.

ERNESTO:
—Vale.

Pausa.

ERNESTO:
—Pregunta fácil.

ERNESTO:
—¿Sabes perderte?

El jugador puede responder:

A

No.

Ernesto sonríe.

ERNESTO:
—Entonces aprenderás.

B

Todavía no conozco Valmar.

ERNESTO:
—Mejor.

Pausa.

ERNESTO:
—Así la conocerás entera.

C

Puedo aprender.

Ernesto asiente.

ERNESTO:
—Esa respuesta me gusta.

⸻

NUEVO — MINI ENTREVISTA DE RESPONSABILIDAD

Ernesto continúa:

ERNESTO:
—Última.

Pausa.

ERNESTO:
—Te dan una carta que no es tuya.

¿Qué haces?

OPCIÓN A

La devuelvo y busco al destinatario.

responsabilidad +1

OPCIÓN B

Pregunto antes de hacer nada.

prudencia +1

OPCIÓN C

La dejo donde corresponde y aviso.

organizacion +1

No existe una respuesta “mala”.

Cada una muestra una personalidad diferente.

⸻

NUEVO — CONTRATO

Ernesto saca una carpeta.

ERNESTO:
—No necesito que seas perfecto/a.

Pausa.

ERNESTO:
—Necesito que seas fiable.

Le entrega el contrato.

Inserto

El nombre del jugador aparece en el documento.

Silencio.

La cámara permanece sobre el documento durante unos segundos.

Ernesto

ERNESTO:
—Bienvenido/a a Correos.

⸻

NUEVO — FIRMA

El jugador debe interactuar con el contrato.

No hacer simplemente:

Aceptar.

La animación debe mostrar:

* sentarse;
* coger bolígrafo;
* firmar;
* mirar el documento;
* devolverlo.

Sistema

trabajo_actual = Repartidor
empleado_valmar = true
empleo_nuevo = true

⸻

NUEVO — PRIMER DÍA

Después de firmar:

ERNESTO:
—Tu primer turno empieza ahora.

El jugador puede pensar que habrá una cinemática.

No.

Ernesto le entrega una pequeña bolsa.

ERNESTO:
—Primero aprende.

Pausa.

ERNESTO:
—Después corre.

⸻

OBJETIVO

Completa tu primer turno (0/3)

Esto conserva y amplía el objetivo original.

⸻

TURNO 1/3 — CLASIFICAR

El jugador debe clasificar cartas.

Mecánica

Cada carta contiene:

* calle;
* número;
* zona.

El jugador debe colocarlas en el compartimento correcto.

No hacerlo excesivamente difícil.

Primer error

Ernesto:

ERNESTO:
—No pasa nada.

Señala.

ERNESTO:
—Mira primero la calle.

Pausa.

ERNESTO:
—Después el número.

El juego enseña mediante el personaje.

⸻

TURNO 2/3 — RUTA

El jugador recibe una pequeña ruta.

Objetivo

Entregar tres paquetes.

Cada entrega debe ser diferente.

Entrega 1

NPC recibe paquete.

NPC:
—Gracias.

Entrega 2

El destinatario no está.

El jugador debe decidir:

* dejar aviso;
* volver más tarde.

Entrega 3

Un perro se acerca.

Ernesto había mencionado perros.

El animal mueve la cola.

Ernesto, por teléfono:

ERNESTO:
—Ese es Bruno.

Pausa.

ERNESTO:
—No muerde.

Pausa.

ERNESTO:
—Bueno.

ERNESTO:
—Creo.

Esto convierte la ciudad en un lugar con pequeñas historias.

⸻

TURNO 3/3 — EL ERROR

Aquí debe ocurrir algo pequeño.

El jugador entrega accidentalmente un paquete en una dirección equivocada si ha cometido suficientes errores durante los turnos anteriores.

No hacer que ocurra siempre.

Si no comete errores

Ernesto:

ERNESTO:
—Ruta limpia.

Si comete un error

El juego no debe hacerle fracasar.

El jugador debe volver y corregirlo.

Ernesto

ERNESTO:
—Los errores pasan.

Pausa.

ERNESTO:
—Lo importante es encontrarlos.

Esto establece una filosofía laboral.

⸻

NUEVO — FIN DEL TURNO

El jugador vuelve a Correos.

Ernesto revisa el registro.

Si buen desempeño

ERNESTO:
—Primer día.

Mira los datos.

ERNESTO:
—Muy bien.

Pausa.

ERNESTO:
—Mañana será más difícil.

Sonríe.

ERNESTO:
—Eso significa que vas bien.

Si desempeño medio

ERNESTO:
—Has aprendido.

Pausa.

ERNESTO:
—Mañana lo harás mejor.

Si desempeño bajo

ERNESTO:
—Hoy no ha sido tu mejor día.

Pausa.

ERNESTO:
—Pero has vuelto.

Sonríe.

ERNESTO:
—Eso también cuenta.

Nunca bloquear el progreso.

⸻

NUEVO — PRIMER SUELDO

Al finalizar el período laboral de la misión:

Transición.

“Primer viernes…”

Música

Emocion

El jugador vuelve a casa.

El móvil vibra.

Inserto

INGRESO RECIBIDO

Primer sueldo

La cantidad aparece.

No exagerar el efecto visual.

El protagonista mira la pantalla.

PrimerPlano

Pequeña sonrisa.

No diálogo todavía.

El jugador entra en casa.

⸻

NUEVO — EL SUELDO COMO OBJETO NARRATIVO

El jugador mira alrededor.

La casa que estaba vacía ahora tiene pequeñas señales de vida:

* una taza;
* una bolsa;
* ropa;
* un objeto comprado;
* correo.

La cámara muestra la vivienda.

Después el dinero.

El contraste es importante:

antes tenía una casa.

ahora empieza a tener una vida.

⸻

NUEVO — PRIMERA DECISIÓN ECONÓMICA

Mostrar:

Has cobrado tu primer sueldo.

¿Qué haces con él?

OPCIÓN A

Guardar la mayor parte.

responsabilidad +1

ahorro +1

OPCIÓN B

Comprar algo para la casa.

hogar +1

OPCIÓN C

Invitar a Lola a comer para agradecerle la bienvenida.

lola +3

OPCIÓN D

Gastar una pequeña parte en algo para ti.

bienestar +1

No exigir que el jugador gaste todo.

⸻

NUEVO — SI ELIGE LOLA

El jugador puede acudir a la cafetería.

Lola está trabajando.

El jugador paga una comida.

Lola

LOLA:
—¿Y esto?

PROTAGONISTA:
—Mi primer sueldo.

Lola sonríe.

LOLA:
—Entonces hoy invito yo.

Devuelve parte del dinero.

LOLA:
—Guárdalo.

Pausa.

LOLA:
—Los primeros sueldos se recuerdan.

⸻

NUEVO — SI COMPRA PARA CASA

El jugador puede adquirir un objeto pequeño.

Por ejemplo:

* lámpara;
* planta;
* cuadro;
* silla;
* pequeño electrodoméstico.

Al colocarlo:

La vivienda cambia físicamente.

Guardar:

primer_objeto_casa = true

Esto comienza el sistema de personalización de vivienda.

⸻

NUEVO — SI GUARDA EL DINERO

El jugador vuelve a casa.

Abre una caja/espacio de ahorro.

Introduce parte del dinero.

Inserto

Dinero guardado.

No hace falta diálogo.

La acción habla por sí sola.

⸻

NUEVO — SI GASTA EN SÍ MISMO

El jugador compra algo.

Al regresar a casa:

Lo utiliza.

Pequeño momento de satisfacción.

No convertirlo en una escena moralista.

El juego no debe decir:

“Has tomado una mala decisión.”

Debe permitir que el jugador construya su personalidad.

⸻

CIERRE CINEMÁTICO

Cinemática

Adulto_PrimerSueldo

Música

Emocion

Cámara

General: exterior del edificio al anochecer.

Inserto: luz encendiéndose en la vivienda.

Medio: protagonista dentro.

PrimerPlano: rostro relajado.

Inserto: objeto comprado / dinero ahorrado / móvil, dependiendo de elección.

Última acción

El protagonista mira por la ventana.

Valmar está iluminada.

Se escucha:

* tráfico;
* voces;
* autobús;
* ciudad.

No narrar demasiado.

Finalmente:

“Primer sueldo.”

Pausa.

“Primera vez que esta ciudad te paga por algo que tú has hecho.”

Fundido.

⸻

BIOGRAFÍA

Al terminar:

“Te ganaste la vida en Valmar.”

Subtítulo:

“Tu primer trabajo. Tu primer sueldo. Tu primera decisión como adulto.”

⸻

ESTADOS PERSISTENTES

Guardar:

empleado_valmar = true
trabajo_actual = Repartidor
primer_sueldo_valmar = true
primer_trabajo_valmar = true
motivo_primer_trabajo
resultado_primer_turno
responsabilidad
prudencia
organizacion
ahorro
hogar
bienestar
lola
primer_objeto_casa

⸻

CONSECUENCIAS FUTURAS

El trabajo no debe desaparecer después de la misión.

El jugador podrá:

* seguir trabajando;
* mejorar estadísticas;
* subir de puesto;
* cambiar de empleo;
* conseguir nuevas ofertas;
* conocer compañeros;
* aumentar ingresos.

El primer empleo debe convertirse en la semilla del sistema profesional.

⸻

SISTEMA DE REPUTACIÓN LABORAL

NUEVO.

Crear:

reputacion_laboral

Valores posibles:

* 0–20 Nuevo
* 21–40 Fiable
* 41–60 Buen trabajador
* 61–80 Destacado
* 81–100 Referencia

No mostrar necesariamente estos rangos al jugador al principio.

Los NPCs deben reaccionar según la reputación.

⸻

CONEXIÓN CON LA SIGUIENTE MISIÓN

Al completar:

Adulto_ConoceLaRegion

debe desbloquearse.

Pero no obligar inmediatamente al jugador a irse de excursión.

La sensación debe ser:

“Ahora ya tengo una casa y un trabajo. ¿Qué hay fuera de mi rutina?”

⸻

DIRECCIÓN DE ACTUACIÓN

Ernesto nunca debe estar quieto durante la entrevista.

Mientras habla:

* clasifica cartas;
* camina;
* revisa paquetes;
* señala rutas;
* consulta una lista;
* entrega objetos.

El protagonista:

* mira el contrato;
* firma;
* guarda el dinero;
* reacciona al primer sueldo;
* observa su casa.

⸻

DIRECCIÓN CINEMATOGRÁFICA

Evitar:

* pantallas de tutorial constantes;
* flechas gigantes;
* personajes congelados;
* diálogos demasiado largos;
* recompensas exageradas;
* música épica.

Priorizar:

* objetos;
* acciones;
* ciudad viva;
* pequeños errores;
* silencios;
* progresión visual de la vivienda.

⸻

QA OBLIGATORIO

Comprobar:

* Adulto_LlegadaValmar completada.
* Tablón de empleo disponible.
* El trabajo de Correos aparece.
* Ernesto está disponible.
* La entrevista funciona.
* Las tres preguntas se guardan.
* El contrato se genera correctamente.
* El nombre del jugador aparece correctamente.
* El primer turno comienza.
* El minijuego de clasificación funciona.
* Las entregas funcionan.
* Los paquetes tienen destinos válidos.
* Los errores pueden corregirse.
* El jugador nunca queda bloqueado por fallar.
* El sueldo se concede una sola vez.
* La cantidad coincide con el trabajo.
* La elección económica se guarda.
* La vivienda cambia si se compra un objeto.
* Lola recibe la interacción si se selecciona.
* La reputación laboral se registra.
* La misión no se puede cobrar dos veces.
* El estado primer_sueldo_valmar queda persistente.
* La siguiente misión se desbloquea.
* La cámara devuelve el control correctamente.
* La música se restaura.
* Todos los NPC recuperan sus rutinas.

⸻

OBJETIVO EMOCIONAL

El jugador comenzó esta ruta con:

una maleta, una casa vacía y poco dinero.

Ahora tiene:

un trabajo, un sueldo y una razón para levantarse mañana.

No parece mucho.

Pero para alguien que acaba de empezar una vida nueva:

lo es todo.
