# Cosme, el de otro universo · y la Saga 2 (en el espacio)

> **BORRADOR para Sebastián.** Es una propuesta para leer, tachar y cambiar. No se ha tocado nada del
> juego: ni misiones, ni marcas (flags), ni código. Donde pone «propuesta», todavía no existe.

## 0 · La idea nueva en cuatro frases

1. Valmar y su gente son **el mundo de bloques**: todos son cuadrados, y para ellos eso es lo normal.
2. Quien llega por la Grieta desde **otros universos** es una persona **«normal»**: cuerpo redondeado, cara con nariz y orejas, manos con dedos. Allí no hay esquinas.
3. **Cosme es de otro universo.** Por eso es distinto. El jugador lo descubre poco a poco, y se confirma en el Acto IV.
4. Más adelante habrá una **Saga 2 en el espacio**, con más tiros (pero sin sangre): un shooter con historia.

---

## 1 · Lo que la historia YA dice de Cosme (y que nos sirve)

He leído la saga entera (`docs/historia/13-saga-de-la-grieta.md`, `docs/historia/reescritura/Saga_*.md`,
`src/shared/LifeStory/Misiones/` y `Guiones/`), la ficha de Cosme en `Cast.luau`, `reparto.md`, la casa
(`docs/historia/casa-cosme.md` y `src/server/World/CosmeHouse/`) y las fases de la Grieta (`shared/SkyRift.luau`).

Lo bueno: **casi no hay que inventar pistas**. Muchas frases ya parecen escritas para este giro.

| Dónde | Lo que ya dice | Cómo se lee con el giro |
|---|---|---|
| `Loco_N1_Cosme` (paso 1) | «Y el chip de mi abuela… Ligeramente ilegal en tres dimensiones.» / «Mi abuela era especial… tenía mejores cálculos que yo. No hablemos de eso.» | Su abuela vive (o vivía) en **otro universo**. El chip es de allí. |
| `Loco_N1_Cosme` (final) | Al ver el tornillo: «¿Desde cuándo? ¿Antes de conocerme?» · «Eso no puede estar aquí.» | El tornillo brillante es **de su mundo**. |
| `Saga_02_Grieta` (Bigotes) | «La Grieta no es nueva. La había visto una vez.» | La primera vez fue cuando **llegó Cosme**. |
| `Saga_02_Grieta` (Medidor) | El medidor mide «cosas que no deberían existir aquí». | Y Cosme no debería existir aquí. |
| `Saga_04_Ventanilla` | «No me llames doctor.» · Sobre el tornillo: «No pertenece a 66-B. Ni a ninguna de las dimensiones registradas.» | El universo de Cosme **no está en ningún registro**. |
| `Saga_07_Costuras` | «Las costuras siempre se sueltan. Lo dijo… otro.» | Lo decía **su abuela**. Se paga en la revelación. |
| `Saga_09_Archivo` (la cinta) | Cósimo: «Un universo mañana. Dos Valmar en una.» Cosme: «Primero una. Luego ya veremos.» | Cosme quería coser el camino **a su casa**. Cósimo quería la Fusión. |
| `Saga_17_Rescate` | Cósimo: «Tú huiste. Yo simplemente continué.» | Huir es algo que Cosme ya hizo una vez. |
| `Saga_19_Recuerdos` | «Sé qué me quitó Cósimo. No quería mis recuerdos. Quería lo que había dentro de ellos.» | Lo que había dentro: **la ruta a su universo**. Aquí encaja la revelación. |
| `Saga_23_Fusion` | Cosme: «Ven a casa. Te hago un batido.» Cósimo: «¿A casa? ¿A qué casa, Cosme?» | Cósimo **siempre lo supo**. |
| `Cast.luau` / `reparto.md` (Abu) | «Se conocen de toda la vida. Sabe más de la noche de la Grieta de lo que dice.» | Abu **le encontró** cuando llegó. Guarda el secreto. |
| `reparto.md` (Pip) | «Señor. Tiene que contárselo. Algún día.» | Funciona para los dos secretos: el Ancla y su origen. |
| `CosmeLook.luau` | Camiseta negra **con colgante que brilla**. | El colgante es de su mundo y brilla cuando la Grieta se abre. |
| Casa: laboratorio | Pizarra del portal: «Destinos probados: **espacio profundo ✔**…» | Puente directo con la Saga 2. |
| Casa: observatorio | Telescopio que el jugador puede usar; satélite «PIP-SAT». | Sitio ideal para mirar hacia «casa». |
| `SkyRift.luau` | Desde la etapa 5 (Portal dimensional), **dentro de la Grieta se ve el espacio**: galaxia, planeta, nebulosa. | Al otro lado de la Grieta hay **espacio**. La Saga 2 va allí. |

**Fases de la Grieta** (no cambian): Rasguño → Crece → Grande → Abierta → Cosida → Hilachas → Rota →
Inminente → Fusión → Última costura → Cerrada.

**Dos cosas que chocan un poco** (ver también las preguntas del final):

- **La hoja de concepto de Cosme** (`docs/cosme/cosme-hoja.png`, recién hecha en `CosmeLook`) es **de bloques**. Con la idea nueva, Cosme tendría que ser «normal». Propongo **mantener todo su disfraz** (pelo de punta, gafas, bata, mochila, aparato de muñeca, pistola de rayos) sobre un **cuerpo distinto**: la misma silueta, pero redondeada.
- **«Las tres Valmar»** (`Loco_U3_Multiverso`, misión loca de la universidad) tiene **otros Cosmes**: el de la dimensión K-12 y el Cosme «aburrido» que trabaja en un banco. Propuesta sencilla: **esos Cosmes también son «normales»**. Son otros Cosmes de su mismo universo que también se cayeron, y por eso el nuestro se queda tan callado al verlos. No hay que cambiar ni una frase.

---

## 2 · El giro de Cosme dentro de la saga actual (Actos I–IV)

### 2.1 · La historia secreta de Cosme (lo que el jugador NO sabe hasta el final)

- Cosme nació en **Tefra**, un planeta de un universo que la Aduana del Tiempo no tiene registrado (en sus pantallas sale «SIN REGISTRO»). Allí todo el mundo es «normal».
- Era un investigador joven. Su abuela, **Nilda**, era la mejor matemática de Tefra («mi abuela era una calculadora»). Le dio un chip con sus cálculos para viajar entre universos.
- Un experimento salió mal y Cosme **cayó por una grieta pequeña** al huerto de la familia de Abu, en Valmar, hace unos **38 años**. Es la «primera vez» que Bigotes vio la Grieta.
- Abu le escondió, le ayudó a quedarse en la casa de al lado y **nunca se lo contó a nadie**. Por eso «sabe más de lo que dice».
- Años después, Cosme conoció a **Cósimo** (que sí es de Valmar, de bloques). Juntos construyeron la máquina de coser dimensiones (el «Proyecto Costura»):
  - **Cosme** quería coser un camino **de vuelta a casa**.
  - **Cósimo** quería coser dos Valmar en una: la Fusión.
- La noche en que nació el jugador, la máquina falló. Lo demás ya lo cuenta la saga: Cósimo cayó a la 66-B y el bebé quedó como Ancla.
- Desde esa noche, Cosme **eligió quedarse** para cuidar al Ancla, aunque eso le alejaba de casa para siempre.
- Lo que Cósimo le sacó de la memoria (misión 19) era **la ruta a Tefra**. El Consorcio la quería: un universo entero sin registrar donde vender sus «vacaciones». Esto abre la Saga 2.

### 2.2 · Pistas sembradas en misiones que ya existen

Regla: **solo se añaden frases o textos de objetos**. No se añaden pasos, no se cambia el orden de los
pasos ni se quitan marcas. Cada frase va en el guion reescrito (`docs/historia/reescritura/<Id>.md`, y
se regenera `Guiones/<Id>.luau` con `lune run scripts/audit/aplicar-reescritura.luau <Id>`) y, para que
no se desincronice, también en el texto de respaldo de la misión (`Misiones/…luau`).

**Acto I (infancia): pistas muy suaves, que parecen chistes.**

| Misión | Momento que ya existe | Lo que se añade |
|---|---|---|
| `Loco_N1_Cosme` · diálogo del paso 2.2 (la bobina, el niño de la heladería) | NIÑO: «Esta cosa estaba dentro. Sabe a martes.» | NIÑO, mirando hacia el garaje: «Mi madre dice que el vecino es redondo porque toma mucho apio.» *(Es la primera vez que alguien dice en voz alta que Cosme es distinto.)* |
| `Loco_N1_Cosme` · opción «¿El chip de tu abuela?» | «Mi abuela era especial… No hablemos de eso.» | COSME, bajito: «Vivía lejos. Más lejos que lejos.» |
| `Loco_N1_Cosme` · cinemática final `Grieta_Rasgun` | La raja de luz aparece en el cielo. | Detalle visual: **el colgante de Cosme se enciende** a la vez que el tornillo. Él lo tapa con la mano. Sin frase. |
| `Loco_N6_Tirachinas` (Abu y Cosme en el parque) | ABU: «¿Has visto qué puntería? Se hereda.» | ABU: «Este hombre cayó en mi huerto hace treinta y ocho años y todavía no sabe usar una regadera.» COSME: «La regadera era defectuosa.» *(Suena a torpeza. Más tarde se entiende al pie de la letra.)* |
| `Saga_02_Grieta` · diálogo `Bigotes` | «La Grieta no es nueva. Una vez. En Gatonia…» | BIGOTES: «Y otra vez aquí, hace muchísimo. Cayó algo en un huerto. Nunca supe qué. Olía a bata.» |
| `Saga_02_Grieta` · diálogo `Medidor` | «Rarezas. Cosas que no deberían existir aquí.» | PIP: «También pita cuando el señor Cosme se acerca. Lo tenemos en estudio.» COSME: «Fallo de fábrica.» |
| `Saga_04_Ventanilla` · diálogo `Sello` | La máquina escanea al jugador: «ORIGEN: VALMAR · PATRÓN: HUMANO». Luego Cosme grita «¡Apágala!». | Antes de que la apaguen, la máquina escanea a Cosme: «ORIGEN: — SIN REGISTRO —». Cosme le da un golpe. FUNCIONARIA: «Como quiera, doctor. En su expediente no pone nada más. Ni siquiera de dónde es.» |
| `Saga_06_Coser` · diálogo `Voz` (después de coser) | «Hoy hemos cosido el cielo. Hoy… a cenar.» | COSME, mirando arriba un segundo: «Cada vez que la coso, cierro una puerta. Y alguna era mía.» |

**Acto II (adolescencia): las pistas se notan más.**

| Misión | Momento que ya existe | Lo que se añade |
|---|---|---|
| `Saga_07_Costuras` · diálogo `Punto1`/`Credencial` | «Las costuras siempre se sueltan. Lo dijo… otro.» | Sin cambios: se queda tal cual. Se paga en la misión 19 («Lo decía mi abuela»). |
| `Saga_09_Archivo` · diálogo `Proyector` (la cinta) | CÓSIMO joven: «Un universo mañana…». COSME joven: «Primero una. Luego ya veremos.» | COSME joven: «Primero la tuya. Luego… la mía.» CÓSIMO joven: «La tuya no sale en ningún mapa, socio.» Ahí **la cinta se corta**. En el presente, COSME: «Esa parte está rayada.» PIP: «No lo está.» COSME: «Pip.» |
| `Saga_12_Graduacion` · diálogo `Casualidad` | OMAR: «¿Ese es el vecino? ¿El de la gallina gigante? ¿Me firma la bata?» | OMAR: «¿Por qué es tan… redondito?» COSME: «Huesos grandes.» |
| `Saga_12_Graduacion` · diálogo `Cosimo` | CÓSIMO: «Siempre fue un buen profesor. Por eso me lo llevo.» | CÓSIMO: «Y porque sabe un camino que yo no sé. ¿Verdad, Cosme?» |

**Objetos en la casa de Cosme** (solo cambia el texto que se lee al usarlos; riesgo casi nulo):

| Sitio | Objeto | Texto propuesto |
|---|---|---|
| Observatorio (`Observatory.luau`, telescopio `CosmeTelescopio`) | Telescopio | Siempre apunta a la misma estrella, que no sale en ningún mapa de Valmar. Una etiqueta pegada: «CASA (no tocar el enfoque)». |
| Habitación secreta (`SecretRoom.luau`, vitrinas) | Objeto nuevo en la vitrina | «Llave de una puerta que no está en Valmar.» La llave es redonda. Todo en Valmar es cuadrado. |
| Habitación secreta, pared de fotos | Foto nueva | Una ciudad con gente **sin esquinas**. Detrás: «Tefra. Cumpleaños de la abuela Nilda.» |
| Despacho (`Interior.luau`, «Foto antigua» con Cósimo) | La foto que ya existe | Se añade: «Cósimo sale cuadrado, como todos. Cosme no.» |
| Laboratorio, pizarra del portal | Ya dice «espacio profundo ✔» | Se añade una línea tachada: «~~Tefra~~ (falta el chip de la abuela)». |

### 2.3 · El momento de sospecha (mitad de la saga · Acto III)

**Dónde:** `Saga_16_66B`, en la Valmar malvada, justo después del diálogo `Malvado` (tu yo malvado).
**Quién está:** tú, Iván, Candela, Pip y tu yo malvado.

Tu yo malvado ya presume de que en la 66-B hay una versión mala de todo el mundo. Se añaden estas líneas al final de ese diálogo:

> **CANDELA:** Pregunta para mi lista. ¿Aquí hay un Cosme malvado?
> **TU YO MALVADO:** ¿Cosme? Aquí no hay ningún Cosme. Al lado de mi casa hay un solar vacío. Siempre lo ha habido.
> **IVÁN:** A lo mejor el Cosme malvado es Cósimo.
> **CANDELA:** No. Cósimo es de aquí y de allí. Cosme no es de ninguna de las dos.
> **PIP:** …
> **CANDELA:** Pip. Te has quedado callado. Tú nunca te quedas callado.
> **PIP:** Estoy calculando rutas. Muchas rutas. Todas a la vez.
> **CANDELA:** Lo apunto. Y apunto otra cosa: Cosme no tiene esquinas. ¿Nadie se ha dado cuenta en veinte años?

A partir de aquí el jugador **sospecha de verdad**, pero nadie se lo confirma. En `Saga_18_Precio`
(Cosme sin memoria) se puede añadir una línea suelta de Cosme en el diálogo `Nombre`: «Hay una estrella
que me mira todas las noches. No sé por qué la saludo.»

### 2.4 · La revelación (Acto IV · misión 19, «Recuerdos de tostadora»)

**Dónde:** el garaje de Cosme, en la escena final de la misión (diálogo `Vuelve`), **sin cambiar el paso**.
**Cuándo:** justo cuando Cosme lo recuerda todo, después de «Señor. Bienvenido. Otra vez.» y antes de «de lo que Cósimo me sacó».
**Quién está:** Cosme, Pip, Don Escamas y tú (los mismos actores que ya tiene el paso).

Borrador del guion (unas 22 líneas):

> *(Cosme deja la tostadora en la mesa. Se toca el colgante. Brilla un poco.)*
> **COSME:** Me acuerdo de todo, criatura. También de lo de antes de ti.
> **TÚ:** ¿Antes de mí?
> **COSME:** De antes de Valmar.
> **PIP:** Señor. ¿Está seguro?
> **COSME:** Llevo treinta y ocho años sin estarlo, Pip. Hoy sí.
> *(Cosme mira su mano. Los dedos. Luego mira la tuya, cuadrada.)*
> **COSME:** ¿Nunca te has preguntado por qué yo no tengo esquinas?
> **TÚ:** Siempre pensé que era el apio.
> **COSME:** Todo Valmar lo pensó. Qué gente tan educada.
> **COSME:** Yo nací en Tefra. Un sitio muy, muy lejos. Al otro lado de la costura.
> **COSME:** Allí nadie es cuadrado. Allí el raro serías tú.
> **DON ESCAMAS:** Lo sabía. Bueno, no lo sabía. Pero lo había apuntado.
> **COSME:** Me caí por una grieta pequeña. En el huerto de tu abu. Tu abu me dio una manta, un plato de sopa y una regla: «A nadie».
> **COSME:** El chip de mi abuela era mi billete de vuelta. Las costuras siempre se sueltan, decía ella.
> **COSME:** Con Cósimo quise coser el camino a casa. Él quiso coser otra cosa. Y esa noche naciste tú.
> **TÚ:** ¿Y por qué no volviste?
> **COSME:** Porque ya tenía a quien cuidar.
> *(Pausa. Pip se aparta para que no se le vea el aceite de los ojos.)*
> **COSME:** Eso es lo que Cósimo me sacó de la cabeza: la ruta a Tefra. Y se la ha vendido al Consorcio.
> **PIP:** Por eso tenían tanto interés en una tostadora.
> **COSME:** Primero salvamos esta Valmar. Luego… ya veremos.
> *(Es la misma frase de la cinta del archivo. Ahora suena distinta.)*

Después sigue el diálogo que ya existe («Y ahora me acuerdo de otra cosa: de lo que Cósimo me sacó…
Lo sabe todo. Viene a por ti.»), sin tocarlo.

**Marca nueva (propuesta):** `SabeOrigenCosme`, en las recompensas (`Rewards.Flags`) de `Saga_19_Recuerdos`.
Solo la usan frases nuevas; nada de lo que ya existe depende de ella.

**Ecos en las misiones siguientes** (una línea cada uno, con `If = { Flags = { "SabeOrigenCosme" } }`):

- `Saga_20_Aliados` (`Reunion`): BIGOTES a Cosme: «Así que tú eras lo del huerto. Me debes treinta y ocho años de curiosidad.»
- `Saga_22_Ancla` (`Oferta`): CÓSIMO: «¿Te lo ha contado ya? ¿Lo de que no es de aquí? Él tampoco pertenece a ningún sitio. Como yo.»
- `Saga_23_Fusion` (`Llegada`), la frase que ya existe «¿A casa? ¿A qué casa, Cosme?» **ahora duele**, sin cambiarla. Se añade COSME: «A esta. La elegí yo.»

### 2.5 · Cómo cambia el final (misión 24, «Coser el cielo (de verdad)»)

Tres opciones. **Recomiendo la A.**

- **A · Se queda, pero deja la puerta entornada (recomendada).** Cosme elige Valmar: «Mi casa es donde alguien me pregunta qué he roto hoy» (es casi la frase que ya dice en «Las tres Valmar»). La Grieta se cierra para siempre, como ahora. **Escena tras el «FIN»**: esa noche, el telescopio del observatorio pita. Una señal desde Tefra. Es la voz del chip de la abuela Nilda: «Cosme. Si oyes esto… se están apagando las estrellas.» Cosme mira al jugador: «Criatura. ¿Tienes carnet de nave?» → **Saga 2**.
- **B · Vuelve a casa.** Despedida triste en el patio. Es más emotivo, pero quita a Cosme de Valmar, y Valmar pierde a su mejor personaje.
- **C · Lo decide el jugador.** «¿Le pides que se quede?» Es bonito, pero obliga a escribir la Saga 2 dos veces.

Cambios del final A: unas líneas nuevas al final del diálogo `Final` de `Saga_24_Final`, solo si
`SabeOrigenCosme`. El paso de la cinemática `Grieta_Final` y la fase `Cerrada` **no cambian**.

### 2.6 · Cómo se ve que Cosme es «normal»

**Cómo es.** Mantiene **todo su disfraz** de la hoja de concepto (pelo plateado de punta, gafas, bata,
camiseta negra con colgante, mochila, aparato de muñeca, pistola de rayos con el tubo morado). Lo que
cambia es **el cuerpo**:

- cabeza redondeada, con nariz y orejas;
- brazos y piernas con forma (codos y rodillas, sin cantos);
- manos con dedos;
- proporciones de persona, un poco más alto y delgado que los vecinos;
- el colgante es lo único que brilla en él.

En la cinta del archivo (misión 9), Cosme joven también es «normal», y Cósimo joven es de bloques: se
ven los dos juntos.

**La primera vez que el jugador lo nota.** En `Loco_N1_Cosme`, en la cinemática de entrada
(`Cosme_PrimeraEntrada`): Cosme sale del humo verde y hay un plano de los dos juntos (tú cuadrado, él
redondo). No se dice nada; el contraste basta. Un minuto después, el niño de la heladería lo dice en voz
alta («es redondo porque toma mucho apio»). Primero lo ves, y luego alguien lo nombra.

**Cómo reaccionan los demás:**

- **Los adultos de Valmar** lo ven, pero **no lo comentan**: «Es Cosme. Siempre ha sido así.» Es un chiste que se repite: allí se considera de mala educación.
- **Los niños** sí lo dicen (el niño del helado, Omar en la graduación).
- **Los animales** lo saben desde siempre: Bigotes y Don Escamas.
- **Las máquinas** no saben qué hacer con él: el medidor de rarezas pita y la ventanilla 42 pone «SIN REGISTRO».
- **Cósimo** se burla. Le llama «socio» con retintín y, como mucho, «el redondo».
- **Candela** es la primera que lo apunta en serio (Acto III).
- **Abu** lo sabe todo y le protege. Nunca se ríe de eso.

---

## 3 · Lista exacta de cambios y su riesgo

| Archivo | Qué cambia | Riesgo |
|---|---|---|
| `docs/historia/reescritura/Loco_N1_Cosme.md`, `Saga_02_Grieta.md`, `Saga_04_Ventanilla.md`, `Saga_06_Coser.md`, `Saga_09_Archivo.md`, `Saga_12_Graduacion.md`, `Saga_16_66B.md`, `Saga_18_Precio.md`, `Saga_19_Recuerdos.md`, `Saga_20_Aliados.md`, `Saga_22_Ancla.md`, `Saga_23_Fusion.md`, `Saga_24_Final.md` | Frases nuevas en diálogos que ya existen | **Bajo.** Solo texto. |
| `src/shared/LifeStory/Guiones/<los mismos>.luau` | Se **regeneran** con `aplicar-reescritura.luau` (nunca a mano) | **Bajo.** Hay que mirar el `.informe.md` que sale. |
| `src/shared/LifeStory/Misiones/Loco_Nino.luau`, `Saga_Acto1.luau` … `Saga_Acto4.luau` | Las mismas frases en el texto de respaldo | **Bajo.** Si no se hace, manda el guion y no pasa nada grave. |
| `Misiones/Saga_Acto4.luau` (`Saga_19_Recuerdos`) | Marca nueva `SabeOrigenCosme` en las recompensas | **Bajo-medio.** Hay que pasar `scripts/test-lifestory.luau`. |
| `Misiones/Loco_Nino.luau` (`Loco_N6_Tirachinas`) | Dos frases de Abu y Cosme | **Bajo.** |
| `src/server/World/CosmeHouse/Observatory.luau`, `SecretRoom.luau`, `Interior.luau`, `Laboratory.luau` | Textos de objetos (y una vitrina más en la habitación secreta) | **Muy bajo** (los textos). **Bajo** (la vitrina nueva). |
| `src/shared/LifeStory/Cast.luau`, `docs/historia/reparto.md`, `docs/historia/13-saga-de-la-grieta.md` | La biografía de Cosme y Abu | **Muy bajo.** |
| `src/shared/CosmeLook.luau` (+ `Npc.dress`, actores de escenas y de cinemáticas) | **Cuerpo «normal» para Cosme** | **Alto.** Sale en decenas de escenas: encuadres, animaciones, caras (`setFace`), la casa. Conviene hacerlo aparte y probarlo en Studio. |

**Lo que NO se toca:** el número ni el orden de los pasos (el guion reescrito los cambia por número,
`Steps["n"]`), las marcas que ya existen, las fases de la Grieta y los `Requires` de las misiones.

---

## 4 · SAGA 2 · «La Saga de las Estrellas» (esquema)

> Nombre de trabajo. Esquema de 1–2 páginas: nada de esto está hecho.

### Premisa

Unos meses después de cerrar la Grieta, llega una señal a Tefra, el mundo de Cosme. El Consorcio
MegaVerso quebró en Valmar, pero sus restos se llevaron la ruta que Cósimo le robó a Cosme. Ahora se
llama **MegaVerso Orbital** y hace algo absurdo y terrible: **apaga estrellas para embotellar su luz** y
venderla como «Luz Premium». El cielo de Tefra se queda a oscuras, estrella a estrella.

La Grieta está cerrada y no se vuelve a abrir. Cosme usa la **Aguja de oro** (el premio de la misión 24)
para hacer algo más pequeño y educado: **un ojal**, una puerta con botón que se abre y se cierra. «Un ojal
no es una grieta. Es un agujero con modales.» Por el ojal pasa **la nave del garaje** (el coche Cometa 66,
convertido en nave).

### Actos y misiones clave

**Acto I · «El ojal»** (Valmar → la órbita)

1. **Señal desde casa.** El telescopio pita; se oye la voz de la abuela Nilda grabada en el chip.
2. **La nave del garaje.** Reúnes piezas por Valmar para convertir el Cometa 66 en nave (al estilo de la misión del microondas).
3. **Pruebas de vuelo.** Aprendes a pilotar en el cielo de Valmar: aros, frenazos y aterrizaje en la torre del observatorio.
4. **Coser un ojal.** Cruzas. Primer combate en el espacio contra drones de vigilancia de MegaVerso.

**Acto II · «Tefra»** (el mundo de los «normales»)

5. **El raro eres tú.** Llegas a Tefra. **Todos son «normales» y tú eres el cuadrado**. Te miran y te hacen fotos.
6. **El que se fue.** Cosme vuelve a casa después de 38 años. Su familia le daba por perdido; la sobrina, Vera, no se lo perdona tan fácil.
7. **La primera estrella apagada.** Asalto a pie a una estación embotelladora: el primer gran tiroteo.
8. **Persecución en el cinturón.** Combate de naves entre asteroides para salvar un carguero.

**Acto III · «Las estrellas apagadas»**

9. **El chip de la abuela.** NILDA, la inteligencia de navegación que hizo la abuela, despierta en tu nave y guía las misiones.
10. **Infiltración en la Torre de Ventas.** Sigilo y tiros en la sede de MegaVerso Orbital.
11. **Un viejo socio.** Cósimo, ya redimido (si le perdonaste en la Saga 1), aparece con una idea y una perilla nueva «solo de visita».
12. **La traición de la letra pequeña.** La directora de MegaVerso Orbital pone a Tefra en venta. Hay que escapar de la estación.

**Acto IV · «Encender el cielo»**

13. **La flota de los aliados.** Vuelven los aliados de la Saga 1 que puedan viajar (Cronos con permisos, Ñoz retransmitiendo, Bigotes «supervisando»).
14. **La Embotelladora Mayor.** Batalla de naves contra la nave madre.
15. **Abordaje.** Combate a pie dentro de la nave madre y jefe final: hay que **descorchar** las estrellas embotelladas, no destruir a nadie.
16. **Encender el cielo.** Epílogo: las estrellas vuelven a brillar. Cosme decide dónde vive (ver preguntas).

### El bucle de juego (shooter con historia)

- **Resumen de una misión:** charla en el hangar → vuelo a la zona (combate de naves) → atraque → combate a pie → jefe o huida → recompensa y mejoras de la nave en el taller de Cosme.
- **A pie (tercera persona):** coberturas, rodar, armas de ciencia ficción **no letales**: aturdidor, cañón de burbujas cuánticas (la evolución de la pistola de burbujas de la misión 1), lanzador de redes. Ves sus balas y sabes cuándo recargar.
- **En nave:** arcade, no simulador. Acelerar, frenar, turbo, escudo, apuntar con fijación de blanco y misiles de pintura que dejan a la nave enemiga «inutilizada».
- **Mejoras:** con «chispas de estrella» (lo que sueltan los enemigos) se mejoran el escudo, el turbo y las armas. Cosme lo comenta todo.
- **Tono sin sangre:** los robots y drones **se deshacen en chispas**. Los pilotos enemigos **salen disparados en una cápsula-burbuja** y se van flotando, enfadados. Los agentes de MegaVerso se rinden («Solo soy de atención al cliente») o se teletransportan a su oficina.

### El jugador en otros universos

**Recomendación:** el jugador **sigue siendo de bloques** en Tefra. Es el espejo de la Saga 1: allí
Cosme era el raro y aquí lo eres tú. Además es lo más barato, porque usa el mismo avatar del jugador.
Detalles graciosos:

- las puertas de Tefra son redondas y tú te atascas con los hombros;
- los niños de Tefra te piden fotos;
- a Cosme, después de 38 años en Valmar, le han salido **dos esquinas** («¿Desde cuándo tengo codos cuadrados?»).

### Personajes nuevos (todos «normales»)

| Personaje | Quién es |
|---|---|
| **Vera** | Sobrina de Cosme. Piloto de carga, seca y valiente. Creció oyendo hablar del «tío que se cayó del cielo». Al principio no le perdona que no volviera. |
| **NILDA** | La inteligencia del chip de la abuela. Habla con refranes matemáticos, va de lista y es muy cariñosa. Es la voz que guía el combate. |
| **Comandante Ruy Tadeo** | Jefe de la patrulla de Tefra. Muy estirado y muy de normas. Al final, aliado (es un poco el Cronos de esta saga). |
| **Kiko** | Mecánico joven de la estación. Habla deprisa, admira a Cosme y te tunea la nave. |
| **Directora Ofelia Brum** | La villana: jefa de MegaVerso Orbital. Sonrisa de anuncio, siempre con un folleto. Cree que la luz «es un producto». |

### El gancho final

Con el cielo de Tefra ya encendido, NILDA encuentra en los archivos de MegaVerso una lista de
**«universos sin registrar»**. Uno de ellos lleva un nombre que el jugador conoce: **VALMAR · ORIGEN**.
Valmar tampoco sale en el registro. ¿Quién **construyó** el mundo de bloques?

### Sistemas necesarios y tamaño aproximado

| Sistema | ¿Existe? | Qué falta |
|---|---|---|
| Armas a pie | Sí: `WeaponService`, `WeaponController`, `WeaponFx`, `CombatController`, `shared/Weapons.luau` | Armas de ciencia ficción no letales. Revisar las reglas de `Weapons.luau` (licencia, zonas seguras) para que valgan dentro de la Saga 2. |
| Combate de la historia | Sí: pasos `Fight` y `Escape` de las misiones, `FighterService` + `CombatAI` | Enemigos **a distancia** (que disparen y se cubran) y oleadas. |
| Vuelo | Base: `AviationService`, `Controllers/Flying`, `shared/Flight` | **Nave espacial**: vuelo en todas direcciones, sin gravedad, con turbo y escudo. |
| Combate de naves | No | Disparos de nave, fijación de blanco, IA de naves enemigas y un jefe nave. |
| Escenas espaciales | No (sí hay cielo con galaxia en `SkyRift`) | Lugares o zonas aparte: órbita, cinturón de asteroides, estaciones y Tefra. Probablemente lugares separados con teletransporte. |
| Personajes «normales» | No | El **mismo cuerpo redondeado que Cosme**, reutilizable para toda la gente de Tefra. |
| Misiones | Sí: el motor LifeStory (pasos, guiones, cinemáticas) | Pasos nuevos: `Fly` (volar a un punto), `Dogfight` (combate de naves), `Board` (abordar) y `Defend` (defender). |

**Tamaño:** 16 misiones de 30 a 45 minutos (unas **10–12 horas**). En trabajo es **más grande que la
Saga 1**: lo nuevo y caro son la nave, el combate de naves y las escenas espaciales. Propuesta de orden:
primero un prototipo de nave con una sola misión (la 4, «Coser un ojal»); si es divertido, el resto.

---

## 5 · Preguntas para Sebastián

1. **¿Cómo se llama el mundo de Cosme?** He puesto «Tefra». ¿Te gusta u otro nombre?
2. **El cuerpo «normal» de Cosme:** ¿mantenemos el disfraz de la hoja de concepto sobre un cuerpo redondeado (recomendado) o quieres una hoja nueva?
3. **¿Cuándo lo descubre el jugador?** ¿En la misión 19 (recomendado), antes (misión 9, la cinta) o solo al final (misión 24)?
4. **El final de Cosme:** A) se queda y llega la señal (recomendado), B) vuelve a su mundo o C) lo elige el jugador.
5. **¿Abu sabía la verdad desde el principio?** Sí (recomendado) o no.
6. **En la Saga 2, ¿el jugador sigue siendo de bloques en el espacio** (recomendado), se vuelve «normal» o se puede elegir?
7. **¿Los otros Cosmes de «Las tres Valmar»** también son «normales» (recomendado) o los quitamos?
8. **El villano de la Saga 2:** ¿MegaVerso Orbital y su directora, o prefieres que vuelva Cósimo como malo?
