# Diseño del espacio: trabajos, villano, misiones, eventos, bandos y estaciones

> Para Sebastián y para quien lo programe. Sale de [`encargo.md`](encargo.md) y de la
> [`auditoria.md`](auditoria.md). Reutiliza el diseño de los planetas (`docs/planetas/diseno-mundos.md`
> §2.1 «Los 11 trabajos comunes», §2.3 «Astillero», §2.4 «Economía») y no contradice el canon de
> `docs/historia/` ni `docs/invasion.md`.
>
> Etiquetas: **[HECHO]** está programado y probado con Lune en esta tanda · **[SIGUIENTE]** es lo
> próximo · **[DISEÑO]** solo está escrito.

---

## 1 · Trabajos espaciales

### 1.1 · Las reglas (las mismas que en los planetas)

- **La carrera es una sola para toda la galaxia** (`diseno-mundos.md` §2.1): un transportista de Alba es
  el mismo transportista en Tefra. Se guarda en `data.Space.Jobs.Xp[trabajo]`.
- **5 rangos**: Aprendiz → Oficial → Veterano → Experto → Maestro. Paga ×1,0 / ×1,2 / ×1,45 / ×1,75 /
  ×2,1 (los mismos números que los planetas).
- **Se apuntan en el tablón** de cada estación: el botón «🧰 Contratos» del tablón de siempre.
- **Contratos que cambian**: cada estación ofrece 4 contratos nuevos **cada 10 minutos**. Salen de una
  **semilla** (estación + franja de 10 min): todos los jugadores del mismo servidor y de otros servidores
  ven los mismos, y se pueden repetir en las pruebas.
- **Todo lo decide el servidor**: el cliente solo elige una opción del menú con ficha (como la tienda).
  Entregar = atracar de verdad en el muelle (el servidor mira dónde está la nave). Cobrar una recompensa =
  el servidor ha visto caer a **ese** enemigo (por su id).
- **Una sola vez**: cada contrato tiene un id único; al completarlo se apunta en `Done` y no se puede
  coger ni cobrar otra vez.
- **Topes contra granjas**: como mucho **3 contratos a la vez**, **12 completados por hora** (después,
  «descansa un poco»), la paga baja un 10 % cada vez que repites el mismo tipo seguido (hasta −40 %), y
  las Chispas de los contratos van con el **mismo tope por hora que los derribos** (40).
- **Fallar no frustra**: si fallas, pierdes el contrato y un poco de reputación; nada de multas ni de
  perder dinero.

### 1.2 · Los trabajos

| Trabajo | Bucle | Paga (rango 1) | Estado |
|---|---|---|---|
| **Transportista (repartidor)** | Coger carga en una estación → volar → atracar en la otra (a tiempo, sin romperla) | $260–520 (+ ✨ 1 en peligrosas) | **[HECHO]** |
| **Cazarrecompensas** | Coger la ficha → ir al sector → el objetivo aparece con su escolta → derribarlo | $350–950 + ✨ 1–3 | **[HECHO]** |
| **Minero/a** | Ya existe: láser contra asteroides, bodega, vender en la tienda | $12–80 por unidad | Existe · rango **[SIGUIENTE]** |
| **Mercenario/a** | Escoltar un carguero NPC por un sector / defender una estación de oleadas | $400–900 | **[DISEÑO]** (necesita NPC que vuelan una ruta) |
| **Explorador/a-cartógrafo** | Descubrir puntos ocultos con el escáner y volver vivo a vender el mapa | $30 por punto + $150 por mapa | **[DISEÑO]** (ya hay `data.Space.Found` y el escáner) |
| **Chatarrero/a** | Recoger restos que dejan los combates (cajas que flotan) y venderlos | $8–40 por pieza | **[DISEÑO]** |
| **Científico/a de anomalías** | Ir a una anomalía en su ventana de tiempo, quedarse dentro escaneando mientras pasan cosas raras | $300–700 + ✨ | **[DISEÑO]** |
| **Contrabandista** | Carga escondida para los Saqueadores: si una patrulla de la Vigilancia te escanea, eliges huir o soltarla | $600–1200, riesgo de reputación | **[DISEÑO]** |
| **Piloto de carreras** | Aros entre los asteroides del Cinturón, contra reloj, nave igualada | Premio fijo + récord | **[DISEÑO]** |
| **Rescatista** | Señal de socorro: llegar a tiempo, proteger la cápsula, llevarla a la estación | $300–600 | **[DISEÑO]** |

### 1.3 · Transportista (repartidor) — **[HECHO]**

| Tipo de carga | Qué pasa | Paga base | Rango | Extra |
|---|---|---|---|---|
| **Suministros** | Normal | $260 | Aprendiz | — |
| **Medicinas (urgente)** | Tiene hora de entrega: si llegas tarde, cobras la mitad | $340 | Aprendiz | — |
| **Instrumentos (frágil)** | Hay que atracar con el casco al **60 %** o más: si no, la carga se rompe | $380 | Aprendiz | — |
| **Combustible de salto (peligrosa)** | Normal, pero vale más y es para gente con experiencia | $520 | Oficial | ✨ 1 |

- **Rutas:** Alba ↔ Cénit (las dos estaciones que existen). **[SIGUIENTE]:** Alba/Cénit → Muelle Bastión
  (Tefra), entregando en la plataforma tras aterrizar.
- **Tiempo mínimo**: no vale entregar antes de `max(12 s, distancia ÷ 1000)` (despegar, cargar el salto
  cuántico de 3 s y atracar ya lleva más). Lo importante lo valida el servidor: solo cuenta atracar con la
  nave de verdad en el muelle. Si alguien llega «antes de tiempo», no cobra y se le avisa.
- **Si te derriban, la carga se pierde** (contrato fallado, −3 de reputación). Si te desconectas, el
  contrato **sigue** (está guardado) pero caduca a los 40 minutos de cogerlo.
- **Bando:** Gremio Libre de Cargueros.

### 1.4 · Cazarrecompensas — **[HECHO]**

| Nivel | Dónde se esconde | Objetivo | Escolta | Paga base | ✨ | Rango |
|---|---|---|---|---|---|---|
| 1 | Sector Brasa | Caza reforzado | — | $350 | 1 | Aprendiz |
| 2 | Ruta de los Saqueadores | Caza reforzado | 1 dron | $600 | 2 | Oficial |
| 3 | Sector Escarcha | Caza muy reforzado | 2 drones | $950 | 3 | Veterano |

- **Ficha**: alias y nombre inventados («Rasca» Ostrel, «La Polilla» Marrás…), delito (piratería en la
  Ruta, robo de carga, contrabando de cristal, atacar una baliza…) y el sector. Sale en el HUD como
  misión, con la flecha al centro del sector.
- **Cómo aparece**: al entrar en su sector (fuera de la zona segura) el servidor lo pone a ~700 studs
  delante de ti con su escolta y avisa: «📡 Objetivo localizado».
- **Se escapa** si te alejas mucho (el sistema de patrullas quita a los enemigos lejanos): vuelve a
  aparecer cuando vuelvas, a los 20 s. Si te derriban o te bajas de la nave, se va y el contrato sigue.
- **Cobrar**: solo si cae **ese** enemigo (por su id) y solo una vez. Caduca a los 45 minutos.
- **[DISEÑO]** «Inutilizar» en vez de derribar (más paga) con el láser preciso cuando le queda poco.
- **Bando:** Vigilancia de Cénit.

### 1.5 · Rangos y reputación — **[HECHO]**

| Rango | Experiencia | Paga | Abre |
|---|---|---|---|
| Aprendiz | 0 | ×1,0 | Cargas normales, urgentes y frágiles; recompensas nivel 1 |
| Oficial | 6 | ×1,2 | Cargas peligrosas; recompensas nivel 2 |
| Veterano | 18 | ×1,45 | Recompensas nivel 3 |
| Experto | 40 | ×1,75 | **[DISEÑO]** contratos entre planetas |
| Maestro | 80 | ×2,1 | **[DISEÑO]** contratos únicos con historia |

- Experiencia: 1 por contrato (2 la carga peligrosa, el nivel en las recompensas).
- **Reputación** por bando de −100 a +100: +2 al cumplir, −3 al fallar, −1 si caduca. Cambia la paga
  entre −10 % y +10 %. **[DISEÑO]:** abre tiendas, precios y misiones de cada bando.

### 1.6 · Guardado y servidor

`data.Space.Jobs` (lo crea el servidor si falta, partidas viejas incluidas):

```
Xp     = { Carga = n, Caza = n }           -- carrera de la galaxia
Rep    = { Gremio = n, Vigilancia = n }    -- reputación
Active = { [id] = contrato copiado }       -- (lo aceptado no cambia si se reequilibra)
Done   = { [id] = os.time() }              -- contra duplicar (se limpia a las 3 h)
Log    = { os.time(), ... }                -- completados en la última hora (tope)
Last, Streak, Total                        -- para la paga que baja al repetir
```

- El objetivo de la recompensa vive **solo en la memoria del servidor** (no se guarda): al salir del
  juego desaparece y no queda nada colgado.
- Se reutilizan los menús con ficha de `SpaceService`, sus sucesos (atracar, derribo, derribado, bajar)
  y su bucle de 1 s (que se apaga solo si nadie vuela). No hay bucle nuevo.

---

## 2 · La historia principal del espacio: **Varkun, el Deshilador**

> **Necesita el sí de Sebastián.** La Saga 2 v3 decidió «planetas sin conexión y sin villano común»
> (`docs/historia/saga-2-siete-planetas.md`, decisiones). Ahora pides «salvar el universo de un malo
> maloso». Esta propuesta **mantiene los 7 episodios sueltos** (cada planeta vive su propio Ragnarock,
> que Varkun **no** provoca) y pone al villano **en el espacio, entre episodio y episodio**.

### 2.1 · En cinco líneas

1. Cada mundo que se acaba hace ruido (los desgarros) y **alguien más lo escucha**: Varkun, el último
   superviviente de un universo que se acabó sin que nadie fuera a ayudar.
2. Con su nave-luna, **la Rueca**, llega cuando un mundo está a punto de caer y le **saca el hilo**: lo
   convierte en hilo negro, que sirve para **deshilar** universos enteros.
3. Quiere tejer con todos ellos **un único tapiz quieto**, donde nada vuelva a acabarse… porque nada se
   mueve ni vive. «Nadie vino a por nosotros. Yo me aseguraré de que nadie tenga que esperar.»
4. Busca **los cálculos de la abuela Nilda** (NILDA, el chip de Cosme): el único mapa de los universos sin
   registro… entre ellos, **Valmar**.
5. Tú, Cosme, Pip y los aliados de los 7 planetas lo paráis en la Rueca; al final eliges **cortar su hilo**
   o **devolverle el de su mundo** (si encontraste la carta de Nilda).

### 2.2 · Por qué encaja con lo que ya hay

| Canon | Cómo encaja Varkun |
|---|---|
| Los desgarros, la Aguja y el ojal (`saga-2` §1.1) | Varkun oye lo mismo que la Aguja; su Rueca es el «revés» de la Aguja de Cosme (coser ↔ deshilar). Todo el vocabulario de costura de la Saga 1 (costuras, hilachas, ojal) se mantiene. |
| Cada episodio suelto (`saga-2` decisiones) | Varkun no causa ninguna crisis. Aparece **al final** de cada episodio como una costura negra en el cielo y en una misión del espacio aparte. |
| Cosme y Nilda (`cosme-otro-universo-y-saga-2.md`) | Nilda escribió a Varkun hace años (la mejor matemática de Tefra). NILDA guarda un archivo cerrado: «Para V., si alguna vez vuelve». |
| «VALMAR · ORIGEN» (gancho final, mismo documento) | Valmar tampoco está registrada: es el último hilo que Varkun quiere. Así el final vuelve a casa. |
| Las razas de la Invasión y sus reyes/dios (`docs/invasion.md`) | Las razas cruzaron la Grieta **huyendo** de los bordes deshilados de sus galaxias. En el Acto II puedes aliarte con algunos reyes (OZ-0 fabrica contramedidas, la luz de Ilyra quema el hilo negro, la niebla de Oskun esconde la flota) o pelear con ellos. Las invasiones de Valmar siguen igual. |
| Ofelia Brum solo en Vértice (`saga-2` decisiones) | Se queda en Vértice. Allí descubres que su «luz embotellada» la compra a «un tal V.». Es solo un guiño. |
| 13+ sin sangre (`saga-2` §0) | Deshilar se ve como **hilos de luz** que se desenredan (ciudades que se vuelven dibujos de tapiz), nunca cuerpos. Las muertes, fuera de plano. Naves y drones revientan con fuego y restos. |

### 2.3 · Varkun

- **Aspecto**: alto, con una capa hecha de retales de mundos (cada retal es un paisaje quieto), una
  máscara de hilo y unas manos con dedales de metal. Habla despacio, con educación, nunca grita.
- **Defecto y motivo**: se quedó solo esperando ayuda en un mundo que se apagaba. Cree que acabar con todo
  **de golpe y bonito** es más justo que dejarlo acabar mal.
- **Espejo de Cosme**: Cosme dice «No podemos salvarlos a todos. Pero podemos estar ahí». Varkun:
  «Estar ahí no salva a nadie. Yo lo sé: alguien estuvo, y miró».
- **Su gente**: los **Hilanderos**, drones y pilotos tejidos (no seres vivos: telas animadas con un núcleo
  de luz), así que se pueden derribar sin que «muera nadie».

### 2.4 · Actos y misiones clave

| Acto | Cuándo se abre | Misiones clave | Jefe |
|---|---|---|---|
| **Prólogo · «La costura negra»** | Al terminar la Saga 1 (como hoy la nave) | 1. **Señal de socorro** en la Ruta de los Saqueadores: un carguero destrozado lleva un carrete de hilo negro. 2. **Lo que nadie pidió** (transportista): llevar el carrete a la Cénit sin que te alcancen los primeros Hilanderos. 3. **Ruido en la Escarcha** (ciencia): escanear la primera anomalía de hilo. | — |
| **Acto I · «Hilos sueltos»** | Tras el episodio de Tefra | 4. **Lo que queda de Ovilla**: la luna de Tefra, tras la guerra, tiene una costura negra; explorar los restos. 5. **Convoy de Bastión** (mercenario): escoltar a los refugiados de Tefra hasta Alba. 6. **El mensaje**: Varkun habla por primera vez por la radio de NILDA. | **La Devanadera**: carguero pesado que suelta drones; romper sus 3 bobinas (puntos débiles, como el rey de la Invasión) para dejarlo al descubierto. |
| **Acto II · «El mapa de Nilda»** | Entre los episodios 2 y 6, en el orden que elijas | Tras cada planeta, una misión del espacio que recoge **un hilo** de ese mundo (5 hilos). 7. **Infiltración** en un Telar Hilandero (sigilo a pie): rescatar presos **o** robar un trozo del mapa (decisión). 8. **El Rey Engranaje**: OZ-0 ofrece una alianza a cambio de algo (aceptar o pelear). 9. **Duelo en el Huso**: Varkun en persona, en su nave; se retira al 50 % y te deja un retal de su mundo. | **El Huso** (nave de Varkun): duelo rápido con fases de esquivar hilos. |
| **Acto III · «El Telar del Fin»** | Tras Vértice | 10. **Llamada a los aliados**: vienen los de los 7 planetas según tus decisiones y tu reputación. 11. **Batalla de la Rueca** sobre el Sistema Valmar. 12. **Abordaje** (a pie, dentro de la Rueca). 13. **Cortar o coser**: el final. | **La Rueca** en 3 fases: 1) cortar los hilos que la sujetan (puntos débiles en el anillo), 2) el corazón del huso con oleadas de Hilanderos, 3) a pie contra Varkun con su armadura de dedales (avisos en el suelo, como el rey). |

### 2.5 · Consecuencias

- **Final A «Cortar»**: la Rueca se apaga y cae al sol con Varkun dentro (fuera de plano; queda su
  máscara flotando). El cielo de Valmar enseña para siempre los retales liberados como nebulosas nuevas.
- **Final B «Coser»** (solo si leíste la carta de Nilda): con la Aguja y NILDA coses el último retal de su
  mundo. Varkun se queda en la Cénit, preso, y a veces te da misiones de cartógrafo («sé dónde hay mundos
  que aún se pueden salvar»).
- **Lo que se guarda**: actos hechos, hilos recogidos, decisiones (presos o mapa, OZ-0 sí/no), aliados que
  vinieron y final. Con eso cambian los NPC de las estaciones, los carteles y los eventos (§4).

---

## 3 · Misiones secundarias del espacio (catálogo)

Cada una con la ficha de calidad del encargo. Las marcadas **[HECHO]** son los contratos; el resto,
**[DISEÑO]**.

| Misión | Objetivo | Inicio | Pasos | Éxito / fallo | Premio | Consecuencia | Se guarda |
|---|---|---|---|---|---|---|---|
| **Contrato de carga** [HECHO] | Llevar carga a otra estación | Tablón, rango | Coger → volar → atracar | Atracar a tiempo y entera / derribado o rota | $ y reputación Gremio | Rango de transportista | `Jobs.Active/Done/Xp/Rep` |
| **Contrato de recompensa** [HECHO] | Derribar a un fugitivo | Tablón, rango | Coger → ir al sector → derribarlo | Cae él / caduca | $, ✨, reputación Vigilancia | Rango de cazarrecompensas | igual |
| **Señal de socorro** | Salvar una cápsula | Evento aleatorio cerca de ti | Llegar antes de 90 s → defenderla 60 s → acompañarla a la estación | Llega / la destruyen | $ + objeto | La persona aparece luego en la estación | `Space.Rescued` |
| **Convoy** | Escoltar cargueros NPC | Evento global (§4) | Unirse → defender en 3 tramos | Llegan ≥ 2 de 3 / caen todos | $ por carguero | Precios de la estación bajan 1 h | Nada (temporal) |
| **Piratas de la Ruta** | Cadena de 5 misiones contra los Saqueadores | Reputación Vigilancia ≥ 10 | Investigar → seguir una nave → asaltar su base | — | Pieza de nave | El sector baja de nivel durante el día | `Space.Chains.Piratas` |
| **La anomalía que canta** | Escanear una anomalía | Ventana de 3 min | Entrar → quedarse dentro mientras falla el HUD | Escaneo al 100 % / sales | ✨ y dato científico | Abre la Estación Vigía | `Space.Science` |
| **Chatarra del Brasa** | Recoger 10 restos tras un combate | Tras un derribo grande | Recoger con el rayo → vender | — | $ | — | Nada |
| **El récord del Cinturón** | Carrera de aros | Siempre | 12 aros entre asteroides | Tiempo | Pintura | Tabla de récords del servidor | `Space.Records` |
| **Carga sin preguntas** | Contrabando | Reputación Saqueadores ≥ 0 | Coger → evitar el escáner de la Vigilancia → entregar | Entregas / te pillan (eliges soltarla o huir) | $$ | Reputación cruzada (+Saqueadores, −Vigilancia) | `Jobs.Rep` |

---

## 4 · Eventos galácticos

Todos salen de la **hora del servidor** (`shared/Cosmos/SpaceEvents`, ya existe): todos los servidores ven
lo mismo sin mandar nada.

| Evento | Estado | Inicio · duración | Qué pasa | Final y consecuencia |
|---|---|---|---|---|
| Tormenta de asteroides | Existe | Ciclo de 15 min · 5 min | Minar en un campo da una unidad más | — |
| Incursión pirata | Existe | Ciclo de 15 min · 5 min | Derribos en un sector dan ✨ +1 | — |
| **Contratos calientes** | [SIGUIENTE] | Mismo ciclo | Los contratos de recompensa del sector del evento pagan +25 % | — |
| Lluvia de cristales | [DISEÑO] | 1 de cada 4 ciclos · 3 min | Más cristal solar en la Nube Escarcha | — |
| Convoy de refugiados | [DISEÑO] | Cada hora · 6 min | Cargueros NPC cruzan la Ruta (misión Convoy) | Si llegan, la tienda de Alba baja precios 1 h |
| Tormenta solar | [DISEÑO] | Rara · 4 min | Los escudos se recargan la mitad; aviso en el HUD | — |
| **Costura negra** | [DISEÑO] | Tras el Prólogo · 5 min | Hilanderos en un sector; el cielo enseña la costura | Más fuerte según el acto de la historia |
| Invasión de la Grieta | Existe | Ya la lleva `InvasionService` | Manda en la fila EVENTO del HUD de la nave | — |

---

## 5 · Bandos

| Bando | Dónde | Qué le importa | Trabajo | Estado |
|---|---|---|---|---|
| **Gremio Libre de Cargueros** | Estación Alba (Oficina de Fletes) | Que la carga llegue | Transportista | Reputación **[HECHO]** |
| **Vigilancia de Cénit** | Estación Cénit (Oficina de Recompensas) | La ley en las rutas | Cazarrecompensas | Reputación **[HECHO]** |
| Liga de Estaciones | Las dos estaciones | Que las estaciones funcionen | Mercenario (defensas) | [DISEÑO] |
| Saqueadores de la Ruta | Puesto oculto en la Ruta | Lo que se pueda vender | Contrabandista | [DISEÑO] |
| Instituto Nilda | Campus Nilda (Tefra) y Estación Vigía | Las anomalías | Científico | [DISEÑO] |
| Hilanderos | — | Deshilar | Enemigos de la historia | [DISEÑO] |

## 6 · Papel de cada estación

| Estación | Papel | Lo que hay (✅ existe · [HECHO] esta tanda · [DISEÑO]) |
|---|---|---|
| **Alba** (puerto civil) | Comercio y carga | ✅ tienda, taller, tablón, hangar, portal · [HECHO] contratos (Oficina de Fletes del Gremio) · [DISEÑO] mercado con precios, NPC del Gremio, astillero ligero |
| **Cénit** (vigilancia) | Ley y combate | ✅ lo mismo · [HECHO] contratos (Oficina de Recompensas) · [DISEÑO] celdas (Varkun preso en el final B), armería de nave |
| **Estación Vigía** (nueva) | Ciencia | [DISEÑO] junto a la Nube Escarcha; se abre con «La anomalía que canta» |
| **Puesto Saqueador** (oculto) | Contrabando | [DISEÑO] en la Ruta; solo con reputación |
| **Muelle Bastión** (Tefra) | Puerta del planeta | ✅ plataforma de aterrizaje · [SIGUIENTE] entregas de carga |

---

## 7 · Preguntas para Sebastián

1. ¿Te gusta **Varkun, el Deshilador** como «malo maloso» del espacio, manteniendo los 7 episodios sueltos?
2. ¿Final elegido por el jugador (cortar o coser) o uno solo?
3. ¿Las razas de la Invasión pueden ser aliadas en el Acto II, o siempre enemigas?
4. ¿Qué trabajo quieres después: minero con rangos, mercenario (escoltas) o explorador?
5. ¿Las entregas a Tefra (Muelle Bastión) ya, o cuando estén sus misiones?
