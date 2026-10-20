# Revisión por cinemática (formato A–P del encargo)

Revisión de las **24 escenas más importantes de la historia principal**: aperturas y cierres de capítulo,
despedidas (contadas para +13: nadie muere en pantalla), las fases de la Grieta y el final. Hecha junto a
las fases 3, 4 y 5 del sistema de cine (`docs/cine/auditoria-sistema.md`).

**Cómo se ha revisado.** Leyendo cada escena y con dos herramientas, sin Studio:

- `lune run scripts/audit/cine-revision.luau --lista --hoja` (nueva): duración, planos (el más corto y los
  **huecos sin plano**, en los que la cámara se queda quieta), frases que **no dan tiempo a leerse** antes
  de la siguiente, frases que salen **a la vez que un rótulo**, reacciones escritas (emoción, gesto, mirada),
  **silencio** de 2 s después de cada golpe (impacto, explosión, portal, trueno) y quien **habla sin estar
  en la escena**; y lo que hay en cada pista (actores, efectos, música, ambiente, luz, mundo).
- `test-cineplanos` contra el mapa construido: cámara dentro de algo, tapada, cortando a alguien, saltando
  el eje, actores metidos unos en otros… también llegando desde otros lados y en vehículo.

**Probado visualmente: nada** (ninguna se ha visto en Studio ni en un móvil). Lo que dice cada hoja sale del
código, de las cuentas y de la auditoría geométrica.

Leyenda de las hojas: **A** objetivo · **B** contexto · **C** personajes · **D** guion · **E** planos ·
**F** diálogos · **G** animaciones · **H** efectos · **I** sonido · **J** mundo · **K** misiones ·
**L** archivos · **M** implementación · **N** pruebas · **O** pendiente · **P** cómo validarla. «Motor» =
escena del motor (`Happenings`/`HappeningClient`); «vieja» = cinemática de `Cinematics.luau` (pasan al
motor en la fase 6); «generada» = sale de un guion reescrito (`docs/historia/reescritura/*.md`: se cambia
en el `.md` y se regenera, nunca a mano).

## Resumen de los arreglos

| Escena | Problema encontrado | Arreglo |
|---|---|---|
| Grieta_Caen | Sin silencio tras el impacto (el narrador hablaba al caer), impactos 2 y 3 fuera de cámara, sin reacciones de la gente del barrio, el temblor antes de nada | Rehecha como **meteorito en 10 pasos** (fase 5): avisos, cielo, estela, tres impactos cada uno en su plano, silencio de ~4 s (sin música, ambiente ni frases), vecinos que huyen y uno que vuelve a ayudar, Chispa rompe el silencio, rótulo y búsqueda. La valla del patio queda rota (memoria del mundo) |
| Grieta_Caen | (test-cineplanos) la órbita del parque cruzaba la valla del cole y pasaba por encima de Chispa | Plano fijo desde el sitio del impacto; Chispa huye alejándose de la cámara |
| Grieta_Coser | Cosme hablaba en el mismo segundo en que volvía la luz tras el apagón | Silencio de 2,5 s antes de su frase; la música del tema entra con ella |
| Grieta_Coser / Grieta_Rota | No dejaban nada en el mundo | La marca de la aguja en el patio (azul → roja cuando se rompe la costura → blanca al final) y las losas levantadas donde aterriza Cósimo (roto → en obras → arreglado) |
| Grieta_Final | 1,2 s sin plano entre Cósimo y la reacción de Cosme (la cámara se quedaba quieta) | El plano de Cósimo dura hasta la reacción; el plano de dos, hasta el de Cósimo |
| Uni01_Campus | 3,5 s sin plano mientras habla el narrador | El travelling del primer día dura lo que su frase |
| Uni06_Final | Despedida con Abu casi sin actuación (2 reacciones); el plano de dos con Abu no cabía en la cafetería (3 avisos de test-cineplanos) | Emociones y miradas de Lola, tu familia, Omar y Abu; Abu se inclina y pregunta con la cabeza; plano por encima de tu hombro |
| Montajes de capítulo (`Etapas.luau`) y Vida_MirarAtras | La frase de una foto la decía «Omar»/«Abu» del reparto, que no está en la escena (está su actor de foto, `N21_Omar`): no hablaba con el cuerpo ni le miraban | La frase la dice el actor de la foto |
| Todas las generadas | Casi ningún gesto escrito | Fase 4: 1919 acotaciones en sus `.md` (75 % de los turnos) |

Lo que **no** se ha tocado y por qué está en cada hoja (O). Los huecos de plano de menos de 1 s y los de
un fundido a negro se dejan (la cámara se queda en el último encuadre, que es un plano quieto válido).

## Hojas

### 1. Prologo_Apertura (vieja)
- **A** Que el jugador entre en el sueño del prólogo: la Grieta existe y algo te espera. **B** Primera escena
  del juego (`Prologo_Sueno`). **C** Narrador. **D** Tres planos de la isla del sueño con tres frases.
- **E** 3 planos, 26,5 s (el más corto 7 s): ritmo lento, de sueño. **F** 3 frases, sin solaparse.
  **G** Ninguna (no hay personajes). **H** Cielo del sueño. **I** Música del prólogo. **J** — **K** Abre el
  prólogo. **L** `Cinematics.luau`, `Guiones/Prologo_Sueno.luau`. **M** Cinemática vieja.
- **N** `test-cinematic` (todas las viejas, saltándolas, lo devuelven todo), `test-reescritura` (el prólogo
  se juega entero con las dos respuestas). **O** Hecho en la fase 6: ya es escena del motor (`Happenings/Capitulos`, mismo id y contenido). **P** Partida nueva: los
  planos no atraviesan la isla y el texto se lee.

### 2. Bebe_NacimientoCuna (motor)
- **A** Naces: la primera imagen de tu familia y de Abu. **B** Sustituye a la vieja `Bebe_Nacimiento`.
  **C** Abu, tu familia. **D** De Los Pinos a la cuna; Abu da la bienvenida; «Ya estás en casa».
- **E** 9 planos, 37 s; 0,8 s quieto antes del último primer plano (se deja: es la pausa antes de «Ya estás
  en casa»). **F** 6 frases, ninguna pisada. **G** 5 reacciones (miradas a la cuna). **H** — **I** Ambiente
  de calle a casa, luz cálida. **J** — **K** Empieza la vida. **L** `Happenings/Colegio.luau`.
- **N** `test-scenes`, `test-cinematic`, `test-cineplanos` (sin avisos). **O** — **P** Vida nueva.

### 3. Bebe_PrimerosPasosAbu (generada)
- **A** Tus primeros pasos, hacia Abu. **B** `Bebe_AprendeACaminar`. **C** Tu familia, narrador.
- **E** 30 planos, 80 s. **F** 20 frases. **G** 12 reacciones (alegría, risa); fase 4 añade gestos a la
  familia. **J** — **L** `Guiones/Bebe_AprendeACaminar.luau` ← `.md`.
- **N** `test-reescritura`, `test-cineplanos`: 3 avisos conocidos (esquina estrecha de la sala: plano alto
  de último recurso y un corrillo cortado en el borde). **O** Esos 3: aceptables (ver «Excepciones»).
  **P** Etapa bebé, paso de andar.

### 4. Montaje_Bebe_Nino (motor, cierre de capítulo)
- **A** Cerrar la etapa bebé y abrir el colegio. **C** Abu, tu familia, Lucía, Nico, Sara, Omar y los
  actores de las fotos. **D** Abu arropa la cuna → fotos de recuerdos → seis años después, la puerta del cole.
- **E** 10 planos, 43 s. **F** 4 frases; una sale cuando aún se ve un rótulo (15,1 s): el reloj de la escena
  la espera (`SceneTiming`: rótulo primero, frase después). **G** 12 reacciones; saludos y risas en las fotos.
- **H** — **I** Íntima → tema de Valmar, «Pasan los años». **L** `Happenings/Etapas.luau`.
- **N** `test-etapas`, `test-transiciones`. **Arreglo** las frases de foto las dice el actor de la foto.
  **P** Acabar la etapa bebé.

### 5. Cole01_Bienvenida (generada, apertura del colegio)
- **A** El primer día: Lucía te recibe y conoces al grupo. **C** Lucía, Nico, Sara, Bruno.
- **E** 11 planos, 44,6 s. **F** 11 frases, sin pisarse. **G** 5 reacciones escritas antes; la fase 4 añade
  gestos en los `.md` (ver `Cole01_PrimerDia`: 79 gestos nuevos en el guion). **N** `test-reescritura`,
  `test-cineplanos` (sin avisos). **O** — **P** `Cole01_PrimerDia`.

### 6. Cole12_Despedida (generada, despedida)
- **A** Último día de colegio: despedida del grupo y de las familias. **C** Abu, familia, Nico, Sara, Omar,
  Mateo, Hugo, Iker. **E** 3 planos de cámara + los de cada frase, 52 s. **F** 12 frases. **G** 11
  reacciones + gestos de la fase 4.
- **N** `test-cineplanos`: 5 avisos conocidos (dos marcas escritas casi juntas, corrillo en sitio
  pequeño). **O** Mover marcas exige tocar el `.md` y el mapa de la misión; aceptables por ahora.
  **P** `Cole12_UltimoDia`, paso 22.

### 7. Cole12_FinDeEpisodio (generada, cierre)
- **A** «¡Los Imparables!»: el grito del grupo cierra el colegio. **E** 3 planos, 14,8 s; el primero dura
  1,4 s y la cámara se queda quieta 1,8 s antes del general. **G** 11 reacciones (todos celebran, las
  familias saludan). **O** Arreglado en la fase 6: el plano venía de la escena escrita a mano (`Happenings/Colegio.luau`);
  ahora dura hasta el grito (3,2 s) y se regeneró el guion. **P** Final de `Cole12_UltimoDia`.

### 8. Montaje_Nino_Adolescente (motor, cierre y apertura)
- **A** Del colegio al instituto, con tus recuerdos. **D** Fotos del grupo, del amigo al que ayudaste, del
  gran momento → tu casa la mañana del primer día. **E** 16 planos, 43 s. **F** 5 frases (una con rótulo a la
  vez: la espera el reloj). **G** 22 reacciones. **Arreglo** Omar decía «Juntos contra el puré» sin estar en
  la escena (el actor era `N21_Omar`): ahora la dice su actor de foto. **N** `test-etapas`.

### 9. Ins01_Parada (motor, apertura del instituto)
- **A** El reencuentro con el grupo, ya mayores, en la parada del bus. **C** Nico, Sara, Omar, Mateo, Hugo.
  **E** 19 planos, 55 s; 2,4 s quieta antes del claxon del bus (se deja: el plano se queda en el grupo
  esperando y el claxon lo corta). **F** 17 frases. **G** 25 reacciones (nervios de Sara y Hugo, Omar
  señala el bus). **I** Ambiente de calle, claxon. **N** `test-cineplanos` (sin avisos). **P** `Ins01`.

### 10. Ins06_Noche (motor, la noche antes de decidir)
- **A** Abu y tu familia te dicen «haz lo que te haga feliz». Escena íntima. **C** Abu, familia, narrador.
  **E** 27 planos, 113 s (el más corto 3,2 s). **F** 25 frases, ritmo lento con pausas, ninguna pisada.
  **G** 16 reacciones, posturas (triste, contenta), miradas al suelo y a ti escritas en cada frase.
  **I** Reloj de la casa, interruptor, luz de noche a cálida. **O** Bien resuelta; no se ha tocado.

### 11. Ins06_Graduacion (motor, cierre del instituto)
- **A** La graduación del instituto. **C** 12 personajes. **E** 25 planos, 104 s; 2,5 s quieta antes de la
  foto de la orla (el plano del momento anterior se queda) — aceptable. **F** 23 frases. **G** 20
  reacciones (celebrar, saludar). **I** Multitud, cámara de fotos, el tema. **P** Final de `Ins06`.

### 12. Uni01_Campus (motor, apertura de la universidad)
- **A** El primer día en el campus: Luca te recibe y aparece Sara. **E** 12 planos, 72,5 s.
  **Arreglo** el travelling del principio paraba a los 4,2 s y la cámara se quedaba quieta 3,5 s mientras
  hablaba el narrador: ahora dura 7,7 s. **G** 8 reacciones (Luca saluda y señala). **N** `test-cineplanos`:
  4 avisos conocidos (explanada con tu sitio aproximado). **P** `Uni01_PrimerDia`, paso 5.

### 13. Uni06_Ceremonia (motor)
- **A** Te dan el diploma. **C** Beltrán, Abu, familia y el equipo. **E** 20 planos, 103 s. **F** 18 frases;
  la de Beltrán sale con el rótulo «Tu diploma» (el reloj la retrasa hasta que el rótulo se va).
  **G** 8 reacciones (celebran). **I** Silencio de música («Nada») antes del nombre y luego resolución.
  **N** `test-cineplanos`: 10 avisos conocidos, casi todos de llegar **en bici** (los huecos libres junto a
  sus marcas quedan a 1,8 studs: al andar se apartan). **O** Aceptables (ver «Excepciones»).

### 14. Uni06_Final (motor, cierre de la universidad y despedida con Abu)
- **A** Abu: «Esas horas no vuelven. Pero se guardan». Despedida tierna, sin dramatismo. **C** Abu, familia,
  Lola, Omar. **E** 12 planos, 58,7 s. **Arreglos** emociones y miradas de los que escuchan, Abu se inclina y
  pregunta con la cabeza, tu familia sonríe; el plano de dos con Abu (que no cabía en la cafetería) pasa a
  plano por encima de tu hombro. **I** Íntima → tema; luz cálida → noche. **P** Final de `Uni06`.

### 15. Adulto_Bienvenida (generada, apertura de la vida adulta)
- **A** Tu primer día de trabajo. **C** Ernesto, Lola (según profesión). **E** 1 plano de cámara + los de
  cada frase (los pone el director de escena). **F** 14 frases. **G** 10 reacciones + gestos de la fase 4.
  **N** `test-cineplanos` (sin avisos). **P** `Adu_Profesion`.

### 16. Adu02_Hospital (generada, despedida a Abu en el hospital)
- **A** Abu se recupera; momento de cuidar a quien te cuidó (13+: nada de pérdidas en pantalla). **C** Abu,
  Nuria, tu familia. **F** 15 frases. **G** 20 reacciones (tristeza que pasa a alegría). **P** `Adu02`.

### 17. Adu02_Orilla (generada)
- **A** El atardecer con Abu junto al mar. **E** 1 plano + los de las frases, 10,8 s. **F** 2 frases.
  **G** 3 reacciones. **O** El «Gracias» de Abu va junto a su frase anterior en el mismo bocadillo (por eso la
  herramienta de gestos no lo toca: `Gestos.Skip`). **P** `Adu02_Atardecer`.

### 18. Grieta_Caen (motor) — el meteorito en 10 pasos
- **A** La Grieta deja de ser una rareza del cielo: algo ha llegado a Valmar. **B** `Saga_02_Grieta` paso 2,
  en el garaje de Cosme. **C** Cosme, Pip, Chispa, dos vecinos del parque, tú.
- **D/E** (35 s, 13 planos):

  | # | Segundo | Plano | Paso |
  |---|---|---|---|
  | 1 | 0–1,6 | Travelling del garaje al cielo verde | 1 avisos: el medidor pita más deprisa, un temblor pequeño, se callan los pájaros · 2 el cielo cambia |
  | 2 | 1,6–2,6 | Junto a ti, mirando a la Grieta («¡Cúbrete!») | 4 reacciones: Pip asustado, Cosme señala |
  | 3 | 2,6–4,6 | Sigue a la primera estrella | 3 la estela |
  | 4 | 4,6–6,2 | Fijo en el parque | 5 impacto 1: destello, onda, cascotes · los vecinos huyen |
  | 5 | 6,2–7,4 | Fijo en el patio del cole | 5 impacto 2: la valla salta |
  | 6 | 7,4–8,6 | Fijo en el camino al cole | 5 impacto 3: humo entre los árboles |
  | 7 | 8,6–12 | Acercamiento lento al cráter humeante | **8 silencio**: sin música, sin ambiente, nadie habla |
  | 8 | 12–15 | Fijo en el parque | 9 Chispa rompe el silencio («¡Bip!») y huye; el vecino vuelve a ver si estáis bien |
  | 9 | 15–18 | El vecino | 9 «¿Estáis bien? ¡No os acerquéis!» |
  | 10 | 18–23,6 | La cara de Cosme | el narrador: «Tres cosas han caído…» |
  | 11–12 | 23,6–29,5 | Pip, Cosme | «Tres impactos» / «No. Tres mensajes» (Cosme se inclina) |
  | 13 | 29,5–35 | Te alejas hacia el cielo | 10 rótulo: busca los cráteres |

- **F** 9 frases; la de Pip del principio se pisa con la de Cosme, pero justo después la escena se para en
  «¡Cúbrete!» y da tiempo a leer las dos. **G** Miedo, sorpresa, nervios, señalar, miradas a la Grieta y
  al que habla. **H** 3 meteoritos con impacto (destello, onda, bola de fuego, humo, chispas, cascotes,
  temblor, mancha), cielo GrietaVerde, «Poof». **I** Pings del medidor, zumbido, el silencio, tensión →
  descubrimiento → tema.
- **J** Se quedan: tres cráteres (humeantes → fríos al recoger) y **la valla del patio rota → en obras al
  acabar Saga_02 → arreglada con una placa al acabar Saga_04** (`StageSets.DanoPatio`). Temporal: el cielo
  verde. **K** El paso siguiente pide buscar los cráteres. **L** `Happenings/Cielo.luau`, `StageSets.luau`,
  `StageBuilders.luau` (Damage).
- **N** `test-scenes` (duración, 13 planos, 4 claves del mundo entre 4,8 y 7,5 s, silencio de 4,6 a 12 s,
  saltar deja lo mismo), `test-worldmemory` (la valla en sus 3 estados, sobrevive a reiniciar),
  `test-mision-grieta`, `test-cineplanos`. **O** Ver en Studio que los tres impactos se leen bien con el
  móvil y que el silencio se nota (no hay voces encima). **P** Misión `Saga_02_Grieta` paso 2; saltarla a
  mitad: deben quedar los cráteres y la valla rota; al acabar Saga_02, la valla con vallas de obra.

### 19. Grieta_Coser (motor, fin del Acto I)
- **A** Coser el cielo juntos. **C** Cosme, Pip. **E** 8 planos, 26 s; 1 s quieto en Cosme antes del inserto
  de la aguja (se deja) y el apagón (negro). **Arreglo** silencio de 2,5 s cuando vuelve la luz antes de
  «Se ha cerrado». **J** La marca de la aguja en el patio (`StageSets.AgujaPatio`: azul; roja desde
  Saga_12; blanca desde Saga_24). **N** `test-scenes`, `test-worldmemory`. **P** `Saga_06_Coser`.

### 20. Grieta_Rota (motor)
- **A** Te roban la graduación: la costura se rompe y baja Cósimo. **C** Cosme, Nico, Omar, Sara, Cósimo.
  **E** 9 planos, 24,5 s. **G** 21 reacciones (todos miran arriba, miedo, sorpresa, rabia de Cosme, Cósimo
  saluda). Silencio tras el crujido y tras el portal ✓. **J** Donde aterriza Cósimo: losas levantadas y
  papeles de la fiesta → en obras (Saga_13) → arreglado con placa (Saga_15) (`StageSets.BajadaInstituto`).
  **P** `Saga_12_Graduacion`.

### 21. Grieta_Fusion (motor)
- **A** La Gran Fusión: el cielo se rompe del todo. **E** 9 planos, 30,5 s. **G** 9 reacciones (miedo,
  calma, rabia de Cosme). Silencio tras el trueno ✓. **N** `test-cineplanos`: 1 aviso conocido llegando en
  coche (el coche aparcado justo detrás de Cosme). **O** No deja nada en el mundo: el monte cambia en el
  capítulo final (lo decide la fase 6/7). **P** `Saga_23_Fusion`.

### 22. Grieta_Final (motor, el final)
- **A** La última costura donde empezó todo; Cósimo y Cosme se reconcilian. **C** Cosme, Cósimo, Pip, Iván,
  Candela. **E** 9 planos, 33 s. **Arreglo** 1,2 s sin plano entre Cósimo y la reacción de Cosme. **G** 19
  reacciones (vergüenza de Cósimo, alegría). **J** La marca de la aguja se queda blanca. **N**
  `test-cineplanos`: 1 aviso conocido (grupo apretado en el general del anclaje). **P** `Saga_24_Final`.

### 23. Vida_MirarAtras (motor, el gran cierre)
- **A** Mirar atrás toda una vida en Valmar. **E** 23 planos, 95 s. **F** 14 frases; dos con rótulo a la vez
  (el reloj las espera). **G** 30 reacciones. **Arreglo** la frase de Abu la dice su actor de foto.
  **N** `test-cineplanos`: 7 avisos conocidos (planos a mano en casa: Omar en el marco de una puerta; el
  último plano mira al cielo). **P** `Adulto_MirarAtras`.

### 24. Prologo_Cierre (vieja → motor en la fase 6)
- **A** Sales del sueño. **E** 1 plano de 16,4 s. **F** 1 frase. **O** Hecho en la fase 6: escena del motor
  (`Happenings/Capitulos`), mismo id, plano, frase y rótulos.

## Excepciones de test-cineplanos (lista PENDIENTES)

La lista tenía **96** casos al empezar esta revisión y tiene **93** al acabar: los 3 del plano de dos con
Abu en `Uni06_Final` se han arreglado (ya no fallan y se han quitado). No son 44: la auditoría v119 añadió comprobaciones nuevas y llegadas desde
otros lados, en bici y en coche, que multiplican cada caso). Ninguno es una cámara dentro de una pared con
el plano a la vista ni un actor que atraviese algo: son encuadres mejorables en sitios estrechos. Por tipos:

| Casos | Por qué siguen | ¿Aceptable? |
|---|---|---|
| 29 | Grupo apretado: alguien del corrillo queda cortado en el borde (8–20 %) desde todos los giros; el ajuste elige el que menos corta | Sí: es lo que haría un operador con el grupo así colocado; se arregla moviendo marcas en cada misión (fase 6/8 en Studio) |
| 9 | Llegada en bici a la graduación: el hueco libre junto a su marca queda a 1,8 studs de otro (mínimo 2) | Sí: al andar se apartan; solo pasa llegando en bici |
| 7 | Montaje de recuerdos: planos a mano en casa (Omar en el marco de una puerta) y el último mira al cielo | Sí: planos de foto a propósito |
| 6 | Plano de situación en un sitio estrecho: quien habla queda detrás de algo; el plano siguiente es el suyo | Sí: dura poco y el siguiente es el bueno |
| 5 | Dos marcas escritas casi juntas en escenas de `Effects.Scene` (Cole12) | Mejorable: mover las marcas en el `.md` (cambia el guion generado) |
| 4 + 3 + 3 | Corrillo con alguien de espaldas delante; plano de dos junto a una puerta o un coche; primer plano en sitio estrecho que acerca la cara | Sí: el ajuste ya elige el mejor giro |
| 27 | Casos sueltos (salto de eje en grupos de tres o explanadas con tu sitio aproximado, plano alto de último recurso en una esquina, niño y adulto en el mismo plano, sitio del coche aproximado, plano a mano que empieza dentro de un mueble…) | Cada uno lleva su razón en la lista; los de «sitio aproximado» dependen de que el mapa de prueba no sabe dónde aparcas |

Comprobado en esta revisión (dos pasadas completas de `test-cineplanos`): los 93 que quedan **siguen
fallando igual** (aceptables por lo de la tabla); ningún caso nuevo en las escenas revisadas.

## Ejecución de test-cineplanos

Dos pasadas con el mapa construido (2537 escenas, ~9840 planos, ~10 min cada una):

1. La primera encontró **2 avisos nuevos en `Grieta_Caen`** (la órbita del parque cruzaba la valla del cole
   y pasaba por encima de Chispa): arreglados (plano fijo). Y que los 3 de `Uni06_Final` ya no fallaban
   con su plano nuevo.
2. La segunda: `Grieta_Caen` sin avisos; los 93 conocidos, igual. **La prueba sigue en rojo por 167 avisos
   que no son de estas escenas**: todos `SinLugar` de las misiones de **Tefra** (`Tefra_07_Tregua`,
   `Tefra_Brasa`, `Tefra_Candados`, `Tefra_Papeles`…): «el sitio no está en el mapa» (`Tefra_Estatua`,
   `Tefra_PuestoHollin`, `Tefra_Panaderia`…). Esos sitios los construye `server/World/TefraCityBuilder` en
   otro planeta y el mapa de la prueba (`build-place` + `cine-extras`) no los tiene. Es contenido de otro
   equipo que entró en la rama a la vez: **no se ha tocado ni se ha escondido en PENDIENTES**; hay que
   enseñarle a la prueba la ciudad de Tefra (o construirla en `cine-extras`).
