MISIÓN: Saga_20_Aliados — «Los que estuvieron ahí»

ID ORIGINAL: Saga_20_Aliados
ACTO: IV — 2/6
ETAPA: Adulto
DURACIÓN OBJETIVO: 30–45 minutos
REQUISITOS: Saga_19_Recuerdos + Adulto

⸻

1. FUNCIÓN NARRATIVA

Esta misión transforma las relaciones construidas durante toda la aventura en una mecánica narrativa real.

Cosme ya ha recuperado sus recuerdos.

Ahora sabe algo fundamental:

Para enfrentarse a Cósimo no basta con ellos.

Necesitan a las personas que el jugador ayudó a lo largo de su vida.

Pero existe una regla:

No todos los aliados estarán disponibles.

Solo acudirán aquellos cuya relación con el jugador haya alcanzado las condiciones necesarias.

Por primera vez, el jugador debe mirar atrás y descubrir que pequeños actos realizados años antes pueden regresar ahora de forma importante.

La misión debe provocar:

«Todo lo que hice antes realmente importaba.»

⸻

2. ESTADO INICIAL

Al comenzar:

saga_20_iniciada = true
cosme_recuerda_todo = true
equipo_rescate_activo = true

El garaje de Cosme se convierte temporalmente en el centro de operaciones.

Sobre una mesa:

* mapa de Valmar;
* fotografías;
* objetos de aventuras anteriores;
* lista de aliados;
* piezas relacionadas con el Ancla;
* álbum de recuerdos.

⸻

PASO 1 — HABLAR CON COSME

Objetivo

Habla con Cosme.

Localización

Garaje.

Personajes

* Cosme
* Pip
* Don Escamas
* jugador

⸻

CINEMÁTICA DE INICIO

CÁMARA — General

El garaje está lleno de actividad.

Pip organiza papeles.

Don Escamas observa desde la pecera.

Cosme está delante de un mapa enorme de Valmar.

El jugador entra.

Cosme levanta la cabeza.

CÁMARA — Medio

Cosme

«Llegas justo a tiempo.»

Señala el mapa.

Cosme

«He hecho una lista.»

Pip mira la lista.

PIP

«La lista es considerablemente larga.»

Cosme la levanta.

Está llena de nombres.

Cosme

«La mitad no son humanos.»

Pausa.

Cosme

«Y uno es un gato.»

Don Escamas:

«Solo uno confirmado.»

Música

Comedia

Pequeña pausa.

La música desaparece.

⸻

CAMBIO DE TONO

Cosme deja la lista sobre la mesa.

CÁMARA — PrimerPlano

Cosme

«No todos vendrán.»

Pausa.

«Vendrán los que ayudaste.»

Mira directamente al jugador.

Cosme

«Así funciona el universo.»

Pausa.

«Lo que das, vuelve.»

Don Escamas gira lentamente.

Don Escamas

«A veces en forma de gato.»

Cosme asiente.

Cosme

«Exactamente.»

⸻

SISTEMA — RED DE ALIADOS

Crear una representación visual de la red de relaciones.

Cada aliado aparece con:

* retrato;
* nombre;
* icono de relación;
* estado;
* ubicación.

Estados:

ALIADO
NO DISPONIBLE
PENDIENTE
CONFIRMADO

Nunca revelar al jugador que una persona no aparecerá simplemente por no haber cumplido una misión.

Debe sentirse como una consecuencia natural.

⸻

PASO 2 — VARIOS OBJETIVOS

Objetivo principal

Reúne a tus antiguos aliados.

Los objetivos pueden realizarse en cualquier orden.

El número y composición del grupo final dependen de las decisiones previas del jugador.

⸻

PASO 2.1 — IVÁN Y CANDELA

Condición

Disponible siempre que su relación correspondiente siga activa.

Localización

Residencia / zona universitaria.

⸻

LLEGADA

Iván está realizando una tarea cotidiana.

Candela está revisando información en una mesa.

Al ver al jugador, Iván levanta la cabeza.

Iván

«Sabía que volverías.»

Candela no levanta inmediatamente la mirada.

Candela

«No.»

Pausa.

«Yo calculé que volvería.»

Iván:

«Eso es lo mismo.»

Candela:

«No.»

⸻

OBJETIVO

Explicar la situación sin convertir la escena en una exposición larga.

Cosme aparece en videollamada o mediante comunicación de Pip.

Cosme

«Necesitamos ayuda.»

Iván mira a Candela.

Iván

«¿Es peligroso?»

Pausa.

Cosme

«Bastante.»

Iván sonríe.

Iván

«Entonces supongo que vamos.»

Candela guarda sus cosas.

Candela

«Ya estaba preparada.»

FLAG

ivan_aliado_confirmado = true
candela_aliada_confirmada = true

⸻

PASO 2.2 — AGENTE CRONOS

CONDICIÓN

cronos_aliado = true

Localización

Zona administrativa / instituto / punto establecido por el sistema de Cronos.

Cronos aparece revisando documentos.

Cronos

«El tiempo tiene una costumbre.»

Mira al jugador.

«Siempre vuelve a pedir cuentas.»

El jugador explica la situación.

Cronos observa el reloj de arena.

Cronos

«Entonces ha llegado la hora.»

Entrega el reloj al jugador durante unos segundos.

Cronos

«No pienso dejar que Cósimo decida cuándo termina esta historia.»

FLAG

cronos_aliado_confirmado = true

⸻

PASO 2.3 — BIGOTES XVII

CONDICIÓN

duque_de_gatonia = true

o la condición equivalente existente en el proyecto.

Localización

Gatonia.

La llegada debe sentirse diferente.

Gatos recorriendo la ciudad.

Pequeñas rutinas.

Guardias felinos.

Carteles.

⸻

LLEGADA

Bigotes XVII observa al jugador desde una plataforma.

Bigotes XVII

«Has vuelto.»

Pausa.

«Y tienes cara de necesitar un ejército.»

El jugador explica la situación.

Bigotes mira hacia los gatos.

Bigotes XVII

«Un ejército no.»

Pausa.

«Pero puedo darte gatos.»

Música

Comedia

⸻

CAMBIO DE TONO

Bigotes baja de la plataforma.

Bigotes XVII

«Le debemos una.»

Mira al jugador.

«Y en Gatonia pagamos nuestras deudas.»

FLAG

bigotes_aliado_confirmado = true
gatos_de_gatonia_activados = true

⸻

PASO 2.4 — REX

CONDICIÓN

rex_se_queda = true

OBJETIVO

Busca a Rex.

La escena debe depender de su relación previa.

Rex aparece en su zona habitual.

Al ver al jugador, se acerca.

Rex

«¿Otra aventura?»

Pausa.

«Esta vez avisa antes de romper algo.»

El jugador explica la situación.

Rex mira hacia la ciudad.

Rex

«Vale.»

Pausa.

«¿Cuándo salimos?»

FLAG

rex_aliado_confirmado = true

⸻

PASO 2.5 — RATÓN PÉREZ

CONDICIÓN

huelga_raton_perez = true

La aparición debe ser inesperada.

El jugador encuentra una pequeña señal en un lugar conocido.

Una moneda.

Un diente.

Un pequeño objeto relacionado con su historia.

CÁMARA — Inserto

El objeto se mueve.

Se escucha un pequeño ruido.

Aparece el Ratón Pérez.

Ratón Pérez

«Me dijeron que había problemas.»

Pausa.

«Y los problemas tienen dientes.»

Mira al jugador.

«Así que vine preparado.»

FLAG

raton_perez_aliado = true

⸻

PASO 2.6 — GNOMO RIGOBERTO

CONDICIÓN

noche_de_los_gnomos = true

Localización

Lugar relacionado con la misión original.

El jugador encuentra varios pequeños rastros.

Una puerta diminuta.

Una luz.

Un sonido.

CÁMARA — Inserto

La puerta se abre.

Rigoberto aparece.

Rigoberto

«¿Otra vez tú?»

Pausa.

«Perfecto.»

Mira al jugador.

«Los problemas grandes son más divertidos.»

FLAG

rigoberto_aliado = true

⸻

PASO 2.7 — TU OTRO YO DE 66-B

CONDICIÓN

conoce_tu_malvado = true

Este encuentro debe tener una función emocional.

No es simplemente un aliado más.

Es la prueba de que incluso una versión distinta del jugador puede elegir ayudar.

⸻

ENCUENTRO

Aparece el otro jugador.

Tiene una expresión seria.

Otro Yo

«Sabía que vendrías.»

Pausa.

«No sé por qué.»

Mira al jugador.

Otro Yo

«Supongo que porque yo también habría venido.»

El jugador puede responder mediante una elección.

ELECCIÓN

A. «Entonces ven con nosotros.»

B. «No tienes que hacerlo.»

⸻

A — SI EL JUGADOR LO INVITA

Otro Yo:

«Sí.»

Pausa.

«Me apunto.»

malvado_66b_aliado = true

⸻

B — SI EL JUGADOR LE DA LIBERTAD

Otro Yo sonríe.

«Gracias.»

Pausa.

«Precisamente por eso voy.»

malvado_66b_aliado = true

La decisión no debe impedir su participación.

La diferencia es emocional.

⸻

SISTEMA DE ALIANZAS

Cada aliado debe tener una pequeña función para el final.

No todos deben convertirse en combatientes.

Ejemplos:

* Candela → análisis y planificación.
* Iván → apoyo logístico.
* Cronos → control temporal.
* Bigotes → red de información.
* Rex → movilidad / apoyo.
* Ratón Pérez → acceso a espacios pequeños.
* Rigoberto → conocimiento de lugares extraños.
* 66-B → conocimiento de la dimensión alternativa.

Esto permite que la misión final tenga soluciones narrativas diferentes según los aliados conseguidos.

⸻

PASO 3 — REGRESO AL GARAJE

Objetivo

Vuelve al garaje con Cosme.

El jugador regresa.

Los aliados empiezan a llegar.

No deben aparecer todos mágicamente.

Cada llegada debe tener una pequeña animación.

⸻

CINEMÁTICA — «TODOS JUNTOS»

CÁMARA — General

Garaje.

Cosme está delante del mapa.

Pip está a su lado.

Se escucha un ruido exterior.

La puerta se abre.

Entra Iván.

Después Candela.

Después los demás aliados disponibles.

Cada uno tiene una pequeña reacción.

⸻

COSME

Cosme mira al grupo.

No habla inmediatamente.

CÁMARA — PrimerPlano

Sonríe.

Cosme

«Vaya.»

Pausa.

«De verdad vinieron.»

⸻

IVÁN

Iván

«Te dijimos que sí.»

⸻

CANDELA

Candela

«Y además hemos llegado a tiempo.»

⸻

COSME

Mira al jugador.

Cosme

«Los reuniste.»

Pausa.

«A todos.»

⸻

MONTAJE DE RELACIONES

La cámara realiza pequeños cortes a los aliados.

Cada uno debe recordar brevemente al jugador.

No repetir grandes exposiciones.

Solo una frase.

Ejemplos:

Bigotes XVII

«Me ayudaste cuando no tenías por qué.»

Cronos

«Las decisiones tienen memoria.»

Rex

«Nunca olvidé lo que hiciste.»

Otro Yo

«Supongo que esto es lo que hacen los buenos.»

No todos deben decir una frase si no están presentes.

⸻

DON ESCAMAS

Don Escamas se mueve dentro de la pecera.

CÁMARA — Inserto

Un pequeño mapa financiero aparece junto a la pecera.

Don Escamas

«Yo también tengo información.»

Todos miran.

Don Escamas

«Tengo cuentas del MegaVerso.»

Pausa.

«Y sé dónde esconden el dinero.»

Silencio.

Iván

«¿Cómo sabes eso?»

Don Escamas:

«Soy un pez.»

Pausa.

«La gente habla delante de los peces.»

Música

Comedia

⸻

CAMBIO DE TONO

Don Escamas continúa.

Don Escamas

«También tengo algo más.»

La música desaparece.

Don Escamas

«El servidor central.»

Cosme levanta la mirada.

CÁMARA — PrimerPlano

Cosme

«¿El servidor?»

Don Escamas asiente.

Don Escamas

«Si cae, cae el Consorcio.»

Pausa.

«Y Cósimo pierde gran parte de su poder.»

⸻

INFORMACIÓN NUEVA

Pip proyecta un mapa.

Aparece:

MEGAVERSO
SERVIDOR CENTRAL
DISTRITO FINANCIERO

Cosme

«Entonces ya tenemos nuestro primer objetivo.»

Mira al jugador.

Cosme

«Entramos.»

⸻

TRANSICIÓN ESPECIAL

Antes de terminar la escena:

Se escucha un ruido en el cielo.

Todos miran arriba.

CÁMARA — Tilt

Una nave pasa sobre Valmar.

Si:

noz_aliada = true

es la nave de Capitana Ñoz.

La nave realiza una pasada rápida.

Blorp saluda desde una ventanilla.

La nave continúa.

Música

Epico

⸻

FINAL DE MISIÓN

Volver al mapa.

El servidor de MegaVerso queda marcado.

El jugador recibe:

OBJETIVO DESBLOQUEADO
ASALTO AL MEGAVERSO

Corte.

⸻

VARIABLES

Siempre:

saga_20_completada = true
equipo_aliados_reunido = true
servidor_megaverso_localizado = true

Según relaciones:

ivan_aliado_confirmado
candela_aliada_confirmada
cronos_aliado_confirmado
bigotes_aliado_confirmado
gatos_de_gatonia_activados
rex_aliado_confirmado
raton_perez_aliado
rigoberto_aliado
malvado_66b_aliado

No crear variables que sustituyan a las variables históricas existentes.

Mapear las variables antiguas a las nuevas mediante una capa de compatibilidad.

⸻

SISTEMA DE CONSECUENCIAS

Crear:

AliadosActivos

La lista debe generarse automáticamente según las decisiones del jugador.

Ejemplo:

AliadosActivos = [
    Iván,
    Candela,
    Cronos,
    Bigotes,
    Rex
]

Otro jugador podría tener:

AliadosActivos = [
    Iván,
    Candela,
    Bigotes,
    Rigoberto,
    OtroYo66B
]

Esto permitirá que diferentes partidas produzcan grupos distintos.

⸻

ALBUM DE RECUERDOS

Si album_recuerdos_obtenido = true:

Añadir fotografías de los aliados reunidos.

Cada fotografía debe incluir:

* personaje;
* lugar;
* fecha aproximada;
* relación;
* recuerdo relacionado.

Ejemplo:

Bigotes XVII

«El día que Gatonia decidió devolverte el favor.»

⸻

DIRECCIÓN DE ACTUACIÓN

Los aliados no deben formar una fila inmóvil.

Durante la escena final:

* Iván observa el mapa.
* Candela calcula.
* Bigotes examina la habitación.
* Rex mira hacia la puerta.
* Rigoberto inspecciona objetos.
* Cronos observa el reloj.
* Don Escamas se mueve dentro de la pecera.
* Cosme cambia continuamente entre los miembros del grupo.

El garaje debe parecer un auténtico centro de operaciones.

⸻

DIRECCIÓN DE CÁMARA

Utilizar exclusivamente:

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

La cámara debe priorizar:

1. relaciones;
2. reacciones;
3. información;
4. sensación de grupo.

⸻

DIRECCIÓN MUSICAL

Utilizar exclusivamente:

* Calma
* Tension
* Emocion
* Accion
* Epico
* Comedia

Progresión:

Preparación → Calma
Encuentros → Emocion
Bigotes / situaciones absurdas → Comedia
Revelación del servidor → Tension
Llegada del grupo → Emocion
Nave de Ñoz → Epico

⸻

CONSECUENCIA NARRATIVA

Esta misión debe cambiar permanentemente el garaje.

Después de completarla:

El garaje deja de ser únicamente la casa de Cosme.

Se convierte en:

BASE DE OPERACIONES DE VALMAR.

Los aliados pueden aparecer allí ocasionalmente.

Pueden conversar.

Pueden discutir.

Pueden revisar información.

Pueden recordar acontecimientos anteriores.

No deben permanecer congelados.

⸻

EVENTOS AMBIENTALES

Después de la misión:

* Iván puede aparecer hablando con Pip.
* Candela puede revisar mapas.
* Bigotes puede enviar pequeños mensajes.
* Cronos puede observar el reloj.
* Rex puede practicar.
* Rigoberto puede esconderse por el garaje.
* Don Escamas puede recibir información.

Estos eventos deben ser opcionales.

Nunca bloquear el progreso.

⸻

MEMORIA DEL JUGADOR

Añadir:

Título: Los que estuvieron ahí

Descripción:

Reuniste a las personas y criaturas que ayudaste durante tu vida.

Y:

alianzas_activas_registradas = true
servidor_megaverso_localizado = true

⸻

QA OBLIGATORIO

Relaciones

* Las decisiones antiguas deben determinar quién aparece.
* No debe aparecer un aliado cuya condición nunca se cumplió.
* No debe desaparecer un aliado que sí fue desbloqueado.
* Las relaciones deben persistir después de cerrar el juego.

Escenas

* Cada aliado entra físicamente al garaje.
* Nadie aparece teletransportado sin transición.
* Las posiciones deben adaptarse al número de aliados.
* Evitar que los NPC se atraviesen.
* Evitar que ocupen el mismo punto.

Gameplay

* Los objetivos pueden completarse en cualquier orden.
* Si un aliado no está disponible, el sistema debe continuar.
* Nunca bloquear la misión esperando una condición imposible.
* El grupo final debe generarse dinámicamente.

Cámara

* Restaurar cámara del jugador.
* Restaurar controles.
* Evitar clipping.
* Adaptar encuadres a grupos pequeños y grandes.

Persistencia

Guardar:

saga_20_completada
equipo_aliados_reunido
servidor_megaverso_localizado
AliadosActivos

⸻

RESULTADO EMOCIONAL

El jugador debe mirar al grupo reunido y comprender:

No está solo.

Pero tampoco debe sentirse como un ejército invencible.

Cada personaje aporta algo diferente.

Algunos son útiles.

Otros son extraños.

Otros son cómicos.

Otros tienen habilidades aparentemente insignificantes.

Y precisamente eso hará que el grupo se sienta humano.

La aventura empezó con un jugador prácticamente solo.

Ahora, después de toda una vida en Valmar:

las personas a las que ayudó han decidido quedarse a su lado.
