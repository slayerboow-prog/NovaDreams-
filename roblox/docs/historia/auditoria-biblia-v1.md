# HEROES OF HISTORY — Auditoría de la Biblia narrativa v1 (Fase 1)

> 18-11-2026. Primera fase de la «Directiva maestra de revisión y evolución narrativa».
> Base auditada: `docs/historia/biblia-narrativa.md` (v1, «Los Ocho Mundos»), contrastada con lo que ya está en el juego:
> las 46 misiones (`src/shared/LifeStory/Misiones/`), el reparto (`Cast.luau`) y el motor de escenas (`Sequencer`,
> `CameraShots`, `SceneDirector`, `ActorStaging`, `WorldState`, `StageSets`).
> **Ojo: la §2 (contradicciones) queda sustituida por `choques-y-estructura-biblia-maestra.md`; la propuesta C3 sobre Kael era errónea.**
> **No cambia nada todavía.** Cada cambio de esta auditoría es una propuesta que el dueño tiene que aprobar (§8).

---

## 0. Veredicto en una página

**La v1 tiene buenos cimientos.** La premisa, el tema, el antagonista y la mitología sirven de base para una historia
adulta y con personalidad propia. **No hay que tirarla: hay que corregirla y desarrollarla.**

**Problemas principales:**
1. **Diez contradicciones con lo que ya está en el juego** (§2). Las más graves:
   - la edad de Cosme;
   - su hermana Lía frente a la «abuela» de la biblia;
   - dónde perdió Kael a su escuadra;
   - cuándo cayó Valmar.
2. **La biblia es un esqueleto.** Dice qué pasa, pero no cómo se vive. Faltan:
   - las fichas completas de los Heraldos;
   - las culturas de cada planeta;
   - la dirección de arte;
   - las grandes secuencias de cine;
   - el mapa de relaciones;
   - el libro de decisiones y consecuencias.
3. **Los arcos que la directiva pide «progresivos» empiezan tarde o no están sembrados:**
   - el deterioro de Sorel arranca en el planeta 5;
   - la caída de Ilse no tiene pasos intermedios;
   - los Heraldos solo aparecen al final de su planeta.
4. **Las 124 horas no se sostienen con calidad.** Propongo unas 90 h de historia principal con duración variable por
   planeta (§5).
5. **Arte y técnica.** Hoy los siete planetas se construyen con el mismo generador de barrios (`PlanetCity`); solo
   Tefra está hecho a mano. La directiva prohíbe expresamente «la misma arquitectura con otros colores». Es el mayor
   coste de producción de todo el proyecto y hay que planificarlo aparte (§6).

---

## 1. Lo que funciona y se conserva

| Elemento | Por qué funciona |
|---|---|
| **Tema «la puerta cerrada»** | Une el pasado (Gran Corte), lo local (Varn y el Sur, Coria y la Cúpula Honda), lo corporativo (el Arca) y lo personal (Kael). La pregunta final de la directiva («¿merece la pena salvar un universo repitiendo sus errores?») ya sale de él. |
| **Ithar** | Filosofía comprensible («gritando o dormidos»), una culpa (retrasó la evacuación), una contradicción (predica disolverse, pero protege a Lys) y una verdad que no quiere mirar (el Coro olvida). Además, nunca miente al jugador. Es un antagonista de nivel. |
| **Oren, los Tejedores, el Telar y los Ocho Sellos** | Explican por qué hay humanos en ocho mundos, por qué existen las grietas y por qué las armas llevan núcleos de Sello. Toda la mitología tiene una función en el juego. |
| **Las reglas de la Marea** | Tres fases (emociones, recuerdos, Velado). Son reglas fijas y sirven de mecánica para el deterioro de Sorel. |
| **La cadena de giros que se reinterpretan** | Lo que en Tefra parece piedad (devolver a los muertos), en Vértice resulta ser hambre. Es la estructura de revelaciones que pide la referencia de KOTOR. |
| **Las viejas heridas entre mundos** | Valmar compró armas en la guerra de Tefra, Vértice compró el sol de Nivalis y Tálasa negó refugio a Miasma. Con ellas, los planetas son civilizaciones con historia común y no niveles sueltos. |
| **La flota final como suma de lo salvado** | Las decisiones se ven en la batalla final. |
| **La muerte de Kael sujetando la compuerta** | Cierra su arco con el mismo gesto que la condenó, pero al revés. Es una muerte con motivo y con consecuencias: Brenn toma el mando. |
| **La monetización sin pay-to-win** | Correcta, y alineada con las normas de Roblox. |
| **El encaje con lo hecho** | Las 46 misiones se aprovechan. |

---

## 2. Contradicciones encontradas (con propuesta)

La regla de la directiva es documentar el problema y proponer una solución, sin inventar explicaciones en silencio.
Cada propuesta procura no tocar lo que el jugador ya ha visto.

### C1 · La edad de Cosme
- **Problema:** la biblia le da 71 años. En el juego (`Coalicion_Marea`) cuenta que cayó por una grieta **a los nueve
  años** y que han pasado **treinta y ocho**, lo que da 47 años. Sin embargo, su aspecto y su voz son de anciano (pelo
  blanco, voz «Abu»).
- **Propuesta:** las dos cosas son verdad. **Cruzar una grieta sin la protección de un Sello cuesta años de vida.** En
  los segundos que pasó dentro, Cosme envejeció más de veinte años. Tiene 47 años en el calendario y un cuerpo de 70.
  - Ningún texto del juego cambia.
  - Explica por qué Ithar «lo recuerda»: el Coro lo tocó.
  - Siembra una regla que paga más tarde: por eso la expedición de Kael volvió envejecida y por eso Ilse no puede
    cruzar sin más.
  - Da a Cosme una herida nueva y adulta: le robaron la vida que tenía por delante, no solo la casa.

### C2 · ¿Abuela o hermana?
- **Problema:** la biblia dice que la abuela de Cosme está en el Coro. En el juego, la persona perdida es su
  **hermana Lía**, que «le esperó» y «bajó a la forja», y cuyo nombre aparece en una lista con la nota «esperando a
  Cosme». La abuela solo se menciona porque llamaba a la Marea «el Silencio que se comía las estrellas».
- **Propuesta:** **Lía es la Velada** que el grupo encuentra en el asedio de Bastión (Tefra, Acto IV), y la decisión
  es de Cosme. La abuela se queda como **pista mitológica**: Tefra conservó en sus cuentos el recuerdo del Gran Corte.

### C3 · Dónde perdió Kael a su escuadra
- **Problema:** el juego dice (`Academia.luau` y `Cast`) que Kael «perdió a su escuadra en Tefra». La biblia dice que
  fue en la expedición del Consorcio a través de una grieta y que la madre de Noa sigue en criosueño **en Tálasa**.
- **Propuesta:** las tres cosas encajan.
  1. La expedición de 1.194 entró por la grieta de la **Lanza, en Tefra**. «Perdí a mi escuadra en Tefra» es la
     versión oficial, y es verdad a medias.
  2. **Ilen**, la segunda de Kael, iba en la expedición y es una de las personas a las que Kael cerró la compuerta.
     La voz de ILEN, la IA de la nave, es la voz de alguien a quien ella abandonó. Eso explica por qué no soporta
     oírla.
  3. Regla nueva del Telar: **«Lo que se pierde en los Hilos acaba en el Ancla.»** La cápsula de Irene Ferran derivó
     hasta el Nudo de Tálasa y la recogió la Estación Abisal. Esto conecta Tefra con Tálasa y prepara el giro de Kael.

### C4 · Cuándo cayó Valmar
- **Problema:** la biblia dice que Valmar cae «hoy», la última de las ocho. En el juego, la Caída de Valmar ocurrió
  **hace dos años**: «por primera vez en dos años se ven las estrellas», y los guardias llevan «dos años sin cruzar la
  empalizada». El juego empieza en un asentamiento de supervivientes.
- **Propuesta:**
  - Valmar cayó en **1.212**, la noche de la Grieta y del Sur.
  - El juego empieza en **1.214**.
  - Valmar no es la última en caer: es **la última que resiste**. Sigue siendo una ciudad de chatarra con una Academia
    mientras los otros siete mundos están ocupados.
  - La premisa «ocho mundos han caído» se mantiene intacta.
  - Cambia la cronología §I: Vértice cae en 1.211 (desde dentro), Valmar en 1.212 y los otros seis entre 1.212 y
    1.213.

### C5 · ¿Los Heraldos «aceptan» o no?
- **Problema:** §D dice que cada Heraldo es «un nativo que aceptó la oferta del Coro». Pero la misma biblia dice que
  Teo «no eligió» y que ÁGORA «no tuvo elección».
- **Propuesta:** la regla se mantiene, y estos dos casos son sus versiones más oscuras.
  - **Teo dijo que sí mientras moría.** La Marea le ofreció que dejara de doler. Tenía 17 años, estaba solo y su
    hermano le había dicho que esperara. Aceptó sin entender. Eso es más trágico que «lo eligieron» y hace que el
    combate final sea contra alguien que dijo que sí a lo que cualquiera diría.
  - **ÁGORA eligió por cálculo.** La IA de MegaVerso llegó a la conclusión de Ithar solo con matemáticas: el Coro
    reduce el sufrimiento total. Es el espejo más peligroso de Ithar, porque una máquina sin culpa le da la razón.
  - **Augusto Halvek deja de ser Heraldo** y pasa a ser el antagonista humano de Vértice. Es el primer colaborador de
    todos (hace 40 años) y el que escapa en el Arca, lo que deja abierta la expansión. Así cada Heraldo tiene su
    conclusión emocional, como pide la directiva, y la huida de Halvek no la estropea.

### C6 · ¿Puede Ithar cruzar?
- **Problema:** la biblia dice que Ithar «no puede cruzar en persona un Hilo cerrado». La directiva pide un «primer
  encuentro físico con Ithar» en Vértice.
- **Propuesta:** la Consola de Vértice es el único Sello que funciona como puerta en los dos sentidos. Con el Plan
  Puerta a medio abrir, Ithar entra con **un cuerpo hecho de ceniza**: se le puede tocar y su sombra se proyecta en la
  luz azul, pero no está entero (se deshace por los bordes cuando se enfada). El encuentro **en carne** solo ocurre en
  Oren. Así, la primera vez da miedo y la última da pena.

### C7 · ¿Por qué está Lys dentro del árbol madre de Umbría?
- **Problema:** la biblia dice que Ithar «la aparta del Coro», pero no explica por qué está en un árbol de otro mundo.
- **Propuesta:** Ithar la escondió en **la Semilla**, el banco de vida de los Tejedores. Es el único lugar al que el
  Coro no llega, porque está protegido por un Sello. **Protege a su hija con lo mismo que combate.** La pista que ya
  estaba («el árbol madre florece cuando suena la señal») gana sentido: es Ithar visitándola.

### C8 · Savia: ¿alcaldesa o sacerdotisa?
- **Problema:** en el reparto existe `AlcaldesaSavia`. La biblia la llama «Madre Savia», sacerdotisa.
- **Propuesta:** es la alcaldesa que firmó la tala y se hizo sacerdotisa de la Ceniza. **El cambio de título es su
  arco.** Los umbríos que la conocieron siguen llamándola «alcaldesa» para hacerle daño.

### C9 · Nombres que se confunden
- **Problema:** hay demasiados nombres parecidos: **Ilse** (Maren), **Ilen** (la segunda de Kael), **ILEN** (la IA),
  la princesa de Nivalis (que hoy también se llama **Ilse**) y **Lys**. «Elin», el nombre que propuse en la v1, sigue
  siendo casi igual que Ilen.
- **Propuesta:** la princesa pasa a llamarse **Ámbar**. Es un nombre de luz para un mundo sin sol, y no se parece a
  ningún otro. Ilen e ILEN se quedan, porque esa confusión está buscada y es el drama de Kael. Lys también se queda,
  porque la directiva la nombra.

### C10 · Tres finales en un MMO
- **Problema:** la biblia propone tres finales, pero el mundo es compartido. Un jugador no puede tener los Hilos
  sellados mientras su vecino tiene el Coro liberado.
- **Propuesta:** se separa lo que vive cada jugador de lo que comparte el mundo.
  - **El final es personal:** cada uno ve su cinemática, sus pérdidas y los epílogos de sus personajes, guardados en su
    `WorldState`.
  - **El estado del mundo es canónico para todos:** después del final, el universo está liberado y vuelve la ciudad de
    antes.
  - **Las expansiones parten del final canónico** («Liberar el Coro»), pero los diálogos recuerdan lo que eligió cada
    uno.

### Coherencias que se dejan escritas (no son errores, pero hay que fijarlas)
- **Siete grietas y ocho Sellos.** El Consorcio abrió siete grietas (así lo dice el juego). La octava perforación es
  la Grieta de Valmar, el Proyecto Umbral de Ilse, financiado por Varn, que llevaba las cuentas del Consorcio en
  Valmar.
- **La señal.** Hay un pulso cada **11 segundos** y **la voz se oye a las 3:12**. Las dos cosas son canon y aparecen
  en misiones distintas.
- **El reparto antiguo.** Varias fichas de `Cast` son de antes del cambio de rumbo; por ejemplo, Cosme aparece como
  «el vecino inventor del garaje». Brenn y Sorel figuran como adolescentes, pero la biblia les da 20 y 19 años. Hay que
  limpiar el reparto, sin tocar la historia.
- **El final ya implementado contradice el plan.** «La última noche» (la flota, la muerte de Kael y el universo
  recuperado) ya está en el juego. Mover la muerte de Kael a Tálasa obliga a retirar y reescribir esas 3 misiones.

---

## 3. Lo que falta (frente a la directiva)

| Pide la directiva | Estado en la v1 | Falta |
|---|---|---|
| Protagonista en **6 etapas** | 5 etapas, sin «Superviviente» ni «Símbolo» | Reordenar: Aprendiz (inicio de Valmar), Superviviente (final de Valmar), Guerrero (Tefra y Miasma), Comandante (Siroco y Nivalis), Símbolo (Umbría y Tálasa), Quien decide (Vértice y Oren). Definir cómo se nota: líneas de diálogo por etapa, cómo le saludan los PNJ, posturas, qué le piden y qué le reprochan. |
| **Heraldos con 8 requisitos** | Una línea por Heraldo; casi todos aparecen solo en el Acto III o el V | Ficha completa por Heraldo: presentación en el Acto I (transmisión, encuentro o huella), presencia durante la campaña, 2-3 conversaciones, consecuencias, combate por fases que cuente su historia y conclusión. Varga y Coria están especialmente flojos. |
| **Ilse: deterioro construido** | Solo se dice que «sigue oyendo la voz» | Escalera de 8 peldaños, uno por planeta: tic, mentira pequeña, desaparece de noche, roba un componente, defiende a Ithar en una discusión… hasta llegar al Nudo. Su hijo necesita nombre, edad y una causa de muerte; el juego todavía no lo nombra, así que se puede definir libremente. |
| **Sorel: deterioro progresivo** | Empieza en Nivalis (planeta 5) | Semillas desde Valmar: pesadillas, oye la señal antes que nadie. Después del contacto, un sistema visible: olvida nombres en sus líneas, ya no se ríe con los chistes de Cosme, su chaqueta pierde parches y sus animaciones son más lentas. |
| **Lys: la verdad que el padre no acepta** | «Quiere que la deje irse» | Su filosofía propia: «Quedarse para siempre no es vivir. Lo que no termina no significa nada.» Su relación con el jugador y su historia en Oren (jardinera del Árbol original). |
| **Ithar: pocas apariciones y memorables** | Un arco de apariciones por planeta, sin escenas concretas | Unas 7 apariciones con puesta en escena concreta y una frase que se recuerde en cada una. |
| **Civilizaciones vivas** (religión, política, costumbres) | Casi nada por planeta | Ficha cultural por mundo: gobierno, religión o creencias, cómo recuerdan el Gran Corte, costumbres, expresiones, comida, oficios, facciones y lugares históricos. |
| **Dirección de arte por planeta** (10 puntos) | No existe | Arquitectura, ecosistema, enemigos, vestimenta, tecnología, música, luz, monumentos, paisaje y transformación al ser liberado. |
| **15 secuencias cinematográficas** | Solo reglas generales (§O) | Guion técnico de cada una: planos, movimientos de cámara y de actores, luz, sonido, silencio, música y vuelta al control. |
| **Música** | Solo hay tema para Kael (cello) e Ithar (coro) | Una identidad por planeta y motivos para Sorel, Brenn, Ilse, Cosme y Lys. |
| **Mapa de relaciones** | No existe | Quién quiere a quién, quién debe qué a quién y cómo cambia cada relación por planeta. |
| **Libro de decisiones** | Las decisiones están sueltas en el texto | Tabla con cada decisión, su clave (Flag), dónde reaparece y qué final abre o cierra. «Encender bien los Sellos» todavía no tiene definición jugable. |
| **Secundarias** | Un párrafo | De 5 a 10 por planeta, con premisa, decisión y efecto en el epílogo (Fase 5, planeta a planeta). |
| **Multijugador en las escenas** | No se trata | Reglas: qué escenas son personales, cuáles de grupo y cuáles del mundo; jugadores que llegan tarde; saltos; decisiones individuales frente a las de grupo. |
| **Un planeta liberado cambia el siguiente** | Solo «cada mundo aporta algo» | Efectos concretos. Por ejemplo, con Tefra liberada, sus herreros aparecen en Miasma y hay armas nuevas en la tienda; con Siroco liberada, hay mapas de los Hilos y una ruta corta a Nivalis. |

---

## 4. Lo que necesita más profundidad

- **Kael.** Falta su vida antes de la expedición: de dónde es, por qué entró en el Consorcio y a quién quería. Su culpa
  se ve en sus silencios: nunca entra en ascensores (una compuerta), cierra todas las puertas que atraviesa y cuenta a
  los cadetes al volver. Tiene que haber al menos **una escena en la que se ría**, para que su muerte duela.
- **Brenn y Teo.** Es la historia central de Valmar y hoy cabe en una línea. Faltan el pasado de los dos hermanos (el
  balón con el nombre de Teo ya existe en el juego), la llamada de las 23:52 (ya está en `Grieta_Umbral`), el primer
  vistazo a Teo entre los Velados, la deserción de Brenn y el combate final, en el que Teo pide descanso.
- **Cosme.** El humor como defensa tiene que tener grietas visibles: una escena en la que el chiste no le sale, y la
  decisión sobre Lía.
- **Varn.** Tiene que ser más que «el malo educado». Su lógica: «salvé a diez mil cerrando el Sur». Es el Gran Corte en
  pequeño y la razón de que el tema vuelva a Valmar.
- **Los planetas del medio.** Siroco, Nivalis y Umbría tienen buen conflicto local, pero poca relación con el
  misterio central hasta su Acto V. Cada uno necesita una pieza del puzle en el Acto II.
- **El Coro por dentro.** Cómo se ve, qué se oye y qué siente quien lo toca. Lo necesitan las escenas de Sorel, las de
  Ilse y el final en Oren.

---

## 5. ¿Hacen falta 124 horas?

**No. La duración no debe ser un objetivo.** Con 15 h por planeta hay que llenar unas 250 misiones. Eso exige pasajes
de transición que la directiva prohíbe («nada de relleno»). Además, una sesión típica en Roblox es corta: un capítulo
de 15 h por planeta tarda semanas en terminarse y el jugador olvida la trama.

**Propuesta: duración según lo que cada historia necesita.**

| Campaña | Horas | Por qué |
|---|---|---|
| Valmar | 12 | Presenta el mundo, el grupo, a Brenn y a Teo, y las reglas del juego. Ya hay unas 5 h hechas. |
| Tefra | 11 | La guerra, Cosme, Lía y Corvo |
| Miasma | 9 | Historia íntima (Andrés, Mara y Leo) |
| Siroco | 9 | Revelación del Gran Corte |
| Nivalis | 11 | Intriga política, el sol y el contacto de Sorel |
| Umbría | 9 | Lys, y el deterioro de Sorel |
| Tálasa | 11 | La traición de Ilse y la muerte de Kael |
| Vértice | 11 | El asalto y el cara a cara con Ithar |
| La puerta (Oren) | 5 | El final y los tres desenlaces |
| **Total** | **≈ 88 h** | Más 5-10 secundarias por planeta (de 15 a 25 h aparte) y las mazmorras rejugables |

Mantiene la escala de una gran aventura, cerca del doble de una campaña AAA de rol, y permite cumplir la regla de que
cada misión tenga un propósito narrativo y jugable.

---

## 6. Viabilidad técnica (qué hay y qué falta)

### Ya existe en el motor (se aprovecha tal cual)

| Lo que pide la directiva | Lo que ya hay |
|---|---|
| Plano general, medio, primer plano, reacción, sobre el hombro y plano de acción | `CameraShots`: `General`, `Medio`, `PrimerPlano`, `PPP`, `Reaccion`, `Hombro`, `DosPlanos`, `Lateral`, `Seguir`, `Inserto`, `Dolly`, `Pan`, `Tilt`. La cámara evita paredes, no tapa caras y «respira» en los planos largos. |
| Silencios y reacciones | `Pause` (antes y después de la frase) y `Beat`: Mirar, Suelo, Apartar, Pensar, Respirar. `Silence` quita la música. |
| Personajes que caminan, entran, se van y miran | `Actors` con `Enter`/`Exit` andando o corriendo, `Look` (a quien habla, al suelo, a otro lado) y `Mood` (emoción que dura). |
| Gestos | `Wave`, `Point`, `Cheer`, `Laugh`, `Dance` |
| Luz narrativa | Ajustes `Sueno`, `Grieta`, `Ceniza`, `Recuerdo`, `Tension`, `Impacto`, `Intima`, `Noche`, `Atardecer`, más la luz de relleno automática en las caras de noche |
| Música adaptada | `Music` por intensidad: Nada, Descubrimiento, Íntima, Tensión, Resolución y Tema, más `Ambience` según el sitio |
| Interrupciones | `Until` (la escena termina con un suceso del juego), `Wait` (se para hasta que pasa algo), `Shake`, `Fx` y `Sound` |
| Consecuencias | `If`/`IfNot`/`Variants` con Flags, Choices, relaciones y memorias. Una escena cambia según lo que hiciste. |
| Saltar escenas sin perder decisiones | `OnSkip`, y las decisiones van siempre fuera de la escena |
| Multijugador | `Scope` = Personal, Group (quien está cerca se une) o World (los demás ven el efecto sin perder el control), más `Queue` |
| Liberación visible | `WorldState` por jugador y decorados condicionales de `StageSets`. Cada jugador puede ver su planeta liberado. |
| Vuelta al control | `CineCamera.restore`: vuelta suave en unos 1 s |

### Falta (habría que construirlo antes de las escenas que lo usan)

| Sistema | Para qué | Coste |
|---|---|---|
| **Posturas**: sentarse, levantarse, arrodillarse, cruzar los brazos, mirar al horizonte, cubrirse, señalar lejos | Lenguaje corporal y personajes que no están quietos | Medio (animaciones R15 y un campo nuevo en `Actors`) |
| **Corte a mitad de frase** | La explosión que interrumpe una línea | Bajo (un campo `Cut` en `Dialogue` más un suceso) |
| **Leitmotivs** | Temas de personaje y de planeta | Medio: audio con licencia de la biblioteca de Roblox o subido por el dueño |
| **Modelos únicos**: Ithar, los 4 rangos de Velados, 8 Heraldos y la ropa de cada cultura | Que nadie parezca un PNJ cualquiera | Alto (arte 3D) |
| **Un kit de arquitectura por planeta** | La regla artística: arquitectura propia en cada mundo | **Muy alto.** Hoy `PlanetCity` genera los siete barrios con los mismos datos. |
| **Mazmorras instanciadas** para grupo, con modo heroico | Dos por planeta más la del Heraldo | Alto (no hay sistema de mazmorras) |
| **Jefes por fases** | Combates que cuenten la historia del Heraldo | Medio (se apoya en `CombatService` y `BeastService`) |
| **Liberación a escala de planeta** | Ampliar `StageSets` y `WorldState` del decorado suelto a barrios enteros | Medio |

**Límite honesto: las caras.** Los personajes de Roblox tienen poca expresión facial, así que un primer plano sostenido
cuenta menos que en The Last of Us. Se compensa con encuadre, luz, pausas, posturas y miradas: el «una mirada vale más
que un discurso» se hace con el cuerpo y la cámara, no con microexpresiones. Si el proyecto adopta cabezas dinámicas
(con expresiones), hay que revisar esta regla.

---

## 7. Propuesta de dirección creativa (avance de la Fase 2)

- **Identidad.** Ópera espacial de civilizaciones con drama humano en el centro. La escala es la de una guerra
  galáctica, pero cada escena grande se cuenta a través de una persona.
- **Tema y pregunta.** El tema sigue siendo **la puerta cerrada**: quién decide por los demás, a quién se deja fuera y
  qué cuesta. La pregunta central es la de la directiva: *¿merece la pena salvar un universo si para hacerlo tenemos
  que repetir los mismos errores que lo destruyeron?* El Coro quita la capacidad de decidir. La victoria del jugador
  es devolvérsela a los ocho mundos, aunque decidan mal.
- **Tono visual.**
  - Cine de ciencia ficción con luz motivada: azul de Sello como esperanza, gris como Coro y la luz propia de cada
    planeta.
  - Al liberar un planeta, su luz cambia de forma visible.
  - Nunca el aspecto genérico de Roblox.
- **Tono de escritura.** Frases cortas y subtexto. Nadie explica lo que acaba de verse. Hay humor de personaje y nunca
  de chiste.
- **Regla de las muertes.** No se añade ninguna muerte nueva. Solo mueren quienes tienen motivo y consecuencia: Teo,
  Kael, Ithar y, según las decisiones, Sorel y Lía.

---

## 8. Decisiones que necesito del dueño

1. **Contradicciones C1-C10:** ¿apruebas las soluciones? Las más visibles:
   - la grieta le robó años a Cosme;
   - Lía es la Velada de Tefra;
   - la expedición de Kael entró por Tefra;
   - Valmar cayó hace dos años y es la última que resiste;
   - ÁGORA es la Heraldo de Vértice y Halvek el humano que huye;
   - la princesa se llama **Ámbar**.
2. **Duración:** ¿unas **88 h** variables por planeta en lugar de 124 h?
3. **Pilares que siguen de la v1:** Ithar y Oren, la muerte de Kael al final de Tálasa, la traición de Ilse y Teo como
   Heraldo de Valmar. ¿Se confirman?
4. **Arte:** ¿se acepta que el **kit de arquitectura por planeta** sea un proyecto propio, empezando por Valmar y
   Tefra, en paralelo a la escritura?

**Siguiente paso, con tu sí:**
- Fase 2: dirección creativa definitiva.
- Fase 3: la Biblia maestra con sus 23 apartados.
- Fase 4: el plan cinematográfico de las 15 secuencias.
- Fase 5: después, la producción de Valmar misión a misión, sin pasar a otro planeta hasta cerrarlo.
