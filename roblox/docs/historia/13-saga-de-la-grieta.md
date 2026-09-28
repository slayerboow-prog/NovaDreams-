# 13 · La Saga de la Grieta (historia principal canónica)

La vida del personaje (colegio, instituto, universidad, trabajo) sigue siendo la base del juego. Por encima
de ella hay una **historia principal canónica**, de ciencia ficción gamberra, que une TODAS las misiones
locas en una sola historia con sentido. Todo lo raro que pasa en Valmar tiene una causa, un villano y un final.

**Objetivo de duración**:

- Saga canónica: unas 15 h, en 24 misiones de 30 a 45 min.
- Secundarias enlazadas con la saga: otras 15 h, entre las misiones locas y las «rarezas» de cada etapa.

**Estado**: las 24 misiones están escritas y se prueban solas en `scripts/test-lifestory.luau`
(`Misiones/Saga_Acto1.luau` … `Saga_Acto4.luau`). Falta probarlas en Roblox Studio con el mapa real.

## Misiones canónicas en el mapa

- Las misiones canónicas (`Canon = true`) se ven **siempre** hasta que las haces:
  - un ❗ dorado en el minimapa y en el mapa grande;
  - un pilar de luz dorado con el título en el mundo.
- Al llegar al sitio, **empiezan solas**: no se pueden rechazar ni cuentan para el límite de secundarias.
- Si piden una hora, la marca lo dice: «(de 2:00 a 5:00)».
- Motor: `LifeStoryService.updateCanonMarks` publica el atributo `CanonMarks`, y `Controllers/CanonMarkers`
  pinta los pilares y las marcas del mapa.

## La historia en una frase

La noche en que naciste, Cosme y su socio de entonces, Cósimo, probaron una máquina que cosía dimensiones.
Salió mal: se abrió **la Grieta**, una costura rota en el cielo de Valmar.

La Grieta se «ancló» a lo único que había cerca: tú, un bebé recién nacido. Eres **el Ancla**. Mientras tú
existas en esta Valmar, la Grieta no puede abrirse del todo.

Cósimo cayó por la Grieta a la dimensión 66-B, donde todo el mundo es malvado. Se dejó perilla (es el
reglamento) y lleva toda tu vida preparando **la Gran Fusión**: juntar su Valmar con la tuya y quedarse
con las dos.

## Personajes que atan todo

| Personaje | Papel en la saga |
|---|---|
| **Cosme** | El vecino inventor. Te protege sin decírtelo desde que naciste. Culpa, cariño y batido de apio. |
| **Pip** | Su robot. Guarda el archivo secreto. |
| **Doctor Cósimo** (dimensión 66-B) | El villano. Era el socio de Cosme. Con perilla. Quiere la Gran Fusión. |
| **El Consorcio MegaVerso S.A.** | Una multinacional multiversal que financia a Cósimo. Quiere vender «vacaciones en otras dimensiones» y franquiciar Valmar en mil universos. Sus agentes van de traje gris. |
| **Agente Cronos** (Aduana del Tiempo) | Empieza persiguiéndote con formularios. Termina de tu lado. |
| **Aliados que vas haciendo** | Bigotes (Gatonia), el Ratón Pérez, Petra, Rex, la Capitana Ñoz (el reality), el Evaluador, Rigoberto (los gnomos), tu yo malvado redimido. Todos vuelven en el final. |

Las **misiones locas** de `docs/historia/12-misiones-locas.md` son secundarias, pero forman parte de la
saga: casi todo lo raro que pasa en ellas llega por la Grieta. En el final vuelven como aliados.

## Acto I · Infancia: «La Grieta»

| # | Misión | Resumen | Enlaces |
|---|---|---|---|
| 1 | **El vecino del garaje** (`Loco_N1_Cosme`, canónica) | El microondas temporal explota. Tres piezas. Al final, en el cielo, una línea verde que «antes no estaba ahí». | Abre la saga. Sin ella no hay nada más. |
| 2 | **La grieta en el cielo** | Caen cosas de la Grieta: un calcetín que habla, una moneda con la cara de Cosme… con perilla. Cosme palidece: «Cósimo». | Primera pista del villano. |
| 3 | **El pez que sabía demasiado** | Don Escamas, un pez de otra dimensión, huye de dos agentes de traje gris del Consorcio. Se le escapa: «¿el Ancla?». | Presenta al Consorcio y el misterio del Ancla. |
| 4 | **La ventanilla 42** | La Aduana del Tiempo multa a Cosme por la Grieta. Tres ventanillas que te mandan a otra ventanilla. Cronos sella… y avisa. | Cronos, que vuelve en A1, U2 y el final. |
| 5 | **La noche de las cosas perdidas** | La Grieta absorbe todo lo perdido de Valmar y lo escupe en el gimnasio del cole. Devuelves cosas y aparece el Monstruo de los Calcetines Desparejados. | Los vecinos empiezan a notar cosas. |
| 6 | **Coser el cielo** | Final del acto. Tres anclajes y la aguja cuántica. La Grieta se cierra… y una voz: «Ya te he visto, Ancla». | Gancho del Acto II. |

## Acto II · Adolescencia: «Los Visitantes»

| # | Misión | Resumen |
|---|---|---|
| 7 | **Las costuras se sueltan** | La Grieta vuelve a abrirse. Cosme te nombra «ayudante oficial», con credencial. El DJ, Zoltán y los lápices llegaron por ella (las misiones locas A2-A5 cobran sentido). |
| 8 | **MegaVerso S.A.** | El Consorcio abre una oficina en el Distrito Financiero: «¡Vacaciones en otras dimensiones!». Te infiltras y huyes de los robots de seguridad. |
| 9 | **El archivo de Pip** | Pip abre el archivo secreto con un flashback: la noche de tu nacimiento, la máquina, Cósimo y tú. Eres el Ancla. |
| 10 | **La fiesta del fin del mundo** | El Consorcio vende entradas para «la Gran Fusión». Saboteas la fiesta. |
| 11 | **Cronos cambia de bando** | El Consorcio falsificó sus formularios. Cronos se une a ti (o no, según cómo le trataste). |
| 12 | **Graduación interdimensional** | Final del acto, en tu graduación. La Grieta se abre del todo, Cósimo aparece por primera vez y se lleva a Cosme. |

## Acto III · Universidad: «El Multiverso»

| # | Misión | Resumen |
|---|---|---|
| 13 | **Sin Cosme** | El garaje está cerrado. Pip, Don Escamas, Iván y Candela (tus compis de la residencia) forman el equipo de rescate. El cuaderno de Cosme. |
| 14 | **El presidente Bigotes** | Portal en el parque a Gatonia. Huyes de la policía gatuna; Bigotes (ahora presidente) te da las coordenadas de Cósimo. |
| 15 | **Reestreno** | De noche, en el Monte del Silencio: la Capitana Ñoz (U1) cambia las grabaciones del laboratorio por un episodio especial del reality. |
| 16 | **Dimensión 66-B** | Te infiltras en la Valmar malvada («Cósimo alcalde para siempre») y conoces a tu yo malvado (prepara D5). Huida de los drones. |
| 17 | **El rescate** | Asalto al laboratorio bajo la universidad: combate contra los robots, abres la cápsula y huyes con Cosme… sin memoria. |
| 18 | **Todo tiene un precio** | Final del acto. Cósimo sale en todas las pantallas y anuncia la Gran Fusión. Cosme solo recuerda una cosa: tu nombre. |

## Acto IV · Vida adulta: «La Gran Fusión»

| # | Misión | Resumen |
|---|---|---|
| 19 | **Recuerdos de tostadora** | La copia de seguridad de la mente de Cosme (D3) tiene huecos. Los rellenas con tus recuerdos de la saga: la gallina, los clones, Pip… |
| 20 | **Todos los aliados** | Reúnes a quien ayudaste en toda tu vida. Cada uno viene por algo que hiciste. |
| 21 | **La caída del Consorcio** | Asalto a la sede de MegaVerso S.A. |
| 22 | **El Ancla** | Cósimo te ofrece un trato: tu vida perfecta en la 66-B a cambio de soltar el ancla. Decides tú. |
| 23 | **La Gran Fusión** | La batalla final en el Monte del Silencio: huida, oleadas, Cósimo y cinemática. |
| 24 | **Coser el cielo (de verdad)** | Epílogo. La Grieta se cierra para siempre. Cosme te llama «criatura» una última vez… y otra más, porque no se ha muerto. Es una comedia. |

## Continuidad con las misiones locas

- **Cosme secuestrado** (del final del acto II al rescate, misión 17) y **Cosme sin memoria** (de la 17 a la 19):
  - «Mi compañero de piso es un dinosaurio» (U2) tiene frases para un Cosme sin memoria.
  - «Las tres Valmar» (U3) necesita al Cosme de siempre: si no da tiempo en la universidad, queda para la vida adulta.
  - «La deuda galáctica» (D2) y «Cosme en una tostadora» (D3) esperan a que Cosme recupere la memoria (y D5 va después de D3).
- **Personajes que ya conoces**: Bigotes (14), la Capitana Ñoz (15), tu yo malvado (D5) y Glub (21) hablan distinto
  según hayas jugado o no su misión loca. Nadie da por hecho una misión que no has hecho.
- **Saludos**: las frases usan `{Saludo}` (buenos días / buenas tardes / buenas noches según la hora del juego).

## Secundarias (unas 15 h)

**Misiones locas**: 21 ya hechas (infancia 6, adolescencia 5, universidad 5, adulto 5).

**«Rarezas de la Grieta»** (`Misiones/Rarezas.luau`). Primer lote hecho, 8 misiones (2 por etapa), todas probadas
de principio a fin en `test-lifestory`:

| Etapa | Rareza | Pieza |
|---|---|---|
| Niño | El buzón que escribe al pasado | Sello del ayer |
| Niño | La farola que canta ópera (de 19:00 a 23:00) | Bombilla tenor |
| Adolescente | El perro que ladra en binario | Chapa binaria de Pip |
| Adolescente | Lluvia de espaguetis | Tenedor cósmico |
| Universidad | El piso 13 | Botón del piso 13 |
| Universidad | El reloj que va hacia atrás | Engranaje al revés |
| Adulto | El semáforo con opiniones | Luz ámbar |
| Adulto | La nube que te sigue | Gota de nube |

Pendiente de las rarezas:

- Entre 6 y 8 por etapa, de 10 a 20 min cada una.
- Son cosas pequeñas y absurdas que caen por la Grieta: el buzón que manda cartas al pasado, la farola
  que canta ópera, el perro que ladra en binario, la lluvia de espaguetis, el ascensor que sube a un
  piso 13 que no existe…
- Cada una da una **pieza de la colección «Restos de la Grieta»**.
- En el final, la colección cuenta: cuantas más piezas, más fácil la batalla.

**Aliados en el final (hecho)**: en la misión 20 vienen Iván y Candela siempre, y además Cronos, Bigotes,
Rex, el Ratón Pérez, los gnomos y tu yo malvado **solo si les ayudaste** en su misión. En la batalla final
aparecen los que vinieron.

**Misiones de aliados** (pendientes): 1 o 2 por cada aliado de la saga, para que vuelvan con sentido en el final.

## Reglas para que todo sea coherente

1. Nada pasa «porque sí»: todo lo raro llega por la Grieta, lo trae el Consorcio o lo inventa Cosme.
2. Cada misión canónica **pide la anterior** (`Requires.Completed`) y **deja una pista** de la siguiente.
3. Las secundarias **citan la saga** («desde que se abrió la Grieta…») y dejan **marcas** (`Flags`)
   que la saga usa: aliados que vienen o no, líneas de diálogo distintas.
4. La edad cuadra:
   - Cada acto pide su etapa mínima (infancia, adolescencia, universidad, adulto).
   - Si no te dio tiempo, el acto sigue disponible en la etapa siguiente: la marca del mapa no desaparece.
5. El tono se mantiene:
   - Absurdo tratado con seriedad, y corazón al final de cada acto.
   - Sin sangre: los malos se desintegran en chispas o vuelven a su dimensión.
