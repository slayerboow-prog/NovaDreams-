MISIÓN: Adulto_MirarAtras — ID: Adulto_MirarAtras
Etapa: Adulto
Tipo: Misión narrativa / Epílogo de vida
Duración objetivo: 20–30 min
Requisito: Haber vivido aproximadamente el 95 % de la etapa adulta
Lugar: Casa familiar de Los Pinos

⸻

INTENCIÓN DE LA MISIÓN

Esta misión no debe sentirse como una pantalla de créditos.

Debe sentirse como:

volver a casa después de haber vivido una vida.

El jugador no recibe una lista de lo que hizo.

Lo recuerda.

La casa, los objetos, los sonidos, las fotografías y las personas deben reconstruir su historia.

La misión debe conseguir algo muy concreto:

hacer que el jugador recuerde cosas que había olvidado.

⸻

REGLA FUNDAMENTAL

No mostrar automáticamente todos los recuerdos.

El sistema debe seleccionar recuerdos según las decisiones reales del jugador.

Si el jugador:

* ayudó a Mateo → Mateo aparece;
* creó un grupo → aparece ese grupo;
* eligió un club → se recuerda ese club;
* tomó determinado camino en el instituto → aparece;
* se graduó → aparece la graduación;
* empezó a trabajar → aparece su primer contrato;
* pasó tiempo con Abu → aparece Playa Dorada;
* eligió una promesa para Abu → cambia el diálogo;
* conoció a Leire → aparece Leire;
* tuvo una relación concreta con Cosme → se refleja;
* eligió determinados objetivos adultos → cambian las conversaciones.

Nada debe sentirse genérico.

⸻

SISTEMA MEMORIA_DE_VIDA

Crear un sistema de recuerdos consultable:

VidaRecuerdos = {
    nacimiento,
    primer_grupo,
    ayudaste_a_mateo,
    primer_club,
    conoces_a_leire,
    el_cruce,
    graduacion,
    primer_contrato,
    atardecer_con_abu,
    el_reencuentro,
    conoci_cosme,
    coser_el_cielo,
    saga_grieta_completada
}

Además:

nombre_grupo
promesa_abu
promesa_adulta

⸻

PASO 1 · IR A

«Vuelve a la casa donde creciste»

Objetivo

El jugador debe viajar físicamente hasta la casa familiar.

No hacer teleport.

⸻

INICIO

Cuando el jugador acepta la misión, el HUD desaparece parcialmente.

Aparece únicamente:

Vuelve a casa.

Sin marcador invasivo.

El mapa muestra una pequeña ruta.

⸻

VIAJE A LOS PINOS

El jugador atraviesa la ciudad.

La ciudad debe seguir funcionando normalmente.

Pero el sistema puede aumentar ligeramente la probabilidad de encontrar:

* antiguos compañeros;
* vecinos;
* lugares asociados a recuerdos;
* edificios relacionados con la infancia.

No detener al jugador obligatoriamente.

⸻

EVENTO OPCIONAL

Si el jugador pasa cerca de un lugar importante de su infancia:

Inserto

Un pequeño destello.

Sonido

Un sonido ambiental asociado al recuerdo.

No aparece texto.

El jugador puede seguir caminando.

Si se detiene:

Recordar

El jugador puede interactuar.

Esto permite que la memoria sea jugable, no solo narrada.

⸻

LLEGADA A LA CASA

La música desaparece.

La cámara se coloca detrás del jugador.

Seguir

El jugador se acerca a la puerta.

La puerta tiene exactamente el mismo chirrido de la infancia.

⸻

Narrador

La casa de Los Pinos.

Pausa.

La puerta sigue chirriando igual.

⸻

El jugador puede abrir.

⸻

PASO 2 · CINEMÁTICA

Vida_MirarAtras

Lugar: Casa familiar de Los Pinos
Duración: 2–4 minutos
Cámara: aproximadamente 22 planos dinámicos

Música: Emocion

No utilizar etiquetas de música no válidas.

⸻

ESCENA 1 — LA CASA VACÍA

Plano 1 — General

Interior de la casa.

Luz de tarde entrando por las ventanas.

Polvo visible en el aire.

No hay personajes todavía.

⸻

Plano 2 — Seguir

El jugador entra.

La cámara sigue sus pasos.

⸻

Plano 3 — Inserto

Una pequeña marca en una pared.

La marca de altura del jugador cuando era niño.

⸻

Plano 4 — PrimerPlano

La mano del jugador toca la pared.

⸻

Flashback

Durante aproximadamente 1 segundo:

Un niño corre por el mismo pasillo.

Corte.

Volvemos al adulto.

⸻

ESCENA 2 — LAS FOTOGRAFÍAS

Sobre una mesa hay un álbum.

El jugador se acerca.

⸻

Narrador

Una foto por etapa.

Pausa.

Una vida dentro de cada foto.

⸻

El jugador puede interactuar.

Al abrirlo:

Inserto

Primera fotografía.

⸻

RECUERDO 1 — NACIMIENTO

Rótulo

El día que naciste

No mostrar un nacimiento explícito.

Mostrar:

* casa;
* familia;
* bebé envuelto;
* Abu;
* padres.

⸻

Narrador

Tu abu dijo tu nombre en voz alta.

Pausa.

Para que lo oyera el barrio.

⸻

MICROFLASHBACK

Abu sonríe.

No más de 3 segundos.

Corte.

⸻

RECUERDO 2 — PRIMER GRUPO

SI existe primer_grupo

El álbum cambia automáticamente.

Rótulo:

Tu grupo del colegio

Subtítulo:

Diez años y un banco del parque.

⸻

Variante según nombre

Si:

nombre_grupo = Los Imparables

Mostrar:

«Los Imparables»

Si:

nombre_grupo = La Patrulla Valmar

Mostrar:

«La Patrulla Valmar»

Si:

nombre_grupo = Los del Banco Azul

Mostrar:

«Los del Banco Azul»

Si:

nombre_grupo = Los Dinosaurios

Mostrar:

«Los Dinosaurios»

⸻

MICROFLASHBACK

El jugador niño y sus amigos sentados en el banco.

Risas.

Un balón rueda por el suelo.

Nico intenta atraparlo.

Omar está comiendo.

Sara está explicando algo.

La escena dura pocos segundos.

⸻

SI NO EXISTE primer_grupo

Si:

ayudaste_a_mateo = true

Mostrar:

Rótulo

Mateo

Subtítulo:

Tu primer amigo empezó con unos libros por el suelo.

⸻

MICROFLASHBACK

Libros cayendo.

Mateo nervioso.

El jugador ayudándolo.

⸻

SI NO EXISTE NINGUNO

Mostrar:

Tu primer día de colegio

Subtítulo:

«Pasad, pasad.»

⸻

RECUERDO 3 — EL CRUCE

Si existe:

el_cruce

Rótulo

El cruce de caminos

Subtítulo:

El día que elegiste quién ser.

No mostrar una única decisión.

Mostrar varios planos de las posibilidades que el jugador tuvo.

El jugador adulto observa.

⸻

Narrador

No sabías qué iba a pasar.

Pausa.

Solo sabías que tenías que elegir.

⸻

SI NO EXISTE el_cruce

Pero existe:

conoces_a_leire

Mostrar:

Leire

Subtítulo:

Te hizo la mejor foto de tu vida.

Pausa.

Y no te la enseñó hasta años después.

⸻

SI NO EXISTEN LOS ANTERIORES

Pero existe:

primer_club

Mostrar:

Tu primer club

Subtítulo:

El instituto, por dentro.

⸻

SI NO EXISTE NINGUNO

Mostrar:

El instituto

Subtítulo:

Los de siempre, un poco más altos.

⸻

RECUERDO 4 — GRADUACIÓN

Si existe:

graduacion

Mostrar:

Tu graduación

Subtítulo:

Beltrán casi sonrió.

⸻

MICROFLASHBACK

La ceremonia.

Profe Beltrán.

Compañeros.

Familia.

El jugador recibe el título.

No mostrar un montaje genérico.

Mostrar un pequeño momento concreto.

⸻

SI NO EXISTE graduacion

Pero existe:

primer_contrato

Mostrar:

Tu primer contrato

Subtítulo:

La primera nómina, enmarcada.

Pausa.

Durante un tiempo.

⸻

SI NO EXISTEN AMBOS

Mostrar:

Tus primeros trabajos

Subtítulo:

Lola gritaba en la cocina y abrazaba fuera.

⸻

RECUERDO 5 — ABU

Si existe:

atardecer_con_abu

La música cambia ligeramente.

Música: Emocion

Rótulo

El atardecer con tu abu

Subtítulo:

Playa Dorada.

⸻

MICROFLASHBACK

Abu y el jugador sentados mirando el mar.

No hablar inmediatamente.

Solo sonido de agua.

⸻

Si promesa_abu = Volver

Volviste cada año.

Pausa.

Contigo o por ti.

⸻

Si promesa_abu = CosasBonitas

Hiciste cosas bonitas.

Pausa.

Muchas.

⸻

Si promesa_abu = Familia

Cuidaste de la familia.

Pausa.

Como te cuidó a ti.

⸻

SI NO EXISTE atardecer_con_abu

Pero existe:

el_reencuentro

Mostrar:

El reencuentro

Subtítulo:

La cafetería de Omar.

⸻

SI NO EXISTE NINGUNO

Mostrar:

Tu familia

Subtítulo:

Los que te enseñaron a andar.

⸻

EL ÁLBUM SE CIERRA

El jugador adulto cierra lentamente el álbum.

Silencio.

Durante unos segundos parece que está solo.

Entonces:

tocan la puerta.

⸻

ESCENA 3 — LA GENTE QUE SE QUEDÓ

El jugador gira.

La puerta se abre.

Entran progresivamente personajes importantes de su vida.

No deben aparecer todos de golpe.

⸻

Nico

Entra primero.

Nico

¿Qué?

Pausa.

¿Pensabas mirar el álbum sin nosotros?

Sonríe.

Se acerca.

⸻

Omar

Entra detrás.

Lleva una bolsa.

Omar

He traído bocadillos.

Pausa.

Por los viejos tiempos.

Mira alrededor.

Y por los nuevos.

Deja la bolsa.

⸻

Sara

Entra.

Mira la habitación.

Sara

Todos aquí.

Pausa.

Estadísticamente, un milagro.

Mira al grupo.

Emocionalmente, lo normal.

⸻

Si existe primer_grupo

Sara mira a los demás.

Sara

Grupo completo.

Pausa.

Que conste en acta.

⸻

PROFE LUCÍA

La puerta vuelve a abrirse.

Profe Lucía entra.

Mira al jugador.

Profe Lucía

Cuarenta cursos dando clase.

Pausa.

Y de esa clase me acuerdo de todo.

Mira alrededor.

No se lo digáis a nadie.

Sonríe.

⸻

ABU

Si corresponde al estado de historia, Abu entra o aparece sentado previamente.

No hacer una entrada teatral.

Simplemente:

Abu

Te has hecho mayor.

Pausa.

Sonríe.

Ya era hora.

⸻

DIÁLOGO SEGÚN PROMESA

promesa_abu = CosasBonitas

Abu mira alrededor.

Abu

Y que se note que eres feliz haciéndolas.

⸻

promesa_abu = Familia

Omar mira al jugador.

Omar

Has cuidado de todos.

Pausa.

Como le prometiste a tu abu.

⸻

promesa_abu = Volver

Omar sonríe.

Omar

Este año también has ido a la playa, ¿verdad?

Pausa.

Omar

Claro que sí.

Sonríe.

Siempre vas.

⸻

PROMESA ADULTA

Si:

promesa_adulta = Viaje

Nico mira al jugador.

Nico

Y todavía me debes el viaje a Villaverde.

Pausa.

Ya no tenemos treinta.

Mira un balón.

Pero el balón sí.

⸻

VARIANTE promesa_adulta = Hijos

El álbum permanece abierto.

Se escucha una voz infantil fuera de cámara.

La cámara gira.

Una hija del jugador aparece con el álbum.

Narrador

Tu hija te espera con el álbum.

Pausa.

Tu nieta ya lo ha abierto por la mitad.

⸻

VARIANTE NORMAL

Narrador

Dentro te espera el álbum.

Pausa.

Alguien lo ha dejado abierto por el principio.

⸻

MOMENTO COLECTIVO

Todos permanecen en la habitación.

No deben quedarse congelados.

Cada NPC realiza pequeñas acciones:

* Nico mira fotografías;
* Omar reparte bocadillos;
* Sara organiza las fotos;
* Profe Lucía observa a los antiguos alumnos;
* Abu se sienta;
* los padres hablan en segundo plano;
* los amigos recuerdan historias.

No convertirlo en una fila de NPCs esperando diálogo.

⸻

RECUERDOS DINÁMICOS

Durante esta escena, si existen recuerdos especiales, los personajes pueden comentarlos.

Ejemplos:

Si ayudaste a Mateo

Mateo aparece brevemente.

Mira una foto.

Mateo

Pensar que todo empezó porque se me cayeron unos libros.

Sonríe.

Menudo desastre.

⸻

Si existe conoces_a_leire

Leire observa una fotografía.

Leire

Esa foto sigue siendo mi favorita.

Pausa.

Nunca te la enseñé.

Sonríe.

Ahora sí.

⸻

Si existe el_cruce

Nerea puede mirar al jugador.

Nerea

Aquel día podrías haber elegido cualquier camino.

Pausa.

Elegiste el tuyo.

⸻

CONEXIÓN CON LA GRIETA

No convertir la Saga de la Grieta en protagonista de esta misión.

Pero sí puede existir un pequeño guiño.

Si:

saga_grieta_completada = true

Pip aparece en la puerta.

Todos lo miran.

Pip

He traído una fotografía.

La coloca sobre la mesa.

Es una foto de:

Cosme, Cósimo, Pip y el jugador.

⸻

Nico

¿Quién hizo esa foto?

Pip:

Yo.

Pausa.

Salgo muy bien.

⸻

Omar

¿Y Cosme?

Pip:

En el garaje.

Pausa.

Dice que está inventando un tostador.

Todos se quedan en silencio.

Sara

Otra vez.

Pip:

Otra vez.

⸻

MOMENTO EMOCIONAL PRINCIPAL

La cámara se aleja lentamente.

Dolly

Todos alrededor de la mesa.

El jugador en el centro.

No porque sea el Ancla.

Porque es su casa.

⸻

Narrador

Toda una vida.

Pausa.

Una ciudad.

Pausa.

Personas que llegaron.

Pausa.

Personas que se fueron.

Pausa.

Personas que se quedaron.

La cámara muestra fotografías.

Narrador

Y todavía queda mucho por vivir.

⸻

PASO 3 · MOMENTO

«Toda una vida en Valmar. Y todavía queda mucho por vivir.»

La cinemática termina.

No cortar inmediatamente a un menú.

El jugador recupera el control.

⸻

GAMEPLAY POST-CINEMÁTICA

Durante aproximadamente 60 segundos:

* puede caminar por la casa;
* mirar fotografías;
* hablar opcionalmente con familiares;
* hablar con amigos;
* volver a abrir el álbum;
* interactuar con objetos de la infancia.

Cada fotografía importante puede mostrar:

Recordar

Al activarlo:

microflashback de 2–4 segundos.

⸻

SISTEMA DE MEMORIA FINAL

Al interactuar con el álbum aparece:

MI VIDA

Con una línea temporal:

NACIMIENTO
↓
PRIMEROS PASOS
↓
COLEGIO
↓
AMIGOS
↓
INSTITUTO
↓
DECISIONES
↓
UNIVERSIDAD
↓
PRIMER TRABAJO
↓
VIDA ADULTA
↓
LA GRIETA
↓
VALMAR
↓
HOY

Los eventos realmente vividos aparecen desbloqueados.

Los que no se vivieron no aparecen como “fallidos”.

Simplemente no están.

⸻

RECOMPENSA

Al completar:

Adulto_MirarAtras = true
vida_mirada_atras = true

Biografía:

«Miraste atrás: toda una vida en Valmar»

⸻

CIERRE DE LA MISIÓN

Cuando el jugador salga de la casa:

La cámara muestra Los Pinos.

Atardecer.

La ciudad sigue funcionando.

Personas caminando.

Coches.

Niños jugando.

Alguien abre una tienda.

Un autobús pasa.

La vida continúa.

⸻

ÚLTIMA FRASE

Narrador

Toda una vida en Valmar.

Pausa.

Y la historia sigue.

Pausa.

Porque la ciudad no se para.

Música: Calma

Fade out.

⸻

CONEXIÓN CON EL JUEGO LIBRE

No mostrar:

«HAS TERMINADO EL JUEGO»

Mostrar:

TU VIDA CONTINÚA

El jugador vuelve al mundo abierto.

A partir de aquí:

* trabajar;
* comprar;
* viajar;
* crear relaciones;
* explorar;
* practicar deportes;
* utilizar el transporte;
* comprar propiedades;
* participar en actividades;
* ayudar a NPC;
* descubrir nuevas historias;
* continuar la vida adulta.

La historia principal termina.

La vida no.

⸻

QA OBLIGATORIO

Antes de dar esta misión por terminada:

Continuidad

* El nombre del grupo debe aparecer correctamente.
* Las promesas de Abu deben coincidir con las decisiones reales.
* No mostrar recuerdos que el jugador nunca consiguió.
* No mostrar personajes que estén marcados como ausentes/muertos si el sistema contempla ese estado.
* La Saga de la Grieta debe aparecer solo si realmente se completó.
* El álbum debe respetar el orden cronológico.
* No duplicar personajes.
* No duplicar diálogos.

Cámara

Después de cada microflashback:

restore_player_camera()
restore_player_controls()
restore_player_hud()

NPC

Ningún personaje debe quedarse congelado durante la reunión.

Todos deben tener:

* idle;
* mirada;
* respiración;
* pequeños desplazamientos;
* interacción con objetos;
* reacción a otros personajes.

Guardado

Al completar:

save_story_state()
save_memory_album()
save_relationship_states()
save_life_choices()

El jugador debe poder cerrar sesión y conservar el álbum exactamente igual al volver.

⸻

OBJETIVO EMOCIONAL FINAL

El jugador debe terminar pensando:

«He vivido esta vida.»

No:

«He terminado una misión.»

Ese es el objetivo de Adulto_MirarAtras.
