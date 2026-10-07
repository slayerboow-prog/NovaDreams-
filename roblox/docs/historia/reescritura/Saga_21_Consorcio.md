MISIÓN: Saga_21_Consorcio — «La caída del Consorcio»

ID ORIGINAL: Saga_21_Consorcio
ACTO: IV — 3/6
ETAPA: Adulto
DURACIÓN OBJETIVO: 25–35 minutos
REQUISITOS: Saga_20_Aliados + Adulto

⸻

1. FUNCIÓN NARRATIVA

Esta misión representa el primer ataque organizado contra el poder de Cósimo.

Hasta ahora:

* el jugador descubrió el origen de la Grieta;
* descubrió que es el Ancla;
* rescató a Cosme;
* recuperó sus recuerdos;
* reunió a sus aliados.

Ahora toca hacer algo que cambie realmente las posibilidades del enfrentamiento:

quitarle a Cósimo los recursos que necesita para ejecutar la Gran Fusión.

El objetivo no es simplemente «entrar en un edificio y pegar a dos NPC».

Debe sentirse como una operación coordinada.

La misión debe demostrar que:

Una buena estrategia puede ser tan importante como la fuerza.

Y, sobre todo:

El jugador no ha llegado hasta aquí solo.

⸻

2. CONCEPTO DE LA MISIÓN

La sede de MegaVerso se encuentra en el Distrito Financiero.

Es un edificio enorme, moderno y excesivamente lujoso.

Todo transmite poder:

* pantallas;
* ascensores;
* recepción;
* oficinas acristaladas;
* seguridad;
* servidores;
* salas de reuniones;
* logotipos ficticios de MegaVerso;
* empleados NPC siguiendo rutinas.

No debe parecer una simple sala vacía creada para una misión.

Debe parecer una empresa que funciona incluso cuando el jugador no está allí.

⸻

3. ESTADO INICIAL

Al llegar a la zona:

saga_21_iniciada = true
servidor_megaverso_localizado = true
equipo_aliados_reunido = true

Don Escamas acompaña al grupo dentro de su cubo/recipiente.

No debe ser un simple objeto transportado.

Tiene pequeñas animaciones:

* mira a ambos lados;
* se esconde;
* asoma la cabeza;
* mueve las aletas cuando detecta peligro.

⸻

PASO 1 — PELEA

Objetivo

Asalto a la sede de MegaVerso: aparta a la seguridad (0/2)

Localización

Oficinas del Distrito Financiero.

En escena

* jugador;
* Candela;
* Iván;
* Don Escamas;
* agentes de seguridad;
* Agente de MegaVerso si existe gris_arrepentida.

⸻

ENTRADA AL EDIFICIO

CINEMÁTICA

CÁMARA — General

Mostrar la sede desde el exterior.

Edificio alto.

Pantallas gigantes.

Personas entrando y saliendo.

Vehículos llegando.

Una pantalla reproduce anuncios corporativos.

La cámara desciende hasta el grupo.

Música

Tension

⸻

CÁMARA — Medio

Candela observa la entrada.

Candela

«Tres entradas.»

Mira a la derecha.

«Dos guardias.»

Mira al jugador.

«Y una opción sencilla.»

Iván:

«¿Cuál?»

Candela:

«No llamar la atención.»

Iván mira su ropa.

Iván

«Creo que ya hemos fallado.»

Pequeña pausa.

Música

Comedia

La música vuelve a Tension.

⸻

GAMEPLAY — INFILTRACIÓN

Antes del enfrentamiento debe existir una pequeña ventana de infiltración.

El jugador puede:

* caminar detrás de NPCs;
* utilizar zonas de cobertura;
* esperar a que un guardia cambie de posición;
* seguir a Candela;
* utilizar rutas secundarias.

No convertirlo en un sistema de sigilo extremadamente complejo.

Debe ser accesible.

⸻

OBJETIVO

Cuando el jugador llega a la zona restringida:

SEGURIDAD MEGAVERSO
2 AGENTES

Aparece:

APARTA A LA SEGURIDAD (0/2)

La acción debe ser no gráfica y apta para Roblox.

Nada de sangre.

Nada de violencia explícita.

Puede consistir en:

* esquivar;
* bloquear;
* empujar;
* desactivar dispositivos;
* hacer que abandonen la zona;
* pequeños enfrentamientos arcade.

⸻

ALIADO CONDICIONAL — AGENTE DE MEGAVERSO

Si:

gris_arrepentida = true

aparece un agente que anteriormente cambió de bando.

No debe actuar como combatiente principal.

Debe utilizar su conocimiento interno.

Agente

«Por aquí.»

Señala una puerta.

Agente

«La seguridad cambia cada noventa segundos.»

Candela:

«¿Y cómo sabes eso?»

Agente

«Porque antes era parte del problema.»

Pausa.

«Ahora quiero arreglarlo.»

FLAG

agente_gris_apoya = true

Esto permite una ruta más sencilla.

⸻

FALLO / CAPTURA

Si el jugador es detectado:

No reiniciar toda la misión.

CÁMARA — Reaccion

Un guardia bloquea el paso.

Agente

«Alto. Esta zona no está autorizada.»

Candela aparece inmediatamente.

Lo agarra suavemente del brazo.

Candela

«Tiene usted una llamada de ventas.»

Lo aparta de la zona.

La misión devuelve al jugador al último punto seguro.

Esto debe ser divertido, no frustrante.

⸻

PASO 1 — COMPLETADO

Al apartar a los dos agentes:

CÁMARA — Medio

Candela mira hacia el pasillo.

Candela

«Ya está.»

Iván:

«¿Ya está?»

Candela:

«Ahora viene lo difícil.»

Don Escamas asoma desde su cubo.

Don Escamas

«Servidor.»

La puerta se abre.

Música

Tension

⸻

PASO 2 — USAR

Objetivo

Enchufa el pendrive de Don Escamas en el servidor central.

⸻

DESCENSO AL SERVIDOR

El grupo avanza por el edificio.

Esta parte debe funcionar como transición jugable.

No teletransportar directamente al servidor.

Mostrar:

* oficinas;
* empleados;
* salas;
* ascensores;
* pantallas;
* cámaras;
* pasillos;
* puertas de seguridad.

La empresa debe sentirse enorme.

⸻

ASCENSOR

CÁMARA — Medio

El grupo entra en el ascensor.

Iván pulsa un botón.

Iván

«¿Planta del servidor?»

Candela:

«Subterráneo.»

Iván:

«Claro.»

Pausa.

«Porque siempre está debajo.»

Don Escamas:

«Es donde guardan las cosas importantes.»

⸻

SERVIDOR CENTRAL

Las puertas se abren.

CÁMARA — General

Gran sala de servidores.

Filas de máquinas.

Luces.

Pantallas.

Refrigeración.

Personal técnico NPC trabajando.

La escala debe transmitir que este servidor controla una enorme parte de MegaVerso.

⸻

INTERACCIÓN

Aparece:

USAR — SERVIDOR CENTRAL DE MEGAVERSO

El jugador saca el pendrive.

CÁMARA — Inserto

El pendrive tiene forma de pez.

Don Escamas lo observa.

Don Escamas

«Trátalo con cuidado.»

Pausa.

«Tiene información sensible.»

El jugador lo conecta.

⸻

ACTIVACIÓN

Silencio.

Una pantalla.

Otra.

Otra.

Todas empiezan a cambiar.

CÁMARA — Pan

Recorrer las pantallas.

Aparecen:

* cuentas;
* transferencias;
* contratos;
* gastos;
* proyectos;
* empresas ficticias;
* inversiones;
* operaciones del Consorcio.

⸻

INFORMACIÓN DEL PROYECTO FUSIÓN

Una pantalla muestra:

PROYECTO FUSIÓN
FINANCIACIÓN:
LABORATORIO DR. CÓSIMO
ESTADO:
ACTIVO
PROYECTO PRIORITARIO

Candela se acerca.

CÁMARA — PrimerPlano

Candela

«Aquí está.»

Iván:

«¿Qué?»

Candela señala la pantalla.

Candela

«La financiación.»

⸻

RECUERDO CONDICIONAL

Si:

recuerdo_proyecto_fusion = true

Candela reconoce la información.

Candela

«Es lo que viste en su ordenador de la oficina.»

Pausa.

«Ahora tenemos los importes.»

⸻

REVELACIÓN

El jugador observa varias cantidades.

No mostrar números excesivamente complejos.

Lo importante es que el jugador comprenda:

MegaVerso está financiando directamente el proyecto de Cósimo.

⸻

IVÁN

Iván

«¿Todo esto para abrir una Grieta?»

Candela:

«Todo esto para controlar dos mundos.»

Iván mira las pantallas.

Iván

«Yo con este dinero habría comprado muchos zumos.»

Candela:

«Iván.»

Iván

«Muchos.»

⸻

DATOS DESCARGADOS

Crear interacción:

DESCARGANDO DATOS...
██████████ 100%

Obtener:

Datos_Financieros_MegaVerso

Y:

Pruebas_Proyecto_Fusion

⸻

CONSECUENCIA IMPORTANTE

El jugador no debe simplemente «robar dinero».

Los datos se envían automáticamente a las autoridades correspondientes.

Esto permite que la caída de MegaVerso tenga una consecuencia lógica.

Don Escamas

«Ahora.»

Pausa.

«Solo hay que dejar que hagan su trabajo.»

⸻

PASO 3 — ESCENA

APARICIÓN DEL BANCO GALÁCTICO

El servidor empieza a emitir una alerta.

No es una alarma de seguridad normal.

Es una comunicación externa.

CÁMARA — General

Todas las pantallas cambian.

Aparece:

BANCO GALÁCTICO

⸻

AGENTE GLUB

Entra en la sala con varios agentes.

No es una escena violenta.

Es una intervención administrativa.

CÁMARA — General

Agente Glub

«Agente Glub. Banco Galáctico.»

Mira las pantallas.

Agente Glub

«Hemos recibido un chivatazo contable impecable.»

Mira el pendrive.

Agente Glub

«Firmado por un tal D. Escamas.»

Pausa.

Mira a Don Escamas.

Agente Glub

«Muy buena caligrafía para ser un pez.»

⸻

RECONOCIMIENTO CONDICIONAL

Si:

deuda_galactica = true

Agente Glub mira al jugador.

Agente Glub

«¿Nos conocemos?»

Pausa.

«Usted leyó la letra pequeña.»

Otra pausa.

«O nos resistió.»

Sonríe.

«Me acuerdo.»

Esto recompensa una misión antigua sin obligar a todos los jugadores a haberla completado.

⸻

INTERVENCIÓN

Agente Glub levanta una tableta.

CÁMARA — PrimerPlano

Agente Glub

«MegaVerso S.A. queda intervenida.»

Pulsa.

Sonido

CLICK

Otra pulsación.

Agente Glub

«Cuentas congeladas.»

Otra.

Agente Glub

«Activos bloqueados.»

Otra.

Agente Glub

«Operaciones suspendidas.»

Silencio.

Agente Glub

«Sellado.»

Pausa.

«Sellado.»

Pausa.

«Y sellado.»

⸻

CONSECUENCIA

La pantalla principal cambia:

MEGAVERSO
FINANCIACIÓN:
BLOQUEADA
PROYECTO FUSIÓN:
SIN FINANCIACIÓN

Música

Emocion

⸻

IVÁN

Iván mira las pantallas.

Iván

«¡Hemos arruinado una multinacional malvada!»

Mira el pendrive.

Iván

«¡Con un pendrive con forma de pez!»

CÁMARA — Reaccion

Iván levanta los brazos.

Iván

«¡Esto hay que ponerlo en el currículum!»

⸻

CANDELA

Si:

recuerdo_equipo_rescate = true

Candela

«El equipo de rescate.»

Pausa.

«Versión asalto.»

Mira a Iván.

«Funciona igual de bien.»

⸻

EL SILENCIO DESPUÉS DE LA VICTORIA

La música desaparece.

Candela mira el mapa del proyecto.

CÁMARA — Hombro

Candela observa una ruta marcada hacia Monte del Silencio.

Candela

«Sin dinero, Cósimo solo tiene una opción.»

Pausa.

«Hacer la Fusión él solo.»

Mira al jugador.

Candela

«Y rápido.»

Pausa.

Candela

«Viene a por el Ancla.»

Silencio.

Candela

«Ahora sí.»

⸻

CINEMÁTICA FINAL

CÁMARA — Dolly

Salir lentamente de la sala de servidores.

El grupo queda pequeño dentro de la enorme instalación.

Las pantallas continúan apagándose.

Una tras otra.

⸻

CORTE

General

Exterior del Distrito Financiero.

Las pantallas de MegaVerso empiezan a apagarse.

Una.

Dos.

Tres.

Hasta que el edificio queda parcialmente a oscuras.

En la distancia, Valmar continúa iluminada.

⸻

ÚLTIMO PLANO

CÁMARA — General

Muy lejos, sobre el Monte del Silencio:

una pequeña luz púrpura aparece en el cielo.

La Grieta.

Todavía pequeña.

Pero creciendo.

Música

Tension

Corte a negro.

⸻

RECOMPENSA

Datos_Financieros_MegaVerso
Pruebas_Proyecto_Fusion

Biografía:

«Hiciste caer al Consorcio MegaVerso»

⸻

VARIABLES

Al completar:

saga_21_completada = true
consorcio_caido = true
megaverso_intervenido = true
cuentas_megaverso_congeladas = true
financiacion_fusion_bloqueada = true
cayó_consorcio = true

Mantener también:

proyecto_fusion
equipo_rescate
todos_los_aliados

No reemplazar variables antiguas.

⸻

CAMBIOS PERMANENTES EN EL MUNDO

Después de esta misión:

Distrito Financiero

La sede de MegaVerso debe cambiar.

Antes:

* edificio activo;
* empleados;
* pantallas;
* seguridad.

Después:

* algunas pantallas apagadas;
* puertas precintadas;
* NPCs comentando la intervención;
* vehículos oficiales;
* trabajadores preocupados;
* periodistas ficticios;
* pequeños grupos de NPC hablando.

No convertirlo en una zona muerta.

Debe sentirse como una empresa que acaba de sufrir una crisis.

⸻

NOTICIAS DEL MUNDO

Los sistemas de noticias de Valmar pueden mostrar:

«MegaVerso intervenida tras descubrirse irregularidades financieras.»

Otro NPC:

«Dicen que el proyecto del doctor Cósimo se ha quedado sin fondos.»

Otro:

«¿Qué pasará ahora con la Fusión?»

El jugador no debe ser obligado a escuchar estas conversaciones.

Son ambientación.

⸻

CONSECUENCIA PARA CÓSIMO

Actualizar:

cosimo_sin_financiacion = true
cosimo_presionado = true
cosimo_ejecuta_fusion_solo = true

Esto debe afectar a su comportamiento posterior.

Cósimo deja de tener:

* ejército corporativo;
* financiación ilimitada;
* estructura del Consorcio.

Ahora solo tiene:

su máquina, su obsesión y la Grieta.

Esto hace que el siguiente enfrentamiento sea mucho más personal.

⸻

DIRECCIÓN DE ACTUACIÓN

Candela

Debe sentirse como el cerebro de la operación.

* analiza;
* observa;
* anticipa;
* no celebra demasiado;
* entiende inmediatamente la gravedad.

Iván

Es el contraste emocional.

* nervioso;
* espontáneo;
* hace bromas;
* pero comprende que la situación es seria.

Don Escamas

Debe comportarse como alguien que sabe mucho más de lo que aparenta.

No convertirlo en un simple gag.

Cuando entrega el pendrive, debe transmitir seguridad.

Agente Glub

Debe parecer profesional.

No agresivo.

Su intervención debe hacer sentir que existe un mundo institucional detrás de Valmar.

⸻

GAMEPLAY Y MOVIMIENTO

Los NPC nunca deben quedarse congelados mientras el jugador interactúa.

Durante el paso 2:

* Iván puede mirar las pantallas;
* Candela puede desplazarse entre terminales;
* Don Escamas puede moverse dentro del cubo;
* empleados pueden caminar al fondo;
* servidores deben tener animaciones;
* luces deben cambiar.

Durante el paso 3:

* Agente Glub entra caminando;
* sus agentes se posicionan;
* las pantallas reaccionan;
* Iván se acerca;
* Candela revisa datos.

Todo debe tener vida.

⸻

CÁMARA

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

No utilizar otros nombres de planos.

La cámara debe transmitir:

entrada → infiltración → descubrimiento → intervención → consecuencia.

⸻

MÚSICA

Utilizar exclusivamente:

* Calma
* Tension
* Emocion
* Accion
* Epico
* Comedia

Secuencia:

Exterior → Tension
Infiltración → Tension
Iván / pendrive → Comedia
Servidor → Tension
Descubrimiento financiero → Emocion
Intervención → Emocion
Consecuencia final → Tension

⸻

QA OBLIGATORIO

Misión

* Se puede completar después de Saga_20_Aliados.
* Los objetivos aparecen correctamente.
* El contador 0/2 funciona.
* La captura no rompe la misión.
* El jugador puede volver al último punto seguro.

Servidor

* El pendrive se inserta correctamente.
* La animación de conexión funciona.
* Las pantallas reaccionan.
* Los datos se descargan una sola vez.
* No se duplica la recompensa.

Intervención

* Agente Glub aparece correctamente.
* La intervención ocurre una sola vez.
* Las cuentas quedan congeladas.
* El estado de MegaVerso se guarda.

Cámara

* Restaurar cámara después de todas las cinemáticas.
* Restaurar controles.
* Restaurar sensibilidad.
* Evitar clipping.
* Evitar que NPCs tapen la información importante.

Persistencia

Guardar:

saga_21_completada
consorcio_caido
megaverso_intervenido
cuentas_megaverso_congeladas
financiacion_fusion_bloqueada
cosimo_sin_financiacion

⸻

RESULTADO EMOCIONAL

El jugador debe terminar la misión pensando:

«Por fin hemos conseguido hacerle daño de verdad.»

Pero inmediatamente después:

«Y eso significa que Cósimo ya no tiene nada que perder.»

La victoria debe sentirse real.

Y precisamente por eso debe dar miedo.

Porque Cósimo ya no puede financiar una guerra.

Ahora solo le queda una cosa:

el Ancla.
