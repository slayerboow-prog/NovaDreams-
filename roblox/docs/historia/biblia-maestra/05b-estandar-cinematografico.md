# Biblia Maestra · Volumen V-b — Estándar cinematográfico de HEROES OF HISTORY

> Referencia oficial. Amplía el Volumen V (`05-cine.md`).
> Origen: seis imágenes de referencia que entregó el dueño el 18-11-2026 (conversación, expresión, movimiento,
> escenario, emoción y transición a jugabilidad).
> **Regla:** se aprenden las **técnicas** (encuadre, lente, luz, actuación, montaje). Nunca se copian escenas,
> personajes, composiciones concretas ni el aspecto de otras obras. HEROES OF HISTORY tiene su propia identidad: sus
> personajes, sus ocho mundos, su azul de Sello y su gris del Coro.

**Prioridades del dueño, en orden:**
1. calidad cinematográfica;
2. expresividad de los personajes;
3. movimientos de cámara naturales;
4. continuidad entre planos;
5. compatibilidad y rendimiento en Roblox;
6. transiciones invisibles entre cinemática y jugabilidad.

---

## 1. Análisis de las seis referencias

### R1 · Conversaciones
**Qué se ve.**
- **Plano sobre el hombro.** La nuca y el hombro del que escucha ocupan un tercio del encuadre, desenfocados, en primer
  término. La cara del que habla está en el tercio contrario, enfocada.
- **Luz lateral motivada** por una ventana con persianas: la cara queda medio en luz y medio en sombra, con franjas.
- Lente algo larga (fondo comprimido), cámara a la altura de los ojos y un actor que no mira a cámara.

**Principios que se extraen.**
1. **El que escucha está en el plano:** la conversación es una relación, no un monólogo.
2. **La luz viene de algo que existe en la escena** (una ventana, una lámpara, la lava) y esculpe la cara.
3. **Profundidad:** un primer término desenfocado, el actor y el fondo.

**En HEROES OF HISTORY.**
- Ejemplo: Kael y Brenn en el taller de la Academia. La luz entra por una ventana tapiada con tablones y forma franjas
  en la cara de Kael (la persiana se convierte en tablones de chatarra: es nuestra estética).
- En el motor: `Hombro:Brenn>Kael` con `Fov` 40-45, luz clave lateral (§4) y el desenfoque de fondo que ya hace
  `DayLight` en las escenas.

### R2 · Expresiones
**Qué se ve.**
- **Primer plano** de un hombre mayor, mirando abajo y a un lado.
- **Luz suave** desde arriba y un lado, con mucha sombra en el resto.
- Colores apagados.
- La emoción está en la **mirada baja, la frente y la quietud**, no en una mueca.

**Principios.**
1. **La emoción se contiene.** Una mirada baja dice más que un gesto grande.
2. **Fondo oscuro y cara iluminada:** nada compite con el rostro.
3. **Quietud:** la cámara casi no se mueve en el momento emocional.

**En HEROES OF HISTORY.**
- Ejemplos: Corvo cuando sus hijos le hablan con una sola voz; Ithar cuando dice «El Coro olvida».
- En el motor: `PrimerPlano:X` con `Fov` 30-35, `Beat = Suelo` o `Pensar`, `Pause` de 1,5-3 s, `Light = Intima` o
  `Tension` y fondo apagado.
- **Límite de Roblox:** las caras tienen pocas expresiones (§5). La emoción se apoya en la **mirada (`Look`), la
  postura, la luz y la duración del plano**.

### R3 · Movimiento de cámara
**Qué se ve.**
- **Plano de seguimiento por detrás:** la cámara va baja, detrás del personaje, que camina hacia unas ruinas en la
  selva.
- Helechos en primer término a los lados enmarcan el camino. Rayos de luz al fondo.
- El personaje está centrado y pequeño frente al lugar.

**Principios.**
1. **La cámara acompaña, no exhibe.** Se mueve porque se mueve alguien.
2. **El entorno enmarca:** la vegetación o las ruinas en primer término dan profundidad y dirección.
3. **La luz al final del camino** dice adónde vamos.

**En HEROES OF HISTORY.**
- Ejemplos: entrar en el Sur muerto detrás de Brenn; bajar hacia la cámara de la Semilla en Umbría.
- En el motor: `Seguir:X` con un desplazamiento bajo y detrás (altura de hombro o menos), `Fov` 55-60, `Shake` 0,15
  (cámara en mano muy suave) y piezas de decorado en primer término.

### R4 · Escenarios
**Qué se ve.**
- **Gran plano general de establecimiento:** una fortaleza sobre una montaña de cristal o hielo junto al agua.
- Nubes enormes, luz rasante, la ciudad diminuta a sus pies. Horizonte bajo y mucho cielo.

**Principios.**
1. **Escala:** lo construido por el hombre es pequeño frente al mundo, o al revés, frente a una obra colosal.
2. **Una silueta reconocible** por mundo: el plano tiene que poder ser la portada del planeta.
3. **Cielo como actor:** las nubes y la luz cuentan el estado del mundo.

**En HEROES OF HISTORY.**
- Cada mundo tiene **su plano de establecimiento canónico** (§9):
  - la Gran Cúpula y la Lanza en Tefra;
  - el sol apagado sobre Fortaleza Albor;
  - la torre MegaVerso bajo la cúpula.
- **Nunca se reutiliza la composición de la referencia:** cada silueta es la del Vol. IV.
- En el motor: `Travelling` alto y lento, u `Órbita` amplia, con `Fov` 60-70, 6-10 s y el `Ambience` del sitio.

### R5 · Emociones y sacrificios
**Qué se ve.**
- **Plano medio de dos personas abrazadas** en un paisaje.
- Ruinas de una ciudad al fondo, desenfocadas. Luz natural, suave, de día nublado.
- La cámara está **cerca, pero sin invadir**.

**Principios.**
1. **La intimidad dentro del mundo:** el fondo recuerda qué han perdido.
2. **Luz natural y fría:** la emoción no se subraya con colores cálidos falsos.
3. **Distancia respetuosa:** primero un plano medio y, solo después, un primer plano si hace falta.

**En HEROES OF HISTORY.**
- Ejemplos: Noa e Irene abrazadas; Brenn sosteniendo a Tomás; la muerte de Kael (S11).
- En el motor: `DosPlanos:A,B` con `Fov` 45-50, `Music = Nada` o el tema íntimo, `Light` según el planeta (nunca
  `Atardecer` dorado en una muerte) y `Dolly` reverso lento para dejar a los personajes solos al final.

### R6 · Transición a jugabilidad
**Qué se ve.**
- **El personaje de espaldas, por encima del hombro**, mirando un valle inmenso.
- **Es exactamente la posición de la cámara de juego.** La cinemática termina donde empieza el control.

**Principios.**
1. **El último plano es la cámara de juego** (el «plano de enganche»). Así no hay corte entre ver y jugar.
2. **Mirar hacia el objetivo:** el plano final orienta al jugador hacia donde tiene que ir.
3. **El mundo invita:** el paisaje abierto delante es la siguiente misión.

**En HEROES OF HISTORY:** toda escena B o C termina en un plano de enganche (§8).

---

## 2. El estándar: diez reglas del lenguaje de HEROES OF HISTORY

1. **La cámara es un testigo, no un dron.** Se mueve porque alguien se mueve o porque algo pasa. Nunca vuela sin
   motivo.
2. **Toda luz tiene origen:** una ventana, el fuego, la lava, un farol, el Sello. La cara del que importa siempre está
   en la luz.
3. **Tres términos en cada plano:** primer término (un hombro, una raíz, un helecho, una barandilla), sujeto y fondo.
4. **La emoción se contiene.** Una mirada, una pausa o una postura. Nada de muecas ni de discursos que expliquen lo que
   se siente.
5. **Quien escucha también actúa.** Cada frase importante tiene su plano de reacción.
6. **Un eje por conversación** (180°). Se cruza solo con un movimiento de cámara visible, nunca con un corte.
7. **El silencio va antes de la verdad:** de 1 a 3 s, sin música.
8. **Escala humana frente al mundo.** Las presentaciones de lugares hacen pequeño al personaje; las emociones lo hacen
   grande.
9. **Cada mundo tiene su luz** (Vol. IV). El azul de Sello es esperanza; el gris del Coro es pérdida; no se mezclan
   sin motivo.
10. **El último plano es jugable:** toda escena termina donde empieza el control.

---

## 3. Escalera de lentes, alturas y distancias (para personajes R15 de unos 5 studs)

| Plano | `Fov` | Distancia al sujeto | Altura de cámara | Duración típica | Referencia |
|---|---|---|---|---|---|
| Establecimiento | 60-70 | 80-400 studs | Alta o rasante | 6-10 s | R4 |
| General de acción | 55-65 | 25-40 | A la altura del pecho | 3-6 s | — |
| Seguimiento | 55-60 | 6-9, detrás | Hombro o más baja | Mientras dura el paseo | R3 |
| Plano medio | 45-50 | 6-8 | Ojos | 3-6 s | R5 |
| Sobre el hombro | 40-45 | 4-6 desde el hombro | Ojos | 2-5 s | R1 |
| Primer plano | 30-35 | 3-4 | Ojos o un poco por debajo (dignidad) | 2-4 s | R2 |
| Primerísimo primer plano | 22-28 | 2-3 | Ojos | 1,5-3 s, muy pocas veces | R2 |
| Enganche | El de juego (70) | La cámara de juego | La cámara de juego | 0,5-1 s | R6 |

**Reglas de lente:**
- Los planos largos y lentos van con `Fov` abierto.
- La emoción va con `Fov` cerrado.
- Nunca un zoom digital rápido (`Fov` de 70 a 30 en menos de 2 s), salvo en un golpe de terror deliberado.

---

## 4. Iluminación de escena

| Tipo de escena | Luz clave | Relleno | Contraluz (borde) | Ajuste del motor |
|---|---|---|---|---|
| Conversación de interior | Lateral, desde la fuente real (ventana, farol) | Bajo; un lado de la cara en sombra | Suave, desde la fuente opuesta | `InteriorCalido` o `Intima` |
| Conversación tensa | Lateral dura | Casi nulo | Frío | `Tension` |
| Emoción o muerte | Suave, desde arriba, fría o neutra | Medio | Débil | `Intima`; nunca `Atardecer` |
| Establecimiento | La del planeta y su hora | — | — | Perfil de `EnvDirector` del planeta |
| El Coro | Sin sombra, gris perla | Total | Ninguno | `Ceniza` o `Sueno` |
| El Sello | Azul desde el Sello (abajo o al frente) | Bajo | Azul | `Grieta` más un `Neon` de la pieza |

**Desenfoque de fondo** (ya existe en `DayLight`):
- Nivel gráfico **Alto:** siempre suave, y más en las escenas.
- Nivel **Medio:** solo en escenas y conversaciones.
- Nivel **Bajo:** nunca.
- En los primeros planos, el sujeto queda nítido y el fondo desenfocado.

**Se mantiene.**

---

## 5. Expresividad de los personajes en Roblox

| Recurso | Estado | Uso |
|---|---|---|
| **Mirada** (`Look`: a quien habla, al suelo, a otro lado, a un ancla) | ✅ | La herramienta principal. Mirar al suelo = vergüenza; apartar la vista = mentira o dolor. |
| **Emoción duradera** (`Mood`: Calm, Fear, Angry, Surprise, Joy, Sad, Hurt, Nervous, Shame) | ✅ | Postura y gesto base de la escena |
| **Pausas y Beats** (Mirar, Suelo, Apartar, Pensar, Respirar) | ✅ | El tiempo de la emoción |
| **Boca al hablar** (`FaceControls`: JawDrop) | ✅ en cabezas que lo tienen | Se mantiene |
| **Expresión facial** (cejas, ojos, párpados con `FaceControls`) | 🆕 auditoría | Ampliar `ActorLife` para que `Mood` y `A` muevan cejas y párpados en las cabezas que tengan `FaceControls`. **Si no se puede en todo el reparto, solo en los protagonistas.** |
| **Posturas** (brazos cruzados, tocar el auricular, apoyarse en el bastón, arrodillarse, sujetar la compuerta) | 🆕 (Vol. V §7.1) | El gesto propio de cada personaje (Vol. II) |
| **Respiración en reposo** | 🆕 | Un leve movimiento del pecho y los hombros en planos largos: nadie es una estatua |

**Regla de actuación.** Un gesto por frase como mucho. Las emociones grandes se hacen con quietud, mirada y luz,
nunca con un gesto exagerado. Es lo que mejor funciona con el estilo de los avatares de Roblox y lo que hace adulta la
escena.

---

## 6. Movimiento de cámara

| Permitido | Valores | Para qué |
|---|---|---|
| Travelling lento | 0,5-2 studs/s | Establecimiento, acercamiento emocional |
| Seguimiento | La velocidad del actor | Caminar con alguien (R3) |
| Órbita | ≤ 8°/s | Revelar un lugar o una figura |
| Dolly in / out | 0,3-1 studs/s | Acercarse a la verdad / dejar solos a los personajes |
| Cámara en mano | `Shake` 0,1-0,3 | Tensión, documental, caos |
| Panorámica | ≤ 15°/s | Seguir una mirada hacia algo |

**Prohibido:**
- órbitas rápidas sin motivo;
- zooms digitales bruscos;
- «vuelos de dron» que atraviesan techos;
- cámara que tiembla en escenas tranquilas;
- cortes en mitad de un movimiento sin una razón de montaje.

---

## 7. Montaje y continuidad

1. **Eje de 180°** en toda conversación. Ya lo cuida el motor con `Hombro:X>Y` y las anclas compuestas.
2. **Raccord de mirada:** si A mira a B fuera de campo hacia la derecha, en el contraplano B mira hacia la izquierda.
3. **Corte en el movimiento:** se corta cuando alguien se gira, se levanta o abre una puerta.
4. **Dirección de pantalla del viaje:** en las escenas, los viajes **hacia Oren** (hacia la verdad) van de izquierda a
   derecha y las huidas de derecha a izquierda. Así, el espectador siente sin saberlo hacia dónde avanza la historia.
5. **Continuidad de luz:** la misma luz clave en todos los planos de una escena. Si cambia, tiene que verse por qué
   (una explosión, un farol que se apaga).
6. **Duración mínima:** 1,5 s por plano, salvo un golpe de acción.
7. **Cortes de audio adelantados:** la voz del siguiente plano empieza un instante antes del corte de imagen. Es
   posible con `At` y `Pause`, y hace las conversaciones fluidas.
8. **Transiciones:**
   - `Cut` por defecto;
   - `Dip` (negro breve) para un salto de tiempo;
   - `Fade` lento para cerrar un capítulo;
   - `Flash` solo para un impacto o un recuerdo.

---

## 8. Transiciones invisibles entre cinemática y jugabilidad

**Entrada sin corte:**
- la cámara de juego **viaja** al primer plano de la escena (de 0,6 a 1 s) en vez de cortar;
- las bandas de cine entran a la vez;
- el personaje no se detiene en seco: termina el paso.

**Salida, el plano de enganche** (R6):
- el último plano se coloca **en la posición y la orientación de la cámara de juego**, detrás del hombro del jugador
  y **mirando hacia el siguiente objetivo**;
- la interfaz vuelve con un fundido de 0,4 s;
- el control se devuelve **en movimiento**: si la escena termina caminando, el jugador ya está caminando.

**Estado del motor:**
- `CineCamera.restore` ya hace una vuelta suave de ~1 s desde el último plano hasta detrás del jugador.
- **Falta** (🆕, capacidad 7.9):
  1. un tipo de plano **«Enganche»**: si el último plano ya está en la pose de juego, la vuelta es una mezcla de 0,3 s
     sin viaje;
  2. la **orientación final hacia el objetivo** (la 7.7 del Vol. V).

**Escenas de nivel A** (las del mundo): nunca quitan el control ni la cámara. Se muestran en el mundo y el jugador
decide si mira.

---

## 9. Plano de establecimiento canónico de cada mundo (la «portada»)

| Mundo | Composición propia (no imitada) | Luz |
|---|---|---|
| Valmar | Desde la muralla de contenedores: torres rotas, la Raíz Mayor bajo el asfalto y los Arcos del Jardín hacia la copa del Árbol en el horizonte norte | Atardecer naranja sucio |
| Tefra | Ovilla en medio cielo; la muralla negra y el foso; las costillas de la Gran Cúpula; la Lanza en el centro | Malva y naranja de lava |
| Miasma | Los discos colgados del pico sobre la niebla verde con relámpagos | Verdosa difusa |
| Siroco | El cañón rojo con toldos y, al fondo, la Esfinge Ciega en la arena | Mediodía blanco |
| Nivalis | La fortaleza con su collar de faroles en la nada y el anillo apagado del sol sobre la montaña | Noche, luna y aurora |
| Umbría | Troncos que se pierden en la niebla y, en el centro, el árbol madre gris hasta media altura | Verde filtrado |
| Tálasa | Las cubiertas sobre pilotes y, bajo la superficie, la cúpula hundida y la fosa negra | Sol blanco, azul profundo |
| Vértice | La torre MegaVerso bajo los paneles de la cúpula y las pantallas con la misma cara | Neón perfecto |
| Oren | Las multitudes de piedra mirando a las puertas apagadas y el Árbol Primero al fondo | Gris sin sombra |

---

## 10. Las 15 grandes secuencias con este estándar

| Secuencia | Referencias que mandan | Ajuste respecto al Vol. V |
|---|---|---|
| S1 La caída de Valmar | R4, R3 | El seguimiento de Tomás es bajo y por detrás (R3); termina en el establecimiento del Sur apagándose (R4) |
| S2 Los Velados | R4, R2 | El giro a la vez se ve en un plano general **quieto** (la quietud asusta) |
| S3 El descubrimiento de Tomás | R1, R2 | Sobre el hombro de Brenn (R1); primer plano de Brenn sin gesto (R2) |
| S4 La llegada a Tefra | R4 | Plano canónico de Tefra (§9) |
| S5 Cosme y Lía | R5, R2 | Dos planos con el puente detrás; el primer plano de Cosme **sin chiste** |
| S6 La verdad del Coro | R2, R4 | Primer plano de Luz en la pausa de tres segundos; el friso como establecimiento interior |
| S7 El sol de Nivalis | R4, R6 | Termina en enganche con la ciudad bañada de luz delante |
| S8 Sorel | R2, R5 | Cuatro primeros planos quietos a lo largo del juego: el mismo encuadre cada vez, para que se note el cambio |
| S9 Lys | R3, R2 | Seguimiento bajando por las raíces (R3) hacia la luz |
| S10 La traición de Ilse | R1, R3 | Seguimiento de Ilse por los pasillos; el plano de su mano en la palanca, quieto |
| S11 La muerte de Kael | R5, R2 | Plano medio y respetuoso; el primer plano solo en las últimas palabras; dolly reverso al final |
| S12 El asalto a Vértice | R4 | Plano canónico de Vértice; la flota con los temas de cada planeta |
| S13 Ithar | R1, R2 | Hombros alternos; un primer plano de Ithar con luz de Sello en la mitad de la cara |
| S14 Oren | R4, R3 | El plano general de 10 s y un seguimiento entre las figuras |
| S15 Los finales | R5, R6 | Cada final termina en un enganche: el jugador vuelve a tener el control en el mundo cambiado |

---

## 11. Rendimiento en Roblox

| Recurso | Regla |
|---|---|
| Efectos de imagen (desenfoque, color, bloom, rayos) | Según el nivel gráfico (ya existe en `DayLight`); en móvil bajo, sin desenfoque |
| Luces de escena | Como mucho 3 luces nuevas por plano (clave, relleno y contraluz), siempre `Shadows = false` salvo la clave en nivel Alto |
| Partículas | ≤ 6 emisores propios de la escena a la vez |
| Actores | ≤ 8 actores con animación a la vez en una escena C; los extras, quietos o con poca animación |
| Carga del lugar | Las anclas de la escena tienen que estar cargadas antes de empezar: se pide la zona de la escena **solo a pie**. **Nunca** se fuerza la ciudad bajo la nave ni se aclara la bruma de vuelo (regla del proyecto). |
| Duración | Escena B: 30-90 s · Escena C: 1-3,5 min · Ninguna escena C seguida de otra C |

---

## 12. Lista de comprobación de cada escena (antes de darla por buena)

- [ ] ¿Empieza con un viaje de cámara desde el juego, sin corte seco?
- [ ] ¿Cada plano tiene tres términos (primer término, sujeto y fondo)?
- [ ] ¿La luz tiene un origen visible y la cara importante está en la luz?
- [ ] ¿Se respeta el eje y el raccord de mirada?
- [ ] ¿La frase importante tiene pausa antes y plano de reacción después?
- [ ] ¿La emoción se cuenta con mirada, postura y luz, no con explicaciones?
- [ ] ¿Ningún personaje está quieto más de 20 s?
- [ ] ¿La música calla cuando debe?
- [ ] ¿Termina en un plano de enganche, mirando hacia el objetivo?
- [ ] ¿Cumple los límites de rendimiento del §11?
- [ ] ¿Se puede saltar sin perder ninguna decisión?

---

## 13. Capacidades nuevas que añade este estándar (auditoría previa obligatoria)

| # | Capacidad | Sistema |
|---|---|---|
| 7.9 | Plano **Enganche** y vuelta sin viaje | `CameraShots` y `CineCamera.restore` |
| 7.10 | Luz por plano (clave, relleno y contraluz como piezas temporales) | `StoryFx.setLight` o una pista nueva |
| 7.11 | Expresión facial con `FaceControls` (cejas y párpados) a partir de `Mood` y `A` | `ActorLife` |
| 7.12 | Respiración en reposo para actores de escena | `ActorLife` |
| 7.13 | Entrada sin corte (de la cámara de juego al primer plano) | `HappeningClient` y `CineCamera` |

Se suman a las 7.1-7.8 del Vol. V.

**Orden recomendado:** 7.9, 7.13 y 7.7 (las transiciones invisibles, prioridad 6 del dueño), luego 7.11 y 7.12 (la
expresividad, prioridad 2), y después 7.10.
