MISIÓN: Adu01_PrimerContrato — ID: Adu01_PrimerContrato
Capítulo: Volar del nido
Etapa: AdultoJoven
Edad: 22–23 años
Tipo: Historia · Vida adulta · Trabajo · Primer hogar
Duración objetivo: 30–45 min
Requisito: Ins06_LaGranDecision completada

⸻

PROPÓSITO DE LA MISIÓN

Esta misión representa un cambio fundamental:

Hasta ahora el jugador estaba preparándose para la vida.

Ahora empieza a pagarla.

Debe sentirse como un momento que el jugador recordará:

«Este fue el día en que mi nombre apareció en un contrato.»

Pero no convertirlo en una simple cinemática.

El jugador debe:

* conseguir su primer hogar;
* llegar a su primer trabajo;
* reencontrarse con un mentor;
* afrontar su primera responsabilidad profesional;
* tomar una decisión sobre cómo trabajar;
* cobrar su primer sueldo;
* descubrir que el dinero desaparece mucho más rápido de lo esperado;
* aprender a gestionar sus primeras facturas;
* recibir una llamada que prepara Adu02_Atardecer.

La misión debe introducir de forma natural el sistema adulto de trabajo + vivienda + economía personal.

⸻

VARIABLES

Consultar:

graduado
estudios
empleo
llegas_tarde_practicas
llegas_tarde_contrato
oferta_trabajo
antecedentes
buen_trabajo
mentiste_entrevista
ascendido
despedido
responsabilidad
valentia
curiosidad
tiene_hogar

Nuevas:

primer_contrato_completado
primer_caso
facturas
primer_sueldo
primer_presupuesto
factura_pendiente

⸻

PASO 1 · TRANSICIÓN

«Septiembre. Un lunes cualquiera… que no es cualquiera.»

Cinemática Adu01_Septiembre

Música: Calma

Plano 1 — General

Amanecer sobre Valmar.

La ciudad despierta.

⸻

Plano 2 — Seguir

El jugador adulto sale de su habitación.

Ya no lleva mochila escolar.

Lleva ropa de adulto acorde a su profesión.

⸻

Inserto

Un calendario.

SEPTIEMBRE

Una fecha marcada.

⸻

Plano 3 — PrimerPlano

El jugador mira su teléfono.

Notificación:

Hoy — Primer día

El jugador sonríe.

⸻

Plano 4 — General

La puerta de casa.

El jugador sale.

La puerta se cierra.

Corte.

⸻

PASO 2 · PRIMER HOGAR

«Busca una casa libre»

Solo si tiene_hogar = false.

Aquí no debe bastar con pulsar un botón.

El jugador entra realmente en el sistema inmobiliario.

⸻

OBJETIVO

Encuentra tu primer hogar.

En el mapa aparecen varias viviendas disponibles.

Cada una muestra:

* precio;
* alquiler;
* tamaño;
* distancia al trabajo;
* número de habitaciones;
* gastos aproximados.

⸻

MECÁNICA

El jugador puede visitar hasta 3 viviendas antes de decidir.

Vivienda A

Pequeña.

Barata.

Cerca del trabajo.

Vivienda B

Más grande.

Más cara.

Más alejada.

Vivienda C

Intermedia.

Mejor equilibrio.

⸻

INSERTO

El jugador mete la llave.

La cámara permanece unos segundos detrás.

Abre la puerta.

Silencio.

La vivienda está vacía.

⸻

Narrador

No es la casa de tus padres.

Pausa.

No es la casa de tus abuelos.

El jugador entra.

Es la primera casa que es completamente tuya.

⸻

INTERACCIÓN

El jugador puede colocar:

* primera cama;
* primera mesa;
* primera foto;
* primer objeto personal.

Esto desbloquea:

tiene_hogar = true

⸻

PASO 3 · PRIMER DÍA DE TRABAJO

«Ve donde hiciste las prácticas»

Solo si graduado = true.

El destino depende de:

estudios

Medicina → Doctora Nuria

Ingeniería → Sofía

Derecho → Montse

Economía → Ignacio

⸻

SISTEMA DE VIAJE

No teleport.

El jugador decide cómo llegar:

* caminar;
* autobús;
* coche;
* metro si está desbloqueado.

Si llega tarde:

llegas_tarde_contrato = true

No hacer un simple mensaje de “llegaste tarde”.

El NPC debe estar realmente esperando.

⸻

PASO 4 · RUTA BARISTA

Solo si empleo = Barista y graduado = false.

Destino:

Cafetería Central

Objetivo:

Ve a hablar con Lola.

Lola está trabajando.

No está esperando congelada.

Está:

* sirviendo;
* organizando;
* hablando con clientes;
* revisando pedidos.

Cuando ve al jugador:

Lola

¡Ahí estás!

Pausa.

Quita de la puerta, que entra el reparto.

El jugador se aparta.

Lola sonríe.

Ahora ven.

⸻

PASO 5 · RUTA REPONEDOR

Solo si empleo = Reponedor y graduado = false.

Destino:

Supermercado

Paco está revisando estanterías.

Paco

Hmm.

Mira al jugador.

Has venido.

Pausa.

Bien.

⸻

PASO 6 · RUTA REPARTIDOR

Solo si empleo = Repartidor y graduado = false.

Destino:

Correos

Ernesto está clasificando paquetes.

Ernesto

¡Hombre!

Mira una bandeja.

Justo a tiempo.

Sonríe.

Acabo de clasificar tu calle.

⸻

PASO 7 · CINEMÁTICA

Adu01_PrimerDia

Este debe ser uno de los momentos más importantes de la etapa adulta.

No hacer una cinemática idéntica para todas las profesiones.

La estructura es común.

La actuación cambia completamente.

⸻

RUTA MEDICINA

Nuria

Plano 1 — General

Hospital funcionando.

Enfermeros y pacientes moviéndose.

⸻

Plano 2 — Seguir

Nuria camina con el jugador.

Nuria

Ven.

Pausa.

Hay papeles.

Sonríe.

Muchos.

⸻

Si NO llegas_tarde_contrato

Nuria

¡Mira quién ha llegado!

Pausa.

Y en hora.

Sonríe.

Eso aquí ya es medio diagnóstico.

⸻

Si llegas_tarde_contrato

PrimerPlano.

Nuria cruza los brazos.

Nuria

Las ocho y veinte.

Pausa.

En urgencias, veinte minutos son una eternidad.

Mira al jugador.

Que no se repita.

⸻

Si llegas_tarde_practicas

Nuria no se enfada.

Está decepcionada.

Nuria

Tarde a las prácticas.

Pausa.

Tarde al contrato.

Mira al jugador.

Empiezo a pensar que es una tradición.

⸻

Entrega

Nuria coloca un documento sobre la mesa.

Nuria

Firma aquí.

⸻

RUTA INGENIERÍA

Sofía lleva al jugador por el laboratorio.

Sofía

Justo a tiempo.

Pausa.

Como un engranaje recién engrasado.

⸻

Si llega tarde:

Sofía

Veinte minutos tarde.

Mira su reloj.

En ingeniería lo llamamos margen de error.

Pausa.

No lo conviertas en costumbre.

⸻

Si llegó tarde a prácticas:

Sofía

Tarde a las prácticas.

Mira al jugador.

Tarde hoy.

Pausa.

Si fueras un puente, ya estaría revisando tus cálculos.

⸻

Sofía llega a una mesa.

Hay un ordenador.

Una placa con el nombre del jugador.

Sofía

Esto lleva tu nombre.

⸻

RUTA DERECHO

Montse espera en un despacho.

Montse

Buenos días.

Pausa.

Puntual.

Sonríe ligeramente.

Me gusta.

⸻

Si llega tarde:

Montse

Las nueve y veinte.

Pausa.

No voy a levantar la voz.

PrimerPlano.

Tampoco lo voy a olvidar.

⸻

Si llegó tarde a prácticas:

Montse

La primera vez fueron las prácticas.

Pausa.

Esta es la segunda.

Mira el contrato.

Un tribunal no daría una tercera.

⸻

Montse coloca un documento.

Montse

Quiero que leas esto despacio.

⸻

RUTA ECONOMÍA

Ignacio espera con tres bolígrafos.

Ignacio

Puntual al minuto.

Pausa.

Los números y yo te damos la bienvenida.

⸻

Si llega tarde:

Ignacio

Veinte minutos tarde.

Mira el reloj.

En intereses de demora, eso sale carísimo.

Sonríe.

Te lo perdono.

Pausa.

Esta vez.

⸻

Si llegó tarde a prácticas:

Ignacio

Dos retrasos en dos primeros días.

Pausa.

Si esto fuera una gráfica…

Mira al jugador.

Me preocuparía la tendencia.

⸻

Ignacio levanta tres bolígrafos.

Ignacio

He traído tres.

Pausa.

Por si acaso.

⸻

RUTA BARISTA

Lola conduce al jugador a la cocina.

Lola

Primero ayudante.

Pausa.

Después responsable.

Mira alrededor.

Ahora quiero saber si puedes llevar esto.

⸻

RUTA REPONEDOR

Paco lleva al jugador por el almacén.

Paco

Pasillo tres.

Pausa.

Perfecto.

Camina.

Pasillo cuatro.

Pausa.

También.

Mira al jugador.

Eso me gusta.

⸻

RUTA REPARTIDOR

Ernesto abre una gran hoja con rutas.

Ernesto

Conoces Valmar.

Pausa.

Ahora vas a conocerla calle por calle.

⸻

PASO 8 · OFERTA DE TRABAJO

Aquí el resultado debe depender del historial.

⸻

GRADUADO + oferta_trabajo

El mentor entrega directamente el puesto.

Nuria / Sofía / Montse / Ignacio

Te estábamos esperando.

⸻

GRADUADO + SIN oferta_trabajo

No convertirlo en fracaso.

El jugador recibe una oportunidad después de demostrar su preparación.

Nuria

Mándame veinte currículums.

Pausa.

Y llámame cuando lo hayas hecho.

Corte.

Más adelante:

Uno de esos sitios te ha llamado.

⸻

ANTECEDENTES

Si antecedentes = true:

No hacer que el juego castigue automáticamente al jugador.

El mentor debe valorar la honestidad.

Nuria / Sofía / Montse / Ignacio

Nos contaste lo que ocurrió.

Pausa.

No lo escondiste.

Mentor

Te contratamos por lo que has demostrado después.

Esto debe reforzar una idea:

el pasado importa, pero no determina completamente el futuro.

⸻

PASO 9 · FIRMA

Adu01_Firma

Música: Emocion

⸻

Plano 1 — Inserto

Contrato sobre la mesa.

Nombre del jugador.

Puesto.

Salario.

Fecha.

⸻

Plano 2 — PrimerPlano

Bolígrafo.

La mano del jugador duda durante medio segundo.

⸻

Plano 3 — PPP

Firma.

⸻

Jugador

Mi nombre.

Pausa.

En un contrato de verdad.

Respira.

Mío.

⸻

RESPUESTA DEL MENTOR

Medicina

Firmado.

Pausa.

Bienvenido al equipo.

⸻

Ingeniería

Oficial.

Sonríe.

Ahora te enseño tu mesa.

⸻

Derecho

Bienvenido al despacho.

Pausa.

Despacio y bien.

⸻

Economía

Tres firmas.

Mira el documento.

Cero errores.

⸻

Barista

Lola grita desde la barra:

¡Encargado/a!

Pausa.

¡A la barra, que hay cola!

⸻

Reponedor

Paco:

Encargado/a.

Pausa.

Bien.

⸻

Repartidor

Ernesto:

Jefe/a de ruta.

Sonríe.

Ahora te aprenderás los nombres de los perros.

⸻

PASO 10 · NUEVO SISTEMA

PrimerDiaProfesional

Solo si graduado = true.

Este paso debe convertirse en gameplay real.

El jugador recibe su primera responsabilidad.

No basta con hablar.

⸻

PASO 11 · PRIMER CASO

El mentor entrega una tarea específica.

⸻

Medicina

Tu primer paciente sin supervisión directa.

Pausa.

Estaré en la sala de al lado.

⸻

Ingeniería

La pasarela del río.

Pausa.

El ayuntamiento aprobó tu idea.

⸻

Derecho

Tu primer cliente propio.

Pausa.

Ha vuelto.

⸻

Economía

Marcos quiere abrir otra tienda.

Pausa.

Tú llevarás sus números.

⸻

DECISIÓN

Opción A

«Pido consejo cuando dudo.»

responsabilidad += 1
primer_caso = Consejo

El mentor responde:

Bien preguntado.

Pausa.

Así se aprende.

⸻

Opción B

«Me lanzo: sé más de lo que creo.»

valentia += 1
primer_caso = Lanzarse

El jugador realiza la tarea.

Puede cometer un pequeño error.

Pero debe corregirlo.

El mentor:

No salió perfecto.

Pausa.

Pero lo arreglaste.

Sonríe.

Hoy has aprendido más que en un semestre.

⸻

PASOS 12–14 · PRIMER TURNO

BARISTA

Objetivo

Primer turno como encargado/a (0/3)

Tres responsabilidades:

1. organizar pedidos;
2. resolver una pequeña incidencia;
3. cerrar caja.

⸻

REPONEDOR

Tres tareas:

1. revisar inventario;
2. organizar mercancía;
3. resolver una estantería mal colocada.

⸻

REPARTIDOR

Tres tareas:

1. organizar ruta;
2. entregar paquetes;
3. solucionar un cambio de dirección.

⸻

PASO 15 · CINEMÁTICA

Adu01_PrimerTurno

Solo si graduado = false.

No hacer una cinemática estática.

Debe mostrar al jugador trabajando.

⸻

BARISTA

Omar aparece.

Omar

¡Encargado/a!

Pausa.

Ya puedo decir que mi jefe es mi amigo.

Piensa.

Espera.

Mira al jugador.

Eso no es bueno para mí.

⸻

Lola observa desde lejos.

Lola

Aquel verano tiraste una bandeja entera.

Pausa.

Y viniste a decírmelo.

Sonríe.

Por eso estás aquí.

⸻

REPONEDOR

Paco revisa los pasillos.

Paco

Pasillo tres.

Pausa.

Perfecto.

Pasillo cuatro.

Pausa.

Perfecto.

Mira al jugador.

Muy bien.

⸻

REPARTIDOR

Ernesto revisa la ruta.

Ernesto

Ruta completa.

Pausa.

Ni una carta perdida.

Sonríe.

Y el perro del catorce te ha movido la cola.

⸻

PASO 16 · FINAL DE MES

Transición

Final de mes…

No utilizar un montaje demasiado rápido.

Mostrar:

* días pasando;
* alarma;
* trabajo;
* comida;
* transporte;
* cansancio;
* pequeñas compras;
* calendario avanzando.

⸻

PASO 17 · PRIMER SUELDO

Adu01_Buzon

Música: Emocion

⸻

Inserto

Aplicación bancaria ficticia.

SALARIO RECIBIDO

El número aparece.

⸻

Jugador

Primer sueldo completo.

Pausa.

Entero.

Sonríe.

Mío.

⸻

El jugador camina hacia el buzón.

Lo abre.

Tres sobres.

⸻

Inserto

ALQUILER

LUZ

AGUA

⸻

Jugador

Nadie me avisó de que ser adulto/a venía con buzón.

⸻

PASO 18 · DECISIÓN FINANCIERA

«¿Qué haces con las facturas?»

⸻

OPCIÓN A

«Pagarlas ya, todas.»

responsabilidad += 1
facturas = Pagar

Jugador

Pagado.

Mira el saldo.

El sueldo ha adelgazado bastante.

Pausa.

Pero esta noche duermo tranquilo/a.

⸻

OPCIÓN B

«Dejarlas para la semana que viene.»

facturas = Luego
factura_pendiente = true

El jugador deja los sobres sobre la mesa.

Coloca una planta delante.

Jugador

Si no las veo…

Pausa.

…no existen.

Mira la planta.

Creo.

⸻

OPCIÓN C

«Hacer un presupuesto.»

curiosidad += 1
facturas = Presupuesto

Jugador

Mejor saber cuánto entra antes de decidir cuánto sale.

⸻

PASO 19 · BANCO

Solo si facturas = Presupuesto

El jugador visita el Banco Valmar.

Ignacio está trabajando.

⸻

Ignacio

¡La persona de los números!

Señala una silla.

Siéntate.

⸻

PASO 20 · PRIMER PRESUPUESTO

No convertirlo en una conversación pasiva.

Crear un pequeño sistema visual.

En pantalla:

INGRESOS
SALARIO
GASTOS
ALQUILER
LUZ
AGUA
COMIDA
TRANSPORTE
AHORRO

El jugador distribuye su dinero.

⸻

Ignacio

Las facturas, primero.

Pausa.

Después, lo que necesites.

Señala una sección.

Y deja algo para los imprevistos.

⸻

Ignacio

Los imprevistos siempre llegan.

Sonríe.

Solo cambia cuándo.

⸻

RESULTADO

Si el jugador consigue ahorrar:

primer_presupuesto = Exitoso

Si deja el presupuesto demasiado ajustado:

primer_presupuesto = Ajustado

No debe existir un “fracaso”.

El juego debe enseñar.

⸻

PASO 21 · LLAMADA DE MAMÁ/PAPÁ

El jugador vuelve a casa.

Suena el teléfono.

La cámara permanece en el personaje.

No abrir menú.

⸻

Mamá/Papá

¿Qué tal el primer mes?

Pausa.

¿Has comido bien?

Otra pausa.

¿Has pagado las facturas?

El jugador puede sonreír.

⸻

Mamá/Papá

Perdona.

Pausa.

No lo puedo evitar.

Silencio.

El tono cambia.

Mamá/Papá

Oye…

Pausa.

Abu no está muy bien.

Pausa.

Nada grave, creo.

Respira.

Pero te echa de menos.

⸻

PrimerPlano del jugador.

⸻

Mamá/Papá

Pásate cuando puedas.

Silencio.

¿Vale?

⸻

FINAL DE MISIÓN

La llamada termina.

El jugador se queda solo.

La casa está silenciosa.

Mira:

* su contrato;
* sus primeras llaves;
* los sobres de las facturas;
* el teléfono.

La cámara hace un:

Dolly

muy lento hacia atrás.

⸻

ÚLTIMA FRASE

Narrador

El primer sueldo te enseñó cuánto cuesta vivir.

Pausa.

La llamada de casa te recordó para quién quieres hacerlo.

Fade out.

⸻

ESTADOS FINALES

primer_contrato_completado = true
primer_sueldo = true
adulto_joven_trabajando = true

Si eligió:

facturas = Pagar

guardar:

facturas_pagadas = true

Si eligió:

facturas = Luego

guardar:

factura_pendiente = true

Si eligió presupuesto:

primer_presupuesto = true

⸻

BIOGRAFÍA

Mostrar:

«Tu primer contrato»

Subtítulo:

El día que tu nombre apareció en un contrato de verdad.

⸻

PREPARACIÓN DE Adu02_Atardecer

La misión debe terminar dejando una transición natural.

En el mapa aparece:

Casa familiar — Los Pinos

Pero no marcar inmediatamente como obligatorio.

Al día siguiente:

Mamá/Papá:

Abu quiere verte.

Y así comienza:

Adu02_Atardecer — Un atardecer junto al mar

⸻

DIRECCIÓN AAA DE LA MISIÓN

La clave visual

La evolución debe verse en el personaje.

Antes

* mochila;
* ropa juvenil;
* habitación familiar;
* horarios escolares.

Ahora

* llaves;
* contrato;
* teléfono;
* vivienda propia;
* transporte;
* trabajo;
* sueldo;
* facturas.

No decir constantemente:

«Ahora eres adulto.»

Mostrarlo.

⸻

REGLA DE ACTUACIÓN

Los NPC profesionales no deben esperar inmóviles.

Mientras hablan:

Nuria

consulta una carpeta, camina, revisa una sala.

Sofía

comprueba planos, toca una pantalla, señala piezas.

Montse

lee documentos, ordena carpetas, escribe.

Ignacio

hace cálculos, revisa una hoja, cambia números.

Lola

sirve, cocina, limpia, organiza.

Paco

coloca productos y revisa inventario.

Ernesto

clasifica paquetes y consulta rutas.

⸻

REGLA DE CÁMARA

No usar una única cámara para toda la misión.

Las conversaciones profesionales deben utilizar:

* General;
* Medio;
* PrimerPlano;
* PPP;
* Hombro;
* DosPlanos;
* Inserto;
* Seguir;
* Dolly;
* Reaccion.

Los momentos de firma deben usar obligatoriamente:

Inserto → PrimerPlano → PPP → DosPlanos.

⸻

REGLA MUSICAL

Utilizar únicamente:

* Calma
* Tension
* Emocion
* Accion
* Epico
* Comedia

No utilizar:

* Descubrimiento
* Intima
* Resolucion
* Tema
* Nada
* VidaAdulta

Si se necesitan esos estados, deben mapearse a las categorías permitidas.

⸻

PRINCIPIO FINAL

Esta misión debe hacer sentir:

«Hasta ayer estaba estudiando para convertirme en alguien.»

«Hoy alguien me ha dado las llaves.»

«Y ahora depende de mí qué hago con ellas.»

Ese es el verdadero inicio de la vida adulta.
