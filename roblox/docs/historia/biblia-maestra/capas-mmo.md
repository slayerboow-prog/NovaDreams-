# HEROES OF HISTORY — Las tres capas del MMO (H10)

> Versión cerrada del 18-11-2026. ✅ Aprobado por el dueño (RC-081).
> Es la norma narrativa y de diseño. **La implementación exige antes auditar** `WorldState`, `StageSets`,
> `HappeningService` y la memoria del mundo. No se ha tocado código.

## 1. Las tres capas

| Capa | Qué contiene | Quién la ve | Dónde se guarda (por auditar) |
|---|---|---|---|
| **1 · Personal** | Las decisiones del jugador y sus consecuencias: quién vive o muere en su historia, el estado de sus Sellos, sus epílogos, sus variantes de diálogo, sus títulos y sus marcas | **Solo ese jugador** (y las escenas de grupo, según §4) | Flags y memoria del mundo del jugador (`WorldState`) |
| **2 · Compartida** | El mundo común: zonas sociales, ciudades, mercados y puntos de encuentro, con un **estado neutral** | Todos los jugadores del servidor | Estado del servidor |
| **3 · Canónica** | La evolución global del universo: hitos que el juego declara ocurridos para todos (por ejemplo, tras el final, los ocho mundos liberados) | Todos, en todos los servidores | Configuración global (versión del canon) |

**Regla madre:** ninguna decisión personal modifica de forma unilateral lo que ven los demás. Lo personal solo se
muestra en la capa personal.

**Regla de implementación (RC-087):** un jugador puede haber elegido «Cerrar» u «Ocupar» en su historia personal
mientras el mundo compartido sigue mostrando la continuidad canónica de «Liberar». Su historia personal no se borra,
pero tampoco transforma el universo común de los demás.

## 2. El estado neutral de la capa compartida

| Elemento | Estado neutral |
|---|---|
| Un planeta durante la campaña | El estado del **acto que la mayoría de su contenido presupone**: la ciudad habitada, con la amenaza presente pero contenida. Nunca muestra un desenlace (ni liberado ni arrasado). |
| Un personaje con destinos distintos (por ejemplo, Luz vuelve o se queda Velada) | **No aparece en las zonas compartidas mientras su destino dependa del jugador.** Aparece solo en la fase personal. |
| Un personaje con destino fijo (Kael muere en Tálasa) | En la capa compartida se ve según el canon: el **monumento a Kael** lo ve todo el mundo (RC-016) |
| PNJ ambientales (vendedores, guardias, vecinos) | Diálogos que no presuponen decisiones personales |
| Cielo y Sellos | La capa compartida muestra los Sellos según el canon global, no según la partida de cada uno |

## 3. Cómo se resuelven los estados

**Orden de prioridad** cuando un jugador está en un sitio:
1. **Fase personal** (una misión o escena suya, una zona de su historia): manda su capa personal.
2. **Zona compartida:** manda la capa compartida (neutral). Lo personal se ve solo como **rastros propios** que no
   cambian el mundo de los demás: su título, su cicatriz o su objeto de recuerdo.
3. **Siempre por encima:** la capa canónica. Ninguna capa personal puede negar un hito canónico en una zona compartida.

**Transiciones:**

| Transición | Cómo se hace |
|---|---|
| De compartida a personal | Al entrar en una misión, en una zona de fase o en una escena de historia. Fundido o plano de enganche (Vol. V-b); nunca un salto brusco. |
| De personal a compartida | Al terminar la escena o salir de la zona de fase. El mundo vuelve a su estado neutral. |
| Un planeta pasa a «liberado» en la capa personal | Al encender su Sello en el Acto V. **Su** cielo y **sus** zonas de fase muestran la liberación; la zona compartida sigue neutral. |
| Hito canónico global | Cuando el canon lo declara (por ejemplo, tras una actualización del juego). Se aplica a todos a la vez. |

## 4. Jugar en grupo

| Situación | Regla |
|---|---|
| Escena de historia en grupo | Cada jugador ve **su** variante: sus diálogos y sus PNJ vivos o muertos (`Scope` personal). Lo que es igual para todos se reproduce una vez (`Scope` de grupo). |
| Decisión tomada en grupo | **Cada jugador registra su propia decisión** en su capa personal. Las votaciones de grupo solo deciden lo que pasa en la escena compartida del momento. Nunca escriben en la historia de otro jugador. |
| Mazmorra instanciada | La instancia usa el estado neutral del acto. Las variantes personales se ven como capas individuales encima (diálogos y presencia de PNJ). |
| Jugadores en actos distintos | Se pueden agrupar. Quien no ha llegado a un acto no ve las revelaciones de ese acto: verá una versión sin destripes. |
| «Reavivar el Sello» en grupo | Cada uno estabiliza **su** Sello (H8) |

## 5. Los tres finales y las capas

| | Capa personal | Capa compartida | Capa canónica |
|---|---|---|---|
| **Cerrar el Telar** | Tu epílogo: los Hilos sellados, Sorel no te recuerda, Lys sola en Umbría (en tu fase de la plaza de Umbría, Nía la oye) | Neutral | — |
| **Liberar el Coro** | Tu epílogo: quién despierta según tus decisiones (Lía, los hijos de Corvo, Nilo, Luz…) | Neutral | **Es el final canónico**: los ocho mundos liberados, los Sellos en el cielo de todos y la ciudad de antes de vuelta. Las expansiones parten de aquí. |
| **Ocupar su lugar** | Tu epílogo: tu Pastor (tú, Ilse o Sorel), los que vuelven (R9) y los que se quedan a su cargo. Si el Pastor eres tú, llevas una cicatriz visible. | Neutral (tu cicatriz es un rastro propio) | — |

**Después del final:**
1. Cada jugador vive **su** final completo en su capa personal: escenas, epílogo, títulos y marcas.
2. Al terminar el epílogo, **el juego posterior ocurre en el mundo canónico** («Liberar»), igual para todos.
3. El final personal **no se borra**: se conserva como la historia de ese personaje. Se puede volver a ver en el
   memorial personal y lo recuerdan, en su fase, los personajes que le importan.
4. **Para quien eligió «Cerrar»:** su epílogo es la versión de su historia. El viaje entre mundos del juego posterior
   pertenece al mundo canónico, que es donde transcurre el MMO. Esto se explica una sola vez, de forma diegética, al
   terminar su epílogo («Así lo recordarás tú. El universo siguió otro hilo»), y no se contradice después.
5. **Hechos fijos que todas las capas comparten** (RC-016): Kael muere en Tálasa; Tomás muere en Valmar; Ilse abre el
   Nudo; Ithar muere en los tres finales.

## 6. Requisitos técnicos obligatorios (RC-088)
No son decisiones narrativas: son pruebas que el sistema tiene que superar **antes** de construir planetas encima.

| # | Prueba | Qué hay que demostrar | Cuándo |
|---|---|---|---|
| T1 | **Memoria individual** | Los diálogos y las escenas reconocen las decisiones personales del jugador **también en una zona compartida con otros jugadores**, sin que los demás vean esa variante | En la misión piloto de Valmar, con dos clientes en Studio |
| T2 | **Transiciones canónicas** | Decorados, personajes, misiones y ciudades cambian de forma coherente cuando el universo cambia de fase (de la campaña al canon «Liberar»), sin restos de la fase anterior | En la misión piloto y en una simulación del paso al canon |

## 7. Comprobación de los tres finales con las capas

| Comprobación | Resultado |
|---|---|
| ¿Algún final personal cambia lo que ven otros? | ✅ No: todo final personal se ve en la capa personal |
| ¿Coinciden los hechos fijos en las tres capas? | ✅ Sí |
| ¿Contradice el mundo canónico algún final personal mientras se está viviendo? | ✅ No: el epílogo personal termina antes de entrar en el mundo canónico (§5, punto 2) |
| ¿Puede un jugador quedar fuera del mundo canónico? | ✅ No: todos entran tras su epílogo, sea cual sea su final |
| ¿Un jugador que eligió «Ocupar» y es el Pastor puede seguir jugando? | ✅ Sí: conserva cuerpo, personaje y continuidad (R12) |
